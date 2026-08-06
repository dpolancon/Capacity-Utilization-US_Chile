---
type: protocol
status: locked
depends_on:
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
stage_scope: S10
country: US_CL
last_updated: 2026-08-05
updated_by: CAPACITY_UTILIZATION_STATE_DEPENDENT_PINCH_YEAR_PROTOCOL_LOCK
layer: empirical_design
design_role: capacity_utilization_level_anchor_protocol
scope: chapter2_core_support
related_to:
  - A00_Aggregate_Transformation_Benchmark
  - M10_Empirical_Identification_Framework
  - N01_CapacityUtilization_StructuralObject
  - R01_residual_vs_structural_identification
  - GPIM, heterogeneous capital, stock-flow consistency, and valuation registers
  - "Price-deflator protocol for ME–NRC Non Financial-capital composition"
created: 2026-05-14
updated: 2026-08-05
subtype: data_measurement
blocks: []
priority: core
---

# Capacity-utilization pinch-year anchoring & structural recovery protocol

## Constitutional Rescue Rule

Capacity utilization ($\mu_t$) is **never** recovered as a statistical filter residual (e.g., HP filter, quadratic trend, or regression error term). Filtering methods impose $\theta = 1$ by construction, conflating utilization ($\mu_t$) with structural capacity growth ($g_{Y^p}$).

Instead, capacity utilization is structurally rescued downstream of identifying the **state-dependent transformation elasticity** ($\theta_t$), anchored by a historical pinch year ($t^*$), and extrapolated using aggregate observed output ($Y_t$).

---

## 1. Sequence of Structural Recovery

The structural reconstruction of capacity utilization follows a strict four-step sequence:

$$
\text{State-Dependent Relation } \theta_t(e_t, p_t^\kappa)
\rightarrow
\text{Capacity Growth } g_{Y^p, t} = \hat{\theta}_t g_{K, t}
\rightarrow
\text{Pinch-Year Level Anchoring } \hat{Y}^p_{t^*} = Y_{t^*}
\rightarrow
\text{Macro Extrapolation } \hat{\mu}_t = \frac{Y_t^{\text{GDP}}}{\hat{Y}^p_t}
$$

1. **State-Dependent Transformation Elasticity ($\theta_t$):** S30 estimates the long-run cointegrating parameters governing $\theta_t$. The elasticity is not an exogenous technical constant, but an endogenous state-dependent function of distributive pressure ($\omega$), capital composition ($\kappa$), and relative asset prices ($p^\kappa$).
2. **Productive Capacity Trajectory ($\hat{Y}^p_t$):** The rate of growth of potential productive capacity is recovered dynamically as:
   $$ g_{\hat{Y}^p, t} = \hat{\theta}_t \cdot g_{K, t} \quad \implies \quad \Delta \ln \hat{Y}^p_t = \hat{\theta}_t \Delta \ln K_t $$
   Integrating this rate of growth identifies the trajectory and slope of potential output $\hat{Y}^p_t$.
3. **Level Anchoring via Pinch Year ($t^*$):** Cointegration identifies the shape of $\hat{Y}^p_t$ but does not fix its absolute scale. The absolute level scale is anchored at an externally motivated full-capacity reference year $t^*$ where utilization equals unity:
   $$ \mu_{t^*} = 1 \quad \implies \quad \hat{Y}^p_{t^*} = Y_{t^*} $$
4. **Aggregate Output Extrapolation ($\hat{\mu}_t$):** Once the level-anchored potential output path $\hat{Y}^p_t$ is constructed, capacity utilization is extrapolated across the full historical sample using **aggregate observed real output ($Y_t = \text{GDP}_t$)**:
   $$ \hat{\mu}_t = \frac{Y_t^{\text{GDP}}}{\hat{Y}^p_t} $$
   Even if sectorial series (e.g., Non-Financial Corporate Gross Value Added) were used to estimate specific micro/meso parameters of $\theta_t$, the final capacity utilization path is evaluated against aggregate macro output ($Y_t^{\text{GDP}}$) to reflect economy-wide realization discipline.

---

## 2. Pinch-Year Rule

A pinch year is a historically and empirically justified reference point in which capacity utilization is treated as equal to full or normal capacity:

$$
\mu_{t^*} = 1
$$

### Principles of Anchoring:
- **External Motivation:** The pinch year must be externally motivated by independent historical or statistical evidence. It must never be selected to artificially smooth or alter the reconstructed utilization path.
- **Scaling, Not Estimation:** The pinch year acts purely as a level-scaling device. It does not estimate $\theta_t$, shift the cointegrating vector, or define an empirical break date.

---

## 3. Country-Specific Anchors

### United States

$$
t^*_{US} = 1973 \quad \implies \quad \mu_{US, 1973} = 1
$$

- **Rationale:** 1973 corresponds to the historical peak capacity utilization observation in the Federal Reserve Board (FRB) utilization index prior to the 1973–1975 stagflation crisis.
- **Role:** Point-year external pinch anchor for level normalization. It does not restrict estimation windows or imply that utilization converges to unity over time.

### Chile

$$
t^*_{CL} = 1980 \quad \implies \quad \mu_{CL, 1980} = 1
$$

- **Rationale:** 1980 is the historically established full-capacity reference year associated with Ffrench-Davis (2018), capturing the peak of post-ISI financialized expansion prior to the 1982 debt crisis.
- **Role:** Point-year historical reference anchor for level normalization.

---

## 4. Comparative Normalization Rule

Cross-country comparisons between the United States and Chile must **not** force a synchronized calendar anchor year. 

Each country is scaled relative to its own country-specific full-capacity reference point ($t^*_{US} = 1973$, $t^*_{CL} = 1980$). This establishes a common, standardized utilization scale without imposing an artificial world-market synchronization constraint.

---

## 5. Summary of Locked Protocol Rules

1. **Anti-Residual Rule:** Utilization $\mu_t$ is a structural ratio derived from $\hat{Y}^p_t$, never a residual or filtered output gap.
2. **State-Dependent Theta Primacy:** Potential output growth is driven strictly by $g_{Y^p, t} = \hat{\theta}_t g_{K, t}$, where $\hat{\theta}_t$ is state-dependent.
3. **Aggregate GDP Extrapolation:** Extrapolation across the full historical sample uses aggregate observed Real GDP ($Y_t$), anchoring sectorial estimations to macro realization.
4. **Point-Year Pinching:** Level normalization requires explicit point-year anchors ($\mu_{US, 1973} = 1$, $\mu_{CL, 1980} = 1$), keeping historical estimation windows distinct from level anchors.
.
