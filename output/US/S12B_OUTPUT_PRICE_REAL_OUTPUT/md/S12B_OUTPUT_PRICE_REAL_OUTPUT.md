# S12B Output Price and Real Output Construction

## Purpose

S12B constructs the locked annual output-price layer and seven NFC real-output objects from validated S12A payloads. It creates no capital, distribution, capacity, utilization, or econometric object.

## Inherited locks

- `P_Y_NFC_GVA_IMPLICIT_SOURCE` is the only same-boundary baseline price.
- T1.15 line 1 remains validation-only.
- Six `P_Y_PROXY_*` objects remain robustness-only.
- CORP/FC real-price residuals and proxy relabeling remain prohibited.
- FAAt402, implied investment, GPIM, and adjusted distribution are outside S12B.

## Inputs

- S12A source observation rows: 1333
- S12A price observation rows: 1079
- S12A availability rows ready: 35
- S12A validation checks passed: 14
- No live API fetch or source discovery was performed.

## Output price objects constructed

| variable_name | role | start_year | end_year | observations |
|---|---|---|---|---|
| P_Y_NFC_GVA_IMPLICIT_SOURCE | baseline | 1929 | 2025 | 97 |
| P_Y_NFC_GVA_T115_VALIDATION | validation | 1929 | 2025 | 97 |
| P_Y_PROXY_GDP_IMPLICIT | robustness | 1929 | 2024 | 96 |
| P_Y_PROXY_NONFARM_BUSINESS_OUTPUT | robustness | 1929 | 2025 | 97 |
| P_Y_PROXY_BUSINESS_OUTPUT | robustness | 1947 | 2025 | 79 |
| P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS | robustness | 1947 | 2025 | 79 |
| P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE | robustness | 1997 | 2025 | 29 |
| P_Y_PROXY_GDPBYIND_VA_MANUFACTURING | robustness | 1997 | 2025 | 29 |

All objects preserve native annual values and include a common `2017=100` normalization. Quarterly BLS indexes are annualized by calendar-year arithmetic mean before normalization; incomplete years are excluded.

## Baseline NFC real output

`Y_REAL_NFC_GVA_BASELINE` uses current-dollar NFC GVA divided by the reconstructed T1.14 NFC implicit deflator. It matches direct T1.14 line 41 with a maximum absolute difference of 1.8626451e-09 million.

## Robustness real-output variants

| variable_name | price_object_used | role | start_year | end_year | observations |
|---|---|---|---|---|---|
| Y_REAL_NFC_GVA_BASELINE | P_Y_NFC_GVA_IMPLICIT_SOURCE | baseline | 1929 | 2025 | 97 |
| Y_REAL_NFC_GVA_PROXY_GDP_IMPLICIT | P_Y_PROXY_GDP_IMPLICIT | robustness | 1929 | 2024 | 96 |
| Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT | P_Y_PROXY_NONFARM_BUSINESS_OUTPUT | robustness | 1929 | 2025 | 97 |
| Y_REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT | P_Y_PROXY_BUSINESS_OUTPUT | robustness | 1947 | 2025 | 79 |
| Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS | P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS | robustness | 1947 | 2025 | 79 |
| Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_FINANCE_INSURANCE | P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE | robustness | 1997 | 2025 | 29 |
| Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_MANUFACTURING | P_Y_PROXY_GDPBYIND_VA_MANUFACTURING | robustness | 1997 | 2025 | 29 |

## Validation results

