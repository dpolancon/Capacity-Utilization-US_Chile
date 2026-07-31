---
type: execution_prompt
status: ready_to_fire
created: 2026-07-25
pipeline_stage: Single-Equation Cointegration & Structural Break Audit (cointReg + strucchange)
depends_on:
  - reports/capital_integration_cointegration_comprehensive_report.tex
  - output/break_informed_johansen_vecm_ledger.csv
  - codes/COMMON_S34_break_informed_vecm_pipeline.R
  - codes/COMMON_S35_visualize_capital_breaks.R
  - data/processed/cl_s20/chile_orthogonalized_panel.csv
  - data/processed/us_s31j/us_staged_pending_conditioners.csv
skills_required:
  - /umass-applied-econometrics (visual-first, PE interpretation, forensic transparency, 14-point checklist)
  - /deep-research (lit-review mode for single-equation cointegration & strucchange econometrics)
  - /humanize-writing
governing_rules:
  - AGENTS.md v4 (reports/ for .tex/.pdf; output/ for .csv, .png, .pdf artifacts)
  - Notation: μ_t = capacity utilization, χ_t = recapitalization rate, τ_t = composition state
  - Normalization: LHS Nonresidential Structures: k_t^NRC = alpha + gamma * k_t^ME + u_t
---

# Execution Prompt: Single-Equation Super-Consistent Cointegration Audit (`cointReg` + `strucchange`)

## Executive Objective

Construct a parallel empirical report and pipeline that evaluates the long-run cointegrating relationship between Nonresidential Structures ($k_t^{\text{NRC}}$/$k_t^{\text{NR}}$) and Machinery ($k_t^{\text{ME}}$) using single-equation **super-consistent modified OLS estimators** from the `cointReg` package (FM-OLS, DOLS, IM-OLS) and tests structural stability endogenously using the `strucchange` package.

The output report will be compiled to `reports/single_equation_cointreg_structural_break_report.tex` (and `.pdf`), establishing whether single-equation estimators confirm the system-level VECM results ($\hat{\gamma} \approx 1.0$ baseline; sub-period regime heterogeneity) and evaluating parameter stability against LOESS 2nd derivative zero-crossings.

---

## Governing Frameworks & Skills

### 1. `/umass-applied-econometrics`
Read `c:\ReposGitHub\academic-research-skills\umass-applied-econometrics\SKILL.md`. Apply:
- **LHS Normalization**: $k_t^{\text{NRC}} = \alpha + \gamma k_t^{\text{ME}} + u_t$. $\hat{\gamma}$ represents the structural envelope response to machinery deepening ($\frac{\partial k^{\text{NRC}}}{\partial k^{\text{ME}}}$).
- **Rule B (Data-First Visualization)**: Present raw series and non-parametric LOESS plots before reporting parametric FM-OLS/DOLS/IM-OLS regressions.
- **Rule D (Specification-Space Mapping)**: Report all three estimators (FM-OLS, DOLS, IM-OLS) side-by-side across all historical windows in consolidated comparative tables.
- **Rule H (Political Economy Coefficient Interpretation)**: Read $\hat{\gamma}$ through the surplus approach and induced innovation framework:
  - $\hat{\gamma} \approx 1.0$: Balanced Fordist accumulation (proportional plant & technique expansion).
  - $\hat{\gamma} < 1.0$: Intensive mechanization outpaces plant construction ($\Delta k^{\text{ME}} > \Delta k^{\text{NRC}}$).
  - $\hat{\gamma} > 1.0$: Extensive plant expansion under wage suppression (e.g., Chile Dictatorship).
  - $\hat{\gamma} \ll 1.0$ or unstable: Neoliberal decoupling or peripheral balance-of-payments truncation.
- **14-Point Diagnostic Checklist**: Execute full pass against §3 checklist.

### 2. `/deep-research`
Read `c:\ReposGitHub\academic-research-skills\deep-research\SKILL.md`. Fire in **lit-review mode** with the following dual research questions:

> **RQ1 (`cointReg` Econometrics):** How do Fully Modified OLS (Phillips & Hansen 1990), Dynamic OLS (Stock & Watson 1993), and Integrated Modified OLS (Vogelsang & Wagner 2014) resolve 2nd-order bias and endogeneity contamination in single-equation cointegrating regressions, and what are their relative performance trade-offs in macro samples ($N=20$--$100$)?
>
> **RQ2 (`strucchange` Econometrics):** How do empirical fluctuation processes (OLS-CUSUM, Rec-CUSUM) and structural break tests (Bai & Perron 1998, 2003 `breakpoints()`, SupF, AveF, ExpF) evaluate parameter stability in cointegrated time series, and how do endogenously estimated break dates compare to non-parametric LOESS 2nd derivative zero-crossings?

