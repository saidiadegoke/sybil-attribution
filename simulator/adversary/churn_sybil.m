function [net, nChurn] = churn_sybil(net, cfg)
% CHURN_SYBIL  Identity churn, a.k.a. whitewashing.
%
% A forged identity that has accumulated enough negative behavioural evidence to
% fall below the veto threshold has stopped being useful, so the attacker
% discards it and re-announces under a fresh name. The new identity inherits the
% attacker's radio and position (the hardware has not moved) but starts with the
% newcomer defaults: trust at cfg.T0 and the direct-evidence counters reset. The
% evidence the network spent rounds accumulating is thrown away with the name.
%
% This is the behaviour that makes a purely behavioural defence structurally
% unable to converge on a Sybil attacker (Douceur, 2002): the evidence clock
% restarts faster than the evidence accrues, so the attacker holds a permanent
% duty cycle of eligibility instead of a single early breach. A permissioned
% roster is untouched by it, because a fresh name is off-roster in its first
% round exactly as the discarded one was, and no evidence is required to refuse
% it.
%
% Note the attacker only churns when trust is what excluded it. Under a roster
% it is refused on identity, which re-minting cannot cure, so churn is futile
% there and correctly makes no difference.
%
% cfg.churnDelay (delta) is the number of rounds an abandoned identity waits
% before the attacker re-announces it. delta = 0 re-mints in the same round the
% identity is burned, which is the paper's default and the strongest adversary.
% Larger delta models an attacker who cannot re-announce instantly, and lets the
% k/(k+delta) duty cycle of Proposition 2 be tested directly.
%
% Sensitivity knobs (added 2026-11-15; the defaults reproduce every earlier run):
%   cfg.newcomerT0      trust a RE-MINTED identity starts with (default cfg.T0).
%                       Deployment-time identities keep cfg.T0, because without
%                       a roster the network cannot tell them from genuine nodes;
%                       it can only treat identities that appear later differently.
%   cfg.sybilMintBudget total re-mints allowed per attacker (default Inf). A
%                       burned identity whose owner has spent its budget retires:
%                       it goes dormant for good and can hold no role.
%   cfg.sybilMintCost   energy (J) debited from the attacker's one battery per
%                       re-mint (default 0), mirrored across its identity group.
  nChurn = 0;
  if ~cfg.sybilChurn || ~any(net.forged), return; end
  if ~isfield(net,'mintsUsed'), net.mintsUsed = zeros(1, numel(net.x)); end
  if numel(net.mintsUsed) < numel(net.x)
    net.mintsUsed(end+1:numel(net.x)) = 0;
  end
  if isfield(cfg,'churnDelay'), delay = cfg.churnDelay; else, delay = 0; end

  % Nodes already waiting out a delay: tick the counter down, and re-mint the
  % ones whose wait has expired.
  waiting = net.remintIn > 0;
  if any(waiting)
    net.remintIn(waiting) = net.remintIn(waiting) - 1;
    due = waiting & (net.remintIn == 0);
    if any(due)
      net = do_remint(net, cfg, due);
      nChurn = nChurn + sum(due);
    end
  end

  % Newly burned identities: re-mint now if delta = 0, else start their wait.
  burned = net.forged & net.alive & (net.T < cfg.tau) & (net.remintIn == 0) & ~net.dormant;
  % Mint budget: identities whose owner has no re-mints left retire for good.
  if isfield(cfg,'sybilMintBudget') && isfinite(cfg.sybilMintBudget) && any(burned)
    out = burned & (net.mintsUsed(net.owner) >= cfg.sybilMintBudget);
    if any(out)
      net.dormant(out) = true;   net.remintIn(out) = 0;
      net.role(out) = 0;         net.cid(out) = 0;
      burned = burned & ~out;
    end
  end
  if any(burned)
    if delay <= 0
      net = do_remint(net, cfg, burned);
      nChurn = nChurn + sum(burned);
    else
      net.remintIn(burned) = delay;
      net.dormant(burned)  = true;   % off the air, so it cannot hold a role
      net.role(burned) = 0; net.cid(burned) = 0;
    end
  end
end

function net = do_remint(net, cfg, idx)
% The whitewash: same radio, same position, new name, newcomer's trust.
  if isfield(cfg,'newcomerT0') && ~isempty(cfg.newcomerT0), T0n = cfg.newcomerT0;
  else, T0n = cfg.T0; end
  net.T(idx)    = T0n;
  % Budget and cost are charged per re-mint to the physical owner.
  ids = find(idx);
  if isfield(net,'mintsUsed')
    for i = ids, net.mintsUsed(net.owner(i)) = net.mintsUsed(net.owner(i)) + 1; end
  end
  if isfield(cfg,'sybilMintCost') && cfg.sybilMintCost > 0
    for i = ids
      o = net.owner(i);
      net.E(o) = net.E(o) - cfg.sybilMintCost;
      grp = (net.owner == o);
      net.E(grp) = net.E(o);                    % one battery, mirrored
      if net.E(o) <= 0, net.alive(grp) = false; end
    end
  end
  net.f(idx)    = 1;
  net.u(idx)    = 1;
  net.Ahat(idx) = 1;
  net.role(idx) = 0;
  net.cid(idx)  = 0;
  net.dormant(idx)  = false;
  net.remintIn(idx) = 0;
end
