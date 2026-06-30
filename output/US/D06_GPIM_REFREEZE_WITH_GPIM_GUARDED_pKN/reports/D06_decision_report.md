# D06 GPIM Refreeze with GPIM-Guarded pKN

## Opening repo state

D06 starts from the committed D05 boundary and does not reopen D01-D05.

```text
git status --short: CLEAN_AT_D06_OPENING_CHECK
git branch --show-current: main
git rev-parse HEAD: b2926addf9db54a53591d6c3043f44302abcfe70
git log --oneline -5: b2926ad Implement D05 GPIM guardian price-stock coherence
6908be4 Merge D04 S12D_B source price and seed audit
e183d33 Implement D04 S12D_B source price and seed audit
7d85d55 Merge D03 S29C price and deflator provenance audit
b84b350 Implement D03 S29C price and deflator provenance audit
git status -sb: main...origin/main [ahead 1]
```

D05 was local and not yet pushed at D06 opening (`main...origin/main [ahead 1]`). This is recorded but does not block local D06 implementation.

## D05 authorization summary

D05 authorization present: `PASS`. D06 consumes D05 outputs only; it does not rerun the D05 price-coherence audit or revise the guardian price logic.

## D06 conceptual lock

D06 is a refreeze pass. It constructs asset-specific ME and NRC gross-survival GPIM stocks first, then constructs K_capacity as ME plus NRC. It does not construct total capital or total fixed assets.

## Input mapping summary

```text
               object_id asset                    role source_column
            I_current_ME    ME            I_current_ME     I_current
                  pKN_ME    ME                  pKN_ME  pKN_guardian
  survival_parameters_ME    ME  survival_parameters_ME      L; alpha
           I_current_NRC   NRC           I_current_NRC     I_current
                 pKN_NRC   NRC                 pKN_NRC  pKN_guardian
 survival_parameters_NRC   NRC survival_parameters_NRC      L; alpha
 coverage_start coverage_end row_count         status
           1925         2024       100        PRESENT
           1925         2024       100        PRESENT
           1925         2024         2 PRESENT_LOCKED
           1931         2024        94        PRESENT
           1931         2024        94        PRESENT
           1931         2024         2 PRESENT_LOCKED
```

## Survival architecture summary

ME uses L=14 and alpha=1.7. NRC uses L=30 and alpha=1.6. D06 uses the D01 untruncated Weibull convention over ages 0:200; survival remains positive beyond L, so no terminal service-life cliff is reintroduced.

## Price-to-real-investment rule

For each asset, D06 constructs I_real_guardian = I_current / (pKN_guardian / 100). The D05 pKN series is normalized to 2017=100 and is not rebased in D06.

## GPIM refreeze rule

For each asset, D06 constructs K_real_refrozen as the sum of D05-guarded real investment vintages weighted by locked Weibull survival probabilities. K_current_refrozen equals K_real_refrozen multiplied by pKN_guardian/100.

## Initialization and warmup

D06 uses the longest D05-authorized pKN history available by asset and treats observations before 1947 as warmup history, not modeled sample observations. It invents no inherited pre-price capital stock.

```text
 asset earliest_I_current_year earliest_pKN_year construction_start_year
    ME                    1925              1925                    1925
   NRC                    1931              1931                    1931
 first_refrozen_stock_year analysis_start_year_if_known
                      1925                         1947
                      1931                         1947
                                                                                                  warmup_rule
 Use D05-authorized real investment from 1925 onward; years before 1947 are warmup, not modeled observations.
 Use D05-authorized real investment from 1931 onward; years before 1947 are warmup, not modeled observations.
                                inherited_vintage_rule
 No inherited pre-D05-price capital stock is invented.
 No inherited pre-D05-price capital stock is invented.
                                                                                                                                                 tail_truncation_rule
 D01 untruncated Weibull convention with ages 0:200; no terminal service-life cliff at L; survival at L+1 remains positive and survival at age 200 is below 0.000001.
 D01 untruncated Weibull convention with ages 0:200; no terminal service-life cliff at L; survival at L+1 remains positive and survival at age 200 is below 0.000001.
                     status
 ASSET_SPECIFIC_WARMUP_USED
 ASSET_SPECIFIC_WARMUP_USED
                                                                                            notes
  pKN coverage begins in 1925 for ME; this is the longest D05-authorized price history available.
 pKN coverage begins in 1931 for NRC; this is the longest D05-authorized price history available.
```

