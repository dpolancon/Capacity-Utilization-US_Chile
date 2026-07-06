---
type: note
subtype: rule
status: active
layer: analytical_foundation
design_role: ontological_guardrail
scope: chapter2_core
estimator_status: historical-or-diagnostic
requires_review_before_use: true
related_to:
  - H02_Theta_to_Empirical_Coefficients
  - R01_Marx_Okishio_Regime_Diagnostic_Guardrail
  - Okishio_Vidal_Transformation_Elasticity
created: 2026-05-27
role: superseded-for-baseline
stage: pre-estimation-design
aliases:
  - E01 abstract benchmark
tags:
  - chapter2/econometrics
  - chapter2/superseded
  - chapter2/fmols
updated_by: D12V2_OBSIDIAN_ECONOMETRICS_VAULT_ORGANIZATION
---

# The Frontier of "Not Becoming" vs. Historical "Becoming"

> [!gate] D12V2 gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.


> [!important] D12V2 status
> The active Chapter 2 baseline-design candidate is Restricted DOLS, not generic DOLS.
> Restricted DOLS keeps nonlinear/interacted terms in the long-run level equation and restricts dynamic corrections to admissible base-variable differences.
> See [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Restricted_DOLS_Asymptotic_Rationale_and_Caveats]].


> [!warning] D12V2 status
> This note is not baseline authorization.
> FM-OLS and IM-OLS are blocked for nonlinear/interacted/generated Chapter 2 baseline specifications.
> Use [[D12V_Restricted_DOLS_Active_Estimator_Lock]], [[FMOLS_IMOLS_Failure_For_Interaction_Objects]], and [[Estimator_Status_Ledger_D12V]] before citing this note for estimation design.


> [!warning] D12V status update — FM-OLS
> Standard FM-OLS is superseded as the active baseline estimator for nonlinear/interacted/generated Chapter 2 specifications.
> It remains available only as historical reference, diagnostic comparator, or possible estimator for strictly linear cointegration objects if the model object is explicitly classified as standard linear cointegration.
> Do not use this note as baseline authorization without passing through [[D12V_Restricted_DOLS_Active_Estimator_Lock]] and [[Interaction_Term_Integration_Order_Gate]].

> [!gate] D12V interaction-term gate
> Any nonlinear/interacted/generated specification must pass [[Interaction_Term_Integration_Order_Gate]] before estimator selection.
> Restricted DOLS is preferred only after base-variable integration status, interaction-term status, and sample-window adequacy are classified.

## Core Claim
The mechanization productive frontier and the condition of smooth reproduction ($\mu = 1$) are **not** behavioral assumptions about how capitalist firms actually operate.

They are analytical abstractions of **"not becoming"** (pure structural being). They serve strictly as a geometric and theoretical benchmark to measure the contradictory reality of historical **"becoming"** (where $\mu_t \neq 1$).

---

## 1. The Abstraction of "Not Becoming" (The Frontier)
In dialectical terms, "not becoming" represents a static, frictionless limit devoid of market anarchy and internal contradiction.
*   **The Cajas Limit:** The cost-minimizing mechanization choice $q^*(\omega, E)$ on the technological frontier.
*   **Smooth Reproduction:** The state where actual output perfectly matches reconstructed productive capacity ($\mu = 1$).
*   **Function:** It defines the *maximum potential transformation elasticity* ($\theta^{max}$) and the directional bias of induced innovation under distributive and external constraints. It is a theoretical envelope, never a historical reality.

## 2. The Reality of "Becoming" (The Historical Path)
Capitalism is pure "becoming"—a dynamic process driven by contradiction, crisis, and disproportionality.
*   **Okishio's Anarchy:** Decentralized accumulation ensures that macro-disequilibrium and idle capacity are the norm, not the exception.
*   **Vidal's Friction:** The internally divided firm means that mechanization is contested, uneven, and historically mediated, rather than a smooth optimization.
*   **The Empirical Path:** The actual economy traces a "scarred" trajectory strictly *inside* or *disjointed from* the pure frontier.

## 3. The Ontological Role of $\mu_t$
Capacity utilization ($\mu_t$) is the **measure of the gap** between the abstraction of "not becoming" and the reality of "becoming."
*   When $\mu_t \neq 1$, it is the empirical fingerprint of Okishio's market anarchy and disproportionality.
*   $\mu_t$ is not a statistical residual to be minimized; it is the structural manifestation of capitalist contradiction.

## 4. Econometric Mapping (Basu-Compliant)
The dimensionally compliant FM-OLS cointegration model estimates the *historical average* of the shifting frontier, while capturing the reality of becoming:
$$ y_t = \alpha_0 + \beta_1 k^{nrc}_t + \beta_2 k^{me}_t + \beta_3 (\omega_t \cdot k^{me}_t) + \beta_4 (E_t \cdot k^{me}_t) + \tilde{\mu}_t $$

*   **The Slopes ($\beta$):** Map the shifting boundaries of the "not becoming" frontier as distribution ($\omega$) and external constraints ($E$) evolve.
*   **The Residual ($\tilde{\mu}_t$):** Captures the ontological distance of "becoming" (the failure of smooth reproduction).
*   **Threshold-FGLS (Regime Shifts):** Captures the dialectical ruptures where the contradictions of "becoming" force a structural reorganization of the frontier itself (shifting corridors).

---

## Locked Formulation
The smooth reproduction path ($\mu=1$) and the mechanization productive frontier are abstractions of "not becoming." They do not assume capitalist equilibrium or unified firm optimization. Rather, they provide the necessary analytical limit against which the historical reality of "becoming"—characterized by Okishio's market anarchy, Vidal's internal firm division, and fluctuating capacity utilization ($\mu_t \neq 1$)—is measured and identified.
