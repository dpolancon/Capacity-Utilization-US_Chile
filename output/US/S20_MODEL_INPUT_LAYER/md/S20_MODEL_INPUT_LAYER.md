# S20 Model-Input Layer

## Scope

S20 consumes the S14 Chapter 2 source-of-truth consolidation and constructs a bounded model-input layer. It preserves the eight S14-authorized GPIM variables and derives only the provisional `K_GROSS_GPIM_TOTAL` component-sum scale benchmark on common support.

S20 does not reconstruct GPIM, reopen provider discovery, run econometrics, estimate theta, construct productive capacity, construct utilization, construct accumulated q, or construct weighted/index-number aggregates.

## Panel Summary

| variable_id | s20_variable_role | unit | s20_object_status | span_and_rows |
|---|---|---|---|---|
| I_NOMINAL_DIRECT_ME | CANONICAL_NOMINAL_INVESTMENT_INPUT | current_millions | S14_REGISTERED_PRESERVED | 1901-2024 (124 rows) |
| I_NOMINAL_DIRECT_NRC | CANONICAL_NOMINAL_INVESTMENT_INPUT | current_millions | S14_REGISTERED_PRESERVED | 1901-2024 (124 rows) |
| I_REAL_GPIM_ME | BASELINE_REAL_INVESTMENT_INPUT | millions_2017 | S14_REGISTERED_PRESERVED | 1901-2024 (124 rows) |
| I_REAL_GPIM_NRC | BASELINE_REAL_INVESTMENT_INPUT | millions_2017 | S14_REGISTERED_PRESERVED | 1901-2024 (124 rows) |
| K_GROSS_GPIM_ME | PRIMARY_COMPONENT_GPIM_REGISTER | millions_2017 | S14_REGISTERED_PRESERVED | 1925-2024 (100 rows) |
| K_GROSS_GPIM_NRC | PRIMARY_COMPONENT_GPIM_REGISTER | millions_2017 | S14_REGISTERED_PRESERVED | 1931-2024 (94 rows) |
| K_GROSS_GPIM_TOTAL | PROVISIONAL_COMPONENT_SUM_SCALE_BENCHMARK | millions_2017 | S20_DERIVED_PROVISIONAL | 1931-2024 (94 rows) |
| P_K_SFC_ME_2017_100 | BASELINE_CAPITAL_PRICE_INPUT | index_2017_100 | S14_REGISTERED_PRESERVED | 1925-2024 (100 rows) |
| P_K_SFC_NRC_2017_100 | BASELINE_CAPITAL_PRICE_INPUT | index_2017_100 | S14_REGISTERED_PRESERVED | 1931-2024 (94 rows) |

## Aggregation and Depletion Locks

GPIM is asset-account-specific first and aggregation second. S20 preserves ME and NRC component lineage and derives the aggregate only ex post from registered component stocks.

- `K_GROSS_GPIM_TOTAL = K_GROSS_GPIM_ME + K_GROSS_GPIM_NRC`.
- The provisional aggregate begins in 1931.
- ME-only 1925-1930 observations remain component-only.
- No independent aggregate GPIM stock is constructed.
- No primitive aggregate survival/depletion profile is constructed.
- S20 inherits and preserves upstream validated GPIM component lineage; it validates lineage, units, support, and row-level component-sum identity only.

## Distribution Ledger

| object_id | object_role | status | source_status |
|---|---|---|---|
| WAGE_SHARE_UNADJUSTED_BASELINE | PREFERRED_DISTRIBUTION_INPUT_PENDING_AUTHORIZED_SOURCE | PENDING_AUTHORIZED_SOURCE | No authorized wage-share source is present in the S14 GPIM input contract. |
| PROFIT_SHARE_ALTERNATIVE_RECONCILIATION | ALTERNATIVE_RECONCILIATION_EVIDENCE_PENDING_AUTHORIZED_SOURCE | PENDING_OPTIONAL_SOURCE | No authorized profit-share source is present in the S14 GPIM input contract. |
| SHAIKH_ADJUSTED_WAGE_SHARE | BLOCKED_PENDING_CROSSWALK_AND_DATA | BLOCKED | No current-release semantic/accounting crosswalk and data contract is authorized in S20. |
| SHAIKH_ADJUSTED_PROFIT_SHARE | BLOCKED_PENDING_CROSSWALK_AND_DATA | BLOCKED | No current-release semantic/accounting crosswalk and data contract is authorized in S20. |

