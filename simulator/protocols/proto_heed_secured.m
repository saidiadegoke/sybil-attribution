function net = proto_heed_secured(net, cfg)
% PROTO_HEED_SECURED  HEED (Younis & Fahmy, 2004) as a SECOND HOST for the
% roster/veto attribution study.
%
% The election is HEED's, unchanged: cluster-head probability proportional to
% residual energy, plus a coverage guarantee promoting uncovered nodes. The one
% difference from PROTO_HEED is that the candidate set is gated by CH_ELIGIBLE.
%
% HEED is chosen as the second host precisely because its election is
% TRUST-BLIND: residual energy and coverage decide, and trust plays no part.
% The proposed host's election consumes trust as a graded antecedent even with
% the veto disabled, which is the mechanism behind the displacement effect. If
% displacement survives here it is a property of competition for a bounded
% resource; if it vanishes, it was a property of the fuzzy election.
  N = numel(net.x);
  net.role = zeros(1,N); net.cid = zeros(1,N); net.Rc = zeros(1,N);
  Ehat = minmax_norm(net.E);
  Cprob = 0.10; pmin = 0.005;

  elig  = ch_eligible(net, cfg);              % <-- the only change from HEED
  cands = find(elig);
  if isempty(cands), net = member_assign(net, cfg); return; end

  chprob = min(max(Cprob .* Ehat(cands), pmin), 1);
  chs = cands(rand(1, numel(cands)) < chprob);
  % coverage guarantee: eligible nodes with no CH in comm range become CH.
  % Gated too, so the coverage path cannot admit a vetoed or off-roster node.
  if isempty(chs)
    covered = false(1,N);
  else
    covered = any(net.D(:, chs) <= cfg.commRange, 2).';
  end
  chs = unique([chs, find(elig & ~covered)]);
  if isempty(chs), chs = cands(1); end
  net.role(chs) = 1; net.cid(chs) = chs;
  net = member_assign(net, cfg);
end
