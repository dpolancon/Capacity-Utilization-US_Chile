---
type: code_recycling_memo
status: active
layer: implementation_design
design_role: chile_code_recycling_and_stage_mapping
scope: chapter2_results_repo
repo: Capacity-Utilization-US_Chile
country: CL
stage_scope:
  - S10
  - S20
  - S30
  - S40
  - S50
  - S60
  - S90
  - S99
related_to:
  - M10_Empirical_Identification_Framework
  - D03_capacity_utilization_level_anchor_pinch_year_protocol
  - C03-REPO_STRUCTURE
  - R02_DOLS_reconstruction_dilemma
  - R04_FMOLS_structural_preservation
  - R06_IMOLS_integration_ladder_reconstruction
  - R07_FGLS_threshold_cointegration_admissibility
  - R08_threshold_break_diagnostics_to_FGLS
anchor_protocol_governed_by: D03_capacity_utilization_level_anchor_pinch_year_protocol
anchor_protocol_country: CL
anchor_protocol_preferred_year: 1980
anchor_protocol_condition: mu_CL_1980_equals_1
anchor_protocol_type: point_year_historical_pinch
anchor_protocol_source: Ffrench_Davis_2018_full_capacity_reference
anchor_protocol_role: level_normalization
ect_regime_classifier_allowed: false
window_average_anchor_allowed_as_baseline: false
created: 2026-05-06
updated: 2026-06-02
---

# Memo 2 — Chile Code Recycling Map

## 1. Status

The Chile code batch should be treated as **recyclable staged material**, not as definitive production code.

The current Chile scripts contain useful machinery:

- source-of-truth panel construction;
- break and significance diagnostics;
- preliminary mu/theta reconstruction routines;
- profitability analysis;
- capacity-utilization diagnostics;
- class-struggle and distribution diagnostics;
- result-package exporters;
- ECT audits;
- short-run and very-short-run diagnostic variants.

But they were not originally organized under the current Chapter 2 stage architecture.

The Chile side must be rebuilt around the same general sequence as the US side, with one crucial addition: Chile also requires the peripheral external-mechanization and balance-of-payments constraint layer.

The current architecture is:

- S10 = source-of-truth panel;
- S20 = composition, mechanization, periodization, and admissibility;
- S30 = long-run transformation coefficient recovery;
- S40 = theta_tot, productive capacity, and mu reconstruction;
- S50 = productive-capacity and profitability corridor interpretation;
- S60 = recapitalization and peripheral external-constraint mechanism;
- S90 = diagnostics and robustness;
- S99 = result-package export.

The Chile implementation must preserve the estimator hierarchy:

- FM-OLS = main reconstruction estimator;
- IM-OLS = robustness estimator;
- DOLS = fragility / stress diagnostic.

It must also preserve the level-anchor protocol governed by:

`04_data_measurement/D03_capacity_utilization_level_anchor_pinch_year_protocol.md`

For Chile, the preferred baseline level anchor is:

$$
\mu_{CL,1980}=1
$$

using 1980 as the full-capacity pinch year associated with Ffrench-Davis (2018).

This anchor is a level-normalization rule.

It is not:

- an estimated break date;
- an ECT-regime classifier;
- a threshold trigger;
- proof that utilization converges to one;
- a profitability result.

---

## 2. Main problem with the current Chile batch

The old Chile logic sometimes moves too directly from source data or preliminary reconstruction into mu, theta, profitability, or regime diagnostics.

The inadmissible shortcut is:

- source panel
- preliminary theta or ECT object
- mu reconstruction
- profitability interpretation
- regime classification

That is too direct.

The new logic must be:

- source-of-truth Chile panel
- composition and mechanization construction
- external-constraint and periodization admissibility
- reduced-form coefficient recovery
- theta_tot reconstruction
- Yp reconstruction
- point-year level anchoring
- mu derivation
- theta_M interpretation
- profitability corridor
- recapitalization / external-constraint corridor
- diagnostics and result package

This matters because Chapter 2 distinguishes what is identified from what is reconstructed.

The empirical model identifies `theta_tot`.

The machinery-specific object `theta_M` is interpreted through composition, distribution, and external-constraint structure. It is not directly estimated.

It also matters because the reconstructed utilization path requires an explicit level anchor. Under D03, the Chile baseline anchor is:

$$
\mu_{CL,1980}=1
$$

not a window-average normalization and not an ECT-derived regime point.

---

## 3. Required Chile target sequence

The Chile code should be reconstructed into the following flat sequence:

