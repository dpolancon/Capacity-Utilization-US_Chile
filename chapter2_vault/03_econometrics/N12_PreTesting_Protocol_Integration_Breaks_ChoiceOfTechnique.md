---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
  - chapter2_vault/02_analyitical_foundation/A03_TransformationElasticity_Two-CapitalCapacityComposition.md
  - chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-25
layer: econometrics
created_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK
role: pre-testing-protocol
stage: pre-estimation-design
tags:
  - chapter2/econometrics
  - chapter2/pre-testing
  - chapter2/integration-order
  - chapter2/structural-breaks
  - chapter2/cointegration
  - chapter2/choice-of-technique
aliases:
  - N12 Pre-testing Protocol
  - Pre-testing Protocol
  - Integration Breaks Choice of Technique Synthesis
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# N12 — Cross-Reference Synthesis & 5-Stage Pre-Testing Protocol: Integration Orders, Structural Breaks, Cointegration, & Choice of Technique

## Executive Summary & Analytical Mapping

This document synthesizes four distinct lines of research within Chapter 2 into a single unified pre-testing framework:

```
[Pillar 1: Integration Orders] ------> [Pillar 2: LOESS Inflections & Breaks]
  (N03, N04, N05: k, tau, w ~ I(1))      (N06: d²tau/dt² = 0, early warning)
                |                                      |
                v                                      v
[Pillar 3: Cointegration & Drift Leakage] <--- [Pillar 4: Choice of Technique]
  (N10: k_NRC accommodation, g_ME > g_NRC)       (A02, A03: theta(w) Okishio-Vidal)
                |
                v
  ===> [Unified 5-Stage Pre-Testing Protocol for Estimation Procedures] <===
```

1. **Integration Orders ([[N03_US_Theta_Integration_Order_Admissibility]], [[N04_CL_Theta_Integration_Order_Admissibility]], [[N05_Capital_Integration_Order_Comprehensive_Audit]]):** Proves that structural envelope scale ($k_t \equiv \ln K^{NRC}$), machinery composition ($\tau_t \equiv \ln K^{ME} - \ln K^{NRC}$), and wage share ($\omega_t$) are strictly $I(1)$, while the cross-product $\tau_t \omega_{t-1}$ is an $O_p(T)$ degree-2 polynomial regressor requiring Cointegrating Polynomial Regression (CPR) methods.
2. **Structural Break Inflections ([[N06_LOESS_DataDriven_Structural_Break_Assessment]], [[N08_Internal_Decision_Report_Window_Estimations_and_Parameter_Stability]], [[N09_Regulationist_Accumulation_Regimes_and_Long_Span_Windowing]]):** Reconciles non-parametric LOESS 2nd-derivative zero-crossings ($\frac{d^2 \tau_t}{dt^2} = 0$, e.g. **1968**) as *early warning indicators* of technical accumulation strain with parametric VECM step-dummies ($D_t$, e.g. **1973**) capturing macro-institutional ruptures.
3. **Cointegration & Drift Leakage ([[N10_US_Capital_Composition_Cointegration_Report]]):** Establishes that nonresidential structures ($k^{NRC}_t$) accommodate equipment ($k^{ME}_t$) over the long run to prevent physical realization failures ($\gamma \approx 1.0$ full century VECM Case 2), while short-sample IM-OLS elasticity spikes ($\hat{\gamma} \approx 4.3$ during Fordism) measure the **structural velocity of technical transformation** ($d\hat{k}/dt$).
4. **Choice of Technique ([[A02_Intensive_Accumulation]], [[A03_TransformationElasticity_Two-CapitalCapacityComposition]], [[H00_Okishio_Vidal_Decentralized_Accumulation]], [[H01_Cajas_to_Transformation_Elasticity]]):** Grounds the econometrics in the Okishio-Vidal Double Choice of Technique model, where distribution ($\omega_t$) conditions mechanization velocity, which in turn determines the aggregate transformation elasticity $\theta^N(\omega, s)$.

---

## 1. Pillar 1: Integration Orders & Stochastic Properties

### 1.1 Univariate Property Audit ([[N05_Capital_Integration_Order_Comprehensive_Audit]])
Across both the United States (1925–2021, $N=97$) and Chile (1920–2024, $N=105$), log-levels of all capital stock components ($k^{ME}_t, k^{NRC}_t, k_t$) and distributive series ($\omega_t$) fail to reject the unit root null across ADF, Phillips-Perron (PP), and Elliott-Rothenberg-Stock (ERS-GLS) tests ($p > 0.10$). First differences ($\Delta k^{ME}_t, \Delta k^{NRC}_t, \Delta \omega_t$) reject unit roots at $p < 0.01$.

