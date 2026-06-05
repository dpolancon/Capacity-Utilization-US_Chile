"""Regenerate fig4_mu_CL — full sample with s_ME-corrected data."""
import os, numpy as np, pandas as pd
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt

REPO = "C:/ReposGitHub/Capacity-Utilization-US_Chile"
CSV1 = os.path.join(REPO, "output/stage_a/Chile/csv")
FIG  = os.path.join(REPO, "output/stage_a/Chile/figs")
os.makedirs(FIG, exist_ok=True)

panel = pd.read_csv(os.path.join(CSV1, "stage2_panel_with_mu_v2.csv"))

def label_period(year):
    if year < 1940: return "Pre-ISI"
    elif year <= 1972: return "ISI"
    elif year <= 1982: return "Crisis"
    else: return "Neoliberal"

panel["period"] = panel["year"].apply(label_period)

period_colors = {"Pre-ISI": "#6baed6", "ISI": "#2171b5",
                 "Crisis": "#cb181d", "Neoliberal": "#fc8d59"}
period_order = ["Pre-ISI", "ISI", "Crisis", "Neoliberal"]
GREY30, GREY40, GREY50 = "0.30", "0.40", "0.50"

def apply_ch2_style(ax):
    ax.grid(True, which="major", color="#EBEBEB", linewidth=0.6)
    ax.grid(False, which="minor")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

panel_mu = panel.dropna(subset=["mu_CL"]).copy()

fig4, ax4 = plt.subplots(figsize=(9, 4.5))

ax4.axhline(1.0, linestyle="--", color=GREY30, linewidth=0.7)
ax4.axvline(1978, linestyle=":", color=GREY50, linewidth=0.6)

for period in period_order:
    mask = panel_mu["period"] == period
    sub = panel_mu.loc[mask].sort_values("year")
    if sub.empty:
        continue
    ax4.plot(sub["year"], sub["mu_CL"], linewidth=1.0,
             color=period_colors[period], label=period)

# Pin year marker
pin_row = panel_mu[panel_mu["year"] == 1980]
if not pin_row.empty:
    ax4.scatter(1980, pin_row["mu_CL"].values[0], color="black", s=55,
                marker="D", zorder=5)
    ax4.annotate(r"Pin: $\mu$(1980) = 1.0", xy=(1982, 1.03),
                 fontsize=9.5, ha="left")

ax4.annotate(r"Identification window $\rightarrow$",
             xy=(1965, 0.48), fontsize=9, color=GREY40, ha="right")
ax4.annotate(r"$\leftarrow$ Extrapolation",
             xy=(1983, 0.48), fontsize=9, color=GREY50, ha="left")

ax4.set_ylabel(r"$\hat{\mu}_t^{CL}$", fontsize=13)
ax4.set_xticks(range(1920, 2025, 10))
ax4.set_xlim(1918, 2026)
apply_ch2_style(ax4)
ax4.legend(loc="upper left", fontsize=10, framealpha=0.8)

fig4.tight_layout()
fig4.savefig(os.path.join(FIG, "fig4_mu_CL.pdf"), dpi=300)
fig4.savefig(os.path.join(FIG, "fig4_mu_CL.png"), dpi=300)
plt.close(fig4)
print("Figure 4 regenerated — full sample, s_ME corrected.")
