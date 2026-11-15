function L = leader_select(mem, net)
% LEADER_SELECT  Eq (7): EA-PoA leader = eligible node with highest current
% battery level (cBL := residual energy).
  [~, k] = max(net.E(mem));
  L = mem(k);
end
