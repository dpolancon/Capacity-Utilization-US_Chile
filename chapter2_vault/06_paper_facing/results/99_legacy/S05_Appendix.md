---
type: appendix
status: locked
country: US
stage_scope: robustness-diagnostics
last_updated: 2026-07-31
depends_on:
  - "[[S04_StructuralBreak_locked decisions]]"
  - "[[S01_StructuralBreak_Protocol]]"
  - "[[S02_StructuralBreak_Protocol]]"
  - "[[E10V_IMOLS_CPR_Active_Estimator_Lock]]"
  - "[[00E_Chapter2_PaperFacing_Constitution]]"
  - "[[00S_Chapter2_Symbology_and_Notation_Lock]]"
blocks:
  - reports/US_Baseline_IMOLS_Capital_Aggregation_Report/
  - reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/
layer: appendix
role: robustness-documentation
stage: post-estimation
subtype: permutation-grid
tags:
  - chapter2/appendix
  - chapter2/robustness
  - chapter2/permutations
  - chapter2/imols
  - chapter2/model-selection
aliases:
  - Appendix C Permutation
scope: chapter2
priority: core
created_by: Diego
updated_by: APPENDIX_LOCK
binding_since: 2026-07-31
---

# Appendix C: Permutation Space, Model Selection, and Robustness Diagnostics

## 1. Combinatorial Permutation Design & Dual-Criterion Adjudication
To guarantee that the structural break and interaction effects reported in the main text are robust and theoretically admissible, we executed a systematic $2^3 = 8$ (Spec A) and $2^4 = 16$ (Spec B) combinatorial grid search across sub-sample windows under **Regime B (Initial-State Centering)**.

Model selection enforces a **Dual-Criterion Adjudication Standard**:
1. **Theoretical Hypothesis Validation**: Preserves the negative sign and statistical significance of the core theoretical mechanisms ($\theta_1 < 0$ in Spec A profit squeeze; $\theta_{\omega\kappa} < 0$ in Spec B mechanization choice).
2. **Econometric & Cointegration Hygiene**: Condition Number $\text{CN} \le 100$, Shin LM stationarity $C_{\text{Shin}} < 0.095$, and Fixed-$b$ HAR joint Wald test $p < 0.05$.

Where multi-way slope breaks induce extreme collinearity ($\text{CN} > 100$) or fail to achieve statistical significance ($|t| < 1.96$), they are converted to additive deterministic step controls ($D_t$).

---

## 2. Specification A $2^3 = 8$ Combinatorial Decision Grid (Regime B Initial-State Centered)

| Model ID | $D_t^*$ | $\theta_{K,\text{brk}}$ | $\theta_{\omega,\text{brk}}$ | $\theta_{\omega K,\text{brk}}$ | CN | $\hat{\sigma}_u$ | Shin LM ($C_{\text{Shin}}$) | Joint Wald $F$ ($p$) | Adjudication Verdict |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| **<u>Fordist Era (1929--1973; $T_B^* = 1947$)</u>** | | | | | | | | | |
| **SpecA-0** | Yes | No | No | No | 13.63 | 0.0715 | 0.0381 | 3.78 ($p=0.061$) | Baseline (Level Only) |
| **SpecA-1** | Yes | **Yes** | No | No | **46.02** | **0.0591** | **0.0255** | **7.32 ($p=0.011$)** | **RETAIN (Parsimonious Model)** |
| **SpecA-2** | Yes | No | Yes | No | 14.04 | 0.0668 | 0.0460 | 6.52 ($p=0.016$) | Convert to Level |
| **SpecA-3** | Yes | Yes | Yes | No | 46.89 | 0.0580 | 0.0372 | 6.12 ($p=0.020$) | Retain |
| **SpecA-4** | Yes | No | No | Yes | 29.78 | 0.0625 | 0.0391 | 3.26 ($p=0.053$) | Convert to Level |
| **SpecA-5** | Yes | Yes | No | Yes | 48.72 | 0.0580 | 0.0463 | 4.29 ($p=0.025$) | Retain |
| **SpecA-6** | Yes | No | Yes | Yes | 31.97 | 0.0605 | 0.0487 | 2.56 ($p=0.097$) | Convert to Level |
| **SpecA-7** | Yes | Yes | Yes | Yes | 50.60 | 0.0570 | 0.0489 | 3.15 ($p=0.061$) | Retain |
| **<u>Post-Fordist Era (1974--2024; $T_B^* = 2008$)</u>** | | | | | | | | | |
| **SpecA-0** | Yes | No | No | No | 32.25 | 0.0520 | 0.1567$^{***}$ | 1.63 ($p=0.210$) | Disqualified (Non-stationary) |
| **SpecA-1** | Yes | **Yes** | No | No | **74.48** | **0.0436** | **0.0276** | **0.83 ($p=0.368$)** | **DROP / Convert to Level** |
| **SpecA-2** | Yes | No | Yes | No | 42.39 | 0.0523 | 0.1585$^{***}$ | 1.21 ($p=0.279$) | Disqualified (Non-stationary) |
| **SpecA-3** | Yes | Yes | Yes | No | 85.03 | 0.0438 | 0.0348 | 1.10 ($p=0.303$) | Drop |
| **SpecA-4** | Yes | No | No | Yes | 47.50 | 0.0521 | 0.1666$^{***}$ | 1.00 ($p=0.379$) | Disqualified (Non-stationary) |
| **SpecA-5** | Yes | Yes | No | Yes | 79.13 | 0.0438 | 0.0350 | 0.53 ($p=0.593$) | Drop |
| **SpecA-6** | Yes | No | Yes | Yes | 83.86 | 0.0484 | 0.1170$^{*}$ | 4.75 ($p=0.015$) | Disqualified (Non-stationary) |
| **SpecA-7** | Yes | Yes | Yes | Yes | 358.99 | 0.0441 | 0.0358 | 0.66 ($p=0.524$) | Collinear ($\text{CN} > 100$) |

---

## 3. Specification B $2^4 = 16$ Combinatorial Decision Grid (Regime B Initial-State Centered)

| Model ID | $\theta_{\text{NRC},\text{brk}}$ | $\theta_{\kappa,\text{brk}}$ | $\theta_{\omega\kappa,\text{brk}}$ | $\theta_{\kappa p^\kappa,\text{brk}}$ | CN | $\hat{\sigma}_u$ | Shin LM ($C_{\text{Shin}}$) | Joint Wald $F$ ($p$) | Adjudication Verdict |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|---|
| **<u>Fordist Era (1929--1973; $T_B^* = 1947$)</u>** | | | | | | | | | |
| **SpecB-0** | No | No | No | No | **90.40** | **0.0446** | **0.0292** | **0.52 ($p=0.478$)** | **BASELINE (Level Only)** |
| **SpecB-1** | Yes | No | No | No | 98.04 | 0.0444 | 0.0301 | 0.34 ($p=0.568$) | Convert to Level |
| **SpecB-2** to **SpecB-15** | — | — | — | — | $>100$ | — | — | — | **Collinear ($\text{CN} > 100$)** |
| **<u>Post-Fordist Era (1974--2024; $T_B^* = 2008$)</u>** | | | | | | | | | |
| **SpecB-0** | No | No | No | No | 45.87 | 0.0341 | 0.0229 | 3.82 ($p=0.060$) | Baseline (Level Only) |
| **SpecB-2** | No | Yes | No | No | 48.46 | 0.0344 | 0.0231 | 3.50 ($p=0.071$) | Convert to Level |
| **SpecB-4** | No | No | Yes | No | 49.60 | 0.0334 | 0.0223 | 2.43 ($p=0.105$) | Convert to Level |
| **SpecB-6** | No | **Yes** | **Yes** | No | **82.48** | **0.0277** | **0.0154** | **7.01 ($p=0.0034$)** | **RETAIN (Parsimonious Model)** |
| **SpecB-8** | No | No | No | Yes | 55.40 | 0.0345 | 0.0260 | 4.04 ($p=0.053$) | Convert to Level |
| **All Other SpecB Models** | — | — | — | — | $>100$ | — | — | — | **Collinear ($\text{CN} > 100$)** |

---

## 4. Key Parameter Robustness Summary

| Parameter / Specification | Sub-Sample | Parsimonious Estimate | Fixed-$b$ HAR $t$-stat | Shin LM $C_{\text{Shin}}$ | Theoretical Hypothesis Validation |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Spec A: Profit Squeeze ($\theta_1$)** | Fordism ($T_{1947}^*$) | **$-3.45^{***}$** | **-2.71** | 0.0255 | **Validated ($\theta_1 < 0, p < 0.01$)** |
| **Spec A: Capital Scale Shift ($\theta_{K,\text{brk}}$)** | Fordism ($T_{1947}^*$) | **$-1.15^{***}$** | **-2.80** | 0.0255 | Elasticity halves post-1947 ($2.01 \to 0.86$) |
| **Spec B: Mechanization Choice ($\theta_{\omega\kappa}$)** | Post-Fordism ($T_{2008}^*$)| **$-46.56^{***}$**| **-3.74** | 0.0154 | **Validated ($\theta_{\omega\kappa} < 0, p < 0.001$)** |
| **Spec B: Wage Interaction Shift ($\theta_{\omega\kappa,\text{brk}}$)**| Post-Fordism ($T_{2008}^*$)| **$+63.94^{***}$**| **3.36** | 0.0154 | Structural shift post-2008 crisis ($F = 7.01, p = 0.0034$) |