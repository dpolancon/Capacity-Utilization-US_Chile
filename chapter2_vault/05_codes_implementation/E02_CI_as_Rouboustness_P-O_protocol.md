---
type: "R-note"
id: "R_Phillips_Ouliaris_Implementation_Protocol"
title: "Phillips-Ouliaris Implementation Protocol for Cointegration Robustness"
status: "draft"
created: "2026-06-03"
updated: "2026-06-03"
project: "Chapter 2"
repo_area: "02_econometrics"
note_role: "implementation_guardrail"
object_domain: "long_run_transformation_relation"
method_family: "residual_based_cointegration_testing"
primary_package: "urca"
primary_function: "ca.po"
primary_test: "Phillips-Ouliaris"
baseline_statistic: "Pz"
baseline_deterministic_case: "constant"
baseline_lag_correction: "short"

primary_estimators:
  - "FM-OLS"
  - "IM-OLS"
  - "DOLS"

implementation_scope:
  - "S33_cointegration_robustness"
  - "B1_E2B_model_choice_review"
  - "residual_based_admissibility"
  - "robustness_protocol"

locked_terms:
  - "Phillips-Ouliaris gate"
  - "Pz normalization-invariant test"
  - "formal residual-based cointegration gate"
  - "residual ADF diagnostic"
  - "estimator triangulation"

forbidden_terms:
  - "pass FM-OLS cointegration test"
  - "Phillips-Hansen cointegration test"
  - "feed FM residuals into ca.po"
  - "S40 reconstruction authorized"

related_specs:
  - "SPEC_B1_WAGE_BASELINE"
  - "SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED"

related_notes:
  - "R_Cointegration_Admissibility_Superconsistent_Estimators"
  - "A06_B1_E2B_Model_Choice_Lock"
  - "S32_B1_E2B_MODEL_CHOICE_REVIEW"

outputs_required:
  - "S33_phillips_ouliaris_gate.csv"
  - "S33_cointegration_admissibility_ledger.csv"
  - "S33_phillips_ouliaris_robustness.md"

tags:
  - "chapter2"
  - "econometrics"
  - "implementation"
  - "cointegration"
  - "phillips-ouliaris"
  - "urca"
  - "ca-po"
  - "fmols"
  - "imols"
  - "dols"
---

# Phillips-Ouliaris Implementation Protocol for Cointegration Robustness

## Purpose

This note defines the implementation protocol for adding Phillips-Ouliaris residual-based cointegration tests to the Chapter 2 super-consistent estimation workflow.

The purpose is not to replace FM-OLS, IM-OLS, or DOLS. The purpose is to add a formal residual-based admissibility gate before interpreting coefficients from those estimators as long-run transformation parameters.

The Phillips-Ouliaris gate belongs to the cointegration-admissibility layer. FM-OLS, IM-OLS, and DOLS belong to the coefficient-inference layer.

## Conceptual placement

The workflow has three distinct layers.

First, define the candidate long-run relation.

Second, assess whether the candidate relation is admissible as cointegrating.

Third, estimate and interpret long-run coefficients using super-consistent estimators.

The distinction is:

$$  
\text{Phillips-Ouliaris tests the candidate long-run relation.}  
$$

$$  
\text{FM-OLS, IM-OLS, and DOLS estimate the coefficients of the relation.}  
$$

The Phillips-Ouliaris result therefore belongs in the admissibility ledger, not in the coefficient table.

## Do not pass estimator residuals into Phillips-Ouliaris

Although Phillips-Ouliaris is residual-based conceptually, the `urca::ca.po()` implementation should not be called by manually passing precomputed FM-OLS, IM-OLS, or DOLS residuals.

The function is called on the levels data matrix of the candidate relation. The function then computes the cointegration regression internally and stores the residuals, statistic, critical values, and test-regression summary.

Therefore:

Do not pass FM-OLS residuals into `ca.po()`.

Do not pass IM-OLS residuals into `ca.po()`.

Do not pass DOLS residuals into `ca.po()`.

Do pass the levels data matrix corresponding to the candidate long-run relation.

