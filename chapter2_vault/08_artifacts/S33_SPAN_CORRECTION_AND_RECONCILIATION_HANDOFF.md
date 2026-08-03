---
type: handoff
stage: S03-S40 complete
country: US
last_updated: 2026-07-31
status: completed with contingencies
---

# S33 Span Correction and Price-Channel Reconciliation — Handoff

## Scope Completed

This session fixed a structural defect affecting three empirical tracks (S33C, S33D, S33E) and resolved evidence for the §3.2-vs-A06 price-channel conflict by running an explicit discrimination test. All three centering regimes reported throughout; only interaction-class parameters gated.

### Deliverables

| Stage | Spec | Output | Status |
|-------|------|--------|--------|
| S33C | A (split, Fordist + Post-Fordist) | v7 report (md/tex/pdf, 16 pp) | ✓ complete |
| S33D | B (split, with B1-B4 taxonomy) | v8 report (md/tex/pdf, 28 pp) | ✓ complete |
| S33E | B (full sample, wage break only) | corrected outputs | ✓ complete |
| S33G | B5 (full sample, Sec.3.2 form) | v6 byte-identical | ✓ verified |
| S33I | B (full sample, price ladder) | 6 ledger CSVs | ✓ complete |
| common | shared utilities | s33_break_span() + assertion | ✓ code |
| reconciliation | A06/§3.2 | cross-reference note | ✓ written |

### The Fix

**Problem:** Centering of an interacted dummy (κ·ω)·D expands as
```
(κ - κ₀)(ω - ω₀)D = κωD - κ₀(ωD) - ω₀(κD) + κ₀ω₀D
```
So the design must carry ALL four terms for centering to be a reparameterization, not a model change. S33C was missing ω·D; S33D missing both ω·D and p·D; S33E missing both κ·D and ω·D.

**Solution:** Added `s33_break_span()` and `s33_assert_complete_span()` helpers to common.R. Applied to all three tracks.

**Verification:** S33G (already complete) byte-identical after fix (0 of 8 files changed).

### What Changed in Each Track

#### S33C (Spec A, split sample)
- Added `omega_x_D` constituent
- Fordist θ₁ still unstable [−15.22, 4.17] (was [−5.90, 3.46])
- Post-Fordist θ₁ remains stable [1.28, 3.60]
- CN rose Fordist: 48.7 → 50.6; Post-Fordist: 79.1 → 359.0
- v6 untouched (2026-07-30); v7 carries corrected estimates

#### S33D (Spec B, split sample)
- Added `omega_x_D` and `p_kappa_x_D` constituents; retained `kappa_x_D` under B4
- B3 Fordist interacted: θ_{ωκ} now stable [−174.37, −95.46] (was [−23.61, 47.79]) ✓ FIXED
- B3 Post-Fordist: θ_{ωκ} stable [−51.03, −45.21]; θ_{κpκ} stable [−28.74, −4.76]
- CN rose 2× in both windows; df fell by 2
- One parameter lost stability: S33D B2 Fordist δ₂ (broken span exposed hidden collinearity there)
- v8 discloses this explicitly; combinatorics grid flagged as needing separate update

#### S33E (full sample, wage break)
- Added `kappa_x_D` and `omega_x_D` constituents
- θ_{κpκ} still unstable [−0.41, 1.08] (was [−0.74, 2.08])
- But the span fix was *required* for theoretical consistency; instability is a design-limitation finding, not an argument to omit the constituents
- Full-sample θ_{κpκ} [−0.689, −0.558] sign-stable in S33G because standalone κ is present there

### The §3.2 vs A06 Reconciliation (S33I)

Ran A06 Sec.2's nested ladder (A1: no price; A2: additive; A3: interacted) under **two timings**:
- Contemporaneous `κ·p_t` (Sec.3.2 line 94)
- Lagged `κ·p_{t−1}` (A06 line 102)

All three centering regimes; full sample; complete span.

#### Key Findings

