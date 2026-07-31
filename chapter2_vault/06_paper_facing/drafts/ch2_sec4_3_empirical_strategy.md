---
type: paper_facing
status: pre-draft note
country: CL
stage_scope: S04_Empirical_Handoff
last_updated: 2026-07-30
depends_on:
  - 03_Section_3_3_Peripheral_Extension
  - chile_bop_binding_report_v7
layer: empirical_strategy
scope: section 4.3
---

# Econometric Adjudication: Terms of Trade vs. Real Exchange Rate

When estimating the long-run import requirement ($\hat{m}^{req}_t$), **Terms of Trade (ToT) must be excluded from the cointegrating vector** and kept strictly on the FX Envelope (supply) side of the model. Conflating the two triggers severe multicollinearity and blurs the theoretical boundary between structural demand and external purchasing power.

## 1. The Prebischian Ontology: Requirement vs. Envelope
*   **The Import Requirement ($F^{req}_t$):** Captures the structural demand for foreign exchange driven by imitative capitalism. It is determined by the physical necessity of the intensive margin ($k^{ME}_t$), domestic financial capacity ($s_t$), and the relative price signal (**RER**). 
*   **The FX Envelope ($F^{avail}_t$):** Captures the external purchasing power. It is determined by export volumes and the **Terms of Trade (ToT)**. This maps to Prebisch’s thesis: the periphery's ability to finance development is gated by the volatile purchasing power of its primary exports over center-manufactures.

## 2. The Econometric Trap: Dutch Disease Multicollinearity
Including ToT in the ARDL/VECM import requirement equation alongside the RER is statistically toxic for Chile. 
1.  **Dutch Disease:** When copper prices rise (ToT improves), the influx of FX causes the domestic currency to appreciate (RER falls). ToT and RER are heavily correlated.
2.  **Variance Inflation:** Including both in a post-1974 ARDL model will explode standard errors and destabilize the long-run elasticity of the machinery stock ($\hat{\beta}_1$).
3.  **Redundancy:** The non-reinvested surplus variable ($s_t$) already absorbs the domestic income/wealth effect of a ToT shock. 

## 3. The Operational Fix: The "Capacity to Import" Gate
Use the WBOP Terms of Trade data to construct the **Prebischian Capacity to Import ($C_t$)** index, which serves as the empirical proxy for the FX Envelope ($F^{avail}_t$).

$$ C_t = X_t \cdot ToT_t $$

This variable is used to define the **External Stress** gating condition for the Binding Regime indicator ($B_t$), resolving the 1961 Timing Puzzle by identifying the *onset* of the Prebischian *estrangulamiento* (collapsing purchasing power) before the physical compression of imports actually occurs.

$$ B_t = \mathbb{I}\Big( (m_t - \hat{m}^{req}_t < 0) \quad \text{AND} \quad (\Delta \ln(C_t) < \text{Threshold}) \Big) $

