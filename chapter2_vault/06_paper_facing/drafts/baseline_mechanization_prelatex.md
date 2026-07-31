---
type: paper_facing
status: draft
country: US_CL
stage_scope: N/A
last_updated: '2026-07-29'
depends_on: []
blocks: []
layer: design
scope: chapter2
priority: context
---

# Baseline Model of Cost-Minimizing Mechanization and Transformation Elasticity

## 1. Executive Summary & Core Framework

This section establishes the micro-foundations and aggregate mechanics of technical change in Chapter 2. We formalize how distributive conflict between labor and capital conditions the firm's choice of technique, determining the structural efficiency with which capital accumulation translates into productive capacity expansion.

Standard macroeconomic frameworks treat technical change as an exogenous process or assume that capacity utilization smoothly adjusts to hit a target "normal" rate. We explicitly reject both assumptions. Grounded in heterodox political economy (Basu 2022; Cajas Guajirro 2024; Dumenil & Levy 1995; Foley 1986), we model the choice of technique as an endogenous response to wage pressure under technological constraints.

Crucially, our framework distinguishes between three operational layers:
1. **Layer 1 (Baseline):** Homogeneous capital stock where technical change operates along a single mechanization frontier.
2. **Layer 2 (Heterogeneous Capital):** Two capital assets — Nonresidential Structures ($K^{NRC}$) as the extensive physical envelope, and Machinery & Equipment ($K^{ME}$) as the intensive tactical margin.
3. **Layer 3 (Peripheral Extension):** External balance-of-payments constraints and foreign-exchange strain gating profit realization and machinery accumulation.

---

## 2. Layer 1: Baseline Model (Homogeneous Capital Stock)

### 2.1 Accounting Identity and Leontief Production Structure

Following heterodox political economy, actual aggregate output is represented using a Leontief production function with fixed technical coefficients:

$$ Y = \min\left( A L, \ \mu B K \right) $$

where $A = Y/L$ is actual labor productivity, $\mu = Y/Y^p$ is capacity utilization, and $B = Y^p/K$ is maximum capital productivity (capacity per unit of capital). This production structure directly governs the rate of profit ($r$) through the fundamental heterodox accounting identity:

$$ r = \mu B (1 - \omega) $$

where $\omega$ is the wage share. Standard models treat $B$ as an exogenous technological parameter and $\mu$ as a behavioral constant smoothly targeted by a unified firm. Instead, we treat the components of the profit rate identity as endogenous outcomes of class struggle and decentralized market anarchy.

### 2.2 Tactical Choice of Technique and Induced Innovation

Firms select a mechanization growth rate $q$ to maximize the net productivity surplus. Let $a$ represent the growth rate of labor productivity and $\omega$ the wage share. The effective distributive cost of deploying mechanization growth is $q(1-\omega)$. The firm solves the tactical optimization problem:

$$ \max_{q} \ c(q) = a - q(1-\omega) $$

This objective captures the induced-innovation logic: firms accelerate mechanization to expand labor productivity growth ($a$), but the distributive cost of capital intensity ($1-\omega$) holds them back. A technological frontier bounds this choice:

$$ a = \Phi(q) = \lambda_0 + \lambda_1 q + \lambda_2 q^2 $$

The frontier parameters govern the structural limits of technical change:
- $\lambda_0 > 0$: Base productivity growth without advanced machinery.
- $\lambda_1 > 0$: Direct productivity payoff of mechanization.
- $\lambda_2 < 0$: Concavity parameter enforcing diminishing marginal returns to mechanization.

Substituting the technological frontier into the objective function yields:

$$ c(q) = \lambda_0 + (\lambda_1 - (1-\omega)) q + \lambda_2 q^2 $$

Differentiating with respect to $q$ and setting the result to zero yields the first-order condition (FOC) for optimal mechanization growth:

$$ \frac{dc}{dq} = \lambda_1 - (1-\omega) + 2\lambda_2 q^* = 0 $$

Solving for optimal mechanization growth $q^*$ gives:

$$ q^*(\omega) = \frac{(1-\omega) - \lambda_1}{2\lambda_2} $$

