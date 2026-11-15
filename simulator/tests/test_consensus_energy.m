function test_consensus_energy()
% TEST_CONSENSUS_ENERGY  Guards the Eq (15) debit in eapoa_round.
% Regression target: an earlier version charged the whole round's consensus
% cost to the leader alone and never called consensus_energy, under-counting
% network consensus energy by roughly the mean cluster size.
  set_seed(11);
  cfg = config_default();
  cfg.protocol = 'proposed';
  net = make_topology(cfg);
  net = sense_inputs(net, cfg);
  net = trust_update(net, cfg);
  net = ch_setup(net, cfg);

  E0 = net.E;
  [net1, consE, blk] = eapoa_round(net, cfg);
  spent = E0 - net1.E;

  part = find(net.cid > 0 & net.alive);
  CHs  = find(net.role == 1 & net.alive);
  assert(~isempty(part) && ~isempty(CHs), 'no authority set to test');

  % (1) energy conservation: the reported total equals what batteries lost
  assert(abs(consE - sum(spent)) < 1e-12, 'consE does not match battery debit');

  % (2) every authority-set member pays at least the non-leader floor E_R + E_I
  floor_e = cfg.ER + cfg.EI;
  assert(all(spent(part) >= floor_e - 1e-15), 'a participant was not debited');

  % (3) nobody outside the authority set pays
  outside = setdiff(find(net.alive), part);
  assert(all(spent(outside) == 0), 'non-participant was debited');

  % (4) exactly one leader per cluster, and each pays E_M + E_R*Nc + E_I
  nClust = numel(CHs);
  leaders = part(spent(part) > floor_e + 1e-15);
  assert(numel(leaders) == nClust, 'expected one leader per cluster');

  % (5) the total matches an independent Eq (15) recomputation
  expect = 0;
  for k = 1:nClust
    memb = part(net.cid(part) == CHs(k));
    Nc = numel(memb);
    [~, li] = max(net.E(memb));                       % Eq 7: highest battery
    for j = 1:Nc
      isL = (j == li);
      expect = expect + consensus_energy(isL, isL*Nc + ~isL*1, cfg);
    end
  end
  assert(abs(expect - consE) < 1e-12, 'total does not match Eq (15) recomputation');

  % (6) the 'ch' scope debits strictly less (CH tier alone)
  cfgCH = cfg; cfgCH.consensusScope = 'ch';
  [~, consE_ch] = eapoa_round(net, cfgCH);
  assert(consE_ch < consE, 'ch scope should cost less than participants scope');

  % (7) the quorum gate is actually wired in: one block per non-empty cluster,
  %     and rejections agree with validate_block recomputed per cluster
  assert(blk.proposed == nClust, 'expected one proposed block per cluster');
  expRej = 0;
  for k = 1:nClust
    memb = part(net.cid(part) == CHs(k));
    if ~validate_block(memb, net, cfg), expRej = expRej + 1; end
  end
  assert(blk.rejected == expRej, 'block-rejection tally does not match validate_block');

  % (8) a majority-malicious cluster must actually be rejected (gate is live)
  netM = net; memb = part(net.cid(part) == CHs(1));
  netM.isMal(memb) = true;
  [~, ~, blkM] = eapoa_round(netM, cfg);
  assert(blkM.rejected >= 1, 'quorum did not reject an all-malicious cluster');

  fprintf(['test_consensus_energy: PASS (consE=%.4g over %d participants, ' ...
           '%d clusters, %d/%d blocks rejected)\n'], ...
          consE, numel(part), nClust, blk.rejected, blk.proposed);
end
