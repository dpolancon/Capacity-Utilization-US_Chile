# DISSERTATION PROGRESS REPORT & ONLINE APPENDIX
## Chapter 2: Disaggregating Plant Scale, Mechanization Choice, and Relative Capital Prices (Specification B)

**Author:** Diego Polanco (Department of Economics, UMass Amherst)  
**Advisor:** Michael Ash  
**Date:** July 2026  
**Compiled Artifact:** `us_specB_imols_capital_disaggregation_report_v8.pdf`  
**Supersedes:** `us_specB_imols_capital_disaggregation_report_v7.pdf` (retained unmodified)

---

## Executive Summary

This progress report provides the complete, paper-facing empirical appendix for **Specification B (Capital Disaggregation Model)** of Chapter 2. By unbundling aggregate productive capital into extensive nonresidential plant structures ($K^{\text{NRC}}$) and intensive machinery ($K^{\text{ME}}$), Specification B provides structural identification of the technical choice mechanism ($\kappa_t = k^{\text{ME}}_t - k^{\text{NRC}}_t$), relative asset price dynamics ($p_t^{\kappa} = \ln P^{\text{ME}}_t - \ln P^{\text{NRC}}_t$), and class distribution ($\omega_{t-1}$). We evaluate the full range of 505 IM-OLS cointegrating regressions across four master comparative matrices comparing specifications **With Step Controls ($\boldsymbol{\gamma}'\mathbf{D}_t = \text{Yes}$)** against **Without Step Controls ($\boldsymbol{\gamma}'\mathbf{D}_t = \text{No}$)**.

Core empirical findings carried forward from v6: (1) class distribution conditions mechanization choice ($\hat{\theta}_{\omega \kappa} = 15.40^{***}$ under initial-state centering with step controls); (2) step controls eliminate residual non-stationarity ($C_{\text{Shin}}$ drops from 0.261 to 0.042); (3) reconstructed capacity utilization ($\hat{\mu}_t^{\text{SpecB}}$) anchored at $\mu_{1973} = 1.00$ recovers a 50 percentage point post-2000 industrial stagnation gap relative to aggregate Specification A; and (4) the total transformation elasticity ($\theta_t^{\text{SpecB}} < 1.0$) confirms persistent capital overaccumulation throughout post-war capitalism.

**What v8 corrects.** Version 7's break-interacted designs were incomplete. The products $(\kappa_t\omega_{t-1})D_t$ and $(\kappa_t p_t^\kappa)D_t$ were estimated without the constituents $\omega_{t-1}D_t$ and $p_t^\kappa D_t$, which means centering the base series was **changing the model rather than reparameterizing it**. Section 2.5A documents the defect, the correction, and its consequences. The correction is materially more consequential here than in Specification A: one of the omitted constituents is significant at 1%, and restoring it **halves the Fordist residual variance** and strengthens the cointegration evidence substantially. The §2.5 slope-break verdict survives, but a wage-share level shift at 1947 that v7 could not see is now visible. Sections 3–5 are unaffected — they carry no break interactions — and are reproduced unchanged.

---

## 1. Methodological Setup & Disaggregation Architecture

National accounting consistency requires strict clarity regarding sectoral boundaries in capital disaggregation:

- **Observed Aggregate Output ($Y_t$)**: Measured via *Total Corporate Gross Value Added* ($Y_{\text{CORP}}$) or aggregate real output ($Y_t$) from NIPA accounts, capturing aggregate demand realization across corporate capitalism.
- **Productive Capital Disaggregation ($K_{\text{NFC}}^{\text{NRC}}$ and $K_{\text{NFC}}^{\text{ME}}$)**: We unbundle non-financial corporate productive fixed assets into nonresidential structures ($K_{\text{NFC}}^{\text{NRC}}$), representing sunk extensive plant scale, and machinery and equipment ($K_{\text{NFC}}^{\text{ME}}$), representing intensive mechanization technology choice.
- **Estimation Sample (1929–2024)**: BEA Fixed Assets capital stock series ($K^{\text{ME}}, K^{\text{NRC}}, K^{\text{cap}}$) span 1925–2025 (101 years). However, corporate value added ($y_t^{\text{NFC}}$) and distribution ($\omega_{t-1}$) begin in 1929, establishing an estimation sample of **1929–2024 ($T = 94$ years)**.

Figure 1 (`output/figures/fig_specB_3panel_structural_decomposition.png`) plots the raw historical trajectories of nonresidential structures ($k^{\text{NRC}}$), machinery ($k^{\text{ME}}$), capital composition residual ($\kappa_t$), and relative equipment-to-structure deflator trends ($p_t^{\kappa}$).

A non-parametric LOESS trend of $\ln K^{\text{cap}}$ reveals structural inflections used in v6 to construct step dummy controls ($\boldsymbol{\gamma}' \mathbf{D}_t = [D_{1933}, D_{1947}, D_{1974}, D_{2008}]'$), capturing the New Deal mobilization, Fordist expansion, late-Fordist profit squeeze, and post-GFC stagnation. **Section 2.5 replaces the LOESS provenance of these dates with formal Bai-Perron evidence.**

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

B4 departs from the S02 taxonomy and is motivated on two grounds. **Theoretically**, in Marxian choice-of-technique models (Okishio 1961; Foley & Michl 1999; Shaikh 2016) capitalists do not raise the machinery-to-structures ratio out of a distribution-neutral propensity to mechanize: technical choice is driven by distributional conflict and by relative asset prices. On that reading $\kappa_t$ enters productive capacity as a *state-dependent channel*, not as an autonomous physical level, and the standalone term has no behavioural referent. The standard objection — that omitting a main effect while retaining its interaction induces omitted-variable bias — presumes the main effect is a primitive of the data-generating process, which is exactly what the Marxian reading denies. **Econometrically**, in a cointegrated system estimated in log-levels the standalone level and its own cross-products are close to parallel, and carrying both forces the estimator to separate near-collinear columns.

