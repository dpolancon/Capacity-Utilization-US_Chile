---
type: pointer
status: active
depends_on:
  - chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/ch2_sec4_3_3.md
  - chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/ch2_sec4_3_4.md
stage_scope: paper-facing
country: US
last_updated: 2026-08-05
updated_by: CH2_PAPER_FACING_SOURCE_SCOPING
layer: pointer
role: figure-location-record
stage: paper-assembly
tags:
  - chapter2/paper-facing
  - chapter2/figures
scope: chapter2
priority: reference
---

# Figure locations — §4.3 Specification B

The Specification B figures used to sit in this folder. `AGENTS.md` reserves `output/`
for quantitative artifacts (`.png`, `.pdf`, `.csv`) and forbids keeping them elsewhere,
so they now live under `output/`. The drafts in this folder still reference them by their
markdown image wire; `compile_chapter2.py` resolves the repo-relative path to the
manuscript's `../../` include at build time.

| Figure | Path | Referenced by |
|---|---|---|
| Aggregate transformation elasticity, Harrodian knife-edge | `output/US/S61_SECTION32_IMOLS/figures/fig_specB_aggregate_elasticity_knife_edge.{png,pdf}` | [[ch2_sec4_3_4]] |
| Aggregate transformation elasticity, zoomed | `output/US/S61_SECTION32_IMOLS/figures/fig_specB_aggregate_elasticity_zoomed.{png,pdf}` | [[ch2_sec4_3_4]] |
| Reconstructed capacity utilization $\hat{\mu}_t$, Specification B | `output/US/S61_SECTION32_IMOLS/figures/fig_specB_reconstructed_capacity_utilization.{png,pdf}` | [[ch2_sec4_3_3]] |

Both `.png` and `.pdf` are kept. The manuscript includes the `.png`; the `.pdf` is the
vector original for any later resizing.

## Related figure locations

Other figures the chapter draws on, recorded here so §4.3 has one place to look:

| Figure | Path | Purpose |
|---|---|---|
| Transformation elasticity and overaccumulation regime | `output/US/S60_CAPACITY_RECOVERY/figures/fig6_transformation_elasticity_overaccumulation.png` | §4.2, Specification A |
| Reconstructed US capacity utilization | `output/US/S60_CAPACITY_RECOVERY/figures/fig4_reconstructed_capacity_utilization.png` | §4.2, Specification A |
| US capital levels, LOESS | `output/figures/us_capital_levels_loess.png` | §4.1 visual-first (Rule B) |
| US capital composition regime bands | `output/figures/us_tau_regime_bands.png` | §4.1 visual-first. Filename retains the retired `tau`; the object is $\kappa_t$ per [[00S_Chapter2_Symbology_and_Notation_Lock]] |
| Chile capital levels, LOESS | `output/CL/S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY/fig_cl_capital_levels_loess.png` | §4.1 visual-first |
| Chile $\kappa$ regime bands | `output/CL/S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY/fig_cl_kappa_regime_bands.png` | §4.1 visual-first |

See also `reports/SALVAGE_MANIFEST.md` for the provenance of the last four.
