---
type: note
status: active
layer: method
design_role: preferred_estimator_rule
scope: chapter2_core_support
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - R03_super_consistency_mechanics_hinge
  - R05_LRV_kernel_bandwidth_regime_misalignment
  - R06_IMOLS_integration_ladder_reconstruction
  - N02_SuperConsistency
  - M10_Empirical_Identification_Framework
  - L00_Econometrics_References
priority: high
---

# FM-OLS and Structural Preservation in Productive-Capacity Reconstruction

## Core claim

FM-OLS is the preferred estimator for the main long-run reconstruction layer because it preserves the A00 structural regressor matrix while correcting for endogeneity and serial correlation.

It is structurally cleaner than DOLS because it does not add lead-lag nuisance terms to the regression. It is more direct than IM-OLS because it estimates the relation in log-level space rather than in integrated partial-sum space.

But FM-OLS still does not identify utilization directly.

---

## 1. What FM-OLS does

FM-OLS estimates a cointegrating relation while correcting for long-run endogeneity and serial correlation through long-run covariance adjustments.

Its advantage is that the structural equation remains intact.

Unlike DOLS, FM-OLS does not expand the regression with leads and lags of first differences. The correction happens through the estimator, not through additional regressors.

---

## 2. Why this matters for Chapter 2

Chapter 2 does not treat the long-run coefficient as the final object.

The coefficient enters a reconstruction sequence:

$$
\text{long-run relation}
\rightarrow
\hat{\theta}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

For this sequence, preserving the theoretical regressor matrix matters.

The corrected A00 structural regressor matrix is:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t,
$$

so the recovered elasticity is:

$$
\hat{\theta}_t
=
\hat{\theta}_0
+
\hat{\theta}_\omega m_{t-1}^{(h)}.
$$

FM-OLS preserves this A00 mapping more cleanly than DOLS because it does not introduce auxiliary lead-lag terms into the structural equation. The accumulated index must be constructed before estimation and remains part of the structural matrix.

---

## 3. Structural preservation rule

FM-OLS is preferred because it keeps the estimated equation aligned with the theoretical equation.

This matters because the reconstructed productive-capacity path requires a clean mapping from the estimated coefficient vector to the theoretical transformation relation.

The A00 preservation rule is:

> the estimator may correct the coefficient, but it must preserve $\alpha+\theta_0 k_t+\theta_\omega q_t^{\omega,h}+u_t$ as the structural object being reconstructed.

FM-OLS satisfies this rule better than DOLS.

---

## 4. The remaining identification limit

FM-OLS improves coefficient recovery. It does not complete object recovery.

The residual from an FM-OLS relation is still not utilization by itself. It becomes meaningful only after productive capacity has been structurally reconstructed and level-anchored.

So the correct sequence is:

$$
\text{FM-OLS recovery of the A00 relation}
\rightarrow
\hat{\theta}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

Not:

$$
\text{FM-OLS residual}
\rightarrow
\hat{\mu}_t.
$$

---

## 5. Relation to DOLS and IM-OLS

FM-OLS occupies the preferred middle position.

Relative to DOLS:

- it avoids lead-lag clutter,
- it preserves the regressor matrix,
- it keeps the structural mapping cleaner.

Relative to IM-OLS:

- it works directly in log-level space,
- it does not require a trace-back from integrated partial-sum space,
- it maps more directly into productive-capacity reconstruction.

For that reason, FM-OLS is the preferred main estimator, while IM-OLS is a robustness check and DOLS is a fragility diagnostic.

---

## 6. Regime warning

FM-OLS remains a global estimator.

Its corrections depend on long-run covariance estimation. If the data-generating process shifts across regimes, the covariance correction can smooth across historically distinct periods.

So FM-OLS is preferred for the long-run reconstruction layer, but it does not solve regime-dependent identification.

The regime layer must remain separate.

---

## 7. Methodological lock

FM-OLS should be assigned the following role:

- yes, main estimator for long-run productive-capacity reconstruction;
- yes, preferred estimator for preserving the A00 structural regressor matrix;
- no, direct estimator of utilization;
- no, threshold-regime estimator.

Its result must be interpreted through the reconstruction sequence, not through the residual.

---

## 8. Locked sentence for reuse

**FM-OLS is preferred because it preserves the corrected A00 structural regressor matrix $\alpha+\theta_0 k_t+\theta_\omega q_t^{\omega,h}+u_t$, and therefore preserves the mapping $\theta_t=\theta_0+\theta_\omega m_{t-1}^{(h)}$. It can support productive-capacity reconstruction only after the generated index is audited, the relation is admissible, and the path is level-anchored; otherwise the residual remains an algebraic remainder, not utilization.**

---

## References

Phillips, P. C. B. (1995). Fully modified least squares and vector autoregression. *Econometrica, 63*(5), 1023–1078.

Phillips, P. C. B., & Hansen, B. E. (1990). Statistical inference in instrumental variables regression with I(1) processes. *Review of Economic Studies, 57*(1), 99–125.
