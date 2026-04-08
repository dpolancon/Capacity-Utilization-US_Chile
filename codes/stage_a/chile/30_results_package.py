#!/usr/bin/env python3
"""
Chile Stage A — Results Package
Four figures + chapter tables + appendix tables + appendix figures.
All data confirmed present — no estimation required.
"""

import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
from matplotlib.lines import Line2D

# ── Paths ─────────────────────────────────────────────────────────────────────
REPO = "/home/user/Capacity-Utilization-US_Chile"
CSV1 = os.path.join(REPO, "output/stage_b/Chile/csv")
FIG  = os.path.join(REPO, "output/stage_b/Chile/figs")
TAB  = os.path.join(REPO, "output/stage_b/Chile/tables")
os.makedirs(FIG, exist_ok=True)
os.makedirs(TAB, exist_ok=True)

# ── Load all CSVs ─────────────────────────────────────────────────────────────
ect_m      = pd.read_csv(os.path.join(REPO, "data/processed/Chile/ECT_m_stage1.csv"))
cv_stage1  = pd.read_csv(os.path.join(CSV1, "stage1_cointegrating_vectors.csv"))
std_impact = pd.read_csv(os.path.join(CSV1, "stage1_standardized_impacts.csv"))
wk_exog    = pd.read_csv(os.path.join(CSV1, "stage1_weak_exogeneity.csv"))
alpha_s1   = pd.read_csv(os.path.join(CSV1, "stage1_alpha_loadings.csv"))
panel      = pd.read_csv(os.path.join(CSV1, "stage2_panel_with_mu_v2.csv"))
theta_cl   = pd.read_csv(os.path.join(CSV1, "stage2_theta_CL_series.csv"))
regime_df  = pd.read_csv(os.path.join(CSV1, "stage2_regime_classification.csv"))
alpha_s2   = pd.read_csv(os.path.join(CSV1, "stage2_alpha_loadings.csv"))
ssr_grid   = pd.read_csv(os.path.join(CSV1, "stage2_ssr_grid.csv"))
lr_boot    = pd.read_csv(os.path.join(CSV1, "stage2_LR_bootstrap.csv"))
params     = pd.read_csv(os.path.join(CSV1, "stage2_structural_params.csv"))
johansen   = pd.read_csv(os.path.join(CSV1, "stage1_johansen_trace.csv"))

print("All CSVs loaded.")

# ── Period labels ─────────────────────────────────────────────────────────────
def label_period(year):
    if year < 1940:
        return "Pre-ISI"
    elif year <= 1972:
        return "ISI"
    elif year <= 1982:
        return "Crisis"
    else:
        return "Neoliberal"

panel["period"] = panel["year"].apply(label_period)
theta_cl["period"] = theta_cl["year"].apply(label_period)

# ── House style ───────────────────────────────────────────────────────────────
period_colors = {
    "Pre-ISI":    "#6baed6",
    "ISI":        "#2171b5",
    "Crisis":     "#cb181d",
    "Neoliberal": "#fc8d59",
}
period_order = ["Pre-ISI", "ISI", "Crisis", "Neoliberal"]

gamma_hat = -0.1394  # threshold (locked from estimation)

# Matplotlib-compatible greys (R "greyNN" → float NN/100)
GREY30 = "0.30"
GREY40 = "0.40"
GREY50 = "0.50"
GREY60 = "0.60"
GREY75 = "0.75"

def apply_ch2_style(ax):
    """Apply chapter 2 house style to an axis."""
    ax.grid(True, which="major", color="#EBEBEB", linewidth=0.6)
    ax.grid(False, which="minor")
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(GREY40)
    ax.spines["bottom"].set_color(GREY40)
    ax.tick_params(labelsize=11)


# =============================================================================
# FIGURE 1: ECT_m TIME SERIES WITH THRESHOLD AND REGIME SHADING
# =============================================================================
print("\n── Figure 1: ECT_m threshold ──")

