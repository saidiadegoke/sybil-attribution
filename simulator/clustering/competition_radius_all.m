function Rc = competition_radius_all(net, cfg)
% COMPETITION_RADIUS_ALL  Eq (14) for every node at once (vectorised).
% Rc = R0 * [1 - c*Dratio] * [alpha*LQ + (1-alpha)*(1-O)], bounded in [0,R0].
  dmax = max(net.dBS); dmin = min(net.dBS);
  Dr = (dmax - net.dBS) ./ max(dmax - dmin, eps);                  % 1xN
  Ovec = min((net.OVL * double(net.alive(:))).' .* net.invSenseA, 1); % 1xN
  Rc = cfg.R0 .* (1 - cfg.c.*Dr) .* (cfg.alpha.*net.LQ + (1-cfg.alpha).*(1-Ovec));
  Rc = min(max(Rc, 0), cfg.R0);
end
