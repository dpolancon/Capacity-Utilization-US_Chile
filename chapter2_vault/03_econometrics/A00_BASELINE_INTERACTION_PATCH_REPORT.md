---
title: "A00 Baseline Interaction Patch Report"
type: "report"
status: "superseded_historical_report"
layer: "method"
design_role: "patch_validation"
scope: "chapter2_core_support"
estimator_status: "historical-or-diagnostic"
requires_review_before_use: true
updated_by: "D12V_ECONOMETRICS_VAULT_ESTIMATOR_PIVOT"
created: 2026-06-01
updated: 2026-06-08
related_to:
  - "A00_Aggregate_Transformation_Benchmark"
  - "A03_TransformationElasticity_Two-CapitalCapacityComposition"
  - "N01_CapacityUtilization_StructuralObject"
  - "M10_Empirical_Identification_Framework"
  - "R04_FMOLS_structural_preservation"
  - "N02_SuperConsistency"
  - "R05_LRV_kernel_bandwidth_regime_misalignment"
---

# A00 Baseline Interaction Patch Report

> [!gate] D12V interaction-term gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.
> Restricted DOLS is preferred only after base-variable integration status, interaction-term status, and sample-window adequacy are classified.

> [!warning] q_omega remains parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path.

> [!warning] Superseded historical report
> This report records the June 1, 2026 level-interaction patch. Its benchmark conclusions were superseded on June 8, 2026 by [[R_distribution_conditioned_theta_identification]]. All old interaction references below are historical record only.

## Summary of Pass 1 Changes

- `02_analyitical_foundation/A00_Aggregate_Transformation_Benchmark.md`: created the exact requested A00 note. It defines A00 as aggregate $K_t$, time-varying $\theta_t$, with the baseline interaction relation:

$$
y_t = c + \beta_1 k_t + \beta_2(\omega_t k_t) + \xi_t,
$$

and the implied mapping:

$$
\theta_t = \beta_1 + \beta_2\omega_t.
$$

- `02_analyitical_foundation/A00_Aggregate_Benchmark.md`: converted the older A00 note into a legacy alias for the locked A00 note during the first patch, then retired it in the bundle-hygiene pass after references were checked.
- `02_analyitical_foundation/A03_TransformationElasticity_Two-CapitalCapacityComposition.md`: patched the A00/A03 boundary. A03 is now framed as decomposing the A00 aggregate $\theta_t$ into $K^{ME}$, $K^{NRC}$, and $s_t$, not as the first source of time variation.
- `03_econometrics/N01_CapacityUtilization_StructuralObject.md`: patched the transformation-elasticity section so $\omega_t k_t$ is named as the A00 baseline econometric object, not an optional example.
- `03_econometrics/M10_Empirical_Identification_Framework.md`: patched the empirical scaffold so the sequence is A00 aggregate interaction relation, $\hat{\theta}_t$, $\hat{Y}_t^p$, level anchoring, and $\hat{\mu}_t$. Added A03/A04 activation boundaries.
- `03_econometrics/R04_FMOLS_structural_preservation.md`: patched the FM-OLS argument so FM-OLS is preferred because it preserves the A00 structural regressor matrix and the mapping $\beta_1 + \beta_2\omega_t$.

## Summary of Pass 2 Changes

- `03_econometrics/N02_SuperConsistency.md`: patched the note so super-consistency is explicitly tied to first-layer coefficient recovery in the A00 aggregate interaction benchmark. The methodological claim remains intact: super-consistency secures coefficient recovery, not $\mu_t$ reconstruction.
- `03_econometrics/R05_LRV_kernel_bandwidth_regime_misalignment.md`: patched the term "global" so it means global estimation of the A00 time-varying interaction mapping, not constant $\theta$. The note now states that FM-OLS can support global A00 reconstruction but cannot by itself identify regime-dependent transformation elasticities.

## Report-Only Review

### `03_econometrics/R01_residual_vs_structural_identification.md`

- decision: no_patch_needed
- reason: The note already enforces the residual-identification guardrail and does not conflict with A00.
- exact phrase or section inspected: "Capacity utilization is not identified by a residual." and "A residual can diagnose failure or describe remaining variation, but it cannot identify $Y_t^p$ or $\mu_t$."
- proposed replacement text: none

### `03_econometrics/R02_DOLS_reconstruction_dilemma.md`

- decision: no_patch_needed
- reason: The note defines DOLS as an estimator-layer correction and blocks direct reconstruction claims. It does not demote the A00 interaction or imply constant $\theta$.
- exact phrase or section inspected: "DOLS can support the first step. It cannot complete the rest."
- proposed replacement text: none

### `03_econometrics/R03_super_consistency_mechanics_hinge.md`

- decision: no_patch_needed
- reason: The "global" language concerns estimator scope and coefficient stability, not constant $\theta$. R05 now clarifies the global-A00 terminology for the FM-OLS layer.
- exact phrase or section inspected: "All three estimators are global. They assume a stable long-run relation across the sample."
- proposed replacement text: none

