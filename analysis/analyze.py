#!/usr/bin/env python3
"""Merge seed shards and produce mean +/- 95% CI tables for the paper.

CIs are Student-t (n-1 df) on the per-seed values, which is what a security PC
expects and what the 5-seed source study could not supply. Every table written
here is generated from the CSVs; nothing is transcribed by hand.
"""
import glob, json, os
import numpy as np, pandas as pd
from scipy import stats

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES  = os.path.join(ROOT, "results")
OUT  = os.path.join(ROOT, "analysis")

def merge(pat, name):
    fs = sorted(glob.glob(os.path.join(RES, "shards", pat)))
    if not fs:
        raise SystemExit(f"no shards matched {pat}")
    df = pd.concat([pd.read_csv(f) for f in fs], ignore_index=True)
    df.to_csv(os.path.join(RES, name), index=False)
    return df

def ci(x, conf=0.95):
    """mean, half-width of the CI, n. Half-width is 0 for a degenerate series."""
    x = np.asarray(x, dtype=float); x = x[~np.isnan(x)]
    n = len(x)
    if n == 0: return np.nan, np.nan, 0
    m = x.mean()
    if n < 2 or np.allclose(x, x[0]): return m, 0.0, n
    se = stats.sem(x)
    return m, se * stats.t.ppf((1 + conf) / 2.0, n - 1), n

def pred_f(k):
    """Proposition 2 as stated: eligibility duty cycle k/(k+delta), delta = 1."""
    return k / (k + 1.0)

def fmt(m, h, dp=3):
    if np.isnan(m): return "n/a"
    return f"{m:.{dp}f} ± {h:.{dp}f}"

def agg(df, by, cols, dps=None):
    dps = dps or {}
    rows = []
    for key, g in df.groupby(by, sort=False):
        if not isinstance(key, tuple): key = (key,)
        row = dict(zip(by, key)); row["n"] = len(g)
        for c in cols:
            m, h, _ = ci(g[c])
            row[c] = fmt(m, h, dps.get(c, 3))
            row[c + "_mean"] = m; row[c + "_ci"] = h
        rows.append(row)
    return pd.DataFrame(rows)

def md_table(df, by, cols, headers):
    lines = ["| " + " | ".join(headers) + " |",
             "|" + "|".join(["---"] * len(headers)) + "|"]
    for _, r in df.iterrows():
        cells = [str(r[c]) for c in by] + [f"{int(r['n'])}"] + [str(r[c]) for c in cols]
        lines.append("| " + " | ".join(cells) + " |")
    return "\n".join(lines)

def merge_adversary():
    """Adversary sweep. The sinkhole was a relabelled blackhole until
    2026-11-15; its rows are replaced by the rerun in shards/sinkfix/ (sinkhole
    with real election attraction) whenever that rerun is present."""
    fs = sorted(glob.glob(os.path.join(RES, "shards", "adv_*.csv")))
    if not fs:
        raise SystemExit("no shards matched adv_*.csv")
    df = pd.concat([pd.read_csv(f) for f in fs], ignore_index=True)
    fix = sorted(glob.glob(os.path.join(RES, "shards", "sinkfix", "sink_*.csv")))
    if fix:
        new = pd.concat([pd.read_csv(f) for f in fix], ignore_index=True)
        df = pd.concat([df[df.attack != "sinkhole"], new], ignore_index=True)
    df.to_csv(os.path.join(RES, "adversary_20.csv"), index=False)
    return df

