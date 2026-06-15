# S15 Inner Vault Lock Audit

## Audit Scope

S15 inspected all 116 Markdown files under `chapter2_vault/`. The conceptual audit excluded `.obsidian` internals; `.obsidian/workspace.json` was observed only as pre-existing workspace noise. No existing vault note was edited.

The audit used the pushed repository state at commit `133f5aa` as the current boundary. S13 consumed the locked GPIM baseline, and S14 registered 884 finite observations across exactly eight variables with 13/13 validation checks passing. The governing S14 decision is `AUTHORIZE_S20_MODEL_INPUT_LAYER`.

## Current Repo Boundary

S20 planning begins from the S14 consolidation layer, not from provider files, S12D construction artifacts, or a new GPIM pass. The authorized GPIM registry is:

| variable_id | role |
|---|---|
| `I_NOMINAL_DIRECT_ME` | canonical nominal ME investment |
| `I_NOMINAL_DIRECT_NRC` | canonical nominal NRC investment |
| `P_K_SFC_ME_2017_100` | SFC implicit ME capital-price index |
| `P_K_SFC_NRC_2017_100` | SFC implicit NRC capital-price index |
| `I_REAL_GPIM_ME` | baseline real ME investment |
| `I_REAL_GPIM_NRC` | baseline real NRC investment |
| `K_GROSS_GPIM_ME` | baseline gross ME GPIM stock |
| `K_GROSS_GPIM_NRC` | baseline gross NRC GPIM stock |

The boundary is closed around these objects. `FAAt402` remains validation-only; NFC output-price translation remains robustness-only historical context; the diagnostic net-value GPIM stock remains excluded; no productive-efficiency object exists; provider discovery and GPIM reconstruction remain closed.

## Locked Decisions

1. **Provider discovery is closed.** `V01_DataProvenance_Managment.md` records the provider pass as locked and S11B/S11C as closed. S14 now supersedes its future-tense construction language: S20 must consume the S14 panel and must not return to provider discovery.

2. **GPIM reconstruction is closed.** S13 and S14 establish the downstream source panel and architecture registration. D01 remains useful as the conceptual stock-flow and valuation-register protocol, but it is no longer an instruction to reconstruct the baseline.

3. **The active capital-price objects are the two SFC implicit indexes.** The S14 registry admits `P_K_SFC_ME_2017_100` and `P_K_SFC_NRC_2017_100`; `FAAt402` cannot replace them.

4. **The S13 and S14 gates are locked.** S13 authorized downstream GPIM consumption, and S14 authorized the S20 model-input layer. The eight-variable allowlist is exact.

5. **Gross real and net monetary registers remain distinct.** D01 correctly assigns gross real GPIM stock to capacity analysis and net current-cost capital to profitability or valuation analysis. The diagnostic net-value GPIM stock is not an S20 baseline input.

6. **The Shaikh adjustment remains blocked.** V00 and V01 preserve unadjusted wage share as the first-pass distribution state and prohibit adjusted objects until a current-release semantic and accounting crosswalk passes.

7. **IPP and government transport are not baseline productive capital.** The binding identification note permits them only as conditioners, diagnostics, or robustness objects unless a later protocol explicitly changes their role.

8. **Centering uses a constant reference.** Rolling-window centering is diagnostic only. Any S20 export must record the reference value, sample, distribution measure, asset boundary, and transformation rule.

9. **Econometric stages remain closed.** S20 may build and validate model inputs. It cannot reopen S30I, S30, or S32, and it cannot construct productive capacity or utilization.

10. **Accumulated `q` is parked under the binding method notes.** `R_distribution_conditioned_theta_identification`, M10, R10, R11, A05, and D04 all subordinate accumulated historical-memory operators to the primitive centered interaction and open composition fork.

## Pending Decisions

### S20

1. **Capital output shape:** decide whether S20 exports aggregate productive capital, separate ME and NRC stocks, or both. The strongest design is to preserve both components and assign the aggregate, if constructed, an explicit derived role rather than treating additivity as already settled.

2. **Scale versus composition:** decide whether the baseline model-input object is aggregate capital scale, whether the ME/NRC log ratio is a competing composition input, and whether both enter the S20 registry with separate analytical roles.

3. **Distribution attachment:** identify the exact distribution series, sector boundary, unit, coverage, and join rule that attaches to the S14 GPIM capital baseline.

4. **Wage share and profit share:** the vault currently prefers unadjusted wage share and treats profit share as reconciliation or alternative evidence. S20 must confirm this operationally because S14 contains no distribution variable.

5. **Shaikh reopening:** keep the adjustment blocked in S20. A later reopening requires a completed current-release crosswalk and cannot silently overwrite the unadjusted baseline.

6. **Frontier conditioners:** decide whether S20 only registers future IPP and government-transport roles or constructs separate control inputs from an independently authorized source lane. Neither can become productive capital or productive efficiency by implication.

7. **Stage gate:** define the exact S20 completion and validation decision that would permit later S21 or integration-order work. No direct jump to S30I, S30, or S32 is admissible.

### S21

1. **Whether S21 opens at all:** the binding vault rule parks accumulated `q`. A new S21 layer therefore requires an explicit reopening decision; it is not already authorized by S14.

2. **Capital basis:** if reopened, accumulated `q` must use the S14 GPIM baseline and the S20-approved aggregate or component capital object.

3. **Reset logic:** define whether accumulation starts with the full available history, resets at an estimation-window boundary, or carries a pre-window state into each window.

4. **Centering:** preserve constant-reference centering as baseline. A rolling-window mean may be used only as a labelled diagnostic or robustness state.

5. **Missing years and coverage asymmetry:** ME stocks begin in 1925 and NRC stocks in 1931, while investment begins in 1901. S21 must define initialization and common-support rules before constructing any cumulative object.

## Stale Or Contradictory Notes

| Note | Finding | Verdict |
|---|---|---|
| `04_data_measurement/V01_DataProvenance_Managment.md` | Closure stops at S11B/S11C; it still orders gross and net GPIM construction, an additive `K_cap`, and preferred accumulated `q`. | Mandatory post-S14 amendment before S20. |
| `04_data_measurement/V00_VariableMenu_US_BEA_Repo.md` | The active-looking menu lists net GPIM, implied depreciation, frontier stocks, aggregate capital, and accumulated `q` beyond the eight-variable S14 registry. It also sends the next pass back to S30I-driven data discovery. | Mandatory S14 status block and current-lock rewrite. |
| `04_data_measurement/D01_GPIM_heterogeneous_capital_SFC.md` | The conceptual register distinction remains valid, but active sections still instruct future GPIM reconstruction and accumulated-`q` exports. | Mandatory status amendment; retain conceptual content. |
| `04_data_measurement/D02_PriceDeflator_Protocol_K_Composition.md` | It correctly separates ME/NRC prices but still calls accumulated `q` the A00 baseline. | Mandatory correction before S20 uses it. |
| `05_codes_implementation/S10_US_Source-of-Truth_GPIM_ConstructionProtocol.md` | The note is marked locked yet describes planned paths and requires promoted Shaikh-corrected layers while the current-release adjustment is blocked. | Mandatory supersession notice and S14 handoff replacement. |
| `05_codes_implementation/S10_US_Source-of-Truth_GPIM_ConstructionProtocol 1.md` | The duplicate is labelled historical but contains extensive authoritative-sounding Weibull, sector-pair, accumulated-`q`, and stage instructions. | Park or archive; remove from active planning links. |
| `05_codes_implementation/C01-US_00_MEMO_RECYCLING.md` | It says the U.S. side lacks a source-of-truth builder and proposes a new S10 script. S14 has closed that gap. | Mandatory replacement of the S10-gap section. |
| `04_data_measurement/D04_ME_NRC_LogRatio_Construction_Protocol.md` | Its construction-to-S31/S30/S32 sequence bypasses the new S14-to-S20 gate and does not resolve whether S21 remains parked. | Mandatory sequencing amendment before S20. |
| `06_paper_facing/Chapter2_Polanco.pdf.md` | The paper-facing backend remains generic and does not identify the locked SFC prices, eight-variable registry, or post-S14 exclusions. | Park until S20 settles aggregate/split and distribution attachment. |

No vault note mentions S12D, S13, S14, S21, the S14 decision, or any of the eight registered S14 variable identifiers. This absence is the central documentation lag.

## Recommended Patch Plan

| Priority | Note | Required update | Timing |
|---|---|---|---|
| 1 | `V01_DataProvenance_Managment.md` | Add an S13/S14 closure amendment; replace future GPIM construction with the eight-variable S14 registry and explicit exclusions. | Mandatory before S20 |
| 2 | `V00_VariableMenu_US_BEA_Repo.md` | Add completed/parked/excluded status columns; remove S30I-driven provider reopening; rewrite the current lock around the primitive interaction and open composition fork. | Mandatory before S20 |
| 3 | Non-suffixed S10 protocol | Mark the old S10 architecture superseded by S13/S14; point to actual S14 paths; keep Shaikh-adjusted layers blocked. | Mandatory before S20 |
| 4 | `C01-US_00_MEMO_RECYCLING.md` | Replace the missing-S10-builder section with the S14 handoff and bounded S20 decisions. | Mandatory before S20 |
| 5 | D01 and D02 | Preserve conceptual stock-flow and price logic, but change construction tense to locked-input consumption and remove accumulated-`q` baseline claims. | Mandatory before S20 |
| 6 | D04 | Insert `S14 -> S20 -> optional S21 -> later diagnostics/estimation`; keep composition variables bounded and non-econometric at S20. | Mandatory before S20 |
| 7 | Duplicate S10 protocol | Retain only as archival history or move it out of active links. | Can be parked |
| 8 | Paper-facing note | Add the final S20-approved capital and distribution architecture after those decisions are made. | Can be parked |

The S20 planning note itself should not patch these notes indirectly. It should name the conflicts, consume only S14 GPIM inputs, resolve the pending architecture questions, and issue a separate implementation authorization.

## Validation Checks

| check_id | status | evidence |
|---|---|---|
| VAULT_MARKDOWN_INSPECTED | PASS | 116 Markdown files inventoried and searched. |
| OBSIDIAN_INTERNALS_EXCLUDED | PASS | `.obsidian` contained no Markdown and was excluded from conceptual findings. |
| EXISTING_VAULT_NOTES_UNMODIFIED | PASS | S15 creates only a new report and ledger outside `chapter2_vault/`. |
| NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED | PASS | Audit inputs were vault Markdown and repository status only. |
| NO_GPIM_RECONSTRUCTION | PASS | No data-construction script or GPIM calculation ran. |
| NO_DOWNSTREAM_SCRIPTS_INVOKED | PASS | S20, S21, S22, S30I, S30, and S32 scripts were not invoked. |
| AUDIT_REPORT_CREATED | PASS | S15 Markdown report and CSV ledger were created. |
| FINAL_DECISION_EXPLICIT | PASS | Decision is stated below. |

## Final Decision

**AUTHORIZE_S20_PLANNING_NOTE**

S14 supplies a valid, locked GPIM architecture for planning. Authorization is limited to an S20 planning note: implementation remains contingent on resolving aggregate versus asset-split capital, distribution attachment, frontier-conditioner roles, and the explicit gate governing any later S21 or econometric stage.
