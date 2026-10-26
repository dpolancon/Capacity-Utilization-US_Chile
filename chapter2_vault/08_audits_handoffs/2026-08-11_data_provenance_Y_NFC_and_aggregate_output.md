---
type: data_provenance_audit
status: active
depends_on: [
  "chapter2_vault/06_paper_facing/00N_Chapter2_PaperFacing_MAP.md",
  "chapter2_vault/04_data_measurement/L06_US_Distributive_Variable_Profit_Share_Ledger.md"
]
stage_scope: all_stages
country: US
last_updated: 2026-08-11
updated_by: DATA_PROVENANCE_AUDIT_Y_NFC_AND_OUTPUT
layer: governance_audit
role: data_provenance_and_accounting
stage: section1_to_section4
tags: [data-provenance, bea, nipa, output-deflator, capacity-utilization, crosswalk]
---

# Comprehensive Data Provenance Audit: Nonfinancial Corporate Real Output ($Y^{\text{NFC}}$) and Aggregate Capacity Utilization Reconstruction

## 1. Executive Summary & Audit Scope
This audit documents the complete end-to-end data provenance for:
1. **$Y^{\text{NFC}}$ (Nonfinancial Corporate Real Output)**: The dependent variable ($y_t = \log Y_{\text{REAL},t}^{\text{NFC}}$) used across all Section 3.1 and Section 3.2 Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS models.
2. **Aggregate Output ($Y_t$) & Potential Output ($Y_t^p$)**: The empirical real output series and reconstructed potential output series used to calculate aggregate capacity utilization ($\mu_t = Y_t / Y_t^p = \exp(y_t - y_t^p)$) in Section 3 and Section 4.

The audit provides an exhaustive crosswalk linking **BEA NIPA source tables, BEA API series codes, FRED ticker symbols, NIPA line numbers, units, sector boundaries, and exact mathematical accounting derivations**.

---

## 2. Sector Boundary & Accounting Definitions

### A. Nonfinancial Corporate Business (NFC) vs. Total Corporate (CORP) vs. Financial (FIN)
The empirical estimation strictly enforces legal-form-of-organization accounting boundaries:
- **NFC (Nonfinancial Corporate Business)**: Excludes financial intermediaries (banks, insurance companies, investment funds) to isolate productive value creation on the shop floor.
- **CORP (Total Corporate Business)**: $\text{CORP} = \text{NFC} + \text{FIN}$.
- **FIN (Financial Corporate Business)**: Intermediate financial claims and net interest flows.

### B. Income & Value Added Concepts
From NIPA Table 1.14 (Gross Value Added of Nonfinancial Corporate Business):
$$\text{Gross Output } (W) = c + v + s$$
$$\text{Gross Value Added } (\text{NFC\_GVA}) = \text{NFC\_CFC} + \text{NFC\_NVA}$$
$$\text{Net Value Added } (\text{NFC\_NVA}) = \text{NFC\_COMP} + \text{NFC\_NOS}$$
$$\text{Net Operating Surplus } (\text{NFC\_NOS}) = \text{NFC\_PROFITS\_IVA\_CC} + \text{NFC\_NET\_INT} + \text{NFC\_TRANSFERS\_NET}$$

Where:
- $\text{NFC\_COMP} = v$ (Variable capital / labor compensation).
- $\text{NFC\_NOS} = s$ (Surplus value / Net operating surplus).
- $\text{NFC\_CFC} = CFC$ (Consumption of fixed capital / physical depreciation).

---

## 3. Real Output ($Y^{\text{NFC}}$) Derivation & Deflator Provenance

### A. Primary Real Output Series: Chained 2017 Dollars ($Y_{\text{REAL, baseline}}^{\text{NFC}}$)
- **Source**: BEA NIPA Table 1.14 (Gross Value Added of Nonfinancial Corporate Business in Chained Dollars), Line 41.
- **BEA Series Code**: `B455RX`
- **Description**: Real Gross Value Added of Nonfinancial Corporate Business (Chained 2017 Dollars).
- **Coverage**: Annual observations $1929–2025$ ($N=97$).
- **Unit**: Millions of Chained 2017 Dollars.

### B. Nominal Output Series ($Y_{\text{NOM}}^{\text{NFC}}$)
- **Source**: BEA NIPA Table 1.14 (Gross Value Added of Nonfinancial Corporate Business), Line 17.
- **BEA Series Code**: `A455RC`
- **Description**: Current-Dollar Gross Value Added of Nonfinancial Corporate Business.
- **Coverage**: Annual observations $1929–2025$ ($N=97$).
- **Unit**: Millions of Current Dollars.

