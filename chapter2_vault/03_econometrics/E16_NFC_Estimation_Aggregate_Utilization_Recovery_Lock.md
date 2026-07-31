---
type: econometrics
status: active
depends_on:
  - chapter2_vault/03_econometrics/N01_CapacityUtilization_StructuralObject.md
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-26
updated_by: NFC_ESTIMATION_AGGREGATE_RECOVERY_LOCK
layer: governance_constraint
role: output_recovery_lock
stage: estimation-and-recovery
tags:
  - chapter2/econometrics
  - chapter2/nfc-boundary
  - chapter2/potential-output
  - chapter2/capacity-utilization
aliases:
  - NFC Estimation Lock
  - Aggregate Utilization Recovery
  - Output Boundary Protocol
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# E16: NFC Sector Estimation & Aggregate Utilization Recovery Lock

> [!IMPORTANT]
> **Constitutional Identification Lock**:
> 1. **Estimation Stage ($y_t^{\text{NFC}}$ $\rightarrow$ Potential Capacity $y_t^p$)**:
>    All long-run cointegrating regressions (IM-OLS) MUST use **Non-Financial Corporate Sector Real Gross Value Added ($y_t^{\text{NFC}}$)** as the observed dependent variable. This isolates pure corporate productive accumulation ($K^{\text{NRC}}, K^{\text{ME}}$) and corporate class distribution ($\omega^{\text{NFC}}$) to structurally estimate latent potential capacity $y_t^p$.
> 
> 2. **Utilization Recovery Stage ($y_t \rightarrow \mu_t$)**:
>    To recover **Capacity Utilization ($\mu_t$)**, observed **Total Aggregate Output ($y_t$, Real GDP / Total GVA)** is divided by the structurally reconstructed potential capacity $y_t^p$:
>    $$\mu_t = \frac{Y_t}{Y_t^p} \quad \implies \quad \log \mu_t = y_t - y_t^p$$
>    followed by level-anchoring at historical peak benchmarks (e.g., 1973 peak $\mu_{1973} = 1.00$).

---

## 1. Methodological Rationale

### 1.1 Why NFC Output ($y_t^{\text{NFC}}$) for Estimation?
- **Productive Sector Boundary**: Cointegrating parameters ($\theta_{\text{NRC}}$, $\theta_{\tau}$, $\gamma_{p^{\text{rel}}}$, $\theta_{1,\tau}$) link physical capital stock accumulation ($K^{\text{NRC}}, K^{\text{ME}}$) to technical capacity expansion.
- Incorporating non-corporate, financial sector, or government overhead output into estimation creates measurement error and distorts technical choice parameters.
- NFC Real Value Added ($y_t^{\text{NFC}}$, BEA NIPA Table 1.14) provides the precise empirical boundary for productive capital estimation.

---

### 1.2 Why Aggregate Output ($y_t$) for Utilization Recovery?
- **Macroeconomic Demand Realization**: Observed total aggregate output $y_t$ reflects effective demand realization across the entire economy.
- Capacity utilization $\mu_t = Y_t / Y_t^p$ measures how aggregate macroeconomic demand utilizes total installed structural productive capacity $Y_t^p$.
- Recovering utilization against total aggregate output ensures consistency with macro-level demand-led growth models, Okishio capacity constraints, and official FRB survey benchmarks.

---

## 2. Table Presentation & Footnote Standard

In all paper-facing regression matrices:

- **Dependent Variable Header**: Labeled strictly as $y_t^{\text{NFC}}$ (or `Non-Financial Corporate Real Value Added ($y_t^{\text{NFC}}$)`).
- **Standard Footnote Text**:
  > *"Estimated via Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014) using observed Non-Financial Corporate Real Value Added ($y_t^{\text{NFC}}$; BEA NIPA Table 1.14) to estimate latent structural potential capacity $Y_t^p$. Capacity utilization $\mu_t = Y_t / Y_t^p$ is recovered by evaluating total aggregate real output $Y_t$ against reconstructed potential capacity $Y_t^p$ with 1973 level anchoring ($\mu_{1973} = 1.00$)."*
