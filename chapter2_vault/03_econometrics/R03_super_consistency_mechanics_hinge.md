---
type: note
status: active
layer: method
design_role: estimator_lineage_hinge
scope: chapter2_core_support
related_to:
  - R02_DOLS_reconstruction_dilemma
  - R04_FMOLS_structural_preservation
  - R05_LRV_kernel_bandwidth_regime_misalignment
  - R06_IMOLS_integration_ladder_reconstruction
  - N02_SuperConsistency
  - M10_Empirical_Identification_Framework
  - L00_Econometrics_References
priority: high
---

# Hinge: The Divergent Mechanics of Super-Consistency

## Core claim

Super-consistency is not a single mechanism. It is achieved through distinct estimator architectures that solve the same asymptotic problem through incompatible mechanical pathways.

These pathways differ in how they treat endogeneity, autocorrelation, and—critically for this dissertation—the structural integrity of the regression used to reconstruct productive capacity.

---

## 1. The common problem

In $I(1)$ cointegrating regressions, OLS is super-consistent but suffers from second-order asymptotic bias driven by:

- endogeneity (correlation between regressors and the error term),
- serial correlation (autocorrelation in the innovations).

All super-consistent estimators attempt to purge this bias.

They do not do so in the same way.

---

## 2. The three estimator lineages

### A. DOLS — Parametric absorption

Mechanism:

DOLS augments the regression with leads and lags of first differences.

$$
y_t = \alpha + \beta x_t + \sum_{j=-q}^{p}\gamma_j \Delta x_{t-j} + \varepsilon_t
$$

Logic:

- leads address endogeneity,
- lags absorb serial correlation.

Implication:

Bias is reduced by expanding the regressor matrix.

Cost:

The regression is structurally altered. Nuisance dynamics enter the specification.

---

### B. FM-OLS — Covariance correction

Mechanism:

FM-OLS estimates long-run covariance matrices and applies corrections to the estimator without modifying the regression.

Logic:

- endogeneity and serial correlation are handled through non-parametric adjustments,
- the regressor matrix is preserved.

Implication:

Bias is corrected externally, not through model expansion.

Cost:

Requires kernel and bandwidth choices and assumes global stability in covariance structure.

---

### C. IM-OLS — Integration transformation

Mechanism:

IM-OLS transforms the data through partial sums, shifting the system into higher-order integration space.

Logic:

- signal grows faster than noise,
- second-order bias is asymptotically dominated.

Implication:

Super-consistency is achieved through order dominance, not VCV correction.

Cost:

Estimation occurs in integrated space, requiring a trace-back to recover level-space objects.

---

## 3. Structural trade-offs

Each estimator solves the same statistical problem but introduces a different structural distortion:

- DOLS: parametric clutter in the regression,
- FM-OLS: temporal smoothing via global covariance estimation,
- IM-OLS: transformation into integrated space requiring inversion.

These are not technical details. They affect the admissibility of the reconstructed object.

---

## 4. Implication for $\mu$ reconstruction

The Chapter 2 target is not the coefficient itself, but the sequence:

$$
\text{long-run relation}
\rightarrow
\hat{\theta}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t
$$

For this sequence:

- DOLS risks contaminating the structural mapping,
- FM-OLS preserves the mapping but smooths across regimes,
- IM-OLS preserves coefficient clarity but complicates level reconstruction.

None of the estimators identifies $\mu_t$ directly.

---

## 5. Regime limitation

All three estimators are global.

They assume a stable long-run relation across the sample.

Therefore:

They cannot, by construction, identify regime-dependent parameters or threshold effects.

That requires a separate estimation layer.

---

## 6. Methodological lock

The estimators must be assigned differentiated roles:

- FM-OLS: main estimator for long-run reconstruction,
- IM-OLS: robustness check without tuning parameters in estimation,
- DOLS: fragility diagnostic via parametric absorption.

---

## 7. Locked sentence for reuse

**DOLS purifies by expanding the regression, FM-OLS by correcting covariance structure, and IM-OLS by transforming the integration order. Each solves second-order bias through a distinct mechanism, and each introduces a different structural distortion. None, by itself, identifies capacity utilization.**