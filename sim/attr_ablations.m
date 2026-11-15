function S = attr_ablations(seeds, outfile)
% ATTR_ABLATIONS  The factorial mechanism ablation (roster x veto, group C3s),
% the identity-minting ablation (group C3c), and the consensus-cost ablation
% (group C4), at a publishable seed budget. Output path is a parameter.
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_ablation_20.csv'; end
  specs = attr_specs();
  rows = {};
  for s = seeds
    for k = 1:numel(specs)
      cfg = config_default();
      cfg.protocol = 'proposed'; cfg.channel = 'shadow';
      cfg.maxRounds = 1500; cfg.seed = s;
      cfg = attr_apply(cfg, specs(k));
      r = simulate(cfg);
      rows{end+1} = sprintf('%s,%s,%d,%d,%d,%d,%.6f,%.6f,%.6f,%.8g,%.6f,%.6f,%d', ...
        specs(k).name, specs(k).group, s, r.FND, r.HND, r.LND, r.PDRmean, ...
        r.Jmean, r.malCHrate, r.consEtotal, r.PDRwin, r.sybCHrate, r.churnTotal);
      fflush(stdout);
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'variant,group,seed,FND,HND,LND,PDR,Jain,malCHrate,consE,PDRwin,sybCH,churnTotal\n');
  for i = 1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows);
  printf('ABL_DONE rows=%d -> %s\n', S, outfile);
end

function specs = attr_specs()
  specs = struct('name',{},'group',{},'set',{});
  % C3s -- the 2x2 factorial: roster x veto, under identity forgery with churn.
  specs(end+1) = mk('Roster+Veto','C3s',{'permissioned',1,'veto',1,'churn',1});
  specs(end+1) = mk('VetoOnly',   'C3s',{'permissioned',0,'veto',1,'churn',1});
  specs(end+1) = mk('RosterOnly', 'C3s',{'permissioned',1,'veto',0,'churn',1});
  specs(end+1) = mk('Neither',    'C3s',{'permissioned',0,'veto',0,'churn',1});
  % C3c -- the threat-model ablation: one-shot minting vs churn.
  specs(end+1) = mk('VetoOnly-churn',  'C3c',{'permissioned',0,'veto',1,'churn',1});
  specs(end+1) = mk('VetoOnly-oneshot','C3c',{'permissioned',0,'veto',1,'churn',0});
  specs(end+1) = mk('Roster-churn',    'C3c',{'permissioned',1,'veto',1,'churn',1});
  specs(end+1) = mk('Roster-oneshot',  'C3c',{'permissioned',1,'veto',1,'churn',0});
  % C4 -- what attribution costs: consensus energy debited from CH batteries.
  specs(end+1) = mk('Consensus',  'C4',{'permissioned',1,'veto',1,'churn',1,'consensus',1});
  specs(end+1) = mk('NoConsensus','C4',{'permissioned',1,'veto',1,'churn',1,'consensus',0});
end

function s = mk(name, group, kv), s.name=name; s.group=group; s.set={kv}; end

function cfg = attr_apply(cfg, spec)
  kv = spec.set{1};
  cfg.adversary = 'sybil'; cfg.compromised = 0.2;   % all arms: identity forgery
  for i = 1:2:numel(kv)
    switch kv{i}
      case 'permissioned', cfg.ablation.permissioned = logical(kv{i+1});
      case 'veto',         cfg.ablation.veto         = logical(kv{i+1});
      case 'consensus',    cfg.ablation.consensus    = logical(kv{i+1});
      case 'churn',        cfg.sybilChurn            = logical(kv{i+1});
    end
  end
end
