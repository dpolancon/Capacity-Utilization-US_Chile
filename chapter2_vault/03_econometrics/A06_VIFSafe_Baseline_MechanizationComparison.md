---
type: note
subtype: object
status: superseded
layer: analytical_foundation
design_role: specification_lock
scope: chapter2_core
estimator_status: historical-or-diagnostic
requires_review_before_use: true
related_to:
  - A00_Aggregate_Transformation_Benchmark
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - A05_NRCEnvelope_MechanizationBias
  - R10_Binding_Specification_Layering_Rule
  - D04_ME_NRC_LogRatio_Construction_Protocol
  - C04-US_S30_STABILITY_PROTOCOL
  - US_S31_model_choice_vif_screen
lock_status:
  comparison_pair: locked
  final_model: not_selected
  s40_status: parked
  human_adjudication_required: true
locked_specs:
  - SPEC_B1_WAGE_BASELINE
  - SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
vif_status:
  SPEC_B1_WAGE_BASELINE: vif_admissible_with_caution
  SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED: vif_safe
created: 2026-06-02
updated: 2026-06-08
role: superseded-for-baseline
stage: pre-estimation-design
aliases:
  - A06 VIF comparison
tags:
  - chapter2/econometrics
  - chapter2/superseded
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---



# A06: VIF-Safe Baseline and Mechanization-Bias Comparison Pair

> [!gate] D12V2 gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.


> [!important] D12V2 status
> The active Chapter 2 baseline-design candidate is Restricted DOLS, not generic DOLS.
> Restricted DOLS keeps nonlinear/interacted terms in the long-run level equation and restricts dynamic corrections to admissible base-variable differences.
> See [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]].


> [!gate] D12V interaction-term gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.
> Restricted DOLS is preferred only after base-variable integration status, interaction-term status, and sample-window adequacy are classified.

> [!warning] Superseded comparison
> This note preserves the June 2, 2026 VIF comparison for former specifications. Neither `SPEC_B1_WAGE_BASELINE` nor `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED` is the active benchmark after [[R_distribution_conditioned_theta_identification]]. The current fork is primitive scale-conditioning versus centered composition-mediated conditioning. This note is historical and not promotion-eligible.

## Core claim

A06 locks the specification pair that will structure the next human review of the US transformation relation.

The comparison pair is:

```text
SPEC_B1_WAGE_BASELINE
```

and:

```text
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
```

This lock does not select a final model. It defines the VIF-admissible comparison set to be evaluated before any later estimation, adjudication, or reconstruction step.

The purpose of A06 is to prevent the code layer from drifting across specification families. The next empirical comparison is not open-ended. It is restricted to:

```text
A00 baseline
versus
A05 NRC-envelope / distribution-conditioned mechanization-bias candidate
```

---

## 1. Baseline specification: A00/B1

The A00 baseline remains:

$$
y_t = c + \beta_k k_t + \beta_{\omega k}(\omega_t k_t) + \xi_t.
$$

with:

$$
\omega_{k,t} = \omega_t k_t.
$$

The implied aggregate transformation path is:

$$
\theta_t^{A00} = \beta_k + \beta_{\omega k}\omega_t.
$$

Implementation label:

```text
SPEC_B1_WAGE_BASELINE
```

Formula label:

```text
y_t ~ k_t + omega_k_t
```

Interpretation:

```text
aggregate capital envelope + distribution-conditioned aggregate transformation path
```

A06 keeps B1 as the baseline review object because it is the binding A00 benchmark. It is not displaced by A05. Any A05 comparison must be read against this baseline.

---

## 2. Mechanization-bias candidate: A05/E2B

The A05 candidate locked for comparison is:

```text
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
```

Formula label:

```text
y_t ~ k_NRC_t + omega_m_ME_NRC_t
```

where:

$$
k_t^{NRC} = \log K_t^{NRC},
$$

$$
m_t = k_t^{ME} - k_t^{NRC}
= \log\left(\frac{K_t^{ME}}{K_t^{NRC}}\right),
$$

and:

$$
\omega_{m,t} = \omega_t m_t.
$$

Interpretation:

```text
NRC envelope + distribution-conditioned mechanization-bias channel
```

This specification keeps the structural envelope and the tactical/distributive mechanism distinct:

```text
K_NRC = extensive plant-scale envelope
m_ME_NRC = mechanization-bias index
omega_m_ME_NRC = distribution-conditioned mechanization-bias channel
```

The raw mechanization-bias level (m_t) does not enter separately in E2B. That restriction is precisely what makes the specification collinearity-safe relative to the full E2A version.

---

## 3. Why E2B is preferred over E2A for the next comparison

The full A05 specification is:

```text
SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL
y_t ~ k_NRC_t + m_ME_NRC_t + omega_m_ME_NRC_t
```

E2A is analytically rich, but it is not VIF-safe in the current US screen. It includes both the raw mechanization-bias level (m_t) and the distribution-conditioned mechanization-bias term (\omega_t m_t). In the current data, those variables become too entangled in key windows.

A06 therefore does not lock E2A for the next estimation comparison.

The restricted E2B specification is preferred because it preserves the core A05 mechanism while avoiding the major collinearity trap:

