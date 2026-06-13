# S12D-A3 External Depreciation / Age-Price Anchor

## Why S12D-A3 Was Required

S12D-A2 showed that exact SFC closure cannot identify a net-value schedule: every positive candidate schedule generated a mechanically exact conditional price path. S12D-A3 therefore reviews only existing external methodology evidence for an independently defensible ME and NRC age-price anchor.

## Evidence Reviewed

- The existing provider methodological note `docs/Weibull_Retirement_Distributions.md`, which summarizes Fraumeni (1997), pre-1997 BEA service lives, geometric depreciation, and the distinction between depreciation and retirement.
- The existing project architecture and legacy pipeline documentation, which records broad-asset declining-balance values of L=15, R=1.65, d=0.110 for ME and L=38, R=0.91, d=0.024 for NRC.
- The S11B handbook crosswalk, which confirms that BEA uses age-price profiles but that FAAt402 is a quantity-index validation object, not a capital-price baseline.
- Locked S12C CFC and net-stock series, used only to confirm that aggregate CFC/net-stock ratios are diagnostics rather than vintage age-price profiles.

## External Anchor Registry

| asset_block | anchor_id | object_identified | evidence_value | classification |
|---|---|---|---|---|
| ME | BEA_GEOMETRIC_DEPRECIATION_PROFILE | age_price_profile_family | geometric age-price decline; documented broad-asset rate 0.110 | ROBUSTNESS_ONLY |
| ME | BEA_DECLINING_BALANCE_SERVICE_LIFE_PROFILE | depreciation_rate_and_age_price_family | L=15; R=1.65; d=R/L=0.110 | ROBUSTNESS_ONLY |
| ME | CFC_NET_STOCK_IMPLIED_AGGREGATE_RATE | aggregate_depreciation_diagnostic | median CFC_CC/K_NET_CC = 0.11603259 | INSUFFICIENT_EVIDENCE |
| ME | LIFE_IMPLIED_GEOMETRIC_DEPRECIATION_RATE | life_based_rate_assumption | 1/L_survival = 0.071428571 | SENSITIVITY_ONLY |
| ME | LINEAR_AGE_PRICE_SCHEDULE | assumed_age_price_profile | max(1-j/L,0) | SENSITIVITY_ONLY |
| ME | HYBRID_SENSITIVITY_SCHEDULE | assumed_blended_age_price_profile | 0.5*linear + 0.5*declining-balance | SENSITIVITY_ONLY |
| NRC | BEA_GEOMETRIC_DEPRECIATION_PROFILE | age_price_profile_family | geometric age-price decline; documented broad-asset rate 0.024 | ROBUSTNESS_ONLY |
| NRC | BEA_DECLINING_BALANCE_SERVICE_LIFE_PROFILE | depreciation_rate_and_age_price_family | L=38; R=0.91; d=R/L=0.024 | ROBUSTNESS_ONLY |
| NRC | CFC_NET_STOCK_IMPLIED_AGGREGATE_RATE | aggregate_depreciation_diagnostic | median CFC_CC/K_NET_CC = 0.02789944 | INSUFFICIENT_EVIDENCE |
| NRC | LIFE_IMPLIED_GEOMETRIC_DEPRECIATION_RATE | life_based_rate_assumption | 1/L_survival = 0.033333333 | SENSITIVITY_ONLY |
| NRC | LINEAR_AGE_PRICE_SCHEDULE | assumed_age_price_profile | max(1-j/L,0) | SENSITIVITY_ONLY |
| NRC | HYBRID_SENSITIVITY_SCHEDULE | assumed_blended_age_price_profile | 0.5*linear + 0.5*declining-balance | SENSITIVITY_ONLY |

## Object Identification

The external evidence identifies an asset-specific depreciation rate and a declining-balance age-price family. It does not identify physical survival, productive efficiency, or a capital-price index. Survival remains the separate locked Weibull object. The SFC implicit capital price remains an output conditional on the manually selected value schedule.

## ME and NRC Treatment

ME and NRC can share the declining-balance profile family, but they cannot share one rate. The documented broad-asset anchors are d_ME=0.110 and d_NRC=0.024, and their Weibull survival parameters also remain asset-specific. Detailed-asset heterogeneity and time-varying composition remain limitations.

## Schedule Mapping

