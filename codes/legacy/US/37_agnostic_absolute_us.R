# 37_agnostic_absolute_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Agnostic self-discovery in ABSOLUTE LOG-LEVELS (2024 constant prices)
# No present-period normalization. No structural restrictions imposed.
#
# State vector:
#   y_t     = log(GVA_NF / Py_rebased)        — log real GVA in 2024 prices
#   k_t     = log(KGC_NF / Py_rebased)        — log real gross capital in 2024 prices
#   omega_t = Wsh_NF                           — gross wage share
#   omega_k = omega_t * k_t                    — interaction
#
# Pipeline:
#   1. Pre-tests (ADF/KPSS) — verify I(1)
#   2. Lag selection
#   3. Johansen rank test — agnostic
#   4. Extract unrestricted eigenvectors at confirmed rank
#   5. Inspect CV1, CV2, CV3 under multiple normalizations
#   6. Alpha matrix with inference
#   7. ECT stationarity
#   8. Structural series: theta, mu in absolute levels
# ═══════════════════════════════════════════════════════════════════════════════

library(urca); library(tseries); library(vars)
library(dplyr); library(readr); library(ggplot2)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

fig_dir <- file.path(REPO, "output/stage_a/us/figs")
csv_dir <- file.path(REPO, "output/stage_a/us/csv")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

dual_save <- function(plot, name, w = 10, h = 6, dpi = 300) {
  ggsave(file.path(fig_dir, paste0(name, ".png")),
         plot = plot, width = w, height = h, dpi = dpi)
  ggsave(file.path(fig_dir, paste0(name, ".pdf")),
         plot = plot, width = w, height = h, device = cairo_pdf)
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}

# ═══════════════════════════════════════════════════════════════════════════════
# 0. DATA — absolute 2024-price log-levels
# ═══════════════════════════════════════════════════════════════════════════════
nf  <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
nf  <- merge(nf, inc[, c("year", "Py_fred")], by = "year")
nf  <- nf[order(nf$year), ]

Py_2024 <- nf$Py_fred[nf$year == 2024]
nf$Py_rebased <- nf$Py_fred / Py_2024
nf$GVA_real   <- nf$GVA_NF / nf$Py_rebased
nf$KGC_real   <- nf$KGC_NF / nf$Py_rebased

# NO normalization — plain log-levels
nf$y_t     <- log(nf$GVA_real)
nf$k_t     <- log(nf$KGC_real)
nf$omega_t <- nf$Wsh_NF
nf$omega_k <- nf$omega_t * nf$k_t

X     <- as.matrix(nf[, c("y_t", "k_t", "omega_t", "omega_k")])
N     <- nrow(X)
years <- nf$year
K     <- 2
p     <- ncol(X)

cat(sprintf("Sample: %d-%d (%d obs) | K=%d\n", min(years), max(years), N, K))
cat(sprintf("y range:  [%.4f, %.4f]\n", min(X[,"y_t"]), max(X[,"y_t"])))
cat(sprintf("k range:  [%.4f, %.4f]\n", min(X[,"k_t"]), max(X[,"k_t"])))
cat(sprintf("omega range: [%.4f, %.4f]\n", min(X[,"omega_t"]), max(X[,"omega_t"])))
cat(sprintf("omega_k range: [%.4f, %.4f]\n", min(X[,"omega_k"]), max(X[,"omega_k"])))


# ═══════════════════════════════════════════════════════════════════════════════
# 1. PRE-TESTS
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("PRE-TESTS: INTEGRATION ORDER\n")
cat(strrep("=", 60), "\n")

for (vname in colnames(X)) {
  x <- X[, vname]
  adf_l <- adf.test(x)
  kpss_l <- kpss.test(x, null = "Level")
  adf_d <- adf.test(diff(x))
  cat(sprintf("\n%-8s  ADF lev p=%.3f  KPSS lev p=%.3f  ADF diff p=%.3f  %s\n",
      vname, adf_l$p.value, kpss_l$p.value, adf_d$p.value,
      ifelse(adf_l$p.value > 0.05 & adf_d$p.value < 0.10, "I(1)", "CHECK")))
}


# ═══════════════════════════════════════════════════════════════════════════════
# 2. LAG SELECTION
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("LAG SELECTION\n")
cat(strrep("=", 60), "\n")

