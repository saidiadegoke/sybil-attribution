#!/usr/bin/env python3
"""The paper's three figures. Print-first: every series is direct-labelled and
carries a distinct marker/dash, so identity never rests on colour alone (the
palette's aqua slot sits below 3:1 on a white surface, which obliges the relief
rule; a greyscale print of the page must stay readable regardless).

Palette: validated categorical slots 1,2,3,7 of the reference instance
(#2a78d6 #eb6834 #1baf7a #4a3aa7) -- all checks PASS, worst all-pairs CVD dE 9.2.
"""
import json, os
import numpy as np, pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle, FancyArrowPatch
from scipy import stats

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RES, FIG = os.path.join(ROOT, "results"), os.path.join(ROOT, "figures")
OUT_A = os.path.join(ROOT, "analysis")
os.makedirs(FIG, exist_ok=True)

BLUE, ORANGE, AQUA, VIOLET = "#2a78d6", "#eb6834", "#1baf7a", "#4a3aa7"
INK, INK2, MUTED = "#0b0b0b", "#52514e", "#8a8a85"
GRID, SURFACE = "#e4e3df", "#fcfcfb"

plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE,
    "savefig.facecolor": SURFACE, "font.size": 9,
    "font.family": "DejaVu Sans", "axes.edgecolor": GRID,
    "axes.labelcolor": INK, "text.color": INK,
    "xtick.color": INK2, "ytick.color": INK2,
    "axes.spines.top": False, "axes.spines.right": False,
    "axes.linewidth": 0.8, "lines.linewidth": 2.0,
    "legend.frameon": False, "figure.dpi": 200,
})

def ci95(x):
    x = np.asarray(x, float); x = x[~np.isnan(x)]
    n = len(x)
    if n < 2 or np.allclose(x, x[0]): return (x.mean() if n else np.nan), 0.0
    return x.mean(), stats.sem(x) * stats.t.ppf(0.975, n - 1)

# ---------------------------------------------------------------- Figure 1
def fig_coverage_matrix():
    """The §3.3 coverage relation as a schematic. Not a data chart: a structural
    claim, so it is drawn as a matrix of states with glyph + word in every cell.
    Colour is the third encoding, never the only one."""
    rows = [("$M_R$  roster", "admission by\nregistration", "provenance"),
            ("$M_B$  veto",   "admission by\nbehaviour",    "conduct"),
            ("$M_Q$  quorum", "agreement on\na proposed block", "concurrence")]
    cols = ["forged identities\n(renewable)", "compromised hardware\n(provenance-bound)",
            "ledger integrity"]
    # state: 1 covered, 0 not covered, -1 covered but not measured here
    M = [[1, 0, None], [0, 1, None], [0, 0, -1]]
    NOTE = {(0,0): "P1", (1,1): "P2", (0,1): "P1", (1,0): "P2",
            (2,0): "P3", (2,1): "P3", (2,2): "§7.1"}

    fig, ax = plt.subplots(figsize=(7.6, 3.2))
    cw, ch = 1.0, 1.0
    for i, r in enumerate(rows):
        for j, c in enumerate(cols):
            s = M[i][j]
            x, y = j * cw, -i * ch
            if s == 1:
                fc, ec, glyph, word, tc = "#e3f5ec", AQUA, "●", "covered", "#0d7a55"
            elif s == -1:
                fc, ec, glyph, word, tc = "#eef1fb", VIOLET, "◐", "covered,\nnot measured", VIOLET
            elif s == 0:
                fc, ec, glyph, word, tc = "#fdeee8", ORANGE, "○", "not covered", "#b8451a"
            else:
                fc, ec, glyph, word, tc = SURFACE, GRID, "", "—", MUTED
            ax.add_patch(Rectangle((x + 0.03, y + 0.03), cw - 0.06, ch - 0.06,
                                   facecolor=fc, edgecolor=ec, linewidth=1.4,
                                   joinstyle="round"))
            if glyph:
                ax.text(x + cw/2, y + ch*0.64, glyph, ha="center", va="center",
                        fontsize=15, color=ec)
            ax.text(x + cw/2, y + ch*0.34, word, ha="center", va="center",
                    fontsize=8.2, color=tc, linespacing=1.25,
                    fontweight="bold" if s in (1,) else "normal")
            if (i, j) in NOTE and s is not None:
                ax.text(x + cw - 0.09, y + ch - 0.13, NOTE[(i, j)], ha="right",
                        va="top", fontsize=6.6, color=MUTED)
    for i, (name, kind, observable) in enumerate(rows):
        y = -i * ch
        ax.text(-0.12, y + ch*0.62, name, ha="right", va="center",
                fontsize=9.5, color=INK, fontweight="bold")
        ax.text(-0.12, y + ch*0.34, f"observes {observable}", ha="right",
                va="center", fontsize=7.6, color=MUTED, style="italic")
    for j, c in enumerate(cols):
        ax.text(j * cw + cw/2, ch * 1.10, c, ha="center", va="bottom",
                fontsize=8.6, color=INK, linespacing=1.3)
    ax.text(-0.12, ch * 1.10, "adversary population →", ha="right", va="bottom",
            fontsize=8, color=MUTED, style="italic")
    ax.plot([-0.06, len(cols) * cw], [ch * 1.04] * 2, color=GRID, lw=0.9,
            clip_on=False)
    ax.set_xlim(-2.05, len(cols) * cw + 0.05)
    ax.set_ylim(-(len(rows) - 1) * ch - 0.10, ch * 1.52)
    ax.axis("off")
    fig.tight_layout()
    fig.savefig(os.path.join(FIG, "fig1_coverage_matrix.png"), bbox_inches="tight")
    plt.close(fig)
    print("fig1 written")

