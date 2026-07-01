# D08 Source-of-Truth Review with GPIM Repair-Regression Audit

## 1. Opening Repo State

- Pre-edit `git status --short`: clean. This was verified before generating D08 artifacts.
- Generation-time `git status --short`: D08 generated artifacts only
- Generation-time `git status -sb`: `## main...origin/main
?? codes/US_D08_source_of_truth_review_gpim_repair_audit.R
?? output/US/D08_SOURCE_OF_TRUTH_REVIEW_WITH_GPIM_REPAIR_REGRESSION_AUDIT/`
- `git branch --show-current`: `main`
- `git rev-parse HEAD`: `acd7ddae9ae26a492ef37661ca20cc29e9656b05`
- `git rev-parse origin/main`: `acd7ddae9ae26a492ef37661ca20cc29e9656b05`

Recent log:

```text
acd7dda Implement D07 level accounting panel consumption
f749c1f Implement D07-0 source-of-truth level accounting contract
1020b56 Implement D06 GPIM refreeze with guarded pKN
b2926ad Implement D05 GPIM guardian price-stock coherence
6908be4 Merge D04 S12D_B source price and seed audit
```

## 2. D05/D06/D07-0/D07 Lock Summary

D08 reads the locked D05, D06, D07-0, and D07 decisions and does not reopen them. D05 authorized D06 GPIM refreeze, D06 authorized D07 capacity consumption, D07-0 authorized level/accounting panel consumption, and D07 authorized D08 source-of-truth review.

## 3. D08 Purpose and Non-Construction Scope

D08 audits the D07 source-of-truth level/accounting panel and the GPIM repair path. It computes diagnostics only inside audit ledgers; it creates no source variables, transformations, model variables, or econometric outputs.

## 4. D07 Panel Integrity Summary

D07 long rows: 4241; D07 wide years: 101; consumed variables: 44.

## 5. Long/Wide Consistency Summary

Long/wide reshape max absolute difference: 0. Duplicate long pairs: 0; duplicate wide years: 0.

## 6. Contract Compliance Summary

Every D07 panel variable is authorized by D07-0. Non-authorized variables are preserved in not-consumed/provenance ledgers only.

## 7. Boundary Leakage Summary

Forbidden boundary patterns are absent from the D07 panel. Not-consumed/provenance references to forbidden objects are permitted and audited separately.

## 8. D06-to-D07 Capacity Equality Summary

D07 fixed-assets/capacity values match D06 source CSVs within CSV serialization tolerance.

## 9. Capacity Identity Summary

K_real_capacity_refrozen equals ME plus NRC and K_current_capacity_refrozen equals current-cost ME plus NRC within audit tolerance.

## 10. Output/Value-Added Boundary Summary

NFC real GVA baseline, NFC nominal GVA/NVA, corporate nominal GVA/NVA, and NFC price support follow D07-0 authorization. Corporate and financial real GVA residual construction remains absent.

## 11. Surplus/Distribution Classification Summary

NFC productive-origin ingredients and corporate reconciliation variants are consumed where authorized. Financial-transfer-adjusted candidates remain outside the panel.

## 12. Financial Correction Gate Summary

Unvalidated financial correction and imputed-interest candidates remain candidate/diagnostic ledger objects and are not consumed as baseline.

## 13. Coverage and Missingness Summary

```text
                        Var1 Freq
        COMPLETE_WITHIN_SPAN   44
 NOT_CONSUMED_STATUS_BLOCKED  101
```

Missingness is recorded and not repaired.

## 14. Numerical Sanity Summary

Numerical sanity diagnostics were completed for all consumed variables. Flags are review diagnostics only and no values were altered.

## 15. Provenance Summary

Every consumed variable has provenance with source stage, file, source column, allowed transformation type, D07-0 status, and D07 consumption status.

## 16. Not-Consumed Ledger Summary

Non-consumed D07-0 rows remain absent from the D07 panel and are preserved for audit, future transformation, frontier/context, or crosswalk review.

## 17. GPIM Initialization Trace Summary

D05 did not decide warmup or initialization. D06 decided asset-specific warmup, uses no inherited pre-price capital stock, uses no Shaikh pinch-year stock anchor, and starts construction in 1925 for ME and 1931 for NRC with analysis start 1947.

## 18. Warmup Sufficiency by Asset

ME warmup is likely adequate relative to L=14. NRC warmup is flagged for review relative to L=30 but does not block because identity, scale, pKN, and source-consumption checks pass.

## 19. pKN Level-Anchor and Normalization Summary

pKN_ME and pKN_NRC are D05-authorized stock-valuation prices normalized to 2017=100. D06 did not silently rebase them and D07 did not revise them.

## 20. Real-Investment Scale Summary

D06 I_real_guardian equals I_current divided by pKN_guardian/100, and D07 consumed the same I_real_guardian values.

## 21. Current-Cost Valuation Identity Summary

Asset and capacity current-cost valuation identities pass: K_current equals K_real times pKN divided by 100.

## 22. Old GPIM Repair-Regression Summary

Old GPIM errors did not re-enter D07: no raw quantity-index aggregation, no terminal service-life cliff, no total-capital baseline, no old S12D/S29C/S29D/S29E/S29F object, and no inherited pre-price stock anchor enters the source-of-truth panel.

## 23. Shaikh Pinch-Year Non-Replication Note

