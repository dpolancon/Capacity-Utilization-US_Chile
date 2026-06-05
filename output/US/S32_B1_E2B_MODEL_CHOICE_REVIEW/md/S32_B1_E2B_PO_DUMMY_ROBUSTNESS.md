# S32 B1/E2B PO Dummy Robustness

Run timestamp: `2026-06-03 14:06:22 -04`.

## 1. Lock statement

`S32_B1_E2B_PO_DUMMY_ROBUSTNESS` is a bounded diagnostic pass inside the existing S32 workflow. It does not create S33, does not authorize S40, and does not reconstruct theta, productive capacity, or utilization.

## 2. Test object

The comparison remains restricted to `SPEC_B1_WAGE_BASELINE` and `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED`. Phillips-Ouliaris remains the only cointegration admissibility gate. The test is the baseline `Pz / constant / short` gate.

## 3. Dummy protocol

| dummy_variant | variant_label | rule | can_rescue_for_serious_human_review | interpretation_limit |
|---|---|---|---|---|
| D0 | no_dummies_current_S32_baseline | No pulse controls; current patched S32 baseline Pz / constant / short. | FALSE | baseline only |
| D1 | strict_high_recurrence_high_priority | Use high-priority pulse years recurring across both specs, at least two estimators, and at least three windows. | TRUE | only bounded dummy variant allowed to rescue a failed baseline for serious human review |
| D2 | all_high_priority_in_window | Use all high-priority pulse years inside the spec-window sample. | FALSE | fragility diagnostic only; cannot define preferred relation |
| D3 | all_high_and_medium_priority_in_window | Use all high-priority and medium-priority pulse years inside the spec-window sample. | FALSE | stress test only; cannot define preferred relation |

D1 is operationalized as high-priority pulse years recurring across both specs, at least two estimators, and at least three windows. D2 uses all high-priority pulse years inside the window. D3 uses all high-priority and medium-priority pulse years inside the window. Historical priors are not used.

## 4. Main-window dummy robustness ledger

| spec_id | window_id | d0_gate | d1_gate | d2_gate | d3_gate | d1_n_dummies | d2_n_dummies | d3_n_dummies | dummy_robustness_status |
|---|---|---|---|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | fail | fail | fail | not_tested | 4.000 | 12.000 | 18.000 | unchanged_failure |
| SPEC_B1_WAGE_BASELINE | fordist_core | fail | fail | not_tested | not_tested | 2.000 | 6.000 | 12.000 | unchanged_failure |
| SPEC_B1_WAGE_BASELINE | full_long_sample | fail | fail | pass_5pct | pass_1pct | 7.000 | 30.000 | 42.000 | fragility_only_D2_or_D3 |
| SPEC_B1_WAGE_BASELINE | post_1973 | fail | fail | fail | fail | 0.000 | 11.000 | 17.000 | unchanged_failure |
| SPEC_B1_WAGE_BASELINE | pre_1974 | fail | fail | pass_5pct | not_tested | 7.000 | 19.000 | 25.000 | fragility_only_D2_or_D3 |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1940_1973 | fail | fail | not_tested | not_tested | 4.000 | 10.000 | 16.000 | unchanged_failure |
| SPEC_B1_WAGE_BASELINE | pre_1974_alt_1947_1974 | fail | fail | not_tested | not_tested | 0.000 | 4.000 | 10.000 | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | fail | fail | fail | not_tested | 4.000 | 12.000 | 18.000 | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | fail | fail | not_tested | not_tested | 2.000 | 6.000 | 12.000 | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | fail | fail | pass_1pct | pass_1pct | 7.000 | 30.000 | 42.000 | fragility_only_D2_or_D3 |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | fail | fail | fail | fail | 0.000 | 11.000 | 17.000 | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | fail | fail | fail | not_tested | 7.000 | 19.000 | 25.000 | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1940_1973 | fail | fail | not_tested | not_tested | 4.000 | 10.000 | 16.000 | unchanged_failure |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974_alt_1947_1974 | fail | fail | not_tested | not_tested | 0.000 | 4.000 | 10.000 | unchanged_failure |