# ---------------------------------------------------------------- Figure 2
def fig_admission_vs_fraction():
    """The paper's headline. Three panels: the two adversary populations counted
    separately, then the aggregate that sums them. Each mechanism zeroes exactly
    one channel; the roster ALONE drives the other channel up by two to three
    orders of magnitude; and the aggregate hides both facts. Arms that coincide
    are labelled jointly -- the coincidence is itself the finding."""
    df = pd.read_csv(os.path.join(RES, "factorial_sweep.csv"))
    df["hwCH"] = df.malCHrate - df.sybCH     # isMal counts both; forged is a subset
    arms = [("Roster+Veto", BLUE,   "o", "-"),
            ("RosterOnly",  AQUA,   "s", "--"),
            ("VetoOnly",    ORANGE, "^", "-."),
            ("Neither",     VIOLET, "D", ":")]
    panels = [("sybCH",     "Forged identities",
               "the roster's channel"),
              ("hwCH",      "Compromised hardware",
               "the veto's channel"),
              ("malCHrate", "Aggregate admission",
               "what a conventional paper reports")]
    fr = np.array(sorted(df.frac.unique()))
    fig, axes = plt.subplots(1, 3, figsize=(11.6, 3.8), sharey=True)

    for ax, (col, title, sub) in zip(axes, panels):
        ax.plot(fr, fr, color=MUTED, lw=1.0, ls=(0, (2, 3)), zorder=1)
        ax.text(0.152, 0.166, "= attacker fraction", fontsize=6.8, color=MUTED,
                style="italic", rotation=33, rotation_mode="anchor",
                ha="left", va="bottom")
        ends = []
        for name, colr, mk, ls in arms:
            g = df[df.arm == name].groupby("frac")[col]
            m = np.array([ci95(g.get_group(f))[0] for f in fr])
            h = np.array([ci95(g.get_group(f))[1] for f in fr])
            ax.fill_between(fr, m - h, m + h, color=colr, alpha=0.15, linewidth=0)
            ax.plot(fr, m, color=colr, marker=mk, ls=ls, ms=5.2, mec=SURFACE,
                    mew=1.2, zorder=3, clip_on=False)
            ends.append([name, colr, float(m[-1])])

        # Group coincident endpoints, then stack the group labels. A shared label
        # is more honest than two drawn on top of each other: it says these arms
        # are indistinguishable.
        ends.sort(key=lambda e: -e[2])
        groups, TOLL = [], 0.006
        for name, colr, y in ends:
            if groups and abs(groups[-1]["y"] - y) < TOLL:
                groups[-1]["names"].append(name); groups[-1]["colors"].append(colr)
            else:
                groups.append({"names": [name], "colors": [colr], "y": y})
        for g in groups: g["ly"] = g["y"]
        for i in range(1, len(groups)):
            if groups[i-1]["ly"] - groups[i]["ly"] < 0.030:
                groups[i]["ly"] = groups[i-1]["ly"] - 0.030
        for g in groups:
            lbl = " = ".join(g["names"])
            if g["y"] < 0.008:      # the zero line: label inside, above the line
                ax.annotate(lbl, (fr[0] + 0.004, 0.0), xytext=(0, 7),
                            textcoords="offset points", ha="left", va="bottom",
                            fontsize=7.4, color=g["colors"][0], fontweight="bold")
                continue
            ax.annotate(lbl, (fr[-1], g["ly"]), xytext=(9, 0),
                        textcoords="offset points", va="center", fontsize=7.4,
                        color=g["colors"][0], fontweight="bold",
                        annotation_clip=False)
            if abs(g["ly"] - g["y"]) > 1e-9:
                ax.annotate("", xy=(fr[-1], g["y"]), xytext=(fr[-1] + 0.009, g["ly"]),
                            arrowprops=dict(arrowstyle="-", color=g["colors"][0],
                                            lw=0.7), annotation_clip=False)
        ax.set_title(title, fontsize=9.5, color=INK, pad=12, loc="left")
        ax.text(0, 1.012, sub, transform=ax.transAxes, fontsize=7.4,
                color=MUTED, style="italic", va="bottom")
        ax.set_xlabel("compromised fraction")
        ax.set_xticks([0.1, 0.2, 0.3]); ax.set_xlim(0.088, 0.312)
        ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)

    # call out displacement where it happens (range read from the analysis, rounded
    # as Table 3 rounds it, so the label cannot drift from the text)
    with open(os.path.join(OUT_A, "key_numbers.json")) as f:
        lo, hi = json.load(f)["displacement_range"]
    axes[1].annotate(f"roster alone raises this\nchannel {lo:.0f}–{hi:.0f}×",
                     (0.2, 0.197), xytext=(-6, -66), textcoords="offset points",
                     ha="right", fontsize=7.4, color="#0d7a55", fontweight="bold",
                     linespacing=1.3,
                     arrowprops=dict(arrowstyle="->", color=AQUA, lw=1.0,
                                     shrinkA=2, shrinkB=4))
    axes[0].set_ylabel("share of cluster-head roles")
    axes[0].set_ylim(-0.012, 0.36)
    fig.subplots_adjust(right=0.88, wspace=0.52)
    fig.savefig(os.path.join(FIG, "fig2_admission_vs_fraction.png"), bbox_inches="tight")
    plt.close(fig)
    print("fig2 written")

