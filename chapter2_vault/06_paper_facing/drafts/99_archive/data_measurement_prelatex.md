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

# 4. Data Measurement and the Generalized Perpetual Inventory Method

To empirically adjudicate the choice-of-technique models developed in Section 3, we must construct capital stock variables that accurately reflect the physical footprint of accumulation. Standard macroeconomic datasets often conflate the monetary value of capital with its operational physical capacity, leading to severe measurement artifacts. This section outlines the structural protocol used to measure capital in this chapter, establishing the Generalized Perpetual Inventory Method (GPIM) as our core stock-flow consistency device.

Consistent with our theoretical progression, we first establish the measurement architecture for the U.S. nonfinancial corporate (NFCorp) sector as the baseline core economy (Section 4.1). We will subsequently detail the harmonization of Chilean capital stocks, which serves as our exemplary case of peripheral development (Section 4.2).

## 4.1 Measuring Productive Capacity in the U.S. Core

Our primary data source for U.S. accumulation is the Bureau of Economic Analysis (BEA) Fixed Assets Accounts. However, we do not use the BEA's aggregate official quantity and price indexes. Instead, we rebuild the necessary capital stocks from the ground up using investment flows and asset-specific price indexes to enforce a strict separation of valuation registers.

### 4.1.1 The Dual Valuation Register

Capital accumulation must be read through two distinct determinations: capacity and profitability. These require fundamentally different stock variables:

1. **The Capacity Register (Gross Real GPIM Stock):** Productive capacity depends on capital goods that are still physically in operation. Therefore, the relevant measure is the *gross real stock* ($K^{G,R}$). A machine that has depreciated to zero monetary accounting value may still operate at full physical capacity until it is permanently retired.
2. **The Profitability Register (Net Current-Cost Stock):** Profitability, conversely, is a monetary ratio between a profit flow and the value of capital advanced. The relevant measure is the *net current-cost stock* ($K^{N,V}$), which tracks the monetary value of capital after accounting for financial depreciation and write-downs.

A common flawed implementation in empirical macroeconomics is to use a single aggregate net capital stock for both capacity utilization and profit rate calculations. By doing so, one conflates value in motion with capacity in operation. We strictly separate these registers.

### 4.1.2 The GPIM Reconstruction Protocol

Machinery ($ME$) and nonresidential structures ($NRC$) do not share a natural physical unit. They become comparable only through a monetary-mediated accounting procedure. We employ the Generalized Perpetual Inventory Method (GPIM) to reconstruct capacity-relevant stocks.

The central GPIM rule is to construct each asset account internally first, rather than aggregating nominal values and deflating with a generic aggregate index. For each asset class $j \in \{ME, NRC\}$ in the U.S. NFCorp sector, we first derive real investment flows:

$$ I_{j,t}^R = \frac{I_{j,t}^V}{P_{j,t}^K} $$

where $I_{j,t}^V$ is the current-cost gross investment and $P_{j,t}^K$ is the asset-specific price index. The gross real GPIM stock is then reconstructed account by account:

$$ K_{j,t}^{G,R} = \text{GPIM}(I_{j,t}^R, \rho_j, L_j) $$

where $\rho_j$ governs the retirement logic and $L_j$ represents the mean service life. Unlike standard perpetual inventory methods that often rely on geometric depreciation (which continually decays the installed volume), our GPIM utilizes a Weibull retirement distribution. The Weibull curve ensures that capital goods remain fully in the capacity envelope until they are physically removed from service, accurately modeling the physical life cycle of a plant or machine.

The resulting gross real GPIM stock ($K^{G,R}$) is not a literal physical quantity; it is a constant-price measure of purchasing power embodied in heterogeneous capital goods still in operation.

### 4.1.3 The ME-NRC Component Proxy

To isolate the mechanization bias discussed in Section 3, we require a measure of the machinery share of capital. For the U.S. NFCorp sector, we utilize an $ME-NRC$ component proxy. 

The capacity-composition share is estimated directly from the gross real GPIM stocks:

$$ s_{t, proxy} = \frac{K_{ME,t}^{G,R}}{K_{ME,t}^{G,R} + K_{NRC,t}^{G,R}} $$

Because it is constructed from asset-specific GPIM stocks, $s_{t, proxy}$ is isolated from relative price drift between machinery and structures. It serves as a rigorous, real-volume proxy for the machinery share relevant to the transformation relation.

## 4.2 Measuring Peripheral Accumulation (Chilean Case)

[Placeholder: This section will detail the specific challenges of peripheral measurement, including the harmonization of Central Bank of Chile (BCCh) data, the treatment of imported capital goods, and the formulation of the external-mechanization wedge ($\mathcal{E}_t$).]
