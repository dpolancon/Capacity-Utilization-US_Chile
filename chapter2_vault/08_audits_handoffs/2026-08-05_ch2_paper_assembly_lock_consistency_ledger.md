---
type: audit
status: active
depends_on:
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - chapter2_vault/03_econometrics/E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock.md
  - chapter2_vault/03_econometrics/E17_Cointegration_Significance_Stars_Lock.md
stage_scope: paper-facing
country: US_CL
last_updated: 2026-08-05
updated_by: CH2_PAPER_ASSEMBLY_LOCK_RECONCILIATION
layer: audit
role: lock-consistency-ledger
stage: paper-assembly
tags:
  - chapter2/audit
  - chapter2/governance
scope: chapter2
priority: core
---

# Lock-Consistency Ledger — Chapter 2 Paper Assembly, 2026-08-05

The governance layer was not rewritten in advance of this assembly pass. Assembling the
manuscript was treated as the diagnostic: what the assembled draft actually does is the
evidence against which each lock was checked. This ledger records, per lock, what the lock
says, what the draft does, and whether the gap is a draft defect or a stale lock.

Locks that turned out to be consistent are recorded as such. That is half the point of the
exercise — knowing what needed nothing is as useful as knowing what needed fixing.

---

## 1. Consistent — no action taken

| Lock | Checked against | Verdict |
|---|---|---|
| `00N_Chapter2_PaperFacing_MAP.md` (6-section structure) | Generated `main.pdf` outline | **Consistent.** Six numbered sections, titles matching the locked burdens. The drafts, `compile_chapter2.py`, and `main.tex` all already followed this map. |
| `00E_Chapter2_PaperFacing_Constitution.md` (analytical sequence) | §3 and §4 argument order | **Consistent.** The chain $\omega \rightarrow \theta \rightarrow \hat{Y}^p \rightarrow \hat{\mu}$ is what the draft does: the transformation elasticity is identified first, capacity is constructed from it, and the level anchor is applied afterwards. |
| `00S` notation (κ replaces τ, δ reserved for depreciation) | Full text grep of generated sections | **Consistent in prose.** No stray $\tau_t$; $\delta$ appears only as depreciation or as the threshold-state penalty $\hat{\delta}_{\omega\kappa}$, which is a coefficient name rather than a step dummy. One artifact *filename* still carries `tau` (`output/figures/us_tau_regime_bands.png`); the caption is correct and the mismatch is flagged in §4.1. |
| `E18_Parameter_Stability_Audit_Protocol_Lock.md` | Appendix E | **Consistent.** The lock's content transposed into Appendix E without amendment. The lock is well-formed; it simply had no paper-facing surface until now. |
| AGENTS.md table/figure formatting (`[H]` floats, `\FloatBarrier`, top captions, bottom notes, explicit `p{}` widths) | The 18 generated `_CORE`/`_TRIAD` fragments | **Consistent.** Inherited from the source fragments and preserved by the split. |
| AGENTS.md paragraph lettering | Generated sections | **Now consistent.** Was violated by the transpiler, not by the locks — see §3. |

---

## 2. Stale locks — amended

### 2.1 `AGENTS.md` — the WLM v4.0 voice mandate

**What the lock said:** "All prose must conform to WLM v4.0", with a `Voice: WLM v4.0`
sign-off.

**What the evidence shows:** no such file exists. Searched `chapter2_vault/` — including
`07_WrittingSkills_and_Rules/`, which the reorganization handoff describes as containing
"WLM v4.0 prose style" — and the sibling `academic-research-skills` repository. Only git
pack objects match. The folder holds exactly two files, one of which (`C04_Model_Selection_Strategy.md`)
is a model/token-budget note misfiled among writing rules.

**Verdict: stale lock.** A binding mandate pointing at nothing binds nothing. Amended to
`umass-applied-econometrics` in its political-economy variant, with `econ-write` for
mechanics only and `C02_Advisor_Michael_Facing_Exposition_Prompt.md` scoped to advisor and
slide material as that file itself already states.

### 2.2 `00E` vocabulary versus `C02` prohibitions

**The apparent conflict:** `00E` makes "structurally reconstructed object" the chapter's
central claim; `C02` bans "reconstructed object", "structural object", and "recovery"
outright.

**Verdict: not a conflict once the scope of `00E` is stated correctly.** `00E` binds as
*procedure*, not as *lexicon*. What is constitutional is the sequence — that $\mu$ is not a
residual, that $\theta$ is identified first, that distribution mediates $\theta$, that the
pinch-year anchors the level without defining the object. The particular phrasing is not.
Recorded as a new line in `AGENTS.md` so the question does not have to be re-litigated.

### 2.3 `E15` §4 and `E17` — the triad reporting rule

**What the locks said:** all paper-facing tables report the three-test triad; `E17` requires
the star-reversal warning in every such table's footnote.

