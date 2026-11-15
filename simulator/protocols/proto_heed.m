function net = proto_heed(net, cfg)
% PROTO_HEED  Baseline (Younis & Fahmy, 2004): residual-energy CH probability
% with a vectorised coverage guarantee; members join the least-cost CH.
  N = numel(net.x);
  net.role = zeros(1,N); net.cid = zeros(1,N); net.Rc = zeros(1,N);
  Ehat = minmax_norm(net.E);
  Cprob = 0.10; pmin = 0.005;
  alive = find(net.alive);
  chprob = min(max(Cprob .* Ehat(alive), pmin), 1);
  chs = alive(rand(1, numel(alive)) < chprob);
  % coverage guarantee (vectorised): alive nodes with no CH in comm range -> CH
  if isempty(chs)
    covered = false(1,N);
  else
    covered = any(net.D(:, chs) <= cfg.commRange, 2).';
  end
  chs = unique([chs, find(net.alive & ~covered)]);
  if isempty(chs), chs = alive(1); end
  net.role(chs) = 1; net.cid(chs) = chs;
  net = member_assign(net, cfg);
end
