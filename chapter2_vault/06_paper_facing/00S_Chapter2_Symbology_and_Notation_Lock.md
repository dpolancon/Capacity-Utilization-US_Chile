---
type: paper_facing
status: active
depends_on:
  - chapter2_vault/06_paper_facing/others/Ch2_Outline_DEFINITIVE.md
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - chapter2_vault/02_analyitical_foundation/A04_PeripheralTransformationElasticity.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-26
updated_by: SYMBOLOGY_AND_NOTATION_LOCK
layer: governance_constraint
role: paper_symbology_lock
scope: chapter2
priority: core
tags:
  - chapter2/symbology
  - chapter2/notation
  - chapter2/paper-facing
  - chapter2/peripheral_model
subtype: paper_facing_lock
blocks: []
---

# 00S: Chapter 2 Symbology and Notation Lock

> [!IMPORTANT]
> **Constitutional Declaration**: This file locks the **definitive mathematical notation, variable naming, parameter indexing, and terminology rules** for Chapter 2 across all empirical models (Specification A and Specification B), analytical foundations (including the Peripheral FX-Constrained Model), reports, vault notes, and execution code.

---

## 1. Master Notation Table

| Role | Symbol | Description & Usage Constraints |
| :--- | :--- | :--- |
| **Capacity Utilization** | $\mu_t$ | $\mu_t = Y_t / Y_t^p$ — **Never use $u$ or $u_t$** (reserved strictly for residual error terms). |
| **Recapitalization Rate** | $\chi_t$ | $\chi_t = I_t / \Pi_t$ — **Never use $\beta_t$**. |
| **Intensive-Margin Accumulation Param.** | $\chi^{\text{ME}}$ | Sensitivity of intensive-margin capital growth to the effective profit share. |
| **Mechanization Growth Rate** | $q$ | $q = \Delta \ln(K^{\text{ME}}/L)$ — **Never use $m$** (reserved for import share/propensity). |
| **Constant Intercept** | $\alpha$ | Cointegrating regression intercept (stands outside the transformation derivative $\frac{d Y^p}{d K} = \theta$). |
| **Transformation Elasticity Terms** | $\theta_j$ | All parameters governing capital variables or capital interacted with distribution/composition that enter the derivative $\frac{d Y^p}{d K} = \theta$: $\theta_K, \theta_{\text{NRC}}, \theta_{\kappa}, \theta_{\omega K}, \theta_{\omega \kappa}, \theta_{\kappa p^{\kappa}}$. |
| **Peripheral Transformation Elasticities**| $\theta_{\text{periph}}, \theta_{\text{ME, periph}}, \theta_{\text{ME, core}}$ | Aggregate peripheral elasticity, constrained intensive-margin elasticity, and core unconstrained intensive-margin elasticity. |
| **Standalone Controls** | $\beta_j$ | Uninteracted control coefficients: $\beta_{\omega}$ (standalone wage share), $\beta_{p^{\kappa}}$ (standalone relative price). |
| **Relative Price Variable** | $p_t^i$ | Relative price variable ($i$ indexes the ratio, e.g. $p_t^{\kappa} = \ln P^{\text{ME}} - \ln P^{\text{NRC}}$). Excluded from Spec A; included in Spec B. |
| **Relative Price Coefficient** | $\beta_{p^{\kappa}}$ | Econometric coefficient on relative price term $p_t^{\kappa}$ (never $\gamma$). |
| **Capital Composition Ratio** | $\kappa_t$ | $\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$ — **Replaces $\tau_t$**. |
| **Step Dummy Controls** | $\boldsymbol{\gamma}' \mathbf{D}_t$ / $\boldsymbol{\Gamma} \mathbf{D}_t$ | $\boldsymbol{\gamma}' \mathbf{D}_t$ ($1 \times 1$ scalar for single equation) or $\boldsymbol{\Gamma} \mathbf{D}_t$ ($K \times 1$ vector for multi-equation system). |
| **Net Capital Depreciation Rate** | $\delta$ | Economic depreciation rate of net capital stock (CFC) in growth accounting and stock-flow modeling. **Never used for step dummies.** |
| **Gross Capital Depletion Rate** | $z$ | Physical discard / retirement rate of gross capital in operation, distinct from net depreciation $\delta$. |
| **Mechanization Function** | $\lambda$ | Parameters governing the mechanization function. |
| **FX-Conversion Ratio** | $\phi_t$ | Fraction of desired imported investment financially realized: $\phi_t = \min(1, F^{\text{avail}}_t / F^{\text{req}}_t)$. |
| **Foreign Exchange Envelopes** | $F^{\text{avail}}_t, F^{\text{req}}_t$ | Available FX envelope and required FX for intensive-margin accumulation. |
| **Effective Profit Share** | $\pi^{\text{eff}}_t$ | Realized profit share available for reinvestment: $\pi^{\text{eff}}_t = \pi_t \cdot \phi_t$. |
| **Macro Import Intensity** | $\nu$ | Aggregate import-intensity parameter of investment demand ($F^{\text{req}}_t = \nu \pi_t Y_t$). **Never use $\mu$** (reserved for capacity utilization). |
| **Micro Import Intensity** | $\iota^{\text{imp}}$ | Import intensity of machinery investment and maintenance at the firm/sector level. |
| **Peripheral Efficiency Penalty** | $\Psi(\phi_t)$ | Function capturing maintenance backlogs/idle capacity due to FX rationing: $\Psi(\phi_t) = \phi_t^\eta$. **Never use $\kappa$** (reserved for capital composition) or **$\mu$**. |
| **Import Rigidity Parameter** | $\eta$ | Leontief strictness of import complementarity ($\eta \geq 1$). |
| **Intensive Margin Weight** | $W_{\text{ME}}$ | Weight of the intensive margin in aggregate capital growth. |
| **Peripheral Regimes** | $E_A, E_B$ | $E_A$: FX Abundant / BoP Slack ($\phi_t = 1$). $E_B$: FX Scarce / BoP Binding ($\phi_t < 1$). |
| **Frontier Terminology** | **MPF** | **Mechanization Productive Frontier** (never "Maximum Productive Frontier" or "IPF"). |
| **Harrodian Terminology** | **Harrodian knife-edge** | **Harrodian knife-edge** (never "Harrodian benchmark"). |
| **Natural Growth Rate** | **Natural rate of growth** | Growth rate absorbing population growth at given productivity growth rate (unblocked for explicit analytical reference, non-binding for paper). |

