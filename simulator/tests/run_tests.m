function run_tests()
% RUN_TESTS  Run all unit/integration tests.
  test_km();
  test_rc_bounds();
  test_tao();
  test_consensus_energy();
  test_sybil();
  test_churn();
  test_sinkhole();
  test_smoke();
  fprintf('ALL TESTS PASSED\n');
end