lag_sel <- VARselect(X, lag.max = 4, type = "const")
print(lag_sel$selection)
K <- max(lag_sel$selection["SC(n)"], 2)
cat(sprintf("Using K=%d\n", K))


# ═══════════════════════════════════════════════════════════════════════════════
# 3. JOHANSEN RANK TEST
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("JOHANSEN RANK TEST\n")
cat(strrep("=", 60), "\n")

jo <- ca.jo(X, type = "trace", ecdet = "const", K = K, spec = "longrun")
jo_max <- ca.jo(X, type = "eigen", ecdet = "const", K = K, spec = "longrun")

cat("\nTrace test:\n")
r_confirmed <- 0
for (r_null in 0:(p - 1)) {
  idx <- p - r_null
  if (idx > 0 && idx <= length(jo@teststat)) {
    rej <- jo@teststat[idx] > jo@cval[idx, 2]
    cat(sprintf("  r <= %d:  trace=%7.2f  cv=%7.2f  %s\n",
        r_null, jo@teststat[idx], jo@cval[idx, 2],
        ifelse(rej, "REJECT", "fail")))
    if (rej) r_confirmed <- r_null + 1 else break
  }
}

cat(sprintf("\nMax-eigenvalue test:\n"))
for (r_null in 0:(p - 1)) {
  idx <- p - r_null
  if (idx > 0 && idx <= length(jo_max@teststat)) {
    cat(sprintf("  r <= %d:  eigen=%7.2f  cv=%7.2f  %s\n",
        r_null, jo_max@teststat[idx], jo_max@cval[idx, 2],
        ifelse(jo_max@teststat[idx] > jo_max@cval[idx, 2], "REJECT", "fail")))
  }
}

cat(sprintf("\nEigenvalues: %s\n", paste(round(jo@lambda, 4), collapse = ", ")))
cat(sprintf("Confirmed rank: r = %d\n", r_confirmed))

# ═══════════════════════════════════════════════════════════════════════════════
# 4. RAW COINTEGRATING VECTORS (NO STRUCTURAL NORMALIZATION IMPOSED)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("RAW COINTEGRATING VECTORS (Johansen output)\n")
cat(strrep("=", 60), "\n")

r <- min(r_confirmed, 3)

# ------------------------------------------------------------
# Normalize package-returned beta vectors on:
#   y_t.l2, k_t.l2, omega_t.l2
# but NOT on omega_k.l2
# ------------------------------------------------------------

beta_pkg <- jo@V[, 1:r, drop = FALSE]
colnames(beta_pkg) <- paste0("EV", 1:r)

norm_targets <- c("y_t.l2", "k_t.l2", "omega_t.l2")

normalize_beta <- function(beta_mat, target_row) {
  out <- beta_mat
  for (j in seq_len(ncol(beta_mat))) {
    pivot <- beta_mat[target_row, j]
    if (is.na(pivot) || abs(pivot) < 1e-12) {
      out[, j] <- NA_real_
    } else {
      out[, j] <- beta_mat[, j] / pivot
    }
  }
  out
}

beta_norm_list <- lapply(norm_targets, function(trg) {
  obj <- normalize_beta(beta_pkg, trg)
  rownames(obj) <- rownames(beta_pkg)
  colnames(obj) <- colnames(beta_pkg)
  obj
})
names(beta_norm_list) <- norm_targets

# Print normalized matrices
for (trg in norm_targets) {
  cat("\n", strrep("=", 60), "\n", sep = "")
  cat(sprintf("BETA VECTORS NORMALIZED ON %s = 1\n", trg))
  cat(strrep("=", 60), "\n", sep = "")
  print(round(beta_norm_list[[trg]], 6))
}

# Optional: print each relation in left-hand-side form
print_lhs_relations <- function(beta_mat, label) {
  cat("\n", strrep("-", 60), "\n", sep = "")
  cat(sprintf("LEFT-HAND-SIDE RELATIONS (%s)\n", label))
  cat(strrep("-", 60), "\n", sep = "")
  
  rn <- rownames(beta_mat)
  for (j in seq_len(ncol(beta_mat))) {
    b <- beta_mat[, j]
    cat(sprintf(
      "%s: %+0.6f*%s %+0.6f*%s %+0.6f*%s %+0.6f*%s %+0.6f = 0\n",
      colnames(beta_mat)[j],
      b[rn == "y_t.l2"],     "y_t.l2",
      b[rn == "k_t.l2"],     "k_t.l2",
      b[rn == "omega_t.l2"], "omega_t.l2",
      b[rn == "omega_k.l2"], "omega_k.l2",
      b[rn == "constant"]
    ))
  }
}