### C. Source-Level Implicit Output Price Deflator ($P_{y,t}^{\text{NFC}}$)
The source-level implicit GVA deflator for nonfinancial corporate output is derived directly from the ratio of nominal to chained real value added:
$$P_{y,t}^{\text{NFC}} = 100 \times \frac{\text{NFC\_GVA}_t (\text{Line 17}, \text{A455RC})}{\text{NFC\_GVA\_REAL}_t (\text{Line 41}, \text{B455RX})}$$
- **Base Year**: $2017 = 100.0$.
- **Downstream Function**: Deflates nominal distributive ingredients (such as $\text{NFC\_NVA}$ or $v_{\text{prod}}$) to construct real value measures without price distortions.

### D. Alternative Deflator Proxies (Audited Robustness Battery in S12B)
To verify that regression estimates are invariant to output deflator choice, eight alternative deflator proxies were constructed and validated in `US_S12B_output_price_real_output_layer.R`:

| Deflator Variable Name | BEA / FRED Source Table & Line | Series Code / Ticker | Description & Base Alignment |
|---|---|---|---|
| `P_Y_NFC_GVA_IMPLICIT_SOURCE` | NIPA T11400 Line 17 / Line 41 | `A455RC` / `B455RX` | **Baseline Source Deflator** ($2017=100.0$) |
| `P_Y_NFC_GVA_T115_VALIDATION` | NIPA T11500 Line 1 | `A455RD` | Official Implicit Deflator of NFC GVA ($2017=100.0$) |
| `P_Y_PROXY_GDP_IMPLICIT` | NIPA T10109 Line 1 | `A191RD` / FRED: `GDPDEF` | Gross Domestic Product Implicit Price Deflator |
| `P_Y_PROXY_NONFARM_BUSINESS` | NIPA T10304 Line 2 | `A358RD` / FRED: `IPDBS` | Nonfarm Business Sector Implicit Price Deflator |
| `P_Y_PROXY_BUSINESS_OUTPUT` | NIPA T10304 Line 1 | `A357RD` | Business Sector Output Implicit Price Deflator |
| `P_Y_PROXY_NONFARM_BLS` | BLS Productivity Program | FRED: `PRS85006093` | BLS Nonfarm Business Implicit Price Deflator |
| `P_Y_PROXY_GDPBYIND_FINANCE` | BEA GDP-by-Industry Table | `VA_FIN` | Financial & Insurance Sector Value Added Deflator |
| `P_Y_PROXY_GDPBYIND_MFG` | BEA GDP-by-Industry Table | `VA_MFG` | Manufacturing Sector Value Added Deflator |

---

## 4. Dependent Variable Log Transformation ($y_t$)

Across all cointegrating regressions in Section 3.1 and Section 3.2, the dependent variable $y_t$ is constructed as:
$$y_t = \log(Y_{\text{REAL},t}^{\text{NFC}})$$

Where $Y_{\text{REAL},t}^{\text{NFC}}$ is the chained 2017 dollar real GVA of nonfinancial corporate business (`B455RX`).

### Model Formulations:
1. **Section 3.1 (Aggregate Capital Model - Specification A)**:
   $$y_t = \alpha + \beta k_t^{\text{cap}} + \theta_1 \text{FWL}((1-\iota_{t-1})\omega_{t-1}) + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$
   Where $k_t^{\text{cap}} = \log(K_{\text{ME},t} + K_{\text{NRC},t})$ is core physical productive capital.

2. **Section 3.2 (Heterogeneous Capital Model - Specification B)**:
   $$y_t = \alpha + \theta_{\text{NRC}} k_{\text{NRC},t} + \theta_{\kappa} \kappa_t + \theta_1 \text{FWL}((1-\iota_{t-1})\omega_{t-1}) + \theta_p \text{FWL}(p_t^{\kappa}) + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$
   Where $k_{\text{NRC},t} = \log(K_{\text{NRC},t})$, $\kappa_t = k_{\text{ME},t} - k_{\text{NRC},t}$ is the mechanization gap, and $p_t^{\kappa} = \log(P_{\text{ME},t} / P_{\text{NRC},t})$ is the relative price of machinery to structures.

---

