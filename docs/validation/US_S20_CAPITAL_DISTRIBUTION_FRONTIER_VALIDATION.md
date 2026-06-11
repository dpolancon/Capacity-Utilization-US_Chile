# U.S. S20 Capital, Distribution, and Frontier Validation

**Overall result: PASS.**

## Purpose

S20 constructs the first-pass NFC productive-capacity capital block, unadjusted CORP/NFC distributive states, and IPP/GOV_TRANS frontier conditioners from locked S10 outputs.

## Upstream inputs

- `data/processed/us_s10/us_s10_source_panel_long.csv`
- `data/processed/us_s10/us_s10_object_admissibility_ledger.csv`
- `docs/data_sources/US_S10_SOURCE_OF_TRUTH_CONSTRUCTION_LEDGER.md`

## Constructed variables

- `K_ME`
- `K_NRC`
- `K_cap`
- `k_ME`
- `k_NRC`
- `k_Kcap`
- `g_K_ME`
- `g_K_NRC`
- `g_Kcap`
- `ME_NRC_gap`
- `ME_share`
- `NRC_share`
- `omega_CORP`
- `omega_NFC`
- `pi_res_CORP`
- `pi_res_NFC`
- `e_CORP`
- `e_NFC`
- `ln_e_CORP`
- `ln_e_NFC`
- `IPP_stock`
- `IPP_growth`
- `IPP_share_total_fixed_assets`
- `IPP_share_capital_plus_IPP`
- `IPP_to_Kcap`
- `GOV_TRANS_stock`
- `GOV_TRANS_growth`
- `GOV_TRANS_to_Kcap`
- `GOV_TRANS_to_NRC`
- `GOV_TRANS_to_ME`

## Blocked or unavailable variables

None. All 30 requested S20 variables were constructed.

## Validation summary

|check_name|status|details|
|---|---|---|
|ME_share plus NRC_share equals one|PASS|100 complete annual observations checked.|
|Construction ledger written|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_s20/us_s20_construction_ledger.csv|
|Construction report written|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/docs/data_sources/US_S20_CAPITAL_DISTRIBUTION_FRONTIER_LEDGER.md|
|GOV_TRANS is not included in private K_cap|PASS|The implemented identity is exactly K_cap = K_ME + K_NRC.|
|GOV_TRANS is retained only as a frontier conditioner|PASS|All GOV_TRANS targets are ledgered as frontier conditioners.|
|Growth rates are first differences of logs|PASS|All five requested growth series were recomputed and compared.|
|IPP is not included in K_cap|PASS|The implemented identity is exactly K_cap = K_ME + K_NRC.|
|IPP is retained only as a frontier conditioner|PASS|All IPP targets are ledgered as frontier conditioners.|
|K_cap equals K_ME plus K_NRC|PASS|100 complete annual observations checked.|
|Logs use strictly positive inputs only|PASS|Capital and exploitation-rate log outputs were audited.|
|Capital and IPP use the preferred NFC boundary|PASS|NFC__ME__net_stock_current_cost; NFC__NRC__net_stock_current_cost; NFC__IPP__net_stock_current_cost|
|No BEA fetch is called|PASS|Static scan found no network or BEA-fetch call.|
|No regressions or integration tests are run|PASS|Static call scan and output-column audit found no estimator or test.|
|No omega_x or e_x variable is constructed|PASS|Superseded level interactions are absent.|
|No q_e variable is constructed|PASS|Accumulated alternative-proxy indexes are deferred to S21.|
|No q_omega variable is constructed|PASS|Accumulated indexes are deferred to S21.|
|No Shaikh-adjusted variable is constructed|PASS|Panel columns contain unadjusted distribution variables only.|
|S20 output directory exists|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_s20|
|Panel output written|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_s20/us_s20_capital_distribution_frontier_panel.csv|
|No provider artifact is modified|PASS|6 provider files hashed unchanged.|
|S10 input files exist|PASS|3 required S10 inputs found.|
|S10 inputs are unchanged|PASS|3 S10 input hashes compared.|
|All requested S20 variables are ledgered|PASS|30 target variables.|
|IPP total-fixed-assets share uses an admissible denominator|PASS|NFC__TOTAL__net_stock_current_cost|
|Validation checks written|PASS|This check is recorded in the final validation-checks output.|
|Validation report written|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/docs/validation/US_S20_CAPITAL_DISTRIBUTION_FRONTIER_VALIDATION.md|

## Hard-lock confirmation

S20 did not fetch BEA data, modify provider artifacts, construct Shaikh-adjusted variables, build q indexes, construct superseded level interactions, run integration-order tests, estimate regressions, or reconstruct capacity utilization.
IPP and GOV_TRANS remain frontier conditioners and do not enter private `K_cap`.
