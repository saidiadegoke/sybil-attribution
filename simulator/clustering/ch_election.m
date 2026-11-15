function net = ch_election(net, cfg)
% CH_ELECTION  Eq (13): trust-veto-gated local-max competition on chi within Rc
% (used by the proposed protocol). Delegates to elect_competition with the
% low-trust veto as the eligibility mask.
  eligible = net.alive & (net.T >= cfg.tau);
  net = elect_competition(net, cfg, net.chi, net.Rc, eligible);
end
