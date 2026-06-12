# S12 Source-of-Truth Readiness

## Purpose

This registry translates the completed S11B/S11C source audit into explicit
construction roles for the next pre-econometric source-of-truth stage. It does
not construct final variables or run estimations.

## S11B/S11C Inherited Locks

- The provider menu is closed and requires no patch.
- NFC has a valid same-boundary implicit GVA deflator.
- NIPA Table 1.15 line 1 is validation-only.
- No same-boundary CORP or FC real/price GVA counterpart exists.
- FC real and price residuals are prohibited.
- Proxy indexes must retain transparent `P_Y_PROXY_*` names.
- `FAAt402` remains comparison/validation-only.
- Direct nominal ME/NRC investment remains canonical.
- Stock-flow-implied investment remains fallback-only.

## Output-Price Hierarchy

1. Baseline: same-boundary NFC implicit GVA deflator.
2. Validation: NIPA Table 1.15 NFC price-per-unit counterpart.
3. Robustness: macro, business/nonfarm-business, and selected industry price
   indexes.
4. Diagnostic-only: gross-output, PPI, investment-price, and fixed-assets
   quantity indexes retained in S11C but excluded from this construction-ready
   registry.

## Baseline Construction-Ready Objects

`P_Y_NFC_GVA_IMPLICIT_SOURCE` is `construction_ready`.

```text
100 * T11400_line17_current_dollar_NFC_GVA
    / T11400_line41_chained_dollar_NFC_GVA
```

Units must be harmonized before division. The object may deflate NFC GVA where
a same-boundary NFC output price is required. It must not be used as a CORP or
FC deflator.

## Validation-Only Objects

`P_Y_NFC_GVA_T115_VALIDATION` is `validation_ready`. NIPA Table 1.15 line 1
(`A455RD`) validates the source-level NFC implicit deflator when scaled
consistently. It does not replace the baseline derivation and does not define
CORP or FC prices.

## Robustness/Proxy Objects

The following are `robustness_ready` and may be used only as explicitly named
robustness deflators:

- `P_Y_PROXY_GDP_IMPLICIT`
- `P_Y_PROXY_NONFARM_BUSINESS_OUTPUT`
- `P_Y_PROXY_BUSINESS_OUTPUT`
- `P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS`
- `P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE`
- `P_Y_PROXY_GDPBYIND_VA_MANUFACTURING`

GDP is an economy-wide boundary. Business and nonfarm-business indexes are
nearer to production but do not match corporate legal form. Finance/insurance
and manufacturing indexes use industry boundaries rather than corporate
legal-form boundaries.

## Objects Still Prohibited

- CORP or FC real GVA formed by residual subtraction.
- CORP or FC price indexes formed by residual subtraction.
- Any proxy renamed as `corp_gva_deflator`, `fc_gva_deflator`,
  `gva_price_or_deflator_corp`, or `gva_price_or_deflator_fc`.
- Diagnostic-only PPI, gross-output, investment-price, or `FAAt402` objects
  promoted into the baseline hierarchy.
- Implied investment promoted from fallback to baseline.

## Next Construction Step

The next implementation step is an S12/S10 source-of-truth construction
scaffold that imports the provider handoff, applies the S11B/S11C price-object
hierarchy, and constructs only pre-econometric source-of-truth variables. It
should not run S20/S21/S22 estimations.
