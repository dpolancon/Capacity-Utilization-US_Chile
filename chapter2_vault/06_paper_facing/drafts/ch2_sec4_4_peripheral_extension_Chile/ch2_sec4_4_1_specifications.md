---
type: paper_draft
status: active
depends_on:
  - chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md
  - chapter2_vault/06_paper_facing/00E_Chapter2_PaperFacing_Constitution.md
  - chapter2_vault/06_paper_facing/00S_Chapter2_Symbology_and_Notation_Lock.md
  - chapter2_vault/04_data_measurement/V02_Chile_KStock_DataProvenance_Management.md
  - chapter2_vault/08_audits_handoffs/2026-08-09_chile_data_provenance_audit_report.md
stage_scope: section_4_4
country: CL
last_updated: 2026-08-09
updated_by: CHILE_DIVISIA_ELASTICITY_FORMULATION_LOCK
layer: paper_facing
role: draft
stage: paper-assembly
tags:
  - chapter2/paper-facing
  - chapter2/chile
  - chapter2/specifications
scope: chapter2
priority: core
---

# Section 4.4.1 Model Specifications & External Constraints: Peripheral Chile

## 1. Aggregate Structural Production Surface

Following [[00E_Chapter2_PaperFacing_Constitution]] and [[00S_Chapter2_Symbology_and_Notation_Lock]], the long-run production surface for the Chilean peripheral economy ($1920\text{--}2024$, $N=104$) is specified as:

$$y_t = \alpha + \theta_{\text{NRC}} k^{\text{NR}}_t + \theta_{\kappa} \kappa_t + \theta_{\omega\kappa} \hat{\omega}^{\text{ortho}}_{t-1} \kappa_t + \theta_{\kappa p^{\kappa}} \hat{p}^{\kappa, \text{ortho}}_t + \delta_{\kappa} (\kappa_t \cdot D^{\text{ext}}_t) + \delta_{\omega\kappa} (\hat{\omega}^{\text{ortho}}_{t-1} \kappa_t \cdot D^{\text{ext}}_t) + u_t$$

where:
*   $y_t = \ln Y_t$ is aggregate Chilean Real GDP in constant 2003 CLP.
*   $k^{\text{NR}}_t = \log K^{\text{NR}}_t$ is the log real net stock of non-residential structures (extensive plant envelope).
*   $k^{\text{ME}}_t = \log K^{\text{ME}}_t$ is the log real net stock of machinery and equipment (intensive productive capacity).
*   $\kappa_t = k^{\text{ME}}_t - k^{\text{NR}}_t$ measures the mechanization composition gap.
*   $\hat{\omega}^{\text{ortho}}_{t-1}$ is the lagged wage share $\omega_{t-1}$, Frisch-Waugh-Lovell (FWL) orthogonalized against base capital regressors ($k^{\text{NR}}_t, \kappa_t$).
*   $\hat{p}^{\kappa, \text{ortho}}_t$ is the log relative price ratio $p^{\kappa}_t = \ln(P^{\text{ME}}_t / P^{\text{NRC}}_t)$, FWL-orthogonalized against base capital regressors.
*   $D^{\text{ext}}_t = \mathbb{I}(v_t \le \hat{\gamma})$ is the state-dependent external balance of payments strangulation dummy.

---

## 2. The Aggregate Transformation Elasticity ($\theta^{\text{Peripheral}}_t$)

The aggregate transformation elasticity ($\theta^{\text{Peripheral}}_t$) is the ratio of the total differentials of potential capacity ($dy^p_t$) and aggregate log capital ($dk^{\text{cap}}_t$) along the empirical accumulation path.

### A. Total Differential of Potential Capacity ($dy^p_t$)
Holding the slow-moving state variables fixed, taking the total differential of the production surface yields:
\begin{align}
    dy^p_t &= \theta_{\text{NRC}} dk^{\text{NR}}_t + MP_{\kappa, t} d\kappa_t \\
    &= \theta_{\text{NRC}} dk^{\text{NR}}_t + \left(\theta_{\kappa} + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p^{\kappa}} p^{\kappa}_t + \delta_{\kappa} D^{\text{ext}}_t + \delta_{\omega\kappa} (\omega_{t-1} D^{\text{ext}}_t) \right) d\kappa_t
