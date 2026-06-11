---
type: implementation_memo
status: superseded_pending_corrected_s30
layer: code_stage_design
design_role: us_s30_formal_stability_protocol
scope: chapter2_results_repo
country: US
stage: S30
repo: Capacity-Utilization-US_Chile
s30_anchor_authority: false
s40_anchor_governed_by: D03_capacity_utilization_level_anchor_pinch_year_protocol
us_s40_preferred_anchor_year: 1973
us_s40_anchor_condition: mu_US_1973_equals_1
us_s40_anchor_type: point_year_external_pinch
us_s40_anchor_source: FRB_maximum_utilization_series
window_average_anchor_allowed_as_baseline: false
created: 2026-05-14
updated: 2026-06-08
related_to:
  - US_S30_SUBSTANTIVE_REVIEW_2026-05-14_PRELIMINARY
  - R09_structural_break_protocol
  - M10_Empirical_Identification_Framework
  - N02_SuperConsistency
  - D03_capacity_utilization_level_anchor_pinch_year_protocol
  - D02_PriceDeflator_Protocol_K_Composition
---

# C04 - US S30 Stability Protocol

> [!important] Current identification lock
> S30 stability applies to the primitive centered scale interaction and the centered composition competitor. `omega_k_t` without the direct distribution control and accumulated-index specifications are historical only.

> [!warning] Superseded method object
> This protocol remains as the historical adjudication record for `SPEC_B1_WAGE_BASELINE`. The B1 level interaction is no longer the active benchmark. A corrected S30 pass must estimate the centered primitive interaction and/or the composition-mediated specification governed by [[R_distribution_conditioned_theta_identification]]. Nothing in this note opens S40 for the current object.

## Parked / not current baseline

Accumulated $q_t^{\omega,h}$ indexes are parked historical-memory operators. They are not required variables for the current S30 baseline and cannot authorize S40 reconstruction.

## 0. Purpose

This memo defines the bounded coding protocol for the US S30 formal stability layer.

It does not authorize S40 code.

It does not reconstruct productive capacity.

It does not compute utilization.

It does not choose the utilization level anchor.

It does not expand the estimator grid.

It does not touch Chile.

The S30 task is to adjudicate whether the existing US S30 results contain a restricted B1 pathway that is admissible enough to open later S40 work under an explicit fragility discipline.

The cointegrating relation remains the primary empirical object.

Formal stability evidence supports the S30 adjudication rather than replacing the object-level assessment.

The relevant S30 adjudication script is:

`codes/US_S30_formal_stability_adjudication.R`

The script should consume the existing US S30 outputs and write additional S30 adjudication artifacts.

It should not overwrite the estimator grid as if the prior S30 pass had already promoted a candidate.

---

## 1. Anchor boundary rule

S30 adjudicates whether S40 may open.

S30 does not choose the utilization level anchor.

The S30 stability protocol decides whether a restricted B1 pathway is admissible for downstream reconstruction. It does not determine the level at which reconstructed utilization equals one.

That level anchor is governed by:

`D03_capacity_utilization_level_anchor_pinch_year_protocol`

For the United States, the preferred S40 baseline anchor is:

$$
\mu_{US,1973}=1
$$

This is a point-year full-capacity pinch anchor based on the FRB utilization-series calibration logic.

It is distinct from:

- the S30 coefficient-recovery window;
- the S30 benchmark window;
- the S30 stability gate;
- rolling or recursive stability diagnostics;
- DOLS fragility diagnostics.

The Fordist-core window may remain relevant for S30 estimation, stability comparison, or historical benchmarking.

It must not be promoted by S30 into a utilization-level normalization such as:

$$
\overline{\mu}_{1945-1973}=1
$$

That window-average normalization is diagnostic only unless separately declared as a robustness normalization.

Locked rule:

> S30 opens or blocks S40. D03 governs the S40 utilization level anchor.

---

## 2. Current S30 status

The existing S30 run produced no clean unrestricted benchmark candidate under the declared proxy-stability discipline.

The S30 evidence nevertheless identified a restricted B1 pathway that could be evaluated under a formal stability gate.

The stability evidence is useful but incomplete unless the formal S30 adjudication layer records whether Hansen-type stability evidence is exact, proxy-based, mixed, contradictory, or unavailable.

The existing stability layer should therefore be treated as a formal adjudication problem, not as a direct authorization of S40.

The target object remains:

$$
y_t \sim k_t + \omega^K_t
$$

for the restricted B1 pathway.

