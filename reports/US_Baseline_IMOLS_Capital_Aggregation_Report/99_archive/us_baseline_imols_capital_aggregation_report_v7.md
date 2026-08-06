# DISSERTATION PROGRESS REPORT & ONLINE APPENDIX
## Chapter 2: Empirical Grounding, Capacity Reconstruction, and the Overaccumulation Regime (Specification A)

**Author:** Diego Polanco (Department of Economics, UMass Amherst)  
**Advisor:** Michael Ash  
**Date:** July 2026  
**Compiled Artifact:** `us_baseline_imols_capital_aggregation_report_v7.pdf`  
**Supersedes:** `us_baseline_imols_capital_aggregation_report_v6.pdf` (retained unmodified)

---

## Executive Summary

This progress report provides the complete, paper-facing empirical appendix for **Specification A (Single Aggregate Capital Model)** of Chapter 2. I evaluate the full range of 168 estimated IM-OLS cointegrating regressions across four master comparative matrices comparing specifications **With Step Controls ($\boldsymbol{\Lambda}\mathbf{D}_t' = \text{Yes}$)** against **Without Step Controls ($\boldsymbol{\Lambda}\mathbf{D}_t' = \text{No}$)**:
1. **Full Sample Baseline Matrix (1929–2024)** across Centering Treatments;
2. **Accumulation Eras Comparative Matrix** comparing Fordism (1929–1973) vs. Post-Fordism (1974–2024);
3. **Multi-Wage Share Robustness Matrix** comparing Baseline NFC GVA, Corporate GVA, Shaikh-Tonak Tier 1, and Shaikh-Tonak Tier 2 wage measures; and
4. **Macroeconomic Sub-Window Diagnostic Matrix** evaluating Interwar & WWII, Golden Age, Neoliberal Restructuring, and Post-GFC Stagnation subwindows.

**What v7 corrects.** Version 6's break-interacted design in Table X was incomplete. The interacted term $(k_t^{\text{cap}} \cdot \omega_{t-1}) \cdot D_t$ was estimated without the constituent $\omega_{t-1} \cdot D_t$, which means centering the base series was **changing the model rather than reparameterizing it**. Section 2.0A documents the defect, the correction, and its costs. The Fordist finding survives and strengthens; the Post-Fordist finding survives unchanged in substance while two of its point estimates change sign. The four master matrices in Section 2 are unaffected — they carry no break interactions — and are reproduced unchanged.

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

### 2.0A The interaction-span correction

**The defect.** When a break-interacted product enters the design, centering the base series expands it. For the Specification A interaction,

$$(k^{\text{cap}} - k_0)(\omega - w_0)\, D_t = (k^{\text{cap}} \omega) D_t - k_0 (\omega D_t) - w_0 (k^{\text{cap}} D_t) + k_0 w_0 D_t$$

so the design must span all four of $(k^{\text{cap}}\omega)D_t$, $\omega D_t$, $k^{\text{cap}} D_t$ and $D_t$ for centering to be a **reparameterization**. Version 6 carried $k^{\text{cap}} D_t$ and $D_t$ but **not $\omega D_t$**. With a constituent missing, the three centering regimes are not three views of one model; they are three different models, and the regime silently selects the parameter values.

The mechanism was verified on synthetic data with a known data-generating process (`US_S33F`): the relative spread of OLS estimates across the three regimes is $6\times10^{-16}$ with a complete span, $7.8\times10^{-2}$ once the product enters without its constituents, and $6\times10^{-16}$ again when they are restored. It is not an IM-OLS artefact and not ill-conditioning — forcing the condition number to 181 leaves the spread at 0.26%.

**The correction.** `US_S33C` now builds the break block through a shared helper (`s33_break_span()`) that includes every lower-order constituent by construction, and a guard (`s33_assert_complete_span()`) halts the stage if any product appears without them. The same correction was applied to the Specification B tracks; see the v8 report.

**Version 6 contained the evidence against itself.** The combinatorial break-permutation grid (`specA_break_combinatorics_summary.csv`, reported as the Combinatorial Structural Break Shift Analysis in the compiled PDF) enumerates the break block over all $2^3$ permutations of $\{k^{\text{cap}}D_t,\ \omega D_t,\ (k^{\text{cap}}\omega)D_t\}$ alongside $D_t$, and therefore *already carried a complete span* at its fully-saturated permutation, SpecA-7. That grid is **byte-identical before and after this correction**, and its SpecA-7 cell reproduces the corrected main design exactly:

| | Fordist CN | Fordist $\hat\sigma_u$ | Fordist $C_{\text{Shin}}$ | Fordist ADF | Post-F. CN | Post-F. $\hat\sigma_u$ |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| Combinatorics SpecA-7 (v6 **and** v7) | 50.60 | 0.0570 | 0.0520 | −4.363 | 358.99 | 0.0441 |
| Main design, corrected (v7 Table X) | 50.60 | 0.0570 | 0.0520 | −4.363 | 358.99 | 0.0441 |

Version 6 thus reported two mutually inconsistent estimates of the same specification in the same document — a Table X built on a broken span and a combinatorics table built on a complete one — and cited the combinatorics condition numbers (50.60, 358.99) in its own text while Table X rested on different ones. The correction removes that inconsistency rather than introducing a new set of numbers, which is the strongest available check that the corrected design is the intended one.

**What it cost.** The correction is required by algebra, not chosen for its results, and it made two things worse. Both are reported here rather than left to inference.

| Cell | Regressors ($k$) | Residual d.f. | Standardized CN | $\hat\sigma_u$ | $C_{\text{Shin}}$ |
|---|:---:|:---:|:---:|:---:|:---:|
| Fordist, interacted | 8 → **9** | 34 → **33** | 48.7 → **50.6** | 0.058 → 0.057 | 0.031 → 0.052 |
| Post-Fordist, interacted | 8 → **9** | 42 → **41** | 79.1 → **359.0** | 0.044 → 0.044 | 0.035 → 0.036 |

*Reported regime (initial-state centering). Non-interacted columns are unaffected — they carry no break products — and are numerically identical to v6.*

The Post-Fordist conditioning deterioration is severe: adding the required constituent multiplies the condition number by 4.5. Neither cell cleared the CN $\le 30$ gate before the correction and neither does after, so no verdict changes, but the interacted Post-Fordist design is now the worst-conditioned in the Specification A track.

**What it fixed, and what it did not.** Of the six interaction-class parameters in the interacted cells, none gained sign-stability and none lost it. The correction did **not** repair the headline instability:

| Cell | Parameter | v6 centering range | v7 centering range | Sign-stable |
|---|---|:---:|:---:|:---:|
| Fordist | $\hat\theta_1$ | $[-5.899,\ 3.459]$ | $[-15.217,\ 4.166]$ | **No**, before and after |
| Fordist | $\hat\delta_2$ | $[-6.972,\ 0.406]$ | $[-9.795,\ 9.588]$ | **No**, before and after |
| Post-Fordist | $\hat\theta_1$ | $[1.280,\ 3.625]$ | $[1.284,\ 3.601]$ | Yes, before and after |
| Post-Fordist | $\hat\delta_2$ | $[-1.083,\ -0.177]$ | $[1.515,\ 3.832]$ | Yes — **but the sign flipped** |

Two points follow, and neither is comfortable. First, **the Fordist interacted $\hat\theta_1$ remains centering-dependent even on a complete span.** Span completeness is necessary for invariance, not sufficient; with $T = 43$ observations against nine regressors the Fordist window is too thin to identify the interaction, and that is a finding about the split-sample design rather than about the correction. The Fordist interacted $\hat\theta_1$ should not be quoted for either sign. Second, **the Post-Fordist $\hat\delta_2$ moved from stably negative to stably positive.** It is insignificant in both versions ($t = -0.33$ in v6, $t = 0.43$ in v7), so no conclusion rests on it, but a sign-stable parameter reversing on a design change is a warning about how much weight sign-stability alone can carry.

The corrected estimates are the ones to use. The v6 values were produced by a design in which the centering convention was doing part of the estimating.

> **A size caveat on the interacted diagnostics.** The interacted designs carry $k = 9$ regressors on $T = 43$ and $T = 51$ observations, leaving 33 and 41 residual degrees of freedom. The Shin LM statistic and the residual ADF are read against **asymptotic** critical values, and both are over-sized at these sample lengths — the Lee-Strazicich critical values used at the pre-testing stage carry the same caveat, being tabulated at $T = 100$. No residual bootstrap was run for the IM-OLS diagnostics. The Fordist residual ADF weakening from $-4.76^{**}$ to $-4.36^{*}$ under the correction sits well inside the range where size distortion could account for the difference, so it should be read as "the Fordist cointegration margin is thin" rather than as a measured deterioration. Bootstrapping these statistics is recorded as an outstanding item.