*   **Result:** Base variables are strictly $I(1)$ processes.
*   **Implication for Estimation:** Standard stationary OLS is invalid. Super-consistent cointegration estimators (IM-OLS) are required.

### 1.2 The Cross-Product Regressor Classification ([[N01_CapacityUtilization_StructuralObject]], [[E11_IMOLS_CPR_Asymptotic_Rationale]])
The interaction term $q_t = \tau_t \omega_{t-1}$ (or $k_t \omega_{t-1}$) is **not** a classical $I(2)$ variable. Taking a second difference $\Delta^2 q_t$ does not yield a stationary $I(0)$ error because the first difference:
$$ \Delta(\tau_t \omega_{t-1}) = \tau_{t-1} \Delta \omega_t + \omega_{t-1} \Delta \tau_t + \Delta \tau_t \Delta \omega_t $$
mixes integrated levels with stationary innovations, creating heterogeneous stochastic volatility.

*   **Correct Classification:** $q_t$ is a **degree-2 polynomial CPR regressor**.
*   **Stochastic Scaling:** Level order $O_p(T)$; partial-sum accumulated order $O_p(T^2)$; coefficient convergence rate $T^{-3/2}$.

---

## 2. Pillar 2: LOESS Inflections vs. Institutional Structural Breaks

### 2.1 The Two-Tier Break Framework ([[N06_LOESS_DataDriven_Structural_Break_Assessment]])

| Break Tool | Mathematical Basis | Empirical Example | PE Structural Function |
| :--- | :--- | :--- | :--- |
| **LOESS 2nd Derivative** | $\frac{d^2 \tau_t}{dt^2} = 0$ (Inflection) | **1933, 1968, 2008** (US)<br>**1933, 1971, 2008** (Chile) | **Early Warning Indicator:** Measures when capitalists alter mechanization velocity due to late-Fordist profit squeezes. |
| **VECM Step-Dummy** | Discrete level shift $D_t \cdot \mathbf{1}(t \ge t^*)$ | **1973** (OPEC / Bretton Woods)<br>**1973/1974** (Chile Coup / Dictatorship) | **Macro-Institutional Rupture:** Captures institutional regime collapse when technical strain reaches critical threshold. |

### 2.2 Reconciling 1968 vs. 1973 (The UMass Data-First Principle)
As documented in [[N06_LOESS_DataDriven_Structural_Break_Assessment]], the non-parametric LOESS 2nd derivative zero-crossing identifies a crucial structural inflection in **1968** — five years *before* the 1973 OPEC oil shock and Bretton Woods collapse. 

*   **Political Economy Insight:** Capitalists began altering their mechanization velocity ($\frac{d^2 \tau}{dt^2} = 0$) in response to the late-Fordist profit squeeze starting in 1968, *before* the institutional regime formally ruptured in 1973. 
*   **Econometric Role:** 
    - The **1968 LOESS inflection** marks the turning point in the choice of technique.
    - The **1973 step-dummy ($D_{1973}$)** restores VECM cointegration rank ($r=1$, Trace = **33.72** > 25.32) by absorbing the discrete macro-level shift.

---

## 3. Pillar 3: Long-Run Cointegration & Drift Leakage

### 3.1 Structural Directionality: Plant Accommodation ([[N10_US_Capital_Composition_Cointegration_Report]])
The empirical long-run cointegration model between structures ($k^{NRC}$) and equipment ($k^{ME}$) asserts a clear directional hypothesis:
$$ k^{NRC}_t = \alpha + \gamma k^{ME}_t + u_t $$
Machinery ($k^{ME}$) represents the active, discretionary choice of technique by capitalists. Nonresidential structures ($k^{NRC}$) act as the accommodating physical envelope required to house that equipment and prevent chronic realization failures.

### 3.2 Full Century vs. Era-Specific Elasticity Matrix ([[N10_US_Capital_Composition_Cointegration_Report]])

