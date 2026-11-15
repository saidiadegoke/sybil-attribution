function [muLo, muUp] = it2_grade(x, t)
% IT2_GRADE  Lower/upper membership of scalar x in IT2 triangular term t.
  muUp = tri(x, t.aU, t.bU, t.cU);
  muLo = t.hL * tri(x, t.aL, t.bL, t.cL);
  muLo = min(muLo, muUp);            % enforce lower <= upper
end

function m = tri(x, a, b, c)
% triangular MF, robust to degenerate shoulders
  left  = (x - a) / max(b - a, eps);
  right = (c - x) / max(c - b, eps);
  m = max(0, min(left, right));
end
