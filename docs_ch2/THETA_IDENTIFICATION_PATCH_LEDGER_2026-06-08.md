# Theta Identification Patch Ledger

Date: 2026-06-08
Branch: `feature/ch2-vault-theta-identification-lock`

## Binding outcome

The active note system now makes accumulated distribution-conditioned capital growth the benchmark identification object:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s.
$$

The former $\omega_t k_t$ level interaction is retained only in explicitly rejected, superseded, historical, legacy, or paper-snapshot contexts.

## Files changed

### Constitutional and analytical

- `chapter2_vault/00_constitutive_core/R_distribution_conditioned_theta_identification.md`
- `chapter2_vault/02_analyitical_foundation/A00_Aggregate_Transformation_Benchmark.md`
- `chapter2_vault/02_analyitical_foundation/A03_TransformationElasticity_Two-CapitalCapacityComposition.md`
- `chapter2_vault/02_analyitical_foundation/A05_NRCEnvelope_MechanizationBias.md`

### Econometrics

- `chapter2_vault/03_econometrics/N01_CapacityUtilization_StructuralObject.md`
- `chapter2_vault/03_econometrics/N02_SuperConsistency.md`
- `chapter2_vault/03_econometrics/R04_FMOLS_structural_preservation.md`
- `chapter2_vault/03_econometrics/R05_LRV_kernel_bandwidth_regime_misalignment.md`
- `chapter2_vault/03_econometrics/R06_IMOLS_integration_ladder_reconstruction.md`
- `chapter2_vault/03_econometrics/R09_structural_break_protocol.md`
- `chapter2_vault/03_econometrics/R10_Binding_Specification_Layering_Rule.md`
- `chapter2_vault/03_econometrics/R11_CointegrationAdmissibility_Super-Consistency.md`
- `chapter2_vault/03_econometrics/M10_Empirical_Identification_Framework.md`
- `chapter2_vault/03_econometrics/A06_VIFSafe_Baseline_MechanizationComparison.md`
- `chapter2_vault/03_econometrics/A00_BASELINE_INTERACTION_PATCH_REPORT.md`

### Data and implementation governance

- `chapter2_vault/04_data_measurement/D01_GPIM_heterogeneous_capital_SFC.md`
- `chapter2_vault/04_data_measurement/D02_PriceDeflator_Protocol_K_Composition.md`
- `chapter2_vault/04_data_measurement/D04_ME_NRC_LogRatio_Construction_Protocol.md`
- `chapter2_vault/04_data_measurement/A00_DATA_MEASUREMENT_ALIGNMENT_REPORT.md`
- `chapter2_vault/05_codes_implementation/S10_US_Source-of-Truth_GPIM_ConstructionProtocol.md`
- `chapter2_vault/05_codes_implementation/S10_US_Source-of-Truth_GPIM_ConstructionProtocol 1.md`
- `chapter2_vault/05_codes_implementation/C01-US_00_MEMO_RECYCLING.md`
- `chapter2_vault/05_codes_implementation/C02-CL_00_MEMO_RECYCLING.md`
- `chapter2_vault/05_codes_implementation/C03-REPO_STRUCTURE.md`
- `chapter2_vault/05_codes_implementation/C04-US_S30_STABILITY_PROTOCOL.md`
- `chapter2_vault/05_codes_implementation/E02_CI_as_Rouboustness_P-O_protocol.md`
- `chapter2_vault/05_codes_implementation/A00_CODE_IMPLEMENTATION_ALIGNMENT_REPORT.md`
- `chapter2_vault/05_codes_implementation/US_S30_SUBSTANTIVE_REVIEW_2026-05-14_PRELIMINARY.md`
- `chapter2_vault/05_codes_implementation/US S40 Restricted B1 Reconstruction Contract.md`
- `chapter2_vault/05_codes_implementation/US S40 Review and Figures Contract.md`
- `chapter2_vault/06_paper_facing/Chapter2_Polanco.pdf.md`