| Macro-Era | IM-OLS $\hat{\gamma}$ | VECM Case 2 $\hat{\gamma}$ | Cointegration Status ($r=1$) | PE Structural Interpretation |
| :--- | :---: | :---: | :---: | :--- |
| **Full Century** (1925–2021) | 2.185 | **0.994** | Cointegrated ($p < 0.05$) | **Harrodian Balanced Growth:** Over 100 years, structures accommodate equipment 1-to-1 ($\gamma \approx 1.0$). $\tau_t \sim I(0)$. |
| **Fordist Expansion** (1947–1973) | **4.319** | 0.597 | Cointegrated ($p < 0.01$) | **Massive Capital Deepening:** Equipment growth ($g_{ME} \approx 5\%$) heavily outpaces plant expansion ($g_{NRC} \approx 2\%$). |
| **Neoliberal Era** (1974–2008) | **-0.600** | 1.774 (No Coint) | **Decoupled** ($r=0$) | **Deindustrialization & ICT Turnover:** Plant structures stagnate while short-lifecycle ICT turns over; cointegration breaks. |

### 3.3 Theoretical Proof of Drift Leakage
The numerical divergence between the restricted VECM full-century baseline ($\hat{\gamma} \approx 1.0$) and single-equation IM-OLS era estimates ($\hat{\gamma} \approx 4.3$) is **Drift Leakage**. 

Under asymmetric accumulation ($g_{ME} \gg g_{NRC}$):
$$ k^{NRC}_t = g_{NRC} t + u^{NRC}_t, \qquad k^{ME}_t = g_{ME} t + u^{ME}_t $$
Single-equation estimators (IM-OLS, FM-OLS) without explicit time detrending absorb the differential growth drift into the estimated elasticity:
$$ \hat{\gamma}_{\text{IMOLS}} \approx \frac{g_{ME}}{g_{NRC}} \approx \frac{4.5\%}{1.1\%} \approx 4.1 $$
This is not estimation bias; it is the mathematical proxy for the **structural velocity of technical transformation** ($d\hat{k}/dt$).

---

## 4. Pillar 4: Choice of Technique under Heterogeneous Capital

### 4.1 The Okishio-Vidal Micro-Meso Foundation ([[A02_Intensive_Accumulation]], [[A03_TransformationElasticity_Two-CapitalCapacityComposition]], [[H00_Okishio_Vidal_Decentralized_Accumulation]])
The analytical foundation decomposes productive capacity formation ($Y^p$) into two distinct capital margins:
$$ Y^p = \frac{a^N(\omega, s)}{q^*(\omega, s)} K^{ME} + \Gamma(K^{NRC}) $$

1.  **Scale / Envelope Margin ($K^{NRC}$):** Nonresidential structures provide the baseline capacity footprint $\Gamma(K^{NRC})$, independent of distribution ($\partial \theta^{NRC} / \partial \omega = 0$).
2.  **Technique / Composition Margin ($K^{ME}$):** Machinery efficiency is modulated by class conflict through the mechanization frontier $a^N(\omega, s) / q^*(\omega, s)$.

### 4.2 Distributive Conditioning & Induced Innovation ([[A03_TransformationElasticity_Two-CapitalCapacityComposition]], [[H01_Cajas_to_Transformation_Elasticity]])
Capitalists select the cost-minimizing technique $q^*(\omega)$ subject to distributive pressures. When wage share rises ($\omega \uparrow \implies \pi \downarrow$), capitalists accelerate mechanization ($\frac{d^2 \tau}{dt^2} > 0$), pushing $q^*$ rightward along the concave Okishio-Vidal frontier ($a^N = \lambda_0 + \lambda_1 q^* + \lambda_2 (q^*)^2$). 

This alters the marginal capacity payoff of machinery:
$$ \theta^{ME}(\omega, s) = \frac{\lambda_0}{q^*(\omega, s)} + \lambda_1 + \lambda_2 q^*(\omega, s) $$
The aggregate transformation elasticity is the composition-weighted sum:
$$ \theta^N(\omega, s) = \frac{\theta^{NRC}(1-s) g_{NRC} + \theta^{ME}(\omega, s) s g_{ME}}{(1-s) g_{NRC} + s g_{ME}} $$

---

## 5. Unified 5-Stage Pre-Testing Protocol for Estimation Procedures

Based on the cross-reference synthesis across all four pillars, any empirical estimation of Chapter 2's capacity models must pass through the following **5-Stage Pre-Testing Sequence**:

```
[Stage 1: Unit Root Audit] ──> [Stage 2: LOESS Inflection Screening]
                                             │
[Stage 4: Drift Leakage Test] <── [Stage 3: Johansen VECM Cointegration]
            │
            ▼
[Stage 5: CPR IM-OLS 3-Regime Estimation (N11)]
```

