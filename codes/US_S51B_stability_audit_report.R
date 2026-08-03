#!/usr/bin/env Rscript

# US_S51B_stability_audit_report.R
# ---------------------------------------------------------------------------
# Builds the companion LaTeX report for the Section 3.1 cointegration-failure
# diagnostics. Reads the artifacts produced by US_S51_section31_stability_audit.R
# so the report can be regenerated without re-running the bootstrap battery.
#
# Report ordering follows umass-applied-econometrics Rule B (visual-first):
# descriptive and non-parametric evidence precedes parametric tests, and the
# consolidated verdict ledger comes last.
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir <- file.path(repo_root, "output", "US", "S51_SECTION31_STABILITY")
csv_dir <- file.path(out_dir, "csv")
fig_dir <- file.path(out_dir, "fig")
rep_dir <- file.path(repo_root, "reports", "US_Section31_Stability_Audit")
dir.create(rep_dir, recursive = TRUE, showWarnings = FALSE)

A <- readRDS(file.path(out_dir, "s51_stability_audit.rds"))
adf <- read.csv(file.path(csv_dir, "s51_adf_lag_sensitivity.csv"))
hansen <- A$hansen; cusum <- A$cusum; gh <- A$gh; split <- A$split
io <- A$io; ledger <- A$ledger; hp <- A$hansen_param

tex_out <- file.path(rep_dir, "us_section31_stability_audit.tex")
esc <- function(s) gsub("_", "\\\\_", s)
fmtp <- function(p) ifelse(is.na(p), "---", ifelse(p < 0.001, "$<$0.001", sprintf("%.3f", p)))

sink(tex_out)
cat("\\documentclass[11pt,a4paper]{article}\n")
cat("\\usepackage[margin=1in]{geometry}\n\\usepackage{booktabs}\n\\usepackage{float}\n")
cat("\\usepackage{makecell}\n\\usepackage{placeins}\n\\usepackage{caption}\n")
cat("\\usepackage{amsmath,amssymb}\n\\usepackage{graphicx}\n\\usepackage{longtable}\n")
cat("\\usepackage{multirow}\n")
cat("\\usepackage[hidelinks]{hyperref}\n")
cat("\\title{\\textbf{Section 3.1 Cointegration Failure Diagnostics:\\\\ Parameter-Stability Audit of the U.S. NFC IM-OLS Matrix (1931--2024)}}\n")
cat("\\author{\\textbf{Department of Economics, UMass Amherst}}\n")
cat("\\date{August 2026}\n\\begin{document}\n\\maketitle\n\n")

# ---- Executive summary --------------------------------------------------
n_p0  <- sum(adf$rej_p0); n_aic <- sum(adf$rej_aic); n_bic <- sum(adf$rej_bic)
n_agree <- sum(adf$aic_lag == adf$bic_lag, na.rm = TRUE)
n_cusum <- sum(cusum$supF_p < 0.05, na.rm = TRUE)
cat("\\section*{Executive Summary}\n")
cat(sprintf(paste0(
  "The Section 3.1 IM-OLS estimation matrix reported overwhelming evidence \\emph{against} ",
  "cointegration. This audit finds that verdict was substantially an artifact of test ",
  "mis-specification. The residual Engle--Granger test was implemented as an \\emph{unaugmented} ",
  "Dickey--Fuller regression (zero lagged differences) while being compared against MacKinnon ",
  "critical values tabulated for the \\emph{augmented} test. The IM-OLS residuals carry AR(2)--AR(4) ",
  "structure with first-order autocorrelation between %.2f and %.2f; lag augmentation is precisely ",
  "the device that whitens such errors, and without it the test is severely biased toward ",
  "non-rejection.\n\n",
  "Correcting the augmentation reverses the finding: rejections of the null of no cointegration rise ",
  "from \\textbf{%d of 18} models to \\textbf{%d of 18} at the 5\\%% level (%d of 18 under BIC; 18 of 18 ",
  "at the 10\\%% level). AIC and BIC select the same lag order in %d of 18 models, and even minimal ",
  "$p=1$ augmentation flips the verdict, so the reversal is not an artifact of lag selection.\n\n",
  "A genuine secondary finding survives the correction. The underlying relationship \\emph{is} ",
  "structurally unstable: the CUSUM family rejects parameter stability in %d of 18 models, with break ",
  "dates at 1974, 1948 and 1945, and the Gregory--Hansen regime-shift scan locates a break in ",
  "1976--77 in %d of 18 models. That instability is real, but it is absorbed by the Bai--Perron step ",
  "dummies already present in the specification --- it was never the reason the cointegration tests ",
  "failed. Note that the Gregory--Hansen \\emph{statistic} rejects its own null of no cointegration in ",
  "only %d of 18 models at 5\\%%: a single regime shift is not sufficient where the Bai--Perron audit ",
  "identifies three to five level shifts.\n\n"),
  min(adf$resid_AR1), max(adf$resid_AR1), n_p0, n_aic, n_bic, n_agree, n_cusum,
  sum(gh$gh_model == "regime" & gh$break_year %in% c(1976, 1977), na.rm = TRUE),
  sum(gh$gh_model == "regime" & gh$boot_p < 0.05, na.rm = TRUE)))