# ---------------------------------------------------------------- Figure 3
def fig_trust_trajectory():
    """Why a behavioural veto cannot converge: the evidence clock restarts. Left,
    mean trust of forged identities under one-shot minting vs churn. Right, how
    many forged identities are eligible (above tau) in each regime."""
    d = pd.read_csv(os.path.join(RES, "results_trace.csv"))
    tau, T0 = d.tau.iloc[0], d.T0.iloc[0]
    R = min(60, len(d))
    d = d.iloc[:R]
    fig, axes = plt.subplots(1, 2, figsize=(7.8, 3.3))

    ax = axes[0]
    ax.axhspan(0, tau, color=AQUA, alpha=0.07, linewidth=0)
    ax.axhline(tau, color=MUTED, lw=1.0, ls=(0, (3, 3)))
    ax.annotate(f"veto threshold $\\tau$ = {tau:g}", (R, tau), xytext=(-4, 5),
                textcoords="offset points", ha="right", fontsize=7.4, color=INK2)
    ax.annotate(f"$T_0$ = {T0:g}", (1, T0), xytext=(4, 4), textcoords="offset points",
                fontsize=7.4, color=MUTED)
    ax.plot(d["round"], d.T_forged_oneshot, color=BLUE, ls="-", zorder=3)
    ax.plot(d["round"], d.T_forged_churn, color=ORANGE, ls="-", zorder=4)
    kx = int(d[d.T_forged_oneshot < tau]["round"].iloc[0])
    ax.plot([kx], [d[d["round"] == kx].T_forged_oneshot.iloc[0]], marker="o",
            ms=6, color=BLUE, mec=SURFACE, mew=1.4, zorder=5)
    ax.annotate(f"convicted at round {kx}\n($k$ = rounds to conviction)",
                (kx, tau), xytext=(2.0, 0.055), textcoords="data",
                fontsize=7.4, color=BLUE, ha="left", va="bottom", linespacing=1.3,
                arrowprops=dict(arrowstyle="-", color=BLUE, lw=0.9,
                                shrinkA=2, shrinkB=3))
    ax.annotate("one-shot minting:\nconvicted once, stays convicted",
                (R * 0.58, 0.30), fontsize=7.8, color=BLUE, fontweight="bold",
                ha="center", linespacing=1.3)
    ax.annotate("churn: re-minted to $T_0$,\nevidence clock restarts",
                (R * 0.5, 0.78), fontsize=7.8, color=ORANGE, fontweight="bold",
                ha="center", linespacing=1.3)
    ax.set_xlabel("round"); ax.set_ylabel("mean trust of forged identities")
    ax.set_ylim(0, 0.92); ax.set_xlim(1, R)
    ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)

    ax = axes[1]
    ax.plot(d["round"], d.nAboveTau_oneshot, color=BLUE, ls="-", zorder=3)
    ax.plot(d["round"], d.nAboveTau_churn, color=ORANGE, ls="-", zorder=4)
    ax.annotate("churn", (R * 0.55, d.nAboveTau_churn.iloc[int(R*0.55)] + 4),
                fontsize=7.8, color=ORANGE, fontweight="bold", ha="center")
    ax.annotate("one-shot", (R * 0.45, 4.5), fontsize=7.8, color=BLUE,
                fontweight="bold", ha="center")
    ax.set_xlabel("round"); ax.set_ylabel("forged identities above $\\tau$ (eligible)")
    ax.set_xlim(1, R); ax.set_ylim(-1.5, d.nAboveTau_churn.max() * 1.16)
    ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)
    tot = int(pd.read_csv(os.path.join(RES, "results_trace.csv")).churn_events.sum())
    ax.text(0.5, -0.235, f"{tot} re-mint events over the traced run",
            transform=ax.transAxes, ha="center", fontsize=7.2, color=MUTED,
            style="italic")
    fig.subplots_adjust(wspace=0.33)
    fig.savefig(os.path.join(FIG, "fig3_trust_churn_trajectory.png"), bbox_inches="tight")
    plt.close(fig)
    print("fig3 written")

# ---------------------------------------------------------------- Figure 4
def fig_k_curve():
    """Proposition 2 as a curve. The qualitative claim holds; the k/(k+1) form
    does not. Capture under churn is FLAT in k and sits on the undefended rate,
    so a faster-converging veto buys nothing: the mechanism is bypassed, not
    merely outpaced."""
    kk = pd.read_csv(os.path.join(RES, "ksweep_with_k.csv"))
    fl = json.load(open(os.path.join(ROOT, "analysis", "k_flatness.json")))
    und = float(pd.read_csv(os.path.join(ROOT, "analysis", "t2_factorial.csv"))
                  .query("variant=='Neither'").sybCH_mean.iloc[0])
    fig, ax = plt.subplots(figsize=(6.6, 3.7))

    ks = np.linspace(2.4, 20.2, 200)
    ax.plot(ks, und * ks / (ks + 1.0), color=MUTED, lw=1.3, ls=(0, (5, 3)), zorder=1)
    ax.annotate("Proposition 2 as stated:\nundefended $\\times\\ k/(k{+}1)$\n— rejected ($p<0.001$)",
                (3.0, und * 3 / 4), xytext=(6, -34), textcoords="offset points",
                ha="left", fontsize=7.2, color=MUTED, style="italic", linespacing=1.35)

    ax.axhline(und, color=VIOLET, lw=1.1, ls=":", zorder=1)


    for arm, colr, mk, lbl in [("veto-churn", ORANGE, "^", "veto only, churn"),
                               ("roster+veto", BLUE, "o", "roster + veto")]:
        sub = kk[kk.arm == arm].dropna(subset=["k_mean"])
        xs = np.array(sorted(sub.k_mean.unique()))
        g = sub.groupby("k_mean")["sybCH"]
        m = np.array([ci95(g.get_group(x))[0] for x in xs])
        h = np.array([ci95(g.get_group(x))[1] for x in xs])
        ax.errorbar(xs, m, yerr=h, color=colr, marker=mk, ms=6.5, ls="none",
                    capsize=3, mec=SURFACE, mew=1.3, elinewidth=1.3, zorder=4)
    # the measured (flat) trend through the churn arm
    ax.plot([2.4, 20.2], [fl["mean_capture"]] * 2, color=ORANGE, lw=1.6,
            ls="-", alpha=0.55, zorder=2)
    ax.annotate("veto only under churn  $=$  undefended rate\n"
                "slope $0.0002\\pm0.0006$ per round ($p=0.425$)",
                (6.0, fl["mean_capture"]), xytext=(2.7, 0.028),
                textcoords="data", ha="left", va="bottom", fontsize=7.8,
                color=ORANGE, fontweight="bold", linespacing=1.4,
                arrowprops=dict(arrowstyle="-", color=ORANGE, lw=0.8,
                                shrinkA=3, shrinkB=2))
    ax.annotate("roster + veto — 0.000 at every $k$, every seed",
                (20.1, 0), xytext=(0, 8), textcoords="offset points",
                ha="right", fontsize=7.8, color=BLUE, fontweight="bold")

    ax.annotate("", xy=(4.0, 0.126), xytext=(19.0, 0.126),
                arrowprops=dict(arrowstyle="<->", color=INK2, lw=0.9))
    ax.text(11.5, 0.1295, "veto made 5× faster to convict — no benefit",
            ha="center", fontsize=7.2, color=INK2, style="italic")

    ax.set_xlabel("measured rounds to conviction, $k$   (slower veto →)")
    ax.set_ylabel("forged-CH share")
    ax.set_xlim(2.2, 20.6); ax.set_ylim(-0.007, 0.140)
    ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)
    fig.tight_layout()
    fig.savefig(os.path.join(FIG, "fig4_k_curve.png"), bbox_inches="tight")
    plt.close(fig)
    print("fig4 written")