## Blocked, Parked, And Excluded Objects

| object_id | status | reason |
|---|---|---|
| INDEPENDENT_AGGREGATE_GPIM_STOCK | EXCLUDED | S20 may derive only component-sum K_GROSS_GPIM_TOTAL from S14 component registers. |
| AGGREGATE_SURVIVAL_DEPLETION_PROFILE | EXCLUDED | Survival/depletion remains asset-account-specific. |
| GPIM_WEIGHTED_CAPITAL_AGGREGATE | PARKED_GPIM_WEIGHTED_AGGREGATION_PENDING_VALUE_REGISTER_PROTOCOL | Future weights require a separate GPIM value-register protocol. |
| TORNQVIST_CAPITAL_INDEX | EXCLUDED | Index-number aggregation is outside S20. |
| DIVISIA_CAPITAL_INDEX | EXCLUDED | Index-number aggregation is outside S20. |
| PRODUCTIVE_EFFICIENCY_WEIGHTED_STOCK | EXCLUDED | No weights may encode theta, productivity, productive capacity, or utilization. |
| THETA_T | EXCLUDED | S20 prepares inputs only. |
| PRODUCTIVE_CAPACITY_Y_P | EXCLUDED | S20 prepares inputs only. |
| CAPACITY_UTILIZATION_MU | EXCLUDED | S20 prepares inputs only. |
| ACCUMULATED_Q | ACCUMULATED_Q_PARKED_S21_CLOSED | Accumulated q remains parked. |
| S21_ACCUMULATED_Q_LAYER | ACCUMULATED_Q_PARKED_S21_CLOSED | S20 does not authorize S21. |
| IPP_FRONTIER_CONDITIONER | PARKED_CONTROL_CONDITIONERS | Future control candidate only; not baseline productive capital. |
| GOV_TRANS_FRONTIER_CONDITIONER | PARKED_CONTROL_CONDITIONERS | Future control candidate only; not baseline productive capital. |
| SHAIKH_ADJUSTED_DISTRIBUTION_OBJECTS | BLOCKED_PENDING_CROSSWALK_AND_DATA | Requires current-release data and semantic/accounting crosswalk. |
| FAAt402_BASELINE_PROMOTION | EXCLUDED_VALIDATION_ONLY_HISTORICAL_CONTEXT | FAAt402 remains validation-only. |
| DIAGNOSTIC_NET_VALUE_GPIM_STOCK | EXCLUDED | Diagnostic net-value GPIM stock remains excluded. |
| NFC_OUTPUT_PRICE_TRANSLATION_BASELINE | EXCLUDED_ROBUSTNESS_ONLY_HISTORICAL_CONTEXT | NFC output-price translation remains robustness-only. |

## Validation Checks

