# GPIM Capital-Stock Decay Diagnostic

**Date:** 25 June 2026  
**Chapter 2 commit:** `8f51482888e3cb41d00b122bbe9d94998237d376`  
**Shaikh repository commit:** `e66ca30cae8db9c552e785efa571646344a439d1`  
**Status:** Cross-repository diagnostic; both source repositories read only

## 1. Question and finding

The frozen Chapter 2 gross productive-capital stock declines sharply after its early peak, whereas all three Shaikh benchmarks rise after 1947. Rebased to 1947, the Chapter 2 stock ends at 35.8 in 2024; the Shaikh asset-level ME+NRC stock ends at 553.2 and the aggregate NFC Weibull stock ends at 1,769.3.

The current terminal-exit rule is consequential but is not the sole explanation. At the stated service life, the current schedule still retains 43.88% of an ME cohort and 43.18% of an NRC cohort, then sets both to zero in the following year.

Removing that cliff changes the endpoint from 35.8 to 41.8 on the 1947=100 scale. The Chapter 2 trajectory therefore still declines under the untruncated schedule. The mean-age hazard endpoint is 34.6.

The cross-switch gives the strongest attribution result. Under the same Shaikh constant retirement engine and the same 1925 cold start, Chapter 2 investment produces an endpoint of 90.7 while Shaikh asset-level investment produces 980.5. The real-investment/deflator input path changes the direction of the long-run trajectory.

## 2. Boundary discipline

The four headline objects do not share an identical legal-sector and asset boundary. Level ratios across them are therefore not treated as measurement gaps. The report compares trajectories after 1947 rebasing and labels the residual boundary contribution `SCOPE_NOT_IDENTIFIED`.

| Series | Legal sector | Asset scope | Construction |
|---|---|---|---|
| chapter2_frozen_G_TOT_GPIM_2017 | nonfinancial corporate | ME + NRC | asset-specific truncated cohort schedules, then exact addition |
| shaikh_canonical_KGCcorp_real | corporate | locked Shaikh corporate fixed capital | locked Shaikh canonical series, deflated by pKN |
| shaikh_aggregate_weibull_KGR_NF_corp | nonfinancial corporate | aggregate fixed assets represented by FAAt601 line | aggregate mean-age Weibull hazard, L=22 alpha=1.65 |
| shaikh_asset_ME_NRC_gross_real | private | ME + NRC from private asset tables | asset-specific constant retirement, ME=1/15 NRC=1/38 |

![Headline trajectories](figures/figure_01_headline_trajectories.png)

## 3. Investment-path comparison

The investment inputs differ substantially even after rebasing. This is not a minor scaling issue because the stock is a weighted history of those flows. The fair cross-switch begins both input systems at zero in 1925 and applies identical retirement engines.

![Investment paths](figures/figure_02_investment_input_paths.png)

## 4. Retirement-profile diagnostic

The frozen construction is a cohort convolution, not the mean-age hazard implementation used by the aggregate Shaikh pipeline. Its terminal rule removes the surviving cohort mass after age L. The untruncated sensitivity extends the Weibull tail to 5L, where remaining survival is negligible, without the age-L mass exit.

![Survival schedules](figures/figure_03_survival_schedules.png)

![Retirement counterfactuals](figures/figure_04_retirement_counterfactuals.png)

![Retirement flows](figures/figure_05_retirement_flows.png)

## 5. Heterogeneous aggregation

Constructing ME and NRC separately under their own schedules and pooling them only afterward produces an endpoint of 41.8 under the untruncated sensitivity. Pooling investment first under the Shaikh aggregate parameters `(L=22, alpha=1.65)` produces 43.7. This comparison isolates parameter and pooling effects on the same Chapter 2 investment.

## 6. Cross-switch decomposition

![Cross-switch matrix](figures/figure_06_cross_switch_matrix.png)

| Input | Engine | End index | Direction |
|---|---|---:|---|
| chapter2_current | current_truncated | 47.2 | declining |
| chapter2_current | mean_age_hazard | 52.2 | declining |
| chapter2_current | shaikh_constant | 90.7 | declining |
| chapter2_current | untruncated_5L | 64.9 | declining |
| shaikh_asset | current_truncated | 704.0 | rising |
| shaikh_asset | mean_age_hazard | 781.4 | rising |
| shaikh_asset | shaikh_constant | 980.5 | rising |
| shaikh_asset | untruncated_5L | 861.3 | rising |

## 7. Initialization sensitivity

Under the untruncated cohort schedule, the 2024 endpoint is 41.8 with the full 1901 history, 64.9 with a 1925 cold start, and 121.1 with a 1931 cold start. The fully supported 1931 start reverses the direction, showing that the inherited pre-1931 vintage stock and initialization history are material to the observed decay.

## 8. Finding matrix

| Question | Result | Evidence |
|---|---|---|
| Is the decline reproduced when retirement mechanics change? | `YES_UNDER_CURRENT_INPUT` | End indexes on Chapter 2 input: truncated=35.8, untruncated=41.8, mean-age=34.6. |
| Does pooling heterogeneous assets materially alter the trend? | `LIMITED_EFFECT` | Separate untruncated end index=41.8; pooled L22 end index=43.7. |
| Does the investment path reproduce the decline under Shaikh retirement? | `INPUT_PATH_CHANGES_TREND_DIRECTION` | 1925 cold-start Shaikh-constant engine: Chapter 2 input end index=90.7; Shaikh input end index=980.5. |
| How much remains attributable to incompatible asset scope? | `SCOPE_NOT_IDENTIFIED` | The four headline series have non-identical legal-sector and asset boundaries; no additive percentage is identified. |
| Does the initialization and inherited vintage history change the trend? | `INITIALIZATION_CHANGES_TREND_DIRECTION` | Untruncated end indexes: 1901 history=41.8; 1925 cold start=64.9; 1931 cold start=121.1. |

## 9. Interpretation

The decay is not explained by heterogeneous aggregation alone. The terminal-exit convention materially depresses the stock and should be corrected in a separate remediation pass, but the investment/deflator path remains capable of producing a declining trajectory under alternative retirement engines. The 1931 cold-start result also shows that the inherited warmup stock changes the trend direction. The appropriate diagnosis is therefore joint: `RETIREMENT_SCHEDULE_DEFECT_SUPPORTED`, `INPUT_PATH_DIFFERENCE_MATERIAL`, and `INITIALIZATION_HISTORY_MATERIAL`.

No percentage is assigned to asset scope because the Chapter 2 NFC ME+NRC boundary, the Shaikh private ME+NRC boundary, the aggregate NFC account, and the canonical corporate series are not identical. That component remains `SCOPE_NOT_IDENTIFIED`.

## 10. Remediation recommendation

Do not replace the frozen stock in this diagnostic. Open a separate capital-governance pass that first removes the forced mass exit by adopting an untruncated cohort schedule or a fully validated mean-age/vintage hazard, then audits the S29C real-investment deflators, the 1901-1930 warmup and initialization treatment, and the legal-sector boundary against the Shaikh asset inputs. Re-freezing is warranted only after these mechanisms are tested independently and the stock-flow contracts are revalidated.

## 11. Reproducibility

- Builder: `codes/US_GPIM_shaikh_capital_stock_decay_diagnostic.R`
- Machine-readable tables: `tables/`
- Input hash and validation records: `validation/`
- No econometric estimation was performed.
- No source or frozen dataset was modified.
