function chi = it2_fis_stage(x, T, R, outCtr)
% IT2_FIS_STAGE  One 3-input IT2 Mamdani stage.
%   x      : 1x3 normalised inputs in [0,1]
%   T      : term set from make_it2_terms (3 terms)
%   R      : 27x4 rule base from build_rulebase
%   outCtr : centroids of the output terms, e.g. [0 0.5 1]
% Returns the defuzzified output chi = 0.5*(yl+yr).
  nR = size(R,1);
  fl = zeros(nR,1); fu = zeros(nR,1); cc = zeros(nR,1);
  for r = 1:nR
    lo = ones(1,3); up = ones(1,3);
    for v = 1:3
      [a,b] = it2_grade(x(v), T(R(r,v)));
      lo(v) = a; up(v) = b;
    end
    fl(r) = min(lo);            % Mamdani AND = min
    fu(r) = min(up);
    cc(r) = outCtr(R(r,4));
  end
  m = fu > 0;                   % keep fired rules
  if ~any(m), chi = 0; return; end
  [yl, yr] = km_type_reduction(fl(m), fu(m), cc(m));
  chi = 0.5 * (yl + yr);
end
