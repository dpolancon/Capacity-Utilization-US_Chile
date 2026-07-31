# DISSERTATION PROGRESS REPORT & ONLINE APPENDIX
## Chapter 2: Disaggregating Plant Scale, Mechanization Choice, and Relative Capital Prices (Specification B)

**Author:** Diego Polanco (Department of Economics, UMass Amherst)  
**Advisor:** Michael Ash  
**Date:** July 2026  
**Compiled Artifact:** `us_specB_imols_capital_disaggregation_report_v7.pdf`  
**Supersedes:** `us_specB_imols_capital_disaggregation_report_v6.pdf` (retained unmodified)

---

## Executive Summary

This progress report provides the complete, paper-facing empirical appendix for **Specification B (Capital Disaggregation Model)** of Chapter 2. By unbundling aggregate productive capital into extensive nonresidential plant structures ($K^{\text{NRC}}$) and intensive machinery ($K^{\text{ME}}$), Specification B provides structural identification of the technical choice mechanism ($\kappa_t = k^{\text{ME}}_t - k^{\text{NRC}}_t$), relative asset price dynamics ($p_t^{\kappa} = \ln P^{\text{ME}}_t - \ln P^{\text{NRC}}_t$), and class distribution ($\omega_{t-1}$). We evaluate the full range of 505 IM-OLS cointegrating regressions across four master comparative matrices comparing specifications **With Step Controls ($\boldsymbol{\gamma}'\mathbf{D}_t = \text{Yes}$)** against **Without Step Controls ($\boldsymbol{\gamma}'\mathbf{D}_t = \text{No}$)**.

Core empirical findings carried forward from v6: (1) class distribution conditions mechanization choice ($\hat{\theta}_{\omega \kappa} = 15.40^{***}$ under initial-state centering with step controls); (2) step controls eliminate residual non-stationarity ($C_{\text{Shin}}$ drops from 0.261 to 0.042); (3) reconstructed capacity utilization ($\hat{\mu}_t^{\text{SpecB}}$) anchored at $\mu_{1973} = 1.00$ recovers a 50 percentage point post-2000 industrial stagnation gap relative to aggregate Specification A; and (4) the total transformation elasticity ($\theta_t^{\text{SpecB}} < 1.0$) confirms persistent capital overaccumulation throughout post-war capitalism.

**What v7 adds.** Version 6 estimated the disaggregated cointegrating relations without a formal, break-aware integration-order pre-testing stage: the $I(1)$ status of $k_t^{\text{NRC}}$ and $\kappa_t$ was assumed, and the step-control dates were imported from LOESS inflections rather than located by a formal break test. Version 7 closes that gap. Section 2.5 reports the binding S0\* sequence — Bai-Perron on stationary first differences, Lee-Strazicich Minimum-LM verification under broken deterministics, then break-interacted IM-OLS — executed fresh under the protocol notes locked on 2026-07-30, and adds the Table 3.2 internal slope-break matrix. The v6 results in Sections 3–5 are reproduced unchanged.

---

## 1. Methodological Setup & Disaggregation Architecture

National accounting consistency requires strict clarity regarding sectoral boundaries in capital disaggregation:

- **Observed Aggregate Output ($Y_t$)**: Measured via *Total Corporate Gross Value Added* ($Y_{\text{CORP}}$) or aggregate real output ($Y_t$) from NIPA accounts, capturing aggregate demand realization across corporate capitalism.
- **Productive Capital Disaggregation ($K_{\text{NFC}}^{\text{NRC}}$ and $K_{\text{NFC}}^{\text{ME}}$)**: We unbundle non-financial corporate productive fixed assets into nonresidential structures ($K_{\text{NFC}}^{\text{NRC}}$), representing sunk extensive plant scale, and machinery and equipment ($K_{\text{NFC}}^{\text{ME}}$), representing intensive mechanization technology choice.
- **Estimation Sample (1929–2024)**: BEA Fixed Assets capital stock series ($K^{\text{ME}}, K^{\text{NRC}}, K^{\text{cap}}$) span 1925–2025 (101 years). However, corporate value added ($y_t^{\text{NFC}}$) and distribution ($\omega_{t-1}$) begin in 1929, establishing an estimation sample of **1929–2024 ($T = 94$ years)**.

Figure 1 (`output/figures/fig_specB_3panel_structural_decomposition.png`) plots the raw historical trajectories of nonresidential structures ($k^{\text{NRC}}$), machinery ($k^{\text{ME}}$), capital composition residual ($\kappa_t$), and relative equipment-to-structure deflator trends ($p_t^{\kappa}$).

