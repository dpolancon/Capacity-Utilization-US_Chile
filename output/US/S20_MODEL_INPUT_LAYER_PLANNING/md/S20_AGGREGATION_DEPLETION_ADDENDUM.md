# S20 Aggregation and Depletion Addendum

## Scope

This addendum refines the S20 model-input implementation contract. It is not S20 implementation. It constructs no model-input data, no GPIM object, no weighted aggregate, no accumulated $q$, no $\theta_t$, no productive capacity, no utilization, and no econometric result.

The current repository boundary is:

- HEAD: `64b600a` (`Plan S20 model input layer`)
- S14: `AUTHORIZE_S20_MODEL_INPUT_LAYER`
- S15: `AUTHORIZE_S20_PLANNING_NOTE`
- S20 planning: `AUTHORIZE_S20_IMPLEMENTATION_PROMPT`

The addendum preserves the S20 planning decision but narrows the future implementation prompt around aggregation and GPIM depletion.

## Component-First GPIM Rule

The GPIM lineage is asset-account specific. For each asset/account $j$:

$$
I^{nominal}_{j,t}
\rightarrow
P^K_{j,t}
\rightarrow
I^{real}_{j,t}
\rightarrow
\text{GPIM survival/depletion}_{j}
\rightarrow
K^{gross}_{j,t}.
$$

ME and NRC are the primary GPIM registers. Any aggregate capital object is downstream of these component GPIM registers.

S20 must preserve this sequence as lineage. It must not reconstruct the sequence.

## Depletion Rule

Survival and depletion belong at the asset-account level. The GPIM component lineage must keep ME and NRC depletion separate:

- ME has its own capital-price, real-investment, survival/depletion, and gross-stock lineage.
- NRC has its own capital-price, real-investment, survival/depletion, and gross-stock lineage.

S20 must not apply one primitive aggregate survival or depletion profile to total capital.

The following path is forbidden unless a later protocol proves component additivity and separately authorizes it:

$$
I^{TOTAL}
\rightarrow
P^{TOTAL}
\rightarrow
\text{one average survival/depletion profile}
\rightarrow
K^{TOTAL}.
$$

If an aggregate depletion measure is ever needed, it must be derived ex post from component registers. It cannot be imposed before GPIM.

## Provisional Aggregate Rule

S20 may construct only the provisional component-sum scale benchmark:

$$
K\_GROSS\_GPIM\_TOTAL_t
=
K\_GROSS\_GPIM\_ME_t
+
K\_GROSS\_GPIM\_NRC_t.
$$

This object:

- starts on common support in 1931;
- has no partial-support aggregate values for 1925-1930;
- preserves ME-only 1925-1930 as component-only data;
- is a derived scale benchmark;
- is not a final theoretical solution to heterogeneous-capital aggregation;
- is not proof that an independently constructed aggregate NFC GPIM stock would be equivalent.

The aggregate must carry lineage and support flags. The component series remain analytically available after the aggregate is constructed.

## Stock-Flow Consistency Language

S20 must use restrained stock-flow consistency language.

Allowed formulation:

> S20 inherits and preserves the upstream validated GPIM component lineage. It validates only lineage, units, support, and the row-level component-sum identity.

Disallowed formulation:

> S20 independently proves GPIM stock-flow consistency.

A stronger stock-flow consistency audit would require a separate audit layer that reopens S12D/S13 construction evidence. S20 does not do that.

## GPIM-Weighted Aggregation

Weighted aggregation is not rejected in principle. It is parked.

Admissible weights must be generated from the GPIM stock-flow system itself. Possible future weights include:

- gross replacement-cost value shares;
- net current-cost value shares;
- nominal investment-flow shares;
- other GPIM-validated value-register weights.

The future object is recorded as:

`PARKED_GPIM_WEIGHTED_AGGREGATION_PENDING_VALUE_REGISTER_PROTOCOL`

