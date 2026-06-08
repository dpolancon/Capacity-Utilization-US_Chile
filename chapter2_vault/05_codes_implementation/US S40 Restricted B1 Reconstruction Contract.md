---
type: implementation_contract
status: active
layer: code_stage_design
design_role: us_s40_restricted_b1_reconstruction_contract
scope: chapter2_results_repo
repo: Capacity-Utilization-US_Chile
country: US
stage: S40_reconstruction
upstream_stage: S30
candidate_spec_id: SPEC_B1_WAGE_BASELINE
s30_gate_governed_by: C04-US_S30_STABILITY_PROTOCOL
reconstruction_script: US_S40_theta_tot_mu_reconstruction.R
review_script: US_S40_review_and_figures.R
anchor_protocol_governed_by: D03_capacity_utilization_level_anchor_pinch_year_protocol
anchor_country: US
anchor_year: 1973
anchor_condition: mu_US_1973_equals_1
anchor_type: point_year_external_pinch
anchor_source: FRB_maximum_utilization_series
anchor_role: level_normalization
anchor_status: externally_declared
preferred_or_diagnostic: preferred
point_year_or_window_average: point_year
diagnostic_window_average_anchor: false
window_average_anchor_allowed_as_baseline: false
fordist_core_mean_anchor_status: diagnostic_only
fragility_flag_required: true
profitability_allowed: false
chile_outputs_allowed: false
new_model_estimation_allowed: false
review_figures_allowed: false
s50_activation_allowed: false
created: 2026-05-14
updated: 2026-06-02
related_to:
  - C01-US_00_MEMO_RECYCLING
  - C03-REPO_STRUCTURE
  - C04-US_S30_STABILITY_PROTOCOL
  - C05-FIGURE_PROTOCOL
  - US_S40_Review_and_Figures_Contract
  - D03_capacity_utilization_level_anchor_pinch_year_protocol
  - M10_Empirical_Identification_Framework
  - R01_residual_vs_structural_identification
  - R09_structural_break_protocol
---

# US S40 Restricted B1 Reconstruction Contract

## 1. Purpose

This file defines the contract for:

`codes/US_S40_theta_tot_mu_reconstruction.R`

This stage reconstructs the restricted B1 U.S. productive-capacity path after the S30 formal gate has opened the restricted pathway under fragility discipline.

It reconstructs:

- `theta_tot`
- productive capacity, `Yp`
- utilization, `mu`

It does not estimate a new model.

It does not reopen S30.

It does not change the candidate specification.

It does not compute profitability.

It does not produce review figures.

It does not touch Chile.

It does not activate S50.

The core reconstruction question is:

> Given the restricted B1 S30 coefficient object, can S40 reconstruct theta_tot, productive capacity, and utilization while obeying the D03 point-year anchor rule, mu_US,1973 = 1?

---

## 2. Binding upstream status

The only active U.S. S40 pathway is:

`SPEC_B1_WAGE_BASELINE`

The pathway is restricted and fragility-aware.

It is not a clean benchmark promotion.

The relevant S30 rule is governed by:

`C04-US_S30_STABILITY_PROTOCOL.md`

The S40 reconstruction script must consume the existing S30 restricted B1 outputs and decision metadata. It must not expand the estimator grid or promote any alternative specification.

Allowed upstream status values are:

- `s40_gate = pass_restricted`
- `s40_gate = pass_restricted_fragility_flag`

If the upstream gate is unavailable, contradictory, blocked, or points to a non-B1 candidate, the script must stop.

---

## 3. Binding inputs

The reconstruction script may read only the input files needed to reconstruct the already-adjudicated restricted B1 path.

Allowed input classes:

- canonical U.S. source-of-truth panel required to assemble `Y_real`, `K`, and relevant transformation variables;
- S30 restricted B1 coefficient outputs;
- S30 formal stability decision and fragility metadata;
- historical-window metadata already produced upstream.

The script must not read Chile outputs.

The script must not read profitability outputs.

The script must not read review-layer outputs.

The script must not use DOLS coefficients as the reconstruction basis.

---

## 4. Reconstruction object

The reconstruction object is `theta_tot`, not a direct estimate of machinery-specific `theta_M`.

`theta_tot` is the exported reconstruction label for the locked A00 empirical aggregate time-varying transformation path, `theta_t`.

It is not a direct A03 machinery-specific object.

The restricted B1 path must treat the long-run transformation relation as the upstream identified object and then derive the capacity-utilization path downstream.

The admissible sequence is:

1. read S30 restricted B1 coefficient object;
2. reconstruct `theta_tot`;
3. reconstruct unanchored productive capacity, `Yp_unanchored`;
4. apply the D03 point-year level anchor;
5. derive `Yp` after anchoring;
6. derive `mu = Y_real / Yp`;
7. write registers and manifests.

The script must not treat residuals as primitive utilization.

The script must not use DOLS as the reconstruction engine.

The script must not infer `theta_M` as directly estimated.

---

## 5. Anchor rule

The reconstruction layer must use the D03 anchor protocol.

The preferred U.S. baseline anchor is:

$$
\mu_{US,1973}=1
$$

This is a point-year full-capacity pinch anchor.

The anchor source is:

`FRB maximum utilization series`

The anchor type is:

`point_year_external_pinch`

The anchor role is:

`level_normalization`

The anchor status is:

`externally_declared`

The script must locate the row for 1973 and compute the anchor scale factor so that the anchored path satisfies:

$$
\mu_{US,1973}=1.
$$

Equivalently, after anchoring:

$$
Y^p_{1973}=Y_{1973}.
$$

The exact implementation may scale `Yp_unanchored` or apply an equivalent log-level shift, but the exported result must verify `mu_1973 = 1` within tolerance.

