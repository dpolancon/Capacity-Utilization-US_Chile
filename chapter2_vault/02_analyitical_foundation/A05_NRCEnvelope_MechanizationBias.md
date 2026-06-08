---
type: note
subtype: object
status: active_pending_governance_patch
layer: analytical_foundation
design_role: empirical_bridge_definition
scope: chapter2_core
related_to:
  - A00_Aggregate_Transformation_Benchmark
  - A01_Extensive_Accumulation
  - A02_Intensive_Accumulation
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - D01_GPIM_heterogeneous_capital_SFC
  - D02_PriceDeflator_Protocol_K_Composition
  - R05_Frontier_of_Not_Becoming
  - R06_Regime_Gating_and_Diagnostic_Ladder
pending_tasks:
  - Patch governing rule note for binding specification layering.
  - Define when A03 candidate specifications may be moved from VIF-only diagnostics into S30/S32 estimation.
  - Prevent S40 from consuming any A03 candidate specification before human adjudication.
created: 2026-06-02
updated: 2026-06-02
---

# A05: NRC Envelope and ME/NRC Mechanization Bias

## Core claim

A05 defines the empirical bridge between the two-capital analytical architecture and candidate econometric specifications that distinguish the extensive envelope from mechanization bias.

The extensive envelope is represented by non-residential construction capital:

$$  
K_t^{NRC}.  
$$

The mechanization-bias index is represented by the log machinery-to-NRC ratio:

$$  
m_t = k_t^{ME} - k_t^{NRC}  
= \log\left(\frac{K_t^{ME}}{K_t^{NRC}}\right).  
$$

The distribution-conditioned mechanization-bias channel is:

$$  
\omega_{m,t} = \omega_t m_t.  
$$

A higher (m_t) means that the capital structure is more machinery-intensive relative to the non-residential construction envelope.

A05 does not replace A00. It defines an A03 candidate mechanism for testing whether the aggregate transformation relation can be opened into an extensive envelope and a mechanization-bias channel.

---

## 1. Position in the architecture

A00 remains the baseline econometric object:

$$  
y_t = c + \beta_k k_t + \beta_{\omega k}(\omega_t k_t) + \xi_t,  
$$

with:

$$  
\omega_{k,t} = \omega_t k_t,  
$$

and implied aggregate transformation path:

$$  
\theta_t^{A00} = \beta_k + \beta_{\omega k}\omega_t.  
$$

A03 opens this aggregate path into two-capital mechanisms. A05 specifies one empirical form of that opening.

The A05 object is not:

1. a constant-(\theta) model;
    
2. a replacement for A00;
    
3. a direct utilization equation;
    
4. a residual-based capacity-utilization measure;
    
5. an authorization for S40 reconstruction.
    

It is an A03 candidate specification family designed to test whether the aggregate capital relation can be decomposed into:

1. an extensive envelope channel;
    
2. a mechanization-bias channel;
    
3. a distribution-conditioned mechanization-bias channel.
    

---

## 2. Extensive envelope

The envelope variable is:

$$  
k_t^{NRC} = \log K_t^{NRC}.  
$$

(K_t^{NRC}) represents the non-residential construction / plant-scale component of productive capital. Its analytical function is to define the structural envelope within which machinery is deployed.

The envelope is not treated as a tactical variable directly shifted by current distributive conflict. It sets the plant-scale and infrastructural boundary of production.

In empirical specifications, (k_t^{NRC}) therefore enters as the extensive-capacity scale variable.

---

## 3. Mechanization-bias index

The mechanization-bias index is:

$$  
m_t = k_t^{ME} - k_t^{NRC}.  
$$

Equivalently:

$$  
m_t = \log\left(\frac{K_t^{ME}}{K_t^{NRC}}\right).  
$$

This index measures the relative machinery intensity of the capital structure.

A higher (m_t) indicates that machinery and equipment occupy a larger position relative to the non-residential construction envelope.

The reverse-sign index may be useful for documentation:

$$  
c_t = k_t^{NRC} - k_t^{ME}  
= \log\left(\frac{K_t^{NRC}}{K_t^{ME}}\right)  
= -m_t.  
$$

However, A05 uses (m_t = \log(K^{ME}/K^{NRC})) as the operative variable because its sign is intuitive: higher values mean more mechanization.

