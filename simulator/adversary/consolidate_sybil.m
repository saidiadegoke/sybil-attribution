function net = consolidate_sybil(net, E0)
% CONSOLIDATE_SYBIL  One attacker, one battery. Forged identities share the
% physical node's charge, so whatever the whole identity group spent in a round
% is debited once from the owner's cell and mirrored across the group. Without
% this an attacker would gain cfg.sybilIds free batteries along with its extra
% identities, which would inflate its endurance rather than its influence.
  if ~any(net.forged), return; end
  M = numel(net.x);
  drain = E0 - net.E;                                    % per-identity spend
  tot   = accumarray(net.owner(:), drain(:), [M,1]).';   % group spend per owner
  net.E = E0(net.owner) - tot(net.owner);                % mirrored remainder
  net.alive(net.E <= 0) = false;
end