Recommended tolerance:

`1e-4`

The tolerance is a numerical reconstruction tolerance, not a theoretical claim that utilization generally converges to one.

---

## 6. What must not be used as preferred anchor

The previous Fordist-core mean normalization is not the preferred baseline:

$$
\overline{\mu}_{1945-1973}=1
$$

The Fordist-core window may remain a coefficient-recovery window, reconstruction context, historical benchmark, or diagnostic comparison window.

It must not silently define normal utilization.

If the script computes a Fordist-core window mean, it must be labeled diagnostic or robustness-only.

The script must not record any of the following as the preferred anchor logic:

- `anchor_window = fordist_core`
- `anchor_year_start = 1945`
- `anchor_year_end = 1973`
- `anchor_check_mean_mu = 1`

The correct preferred baseline check is:

`mu_1973 = 1`

not:

`mean_mu_1945_1973 = 1`

---

## 7. Required anchor register

The reconstruction script must write:

`output/US/S40_theta_tot_mu_reconstruction/us_s40_anchor_register.csv`

The anchor register should include at minimum:

- `country`
- `anchor_variable`
- `anchor_year`
- `anchor_window`
- `anchor_value`
- `anchor_type`
- `anchor_source`
- `anchor_role`
- `anchor_status`
- `normalization_rule`
- `rationale`
- `preferred_or_diagnostic`
- `point_year_or_window_average`
- `diagnostic_window_average_anchor`
- `anchor_scale_factor`
- `log_anchor_shift`
- `anchor_check_mu_1973`
- `input_panel_path`
- `fragility_flag`

Expected values include:

- `country = US`
- `anchor_variable = mu_t`
- `anchor_year = 1973`
- `anchor_value = 1`
- `anchor_type = point_year_external_pinch`
- `anchor_source = FRB maximum utilization series`
- `anchor_role = level_normalization`
- `anchor_status = externally_declared`
- `preferred_or_diagnostic = preferred`
- `point_year_or_window_average = point_year`
- `diagnostic_window_average_anchor = FALSE`
- `anchor_check_mu_1973 = 1` within tolerance

---

## 8. Required outputs

The reconstruction script must write only to:

`output/US/S40_theta_tot_mu_reconstruction/`

Required outputs:

- `us_s40_theta_tot_path.csv`
- `us_s40_productive_capacity_path.csv`
- `us_s40_mu_path.csv`
- `us_s40_anchor_register.csv`
- `us_s40_fragility_register.csv`
- `us_s40_reconstruction_manifest.csv`
- `US_S40_theta_tot_mu_reconstruction_report.md`

The outputs must be sufficient for the review layer to verify the reconstruction without re-running S30 or S40.

---

## 9. Fragility metadata

Because the active U.S. pathway is restricted B1 under fragility discipline, S40 outputs must carry fragility metadata.

The fragility register must record at minimum:

- `candidate_spec_id = SPEC_B1_WAGE_BASELINE`
- `s40_admissibility_status`
- `fragility_flag`
- `dols_fragility_flag`
- `dols_veto = FALSE`
- `dols_reconstruction_basis = FALSE`
- `fmols_reconstruction_basis = TRUE`
- `imols_robustness_metadata_carried = TRUE`
- `clean_benchmark_promotion = FALSE`

Allowed reporting language:

> Restricted B1 reconstruction under fragility.

Forbidden reporting language:

> Clean U.S. benchmark reconstruction.

---

## 10. Diagnostic guardrails

The reconstruction script should run bounded nonpathology checks before exporting final paths.

Recommended checks:

- all `Yp` values are finite;
- all `Yp` values are positive;
- all `mu_t` values are finite;
- all `mu_t` values are positive;
- `mu_1973 = 1` within tolerance;
- no Fordist-core mean anchor is validated as preferred baseline.

A diagnostic failure must be recorded in the manifest and report.

The script must not silently repair failed paths by changing the anchor rule.

---

## 11. Hard prohibitions

The reconstruction script must not:

- estimate any new model;
- alter S30 outputs;
- promote non-B1 specifications;
- use DOLS as reconstruction basis;
- use DOLS as veto estimator;
- identify utilization by residual;
- infer `theta_M` as directly estimated;
- validate Fordist-core mean normalization as the preferred baseline;
- compute profitability;
- touch Chile outputs;
- create comparative outputs;
- generate review figures;
- activate S50;
- activate threshold-FGLS;
- choose the anchor from recession shading;
- choose the anchor from rolling or recursive diagnostics.

---

## 12. Ready to code only if

- active branch is `feature/us-s40-restricted-b1`;
- working tree is clean;
- C04 has opened the restricted B1 pathway;
- D03 anchor protocol is locked;
- C05 figure protocol is locked but not used to choose anchors;
- output is restricted to `output/US/S40_theta_tot_mu_reconstruction/`;
- the preferred U.S. anchor is `mu_US,1973 = 1`;
- Fordist-core mean normalization is diagnostic-only;
- the script records `dols_reconstruction_basis = FALSE`;
- the script records `dols_veto = FALSE`;
- the script records `clean_benchmark_promotion = FALSE`;
- no Chile, profitability, comparative, S50, or figure-review outputs are produced.

---

## 13. Locked formulation

The US S40 restricted B1 reconstruction layer creates the reconstructed `theta_tot`, productive-capacity, and utilization paths from the upstream S30 restricted B1 object.

It does not estimate new models.

It does not compute profitability.

It does not produce review figures.

It does not touch Chile.

It must anchor the utilization path by the D03 point-year rule:

$$
\mu_{US,1973}=1.
$$

The old Fordist-core mean normalization:

$$
\overline{\mu}_{1945-1973}=1
$$

is not the preferred baseline and may appear only as a diagnostic or robustness comparison.
