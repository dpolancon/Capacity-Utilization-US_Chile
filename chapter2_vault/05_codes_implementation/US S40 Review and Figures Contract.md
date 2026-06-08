---
type: implementation_contract
status: active
layer: code_stage_design
design_role: us_s40_review_and_figures_contract
scope: chapter2_results_repo
repo: Capacity-Utilization-US_Chile
country: US
stage: S40_review
upstream_stage: S40
candidate_spec_id: SPEC_B1_WAGE_BASELINE
upstream_reconstruction_contract: US_S40_Restricted_B1_Reconstruction_Contract
figure_protocol_governed_by: C05-FIGURE_PROTOCOL
review_script: US_S40_review_and_figures.R
reconstruction_script: US_S40_theta_tot_mu_reconstruction.R
anchor_protocol_governed_by: D03_capacity_utilization_level_anchor_pinch_year_protocol
anchor_country: US
anchor_year: 1973
anchor_condition: mu_US_1973_equals_1
anchor_type: point_year_external_pinch
anchor_source: FRB_maximum_utilization_series
anchor_role: level_normalization
anchor_status: externally_declared
recession_shading_source: FRED_NBER_monthly_business_cycle_turning_points
recession_shading_annualization: any_month_overlap
recession_shading_role: visual_context_only
recession_shading_regime_classifier: false
window_average_anchor_allowed_as_baseline: false
fordist_core_mean_anchor_status: diagnostic_only
figures_mark_anchor_year: true
figures_shade_recession_years: true
figures_shade_fordist_core_as_anchor_window: false
profitability_allowed: false
chile_outputs_allowed: false
new_model_estimation_allowed: false
s50_activation_allowed: false
created: 2026-05-14
updated: 2026-05-26
related_to:
  - C05-FIGURE_PROTOCOL
  - US_S40_Restricted_B1_Reconstruction_Contract
  - C01-US_00_MEMO_RECYCLING
  - C03-REPO_STRUCTURE
  - C04-US_S30_STABILITY_PROTOCOL
  - D03_capacity_utilization_level_anchor_pinch_year_protocol
  - M10_Empirical_Identification_Framework
  - R01_residual_vs_structural_identification
  - R09_structural_break_protocol
---

# US S40 Review and Figures Contract

## 1. Purpose

This file defines the contract for:

`codes/US_S40_review_and_figures.R`

This stage reviews and visualizes the already-constructed US S40 restricted B1 outputs.

It does not reconstruct new objects.

It does not modify the S40 reconstruction logic.

It does not estimate a new model.

It does not change the utilization anchor.

It does not move to S50.

It does not compute profitability.

It does not touch Chile.

The review layer verifies whether the S40 outputs obey the restricted B1 reconstruction contract, the D03 anchor protocol, and the C05 figure protocol.

The core review question is:

> Did S40 reconstruct theta_tot, productive capacity, and mu under restricted B1 fragility discipline using the preferred U.S. point-year anchor, mu_US,1973 = 1?

The figure-level question is:

> Do the S40 figures mark the 1973 utilization anchor and use recession shading only as visual context?

---

## 2. Binding inputs

The review script must read only:

`output/US/S40_theta_tot_mu_reconstruction/`

Required files:

- `us_s40_theta_tot_path.csv`
- `us_s40_productive_capacity_path.csv`
- `us_s40_mu_path.csv`
- `us_s40_anchor_register.csv`
- `us_s40_fragility_register.csv`
- `us_s40_reconstruction_manifest.csv`

The script must stop if any required input is missing.

The script must not read raw data directly.

The script must not re-run S30.

The script must not re-run S40 reconstruction.

The script must not read Chile outputs.

The script must not read profitability outputs.

The script may construct a local annual U.S. recession-shading register only for visual context, following C05.

---

## 3. Required upstream checks

The review must verify that the S40 reconstruction remains inside the restricted B1 corridor.

Required checks:

- `candidate_spec_id = SPEC_B1_WAGE_BASELINE`
- `fragility_flag = TRUE` if upstream S30 gate was `pass_restricted_fragility_flag`
- `s40_admissibility_status = admissible_restricted_b1_under_fragility` when fragility is active
- `dols_reconstruction_basis = FALSE`
- `dols_veto = FALSE`
- `mu_formula = Y_real / Yp`
- all `mu_t` values are finite
- all `Yp` values are finite
- all `Yp` values are positive
- no profitability variables are computed
- no Chile outputs are touched
- no comparative outputs are created
- no new model is estimated
- no anchor is silently changed

The review layer must report failed checks in:

`us_s40_review_checks.csv`

A failed check does not automatically repair the output.

