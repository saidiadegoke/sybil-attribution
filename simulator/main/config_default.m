function cfg = config_default()
% CONFIG_DEFAULT  Pinned parameter set (matlab-design-implementation.md §9).
  cfg.N      = 100;
  cfg.field  = [200 200];          % m
  cfg.BS     = [100 100];          % central BS
  cfg.E0     = 0.5;                % J

  % first-order radio model (Heinzelman et al., 2002)
  cfg.Eelec  = 50e-9;             cfg.EDA = 5e-9;
  cfg.efs    = 10e-12;            cfg.emp = 0.0013e-12;
  cfg.d0     = sqrt(cfg.efs / cfg.emp);     % ~87.7 m
  cfg.pktBits  = 4000;           cfg.ctrlBits = 200;

  % PHY / channel
  cfg.Pt      = 20;   cfg.PL0 = 40.05;  cfg.n = 3.5;   cfg.sigma = 4;   % dBm/dB
  cfg.RSSImin = -85;  cfg.RSSImax = -40;  cfg.N0 = -100;                % dBm
  cfg.commRange = 30;                                                   % m

  % competition radius (Eq 14) + link-quality fusion (Eq 10)
  cfg.R0 = 60;   cfg.c = 0.5;   cfg.alpha = 0.6;
  cfg.wLQ = [0.5 0.3 0.2];

  % trust (Eq 11)
  cfg.tau = 0.4;   cfg.lambda = 0.5;   cfg.eta = 0.2;   cfg.T0 = 0.7;

  % EA-PoA consensus (Eqs 7,15)
  cfg.EM = 2e-6;   cfg.ER = 1e-6;   cfg.EI = 1e-7;   cfg.quorum = 0.5;
  cfg.consensusScope = 'participants';   % 'participants' (CH + members) | 'ch'

  % experiment factors
  cfg.channel     = 'shadow';     % 'ideal' | 'shadow'
  cfg.adversary   = 'none';       % 'none'|'sybil'|'blackhole'|'sinkhole'
  cfg.compromised = 0.0;
  cfg.sybilIds    = 3;            % forged identities per attacker (Sybil)
  cfg.sybilJitter = 2;            % m, position spread of forged identities
  cfg.sybilChurn  = true;         % re-mint a vetoed forged identity (whitewash)
  cfg.newcomerT0      = [];       % trust of a RE-MINTED identity ([] = cfg.T0)
  cfg.sybilMintBudget = Inf;      % total re-mints allowed per attacker
  cfg.sybilMintCost   = 0;        % J debited from the attacker per re-mint
  cfg.sinkholeSpoof = true;       % sinkhole advertises full energy, LQ=1 and the
                                  % shortest BS distance at election (false = the
                                  % pre-2026-11-15 relabelled-blackhole behaviour)
  cfg.protocol    = 'proposed';   % 'proposed'|'leach'|'eapoa'
  cfg.pLEACH      = 0.1;          % LEACH target CH proportion
  cfg.maxRounds   = 3000;
  cfg.seed        = 1;

  % IT2 FIS
  cfg.fuzzy = struct('fou', 0.08, 'hLo', 0.7);

  % ablation toggles (all "on" = full proposed protocol)
  cfg.ablation = struct('it2',true, 'signalRc',true, 'veto',true, ...
                        'consensus',true, 'crispSelector',false, ...
                        'permissioned',true, 'vetoAuthority',false);
  cfg.churnDelay = 0;                 % rounds an abandoned identity waits (delta)
  cfg.inputNoise = 0;                 % std added to normalised FIS inputs (H5 test)
  cfg.crispW = [0.4 0.2 0.2 0.2];     % crisp-selector weights [E, (1-d), LQ, T]
  cfg.pdrWindow = 1000;               % rounds for common-window (fair) PDR
end
