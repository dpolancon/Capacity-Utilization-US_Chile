---
type: econometrics
status: locked
country: US_CL
stage_scope: pre-estimation-design
last_updated: 2026-07-30
depends_on:
  - chapter2_vault/03_econometrics/N12_PreTesting_Protocol_Integration_Breaks_ChoiceOfTechnique.md
blocks:
  - chapter2_vault/03_econometrics/S01_StructuralBreak_Protocol.md
  - chapter2_vault/03_econometrics/S02_StructuralBreak_Protocol.md
  - reports/US_Baseline_IMOLS_Capital_Aggregation_Report/
  - reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/
  - codes/CL_S3*_*.R
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
  - chapter2/dols
  - chapter2/imols
aliases:
  - S03 Structural Break Protocol
  - Bai-Perron Lee-Strazicich Pre-Testing Protocol
  - Structural Break Interaction Specifications
scope: chapter2
priority: core
created_by: Diego
updated_by: STRUCTURAL_BREAK_PROTOCOL_BINDING_LOCK
binding_since: 2026-07-30
---

# Note: Structural Break Interaction Specifications & Pre-Testing Protocol in Cointegrating Vectors

## 1. Mathematical Specifications

To test whether a structural break $T_B$ alters the **baseline deterministic trend** versus the **structural elasticity ($\beta_1$)**, we expand the Stage 1 import requirement equation using both additive and multiplicative break terms.

### A. Pure Level/Trend Shift (Additive / Baseline Shift)

Models a shift in the intercept or steady-state growth path while assuming the long-run structural import elasticity ($\beta_1$) remains constant across regimes:

$$m_t = \beta_0 + \gamma_1 D_t(T_B) + \gamma_2 DT_t(T_B) + \beta_1 k^{ME}_t + \beta_2 s_t + \beta_3 r_t + \sum_{j=-q}^{q} \boldsymbol{\theta}_j' \Delta \mathbf{X}_{t-j} + u_t$$

- $D_t(T_B) = \mathbb{I}(t \ge T_B)$: Step dummy (Level shift).
    
- $DT_t(T_B) = (t - T_B + 1) \cdot \mathbb{I}(t \ge T_B)$: Trend-break dummy (Slope shift in deterministic trend).
    

### B. Structural Elasticity Switch (Multiplicative / Parameter Shift)

To test whether a policy change (e.g., Chile’s post-1974 trade liberalization) permanently altered the **technological import intensity per unit of capital stock**, interact the machinery stock $k^{ME}_t$ directly with the regime dummy:

$$m_t = \beta_0 + \gamma_1 D_t(T_B) + \beta_1 k^{ME}_t + \boldsymbol{\delta_1 \left[ k^{ME}_t \cdot D_t(T_B) \right]} + \beta_2 s_t + \beta_3 r_t + \sum_{j=-q}^{q} \boldsymbol{\theta}_j' \Delta \mathbf{X}_{t-j} + u_t$$

- **Pre-Break Elasticity ($t < T_B$):** $\hat{\beta}_1$
    
- **Post-Break Elasticity ($t \ge T_B$):** $\hat{\beta}_1 + \hat{\delta}_1$
    
- **Hypothesis Test:** $H_0: \delta_1 = 0$ (No structural shift in technological import intensity).
    

## 2. Theoretical Literature & Pre-Testing Framework: Bai-Perron vs. Lee-Strazicich

When modeling structural breaks in macro-time-series cointegration, selecting break dates endogenous to the estimation avoids data-mining biases. However, the choice between **Bai & Perron (1998, 2003)** and **Lee & Strazicich (2003)** rests on a fundamental distinction regarding the **stationarity of the series under testing**.

### A. The Bai-Perron (1998, 2003) Paradigm: Pure Structural Breaks in Stationary / Differenced Regressors

Bai & Perron (BP) developed a comprehensive framework for testing multiple structural breaks in linear regression models estimated via least squares:

$$y_t = \mathbf{x}_t' \boldsymbol{\beta} + \mathbf{z}_t' \boldsymbol{\delta}_j + u_t, \quad t = T_{j-1} + 1, \dots, T_j \quad (j = 1, \dots, m+1)$$

- **Core Econometric Assumption:** The regressors $\mathbf{x}_t$ and $\mathbf{z}_t$ must be **stationary $I(0)$ variables** or stationary first-differences ($\Delta y_t$). BP theory breaks down if applied directly to non-stationary $I(1)$ levels without appropriate cointegration structure.
    
- **Testing Engine:** BP utilizes dynamic programming to minimize the sum of squared residuals ($SSR$) across all possible partition combinations $(T_1, \dots, T_m)$ with a trimming parameter $\epsilon$ (typically $0.15$). It sequentially evaluates:
    
    1. $Sup F_T(k)$: Test of 0 versus $k$ globally optimal structural breaks.
        
    2. $Double Maximum Tests (UD_{max}, WD_{max})$: Test of 0 versus an unknown number of breaks $m \le M$.
        
    3. $Sup F_T(l+1 \mid l)$: Sequential test of $l$ versus $l+1$ structural breaks.
        
- **Application in the Protocol:** Apply Bai-Perron to the **stationary growth rate series ($\Delta k^{ME}_t$)** or the **first-differenced vector ($\Delta \mathbf{Y}_t$)**. It identifies structural acceleration/deceleration regimes (inflection points in levels) purely based on parameter shifts in the short-run dynamics.
    

### B. The Lee-Strazicich (2003) Paradigm: Break-Robust Unit Root Testing

While Bai-Perron identifies break dates assuming stationarity, Lee & Strazicich (LS) address the unit root problem when $k^{ME}_t$ exhibits pseudo-$I(2)$ persistence due to broken deterministic trends.

- **Core Econometric Innovation:** Traditional tests like Zivot & Andrews (1992) or Lumsdaine & Papell (1997) include break dummies _only under the alternative hypothesis_ ($H_1: I(0)$ with a break). If the true data-generating process is an $I(1)$ unit root _with a structural break_, ZA/LP suffer from severe size distortions and spurious rejections of the unit root null.
    
- **The LS Minimum LM Engine:** LS construct an LM test statistic derived from a Data-Generating Process that includes structural breaks under **both $H_0$ and $H_1$**:
    

$$\Delta y_t = \boldsymbol{\delta}' \Delta \mathbf{Z}_t + \phi \tilde{S}_{t-1} + \sum_{i=1}^k d_i \Delta \tilde{S}_{t-i} + \varepsilon_t$$

Where $\tilde{S}_t = y_t - \tilde{\psi}_y - \tilde{\boldsymbol{\delta}}' \mathbf{Z}_t$ is the LM detrended variable.

- **Key Result:** A rejection of $H_0$ under the LS Minimum LM test unambiguously proves that the series is **$I(1)$ with structural breaks** (or trend-stationary $I(0)$ with breaks), eliminating spurious $I(2)$ classifications caused by regime shifts (e.g., Chile 1973/1974 or 1982).
    

### C. Integrated Two-Stage Pre-Testing Protocol

To establish a methodologically bulletproof justification for committee presentation, combine both approaches into a sequential pre-testing routine:

```
                      Stage 1A: Bai-Perron (1998, 2003)
            Run BP sequential Sup F_T(l+1|l) on Δk^ME_t
         ► Locates break dates T_B based on growth-rate shifts
                                     │
                                     ▼
                     Stage 1B: Lee-Strazicich (2003)
      Run LS Minimum LM Test on k^ME_t levels using BP break dates
     ► Tests if k^ME_t is I(1) with breaks vs I(2) without size distortion
                                     │
                   ┌─────────────────┴─────────────────┐
                   ▼                                   ▼
          LS Rejects Unit Root Null            LS Fails to Reject
      k^ME_t is I(1) conditionally on T_B    True I(2) process persists
                   │                                   │
                   ▼                                   ▼
      Construct Step D_t(T_B) and             Switch Stage 1 level
    Trend DT_t(T_B) break terms for          specification to Investment
        DOLS Cointegration Stage                 Flows ln(I^ME_t)
```

