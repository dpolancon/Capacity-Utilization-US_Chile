---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/N06_Kappa_Identification_and_IMOLS_Exogeneity_Paradox.md
  - chapter2_vault/03_econometrics/N06_LOESS_DataDriven_Structural_Break_Assessment.md
  - chapter2_vault/02_analyitical_foundation/A06_RelativePrice_Mechanization_Theory.md
  - chapter2_vault/06_paper_facing/00S_Chapter2_Symbology_and_Notation_Lock.md
stage_scope: layer_2_estimation
country: US_CL
last_updated: 2026-07-26
updated_by: KAPPA_PATH_DERIVATIVE_LOESS_LOCK
layer: econometrics
scope: all_agent_sessions
tags:
  - chapter2/econometrics
  - chapter2/kappa-identification
  - chapter2/loess
  - chapter2/total-derivative
  - chapter2/lock
subtype: econometric_lock
blocks: []
priority: reference
---

# E18 — Kappa Path Derivative LOESS Identification Lock

## Binding Rule

The path derivative $\frac{d \kappa_t}{d k_t^{\text{NRC}}}$ that enters the Specification B aggregate transformation elasticities:

$$\theta_t^{\text{SpecB1}} = \frac{\theta_{\text{NRC}} + \theta_{\kappa} \frac{d \kappa_t}{d k_t^{\text{NRC}}}}{1 + s_{\text{ME}, t} \, \frac{d \kappa_t}{d k_t^{\text{NRC}}}}$$

$$\theta_t^{\text{SpecB2}}(\omega_{t-1}) = \frac{\theta_{\text{NRC}} + \left( \theta_{\kappa} + \theta_{\omega \kappa} \omega_{t-1} \right) \frac{d \kappa_t}{d k_t^{\text{NRC}}}}{1 + s_{\text{ME}, t} \, \frac{d \kappa_t}{d k_t^{\text{NRC}}}}$$

$$\theta_t^{\text{SpecB3}}(\omega_{t-1}, p_t^{\kappa}) = \frac{\theta_{\text{NRC}} + \left( \theta_{\kappa} + \theta_{\omega \kappa} \omega_{t-1} + \theta_{\kappa p^{\kappa}} p_t^{\kappa} \right) \frac{d \kappa_t}{d k_t^{\text{NRC}}}}{1 + s_{\text{ME}, t} \, \frac{d \kappa_t}{d k_t^{\text{NRC}}}}$$

**is identified via the LOESS non-parametric trend derivative of $\kappa_t$ with respect to $k_t^{\text{NRC}}$, never as a point-wise discrete ratio.**

---

## Standing Prohibition

**Point-wise annual discrete ratios are forbidden.** Computing $\frac{d \kappa_t}{d k_t^{\text{NRC}}} \approx \frac{\Delta \kappa_t}{\Delta k_t^{\text{NRC}}}$ year-by-year produces division-by-zero singularities ($\Delta k_t^{\text{NRC}} \approx 0$ during investment pauses: 1930–33, 1945, 2008–09) and explosive noise spikes that reflect measurement artifacts, not structural economic capacity.

---

## Identification Protocol

### Step 1: LOESS Smoothing of $\kappa_t$ Against $k_t^{\text{NRC}}$

Fit a LOESS (locally estimated scatterplot smoothing) regression of $\kappa_t$ on $k_t^{\text{NRC}}$:

$$\hat{\kappa}_t = \text{LOESS}(\kappa_t \mid k_t^{\text{NRC}}; \, \text{span} = h)$$

where $h$ is the bandwidth parameter governing the degree of local smoothing. The span is selected via GCV (Generalized Cross-Validation) or fixed at a regime-appropriate value (e.g. $h = 0.3$ for century-long series).

### Step 2: Numerical Derivative of LOESS Trend

The path derivative is recovered as the first derivative of the fitted LOESS surface:

$$\widehat{\frac{d \kappa_t}{d k_t^{\text{NRC}}}} = \frac{d \hat{\kappa}_t}{d k_t^{\text{NRC}}} \bigg|_{\text{LOESS}}$$

computed via finite differences on the fitted values ($\frac{\hat{\kappa}_{t+1} - \hat{\kappa}_{t-1}}{k_{t+1}^{\text{NRC}} - k_{t-1}^{\text{NRC}}}$) or analytically from the local polynomial kernel.

### Step 3: Plug into Total Derivative Formula

The smooth LOESS path derivative $\widehat{\frac{d \kappa}{d k^{\text{NRC}}}}$ enters both the numerator and denominator of the $\theta_t^{\text{SpecB}}$ formula. This guarantees:

1. **Non-singularity**: The denominator $1 + s_{\text{ME},t} \cdot \widehat{\frac{d \kappa}{d k^{\text{NRC}}}}$ is bounded and smooth.
2. **Regime sensitivity**: LOESS captures smooth regime transitions (e.g., the 1968 US mechanization inflection detected in [[N06_LOESS_DataDriven_Structural_Break_Assessment]]) without imposing parametric functional form.
3. **Aggregation consistency**: The resulting $\theta_t^{\text{SpecB}}$ is directly comparable to $\theta_t^{\text{SpecA}}$ as a one-sector aggregate elasticity.

---

## Economic Interpretation

The LOESS path derivative $\widehat{\frac{d \kappa_t}{d k_t^{\text{NRC}}}}$ measures the **smooth historical tendency** of how much additional mechanization ($\kappa_t = k_t^{\text{ME}} - k_t^{\text{NRC}}$) accompanies each unit of plant scale expansion ($k_t^{\text{NRC}}$).

| Sign | Regime | Meaning |
|:---|:---|:---|
| $\frac{d \kappa}{d k^{\text{NRC}}} > 0$ | Mechanization-deepening | Plant expansion is accompanied by proportionally faster machinery accumulation. Each new factory arrives with more equipment per unit of structure. |
| $\frac{d \kappa}{d k^{\text{NRC}}} = 0$ | Balanced accumulation | Structures and machinery grow proportionally (Harrodian knife-edge corridor). |
| $\frac{d \kappa}{d k^{\text{NRC}}} < 0$ | De-mechanization / Extensification | Plant expansion outpaces machinery: accumulation shifts toward extensive (spatial) expansion rather than intensive (technique) deepening. |

---

## Vault Cross-References

- Analytical Foundation: [[A06_RelativePrice_Mechanization_Theory]] (Section 3: Total Derivative Derivation)
- Kappa Identification Paradox: [[N06_Kappa_Identification_and_IMOLS_Exogeneity_Paradox]]
- LOESS Structural Break Assessment: [[N06_LOESS_DataDriven_Structural_Break_Assessment]]
- Symbology Lock: [[00S_Chapter2_Symbology_and_Notation_Lock]]
- Estimator Lock: [[E10V_IMOLS_CPR_Active_Estimator_Lock]]
