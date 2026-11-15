# STITCH host protocol: full specification

Supplement to *Roster or Reputation? Attributing Sybil Resistance to Mechanisms in Secure Clustered Wireless Sensor Networks: A Simulation Study* (FEIC 2026), Section 3.3. Every value below is taken from the simulator in `simulator/`; file names are given so each statement can be checked against the code.

## 1. Round structure (`core/simulate.m`)

Each round runs, in order:

1. **Sensing** (`network/sense_inputs.m`): local density and link quality from the current alive set.
2. **Trust update** (`trust/trust_update.m`), from the evidence accumulated so far.
3. **Cluster set-up** (`protocols/ch_setup.m` → `protocols/proto_proposed.m`): admission gate, two-stage IT2 inference, competition election, member assignment. Under the sinkhole attack, `adversary/sinkhole_advertise.m` substitutes inflated self-reported inputs for this step only.
4. **Consensus** (`consensus/eapoa_round.m`): one block per cluster, quorum vote, trust evidence, consensus energy.
5. **Data phase**: members send one packet to their head; the head aggregates and forwards to the base station. A compromised head under blackhole or sinkhole drops its cluster's traffic.
6. **Identity churn** (`adversary/churn_sybil.m`): forged identities whose trust has fallen below τ are re-minted.

## 2. Parameters (`main/config_default.m`)

| Symbol | Meaning | Value |
|---|---|---|
| N | deployed nodes | 100 |
| field | deployment area | 200 × 200 m², base station at the centre |
| E₀ | initial energy per node | 0.5 J |
| E_elec, ε_fs, ε_mp, E_DA | first-order radio model | 50 nJ/bit, 10 pJ/bit/m², 0.0013 pJ/bit/m⁴, 5 nJ/bit/signal |
| packet sizes | data, control | 4000 bits, 200 bits |
| P_t, PL₀, n, σ | transmit power, reference path loss, path-loss exponent, shadowing | 20 dBm, 40.05 dB, 3.5, 4 dB |
| RSSI_min, RSSI_max | normalisation range | −85 dBm, −40 dBm |
| τ | veto threshold | 0.4 |
| η | trust update rate | 0.2 |
| λ | weight of consensus agreement in trust | 0.5 |
| T₀ | initial trust of every identity | 0.7 |
| R₀, c, α | competition radius constants | 60 m, 0.5, 0.6 |
| w_LQ | link-quality fusion weights (RSSI, LQI proxy, PRR) | 0.5, 0.3, 0.2 |
| FOU, h_L | IT2 footprint width, lower-MF height | 0.08, 0.7 |
| quorum | agreeing fraction needed to commit a block | 0.5, i.e. ⌈N_c/2⌉ of N_c |
| E_M, E_R, E_I | consensus energy: sign, relay per validation, idle | 2 μJ, 1 μJ, 0.1 μJ |
| s | forged identities per attacker | 3 |

## 3. Trust (`trust/trust_update.m`, `consensus/eapoa_round.m`)

Each identity i holds a positive evidence count f_i and a negative count u_i (both start at 1), an agreement estimate Â_i (starts at 1) and trust T_i (starts at T₀). Every round:

T_i ← clip₀¹( (1 − η)·T_i + η·[ (1 − λ)·f_i / max(f_i + u_i, 1) + λ·Â_i ] )

**All evidence comes from the consensus round.** In each round, every member of a cluster's authority set (Section 6) casts a validation. An honest member gains f_i ← f_i + 1; a compromised node or forged identity gains u_i ← u_i + 1. The proposer of a block that fails quorum takes a further u_i ← u_i + 1. The agreement estimate is updated as Â_i ← 0.7·Â_i + 0.3·(honest fraction of i's authority set).

Two consequences follow, and the paper relies on both:

- The detector is **idealised**: every validation cast by a malicious identity counts against it. A noisier detector would lengthen the rounds-to-conviction k; Section 4.5 of the paper sweeps k from 3 to 19 rounds.
- With the consensus layer disabled, no evidence accrues, every trust score converges to (1 − λ)·0.5 + λ·1 = 0.75, which is above τ, and the veto excludes no one. This is why the consensus layer is worth 12.9% of half-life in the paper's Section 4.6.

