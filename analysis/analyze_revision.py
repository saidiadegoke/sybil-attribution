"""FEIC 2026 revision: statistics requested by the reviewers, computed from the
existing per-seed results (no new runs).

  R1  A3/A5  displacement as a paired absolute difference (bootstrap CI,
             Wilcoxon, Hodges-Lehmann shift, Cliff's delta), ratio secondary
  R2  A5     factorial table (STITCH, 20%) with seed-bootstrap CIs on shares,
             t-CIs on HND, and a count of degenerate (all-zero) cells
  R3  A4     roster x veto interaction on HND, per seed, per fraction and host
  R4  A2     one effective delay, delta_eff = 1 + d, in both predictions; the
             expected k-slope derivation
  R5  A6     replication across hosts, network sizes and base-station placement
  R6  A8     competitive displacement: hardware capture vs s on three hosts
  R7  B4, B6, B7  consensus on/off, EA-PoA and STITCH rows by fraction,
             Table 2 at four decimals

Writes tables_revision.md and key_numbers_revision.json.
"""
import json, os
import numpy as np, pandas as pd
from scipy import stats

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES = os.path.join(ROOT, "results")
OUT = os.path.join(ROOT, "analysis")
RNG = np.random.default_rng(20261115)
NB = 10000
ORDER = ["Roster+Veto", "RosterOnly", "VetoOnly", "Neither"]
HOSTS = {"proposed": "STITCH", "heed_secured": "HEED", "tao_secured": "Tao IT2-TSK"}


def boot_mean_ci(x):
    x = np.asarray(x, float)
    if np.allclose(x, x[0]):
        return x.mean(), x.mean(), x.mean()
    # fresh generator per call, so every interval is reproducible on its own
    idx = np.random.default_rng(20261115).integers(0, len(x), size=(NB, len(x)))
    m = x[idx].mean(axis=1)
    return x.mean(), np.percentile(m, 2.5), np.percentile(m, 97.5)


def t_ci(x):
    x = np.asarray(x, float)
    return x.mean(), stats.t.ppf(0.975, len(x) - 1) * x.std(ddof=1) / np.sqrt(len(x))


def wilcoxon_p(d):
    d = np.asarray(d, float)
    if np.allclose(d, 0):
        return 1.0
    return float(stats.wilcoxon(d).pvalue)


def hodges_lehmann(d):
    d = np.asarray(d, float)
    w = (d[:, None] + d[None, :]) / 2
    return float(np.median(w[np.triu_indices(len(d))]))


def cliffs_delta(a, b):
    a, b = np.asarray(a, float), np.asarray(b, float)
    gt = (a[:, None] > b[None, :]).sum(); lt = (a[:, None] < b[None, :]).sum()
    return float((gt - lt) / (len(a) * len(b)))


def fp(p):
    return "< 0.001" if p < 0.001 else f"{p:.3f}"


def fci(m, lo, hi, d=4):
    return f"{m:.{d}f} [{lo:.{d}f}, {hi:.{d}f}]"


def paired(a, b):
    """a - b on matched seeds."""
    d = np.asarray(a, float) - np.asarray(b, float)
    m, lo, hi = boot_mean_ci(d)
    return dict(diff=float(m), ci=[float(lo), float(hi)], p=wilcoxon_p(d),
                hl=hodges_lehmann(d), cliff=cliffs_delta(a, b),
                ratio=float(np.mean(a) / np.mean(b)) if np.mean(b) > 0 else None)


out, key = [], {}

# ------------------------------------------------------------------ data
fs = pd.read_csv(os.path.join(RES, "factorial_sweep.csv"))
fs["hwCH"] = fs.malCHrate - fs.sybCH
H = pd.read_csv(os.path.join(RES, "hosts_all.csv"))


def piv(df, val, idx="seed"):
    return df.pivot_table(index=idx, columns="arm", values=val)


# ------------------------------------------------------------------ R1
out.append("# FEIC 2026 revision statistics (from existing results)\n")
out.append(f"Seed-level percentile bootstrap, {NB:,} resamples (generator seed 20261115); "
           "(a fresh generator per interval); Wilcoxon signed-rank on matched seeds; HL = Hodges-Lehmann shift; "
           "Cliff's delta in [-1, 1]. Shares are fractions of CH-rounds.\n")