A non-parametric LOESS trend of $\ln K^{\text{cap}}$ reveals structural inflections used in v6 to construct step dummy controls ($\boldsymbol{\gamma}' \mathbf{D}_t = [D_{1933}, D_{1947}, D_{1974}, D_{2008}]'$), capturing the New Deal mobilization, Fordist expansion, late-Fordist profit squeeze, and post-GFC stagnation. **Section 2.5 replaces the LOESS provenance of these dates with formal Bai-Perron evidence**, which is the substantive change in this version.

---

## 2. Specification Taxonomy & Cointegration Hierarchy

We establish a nested three-tier cointegration hierarchy for Specification B to test the marginal contributions of relative prices and distributional interaction.

**Specification B1 — Linear Uninteracted Baseline.** Unbundles plant scale from capital composition without interaction terms:
$$y_t^{\text{NFC}} = \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \theta_{\kappa} \kappa_t + \beta_{p^{\kappa}} p_t^{\kappa} + \beta_{\omega} \omega_{t-1} + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$

**Specification B2 — Distributionally Interacted Mechanization Model.** Introduces state-dependent distribution conditioning on mechanization choice:
$$y_t^{\text{NFC}} = \text{B1} + \theta_{\omega \kappa} (\kappa_t \cdot \omega_{t-1}) + u_t$$

**Specification B3 — Canonical Fully Interacted Model.** Incorporates relative capital asset price conditioning on mechanization choice:
$$y_t^{\text{NFC}} = \text{B2} + \theta_{\kappa p^{\kappa}} (\kappa_t \cdot p_t^{\kappa}) + u_t$$

**Specification B4 — Pure Distribution/Price-Conditioned Model.** Drops the standalone level of the mechanization gap, retaining it only through its two interaction channels:
$$y_t^{\text{NFC}} = \alpha + \theta_{\text{NRC}} k_t^{\text{NRC}} + \beta_{p^{\kappa}} p_t^{\kappa} + \beta_{\omega} \omega_{t-1} + \theta_{\omega \kappa} (\kappa_t \cdot \omega_{t-1}) + \theta_{\kappa p^{\kappa}} (\kappa_t \cdot p_t^{\kappa}) + \boldsymbol{\gamma}' \mathbf{D}_t + u_t$$

B4 departs from the S02 taxonomy and is motivated on two grounds. **Theoretically**, in Marxian choice-of-technique models (Okishio 1961; Foley & Michl 1999; Shaikh 2016) capitalists do not raise the machinery-to-structures ratio out of a distribution-neutral propensity to mechanize: technical choice is driven by distributional conflict and by relative asset prices. On that reading $\kappa_t$ enters productive capacity as a *state-dependent channel*, not as an autonomous physical level, and the standalone term has no behavioural referent. The standard objection — that omitting a main effect while retaining its interaction induces omitted-variable bias — presumes the main effect is a primitive of the data-generating process, which is exactly what the Marxian reading denies. **Econometrically**, in a cointegrated system estimated in log-levels the standalone level and its own cross-products are close to parallel, and carrying both forces the estimator to separate near-collinear columns. §2.5 reports what that costs and what dropping it recovers.

Each specification is evaluated both With and Without Step Controls across Initial-State, Uncentered, and Sample-Mean normalizations. Adding distributional interaction ($\hat{\theta}_{\omega \kappa} = 15.40^{***}$) confirms that labor share conditions mechanization, while step controls eliminate residual non-stationarity ($C_{\text{Shin}}$ drops from 0.261 to 0.042).

### Table 2.1: Specification B Model Taxonomy Comparison Matrix (Initial-State Centering)

| Parameter / Diagnostic | (1) B1 (Yes) | (2) B1 (No) | (3) B2 (Yes) | (4) B2 (No) | (5) B3 (Yes) | (6) B3 (No) |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| **$\hat{\theta}_{\text{NRC}}$** | 0.57*** | 0.45*** | 0.36*** | 0.43*** | 0.33*** | 0.43*** |
| | (10.18) | (9.35) | (4.14) | (8.58) | (4.62) | (11.16) |
| **$\hat{\theta}_{\kappa}$** | -3.77 | -6.42 | -10.20*** | -5.58 | -7.14*** | -1.99 |
| | (-1.27) | (-1.26) | (-3.27) | (-1.15) | (-2.59) | (-0.43) |
| **$\hat{\beta}_{p^{\kappa}}$** | — | — | -0.41* | 0.04 | -1.17*** | -0.48 |
| | | | (-1.93) | (0.19) | (-3.00) | (-0.98) |
| **$\hat{\beta}_{\omega}$** | 0.14 | -1.05 | 9.53** | -0.42 | 8.11** | -3.09 |
| | (0.04) | (-0.16) | (2.30) | (-0.06) | (2.32) | (-0.55) |
| **$\hat{\theta}_{\omega \kappa}$** | 7.36 | 11.74 | 18.49*** | 10.27 | 15.40*** | 5.74 |
| | (1.55) | (1.48) | (3.62) | (1.32) | (3.63) | (0.84) |
| **$\hat{\theta}_{\kappa p^{\kappa}}$** | — | — | — | — | -1.14** | -0.78 |
| | | | | | (-2.21) | (-1.13) |
| **$\boldsymbol{\gamma}' \mathbf{D}_t$** | Yes | No | Yes | No | Yes | No |
| **<u>Cointegration Tests</u>** | | | | | | |
| VW Type 2 ($\lambda_2 = 0$) [$H_0$: Coint] | 1.7756 | 0.3068 | 1.4789 | 1.0635 | 2.1825 | 0.2893 |
| Resid. ADF ($t_{\text{ADF}}$) [$H_0$: No Coint] | -6.32*** | -1.69 | -6.46*** | -3.84 | -6.32*** | -2.97 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Coint] | 0.089 | 4.931 | 0.032 | 0.244 | 0.042 | 0.261 |
| **<u>Goodness-of-Fit & Controls</u>** | | | | | | |
| $R_{\text{level}}^2$ | 0.979 | 0.805 | 0.989 | 0.967 | 0.991 | 0.969 |
| $R_{\text{sum}}^2$ | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| $\hat{\sigma}_u$ | 0.166 | 0.497 | 0.125 | 0.205 | 0.112 | 0.200 |
| Sample Size ($T$) | 94 | 94 | 94 | 94 | 94 | 94 |

