function e = radio_energy_eff(bits, d, cfg)
% RADIO_ENERGY_EFF  Eq (M5): retransmission-aware Tx energy = E_Tx / P_success.
% Under the ideal channel this equals the plain radio energy.
  e = radio_energy(bits, d, cfg);
  if ~strcmp(cfg.channel, 'ideal')
    e = e ./ max(1 - weak_link(d, cfg), 0.05);
  end
end
