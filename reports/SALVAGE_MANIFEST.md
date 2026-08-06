# reports/ — Salvage Manifest and Archive Record

**Date:** 2026-08-05
**Event:** `CH2_PAPER_FACING_SOURCE_SCOPING`

---

## 1. Binding paper-facing sources (three folders only)

These three folders are the single source of truth for every estimate in the Chapter 2
manuscript. Their `table_*.tex` fragments are `\input` directly by
`chapter2_paper/WP_Chapter2_1.0/`. No number may be hand-copied out of them.

| Folder | Chapter section | Specification |
|---|---|---|
| `US_Section31_IMOLS_Results/` | §4.2 | Specification A — aggregate capital $k^{\text{cap}}$ |
| `US_Section32_IMOLS_Results/` | §4.3 | Specification B — heterogeneous capital ($k^{\text{NRC}}$, $\kappa$) |
| `Chile_Section33_Peripheral_IMOLS_Results/` | §4.4 | Threshold CMPR IM-OLS — peripheral extension |

The `_legacy*` subfolders already present inside these three are left untouched.

---

## 2. Salvaged forward (used by the manuscript, not archived)

Nothing was physically moved: these artifacts already live in `output/`, which is their
governed location. What follows is the record of *which* ones the manuscript now depends on,
and which archived report first established them — so provenance stays traceable after the
source reports are archived.

### 2.1 Visual-first material (`umass-applied-econometrics` Rule B)

The manuscript has no non-parametric visualization preceding its parametric tables. Rule B
requires raw historical trends to be shown before the regressions that model them. These four
figures fill that gap and are wired into the draft:

| Figure | Purpose | Established by |
|---|---|---|
| `output/figures/us_capital_levels_loess.png` | US capital levels, LOESS-smoothed — raw trend before any parametric fit | `US_Capital_Composition_Integrated_Report/` |
| `output/figures/us_tau_regime_bands.png` | US capital-composition regime bands. **Note:** filename retains the deprecated `tau`; the object is $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$ per the `00S` notation lock, which retired $\tau_t$. Caption and label must use $\kappa$. | `US_Capital_Composition_Integrated_Report/` |
| `output/CL/S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY/fig_cl_capital_levels_loess.png` | Chile capital levels, LOESS-smoothed | `Chile_Capital_Composition_Integrated_Report/` |
| `output/CL/S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY/fig_cl_kappa_regime_bands.png` | Chile $\kappa$ regime bands | `Chile_Capital_Composition_Integrated_Report/` |

The US/Chile $\kappa$ pair also does comparative work for §5: it shows the same composition
object in both cases without a norm/deviation framing, which `00N_MAP.md` §5 forbids.

### 2.2 Appendix feedstock

| Appendix | Content | Archived source |
|---|---|---|
| **B** — Data construction | Wage-share source reconciliation and provenance | `US_Wage_Share_Data_Provenance_Note/` |
| **B** — Data construction | GPIM survival, initialization, deflator, and price-seed audits | `maintenance/` (left in place; already self-organizing by date) |
| **C** — Permutation space | Integration-order verdict table (Rule G) | `US_Integration_Order_Appendix/` |
| **E** — Parameter stability | Hansen $L_c$, CUSUM, Gregory–Hansen audit output | `US_Section31_Stability_Audit/` |

---

## 3. Archived

Each folder below had its contents moved into a `99_archive/` subfolder **inside that same
folder**. Nothing left `reports/`; nothing was deleted. The move is reversible.

`Chile_BOP_Binding_Import_ECT_Report` · `Chile_Capital_Composition_Integrated_Report` ·
`Chile_Structural_Break_VECM_Report` · `US_Baseline_IMOLS_Capital_Aggregation_Report` ·
`US_Capital_Composition_Integrated_Report` · `US_IPP_Share_Integration_Report` ·
`US_Integration_Order_Appendix` · `US_Section31_Stability_Audit` ·
`US_Section33_IMOLS_Results` · `US_SpecB5_Theory_Specification_Results_Report` ·
`US_SpecificationB_IMOLS_Capital_Disaggregation_Report` ·
`US_Wage_Share_Data_Provenance_Note` · `US_Wage_Share_Integration_Report` ·
`report_K_cointegration` · `report_K_cointegration_single_eq` · `report_S31B_2026-06-24` ·
`report_gpim_shaikh_comparison_2026-06-25` ·
`report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01` ·
`report_validation_SofT_dataset_2026-07-01`

`maintenance/` was **not** archived — it is a dated container of GPIM provenance audits that
already organizes itself, and it remains live feedstock for Appendix B.

### 3.1 Note on `US_Section33_IMOLS_Results/`

This folder is misleadingly named. It contains `us_section32_imols_results.*` build artifacts
alongside `us_section33_imols_results.*`, plus five table fragments
(`table_specB_part1.tex`, `table_specB_set{1,2}.tex`, `table_spec_set_{1,2}_part1.tex`) that
duplicate the orphaned fragments in `US_Section32_IMOLS_Results/`. It is a superseded working
copy of the Specification B work, not a Section 3.3 result set — Section 3.3 is Chile. Archived
in full.

Its `table_specB_part1.tex` does contain the only written-out **Specification B model
crosswalk** (B1, B3, B3e, B4, B4e with their estimating equations) found anywhere in the tree.
If §4.3 needs a crosswalk table, that fragment is where the equations already exist — but it
also contains literal `nan` cells and reports t-statistics where the active tables report
standard errors, so it cannot be `\input` as-is.
