---
type: code_recycling_memo
status: active
layer: implementation_design
design_role: us_code_recycling_and_stage_mapping
scope: chapter2_results_repo
repo: Capacity-Utilization-US_Chile
country: US
stage_scope:
  - S10
  - S20
  - S30
  - S40
  - S50
  - S90
  - S99
related_to:
  - M10_Empirical_Identification_Framework
  - D03_capacity_utilization_level_anchor_pinch_year_protocol
  - C03-REPO_STRUCTURE
  - R02_DOLS_reconstruction_dilemma
  - R04_FMOLS_structural_preservation
  - R06_IMOLS_integration_ladder_reconstruction
anchor_protocol_governed_by: D03_capacity_utilization_level_anchor_pinch_year_protocol
anchor_protocol_country: US
anchor_protocol_preferred_year: 1973
anchor_protocol_condition: mu_US_1973_equals_1
anchor_protocol_type: point_year_external_pinch
anchor_protocol_source: FRB_maximum_utilization_series
anchor_protocol_role: level_normalization
window_average_anchor_allowed_as_baseline: false
created: 2026-05-06
updated: 2026-06-02
---


# Memo 1 — US Code Recycling Map

## 1. Status

The US code batch should be treated as **recyclable DOLS-era material**, not as definitive production code.

The scripts contain useful machinery:

- estimator grids
- window comparisons
- DOLS sensitivity checks
- theta paths
- mu reconstruction routines
- profitability decomposition
- result-package exports

But they are still organized around an older pipeline where DOLS carries too much weight. Under the current analytical lock, that is no longer admissible as the main reconstruction architecture.

The US side must be rebuilt around:

- FM-OLS = main reconstruction estimator
- IM-OLS = robustness estimator
- DOLS = fragility / stress diagnostic

This estimator-role hierarchy is already locked in the empirical identification framework: Chapter 2 estimates the long-run transformation relation, reconstructs productive capacity, anchors it, and only then derives utilization; FM-OLS reconstructs, IM-OLS checks, and DOLS stresses fragility.

The additional S40-level anchor rule is now governed by:

`04_data_measurement/D03_capacity_utilization_level_anchor_pinch_year_protocol.md`

That protocol separates the reconstruction window from the utilization level anchor.

For the United States, the preferred baseline level anchor is:

$$
\mu_{US,1973}=1
$$

using 1973 as the FRB full-capacity pinch year.

The Fordist-core window may remain a historical benchmark or reconstruction context, but it must not define normal utilization by imposing:

$$
\overline{\mu}_{1945-1973}=1
$$

as the baseline normalization.

---

## 2. Main problem with the current US batch

The old US logic is approximately:

- DOLS coefficients
- theta_t = beta_1 + beta_2 omega_t
- Yp
- mu
- graphs / profitability

That is too direct.

The new logic must be:

- source-of-truth US panel
- composition and admissibility layer
- reduced-form coefficient recovery
- theta_tot reconstruction
- Yp reconstruction
- point-year level anchoring
- mu derivation
- theta_M interpretation
- profitability corridor
- results package

This matters because the updated analytical foundation distinguishes what is identified from what is reconstructed. The empirical model identifies `theta_tot`; `theta_M` is not directly estimated, but inferred through the model structure and the behavior of estimated coefficients.

It also matters because the reconstructed utilization path requires an explicit level anchor. That anchor is not chosen by S30 and should not be generated silently from the coefficient-recovery window. Under D03, the U.S. baseline anchor is the point-year condition:

$$
\mu_{US,1973}=1
$$

not the Fordist-core window-average condition:

$$
\overline{\mu}_{1945-1973}=1.
$$

---

## 3. Required US target sequence

The US code should be reconstructed into the following flat sequence:

- `US_S10_source_of_truth_panel.R`
- `US_S20_composition_stability_admissibility.R`
- `US_S30_transformation_relation_fmols_imols_dols.R`
- `US_S40_theta_tot_mu_reconstruction.R`
- `US_S50_theta_mu_profitability_corridor.R`
- `US_S90_dols_fragility_diagnostics.R`
- `US_S99_results_package.R`

