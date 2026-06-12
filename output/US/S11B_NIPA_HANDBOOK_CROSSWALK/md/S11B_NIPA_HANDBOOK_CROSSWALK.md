# S11B NIPA Handbook Crosswalk Audit

**Verdict: A. Provider lock confirmed, with stronger BEA/NIPA documentation.**

## Scope

S11B is a bounded provider-documentation audit. It constructs no real variables, GPIM stocks, distribution variables, q-indexes, interactions, econometric datasets, or estimations.

## Primary evidence

- NIPA Handbook landing page: https://www.bea.gov/resources/methodologies/nipa-handbook
- Chapter 13, Corporate Profits: https://www.bea.gov/resources/methodologies/nipa-handbook/pdf/chapter-13.pdf
- Chapter 4, Estimating Methods: https://www.bea.gov/resources/methodologies/nipa-handbook/pdf/chapter-04.pdf
- Chapter 6, Private Fixed Investment: https://www.bea.gov/resources/methodologies/nipa-handbook/pdf/chapter-06.pdf
- BEA fixed-assets primer: https://www.bea.gov/sites/default/files/papers/WP2015-6.pdf
- BEA fixed-assets methods volume: https://www.bea.gov/sites/default/files/methodologies/Fixed-Assets-1925-97.pdf
- BEA API root: https://apps.bea.gov/api/data/

Live BEA API verification passed for T11400 lines 1, 16, 17, and 41; T11500 line 1; and selected FAAt402 ME/NRC legal-form lines.

## Core findings

1. NIPA Table 1.14 publishes total domestic corporate and financial corporate GVA in current dollars, but its real-GVA lines are limited to nonfinancial corporate business.
2. The Chapter 13 appendix states that BEA prepares real GVA for the nonfinancial corporate sector by applying a nonfinancial-industry chain-type price index.
3. NFC current-dollar GVA (T11400 line 17, A455RC) and chained-dollar GVA (line 41, B455RX) therefore validate the provider's source-level implicit deflator.
4. T11500 line 1 (A455RD) is the direct price-per-unit validation counterpart. It is NFC-only and equals the current/real ratio; its index-scale counterpart is line 1 multiplied by 100.
5. No same-boundary real/quantity or price object was identified for total CORP or FC. Real and price FC residuals remain prohibited.
6. FAAt402 is a Fisher quantity-index table for BEA net stocks. It is comparison/validation-only and cannot supply the missing stock revaluation term or define the Chapter 2 GPIM baseline.
7. No standalone ME/NRC stock-price or revaluation index was identified. Those gaps are non-blocking because direct nominal investment remains canonical.

## Decision summary

| Decision | Rows |
|---|---|
| no_baseline_change | 2 |
| source_level_derived_confirmed | 1 |
| unresolved_true_absence | 4 |
| validation_only_confirmed | 2 |

## Crosswalk ledger

| target_variable | provider_status | handbook_table_reference | bea_line_to_check_if_known | construction_role | decision | notes |
|---|---|---|---|---|---|---|
| gva_real_or_qindex_corp | fetch_status=unresolved; construction_status=not_constructed_here; chapter2_role=unresolved; baseline_status=locked | NIPA Table 1.14 | 1 (A451RC); no CORP chained-dollar line | unresolved source input | unresolved_true_absence | No same-boundary CORP real or quantity object was missed. NFC unit-price series cannot substitute for CORP. |
| gva_real_or_qindex_fc | fetch_status=unresolved; construction_status=not_constructed_here; chapter2_role=unresolved; baseline_status=locked | NIPA Table 1.14 | 16 (A454RC); no FC chained-dollar line | unresolved source input; residual prohibited | unresolved_true_absence | Do not construct FC real GVA as CORP real GVA minus NFC real GVA. |
| gva_price_or_deflator_corp | fetch_status=unresolved; construction_status=not_constructed_here; chapter2_role=unresolved; baseline_status=locked | NIPA Tables 1.14 and 1.15 | T11400 line 1 current-dollar only; T11500 has no CORP line | unresolved source input | unresolved_true_absence | The NFC Table 1.15 price-per-unit series is not a CORP robustness source. |
| gva_price_or_deflator_fc | fetch_status=unresolved; construction_status=not_constructed_here; chapter2_role=unresolved; baseline_status=locked | NIPA Tables 1.14 and 1.15 | T11400 line 16 current-dollar only; T11500 has no FC line | unresolved source input; residual prohibited | unresolved_true_absence | Do not construct an FC price object by subtracting CORP and NFC indexes. |
| gva_price_or_deflator_nfc | fetch_status=derivable_from_bea_components; construction_status=source_level_derived; chapter2_role=preferred_baseline_source; baseline_status=source_level_derived | NIPA Table 1.14 | 17 (A455RC) and 41 (B455RX) | source-level implicit deflator | source_level_derived_confirmed | Provider formula 100 * current-dollar NFC GVA / chained-dollar NFC GVA is methodologically valid at the same boundary. |
| gva_price_or_deflator_nfc | fetch_status=derivable_from_bea_components; construction_status=source_level_derived; chapter2_role=preferred_baseline_source; baseline_status=source_level_derived | NIPA Table 1.15 | 1 (A455RD) | direct validation counterpart only | validation_only_confirmed | Use line 1 to validate the derived NFC implicit deflator, not to replace its source-level derivation or define CORP/FC prices. |
| me_stock_price_or_revaluation_index | fetch_status=unresolved; construction_status=not_constructed_here; chapter2_role=unresolved; baseline_status=locked | FixedAssets Tables 4.1, 4.2, 4.4, 4.7, and 4.8 | equipment lines by legal form; no revaluation-index line | implied-investment fallback input only | no_baseline_change | Leave unresolved. This does not block the baseline because direct nominal investment remains canonical; the index is needed only if the implied-investment fallback is activated. |
| nrc_stock_price_or_revaluation_index | fetch_status=unresolved; construction_status=not_constructed_here; chapter2_role=unresolved; baseline_status=locked | FixedAssets Tables 4.1, 4.2, 4.4, 4.7, and 4.8 | structures lines by legal form; no revaluation-index line | implied-investment fallback input only | no_baseline_change | Leave unresolved. This does not block the baseline because direct nominal investment remains canonical; the index is needed only if the implied-investment fallback is activated. |
| FAAt402 | fetch_status=direct_bea; construction_status=metadata_only; chapter2_role=validation_only; baseline_status=comparison_only \| fetch_status=direct_bea; construction_status=metadata_only; chapter2_role=validation_only; baseline_status=comparison_only | FixedAssets Table 4.2 | ME/NRC lines 2-3, CORP 18-19, FC 34-35, NFC 38-39 | comparison and validation only | validation_only_confirmed | Provider lock confirmed: FAAt402 is not a GPIM product, baseline stock, price index, or substitute for the missing revaluation term. |

## Lock confirmation

- No new variable is added.
- No provider row is reclassified.
- No FRED candidate is accepted.
- Direct nominal ME/NRC investment remains canonical.
- Stock-flow-implied investment remains fallback-only.
- `FAAt402` remains comparison/validation-only.
- `gva_price_or_deflator_nfc` remains source-level derived.
- CORP and FC real/price rows remain unresolved true absences.
- No FC real or price residual is constructed.

## Machine-readable output

- `output/US/S11B_NIPA_HANDBOOK_CROSSWALK/csv/S11B_handbook_crosswalk_ledger.csv`