## 5. Capacity Utilization ($\mu_t$) Reconstruction & Potential Output ($Y_t^p$)

### A. Constitutional Definition of Capacity Utilization
Capacity utilization $\mu_t$ is defined as actual real output relative to structural productive capacity (potential output $Y_t^p$):
$$\mu_t = \frac{Y_t}{Y_t^p} \quad \implies \quad \log(\mu_t) = y_t - y_t^p$$
$$\mu_t (\%) = 100 \times \exp(y_t - y_t^p)$$

### B. Pinch-Year Anchor ($1973 = 100\%$)
Following historical peak utilization governance, potential output $Y_t^p$ is anchored at the $1973$ Fordist Golden Age peak:
$$\mu_{1973} = 100.0\% \quad \implies \quad y_{1973}^p = y_{1973}$$

### C. Reconstruction of Potential Output ($y_t^p$)

#### 1. Section 3.1 Aggregate Capital Reconstruction:
$$y_t^p = y_{1973} + \hat{\theta}_0 (k_t^{\text{cap}} - k_{1973}^{\text{cap}}) + \hat{\theta}_1 \text{FWL}\left((1-\iota_{t-1})\omega_{t-1}\right) (k_t^{\text{cap}} - k_{1973}^{\text{cap}})$$

Where:
- $\hat{\theta}_0$: Base transformation elasticity of private core capital.
- $\hat{\theta}_1$: Interaction coefficient measuring how defensive wage pressure forces substitution that alters the marginal transformation yield.

#### 2. Section 3.2 Heterogeneous Capital Reconstruction (Specification B):
In Specification B, potential output accounts for changing asset composition ($\tau_{\text{real},t} = k_{\text{ME},t} - k_{\text{NRC},t}$):
$$\theta_t^{\text{SpecB}} = \frac{\hat{\theta}_{\text{NRC}}^{\text{str}} + MP_{\kappa,t} \cdot \left(\frac{d\tau}{dk_{\text{NRC}}}\right)_t}{1 + s_{\text{ME},t}^{\text{real}} \cdot \left(\frac{d\tau}{dk_{\text{NRC}}}\right)_t}$$
$$y_t^p = y_{1973} + \int_{1973}^t \theta_s^{\text{SpecB}} \, dk_s^{\text{cap}}$$

Where:
- $\left(\frac{d\tau}{dk_{\text{NRC}}}\right)_t$: Smooth non-parametric derivative from LOESS fit ($\text{span} = 0.30$).
- $s_{\text{ME},t}^{\text{real}} = \frac{K_{\text{ME},t}}{K_{\text{ME},t} + K_{\text{NRC},t}}$: Real physical capital share of machinery and equipment.
- $MP_{\kappa,t} = \hat{\theta}_{\kappa}^{\text{str}} + \hat{\theta}_1 \text{FWL}(\omega_{t-1}) + \hat{\theta}_p \text{FWL}(p_t^{\kappa})$: Marginal productivity of mechanization.

---

## 6. Complete BEA / NIPA / FRED API Data Crosswalk Table

The following master table provides the complete technical crosswalk for all variables entering the $Y^{\text{NFC}}$ regressions and capacity utilization reconstructions:

| Variable ID | Canonical Name | BEA Dataset | BEA Table | BEA Line | Series Code (BEA API) | FRED Ticker | Frequency / Unit | Downstream Role & Function |
|---|---|---|---|---|---|---|---|---|
| `NFC_GVA_REAL_T11400_L41` | NFC Real Gross Value Added | `NIPA` | `T11400` | Line 41 | `B455RX` | `A455RX1A027NBEA` | Annual / Millions 2017 \$ | **Dependent variable ($y_t = \log Y_{\text{REAL}}^{\text{NFC}}$)** and actual output $Y_t$ |
| `NFC_GVA` | NFC Current-Dollar GVA | `NIPA` | `T11400` | Line 17 | `A455RC` | `A455RC1A027NBEA` | Annual / Millions Current \$ | Nominal numerator for implicit output deflator $P_{y,t}^{\text{NFC}}$ |
| `NFC_CFC` | NFC Consumption of Fixed Capital | `NIPA` | `T11400` | Line 18 | `A457RC` | `A457RC1A027NBEA` | Annual / Millions Current \$ | Physical depreciation deducted to yield $\text{NFC\_NVA}$ |
| `NFC_NVA` | NFC Net Value Added | `NIPA` | `T11400` | Line 19 | `A458RC` | `A458RC1A027NBEA` | Annual / Millions Current \$ | Denominator for NVA-basis wage shares ($\omega_{\text{NFC,NVA}}$) |
| `NFC_COMP` | NFC Compensation of Employees | `NIPA` | `T11400` | Line 20 | `A460RC` | `A460RC1A027NBEA` | Annual / Millions Current \$ | Variable labor cost numerator for Tier 1 wage share |
| `NFC_NOS` | NFC Net Operating Surplus | `NIPA` | `T11400` | Line 24 | `A464RC` | `A464RC1A027NBEA` | Annual / Millions Current \$ | Surplus value component ($s$) of nonfinancial corporate business |
| `NFC_NET_INT` | NFC Net Interest Payments | `NIPA` | `T11400` | Line 25 | `A465RC` | `A465RC1A027NBEA` | Annual / Millions Current \$ | Net interest payments purged in Clean Corporate denominator |
| `NFC_PROFITS_IVA_CC` | NFC Profits with IVA & CCAdj | `NIPA` | `T11400` | Line 27 | `A466RC` | `A466RC1A027NBEA` | Annual / Millions Current \$ | Corporate profits after inventory & capital consumption adjustments |
| `CORP_GVA` | Total Corporate GVA | `NIPA` | `T11400` | Line 1 | `A432RC` | `A432RC1A027NBEA` | Annual / Millions Current \$ | Total corporate gross value added denominator |
| `CORP_NVA` | Total Corporate NVA | `NIPA` | `T11400` | Line 3 | `A434RC` | `A434RC1A027NBEA` | Annual / Millions Current \$ | Total corporate net value added denominator |
| `CORP_COMP` | Total Corporate Compensation | `NIPA` | `T11400` | Line 4 | `A436RC` | `A436RC1A027NBEA` | Annual / Millions Current \$ | Total corporate employee compensation numerator |
| `FIN_GVA` | Financial Corporate GVA | `NIPA` | `T11400` | Line 16 | `A454RC` | `A454RC1A027NBEA` | Annual / Millions Current \$ | Financial sector value added diagnostic |
| `FIN_NOS_IMPLIED` | Financial Imputed NOS | `NIPA` | `T11400` / `T71100` | Derived | `Derived` | `Derived` | Annual / Millions Current \$ | Purged in Clean Corporate denominator ($\text{CORP\_NVA}^{\text{clean}}$) |
| `GDPDEF` | GDP Implicit Price Deflator | `NIPA` | `T10109` | Line 1 | `A191RD` | `GDPDEF` | Annual / Index $2017=100$ | Alternative deflator proxy (Robustness audit) |
| `IPDBS` | Nonfarm Business Output Deflator | `NIPA` | `T10304` | Line 2 | `A358RD` | `IPDBS` | Annual / Index $2017=100$ | Alternative deflator proxy (Robustness audit) |

---

## 7. Pipeline File Mapping & Execution Provenance

The data flows deterministically through the following repository scripts:

```
[BEA API / NIPA Cache]
         │
         ▼
`US_S12A_observation_payload_import.R`  ──► Imports raw B455RX & A455RC series from NIPA T11400.
         │
         ▼
`US_S12B_output_price_real_output_layer.R` ──► Constructs P_Y_NFC_GVA_IMPLICIT_SOURCE & Y_REAL_NFC_GVA_BASELINE.
         │
         ▼
`US_S29F_shaikh_tonak_wage_share_construction.R` ──► Assembles NVA/GVA wage shares and Clean Corporate series.
         │
         ▼
`COMMON_S30_gpim_baseline_capital_intake.R` ──► Lags wage shares (omega_{t-1}) and computes y_t = log(B455RX).
         │
         ▼
`US_S50_section31_imols_estimation.R` ──► Runs CMPR IM-OLS regressions y_t ~ k_cap + (1-iota)*omega_{t-1}*k_cap.
`US_S61_section32_imols_specB.R`       ──► Runs CMPR IM-OLS regressions y_t ~ k_NRC + kappa + inter_w + inter_p.
         │
         ▼
`US_S60_section32_reconstruction.R`   ──► Reconstructs y_t^p, capacity utilization mu_t, and elasticity theta_t.
```

---
*Authored by Agentic AI Coding Assistant — 2026-08-11*
*Verification Status: PASS (Matches all locked NIPA Table 1.14 lines and BEA API endpoints)*
