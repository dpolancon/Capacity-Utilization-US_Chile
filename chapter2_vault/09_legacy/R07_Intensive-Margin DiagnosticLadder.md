---
type: note
subtype: rule
status: experimental
layer: analytical_foundation
design_role: diagnostic_protocol
scope: chapter2_core
related_to:
  - A02_Intensive_Accumulation_Choice_of_Technique
  - N04_Extensive_Margin_and_Structural_Envelope
  - R05_Frontier_of_Not_Becoming
  - R06_Regime_Gating_and_Diagnostic_Ladder
  - Okishio_Vidal_Transformation_Elasticity
  - M10_Empirical_Identification_Framework
created: 2026-05-27
---

# R07: Intensive-Margin Diagnostic Ladder (Mechanism Validation & Friction Diagnosis)

## Core Claim
The optimal mechanization choice $q^*(\omega, K^{NRC})$ is an analytical abstraction of **"not becoming"** (smooth reproduction limit). Historical realization $q_t$ systematically deviates due to decentralized accumulation, internal firm division, and financial/technological frictions. 

This diagnostic ladder does **not** gate regime transitions (that is `R06`'s domain). Instead, it validates the empirical admissibility of the induced innovation mechanism, distinguishes intra-regime "becoming" friction from structural mechanism breakdown, and ensures the empirical interaction term ($\omega_t \cdot c_t$) is not contaminated by non-distributive constraints.

---

## 1. Analytical Purpose & Boundary Conditions
| Diagnostic Target | Scope | Escalation Rule |
|------------------|-------|----------------|
| **R06 (Extensive)** | Regime stability, $\lambda^{[s]}$ shifts, closure condition breaks | Triggers $s \to s'$ transition & frontier re-estimation |
| **R07 (Intensive)** | Mechanism validity, friction attribution, interaction-term admissibility | Triggers friction decomposition or model boundary review; **never** triggers regime shift alone |

**Boundary Rule:** Persistent failure in R07 L1 may indicate either (a) unmodeled intensive-margin constraint, or (b) an underlying extensive-margin regime shift. In case (b), escalation to R06 L1/L2 is mandatory. R07 cannot independently redefine the theoretical object or capacity envelope.

---

## 2. Layer-Specific Diagnostic Protocol

### L1: Induced Innovation Coherence
- **Question:** Does the historical mechanization rate respond positively to distributive pressure, as predicted by the FOC $\partial q^*/\partial \omega > 0$?
- **Indicator:** Rolling sign/stability of the $\omega_t \cdot c_t$ interaction coefficient; conditional correlation $\text{Corr}(\Delta q_t, \Delta \omega_t | K^{NRC} \text{ fixed})$.
- **Admissibility Threshold:** Positive, statistically robust response within the current extensive regime.
- **Failure Interpretation:** Mechanism breakdown. Either distributive conflict no longer biases technique choice, or a non-distributive constraint is dominating. Escalate to L2/L3 before considering R06.

### L2: Financial & Credit Gating
- **Question:** Is $K^{ME}$ accumulation blocked by working capital/credit constraints rather than distributive calculus?
- **Indicator:** Real interest rate spreads, corporate credit-to-GDP ratios, debt service-to-cash-flow constraints, liquidity coverage indices.
- **Mechanism Mapping:** Tight credit decouples $q_t$ from $\omega_t$ even when the FOC predicts higher mechanization. The interaction term $\omega_t \cdot c_t$ will weaken, but this is a **financial friction**, not a theoretical failure.
- **Action:** Introduce credit-conditioning controls or interpret weakened $\gamma_4$ as financially constrained induced innovation.

### L3: Technological Diffusion & Vintage Hysteresis
- **Question:** Do scrapping resistance, installation lags, or vintage capital rigidity create a hysteresis band around $q^*$?
- **Indicator:** Gross vs. net $K^{ME}$ investment divergence, average machine age, scrapping rate volatility, diffusion-lag proxies (e.g., patent-to-capex ratios, ICT adoption indices).
- **Mechanism Mapping:** $q_t$ exhibits inertial adjustment. Short-run deviations from $q^*$ are mechanically expected. Only persistent, multi-cycle misalignment warrants mechanism review.
- **Action:** Validate that $\omega_t \cdot c_t$ operates on a medium-horizon filter (3–5 years). Do not penalize the model for short-run vintage rigidities.

### L4: Internal Division Proxy (Vidal Friction)
- **Question:** Is intra-firm contestation (management-labor conflict, shareholder vs. operative priorities, capacity convention disputes) suppressing the tactical response to $\omega$?
- **Indicator:** Wage bargaining centralization indices, profit-retention vs. dividend payout ratios, strike/lockout frequency, internal rate-of-return dispersion across plant divisions.
- **Mechanism Mapping:** The firm does not optimize as a unified agent. Distributive pressure may trigger hoarding, financialization, or output restriction rather than mechanization. This is **Vidal friction**, not Okishio failure.
- **Action:** Document friction channel. Do not reinterpret $\theta^N$ or discard the mechanism. Treat as intra-regime "becoming" noise.

---

## 3. Decision & Escalation Matrix
| R07 Signal | Interpretation | Required Action |
|------------|----------------|-----------------|
| **L1 holds, L2-L3 active** | Mechanism valid; friction explained | Continue estimation; document friction decomposition |
| **L1 weakens, L4 active** | Vidal internal division suppressing response | Retain mechanism; flag as intra-regime contradiction |
| **L1 breaks, L2-L4 stable** | Structural mechanism failure | 1. Cross-check with R06 L1/L2<br>2. If R06 signals break → transition $s \to s'$<br>3. If R06 silent → review analytical boundary of $q^*(\omega)$ |
| **L1 breaks, R06 confirms regime shift** | Extensive-margin reorganization redefining frontier | Freeze intensive estimation; transition to $\lambda^{[s']}$; re-initialize L1 test |

---

## 4. Constitutional Compliance & Firewall Protection
- **Design vs. Presentation:** R07 operates strictly as a validation protocol. It does not redefine $q^*$, $\theta^N$, or the mechanization frontier. Empirical diagnostics must never overwrite the analytical core.
- **Anti-Residual Ontology:** Deviations $q_t \neq q^*$ are expected. The residual is not a misspecification error; it is the empirical fingerprint of capitalist "becoming." R07 attributes deviations to structural friction, not to capacity misdefinition.
- **Dimensional Compliance (Basu, 2022):** All indicators in L1-L4 must be constructed as dimensionless ratios or properly reference-unit normalized. No logarithmic transformations of dimensioned stocks or flows without Basu-compliant indexing.
- **Okishio-Vidal Integration:** L1-L4 explicitly separate Okishio's market-anarchy dispersion (L1/L2) from Vidal's internal-division contestation (L4), preserving the theoretical articulation without collapsing into neoclassical optimization assumptions.

---

## Locked Formulation
The intensive-margin diagnostic ladder validates the empirical admissibility of the induced innovation mechanism ($q^* \leftrightarrow \omega$) and attributes historical deviations to financial gating, technological hysteresis, or internal firm division. It does not gate regime transitions (reserved for R06/extensive margin) and never redefines the theoretical object. Persistent mechanism failure triggers cross-validation with extensive-margin closure conditions; otherwise, deviations are documented as intra-regime "becoming" friction. This protocol ensures that empirical identification remains strictly subordinate to the analytical abstraction of "not becoming" and the constitutional rule against residual-defined capacity.