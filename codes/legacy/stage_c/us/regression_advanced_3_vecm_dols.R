###############################################################################
# STAGE 3: VECM (tsDyn/urca) + DOLS (manual) — appends to the ARDL markdown
# ============================================================================

proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(proj_root, "output/results_package_us")
tab_dir   <- file.path(out_dir, "tables")

# Load pre-built data
d_ts <- readRDS(file.path(out_dir, "d_ts_regression.rds"))
n_obs <- nrow(d_ts)

# Load packages individually
library(tsDyn)
library(urca)
library(lmtest)
library(sandwich)

# ── Prepare levels data for VECM ────────────────────────────────────────────
Y_vecm <- as.matrix(d_ts[, c("ln_r_t", "RR_t", "GD_t")])
colnames(Y_vecm) <- c("ln_r", "RR", "GD")

md_file <- file.path(tab_dir, "regression_advanced.md")

sink(md_file, append = TRUE)

# ============================================================================
# BLOCK V.B — VECM MODEL
# ============================================================================

cat("\n---\n\n")
cat("# Block V.B — VECM: Cointegration Rank and Long-Run Structure\n\n")

# ── B1. VAR lag-length selection ───────────────────────────────────────────
cat("## B1. VAR Lag-Length Selection\n\n")

library(vars)
max_lag_vecm <- 3
var_lags <- list()
for (p in 1:max_lag_vecm) {
  var_lags[[p]] <- VAR(Y_vecm, p = p, type = "const")
}

for (p in 1:max_lag_vecm) {
  cat(sprintf("- VAR(%d): AIC = %.4f, BIC = %.4f\n",
              p, AIC(var_lags[[p]]), BIC(var_lags[[p]])))
}
cat("\n")

# Select lag by BIC
bic_vals <- sapply(1:max_lag_vecm, function(p) BIC(var_lags[[p]]))
p_opt <- which.min(bic_vals)
cat(sprintf("- **BIC-optimal VAR lag:** %d\n\n", p_opt))

# ── B2. Johansen cointegration rank tests ──────────────────────────────────
cat("## B2. Johansen Cointegration Rank Tests\n\n")

# Use urca::ca.jo
K_vecm <- max(2, p_opt - 1)  # VECM lag order = VAR lag - 1; ca.jo needs K>=2

cj <- ca.jo(Y_vecm, type = "trace", ecdet = "const",
            K = K_vecm, spec = "longrun", season = NULL)

cat("### Trace Test\n\n")
cat("```\n")
print(cj)
cat("```\n\n")

cj_max <- ca.jo(Y_vecm, type = "eigen", ecdet = "const",
                K = K_vecm, spec = "longrun", season = NULL)

cat("### Max-Eigenvalue Test\n\n")
cat("```\n")
print(cj_max)
cat("```\n\n")

# ── B3. Rank discussion ────────────────────────────────────────────────────
cat("## B3. Cointegration Rank Assessment\n\n")

trace_stats <- cj@teststat
trace_cv10  <- cj@criticalval[, "10pct"]
trace_cv5   <- cj@criticalval[, "5pct"]
trace_cv1   <- cj@criticalval[, "1pct"]
r_names     <- cj@cvalnames

cat("### Trace Test Summary\n\n")
cat("| r ≤ | Test Stat | 10% CV | 5% CV | 1% CV | Decision (5%) |\n")
cat("|-----|----------|--------|-------|-------|---------------|\n")
for (i in 1:length(trace_stats)) {
  decision <- ifelse(trace_stats[i] > trace_cv5[i],
                     sprintf("Reject (r > %d)", i-1),
                     sprintf("Fail to reject (r = %d)", i-1))
  cat(sprintf("| %s | %.4f | %.4f | %.4f | %.4f | %s |\n",
              r_names[i], trace_stats[i], trace_cv10[i], trace_cv5[i],
              trace_cv1[i], decision))
}
cat("\n\n")

rank_trace <- sum(trace_stats > trace_cv5)
cat(sprintf("- **Trace test indicates rank r = %d** (5%% level).\n\n", rank_trace))

eigen_stats <- cj_max@teststat
eigen_cv5   <- cj_max@criticalval[, "5pct"]
rank_eigen <- sum(eigen_stats > eigen_cv5)
cat(sprintf("- **Max-eigen test indicates rank r = %d** (5%% level).\n\n", rank_eigen))

if (rank_trace == rank_eigen) {
  cat(sprintf("- **Both tests agree on rank = %d.**\n\n", rank_trace))
} else {
  cat("- **Tests disagree.** Trace test is generally more reliable in small samples.\n\n")
}

cat("### Feasibility of higher-rank models\n\n")
if (rank_trace >= 1) {
  cat("A rank-1 VECM is identified. ")
  if (rank_trace >= 2) {
    cat("The trace test also supports **rank = 2**, suggesting two cointegrating relationships ")
    cat("among the three variables. This implies a richer long-run structure ")
    cat(sprintf("but is harder to estimate precisely with only %d observations.\n\n", n_obs))
  } else {
    cat("The trace test does **not** support rank > 1. ")
    cat("A single cointegrating vector is the only statistically defensible specification.\n\n")
  }
} else {
  cat("Neither test supports cointegration. A VAR in differences would be more appropriate.\n\n")
}

# ── B4. Estimate VECM with rank = 1 ────────────────────────────────────────
r_est <- max(1, min(rank_trace, 2))

cat(sprintf("\n## B4. VECM Estimation (r = %d, VAR lag = %d)\n\n", r_est, p_opt))

vecm_fit <- VECM(Y_vecm, lag = K_vecm, r = r_est, include = "const")

cat("### Adjustment Coefficients (α)\n\n")
cat("```\n")
print(vecm_fit@beta)
cat("```\n\n")

# The cointegrating vectors are stored in vecm_fit@beta
# But tsDyn stores them differently — let's extract properly
cat("### Cointegrating Relations (β)\n\n")

# tsDyn VECM stores the normalized cointegrating vector in @beta
# The first element is normalized to 1
beta_mat <- vecm_fit@beta
cat("```\n")
print(beta_mat)
cat("```\n\n")

cat("### Normalized cointegrating relationship\n\n")
if (r_est >= 1 && nrow(beta_mat) >= 3) {
  # beta is stored as a matrix; first row is the normalization
  beta_norm <- beta_mat[, 1] / beta_mat[1, 1]
  cat(sprintf("The estimated long-run relationship is:\n\n"))
  cat(sprintf("$\\ln r_t$ + (%.4f)·$RR_t$ + (%.4f)·$GD_t$ = $ECT_t$\n\n",
              beta_norm[2], beta_norm[3]))
}

cat("### Error-correction dynamics\n\n")
cat("```\n")
print(summary(vecm_fit))
cat("```\n\n")

sink()

# ============================================================================
# BLOCK V.C — DOLS (Dynamic OLS)
# ============================================================================

sink(md_file, append = TRUE)

cat("\n---\n\n")
cat("# Block V.C — Dynamic OLS (DOLS)\n\n")
cat("## Methodology\n\n")
cat("Dynamic OLS (Saikkonen, 1991; Stock & Watson, 1993) augments the static ")
cat("cointegrating regression with leads and lags of the first differences of ")
cat("regressors to eliminate endogeneity bias and serial correlation.\n\n")
cat("$$g^Y_t = \\alpha + \\beta_1 \\ln r_t + \\beta_2 RR_t + \\beta_3 GD_t ")
cat("+ \\sum_{j=-p}^{p} \\gamma_j \\Delta X_{t-j} + \\varepsilon_t$$\n\n")
cat("where $X_t = (\\ln r_t, RR_t, GD_t)'$ and $p = 1$.\n\n")

# ── C1. Prepare DOLS data ──────────────────────────────────────────────────
p_dols <- 1

# First differences
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

# Leads and lags
d_work$d_ln_r_L1 <- c(NA,        head(d_work$d_ln_r, -1))
d_work$d_ln_r_F1 <- c(tail(d_work$d_ln_r, -1), NA)
d_work$d_RR_L1   <- c(NA,        head(d_work$d_RR, -1))
d_work$d_RR_F1   <- c(tail(d_work$d_RR, -1),   NA)
d_work$d_GD_L1   <- c(NA,        head(d_work$d_GD, -1))
d_work$d_GD_F1   <- c(tail(d_work$d_GD, -1),   NA)

# Drop rows with any NA
d_work <- d_work[complete.cases(d_work), ]
n_dols <- nrow(d_work)
cat("DOLS sample:", n_dols, "observations\n")

# ── C2. Estimate DOLS ──────────────────────────────────────────────────────
dols_fit <- lm(gY ~ ln_r + RR + GD +
                 d_ln_r_L1 + d_ln_r_F1 +
                 d_RR_L1   + d_RR_F1 +
                 d_GD_L1   + d_GD_F1,
               data = d_work)

cat("## DOLS Estimates (p = ", p_dols, " lead/lag)\n\n", sep = "")

cat("### Long-Run Coefficients (OLS)\n\n")
cat("| Variable | Estimate | Std. Error | t-value | p-value |\n")
cat("|----------|----------|------------|---------|--------|\n")

dols_sum <- summary(dols_fit)
lr_vars <- c("(Intercept)", "ln_r", "RR", "GD")
for (v in lr_vars) {
  b <- dols_sum$coefficients[v, ]
  cat(sprintf("| %s | %.6f | %.6f | %.4f | %.4f |\n",
              v, b["Estimate"], b["Std. Error"], b["t value"], b["Pr(>|t|)"]))
}
cat("\n\n")

cat("### Model Fit\n\n")
cat(sprintf("- **R²:** %.4f\n\n", dols_sum$r.squared))
cat(sprintf("- **Adjusted R²:** %.4f\n\n", dols_sum$adj.r.squared))
cat(sprintf("- **Residual SD:** %.6f\n\n", dols_sum$sigma))

# HAC inference
cat("### HAC-Robust Inference (Newey-West, lag = 2)\n\n")
dols_vcov <- NeweyWest(dols_fit, lag = 2, prewhite = FALSE)
dols_ct  <- coeftest(dols_fit, vcov = dols_vcov)

cat("| Variable | Estimate | HAC SE | t-value | p-value |\n")
cat("|----------|----------|--------|---------|--------|\n")
for (v in lr_vars) {
  cat(sprintf("| %s | %.6f | %.6f | %.4f | %.4f |\n",
              v, dols_ct[v, 1], dols_ct[v, 2], dols_ct[v, 3], dols_ct[v, 4]))
}
cat("\n\n")

cat("### Interpretation\n\n")
beta_dols_lr <- dols_sum$coefficients["ln_r", "Estimate"]
cat(sprintf("- The long-run elasticity of income growth with respect to profitability ")
cat(sprintf("is %.4f.\n\n", beta_dols_lr)))
cat("- DOLS corrects for endogeneity of the profit rate and serial correlation ")
cat("by including leads and lags of differenced regressors.\n\n")
cat("- If the DOLS coefficient differs materially from the ARDL long-run multiplier, ")
cat("this suggests either endogeneity bias in static OLS or sensitivity to ")
cat("the dynamic augmentation scheme.\n\n")

# ── C3. Cross-model comparison ─────────────────────────────────────────────
cat("\n---\n\n")
cat("# Block V.D — Cross-Model Comparison: Long-Run Coefficients\n\n")

cat("| Model | ln(r) | RR | GD | Method |\n")
cat("|-------|-------|----|----|--------|\n")

# ARDL
if (file.exists(file.path(out_dir, "ardl_results.rds"))) {
  ardl_res <- readRDS(file.path(out_dir, "ardl_results.rds"))
  if (!is.null(ardl_res$lr_bic)) {
    lb <- ardl_res$lr_bic$longrun
    if (!is.null(lb)) {
      cat(sprintf("| ARDL (BIC) | %.4f | %.4f | %.4f | Long-run multiplier |\n",
                  lb["ln_r_t"], lb["RR_t"], lb["GD_t"]))
    }
  }
  if (!is.null(ardl_res$lr_aic)) {
    la <- ardl_res$lr_aic$longrun
    if (!is.null(la)) {
      cat(sprintf("| ARDL (AIC) | %.4f | %.4f | %.4f | Long-run multiplier |\n",
                  la["ln_r_t"], la["RR_t"], la["GD_t"]))
    }
  }
}

# VECM
if (exists("beta_norm") && length(beta_norm) >= 3) {
  cat(sprintf("| VECM (r=%d) | 1.0000 | %.4f | %.4f | Normalized β |\n",
              r_est, beta_norm[2], beta_norm[3]))
}

# DOLS
cat(sprintf("| DOLS (p=%d) | %.4f | %.4f | %.4f | Dynamic OLS |\n",
            p_dols,
            dols_sum$coefficients["ln_r", "Estimate"],
            dols_sum$coefficients["RR", "Estimate"],
            dols_sum$coefficients["GD", "Estimate"]))

cat("\n\n")
cat("---\n\n")
cat("*Report generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "*\n\n")
cat("## References\n\n")
cat("- Pesaran, M.H., Shin, Y. & Smith, R.J. (2001). Bounds testing approaches to ")
cat("the analysis of levels relationships. *Journal of Applied Econometrics*, 16(3), 289–326.\n\n")
cat("- Natsiopoulos, K. & Tzeremes, N.G. (2022). ARDL bounds test for cointegration: ")
cat("Replicating the Pesaran et al. (2001) results. *Journal of Applied Econometrics*, 37(5), 1079–1090.\n\n")
cat("- Saikkonen, P. (1991). Asymptotically efficient estimation of cointegrating regression models. ")
cat("*Econometric Theory*, 7, 1–21.\n\n")
cat("- Stock, J.H. & Watson, M.W. (1993). A simple estimator of cointegrating vectors in higher order integrated systems. ")
cat("*Econometrica*, 61(4), 783–820.\n\n")

sink()

cat("\n=== STAGE 3 COMPLETE: VECM + DOLS + report assembled ===\n")
cat("Markdown report:", md_file, "\n")
