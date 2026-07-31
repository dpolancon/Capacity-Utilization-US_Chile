---
type: theory
status: active
depends_on:
  - chapter2_vault/00_constitutive_core/01_Governing_Memo.md
stage_scope: S00
country: US_CL
last_updated: 2026-07-25
updated_by: PERIPHERAL_DIVIDED_MANAGEMENT_PARKED_SYNTHESIS
subtype: analytical_foundation
layer: analytical_foundation
design_role: mechanism_definition
scope: chapter2_core
related_to:
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - H02_Peripheral_Divided_Management_and_World_System_Entanglement
  - N00_Mechanization_Analytical_References
  - N02_Peripheral_Mechanization_Constraint
  - R06_Regime_Gating_and_Diagnostic_Ladder
  - R05_Frontier_of_Not_Becoming
created: 2026-05-27
blocks: []
priority: reference
---

# A04: Peripheral Transformation Elasticity and FX-Constrained Profit Realization

## Core Claim
In the capitalist periphery, the transformation elasticity $\theta$ is not solely determined by domestic distributive conflict and the infrastructural envelope. It is structurally conditioned by foreign exchange (FX) availability and Balance of Payments (BoP) dynamics. 

Because intensive-margin ($K^{\text{ME}}$) accumulation and maintenance require imported capital goods, spare parts, and complementary intermediates, FX scarcity generates a **realization bottleneck**. When the BoP constraint binds, the *effective profit share* available for reinvestment is squeezed—not because surplus value is not produced, but because it cannot be converted into imported reinvestment goods. This truncates the capacity payoff of machinery accumulation, generating a regime-dependent, kinked peripheral transformation elasticity that structurally decouples nominal profitability from realized capacity formation.

---

## 1. The FX-Conversion Bottleneck and Macroeconomic Closure
The intensive margin's optimal mechanization rate requires the continuous deployment and maintenance of $K^{\text{ME}}$. In peripheral economies, a fraction of these inputs is technologically non-substitutable domestically. The total investment demand for the intensive margin is:
$$ i^{\text{ME}}_t = i^{\text{ME, dom}}_t + i^{\text{ME, imp}}_t $$
Realized accumulation depends on the ability to convert accounting surplus into imported reinvestment flows. Let $F^{\text{avail}}_t$ denote the exogenous foreign exchange envelope (exports, net capital inflows, reserves net of debt service and essential consumption imports). The FX requirement for intensive-margin accumulation is:
$$ F^{\text{req}}_t = \iota^{\text{imp}} \cdot P^{\text{ME, imp}}_t \cdot i^{\text{ME}}_t \cdot K^{\text{ME}}_{t-1} $$
where $\iota^{\text{imp}} \in (0,1]$ is the import intensity of machinery investment and maintenance. 

Aggregating the micro-foundation, and assuming investment is profit-led ($i^{\text{ME}}_t \propto \pi_t Y_t / K^{\text{ME}}_{t-1}$), the macro-level FX requirement simplifies to:
$$ F^{\text{req}}_t = \nu \cdot \pi_t \cdot Y_t $$
where $\nu$ captures the aggregate import-intensity parameter of the investment demand.

**The FX-Conversion Ratio:** The structural contradiction is gated by the FX-conversion ratio $\phi_t$, which measures the fraction of desired imported investment that can be financially realized:
$$ \phi_t = \min\left(1, \frac{F^{\text{avail}}_t}{F^{\text{req}}_t}\right) $$
- **Regime $E_A$ (FX Abundant / BoP Slack):** $F^{\text{avail}}_t \geq F^{\text{req}}_t \implies \phi_t = 1$.
- **Regime $E_B$ (FX Scarce / BoP Binding):** $F^{\text{avail}}_t < F^{\text{req}}_t \implies \phi_t < 1$. 

The gap $1 - \phi_t$ represents **blocked surplus**: accounting profits that cannot be materialized as productive reinvestment due to external payment constraints.

---

## 2. The Realization Wedge and Effective Profit Share
Let $\pi_t = 1 - \omega_t$ be the nominal profit share. The **effective profit share** available for realized reinvestment is:
$$ \pi^{\text{eff}}_t = \pi_t \cdot \phi_t $$

