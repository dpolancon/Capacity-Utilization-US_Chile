# U.S. S10 Source-of-Truth Scaffold Validation

**Overall result: PASS.**

## Scope lock

- S10 reads only from downstream provider artifacts.
- S10 performs no BEA fetch.
- S10 does not alter provider artifacts.
- S10 does not construct GPIM stocks yet.
- S10 does not construct Shaikh-adjusted variables.
- S10 does not estimate regressions.
- S10 registers unadjusted wage share as the first-pass baseline pending construction.
- S10 registers all Shaikh-adjusted variables as blocked.
- S10 preserves the q_omega/q_e accumulated-index locks.
- S10 preserves IPP and GOV_TRANS as frontier conditioners.
- S10 is a source-of-truth scaffold, not the final model-ready dataset.

## Validation checks

|validation_check|expected|observed|result|
|---|---|---|---|
|IPP and GOV_TRANS objects remain frontier conditioners|10|10|PASS|
|All level-interaction objects and provider contracts are superseded diagnostics only|all matched rows superseded|12 superseded rows|PASS|
|Manifest rows|175|175|PASS|
|No BEA fetch occurred|local file reads only|local provider artifacts read; no network/fetch function executed|PASS|
|S10 constructs no GPIM stocks|pending registry only|pending registry only|PASS|
|S10 estimates no regressions|none|none|PASS|
|S10 constructs no Shaikh-adjusted variables|blocked registry only|blocked registry only|PASS|
|Provenance rows|175|175|PASS|
|Provider artifacts are unchanged by S10|all hashes unchanged|4/4 unchanged|PASS|
|All four locked provider inputs are present|4|4|PASS|
|All source files resolve inside the downstream provider directory|provider-only paths|provider-only paths|PASS|
|All q_omega/q_e objects are pending and not constructed|6|6|PASS|
|All required pending downstream objects are registered|53|53|PASS|
|All Shaikh-style and adjusted contracts are blocked pending the current-release protocol|all matched rows blocked|17 blocked rows|PASS|
|S10 source-panel rows|9438|9438|PASS|
|S10 source-panel distinct variable_id values|94|94|PASS|
|Every staged variable_id exists in the manifest|0 missing|0 missing|PASS|
|Every staged variable_id exists in the provenance ledger|0 missing|0 missing|PASS|
|Staged annual observations|9438|9438|PASS|
|Distinct staged source variables|94|94|PASS|

## Output counts

- Source panel rows: 9438
- Object admissibility ledger rows: 236
- Provider validation checks: 20

## Locked analytical boundary

`q_omega_h1_Kcap` is the preferred inherited one-period A00 object. `q_omega_h3_Kcap` and `q_omega_h5_Kcap` are restricted robustness states. The `q_e_*` family is alternative-proxy robustness.
All Shaikh-style adjusted objects remain `blocked_pending_current_release_protocol`; current T711 lines remain candidate provenance ingredients only.
IPP and GOV_TRANS remain frontier conditioners and do not enter private `K_cap` as additive capital terms.