D06 does not use Shaikh pinch years as binding stock-level anchors. This is permitted because Shaikh supplies methodological guidance, not a target series; the D05-pKN-plus-warmup rule is documented and coherent in D06.

## 24. Review Flags Summary

```text
   Var1            Var2 Freq
 MEDIUM REVIEW_REQUIRED    1
```

No blocking review flag remains.

## 25. Validation Table

| Check | Status | Notes |
|---|---:|---|
| REPO_STATE_RECORDED | PASS | branch main HEAD acd7dda origin/main acd7dda status_short D08 generated artifacts only |
| D07_AUTHORIZATION_PRESENT | PASS | Required D05/D06/D07-0/D07 decisions are present. |
| D07_FILES_PRESENT | PASS | All required D07 files are present. |
| D07_VALIDATION_ALL_PASS | PASS | D07 validation checks all PASS. |
| PANEL_LONG_WIDE_CONSISTENT | PASS | Long/wide uniqueness and reshape equality pass. |
| VARIABLE_DICTIONARY_COMPLETE | PASS | Dictionary covers consumed variables and required fields. |
| CONTRACT_COMPLIANCE_PASS | PASS | Every consumed variable is authorized by D07-0. |
| NO_UNAUTHORIZED_OBJECT_CONSUMED | PASS | No non-authorized D07-0 object enters panel. |
| NO_PROHIBITED_BOUNDARY_LEAKAGE | PASS | Forbidden object patterns are absent from D07 panel. |
| D06_TO_D07_CAPACITY_VALUES_MATCH | PASS | D07 capacity/fixed-assets values match D06 source values. |
| CAPACITY_IDENTITIES_PASS | PASS | D06/D07 capacity identities pass. |
| OUTPUT_VALUE_ADDED_BOUNDARY_PASS | PASS | Output/value-added boundary audit passes. |
| SURPLUS_DISTRIBUTION_CLASSIFICATION_PASS | PASS | Surplus/distribution ladder audit passes. |
| FINANCIAL_CORRECTION_GATE_PASS | PASS | Financial correction candidates remain outside D07 panel. |
| COVERAGE_MISSINGNESS_RECORDED | PASS | Coverage/missingness ledger statuses are valid. |
| NO_MISSINGNESS_REPAIR_DETECTED | PASS | D08 detects no interpolation, extrapolation, carry-forward, or residual filling in D07 artifacts. |
| NUMERICAL_SANITY_AUDIT_COMPLETED | PASS | Numerical sanity audit completed for all consumed variables. |
| PROVENANCE_AUDIT_PASS | PASS | Provenance rows are complete and use allowed transformation types. |
| NOT_CONSUMED_LEDGER_AUDIT_PASS | PASS | Not-consumed rows use coherent statuses and remain absent from panel. |
| GPIM_INITIALIZATION_RULE_RECORDED | PASS | D06 asset-specific initialization rule is recorded. |
| NO_SHAIKH_PINCH_YEAR_ASSUMED | PASS | D06 does not use Shaikh pinch years as binding anchors. |
| NO_INHERITED_PRE_PRICE_STOCK_INVENTED | PASS | D06 invents no inherited pre-price capital stock. |
| WARMUP_LENGTH_REPORTED_BY_ASSET | PASS | Warmup length is reported for ME and NRC. |
| WARMUP_SUFFICIENCY_ASSESSED_BY_ASSET_LIFE | PASS | Warmup sufficiency assessed against locked asset life. |
| PKN_LEVEL_ANCHOR_DOCUMENTED | PASS | pKN level anchor documented as D05-authorized stock-valuation price. |
| PKN_2017_NORMALIZATION_CONFIRMED | PASS | pKN base year 2017 equals 100 for ME and NRC. |
| REAL_INVESTMENT_SCALE_COHERENT_WITH_PKN | PASS | I_real_guardian scale matches I_current/(pKN/100). |
| CURRENT_COST_IDENTITY_PASS | PASS | Current-cost valuation identities pass. |
| GROSS_SURVIVING_STOCK_OBJECT_CONFIRMED | PASS | D06 baseline is gross surviving GPIM ME/NRC stock. |
| SURVIVAL_ARCHITECTURE_CONFIRMED | PASS | D06 survival architecture uses ages 0:200 and no terminal cliff. |
| RAW_QUANTITY_INDEXES_NOT_AGGREGATED | PASS | D06/D07 do not aggregate raw quantity indexes. |
| OLD_GPIM_OBJECTS_NOT_CONSUMED | PASS | Old GPIM objects are absent from D07 panel. |
| SHAIKH_PINCH_YEAR_NON_REPLICATION_RECORDED | PASS | Shaikh pinch-year non-replication recorded. |
| REPAIR_REGRESSION_AUDIT_COMPLETED | PASS | Mandatory GPIM repair-regression audit completed. |
| REVIEW_FLAGS_LEDGER_CREATED | PASS | Review flags ledger created. |
| NO_ECONOMETRICS_RUN | PASS | D08 runs no stationarity, integration, cointegration, regression, or econometric routine. |
| NO_TRANSFORMATIONS_CREATED | PASS | D08 writes diagnostics only and does not add variables to source-of-truth panels. |
| DECISION_RECORDED | PASS | AUTHORIZE_D09_TRANSFORMATION_PLANNING |

## 26. Final Decision Code

`AUTHORIZE_D09_TRANSFORMATION_PLANNING`
