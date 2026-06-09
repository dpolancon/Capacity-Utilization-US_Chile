# U.S. BEA Provider Import Validation Report

## Import identity

- Upstream repo: `C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset`
- Locked upstream commit: `9ca9f791a1cc01be60ce0d922bc2098223efc028`
- Locked upstream tag: `us-bea-provider-menu-shaikh-blocked-2026-06-09`
- Observed upstream HEAD: `9ca9f791a1cc01be60ce0d922bc2098223efc028`
- Downstream repo: `C:/ReposGitHub/Capacity-Utilization-US_Chile`
- Import layer: `S00` provider artifact import and validation only

## Imported files

- `data/metadata/us_bea_variable_menu_locked.csv` -> `data/external/us_bea_provider/us_bea_variable_menu_locked.csv`
- `data/metadata/us_bea_variable_menu_locked.json` -> `data/external/us_bea_provider/us_bea_variable_menu_locked.json`
- `data/metadata/us_bea_source_provenance_ledger.csv` -> `data/external/us_bea_provider/us_bea_source_provenance_ledger.csv`
- `data/metadata/us_bea_shaikh_candidate_line_semantic_audit.csv` -> `data/external/us_bea_provider/us_bea_shaikh_candidate_line_semantic_audit.csv`
- `data/staged/us_bea_variable_menu_long.csv` -> `data/external/us_bea_provider/us_bea_variable_menu_long.csv`
- `docs/US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md` -> `docs/data_sources/US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md`
- `docs/US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md` -> `docs/data_sources/US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md`
- `docs/US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md` -> `docs/data_sources/US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md`
- `docs/US_BEA_SHAIKH_LINE_SEMANTIC_AUDIT.md` -> `docs/data_sources/US_BEA_SHAIKH_LINE_SEMANTIC_AUDIT.md`
- `docs/US_BEA_SHAIKH_SEMANTIC_PROPAGATION_PATCH.md` -> `docs/data_sources/US_BEA_SHAIKH_SEMANTIC_PROPAGATION_PATCH.md`

## Validation

| Validation check | Expected | Observed | Result |
|---|---|---|:---:|
| Upstream HEAD is at or contains the locked commit | 9ca9f791a1cc01be60ce0d922bc2098223efc028 | 9ca9f791a1cc01be60ce0d922bc2098223efc028 | PASS |
| Locked tag resolves to the locked commit | 9ca9f791a1cc01be60ce0d922bc2098223efc028 | 9ca9f791a1cc01be60ce0d922bc2098223efc028 | PASS |
| Required upstream files match the checked-out commit | no path modifications | no path modifications | PASS |
| All required provider files copied byte-for-byte | 10 | 10 | PASS |
| Manifest rows | 175 | 175 | PASS |
| Provenance ledger rows | 175 | 175 | PASS |
| Staged long rows | 9438 | 9438 | PASS |
| Distinct staged variable_id values | 94 | 94 | PASS |
| Manifest variable_id values are unique | 175 | 175 | PASS |
| Provenance variable_id values are unique | 175 | 175 | PASS |
| Manifest and provenance variable_id sets are identical | identical sets | 0 differences | PASS |
| All staged variable_id values exist in manifest | 0 missing | 0 missing | PASS |
| All staged variable_id values exist in provenance ledger | 0 missing | 0 missing | PASS |
| All eight T711 candidate lines are staged | T711_L4; T711_L44; T711_L73; T711_L28; T711_L52; T711_L91; T711_L74; T711_L53 | T711_L28; T711_L4; T711_L44; T711_L52; T711_L53; T711_L73; T711_L74; T711_L91 | PASS |
| T711 staged rows | 592 | 592 | PASS |
| Every staged T711 row has the candidate-line role tag | shaikh_candidate_line_ingredient | shaikh_candidate_line_ingredient | PASS |
| Every staged T711 row is restricted to semantic audit | shaikh_candidate_semantic_audit_only | shaikh_candidate_semantic_audit_only | PASS |
| No staged T711 field equals a prohibited role or constructed object | none | none | PASS |
| Semantic audit contains exactly the eight T711 candidates | T711_L4; T711_L44; T711_L73; T711_L28; T711_L52; T711_L91; T711_L74; T711_L53 | T711_L28; T711_L4; T711_L44; T711_L52; T711_L53; T711_L73; T711_L74; T711_L91 | PASS |
| Shaikh semantic admissibility is BLOCKED | BLOCKED pending historical/current semantic crosswalk | BLOCKED | PASS |
| wage share documented as preferred distributive state | preferred distributive state | documented | PASS |
| exploitation rate documented as alternative proxy | alternative proxy | documented | PASS |
| Required GOV_TRANS gross-investment variables map to FAAt705 | GOV_TRANS__HIGHWAYS_STREETS__gross_investment_current_cost; GOV_TRANS__TRANSPORTATION_STRUCTURES__gross_investment_current_cost | GOV_TRANS__HIGHWAYS_STREETS__gross_investment_current_cost -> FAAt705; GOV_TRANS__TRANSPORTATION_STRUCTURES__gross_investment_current_cost -> FAAt705 | PASS |
| GOV_TRANS remains a frontier conditioner | frontier_conditioner | frontier_conditioner | PASS |
| IPP remains a frontier conditioner | frontier_conditioner | frontier_conditioner | PASS |
| ME and NRC remain direct productive-capacity capital | direct_productive_capacity_capital | direct_productive_capacity_capital | PASS |
| No downstream analytical object is constructed in S00 | none | provider artifacts and validation outputs only | PASS |

**Overall result: PASS.**

## T711 blocked status

All eight T711 candidate lines are imported as `shaikh_candidate_line_ingredient` rows restricted to `shaikh_candidate_semantic_audit_only`.
Shaikh-adjusted construction remains **BLOCKED** pending a documented historical/current semantic crosswalk.

## Scope boundary

This S00 pass imports provider artifacts only and does not construct analytical Chapter 2 variables.
S00 validates only provider-artifact import and the distributive-state hierarchy. It does not define, validate, or construct downstream interaction variables. The econometric operationalization of distribution-conditioned accumulation is governed by the Chapter 2 vault/econometric implementation notes and must not be inferred from provider metadata.
It constructs no GPIM stocks, Shaikh-adjusted income variables, distributive variables, interactions, capacity or utilization variables, S10/S20/S30 datasets, or econometric outputs.

The machine-readable validation ledger is:

- `data/external/us_bea_provider/US_BEA_PROVIDER_IMPORT_VALIDATION_LEDGER.csv`