for (trg in norm_targets) {
  print_lhs_relations(beta_norm_list[[trg]], paste0(trg, " = 1"))
}

cat("\nInterpretation note:\n")
cat("  - These are the raw cointegrating vectors returned by the Johansen routine.\n")
cat("  - No extra normalization is imposed here.\n")
cat("  - Any beta vector is only identified up to scale (and sign).\n")

# Helper: normalize a beta vector on a chosen slot for inspection only
normalize_beta <- function(beta_col, slot) {
  slot_idx <- match(slot, names(beta_col))
  if (is.na(slot_idx)) stop(sprintf("Unknown slot: %s", slot))
  if (abs(beta_col[slot_idx]) < 1e-10) {
    return(rep(NA_real_, length(beta_col)))
  }
  beta_col / beta_col[slot_idx]
}

# Assign beta_raw for downstream use
beta_raw <- beta_pkg
rownames(beta_raw) <- c("y", "k", "omega", "omega_k", "const")

# ═══════════════════════════════════════════════════════════════════════════════
# 5. RAW ECT CONSTRUCTION
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("RAW ERROR-CORRECTION TERMS (FROM RAW BETA)\n")
cat(strrep("=", 60), "\n")

# X contains only the 4 endogenous variables: y, k, omega, omega_k
X4 <- as.matrix(nf[, c("y_t", "k_t", "omega_t", "omega_k")])

# Build ECTs directly from raw beta vectors:
# ECT_j,t = [y_t, k_t, omega_t, omega_k,t] %*% beta_j(1:4) + const_j
ects_raw <- X4 %*% beta_raw[1:4, , drop = FALSE] +
  matrix(beta_raw[5, ], nrow = nrow(X4), ncol = r, byrow = TRUE)

colnames(ects_raw) <- paste0("ECT", 1:r)
rownames(ects_raw) <- years

cat("\nFirst 6 observations of raw ECTs:\n")
print(round(head(ects_raw), 6))

cat("\nSummary statistics of raw ECTs:\n")
for (j in 1:r) {
  ectj <- ects_raw[, j]
  cat(sprintf(
    "  ECT%d: mean=%+.4f  sd=%.4f  min=%+.4f  max=%+.4f\n",
    j, mean(ectj), sd(ectj), min(ectj), max(ectj)
  ))
}

# ═══════════════════════════════════════════════════════════════════════════════
# 6. STATIONARITY OF RAW ECTs
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("STATIONARITY OF RAW ECTs\n")
cat(strrep("=", 60), "\n")

ect_adf <- vector("list", r)
for (j in 1:r) {
  ectj <- ects_raw[, j]
  adf_j <- adf.test(ectj)
  ect_adf[[j]] <- adf_j
  cat(sprintf(
    "ECT%d: ADF=%+.3f  p=%.3f  -> %s\n",
    j,
    unname(adf_j$statistic),
    adf_j$p.value,
    ifelse(adf_j$p.value < 0.05, "I(0)", "WARNING")
  ))
}

# ═══════════════════════════════════════════════════════════════════════════════
# 7. RAW BETA REPORTER (NO STRUCTURAL CLAIMS YET)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("RAW COINTEGRATING RELATIONS\n")
cat(strrep("=", 60), "\n")

for (j in 1:r) {
  b <- beta_raw[, j]
  names(b) <- rownames(beta_raw)
  cat(sprintf(
    "\nCV%d raw relation:\n  %+0.6f*y %+0.6f*k %+0.6f*omega %+0.6f*omega_k %+0.6f = 0\n",
    j, b["y"], b["k"], b["omega"], b["omega_k"], b["const"]
  ))
}

# ═══════════════════════════════════════════════════════════════════════════════
# 8. OPTIONAL: CHOOSE ONE NORMALIZATION ONLY WHEN YOU ARE READY
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("OPTIONAL NORMALIZED VIEW OF CV1 (INSPECTION ONLY)\n")
cat(strrep("=", 60), "\n")

b1_raw <- beta_raw[, 1]
names(b1_raw) <- rownames(beta_raw)