`omega_k_t` is the A00 baseline interaction variable (`omega_t k_t`), not a secondary extension.

The standardized implementation export is:

`omega_k_t = omega_t * k_t`

meaning:

$$
\omega_{k,t}=\omega_t k_t
$$

---

## 3. Specification disposition

The S30 code must use the following adjudicated disposition, regardless of the original `promotion_eligible` flags in the first-pass specification register.

| spec_id | Adjudicated role | S40 eligibility after this memo | Treatment in next code |
|---|---|---:|---|
| `SPEC_B0_CAPITAL_ONLY` | supporting benchmark | no | Keep as baseline reference only. It may be reported beside B1 to contextualize stability, but it cannot carry S40. |
| `SPEC_B1_WAGE_BASELINE` | leading restricted candidate under review | conditional | This is the only specification eligible for restricted S40 pathway adjudication. It is not promoted unless it passes the hierarchical gate below. |
| `SPEC_C1_COMPOSITION_STOCK` | mechanism evidence | no | Keep as diagnostic/mechanism evidence. It can show that the ME-NRC composition proxy matters, but it cannot define the reconstruction specification. |
| `SPEC_C2_FULL_COMPOSITION` | diagnostic-only | no | Demote from core eligibility because severe collinearity makes the full interaction structure non-promotable. |
| `SPEC_D1_CURRENT_COST_DIAGNOSTIC` | diagnostic-only | no | Keep only as valuation-composition diagnostic. |
| `SPEC_D2_PRICE_WEDGE_DIAGNOSTIC` | diagnostic-only | no | Keep only as relative-price wedge diagnostic. |

Operationally, the S30 adjudication output should include a fresh disposition table rather than silently editing the historical first-pass register.

The first-pass register records what was attempted.

The new table records what remains admissible after substantive review.

---

## 4. Candidate eligibility rule

Only `SPEC_B1_WAGE_BASELINE` remains eligible for restricted S40 pathway review.

Eligibility means only:

`eligible_for_restricted_s40_adjudication = TRUE`

It does not mean:

`promoted_to_S40 = TRUE`

B1 can move forward only as a restricted candidate if it passes the object-admissibility tier and receives supportive or mixed stability evidence using the existing S30 variable set, estimator roles, and historical-window register.

If the evidence is mixed, any later S40 output must carry a fragility flag.

If the evidence is contradictory or unavailable, the US benchmark stops at S30.

No composition-augmented specification should be promoted as a substitute if B1 fails.

C1 remains mechanism evidence.

C2 remains diagnostic-only.

D1 and D2 remain valuation and price-wedge diagnostics.

---

## 5. Estimator hierarchy

The S30 estimator hierarchy is:

- FM-OLS = main estimator;
- IM-OLS = robustness estimator;
- DOLS = fragility / stress diagnostic.

FM-OLS carries the main S30 object interpretation.

IM-OLS checks whether the FM-OLS result is robust to a different super-consistent estimator logic.

DOLS does not carry the reconstruction pathway.

DOLS does not veto S40 by itself.

DOLS contradictions must be recorded as fragility metadata, not as automatic Tier 1 failure.

The S30 adjudication output must therefore preserve:

- `dols_fragility_flag`
- `dols_veto = FALSE`
- `dols_reconstruction_basis = FALSE`
- `dols_contradiction_windows`
- a short explanation of the DOLS contradiction as stress evidence.

This implements the R09 rule: DOLS is a fragility diagnostic, not the estimator that defines admissibility.

---

## 6. Preferred stability diagnostics before S40

The S30 script should add the preferred formal stability diagnostic for the B1 cointegrating relation:

`y_t ~ k_t + omega_k_t`

Minimum required diagnostic checks:

1. Run a Hansen-type parameter-instability test, or the closest implementable equivalent, as preferred formal stability evidence for the B1 cointegrating regression.
2. Apply it to the existing S30 reference windows only; do not add new candidate windows.
3. Report whether the procedure is the exact Hansen test or an operational proxy.
4. Report test statistic, p-value if available, critical values if available, implementation package/function, and failure reason if the test cannot be computed.
5. Preserve the estimator-role hierarchy: FM-OLS main, IM-OLS robustness, DOLS fragility diagnostic.
6. Carry forward effective sample size, DOLS survival/failure, neighborhood reversals, collinearity flags, and rolling diagnostics from the existing S30 outputs.
7. Classify the stability evidence as `supportive`, `mixed`, `contradictory`, or `unavailable`.

Suggested evidence mapping:

| Formal result | Evidence class |
|---|---|
| No instability rejection at 10 percent | `supportive` |
| Rejection at 10 percent but not 5 percent | `mixed`; restricted S40 may open only with a fragility flag if Tier 1 also passes |
| Rejection at 5 percent or stronger | `contradictory`; S40 remains blocked |
| Test unavailable or effective sample inadequate | `unavailable`; S40 remains blocked |

The code should report 10, 5, and 1 percent results when the implementation provides them.

A preferred coefficient sign, magnitude, or significance level cannot override the hierarchical S40 gate.

---

## 7. Gregory-Hansen and Hansen-style break tests

Hansen-type parameter-instability testing is the preferred formal stability diagnostic because S30 is asking whether the cointegrating relation can be treated as sufficiently stable for restricted downstream use.

Gregory-Hansen style tests may be used only as a bounded supporting stress check.

Their role is to ask whether cointegration is recovered when one unknown regime shift is allowed.

They do not select the S40 window.

They do not create a regime model.

They do not convert the chapter into a structural-break econometrics paper.

Rules for the S30 code:

- Run the Hansen-type check for B1 as the preferred formal diagnostic supporting S30 adjudication.
- Run Gregory-Hansen for B1 only if the implementation stack can do so cleanly.
- If Gregory-Hansen is run, export the estimated break date and model variant as diagnostic evidence only.
- Do not use the Gregory-Hansen break date to redefine historical windows.
- Do not run Bai-Perron, Kejriwal-Perron, threshold-FGLS, or multiple-break searches in this step.
- Do not promote C1 or C2 because a break-adjusted test looks more favorable.
- Do not report rolling or recursive paths as regime identifiers.

Admissible interpretation:

> The one-break diagnostic suggests whether B1's cointegration evidence is sensitive to allowing a single unknown shift.

Inadmissible interpretation:

> The break test discovered the regime structure for S40.

---

## 8. Export artifacts required from the S30 adjudication script

The S30 adjudication script should write only US S30 artifacts under:

`C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/`

Required exports:

| Artifact | Required content |
|---|---|
| `us_s30_formal_spec_disposition.csv` | One row per existing S30 specification with adjudicated role, S40 eligibility, diagnostic-only flag, and exclusion reason. |
| `us_s30_hansen_stability_tests.csv` | B1 Hansen-type stability evidence by existing reference window, including exact/proxy flag, statistic, p-value or critical values, evidence class, package/function, and failure reason. |
| `us_s30_gregory_hansen_stress.csv` | B1 one-break cointegration stress results if implemented; otherwise a row recording `not_implemented` and the reason. |
| `us_s30_formal_stability_decision.csv` | Final hierarchical S30 gate table with Tier 1, Tier 2, and Tier 3 status; B1 restricted-pathway decision; fragility flag; and whether S40 remains blocked. |
| `US_S30_formal_stability_adjudication_report.md` | Short human-readable report summarizing disposition, formal tests, Gregory-Hansen treatment, and S40 gate result. |
| `us_s30_formal_stability_manifest.csv` | Run timestamp, input files, package availability, test implementations, unchanged estimator settings, explicit `no_s40_code = TRUE`, and explicit `s30_anchor_authority = FALSE`. |

Forbidden exports in this step:

- productive-capacity paths;
- `Yp` series;
- utilization or `mu` series;
- utilization anchors;
- profitability outputs;
- Chile outputs;
- new estimator-grid expansions;
- paper-facing tables presented as final chapter results.

---

## 9. S40 hierarchical stop-rule

S40 may open only as a restricted B1 pathway.

The gate is hierarchical.

### Tier 1: object admissibility

All Tier 1 conditions must pass:

1. B1 is the candidate being evaluated.
2. B1 is under formal restricted-pathway evaluation.
3. No severe collinearity flag applies to B1.
4. FM-OLS is available for the B1 reconstruction-relevant windows.
5. IM-OLS does not substantively contradict FM-OLS.

DOLS contradiction does not make Tier 1 fail.

DOLS contradiction sets:

- `dols_fragility_flag = TRUE`
- `dols_veto = FALSE`
- `dols_reconstruction_basis = FALSE`

If Tier 1 fails, S40 remains blocked regardless of later stability or stress-test evidence.

### Tier 2: stability evidence

Tier 2 uses Hansen-type evidence as the preferred formal stability diagnostic, together with existing neighborhood diagnostics.

Tier 2 requires:

1. Hansen-type evidence is `supportive` or `mixed`.
2. Neighborhood diagnostics do not overturn the interpretation.