The NFC implicit deflator matches T1.15 line 1 over 97 years with a maximum absolute difference of 0.04907547 index points.
| validation_rule | expected | observed | result |
|---|---|---|---|
| P_Y_NFC_GVA_IMPLICIT_SOURCE constructed from T11400 lines 17 and 41 | 97 matched annual observations | 97 matched annual observations | PASS |
| P_Y_NFC_GVA_IMPLICIT_SOURCE matches T11500 line 1 within published rounding | maximum absolute difference <= 0.1 | 0.04907547 | PASS |
| Y_REAL_NFC_GVA_BASELINE matches T11400 line 41 within published rounding | maximum absolute difference <= 0.1 million | 1.8626451e-09 | PASS |
| All six proxy price objects retain P_Y_PROXY_* names | 6 | 6 | PASS |
| All proxy-real-output variants retain Y_REAL_NFC_GVA_PROXY_* names | 6 | 6 | PASS |
| No CORP real GVA object constructed | none |  | PASS |
| No FC real GVA object constructed | none |  | PASS |
| No CORP price object constructed | none |  | PASS |
| No FC price object constructed | none |  | PASS |
| No chained-dollar residual subtraction performed | direct T11400 line 41 only | direct T11400 line 41 used | PASS |
| No proxy relabeled as CORP/FC GVA deflator | transparent P_Y_PROXY_* names | P_Y_PROXY_GDP_IMPLICIT; P_Y_PROXY_NONFARM_BUSINESS_OUTPUT; P_Y_PROXY_BUSINESS_OUTPUT; P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS; P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE; P_Y_PROXY_GDPBYIND_VA_MANUFACTURING | PASS |
| No FAAt402 baseline use | no FAAt402 input | source tables: T11400, T11500, FRED/BLS, GDPByIndustry | PASS |
| No implied investment baseline use | none | no investment object used | PASS |
| No GPIM stocks constructed | none | output-price and NFC real-output objects only | PASS |
| No adjusted distribution variables constructed | none | output-price and NFC real-output objects only | PASS |
| No S20/S21/S22/econometric code run | none | S12B script only | PASS |
| Only the eight locked output-price objects exist | P_Y_NFC_GVA_IMPLICIT_SOURCE; P_Y_NFC_GVA_T115_VALIDATION; P_Y_PROXY_GDP_IMPLICIT; P_Y_PROXY_NONFARM_BUSINESS_OUTPUT; P_Y_PROXY_BUSINESS_OUTPUT; P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS; P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE; P_Y_PROXY_GDPBYIND_VA_MANUFACTURING | P_Y_NFC_GVA_IMPLICIT_SOURCE; P_Y_NFC_GVA_T115_VALIDATION; P_Y_PROXY_GDP_IMPLICIT; P_Y_PROXY_NONFARM_BUSINESS_OUTPUT; P_Y_PROXY_BUSINESS_OUTPUT; P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS; P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE; P_Y_PROXY_GDPBYIND_VA_MANUFACTURING | PASS |
| Only the seven locked NFC real-output objects exist | Y_REAL_NFC_GVA_BASELINE; Y_REAL_NFC_GVA_PROXY_GDP_IMPLICIT; Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT; Y_REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT; Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS; Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_FINANCE_INSURANCE; Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_MANUFACTURING | Y_REAL_NFC_GVA_BASELINE; Y_REAL_NFC_GVA_PROXY_GDP_IMPLICIT; Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT; Y_REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT; Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS; Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_FINANCE_INSURANCE; Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_MANUFACTURING | PASS |
| Every price object is normalized to 2017=100 | all 2017 values equal 100 | 100; 100; 100; 100; 100; 100; 100; 100 | PASS |

## Prohibited objects preserved

- No CORP or FC real GVA object was constructed.
- No CORP or FC price object was constructed.
- No chained-dollar residual subtraction was performed.
- No proxy was relabeled as a same-boundary corporate deflator.
- No FAAt402, implied-investment, GPIM, or adjusted-distribution object was used.
- No S20/S21/S22 or econometric code was run.

## Next construction step

After S12B validates the output-price and NFC real-output layer, the next step is S12C: capital input preparation for direct nominal ME/NRC investment, CFC, current-cost validation stocks, and GPIM protocol definition. S12C must still not run S20/S21/S22 or construct econometric datasets.
