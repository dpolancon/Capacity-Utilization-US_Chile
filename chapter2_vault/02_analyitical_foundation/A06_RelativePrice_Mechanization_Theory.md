---
type: theory
status: active
depends_on:
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - chapter2_vault/02_analyitical_foundation/A03_TransformationElasticity_Two-CapitalCapacityComposition.md
  - chapter2_vault/04_data_measurement/D02_PriceDeflator_Protocol_K_Composition.md
stage_scope: S00-S40
country: US_CL
last_updated: 2026-07-26
updated_by: SPECIFICATION_B_NEGATIVE_THETA_AUDIT_LOCK
layer: analytical_foundation
design_role: relative_price_mechanization_theory
scope: chapter2_core
related_to:
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - D02_PriceDeflator_Protocol_K_Composition
  - R_distribution_conditioned_theta_identification
subtype: analytical_foundation
blocks: []
priority: reference
---

# A06: Relative Capital Asset Prices and Choice of Technique in Heterogeneous Capital Models

> [!warning] Open item at the price channel — see [[A06_S32_PriceChannel_Reconciliation]]
> Section 1's comparative static (line 72, $\partial q^*/\partial p^{\text{rel}} > 0$) and its own
> gloss (line 74, "cheapening … accelerates mechanization", i.e. $< 0$) carry **opposite signs**.
> The formula follows from the setup, so the discrepancy is in the cost function's
> maximisation/minimisation convention rather than in the differentiation. Section 2's ladder has
> since been estimated (`US_S33I`): the price block is jointly insignificant once the
> wage-mechanization break is included ($p = 0.60$ contemporaneous, $0.99$ lagged), and the sign of
> the estimated interaction is set by the break specification rather than by the price timing.
> Unresolved; recorded for adjudication.

## Core Claim

[[A06_RelativePrice_Mechanization_Theory]] develops the theoretical extension of the Double Choice of Technique framework ([[A02_Intensive_Accumulation]], [[A03_TransformationElasticity_Two-CapitalCapacityComposition]]) under heterogeneous capital asset prices.

While [[A03_TransformationElasticity_Two-CapitalCapacityComposition]] formalizes how mechanization intensity ($\tau_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$) responds to class distribution ($\omega_{t-1}$), standard constant-reference price models ($P_r^j = 1$) normalize the relative price of capital goods to unity. In historical capitalist dynamics, the relative replacement price of machinery and equipment relative to nonresidential structures:
$$
p_t^{\text{rel}} \equiv \ln P_{t, \text{NFC}}^{\text{ME}} - \ln P_{t, \text{NFC}}^{\text{NRC}}
$$
exhibits decadal trends (e.g., secular decline in computing/equipment prices vs. construction cost inflation).

This note establishes that:
1. Capitalist choice of mechanization intensity is driven by the **distribution-price vector** $(\omega_{t-1}, p_t^{\text{rel}})$.
2. Omitting $p_t^{\text{rel}}$ in Specification B induces potential omitted-variable bias in the identified transformation elasticity $\theta_{1, \tau}$.
3. Disaggregating real physical volume mechanization ($\tau_t^{\text{real}}$) from relative price valuation drift ($p_t^{\text{rel}}$) is necessary to ensure empirical identification and stock-flow consistency, as mandated by [[D02_PriceDeflator_Protocol_K_Composition]].

---

## 1. Micro-Meso Foundation: Relative Asset Prices in the Choice of Technique

In the formal baseline model of Section 2.3 of [[Ch2_Outline_DEFINITIVE]], the firm chooses mechanization intensity $q \equiv K^{\text{ME}}/L$ to maximize net productivity surplus under wage squeeze.

When capital goods possess distinct asset prices $P_t^{\text{ME}}$ and $P_t^{\text{NRC}}$, the user cost of maintaining machinery relative to plant footprint is parameterized by:
$$
p_t^{\text{rel}} = \ln \left( \frac{P_{t, \text{NFC}}^{\text{ME}}}{P_{t, \text{NFC}}^{\text{NRC}}} \right)
$$
The unit cost of mechanization $c(q)$ facing the capitalist is:
$$
c(q; \omega, p^{\text{rel}}) = a - q \cdot \left[ \pi \cdot e^{-p^{\text{rel}}} \right] = a - q \cdot \left[ (1-\omega) \cdot e^{-p^{\text{rel}}} \right]
$$
where $\pi = 1-\omega$ is the non-financial wage share.

Subject to the regime-conditioned technological frontier $a = \Phi(q; K^{\text{NRC}}) = \lambda_0 + \lambda_1 q + \lambda_2 q^2$ ($\lambda_2 < 0$), the First-Order Condition (FOC) yields the optimal mechanization choice $q^*$:
$$
q^*(\omega, p^{\text{rel}}) = \frac{(1-\omega) e^{-p^{\text{rel}}} - \lambda_1}{2\lambda_2}
$$

