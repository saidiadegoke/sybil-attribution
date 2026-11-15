function e = radio_energy(bits, d, cfg)
% RADIO_ENERGY  Eqs (1)-(2): first-order radio model, vectorised over d.
  near = d < cfg.d0;
  e = cfg.Eelec*bits + bits.*(cfg.efs.*d.^2).*near + bits.*(cfg.emp.*d.^4).*(~near);
end
