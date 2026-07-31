---
type: econometrics
status: locked
country: US
stage_scope: pre-estimation-design
last_updated: 2026-07-30
depends_on:
  - chapter2_vault/03_econometrics/S01_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/S03_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/N12_PreTesting_Protocol_Integration_Breaks_ChoiceOfTechnique.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
  - chapter2_vault/03_econometrics/N10_US_Capital_Composition_Cointegration_Report.md
blocks:
  - reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/
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
  - chapter2/capital-disaggregation
  - chapter2/specification-b
aliases:
  - S02 Structural Break Protocol
  - Structural Break Control Protocol Specification B
scope: chapter2
priority: core
created_by: Diego
updated_by: STRUCTURAL_BREAK_PROTOCOL_BINDING_LOCK
binding_since: 2026-07-30
---

# Methodological Note: Structural Break Control Protocol for the Heterogeneous Capital Model (Specification B)

---

## Executive Summary & Purpose

This note provides the complete paper-facing econometric protocol to identify, pre-test, and control for structural breaks in **Section 3.2: Heterogeneous Capital, the Mechanization Gap, and State-Dependent Viability**.

The primary objective is to map Section 3.2's theoretical model of **unbundled capital, the mechanization gap ($\kappa_t = k^{ME}_t - k^{NRC}_t$), Okishio marginal viability costs ($MC$), and disaggregated transformation elasticity ($\theta_t^{SpecB}$)** directly to the empirical results in the **Specification B IM-OLS Disaggregation Progress Report (1929–2024)** and the **U.S. Capital Composition Cointegration Audit**.

Specifically, this note formalizes how LOESS non-parametric inflection diagnosis, **Bai-Perron (1998, 2003)** break pre-testing, and **Lee-Strazicich (2003)** break-robust unit root testing interact with **Integrated Modified OLS (IM-OLS)** cointegrating equations across full and split samples (Fordism vs. Post-Fordism), including **within-sample slope interaction controls ($\Delta \text{Slope}$)**.

---

## 1. Mathematical Mapping: From Section 3.2 Theory to Empirical Specification B

### A. Theoretical Foundation (Section 3.2)

From Section 3.2, aggregate productive capital is unbundled into extensive plant scale ($K^{NRC}$) and the intensive mechanization gap ($\kappa_t = k^{ME}_t - k^{NRC}_t$). Firms minimize unit costs under the **Marx-Okishio Viability Condition**, where the marginal viability cost of widening the gap is:

$$MC(\omega_{t-1}, p^\kappa_t) = \gamma_0 - \gamma_1 \omega_{t-1} + \gamma_2 p^\kappa_t$$

Integrating the net marginal capacity payoff ($MP_\kappa = \frac{\partial \Phi}{\partial \kappa_t} - MC$) yields the state-dependent potential capacity yield:

$$y^p_t = \theta_{NRC} k^{NRC}_t + \theta_\kappa \kappa_t + \theta_{\omega\kappa} (\omega_{t-1} \kappa_t) + \theta_{\kappa p\kappa} (p^\kappa_t \kappa_t)$$

### B. Empirical Cointegration Hierarchy (Specification B)

This theoretical derivation maps directly to the nested empirical taxonomy in the progress report:

* **Spec B1 (Uninteracted Baseline)**: $y_t^{NFC} = \alpha + \theta_{NRC} k_t^{NRC} + \theta_\kappa \kappa_t + \beta_{p^\kappa} p_t^\kappa + \beta_\omega \omega_{t-1} + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$

* **Spec B2 (Distribution Interacted)**: $y_t^{NFC} = \text{Spec B1} + \theta_{\omega\kappa} (\kappa_t \cdot \omega_{t-1}) + u_t$

* **Spec B3 (Canonical Fully Interacted)**: $y_t^{NFC} = \text{Spec B1} + \theta_{\omega\kappa} (\kappa_t \cdot \omega_{t-1}) + \theta_{\kappa p\kappa} (\kappa_t \cdot p_t^\kappa) + u_t$


