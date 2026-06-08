---
type: note
subtype: rule
status: active
layer: analytical_foundation
design_role: ontological_guardrail
scope: chapter2_core
related_to:
  - H02_Theta_to_Empirical_Coefficients
  - R01_Marx_Okishio_Regime_Diagnostic_Guardrail
  - Okishio_Vidal_Transformation_Elasticity
created: 2026-05-27
---

# The Frontier of "Not Becoming" vs. Historical "Becoming"

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