Estimator-specific residual ADF checks may remain as diagnostics, but they are not the Phillips-Ouliaris gate.

## Candidate systems

For B1, the candidate relation is:

$$  
y_t = c + \beta_k k_t + \beta_{\omega k}(\omega_t k_t) + u_t^{B1}.  
$$

The Phillips-Ouliaris data matrix is:

```r
z_b1 <- cbind(
  y_t = d$y_t,
  k_t = d$k_t,
  omega_k_t = d$omega_k_t
)
```

For E2B, the candidate relation is:

$$  
y_t = c + \beta_{NRC}k^{NRC}_t + \beta_{\omega m}(\omega_t m_t) + u_t^{E2B}.  
$$

where

$$  
m_t = k^{ME}_t - k^{NRC}_t.  
$$

The Phillips-Ouliaris data matrix is:

```r
z_e2b <- cbind(
  y_t = d$y_t,
  k_NRC_t = d$k_NRC_t,
  omega_m_ME_NRC_t = d$omega_m_ME_NRC_t
)
```

Each matrix must use the same complete-case sample and window definition used in the corresponding FM-OLS, IM-OLS, and DOLS estimation cell.

## Baseline test

The baseline Phillips-Ouliaris test is:

```r
po <- urca::ca.po(
  z = z_spec_window,
  demean = "constant",
  lag = "short",
  type = "Pz"
)
```

Baseline choices:

`type = "Pz"` because it is invariant to the normalization of the cointegrating vector.

`demean = "constant"` because the long-run relation includes an intercept.

`lag = "short"` because it is the baseline variance-covariance correction.

This baseline should be reported as the main Phillips-Ouliaris gate.

## Sensitivity grid

The robustness grid should evaluate:

```r
po_grid <- expand.grid(
  type = c("Pz", "Pu"),
  demean = c("none", "constant", "trend"),
  lag = c("short", "long"),
  stringsAsFactors = FALSE
)
```

Interpretation of variants:

`Pz` is the preferred test because it is normalization-invariant.

`Pu` is a sensitivity check.

`demean = "none"` is the no-deterministic-term case.

`demean = "constant"` is the baseline intercept case.

`demean = "trend"` checks whether rejection depends on deterministic trend treatment.

`lag = "short"` and `lag = "long"` check sensitivity to variance-covariance correction.

## Required output table

Create one tidy row per:

$$  
\text{specification} \times \text{window} \times \text{type} \times \text{demean} \times \text{lag}.  
$$

Required columns:

```text
spec_id
window_id
window_start
window_end
period_family
n_obs
po_type
po_demean
po_lag
po_statistic
po_cv_1pct
po_cv_5pct
po_cv_10pct
phillips_ouliaris_gate
po_error
po_warning
```

Suggested gate labels:

```text
pass_1pct
pass_5pct
pass_10pct
fail
not_tested
```

The gate must be assigned by comparing the test statistic to the critical values using the correct rejection direction from the `urca::ca.po()` output. The code must verify this direction from the object and not assume it blindly.

## Baseline admissibility field

Create the baseline field:

```text
po_pz_constant_short_gate
```

This is the primary Phillips-Ouliaris gate used in the model-choice ledger.

Create the following sensitivity fields:

```text
po_pz_constant_long_gate
po_pz_trend_short_gate
po_pz_trend_long_gate
po_pu_constant_short_gate
po_any_pz_pass
po_all_pz_fail
po_deterministic_sensitive
po_lag_sensitive
po_normalization_sensitive
```

## Alignment with current residual ADF gate

The current S32 field previously labelled `cointegration_pass` must be treated as:

```text
residual_adf_stationarity_gate
```

This is an estimator-specific diagnostic gate based on residual ADF tests after FM-OLS, IM-OLS, or DOLS estimation.

The Phillips-Ouliaris gate must be added separately:

```text
phillips_ouliaris_gate
```

Do not overwrite the residual ADF field.

Do not relabel the residual ADF field as Phillips-Ouliaris.

Do not describe the residual ADF diagnostic as a Phillips-Hansen or Phillips-Ouliaris test.

