function net = rebuild_geometry(net, cfg)
% REBUILD_GEOMETRY  (Re)compute the static geometry matrices for the current node
% set. Split out of make_topology because Sybil identity forgery grows the node
% arrays after deployment (see spawn_sybil), and every vectorised per-round op
% indexes these matrices.
  X = net.x(:); Y = net.y(:);
  D = sqrt((X - X.').^2 + (Y - Y.').^2);      % MxM pairwise distance
  net.D       = D;
  net.log10D  = log10(max(D,1));
  net.A0      = (D > 0 & D <= cfg.commRange); % comm-range adjacency
  R = cfg.commRange;
  net.OVL     = circ_overlap_mat(D, R);       % MxM sensing-disk overlap area
  net.invSenseA = 1 / (pi * R^2);
  net.dBS     = hypot(net.x - cfg.BS(1), net.y - cfg.BS(2));
  net.rho     = density(net, cfg);
end

function A = circ_overlap_mat(D, R)
% Pairwise intersection area of equal-radius (R) sensing disks. Diagonal & beyond
% 2R -> 0 (self/no overlap).
  A = zeros(size(D));
  m = (D > 0 & D < 2*R);
  dd = D(m);
  A(m) = 2*R^2 .* acos(dd ./ (2*R)) - (dd ./ 2) .* sqrt(max(4*R^2 - dd.^2, 0));
end
