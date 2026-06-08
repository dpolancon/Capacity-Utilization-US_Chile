
# R10: Binding Specification Layering Rule

## Core rule

R10 defines how empirical specifications are allowed to enter the Chapter 2 econometric workflow.

The rule is simple:

```text
A00 is the binding baseline.
A03 specifications are escalation mechanisms.
A05 specifications are candidate mechanisms until authorized.
Diagnostic specifications are non-promotable.
S40 cannot consume any coefficient object until human adjudication explicitly promotes it.
```

No code layer may treat an available specification as admissible merely because it can be estimated.

No reconstruction layer may consume a coefficient object merely because it exists in an output table.

A specification becomes binding only when it satisfies the sequence defined in this rule.

---

## 1. Why this rule exists

The Chapter 2 codebase is downstream of the analytical vault.

The code must not decide the conceptual status of a specification. It may execute an authorized design, report estimates, compute diagnostics, or prepare review tables, but it cannot promote a candidate specification into the dissertation architecture by convenience.

This rule prevents four forms of drift:

1. treating A03 mechanisms as replacements for A00;
    
2. treating diagnostic specifications as admissible reconstruction inputs;
    
3. letting S40 reconstruct capacity before S30/S32 has passed human adjudication;
    
4. letting code-generated outputs govern the analytical foundation.
    

The correct order is:

```text
analytical object
→ admissibility rule
→ VIF / diagnostic feasibility
→ estimation
→ human adjudication
→ possible reconstruction
```

Not:

```text
code output
→ retroactive theory
```

---

## 2. Baseline layer: A00

A00 is the binding baseline econometric object.

The A00 baseline relation is:

$$  
y_t = c + \beta_k k_t + \beta_{\omega k}(\omega_t k_t) + \xi_t.  
$$

The implementation variable is:

$$  
\omega_{k,t} = \omega_t k_t.  
$$

The implied aggregate transformation path is:

$$  
\theta_t^{A00} = \beta_k + \beta_{\omega k}\omega_t.  
$$

Within the current implementation, the binding A00 baseline specification is:

```text
SPEC_B1_WAGE_BASELINE
y_t ~ k_t + omega_k_t
```

This is the baseline for human review.

The capital-only specification:

```text
SPEC_B0_CAPITAL_ONLY
y_t ~ k_t
```

is not the Chapter 2 baseline. It is a reference/null comparison only.

---

## 3. A03 proxy-escalation layer

A03 opens the A00 aggregate transformation relation into capital-composition mechanisms.

Current S30 contains A03 proxy-escalation specifications:

```text
SPEC_C1_COMPOSITION_STOCK
y_t ~ k_t + omega_k_t + s_proxy_k_t
```

and:

```text
SPEC_C2_FULL_COMPOSITION
y_t ~ k_t + omega_k_t + s_proxy_k_t + omega_s_proxy_k_t
```

These specifications are review-eligible A03 proxy specifications.

They are not baseline replacements.

They are not direct NFCorp-by-asset-type ME/NRC estimates unless the data layer explicitly provides such a direct split.

Their role is to test whether the A00 aggregate transformation path is modified by ME/NRC composition proxies.

---

## 4. A05 candidate layer: NRC envelope and mechanization bias

A05 defines a candidate A03 mechanism that separates:

```text
NRC = extensive envelope
ME/NRC = mechanization-bias index
omega × ME/NRC = distribution-conditioned mechanization-bias channel
```

The operative variables are:

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

The A05 candidate specifications are:

```text
SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS
y_t ~ k_NRC_t + m_ME_NRC_t
```

```text
SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL
y_t ~ k_NRC_t + m_ME_NRC_t + omega_m_ME_NRC_t
```

```text
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
y_t ~ k_NRC_t + omega_m_ME_NRC_t
```

These E-specifications are analytically defined but not automatically authorized for estimation.

Their initial status is:

```text
A03_candidate
vif_only_until_authorized
not_S40_eligible
```

---

## 5. Diagnostic layer

Diagnostic specifications are non-promotable unless a later rule explicitly reclassifies them.