- `CL_S10_source_of_truth_panel.R`
- `CL_S20_composition_mechanization_external_constraint.R`
- `CL_S20_periodization_stability_admissibility.R`
- `CL_S20_external_constraint_threshold_index.R`
- `CL_S30_transformation_relation_fmols.R`
- `CL_S30_transformation_relation_imols.R`
- `CL_S30_transformation_relation_dols_fragility.R`
- `CL_S40_theta_tot_mu_reconstruction.R`
- `CL_S50_thetaM_corridor_interpretation.R`
- `CL_S50_theta_mu_profitability_corridor.R`
- `CL_S60_peripheral_mechanization_constraint.R`
- `CL_S60_bop_recapitalization_corridor.R`
- `CL_S90_threshold_dummy_fgls_admissibility.R`
- `CL_S99_results_package.R`

This is a flat `codes/` architecture.

No country folders inside `codes/`.

---

## 4. Chile script recycling table

| Current script | Recycling status | New target | Treatment |
|---|---|---|---|
| `CL_00_source_of_truth_chile.R` | Promote / rebuild as core donor | `CL_S10_source_of_truth_panel.R` | Use as the canonical donor for the Chile source-of-truth panel. It should not run econometrics or reconstruct utilization. |
| `CL_01_stage1_mu.R` | Recycle and split | `CL_S20`, `CL_S30`, `CL_S40` components | Split data preparation, admissibility, coefficient recovery, and reconstruction. Do not preserve a direct jump to mu. |
| `CL_01_stage1_mu_source_truth_break_sig_STAGE1_ONLY.R` | Recycle into admissibility | `CL_S20_periodization_stability_admissibility.R` | Use break/significance material as periodization and stability evidence. Do not let it define utilization by itself. |
| `CL_01_stage1_mu_source_truth_break_sig_full.R` | Recycle into extended admissibility | `CL_S20_periodization_stability_admissibility_full.R` | Use only as an expanded diagnostic source. Keep separate from S40 reconstruction. |
| `CL_03_results_package_mu_theta_wsh.R` | Rebuild / split | `CL_S40_theta_tot_mu_reconstruction.R` and `CL_S99_capacity_results_package.R` | Preserve output logic, but rebuild theta/mu around theta_tot and D03 anchor rule: `mu_CL,1980 = 1`. |
| `CL_04_results_presentation.R` | Merge into export layer | `CL_S99_results_presentation.R` | Presentation only. It must consume upstream objects and not recompute them silently. |
| `CL_05_profitability_analysis_core.R` | Keep downstream | `CL_S50_theta_mu_profitability_corridor.R` | Strong analytical donor. Must consume reconstructed theta_tot, Yp, and mu from S40. |
| `CL_05_profitability_analysis_core_BENCH.R` | Keep as stress / benchmark | `CL_S90_profitability_benchmark_stress.R` | Diagnostic only unless promoted through a separate result-package rule. |
| `CL_06_results_package_profitability.R` | Keep downstream exporter | `CL_S99_profitability_results_package.R` | Export only. No silent reconstruction. |
| `CL_07_results_package_profitability_diagnostics.R` | Diagnostic exporter | `CL_S90_profitability_diagnostics.R` | Keep as diagnostic result package. |
| `CL_08_results_package_profitability_diagnostics_shortrun.R` | Diagnostic exporter | `CL_S90_profitability_short_run_diagnostics.R` | Short-run diagnostic only. |
| `CL_09_results_package_profitability_diagnostics_very_shortrun.R` | Diagnostic exporter | `CL_S90_profitability_very_short_run_diagnostics.R` | Very-short-run diagnostic only. |
| `CL_10_class_struggle_diagnostic.R` | Recycle as distribution diagnostic | `CL_S50_distribution_conflict_diagnostic.R` or `CL_S90_distribution_stress.R` | Useful for interpretation, but not a substitute for S40 reconstruction. |
| `CL_11_dys_diagnostic_package.R` | Diagnostic package donor | `CL_S90_dysfunctionality_diagnostic_package.R` | Diagnostic only. |
| `CL_12_capacity_utilization_diagnostic.R` | Diagnostic donor | `CL_S90_capacity_utilization_diagnostic.R` | Use to evaluate reconstructed mu. It should not define mu. |
| `CL_12_capacity_utilization_diagnostic_rebased2010.R` | Diagnostic donor | `CL_S90_capacity_utilization_rebase2010_diagnostic.R` | Rebase diagnostic only. Not baseline. |
| `CL_12_capacity_utilization_diagnostic_rebased2010_v2.R` | Diagnostic donor | `CL_S90_capacity_utilization_rebase2010_diagnostic_v2.R` | Rebase diagnostic only. Not baseline. |
| `CL_A_stage1_ECT_audit.R` | Diagnostic only | `CL_S90_ect_audit_not_regime_classifier.R` | ECT audits cannot activate regimes or define utilization anchors. |
| `CL_B_stage2_mu_Diagnostic.R` | Diagnostic only | `CL_S90_mu_reconstruction_diagnostic.R` | Review reconstructed mu; do not reconstruct it as baseline. |
| `chile_class_struggle_astorga_weisskopf_v2.R` | Recycle as distribution conflict donor | `CL_S50_distribution_conflict_astorga_weisskopf.R` | Interpretive donor for distribution conflict, not core reconstruction. |

