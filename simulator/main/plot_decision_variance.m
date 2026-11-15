function plot_decision_variance(csvfile, outpng)
% PLOT_DECISION_VARIANCE  Draw fig7 from results_decvar.csv without re-running
% the experiment. Split out of run_decision_variance so the figure can be
% redrawn from stored results, leaving results_decvar.csv untouched.
%   Uses the qt toolkit: the gnuplot backend drops legend() on invisible
%   figures and clips titles at the top edge.
  if nargin < 1 || isempty(csvfile), csvfile = 'results_decvar.csv'; end
  if nargin < 2 || isempty(outpng),  outpng  = 'figures/fig7_decision_variance.png'; end
  if ~exist('figures','dir'), mkdir('figures'); end

  fid = fopen(csvfile,'r');
  C = textscan(fid,'%f%f%f%f%f','Delimiter',',','HeaderLines',1); fclose(fid);
  it2 = C{1}; sigma = C{2}; chiStd = C{4}; flipRate = C{5};

  sg = unique(sigma).';
  pick = @(it,v) arrayfun(@(x) mean(v(it2==it & sigma==x)), sg);

  f = figure('position',[80 80 980 430],'visible','off');
  try, graphics_toolkit(f,'qt'); catch, end

  subplot(1,2,1);
  plot(sg, pick(1,chiStd), '-o', sg, pick(0,chiStd), '-s', 'linewidth',1.6); grid on;
  xlabel('input noise sigma'); ylabel('mean per-node std(chi)');
  title('Objective 5: CH-score variance');
  legend({'Interval Type-2','Type-1'},'location','northwest');

  subplot(1,2,2);
  plot(sg, pick(1,flipRate), '-o', sg, pick(0,flipRate), '-s', 'linewidth',1.6); grid on;
  xlabel('input noise sigma'); ylabel('CH-decision flip rate');
  title('Objective 5: election instability');
  legend({'Interval Type-2','Type-1'},'location','northwest');

  print(f, outpng, '-dpng'); close(f);
  fprintf('WROTE %s\n', outpng);
end
