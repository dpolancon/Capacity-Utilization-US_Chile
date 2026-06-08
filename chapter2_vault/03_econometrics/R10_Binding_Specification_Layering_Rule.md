---
type: rule_note
status: binding
layer: method
scope: chapter2_core
design_role: specification_layering
created: 2026-06-02
updated: 2026-06-08
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - A05_NRCEnvelope_MechanizationBias
  - M10_Empirical_Identification_Framework
---

# R10: Binding Specification Layering Rule

## Core rule

[[R_distribution_conditioned_theta_identification]] governs every specification layer.

```text
A00 accumulated aggregate index = binding benchmark
A03/A05 accumulated machinery index = decomposed candidate
old level interactions = superseded or exploratory only
Johansen/VECM = system robustness only
S40 = blocked until S30/S32 human promotion
```

No code output promotes itself. A specification becomes eligible for reconstruction only after the analytical object, generated variables, diagnostics, estimator comparison, and human adjudication are complete.

## 1. Binding A00 benchmark

The A00 benchmark is:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s,
$$

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

with:

$$
\theta_t
=
\theta_0
+
\theta_\omega m_{t-1}^{(h)}.
$$

The benchmark uses $m_{t-1}^{(1)}=\omega_{t-1}$. Three-year and five-year moving averages are restricted robustness states. No full-sample centering or unrestricted lag-weight estimation is permitted.

## 2. Superseded benchmark layer

The former `SPEC_B1_WAGE_BASELINE` based on `omega_k_t = omega_t * k_t` is superseded as the binding benchmark. It may remain in historical tables and reports only when labeled:

```text
superseded_level_interaction
not_promotion_eligible
not_s40_eligible
```

The same restriction applies to $\omega_t m_t$ and $\omega_t k_t^{ME}$ level interactions.

## 3. A03/A05 candidate layer

The preferred decomposed generated index is:

$$
q_t^{ME,\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s^{ME}.
$$

The candidate relation is:

$$
y_t^p
=
\alpha
+
\beta_{NRC}k_t^{NRC}
+
\beta_{ME}k_t^{ME}
+
\beta_{\omega ME}q_t^{ME,\omega,h}
+
u_t.
$$

This candidate preserves the NRC envelope as non-distributive and makes distribution operate through machinery accumulation. It is not an A00 replacement and is not S40-eligible before review.

The ratio accumulation variant $q_t^{m,\omega,h}$ is less preferred and robustness-only.

## 4. Variable-generation gate

Corrected variables must exist before estimation. Required aggregate indexes are:

```text
q_omega_1
q_omega_3
q_omega_5
```

Required machinery indexes are:

```text
q_ME_omega_1
q_ME_omega_3
q_ME_omega_5
```

Every export must record:

```text
distribution_measure
timing_rule
memory_state
centering_rule
capital_stock_definition
first_valid_year
missing_observations
```

## 5. Feasibility gate

Before any corrected specification enters estimation, review:

1. missingness and sample loss from lagging;
2. integration order;
3. correlation with $k_t$ and component stocks;
4. VIF and collinearity;
5. the historical index path;
6. sensitivity to the capital-stock definition;
7. wage-share versus profit-share sensitivity.

Prior VIF results for level interactions do not transfer to accumulated indexes.

## 6. Estimation and admissibility

Estimator roles are:

```text
FM-OLS = main
IM-OLS = robustness
DOLS = fragility/robustness check
Johansen/VECM = system-level robustness only
```

Admissibility requires:

1. residual ADF stationarity evidence;
2. Phillips-Ouliaris or equivalent cointegration evidence when available;
3. outlier screening;
4. dummy robustness only after theoretical adjudication;
5. coherent coefficient signs;
6. estimator-family agreement;
7. historical interpretability.

No coefficient becomes binding because it passes one gate.

## 7. Specification statuses

Allowed statuses are:

```text
A00_corrected_benchmark_candidate
A03_A05_corrected_candidate
superseded_level_interaction
diagnostic_only
reference_only
promoted_for_reconstruction
```

Only `promoted_for_reconstruction` may be consumed by S40.

## 8. Promotion rule

A corrected specification can be promoted only if:

1. $\theta_t$ remains endogenous to distribution;
2. the old level interaction is absent from the benchmark;
3. timing is explicit;
4. memory is pre-specified;
5. residual stationarity and cointegration gates pass;
6. estimator variants are stable;
7. the historical path is interpretable;
8. human review explicitly promotes it.

## 9. S30/S32/S40 sequence

```text
generated-variable construction
-> feasibility diagnostics
-> S30 aggregate corrected benchmark
-> S32 decomposed candidate if authorized
-> human adjudication
-> possible S40 reconstruction
```

Existing S40 contracts based on `SPEC_B1_WAGE_BASELINE` do not authorize the corrected object. S40 remains untouched until a corrected coefficient object is promoted.

## Locked formulation

The accumulated distribution-conditioned capital-growth index is the binding A00 benchmark device. The machinery accumulation-weighted index is the preferred A03/A05 candidate device. Level interactions are superseded or exploratory, and no corrected coefficient object reaches S40 without S30/S32 human promotion.
