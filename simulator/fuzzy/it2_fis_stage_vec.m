function chi = it2_fis_stage_vec(X, T, R, outCtr)
% IT2_FIS_STAGE_VEC  Node-batched IT2 Mamdani stage.
%   X      : M x 3 normalised inputs (M nodes)
%   T      : 3 IT2 terms (make_it2_terms)
%   R      : 27 x 4 rule base (build_rulebase)
%   outCtr : output-term centroids, e.g. [0 0.5 1]
% Returns chi (M x 1). KM is vectorised across nodes: consequent centroids are
% node-independent, so the rule sort order (hence switch points) is shared.
  M = size(X,1); nR = size(R,1);
  gLo = cell(1,3); gUp = cell(1,3);
  for v = 1:3
    lo = zeros(M,3); up = zeros(M,3);
    for t = 1:3
      [a,b] = it2_grade(X(:,v), T(t));
      lo(:,t) = a; up(:,t) = b;
    end
    gLo{v} = lo; gUp{v} = up;
  end
  fl = zeros(M,nR); fu = zeros(M,nR); cv = zeros(nR,1);
  for r = 1:nR
    fl(:,r) = min(min(gLo{1}(:,R(r,1)), gLo{2}(:,R(r,2))), gLo{3}(:,R(r,3)));
    fu(:,r) = min(min(gUp{1}(:,R(r,1)), gUp{2}(:,R(r,2))), gUp{3}(:,R(r,3)));
    cv(r)   = outCtr(R(r,4));
  end
  [cs, ord] = sort(cv); fl = fl(:,ord); fu = fu(:,ord);
  yl = inf(M,1); yr = -inf(M,1);
  for k = 0:nR
    F = [fu(:,1:k) fl(:,k+1:nR)];                 % minimise -> y_l
    den = sum(F,2); val = (F*cs)./den; val(den<=0) = inf;
    yl = min(yl, val);
    G = [fl(:,1:k) fu(:,k+1:nR)];                 % maximise -> y_r
    den2 = sum(G,2); val2 = (G*cs)./den2; val2(den2<=0) = -inf;
    yr = max(yr, val2);
  end
  chi = 0.5*(yl + yr);
  chi(sum(fu,2) <= 0) = 0;                        % unfired nodes
  chi(~isfinite(chi)) = 0;
end
