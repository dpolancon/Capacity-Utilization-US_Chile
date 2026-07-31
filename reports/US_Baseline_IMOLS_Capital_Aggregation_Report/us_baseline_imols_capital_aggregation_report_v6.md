# DISSERTATION PROGRESS REPORT & ONLINE APPENDIX
## Chapter 2: Empirical Grounding, Capacity Reconstruction, and the Overaccumulation Regime (Specification A)

**Author:** Diego Polanco (Department of Economics, UMass Amherst)  
**Advisor:** Michael Ash  
**Date:** July 2026  
**Compiled Artifact:** `us_baseline_imols_capital_aggregation_report_v6.pdf`  
**Supersedes:** `us_baseline_imols_capital_aggregation_report_v5.pdf` (retained unmodified)

---

## Executive Summary

This progress report provides the complete, paper-facing empirical appendix for **Specification A (Single Aggregate Capital Model)** of Chapter 2. I evaluate the full range of 168 estimated IM-OLS cointegrating regressions across four master comparative matrices comparing specifications **With Step Controls ($\boldsymbol{\Lambda}\mathbf{D}_t' = \text{Yes}$)** against **Without Step Controls ($\boldsymbol{\Lambda}\mathbf{D}_t' = \text{No}$)**:
1. **Full Sample Baseline Matrix (1929–2024)** across Centering Treatments;
2. **Accumulation Eras Comparative Matrix** comparing Fordism (1929–1973) vs. Post-Fordism (1974–2024);
3. **Multi-Wage Share Robustness Matrix** comparing Baseline NFC GVA, Corporate GVA, Shaikh-Tonak Tier 1, and Shaikh-Tonak Tier 2 wage measures; and
4. **Macroeconomic Sub-Window Diagnostic Matrix** evaluating Interwar & WWII, Golden Age, Neoliberal Restructuring, and Post-GFC Stagnation subwindows.

**What v6 adds.** Version 5 estimated these cointegrating relations without a formal, break-aware integration-order pre-testing stage: the integration order of $k_t^{\text{cap}}$ was assumed rather than established, and the step-control dates were imposed rather than located. Version 6 closes that gap. Section 2.0 reports the binding S0\* sequence — Bai-Perron sequential break search on stationary first differences, Lee-Strazicich Minimum-LM unit root verification under broken deterministics, then break-interacted IM-OLS — executed fresh under the protocol notes locked on 2026-07-30. The v5 matrices in Section 2 are reproduced unchanged; the new Table X in Section 2.0 reports the internal slope-break estimation that the pre-testing licenses.

---

## 1. Methodological Setup & Data Boundaries

In Chapter 2's theoretical framework, productive capacity ($Y^p_t$) is not a neutral physical constant. It reflects historical capital accumulation conditioned by distributional conflict between labor and capital.

### Sectoral Boundaries and Sample Limits
- **Observed Aggregate Output ($Y_t$)**: We measure aggregate output using *Total Corporate Gross Value Added* ($Y_{\text{CORP}}$) or aggregate real output ($Y_t$) from NIPA accounts, capturing aggregate demand realization across corporate capitalism.
- **Productive Capital Stock ($K^{\text{cap}}$) and Capacity ($Y^p_t$)**: We construct productive capital strictly from *Non-Financial Corporate* (NFC) fixed assets ($K_{\text{NFC}}^{\text{ME}} + K_{\text{NFC}}^{\text{NRC}}$). This isolates physical plant structures and equipment in non-financial production from financial sector asset noise.
- **Estimation Sample (1929–2024)**: BEA Fixed Assets capital stock series ($K^{\text{ME}}, K^{\text{NRC}}, K^{\text{cap}}$) span 1925–2025 (101 years). However, BEA NIPA Table 1.14 corporate value added ($y_t^{\text{NFC}}$) and distribution ($\omega_{t-1}$) begin in 1929. Consequently, our estimation sample covers **1929–2024 ($T = 94$ years)**.

---

## 2. Empirical Results Matrix & Robustness

We estimate the baseline single-aggregate capital specification:
$$y_t^{\text{NFC}} = \alpha + \beta_{\text{Kcap}} k_t^{\text{cap}} + \phi_{\omega} \omega_{t-1} + \theta_1 (k_t^{\text{cap}} \cdot \omega_{t-1}) + \boldsymbol{\Lambda} \mathbf{D}_t' + u_t$$
using Integrated Modified OLS (IM-OLS; Vogelsang & Wagner 2014) with Fixed-$b$ HAR inference.

