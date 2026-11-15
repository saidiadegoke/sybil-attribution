function rssi = rssi_model(d, cfg)
% RSSI_MODEL  Eqs (5)-(6): log-normal-shadowing path loss -> RSSI (dBm).
% 'ideal' channel sets the shadowing term to zero.
  if strcmp(cfg.channel, 'ideal')
    X = 0;
  else
    X = cfg.sigma * randn(size(d));
  end
  PL = cfg.PL0 + 10 * cfg.n * log10(max(d,1)) + X;
  rssi = cfg.Pt - PL;
end
