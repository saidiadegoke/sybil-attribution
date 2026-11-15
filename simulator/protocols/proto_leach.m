function net = proto_leach(net, cfg)
% PROTO_LEACH  Baseline: probabilistic CH selection (Eq 8 simplified to a
% per-round Bernoulli at the target CH proportion), nearest-CH membership.
  N = numel(net.x);
  net.role = zeros(1,N); net.cid = zeros(1,N); net.Rc = zeros(1,N);
  alive = find(net.alive);
  isCH = rand(1, numel(alive)) < cfg.pLEACH;
  chs = alive(isCH);
  if isempty(chs), chs = alive(randi(numel(alive))); end
  net.role(chs) = 1; net.cid(chs) = chs;
  net = member_assign(net, cfg);
end