# ---------------------------------------------------------------- Figure 5
def fig_cross_host():
    """Cross-host replication. The coverage claims (left, centre) hold on all
    three hosts; the half-life interaction (right) does not, and reverses on the
    host whose cluster-head population is smallest."""
    d = pd.read_csv(os.path.join(RES, "hosts_all.csv"))
    d = d[d.frac == 0.2]
    HOSTS = ["proposed", "tao_secured", "heed_secured"]
    HL = {"proposed": "ST-IT2FUC", "tao_secured": "Tao IT2-TSK", "heed_secured": "HEED"}
    ARMS = [("Roster+Veto", BLUE), ("RosterOnly", AQUA),
            ("VetoOnly", ORANGE), ("Neither", VIOLET)]
    fig, axes = plt.subplots(1, 3, figsize=(11.8, 3.7))
    w, xs = 0.19, np.arange(len(HOSTS))

    for ax, (col, title, sub) in zip(axes[:2], [
            ("sybCH", "Forged identities", "the roster's channel — zero on every host"),
            ("hwCH", "Compromised hardware", "the veto's channel — near zero on every host")]):
        for j, (arm, colr) in enumerate(ARMS):
            m, h = [], []
            for hn in HOSTS:
                a, b = ci95(d[(d.host == hn) & (d.arm == arm)][col]); m.append(a); h.append(b)
            ax.bar(xs + (j - 1.5) * w, m, w * 0.86, yerr=h, color=colr, label=arm,
                   capsize=2.5, error_kw=dict(elinewidth=1.0, ecolor=INK2), zorder=3)
            for xi, v in zip(xs + (j - 1.5) * w, m):
                if v < 0.004:
                    ax.text(xi, 0.006, "0" if v == 0 else f"{v:.3f}", ha="center",
                            va="bottom", fontsize=6.2, color=colr, fontweight="bold",
                            rotation=90)
        ax.set_xticks(xs); ax.set_xticklabels([HL[h] for h in HOSTS], fontsize=8.2)
        ax.set_title(title, fontsize=9.5, color=INK, pad=12, loc="left")
        ax.text(0, 1.012, sub, transform=ax.transAxes, fontsize=7.4, color=MUTED,
                style="italic", va="bottom")
        ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)
        ax.set_ylim(0, 0.30)
    axes[0].set_ylabel("share of cluster-head roles")
    axes[0].legend(fontsize=7.2, ncol=2, loc="upper center", handlelength=1.1,
                   columnspacing=1.0, borderpad=0.2)

    ax = axes[2]
    for j, (arm, colr) in enumerate(ARMS):
        gains = []
        for hn in HOSTS:
            base = d[(d.host == hn) & (d.arm == "Neither")].HND.mean()
            gains.append((d[(d.host == hn) & (d.arm == arm)].HND.mean() / base - 1) * 100)
        ax.bar(xs + (j - 1.5) * w, gains, w * 0.86, color=colr, zorder=3)
    ax.axhline(0, color=INK2, lw=1.0)
    ax.set_xticks(xs); ax.set_xticklabels([HL[h] for h in HOSTS], fontsize=8.2)
    ax.set_title("Half-life vs undefended", fontsize=9.5, color=INK, pad=12, loc="left")
    ax.text(0, 1.012, "the interaction does NOT replicate", transform=ax.transAxes,
            fontsize=7.4, color=MUTED, style="italic", va="bottom")
    ax.set_ylabel("change in HND (%)")
    ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)
    ax.annotate("defences shorten\nlifetime here", (xs[1] - 1.5 * w, -15.4),
                xytext=(0, -30), textcoords="offset points", ha="center",
                fontsize=7.4, color=BLUE, fontweight="bold", linespacing=1.3,
                arrowprops=dict(arrowstyle="->", color=BLUE, lw=1.0, shrinkB=3))
    ax.set_ylim(-32, 52)
    fig.subplots_adjust(wspace=0.30)
    fig.savefig(os.path.join(FIG, "fig5_cross_host.png"), bbox_inches="tight")
    plt.close(fig)
    print("fig5 written")


