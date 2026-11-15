function make_figures(csvfile)
% MAKE_FIGURES  Plot the sweep results to PNGs under figures/ (headless).
%   - bar charts of FND/HND/LND and PDR/Jain (protocol x channel) from the CSV
%   - alive-vs-rounds and total-energy-vs-rounds curves (re-run one seed/protocol)
% Uses the qt toolkit per-figure so print works with no display and keeps legends.
  if nargin < 1, csvfile = 'results_raw.csv'; end
  if ~exist('figures','dir'), mkdir('figures'); end

  protos = {'leach','heed','eaucf','eflzsepfch','tao_it2','eapoa','proposed'};
  labels = {'LEACH','HEED','EAUCF','E-FLZ','TaoIT2','EA-PoA','PROP'};  % short x-tick labels
  chans  = {'ideal','shadow'};
  chanlab = {'ideal channel','shadow channel'};   % legend text

  fid = fopen(csvfile,'r');
  C = textscan(fid, '%s%s%f%f%f%f%f%f%f', 'Delimiter', ',', 'HeaderLines', 1);
  fclose(fid);
  proto = C{1}; chan = C{2};
  FND = C{4}; HND = C{5}; LND = C{6}; PDR = C{7}; Jain = C{8};

  np = numel(protos); nc = numel(chans);
  mFND=zeros(np,nc); mHND=mFND; mLND=mFND; mPDR=mFND; mJ=mFND;
  for a=1:np
    for b=1:nc
      m = strcmp(proto,protos{a}) & strcmp(chan,chans{b});
      mFND(a,b)=mean(FND(m)); mHND(a,b)=mean(HND(m)); mLND(a,b)=mean(LND(m));
      mPDR(a,b)=mean(PDR(m)); mJ(a,b)=mean(Jain(m));
    end
  end

  % ---- Fig 1: lifetime (FND/HND/LND), stacked for full-width labels ----
  f = newfig([100 100 860 920]);
  ttl={'First Node Death','Half Node Death','Last Node Death'}; dat={mFND,mHND,mLND};
  for k=1:3
    subplot(3,1,k); bar(dat{k}); grid on;
    set(gca,'xtick',1:np,'xticklabel',labels,'fontsize',9);
    ylabel('rounds'); title(ttl{k});
    if k==1, legend(chanlab,'location','northwest'); end
  end
  print(f,'figures/fig1_lifetime.png','-dpng'); close(f);

  % ---- Fig 2: PDR and Jain, stacked ----
  f = newfig([100 100 860 660]);
  subplot(2,1,1); bar(mPDR); grid on; set(gca,'xtick',1:np,'xticklabel',labels,'fontsize',9);
  ylabel('mean PDR'); title('Packet Delivery Ratio (axis truncated)'); ylim([0.9 1]);
  legend(chanlab,'location','southoutside','orientation','horizontal');
  subplot(2,1,2); bar(mJ); grid on; set(gca,'xtick',1:np,'xticklabel',labels,'fontsize',9);
  ylabel('mean Jain index'); title('Energy-balance fairness');
  print(f,'figures/fig2_pdr_jain.png','-dpng'); close(f);

  % ---- Fig 3, 4 & PDR-curve: time series (re-run seed=1, shadow) ----
  cols = lines(np);
  fA = newfig([100 100 760 480]);
  fE = newfig([100 100 760 480]);
  fP = newfig([100 100 760 480]);
  w = 25;                                            % moving-average window for the PDR curve
  for a=1:np
    cfg = config_default(); cfg.protocol=protos{a}; cfg.channel='shadow';
    cfg.seed=1; cfg.maxRounds=2500;
    r = simulate(cfg);
    set(0,'currentfigure',fA); hold on; plot(1:numel(r.alive), r.alive, 'color', cols(a,:), 'linewidth', 1.4);
    set(0,'currentfigure',fE); hold on; plot(1:numel(r.energy), r.energy, 'color', cols(a,:), 'linewidth', 1.4);
    sm = conv(r.pdr, ones(1,w)/w, 'same');           % smoothed per-round PDR
    set(0,'currentfigure',fP); hold on; plot(1:numel(sm), sm, 'color', cols(a,:), 'linewidth', 1.4);
  end
  set(0,'currentfigure',fA); grid on; xlabel('round'); ylabel('alive nodes');
  title('Alive nodes vs rounds (shadow, seed 1)'); legend(labels,'location','northeast');
  print(fA,'figures/fig3_alive_vs_rounds.png','-dpng'); close(fA);
  set(0,'currentfigure',fE); grid on; xlabel('round'); ylabel('total residual energy (J)');
  title('Total energy vs rounds (shadow, seed 1)'); legend(labels,'location','northeast');
  print(fE,'figures/fig4_energy_vs_rounds.png','-dpng'); close(fE);
  set(0,'currentfigure',fP); grid on; ylim([0 1.02]); xlabel('round');
  ylabel('per-round PDR (25-round moving average)');
  title('Per-round PDR vs rounds (shadow, seed 1)'); legend(labels,'location','southwest');
  print(fP,'figures/fig_pdr_vs_rounds.png','-dpng'); close(fP);

  fprintf('FIGURES_DONE: fig1 fig2 fig3 fig4 fig_pdr_vs_rounds\n');
end

function fh = newfig(pos)
% Invisible figure on the qt toolkit. qt prints headless AND renders legend()
% into the PNG; the gnuplot backend silently drops legends on invisible figures
% and clips titles at the top edge, which is why earlier figures had no keys.
  fh = figure('position', pos, 'visible', 'off');
  try, graphics_toolkit(fh, 'qt'); catch, end
end
