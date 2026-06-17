# S20B Distribution Attachment Contract

## Scope

S20B is a bounded data-architecture layer after the current S20 model-input layer. It audits repo-local distribution candidates and decides whether an already-authorized unadjusted wage-share source can attach to current S20. It does not reconstruct GPIM, run provider discovery, modify provider data, invoke S21/S22/S30/S32, estimate econometric objects, construct theta, construct productive capacity, construct capacity utilization, or build accumulated q.

## Governing Inputs

- `output/US/S20_MODEL_INPUT_LAYER/`
- `output/US/S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION/`
- repo-local processed/ledger/report artifacts used only for distribution-source audit

## Candidate Source Summary

|candidate_status|candidate_count|
|---|---:|
|AUDITED_INGREDIENT_ONLY_NOT_ATTACHABLE| 8|
|AUDITED_NOT_ATTACHABLE_CURRENT_S20|16|
|AUDITED_REFERENCE_ONLY| 4|
|BLOCKED|15|
|BLOCKED_LEGACY_OR_ECONOMETRIC_ARTIFACT|16|
|BLOCKED_OR_OPTIONAL_NOT_ATTACHABLE| 3|
|PENDING_NOT_ATTACHABLE| 1|
|REGISTERED_OR_PENDING_NOT_ATTACHABLE|20|

The audit found historical and legacy unadjusted wage-share observations, including old `data/processed/us_s20` objects and S10 ingredient registrations. Those artifacts are not current S20 attachment authority. The current governing S20 distribution ledger keeps `WAGE_SHARE_UNADJUSTED_BASELINE` at `PENDING_AUTHORIZED_SOURCE`, and the current S20 model-input panel contains no distribution attachment variable.

## Attachment Contract

|contract_id|role|status|source_path|variable_id|
|---|---|---|---|---|
|WAGE_SHARE_UNADJUSTED_BASELINE|PREFERRED_UNADJUSTED_WAGE_SHARE_BASELINE|DISTRIBUTION_ATTACHMENT_BLOCKED_PENDING_AUTHORIZED_WAGE_SHARE_SOURCE|not_authorized|pending_authorized_unadjusted_wage_share|
|PROFIT_SHARE_ALTERNATIVE_RECONCILIATION|ALTERNATIVE_OR_RECONCILIATION_EVIDENCE|RECORDED_NOT_PROMOTED|candidate_ledgers_only|pi_res_* or pi candidates|
|SHAIKH_ADJUSTED_DISTRIBUTION_OBJECTS|SHAIKH_ADJUSTMENT_BLOCKED_PENDING_CROSSWALK_AND_DATA|SHAIKH_ADJUSTMENT_BLOCKED_PENDING_CROSSWALK_AND_DATA|not_authorized|omega_adj_* / pi_adj_* candidates|

The preferred baseline remains an unadjusted wage share. S20B does not construct it from S10 ingredients and does not promote legacy panels. Profit-share candidates are retained only as alternative or reconciliation evidence. Shaikh-adjusted objects remain blocked unless a current-release semantic/accounting crosswalk and data contract both pass.

## Validation

|check_id|status|evidence|
|---|---|---|
|HEAD_AND_ORIGIN_AT_874D19D|PASS|HEAD=874d19d; origin/main=874d19d; branch=main.|
|S20_OUTPUTS_FOUND|PASS|Found 6 current S20 artifacts.|
|S20_VALIDATION_ALL_PASS|PASS|31/31 S20 checks PASS.|
|S20_DECISION_AUTHORIZES_MODEL_INPUT_CONSUMPTION|PASS|AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION recognized in current S20 report/validation.|
|S14_OUTPUTS_FOUND_AND_PASS|PASS|S14 panel found; S14 PASS checks: 13/13.|
|CURRENT_S20_CAPITAL_LAYER_UNCHANGED|PASS|S20B left current S20 artifacts byte-identical during execution.|
|NO_CURRENT_S20_DISTRIBUTION_PANEL_ATTACHMENT|PASS|Current output/US/S20_MODEL_INPUT_LAYER panel contains no omega/wage/profit attachment variables.|
|CANDIDATE_SOURCES_AUDITED|PASS|Candidate audit rows: 83|
|WAGE_SHARE_BASELINE_PRESERVED|PASS|Unadjusted wage share remains the preferred baseline role.|
|PROFIT_SHARE_ALTERNATIVE_ONLY|PASS|Profit share is recorded only as alternative/reconciliation evidence.|
|SHAIKH_BLOCKED_UNLESS_CROSSWALK_AND_DATA|PASS|No Shaikh-adjusted object is authorized; blocked pending crosswalk and data.|
|NO_DOWNSTREAM_SCRIPTS_INVOKED|PASS|S20B script contains no source/system invocation of S21/S22/S30/S32 scripts.|
|NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED|PASS|S20B reads repo-local outputs/docs/processed ledgers only; provider/raw roots are not inputs.|
|NO_GPIM_RECONSTRUCTION|PASS|S20B does not reconstruct GPIM or alter S20 capital outputs.|
|DATA_ARCHITECTURE_ONLY_NOT_ECONOMETRICS|PASS|No econometric estimator, theta, productive-capacity, utilization, or q object is constructed.|
|ATTACHMENT_AUTHORIZED_OR_FAILED_CLOSED|PASS|Final decision: BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION|
|FINAL_DECISION_EXPLICIT|PASS|BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION|

## Final Decision

`BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION`