A failed check blocks interpretation until S40 is patched upstream.

---

## 4. Anchor review rule

The review layer must use the D03 anchor protocol.

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

The review must verify that the anchor register records:

- `country = US`
- `anchor_year = 1973`
- `anchor_value = 1`
- `anchor_variable = mu_t`
- `anchor_type = point_year_external_pinch`
- `anchor_source = FRB maximum utilization series`
- `anchor_role = level_normalization`
- `anchor_status = externally_declared`
- `preferred_or_diagnostic = preferred`
- `point_year_or_window_average = point_year`
- `diagnostic_window_average_anchor = FALSE`

The review must verify:

$$
\mu_{US,1973}=1
$$

within the declared numerical tolerance.

Recommended tolerance:

`1e-4`

The tolerance is a reconstruction-consistency tolerance, not a theory restriction.

If the anchor register does not record `anchor_year = 1973` and `anchor_type = point_year_external_pinch`, the review must fail.

The review must not silently accept a window-average anchor as equivalent to the point-year anchor.

---

## 5. What the review must not validate as baseline

The review must not validate the old Fordist-core window-average normalization as the preferred baseline.

The following condition is not the preferred U.S. baseline:

$$
\overline{\mu}_{1945-1973}=1
$$

The Fordist-core window may appear in S30 or S40 metadata as:

- coefficient-recovery window;
- reconstruction window;
- historical benchmark window;
- diagnostic comparison window.

It must not be treated as the utilization level anchor unless explicitly labeled as diagnostic or robustness.

If the review script detects:

- `anchor_window = fordist_core`
- `anchor_year_start = 1945`
- `anchor_year_end = 1973`
- `anchor_check_mean_mu = 1`

as the preferred anchor logic, the review must flag this as:

`wrong_anchor_protocol_for_preferred_baseline`

The correct preferred baseline check is:

`mu_1973 = 1`

not:

`mean_mu_1945_1973 = 1`

---

## 6. Recession-shading rule

The review figures must follow:

`C05-FIGURE_PROTOCOL.md`

For U.S. figures, recession shading follows the FRED/NBER recession-bar convention.

Because the S40 series are annual, recession shading must use the C05 annualization rule:

`any_month_overlap`

That means a calendar year is shaded if at least one month in that year overlaps an NBER/FRED recession interval.

Recession shading is visual context only.

It is not:

- a regime classifier;
- a break-date estimator;
- a window-selection device;
- a threshold trigger;
- a utilization-anchor rule;
- evidence that recession dates determine the reconstructed capacity path.

The review manifest must record:

- `recession_shading_source = FRED_NBER_monthly_business_cycle_turning_points`
- `recession_shading_annualization = any_month_overlap`
- `recession_shading_role = visual_context_only`
- `recession_shading_regime_classifier = FALSE`

The review should export an annual recession-shading register so the figure layer is auditable.

---

## 7. Required summary outputs

The review script must write only to:

`output/US/S40_review_and_figures/`

Required CSV outputs:

- `us_s40_review_checks.csv`
- `us_s40_mu_summary.csv`
- `us_s40_theta_summary.csv`
- `us_s40_anchor_point_summary.csv`
- `us_s40_anchor_protocol_summary.csv`
- `us_s40_recession_shading_register.csv`

Required manifest:

- `us_s40_review_manifest.csv`

Required report:

- `US_S40_review_and_figures_report.md`

Optional diagnostic CSV:

- `us_s40_anchor_window_summary.csv`

This file may summarize the Fordist-core window only as a historical or diagnostic window. It must not be used to validate the preferred anchor.

The report must state:

> S40 proceeds as a restricted B1 reconstruction under fragility, not as a clean benchmark promotion.

The report must also state:

> The preferred U.S. utilization level anchor is the point-year condition mu_US,1973 = 1, not mean utilization over the Fordist-core window.

The report must also state:

> U.S. recession shading follows the C05 figure protocol and is annualized using the any-month-overlap rule. Recession shading is visual context only, not regime identification.

---

## 8. Required figures

The review script should generate diagnostic, advisor-facing figures.

Figures are outputs of the review layer, not new analytical objects.

Required figures:

- `fig_us_s40_mu_path.png`
- `fig_us_s40_mu_path.pdf`
- `fig_us_s40_y_ycapacity_path.png`
- `fig_us_s40_y_ycapacity_path.pdf`
- `fig_us_s40_theta_tot_path.png`
- `fig_us_s40_theta_tot_path.pdf`

Figures may remain ignored by `.gitignore` if the repo policy excludes binary outputs.

The CSV summaries, recession-shading register, manifest, and report should remain tracked.