A forged identity that is not on the roster never enters an authority set, so it gathers no evidence; under the roster it is refused on identity instead.

## 4. Election inputs (`network/sense_inputs.m`, `channel/link_quality.m`)

All inputs lie in [0, 1]:

| Input | Definition |
|---|---|
| Ê | residual energy, min-max normalised across nodes |
| LQ | 0.5·RSSIₙ + 0.3·LQIₙ + 0.2·PRR, where RSSIₙ is the mean RSSI to alive neighbours normalised over [RSSI_min, RSSI_max], LQIₙ = RSSIₙ (proxy), and PRR is the packet reception ratio at that RSSI |
| T | trust (Section 3) |
| ρ | alive-neighbour count within the 30 m communication range, divided by the network maximum |
| D | 1 − min-max normalised distance to the base station |

## 5. Two-stage Interval Type-2 inference (`fuzzy/`)

- **Stage 1, reliability:** (Ê, LQ, T) → Re.
- **Stage 2, eligibility:** (Re, ρ, D) → χ, the election score.

**Membership functions** (`make_it2_terms.m`). Each input has three terms, Low, Medium and High, built on principal triangles centred at 0, 0.5 and 1 with half-width 0.5. The upper membership function widens the triangle's feet by the FOU (0.08); the lower one narrows them by 0.08 and is scaled to height h_L = 0.7, and is clipped to stay below the upper one.

**Inference** (`it2_fis_stage_vec.m`). Firing interval of each rule: minimum t-norm over the lower grades and over the upper grades. Consequent centroids: Low 0, Medium 0.5, High 1. Type reduction: Karnik-Mendel, by exhaustive switch-point search over the 27 sorted rules. Output: the midpoint (y_l + y_r)/2. A node that fires no rule scores 0.

**Rule bases** (`build_rulebase.m`). Each stage has a complete base of 3³ = 27 rules. The consequent is set by a fixed monotone score of the antecedent term indices (Low = 1, Medium = 2, High = 3): output Low if the score ≤ 1.8, Medium if ≤ 2.4, High otherwise.

- Reliability score: 0.35·Energy + 0.30·LinkQuality + 0.35·Trust, capped at 1.5 when Trust is Low (so low trust always gives Low reliability).
- Eligibility score: 0.50·Reliability + 0.25·Density + 0.25·Proximity.

### Stage 1 rule base (reliability)

| # | Energy | Link quality | Trust | Score | Output |
|---|---|---|---|---|---|
| 1 | Low | Low | Low | 1.00 | Low |
| 2 | Medium | Low | Low | 1.35 | Low |
| 3 | High | Low | Low | 1.50 | Low |
| 4 | Low | Medium | Low | 1.30 | Low |
| 5 | Medium | Medium | Low | 1.50 | Low |
| 6 | High | Medium | Low | 1.50 | Low |
| 7 | Low | High | Low | 1.50 | Low |
| 8 | Medium | High | Low | 1.50 | Low |
| 9 | High | High | Low | 1.50 | Low |
| 10 | Low | Low | Medium | 1.35 | Low |
| 11 | Medium | Low | Medium | 1.70 | Low |
| 12 | High | Low | Medium | 2.05 | Medium |
| 13 | Low | Medium | Medium | 1.65 | Low |
| 14 | Medium | Medium | Medium | 2.00 | Medium |
| 15 | High | Medium | Medium | 2.35 | Medium |
| 16 | Low | High | Medium | 1.95 | Medium |
| 17 | Medium | High | Medium | 2.30 | Medium |
| 18 | High | High | Medium | 2.65 | High |
| 19 | Low | Low | High | 1.70 | Low |
| 20 | Medium | Low | High | 2.05 | Medium |
| 21 | High | Low | High | 2.40 | Medium |
| 22 | Low | Medium | High | 2.00 | Medium |
| 23 | Medium | Medium | High | 2.35 | Medium |
| 24 | High | Medium | High | 2.70 | High |
| 25 | Low | High | High | 2.30 | Medium |
| 26 | Medium | High | High | 2.65 | High |
| 27 | High | High | High | 3.00 | High |

### Stage 2 rule base (eligibility)