---

## 2. Specification Subscript Indexing Rules ($j$)

### Specification A: Aggregate Capital Model
Cointegrating equation:
$$y_t = \boldsymbol{\gamma}' \mathbf{D}_t + \alpha + \theta_K k_t^{\text{cap}} + \beta_{\omega} \omega_t + \theta_{\omega K} (\omega_t \cdot k_t^{\text{cap}}) + u_t$$

* **Subscript Index Set**: $j \in \{K, \omega K\}$
* **Aggregate Transformation Elasticity**:
  $$\theta_A(\omega_t) = \frac{\partial y_t}{\partial k_t^{\text{cap}}} = \theta_K + \theta_{\omega K} \omega_t = \sum_{j \in \{K, \omega K\}} \theta_j X_j^{(k)}$$

---

### Specification B: Capital Composition-Mediated Model

#### 1. Spec B1: Linear Uninteracted Baseline Model
Cointegrating equation:
$$y_t^{\text{NFC}} = \boldsymbol{\gamma}' \mathbf{D}_t + \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \theta_{\kappa} \kappa_t + \beta_{p^{\kappa}} p_t^{\kappa} + \beta_{\omega} \omega_{t-1} + u_t$$

* **Subscript Index Set**: $j \in \{\text{NRC}, \kappa\}$
* **Total Derivative Aggregate Transformation Elasticity**:
  $$\theta_t^{\text{SpecB1}} \equiv \frac{d y_t^p}{d k_t^{\text{cap}}} = \frac{\theta_{\text{NRC}} + \theta_{\kappa} \frac{d \kappa_t}{d k_t^{\text{NRC}}}}{1 + s_{\text{ME}, t} \, \frac{d \kappa_t}{d k_t^{\text{NRC}}}}$$

---

#### 2. Spec B2: Distributionally Interacted Mechanization Model
Cointegrating equation:
$$y_t^{\text{NFC}} = \boldsymbol{\gamma}' \mathbf{D}_t + \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \theta_{\kappa} \kappa_t + \beta_{p^{\kappa}} p_t^{\kappa} + \beta_{\omega} \omega_{t-1} + \theta_{\omega \kappa} (\kappa_t \cdot \omega_{t-1}) + u_t$$

* **Subscript Index Set**: $j \in \{\text{NRC}, \kappa, \omega \kappa\}$
* **Total Derivative Aggregate Transformation Elasticity**:
  $$\theta_t^{\text{SpecB2}}(\omega_{t-1}) \equiv \frac{d y_t^p}{d k_t^{\text{cap}}} = \frac{\theta_{\text{NRC}} + \left( \theta_{\kappa} + \theta_{\omega \kappa} \omega_{t-1} \right) \frac{d \kappa_t}{d k_t^{\text{NRC}}}}{1 + s_{\text{ME}, t} \, \frac{d \kappa_t}{d k_t^{\text{NRC}}}}$$

---

#### 3. Spec B3: Canonical Fully Interacted Model
Cointegrating equation:
$$y_t^{\text{NFC}} = \boldsymbol{\gamma}' \mathbf{D}_t + \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \theta_{\kappa} \kappa_t + \beta_{p^{\kappa}} p_t^{\kappa} + \beta_{\omega} \omega_{t-1} + \theta_{\omega \kappa} (\kappa_t \cdot \omega_{t-1}) + \theta_{\kappa p^{\kappa}} (\kappa_t \cdot p_t^{\kappa}) + u_t$$

