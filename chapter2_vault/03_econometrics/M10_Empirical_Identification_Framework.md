---
type: master_note
status: active
layer: method
design_role: empirical_strategy_scaffold
scope: chapter2_core_support
estimator_status: restricted-dols-required-for-nonlinear-baseline
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - A05_NRCEnvelope_MechanizationBias
  - N01_CapacityUtilization_StructuralObject
  - N02_SuperConsistency
  - R01_residual_vs_structural_identification
  - R02_DOLS_reconstruction_dilemma
  - R04_FMOLS_structural_preservation
  - R06_IMOLS_integration_ladder_reconstruction
  - R07_FGLS_threshold_cointegration_admissibility
  - R08_threshold_break_diagnostics_to_FGLS
  - L00_Econometrics_References
priority: high
role: superseded-for-baseline
stage: pre-estimation-design
aliases:
  - M10 empirical framework
tags:
  - chapter2/econometrics
  - chapter2/superseded
  - chapter2/fmols
  - chapter2/imols
  - chapter2/qomega-parked
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# M10 Empirical Identification Framework

> [!warning] q_omega parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path. See [[D12V_Restricted_DOLS_Active_Estimator_Lock]].


> [!gate] D12V2 gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.


> [!warning] D12V2 status
> This note is not baseline authorization.
> FM-OLS and IM-OLS are blocked for nonlinear/interacted/generated Chapter 2 baseline specifications.
> Use [[D12V_Restricted_DOLS_Active_Estimator_Lock]], [[FMOLS_IMOLS_Failure_For_Interaction_Objects]], and [[Estimator_Status_Ledger_D12V]] before citing this note for estimation design.


> [!warning] D12V status update — FM-OLS
> Standard FM-OLS is superseded as the active baseline estimator for nonlinear/interacted/generated Chapter 2 specifications.
> It remains available only as historical reference, diagnostic comparator, or possible estimator for strictly linear cointegration objects if the model object is explicitly classified as standard linear cointegration.
> Do not use this note as baseline authorization without passing through [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Interaction_Term_Integration_Order_Gate]].

> [!warning] D12V status update — IM-OLS
> Standard IM-OLS is not baseline-authorized for nonlinear/interacted/generated Chapter 2 specifications.
> A restricted IM-OLS analogue is blocked as a substitute for Restricted DOLS because cumulative sums of base variables do not resolve interaction-term endogeneity in the required way.
> Use [[FMOLS_IMOLS_Failure_For_Interaction_Objects]] and [[Estimator_Status_Ledger_D12V]] before citing this note for estimation design.

> [!important] D12V status update — DOLS
> The active Chapter 2 baseline-design candidate is Restricted DOLS, not generic DOLS.
> Restricted DOLS keeps nonlinear/interacted terms in the long-run level equation but restricts the dynamic correction set to admissible base-variable differences.
> Unrestricted DOLS is blocked for interaction objects unless a separate protocol authorizes leads/lags of interaction-term differences.
> See [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]].

> [!gate] D12V interaction-term gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.
> Restricted DOLS is preferred only after base-variable integration status, interaction-term status, and sample-window adequacy are classified.

> [!warning] q_omega remains parked
> q_omega-family variables remain parked and are not part of the active Restricted DOLS baseline-design path. See [[D12V_Restricted_DOLS_Active_Estimator_Lock]].

## Core claim

Chapter 2 identifies a distribution-conditioned capital-to-capacity elasticity in the first layer. It does not estimate utilization, short-run demand adjustment, or a wage-led/profit-led demand regime.

The sequence is:

$$
\text{long-run coefficient vector}
\rightarrow
\hat\theta_t
\rightarrow
\hat y_t^p
\rightarrow
\text{level anchoring}
\rightarrow
\hat\mu_t.
$$

## 1. First-layer object

The preferred primitive interaction is:

$$
y_t
=
\alpha
+
\theta_0 k_t
+
\phi\tilde d_t
+
\theta_1(k_t\tilde d_t)
+
\varepsilon_t,
$$

with:

$$
\theta_t=\theta_0+\theta_1\tilde d_t.
$$

The direct distribution term is a nuisance control. $\phi$ is not a wage-led/profit-led coefficient.

The first-layer capital variable must be restricted to the productive-capacity boundary before estimation.

## 2. Competing composition specification

The composition-mediated candidate is:

$$
y_t
=
\alpha
+
\theta\tilde k_t^{scale}
+
\psi\tilde\tau_t
+
\phi\tilde d_t
+
\lambda(\tilde\tau_t\tilde d_t)
+
\varepsilon_t.
$$

This tests whether distribution acts through capital composition rather than directly through productive-capital scale. It does not presume a conclusive machinery/intensive and structures/extensive mapping.

## 3. Super-consistency

Super-consistency may support recovery of the long-run coefficient vector. It does not validate the reconstructed productive-capacity path or derived utilization series.

**Coefficient consistency does not imply object consistency.**

## 4. Estimator assignment

| Role | Estimator / method | Function |
| --- | --- | --- |
| Main coefficient recovery | FM-OLS | Preserves the log-level first-layer regressor matrix |
| Robustness | IM-OLS | Checks coefficient stability |
| Fragility | DOLS | Tests sensitivity to costly leads and lags |
| System robustness | Johansen/VECM | Rank and system evidence only |
| Regime estimation | Threshold-FGLS | Separate layer after threshold admissibility |

ARDL, ECM coefficients, short-run multipliers, and full VECM dynamics do not identify the first-layer object.

## 5. Effective-demand boundary

Government expenditure, exports, consumption, imports, and other demand-composition variables belong to realization, utilization, leakages, fixed points, and later interpretation. They do not enter the first-layer productive-capacity equation as direct capacity builders.

## 6. Diagnostic and regime layers

The first layer assumes a stable long-run relation. Regime switching follows only after:

1. integration order;
2. deterministic components;
3. structural breaks;
4. nonlinear mean reversion;
5. threshold admissibility.

Threshold-FGLS is not a general replacement for FM-OLS, IM-OLS, or DOLS.

## 7. Reconstruction

Observed output satisfies:

$$
y_t=y_t^p+\log\mu_t.
$$

After $\hat y_t^p$ has been reconstructed and anchored:

$$
\widehat{\log\mu_t}=y_t-\hat y_t^p.
$$

The cointegrating residual is an admissibility and diagnostic object. It does not directly identify utilization.

## Parked / not current baseline

The accumulated $q_t^{\omega,h}$ index remains a possible historical-memory operator to test after the primitive interaction problem is clarified. It is not the current first-layer baseline.

## Locked statement

**The first layer identifies the interaction-implied capital-to-capacity elasticity. Productive capacity is reconstructed from the fitted long-run component and explicitly anchored; utilization is derived only afterwards.**

## Constitutional subordination

This framework remains subordinate to:

- [[00_constitutive_core/01_Governing_Memo|Governing memo]]
- [[00_constitutive_core/01A_Design_vs_Presentation_Firewall|Design vs presentation firewall]]
- [[R_distribution_conditioned_theta_identification]]