**Scope boundaries:**
- **In scope:** Phillips & Hansen (1990) kernel long-run variance estimation (Bartlett, Parzen, Quadratic Spectral) and Andrews (1991) / Newey-West (1994) automatic bandwidth selection; Stock & Watson (1993) lead/lag selection via AIC/BIC; Vogelsang & Wagner (2014) partial sum integration transformation and Fixed-$b$ asymptotic inference; Zeileis et al. (2002, 2003) `strucchange` architecture (`efp()`, `sctest()`, `breakpoints()`, `Fstats()`); comparison between single-equation modified OLS and Johansen VECM system estimators.
- **Out of scope:** Non-stationary panel regression, structural VAR identify schemes, GARCH volatility models.

The lit-review synthesis feeds directly into Section 2 of the new report.

---

## Data Pipeline & R Implementation (`codes/COMMON_S38_cointreg_strucchange_pipeline.R`)

Create an R script `codes/COMMON_S38_cointreg_strucchange_pipeline.R` that executes the full empirical audit:

### 1. Data Intake
- Load U.S. data (`data/processed/us_s31j/us_staged_pending_conditioners.csv`, 1925–2021, $N=97$).
- Load Chile data (`data/processed/cl_s20/chile_orthogonalized_panel.csv`, 1920–2024, $N=105$).
- Define LHS variable: $y_t = k_t^{\text{NRC}}$ (or $k_t^{\text{NR}}$).
- Define RHS variable: $x_t = k_t^{\text{ME}}$.

### 2. Periodization Windows (LOESS Zero-Crossing Defined)
- **United States**:
  - Full Century: 1925–2021 ($N=97$)
  - Interwar & WWII: 1925–1946 ($N=22$) [LOESS Break 1 = 1933]
  - Fordist Golden Age: 1947–1973 ($N=27$) [LOESS Break 2 = 1968]
  - Neoliberal Restructuring: 1974–2008 ($N=35$) [LOESS Break 3 = 2008]
  - Post-GFC Stagnation: 2009–2021 ($N=13$)
- **Chile**:
  - Full Chile Century: 1920–2024 ($N=105$)
  - Nitrate Crisis & Early State: 1920–1938 ($N=19$) [LOESS Break 1 = 1936]
  - Classic ISI Era: 1939–1973 ($N=35$) [LOESS Break 2 = 1971]
  - Dictatorship Shock: 1974–1989 ($N=16$) [LOESS Break 3 = 1982]
  - Democratic Neoliberal: 1990–2024 ($N=35$)

### 3. `cointReg` Super-Consistent Estimation
For every historical window, estimate the cointegrating vector $k_t^{\text{NRC}} = \alpha + \gamma k_t^{\text{ME}} + u_t$ using all three `cointReg` estimators:

1. **FM-OLS (`cointRegFM`)**:
   - `cointRegFM(x = x, y = y, deter = rep(1, N), kernel = "Quadratic Spectral", bw = "Andrews")`
   - Extract $\hat{\gamma}_{\text{FM}}$, standard error, $t$-stat, $p$-value, and long-run variance $\Omega$.
2. **DOLS (`cointRegDOLS`)**:
   - `cointRegDOLS(x = x, y = y, deter = rep(1, N), n.p = 2, n.n = 2)` (or AIC-selected leads/lags).
   - Extract $\hat{\gamma}_{\text{DOLS}}$, standard error, $t$-stat, $p$-value.
3. **IM-OLS (`cointRegIM`)**:
   - `cointRegIM(x = x, y = y, deter = rep(1, N))`
   - Extract $\hat{\gamma}_{\text{IM}}$, Fixed-$b$ test statistic, and $p$-value.

### 4. `strucchange` Endogenous Break Testing
On the full-century models for both countries:
1. **Fluctuation Monitoring**:
   - `efp(y ~ x, type = "OLS-CUSUM")` and `efp(y ~ x, type = "Rec-CUSUM")`.
   - Plot empirical fluctuation paths with 5% boundary lines.
2. **SupF, AveF, ExpF Tests**:
   - `fs <- Fstats(y ~ x, from = 0.15, to = 0.85)`
   - `sctest(fs, type = "supF")`, `sctest(fs, type = "aveF")`, `sctest(fs, type = "expF")`.
3. **Bai-Perron Multiple Break Estimation**:
   - `bp <- breakpoints(y ~ x, h = 0.15, breaks = 3)`
   - Extract estimated break dates $\hat{T}_b^{(1)}, \hat{T}_b^{(2)}, \hat{T}_b^{(3)}$ and confidence intervals.
   - Compare endogenous break dates to LOESS zero-crossings ({1933, 1968, 2008} for U.S.; {1936, 1971, 1982} for Chile).