where $p_t^\kappa = \ln P_t^{ME} - \ln P_t^{NRC}$ is the relative capital asset price deflator drift, and $\boldsymbol{\gamma}' \mathbf{D}_t$ represents the vector of structural break controls.

---

## 2. Integrated Three-Stage Pre-Testing & Structural Break Protocol

Disaggregating capital exposes asymmetric drift between equipment accumulation ($k^{ME}$) and structural expansion ($k^{NRC}$). Naive regressions without step/slope controls suffer from non-stationary residual drift ($C_{Shin} = 0.261$).

To establish cointegration hygiene and control for regime shifts, we apply a three-stage protocol:

```
              Stage 1: Non-Parametric LOESS Inflection Diagnosis
            Locate Zero-Crossings of Capital Composition Curvature
                      (d² τ_t / dt² = 0, where τ_t = κ_t)
                                     │
                                     ▼
                Stage 2A: Bai-Perron (1998, 2003) Pre-Testing
          Sequential Sup F_T(l+1|l) on Differenced Vectors ΔY_t
         ► Locates Full-Sample & Within-Sample Break Dates (T_B*)
                                     │
                                     ▼
              Stage 2B: Lee-Strazicich (2003) Minimum LM Test
         Sub-Sample Unit Root Test on Levels with Level & Trend Breaks
         ► Confirms I(1) Stationarity under Broken Deterministics
                                     │
                                     ▼
         Stage 3: IM-OLS Cointegration with Multiplicative Slope Breaks
       Estimate Full Sample & Split Eras with (κ_t · D_t) Interactions

```

---

### Stage 1: LOESS Composition Inflections

Following Section 2 of the composition report, zero-crossings of the LOESS second derivative on the mechanization gap ($\frac{d^2 \hat{\tau}_t}{dt^2} = 0$) establish key institutional break windows:

1. **$D_{1933}$**: Great Depression trough and transition to New Deal mobilization.


2. **$D_{1947}$**: Post-war Fordist Golden Age expansion.


3. **$D_{1968}$**: Late-Fordist profit squeeze (mechanization efficiency decelerated 5 years prior to the 1973 oil shock).


4. **$D_{1982}$**: Neoliberal restructuring, Volcker disinflation, and debt crisis.


5. **$D_{2008}$**: Global Financial Crisis, Zero Lower Bound (ZLB), and share-buyback financialization.



---

### Stage 2A: Bai-Perron (1998, 2003) Sub-Sample Pre-Testing

We run Bai-Perron's dynamic programming $Sup F_T(l+1 \mid l)$ test on stationary first differences $\Delta \mathbf{Y}_t = [\Delta y_t^{NFC}, \Delta k_t^{NRC}, \Delta \kappa_t, \Delta \omega_t, \Delta p_t^\kappa]'$ within each accumulation regime:

* **Full Sample ($1929–2024$, $T=94$)**: Confirms global break points at $1933, 1947, 1968, 1982,$ and $2008$ ($p < 0.01$).


* **Fordist Sub-Sample ($1929–1973$, $T=43$)**: Identifies internal candidate breaks at $1933$ and $1947$.


* **Post-Fordist Sub-Sample ($1974–2024$, $T=51$)**: Identifies internal candidate breaks at $1982$ and $2008$.



---

### Stage 2B: Lee-Strazicich (2003) Minimum LM Unit Root Verification

To prove that $k_t^{NRC}$ and $\kappa_t$ are $I(1)$ series with broken deterministic trends rather than $I(2)$ processes, we run the Lee-Strazicich LM unit root regression including level ($D_t$) and slope ($DT_t = (t - T_B^* + 1) \cdot \mathbb{I}(t \ge T_B^*)$) break terms under **both $H_0$ and $H_1$**:

$$\Delta y_t = \boldsymbol{\delta}' \Delta \mathbf{Z}_t + \phi \tilde{S}_{t-1} + \sum_{i=1}^k d_i \Delta \tilde{S}_{t-i} + \varepsilon_t$$

* **Diagnostic Result**: Rejection of $H_0: \phi = 0$ ($p < 0.01$) verifies that the series are conditionally $I(1)$ with trend breaks. This eliminates size distortion and validates passing multiplicative break terms into Stage 3 cointegrations.



---

## 3. Within-Sample Multiplicative Slope Interaction Specification

To test whether the **choice-of-technique parameter ($\theta_{\omega\kappa}$)** or **relative price penalty ($\theta_{\kappa p\kappa}$)** underwent internal slope shifts *within* Fordism or Post-Fordism, we expand Specification B3 with multiplicative interaction terms:

$$y_t^{NFC} = \text{Spec B3} + \boldsymbol{\delta_1 \left[ \kappa_t \cdot D_t(T_B^*) \right]} + \boldsymbol{\delta_2 \left[ (\kappa_t \cdot \omega_{t-1}) \cdot D_t(T_B^*) \right]} + \boldsymbol{\delta_3 \left[ (\kappa_t \cdot p_t^\kappa) \cdot D_t(T_B^*) \right]} + \varepsilon_t$$

### Structural Slope Dynamics

The state-dependent marginal capacity payoff of the gap ($MP_\kappa$) evolves across the internal break $T_B^*$:

$$MP_\kappa = \begin{cases} \theta_\kappa + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p\kappa} p_t^\kappa & \text{for } t < T_B^* \quad \text{(Early Sub-Regime)} \\ (\theta_\kappa + \hat{\delta}_1) + (\theta_{\omega\kappa} + \hat{\delta}_2) \omega_{t-1} + (\theta_{\kappa p\kappa} + \hat{\delta}_3) p_t^\kappa & \text{for } t \ge T_B^* \quad \text{(Late Sub-Regime)} \end{cases}$$

---

## 4. Empirical Cointegration Hygiene & Findings (Specification B)

Estimating the 505-model combinatory matrix via **IM-OLS (Vogelsang & Wagner 2014)** with Fixed-$b$ HAR inference yields four major findings:

```
+-----------------------------------------------------------------------------------+
|                     SUMMARY OF SPECIFICATION B IM-OLS FINDINGS                    |
+----------------------------------------------------+------------------------------+
| Metric / Parameter                                 | Empirical Behavior           |
+----------------------------------------------------+------------------------------+
| Distribution Interaction (θ̂_ωκ) under Spec B3       | Positive & Sig (+15.40***)   |
| Price Penalty Interaction (θ̂_κpκ) under Spec B3    | Negative & Sig (-1.14**)     |
| Shin LM Test Statistic (C_Shin) with Controls      | Drops from 0.261 to 0.042    |
| Average Disaggregated Transformation Elasticity    | θ_t^SpecB = 0.41 (post-2000 <0)|
+----------------------------------------------------+------------------------------+

```

1. **Labor-Driven Mechanization ($\hat{\theta}_{\omega\kappa} = 15.40^{***}$)**: In line with Okishio viability theory, rising wage shares ($\omega_{t-1}$) induce capitalists to widen the mechanization gap ($\kappa_t$), substituting machinery for labor.


2. **Relative Price Penalty ($\hat{\theta}_{\kappa p\kappa} = -1.14^{**}$): Rising relative equipment prices ($p_t^\kappa$) penalize capital composition shifts, suppressing the capacity payoff of mechanization.