### 2.0 Break-Aware Integration-Order Pre-Testing (S0\* Protocol)

The estimates in Section 2 rest on two claims that v5 asserted rather than tested: that $k_t^{\text{cap}}$ is $I(1)$, and that the step-control dates mark real structural breaks. The S0\* protocol notes locked on 2026-07-30 make both testable, in a fixed order — Bai-Perron locates candidate breaks on stationary first differences, Lee-Strazicich verifies integration order under broken deterministics, and only then does break-interacted IM-OLS run. That sequence was executed fresh for this version; the ledgers are under `output/US/BREAK_AWARE_IMOLS/`.

One framing point governs everything below. **The split samples are historical, not estimated.** Fordism runs to 1973 and Post-Fordism from 1974, and no break test is permitted to revise that periodization. What the break tests locate are *within-sample* structural breaks — the Depression, war mobilization, the Volcker disinflation — that must be controlled for the estimation to be adequate. A Bai-Perron date landing in 1942 is a statement about war production, not a rival account of when Fordism began.

**Step 1 — Bai-Perron (1998, 2003).** The sequential search ran on the stationary first-differenced vector $\Delta\mathbf{Y}_t = [\Delta y_t, \Delta k_t^{\text{cap}}, \Delta\omega_t]'$, never on levels, within each sub-sample separately: Fordist trimming $\epsilon = 0.20$, Post-Fordist $\epsilon = 0.15$, maximum three breaks. Breaks are admitted only when UDmax rejects at 5% *and* the sequential $\sup F_T(l+1|l)$ rejects, which is stricter than reading the selected break count off the estimator. Inside Fordism the procedure locates a single break at **1939** in the capital growth rate (95% CI 1932–1955) and at **1942** in the differenced relation (95% CI 1938–1949); $\Delta y_t$ and $\Delta\omega_t$ carry no breaks at all. Inside Post-Fordism it locates **1981** (95% CI 1980–1983), **2000** (95% CI 1998–2004) and **2010** (95% CI 2005–2017). The protocol's Post-Fordist candidates are recovered almost exactly — 1982 at a distance of one year, 2000 exactly, 2008 within two. The Fordist candidates are not recovered as point estimates: 1933 sits six years from the nearest estimate and 1947 five. Both nonetheless fall inside the 95% confidence intervals of the Fordist break dates, so the honest statement is that the Fordist window contains one poorly-identified break somewhere between the Depression and the post-war conversion, not that 1947 is refuted. $WD_{\max}$ is listed in S03 §2A but is not exposed by `mbreaks` 1.0.1; it is recorded as unavailable rather than approximated.

**Step 2 — Lee-Strazicich (2003) Minimum-LM.** The test comes from the mandated external engine at `C:\ReposGitHub\LeeStrazicichUnitRoot`; no substitute was written. Two deviations are on the record and both matter for reading the numbers. First, `ur.ls()` locates breaks *endogenously* by grid-minimising the LM statistic and accepts no fixed-date argument, so the test could not be run "at the Bai-Perron dates" as S01 §2 Step 2 requests; it was run as designed and a date-concordance ledger reports the agreement separately. Second, and more consequentially, the S03 §2C decision matrix reads a *levels* rejection as evidence of $I(1)$ and a levels non-rejection as evidence of $I(2)$. That inverts the standard logic: an $I(1)$ series has a unit root in levels, so failing to reject in levels is exactly what it must do. Applied literally, the matrix classified $k_t^{\text{cap}}$ as an $I(2)$ risk in almost every window — a pre-testing stage diagnosing itself rather than the data. The discriminating test, and what S03 §2B says it wants when it speaks of "eliminating spurious $I(2)$ classification", is the LM test on the *first difference*. Both were run and the verdict is taken on the pair.

