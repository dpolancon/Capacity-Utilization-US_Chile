# D07 Level/Accounting Panel Consumption

## 1. Opening Repo State

- Pre-edit `git status --short`: clean. This was verified before generating D07 artifacts.
- Generation-time `git status --short`: D07 generated artifacts only
- Generation-time `git status -sb`: `## main...origin/main
?? codes/US_D07_level_accounting_panel_consumption.R
?? output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/`
- `git branch --show-current`: `main`
- `git rev-parse HEAD`: `f749c1f253f495de328b7a6c599e41eb9966b290`
- `git rev-parse origin/main`: `f749c1f253f495de328b7a6c599e41eb9966b290`

Recent log:

```text
f749c1f Implement D07-0 source-of-truth level accounting contract
1020b56 Implement D06 GPIM refreeze with guarded pKN
b2926ad Implement D05 GPIM guardian price-stock coherence
6908be4 Merge D04 S12D_B source price and seed audit
e183d33 Implement D04 S12D_B source price and seed audit
```

## 2. D05/D06/D07-0 Lock Summary

- D05 decision: `AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN`.
- D06 decision: `AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION`.
- D07-0 decision: `AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION`.
- D07 consumes these locks and does not revise pKN, survival, warmup, GPIM, or D07-0 admissibility decisions.

## 3. D07 Purpose and Scope

D07 materializes the level/accounting panel authorized by D07-0. It is a consumption pass, not discovery, admissibility, transformation, or econometric work.

## 4. D07-0 Contract Consumption Summary

- Authorized D07-0 rows: 48.
- Unique consumed variable ids: 44.
- Non-authorized rows preserved in not-consumed/provenance ledgers: 101.

## 5. Fixed-Assets Capacity Block Consumed

D07 consumes D06-refrozen ME, NRC, and capacity variables, current-cost accounting variables, guarded investment ingredients, and D06 pKN support. The capacity-capital boundary remains `K_capacity = ME + NRC`; total capital, total fixed assets, IPP, residential, and government transportation are not consumed.

## 6. Output/Value-Added Block Consumed

D07 consumes `Y_REAL_NFC_GVA_BASELINE`, NFC nominal GVA/NVA, corporate nominal GVA/NVA, and `P_Y_NFC_GVA_IMPLICIT_SOURCE` from local committed source-level artifacts. It does not construct corporate or financial real GVA by residual deflation.

## 7. Surplus/Distribution Block Consumed

D07 consumes authorized NFC productive-origin accounting ingredients, corporate reconciliation ingredients, and already constructed wage-share ratios. Financial-transfer-adjusted candidates remain out of the panel unless D07-0 authorized them, which it did not.

## 8. Distributive Hierarchy Preserved

`NFC_COMPENSATION_SHARE_GVA` is consumed as the preferred wage-share object. Corporate and NVA wage-share variants are retained as authorized alternatives/reconciliation variants. Profit/surplus shares remain scaffolds or diagnostics where D07-0 classified them so. Exploitation-rate construction contracts are not consumed as series.

## 9. Financial Correction Gate Preserved

Unvalidated financial correction and imputed-interest objects are preserved in ledgers only. D07 does not promote any candidate financial correction into the source-of-truth panel.

## 10. Frontier/Context and Transformation Parking Preserved

IPP, government transportation, highways and streets, transportation structures, residential diagnostics, old GPIM/Kcap outputs, total-capital objects, logs, growth rates, q_omega indexes, interactions, periodized variants, and stationarity/cointegration classifications are not consumed into the panel.

## 11. Coverage and Missingness Summary

```text
                        Var1 Freq
        COMPLETE_WITHIN_SPAN   44
 NOT_CONSUMED_STATUS_BLOCKED  101
```

D07 records missingness by variable span and performs no interpolation, extrapolation, carry-forward, or residual construction.

## 12. Provenance Summary

The provenance ledger records direct reads from D06, S12B, local provider-imported source-level panels, and S30B. D07 records non-consumed D07-0 rows as metadata-only or blocked-not-consumed provenance records.

## 13. Not-Consumed Variables Summary

```text
                              Var1 Freq
         BLOCKED_BOUNDARY_CONFLICT    6
 CANDIDATE_ONLY_REQUIRES_CROSSWALK   22
                   DIAGNOSTIC_ONLY   17
           PARKED_FRONTIER_CONTEXT   41
             PARKED_TRANSFORMATION    5
                   REVIEW_REQUIRED    2
           SUPERSEDED_FOR_BASELINE    8
```

