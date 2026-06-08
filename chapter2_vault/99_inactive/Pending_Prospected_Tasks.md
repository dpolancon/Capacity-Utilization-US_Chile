---
type: note
subtype: prospecting
status: active
layer: governance
design_role: pipeline_planning
scope: chapter2_transition
related_to:
  - A01_Extensive_Accumulation
  - A02_Intensive_Accumulation
  - A03_TransformationElasticity_Two-CapitalCapacityComposition
  - A04_PeripheralTransformationElasticity
  - H00_Okishio_Vidal_Decentralized_Accumulation
  - H01_Cajas_to_Transformation_Elasticity
  - R01_Ontological_Interpretation_Guardrails
  - R02_Identification_and_Estimation_Protocol
  - R03_Regime_Diagnostic_and_Threshold_Gating
  - R04_Measurement_and_Accounting_Consistency
created: 2026-05-27
updated: 2026-05-27
---

# PROSPECTING: Analytical Closure Confirmed & Empirical Implementation Handoff

## Core Status
- **R-Series Insertion:** Confirmed. `R01`–`R04` are active and govern ontology, identification, regime gating, and measurement consistency.
- **Legacy Archival:** Confirmed. Superseded notes (`H02`, `H03`, `N01`–`N05`, old `R*`, `E01`) are moved to `09_legacy/`. Cross-reference sweeps complete.
- **Analytical Foundation:** Closed. `A01`–`A04`, `H00`–`H01`, `N00`, `R01`–`R04` form a mathematically consistent, ontologically unified, and constitutionally compliant layer.

The next phase operationalizes capacity reconstruction and regime-gated estimation into the empirical implementation layer.

---

## 1. Draft Level Anchoring Protocol
**Target Series:** `M01_Level_Anchoring_Protocol.md` (`M`-series: Empirical Implementation & Estimation)

**Function:**
Pins the dimensionless utilization gap ($\ln Y_t - \ln \hat{Y}^p_t$) to a verified historical benchmark year $t^*$, recovering the absolute level of $\mu_t$ without relying on the contaminated intercept $\alpha_0$. It operationalizes the anti-residual ontology by ensuring productive capacity is **structurally reconstructed from slopes only**, and utilization is derived as a structurally meaningful deviation, not a statistical residual.

**Architectural Linkages:**
- Directly executes `R02` §3 (Intercept Rule & Level Anchoring)
- Grounds `A03` §6 (Ontological Status: $\mu_t \neq 1$ as historical "becoming")
- Preserves the Design vs. Presentation Firewall by mathematically separating capacity reconstruction ($\hat{Y}^p_t$) from empirical error ($\tilde{\mu}_t$)

---

## 2. Draft FM-OLS/Threshold-FGLS Pipeline
**Target Series:** `M02_FM_OLS_Threshold_FGLS_Pipeline.md` (`M`-series: Empirical Implementation & Estimation)

**Function:**
Translates the two-capital capacity identity, distributive conditioning, and peripheral realization bottleneck into an estimable specification. It defines:
- Data construction sequence (real flows → PIM stocks → $s_t$ → log-level indices)
- FM-OLS bandwidth selection & super-consistent slope extraction
- Threshold-FGLS regime gating (operationalizing `R03` L1/L2 closure proxies and `A04` FX-realization gate $\phi_t$)
- Explicit mapping of estimated slopes ($\hat{\beta}_1, \hat{\beta}_2, \hat{\beta}_3$) to structural payoffs ($\theta^{NRC}, \theta^{ME}$)
- Enforcement of the intercept-discard rule and anti-residual capacity reconstruction

**Architectural Linkages:**
- Directly executes `R02` §1–2 (Estimable Specification & Identification vs. Reconstruction)
- Operationalizes `R03` §1–3 (Unified Diagnostic Hierarchy & Escalation Matrix)
- Bridges `A03` §2 (Stock-Flow Consistency) and `A04` §1–3 (Peripheral FX-Realization Bottleneck) to empirical data pipelines

---

## 3. Series Placement & Naming Convention
| Note | Target Series | Layer | Role |
|------|--------------|-------|------|
| `M01_Level_Anchoring_Protocol.md` | `M` (Method/Empirical) | `03_empirical_implementation/` | Structural utilization pinning; intercept discipline |
| `M02_FM_OLS_Threshold_FGLS_Pipeline.md` | `M` (Method/Empirical) | `03_empirical_implementation/` | Specification, estimation, regime gating, slope mapping |

**Rationale for `M`-Series Placement:** The `R`-series governs analytical rules and diagnostic guardrails. The `M`-series governs estimation protocols, data construction, and algorithmic execution. This preserves the constitutional separation between theoretical constraints (`R`) and empirical operationalization (`M`).

---

## 4. Execution Sequence & Compliance Rules
1. **Sequence:** Draft `M01` → Draft `M02` → Cross-validate against `R01`–`R04` → Lock empirical layer.
2. **Compliance Rules:**
   - **Anti-Residual Lock:** Capacity is never extracted from residuals. $\mu_t$ is always pinned via `M01`.
   - **Intercept Discipline:** $\alpha_0$ is strictly discarded for structural inference in `M02`.
   - **Firewall Enforcement:** Empirical diagnostics cannot overwrite analytical objects ($q^*, \theta^N, \pi^{eff}$). They only measure realized deviations.
   - **Notation Consistency:** All empirical equations use $\pi = 1-\omega$, $\lambda^{[s]}$, $\theta^N(\pi, s)$, $\phi_t$, $\pi^{eff}$ as defined in `A01`–`A04`.
   - **Basu Relaxation Boundary:** Standard log-level cointegration is used, but real stock-flow consistency and asset-specific deflation remain mandatory per `R04`.

---

## Locked Formulation
Analytical foundation closure is confirmed. R-series insertion and legacy archival are complete. The empirical implementation layer (`M`-series) will operationalize capacity reconstruction and regime-gated estimation through `M01` (Level Anchoring Protocol) and `M02` (FM-OLS/Threshold-FGLS Pipeline). Both notes will enforce anti-residual ontology, intercept discipline, and strict firewall compliance while translating the two-capital architecture into estimable specifications. Execution proceeds sequentially with explicit cross-validation against active `R`-series guardrails.