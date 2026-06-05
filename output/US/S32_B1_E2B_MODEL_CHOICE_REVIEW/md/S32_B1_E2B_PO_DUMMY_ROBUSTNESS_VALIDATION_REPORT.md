# S32 B1/E2B PO Dummy Robustness Validation Report

Run timestamp: `2026-06-03 14:06:22 -04`.

| check | pass | detail |
|---|---|---|
| S40 remains parked | TRUE | no S40 paths used |
| Outlier identification used no historical priors | TRUE | historical_prior_used is false for all outlier rows |
| Dummy robustness stays inside existing S32 output family | TRUE | S32_B1_E2B_PO_DUMMY_ROBUSTNESS |
| Dummy robustness keeps B1/E2B as the only specs | TRUE | SPEC_B1_WAGE_BASELINE \| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED |
| Dummy robustness uses only baseline Phillips-Ouliaris Pz constant short | TRUE | D0-D3 use Pz / constant / short |
| Dummy robustness uses no historical priors | TRUE | all dummy robustness historical_prior_used fields are false |
| Only D1 can rescue for serious human review | TRUE | D2/D3 are fragility and stress diagnostics only |
| Dummy robustness does not authorize preferred relation or S40 | TRUE | preferred_relation_authorized and s40_authorized are false |

## Dummy robustness log

| item | value |
|---|---|
| pass_name | S32_B1_E2B_PO_DUMMY_ROBUSTNESS |
| spec_window_variant_rows | 440 |
| baseline_D0_rows | 110 |
| D1_rescue_rows | 0 |
| D2_fragility_signal_rows | 5 |
| D3_stress_signal_rows | 2 |
| not_tested_rows | 152 |
| historical_prior_used | FALSE |
| s40_authorized | FALSE |

Dummy robustness validation status: `passed`.