Read that way the evidence is clean. Under Model C, with breaks in intercept and trend under both hypotheses, $k_t^{\text{cap}}$ does not reject the unit root in levels ($LM = -3.62$ against a 5% value of $-5.67$ in Fordism) and rejects decisively in first differences ($LM = -7.38$): **$k_t^{\text{cap}}$ is $I(1)$ with breaks, not $I(2)$**, which is what the v5 estimation assumed and can now assert. The same verdict holds for $y_t^{\text{NFC}}$ in both eras and for $k_t^{\text{cap}}$ over the full sample. Two exceptions are genuine and are not smoothed over: $\omega_{t-1}$ rejects the unit root *in levels* over the full sample and within Fordism, making it trend-stationary around breaks rather than $I(1)$; and $k_t^{\text{cap}}$ likewise rejects in levels within Post-Fordism. Fourteen of eighteen variable-window cells clear the gate. Every Lee-Strazicich critical value is tabulated at $T = 100$ while these windows carry $T = 43$ and $T = 51$, so the test is over-sized in the sub-samples and the marginal cases should be read with that in mind.

**Step 3 — Break-interacted IM-OLS.** Because $\omega_{t-1}$ (Fordism) and $k_t^{\text{cap}}$ (Post-Fordism) do not clear the gate as $I(1)$, **both eras are estimated on the exploratory route, not the formal one.** Following the honesty standard used in the Chile S40/S50 chronology, estimation still runs and the label travels with every coefficient: nothing in Table X below is a formally gated result, and none of it should be quoted as one. The estimator remains IM-OLS under the E10V lock, with DOLS run only as a diagnostic comparator, and the interaction terms enter the design raw — the FWL prohibition is enforced structurally, not by assertion.

Two implementation notes belong in the record. The multiplicative slope shift is placed at the protocol dates $T_B^* = 1947$ (Fordism) and $T_B^* = 2008$ (Post-Fordism) exactly as S01 §5 pins them, while the Bai-Perron dates enter *additively* as step controls: a permanent step at 1933 for the New Deal regime change and a 1942–1945 block that switches back off for war mobilization, since war output is a level distortion that reverses rather than a permanent shift, plus permanent steps at 1981 and 2000 in Post-Fordism. And the uncentered design is numerically unusable here — the standardized condition number runs between 3054 and 8832 under Regime A against 12 to 79 under initial-state centering — so all reported estimates use **Regime B (initial-state centering)**, which is the AGENTS.md instruction to log the condition number and default to Regime B rather than block.

#### Table X: Sub-Sample Internal Slope Break Cointegration Matrix (IM-OLS)

*Dependent variable: log real non-financial gross value added ($y_t^{\text{NFC}}$). Fixed-$b$ HAR $t$-statistics in parentheses.*

| Parameter / Diagnostic | (1) Fordist, No Interaction | (2) Fordist, With Interaction | (3) Post-Fordist, No Interaction | (4) Post-Fordist, With Interaction |
|---|:---:|:---:|:---:|:---:|
| Internal Slope Interaction | No | Yes | No | Yes |
| Internal Break Date ($T_B^*$) | 1947 | 1947 | 2008 | 2008 |
| **Capital Stock ($\hat{\beta}_{\text{Kcap}}$)** | 0.82*** | 1.84*** | 0.85*** | 0.89*** |
| | (30.63) | (4.20) | (12.69) | (16.34) |
| **Capital Slope Shift ($\hat{\theta}_{K, \text{brk}}$)** | — | -0.98** | — | -0.14 |
| | | (-2.26) | | (-1.13) |
| **Wage Share ($\hat{\phi}_{\omega}$)** | -4.75* | -1.44 | -2.88 | -3.92 |
| | (-1.82) | (-0.84) | (-1.18) | (-1.27) |
| **Interaction Squeeze ($\hat{\theta}_1$)** | -1.52 | 3.46 | 2.82** | 1.63 |
| | (-0.99) | (0.23) | (2.39) | (1.01) |
| **Interaction Slope Shift ($\hat{\theta}_{\omega K, \text{brk}}$)** | — | -6.97 | — | -0.25 |
| | | (-0.48) | | (-0.33) |
| Step Dummies ($\mathbf{D}_t$) | Yes | Yes | Yes | Yes |
| **<u>Diagnostics</u>** | | | | |
| Residual Variance ($\hat{\sigma}_u$) | 0.096 | 0.058 | 0.074 | 0.044 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Cointegration] | 0.185*** | 0.031 | 0.330*** | 0.035 |
| Residual ADF ($t_{\text{ADF}}$) [$H_0$: No Cointegration] | -2.805 | -4.759** | -4.194* | -5.976*** |
| Sample Size ($T$) | 43 | 43 | 51 | 51 |
| **Break-Aware Gate Status** | Exploratory | Exploratory | Exploratory | Exploratory |
| Reported Centering Regime | Initial-State | Initial-State | Initial-State | Initial-State |

*Step controls: Fordism $\mathbf{D}_{1933}$ and war block $\mathbf{B}_{1942\text{--}1945}$; Post-Fordism $\mathbf{D}_{1981}$ and $\mathbf{D}_{2000}$. \* $p<0.10$, \*\* $p<0.05$, \*\*\* $p<0.01$.*

**Verdict on the S01 §3 decision matrix.** Inside Fordism the capital slope shift is significant ($\hat{\theta}_{K, \text{brk}} = -0.98$, $t = -2.26$), so the multiplicative interaction is retained and the elasticity must be reported as two sub-regimes rather than one: $\hat{\beta}_{\text{Kcap}}$ falls from **1.84 before 1947 to 0.86 after it**, a halving of the capacity-generating effect of aggregate capital across the post-war conversion. That estimate is exploratory, not formally gated, because $\omega_{t-1}$ is trend-stationary rather than $I(1)$ in this window. Inside Post-Fordism neither slope shift is significant ($\hat{\theta}_{K, \text{brk}} = -0.14$, $t = -1.13$; $\hat{\theta}_{\omega K, \text{brk}} = -0.25$, $t = -0.33$), so the S01 §3 "NO" branch applies: the capital elasticity is structurally invariant at $\hat{\beta}_{\text{Kcap}} = 0.89$ across 2008, and the step dummies are retained strictly for variance hygiene. The neoliberal era does not contain an internal slope break in aggregate capital; the Fordist era does.

**The break controls repair the cointegration diagnostics.** This is the strongest result of the pre-testing stage and it is a specification finding, not a point estimate. Without the interaction, the Shin LM statistic rejects the cointegration null in both eras ($C_{\text{Shin}} = 0.185^{***}$ in Fordism, $0.330^{***}$ in Post-Fordism) — the residuals carry non-stationary drift and the long-run relation is not clean. With the break interaction, both fall below the 10% critical value (0.031 and 0.035) and the residual ADF strengthens from $-2.81$ to $-4.76^{**}$ and from $-4.19^{*}$ to $-5.98^{***}$. Residual variance falls in parallel, from 0.096 to 0.058 and from 0.074 to 0.044, in both cases far below the S01 §2 Step 3 progress-report baselines of 0.158 and 0.184. The within-sample break structure was absorbing into the residual; once modelled, the cointegrating relation holds.

**On the preliminary evidence.** The LOESS-based and pairwise integration-order groundwork in `reports/US_Capital_Composition_Integrated_Report/us_capital_composition_integrated_report.pdf` motivated the candidate break dates used above and is cited only in that capacity. It does not satisfy the S0\* pre-testing requirement, and the Bai-Perron → Lee-Strazicich → IM-OLS sequence reported here was run fresh rather than inherited from it.

### Master Comparative Appendix Tables

*The four matrices below are reproduced unchanged from v5. They are estimated on the full-sample and era designs without the internal slope-break terms of Table X, and they remain the reference results for Specification A.*

#### Table A1: Full Sample Baseline IM-OLS Matrix (1929–2024, With vs. Without Dummies)

| Parameter / Diagnostic | (1) Uncentered (Yes) | (2) Uncentered (No) | (3) Initial-St (Yes) | (4) Initial-St (No) | (5) Sample-Mean (Yes) | (6) Sample-Mean (No) |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| **$\hat{\beta}_{\text{Kcap}}$** | 0.49 | -11.03 | 12.65*** | 12.57*** | 15.37*** | 14.70*** |
| | (0.08) | (-0.87) | (128.24) | (97.07) | (50.50) | (339.78) |
| **$\hat{\phi}_{\omega}$** | 1.21*** | 1.68** | 0.81*** | 0.61*** | 0.76*** | 0.59*** |
| | (3.05) | (2.11) | (19.15) | (30.41) | (20.42) | (30.20) |
| **$\hat{\theta}_{1}$** | 5.01 | 27.83 | -10.64*** | -10.16** | -3.16** | 0.24 |
| | (0.55) | (1.38) | (-3.70) | (-2.48) | (-2.37) | (0.09) |
| **$\boldsymbol{\Lambda} \mathbf{D}_t'$** | Yes | No | Yes | No | Yes | No |
| **<u>Cointegration Tests</u>** | | | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Cointegration] | 0.07 | 0.01 | 1.60*** | 0.01 | 0.26 | 0.04 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Cointegration] | -3.78 | -3.91** | -3.75 | -1.77 | -4.56** | -3.24 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Cointegration] | 0.12 | 2.05*** | 0.08 | 4.66*** | 0.16 | 2.35*** |
| **<u>Goodness-of-Fit & Controls</u>** | | | | | | |
| $R_{\text{level}}^2$ | 0.974 | 0.658 | 0.982 | 0.650 | 0.979 | 0.709 |
| $R_{\text{sum}}^2$ | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| $\hat{\sigma}_u$ | 0.185 | 0.655 | 0.155 | 0.662 | 0.164 | 0.604 |
| Sample Window | Full Sample | Full Sample | Full Sample | Full Sample | Full Sample | Full Sample |
| Sample Size ($T$) | 94 | 94 | 94 | 94 | 94 | 94 |

---

#### Table A2: Accumulation Eras Comparative Matrix (Fordism vs. Post-Fordism, With vs. Without Dummies)

| Parameter / Diagnostic | (1) Fordism Init-St (Yes) | (2) Fordism Init-St (No) | (3) Fordism Uncent (Yes) | (4) Fordism Uncent (No) | (5) Post-Fordism Init-St (Yes) | (6) Post-Fordism Init-St (No) | (7) Post-Fordism Uncent (Yes) | (8) Post-Fordism Uncent (No) |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **$\hat{\beta}_{\text{Kcap}}$** | 2.50*** | 2.50*** | 0.28 | 0.28 | 14.15*** | 14.28*** | -0.32 | -0.19 |
| | (21.57) | (21.57) | (0.05) | (0.05) | (155.07) | (81.65) | (-0.11) | (-0.07) |
| **$\hat{\phi}_{\omega}$** | 0.38* | 0.38* | 0.81 | 0.81 | -0.06 | -0.05 | -0.33 | -0.31 |
| | (1.81) | (1.81) | (1.49) | (1.49) | (-0.38) | (-0.32) | (-0.72) | (-0.66) |
| **$\hat{\theta}_{1}$** | -0.07 | -0.07 | -0.19 | -0.19 | -15.42*** | -15.65*** | 17.65 | 16.48 |
| | (-0.02) | (-0.02) | (-0.02) | (-0.02) | (-2.99) | (-2.78) | (0.83) | (0.76) |
| **$\boldsymbol{\Lambda} \mathbf{D}_t'$** | Yes | No | Yes | No | Yes | No | Yes | No |
| **<u>Cointegration Tests</u>** | | | | | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Cointegration] | 0.23 | 0.23 | 0.36 | 0.36 | 0.20 | 0.05 | 0.17 | 0.06 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Cointegration] | -4.43** | -4.43** | -4.43** | -4.43** | -4.68** | -4.68** | -4.68** | -4.68** |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Cointegration] | 0.09 | 0.09 | 0.09 | 0.09 | 0.10 | 0.10 | 0.10 | 0.10 |
| **<u>Goodness-of-Fit & Controls</u>** | | | | | | | | |
| $R_{\text{level}}^2$ | 0.974 | 0.974 | 0.974 | 0.974 | 0.985 | 0.985 | 0.985 | 0.985 |
| $R_{\text{sum}}^2$ | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| $\hat{\sigma}_u$ | 0.165 | 0.165 | 0.165 | 0.165 | 0.126 | 0.126 | 0.126 | 0.126 |
| Sample Size ($T$) | 44 | 44 | 44 | 44 | 50 | 50 | 50 | 50 |

---

#### Table A3: Multi-Wage Share Robustness Matrix (4 Wage Measures, With vs. Without Dummies)

