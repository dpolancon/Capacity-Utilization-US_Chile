---
type: implementation_memo
status: active
layer: figure_protocol
design_role: recession_shading_and_stage_figure_conventions
scope: chapter2_results_repo
repo: Capacity-Utilization-US_Chile
applies_to:
  - US
  - CL
  - CMP
figure_scope:
  - S40
  - S50
  - S60
  - S70
  - S90
  - S99
us_recession_shading_source: FRED_NBER_monthly_business_cycle_turning_points
us_recession_shading_source_url: fredhelp_stlouisfed_recession_bars
annual_recession_rule: any_month_overlap
recession_shading_role: visual_context_only
recession_shading_regime_classifier: false
anchor_markers_required_when_applicable: true
created: 2026-05-14
updated: 2026-05-14
related_to:
  - C03-REPO_STRUCTURE
  - US_S40_Review_and_Figures_Contract
  - US_S40_Restricted_B1_Reconstruction_Contract
  - D03_capacity_utilization_level_anchor_pinch_year_protocol
  - M10_Empirical_Identification_Framework
---

# C05 - Figure Protocol

## 1. Purpose

This memo defines reusable figure conventions for the Chapter 2 results repository.

It governs visual conventions only.

It does not define measurement objects.

It does not estimate models.

It does not reconstruct capacity.

It does not define utilization anchors.

It does not classify regimes.

It provides figure-level rules for:

- recession shading;
- anchor markers;
- stage labels;
- diagnostic labels;
- output formats;
- figure interpretation.

This protocol applies to U.S., Chile, and comparative figures whenever the convention is relevant.

---

## 2. Figure-status rule

Every figure must be visually and textually tied to its analytical status.

A figure should indicate whether it is:

- diagnostic;
- advisor-facing;
- paper-facing candidate;
- robustness-only;
- restricted reconstruction;
- restricted reconstruction under fragility;
- comparative synthesis.

Figures must not silently promote a provisional or diagnostic object into a clean benchmark result.

For S40 U.S. figures, the figure label must indicate:

`restricted B1 under fragility`

unless the upstream gate is later changed and explicitly re-run.

---

## 3. U.S. recession shading source

U.S. recession shading should use the official recession-bar convention used by FRED.

FRED uses NBER business-cycle turning points for recession bars. The underlying recession dates are monthly peak and trough dates, represented as daily dates in FRED graphs regardless of the plotted series frequency.

Therefore, U.S. recession shading must be treated as a visual context layer derived from NBER/FRED recession intervals.

It is not:

- a regime classifier;
- a break-date estimator;
- a window-selection device;
- a threshold trigger;
- a replacement for S20/S30 stability diagnostics.

---

## 4. Annualization rule for U.S. recession shading

Most Chapter 2 series are annual.

The preferred annualization rule is:

> Shade annual year y if at least one month in calendar year y overlaps an NBER/FRED recession interval.

This is the `any_month_overlap` rule.

Formally, let recession interval j run from monthly peak date `P_j` to monthly trough date `T_j`.

Annual year y is recession-shaded if:

$$
[Jan_y,Dec_y] \cap [P_j,T_j] \neq \emptyset
$$

for at least one recession interval j.

This rule is preferred because it is transparent and preserves short recessions and edge years.

Examples:

- the 1973-11 to 1975-03 recession shades 1973, 1974, and 1975;
- the 1980-01 to 1980-07 recession shades 1980;
- the 2007-12 to 2009-06 recession shades 2007, 2008, and 2009;
- the 2020-02 to 2020-04 recession shades 2020.

---

## 5. Rejected annualization rules

The following annualization rules are not preferred:

### Majority-of-months rule

This shades a year only if most months overlap a recession.

Problem:

It drops edge years and short recessions too aggressively.

### Full-year recession rule

This shades a year only if all months are recession months.

Problem:

It is almost useless for modern U.S. recessions.

### Peak/trough-year-only vertical markers

This marks only peak and trough years.

Problem:

It loses duration information.

This may be used as a secondary visual device, but not as the main annual recession shading rule.

---

## 6. Recession shading metadata

Any script adding U.S. recession shading must record:

- `recession_shading_source = FRED_NBER_monthly_business_cycle_turning_points`
- `recession_shading_annualization = any_month_overlap`
- `recession_shading_role = visual_context_only`
- `recession_shading_regime_classifier = FALSE`

If a figure uses annual recession shading, the report or manifest should state the annualization rule.

---

## 7. Anchor marker rule

When a figure shows a reconstructed utilization path, it must mark the relevant utilization anchor if the anchor belongs to the active contract.

For the U.S. S40 restricted B1 reconstruction, the anchor marker is:

$$
\mu_{US,1973}=1
$$

The mu figure must mark 1973 as the utilization anchor point.

It must not shade 1945–1973 as if that interval were the utilization anchor window.

If the Fordist-core window is displayed, it must be labeled as:

- historical benchmark;
- coefficient-recovery window;
- diagnostic window;

not as the utilization level anchor.

For Chile, the preferred anchor marker is:

$$
\mu_{CL,1980}=1
$$

when Chile S40 figures are implemented.

---

## 8. Interaction between recession shading and anchors

Recession shading and anchor markers are different visual layers.

Recession shading provides macro-historical context.

Anchor markers identify level-normalization points.

Do not interpret recession shading as evidence that the anchor year is a regime boundary.

Do not interpret anchor years as recession dates unless independently true.

Do not let recession shading obscure anchor markers.

If both are shown, the anchor marker should remain visually legible.

---

## 9. Figure output formats

Advisor-facing and paper-facing figures should be exported in both:

- `.png`
- `.pdf`

CSV summaries and reports should be tracked unless the repository policy says otherwise.

Binary figure files may remain ignored by `.gitignore` if that is the repository policy.

If binary figures are ignored, the report should list their expected local output paths.

---

## 10. Figure notes

Figure notes should state the analytical status of the object.

For U.S. S40 restricted B1 figures, use language such as:

> Restricted B1 reconstruction under fragility. U.S. recession shading follows the FRED/NBER recession-bar convention, annualized using the any-month-overlap rule. The utilization anchor is the point-year condition mu_US,1973 = 1.

Avoid language such as:

> The figure identifies the U.S. utilization regime.

or:

> Recession bars determine the reconstruction window.

---

## 11. Hard prohibitions

Figures must not:

- identify regimes by recession shading;
- identify structural breaks by recession shading;
- choose reconstruction windows by recession shading;
- choose utilization anchors by recession shading;
- imply that theta_M is directly estimated;
- present diagnostic reconstructions as clean benchmarks;
- hide fragility flags;
- treat Fordist-core mean utilization as the preferred U.S. baseline anchor;
- use recession shading as a substitute for S20/S30 stability diagnostics.

---

## 12. Locked formulation

Chapter 2 figures must separate visual context from identification.

For U.S. figures, recession shading follows the FRED/NBER recession-bar convention. Because the core Chapter 2 series are annual, recession shading is annualized using the any-month-overlap rule: a year is shaded if any month in that calendar year overlaps an NBER/FRED recession interval.

Recession shading is visual context only. It is not a regime classifier, a break-date estimator, a window-selection device, or an anchor rule.

Utilization anchor markers are governed separately by D03. For the U.S. S40 restricted B1 reconstruction, the anchor marker is:

$$
\mu_{US,1973}=1
$$

For Chile, the preferred anchor marker is:

$$
\mu_{CL,1980}=1
$$

when Chile S40 figures are implemented.