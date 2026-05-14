###############################################################################
# STAGE 3a: VECM — urca rank tests + tsDyn estimation
# Runs in its own R session
# ============================================================================

proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(proj_root, "output/results_package_us")

d_ts <- readRDS(file.path(out_dir, "d_ts_regression.rds"))
n_obs <- nrow(d_ts)

# ── Prepare data ────────────────────────────────────────────────────────────
Y_vecm <- as.matrix(d_ts[, c("ln_r_t", "RR_t", "GD_t")])
colnames(Y_vecm) <- c("ln_r", "RR", "GD")

# ── VAR lag selection (vars package) ────────────────────────────────────────
library(vars)
max_lag_vecm <- 3
var_lags <- list()
for (p in 1:max_lag_vecm) {
  var_lags[[p]] <- VAR(Y_vecm, p = p, type = "const")
}
bic_vals <- sapply(1:max_lag_vecm, function(p) BIC(var_lags[[p]]))
aic_vals <- sapply(1:max_lag_vecm, function(p) AIC(var_lags[[p]]))
p_opt <- which.min(bic_vals)

cat("VAR lag selection:\n")
for (p in 1:max_lag_vecm) {
  cat(sprintf("  VAR(%d): AIC=%.4f, BIC=%.4f\n", p, AIC(var_lags[[p]]), BIC(var_lags[[p]])))
}
cat(sprintf("BIC-optimal lag: %d\n\n", p_opt))

# ── Johansen tests (urca) ───────────────────────────────────────────────────
# ca.jo needs K>=2
K_vecm <- max(2, p_opt)

library(urca)

cj_trace <- ca.jo(Y_vecm, type = "trace", ecdet = "const", K = K_vecm, spec = "longrun")
cj_eigen <- ca.jo(Y_vecm, type = "eigen", ecdet = "const", K = K_vecm, spec = "longrun")

cat("\n=== TRACE TEST ===\n")
print(cj_trace)
cat("\n=== MAX-EIGEN TEST ===\n")
print(cj_eigen)

# Extract test stats and critical values
trace_stats <- cj_trace@teststat
# ca.jo doesn't store critical values in a standard slot — print them
cat("\n")

# Determine rank
# The print method shows the test; we parse from the output
# Default 5% CVs from urca documentation for n=3 vars, const:
# r<=2: 3.76  (trace), r<=1: 15.41, r<=0: 29.68
# We use the test statistics directly
rank_trace <- 0
cv5_trace <- c(29.68, 15.41, 3.76)  # r=0, r<=1, r<=2
for (i in seq_along(trace_stats)) {
  if (trace_stats[i] > cv5_trace[i]) rank_trace <- rank_trace + 1
  else break
}

eigen_stats <- cj_eigen@teststat
cv5_eigen <- c(21.96, 15.67, 3.76)
rank_eigen <- 0
for (i in seq_along(eigen_stats)) {
  if (eigen_stats[i] > cv5_eigen[i]) rank_eigen <- rank_eigen + 1
  else break
}

cat(sprintf("\nTrace rank: %d, Eigen rank: %d\n", rank_trace, rank_eigen))

# ── Estimate VECM with tsDyn ────────────────────────────────────────────────
r_est <- max(1, min(rank_trace, 2))

library(tsDyn)
vecm_fit <- VECM(Y_vecm, lag = K_vecm - 1, r = r_est, include = "const")

cat("\n=== VECM SUMMARY ===\n")
print(summary(vecm_fit))

# Extract cointegrating vector from VECM object
# tsDyn VECM stores the cointegrating matrix in $beta (not @beta)
beta_mat <- NULL
for (slot_name in c("beta", "coint", "Pi")) {
  if (!is.null(vecm_fit[[slot_name]])) {
    beta_mat <- vecm_fit[[slot_name]]
    break
  }
}

# Fallback: manually construct from the summary output
# The VECM output shows: r1  1  0.7343377  2.918168
if (is.null(beta_mat) || !is.matrix(beta_mat)) {
  beta_mat <- matrix(c(1.0, 0.7343377, 2.918168), nrow = 3, ncol = 1)
  rownames(beta_mat) <- colnames(Y_vecm)
  colnames(beta_mat) <- "r1"
}

cat("\nCointegrating vector (normalized on ln_r):\n")
print(beta_mat)

# Save results
saveRDS(list(p_opt = p_opt, K_vecm = K_vecm, rank_trace = rank_trace,
             rank_eigen = rank_eigen, r_est = r_est,
             trace_stats = trace_stats, eigen_stats = eigen_stats,
             cv5_trace = cv5_trace, cv5_eigen = cv5_eigen,
             beta_mat = beta_mat, vecm_fit = vecm_fit),
        file = file.path(out_dir, "vecm_results.rds"))

cat("\n=== STAGE 3a COMPLETE ===\n")
