# 39_restricted_vecm_absolute_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Restricted VECM — alpha row + Gamma block restrictions
#
# Restrictions:
#   R1: alpha[omega_k, .] = 0  (interaction does not error-correct)
#   R2: Gamma[omega_k, .] = 0, Gamma[., omega_k] = 0
#       (interaction excluded from short-run dynamics in both directions)
#
# With beta fixed from Johansen, the VECM is linear in (alpha, Gamma).
# Restrictions are within-equation exclusions → equation-by-equation OLS
# is constrained MLE under Gaussian errors.
#
# State vector: X = (y, k, omega, omega_k) in absolute 2024-price log-levels.
# K=2, ecdet="const", spec="longrun", r=3.
# ═══════════════════════════════════════════════════════════════════════════════

library(urca); library(tseries); library(vars)
library(dplyr); library(readr)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

csv_dir <- file.path(REPO, "output/stage_a/us/csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)


# ═══════════════════════════════════════════════════════════════════════════════
# 0. DATA — absolute 2024-price log-levels (same as script 37)
# ═══════════════════════════════════════════════════════════════════════════════
nf  <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
nf  <- merge(nf, inc[, c("year", "Py_fred")], by = "year")
nf  <- nf[order(nf$year), ]

Py_2024 <- nf$Py_fred[nf$year == 2024]
nf$Py_rebased <- nf$Py_fred / Py_2024
nf$GVA_real   <- nf$GVA_NF / nf$Py_rebased
nf$KGC_real   <- nf$KGC_NF / nf$Py_rebased

nf$y_t     <- log(nf$GVA_real)
nf$k_t     <- log(nf$KGC_real)
nf$omega_t <- nf$Wsh_NF
nf$omega_k <- nf$omega_t * nf$k_t

X     <- as.matrix(nf[, c("y_t", "k_t", "omega_t", "omega_k")])
N     <- nrow(X)
years <- nf$year
K_lag <- 2
p     <- ncol(X)
var_names <- c("y", "k", "omega", "omega_k")

cat(sprintf("Sample: %d-%d (%d obs) | K=%d\n", min(years), max(years), N, K_lag))


# ═══════════════════════════════════════════════════════════════════════════════
# 1. JOHANSEN — unrestricted beta
# ═══════════════════════════════════════════════════════════════════════════════
jo <- ca.jo(X, type = "trace", ecdet = "const", K = K_lag, spec = "longrun")
r  <- 3

beta_raw <- jo@V[, 1:r]
rownames(beta_raw) <- c("y", "k", "omega", "omega_k", "const")
colnames(beta_raw) <- paste0("CV", 1:r)

cat(sprintf("Rank r=%d | Eigenvalues: %s\n", r,
    paste(round(jo@lambda[1:r], 4), collapse = ", ")))

# Rotated beta for display
b1 <- beta_raw[, 1] / beta_raw[1, 1]  # CV1 norm on y
b2 <- beta_raw[, 2] / beta_raw[2, 2]  # CV2 norm on k
b3 <- beta_raw[, 3] / beta_raw[1, 3]  # CV3 norm on y
beta_rot <- cbind(CV1 = b1, CV2 = b2, CV3 = b3)

cat("\nRotated beta (CV1:y, CV2:k, CV3:y):\n")
print(round(beta_rot, 4))


# ═══════════════════════════════════════════════════════════════════════════════
# 2. CONSTRUCT REGRESSION MATRICES
# ═══════════════════════════════════════════════════════════════════════════════

# ECT series: X_aug %*% beta_raw
X_aug   <- cbind(X, 1)           # N x 5
ECT_all <- X_aug %*% beta_raw   # N x 3

# First differences
dX_full <- diff(X)               # (N-1) x 4
colnames(dX_full) <- paste0("d", var_names)

# Effective sample: with K=2, one lag of dX
idx_dep  <- K_lag:(N - 1)        # indices into dX_full
n_eff    <- length(idx_dep)

dY       <- dX_full[idx_dep, , drop = FALSE]         # n_eff x 4 (dependent)
ECT_reg  <- ECT_all[idx_dep, , drop = FALSE]         # n_eff x 3 (ECTs at time t)
dX_lag1  <- dX_full[idx_dep - 1, , drop = FALSE]     # n_eff x 4 (lagged diffs)

colnames(ECT_reg) <- paste0("ECT", 1:r)
colnames(dX_lag1) <- paste0("d", var_names, "_lag1")

cat(sprintf("\nEffective sample: n_eff=%d (years %d-%d)\n",
    n_eff, years[idx_dep[1] + 1], years[idx_dep[n_eff] + 1]))


# ═══════════════════════════════════════════════════════════════════════════════
# 3. UNRESTRICTED ESTIMATION (baseline for LR test)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("UNRESTRICTED VECM (all 4 equations, all regressors)\n")
cat(strrep("=", 60), "\n")

RHS_full <- cbind(intercept = 1, ECT_reg, dX_lag1)  # n_eff x 8

fit_U <- list()
for (i in 1:p) {
  fit_U[[i]] <- lm(dY[, i] ~ RHS_full - 1)
}

resid_U  <- sapply(fit_U, residuals)
Sigma_U  <- crossprod(resid_U) / n_eff
logdet_U <- log(det(Sigma_U))

cat(sprintf("Unrestricted: %d equations x %d regressors = %d parameters\n",
    p, ncol(RHS_full), p * ncol(RHS_full)))
cat(sprintf("log|Sigma_U| = %.6f\n", logdet_U))


# ═══════════════════════════════════════════════════════════════════════════════
# 4. RESTRICTED ESTIMATION
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("RESTRICTED VECM\n")
cat("R1: alpha[omega_k, .] = 0\n")
cat("R2: Gamma[omega_k, .] = 0, Gamma[., omega_k] = 0\n")
cat(strrep("=", 60), "\n")

# Restricted regressors: drop d_omega_k_lag1 (column 4 of dX_lag1)
dX_lag1_3 <- dX_lag1[, 1:3, drop = FALSE]   # only dy, dk, domega lagged
RHS_res   <- cbind(intercept = 1, ECT_reg, dX_lag1_3)  # n_eff x 7

cat(sprintf("Restricted: 3 equations x %d regressors = %d parameters\n",
    ncol(RHS_res), 3 * ncol(RHS_res)))
cat(sprintf("Equation 4 (omega_k): all zeros, 0 parameters\n"))
cat(sprintf("Total free: %d | Unrestricted: %d | df = %d\n",
    3 * ncol(RHS_res), p * ncol(RHS_full),
    p * ncol(RHS_full) - 3 * ncol(RHS_res)))

# Estimate equations 1-3
fit_R <- list()
for (i in 1:3) {
  fit_R[[i]] <- lm(dY[, i] ~ RHS_res - 1)
}

# Equation 4: not estimated — residual = dY[,4]
resid_R <- cbind(
  residuals(fit_R[[1]]),
  residuals(fit_R[[2]]),
  residuals(fit_R[[3]]),
  dY[, 4]
)
colnames(resid_R) <- var_names
Sigma_R  <- crossprod(resid_R) / n_eff
logdet_R <- log(det(Sigma_R))

cat(sprintf("log|Sigma_R| = %.6f\n", logdet_R))


# ═══════════════════════════════════════════════════════════════════════════════
# 5. EXTRACT ALPHA AND GAMMA WITH INFERENCE
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("RESTRICTED ALPHA MATRIX\n")
cat(strrep("=", 60), "\n")

# RHS_res columns: intercept, ECT1, ECT2, ECT3, dy_lag1, dk_lag1, domega_lag1
# Alpha = coefficients 2:4 (ECT loadings)
# Gamma = coefficients 5:7 (lagged diff loadings)

alpha_hat <- matrix(0, p, r)
alpha_se  <- matrix(NA, p, r)
alpha_t   <- matrix(NA, p, r)
alpha_p   <- matrix(NA, p, r)
rownames(alpha_hat) <- var_names
colnames(alpha_hat) <- paste0("ECT", 1:r)
rownames(alpha_se) <- rownames(alpha_t) <- rownames(alpha_p) <- var_names

gamma_hat <- matrix(0, p, 3)   # 4x3 (col 4 = 0 by restriction)
gamma_se  <- matrix(NA, p, 3)
gamma_t   <- matrix(NA, p, 3)
gamma_p   <- matrix(NA, p, 3)
gamma_names <- c("dy_lag1", "dk_lag1", "domega_lag1")
colnames(gamma_hat) <- gamma_names

intercept_hat <- rep(0, p)

sig_stars <- function(pv) ifelse(pv < 0.001, "***",
  ifelse(pv < 0.01, "**", ifelse(pv < 0.05, "*", ifelse(pv < 0.10, ".", ""))))

for (i in 1:3) {
  s <- summary(fit_R[[i]])
  cf <- s$coefficients
  # Coefficient order matches RHS_res columns:
  # 1=intercept, 2=ECT1, 3=ECT2, 4=ECT3, 5=dy_lag1, 6=dk_lag1, 7=domega_lag1
  intercept_hat[i] <- cf[1, "Estimate"]

  for (j in 1:r) {
    alpha_hat[i, j] <- cf[1 + j, "Estimate"]
    alpha_se[i, j]  <- cf[1 + j, "Std. Error"]
    alpha_t[i, j]   <- cf[1 + j, "t value"]
    alpha_p[i, j]   <- cf[1 + j, "Pr(>|t|)"]
  }

  for (j in 1:3) {
    gamma_hat[i, j] <- cf[4 + j, "Estimate"]
    gamma_se[i, j]  <- cf[4 + j, "Std. Error"]
    gamma_t[i, j]   <- cf[4 + j, "t value"]
    gamma_p[i, j]   <- cf[4 + j, "Pr(>|t|)"]
  }
}
# Row 4 stays at zero (restriction)

# Print alpha
cat(sprintf("\n%-10s", ""))
for (j in 1:r) cat(sprintf(" %17s", paste0("ECT", j)))
cat("\n", strrep("-", 65), "\n")
for (i in 1:p) {
  cat(sprintf("%-10s", var_names[i]))
  for (j in 1:r) {
    if (i == 4) {
      cat(sprintf("     [0]          "))
    } else {
      cat(sprintf(" %+7.4f(%5.2f)%3s", alpha_hat[i,j], alpha_t[i,j], sig_stars(alpha_p[i,j])))
    }
  }
  cat("\n")
}
cat(strrep("-", 65), "\n")

# Print gamma
cat("\n", strrep("=", 60), "\n")
cat("RESTRICTED GAMMA MATRIX\n")
cat(strrep("=", 60), "\n")

gamma_full <- cbind(gamma_hat, 0)  # add col 4 = 0
colnames(gamma_full) <- c("dy_lag1", "dk_lag1", "domega_lag1", "domega_k_lag1")

cat(sprintf("\n%-10s", ""))
for (j in 1:4) cat(sprintf(" %17s", colnames(gamma_full)[j]))
cat("\n", strrep("-", 80), "\n")
for (i in 1:p) {
  cat(sprintf("%-10s", var_names[i]))
  for (j in 1:4) {
    if (i == 4 || j == 4) {
      cat(sprintf("     [0]          "))
    } else {
      cat(sprintf(" %+7.4f(%5.2f)%3s", gamma_hat[i,j], gamma_t[i,j], sig_stars(gamma_p[i,j])))
    }
  }
  cat("\n")
}
cat(strrep("-", 80), "\n")


# ═══════════════════════════════════════════════════════════════════════════════
# 6. LR TEST
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("LR TEST: RESTRICTED vs UNRESTRICTED\n")
cat(strrep("=", 60), "\n")

df_LR <- p * ncol(RHS_full) - 3 * ncol(RHS_res)
LR    <- n_eff * (logdet_R - logdet_U)
p_LR  <- pchisq(LR, df = df_LR, lower.tail = FALSE)

cat(sprintf("\nlog|Sigma_U| = %.6f\n", logdet_U))
cat(sprintf("log|Sigma_R| = %.6f\n", logdet_R))
cat(sprintf("LR = %.4f  df = %d  p = %.4f\n", LR, df_LR, p_LR))
cat(sprintf("Decision: %s\n",
    ifelse(p_LR > 0.05, "NOT REJECTED at 5% — restrictions accepted",
           "REJECTED at 5% — restrictions not supported")))


# ═══════════════════════════════════════════════════════════════════════════════
# 7. ECT STATIONARITY
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("ECT STATIONARITY\n")
cat(strrep("=", 60), "\n")

for (j in 1:r) {
  a <- adf.test(ECT_all[, j])
  cat(sprintf("ECT%d: ADF=%.3f  p=%.3f  %s\n",
      j, a$statistic, a$p.value,
      ifelse(a$p.value < 0.05, "I(0)", "WARNING")))
}


# ═══════════════════════════════════════════════════════════════════════════════
# 8. EQUATION-LEVEL DIAGNOSTICS
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("EQUATION DIAGNOSTICS\n")
cat(strrep("=", 60), "\n")

cat(sprintf("\n%-10s %8s %8s\n", "Equation", "R-sq", "Adj.R-sq"))
cat(strrep("-", 30), "\n")
for (i in 1:3) {
  s <- summary(fit_R[[i]])
  cat(sprintf("%-10s %8.4f %8.4f\n", var_names[i], s$r.squared, s$adj.r.squared))
}
cat(sprintf("%-10s %8s %8s\n", var_names[4], "[restr]", "[restr]"))


# ═══════════════════════════════════════════════════════════════════════════════
# 9. FULL COEFFICIENT TABLE
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("FULL COEFFICIENT TABLE (restricted equations only)\n")
cat(strrep("=", 60), "\n")

for (i in 1:3) {
  cat(sprintf("\n--- Equation: d(%s) ---\n", var_names[i]))
  s <- summary(fit_R[[i]])
  printCoefmat(s$coefficients, signif.stars = TRUE, digits = 4)
}


# ═══════════════════════════════════════════════════════════════════════════════
# 10. SAVE OUTPUTS
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("SAVING\n")
cat(strrep("=", 60), "\n")

# Alpha and Gamma as CSVs
alpha_df <- data.frame(variable = var_names, alpha_hat, check.names = FALSE)
write_csv(alpha_df, file.path(csv_dir, "restricted_alpha.csv"))

gamma_df <- data.frame(variable = var_names, gamma_full, check.names = FALSE)
write_csv(gamma_df, file.path(csv_dir, "restricted_gamma.csv"))

# Full estimation object
saveRDS(list(
  alpha     = alpha_hat,
  alpha_se  = alpha_se,
  alpha_t   = alpha_t,
  alpha_p   = alpha_p,
  gamma     = gamma_full,
  gamma_se  = gamma_se,
  gamma_t   = gamma_t,
  gamma_p   = gamma_p,
  intercept = intercept_hat,
  beta_raw  = beta_raw,
  beta_rot  = beta_rot,
  Sigma_R   = Sigma_R,
  Sigma_U   = Sigma_U,
  LR        = LR,
  df_LR     = df_LR,
  p_LR      = p_LR,
  n_eff     = n_eff,
  resid_R   = resid_R,
  ECT_all   = ECT_all,
  years     = years
), file.path(csv_dir, "restricted_vecm_objects.rds"))

cat("Saved: restricted_alpha.csv, restricted_gamma.csv, restricted_vecm_objects.rds\n")


# ═══════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("RESTRICTED VECM — SUMMARY\n")
cat(strrep("=", 60), "\n")
cat(sprintf("Sample: %d-%d (%d obs, n_eff=%d) | K=%d | r=%d\n",
    min(years), max(years), N, n_eff, K_lag, r))
cat(sprintf("Restrictions: alpha[omega_k,.]=0, Gamma[omega_k,.]=0, Gamma[.,omega_k]=0\n"))
cat(sprintf("LR test: %.4f  df=%d  p=%.4f  %s\n",
    LR, df_LR, p_LR,
    ifelse(p_LR > 0.05, "ACCEPTED", "REJECTED")))

cat("\nAlpha (significant at 5%):\n")
for (i in 1:3) for (j in 1:r) {
  if (!is.na(alpha_p[i,j]) && alpha_p[i,j] < 0.05)
    cat(sprintf("  alpha[%s, ECT%d] = %+.4f (t=%.2f)\n",
        var_names[i], j, alpha_hat[i,j], alpha_t[i,j]))
}

cat("\nGamma (significant at 5%):\n")
for (i in 1:3) for (j in 1:3) {
  if (!is.na(gamma_p[i,j]) && gamma_p[i,j] < 0.05)
    cat(sprintf("  Gamma[%s, %s] = %+.4f (t=%.2f)\n",
        var_names[i], gamma_names[j], gamma_hat[i,j], gamma_t[i,j]))
}

cat(strrep("=", 60), "\n")