| check_id | status | evidence |
|---|---|---|
| CURRENT_HEAD_CHECKED_AT_A93B420 | PASS | HEAD=a93b420; branch=main. |
| S14_INPUTS_FOUND | PASS | S14 panel, role ledger, validation table, and report are present. |
| S20_PLANNING_DECISION_RECOGNIZED | PASS | AUTHORIZE_S20_IMPLEMENTATION_PROMPT decision count: 1. |
| S20_AGGREGATION_DEPLETION_ADDENDUM_RECOGNIZED | PASS | AUTHORIZE_S20_IMPLEMENTATION_WITH_AGGREGATION_DEPLETION_LOCKS count: 1. |
| S14_DECISION_RECOGNIZED | PASS | AUTHORIZE_S20_MODEL_INPUT_LAYER count: 1; S14 PASS checks: 13/13. |
| EXACT_EIGHT_VARIABLE_S14_ALLOWLIST_CONSUMED | PASS | S14 variables consumed: I_NOMINAL_DIRECT_ME, I_NOMINAL_DIRECT_NRC, I_REAL_GPIM_ME, I_REAL_GPIM_NRC, K_GROSS_GPIM_ME, K_GROSS_GPIM_NRC, P_K_SFC_ME_2017_100, P_K_SFC_NRC_2017_100. |
| ME_AND_NRC_COMPONENT_STOCKS_PRESERVED | PASS | ME component rows: 100; NRC component rows: 94. |
| COMPONENT_FIRST_GPIM_RULE_PRESERVED_AS_LINEAGE | PASS | S20 records asset-account GPIM first, aggregation second as lineage. |
| AGGREGATE_CONSTRUCTED_ONLY_ON_COMMON_SUPPORT | PASS | Aggregate years: 1931-2024; rows: 94. |
| AGGREGATE_STARTS_IN_1931 | PASS | Minimum aggregate year: 1931. |
| NO_PARTIAL_SUPPORT_AGGREGATE_1925_1930 | PASS | Aggregate rows 1925-1930: 0; ME component-only rows 1925-1930: 6. |
| AGGREGATE_IDENTITY_ROW_LEVEL_CHECKS_PASS | PASS | Maximum absolute identity residual: 0.000000007450581. |
| UNITS_VALIDATED_AS_MILLIONS_2017_BEFORE_AGGREGATION | PASS | Component stock units observed: millions_2017. |
| K_GROSS_GPIM_TOTAL_LABELLED_PROVISIONAL_BENCHMARK | PASS | K_GROSS_GPIM_TOTAL carries PROVISIONAL_COMPONENT_SUM_SCALE_BENCHMARK role. |
| NO_INDEPENDENT_AGGREGATE_GPIM_STOCK_CONSTRUCTED | PASS | Independent aggregate GPIM stock is absent from panel and recorded as excluded. |
| NO_AGGREGATE_SURVIVAL_DEPLETION_PROFILE_CONSTRUCTED | PASS | Aggregate survival/depletion profile is absent and recorded as excluded. |
| S20_STOCK_FLOW_CLAIM_LIMITED_TO_LINEAGE_PRESERVING_VALIDATION | PASS | S20 validates lineage, units, support, and component-sum identity only. |
| NO_WEIGHTED_OR_INDEX_NUMBER_AGGREGATE_CONSTRUCTED | PASS | No weighted, Tornqvist, or Divisia aggregate variable appears in the S20 panel. |
| GPIM_WEIGHTED_AGGREGATION_PARKED | PASS | Weighted aggregation is recorded as PARKED_GPIM_WEIGHTED_AGGREGATION_PENDING_VALUE_REGISTER_PROTOCOL. |
| PRODUCTIVE_EFFICIENCY_WEIGHTS_EXCLUDED | PASS | Productive-efficiency weights are excluded and absent from the panel. |
| THETA_NOT_ESTIMATED | PASS | No theta variable, coefficient, or column is emitted. |
| PRODUCTIVE_CAPACITY_NOT_CONSTRUCTED | PASS | No productive-capacity object is emitted. |
| UTILIZATION_NOT_CONSTRUCTED | PASS | No utilization object is emitted. |
| ACCUMULATED_Q_NOT_CONSTRUCTED | PASS | No accumulated q object is emitted; S21 remains closed. |
| FRONTIER_CONDITIONERS_EXCLUDED_FROM_BASELINE | PASS | IPP and GOV_TRANS are parked control-conditioners and absent from the panel. |
| SHAIKH_ADJUSTMENT_BLOCKED_UNLESS_CROSSWALK_PLUS_DATA_EXIST | PASS | Shaikh-adjusted distribution objects are blocked pending crosswalk plus data. |
| NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED | PASS | S20 reads only S14 consolidation artifacts and S20 planning gate reports. |
| NO_GPIM_RECONSTRUCTION | PASS | S20 derives only a component-sum aggregate from S14 registered component stocks. |
| NO_DOWNSTREAM_SCRIPTS_INVOKED | PASS | Executable S20 lines invoking S21/S22/S30I/S30/S32: 0. |
| NO_ECONOMETRICS_RUN | PASS | Econometric function calls found in S20 script: 0. |
| FINAL_DECISION_EXPLICIT | PASS | Final decision resolved explicitly as AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION. |

## Final Decision

**AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION**