| Parameter / Diagnostic | (1) NFC GVA (Yes) | (2) NFC GVA (No) | (3) Corp GVA (Yes) | (4) Corp GVA (No) | (5) ST Tier 1 (Yes) | (6) ST Tier 1 (No) | (7) ST Tier 2 (Yes) | (8) ST Tier 2 (No) |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **$\hat{\beta}_{\text{Kcap}}$** | 12.65*** | 12.57*** | 12.66*** | 12.55*** | 12.69*** | 12.65*** | 12.60*** | 12.74*** |
| | (128.24) | (97.07) | (130.83) | (95.83) | (133.88) | (125.19) | (148.15) | (170.08) |
| **$\hat{\phi}_{\omega}$** | 0.81*** | 0.61*** | 0.84*** | 0.62*** | 0.83*** | 0.62*** | 0.92*** | 0.59*** |
| | (19.15) | (30.41) | (18.92) | (29.47) | (20.21) | (42.32) | (13.53) | (9.62) |
| **$\hat{\theta}_{1}$** | -10.64*** | -10.16** | -11.37*** | -9.85*** | -5.40*** | -4.88*** | -3.33*** | -3.66*** |
| | (-3.70) | (-2.48) | (-4.03) | (-2.67) | (-3.46) | (-2.66) | (-3.14) | (-4.26) |
| **$\boldsymbol{\Lambda} \mathbf{D}_t'$** | Yes | No | Yes | No | Yes | No | Yes | No |
| **<u>Cointegration Tests</u>** | | | | | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Cointegration] | 1.60*** | 0.01 | 1.28*** | 0.02 | 0.23 | 0.03 | 0.43** | 0.01 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Cointegration] | -3.75 | -1.77 | -3.87* | -1.76 | -3.90* | -1.72 | -3.28 | -1.21 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Cointegration] | 0.08 | 4.66*** | 0.08 | 3.75*** | 0.10* | 3.11*** | 0.11* | 7.32*** |
| **<u>Goodness-of-Fit & Controls</u>** | | | | | | | | |
| $R_{\text{level}}^2$ | 0.982 | 0.650 | 0.983 | 0.679 | 0.984 | 0.733 | 0.984 | 0.821 |
| $R_{\text{sum}}^2$ | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| $\hat{\sigma}_u$ | 0.155 | 0.662 | 0.147 | 0.634 | 0.145 | 0.579 | 0.144 | 0.474 |
| Sample Size ($T$) | 94 | 94 | 94 | 94 | 94 | 94 | 94 | 94 |

---

#### Table A4: Specification A Macroeconomic Sub-Window Diagnostic Sensitivity Matrix (With vs. Without Dummies)

| Parameter / Diagnostic | (1) Interwar (Yes) | (2) Interwar (No) | (3) Golden Age (Yes) | (4) Golden Age (No) | (5) Neoliberal (Yes) | (6) Neoliberal (No) | (7) Post-GFC (Yes) | (8) Post-GFC (No) |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **$\hat{\beta}_{\text{Kcap}}$** | 2.05** | 2.05** | 2.50*** | 2.50*** | 1.95*** | 1.95*** | 0.74*** | 0.74*** |
| | (2.29) | (2.29) | (21.57) | (21.57) | (9.48) | (9.48) | (3.78) | (3.78) |
| **$\hat{\phi}_{\omega}$** | 0.69 | 0.69 | 0.38* | 0.38* | -0.10 | -0.10 | 0.08 | 0.08 |
| | (0.83) | (0.83) | (1.81) | (1.81) | (-0.46) | (-0.46) | (0.33) | (0.33) |
| **$\hat{\theta}_{1}$** | -12.43 | -12.43 | -0.07 | -0.07 | -15.26 | -15.26 | 0.09 | 0.09 |
| | (-1.08) | (-1.08) | (-0.02) | (-0.02) | (-0.97) | (-0.97) | (0.01) | (0.01) |
| **$\boldsymbol{\Lambda} \mathbf{D}_t'$** | Yes | No | Yes | No | Yes | No | Yes | No |
| **<u>Cointegration Tests</u>** | | | | | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Cointegration] | 0.05 | 0.05 | 0.23 | 0.23 | 0.17 | 0.17 | 0.12 | 0.12 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Cointegration] | -3.11 | -3.11 | -4.43** | -4.43** | -4.68** | -4.68** | -2.85 | -2.85 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Cointegration] | 0.10 | 0.10 | 0.09 | 0.09 | 0.10 | 0.10 | 0.12 | 0.12 |
| **<u>Goodness-of-Fit & Controls</u>** | | | | | | | | |
| $R_{\text{level}}^2$ | 0.941 | 0.941 | 0.974 | 0.974 | 0.985 | 0.985 | 0.962 | 0.962 |
| $R_{\text{sum}}^2$ | 0.995 | 0.995 | 0.998 | 0.998 | 0.999 | 0.999 | 0.996 | 0.996 |
| $\hat{\sigma}_u$ | 0.218 | 0.218 | 0.165 | 0.165 | 0.126 | 0.126 | 0.084 | 0.084 |
| Sample Size ($T$) | 17 | 17 | 44 | 44 | 50 | 50 | 15 | 15 |

