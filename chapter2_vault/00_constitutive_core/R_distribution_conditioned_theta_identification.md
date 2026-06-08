---
type: rule_note
status: binding
layer: analytical_foundation
scope: chapter2_core
topic: distribution_conditioned_transformation_elasticity
created: 2026-06-08
updated: 2026-06-08
design_role: specification_governance
---

# Distribution-Conditioned Transformation Elasticity Identification

## Binding rule

Chapter 2 identifies the distribution-conditioned transformation elasticity through accumulated distribution-conditioned capital accumulation. Distribution conditions the conversion of capital growth into productive-capacity growth; it does not operate through a contemporaneous multiplication between distribution and the capital-stock level.

The active aggregate index is:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s.
$$

The binding benchmark relation is:

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

with implied transformation coefficient:

$$
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

The accumulated index is the level-compatible econometric counterpart of a growth-rate transformation theory. It identifies $\theta_t$ where the theory locates it: in the transformation of capital accumulation into productive capacity.

## Superseded route

The former benchmark:

$$
y_t
=
c
+
\beta_1 k_t
+
\beta_2(\omega_t k_t)
+
\xi_t
$$

and its mapping $\theta_t=\beta_1+\beta_2\omega_t$ are superseded as active identification devices. The $\omega_t k_t$ level interaction may appear only in a subsection or note explicitly labeled `superseded`, `rejected`, or `historical record`. It may not define the benchmark, an active implementation export, or an S40 reconstruction input.

## Timing rule

Distribution is inherited when current capital accumulation is converted into capacity. The benchmark therefore uses lagged distribution:

$$
m_{t-1}^{(1)}
=
\omega_{t-1}.
$$

Contemporaneous $\omega_t\Delta k_t$ is not the benchmark. Any alternative timing must be pre-specified, historically interpretable, and treated as robustness.

## Centering rule

The benchmark does not use full-sample centering of $\omega_t$, $m_{t-1}^{(h)}$, or the generated accumulation index. Full-sample centering imports future information into earlier observations and changes the historical meaning of the accumulated path. Local transformations may be used only as clearly labeled diagnostics that do not replace the uncentered benchmark.

## Restricted memory-state menu

The benchmark memory state is:

$$
m_{t-1}^{(1)}
=
\omega_{t-1}.
$$

The pre-specified moving-average robustness states are:

$$
m_{t-1}^{(3)}
=
\frac{1}{3}
\left(
\omega_{t-1}
+
\omega_{t-2}
+
\omega_{t-3}
\right),
$$

and:

$$
m_{t-1}^{(5)}
=
\frac{1}{5}
\sum_{j=1}^{5}
\omega_{t-j}.
$$

Optional exponential-memory robustness is:

$$
m_{t-1}^{(\lambda)}
=
(1-\lambda)\omega_{t-1}
+
\lambda m_{t-2}^{(\lambda)},
$$

with:

$$
\lambda
\in
\{0.25,0.50,0.75\}.
$$

Unrestricted lag-weight estimation is prohibited in the benchmark.

## Generated variables

The aggregate generated indexes are:

$$
q_t^{\omega,1}
=
\sum_{s=1}^{t}
\omega_{s-1}\Delta k_s,
$$

$$
q_t^{\omega,3}
=
\sum_{s=1}^{t}
m_{s-1}^{(3)}\Delta k_s,
$$

$$
q_t^{\omega,5}
=
\sum_{s=1}^{t}
m_{s-1}^{(5)}\Delta k_s.
$$

The machinery generated indexes are:

$$
q_t^{ME,\omega,1}
=
\sum_{s=1}^{t}
\omega_{s-1}\Delta k_s^{ME},
$$

$$
q_t^{ME,\omega,3}
=
\sum_{s=1}^{t}
m_{s-1}^{(3)}\Delta k_s^{ME},
$$

$$
q_t^{ME,\omega,5}
=
\sum_{s=1}^{t}
m_{s-1}^{(5)}\Delta k_s^{ME}.
$$

These variables must be generated and audited before estimation.

## Estimator-family implication

The corrected benchmark remains a single-equation cointegrating regression:

- FM-OLS is the main estimator.
- IM-OLS is the robustness estimator.
- DOLS is the fragility and robustness check.
- Johansen/VECM may provide system-level robustness or rank evidence, but it may not replace the single-equation benchmark.

Before coefficient interpretation, the generated indexes must be checked for missingness and lag-induced sample loss, integration order, correlation with $k_t$, VIF/collinearity, path plausibility, sensitivity to the capital-stock definition, and sensitivity to wage-share versus profit-share conditioning.

Admissibility requires residual ADF evidence, Phillips-Ouliaris or an equivalent cointegration gate when available, an outlier screen, theoretically adjudicated dummy robustness, coefficient-sign coherence, estimator-family agreement, and historical interpretability. Passing one statistical gate never makes a coefficient dissertation-binding.

## Promotion rule

A corrected specification can be promoted only if all conditions hold:

1. It preserves $\theta_t$ as endogenous to distribution.
2. It does not use the rejected $\omega_t k_t$ level interaction as the benchmark device.
3. Its generated index has an explicit inherited-distribution timing rule.
4. Its memory filter is pre-specified.
5. Its residuals pass stationarity and cointegration-admissibility checks.
6. Its coefficients are stable across reasonable estimator variants.
7. Its historical path is interpretable.
8. Human review explicitly promotes it from candidate to reconstruction input.

The corrected object must pass S30/S32 human review before S40 is opened. Existing S40 contracts based on the superseded level interaction do not authorize reconstruction with the corrected specification.

## Governing links

- [[A00_Aggregate_Transformation_Benchmark]]
- [[A03_TransformationElasticity_Two-CapitalCapacityComposition]]
- [[A05_NRCEnvelope_MechanizationBias]]
- [[R10_Binding_Specification_Layering_Rule]]
- [[M10_Empirical_Identification_Framework]]
