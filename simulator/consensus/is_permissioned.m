function t = is_permissioned(cfg)
% IS_PERMISSIONED  True for the protocols that maintain a PoA authority set.
% Kept as one function so the roster gate and the consensus round cannot drift
% apart. The 'permissioned' ablation toggle disables the roster while leaving
% the rest of EA-PoA intact, isolating the identity gate from the trust veto.
  t = any(strcmp(cfg.protocol, {'proposed','eapoa','heed_secured','tao_secured'}));
  if t && isfield(cfg,'ablation') && isfield(cfg.ablation,'permissioned')
    t = cfg.ablation.permissioned;
  end
end
