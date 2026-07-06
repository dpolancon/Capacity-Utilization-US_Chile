---
type: note
status: superseded-for-baseline
layer: method
design_role: preferred_estimator_rule
scope: chapter2_core_support
estimator_status: historical-or-diagnostic
requires_review_before_use: true
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
role: superseded-for-baseline
stage: pre-estimation-design
aliases:
  - FM-OLS structural preservation
tags:
  - chapter2/econometrics
  - chapter2/superseded
  - chapter2/fmols
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# FM-OLS and Structural Preservation in Productive-Capacity Reconstruction

> [!gate] D12V2 gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.


> [!warning] D12V2 status
> This note is not baseline authorization.
> FM-OLS and IM-OLS are blocked for nonlinear/interacted/generated Chapter 2 baseline specifications.
> Use [[D12V_Restricted_DOLS_Active_Estimator_Lock]], [[FMOLS_IMOLS_Failure_For_Interaction_Objects]], and [[Estimator_Status_Ledger_D12V]] before citing this note for estimation design.


> [!warning] D12V status update — FM-OLS
> Standard FM-OLS is superseded as the active baseline estimator for nonlinear/interacted/generated Chapter 2 specifications.
> It remains available only as historical reference, diagnostic comparator, or possible estimator for strictly linear cointegration objects if the model object is explicitly classified as standard linear cointegration.
> Do not use this note as baseline authorization without passing through [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Interaction_Term_Integration_Order_Gate]].

> [!important] D12V status update — DOLS
> The active Chapter 2 baseline-design candidate is Restricted DOLS, not generic DOLS.
> Restricted DOLS keeps nonlinear/interacted terms in the long-run level equation but restricts the dynamic correction set to admissible base-variable differences.
> Unrestricted DOLS is blocked for interaction objects unless a separate protocol authorizes leads/lags of interaction-term differences.
> See [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]].

> [!gate] D12V interaction-term gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.
> Restricted DOLS is preferred only after base-variable integration status, interaction-term status, and sample-window adequacy are classified.

> [!important] Current identification lock
> The preferred regressor matrix is the primitive centered interaction in [[R_distribution_conditioned_theta_identification]]. Any accumulated-index baseline language below is parked historical material and does not govern current reconstruction.

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

The direct scale-conditioning regressor matrix is:

$$
y_t
=
\alpha
+
\theta_0\tilde k_t^{scale}
+
\phi\tilde d_t
+
\theta_1(\tilde k_t^{scale}\tilde d_t)
+
\varepsilon_t,
$$

so the recovered elasticity is:

$$
\hat{\theta}_t
=
\hat{\theta}_0
+
\hat{\theta}_1\tilde d_t.
$$

The competing composition-mediated matrix replaces the scale interaction with $\tilde\tau_t\tilde d_t$ while retaining the direct distribution control. FM-OLS preserves either governed matrix more cleanly than DOLS because it does not introduce auxiliary lead-lag terms into the structural equation.

---

## 3. Structural preservation rule

FM-OLS is preferred because it keeps the estimated equation aligned with the theoretical equation.

This matters because the reconstructed productive-capacity path requires a clean mapping from the estimated coefficient vector to the theoretical transformation relation.

The preservation rule is:

> the estimator may correct the coefficient, but it must preserve the selected primitive scale-conditioning or composition-mediated regressor matrix as the structural object being reconstructed.

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

**FM-OLS is preferred because it preserves the governed primitive scale-conditioning or composition-mediated regressor matrix while correcting long-run endogeneity and serial correlation. IM-OLS remains the robustness check and DOLS the fragility diagnostic. Productive capacity can be reconstructed only after the selected relation is admissible and its fitted path is level-anchored; otherwise the residual remains an algebraic remainder, not utilization.**

---

## References

Phillips, P. C. B. (1995). Fully modified least squares and vector autoregression. *Econometrica, 63*(5), 1023–1078.

Phillips, P. C. B., & Hansen, B. E. (1990). Statistical inference in instrumental variables regression with I(1) processes. *Review of Economic Studies, 57*(1), 99–125.
