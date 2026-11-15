function net = spawn_sybil(net, cfg, attackers)
% SPAWN_SYBIL  Model Sybil as what it actually is: identity forgery.
%
% Each attacker fabricates cfg.sybilIds additional network identities. A forged
% identity is NOT a new device; it is the attacker's one radio announcing itself
% under several names, so:
%   * it sits at the attacker's position (small jitter only),
%   * it draws on the attacker's single battery (mirrored in consolidate_sybil),
%   * it presents a CLEAN behavioural history (T = the deployment default, f/u
%     reset). This is the point of the attack: reputation cannot bind to an
%     identity the attacker can discard and re-mint, so a behavioural trust
%     veto alone does not stop it (Douceur, 2002).
%   * it is NOT on the deployment roster, which is the one property a
%     permissioned authority set can check.
%
% The forged identities compete for cluster-head roles and occupy cluster slots,
% giving the attacker disproportionate influence per unit of hardware. Giving
% each forged identity full participation (rather than a degraded one) makes the
% attacker stronger than a real one would be, so any defence result is
% conservative.
  m = cfg.sybilIds;
  if m <= 0 || isempty(attackers), return; end
  N = numel(net.x);
  k = numel(attackers);
  owner = reshape(repmat(attackers(:).', m, 1), 1, []);   % m ids per attacker
  M = numel(owner);

  jit = cfg.sybilJitter;
  net.x = [net.x, min(max(net.x(owner) + jit*(2*rand(1,M)-1), 0), cfg.field(1))];
  net.y = [net.y, min(max(net.y(owner) + jit*(2*rand(1,M)-1), 0), cfg.field(2))];

  net.E     = [net.E,     net.E(owner)];           % mirrors the owner's battery
  net.alive = [net.alive, net.alive(owner)];
  net.role  = [net.role,  zeros(1,M)];
  net.cid   = [net.cid,   zeros(1,M)];

  net.T     = [net.T,     cfg.T0*ones(1,M)];       % clean slate: whitewashed
  net.f     = [net.f,     ones(1,M)];
  net.u     = [net.u,     ones(1,M)];
  net.Ahat  = [net.Ahat,  ones(1,M)];

  net.Re    = [net.Re,    zeros(1,M)];
  net.chi   = [net.chi,   zeros(1,M)];
  net.Rc    = [net.Rc,    zeros(1,M)];
  net.avgRSSI = [net.avgRSSI, zeros(1,M)];
  net.LQ    = [net.LQ,    zeros(1,M)];
  net.rho   = [net.rho,   zeros(1,M)];

  net.isMal = [net.isMal, true(1,M)];
  net.atk   = [net.atk,   ones(1,M)];              % 1 = sybil

  net.forged = [net.forged, true(1,M)];
  net.remintIn = [net.remintIn, zeros(1,M)];
  net.dormant  = [net.dormant,  false(1,M)];
  net.owner  = [net.owner,  owner];
  net.roster = [net.roster, false(1,M)];           % never registered

  net = rebuild_geometry(net, cfg);
  assert(numel(net.x) == N + M, 'spawn_sybil: array growth inconsistent');
end