### `03_econometrics/R06_IMOLS_integration_ladder_reconstruction.md`

- decision: no_patch_needed
- reason: The interaction discussion is a technical sequencing rule for IM-OLS. It does not define the baseline relation and does not conflict with A00.
- exact phrase or section inspected: "If the specification contains interaction terms, the order of operations matters."
- proposed replacement text: none

### `03_econometrics/R07_FGLS_threshold_cointegration_admissibility.md`

- decision: no_patch_needed
- reason: The note assigns FGLS to the regime layer and blocks residual utilization. Its global-estimator warning concerns regime-specific parameters, not a constant A00 $\theta_t$.
- exact phrase or section inspected: "DOLS, FM-OLS, and IM-OLS are global long-run estimators."
- proposed replacement text: none

### `03_econometrics/R08_threshold_break_diagnostics_to_FGLS.md`

- decision: no_patch_needed
- reason: The note only defines the diagnostic path from break testing to threshold-FGLS. It does not redefine A00, demote the interaction term, or treat residuals as utilization.
- exact phrase or section inspected: "The diagnostic ladder comes first. The regime estimator comes second."
- proposed replacement text: none

## Remaining Risks or Unresolved Issues

- Several non-target notes still discuss global estimators or stable relations in generic terms. After the R05 clarification, this should be read as estimator-scope language, not a constant-$\theta$ A00 claim.
- `03_econometrics/R09_structural_break_protocol.md` already contains the locked interaction equation and was not part of the requested patch set.

## Follow-up Hygiene Pass

- N01 was directly verified. It contains the A00 baseline relation and the implied $\theta_t = \beta_1 + \beta_2\omega_t$ mapping.
- N01 required a minor wording patch so the interaction term is named with the required A00 baseline-device wording.
- The A00 YAML link was added to `02_analyitical_foundation/A03_TransformationElasticity_Two-CapitalCapacityComposition.md`, `03_econometrics/N01_CapacityUtilization_StructuralObject.md`, `03_econometrics/M10_Empirical_Identification_Framework.md`, `03_econometrics/R04_FMOLS_structural_preservation.md`, `03_econometrics/N02_SuperConsistency.md`, and `03_econometrics/R05_LRV_kernel_bandwidth_regime_misalignment.md`.
- The A00/A03 notation bridge was added to A03. It distinguishes A00's empirical $\theta_t$ path from A03's analytical $\theta^N(\pi,s)$ decomposition without changing the theory.
- YAML validation passed after the follow-up changes.

## Bundle Hygiene Pass

- Backticked conceptual wikilinks in active analytical notes were converted to active Obsidian wikilinks where they refer to vault notes.
- Incorrect references to `A03_Transformation_Elasticity_Two-CapitalCapacityComposition` were corrected to `A03_TransformationElasticity_Two-CapitalCapacityComposition`.
- No active conceptual links to `A00_Aggregate_Benchmark` remained after the scan. The legacy alias note was removed with `git rm`.
- YAML frontmatter was checked for wikilink brackets and duplicate A00 entries.
- Markdown math fences were audited for malformed one-sided display blocks.

## Validation Checklist

- [x] YAML remains valid in all edited Markdown files.
- [x] `A00_Aggregate_Transformation_Benchmark.md` exists in `02_analyitical_foundation`.
- [x] A00 states aggregate $K_t$, time-varying $\theta_t$.
- [x] A00 uses this baseline equation:

$$
y_t = c + \beta_1 k_t + \beta_2(\omega_t k_t) + \xi_t
$$

- [x] A00 states the implied transformation elasticity:

$$
\theta_t = \beta_1 + \beta_2\omega_t
$$

- [x] N01 names the interaction term as the A00 baseline.
- [x] M10 contains the A00 to reconstruction to anchoring to utilization sequence.
- [x] R04 names FM-OLS as preserving the A00 structural regressor matrix.
- [x] N02 and R05 do not imply constant $\theta$.
- [x] A03 is framed as decomposition/escalation, not replacement.
- [x] No edited note treats residuals as identifying $\mu_t$.
- [x] No edited note says A03 is the first source of time variation in $\theta_t$.
- [x] N01 directly verified.
- [x] N01 names $\omega_t k_t$ as the A00 baseline device.
- [x] A03 includes `A00_Aggregate_Transformation_Benchmark` in `related_to`.
- [x] Econometrics notes directly dependent on A00 include `A00_Aggregate_Transformation_Benchmark` in `related_to`.
- [x] A03 includes the bridge between A00's empirical $\theta_t$ and A03's analytical $\theta^N(\pi,s)$.
- [x] Backticked conceptual wikilinks fixed where appropriate.
- [x] Wrong A03 spelling corrected.
- [x] A00 legacy alias removed after safe reference migration.
