function S = attr_delay(seeds, outfile)
% ATTR_DELAY  §8 item 2: the re-mint delay sweep. §6.5 rejects the k/(k+delta)
% duty-cycle form at delta ~ 1. Sweeping delta from 0 upward establishes whether
% ANY re-mint delay restores the veto, or whether capture saturation makes the
% mechanism inoperative for all delta below k.
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_delay.csv'; end
  delays = [0 1 2 4 8 16 32];
  arms = { 'veto-only', false; 'roster+veto', true };
  rows = {};
  for d = delays
    for ia = 1:size(arms,1)
      for s = seeds
        cfg = config_default();
        cfg.protocol='proposed'; cfg.channel='shadow';
        cfg.adversary='sybil'; cfg.compromised=0.2;
        cfg.maxRounds=1500; cfg.seed=s; cfg.sybilChurn=true;
        cfg.churnDelay = d;
        cfg.ablation.permissioned = arms{ia,2};
        r = simulate(cfg);
        rows{end+1} = sprintf('%s,%d,%d,%.6f,%.6f,%d,%d', ...
          arms{ia,1}, d, s, r.sybCHrate, r.malCHrate, r.HND, r.churnTotal);
        fflush(stdout);
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'arm,delay,seed,sybCH,malCHrate,HND,churnTotal\n');
  for i=1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows); printf('DELAY_DONE rows=%d -> %s\n', S, outfile);
end
