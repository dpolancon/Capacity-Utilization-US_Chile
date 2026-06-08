---
type: note
status: active
layer: method
design_role: diagnostic_to_regime_bridge
scope: chapter2_core_support
related_to:
  - R07_FGLS_threshold_cointegration_admissibility
  - R03_super_consistency_mechanics_hinge
  - R05_LRV_kernel_bandwidth_regime_misalignment
  - N02_SuperConsistency
  - M10_Empirical_Identification_Framework
  - L00_Econometrics_References
priority: high
---

# From Break Diagnostics to Threshold-FGLS

## Core claim

Threshold-FGLS is not the first response to global estimator fragility.

Before threshold-FGLS becomes admissible, the empirical design must distinguish between unit-root persistence, structural breaks, nonlinear mean reversion, and threshold cointegration.

The diagnostic ladder comes first. The regime estimator comes second.

## 1. Diagnostic problem

Persistent macroeconomic series can look similar for different reasons.

A series may appear nonstationary because it has:

- a unit root;
- a structural break;
- nonlinear mean reversion;
- threshold behavior;
- or misspecified deterministic components.

These are not equivalent.

Each implies a different empirical architecture.

## 2. Haldrup diagnostic ladder

Haldrup et al. organize the diagnostic problem around unit roots, nonlinearities, and structural breaks.

Their key implication for Chapter 2 is that regime-sensitive estimation cannot begin until the stochastic source of persistence has been disciplined.

The relevant diagnostic questions are:

1. Is the series integrated?
2. Are deterministic components correctly specified?
3. Are there structural breaks?
4. Does break-adjusted unit-root testing change the inference?
5. Is nonlinear mean reversion present?
6. Is threshold behavior more plausible than breaks or smooth nonlinear adjustment?

## 3. Chen threshold-estimation ladder

Chen enters only after threshold behavior is admissible.

Chen’s framework concerns threshold models with integrated regressors. It deals with:

- threshold effects in cointegrating relations;
- weak versus strong threshold identification;
- serial correlation;
- endogeneity;
- FGLS estimation;
- sup-Wald testing;
- bootstrap inference.

So Chen does not replace the diagnostic ladder.

Chen governs the estimation layer once the diagnostic ladder justifies threshold cointegration.

## 4. Breaks versus thresholds

Structural breaks and thresholds are conceptually distinct.

A structural break is a historical shift in the relation itself, often tied to a date or institutional rupture.

A threshold is a recurrent state-dependent switch activated when an observed variable crosses a boundary.

This distinction matters for Chile.

If the relation changes because of an institutional rupture, a break or historically partitioned design may be more appropriate.

If the relation switches because an observed state variable crosses a threshold, threshold cointegration may be admissible.

## 5. Rule against ECT activation

A generated ECT should not be the primary regime activator.

If the long-run relation is unstable, the ECT inherits the instability of the estimated relation.

Using it to activate regimes would collapse:

1. long-run estimation;
2. regime diagnosis;
3. regime activation.

That collapse is not admissible.

## 6. Correct pipeline

The admissible sequence is:

$$
\text{object admissibility}
\rightarrow
\text{unit-root and break diagnostics}
\rightarrow
\text{nonlinear diagnostic checks}
\rightarrow
\text{threshold admissibility}
\rightarrow
\text{threshold-FGLS}
\rightarrow
\text{regime-specific reconstruction}.
$$

Only after this sequence can the coefficients enter:

$$
\hat{\theta}_{t,\text{regime}}
\rightarrow
\hat{Y}_t^p
\rightarrow
\hat{\mu}_t.
$$

## 7. Methodological lock

Threshold cointegration is not a robustness check.

It is a structural claim about regime-dependent equilibrium.

Therefore, it must be justified by diagnostics and by the theoretical meaning of the threshold variable.

## 8. Locked sentence for reuse

**Haldrup organizes the diagnostic ladder; Chen organizes the threshold-estimation ladder. Chapter 2 must pass through the diagnostic ladder before FGLS can be treated as admissible regime-specific estimation.**

---

## References

Chen, H. (2013). *Robust estimation and inference for threshold models with integrated regressors*. Wang Yanan Institute for Studies in Economics, Xiamen University.

Haldrup, N., Kruse, R., Teräsvirta, T., & Varneskov, R. T. (2012). *Unit roots, nonlinearities and structural breaks* (CREATES Research Paper 2012-14). Aarhus University.

Hansen, B. E. (2000). Sample splitting and threshold estimation. *Econometrica, 68*(3), 575–603.

Perron, P. (1989). The great crash, the oil price shock, and the unit root hypothesis. *Econometrica, 57*(6), 1361–1401.

Zivot, E., & Andrews, D. W. K. (1992). Further evidence on the great crash, the oil-price shock, and the unit-root hypothesis. *Journal of Business & Economic Statistics, 10*(3), 251–270.