### Consolidated specification verdict

Mapping each Specification A design to its theoretical basis, stochastic evidence, and disposition:

| Design | Theoretical basis | Integration-order gate | Conditioning | Sign-identification | Disposition |
|---|---|---|---|---|---|
| Fordist, uninteracted | S01 §3 baseline | **Exploratory** ($\omega_{t-1}$ trend-stationary) | CN 12.2, **passes** $\le 30$ | n/a | **Held** — well-conditioned but route status blocks formal claims |
| Fordist, interacted | S01 §5 slope shift at 1947 | **Exploratory** | CN 50.6, fails | $\hat\theta_1$ **unstable** $[-15.2, 4.2]$ | **Held as diagnostic** — $\hat\delta_1$ interpretable, $\hat\theta_1$ is not |
| Post-Fordist, uninteracted | S01 §3 baseline | **Exploratory** ($k^{\text{cap}}$ trend-stationary) | CN 29.7, **passes** $\le 30$ | n/a | **Held** |
| Post-Fordist, interacted | S01 §5 slope shift at 2008 | **Exploratory** | CN 359.0, fails badly | $\hat\theta_1$ stable, $\hat\delta_2$ stable but sign-reversed vs v6 | **Held as diagnostic** — no slope shift significant |
| Full sample + era matrices (A1–A4) | v5 reference designs | not break-gated | varies | n/a | **Reference results** — carry no break products, unaffected |
| FWL-residualized interactions | — | — | — | — | **Blocked** — E10V: partial summation does not commute with projection |

The pattern is that **conditioning and identification move in opposite directions to the break interaction**: the two uninteracted designs clear $\text{CN} \le 30$ but cannot address the break question, while the two designs that can address it fail conditioning and, in the Fordist case, fail sign-identification as well. That trade is the honest summary of what Specification A can support on split samples.

### 2.0 Break-Aware Integration-Order Pre-Testing (S0\* Protocol)

The estimates in Section 2 rest on two claims that v5 asserted rather than tested: that $k_t^{\text{cap}}$ is $I(1)$, and that the step-control dates mark real structural breaks. The S0\* protocol notes locked on 2026-07-30 make both testable, in a fixed order — Bai-Perron locates candidate breaks on stationary first differences, Lee-Strazicich verifies integration order under broken deterministics, and only then does break-interacted IM-OLS run. That sequence was executed fresh; the ledgers are under `output/US/BREAK_AWARE_IMOLS/`.

One framing point governs everything below. **The split samples are historical, not estimated.** Fordism runs to 1973 and Post-Fordism from 1974, and no break test is permitted to revise that periodization. What the break tests locate are *within-sample* structural breaks — the Depression, war mobilization, the Volcker disinflation — that must be controlled for the estimation to be adequate. A Bai-Perron date landing in 1942 is a statement about war production, not a rival account of when Fordism began.

**Step 1 — Bai-Perron (1998, 2003).** The sequential search ran on the stationary first-differenced vector $\Delta\mathbf{Y}_t = [\Delta y_t, \Delta k_t^{\text{cap}}, \Delta\omega_t]'$, never on levels, within each sub-sample separately: Fordist trimming $\epsilon = 0.20$, Post-Fordist $\epsilon = 0.15$, maximum three breaks. Breaks are admitted only when UDmax rejects at 5% *and* the sequential $\sup F_T(l+1|l)$ rejects, which is stricter than reading the selected break count off the estimator. Inside Fordism the procedure locates a single break at **1939** in the capital growth rate (95% CI 1932–1955) and at **1942** in the differenced relation (95% CI 1938–1949); $\Delta y_t$ and $\Delta\omega_t$ carry no breaks at all. Inside Post-Fordism it locates **1981** (95% CI 1980–1983), **2000** (95% CI 1998–2004) and **2010** (95% CI 2005–2017). The protocol's Post-Fordist candidates are recovered almost exactly — 1982 at a distance of one year, 2000 exactly, 2008 within two. The Fordist candidates are not recovered as point estimates: 1933 sits six years from the nearest estimate and 1947 five. Both nonetheless fall inside the 95% confidence intervals of the Fordist break dates, so the honest statement is that the Fordist window contains one poorly-identified break somewhere between the Depression and the post-war conversion, not that 1947 is refuted. $WD_{\max}$ is listed in S03 §2A but is not exposed by `mbreaks` 1.0.1; it is recorded as unavailable rather than approximated.

