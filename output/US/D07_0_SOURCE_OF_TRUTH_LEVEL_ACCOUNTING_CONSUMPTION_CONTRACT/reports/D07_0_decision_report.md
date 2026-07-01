# D07-0 Source-of-Truth Level/Accounting Consumption Contract

## 1. Opening Repo State

- Pre-edit `git status --short`: clean. This was verified before generating D07-0 artifacts.
- Generation-time `git status --short`: D07-0 generated artifacts only
- Generation-time `git status -sb`: `## main...origin/main
?? codes/US_D07_0_source_of_truth_level_accounting_contract.R
?? output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT/`
- `git branch --show-current`: `main`
- `git rev-parse HEAD`: `1020b56ac160aeea48cdde9dc5db7c3c3b915778`
- `git rev-parse origin/main`: `1020b56ac160aeea48cdde9dc5db7c3c3b915778`

Recent log:

```text
1020b56 Implement D06 GPIM refreeze with guarded pKN
b2926ad Implement D05 GPIM guardian price-stock coherence
6908be4 Merge D04 S12D_B source price and seed audit
e183d33 Implement D04 S12D_B source price and seed audit
7d85d55 Merge D03 S29C price and deflator provenance audit
```

## 2. D05/D06 Lock Summary

- D05 decision: `AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN`.
- D05 commit: `b2926ad Implement D05 GPIM guardian price-stock coherence`.
- D06 decision: `AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION`.
- D06 commit: `1020b56 Implement D06 GPIM refreeze with guarded pKN`.
- Active fixed-assets/capacity-capital object: `K_capacity = ME + NRC` from the D06 refrozen panel.
- D07-0 does not revise pKN, survival rules, warmup rules, or the capacity-capital boundary.

## 3. Purpose of D07-0

D07-0 creates a source-of-truth consumption contract for level/accounting variables. It tells the next D07 pass which variables are authorized, parked, candidate-only, diagnostic, superseded, or blocked. It does not build the final regression/model panel.

## 4. Level/Accounting-Only Scope

Authorized objects are levels, accounting ingredients, price/valuation supports, wage-share accounting ratios, and explicitly classified source contracts. Logs, growth rates, first differences, q_omega indexes, interactions, periodized model variants, stationarity classifications, cointegration-ready panels, and regression-ready variables are parked.

## 5. Fixed-Assets Capacity Block Summary

The only baseline capacity-capital object is D06-refrozen `K_real_capacity_refrozen = K_real_ME_refrozen + K_real_NRC_refrozen`. Current-cost capacity, ME/NRC component stocks, current investment ingredients, guarded real investment ingredients, and D06 pKN support variables are authorized for D07 level/accounting panel consumption. Total capital, total fixed assets, IPP, residential capital, and government transportation are not authorized as baseline capacity capital.

## 6. Output/Value-Added Block Summary

NFC real GVA baseline (`Y_REAL_NFC_GVA_BASELINE`) is authorized as the authoritative real output level. NFC nominal GVA/NVA are authorized as direct accounting levels. Corporate nominal GVA/NVA are authorized for reconciliation and robustness, not as the clean productive-origin baseline. Financial nominal GVA/NVA are candidate-only financial correction/accounting objects. Corporate and financial real GVA residual construction remains blocked.

## 7. Shaikh-Tonak Surplus-Transfer Principle

D07-0 records the surplus-transfer principle: productive-origin surplus must be distinguished from surplus transfers, claims, absorptions, and redistributions. Financial-sector income accounts are transfer, reconciliation, financial-correction, or diagnostic objects unless a validated crosswalk authorizes stronger use.

## 8. Shaikh Appendix Status

Shaikh appendix logic is an operational guide, accounting discipline, plausibility guide, and example of avoiding double counting. It is not a binding line-by-line replication target and cannot force unvalidated adjusted NOS, override provider gates, or promote unvalidated imputed-interest corrections.

## 9. Surplus Accounting Ladder

A. NFC productive-origin baseline: NFC GVA/NVA/COMP/CFC/NOS/profit/tax/retained/transfer ingredients are authorized as the strict productive-origin accounting baseline.

B. Corporate reconciliation variants: corporate GVA/NVA/COMP/CFC/NOS/profit/tax/retained/transfer ingredients are authorized for reconciliation, robustness, and comparison, not automatic productive-origin baseline substitution.

C. Financial-transfer-adjusted corporate candidates: financial and imputed-interest objects remain candidate-only or diagnostic unless semantic and historical/current crosswalk validation exists.

## 10. Distributive Variable Hierarchy

The preferred operational distributive variable is wage share, led by `NFC_COMPENSATION_SHARE_GVA`. Profit-share variants are accounting scaffolds and diagnostics. Exploitation-rate variants are retained as alternative distributive construction contracts; S30B records no constructed exploitation-rate series in the current closure.