> **A note on B4 in light of §2.5A.** The span correction sharpens what B4 is and is not. Dropping the standalone $\kappa_t$ **level** is a theoretical claim about the data-generating process. Dropping $\kappa_t D_t$ would be a different thing entirely — an algebraic defect, since that column is a required constituent of $(\kappa_t\omega_{t-1})D_t$ regardless of whether $\kappa_t$ has a behavioural referent as a main effect. Version 7's B4 conflated the two and omitted both. Version 8 retains $\kappa_t D_t$ under B4 as a span constituent while still excluding the standalone level, so B4 now tests the theoretical claim it was meant to test. Section 3.2 of the Section 3.2 draft governs the level question; the span question is not a modelling choice.

Each specification is evaluated both With and Without Step Controls across Initial-State, Uncentered, and Sample-Mean normalizations.

### Table 2.1: Specification B Model Taxonomy Comparison Matrix (Initial-State Centering)

*Unchanged from v7: these are uninteracted full-sample designs and carry no break products.*

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

## 2.5A The interaction-span correction

**The defect.** When a break-interacted product enters the design, centering the base series expands it:

$$(\kappa - k_0)(\omega - w_0)\, D_t = (\kappa\omega) D_t - k_0 (\omega D_t) - w_0 (\kappa D_t) + k_0 w_0 D_t$$

so the design must span $(\kappa\omega)D_t$, $\omega D_t$, $\kappa D_t$ and $D_t$ for centering to be a **reparameterization**. Version 7 carried $\kappa D_t$ (as $\hat\delta_1$, and only under B1–B3) but **not $\omega D_t$**, and carried $(\kappa p^\kappa)D_t$ without $p^\kappa D_t$. With a constituent missing, the three centering regimes are three different models and the regime silently selects the parameter values.

The mechanism was verified on synthetic data with a known data-generating process (`US_S33F`): the relative spread of OLS estimates across regimes is $6\times10^{-16}$ with a complete span, $7.8\times10^{-2}$ once a product enters without its constituents, and $6\times10^{-16}$ again when they are restored. It is not an IM-OLS artefact and not ill-conditioning.

**The correction.** `US_S33D` and `US_S33E` now build the break block through a shared helper (`s33_break_span()`) that includes every lower-order constituent by construction, with a guard (`s33_assert_complete_span()`) that halts the stage otherwise. As a regression test, `US_S33G` (Specification B5) — which already carried a complete span — is **byte-identical** after the change, confirming the correction is scoped to the designs that were actually defective.

**What it bought and what it cost.**

| Cell | Regressors ($k$) | Residual d.f. | Standardized CN | $\hat\sigma_u$ | $C_{\text{Shin}}$ |
|---|:---:|:---:|:---:|:---:|:---:|
| B3 Fordist, interacted | 12 → **14** | 30 → **28** | 361.4 → **468.2** | 0.0409 → **0.0204** | 0.0334 → **0.0054** |
| B3 Post-Fordist, interacted | 12 → **14** | 38 → **36** | 230.7 → **463.2** | 0.0251 → 0.0255 | 0.0110 → 0.0107 |
| Full-sample wage-break, interacted | 11 → **13** | 82 → **80** | 39.2 → **76.8** | 0.0939 → **0.0805** | 0.0236 → **0.0198** |

*Reported regime (initial-state centering). Uninteracted columns carry no break products and are numerically identical to v7.*

**The Fordist result is the strongest evidence that the correction was necessary.** The omitted constituent $\omega_{t-1}D_t$ is significant at 1% ($\hat\beta_{\omega,\text{brk}} = 16.78$, $t = 2.62$) — it was not a technicality but a real term. Restoring it **halves the residual variance** (0.0409 → 0.0204), cuts the Shin statistic by a factor of six (0.0334 → 0.0054) and strengthens the residual ADF from $-4.578^{**}$ to $-7.995^{***}$. Version 7's Fordist interacted column was fitting a misspecified model.

> **A size caveat on those diagnostics.** The Fordist interacted design carries $k = 14$ regressors on $T = 43$ observations, leaving 28 residual degrees of freedom. Both the Shin LM statistic and the residual ADF are read against **asymptotic** critical values, and at this ratio the standard concern applies in both directions: a heavily parameterised design can manufacture residuals that look stationary, and the ADF is over-sized in short samples. No residual bootstrap was run for these IM-OLS diagnostics — the resampling protocol used for the Chile sub-sample VECMs has no implementation in the S33 stage. The direction of the change (misspecified → correctly specified) is not in question, because the added term is a required constituent and is significant on its own $t$-statistic. The *magnitude* of the diagnostic improvement should be discounted accordingly, and $C_{\text{Shin}} = 0.005$ should not be read as six times better cointegration evidence than $C_{\text{Shin}} = 0.033$. Bootstrapping these statistics is recorded as an outstanding item.

**The cost is conditioning, and it is severe.** Both split-sample interacted designs roughly double their condition numbers, and the Post-Fordist cell goes from 230.7 to 463.2 with no compensating gain in fit. Neither cleared the CN $\le 30$ gate before and neither does after, so no verdict changes — but the B3 interacted designs are now the worst-conditioned in the project, carrying 14 regressors on $T = 43$ and $T = 51$.

**Sign-stability: a partial repair.** Across all 46 interaction-class parameters in the Specification B track, five gained sign-stability across the three centering regimes and one lost it. The headline gain is the Fordist wage interaction:

| Cell | Parameter | v7 centering range | v8 centering range | Sign-stable |
|---|---|:---:|:---:|:---:|
| B3 Fordist, int. | $\hat\theta_{\omega\kappa}$ | $[-23.61,\ 47.79]$ | $[-174.37,\ -95.46]$ | No → **Yes** |
| B3 Fordist, int. | $\hat\theta_{\kappa p^\kappa}$ | $[-11.48,\ 0.01]$ | $[-28.74,\ -4.76]$ | No → **Yes** |
| B4 Fordist, int. | $\hat\theta_{\kappa p^\kappa}$ | $[-1.83,\ 2.82]$ | $[-48.72,\ -8.70]$ | No → **Yes** |
| B2 Fordist, int. | $\hat\delta_2$ | $[-63.45,\ -10.78]$ | $[-65.53,\ 111.63]$ | **Yes → No** |

