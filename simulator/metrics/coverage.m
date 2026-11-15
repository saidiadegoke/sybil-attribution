function c = coverage(net, cfg)
% COVERAGE  Fraction of a 20x20 grid within cfg.commRange of an alive node.
% Vectorised (grid-points x alive-nodes distance matrix).
  al = find(net.alive);
  if isempty(al), c = 0; return; end
  [GX, GY] = meshgrid(linspace(0,cfg.field(1),20), linspace(0,cfg.field(2),20));
  gx = GX(:); gy = GY(:);                       % 400x1
  DX = gx - net.x(al);  DY = gy - net.y(al);    % 400 x Ma (broadcast)
  covered = any(DX.^2 + DY.^2 <= cfg.commRange^2, 2);
  c = mean(covered);
end
