# Notebook 6: μ̂^CL Construction, Results, and Chapter Mapping
## From θ̂^CL to Capacity Utilization — Closing the Identification Chain

**Prerequisite:** NB-05 (θ̂^CL series confirmed)
**Output files:** `stage2_panel_with_mu_v2.csv`, `stage2_mu_sensitivity.csv`

---

## 6.1 The productive capacity growth closure

From §3.5 equation (30):

$$g_{Y_t^{p,CL}} = \hat{\theta}^{CL}(\omega_t, \phi_t) \cdot g_{K_t^{CL}}$$

where:
- $g_{Y_t^{p,CL}} = \Delta y_t^p$ — growth rate of productive capacity
- $g_{K_t^{CL}} = \Delta k_t^{CL}$ — growth rate of aggregate capital
- $\hat{\theta}^{CL}(\omega_t, \phi_t)$ — the time-varying transformation elasticity from NB-05

Capacity utilization grows at:

$$g_{\hat{\mu}_t^{CL}} = g_{Y_t^{CL}} - g_{Y_t^{p,CL}} = \Delta y_t - \hat{\theta}^{CL}(\omega_t,\phi_t) \cdot \Delta k_t^{CL}$$

This is a growth-rate identification only. The level of $\hat{\mu}^{CL}$ requires
one normalization assumption.

---

## 6.2 Pin-year normalization: μ̂^CL(1980) = 1.0

**Justification:** 1980 is the last year before the Chilean debt crisis of 1981–83.
Following Ffrench-Davis (2002), the economy reached full productive capacity
utilization at the peak of the credit-financed expansion of 1977–1981, immediately
before the sudden stop and the 14–15% GDP collapse of 1982–83. Pinning at
$\hat{\mu}^{CL}(1980) = 1.0$ is the natural classical normalization: the productive
frontier was fully activated at the cyclical peak preceding the crisis.

**Note:** This is a cyclical-peak normalization, in contrast to the US normalization
at a normal-operation level $\hat{\mu}^{US}(1948) = 0.80$ (Federal Reserve benchmark
for peacetime average capacity utilization). The two normalizations reflect different
empirical strategies: the US pin anchors to a known institutional benchmark; the
Chilean pin anchors to the pre-crisis peak, which is the theoretically meaningful
reference point for the shadow price interpretation.

**Reference:** Ffrench-Davis, R. (2002). *Economic Reforms in Chile: From Dictatorship
to Democracy*. University of Michigan Press. [Page reference assumed pending
confirmation.]

---

## 6.3 Forward and backward accumulation

```
μ̂^CL(1980) = 1.0                          [pin year]

Forward:  μ̂^CL(t) = μ̂^CL(t-1) × exp(g_μ(t))    for t = 1981, ..., 2024
Backward: μ̂^CL(t) = μ̂^CL(t+1) / exp(g_μ(t+1))   for t = 1979, ..., 1920
```

The accumulated series covers 1920–2024 (N=105), with the pre-1920 extrapolation
cut at the data boundary.

---

## 6.4 Expected results structure

**ISI period (1940–1972):**

- $\hat{\theta}^{CL} < 1$ expected (sub-Harrodian): productive capacity grows slower
  than capital. ISI-era over-accumulation of capital relative to productive frontier.
- $\hat{\mu}^{CL}$ should be below 1.0 but stable, oscillating around a Fordist plateau
  analogous to the US 0.73–0.76 range.

**Crisis period (1973–1982):**

- Sharp $\hat{\mu}^{CL}$ decline after 1973. The 1975 shock-therapy contraction
  should register as a severe underutilization trough.
- 1980: $\hat{\mu}^{CL} = 1.0$ by construction (pin year).
- 1982–83: sharp post-crisis collapse — the most severe single-period decline in the series.

**Neoliberal period (1983–2024):**

- $\hat{\theta}^{CL}$ may shift toward super-Harrodian territory ($> 1$) as import
  liberalization and wage suppression reshape the composition-distribution nexus.
- $\hat{\mu}^{CL}$ recovering but at structurally lower average than ISI, reflecting
  the persistent BoP constraint legacy and the different institutional composition
  of the neoliberal regime.

---

## 6.5 Pin-year sensitivity

Three alternatives reported in the appendix:

| Pin specification | ISI mean | Post-1982 mean | Interpretation |
|---|---|---|---|
| 1978 @ 0.95 | (compute) | (compute) | Conservative peak — pre-boom |
| 1979 @ 1.00 | (compute) | (compute) | One year before baseline |
| **1980 @ 1.00** | **(baseline)** | **(baseline)** | **Ffrench-Davis pre-crisis peak** |
| 1981 @ 1.00 | (compute) | (compute) | One year into boom extension |

The qualitative narrative should be robust across these alternatives. If the
ISI-period mean changes by more than 0.05 across alternatives, the pin-year
choice is material and must be discussed explicitly in the text.

---

## 6.6 Chapter/appendix mapping for Stage 2 results

**Chapter body — §2.8.2 Chilean Results:**

| Object | Content |
|--------|---------|
| Lead equation | Boxed $\hat{\theta}^{CL}(\omega_t,\phi_t) = \hat{\theta}_0 + \hat{\psi}\phi_t + \hat{\theta}_2\omega_tφ_t$ with parameter estimates |
| Kaldor premium | $\hat{\psi} - \hat{\theta}_0 = 2\hat{B}$: machinery vs. infrastructure elasticity differential |
| Harrodian surface | $\phi_H(\bar{\omega})$: composition share at which $\hat{\theta}^{CL}=1$ |
| Regime classification | Table: $\hat{\gamma}$, N in each regime, years in Regime 2 |
| Shadow price test | $|\hat{\alpha}_y^{(2)}| < |\hat{\alpha}_y^{(1)}|$: confirmed/not confirmed |
| LR linearity test | Bootstrap p-value |
| Figure: $\hat{\theta}^{CL}$ | Time series 1920–2024, color-coded by regime |
| Figure: $\hat{\mu}^{CL}$ | Time series 1920–2024, dashed at 1.0, pin year annotated |

**Appendix:**

| Object | Content |
|--------|---------|
| Unit root crosswalk | Full table: ADF, PP, KPSS, ZA for all variables |
| CV1 raw coefficients | $(A, B, C)$ with parameter recovery workings |
| Full loading matrices | $\hat{\alpha}^{(1)}$ and $\hat{\alpha}^{(2)}$ for all 4 equations |
| SSR surface plot | Grid search surface confirming global minimum |
| Bootstrap null distribution | LR bootstrap histogram with observed LR marked |
| Pin-year sensitivity | $\hat{\mu}^{CL}$ period means under 4 pin specifications |
| Cross-country comparison table | $\hat{\theta}^{US}$ vs $\hat{\theta}^{CL}$ period averages |

---

## 6.7 Cross-country comparison (anticipating the structural chapter)

The central cross-country contrast is:

| Object | US | Chile |
|--------|-----|-------|
| $\hat{\theta}$ specification | $\hat{\theta}^{US}(\omega_t) = 8.924 - 12.851\omega_t$ | $\hat{\theta}^{CL}(\omega_t,\phi_t) = \hat{\theta}_0 + \hat{\psi}\phi_t + \hat{\theta}_2\omega_t\phi_t$ |
| Conditioning variables | $\omega_t$ only (homogeneous capital) | $\omega_t$ and $\phi_t$ (heterogeneous capital + BoP) |
| Harrodian knife-edge | $\omega_H = 0.617$ (single point) | $\phi_H(\omega)$ (surface in $(\omega,\phi)$ space) |
| Pin year | 1948, $\hat{\mu}^{US} = 0.80$ (FRB benchmark) | 1980, $\hat{\mu}^{CL} = 1.0$ (pre-crisis peak) |
| Regime switch trigger | $\omega_t$ crosses $\omega_H$ | ECT_m crosses $\hat{\gamma}$ |
| Shadow price | None (closed economy) | $\lambda > 0$ when Regime 2 activated |

The BoP constraint introduces a second dimension into the transformation elasticity
that the US identification cannot detect. This is the chapter's theoretical
contribution for the peripheral case.

---

## 6.8 Notebook series summary

| NB | Purpose | Key output |
|----|---------|-----------|
| NB-01 | Why redesign | Architecture decision log |
| NB-02 | Unit root battery | `stage2_ur_crosswalk.csv` |
| NB-03 | ECT_m verification | Stationarity + regime structure confirmed |
| NB-04 | CLS estimation | `stage2_ssr_grid.csv`, `stage2_alpha_loadings.csv` |
| NB-05 | Parameter recovery | `stage2_structural_params.csv`, `stage2_theta_CL_series.csv` |
| NB-06 (this) | μ̂^CL and chapter mapping | `stage2_panel_with_mu_v2.csv` |

**Identification chain complete:**
$$\text{Stage 1 ECT}_m \xrightarrow{R_t = \mathbf{1}[\cdot > \hat{\gamma}]} \text{CLS-TVECM} \xrightarrow{(A,B,C)} (\hat{\theta}_0, \hat{\psi}, \hat{\theta}_2) \xrightarrow{\phi_t} \hat{\theta}^{CL}(\omega_t,\phi_t) \xrightarrow{\text{pin 1980}} \hat{\mu}^{CL}_t$$

---

*NB-06 | 2026-04-07 | Identification chain complete*
