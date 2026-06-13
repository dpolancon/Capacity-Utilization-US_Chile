# S12D-A GPIM Stock-Flow Consistency Price-Index Test

## Purpose

This pass tests whether GPIM can recover asset-specific stock-flow-consistent implicit capital price indexes. BEA quality-adjusted quantity indexes and output-price deflation are not treated as baseline capital-price recovery routes. They are comparison, validation, translation, or robustness objects unless the SFC tests justify a different protocol decision.

## Hypothesis

BEA quality-adjusted fixed-asset indexes may not preserve the finite-life stock-flow identity required by a GPIM driven by direct nominal investment. The test therefore compares an internally recovered SFC price with FAAt402-implied prices and the NFC output-price translation.

## Inherited S12C state

- Direct FAAt407 nominal ME and NRC investment is canonical.
- FAAt401 supplies net current-cost validation anchors.
- FAAt402 remains validation-only.
- CFC is available but implied investment remains fallback-only.
- Locked Weibull parameters are L_ME=14, alpha_ME=1.7, L_NRC=30, alpha_NRC=1.6.
- No final GPIM stock, S20/S21/S22 run, or econometric output is authorized.

## Candidate price treatments

- `SFC_IMPLICIT`: recursively recovered asset price; candidate baseline route conditional on a net-value-schedule lock.
- `BEA_QADJ_VALIDATION`: FAAt402/current-cost implied price; validation only.
- `OUTPUT_UNIT_TRANSLATION`: NFC output-price deflation; translation or robustness only.
- `FALLBACK_ONLY`: implied investment; not activated and requires a revaluation term.

## GPIM stock-flow consistency logic

For each asset, the test evaluates K_t = (P_t/100) sum_j V(j) I_{t-j}/(P_{t-j}/100). The current vintage has V(0)=1. The reported stock reconstructions are diagnostic objects only.

## SFC implicit price-index recovery

Only net current-cost stocks are available. The test therefore does not treat Weibull survival weights as net-value weights. It constructs an explicit candidate schedule V(j)=S(j) max(1-j/L,0), labels it `net_value_schedule_candidate` and `not_baseline_locked`, initializes prices before each asset's first complete-vintage recovery anchor to a common seed, solves forward, and normalizes the complete price path to 2017=100.

| asset_block | first_year | last_year | observations | minimum_index | maximum_index |
|---|---|---|---|---|---|
| ME | 1925 | 2024 | 100 | 0.298026 | 138.8962 |
| NRC | 1930 | 2024 | 95 | 0.007565 | 220.5656 |

## BEA quality-adjusted price/index comparison

The FAAt402 comparison price is 100*(K_t/K_2017)/(Q_t/Q_2017). It is then applied to direct nominal investment in the same candidate net-value reconstruction. Summary residuals exclude the full finite-life initialization window.

## Output-unit translation comparison

`P_Y_NFC_GVA_IMPLICIT_SOURCE` translates direct nominal investment into NFC output units. It is not an asset-specific capital-price recovery route. Summary residuals exclude the full finite-life initialization window.

## Test results

| asset_block | price_route | years_tested | mean_abs_residual_pct | max_abs_residual_pct | pass_fail |
|---|---|---|---|---|---|
| ME | SFC_IMPLICIT | 1925-2024 (100) | 0.00000 | 0.00000 | PASS |
| ME | BEA_QADJ_VALIDATION | 1939-2024 (86) | 11.80418 | 29.51099 | FAIL |
| ME | OUTPUT_UNIT_TRANSLATION | 1943-2024 (82) | 10.91236 | 22.96139 | FAIL |
| NRC | SFC_IMPLICIT | 1930-2024 (95) | 0.00000 | 0.00000 | PASS |
| NRC | BEA_QADJ_VALIDATION | 1955-2024 (70) | 45.96895 | 55.48241 | FAIL |
| NRC | OUTPUT_UNIT_TRANSLATION | 1959-2024 (66) | 51.17397 | 60.41346 | FAIL |

- SFC internally solved tolerance: max absolute residual <= 0.1 percent.
- Comparison-route FAIL results are findings, not forced validation failures.

## Price-treatment labeling decision

ME and NRC SFC implicit price paths are mathematically recoverable under the candidate net-value schedule. They are not yet baseline locked. FAAt402 remains validation-only, and the NFC output price remains a translation/robustness object. Implied investment remains fallback-only.

## Remaining protocol risks

The binding risk is the absence of an independently locked net age-price/value schedule. Exact fit by the recursive SFC route is an identity result conditional on that schedule and initialization; it is not independent evidence that the candidate schedule is economically correct. The especially wide NRC candidate index range demonstrates that sensitivity directly. Gross-anchor recovery is unavailable because no admissible gross current-cost stock anchor is present in the locked S12C layer.

## Next construction step

If S12D-A identifies recoverable SFC implicit capital price indexes for ME and NRC, the next step is S12D-B: lock the GPIM baseline price-treatment protocol and construct real investment plus gross GPIM stocks using those implicit SFC price indexes. If S12D-A shows that net-stock anchoring requires an additional net value schedule, the next step is not GPIM construction but a narrow S12D-A2 net-value schedule protocol.

This test finds that the net-stock route requires that S12D-A2 protocol before any baseline lock or final GPIM construction.
