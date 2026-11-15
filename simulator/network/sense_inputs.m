function net = sense_inputs(net, cfg)
% SENSE_INPUTS  Vectorised per-round density and average-RSSI -> link quality,
% using the precomputed static geometry. Extracted so experiments (e.g.
% decision-variance) can build a realistic node state without the round loop.
  al  = double(net.alive(:));
  cnt = net.A0 * al;                               % Nx1 alive-neighbour counts
  net.rho = (cnt ./ max(max(cnt), 1)).';
  meanlog = (net.A0 .* net.log10D) * al ./ max(cnt, 1);   % Nx1 mean log10 dist
  avg = cfg.Pt - cfg.PL0 - 10*cfg.n .* meanlog.';         % 1xN mean RSSI
  avg(cnt.' == 0)  = cfg.RSSImin;
  avg(~net.alive)  = cfg.RSSImin;
  net.avgRSSI = avg;
  net.LQ = link_quality(avg, cfg);
  net.LQ(~net.alive) = 0;
end
