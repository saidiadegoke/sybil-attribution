# Adversary-model sensitivity (20 seeds, 20% attackers, host STITCH, roster off)

Rows: 600. One factor changed at a time from the default adversary (T0n = 0.7, unlimited free re-minting, s = 3, delta = 0). Difference = veto-only minus undefended forged-CH share on matched seeds; bootstrap 95% CI; Wilcoxon signed-rank.


## Re-minted identity trust T0n (tau = 0.4)

| Level | Veto-only forged-CH | Undefended forged-CH | Difference [95% CI] | p | Veto / undefended | Re-mints (veto-only) | HND veto-only |
|---|---|---|---|---|---|---|---|
| 0.3 | 0.0005 | 0.1195 | -0.1190 [-0.1322, -0.1063] | < 0.001 | 0.00 | 68,483 | 621 |
| 0.4 | 0.1120 | 0.1113 | +0.0006 [-0.0007, +0.0022] | 0.812 | 1.01 | 6,412 | 537 |
| 0.5 | 0.1073 | 0.1073 | -0.0000 [-0.0008, +0.0009] | 0.841 | 1.00 | 5,410 | 537 |
| 0.7 (default) | 0.1005 | 0.1010 | -0.0004 [-0.0012, +0.0004] | 0.154 | 1.00 | 4,403 | 534 |

## Re-mints allowed per attacker

| Level | Veto-only forged-CH | Undefended forged-CH | Difference [95% CI] | p | Veto / undefended | Re-mints (veto-only) | HND veto-only |
|---|---|---|---|---|---|---|---|
| 3 | 0.0013 | 0.0015 | -0.0001 [-0.0001, -0.0001] | < 0.001 | 0.93 | 60 | 624 |
| 10 | 0.0039 | 0.0042 | -0.0003 [-0.0003, -0.0002] | < 0.001 | 0.93 | 236 | 624 |
| 30 | 0.0091 | 0.0096 | -0.0006 [-0.0007, -0.0004] | < 0.001 | 0.94 | 580 | 609 |
| unlimited (default) | 0.1005 | 0.1010 | -0.0004 [-0.0012, +0.0004] | 0.154 | 1.00 | 4,403 | 534 |

## Energy per re-mint (J, battery 0.5 J)

| Level | Veto-only forged-CH | Undefended forged-CH | Difference [95% CI] | p | Veto / undefended | Re-mints (veto-only) | HND veto-only |
|---|---|---|---|---|---|---|---|
| 0.001 | 0.0481 | 0.0484 | -0.0004 [-0.0008, +0.0000] | 0.133 | 0.99 | 2,975 | 469 |
| 0.01 | 0.0091 | 0.0094 | -0.0003 [-0.0004, -0.0001] | 0.004 | 0.97 | 786 | 337 |

## Forged identities per attacker s

| Level | Veto-only forged-CH | Undefended forged-CH | Difference [95% CI] | p | Veto / undefended | Re-mints (veto-only) | HND veto-only |
|---|---|---|---|---|---|---|---|
| 1 | 0.1043 | 0.1017 | +0.0026 [+0.0014, +0.0038] | < 0.001 | 1.03 | 1,398 | 543 |
| 2 | 0.1028 | 0.1026 | +0.0001 [-0.0011, +0.0015] | 0.729 | 1.00 | 2,884 | 537 |
| 3 (default) | 0.1005 | 0.1010 | -0.0004 [-0.0012, +0.0004] | 0.154 | 1.00 | 4,403 | 534 |
| 5 | 0.0998 | 0.0996 | +0.0002 [-0.0006, +0.0010] | 0.330 | 1.00 | 7,419 | 525 |
| 8 | 0.0998 | 0.0991 | +0.0006 [-0.0009, +0.0026] | 0.956 | 1.01 | 11,967 | 520 |
