function O = overlap(i, net, cfg)
% OVERLAP  Eq (M6): fractional sensing-disk overlap of node i with its
% neighbours, capped at 1.  Sensing radius = cfg.commRange.
  R = cfg.commRange;
  nb = net.nbr{i};
  if isempty(nb), O = 0; return; end
  acc = 0; A = pi*R^2;
  for j = nb
    d = hypot(net.x(i)-net.x(j), net.y(i)-net.y(j));
    acc = acc + circ_overlap(R, R, d);
  end
  O = min(acc / A, 1);
end

function a = circ_overlap(r1, r2, d)
% area of intersection of two circles
  if d >= r1 + r2
    a = 0;
  elseif d <= abs(r1 - r2)
    a = pi * min(r1, r2)^2;
  else
    p1 = r1^2 * acos((d^2 + r1^2 - r2^2)/(2*d*r1));
    p2 = r2^2 * acos((d^2 + r2^2 - r1^2)/(2*d*r2));
    p3 = 0.5 * sqrt((-d+r1+r2)*(d+r1-r2)*(d-r1+r2)*(d+r1+r2));
    a = p1 + p2 - p3;
  end
end
