# S12A Observation Payload Import

## Purpose

S12A reconciles the closed metadata handoff with the staged provider observation route and imports only admissible source observations. It does not construct final source-of-truth variables.

## Inherited locks

- The S11B/S11C/S12 provider and output-price hierarchy remains closed.
- CORP/FC real-price residuals and proxy relabeling remain prohibited.
- FAAt402 remains validation-only.
- Direct FAAt407 nominal ME/NRC investment remains canonical.
- Implied investment remains fallback-only.
- GPIM and Shaikh-adjusted objects remain unconstructed.

## Payload routes checked

| route_role | exists | files_found | observation_payload_present | preferred_for_construction |
|---|---|---|---|---|
| downstream_provider_handoff | TRUE |  9 | FALSE | FALSE |
| downstream_external_provider_copy | TRUE |  6 | TRUE | FALSE |
| upstream_staged_observation_payload | TRUE |  1 | TRUE | TRUE |
| upstream_metadata_payload | TRUE |  4 | FALSE | TRUE |
| raw_snapshot_audit_backup | TRUE | 16 | TRUE | FALSE |

The downstream external provider copy and upstream staged route are byte-identical for the staged observations, provenance ledger, and locked manifest. S12A uses the upstream route as the canonical carrier without modifying either repository.

## Observation payloads found

- Provider source observations imported: 1333
- Distinct provider source series imported: 13
- Price proxy observations imported: 1079
- Distinct price objects with local observations: 8
- Live exact-series API fetch performed: yes.
- Dated raw-cache path: `output/US/S12A_OBSERVATION_PAYLOAD_IMPORT/raw_cache/2026-06-12`.

## Required series availability

- Targets numerically ready: 25
- Targets with missing or incomplete inputs: 0
- Ready targets: CFC_CC_NFC_ME_INPUT, CFC_CC_NFC_NRC_INPUT, I_NOM_NFC_ME_DIRECT, I_NOM_NFC_NRC_DIRECT, K_NET_CC_NFC_ME_VALIDATION, K_NET_CC_NFC_NRC_VALIDATION, omega_CORP, omega_NFC, P_Y_NFC_GVA_IMPLICIT_SOURCE, P_Y_NFC_GVA_T115_VALIDATION, P_Y_PROXY_BUSINESS_OUTPUT, P_Y_PROXY_GDP_IMPLICIT, P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE, P_Y_PROXY_GDPBYIND_VA_MANUFACTURING, P_Y_PROXY_NONFARM_BUSINESS_OUTPUT, P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS, Q_K_BEAFIXEDASSETS_ME_VALIDATION, Q_K_BEAFIXEDASSETS_NRC_VALIDATION, Y_REAL_NFC_GVA_BASELINE, Y_REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT, Y_REAL_NFC_GVA_PROXY_GDP_IMPLICIT, Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_FINANCE_INSURANCE, Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_MANUFACTURING, Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT, Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS

## Price proxy observation status

| target_variable | ready_for_construction | n_observations |
|---|---|---|
| P_Y_NFC_GVA_IMPLICIT_SOURCE | TRUE |  97 |
| P_Y_NFC_GVA_T115_VALIDATION | TRUE |  97 |
| P_Y_PROXY_GDP_IMPLICIT | TRUE |  96 |
| P_Y_PROXY_NONFARM_BUSINESS_OUTPUT | TRUE |  97 |
| P_Y_PROXY_BUSINESS_OUTPUT | TRUE | 317 |
| P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS | TRUE | 317 |
| P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE | TRUE |  29 |
| P_Y_PROXY_GDPBYIND_VA_MANUFACTURING | TRUE |  29 |

All eight locked price objects now have exact observation payloads. The NFC implicit GVA deflator is marked source-level derived and not-final; T1.15 line 1 remains validation-only. Macro, business, BLS, and industry objects retain their transparent robustness names.

## Source observations imported

Imported provider observations cover nominal NFC/CORP GVA and compensation, direct NFC ME/NRC investment, validation current-cost stocks, diagnostic depreciation, and NFC FAAt402 quantity indexes. Original IDs, tables, lines, series codes, units, frequency, roles, and source files are preserved.

## Missing observations

None. Every registered admissible target has its required payload.

## Validation results

| validation_rule | result | observed |
|---|---|---|
| No prohibited target variable imported as construction-ready | PASS |  |
| No blocked Shaikh-adjusted object imported as formula-admissible | PASS | No Shaikh-adjusted target imported |
| No CORP/FC real or price residual constructed | PASS | No residual target imported |
| No proxy relabeled as CORP/FC GVA deflator | PASS | Transparent proxy names preserved |
| No FAAt402 baseline use | PASS | FAAt402 observations route only to validation targets |
| No implied investment baseline use | PASS | Only direct FAAt407 investment imported |
| No GPIM stock constructed | PASS | No GPIM target observations created |
| No S20/S21/S22 executed | PASS | S12A script only |
| All imported provider observations preserve source provenance | PASS | 1333 provider observation rows |
| All observation payloads have year/time_period and numeric value fields | PASS | 2412 total imported observation rows |
| Units and frequencies are recorded | PASS | All imported rows contain unit and frequency metadata |
| Derived NFC implicit GVA deflator matches T1.15 line 1 within published rounding | PASS | 97 matched years; maximum absolute difference 0.0490755 |
| Upstream staged route and downstream external copy reconcile | PASS | Observation, provenance, and manifest files are byte-identical |
| Live API fetches are limited to exact locked tables and shortlisted IDs | PASS | Dated cache files: 6; live fetch in this run: FALSE |

## Next construction step

If S12A validates the required observation payloads, the next step is S12B: construct source-level output price objects, validation objects, and robustness deflator series. S12B still must not construct GPIM stocks, adjusted distribution variables, or econometric datasets.