| # | Reliability | Density | Proximity to BS | Score | Output |
|---|---|---|---|---|---|
| 1 | Low | Low | Low | 1.00 | Low |
| 2 | Medium | Low | Low | 1.50 | Low |
| 3 | High | Low | Low | 2.00 | Medium |
| 4 | Low | Medium | Low | 1.25 | Low |
| 5 | Medium | Medium | Low | 1.75 | Low |
| 6 | High | Medium | Low | 2.25 | Medium |
| 7 | Low | High | Low | 1.50 | Low |
| 8 | Medium | High | Low | 2.00 | Medium |
| 9 | High | High | Low | 2.50 | High |
| 10 | Low | Low | Medium | 1.25 | Low |
| 11 | Medium | Low | Medium | 1.75 | Low |
| 12 | High | Low | Medium | 2.25 | Medium |
| 13 | Low | Medium | Medium | 1.50 | Low |
| 14 | Medium | Medium | Medium | 2.00 | Medium |
| 15 | High | Medium | Medium | 2.50 | High |
| 16 | Low | High | Medium | 1.75 | Low |
| 17 | Medium | High | Medium | 2.25 | Medium |
| 18 | High | High | Medium | 2.75 | High |
| 19 | Low | Low | High | 1.50 | Low |
| 20 | Medium | Low | High | 2.00 | Medium |
| 21 | High | Low | High | 2.50 | High |
| 22 | Low | Medium | High | 1.75 | Low |
| 23 | Medium | Medium | High | 2.25 | Medium |
| 24 | High | Medium | High | 2.75 | High |
| 25 | Low | High | High | 2.00 | Medium |
| 26 | Medium | High | High | 2.50 | High |
| 27 | High | High | High | 3.00 | High |

## 6. Admission, election and membership

**Admission gate** (`protocols/ch_eligible.m`, shared by every secured host). A node may stand for cluster head this round only if it is alive, is on the deployment roster when the roster is on (`consensus/admissible.m`), and has T_i ≥ τ when the veto is on. Turning a mechanism off removes its condition and nothing else.

**Competition election** (`clustering/elect_competition.m`). Eligible nodes are sorted by χ, highest first. Each in turn becomes a cluster head unless an already chosen head lies within its competition radius

Rc_i = R₀ · (1 − c·Dr_i) · (α·LQ_i + (1 − α)·(1 − O_i)), bounded to [0, R₀],

where Dr_i = (d_max − d_i)/(d_max − d_min) is the node's normalised closeness to the base station and O_i is the fraction of its sensing disk overlapped by alive neighbours (`clustering/competition_radius_all.m`). Nodes near the base station therefore get smaller radii, giving unequal clusters. If no node is eligible, the round has no cluster head.

**Membership** (`clustering/member_assign.m`). Every other alive node joins the head that maximises RSSIₙ × max(R₀ − d, 0)/R₀, with a small bonus for links at least 5 dB above RSSI_min.

## 7. Consensus (`consensus/eapoa_round.m`, `validate_block.m`, `energy/consensus_energy.m`)

- **Authority set.** For each cluster: its alive members, including the head, that pass the roster test (every member, when the roster is off). Its size is N_c. The authority set is not veto-gated by default; `cfg.ablation.vetoAuthority` extends the veto to it.
- **Proposer.** The member with the highest residual energy (battery-aware Proof-of-Authority).
- **Quorum.** The block is committed when the honest agreeing fraction is at least 0.5, that is, at least ⌈N_c/2⌉ of N_c members agree. A rejected block is not committed and its proposer takes a negative evidence count.
- **Energy (Eq. 15).** Each member pays E_I every round and E_R per validation it relays (once); the proposer also pays E_M and relays to all N_c members. Energy spent by a forged identity is charged to its attacker's single battery.
- **Effect of the toggles.** Switching the roster or the veto changes which nodes may stand or validate. It changes no energy constant.

## 8. Adversary (`adversary/`)

Compromised nodes are drawn at the stated fraction. Under Sybil, each fabricates s forged identities placed within 2 m of it, sharing its battery. Forged identities compete for roles and occupy cluster slots but carry no sensor and send no data. Under churn (the default) a forged identity whose trust falls below τ is discarded and re-announced under a fresh name after an additional delay d (default 0), so the effective delay is δ = 1 + d. The sensitivity knobs `cfg.newcomerT0`, `cfg.sybilMintBudget` and `cfg.sybilMintCost` are off by default.
