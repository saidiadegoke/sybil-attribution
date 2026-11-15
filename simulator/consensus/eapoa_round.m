function [net, consE, blk] = eapoa_round(net, cfg)
% EAPOA_ROUND  One EA-PoA consensus round over every cluster's Local Blockchain,
% fully vectorised except the per-cluster block validation. For each cluster (CH
% as boot node + its admitted members as proposers = the authority set) it elects
% a battery-aware leader (Eq 7), puts the round's block to the quorum via
% validate_block, feeds the agreement outcome back into the trust counters
% (f/u/Ahat) so misbehaving nodes lose trust, and debits Eq (15) from EVERY node
% in the authority set, not only the leader. Returns total consensus energy and
% a block tally blk = {proposed, rejected}.
%
% Eq (15) per participant i in a cluster of size Nc:
%     E_cons(i) = E_M*1[i = L] + E_R*nVal(i) + E_I
%   nVal(L)     = Nc   the leader relays the block to, and collects votes from,
%                      the whole authority set
%   nVal(i /= L) = 1   each non-leader relays its own validation vote once
% E_I (idle/listen) is paid by every participant every round, since the whole
% authority set must stay awake for the exchange.
%
% cfg.consensusScope selects who is debited:
%   'participants' (default) CH boot node + member proposers, per section 8.6
%   'ch'                     the CH tier alone
  blk = struct('proposed', 0, 'rejected', 0);
  N = numel(net.x);
  CHs = find(net.role == 1 & net.alive);
  if isempty(CHs), consE = 0; return; end
  nCH = numel(CHs);
  pos = zeros(1,N); pos(CHs) = 1:nCH;

  % Authority set = clustered, alive AND on the permissioned roster. An
  % unregistered (forged) identity may associate as an ordinary member but is
  % never admitted to the authority tier, so it neither validates nor signs.
  % The authority set is roster-gated by default but NOT veto-gated: a node the
  % veto has barred from the cluster-head role still validates blocks and can
  % still be elected signer (leader = highest battery among ). That is the
  % implementation this study's admission results were measured on, so it is the
  % default. cfg.ablation.vetoAuthority extends the veto to authority-set
  % membership as well, which is the remedy the ledger results motivate.
  part = find(net.cid > 0 & net.alive & admissible(net, cfg));
  if isfield(cfg,'ablation') && isfield(cfg.ablation,'vetoAuthority') ...
     && cfg.ablation.vetoAuthority
    part = part(net.T(part) >= cfg.tau);
  end
  part = part(:).';                                % force row
  g = pos(net.cid(part));  g = g(:).';             % cluster index per participant (row)
  keep = g > 0; part = part(keep); g = g(keep);
  if isempty(part), consE = 0; return; end

  honest = double(~net.isMal(part));               % 1xK

  % --- trust feedback (elementwise) ---
  net.f(part(honest == 1)) = net.f(part(honest == 1)) + 1;
  net.u(part(honest == 0)) = net.u(part(honest == 0)) + 1;

  % --- per-cluster agreement rate -> Ahat ---
  cnt  = accumarray(g(:), 1,         [nCH,1]);
  sumh = accumarray(g(:), honest(:), [nCH,1]);
  frac = sumh ./ max(cnt, 1);                       % nCH x 1
  net.Ahat(part) = 0.7*net.Ahat(part) + 0.3*reshape(frac(g), 1, []);

  % --- leader per cluster = highest-battery participant (Eq 7) ---
  [~, ordp] = sort(net.E(part), 'descend');
  gs = g(ordp);
  [~, fi] = unique(gs(:), 'first');                % first per group = max battery
  isLead = false(1, numel(part));
  isLead(ordp(fi)) = true;                         % leader flag, aligned with `part`
  leaders  = part(isLead);                         % one leader per non-empty cluster
  gLeaders = g(isLead);                            % its cluster index

  % --- per-cluster block validation against the quorum (§8.6) ---
  % One Local-Blockchain block per cluster per round, accepted iff the honest
  % agreeing fraction meets cfg.quorum. A rejected block is not committed and
  % its proposer takes a trust penalty (Eq 11). Note this is a block-ACCEPTANCE
  % test, not an admission gate: a node that validates honestly at the consensus
  % layer can still misbehave at the data plane, which is why quorum alone
  % cannot keep a malicious node out of the cluster-head role (see §10).
  rejected = false(1, nCH);
  for k = 1:nCH
    memk = part(g == k);
    if isempty(memk), continue; end
    rejected(k) = ~validate_block(memk, net, cfg);
  end
  blk = struct('proposed', numel(leaders), 'rejected', sum(rejected(gLeaders)));
  bad = leaders(rejected(gLeaders));
  net.u(bad) = net.u(bad) + 1;                     % proposer of a rejected block

  % --- ledger integrity: adversarial writes and the rules that refuse them ---
  committed = leaders(~rejected(gLeaders));
  net = ledger_attacks(net, cfg, part, g, nCH, leaders, gLeaders, committed);

  % --- consensus energy debit over the authority set (Eq 15) ---
  Nc   = reshape(cnt(g), 1, []);                   % cluster size per participant
  nVal = ones(1, numel(part));
  nVal(isLead) = Nc(isLead);
  e = consensus_energy(isLead, nVal, cfg);         % Eq 15, vectorised

  if isfield(cfg, 'consensusScope'), scope = cfg.consensusScope;
  else,                              scope = 'participants';
  end
  if strcmp(scope, 'ch')
    e = e .* double(net.role(part) == 1);          % CH tier alone pays
  end

  net.E(part) = net.E(part) - e;
  consE = sum(e);

  net.alive(net.E <= 0) = false;
end