**Step 2 — Lee-Strazicich (2003) Minimum-LM.** The test comes from the mandated external engine at `C:\ReposGitHub\LeeStrazicichUnitRoot`; no substitute was written. Two deviations are on the record and both matter for reading the numbers. First, `ur.ls()` locates breaks *endogenously* by grid-minimising the LM statistic and accepts no fixed-date argument, so the test could not be run "at the Bai-Perron dates" as S01 §2 Step 2 requests; it was run as designed and a date-concordance ledger reports the agreement separately. Second, and more consequentially, the S03 §2C decision matrix reads a *levels* rejection as evidence of $I(1)$ and a levels non-rejection as evidence of $I(2)$. That inverts the standard logic: an $I(1)$ series has a unit root in levels, so failing to reject in levels is exactly what it must do. Applied literally, the matrix classified $k_t^{\text{cap}}$ as an $I(2)$ risk in almost every window — a pre-testing stage diagnosing itself rather than the data. The discriminating test, and what S03 §2B says it wants when it speaks of "eliminating spurious $I(2)$ classification", is the LM test on the *first difference*. Both were run and the verdict is taken on the pair.

Read that way the evidence is clean. Under Model C, with breaks in intercept and trend under both hypotheses, $k_t^{\text{cap}}$ does not reject the unit root in levels ($LM = -3.62$ against a 5% value of $-5.67$ in Fordism) and rejects decisively in first differences ($LM = -7.38$): **$k_t^{\text{cap}}$ is $I(1)$ with breaks, not $I(2)$**, which is what the v5 estimation assumed and can now assert. The same verdict holds for $y_t^{\text{NFC}}$ in both eras and for $k_t^{\text{cap}}$ over the full sample. Two exceptions are genuine and are not smoothed over: $\omega_{t-1}$ rejects the unit root *in levels* over the full sample and within Fordism, making it trend-stationary around breaks rather than $I(1)$; and $k_t^{\text{cap}}$ likewise rejects in levels within Post-Fordism. Fourteen of eighteen variable-window cells clear the gate. Every Lee-Strazicich critical value is tabulated at $T = 100$ while these windows carry $T = 43$ and $T = 51$, so the test is over-sized in the sub-samples and the marginal cases should be read with that in mind.

**Step 3 — Break-interacted IM-OLS.** Because $\omega_{t-1}$ (Fordism) and $k_t^{\text{cap}}$ (Post-Fordism) do not clear the gate as $I(1)$, **both eras are estimated on the exploratory route, not the formal one.** Following the honesty standard used in the Chile S40/S50 chronology, estimation still runs and the label travels with every coefficient: nothing in Table X below is a formally gated result, and none of it should be quoted as one. The estimator remains IM-OLS under the E10V lock, with DOLS run only as a diagnostic comparator, and the interaction terms enter the design raw — the FWL prohibition is enforced structurally, not by assertion.

Two implementation notes belong in the record. The multiplicative slope shift is placed at the protocol dates $T_B^* = 1947$ (Fordism) and $T_B^* = 2008$ (Post-Fordism) exactly as S01 §5 pins them, while the Bai-Perron dates enter *additively* as step controls: a permanent step at 1933 for the New Deal regime change and a 1942–1945 block that switches back off for war mobilization, since war output is a level distortion that reverses rather than a permanent shift, plus permanent steps at 1981 and 2000 in Post-Fordism. And the uncentered design is numerically unusable here — the standardized condition number runs between 3054 and 39664 under Regime A against 12 to 359 under initial-state centering — so all reported estimates use **Regime B (initial-state centering)**, which is the AGENTS.md instruction to log the condition number and default to Regime B rather than block.

#### What the raw series do, before any estimation

The estimates below should be read against the unconditional growth record (mean annual log change, per cent per year, computed without calling any estimator):

| Series | Full sample 1929–2024 | Fordism 1929–1973 | Post-Fordism 1974–2024 |
|---|:---:|:---:|:---:|
| Corporate value added $y^{\text{NFC}}$ | 3.89 | **4.93** | **3.12** |
| Aggregate productive capital $k^{\text{cap}}$ | 5.89 | 5.92 | 5.57 |
| Wage share $\omega_{t-1}$ | −0.08 | +0.01 | −0.16 |

