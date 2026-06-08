---
type: note
status: active
layer: method
design_role: regime_architecture_rule
scope: chapter2_core_support
related_to:
  - R03_super_consistency_mechanics_hinge
  - R04_FMOLS_structural_preservation
  - R05_LRV_kernel_bandwidth_regime_misalignment
  - R06_IMOLS_integration_ladder_reconstruction
  - R08_threshold_break_diagnostics_to_FGLS
  - M10_Empirical_Identification_Framework
  - L00_Econometrics_References
priority: high
---

# FGLS and Threshold-Cointegration Admissibility

## Core claim

FGLS becomes relevant only at the regime layer.

It is not a substitute for cointegration identification, not a general replacement for FM-OLS, and not a direct estimator of capacity utilization.

Its admissible role is narrower: once threshold behavior is justified, FGLS can support regime-specific coefficient recovery in threshold models with integrated regressors, serial correlation, and endogeneity.

---

## 1. The wall of global estimators

DOLS, FM-OLS, and IM-OLS are global long-run estimators.

They can recover long-run coefficient vectors under cointegration, but they assume that the relevant relation is stable across the sample.

If the relation changes across regimes, the global estimate can average over distinct parameter vectors:

$$
\theta_1 \neq \theta_2
\quad \Rightarrow \quad
\hat{\theta}_{global}
\neq
\text{a clean regime-specific parameter}.
$$

So the problem is no longer only second-order asymptotic bias.

The problem becomes regime admissibility.

---

## 2. Threshold-FGLS is not the first move

Threshold-FGLS cannot be used simply because global estimators are fragile.

Before threshold-FGLS is admissible, the diagnostic layer must establish that the observed nonlinearity is better interpreted as threshold cointegration rather than:

- a unit-root problem,
- a deterministic structural break,
- a break-adjusted unit-root problem,
- smooth nonlinear mean reversion,
- or misspecified deterministic components.

This is the Haldrup diagnostic constraint.

The regime estimator cannot substitute for the diagnostic ladder.

---

## 3. What Chen adds

Chen’s threshold framework studies models with integrated regressors in which the long-run coefficient vector changes when an observed threshold variable crosses an unknown threshold.

The threshold effect may be strongly identified or weakly identified.

That matters because weak identification changes the behavior of the threshold estimator and requires robust confidence intervals.

Chen’s contribution is therefore not simply “use FGLS.”

It is:

- estimate threshold models with integrated regressors;
- account for weak versus strong threshold identification;
- handle serial correlation and endogeneity;
- use Cochrane-Orcutt FGLS for the generalized model;
- use sup-Wald testing and bootstrap inference for threshold effects.

---

## 4. Regime activation rule

A generated ECT should not automatically activate regimes.

If the long-run relation is unstable, the ECT inherits that instability and becomes a polluted classifier.

Regimes should therefore be activated by:

- observable threshold variables,
- historically justified partitions,
- externally defined institutional transitions,
- or structural indicators whose meaning does not depend on the generated residual.

The threshold variable must be part of the regime architecture, not an accidental by-product of the previous estimation step.

---

## 5. What FGLS can do

FGLS can be used after the regime layer is justified.

Its role is to correct within-regime error structure and support regime-specific coefficient recovery when serial correlation and endogeneity are present.

It can be admissible when:

- the threshold variable is meaningful;
- threshold behavior is tested;
- weak identification is addressed;
- the sample within regimes is empirically usable;
- and the resulting coefficients remain interpretable inside the productive-capacity reconstruction sequence.

---

## 6. What FGLS cannot do

FGLS does not identify cointegration by itself.

It does not justify the threshold variable by itself.

It does not distinguish threshold behavior from structural breaks by itself.

It does not validate productive capacity by itself.

It does not turn the residual into utilization.

Therefore, FGLS is not a reconstruction engine.

It is a regime-layer coefficient-recovery tool.

---

## 7. Reconstruction implication

If threshold-FGLS is admissible, productive capacity must be reconstructed through regime-specific coefficients:

$$
\text{threshold-FGLS coefficient recovery}
\rightarrow
\hat{\theta}_{t,\text{regime}}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

The utilization series still requires:

- structural interpretation;
- empirical discipline;
- level anchoring;
- and avoidance of residual identification.

---

## 8. Methodological lock

FGLS should be assigned the following role:

- not the main global estimator;
- not a replacement for FM-OLS;
- not a direct estimator of utilization;
- yes, a regime-layer estimator after threshold admissibility has been established.

The correct use is:

$$
\text{diagnostic ladder}
\rightarrow
\text{threshold admissibility}
\rightarrow
\text{threshold-FGLS}
\rightarrow
\text{productive-capacity reconstruction}.
$$

---

## 9. Locked sentence for reuse

**FGLS is admissible only after threshold behavior has been independently justified. It can support regime-specific coefficient recovery under threshold cointegration, but it cannot identify cointegration, activate regimes, or reconstruct utilization by itself.**

---

## References

Balke, N. S., & Fomby, T. B. (1997). Threshold cointegration. *International Economic Review, 38*(3), 627–645.

Chen, H. (2013). *Robust estimation and inference for threshold models with integrated regressors*. Wang Yanan Institute for Studies in Economics, Xiamen University.

Haldrup, N., Kruse, R., Teräsvirta, T., & Varneskov, R. T. (2012). *Unit roots, nonlinearities and structural breaks* (CREATES Research Paper 2012-14). Aarhus University.

Hansen, B. E. (2000). Sample splitting and threshold estimation. *Econometrica, 68*(3), 575–603.