---

## 5. Chile S10 role

`CL_S10_source_of_truth_panel.R` should build the canonical Chile panel.

Its function should be limited to data construction.

It should not:

- estimate the transformation relation;
- reconstruct theta_tot;
- reconstruct Yp;
- derive mu;
- compute profitability as an interpretive result;
- classify regimes;
- activate FGLS;
- generate final paper-facing figures.

Expected objects include:

- `year`
- real output;
- gross real capacity-relevant capital;
- machinery and non-machinery capital where available;
- wage-share or distribution variables;
- investment-composition variables;
- price and deflator variables;
- external-constraint candidates;
- profitability inputs for downstream use.

S10 must preserve register discipline.

Capacity reconstruction belongs to the gross-real capacity register.

Profitability belongs to the monetary valuation register.

---

## 6. Chile S20 role

Chile requires a stronger S20 layer than the U.S. because the peripheral external-mechanization constraint is not optional.

S20 should construct or validate:

$$
s_t=\frac{K_t^M}{K_t}
$$

$$
\varphi_t=\frac{I_t^M}{I_t^A}
$$

$$
\mathcal{E}_t=\Lambda_t\varphi_t
$$

where:

- `s_t` is the machinery share of the relevant capacity stock;
- `varphi_t` is the machinery share of accumulation;
- `Lambda_t` is the shadow cost or proxy for foreign-exchange pressure;
- `mathcal{E}_t` is the external mechanization wedge.

S20 should also:

- define candidate historical windows;
- check integration order;
- check deterministic components;
- check structural breaks;
- check parameter stability;
- evaluate threshold candidates;
- prepare admissible samples for S30;
- log what can and cannot be interpreted as stable.

S20 may prepare the external-constraint threshold object.

It does not derive utilization.

It does not choose the utilization level anchor.

---

## 7. Chile S30 role

S30 estimates the reduced-form long-run transformation relation.

Estimator roles:

- FM-OLS = main;
- IM-OLS = robustness;
- DOLS = fragility / stress.

Chile S30 must begin from the corrected A00 accumulated-index baseline before escalating to composition or external-constraint surfaces.

The hierarchy is:

1. A00 accumulated-index baseline:

```text
q_omega_1
q_omega_3
q_omega_5
```

meaning:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s.
$$

2. A03 ME/NRC composition escalation, where machinery and non-machinery capital shares condition the aggregate relation.

3. A04 external/peripheral realization escalation, where foreign-exchange, balance-of-payments, and peripheral mechanization variables are diagnostic or escalated realization variables.

Chile must not begin directly from composition terms, threshold surfaces, or external-constraint terms as if they were baseline replacements. A04/external variables can diagnose or escalate the A00/A03 relation, but they do not replace the corrected A00 accumulated-index baseline.

For Chile, the escalated S30 equation may allow composition-weighted transformation logic after the A00 baseline is declared.

The relevant interaction surface may include:

$$
k_t
$$

$$
(s_t-\bar{s})k_t
$$

$$
\omega_t(s_t-\bar{s})k_t
$$

$$
D_t(\hat{\gamma})(s_t-\bar{s})k_t
$$

$$
D_t(\hat{\gamma})\omega_t(s_t-\bar{s})k_t
$$

The point is not to estimate:

$$
\theta_t^M
$$

directly.

The point is to estimate coefficients that identify the behavior of:

$$
\theta_t^{tot}
$$

S30 may adjudicate whether S40 can open.

S30 does not choose the utilization level anchor.

---

## 8. Chile S40 role

`CL_S40_theta_tot_mu_reconstruction.R` should take the admissible S30 coefficient output and reconstruct:

- `theta_tot`
- `Yp`
- `mu`

This is where productive capacity and utilization are derived.

