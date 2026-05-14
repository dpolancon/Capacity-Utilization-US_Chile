# US S40 Review and Figures Report

## 1. Purpose

This pass reviews and visualizes the existing S40 restricted B1 reconstruction outputs. It does not reconstruct new objects, estimate new models, alter S40 outputs, compute profitability, or move toward S50.

All figures are labeled as restricted B1 under fragility.
The anchor check uses a reconstruction-consistency tolerance rather than an exact-arithmetic tolerance. The bounded mu_t check is a diagnostic guardrail against bad anchoring, coding errors, or explosive paths; it is not a theory restriction.

## 2. Required checks

| check_id | required_condition | observed_value | passed | tolerance | notes |
| --- | --- | --- | --- | --- | --- |
| fragility_flag_true | fragility_flag = TRUE | TRUE | TRUE |  | Checked path tables, registers, and reconstruction manifest. |
| s40_admissibility_status | s40_admissibility_status = admissible_restricted_b1_under_fragility | admissible_restricted_b1_under_fragility | TRUE |  |  |
| dols_reconstruction_basis_false | dols_reconstruction_basis = FALSE | FALSE | TRUE |  |  |
| dols_veto_false | dols_veto = FALSE | FALSE | TRUE |  |  |
| mu_formula | mu_formula = Y_real / Yp | Y_real / Yp | TRUE |  |  |
| anchor_window | anchor window = fordist_core | fordist_core | TRUE |  |  |
| anchor_years | anchor years = 1945-1973 | 1945-1973 | TRUE |  |  |
| anchor_mean_mu | anchor mean(mu_t) = 1 within tolerance | 1 | TRUE |  0.0001 |  |
| all_mu_finite | all mu_t values finite | 96/96 finite | TRUE |  |  |
| mu_nonpathological | diagnostic guardrail: 0 < mu_t < 2.5 | range=0.641916073600041-1.23408248535147 | TRUE |  | Diagnostic guardrail only; not a theoretical restriction on utilization. |
| all_yp_positive_finite | all Yp values positive and finite | 96/96 positive finite | TRUE |  |  |
| no_profitability_variables | no profitability variables | profitability_columns_detected=FALSE; manifest_profitability_computed=FALSE | TRUE |  |  |
| no_chile_outputs | no Chile outputs | manifest_chile_outputs_touched=FALSE | TRUE |  |  |
| hard_prohibitions_violated | hard_prohibitions_violated = FALSE | FALSE | TRUE |  |  |

## 3. Failed checks

- none

## 4. Summaries

### mu_t

| run_timestamp | variable | year_min | year_max | n | min | q25 | mean | median | q75 | max | sd | anchor_window | anchor_year_start | anchor_year_end | anchor_mean_mu | fragility_flag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-05-14 17:16:04 -04 | mu_t |    1929 |    2024 |      96 | 0.641916 | 0.87841 | 0.936076 | 0.949855 | 0.995678 | 1.23408 | 0.103929 | fordist_core |    1945 |    1973 |       1 | TRUE |

### theta_tot

| run_timestamp | variable | year_min | year_max | n | min | q25 | mean | median | q75 | max | sd | fragility_flag | figure_scope |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-05-14 17:16:04 -04 | theta_tot |    1929 |    2024 |      96 | 0.834775 | 0.838186 | 0.839783 | 0.839221 | 0.840798 | 0.84507 | 0.00235334 | TRUE | theta_tot_only |

### Anchor window

| run_timestamp | anchor_window | anchor_year_start | anchor_year_end | observations | mean_mu_t | min_mu_t | max_mu_t | sd_mu_t | mean_Y_real | mean_Yp | mean_theta_tot | anchor_tolerance | anchor_mean_passed | fragility_flag |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-05-14 17:16:04 -04 | fordist_core |    1945 |    1973 |      29 |       1 | 0.922163 | 1.08981 | 0.0355445 | 2429993 | 2429338 | 0.838834 |  0.0001 | TRUE | TRUE |

## 5. Hard prohibitions

- Hard prohibition violated: FALSE
- No new model was estimated.
- No S40 reconstruction output was modified.
- DOLS was not used as a reconstruction basis.
- Profitability was not computed.
- Chile and comparative outputs were not touched.

## 6. Output files

| file | path |
| --- | --- |
| us_s40_review_checks.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/us_s40_review_checks.csv |
| us_s40_mu_summary.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/us_s40_mu_summary.csv |
| us_s40_theta_summary.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/us_s40_theta_summary.csv |
| us_s40_anchor_window_summary.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/us_s40_anchor_window_summary.csv |
| US_S40_review_and_figures_report.md | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/US_S40_review_and_figures_report.md |
| fig_us_s40_mu_path.png | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/fig_us_s40_mu_path.png |
| fig_us_s40_mu_path.pdf | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/fig_us_s40_mu_path.pdf |
| fig_us_s40_y_ycapacity_path.png | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/fig_us_s40_y_ycapacity_path.png |
| fig_us_s40_y_ycapacity_path.pdf | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/fig_us_s40_y_ycapacity_path.pdf |
| fig_us_s40_theta_tot_path.png | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/fig_us_s40_theta_tot_path.png |
| fig_us_s40_theta_tot_path.pdf | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_review_and_figures/fig_us_s40_theta_tot_path.pdf |