# ---------------------------------------------------------------- Figure 6
def fig_wave4():
    """The four §8 items. (a) the veto degrades ledger integrity and the remedy
    restores it; (b) no re-mint delay restores the veto; (c) displacement scales
    as a power law in s; (d) the attribution structure is scale- and
    topology-invariant."""
    fig, axes = plt.subplots(2, 2, figsize=(11.0, 7.4))

    # (a) ledger integrity
    ax = axes[0, 0]
    L = pd.read_csv(os.path.join(RES, "ledger_20.csv"))
    arms = [("EA-PoA", AQUA, "roster + quorum"),
            ("proposed", ORANGE, "roster + quorum + veto"),
            ("proposed+vetoAuth", BLUE, "veto on authority set")]
    fr = np.array(sorted(L.frac.unique())); w = 0.24
    for j, (a, colr, lbl) in enumerate(arms):
        m, h = [], []
        for x in fr:
            v, c = ci95(L[(L.arm == a) & (L.frac == x)].forkRefused); m.append(v); h.append(c)
        ax.bar(np.arange(len(fr)) + (j - 1) * w, m, w * 0.88, yerr=h, color=colr,
               label=lbl, capsize=2.5, error_kw=dict(elinewidth=1.0, ecolor=INK2), zorder=3)
    ax.set_xticks(np.arange(len(fr))); ax.set_xticklabels([f"{x:.0%}" for x in fr])
    ax.set_xlabel("compromised fraction"); ax.set_ylabel("fork attempts refused")
    ax.set_title("(a) Ledger integrity", fontsize=9.5, color=INK, pad=12, loc="left")
    ax.text(0, 1.012, "the veto costs integrity; gating the authority set restores it",
            transform=ax.transAxes, fontsize=7.4, color=MUTED, style="italic", va="bottom")
    ax.legend(fontsize=7.0, loc="upper right", handlelength=1.1, borderpad=0.2)
    ax.set_ylim(0, 1.12); ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)

    # (b) re-mint delay
    ax = axes[0, 1]
    D = pd.read_csv(os.path.join(RES, "delay_20.csv"))
    ds = np.array(sorted(D.delay.unique())); k_meas, und = 7.65, 0.10095
    ax.plot(ds, und * k_meas / (k_meas + ds), color=MUTED, lw=1.3, ls=(0, (5, 3)), zorder=1)
    ax.annotate("predicted by $k/(k{+}\\delta)$", (ds[-1], und * k_meas / (k_meas + ds[-1])),
                xytext=(-4, -14), textcoords="offset points", ha="right", fontsize=7.2,
                color=MUTED, style="italic")
    for a, colr, mk in [("veto-only", ORANGE, "^"), ("roster+veto", BLUE, "o")]:
        m = [ci95(D[(D.arm == a) & (D.delay == x)].sybCH)[0] for x in ds]
        h = [ci95(D[(D.arm == a) & (D.delay == x)].sybCH)[1] for x in ds]
        ax.errorbar(ds, m, yerr=h, color=colr, marker=mk, ms=6, capsize=3, lw=1.8,
                    mec=SURFACE, mew=1.2, zorder=4)
    ax.axhline(und, color=VIOLET, lw=1.0, ls=":")
    ax.annotate("undefended rate", (ds[-1], und), xytext=(-2, 5), textcoords="offset points",
                ha="right", fontsize=7.2, color=VIOLET)
    ax.annotate("veto only", (16, 0.108), fontsize=7.8, color=ORANGE, fontweight="bold")
    ax.annotate("roster + veto: 0.000 at every $\\delta$", (1, 0.006), fontsize=7.8,
                color=BLUE, fontweight="bold")
    ax.set_xlabel("re-mint delay $\\delta$ (rounds)"); ax.set_ylabel("forged-CH share")
    ax.set_title("(b) Re-mint delay", fontsize=9.5, color=INK, pad=12, loc="left")
    ax.text(0, 1.012, "no delay restores the veto, even at 4× the conviction time",
            transform=ax.transAxes, fontsize=7.4, color=MUTED, style="italic", va="bottom")
    ax.set_ylim(-0.006, 0.135); ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)

    # (c) displacement scaling law
    ax = axes[1, 0]
    R = pd.read_csv(os.path.join(OUT_A, "t10_displacement_scaling.csv"))
    HL = {"proposed": "ST-IT2FUC", "tao_secured": "Tao IT2-TSK", "heed_secured": "HEED"}
    for h, colr, mk in [("proposed", BLUE, "o"), ("tao_secured", ORANGE, "^"),
                        ("heed_secured", AQUA, "s")]:
        g = R[R.host == h].sort_values("s")
        lr = stats.linregress(np.log(g.s), np.log(g.ratio))
        ax.loglog(g.s, g.ratio, color=colr, marker=mk, ms=6, lw=1.8, mec=SURFACE, mew=1.2,
                  label=f"{HL[h]}, slope {lr.slope:+.2f}")
    ax.set_xlabel("forged identities per attacker, $s$")
    ax.set_ylabel("displacement ratio (×)")
    ax.set_title("(c) Displacement scaling", fontsize=9.5, color=INK, pad=12, loc="left")
    ax.text(0, 1.012, "ratio is a power law in s; absolute displacement saturates near 0.20",
            transform=ax.transAxes, fontsize=7.4, color=MUTED, style="italic", va="bottom")
    from matplotlib.ticker import NullFormatter
    ax.set_xticks([1, 2, 3, 5, 8]); ax.set_xticklabels(["1", "2", "3", "5", "8"])
    ax.xaxis.set_minor_formatter(NullFormatter())
    ax.legend(fontsize=7.0, loc="upper left", handlelength=1.3, borderpad=0.25)
    ax.set_xlim(0.85, 9.5)
    ax.grid(True, which="major", color=GRID, lw=0.6); ax.set_axisbelow(True)

    # (d) scale and topology invariance
    ax = axes[1, 1]
    T = pd.read_csv(os.path.join(RES, "scale_topo_20.csv"))
    cells, lbls = [], []
    for N in sorted(T.N.unique()):
        for e in [0, 1]:
            cells.append((N, e)); lbls.append(f"{N}\n{'edge' if e else 'ctr'}")
    xs = np.arange(len(cells)); w = 0.19
    series = [("Roster+Veto", BLUE, "sybCH"), ("RosterOnly", AQUA, "sybCH"),
              ("VetoOnly", ORANGE, "sybCH"), ("Neither", VIOLET, "sybCH")]
    for j, (a, colr, col) in enumerate(series):
        m = [ci95(T[(T.N == N) & (T.edgeBS == e) & (T.arm == a)][col])[0] for N, e in cells]
        h = [ci95(T[(T.N == N) & (T.edgeBS == e) & (T.arm == a)][col])[1] for N, e in cells]
        ax.bar(xs + (j - 1.5) * w, m, w * 0.86, yerr=h, color=colr, label=a, capsize=2,
               error_kw=dict(elinewidth=0.9, ecolor=INK2), zorder=3)
    ax.set_xticks(xs); ax.set_xticklabels(lbls, fontsize=7.2)
    ax.set_xlabel("network size and base-station placement")
    ax.set_ylabel("forged-CH share")
    ax.set_title("(d) Scale and topology", fontsize=9.5, color=INK, pad=12, loc="left")
    ax.text(0, 1.012, "roster arms hold 0.0000 in every cell; veto tracks undefended",
            transform=ax.transAxes, fontsize=7.4, color=MUTED, style="italic", va="bottom")
    ax.legend(fontsize=7.0, ncol=2, loc="upper left", handlelength=1.1, columnspacing=0.9,
              borderpad=0.2)
    ax.set_ylim(0, 0.26); ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)

    fig.subplots_adjust(hspace=0.52, wspace=0.26)
    fig.savefig(os.path.join(FIG, "fig6_wave4.png"), bbox_inches="tight")
    plt.close(fig)
    print("fig6 written")