This is a flat `codes/` architecture.

No country folders inside `codes/`.

---

## 4. US script recycling table

| Current script | Recycling status | New target | Treatment |
|---|---|---|---|
| `US_dols_diagnostic.R` | Keep as diagnostic donor | `US_S90_dols_fragility_diagnostics.R` | Recycle rolling VIF, lead-lag sensitivity, estimator-comparator, candidate dummy diagnostics. Do not allow it to define reconstruction. |
| `us_dols_spec_grid_cointReg.R` | Keep as stress-test donor | `US_S90_dols_spec_grid_fragility.R` | Preserve grid logic, collinearity checks, and specification sensitivity. DOLS remains fragility diagnostic, not main estimator. |
| `US_dols_try_fullsample.R` | Partial donor | `US_S20_historical_break_window_scan.R` or `US_S90_known_break_stress_test.R` | Use known-break and window logic as admissibility/stability evidence, not as final regime truth. |
| `US_dols_try_fullsample_v2.R` | Strongest estimator donor | `US_S30_transformation_relation_fmols_imols_dols.R` | Main donor for estimator-grid reconstruction because it already moves beyond pure DOLS. FM-OLS should become main, IM-OLS robustness, DOLS fragility. |
| `us_dols_mu_theta_graph.R` | Rebuild | `US_S40_theta_tot_mu_reconstruction.R` + `US_S99_theta_mu_figures.R` | Keep plotting/export ideas, but rebuild theta/mu around `theta_tot`, not old DOLS theta. The S40 anchor must follow D03: U.S. baseline `mu_1973 = 1`. |
| `us_dols_theta_graph.R` | Merge into export layer | `US_S99_theta_figures.R` | Should not remain standalone. It depends on upstream reconstructed theta objects. |
| `us_profitability_analysis.R` | Keep downstream | `US_S50_theta_mu_profitability_corridor.R` | Strong analytical engine, but it must consume rebuilt `theta_tot`, `Yp`, and `mu`. |
| `us_profitability_analysis_results_pack.R` | Keep downstream exporter | `US_S99_profitability_results_package.R` | Preserve tables, figures, and result-package logic after paths are standardized. |

---

## 5. US S10 gap

The current US batch lacks a clean source-of-truth builder.

A new script is required:

`US_S10_source_of_truth_panel.R`

Its function should be limited to canonical panel construction. It should not run econometrics, reconstruct mu, or generate paper-facing outputs.

Expected variables:

- `year`
- `Y_real`
- `K_total_real`
- `K_machinery_real`, if available
- `K_other_real`, if available
- `s_t = K_machinery / K_total`
- `omega_t`
- `pY`
- `pK`
- profitability inputs

### A00 interaction metadata

For A00 implementation metadata, `K_t` is aggregate real productive capital.

`k_t` is the log of `K_t` or another dimensionally admissible aggregate-capital index declared in the source-of-truth panel.

`omega_t` is the wage-share / distributive condition used in the aggregate transformation relation.

The A00 baseline interaction export is:

`omega_k_t = omega_t * k_t`

meaning:

$$
\omega_{k,t}=\omega_t k_t
$$

Restricted B1 is therefore the A00 aggregate interaction implementation before any A03 composition interpretation. Machinery and non-machinery capital variables may support A03 mechanism interpretation, but they do not replace the A00 baseline object.

The current scripts appear to repeatedly rebuild real output, real capital, and wage-share objects internally. That should stop. Each script should not behave as a tiny independent republic.

---

## 6. US S20 role

The US still needs an admissibility layer, even without the peripheral external-mechanization wedge.

`US_S20_composition_stability_admissibility.R` should:

- construct or validate `s_t` if available;
- define estimation windows;
- check integration order;
- check deterministic components;
- check breaks / stability;
- prepare admissible samples for S30;
- record what can and cannot be interpreted as stable.

This layer prevents a direct jump from source data to theta/mu reconstruction.

S20 may define candidate historical windows and benchmark windows. It does not define the utilization level anchor.