It must not treat residuals as primitive utilization.

The correct logic is:

- estimated reduced-form relation;
- theta_tot;
- reconstructed Yp;
- explicit point-year level anchor;
- derived mu.

### S40 anchor rule

Chile S40 must distinguish three objects:

- coefficient-recovery window;
- reconstruction / benchmark window;
- utilization level anchor.

The preferred Chile baseline level anchor is:

$$
\mu_{CL,1980}=1
$$

Rationale:

1980 is treated as the Chile full-capacity pinch year following the full-capacity interpretation associated with Ffrench-Davis (2018).

Therefore, the anchor is:

- country-specific;
- externally motivated;
- point-year based;
- a level-normalization rule.

It is not:

- an estimated break date;
- an ECT-regime classifier;
- a threshold trigger;
- a direct profitability result.

Window-average normalization may be retained only as a diagnostic or robustness normalization, and it must be labeled as such.

S40 anchor registers must record:

- `country = CL`
- `anchor_year = 1980`
- `anchor_value = 1`
- `anchor_variable = mu_t`
- `anchor_type = point_year_historical_pinch`
- `anchor_source = Ffrench-Davis 2018 full-capacity reference`
- `anchor_role = level_normalization`
- `anchor_status = externally_declared`
- `ect_regime_classifier = FALSE`
- `diagnostic_window_average_anchor = FALSE`

---

## 9. Chile S50 role

`CL_S50_theta_mu_profitability_corridor.R` should consume the reconstructed mu and theta objects.

Its purpose is to interpret:

`theta → mu → r`

This is the productive-capacity corridor.

S50 should:

- interpret theta_tot behavior;
- infer machinery-channel behavior;
- evaluate wage-share conditioning;
- connect utilization to profitability;
- organize the productive-capacity corridor.

S50 must not repair or re-anchor mu.

If the S40 anchor is wrong, S40 must be patched upstream.

---

## 10. Chile S60 role

S60 handles the recapitalization and peripheral external-constraint corridor.

The recapitalization corridor is:

`chi → k → g`

For Chile, S60 must also handle the external mechanization wedge:

$$
\mathcal{E}_t=\Lambda_t\varphi_t
$$

where:

$$
\varphi_t=\frac{I_t^M}{I_t^A}
$$

and `Lambda_t` is the shadow cost or proxy for foreign-exchange pressure.

Expected scripts:

- `CL_S60_peripheral_mechanization_constraint.R`
- `CL_S60_bop_recapitalization_corridor.R`

S60 does not replace S40.

It interprets whether profitability and surplus are translated into renewed accumulation and growth under external constraint.

---

## 11. Chile S90 role

S90 contains diagnostics, robustness, and stress tests.

It may include:

- DOLS fragility checks;
- lead-lag sensitivity;
- VIF and collinearity checks;
- window sensitivity;
- break versus threshold diagnostics;
- threshold significance;
- weak-identification checks;
- FGLS admissibility;
- bootstrap or sup-Wald procedures where required;
- ECT audits;
- mu reconstruction diagnostics.

S90 cannot override S20.

S90 cannot define the S40 utilization level anchor.

Threshold-FGLS belongs only after threshold behavior is independently justified.

ECT diagnostics cannot classify regimes by themselves.

---

## 12. Chile S99 role

`CL_S99_results_package.R` should collect and export final outputs only after upstream objects are rebuilt.

Expected outputs:

- tables;
- figures;
- diagnostic summaries;
- paper-facing result sheets;
- advisor-facing figures;
- reproducibility manifests.

S99 should not silently recompute theta, Yp, mu, anchors, profitability, or regime objects.

---

## 13. Chile locked memo statement

The Chile code batch is not promoted as-is.

It is recycled as follows:

- source panel scripts → S10 source-of-truth panel;
- break/significance scripts → S20 admissibility and periodization;
- preliminary theta/mu scripts → S30/S40 split;
- profitability scripts → S50 corridor interpretation and S99 result package;
- ECT and mu diagnostic scripts → S90 diagnostics;
- class-struggle scripts → S50 interpretation or S90 stress diagnostics.

The final Chile architecture must be FM-OLS-centered, IM-OLS-checked, DOLS-stressed, and rebuilt around `theta_tot`, not direct `theta_M`.

The final Chile S40 architecture must also follow the D03 level-anchor rule:

$$
\mu_{CL,1980}=1.
$$

This is a point-year full-capacity anchor associated with Ffrench-Davis (2018). It is not an estimated break date, not an ECT-regime classifier, and not a threshold trigger.
