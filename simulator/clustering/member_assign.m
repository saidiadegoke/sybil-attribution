function net = member_assign(net, cfg)
% MEMBER_ASSIGN  Eq (M7): each non-CH alive node joins the CH maximising the
% RSSI x proximity trade-off (with a small bonus for links above RSSImin+margin).
% Vectorised over members x CHs.
  CHs = find(net.role == 1 & net.alive);
  if isempty(CHs), return; end
  mem = find(net.alive & net.role == 0);
  if isempty(mem), return; end
  Dm = net.D(mem, CHs);                                  % Mmem x Mch
  rssi  = cfg.Pt - (cfg.PL0 + 10*cfg.n*log10(max(Dm,1)));
  rssiN = min(max((rssi - cfg.RSSImin)/(cfg.RSSImax - cfg.RSSImin), 0), 1);
  prox  = max(cfg.R0 - Dm, 0) / cfg.R0;
  okm   = double(rssi >= cfg.RSSImin + 5);              % 5 dB margin
  score = rssiN .* prox + 0.001 .* okm;
  [~, k] = max(score, [], 2);
  net.cid(mem) = CHs(k);
end