# ------------------------------------------------- split-paper figure variants
def fig_p1_delay():
    """P1 standalone: capture under a veto against the re-mint delay, with the
    duty-cycle curve the model predicts."""
    D = pd.read_csv(os.path.join(RES, "delay_20.csv"))
    ds = np.array(sorted(D.delay.unique())); k_meas, und = 7.65, 0.10095
    fig, ax = plt.subplots(figsize=(5.9, 3.5))
    ax.plot(ds, und * k_meas / (k_meas + ds), color=MUTED, lw=1.4, ls=(0, (5, 3)), zorder=1)
    ax.annotate("predicted by $k/(k{+}\\delta)$", (ds[-1], und*k_meas/(k_meas+ds[-1])),
                xytext=(-4, -15), textcoords="offset points", ha="right", fontsize=7.4,
                color=MUTED, style="italic")
    for a, colr, mk in [("veto-only", ORANGE, "^"), ("roster+veto", BLUE, "o")]:
        m = [ci95(D[(D.arm == a) & (D.delay == x)].sybCH)[0] for x in ds]
        h = [ci95(D[(D.arm == a) & (D.delay == x)].sybCH)[1] for x in ds]
        ax.errorbar(ds, m, yerr=h, color=colr, marker=mk, ms=6.5, capsize=3, lw=1.9,
                    mec=SURFACE, mew=1.2, zorder=4)
    ax.axhline(und, color=VIOLET, lw=1.0, ls=":")
    ax.annotate("undefended rate", (ds[-1], und), xytext=(-2, 6),
                textcoords="offset points", ha="right", fontsize=7.4, color=VIOLET)
    ax.annotate("veto only", (17, 0.109), fontsize=8.0, color=ORANGE, fontweight="bold")
    ax.annotate("roster + veto: 0.000 at every $\\delta$", (1, 0.007), fontsize=8.0,
                color=BLUE, fontweight="bold")
    ax.set_xlabel("re-mint delay $\\delta$ (rounds)   (slower attacker →)")
    ax.set_ylabel("forged-CH share")
    ax.set_ylim(-0.006, 0.135)
    ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)
    fig.tight_layout()
    fig.savefig(os.path.join(FIG, "fig_p1_delay.png"), bbox_inches="tight")
    plt.close(fig); print("fig_p1_delay written")


