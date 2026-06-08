---
type: note
subtype: object
status: superseded
layer: analytical_foundation
design_role: mechanism_definition
scope: chapter2_core
related_to:
  - N00_Mechanization_Analytical_References
  - H01_Cajas_to_Transformation_Elasticity
  - H03_Double_Choice_of_Technique
  - R05_Frontier_of_Not_Becoming
  - Okishio_Vidal_Transformation_Elasticity
created: 2026-05-27
---

# N03: Two-Capital Mechanization and Transformation Elasticity

## Core Claim
Productive capacity formation is not a monolithic process governed by a single capital aggregate. It is structurally asymmetric, partitioned into an **extensive margin** (infrastructure/plant capacity) and an **intensive margin** (machinery/mechanization). 

This asymmetry generates a two-stage analytical determination:
1. A cost-minimization problem conditioned on the structural envelope yields a **normal rate of labor productivity**.
2. The interaction between accumulation demand and the dual-capital structure defines a **transformation elasticity** that maps investment into productive capacity.

Both objects are abstractions of smooth reproduction ("not becoming") and serve as theoretical benchmarks against which historical contradiction ("becoming") is measured.

---

## 1. The Dual Nature of Capital Stocks
Capital accumulation is decomposed into two functionally and temporally distinct stocks:

### 1.1 Extensive Margin: $K^{NRC}$ (Non-Residential Construction)
- **Role:** Defines the structural envelope or plant capacity.
- **Properties:** Lumpy, irreversible, slow-moving, financially constrained, and spatially fixed.
- **Analytical Function:** Sets the maximum physical scale of production. It is the *precondition* for technique choice, not the object of marginal adjustment.

### 1.2 Intensive Margin: $K^{ME}$ (Machinery & Equipment)
- **Role:** Defines the technique of production (mechanization).
- **Properties:** Continuous, mobile, subject to scrapping/depreciation, and tactically adjustable.
- **Analytical Function:** The active margin of induced innovation. It responds to distributive conflict and technological substitution within the bounds set by $K^{NRC}$.

**Complementarity Condition:** The productive potential of machinery is strictly conditioned by the structural envelope. A larger or better-quality plant raises both the ceiling and the marginal productivity of mechanization.

---

## 2. The Technological Frontier & Cost Minimization
Given the structural envelope $K^{NRC}$, the firm operates on a conditioned technological frontier:
$$ a = \Phi(q; K^{NRC}) $$
where $a = Y/L$ is labor productivity and $q = K^{ME}/L$ is the mechanization rate.

**Properties:**
- $\Phi_q > 0, \Phi_{qq} < 0$ (diminishing returns to mechanization)
- $\Phi_{K^{NRC}} > 0$ (infrastructure raises productivity ceiling)
- $\Phi_{q, K^{NRC}} > 0$ (marginal productivity of machinery increases with better infrastructure)

### 2.1 The Tactical Choice Problem
The firm minimizes unit labor-plus-capital cost:
$$ \min_{q} \ c(q) = \frac{w + \rho q}{\Phi(q; K^{NRC})} $$
where $w$ is the nominal wage and $\rho$ is the user cost of machinery.

### 2.2 First-Order Condition (Induced Innovation)
Differentiating with respect to $q$ and setting to zero:
$$ \frac{\rho \Phi - (w + \rho q)\Phi_q}{\Phi^2} = 0 \implies \frac{\Phi_q \cdot q}{\Phi} = \frac{\rho q}{w + \rho q} $$
Define:
- $\epsilon_{a,q} = \frac{\Phi_q q}{\Phi}$: elasticity of labor productivity with respect to mechanization.
- $\sigma_{me}(\omega) = \frac{\rho q}{w + \rho q}$: machinery cost share, which is inversely related to the wage share $\omega$.

The optimal mechanization rate satisfies:
$$ \epsilon_{a,q}(q^*; K^{NRC}) = \sigma_{me}(\omega) $$

**Analytical Implication:** Distributive pressure ($\omega \uparrow$) increases the relative cost of labor, forcing the firm to choose a higher mechanization rate ($q^* \uparrow$) to restore unit cost efficiency. The optimal technique is explicitly conditional on both distribution and the structural envelope:
$$ q^* = q(\omega, K^{NRC}) $$

---

## 3. Normal Rate of Labor Productivity
Substituting the optimal technique back into the technological frontier yields the **normal rate of labor productivity** under smooth reproduction:
$$ a^N(\omega, K^{NRC}) = \Phi\left(q(\omega, K^{NRC}); K^{NRC}\right) $$

**Interpretation:**
- This is the frictionless, "not becoming" benchmark. It represents the maximum labor productivity achievable given the current wage share and infrastructural envelope.
- It is not a historical average; it is a structural limit derived from the cost-minimization FOC.
- Changes in $\omega$ shift the optimal technique along the frontier, altering $a^N$ without changing the frontier itself. Changes in $K^{NRC}$ shift the entire frontier outward.

