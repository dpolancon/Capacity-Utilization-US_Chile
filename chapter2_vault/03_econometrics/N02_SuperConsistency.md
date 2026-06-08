---
type: note
status: active
layer: method
design_role: estimation_clarification
scope: chapter2_core_support
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - N01_CapacityUtilization_StructuralObject
  - R01_residual_vs_structural_identification
  - R02_DOLS_reconstruction_dilemma
  - R03_super_consistency_mechanics_hinge
  - R04_FMOLS_structural_preservation
  - R05_LRV_kernel_bandwidth_regime_misalignment
  - R06_IMOLS_integration_ladder_reconstruction
  - R07_FGLS_threshold_cointegration_admissibility
  - R08_threshold_break_diagnostics_to_FGLS
  - L00_Econometrics_References
  - M10_Empirical_Identification_Framework
priority: high
---

# Super-consistency and the reconstruction of $\mu$

## Core claim

Super-consistency secures recovery of the first-layer coefficient vector in the corrected A00 accumulated-index benchmark.

It does not secure the empirical reconstruction of $\mu$.

The reason is that $\mu_t$ is not directly estimated. It is reconstructed from productive capacity, and productive capacity is itself an unobserved structural object.

---

## 1. The distinction

Cointegrated estimators are designed to recover a long-run coefficient vector under integration.

This establishes:

> whether the transformation relation can be estimated.

It does not establish:

> whether the utilization series derived from that relation is theoretically and empirically admissible.

So the econometric target is not $\mu_t$ directly.

The target is the A00 accumulated-index relation that allows productive capacity to be reconstructed:

$$
y_t^p
=
\alpha
+
\theta_0 k_t
+
\theta_\omega q_t^{\omega,h}
+
u_t.
$$

---

## 2. Identification sequence

The empirical object is produced through a strict sequence:

$$
\text{A00 accumulated-index relation}
\rightarrow
\hat{\theta}_t
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

Super-consistency applies only to the first step: coefficient recovery in the corrected A00 benchmark.

Everything downstream remains contingent on:

- theoretical interpretation of the coefficient,
- deterministic specification,
- interaction structure,
- productive-capacity reconstruction,
- level anchoring or pinch-year normalization,
- and the inadmissibility of treating the residual as the identifying object.

The residual does not identify utilization. It becomes interpretable only after $Y_t^p$ has been structurally reconstructed.

---

## 3. Estimator layer

In linear cointegration, the main estimator family is:

- OLS: super-consistent but second-order biased;
- DOLS: corrects through leads and lags of differences;
- FM-OLS: corrects through long-run covariance adjustment;
- IM-OLS: uses an integrated partial-sum transformation.

These estimators are not interchangeable for reconstruction.

They solve the coefficient-recovery problem through different mechanisms:

- DOLS purifies by expanding the regression;
- FM-OLS purifies by correcting covariance structure while preserving the regressor matrix;
- IM-OLS purifies by transforming the integration order.

Each introduces a different structural cost.

---

## 4. Breakdown under regime switching

Global super-consistent estimators assume a stable long-run relation.

Once regime switching is introduced, this assumption becomes binding. The problem is no longer only second-order bias in a linear cointegrating regression. The problem becomes whether the long-run parameter itself is stable across the sample.

Chen’s threshold-cointegration framework shows why this matters. In threshold models with integrated regressors, the threshold effect may be identified or weakly identified, and inference must account for that distinction. Under serial correlation and endogeneity, Chen proposes a Cochrane-Orcutt FGLS estimator and a generalized sup-Wald test with bootstrap critical values.

Therefore, FGLS is not a general replacement for FM-OLS, DOLS, or IM-OLS. It belongs to a threshold-cointegration layer.

## 5. Diagnostic layer before threshold estimation

Haldrup et al. show that unit roots, structural breaks, and nonlinear mean reversion can mimic one another in persistent macroeconomic series. A process may look nonstationary because it has a unit root, because it has infrequent structural breaks, or because it is stationary but nonlinear.

Therefore, threshold estimation is not the first move.

The prior diagnostic ladder is:

1. assess integration order;
2. test for structural breaks or break-adjusted unit roots;
3. assess nonlinear unit-root alternatives;
4. only then ask whether threshold cointegration is the appropriate regime model.

The key rule is:

> threshold cointegration is admissible only after the nonlinear pattern is not better interpreted as a deterministic break, break-adjusted unit-root problem, or smooth nonlinear mean reversion.

## 6. Threshold-FGLS layer