cat("\\FloatBarrier\n")

# ---- Section 1: what was ruled out --------------------------------------
cat("\\section{What the Failure Was Not: Regressor Admissibility}\n")
cat("The leading rival explanation --- that the interaction regressors inherit $I(2)$ behaviour and are ",
    "inadmissible in an $I(1)$ cointegration framework --- is excluded. The S33 integration-order battery ",
    "had already tested the interaction terms directly and returned $I(1)$ throughout. This audit closed ",
    "two gaps that battery left open, testing the series \\emph{exactly as US\\_S50 constructs them}: the ",
    "\\textbf{lagged} interaction terms (S33 tested contemporaneous ones), and ",
    "\\texttt{omega\\_ST\\_Tier2\\_GVA\\_adj} standalone, which had never been tested despite being the ",
    "wage share the project constitution mandates.\n\n", sep = "")
cat("\\begin{table}[H]\\centering\\caption{Integration-order gap closure (ADF + KPSS, levels and first differences)}\n")
cat("\\small\\begin{tabular}{p{9.5cm}l}\n\\toprule\nSeries & Verdict \\\\\n\\midrule\n")
for (i in seq_len(nrow(io))) cat(sprintf("%s & %s \\\\\n", esc(io$series[i]), io$verdict[i]))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\caption*{\\footnotesize The Integration Order Gate passes. One term (M2.9's triple interaction) ",
    "returns an ambiguous ADF/KPSS combination and is flagged for follow-up.}\n\\end{table}\n")
cat("\\FloatBarrier\n")

# ---- Section 2: the defect ----------------------------------------------
cat("\\section{The Defect: Missing Lag Augmentation}\n")
cat("US\\_S50 computed the residual test as \\texttt{lm(diff(u) \\textasciitilde{} u[-T] - 1)} --- a plain ",
    "Dickey--Fuller with no lagged differences. Table~\\ref{tab:adfsens} shows the consequence.\n\n", sep = "")
cat("\\begin{table}[H]\\centering\\caption{EG-ADF lag-augmentation sensitivity, all 18 models}\\label{tab:adfsens}\n")
cat("\\small\\begin{tabular}{lrrrrrrrr}\n\\toprule\n")
cat("Model & AR(1) & $p{=}0$ & $p{=}1$ & $p{=}2$ & $p{=}3$ & $p{=}4$ & AIC (lag) & 5\\% cv \\\\\n\\midrule\n")
for (i in seq_len(nrow(adf))) {
  st <- function(v, rej) sprintf("%s%.2f%s", if (rej) "\\textbf{" else "", v, if (rej) "}" else "")
  cat(sprintf("%s & %.2f & %s & %s & %s & %s & %s & %s (%d) & %.2f \\\\\n",
    adf$Model_ID[i], adf$resid_AR1[i],
    st(adf$adf_p0[i], adf$rej_p0[i]), st(adf$adf_p1[i], adf$rej_p1[i]),
    st(adf$adf_p2[i], adf$rej_p2[i]), st(adf$adf_p3[i], adf$rej_p3[i]),
    st(adf$adf_p4[i], adf$rej_p4[i]), st(adf$adf_aic[i], adf$rej_aic[i]),
    adf$aic_lag[i], adf$cv5[i]))
}
cat("\\midrule\n")
cat(sprintf("\\textbf{Rejections} & & \\textbf{%d} & %d & %d & %d & %d & \\textbf{%d} & \\\\\n",
    n_p0, sum(adf$rej_p1), sum(adf$rej_p2), sum(adf$rej_p3), sum(adf$rej_p4), n_aic))
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\caption*{\\footnotesize Bold entries reject $H_0$: no cointegration at 5\\%. Column $p{=}0$ is the ",
    "specification shipped in the v2 report. The decline at $p\\ge4$ is the expected power loss from ",
    "over-augmentation at $T=94$. \\textbf{Caveat:} the residuals come from a regression containing ",
    "endogenously-selected Bai--Perron step dummies; standard Engle--Granger critical values do not ",
    "account for estimated break dates and are therefore somewhat liberal here. The Gregory--Hansen ",
    "test in Section~4 is the break-robust cross-check.}\n\\end{table}\n")
cat("\\FloatBarrier\n")

# ---- Section 3: visual-first evidence -----------------------------------
cat("\\section{Descriptive Evidence: Recursive Elasticity Paths and CUSUM}\n")
cat("Following the visual-first protocol, the non-parametric evidence is presented before the ",
    "parametric instability tests. Figure~\\ref{fig:rec} shows the recursive capital elasticity ",
    "$\\hat{\\theta}_0$ over expanding windows; Figure~\\ref{fig:cus} the OLS-CUSUM path.\n\n", sep = "")
for (nm in c("M1.1", "M1.5")) {
  f1 <- file.path(fig_dir, sprintf("s51_recursive_theta_%s.png", nm))
  if (file.exists(f1)) {
    cat("\\begin{figure}[H]\\centering\n")
    cat(sprintf("\\includegraphics[width=0.78\\textwidth]{%s}\n", gsub("\\\\", "/", f1)))
    cat(sprintf(paste0("\\caption{Recursive $\\hat{\\theta}_0$, model %s. Dashed lines are fixed-$b$ 95\\%% ",
                       "bands; they are unavailable for the shortest windows, where \\texttt{cointRegIM} ",
                       "returns non-finite standard errors.}\\label{fig:rec}\n"), nm))
    cat("\\end{figure}\n")
    break
  }
}
f2 <- file.path(fig_dir, "s51_cusum_M1.1.png")
if (file.exists(f2)) {
  cat("\\begin{figure}[H]\\centering\n")
  cat(sprintf("\\includegraphics[width=0.78\\textwidth]{%s}\n", gsub("\\\\", "/", f2)))
  cat("\\caption{OLS-CUSUM, model M1.1, core specification (step dummies excluded).}\\label{fig:cus}\n")
  cat("\\end{figure}\n")
}
cat("\\FloatBarrier\n")

# ---- Section 4: parametric instability ----------------------------------
cat("\\section{Parametric Instability Tests}\n")
cat("The CUSUM family runs on the \\textbf{core specification} --- intercept plus stochastic regressors, ",
    "\\emph{excluding} the Bai--Perron step dummies. Those dummies were selected from a break audit on ",
    "these very residuals; including them would absorb the instability the test exists to detect.\n\n", sep = "")
cat("\\begin{table}[H]\\centering\\caption{Parameter stability: CUSUM family, Hansen (1992), Gregory--Hansen}\n")
cat("\\small\\begin{tabular}{lrrrrrrr}\n\\toprule\n")
cat("\\multirow{2}{*}{Model} & \\multicolumn{3}{c}{CUSUM family (core spec)} & \\multicolumn{2}{c}{Hansen $L_c$} & \\multicolumn{2}{c}{Gregory--Hansen} \\\\\n")
cat("\\cmidrule(lr){2-4}\\cmidrule(lr){5-6}\\cmidrule(lr){7-8}\n")
cat(" & OLS-CUSUM $p$ & supF $p$ & break & $L_c$ & $p$ & stat & break \\\\\n\\midrule\n")
for (i in seq_len(nrow(cusum))) {
  nm <- cusum$Model_ID[i]
  h <- hansen[hansen$Model_ID == nm, ]
  g <- gh[gh$Model_ID == nm & gh$gh_model == "regime", ]
  cat(sprintf("%s & %s & %s & %s & %.1f & %s & %.2f & %s \\\\\n", nm,
      fmtp(cusum$OLS_CUSUM_p[i]), fmtp(cusum$supF_p[i]),
      ifelse(is.na(cusum$supF_break_year[i]), "---", cusum$supF_break_year[i]),
      h$Lc_all[1], fmtp(h$Lc_all_p[1]),
      if (nrow(g)) g$statistic[1] else NA_real_,
      if (nrow(g) && !is.na(g$break_year[1])) g$break_year[1] else "---"))
}
cat("\\bottomrule\n\\end{tabular}\n")
cat("\\caption*{\\footnotesize Hansen $L_c$ is computed on the model \\emph{as estimated}, i.e. including ",
    "the step dummies, with a bootstrapped null (1{,}000 replications, AR-sieve DGP). ",
    "Gregory--Hansen uses the regime-shift (C/S) specification, which allows the cointegrating vector ",
    "itself to break, with a random-walk null (499 replications). ",
    "The two families have opposite nulls: for CUSUM and Hansen, $H_0$ is stability; for ",
    "Gregory--Hansen, $H_0$ is \\emph{no} cointegration.}\n\\end{table}\n")

cat("\\subsection{Reconciling Hansen with Shin}\n")
cat("Shin's $C$ statistic is Hansen's $L_c$ restricted to intercept-only parameter variation. The ",
    "identity $L_c^{\\text{intercept}} = T \\cdot C_{\\text{Shin}}$ was verified exactly across all 18 ",
    "models (maximum relative error $3\\times10^{-16}$) and is enforced as a blocking pre-condition in ",
    "the audit script. The v2 report's 18/18 Shin rejection was therefore always a statement about ",
    "\\emph{intercept} instability, not about cointegration failure in general. Its apparent conflict ",
    "with the non-rejecting $L_c$ reported above is a long-run-variance normalisation difference: Shin ",
    "uses \\texttt{cointReg}'s conditional $\\omega_{u\\cdot v}$, Hansen the score-process Bartlett LRV.\n\n", sep = "")

cat("\\subsection{Where the instability sits}\n")
cat("The per-parameter $L_c$ decomposition locates the instability in the \\textbf{step-dummy ",
    "coefficients} rather than the structural parameters. Representative values (model M1.1): ",
    "intercept 4.4, $\\hat\\theta_0$ 4.6, $\\hat\\theta_1$ 2.7, against $D_{1965}$ 20.4, $D_{1985}$ 20.1, ",
    "$D_{2003}$ 17.3. The capital elasticity is comparatively stable; what moves is the level. ",
    "These magnitudes are \\emph{descriptive only} --- see Section~6.\n\n", sep = "")
cat("\\FloatBarrier\n")

# ---- Section 5: regime split --------------------------------------------
cat("\\section{Regime-Split Re-estimation}\n")
if (!is.null(split) && nrow(split) > 0) {
  cat(sprintf(paste0("Each model is split at its own endogenously identified break. %d regime sub-models ",
                     "were estimated, of which %d fall below 25 observations and are flagged as ",
                     "underpowered.\n\n"),
              nrow(split), sum(split$underpowered)))
  cat("\\begin{longtable}{llrrrrrl}\n\\toprule\n")
  cat("Model & Regime & Years & $n$ & $\\hat\\theta_0$ & (s.e.) & EG-ADF & Note \\\\\n\\midrule\n\\endhead\n")
  for (i in seq_len(nrow(split))) {
    cat(sprintf("%s & %s & %d--%d & %d & %.3f & (%.3f) & %.2f & %s \\\\\n",
      split$Model_ID[i], split$regime[i], split$start_year[i], split$end_year[i], split$n[i],
      split$theta_0[i], split$theta_0_sd[i], split$EG_ADF[i],
      ifelse(split$underpowered[i], "underpowered", "")))
  }
  cat("\\bottomrule\n\\end{longtable}\n")
  cat("\\noindent\\footnotesize Step dummies constant within a sub-sample are dropped before ",
      "re-estimation (they are collinear with the intercept), so sub-sample specifications differ from ",
      "the full-sample one. Sub-sample EG-ADF values are reported without stars because standard ",
      "critical values are unreliable at these sample sizes.\\normalsize\n\n", sep = "")
}
cat("\\FloatBarrier\n")

# ---- Section 6: limitations ---------------------------------------------
cat("\\section{What This Audit Does Not Claim}\n")
cat("\\begin{enumerate}\n")
cat("\\item \\textbf{The hand-rolled Hansen subset statistic is not used for inference.} $L_c^{\\text{core}}$ ",
    "inverts the submatrix $V_{\\text{core,core}}$, ignoring covariance with the nuisance step-dummy ",
    "scores. It failed a self-normalisation check --- independent i.i.d. and AR-sieve nulls produced ",
    "materially different distributions --- whereas the joint $L_c$ agreed across both to within 1\\%. ",
    "Inferential instability verdicts therefore come from \\texttt{strucchange}'s published asymptotics.\n", sep = "")
cat("\\item \\textbf{A null result was not reinterpreted as a finding.} The first bootstrap run returned ",
    "Hansen $p \\approx 0.96$ (``parameters are stable''), contradicting every other diagnostic. That was ",
    "treated as an implementation problem to investigate rather than a result; investigating it is what ",
    "surfaced the ADF defect.\n", sep = "")
cat("\\item \\textbf{A defect in this audit's own code was found and fixed mid-run.} The Gregory--Hansen ",
    "inner ADF initially replicated the same unaugmented-DF bug being audited, inherited from the ",
    "repository's existing convention. The first production run was discarded.\n", sep = "")
cat("\\item \\textbf{Break dates are reported as they came out}, including the disagreement between ",
    "CUSUM (1974), Gregory--Hansen (1977), and the Bai--Perron dates already in the estimation matrix ",
    "(1944, 1965--68, 1981--82, 1996--99, 2010). No date was selected to fit a narrative.\n", sep = "")
cat("\\item \\textbf{Shin LM critical values remain unverified}, carried over from the preceding ",
    "significance-star audit.\n", sep = "")
cat("\\end{enumerate}\n")
cat("\\FloatBarrier\n")

# ---- Section 7: verdict ledger ------------------------------------------
cat("\\section{Consolidated Verdict Ledger}\n")
cat("\\footnotesize\n\\begin{longtable}{p{1.1cm}p{3.2cm}p{7.6cm}p{1.4cm}}\n\\toprule\n")
cat("Model & Theoretical Basis & Evidence & Status \\\\\n\\midrule\n\\endhead\n")
for (i in seq_len(nrow(ledger))) {
  cat(sprintf("%s & %s & %s & \\textbf{%s} \\\\\n\\addlinespace\n",
      ledger$Model_ID[i], esc(ledger$Theoretical_Basis[i]),
      esc(ledger$Evidence[i]), ledger$Status[i]))
}
cat("\\bottomrule\n\\end{longtable}\n\\normalsize\n")
cat("\\noindent\\footnotesize Status definitions (E18 protocol): \\textbf{Promoted} --- cointegration holds ",
    "under the corrected test with no detected instability; \\textbf{Held} --- cointegration supported but ",
    "parameters unstable, so the long-run relation is regime-conditional rather than a fixed-coefficient ",
    "equilibrium; \\textbf{Blocked} --- no cointegration even after correction and allowing a regime shift; ",
    "\\textbf{Rejected} --- evidence inconclusive.\\normalsize\n\n", sep = "")

cat("\\section*{Governing Locks}\n")
cat("E18 (parameter stability audit protocol); E17 (significance stars and critical values); ",
    "E15 (Vogelsang--Wagner triad); E10V (IM-OLS CPR active estimator). Full memo: ",
    "\\texttt{chapter2\\_vault/08\\_audits/2026-08-03\\_section31\\_cointegration\\_failure\\_diagnostics.md}.\n", sep = "")

cat("\\end{document}\n")
sink()
cat("Wrote:", tex_out, "\n")
