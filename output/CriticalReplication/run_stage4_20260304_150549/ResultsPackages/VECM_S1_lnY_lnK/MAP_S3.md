# Stage 3 Results Package — VECM S1 (lnY, lnK), r=1

- Base source: `output/CriticalReplication/Exercise_c_VECM_S1_r1`
- Package output: `output/CriticalReplication/run_stage4_20260304_150549/ResultsPackages/VECM_S1_lnY_lnK`

## What to read first (advisor ordering)
1) `tables/TAB_S3_confinement_winners_by_branch.(csv|tex)`
2) `tables/TAB_S3_metric_summary_by_branch.(csv|tex)`
3) `figs/FIG_S3_frontier_logLik_vs_k_total.png`
4) Branch-level surfaces already in Exercise C folders (theta / stability / dBIC)

## Outputs created by this package
- `tables/DATA_S3_specification_universe.(csv|tex)`
- `tables/TAB_S3_confinement_winners_by_branch.(csv|tex)`
- `tables/TAB_S3_metric_summary_by_branch.(csv|tex)` (if metrics exist)
- `figs/FIG_S3_frontier_logLik_vs_k_total.png` (if columns exist)
- `figs/FIG_S3_frontier_logLik_vs_ICOMP_penalty.png` (optional)
- `figs/FIG_S3_frontier_logLik_vs_RICOMP_penalty.png` (optional)

## Notes
- This script does not re-estimate any model. It packages computed outputs only.
- Column harmonization is conservative (no overwrites; creates canonical aliases where missing).
