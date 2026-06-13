# S12D-B GPIM Baseline Construction Under Locked SFC Price Protocol

## Stage gate

S12D-A4 authorized this construction by recording and validating the manual net-value theory lock. This pass uses that lock without changing its survival parameters, depreciation rates, or object roles.

The exact inherited lock sentence is:

> For the Chapter 2 GPIM baseline, net-value weights are defined separately from physical survival as V_i(j)=S_i(j)(1-d_i)^j, where S_i(j) is the locked asset-specific Weibull survival schedule and the externally documented declining-balance age-price rates are d_ME=0.110 and d_NRC=0.024. These rates are age-price/depreciation anchors only; they are not retirement rates, productive-efficiency profiles, FAAt402 price indexes, NFC output deflators, or final capital-price indexes.

## Locked schedules

- ME: Weibull physical survival with `L=14` and `alpha=1.7`; declining-balance age price with `d=0.110`; net value `V_ME(j)=S_ME(j)*(1-0.110)^j`.
- NRC: Weibull physical survival with `L=30` and `alpha=1.6`; declining-balance age price with `d=0.024`; net value `V_NRC(j)=S_NRC(j)*(1-0.024)^j`.

Physical survival, age-price decline, net value, productive efficiency, and the recursively recovered capital-price index remain distinct objects. Productive-efficiency profiles are not constructed here.

## Recursive construction

For each asset, the current-period SFC price is solved so that the current-cost net-stock anchor equals the price times the locked net-value-weighted sum of current and prior real investment vintages. The recovered path is normalized to `2017=100`; nominal investment is then deflated by that path. Pre-recovery vintages use one common raw-price initialization, transformed by the same 2017 normalization, and are explicitly flagged `INITIALIZATION_SEED_PRICE` rather than independently recovered prices.

The baseline gross GPIM stock is the Weibull-survival-weighted sum of real investment vintages. The net-value-weighted stock is retained only as a diagnostic reconstruction object.

## Object distinctions

- Recovered SFC implicit price: the baseline capital-price index recursively solved from direct nominal investment, locked net-value weights, and the current-cost net-stock anchor.
- FAAt402 validation object: an official quantity-index comparison object, not a baseline price.
- NFC output-unit translation: an output-price robustness object, not a capital-price baseline.
- Real investment: canonical nominal investment divided by the recovered SFC price index.
- Gross/survival GPIM stock: the baseline survival-weighted sum of real investment vintages.
- Diagnostic net-value stock: the locked net-value-weighted sum used to verify the current-cost stock identity, not the gross baseline stock.

## Output spans

| Asset | SFC price rows | SFC price span | Real-flow rows | Real-flow span | Stock rows | Stock span | Max absolute SFC residual (million) |
|---|---:|---|---:|---|---:|---|---:|
| ME | 100 | 1925-2024 | 124 | 1901-2024 | 100 | 1925-2024 | 5.58794e-09 |
| NRC | 94 | 1931-2024 | 124 | 1901-2024 | 94 | 1931-2024 | 5.58794e-09 |

Required output table row counts:

- `S12D_B_sfc_implicit_price_indexes.csv`: 194
- `S12D_B_real_investment_flows.csv`: 248
- `S12D_B_gpim_stock_panel.csv`: 194
- `S12D_B_sfc_reconstruction_checks.csv`: 2
- `S12D_B_price_boundary_comparison.csv`: 190
- `S12D_B_object_role_ledger.csv`: 16
- `S12D_B_validation_checks.csv`: 21

## Price boundary

`FAAt402` remains validation-only and is not the baseline capital-price route. The NFC output price remains output-unit translation robustness-only and is not the baseline capital-price route. The baseline capital-price objects are the SFC implicit indexes recovered under the locked asset-specific net-value schedules.

## Protocol boundary and next stage

This pass did not run S20, S21, or S22, did not run econometrics, and did not create productive-efficiency objects. It constructed the authorized ME and NRC baseline gross GPIM stock objects and their diagnostic net-value counterparts.

**Next-stage decision:** `AUTHORIZE_S12D_C`. S12D-C is the next consolidation and downstream handoff step; S13 remains blocked until that validation is complete.

Validation result: **21/21 PASS**.
