> [!WARNING]
> **STALE / SUPERSEDED (flagged 2026-08-03).** This file contains numbers from an earlier, pre-fix
> run of the pipeline and does **not** match `us_section31_imols_results.tex` /
> `us_section31_imols_results_v2.pdf`, which are the current, corrected outputs of
> `codes/US_S50_section31_imols_estimation.R`. The generating script defines a path for this `.md`
> file (`md_out`) but never actually writes to it, so this file is an orphaned leftover, not a
> tracked artifact of the current pipeline. Do not cite or audit against the numbers below — see the
> PDF/TeX report instead, and see
> `chapter2_vault/08_audits/2026-08-03_section31_cointegration_stars_audit.md` for what changed and
> why. Recommend deleting this file; left in place pending confirmation.

# Section 3.1 IM-OLS Cointegration Estimation Matrix: U.S. NFC Transformation Elasticity (1929–2024)

**Department of Economics, UMass Amherst**  
*August 2026*

---

## Data Provenance and Estimation Summary

This report presents the empirical cointegration results for Section 3.1 of Chapter 2. All models are estimated via Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014) over the full NIPA sample window (1929–2024, $N=94$ effective observations). Point estimates are tuning-parameter free; fixed-$b$ HAR $t$-statistics use a Bartlett kernel with Newey-West bandwidth. Distributional conditioning variables ($\omega_{t-1}$ and $\iota_{t-1}$) are centered at their 1929 initial values, preserving $\hat{\theta}_0$ as the capital elasticity at the initial state. VIF statistics are computed on the level regressors space. Post-estimation residual break audits use Bai-Perron tests with 15% trimming.

---

## Section 1: Specification Set 1 — Double Interactions ($k^{\text{cap}} \cdot \omega_{t-1}$)

### Table 1: Specification Set 1 Double Interaction IM-OLS Cointegration Estimates (1929–2024)

| Metric / Parameter | M1.1 (NFC GVA, Core) | M1.2 (NFC GVA, Infra) | M1.3 (Corp GVA, Core) | M1.4 (Corp GVA, Infra) | M1.5 (ST Tier 2, Core) | M1.6 (ST Tier 2, Infra) |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Capital Stock** | $k^{\text{cap}}_1$ | $k^{\text{cap}}_2$ | $k^{\text{cap}}_1$ | $k^{\text{cap}}_2$ | $k^{\text{cap}}_1$ | $k^{\text{cap}}_2$ |
| **Demand Control** | None | None | None | None | None | None |
| $\hat{\theta}_0$ (Capital Elasticity) | 6.466*** <br> *(20.52)* | 6.288*** <br> *(19.90)* | 6.469*** <br> *(20.13)* | 6.283*** <br> *(19.49)* | 7.635*** <br> *(12.32)* | 7.511*** <br> *(11.65)* |
| $\hat{\theta}_1$ (Interaction) | 0.589*** <br> *(25.87)* | 0.590*** <br> *(26.35)* | 0.588*** <br> *(24.84)* | 0.591*** <br> *(25.34)* | 0.479*** <br> *(8.92)* | 0.479*** <br> *(8.76)* |
| **VIF ($k^{\text{cap}}$)** | 1.38 | 1.40 | 1.54 | 1.56 | 8.04 | 8.14 |
| **VIF (Interaction)** | 1.38 | 1.40 | 1.54 | 1.56 | 8.04 | 8.14 |
| **Resid. ADF ($t_{\text{ADF}}$)** | -4.108** | -4.172** | -4.062** | -4.136** | -3.647* | -3.410 |
| **Shin LM ($C_{\text{Shin}}$)** | 2.528*** | 2.556*** | 2.529*** | 2.552*** | 0.865*** | 1.043*** |
| **VW Type 2 ($S_{\text{Type 2}}$)** | 4.198 | 4.718 | 4.799 | 5.178 | 862.944*** | 813.219*** |
| **Residual Break Audit** | FAIL (4 breaks) | FAIL (3 breaks) | FAIL (4 breaks) | FAIL (4 breaks) | FAIL (4 breaks) | FAIL (4 breaks) |
| $R^2_{\text{sum}}$ | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| **Sample Size ($N$)** | 94 | 94 | 94 | 94 | 94 | 94 |

*Note: Estimated via Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014) over 1929–2024. Fixed-b HAR t-statistics reported in parentheses. \*p<0.10, \*\*p<0.05, \*\*\*p<0.01. Star Reversal Warning: For Residual ADF, stars indicate rejection of No Cointegration (supporting cointegration). For Shin LM and VW Type 2, stars indicate rejection of Cointegration. Distributional variables are centered at 1929 initial state ($t_0$). Bai-Perron residual break audit uses 15% trimming.*

---

## Section 2: Specification Set 2 — Triple Interactions ($k^{\text{cap}} \cdot \omega_{t-1} \cdot \iota_{t-1}$)

### Table 2A: Specification Set 2 (Part A: Baseline NFC & Corporate GVA Wage Shares) Triple Interaction IM-OLS Cointegration Estimates