S20 must not construct these weights, a GPIM-weighted capital aggregate, a Törnqvist index, a Divisia index, or any other index-number aggregate.

## Productive-Efficiency Exclusion

No productive-efficiency weights enter S20.

No weighting scheme may smuggle $\theta_t$, productivity, productive capacity, or utilization into the data layer. If weights are later authorized, they may summarize GPIM valuation or composition only. They may not encode estimated elasticities, fitted productive-capacity paths, utilization levels, or productivity rankings.

## S20 Implementation Prompt Amendment

A future S20 implementation prompt may construct:

- preserved ME and NRC component stocks;
- provisional `K_GROSS_GPIM_TOTAL` on common support from 1931;
- support, provenance, and lineage flags;
- row-level aggregate identity checks;
- blocked and parked ledgers for weighted aggregation and accumulated $q$.

A future S20 implementation prompt must not construct:

- an independent aggregate GPIM stock;
- an aggregate survival/depletion profile;
- a GPIM-weighted capital aggregate;
- a Törnqvist or Divisia index;
- a productive-efficiency-weighted stock;
- $\theta_t$;
- productive capacity;
- utilization;
- accumulated $q$;
- econometric results.

## Validation Checks

| check_id | status | evidence |
|---|---|---|
| CURRENT_HEAD_CHECKED | PASS | HEAD is `64b600a` on `main`. |
| S20_PLANNING_DECISION_RECOGNIZED | PASS | S20 planning decision is `AUTHORIZE_S20_IMPLEMENTATION_PROMPT`. |
| EXISTING_VAULT_NOTES_UNMODIFIED | PASS | This addendum creates files only under `output/US/S20_MODEL_INPUT_LAYER_PLANNING/`. |
| NO_MODEL_INPUT_DATA_CONSTRUCTED | PASS | The addendum defines rules only and emits no model-input panel. |
| NO_GPIM_RECONSTRUCTION | PASS | No GPIM construction or reconstruction was performed. |
| NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED | PASS | The addendum used existing S20 planning artifacts only. |
| NO_DOWNSTREAM_SCRIPTS_INVOKED | PASS | No S20, S21, S22, S31I, S30, or S32 script was invoked. |
| NO_ECONOMETRICS_RUN | PASS | No estimator, test, coefficient, or model object was created. |
| COMPONENT_FIRST_GPIM_RULE_STATED | PASS | The lineage is stated as `I_nominal_j -> P_K_j -> I_real_j -> GPIM survival/depletion_j -> K_gross_j`. |
| DEPLETION_COMPONENT_LEVEL_RULE_STATED | PASS | The addendum prohibits a primitive aggregate survival/depletion profile. |
| PROVISIONAL_AGGREGATE_STATUS_STATED | PASS | `K_GROSS_GPIM_TOTAL` is a provisional component-sum benchmark on common support from 1931. |
| STOCK_FLOW_CLAIM_DOWNGRADED | PASS | S20 is limited to preserving lineage, units, support, and row-level identity. |
| GPIM_WEIGHTED_AGGREGATION_PARKED | PASS | Weighted aggregation is parked as `PARKED_GPIM_WEIGHTED_AGGREGATION_PENDING_VALUE_REGISTER_PROTOCOL`. |
| PRODUCTIVE_EFFICIENCY_WEIGHTS_EXCLUDED | PASS | The addendum bars weights that encode theta, productivity, productive capacity, or utilization. |
| FINAL_DECISION_EXPLICIT | PASS | The decision below is one of the permitted outcomes. |

## Final Decision

**AUTHORIZE_S20_IMPLEMENTATION_WITH_AGGREGATION_DEPLETION_LOCKS**

This decision authorizes only a future S20 implementation prompt that incorporates the component-first GPIM lineage, component-level depletion rule, provisional common-support aggregate, downgraded stock-flow consistency claim, parked weighted-aggregation protocol, and productive-efficiency exclusion.
