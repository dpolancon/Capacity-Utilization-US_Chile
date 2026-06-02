# US S31 Estimation Tables Report

Run timestamp: 2026-06-02 13:41:24 -04

## 1. Purpose of S31

S31 is a reporting/export layer for human review of S30 estimates. S31 does not estimate new models. S31 does not adjudicate S30. S31 exports S30 estimates for human adjudication.

## 2. Inputs Consumed

- s30_estimator_grid: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_estimator_grid.csv`
- s30_specification_register: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_specification_register.csv`
- s30_run_manifest: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_run_manifest.csv`
- s30_window_stability_summary: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_window_stability_summary.csv`
- s30_rolling_coefficients: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/us_s30_rolling_coefficients.csv`
- s30_report: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S30_transformation_relation/US_S30_transformation_relation_report.md`
- s20_admissibility_panel: `C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/US/us_s20_admissibility_panel.csv`
- s20_candidate_window_register: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S20_composition_admissibility/us_s20_candidate_window_register.csv`
- s20_window_admissibility_summary: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S20_composition_admissibility/us_s20_window_admissibility_summary.csv`
- s20_report: `C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S20_composition_admissibility/US_S20_admissibility_summary.md`

## 3. Included and Excluded Windows

- Included main S31 windows: full_long_sample, pre_1974, post_1973, fordist_core, bridge_1940_1978, pre_1974_alt_1940_1973, pre_1974_alt_1947_1974
- Excluded diagnostic/event/predecessor windows: post_1974_tight, post_1974_support, prefordist_core_1929_1944

## 4. A00 Baseline Table Contents

The A00 baseline table includes only SPEC_B1_WAGE_BASELINE: y_t ~ k_t + omega_k_t. Its implied mapping is theta_A00_t = beta_k + beta_omega_k * omega_t. SPEC_B0_CAPITAL_ONLY is not treated as the Chapter 2 baseline.

## 5. A03 Proxy-Escalation Table Contents

The A03 proxy table includes SPEC_C1_COMPOSITION_STOCK and SPEC_C2_FULL_COMPOSITION. C1 reports y_t ~ k_t + omega_k_t + s_proxy_k_t. C2 reports y_t ~ k_t + omega_k_t + s_proxy_k_t + omega_s_proxy_k_t. They are composition-proxy escalation evidence, not baseline replacements.

## 6. Preferred Asymmetric ME/NRC Specification

The preferred asymmetric ME/NRC A03 specification is absent from current S30 estimates. Current S30 contains only A03 composition-proxy escalation specifications based on Tier-B ME/NRC component proxies. These are useful proxy/escalation evidence, not direct identification of the asymmetric NRC-envelope and ME-distribution mechanism.

## 7. Diagnostic Appendix Contents

The diagnostic appendix exports SPEC_D1_CURRENT_COST_DIAGNOSTIC and SPEC_D2_PRICE_WEDGE_DIAGNOSTIC. D1/D2 are diagnostic-only and are not eligible for baseline promotion.

## 8. Estimator Roles

- FM-OLS = main estimator.
- IM-OLS = robustness check.
- DOLS = fragility/stress check.

## 9. Estimator Tuning Metadata Reported from S30

- FM-OLS kernel/bandwidth: kernel reported in coefficient notes where available; bandwidth = and
- IM-OLS kernel/bandwidth/selector: kernel reported in coefficient notes where available; bandwidth = and; selector = 1
- DOLS bandwidth and lead/lag setting: bandwidth = 3; leads/lags = 2

## 10. VIF Diagnostics and Interpretation Rule

S31 computes VIF diagnostics for every reported spec_id x window_id cell where VIF is meaningful, using the exact S30 RHS regressors and the same window sample from the S20 admissibility panel. VIF status bins are low (VIF < 5), moderate (5 <= VIF < 10), and high (VIF >= 10). VIF is a coefficient-interpretation fragility diagnostic, not an automatic model-rejection rule. It does not adjudicate cointegration, does not replace FM-OLS/IM-OLS/DOLS comparison, and does not promote or demote A00/A03 specifications by itself.

## 11. Limitations

S31 does not reconstruct theta_tot.
S31 does not reconstruct productive capacity.
S31 does not compute mu.
S31 does not choose utilization anchors.
S31 does not read S40 outputs.
S31 does not activate S40.

## 12. Required Human Decisions Before S40 Can Be Unparked

Human review must adjudicate the S30 coefficient evidence, decide whether an admissible coefficient object can be promoted, document the preferred A00/A03 interpretation, and only then explicitly unpark S40. S31 does not perform that promotion.
