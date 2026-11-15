"""Adversary-model sensitivity (FEIC 2026 revision, Reviewer 2).

For each one-at-a-time change to the adversary model, compares veto-only
forged-CH capture with the undefended ('neither') arm on matched seeds:
paired difference with a seed-level bootstrap 95% CI (10,000 resamples) and a
Wilcoxon signed-rank test. Writes tables_sensitivity.md and
key_numbers_sensitivity.json.
"""
import glob, json, os
import numpy as np, pandas as pd
from scipy import stats

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "results")
OUT = os.path.join(ROOT, "analysis")
RNG = np.random.default_rng(20261115)

LABEL = {"T0n": "Re-minted identity trust T0n (tau = 0.4)",
         "budget": "Re-mints allowed per attacker",
         "cost": "Energy per re-mint (J, battery 0.5 J)",
         "s": "Forged identities per attacker s"}
DEFAULT = {"T0n": 0.7, "budget": np.inf, "cost": 0.0, "s": 3}


def boot_ci(d, n=10000):
    d = np.asarray(d, float)
    if np.allclose(d, d[0]):
        return d.mean(), d.mean()
    idx = np.random.default_rng(20261115).integers(0, len(d), size=(n, len(d)))  # reproducible per interval
    m = d[idx].mean(axis=1)
    return np.percentile(m, 2.5), np.percentile(m, 97.5)


def wilcoxon_p(d):
    d = np.asarray(d, float)
    if np.allclose(d, 0):
        return 1.0
    return float(stats.wilcoxon(d).pvalue)


def fmt_p(p):
    return "< 0.001" if p < 0.001 else f"{p:.3f}"


def main():
    fs = sorted(glob.glob(os.path.join(RES, "shards", "sens", "sens_*.csv")))
    if not fs:
        raise SystemExit("no sensitivity shards found")
    df = pd.concat([pd.read_csv(f) for f in fs], ignore_index=True)
    df.to_csv(os.path.join(RES, "sensitivity_20.csv"), index=False)

    out = ["# Adversary-model sensitivity (20 seeds, 20% attackers, host STITCH, roster off)\n",
           f"Rows: {len(df)}. One factor changed at a time from the default adversary "
           "(T0n = 0.7, unlimited free re-minting, s = 3, delta = 0). Difference = veto-only "
           "minus undefended forged-CH share on matched seeds; bootstrap 95% CI; Wilcoxon signed-rank.\n"]
    key = {}
    for st in ["T0n", "budget", "cost", "s"]:
        g = df[df.study == st]
        if g.empty:
            continue
        out.append(f"\n## {LABEL[st]}\n")
        out.append("| Level | Veto-only forged-CH | Undefended forged-CH | Difference [95% CI] | p | Veto / undefended | Re-mints (veto-only) | HND veto-only |")
        out.append("|---|---|---|---|---|---|---|---|")
        for lv in sorted(g.level.unique()):
            v = g[(g.level == lv) & (g.arm == "veto-only")].sort_values("seed")
            n = g[(g.level == lv) & (g.arm == "neither")].sort_values("seed")
            assert list(v.seed) == list(n.seed)
            d = v.sybCH.values - n.sybCH.values
            lo, hi = boot_ci(d)
            p = wilcoxon_p(d)
            ratio = v.sybCH.mean() / n.sybCH.mean() if n.sybCH.mean() > 0 else np.nan
            tag = " (default)" if (lv == DEFAULT[st] or (np.isinf(lv) and np.isinf(DEFAULT[st]))) else ""
            lvs = "unlimited" if np.isinf(lv) else f"{lv:g}"
            out.append(f"| {lvs}{tag} | {v.sybCH.mean():.4f} | {n.sybCH.mean():.4f} | "
                       f"{d.mean():+.4f} [{lo:+.4f}, {hi:+.4f}] | {fmt_p(p)} | {ratio:.2f} | "
                       f"{v.churnTotal.mean():,.0f} | {v.HND.mean():.0f} |")
            key[f"{st}@{lvs}"] = dict(veto=float(v.sybCH.mean()), neither=float(n.sybCH.mean()),
                                      diff=float(d.mean()), ci=[float(lo), float(hi)], p=p,
                                      ratio=float(ratio), remints=float(v.churnTotal.mean()),
                                      hnd_veto=float(v.HND.mean()), hnd_neither=float(n.HND.mean()))
    open(os.path.join(OUT, "tables_sensitivity.md"), "w").write("\n".join(out) + "\n")
    json.dump(key, open(os.path.join(OUT, "key_numbers_sensitivity.json"), "w"), indent=1)
    print("\n".join(out))


if __name__ == "__main__":
    main()
