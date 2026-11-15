function test_rc_bounds()
% TEST_RC_BOUNDS  Competition radius (Eq 14) always lies in [0, R0].
  set_seed(3);
  cfg = config_default();
  for t = 1:50
    net = make_topology(cfg);
    net = sense_inputs_local(net, cfg);
    for i = 1:5:cfg.N
      Rc = competition_radius(i, net, cfg);
      assert(Rc >= -1e-9 && Rc <= cfg.R0 + 1e-9, 'Rc out of [0,R0]');
    end
  end
  fprintf('test_rc_bounds: PASS\n');
end

function net = sense_inputs_local(net, cfg)
  net.nbr = neighbors(net, cfg);
  net.rho = density(net, cfg);
  for i = find(net.alive)
    nb = net.nbr{i};
    if isempty(nb), net.LQ(i) = 0; continue; end
    d = hypot(net.x(i)-net.x(nb), net.y(i)-net.y(nb));
    net.LQ(i) = link_quality(mean(rssi_model(d,cfg)), cfg);
  end
end
