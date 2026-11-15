function S = attr_adversary(seeds, outfile, atks)
% ATTR_ADVERSARY  Population-separated security sweep at a publishable seed
% budget. Same factor grid as the source study's run_adversary, but the output
% path is a parameter so seed shards can run in parallel without collision.
%
% Columns: malCHrate (aggregate admission), sybCH (forged-identity CH share),
% blkRej (quorum activity), PDRwin (common-window delivery).
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_adversary_20.csv'; end
  % optional third argument: run a subset of attacks (used for the 2026-11-15
  % sinkhole rerun after the sinkhole was given real election attraction)
  if nargin < 3 || isempty(atks), atks = {'sybil','blackhole','sinkhole'}; end
  protos = {'eflzsepfch','eapoa','proposed'};
  fracs  = [0.1 0.2 0.3];
  rows = {};
  for ip = 1:numel(protos)
    for ia = 1:numel(atks)
      for fr = fracs
        for s = seeds
          cfg = config_default();
          cfg.protocol = protos{ip}; cfg.channel = 'shadow';
          cfg.adversary = atks{ia};  cfg.compromised = fr;
          cfg.seed = s; cfg.maxRounds = 2000;
          r = simulate(cfg);
          rows{end+1} = sprintf('%s,%s,%.2f,%d,%.6f,%d,%d,%.6f,%.6f,%.6f,%.6f,%.3f', ...
            protos{ip}, atks{ia}, fr, s, r.malCHrate, r.HND, r.LND, ...
            r.PDRmean, r.PDRwin, r.blkRejRate, r.sybCHrate, r.sybMemMean);
          fflush(stdout);
        end
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'protocol,attack,frac,seed,malCHrate,HND,LND,PDR,PDRwin,blkRej,sybCH,sybMem\n');
  for i = 1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows);
  printf('ADV_DONE rows=%d -> %s\n', S, outfile);
end