### Stage 1: Unit Root & Polynomial Classification Gate
- **Check 1.1:** Confirm $y_t, k_t, \tau_t, \omega_t \sim I(1)$ via ADF, PP, ERS-GLS.
- **Check 1.2:** Classify $\tau_t \omega_{t-1}$ as degree-2 polynomial CPR regressor (order $O_p(T)$, partial sum $O_p(T^2)$).
- **Check 1.3:** Verify prohibition of FWL pre-filtering ($SM_X \neq M_{SX}S$).

### Stage 2: Data-First LOESS Inflection Screening
- **Check 2.1:** Compute non-parametric LOESS 2nd derivative zero-crossings ($\frac{d^2 \tau_t}{dt^2} = 0$).
- **Check 2.2:** Flag technical inflection years (e.g. 1933, 1968, 2008) as candidate macro-era boundaries.

### Stage 3: Johansen VECM Cointegration & Break-Dummy Gate
- **Check 3.1:** Test VECM Case 2 (restricted constant) for secular Harrodian baseline ($\hat{\gamma} \approx 1.0$).
- **Check 3.2:** If trace test fails over full span, introduce LOESS-guided step-dummies ($D_{1973}, D_{2008}$). Verify $r=1$ recovery under Wild Bootstrap ($B=999$).

### Stage 4: Drift Leakage Diagnostic
- **Check 4.1:** Compute growth rate ratio $g_{ME} / g_{NRC}$ over the estimation window.
- **Check 4.2:** Compare restricted VECM $\hat{\gamma}_{\text{Case 2}}$ against unrestricted IM-OLS $\hat{\gamma}_{\text{IMOLS}}$. If $\hat{\gamma}_{\text{IMOLS}} \approx g_{ME} / g_{NRC} \gg 1.0$, record the gap as structural technical acceleration ($d\hat{k}/dt$).

### Stage 5: CPR IM-OLS 3-Regime Estimation ([[N11_Centering_Protocol_Three_Regime]])
- **Regime A (Main):** Estimate raw uncentered equation using QR decomposition (`lm()`) or SVD (`lstsq`).
- **Regime B (Primary Robustness):** Estimate initial-state centered equation ($\tilde{\tau}_t = \tau_t - \tau_1, \tilde{\omega}_t = \omega_t - \omega_1$) for canonical Brownian start and path-dependent historical interpretation.
- **Regime C (Secondary Robustness):** Estimate sample-mean centered equation for standard comparability.
- **Diagnostic Check:** Verify confidence-band overlap for $\hat{d}$ and $\hat{\theta}(\omega_0)$ across regimes. If Regime A suffers floating-point precision loss due to condition number, default to Regime B.

---

## 6. Synthesis Summary Matrix

| Pillar | Core File | Key Econometric / PE Result | Role in Estimation Protocol |
| :--- | :--- | :--- | :--- |
| **1. Integration Orders** | [[N03_US_Theta_Integration_Order_Admissibility]], [[N05_Capital_Integration_Order_Comprehensive_Audit]] | $k, \tau, \omega \sim I(1)$; $\tau\omega \sim \text{CPR degree-2 polynomial } O_p(T)$ | Pre-test gate: Blocks linear OLS/FM-OLS; requires CPR IM-OLS |
| **2. Structural Breaks** | [[N06_LOESS_DataDriven_Structural_Break_Assessment]], [[N08_Internal_Decision_Report_Window_Estimations_and_Parameter_Stability]] | LOESS $\frac{d^2 \tau}{dt^2}=0$ = early warning (1968); VECM $D_t$ = rupture (1973) | Dictates window boundaries and VECM step-dummy placement |
| **3. Cointegration & Drift** | [[N10_US_Capital_Composition_Cointegration_Report]] | $k^{NRC}$ accommodates $k^{ME}$; Full-span $\gamma \approx 1.0$; Fordist $\hat{\gamma} = 4.32$ | Distinguishes Harrodian equilibrium from short-span technical velocity |
| **4. Choice of Technique** | [[A02_Intensive_Accumulation]], [[A03_TransformationElasticity_Two-CapitalCapacityComposition]] | $\theta^N(\omega, s)$ endogenously modulated by class struggle on Okishio frontier | Provides structural interpretation of state elasticity $\hat{\theta}(\omega_0)$ |
