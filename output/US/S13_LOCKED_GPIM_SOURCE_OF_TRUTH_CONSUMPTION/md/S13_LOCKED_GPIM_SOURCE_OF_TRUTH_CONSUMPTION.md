# S13 Locked GPIM Source-of-Truth Consumption

## Consumption Gate

S13 consumed the locked S12D-C contract and creates the downstream-facing GPIM source panel. The panel contains only baseline-consumable S12D-C objects.

## Integration Boundary

- S13 did not reconstruct GPIM stocks.
- S13 did not run S20, S21, or S22.
- S13 did not run econometrics.
- S13 did not modify provider data.
- The diagnostic net-value stock remains excluded.
- `FAAt402` remains validation-only.
- NFC output-price translation remains robustness-only.
- Productive-efficiency objects remain not constructed.

## Source Panel

| asset_block | variable_id | object_role | unit | span_and_rows |
|---|---|---|---|---|
| ME | I_NOMINAL_DIRECT_ME | DIRECT_NOMINAL_INVESTMENT_CANONICAL | current_millions | 1901-2024 (124 rows) |
| NRC | I_NOMINAL_DIRECT_NRC | DIRECT_NOMINAL_INVESTMENT_CANONICAL | current_millions | 1901-2024 (124 rows) |
| ME | P_K_SFC_ME_2017_100 | SFC_IMPLICIT_BASELINE_PRICE | index_2017_100 | 1925-2024 (100 rows) |
| NRC | P_K_SFC_NRC_2017_100 | SFC_IMPLICIT_BASELINE_PRICE | index_2017_100 | 1931-2024 (94 rows) |
| ME | K_GROSS_GPIM_ME | GROSS_SURVIVAL_GPIM_STOCK_BASELINE | millions_2017 | 1925-2024 (100 rows) |
| NRC | K_GROSS_GPIM_NRC | GROSS_SURVIVAL_GPIM_STOCK_BASELINE | millions_2017 | 1931-2024 (94 rows) |
| ME | I_REAL_GPIM_ME | REAL_INVESTMENT_BASELINE | millions_2017 | 1901-2024 (124 rows) |
| NRC | I_REAL_GPIM_NRC | REAL_INVESTMENT_BASELINE | millions_2017 | 1901-2024 (124 rows) |

## Consumption Audit

| asset_block | object_role | consumed | source_table | variable_ids_created | evidence |
|---|---|---|---|---|---|
| ME | SFC_IMPLICIT_BASELINE_PRICE | yes | S12D_B_sfc_implicit_price_indexes.csv | P_K_SFC_ME_2017_100 | 100 source-panel rows with status BASELINE_CONSUMABLE. |
| ME | DIRECT_NOMINAL_INVESTMENT_CANONICAL | yes | S12D_B_real_investment_flows.csv | I_NOMINAL_DIRECT_ME | 124 source-panel rows with status BASELINE_CONSUMABLE. |
| ME | REAL_INVESTMENT_BASELINE | yes | S12D_B_real_investment_flows.csv | I_REAL_GPIM_ME | 124 source-panel rows with status BASELINE_CONSUMABLE. |
| ME | GROSS_SURVIVAL_GPIM_STOCK_BASELINE | yes | S12D_B_gpim_stock_panel.csv | K_GROSS_GPIM_ME | 100 source-panel rows with status BASELINE_CONSUMABLE. |
| NRC | SFC_IMPLICIT_BASELINE_PRICE | yes | S12D_B_sfc_implicit_price_indexes.csv | P_K_SFC_NRC_2017_100 | 94 source-panel rows with status BASELINE_CONSUMABLE. |
| NRC | DIRECT_NOMINAL_INVESTMENT_CANONICAL | yes | S12D_B_real_investment_flows.csv | I_NOMINAL_DIRECT_NRC | 124 source-panel rows with status BASELINE_CONSUMABLE. |
| NRC | REAL_INVESTMENT_BASELINE | yes | S12D_B_real_investment_flows.csv | I_REAL_GPIM_NRC | 124 source-panel rows with status BASELINE_CONSUMABLE. |
| NRC | GROSS_SURVIVAL_GPIM_STOCK_BASELINE | yes | S12D_B_gpim_stock_panel.csv | K_GROSS_GPIM_NRC | 94 source-panel rows with status BASELINE_CONSUMABLE. |

## Validation Checks

| check_id | status | evidence |
|---|---|---|
| S12D_C_READINESS_ALL_PASS | PASS | 15/15 S12D-C readiness checks are PASS. |
| S12D_C_DECISION_AUTHORIZES_CONSUMPTION | PASS | Exact AUTHORIZE_NEXT_LAYER_CONSUMPTION decision line count: 1. |
| CONSUMPTION_CONTRACT_PRESENT | PASS | Observed 16 S12D-C contract rows. |
| ONLY_BASELINE_CONSUMABLE_OBJECTS_USED | PASS | Consumed roles: DIRECT_NOMINAL_INVESTMENT_CANONICAL, GROSS_SURVIVAL_GPIM_STOCK_BASELINE, REAL_INVESTMENT_BASELINE, SFC_IMPLICIT_BASELINE_PRICE. |
| NON_BASELINE_OBJECTS_EXCLUDED | PASS | Excluded roles found in source panel: 0. |
| ME_AND_NRC_PRESENT | PASS | Observed asset blocks: ME, NRC. |
| SFC_PRICE_VARIABLES_CREATED | PASS | Created P_K_SFC_ME_2017_100 and P_K_SFC_NRC_2017_100. |
| DIRECT_NOMINAL_INVESTMENT_VARIABLES_CREATED | PASS | Created both direct nominal investment variables. |
| REAL_INVESTMENT_VARIABLES_CREATED | PASS | Created I_REAL_GPIM_ME and I_REAL_GPIM_NRC. |
| GROSS_GPIM_STOCK_VARIABLES_CREATED | PASS | Created K_GROSS_GPIM_ME and K_GROSS_GPIM_NRC. |
| SOURCE_PANEL_NONEMPTY | PASS | Source panel contains 884 finite observations across 8 variables. |
| SOURCE_PANEL_UNIQUE_KEYS | PASS | Duplicate asset-year-variable keys: 0. |
| S12D_B_ROLE_LEDGER_MATCHES_CONTRACT | PASS | S12D-B ledger exposes 8 baseline asset-role combinations. |
| S12D_B_VALIDATION_AND_RECONSTRUCTION_PASS | PASS | 21/21 S12D-B validations and 2/2 reconstruction checks are PASS. |
| NO_S20_S21_S22_RUN | PASS | S13 reads only the named S12D-B and S12D-C artifacts. |
| NO_ECONOMETRICS_RUN | PASS | S13 creates no econometric object and invokes no econometric script. |
| NO_PROVIDER_MODIFICATION | PASS | S13 reads no provider repository path and modifies no provider data. |
| FINAL_DECISION_EXPLICIT | PASS | Final decision resolved explicitly as AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION. |

## Final Decision

**AUTHORIZE_DOWNSTREAM_GPIM_CONSUMPTION**