out.append("\n## R1 (A3, A5). Displacement: compromised-hardware capture, roster-only minus undefended\n")
out.append("| Host | Frac | Roster only | Undefended | Difference [95% CI] | p | HL | Cliff's delta | Ratio (secondary) |")
out.append("|---|---|---|---|---|---|---|---|---|")
key["displacement"] = {}
for host in HOSTS:
    src = fs if host == "proposed" else H[H.host == host]
    for fr in sorted(src.frac.unique()):
        q = piv(src[src.frac == fr], "hwCH")
        r = paired(q["RosterOnly"].values, q["Neither"].values)
        r.update(roster_only=float(q["RosterOnly"].mean()), neither=float(q["Neither"].mean()),
                 roster_only_ci=[float(v) for v in boot_mean_ci(q["RosterOnly"])[1:]],
                 neither_ci=[float(v) for v in boot_mean_ci(q["Neither"])[1:]])
        key["displacement"][f"{host}@{fr}"] = r
        out.append(f"| {HOSTS[host]} | {fr} | {r['roster_only']:.4f} | {r['neither']:.5f} | "
                   f"{fci(r['diff'], *r['ci'])} | {fp(r['p'])} | {r['hl']:.4f} | {r['cliff']:+.2f} | "
                   f"{r['ratio']:.1f}× |")
ab = [v["diff"] for k, v in key["displacement"].items() if k.endswith("@0.2")]
ra = [v["ratio"] for k, v in key["displacement"].items() if k.endswith("@0.2")]
out.append(f"\nAt 20%, the absolute displacement spans {min(ab):.3f} to {max(ab):.3f} across the three hosts "
           f"while the ratio spans {min(ra):.1f}× to {max(ra):.0f}×.")

# ------------------------------------------------------------------ R2
out.append("\n\n## R2 (A5). Factorial at 20% (STITCH): bootstrap CIs on shares, t-CI on HND\n")
out.append("| Configuration | Forged-CH share | Hardware-CH share | Aggregate | PDR (window) | HND (rounds) | Seeds with forged share = 0 |")
out.append("|---|---|---|---|---|---|---|")
f20 = fs[fs.frac == 0.2]
key["factorial20"] = {}
for a in ORDER:
    g = f20[f20.arm == a]
    row = {c: boot_mean_ci(g[c]) for c in ["sybCH", "hwCH", "malCHrate", "PDRwin"]}
    hm, hh = t_ci(g.HND)
    z = int((g.sybCH == 0).sum())
    key["factorial20"][a] = {c: [float(v) for v in row[c]] for c in row} | dict(HND=[hm, hh], zero_seeds=z)
    out.append(f"| {a} | {fci(*row['sybCH'])} | {fci(*row['hwCH'])} | {fci(*row['malCHrate'])} | "
               f"{fci(*row['PDRwin'], d=3)} | {hm:.1f} ± {hh:.1f} | {z}/20 |")
out.append("\nA degenerate cell (0.0000 [0.0000, 0.0000]) means no forged identity held a CH role in any "
           "round of any of the 20 seeds. CH-round counts are not stored per run, so no binomial upper "
           "bound is given.")
# key paired tests at 20%, Wilcoxon replacing paired t
p20s, p20h = piv(f20, "sybCH"), piv(f20, "HND")
key["tests20"] = {
    "forged: VetoOnly vs Neither": paired(p20s["VetoOnly"].values, p20s["Neither"].values),
    "HND: Roster+Veto vs RosterOnly": paired(p20h["Roster+Veto"].values, p20h["RosterOnly"].values),
    "HND: Roster+Veto vs VetoOnly": paired(p20h["Roster+Veto"].values, p20h["VetoOnly"].values),
}
out.append("\n| Paired comparison (20%) | Difference [95% CI] | Wilcoxon p | HL | Cliff's delta |")
out.append("|---|---|---|---|---|")
for k_, r in key["tests20"].items():
    d = 1 if k_.startswith("HND") else 4
    out.append(f"| {k_} | {fci(r['diff'], *r['ci'], d=d)} | {fp(r['p'])} | {r['hl']:.{d}f} | {r['cliff']:+.2f} |")

