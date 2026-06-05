# S32 Validation Report

Run timestamp: `2026-06-03 14:06:22 -04`.

| check | pass | detail |
|---|---|---|
| B1 and E2B are the only estimated specs in S32 | TRUE | SPEC_B1_WAGE_BASELINE \| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED |
| FM/IM/DOLS roles are correctly assigned | TRUE | FM_OLS main_estimator \| IM_OLS robustness_estimator \| DOLS fragility_stress_diagnostic |
| All required CSV files exist | TRUE |  |
| All non-allowed-empty CSV files are non-empty | TRUE | dummy candidate grid may be empty if no consensus outliers exist |
| All TeX tables exist | TRUE |  |
| All TeX tables are backed by existing CSV files | TRUE | see audit/S32_tex_csv_backing.csv |
| S32 folder only; no S33 folder created | TRUE | no S33 output folder exists |
| Only Phillips-Ouliaris cointegration testing is reported | TRUE | cointegration admissibility uses Phillips-Ouliaris only |
| Phillips-Ouliaris is implemented with urca::ca.po | TRUE | po_test_function column equals urca::ca.po |
| ca.po is called on levels data matrices, not FM/IM/DOLS residuals | TRUE | PO matrix columns are built from y_t and spec regressors in the levels panel |
| Baseline PO gate uses type=Pz, demean=constant, lag=short | TRUE | baseline rows: 110 |
| Sensitivity grid includes Pu/Pz, none/constant/trend, short/long | TRUE | full 2 x 3 x 2 PO grid present |
| S32_phillips_ouliaris_gate.csv exists and is non-empty or failures are documented | TRUE | rows: 1320; not_tested: 0 |
| S32_cointegration_admissibility_ledger.csv exists and is non-empty or failures are documented | TRUE | rows: 110 |
| S40 remains parked | TRUE | no S40 paths used |
| No theta/Yp/mu reconstruction was run | TRUE | script estimates cointegrating relations only and constructs no reconstruction object |
| Outlier identification used no historical priors | TRUE | historical_prior_used is false for all outlier rows |
| Rolling endpoint windows did not move the 1974 partition | TRUE | rolling windows are either Fordist/pre-1974 or post-Fordist/post-1973 |
| human_decision remains pending_human_adjudication unless mechanically rejected | TRUE | mechanically_rejected |
| Dummy robustness stays inside existing S32 output family | TRUE | S32_B1_E2B_PO_DUMMY_ROBUSTNESS |
| Dummy robustness keeps B1/E2B as the only specs | TRUE | SPEC_B1_WAGE_BASELINE \| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED |
| Dummy robustness uses only baseline Phillips-Ouliaris Pz constant short | TRUE | D0-D3 use Pz / constant / short |
| Dummy robustness uses no historical priors | TRUE | all dummy robustness historical_prior_used fields are false |
| Only D1 can rescue for serious human review | TRUE | D2/D3 are fragility and stress diagnostics only |
| Dummy robustness does not authorize preferred relation or S40 | TRUE | preferred_relation_authorized and s40_authorized are false |

## Phillips-Ouliaris diagnostic sample

| spec_id | po_statistic | po_cv_1pct | po_cv_5pct | po_cv_10pct | phillips_ouliaris_gate |
|---|---|---|---|---|---|
| SPEC_B1_WAGE_BASELINE | 51.256 | 109.453 | 89.762 | 80.203 | fail |
| SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED | 16.034 | 109.453 | 89.762 | 80.203 | fail |

Validation status: `passed`.
