function S = attr_scale_topo(seeds, outfile)
% ATTR_SCALE_TOPO  §8 item 4: scale and topology. The attribution STRUCTURE is
% claimed to be scale-invariant even where the magnitudes shift, so the full
% roster x veto factorial is repeated at larger network sizes and with the base
% station moved to the field edge, which stresses the hot-spot.
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_scale_topo.csv'; end
  Ns   = [200 300 500];
  arms = { 'Roster+Veto',1,1; 'RosterOnly',1,0; 'VetoOnly',0,1; 'Neither',0,0 };
  rows = {};
  for N = Ns
    for edge = [0 1]
      for ia = 1:size(arms,1)
        for s = seeds
          cfg = config_default();
          cfg.protocol='proposed'; cfg.channel='shadow';
          cfg.adversary='sybil'; cfg.compromised=0.2;
          cfg.maxRounds=1000; cfg.seed=s; cfg.sybilChurn=true;
          cfg.N = N;
          if edge, cfg.BS = [cfg.field(1)/2, cfg.field(2)*1.05]; end
          cfg.ablation.permissioned = logical(arms{ia,2});
          cfg.ablation.veto         = logical(arms{ia,3});
          r = simulate(cfg);
          rows{end+1} = sprintf('%d,%d,%s,%d,%.6f,%.6f,%.6f,%d,%.6f', ...
            N, edge, arms{ia,1}, s, r.sybCHrate, r.malCHrate, ...
            r.malCHrate - r.sybCHrate, r.HND, r.PDRwin);
          fflush(stdout);
        end
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'N,edgeBS,arm,seed,sybCH,malCHrate,hwCH,HND,PDRwin\n');
  for i=1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows); printf('SCALETOPO_DONE rows=%d -> %s\n', S, outfile);
end
