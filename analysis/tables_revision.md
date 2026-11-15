# FEIC 2026 revision statistics (from existing results)

Seed-level percentile bootstrap, 10,000 resamples (generator seed 20261115); (a fresh generator per interval); Wilcoxon signed-rank on matched seeds; HL = Hodges-Lehmann shift; Cliff's delta in [-1, 1]. Shares are fractions of CH-rounds.


## R1 (A3, A5). Displacement: compromised-hardware capture, roster-only minus undefended

| Host | Frac | Roster only | Undefended | Difference [95% CI] | p | HL | Cliff's delta | Ratio (secondary) |
|---|---|---|---|---|---|---|---|---|
| STITCH | 0.1 | 0.0912 | 0.00009 | 0.0911 [0.0793, 0.1039] | < 0.001 | 0.0902 | +1.00 | 1027.8× |
| STITCH | 0.2 | 0.1971 | 0.00126 | 0.1959 [0.1777, 0.2150] | < 0.001 | 0.1929 | +1.00 | 156.5× |
| STITCH | 0.3 | 0.2967 | 0.00084 | 0.2958 [0.2704, 0.3214] | < 0.001 | 0.2961 | +1.00 | 353.1× |
| HEED | 0.1 | 0.1028 | 0.01777 | 0.0850 [0.0729, 0.0977] | < 0.001 | 0.0839 | +1.00 | 5.8× |
| HEED | 0.2 | 0.2033 | 0.03324 | 0.1701 [0.1505, 0.1890] | < 0.001 | 0.1710 | +1.00 | 6.1× |
| HEED | 0.3 | 0.2998 | 0.04729 | 0.2525 [0.2295, 0.2753] | < 0.001 | 0.2530 | +1.00 | 6.3× |
| Tao IT2-TSK | 0.1 | 0.1122 | 0.02198 | 0.0902 [0.0770, 0.1044] | < 0.001 | 0.0897 | +1.00 | 5.1× |
| Tao IT2-TSK | 0.2 | 0.2188 | 0.04431 | 0.1745 [0.1578, 0.1918] | < 0.001 | 0.1749 | +1.00 | 4.9× |
| Tao IT2-TSK | 0.3 | 0.3174 | 0.06184 | 0.2555 [0.2324, 0.2793] | < 0.001 | 0.2546 | +1.00 | 5.1× |

At 20%, the absolute displacement spans 0.170 to 0.196 across the three hosts while the ratio spans 4.9× to 157×.


## R2 (A5). Factorial at 20% (STITCH): bootstrap CIs on shares, t-CI on HND

| Configuration | Forged-CH share | Hardware-CH share | Aggregate | PDR (window) | HND (rounds) | Seeds with forged share = 0 |
|---|---|---|---|---|---|---|
| Roster+Veto | 0.0000 [0.0000, 0.0000] | 0.0007 [0.0006, 0.0009] | 0.0007 [0.0006, 0.0009] | 0.992 [0.991, 0.994] | 634.0 ± 45.6 | 20/20 |
| RosterOnly | 0.0000 [0.0000, 0.0000] | 0.1971 [0.1791, 0.2163] | 0.1971 [0.1791, 0.2163] | 0.992 [0.990, 0.993] | 544.6 ± 44.5 | 20/20 |
| VetoOnly | 0.1005 [0.0919, 0.1090] | 0.0001 [0.0001, 0.0001] | 0.1006 [0.0920, 0.1091] | 0.991 [0.989, 0.993] | 533.9 ± 37.5 | 0/20 |
| Neither | 0.1010 [0.0922, 0.1096] | 0.0013 [0.0002, 0.0028] | 0.1022 [0.0933, 0.1109] | 0.991 [0.990, 0.993] | 528.4 ± 38.4 | 0/20 |

A degenerate cell (0.0000 [0.0000, 0.0000]) means no forged identity held a CH role in any round of any of the 20 seeds. CH-round counts are not stored per run, so no binomial upper bound is given.

