function S = run_decision_variance(seeds, sigmas, R)
% RUN_DECISION_VARIANCE  Proper C5/H5 test: does the IT2 FIS make the cluster-head
% decision more robust to input noise than a Type-1 FIS? For a fixed mid-life
% network snapshot, the CH-election (proto_proposed, veto off) is run R times with
% independent input-noise draws of std sigma; we measure (i) the mean per-node
% std of the CH-eligibility score chi, and (ii) the CH-decision flip rate vs the
% noise-free baseline. Lower = more robust. Writes results_decvar.csv + fig7.
  if nargin < 1 || isempty(seeds),  seeds  = 1:5;                 end
  if nargin < 2 || isempty(sigmas), sigmas = [0.05 0.10 0.15 0.20]; end
  if nargin < 3 || isempty(R),      R = 20;                       end
  if ~exist('figures','dir'), mkdir('figures'); end

  S = struct('it2',{},'sigma',{},'seed',{},'chiStd',{},'flipRate',{});
  for s = seeds
    set_seed(1000 + s);
    cfg = config_default(); cfg.channel = 'shadow'; cfg.ablation.veto = false;
    net = make_topology(cfg);
    net.E = cfg.E0 * (0.2 + 0.8*rand(1,cfg.N));     % spread energies (mid-life)
    net.T = 0.4 + 0.6*rand(1,cfg.N);
    net = sense_inputs(net, cfg);
    al = find(net.alive);
    for it2 = [true false]
      cb = cfg; cb.ablation.it2 = it2; cb.inputNoise = 0;
      base = proto_proposed(net, cb); baseRole = base.role;
      for sg = sigmas
        cn = cfg; cn.ablation.it2 = it2; cn.inputNoise = sg;
        chiMat = zeros(numel(al), R); flips = zeros(1, R);
        for r = 1:R
          nr = proto_proposed(net, cn);
          chiMat(:,r) = nr.chi(al).';
          flips(r) = mean(nr.role(al) ~= baseRole(al));
        end
        S(end+1) = struct('it2',it2,'sigma',sg,'seed',s, ...
          'chiStd',mean(std(chiMat,0,2)), 'flipRate',mean(flips)); %#ok<AGROW>
      end
    end
  end

  fid = fopen('results_decvar.csv','w');
  fprintf(fid,'it2,sigma,seed,chiStd,flipRate\n');
  for i = 1:numel(S)
    fprintf(fid,'%d,%.3f,%d,%.5f,%.5f\n', S(i).it2, S(i).sigma, S(i).seed, S(i).chiStd, S(i).flipRate);
  end
  fclose(fid);

  plot_decision_variance('results_decvar.csv', 'figures/fig7_decision_variance.png');

  fprintf('DECVAR_DONE rows=%d (results_decvar.csv, figures/fig7_decision_variance.png)\n', numel(S));
end
