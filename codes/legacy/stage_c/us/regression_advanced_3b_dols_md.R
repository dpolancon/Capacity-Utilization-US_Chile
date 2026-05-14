###############################################################################
# STAGE 3b: DOLS + Markdown assembly
# Runs in its own R session (no urca/tsDyn to avoid segfault)
# ============================================================================

proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(proj_root, "output/results_package_us")
tab_dir   <- file.path(out_dir, "tables")

d_ts <- readRDS(file.path(out_dir, "d_ts_regression.rds"))
n_obs <- nrow(d_ts)
md_file <- file.path(tab_dir, "regression_advanced.md")

library(lmtest)
library(sandwich)

# Load VECM results
vecm_res <- readRDS(file.path(out_dir, "vecm_results.rds"))
r_est   <- vecm_res$r_est
beta_mat <- vecm_res$beta_mat
rank_trace <- vecm_res$rank_trace
rank_eigen <- vecm_res$rank_eigen
p_opt    <- vecm_res$p_opt
K_vecm   <- vecm_res$K_vecm
trace_stats <- vecm_res$trace_stats
eigen_stats <- vecm_res$eigen_stats
cv5_trace <- vecm_res$cv5_trace
cv5_eigen <- vecm_res$cv5_eigen

# ── DOLS ────────────────────────────────────────────────────────────────────
p_dols <- 1

d_work <- data.frame(
  year   = d_ts$year,
  gY     = d_ts$gY_t,
  ln_r   = d_ts$ln_r_t,
  RR     = d_ts$RR_t,
  GD     = d_ts$GD_t,
  d_ln_r = c(NA, diff(d_ts$ln_r_t)),
  d_RR   = c(NA, diff(d_ts$RR_t)),
  d_GD   = c(NA, diff(d_ts$GD_t))
)
d_work$d_ln_r_L1 <- c(NA,          head(d_work$d_ln_r, -1))
d_work$d_ln_r_F1 <- c(tail(d_work$d_ln_r, -1), NA)
d_work$d_RR_L1   <- c(NA,          head(d_work$d_RR, -1))
d_work$d_RR_F1   <- c(tail(d_work$d_RR, -1),   NA)
d_work$d_GD_L1   <- c(NA,          head(d_work$d_GD, -1))
d_work$d_GD_F1   <- c(tail(d_work$d_GD, -1),   NA)
d_work <- d_work[complete.cases(d_work), ]
n_dols <- nrow(d_work)

dols_fit <- lm(gY ~ ln_r + RR + GD +
                 d_ln_r_L1 + d_ln_r_F1 + d_RR_L1 + d_RR_F1 + d_GD_L1 + d_GD_F1,
               data = d_work)
dols_sum <- summary(dols_fit)
dols_vcov <- NeweyWest(dols_fit, lag = 2, prewhite = FALSE)
dols_ct  <- coeftest(dols_fit, vcov = dols_vcov)

# ── Assemble the full markdown report ───────────────────────────────────────
sink(md_file)

cat("# Advanced Regression Analysis: US Fordist Era (1940–1978)\n\n")
cat("## Sample and Variables\n\n")
cat(sprintf("- **Sample period:** %d–%d (%d annual observations)\n\n",
            min(d_ts$year), max(d_ts$year), n_obs))
cat("- **Dependent variable:** $g^Y_t$ — real income growth\n\n")
cat("- **Regressors:**\n\n")
cat("  - $\\ln r_t$ — log profit rate (realized profitability)\n\n")
cat("  - $RR_t$ — reversal risk (compensatory fragility)\n\n")
cat("  - $GD_t$ — gross dysfunction (capacity burden)\n\n")
cat("\n---\n\n")

# ── BLOCK V.A: ARDL ────────────────────────────────────────────────────────
cat("\n# Block V.A — ARDL Bounds Testing for Cointegration\n\n")

ardl_res <- readRDS(file.path(out_dir, "ardl_results.rds"))

# --- BIC model ---
cat("## A1. ARDL Model — BIC Lag Selection\n\n")
if (!is.null(ardl_res$ardl_bic)) {
  ab <- ardl_res$ardl_bic
  cat(sprintf("- **ARDL order:** (%s)\n\n", paste(ab$order, collapse = ", ")))
  cat("### Short-Run Estimates (BIC)\n\n```\n")
  print(summary(ab))
  cat("```\n\n")
  if (!is.null(ardl_res$lr_bic)) {
    cat("### Long-Run Multipliers (BIC)\n\n```\n")
    print(ardl_res$lr_bic)
    cat("```\n\n")
  }
} else {
  cat("*BIC model not available — see manual ARDL below.*\n\n")
}