* **Subscript Index Set**: $j \in \{\text{NRC}, \kappa, \omega \kappa, \kappa p^{\kappa}\}$
* **Total Derivative Aggregate Transformation Elasticity**:
  $$\theta_t^{\text{SpecB3}}(\omega_{t-1}, p_t^{\kappa}) \equiv \frac{d y_t^p}{d k_t^{\text{cap}}} = \frac{\theta_{\text{NRC}} + \left( \theta_{\kappa} + \theta_{\omega \kappa} \omega_{t-1} + \theta_{\kappa p^{\kappa}} p_t^{\kappa} \right) \frac{d \kappa_t}{d k_t^{\text{NRC}}}}{1 + s_{\text{ME}, t} \, \frac{d \kappa_t}{d k_t^{\text{NRC}}}}$$

where $s_{\text{ME}, t} = \frac{K_{t, \text{NFC}}^{\text{ME}}}{K_{t, \text{NFC}}^{\text{ME}} + K_{t, \text{NFC}}^{\text{NRC}}}$ is the machinery share of aggregate productive capital stock, and $\frac{d \kappa_t}{d k_t^{\text{NRC}}}$ is the empirical LOESS trend path derivative of mechanization choice relative to plant scale.

---

## 3. Peripheral Analytical Foundation Formulations (FX-Constrained Realization)

> [!NOTE]
> These equations lock the analytical mechanics of the peripheral FX-constrained model (ref: `A04`). They define the structural decoupling of nominal profitability from realized capacity formation under Balance of Payments (BoP) constraints.

### 3.1. FX-Conversion Bottleneck & Realization Wedge
The macro-level FX requirement for intensive-margin accumulation is:
$$ F^{\text{req}}_t = \nu \cdot \pi_t \cdot Y_t $$
The FX-conversion ratio gates the realization of accounting profits:
$$ \phi_t = \min\left(1, \frac{F^{\text{avail}}_t}{F^{\text{req}}_t}\right) $$
The effective profit share available for realized reinvestment is:
$$ \pi^{\text{eff}}_t = \pi_t \cdot \phi_t $$
* **Regime $E_B$ (Binding Constraint, $\phi_t < 1$):** Substituting $\phi_t$ yields $\pi^{\text{eff}}_t = \frac{F^{\text{avail}}_t}{\nu Y_t}$. 
* **Locked Property (Distributional Invariance):** In Regime $E_B$, $\frac{\partial \pi^{\text{eff}}_t}{\partial \pi_t} = 0$. The effective profit share is strictly invariant to domestic wage suppression.

### 3.2. Peripheral Transformation Elasticity
The peripheral efficiency penalty captures maintenance backlogs and idle capacity due to imported complement rationing:
$$ \Psi(\phi_t) = \phi_t^{\eta} $$
The constrained intensive-margin transformation elasticity is:
$$ \theta_{\text{ME, periph}} = \theta_{\text{ME, core}} \cdot \Psi(\phi_t) = \theta_{\text{ME, core}} \cdot \phi_t^{\eta} $$
The aggregate peripheral transformation elasticity is the weighted average of the extensive and constrained intensive margins:
$$ \theta_{\text{periph}} = (1 - W_{\text{ME}}) \theta_{\text{NRC}} + W_{\text{ME}} \theta_{\text{ME, periph}} $$
where $W_{\text{ME}} = \frac{s_{\text{ME}} g_{K^{\text{ME}}}}{(1-s_{\text{ME}}) g_{K^{\text{NRC}}} + s_{\text{ME}} g_{K^{\text{ME}}}}$ and the intensive margin growth rate is $g_{K^{\text{ME}}} = \chi^{\text{ME}} \pi^{\text{eff}}_t - \delta^{\text{ME}}$.

### 3.3. Locked Comparative Statics (Regime $E_B$)
To preserve analytical consistency, the following partial derivatives are locked for the binding regime:
1. **FX Relaxation:** $\frac{\partial \theta_{\text{periph}}}{\partial F^{\text{avail}}_t} > 0$
2. **Import Rigidity:** $\frac{\partial \theta_{\text{periph}}}{\partial \eta} < 0$
3. **The Accumulation Paradox (Distributive Conflict):** 
   $$ \frac{\partial \theta_{\text{periph}}}{\partial \pi_t} < 0 \implies \frac{\partial \theta_{\text{periph}}}{\partial \omega_t} > 0 $$
   *Locked Interpretation:* In a binding BoP regime, increasing the wage share (lowering $\pi_t$) actually *increases* the aggregate transformation elasticity by alleviating the FX bottleneck. Aggressive wage suppression mechanically degrades realized capacity formation.

---

## 4. Vault Cross-References

- Definitive Outline: [[Ch2_Outline_DEFINITIVE]]
- Paper-Facing Constitution: [[00E_Chapter2_PaperFacing_Constitution]]
- Peripheral Analytical Foundation: [[A04_PeripheralTransformationElasticity]]
- Cointegration Stars & Triad Lock: [[E17_Cointegration_Significance_Stars_Lock]]