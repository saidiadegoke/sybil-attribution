function diag_pdr_shift()
% DIAG_PDR_SHIFT  Why did pooled PDRmean jump when Eq 15 was debited on the whole
% authority set, while common-window PDRwin stayed put? Compares per-round alive /
% clustered / CH / gen / deliv trajectories for the adversary scenario.
  cfg = config_default();
  cfg.protocol='proposed'; cfg.channel='shadow';
  cfg.adversary='blackhole'; cfg.compromised=0.2;
  cfg.seed=1; cfg.maxRounds=2000;

  for scope = {'participants','ch','legacy'}
    r = trace_run(cfg, scope{1});
    fprintf('\n--- scope=%s  PDRmean=%.4f PDRwin=%.4f LND=%d\n', scope{1}, ...
            sum(r.deliv)/sum(r.gen), sum(r.deliv(1:1000))/sum(r.gen(1:1000)), r.LND);
    fprintf('%6s %7s %9s %7s %7s %8s %8s\n','round','alive','clustered','orphan','nCH','gen','deliv');
    for rr = [500 1000 1200 1400 1600 1800 2000]
      fprintf('%6d %7d %9d %7d %7d %8d %8d\n', rr, r.alive(rr), r.clust(rr), ...
              r.alive(rr)-r.clust(rr), r.nCH(rr), r.gen(rr), r.deliv(rr));
    end
  end
end

function res = trace_run(cfg, scope)
  cfg.consensusScope = scope;
  set_seed(cfg.seed);
  net = make_topology(cfg); net = inject_attack(net, cfg);
  Z = zeros(1,cfg.maxRounds);
  res = struct('alive',Z,'clust',Z,'nCH',Z,'gen',Z,'deliv',Z,'LND',cfg.maxRounds);
  for r = 1:cfg.maxRounds
    if ~any(net.alive), res.LND = r; break; end
    net = sense_inputs(net,cfg); net = trust_update(net,cfg); net = ch_setup(net,cfg);
    if strcmp(scope,'legacy'), net = legacy_eapoa_round(net,cfg);
    else,                      net = eapoa_round(net,cfg);
    end
    [net, deliv, gen] = dphase(net,cfg);
    res.alive(r)=sum(net.alive); res.clust(r)=sum(net.alive & net.cid>0);
    res.nCH(r)=sum(net.role==1 & net.alive); res.gen(r)=gen; res.deliv(r)=deliv;
  end
end

function net = legacy_eapoa_round(net, cfg)
% Verbatim pre-fix debit: whole round's consensus cost charged to the leader only.
  N = numel(net.x);
  CHs = find(net.role == 1 & net.alive);
  if isempty(CHs), return; end
  nCH = numel(CHs); pos = zeros(1,N); pos(CHs) = 1:nCH;
  part = find(net.cid > 0 & net.alive); part = part(:).';
  g = pos(net.cid(part)); g = g(:).';
  keep = g > 0; part = part(keep); g = g(keep);
  if isempty(part), return; end
  honest = double(~net.isMal(part));
  net.f(part(honest==1)) = net.f(part(honest==1)) + 1;
  net.u(part(honest==0)) = net.u(part(honest==0)) + 1;
  cnt  = accumarray(g(:),1,[nCH,1]);
  sumh = accumarray(g(:),honest(:),[nCH,1]);
  frac = sumh ./ max(cnt,1);
  net.Ahat(part) = 0.7*net.Ahat(part) + 0.3*reshape(frac(g),1,[]);
  [~, ordp] = sort(net.E(part),'descend');
  gs = g(ordp); [ug, fi] = unique(gs(:),'first');
  leaders = reshape(part(ordp(fi)),1,[]);
  sizes   = reshape(cnt(ug),1,[]);
  e = cfg.EM + cfg.ER .* sizes + cfg.EI;
  net.E(leaders) = net.E(leaders) - e;
  net.alive(net.E <= 0) = false;
end

function [net, deliv, gen] = dphase(net, cfg)
% mirror of simulate.m's data_phase (private there), for tracing only
  N = numel(net.x); gen = sum(net.alive);
  CHs = find(net.role==1 & net.alive);
  if isempty(CHs), deliv=0; net.alive(net.E<=0)=false; return; end
  pos = zeros(1,N); pos(CHs)=1:numel(CHs);
  mem = find(net.alive & net.role==0 & net.cid>0);
  cpos = pos(net.cid(mem)); keep = cpos>0; mem=mem(keep); cpos=cpos(keep);
  cntMem = zeros(1,numel(CHs)); krecv = zeros(1,numel(CHs));
  if ~isempty(mem)
    cntMem = accumarray(cpos(:),1,[numel(CHs),1]).';
    dmc = net.D(mem + (net.cid(mem)-1)*N);
    net.E(mem) = net.E(mem) - radio_energy_eff(cfg.pktBits, dmc, cfg);
    rssi = cfg.Pt - (cfg.PL0 + 10*cfg.n*log10(max(dmc,1)));
    [~, pdr] = ber_pdr(rssi, cfg);
    recv = double(rand(1,numel(mem)) < pdr);
    krecv = accumarray(cpos(:),recv(:),[numel(CHs),1]).';
  end
  net.E(CHs) = net.E(CHs) - cfg.Eelec*cfg.pktBits .* cntMem;
  aggCount = krecv + 1;
  net.E(CHs) = net.E(CHs) - cfg.EDA*cfg.pktBits .* aggCount;
  dB = net.dBS(CHs);
  net.E(CHs) = net.E(CHs) - radio_energy_eff(cfg.pktBits, dB, cfg);
  rssiB = cfg.Pt - (cfg.PL0 + 10*cfg.n*log10(max(dB,1)));
  [~, pdrB] = ber_pdr(rssiB, cfg);
  drop = net.isMal(CHs) & (net.atk(CHs)==2 | net.atk(CHs)==3);
  chFwd = (rand(1,numel(CHs)) < pdrB) & ~drop;
  deliv = sum(aggCount .* chFwd);
  net.alive(net.E<=0) = false;
end
