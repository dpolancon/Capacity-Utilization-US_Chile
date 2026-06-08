# Theta Identification Vault Audit

Date: 2026-06-08
Scope: `chapter2_vault/`
Branch: `feature/ch2-vault-theta-identification-lock`

## Audit verdict

The active vault previously treated the contemporaneous level interaction $\omega_t k_t$ as the A00 benchmark and propagated it through analytical, econometric, data, and implementation notes. A05 also preferred $\omega_t m_t$, while active implementation contracts allowed a restricted B1 path into S40.

Those objects contradicted the updated identification rule. The binding benchmark is now accumulated distribution-conditioned capital growth:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s.
$$

The preferred decomposed object is:

$$
q_t^{ME,\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s^{ME}.
$$

## Vault map inspected

| Folder | Audit role |
|---|---|
| `00_constitutive_core` | Constitutional and governance rules |
| `02_analyitical_foundation` | A00/A03/A05 theoretical and bridge objects |
| `03_econometrics` | Estimator, admissibility, stability, and specification governance |
| `04_data_measurement` | Capital construction and generated-variable protocols |
| `05_codes_implementation` | S10/S30/S32/S40 sequencing and contracts |
| `06_paper_facing` | Paper-facing snapshots that can propagate stale specifications |
| `09_legacy` | Archived analytical material |
| `99_inactive` | Inactive handoffs and historical notes |

`.obsidian/` was not inspected or edited.

## Classification

### Binding targets

| File | Classification | Audit disposition |
|---|---|---|
| `00_constitutive_core/R_distribution_conditioned_theta_identification.md` | `binding_target` | Created as the binding rule note. |
| `02_analyitical_foundation/A00_Aggregate_Transformation_Benchmark.md` | `binding_target` | Replaced the active level interaction with $q_t^{\omega,h}$; retained aggregate capital and time-varying $\theta_t$. |
| `03_econometrics/N01_CapacityUtilization_StructuralObject.md` | `binding_target` | Updated the structural identification sequence. |
| `03_econometrics/N02_SuperConsistency.md` | `binding_target` | Reassigned super-consistency to the corrected benchmark. |
| `03_econometrics/R04_FMOLS_structural_preservation.md` | `binding_target` | Updated the preserved regressor matrix and $\theta_t$ mapping. |
| `03_econometrics/R10_Binding_Specification_Layering_Rule.md` | `binding_target` | Rewritten around corrected benchmark/candidate statuses and promotion gates. |
| `03_econometrics/R11_CointegrationAdmissibility_Super-Consistency.md` | `binding_target` | Replaced B1/E2B candidate systems with corrected A00/A05 systems. |

### Bridge targets

| File | Classification | Audit disposition |
|---|---|---|
| `02_analyitical_foundation/A03_TransformationElasticity_Two-CapitalCapacityComposition.md` | `bridge_target` | Locked the growth-rate interpretation and aggregate accumulated-index bridge. |
| `02_analyitical_foundation/A05_NRCEnvelope_MechanizationBias.md` | `bridge_target` | Made machinery accumulation the preferred distributive channel; retained NRC as non-distributive. |
| `04_data_measurement/D02_PriceDeflator_Protocol_K_Composition.md` | `bridge_target` | Updated the A00/A03 boundary. |
| `04_data_measurement/D04_ME_NRC_LogRatio_Construction_Protocol.md` | `bridge_target` | Restricted the log-ratio route to less-preferred robustness. |

### Empirical strategy targets

| File | Classification | Audit disposition |
|---|---|---|
| `03_econometrics/M10_Empirical_Identification_Framework.md` | `empirical_strategy_target` | Added generated-variable, estimator, VECM, and S40 locks. |
| `03_econometrics/R05_LRV_kernel_bandwidth_regime_misalignment.md` | `empirical_strategy_target` | Updated the global FM-OLS object. |
| `03_econometrics/R06_IMOLS_integration_ladder_reconstruction.md` | `empirical_strategy_target` | Corrected the order-of-operations rule for accumulated indexes. |
| `03_econometrics/R09_structural_break_protocol.md` | `empirical_strategy_target` | Updated the representative S30 specification. |
| `04_data_measurement/D01_GPIM_heterogeneous_capital_SFC.md` | `empirical_strategy_target` | Added aggregate and machinery generated-index exports and metadata. |
| `05_codes_implementation/S10_US_Source-of-Truth_GPIM_ConstructionProtocol.md` | `empirical_strategy_target` | Added the six required generated indexes and feasibility gate. |
| `05_codes_implementation/S10_US_Source-of-Truth_GPIM_ConstructionProtocol 1.md` | `empirical_strategy_target` | Replaced level interactions and centering with corrected construction rules. |
| `05_codes_implementation/C01-US_00_MEMO_RECYCLING.md` | `empirical_strategy_target` | Replaced `omega_k_t` implementation metadata. |
| `05_codes_implementation/C02-CL_00_MEMO_RECYCLING.md` | `empirical_strategy_target` | Replaced the Chile baseline hierarchy. |
| `05_codes_implementation/E02_CI_as_Rouboustness_P-O_protocol.md` | `empirical_strategy_target` | Updated Phillips-Ouliaris matrices for corrected A00/A05 candidates. |
| `05_codes_implementation/C03-REPO_STRUCTURE.md` | `empirical_strategy_target` | Added a binding override that blocks the prior B1 S40 path. |

### Superseded references

| File | Classification | Audit disposition |
|---|---|---|
| `03_econometrics/A00_BASELINE_INTERACTION_PATCH_REPORT.md` | `superseded_reference` | Marked historical; old hits are acceptable only in that role. |
| `03_econometrics/A06_VIFSafe_Baseline_MechanizationComparison.md` | `superseded_reference` | Marked superseded; prior VIF results do not transfer. |
| `04_data_measurement/A00_DATA_MEASUREMENT_ALIGNMENT_REPORT.md` | `superseded_reference` | Marked historical. |
| `05_codes_implementation/A00_CODE_IMPLEMENTATION_ALIGNMENT_REPORT.md` | `superseded_reference` | Marked historical. |
| `05_codes_implementation/C04-US_S30_STABILITY_PROTOCOL.md` | `superseded_reference` | Retained as the old B1 adjudication record; no S40 authority. |
| `05_codes_implementation/US S40 Restricted B1 Reconstruction Contract.md` | `superseded_reference` | Marked superseded and blocked. |
| `05_codes_implementation/US S40 Review and Figures Contract.md` | `superseded_reference` | Marked superseded and parked. |
| `05_codes_implementation/US_S30_SUBSTANTIVE_REVIEW_2026-05-14_PRELIMINARY.md` | `superseded_reference` | Updated its header-level status so the old B1 lane is no longer described as current. |
| `06_paper_facing/Chapter2_Polanco.pdf.md` | `superseded_reference` | Added a methodological-snapshot warning. |

### Archive no touch

The following were inspected through search results but not edited:

- `09_legacy/R02_Threshold_Model_Peripheral_Diagnostic.md`
- other `09_legacy/` notes containing transformation-elasticity terminology;
- `99_inactive/H02_Theta_to_Empirical_Coefficients.md`;
- `99_inactive/H01_Cajas_to_Transformation_Elasticity 1.md`;
- `99_inactive/Handoff_Next_Worksession.md`;
- `01_contradictory_utilization_configurations/okishio_macro_anarchy_bridge/archive_raw_briefs/`.

Classification: `archive_no_touch`. Their location already prevents them from governing the active benchmark.

### Irrelevant hits

Search hits were classified `irrelevant_hit` when they mentioned estimator names, wage share, theta, or S40 without defining the transformation-elasticity specification. Examples include:

- `07_WrittingSkills_and_Rules/C02_Advisor_Michael_Facing_Exposition_Prompt.md`;
- `03_econometrics/L00_Econometrics_References.md`;
- `06_paper_facing/Chapter2_References.md`;
- figure and reference notes whose hits were bibliographic or presentational only.

## Stale objects found

1. $\omega_t k_t$ presented as the binding A00 benchmark.
2. $\omega_t m_t$ presented as the preferred A05 mechanism.
3. $\omega_t k_t^{ME}$ presented as a direct two-capital distributive channel.
4. `omega_k_t` treated as a required S10/S30 export.
5. Full-sample-centered interaction variants allowed in S10.
6. B1/E2B VIF results treated as governing the next model comparison.
7. Restricted B1 contracts treated as opening S40.
8. Phillips-Ouliaris candidate matrices tied to the superseded B1/E2B systems.
9. Several estimator notes preserving the wrong regressor matrix.

## Required patches completed

- Created the constitutional rule note with inherited timing, no full-sample centering, restricted memory states, estimator roles, and promotion conditions.
- Patched A00, A03, and A05 in the required order.
- Added the aggregate and machinery index menus to S10/data governance.
- Locked FM-OLS main, IM-OLS robustness, DOLS fragility/robustness, and Johansen/VECM system-level-only roles.
- Locked residual ADF, Phillips-Ouliaris/equivalent, outlier, dummy, sign, estimator-agreement, and historical-interpretability gates.
- Parked prior B1 S40 contracts.

## Files intentionally not touched

- `.obsidian/`
- `codes/`
- `data/`
- `output/`
- generated empirical outputs
- `09_legacy/` and `99_inactive/` contents
- the locked dissertation outline and prose draft

## Risks and ambiguities for human review

1. Whether the dependent variable in S30 should be labeled observed $y_t$ or latent/reconstructed $y_t^p$ in the estimating equation must be standardized before implementation.
2. The exact wage-share and profit-share source series for each country remains a data-selection decision.
3. The initial value convention for each cumulative index must be declared in code and metadata.
4. The expected integration order of the generated indexes must be established empirically; it cannot be assumed from the components.
5. The preferred aggregate capital definition and the preferred machinery-stock definition require sensitivity review.
6. The duplicate S10 protocol files should be reconciled in a later governance pass; neither was deleted here.
7. Existing B1/E2B outputs remain historical evidence only. They cannot be reinterpreted as corrected-index results.
