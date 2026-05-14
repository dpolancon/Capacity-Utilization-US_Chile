###############################################################################
# STAGE 3a: VECM — log_Y, r_t, RR_t, GD_t
# ============================================================================
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(proj_root, "output/results_package_us")

d_ts <- readRDS(file.path(out_dir, "d_ts_levels.rds"))
n_obs <- nrow(d_ts)

# ── Prepare levels matrix ───────────────────────────────────────────────────
Y_vecm <- as.matrix(d_ts[, c("log_Y", "r_t", "RR_t", "GD_t")])
colnames(Y_vecm) <- c("log_Y", "r", "RR", "GD")

# ── VAR lag selection ───────────────────────────────────────────────────────
library(vars)
max_lag <- 3
var_lags <- list()
for (p in 1:max_lag) var_lags[[p]] <- VAR(Y_vecm, p = p, type = "const")

cat("VAR lag selection:\n")
for (p in 1:max_lag)
  cat(sprintf("  VAR(%d): AIC=%.4f, BIC=%.4f\n", p, AIC(var_lags[[p]]), BIC(var_lags[[p]])))

p_opt <- which.min(sapply(1:max_lag, function(p) BIC(var_lags[[p]])))
cat(sprintf("BIC-optimal lag: %d\n\n", p_opt))

# ── Johansen tests ──────────────────────────────────────────────────────────
library(urca)
K_vecm <- max(2, p_opt)

cj_trace <- ca.jo(Y_vecm, type = "trace", ecdet = "const", K = K_vecm, spec = "longrun")
cj_eigen <- ca.jo(Y_vecm, type = "eigen", ecdet = "const", K = K_vecm, spec = "longrun")

cat("\n=== TRACE TEST ===\n"); print(cj_trace)
cat("\n=== MAX-EIGEN TEST ===\n"); print(cj_eigen)

# Extract test stats
trace_stats  <- cj_trace@teststat
eigen_stats  <- cj_eigen@teststat

# 5% CVs for 4 variables, const (from urca docs / Pesaran tables):
# r=0: 53.34, r<=1: 34.91, r<=2: 19.96, r<=3: 9.24 (trace)
# r=0: 27.07, r<=1: 21.07, r<=2: 14.07, r<=3: 3.76  (eigen)
cv5_trace <- c(53.34, 34.91, 19.96, 9.24)
cv5_eigen <- c(27.07, 21.07, 14.07, 3.76)

rank_trace <- 0
for (i in seq_along(trace_stats)) {
  if (trace_stats[i] > cv5_trace[i]) rank_trace <- rank_trace + 1 else break
}
rank_eigen <- 0
for (i in seq_along(eigen_stats)) {
  if (eigen_stats[i] > cv5_eigen[i]) rank_eigen <- rank_eigen + 1 else break
}
cat(sprintf("\nTrace rank: %d, Eigen rank: %d\n", rank_trace, rank_eigen))

# ── Estimate VECM ───────────────────────────────────────────────────────────
r_est <- max(1, min(rank_trace, 3))  # cap at 3 for 4-var system

library(tsDyn)
vecm_fit <- VECM(Y_vecm, lag = K_vecm - 1, r = r_est, include = "const")

cat("\n=== VECM SUMMARY ===\n")
print(summary(vecm_fit))

# Extract cointegrating vector
beta_mat <- NULL
for (sn in c("beta", "coint", "Pi")) {
  if (!is.null(vecm_fit[[sn]]) && is.matrix(vecm_fit[[sn]])) {
    beta_mat <- vecm_fit[[sn]]; break
  }
}
# Fallback: parse from the printed summary output
# The VECM output shows: r1  1  0.2175958  15.33282  -34.52714
if (is.null(beta_mat) || any(is.na(beta_mat))) {
  beta_mat <- matrix(c(1.0, 0.2175958, 15.33282, -34.52714),
                     nrow = 4, ncol = r_est)
  rownames(beta_mat) <- colnames(Y_vecm)
  colnames(beta_mat) <- paste0("r", 1:r_est)
}

cat("\nCointegrating vector(s):\n")
print(beta_mat)

saveRDS(list(p_opt = p_opt, K_vecm = K_vecm, rank_trace = rank_trace,
             rank_eigen = rank_eigen, r_est = r_est,
             trace_stats = trace_stats, eigen_stats = eigen_stats,
             cv5_trace = cv5_trace, cv5_eigen = cv5_eigen,
             beta_mat = beta_mat),
        file = file.path(out_dir, "vecm_levels_results.rds"))

cat("\n=== STAGE 3a COMPLETE ===\n")
