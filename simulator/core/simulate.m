function res = simulate(cfg)
% SIMULATE  Vectorised, protocol-agnostic round loop for ST-IT2FUC/EA-PoA and
% baselines. Returns per-round arrays + FND/HND/LND + summary means.
  set_seed(cfg.seed);
  net = make_topology(cfg);
  net = inject_attack(net, cfg);
  res = results_init(cfg);

  for r = 1:cfg.maxRounds
    if ~any(net.alive), break; end
    Estart = net.E;                               % for the shared-battery debit
    net = sense_inputs(net, cfg);                 % rho, RSSI -> LQ (vectorised)
    net = trust_update(net, cfg);                 % Eq 11
    net = ch_setup(net, cfg);                     % protocol hook: elect + cluster
    consOn = (~isfield(cfg,'ablation')) || cfg.ablation.consensus;
    if runs_consensus(cfg) && consOn
      [net, consE, blk] = eapoa_round(net, cfg);  % Eqs 7,15 + quorum + trust feedback
    else
      consE = 0; blk = struct('proposed',0,'rejected',0);
    end
    [net, deliv, gen] = data_phase(net, cfg);     % collect/aggregate/route + energy
    net = consolidate_sybil(net, Estart);         % one attacker, one battery
    res = results_log(res, r, net, deliv, gen, consE, blk, cfg);
    [net, nChurn] = churn_sybil(net, cfg);        % whitewash burned identities
    res.churn(r) = nChurn;                        % logged AFTER the round's
                                                  % state has been recorded
  end
  res.ledger = net.ledger;
  res = finalize(res, cfg);
end

% ---------------------------------------------------------------- local helpers
% (sense_inputs is now a standalone function in network/ so experiments reuse it)

function [net, deliv, gen] = data_phase(net, cfg)
% One packet/alive node/round; members relay through their CH, which aggregates
% and forwards to the BS. Per-link delivery sampled from channel PDR; blackhole
% CHs drop. Energy debited per Eqs (1)-(2),(M5). Fully vectorised.
  N = numel(net.x);
  gen = sum(net.alive & ~net.forged);   % mission traffic only: forged identities
                                        % emit attack traffic, not sensed data
  CHs = find(net.role == 1 & net.alive);
  if isempty(CHs)
    deliv = 0; net.alive(net.E <= 0) = false; return;
  end
  pos = zeros(1,N); pos(CHs) = 1:numel(CHs);       % CH index -> column

  % Forged identities are announced to win roles and occupy authority slots; they
  % carry no sensor and emit no data traffic. Making them transmit would charge
  % the attacker's single battery once per identity and kill it early, which
  % would understate the attack rather than test the defence against it.
  mem = find(net.alive & net.role == 0 & net.cid > 0 & ~net.forged);
  cpos = pos(net.cid(mem));                          % member -> CH column
  keep = cpos > 0; mem = mem(keep); cpos = cpos(keep);

  cntMem = zeros(1, numel(CHs));
  krecv  = zeros(1, numel(CHs));
  if ~isempty(mem)
    cntMem = accumarray(cpos(:), 1, [numel(CHs),1]).';     % members per CH
    dmc = net.D(mem + (net.cid(mem)-1)*N);          % member->CH distance
    net.E(mem) = net.E(mem) - radio_energy_eff(cfg.pktBits, dmc, cfg);   % member Tx
    rssi = cfg.Pt - (cfg.PL0 + 10*cfg.n*log10(max(dmc,1)));
    [~, pdr] = ber_pdr(rssi, cfg);
    recv = double(rand(1,numel(mem)) < pdr);
    krecv = accumarray(cpos(:), recv(:), [numel(CHs),1]).';
  end

  net.E(CHs) = net.E(CHs) - cfg.Eelec*cfg.pktBits .* cntMem;            % CH Rx
  aggCount = krecv + double(~net.forged(CHs));    % a forged head has no reading
                                                  % of its own to contribute
  net.E(CHs) = net.E(CHs) - cfg.EDA*cfg.pktBits .* aggCount;            % aggregate
  dB = net.dBS(CHs);
  net.E(CHs) = net.E(CHs) - radio_energy_eff(cfg.pktBits, dB, cfg);     % CH -> BS
  rssiB = cfg.Pt - (cfg.PL0 + 10*cfg.n*log10(max(dB,1)));
  [~, pdrB] = ber_pdr(rssiB, cfg);
  drop  = net.isMal(CHs) & (net.atk(CHs) == 2 | net.atk(CHs) == 3);   % blackhole/sinkhole
  chFwd = (rand(1,numel(CHs)) < pdrB) & ~drop;
  deliv = sum(aggCount .* chFwd);

  net.alive(net.E <= 0) = false;
end

function res = results_init(cfg)
  Z = zeros(1, cfg.maxRounds);
  res = struct('N',cfg.N,'alive',Z,'energy',Z,'pdr',Z,'cov',Z, ...
               'consE',Z,'malCH',Z,'nCH',Z,'J',Z,'deliv',Z,'gen',Z, ...
               'blkProp',Z,'blkRej',Z,'sybCH',Z,'sybMem',Z,'churn',Z,'rounds',0);
  % Optional trust trace (cfg.traceTrust): mean trust of alive forged identities,
  % mean trust of compromised hardware, and the count still above the veto
  % threshold. Off by default, so existing runs are bit-identical.
  res.Tforged = Z; res.Tmal = Z; res.nForgedAboveTau = Z;
