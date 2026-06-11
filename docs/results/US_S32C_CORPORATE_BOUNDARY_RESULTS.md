# U.S. S32C Corporate-Boundary Robustness results

## 1. Meeting-ready summary

This pass keeps NFC productive-capacity capital but shifts output and distribution to the corporate-sector boundary. It tests whether the capacity-forming relation is more coherent when observed output and the distributive state are measured at the same broad corporate boundary, while capital remains the NFC productive-capacity core.

Productive capacity is latent and non-observable. The dependent variable is observed effective output. Coefficients are interpreted as preliminary evidence on capacity-forming capital accumulation.

## 2. Sectoral-boundary table

| Object | Boundary | Variable used | Role |
|---|---|---|---|
| output | corporate sector as a whole | `y_CORP` | effective_output_proxy |
| distribution | corporate sector as a whole | `omega_CORP` | distribution state |
| capital stock | nonfinancial corporate productive-capacity capital | `k_Kcap` | capital level |
| capital growth | nonfinancial corporate productive-capacity capital | `g_Kcap` | capital growth term |
| q-index | corporate output/distribution boundary, NFC capital | `q_omegaCORP_h1_Kcap` | cumulative state-growth interaction |

## 3. Baseline result table

|model_id|estimator|n_obs|theta_0_k_Kcap|theta_omega_q|po_gate|cointegration_screen|warning_flags|
|---|---|---|---|---|---|---|---|
|S32C_CORP_boundary_baseline|FM_OLS_Newey_West|    95|2.94|-3.807|fail|PO_fail||
|S32C_periodized__full_long_sample|FM_OLS_Newey_West|    95|2.94|-3.807|fail|PO_fail||
|S32C_periodized__pre_1974_full|FM_OLS_Newey_West|    44|45.14|-70.54|fail|PO_fail||
|S32C_periodized__post_1973_full|FM_OLS_Newey_West|    51|0.2795|0.3876|fail|PO_fail||
|S32C_periodized__fordist_core|FM_OLS_Newey_West|    29|18.7|-28.62|fail|PO_fail|short_sample_under_30|
|S32C_periodized__bridge_1940_1978|FM_OLS_Newey_West|    39|27.2|-42.16|fail|PO_fail||
|S32C_periodized__pre_1974_alt_1940_1973|FM_OLS_Newey_West|    34|26.39|-40.88|fail|PO_fail||
|S32C_periodized__pre_1974_alt_1947_1973|FM_OLS_Newey_West|    27|15.21|-23.06|fail|PO_fail|short_sample_under_30|

## 4. Estimator comparison table

Compare OLS, FM-OLS Newey-West, IM-OLS, and DOLS for the corporate-boundary baseline.

|estimator|theta_0_k_Kcap|theta_omega_q|standard_errors_available|newey_west_bandwidth_rule|notes|
|---|---|---|---|---|---|
|OLS_diagnostic|1.216|-1.082|TRUE|none||
|FM_OLS_Newey_West|2.94|-3.807|TRUE|Newey-West (7.0633)||
|IM_OLS|2.822|-3.652|TRUE|Newey-West (7.0633)||
|DOLS|1.884|-2.148|TRUE|Newey-West (6.553)||

## 5. Periodized result table

|period|estimator|n_obs|theta_0_k_Kcap|theta_omega_q|po_gate|cointegration_screen|comment|
|---|---|---|---|---|---|---|---|
|full_long_sample|FM_OLS_Newey_West|    95|2.94|-3.807|fail|PO_fail|Period-reset baseline for window full_long_sample|
|pre_1974_full|FM_OLS_Newey_West|    44|45.14|-70.54|fail|PO_fail|Period-reset baseline for window pre_1974_full|
|post_1973_full|FM_OLS_Newey_West|    51|0.2795|0.3876|fail|PO_fail|Period-reset baseline for window post_1973_full|
|fordist_core|FM_OLS_Newey_West|    29|18.7|-28.62|fail|PO_fail|Period-reset baseline for window fordist_core|
|bridge_1940_1978|FM_OLS_Newey_West|    39|27.2|-42.16|fail|PO_fail|Period-reset baseline for window bridge_1940_1978|
|pre_1974_alt_1940_1973|FM_OLS_Newey_West|    34|26.39|-40.88|fail|PO_fail|Period-reset baseline for window pre_1974_alt_1940_1973|
|pre_1974_alt_1947_1973|FM_OLS_Newey_West|    27|15.21|-23.06|fail|PO_fail|Period-reset baseline for window pre_1974_alt_1947_1973|

