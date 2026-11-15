function [yl, yr] = km_type_reduction(fl, fu, c)
% KM_TYPE_REDUCTION  Center-of-sets Karnik-Mendel via exact switch-point
% enumeration (M small). fl,fu = lower/upper firing strengths; c = consequent
% centroids. Returns the type-reduced interval [yl,yr].  (Eq 12 takes midpoint.)
  c = c(:); fl = fl(:); fu = fu(:);
  [c, ix] = sort(c); fl = fl(ix); fu = fu(ix);
  M = numel(c);
  yl = inf; yr = -inf;
  for k = 0:M
    fL = [fu(1:k); fl(k+1:end)];          % upper for i<=k, lower for i>k -> minimise
    if sum(fL) > 0, yl = min(yl, (fL.'*c)/sum(fL)); end
    fR = [fl(1:k); fu(k+1:end)];          % lower for i<=k, upper for i>k -> maximise
    if sum(fR) > 0, yr = max(yr, (fR.'*c)/sum(fR)); end
  end
  if ~isfinite(yl), yl = 0; end
  if ~isfinite(yr), yr = 0; end
end