---

## 9. Figure rules

All figures must be diagnostic and advisor-facing.

They must not claim clean benchmark status.

Every figure title, subtitle, or caption should indicate:

`restricted B1 under fragility`

The mu figure must mark the 1973 anchor point.

The mu figure must shade U.S. recession years using the C05 annualized recession-shading protocol.

The mu figure must not shade 1945–1973 as if it were the normalization window.

If the Fordist-core window is shown visually, it must be labeled as a historical benchmark or coefficient-recovery window, not as the utilization anchor.

The Y and Yp figure must compare:

- observed output;
- reconstructed productive capacity.

The Y and Yp figure must use recession shading only as visual context.

The theta figure must show reconstructed:

$$
\theta_t^{tot}
$$

not:

$$
\theta_t^M
$$

The theta figure must not imply that machinery-specific theta is directly estimated.

The theta figure may include recession shading as visual context, but it must not imply that recession dates identify structural breaks in theta.

---

## 10. Interpretation rules

Allowed language:

- restricted B1 reconstruction
- fragility-aware S40 path
- FM-OLS-centered reconstruction
- IM-OLS carried as robustness metadata
- DOLS carried as stress metadata
- utilization derived after productive capacity reconstruction and point-year anchoring
- U.S. point-year anchor
- `mu_US,1973 = 1`
- FRB full-capacity pinch year
- annualized NBER/FRED recession shading
- recession shading as visual context only

Forbidden language:

- clean benchmark
- final utilization estimate
- DOLS reconstruction
- DOLS veto
- direct estimate of theta_M
- profitability result
- regime proof
- residual utilization
- Fordist-core mean as normal utilization
- mean utilization over 1945–1973 as preferred baseline
- recession bars identify regimes
- recession bars identify break dates
- recession bars determine reconstruction windows

---

## 11. Diagnostic guardrails

The review may include bounded nonpathology checks.

Recommended diagnostic check:

- all `mu_t` values are finite;
- all `mu_t` values are positive;
- all `mu_t` values fall within a broad diagnostic range such as `0 < mu_t < 2.5`.

This is not a theoretical law.

It is only a diagnostic guardrail against bad anchoring, coding errors, or explosive paths.

If the check fails, the review should flag the result as diagnostic failure.

It should not silently repair the path.

---

## 12. Hard prohibitions

The review script must not:

- estimate any new model
- alter S40 reconstruction outputs
- change the anchor
- compute profitability
- touch Chile outputs
- create comparative outputs
- promote non-B1 specifications
- use DOLS as reconstruction basis
- use DOLS as veto estimator
- infer theta_M as directly estimated
- identify utilization by residual
- activate S50
- activate threshold-FGLS
- validate Fordist-core mean normalization as the preferred baseline
- use recession shading as regime identification
- use recession shading as break-date identification
- use recession shading as window-selection evidence

---

## 13. Ready to code only if

- active branch is `feature/us-s40-restricted-b1`
- S40 reconstruction commit exists
- working tree is clean
- D03 anchor protocol is locked
- C05 figure protocol is locked
- US S40 reconstruction contract is locked
- preferred U.S. anchor is `mu_US,1973 = 1`
- output is restricted to `codes/US_S40_review_and_figures.R` and `output/US/S40_review_and_figures/`
- review figures mark the 1973 anchor point
- review figures apply annualized recession shading under C05
- review checks verify the point-year anchor
- review checks do not treat Fordist-core mean utilization as the preferred baseline
- the review manifest records `hard_prohibitions_violated = FALSE`
- the review manifest records `wrong_anchor_protocol_for_preferred_baseline = FALSE`
- the review manifest records `recession_shading_regime_classifier = FALSE`

---

## 14. Locked formulation

The US S40 review layer verifies and visualizes the restricted B1 reconstruction.

It does not reconstruct new objects.

It does not change the anchor.

It does not estimate new models.

It does not compute profitability.

The review must verify that S40 obeys the D03 point-year anchor protocol:

$$
\mu_{US,1973}=1
$$

The previous Fordist-core window-average normalization:

$$
\overline{\mu}_{1945-1973}=1
$$

is not the preferred baseline.

It may appear only as a diagnostic or robustness normalization if explicitly labeled as such.

The review layer must also obey C05. U.S. recession shading follows the FRED/NBER recession-bar convention and is annualized using the any-month-overlap rule.

Recession shading is visual context only. It is not regime identification, break-date identification, window selection, or anchor selection.

The review layer should therefore mark the 1973 anchor point, shade annualized recession years, and report any Fordist-core mean normalization as a non-baseline diagnostic.