**What the evidence shows:** the locks were internally inconsistent before this pass. `E15`
already designated the Vogelsang-Wagner Type 2 test "PRIMARY & BINDING" and demoted ADF and
Shin to "SECONDARY ROBUSTNESS CHECKS", yet §4 mandated presenting all three co-equally. The
tables in turn contradicted their own footnotes: every footnote promised Monte-Carlo-derived
VW stars, and no VW cell in any table carried one. The prose then led with ADF, inverting
`E15`'s own hierarchy.

**Verdict: stale locks, amended in the direction `E15` already pointed.** Core tables now
report the VW row alone, directly beneath the parameter estimates; ADF and Shin move to
Appendix D, which is now the only place the star-reversal warning is needed. The verdict is
assigned on VW alone. Both locks advanced with `updated_by: VW_PROMOTION_TO_CORE`.

### 2.4 Broken paths across the governance layer

Each verified against disk before amendment:

| Declared | Actual |
|---|---|
| `chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md` — in `00E`, `00N`, `00S`, `E15`, `AGENTS.md` | `chapter2_vault/06_paper_facing/others/Ch2_Outline_DEFINITIVE.md` |
| `02_analytical_foundations/A04_Peripheral_Transformation_Elasticity.md` — in `00S` | `02_analyitical_foundation/A04_PeripheralTransformationElasticity.md` (misspelled directory *and* different filename) |
| `chapter2_vault/08_audits/...` — in `E17`, `E18` | `chapter2_vault/08_audits_handoffs/...` |
| `chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md` — in `AGENTS.md`, named as an authority file and as the target of the stage gate | `chapter2_vault/05_codes_implementation/99_legacy/C03-REPO_STRUCTURE.md` |

The last of these is not merely a path error. An **authority file was archived into
`99_legacy/` while `AGENTS.md` continued to name it authoritative** and to route the stage
gate through it. The reference now points at the real location so nothing is silently
dangling, but whether a file in `99_legacy/` should still govern stage transitions is a
question the archiving decision did not answer. Flagged for adjudication.

---

## 3. Draft defects, not lock defects — fixed in the draft

| Defect | Where | Nature |
|---|---|---|
| Every transpiled table given the same caption and `\label` | `compile_chapter2.py:153-154` | Transpiler bug. The locks were right; the tool ignored them. |
| `\paragraph{}` argument swallowing whole paragraphs and a display equation | `compile_chapter2.py` heading branches | Transpiler bug. Produced headings that violated the lettering lock. |
| `###` headings emitted as `\paragraph{A. The Fordist Era...}` | Transpiler, `shift_headers` path | Violated the lettering lock two ways at once: occupied a letter slot and repeated a manual letter. Now a bold run-in under a properly lettered paragraph. |
| Significance stars eaten into `\textit{}` | `compile_chapter2.py:88` bold/italic regexes | Transpiler bug. `0.58***` was read as an emphasis span. |
| Appendix `\section` stripped, subsubsections orphaned under §6 | `compile_chapter2.py:410` | Transpiler bug. |
| Hardcoded `11.45` cited while the section calls itself "Corrected" | `ch2_sec4_2_2.md` §D | Draft defect against a correct lock. `E17` had already condemned this triple; the draft had not caught up. Now withdrawn and flagged rather than silently re-based. |
| Shin $k=3$ 10% value (`0.121`) cited as a 5% value | `ch2_sec4_2_2.md` §D | Draft defect. Both the level and the $k$-index were misattributed; `E17` records $k=2$ throughout Specification A, where the 5% value is `0.221`. |
| Hand-copied Chile table diverging from its binding source | `ch2_sec4_4_peripheral_econometrics_prelatex.md` | Draft defect, and the clearest argument for the wiring change: the transcription reported a different standard error and three stars where the source has one. |

---

## 4. Unresolved — recorded, not closed

- **`E18` numbering collision.** `E18_Parameter_Stability_Audit_Protocol_Lock.md` and
  `E18_Kappa_Path_Derivative_LOESS_Lock.md` share a number. Both are active and substantive.
  Renumbering touches every inbound reference, so it is left for a deliberate pass.
- **Two parallel audit directories**, `08_audit_handoffs/` and `08_audits_handoffs/`.
  Consolidation deferred for the same reason.
- **The FWL question.** `Ch2_Outline_DEFINITIVE.md` ¶4.2.1 forbids pre-estimation FWL
  orthogonalization on the ground that partial summation does not commute with projection
  ($S M_X \neq M_{SX} S$), altering the Brownian limit functional. The draft §4.3 runs an
  explicit FWL orthogonalization protocol, and all nine binding table fragments state FWL
  orthogonalization in their footnotes. Since `Ch2_Outline_DEFINITIVE.md` is superseded as a
  structural authority, its ¶4.2.1 no longer binds *as outline* — but the econometric
  objection it raises is independent of its status as an outline and is not answered anywhere
  in the vault. **This is the most consequential open item in the governance layer**: if the
  objection holds, it affects every estimate in the chapter, not the presentation of them.
  It needs adjudication on econometric grounds by someone who can settle whether the
  orthogonalization as implemented occurs before or after partial summation.
- **VW critical values.** Out of scope for this pass by decision; flagged in the manuscript
  itself rather than silently omitted.
