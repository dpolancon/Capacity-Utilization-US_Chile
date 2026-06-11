---
type: note
status: active
layer: empirical_design
design_role: gpim_stock_flow_valuation_protocol
scope: chapter2_core_support
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - N04_Composition_of_Accumulation_and_Transformation
  - R04_What_is_Identified_vs_Reconstructed
  - Price_Deflator_Protocol_ME_NRC_Composition
  - TARGET_REPO_STRUCTURE_AND_CODE_STAGE_IMPLEMENTATION
created: 2026-05-06
updated: 2026-06-08
---

# GPIM, heterogeneous capital, stock-flow consistency, and valuation registers

> [!important] Current identification lock
> D01 must first define the productive-capital boundary, then export productive-capital scale, constant-centered distribution, their interaction, and the centered ME/NR composition variables. Accumulated-index baseline language below is parked under [[R_distribution_conditioned_theta_identification]].

## Core claim

GPIM should be used as the **stock-flow-consistency device** for reconstructing capital in operation.

It should not be interpreted as proof that heterogeneous capital goods have become physically homogeneous.

Machinery, equipment, structures, and other fixed assets do not share a natural physical unit. They become comparable only through a monetary-mediated accounting procedure: investment flows are valued, deflated through asset-specific price indexes, accumulated through a stock-flow law, and adjusted for retirement or depreciation.

The correct object is therefore not “physical capital stock.”

The correct object is:

> constant-price purchasing power embodied in heterogeneous capital goods still in operation.

This phrasing preserves the monetary mediation of capital while allowing gross real GPIM stocks to serve as the capacity-relevant stock measure.

---

# 1. Measurement problem

Chapter 2 requires two different capital-stock registers:

1. A stock measure for reconstructing productive capacity.
2. A stock measure for measuring profitability.

These are not the same object.

Productive capacity depends on capital goods still in operation. Therefore, the relevant stock is a gross real stock.

Profitability is a monetary ratio between a profit flow and the value of capital advanced or tied up. Therefore, the relevant stock is a net current-cost, replacement-cost, or otherwise explicitly monetary valuation of capital.

The same capital circuit is therefore read through two different determinations:

- capacity determination;
- profitability determination.

This is not inconsistency. It is a disciplined separation of registers.

---

# 2. Valuation-register architecture

## 2.1 Capacity register

Use:

$$
K_{j,t}^{G,R}
$$

where:

- $j$ is the capital account or asset type;
- $G$ means gross;
- $R$ means real or constant-price;
- $K_{j,t}^{G,R}$ is the gross real stock of asset $j$ in operation.

Interpretation:

> $K_{j,t}^{G,R}$ is a constant-price measure of purchasing power embodied in capital goods of type $j$ still in operation.

Use this register for:

- productive-capacity reconstruction;
- capacity-composition shares;
- the transformation relation;
- $\theta_t^{tot}$;
- the derivation of $Y_t^p$ and $\mu_t$.

## A00 baseline and A03 decomposition boundary

A00 uses aggregate real productive capital ($K_t$), not the ME/NRC decomposition as separate explanatory channels.

The aggregate $K_t$ should be constructed from coherent gross real GPIM capacity-relevant capital. ME/NRC component construction can be used as measurement input if needed, but in A00 it enters only to construct aggregate $K_t$.

The corrected A00 econometric baseline requires:

- $y_t$;
- $k_t$;
- $\omega_t$;
- $\Delta k_t$;
- inherited-distribution memory states;
- accumulated indexes $q_t^{\omega,1}$, $q_t^{\omega,3}$, and $q_t^{\omega,5}$.

Construct:

$$
q_t^{\omega,h}
=
\sum_{s=1}^{t}
m_{s-1}^{(h)}\Delta k_s.
$$

The former `omega_k_t = omega_t * k_t` export is superseded as the benchmark variable and may be retained only as a labeled historical diagnostic.

ME/NRC shares ($s_t$), component stocks, and component-flow shares belong to A03 decomposition/proxy work. Current-cost shares remain diagnostics, not substitutes for real-volume capacity composition.

## 2.2 Profitability register

Use:

$$
K_t^{N,V}
$$

where:

- $N$ means net;
- $V$ means current value, current cost, or replacement-cost valuation.

Interpretation:

> $K_t^{N,V}$ is the monetary value of the stock of capital advanced or tied up, after depreciation or write-down.

Use this register for:

- profit-rate measurement;
- profitability decomposition;
- current valuation of capital advanced;
- monetary accounting of the capital circuit.

## 2.3 Diagnostic valuation register

Use:

$$
K_{j,t}^{G,V}
$$

where:

- $G$ means gross;
- $V$ means current-cost value.

Interpretation:

> $K_{j,t}^{G,V}$ measures the current-cost valuation of capital goods of type $j$ in operation.

Use this register for:

- valuation-composition shares;
- relative-price diagnostics;
- financing and expenditure pressure;
- comparison between real-volume and current-cost composition.

---

# 3. GPIM as stock-flow consistency device

GPIM reconstructs capital in operation from investment flows, retirement or depreciation logic, and price structures.

For each asset account $j$, real investment is constructed internally:

$$
I_{j,t}^{R}
=
\frac{I_{j,t}^{V}}{P_{j,t}^{K}}
$$

where:

- $I_{j,t}^{V}$ is current-cost gross investment in asset $j$;
- $P_{j,t}^{K}$ is the asset-specific capital-goods price index;
- $I_{j,t}^{R}$ is real investment in asset $j$.

The GPIM stock is then reconstructed account by account:

$$
K_{j,t}^{G,R}
=
GPIM(I_{j}^{R}, \rho_j, L_j, \text{retirement logic})
$$

where:

- $\rho_j$ is the retirement or survival logic for asset $j$;
- $L_j$ is the relevant service-life or lifetime parameter;
- the exact GPIM implementation may include survival, retirement, revaluation, and warmup rules.

The central rule is:

> construct each asset account internally first, then aggregate.

Not:

> aggregate current-cost heterogeneous assets first, then deflate with a generic aggregate price index.

---

# 4. Heterogeneous capital and aggregation

Heterogeneous capital stocks cannot be aggregated as physical quantities.

Machinery and structures are physically different objects. Their aggregation is possible only after each account has been transformed into a comparable accounting register.

The preferred aggregation rule is:

$$
K_{A,t}^{G,R}
=
\sum_{j \in A} K_{j,t}^{G,R}
$$

where $A$ is the chosen asset set.

For the current US composition proxy, the relevant set is:

$$
A = \{ME,NRC\}
$$

Thus:

$$
K_{ME,NRC,t}^{G,R}
=
K_{ME,t}^{G,R}
+
K_{NRC,t}^{G,R}
$$

This is not a physical aggregation.

It is an aggregation of constant-price purchasing power embodied in capital goods still in operation.

---

# 5. US composition basis

The US sector target is:

$$
NFCorp
$$

meaning nonfinancial corporate business.

However, the available composition basis is not a direct nonfinancial-corporate-by-asset-type split.

The available basis is a component proxy:

$$
ME + NRC
$$

where:

- $ME$ = machinery and equipment;
- $NRC$ = nonresidential construction or structures.

Therefore, the default Chapter 2 label should be:

> ME–NRC component proxy

Do not label the Chapter 2 object as `TOTAL_PRODUCTIVE`.

Do not claim that the measure is a direct machinery share of nonfinancial corporate capital.

Write instead:

> The US composition measure is a Tier-B ME–NRC component proxy for the machinery share relevant to the NFCorp-centered transformation relation.

---

# 6. Default stock share

The default capacity-composition share should be estimated from gross real GPIM stocks:

$$
s_{t,proxy}^{ME|ME,NRC}
=
\frac{K_{ME,t}^{G,R}}
{K_{ME,t}^{G,R}+K_{NRC,t}^{G,R}}
$$

Interpretation:

> $s_{t,proxy}^{ME|ME,NRC}$ measures the machinery share of constant-price purchasing power embodied in the ME–NRC capital stock in operation.

It is not a literal physical share.

It is not a current-cost value share.

It is a real-volume composition share constructed from asset-specific GPIM stocks.

For implementation, map:

- `s_t_proxy_default = s_ME_over_ME_NRC_gross_real`

---

# 7. Default flow share

The default machinery share of accumulation should be estimated from real investment flows:

$$
\varphi_{t,proxy}^{ME|ME,NRC}
=
\frac{I_{ME,t}^{R}}
{I_{ME,t}^{R}+I_{NRC,t}^{R}}
$$

Interpretation:

> $\varphi_{t,proxy}^{ME|ME,NRC}$ measures the machinery share of current accumulation in real-volume terms.

Use this for the mechanization or composition channel.

For implementation, map:

- `phi_t_proxy_default = phi_ME_over_ME_NRC_real`

---

# 8. Current-cost diagnostic shares

Current-cost shares must also be computed, but they answer a different question.

The gross current-cost stock share is:

$$
s_{t,proxy}^{V}
=
\frac{K_{ME,t}^{G,V}}
{K_{ME,t}^{G,V}+K_{NRC,t}^{G,V}}
$$

The current-cost investment share is:

$$
\varphi_{t,proxy}^{V}
=
\frac{I_{ME,t}^{V}}
{I_{ME,t}^{V}+I_{NRC,t}^{V}}
$$

Use these for:

