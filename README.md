# Roster or Reputation? Sybil mechanism attribution in clustered WSNs

Simulation code, raw results and analysis scripts for the paper

> **Roster or Reputation? Attributing Sybil Resistance to Mechanisms in Secure Clustered Wireless Sensor Networks: A Simulation Study**
> (FEIC 2026, Faculty of Engineering International Conference, University of Lagos)

Secure clustering protocols for wireless sensor networks bundle a registration roster, a behavioural trust veto and a consensus quorum, then report one aggregate security figure. This repository runs the factorial ablation that separates them: it switches the roster and the veto on and off in every combination, counts forged identities and compromised hardware separately, and sweeps the defender's and the attacker's time constants.

## Layout

| Folder | Contents |
|---|---|
| `simulator/` | The reference simulator (MATLAB/Octave, toolbox-free). The host protocol STITCH, the baselines E-FLZSEPFCH and EA-PoA, the cross-host protocols HEED and Tao IT2-TSK, the radio, energy, trust, consensus and adversary models, and unit tests |
| `sim/` | This paper's experiment drivers (`attr_*.m`) and the shard runners (`run_*.sh`) |
| `results/` | Merged per-seed CSVs, plus `shards/` holding the raw per-shard output |
| `analysis/` | Python scripts that merge the shards and produce every table, confidence interval and test in the paper, plus their generated output |
| `figures/` | The paper's figures; `simulator/figures/` holds the simulator's own figures |

The roster and the veto share one gate, `simulator/protocols/ch_eligible.m`, on every host, so the mechanisms cannot drift between hosts.

## Requirements

- GNU Octave (tested with 11.3) or MATLAB. No toolboxes are needed.
- Python 3 with `numpy`, `pandas`, `scipy` and `matplotlib` for the analysis.

## Quick start

```bash
cd sim
octave-cli --eval "attr_setup(); run_tests();"     # 8 simulator tests
octave-cli --eval "attr_setup(); r = simulate(config_default()); disp(r.HND)"
```

`attr_setup` finds the simulator in `../simulator` and puts it on the Octave path.

## Reproducing the campaign

Every experiment runs at 20 seeds, sharded across processes; each shard writes its own CSV to `results/shards/`.

```bash
cd sim
./run_all.sh          # wave 1: adversary sweep, ablations, k-sweep
./run_wave2.sh        # wave 2: roster x veto factorial across attacker fractions
./run_wave3.sh        # wave 3: the same factorial on the HEED and Tao IT2-TSK hosts
./run_wave4.sh        # wave 4: ledger integrity, re-mint delay, s-scaling, scale and topology
./run_sinkfix.sh      # sinkhole rerun with election attraction (see below)
./run_sensitivity.sh  # adversary-model sensitivity: re-minted trust, mint budget, mint cost, s
cd ../analysis
python3 analyze.py         # main tables  -> tables.md, key_numbers.json
python3 analyze_hosts.py   # cross-host   -> tables_hosts.md
python3 analyze_wave4.py   # wave 4       -> tables_wave4.md
python3 figures.py         # figures      -> ../figures/
```

| Driver | Grid | Runs |
|---|---|---|
| `attr_adversary` | 3 protocols x 3 attacks x 3 fractions x 20 seeds | 540 |
| `attr_ablations` | 10 ablation arms x 20 seeds | 200 |
| `attr_ksweep` | 9 (eta, tau) settings x 3 arms x 20 seeds | 540 |
| `attr_factorial_sweep` | 4 arms x 3 fractions x 20 seeds | 240 |
| `attr_hosts` | 2 hosts x 4 arms x 3 fractions x 20 seeds | 480 |
| `attr_ledger` | 4 arms x 3 fractions x 20 seeds | 240 |
| `attr_delay` | 7 delays x 2 arms x 20 seeds | 280 |
| `attr_scaling` | 3 hosts x 5 s-values x 2 arms x 20 seeds | 600 |
| `attr_scale_topo` | 3 sizes x 2 base-station placements x 4 arms x 20 seeds | 480 |
| `attr_adversary` (sinkhole rerun) | 3 protocols x 3 fractions x 20 seeds | 180 |
| `attr_sensitivity` | 13 adversary settings x 2 arms x 20 seeds | 600 |

## Corrections and additions in the FEIC 2026 revision

- **Sinkhole.** Earlier runs simulated the sinkhole as a relabelled blackhole: the same drop rule, with no attraction. A sinkhole node now advertises inflated self-reported election inputs (full residual energy, maximum link quality, shortest distance to the base station) during election only (`simulator/adversary/sinkhole_advertise.m`), then drops like a blackhole. `cfg.sinkholeSpoof = false` reproduces the old behaviour. `analysis/analyze.py` replaces the old sinkhole rows with the rerun in `results/shards/sinkfix/`. The test `simulator/tests/test_sinkhole.m` checks that a sinkhole out-attracts a blackhole.
- **Adversary-model sensitivity.** Three new knobs, each off by default so every earlier result is unchanged: `cfg.newcomerT0` (trust of a re-minted identity), `cfg.sybilMintBudget` (re-mints allowed per attacker) and `cfg.sybilMintCost` (energy per re-mint). They are documented in `simulator/adversary/churn_sybil.m` and swept by `sim/attr_sensitivity.m`.

## Licence

MIT; see [LICENSE](LICENSE).

## Citation

If you use this code, please cite the paper and this software; see [CITATION.cff](CITATION.cff). The archived release has a Zenodo DOI.
