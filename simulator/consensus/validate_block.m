function [ok, agree] = validate_block(mem, net, cfg)
% VALIDATE_BLOCK  Members validate the round's block. A member's validation is
% honest unless it is malicious (Sybil/forging). Block is accepted if the
% honest fraction meets the quorum.
  agree = ~net.isMal(mem);                 % logical 1xK : honest agreement
  ok = mean(agree) >= cfg.quorum;
end