## 11. Financial Correction Gate

Financial correction objects are candidate-only unless a prior validated crosswalk exists. `NFC_NET_INT` is a bounded diagnostic/proxy source for NFC net interest and miscellaneous payments, not an exact Shaikh Appendix 6.7 correction and not a license to promote unvalidated financial adjustments to baseline.

## 12. Frontier/Context Parking

IPP, government transportation, highways and streets, transportation structures, and related context variables are parked as frontier/context/conditioning objects. Residential capital remains exclusion-diagnostic only. None enter `K_capacity` or baseline productive accumulation capital.

## 13. Supersession and Parking Summary

Older D01-D04, S12D, and S29D/S29E GPIM/Kcap objects that conflict with the D06 refrozen boundary are superseded for baseline use and preserved for audit/provenance. S29F/S29K total-capital and analytical transformation outputs are parked or blocked for D07 level/accounting consumption.

## 14. Validation Table

| Check | Status | Notes |
|---|---:|---|
| REPO_STATE_RECORDED | PASS | branch main HEAD 1020b56 origin/main 1020b56 status_short D07-0 generated artifacts only |
| D06_AUTHORIZATION_PRESENT | PASS | D06 decision authorizes D07 capacity panel consumption and D06 validation checks pass. |
| D06_FIXED_ASSETS_OBJECTS_CLASSIFIED | PASS | D06 capacity, asset, and guardian panels contain ME, NRC, and capacity objects. |
| NO_D05_D06_REOPENING | PASS | D07-0 only reads D05/D06 artifacts and does not revise pKN, survival, warmup, or capacity boundary. |
| LEVEL_ACCOUNTING_ONLY_ENFORCED | PASS | No final regression/model panel is created. |
| TRANSFORMATIONS_PARKED | PASS | Logs, growth rates, first differences, q_omega, interactions, periodization, stationarity, and cointegration objects are parked. |
| OUTPUT_VALUE_ADDED_BLOCK_CLASSIFIED | PASS | Output/value-added objects are classified by sector boundary and nominal/real status. |
| SURPLUS_DISTRIBUTION_SCAFFOLD_CREATED | PASS | Surplus/distribution scaffold created with required metadata fields. |
| SHAIKH_TONAK_SURPLUS_TRANSFER_PRINCIPLE_RECORDED | PASS | Financial-sector variables are transfer/reconciliation/correction candidates, not productive-origin surplus equivalents. |
| SHAIKH_APPENDIX_NOT_BINDING_REPLICATION_TARGET | PASS | Shaikh appendix recorded as conceptual benchmark/accounting guide, not binding line-by-line recipe. |
| WAGE_SHARE_MARKED_PRIMARY_OPERATIONAL_DISTRIBUTIVE_VARIABLE | PASS | Wage share is marked as preferred operational distributive variable. |
| EXPLOITATION_RATE_MARKED_ALTERNATIVE_DISTRIBUTIVE_VARIABLE | PASS | Exploitation rate is retained as an alternative distributive construction contract. |
| PROFIT_SHARE_MARKED_ACCOUNTING_SCAFFOLD | PASS | Profit-share variants are scaffolds/diagnostics, not primary operational variables. |
| FINANCIAL_CORRECTION_GATE_ENFORCED | PASS | Financial correction candidates are not promoted to baseline absent crosswalk validation. |
| UNVALIDATED_IMPUTED_INTEREST_NOT_BASELINE_AUTHORIZED | PASS | Table 7.11 and imputed-interest candidates remain candidate/diagnostic only. |
| FRONTIER_CONTEXT_VARIABLES_PARKED | PASS | IPP and government transportation/context variables are parked. |
| OLD_GPIM_OBJECTS_SUPERSEDED_FOR_BASELINE | PASS | Older GPIM/Kcap objects are superseded for baseline use and preserved for audit. |
| NO_TOTAL_CAPITAL_BASELINE_AUTHORIZED | PASS | No total-capital object is authorized. |
| NO_TOTAL_FIXED_ASSETS_BASELINE_AUTHORIZED | PASS | No total fixed-assets object is authorized. |
| NO_IPP_BASELINE_CAPITAL_AUTHORIZED | PASS | IPP is not baseline capacity capital. |
| NO_RESIDENTIAL_BASELINE_CAPITAL_AUTHORIZED | PASS | Residential capital is not baseline capacity capital. |
| NO_GOV_TRANS_BASELINE_CAPITAL_AUTHORIZED | PASS | Government transportation capital is not baseline capacity capital. |
| CONSUMPTION_CONTRACT_CREATED | PASS | Consumption contract rows created. |
| DECISION_RECORDED | PASS | AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION |

## 15. Final Decision Code

`AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION`
