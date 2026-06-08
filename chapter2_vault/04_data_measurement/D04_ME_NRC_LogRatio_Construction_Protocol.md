---
type: note
subtype: protocol
status: active
layer: data_measurement
design_role: variable_construction_protocol
scope: chapter2_core
related_to:
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - A05_NRCEnvelope_MechanizationBias
  - D01_GPIM_heterogeneous_capital_SFC
  - D02_PriceDeflator_Protocol_K_Composition
  - R10_Binding_Specification_Layering_Rule
governs:
  - K_ME_real
  - K_NRC_real
  - k_ME_t
  - k_NRC_t
  - m_ME_NRC_t
  - c_NRC_ME_t
  - omega_m_ME_NRC_t
measurement_status:
  direct_sector_asset_split: required_for_direct_estimate
  tier_b_component_proxy: admissible_as_proxy_only
  nominal_ratio: inadmissible
  mixed_price_ratio: inadmissible
created: 2026-06-02
updated: 2026-06-02
---
# D04: ME/NRC Log-Ratio Construction Protocol

## Core claim

D04 defines the measurement protocol for constructing the NRC-envelope / mechanization-bias variables introduced in A05.

The central variables are:

$$  
k_t^{NRC} = \log K_t^{NRC},  
$$

$$  
k_t^{ME} = \log K_t^{ME},  
$$

$$  
m_t = k_t^{ME} - k_t^{NRC}  
= \log\left(\frac{K_t^{ME}}{K_t^{NRC}}\right),  
$$

and:

$$  
\omega_{m,t} = \omega_t m_t.  
$$

The construction rule is strict: (K_t^{ME}) and (K_t^{NRC}) must be real component stocks measured in constant-reference prices. Nominal stocks, mixed-price aggregates, and unqualified current-price ratios are inadmissible.

D04 is a data-measurement protocol. It does not authorize estimation. It defines how variables must be built before A05 E-specifications can be used in VIF diagnostics or later S30/S32 estimation.

---

## 1. Position in the architecture

A05 defines the analytical object:

```text
NRC envelope + ME/NRC mechanization bias
```

R10 defines when that object can move through the specification ladder.

D04 defines how the data objects must be constructed.

The sequence is:

```text
A05 defines the object
→ D04 defines the measurement construction
→ R10 governs specification admissibility
→ S31 may run VIF-only diagnostics
→ S30/S32 may estimate only if authorized
```

D04 does not replace D01 or D02.

D01 governs heterogeneous capital stock-flow consistency.

D02 governs deflator and relative-price treatment.

D04 applies those rules specifically to the ME/NRC log-ratio variables required by A05.

---

## 2. Required source stocks

The protocol requires two real capital-stock series:

$$  
K_t^{ME},  
$$

and:

$$  
K_t^{NRC}.  
$$

Where:

```text
K_ME = machinery and equipment capital stock
K_NRC = non-residential construction capital stock
```

Both must be expressed in real terms using component-specific capital-stock deflators.

The valid real-stock construction is:

# $$  
K_t^j

\frac{K_t^{j,nom}}{P_t^j/P_r^j},  
\quad  
j \in {ME,NRC}.  
$$

The reference price base must be internally consistent across the component stocks.

---

## 3. Inadmissible constructions

The following constructions are inadmissible:

```text
nominal K_ME / nominal K_NRC
```

```text
current-cost K_ME / current-cost K_NRC without diagnostic label
```

```text
K_ME deflated by aggregate capital deflator divided by K_NRC deflated by component deflator
```

```text
mixed-price ME/NRC ratios
```

```text
price-wedge variables treated as physical composition variables
```

The reason is simple: the mechanization-bias index must capture real composition, not relative valuation drift.

If a current-cost or price-relative object is used, it must be labeled as diagnostic, not as the core D04 mechanization-bias variable.

---

## 4. Log component variables

Construct:

$$  
k_t^{ME} = \log K_t^{ME},  
$$

and:

$$  
k_t^{NRC} = \log K_t^{NRC}.  
$$

Implementation labels:

```text
k_ME_t
k_NRC_t
```

Both source stocks must be strictly positive before logs are taken.

If either source stock is zero, negative, or missing inside the relevant estimation or diagnostic window, the E-specification candidate must be marked inadmissible for that window.

---

## 5. Mechanization-bias index

The operative mechanization-bias index is:

$$  
m_t = k_t^{ME} - k_t^{NRC}.  
$$

Equivalently:

$$  
m_t = \log\left(\frac{K_t^{ME}}{K_t^{NRC}}\right).  
$$

Implementation label:

```text
m_ME_NRC_t
```

Interpretation:

```text
higher m_ME_NRC_t = more machinery-intensive relative to NRC envelope
lower m_ME_NRC_t = more NRC-heavy relative to machinery
```

This sign convention is binding.

The reverse-sign variable may be constructed for documentation:

$$  
c_t = k_t^{NRC} - k_t^{ME}.  
$$

Equivalently:

$$  
c_t = \log\left(\frac{K_t^{NRC}}{K_t^{ME}}\right) = -m_t.  
$$

Implementation label:

```text
c_NRC_ME_t
```

But (c_t) is documentation-only unless a later note explicitly authorizes a reverse-sign specification.

Do not use (m_t) and (c_t) in the same regression or VIF diagnostic.

---

## 6. Distribution-conditioned mechanization-bias variable

Construct:

$$  
\omega_{m,t} = \omega_t m_t.  
$$

Implementation label:

```text
omega_m_ME_NRC_t
```

This variable captures the distribution-conditioned mechanization-bias channel.

It does not mean that distribution directly interacts with the NRC envelope.

The rule is:

```text
NRC is the extensive envelope.
ME/NRC is the mechanization-bias index.
omega × ME/NRC is the distribution-conditioned mechanization-bias channel.
```

Do not construct:

```text
omega_t * k_NRC_t
```

as a baseline A05 variable.

If such a variable is ever used, it must be explicitly diagnostic and justified by a separate rule note, because it violates the A01/A02 separation between envelope and tactical mechanization.

---

## 7. Candidate variables for A05 E-specifications

D04 authorizes construction of the following variables for VIF-only diagnostics:

```text
k_NRC_t
m_ME_NRC_t
omega_m_ME_NRC_t
```

Candidate E1:

```text
SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS
y_t ~ k_NRC_t + m_ME_NRC_t
```

Candidate E2A:

```text
SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL
y_t ~ k_NRC_t + m_ME_NRC_t + omega_m_ME_NRC_t
```

Candidate E2B:

```text
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
y_t ~ k_NRC_t + omega_m_ME_NRC_t
```

D04 authorizes variable construction.

D04 does not authorize estimation.

D04 does not authorize S40 reconstruction.

---

## 8. Direct versus proxy status

The measurement status of the variables must be declared.

If the source data provide direct NFCorp-by-asset-type capital stocks, then the variables may be labeled:

```text
A03_candidate_direct_asset_split
```

only if:

```text
sector_target = NFCorp
direct_sector_asset_split = TRUE
```

If the source data provide only ME/NRC component proxies, then the variables must be labeled:

```text
A03_candidate_proxy
```

and:

```text
direct_sector_asset_split = FALSE
```

In that case, the outputs must state:

```text
The ME/NRC log-ratio variables are Tier-B component-proxy variables, not direct NFCorp-by-asset-type estimates.
```

The proxy may be useful for feasibility diagnostics and exploratory S30/S32 design, but it cannot be described as direct identification of the NFCorp two-capital mechanism.

---

## 9. Required metadata fields

Any code layer constructing D04 variables must export the following metadata:

```text
composition_status
composition_basis
composition_tier
sector_target
direct_sector_asset_split
K_ME_source
K_NRC_source
K_ME_price_basis
K_NRC_price_basis
K_ME_deflator
K_NRC_deflator
reference_price_year
m_ME_NRC_formula
omega_m_ME_NRC_formula
mechanization_bias_sign
measurement_status
```

Required formula metadata:

```text
m_ME_NRC_formula = "log(K_ME_real / K_NRC_real)"
```

