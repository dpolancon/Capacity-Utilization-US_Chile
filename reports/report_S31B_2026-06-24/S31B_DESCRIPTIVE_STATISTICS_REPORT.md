# Chapter 2 U.S. Descriptive Statistics: Historical Windows, Growth Rates, and Output-Capital Correspondence

## S31B Univariate Descriptive Diagnostics

Date: June 24, 2026

## 1. Scope and stage boundary

S31B computes descriptive statistics and non-canonical diagnostic growth rates from the frozen S30 release. It does not alter the source-of-truth dataset, create new canonical variables, construct estimation samples, infer integration order, or estimate structural elasticities.

## 2. Frozen dataset and variable coverage

The frozen release contains 37 canonical variables, 3637 long-format observations, and 125 annual wide-panel rows spanning 1901-2025. Every canonical variable enters the master table; the descriptive architecture therefore preserves the release rather than selecting a convenient subset.

## 3. Historical-window architecture

The registry contains 16 windows: 4 structural or structural-umbrella windows, 6 nested windows, 4 transition windows, one global window, and one supplementary bridge. Transition and event windows are descriptive only and are not eligible for testing or estimation.

## 4. Variable inclusion and reporting tiers

Tier A contains 16 core representations, Tier B contains 17 robustness representations, and Tier C contains 4 reference-only variables. These are presentation tiers derived from frozen S30 and S31A metadata; they do not reclassify the underlying analytical roles.

## 5. Growth-rate construction protocol

Positive levels use direct annual percent changes, shares use percentage-point changes, and existing frozen growth or difference variables enter directly without another transformation. Log levels do not drive the headline evidence when a frozen level counterpart exists. The growth panel is diagnostic, non-canonical, and confined to S31B.

## 6. Broad structural comparison

Cells report mean growth, standard deviation in parentheses, and valid n in brackets.
| Variable | Global available | Pre-1974 | Post-1974 | Post-Fordist pre-GFC, 1974-2008 | Post-GFC, 2009-2025 |
| --- | --- | --- | --- | --- | --- |
| G_TOT_GPIM_2017 | 2.61 (13.81) [n=123] | 5.21 (17.64) [n=72] | -1.06 (0.65) [n=51] | -0.78 (0.53) [n=35] | -1.67 (0.46) [n=16] |
| NFC_COMPENSATION_SHARE_GVA | -0.07 (1.17) [n=96] | 0.03 (1.37) [n=44] | -0.15 (0.96) [n=52] | -0.14 (0.94) [n=35] | -0.17 (1.04) [n=17] |
| Y_REAL_NFC_GVA_BASELINE | 3.83 (5.46) [n=96] | 4.66 (7.25) [n=44] | 3.13 (3.19) [n=52] | 3.52 (2.99) [n=35] | 2.31 (3.54) [n=17] |

## 7. Pre-1974 decomposition

The 1940-1946 consolidation window is too short to carry regime-level distributional claims; it remains a bounded descriptive interval whose endpoint and annual-change evidence complements the longer Fordist core.
| Variable | Pre-Fordist available | Pre-Fordist consolidation, 1940-1946 | Fordist core, 1947-1973 |
| --- | --- | --- | --- |
| G_TOT_GPIM_2017 | 9.42 (21.25) [n=45] | -3.35 (0.87) [n=7] | -1.80 (1.97) [n=27] |
| NFC_COMPENSATION_SHARE_GVA | 0.18 (1.79) [n=17] | 0.47 (1.70) [n=7] | -0.07 (1.06) [n=27] |
| Y_REAL_NFC_GVA_BASELINE | 3.82 (10.65) [n=17] | 7.04 (10.05) [n=7] | 5.19 (4.06) [n=27] |

## 8. Post-1974 decomposition

The post-1974 hierarchy separates the mature post-Volcker interval from the post-GFC configuration. The 2022-2025 interval remains descriptive only because four annual observations cannot establish a regime parameter.
| Variable | Post-Fordist pre-GFC, 1974-2008 | Mature post-Volcker pre-GFC, 1983-2008 | Post-GFC, 2009-2025 | Post-GFC pre-COVID, 2009-2019 | Post-COVID configuration, 2022-2025 |
| --- | --- | --- | --- | --- | --- |
| G_TOT_GPIM_2017 | -0.78 (0.53) [n=35] | -0.97 (0.44) [n=26] | -1.67 (0.46) [n=16] | -1.62 (0.44) [n=11] | -1.52 (0.54) [n=3] |
| NFC_COMPENSATION_SHARE_GVA | -0.14 (0.94) [n=35] | -0.16 (0.88) [n=26] | -0.17 (1.04) [n=17] | -0.07 (0.77) [n=11] | -0.33 (0.81) [n=4] |
| Y_REAL_NFC_GVA_BASELINE | 3.52 (2.99) [n=35] | 3.74 (2.66) [n=26] | 2.31 (3.54) [n=17] | 2.04 (3.18) [n=11] | 2.82 (0.82) [n=4] |

