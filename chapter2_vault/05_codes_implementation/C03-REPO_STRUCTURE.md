---
type: implementation_memo
status: active
layer: code_stage_design
design_role: repo_structure_and_stage_governance
scope: chapter2_results_repo
repo: Capacity-Utilization-US_Chile
stage_scope:
  - S10
  - S20
  - S30
  - S40
  - S50
  - S60
  - S70
  - S90
  - S99
anchor_protocol_governed_by: D03_capacity_utilization_level_anchor_pinch_year_protocol
figure_protocol_governed_by: C05-FIGURE_PROTOCOL
s30_anchor_authority: false
us_s40_preferred_anchor_year: 1973
us_s40_anchor_condition: mu_US_1973_equals_1
us_s40_anchor_type: point_year_external_pinch
us_s40_anchor_source: FRB_maximum_utilization_series
cl_s40_preferred_anchor_year: 1980
cl_s40_anchor_condition: mu_CL_1980_equals_1
cl_s40_anchor_type: point_year_historical_pinch
cl_s40_anchor_source: Ffrench_Davis_2018_full_capacity_reference
window_average_anchor_allowed_as_baseline: false
created: 2026-05-06
updated: 2026-05-26
related_to:
  - C01-US_00_MEMO_RECYCLING
  - C02-CL_00_MEMO_RECYCLING
  - C04-US_S30_STABILITY_PROTOCOL
  - C05-FIGURE_PROTOCOL
  - US_S40_Restricted_B1_Reconstruction_Contract
  - US_S40_Review_and_Figures_Contract
  - D03_capacity_utilization_level_anchor_pinch_year_protocol
  - M10_Empirical_Identification_Framework
---

# C03 - Results Repository Structure and Stage Governance

## 1. Purpose

This memo defines the implementation structure for the Chapter 2 results repository:

`C:\ReposGitHub\Capacity-Utilization-US_Chile`

It is a repository-governance note. It does not estimate models, reconstruct productive capacity, compute utilization, choose anchors, generate figures, or activate later stages.

Its role is to keep the code layer flat, stage-bounded, and consistent with the analytical locks already defined elsewhere in the vault.

The core rule is simple:

> C03 maps the implementation architecture. It does not override D03, C04, C05, or the stage-specific contracts.

---

## 2. Source-of-authority hierarchy

The implementation layer is governed by separate notes with separate jobs.

| Authority | Governs | Does not govern |
|---|---|---|
| `D03_capacity_utilization_level_anchor_pinch_year_protocol` | Utilization level anchors | Estimator choice, figure style, S30 gate |
| `C04-US_S30_STABILITY_PROTOCOL` | US S30 formal stability gate | S40 anchor choice, figures, reconstruction formula |
| `US S40 Restricted B1 Reconstruction Contract` | US S40 restricted B1 reconstruction | Review figures, profitability, Chile, S50 |
| `US S40 Review and Figures Contract` | US S40 checks and figures | Re-estimation, re-anchoring, profitability, S50 |
| `C05-FIGURE_PROTOCOL` | Figure conventions, anchor markers, recession shading | Measurement objects, model estimation, utilization anchors |
| `C01-US_00_MEMO_RECYCLING` | US script recycling map | Active code execution by itself |
| `C02-CL_00_MEMO_RECYCLING` | Chile script recycling map | Active code execution by itself |

No note may silently import another note's authority.

In particular:

- S30 opens or blocks S40; it does not choose the utilization level anchor.
- D03 governs the utilization level anchor.
- C05 governs recession shading and figure conventions.
- S40 reconstruction creates `theta_tot`, `Yp`, and `mu`.
- S40 review verifies and visualizes; it does not reconstruct.

---

## 3. Repository shape

The results repository should use a flat code architecture:

`codes/`

No country subfolders should be created inside `codes/` unless a later repository-wide decision changes the architecture.

Country, stage, and function should be carried in script names:

- `US_S10_source_of_truth_panel.R`
- `US_S20_composition_stability_admissibility.R`
- `US_S30_transformation_relation_fmols_imols_dols.R`
- `US_S30_formal_stability_adjudication.R`
- `US_S40_theta_tot_mu_reconstruction.R`
- `US_S40_review_and_figures.R`
- `US_S50_theta_mu_profitability_corridor.R`
- `US_S90_dols_fragility_diagnostics.R`
- `US_S99_results_package.R`
- `CL_S10_source_of_truth_panel.R`
- `CL_S20_composition_mechanization_external_constraint.R`
- `CL_S30_transformation_relation_fmols.R`
- `CL_S40_theta_tot_mu_reconstruction.R`
- `CL_S50_theta_mu_profitability_corridor.R`
- `CL_S60_peripheral_mechanization_constraint.R`
- `CL_S90_threshold_dummy_fgls_admissibility.R`
- `CL_S99_results_package.R`

The output layer may use country and stage folders, for example:

`output/US/S40_theta_tot_mu_reconstruction/`

`output/US/S40_review_and_figures/`

`output/CL/S40_theta_tot_mu_reconstruction/`

This separation keeps executable code flat while allowing outputs to remain auditable by country and stage.

