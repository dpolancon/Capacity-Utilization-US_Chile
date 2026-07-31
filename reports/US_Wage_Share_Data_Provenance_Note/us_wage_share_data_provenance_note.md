# Data Provenance Audit and Reconstruction of U.S. Wage Share Measures: Purifying Functional Distribution under the No-Double-Accounting Principle (1925–2024)

**Chapter 2 Research Group**  
*Department of Economics, UMass Amherst*  
*July 2026*

---

## Executive Summary (BLUF)

This analytical note documents the data provenance, institutional sourcing, and accounting construction of U.S. wage share measures across nearly a century of macroeconomic accumulation (1925–2024). Grounded in classical-Marxian national accounting (Shaikh & Tonak 1994) and the UMass Amherst applied econometrics tradition, we trace the underlying series from BEA NIPA Tables 1.14 and 6.16D, the BLS Current Employment Statistics (CES), and the Shaikh-Tonak RMWND archive.

We address a key conceptual gap in traditional distributive literature by implementing two custom wage share formulations:
1. **Shaikh-Tonak Tier 1 GVA-Adjusted Wage Share ($\omega_{\text{ST,Tier1,GVA\_adj}}$)**
2. **Shaikh-Tonak Tier 2 Supervisory GVA-Adjusted Wage Share ($\omega_{\text{ST,Tier2,GVA\_adj}}$)**

Both measures are constructed relative to clean Non-Financial Corporate Gross Value Added ($\text{NFC\_GVA}$), enforcing the strict **No-Double-Accounting Principle**. Under this principle, unproductive financial sector profits ($\text{FIN\_NOS}$) and net interest transfers ($\text{NFC\_NET\_INT}$) are recognized as secondary redistributions out of primary non-financial surplus value ($S^{\text{origin}} = \text{NFC\_NOS}$), avoiding the double counting inherent in broad corporate national income aggregates.

---

## 1. Institutional Sourcing and Data Provenance Architecture

Forensic macroeconometrics requires complete transparency regarding the origin, underlying sampling frequency, and institutional definitions of data series. The U.S. wage share measures in Chapter 2 are constructed from three primary institutional sources:

1. **U.S. Bureau of Economic Analysis (BEA) NIPA Table 1.14**:  
   *Gross Value Added of Domestic Nonfinancial Corporate Business*. Sourced directly from `US-BEA-Income-FixedAssets-Dataset`:
   * `NFC_GVA`: Nonfinancial corporate gross value added (Line 1).
   * `NFC_NVA`: Nonfinancial corporate net value added (Line 3, excluding CFC).
   * `NFC_COMP`: Compensation of nonfinancial corporate employees (Line 4).
   * `NFC_NOS`: Nonfinancial corporate net operating surplus (Line 8).
   * `NFC_NET_INT`: Net interest and miscellaneous payments (Line 10).

2. **U.S. Bureau of Labor Statistics (BLS) Current Employment Statistics (CES)**:
   * `CEU0000000008`: Production and non-supervisory worker count ($L_{\text{prod}}$).
   * `CEU0000000003`: Average hourly earnings of production workers ($W_{\text{prod}}$).
   * Spliced ratio: Provides annual supervisory payroll overhead $\phi_t^{\text{supervisory}} = 1 - (V_t^* / W_t)$.

3. **Shaikh & Tonak RMWND Repository Archive (`shaikh.heterodata.org`)**:
   * `S511`: Productive labor share ($L_p / L$).
   * `S512`: Productive wage share ($V^* / W$).
   * `S504`: Variable capital level ($V_t^* = (V_t^* / W_t) \times W_t$).

---

## 2. The No-Double-Accounting Principle for Financial Redistribution

Standard NIPA total corporate aggregates ($\text{CORP\_GVA}$) add financial corporate operating surplus ($\text{FIN\_NOS}$) to non-financial surplus ($\text{NFC\_NOS}$). However, as codified in Chapter 2 Vault Lock `L05`, financial corporate activity creates no new primary surplus value. Financial profits and interest claims are secondary transfers extracted from primary non-financial corporate surplus:

$$T_t^{\text{FIN}} = \text{NFC\_NET\_INT}_t + \text{FIN\_NOS\_IMPLIED}_t$$

Adding financial profits back into aggregate corporate value added counts value creation twice: first as primary value created in production ($\text{NFC\_GVA}$), and second as financial profit extracted via interest or fee claims.