*Star reversal warning: for the Residual ADF test, stars indicate rejection of no-cointegration (supporting cointegration). For VW Type 2 and Shin LM, stars indicate rejection of cointegration (indicating non-stationarity). \* $p<0.10$, \*\* $p<0.05$, \*\*\* $p<0.01$.*

---

## 2.5 Break-Aware Integration-Order Pre-Testing (S0\* Protocol)

The estimates in Sections 2 and 3 rest on two claims that v6 asserted rather than tested: that $k_t^{\text{NRC}}$ and $\kappa_t$ are $I(1)$, and that the step-control dates mark real structural breaks rather than LOESS curvature. The S0\* protocol notes locked on 2026-07-30 make both testable in a fixed order — Bai-Perron, then Lee-Strazicich, then break-interacted IM-OLS. That sequence was executed fresh for this version; the ledgers are under `output/US/BREAK_AWARE_IMOLS/`.

**The split samples are historical, not estimated.** Fordism runs to 1973 and Post-Fordism from 1974, and no break test revises that periodization. What the break tests locate are *within-sample* structural breaks — the Depression, war mobilization, the Volcker disinflation — that must be controlled for the estimation to be adequate.

**Stage 2A — Bai-Perron (1998, 2003).** The sequential search ran on the stationary five-variable differenced vector $\Delta\mathbf{Y}_t = [\Delta y_t, \Delta k_t^{\text{NRC}}, \Delta\kappa_t, \Delta\omega_t, \Delta p_t^{\kappa}]'$, never on levels, with full-sample trimming $\epsilon = 0.15$ and up to five breaks, and sub-sample trimming $\epsilon = 0.20$ (Fordist) and $0.15$ (Post-Fordist) with up to three. Breaks are admitted only when UDmax rejects at 5% *and* the sequential $\sup F_T(l+1|l)$ rejects. Over the full sample the procedure locates breaks at **1945, 1995 and 2008** in the relative price series $\Delta p_t^{\kappa}$; inside Fordism at **1945** ($\Delta p_t^{\kappa}$) and **1943** in the differenced relation; inside Post-Fordism at **1981** ($\Delta k_t^{\text{NRC}}$), **1992** ($\Delta p_t^{\kappa}$), and **1980, 1990, 1998** in the differenced relation. $\Delta y_t$, $\Delta\kappa_t$ and $\Delta\omega_t$ carry no growth-rate breaks at all.

Measured against the S02 Stage 2A candidates, the record is mixed and is reported as such: **1947 and 2008 are recovered** (distances of two years and zero), **1933, 1968 and 1982 are not** (distances of ten, twenty-three and thirteen). The mechanization gap $\kappa_t$ itself is the quietest series in the system — its growth rate contains no detectable break in any window — so the breaks the LOESS diagnosis attributed to capital composition are, on formal testing, breaks in the *relative price* series instead. $WD_{\max}$ is named in S03 §2A but is not exposed by `mbreaks` 1.0.1; it is recorded as unavailable rather than approximated.

**Stage 2B — Lee-Strazicich (2003) Minimum-LM.** The test comes from the mandated external engine at `C:\ReposGitHub\LeeStrazicichUnitRoot`; no substitute was written. Two deviations are on the record. First, `ur.ls()` locates breaks *endogenously* and accepts no fixed-date argument, so the test could not be run "at the Bai-Perron dates" as S02 Stage 2B requests; it was run as designed and a date-concordance ledger reports the agreement separately. Second, the S03 §2C decision matrix reads a *levels* non-rejection as evidence of $I(2)$ — which inverts the standard logic, since an $I(1)$ series must fail to reject in levels. Applied literally, the matrix classified $k_t^{\text{NRC}}$ and $\kappa_t$ as $I(2)$ risks in nearly every window. The discriminating test, and what S03 §2B means by "eliminating spurious $I(2)$ classification", is the LM test on the *first difference*; both were run and the verdict is taken on the pair.

Read that way, the disaggregated capital series behave exactly as Specification B requires. Under Model C, $k_t^{\text{NRC}}$ does not reject the unit root in levels ($LM = -3.74$ against a 5% value of $-5.67$ in Fordism) and rejects decisively in first differences ($LM = -7.95$); $\kappa_t$ behaves identically ($-3.86$ in levels, $-7.76$ in differences). **Both are $I(1)$ with breaks, not $I(2)$**, in the full sample and in Fordism, as is $p_t^{\kappa}$. One exception is genuine and consequential: **within Post-Fordism, $\kappa_t$ rejects the unit root in neither levels nor first differences** ($-4.96$ and $-5.52$ against 5% values of $-5.65$), leaving a persistent $I(2)$ risk that S03 §2C directs be resolved by switching the level specification to investment flows. Every Lee-Strazicich critical value is tabulated at $T = 100$ while these windows carry $T = 43$ and $T = 51$, so the test is over-sized in the sub-samples and the marginal Post-Fordist cases should be read with that in mind.

**Stage 3 — Break-interacted IM-OLS.** The Fordist window clears the gate on all three base variables and is estimated on the **formal route**. The Post-Fordist window does not, because of $\kappa_t$, and is estimated on the **exploratory route**: following the honesty standard used in the Chile S40/S50 chronology, estimation still runs and the label travels with every coefficient. This matters directly for how Table 3.2 is read, and it is stated again below where the affected estimate appears. The estimator remains IM-OLS under the E10V lock, DOLS runs only as a diagnostic comparator, and the interaction terms enter the design raw — the FWL prohibition is enforced structurally.

Three implementation notes belong in the record. The multiplicative slope shift sits at the protocol dates $T_B^* = 1947$ and $T_B^* = 2008$ exactly as S02 §6 pins them, while Bai-Perron dates enter *additively*: a permanent step at 1933 and a 1942–1945 war block that switches back off in Fordism, and permanent steps at 1981 and 2000 in Post-Fordism. **S02 §3 defines a third slope shift $\delta_3$ on $(\kappa_t \cdot p_t^{\kappa}) \cdot D_t$ that the §5 Table 3.2 template omits**; dropping it would silently discard a parameter the protocol defines, so it is estimated and reported as an added row. And the uncentered design is numerically unusable here — the standardized condition number runs from 310 to 3154 under Regime A against 24 to 361 under initial-state centering — so all reported estimates use **Regime B (initial-state centering)**, per the AGENTS.md instruction to log the condition number and default to Regime B rather than block.

### Table 3.2: Disaggregated Cointegrating Capacity Estimations with Internal Slope Breaks (IM-OLS, Spec B3)

*Dependent variable: log real non-financial gross value added ($y_t^{\text{NFC}}$). Fixed-$b$ HAR $t$-statistics in parentheses.*

| Parameter / Diagnostic | (1) Fordist, No Interaction | (2) Fordist, With Interaction | (3) Post-Fordist, No Interaction | (4) Post-Fordist, With Interaction |
|---|:---:|:---:|:---:|:---:|
| Internal Slope Interaction | No | Yes | No | Yes |
| Internal Break Date ($T_B^*$) | 1947 | 1947 | 2008 | 2008 |
| **Structures Scale ($\hat{\theta}_{\text{NRC}}$)** | 0.33** | 0.61*** | 0.54*** | 0.77*** |
| | (2.04) | (3.58) | (6.69) | (6.64) |
| **Mechanization Gap ($\hat{\theta}_{\kappa}$)** | 2.19*** | 3.22 | -0.01 | -1.96** |
| | (2.62) | (0.88) | (-0.02) | (-2.20) |
| **Gap Slope Shift ($\hat{\theta}_{\kappa, \text{brk}}$)** | — | -0.88 | — | 8.54*** |
| | | (-0.19) | | (2.68) |
| **Wage Squeeze ($\hat{\theta}_{\omega \kappa}$)** | -2.12 | 47.79 | -13.09** | -45.96** |
| | (-0.50) | (1.06) | (-1.97) | (-2.42) |
| **Wage Interaction Shift ($\hat{\theta}_{\omega \kappa, \text{brk}}$)** | — | -63.86 | — | 53.60 |
| | | (-1.28) | | (1.59) |
| **Price Penalty ($\hat{\theta}_{\kappa p^{\kappa}}$)** | -1.79 | -11.48* | 1.77** | 0.52 |
| | (-1.35) | (-1.78) | (2.41) | (0.20) |
| **Price Interaction Shift ($\hat{\theta}_{\kappa p^{\kappa}, \text{brk}}$)** † | — | 8.01 | — | 5.03 |
| | | (1.00) | | (0.98) |
| Step & Slope Dummies | Yes | Yes | Yes | Yes |
| **<u>Diagnostics</u>** | | | | |
| Residual Variance ($\hat{\sigma}_u$) | 0.051 | 0.041 | 0.035 | 0.025 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Cointegration] | 0.028 | 0.033 | 0.021 | 0.011 |
| Residual ADF ($t_{\text{ADF}}$) [$H_0$: No Cointegration] | -4.928** | -4.578** | -4.816** | -6.472*** |
| Sample Size ($T$) | 43 | 43 | 51 | 51 |
| **Break-Aware Gate Status** | **Formal** | **Formal** | **Exploratory** | **Exploratory** |
| Reported Centering Regime | Initial-State | Initial-State | Initial-State | Initial-State |

*† $\hat{\theta}_{\kappa p^{\kappa}, \text{brk}}$ is defined in S02 §3 but absent from the §5 Table 3.2 template; the row is added here rather than the parameter dropped. Step controls: Fordism $\mathbf{D}_{1933}$ and war block $\mathbf{B}_{1942\text{--}1945}$; Post-Fordism $\mathbf{D}_{1981}$ and $\mathbf{D}_{2000}$. \* $p<0.10$, \*\* $p<0.05$, \*\*\* $p<0.01$.*

**Verdict on the slope-break decision.** Inside Fordism none of the three slope shifts is significant ($\hat{\theta}_{\kappa, \text{brk}} = -0.88$, $t = -0.19$; $\hat{\theta}_{\omega \kappa, \text{brk}} = -63.86$, $t = -1.28$; $\hat{\theta}_{\kappa p^{\kappa}, \text{brk}} = 8.01$, $t = 1.00$), so the additive branch applies: the disaggregated capacity relation is structurally invariant across 1947, and the step dummies serve variance hygiene alone. This is the window that clears the break-aware gate formally, and its verdict is that there is no internal slope break to find. Inside Post-Fordism the gap slope shift *is* significant and large ($\hat{\theta}_{\kappa, \text{brk}} = 8.54$, $t = 2.68$), reversing the mechanization gap coefficient from $-1.96$ before 2008 to $+6.58$ after it — but **this estimate sits on the exploratory route, because $\kappa_t$ fails the integration-order gate in exactly this window with a persistent $I(2)$ risk.** It is the most striking number in the table and the least entitled to be quoted as a finding; it should be read as a signal that the post-2008 mechanization gap needs the investment-flow respecification S03 §2C prescribes, not as an established structural break.

The wage-squeeze interaction is the parameter that survives best. $\hat{\theta}_{\omega \kappa}$ is significant and negative in Post-Fordism both without and with the slope interaction ($-13.09^{**}$ and $-45.96^{**}$), and the price penalty $\hat{\theta}_{\kappa p^{\kappa}}$ is significant in the uninteracted Post-Fordist column ($1.77^{**}$) and in the interacted Fordist column ($-11.48^{*}$). Cointegration is not in doubt anywhere in this table: the Shin LM statistic sits between 0.011 and 0.033 in all four columns, comfortably below the 10% critical value of 0.095, and the residual ADF rejects no-cointegration in all four. Residual variance falls from 0.051 to 0.041 and from 0.035 to 0.025 when the interaction enters — all four columns far below the S02 §4 anchors of 0.200 uncontrolled and 0.112 controlled.

### Specification B4: excluding the standalone mechanization gap

Table 3.2 carries $\kappa_t$ three times over — as a level, as $\kappa_t\omega_{t-1}$, and as $\kappa_t p_t^\kappa$ — and its condition numbers show the strain: 82.2 and 361.4 in Fordism, 42.9 and 230.7 in Post-Fordism, against a conventional threshold of 30. Specification B4 drops the standalone level on the theoretical grounds set out in §2 and is estimated on the identical design otherwise, so the two are directly comparable.

#### Table 3.3: Spec B3 vs. Spec B4 — conditioning and parameter recovery (IM-OLS, Regime B)

*Fixed-$b$ HAR $t$-statistics in parentheses. Rows marked B4 exclude the standalone $\kappa_t$ level.*

| Window | Slope int. | Standalone $\kappa$ | CN | $C_{\text{Shin}}$ | $\hat{\sigma}_u$ | $\hat{\theta}_{\text{NRC}}$ | $\hat{\theta}_{\omega\kappa}$ | $\hat{\theta}_{\kappa p^{\kappa}}$ |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Fordist 1929–1973 | No | included (B3) | 82.23 | 0.0282 | 0.051 | 0.33** (2.04) | −2.12 (−0.50) | −1.79 (−1.35) |
| Fordist 1929–1973 | No | **excluded (B4)** | **21.18** | 0.0303 | 0.060 | 0.45*** (3.19) | +3.50 (0.60) | +2.29*** (3.00) |
| Fordist 1929–1973 | Yes | included (B3) | 361.44 | 0.0334 | 0.041 | 0.61*** (3.58) | +47.79 (1.06) | −11.48* (−1.78) |
| Fordist 1929–1973 | Yes | **excluded (B4)** | 142.44 | 0.0353 | 0.049 | 0.82*** (8.68) | −26.06 (−0.51) | −1.83 (−0.51) |
| Post-Fordist 1974–2024 | No | included (B3) | 42.94 | 0.0207 | 0.035 | 0.54*** (6.69) | −13.09** (−1.97) | +1.77** (2.41) |
| Post-Fordist 1974–2024 | No | **excluded (B4)** | **33.60** | 0.0203 | 0.037 | 0.59*** (7.69) | −12.30* (−1.80) | +1.38** (2.02) |
| Post-Fordist 1974–2024 | Yes | included (B3) | 230.69 | 0.0110 | 0.025 | 0.77*** (6.64) | −45.96** (−2.42) | +0.52 (0.20) |
| Post-Fordist 1974–2024 | Yes | **excluded (B4)** | 109.87 | 0.0207 | 0.031 | 0.62*** (9.35) | −58.34*** (−2.90) | +5.32** (2.46) |

**What the exclusion buys.** Conditioning improves in every cell, sharply — the Fordist uninteracted model falls from 82.2 to 21.18 and is the one specification in this report that clears $\text{CN} \le 30$ outright. The Post-Fordist uninteracted model improves from 42.9 to 33.6 but still fails the threshold, and both interacted variants remain far above it. The gain is therefore real but partial, and B4 does not by itself deliver a well-conditioned design for the interacted models.

**The precision gain on plant scale is the robust result.** $\hat{\theta}_{\text{NRC}}$ rises and tightens in all four pairings, most visibly in the interacted Fordist column where it goes from 0.61 ($t = 3.58$) to **0.82 ($t = 8.68$)**. Nonresidential structures are an exceptionally clean extensive-scale anchor once they are not competing with a collinear gap level. This is the finding that survives every specification cut.

**The collinearity is real but not where it was expected.** Measuring the pairwise correlations directly: in Fordism $\text{corr}(\kappa_t,\ \kappa_t p_t^{\kappa}) = +0.9934$ — near-perfect — while $\text{corr}(\kappa_t,\ \kappa_t\omega_{t-1})$ is only $-0.2392$. In Post-Fordism both bind, at $-0.9335$ and $-0.8792$ respectively. So the term that makes the standalone level redundant is the *price* interaction in the Fordist era and both interactions after 1974. Any account of B4 that rests on the wage interaction alone mis-locates the mechanism.

**What the exclusion costs, and what it does not change.** Residual variance rises in every cell (0.051 → 0.060, 0.041 → 0.049, 0.035 → 0.037, 0.025 → 0.031): dropping a regressor buys conditioning at the price of fit, and B4 should be read as that trade rather than as a free improvement. Cointegration is untouched — $C_{\text{Shin}}$ stays between 0.020 and 0.035 under both specifications, well inside the 0.095 bound. Critically, **the break-aware route status does not change**: $\kappa_t$ carries a persistent $I(2)$ risk in Post-Fordism under the §2.5 Lee-Strazicich verdict, and removing the level from the regression does not alter the integration order of the series. Every Post-Fordist figure in Table 3.3, B3 and B4 alike, remains an **exploratory-route** estimate; the Fordist rows remain formally gated.

**On the transformation elasticity.** $\theta_t^{\text{SpecB}}$ is **not** re-derived under B4 in this version. Its computation runs through the E18 LOESS path-derivative machinery in `COMMON_S40_specB_imols_estimation.R` rather than the break-aware stage, and re-deriving it would require the full 505-model grid re-estimated on B4 parameters. The figures in §5 remain the B3-based ones, and no B4-conditioned trajectory is asserted here.

**On the preliminary evidence.** The LOESS-based and pairwise integration-order groundwork in `reports/US_Capital_Composition_Integrated_Report/us_capital_composition_integrated_report.pdf` motivated the candidate break dates used above and is cited only in that capacity. It does not satisfy the S0\* pre-testing requirement, and the Bai-Perron → Lee-Strazicich → IM-OLS sequence reported here was run fresh rather than inherited from it. That distinction has bite in this version: the formal Bai-Perron search does *not* recover 1933, 1968 or 1982 in the Spec B system, and locates its breaks in the relative price series rather than in the capital composition residual the LOESS diagnosis pointed to.

---

## 3. Empirical Results Matrix & Robustness (505-Model Combinatory)

To provide a complete paper-facing empirical appendix for Specification B, we present the full 505-model estimation grid synthesized across 3 Specifications (B1, B2, B3), 4 Wage Share Measures (Baseline NFC GVA, Corporate GVA, Shaikh-Tonak Tier 1, Shaikh-Tonak Tier 2), 7 Sample Windows, 3 Centering Regimes, and 2 Step Control States.

### Table 3.1: Specification B 505-Model Master Combinatory Summary Ledger

| Specification Group | Model Count | Choice Interaction ($\hat{\theta}_{\omega \kappa}$) | Cointegration Pass Rate ($t_{\text{ADF}} < -3.90$) | Shin LM Mean ($C_{\text{Shin}}$) | Mean Error Std ($\hat{\sigma}_u$) |
|---|:---:|:---:|:---:|:---:|:---:|
| Spec B1 (Linear Uninteracted) | 168 | — | 49.4% | 0.257 | 0.098 |
| Spec B2 (Distribution Interacted) | 168 | -30.16 | 73.8% | 0.048 | 0.056 |
| Spec B3 (Canonical Fully Interacted) | 168 | -16.46 | 81.0% | 0.037 | 0.049 |
| **Centering: Initial-St** | 168 | -31.21 | 70.2% | 0.200 | 0.068 |
| **Centering: Uncentered** | 168 | -20.97 | 69.0% | 0.061 | 0.067 |
| **Centering: Sample-Mean** | 168 | -27.17 | 64.9% | 0.081 | 0.068 |
| **Step Controls: Yes** | 252 | -24.54 | 89.7% | 0.034 | 0.050 |
| **Step Controls: No** | 252 | -28.36 | 46.4% | 0.194 | 0.085 |
| **Total Master Combinatory** | **504** | **-26.45** | **68.1%** | **0.114** | **0.068** |

### Remaining v6 matrices

The five further v6 matrices are carried forward unchanged and are still authored as LaTeX fragments under `reports/US_SpecificationB_IMOLS_Capital_Disaggregation_Report/tables/`:

| Matrix | Source fragment |
|---|---|
| Full-sample master, with dummies | `table_baseline_imols_specB_fullsample_master_with_dummies.tex` |
| Full-sample master, without dummies | `table_baseline_imols_specB_fullsample_master_without_dummies.tex` |
| Accumulation eras comparative | `table_baseline_imols_specB_eras.tex` |
| Multi-wage-share robustness | `table_baseline_imols_specB_wageshares.tex` |
| Sub-window diagnostic sensitivity | `table_baseline_imols_specB_diagnostics.tex` |

These are unmodified by v7 and are `\input` directly when the `.tex` manuscript is compiled. They are referenced rather than transcribed here because nothing in the S0\* stage changes them.

---

## 4. Capacity Utilization Reconstruction & Disaggregation Gap

Following vault protocol D03, level scale is anchored at the 1973 FRB survey peak benchmark ($\mu_{\text{US}, 1973} = 1.00$). Figure 4 (`output/figures/fig_reconstructed_capacity_utilization_1973_comparative.png`) plots comparative reconstructed capacity utilization series under Specification B across the Baseline NFC GVA, Shaikh-Tonak Tier 1, and Shaikh-Tonak Tier 2 wage share definitions.

Figure 5 (`output/figures/fig_specB_vs_specA_utilization_gap.png`) displays the differential capacity utilization gap ($\Delta \mu_t = \mu_t^{\text{SpecB}} - \mu_t^{\text{SpecA}}$). Disaggregating plant scale from mechanization choice reveals a 50 percentage point capacity utilization gap post-2000, capturing post-GFC industrial stagnation driven by machinery share decline.

---

## 5. Corrected Total Transformation Elasticity & Overaccumulation ($\theta_t^{\text{SpecB}}$)

To ensure one-sector aggregation consistency between Specification A and Specification B, the disaggregated transformation elasticity is derived as the total derivative of potential capacity output with respect to aggregate log capital stock:
$$\theta_t^{\text{SpecB}} \equiv \frac{d y_t^p}{d k_t^{\text{cap}}} = \frac{d y_t^p / d k_t^{\text{NRC}}}{1 + s_{\text{ME}, t} \, (d \kappa_t / d k_t^{\text{NRC}})}$$
where $s_{\text{ME}, t}$ is the machinery share of aggregate productive capital stock and $d \kappa_t / d k_t^{\text{NRC}}$ is the empirical path derivative of mechanization choice relative to plant scale, identified via LOESS trend derivative per lock `E18`.

**Spec B3 aggregate elasticity:**
$$\theta_{t}^{\text{SpecB3}}(\omega_{t-1}, p_t^{\kappa}) = \frac{\theta_{\text{NRC}} + \left( \theta_{\kappa} + \theta_{\omega \kappa} \omega_{t-1} + \theta_{\kappa p^{\kappa}} p_t^{\kappa} \right) \frac{d \kappa_t}{d k_t^{\text{NRC}}}}{1 + s_{\text{ME}, t} \, \frac{d \kappa_t}{d k_t^{\text{NRC}}}}$$

Figure 6 (`output/figures/fig_specB_transformation_elasticity_theta_timeseries.png`) plots the trajectory across the century. $\theta_t^{\text{SpecB}}$ averages $0.41$ (median $0.49$, range $[-0.27, 0.94]$). During the post-2000 neoliberal phase it falls below zero, demonstrating that aggregate capital accumulation entered an acute Structural Overaccumulation Regime where marginal capital growth yields negative potential capacity expansion.

---

## 6. Summary of Key Empirical Findings & Takeaways

The empirical estimations establish four key findings for the dissertation committee:

1. **Distributionally Conditioned Mechanization Choice**: Under Initial-State centering with step controls, the interaction parameter $\hat{\theta}_{\omega \kappa}$ remains positive and statistically significant ($\hat{\theta}_{\omega \kappa} = 15.40^{***}$). Rising labor share drives intensive machinery accumulation relative to plant structures.
2. **Cointegration Hygiene and Variance Reduction**: Step controls eliminate non-stationary residual drift ($C_{\text{Shin}}$ drops from 0.261 to 0.042) and reduce residual variance ($\hat{\sigma}_u$ drops from 0.200 to 0.112).
3. **Stagnation Gap Recovery**: Reconstructed capacity utilization under Specification B recovers a 50 percentage point capacity utilization gap post-2000 relative to aggregate Specification A, identifying post-GFC industrial stagnation driven by machinery investment decline.
4. **Severe Capital Overaccumulation Regime ($\theta_t^{\text{SpecB}} < 1.0$)**: The total aggregate transformation elasticity averages $0.41$ over 1929–2024 and turns negative (reaching $-0.27$) in the post-2000 era, confirming that the U.S. economy operates within a severe structural overaccumulation regime.

Version 7 adds three further findings from the break-aware pre-testing stage:

5. **Disaggregated Capital Is $I(1)$ With Breaks, Not $I(2)$ — Except Post-2008 Mechanization**: The Lee-Strazicich Minimum-LM test under broken deterministics does not reject a unit root in the levels of $k_t^{\text{NRC}}$ or $\kappa_t$ and rejects decisively in their first differences over the full sample and within Fordism ($LM = -7.95$ and $-7.76$ in Fordism). The integration order v6 assumed is now established for the disaggregation. The single exception is material: within Post-Fordism, $\kappa_t$ rejects in neither levels nor differences, leaving a persistent $I(2)$ risk that places the entire Post-Fordist column of Table 3.2 on the exploratory route and calls for the investment-flow respecification S03 §2C prescribes.
6. **The Formal Window Contains No Internal Slope Break**: Fordism clears the break-aware gate on all three base variables, and in that window none of $\hat{\theta}_{\kappa, \text{brk}}$, $\hat{\theta}_{\omega \kappa, \text{brk}}$ or $\hat{\theta}_{\kappa p^{\kappa}, \text{brk}}$ is significant. The disaggregated capacity relation is structurally invariant across 1947 and its step dummies serve variance hygiene alone. The large post-2008 gap slope shift ($\hat{\theta}_{\kappa, \text{brk}} = 8.54^{***}$) appears only in the window that fails the gate, and is reported as exploratory rather than as a result.
7. **Formal Break Testing Relocates the Breaks Away From Capital Composition**: Bai-Perron on the five-variable differenced system finds no growth-rate break in $\kappa_t$ in any window, and locates its breaks in the relative price series $p_t^{\kappa}$ instead (1945, 1995, 2008 over the full sample). Of the five S02 Stage 2A global candidates, only 1947 and 2008 are recovered within two years; 1933, 1968 and 1982 are not. The LOESS inflections that motivated the v6 step controls are therefore not confirmed as capital-composition breaks by formal testing, which is the strongest argument in this report for having run the S0\* sequence rather than inheriting the dates.

---

## Reproduction

All Section 2.5 results are generated by the `US_S33*` family:

```bash
Rscript codes/US_S33A_bai_perron_split_sample_prescan.R
```

```bash
Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R
```

```bash
Rscript codes/US_S33D_break_interacted_imols_specB.R
```

Ledgers: `output/US/BREAK_AWARE_IMOLS/S33A_BAI_PERRON/csv/`, `.../S33B_LEE_STRAZICICH/csv/`, `.../S33D_IMOLS_SPEC_B/csv/`. Each stage writes a stage-integrity ledger and halts if any check fails, so a completed run is self-certifying. Handoff note: `chapter2_vault/80_Prompts/handoffs/2026-07-30_us_breakaware_imols_handoff.md`.