These variables remain preserved for audit, future transformation, frontier/context work, or semantic crosswalk review, but they are absent from the D07 panel.

## 14. Validation Table

| Check | Status | Notes |
|---|---:|---|
| REPO_STATE_RECORDED | PASS | branch main HEAD f749c1f origin/main f749c1f status_short D07 generated artifacts only |
| D07_0_AUTHORIZATION_PRESENT | PASS | D07-0 decision authorizes D07 level/accounting panel consumption. |
| D07_0_CONTRACT_CONSUMED | PASS | Required D07-0 contract files were read. |
| D06_AUTHORIZATION_PRESENT | PASS | D06 decision authorizes D07 capacity consumption and validation checks pass. |
| D06_FIXED_ASSETS_OBJECTS_CONSUMED | PASS | All D07-0-authorized D06 fixed-assets/capacity objects are consumed. |
| LEVEL_ACCOUNTING_PANEL_LONG_CREATED | PASS | 4241 long rows created. |
| LEVEL_ACCOUNTING_PANEL_WIDE_CREATED | PASS | 101 wide years and 44 variables created. |
| VARIABLE_DICTIONARY_CREATED | PASS | Variable dictionary covers consumed variables. |
| COVERAGE_LEDGER_CREATED | PASS | Coverage ledger created. |
| PROVENANCE_LEDGER_CREATED | PASS | Provenance ledger created. |
| NOT_CONSUMED_LEDGER_CREATED | PASS | Not-consumed ledger created. |
| ONLY_AUTHORIZED_D07_LEVEL_OBJECTS_CONSUMED | PASS | Panel variable ids match D07-0 authorized ids with local source series. |
| TRANSFORMATIONS_NOT_CREATED | PASS | D07 only reads direct or already-constructed source-level/accounting objects. |
| NO_LOGS_CREATED | PASS | No log-level variables are consumed or created. |
| NO_GROWTH_RATES_CREATED | PASS | No growth rates or first differences are consumed or created. |
| NO_Q_OMEGA_CREATED | PASS | No q_omega index is consumed or created. |
| NO_INTERACTIONS_CREATED | PASS | No interaction variables are consumed or created. |
| NO_ECONOMETRICS_RUN | PASS | Script runs no stationarity, cointegration, regression, or econometric routines. |
| NO_D05_D06_REOPENING | PASS | D05/D06/D07-0 artifacts are read only. |
| NO_GPIM_REBUILD | PASS | D07 reads D06 refrozen GPIM outputs; it does not rebuild GPIM. |
| NO_PKN_REVISION | PASS | D07 reads D06 pKN support; it does not revise pKN. |
| NO_SURVIVAL_REVISION | PASS | D07 reads D06 outputs; it does not revise survival parameters. |
| NO_TOTAL_CAPITAL_BASELINE_CONSUMED | PASS | No total-capital object enters the panel. |
| NO_TOTAL_FIXED_ASSETS_BASELINE_CONSUMED | PASS | No total fixed-assets object enters the panel. |
| NO_IPP_BASELINE_CAPITAL_CONSUMED | PASS | No IPP baseline capital object enters the panel. |
| NO_RESIDENTIAL_BASELINE_CAPITAL_CONSUMED | PASS | No residential capital object enters the panel. |
| NO_GOV_TRANS_BASELINE_CAPITAL_CONSUMED | PASS | No government transportation capital object enters the panel. |
| UNVALIDATED_FINANCIAL_CORRECTION_NOT_CONSUMED | PASS | Unvalidated financial correction candidates are ledger-only; variables authorized under another block are consumed only in that authorized role. |
| UNVALIDATED_IMPUTED_INTEREST_NOT_CONSUMED | PASS | Unvalidated imputed-interest objects are not consumed. |
| SHAIKH_APPENDIX_NOT_FORCED | PASS | D07 consumes authorized source-level objects and does not force a line-by-line Shaikh appendix replication. |
| WAGE_SHARE_HIERARCHY_PRESERVED | PASS | Preferred NFC wage-share object is consumed. |
| EXPLOITATION_RATE_ALTERNATIVE_STATUS_PRESERVED | PASS | Exploitation-rate construction contracts remain out of the panel because no D07-0-authorized series exists. |
| MISSINGNESS_RECORDED_NOT_FILLED | PASS | Coverage ledger records missingness; no interpolation, extrapolation, or carry-forward is performed. |
| DECISION_RECORDED | PASS | AUTHORIZE_D08_SOURCE_OF_TRUTH_REVIEW |

## 15. Final Decision Code

`AUTHORIZE_D08_SOURCE_OF_TRUTH_REVIEW`
