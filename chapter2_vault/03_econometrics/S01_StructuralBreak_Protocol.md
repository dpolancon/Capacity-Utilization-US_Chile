---
type: econometrics
status: locked
country: US
stage_scope: pre-estimation-design
last_updated: 2026-07-30
depends_on:
  - chapter2_vault/03_econometrics/N12_PreTesting_Protocol_Integration_Breaks_ChoiceOfTechnique.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md
  - chapter2_vault/03_econometrics/S03_StructuralBreak_Protocol.md
blocks:
  - reports/US_Baseline_IMOLS_Capital_Aggregation_Report/
external_dependency: "C:/ReposGitHub/LeeStrazicichUnitRoot"
layer: econometrics
role: binding-protocol
stage: pre-estimation-design
subtype: structural_break_protocol
tags:
  - chapter2/econometrics
  - chapter2/structural-breaks
  - chapter2/pre-testing
  - chapter2/bai-perron
  - chapter2/lee-strazicich
  - chapter2/imols
  - chapter2/specification-a
aliases:
  - S01 Structural Break Protocol
  - Slope Structural Break Protocol Specification A
scope: chapter2
priority: core
created_by: Diego
updated_by: STRUCTURAL_BREAK_PROTOCOL_BINDING_LOCK
binding_since: 2026-07-30
---

# Methodological Note: Protocol for Identifying Slope Structural Breaks Within Split Samples (Fordism vs. Post-Fordism)

## Executive Summary & Objectives

This note establishes the paper-facing econometric protocol to re-run and re-do the empirical report (Specification A & Specification B), specifically extending structural break identification beyond pure level shifts ($D_t$) to detect **slope structural breaks ($\Delta \text{Slope}$)** _within_ the sub-sample windows of **Fordism (1929–1973 / 1950–1973)** and **Post-Fordism (1974–2024)**.

While setting $T_{1974}$ as a fixed macroeconomic boundary splits the broader Regulationist accumulation regimes, each regime contains internal institutional shifts (e.g., WWII mobilization within Fordism; the 1982 debt crisis, 1990s neoliberal consolidation, or 2008 GFC within Post-Fordism). This protocol formalizes how to test whether the **capacity-generating elasticity parameter ($\beta_{Kcap}$)** and the **state-dependent profit squeeze parameter ($\theta_1$)** experience internal slope shifts within each regime.

## 1. Structural Model & Within-Sample Interaction Mathematics

### A. General Multiplicative Interaction Specification (Within Sub-Sample $S$)

For a given sub-sample $S \in \{\text{Fordism}, \text{Post-Fordism}\}$, let $T_B^* \in S$ be an internally identified structural break date. The Stage 1 cointegrating equation is specified as:

$$y_t^{NFC} = \alpha_0 + \gamma_1 D_t(T_B^*) + \beta_{Kcap} k_t^{cap} + \boldsymbol{\delta_1 \left[ k_t^{cap} \cdot D_t(T_B^*) \right]} + \phi_\omega \omega_{t-1} + \theta_1 (k_t^{cap} \cdot \omega_{t-1}) + \boldsymbol{\delta_2 \left[ k_t^{cap} \cdot \omega_{t-1} \cdot D_t(T_B^*) \right]} + \varepsilon_t$$

where:

- $D_t(T_B^*) = \mathbb{I}(t \ge T_B^*)$ is the internal regime step dummy.
    
- $k_t^{cap} \cdot D_t(T_B^*)$ tests for an internal slope break in baseline capital elasticity ($\Delta \hat{\beta}_{Kcap} = \delta_1$).
    
- $k_t^{cap} \cdot \omega_{t-1} \cdot D_t(T_B^*)$ tests for an internal slope break in the state-dependent profit squeeze ($\Delta \hat{\theta}_1 = \delta_2$).
    

### B. Regime Elasticity Dynamics

Within sub-sample $S$, the marginal transformation elasticity $\theta_t = \frac{\partial y_t^p}{\partial k_t^{cap}}$ transitions dynamically across $T_B^*$:

$$\theta_t = \begin{cases} \hat{\beta}_{Kcap} + \hat{\theta}_1 \omega_{t-1} & \text{for } t < T_B^* \quad \text{(Early Sub-Regime)} \\ (\hat{\beta}_{Kcap} + \hat{\delta}_1) + (\hat{\theta}_1 + \hat{\delta}_2) \omega_{t-1} & \text{for } t \ge T_B^* \quad \text{(Late Sub-Regime)} \end{cases}$$

- **Hypothesis Test for Slope Stability**: $H_0: \delta_1 = 0 \text{ AND } \delta_2 = 0$. If rejected, parameter constancy fails within the sub-sample, requiring internal slope controls or finer sub-window reporting.
    

## 2. Integrated Pre-Testing Protocol for Internal Slope Breaks

To ensure internal break selection is statistically rigorous rather than ad-hoc, execute this sequential three-step procedure on each sub-sample separately:

```
                  Step 1: Within-Sample Bai-Perron (1998, 2003)
                Run Sup F_T(l+1|l) on First Differences ΔY_t within S
            ► Locates Candidate Internal Slope Break Dates (T_B*)
                                     │
                                     ▼
                Step 2: Within-Sample Lee-Strazicich (2003)
            LM Unit Root Test on Sub-Sample Levels with Internal T_B*
            ► Verifies I(1) Stationarity under Broken Deterministics
                                     │
                                     ▼
                  Step 3: IM-OLS / DOLS Multiplicative Test
              Estimate Equations with Interaction Terms (δ_1, δ_2)
            ► Evaluate Parameter Stability via Fixed-b HAR Inference
```

### Step 1: Sub-Sample Bai-Perron Pre-Testing

Run Bai-Perron's sequential break test on the stationary first-differenced vectors $\Delta \mathbf{Y}_t = [\Delta y_t^{NFC}, \Delta k_t^{cap}, \Delta \omega_t]'$ within each split sample:

- **Fordist Window ($1929–1973$, $T=43$)**: Trimming parameter $\epsilon = 0.20$. Evaluate candidate slope breaks at $1933$ (New Deal plant mobilization) and $1947$ (Post-War conversion).
    
- **Post-Fordist Window ($1974–2024$, $T=51$)**: Trimming parameter $\epsilon = 0.15$. Evaluate candidate slope breaks at $1982$ (Volcker disinflation/debt crisis), $2000$ (Dot-Com crash), and $2008$ (Great Recession).
    

### Step 2: Sub-Sample Lee-Strazicich (2003) LM Verification

Apply the Lee-Strazicich Minimum LM unit root test to $k_t^{cap}$ within each sub-sample using the candidate internal dates $T_B^*$:

$$\Delta y_t = \boldsymbol{\delta}' \Delta \mathbf{Z}_t + \phi \tilde{S}_{t-1} + \sum_{i=1}^k d_i \Delta \tilde{S}_{t-i} + \varepsilon_t$$

where $\mathbf{Z}_t$ includes both level step terms ($D_t$) and trend slope break terms ($DT_t = (t - T_B^* + 1) \cdot \mathbb{I}(t \ge T_B^*)$).

- **Diagnostic Objective**: Rejection of $H_0: \phi = 0$ confirms $k_t^{cap}$ is conditionally $I(1)$ with internal trend breaks, verifying that Stage 3 interactions will not yield spurious cointegration statistics.
    

### Step 3: IM-OLS / DOLS Multiplicative Cointegration

Estimate the full multiplicative interaction model via Integrated Modified OLS (IM-OLS) and Dynamic OLS (DOLS) with leads and lags ($q=1, \ell=1$).

- **Variance Reduction Check**: Confirm whether adding slope interactions reduces residual variance ($\hat{\sigma}_u$) relative to the progress report baselines ($\hat{\sigma}_{u,\text{Ford}} = 0.158$, $\hat{\sigma}_{u,\text{Post}} = 0.184$).
    
