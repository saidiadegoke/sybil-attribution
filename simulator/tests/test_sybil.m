function test_sybil()
% TEST_SYBIL  Sybil must be modelled as identity forgery, not as a flag.
% Regression target: an earlier version set net.atk=1 and nothing else, so a
% "Sybil" node was indistinguishable from an honest one at both the consensus
% and the data plane, and the permissioned authority set had nothing to defend
% against.
  set_seed(7);
  cfg = config_default(); cfg.protocol = 'eflzsepfch';
  cfg.adversary = 'sybil'; cfg.compromised = 0.2; cfg.sybilIds = 3;

  net = make_topology(cfg);
  N0 = numel(net.x);
  net = inject_attack(net, cfg);

  k = round(cfg.compromised * cfg.N);
  % (1) identities are actually fabricated, and the arrays grow consistently
  assert(numel(net.x) == N0 + k*cfg.sybilIds, 'forged identities not created');
  assert(sum(net.forged) == k*cfg.sybilIds, 'forged mask wrong');
  flds = {'x','y','E','alive','role','cid','T','f','u','Ahat','Re','chi','Rc', ...
          'avgRSSI','LQ','rho','isMal','atk','forged','owner','roster','dBS'};
  for i = 1:numel(flds)
    assert(numel(net.(flds{i})) == numel(net.x), ...
           sprintf('field %s not grown', flds{i}));
  end
  assert(all(size(net.D) == [numel(net.x) numel(net.x)]), 'geometry not rebuilt');

  % (2) a forged identity is off-roster and presents a clean history
  f = find(net.forged);
  assert(~any(net.roster(f)), 'forged identity must not be on the roster');
  assert(all(net.T(f) == 0.7), 'forged identity must present a clean slate');
  assert(all(net.owner(f) ~= f), 'forged identity must point at a physical owner');
  assert(all(net.isMal(net.owner(f))), 'owner must be an attacker');

  % (3) forged identities sit on the attacker's radio, not somewhere else
  d = hypot(net.x(f) - net.x(net.owner(f)), net.y(f) - net.y(net.owner(f)));
  assert(all(d <= cfg.sybilJitter*sqrt(2) + 1e-9), 'forged identity displaced');

  % (4) ONE battery: a round's spend across an identity group hits the owner once
  E0 = net.E;
  net2 = net; net2.E(f(1)) = net2.E(f(1)) - 0.01;   % a forged identity transmits
  net2 = consolidate_sybil(net2, E0);
  own = net.owner(f(1));
  grp = find(net.owner == own);
  assert(abs(net2.E(own) - (E0(own) - 0.01)) < 1e-12, 'spend not charged to owner');
  assert(all(abs(net2.E(grp) - net2.E(own)) < 1e-12), 'battery not mirrored');

  % (5) the roster gate admits forged identities to an unpermissioned protocol
  %     and refuses them under PoA -- the whole point of the experiment
  cfgU = cfg; cfgU.protocol = 'eflzsepfch';
  cfgP = cfg; cfgP.protocol = 'eapoa';
  assert(~is_permissioned(cfgU) &&  any(admissible(net, cfgU)(f)), ...
         'unpermissioned protocol should admit forged identities');
  assert( is_permissioned(cfgP) && ~any(admissible(net, cfgP)(f)), ...
         'permissioned protocol must refuse forged identities');

  % (6) end to end: forged identities win CH roles without a roster, none with
  ru = simulate(setfield(cfg, 'maxRounds', 300));                    %#ok<SFLD>
  rp = simulate(setfield(setfield(cfg,'protocol','eapoa'), 'maxRounds', 300)); %#ok<SFLD>
  assert(ru.sybCHrate > 0.05, ...
         sprintf('unsecured run should admit forged CHs (got %.4f)', ru.sybCHrate));
  assert(rp.sybCHrate == 0, ...
         sprintf('EA-PoA must admit no forged CH (got %.4f)', rp.sybCHrate));

  fprintf(['test_sybil: PASS (%d forged ids; forged-CH share %.3f unsecured ' ...
           'vs %.3f permissioned)\n'], sum(net.forged), ru.sybCHrate, rp.sybCHrate);
end