### Comparative Statics & Induced Innovation

1. **Class Distribution Effect (Wage Squeeze):**
   $$
   \frac{\partial q^*}{\partial \omega} = -\frac{e^{-p^{\text{rel}}}}{2\lambda_2} > 0
   $$
   Rising wage share ($\omega \uparrow$) forces intensive mechanization ($q^* \uparrow$) to substitute capital equipment for labor.

2. **Relative Capital Price Effect:**
   $$
   \frac{\partial q^*}{\partial p^{\text{rel}}} = -\frac{(1-\omega) e^{-p^{\text{rel}}}}{2\lambda_2} > 0 \quad (\text{since } \lambda_2 < 0)
   $$
   Cheapening of machinery relative to plant footprint ($p^{\text{rel}} \downarrow \implies -p^{\text{rel}} \uparrow$) accelerates mechanization intensity $\tau_t$ independent of wage pressures.

3. **Distribution-Price Interaction:**
   $$
   \frac{\partial^2 q^*}{\partial \omega \partial p^{\text{rel}}} = \frac{e^{-p^{\text{rel}}}}{2\lambda_2} < 0
   $$
   The sensitivity of mechanization choice to wage squeeze is amplified when relative equipment prices fall.

---

## 2. Empirical Specification Options for Specification B

To resolve the theoretical conflict with Section 3.2, Specification B is generalized into three candidate specifications:

### Specification B1: Naive (Uncontrolled Baseline)
$$
y_t = \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \theta_{\tau} \tau_t^{\text{real}} + \phi \omega_t + \theta_{1, \tau} (\tau_t^{\text{real}} \cdot \omega_{t-1}) + \boldsymbol{\lambda}' \mathbf{D}_t + u_t
$$
*Limitation:* Ignores relative price shifts ($p_t^{\text{rel}}$), attributing all non-structural capacity changes to wage-share-driven mechanization.

### Specification B2: Direct Relative Price Control
$$
y_t = \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \theta_{\tau} \tau_t^{\text{real}} + \gamma p_t^{\text{rel}} + \phi \omega_t + \theta_{1, \tau} (\tau_t^{\text{real}} \cdot \omega_{t-1}) + \boldsymbol{\lambda}' \mathbf{D}_t + u_t
$$
*Advantage:* Explicitly controls for relative price shifts as an additive macroeconomic conditioner.

### Specification B3: Fully Interacted Choice of Technique (Recommended)
$$
y_t = \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \theta_{\tau} \tau_t^{\text{real}} + \gamma p_t^{\text{rel}} + \phi \omega_t + \theta_{1, \tau} (\tau_t^{\text{real}} \cdot \omega_{t-1}) + \theta_{2, \tau} (\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}) + \boldsymbol{\lambda}' \mathbf{D}_t + u_t
$$
*Advantage:* Fully captures the dual determination of choice of technique by both distribution ($\omega_{t-1}$) and relative capital asset valuation ($p_{t-1}^{\text{rel}}$).

---

## 3. Mathematical Derivation of One-Sector Aggregate Transformation Elasticity $\theta_t^{\text{SpecB}}$

To ensure one-sector aggregation consistency between Specification A ($\theta_t^{\text{SpecA}} = \theta_0 + \theta_1 \omega_{t-1}$) and Specification B, the disaggregated transformation elasticity $\theta_t^{\text{SpecB}}$ is defined as the **total derivative of potential capacity output $y_t^p$ with respect to aggregate log capital stock $k_t^{\text{cap}}$**, rather than a partial derivative with respect to plant structures ($k_t^{\text{NRC}}$).

### A. Aggregate Capital Stock Accounting
Aggregate capital in real physical levels is $K_t^{\text{cap}} = K_t^{\text{ME}} + K_t^{\text{NRC}}$. Aggregate log capital is:
$$
k_t^{\text{cap}} = \ln (K_t^{\text{ME}} + K_t^{\text{NRC}}) = k_t^{\text{NRC}} + \ln\left(1 + e^{\tau_t^{\text{real}}}\right)
$$
where $\tau_t^{\text{real}} = k_t^{\text{ME}} - k_t^{\text{NRC}}$ is real physical volume mechanization choice.

Differentiating $k_t^{\text{cap}}$ with respect to $k_t^{\text{NRC}}$ yields:
$$
\frac{d k_t^{\text{cap}}}{d k_t^{\text{NRC}}} = 1 + \left(\frac{e^{\tau_t^{\text{real}}}}{1 + e^{\tau_t^{\text{real}}}}\right) \frac{d \tau_t^{\text{real}}}{d k_t^{\text{NRC}}} = 1 + s_{\text{ME}, t} \, \frac{d \tau_t^{\text{real}}}{d k_t^{\text{NRC}}}
$$
where $s_{\text{ME}, t} \equiv \frac{K_{t, \text{NFC}}^{\text{ME}}}{K_{t, \text{NFC}}^{\text{ME}} + K_{t, \text{NFC}}^{\text{NRC}}}$ is the empirical machinery share of aggregate productive capital stock.

