function p = weak_link(d, cfg)
% WEAK_LINK  Eq (M1): probability RSSI(d) < RSSImin under log-normal shadowing.
  p = qfunc((cfg.Pt - cfg.PL0 - 10*cfg.n*log10(max(d,1)) - cfg.RSSImin) / cfg.sigma);
end