## 3. Interaction with DOLS Lead/Lag Augmentations

When estimating via **Dynamic OLS (DOLS)**, the leads and lags of first differences ($\Delta \mathbf{X}_{t-j}$) control for endogeneity and dynamic correlation in $I(1)$ series.

### Critical Rule for Lead/Lag Interactions

If a major structural break $T_B$ alters the long-run relation, it also affects the short-run dynamics surrounding $T_B$.

1. **Standard DOLS Specification:**
    
    Include interaction terms for the cointegrating level variables while running continuous leads/lags of $\Delta \mathbf{X}_{t-j}$.
    
2. **Break Window Truncation:**
    
    Around the exact break date $T_B$, the differenced series $\Delta k^{ME}_{T_B}$ will exhibit a pulse shock. Ensure that lead/lag polynomials $\sum_{j=-q}^{q} \boldsymbol{\theta}_j' \Delta \mathbf{X}_{t-j}$ include a single-period pulse dummy $P_t(T_B) = \mathbb{I}(t = T_B)$ to prevent short-run variance spikes from contaminating the long-run elasticity estimates $\hat{\beta}_1$ and $\hat{\delta}_1$.
    

## 4. Methodological Workflow for Chapter 4

```
                   [1. Run Integrated Pre-Testing Protocol]
                Execute Bai-Perron + Lee-Strazicich on k^ME_t
                                     │
                                     ▼
                [2. Estimate Full Multiplicative Model]
     Interact k^ME_t with D_t(T_B1) and D_t(T_B2) via DOLS/IM-OLS
                                     │
                    ┌────────────────┴────────────────┐
                    ▼                                 ▼
           δ_1 is Statistically              δ_1 is Statistically
             Significant                     Insignificant
                    │                                 │
                    ▼                                 ▼
        [Retain Interaction Term]         [Drop Multiplicative Term]
      Structural elasticity shifted;     Elasticity β_1 is invariant;
     use sample-split estimations.      use additive step dummies D_t
                                        strictly for level alignment.
```

## 5. Paper-Facing Reporting Template

When presenting these interaction results in the paper, structure the cointegration table to highlight parameter stability across regimes:

|**Variable**|**Full Sample (Additive Only)**|**Full Sample (Multiplicative Shift)**|**Fordist Era (1930–1973)**|**Post-Fordist Era (1974–2019)**|
|---|---|---|---|---|
|**Machinery Stock ($k^{ME}_t$)**|$\hat{\beta}_1$|$\hat{\beta}_1^{\text{Base}}$|$\hat{\beta}_1^{\text{Ford}}$|$\hat{\beta}_1^{\text{Post}}$|
|**Break Interaction ($k^{ME}_t \cdot D_{1974}$)**|—|$\hat{\delta}_1$ ***|—|—|
|**Step Dummy ($D_{1974}$)**|$\hat{\gamma}_1$|$\hat{\gamma}_1$|—|—|
|**Real Exchange Rate ($r_t$)**|$\hat{\beta}_3$|$\hat{\beta}_3$|$\hat{\beta}_{3,\text{Ford}}$|$\hat{\beta}_{3,\text{Post}}$|
|**Residual Stationarity ($\widehat{\text{Gap}}_t$)**|ADF $t$-stat ($p < 0.05$)|ADF $t$-stat ($p < 0.01$)|ADF $t$-stat ($p < 0.05$)|ADF $t$-stat ($p < 0.01$)|

*** $p < 0.01$, $p < 0.05$. Standard errors corrected via Newey-West HAC covariance matrix.