---
type: econometric_protocol
status: active
depends_on: [chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md]
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
scope: chapter2-econometrics
stage: pre-estimation-design
created_or_updated_by: E10V_I2_TRAP_RESOLUTION
role: moc
aliases:
- Econometrics MOC
- Chapter 2 Econometrics
- E10V econometrics entry point
tags:
- chapter2/econometrics
- chapter2/moc
- chapter2/pre-estimation-design
---

# 03 Econometrics — MOC

## Current Active Doctrine

*   **IM-OLS (adapted for Cointegrating Polynomial Regressions - CPR)** is the preferred baseline-design estimator for Chapter 2.
*   **Orthogonalization (Residual Centering)** is mandatory for all interaction terms to resolve the $I(2)$ trap and eliminate multicollinearity.
*   **DOLS and FM-OLS** are blocked for baseline estimations (DOLS due to regressor density explosion, FM-OLS due to LRCV matrix sensitivity under $I(2)$ processes).
*   Phillips-Ouliaris and Johansen tests are diagnostic only. Cointegration checks for CPR specifications must use the Vogelsang-Wagner residual test.

## Start Here

- [[E10V_IMOLS_CPR_Active_Estimator_Lock]] (Active Doctrine & Baseline Lock)
- [[Interaction_Term_Integration_Order_Gate]] (Active Cointegration Gate)
- [[Estimator_Status_Ledger_E10V]] (Estimator Status Matrix)
- [[E11_IMOLS_CPR_Asymptotic_Rationale]] (Mathematical & Convergence Rationale)
- [[E_00_I2_Trap]] (Methodological Guide to Time-Varying Elasticities)
- [[E_01_I2_Trap]] (Interactive Cointegration Framework)

## Methodological Rationales & Core Concepts

- [[N01_CapacityUtilization_StructuralObject]] (Structural Capacity Utilization)
- [[R01_residual_vs_structural_identification]] (Residual vs. Structural Utilization)
- [[R11_CointegrationAdmissibility_Super-Consistency]] (Super-consistency benefits)

## Historical / Superseded Notes

- [[D12V_Restricted_DOLS_Active_Estimator_Lock]] (Superseded: Restricted DOLS Active Lock)
- [[FMOLS_IMOLS_Failure_For_Interaction_Objects]] (Superseded: Standard FM-OLS/IM-OLS Warning)
- [[Estimator_Status_Ledger_D12V]] (Superseded: D12V Estimator Ledger)
- [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]] (Superseded: DOLS Asymptotic Rationale)
- [[A00_BASELINE_INTERACTION_PATCH_REPORT]]
- [[A06_VIFSafe_Baseline_MechanizationComparison]]
- [[E01_Specification_Abstract_Benchmark]]
- [[M10_Empirical_Identification_Framework]]
- [[N02_SuperConsistency]]
- [[R02_DOLS_reconstruction_dilemma]]
- [[R03_super_consistency_mechanics_hinge]]
- [[R04_FMOLS_structural_preservation]]
- [[R05_LRV_kernel_bandwidth_regime_misalignment]]
- [[R06_IMOLS_integration_ladder_reconstruction]]
- [[R09_structural_break_protocol]]
- [[R10_Binding_Specification_Layering_Rule]]

## Diagnostic-Only Notes

- [[R07_FGLS_threshold_cointegration_admissibility]]
- [[R08_threshold_break_diagnostics_to_FGLS]]

## Audit and Validation Notes

- [[D12V_ECONOMETRICS_VAULT_AUDIT]]
- [[D12V_VALIDATION_CHECKS]]
- [[D12V2_OBSIDIAN_ORGANIZATION_AUDIT]]
- [[D12V2_VALIDATION_CHECKS]]
- [[D12V_TERMINAL_DECISION]]
- [[D12V2_TERMINAL_DECISION]]