The strict concavity of the frontier ($c''(q) = 2\lambda_2 < 0$) guarantees a unique, stable maximum. Differentiating $q^*$ with respect to the wage share $\omega$ establishes the **induced innovation mechanism**:

$$ \frac{\partial q^*}{\partial \omega} = -\frac{1}{2\lambda_2} > 0 $$

A rise in the wage share ($\omega \uparrow$) forces cost-minimizing firms to substitute machinery for labor. Rising wages drive mechanization directly through the FOC, pushing optimal capital intensity growth $q^*$ upward.

### 2.3 Endogenous Transformation Elasticity

Substituting the optimal technique back into the technological frontier recovers normal labor productivity growth under smooth reproduction:

$$ a^N(\omega) = \lambda_0 + \lambda_1 q^*(\omega) + \lambda_2 \left[ q^*(\omega) \right]^2 $$

This optimal technique dictates the trajectory of maximum capital productivity ($B = Y^p / K$). Expressed in dynamic growth rates, the growth of capital productivity ($b$) is the difference between capacity growth and capital accumulation ($b = g_{Y^p} - g_K$), or equivalently, the gap between labor productivity growth and mechanization growth ($b = a - q$).

Evaluated at the smooth reproduction benchmark, this optimal gap is $b^N(\omega) = a^N(\omega) - q^*(\omega)$.

We define the **transformation elasticity** ($\theta$) as the structural parameter translating capital accumulation into productive capacity growth ($g_{Y^p} = \theta g_K$). Substituting this definition into the growth rate of capital productivity ($b = \theta g_K - g_K$) reveals the fundamental mathematical link between the level coefficient $B$ and the elasticity $\theta$:

$$ \theta = 1 + \frac{b}{g_K} $$

To evaluate this elasticity, we anchor the optimal technique to the normal rate of capital accumulation ($g_K^N$), driven by the normal profit rate ($r^N$) and normal recapitalization share ($\chi^N$), net of depreciation ($\delta$):

$$ g_K^N = \chi^N r^N - \delta $$

Expressed dynamically relative to this normal accumulation path, the aggregate transformation elasticity becomes:

$$ \theta(\omega) = 1 + \frac{b^N(\omega)}{g_K^N} = 1 + \frac{a^N(\omega) - q^*(\omega)}{g_K^N} $$

The transformation elasticity is not an exogenous technical constant. It emerges endogenously from the cost-minimizing choice of technique under distributive pressure.

---

## 3. Layer 2: Heterogeneous Capital and Two-Capital Composition

### 3.1 Stock-Flow Consistency and GPIM Valuation Discipline

Capital is not homogeneous. We decompose aggregate capital into two physically distinct asset classes:
- **Nonresidential structures ($K^{NRC}$):** extensive physical envelope.
- **Machinery and equipment ($K^{ME}$):** intensive margin of tactical technique choice.

To prevent relative price drift from distorting capacity metrics, we impose strict stock-flow accounting discipline. Current-cost investment flows ($I_{j,t}^V$) are deflated by asset-specific price indexes ($P_{j,t}^K$):

$$ I_{j,t}^R = \frac{I_{j,t}^V}{P_{j,t}^K} \quad \text{for } j \in \{ME, NRC\} $$

The **gross real GPIM stock** ($K^{G,R}$) is reconstructed account by account using asset-specific service lives ($L_j$) and Weibull survival distributions ($\rho_j$):

$$ K_{j,t}^{G,R} = \text{GPIM}(I_{j,t}^R, \rho_j, L_j) $$

Gross real GPIM stocks track capital goods still in physical operation. They provide the correct capacity-relevant stock measure, isolating capacity from accounting depreciation and financial write-downs.

The capacity composition share is estimated directly from gross real GPIM stocks:

$$ s_t = \frac{K_{ME,t}^{G,R}}{K_{NRC,t}^{G,R} + K_{ME,t}^{G,R}} $$

Because all stocks are reconstructed from asset-specific deflators and survival curves, $s_t$ is a pure real-volume proxy, strictly reflecting real accumulation differentials ($g_{K^{ME}} \neq g_{K^{NRC}}$).

