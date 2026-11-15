function rho = density(net, cfg) %#ok<INUSD>
% DENSITY  Vectorised normalised local density = alive-neighbour count / max.
  cnt = (net.A0 * double(net.alive(:))).';   % 1xN
  m = max(cnt); if m < 1, m = 1; end
  rho = cnt ./ m;
end
