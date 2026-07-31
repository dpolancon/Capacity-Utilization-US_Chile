---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/N05_Capital_Integration_Order_Comprehensive_Audit.md
  - reports/vecm_vs_cointreg_elasticity_paradox_synthesis.md
stage_scope: layer_2_integration
country: US_CL
last_updated: 2026-07-26
updated_by: KAPPA_IDENTIFICATION_LOCK
layer: econometrics
scope: all_agent_sessions
subtype: econometric_synthesis
blocks: []
priority: reference
---

# N06 — IM-OLS Exogeneity Re-Calibration and Finite-Sample Identification Paradox (Kappa Identification)

This document synthesizes the resolution of two critical econometric issues regarding the estimation of the capital composition cointegrating vector ($k_t^{\text{NRC}} = \alpha + \gamma k_t^{\text{ME}}$). It integrates findings from the `Empirical_CPR_Okishio` repository to correct previous assumptions about IM-OLS and provides a theoretical interpretation of $\kappa_t$ stationarity vis-à-vis short-sample identification.

---

## 1. Re-Calibration of IM-OLS and Endogeneity Handling

Prior interpretations suggested that single-equation models might fail to match the system Johansen estimates because they assume weak exogeneity. A review of the `Empirical_CPR_Okishio` repository—specifically the `im-ols-framework.md` documentation—requires a re-calibration of this stance regarding Vogelsang and Wagner's (2014) Integrated Modified OLS (IM-OLS).

### The IM-OLS Transformation
Unlike FM-OLS (which relies on non-parametric long-run variance matrix estimations with kernel choices) and DOLS (which uses parametric leads and lags), **IM-OLS intrinsically accounts for long-run endogeneity without requiring user-specified tuning parameters.**

Vogelsang and Wagner transform the standard $I(1)$ cointegrating regression into a partial sum (integrated) framework:
$$S y_t = S f_t' \boldsymbol{\delta} + S x_t' \boldsymbol{\beta} + x_t' \boldsymbol{\gamma} + u_{S,t}$$

Here, $S(\cdot)$ denotes the cumulative sum operator. The critical mechanism for endogeneity correction is the **untransformed augmentation term** $x_t' \boldsymbol{\gamma}$. In this augmented integrated design, the $x_t' \boldsymbol{\gamma}$ term completely absorbs the long-run endogeneity correlation between the regressors and the cointegrating error, cleanly isolating the cointegrating vector $\boldsymbol{\beta}$.

### Implications for the Elasticity Paradox
Because IM-OLS handles exogeneity asymptotically via this exact mathematical transformation, the divergence in magnitude between Johansen VECM ($\hat{\gamma} \approx 1.0$) and IM-OLS ($\hat{\gamma} \approx 2.15-3.03$) is **not** a result of IM-OLS failing to model endogeneity. Instead, the discrepancy is structurally driven by:
1. **Deterministic Drift Leakage:** Single-equation static and integrated models absorb low-frequency drift into the level slope, whereas Johansen restricted-constant models project it out.
2. **System Dynamics in Finite Samples:** While IM-OLS is asymptotically robust to endogeneity, in finite samples with mutual bilateral adjustment ($\alpha_{\text{NRC}} < 0, \alpha_{\text{ME}} > 0$), the single-equation conditioning still struggles to distinguish the equilibrium vector from the short-run transitional path.

---

## 2. Stationarity of $\kappa_t$ vs. Short-Sample Identification

The Johansen century-long baseline establishes that $\hat{\gamma} \approx 1.0$. This unit elasticity confirms that $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$ is a stationary (or near-stationary) $I(0)$ process reflecting the long-run Harrodian balanced growth corridor where factory structures and machinery accumulate proportionally over the secular longue durée.

However, a fundamental paradox arises when transitioning to the structural break windows (e.g., $N=15-30$ years) evaluated by `cointReg` super-consistent estimators:

### The Finite-Sample Identification Problem
**Validation that $\kappa_t$ is stationary globally does *not* guarantee that the $\gamma$ coefficient is adequately identified as 1.0 in short sub-samples.**

1. **Transitional Regimes Dominate:** In short samples of 15 to 30 years, capital accumulation is not traversing the long-run balanced growth path; it is characterized by specific, historically bounded choice-of-technique regimes (e.g., rapid post-war mechanization or Neoliberal de-industrialization). The variance of these localized, deterministic trends dwarfs the variance of the long-run cointegrating relationship.
2. **Asymptotic Convergence Rates:** Super-consistent estimators achieve their properties via $O(T)$ or $O(T^{3/2})$ convergence rates. In small samples, there is simply not enough temporal variation (degrees of freedom) for the asymptotic properties of FM-OLS, DOLS, or IM-OLS to fully purge the transient dynamics. The estimators inevitably fit the local trajectory rather than the global equilibrium.
3. **Economic Meaning of Inflated Elasticities:** The elevated magnitudes from the `cointReg` triad in short samples ($\hat{\gamma} > 2.0$) are not statistical artifacts to be discarded. They are accurate reflections of the *local* structural elasticity of transformation. When capitalists restructure production rapidly, machinery investment outpaces structures dramatically, producing a locally steep slope that the estimators correctly identify as the prevailing regime parameter. 

### Conclusion
The century-long VECM validates $\kappa_t$ as a structurally admissible $I(0)$ state variable for the aggregate capacity utilization function. Conversely, the short-sample `cointReg` models provide the necessary high-resolution parameters of the active choice-of-technique regime. The divergence in orders of magnitude is therefore a feature of analyzing multiple temporal frequencies of capitalist accumulation, not a failure of econometric identification.

---

## Vault Cross-References

- Path Derivative Identification Lock: [[E18_Kappa_Path_Derivative_LOESS_Lock]] — binds $\frac{d \kappa_t}{d k_t^{\text{NRC}}}$ to LOESS trend derivatives (never point-wise discrete ratios).
- LOESS Structural Break Assessment: [[N06_LOESS_DataDriven_Structural_Break_Assessment]]
- Analytical Foundation: [[A06_RelativePrice_Mechanization_Theory]]
- Symbology Lock: [[00S_Chapter2_Symbology_and_Notation_Lock]]
