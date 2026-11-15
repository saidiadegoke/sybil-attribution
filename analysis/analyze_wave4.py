#!/usr/bin/env python3
"""Analysis for the four [TO RUN] items of §8.

  item 1  ledger integrity      -> the third coverage channel, measured
  item 2  re-mint delay sweep   -> does ANY delay restore the veto?
  item 3  displacement scaling  -> displacement as a law in s and host
  item 4  scale and topology    -> is the attribution structure scale-invariant?
"""
import json, os
import numpy as np, pandas as pd
from scipy import stats

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES, OUT = os.path.join(ROOT, "results"), os.path.join(ROOT, "analysis")

def ci(x):
    x = np.asarray(x, float); x = x[~np.isnan(x)]; n = len(x)
    if n < 2 or np.allclose(x, x[0]): return (x.mean() if n else np.nan), 0.0
    return x.mean(), stats.sem(x) * stats.t.ppf(0.975, n - 1)

def f(m, h, dp=4):
    return "n/a" if np.isnan(m) else f"{m:.{dp}f} ± {h:.{dp}f}"

out, key = ["# Wave 4: the four [TO RUN] items (20 seeds, mean ± 95% CI)\n"], {}

# ---------------------------------------------------------------- item 1
L = pd.read_csv(os.path.join(RES, "ledger_20.csv"))
out.append("\n## W1. Ledger integrity (item 1)\n")
out.append("| Arm | Frac | n | Fork refused | Rewrite refused | Unauth. refused | Adversarial commits | Attempts | Breaches |")
out.append("|---|---|---|---|---|---|---|---|---|")
led = {}
for (a, fr), g in L.groupby(["arm", "frac"], sort=False):
    fk, fkc = ci(g.forkRefused); rw, rwc = ci(g.rewriteRefused)
    ua, uac = ci(g.unauthRefused); ac, acc = ci(g.advCommitFrac)
    att, _ = ci(g.ledgerAtt); br, _ = ci(g.ledgerBreaches)
    led[f"{a}@{fr}"] = dict(fork=fk, fork_ci=fkc, adv=ac, adv_ci=acc,
                            att=att, breaches=br)
    out.append(f"| {a} | {fr} | {len(g)} | {f(fk,fkc)} | {f(rw,rwc)} | {f(ua,uac)} "
               f"| {f(ac,acc)} | {att:,.0f} | {br:,.0f} |")
key["ledger"] = led
# the remedy, paired by seed at 20%
p20 = L[L.frac == 0.2].pivot_table(index="seed", columns="arm",
                                   values=["forkRefused", "advCommitFrac", "ledgerBreaches"])
t1, p1 = stats.ttest_rel(p20["forkRefused"]["proposed+vetoAuth"], p20["forkRefused"]["proposed"])
t2, p2 = stats.ttest_rel(p20["ledgerBreaches"]["proposed+vetoAuth"], p20["ledgerBreaches"]["proposed"])
key["ledger_remedy"] = dict(
    fork_t=float(t1), fork_p=float(p1),
    breach_t=float(t2), breach_p=float(p2),
    breach_ratio=float(p20["ledgerBreaches"]["proposed"].mean() /
                       max(p20["ledgerBreaches"]["proposed+vetoAuth"].mean(), 1e-9)),
    att_ratio=float(L[(L.frac==.2)&(L.arm=="proposed")].ledgerAtt.mean() /
                    max(L[(L.frac==.2)&(L.arm=="proposed+vetoAuth")].ledgerAtt.mean(), 1e-9)))
# veto vs no-veto on the ledger channel (the degradation)
t3, p3 = stats.ttest_rel(p20["forkRefused"]["proposed"], p20["forkRefused"]["EA-PoA"])
key["ledger_veto_cost"] = dict(t=float(t3), p=float(p3),
    proposed=float(p20["forkRefused"]["proposed"].mean()),
    eapoa=float(p20["forkRefused"]["EA-PoA"].mean()))

# ---------------------------------------------------------------- item 2
D = pd.read_csv(os.path.join(RES, "delay_20.csv"))
out.append("\n\n## W2. Re-mint delay sweep (item 2)\n")
out.append("| Arm | delta | n | Forged-CH share | predicted by k/(k+delta) | Aggregate | HND | Re-mints |")
out.append("|---|---|---|---|---|---|---|---|")
k_meas, und = 7.65, 0.10095
dl = {}
for (a, d), g in D.groupby(["arm", "delay"], sort=False):
    m, h = ci(g.sybCH); ag, _ = ci(g.malCHrate); hn, _ = ci(g.HND); rm, _ = ci(g.churnTotal)
    pred = und * k_meas / (k_meas + d)
    dl[f"{a}@{d}"] = dict(sybCH=m, ci=h, predicted=pred)
    out.append(f"| {a} | {d} | {len(g)} | {f(m,h)} | {pred:.4f} | {ag:.4f} | {hn:.0f} | {rm:,.0f} |")
key["delay"] = dl
vo = D[D.arm == "veto-only"]
lr = stats.linregress(vo.delay.values, vo.sybCH.values)
tc = stats.t.ppf(0.975, len(vo) - 2)
key["delay_flatness"] = dict(slope=float(lr.slope), ci=float(tc*lr.stderr), p=float(lr.pvalue),
                             n=int(len(vo)), max_delay=int(D.delay.max()),
                             capture_at_max=float(vo[vo.delay==D.delay.max()].sybCH.mean()),
                             predicted_at_max=float(und*k_meas/(k_meas+D.delay.max())),
                             undefended=und)
