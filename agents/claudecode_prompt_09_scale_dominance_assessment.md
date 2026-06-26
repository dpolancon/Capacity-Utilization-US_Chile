# Claude Code Prompt 09: Chile Stage A.4 — Capital Scale Dominance Assessment
## Econometric Analysis of Cointegrating Variance and Small-Sample Parameter Insignificance
## Methodological Framework: Cointegration Asymptotics, Super-Consistency, and WLM v4.0 Voice

---

## 1. Objective and Task Definition

You are instructed to produce a rigorous econometric assessment explaining why the **aggregate capital scale regressor ($k_t^{CL}$)** dominates the capacity frontier estimation, "soaking up" almost the entirety of the long-run cointegrating variance and rendering the capital composition ($c_t$) and distribution interaction ($\omega_c$) terms statistically insignificant in both regimes.

This assessment must be written as a formal research note:
* **Target File:** `output/stage_a/Chile/docs/CL_S90_capital_scale_dominance_assessment.md`
* **Style Guide:** Conform strictly to **WLM v4.0** (direct, unhedged voice; evidence and verdict in the same paragraph; no neutral summaries; citation discipline).

---

## 2. The Empirical Paradox (The Findings to Analyze)

In the Chile FGLS threshold cointegration model (N=39, 1940–1978 estimation window), the regime-specific parameters show the following patterns:

* **Regime 1 (BOP Deficit):** 
  * Capital Scale ($k_{CL}$): Est = $0.8444$, SE = $0.0889$, t = **$9.50$** (Highly Significant)
  * Composition ($c_t$): Est = $0.1865$, SE = $0.1967$, t = $0.95$ (Insignificant)
  * Interaction ($\omega_c$): Est = $-0.0333$, SE = $0.9269$, t = $-0.04$ (Insignificant)
  * Wage Share ($\omega_t$): Est = $-0.0883$, SE = $0.7401$, t = $-0.12$ (Insignificant)

* **Regime 2 (BOP Surplus):**
  * Capital Scale ($k_{CL}$): Est = $0.8949$, SE = $0.2578$, t = **$3.47$** (Highly Significant)
  * Composition ($c_t$): Est = $-0.1794$, SE = $0.4519$, t = $-0.40$ (Insignificant)
  * Interaction ($\omega_c$): Est = $-0.2175$, SE = $6.5849$, t = $-0.03$ (Insignificant)
  * Wage Share ($\omega_t$): Est = $-1.1414$, SE = $7.0775$, t = $-0.16$ (Insignificant)

---

## 3. Econometric Hypotheses to Assess

Your assessment must evaluate the following four hypotheses using the repository's econometric vault rules (`R03` and `R11`):

### A. Cointegration Asymptotics and the Super-Consistency Hinge
* **Mechanism:** Analyze how the aggregate scale capital stock ($k_t^{CL}$) acts as the primary $I(1)$ stochastic trend driving long-run output ($y_t$). Under standard cointegration asymptotics, the coefficient on the dominant $I(1)$ trend converges at rate $T$ (super-consistency), absorbing the bulk of the level-space variance.
* **Dominance:** In contrast, capital composition ($c_t = k_t^{ME} - k_t^{NR}$) and wage share ($\omega_t$), while persistent, behave more like stationary or near-$I(1)$ drift-less variables. Their coefficients converge at the slower rate of $\sqrt{T}$, meaning they are asymptotically dominated by the scale trend in level regressions.

### B. Small-Sample Power and Degrees-of-Freedom Squeeze
* **Parameter Inflation:** We are estimating 10 parameters (constant, scale, composition, interaction, and distribution controls split across 2 regimes) on a small annual sample of $N=39$ observations.
* **Squeeze:** Regime 1 has $N_1=15$ observations, and Regime 2 has $N_2=23$ observations. When you apply Cochrane-Orcutt filters (consuming lags) and Saikkonen dynamic leads/lags of first differences (which add multiple extra regressors to purge endogeneity), the remaining degrees of freedom are virtually zero. This inflates the parameter variance (standard errors) of the secondary variables, rendering them statistically insignificant.

### C. Signal-to-Noise Ratio of Log-Composition vs. Aggregate Scale
* **Frontier vs. Margin:** Cointegration in log-levels identifies the long-run frontier (scale elasticity). The composition variable $c_t$ captures structural margins of mechanization. While $k_t^{CL}$ has a massive, drift-driven signal, the composition ratio $c_t$ moves slowly and has a low signal-to-noise ratio in log-levels during the 1940–1978 period.
* **Collinearity:** Since $k_t^{NR}$ and $k_t^{ME}$ share a common stochastic trend, the scale trend $k_t^{CL}$ absorbs the common cointegrating vector, leaving little residual variance for the composition term to explain.

### D. Cochrane-Orcutt FGLS Variance Shifting
* **Filter Effect:** Cochrane-Orcutt filtering ($\rho_1 = 0.3690$) transforms the variables into quasi-differences, which reduces the low-frequency (trend) component of the data and emphasizes the high-frequency (short-run) variations. Explain how this filtering shifts the variance structure, making secondary level parameters even more difficult to identify in small samples.

---

## 4. Writing Instructions (WLM v4.0 Voice)

* **No Hedging:** Do not write that the variables "may be" or "seem to be" insignificant due to sample size. State the structural cause directly.
* **Evidence and Verdict:** Place the empirical evidence (t-stats, N values, AR coefficients) in the same paragraph as the econometric verdict.
* **Structure of the Report:**
  1. **Executive Verdict:** Unhedged summary of why capital scale dominates the cointegrating space.
  2. **The Super-Consistency Hinge:** Deep dive into $T$ vs. $\sqrt{T}$ asymptotic convergence rates.
  3. **Small Sample Over-parameterization:** Table showing degrees of freedom consumption (Saikkonen leads/lags + FGLS splits).
  4. **Economic Implications:** What this means for the Chilean capacity utilization reconstruction. (Verdict: the scale trend is the true long-run frontier anchor; composition and interactions represent local parameter drifts rather than sovereign cointegrating trends).
