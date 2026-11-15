function S = attr_ksweep(seeds, outfile)
% ATTR_KSWEEP  Turn Proposition 2 from a point result into a curve.
%
% k is rounds-to-conviction: how many rounds a freshly minted forged identity
% stays above the veto threshold before behavioural evidence convicts it. It is
% a property of the trust dynamics, not a free parameter, so it is varied here
% through the two knobs that set those dynamics -- the trust update rate eta
% (Eq 11) and the veto threshold tau -- and then MEASURED rather than assumed.
%
% k is measured on the one-shot arm (no churn), where the trust trajectory is
% not reset and the crossing is well defined. The outcome of interest, forged
% cluster-head share, is measured on the churn arm at the same (eta,tau). This
% separation is deliberate: k describes the mechanism, churn describes the
% adversary, and the paper's claim is about how the first governs the second.
%
% Arms per setting:
%   veto-oneshot : permissioned=0, veto=1, churn=0   -> yields k, and the
%                  flattering O(k/R) capture rate the field usually reports
%   veto-churn   : permissioned=0, veto=1, churn=1   -> the honest capture rate
%   roster+veto  : permissioned=1, veto=1, churn=1   -> predicted flat at 0,
%                  invariant to k (Proposition 1)
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_ksweep_20.csv'; end

  % (eta, tau) settings chosen to span a wide range of k in both directions.
  settings = [0.05 0.40; 0.10 0.40; 0.20 0.40; 0.35 0.40; 0.50 0.40; 0.80 0.40; ...
              0.20 0.25; 0.20 0.55; 0.20 0.65];
  arms = {'veto-oneshot','veto-churn','roster+veto'};

  rows = {};
  for is = 1:size(settings,1)
    eta = settings(is,1); tau = settings(is,2);
    for s = seeds
      for ia = 1:numel(arms)
        cfg = config_default();
        cfg.protocol='proposed'; cfg.channel='shadow';
        cfg.adversary='sybil';   cfg.compromised=0.2;
        cfg.maxRounds=1500;      cfg.seed=s;
        cfg.eta = eta;           cfg.tau = tau;
        switch arms{ia}
          case 'veto-oneshot'
            cfg.ablation.permissioned=false; cfg.ablation.veto=true;
            cfg.sybilChurn=false; cfg.traceTrust=true;
          case 'veto-churn'
            cfg.ablation.permissioned=false; cfg.ablation.veto=true;
            cfg.sybilChurn=true;  cfg.traceTrust=true;
          case 'roster+veto'
            cfg.ablation.permissioned=true;  cfg.ablation.veto=true;
            cfg.sybilChurn=true;  cfg.traceTrust=false;
        end
        r = simulate(cfg);
        kmeas = NaN;
        if strcmp(arms{ia},'veto-oneshot')
          kmeas = kcross(r.Tforged, tau);
        end
        rows{end+1} = sprintf('%s,%.3f,%.3f,%d,%.6f,%.6f,%.6f,%d,%d,%g', ...
          arms{ia}, eta, tau, s, r.sybCHrate, r.malCHrate, r.PDRwin, ...
          r.HND, r.churnTotal, kmeas);
        fflush(stdout);
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'arm,eta,tau,seed,sybCH,malCHrate,PDRwin,HND,churnTotal,k\n');
  for i = 1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows);
  printf('KSWEEP_DONE rows=%d -> %s\n', S, outfile);
end

function k = kcross(T, tau)
% First round at which the mean trust of alive forged identities falls below the
% veto threshold. NaN if it never crosses within the run.
  idx = find(~isnan(T) & T < tau, 1);
  if isempty(idx), k = NaN; else, k = idx; end
end
