function q = qfunc(x)
% QFUNC  Gaussian tail probability Q(x) = 0.5*erfc(x/sqrt(2)).
% Toolbox-free; elementwise.
  q = 0.5 .* erfc(x ./ sqrt(2));
end
