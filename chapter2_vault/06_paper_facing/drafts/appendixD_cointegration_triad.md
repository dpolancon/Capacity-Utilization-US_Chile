---
type: paper_facing
status: draft
depends_on:
  - chapter2_vault/03_econometrics/E15_Vogelsang_Wagner_IMOLS_Cointegration_Test_Lock.md
  - chapter2_vault/03_econometrics/E17_Cointegration_Significance_Stars_Lock.md
  - chapter2_vault/06_paper_facing/results/03_monte_carlo_tail_convergence_report.md
stage_scope: paper-facing
country: US_CL
last_updated: 2026-08-05
updated_by: VW_PROMOTION_TO_CORE
layer: appendix
role: cointegration-diagnostics
stage: post-estimation-diagnostics
tags:
  - chapter2/appendix
  - chapter2/cointegration
  - chapter2/imols
scope: chapter2
priority: core
---

# Appendix D: Cointegration Diagnostics and the Monte Carlo Critical-Value Protocol

The main text reports one cointegration statistic per specification: the Vogelsang and Wagner (2014) Type 2 test. This appendix reports the full diagnostic set behind that verdict, states the critical values, and explains why the Type 2 test rather than the residual tests carries the reading.

## D.1 Why the Type 2 test governs

The three tests in use do not stand on equal footing, and treating them as a co-equal triad obscures what each is doing.

The residual Engle-Granger ADF test asks whether the estimated residual series contains a unit root. Its null is *no* cointegration, so rejection supports the long-run relation. The Shin LM test inverts this: its null is cointegration, and rejection indicates spurious regression. The Vogelsang-Wagner Type 2 test also takes cointegration as its null, but it differs from both residual tests in a way that matters for this chapter. Rather than testing a property of a residual series constructed after the fact, it tests a restriction on the IM-OLS estimator itself — that the auxiliary coefficient vector $\lambda_2$ is zero, which holds under genuine cointegration and fails under spurious regression. Because the specifications here carry generated interaction regressors that have been FWL-orthogonalized against the base capital terms and the deterministic space, a residual-based test inherits whatever the orthogonalization did to the residual's serial dependence. The Type 2 statistic does not.

That is the substantive reason for the hierarchy, and it is the one the estimation protocol adopts: the Type 2 test is primary and binding, the residual ADF and Shin LM tests are secondary robustness checks, and Johansen and Phillips-Ouliaris statistics are background diagnostics that do not enter the paper.

## D.2 Reading the stars: opposed nulls

Because the nulls run in opposite directions, an identical typographic convention carries opposite meanings across rows of the tables below. This is worth stating plainly rather than leaving to a footnote.

For the residual ADF test, stars indicate rejection of no cointegration, and are therefore the favourable result. For the Shin LM and Vogelsang-Wagner Type 2 tests, stars indicate rejection of cointegration, and are therefore the unfavourable result. A well-behaved specification shows stars on its ADF row and none on the other two.

## D.3 Critical values

**Table D.1: Critical Values for the Cointegration Diagnostics**

| Test | Source | 10% | 5% | 1% |
| :--- | :--- | :---: | :---: | :---: |
| Residual ADF ($t_{\text{ADF}}$) | MacKinnon (2010), Case 2, constant only, $m=4$ | $-3.81$ | $-4.10$ | $-4.64$ |
| Shin LM ($C_{\text{Shin}}$), $k=2$ | Shin (1994), Table 1, demeaned $C_\mu$ | $0.163$ | $0.221$ | $0.380$ |
| Shin LM ($C_{\text{Shin}}$), $k=3$ | Shin (1994), Table 1, demeaned $C_\mu$ | $0.121$ | $0.159$ | $0.271$ |
| VW Type 2 ($S_{\text{Type 2}}$) | Vogelsang and Wagner (2014), fixed-$b$, Bartlett kernel, intercept-only | jointly indexed by $(b,k)$ | no single constant applies | see D.3 note |

Here $m$ counts the total number of $I(1)$ variables in the system, one dependent variable plus the stochastic regressors, with step dummies excluded from the count; $k$ counts stochastic $I(1)$ regressors alone. Exogenous $I(0)$ controls sit in the deterministic matrix and so do not enter $k$.

The last row is the substantive point. Vogelsang-Wagner fixed-$b$ critical values are not constants. They vary by roughly an order of magnitude across the tabulated bandwidth-ratio range and depend on the regressor count, so every model must be evaluated against the cell matching its own $(b, k)$ pair. Each table below reports the bandwidth ratio $b$ for exactly this reason.