- valuation diagnostics;
- relative-price effects;
- expenditure composition;
- financing pressure;
- external-pressure diagnostics where current expenditure is theoretically relevant.

For implementation, map:

- `s_t_proxy_cc = s_ME_over_ME_NRC_gross_cc`
- `phi_t_proxy_cc = phi_ME_over_ME_NRC_cc`

---

# 9. Relative-price wedge

The difference between real-volume and current-cost shares is governed by the relative price wedge:

$$
\rho_t^{ME,NRC}
=
\frac{P_{ME,t}^{K}}{P_{NRC,t}^{K}}
$$

If $s_t^R$ and $s_t^V$ move differently, the difference should not be treated as noise.

It means that the real composition of capital in operation and the monetary valuation of that composition are moving differently.

This wedge must be exported as a diagnostic object:

- `pK_relative_ME_NRC = pK_ME / pK_NRC`

Interpretation:

> The relative-price wedge records how machinery and construction price structures mediate the gap between real-volume composition and current-cost composition.

---

# 10. Relation to the transformation-elasticity model

A00 identifies the aggregate time-varying transformation path using aggregate $K_t$ and accumulated distribution-conditioned capital growth $q_t^{\omega,h}$.

A03 decomposes that aggregate path using ME/NRC component proxies and the machinery accumulation-weighted index $q_t^{ME,\omega,h}$. In the A03 layer, the theoretical composition relation is:

$$
\theta_t^{tot}
=
s_t\theta_t^M
+
(1-s_t)\theta^O
$$

With the currently available US proxy, the empirical relation becomes:

$$
\theta_t^{tot}
\approx
s_{t,proxy}^{ME|ME,NRC}\theta_t^M
+
(1-s_{t,proxy}^{ME|ME,NRC})\theta^O
$$

This approximation must be stated.

This is an A03 decomposition object, not the first-stage A00 baseline. The first-stage A00 baseline remains aggregate $K_t$, time-varying $\theta_t$.

The A03 proxy model identifies a composition-weighted aggregate transformation object.

It does not directly estimate the machinery-specific transformation elasticity.

Thus:

- $\theta_t^{tot}$ is identified;
- $\theta_t^M$ is interpreted through the composition structure;
- $s_{t,proxy}^{ME|ME,NRC}$ is a Tier-B proxy for the machinery channel.

---

# 11. Relation to productive capacity

The capacity reconstruction uses gross real GPIM stock because productive capacity depends on capital goods in operation.

The capacity relation should therefore use:

$$
K_t^{G,R}
$$

not:

$$
K_t^{N,V}
$$

and not:

$$
K_t^{G,V}
$$

The correct interpretation is:

> gross real GPIM stock measures constant-price purchasing power embodied in capital goods still in operation.

This object is capacity-relevant because it tracks the operational stock of capital goods, not their written-down monetary value.

---

# 12. Relation to profitability

Profitability belongs to the monetary valuation register.

The profit rate should be constructed as:

$$
r_t
=
\frac{\Pi_t}{K_t^{N,V}}
$$

where:

- $\Pi_t$ is a profit flow;
- $K_t^{N,V}$ is a net current-cost or otherwise explicit monetary valuation of capital advanced.

Do not use gross real GPIM stock as the profit-rate denominator.

Gross real stock reconstructs capacity.

Net current-cost stock measures the monetary value against which profit is assessed.

---

# 13. Relation to value in motion

The use of real GPIM stock does not deny that capital is value in motion.

Investment begins as money expenditure. GPIM reconstructs the stock produced by those flows. Asset-specific deflation removes price-level variation to recover a capacity-relevant real-volume measure. Profitability later returns the analysis to the current-money valuation register.

The movement is:

$$
I_t^V
\rightarrow
I_t^R
\rightarrow
K_t^{G,R}
\rightarrow
Y_t^p
\rightarrow
\mu_t
$$

for capacity reconstruction, and:

$$
\Pi_t
\rightarrow
\frac{\Pi_t}{K_t^{N,V}}
$$

for profitability.

These are different determinations of the same capital circuit.

The mistake would be to collapse them into one register.

---

# 14. External-mechanization wedge

For peripheral analysis, the machinery share of accumulation is:

$$
\varphi_t
=
\frac{I_t^{ME}}{I_t^{ME}+I_t^{NRC}}
$$

The external mechanization wedge is:

$$
\mathcal{E}_t
=
\Lambda_t\varphi_t
$$

Use real $\varphi_t$ when the object is machinery-volume composition.

Use current-cost or import-adjusted $\varphi_t$ when the object is foreign-exchange expenditure pressure.

Therefore:

- real $\varphi_t$ captures machinery volume composition;
- current-cost $\varphi_t^V$ captures expenditure or valuation pressure;
- import-adjusted $\varphi_t$ would be preferable for strict balance-of-payments analysis if available.

---

# 15. Implementation metadata

The export script should include metadata fields:

- `sector_target = "NFCorp"`
- `K_t = "aggregate gross real productive capital"`
- `k_t = "log or dimensionally admissible index of aggregate real productive capital"`
- `omega_t = "wage-share / distributive condition"`
- `q_omega_1 = "cumulative sum of lagged omega times delta k"`
- `q_omega_3 = "cumulative sum of three-year inherited-distribution memory times delta k"`
- `q_omega_5 = "cumulative sum of five-year inherited-distribution memory times delta k"`
- `q_ME_omega_1 = "cumulative sum of lagged omega times delta k_ME"`
- `q_ME_omega_3 = "cumulative sum of three-year inherited-distribution memory times delta k_ME"`
- `q_ME_omega_5 = "cumulative sum of five-year inherited-distribution memory times delta k_ME"`
- `centering_rule = "no_full_sample_centering"`
- `A00_capital_object = "aggregate_K_t"`
- `A03_component_basis = "ME_NRC_component_proxy"`
- `composition_basis = "ME_NRC_component_proxy"`
- `composition_tier = "Tier B"`
- `direct_sector_asset_split = FALSE`
- `capacity_register = "gross_real_GPIM"`
- `profitability_register = "net_current_cost"`
- `default_stock_share = "s_ME_over_ME_NRC_gross_real"`
- `default_flow_share = "phi_ME_over_ME_NRC_real"`
- `valuation_stock_share = "s_ME_over_ME_NRC_gross_cc"`
- `valuation_flow_share = "phi_ME_over_ME_NRC_cc"`
- `relative_price_wedge = "pK_relative_ME_NRC"`

---

# 16. Implementation variables

Default structural variables:

- `K_ME_gross_real`
- `K_NRC_gross_real`
- `K_ME_NRC_component_gross_real`
- `s_ME_over_ME_NRC_gross_real`
- `IG_ME_real`
- `IG_NRC_real`
- `IG_ME_NRC_component_real`
- `phi_ME_over_ME_NRC_real`

Diagnostic valuation variables:

- `K_ME_gross_cc`
- `K_NRC_gross_cc`
- `K_ME_NRC_component_gross_cc`
- `s_ME_over_ME_NRC_gross_cc`
- `IG_ME_cc`
- `IG_NRC_cc`
- `IG_ME_NRC_component_cc`
- `phi_ME_over_ME_NRC_cc`
- `pK_ME`
- `pK_NRC`
- `pK_relative_ME_NRC`

Optional robustness variables:

- `K_IP_gross_real`
- `K_IP_gross_cc`
- `s_ME_over_ME_NRC_IP_gross_real`
- `phi_ME_over_ME_NRC_IP_real`

---

# 17. Guardrails

Do not write:

> gross real GPIM stock measures physical capital.

Write:

> gross real GPIM stock measures constant-price purchasing power embodied in heterogeneous capital goods still in operation.

Do not write:

> machinery and construction are physically comparable units.

Write:

> machinery and construction are comparable only after account-specific valuation, deflation, and stock-flow reconstruction.

Do not write:

> the US data directly identify the machinery share of nonfinancial corporate capital.

Write:

> the US data provide a ME–NRC component proxy for the machinery share relevant to the nonfinancial-corporate transformation relation.

Do not write:

> current-cost and real composition shares are interchangeable.

Write:

> real shares measure capacity-relevant volume composition; current-cost shares measure valuation and expenditure composition.

Do not write:

> gross real capital should be used for profitability.

Write:

> profitability remains in the monetary valuation register and should use net current-cost capital or another explicitly monetary denominator.

Do not write:

> `TOTAL_PRODUCTIVE` is a theoretical category.

Write:

> the implementation denominator is the ME–NRC component aggregate; the label `TOTAL_PRODUCTIVE` should be avoided in Chapter 2 outputs.

---

# 18. Locked formulation

GPIM enforces stock-flow consistency by reconstructing each capital account from its own investment flows, retirement or depreciation logic, and asset-specific price structure.

Heterogeneous capital is aggregated only after this account-level construction.

The resulting gross real stock is not a literal physical quantity. It is a constant-price measure of purchasing power embodied in capital goods still in operation.

Shares used in productive-capacity reconstruction should therefore be estimated from gross real GPIM stocks.

Current-cost shares should be retained as valuation diagnostics.

Profitability remains in the monetary valuation register and should use net current-cost capital, not gross real capacity stock.

The default US composition measure for Chapter 2 is a Tier-B ME–NRC component proxy for the machinery share relevant to the NFCorp-centered transformation relation.
