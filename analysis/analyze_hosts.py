#!/usr/bin/env python3
"""Cross-host attribution analysis.

The same roster x veto factorial on three hosts whose election rules differ in
how much they consume trust:
  proposed     -- trust is a graded antecedent in the election (fuzzy IT2)
  tao_secured  -- fuzzy IT2 TSK, but trust-blind (Tao, Zhang & Yang, 2020)
  heed_secured -- residual-energy probability, trust-blind (Younis & Fahmy, 2004)

The prediction registered before the runs: the roster and veto COVERAGE columns
are structural and should replicate on every host; the DISPLACEMENT magnitude is
not, because it depends on how far the host's own election already suppresses
compromised hardware in the undefended arm.
"""
import glob, json, os
import numpy as np, pandas as pd
from scipy import stats

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES, OUT = os.path.join(ROOT, "results"), os.path.join(ROOT, "analysis")

def ci(x):
    x = np.asarray(x, float); x = x[~np.isnan(x)]; n = len(x)
    if n < 2 or np.allclose(x, x[0]): return (x.mean() if n else np.nan), 0.0
    return x.mean(), stats.sem(x) * stats.t.ppf(0.975, n - 1)

def f(m, h, dp=4): return f"{m:.{dp}f} ± {h:.{dp}f}"

