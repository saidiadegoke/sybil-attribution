function j = jain(x)
% JAIN  Eq (17): Jain's fairness index over non-negative values.
  x = x(:); x = x(x >= 0);
  if isempty(x) || sum(x.^2) == 0, j = 0; return; end
  j = (sum(x))^2 / (numel(x) * sum(x.^2));
end