out.append(f"\nRegression of capture on delta (veto-only): slope {lr.slope:+.6f} ± {tc*lr.stderr:.6f} "
           f"per round, p = {lr.pvalue:.3f}, n = {len(vo)}.")

# ---------------------------------------------------------------- item 3
S = pd.read_csv(os.path.join(RES, "scaling_20.csv"))
piv = S.pivot_table(index=["host", "sybilIds", "seed"], columns="arm", values="hwCH").reset_index()
out.append("\n\n## W3. Displacement scaling in s and host (item 3)\n")
out.append("| Host | s | roster only | neither | ratio | absolute | p |")
out.append("|---|---|---|---|---|---|---|")
rows = []
for (h, sv), g in piv.groupby(["host", "sybilIds"]):
    ro, ne = g["RosterOnly"], g["Neither"]
    t, p = stats.ttest_rel(ro, ne)
    rows.append(dict(host=h, s=sv, roster_only=ro.mean(), neither=ne.mean(),
                     ratio=ro.mean()/max(ne.mean(), 1e-12), absolute=ro.mean()-ne.mean(), p=p))
R = pd.DataFrame(rows).sort_values(["host", "s"])
for r in R.itertuples():
    out.append(f"| {r.host} | {r.s} | {r.roster_only:.4f} | {r.neither:.4f} "
               f"| {r.ratio:,.1f}× | {r.absolute:.4f} | {r.p:.1e} |")
R.to_csv(os.path.join(OUT, "t10_displacement_scaling.csv"), index=False)
out.append("\n**Scaling law.** Log-log regression of the displacement ratio on s:\n")
out.append("| Host | slope | r² | p | absolute displacement (min to max over s) |")
out.append("|---|---|---|---|---|")
law = {}
for h, g in R.groupby("host"):
    lr = stats.linregress(np.log(g.s), np.log(g.ratio))
    law[h] = dict(slope=float(lr.slope), r2=float(lr.rvalue**2), p=float(lr.pvalue),
                  abs_min=float(g.absolute.min()), abs_max=float(g.absolute.max()))
    out.append(f"| {h} | {lr.slope:+.3f} | {lr.rvalue**2:.3f} | {lr.pvalue:.4f} "
               f"| {g.absolute.min():.4f} to {g.absolute.max():.4f} |")
key["scaling_law"] = law

# ---------------------------------------------------------------- item 4
T = pd.read_csv(os.path.join(RES, "scale_topo_20.csv"))
out.append("\n\n## W4. Scale and topology (item 4)\n")
out.append("| N | BS | Arm | n | Forged-CH share | Hardware share | HND |")
out.append("|---|---|---|---|---|---|---|")
st = {}
for (N, e, a), g in T.groupby(["N", "edgeBS", "arm"], sort=False):
    fm, fh = ci(g.sybCH); hm, hh = ci(g.hwCH); hn, _ = ci(g.HND)
    st[f"{N}|{e}|{a}"] = dict(forged=fm, hw=hm)
    out.append(f"| {N} | {'edge' if e else 'central'} | {a} | {len(g)} | {f(fm,fh)} | {f(hm,hh)} | {hn:.0f} |")
key["scale_topo"] = st
# structural invariants across every (N, BS) cell
inv = []
for (N, e), g in T.groupby(["N", "edgeBS"]):
    rost = g[g.arm.isin(["Roster+Veto", "RosterOnly"])].sybCH.max()
    vo_  = g[g.arm == "VetoOnly"].sybCH.mean()
    ne_  = g[g.arm == "Neither"].sybCH.mean()
    vhw  = g[g.arm == "VetoOnly"].hwCH.mean()
    rhw  = g[g.arm == "RosterOnly"].hwCH.mean()
    inv.append(dict(N=N, edge=e, roster_max_forged=rost, veto_vs_undef=vo_/max(ne_,1e-12),
                    veto_over_roster_hw=vhw/max(rhw,1e-12)))
I = pd.DataFrame(inv)
out.append("\n**Structural invariants across scale and topology.**\n")
out.append("| N | BS | roster arms: max forged | veto-only ÷ undefended (forged) | veto ÷ roster-only (hardware) |")
out.append("|---|---|---|---|---|")
for r in I.itertuples():
    out.append(f"| {r.N} | {'edge' if r.edge else 'central'} | {r.roster_max_forged:.4f} "
               f"| {r.veto_vs_undef:.2f} | {r.veto_over_roster_hw:.4f} |")
key["scale_invariants"] = dict(roster_max_forged=float(I.roster_max_forged.max()),
                               veto_ratio_min=float(I.veto_vs_undef.min()),
                               veto_ratio_max=float(I.veto_vs_undef.max()),
                               veto_hw_max=float(I.veto_over_roster_hw.max()))

open(os.path.join(OUT, "tables_wave4.md"), "w").write("\n".join(out) + "\n")
json.dump(key, open(os.path.join(OUT, "key_numbers_wave4.json"), "w"), indent=2, default=float)
print("\n".join(out))