b1_y <- normalize_beta(b1_raw, "y")
if (!all(is.na(b1_y))) {
  cat("\nCV1 normalized on y = 1 (inspection only):\n")
  cat(sprintf(
    "  y %+0.6f*k %+0.6f*omega %+0.6f*omega_k %+0.6f = 0\n",
    b1_y["k"], b1_y["omega"], b1_y["omega_k"], b1_y["const"]
  ))
}

# ═══════════════════════════════════════════════════════════════════════════════
# 9. ALPHA MATRIX — FULL INFERENCE AT r=3
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("ALPHA MATRIX — UNRESTRICTED r=3\n")
cat(strrep("=", 60), "\n")

# S-matrices for alpha inference
Neff   <- nrow(jo@Z0)
M00    <- crossprod(jo@Z0) / Neff
M11    <- crossprod(jo@Z1) / Neff
MKK    <- crossprod(jo@ZK) / Neff
M01    <- t(jo@Z0) %*% jo@Z1 / Neff
M0K    <- t(jo@Z0) %*% jo@ZK / Neff
M1K    <- t(jo@Z1) %*% jo@ZK / Neff
M11inv <- solve(M11)

S00 <- M00 - M01 %*% M11inv %*% t(M01)
S0K <- M0K - M01 %*% M11inv %*% M1K
SK0 <- t(S0K)
SKK <- MKK - t(M1K) %*% M11inv %*% M1K

# Concentrated alpha
alpha_hat <- S0K %*% beta_raw %*% solve(t(beta_raw) %*% SKK %*% beta_raw)
rownames(alpha_hat) <- c("y", "k", "omega", "omega_k")
colnames(alpha_hat) <- paste0("ECT", 1:r)

# Residual covariance
bSb_hat   <- t(beta_raw) %*% SKK %*% beta_raw
Sigma_hat <- S00 - S0K %*% beta_raw %*% solve(bSb_hat) %*% t(beta_raw) %*% SK0
bSb_inv   <- solve(bSb_hat)

var_names <- c("y", "k", "omega", "omega_k")
ect_names <- paste0("ECT", 1:r)

sig_stars <- function(pv) ifelse(pv<0.001,"***",ifelse(pv<0.01,"**",ifelse(pv<0.05,"*",ifelse(pv<0.10,".",""))))

alpha_se <- matrix(NA, p, r)
alpha_t  <- matrix(NA, p, r)
alpha_p  <- matrix(NA, p, r)

cat(sprintf("\n%-22s %8s %8s %8s %8s %5s\n",
    "Loading", "Est", "SE", "t-stat", "p-value", "Sig"))
cat(strrep("-", 62), "\n")
for (i in 1:p) {
  for (j in 1:r) {
    alpha_se[i,j] <- sqrt(Sigma_hat[i,i] * bSb_inv[j,j] / Neff)
    alpha_t[i,j]  <- alpha_hat[i,j] / alpha_se[i,j]
    alpha_p[i,j]  <- 2 * pnorm(-abs(alpha_t[i,j]))
    cat(sprintf("alpha[%-8s, %4s] %8.4f %8.4f %8.3f %8.4f %s\n",
        var_names[i], ect_names[j],
        alpha_hat[i,j], alpha_se[i,j], alpha_t[i,j], alpha_p[i,j],
        sig_stars(alpha_p[i,j])))
  }
}
cat(strrep("-", 62), "\n")

# Summary matrix
cat("\nAlpha matrix (estimate / t-stat):\n")
cat(sprintf("%-10s", ""))
for (j in 1:r) cat(sprintf(" %17s", ect_names[j]))
cat("\n")
for (i in 1:p) {
  cat(sprintf("%-10s", var_names[i]))
  for (j in 1:r) cat(sprintf(" %7.4f / %5.2f", alpha_hat[i,j], alpha_t[i,j]))
  cat("\n")
}

# Significant loadings at 5%
cat("\nSignificant loadings (p < 0.05):\n")
for (i in 1:p) for (j in 1:r) {
  if (alpha_p[i,j] < 0.05)
    cat(sprintf("  alpha[%s, %s] = %.4f (t=%.2f)\n",
        var_names[i], ect_names[j], alpha_hat[i,j], alpha_t[i,j]))
}


# ═══════════════════════════════════════════════════════════════════════════════
# 10. SELF-DISCOVERY: OMEGA-NORMALIZED INSPECTION
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("SELF-DISCOVERY: OMEGA-NORMALIZED COINTEGRATING VECTORS\n")
cat(strrep("=", 60), "\n")