\end{align}

### B. Divisia Index of Heterogeneous Aggregate Capital ($dk^{\text{cap}}_t$)
Variation in aggregate capital follows from the Divisia index of its heterogeneous structural components. Since $s_{\text{ME}, t} + s_{\text{NRC}, t} = 1$ and $d\kappa_t = dk^{\text{ME}}_t - dk^{\text{NRC}}_t$:
\begin{align}
    dk^{\text{cap}}_t &\approx s_{\text{ME}, t} dk^{\text{ME}}_t + s_{\text{NRC}, t} dk^{\text{NRC}}_t \\
    &= dk^{\text{NR}}_t + s_{\text{ME}, t} d\kappa_t
\end{align}

### C. The Ratio along the Empirical Accumulation Path
Dividing $dy^p_t$ by $dk^{\text{cap}}_t$ and decomposing $d\kappa_t$ into its inner composition $\frac{d\kappa_t}{dk^{\text{NR}}_t} = \left(\frac{dk^{\text{ME}}_t}{dk^{\text{NR}}_t} - 1\right)$ yields the state-dependent aggregate transformation elasticity:

\begin{equation}
    \theta^{\text{Peripheral}}_t = \frac{\theta_{\text{NRC}} + \left[ \theta_{\kappa} + \theta_{\omega\kappa} \omega_{t-1} + \theta_{\kappa p^{\kappa}} p^{\kappa}_t + \delta_{\kappa} D^{\text{ext}}_t + \delta_{\omega\kappa} (\omega_{t-1} D^{\text{ext}}_t) \right] \left( \frac{d\kappa_t}{dk^{\text{NR}}_t} \right)}{1 + s_{\text{ME}, t} \left( \frac{d\kappa_t}{dk^{\text{NR}}_t} \right)}
    \label{eq:theta_divisia_peripheral}
\end{equation}

where:
*   $\frac{d\kappa_t}{dk^{\text{NR}}_t} = \beta^{\text{path}}_t - 1$ is estimated via non-parametric LOESS / rolling window regression of $k^{\text{ME}}_t$ on $k^{\text{NR}}_t$ along the historical accumulation path ($\text{span} = 0.35$).
*   $s_{\text{ME}, t} = \frac{K^{\text{ME}}_t}{K^{\text{ME}}_t + K^{\text{NR}}_t}$ is the real share of machinery and equipment in aggregate capital.

---

## 3. Multi-Proxy Relative Capital Price Matrix ($p^{\kappa}_t$)

To address the absence of official sectorial fixed-asset price deflators prior to 1940, we construct a 4-variant matrix of relative price proxies $p^{\kappa}_t$:

1.  **Proxy 1 (Real Exchange Rate Baseline)**: $p^{\kappa}_{\text{RER}, t} = \ln(\text{TCREAL}_{t, 2003=1.0})$. Captures foreign currency competitiveness and import cost pressure via the ClioLab PUC RER index.
2.  **Proxy 2 (US Wholesale Capital Import Ratio)**: $p^{\kappa}_{\text{IPMUSA}, t} = \ln(\text{IPMUSA}_{t, 2003=1.0} / P_{K, t, 2003=1.0})$. Measures imported machinery prices (proxied by the US wholesale capital price index) relative to domestic gross capital formation deflator $P_K$.
3.  **Proxy 3 (Composite Import-Adjusted Price)**: $p^{\kappa}_{\text{Composite}, t} = \ln((\text{IPMUSA}_{t, 2003=1.0} \cdot \text{TCREAL}_{t, 2003=1.0}) / P_{K, t, 2003=1.0})$. Combines international capital price trends with real exchange rate shocks.
4.  **Proxy 4 (Terms-of-Trade Adjusted Ratio)**: $p^{\kappa}_{\text{ToT}, t} = \ln((\text{IPMUSA}_{t, 2003=1.0} / \text{TERMINT}_{t, 2003=1.0}) / P_{K, t, 2003=1.0})$. Incorporates raw material export terms of trade relative to capital import costs.

