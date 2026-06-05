# §2.7 — Stage C: Investment Function Estimation
**Source authority:** `Ch2_Outline_DEFINITIVE.md` §2.7; `ch2_section_prompts.md` §2.7.1–§2.7.6
**Date drafted:** 2026-04-02
**Word count:** ~1200
**Self-check:** PASS
**Transition check:** Opens from §2.6.4 (Stage A derived objects enter as regressors); closes to §2.8 (results).

---

The empirical strategy of Stage C follows directly from the two-layer identification established in §2.3. Layer 1 identifies three distinct channels through which profitability composes the accumulation rate — demand ($\mu$), technology ($b$), and distribution ($\pi$) — and requires that they enter the investment function separately by default. Layer 2 provides the behavioral interpretation: each coefficient measures the recapitalization elasticity relative to the Cambridge accounting benchmark, where $\psi_j = 1$ implies mechanical reinvestment and $\eta_j = \psi_j - 1$ measures the behavioral deviation. The FM spec is therefore the primary estimating equation. The Keynes-Robinson and Bhaduri-Marglin specifications are not steps in an ascending-complexity ladder; they are economically motivated compressions whose empirical warrant is tested via Wald restrictions within the FM framework.

## §2.7.1 ARDL Estimation Architecture

Stage C estimates all investment function specifications via the autoregressive distributed lag bounds-testing procedure of Pesaran, Shin, and Smith (2001). The choice of framework is not arbitrary: the regressors include a mixture of $I(0)$ and $I(1)$ variables — $\ln \widehat{\mu}_t$ is stationary by construction from the rank-1 identification of Stage A, while $\ln \pi_t$ and $\ln \widehat{B}_t$ are plausibly integrated — and the PSS procedure does not require pre-classification of integration order. Cointegration in the FM spec is structurally guaranteed by the accounting identity $g_K = \chi \pi \mu b$: if the components wander, the accumulation rate wanders with them. The bounds test confirms this empirically; the identity explains why it must hold.

Lag selection follows the Akaike and Schwarz criteria with a maximum lag of four. Parameter stability is assessed via CUSUM and CUSUM-squared tests, which carry substantive content: instability of the utilization coefficient $\psi_3$ across sub-periods is not a diagnostic nuisance but a structural finding bearing on the regime-specificity of the crisis trigger. All specifications are estimated for both the capital accumulation rate $\kappa_t = I_t / K_t$ and the rate of capitalization $a_t = \chi_t = I_t / \Pi_t$ as dependent variable. The prospectus hypothesis — that $a_t$ is more sensitive to profitability conditions in the short run than $\kappa_t$ — is tested from the short-run adjustment coefficients of the FM spec.

## §2.7.2 Primary Model: Full Weisskopf Disaggregation (FM Spec)

The FM spec enters the three Weisskopf channels separately as regressors:

$$y_t = \psi_0 + \psi_1 \widehat{b}_t + \psi_2 \pi_t + \psi_3 \widehat{\mu}_t + \eta_t. \tag{2.18}$$

The regressors $\widehat{b}_t$ and $\widehat{\mu}_t$ are Stage A outputs, recovered from the cointegrating relation estimated in §2.6 and constructed via the definitions of §2.6.4. This is the point at which the two-stage architecture becomes load-bearing for behavioral estimation. An HP-filter estimate of utilization imposes the transformation elasticity $\theta = 1$, which collapses the demand and technology channels into a single object — the output-capital ratio — and makes the Okishio test impossible. The clean channel separation that Stage A produces is precisely what identifies equation (2.18).

Each coefficient carries a dual interpretation through the Layer-2 identification of §2.3.3:

| Coefficient | Accounting benchmark ($\psi_j = 1$) | Behavioral reading ($\eta_j = \psi_j - 1$) |
|---|---|---|
| $\psi_1$ | Cambridge closure on $b$: $\chi$ inert to capital productivity | Recapitalization response to structural conditions |
| $\psi_2$ | Cambridge closure on $\pi$: $\chi$ inert to distribution | Recapitalization response to profit share |
| $\psi_3$ | Cambridge closure on $\mu$: $\chi$ inert to demand | Recapitalization response to capacity utilization |

When $\psi_j = 1$, the accounting identity governs that margin and the recapitalization rate does not respond to channel $j$. When $\psi_j \neq 1$, the deviation $\eta_j$ is the behavioral content — the extent to which capitalists' reinvestment decisions amplify or partially offset the accounting channel.

The primary hypothesis tested within the FM spec is the Okishio crisis-trigger test:

$$H_0: \psi_1 = \psi_3 \quad \bigl(\Leftrightarrow\; \beta_2 = \beta_3 \text{ in Layer-2 notation}\bigr). \tag{2.19}$$

