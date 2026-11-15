function setup_paths()
% SETUP_PATHS  Add all project subfolders to the path. Run once per session.
  here = fileparts(mfilename('fullpath'));
  addpath(genpath(here));
end
