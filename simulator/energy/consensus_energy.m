function e = consensus_energy(isLeader, nVal, cfg)
% CONSENSUS_ENERGY  Eq (15): EA-PoA per-node cost = sign(if leader)+relay+idle.
% Elementwise/vectorised: isLeader and nVal may be arrays of equal size (one
% entry per authority-set member). Called from eapoa_round for every
% participant, so the round's consensus energy is not charged to the leader
% alone.
  e = cfg.EM*double(isLeader) + cfg.ER*nVal + cfg.EI;
end
