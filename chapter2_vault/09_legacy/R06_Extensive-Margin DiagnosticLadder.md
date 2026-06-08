---
type: note
subtype: rule
status: experimental
layer: analytical_foundation
design_role: diagnostic_protocol
scope: chapter2_core
related_to:
  - N04_Extensive_Margin_and_Structural_Envelope
  - N05_Tactical_Choice_of_Technique
  - M10_Empirical_Identification_Framework
  - R01_Marx_Okishio_Regime_Diagnostic_Guardrail
  - R05_Frontier_of_Not_Becoming
  - A01_Extensive_Accumulation
created: 2026-05-27
---

# R06: Diagnostic Ladder for Regime Transitions ($s \to s'$)

## Core Claim
Regime transitions in the mechanization possibilities frontier ($\lambda^{[s]} \to \lambda^{[s']}$) are not triggered by marginal fluctuations in machinery accumulation or distributive conflict. They are gated exclusively by structural reorganizations of the extensive margin ($K^{NRC}$) and/or breaks in the institutional/financial closure conditions that govern long-run capacity planning.

This diagnostic ladder provides a theoretically grounded, multi-layered protocol for detecting when a regime transition has occurred, ensuring that empirical threshold estimation respects the analytical hierarchy of the Double Choice framework.

---

## 1. Analytical Hierarchy of Regime Detection
Regime stability is anchored to the extensive margin. Therefore, diagnostic tests must prioritize indicators of $K^{NRC}$ reorganization over short-run fluctuations in $K^{ME}$ or $\omega$. The ladder proceeds from slow-moving, structural indicators to faster, tactical signals:

| Layer | Indicator Type | Theoretical Justification | Temporal Horizon |
|-------|---------------|---------------------------|-----------------|
| **L1: Closure Conditions** | Breaks in $r^N$ (normal profit rate), $\chi^N$ (reinvestment ratio), or institutional wage-price norms | Basu (2024) reproduction schemas; Regulation theory (Aglietta, Boyer) | Multi-decade |
| **L2: Extensive-Margin Structure** | Structural breaks in $K^{NRC}$ growth trend, lumpy investment episodes, or spatial-logistical reorganization | Lumpiness, irreversibility, long gestation of infrastructure | 5–15 years |
| **L3: Frontier Parameter Stability** | Joint instability in $\lambda_0^{[s]}, \lambda_1^{[s]}, \lambda_2^{[s]}$ estimated over rolling windows | Mechanization frontier parameters are regime-indexed constants | 3–7 years |
| **L4: Tactical Residual Diagnostics** | Persistent, non-cyclical deviations in $\tilde{\mu}_t$ or breakdown in $\omega_t \cdot c_t$ interaction | Okishio-Vidal friction exceeding intra-regime bounds | 1–3 years |

**Decision Rule:** A regime transition $s \to s'$ is only admissible if **L1 or L2** signals a structural break. L3 and L4 serve as corroborating evidence but cannot gate a transition independently.

---

## 2. Layer-Specific Diagnostic Protocols

### L1: Closure Condition Breaks
- **Normal Profit Rate ($r^N$):** Detect shifts in the institutional anchoring of long-run profitability (e.g., transition from coordinated wage bargaining to financialized shareholder value).
- **Reinvestment Ratio ($\chi^N$):** Identify breaks in credit market structures, state infrastructure policy, or retained earnings conventions that gate long-run $K^{NRC}$ planning.
- **Method:** Historical-institutional analysis, regime narrative mapping, and structural break tests on proxy variables (e.g., long-term interest rate spreads, public investment shares, wage coordination indices).

### L2: Extensive-Margin Structural Breaks
- **$K^{NRC}$ Growth Trend:** Apply Bai-Perron or similar multiple break tests to the long-run growth rate of non-residential construction, controlling for cyclical components.
- **Lumpy Investment Episodes:** Identify discrete, multi-year surges or collapses in $K^{NRC}$ accumulation that exceed normal corridor fluctuations.
- **Spatial-Logistical Reorganization:** Qualitative indicators (e.g., shift from vertically integrated Fordist plants to fragmented just-in-time networks, digitalization of supply chains, green transition infrastructure).
- **Method:** Time-series break detection combined with historical case analysis.

### L3: Frontier Parameter Stability
- **Rolling Window Estimation:** Estimate the mechanization frontier parameters ($\lambda_0, \lambda_1, \lambda_2$) over moving windows. Joint instability across all three parameters signals a potential regime shift.
- **Constraint:** This layer cannot gate a transition alone. Parameter instability must be corroborated by L1 or L2 evidence to avoid false positives from intra-regime tactical noise.

### L4: Tactical Residual Diagnostics
- **Utilization Gap Persistence:** Persistent, non-cyclical deviations in $\tilde{\mu}_t$ that cannot be explained by Okishio-Vidal friction within the current regime.
- **Interaction Breakdown:** Loss of statistical significance or sign reversal in the $\omega_t \cdot c_t$ interaction term, suggesting the induced innovation mechanism has been structurally reorganized.
- **Constraint:** Purely corroborative. Tactical residuals fluctuate within regimes; only persistent, structural deviations warrant escalation to L3/L2 review.

---

## 3. Transition Protocol: $s \to s'$
When L1 or L2 signals a structural break:
1. **Freeze Estimation:** Halt parameter estimation for the current regime $s$.
2. **Historical Validation:** Cross-check the break signal against institutional narratives, policy shifts, or technological paradigm changes (per `N00` references).
3. **Re-initialize Frontier:** Define new regime-indexed constants $\lambda^{[s']}$ and re-estimate the tactical optimization problem within the new structural envelope.
4. **Level Anchoring Continuity:** Ensure the utilization extraction protocol ($\mu_t$) maintains historical continuity across the transition (no artificial jumps in $\mu_t$ due to regime re-estimation).
5. **Document the Break:** Record the theoretical justification for the transition in the empirical log (per `PRE_COMMIT_CH2_CHECKLIST`).

---

## 4. Constitutional Compliance & Firewall Protection
- **Design vs. Presentation:** This ladder operates strictly in the analytical foundation layer. Empirical implementation (threshold-FGLS, break tests) must not redefine the theoretical object or mechanism chain.
- **Anti-Residual Ontology:** Regime transitions are never detected by residual behavior alone. The residual ($\tilde{\mu}_t$) is the measure of "becoming," not the driver of structural change.
- **Dimensional Compliance:** All indicators must respect Basu (2022) dimensional analysis. No logarithmic transformations of dimensioned variables without reference-unit normalization.

---

## Locked Formulation
Regime transitions ($s \to s'$) are gated exclusively by structural reorganizations of the extensive margin ($K^{NRC}$) or breaks in institutional/financial closure conditions. The diagnostic ladder prioritizes slow-moving, theoretically grounded indicators (L1–L2) over faster, tactical signals (L3–L4). A transition is only admissible when L1 or L2 confirms a structural break, ensuring that empirical threshold estimation respects the analytical hierarchy of the Double Choice framework and the constitutional rule against residual-defined capacity.