regime_merge = regime_df[["year", "regime"]].copy()
ect_plot = ect_m.merge(regime_merge, on="year", how="left", suffixes=("_orig", "_cls"))
# Use the classification regime column
if "regime_cls" in ect_plot.columns:
    ect_plot["regime_class"] = ect_plot["regime_cls"]
elif "regime_y" in ect_plot.columns:
    ect_plot["regime_class"] = ect_plot["regime_y"]
else:
    ect_plot["regime_class"] = ect_plot["regime"]
ect_plot["regime_class"] = ect_plot["regime_class"].fillna("Regime1_slack")

fig1, ax1 = plt.subplots(figsize=(9, 4.5))

# Regime 2 shading
r2_years = ect_plot.loc[ect_plot["regime_class"] == "Regime2_binding", "year"]
for yr in r2_years:
    ax1.axvspan(yr - 0.5, yr + 0.5, color="#cb181d", alpha=0.10, linewidth=0)

# Threshold and zero lines
ax1.axhline(gamma_hat, linestyle="--", color=GREY30, linewidth=0.7)
ax1.axhline(0, linestyle=":", color=GREY60, linewidth=0.5)

# ECT_m series
ax1.plot(ect_plot["year"], ect_plot["ECT_m"], linewidth=0.9, color="#2171b5")

# Key year annotations
for yr_label in [1973, 1982]:
    ymin = ect_plot["ECT_m"].min()
    ax1.annotate(str(yr_label), xy=(yr_label, ymin + 0.08),
                 fontsize=9.5, color="#cb181d", rotation=90, va="bottom")

ax1.set_ylabel(r"$\widehat{ECT}_{m,t}$", fontsize=13)
ax1.set_xticks(range(1920, 2025, 10))
ax1.set_xlim(1918, 2026)
apply_ch2_style(ax1)

# Legend
legend_elements = [
    Rectangle((0, 0), 1, 1, facecolor="#cb181d", alpha=0.15, edgecolor="none",
              label="Regime 2 (BoP binding)"),
    Line2D([0], [0], color=GREY30, linestyle="--", linewidth=0.7,
           label=f"$\\hat{{\\gamma}} = {gamma_hat:.3f}$"),
]
ax1.legend(handles=legend_elements, loc="upper left", fontsize=10, framealpha=0.8)

fig1.tight_layout()
fig1.savefig(os.path.join(FIG, "fig1_ECTm_threshold.pdf"), dpi=300)
fig1.savefig(os.path.join(FIG, "fig1_ECTm_threshold.png"), dpi=300)
plt.close(fig1)
print("Figure 1 saved.")


# =============================================================================
# FIGURE 2: theta^CL TIME SERIES
# =============================================================================
print("\n── Figure 2: theta_CL ──")

fig2, ax2 = plt.subplots(figsize=(9, 4.5))

# Harrodian knife-edge and US Fordist reference
ax2.axhline(1.0, linestyle="--", color=GREY30, linewidth=0.7)
ax2.axhline(0.787, linestyle=":", color="#8856a7", linewidth=0.6, alpha=0.7)

# Plot by period
for period in period_order:
    mask = theta_cl["period"] == period
    sub = theta_cl.loc[mask].sort_values("year")
    if sub.empty:
        continue
    ax2.plot(sub["year"], sub["theta_CL"], linewidth=0.9,
             color=period_colors[period], label=period)
    ax2.scatter(sub["year"], sub["theta_CL"], s=8,
                color=period_colors[period], zorder=5)

# Annotations
ax2.annotate("Harrodian knife-edge ($\\theta = 1$)",
             xy=(2020, 1.03), fontsize=9.5, color=GREY30, ha="right")
ax2.annotate("US Fordist $\\bar{\\theta} = 0.787$",
             xy=(1925, 0.74), fontsize=9, color="#8856a7")