## 9. Transition and event profiles

Transition and event windows are descriptive only and are not eligible for testing or estimation. The authoritative transition summary and year-level event profiles are available in the accompanying CSV files.

| Variable | Window | Initial | Terminal | Absolute change | Relative change | Mean annual change | n |
| --- | --- | --- | --- | --- | --- | --- | --- |
| G_TOT_GPIM_2017 | Fordist aftermath, 1974-1978 | 33,562,535.66 | 33,045,743.33 | -516,792.33 | -1.54 | -129,198.08 | 5 |
| G_TOT_GPIM_2017 | Volcker transition, 1979-1982 | 32,992,478.69 | 32,579,850.43 | -412,628.26 | -1.25 | -137,542.75 | 4 |
| G_TOT_GPIM_2017 | GFC transition, 2008-2009 | 25,313,159.66 | 24,796,841.82 | -516,317.84 | -2.04 | -516,317.84 | 2 |
| G_TOT_GPIM_2017 | COVID transition, 2020-2021 | 20,731,781.53 | 20,233,341.36 | -498,440.17 | -2.40 | -498,440.17 | 2 |
| I_TOT_REAL_2017 | Fordist aftermath, 1974-1978 | 1,763,511.18 | 1,803,086.64 | 39,575.46 | 2.24 | 1,672,546.88 | 5 |
| I_TOT_REAL_2017 | Volcker transition, 1979-1982 | 1,882,974.29 | 1,737,933.58 | -145,040.71 | -7.70 | 1,818,192.97 | 4 |
| I_TOT_REAL_2017 | GFC transition, 2008-2009 | 1,372,420.18 | 1,070,047.48 | -302,372.70 | -22.03 | 1,221,233.83 | 2 |
| I_TOT_REAL_2017 | COVID transition, 2020-2021 | 1,009,463.45 | 974,740.54 | -34,722.91 | -3.44 | 992,101.99 | 2 |
| DELTA_G_TOT | Fordist aftermath, 1974-1978 | 200,168.97 | -51,571.31 | -251,740.28 | -125.76 | -63,324.67 | 5 |
| DELTA_G_TOT | Volcker transition, 1979-1982 | -53,264.64 | -218,160.21 | -164,895.57 | 309.58 | -116,473.22 | 4 |
| DELTA_G_TOT | GFC transition, 2008-2009 | -155,101.68 | -516,317.84 | -361,216.17 | 232.89 | -335,709.76 | 2 |
| DELTA_G_TOT | COVID transition, 2020-2021 | -421,150.99 | -498,440.17 | -77,289.18 | 18.35 | -459,795.58 | 2 |
| DLOG_G_TOT | Fordist aftermath, 1974-1978 | 0.01 | -0.00 | -0.01 | -126.07 | -0.19 | 5 |
| DLOG_G_TOT | Volcker transition, 1979-1982 | -0.00 | -0.01 | -0.01 | 313.72 | -0.35 | 4 |
| DLOG_G_TOT | GFC transition, 2008-2009 | -0.01 | -0.02 | -0.01 | 237.36 | -1.34 | 2 |
| DLOG_G_TOT | COVID transition, 2020-2021 | -0.02 | -0.02 | -0.00 | 21.01 | -2.22 | 2 |
| DLOG_N_TOT | Fordist aftermath, 1974-1978 | 0.00 | -0.00 | -0.00 | -254.74 | -0.58 | 5 |
| DLOG_N_TOT | Volcker transition, 1979-1982 | 0.00 | -0.01 | -0.01 | -2,123.00 | -0.21 | 4 |
| DLOG_N_TOT | GFC transition, 2008-2009 | -0.01 | -0.03 | -0.02 | 213.64 | -1.88 | 2 |
| DLOG_N_TOT | COVID transition, 2020-2021 | -0.03 | -0.03 | -0.00 | 11.78 | -2.73 | 2 |
| GROWTH_ARITH_G_TOT | Fordist aftermath, 1974-1978 | 0.01 | -0.00 | -0.01 | -125.97 | -0.19 | 5 |
| GROWTH_ARITH_G_TOT | Volcker transition, 1979-1982 | -0.00 | -0.01 | -0.01 | 312.67 | -0.35 | 4 |
| GROWTH_ARITH_G_TOT | GFC transition, 2008-2009 | -0.01 | -0.02 | -0.01 | 234.93 | -1.32 | 2 |
| GROWTH_ARITH_G_TOT | COVID transition, 2020-2021 | -0.02 | -0.02 | -0.00 | 20.76 | -2.20 | 2 |
| GROWTH_ARITH_N_TOT | Fordist aftermath, 1974-1978 | 0.00 | -0.00 | -0.00 | -254.54 | -0.57 | 5 |
| GROWTH_ARITH_N_TOT | Volcker transition, 1979-1982 | 0.00 | -0.01 | -0.01 | -2,116.79 | -0.21 | 4 |
| GROWTH_ARITH_N_TOT | GFC transition, 2008-2009 | -0.01 | -0.03 | -0.02 | 210.62 | -1.86 | 2 |
| GROWTH_ARITH_N_TOT | COVID transition, 2020-2021 | -0.03 | -0.03 | -0.00 | 11.61 | -2.69 | 2 |
| NFC_COMPENSATION_SHARE_GVA | Fordist aftermath, 1974-1978 | 0.65 | 0.64 | -1.80 |  | -0.45 | 5 |
| NFC_COMPENSATION_SHARE_GVA | Volcker transition, 1979-1982 | 0.65 | 0.64 | -1.19 |  | -0.40 | 4 |
| NFC_COMPENSATION_SHARE_GVA | GFC transition, 2008-2009 | 0.60 | 0.59 | -0.25 |  | -0.25 | 2 |
| NFC_COMPENSATION_SHARE_GVA | COVID transition, 2020-2021 | 0.60 | 0.58 | -2.51 |  | -2.51 | 2 |
| Y_REAL_NFC_GVA_BASELINE | Fordist aftermath, 1974-1978 | 2,491,175.00 | 3,038,745.00 | 547,570.00 | 21.98 | 136,892.50 | 5 |
| Y_REAL_NFC_GVA_BASELINE | Volcker transition, 1979-1982 | 3,118,975.00 | 3,253,862.00 | 134,887.00 | 4.32 | 44,962.33 | 4 |
| Y_REAL_NFC_GVA_BASELINE | GFC transition, 2008-2009 | 8,373,691.00 | 7,780,498.00 | -593,193.00 | -7.08 | -593,193.00 | 2 |
| Y_REAL_NFC_GVA_BASELINE | COVID transition, 2020-2021 | 9,979,518.00 | 10,945,065.00 | 965,547.00 | 9.68 | 965,547.00 | 2 |

