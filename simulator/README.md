# STITCH — WSN simulator (MATLAB/Octave)

Reference implementation of the **Signal- and Trust-aware Interval Type-2 Fuzzy
Unequal Clustering with Energy-aware Proof-of-Authority** protocol, built to the
blueprint in `reviews/matlab-design-implementation.md`. Toolbox-free and
Octave-compatible (the Interval Type-2 engine and Karnik–Mendel type-reduction
are hand-coded, per contribution C5).

## Run

```matlab
setup_paths();           % add subfolders to the path (once per session)
res = simulate(config_default());     % single run
run_tests();             % unit + integration tests
S = run_experiments();   % small protocol x channel x seed sweep -> results_raw.csv
```

Octave (command line):

```bash
octave-cli --eval "setup_paths(); run_tests();"
octave-cli --eval "setup_paths(); run_experiments();"
```

## Layout (maps to the design doc)

| Folder | Contents |
|---|---|
| `core/` | `simulate.m` — the round loop (set-up → consensus → data → energy) |
| `protocols/` | `ch_setup` dispatch; `proto_proposed`, `proto_leach` |
| `fuzzy/` | hand-coded IT2: terms, grades, rule base, `it2_fis_stage`, `km_type_reduction` |
| `clustering/` | competition radius (Eq 14), overlap (Eq M6), CH election (Eq 13), member assignment (Eq M7) |
| `consensus/` | EA-PoA: `leader_select` (Eq 7), `validate_block`, `eapoa_round` (Eq 15) + trust feedback |
| `trust/` | `trust_update` (Eq 11) |
| `channel/` | RSSI (Eqs 5–6), weak-link (Eq M1), BER/PDR (Eqs M3–M4), link quality (Eq 10) |
| `energy/` | radio (Eqs 1–2), retransmission-aware (Eq M5), consensus (Eq 15) |
| `network/`, `adversary/`, `metrics/`, `utils/` | topology, attacks, FND/HND/LND/PDR/Jain/coverage, helpers |
| `localization/` | intentionally empty — RSSI is link-quality only (see folder README) |
| `tests/` | `test_km`, `test_rc_bounds`, `test_smoke`, `run_tests` |

## Scope / status

- **Implemented end-to-end:** the proposed protocol and a **LEACH** baseline,
  the full channel/energy/IT2/clustering/trust/EA-PoA/metrics pipeline, the
  experiment driver, and tests.
- **Hooks for the remaining baselines** (HEED, EAUCF, E-FLZSEPFCH, Tao-IT2)
  attach at `protocols/ch_setup.m`; `'eapoa'` currently reuses the proposed
  clustering with consensus.
- **No fabricated results:** the simulator *produces* metrics; the paper's
  Results/Discussion tables are populated from these runs, not hand-written.

## Parameters

All in `main/config_default.m` (first-order radio constants, PHY/channel, Rc,
trust, consensus costs, factors). Override fields per run, e.g.
`cfg.channel='ideal'; cfg.adversary='sybil'; cfg.compromised=0.1;`.