If Tier 2 is `supportive` and Tier 1 passes, S40 may open only as a restricted B1 pathway.

If Tier 2 is `mixed` and Tier 1 passes, S40 may open only as a restricted B1 pathway with an explicit fragility flag.

If Tier 2 is `contradictory` or `unavailable`, S40 remains blocked.

### Tier 3: supporting stress checks

Gregory-Hansen, if run, is a supporting stress check only.

It may report one-break cointegration sensitivity, but it cannot redefine historical windows, create regimes, or promote any non-B1 specification.

The decision table must explicitly record one of:

- `s40_gate = pass_restricted`
- `s40_gate = pass_restricted_fragility_flag`
- `s40_gate = blocked`

If the hierarchical gate blocks S40, the correct result is:

> US S40 blocked: no admissible restricted B1 pathway under S30 evidence.

This is a substantive S30 finding, not a failed code path.

---

## 10. Relation to S40 anchoring

If S30 returns:

`s40_gate = pass_restricted`

or:

`s40_gate = pass_restricted_fragility_flag`

then S40 may proceed only under the downstream S40 contract.

S40 must then use the D03 anchor protocol.

For the United States, the preferred S40 baseline is:

$$
\mu_{US,1973}=1
$$

S40 must not infer the utilization anchor from:

- the S30 benchmark window;
- the S30 stability gate;
- the S30 candidate-window register;
- DOLS fragility results;
- rolling or recursive paths.

The Fordist-core window may remain a coefficient-recovery or historical benchmark window, but it must not be silently converted into:

$$
\overline{\mu}_{1945-1973}=1
$$

as the preferred baseline.

If a Fordist-core mean normalization is computed later, it must be labeled diagnostic or robustness only.

---

## 11. Ready to code only if

- [ ] The script is limited to US S30 formal stability adjudication.
- [ ] The script consumes existing S30 outputs instead of expanding the estimator grid.
- [ ] `SPEC_B1_WAGE_BASELINE` is the only restricted S40-pathway candidate under review.
- [ ] `SPEC_C1_COMPOSITION_STOCK` is mechanism evidence only.
- [ ] `SPEC_C2_FULL_COMPOSITION`, `SPEC_D1_CURRENT_COST_DIAGNOSTIC`, and `SPEC_D2_PRICE_WEDGE_DIAGNOSTIC` are diagnostic-only.
- [ ] FM-OLS remains the main estimator.
- [ ] IM-OLS remains the robustness estimator.
- [ ] DOLS remains a fragility/stress diagnostic only.
- [ ] DOLS contradiction flags fragility but does not veto Tier 1.
- [ ] Hansen-type parameter-instability testing is the preferred formal stability diagnostic, with exact/proxy status reported.
- [ ] Stability evidence is classified as `supportive`, `mixed`, `contradictory`, or `unavailable`.
- [ ] The S40 decision uses the Tier 1 object-admissibility, Tier 2 stability-evidence, and Tier 3 supporting-stress hierarchy.
- [ ] Mixed Tier 2 evidence opens S40 only with an explicit fragility flag.
- [ ] Contradictory or unavailable Tier 2 evidence leaves S40 blocked.
- [ ] Gregory-Hansen is optional, one-break-only, and diagnostic; it does not choose regimes or windows.
- [ ] No S40 code, productive-capacity reconstruction, utilization computation, utilization anchor, profitability analysis, or Chile output is produced.
- [ ] The script exports a formal S30 gate decision that never promotes C1, C2, D1, or D2.
- [ ] The manifest records `s30_anchor_authority = FALSE`.
- [ ] The note remains consistent with D03: if S40 opens, the preferred U.S. utilization anchor is $\mu_{US,1973}=1$.

---

## 12. Locked formulation

S30 opens or blocks S40.

S30 does not choose the utilization level anchor.

The US S30 formal stability protocol adjudicates whether `SPEC_B1_WAGE_BASELINE` may open a restricted S40 pathway under fragility discipline.

The admissible hierarchy is:

- FM-OLS = main estimator;
- IM-OLS = robustness estimator;
- DOLS = fragility / stress diagnostic.

DOLS may flag fragility, but it may not independently veto Tier 1 or define the reconstruction basis.

If S40 opens, the U.S. utilization anchor is governed by D03, with the preferred baseline condition:

$$
\mu_{US,1973}=1
$$

The Fordist-core window may remain a coefficient-recovery or historical benchmark window, but it must not silently impose:

$$
\overline{\mu}_{1945-1973}=1
$$

as the baseline utilization normalization.
