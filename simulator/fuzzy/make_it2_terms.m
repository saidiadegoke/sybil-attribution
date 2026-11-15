function T = make_it2_terms(fou, hLo)
% MAKE_IT2_TERMS  Three IT2 triangular terms {Low,Med,High} over [0,1].
% Upper MF = principal triangle widened by 'fou'; lower MF = narrowed and
% scaled to height hLo. Returns a 1x3 struct array.
  ctr = [0 0.5 1];  w = 0.5;
  T = struct('aU',{},'bU',{},'cU',{},'aL',{},'bL',{},'cL',{},'hL',{});
  for k = 1:3
    a = ctr(k)-w; b = ctr(k); c = ctr(k)+w;
    T(k).aU = a-fou; T(k).bU = b; T(k).cU = c+fou;     % upper (widened)
    T(k).aL = a+fou; T(k).bL = b; T(k).cL = c-fou;     % lower (narrowed)
    T(k).hL = hLo;
  end
end