## 10. Output-capital growth correspondence

The correspondence table pairs the preferred frozen Tier A real-output level with the preferred frozen Tier A total-capital level. The descriptive output-capital growth ratio is not an estimate of the structural elasticity theta.
| Window | Output growth | Capital growth | Difference | Correlation | Descriptive ratio | Joint n |
| --- | --- | --- | --- | --- | --- | --- |
| Global available | 3.84 | -1.59 | 5.43 | -0.16 | -2.41 | 95 |
| Pre-1974 | 4.66 | -2.20 | 6.86 | -0.14 | -2.11 | 44 |
| Pre-Fordist available | 3.82 | -2.84 | 6.66 | -0.42 | -1.35 | 17 |
| Pre-Fordist consolidation, 1940-1946 | 7.04 | -3.35 | 10.39 | -0.44 |  | 7 |
| Fordist core, 1947-1973 | 5.19 | -1.80 | 6.99 | 0.14 | -2.88 | 27 |
| Post-1974 | 3.13 | -1.06 | 4.19 | 0.01 | -2.94 | 51 |
| Post-Fordist pre-GFC, 1974-2008 | 3.52 | -0.78 | 4.31 | -0.23 | -4.49 | 35 |
| Mature post-Volcker pre-GFC, 1983-2008 | 3.74 | -0.97 | 4.70 | -0.11 | -3.87 | 26 |
| Post-GFC, 2009-2025 | 2.26 | -1.67 | 3.94 | 0.02 | -1.35 | 16 |
| Post-GFC pre-COVID, 2009-2019 | 2.04 | -1.62 | 3.66 | 0.31 | -1.26 | 11 |
| Post-COVID configuration, 2022-2025 | 2.73 | -1.52 | 4.25 | -0.63 |  | 3 |

## 11. Robustness and reference-only variables

Robustness variables remain visible in Appendix A and reference-only variables remain visible in Appendix B. Their inclusion preserves the frozen contract while preventing alternative representations from displacing the preferred Tier A evidence.

## 12. Coverage and interpretation cautions

Missing observations are measured, never filled. Annual changes require consecutive calendar years, transition windows never support testing or estimation, and no annual output-growth/capital-growth ratio is constructed.

## 13. Validation summary

The authoritative validation ledger is copied into the report bundle. The final result requires the compiled PDF and page-by-page visual inspection to pass.

## Appendices

- [Robustness descriptives CSV](csv/S31B_master_descriptive_statistics.csv)
- [Reference-variable descriptives CSV](csv/S31B_descriptive_variable_registry.csv)
- [Complete master descriptives CSV](csv/S31B_master_descriptive_statistics.csv)
