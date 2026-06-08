---
type: note
subtype: object
status: active
layer: analytical_foundation
design_role: mechanism_definition
scope: chapter2_core
related_to:
  - N00_Mechanization_Analytical_References
  - A01_Extensive_Accumulation
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - A04_PeripheralTransformationElasticity
  - H03_Double_Choice_of_Technique
  - R05_Frontier_of_Not_Becoming
  - R06_Regime_Gating_and_Diagnostic_Ladder
created: 2026-05-27
updated: 2026-05-27
---

# A02: Intensive Accumulation: Choice of Technique and Mechanization Optimization

## Core Claim
The optimization over mechanization is not a unified, globally coherent profit-maximization problem. It is a **conditional cost-surplus maximization** along a technological frontier strictly conditioned by the structural envelope ($K^{NRC}$). 

This optimization yields a normal rate of labor productivity and serves exclusively as the analytical abstraction of **"not becoming"** (smooth reproduction limit). Historical deviations from this limit capture Okishio's market anarchy, Vidal's internal firm division, and utilization gaps.

---

## 1. Problem Statement & Objective Function
Given a fixed infrastructural envelope, the tactical margin of accumulation chooses the mechanization rate $q = K^{ME}/L$ to optimize the net productivity surplus:
$$ \max_{q} \ c(q) = a - q\pi $$
where:
- $a = Y/L$ is labor productivity
- $\pi = 1-\omega$ is the nominal profit share (proxy for the unit cost of mechanization net of wage pressure)
- $q\pi$ represents the effective cost of deploying machinery per worker

The objective captures the Marxian/induced-innovation logic: mechanization is pursued to expand productivity ($a$), but is constrained by the distributive cost of capital intensity $\pi$.

---

## 2. Technological Frontier & Infrastructure Conditioning
The choice is bounded by a mechanization productive frontier that is **explicitly conditioned** on the extensive margin:
$$ a = \Phi(q; K^{NRC}) = \lambda_0^{[s]} + \lambda_1^{[s]}q + \lambda_2^{[s]}q^2 $$

**Properties:**
- $\lambda_0^{[s]} > 0$: Base productivity level rises with better infrastructure
- $\lambda_1^{[s]} > 0$: Linear mechanization payoff increases with plant scale and logistical efficiency
- $\lambda_2^{[s]} < 0$: Diminishing marginal productivity of mechanization (concavity condition)
- $\frac{\partial \lambda_i^{[s]}}{\partial \omega} = 0$: Frontier parameters are structurally determined, not distributively shifted. They remain constant within regime $s$ and jump discretely only when extensive-margin reorganization occurs ($s \to s'$), per [[R06_Regime_Gating_and_Diagnostic_Ladder]].

**Analytical Role of $K^{NRC}$:** Infrastructure does not enter the objective function as an optimization variable or an interactive term with $\pi$. It strictly shifts the technological frontier via regime-indexed constants, altering the ceiling, marginal payoff, and curvature of the mechanization choice.

---

## 3. First-Order Condition & Optimal Mechanization
Substituting the regime-conditioned frontier into the objective yields the unconstrained tactical problem:
$$ c(q) = \lambda_0^{[s]} + \left[ \lambda_1^{[s]} - \pi \right]q + \lambda_2^{[s]}q^2 $$

**FOC:** Differentiating with respect to $q$ and setting to zero:
$$ \frac{dc}{dq} = \lambda_1^{[s]} - \pi + 2\lambda_2^{[s]}q^* = 0 $$

**Optimal Mechanization Rate:**
$$ q^*(\pi, s) = \frac{\pi - \lambda_1^{[s]}}{2\lambda_2^{[s]}} $$

**Comparative Statics (Induced Innovation):**
$$ \frac{\partial q^*}{\partial \pi} = \frac{1}{2\lambda_2^{[s]}} < 0 \quad \text{(since } \lambda_2^{[s]} < 0\text{)} $$
Higher profit share $\pi$ (lower distributive pressure $\omega$) mechanically shifts the optimal technique toward lower mechanization. Equivalently, rising $\omega \implies \pi \downarrow \implies q^* \uparrow$. The cost-minimizing response to wage bargaining is the expansion of $q^*$ along the frontier.

**Second-Order Condition:** $c''(q) = 2\lambda_2^{[s]} < 0$ ensures an interior, stable maximum.

---

## 4. Normal Labor Productivity (Smooth Reproduction Benchmark)
Substituting $q^*$ back into the regime-conditioned frontier yields the **normal rate of labor productivity**:
$$ a^N(\pi, s) = \lambda_0^{[s]} + \lambda_1^{[s]}q^* + \lambda_2^{[s]}(q^*)^2 $$
*(Note: $a^N(\pi, s) \equiv a^N(\omega, s)$ with $\pi = 1-\omega$, ensuring direct compatibility with the capacity identity in [[A03_TransformationElasticity_Two-CapitalCapacityComposition]].)*

**Interpretation:**
- $a^N$ is the frictionless productivity ceiling achievable under the current profit share and structural regime.
- It is a **structural limit**, not a historical average.
- Changes in $\pi$ shift the optimal technique along the frontier, altering $a^N$ without changing the frontier itself.
- The frontier parameters $\lambda_i^{[s]}$ remain strictly constant within regime $s$. They only jump to new values when the extensive margin undergoes discrete structural reorganization.

---

## 5. Ontological Status: The Optimization as "Not Becoming"
Per the Okishio-Vidal articulation and [[R05_Frontier_of_Not_Becoming]], this optimization problem **does not assume** a representative, unified firm solving a global profit-maximization problem. Instead:

1. **Abstraction of "Not Becoming":** $q^*(\pi, s)$ and $a^N(\pi, s)$ represent the smooth reproduction benchmark under idealized coordination. They define the geometric boundary of what is technically and distributively possible.
2. **Historical "Becoming":** Real accumulation is decentralized, internally divided, and crisis-prone. Firms rarely operate exactly at $q^*$. The actual mechanization rate $q_t$ and productivity $a_t$ deviate systematically due to:
   - Capitalist market anarchy (Okishio)
   - Contested capacity conventions and internal firm division (Vidal)
   - Financial constraints and external wedges
3. **Peripheral Truncation:** In the capitalist periphery, FX scarcity may further squeeze the realized accumulation rate via $\pi^{eff} = \pi \cdot \phi_t$ (per [[A04_PeripheralTransformationElasticity]]). This does not alter the analytical benchmark; it truncates its materialization, widening the gap between $a^N$ and historical $a_t$.
4. **Analytical Function:** The optimization provides the necessary theoretical limit against which historical contradiction is measured. The gap $a_t - a^N$ and the resulting utilization deviation $\mu_t \neq 1$ are the empirical fingerprints of capitalist "becoming."

---

## Locked Formulation
The tactical choice of technique is formalized as a cost-surplus maximization over the mechanization rate, subject to a technological frontier strictly conditioned by the structural envelope ($K^{NRC}$) and parameterized by regime-indexed constants ($\lambda^{[s]}$). The first-order condition yields an optimal mechanization rate that responds positively to distributive pressure, capturing the induced innovation mechanism. The resulting normal labor productivity ($a^N$) is not a behavioral prediction but an analytical abstraction of "not becoming" (smooth reproduction). It serves exclusively as the theoretical benchmark against which the contradictory reality of decentralized accumulation, internal firm division, and peripheral realization constraints are measured. Infrastructure conditions the frontier; distribution shifts the optimal technique along it. Neither interacts across margins.