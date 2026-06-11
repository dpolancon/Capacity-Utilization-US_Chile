---
type: note
status: active
layer: empirical_design
design_role: price_deflator_protocol
scope: chapter2_core_support
related_to:
  - R_distribution_conditioned_theta_identification
  - A00_Aggregate_Transformation_Benchmark
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - N04_Composition_of_Accumulation_and_Transformation
  - R04_What_is_Identified_vs_Reconstructed
  - TARGET_REPO_STRUCTURE_AND_CODE_STAGE_IMPLEMENTATION
created: 2026-05-06
updated: 2026-06-08
---

# Price-deflator protocol for ME–NRC nonfinancial-corporate composition

> [!important] Current identification lock
> This note supplies measurement for the open composition-mediated specification. It does not replace the primitive scale interaction or lock machinery and structures into fixed structural roles. Accumulated-index baseline language below is parked.

## Core claim

Different capital accounts should not be merged as if their prices were identical.

For Chapter 2, machinery and equipment (`ME`) and nonresidential construction (`NRC`) must be treated as distinct capital accounts with distinct stock and investment price structures.

This note is an A03 measurement protocol. It governs the construction of ME/NRC component stocks, shares, and deflator diagnostics once the aggregate A00 capital object is opened. It does not replace the A00 baseline, where the capital object is aggregate real productive capital ($K_t$) and distribution enters through accumulated distribution-conditioned capital growth $q_t^{\omega,h}$.

The empirical object is not simply the machinery share of capital. It is the machinery share under a stated valuation basis.

The default Chapter 2 composition object should therefore distinguish:

- real-volume composition;
- current-cost or valuation composition;
- relative-price wedges;
- sector-anchor status;
- proxy status.

The implementation denominator should not be labeled `TOTAL_PRODUCTIVE` in Chapter 2 outputs.

Use the clearer label:

**ME–NRC component proxy**

The sector target remains:

**NFCorp = nonfinancial corporate business**

but the available composition object is not a direct nonfinancial-corporate-by-asset-type split.

---

# 1. Sector anchor and composition basis

The sectoral target of the US benchmark is nonfinancial corporate business.

However, the currently available asset-composition basis is not a direct split of nonfinancial corporate capital into machinery and construction.

The available composition basis is:

$$
ME + NRC
$$

where:

- `ME` = machinery and equipment;
- `NRC` = nonresidential construction / structures.

The current implementation should therefore avoid writing:

$$
s_t
=
\frac{K_{ME,t}^{NFCorp}}{K_t^{NFCorp}}
$$

because that would imply a direct nonfinancial-corporate asset-type split.

Write instead:

$$
s_{t,proxy}^{ME|ME,NRC}
=
\frac{K_{ME,t}}{K_{ME,t}+K_{NRC,t}}
$$

Interpretation:

> This is a machinery-share proxy for the NFCorp-centered transformation relation, constructed from ME and NRC component accounts. It is not a direct NFCorp-by-asset-type stock share.

---

# 2. Default denominator

The default productive-capital composition denominator is:

$$
K_{ME,NRC,t}
=
K_{ME,t}
+
K_{NRC,t}
$$

The default machinery share is:

$$
s_{t,proxy}^{ME|ME,NRC}
=
\frac{K_{ME,t}}{K_{ME,t}+K_{NRC,t}}
$$

The default machinery-investment share is:

$$
\varphi_{t,proxy}^{ME|ME,NRC}
=
\frac{I_{ME,t}}{I_{ME,t}+I_{NRC,t}}
$$

Intellectual property (`IP`) is excluded from the default denominator.

IP may be tracked as an auxiliary category or activated as a robustness denominator, but it should not be silently folded into the default ME–NRC composition share.

---

# 3. Real-volume shares and current-cost shares

Each asset account has a current-cost value and an account-specific price index.

Let $K_{j,t}^{V}$ be the current-cost value of capital account $j$, and let $P_{j,t}^{K}$ be its capital-stock price index, where:

$$
j \in \{ME,NRC\}
$$

Then the real capital stock is:

$$
K_{j,t}^{R}
=
\frac{K_{j,t}^{V}}{P_{j,t}^{K}}
$$

