function test_tao()
% TEST_TAO  Guards the UCT2TSK baseline (Tao et al., 2020) against the defect it
% used to have: proto_tao_it2 was proto_eflzsepfch with the FOU switched on, so
% the two "different" baselines produced near-identical results. Each assertion
% below pins one feature of the paper that the old version dropped.

  cfg = config_default();

  % --- 1. the rule base is Tao's Table 1, not a reconstruction --------------
  R = build_rulebase_tao();
  assert(size(R,1) == 27 && size(R,2) == 5, 'rule base must be 27 x [3 ante + Cr + Rank]');
  assert(size(unique(R(:,1:3), 'rows'), 1) == 27, 'antecedent grid incomplete or duplicated');
  pick = @(a,b,c) R(R(:,1)==a & R(:,2)==b & R(:,3)==c, 4:5);
  % the four extremes Tao states in prose (§IV-A-2)
  v = pick(3,3,1); assert(abs(v(1) - 1) < 1e-12, 'Far/High/Low must give Cr = 1');
  v = pick(1,1,3); assert(abs(v(1) - 0) < 1e-12, 'Close/Low/High must give Cr = 0');
  v = pick(1,3,3); assert(abs(v(2) - 1) < 1e-12, 'Close/High/High must give Rank = 1');
  v = pick(3,1,1); assert(abs(v(2) - 0) < 1e-12, 'Far/Low/Low must give Rank = 0');

  % --- 2. inference uses the product t-norm (Eq 7), not the minimum ---------
  T = make_it2_terms(cfg.fuzzy.fou, cfg.fuzzy.hLo);
  % a point where product and min differ measurably in the upper firing level
  x = [0.35 0.35 0.35];
  gU = zeros(1,3);
  for v3 = 1:3, [~, gU(v3)] = it2_grade(x(v3), T(2)); end
  assert(abs(prod(gU) - min(gU)) > 1e-3, 'test point cannot discriminate product from min');
  [Cr, Rank] = it2_tsk_tao_vec(x, T, R);
  assert(all(Cr >= 0 & Cr <= 1) && all(Rank >= 0 & Rank <= 1), 'outputs must lie in [0,1]');

  % monotonic in the directions Table 1 encodes
  [Cr2, Rk2] = it2_tsk_tao_vec([0.1 0.9 0.2; 0.9 0.1 0.8], T, R);
  assert(Rk2(1) > Rk2(2), 'a close, energetic node must outrank a far, drained one');
  assert(Cr2(2) > Cr2(1), 'a far node must claim a larger competition radius');

  % --- 3. the radius is a fuzzy OUTPUT, not the geometric blind radius ------
  set_seed(11);
  net = make_topology(cfg);
  net = sense_inputs(net, cfg);
  net = trust_update(net, cfg);
  netT = proto_tao_it2(net, cfg);
  CrMin = 0.2 * cfg.R0;
  assert(all(netT.Rc >= CrMin - 1e-9 & netT.Rc <= cfg.R0 + 1e-9), 'Rc outside [Cr_min, Cr_max]');
  assert(std(netT.Rc) > 1e-6, 'Rc is constant -- the fuzzy radius is not wired up');
  Rblind = competition_radius_blind_all(net, cfg);
  assert(max(abs(netT.Rc - Rblind)) > 1e-6, 'Rc equals the signal-blind geometric radius');

  % --- 4. election is probabilistic (Algorithm 1, lines 7-11) ---------------
  set_seed(21); a = proto_tao_it2(net, cfg);
  set_seed(22); b = proto_tao_it2(net, cfg);
  assert(~isequal(a.role, b.role), 'CH set is RNG-independent -- candidacy draw is missing');

  % --- 5. the regression itself: Tao must not collapse onto E-FLZSEPFCH -----
  set_seed(31); nT = proto_tao_it2(net, cfg);
  set_seed(31); nE = proto_eflzsepfch(net, cfg);
  assert(~isequal(nT.role, nE.role), 'Tao and E-FLZSEPFCH elect the same CHs');

  fprintf('test_tao: PASS (Rc spread %.1f-%.1f m, %d CHs vs %d for E-FLZSEPFCH)\n', ...
          min(netT.Rc), max(netT.Rc), sum(nT.role == 1), sum(nE.role == 1));
end
