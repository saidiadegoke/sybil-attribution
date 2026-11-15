function net = proto_proposed(net, cfg)
% PROTO_PROPOSED  ST-IT2FUC set-up phase (vectorised, ablation-aware).
% Honours cfg.ablation toggles so the same code serves the full protocol and
% the C1/C2/C3/C5 ablations:
%   ablation.it2          : IT2 FIS (true) vs Type-1 FIS (false)
%   ablation.crispSelector: replace the FIS with a crisp weighted-sum selector
%   ablation.signalRc     : signal-/coverage-aware Rc (true) vs blind Rc (false)
%   ablation.veto         : low-trust veto on (true) / off (false)
%   cfg.inputNoise        : Gaussian noise added to normalised FIS inputs (H5)
  ab = cfg.ablation;
  Ehat = minmax_norm(net.E); dBShat = minmax_norm(net.dBS);
  net.Re(:) = 0; net.chi(:) = 0;

  elig = ch_eligible(net, cfg);                  % roster (anti-Sybil) + low-trust veto
  idx = find(elig);

  if ~isempty(idx)
    E   = Ehat(idx).';   LQ = net.LQ(idx).';  Tr = net.T(idx).';
    rho = net.rho(idx).'; D1 = (1 - dBShat(idx)).';
    if cfg.inputNoise > 0
      pert = @(v) min(max(v + cfg.inputNoise*randn(size(v)), 0), 1);
      E = pert(E); LQ = pert(LQ); Tr = pert(Tr); rho = pert(rho); D1 = pert(D1);
    end
    if ab.crispSelector
      w = cfg.crispW;
      chi = w(1)*E + w(2)*D1 + w(3)*LQ + w(4)*Tr;       % crisp weighted sum (A2)
    else
      if ab.it2, T = make_it2_terms(cfg.fuzzy.fou, cfg.fuzzy.hLo);
      else,      T = make_it2_terms(0, 1);              % Type-1 (degenerate FOU)
      end
      R1 = build_rulebase('reliability'); R2 = build_rulebase('eligibility');
      oc = [0 0.5 1];
      Re = it2_fis_stage_vec([E LQ Tr], T, R1, oc);
      net.Re(idx) = Re.';
      chi = it2_fis_stage_vec([Re rho D1], T, R2, oc);
    end
    net.chi(idx) = chi.';
  end

  if ab.signalRc, net.Rc = competition_radius_all(net, cfg);
  else,           net.Rc = competition_radius_blind_all(net, cfg);
  end
  net = elect_competition(net, cfg, net.chi, net.Rc, elig);   % Eq 13 (veto via elig)
  net = member_assign(net, cfg);
end