One fact organises everything the parametric work can say. **Output growth falls by more than a third across the periodization (4.93 → 3.12) while capital growth barely moves (5.92 → 5.57).** Capital keeps accumulating at close to its Fordist rate while the capacity it generates decelerates sharply — which is the descriptive content of $\theta_t < 1$, visible in the raw series before any cointegrating regression is run. The wage share turns from flat to falling ($+0.01$ to $-0.16$), so the post-1974 decline in capacity growth cannot be attributed to a wage squeeze in the ordinary sense: distribution moved *in favour of capital* over precisely the window in which capital's capacity yield deteriorated. The interaction parameter $\theta_1$ exists to hold that tension, and the estimates below should be judged by whether they can.

#### Table X: Sub-Sample Internal Slope Break Cointegration Matrix (IM-OLS, complete interaction span)

*Dependent variable: log real non-financial gross value added ($y_t^{\text{NFC}}$). Fixed-$b$ HAR $t$-statistics in parentheses.*

| Parameter / Diagnostic | (1) Fordist, No Interaction | (2) Fordist, With Interaction | (3) Post-Fordist, No Interaction | (4) Post-Fordist, With Interaction |
|---|:---:|:---:|:---:|:---:|
| Internal Slope Interaction | No | Yes | No | Yes |
| Internal Break Date ($T_B^*$) | 1947 | 1947 | 2008 | 2008 |
| **Capital Stock ($\hat{\beta}_{\text{Kcap}}$)** | 0.82*** | 1.80*** | 0.85*** | 0.88*** |
| | (30.63) | (5.72) | (12.69) | (16.47) |
| **Capital Slope Shift ($\hat{\delta}_1$)** | — | -0.95*** | — | 0.10 |
| | | (-3.01) | | (0.17) |
| **Wage Share ($\hat{\phi}_{\omega}$)** | -4.75* | -2.51** | -2.88 | -3.79 |
| | (-1.82) | (-2.25) | (-1.18) | (-1.23) |
| **Wage Share Level Shift ($\hat{\phi}_{\omega, \text{brk}}$)** | — | 4.93 | — | -8.90 |
| | | (1.16) | | (-0.45) |
| **Interaction Squeeze ($\hat{\theta}_1$)** | -1.52 | 4.17 | 2.82** | 1.55 |
| | (-0.99) | (0.41) | (2.39) | (0.96) |
| **Interaction Slope Shift ($\hat{\delta}_2$)** | — | -9.79 | — | 3.57 |
| | | (-0.94) | | (0.43) |
| **Break Level ($\hat{\gamma}_1$)** | — | -0.07 | — | -0.64 |
| | | (-1.27) | | (-0.47) |
| Step Dummies ($\mathbf{D}_t$) | Yes | Yes | Yes | Yes |
| **<u>Diagnostics</u>** | | | | |
| Residual Variance ($\hat{\sigma}_u$) | 0.096 | 0.057 | 0.074 | 0.044 |
| Shin LM ($C_{\text{Shin}}$) [$H_0$: Cointegration] | 0.185*** | 0.052 | 0.330*** | 0.036 |
| Residual ADF ($t_{\text{ADF}}$) [$H_0$: No Cointegration] | -2.805 | -4.363* | -4.194* | -5.958*** |
| $R^2_{\text{level}}$ | 0.981 | 0.994 | 0.977 | 0.992 |
| Standardized Condition Number | 12.2 | 50.6 | 29.7 | 359.0 |
| Regressors ($k$) | 5 | 9 | 5 | 9 |
| Residual d.f. | 37 | 33 | 45 | 41 |
| Sample Size ($T$) | 43 | 43 | 51 | 51 |
| **Break-Aware Gate Status** | Exploratory | Exploratory | Exploratory | Exploratory |
| Reported Centering Regime | Initial-State | Initial-State | Initial-State | Initial-State |
| **Interaction span** | n/a | **Complete** | n/a | **Complete** |

*Step controls: Fordism $\mathbf{D}_{1933}$ and war block $\mathbf{B}_{1942\text{--}1945}$; Post-Fordism $\mathbf{D}_{1981}$ and $\mathbf{D}_{2000}$. \* $p<0.10$, \*\* $p<0.05$, \*\*\* $p<0.01$. The $\hat{\phi}_{\omega, \text{brk}}$ row is new in v7: it is the constituent $\omega_{t-1} D_t$ whose absence made v6's centering non-invariant. Columns (1) and (3) are numerically identical to v6.*

**Verdict on the S01 §3 decision matrix — unchanged, and better supported.** Inside Fordism the capital slope shift is significant and the correction *strengthens* it, from $\hat{\delta}_1 = -0.98$ ($t = -2.26$, 5%) in v6 to $\hat{\delta}_1 = -0.95$ ($t = -3.01$, **1%**). The multiplicative interaction is retained and the elasticity is reported as two sub-regimes: $\hat{\beta}_{\text{Kcap}}$ falls from **1.80 before 1947 to 0.85 after it**, essentially the v6 reading (1.84 → 0.86) on a design that now supports it. That estimate remains exploratory, not formally gated, because $\omega_{t-1}$ is trend-stationary rather than $I(1)$ in this window.

**What that halving means in the analytical model.** $\beta_{\text{Kcap}}$ is the long-run elasticity of potential capacity to aggregate productive capital — the rate at which accumulated means of production are converted into capacity to produce. A value above unity before 1947 says that capital accumulation was *more* than proportionally capacity-generating during the Depression and war-mobilization years; a value of 0.85 after says it became less than proportionally so. Read as a regime signature rather than a technical constant, the shift dates the exhaustion of the extraordinary conversion conditions of the 1930s and 1940s: idle capacity available for wartime requisition, state-directed investment in plant that entered the private capital stock at below-market cost, and a labour process reorganised under conditions where effort norms were set by mobilization rather than by bargaining. Once those conditions lapse, the same accumulated capital yields proportionally less capacity, and the economy enters the $\theta_t < 1$ corridor that the aggregate elasticity in finding 4 tracks for the rest of the century. The break is therefore not a statistical nuisance to be absorbed by a dummy; it is the point at which the accumulation regime's conversion efficiency changes, and treating 1947 as a mere variance-hygiene control would discard that.

The wage-share level shift $\hat\phi_{\omega,\text{brk}} = 4.93$ is positive but insignificant ($t = 1.16$), so the aggregate specification cannot detect a corresponding change in how distribution enters capacity. The disaggregated Specification B does detect one, at 1% — see the v8 report §2.5. That the aggregate model misses what the disaggregated model finds is itself an argument for the disaggregation, since aggregating $K^{\text{ME}}$ and $K^{\text{NRC}}$ into $K^{\text{cap}}$ averages away the margin on which the distributional mechanism operates.

Inside Post-Fordism neither slope shift is significant ($\hat{\delta}_1 = 0.10$, $t = 0.17$; $\hat{\delta}_2 = 3.57$, $t = 0.43$), so the S01 §3 "NO" branch applies exactly as in v6: the capital elasticity is structurally invariant at $\hat{\beta}_{\text{Kcap}} = 0.88$ across 2008, and the step dummies are retained strictly for variance hygiene. **Both slope-shift point estimates changed sign** between v6 and v7 ($-0.14 \to 0.10$ and $-0.25 \to 3.57$). Neither was distinguishable from zero in either version, which is precisely why the conclusion is unaffected — but it is a direct demonstration that unidentified coefficients in a span-broken design carry no information, not even about their sign.

**The break controls still repair the cointegration diagnostics, with one qualification.** Without the interaction, the Shin LM statistic rejects the cointegration null in both eras ($C_{\text{Shin}} = 0.185^{***}$ in Fordism, $0.330^{***}$ in Post-Fordism). With it, both fall below the 10% critical value (0.052 and 0.036) and residual variance falls from 0.096 to 0.057 and from 0.074 to 0.044, in both cases far below the S01 §2 Step 3 baselines of 0.158 and 0.184. The qualification is Fordist: the residual ADF now reads $-4.363^{*}$ where v6 reported $-4.759^{**}$, so the Fordist cointegration evidence is **weaker on the corrected design** — significant at 10% rather than 5%. The Post-Fordist ADF is essentially unchanged ($-5.958^{***}$ against $-5.976^{***}$). The specification finding holds; its Fordist margin is thinner than v6 implied.

**On the preliminary evidence.** The LOESS-based and pairwise integration-order groundwork in `reports/US_Capital_Composition_Integrated_Report/us_capital_composition_integrated_report.pdf` motivated the candidate break dates used above and is cited only in that capacity. It does not satisfy the S0\* pre-testing requirement, and the Bai-Perron → Lee-Strazicich → IM-OLS sequence reported here was run fresh rather than inherited from it.

### Master Comparative Appendix Tables

*The four matrices below are reproduced unchanged from v5 and v6. They are estimated on the full-sample and era designs without the internal slope-break terms of Table X, carry no break-interacted products, and are therefore untouched by the span correction. They remain the reference results for Specification A.*

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

Version 6 added two findings from the break-aware pre-testing stage; both survive the v7 correction, the first unchanged and the second strengthened:

5. **The Capital Stock Is $I(1)$ With Breaks, Not $I(2)$**: The Lee-Strazicich Minimum-LM test under broken deterministics does not reject a unit root in the levels of $k_t^{\text{cap}}$ and rejects decisively in first differences ($LM = -7.38$ in Fordism, $-6.94$ over the full sample). The integration order that v5 assumed is now established, and the spurious $I(2)$ reading that broken deterministic trends can produce is ruled out. Two variables fail this gate — $\omega_{t-1}$ is trend-stationary around breaks in Fordism and over the full sample, and $k_t^{\text{cap}}$ is trend-stationary within Post-Fordism — which is why every Table X estimate is reported on the exploratory route rather than as a formally gated result. *(Unaffected by the span correction: integration-order testing is prior to the estimation design.)*
6. **Fordism Contains an Internal Slope Break; Post-Fordism Does Not**: On the corrected span, the capital slope shift at 1947 is significant at 1% ($\hat{\delta}_1 = -0.95$, $t = -3.01$, against $t = -2.26$ in v6) and halves the aggregate capital elasticity from 1.80 to 0.85 across the post-war conversion, so the S01 §3 decision matrix retains the multiplicative interaction and the Fordist elasticity is reported as two sub-regimes. Neither slope shift is significant at 2008 — both changed sign under the correction while remaining insignificant — so the Post-Fordist elasticity is structurally invariant at 0.88 and its step dummies serve variance hygiene alone. Modelling the within-sample break structure repairs the cointegration diagnostics in both eras: $C_{\text{Shin}}$ falls from $0.185^{***}$ to 0.052 in Fordism and from $0.330^{***}$ to 0.036 in Post-Fordism, with the residual ADF at $-4.36^{*}$ and $-5.96^{***}$ respectively.

Version 7 adds one finding of its own, and it is a negative one:

7. **The Fordist Interaction Is Not Identified, Even on a Complete Span**: $\hat{\theta}_1$ in the Fordist interacted design spans $[-15.217,\ 4.166]$ across the three centering regimes and does not hold its sign. Completing the interaction span was necessary — without it the centering convention was selecting the estimate — but it was not sufficient. With $T = 43$ observations and seven slope columns the window cannot support the break-interacted specification, and **no sign should be claimed for the Fordist interaction squeeze**. This is a limitation of the split-sample design, not of the correction; the full-sample Specification B5 track, which carries a complete span on $T = 94$, is sign-identified throughout.

---

## Reproduction

All Section 2.0 and 2.0A results are generated by the `US_S33*` family and can be reproduced end to end:

```bash
Rscript codes/US_S33A_bai_perron_split_sample_prescan.R
```

```bash
Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R
```

```bash
Rscript codes/US_S33C_break_interacted_imols_specA.R
```

Ledgers: `output/US/BREAK_AWARE_IMOLS/S33A_BAI_PERRON/csv/`, `.../S33B_LEE_STRAZICICH/csv/`, `.../S33C_IMOLS_SPEC_A/csv/`. The span-correction impact table in Section 2.0A is `.../S33C_IMOLS_SPEC_A/csv/specA_span_correction_impact.csv`. Each stage writes a stage-integrity ledger and halts if any check fails, so a completed run is self-certifying; `US_S33C` carries 15 checks including `interaction_span_complete`. The centering-invariance mechanism is demonstrated on synthetic data by `codes/US_S33F_centering_invariance_diagnostic.R`. Handoff note: `chapter2_vault/80_Prompts/handoffs/2026-07-30_us_breakaware_imols_handoff.md`.
