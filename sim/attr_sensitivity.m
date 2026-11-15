function S = attr_sensitivity(seeds, outfile, studies)
% ATTR_SENSITIVITY  Reviewer 2 (FEIC 2026): is the veto's flatness in k and
% delta an artefact of the adversary model? Varies, one at a time from the
% default adversary (20% attackers, s = 3, free unlimited minting, re-minted
% trust 0.7, delta = 0):
%   T0n    trust a re-minted identity starts with       {0.3, 0.4, 0.5, 0.7}
%   budget total re-mints allowed per attacker          {3, 10, 30, Inf}
%   cost   energy per re-mint from the attacker (J)     {0.001, 0.01}
%   s      forged identities per attacker               {1, 2, 3, 5, 8}
% Arms: veto-only (roster off) and neither (roster and veto off), host STITCH.
% 600 runs at 20 seeds. Output columns: study,level,arm,seed,sybCH,malCHrate,
% HND,churnTotal.
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_sensitivity.csv'; end
  if nargin < 3 || isempty(studies), studies = {'T0n','budget','cost','s'}; end
  grid = struct('T0n', [0.3 0.4 0.5 0.7], 'budget', [3 10 30 Inf], ...
                'cost', [0.001 0.01], 's', [1 2 3 5 8]);
  arms = { 'veto-only', true; 'neither', false };
  rows = {};
  for is = 1:numel(studies)
    st = studies{is};
    for lv = grid.(st)
      for ia = 1:size(arms,1)
        for sd = seeds
          cfg = config_default();
          cfg.protocol='proposed'; cfg.channel='shadow';
          cfg.adversary='sybil'; cfg.compromised=0.2;
          cfg.maxRounds=1500; cfg.seed=sd; cfg.sybilChurn=true;
          cfg.ablation.permissioned = false;
          cfg.ablation.veto = arms{ia,2};
          switch st
            case 'T0n',    cfg.newcomerT0 = lv;
            case 'budget', cfg.sybilMintBudget = lv;
            case 'cost',   cfg.sybilMintCost = lv;
            case 's',      cfg.sybilIds = lv;
          end
          r = simulate(cfg);
          rows{end+1} = sprintf('%s,%g,%s,%d,%.6f,%.6f,%d,%d', st, lv, arms{ia,1}, ...
                                sd, r.sybCHrate, r.malCHrate, r.HND, r.churnTotal);
          fflush(stdout);
        end
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'study,level,arm,seed,sybCH,malCHrate,HND,churnTotal\n');
  for i = 1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows); printf('SENS_DONE rows=%d -> %s\n', S, outfile);
end