The real-volume machinery share is:

$$
s_t^R
=
\frac{K_{ME,t}^{R}}
{K_{ME,t}^{R}+K_{NRC,t}^{R}}
$$

The current-cost machinery share is:

$$
s_t^V
=
\frac{K_{ME,t}^{V}}
{K_{ME,t}^{V}+K_{NRC,t}^{V}}
$$

These two shares are not equivalent when:

$$
P_{ME,t}^{K}
\neq
P_{NRC,t}^{K}
$$

---

# 4. Relative-price wedge

The relation between real-volume and current-cost shares is governed by the relative price wedge:

$$
\rho_t^{ME,NRC}
=
\frac{P_{ME,t}^{K}}{P_{NRC,t}^{K}}
$$

The current-cost share can be written as:

$$
s_t^V
=
\frac{\rho_t^{ME,NRC}s_t^R}
{\rho_t^{ME,NRC}s_t^R+(1-s_t^R)}
$$

Therefore, movement in the current-cost share can reflect:

- a real change in machinery composition;
- a relative-price movement between machinery and construction;
- or both.

This is why current-cost shares cannot be treated as pure machinery-composition measures.

---

# 5. Default interpretation rule

Use real-volume shares when the object is the physical or technical composition of productive capacity.

Default stock composition:

$$
s_{t,proxy}^{default}
=
\frac{K_{ME,t}^{gross,R}}
{K_{ME,t}^{gross,R}+K_{NRC,t}^{gross,R}}
$$

Default investment-flow composition:

$$
\varphi_{t,proxy}^{default}
=
\frac{I_{ME,t}^{R}}
{I_{ME,t}^{R}+I_{NRC,t}^{R}}
$$

Use current-cost shares as valuation or expenditure diagnostics.

Diagnostic stock share:

$$
s_{t,proxy}^{V}
=
\frac{K_{ME,t}^{gross,V}}
{K_{ME,t}^{gross,V}+K_{NRC,t}^{gross,V}}
$$

Diagnostic investment share:

$$
\varphi_{t,proxy}^{V}
=
\frac{I_{ME,t}^{V}}
{I_{ME,t}^{V}+I_{NRC,t}^{V}}
$$

---

# 6. Stock-flow consistency rule

Stock-flow consistency must hold within each asset account before aggregation.

For each asset account $j$, the real stock and real investment flow must be constructed using the account-specific price logic of that account.

Do not mix:

- machinery stocks deflated with a machinery deflator;
- construction investment deflated with a total-capital deflator;
- total capital constructed from another price basis;
- and then call the result a coherent composition share.

The rule is:

> construct each asset account internally first, then aggregate.

Not:

> aggregate current-cost accounts first, then deflate by a generic total-capital price index.

---

# 7. Aggregation rule

The preferred real ME–NRC denominator is the additive real account-level aggregate:

$$
K_{ME,NRC,t}^{gross,R}
=
K_{ME,t}^{gross,R}
+
K_{NRC,t}^{gross,R}
$$

The preferred real investment denominator is:

$$
I_{ME,NRC,t}^{R}
=
I_{ME,t}^{R}
+
I_{NRC,t}^{R}
$$

This preserves account-specific deflator structure.

If an externally supplied aggregate is used, it must be checked against the component identity:

$$
K_{aggregate,t}^{R}
\overset{?}{=}
K_{ME,t}^{R}
+
K_{NRC,t}^{R}
$$

and:

$$
I_{aggregate,t}^{R}
\overset{?}{=}
I_{ME,t}^{R}
+
I_{NRC,t}^{R}
$$

If the identity holds up to rounding error, the aggregate may be used as a denominator.

If it does not, the component sum should be preferred and the discrepancy logged.

---

# 8. Naming convention

Do not export ambiguous variables such as:

- `s_t`
- `phi_t`
- `TOTAL_PRODUCTIVE`

without qualification.

Use explicit names:

- `K_ME_gross_real`
- `K_NRC_gross_real`
- `K_ME_NRC_component_gross_real`
- `s_ME_over_ME_NRC_gross_real`
- `IG_ME_real`
- `IG_NRC_real`
- `IG_ME_NRC_component_real`
- `phi_ME_over_ME_NRC_real`
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

