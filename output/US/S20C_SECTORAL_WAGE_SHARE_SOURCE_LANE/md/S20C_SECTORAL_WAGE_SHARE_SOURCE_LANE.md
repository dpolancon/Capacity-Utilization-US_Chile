# S20C Sectoral Wage-Share Source Lane

## Scope

S20C creates a sector-explicit unadjusted wage-share source-lane contract. It does not attach a wage-share series to S20, run S21/S22/S30/S32, run econometrics, estimate theta, construct productive capacity, construct utilization, construct accumulated q, reconstruct GPIM, or alter S20 capital outputs.

## Governing Inputs

- `output/US/S20_MODEL_INPUT_LAYER/`
- `output/US/S20B_DISTRIBUTION_ATTACHMENT_CONTRACT/`
- `output/US/S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION/`
- `data/processed/us_s10/us_s10_source_panel_long.csv` and `data/processed/us_s10/us_s10_object_admissibility_ledger.csv` as repo-local current-release source metadata

## Candidate Source Summary

|sector_classification|object_kind|candidate_count|
|---|---|---:|
|corporate_sector|constructed_or_registered_wage_share| 4|
|corporate_sector|distribution_related| 3|
|corporate_sector|historical_downstream_reference| 1|
|corporate_sector|labor_compensation_ingredient| 2|
|corporate_sector|profit_share_or_profit_ingredient|10|
|corporate_sector|shaikh_adjusted_or_adjustment_candidate|10|
|corporate_sector|value_added_ingredient| 2|
|corporate_sector|wage_share_or_wage_share_ingredient| 7|
|nonfinancial_corporate|constructed_or_registered_wage_share| 2|
|nonfinancial_corporate|distribution_related| 1|
|nonfinancial_corporate|labor_compensation_ingredient| 2|
|nonfinancial_corporate|profit_share_or_profit_ingredient| 7|
|nonfinancial_corporate|shaikh_adjusted_or_adjustment_candidate| 4|
|nonfinancial_corporate|value_added_ingredient| 2|
|nonfinancial_corporate|wage_share_or_wage_share_ingredient| 5|
|pending_or_not_applicable|adjusted_or_shaikh_candidate| 3|
|pending_or_not_applicable|profit_share_or_profit_ingredient| 1|
|unclear|historical_downstream_reference| 3|
|unclear|profit_share_or_profit_ingredient| 1|
|unclear|shaikh_adjusted_or_adjustment_candidate| 3|
|unclear|wage_share_or_wage_share_ingredient| 9|

The current-release repo-local S10 source panel contains staged annual BEA NIPA Table 1.14 ingredients for `NFC_COMP`, `NFC_GVA`, `CORP_COMP`, and `CORP_GVA`. Each is current-dollar, annual, documented with provenance fields, and covers 1929-2025, so each overlaps the S20 aggregate-capital common support of 1931-2024. Legacy constructed wage-share panels remain audited but not authorized as current source authority.

## Source Contracts

|contract_id|status|role|sector_boundary|formula|common_support|
|---|---|---|---|---|---|
|WAGE_SHARE_UNADJUSTED_NFC_GVA_BASELINE|AUTHORIZE_S20C_NFC_WAGE_SHARE_SOURCE_CONTRACT|PREFERRED_DISTRIBUTION_VARIABLE_FOR_S20_NFC_GPIM_BASELINE|nonfinancial_corporate_sector|WAGE_SHARE_UNADJUSTED_NFC_GVA_BASELINE = NFC_COMP / NFC_GVA|1929-2025|
|WAGE_SHARE_UNADJUSTED_CORP_GVA_ROBUSTNESS|AUTHORIZE_CORPORATE_WAGE_SHARE_ROBUSTNESS_SOURCE_CONTRACT|ROBUSTNESS_OR_RECONCILIATION_OBJECT_NOT_BASELINE|corporate_sector_as_a_whole|WAGE_SHARE_UNADJUSTED_CORP_GVA_ROBUSTNESS = CORP_COMP / CORP_GVA|1929-2025|

S20C authorizes source-lane contracts only. It does not merge either source into the S20 model-input panel. The NFC contract is the preferred baseline. The corporate contract is available only for robustness or reconciliation unless a later protocol explicitly shifts the model boundary.

## Rejections And Blocks

Generic economy-wide, private-business, total-business, nonfarm-business, household, mixed-income, and sector-unclear wage-share objects remain rejected for baseline use. Profit-share objects remain alternative or reconciliation evidence only. Shaikh-adjusted objects remain blocked pending both a current-release source-data contract and a passing semantic/accounting crosswalk.

## Validation

|check_id|status|evidence|
|---|---|---|
|HEAD_AND_ORIGIN_AT_ACD5280|PASS|HEAD=acd5280; origin/main=acd5280; branch=main.|
|S20_OUTPUTS_FOUND|PASS|Found 6 current S20 artifacts.|
|S20_DECISION_AUTHORIZES_MODEL_INPUT_CONSUMPTION|PASS|AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION recognized.|
|S20B_OUTPUTS_FOUND|PASS|S20B validation, contract, audit, and report artifacts found.|
|S20B_BLOCK_DECISION_RECOGNIZED|PASS|BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION recognized.|
|S14_OUTPUTS_FOUND_AND_PASS|PASS|S14 validation PASS checks: 13/13.|
|S20_CAPITAL_LAYER_LEFT_UNCHANGED|PASS|Current S20 artifacts are byte-identical before and after S20C execution.|
|NO_GPIM_RECONSTRUCTION|PASS|S20C does not reconstruct GPIM or alter K_GROSS_GPIM_TOTAL.|
|NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED|PASS|S20C reads repo-local outputs/docs/processed ledgers only; provider/raw roots are not inputs.|
|NO_DOWNSTREAM_ECONOMETRIC_STAGE_INVOKED|PASS|S20C script contains no source/system invocation of S21/S22/S30/S32 scripts.|
|NO_THETA_PRODUCTIVE_CAPACITY_UTILIZATION_OR_Q|PASS|No theta, productive capacity, utilization, accumulated q, or econometric estimator is constructed.|
|CANDIDATE_SECTORAL_WAGE_SHARE_SOURCES_AUDITED|PASS|Candidate audit rows: 82|
|GENERIC_WAGE_SHARE_OBJECTS_REJECTED|PASS|Generic or unclear wage-share objects are not authorized.|
|NFC_WAGE_SHARE_BASELINE_AUTHORIZED_OR_FAILED_CLOSED|PASS|NFC decision: AUTHORIZE_S20C_NFC_WAGE_SHARE_SOURCE_CONTRACT|
|CORPORATE_WAGE_SHARE_ROBUSTNESS_AUTHORIZED_OR_FAILED_CLOSED|PASS|Corporate robustness decision: AUTHORIZE_CORPORATE_WAGE_SHARE_ROBUSTNESS_SOURCE_CONTRACT|
|PROFIT_SHARE_ALTERNATIVE_ONLY|PASS|Profit share is kept as alternative/reconciliation evidence only.|
|SHAIKH_BLOCKED_UNLESS_CROSSWALK_PLUS_DATA|PASS|No Shaikh-adjusted object is authorized; blocked pending crosswalk plus data.|
|NO_S20_PANEL_ATTACHMENT_PERFORMED|PASS|S20C creates source contracts only; no S20 panel merge is performed.|
|FINAL_DECISION_EXPLICIT|PASS|AUTHORIZE_S20D_DISTRIBUTION_ATTACHMENT_PROMPT|

## Final Decision

`AUTHORIZE_S20D_DISTRIBUTION_ATTACHMENT_PROMPT`
