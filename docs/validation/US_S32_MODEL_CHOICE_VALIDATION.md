# U.S. S32 Preliminary Model-Choice Validation

## Purpose

S32 estimates preliminary effective-output relations, applies Phillips-Ouliaris and residual-stationarity gates, and records FM-OLS, IM-OLS, DOLS, and diagnostic levels OLS results without promoting coefficients to final dissertation estimates.

## Locked metadata

- `dependent_variable = y_t`
- `dependent_variable_label = actual_log_output`
- `dependent_variable_role = effective_output_proxy`
- `target_of_identification = productive_capacity_formation_coefficient`
- `productive_capacity_status = latent_non_observable`

## Estimator hierarchy

- `FM_OLS_preliminary`: preferred available preliminary estimator.
- `IM_OLS_preliminary`: preliminary robustness estimator.
- `DOLS_preliminary`: preliminary robustness estimator with one lead and lag.
- `diagnostic_levels_OLS`: diagnostic levels regression, never FM-OLS.

## Gate protocol

Phillips-Ouliaris uses `urca::ca.po` with Pz, a constant, and short bandwidth. Residual ADF uses no deterministic term with AIC lag selection. Residual KPSS uses a level-stationarity null and short bandwidth. The screen is preliminary and model-specific.

## Validation summary

|check_name|status|details|
|---|---|---|
|Residual ADF gates attempted for every model|PASS|21 ADF rows.|
|Advisor report is written|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/docs/results/US_S32_MODEL_CHOICE_BASELINE_EXTENSIONS.md|
|Aggregate q variants retain theoretical roles|PASS|Preferred, memory, and alternative-distribution roles retained.|
|Baseline model estimated|PASS|S32_A00_baseline has successful estimator rows.|
|All required CSV outputs are written|PASS|7 of 7 required CSV outputs written.|
|FM-OLS/IM-OLS/DOLS failures are recorded, not hidden|PASS|0 unavailable/failed attempts recorded.|
|I2-risk variables are flagged clearly|PASS|6 models flagged.|
|Residual KPSS gates attempted where available|PASS|21 KPSS rows.|
|No Johansen/VECM is run|PASS|No system cointegration estimator is called.|
|No Delta(omega*K) or Delta(omega*k) q construction occurs|PASS|S32 consumes governed q inputs and constructs no q series.|
|No S40 or utilization reconstruction occurs|PASS|S32 estimates only governed effective-output relations.|
|No Shaikh-adjusted variables are used|PASS|All distribution inputs are unadjusted governed objects.|
|OLS is not mislabeled as FM-OLS|PASS|OLS is labeled diagnostic_levels_OLS only.|
|PO gates attempted for every model|PASS|21 PO rows for 21 models.|
|Coefficients are marked preliminary|PASS|284 coefficient rows.|
|No provider artifacts are modified|PASS|6 hashes compared.|
|Preferred q increment rule is respected|PASS|Delta q_omega_h1_Kcap equals lagged omega_NFC times g_Kcap.|
|Rolling instability is warning, not automatic block|PASS|Baseline I(1)/no-I(2) variables enter S32 with rolling warnings.|
|S20 input exists|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_s20/us_s20_capital_distribution_frontier_panel.csv|
|S22 periodized q panel exists|PASS|C:/ReposGitHub/Capacity-Utilization-US_Chile/data/processed/us_s22/us_s22_periodized_q_panel.csv|
|S31I recommendation files exist|PASS|Three S31I governance inputs checked.|
|S20/S22/S31I inputs are unchanged|PASS|7 hashes compared.|
|y_t is not labeled canonical y_t^p|PASS|Actual log output is the effective-output proxy; capacity is latent.|
|y_t exists and is labeled effective-output proxy|PASS|y_t; actual_log_output; effective_output_proxy; productive_capacity_formation_coefficient; latent_non_observable|

## Hard-lock confirmation

S32 fetched no BEA data, modified no S20/S22/S31I or provider output, constructed no adjusted distribution or level interaction, ran no Johansen/VECM or S40 step, reconstructed no productive capacity or capacity utilization, and promoted no coefficient as final.
