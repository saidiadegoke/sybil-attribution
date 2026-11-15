function lq = link_quality(avgRSSI, cfg)
% LINK_QUALITY  Eq (10): fuse normalised RSSI, LQI (proxy), and PRR into [0,1].
  rssiN = min(max((avgRSSI - cfg.RSSImin) ./ (cfg.RSSImax - cfg.RSSImin), 0), 1);
  [~, prr] = ber_pdr(avgRSSI, cfg);
  lqiN = rssiN;                            % LQI proxy (monotone in RSSI on motes)
  lq = cfg.wLQ(1)*rssiN + cfg.wLQ(2)*lqiN + cfg.wLQ(3)*prr;
  lq = min(max(lq, 0), 1);
end
