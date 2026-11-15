function net = sinkhole_restore(net, saved)
% SINKHOLE_RESTORE  Undo sinkhole_advertise once election is over, so every
% later phase (energy, routing, delivery, metrics) uses the true node state.
  if isempty(saved), return; end
  net.E(saved.idx)   = saved.E;
  net.LQ(saved.idx)  = saved.LQ;
  net.dBS(saved.idx) = saved.dBS;
end
