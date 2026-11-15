function t = is_secured(cfg)
% IS_SECURED  True for host protocols carrying the roster/veto mechanisms.
% 'proposed' is the original host; the '*_secured' variants graft the same two
% mechanisms onto an independently authored clustering protocol so that the
% attribution can be tested across hosts (see the cross-host study).
  t = any(strcmp(cfg.protocol, {'proposed','heed_secured','tao_secured'})) ...
      && isfield(cfg,'ablation') && isfield(cfg.ablation,'veto');
end