def fig_p2_placement():
    """P2: ledger integrity, displacement scaling, and scale/topology invariance."""
    from matplotlib.ticker import NullFormatter
    fig, axes = plt.subplots(1, 3, figsize=(12.0, 3.8))

    ax = axes[0]
    L = pd.read_csv(os.path.join(RES, "ledger_20.csv"))
    arms = [("EA-PoA", AQUA, "roster + quorum"),
            ("proposed", ORANGE, "+ veto at election"),
            ("proposed+vetoAuth", BLUE, "+ veto at both gates")]
    fr = np.array(sorted(L.frac.unique())); w = 0.24
    for j, (a, colr, lbl) in enumerate(arms):
        m = [ci95(L[(L.arm == a) & (L.frac == x)].forkRefused)[0] for x in fr]
        h = [ci95(L[(L.arm == a) & (L.frac == x)].forkRefused)[1] for x in fr]
        ax.bar(np.arange(len(fr)) + (j-1)*w, m, w*0.88, yerr=h, color=colr, label=lbl,
               capsize=2.5, error_kw=dict(elinewidth=1.0, ecolor=INK2), zorder=3)
    ax.set_xticks(np.arange(len(fr))); ax.set_xticklabels([f"{x:.0%}" for x in fr])
    ax.set_xlabel("compromised fraction"); ax.set_ylabel("fork attempts refused")
    ax.set_title("(a) Ledger integrity", fontsize=9.5, color=INK, pad=12, loc="left")
    ax.text(0, 1.012, "where the gate is enforced decides the channel",
            transform=ax.transAxes, fontsize=7.4, color=MUTED, style="italic", va="bottom")
    ax.legend(fontsize=7.0, loc="upper right", handlelength=1.1, borderpad=0.2)
    ax.set_ylim(0, 1.15); ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)

    ax = axes[1]
    R = pd.read_csv(os.path.join(OUT_A, "t10_displacement_scaling.csv"))
    HL = {"proposed": "ST-IT2FUC", "tao_secured": "Tao IT2-TSK", "heed_secured": "HEED"}
    for h, colr, mk in [("proposed", BLUE, "o"), ("tao_secured", ORANGE, "^"),
                        ("heed_secured", AQUA, "s")]:
        g = R[R.host == h].sort_values("s")
        lr = stats.linregress(np.log(g.s), np.log(g.ratio))
        ax.loglog(g.s, g.ratio, color=colr, marker=mk, ms=6, lw=1.8, mec=SURFACE, mew=1.2,
                  label=f"{HL[h]}, slope {lr.slope:+.2f}")
    ax.set_xticks([1, 2, 3, 5, 8]); ax.set_xticklabels(["1", "2", "3", "5", "8"])
    ax.xaxis.set_minor_formatter(NullFormatter()); ax.set_xlim(0.85, 9.5)
    ax.set_xlabel("forged identities per attacker, $s$")
    ax.set_ylabel("displacement ratio (×)")
    ax.set_title("(b) Displacement scaling", fontsize=9.5, color=INK, pad=12, loc="left")
    ax.text(0, 1.012, "ratio is a power law; absolute displacement saturates",
            transform=ax.transAxes, fontsize=7.4, color=MUTED, style="italic", va="bottom")
    ax.legend(fontsize=7.0, loc="upper left", handlelength=1.3, borderpad=0.25)
    ax.grid(True, which="major", color=GRID, lw=0.6); ax.set_axisbelow(True)

    ax = axes[2]
    T = pd.read_csv(os.path.join(RES, "scale_topo_20.csv"))
    cells = [(N, e) for N in sorted(T.N.unique()) for e in (0, 1)]
    lbls = [f"{N}\n{'edge' if e else 'ctr'}" for N, e in cells]
    xs = np.arange(len(cells)); w = 0.19
    for j, (a, colr) in enumerate([("Roster+Veto", BLUE), ("RosterOnly", AQUA),
                                   ("VetoOnly", ORANGE), ("Neither", VIOLET)]):
        m = [ci95(T[(T.N == N) & (T.edgeBS == e) & (T.arm == a)].sybCH)[0] for N, e in cells]
        h = [ci95(T[(T.N == N) & (T.edgeBS == e) & (T.arm == a)].sybCH)[1] for N, e in cells]
        ax.bar(xs + (j-1.5)*w, m, w*0.86, yerr=h, color=colr, label=a, capsize=2,
               error_kw=dict(elinewidth=0.9, ecolor=INK2), zorder=3)
    ax.set_xticks(xs); ax.set_xticklabels(lbls, fontsize=7.2)
    ax.set_xlabel("network size and base-station placement")
    ax.set_ylabel("forged-CH share")
    ax.set_title("(c) Scale and topology", fontsize=9.5, color=INK, pad=12, loc="left")
    ax.text(0, 1.012, "roster arms hold 0.0000 in every cell",
            transform=ax.transAxes, fontsize=7.4, color=MUTED, style="italic", va="bottom")
    ax.legend(fontsize=6.8, ncol=2, loc="upper left", handlelength=1.0, columnspacing=0.8,
              borderpad=0.2)
    ax.set_ylim(0, 0.27); ax.grid(axis="y", color=GRID, lw=0.7); ax.set_axisbelow(True)

    fig.subplots_adjust(wspace=0.30)
    fig.savefig(os.path.join(FIG, "fig_p2_placement.png"), bbox_inches="tight")
    plt.close(fig); print("fig_p2_placement written")

if __name__ == "__main__":
    fig_coverage_matrix()
    fig_trust_trajectory()
    for f in (fig_admission_vs_fraction, fig_k_curve, fig_cross_host, fig_wave4,
              fig_p1_delay, fig_p2_placement):
        try: f()
        except Exception as e: print(f"{f.__name__} skipped: {e}")
