function y = minmax_norm(v)
% MINMAX_NORM  Scale a vector to [0,1] by (v-min)/(max-min). Flat input -> zeros.
  v = v(:).';
  lo = min(v); hi = max(v);
  if (hi - lo) < eps
    y = zeros(size(v));
  else
    y = (v - lo) ./ (hi - lo);
  end
end