---

## 4. Distribution-conditioned mechanization bias

Distribution conditions the mechanization-bias channel through:

$$  
\omega_{m,t} = \omega_t m_t.  
$$

This term does not mean that distribution directly shifts the NRC envelope. The envelope remains the structural scale condition.

Instead, (\omega_{m,t}) captures whether the mechanization bias becomes more or less capacity-relevant under different distributive conditions.

The analytical asymmetry is:

$$  
K^{NRC}: \text{extensive envelope}  
$$

$$  
K^{ME}/K^{NRC}: \text{mechanization bias}  
$$

$$  
\omega_t \cdot \log(K^{ME}/K^{NRC}): \text{distribution-conditioned mechanization bias}.  
$$

---

## 5. Candidate specification family

A05 defines three candidate A03 specifications.

These specifications are candidates for VIF feasibility checks and possible later S30b/S32 estimation. They are not currently authorized as S40 reconstruction inputs.

### 5.1 E1: NRC envelope plus mechanization bias

Specification:

$$  
y_t = c + \beta_{NRC} k_t^{NRC} + \beta_m m_t + \xi_t.  
$$

Formula label:

```text
y_t ~ k_NRC_t + m_ME_NRC_t
```

Specification ID:

```text
SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS
```

Interpretation:

- (\beta_{NRC}) captures the extensive envelope effect.
    
- (\beta_m) captures the mechanization-bias effect.
    
- No distribution-conditioned term is included.
    

This is the minimal envelope-versus-mechanization candidate.

---

### 5.2 E2A: NRC envelope plus mechanization bias plus distribution-conditioned mechanization

Specification:

# $$  
y_t

c  
+  
\beta_{NRC} k_t^{NRC}  
+  
\beta_m m_t  
+  
\beta_{\omega m}(\omega_t m_t)  
+  
\xi_t.  
$$

Formula label:

```text
y_t ~ k_NRC_t + m_ME_NRC_t + omega_m_ME_NRC_t
```

Specification ID:

```text
SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL
```

Interpretation:

- (\beta_{NRC}) captures the extensive envelope effect.
    
- (\beta_m) captures the direct mechanization-bias effect.
    
- (\beta_{\omega m}) captures the distribution-conditioned mechanization-bias effect.
    

This is the full A05 candidate specification.

---

### 5.3 E2B: NRC envelope plus distribution-conditioned mechanization only

Specification:

# $$  
y_t

c  
+  
\beta_{NRC} k_t^{NRC}  
+  
\beta_{\omega m}(\omega_t m_t)  
+  
\xi_t.  
$$

Formula label:

```text
y_t ~ k_NRC_t + omega_m_ME_NRC_t
```

Specification ID:

```text
SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED
```

Interpretation:

- (\beta_{NRC}) captures the extensive envelope effect.
    
- (\beta_{\omega m}) captures the distribution-conditioned mechanization-bias effect.
    
- The raw mechanization-bias level (m_t) is omitted.
    

This restricted variant tests whether the distribution-conditioned mechanization channel can be separated from the NRC envelope without also including the raw mechanization-bias level.

---

## 6. Relation to current C1/C2 proxy specifications

The current S30 proxy specifications are:

```text
SPEC_C1_COMPOSITION_STOCK
y_t ~ k_t + omega_k_t + s_proxy_k_t
```

and:

```text
SPEC_C2_FULL_COMPOSITION
y_t ~ k_t + omega_k_t + s_proxy_k_t + omega_s_proxy_k_t
```

These are A03 composition-proxy specifications. They preserve the A00 aggregate envelope (k_t) and add centered share-based composition terms.

A05 defines a different A03 candidate family.

The difference is:

```text
C1/C2 family:
aggregate envelope + share-based composition proxy

E1/E2 family:
NRC envelope + log ME/NRC mechanization-bias index
```

Therefore, C1/C2 and E1/E2 should not be conflated.

C1/C2 are current S30 proxy-escalation specifications.

E1/E2 are candidate A03 specifications requiring VIF feasibility checks and later governance authorization before estimation.

---

## 7. Relation to direct ME/NRC two-capital models

A direct two-capital specification would enter (k_t^{ME}) and (k_t^{NRC}) separately:

$$  
y_t \sim k_t^{NRC} + k_t^{ME} + \omega_t k_t^{ME}.  
$$

This form directly separates the two capital stocks, but it may generate severe multicollinearity because (k_t^{ME}), (k_t^{NRC}), and their interactions share long-run trends.

The A05 log-ratio formulation is designed to reduce that risk by keeping (k_t^{NRC}) as the envelope and using (m_t) as a relative mechanization-bias index.

The empirical question becomes:

Can the NRC envelope and the ME/NRC mechanization-bias index be separated sufficiently to support coefficient interpretation?

That question must be answered through VIF and collinearity diagnostics before any E-specification is estimated.

---

## 8. Data and measurement requirements

A05 requires constant-reference-price capital stocks:

$$  
K_t^{ME}, \quad K_t^{NRC}.  
$$

The operative variables are:

$$  
k_t^{ME} = \log K_t^{ME},  
$$

$$  
k_t^{NRC} = \log K_t^{NRC},  
$$

$$  
m_t = k_t^{ME} - k_t^{NRC},  
$$

$$  
\omega_{m,t} = \omega_t m_t.  
$$

All capital stocks must be constructed in real units using appropriate component-specific deflators. Nominal stocks or mixed-price ratios are inadmissible.

If only Tier-B ME/NRC component proxies are available, then the E-specifications must be labeled as proxy-based:

```text
A03_candidate_proxy
```

and not as direct NFCorp-by-asset-type estimates.

---

## 9. Empirical status

Current status:

```text
A05 object defined.
E1/E2 candidate family analytically specified.
VIF feasibility required before estimation.
S30/S32 estimation not yet authorized.
S40 consumption not authorized.
```

A05 authorizes VIF-only candidate diagnostics.

A05 does not authorize:

1. adding E1/E2 to the S30 estimation grid;
    
2. promoting E1/E2 as A00 replacements;
    
3. using E1/E2 for S40 reconstruction;
    
4. treating E1/E2 outputs as final dissertation results.
    

Those steps require a separate governing-rule patch.

---

## 10. Pending governance patch

A governing-rule note must be added or patched after A05.

Pending task:

```text
Patch governing rules for binding specification layering.
```

The rule patch must define:

1. how A00, A03, diagnostic, and candidate specifications are layered;
    
2. when A03 candidate specifications may be estimated;
    
3. when VIF-only diagnostics are required before estimation;
    
4. when a candidate specification may be promoted to human adjudication;
    
5. why S40 cannot consume any coefficient object until S30/S32 human review explicitly promotes it;
    
6. how code manifests must label baseline, proxy, diagnostic, and candidate specifications.
    

Suggested rule-note target:

```text
03_econometrics/R10_Binding_Specification_Layering_Rule.md
```

or:

```text
05_codes_implementation/C06_BINDING_SPECIFICATION_LAYERING.md
```

The preferred path is to create an R-note if the rule is epistemic and identification-related, and a C-note if the rule is primarily implementation-procedural.

---

## Boundary with A00

A05 does not change the A00 baseline.

A00 remains:

$$  
y_t = c + \beta_k k_t + \beta_{\omega k}(\omega_t k_t) + \xi_t.  
$$

A05 only defines a candidate A03 mechanism for opening the aggregate transformation path into an NRC envelope and ME/NRC mechanization-bias channel.

The sequence is:

$$  
A00 \rightarrow A03 \rightarrow A05.  
$$

A05 is downstream of A00 and internal to A03. It is not a replacement for either.

---

## Locked formulation

A05 defines the NRC-envelope / mechanization-bias candidate specification family. The extensive margin is represented by (k_t^{NRC}), the log real non-residential construction capital stock. The intensive mechanization-bias index is (m_t = k_t^{ME} - k_t^{NRC} = \log(K_t^{ME}/K_t^{NRC})), where higher values indicate greater machinery intensity relative to the NRC envelope. Distribution enters only through the mechanization-bias channel, (\omega_{m,t} = \omega_t m_t), and does not directly interact with the NRC envelope. The E1/E2 specification family is an A03 candidate escalation, not an A00 replacement and not an S40 reconstruction input. Before any E-specification is estimated, it must pass VIF/collinearity feasibility checks and be authorized by a separate binding-specification governance rule.