The Chapter 2 repo may then map:

- `s_t_proxy = s_ME_over_ME_NRC_gross_real`
- `phi_t_proxy = phi_ME_over_ME_NRC_real`

but only with metadata:

- `sector_target = "NFCorp"`
- `composition_basis = "ME_NRC_component_proxy"`
- `composition_tier = "Tier B"`
- `direct_sector_asset_split = FALSE`

---

# 9. Role in the transformation-elasticity model

The real-volume machinery share enters as an A03 composition proxy.

It does not define the first-stage A00 relation. The A00 relation remains aggregate $K_t$, time-varying $\theta_t$, with $q_t^{\omega,h}=\sum_{s=1}^{t}m_{s-1}^{(h)}\Delta k_s$.

Once the aggregate A00 coefficient is decomposed into A03 channels, the structural relation is:

$$
\theta_t^{tot}
=
s_t\theta_t^M
+
(1-s_t)\theta^O
$$

With the available proxy data, the empirical version is:

$$
\theta_t^{tot}
\approx
s_{t,proxy}^{ME|ME,NRC}\theta_t^M
+
(1-s_{t,proxy}^{ME|ME,NRC})\theta^O
$$

This approximation must be stated as an A03 proxy relation.

It identifies a composition-weighted transformation object using the available ME–NRC component basis. It does not directly identify the machinery-specific structural elasticity.

---

# 10. External-mechanization wedge

For the peripheral extension, the machinery share of accumulation is:

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

If the object is physical mechanization pressure, use real investment composition:

$$
\varphi_t^R
$$

If the object is foreign-exchange expenditure pressure, current-cost or import-price-adjusted measures may be more appropriate:

$$
\varphi_t^V
$$

or an import-content-weighted machinery share.

Thus:

- real $\varphi_t$ captures machinery volume composition;
- current-cost $\varphi_t^V$ captures expenditure or valuation pressure;
- import-adjusted $\varphi_t$ would be preferred for a strict balance-of-payments mechanism if available.

---

# 11. Implementation rule

The export script should compute both real and current-cost variants.

Default structural variables:

- `s_t_proxy_default = s_ME_over_ME_NRC_gross_real`
- `phi_t_proxy_default = phi_ME_over_ME_NRC_real`

Diagnostic valuation variables:

- `s_t_proxy_cc = s_ME_over_ME_NRC_gross_cc`
- `phi_t_proxy_cc = phi_ME_over_ME_NRC_cc`
- `pK_relative_ME_NRC = pK_ME / pK_NRC`

The S20 script must then report:

- `composition_status = "proxy_available"`
- `composition_basis = "ME_NRC_component_proxy"`
- `composition_tier = "Tier B"`
- `direct_sector_asset_split = FALSE`

---

# 12. Guardrails

Do not write:

> The US data directly identify the machinery share of nonfinancial corporate capital.

Write:

> The US data provide a ME–NRC component proxy for the machinery share relevant to the nonfinancial-corporate transformation relation.

Do not write:

> The real and current-cost composition shares are interchangeable.

Write:

> Real composition shares capture volume composition; current-cost shares capture valuation and relative-price effects.

Do not write:

> TOTAL_PRODUCTIVE is a theoretical category.

Write:

> The implementation denominator is the ME–NRC component aggregate. The label `TOTAL_PRODUCTIVE` should be avoided in Chapter 2 outputs.

Do not write:

> IP is irrelevant.

Write:

> IP is excluded from the default ME–NRC denominator and may be activated only as an explicit robustness denominator.

---

# 13. Locked formulation

The default US composition measure for Chapter 2 is a Tier-B ME–NRC component proxy for the machinery share relevant to the NFCorp-centered transformation relation.

It should be constructed using account-specific real stock and investment measures, with current-cost variants retained as diagnostics.

The price-deflator protocol requires that each asset account be deflated internally before aggregation. Differences between machinery and construction price indexes must be recorded through a relative-price wedge and not silently absorbed into the composition variable.

This preserves the distinction between real productive-capital composition, valuation composition, and external-expenditure pressure.
