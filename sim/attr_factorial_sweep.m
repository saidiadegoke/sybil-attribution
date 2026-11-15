function S = attr_factorial_sweep(seeds, outfile)
% ATTR_FACTORIAL_SWEEP  The roster x veto factorial swept across attacker
% fractions, so that mechanism attribution can be read as a curve rather than
% at a single operating point. This is the paper's headline figure: four
% ablation arms x three attacker fractions, with both adversary populations
% counted separately at every point.
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_factorial_sweep.csv'; end
  arms = { 'Roster+Veto', 1, 1; ...
           'VetoOnly',    0, 1; ...
           'RosterOnly',  1, 0; ...
           'Neither',     0, 0 };
  fracs = [0.1 0.2 0.3];
  rows = {};
  for ia = 1:size(arms,1)
    for fr = fracs
      for s = seeds
        cfg = config_default();
        cfg.protocol='proposed'; cfg.channel='shadow';
        cfg.adversary='sybil';   cfg.compromised=fr;
        cfg.maxRounds=1500;      cfg.seed=s;  cfg.sybilChurn=true;
        cfg.ablation.permissioned = logical(arms{ia,2});
        cfg.ablation.veto         = logical(arms{ia,3});
        r = simulate(cfg);
        rows{end+1} = sprintf('%s,%.2f,%d,%.6f,%.6f,%.6f,%d,%d,%.6f', ...
          arms{ia,1}, fr, s, r.sybCHrate, r.malCHrate, r.PDRwin, ...
          r.HND, r.churnTotal, r.blkRejRate);
        fflush(stdout);
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'arm,frac,seed,sybCH,malCHrate,PDRwin,HND,churnTotal,blkRej\n');
  for i = 1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows);
  printf('FACSWEEP_DONE rows=%d -> %s\n', S, outfile);
end