---

## 4. Balance of Payments (BOP) Binding Constraint & Threshold Suite

The peripheral realization constraint is operationalized via a Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS threshold model (Vogelsang et al. 2024):

$$y_t = \alpha + \boldsymbol{\theta}' \mathbf{x}_t + \delta_{\kappa} (\kappa_t \cdot D^{\text{ext}}_t) + \delta_{\omega\kappa} (\hat{\omega}^{\text{ortho}}_{t-1} \kappa_t \cdot D^{\text{ext}}_t) + u_t$$

where $D^{\text{ext}}_t = \mathbb{I}(v_t \le \hat{\gamma})$ is a state-dependent regime dummy defined by Profile Least Squares grid search over candidate threshold variable $v_t$ (trimmed over 15th-to-85th percentiles):

### Threshold Candidate Matrix ($v_t$):

1.  **Prebischian Purchasing Power of Exports ($M^{\text{cap, ToT}}_t$)**:
    $$M^{\text{cap, ToT}}_t = \text{ToT}_{t, 2003=1.0} \cdot X_{\text{FOB}, t}$$
    Measures real export earnings adjusted for terms of trade ($\text{TERMINT}$).
2.  **Machinery Demand Import Imbalance Ratio ($\text{Imbalance}_{\text{level}, t}$)**:
    $$\text{Imbalance}_{\text{level}, t} = \ln(I_{\text{ME}, t}) - \ln(M^{\text{cap, ToT}}_t)$$
    Measures the gap between physical machinery investment demand ($I_{\text{ME}}$ from Pérez & Eyzaguirre) and foreign exchange purchasing power.
3.  **Relative Machinery Accumulation Growth Imbalance ($\text{Imbalance}_{\text{growth}, t}$)**:
    $$\text{Imbalance}_{\text{growth}, t} = \Delta \ln(I_{\text{ME}, t}) - \Delta \ln(M^{\text{cap, ToT}}_t)$$
    Captures dynamic accumulation pressure exceeding capacity to import growth.
4.  **Nievas & Piketty (2025) Manufactured Goods Imports ($M^{\text{manuf}}_t / Y_t$)**:
    WBOP Sheet `B3c` column `CL`. Directly proxies capital goods / machinery import dependence as a share of GDP.
5.  **Nievas & Piketty (2025) Foreign Income Outflows ($D1c_t$)**:
    WBOP Sheet `D1c` column `CL`. Profit remittances and external interest payments (% GDP) constraining import capacity.

---

## 5. Monte Carlo Replication Protocol

All non-standard fixed-$b$ critical bounds for coefficient $t$-statistics and $CT_{\text{IM}}$ cointegration statistics are simulated across $100,000$ passes using `CL_S52_cmpr_montecarlo_critical_values.R`. Computational reproducibility is guaranteed by explicitly locking the random seed:
*   Script initialization: `set.seed(1920)`
*   Parallel PSOCK cluster stream: `parallel::clusterSetRNGStream(cl, 1920)`

---

## Related Vault Notes

- [[00N_Chapter2_PaperFacing_MAP]] — Locked 6-section chapter structure
- [[00E_Chapter2_PaperFacing_Constitution]] — Constitutional paper-facing claim
- [[00S_Chapter2_Symbology_and_Notation_Lock]] — Notation lock
- [[V02_Chile_KStock_DataProvenance_Management]] — Chile data provenance management note
- [[2026-08-09_chile_data_provenance_audit_report]] — Chile master data provenance audit report
- [[R05_Chile_Preferable_Models_and_Aggregate_Elasticity_Audit]] — Chile preferable models & aggregate elasticity audit