ax2.set_ylabel(r"$\hat{\theta}^{CL}(\omega_t,\, s_t^{ME})$", fontsize=13)
ax2.set_xticks(range(1920, 2025, 10))
ax2.set_xlim(1918, 2026)
ax2.set_yticks(np.arange(0, 1.4, 0.2))
apply_ch2_style(ax2)
ax2.legend(loc="lower right", fontsize=10, framealpha=0.8)

fig2.tight_layout()
fig2.savefig(os.path.join(FIG, "fig2_theta_CL.pdf"), dpi=300)
fig2.savefig(os.path.join(FIG, "fig2_theta_CL.png"), dpi=300)
plt.close(fig2)
print("Figure 2 saved.")


# =============================================================================
# FIGURE 3: REGIME CLASSIFICATION OVERLAID ON ECT_m
# =============================================================================
print("\n── Figure 3: Regime classification ──")

ect_regime = ect_m.merge(regime_df[["year", "regime"]], on="year", how="left",
                          suffixes=("_orig", "_cls"))
if "regime_cls" in ect_regime.columns:
    ect_regime["reg"] = ect_regime["regime_cls"]
else:
    ect_regime["reg"] = ect_regime.get("regime_y", ect_regime.get("regime"))
ect_regime["reg"] = ect_regime["reg"].fillna("Regime1_slack")

fig3, ax3 = plt.subplots(figsize=(9, 4.5))

# Threshold and zero lines
ax3.axhline(gamma_hat, linestyle="--", color=GREY30, linewidth=0.6)
ax3.axhline(0, linestyle=":", color=GREY60, linewidth=0.4)

# Background line
ax3.plot(ect_regime["year"], ect_regime["ECT_m"],
         color=GREY75, linewidth=0.5, zorder=1)

# Regime 2 points (binding)
r2 = ect_regime[ect_regime["reg"] == "Regime2_binding"]
r1 = ect_regime[ect_regime["reg"] != "Regime2_binding"]

ax3.scatter(r2["year"], r2["ECT_m"], color="#cb181d", s=20, zorder=3,
            marker="o", label="Regime 2 (BoP binding)")
ax3.scatter(r1["year"], r1["ECT_m"], color="#2171b5", s=12, zorder=2,
            marker="o", facecolors="none", linewidths=0.7,
            label="Regime 1 (BoP slack)")

# Period annotations — positioned to avoid overlap
annotations = [
    (1945, 0.55, "ISI peaks\n1941–50", "#cb181d"),
    (1963, 0.55, "1961–66", "#cb181d"),
    (1968, -0.80, "Frei–Allende\n1967–72", "#2171b5"),
    (1979, -0.80, "Chicago Boys\n1975–81", "#2171b5"),
    (2010, 0.55, "1997–2024\nunbroken", "#cb181d"),
]
for x, y, txt, c in annotations:
    ax3.annotate(txt, xy=(x, y), fontsize=8.5, color=c, ha="center", va="center")

ax3.set_ylabel(r"$\widehat{ECT}_{m,t}$", fontsize=13)
ax3.set_xticks(range(1920, 2025, 10))
ax3.set_xlim(1918, 2026)
apply_ch2_style(ax3)
ax3.legend(loc="upper left", fontsize=10, framealpha=0.8,
           markerscale=1.3)

fig3.tight_layout()
fig3.savefig(os.path.join(FIG, "fig3_regime_classification.pdf"), dpi=300)
fig3.savefig(os.path.join(FIG, "fig3_regime_classification.png"), dpi=300)
plt.close(fig3)
print("Figure 3 saved.")


# =============================================================================
# FIGURE 4: mu^CL CAPACITY UTILIZATION
# =============================================================================
print("\n── Figure 4: mu_CL ──")

panel_mu = panel.dropna(subset=["mu_CL"]).copy()

fig4, ax4 = plt.subplots(figsize=(9, 4.5))