# ------------------------------------------------------------------ R3
out.append("\n\n## R3 (A4). Roster × veto interaction on HND\n")
out.append("Per seed: I = HND(R+V) − HND(R) − HND(V) + HND(N). For a 2×2 within-seed design the "
           "repeated-measures ANOVA interaction F(1, 19) equals the square of the paired t on I.\n")
out.append("| Host | Frac | N | R only | V only | R+V | I, rounds [95% CI] | I as % of N | F(1,19) | p (F) | Wilcoxon p |")
out.append("|---|---|---|---|---|---|---|---|---|---|---|")
key["interaction"] = {}
for host in HOSTS:
    src = fs if host == "proposed" else H[H.host == host]
    for fr in sorted(src.frac.unique()):
        q = piv(src[src.frac == fr], "HND")
        I = (q["Roster+Veto"] - q["RosterOnly"] - q["VetoOnly"] + q["Neither"]).values
        m, lo, hi = boot_mean_ci(I)
        t, p = stats.ttest_1samp(I, 0)
        r = dict(I=float(m), ci=[float(lo), float(hi)], F=float(t**2), p=float(p), p_w=wilcoxon_p(I),
                 pct=float(100 * m / q["Neither"].mean()),
                 means={a: float(q[a].mean()) for a in ORDER})
        key["interaction"][f"{host}@{fr}"] = r
        out.append(f"| {HOSTS[host]} | {fr} | {r['means']['Neither']:.1f} | {r['means']['RosterOnly']:.1f} | "
                   f"{r['means']['VetoOnly']:.1f} | {r['means']['Roster+Veto']:.1f} | "
                   f"{m:+.1f} [{lo:+.1f}, {hi:+.1f}] | {r['pct']:+.1f}% | {r['F']:.1f} | {fp(p)} | {fp(r['p_w'])} |")

# ------------------------------------------------------------------ R4
out.append("\n\n## R4 (A2). One effective delay, δ_eff = 1 + d\n")
kk = pd.read_csv(os.path.join(RES, "ksweep_with_k.csv"))
und = 0.10095          # undefended forged-CH share used throughout (analyze.py)
k0 = kk[(kk.arm == "veto-oneshot") & (kk.eta == 0.2) & (kk.tau == 0.4)].k.dropna()
k_meas = float(k0.mean())
D = pd.read_csv(os.path.join(RES, "delay_20.csv"))
vo = D[D.arm == "veto-only"]
out.append(f"Default setting (η = 0.2, τ = 0.4): measured k = {k_meas:.2f} (SD {k0.std(ddof=1):.3f}, "
           f"95% CI ± {stats.t.ppf(.975, len(k0)-1)*k0.std(ddof=1)/np.sqrt(len(k0)):.2f}). "
           f"Undefended forged share {und}.\n")
out.append("| d (configured) | δ_eff | Observed veto-only [95% CI] | Old prediction k/(k+d) | New prediction k/(k+1+d) |")
out.append("|---|---|---|---|---|")
key["delay_eff"] = {}
for d, g in vo.groupby("delay"):
    m, lo, hi = boot_mean_ci(g.sybCH)
    old, new = und * k_meas / (k_meas + d), und * k_meas / (k_meas + 1 + d)
    key["delay_eff"][int(d)] = dict(obs=float(m), ci=[float(lo), float(hi)], old=old, new=new)
    out.append(f"| {d} | {1+d} | {fci(m, lo, hi)} | {old:.4f} | {new:.4f} |")
lr = stats.linregress(vo.delay, vo.sybCH)
key["delay_slope"] = dict(slope=float(lr.slope), se=float(lr.stderr), p=float(lr.pvalue))
out.append(f"\nObserved slope of capture on d: {lr.slope:+.6f} per round (SE {lr.stderr:.6f}, p = {lr.pvalue:.2f}). "
           f"The k/(k+1+d) curve falls from {und*k_meas/(k_meas+1):.4f} at d = 0 to "
           f"{und*k_meas/(k_meas+33):.4f} at d = 32.")