```text
omega_m_ME_NRC_formula = "omega_t * m_ME_NRC_t"
```

Required sign metadata:

```text
mechanization_bias_sign = "higher m_ME_NRC_t means more machinery-intensive relative to NRC"
```

---

## 10. Window-level admissibility checks

For each window used in VIF diagnostics or later estimation, D04 requires the following checks:

```text
K_ME_real finite and positive for all observations
K_NRC_real finite and positive for all observations
omega_t finite for all observations
m_ME_NRC_t finite for all observations
omega_m_ME_NRC_t finite for all observations
n_obs sufficient for requested diagnostic or estimator
```

If any check fails, the window must be marked:

```text
D04_variable_construction_failed
```

or:

```text
D04_window_inadmissible
```

The code must not silently drop years unless a manifest records the dropped years and the reason.

---

## 11. Relation to C1/C2 share-based proxies

C1/C2 use share-based composition variables:

```text
s_proxy_k_t
omega_s_proxy_k_t
```

D04 uses log-ratio variables:

```text
m_ME_NRC_t
omega_m_ME_NRC_t
```

These are not the same object.

The share:

$$  
s_t = \frac{K_t^{ME}}{K_t^{ME} + K_t^{NRC}}  
$$

is bounded between 0 and 1.

The log ratio:

$$  
m_t = \log\left(\frac{K_t^{ME}}{K_t^{NRC}}\right)  
$$

is unbounded and symmetric in proportional changes.

They are monotonically related when both stocks are positive, but they encode different empirical transformations.

Therefore:

```text
C1/C2 = share-based A03 proxy family
E1/E2 = NRC-envelope / log-ratio mechanization-bias candidate family
```

They must not be conflated.

---

## 12. Relation to price-wedge diagnostics

D04 physical-composition variables are distinct from price-wedge diagnostics.

The physical log-ratio is:

$$  
m_t = \log(K_t^{ME}/K_t^{NRC}).  
$$

A relative-price wedge would be:

$$  
p_t^{ME/NRC} = \log(P_t^{ME}/P_t^{NRC}).  
$$

The second object may be useful diagnostically, but it cannot replace the first.

If a model includes price-wedge variables, it belongs to a diagnostic specification family unless a later rule note explicitly reclassifies it.

---

## 13. Relation to S31

S31 may use D04 to construct VIF-only candidate diagnostics.

S31 may compute VIF for:

```text
SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS
SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
```

S31 may not estimate these specifications.

S31 may not report coefficients for them.

S31 may not treat them as S30 outputs.

S31 may only report whether their RHS variables are collinearity-feasible.

---

## 14. Relation to S30/S32

S30 or S32 may estimate E-specifications only after R10 or a later rule note authorizes estimation.

Before estimation, the D04 variables must pass:

```text
construction admissibility
window admissibility
VIF feasibility
metadata completeness
```

Estimation without those checks is invalid.

---

## 15. Relation to S40

S40 cannot consume D04 variables directly.

S40 cannot consume E-specification coefficients unless:

```text
E-specification estimated in S30/S32
human adjudication promotes it
reconstruction status explicitly set to promoted_for_reconstruction
```

D04 does not authorize S40.

D04 only governs variable construction.

---

## Locked formulation

D04 locks the construction protocol for the ME/NRC log-ratio mechanization-bias variables. (K_t^{ME}) and (K_t^{NRC}) must be real component stocks in constant-reference prices. The operative mechanization-bias variable is (m_t = k_t^{ME} - k_t^{NRC} = \log(K_t^{ME}/K_t^{NRC})), where higher values mean greater machinery intensity relative to the NRC envelope. The distribution-conditioned variable is (\omega_{m,t} = \omega_t m_t). These variables may be constructed for A05 VIF-only candidate diagnostics, but they do not authorize estimation, promotion, or S40 reconstruction. If the available data are Tier-B ME/NRC component proxies rather than direct NFCorp-by-asset-type stocks, all outputs must be labeled as proxy-based and cannot be presented as direct sectoral asset-split estimates.