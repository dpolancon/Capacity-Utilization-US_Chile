# U.S. S32C Corporate-Boundary Robustness Validation

## Purpose

S32C estimates preliminary corporate-boundary robustness models, applies Phillips-Ouliaris and residual-stationarity gates, and records OLS, FM-OLS, IM-OLS, and DOLS results without promoting coefficients to final dissertation estimates.

## Sectoral-Boundary Configuration

- Capital boundary: NFC productive-capacity capital stock.
- Output boundary: Corporate sector GVA.
- Distribution boundary: Corporate sector wage share.

## Locked Metadata

- `dependent_variable = y_CORP`
- `dependent_variable_role = effective_output_proxy`
- `target_of_identification = productive_capacity_formation_coefficient`
- `productive_capacity_status = latent_non_observable`
- `capital_boundary = nonfinancial corporate productive-capacity capital`
- `output_boundary = corporate sector as a whole`
- `distribution_boundary = corporate sector as a whole`

## Validation Summary

|check_name|status|details|
|---|---|---|
|NFC K_cap exists in S20 and candidate panel|PASS|Checked K_cap column.|
|k_Kcap exists in candidate panel|PASS|Checked k_Kcap column.|
|g_Kcap exists in candidate panel|PASS|Checked g_Kcap column.|
|omega_CORP exists in candidate panel|PASS|Checked omega_CORP column.|
|corporate output dependent variable y_CORP exists|PASS|y_CORP constructed and verified.|
|dependent variable role is effective_output_proxy|PASS|Registry dependent_variable_role matches.|
|dependent variable is not labeled canonical y_t^p|PASS|No canonical y_t^p labeling found.|
|q_omegaCORP_h1_Kcap is constructed|PASS|Checked q_omegaCORP_h1_Kcap column.|
|q increment equals lagged omega_CORP * g_Kcap within tolerance|PASS|Lagged identity verified.|
|no Delta(omega*K) or level interaction is constructed|PASS|No level interaction or product delta columns in candidate panel.|
|aggregate corporate-boundary baseline is estimated|PASS|S32C_CORP_boundary_baseline estimated successfully.|
|periodized corporate-boundary models are estimated|PASS|All 7 periodized models estimated.|
|modified mechanization-bias comparisons are estimated|PASS|All mechanization extensions estimated.|
|FM-OLS uses Newey-West bandwidth and records it|PASS|Bandwidth rule recorded for FM-OLS.|
|IM-OLS is attempted for all models|PASS|IM-OLS attempted rows checked.|
|DOLS is attempted for all models|PASS|DOLS attempted rows checked.|
|Phillips-Ouliaris gates are attempted for every model|PASS|All PO gates attempted.|
|ADF/KPSS are not used as cointegration gates|PASS|Only PO gate is the formal cointegration screen.|
|OLS is not mislabeled as FM-OLS|PASS|OLS matches stats::lm.|
|estimator failures are recorded if any|PASS|0 failures recorded.|
|coefficients are marked preliminary|PASS|Checked coefficient_status column.|
|No Johansen or VECM is run|PASS|No Johansen/VECM commands present.|
|No capacity utilization is reconstructed|PASS|No capacity utilization variables constructed.|
|No Shaikh-adjusted variables are constructed|PASS|Checked regressors for Shaikh terms.|
|no provider artifacts are modified|PASS|Hashed files checked and matched.|
|advisor report is written|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/docs/results/US_S32C_CORPORATE_BOUNDARY_RESULTS.md|
|all required CSV outputs are written|PASS|All required CSV files present.|

## Hard-lock confirmation

S32C fetched no BEA data, modified no provider artifacts, modified no S20/S22/S30I/S32 outputs, constructed no Shaikh-adjusted variables, constructed no level interactions, ran no Johansen/VECM, reconstructed no productive capacity or utilization, and promoted no coefficient as final.
