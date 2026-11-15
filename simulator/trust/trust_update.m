function net = trust_update(net, cfg)
% TRUST_UPDATE  Eq (11): blend direct behavioural trust with on-chain
% agreement, then apply exponential aging (anti on-off attack).
  direct = net.f ./ max(net.f + net.u, 1);
  Tnew   = (1 - cfg.lambda)*direct + cfg.lambda*net.Ahat;
  net.T  = (1 - cfg.eta)*net.T + cfg.eta*Tnew;
  net.T  = min(max(net.T, 0), 1);
end
