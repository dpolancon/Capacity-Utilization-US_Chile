# S11C Output Price Proxy Search

## Purpose

S11C searches broadly for official output-price proxy objects and classifies them without redefining the Chapter 2 baseline or reopening the provider menu.

## Link to S11B

S11B confirmed that CORP and FC same-boundary GVA real/price objects are unavailable in the audited BEA/NIPA documentation and API tables. S11C does not reverse that result. S11C searches for proxy deflators and robustness objects to support dataset closure while preserving correct metadata labels.

## Search scope

- FRED searches executed: 14
- Raw FRED candidate rows retained: 172
- BEA GDPByIndustry tables reviewed: 8, 10, 11, 15, 16, 18, 208
- BEA GDPByIndustry candidate boundaries: all industries, manufacturing, finance and insurance, and FIRE.
- BLS business/nonfarm-business output deflators and PPI series were reviewed through their official-origin FRED metadata.
- Investment price indexes and FAAt402 were retained only as capital-side diagnostics.

## Classification rules

- Baseline requires an exact same-boundary GVA source or same-boundary source-level derivation.
- Validation objects may check the baseline but do not replace it.
- Proxy and robustness objects keep transparent `P_Y_PROXY_*` names.
- PPI, investment-price, and capital-stock indexes remain diagnostic-only.
- Industry and gross-output indexes are never relabeled as corporate-sector GVA deflators.

## Same-boundary results

| recommended_variable_name | source_title | recommended_role | limitations |
|---|---|---|---|
| P_Y_NFC_GVA_IMPLICIT_SOURCE | Gross value added of nonfinancial corporate business | baseline_source | Available only for NFC. |

## Validation-only results

| recommended_variable_name | source_title | recommended_role | limitations |
|---|---|---|---|
| P_Y_NFC_GVA_T115_VALIDATION | Price per unit of real gross value added of nonfinancial corporate business | validation_only | Validation counterpart, not an independent CORP or FC deflator. |

## Proxy shortlist

| recommended_variable_name | source_system | source_title | boundary_distance_from_target | recommended_role | limitations |
|---|---|---|---|---|---|
| P_Y_PROXY_GDP_IMPLICIT | FRED_API | Gross domestic product (implicit price deflator) | macro_proxy | robustness_deflator | Economy-wide GDP boundary includes households, government, and noncorporate activity. |
| P_Y_PROXY_NONFARM_BUSINESS_OUTPUT | FRED_API | Gross value added: GDP: Business: Nonfarm (chain-type price index) | near | robustness_deflator | Nearer to corporate production than GDP but includes noncorporate nonfarm business. |
| P_Y_PROXY_BUSINESS_OUTPUT | BLS | Business Sector: Value-Added Output Price Deflator for All Workers | near | robustness_deflator | BLS productivity-program business boundary is not the NIPA corporate boundary. |
| P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS | BLS | Nonfarm Business Sector: Value-Added Output Price Deflator for All Workers | near | robustness_deflator | Excludes farms but still includes noncorporate business and does not match CORP/NFC. |
| P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE | BEA_API | Finance and insurance | industry_proxy | robustness_deflator | NAICS industry boundary is not financial corporate business. |
| P_Y_PROXY_GDPBYIND_VA_MANUFACTURING | BEA_API | Manufacturing | industry_proxy | robustness_deflator | Manufacturing is a narrow industry proxy, not the NFC boundary. |

## Rejected candidates

- Rejected candidate rows: 2
| candidate_variable_id | source_title | decision | limitations |
|---|---|---|---|
| fred_financial_auditing_ppi | Producer Price Index by Commodity: Professional Services (Partial): Financial Auditing | reject_boundary_mismatch | Narrow professional-service PPI does not represent financial corporate GVA. |
| fred_nonfarm_business_real_output | Nonfarm Business Sector: Real Value-Added Output for All Workers | reject_not_price_object | Real output index is not itself a price object. |

## Naming convention

- `P_Y` identifies output-price objects.
- `SOURCE` identifies the same-boundary NFC source-level derivation.
- `VALIDATION` identifies direct checks of that derivation.
- `PROXY` identifies non-equivalent macro, business, or industry objects.
- `DIAG` identifies diagnostic-only price or quantity indexes.

## Recommended dataset-closure path

**B. Baseline uses the NFC same-boundary GVA implicit deflator; GDP, business/nonfarm-business, and selected GDPByIndustry price indexes are retained only as explicitly named robustness variants.**
CORP and FC same-boundary real/price rows remain absent. The preferred first robustness proxies are the annual GDP implicit deflator, BEA nonfarm-business GVA chain-price index, and BLS business/nonfarm-business value-added output deflators. Industry indexes are narrower robustness options; gross-output, PPI, investment-price, and FAAt402 objects remain diagnostic-only.

## Non-negotiable locks preserved

- The provider menu and provider repository are unchanged.
- No CORP or FC real/price residual is constructed.
- No chained-dollar series is raw-subtracted.
- No macro, business, or industry proxy is called a CORP/FC GVA deflator.
- Direct nominal ME/NRC investment remains canonical.
- Stock-flow-implied investment remains fallback-only.
- FAAt402 remains comparison/validation-only.
- No S20/S21/S22 or econometric code was run.

## Machine-readable outputs

- `output/US/S11C_OUTPUT_PRICE_PROXY_SEARCH/csv/S11C_output_price_proxy_ledger.csv`
- `output/US/S11C_OUTPUT_PRICE_PROXY_SEARCH/csv/S11C_output_price_proxy_shortlist.csv`
- `output/US/S11C_OUTPUT_PRICE_PROXY_SEARCH/csv/S11C_fred_output_price_raw_candidates.csv`
- `output/US/S11C_OUTPUT_PRICE_PROXY_SEARCH/csv/S11C_bea_output_price_raw_candidates.csv`