ka = kk[kk.arm == "veto-churn"].dropna(subset=["k_mean"])
km = ka.groupby(["eta", "tau"]).agg(k=("k_mean", "first"), obs=("sybCH", "mean")).reset_index()
km["pred"] = und * km.k / (km.k + 1)
secant = (km.pred.max() - km.pred.min()) / (km.k.max() - km.k.min())
ls = stats.linregress(km.k, km.pred).slope
obs_lr = stats.linregress(ka.k_mean, ka.sybCH)
key["k_slope"] = dict(secant=float(secant), least_squares=float(ls),
                      observed=float(obs_lr.slope), observed_se=float(obs_lr.stderr),
                      k_min=float(km.k.min()), k_max=float(km.k.max()))
out.append(f"\nExpected k-slope. The stored value 0.00127 per round is the **secant** of the predicted "
           f"capture u·k/(k+1) (u = {und}) between the smallest and largest measured k "
           f"({km.k.min():.2f} and {km.k.max():.2f}): (u·k_max/(k_max+1) − u·k_min/(k_min+1)) / (k_max − k_min) "
           f"= {secant:.5f}. A least-squares fit of the predicted values on k over the nine settings gives "
           f"{ls:.5f}. Observed slope {obs_lr.slope:+.5f} (SE {obs_lr.stderr:.5f}).")

# ------------------------------------------------------------------ R5
out.append("\n\n## R5 (A6). Replication at 20% attackers\n")
out.append("| Setting | Max forged share, roster arms | Veto-only hardware share | Displacement (abs) | Ratio | Veto-only / undefended forged | Interaction I (HND) |")
out.append("|---|---|---|---|---|---|---|")
rep = {}
def rep_row(label, src, host_key=None):
    g = src[src.frac == 0.2] if "frac" in src else src
    mx = g[g.arm.isin(["Roster+Veto", "RosterOnly"])].sybCH.max()
    hw = g[g.arm == "VetoOnly"].hwCH.mean()
    q = piv(g, "hwCH"); dsp = (q["RosterOnly"] - q["Neither"]).mean(); rat = q["RosterOnly"].mean()/q["Neither"].mean()
    s = piv(g, "sybCH"); vr = s["VetoOnly"].mean()/s["Neither"].mean()
    h = piv(g, "HND"); I = (h["Roster+Veto"] - h["RosterOnly"] - h["VetoOnly"] + h["Neither"])
    t, p = stats.ttest_1samp(I, 0)
    rep[label] = dict(max_forged_roster=float(mx), veto_hw=float(hw), disp=float(dsp), ratio=float(rat),
                      veto_forged_ratio=float(vr), I=float(I.mean()), I_p=float(p))
    out.append(f"| {label} | {mx:.4f} | {hw:.4f} | {dsp:.3f} | {rat:.1f}× | {vr:.2f} | {I.mean():+.1f} (p {fp(p)}) |")
rep_row("STITCH, N = 100, central BS", fs)
for h_ in ["heed_secured", "tao_secured"]:
    rep_row(f"{HOSTS[h_]}, N = 100, central BS", H[H.host == h_])
ST = pd.read_csv(os.path.join(RES, "scale_topo_20.csv"))
for (n, e), g in ST.groupby(["N", "edgeBS"]):
    rep_row(f"STITCH, N = {n}, {'edge' if e else 'central'} BS", g)
key["replication"] = rep

# ------------------------------------------------------------------ R6
out.append("\n\n## R6 (A8). Competition: compromised-hardware capture as forged identities per attacker grow\n")
S = pd.read_csv(os.path.join(RES, "scaling_20.csv"))
out.append("| Host | Arm | s = 1 | s = 2 | s = 3 | s = 5 | s = 8 | Spearman ρ (s, hw share) | p |")
out.append("|---|---|---|---|---|---|---|---|---|")
key["competition"] = {}
for host in HOSTS:
    for a in ["Neither", "RosterOnly"]:
        g = S[(S.host == host) & (S.arm == a)]
        m = g.groupby("sybilIds").hwCH.mean()
        rho, p = stats.spearmanr(g.sybilIds, g.hwCH)
        key["competition"][f"{host}/{a}"] = dict(means={int(k): float(v) for k, v in m.items()},
                                                 rho=float(rho), p=float(p))
        out.append(f"| {HOSTS[host]} | {a} | " + " | ".join(f"{v:.4f}" for v in m.values) +
                   f" | {rho:+.2f} | {fp(p)} |")