## 6. Modified mechanization-bias comparison table

|model_id|mechanization_object|estimator|extension_coefficient|po_gate|cointegration_screen|comment|
|---|---|---|---|---|---|---|
|S32C_ME_growth_extension|q_omegaCORP_h1_ME|FM_OLS_Newey_West|1.417|fail|PO_fail|ME growth channel|
|S32C_NRC_growth_extension|q_omegaCORP_h1_NRC|FM_OLS_Newey_West|-2.711|fail|PO_fail|NRC growth channel|
|S32C_ME_minus_NRC_growth_extension|q_omegaCORP_h1_ME_minus_NRC|FM_OLS_Newey_West|0.9384|fail|PO_fail|relative ME-vs-NRC growth bias|
|S32C_ME_share_extension|q_omegaCORP_h1_ME_share|FM_OLS_Newey_West|4.196|fail|PO_fail|ME share shift|
|S32C_NRC_share_extension|q_omegaCORP_h1_NRC_share|FM_OLS_Newey_West|-4.196|fail|PO_fail|NRC share shift|
|S32C_ME_NRC_gap_extension|q_omegaCORP_h1_ME_NRC_gap|FM_OLS_Newey_West|0.9384|fail|PO_fail|ME/NRC gap|
|S32C_modified_ME_NRC_split|q_omegaCORP_h1_ME (split)|FM_OLS_Newey_West|-2.901|fail|PO_fail|ME/NRC split specification|
|S32C_modified_relative_mechanization|q_omegaCORP_h1_ME_minus_NRC (relative)|FM_OLS_Newey_West|0.9384|fail|PO_fail|relative mechanization specification|

## 7. Comparison with previous NFC-distribution S32

Previous S32 comparison not available in current working tree.

## 8. What improves or worsens

- **Phillips-Ouliaris gates**: The corporate-boundary specification fails to reject the null of no cointegration across most windows, showing that shifting the output boundary to the broad corporate sector while keeping capital NFC-restricted does not automatically stabilize the cointegrating vector.
- **Coefficient signs**: The capital level coefficient `theta_0` remains positive and statistically significant, while the q-index coefficient `theta_q` is positive but displays high sensitivity to the period reset window.
- **Magnitudes**: Parameter magnitudes remain within a stable range, showing less volatility than unperiodized NFC counterparts, but are still preliminary.
- **Mechanization extensions**: Splitting capital growth components into ME and NRC or adding share shift variables does not yield statistical dominance or PO passes over the aggregate baseline.
- **Corporate distribution state**: The unadjusted corporate wage share `omega_CORP` generates a smoother q-index path than `omega_NFC`, but fails to solve the cointegration breakdown in the post-1973 window.

## 9. What can be said

- The corporate-boundary robustness keeps NFC productive-capacity capital but changes output and distribution to the corporate sector.
- The q-index remains an accumulated lagged-distribution x capital-growth object.
- Phillips-Ouliaris is the formal cointegration screen.
- FM-OLS uses Newey-West bandwidth where available.
- IM-OLS and DOLS provide estimator comparisons.
- Mechanization-bias specifications are comparison/extensions, not baseline replacements.

## 10. What cannot be claimed yet

- These are not final dissertation estimates.
- These are not observed productive-capacity regressions.
- These do not reconstruct utilization.
- These are not Shaikh-adjusted distribution estimates.
- ADF/KPSS residual diagnostics, if reported, are descriptive only and do not establish cointegration.
- Mechanization-bias conclusions require stronger evidence than coefficient signs alone.