| Paired comparison (20%) | Difference [95% CI] | Wilcoxon p | HL | Cliff's delta |
|---|---|---|---|---|
| forged: VetoOnly vs Neither | -0.0004 [-0.0012, 0.0004] | 0.154 | -0.0006 | -0.02 |
| HND: Roster+Veto vs RosterOnly | 89.4 [62.7, 116.8] | < 0.001 | 89.0 | +0.49 |
| HND: Roster+Veto vs VetoOnly | 100.2 [66.5, 137.6] | < 0.001 | 88.8 | +0.59 |


## R3 (A4). Roster × veto interaction on HND

Per seed: I = HND(R+V) − HND(R) − HND(V) + HND(N). For a 2×2 within-seed design the repeated-measures ANOVA interaction F(1, 19) equals the square of the paired t on I.

| Host | Frac | N | R only | V only | R+V | I, rounds [95% CI] | I as % of N | F(1,19) | p (F) | Wilcoxon p |
|---|---|---|---|---|---|---|---|---|---|---|
| STITCH | 0.1 | 541.7 | 543.9 | 541.8 | 590.5 | +46.5 [+28.8, +67.6] | +8.6% | 21.1 | < 0.001 | < 0.001 |
| STITCH | 0.2 | 528.4 | 544.6 | 533.9 | 634.0 | +83.8 [+58.6, +109.6] | +15.9% | 38.1 | < 0.001 | < 0.001 |
| STITCH | 0.3 | 513.6 | 550.2 | 523.4 | 626.6 | +66.6 [+39.3, +97.4] | +13.0% | 18.6 | < 0.001 | < 0.001 |
| HEED | 0.1 | 388.1 | 421.1 | 391.5 | 464.1 | +39.6 [+19.4, +60.7] | +10.2% | 13.4 | 0.002 | 0.002 |
| HEED | 0.2 | 364.6 | 421.1 | 360.7 | 525.8 | +108.5 [+83.0, +133.3] | +29.7% | 67.8 | < 0.001 | < 0.001 |
| HEED | 0.3 | 339.5 | 418.7 | 342.2 | 547.1 | +125.7 [+99.7, +150.2] | +37.0% | 91.0 | < 0.001 | < 0.001 |
| Tao IT2-TSK | 0.1 | 767.5 | 760.4 | 760.4 | 731.0 | -22.2 [-52.5, +6.4] | -2.9% | 2.1 | 0.167 | 0.143 |
| Tao IT2-TSK | 0.2 | 790.9 | 752.0 | 770.6 | 669.2 | -62.5 [-95.6, -31.2] | -7.9% | 13.9 | 0.001 | 0.002 |
| Tao IT2-TSK | 0.3 | 807.2 | 760.4 | 770.0 | 587.4 | -135.8 [-171.3, -99.9] | -16.8% | 52.6 | < 0.001 | < 0.001 |


## R4 (A2). One effective delay, δ_eff = 1 + d

Default setting (η = 0.2, τ = 0.4): measured k = 7.65 (SD 0.489, 95% CI ± 0.23). Undefended forged share 0.10095.

| d (configured) | δ_eff | Observed veto-only [95% CI] | Old prediction k/(k+d) | New prediction k/(k+1+d) |
|---|---|---|---|---|
| 0 | 1 | 0.1005 [0.0919, 0.1090] | 0.1009 | 0.0893 |
| 1 | 2 | 0.1005 [0.0918, 0.1090] | 0.0893 | 0.0800 |
| 2 | 3 | 0.1013 [0.0924, 0.1101] | 0.0800 | 0.0725 |
| 4 | 5 | 0.1026 [0.0931, 0.1119] | 0.0663 | 0.0610 |
| 8 | 9 | 0.1038 [0.0942, 0.1132] | 0.0493 | 0.0464 |
| 16 | 17 | 0.1022 [0.0924, 0.1121] | 0.0327 | 0.0313 |
| 32 | 33 | 0.0988 [0.0853, 0.1135] | 0.0195 | 0.0190 |

Observed slope of capture on d: -0.000057 per round (SE 0.000181, p = 0.75). The k/(k+1+d) curve falls from 0.0893 at d = 0 to 0.0190 at d = 32.