## 5. Gate output sample

| spec_id | window_id | dummy_variant | n_dummies | effective_n_after_controls | po_statistic | po_cv_10pct | phillips_ouliaris_gate | po_error |
|---|---|---|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | full_long_sample | D0 | 0.000 | 96.000 | 51.256 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | full_long_sample | D1 | 7.000 | 89.000 | 58.450 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | full_long_sample | D2 | 30.000 | 66.000 | 102.117 | 80.203 | pass_5pct |  |
| SPEC_B1_WAGE_BASELINE | full_long_sample | D3 | 42.000 | 54.000 | 122.664 | 80.203 | pass_1pct |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | D0 | 0.000 | 96.000 | 16.034 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | D1 | 7.000 | 89.000 | 28.874 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | D2 | 30.000 | 66.000 | 113.368 | 80.203 | pass_1pct |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | full_long_sample | D3 | 42.000 | 54.000 | 129.786 | 80.203 | pass_1pct |  |
| SPEC_B1_WAGE_BASELINE | pre_1974 | D0 | 0.000 | 45.000 | 30.419 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | pre_1974 | D1 | 7.000 | 38.000 | 44.050 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | pre_1974 | D2 | 19.000 | 26.000 | 98.226 | 80.203 | pass_5pct |  |
| SPEC_B1_WAGE_BASELINE | pre_1974 | D3 | 25.000 | 20.000 |  |  | not_tested | too_many_dummies_for_min_effective_sample |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | D0 | 0.000 | 45.000 | 22.720 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | D1 | 7.000 | 38.000 | 22.493 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | D2 | 19.000 | 26.000 | 62.080 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | pre_1974 | D3 | 25.000 | 20.000 |  |  | not_tested | too_many_dummies_for_min_effective_sample |
| SPEC_B1_WAGE_BASELINE | post_1973 | D0 | 0.000 | 51.000 | 30.725 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | post_1973 | D1 | 0.000 | 51.000 | 30.725 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | post_1973 | D2 | 11.000 | 40.000 | 55.692 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | post_1973 | D3 | 17.000 | 34.000 | 62.889 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | D0 | 0.000 | 51.000 | 10.591 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | D1 | 0.000 | 51.000 | 10.591 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | D2 | 11.000 | 40.000 | 51.430 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | post_1973 | D3 | 17.000 | 34.000 | 58.124 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | fordist_core | D0 | 0.000 | 29.000 | 19.031 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | fordist_core | D1 | 2.000 | 27.000 | 24.695 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | fordist_core | D2 | 6.000 | 23.000 |  |  | not_tested | too_many_dummies_for_min_effective_sample |
| SPEC_B1_WAGE_BASELINE | fordist_core | D3 | 12.000 | 17.000 |  |  | not_tested | too_many_dummies_for_min_effective_sample |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | D0 | 0.000 | 29.000 | 6.739 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | D1 | 2.000 | 27.000 | 22.838 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | D2 | 6.000 | 23.000 |  |  | not_tested | too_many_dummies_for_min_effective_sample |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | fordist_core | D3 | 12.000 | 17.000 |  |  | not_tested | too_many_dummies_for_min_effective_sample |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | D0 | 0.000 | 39.000 | 16.296 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | D1 | 4.000 | 35.000 | 31.053 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | D2 | 12.000 | 27.000 | 62.574 | 80.203 | fail |  |
| SPEC_B1_WAGE_BASELINE | bridge_1940_1978 | D3 | 18.000 | 21.000 |  |  | not_tested | too_many_dummies_for_min_effective_sample |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | D0 | 0.000 | 39.000 | 21.234 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | D1 | 4.000 | 35.000 | 28.024 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | D2 | 12.000 | 27.000 | 67.710 | 80.203 | fail |  |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | bridge_1940_1978 | D3 | 18.000 | 21.000 |  |  | not_tested | too_many_dummies_for_min_effective_sample |

## 6. Interpretation lock

Dummies are endogenous diagnostic pulse controls, not historical interpretation. D1 can move a failed baseline into serious human review. D2 and D3 can signal fragility but cannot define the preferred relation. S40 remains parked.