FGLS becomes relevant only after the regime layer has been independently justified.

In Chen’s framework, FGLS is useful because the threshold model has integrated regressors and may contain endogeneity and serial correlation. The FGLS-based sup-Wald test is designed to test for threshold effects while remaining robust to different error specifications, including I(0) and I(1) errors.

But this does not mean FGLS identifies utilization.

FGLS can support regime-specific coefficient recovery only if:

- the threshold variable is admissible;
- the threshold effect is tested;
- weak identification is handled;
- bootstrap inference is used where required;
- and the resulting coefficients remain interpretable inside the productive-capacity reconstruction sequence.

So the correct chain is:

$$
\text{diagnostic ladder}
\rightarrow
\text{threshold admissibility}
\rightarrow
\text{threshold-FGLS coefficient recovery}
\rightarrow
\hat{\theta}_{regime}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

---

## 7. Implication for $\mu$

Even under super-consistency:

- $\theta_t$ may be estimated;
- $Y_t^p$ must be reconstructed;
- $\mu_t$ must be derived.

This requires:

1. translating the long-run relation into productive capacity;
2. imposing a benchmark normalization;
3. deriving utilization as the ratio between observed output and reconstructed productive capacity.

So:

> coefficient consistency does not imply object consistency.

---

## 8. U.S. case

In the U.S., the long-run transformation relation is comparatively cleaner.

The corrected A00 index $q_t^{\omega,h}$ must first be generated and shown to be integration- and collinearity-admissible. Global super-consistent estimators are appropriate only after that variable-generation gate.

But the gain remains partial:

- strong coefficient recovery;
- conditional productive-capacity reconstruction;
- derived utilization.

Even here, $\mu_t$ depends on the translation from $\hat{\theta}_t$ to $\hat{Y}_t^p$ and on explicit level anchoring.

---

## 9. Chile case

In Chile, the distinction becomes binding.

The previous design attempted to:

- estimate a long-run relation;
- activate regimes through the ECT;
- allow coefficient switching;
- reconstruct $\theta_t$ and $\mu_t$.

This collapses four operations:

1. long-run coefficient recovery;
2. productive-capacity reconstruction;
3. diagnostic classification of the stochastic structure;
4. regime activation.

That collapse is not admissible.

Chen clarifies that threshold-FGLS belongs to a specific threshold-cointegration architecture, not to any generic regime-switching exercise. Haldrup et al. clarify that threshold behavior must first be distinguished from unit roots, structural breaks, and nonlinear mean reversion.

So:

> failure or fragility of DOLS is a specification lesson, not an empirical refutation.

For Chile, the regime layer must be defined only after a diagnostic ladder has established whether the problem is better read as a break, nonlinear adjustment, or threshold cointegration. A generated ECT cannot serve as the primary regime classifier.

---

## 10. Correct separation

### Long-run layer

- identify the transformation relation;
- estimate the long-run coefficient vector;
- assign estimator roles: FM-OLS main, IM-OLS robustness, DOLS fragility.

### Diagnostic layer

- assess integration order;
- assess deterministic components;
- assess structural breaks;
- assess nonlinear unit-root behavior;
- distinguish breaks, nonlinear mean reversion, and threshold equilibria.

### Regime-admissibility layer

- define whether a regime model is warranted;
- use observable variables, historically justified partitions, or tested threshold variables;
- do not use a generated ECT as the regime activator;
- move to threshold-FGLS only if threshold behavior is admissible.

### Threshold-FGLS layer

- estimate regime-specific coefficient vectors only after threshold admissibility is established;
- use sup-Wald and bootstrap inference where required;
- handle weak threshold identification explicitly.

### Reconstruction layer

- recover $\theta_t$ or $\theta_{t,\text{regime}}$;
- construct $Y_t^p$;
- impose level anchoring;
- derive $\mu_t$.

---

## 11. Locked statement

**Super-consistency belongs to A00 first-layer coefficient recovery. The empirical reconstruction of $\mu$ requires a second operation: translating the accumulated-index relation into productive capacity and only then into utilization under an explicit normalization rule.**

## 12. Extended locked statement

**FM-OLS is the preferred estimator for the main log-level reconstruction layer, IM-OLS is a robustness check, and DOLS is a fragility diagnostic. Threshold-FGLS belongs only to a regime layer that has passed the diagnostic ladder separating unit roots, breaks, nonlinear mean reversion, and threshold cointegration. None of these estimators identifies $\mu_t$ directly.**
