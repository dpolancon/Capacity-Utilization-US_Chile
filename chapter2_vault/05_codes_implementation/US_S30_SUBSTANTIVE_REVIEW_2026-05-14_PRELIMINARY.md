---
type: implementation_review_memo
status: superseded
layer: code_stage_design
design_role: us_s30_preliminary_substantive_review
scope: chapter2_results_repo
country: US
stage: S30
repo: Capacity-Utilization-US_Chile
review_date: 2026-05-14
superseded_by:
  - R_distribution_conditioned_theta_identification
  - C04-US_S30_STABILITY_PROTOCOL
  - US_S40_Restricted_B1_Reconstruction_Contract
  - US_S40_Review_and_Figures_Contract
supersession_reason: formal_s30_gate_opened_restricted_b1_under_fragility
active_contract: false
historical_trace: true
s40_blocked_conclusion_active: false
s40_current_status: blocked_pending_corrected_s30_s32_review
dols_veto_active: false
dols_fragility_metadata_only: true
s30_anchor_authority: false
s40_anchor_governed_by: D03_capacity_utilization_level_anchor_pinch_year_protocol
us_s40_preferred_anchor_year: 1973
us_s40_anchor_condition: mu_US_1973_equals_1
created: 2026-05-14
updated: 2026-06-08
related_to:
  - C04-US_S30_STABILITY_PROTOCOL
  - D03_capacity_utilization_level_anchor_pinch_year_protocol
  - R09_structural_break_protocol
  - M10_Empirical_Identification_Framework
---

# US S30 Substantive Review — Preliminary Memo

## Supersession notice

This memo is preserved as a historical trace of the preliminary S30 substantive review.

It is no longer an active implementation contract.

The later restricted B1 pathway was itself superseded on June 8, 2026 by [[R_distribution_conditioned_theta_identification]]. S40 is now blocked pending corrected S30/S32 review.

The active implementation rules are now governed by:

- `C04-US_S30_STABILITY_PROTOCOL.md`
- `US S40 Restricted B1 Reconstruction Contract.md`
- `US S40 Review and Figures Contract.md`
- `D03_capacity_utilization_level_anchor_pinch_year_protocol.md`

Historical B1 status recorded by this memo:

- B1 was the restricted S40 pathway.
- S40 proceeded only under fragility discipline.
- DOLS is fragility metadata only.
- DOLS does not veto Tier 1.
- DOLS is not a reconstruction basis.
- S30 does not choose the utilization level anchor.
- The preferred U.S. S40 anchor is:

$$
\mu_{US,1973}=1
$$

The historical content below does not authorize the current benchmark or S40.

It remains useful only as a record of the earlier pre-formal-gate interpretation.

---

## Historical memo begins below

**Proposed repo path:** `artifacts/repo_state_logs/us_s30_transformation_relation/US_S30_SUBSTANTIVE_REVIEW_2026-05-14.md`  
**Status:** preliminary substantive review based on the carry-over contract and known S30 classification summary. Coefficient-level confirmation still requires local inspection of the S30 CSVs and report files.

## 1. Historical decision

S40 should remain blocked as the default productive-capacity reconstruction pathway.

The correct next path is a formal-stability path, with a bounded mechanism-evidence interpretation of C1 and a restricted-candidate status for B1. B1 can remain the leading specification for review, but it should not be promoted to S40 on the current evidence. The decisive reason is simple: S30 produced zero core candidates under the declared stability discipline, and the current stability screen is explicitly a proxy diagnostic rather than a formal parameter-instability test.

A conservative B1 route can be kept alive only as a labelled candidate-under-review, not as a promoted productive-capacity benchmark. If used later, it should be introduced as a restricted sensitivity reconstruction after a formal stability check or after an explicit methodological override is documented.

Historical-status clarification:

This conclusion is superseded as an active implementation rule. It remains part of the historical record because it correctly identified the need for a formal S30 adjudication step before any S40 reconstruction. The later formal gate resolved that bounded question by opening restricted B1 under fragility discipline.

---

## 2. Answers to the seven review questions

### 1. Is B1 defensible as a conservative restricted S40 candidate despite fragility?

Not yet as an S40 candidate. Yes as the leading restricted object for further review.

B1 is attractive because it avoids the severe collinearity that damages fuller composition specifications and because it carries the wage-share/distributional channel directly. That gives it theoretical discipline and practical cleanliness. But its current classification remains fragile, and the pipeline rule forbids promotion by coefficient appeal. Therefore B1 should be labelled:

> Leading restricted candidate under review; not yet S40-promoted.

This keeps the door open without violating the S30 gate.

Historical-status clarification:

This statement has been superseded by the later C04/S40 contracts. B1 is now the restricted S40 pathway under fragility discipline, not a clean benchmark promotion.

### 2. Does C1 provide mechanism evidence without being used for S40?

Yes. C1 should be reported as mechanism evidence, not as a reconstruction engine.

C1 tests whether the ME–NRC stock-composition proxy adds information to the transformation relation. Since the proxy is Tier-B and not a direct NFCorp asset-composition split, it can support a mechanism reading only with careful language. The correct language is:

> C1 indicates that composition is empirically relevant to the transformation relation, but the evidence is not stable enough to define the productive-capacity reconstruction specification.

That is useful and dissertation-facing: composition matters, but the available proxy cannot carry the core S40 object.

This remains active as a historical interpretation constraint: C1 is mechanism evidence only and is not a reconstruction basis.

### 3. Is C2 formally demoted to diagnostic-only in the next pass?

Yes. C2 should be demoted from core eligibility.

The full composition interaction is repeatedly damaged by severe collinearity. That is not a minor nuisance; it means the model is asking the available data to distinguish too many closely related channels at once. C2 should remain in the S30 archive as a stress diagnostic showing the limits of the Tier-B composition bridge.

