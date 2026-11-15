function test_churn()
% TEST_CHURN  Identity churn (whitewashing) must restart the evidence clock, so
% that a behavioural veto never converges on a Sybil attacker while a
% permissioned roster is unaffected.
  base = config_default();
  base.protocol='proposed'; base.channel='shadow';
  base.adversary='sybil'; base.compromised=0.2; base.seed=1; base.maxRounds=400;

  % (1) a burned identity is re-minted to the newcomer default
  cfg = base; cfg.ablation.permissioned = false;
  set_seed(cfg.seed);
  net = make_topology(cfg); net = inject_attack(net, cfg);
  f = find(net.forged);
  net.T(f(1)) = 0.1;                             % below tau: veto would fire
  [net2, n] = churn_sybil(net, cfg);
  assert(n >= 1, 'churn did not fire on a burned identity');
  assert(abs(net2.T(f(1)) - cfg.T0) < 1e-12, 'trust not reset to newcomer default');
  assert(net2.f(f(1)) == 1 && net2.u(f(1)) == 1, 'evidence counters not reset');
  assert(net2.x(f(1)) == net.x(f(1)), 'churn must not move the attacker radio');

  % (2) churn disabled leaves the burned identity burned
  cfgN = cfg; cfgN.sybilChurn = false;
  [net3, n3] = churn_sybil(net, cfgN);
  assert(n3 == 0 && net3.T(f(1)) == 0.1, 'churn fired while disabled');

  % (3) genuine nodes are never whitewashed
  g = find(~net.forged);
  net4 = net; net4.T(g) = 0.05;
  net4 = churn_sybil(net4, cfg);
  assert(all(net4.T(g) == 0.05), 'churn must not touch genuine nodes');

  % (4) end to end: with only a behavioural veto, churn keeps the attacker in
  %     play; with the roster, churn changes nothing
  vChurn = simulate(setfield(cfg, 'sybilChurn', true));   %#ok<SFLD>
  vOnce  = simulate(setfield(cfg, 'sybilChurn', false));  %#ok<SFLD>
  assert(vChurn.churnTotal > 0, 'no re-mints recorded under churn');
  assert(vOnce.churnTotal == 0, 're-mints recorded with churn disabled');
  assert(vChurn.sybCHrate > 5*vOnce.sybCHrate, ...
    sprintf('churn should sustain forged-CH capture (%.4f vs one-shot %.4f)', ...
            vChurn.sybCHrate, vOnce.sybCHrate));

  cfgR = base;                                    % roster on (default)
  rChurn = simulate(setfield(cfgR, 'sybilChurn', true));   %#ok<SFLD>
  rOnce  = simulate(setfield(cfgR, 'sybilChurn', false));  %#ok<SFLD>
  assert(rChurn.sybCHrate == 0 && rOnce.sybCHrate == 0, ...
         'roster must hold at zero regardless of churn');

  fprintf(['test_churn: PASS (veto-only forged-CH %.4f churn vs %.4f one-shot; ' ...
           'roster 0.0000 either way)\n'], vChurn.sybCHrate, vOnce.sybCHrate);
end
