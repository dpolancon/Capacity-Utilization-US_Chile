---
type: econometric_protocol
status: active
depends_on: [chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]
stage_scope: all_stages
country: US
last_updated: 2026-07-23
layer: code_stage_design
created_by: E10V_I2_TRAP_RESOLUTION
role: active-ledger
stage: pre-estimation-design
tags:
- chapter2/econometrics
- chapter2/active-ledger
---

# Estimator Status Ledger E10V

| Estimator | Status for CPR (I(2) Interaction) | Allowed Role | Blocked Role | Required Gate |
| :--- | :--- | :--- | :--- | :--- |
| **IM-OLS (CPR-adapted)** | **Preferred Baseline** | Long-run parameter estimation and capacity reconstruction. | Silent re-estimation in downstream results packaging. | Cointegration check under Vogelsang-Wagner residual test. |
| **Orthogonalization** | **Mandatory Pre-Filter** | Partialing out linear components of interaction terms. | Direct baseline estimation without residual extraction. | Auxiliary OLS diagnostic check. |
| **Restricted DOLS** | **Diagnostic/Robustness** | Comparator to check coefficient stability. | Baseline estimation. | Integration-order gate check. |
| **FM-OLS** | **Diagnostic/Robustness** | Comparator for linear sub-specifications. | Baseline estimation. | Long-run covariance matrix stability check. |
| **Static OLS** | **Preliminary levels check** | Cointegration diagnostics, auxiliary regression. | Final coefficient inference. | Integration-order gate check. |
| **Johansen / VECM** | **System robustness** | System dynamic checks. | Automatic replacement for single-equation CPR baseline. | Integration-order gate check. |