ax4.axhline(1.0, linestyle="--", color=GREY30, linewidth=0.7)
ax4.axvline(1978, linestyle=":", color=GREY50, linewidth=0.6)

for period in period_order:
    mask = panel_mu["period"] == period
    sub = panel_mu.loc[mask].sort_values("year")
    if sub.empty:
        continue
    ax4.plot(sub["year"], sub["mu_CL"], linewidth=0.9,
             color=period_colors[period], label=period)

# Pin year marker
pin_row = panel_mu[panel_mu["year"] == 1980]
if not pin_row.empty:
    ax4.scatter(1980, pin_row["mu_CL"].values[0], color="black", s=55,
                marker="D", zorder=5)
    ax4.annotate(r"Pin: $\mu$(1980) = 1.0", xy=(1982, 1.03),
                 fontsize=9.5, ha="left")

ax4.annotate(r"$\leftarrow$ Identification window",
             xy=(1977, 0.50), fontsize=9, color=GREY40, ha="right")

ax4.set_ylabel(r"$\hat{\mu}_t^{CL}$", fontsize=13)
ax4.set_xticks(range(1920, 2025, 10))
ax4.set_xlim(1918, 2026)
ax4.set_yticks(np.arange(0.4, 1.5, 0.2))
apply_ch2_style(ax4)
ax4.legend(loc="upper left", fontsize=10, framealpha=0.8)

fig4.tight_layout()
fig4.savefig(os.path.join(FIG, "fig4_mu_CL.pdf"), dpi=300)
fig4.savefig(os.path.join(FIG, "fig4_mu_CL.png"), dpi=300)
plt.close(fig4)
print("Figure 4 saved.")


# =============================================================================
# CHAPTER BODY TABLES
# =============================================================================
print("\n── Chapter body tables ──")

# ── Table 1: Standardized impacts across channels and regimes ─────────────────
# std_impact is already wide: channel, coeff_pre, sd_pre, impact_pre, coeff_post, sd_post, impact_post
tab1 = std_impact.copy()
tab1["channel_label"] = tab1["channel"].map({
    "k_ME (Tavares)":          r"Machinery accumulation → imports (ζ₁)",
    "nrs (Kaldor/Palma-Marcel)": r"Non-reinvested surplus → imports (ζ₂)",
    "omega (wage share)":      r"Wage share → import compression (ζ₃)",
})
tab1 = tab1[["channel_label", "coeff_pre", "sd_pre", "impact_pre",
             "coeff_post", "sd_post", "impact_post"]]
tab1.columns = ["channel", "coeff_pre1973", "sd_pre1973", "impact_pre1973",
                "coeff_post1973", "sd_post1973", "impact_post1973"]
tab1.to_csv(os.path.join(TAB, "tab1_standardized_impacts.csv"), index=False)
print("Table 1 saved.")
print(tab1.to_string(index=False))

# ── Table 2: theta^CL and mu^CL period averages ──────────────────────────────
tab2 = (panel.groupby("period")
        .agg(theta_mean=("theta_CL", "mean"), mu_mean=("mu_CL", "mean"))
        .reindex(period_order)
        .reset_index())
tab2.to_csv(os.path.join(TAB, "tab2_theta_mu_period_averages.csv"), index=False)
print("\nTable 2 saved.")
print(tab2.to_string(index=False))

# ── Table 3: Shadow price test ────────────────────────────────────────────────
tab3 = alpha_s2[alpha_s2["equation"] == "y"].copy()
tab3["shadow_price_confirmed"] = tab3["alpha_r2"].abs() < tab3["alpha_r1"].abs()
tab3["slowdown_factor"] = round(tab3["alpha_r1"].abs() / tab3["alpha_r2"].abs(), 1)
tab3.to_csv(os.path.join(TAB, "tab3_shadow_price_test.csv"), index=False)
print("\nTable 3 saved.")
print(tab3.to_string(index=False))


