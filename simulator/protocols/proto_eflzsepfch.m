function net = proto_eflzsepfch(net, cfg)
% PROTO_EFLZSEPFCH  Anchor baseline (Ali et al., 2024): Type-1 Mamdani CH
% election on {Energy, Density, Distance-to-BS} with a signal-blind unequal
% competition radius. No RSSI/trust/consensus. Type-1 realised by a degenerate
% FOU (fou=0, hLo=1). Vectorised.
  persistent T1 R
  if isempty(T1), T1 = make_it2_terms(0,1); R = build_rulebase('eligibility'); end
  oc = [0 0.5 1];
  Ehat = minmax_norm(net.E); dBShat = minmax_norm(net.dBS);
  net.chi(:) = 0;
  idx = find(net.alive);
  chi = it2_fis_stage_vec([Ehat(idx).', net.rho(idx).', (1-dBShat(idx)).'], T1, R, oc);
  net.chi(idx) = chi.';
  net.Rc = competition_radius_blind_all(net, cfg);
  % roster gate is a no-op for plain E-FLZSEPFCH and active for the EA-PoA
  % configuration, which is the only difference between the two baselines
  net = elect_competition(net, cfg, net.chi, net.Rc, net.alive & admissible(net, cfg));
  net = member_assign(net, cfg);
end
