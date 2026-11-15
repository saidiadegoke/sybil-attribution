function S = attr_hosts(seeds, outfile)
% ATTR_HOSTS  The cross-host attribution study: the same roster x veto factorial
% run on independently authored clustering protocols.
%
% The mechanisms under test are identical across hosts -- all three call the one
% CH_ELIGIBLE gate -- so any difference in the coverage matrix is attributable to
% the host's election rule and not to the mechanisms.
%
%   heed_secured : HEED (Younis & Fahmy, 2004). Election is residual-energy
%                  probability plus a coverage guarantee. TRUST-BLIND.
%   tao_secured  : UCT2TSK (Tao, Zhang & Yang, 2020). Interval type-2 TSK
%                  inference emitting radius and rank. Fuzzy but TRUST-BLIND,
%                  and independently authored.
%
% The proposed host's arm of this factorial is already produced by
% ATTR_FACTORIAL_SWEEP; this driver supplies the other two so the three can be
% compared on one grid.
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_hosts.csv'; end
  hosts = {'heed_secured','tao_secured'};
  arms  = { 'Roster+Veto', 1, 1; 'VetoOnly', 0, 1; ...
            'RosterOnly',  1, 0; 'Neither',  0, 0 };
  fracs = [0.1 0.2 0.3];
  rows = {};
  for ih = 1:numel(hosts)
    for ia = 1:size(arms,1)
      for fr = fracs
        for s = seeds
          cfg = config_default();
          cfg.protocol = hosts{ih}; cfg.channel = 'shadow';
          cfg.adversary = 'sybil';  cfg.compromised = fr;
          cfg.maxRounds = 1500;     cfg.seed = s;  cfg.sybilChurn = true;
          cfg.ablation.permissioned = logical(arms{ia,2});
          cfg.ablation.veto         = logical(arms{ia,3});
          r = simulate(cfg);
          rows{end+1} = sprintf('%s,%s,%.2f,%d,%.6f,%.6f,%.6f,%d,%d,%.6f', ...
            hosts{ih}, arms{ia,1}, fr, s, r.sybCHrate, r.malCHrate, ...
            r.PDRwin, r.HND, r.churnTotal, r.blkRejRate);
          fflush(stdout);
        end
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'host,arm,frac,seed,sybCH,malCHrate,PDRwin,HND,churnTotal,blkRej\n');
  for i = 1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows);
  printf('HOSTS_DONE rows=%d -> %s\n', S, outfile);
end