```text
distribution acts through mechanization bias;
distribution does not interact directly with the NRC envelope;
the raw mechanization-bias level is omitted from the restricted candidate.
```

---

## 4. VIF screen result

The current S31 model-choice VIF screen reports:

```text
SPEC_B1_WAGE_BASELINE
max VIF: 5.934
high-VIF windows: 0
status: VIF-admissible with caution
```

and:

```text
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
max VIF: 1.395
high-VIF windows: 0
status: VIF-safe
```

A06 interprets these results as follows:

```text
B1 remains the baseline review object.
E2B is the preferred A05 candidate for comparison.
Both specifications clear the high-VIF exclusion screen.
E2B is substantially cleaner than B1 on collinearity grounds.
```

This does not mean E2B is empirically superior. It means E2B is sufficiently collinearity-safe to be considered in the next governed estimation pass.

---

## 5. Comparison logic

The next model-choice review should compare:

### Baseline

```text
SPEC_B1_WAGE_BASELINE
y_t ~ k_t + omega_k_t
```

### A05 restricted mechanization-bias candidate

```text
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
y_t ~ k_NRC_t + omega_m_ME_NRC_t
```

The comparison asks:

```text
Does the aggregate A00 distributive-interaction baseline remain adequate,
or does the A05 NRC-envelope / distribution-conditioned mechanization-bias specification provide a better structured empirical object?
```

The comparison is not a mechanical horse race. It must be adjudicated through:

1. coefficient signs;

2. estimator triangulation;

3. window behavior;

4. VIF and collinearity diagnostics;

5. conceptual consistency with A01, A02, A03, A05, D04, and R10;

6. reconstruction eligibility only after human adjudication.


---

## 6. Status of other specifications

A06 does not promote or lock the following specifications for the next comparison.

### B0

```text
SPEC_B0_CAPITAL_ONLY
```

Status:

```text
reference-only
not baseline
not part of A06 comparison pair
```

### C1

```text
SPEC_C1_COMPOSITION_STOCK
```

Status:

```text
A03 proxy-escalation
reviewable but not part of the locked A06 comparison pair
```

C1 remains useful as a proxy-composition reference, but A06 prioritizes the theoretically sharper A05 restricted candidate.

### C2

```text
SPEC_C2_FULL_COMPOSITION
```

Status:

```text
A03 proxy-escalation
VIF-fragile
not part of the locked A06 comparison pair
```

### E1

```text
SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS
```

Status:

```text
A05 candidate
VIF-feasible
not selected for the locked A06 comparison pair
```

E1 is VIF-feasible, but it lacks the distribution-conditioned mechanization-bias channel. It may remain a supporting candidate or robustness object after E2B is assessed.

### E2A

```text
SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL
```

Status:

```text
A05 candidate
VIF-blocked before estimation or promotion
not part of the locked A06 comparison pair
```

### D1/D2

```text
SPEC_D1_CURRENT_COST_DIAGNOSTIC
SPEC_D2_PRICE_WEDGE_DIAGNOSTIC
```

Status:

```text
diagnostic-only
non-promotable
not part of the locked A06 comparison pair
```

---

## 7. Relation to estimation

A06 authorizes the next estimation design to focus on the B1 versus E2B comparison.

This authorization is limited.

A06 permits:

```text
prepare an S32 or S30b estimation pass comparing B1 and E2B
```

A06 does not permit:

```text
S40 reconstruction
final model selection
automatic promotion of E2B
retroactive replacement of A00
use of E2B as a reconstruction object without human adjudication
```

The E2B specification is now VIF-safe for estimation review, not dissertation-final.

---

## 8. Relation to S40

S40 remains parked.

Neither B1 nor E2B is automatically S40-eligible from A06 alone.

S40 can only be unparked after human adjudication decides:

1. which specification is admissible;

2. which window is admissible;

3. which estimator is the reconstruction basis;

4. whether robustness and fragility checks support the selected coefficient object;

5. whether the selected object should reconstruct (\theta_t), (Y^p), and (\mu_t).


Until then:

```text
S40 status = parked
```

---

## 9. Locked comparison pair

A06 locks the next comparison pair as:

```text
Baseline:
SPEC_B1_WAGE_BASELINE
y_t ~ k_t + omega_k_t
```

and:

```text
A05 restricted mechanization-bias candidate:
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
y_t ~ k_NRC_t + omega_m_ME_NRC_t
```

This pair is the governed model-choice object for the next US estimation review.

---

## Locked formulation

A06 locks the VIF-admissible comparison pair for the next US model-choice review. The baseline specification is `SPEC_B1_WAGE_BASELINE`, the A00 aggregate distributive-interaction relation (y_t \sim k_t + \omega_t k_t). The preferred A05 candidate is `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED`, (y_t \sim k_t^{NRC} + \omega_t m_t), where (m_t = \log(K_t^{ME}/K_t^{NRC})). E2B preserves the analytical asymmetry between NRC as extensive envelope and ME/NRC as distribution-conditioned mechanization bias while passing the VIF screen cleanly. A06 authorizes a future B1-versus-E2B estimation comparison but does not select a final model, does not authorize S40 reconstruction, and does not override the requirement of human adjudication.
