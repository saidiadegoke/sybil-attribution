function net = proto_tao_it2(net, cfg)
% PROTO_TAO_IT2  Baseline UCT2TSK, per Tao, Zhang & Yang (2020), IEEE Access 8,
% 197173-197183, doi:10.1109/ACCESS.2020.3034607.
%
% Faithful re-implementation of Algorithm 1 and §IV-A of the paper. The five
% features that make this UCT2TSK rather than "E-FLZSEPFCH with the FOU on":
%   1. ONE interval type-2 TSK FLS emits TWO outputs -- the competition radius
%      Cr and the cluster-head level Rank -- from the published 27-rule base
%      (Table 1). The radius is a fuzzy output, NOT a geometric function.
%   2. The t-norm is the product (Eq 7), not the minimum.
%   3. Cluster-head election is probabilistic: Tprob = Rank, a node draws
%      mu ~ U(0,1) and is a CANDIDATE only if mu < Tprob (Algorithm 1, 7-11).
%      UCT2TSK "inherits the idea of the 'turn' of LEACH" (§IV).
%   4. Candidates then compete on Rank inside the broadcast radius (12-20).
%   5. Inputs use the paper's own normalisations (Eqs 4-6), not the min-max
%      normalisation the other protocols in this harness share.
%
% No RSSI, trust, consensus, or coverage term: those are the proposed
% protocol's contributions and are deliberately absent here.

  persistent T2 R
  if isempty(T2)
    T2 = make_it2_terms(cfg.fuzzy.fou, cfg.fuzzy.hLo);
    R  = build_rulebase_tao();
  end

  N = numel(net.x);
  alive = net.alive(:).';

  % ---- Cr_max / Cr_min (Tao §V-A-1) -------------------------------------
  % The paper pins Cr_max = 100 m, Cr_min = 20 m for its 200x200 m scenario
  % (and 55 m / 15 m for the 1000x1000 m one). Here Cr_max defaults to cfg.R0
  % so the baseline competes on the SAME maximum radius as every other
  % protocol in this harness -- a matched-parameter comparison. The Cr_min/
  % Cr_max ratio of 0.2 is Tao's own (20/100). Override via cfg.tao to
  % reproduce the paper's absolute metres instead.
  CrMax = cfg.R0;  CrMin = 0.2 * CrMax;
  if isfield(cfg, 'tao')
    if isfield(cfg.tao, 'CrMax'), CrMax = cfg.tao.CrMax; end
    if isfield(cfg.tao, 'CrMin'), CrMin = cfg.tao.CrMin; end
  end

  % ---- inputs -----------------------------------------------------------
  % RDB (Eq 4): distance to BS over the largest such distance, so RDB lies in
  % (0,1] and lands on the domain of Fig. 4. Note this is a pure ratio, NOT
  % min-max: the nearest node does not get forced to 0.
  dmax = max(net.dBS(alive > 0));
  if isempty(dmax) || dmax <= 0, dmax = max(net.dBS); end
  RDB = min(net.dBS ./ max(dmax, eps), 1);

  % RE (Eq 5): absolute fraction of the INITIAL energy, not a rank among peers.
  RE = min(max(net.E ./ cfg.E0, 0), 1);

  % ND (Eq 6): alive neighbours inside the node's competition radius, over the
  % total node count. Cr is itself an FLS output, so the count uses the
  % previous round's radius; Tao sets round 1 "artificially" (§IV-B), which
  % here means the static communication range.
  if isfield(net, 'Rc') && ~isempty(net.Rc) && any(net.Rc > 0)
    Rprev = net.Rc(:);
  else
    Rprev = repmat(cfg.commRange, N, 1);
  end
  within = (net.D <= Rprev);                       % row i tested against Rprev(i)
  cnt    = (within * alive(:)).' - alive;          % exclude self
  ND     = max(cnt, 0) ./ max(N, 1);
  % Fig. 6 draws the ND terms over [0, 0.5]; rescale onto the unit domain the
  % shared triangular terms use.
  NDx = min(ND ./ 0.5, 1);

  % ---- IT2 TSK inference -> Cr and Rank ---------------------------------
  Cr = zeros(1,N); Rank = zeros(1,N);
  idx = find(net.alive);
  if ~isempty(idx)
    [crv, rkv] = it2_tsk_tao_vec([RDB(idx).', RE(idx).', NDx(idx).'], T2, R);
    Cr(idx) = crv.'; Rank(idx) = rkv.';
  end

  % Real radius = fuzzy output x Cr_max, floored at Cr_min (§IV-B).
  net.Rc  = min(max(Cr .* CrMax, CrMin), CrMax);
  net.chi = Rank;                     % Rank is this protocol's CH score

  % ---- Algorithm 1, lines 5-12: probabilistic candidacy ------------------
  mu   = rand(1, N);
  cand = net.alive & (mu < Rank);
  if ~any(cand)                       % Tao leaves this case open; fall back to
    [~, b] = max(Rank .* double(net.alive));   % the best-ranked alive node so
    cand(b) = true;                            % the round still forms a cluster
  end

  % ---- Algorithm 1, lines 13-20: competition on Rank --------------------
  % Each candidate broadcasts inside its own Cr and the lower-Rank party loses,
  % so a pair conflicts when either radius spans the gap: d <= max(Cr_i, Cr_j).
  net.role = zeros(1,N); net.cid = zeros(1,N);
  ci = find(cand);
  [~, o] = sort(Rank(ci), 'descend');
  ci = ci(o);
  chosen = [];
  for i = ci
    if isempty(chosen)
      win = true;
    else
      d   = net.D(i, chosen);
      win = ~any(d <= max(net.Rc(i), net.Rc(chosen)));
    end
    if win
      net.role(i) = 1; net.cid(i) = i;
      chosen(end+1) = i; %#ok<AGROW>
    end
  end

  % ---- Algorithm 1, lines 26-30: members join the nearest CH -------------
  % MEMBER_ASSIGN maximises a deterministic RSSI x proximity score; both terms
  % are monotone in distance here, so its argmax IS the nearest cluster head,
  % which is what line 28 specifies.
  net = member_assign(net, cfg);
end