In the binding regime ($E_B$), substituting $\phi_t = \frac{F^{\text{avail}}_t}{\nu \pi_t Y_t}$ yields:
$$ \pi^{\text{eff}}_t = \pi_t \left( \frac{F^{\text{avail}}_t}{\nu \pi_t Y_t} \right) = \frac{F^{\text{avail}}_t}{\nu Y_t} $$

**Analytical Implication 1 (Distributional Invariance):** In Regime $E_B$, the effective profit share $\pi^{\text{eff}}_t$ becomes **strictly invariant to domestic distributive conflict** ($\pi_t$). Squeezing wages to raise $\pi_t$ does not increase $\pi^{\text{eff}}_t$; it merely expands the blocked surplus $(1-\phi_t)$. This analytically separates distributional conflict from external realization.

The intensive-margin accumulation rate responds to $\pi^{\text{eff}}$, not $\pi$:
$$ g_{K^{\text{ME}}, t} = \chi^{\text{ME}} \pi^{\text{eff}}_t - \delta^{\text{ME}} = \chi^{\text{ME}} \pi_t \phi_t - \delta^{\text{ME}} $$
When the BoP binds, the mechanization budget constraint tightens endogenously. The economy experiences a *peripheral accumulation wedge* where high nominal profitability coexists with low realized capacity formation.

---

## 3. Derivation of Peripheral Transformation Elasticity
The capacity payoff of machinery accumulation ($\theta_{\text{ME}}$) is defined as the marginal capacity expansion per unit of accounting investment (the inverse of the incremental capital-output ratio). 

**The Peripheral Efficiency Penalty:** When $\phi_t < 1$, the rationing of imported spare parts and complements induces a drop in capacity utilization and maintenance backlogs. We model this via a peripheral efficiency penalty $\Psi(\phi_t) \in (0,1]$, defined as:
$$ \Psi(\phi_t) = \phi_t^{\eta} $$
where $\eta \geq 1$ captures the rigidity of import complementarity (Leontief strictness). If a crucial imported spare part is missing, the entire machine may idle ($\eta > 1$).

The realized capacity growth of the intensive margin is therefore:
$$ g_{Y^{\text{ME}}} = \theta_{\text{ME, core}} \cdot \Psi(\phi_t) \cdot \left( \frac{I^{\text{ME}}}{Y^{\text{ME}}} \right) $$
Thus, the **effective peripheral transformation elasticity** for the intensive margin is:
$$ \theta_{\text{ME, periph}} = \theta_{\text{ME, core}} \cdot \Psi(\phi_t) = \theta_{\text{ME, core}} \cdot \phi_t^{\eta} $$

**Aggregate Aggregation:** The aggregate peripheral transformation elasticity $\theta_{\text{periph}}$ is the weighted average of the extensive margin ($\theta_{\text{NRC}}$) and the constrained intensive margin. Let $W_{\text{ME}} = \frac{s_{\text{ME}} g_{K^{\text{ME}}}}{(1-s_{\text{ME}}) g_{K^{\text{NRC}}} + s_{\text{ME}} g_{K^{\text{ME}}}}$ be the weight of the intensive margin in aggregate capital growth, where $s_{\text{ME}}$ is the machinery share of aggregate productive capital stock. The locked formulation is:
$$ \theta_{\text{periph}} = (1 - W_{\text{ME}}) \theta_{\text{NRC}} + W_{\text{ME}} \theta_{\text{ME, periph}} $$

---

## 4. Endogenous Regime Switching & The Accumulation Paradox
The model generates a profound structural paradox through endogenous regime switching. Because $F^{\text{req}}_t$ is an increasing function of $\pi_t$, aggressive domestic wage suppression can *trigger* the BoP constraint.

**Analytical Implication 2 (Absolute Immiserizing Accumulation):** 
Suppose the economy is initially in Regime $E_A$ ($\phi_t = 1$). A successful wage suppression raises $\pi_t$, which increases $F^{\text{req}}_t$. If $F^{\text{req}}_t$ exceeds $F^{\text{avail}}_t$, the economy is forced into Regime $E_B$. 
In $E_B$, as shown in Section 2, $\pi^{\text{eff}}_t = \frac{F^{\text{avail}}_t}{\nu Y_t}$. 
If the attempt to raise $\pi_t$ further depresses domestic output $Y_t$ (via demand-led channels), $\pi^{\text{eff}}_t$ will actually **fall**. Thus, attempting to accelerate accumulation via distributive conflict can mechanically collapse the effective profit share and the transformation elasticity. The induced innovation logic $q^*(\omega)$ is truncated not by wage pressure, but by the external realization gate.