This must be read with care. The Fordist $\hat\theta_{\omega\kappa}$ is now sign-stable, but at $-95$ to $-174$ with a condition number of 468 and $C_{\text{Shin}}$ collapsing to 0.005 — magnitudes and diagnostics more consistent with an over-specified design on 43 observations than with a recovered structural parameter. **Sign-stability is a necessary condition, not a sufficient one**, and the B2 Fordist reversal in the opposite direction makes the same point. The Fordist interacted estimates should be read as diagnostics of the split-sample design's limits rather than as parameter recovery.

The full-sample track fares better on every dimension: fit improves, conditioning stays under 80, and no parameter loses stability.

### Consolidated specification verdict

Mapping every break-interacted design in the Specification B track to its theoretical basis, its stochastic evidence, and its disposition. This is the specification space actually searched; nothing below is presented as a single preferred model.

| Design | Theoretical basis | Integration-order gate | Conditioning | Sign-identification | Disposition |
|---|---|---|---|---|---|
| B3 Fordist, uninteracted | S02 §3 canonical | **Formal** (all three base vars $I(1)$) | CN 82.2, fails $\le 30$ | n/a | **Held** — cointegrated, but conditioning fails |
| B3 Fordist, interacted | S02 §3 + §6 slope shift | **Formal** | CN 468.2, fails badly | $\hat\theta_{\omega\kappa}$ stable but at $-95$ to $-174$ | **Held as diagnostic** — 14 regressors on $T=43$; magnitudes not credible as parameters |
| B3 Post-Fordist, uninteracted | S02 §3 canonical | **Exploratory** ($\kappa_t$ $I(2)$ risk) | CN 42.9, fails | n/a | **Held** — route status blocks formal claims |
| B3 Post-Fordist, interacted | S02 §3 + §6 | **Exploratory** | CN 463.2, fails badly | $\hat\theta_{\omega\kappa}$ stable, $-45.2^{**}$ | **Held as diagnostic** |
| B4 Fordist, uninteracted | §2 Marxian channel reading | **Formal** | **CN 21.2, passes** | n/a | **Promoted** — the only design in this report clearing the threshold |
| B4 Post-Fordist, uninteracted | §2 | **Exploratory** | CN 33.6, marginal fail | n/a | **Held** |
| B4, interacted (both windows) | §2 + §6 | as B3 | CN 383–455, fails | mixed | **Held as diagnostic** — exclusion buys little once span is complete |
| Full-sample wage-break (B4 form) | §2.6 regime prediction | **Formal** | CN 76.8, fails | $\hat\theta_{\kappa p^\kappa}$ **unstable** | **Held** — no standalone $\kappa$, so invariance incomplete |
| **Spec B5** (`US_S33G`) | §3.2 line 94 | **Formal** | CN 30.0–76.8, fails | **7/7 interaction-class stable** | **Reference specification** for the break-interacted evidence |
| FWL-residualized interactions | — | — | — | — | **Blocked** — E10V: partial summation does not commute with projection |
| Three-way $\kappa\omega p^\kappa$ | A06 line 78 cross-partial | — | — | — | **Blocked** — §3.2's separable cost derives no such term (see reconciliation note) |

Two patterns run through the table and neither is a matter of taste. **No design clears $\text{CN} \le 30$ except B4 Fordist uninteracted**, so the collinearity problem is structural to the log-levels stock formulation rather than an artefact of any one specification; the investment-flow respecification S03 §2C prescribes remains the outstanding econometric route. And **every interacted split-sample design is now held as a diagnostic rather than reported as parameter recovery**, on the joint grounds of conditioning, degrees of freedom, and implausible magnitudes. The break-interacted evidence the chapter should carry comes from the full-sample tracks.

---

## 2.5 Break-Aware Integration-Order Pre-Testing (S0\* Protocol)

The estimates in Sections 2 and 3 rest on two claims that v6 asserted rather than tested: that $k_t^{\text{NRC}}$ and $\kappa_t$ are $I(1)$, and that the step-control dates mark real structural breaks rather than LOESS curvature. The S0\* protocol notes locked on 2026-07-30 make both testable in a fixed order — Bai-Perron, then Lee-Strazicich, then break-interacted IM-OLS. That sequence was executed fresh; the ledgers are under `output/US/BREAK_AWARE_IMOLS/`.

**The split samples are historical, not estimated.** Fordism runs to 1973 and Post-Fordism from 1974, and no break test revises that periodization. What the break tests locate are *within-sample* structural breaks — the Depression, war mobilization, the Volcker disinflation — that must be controlled for the estimation to be adequate.

**Stage 2A — Bai-Perron (1998, 2003).** The sequential search ran on the stationary five-variable differenced vector $\Delta\mathbf{Y}_t = [\Delta y_t, \Delta k_t^{\text{NRC}}, \Delta\kappa_t, \Delta\omega_t, \Delta p_t^{\kappa}]'$, never on levels, with full-sample trimming $\epsilon = 0.15$ and up to five breaks, and sub-sample trimming $\epsilon = 0.20$ (Fordist) and $0.15$ (Post-Fordist) with up to three. Breaks are admitted only when UDmax rejects at 5% *and* the sequential $\sup F_T(l+1|l)$ rejects. Over the full sample the procedure locates breaks at **1945, 1995 and 2008** in the relative price series $\Delta p_t^{\kappa}$; inside Fordism at **1945** ($\Delta p_t^{\kappa}$) and **1943** in the differenced relation; inside Post-Fordism at **1981** ($\Delta k_t^{\text{NRC}}$), **1992** ($\Delta p_t^{\kappa}$), and **1980, 1990, 1998** in the differenced relation. $\Delta y_t$, $\Delta\kappa_t$ and $\Delta\omega_t$ carry no growth-rate breaks at all.

Measured against the S02 Stage 2A candidates, the record is mixed and is reported as such: **1947 and 2008 are recovered** (distances of two years and zero), **1933, 1968 and 1982 are not** (distances of ten, twenty-three and thirteen). The mechanization gap $\kappa_t$ itself is the quietest series in the system — its growth rate contains no detectable break in any window — so the breaks the LOESS diagnosis attributed to capital composition are, on formal testing, breaks in the *relative price* series instead. $WD_{\max}$ is named in S03 §2A but is not exposed by `mbreaks` 1.0.1; it is recorded as unavailable rather than approximated.

**Stage 2B — Lee-Strazicich (2003) Minimum-LM.** The test comes from the mandated external engine at `C:\ReposGitHub\LeeStrazicichUnitRoot`; no substitute was written. Two deviations are on the record. First, `ur.ls()` locates breaks *endogenously* and accepts no fixed-date argument, so the test could not be run "at the Bai-Perron dates" as S02 Stage 2B requests; it was run as designed and a date-concordance ledger reports the agreement separately. Second, the S03 §2C decision matrix reads a *levels* non-rejection as evidence of $I(2)$ — which inverts the standard logic, since an $I(1)$ series must fail to reject in levels. Applied literally, the matrix classified $k_t^{\text{NRC}}$ and $\kappa_t$ as $I(2)$ risks in nearly every window. The discriminating test, and what S03 §2B means by "eliminating spurious $I(2)$ classification", is the LM test on the *first difference*; both were run and the verdict is taken on the pair.

Read that way, the disaggregated capital series behave exactly as Specification B requires. Under Model C, $k_t^{\text{NRC}}$ does not reject the unit root in levels ($LM = -3.74$ against a 5% value of $-5.67$ in Fordism) and rejects decisively in first differences ($LM = -7.95$); $\kappa_t$ behaves identically ($-3.86$ in levels, $-7.76$ in differences). **Both are $I(1)$ with breaks, not $I(2)$**, in the full sample and in Fordism, as is $p_t^{\kappa}$. One exception is genuine and consequential: **within Post-Fordism, $\kappa_t$ rejects the unit root in neither levels nor first differences** ($-4.96$ and $-5.52$ against 5% values of $-5.65$), leaving a persistent $I(2)$ risk that S03 §2C directs be resolved by switching the level specification to investment flows. Every Lee-Strazicich critical value is tabulated at $T = 100$ while these windows carry $T = 43$ and $T = 51$, so the test is over-sized in the sub-samples and the marginal Post-Fordist cases should be read with that in mind.

**Stage 3 — Break-interacted IM-OLS.** The Fordist window clears the gate on all three base variables and is estimated on the **formal route**. The Post-Fordist window does not, because of $\kappa_t$, and is estimated on the **exploratory route**: estimation still runs and the label travels with every coefficient. The estimator remains IM-OLS under the E10V lock, DOLS runs only as a diagnostic comparator, and the interaction terms enter the design raw — the FWL prohibition is enforced structurally.

Three implementation notes belong in the record. The multiplicative slope shift sits at the protocol dates $T_B^* = 1947$ and $T_B^* = 2008$ exactly as S02 §6 pins them, while Bai-Perron dates enter *additively*: a permanent step at 1933 and a 1942–1945 war block that switches back off in Fordism, and permanent steps at 1981 and 2000 in Post-Fordism. **S02 §3 defines a third slope shift $\delta_3$ on $(\kappa_t \cdot p_t^{\kappa}) \cdot D_t$ that the §5 Table 3.2 template omits**; dropping it would silently discard a parameter the protocol defines, so it is estimated and reported as an added row. And the uncentered design is numerically unusable — the standardized condition number runs from 310 to 17876 under Regime A against 21 to 468 under initial-state centering — so all reported estimates use **Regime B (initial-state centering)**.

### What the raw series do, before any estimation

The parametric results below should be read against the unconditional growth record, which `US_S33H` computes without calling any estimator (mean annual log change, per cent per year):

| Series | Full sample 1929–2024 | Fordism 1929–1973 | Post-Fordism 1974–2024 |
|---|:---:|:---:|:---:|
| Corporate value added $y^{\text{NFC}}$ | 3.89 | 4.93 | 3.12 |
| Nonresidential structures $k^{\text{NRC}}$ | 5.76 | 5.46 | 5.72 |
| Machinery and equipment $k^{\text{ME}}$ | 6.21 | 6.95 | 5.30 |
| **Mechanization gap $\kappa$** | 0.45 | **+1.49** | **−0.43** |
| **Relative price $p^{\kappa}$** | −0.69 | **+0.90** | **−2.03** |
| Wage share $\omega$ | −0.10 | −0.05 | −0.17 |

Three facts constrain any account the regressions can offer. **Output growth falls by more than a third across the periodization** (4.93 → 3.12) while structures growth is essentially flat (5.46 → 5.72): the extensive margin keeps accumulating as capacity growth decelerates, which is the descriptive signature of overaccumulation the elasticity $\theta_t^{\text{SpecB}} < 1$ formalises. **The mechanization gap reverses sign** (+1.49 → −0.43): machinery outgrew structures under Fordism and has fallen behind since, so the intensive margin is not merely slowing but retreating. And **the relative price of machinery collapses** (+0.90 → −2.03), which under either derivation in §2 should have *encouraged* mechanization after 1974. That it did not is the central puzzle the price channel is meant to address, and it is why the joint insignificance of the price block reported at the end of this section matters rather than being a technicality.

### Table 3.2: Disaggregated Cointegrating Capacity Estimations with Internal Slope Breaks (IM-OLS, Spec B3, complete interaction span)

*Dependent variable: log real non-financial gross value added ($y_t^{\text{NFC}}$). Fixed-$b$ HAR $t$-statistics in parentheses.*

| Parameter / Diagnostic | (1) Fordist, No Interaction | (2) Fordist, With Interaction | (3) Post-Fordist, No Interaction | (4) Post-Fordist, With Interaction |
|---|:---:|:---:|:---:|:---:|
| Internal Slope Interaction | No | Yes | No | Yes |
| Internal Break Date ($T_B^*$) | 1947 | 1947 | 2008 | 2008 |
| **Structures Scale ($\hat{\theta}_{\text{NRC}}$)** | 0.33** | 0.59*** | 0.54*** | 0.79*** |
| | (2.04) | (3.77) | (6.69) | (6.45) |
| **Mechanization Gap ($\hat{\theta}_{\kappa}$)** | 2.19*** | -3.86 | -0.01 | -2.11** |
| | (2.62) | (-0.85) | (-0.02) | (-2.37) |
| **Gap Slope Shift ($\hat{\delta}_1$)** | — | 4.78 | — | 1.65 |
| | | (0.99) | | (0.14) |
| **Wage Share ($\hat{\beta}_{\omega}$)** | -1.72* | -7.12 | 1.80* | 1.12 |
| | (-1.81) | (-1.22) | (1.66) | (0.37) |
| **Wage Share Level Shift ($\hat{\beta}_{\omega, \text{brk}}$)** ‡ | — | **16.78***** | — | 3.76 |
| | | **(2.62)** | | (0.19) |
| **Relative Price ($\hat{\beta}_{p^{\kappa}}$)** | 0.58** | 1.73** | 0.15 | 1.08* |
| | (2.40) | (2.03) | (1.09) | (1.92) |
| **Price Level Shift ($\hat{\beta}_{p^{\kappa}, \text{brk}}$)** ‡ | — | -0.74 | — | -1.36 |
| | | (-0.44) | | (-0.70) |
| **Wage Squeeze ($\hat{\theta}_{\omega \kappa}$)** | -2.12 | -174.37* | -13.09** | -45.21** |
| | (-0.50) | (-1.76) | (-1.97) | (-2.40) |
| **Wage Interaction Shift ($\hat{\delta}_2$)** | — | 140.89 | — | 64.03 |
| | | (1.42) | | (0.56) |
| **Price Penalty ($\hat{\theta}_{\kappa p^{\kappa}}$)** | -1.79 | -4.76 | 1.77** | 0.14 |
| | (-1.35) | (-0.71) | (2.41) | (0.05) |
| **Price Interaction Shift ($\hat{\delta}_3$)** † | — | 3.61 | — | -2.28 |
| | | (0.48) | | (-0.20) |
| **Break Level ($\hat{\gamma}_1$)** | — | 0.58 | — | -0.68 |
| | | (0.69) | | (-0.35) |
| Step & Slope Dummies | Yes | Yes | Yes | Yes |
| **<u>Diagnostics</u>** | | | | |
| Residual Variance ($\hat{\sigma}_u$) | 0.051 | **0.020** | 0.035 | 0.026 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Cointegration] | 0.028 | **0.005** | 0.021 | 0.011 |
| Residual ADF ($t_{\text{ADF}}$) [$H_0$: No Cointegration] | -4.928** | **-7.995*** | -4.816** | -6.513*** |
| Standardized Condition Number | 82.2 | 468.2 | 42.9 | 463.2 |
| Regressors ($k$) | 8 | 14 | 8 | 14 |
| Residual d.f. | 34 | 28 | 42 | 36 |
| Sample Size ($T$) | 43 | 43 | 51 | 51 |
| **Break-Aware Gate Status** | **Formal** | **Formal** | **Exploratory** | **Exploratory** |
| Reported Centering Regime | Initial-State | Initial-State | Initial-State | Initial-State |
| **Interaction span** | n/a | **Complete** | n/a | **Complete** |

*‡ New in v8: $\hat{\beta}_{\omega, \text{brk}}$ and $\hat{\beta}_{p^{\kappa}, \text{brk}}$ are the constituents $\omega_{t-1}D_t$ and $p_t^\kappa D_t$ whose absence made v7's centering non-invariant. † $\hat{\delta}_3$ is defined in S02 §3 but absent from the §5 template; the row is added here rather than the parameter dropped. Step controls: Fordism $\mathbf{D}_{1933}$ and war block $\mathbf{B}_{1942\text{--}1945}$; Post-Fordism $\mathbf{D}_{1981}$ and $\mathbf{D}_{2000}$. \* $p<0.10$, \*\* $p<0.05$, \*\*\* $p<0.01$. Columns (1) and (3) are numerically identical to v7.*

**Verdict on the slope-break decision — unchanged.** Inside Fordism none of the three slope shifts is significant ($\hat{\delta}_1 = 4.78$, $t = 0.99$; $\hat{\delta}_2 = 140.89$, $t = 1.42$; $\hat{\delta}_3 = 3.61$, $t = 0.48$), so the additive branch applies exactly as in v7: the disaggregated capacity relation carries no internal *slope* break across 1947. This is the window that clears the break-aware gate formally, and its verdict survives the correction.

**But a level shift at 1947 is now visible, and v7 could not have seen it.** $\hat{\beta}_{\omega, \text{brk}} = 16.78$ ($t = 2.62$, significant at 1%) says the wage share's contribution to capacity shifts sharply at the post-war conversion. This term was **absent from v7's design entirely** — it was the missing span constituent — so its significance is a genuine addition rather than a revision. The reading is that 1947 marks a change in how distribution enters capacity, not a change in the mechanization slope.

**What that parameter means in the analytical model.** $\hat\beta_\omega$ is the contribution of the lagged wage share to potential capacity *at a given mechanization gap* — it is not a cost coefficient but a measure of how far distributional conflict is transmitted into the capacity-generating process. Before 1947 that transmission is negative ($\hat\beta_\omega = -7.12$); after it, the sum $\hat\beta_\omega + \hat\beta_{\omega,\text{brk}} = +9.66$ is positive. The sign reversal has a specific institutional referent. The post-war accord — pattern bargaining, the productivity-linked wage formula written into the 1948 and 1950 auto settlements, and the grievance machinery that stabilised shop-floor effort norms — converted the wage share from a pure cost of production into an index of a settled labour-management relation under which higher wages accompanied, rather than obstructed, capacity growth. Read through the surplus approach: before the accord, a rising wage share signalled unresolved distributional conflict and disrupted the conversion of capital into capacity; after it, the same variable indexes the strength of a regime in which real wage growth was institutionally tied to productivity growth. This is the induced-innovation mechanism operating through an institutional settlement rather than through relative prices, and it is what the Fordist periodization is *for*.

That the break registers on the wage-share **level** rather than on the mechanization **slope** ($\hat\delta_2$, $t = 1.42$) sharpens the claim further: 1947 changes the distributional environment within which technique is chosen, not the technical responsiveness of capacity to the gap itself. That is a cleaner and more interpretable statement of the post-war conversion than v7 could make, and it is the substantive payoff of the correction.

Inside Post-Fordism the picture is unchanged in substance. The wage-squeeze interaction remains significant and negative ($\hat{\theta}_{\omega\kappa} = -45.21^{**}$ against v7's $-45.96^{**}$), no slope shift is significant, and the whole column remains on the **exploratory route** because $\kappa_t$ fails the integration-order gate in exactly this window. Note that v7's most striking number — the gap slope shift $\hat{\theta}_{\kappa,\text{brk}} = 8.54^{***}$, which appeared to reverse the mechanization gap coefficient after 2008 — **does not survive the correction.** On the complete span it is $\hat{\delta}_1 = 1.65$ with $t = 0.14$. Version 7 flagged that estimate as the least entitled to be quoted; it is now clear that it was an artefact of the incomplete span rather than a signal about post-2008 mechanization.

**Cointegration is not in doubt anywhere in this table**, and is markedly stronger than v7 reported in the Fordist interacted column: the Shin statistic sits between 0.005 and 0.028 in all four columns, far below the 10% critical value of 0.095, and the residual ADF rejects no-cointegration in all four. Residual variance falls from 0.051 to 0.020 and from 0.035 to 0.026 when the interaction enters — all four columns far below the S02 §4 anchors of 0.200 uncontrolled and 0.112 controlled.

### Specification B4: excluding the standalone mechanization gap

Table 3.2 carries $\kappa_t$ three times over — as a level, as $\kappa_t\omega_{t-1}$, and as $\kappa_t p_t^\kappa$ — and its condition numbers show the strain: 82.2 and 468.2 in Fordism, 42.9 and 463.2 in Post-Fordism, against a conventional threshold of 30. Specification B4 drops the standalone level on the theoretical grounds set out in §2, retaining $\kappa_t D_t$ as a span constituent, and is estimated on the identical design otherwise.

#### Table 3.3: Spec B3 vs. Spec B4 — conditioning and parameter recovery (IM-OLS, Regime B, complete span)

*Fixed-$b$ HAR $t$-statistics in parentheses. Rows marked B4 exclude the standalone $\kappa_t$ level.*

| Window | Slope int. | Standalone $\kappa$ | CN | $C_{\text{Shin}}$ | $\hat{\sigma}_u$ | $\hat{\theta}_{\text{NRC}}$ | $\hat{\theta}_{\omega\kappa}$ | $\hat{\theta}_{\kappa p^{\kappa}}$ |
|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| Fordist 1929–1973 | No | included (B3) | 82.23 | 0.0282 | 0.051 | 0.33** (2.04) | −2.12 (−0.50) | −1.79 (−1.35) |
| Fordist 1929–1973 | No | **excluded (B4)** | **21.18** | 0.0303 | 0.060 | 0.45*** (3.19) | +3.50 (0.60) | +2.29*** (3.00) |
| Fordist 1929–1973 | Yes | included (B3) | 468.24 | 0.0054 | 0.020 | 0.59*** (3.77) | −174.37* (−1.76) | −4.76 (−0.71) |
| Fordist 1929–1973 | Yes | **excluded (B4)** | 383.27 | 0.0092 | 0.023 | 0.63*** (3.89) | −143.53** (−2.31) | −8.70*** (−3.45) |
| Post-Fordist 1974–2024 | No | included (B3) | 42.94 | 0.0207 | 0.035 | 0.54*** (6.69) | −13.09** (−1.97) | +1.77** (2.41) |
| Post-Fordist 1974–2024 | No | **excluded (B4)** | **33.60** | 0.0203 | 0.037 | 0.59*** (7.69) | −12.30* (−1.80) | +1.38** (2.02) |
| Post-Fordist 1974–2024 | Yes | included (B3) | 463.23 | 0.0107 | 0.026 | 0.79*** (6.45) | −45.21** (−2.40) | +0.14 (0.05) |
| Post-Fordist 1974–2024 | Yes | **excluded (B4)** | 454.72 | 0.0122 | 0.029 | 0.68*** (9.79) | −53.00*** (−2.66) | +3.90* (1.78) |

**What the exclusion buys.** Conditioning improves in every cell. The Fordist uninteracted model falls from 82.2 to 21.18 and remains the one specification in this report that clears $\text{CN} \le 30$ outright; the Post-Fordist uninteracted model improves from 42.9 to 33.6 but still fails. **The interacted cells barely move** (468 → 383, 463 → 455): with the span now complete, the standalone level is no longer the dominant source of collinearity in the interacted designs, so B4 buys much less there than v7's table suggested. That is a change in the case for B4 and it should be stated plainly — the exclusion is well motivated for the uninteracted models and close to inconsequential for the interacted ones.

**The precision gain on plant scale is the robust result.** $\hat{\theta}_{\text{NRC}}$ rises and tightens in all four pairings, most visibly in the interacted Post-Fordist column where it goes from 0.79 ($t = 6.45$) to **0.68 ($t = 9.79$)**. Nonresidential structures are an exceptionally clean extensive-scale anchor once they are not competing with a collinear gap level. This finding survives every specification cut, including the span correction.

**The collinearity is real but not where it was expected.** Measuring the pairwise correlations directly: in Fordism $\text{corr}(\kappa_t,\ \kappa_t p_t^{\kappa}) = +0.9934$ — near-perfect — while $\text{corr}(\kappa_t,\ \kappa_t\omega_{t-1})$ is only $-0.2392$. In Post-Fordism both bind, at $-0.9335$ and $-0.8792$ respectively. So the term that makes the standalone level redundant is the *price* interaction in the Fordist era and both interactions after 1974.

**What the exclusion costs, and what it does not change.** Residual variance rises in every cell (0.051 → 0.060, 0.020 → 0.023, 0.035 → 0.037, 0.026 → 0.029): dropping a regressor buys conditioning at the price of fit. Cointegration is untouched — $C_{\text{Shin}}$ stays between 0.005 and 0.035 under both specifications. Critically, **the break-aware route status does not change**: $\kappa_t$ carries a persistent $I(2)$ risk in Post-Fordism under the §2.5 Lee-Strazicich verdict, and removing the level from the regression does not alter the integration order of the series. Every Post-Fordist figure in Table 3.3, B3 and B4 alike, remains an **exploratory-route** estimate; the Fordist rows remain formally gated.

**On the transformation elasticity.** $\theta_t^{\text{SpecB}}$ is **not** re-derived under B4 or under the corrected span in this version. Its computation runs through the E18 LOESS path-derivative machinery in `COMMON_S40_specB_imols_estimation.R` rather than the break-aware stage, and re-deriving it would require the full 505-model grid re-estimated. The figures in §5 remain the B3-based, uninteracted ones, and no corrected-span trajectory is asserted here. Because the correction changed several break-interacted coefficients materially, **this re-derivation is now the highest-priority outstanding item.**

### Full-sample wage-mechanization break (Spec B4 form, complete span)

`US_S33E` estimates the full sample with a break interacted on the wage-mechanization product alone, which is where §2.6 predicts a regime change. The correction adds $\kappa_t D_t$ and $\omega_{t-1} D_t$ as constituents.

| Parameter | No interaction | With interaction |
|---|:---:|:---:|
| $\hat{\theta}_{\text{NRC}}$ | 0.45*** (6.31) | 0.70*** (10.28) |
| $\hat{\theta}_{\kappa, \text{brk}}$ ‡ | — | **−1.33*** (−2.72) |
| $\hat{\beta}_{\omega}$ | −0.43 (−0.16) | −0.00 (−0.00) |
| $\hat{\beta}_{\omega, \text{brk}}$ ‡ | — | 5.35 (0.93) |
| $\hat{\beta}_{p^{\kappa}}$ | −0.95** (−2.57) | −0.07 (−0.24) |
| $\hat{\theta}_{\omega\kappa}$ | −5.25 (−0.97) | **−15.06** (−2.18) |
| $\hat{\theta}_{\omega\kappa, \text{brk}}$ | — | 8.04 (0.65) |
| $\hat{\theta}_{\kappa p^{\kappa}}$ | 2.15*** (4.27) | 0.77* (1.86) |
| $\hat{\gamma}_1$ | — | 0.77** (2.42) |
| $\hat{\sigma}_u$ | 0.128 | 0.081 |
| $C_{\text{Shin}}$ | 0.036 | 0.020 |
| Residual ADF | −5.684*** | −7.850*** |
| Standardized CN | 32.4 | 76.8 |
| Residual d.f. | 84 | 80 |
| $T_B^*$ | 1969 | 1969 |

*‡ New in v8 as span constituents. $T_B^* = 1969$ is located by Bai-Perron on $\Delta(\kappa_t\omega_{t-1})$, five years from the theoretical 1974.*

The wage-mechanization slope shift $\hat\theta_{\omega\kappa,\text{brk}}$ is **not** significant ($t = 0.65$), so §2.6's predicted regime change in the wage channel is not detected as a slope shift. What is significant is the newly exposed $\hat\theta_{\kappa,\text{brk}} = -1.33$ ($t = -2.72$) — a shift in the gap's own contribution at 1969 — together with a level shift $\hat\gamma_1 = 0.77$ ($t = 2.42$). The wage interaction itself strengthens to $-15.06^{**}$ once the break block is complete. As in the split sample, the correction relocates the detected break from the interaction slope to the constituent terms.

One caution: $\hat\theta_{\kappa p^\kappa}$ remains **sign-unstable across centering** in this specification ($[-0.41,\ 1.08]$), because this design follows the B4 form and omits the standalone $\kappa_t$ level. `US_S33F` established that both a complete span *and* the standalone level are needed for invariance here; Specification B5 (`US_S33G`) carries both and is sign-identified throughout. The B5 report remains the reference for the price channel, subject to the qualification in the next paragraph.

**Cross-reference on the price channel.** `US_S33I` has since estimated A06 §2's nested ladder and found that the price block is **jointly insignificant once the wage-mechanization break is included** ($F = 0.521$, $p = 0.597$ contemporaneous; $F = 0.015$, $p = 0.985$ lagged), and that the sign of $\hat\theta_{\kappa p^\kappa}$ is set by the break specification rather than by the price timing. The §3.2-versus-A06 sign conflict is also narrower than previously recorded: the two derivations address different objects, and A06's formula contradicts A06's own prose. See `A06_S32_PriceChannel_Reconciliation.md`.

**On the preliminary evidence.** The LOESS-based and pairwise integration-order groundwork in `reports/US_Capital_Composition_Integrated_Report/us_capital_composition_integrated_report.pdf` motivated the candidate break dates used above and is cited only in that capacity. It does not satisfy the S0\* pre-testing requirement. That distinction has bite: the formal Bai-Perron search does *not* recover 1933, 1968 or 1982 in the Spec B system, and locates its breaks in the relative price series rather than in the capital composition residual the LOESS diagnosis pointed to.

---

## 3. Empirical Results Matrix & Robustness (505-Model Combinatory)

*Unchanged from v7. These are uninteracted designs and carry no break products.*

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

These are unmodified by v8 and are `\input` directly when the `.tex` manuscript is compiled.

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

*These figures rest on the uninteracted B3 parameters and are unaffected by the span correction. They do **not** incorporate the corrected break-interacted coefficients; see the note in §2.5A.*

---

## 6. Summary of Key Empirical Findings & Takeaways

The empirical estimations establish four key findings for the dissertation committee:

1. **Distributionally Conditioned Mechanization Choice**: Under Initial-State centering with step controls, the interaction parameter $\hat{\theta}_{\omega \kappa}$ remains positive and statistically significant ($\hat{\theta}_{\omega \kappa} = 15.40^{***}$). Rising labor share drives intensive machinery accumulation relative to plant structures.
2. **Cointegration Hygiene and Variance Reduction**: Step controls eliminate non-stationary residual drift ($C_{\text{Shin}}$ drops from 0.261 to 0.042) and reduce residual variance ($\hat{\sigma}_u$ drops from 0.200 to 0.112).
3. **Stagnation Gap Recovery**: Reconstructed capacity utilization under Specification B recovers a 50 percentage point capacity utilization gap post-2000 relative to aggregate Specification A, identifying post-GFC industrial stagnation driven by machinery investment decline.
4. **Severe Capital Overaccumulation Regime ($\theta_t^{\text{SpecB}} < 1.0$)**: The total aggregate transformation elasticity averages $0.41$ over 1929–2024 and turns negative (reaching $-0.27$) in the post-2000 era.

Version 7's three break-aware findings survive the v8 correction, one of them substantially revised:

5. **Disaggregated Capital Is $I(1)$ With Breaks, Not $I(2)$ — Except Post-2008 Mechanization**: Unchanged. The Lee-Strazicich verdict is prior to the estimation design and is untouched by the span correction. The Post-Fordist $\kappa_t$ exception continues to place that entire column on the exploratory route.
6. **The Formal Window Contains No Internal Slope Break — But Does Contain a Level Shift**: Fordism clears the break-aware gate on all three base variables, and in that window none of $\hat{\delta}_1$, $\hat{\delta}_2$ or $\hat{\delta}_3$ is significant, exactly as v7 found. **What is new is that the wage-share level shift at 1947 is significant at 1% ($\hat{\beta}_{\omega,\text{brk}} = 16.78$, $t = 2.62$)** — a term absent from v7's design. The post-war conversion changes how distribution enters capacity, not how mechanization does. Version 7's striking post-2008 gap slope shift ($8.54^{***}$) **does not survive**: on the complete span it is $1.65$ with $t = 0.14$, and was an artefact of the incomplete design.
7. **Formal Break Testing Relocates the Breaks Away From Capital Composition**: Unchanged. Bai-Perron finds no growth-rate break in $\kappa_t$ in any window and locates its breaks in $p_t^{\kappa}$ instead. Of the five S02 candidates only 1947 and 2008 are recovered within two years.

Version 8 adds two findings of its own:

8. **The Omitted Span Constituent Was a Real Term, Not a Technicality**: $\omega_{t-1}D_t$ is significant at 1% in the Fordist interacted design. Restoring it halves the residual variance (0.041 → 0.020), cuts the Shin statistic sixfold (0.033 → 0.005) and strengthens the residual ADF from $-4.58^{**}$ to $-8.00^{***}$. Version 7's Fordist interacted column was fitting a misspecified model, and the correction is not a formality but a substantive improvement in that window.
9. **Sign-Stability Is Necessary, Not Sufficient — and the Split-Sample Interacted Designs Are at Their Limit**: Five interaction-class parameters gained sign-stability across centering under the correction and one lost it. But the headline gain, the Fordist $\hat{\theta}_{\omega\kappa}$, is sign-stable at $-95$ to $-174$ with a condition number of 468 on 28 residual degrees of freedom — magnitudes consistent with an over-specified design rather than a recovered parameter. Meanwhile the exclusion case for B4 weakens in exactly these cells: with the span complete, dropping the standalone level barely improves conditioning in the interacted models (468 → 383, 463 → 455). The honest reading is that **the split-sample break-interacted specification is not viable at $T = 43$ and $T = 51$ with 14 regressors**, and the full-sample tracks — `US_S33E` and especially Specification B5 — are where the break-interacted evidence should be taken.

---

## Reproduction

All Section 2.5 and 2.5A results are generated by the `US_S33*` family:

```bash
Rscript codes/US_S33A_bai_perron_split_sample_prescan.R
```

```bash
Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R
```

```bash
Rscript codes/US_S33D_break_interacted_imols_specB.R
```

```bash
Rscript codes/US_S33E_break_interacted_imols_specB_full_sample.R
```

```bash
Rscript codes/US_S33I_price_channel_discrimination.R
```

Ledgers: `output/US/BREAK_AWARE_IMOLS/S33A_BAI_PERRON/csv/`, `.../S33B_LEE_STRAZICICH/csv/`, `.../S33D_IMOLS_SPEC_B/csv/`, `.../S33E_IMOLS_SPEC_B_FULL_SAMPLE/csv/`, `.../S33I_PRICE_CHANNEL_DISCRIMINATION/csv/`. The span-correction impact tables are `specB_span_correction_impact.csv` and `specB_full_sample_span_correction_impact.csv` in the S33D and S33E trees. Each stage writes a stage-integrity ledger and halts if any check fails; `US_S33D` carries 17 checks and `US_S33E` 11, both including `interaction_span_complete`. The centering-invariance mechanism is demonstrated on synthetic data by `codes/US_S33F_centering_invariance_diagnostic.R`. Handoff note: `chapter2_vault/80_Prompts/handoffs/2026-07-30_us_breakaware_imols_handoff.md`.
