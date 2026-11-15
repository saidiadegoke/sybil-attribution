function net = inject_attack(net, cfg)
% INJECT_ATTACK  Flag a fraction of nodes malicious and set the attack type.
%   atk: 0 none, 1 sybil, 2 blackhole, 3 sinkhole.
  if strcmp(cfg.adversary,'none') || cfg.compromised <= 0, return; end
  N = numel(net.x);
  k = max(1, round(cfg.compromised * N));
  idx = randperm(N, k);
  net.isMal(idx) = true;
  switch cfg.adversary
    case 'sybil',     net.atk(idx) = 1; net = spawn_sybil(net, cfg, idx);
    case 'blackhole', net.atk(idx) = 2;
    case 'sinkhole',  net.atk(idx) = 3;
  end
end
