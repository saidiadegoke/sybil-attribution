function net = ch_setup(net, cfg)
% CH_SETUP  Protocol-specific set-up hook: elect CHs and form clusters.
% All protocols share the same channel/energy/metrics code; only this differs.
% Consensus (EA-PoA) is run separately in simulate() for {'proposed','eapoa'}.
%
% Sinkhole nodes advertise inflated self-reported inputs during election only
% (adversary/sinkhole_advertise.m); the true values are restored before return,
% so the spoof is identical for every protocol and touches nothing but election.
  [net, sinkSaved] = sinkhole_advertise(net, cfg);
  switch cfg.protocol
    case 'proposed',   net = proto_proposed(net, cfg);
    case 'leach',      net = proto_leach(net, cfg);
    case 'heed',       net = proto_heed(net, cfg);
    case 'eaucf',      net = proto_eaucf(net, cfg);
    case 'eflzsepfch', net = proto_eflzsepfch(net, cfg);
    case 'tao_it2',    net = proto_tao_it2(net, cfg);
    case 'eapoa',      net = proto_eflzsepfch(net, cfg);   % E-FLZSEPFCH clustering + EA-PoA
    % Cross-host attribution study: the same roster/veto mechanisms grafted onto
    % independently authored clustering protocols (see ch_eligible).
    case 'heed_secured', net = proto_heed_secured(net, cfg);
    case 'tao_secured',  net = proto_tao_secured(net, cfg);
    otherwise, error('ch_setup: protocol "%s" not implemented', cfg.protocol);
  end
  net = sinkhole_restore(net, sinkSaved);
end
