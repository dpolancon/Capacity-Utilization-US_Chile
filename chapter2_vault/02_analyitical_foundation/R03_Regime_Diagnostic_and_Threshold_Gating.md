---
type: note
subtype: rule
status: active
layer: analytical_foundation
design_role: diagnostic_protocol
scope: chapter2_core
related_to:
  - A01_Extensive_Accumulation
  - A02_Intensive_Accumulation
  - A04_PeripheralTransformationElasticity
created: 2026-05-27
---

# R03: Regime Diagnostic and Threshold Gating

## Core Rule
Regime transitions ($\lambda^{[s]} \to \lambda^{[s']}$) are gated **exclusively** by extensive-margin structural breaks or closure-condition failures. Intensive-margin friction and peripheral FX-realization gates validate or attenuate mechanisms but never trigger regime shifts independently.

## 1. Unified Diagnostic Hierarchy
| Layer | Indicator | Theoretical Gate | Temporal Horizon |
|-------|-----------|------------------|------------------|
| L1: Closure Conditions | Breaks in $r^N$, $\chi^N$, institutional wage-price norms | Basu reproduction schemas, Regulation theory | Multi-decade |
| L2: Extensive-Margin Structure | Structural breaks in $K^{NRC}$ trend, lumpy investment episodes | Lumpiness, irreversibility, long gestation (per [[A01_Extensive_Accumulation]]) | 5–15 years |
| L3: Peripheral FX-Realization | $\phi_t$ drops below 1, $\pi^{eff} < \pi$, BoP stress indicators | Import-dependent $K^{ME}$, realization bottleneck (per [[A04_PeripheralTransformationElasticity]]) | 2–7 years |
| L4: Intensive-Margin Friction | $\omega_t \cdot c_t$ attenuation, credit/vintage hysteresis, Vidal friction | Financial gating, internal division, diffusion lags (per [[A02_Intensive_Accumulation]]) | 1–3 years |

**Decision Rule:** $s \to s'$ transition is **only admissible** if L1 or L2 confirms a structural break. L3 and L4 are corroborative or trigger mechanism-validation protocols.

## 2. Peripheral FX-Realization Gate (per [[A04_PeripheralTransformationElasticity]])
When $F^{avail}_t < F^{req}_t$, the FX-conversion ratio $\phi_t < 1$ squeezes $\pi^{eff} = \pi \cdot \phi_t$. This truncates $\theta^{ME}_{periph}$ independently of $\omega$. 
- **Diagnostic:** Current account stress, reserve adequacy, import compression, terms-of-trade shocks.
- **Action:** If $\phi_t$ binds, interpret $\omega_t \cdot c_t$ attenuation as realization-gated accumulation, not mechanism failure. Do not escalate to regime transition unless L1/L2 triggers.

## 3. Escalation Matrix
| Signal | Interpretation | Required Action |
|--------|----------------|-----------------|
| L1/L2 breaks | Extensive reorganization / closure shift | Freeze estimation → validate historically → transition to $\lambda^{[s']}$ |
| L3 active, L1/L2 silent | FX-realization bottleneck | Retain regime; apply $\pi^{eff}$ truncation; document peripheral wedge |
| L4 active, L1-L3 silent | Intensive friction (credit/vintage/Vidal) | Continue estimation; flag intra-regime "becoming" noise |
| L1/L2 + L3 active | Structural break + peripheral stress | Transition regime; re-initialize FX gate for new $s'$ |

## Locked Formulation
Regime stability is anchored to the extensive margin and institutional closure. Peripheral FX-realization and intensive friction operate as validation layers, not regime triggers. Threshold estimation must respect this hierarchy to preserve the constitutional firewall between theoretical objects and empirical diagnostics.