## Asset-level results

```text
 asset first_year last_year rows K_real_1947 K_real_2024     pKN_1947  pKN_2024
    ME       1925      2024  100    115.7689     1380856 1271.8934185  98.77055
   NRC       1931      2024   94 413306.6286     1610205    0.5099036 249.37836
```

## Bottom-up K_capacity summary

```text
 first_year last_year rows K_real_capacity_1947 K_real_capacity_2024
       1931      2024   94             413422.4              2991061
 pKN_capacity_1947 pKN_capacity_2024
         0.8659236          179.8486
```

## Exclusion statement

D06 excludes total capital, BEA total fixed assets, provider TOTAL, IPP baseline, residential baseline, government transportation baseline, raw quantity-index aggregation, and econometrics.

## Validation table

```text
                                          check_id status
                               REPO_STATE_RECORDED   PASS
                         D05_AUTHORIZATION_PRESENT   PASS
                       REQUIRED_D05_INPUTS_PRESENT   PASS
                    REQUIRED_PRICE_OBJECTS_PRESENT   PASS
        REQUIRED_NOMINAL_INVESTMENT_INPUTS_PRESENT   PASS
                        SURVIVAL_PARAMETERS_LOCKED   PASS
                    NO_TERMINAL_CLIFF_REINTRODUCED   PASS
 REAL_INVESTMENT_CONSTRUCTED_FROM_GPIM_GUARDED_pKN   PASS
                      ME_REFROZEN_GPIM_CONSTRUCTED   PASS
                     NRC_REFROZEN_GPIM_CONSTRUCTED   PASS
        CAPACITY_BOTTOM_UP_AGGREGATION_CONSTRUCTED   PASS
                 NO_RAW_QUANTITY_INDEX_AGGREGATION   PASS
                     NO_TOTAL_CAPITAL_CONSTRUCTION   PASS
             NO_FORBIDDEN_BASELINE_OBJECT_INCLUDED   PASS
             INITIALIZATION_WARMUP_LEDGER_COMPLETE   PASS
                               NO_ECONOMETRICS_RUN   PASS
                                 DECISION_RECORDED   PASS
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          notes
                                                                                                                                                                                                                                                                                                                                                                                                                                  Opening repo state recorded; local main was ahead of origin/main by D05 only.
                                                                                                                                                                                                                                                                                                                                                                                                                                                    D05 decision report authorizes D06 and all D05 checks pass.
 output/US/D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE/csv/D05_asset_price_stock_flow_panel.csv present; output/US/D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE/csv/D05_asset_coherence_checks.csv present; output/US/D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE/csv/D05_capacity_aggregation_panel.csv present; output/US/D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE/csv/D05_validation_checks.csv present; output/US/D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE/reports/D05_decision_report.md present
                                                                                                                                                                                                                                                                                                                                                                                                                                                           pKN_ME and pKN_NRC are mapped from D05 pKN_guardian.
                                                                                                                                                                                                                                                                                                                                                                                                                                                  I_current_ME and I_current_NRC are mapped from D05 I_current.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ME L=14 alpha=1.7; NRC L=30 alpha=1.6.
                                                                                                                                                                                                                                                                                                                                                                                                                            D06 uses ages 0:200 with positive survival beyond L and negligible tail at max age.
                                                                                                                                                                                                                                                                                                                                                                                                                                                              I_real_guardian = I_current / (pKN_guardian/100).
                                                                                                                                                                                                                                                                                                                                                                                                                                                 ME gross surviving refrozen GPIM stock constructed separately.
                                                                                                                                                                                                                                                                                                                                                                                                                                                NRC gross surviving refrozen GPIM stock constructed separately.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                      K_capacity_refrozen is exact ME plus NRC.
                                                                                                                                                                                                                                                                                                                                                                                                                                          D06 reads no quantity-index column and aggregates no raw chain index.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                     No total-capital output object is emitted.
                                                                                                                                                                                                                                                                                                                                                                                                                                                     All forbidden baseline objects are excluded in the ledger.
                                                                                                                                                                                                                                                                                                                                                                                                                Asset-specific warmup from D05 pKN history is recorded; no inherited capital stock is invented.
                                                                                                                                                                                                                                                                                                                                                                                                                                                                    D06 writes construction/audit outputs only.
                                                                                                                                                                                                                                                                                                                                                                                                                                                            Decision code is written to D06_decision_report.md.
```

## Final decision

AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION
