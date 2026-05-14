###############################################################################
# STAGE 3b: DOLS (cointReg) + Markdown assembly
# ============================================================================
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(proj_root, "output/results_package_us")
tab_dir   <- file.path(out_dir, "tables")

d_ts <- readRDS(file.path(out_dir, "d_ts_levels.rds"))
n_obs <- nrow(d_ts)
md_file <- file.path(tab_dir, "reg_levels_advanced.md")

vecm_res <- readRDS(file.path(out_dir, "vecm_levels_results.rds"))
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

# ── DOLS via cointReg ───────────────────────────────────────────────────────
library(cointReg)

cat("Estimating DOLS...\n")

y_dols <- d_ts$log_Y
x_dols <- as.matrix(d_ts[, c("r_t", "RR_t", "GD_t")])
colnames(x_dols) <- c("r", "RR", "GD")

dols_fit <- cointRegD(
  x = x_dols,
  y = y_dols,
  kernel = "ba",
  bandwidth = "and",
  n.lead = 1,
  n.lag = 1
)

cat("DOLS estimated.\n")
dols_sum <- summary(dols_fit)

# cointRegD stores: beta = long-run coefficients, theta = lead/lag terms
# varmat = variance-covariance matrix
cat("\n=== DOLS RESULTS ===\n")
cat("Long-run coefficients (beta):\n")
print(dols_fit$beta)
cat("t-stats (theta):\n")
print(dols_fit$t.theta)
cat("p-values (theta):\n")
print(dols_fit$p.theta)

# ── Assemble markdown ───────────────────────────────────────────────────────
sink(md_file)

cat("# Advanced Regression Analysis: US Fordist Era (1940–1978)\n\n")
cat("## Specification\n\n")
cat("- **Dependent variable:** $\\ln Y_t$ — log real income (level)\n\n")
cat("- **Regressors:**\n\n")
cat("  - $r_t$ — profit rate (level)\n\n")
cat("  - $RR_t$ — reversal risk\n\n")
cat("  - $GD_t$ — gross dysfunction\n\n")
cat(sprintf("- **Sample:** %d observations (%d–%d)\n\n",
            n_obs, min(d_ts$year), max(d_ts$year)))
cat("\n---\n\n")

# ── BLOCK V.A: ARDL ────────────────────────────────────────────────────────
cat("\n# Block V.A — ARDL Bounds Testing for Cointegration\n\n")

ardl_res <- readRDS(file.path(out_dir, "ardl_levels_results.rds"))

# --- BIC ---
cat("## A1. ARDL Model — BIC Lag Selection\n\n")
if (!is.null(ardl_res$ardl_bic)) {
  ab <- ardl_res$ardl_bic
  cat(sprintf("- **ARDL order:** (%s), BIC = %.4f\n\n",
              paste(ab$order, collapse = ", "), ab$ic_val))
  cat("### Short-Run Estimates\n\n```\n")
  print(summary(ab))
  cat("```\n\n")
  if (!is.null(ardl_res$lr_bic)) {
    cat("### Long-Run Multipliers\n\n```\n"); print(ardl_res$lr_bic); cat("```\n\n")
  }
  if (!is.null(ardl_res$f_bic)) {
    cat("### Bounds F-Test\n\n```\n"); print(ardl_res$f_bic); cat("```\n\n")
    cat(sprintf("**F = %.4f** | I(0) 5%% CV = 2.86 | I(1) 5%% CV = 4.01\n\n",
                ardl_res$f_bic$statistic))
  }
} else { cat("*BIC model unavailable.*\n\n") }

# --- AIC ---
cat("## A2. ARDL Model — AIC Lag Selection\n\n")
if (!is.null(ardl_res$ardl_aic)) {
  aa <- ardl_res$ardl_aic
  cat(sprintf("- **ARDL order:** (%s), AIC = %.4f\n\n",
              paste(aa$order, collapse = ", "), aa$ic_val))
  cat("### Short-Run Estimates\n\n```\n")
  print(summary(aa))
  cat("```\n\n")
  if (!is.null(ardl_res$lr_aic)) {
    cat("### Long-Run Multipliers\n\n```\n"); print(ardl_res$lr_aic); cat("```\n\n")
  }
  if (!is.null(ardl_res$f_aic)) {
    cat("### Bounds F-Test\n\n```\n"); print(ardl_res$f_aic); cat("```\n\n")
    cat(sprintf("**F = %.4f** | I(0) 5%% CV = 2.86 | I(1) 5%% CV = 4.01\n\n",
                ardl_res$f_aic$statistic))
  }
} else { cat("*AIC model unavailable.*\n\n") }

# --- Bounds summary ---
cat("## A3. Bounds F-Test Summary\n\n")
cat("| Specification | F-statistic | I(0) 5% CV | I(1) 5% CV | Verdict |\n")
cat("|--------------|------------|-----------|-----------|---------|\n")
for (label in c("BIC", "AIC")) {
  fv <- ardl_res[[paste0("f_", tolower(label))]]
  if (!is.null(fv)) {
    v <- ifelse(fv$statistic > 4.01, "Cointegration",
         ifelse(fv$statistic < 2.86, "No coint.", "Inconclusive"))
    cat(sprintf("| %s | %.4f | 2.86 | 4.01 | %s |\n", label, fv$statistic, v))
  }
}
cat("\n\n")

# --- Pesaran discussion ---
cat("## A4. Case Selection (Pesaran et al., 2001)\n\n")
cat("The dependent variable $\\ln Y_t$ is a level with a deterministic trend, ")
cat("corresponding to **Case IV** (unrestricted intercept + unrestricted trend). ")
cat("The ARDL package default is Case III (unrestricted intercept, no trend), ")
cat("so the critical values reported are slightly conservative.\n\n")

cat("\n---\n\n")

# ── BLOCK V.B: VECM ────────────────────────────────────────────────────────
cat("# Block V.B — VECM: Cointegration Rank and Long-Run Structure\n\n")

cat("## B1. VAR Lag-Length Selection\n\n")
cat(sprintf("- BIC-optimal VAR lag: **%d** (4-variable system)\n\n", p_opt))

cat("## B2. Johansen Cointegration Rank Tests\n\n")
r_labels <- c("r = 0", "r ≤ 1", "r ≤ 2", "r ≤ 3")
n_ranks <- min(length(trace_stats), 4)

cat("### Trace Test\n\n")
cat("| r ≤ | Test Stat | 5% CV | Decision |\n|-----|----------|-------|----------|\n")
for (i in 1:n_ranks) {
  dec <- ifelse(trace_stats[i] > cv5_trace[i],
                sprintf("Reject (r > %d)", i-1),
                sprintf("Fail to reject (r = %d)", i-1))
  cat(sprintf("| %s | %.4f | %.4f | %s |\n", r_labels[i], trace_stats[i], cv5_trace[i], dec))
}
cat("\n\n")

cat("### Max-Eigenvalue Test\n\n")
cat("| r ≤ | Test Stat | 5% CV | Decision |\n|-----|----------|-------|----------|\n")
for (i in 1:n_ranks) {
  dec <- ifelse(eigen_stats[i] > cv5_eigen[i],
                sprintf("Reject (r > %d)", i-1),
                sprintf("Fail to reject (r = %d)", i-1))
  cat(sprintf("| %s | %.4f | %.4f | %s |\n", r_labels[i], eigen_stats[i], cv5_eigen[i], dec))
}
cat("\n\n")

cat("## B3. Rank Assessment\n\n")
cat(sprintf("- Trace test: **r = %d**, Max-eigen test: **r = %d**\n\n",
            rank_trace, rank_eigen))
if (rank_trace == rank_eigen) {
  cat("Both tests agree.\n\n")
} else {
  cat("Tests disagree; trace test is more reliable in small samples.\n\n")
}
if (rank_trace >= 1) {
  cat(sprintf("A rank-%d VECM is identified", min(rank_trace, 3)))
  if (rank_trace >= 2) {
    cat(", implying multiple cointegrating relationships among the four variables.")
  } else {
    cat(".")
  }
  cat("\n\n")
} else {
  cat("No cointegration detected; VAR in differences would be appropriate.\n\n")
}

cat(sprintf("## B4. VECM Estimation (r = %d)\n\n", r_est))

if (!is.null(beta_mat) && is.matrix(beta_mat) && ncol(beta_mat) >= 1) {
  # Normalize on first variable (log_Y)
  bn <- beta_mat[, 1] / beta_mat[1, 1]
  cat("### Normalized cointegrating relationship\n\n")
  cat(sprintf("$\\ln Y_t$ + (%.4f)·$r_t$ + (%.4f)·$RR_t$ + (%.4f)·$GD_t$ = $ECT_t$\n\n",
              bn[2], bn[3], bn[4]))
}

