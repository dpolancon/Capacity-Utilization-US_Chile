---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-26
scope: chapter2-econometrics
stage: pre-estimation-design
created_or_updated_by: CPR_IMOLS_ESTIMATION_PROTOCOL_LOCK
role: moc
aliases:
  - Econometrics MOC
  - Chapter 2 Econometrics
  - E10V econometrics entry point
tags:
  - chapter2/econometrics
  - chapter2/moc
  - chapter2/pre-estimation-design
subtype: econometric_protocol
blocks: []
layer: empirics
priority: reference
---

# 03 Econometrics — MOC

## Current Active Doctrine

*   **IM-OLS (adapted for Cointegrating Polynomial Regressions - CPR)** is the preferred baseline-design estimator for Chapter 2.
*   **FWL Orthogonalization (Pre-Filtering) is Forbidden.** Partial summation does not commute with projection ($S M_X \neq M_{SX} S$). The raw interaction enters the full IM-OLS design.
*   **Three-Regime Centering Architecture:** Uncentered (Regime A) is the main specification (requires QR/SVD matrix factorization); Initial-State Centering (Regime B) is the primary robustness check (canonical Brownian start, path-dependent historical interpretation); Sample-Mean Centering (Regime C) is a secondary comparator. See [[N11_Centering_Protocol_Three_Regime]].
*   **Unified 5-Stage Pre-Testing Protocol:** Mandatory pre-estimation diagnostic pipeline (Unit Roots $\to$ LOESS Inflections $\to$ VECM Cointegration $\to$ Drift Leakage $\to$ CPR IM-OLS 3-Regime Estimation). See [[N12_PreTesting_Protocol_Integration_Breaks_ChoiceOfTechnique]].
*   **DOLS and FM-OLS** are blocked for baseline estimations (DOLS due to regressor density explosion, FM-OLS due to path-dependent quadratic variation in cross-product Brownian limits).
*   **Vogelsang-Wagner IM-OLS Cointegration Test (Lock E15)** is the SOLE and AUTHORITATIVE cointegration test for Chapter 2. Johansen and Phillips-Ouliaris tests are relegated to background diagnostics. See [[E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock]].
*   **NFC Sector Estimation & Aggregate Utilization Recovery (Lock E16)**: Cointegrating regressions are estimated using Non-Financial Corporate Real Value Added ($y_t^{\text{NFC}}$) to reconstruct latent potential capacity $y_t^p$, while capacity utilization $\mu_t = Y_t / Y_t^p$ is recovered using total aggregate output $Y_t$. See [[E16_NFC_Estimation_Aggregate_Utilization_Recovery_Lock]].

## Start Here

- [[E10V_IMOLS_CPR_Active_Estimator_Lock]] (Active Doctrine & Baseline Lock)
- [[E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock]] (Vogelsang-Wagner IM-OLS Cointegration Test Lock)
- [[E16_NFC_Estimation_Aggregate_Utilization_Recovery_Lock]] (NFC Estimation & Aggregate Utilization Recovery Lock)
- [[N12_PreTesting_Protocol_Integration_Breaks_ChoiceOfTechnique]] (Unified 5-Stage Pre-Testing Protocol)
- [[N11_Centering_Protocol_Three_Regime]] (Centering Protocol Architecture)
- [[Interaction_Term_Integration_Order_Gate]] (Active Cointegration Gate)
- [[E14_RelativePrice_Integration_Order_Gate]] (Relative Price Integration Order & Break Gate)
- [[N06_Kappa_Identification_and_IMOLS_Exogeneity_Paradox]] (Kappa Identification & Finite-Sample Paradox)
- [[E18_Kappa_Path_Derivative_LOESS_Lock]] (Kappa Path Derivative LOESS Identification Lock)
- [[E17_Cointegration_Significance_Stars_Lock]] (Cointegration Significance Stars & Opposing Null Hypotheses)
- [[E11_IMOLS_CPR_Asymptotic_Rationale]] (Mathematical & Convergence Rationale)
- [[E_00_I2_Trap]] (Methodological Guide to Time-Varying Elasticities)
- [[E_01_I2_Trap]] (Interactive Cointegration Framework)



## Methodological Rationales & Core Concepts

- [[N01_CapacityUtilization_StructuralObject]] (Structural Capacity Utilization)
- [[R01_residual_vs_structural_identification]] (Residual vs. Structural Utilization)
- [[R11_CointegrationAdmissibility_Super-Consistency]] (Super-consistency benefits)

## Historical / Superseded Notes (Archived in `_legacy/`)

- [[D12V_Restricted_DOLS_Active_Estimator_Lock|D12V_Restricted_DOLS_Active_Estimator_Lock]] (Superseded: Restricted DOLS Active Lock)
- [[FMOLS_IMOLS_Failure_For_Interaction_Objects|FMOLS_IMOLS_Failure_For_Interaction_Objects]] (Superseded: Standard FM-OLS/IM-OLS Warning)
- [[Estimator_Status_Ledger_D12V|Estimator_Status_Ledger_D12V]] (Superseded: D12V Estimator Ledger)
- [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats|Restricted_DOLS_Asymptotic_Rationale_and_Caveats]] (Superseded: DOLS Asymptotic Rationale)
- [[A00_BASELINE_INTERACTION_PATCH_REPORT|A00_BASELINE_INTERACTION_PATCH_REPORT]]
- [[A06_VIFSafe_Baseline_MechanizationComparison|A06_VIFSafe_Baseline_MechanizationComparison]]
- [[E01_Specification_Abstract_Benchmark|E01_Specification_Abstract_Benchmark]]
- [[M10_Empirical_Identification_Framework|M10_Empirical_Identification_Framework]]
- [[N02_SuperConsistency|N02_SuperConsistency]]
- [[R02_DOLS_reconstruction_dilemma|R02_DOLS_reconstruction_dilemma]]
- [[R03_super_consistency_mechanics_hinge|R03_super_consistency_mechanics_hinge]]
- [[R04_FMOLS_structural_preservation|R04_FMOLS_structural_preservation]]
- [[R05_LRV_kernel_bandwidth_regime_misalignment|R05_LRV_kernel_bandwidth_regime_misalignment]]
- [[R06_IMOLS_integration_ladder_reconstruction|R06_IMOLS_integration_ladder_reconstruction]]
- [[R09_structural_break_protocol|R09_structural_break_protocol]]
- [[R10_Binding_Specification_Layering_Rule|R10_Binding_Specification_Layering_Rule]]

## Diagnostic-Only Notes

- [[R07_FGLS_threshold_cointegration_admissibility]]
- [[R08_threshold_break_diagnostics_to_FGLS]]

## Historical Audit and Validation Notes (Archived in `_legacy/`)

- [[D12V_ECONOMETRICS_VAULT_AUDIT|D12V_ECONOMETRICS_VAULT_AUDIT]]
- [[D12V_VALIDATION_CHECKS|D12V_VALIDATION_CHECKS]]
- [[D12V2_OBSIDIAN_ORGANIZATION_AUDIT|D12V2_OBSIDIAN_ORGANIZATION_AUDIT]]
- [[D12V2_VALIDATION_CHECKS|D12V2_VALIDATION_CHECKS]]
- [[D12V_TERMINAL_DECISION|D12V_TERMINAL_DECISION]]
- [[D12V2_TERMINAL_DECISION|D12V2_TERMINAL_DECISION]]