---

## 7. US S30 role

`US_S30_transformation_relation_fmols_imols_dols.R` should estimate the reduced-form long-run transformation relation.

Estimator roles:

- FM-OLS = main
- IM-OLS = robustness
- DOLS = fragility / stress

The script should not derive final mu as its main task. Its output should be coefficient objects and estimator-comparison diagnostics.

S30 may adjudicate whether S40 can open. It does not choose the utilization level anchor.

---

## 8. US S40 role

`US_S40_theta_tot_mu_reconstruction.R` should take the S30 coefficient output and reconstruct:

- `theta_tot`
- `Yp`
- `mu`

This is where productive capacity and utilization are derived.

It must not treat DOLS residuals as primitive utilization.

The correct logic is:

- estimated reduced-form relation
- theta_tot
- reconstructed Yp
- explicit point-year level anchor
- derived mu

This preserves the empirical identification rule: utilization is derived only after productive capacity is reconstructed and anchored.

### S40 anchor rule

US S40 must distinguish three objects:

- coefficient-recovery window
- reconstruction / benchmark window
- utilization level anchor

The Fordist-core window may be used as a coefficient-recovery or benchmark window if it is predeclared by S30.

It must not silently define normal utilization.

The preferred U.S. baseline level anchor is:

$$
\mu_{US,1973}=1
$$

Rationale:

1973 is treated as the U.S. full-capacity pinch year because it corresponds to the maximum capacity-utilization observation in the FRB utilization series used as external calibration evidence.

Therefore, the following is not the preferred baseline:

$$
\overline{\mu}_{1945-1973}=1
$$

That window-average normalization may be retained only as a diagnostic or robustness normalization, and it must be labeled as such.

S40 anchor registers must record:

- `country = US`
- `anchor_year = 1973`
- `anchor_value = 1`
- `anchor_variable = mu_t`
- `anchor_type = point_year_external_pinch`
- `anchor_source = FRB maximum utilization series`
- `anchor_role = level_normalization`
- `anchor_status = externally_declared`
- `diagnostic_window_average_anchor = FALSE`

---

## 9. US S50 role

`US_S50_theta_mu_profitability_corridor.R` should consume the reconstructed mu and theta objects.

Its purpose is to interpret:

`theta → mu → r`

This corresponds to the productive-capacity corridor. The process-tracing playbook defines this corridor as `theta → mu → r`, distinct from the recapitalization corridor `chi → k → g`.

S50 must not repair or re-anchor mu. If the S40 anchor is wrong, S40 must be patched upstream.

---

## 10. US S90 role

DOLS belongs mainly here.

`US_S90_dols_fragility_diagnostics.R` should include:

- lead-lag sensitivity
- DOLS grid tests
- window robustness
- collinearity / VIF checks
- known-break stress tests
- full-sample fragility checks

DOLS can reveal fragility. It should not define the main reconstruction.

---

## 11. US S99 role

`US_S99_results_package.R` should collect and export final outputs only after upstream objects are rebuilt.

Expected outputs:

- tables
- figures
- diagnostic summaries
- paper-facing result sheets
- advisor-facing figures

It should not silently recompute theta, Yp, mu, anchors, or profitability objects.

---

## 12. US locked memo statement

The US code batch is not promoted as-is.

It is recycled as follows:

- DOLS-era estimation scripts → S90 fragility diagnostics
- fullsample / FM / IM donor scripts → S30 estimator grid
- theta/mu graph scripts → S40 reconstruction + S99 figures
- profitability scripts → S50 corridor interpretation + S99 result package

The final US architecture must be FM-OLS-centered, IM-OLS-checked, DOLS-stressed, and rebuilt around `theta_tot`, not direct `theta_M`.

The final US S40 architecture must also follow the D03 level-anchor rule:

$$
\mu_{US,1973}=1.
$$

The Fordist-core window may remain a reconstruction or historical benchmark window, but it must not impose:

$$
\overline{\mu}_{1945-1973}=1
$$

as the preferred baseline normalization.