cat("\n---\n\n")

# ── BLOCK V.C: DOLS ────────────────────────────────────────────────────────
cat("# Block V.C — Dynamic OLS (DOLS)\n\n")
cat("DOLS estimated via `cointReg` (Saikkonen, 1991; Stock & Watson, 1993)\n\n")

cat(sprintf("## DOLS Estimates (p = 1 lead/lag, n = %d)\n\n", n_obs))

cat("### DOLS Coefficients (Long-Run)\n\n")

# dols_fit$beta = estimates, dols_fit$sd.theta = std errors, dols_fit$t.theta = t-stats
# dols_fit$varmat = full covariance matrix
coef_names_dols <- c("r", "RR", "GD")
beta_est <- dols_fit$beta
# Standard errors: extract from varmat (which is the long-run variance-covariance)
# The diagonal of varmat contains variances; sqrt gives SEs
# cointReg stores SE in sqrt(diag(varmat)) for the beta portion
# For simplicity, compute t-stats from theta output
t_vals <- dols_fit$t.theta
p_vals <- dols_fit$p.theta

# The varmat is the full covariance; first 3x3 block is for beta
if (!is.null(dols_fit$varmat) && is.matrix(dols_fit$varmat)) {
  var_beta <- dols_fit$varmat[1:3, 1:3]
  se_beta <- sqrt(diag(var_beta))
} else {
  se_beta <- rep(NA, 3)
}

cat("| Variable | Estimate | Std. Error | t-value | p-value |\n")
cat("|----------|----------|------------|---------|--------|\n")
for (i in seq_along(coef_names_dols)) {
  v <- coef_names_dols[i]
  cat(sprintf("| %s | %.6f | %.6f | %.4f | %.4f |\n",
              v, beta_est[i], se_beta[i], t_vals[i], p_vals[i]))
}
cat("\n\n")

cat("### Interpretation\n\n")
cat(sprintf("- The profit rate coefficient is **%.6f** (t = %.4f, p = %.4f).\n\n",
            beta_est[1], t_vals[1], p_vals[1]))
cat("- DOLS corrects for endogeneity and serial correlation via leads and lags.\n\n")

# ── BLOCK V.D: Cross-model comparison ──────────────────────────────────────
cat("\n---\n\n# Block V.D — Cross-Model Comparison: Long-Run Coefficients\n\n")

cat("| Model | r | RR | GD | Method |\n|-------|-------|----|----|--------|\n")

if (!is.null(ardl_res$lr_bic) && !is.null(ardl_res$lr_bic$longrun)) {
  lb <- ardl_res$lr_bic$longrun
  cat(sprintf("| ARDL (BIC) LR | %.4f | %.4f | %.4f | Long-run multiplier |\n",
              lb["r_t"], lb["RR_t"], lb["GD_t"]))
}
if (!is.null(ardl_res$lr_aic) && !is.null(ardl_res$lr_aic$longrun)) {
  la <- ardl_res$lr_aic$longrun
  cat(sprintf("| ARDL (AIC) LR | %.4f | %.4f | %.4f | Long-run multiplier |\n",
              la["r_t"], la["RR_t"], la["GD_t"]))
}
if (!is.null(beta_mat) && is.matrix(beta_mat) && ncol(beta_mat) >= 1) {
  bn <- beta_mat[, 1] / beta_mat[1, 1]
  cat(sprintf("| VECM (r=%d) | 1.0000 | %.4f | %.4f | %.4f | Normalized β |\n",
              r_est, bn[2], bn[3], bn[4]))
}
cat(sprintf("| DOLS (p=1) | %.4f | %.4f | %.4f | Dynamic OLS |\n",
            beta_est[1], beta_est[2], beta_est[3]))

cat("\n\n---\n\n")
cat("*Report generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*\n\n")
cat("## References\n\n")
cat("- Pesaran, M.H., Shin, Y. & Smith, R.J. (2001). *JAE*, 16(3), 289–326.\n")
cat("- Natsiopoulos, K. & Tzeremes, N.G. (2022). *JAE*, 37(5), 1079–1090.\n")
cat("- Saikkonen, P. (1991). *Econometric Theory*, 7, 1–21.\n")
cat("- Stock, J.H. & Watson, M.W. (1993). *Econometrica*, 61(4), 783–820.\n")

sink()

cat("\n=== STAGE 3b COMPLETE ===\n")
cat("Report:", md_file, "\n")
