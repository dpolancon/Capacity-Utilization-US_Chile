# S12C Capital Input and GPIM Protocol

## Purpose

S12C prepares the locked NFC ME/NRC capital source observations and records the GPIM protocol boundary. It does not construct real investment or any GPIM stock.

## Inherited locks

- Direct FAAt407 nominal ME/NRC investment is canonical.
- FAAt402 is comparison/validation-only.
- Implied investment is fallback-only and requires a valid revaluation term.
- GPIM stocks remain blocked pending a real-investment price-treatment lock.
- No S20/S21/S22, adjusted distribution, or econometric code is run.

## Capital inputs prepared

| variable_name | role | source_table | start_year | end_year | observations |
|---|---|---|---|---|---|
| I_NOM_NFC_ME_DIRECT | baseline_input | FAAt407 | 1901 | 2024 | 124 |
| I_NOM_NFC_NRC_DIRECT | baseline_input | FAAt407 | 1901 | 2024 | 124 |
| CFC_CC_NFC_ME_INPUT | diagnostic | FAAt404 | 1925 | 2024 | 100 |
| CFC_CC_NFC_NRC_INPUT | diagnostic | FAAt404 | 1925 | 2024 | 100 |
| K_NET_CC_NFC_ME_VALIDATION | validation | FAAt401 | 1925 | 2024 | 100 |
| K_NET_CC_NFC_NRC_VALIDATION | validation | FAAt401 | 1925 | 2024 | 100 |
| Q_K_BEAFIXEDASSETS_ME_VALIDATION | validation_only | FAAt402 | 1925 | 2024 | 100 |
| Q_K_BEAFIXEDASSETS_NRC_VALIDATION | validation_only | FAAt402 | 1925 | 2024 | 100 |

- Capital input observation rows: 848

## GPIM parameters

| parameter_name | asset_block | parameter_value | parameter_unit | status |
|---|---|---|---|---|
| L_ME | ME | 14.0 | years | methodological_metadata_ready |
| alpha_ME | ME |  1.7 | Weibull shape parameter | methodological_metadata_ready |
| L_NRC | NRC | 30.0 | years | methodological_metadata_ready |
| alpha_NRC | NRC |  1.6 | Weibull shape parameter | methodological_metadata_ready |

## FAAt402 status

NFC ME and NRC FAAt402 Fisher quantity indexes are retained only for comparison with a future real-stock trajectory. They are prohibited as baseline stocks, capital prices, revaluation indexes, GPIM inputs, or GPIM products.

## Implied-investment fallback status

The stock-flow-implied ME/NRC investment formulas are not activated. Direct FAAt407 nominal investment remains canonical, and the missing asset revaluation terms keep implied investment fallback-only.

## Capital-price treatment options

| protocol_item | asset_block | baseline_allowed | decision | reason |
|---|---|---|---|---|
| ME_price_option_A_direct_asset_specific_index | ME | FALSE | not_available_or_not_locked | No same-boundary canonical ME investment price index has been locked for the GPIM baseline. |
| ME_price_option_B_FAAt402_quantity_index | ME | FALSE | prohibited_for_baseline | FAAt402 is a BEA Fisher quantity-index comparison object, not a GPIM price index or GPIM product. |
| ME_price_option_C_output_price_deflation | ME | pending_protocol_lock | candidate_protocol_option | This may provide a common-output-unit normalization but is not an asset-specific investment price. |
| ME_price_option_D_nominal_current_cost_bookkeeping | ME | pending_protocol_lock | candidate_protocol_option | Nominal consistency does not by itself yield a real productive-capacity capital stock. |
| NRC_price_option_A_direct_asset_specific_index | NRC | FALSE | not_available_or_not_locked | No same-boundary canonical NRC investment price index has been locked for the GPIM baseline. |
| NRC_price_option_B_FAAt402_quantity_index | NRC | FALSE | prohibited_for_baseline | FAAt402 is a BEA Fisher quantity-index comparison object, not a GPIM price index or GPIM product. |
| NRC_price_option_C_output_price_deflation | NRC | pending_protocol_lock | candidate_protocol_option | This may provide a common-output-unit normalization but is not an asset-specific investment price. |
| NRC_price_option_D_nominal_current_cost_bookkeeping | NRC | pending_protocol_lock | candidate_protocol_option | Nominal consistency does not by itself yield a real productive-capacity capital stock. |

## Protocol decision required before GPIM construction

S12C prepares the capital inputs but does not construct GPIM stocks. Before S12D can construct GPIM stocks, the project must lock the real-investment price treatment. FAAt402 cannot supply this role. Direct nominal ME/NRC investment remains canonical, while implied investment remains fallback-only.

The admissible candidates still requiring review are:

- Output-price deflation with `P_Y_NFC_GVA_IMPLICIT_SOURCE` as a common-output-unit normalization.
- Nominal/current-cost bookkeeping that preserves nominal consistency without claiming a real productive-capacity stock.

## Validation results

| validation_rule | result | observed |
|---|---|---|
| direct ME nominal investment input present | PASS | 124 |
| direct NRC nominal investment input present | PASS | 124 |
| ME current-cost net-stock validation input present | PASS | 100 |
| NRC current-cost net-stock validation input present | PASS | 100 |
| ME CFC/depreciation input present | PASS | 100 |
| NRC CFC/depreciation input present | PASS | 100 |
| FAAt402 ME observations retained only as validation/comparison | PASS | 100 validation-only rows |
| FAAt402 NRC observations retained only as validation/comparison | PASS | 100 validation-only rows |
| GPIM parameters present | PASS | L_ME; alpha_ME; L_NRC; alpha_NRC |
| no GPIM stock constructed | PASS | capital source inputs only |
| no FAAt402 baseline use | PASS | FAAt402 appears only in validation_only rows |
| no implied investment baseline use | PASS | fallback ledger only; no implied observation series |
| no revaluation-index fallback activated | PASS | ME/NRC revaluation terms remain unavailable |
| capital-price treatment remains pending | PASS | S12D remains blocked pending protocol lock |
| no S20/S21/S22 run | PASS | S12C script only |
| no econometric outputs created | PASS | capital inputs and protocol metadata only |

## Next construction step

The next step is S12D only after a GPIM price-treatment protocol is locked. S12D may then construct GPIM ME/NRC gross stocks and Kcap. Until then, proceed only to protocol review, not GPIM construction.