---

## 4. Transformation Elasticity of Accumulation to Productive Capacity
The transformation elasticity ($\theta^N$) measures how effectively accumulation demand translates into productive capacity growth. In a two-capital framework, it is not a scalar constant but a composition-weighted structural parameter.

### 4.1 Analytical Definition
Let $g_{K^{NRC}}$ and $g_{K^{ME}}$ denote the growth rates of the two capital stocks. Total capital growth is composition-weighted: $g_K^N = s \cdot g_{K^{ME}} + (1-s) \cdot g_{K^{NRC}}$, where $s = K^{ME}/K$.

Productive capacity growth follows from differentiating the capacity envelope:
$$ g_Y^p = \theta^{NRC} g_{K^{NRC}} + \theta^{ME}(\omega) g_{K^{ME}} $$
where:
- $\theta^{NRC} = \frac{\partial \ln \Gamma(K^{NRC})}{\partial \ln K^{NRC}}$: baseline capacity payoff of infrastructure.
- $\theta^{ME}(\omega) = 1 + \frac{a^N(\omega, K^{NRC}) - q^*(\omega, K^{NRC})}{g_{K^{NRC}}}$: distributively conditioned payoff of machinery accumulation.

### 4.2 The Aggregate Transformation Elasticity
The effective transformation elasticity of total accumulation demand to productive capacity is defined as:
$$ \theta^N(\omega, s, K^{NRC}) = \frac{g_Y^p}{g_K^N} = \frac{\theta^{NRC}(1-s) g_{K^{NRC}} + \theta^{ME}(\omega) s g_{K^{ME}}}{(1-s) g_{K^{NRC}} + s g_{K^{ME}}} $$

**Key Properties:**
1. **Regime-Dependent:** $\theta^N$ is not globally stable. It fluctuates with the wage share ($\omega$), the capital composition ($s$), and the relative growth rates of the two stocks.
2. **Distributive Modulation:** When $\omega$ rises, $q^*$ increases, raising $\theta^{ME}(\omega)$. If accumulation shifts toward machinery ($s \uparrow$), the aggregate $\theta^N$ rises. This is the analytical core of induced innovation.
3. **Envelope Constraint:** $\theta^N$ is bounded above by $\theta^{NRC}$ when $s \to 0$, and asymptotically approaches $\theta^{ME}(\omega)$ when $s \to 1$. The infrastructure stock acts as a drag or catalyst depending on its growth relative to machinery.

### 4.3 Alternative Gap Formulation (Consistency with H01)
Following the analytical tradition in H01, the transformation elasticity can also be expressed as a structural gap between productivity growth and mechanization growth, normalized by normal accumulation:
$$ \theta_t^N = 1 + \frac{a_t - q_t}{g_{K,t}^N} $$
In the two-capital framework, $a_t - q_t$ is not a residual. It is the **net capacity effect** of shifting the technique frontier under the envelope constraint. When $a_t > q_t$, accumulation yields super-linear capacity expansion (high $\theta^N$). When $a_t < q_t$, accumulation is capacity-intensive but productivity-weak (low $\theta^N$).

---

## 5. Analytical Implications & Regime Dependence
1. **The Frontier of "Not Becoming":** $a^N(\omega, K^{NRC})$ and $\theta^N(\omega, s, K^{NRC})$ are abstractions of smooth reproduction. They define the maximum structural efficiency of the accumulation process under idealized coordination.
2. **Okishio-Vidal Friction:** In reality, decentralized accumulation and internally divided firms prevent the economy from residing on this frontier. The actual labor productivity $a_t$ and utilization $\mu_t$ deviate systematically from $a^N$ and $\theta^N$.
3. **Structural Shifts:** Regime changes (e.g., institutional wage bargaining, financialization, import substitution) alter the parameters of $\Phi(\cdot)$ or the constraint set on $K^{NRC}$. This shifts the frontier itself, causing structural breaks in $\theta^N$ independent of cyclical fluctuations.

---

## Locked Formulation
Productive capacity formation is governed by a structural asymmetry between infrastructure ($K^{NRC}$) and machinery ($K^{ME}$). Infrastructure defines the extensive envelope, while machinery defines the intensive margin of technique choice. Cost minimization under distributive pressure yields a normal rate of labor productivity $a^N(\omega, K^{NRC})$, which serves as the smooth reproduction benchmark. The transformation elasticity $\theta^N$ is not a technical constant; it is a composition-weighted, distributively conditioned structural parameter that maps accumulation demand to productive capacity growth. Both objects are analytical abstractions of "not becoming," providing the necessary geometric and theoretical limits against which the contradictory reality of capitalist accumulation is measured.


