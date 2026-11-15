function R = build_rulebase(kind)
% BUILD_RULEBASE  Complete 3-input x 3-term rule base (27 rows, [a1 a2 a3 out]).
% Output term derived by a documented monotone score so the base is
% reproducible (C5); experts may override individual rows.
  [I,J,K] = ndgrid(1:3, 1:3, 1:3);
  ante = [I(:) J(:) K(:)];                 % 27 x 3  (1=Low,2=Med,3=High)
  switch kind
    case 'reliability'   % inputs: Energy, LinkQuality, Trust  (trust dominant)
      score = 0.35*ante(:,1) + 0.30*ante(:,2) + 0.35*ante(:,3);
      score(ante(:,3)==1) = min(score(ante(:,3)==1), 1.5);   % low trust -> low rel
    case 'eligibility'   % inputs: Reliability, Density, (1 - Distance) proxy
      score = 0.50*ante(:,1) + 0.25*ante(:,2) + 0.25*ante(:,3);
    otherwise
      error('build_rulebase: unknown kind "%s"', kind);
  end
  out = ones(size(score));
  out(score > 1.8) = 2;
  out(score > 2.4) = 3;
  R = [ante out];
end
