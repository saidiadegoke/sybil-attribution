function net = make_topology(cfg)
% MAKE_TOPOLOGY  Uniform-random node field (struct-of-arrays) with precomputed
% STATIC geometry matrices (positions never move), so per-round neighbour /
% density / overlap / RSSI become vectorised matrix ops.
  N = cfg.N;
  net.x = rand(1,N) * cfg.field(1);
  net.y = rand(1,N) * cfg.field(2);
  net.E  = repmat(cfg.E0, 1, N);
  net.E0 = cfg.E0;
  net.alive = true(1,N);
  net.role  = zeros(1,N);
  net.cid   = zeros(1,N);
  net.dBS   = hypot(net.x - cfg.BS(1), net.y - cfg.BS(2));
  net.T     = cfg.T0 * ones(1,N);
  net.f     = ones(1,N);  net.u = ones(1,N);  net.Ahat = ones(1,N);
  net.Re    = zeros(1,N); net.chi = zeros(1,N); net.Rc = zeros(1,N);
  net.avgRSSI = zeros(1,N); net.LQ = zeros(1,N); net.rho = zeros(1,N);
  net.isMal = false(1,N); net.atk = zeros(1,N);

  % ---- identity model (Sybil) ----
  % forged : identity fabricated by an attacker rather than deployed
  % owner  : index of the physical node behind the identity (self if genuine)
  % roster : registered in the permissioned authority set at deployment. A PoA
  %          protocol admits only roster identities to the authority tier; a
  %          protocol without an authority set accepts any identity that
  %          announces itself, which is what a Sybil attacker exploits.
  net.forged = false(1,N);
  % Re-mint bookkeeping for the churn-delay ablation: remintIn counts down the
  % rounds an abandoned identity waits before re-announcing, and dormant marks
  % an identity that is off the air while it waits.
  net.remintIn = zeros(1,N);  net.dormant = false(1,N);
  % Ledger-integrity counters (network-level Master Blockchain abstraction).
  net.ledger = struct('height',0, 'commits',0, 'advCommits',0, ...
                      'forkAtt',0, 'forkOk',0, 'rewriteAtt',0, 'rewriteOk',0, ...
                      'unauthAtt',0, 'unauthOk',0);
  net.owner  = 1:N;
  net.roster = true(1,N);

  net = rebuild_geometry(net, cfg);
end

