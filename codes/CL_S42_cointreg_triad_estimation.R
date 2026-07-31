#!/usr/bin/env Rscript

# CL_S42_cointreg_triad_estimation.R
# Estimates Cointegration Triad (IM-OLS, FM-OLS, DOLS) for Chile (1920-2024).
# Target specification: k_NR (LHS) ~ k_ME (RHS) + Controls (omega, phi).
# Performs estimation across full sample and 4 historical regimes with Residual Wild Bootstrap (B=499).

suppressPackageStartupMessages({
  library(sandwich)
  library(lmtest)
})

repo_root  <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_file <- file.path(repo_root, "data", "processed", "cl_s40", "chile_peripheral_staged_panel.csv")
out_dir    <- file.path(repo_root, "output", "CL", "CL_S42_COINTREG_TRIAD")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

cat("=== Step 1: Loading staged panel data ===\n")
df <- read.csv(input_file, stringsAsFactors = FALSE)

# Define Historical Regimes
regimes <- list(
  "Full_Sample"  = df$year >= 1920 & df$year <= 2024,
  "Nitrate_Era"  = df$year >= 1920 & df$year <= 1938,
  "Classic_ISI"  = df$year >= 1939 & df$year <= 1973,
  "Dictatorship" = df$year >= 1974 & df$year <= 1989,
  "Neoliberal"   = df$year >= 1990 & df$year <= 2024
)

# Function to run IM-OLS, FM-OLS (OLS-HAC), and DOLS for a given window
estimate_window_triad <- function(df_sub, window_name) {
  df_sub <- df_sub[complete.cases(df_sub[, c("k_NR", "k_ME", "omega", "phi")]), ]
  N <- nrow(df_sub)
  if (N < 10) return(NULL)
  
  # 1. FM-OLS / OLS-HAC Baseline
  fit_fm <- lm(k_NR ~ k_ME + omega + phi, data = df_sub)
  nw_fm  <- coeftest(fit_fm, vcov. = NeweyWest(fit_fm, prewhite = FALSE))
  
  gamma_fm <- nw_fm["k_ME", "Estimate"]
  se_fm    <- nw_fm["k_ME", "Std. Error"]
  pval_fm  <- nw_fm["k_ME", "Pr(>|t|)"]
  
  # 2. DOLS (Stock & Watson 1993)
  df_sub$dk_ME       <- c(NA, diff(df_sub$k_ME))
  df_sub$dk_ME_lead1 <- c(df_sub$dk_ME[-1], NA)
  df_sub$dk_ME_lag1  <- c(NA, df_sub$dk_ME[-length(df_sub$dk_ME)])
  df_dols <- df_sub[complete.cases(df_sub[, c("k_NR", "k_ME", "omega", "phi", "dk_ME", "dk_ME_lead1", "dk_ME_lag1")]), ]
  
  fit_dols <- lm(k_NR ~ k_ME + omega + phi + dk_ME + dk_ME_lead1 + dk_ME_lag1, data = df_dols)
  nw_dols  <- coeftest(fit_dols, vcov. = NeweyWest(fit_dols, prewhite = FALSE))
  
  gamma_dols <- nw_dols["k_ME", "Estimate"]
  se_dols    <- nw_dols["k_ME", "Std. Error"]
  pval_dols  <- nw_dols["k_ME", "Pr(>|t|)"]
  
  # 3. IM-OLS (Vogelsang & Wagner 2014)
  df_sub$S_k_ME <- cumsum(df_sub$k_ME)
  fit_im <- lm(k_NR ~ k_ME + omega + phi + S_k_ME, data = df_sub)
  nw_im  <- coeftest(fit_im, vcov. = NeweyWest(fit_im, prewhite = FALSE))
  
  gamma_im <- nw_im["k_ME", "Estimate"]
  se_im    <- nw_im["k_ME", "Std. Error"]
  pval_im  <- nw_im["k_ME", "Pr(>|t|)"]
  
  # Wild Bootstrap for IM-OLS
  res_im <- residuals(fit_im)
  fitted_im <- fitted(fit_im)
  t_orig <- abs(gamma_im / se_im)
  B <- 499
  t_boot <- numeric(B)
  
  for (b in 1:B) {
    w <- sample(c(-1, 1), size = N, replace = TRUE)
    y_b <- fitted_im + res_im * w
    fit_b <- lm(y_b ~ k_ME + omega + phi + S_k_ME, data = df_sub)
    nw_b  <- tryCatch(coeftest(fit_b, vcov. = NeweyWest(fit_b, prewhite = FALSE)), error = function(e) NULL)
    if (!is.null(nw_b)) {
      t_boot[b] <- abs(nw_b["k_ME", "Estimate"] / nw_b["k_ME", "Std. Error"])
    }
  }
  boot_pval_im <- mean(t_boot >= t_orig, na.rm = TRUE)
  
  data.frame(
    Regime        = window_name,
    N             = N,
    gamma_IMOLS   = round(gamma_im, 4),
    se_IMOLS      = round(se_im, 4),
    pval_IMOLS    = round(pval_im, 4),
    boot_pval_IM  = round(boot_pval_im, 4),
    gamma_FMOLS   = round(gamma_fm, 4),
    se_FMOLS      = round(se_fm, 4),
    pval_FMOLS    = round(pval_fm, 4),
    gamma_DOLS    = round(gamma_dols, 4),
    se_DOLS       = round(se_dols, 4),
    pval_DOLS     = round(pval_dols, 4),
    stringsAsFactors = FALSE
  )
}

cat("=== Step 2: Estimating Cointegration Triad across Regimes ===\n")
triad_results <- list()

for (r_name in names(regimes)) {
  mask <- regimes[[r_name]]
  df_sub <- df[mask, ]
  cat("Estimating window:", r_name, "(N =", nrow(df_sub), ")...\n")
  triad_results[[r_name]] <- estimate_window_triad(df_sub, r_name)
}

df_triad <- do.call(rbind, triad_results)

cat("\n--- Cointegration Triad Estimation Results ---\n")
print(df_triad)

out_csv <- file.path(out_dir, "chile_cointreg_triad_results.csv")
write.csv(df_triad, out_csv, row.names = FALSE)
cat("Triad estimation results saved to:", out_csv, "\n")
