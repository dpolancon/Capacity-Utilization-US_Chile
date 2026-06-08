---
type: note
subtype: rule
status: active
layer: analytical_toolkit
design_role: measurement_guardrail
scope: chapter2_implementation
related_to:
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
created: 2026-05-27
---

# R04: Measurement and Accounting Consistency

## Core Rule
The analytical composition share $s_t$ is a **pure physical stock metric**. It must be constructed via asset-specific deflation and PIM accumulation. Current-price or nominal shares are inadmissible as baseline inputs.

## 1. Construction Protocol
1. **Deflate Nominal Investment:** 
$$
I^{ME,r}_t = V^{ME}_t / P^{ME,I}_t, \quad I^{NRC,r}_t = V^{NRC}_t / P^{NRC,I}_t
$$
2. **PIM Accumulation:** 
$$
K^{ME}_t = (1-\delta^{ME})K^{ME}_{t-1} + I^{ME,r}_t
$$
(same for NRC)
3. **Compute Share:** 
$$
s_t = K^{ME}_t / (K^{ME}_t + K^{NRC}_t)
$$

**Prohibition:** Do not allocate aggregate real GFCF using current-price shares $\varphi^V_t$. This injects relative capital-goods price movements into measured accumulation.

## 2. Price Wedge Diagnostics
Current-price shares may be used **only** as distortion diagnostics:
$$
\log\left(\frac{\varphi^V_t}{1-\varphi^V_t}\right) = \log\left(\frac{\varphi^r_t}{1-\varphi^r_t}\right) + \log(\rho^I_t)
$$
Capital-stock wedge $\rho^K_t = P^{ME,K}_t / P^{NRC,K}_t$ is admissible **if-and-only-if** asset-specific stock deflators are observed or recoverable. Borrow investment deflators for stock wedges only as a last-resort proxy with documented error bounds.

## 3. Cross-National/Data Consistency
- Ensure base year $r$ aligns across output, $K^{NRC}$, and $K^{ME}$ series.
- Verify depreciation rates $\delta^{ME}$, $\delta^{NRC}$ match institutional accounting conventions.
- Flag regime transitions that coincide with national account rebasing or PIM methodology changes.

## Locked Formulation
Real flows → real stocks → $s_t$ → $\theta^N$. Current-price composition is a diagnostic, not an analytical input. Asset-specific deflation precedes aggregation. This guardrail ensures dimensional homogeneity and prevents valuation artifacts from contaminating the transformation elasticity.