## Cointegration admissibility ledger

Create a combined ledger with one row per:

$$  
\text{specification} \times \text{window}.  
$$

Required columns:

```text
spec_id
window_id
period_family
window_start
window_end
n_obs
residual_adf_fm_gate
residual_adf_im_gate
residual_adf_dols_gate
po_pz_constant_short_gate
po_pz_constant_long_gate
po_pz_trend_short_gate
po_pz_trend_long_gate
po_any_pz_pass
po_all_pz_fail
po_deterministic_sensitive
po_lag_sensitive
po_normalization_sensitive
fm_im_coefficient_alignment
dols_fragility_flag
vif_status
outlier_severity
cointegration_admissibility_status
human_review_status
```

Suggested `cointegration_admissibility_status` values:

```text
strong_admissibility
moderate_admissibility
weak_or_sensitive_admissibility
residual_gate_conflict
fail
not_tested
```

## Suggested decision rules

Assign `strong_admissibility` if the baseline `Pz` constant-short gate passes at 5 percent or better, at least one additional `Pz` sensitivity case also passes, and the FM/IM residual ADF gates do not contradict the result.

Assign `moderate_admissibility` if the baseline `Pz` gate passes only at 10 percent, or if the baseline `Pz` gate passes at 5 percent but sensitivity is mixed.

Assign `weak_or_sensitive_admissibility` if `Pz` passes only under one deterministic or lag variant.

Assign `residual_gate_conflict` if residual ADF and Phillips-Ouliaris point in opposite directions.

Assign `fail` if `Pz` fails across baseline and sensitivity cases.

Assign `not_tested` if the sample is too short, the matrix is singular, or the test fails.

## Interpretation rules

A Phillips-Ouliaris pass does not automatically promote a specification.

A Phillips-Ouliaris fail does not automatically refute the theoretical object.

A specification may be retained for review only if residual-based admissibility evidence and coefficient-inference evidence are not contradictory.

A specification may not be promoted to reconstruction if it lacks residual-based admissibility support.

DOLS disagreement remains a fragility diagnostic, not an automatic rejection, unless combined with residual-admissibility failure.

## Relation to FM-OLS, IM-OLS, and DOLS

After Phillips-Ouliaris admissibility is evaluated, coefficient interpretation proceeds through the existing estimator protocol.

FM-OLS is the main estimator.

IM-OLS is the robustness estimator.

DOLS is the fragility and dynamic-stress diagnostic.

The final model-choice table must not report Phillips-Ouliaris as if it were an estimator of the coefficient. It is a gate on the long-run relation.

## Relation to Johansen robustness

Phillips-Ouliaris and Johansen should not be treated as substitutes.

Phillips-Ouliaris is the formal residual-based cointegration gate.

Johansen is the system-rank robustness gate.

The strongest admissibility case is one in which residual-based evidence and system-rank evidence point in the same direction.

Suggested future combined status:

```text
strong_cointegration_admissibility =
  Phillips-Ouliaris Pz pass
  + Johansen rank >= 1
  + residual ADF diagnostics not contradictory
  + FM/IM coefficient alignment
```

## Governance rule

The Phillips-Ouliaris gate authorizes cointegration-admissibility review only.

It does not authorize S40 reconstruction.

It does not authorize theta reconstruction.

It does not authorize productive-capacity reconstruction.

It does not authorize utilization reconstruction.

S40 remains parked until a separate reconstruction authorization is issued.

## Locked implementation sentence

For each candidate specification and window, Chapter 2 evaluates cointegration admissibility using `urca::ca.po()` on the levels data matrix of the candidate relation. The baseline Phillips-Ouliaris gate is `type = "Pz"`, `demean = "constant"`, and `lag = "short"`. The `Pz` test is preferred because it is invariant to the normalization of the cointegrating vector. `Pu`, deterministic alternatives, and lag alternatives are reported as sensitivity checks. The resulting Phillips-Ouliaris gate is combined with the residual ADF diagnostic and FM/IM/DOLS coefficient triangulation before any human model-choice adjudication.