def main():
    adv = merge_adversary()
    abl = merge("abl_*.csv", "ablation_20.csv")
    ksw = merge("ksw_*.csv", "ksweep_20.csv")

    out, key = [], {}
    out.append("# Generated result tables (20 seeds, mean ± 95% CI)\n")
    out.append(f"Adversary rows: {len(adv)} · ablation rows: {len(abl)} · k-sweep rows: {len(ksw)}\n")

    # ---- Table 1/3: security under attack, populations separated ------------
    out.append("\n## T1. Security under attack, by protocol × attack × attacker fraction\n")
    a = agg(adv, ["protocol", "attack", "frac"],
            ["malCHrate", "sybCH", "PDRwin", "blkRej"])
    out.append(md_table(a, ["protocol", "attack", "frac"],
                        ["malCHrate", "sybCH", "PDRwin", "blkRej"],
                        ["Protocol", "Attack", "Frac", "n", "Malicious-CH admission",
                         "Forged-CH share", "Common-window PDR", "Quorum block-rejection"]))
    a.to_csv(os.path.join(OUT, "t1_adversary.csv"), index=False)

    syb = a[a.attack == "sybil"]
    key["sybil"] = {f"{r.protocol}@{r.frac}": dict(
        malCH=r.malCHrate_mean, malCH_ci=r.malCHrate_ci,
        sybCH=r.sybCH_mean, sybCH_ci=r.sybCH_ci,
        pdrwin=r.PDRwin_mean, blkrej=r.blkRej_mean) for r in syb.itertuples()}

    # ---- Table 4: the roster x veto factorial -------------------------------
    out.append("\n\n## T2. Factorial mechanism ablation (roster × veto), Sybil 20%, churn on\n")
    f = agg(abl[abl.group == "C3s"], ["variant"],
            ["sybCH", "malCHrate", "PDRwin", "HND"], dps={"HND": 1})
    order = ["Roster+Veto", "VetoOnly", "RosterOnly", "Neither"]
    f["__o"] = f.variant.map({v: i for i, v in enumerate(order)}); f = f.sort_values("__o")
    out.append(md_table(f, ["variant"], ["sybCH", "malCHrate", "PDRwin", "HND"],
                        ["Configuration", "n", "Forged-CH share", "Malicious-CH admission",
                         "Common-window PDR", "HND (rounds)"]))
    f.to_csv(os.path.join(OUT, "t2_factorial.csv"), index=False)
    key["factorial"] = {r.variant: dict(sybCH=r.sybCH_mean, sybCH_ci=r.sybCH_ci,
                                        malCH=r.malCHrate_mean, malCH_ci=r.malCHrate_ci,
                                        hnd=r.HND_mean, hnd_ci=r.HND_ci) for r in f.itertuples()}

    # interaction on half-life: is the joint gain more than the sum of the parts?
    base = f[f.variant == "Neither"].HND_mean.iloc[0]
    gains = {v: f[f.variant == v].HND_mean.iloc[0] / base - 1 for v in order}
    key["hnd_gain_vs_neither"] = gains
    key["superadditive"] = gains["Roster+Veto"] - (gains["VetoOnly"] + gains["RosterOnly"])
    # two-sample t-test: joint arm vs the better single arm, paired by seed
    A = abl[(abl.group=="C3s")].pivot(index="seed", columns="variant", values="HND")
    best_single = "VetoOnly" if gains["VetoOnly"] > gains["RosterOnly"] else "RosterOnly"
    t, p = stats.ttest_rel(A["Roster+Veto"], A[best_single])
    key["hnd_joint_vs_best_single"] = dict(better=best_single, t=float(t), p=float(p))

    # ---- Table 5: the identity-minting ablation ----------------------------
    out.append("\n\n## T3. Identity-minting ablation (one-shot vs churn), Sybil 20%\n")
    c = agg(abl[abl.group == "C3c"], ["variant"],
            ["sybCH", "malCHrate", "HND", "churnTotal"], dps={"HND": 1, "churnTotal": 1})
    corder = ["VetoOnly-oneshot", "VetoOnly-churn", "Roster-oneshot", "Roster-churn"]
    c["__o"] = c.variant.map({v: i for i, v in enumerate(corder)}); c = c.sort_values("__o")
    out.append(md_table(c, ["variant"], ["sybCH", "malCHrate", "HND", "churnTotal"],
                        ["Configuration", "n", "Forged-CH share", "Malicious-CH admission",
                         "HND (rounds)", "Re-mint events"]))
    c.to_csv(os.path.join(OUT, "t3_churn.csv"), index=False)
    key["churn"] = {r.variant: dict(sybCH=r.sybCH_mean, sybCH_ci=r.sybCH_ci,
                                    hnd=r.HND_mean, remints=r.churnTotal_mean)
                    for r in c.itertuples()}
    # churn effect on the veto arm, paired by seed
    B = abl[abl.group=="C3c"].pivot(index="seed", columns="variant", values="sybCH")
    t, p = stats.ttest_rel(B["VetoOnly-churn"], B["VetoOnly-oneshot"])
    key["churn_effect_veto"] = dict(t=float(t), p=float(p),
        ratio=float(B["VetoOnly-churn"].mean() / max(B["VetoOnly-oneshot"].mean(), 1e-9)))

    # ---- Table 6: C4 consensus cost ---------------------------------------
    out.append("\n\n## T4. Cost of attribution: consensus energy debited from CH batteries\n")
    e = agg(abl[abl.group == "C4"], ["variant"], ["HND", "consE", "PDRwin"],
            dps={"HND": 1, "consE": 6})
    out.append(md_table(e, ["variant"], ["HND", "consE", "PDRwin"],
                        ["Configuration", "n", "HND (rounds)", "Consensus energy (J)",
                         "Common-window PDR"]))
    e.to_csv(os.path.join(OUT, "t4_consensus.csv"), index=False)
    hn = {r.variant: r.HND_mean for r in e.itertuples()}
    key["consensus_halflife_cost"] = 1 - hn.get("Consensus", np.nan) / hn.get("NoConsensus", np.nan)
    key["consensus_energy_J"] = float(e[e.variant == "Consensus"].consE_mean.iloc[0])

    # ---- Table 7: the k sweep ---------------------------------------------
    out.append("\n\n## T5. Rounds-to-conviction sweep (k), Sybil 20%\n")
    kk = ksw.copy()
    kmeas = (kk[kk.arm == "veto-oneshot"].groupby(["eta", "tau"])["k"]
               .agg(["mean", "std", "count"]).reset_index()
               .rename(columns={"mean": "k_mean", "std": "k_sd", "count": "k_n"}))
    kk = kk.merge(kmeas[["eta", "tau", "k_mean"]], on=["eta", "tau"], how="left")
    g = agg(kk, ["arm", "eta", "tau"], ["sybCH", "malCHrate", "HND", "k_mean"],
            dps={"HND": 1, "k_mean": 2})
    out.append(md_table(g, ["arm", "eta", "tau"], ["k_mean", "sybCH", "malCHrate", "HND"],
                        ["Arm", "eta", "tau", "n", "measured k (rounds)",
                         "Forged-CH share", "Malicious-CH admission", "HND"]))
    g.to_csv(os.path.join(OUT, "t5_ksweep.csv"), index=False)
    kk.to_csv(os.path.join(RES, "ksweep_with_k.csv"), index=False)

    # The analytic prediction of Proposition 2: eligibility duty cycle k/(k+delta)
    # with delta = 1 round (churn_sybil fires at the end of the round in which
    # trust crosses tau), scaled by the undefended capture rate.
    und = key["factorial"]["Neither"]["sybCH"]
    pred = kmeas.copy()
    pred["predicted_sybCH"] = und * pred.k_mean / (pred.k_mean + 1.0)
    obs = (kk[kk.arm == "veto-churn"].groupby(["eta", "tau"])["sybCH"].mean()
             .reset_index().rename(columns={"sybCH": "observed_sybCH"}))
    pred = pred.merge(obs, on=["eta", "tau"])
    pred["abs_err"] = (pred.predicted_sybCH - pred.observed_sybCH).abs()
    pred.to_csv(os.path.join(OUT, "t6_prop2_prediction.csv"), index=False)
    r_ = stats.pearsonr(pred.predicted_sybCH, pred.observed_sybCH)
    key["prop2"] = dict(undefended=und, mean_abs_err=float(pred.abs_err.mean()),
                        pearson_r=float(r_[0]), p=float(r_[1]),
                        k_range=[float(pred.k_mean.min()), float(pred.k_mean.max())])
    out.append("\n\n## T6. Proposition 2 check: predicted vs observed forged-CH share\n")
    out.append("Predicted = (undefended capture rate) × k/(k+1), δ=1 round.\n")
    out.append("| eta | tau | measured k | predicted | observed | abs err |")
    out.append("|---|---|---|---|---|---|")
    for r in pred.itertuples():
        out.append(f"| {r.eta} | {r.tau} | {r.k_mean:.2f} | {r.predicted_sybCH:.4f} "
                   f"| {r.observed_sybCH:.4f} | {r.abs_err:.4f} |")

    # ---- Table 7: population decomposition across attacker fractions --------
    # The aggregate flag covers both adversary populations and the forged flag a
    # subset, so the hardware channel is their difference. This is the table the
    # factorial fraction sweep (wave 2) exists to produce.
    fs = pd.read_csv(os.path.join(RES, "factorial_sweep.csv"))
    fs["hwCH"] = fs.malCHrate - fs.sybCH
    dec = agg(fs, ["arm", "frac"], ["sybCH", "hwCH", "malCHrate", "PDRwin", "HND"],
              dps={"HND": 1, "hwCH": 4, "sybCH": 4})
    dorder = ["Roster+Veto", "RosterOnly", "VetoOnly", "Neither"]
    dec["__o"] = dec.arm.map({a: i for i, a in enumerate(dorder)})
    dec = dec.sort_values(["__o", "frac"])
    dec.to_csv(os.path.join(OUT, "t7_decomposition.csv"), index=False)
    out.append("\n\n## T7. Population decomposition by arm and attacker fraction\n")
    out.append(md_table(dec, ["arm", "frac"], ["sybCH", "hwCH", "malCHrate", "HND"],
                        ["Configuration", "Frac", "n", "Forged-CH share",
                         "Compromised-hardware share", "Aggregate admission",
                         "HND (rounds)"]))
    key["decomposition"] = {f"{r.arm}@{r.frac}": dict(
        forged=r.sybCH_mean, forged_ci=r.sybCH_ci,
        hw=r.hwCH_mean, hw_ci=r.hwCH_ci,
        agg=r.malCHrate_mean, agg_ci=r.malCHrate_ci) for r in dec.itertuples()}

    # ---- Displacement: does a roster alone arm the channel it cannot cover? --
    piv = fs.pivot_table(index=["seed", "frac"], columns="arm", values="hwCH").reset_index()
    disp = {}
    out.append("\n\n## T8. Displacement: compromised-hardware capture, roster-only vs undefended\n")
    out.append("| Frac | roster only | neither | ratio | paired t | p |")
    out.append("|---|---|---|---|---|---|")
    for fr in sorted(fs.frac.unique()):
        q = piv[piv.frac == fr]
        t, pv = stats.ttest_rel(q["RosterOnly"], q["Neither"])
        ratio = q["RosterOnly"].mean() / max(q["Neither"].mean(), 1e-12)
        disp[str(fr)] = dict(roster_only=float(q["RosterOnly"].mean()),
                             neither=float(q["Neither"].mean()),
                             ratio=float(ratio), t=float(t), p=float(pv))
        out.append(f"| {fr} | {q['RosterOnly'].mean():.4f} | {q['Neither'].mean():.4f} "
                   f"| {ratio:.0f}× | {t:.2f} | {pv:.1e} |")
    key["displacement"] = disp
    key["displacement_range"] = [min(d["ratio"] for d in disp.values()),
                                 max(d["ratio"] for d in disp.values())]

    # ---- k-invariance: is capture under churn flat in rounds-to-conviction? --
    ka = kk[kk.arm == "veto-churn"].dropna(subset=["k_mean"])
    lr = stats.linregress(ka.k_mean.values, ka.sybCH.values)
    n_k = len(ka); tc = stats.t.ppf(0.975, n_k - 2)
    pred_slope = (und * pred_f(kmeas.k_mean.max()) - und * pred_f(kmeas.k_mean.min())) \
                 / (kmeas.k_mean.max() - kmeas.k_mean.min())
    t_vs = (lr.slope - pred_slope) / lr.stderr
    roster_max = kk[kk.arm == "roster+veto"].dropna(subset=["k_mean"]).sybCH.max()
    key["k_invariance"] = dict(
        slope=float(lr.slope), slope_ci=float(tc * lr.stderr), p=float(lr.pvalue), n=int(n_k),
        predicted_slope=float(pred_slope), t_vs_predicted=float(t_vs),
        p_vs_predicted=float(2 * (1 - stats.t.cdf(abs(t_vs), n_k - 2))),
        mean_capture=float(ka.sybCH.mean()), undefended=float(und),
        ratio_to_undefended=float(ka.sybCH.mean() / und),
        k_min=float(kmeas.k_mean.min()), k_max=float(kmeas.k_mean.max()),
        roster_max_capture=float(roster_max))
    out.append("\n\n## T9. k-invariance of the veto's failure (arm: veto only, churn)\n")
    out.append(f"- measured k range: {kmeas.k_mean.min():.2f} to {kmeas.k_mean.max():.2f} rounds")
    out.append(f"- regression of capture on k: slope {lr.slope:.6f} ± {tc*lr.stderr:.6f} per round, p = {lr.pvalue:.3f} (n = {n_k})")
    out.append(f"- Proposition-2 predicted slope: {pred_slope:.6f} per round; observed is {lr.slope/pred_slope*100:.0f}% of it (t = {t_vs:.2f}, p = {key['k_invariance']['p_vs_predicted']:.1e})")
    out.append(f"- mean capture across all k: {ka.sybCH.mean():.4f} vs undefended {und:.4f} (ratio {ka.sybCH.mean()/und:.3f})")
    out.append(f"- roster + veto, max capture over all k and seeds: {roster_max:.6f}")

    with open(os.path.join(OUT, "tables.md"), "w") as fh:
        fh.write("\n".join(out) + "\n")
    with open(os.path.join(OUT, "key_numbers.json"), "w") as fh:
        json.dump(key, fh, indent=2, default=float)
    print("wrote analysis/tables.md and analysis/key_numbers.json")
    print(json.dumps(key, indent=2, default=float)[:2000])

if __name__ == "__main__":
    main()
