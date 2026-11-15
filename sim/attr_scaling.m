function S = attr_scaling(seeds, outfile)
% ATTR_SCALING  §8 item 3: displacement scaling. §7.4 predicts that displacement
% magnitude scales with the forged-identities-per-attacker ratio s, and §6.7
% shows it also scales with how far the host's election suppresses hardware.
% This is the two-factor sweep over s and host that turns displacement from a
% measurement into a law. Only the two arms needed for the ratio are run:
% RosterOnly (the partial defence) and Neither (the undefended reference).
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_scaling.csv'; end
  sVals = [1 2 3 5 8];
  hosts = {'proposed','tao_secured','heed_secured'};
  arms  = { 'RosterOnly', 1, 0; 'Neither', 0, 0 };
  rows = {};
  for ih = 1:numel(hosts)
    for sv = sVals
      for ia = 1:size(arms,1)
        for sd = seeds
          cfg = config_default();
          cfg.protocol=hosts{ih}; cfg.channel='shadow';
          cfg.adversary='sybil'; cfg.compromised=0.2;
          cfg.maxRounds=1500; cfg.seed=sd; cfg.sybilChurn=true;
          cfg.sybilIds = sv;
          cfg.ablation.permissioned = logical(arms{ia,2});
          cfg.ablation.veto         = logical(arms{ia,3});
          r = simulate(cfg);
          rows{end+1} = sprintf('%s,%d,%s,%d,%.6f,%.6f,%.6f,%d', ...
            hosts{ih}, sv, arms{ia,1}, sd, r.sybCHrate, r.malCHrate, ...
            r.malCHrate - r.sybCHrate, r.HND);
          fflush(stdout);
        end
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'host,sybilIds,arm,seed,sybCH,malCHrate,hwCH,HND\n');
  for i=1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows); printf('SCALING_DONE rows=%d -> %s\n', S, outfile);
end