---

## 5. Formal Comparative Statics and Expected Effects
To ensure analytical consistency and identify the expected effects of policy and structural shocks, we derive the formal partial derivatives of the model's core variables in the binding regime ($E_B$, where $\phi_t < 1$). 

### 5.1. Derivatives of the Realization Wedge
1. **FX Relaxation:** 
   $$ \frac{\partial \phi_t}{\partial F^{\text{avail}}_t} = \frac{1}{\nu \pi_t Y_t} > 0 \implies \frac{\partial \pi^{\text{eff}}_t}{\partial F^{\text{avail}}_t} = \frac{1}{\nu Y_t} > 0 $$
   *Effect:* An increase in foreign exchange directly relaxes the bottleneck, raising the effective profit share.
2. **Distributive Conflict (Nominal Profit Share):**
   $$ \frac{\partial \phi_t}{\partial \pi_t} = -\frac{F^{\text{avail}}_t}{\nu \pi_t^2 Y_t} < 0 \implies \frac{\partial \pi^{\text{eff}}_t}{\partial \pi_t} = 0 $$
   *Effect:* In the binding regime, the effective profit share is **strictly invariant** to domestic wage suppression. Raising $\pi_t$ merely expands the blocked surplus $(1-\phi_t)$ without increasing realized reinvestment capacity.

### 5.2. Derivatives of the Intensive-Margin Elasticity
1. **FX Relaxation:**
   $$ \frac{\partial \theta_{\text{ME, periph}}}{\partial F^{\text{avail}}_t} = \eta \theta_{\text{ME, core}} \phi_t^{\eta-1} \left( \frac{1}{\nu \pi_t Y_t} \right) > 0 $$
   *Effect:* More FX reduces maintenance backlogs and idle capacity, directly improving the capacity payoff of machinery.
2. **Distributive Conflict:**
   $$ \frac{\partial \theta_{\text{ME, periph}}}{\partial \pi_t} = \eta \theta_{\text{ME, core}} \phi_t^{\eta-1} \left( -\frac{F^{\text{avail}}_t}{\nu \pi_t^2 Y_t} \right) < 0 $$
   *Effect:* Aggressive wage suppression (higher $\pi_t$) increases import demand, worsening the FX bottleneck, which exacerbates the efficiency penalty and *lowers* the capacity payoff of machinery.
3. **Import Rigidity ($\eta$):**
   $$ \frac{\partial \theta_{\text{ME, periph}}}{\partial \eta} = \theta_{\text{ME, core}} \phi_t^{\eta} \ln(\phi_t) < 0 \quad (\text{since } \phi_t < 1 \implies \ln(\phi_t) < 0) $$
   *Effect:* Higher technological rigidity in imported complements strictly degrades the transformation elasticity.

### 5.3. Derivatives of the Aggregate Transformation Elasticity
Taking the total derivative of $\theta_{\text{periph}} = (1 - W_{\text{ME}}) \theta_{\text{NRC}} + W_{\text{ME}} \theta_{\text{ME, periph}}$ with respect to a variable $X$:
$$ \frac{\partial \theta_{\text{periph}}}{\partial X} = W_{\text{ME}} \frac{\partial \theta_{\text{ME, periph}}}{\partial X} + (\theta_{\text{ME, periph}} - \theta_{\text{NRC}}) \frac{\partial W_{\text{ME}}}{\partial X} $$

1. **Effect of FX Availability ($F^{\text{avail}}_t$):**
   Since $\frac{\partial g_{K^{\text{ME}}}}{\partial F^{\text{avail}}_t} = \frac{\chi^{\text{ME}}}{\nu Y_t} > 0$, the weight $W_{\text{ME}}$ increases with $F^{\text{avail}}_t$. Assuming machinery is more productive than the extensive margin ($\theta_{\text{ME, periph}} > \theta_{\text{NRC}}$), both terms are positive:
   $$ \frac{\partial \theta_{\text{periph}}}{\partial F^{\text{avail}}_t} > 0 $$
   *Effect:* FX accumulation unambiguously raises aggregate transformation elasticity.