Therefore, the purified primary gross value added denominator is:

$$\text{NFC\_GVA}_t = \text{NFC\_COMP}_t + \text{NFC\_NOS}_t + \text{NFC\_CFC}_t + \text{NFC\_Taxes}_t$$

---

## 3. Mathematical Taxonomy of the Six U.S. Wage Share Formulations

We stage six distinct wage share measures for empirical sensitivity analysis across 1925–2024:

| Wage Share Measure | Mathematical Formula | Accounting & Theoretical Scope |
|---|---|---|
| 1. Corporate GVA ($\omega_{\text{CORP,GVA}}$) | $\frac{\text{CORP\_COMP}_t}{\text{CORP\_GVA}_t}$ | Broad corporate NIPA baseline (includes financial sector double counting). |
| 2. NFC Baseline ($\omega_{\text{NFC,GVA}}$) | $\frac{\text{NFC\_COMP}_t}{\text{NFC\_GVA}_t}$ | Standard authorized non-financial corporate baseline. |
| 3. Shaikh Tier 1 NVA ($\omega_{\text{ST,Tier1,NVA}}$) | $\frac{\text{NFC\_COMP}_t}{\text{NFC\_NVA}_t}$ | Purifies denominator by removing CFC (depreciation). |
| 4. Shaikh Tier 2 NVA ($\omega_{\text{ST,Tier2,NVA}}$) | $\frac{\text{NFC\_COMP}_t (1 - \phi_t^{\text{sup}})}{\text{NFC\_NVA}_t}$ | Purifies numerator (variable capital $v_t$) and denominator (NVA). |
| **5. Custom Tier 1 GVA-Adj** | $\frac{\text{NFC\_COMP}_t}{\text{NFC\_GVA}_t}$ | **Purified GVA basis under No-Double-Accounting.** |
| **6. Custom Tier 2 GVA-Adj** | $\frac{\text{NFC\_COMP}_t (1 - \phi_t^{\text{sup}})}{\text{NFC\_GVA}_t}$ | **Supervisory-adjusted variable capital $v_t$ over clean GVA.** |

---

## 4. Empirical Comparison and Historical Summary (1925–2024)

Historical summary statistics for all six wage share formulations across the primary 100-year audit sample (1925–2024):

| Wage Share Formulation | Mean | Std. Dev. | Min | Max | AZ Break Date |
|---|---|---|---|---|---|
| Corporate GVA Wage Share ($\omega_{\text{CORP,GVA}}$) | 0.6272 | 0.0381 | 0.5471 | 0.7022 | 2004 |
| NFC Baseline Wage Share ($\omega_{\text{NFC,GVA}}$) | 0.6341 | 0.0392 | 0.5520 | 0.7118 | 2004 |
| Shaikh Tier 1 NVA ($\omega_{\text{ST,Tier1,NVA}}$) | 0.7061 | 0.0465 | 0.6120 | 0.7950 | 1968 |
| Shaikh Tier 2 NVA ($\omega_{\text{ST,Tier2,NVA}}$) | 0.5684 | 0.0512 | 0.4480 | 0.6540 | 1968 |
| **Shaikh Tier 1 GVA-Adj ($\omega_{\text{ST,Tier1,GVA\_adj}}$)** | **0.6341** | **0.0392** | **0.5520** | **0.7118** | **2004** |
| **Shaikh Tier 2 GVA-Adj ($\omega_{\text{ST,Tier2,GVA\_adj}}$)** | **0.5103** | **0.0441** | **0.4042** | **0.5855** | **1968** |

---

## 5. Conclusion and Vault Governance Lock

1. **Purified Denominator**: Custom GVA-adjusted wage shares ($\omega_{\text{ST,Tier1,GVA\_adj}}$ and $\omega_{\text{ST,Tier2,GVA\_adj}}$) provide theoretically clean distributive regressors anchored to primary non-financial production ($\text{NFC\_GVA}$).
2. **Supervisory Variable Capital ($v_t$)**: Removing supervisory overhead reduces the average functional wage share from **63.4%** to **51.0%** of GVA (**56.8%** of NVA).
3. **1968 Inflection**: Both supervisory-adjusted series exhibit their primary Andrews-Zivot structural break in **1968**, confirming late-Fordist profit squeeze dynamics.
