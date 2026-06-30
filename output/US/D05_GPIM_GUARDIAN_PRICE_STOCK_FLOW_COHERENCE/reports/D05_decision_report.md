# D05 GPIM Guardian Price/Stock-Flow Coherence

## Opening repo state

D05 starts from the verified D04 boundary condition and does not reopen D01-D04.

```text
git status --short: CLEAN_AT_D05_OPENING_CHECK
git branch --show-current: main
git rev-parse HEAD: 6908be4dd7351d63c8da5027925db273487cc817
git log --oneline -5: 6908be4 Merge D04 S12D_B source price and seed audit
e183d33 Implement D04 S12D_B source price and seed audit
7d85d55 Merge D03 S29C price and deflator provenance audit
b84b350 Implement D03 S29C price and deflator provenance audit
0765c69 Merge D02 GPIM input-path and initialization audit
```

## Source/input availability

The six required staged provider/downstream inputs are read from S24B. ME maps to BEA Fixed Assets line 34. NRC maps to line 35. Legal-form gross-stock current-cost objects are not required because D05 constructs GPIM stocks from investment vintages.

```text
                               object_id asset
  FIN__ME__gross_investment_current_cost    ME
         FIN__ME__net_stock_current_cost    ME
       FIN__ME__net_stock_quantity_index    ME
 FIN__NRC__gross_investment_current_cost   NRC
        FIN__NRC__net_stock_current_cost   NRC
      FIN__NRC__net_stock_quantity_index   NRC
                                 role coverage_start coverage_end row_count
        current_cost_gross_investment           1901         2024       124
        current_cost_net_stock_anchor           1925         2024       100
 net_stock_quantity_index_review_only           1925         2024       100
        current_cost_gross_investment           1901         2024       124
        current_cost_net_stock_anchor           1925         2024       100
 net_stock_quantity_index_review_only           1925         2024       100
  status
 PRESENT
 PRESENT
 PRESENT
 PRESENT
 PRESENT
 PRESENT
```

## Methodological lock

Shaikh Appendix 6.8 is used as a methodological template: GPIM must discipline current-cost investment, real/quantity stock movement, and current-cost stock valuation under one stock-flow law. Shaikh is not used as the target series.

## Capacity definition

D05 defines capacity capital as K_capacity = ME + NRC. It does not construct total capital, total fixed assets, IPP, residential capital, government transportation, or an all-capital aggregate.

## Aggregation rule

ME and NRC are validated separately before aggregation. Raw chain-type quantity indexes are not added. K_real_capacity is the sum of K_real_ME and K_real_NRC after asset-level coherence passes. K_current_capacity is the corresponding current-cost sum. pKN_capacity is derived as 100 * K_current_capacity / K_real_capacity.

## Guardian price summary

```text
 asset first_year last_year rows   pKN_start pKN_2017   pKN_end
    ME       1925      2024  100 9224.115153      100  98.77055
   NRC       1931      2024   94    0.117835      100 249.37836
 max_abs_current_recursion_residual max_abs_real_recursion_residual
                 0.0000000002328306              0.0000000004656613
                 0.0000000004656613              0.0000000011641532
```

## Exclusion statement

Provider TOTAL and K_total are excluded from the D05 baseline. Official unmapped price indexes remain review-only. IPP, residential capital, and government transportation remain outside baseline capacity capital.

## Validation table

```text
                            check_id status
                 REPO_STATE_RECORDED   PASS
             REQUIRED_INPUTS_PRESENT   PASS
          ASSET_BOUNDARY_ME_NRC_ONLY   PASS
       NO_TOTAL_CAPITAL_CONSTRUCTION   PASS
   NO_RAW_QUANTITY_INDEX_AGGREGATION   PASS
                  PKN_ME_CONSTRUCTED   PASS
                 PKN_NRC_CONSTRUCTED   PASS
              ME_GPIM_COHERENCE_PASS   PASS
             NRC_GPIM_COHERENCE_PASS   PASS
 CAPACITY_BOTTOM_UP_AGGREGATION_PASS   PASS
                PKN_CAPACITY_DERIVED   PASS
           EXCLUSION_LEDGER_COMPLETE   PASS
             NO_WARMUP_DECISION_MADE   PASS
                 NO_ECONOMETRICS_RUN   PASS
                   DECISION_RECORDED   PASS
                                                                                                                                                                                                                                                                     notes
                                                                                                                                                                     Opening repo state is recorded in D05_decision_report.md; D04 head 6908be4 is the boundary condition.
 FIN__ME__gross_investment_current_cost PRESENT; FIN__ME__net_stock_current_cost PRESENT; FIN__ME__net_stock_quantity_index PRESENT; FIN__NRC__gross_investment_current_cost PRESENT; FIN__NRC__net_stock_current_cost PRESENT; FIN__NRC__net_stock_quantity_index PRESENT
                                                                                                                                                                                                                                 D05 asset panel contains ME and NRC only.
                                                                                                                                                                                                           No total-capital panel, column, or derived baseline is emitted.
                                                                                                                                                                                                         Quantity indexes remain asset-level context and are never summed.
                                                                                                                                                                                                                          pKN_ME is the ME guardian stock-valuation price.
                                                                                                                                                                                                                        pKN_NRC is the NRC guardian stock-valuation price.
                                                                                                                                                                                                                          ME asset-level current and real recursions pass.
                                                                                                                                                                                                                         NRC asset-level current and real recursions pass.
                                                                                                                                                                                                            Capacity is exact ME plus NRC after separate asset validation.
                                                                                                                                                                                                     pKN_capacity is derived from K_current_capacity over K_real_capacity.
                                                                                                                                                                                                                                 All required D05 exclusions are recorded.
                                                                                                                                                                                             D05 does not alter or authorize seed, inherited-vintage, or warmup treatment.
                                                                                                                                                                                                                    D05 reads staged inputs and writes audit outputs only.
                                                                                                                                                                                                                      D05 decision code is written to the decision report.
```

## Final decision

AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN
