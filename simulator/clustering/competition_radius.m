function Rc = competition_radius(i, net, cfg)
% COMPETITION_RADIUS  Eq (14) for a single node i (wrapper over the vectorised
% all-node form; convenient for tests).
  all = competition_radius_all(net, cfg);
  Rc = all(i);
end
