function S = run_adversary(seeds, fracs)
% RUN_ADVERSARY  Scenario S4: malicious-CH admission and lifetime/PDR under
% Sybil / blackhole / sinkhole attacks at several compromised fractions, for the
% unsecured baseline (eflzsepfch), EA-PoA (consensus, no fuzzy-trust veto), and
% the proposed protocol (trust veto + EA-PoA). Writes results_adversary.csv.
  if nargin < 1 || isempty(seeds), seeds = 1:5; end
  if nargin < 2 || isempty(fracs), fracs = [0.1 0.2 0.3]; end
  protos = {'eflzsepfch','eapoa','proposed'};
  atks   = {'sybil','blackhole','sinkhole'};
  S = struct('protocol',{},'attack',{},'frac',{},'seed',{}, ...
             'malCHrate',{},'LND',{},'PDR',{},'PDRwin',{},'blkRej',{},'sybCH',{},'sybMem',{});
  for ip = 1:numel(protos)
    for ia = 1:numel(atks)
      for fr = fracs
        for s = seeds
          cfg = config_default();
          cfg.protocol = protos{ip}; cfg.channel = 'shadow';
          cfg.adversary = atks{ia};  cfg.compromised = fr;
          cfg.seed = s; cfg.maxRounds = 2000;
          r = simulate(cfg);
          S(end+1) = struct('protocol',protos{ip},'attack',atks{ia}, ...
            'frac',fr,'seed',s,'malCHrate',r.malCHrate,'LND',r.LND, ...
            'PDR',r.PDRmean,'PDRwin',r.PDRwin,'blkRej',r.blkRejRate, ...
            'sybCH',r.sybCHrate,'sybMem',r.sybMemMean); %#ok<AGROW>
        end
      end
    end
  end
  fid = fopen('results_adversary.csv','w');
  fprintf(fid,'protocol,attack,frac,seed,malCHrate,LND,PDR,PDRwin,blkRej,sybCH,sybMem\n');
  for i = 1:numel(S)
    fprintf(fid,'%s,%s,%.2f,%d,%.4f,%d,%.4f,%.4f,%.4f,%.4f,%.3f\n', S(i).protocol, S(i).attack, ...
      S(i).frac, S(i).seed, S(i).malCHrate, S(i).LND, S(i).PDR, S(i).PDRwin, S(i).blkRej, ...
      S(i).sybCH, S(i).sybMem);
  end
  fclose(fid);
  fprintf('\nADV_COMPLETE rows=%d (results_adversary.csv)\n', numel(S));
end
