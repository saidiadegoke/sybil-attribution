function test_smoke()
% TEST_SMOKE  End-to-end: the proposed protocol runs, energy is non-increasing,
% alive-count is monotone non-increasing, and lifetimes are ordered.
  cfg = config_default();
  cfg.maxRounds = 400;
  res = simulate(cfg);
  assert(res.rounds > 0, 'no rounds executed');
  assert(all(diff(res.energy) <= 1e-9), 'total energy increased');
  assert(all(diff(res.alive) <= 0), 'alive count increased');
  assert(res.FND >= 1 && res.FND <= res.HND && res.HND <= res.LND, 'FND<=HND<=LND violated');
  assert(res.PDRmean >= 0 && res.PDRmean <= 1, 'PDR out of range');
  fprintf('test_smoke: PASS  (FND=%d HND=%d LND=%d PDR=%.3f Jain=%.3f)\n', ...
          res.FND, res.HND, res.LND, res.PDRmean, res.Jmean);
end