### 3.2 Nested Leontief Structure and Margins of Accumulation

Actual aggregate output is constrained by a nested Leontief structure:

$$ Y = \min\left( A L, \ \mu B^{NRC} K^{NRC}, \ \mu B^{ME} K^{ME} \right) $$

The extensive margin ($K^{NRC}$) evolves along a long-horizon reproduction corridor ($g_{K^{NRC}}^N = \chi^N r^N - \delta^{NRC}$). Multi-year plant commitments filter out short-run wage bargaining, making the extensive margin structurally insensitive to distribution ($\partial K^{NRC} / \partial \omega = 0$).

Conversely, the intensive margin ($K^{ME}$) is the direct instrument of technique choice. Its capacity yield ($B^{ME}$) is distribution-conditioned ($b^{ME}(\omega) = a^N(\omega) - q^*(\omega)$).

This yields the heterogeneous potential capacity function:

$$ Y^p = \min\left( B^{NRC} K^{NRC}, \ B^{ME}(\omega) K^{ME} \right) $$

### 3.3 Theoretical Underpinning of Cointegration ($\tau_t$)

For smooth reproduction, plant envelope and machinery must move in proportional lockstep:

$$ B^{NRC} K^{NRC} = B^{ME}(\omega) K^{ME} $$

Taking logarithms and normalizing on Machinery ($K^{ME}$) yields the long-run structural equilibrium:

$$ \ln K^{ME} = \left[ \ln B^{NRC} - \ln B^{ME}(\omega) \right] + \ln K^{NRC} $$

This establishes that the capital composition variable $\tau_t = \ln K^{ME}_t - \ln K^{NRC}_t$ is stationary or mean-reverting around structural shifts. We estimate this equilibrium via the cointegrating vector:

$$ \ln K^{ME}_t = \hat{\alpha} + \hat{\gamma} \ln K^{NRC}_t + \hat{u}_t $$

Under balanced Fordist mechanization, $\hat{\gamma} \approx 1$ ($\hat{\gamma} = 1.006$ for the US and $\hat{\gamma} = 1.047$ for Chile). Under neoliberal restructuring, spatial and financial constraints decouple machinery turnover from structural plant expansion ($\hat{\gamma} = 4.22$ in the US post-1973).

---

## 4. Layer 3: Peripheral Extension (Foreign Strain and Balance of Payments)

In peripheral economies, machinery accumulation ($K^{ME}$) requires imported capital goods, spare parts, and technology. Foreign exchange (FX) scarcity generates a **realization bottleneck**.

Let $F^{\text{avail}}_t$ denote available foreign exchange and $F^{\text{req}}_t = \mu_{\text{imp}} P^{ME, \text{imp}}_t i^{ME}_t$ the import requirement. The FX-conversion ratio is:

$$ \phi_t = \min\left(1, \frac{F^{\text{avail}}_t}{F^{\text{req}}_t}\right) $$

When the balance of payments binds ($\phi_t < 1$), accounting profits cannot be converted into imported machinery. The **effective profit share** available for reinvestment is squeezed:

$$ \pi^{\text{eff}}_t = (1 - \omega_t) \phi_t $$

The intensive-margin accumulation rate responds directly to $\pi^{\text{eff}}$:

$$ g_{K^{ME}, t} = \chi^{ME} (1-\omega_t) \phi_t - \delta^{ME} $$

When $\phi_t < 1$, the induced innovation mechanism $q^*(\omega)$ is truncated not by domestic wage pressure, but by structural foreign-exchange rationing. The peripheral transformation elasticity becomes kinked and regime-dependent:

$$ \theta^N_{\text{periph}} = \frac{\theta^{NRC}(1-s) g_{K^{NRC}} + \theta^{ME}_{\text{periph}} \cdot s \cdot (\chi^{ME} \pi^{\text{eff}} - \delta^{ME})}{(1-s) g_{K^{NRC}} + s \cdot (\chi^{ME} \pi^{\text{eff}} - \delta^{ME})} $$

High nominal profitability coexists with low realized capacity formation—a structural accumulation wedge imposed by peripheral financial subordination.