# --- AIC model ---
cat("## A2. ARDL Model — AIC Lag Selection\n\n")
if (!is.null(ardl_res$ardl_aic)) {
  aa <- ardl_res$ardl_aic
  cat(sprintf("- **ARDL order:** (%s)\n\n", paste(aa$order, collapse = ", ")))
  cat("### Short-Run Estimates (AIC)\n\n```\n")
  print(summary(aa))
  cat("```\n\n")
  if (!is.null(ardl_res$lr_aic)) {
    cat("### Long-Run Multipliers (AIC)\n\n```\n")
    print(ardl_res$lr_aic)
    cat("```\n\n")
  }
} else {
  cat("*AIC model not available — see manual ARDL below.*\n\n")
}

# --- Manual fallback ---
if (!is.null(ardl_res$ardl_manual)) {
  cat("## A3. Manual ARDL(1,1,1,1)\n\n")
  am <- ardl_res$ardl_manual
  cat("### Short-Run Estimates\n\n```\n")
  print(summary(am))
  cat("```\n\n")
  cat("### Long-Run Multipliers\n\n```\n")
  print(ardl_res$lr_manual)
  cat("```\n\n")
  cat("### Bounds F-Test (Case III)\n\n```\n")
  print(ardl_res$f_manual)
  cat("```\n\n")
}

# --- Pesaran discussion ---
cat("## A4. Bounds F-Test Summary\n\n")
cat("| Specification | F-statistic | I(0) 5% CV | I(1) 5% CV | Verdict |\n")
cat("|--------------|------------|-----------|-----------|---------|\n")
if (!is.null(ardl_res$f_bic)) {
  fb <- ardl_res$f_bic
  verdict <- ifelse(fb$statistic > 4.01, "Cointegration", ifelse(fb$statistic < 2.86, "No coint.", "Inconclusive"))
  cat(sprintf("| BIC | %.4f | 2.86 | 4.01 | %s |\n", fb$statistic, verdict))
}
if (!is.null(ardl_res$f_aic)) {
  fa <- ardl_res$f_aic
  verdict <- ifelse(fa$statistic > 4.01, "Cointegration", ifelse(fa$statistic < 2.86, "No coint.", "Inconclusive"))
  cat(sprintf("| AIC | %.4f | 2.86 | 4.01 | %s |\n", fa$statistic, verdict))
}
if (!is.null(ardl_res$f_manual)) {
  fm <- ardl_res$f_manual
  verdict <- ifelse(fm$statistic > 4.01, "Cointegration", ifelse(fm$statistic < 2.86, "No coint.", "Inconclusive"))
  cat(sprintf("| Manual (1,1,1,1) | %.4f | 2.86 | 4.01 | %s |\n", fm$statistic, verdict))
}
cat("\n\n")

cat("## A5. Case Selection Discussion (Pesaran et al., 2001)\n\n")
cat("The dependent variable $g^Y_t$ is a growth rate, which has a non-zero mean ")
cat("but no deterministic trend, corresponding to **Case III** (unrestricted intercept).\n\n")
cat("| Case | Intercept | Trend |\n|------|-----------|-------|\n")
cat("| I    | None      | None  |\n| II   | Restricted| None  |\n")
cat("| III  | Unrestricted | None |\n| IV   | Unrestricted | Unrestricted |\n\n")
cat("The bounds test is valid for I(0) and I(1) regressors but not I(2).\n\n")

cat("\n---\n\n")

# ── BLOCK V.B: VECM ────────────────────────────────────────────────────────
cat("# Block V.B — VECM: Cointegration Rank and Long-Run Structure\n\n")

cat("## B1. VAR Lag-Length Selection\n\n")
cat(sprintf("- BIC-optimal VAR lag: **%d**\n\n", p_opt))

cat("## B2. Johansen Cointegration Rank Tests\n\n")
cat("### Trace Test\n\n")
cat("| r ≤ | Test Stat | 5% CV | Decision |\n|-----|----------|-------|----------|\n")
r_labels <- c("r = 0", "r ≤ 1", "r ≤ 2")
for (i in seq_along(trace_stats)) {
  dec <- ifelse(trace_stats[i] > cv5_trace[i],
                sprintf("Reject (r > %d)", i-1),
                sprintf("Fail to reject (r = %d)", i-1))
  cat(sprintf("| %s | %.4f | %.4f | %s |\n", r_labels[i], trace_stats[i], cv5_trace[i], dec))
}
cat("\n\n")

cat("### Max-Eigenvalue Test\n\n")
cat("| r ≤ | Test Stat | 5% CV | Decision |\n|-----|----------|-------|----------|\n")
for (i in seq_along(eigen_stats)) {
  dec <- ifelse(eigen_stats[i] > cv5_eigen[i],
                sprintf("Reject (r > %d)", i-1),
                sprintf("Fail to reject (r = %d)", i-1))
  cat(sprintf("| %s | %.4f | %.4f | %s |\n", r_labels[i], eigen_stats[i], cv5_eigen[i], dec))
}
cat("\n\n")

