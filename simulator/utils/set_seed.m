function set_seed(s)
% SET_SEED  Reproducible RNG seeding (works on MATLAB and Octave).
  try
    rng(s, 'twister');
  catch
    rand('state', s);  %#ok<RAND>
    randn('state', s); %#ok<RAND>
  end
end