Under the null, capacity utilization and capital productivity enter the recapitalization decision identically — no independent crisis-trigger effect exists. Rejection establishes that the path of $\widehat{\mu}_t$ has an independent recapitalization effect irreducible to the profit rate. This result admits two readings. At the macro level, it confirms the Okishio mechanism: cumulative disequilibrium in demand conditions fires the crisis trigger independently of profitability. At the firm level, following the micro-foundation developed in §2.2.4, $\psi_3$ is regime-specific — contingent on the Fordist institutional settlement that temporarily suppressed the within-firm multi-scalar contradiction. CUSUM instability of $\psi_3$ across sub-periods confirms this reading: the utilization elasticity of recapitalization is not a structural constant but a historically determined parameter whose stability depends on the institutional conditions that make demand legible to the firm.

## §2.7.3 The Shaikh Net-Profitability Test

Before proceeding to compression tests, the FM spec is augmented with the interest rate as a separate regressor:

$$y_t = \psi_0 + \psi_1 \widehat{b}_t + \psi_2 \pi_t + \psi_3 \widehat{\mu}_t + \psi_4 i_t + \eta_t. \tag{2.20}$$

The Wald test evaluates the net-profitability restriction:

$$H_0: \psi_2^{\pi} = -\psi_4^{i}. \tag{2.21}$$

If the null is not rejected, the profit share and interest rate can be netted into a single net-profitability variable, yielding the compressed Keynes-Robinson-Shaikh form $y_t = \beta_0 + \beta_1(r_t - i_t) + \varepsilon_t$. The decision is sequential: the Shaikh test determines whether the compression tests of §2.7.4–§2.7.5 run on gross or net profitability.

## §2.7.4 Compression Test 1: Bhaduri-Marglin

The Bhaduri-Marglin specification compresses the technology and demand channels into a single regressor, the output-capital ratio at effective demand $\rho_t = \mu_t b_t$, while retaining the profit share as a separate channel:

$$y_t = \gamma_0 + \gamma_1 \rho_t + \gamma_2 \pi_t + \eta_t. \tag{2.22}$$

The Wald restriction tested within the FM framework is $H_0: \psi_1 = \psi_3$ — the same null as the Okishio test. This identity is not coincidental: the BM compression is warranted if and only if the Okishio null is not rejected, because compressing $\widehat{b}_t$ and $\widehat{\mu}_t$ into $\rho_t$ presupposes that they enter the recapitalization decision with equal weight. The behavioral content of the BM specification operates through Layer 2: entering $\rho$ suppresses the technology channel (setting it to Cambridge closure) while letting the demand-distribution separation remain free. The BM framework identifies profit-led versus wage-led investment regimes, but at the cost of losing the CU-productivity distinction that the Okishio test requires. The BM specification is also estimated directly, not only as a within-FM restriction, to allow comparison of point estimates and diagnostic performance.

## §2.7.5 Compression Test 2: Keynes-Robinson

The Keynes-Robinson specification is the limiting compression, entering only the profit rate:

$$y_t = \alpha_0 + \alpha_1 r_t + \varepsilon_t. \tag{2.23}$$

The Wald restriction tested within the FM framework is the joint null $H_0: \psi_1 = \psi_2 = \psi_3$ — all three channels respond identically and are compressible into $r$. KR serves as the benchmark against which disaggregation is measured: if the joint null is not rejected, the full Weisskopf disaggregation adds no behavioral information beyond the profit rate. Stability of $\alpha_0$ across sub-periods provides a secondary test, interpretable as a proxy for the constancy of Keynes's animal spirits. The KR specification is estimated directly as the limiting compression benchmark.

## §2.7.6 Wald Test Sequence

The testing sequence runs from the primary model outward to compressions — from the accounting-grounded baseline to tested restrictions:

| Test | Null hypothesis | What it determines |
|---|---|---|
| 1. Shaikh (within FM) | $\psi_2^{\pi} = -\psi_4^{i}$ | Whether gross or net $r$ enters compressions |
| 2. Okishio (within FM) | $\psi_1 = \psi_3$ | CU crisis trigger; BM compression warranted? |
| 3. BM restriction | Technology-demand compressible into $\rho$ | BM vs. FM |
| 4. KR restriction | All channels compressible into $r$ | KR vs. FM |

The sequence has a recursive structure. Tests 2 and 3 share the same null hypothesis: the Okishio restriction and the BM compression restriction are algebraically identical. Rejecting the Okishio null therefore rejects BM compression simultaneously — capacity utilization cannot be an independent crisis trigger and yet be compressible with capital productivity into the output-capital ratio. If the Okishio null is rejected, the FM spec stands as the supported model, and the rejection carries both its macro reading (cumulative disequilibrium as crisis mechanism) and its firm-level reading (regime-specificity of the utilization elasticity). The full sequence of Wald statistics, together with their bootstrap-adjusted critical values, is reported in §2.8.
