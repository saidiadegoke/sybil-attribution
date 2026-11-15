function S = attr_ledger(seeds, outfile)
% ATTR_LEDGER  §8 item 1: ledger-integrity metrics for the third channel of the
% coverage matrix, which the admission metrics of §6 do not observe.
%
% Arms: the unsecured baseline (no ledger at all), EA-PoA (roster + quorum),
% the proposed protocol (roster + quorum + veto), and the proposed protocol with
% the veto extended to authority-set membership. The last arm is the remedy:
% by default the veto gates the cluster-head role but NOT the authority set, so
% a barred node still validates and can still be elected signer.
  if nargin < 1 || isempty(seeds),   seeds = 1:20; end
  if nargin < 2 || isempty(outfile), outfile = 'results_ledger.csv'; end
  arms = { 'unsecured',      'eflzsepfch', false; ...
           'EA-PoA',         'eapoa',      false; ...
           'proposed',       'proposed',   false; ...
           'proposed+vetoAuth','proposed', true  };
  fracs = [0.1 0.2 0.3];
  rows = {};
  for ia = 1:size(arms,1)
    for fr = fracs
      for s = seeds
        cfg = config_default();
        cfg.protocol = arms{ia,2}; cfg.channel='shadow';
        cfg.adversary='sybil'; cfg.compromised=fr;
        cfg.maxRounds=1500; cfg.seed=s; cfg.sybilChurn=true;
        cfg.ablation.vetoAuthority = arms{ia,3};
        r = simulate(cfg);
        rows{end+1} = sprintf('%s,%.2f,%d,%.6f,%.6f,%.6f,%.6f,%d,%d,%.6f,%.6f,%d', ...
          arms{ia,1}, fr, s, r.forkRefused, r.rewriteRefused, r.unauthRefused, ...
          r.advCommitFrac, r.ledgerAtt, r.ledgerBreaches, r.malCHrate, r.sybCHrate, r.HND);
        fflush(stdout);
      end
    end
  end
  fid = fopen(outfile,'w');
  fprintf(fid,'arm,frac,seed,forkRefused,rewriteRefused,unauthRefused,advCommitFrac,ledgerAtt,ledgerBreaches,malCHrate,sybCH,HND\n');
  for i=1:numel(rows), fprintf(fid,'%s\n', rows{i}); end
  fclose(fid);
  S = numel(rows); printf('LEDGER_DONE rows=%d -> %s\n', S, outfile);
end
