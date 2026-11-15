function t = runs_consensus(cfg)
% RUNS_CONSENSUS  True for protocols that execute an EA-PoA round.
% Kept as one function so the round loop and the roster gate agree on which
% protocols carry a consensus layer. The secured cross-host variants run it too,
% so that the trust-feedback path (a failed proposer takes a trust penalty) is
% present on every host and the veto is compared under matched conditions.
  t = any(strcmp(cfg.protocol, {'proposed','eapoa','heed_secured','tao_secured'}));
end