Recommended label:

> SPEC_C2_FULL_COMPOSITION = diagnostic-only; excluded from core promotion gates because of severe collinearity.

This remains active as a historical interpretation constraint: C2 is diagnostic-only.

### 4. Are DOLS failures mainly sample-size stress rather than substantive contradiction?

Provisionally, yes.

The carry-over record says DOLS ran, but some window/specification cells were rejected after lead/lag construction reduced the effective sample. That is a DOLS stress pattern, not automatically a substantive contradiction. The memo should distinguish:

- failure because the cell becomes too short after DOLS lead/lag construction;
- failure because surviving DOLS estimates contradict FM-OLS and IM-OLS;
- failure because DOLS survives but sharply widens uncertainty.

Only the second case would be a substantive contradiction. The known record currently supports the first interpretation.

Historical-status clarification:

This paragraph is superseded by the later R09/C04 rule for implementation purposes. DOLS contradictions are now recorded as fragility metadata. DOLS does not veto Tier 1 and does not define the reconstruction basis.

### 5. Are rolling FM-OLS paths structured enough for historical interpretation?

They can be used as historical diagnostics, not as regime identifiers.

The locked S30 rule already decides the key issue: rolling and recursive estimates do not identify regimes. They can help narrate where instability becomes visible, especially if movements cluster around historically meaningful windows, but they cannot define the window choice and cannot promote a specification.

Recommended language:

> Rolling FM-OLS paths are admissible as instability diagnostics and historical illustrations. They are not admissible as regime-selection devices.

This remains active as a guardrail.

### 6. Is a formal Hansen/Gregory-Hansen stability module needed before S40?

Yes, if S40 is meant to produce a defensible US benchmark rather than an explicitly exploratory sensitivity reconstruction.

The present S30 screen is a proxy-stability diagnostic. That is useful, but it does not settle parameter stability of the cointegrating vector. A bounded formal module is warranted before S40 if the chapter wants to avoid both arbitrary split-window selection and overclaiming from fragile super-consistent estimates.

Recommended implementation scope:

1. Hansen-type parameter-instability tests for the cointegrating regression where feasible.
2. Gregory-Hansen-style residual-based cointegration tests with one unknown regime shift as a stress check, not as a new regime-mining exercise.
3. A small decision table: stable, unstable-with-known-window-support, unstable-without-promotable-candidate.

This module should not expand the estimator grid. It should adjudicate whether B1 can be promoted or whether the US benchmark must stop at S30.

Historical-status clarification:

This recommendation was implemented downstream through the C04 formal S30 stability protocol and the S40 restricted B1 reconstruction contract.

### 7. Should the paper report “no stable S30 core candidate” as a substantive result?

Yes. This is a result, not a failure.

The paper should report that under the declared historical-window, estimator-triangulation, and proxy-stability discipline, no US S30 specification qualifies as a stable core candidate. That finding matters because it prevents the chapter from manufacturing a productive-capacity path from a convenient coefficient. It also clarifies the empirical status of the composition mechanism: theoretically important and empirically suggestive, but not yet stable enough to carry S40.

Historical-status clarification:

This remains useful as context, but the active implementation result is narrower: no clean unrestricted benchmark is promoted; restricted B1 opens under fragility discipline.

---

## 3. Specification disposition table

| Specification | Review disposition | S40 status in preliminary memo | Current active status | Reporting role |
|---|---|---|---|---|
| B0 capital only | Supporting benchmark | Not eligible as core | Not S40 eligible | Baseline reference only |
| B1 wage baseline | Leading restricted candidate under review | Blocked pending formal stability check | Restricted S40 pathway under fragility | Main restricted reconstruction candidate |
| C1 composition stock | Mechanism-informative but unstable | Not eligible | Mechanism evidence only | Report as mechanism evidence |
| C2 full composition | Diagnostic-only | Demoted from core eligibility | Diagnostic-only | Stress test / collinearity evidence |
| D1/D2 valuation and price diagnostics | Diagnostic-only | Not eligible | Diagnostic-only | Current-cost and relative-price checks |

---

## 4. Historical memo-level conclusion

The original recommended decision was:

> S40 remains blocked for the US benchmark. B1 is retained as the leading restricted candidate for formal stability adjudication. C1 is reported as mechanism evidence but excluded from reconstruction. C2 is demoted to diagnostic-only. The paper should report no stable S30 core candidate as a substantive result under the declared discipline.

This was the cleanest path at the time because it preserved the anti-arbitrariness rule, avoided promotion by coefficient appeal, and still extracted the substantive lesson from S30: the transformation relation is estimable, but not yet stable enough to reconstruct productive capacity for the US benchmark without an additional stability gate.

Current active conclusion:

> The preliminary blocked-S40 conclusion is superseded. The later formal S30 gate opened a restricted B1 S40 pathway under fragility discipline. S40 is not a clean benchmark promotion. It is a restricted reconstruction path governed by C04, the S40 reconstruction contract, the S40 review contract, R09, and D03.

---

## 5. Historical recommended next bounded patch

Original recommendation:

No S40 code.

The next bounded patch should create a formal S30 stability adjudication module and a one-page decision table. The patch should not touch Chile scripts, profitability analysis, S40 reconstruction, or the broader repo curation surface.

Suggested next label:

`US_S30_FORMAL_STABILITY_ADJUDICATION_2026-05-14`

Current active status:

This recommendation has been superseded by completed downstream implementation governance:

- C04 formalized the S30 gate.
- The S40 restricted B1 reconstruction contract opened the restricted reconstruction lane.
- The S40 review and figures contract governs diagnostics and visualization.
- D03 governs the U.S. utilization level anchor.