\PLACEHOLDER{The Type 2 rows in the tables below carry no significance stars, because the statistics have not yet been evaluated against the $(b,k)$-indexed fixed-$b$ table digitized in \texttt{codes/COMMON\_VW\_fixedb\_critical\_values.R}. Earlier drafts compared them against a single hardcoded triple ($11.45$ / $13.78$ / $18.90$) applied uniformly across models regardless of bandwidth or regressor count; a 2026-08-03 audit established that this triple matches no cell of the published table, and those comparisons have been withdrawn rather than reproduced here. Re-running the estimation against the digitized module is the outstanding work. Until it is done, this appendix reports the statistics and the critical-value regime, but not a starred verdict.}

## D.4 Constructing the residual statistics

Two implementation details determine whether the residual diagnostics measure what they are supposed to measure.

The Shin LM statistic is evaluated on the IM-OLS partial sum residuals $U_t = \sum e_t$ directly, with no further accumulation. Because $U_t$ is already an integrated partial sum by construction, applying a second cumulative sum produces an $I(2)$ series and inflates the statistic. The error is easy to make and hard to see, since the inflated statistic remains finite and ordered plausibly across models.

The regressors entering the residual tests are the deterministically detrended series — the residuals of $\mathbf{x}$ regressed on the step dummies and their partial sums — from which the reverse cumulative sum regressors are then built. Skipping the detrending leaves deterministic trend contamination in the test.

## D.5 Small-sample and lag-augmentation caveats

Two further constraints bear on how the residual diagnostics below should be read.

Residual unit-root tests must be lag-augmented with an information-criterion-selected lag order. A plain Dickey-Fuller regression with zero lagged differences is not admissible where the residuals are serially correlated, which in this setting means everywhere. Where a sub-sample is short — the Fordist window gives $T=44$ — small-sample bias pushes the true critical values more negative than the asymptotic boundaries tabulated above, so marginal significance near $-4.10$ in a sub-sample should not be read as a clean rejection.

Second, step dummies test only for level shifts. They cannot absorb a shift in the cointegrating vector itself, so a specification that answers detected breaks with step dummies alone has not addressed slope instability and is not described as break-robust anywhere in this chapter. Appendix E takes up parameter stability directly.

## D.6 Specification A: aggregate capital

<!-- TABLE: reports/US_Section31_IMOLS_Results/table_specA_set1_gva_TRIAD.tex -->

<!-- TABLE: reports/US_Section31_IMOLS_Results/table_specA_set1_nva_TRIAD.tex -->

<!-- TABLE: reports/US_Section31_IMOLS_Results/table_specA_set2_gva_TRIAD.tex -->

<!-- TABLE: reports/US_Section31_IMOLS_Results/table_specA_set2_nva_TRIAD.tex -->

## D.7 Specification B: heterogeneous capital

<!-- TABLE: reports/US_Section32_IMOLS_Results/table_specB_set1_gva_TRIAD.tex -->

<!-- TABLE: reports/US_Section32_IMOLS_Results/table_specB_set1_nva_TRIAD.tex -->

<!-- TABLE: reports/US_Section32_IMOLS_Results/table_specB_set2_gva_TRIAD.tex -->

<!-- TABLE: reports/US_Section32_IMOLS_Results/table_specB_set2_nva_TRIAD.tex -->

## D.8 Chile: threshold specification

<!-- TABLE: reports/Chile_Section33_Peripheral_IMOLS_Results/table_chile_threshold_imols_TRIAD.tex -->

## D.9 The Monte Carlo protocol

Coefficient-level significance throughout the chapter comes from a 100,000-pass Monte Carlo simulation that reproduces the exact data-generating process of each specification variant, including whether step level-shifts are present. This is not a convenience. Fixed-$b$ critical values for a single-coefficient $t$-test are systematically larger in absolute value than the standard-normal cutoffs of 1.645, 1.960, and 2.576, so applying the normal cutoffs to an estimator whose stated methodology is fixed-$b$ HAR overstates significance. Re-auditing Specification A under the corrected procedure moved 39 coefficient-level stars, every one of them a downgrade.

For the Chilean threshold specification the simulation additionally replicates the Profile Least Squares grid search over the capacity-to-import threshold inside each pass. Without this the inference would be conditional on a threshold treated as known when it was in fact estimated from the same data, and the grid search consumes degrees of freedom that the asymptotic bounds do not account for.

\PLACEHOLDER{Tail-convergence evidence for the simulation --- the $CT_{IM}$, $t_{\theta_0}$, and $t_{\theta_1}$ convergence diagnostics at $N=100{,}000$, and the inflation of the 95th-percentile critical values under structural breaks --- exists at \texttt{chapter2\_vault/06\_paper\_facing/results/03\_monte\_carlo\_tail\_convergence\_report.md} with four supporting figures, and should be folded into this subsection.}
