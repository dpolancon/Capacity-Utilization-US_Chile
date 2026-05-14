# US S30 Formal Stability Adjudication Report

## 1. Purpose

This script adjudicates the existing S30 transformation-relation outputs for the restricted B1 pathway. It does not expand the estimator grid, create S40 code, reconstruct productive capacity, compute capacity utilization or mu, produce profitability outputs, or touch Chile outputs.

Estimator roles follow the locked R09 rule: FM-OLS is the main estimator, IM-OLS is the robustness estimator, and DOLS is a fragility/stress diagnostic. DOLS contradiction is recorded but does not veto Tier 1 and does not independently block S40.

## 2. Required inputs detected

| input | detected |
| --- | --- |
| us_s30_estimator_grid.csv | TRUE |
| us_s30_window_stability_summary.csv | TRUE |
| us_s30_rolling_coefficients.csv | TRUE |
| us_s30_specification_register.csv | TRUE |
| us_s30_candidate_window_register_used.csv | TRUE |
| us_s30_run_manifest.csv | TRUE |

## 3. Formal specification disposition

| formal_short_label | spec_id | formal_disposition | under_formal_evaluation | restricted_s40_candidate | formal_promotion_allowed |
| --- | --- | --- | --- | --- | --- |
| B0 | SPEC_B0_CAPITAL_ONLY | supporting_benchmark_only | FALSE | FALSE | FALSE |
| B1 | SPEC_B1_WAGE_BASELINE | restricted_s40_pathway_candidate | TRUE | TRUE | TRUE |
| C1 | SPEC_C1_COMPOSITION_STOCK | mechanism_evidence_only | FALSE | FALSE | FALSE |
| C2 | SPEC_C2_FULL_COMPOSITION | diagnostic_only | FALSE | FALSE | FALSE |
| D1 | SPEC_D1_CURRENT_COST_DIAGNOSTIC | diagnostic_only | FALSE | FALSE | FALSE |
| D2 | SPEC_D2_PRICE_WEDGE_DIAGNOSTIC | diagnostic_only | FALSE | FALSE | FALSE |

## 4. Tier 1 object admissibility

| check | result | detail |
| --- | --- | --- |
| B1 under formal evaluation | TRUE | B1 is the only restricted S40-pathway candidate. |
| B1 has no severe collinearity flag | TRUE | Evaluated from us_s30_window_stability_summary.csv. |
| FM-OLS main estimator available across B1 windows | TRUE | FM-OLS is the main estimator under the locked R09 rule. |
| IM-OLS robustness estimator available across B1 windows | TRUE | IM-OLS is the robustness estimator under the locked R09 rule. |
| IM-OLS does not substantively contradict FM-OLS | TRUE | A substantive IM-OLS contradiction of FM-OLS is the only estimator contradiction that can fail Tier 1. |
| DOLS fragility diagnostic active | TRUE | Surviving DOLS stress diagnostic contradicts FM-OLS/IM-OLS evidence in window(s): fordist_core; pre_1974_alt_1947_1974. Under the locked R09 rule, DOLS is recorded as a fragility diagnostic only and cannot veto Tier 1 or independently block S40. |
| DOLS veto applied | FALSE | DOLS is a fragility/stress diagnostic, not a veto estimator; dols_veto = FALSE. |
| Tier 1 object admissibility | TRUE | Tier 1 passes, but Tier 2 stability evidence is mixed; S40 can proceed only as restricted B1 with a Tier 2 fragility flag. |

## 5. Tier 2 stability evidence

Exact Hansen-type parameter-instability testing is unavailable in this bounded pass because the required raw cointegrating-regression objects are not part of the S30 output-only input contract. The exported diagnostic therefore reports a proxy status and uses the existing S30 rolling FM-OLS coefficient path.

| test_id | exact_or_proxy_status | rolling_windows | rolling_adjacent_sign_reversal_count | summary_proxy_reversal_count | evidence_class |
| --- | --- | --- | --- | --- | --- |
| B1_HANSEN_TYPE_ROLLING_PROXY | proxy_from_existing_s30_rolling_coefficients |    67 |     3 |     1 | mixed |

## 6. Tier 3 Gregory-Hansen stress

Gregory-Hansen is exported as a not_implemented diagnostic row. The pass does not redefine windows and does not promote non-B1 specifications.

| test_id | implementation_status | evidence_class | windows_redefined | non_b1_specs_promoted |
| --- | --- | --- | --- | --- |
| B1_GREGORY_HANSEN_ONE_BREAK_STRESS | not_implemented | unavailable | FALSE | FALSE |

## 7. Decision

| candidate_spec_id | tier1_pass | tier2_evidence_class | dols_fragility_flag | dols_veto | tier3_implementation_status | s40_gate | fragility_flag |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SPEC_B1_WAGE_BASELINE | TRUE | mixed | TRUE | FALSE | not_implemented | pass_restricted_fragility_flag | TRUE |

- Gate reason: Tier 1 passes, but Tier 2 stability evidence is mixed; S40 can proceed only as restricted B1 with a Tier 2 fragility flag.

## 8. Package/function availability

| package | function_name | diagnostic_role | package_available | function_available |
| --- | --- | --- | --- | --- |
| cointReg | cointRegFM | S30 estimator provenance | TRUE | TRUE |
| strucchange | efp | generic parameter-instability tools | TRUE | TRUE |
| urca | ca.po | cointegration test helper, not Gregory-Hansen | TRUE | TRUE |
| tseries | adf.test | unit-root helper, not formal S30 adjudication | TRUE | TRUE |

## 9. Output files

| output | path |
| --- | --- |
| us_s30_formal_spec_disposition.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_formal_spec_disposition.csv |
| us_s30_hansen_stability_tests.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_hansen_stability_tests.csv |
| us_s30_gregory_hansen_stress.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_gregory_hansen_stress.csv |
| us_s30_formal_stability_decision.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_formal_stability_decision.csv |
| US_S30_formal_stability_adjudication_report.md | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/US_S30_formal_stability_adjudication_report.md |
| us_s30_formal_stability_manifest.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_formal_stability_manifest.csv |

## 10. Warnings

- none