---

## 3. Summary of Key Empirical Findings & Takeaways

The empirical estimations establish four key findings for the dissertation committee:

1. **State-Dependent Profit Squeeze Stability**: Under Initial-State centering, the interaction parameter $\hat{\theta}_1$ remains negative and statistically significant ($\hat{\theta}_1 = -10.64^{***}$ with step controls vs. $-10.16^{**}$ without step controls). Higher wage shares suppress the capacity-generating effect of capital accumulation.
2. **Variance Reduction and Cointegration Hygiene**: Step controls ($\mathbf{D}_{1933}, \mathbf{D}_{1947}, \mathbf{D}_{1974}, \mathbf{D}_{2008}$) leave point estimates stable while reducing residual variance ($\hat{\sigma}_u$ drops from 0.662 to 0.155) and eliminating non-stationary residual drift ($C_{\text{Shin}}$ drops from 4.657 to 0.082).
3. **Capacity Utilization Level Reconstruction**: Anchoring level scale at $t^* = 1973$ ($\mu_{1973} = 1.00$) recovers an empirically consistent utilization path ($\hat{\mu}_t$). Utilization peaks during WWII mobilization ($\hat{\mu}_{1944} \approx 1.15$), remains stable during post-war Fordism ($\hat{\mu} \in [0.90, 1.00]$), and experiences a secular decline under neoliberalism, reaching a trough during the Great Recession ($\hat{\mu}_{2009} \approx 0.70$).
4. **Persistent Capital Overaccumulation Regime**: The total transformation elasticity $\theta_t = \hat{\beta}_{\text{Kcap}} + \hat{\theta}_1 \omega_{t-1}$ remains bounded strictly below 1.00 throughout 1929–2024 ($\theta_t \in [0.65, 0.95]$). The U.S. capitalist economy has operated within a structural overaccumulation regime ($\theta_t < 1.0$) for nearly a century.

Version 6 adds two further findings from the break-aware pre-testing stage:

5. **The Capital Stock Is $I(1)$ With Breaks, Not $I(2)$**: The Lee-Strazicich Minimum-LM test under broken deterministics does not reject a unit root in the levels of $k_t^{\text{cap}}$ and rejects decisively in first differences ($LM = -7.38$ in Fordism, $-6.94$ over the full sample). The integration order that v5 assumed is now established, and the spurious $I(2)$ reading that broken deterministic trends can produce is ruled out. Two variables fail this gate — $\omega_{t-1}$ is trend-stationary around breaks in Fordism and over the full sample, and $k_t^{\text{cap}}$ is trend-stationary within Post-Fordism — which is why every Table X estimate is reported on the exploratory route rather than as a formally gated result.
6. **Fordism Contains an Internal Slope Break; Post-Fordism Does Not**: The capital slope shift at 1947 is significant ($\hat{\theta}_{K, \text{brk}} = -0.98$, $t = -2.26$) and halves the aggregate capital elasticity from 1.84 to 0.86 across the post-war conversion, so the S01 §3 decision matrix retains the multiplicative interaction and the Fordist elasticity must be reported as two sub-regimes. Neither slope shift is significant at 2008, so the Post-Fordist elasticity is structurally invariant at 0.89 and its step dummies serve variance hygiene alone. Modelling the within-sample break structure repairs the cointegration diagnostics in both eras: $C_{\text{Shin}}$ falls from $0.185^{***}$ to 0.031 in Fordism and from $0.330^{***}$ to 0.035 in Post-Fordism, and the residual ADF strengthens to $-4.76^{**}$ and $-5.98^{***}$ respectively.

---

## Reproduction

All Section 2.0 results are generated by the `US_S33*` family and can be reproduced end to end:

```bash
Rscript codes/US_S33A_bai_perron_split_sample_prescan.R
```

```bash
Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R
```

```bash
Rscript codes/US_S33C_break_interacted_imols_specA.R
```

Ledgers: `output/US/BREAK_AWARE_IMOLS/S33A_BAI_PERRON/csv/`, `.../S33B_LEE_STRAZICICH/csv/`, `.../S33C_IMOLS_SPEC_A/csv/`. Each stage writes a stage-integrity ledger and halts if any check fails, so a completed run is self-certifying. Handoff note: `chapter2_vault/80_Prompts/handoffs/2026-07-30_us_breakaware_imols_handoff.md`.