out.append("\nUndefended, forged identities and compromised hardware compete for the same CH roles: more "
           "forged identities per attacker leave less for hardware. With the roster on, forged identities "
           "are excluded and hardware capture returns to about the attacker fraction regardless of s.")

# ------------------------------------------------------------------ R7
out.append("\n\n## R7 (B4, B6, B7)\n")
A = pd.read_csv(os.path.join(RES, "ablation_20.csv"))
out.append("**B4. Consensus layer on and off (STITCH, 20%).**\n")
out.append("| Configuration | HND (rounds) | Consensus energy (J) | PDR (window) |")
out.append("|---|---|---|---|")
key["B4"] = {}
for v in ["Consensus", "NoConsensus"]:
    g = A[A.variant == v]
    if g.empty:
        continue
    hm, hh = t_ci(g.HND); cm, ch = t_ci(g.consE); pm, plo, phi = boot_mean_ci(g.PDRwin)
    lab = "Consensus on (energy debited, failed-proposal trust penalty active)" if v == "Consensus" else "Consensus off"
    key["B4"][v] = dict(HND=[hm, hh], consE=[cm, ch], PDR=[pm, plo, phi])
    out.append(f"| {lab} | {hm:.1f} ± {hh:.1f} | {cm:.3f} ± {ch:.3f} | {pm:.3f} [{plo:.3f}, {phi:.3f}] |")
ga, gb = A[A.variant == "Consensus"].sort_values("seed"), A[A.variant == "NoConsensus"].sort_values("seed")
if len(ga) and len(gb):
    r = paired(ga.HND.values, gb.HND.values); key["B4"]["diff"] = r
    out.append(f"\nPaired HND difference {r['diff']:+.1f} [{r['ci'][0]:+.1f}, {r['ci'][1]:+.1f}] rounds, Wilcoxon p {fp(r['p'])}.")

AD = pd.read_csv(os.path.join(RES, "adversary_20.csv"))
out.append("\n**B6. Sybil admission and block rejection by attacker fraction.**\n")
out.append("| Protocol | Frac | Aggregate admission [95% CI] | Block rejection [95% CI] |")
out.append("|---|---|---|---|")
key["B6"] = {}
for pr, lab in [("eflzsepfch", "E-FLZSEPFCH"), ("eapoa", "EA-PoA"), ("proposed", "STITCH")]:
    for fr in [0.1, 0.2, 0.3]:
        g = AD[(AD.protocol == pr) & (AD.attack == "sybil") & (AD.frac == fr)]
        a_, b_ = boot_mean_ci(g.malCHrate), boot_mean_ci(g.blkRej)
        key["B6"][f"{pr}@{fr}"] = dict(adm=[float(x) for x in a_], rej=[float(x) for x in b_])
        out.append(f"| {lab} | {fr} | {fci(*a_, d=3)} | {fci(*b_, d=3)} |")

out.append("\n**B7. Table 2 (population decomposition) at four decimals, bootstrap CIs.**\n")
out.append("| Configuration | Frac | Forged | Hardware | Aggregate | HND |")
out.append("|---|---|---|---|---|---|")
key["B7"] = {}
for a in ORDER:
    for fr in [0.1, 0.2, 0.3]:
        g = fs[(fs.arm == a) & (fs.frac == fr)]
        s_, h_, m_ = boot_mean_ci(g.sybCH), boot_mean_ci(g.hwCH), boot_mean_ci(g.malCHrate)
        hm, hh = t_ci(g.HND)
        key["B7"][f"{a}@{fr}"] = dict(forged=[float(x) for x in s_], hw=[float(x) for x in h_],
                                      agg=[float(x) for x in m_], HND=[hm, hh])
        out.append(f"| {a} | {fr} | {fci(*s_)} | {fci(*h_)} | {fci(*m_)} | {hm:.1f} ± {hh:.1f} |")

open(os.path.join(OUT, "tables_revision.md"), "w").write("\n".join(out) + "\n")
json.dump(key, open(os.path.join(OUT, "key_numbers_revision.json"), "w"), indent=1, default=float)
print("\n".join(out))