# =============================================================================
# APPENDIX TABLES
# =============================================================================
print("\n── Appendix tables ──")

# ── Table A1: Stage 1 Johansen trace ─────────────────────────────────────────
johansen.to_csv(os.path.join(TAB, "tabA1_stage1_johansen_trace.csv"), index=False)
print("Table A1 saved.")

# ── Table A2: Stage 1 alpha loadings + weak exogeneity ───────────────────────
tabA2 = alpha_s1.merge(wk_exog, on=["regime", "variable"], how="left")
tabA2.to_csv(os.path.join(TAB, "tabA2_stage1_alpha_weakexog.csv"), index=False)
print("Table A2 saved.")

# ── Table A3: Stage 2 full alpha matrix ──────────────────────────────────────
alpha_s2.to_csv(os.path.join(TAB, "tabA3_stage2_alpha_loadings.csv"), index=False)
print("Table A3 saved.")

# ── Table A4: Structural parameters ─────────────────────────────────────────
params.to_csv(os.path.join(TAB, "tabA4_structural_params.csv"), index=False)
print("Table A4 saved.")

# ── Table A5: Pin-year sensitivity ───────────────────────────────────────────
pin_configs = [(1978, 0.95), (1979, 1.0), (1980, 1.0), (1981, 1.0)]
pin_rows = []

for pyr, pmu in pin_configs:
    mu_a = np.full(len(panel), np.nan)
    idx_pin = panel.index[panel["year"] == pyr]
    if len(idx_pin) == 0:
        continue
    mu_a[idx_pin[0]] = pmu

    # Forward from pin
    for i in range(idx_pin[0] + 1, len(panel)):
        g = panel.loc[i, "g_mu"]
        if not np.isnan(g) and not np.isnan(mu_a[i - 1]):
            mu_a[i] = mu_a[i - 1] * np.exp(g)

    # Backward from pin
    for i in range(idx_pin[0] - 1, -1, -1):
        g = panel.loc[i + 1, "g_mu"]
        if not np.isnan(g) and not np.isnan(mu_a[i + 1]):
            mu_a[i] = mu_a[i + 1] / np.exp(g)

    years = panel["year"].values
    isi_mean    = np.nanmean(mu_a[(years >= 1940) & (years <= 1972)])
    crisis_mean = np.nanmean(mu_a[(years >= 1973) & (years <= 1982)])
    neo_mean    = np.nanmean(mu_a[(years >= 1983) & (years <= 2024)])

    pin_rows.append({
        "pin_year": pyr, "pin_value": pmu,
        "ISI_mean": round(isi_mean, 4),
        "crisis_mean": round(crisis_mean, 4),
        "neo_mean": round(neo_mean, 4),
    })

pin_sensitivity = pd.DataFrame(pin_rows)
pin_sensitivity.to_csv(os.path.join(TAB, "tabA5_pin_sensitivity.csv"), index=False)
print("Table A5 saved.")
print(pin_sensitivity.to_string(index=False))


# =============================================================================
# APPENDIX FIGURE A1: SSR Grid Search Surface
# =============================================================================
print("\n── Appendix Figure A1: SSR surface ──")

gamma_min_idx = ssr_grid["ssr"].idxmin()
gamma_min_ssr = ssr_grid.loc[gamma_min_idx, "gamma"]

figA1, axA1 = plt.subplots(figsize=(8, 4))
axA1.plot(ssr_grid["gamma"], ssr_grid["ssr"], linewidth=0.8, color="#2171b5")
axA1.axvline(gamma_min_ssr, linestyle="--", color="#cb181d", linewidth=0.7)
axA1.annotate(f"$\\hat{{\\gamma}} = {gamma_min_ssr:.4f}$",
              xy=(gamma_min_ssr + 0.01, ssr_grid["ssr"].max() * 0.97),
              fontsize=10, color="#cb181d", ha="left")
