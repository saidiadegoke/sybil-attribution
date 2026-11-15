function S = run_experiments(seeds, protocols, channels)
% RUN_EXPERIMENTS  Small factorial sweep (protocol x channel x seed). Prints a
% mean-over-seeds summary and returns a struct array of per-run results.
% Table-free for Octave compatibility; writes results_raw.csv.
  if nargin < 1 || isempty(seeds),     seeds = 1:5;                       end
  if nargin < 2 || isempty(protocols), protocols = {'leach','proposed'};  end
  if nargin < 3 || isempty(channels),  channels  = {'ideal','shadow'};    end

  S = struct('protocol',{},'channel',{},'seed',{}, ...
             'FND',{},'HND',{},'LND',{},'PDR',{},'Jain',{},'consE',{});
  for p = 1:numel(protocols)
    for ch = 1:numel(channels)
      for s = seeds
        cfg = config_default();
        cfg.protocol = protocols{p};
        cfg.channel  = channels{ch};
        cfg.seed     = s;
        cfg.maxRounds = 2500;
        r = simulate(cfg);
        S(end+1) = struct('protocol',protocols{p},'channel',channels{ch}, ...
          'seed',s,'FND',r.FND,'HND',r.HND,'LND',r.LND, ...
          'PDR',r.PDRmean,'Jain',r.Jmean,'consE',r.consEtotal); %#ok<AGROW>
      end
    end
  end

  write_csv(S, 'results_raw.csv');

  fprintf('\n=== mean over %d seed(s) ===\n', numel(seeds));
  fprintf('%-9s %-7s %8s %8s %8s %7s %7s\n', ...
          'protocol','channel','FND','HND','LND','PDR','Jain');
  for p = 1:numel(protocols)
    for ch = 1:numel(channels)
      sel = strcmp({S.protocol},protocols{p}) & strcmp({S.channel},channels{ch});
      fprintf('%-9s %-7s %8.0f %8.0f %8.0f %7.3f %7.3f\n', ...
        protocols{p}, channels{ch}, ...
        mean([S(sel).FND]), mean([S(sel).HND]), mean([S(sel).LND]), ...
        mean([S(sel).PDR]), mean([S(sel).Jain]));
    end
  end
end

function write_csv(S, fname)
  fid = fopen(fname, 'w');
  fprintf(fid, 'protocol,channel,seed,FND,HND,LND,PDR,Jain,consE\n');
  for i = 1:numel(S)
    fprintf(fid, '%s,%s,%d,%d,%d,%d,%.4f,%.4f,%.6g\n', ...
      S(i).protocol, S(i).channel, S(i).seed, S(i).FND, S(i).HND, ...
      S(i).LND, S(i).PDR, S(i).Jain, S(i).consE);
  end
  fclose(fid);
end
