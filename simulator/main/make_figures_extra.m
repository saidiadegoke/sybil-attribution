function make_figures_extra(advcsv, ablcsv)
% MAKE_FIGURES_EXTRA  Adversary (S4) and ablation figures, headless (qt).
%   fig5_adversary.png : malicious-CH admission (top) and common-window PDR
%                        (bottom) vs compromised fraction, per attack
%   fig6_ablation.png  : per-contribution ablation comparisons (PDR uses the
%                        fair common-window PDRwin; LND avoided as it is censored)
  if nargin < 1, advcsv = 'results_adversary.csv'; end
  if nargin < 2, ablcsv = 'results_ablation.csv'; end
  if ~exist('figures','dir'), mkdir('figures'); end

  % ===================== Adversary =====================
  fid = fopen(advcsv,'r');
  A = textscan(fid,'%s%s%f%f%f%f%f%f%f%f%f','Delimiter',',','HeaderLines',1); fclose(fid);
  proto=A{1}; attack=A{2}; frac=A{3}; malCH=A{5}; PDRwin=A{8};
  protos = {'eflzsepfch','eapoa','proposed'};
  plabel = {'E-FLZ (unsecured)','EA-PoA','STITCH (proposed)'};
  atks   = {'sybil','blackhole','sinkhole'};
  ufr = unique(frac).'; cols = lines(numel(protos));

  f = newfig([80 80 1200 680]);
  for c = 1:numel(atks)        % top: malicious-CH admission
    subplot(2,3,c); hold on;
    for p = 1:numel(protos)
      y = arrayfun(@(fr) mean(malCH(strcmp(proto,protos{p}) & strcmp(attack,atks{c}) & frac==fr)), ufr);
      plot(ufr, y, '-o', 'color', cols(p,:), 'linewidth', 1.5);
    end
    grid on; ylim([0 0.4]); title(['malicious-CH: ' atks{c}]);
    xlabel('compromised fraction'); ylabel('malicious-CH rate');
  end
  for c = 1:numel(atks)        % bottom: fair common-window PDR
    subplot(2,3,3+c); hold on;
    for p = 1:numel(protos)
      y = arrayfun(@(fr) mean(PDRwin(strcmp(proto,protos{p}) & strcmp(attack,atks{c}) & frac==fr)), ufr);
      plot(ufr, y, '-o', 'color', cols(p,:), 'linewidth', 1.5);
    end
    grid on; ylim([0.4 1]); title(['PDR (first 1000 rds): ' atks{c}]);
    xlabel('compromised fraction'); ylabel('windowed PDR');
    if c==1, legend(plabel,'location','southwest'); end
  end
  print(f,'figures/fig5_adversary.png','-dpng'); close(f);

  % ===================== Ablations =====================
  fid = fopen(ablcsv,'r');
  B = textscan(fid,'%s%s%f%f%f%f%f%f%f%f%f%f','Delimiter',',','HeaderLines',1); fclose(fid);
  vv=B{1}; FNDa=B{4}; HNDa=B{5}; Jaina=B{8}; malCHa=B{9}; PDRwina=B{11};
  gm = @(name,col,fn) fn(col(strcmp(vv,name)));

  panels = { ...
    {'C2 energy balance (central BS)', {'SignalRc','BlindRc'},          Jaina,  @mean, 'mean Jain'}, ...
    {'C2 energy balance (edge BS, stressed)', {'SignalRc-strs','BlindRc-strs'}, Jaina, @mean, 'mean Jain'}, ...
    {'C2 first-death (edge BS, stressed)', {'SignalRc-strs','BlindRc-strs'}, FNDa, @mean, 'mean FND'}, ...
    {'C3 malicious-CH under attack', {'Veto-atk','NoVeto-atk'},         malCHa, @mean, 'malicious-CH rate'}, ...
    {'C3 PDR under attack (windowed)', {'Veto-atk','NoVeto-atk'},       PDRwina,@mean, 'windowed PDR'}, ...
    {'A2 reliability (windowed PDR)', {'Fuzzy-IT2','CrispSum'},          PDRwina,@mean, 'windowed PDR'}, ...
    {'C4 half-life cost (HND)', {'Consensus','NoConsensus'},            HNDa,   @mean, 'mean HND'}, ...
    {'C5 decision spread (std HND)', {'IT2-noise','Type1-noise'},       HNDa,   @std,  'std(HND)'} };

  f = newfig([60 60 1300 900]);
  for k = 1:numel(panels)
    P = panels{k}; names = P{2}; col = P{3}; fn = P{4};
    vals = [gm(names{1},col,fn), gm(names{2},col,fn)];
    subplot(3,3,k); bar(vals); grid on;
    set(gca,'xtick',1:2,'xticklabel',names,'fontsize',9);
    title(P{1}); ylabel(P{5});
  end
  print(f,'figures/fig6_ablation.png','-dpng'); close(f);

  fprintf('EXTRA_FIGS_DONE: figures/fig5_adversary.png figures/fig6_ablation.png\n');
end

function fh = newfig(pos)
% qt, not gnuplot: the gnuplot backend drops legend() on invisible figures.
  fh = figure('position', pos, 'visible', 'off');
  try, graphics_toolkit(fh, 'qt'); catch, end
end
