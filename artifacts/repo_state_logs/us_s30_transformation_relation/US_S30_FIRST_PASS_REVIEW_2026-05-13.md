---
type: memo
status: active
layer: empirical_review
design_role: s30_first_pass_review
scope: chapter2_us
stage: S30
created: 2026-05-13
---

# US S30 first-pass review — transformation-relation stability grid

## Core finding

S30 successfully estimates the declared estimator-window-specification grid and validates the stability gate.

No specification is automatically promoted to S40.

This is not a failed run. It means the promotion discipline is binding.

## Pipeline status

The US path is now complete through S30:

- S10 source-of-truth panel: complete
- S20 composition and admissibility layer: complete
- S30 transformation-relation estimator/stability grid: complete
- S40 productive-capacity and utilization reconstruction: blocked pending review

## S30 run status

The S30 script runs successfully through both:

- `source("codes/US_S30_transformation_relation_fmols_imols_dols.R")`
- `Rscript codes/US_S30_transformation_relation_fmols_imols_dols.R`

Required outputs are generated under:

- `output/US/S30_transformation_relation/`

The S30 report confirms:

- FM-OLS, IM-OLS, and DOLS are available.
- 10 windows are used.
- 6 specifications are estimated.
- Exact Hansen-type testing is not implemented in this first script.
- Stability is reported as `proxy_stability_diagnostic`.
- Rolling diagnostics are diagnostic only and do not identify regimes.

## Classification result

S30 produces:

- `CORE_CANDIDATE = 0`
- `SUPPORTING = 10`
- `FRAGILE = 30`
- `DIAGNOSTIC_ONLY = 20`
- `REJECTED = 0`

The absence of a core candidate blocks automatic S40 reconstruction.

## Specification interpretation

### SPEC_B0_CAPITAL_ONLY

Status: supporting benchmark only.

This specification is useful as a baseline reference, but it is not theoretically sufficient for Chapter 2 because it omits distribution and composition.

### SPEC_B1_WAGE_BASELINE

Status: leading restricted candidate for review.

This is the cleanest promotion-eligible object because it avoids severe collinearity and carries the distributional interaction directly.

However, it remains fragile under the current S30 promotion gate. It requires human review before any S40 use.

### SPEC_C1_COMPOSITION_STOCK

Status: mechanism-informative but unstable.

The stock-composition term is substantively important because it tests whether the ME–NRC proxy adds information to the transformation relation.

However, the sign and stability pattern are not robust enough for automatic promotion. This specification should be reviewed as mechanism evidence, not used directly for S40 yet.

### SPEC_C2_FULL_COMPOSITION

Status: demote from core eligibility.

The full interaction specification is repeatedly damaged by severe collinearity. It should remain as a stress diagnostic, not a core candidate.

### SPEC_D1 and SPEC_D2

Status: diagnostic only.

Current-cost and price-wedge specifications are useful for valuation and relative-price diagnostics. They are not default structural specifications for productive-capacity reconstruction.

## Interpretation lock

The current S30 result should be written as:

> S30 estimates the declared transformation-relation grid and finds that no specification qualifies for automatic promotion to S40 under the current stability discipline. The wage-share baseline is the leading restricted candidate for review; the stock-composition specification is mechanism-informative but unstable; and the full composition interaction is disqualified as a core specification by severe collinearity.

## S40 status

S40 remains blocked.

Do not reconstruct productive capacity or utilization until a human review decides whether to:

1. use the restricted wage-share baseline as a conservative S40 candidate;
2. redesign the composition specification;
3. add a formal Hansen/Gregory-Hansen stability module;
4. or report S30 fragility as a substantive result.

## Next decision

The next work session should not expand the estimator grid.

It should review the S30 outputs and decide between:

- conservative restricted path: B1 review for S40;
- composition-mechanism path: C1 as mechanism evidence only;
- methodological extension: add formal parameter-instability testing;
- stop rule: report no stable S30 core candidate.