2. **Effect of Distributive Conflict ($\omega_t$ or $\pi_t$):**
   Since $\frac{\partial g_{K^{\text{ME}}}}{\partial \pi_t} = 0$ in Regime $E_B$, the weight $W_{\text{ME}}$ is invariant to $\pi_t$. Thus:
   $$ \frac{\partial \theta_{\text{periph}}}{\partial \pi_t} = W_{\text{ME}} \frac{\partial \theta_{\text{ME, periph}}}{\partial \pi_t} < 0 $$
   Translating to the wage share ($\pi_t = 1 - \omega_t$):
   $$ \frac{\partial \theta_{\text{periph}}}{\partial \omega_t} = - \frac{\partial \theta_{\text{periph}}}{\partial \pi_t} > 0 $$
   *Effect (The Accumulation Paradox):* In a binding BoP regime, **increasing the wage share (lowering $\pi_t$) actually increases the aggregate transformation elasticity**. Wage moderation (squeezing $\omega$) exacerbates the FX bottleneck, triggering efficiency penalties that collapse realized capacity formation.

### 5.4. Summary of Expected Effects (Regime $E_B$)
| Shock / Variable | Effect on $\phi_t$ | Effect on $\pi^{\text{eff}}_t$ | Effect on $\theta_{\text{ME, periph}}$ | Effect on $\theta_{\text{periph}}$ |
| :--- | :---: | :---: | :---: | :---: |
| $\uparrow F^{\text{avail}}_t$ (FX inflow) | $+$ | $+$ | $+$ | $+$ |
| $\uparrow \pi_t$ (Wage suppression) | $-$ | $0$ | $-$ | **$-$** (Paradoxical) |
| $\uparrow \eta$ (Import rigidity) | $0$ | $0$ | $-$ | $-$ |

---

## 6. Contradictory Dynamics & Ontological Status
1. **Historical "Becoming" in the Periphery:** The gap $\pi - \pi^{\text{eff}}$ measures the **structural realization loss** due to FX scarcity. $\theta_{\text{periph}}$ is the empirical realization of Okishio's market anarchy intersecting with Prebisch/Thirlwall's external constraint.
2. **Not a Marginal Friction:** The BoP constraint does not act as a continuous tax or friction on the first-order conditions (FOC). It operates as a **regime gate** on profit realization. This preserves the analytical purity of the induced innovation mechanism while acknowledging that its materialization is structurally truncated by macro-external limits.
3. **Empirical Mapping:** In the Basu-compliant cointegration framework, this corresponds to regime-dependent slope shifts in the capacity reconstruction vector. Threshold diagnostics must gate breaks on external indicators (current account balance, FX reserves, terms of trade) alongside domestic closure conditions (`R06` & `R07`). The empirical interaction term ($\omega_t \cdot \kappa_t$) will exhibit sign instability or attenuation precisely when $\phi_t$ drops, signaling the transition from distributive to realization-gated accumulation.

---

## Locked Formulation
The peripheral transformation elasticity $\theta_{\text{periph}}$ captures the structural contradiction between domestic surplus generation and external payment realization. Because $K^{\text{ME}}$ accumulation is import-dependent, FX scarcity acts as a hard ceiling on the conversion of accounting profits into reinvestment flows. When the BoP binds, the effective profit share ($\pi^{\text{eff}} = \pi \cdot \phi$) is squeezed, and the capacity payoff is penalized by import-complementarity rigidities ($\Psi(\phi) = \phi^\eta$). Crucially, formal comparative statics reveal that in the binding regime, $\pi^{\text{eff}}$ becomes invariant to domestic distributive conflict, while higher nominal profitability ($\pi$) mechanically degrades the aggregate transformation elasticity ($\frac{\partial \theta_{\text{periph}}}{\partial \pi} < 0$). This generates an endogenous regime-switching paradox where aggressive wage suppression triggers the BoP constraint and collapses realized accumulation, structurally decoupling nominal profitability from realized capacity formation.