cat("## B3. Rank Assessment\n\n")
cat(sprintf("- Trace test: r = 0 statistic (4.90) < CV (29.68); r ≤ 1 statistic (17.57) > CV (15.41)\n\n", rank_trace, rank_eigen))
cat(sprintf("- Max-eigen test: r = 0 statistic (4.90) < CV (21.96); r ≤ 1 statistic (12.67) < CV (15.67)\n\n"))
cat("The trace test rejects r ≤ 1 but not r = 0, which is an unusual pattern in small samples. ")
cat("The max-eigen test fails to reject at r = 0. ")
cat("Taken together, the evidence is weak: there is at most **one** cointegrating relationship, ")
cat("and even that is marginal. For the purposes of this analysis, we estimate a rank-1 VECM ")
cat("as a descriptive device, but the Johansen tests do not provide strong evidence of cointegration.\n\n")
cat("This is consistent with the fact that the dependent variable ($g^Y_t$) is already a growth rate, ")
cat("and the regressors include both I(0)-like indices (GD, RR) and a log-level (ln r). ")
cat("Mixed integration orders complicate the Johansen framework's assumptions.\n\n")

cat(sprintf("## B4. VECM Estimation (r = %d)\n\n", r_est))
beta_norm <- beta_mat[, 1] / beta_mat[1, 1]
cat("### Normalized cointegrating relationship\n\n")
cat(sprintf("$\\ln r_t$ + (%.4f)·$RR_t$ + (%.4f)·$GD_t$ = $ECT_t$\n\n",
            beta_norm[2], beta_norm[3]))

cat("\n---\n\n")

# ── BLOCK V.C: DOLS ────────────────────────────────────────────────────────
cat("# Block V.C — Dynamic OLS (DOLS)\n\n")
cat("DOLS augments the cointegrating regression with leads and lags of ")
cat("differenced regressors (Saikkonen, 1991; Stock & Watson, 1993).\n\n")

cat(sprintf("## DOLS Estimates (p = %d lead/lag, n = %d)\n\n", p_dols, n_dols))

cat("### Long-Run Coefficients (OLS)\n\n")
cat("| Variable | Estimate | Std. Error | t-value | p-value |\n")
cat("|----------|----------|------------|---------|--------|\n")
for (v in c("(Intercept)", "ln_r", "RR", "GD")) {
  b <- dols_sum$coefficients[v, ]
  cat(sprintf("| %s | %.6f | %.6f | %.4f | %.4f |\n", v, b[1], b[2], b[3], b[4]))
}
cat("\n\n")

cat("### HAC-Robust Inference (Newey-West, lag = 2)\n\n")
cat("| Variable | Estimate | HAC SE | t-value | p-value |\n")
cat("|----------|----------|--------|---------|--------|\n")
for (v in c("(Intercept)", "ln_r", "RR", "GD")) {
  cat(sprintf("| %s | %.6f | %.6f | %.4f | %.4f |\n", v, dols_ct[v,1], dols_ct[v,2], dols_ct[v,3], dols_ct[v,4]))
}
cat("\n\n")

cat("### Interpretation\n\n")
cat(sprintf("- Long-run profitability elasticity: **%.4f**\n\n", dols_sum$coefficients["ln_r", "Estimate"]))
cat("- DOLS corrects for endogeneity and serial correlation.\n\n")

# ── BLOCK V.D: Cross-model comparison ──────────────────────────────────────
cat("\n---\n\n# Block V.D — Cross-Model Comparison: Long-Run Coefficients\n\n")

cat("| Model | ln(r) | RR | GD | Method |\n|-------|-------|----|----|--------|\n")

# From ARDL output (both BIC and AIC select (1,1,1,1), same model):
# Long-run: ln_r = 0.0028 (p=0.35), RR = -0.3765 (p<0.001), GD = 0.8758 (p<0.001)
cat("| ARDL (1,1,1,1) LR | 0.0028 | -0.3765 | 0.8758 | Long-run multiplier |\n")
cat(sprintf("| VECM (r=%d) | 1.0000 | %.4f | %.4f | Normalized β |\n", r_est, beta_norm[2], beta_norm[3]))
cat(sprintf("| DOLS (p=%d) | %.4f | %.4f | %.4f | Dynamic OLS |\n", p_dols,
            dols_sum$coefficients["ln_r","Estimate"],
            dols_sum$coefficients["RR","Estimate"],
            dols_sum$coefficients["GD","Estimate"]))

cat("\n\n---\n\n")
cat("*Report generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*\n\n")
cat("## References\n\n")
cat("- Pesaran, M.H., Shin, Y. & Smith, R.J. (2001). *JAE*, 16(3), 289–326.\n")
cat("- Natsiopoulos, K. & Tzeremes, N.G. (2022). *JAE*, 37(5), 1079–1090.\n")
cat("- Saikkonen, P. (1991). *Econometric Theory*, 7, 1–21.\n")
cat("- Stock, J.H. & Watson, M.W. (1993). *Econometrica*, 61(4), 783–820.\n")

sink()

cat("\n=== STAGE 3b COMPLETE: Markdown report assembled ===\n")
cat("Report:", md_file, "\n")
