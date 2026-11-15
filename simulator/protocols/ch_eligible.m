function elig = ch_eligible(net, cfg)
% CH_ELIGIBLE  The cluster-head admission gate, in ONE place.
%
% Returns the mask of nodes permitted to stand for cluster head this round,
% applying the two mechanisms this study attributes:
%   roster (M_R) : ADMISSIBLE() -- only identities registered at deployment,
%                  active for permissioned protocols and toggled by
%                  cfg.ablation.permissioned.
%   veto   (M_B) : trust at or above cfg.tau, toggled by cfg.ablation.veto.
%
% Unsecured baselines (LEACH, HEED, EAUCF, E-FLZSEPFCH, Tao-IT2) carry neither,
% so this reduces to net.alive for them and their behaviour is unchanged.
%
% Factored out so that a host protocol can be "secured" by gating its candidate
% set with this one call, and so the gate cannot drift between hosts -- which is
% precisely what a cross-host attribution study needs to hold fixed.
  elig = net.alive & admissible(net, cfg);
  if isfield(net,'dormant'), elig = elig & ~net.dormant; end   % waiting to re-mint
  if is_secured(cfg) && cfg.ablation.veto
    elig = elig & (net.T >= cfg.tau);
  end
end
