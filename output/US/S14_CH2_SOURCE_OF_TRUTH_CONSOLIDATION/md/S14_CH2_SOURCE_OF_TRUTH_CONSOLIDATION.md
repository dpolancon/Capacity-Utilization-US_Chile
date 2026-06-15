# S14 Chapter 2 Source-of-Truth Consolidation

## Architecture Result

S14 registers the locked S13 GPIM baseline in the Chapter 2 source-of-truth architecture. The consolidation panel preserves all 884 S13 observations and registers exactly the eight authorized GPIM variables for the bounded S20 model-input layer.

## Registered Object Roles

| variable_id | asset_block | object_role | source_of_truth_role | unit | coverage_start | coverage_end | observation_count | registration_status |
|---|---|---|---|---|---|---|---|---|
| I_NOMINAL_DIRECT_ME | ME | DIRECT_NOMINAL_INVESTMENT_CANONICAL | canonical_nominal_investment_input | current_millions | 1901 | 2024 | 124 | REGISTERED_BASELINE |
| I_NOMINAL_DIRECT_NRC | NRC | DIRECT_NOMINAL_INVESTMENT_CANONICAL | canonical_nominal_investment_input | current_millions | 1901 | 2024 | 124 | REGISTERED_BASELINE |
| P_K_SFC_ME_2017_100 | ME | SFC_IMPLICIT_BASELINE_PRICE | baseline_capital_price_input | index_2017_100 | 1925 | 2024 | 100 | REGISTERED_BASELINE |
| P_K_SFC_NRC_2017_100 | NRC | SFC_IMPLICIT_BASELINE_PRICE | baseline_capital_price_input | index_2017_100 | 1931 | 2024 |  94 | REGISTERED_BASELINE |
| I_REAL_GPIM_ME | ME | REAL_INVESTMENT_BASELINE | baseline_real_investment_input | millions_2017 | 1901 | 2024 | 124 | REGISTERED_BASELINE |
| I_REAL_GPIM_NRC | NRC | REAL_INVESTMENT_BASELINE | baseline_real_investment_input | millions_2017 | 1901 | 2024 | 124 | REGISTERED_BASELINE |
| K_GROSS_GPIM_ME | ME | GROSS_SURVIVAL_GPIM_STOCK_BASELINE | baseline_gross_capital_stock_input | millions_2017 | 1925 | 2024 | 100 | REGISTERED_BASELINE |
| K_GROSS_GPIM_NRC | NRC | GROSS_SURVIVAL_GPIM_STOCK_BASELINE | baseline_gross_capital_stock_input | millions_2017 | 1931 | 2024 |  94 | REGISTERED_BASELINE |

## Boundary Enforcement

- S14 consumes only the S13 panel, audit, validation table, and report.
- S14 does not reconstruct GPIM or reopen provider discovery.
- S14 does not read or modify provider files.
- S14 does not invoke S20, S21, S22, S30I, S30, or S32.
- S14 creates no econometric or productive-efficiency object.
- The diagnostic net-value stock does not enter S14.
- `FAAt402` remains validation-only historical context.
- NFC output-price translation remains robustness-only historical context.

## Validation Checks

| check_id | status | evidence |
|---|---|---|
| S13_VALIDATION_ALL_PASS | PASS | 18/18 S13 validation checks are PASS. |
| S13_DECISION_AUTHORIZES_DOWNSTREAM_GPIM | PASS | Exact AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION decision line count: 1. |
| EXACTLY_EIGHT_AUTHORIZED_GPIM_VARIABLES_REGISTERED | PASS | Registered 8 distinct variables: I_NOMINAL_DIRECT_ME, I_NOMINAL_DIRECT_NRC, I_REAL_GPIM_ME, I_REAL_GPIM_NRC, K_GROSS_GPIM_ME, K_GROSS_GPIM_NRC, P_K_SFC_ME_2017_100, P_K_SFC_NRC_2017_100. |
| ME_AND_NRC_ASSET_BLOCKS_PRESENT | PASS | Observed asset blocks: ME, NRC. |
| S13_AUDIT_COVERS_EIGHT_BASELINE_OBJECTS | PASS | 8/8 S13 audit rows are consumed=yes. |
| NO_NON_BASELINE_S12D_OBJECTS_ENTER_S14 | PASS | Non-baseline variable or role rows registered: 0. |
| S13_OBSERVATIONS_PRESERVED_WITHOUT_TRANSFORMATION | PASS | 884 finite observations registered; duplicate keys: 0; transformations applied: none. |
| NO_DOWNSTREAM_STAGE_SCRIPT_INVOKED | PASS | Executable S14 lines invoking S20/S21/S22/S30I/S30/S32: 0. |
| S14_DATA_ARCHITECTURE_ONLY | PASS | Econometric function calls found: 0; output layer is registration-only. |
| S13_INPUTS_UNCHANGED_DURING_CONSOLIDATION | PASS | 4/4 S13 input hashes unchanged after consumption. |
| NO_PROVIDER_FILES_REFERENCED_OR_MODIFIED | PASS | All four inputs resolve inside the S13 output directory; S14 has no provider input or provider write target. |
| OBJECT_ROLE_LEDGER_COMPLETE | PASS | 8 ledger rows register 884 observations. |
| FINAL_DECISION_EXPLICIT | PASS | Final decision resolved explicitly as AUTHORIZE_S20_MODEL_INPUT_LAYER. |

## Final Decision

**AUTHORIZE_S20_MODEL_INPUT_LAYER**