def main():
    fs = sorted(glob.glob(os.path.join(RES, "shards", "hosts_*.csv")))
    if not fs: raise SystemExit("no host shards")
    h = pd.concat([pd.read_csv(x) for x in fs], ignore_index=True)
    h.to_csv(os.path.join(RES, "hosts.csv"), index=False)

    # fold the original host in from the wave-2 factorial, same grid
    p = pd.read_csv(os.path.join(RES, "factorial_sweep.csv")).copy()
    p["host"] = "proposed"
    cols = ["host", "arm", "frac", "seed", "sybCH", "malCHrate", "PDRwin", "HND",
            "churnTotal", "blkRej"]
    allh = pd.concat([p[cols], h[cols]], ignore_index=True)
    allh["hwCH"] = allh.malCHrate - allh.sybCH
    allh.to_csv(os.path.join(RES, "hosts_all.csv"), index=False)

    HOSTS = ["proposed", "tao_secured", "heed_secured"]
    LABEL = {"proposed": "ST-IT2FUC (trust-consuming)",
             "tao_secured": "Tao IT2-TSK (trust-blind, independent)",
             "heed_secured": "HEED (trust-blind, independent)"}
    ARMS = ["Roster+Veto", "RosterOnly", "VetoOnly", "Neither"]
    key, out = {}, ["# Cross-host attribution (20 seeds, mean ± 95% CI)\n",
                    f"Rows: {len(allh)} · hosts: {HOSTS}\n"]

    # ---- coverage matrix per host, at 20% attackers ------------------------
    out.append("\n## H1. Coverage matrix by host (20% attackers)\n")
    out.append("| Host | Configuration | n | Forged-CH share | Compromised-hardware share | Aggregate |")
    out.append("|---|---|---|---|---|---|")
    cov = {}
    for hn in HOSTS:
        for arm in ARMS:
            g = allh[(allh.host == hn) & (allh.arm == arm) & (allh.frac == 0.2)]
            fm, fh = ci(g.sybCH); hm, hh = ci(g.hwCH); am, ah = ci(g.malCHrate)
            cov[f"{hn}|{arm}"] = dict(forged=fm, forged_ci=fh, hw=hm, hw_ci=hh,
                                      agg=am, agg_ci=ah, n=len(g))
            out.append(f"| {LABEL[hn]} | {arm} | {len(g)} | {f(fm,fh)} | {f(hm,hh)} | {f(am,ah)} |")
    key["coverage_by_host"] = cov

    # ---- does the matrix replicate? the three structural claims ------------
    out.append("\n\n## H2. Do the structural claims replicate?\n")
    out.append("| Claim | " + " | ".join(LABEL[x] for x in HOSTS) + " |")
    out.append("|---|" + "---|" * len(HOSTS))
    rep = {}
    def row(name, fn, fmt="{:.4f}"):
        cells = []
        for hn in HOSTS:
            v = fn(hn); cells.append(fmt.format(v)); rep.setdefault(name, {})[hn] = float(v)
        out.append(f"| {name} | " + " | ".join(cells) + " |")
    row("Roster arms: max forged capture (any frac, any seed)",
        lambda hn: allh[(allh.host==hn) & allh.arm.isin(["Roster+Veto","RosterOnly"])].sybCH.max())
    row("Veto-only forged capture vs undefended (ratio)",
        lambda hn: allh[(allh.host==hn)&(allh.arm=="VetoOnly")&(allh.frac==0.2)].sybCH.mean() /
                   max(allh[(allh.host==hn)&(allh.arm=="Neither")&(allh.frac==0.2)].sybCH.mean(),1e-12),
        "{:.2f}")
    row("Veto covers hardware: VetoOnly / RosterOnly hw capture",
        lambda hn: allh[(allh.host==hn)&(allh.arm=="VetoOnly")&(allh.frac==0.2)].hwCH.mean() /
                   max(allh[(allh.host==hn)&(allh.arm=="RosterOnly")&(allh.frac==0.2)].hwCH.mean(),1e-12),
        "{:.4f}")
    key["replication"] = rep

    # ---- displacement, both directions, per host ---------------------------
    out.append("\n\n## H3. Displacement by host and direction (20% attackers, paired by seed)\n")
    out.append("Forward: does the roster alone arm the hardware channel? "
               "Reverse: does the veto alone arm the forged channel?\n")
    out.append("| Host | Direction | defended arm | undefended | ratio | paired t | p |")
    out.append("|---|---|---|---|---|---|---|")
    disp = {}
    for hn in HOSTS:
        sub = allh[(allh.host == hn) & (allh.frac == 0.2)]
        piv = sub.pivot_table(index="seed", columns="arm", values=["hwCH", "sybCH"])
        for direction, col, defarm in [("roster → hardware", "hwCH", "RosterOnly"),
                                       ("veto → forged", "sybCH", "VetoOnly")]:
            a, b = piv[col][defarm], piv[col]["Neither"]
            t, pv = stats.ttest_rel(a, b)
            r = a.mean() / max(b.mean(), 1e-12)
            disp[f"{hn}|{direction}"] = dict(defended=float(a.mean()), undefended=float(b.mean()),
                                             ratio=float(r), t=float(t), p=float(pv))
            out.append(f"| {LABEL[hn]} | {direction} | {a.mean():.4f} | {b.mean():.4f} "
                       f"| {r:.1f}× | {t:.2f} | {pv:.1e} |".replace(
                           f"{r:.1f}×", f"{r:.0f}×" if r >= 10 else f"{r:.1f}×"))
    key["displacement_by_host"] = disp

    # ---- super-additivity on half-life, per host ---------------------------
    out.append("\n\n## H4. Half-life interaction by host (20% attackers)\n")
    out.append("| Host | neither | veto only | roster only | roster+veto | joint gain | sum of parts | p (joint vs best single) |")
    out.append("|---|---|---|---|---|---|---|---|")
    inter = {}
    for hn in HOSTS:
        sub = allh[(allh.host == hn) & (allh.frac == 0.2)]
        piv = sub.pivot_table(index="seed", columns="arm", values="HND")
        base = piv["Neither"].mean()
        g = {a: piv[a].mean() / base - 1 for a in ARMS}
        best = "VetoOnly" if g["VetoOnly"] > g["RosterOnly"] else "RosterOnly"
        t, pv = stats.ttest_rel(piv["Roster+Veto"], piv[best])
        inter[hn] = dict(joint=g["Roster+Veto"], veto=g["VetoOnly"], roster=g["RosterOnly"],
                         sum_parts=g["VetoOnly"] + g["RosterOnly"], p=float(pv), t=float(t))
        out.append(f"| {LABEL[hn]} | {base:.1f} | {piv['VetoOnly'].mean():.1f} "
                   f"| {piv['RosterOnly'].mean():.1f} | {piv['Roster+Veto'].mean():.1f} "
                   f"| {g['Roster+Veto']*100:+.1f}% | {(g['VetoOnly']+g['RosterOnly'])*100:+.1f}% "
                   f"| {pv:.1e} |")
    key["interaction_by_host"] = inter

    with open(os.path.join(OUT, "tables_hosts.md"), "w") as fh:
        fh.write("\n".join(out) + "\n")
    json.dump(key, open(os.path.join(OUT, "key_numbers_hosts.json"), "w"), indent=2, default=float)
    print("\n".join(out))

if __name__ == "__main__":
    main()
