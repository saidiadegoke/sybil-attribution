function attr_trace(outfile)
% ATTR_TRACE  Single-run trust trajectories for the churn figure: mean trust of
% forged identities under one-shot minting (decays once, stays convicted) versus
% under churn (decays, is re-minted to the newcomer default, decays again), with
% the compromised-hardware trajectory alongside as the population the veto can
% actually hold. Seed 1, default (eta,tau).
  if nargin < 1 || isempty(outfile), outfile = 'results_trace.csv'; end
  R = 120;                                  % early rounds are where this happens
  base = config_default();
  base.protocol='proposed'; base.channel='shadow';
  base.adversary='sybil';   base.compromised=0.2;
  base.maxRounds=R; base.seed=1; base.traceTrust=true;
  base.ablation.permissioned=false; base.ablation.veto=true;

  c1 = base; c1.sybilChurn=false; r1 = simulate(c1);
  c2 = base; c2.sybilChurn=true;  r2 = simulate(c2);

  n = min([numel(r1.Tforged), numel(r2.Tforged), R]);
  fid = fopen(outfile,'w');
  fprintf(fid,'round,T_forged_oneshot,T_forged_churn,T_mal_oneshot,nAboveTau_oneshot,nAboveTau_churn,churn_events,tau,T0\n');
  for r = 1:n
    fprintf(fid,'%d,%.6f,%.6f,%.6f,%d,%d,%d,%.3f,%.3f\n', r, ...
      r1.Tforged(r), r2.Tforged(r), r1.Tmal(r), ...
      r1.nForgedAboveTau(r), r2.nForgedAboveTau(r), r2.churn(r), ...
      base.tau, base.T0);
  end
  fclose(fid);
  printf('TRACE_DONE rounds=%d -> %s\n', n, outfile);
end
