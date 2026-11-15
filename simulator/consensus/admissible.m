function m = admissible(net, cfg)
% ADMISSIBLE  Permissioned-identity gate over the authority tier.
%
% Protocols carrying a Proof-of-Authority authority set (proposed, eapoa) admit
% only identities registered at deployment (net.roster). Protocols without one
% (LEACH, HEED, EAUCF, E-FLZSEPFCH, Tao-IT2) accept any identity that announces
% itself, which is exactly the opening a Sybil attacker exploits.
%
% This is the structural defence Douceur (2002) identifies: a trusted, closed
% authority set is necessary against Sybil, because behavioural reputation
% cannot bind to an identity the attacker can discard and re-mint.
  if is_permissioned(cfg)
    m = net.roster;
  else
    m = true(1, numel(net.x));
  end
end
