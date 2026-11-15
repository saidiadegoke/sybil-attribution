function attr_setup()
% ATTR_SETUP  Put the ST-IT2FUC/EA-PoA reference simulator on the path.
% The simulator is NOT copied into the drivers: it stays the single reference
% implementation, and this paper's drivers are additive. Two layouts work:
%   repository : <repo>/simulator next to <repo>/sim
%   workspace  : ../../ST-IT2FUC-EAPoA relative to sim/
  here = fileparts(mfilename('fullpath'));
  cands = { fullfile(here, '..', 'simulator'), ...
            fullfile(here, '..', '..', 'ST-IT2FUC-EAPoA') };
  sim = '';
  for i = 1:numel(cands)
    if exist(fullfile(cands{i}, 'setup_paths.m'), 'file'), sim = cands{i}; break; end
  end
  if isempty(sim), error('attr_setup: simulator not found (looked in %s)', strjoin(cands, ', ')); end
  old = pwd(); cd(sim); setup_paths(); cd(old);
  addpath(here);
end