axA1.set_xlabel(r"Candidate threshold ($\gamma$)", fontsize=12)
axA1.set_ylabel("Sum of squared residuals", fontsize=12)
apply_ch2_style(axA1)

figA1.tight_layout()
figA1.savefig(os.path.join(FIG, "figA1_ssr_surface.pdf"), dpi=300)
figA1.savefig(os.path.join(FIG, "figA1_ssr_surface.png"), dpi=300)
plt.close(figA1)
print("Figure A1 saved.")


# =============================================================================
# APPENDIX FIGURE A2: Bootstrap LR Distribution
# =============================================================================
print("\n── Appendix Figure A2: Bootstrap LR ──")

ssr_lin = ssr_grid["ssr"].max()
ssr_min = ssr_grid["ssr"].min()
T_est   = len(regime_df)
LR_obs  = T_est * np.log(ssr_lin / ssr_min)
p_boot  = (lr_boot["LR_boot"] >= LR_obs).mean()

figA2, axA2 = plt.subplots(figsize=(8, 4))
axA2.hist(lr_boot["LR_boot"], bins=50, color="#6baed6", edgecolor="white",
          alpha=0.85)
axA2.axvline(LR_obs, color="#cb181d", linestyle="--", linewidth=0.9)
axA2.annotate(f"LR = {LR_obs:.2f}\np = {p_boot:.3f}",
              xy=(LR_obs * 1.05, axA2.get_ylim()[1] * 0.85),
              fontsize=10, color="#cb181d", ha="left")
axA2.set_xlabel("Bootstrap LR statistic", fontsize=12)
axA2.set_ylabel("Count", fontsize=12)
apply_ch2_style(axA2)

figA2.tight_layout()
figA2.savefig(os.path.join(FIG, "figA2_bootstrap_LR.pdf"), dpi=300)
figA2.savefig(os.path.join(FIG, "figA2_bootstrap_LR.png"), dpi=300)
plt.close(figA2)
print("Figure A2 saved.")


# =============================================================================
# FINAL INVENTORY REPORT
# =============================================================================
print("\n" + "=" * 64)
print("  RESULTS PACKAGE — FILE INVENTORY")
print("=" * 64)

all_outputs = [
    os.path.join(FIG, "fig1_ECTm_threshold.pdf"),
    os.path.join(FIG, "fig1_ECTm_threshold.png"),
    os.path.join(FIG, "fig2_theta_CL.pdf"),
    os.path.join(FIG, "fig2_theta_CL.png"),
    os.path.join(FIG, "fig3_regime_classification.pdf"),
    os.path.join(FIG, "fig3_regime_classification.png"),
    os.path.join(FIG, "fig4_mu_CL.pdf"),
    os.path.join(FIG, "fig4_mu_CL.png"),
    os.path.join(FIG, "figA1_ssr_surface.pdf"),
    os.path.join(FIG, "figA1_ssr_surface.png"),
    os.path.join(FIG, "figA2_bootstrap_LR.pdf"),
    os.path.join(FIG, "figA2_bootstrap_LR.png"),
    os.path.join(TAB, "tab1_standardized_impacts.csv"),
    os.path.join(TAB, "tab2_theta_mu_period_averages.csv"),
    os.path.join(TAB, "tab3_shadow_price_test.csv"),
    os.path.join(TAB, "tabA1_stage1_johansen_trace.csv"),
    os.path.join(TAB, "tabA2_stage1_alpha_weakexog.csv"),
    os.path.join(TAB, "tabA3_stage2_alpha_loadings.csv"),
    os.path.join(TAB, "tabA4_structural_params.csv"),
    os.path.join(TAB, "tabA5_pin_sensitivity.csv"),
]

for f in all_outputs:
    status = "OK" if os.path.exists(f) else "MISSING"
    print(f"  {os.path.basename(f)}: {status}")

print("=" * 64)
print("Done.")