| Metric / Parameter | M2.1 | M2.2 | M2.3 | M2.4 | M2.5 | M2.6 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Wage Share** | Baseline NFC | Baseline NFC | Baseline NFC | Baseline NFC | Corporate GVA | Corporate GVA |
| **Capital Stock** | $k^{\text{cap}}_1$ | $k^{\text{cap}}_1$ | $k^{\text{cap}}_2$ | $k^{\text{cap}}_2$ | $k^{\text{cap}}_1$ | $k^{\text{cap}}_1$ |
| **Demand Control** | None | NetC Share | None | NetC Share | None | NetC Share |
| $\hat{\theta}_0$ (Capital Elasticity) | 6.478*** <br> *(18.02)* | 9.108*** <br> *(11.76)* | 6.284*** <br> *(17.62)* | 8.871*** <br> *(11.52)* | 6.468*** <br> *(17.32)* | 9.146*** <br> *(11.70)* |
| $\hat{\theta}_1$ (Interaction) | 0.588*** <br> *(22.58)* | 0.524*** <br> *(19.60)* | 0.591*** <br> *(23.29)* | 0.528*** <br> *(20.07)* | 0.588*** <br> *(21.52)* | 0.522*** <br> *(18.80)* |
| $\hat{\beta}_{\text{cm}}$ ($\text{NetC}^{\text{share}}$) | --- | -0.330 <br> *(-0.46)* | --- | 0.021 <br> *(0.03)* | --- | -0.257 <br> *(-0.38)* |
| **VIF ($k^{\text{cap}}$)** | 1.57 | 2.54 | 1.59 | 2.61 | 1.74 | 2.79 |
| **VIF (Interaction)** | 1.57 | 1.63 | 1.59 | 1.67 | 1.74 | 1.82 |
| **Resid. ADF ($t_{\text{ADF}}$)** | -4.442*** | -1.103 | -4.483*** | -1.126 | -4.396*** | -1.117 |
| **Shin LM ($C_{\text{Shin}}$)** | 2.686*** | 2.041*** | 2.794*** | 2.132*** | 2.684*** | 2.030*** |
| **VW Type 2 ($S_{\text{Type 2}}$)** | 688.885*** | 14193.901*** | 738.308*** | 18368.239*** | 1146.521*** | 13834.554*** |
| **Residual Break Audit** | FAIL (3 breaks) | FAIL (4 breaks) | FAIL (3 breaks) | FAIL (4 breaks) | FAIL (3 breaks) | FAIL (4 breaks) |
| $R^2_{\text{sum}}$ | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| **Sample Size ($N$)** | 94 | 94 | 94 | 94 | 94 | 94 |

---

### Table 2B: Specification Set 2 (Part B: Corporate GVA & Shaikh-Tonak Tier 2 Wage Shares) Triple Interaction IM-OLS Cointegration Estimates

| Metric / Parameter | M2.7 | M2.8 | M2.9 | M2.10 | M2.11 | M2.12 |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Wage Share** | Corporate GVA | Corporate GVA | ST Tier 2 | ST Tier 2 | ST Tier 2 | ST Tier 2 |
| **Capital Stock** | $k^{\text{cap}}_2$ | $k^{\text{cap}}_2$ | $k^{\text{cap}}_1$ | $k^{\text{cap}}_1$ | $k^{\text{cap}}_2$ | $k^{\text{cap}}_2$ |
| **Demand Control** | None | NetC Share | None | NetC Share | None | NetC Share |
| $\hat{\theta}_0$ (Capital Elasticity) | 6.264*** <br> *(16.88)* | 8.895*** <br> *(11.39)* | 6.397*** <br> *(9.12)* | 10.054*** <br> *(10.73)* | 6.047*** <br> *(8.32)* | 9.687*** <br> *(9.62)* |
| $\hat{\theta}_1$ (Interaction) | 0.592*** <br> *(22.20)* | 0.527*** <br> *(19.21)* | 0.595*** <br> *(10.47)* | 0.474*** <br> *(10.26)* | 0.610*** <br> *(10.58)* | 0.490*** <br> *(9.93)* |
| $\hat{\beta}_{\text{cm}}$ ($\text{NetC}^{\text{share}}$) | --- | 0.071 <br> *(0.11)* | --- | -0.799 <br> *(-1.19)* | --- | -0.429 <br> *(-0.61)* |
| **VIF ($k^{\text{cap}}$)** | 1.78 | 2.88 | 6.76 | 9.56 | 7.09 | 10.32 |
| **VIF (Interaction)** | 1.78 | 1.87 | 6.76 | 7.53 | 7.09 | 8.07 |
| **Resid. ADF ($t_{\text{ADF}}$)** | -4.425*** | -1.141 | -4.578*** | -1.041 | -4.325*** | -1.100 |
| **Shin LM ($C_{\text{Shin}}$)** | 2.784*** | 2.104*** | 2.833*** | 1.886*** | 2.818*** | 1.812*** |
| **VW Type 2 ($S_{\text{Type 2}}$)** | 1133.728*** | 17651.223*** | 3622.814*** | 5439.993*** | 3433.373*** | 11691.106*** |
| **Residual Break Audit** | FAIL (3 breaks) | FAIL (4 breaks) | FAIL (3 breaks) | FAIL (5 breaks) | FAIL (3 breaks) | FAIL (5 breaks) |
| $R^2_{\text{sum}}$ | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| **Sample Size ($N$)** | 94 | 94 | 94 | 94 | 94 | 94 |

*Note: Estimated via Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014) over 1929–2024. Fixed-b HAR t-statistics reported in parentheses. \*p<0.10, \*\*p<0.05, \*\*\*p<0.01. Star Reversal Warning: For Residual ADF, stars indicate rejection of No Cointegration (supporting cointegration). For Shin LM and VW Type 2, stars indicate rejection of Cointegration. Distributional variables are centered at 1929 initial state ($t_0$). Bai-Perron residual break audit uses 15% trimming.*