1. **θ_{κpκ} sign depends on break specification, not timing**
   - A3 contemporaneous + break: −0.689 to −0.558 (stable, favours Sec.3.2)
   - A3 contemporaneous no break: +0.655 to +1.027 (stable, favours A06 line 72)
   - A3 lagged + break: −0.068 to +0.531 (unstable — indeterminate)

2. **Price terms are jointly insignificant** once wage break is in
   - A3 Wald F = 0.521 (p = 0.597) contemporaneous with break
   - A3 Wald F = 0.015 (p = 0.985) lagged with break
   - The price channel is not identified

3. **A06 line 72 contradicts A06 line 74**
   - Formula: ∂q*/∂p^{rel} > 0 (line 72)
   - Prose: "cheapening machinery ... accelerates mechanization" = ∂q*/∂p^{rel} < 0 (line 74)
   - Sec.3.2 agrees with the prose

4. **Timing convention (A06's central claim) is model-dependent**
   - No break: lagged σ̂ᵤ = 0.1076 vs contemporaneous 0.1094 (lagged slightly better)
   - With break: contemporaneous σ̂ᵤ = 0.064 vs lagged 0.071 (contemporaneous better)
   - Data cannot separate the timing empirically

#### Verdict Recorded, Not Adjudicated

Wrote `specB_price_channel_verdict.csv` without taking a side. Issues:
- Sec.3.2 and A06 are comparing different objects (capacity vs optimal gap)
- Even if they were the same, A06 is self-contradictory
- The price block is empirically unidentified when the wage break enters
- This points to investment-flow respecification as the next route

## Outstanding Work

### Immediate (depends on these estimates)

1. **θ_t^{SpecB} derivation (E18 path derivatives)** — depends on corrected S33D/S33E coefficients
   - Full-sample formula uses θ_{κpκ}, which is still unstable in S33E
   - Split-sample formulas can use S33D's corrected figures

2. **Spec B combinatorics grid** — still carries broken-span design
   - Recompute with `s33_break_span()` if the B1–B4 taxonomy is to be finalized
   - Impact: conditioning will worsen further; some cells may become untenable

### Medium term (design contingencies)

3. **Fordist window viability** — S33D B3 interacted now puts 12 regressors on T = 43 (df = 30)
   - Specification is correctly scoped, but reliability is questionable
   - Consider: (a) narrower window (e.g., 1930s–1960s excluding WWII), (b) drop interacted rung, (c) accept as exploratory

4. **Investment-flow respecification** — price channel is unidentified as a state-dependent force
   - Theory suggests firm-level investment decisions respond to q* changes, not capacity payoffs
   - This requires respecifying the outcome as investment flows (ΔK^ME) rather than capacity yields
   - Blocked pending Sec.3.2 revision

### Later (beyond Spec B)

5. **Chile parallel tracks** — S33 design (with span completion) is ready to apply to CL data
   - CL stage B TVECM already built on the backbone panel
   - Exchange rates still missing (see MEMORY.md)

## Technical Notes

### Centering Protocol (N11 Sec.1)

- Only **interaction-class** parameters are claimed invariant across centering regimes
- Base-class coefficients **are expected to move** — they are reparameterizations of the intercept
- All three regimes reported in every CSV; "reported regime" chosen by CN ≤ 30 gate
- Gating restricts to interaction-class sign-stability; base-class moves do not fail a gate

### No-Fabrication Verification

- 48 headline numbers in v7/v8 traced to ledger cells; all matched
- Integrity checks: 63 checks across 5 stages, all pass
- Predessors v6/v7 byte-identical (2026-07-30); not edited

### Code Quality

- 5 new functions in common.R: `s33_break_span()`, `s33_assert_complete_span()`, `s33_joint_wald()`, `s33_center()`, `s33_step()`
- No FWL pre-filtering (verified); no three-way interactions inferred
- E10V estimator lock maintained; no post-hoc unit-root tests on cross-products
- Governance: all artifacts under `output/US/BREAK_AWARE_IMOLS/`

## Decision Checkpoints

### v7 (Spec A) — Go
- Fordist interaction remains unstable, but span fix is required for centering to be valid
- Instability is a reporting finding, not grounds to omit the constituent
- CN and df trade-offs disclosed in v7; not hidden

### v8 (Spec B) — Go with caveats
- B3 Fordist sign-stabilized; post-Fordist unchanged (already stable)
- **BUT:** S33D B2 Fordist δ₂ **lost** stability (span exposure of hidden collinearity)
  - Decision: report as a rung-specific limitation; accept B3 as the primary split-sample rung
  - Do not force B2 back to pre-correction state (that would reintroduce the defect)
  
- **Combinatorics grid not corrected** (separate effort)
  - Decision: flag in v8 as "span correction pending"; do not cascade corrections into 505 models without review
  - Keeps the revision scope bounded; allows selective updates later

### Price-channel reconciliation — Go
- Evidence recorded, theory not adjudicated
- Sent to author with A06 self-contradiction noted and cross-partial caveat logged
- Unidentification of the price block is itself a finding

## How to Continue

### If extending Spec B to investment flows

1. Redefine outcome as `d(κ_t)` or `d(K^ME_t)` rather than `d(κ_t) → capacity`
2. Run S33 ladder with the new outcome; compare price-channel sign
3. Apply S33I discrimination test to investment flows — may resolve the sign if investment decisions precede capacity payoffs

### If fixing Fordist window

1. **Option A:** Subsample 1930–1965 (Golden Age, exclude WWII/immediate postwar)
   - Re-run Bai-Perron on this window; may find a different break date
   - Reduces T but improves df for the interacted rung
   
2. **Option B:** Pool Fordist + Post-Fordist with a structural-break interaction
   - Frees up degrees of freedom; treats the two eras as one DGP with a shift
   - Requires theory justification for why κ·D enters at all

3. **Option C:** Accept S33D B3 Fordist as exploratory (not formal)
   - Keeps the rung in the combinatorics for transparency
   - Report CN/df as limitations upfront; do not use for structural parameter recovery

### If updating Spec B combinatorics

1. Recompute the 505-model grid using corrected S33D design (with `s33_break_span()`)
2. Compare before/after to quantify the span-correction impact across the taxonomy
3. Update COEF_MAP and PARAM_CLASS in the combinatorics script to match S33D
4. Rerun with integrity gates; report which cells fail the interaction-stability gate

## Key Contacts & References

| Topic | File / Script |
|-------|---------------|
| Theory conflict stated precisely | ch2_sec3_2_heterogeneous_capital_prelatex.md (line 51, 68) and A06_RelativePrice_Mechanization_Theory.md (line 72, 74) |
| Span mechanism on synthetic data | codes/US_S33F_centering_invariance_diagnostic.R and handoff note |
| Wald joint test on price terms | s33_joint_wald() in common.R |
| N11 centering gate logic | US_S33G_specB5_theory_consistent_full_sample.R (lines 244–253) |
| Split-sample windows | S33_WINDOWS in common.R; Bai-Perron dates from S33A |
| Data backbone | output/panel/chile_panel_extended.csv (Chile) and GPIM_specB_components_long.csv (US) |

## Session Summary

**Span defect fixed:** all three tracks now carry complete break-interaction spans.
**Fordist window strained:** B3 interacted reaches 12 regressors on T=43; stability recovered but reliability contingent.
**Price channel unidentified:** both timings and both derivations empirically indistinguishable once wage break enters.
**Reports issued:** v7 (16 pp) and v8 (28 pp) with no undefined refs; v6/v7 preserved byte-identical.
**Pending:** θ_t^SpecB derivation (needs stable θ_{κpκ}), combinatorics recompute, investment-flow respecification route.

---

**Created:** 2026-07-31 15:30 UTC
**Model:** Claude Haiku 4.5
**Next session should:** review Spec B5 vs investment-flow trade-off; decide on Fordist viability option; sketch E18 path derivatives.
