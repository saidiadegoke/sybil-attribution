function S = run_ablations(seeds)
% RUN_ABLATIONS  Contribution ablations on the proposed protocol (shadow channel).
% Each group toggles one mechanism and reports the metric it should move:
%   C5  IT2 vs Type-1 under input noise        -> decision robustness (LND/PDR variance)
%   C2  signal-aware vs blind competition radius-> Jain / FND
%   C3  trust veto on vs off (under blackhole)  -> malicious-CH admission, LND
%   A2  fuzzy IT2 vs crisp weighted-sum selector-> PDR / LND
%   C4  consensus debit on vs off              -> LND, total consensus energy
% Writes results_ablation.csv.
  if nargin < 1, seeds = 1:5; end
  specs = ablation_specs();
  S = struct('variant',{},'group',{},'seed',{},'FND',{},'HND',{},'LND',{}, ...
             'PDR',{},'Jain',{},'malCHrate',{},'consE',{},'PDRwin',{},'sybCH',{});
  for s = seeds
    for k = 1:numel(specs)
      cfg = config_default();
      cfg.protocol = 'proposed'; cfg.channel = 'shadow';
      cfg.maxRounds = 1500; cfg.seed = s;
      cfg = apply_spec(cfg, specs(k));
      r = simulate(cfg);
      S(end+1) = struct('variant',specs(k).name,'group',specs(k).group,'seed',s, ...
        'FND',r.FND,'HND',r.HND,'LND',r.LND,'PDR',r.PDRmean,'Jain',r.Jmean, ...
        'malCHrate',r.malCHrate,'consE',r.consEtotal,'PDRwin',r.PDRwin, ...
        'sybCH',r.sybCHrate); %#ok<AGROW>
    end
  end
  fid = fopen('results_ablation.csv','w');
  fprintf(fid,'variant,group,seed,FND,HND,LND,PDR,Jain,malCHrate,consE,PDRwin,sybCH\n');
  for i = 1:numel(S)
    fprintf(fid,'%s,%s,%d,%d,%d,%d,%.4f,%.4f,%.4f,%.6g,%.4f,%.4f\n', S(i).variant, S(i).group, ...
      S(i).seed, S(i).FND, S(i).HND, S(i).LND, S(i).PDR, S(i).Jain, S(i).malCHrate, S(i).consE, ...
      S(i).PDRwin, S(i).sybCH);
  end
  fclose(fid);
  fprintf('\nABL_COMPLETE rows=%d (results_ablation.csv)\n', numel(S));
end

% ------------------------------------------------------------------ specs/apply

function specs = ablation_specs()
  specs = struct('name',{},'group',{},'set',{});
  specs(end+1) = mk('IT2-noise',   'C5', {'inputNoise',0.10,'it2',true});
  specs(end+1) = mk('Type1-noise', 'C5', {'inputNoise',0.10,'it2',false});
  specs(end+1) = mk('SignalRc',    'C2', {'signalRc',true});
  specs(end+1) = mk('BlindRc',     'C2', {'signalRc',false});
  specs(end+1) = mk('Veto-atk',    'C3', {'veto',true,'attack',1});
  specs(end+1) = mk('NoVeto-atk',  'C3', {'veto',false,'attack',1});
  specs(end+1) = mk('Fuzzy-IT2',   'A2', {'crispSelector',false});
  specs(end+1) = mk('CrispSum',    'A2', {'crispSelector',true});
  specs(end+1) = mk('Consensus',   'C4', {'consensus',true});
  specs(end+1) = mk('NoConsensus', 'C4', {'consensus',false});
  % C3s: which mechanism actually stops Sybil? The behavioural trust veto cannot
  % bind to an identity the attacker re-mints clean, so isolate the permissioned
  % roster from the veto under an identity-forgery attack.
  specs(end+1) = mk('Roster+Veto', 'C3s', {'permissioned',true, 'veto',true, 'attack',2});
  specs(end+1) = mk('VetoOnly',    'C3s', {'permissioned',false,'veto',true, 'attack',2});
  specs(end+1) = mk('RosterOnly',  'C3s', {'permissioned',true, 'veto',false,'attack',2});
  specs(end+1) = mk('Neither',     'C3s', {'permissioned',false,'veto',false,'attack',2});
  % C3c: identity churn. One-shot minting lets the veto converge after a short
  % early breach; re-minting restarts the evidence clock and it never converges.
  specs(end+1) = mk('VetoOnly-churn',   'C3c', {'permissioned',false,'veto',true,'churn',true, 'attack',2});
  specs(end+1) = mk('VetoOnly-oneshot', 'C3c', {'permissioned',false,'veto',true,'churn',false,'attack',2});
  specs(end+1) = mk('Roster-churn',     'C3c', {'permissioned',true, 'veto',true,'churn',true, 'attack',2});
  specs(end+1) = mk('Roster-oneshot',   'C3c', {'permissioned',true, 'veto',true,'churn',false,'attack',2});
  % C2 under a stressed hot-spot (edge base station) -> where signal/coverage Rc should help
  specs(end+1) = mk('SignalRc-strs','C2s', {'signalRc',true,'bsEdge',1});
  specs(end+1) = mk('BlindRc-strs', 'C2s', {'signalRc',false,'bsEdge',1});
end

function s = mk(name, group, kv)
  s.name = name; s.group = group; s.set = {kv};   % wrap cell so it stores intact
end

function cfg = apply_spec(cfg, spec)
  kv = spec.set{1};
  for i = 1:2:numel(kv)
    key = kv{i}; val = kv{i+1};
    switch key
      case 'inputNoise',     cfg.inputNoise = val;
      case 'it2',            cfg.ablation.it2 = val;
      case 'signalRc',       cfg.ablation.signalRc = val;
      case 'veto',           cfg.ablation.veto = val;
      case 'crispSelector',  cfg.ablation.crispSelector = val;
      case 'consensus',      cfg.ablation.consensus = val;
      case 'permissioned',   cfg.ablation.permissioned = val;
      case 'churn',          cfg.sybilChurn = val;
      case 'attack'          % 1 -> blackhole, 2 -> sybil, at 20% compromised
        if val == 1, cfg.adversary = 'blackhole'; cfg.compromised = 0.2; end
        if val == 2, cfg.adversary = 'sybil';     cfg.compromised = 0.2; end
      case 'bsEdge'          % 1 -> move BS to the field edge (stress the hot-spot)
        if val == 1, cfg.BS = [cfg.field(1)/2, cfg.field(2)*1.05]; end
    end
  end
end