| asset_block | survival_profile | age_price_profile | net_value_schedule | current_classification | manual_theory_choice_required |
|---|---|---|---|---|---|
| ME | S_ME(j)=Weibull(L=14, alpha=1.7) | A_ME(j)=(1-0.110)^j | V_ME(j)=S_ME(j)*(1-0.110)^j | ROBUSTNESS_ONLY | TRUE |
| NRC | S_NRC(j)=Weibull(L=30, alpha=1.6) | A_NRC(j)=(1-0.024)^j | V_NRC(j)=S_NRC(j)*(1-0.024)^j | ROBUSTNESS_ONLY | TRUE |

## Stage-Gate Decision

- Decision: `REQUIRE_MANUAL_THEORY_LOCK`.
- S12D-B authorized: no.
The evidence is sufficiently explicit to define a precise candidate protocol, so no provider return is required. It is not sufficient to make the conceptual combination automatic: the dissertation must manually decide whether finite Weibull survival and BEA-style declining-balance age-price decay should jointly define net value.

## Exact Protocol Sentence Proposed For Lock

For the Chapter 2 GPIM baseline, net-value weights shall be defined separately from physical survival as V_i(j)=S_i(j)(1-d_i)^j, where S_i(j) is the locked asset-specific Weibull survival schedule and the documented declining-balance age-price rates are d_ME=0.110 and d_NRC=0.024. These rates are age-price/depreciation anchors only; they are not retirement rates, productive-efficiency profiles, FAAt402 price indexes, NFC output deflators, or final capital-price indexes.

This sentence is proposed for manual adoption in the dissertation and source-of-truth notes. S12D-A3 does not itself activate it.

## Boundary Confirmation

- FAAt402 baseline capital-price use: no.
- NFC output-price baseline capital-price use: no.
- Survival weights relabeled as net-value weights: no.
- Aggregate CFC/net-stock rate treated as a vintage profile: no.
- Productive-efficiency profile constructed: no.
- Final GPIM stocks constructed: no.
- S20/S21/S22 run: no.
- Econometric output created: no.

## Validation

| validation_rule | result | observed |
|---|---|---|
| all six required external anchors evaluated | PASS | BEA_GEOMETRIC_DEPRECIATION_PROFILE; BEA_DECLINING_BALANCE_SERVICE_LIFE_PROFILE; CFC_NET_STOCK_IMPLIED_AGGREGATE_RATE; LIFE_IMPLIED_GEOMETRIC_DEPRECIATION_RATE; LINEAR_AGE_PRICE_SCHEDULE; HYBRID_SENSITIVITY_SCHEDULE |
| ME and NRC evaluated separately | PASS | 12 asset-anchor rows |
| anchor classifications controlled | PASS | INSUFFICIENT_EVIDENCE; ROBUSTNESS_ONLY; SENSITIVITY_ONLY |
| depreciation age-price survival efficiency and price separated | PASS | five distinct protocol rows |
| survival-only not accepted as net-value schedule | PASS | survival remains a separate physical object |
| CFC net-stock rate remains aggregate diagnostic | PASS | not treated as a vintage age-price profile |
| FAAt402 not used as baseline capital-price route | PASS | validation/comparison boundary preserved |
| NFC output price not used as baseline capital-price route | PASS | no output-price capital route |
| no final GPIM stocks constructed | PASS | protocol metadata only |
| no S20/S21/S22 run | PASS | S12D-A3 script only |
| no econometric output created | PASS | documentation and protocol mapping only |
| explicit final decision produced | PASS | REQUIRE_MANUAL_THEORY_LOCK |
| exactly one final decision produced | PASS | REQUIRE_MANUAL_THEORY_LOCK |
| S12D-B remains blocked pending manual lock | PASS | manual theory lock required |
| protocol sentence is explicit and asset-specific | PASS | For the Chapter 2 GPIM baseline, net-value weights shall be defined separately from physical survival as V_i(j)=S_i(j)(1-d_i)^j, where S_i(j) is the locked asset-specific Weibull survival schedule and the documented declining-balance age-price rates are d_ME=0.110 and d_NRC=0.024. These rates are age-price/depreciation anchors only; they are not retirement rates, productive-efficiency profiles, FAAt402 price indexes, NFC output deflators, or final capital-price indexes. |
| provider return not triggered | PASS | Existing documentation contains the rate evidence; the unresolved step is conceptual adoption, not a new provider variable. |