- **Cointegration Test Verification**: Monitor Shin LM ($C_{Shin}$) and Residual ADF statistics to confirm cointegration $H_0$ holds.
    

## 3. Execution Decision Matrix for Report Re-Run

```
                                  [Run Internal Pre-Testing on Sub-Sample S]
                                                       │
                                                       ▼
                                      Are δ_1 or δ_2 Statistically Significant?
                                      (Fixed-b HAR t-stat, p < 0.05)
                                                       │
                           ┌───────────────────────────┴───────────────────────────┐
                           ▼                                                       ▼
                        [YES]                                                   [NO]
                           │                                                       │
                           ▼                                                       ▼
         [Retain Multiplicative Interaction]                      [Retain Additive Step Control]
   Parameter elasticity shifted internally.                 Parameter elasticity is structurally invariant.
   Report dual sub-regime elasticities (θ_early vs θ_late).  Use level step dummies D_t(T_B*) strictly for 
                                                            variance hygiene (σ̂_u reduction).
```

## 4. Paper-Facing Re-Run Reporting Template

When updating the report appendices and Chapter 2 text, present the internal slope break diagnostics using this comparative matrix structure:

```
Table X: Sub-Sample Internal Slope Break Cointegration Matrix (IM-OLS / DOLS)
Dependent Variable: Log Real Non-Financial Gross Value Added (y_t^NFC)
=================================================================================================
                                     --- FORDIST ERA (1929–1973) ---    -- POST-FORDIST ERA (1974–2024) --
                                          (1)             (2)                (3)             (4)
Internal Slope Interaction:               No              Yes                No              Yes
Internal Break Date (T_B*):             1947            1947               2008            2008
-------------------------------------------------------------------------------------------------
Capital Stock (β_Kcap)                12.61***        12.45***           14.57***        14.82***
                                     (140.32)        (112.10)           (172.69)        (135.40)

Capital Slope Shift (δ_1)                —             0.32*                —            -0.51**
                                                      (1.85)                            (-2.15)

Wage Share (ϕ_ω)                       0.89***         0.82***            0.67***         0.71***
                                      (13.82)         (11.40)            (18.64)         (14.20)

Interaction Squeeze (θ̂₁)             -8.84***        -9.12***            3.76            2.10
                                      (-2.99)         (-3.15)             (1.11)          (0.85)

Interaction Slope Shift (δ_2)            —             0.54                 —             2.45*
                                                      (0.62)                              (1.78)

Step Dummies (D_t)                       Yes             Yes                Yes             Yes
-------------------------------------------------------------------------------------------------
Residual Variance (σ̂_u)                0.158           0.142              0.184           0.151
Shin LM Test (C_Shin)                  0.130**         0.091              3.560***        0.112**
Residual ADF (ADF)                    -3.350          -3.820*            -2.040          -3.610**
Sample Size (T)                         43              43                 51              51
=================================================================================================
Note: Fixed-b HAR t-statistics reported in parentheses underneath point estimates.
* p < 0.10, ** p < 0.05, *** p < 0.01.
```

## 5. Protocol Execution Steps

1. **Script Update**: Modify the R estimation script to compute interaction terms $k_t^{cap} \cdot D_t(T_B^*)$ and $k_t^{cap} \cdot \omega_{t-1} \cdot D_t(T_B^*)$ for $T_{1947}$ in Fordism and $T_{2008}$ in Post-Fordism.
    
2. **Re-Run Matrix**: Re-generate the 168-model master comparative matrix in the progress report incorporating slope break treatments[cite: 1].
    
3. **Reconstruct Capacity Utilization**: Re-estimate $Y_t^p$ and $\hat{\mu}_t$ under the slope-adjusted parameters to evaluate whether capacity utilization level anchors at $\mu_{1973} = 1.00$ remain stable[cite: 1].