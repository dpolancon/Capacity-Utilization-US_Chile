# US S40 Theta_tot and Mu Reconstruction Report

## 1. Purpose

S40 reconstructs theta_tot, productive capacity, and mu_t from the already-adjudicated S30 restricted B1 pathway. It is a reconstruction stage, not an estimator stage.

S40 proceeds as a restricted B1 reconstruction under fragility, not as a clean benchmark promotion.

## 2. Upstream S30 gate

| check | value |
| --- | --- |
| candidate_spec_id | SPEC_B1_WAGE_BASELINE |
| tier1_pass | TRUE |
| s40_gate | pass_restricted_fragility_flag |
| non_b1_specs_promoted | FALSE |
| no_s40_code | TRUE |
| no_mu_computation | TRUE |
| no_chile_outputs | TRUE |

## 3. Input panel

- Detected panel path: C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/US/us_s20_admissibility_panel.csv
- Detection method: S30 run manifest item `input_panel`.

## 4. Reconstruction basis

FM-OLS is the main reconstruction basis. IM-OLS is carried as robustness metadata. DOLS is carried only as fragility/stress metadata and does not define theta_tot, Yp, mu_t, anchoring, or admissibility.

| field | value |
| --- | --- |
| main reconstruction estimator | FM_OLS |
| robustness metadata estimator | IM_OLS |
| fragility/stress metadata estimator | DOLS |
| basis specification | SPEC_B1_WAGE_BASELINE |
| basis window | fordist_core (1945-1973) |
| FM-OLS const | 1.82034175009358 |
| FM-OLS k_t | 0.896535271845096 |
| FM-OLS omega_k_t | -0.0911274319814765 |

## 5. Reconstruction sequence

The B1 reduced-form relation `y_t ~ k_t + omega_k_t` is transformed into `theta_tot = beta_k_t + beta_omega_k_t * omega_t`. Productive capacity is then reconstructed from the FM-OLS B1 fitted productive-capacity path, level anchored to the externally locked 1973 point-year pinch, and mu_t is derived as `Y_real / Yp`.

## 6. Anchor

| reconstruction_window_id | reconstruction_year_start | reconstruction_year_end | anchor_type | anchor_variable | anchor_year | anchor_value | anchor_source | anchor_status | anchor_scale_factor | anchor_check_mu_t |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| fordist_core |    1945 |    1973 | point_year_external_pinch | mu_t |    1973 |       1 | externally_locked_by_D03_S40_contract | externally_locked | 1.01589 |       1 |

- Normalization rule: Scale FM-OLS B1 unanchored productive capacity by Y_real_1973 / Yp_unanchored_1973 so mu_t,1973 = 1.
- Rationale: The utilization anchor is externally locked by the D03/S40 contract. The S30 benchmark window supplies the reconstruction coefficients only; it is not the utilization anchor.

## 7. Fragility

| s30_gate | fragility_flag | s30_tier2_evidence_class | dols_fragility_flag | dols_contradiction_windows | dols_veto_disabled | s40_admissibility_status |
| --- | --- | --- | --- | --- | --- | --- |
| pass_restricted_fragility_flag | TRUE | mixed | TRUE | fordist_core; pre_1974_alt_1947_1974 | TRUE | admissible_restricted_b1_under_fragility |

## 8. Hard prohibitions

| prohibition | violated |
| --- | --- |
| new cointegrating relation estimated | FALSE |
| estimator grid expanded | FALSE |
| DOLS used as reconstruction basis | FALSE |
| non-B1 specifications promoted | FALSE |
| profitability computed | FALSE |
| Chile outputs touched | FALSE |
| comparative outputs created | FALSE |
| threshold-FGLS activated | FALSE |
| theta_t^M directly estimated | FALSE |
| mu_t identified by residual | FALSE |
| silent anchor choice | FALSE |

## 9. Output files

| output | path |
| --- | --- |
| us_s40_theta_tot_path.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_theta_tot_mu_reconstruction/us_s40_theta_tot_path.csv |
| us_s40_productive_capacity_path.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_theta_tot_mu_reconstruction/us_s40_productive_capacity_path.csv |
| us_s40_mu_path.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_theta_tot_mu_reconstruction/us_s40_mu_path.csv |
| us_s40_anchor_register.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_theta_tot_mu_reconstruction/us_s40_anchor_register.csv |
| us_s40_fragility_register.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_theta_tot_mu_reconstruction/us_s40_fragility_register.csv |
| us_s40_reconstruction_manifest.csv | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_theta_tot_mu_reconstruction/us_s40_reconstruction_manifest.csv |
| US_S40_theta_tot_mu_reconstruction_report.md | C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S40_theta_tot_mu_reconstruction/US_S40_theta_tot_mu_reconstruction_report.md |