Expected k-slope. The stored value 0.00127 per round is the **secant** of the predicted capture u·k/(k+1) (u = 0.10095) between the smallest and largest measured k (3.00 and 18.95): (u·k_max/(k_max+1) − u·k_min/(k_min+1)) / (k_max − k_min) = 0.00127. A least-squares fit of the predicted values on k over the nine settings gives 0.00114. Observed slope +0.00024 (SE 0.00030).


## R5 (A6). Replication at 20% attackers

| Setting | Max forged share, roster arms | Veto-only hardware share | Displacement (abs) | Ratio | Veto-only / undefended forged | Interaction I (HND) |
|---|---|---|---|---|---|---|
| STITCH, N = 100, central BS | 0.0000 | 0.0001 | 0.196 | 156.5× | 1.00 | +83.8 (p < 0.001) |
| HEED, N = 100, central BS | 0.0000 | 0.0005 | 0.170 | 6.1× | 1.09 | +108.5 (p < 0.001) |
| Tao IT2-TSK, N = 100, central BS | 0.0000 | 0.0004 | 0.174 | 4.9× | 1.27 | -62.5 (p 0.001) |
| STITCH, N = 200, central BS | 0.0000 | 0.0002 | 0.124 | 97.6× | 1.01 | +58.8 (p < 0.001) |
| STITCH, N = 200, edge BS | 0.0000 | 0.0002 | 0.157 | 41.7× | 1.01 | +15.2 (p < 0.001) |
| STITCH, N = 300, central BS | 0.0000 | 0.0002 | 0.124 | 58.1× | 1.00 | +47.0 (p < 0.001) |
| STITCH, N = 300, edge BS | 0.0000 | 0.0002 | 0.139 | 123.9× | 1.01 | +18.7 (p < 0.001) |
| STITCH, N = 500, central BS | 0.0000 | 0.0002 | 0.112 | 55.6× | 1.01 | +32.9 (p < 0.001) |
| STITCH, N = 500, edge BS | 0.0000 | 0.0002 | 0.133 | 100.7× | 1.00 | +19.6 (p < 0.001) |


## R6 (A8). Competition: compromised-hardware capture as forged identities per attacker grow

| Host | Arm | s = 1 | s = 2 | s = 3 | s = 5 | s = 8 | Spearman ρ (s, hw share) | p |
|---|---|---|---|---|---|---|---|---|
| STITCH | Neither | 0.0060 | 0.0013 | 0.0013 | 0.0001 | 0.0001 | -0.81 | < 0.001 |
| STITCH | RosterOnly | 0.2056 | 0.2017 | 0.1971 | 0.1909 | 0.1911 | -0.14 | 0.162 |
| HEED | Neither | 0.0805 | 0.0476 | 0.0332 | 0.0199 | 0.0123 | -0.94 | < 0.001 |
| HEED | RosterOnly | 0.2036 | 0.2035 | 0.2033 | 0.2033 | 0.2038 | -0.00 | 0.983 |
| Tao IT2-TSK | Neither | 0.1061 | 0.0648 | 0.0443 | 0.0251 | 0.0140 | -0.95 | < 0.001 |
| Tao IT2-TSK | RosterOnly | 0.2158 | 0.2196 | 0.2188 | 0.2155 | 0.2171 | +0.01 | 0.959 |

Undefended, forged identities and compromised hardware compete for the same CH roles: more forged identities per attacker leave less for hardware. With the roster on, forged identities are excluded and hardware capture returns to about the attacker fraction regardless of s.


## R7 (B4, B6, B7)

**B4. Consensus layer on and off (STITCH, 20%).**

| Configuration | HND (rounds) | Consensus energy (J) | PDR (window) |
|---|---|---|---|
| Consensus on (energy debited, failed-proposal trust penalty active) | 634.0 ± 45.6 | 0.162 ± 0.005 | 0.992 [0.991, 0.993] |
| Consensus off | 561.5 ± 41.3 | 0.000 ± 0.000 | 0.991 [0.990, 0.993] |