Current diagnostic specifications include:

```text
SPEC_D1_CURRENT_COST_DIAGNOSTIC
```

and:

```text
SPEC_D2_PRICE_WEDGE_DIAGNOSTIC
```

Diagnostic specifications may be useful for fragility checks, price-wedge checks, or measurement sensitivity.

They cannot define the baseline.

They cannot replace A03.

They cannot feed S40 reconstruction.

They cannot be promoted merely because they display convenient signs, significance, or smoother behavior.

---

## 6. Binding specification ladder

Every specification must be assigned to one and only one layer:

```text
A00_baseline
A03_proxy_escalation
A03_candidate
diagnostic_only
reference_only
```

The admissibility ladder is:

```text
reference_only
→ may be reported but not promoted

diagnostic_only
→ may be reported but not promoted

A03_candidate
→ VIF-only feasibility first

A03_proxy_escalation
→ may be estimated if already authorized

A00_baseline
→ binding baseline for review
```

A specification cannot skip levels.

An A03 candidate cannot become an estimated S30/S32 object until a governance note or explicit human review authorizes that move.

An estimated object cannot become a reconstruction object until human adjudication promotes it.

---

## 7. VIF feasibility rule

All new A03 candidate specifications must pass VIF/collinearity feasibility checks before estimation.

For A05 E-specifications, S31 or a related review layer may compute VIF-only diagnostics.

That VIF-only pass may construct:

```text
k_NRC_t
m_ME_NRC_t
omega_m_ME_NRC_t
```

from the S20 panel.

But VIF-only diagnostics do not estimate coefficients.

They do not authorize S40.

They do not convert E-specifications into S30 estimates.

Their sole function is to answer:

```text
Can this specification family plausibly separate its RHS variables enough to justify future estimation?
```

VIF interpretation:

```text
VIF < 5        low collinearity concern
5 <= VIF < 10 moderate collinearity concern
VIF >= 10     high collinearity concern
```

High VIF is not automatic theoretical rejection, but it blocks coefficient interpretation unless a later note gives a reason to proceed.

---

## 8. Estimation authorization rule

A candidate specification may enter S30b/S32 estimation only after three conditions are met:

1. the analytical object has been defined in the vault;
    
2. the governing rule classifies the specification as estimable;
    
3. VIF/collinearity diagnostics do not block coefficient interpretation.
    

For A05, this means:

```text
E1/E2 cannot enter S30b/S32 only because they are mathematically constructible.
```

They may enter only after the VIF-only pass is reviewed.

If the candidate VIF diagnostics show high collinearity, the specification remains parked.

If the candidate VIF diagnostics are acceptable, the candidate may be moved to:

```text
A03_candidate_estimation_authorized
```

but still not to S40.

---

## 9. Human adjudication rule

Estimation does not equal promotion.

A coefficient object becomes eligible for S40 only after human adjudication.

Human adjudication must decide:

1. which specification family is being reviewed;
    
2. which window is admissible;
    
3. which estimator is the reconstruction basis;
    
4. whether IM-OLS supports or weakens the FM-OLS result;
    
5. whether DOLS flags fragility;
    
6. whether VIF or rolling diagnostics undermine coefficient interpretation;
    
7. whether the estimated object is conceptually consistent with the analytical foundation.
    

Until this decision is made, S40 remains parked.

---

## 10. S40 consumption rule

S40 may consume only an explicitly promoted coefficient object.

S40 cannot consume:

1. reference-only specifications;
    
2. diagnostic-only specifications;
    
3. VIF-only candidate specifications;
    
4. unreviewed S30/S32 estimates;
    
5. A03 candidate estimates that have not passed human adjudication.
    

S40 is a reconstruction layer.

It does not choose specifications.

It does not choose windows.

It does not choose anchors.

It does not decide whether A00, A03, or A05 is correct.

It only reconstructs after a coefficient object has been promoted.

---

## 11. Rules for code manifests

All code manifests and exported tables must identify each specification with the following fields:

```text
spec_id
formula_label
architecture_layer
identification_role
specification_layer
baseline_replacement_allowed
promotion_eligible
diagnostic_only
vif_only_candidate
estimated_in_s30
estimated_in_s32
s40_eligible
human_adjudication_status
```

Allowed values for `specification_layer` are:

```text
A00_baseline
A03_proxy_escalation
A03_candidate
diagnostic_only
reference_only
```

Allowed values for `human_adjudication_status` are:

```text
not_required_reference
pending_review
parked_collinearity
rejected
promoted_for_reconstruction
```

Only specifications with:

```text
human_adjudication_status = promoted_for_reconstruction
```

may be consumed by S40.

---

## 12. Current status of known specifications

Current classification:

```text
SPEC_B0_CAPITAL_ONLY
layer: reference_only
S40 eligible: no
```

```text
SPEC_B1_WAGE_BASELINE
layer: A00_baseline
S40 eligible: only after human adjudication
```

```text
SPEC_C1_COMPOSITION_STOCK
layer: A03_proxy_escalation
S40 eligible: only after human adjudication
```

```text
SPEC_C2_FULL_COMPOSITION
layer: A03_proxy_escalation
S40 eligible: only after human adjudication
collinearity status: currently fragile unless diagnostics say otherwise
```

```text
SPEC_D1_CURRENT_COST_DIAGNOSTIC
layer: diagnostic_only
S40 eligible: no
```

```text
SPEC_D2_PRICE_WEDGE_DIAGNOSTIC
layer: diagnostic_only
S40 eligible: no
```

```text
SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS
layer: A03_candidate
current status: VIF-only until authorized
S40 eligible: no
```

```text
SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL
layer: A03_candidate
current status: VIF-only until authorized
S40 eligible: no
```

```text
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
layer: A03_candidate
current status: VIF-only until authorized
S40 eligible: no
```

---

## 13. Relation to S31

S31 is a review-export layer.

It may:

1. report existing S30 estimates;
    
2. export LaTeX tables;
    
3. compute VIF diagnostics;
    
4. compute VIF-only diagnostics for candidate specifications;
    
5. document absent specifications.
    

S31 may not:

1. estimate new models;
    
2. promote specifications;
    
3. choose reconstruction windows;
    
4. reconstruct (\theta_t);
    
5. reconstruct productive capacity;
    
6. compute utilization;
    
7. activate S40.
    

S31 exists to support human adjudication, not to replace it.

---

## 14. Relation to S32

S32 is reserved for candidate specification checks or robustness extensions.

S32 may be created if and only if R10 or a later rule authorizes a candidate specification family for estimation.

For A05, S32 may eventually estimate E1/E2 specifications only if the VIF-only feasibility pass is acceptable and human review authorizes estimation.

S32 outputs are still not S40-eligible until human adjudication promotes a coefficient object.

---

## 15. Boundary with A00 and A03

R10 does not alter A00.

R10 does not alter A03.

R10 governs how empirical specifications are layered under A00 and A03.

A00 remains the baseline.

A03 remains the mechanism-opening layer.

A05 remains a candidate A03 empirical bridge until authorized.

The sequence is:

```text
A00 baseline
→ A03 mechanism opening
→ A05 candidate specification family
→ R10 governance
→ S31 VIF-only feasibility
→ possible S32 estimation
→ human adjudication
→ possible S40 reconstruction
```

---

## Locked formulation

R10 locks the specification-layering rule for Chapter 2. A00/B1 is the binding baseline. A03 proxy specifications may be reviewed as escalation mechanisms but do not replace A00. A05 E-specifications define an NRC-envelope / ME–NRC mechanization-bias candidate family and remain VIF-only until separately authorized for estimation. Diagnostic specifications are non-promotable. S31 may report estimates and compute diagnostics but cannot adjudicate or reconstruct. S32 may estimate candidate specifications only after governance authorization. S40 remains parked until a coefficient object is explicitly promoted by human adjudication. No code layer may promote, reconstruct, or relabel a specification beyond the authority granted by the vault.