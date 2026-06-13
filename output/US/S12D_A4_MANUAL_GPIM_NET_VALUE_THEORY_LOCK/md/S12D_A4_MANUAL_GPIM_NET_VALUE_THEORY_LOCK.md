# S12D-A4 Manual GPIM Net-Value Theory Lock

## Why A Manual Lock Was Required

S12D-A3 found explicit external declining-balance age-price evidence for ME and NRC, but the evidence did not automatically authorize combining those value-decay rates with the project's separate finite Weibull survival schedules. S12D-A4 records the dissertation-level choice that resolves that conceptual boundary.

## Exact Manual Lock

For the Chapter 2 GPIM baseline, net-value weights are defined separately from physical survival as V_i(j)=S_i(j)(1-d_i)^j, where S_i(j) is the locked asset-specific Weibull survival schedule and the externally documented declining-balance age-price rates are d_ME=0.110 and d_NRC=0.024. These rates are age-price/depreciation anchors only; they are not retirement rates, productive-efficiency profiles, FAAt402 price indexes, NFC output deflators, or final capital-price indexes.

## Locked Parameterization

| asset_block | survival_profile | L | alpha | age_price_profile | d | net_value_schedule | baseline_status |
|---|---|---|---|---|---|---|---|
| ME | Weibull | 14.0 | 1.7 | declining_balance_geometric | 0.110 | V_ME(j)=S_ME(j)*(1-0.110)^j | LOCKED_FOR_S12D_B |
| NRC | Weibull | 30.0 | 1.6 | declining_balance_geometric | 0.024 | V_NRC(j)=S_NRC(j)*(1-0.024)^j | LOCKED_FOR_S12D_B |

## Interpretation

1. Physical survival remains the locked asset-specific Weibull schedule.
2. Age-price decline uses the externally anchored asset-specific rates.
3. Net-value weights combine survival and age-price decline.
4. The SFC implicit capital price remains recovered recursively.
5. The recovered SFC price is not FAAt402.
6. The recovered SFC price is not the NFC output deflator.
7. Productive-efficiency profiles remain separate and unconstructed.

## Capital-Price Boundary

This lock defines value weights; it does not promote FAAt402 or the NFC output deflator. FAAt402 remains a quality-adjusted quantity-index validation object. The NFC output price remains an output-unit translation or robustness route. S12D-B must recover the asset-specific SFC implicit price by recursion under the locked schedules.

## Construction Boundary

S12D-A4 records protocol metadata only. It does not deflate investment, run the GPIM recursion, construct a final stock, run S20/S21/S22, or create econometric output.

## Stage-Gate Decision

- Decision: `AUTHORIZE_S12D_B`.
- S12D-B is authorized as the next construction step under the exact manual lock and inherited provider/price boundaries.
- Final GPIM stocks constructed in this pass: no.

## Validation

| validation_rule | result | observed |
|---|---|---|
| exact manual lock sentence recorded | PASS | For the Chapter 2 GPIM baseline, net-value weights are defined separately from physical survival as V_i(j)=S_i(j)(1-d_i)^j, where S_i(j) is the locked asset-specific Weibull survival schedule and the externally documented declining-balance age-price rates are d_ME=0.110 and d_NRC=0.024. These rates are age-price/depreciation anchors only; they are not retirement rates, productive-efficiency profiles, FAAt402 price indexes, NFC output deflators, or final capital-price indexes. |
| parameter ledger has exactly ME and NRC rows | PASS | ME; NRC |
| ME depreciation rate locked | PASS | 0.110 |
| NRC depreciation rate locked | PASS | 0.024 |
| ME Weibull parameters unchanged | PASS | L=14; alpha=1.7 |
| NRC Weibull parameters unchanged | PASS | L=30; alpha=1.6 |
| age-price profile locked separately from survival | PASS | V_ME(j)=S_ME(j)*(1-0.110)^j; V_NRC(j)=S_NRC(j)*(1-0.024)^j |
| both schedules locked for S12D-B | PASS | LOCKED_FOR_S12D_B; LOCKED_FOR_S12D_B |
| FAAt402 not baseline capital-price route | PASS | validation only |
| NFC output price not baseline capital-price route | PASS | output translation/robustness only |
| productive-efficiency profile remains separate | PASS | not constructed |
| no final GPIM stocks constructed | PASS | lock metadata only |
| no S20/S21/S22 run | PASS | S12D-A4 only |
| no econometric output created | PASS | none |
| exactly one final stage-gate decision | PASS | AUTHORIZE_S12D_B |
| S12D-B authorization requires recorded manual lock | PASS | exact sentence recorded before authorization |
| S12D-A3 rates inherited without alteration | PASS | ME=0.110; NRC=0.024 |