### 5. CSV Ledger Output
Save complete results to `output/cointreg_strucchange_robustness_ledger.csv` with columns:
`Country`, `Window`, `Start_Year`, `End_Year`, `N`, `Gamma_FM`, `SE_FM`, `T_FM`, `P_FM`, `Gamma_DOLS`, `SE_DOLS`, `T_DOLS`, `P_DOLS`, `Gamma_IM`, `Stat_IM`, `P_IM`, `BP_Break_1`, `BP_Break_2`, `BP_Break_3`, `SupF_Stat`, `SupF_PVal`, `LOESS_Match_Verdict`.

### 6. Figure Generation
Save two publication figures to `output/figures/`:
1. `cointreg_estimator_triad_comparison.png`: Paired dot-and-whisker plot comparing $\hat{\gamma}_{\text{FM}}$, $\hat{\gamma}_{\text{DOLS}}$, and $\hat{\gamma}_{\text{IM}}$ across windows against the $\hat{\gamma}=1.0$ benchmark.
2. `strucchange_cusum_breakpoints.png`: Two-panel plot showing OLS-CUSUM fluctuation paths with Bai-Perron break lines overlaid on LOESS 2nd derivative zero-crossings.

---

## LaTeX Manuscript Structure (`reports/single_equation_cointreg_structural_break_report.tex`)

Draft and compile a 12-to-15 page LaTeX document structured as follows:

```
Title: Super-Consistent Cointegration Estimators and Structural Stability of Capital Composition: An Empirical Audit using cointReg and strucchange for the U.S. and Chile
Abstract: (BLUF summary of FM-OLS vs DOLS vs IM-OLS estimates, structural break dates, and PE implications)

Section 1: Introduction: Single-Equation Cointegration vs. System VECMs in Political Economy
Section 2: Econometric Foundations of Super-Consistent Modified OLS (cointReg Triad)
Section 3: Structural Break Testing in Cointegrating Regressions (strucchange Architecture)
Section 4: Data-First Visualization & LOESS Inflection Baseline
Section 5: Comparative Cointegration Estimates: FM-OLS, DOLS, and IM-OLS across Windows
Section 6: Endogenous Structural Break Audit (Bai-Perron vs. LOESS Inflections)
Section 7: Robustness Reconciliation: Single-Equation cointReg vs. Johansen VECM
Section 8: Unified Political Economy Reading of Cointegrating Elasticities
Section 9: Implications for Mechanization Intensity Proxy Selection (tau_t Governance)
Section 10: Conclusion
```

### Formatting Requirements (AGENTS.md v4)
- All bold text in LaTeX must use `\textbf{}`. No markdown `**`.
- All `\begin{table}` and `\begin{figure}` environments must use `[h!]` or `[H]`.
- Place `\FloatBarrier` before every `\section`.
- Explicit column widths (`p{Xcm}`) for journal-ready tables.
- Table footnotes use `\footnotesize` inside `\multicolumn{N}{p{Wcm}}{...}`.
- Save source `.tex` and compiled `.pdf` strictly in `reports/`. Never place `.tex` or `.pdf` in `output/`.

---

## Execution Steps

1. **Fire `/deep-research` in lit-review mode** for RQ1 (`cointReg`) and RQ2 (`strucchange`). Save output as artifact.
2. **Write and execute `codes/COMMON_S38_cointreg_strucchange_pipeline.R`**. Generate CSV ledger and PNG figures.
3. **Write `reports/single_equation_cointreg_structural_break_report.tex`**, weaving lit-review, empirical tables, figures, and PE interpretations into a unified narrative.
4. **Compile LaTeX to PDF with `pdflatex`** (2 passes to resolve references). Confirm 0 errors.
5. **Execute 14-point UMass checklist audit** against the final manuscript.
6. **Update `walkthrough.md`** to document accomplishments and file inventory.

---

## Verification & Acceptance Criteria

- [ ] R script `COMMON_S38_cointreg_strucchange_pipeline.R` executes cleanly.
- [ ] CSV ledger `output/cointreg_strucchange_robustness_ledger.csv` populated with all 3 estimators + `strucchange` test statistics.
- [ ] Figures `cointreg_estimator_triad_comparison.png` and `strucchange_cusum_breakpoints.png` saved in `output/figures/`.
- [ ] LaTeX manuscript `reports/single_equation_cointreg_structural_break_report.tex` drafted.
- [ ] PDF compiled cleanly (`reports/single_equation_cointreg_structural_break_report.pdf`, 12–15 pages, 0 errors).
- [ ] `\textbf{}` used exclusively for bold formatting in `.tex`.
- [ ] `\FloatBarrier` placed before every `\section`.
- [ ] `p{Xcm}` column widths used in all LaTeX tables.
- [ ] 14-point `/umass-applied-econometrics` checklist satisfied.

---

*Prompt v1.0 — 2026-07-25*
*Authority: Ch2_Outline_DEFINITIVE.md | AGENTS.md v4 | /umass-applied-econometrics | /deep-research*
