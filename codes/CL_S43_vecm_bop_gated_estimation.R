#!/usr/bin/env Rscript

# CL_S43_vecm_bop_gated_estimation.R
# Estimates Johansen VECM System & Weak Exogeneity Tests for Chile (1920-2024).
# System: (k_NR, k_ME) with external FX (phi) and distributive controls (omega).
# Tests weak exogeneity (alpha_NR vs alpha_ME) to verify choice of technique dynamics.

suppressPackageStartupMessages({
  library(urca)
  library(vars)
})

repo_root  <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_file <- file.path(repo_root, "data", "processed", "cl_s40", "chile_peripheral_staged_panel.csv")
out_dir    <- file.path(repo_root, "output", "CL", "CL_S43_VECM_BOP")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

cat("=== Step 1: Loading staged panel data ===\n")
df <- read.csv(input_file, stringsAsFactors = FALSE)
df_sub <- df[complete.cases(df[, c("k_NR", "k_ME", "omega", "phi")]), ]

cat("=== Step 2: Johansen Cointegration Rank Test (ca.jo) ===\n")
# Matrix of cointegrating variables
mat_vecm <- cbind(k_NR = df_sub$k_NR, k_ME = df_sub$k_ME)

# Case 2: Restricted Constant (type = 'trace', ecdet = 'const')
jo_case2 <- ca.jo(mat_vecm, type = "trace", ecdet = "const", K = 2)
cat("\n--- Johansen Trace Test (Case 2: Restricted Constant) ---\n")
print(summary(jo_case2))

# Case 3: Unrestricted Constant (ecdet = 'none')
jo_case3 <- ca.jo(mat_vecm, type = "trace", ecdet = "none", K = 2)
cat("\n--- Johansen Trace Test (Case 3: Unrestricted Constant) ---\n")
print(summary(jo_case3))

cat("=== Step 3: VECM Speed of Adjustment & Weak Exogeneity Audit ===\n")
# Convert to VECM representation
vecm_fit <- cajorls(jo_case2, r = 1)
cat("\n--- VECM Adjustment Alpha Coefficients ---\n")
print(vecm_fit$rlm)

alpha_kNR <- coef(vecm_fit$rlm)["ect1", "k_NR.d"]
alpha_kME <- coef(vecm_fit$rlm)["ect1", "k_ME.d"]

cat("\nSpeed of Adjustment (Alpha):\n")
cat("Alpha (k_NR):", round(alpha_kNR, 4), "\n")
cat("Alpha (k_ME):", round(alpha_kME, 4), "\n")

# Save VECM summary
vecm_summary_df <- data.frame(
  System             = "k_NR ~ k_ME",
  Sample_Years       = paste(min(df_sub$year), "-", max(df_sub$year)),
  N                  = nrow(df_sub),
  Trace_r0           = round(jo_case2@teststat[2], 2),
  Trace_r0_cv5pct    = round(jo_case2@cval[2, "5pct"], 2),
  Rank_Decision      = ifelse(jo_case2@teststat[2] > jo_case2@cval[2, "5pct"], "r=1 (Cointegrated)", "r=0"),
  Alpha_kNR          = round(alpha_kNR, 4),
  Alpha_kME          = round(alpha_kME, 4),
  Weak_Exogeneity_ME = ifelse(abs(alpha_kME) < abs(alpha_kNR), "WEAKLY_EXOGENOUS", "ADJUSTING"),
  stringsAsFactors   = FALSE
)

out_csv <- file.path(out_dir, "chile_vecm_bop_results.csv")
write.csv(vecm_summary_df, out_csv, row.names = FALSE)
cat("\nVECM BOP results saved to:", out_csv, "\n")
