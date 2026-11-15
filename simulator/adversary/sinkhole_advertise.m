function [net, saved] = sinkhole_advertise(net, cfg)
% SINKHOLE_ADVERTISE  Make sinkhole nodes advertise attractive election inputs.
%
% A sinkhole attracts traffic by looking like the best next hop, then drops it.
% In a clustered WSN the attraction happens at cluster-head election, so a
% sinkhole node (atk == 3) reports the best values it can plausibly claim for
% the inputs a node SELF-REPORTS:
%   residual energy        -> a full battery, cfg.E0
%   link quality           -> 1 (the top of the scale)
%   distance to the BS     -> the smallest distance among alive nodes
% Density (rho) is NOT spoofed: it is a neighbour count that the neighbours
% observe, not a value the node announces about itself.
%
% Trust is NOT spoofed: it is computed by the network from observed forwarding
% behaviour, so the behavioural veto still sees the drops.
%
% The real values are returned in SAVED, and sinkhole_restore puts them back
% straight after election, so energy accounting, routing and the data phase use
% the node's true state. Before 2026-11-15 a sinkhole was a relabelled
% blackhole (same drop rule, no attraction); set cfg.sinkholeSpoof = false to
% reproduce that old behaviour.
  saved = [];
  if ~isfield(cfg, 'sinkholeSpoof') || ~cfg.sinkholeSpoof, return; end
  if ~isfield(net, 'atk'), return; end
  sk = find(net.atk == 3 & net.isMal & net.alive);
  if isempty(sk), return; end

  saved = struct('idx', sk, 'E', net.E(sk), 'LQ', net.LQ(sk), 'dBS', net.dBS(sk));
  alive = net.alive;
  net.E(sk)   = cfg.E0;
  net.LQ(sk)  = 1;
  net.dBS(sk) = min(net.dBS(alive));
end