## Files inspected but not changed

- `chapter2_vault/04_data_measurement/D03_capacity_utilization_level_anchor_pinch_year_protocol.md`
- `chapter2_vault/03_econometrics/R01_residual_vs_structural_identification.md`
- `chapter2_vault/03_econometrics/R02_DOLS_reconstruction_dilemma.md`
- `chapter2_vault/03_econometrics/R03_super_consistency_mechanics_hinge.md`
- `chapter2_vault/03_econometrics/R07_FGLS_threshold_cointegration_admissibility.md`
- `chapter2_vault/03_econometrics/R08_threshold_break_diagnostics_to_FGLS.md`
- `chapter2_vault/03_econometrics/L00_Econometrics_References.md`
- `chapter2_vault/09_legacy/`
- `chapter2_vault/99_inactive/`

## Stale specifications and handling

| Stale object | Handling |
|---|---|
| $\omega_t k_t$ A00 benchmark | Rejected in the rule note and A00; historical references explicitly superseded. |
| `omega_k_t` required export | Replaced by `q_omega_1`, `q_omega_3`, and `q_omega_5`. |
| $\omega_t m_t$ preferred A05 object | Superseded; ratio route retained only through accumulated $\Delta m_t$ robustness. |
| $\omega_t k_t^{ME}$ direct channel | Superseded; replaced by $q_t^{ME,\omega,h}$. |
| Centered interaction benchmark | Prohibited; benchmark is uncentered. |
| B1/E2B VIF comparison lock | Marked superseded; old VIF evidence does not transfer. |
| B1 restricted S40 path | Contracts marked superseded/blocked. |
| B1/E2B Phillips-Ouliaris matrices | Replaced with corrected A00/A05 matrices. |
| Johansen/VECM benchmark risk | Locked to system-level robustness only. |

## Remaining ambiguities

1. Standardize whether the single-equation dependent variable is denoted $y_t$ or $y_t^p$ during estimation.
2. Choose and document index initialization.
3. Adjudicate wage-share versus profit-share conditioning by country.
4. Verify the generated indexes' integration orders.
5. Reconcile duplicate S10 protocol notes.
6. Define corrected specification IDs and exact exported column names before code work.

## Next implementation steps

1. Construct the six generated indexes in an S10/S20 candidate panel without changing existing empirical outputs.
2. Export timing, memory, centering, sample-loss, capital-definition, and distribution-measure metadata.
3. Run missingness, integration, correlation, VIF, path, capital-definition, and distribution-measure diagnostics.
4. Estimate the aggregate corrected benchmark in S30 with FM-OLS, IM-OLS, and DOLS.
5. Apply residual ADF and Phillips-Ouliaris/equivalent gates, outlier review, sign checks, and historical-path review.
6. Authorize S32 only if the machinery accumulation-weighted candidate clears feasibility review.
7. Conduct explicit human adjudication before any reconstruction.

## S40 lock

S40 remains untouched. No corrected coefficient object may enter S40 until S30/S32 human review explicitly promotes it from candidate to reconstruction input.

## Final search classification

Remaining `omega_t k_t`, `\omega_t k_t`, `level interaction`, or `capital-stock level` hits are:

- `acceptable`: rejected/superseded subsections in the new rule, A00, A05, N01, R10, and D04;
- `acceptable`: files whose frontmatter or opening warning marks them as superseded historical records, including A00 alignment reports, A06, C04, the B1 S40 contract, and the paper-facing snapshot;
- `acceptable`: `09_legacy/R02_Threshold_Model_Peripheral_Diagnostic.md`, which remains under the legacy layer;
- `unacceptable`: none found;
- `ambiguous`: none found.

The estimator search confirms that the active rule chain assigns FM-OLS as main, IM-OLS as robustness, DOLS as fragility/robustness, Phillips-Ouliaris/residual ADF as admissibility checks, Johansen/VECM as system-level robustness only, and S40 as blocked pending promotion.