---

## 4. Stage map

| Stage | Role | Produces | Must not do |
|---|---|---|---|
| S10 | Source-of-truth panel | Canonical panel and data register | Econometrics, mu reconstruction, profitability interpretation |
| S20 | Composition, admissibility, windows, diagnostics | Candidate variables, admissible samples, stability evidence | Utilization anchoring, final reconstruction |
| S30 | Long-run transformation relation | Coefficients, estimator diagnostics, formal gate decisions | Productive capacity paths, mu paths, anchors |
| S40 | Theta, productive capacity, utilization reconstruction | `theta_tot`, `Yp`, `mu`, anchor register | New model estimation, profitability, S50 |
| S50 | Productive-capacity/profitability corridor | Downstream interpretation of `theta -> mu -> r` | Re-anchor or repair S40 |
| S60 | Chile peripheral recapitalization/external-constraint corridor | `chi -> k -> g` and external-mechanization diagnostics | Replace S40 reconstruction |
| S70 | Comparative synthesis, if activated | Cross-country comparison | Recompute country-level primitives silently |
| S90 | Diagnostics and stress tests | DOLS stress, ECT audits, robustness checks | Define baseline reconstruction or anchor |
| S99 | Results package | Tables, manifests, paper/advisor-facing outputs | Silent recomputation of upstream objects |

A downstream stage consumes upstream outputs. It does not repair them silently.

If an upstream object is wrong, the upstream stage must be patched and re-run.

---

## 5. US pathway status

The current US implementation pathway is restricted B1 under fragility discipline.

The active candidate is:

`SPEC_B1_WAGE_BASELINE`

The active S30 rule is governed by:

`C04-US_S30_STABILITY_PROTOCOL.md`

The active S40 reconstruction contract is:

`US S40 Restricted B1 Reconstruction Contract.md`

The active S40 review and figure contract is:

`US S40 Review and Figures Contract.md`

The US pathway is not a clean benchmark promotion.

It is a restricted reconstruction path that must carry its fragility status unless a later formal gate is rerun and changes that status.

---

## 6. Anchor boundary rule

Utilization anchors are not chosen by repository layout, S30 stability tests, reconstruction windows, DOLS diagnostics, or figure conventions.

They are governed by:

`D03_capacity_utilization_level_anchor_pinch_year_protocol.md`

For the United States, the preferred S40 baseline anchor is:

$$
\mu_{US,1973}=1
$$

This is a point-year external-pinch anchor sourced to the FRB maximum utilization series.

For Chile, the preferred S40 baseline anchor is:

$$
\mu_{CL,1980}=1
$$

This is a point-year historical-pinch anchor associated with the Ffrench-Davis (2018) full-capacity reference.

The Fordist-core window may remain relevant for coefficient recovery, historical benchmarking, or diagnostics.

It must not silently impose:

$$
\overline{\mu}_{1945-1973}=1
$$

as the preferred US utilization normalization.

Any window-average normalization must be explicitly labeled diagnostic or robustness-only.

---

## 7. Figure boundary rule

Figure conventions are governed by:

`C05-FIGURE_PROTOCOL.md`

For U.S. figures, recession shading follows the FRED/NBER recession-bar convention and is annualized using the `any_month_overlap` rule.

Recession shading is visual context only.

It is not:

- a regime classifier;
- a break-date estimator;
- a window-selection device;
- a threshold trigger;
- an anchor rule.

For U.S. S40 review figures, the mu figure must mark:

$$
\mu_{US,1973}=1
$$

The figure layer must not shade 1945--1973 as if that interval were the utilization anchor window.

---

## 8. Country boundaries

US and Chile outputs must remain separated unless a comparative stage explicitly consumes both.

US S40 scripts must not touch Chile outputs.

Chile S40 scripts must not touch US outputs except through a later comparative stage.

Comparative outputs should live only in a declared comparative stage, such as S70 or S99 comparative packaging.

---

## 9. Hard prohibitions

The repository structure must not allow scripts to:

- re-estimate models inside review layers;
- reconstruct utilization inside S30;
- choose anchors from rolling estimates;
- choose anchors from recession shading;
- choose anchors from Fordist-core window means as the preferred baseline;
- use DOLS as the reconstruction basis;
- use residuals as primitive utilization;
- infer `theta_M` as directly estimated;
- compute profitability before S50;
- let S99 silently recompute upstream objects;
- let C03 override D03, C04, C05, or S40 contracts.

---

## 10. Locked formulation

The Chapter 2 results repository is organized as a flat staged code architecture.

C03 governs the stage map and repository boundaries only.

C04 governs the US S30 gate.

D03 governs utilization anchors.

C05 governs figures.

The S40 reconstruction contract governs the creation of `theta_tot`, `Yp`, and `mu`.

The S40 review contract governs checks and figures.

For the current US path, S40 may proceed only as restricted B1 under fragility discipline, with the preferred utilization anchor:

$$
\mu_{US,1973}=1.
$$

The Fordist-core mean normalization:

$$
\overline{\mu}_{1945-1973}=1
$$

is diagnostic only and must not be treated as the preferred baseline.
