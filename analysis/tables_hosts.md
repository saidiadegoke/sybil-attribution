# Cross-host attribution (20 seeds, mean ± 95% CI)

Rows: 720 · hosts: ['proposed', 'tao_secured', 'heed_secured']


## H1. Coverage matrix by host (20% attackers)

| Host | Configuration | n | Forged-CH share | Compromised-hardware share | Aggregate |
|---|---|---|---|---|---|
| ST-IT2FUC (trust-consuming) | Roster+Veto | 20 | 0.0000 ± 0.0000 | 0.0007 ± 0.0002 | 0.0007 ± 0.0002 |
| ST-IT2FUC (trust-consuming) | RosterOnly | 20 | 0.0000 ± 0.0000 | 0.1971 ± 0.0203 | 0.1971 ± 0.0203 |
| ST-IT2FUC (trust-consuming) | VetoOnly | 20 | 0.1005 ± 0.0094 | 0.0001 ± 0.0000 | 0.1006 ± 0.0094 |
| ST-IT2FUC (trust-consuming) | Neither | 20 | 0.1010 ± 0.0096 | 0.0013 ± 0.0015 | 0.1022 ± 0.0096 |
| Tao IT2-TSK (trust-blind, independent) | Roster+Veto | 20 | 0.0000 ± 0.0000 | 0.0312 ± 0.0072 | 0.0312 ± 0.0072 |
| Tao IT2-TSK (trust-blind, independent) | RosterOnly | 20 | 0.0000 ± 0.0000 | 0.2188 ± 0.0209 | 0.2188 ± 0.0209 |
| Tao IT2-TSK (trust-blind, independent) | VetoOnly | 20 | 0.1839 ± 0.0155 | 0.0004 ± 0.0001 | 0.1843 ± 0.0155 |
| Tao IT2-TSK (trust-blind, independent) | Neither | 20 | 0.1453 ± 0.0120 | 0.0443 ± 0.0040 | 0.1897 ± 0.0150 |
| HEED (trust-blind, independent) | Roster+Veto | 20 | 0.0000 ± 0.0000 | 0.0009 ± 0.0000 | 0.0009 ± 0.0000 |
| HEED (trust-blind, independent) | RosterOnly | 20 | 0.0000 ± 0.0000 | 0.2033 ± 0.0243 | 0.2033 ± 0.0243 |
| HEED (trust-blind, independent) | VetoOnly | 20 | 0.1085 ± 0.0105 | 0.0005 ± 0.0000 | 0.1089 ± 0.0105 |
| HEED (trust-blind, independent) | Neither | 20 | 0.0993 ± 0.0106 | 0.0332 ± 0.0035 | 0.1326 ± 0.0141 |


## H2. Do the structural claims replicate?

| Claim | ST-IT2FUC (trust-consuming) | Tao IT2-TSK (trust-blind, independent) | HEED (trust-blind, independent) |
|---|---|---|---|
| Roster arms: max forged capture (any frac, any seed) | 0.0000 | 0.0000 | 0.0000 |
| Veto-only forged capture vs undefended (ratio) | 1.00 | 1.27 | 1.09 |
| Veto covers hardware: VetoOnly / RosterOnly hw capture | 0.0006 | 0.0019 | 0.0023 |


## H3. Displacement by host and direction (20% attackers, paired by seed)

Forward: does the roster alone arm the hardware channel? Reverse: does the veto alone arm the forged channel?

| Host | Direction | defended arm | undefended | ratio | paired t | p |
|---|---|---|---|---|---|---|
| ST-IT2FUC (trust-consuming) | roster → hardware | 0.1971 | 0.0013 | 157× | 20.11 | 2.9e-14 |
| ST-IT2FUC (trust-consuming) | veto → forged | 0.1005 | 0.1010 | 1.0× | -1.08 | 2.9e-01 |
| Tao IT2-TSK (trust-blind, independent) | roster → hardware | 0.2188 | 0.0443 | 4.9× | 19.76 | 4.0e-14 |
| Tao IT2-TSK (trust-blind, independent) | veto → forged | 0.1839 | 0.1453 | 1.3× | 16.41 | 1.1e-12 |
| HEED (trust-blind, independent) | roster → hardware | 0.2033 | 0.0332 | 6.1× | 16.99 | 6.0e-13 |
| HEED (trust-blind, independent) | veto → forged | 0.1085 | 0.0993 | 1.1× | 18.63 | 1.2e-13 |


## H4. Half-life interaction by host (20% attackers)

| Host | neither | veto only | roster only | roster+veto | joint gain | sum of parts | p (joint vs best single) |
|---|---|---|---|---|---|---|---|
| ST-IT2FUC (trust-consuming) | 528.4 | 533.9 | 544.6 | 634.0 | +20.0% | +4.1% | 5.9e-06 |
| Tao IT2-TSK (trust-blind, independent) | 790.9 | 770.6 | 752.0 | 669.2 | -15.4% | -7.5% | 2.5e-06 |
| HEED (trust-blind, independent) | 364.6 | 360.7 | 421.1 | 525.8 | +44.2% | +14.5% | 7.0e-08 |
