# S12 Source-of-Truth Construction Scaffold

## Purpose

This scaffold translates the closed provider handoff and S11B/S11C price hierarchy into a pre-econometric construction plan. It validates metadata, required provider IDs, object roles, and hard prohibitions. It does not construct final series.

## Inputs

- Provider handoff: `data/provider_handoffs/US_BEA_FixedAssets/2026-06-11`
- Price registry: `output/US/S12_SOURCE_OF_TRUTH_READINESS/csv/S12_price_object_construction_registry.csv`
- Provenance authority: `chapter2_vault/04_data_measurement/V01_DataProvenance_Managment.md`
- Provider menu rows: 71
- Provider validation: 71 PASS / 0 FAIL
- Price registry rows: 8
- The handoff is metadata-complete but contains no observation payload; numerical imports remain pending.

## Locked Price Hierarchy

- Baseline: `P_Y_NFC_GVA_IMPLICIT_SOURCE`.
- Validation: `P_Y_NFC_GVA_T115_VALIDATION`.
- Robustness: the six explicitly named `P_Y_PROXY_*` objects.
- No proxy is admissible as a CORP or FC GVA deflator.

## Construction Plan Summary

- Construction-plan rows: 46
| allowed_status | rows |
|---|---|
| baseline_allowed_not_constructed | 2 |
| blocked_pending_current_release_protocol | 9 |
| construction_planned | 1 |
| construction_ready | 1 |
| diagnostic_ready | 2 |
| prohibited | 9 |
| protocol_definition_required | 3 |
| robustness_planned | 6 |
| robustness_ready | 6 |
| source_input_ready | 2 |
| validation_only | 2 |
| validation_ready | 3 |

## Baseline and Validation Objects

The baseline real-output plan uses NFC current-dollar GVA and the same-boundary NFC implicit deflator, with direct T11400 line 41 chained-dollar NFC GVA as validation. T11500 line 1 remains a validation-only price counterpart.
Direct FAAt407 nominal ME and NRC investment remains canonical. FAAt401 stocks, FAAt404 depreciation, and FAAt402 quantity indexes remain validation or diagnostic ingredients according to their locked roles.

## GPIM Boundary

`K_G_NFC_ME_GPIM`, `K_G_NFC_NRC_GPIM`, and `K_G_NFC_KCAP_GPIM` are registered as planned downstream objects. Their exact initialization, survival/depreciation parameterization, and admissible capital-price treatment require a separate construction protocol. FAAt402 cannot be used as a GPIM baseline input or output.

## Distribution Boundary

Unadjusted `omega_NFC` and `omega_CORP` are allowed first-pass baseline placeholders. All current-release Shaikh-adjusted objects remain `blocked_pending_current_release_protocol` and may not overwrite the unadjusted baseline.

## Blocked and Prohibited Objects

| target_variable | allowed_status | blocked_reason |
|---|---|---|
| K_G_NFC_ME_GPIM | protocol_definition_required | Exact GPIM initialization and admissible capital-price treatment remain downstream protocol work; FAAt402 cannot fill that role. |
| K_G_NFC_NRC_GPIM | protocol_definition_required | Exact GPIM initialization and admissible capital-price treatment remain downstream protocol work; FAAt402 cannot fill that role. |
| K_G_NFC_KCAP_GPIM | protocol_definition_required | Exact GPIM initialization and admissible capital-price treatment remain downstream protocol work; FAAt402 cannot fill that role. |
| BankMonIntPaid_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| CorpNFNetImpIntPaid_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| CorpImpIntAdj_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| GVAcorp_adj_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| NOScorp_adj_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| VAcorp_adj_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| omega_adj_CORP_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| pi_adj_res_CORP_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| e_adj_CORP_t | blocked_pending_current_release_protocol | Current BEA candidate lines are provenance ingredients, not formula-admissible inputs. |
| gva_real_or_qindex_corp | prohibited | No same-boundary CORP real GVA source exists; chained-dollar residual subtraction is prohibited. |
| gva_real_or_qindex_fc | prohibited | No same-boundary FC real GVA source exists; chained-dollar residual subtraction is prohibited. |
| gva_price_or_deflator_corp | prohibited | No same-boundary CORP real/price counterpart exists. |
| gva_price_or_deflator_fc | prohibited | No same-boundary FC real/price counterpart exists. |
| corp_gva_deflator_PROXY_RELABEL | prohibited | Proxy relabeling would falsely claim a corporate legal-form boundary. |
| fc_gva_deflator_PROXY_RELABEL | prohibited | Proxy relabeling would falsely claim a financial-corporate boundary. |
| me_investment_implied_fallback_nfc_BASELINE | prohibited | Direct FAAt407 ME investment is available and canonical. |
| nrc_investment_implied_fallback_nfc_BASELINE | prohibited | Direct FAAt407 NRC investment is available and canonical. |
| FAAt402_GPIM_BASELINE | prohibited | FAAt402 is a Fisher quantity-index comparison object only. |

## Execution Boundary

- No provider discovery or provider-menu modification occurred.
- No live API fetch occurred.
- No final output, capital, GPIM, or distribution variable was constructed.
- No S20/S21/S22 script or econometric estimation was run.

## Next Pre-Econometric Step

The next implementation may load versioned observation payloads for the registered provider IDs and price series, harmonize frequency and units, and construct only rows marked construction, validation, or robustness ready. It must preserve all prohibited and protocol-gated rows in this ledger.
