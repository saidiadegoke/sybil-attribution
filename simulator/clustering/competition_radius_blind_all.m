function Rc = competition_radius_blind_all(net, cfg)
% COMPETITION_RADIUS_BLIND_ALL  Signal-blind unequal radius (distance-only) for
% every node (vectorised). Used by the E-FLZSEPFCH and Tao-IT2 baselines.
  dmax = max(net.dBS); dmin = min(net.dBS);
  Dr = (dmax - net.dBS) ./ max(dmax - dmin, eps);
  Rc = cfg.R0 .* (1 - cfg.c.*Dr);
  Rc = min(max(Rc, 0), cfg.R0);
end