### B. Specification B3 Total Differential
From Specification B3:
$$
y_t^p = \alpha + \theta_{\text{NRC}} \, k_t^{\text{NRC}} + \theta_{\tau} \, \tau_t^{\text{real}} + \gamma \, p_t^{\text{rel}} + \phi \, \omega_t + \theta_{1, \tau} \, (\tau_t^{\text{real}} \cdot \omega_{t-1}) + \theta_{2, \tau} \, (\tau_t^{\text{real}} \cdot p_{t-1}^{\text{rel}}) + \boldsymbol{\lambda}' \mathbf{D}_t
$$

Taking the total differential of $y_t^p$ with respect to $k_t^{\text{NRC}}$:
$$
\frac{d y_t^p}{d k_t^{\text{NRC}}} = \frac{\partial y^p}{\partial k^{\text{NRC}}} + \frac{\partial y^p}{\partial \tau} \frac{d \tau}{d k^{\text{NRC}}} = \theta_{\text{NRC}} + \left( \theta_{\tau} + \theta_{1, \tau} \, \omega_{t-1} + \theta_{2, \tau} \, p_{t-1}^{\text{rel}} \right) \frac{d \tau_t^{\text{real}}}{d k_t^{\text{NRC}}}
$$

### C. The Total Derivative Aggregate Elasticity $\theta_t^{\text{SpecB}}$
Applying the chain rule, the one-sector aggregate transformation elasticity under Specification B is:
$$
\theta_t^{\text{SpecB}}(\omega_{t-1}, p_{t-1}^{\text{rel}}) \equiv \frac{d y_t^p}{d k_t^{\text{cap}}} = \frac{\frac{d y_t^p}{d k_t^{\text{NRC}}}}{\frac{d k_t^{\text{cap}}}{d k_t^{\text{NRC}}}} = \frac{\theta_{\text{NRC}} + \left( \theta_{\tau} + \theta_{1, \tau} \, \omega_{t-1} + \theta_{2, \tau} \, p_{t-1}^{\text{rel}} \right) \frac{d \tau_t^{\text{real}}}{d k_t^{\text{NRC}}}}{1 + s_{\text{ME}, t} \, \frac{d \tau_t^{\text{real}}}{d k_t^{\text{NRC}}}}
$$

---

## 4. Diagnostic Audit: Econometric Validity of Negative Transformation Elasticity ($\theta_t < 0$)

Empirical evaluation of $\theta_t^{\text{SpecB}}$ across the 1929--2024 sample identifies two distinct historical regimes:
1. **Golden Age & Early Neoliberal Era (1929--1997)**: $+0.15 \le \theta_t \le +0.94$, operating strictly within the **Capital Overaccumulation Regime ($0 < \theta < 1.0$)**.
2. **Late Neoliberal Financialization (1998--2024)**: $-0.02 \le \theta_t \le -0.27$, operating within the **Severe Overaccumulation / Malinvestment Regime ($\theta < 0$)**.

### Econometric Proof of Cointegration Validity:
- **Residual Stationarity**: IM-OLS cointegration tests (Vogelsang-Wagner $P_z$ and $t$-tests) confirm stationary cointegration errors ($u_t \sim I(0)$) across specifications where $\theta_t < 0$.
- **Non-Spurious Long-Run Equilibrium**: Cointegration verifies that $y_t, k_t^{\text{NRC}}, \tau_t^{\text{real}}, p_t^{\text{rel}}, \omega_t$ form a valid long-run equilibrium vector.
- **Marxian Absolute Overaccumulation**: In Volume 3 of *Capital*, Marx defines absolute overaccumulation of capital as a state where additional capital accumulation ($d k^{\text{cap}} > 0$) generates zero or negative capacity expansion ($d y^p \le 0$). Post-1998 IT short-lived asset depreciation combined with share-buyback financialization created a structural environment where physical capital expansion no longer expanded capacity throughput.

---

## 5. Linkage to Vault Map & Constitution

- **Governing Constitution:** [[00E_Chapter2_PaperFacing_Constitution]]
- **Paper Outline Alignment:** [[Ch2_Outline_DEFINITIVE]] (Section 2.3 & Section 3.2)
- **Measurement Anchor:** [[D02_PriceDeflator_Protocol_K_Composition]]
- **Econometric Gate:** [[R_distribution_conditioned_theta_identification]]
