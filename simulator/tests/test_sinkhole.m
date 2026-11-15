function test_sinkhole()
% TEST_SINKHOLE  A sinkhole must differ from a blackhole by attracting roles.
% Regression target: before 2026-11-15 the sinkhole was a relabelled blackhole
% (same drop rule in simulate.m, no attraction), so every result table showed
% identical blackhole and sinkhole rows.

  % (1) the spoof touches election only: true state is restored afterwards
  set_seed(3);
  cfg = config_default(); cfg.protocol = 'eflzsepfch';
  cfg.adversary = 'sinkhole'; cfg.compromised = 0.2;
  net = make_topology(cfg); net = inject_attack(net, cfg);
  net = sense_inputs(net, cfg);
  sk = find(net.atk == 3);
  assert(~isempty(sk), 'no sinkhole nodes injected');
  net.E(sk) = 0.1;                                 % drained, unattractive nodes
  E0 = net.E; LQ0 = net.LQ; d0 = net.dBS;
  net2 = ch_setup(net, cfg);
  assert(isequal(net2.E, E0) && isequal(net2.LQ, LQ0) && isequal(net2.dBS, d0), ...
         'sinkhole spoof leaked out of election');

  % (2) unsecured host: a sinkhole wins more CH roles than a blackhole
  share = @(atk, spoof) run_share(atk, spoof);
  sinkOn  = share('sinkhole', true);
  sinkOff = share('sinkhole', false);
  black   = share('blackhole', true);
  assert(abs(sinkOff - black) < 1e-12, ...
         'spoof off must reproduce the blackhole exactly');
  assert(sinkOn > black, sprintf( ...
         'sinkhole (%.4f) must out-attract blackhole (%.4f)', sinkOn, black));
  fprintf('test_sinkhole: OK (malicious-CH share sinkhole %.4f vs blackhole %.4f)\n', ...
          sinkOn, black);
end

function m = run_share(atk, spoof)
  m = 0;
  for s = 1:3
    cfg = config_default(); cfg.protocol = 'eflzsepfch'; cfg.channel = 'shadow';
    cfg.adversary = atk; cfg.compromised = 0.2; cfg.sinkholeSpoof = spoof;
    cfg.seed = s; cfg.maxRounds = 300;
    r = simulate(cfg);
    m = m + r.malCHrate / 3;
  end
end
