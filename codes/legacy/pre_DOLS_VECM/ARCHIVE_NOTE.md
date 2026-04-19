# Archive Note
**Date:** 2026-04-13

These scripts implement Johansen RRR / VECM identification superseded by DOLS-based θ identification (EI framework, April 2026). Do not modify. Archived for reproducibility.

## Archived files (moved from codes/stage_a/us/)
- `27_vecm_split_wk_exog.R` — VECM with split sample, wk exogenous
- `28_vecm_trend_and_dols.R` — Johansen VECM const vs trend + DOLS comparison
- `29_dols_robustness.R` — DOLS robustness checks
- `35_theta_omega_plot_us.R` — θ(ω) plotting utilities
- `37_agnostic_absolute_us.R` — Agnostic Johansen estimation
- `39_restricted_vecm_absolute_us.R` — Restricted VECM
- `39b_rank_under_restriction.R` — Rank test under restrictions
- `40_test_cv1_omega0_absolute_us.R` — CV1 test at ω=0
- `41_test_beta_restrictions_all_cvs.R` — Beta restrictions across all CVs
- `42_rank1_check.R` — Rank-1 check

The following data preparation scripts remain in place (not moved):
- `codes/stage_a/chile/10_data_prep_us.R`
- `codes/stage_a/chile/20_integration_tests.R`
- `codes/stage_b/us/10_build_dataset_us.R`
- `codes/utils/00_utils.R`
