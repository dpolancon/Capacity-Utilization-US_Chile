# S12D-A2 Net-Value Schedule Protocol

## Purpose

S12D-A forced S12D-A2 because the net current-cost stock recursion recovered ME and NRC implicit prices only after imposing a candidate net age-price/value schedule. The locked observations identify the conditional price path, not the schedule that conditions it.

## Object Distinctions

1. The survival schedule measures physical vintage survival and uses the locked Weibull L and alpha parameters.
2. The age-price/net-value schedule measures remaining current-cost value conditional on survival. It is not identified by survival alone.
3. A productive-efficiency schedule would measure productive service contribution. It is a separate future object and is not constructed here.
4. The SFC implicit price index is recovered from direct nominal investment, a selected net-value schedule, and current-cost net-stock anchors. Its path is conditional on that schedule.

## Candidate Schedule Registry

| schedule_id | age_price_schedule | parameter_source | schedule_admissibility | baseline_lockable |
|---|---|---|---|---|
| SURVIVAL_ONLY_REJECTED | V(j) = S(j) | locked Weibull survival parameters only | REJECTED | FALSE |
| LINEAR_AGE_PRICE_CANDIDATE | V(j) = S(j) * max(1 - j/L, 0) | S12D-A candidate using locked L and alpha | SENSITIVITY_ONLY | FALSE |
| GEOMETRIC_AGE_PRICE_CANDIDATE | V(j) = S(j) * (1 - 1/L)^j | life-implied geometric rate delta = 1/L | REQUIRES_EXTERNAL_JUSTIFICATION | FALSE |
| BEA_STYLE_DECLINING_BALANCE_CANDIDATE | V(j) = S(j) * (1 - delta_CFC)^j | delta_CFC = median(CFC_CC/K_NET_CC) = 0.11603259 | REQUIRES_EXTERNAL_JUSTIFICATION | FALSE |
| HYBRID_SENSITIVITY_ONLY | V(j) = S(j) * 0.5 * [max(1-j/L,0) + (1-delta_CFC)^j] | equal-weight linear/CFC-rate sensitivity blend | SENSITIVITY_ONLY | FALSE |

The formulas are applied separately to ME and NRC using their locked Weibull parameters. The CFC-rate candidate uses each asset's median locked current-cost CFC/net-stock ratio only as an internal aggregate diagnostic.

## SFC Recovery Sensitivity

| asset_block | schedule_id | first_complete_vintage_year | minimum_price_index | maximum_price_index | max_abs_log_gap_vs_linear | max_abs_sfc_residual_pct | schedule_admissibility |
|---|---|---|---|---|---|---|---|
| ME | SURVIVAL_ONLY_REJECTED | 1925 | 65.098322 | 6988.6513 | 10.062617 | 0 | REJECTED |
| ME | LINEAR_AGE_PRICE_CANDIDATE | 1925 | 0.298026 | 138.8962 | 0.000000 | 0 | SENSITIVITY_ONLY |
| ME | GEOMETRIC_AGE_PRICE_CANDIDATE | 1925 | 6.922922 | 141.1105 | 3.293483 | 0 | REQUIRES_EXTERNAL_JUSTIFICATION |
| ME | BEA_STYLE_DECLINING_BALANCE_CANDIDATE | 1925 | 0.088958 | 154.3533 | 1.209016 | 0 | REQUIRES_EXTERNAL_JUSTIFICATION |
| ME | HYBRID_SENSITIVITY_ONLY | 1925 | 0.159885 | 146.6198 | 0.622724 | 0 | SENSITIVITY_ONLY |
| NRC | SURVIVAL_ONLY_REJECTED | 1931 | 0.835222 | 147.4275 | 4.745279 | 0 | REJECTED |
| NRC | LINEAR_AGE_PRICE_CANDIDATE | 1930 | 0.007565 | 220.5656 | 0.000000 | 0 | SENSITIVITY_ONLY |
| NRC | GEOMETRIC_AGE_PRICE_CANDIDATE | 1931 | 0.051790 | 186.9035 | 1.937285 | 0 | REQUIRES_EXTERNAL_JUSTIFICATION |
| NRC | BEA_STYLE_DECLINING_BALANCE_CANDIDATE | 1931 | 0.082182 | 179.7132 | 2.403761 | 0 | REQUIRES_EXTERNAL_JUSTIFICATION |
| NRC | HYBRID_SENSITIVITY_ONLY | 1931 | 0.031358 | 195.3594 | 1.432550 | 0 | SENSITIVITY_ONLY |

## Why Zero Residuals Do Not Validate a Schedule

The recursion solves the current price to reproduce the current-cost stock anchor for any positive candidate value schedule. Exact SFC fit is therefore an internal identity result. It cannot choose among linear, geometric, declining-balance, or hybrid age-price assumptions. The different normalized price ranges and gaps demonstrate this under-identification.

## Schedule Decision

No candidate is baseline-lockable. Survival-only is rejected because physical survival is not remaining value. The linear and hybrid forms remain sensitivity-only. The geometric and CFC-rate declining-balance forms require external age-price or depreciation-profile justification. The aggregate CFC/net-stock ratio does not identify a vintage profile.

## Stage Gate Decision

- Decision: `REQUIRE_S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR`.
- S12D-B authorized: no.
- Final GPIM stock construction authorized: no.
- Required next evidence: an external, asset-specific depreciation or age-price anchor that can justify a net-value schedule for both ME and NRC without using FAAt402 or the NFC output price as a capital-price baseline.

## Boundary Confirmation

- FAAt402 baseline use: no.
- NFC output-price baseline use: no.
- Survival weights treated as net-value weights: no.
- Productive-efficiency schedule constructed: no.
- Final GPIM stocks constructed: no.
- S20/S21/S22 run: no.
- Econometric output created: no.

## Validation

| validation_rule | result | observed |
|---|---|---|
| all five required schedules registered | PASS | SURVIVAL_ONLY_REJECTED; LINEAR_AGE_PRICE_CANDIDATE; GEOMETRIC_AGE_PRICE_CANDIDATE; BEA_STYLE_DECLINING_BALANCE_CANDIDATE; HYBRID_SENSITIVITY_ONLY |
| ME and NRC schedule sensitivity produced | PASS | 10 asset-schedule rows |
| schedule admissibility values controlled | PASS | REJECTED; REQUIRES_EXTERNAL_JUSTIFICATION; SENSITIVITY_ONLY |
| survival-only not labeled as net-value baseline | PASS | prohibited boundary case only |
| survival and age-price schedules separated | PASS | separate registry fields |
| productive-efficiency schedule remains separate | PASS | not constructed |
| FAAt402 not used as baseline | PASS | no schedule parameter or decision evidence uses FAAt402 |
| NFC output price not used as baseline | PASS | no output-price schedule parameter |
| no final GPIM stocks constructed | PASS | diagnostic price-path summaries only |
| no S20/S21/S22 run | PASS | S12D-A2 script only |
| no econometric output created | PASS | schedule protocol and diagnostic sensitivity only |
| explicit protocol decision produced | PASS | REQUIRE_S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR |
| final decision appears once in decision ledger | PASS | REQUIRE_S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR |
| S12D-B authorization consistent with baseline lockability | PASS | baseline_lockable=FALSE |
| protocol remains diagnostic and bounded | PASS | no baseline schedule locked |