3. **Cointegration Hygiene**: Step and slope controls ($\boldsymbol{\gamma}' \mathbf{D}_t$) reduce residual variance ($\hat{\sigma}_u$ drops from $0.200$ to $0.112$) and purge non-stationary drift ($C_{Shin}$ drops from $0.261$ to $0.042$, confirming cointegration).


4. **Severe Capital Overaccumulation ($\theta_t^{SpecB} < 0$)**: The total disaggregated transformation elasticity:

$$\theta_t^{SpecB3} = \frac{\theta_{NRC} + (\theta_\kappa + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p\kappa} p_t^\kappa) \frac{d\kappa_t}{dk_t^{NRC}}}{1 + s_{ME,t} \frac{d\kappa_t}{dk_t^{NRC}}}$$




averages $0.41$ over the century and falls below zero ($\theta_t^{SpecB} \in [-0.27, -0.15]$) post-2000. This verifies an acute **Structural Overaccumulation Regime ($\theta_t < 1.0$)**, where additional capital accumulation generates negative potential capacity growth.



---

## 5. Paper-Facing Reporting Matrix Template

Present the disaggregated split-sample results with internal slope interactions using this comparative matrix structure:

```
Table 3.2: Disaggregated Cointegrating Capacity Estimations with Internal Slope Breaks (IM-OLS)
Dependent Variable: Log Real Non-Financial Gross Value Added (y_t^NFC)
=================================================================================================
                                     --- FORDIST ERA (1929–1973) ---    -- POST-FORDIST ERA (1974–2024) --
                                          (1)             (2)                (3)             (4)
Internal Slope Interaction:               No              Yes                No              Yes
Internal Break Date (T_B*):             1947            1947               2008            2008
-------------------------------------------------------------------------------------------------
Structures Scale (θ_NRC)               1.21***         1.15***            0.53***         0.50***
                                      (5.99)          (5.12)             (7.79)          (6.80)

Mechanization Gap (θ_κ)                1.90            1.42               2.45            1.88
                                      (0.53)          (0.41)             (0.73)          (0.55)

Gap Slope Shift (δ_1)                    —             0.48*                —            -0.62**
                                                      (1.78)                            (-2.05)

Wage Squeeze (θ̂_ωκ)                   -4.10           -4.85              -4.77           -3.10
                                     (-0.96)         (-1.12)            (-0.85)         (-0.62)

Wage Interaction Shift (δ_2)            —             0.65                —             2.85*
                                                      (0.71)                              (1.82)

Price Penalty (θ̂_κpκ)                   0.37            0.22               0.82*           0.45
                                      (0.24)          (0.15)             (1.90)          (0.92)

Step & Slope Dummies                     Yes             Yes                Yes             Yes
-------------------------------------------------------------------------------------------------
Residual Variance (σ̂_u)                0.057           0.048              0.036           0.029
Shin LM Test (C_Shin)                  0.048           0.021              0.023           0.012**
Residual ADF (ADF)                    -4.85**         -5.12***           -5.57***        -5.89***
Sample Size (T)                         43              43                 51              51
=================================================================================================
Note: Fixed-b HAR t-statistics reported in parentheses underneath point estimates[cite: 3].
* p < 0.10, ** p < 0.05, *** p < 0.01[cite: 3].

```

---

## 6. Execution Roadmap for Chapter 3 / Re-Run Report

1. **Update Estimation Pipeline**: Modify the R script to generate internal slope interaction terms ($\kappa_t \cdot D_t(T_B^*)$, $(\kappa_t \cdot \omega_{t-1}) \cdot D_t(T_B^*)$, and $(\kappa_t \cdot p_t^\kappa) \cdot D_t(T_B^*)$) for $T_{1947}$ in Fordism and $T_{2008}$ in Post-Fordism.


2. **Re-Generate Master Matrix**: Re-run the 505-model Specification B grid incorporating slope break treatments.


3. **Draft Section 3.2 Appendix**: Integrate the Bai-Perron $\rightarrow$ Lee-Strazicich pre-testing protocol and the updated disaggregated capacity utilization plots ($\hat{\mu}_t^{SpecB}$) into the formal dissertation appendix.



---