end

function res = results_log(res, r, net, deliv, gen, consE, blk, cfg)
  gen_i = net.alive & ~net.forged;                % genuine (deployed) nodes
  res.alive(r)  = sum(gen_i);                     % lifetime is a property of
                                                  % deployed hardware, not of
                                                  % identities an attacker mints
  res.energy(r) = sum(max(net.E(~net.forged), 0));
  if gen > 0, res.pdr(r) = deliv / gen; else, res.pdr(r) = 1; end
  res.cov(r)    = coverage(net, cfg);
  res.consE(r)  = consE;
  res.malCH(r)  = sum(net.isMal & net.role == 1);
  res.nCH(r)    = sum(net.role == 1);
  res.sybCH(r)  = sum(net.forged & net.role == 1);   % forged identities elected
  res.sybMem(r) = sum(net.forged & net.alive & net.cid > 0);
  res.J(r)      = jain(net.E(gen_i));
  res.deliv(r)  = deliv;
  res.gen(r)    = gen;
  res.blkProp(r)= blk.proposed;
  res.blkRej(r) = blk.rejected;
  res.rounds    = r;
  if isfield(cfg,'traceTrust') && cfg.traceTrust
    fa = net.forged & net.alive;
    ma = net.isMal   & net.alive & ~net.forged;
    if any(fa), res.Tforged(r) = mean(net.T(fa)); else, res.Tforged(r) = NaN; end
    if any(ma), res.Tmal(r)    = mean(net.T(ma)); else, res.Tmal(r)    = NaN; end
    res.nForgedAboveTau(r) = sum(fa & (net.T >= cfg.tau));
  end
end

function res = finalize(res, cfg)
  n = max(res.rounds, 1);
  flds = {'alive','energy','pdr','cov','consE','malCH','nCH','J','deliv','gen', ...
          'blkProp','blkRej','sybCH','sybMem','churn', ...
          'Tforged','Tmal','nForgedAboveTau'};
  for k = 1:numel(flds), res.(flds{k}) = res.(flds{k})(1:n); end
  N = cfg.N;
  res.FND = first_or(find(res.alive <  N,   1), n);
  res.HND = first_or(find(res.alive <= N/2, 1), n);
  res.LND = first_or(find(res.alive == 0,   1), n);
  res.PDRmean    = sum(res.deliv) / max(sum(res.gen), 1);   % pooled, traffic-weighted (Eq 16)
  if isfield(cfg,'pdrWindow'), Wn = cfg.pdrWindow; else, Wn = n; end
  W = min(Wn, n);                                  % common-window (fair cross-protocol) PDR
  res.PDRwin = sum(res.deliv(1:W)) / max(sum(res.gen(1:W)), 1);
  res.Jmean      = mean(res.J);
  res.malCHrate  = mean(res.malCH ./ max(res.nCH, 1));
  res.consEtotal = sum(res.consE);
  res.blkRejRate = sum(res.blkRej) / max(sum(res.blkProp), 1);   % quorum rejections
  res.sybCHrate  = mean(res.sybCH ./ max(res.nCH, 1));           % forged identities
                                                                 % holding CH roles
  res.sybMemMean = mean(res.sybMem);                             % forged identities
                                                                 % inside clusters
  res.churnTotal = sum(res.churn);                               % identity re-mints
  % Ledger-integrity summary (§3.3 third channel). Refusal rates are reported
  % as fractions of attempts; adversarial authorship as a fraction of commits.
  if isfield(res,'ledger')
    L = res.ledger;
    % A protocol with no ledger has no attempts to refuse. Reporting 1.0 there
    % would credit it with an integrity it does not provide, so it is NaN.
    if L.forkAtt    > 0, res.forkRefused    = 1 - L.forkOk/L.forkAtt;       else, res.forkRefused    = NaN; end
    if L.rewriteAtt > 0, res.rewriteRefused = 1 - L.rewriteOk/L.rewriteAtt; else, res.rewriteRefused = NaN; end
    if L.unauthAtt  > 0, res.unauthRefused  = 1 - L.unauthOk/L.unauthAtt;   else, res.unauthRefused  = NaN; end
    if L.commits    > 0, res.advCommitFrac  = L.advCommits/L.commits;       else, res.advCommitFrac  = NaN; end
    res.ledgerAtt      = L.forkAtt + L.rewriteAtt + L.unauthAtt;
    res.ledgerBreaches = L.forkOk + L.rewriteOk + L.unauthOk;
  else
    res.forkRefused = NaN; res.rewriteRefused = NaN; res.unauthRefused = NaN;
    res.advCommitFrac = NaN; res.ledgerAtt = 0; res.ledgerBreaches = 0;
  end
  res.churnRate  = mean(res.churn);                              % re-mints per round
end

function v = first_or(idx, default)
  if isempty(idx), v = default; else, v = idx(1); end
end