Paired HND difference +72.6 [+37.5, +112.4] rounds, Wilcoxon p < 0.001.

**B6. Sybil admission and block rejection by attacker fraction.**

| Protocol | Frac | Aggregate admission [95% CI] | Block rejection [95% CI] |
|---|---|---|---|
| E-FLZSEPFCH | 0.1 | 0.085 [0.077, 0.095] | 0.000 [0.000, 0.000] |
| E-FLZSEPFCH | 0.2 | 0.179 [0.163, 0.195] | 0.000 [0.000, 0.000] |
| E-FLZSEPFCH | 0.3 | 0.271 [0.252, 0.290] | 0.000 [0.000, 0.000] |
| EA-PoA | 0.1 | 0.101 [0.091, 0.113] | 0.006 [0.002, 0.011] |
| EA-PoA | 0.2 | 0.204 [0.187, 0.222] | 0.032 [0.021, 0.045] |
| EA-PoA | 0.3 | 0.308 [0.288, 0.329] | 0.107 [0.085, 0.130] |
| STITCH | 0.1 | 0.000 [0.000, 0.000] | 0.046 [0.037, 0.055] |
| STITCH | 0.2 | 0.001 [0.000, 0.001] | 0.133 [0.120, 0.147] |
| STITCH | 0.3 | 0.001 [0.001, 0.001] | 0.253 [0.235, 0.271] |

**B7. Table 2 (population decomposition) at four decimals, bootstrap CIs.**

| Configuration | Frac | Forged | Hardware | Aggregate | HND |
|---|---|---|---|---|---|
| Roster+Veto | 0.1 | 0.0000 [0.0000, 0.0000] | 0.0004 [0.0003, 0.0006] | 0.0004 [0.0003, 0.0006] | 590.5 ± 43.8 |
| Roster+Veto | 0.2 | 0.0000 [0.0000, 0.0000] | 0.0007 [0.0006, 0.0009] | 0.0007 [0.0006, 0.0009] | 634.0 ± 45.6 |
| Roster+Veto | 0.3 | 0.0000 [0.0000, 0.0000] | 0.0009 [0.0008, 0.0009] | 0.0009 [0.0008, 0.0009] | 626.6 ± 39.5 |
| RosterOnly | 0.1 | 0.0000 [0.0000, 0.0000] | 0.0912 [0.0795, 0.1040] | 0.0912 [0.0795, 0.1040] | 543.9 ± 41.3 |
| RosterOnly | 0.2 | 0.0000 [0.0000, 0.0000] | 0.1971 [0.1791, 0.2163] | 0.1971 [0.1791, 0.2163] | 544.6 ± 44.5 |
| RosterOnly | 0.3 | 0.0000 [0.0000, 0.0000] | 0.2967 [0.2710, 0.3233] | 0.2967 [0.2710, 0.3233] | 550.2 ± 42.6 |
| VetoOnly | 0.1 | 0.0491 [0.0435, 0.0550] | 0.0001 [0.0000, 0.0001] | 0.0491 [0.0436, 0.0551] | 541.8 ± 42.7 |
| VetoOnly | 0.2 | 0.1005 [0.0919, 0.1090] | 0.0001 [0.0001, 0.0001] | 0.1006 [0.0920, 0.1091] | 533.9 ± 37.5 |
| VetoOnly | 0.3 | 0.1535 [0.1414, 0.1660] | 0.0002 [0.0002, 0.0002] | 0.1537 [0.1416, 0.1662] | 523.4 ± 38.9 |
| Neither | 0.1 | 0.0491 [0.0437, 0.0551] | 0.0001 [0.0001, 0.0001] | 0.0492 [0.0438, 0.0552] | 541.7 ± 42.7 |
| Neither | 0.2 | 0.1010 [0.0922, 0.1096] | 0.0013 [0.0002, 0.0028] | 0.1022 [0.0933, 0.1109] | 528.4 ± 38.4 |
| Neither | 0.3 | 0.1541 [0.1420, 0.1668] | 0.0008 [0.0003, 0.0016] | 0.1550 [0.1426, 0.1679] | 513.6 ± 36.4 |
