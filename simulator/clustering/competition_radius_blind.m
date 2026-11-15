function Rc = competition_radius_blind(i, net, cfg)
% COMPETITION_RADIUS_BLIND  Signal-blind unequal-clustering radius (EADUC/EEUC
% form): shrinks with proximity to the BS by distance alone. Used by the
% E-FLZSEPFCH and Tao-IT2 baselines (no signal/coverage awareness).
  dmax = max(net.dBS); dmin = min(net.dBS);
  Dratio = (dmax - net.dBS(i)) / max(dmax - dmin, eps);
  Rc = cfg.R0 * (1 - cfg.c * Dratio);
  Rc = min(max(Rc, 0), cfg.R0);
end
