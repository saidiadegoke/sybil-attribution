function [Cr, Rank] = it2_tsk_tao_vec(X, T, R)
% IT2_TSK_TAO_VEC  Interval type-2 TSK inference exactly as specified by
% Tao et al. (2020), §IV-A-3 to §IV-A-5. Node-batched.
%
% Differs from IT2_FIS_STAGE_VEC (used by the proposed protocol) in two ways
% that are dictated by the paper and must NOT be "harmonised" with it:
%   (a) the t-norm is the PRODUCT, not the minimum   -- Tao Eq (7);
%   (b) one rule base drives TWO outputs, the competition radius Cr and the
%       cluster-head level Rank                      -- Tao Table 1.
%
%   X : M x 3 inputs [RDB, RE, ND], each already mapped to [0,1]
%   T : 1 x 3 IT2 terms from MAKE_IT2_TERMS
%   R : 27 x 5 rule base from BUILD_RULEBASE_TAO
%
% Returns Cr and Rank (M x 1), each the midpoint of its type-reduced interval
% (Tao Eq 10), which is the same defuzzification the proposed protocol uses.

  M = size(X,1); nR = size(R,1);

  % --- fuzzification: lower/upper grade of each input in each of the 3 terms
  gLo = cell(1,3); gUp = cell(1,3);
  for v = 1:3
    lo = zeros(M,3); up = zeros(M,3);
    for t = 1:3
      [a,b] = it2_grade(X(:,v), T(t));
      lo(:,t) = a; up(:,t) = b;
    end
    gLo{v} = lo; gUp{v} = up;
  end

  % --- inference: firing interval by PRODUCT t-norm (Tao Eq 7)
  fl = zeros(M,nR); fu = zeros(M,nR);
  for r = 1:nR
    fl(:,r) = gLo{1}(:,R(r,1)) .* gLo{2}(:,R(r,2)) .* gLo{3}(:,R(r,3));
    fu(:,r) = gUp{1}(:,R(r,1)) .* gUp{2}(:,R(r,2)) .* gUp{3}(:,R(r,3));
  end

  % --- type-reduction + defuzzification, once per output (Tao Eqs 8-10)
  Cr   = km_cos_vec(fl, fu, R(:,4));
  Rank = km_cos_vec(fl, fu, R(:,5));
end

% -------------------------------------------------------------------------
function y = km_cos_vec(fl, fu, c)
% Centre-of-sets Karnik-Mendel by exact switch-point enumeration, vectorised
% across nodes. The consequent singletons are node-independent, so the sort
% order (and hence the set of candidate switch points) is shared by all nodes,
% which is what makes the enumeration batchable. Same scheme as
% KM_TYPE_REDUCTION, kept local so the shared engine is untouched.
  [cs, ord] = sort(c(:));
  fl = fl(:,ord); fu = fu(:,ord);
  [M, nR] = size(fl);
  yl = inf(M,1); yr = -inf(M,1);
  for k = 0:nR
    F = [fu(:,1:k) fl(:,k+1:nR)];              % upper below switch -> minimise
    den = sum(F,2);  val = (F*cs)./den;  val(den<=0) = inf;
    yl = min(yl, val);
    G = [fl(:,1:k) fu(:,k+1:nR)];              % lower below switch -> maximise
    den2 = sum(G,2); val2 = (G*cs)./den2; val2(den2<=0) = -inf;
    yr = max(yr, val2);
  end
  y = 0.5*(yl + yr);                            % Tao Eq (10)
  y(sum(fu,2) <= 0) = 0;                        % unfired nodes
  y(~isfinite(y)) = 0;
end
