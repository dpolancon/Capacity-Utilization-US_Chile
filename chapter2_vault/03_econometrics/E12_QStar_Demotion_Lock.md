---
type: econometrics
status: active
depends_on:
  - chapter2_vault/06_paper_facing/Ch2_Outline_DEFINITIVE.md
stage_scope: all_stages
country: US_CL
last_updated: 2026-07-23
layer: code_stage_design
gate_type: demotion-lock
blocks_estimation_until_passed: false
applies_to:
  - accumulated-q-paths
  - optimal-mechanization-proxies
created_by: E12_QSTAR_DEMOTION_RESOLUTION
role: active-lock
stage: pre-estimation-design
aliases:
  - QStar demotion lock
  - Accumulated path demotion
  - Mechanization proxy lock
tags:
  - chapter2/econometrics
  - chapter2/active-lock
  - chapter2/demotion-lock
subtype: econometric_protocol
blocks: []
scope: chapter2
priority: reference
---

# E12 — $Q^*$ Accumulated-Path Demotion Lock

## Active Doctrine
Accumulated-path proxies for optimal mechanization—specifically $Q_t^\omega = \sum \omega_{s-1}\Delta k_s^{\text{cap}}$, $Q_t^{\text{ME share}} = \sum s_{s-1}^{\text{ME}}\Delta k_s^{\text{cap}}$, and $Q_t^q = \sum q_{s-1}\Delta k_s^{\text{cap}}$—are **formally demoted and blocked** as active first-layer specifications for estimating transformation elasticity ($\theta_t$) or representing unobserved optimal technique choice ($q^*$).

Any future session or agent reviewing vault notes must treat $Q^*$ paths as **non-promoted diagnostic artifacts**.

## Demotion Rationale
1. **Extreme Multicollinearity**: In level regressions ($y_t = \alpha + \beta_K k_t^{\text{cap}} + \beta_Q Q_t^\omega$), $Q_t^\omega$ has a correlation of **0.99997** with $k_t^{\text{cap}}$ (Condition Number 271.7), making parameter identification impossible.
2. **$I(2)$ Stochastic Risk**: Observed mechanization path $Q_t^q$ carries unresolved $I(2)$ risk, violating $I(1)$ cointegration admissibility requirements.
3. **Active Replacement**: FWL residual centering ($D_7$ / $D_9$) using orthogonalized residuals $\hat{u}^{(k,\omega)}_t$ or $\hat{u}^{(\tau,\omega)}_t$ is the sole active baseline doctrine under [[E10V_IMOLS_CPR_Active_Estimator_Lock]].

## Blocked Roles
- **Primary Estimator Regressor**: $Q_t^\omega$, $Q_t^{\text{ME share}}$, or $Q_t^q$ must never enter main cointegration equations.
- **Proxy for Optimal $q^*$**: Theoretical claims asserting that $Q^*$ identifies $q^*$ in macro regressions are rejected.

## Links
- [[N03_US_Theta_Integration_Order_Admissibility]]
- [[E10V_IMOLS_CPR_Active_Estimator_Lock]]
- [[H01_Cajas_to_Transformation_Elasticity]]
- [[A02_Intensive_Accumulation]]
