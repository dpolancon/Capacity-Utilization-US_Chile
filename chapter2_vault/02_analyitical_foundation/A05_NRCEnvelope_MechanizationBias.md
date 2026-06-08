---
type: note
subtype: object
status: active_pending_human_review
layer: analytical_foundation
design_role: empirical_bridge_definition
scope: chapter2_core
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - A01_Extensive_Accumulation
  - A02_Intensive_Accumulation
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - D01_GPIM_heterogeneous_capital_SFC
  - D02_PriceDeflator_Protocol_K_Composition
  - R10_Binding_Specification_Layering_Rule
pending_tasks:
  - Generate and audit machinery accumulation-weighted indexes.
  - Review corrected candidates through S30/S32.
  - Keep S40 blocked until explicit human promotion.
created: 2026-06-02
updated: 2026-06-08
---

# A05: NRC Envelope and Machinery Accumulation Bias

## Core claim

A05 is the empirical bridge between A03's two-capital growth-rate decomposition and candidate cointegrating specifications. Its governing rule is [[R_distribution_conditioned_theta_identification]].

The nonresidential-structures stock remains the non-distributive extensive envelope:

$$
k_t^{NRC}
=
\log K_t^{NRC}.
$$

Distribution operates through machinery accumulation. The preferred generated object is:

$$
q_t^{ME,\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}
\Delta k_s^{ME}.
$$

This object asks whether machinery accumulation produces different capacity effects under inherited distributive conditions. It does not make the NRC envelope distributive.

## 1. Position in the architecture

A00 remains the aggregate-capital benchmark:

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

A03 decomposes the growth-rate transformation object into machinery and nonresidential-structures channels. A05 supplies the level-compatible accumulated machinery object required to estimate that decomposition.

The sequence is:

```text
A00 aggregate benchmark
-> A03 two-capital growth-rate decomposition
-> A05 machinery accumulation-weighted candidate
-> S30/S32 human review
-> possible S40 promotion
```

A05 does not replace A00 and does not authorize reconstruction.

## 2. Non-distributive NRC envelope

$K_t^{NRC}$ defines plant scale, structures, and the extensive capacity envelope. It enters the decomposed relation directly:

$$
k_t^{NRC}
=
\log K_t^{NRC}.
$$

The benchmark does not interact distribution with $k_t^{NRC}$. Current distributive conditions do not redefine the inherited structures envelope.

## 3. Preferred machinery accumulation-weighted object

The preferred A05 index is:

$$
q_t^{ME,\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}
\Delta k_s^{ME}.
$$

The inherited-distribution benchmark is:

$$
q_t^{ME,\omega,1}
=
\sum_{s=1}^{t}
\omega_{s-1}\Delta k_s^{ME}.
$$

The restricted moving-average robustness indexes are:

$$
q_t^{ME,\omega,3}
=
\sum_{s=1}^{t}
m_{s-1}^{(3)}\Delta k_s^{ME},
$$

and:

$$
q_t^{ME,\omega,5}
=
\sum_{s=1}^{t}
m_{s-1}^{(5)}\Delta k_s^{ME}.
$$

The timing and memory states are inherited from the governing rule. Full-sample centering and unrestricted lag-weight estimation are prohibited in the benchmark.

## 4. Candidate decomposed specification

The preferred candidate is:

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

Interpretation:

- $\beta_{NRC}$ identifies the non-distributive extensive envelope.
- $\beta_{ME}$ identifies the baseline machinery stock contribution.
- $\beta_{\omega ME}$ identifies how inherited distribution conditions the capacity payoff of machinery accumulation.

The generated index must be tested for integration order, correlation with $k_t^{ME}$ and $k_t^{NRC}$, VIF/collinearity, path plausibility, sample loss, capital-stock-definition sensitivity, and wage-share versus profit-share sensitivity before estimation.

## 5. Superseded level interactions

The former preferred device:

$$
\omega_t m_t,
\qquad
m_t
=
k_t^{ME}
-
k_t^{NRC},
$$

is superseded as the preferred A05 route. It is a contemporaneous level interaction and therefore does not identify distribution where the theory locates it: in machinery accumulation.

The direct machinery-stock interaction $\omega_t k_t^{ME}$ is also superseded as a benchmark device. Both may remain only as exploratory or historical comparison specifications.

## 6. Less-preferred ratio accumulation variant

The ratio-based accumulated variant is:

$$
q_t^{m,\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}
\Delta m_s,
$$

where:

$$
m_s
=
k_s^{ME}
-
k_s^{NRC}.
$$

This variant is less preferred because the theory locates distribution more directly in machinery accumulation than in changes in the machinery-to-NRC ratio. It may be retained as a bounded robustness comparison after the preferred machinery index is feasible.

## 7. Estimator and admissibility rule

The A05 candidate remains a single-equation cointegrating regression:

- FM-OLS is the main estimator.
- IM-OLS is the robustness estimator.
- DOLS is the fragility/robustness check.
- Johansen/VECM is system-level robustness only.

Residual ADF and Phillips-Ouliaris or an equivalent cointegration gate must support admissibility. Outlier and dummy robustness follows theoretical adjudication; it cannot be used to manufacture a passing specification. Coefficient signs, estimator-family agreement, and historical interpretability remain required.

## 8. Promotion boundary

The corrected A05 object is a candidate reconstruction input, not a reconstruction input.

S40 remains blocked until:

1. the preferred generated indexes are constructed;
2. feasibility and integration diagnostics are reviewed;
3. S30/S32 estimation is completed;
4. estimator-family results are compared;
5. human review explicitly promotes a coefficient object.

Existing VIF results for $\omega_t m_t$ do not transfer to $q_t^{ME,\omega,h}$.

## Locked formulation

A05 preserves $k_t^{NRC}$ as a non-distributive extensive envelope and makes distribution operate through machinery accumulation:

$$
q_t^{ME,\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}
\Delta k_s^{ME}.
$$

The preferred decomposed candidate is:

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

The former $\omega_t m_t$ and $\omega_t k_t^{ME}$ level interactions are exploratory or superseded, and S40 remains blocked pending S30/S32 human promotion.
