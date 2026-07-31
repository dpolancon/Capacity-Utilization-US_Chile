---
type: econometrics
status: active
country: US_CL
stage_scope: N/A
last_updated: '2026-07-30'
depends_on: []
blocks: []
layer: empirics
scope: chapter2
priority: reference
---

# Econometrics Specifications

## Active Estimator: Polynomial Cointegration (CPR)

See: N01_CapacityUtilization_StructuralObject.md

## Binding Structural Break Protocols (S0*)

**Status: `locked` — binding on all US Baseline (Spec A) and Specification B re-runs.**

As of 2026-07-30, the three structural break protocol notes govern all integration-order
pre-testing and structural break identification for the U.S. IM-OLS reports. No cointegrating
equation for Specification A or Specification B may be re-estimated or reported without passing
through this sequence first.

| File | Role | Scope |
|---|---|---|
| `S03_StructuralBreak_Protocol.md` | **Foundational.** Bai-Perron vs. Lee-Strazicich theoretical framework; defines when to use additive (level/trend) vs. multiplicative (elasticity-switch) break terms | US_CL, general |
| `S01_StructuralBreak_Protocol.md` | Applies S03 to the aggregated baseline model (Specification A / NFC value added, $k_t^{cap}$) | US, Fordism/Post-Fordism split-sample |
| `S02_StructuralBreak_Protocol.md` | Applies S03 to the disaggregated capital model (Specification B / mechanization gap $\kappa_t$) | US, Fordism/Post-Fordism split-sample |

**Read order:** S03 → S01 (if working on Spec A) → S02 (if working on Spec B).

**Binding sequence (all three protocols):**
1. Bai-Perron (1998, 2003) sequential break search on stationary first differences
2. Lee-Strazicich (2003) Minimum-LM unit root verification at candidate break dates (confirms I(1)-with-break rather than spurious I(2))
3. IM-OLS / DOLS estimation with additive and/or multiplicative break terms, gated on Step 2's verdict

**External dependency:** `C:\ReposGitHub\LeeStrazicichUnitRoot` — implementation repo for the Lee-Strazicich LM unit root test used in Step 2 of all three protocols. Not vendored into this repo; treat as an upstream code dependency.

**Downstream reports gated by this lock:**
- `reports/US_Baseline_IMOLS_Capital_Aggregation_Report/` (Specification A)
- `reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/` (Specification B)

**Non-binding preliminary evidence:** `reports/US_Capital_Composition_Integrated_Report/` documents the LOESS-based and pairwise integration-order groundwork that motivated this protocol. It is informative context, not an authority — do not cite it as satisfying the S0* pre-testing requirement on its own.

## Deprecated Explorations

See: ../99_archive/legacy_econometrics/ for:
- DOLS vs. FM-OLS vs. IM-OLS comparisons
- Earlier threshold-model attempts
- Interaction-term integration-order work (now consolidated in E_*.md)

These are provided for understanding the research process, not for current work.