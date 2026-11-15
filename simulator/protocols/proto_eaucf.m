function net = proto_eaucf(net, cfg)
% PROTO_EAUCF  Baseline (Bagci & Yazici, 2013): energy-aware unequal clustering
% with a fuzzy (energy+distance) competition radius; energy wins the contest.
% Signal-blind. Vectorised.
  Ehat = minmax_norm(net.E);
  dmax = max(net.dBS); dmin = min(net.dBS);
  Dr = (dmax - net.dBS) ./ max(dmax - dmin, eps);
  Rc = cfg.R0 .* (1 - cfg.c.*Dr) .* (0.5 + 0.5.*Ehat);
  net.Rc = min(max(Rc, 0), cfg.R0);
  net = elect_competition(net, cfg, Ehat, net.Rc, net.alive);   % energy-based
  net = member_assign(net, cfg);
end
