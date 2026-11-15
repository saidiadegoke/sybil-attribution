function net = ledger_attacks(net, cfg, part, g, nCH, leaders, gLeaders, committed)
% LEDGER_ATTACKS  Adversarial writes against the Local/Master blockchain, and
% the chain rules that refuse them. This measures the third channel of §3.3,
% ledger integrity, which the admission metrics do not observe.
%
% Three attempts are modelled, one per adversarial member of an authority set
% per round. Each is refused by a chain rule unless the adversary can muster a
% quorum inside its own cluster, which is the one condition under which a
% permissioned chain genuinely fails:
%
%   unauthorised write : a non-leader appends a block. Refused by the
%                        leader rule (Eq 7): only the round's elected signer may
%                        extend the chain. No quorum can override this, because
%                        the signature itself is checked, so refusal is total.
%   fork               : a block is proposed against a stale parent, creating a
%                        competing branch. Refused unless the adversary holds
%                        the cluster quorum, in which case the branch is
%                        accepted by that cluster's authority set.
%   rewrite            : an already-committed block is replaced. Refused unless
%                        the adversary holds the cluster quorum.
%
% The 100% refusal of unauthorised writes is a property of the model, not an
% empirical discovery, and is reported as such. The empirical content is the
% NUMBER of attempts each configuration exposes itself to, and the fork and
% rewrite success rates, both of which depend on how many adversaries the
% roster and veto have admitted to the authority sets.
  if isempty(part), return; end

  adv = net.isMal(part);
  if ~any(adv), return; end

  % Malicious fraction of each cluster's authority set: the quorum an adversary
  % would have to hold to get a forged branch accepted.
  cnt   = accumarray(g(:), 1,               [nCH,1]);
  nbad  = accumarray(g(:), double(adv(:)),  [nCH,1]);
  badFrac = nbad ./ max(cnt, 1);
  advQuorum = badFrac >= cfg.quorum;               % nCH x 1 logical

  advIdx = find(adv);                              % positions within `part`
  gAdv   = g(advIdx);                              % their cluster indices
  isLeadAdv = ismember(part(advIdx), leaders);

  % --- unauthorised write: every adversarial NON-leader attempts one ---------
  nUnauth = sum(~isLeadAdv);
  net.ledger.unauthAtt = net.ledger.unauthAtt + nUnauth;
  % refused by the leader rule in every case; none succeed
  net.ledger.unauthOk  = net.ledger.unauthOk + 0;

  % --- fork: every adversarial member attempts one stale-parent proposal -----
  net.ledger.forkAtt = net.ledger.forkAtt + numel(advIdx);
  net.ledger.forkOk  = net.ledger.forkOk  + sum(advQuorum(gAdv));

  % --- rewrite: attempted only where there is history to rewrite ------------
  if net.ledger.height > 0
    net.ledger.rewriteAtt = net.ledger.rewriteAtt + numel(advIdx);
    net.ledger.rewriteOk  = net.ledger.rewriteOk  + sum(advQuorum(gAdv));
  end

  % --- authorship of the blocks that WERE committed this round --------------
  if ~isempty(committed)
    net.ledger.commits    = net.ledger.commits + numel(committed);
    net.ledger.advCommits = net.ledger.advCommits + sum(net.isMal(committed));
    net.ledger.height     = net.ledger.height + numel(committed);
  end
end