# The omega-normalized form is the most informative for inspection:
# Each CV reads as: omega = f(y, k, omega_k, const)
# This shows what distributional relationship each CV captures.

cat("\nAll three CVs normalized on omega = 1:\n\n")
beta_omega <- beta_norm_list[["omega_t.l2"]]

cat(sprintf("CV1: omega = %+.4f*y %+.4f*k %+.4f*(omega*k) %+.4f\n",
    -beta_omega[1,1], -beta_omega[2,1], -beta_omega[4,1], -beta_omega[5,1]))
cat(sprintf("CV2: omega = %+.4f*y %+.4f*k %+.4f*(omega*k) %+.4f\n",
    -beta_omega[1,2], -beta_omega[2,2], -beta_omega[4,2], -beta_omega[5,2]))
cat(sprintf("CV3: omega = %+.4f*y %+.4f*k %+.4f*(omega*k) %+.4f\n",
    -beta_omega[1,3], -beta_omega[2,3], -beta_omega[4,3], -beta_omega[5,3]))

# Key observation: in normalized form, are the y coefficients near zero
# for any CV? That would confirm the y=0 restriction from the earlier
# self-discovery (which found y=0 free in CV2 under normalization).
cat("\n--- Inspection: y-coefficient in omega-normalized CVs ---\n")
for (j in 1:r) {
  y_coef <- -beta_omega[1, j]
  cat(sprintf("  CV%d: y-coef = %+.6f  (near zero? %s)\n",
      j, y_coef, ifelse(abs(y_coef) < 0.05, "YES", "no")))
}

# Key observation: are the k and omega_k coefficients consistent
# across CVs? If so, the three CVs may be near-collinear.
cat("\n--- Inspection: k and omega_k ratios across CVs ---\n")
for (j in 1:r) {
  k_coef  <- -beta_omega[2, j]
  wk_coef <- -beta_omega[4, j]
  if (abs(wk_coef) > 1e-6) {
    cat(sprintf("  CV%d: k/omega_k = %+.4f\n", j, k_coef / wk_coef))
  }
}


# ═══════════════════════════════════════════════════════════════════════════════
# 11. SPAN TEST — IS CV3 NEAR-COLLINEAR WITH CV1+CV2?
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("SPAN TEST: CV3 vs span(CV1, CV2)\n")
cat(strrep("=", 60), "\n")

B12 <- beta_raw[, 1:2]
b3  <- beta_raw[, 3]
lambda_hat <- solve(t(B12) %*% B12) %*% t(B12) %*% b3
b3_fitted  <- B12 %*% lambda_hat
resid      <- b3 - b3_fitted
r2_span    <- 1 - sum(resid^2) / sum((b3 - mean(b3))^2)

cat(sprintf("\nCV3 ≈ %.4f*CV1 + %.4f*CV2\n", lambda_hat[1], lambda_hat[2]))
cat(sprintf("R-squared (span): %.4f\n", r2_span))
cat(sprintf("Residual norm:    %.4f\n", sqrt(sum(resid^2))))
cat(sprintf("Conclusion: %s\n",
    ifelse(r2_span > 0.99, "CV3 is nearly redundant (R2 > 0.99)",
    ifelse(r2_span > 0.95, "CV3 is substantially in span(CV1,CV2)",
                           "CV3 contains independent information"))))


# ═══════════════════════════════════════════════════════════════════════════════
# 12. SAVE RAW OBJECTS
# ═══════════════════════════════════════════════════════════════════════════════
raw_beta_df <- data.frame(
  term = rownames(beta_raw),
  beta_raw,
  check.names = FALSE
)

raw_ect_df <- data.frame(
  year = years,
  ects_raw,
  check.names = FALSE
)

write_csv(raw_beta_df, file.path(csv_dir, "stage_a_raw_cointegrating_vectors.csv"))
write_csv(raw_ect_df,  file.path(csv_dir, "stage_a_raw_ects.csv"))

saveRDS(
  list(
    beta_raw = beta_raw,
    ects_raw = ects_raw,
    ect_adf = ect_adf,
    rank = r,
    eigenvalues = jo@lambda
  ),
  file.path(csv_dir, "stage_a_raw_coint_objects.rds")
)

cat("\nSaved:\n")
cat("  - stage_a_raw_cointegrating_vectors.csv\n")
cat("  - stage_a_raw_ects.csv\n")
cat("  - stage_a_raw_coint_objects.rds\n")