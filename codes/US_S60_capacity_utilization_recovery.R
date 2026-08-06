#!/usr/bin/env Rscript

# US_S60_capacity_utilization_recovery.R
# Reconstructs aggregate capacity utilization (mu_t) and transformation elasticity (theta_t)
# from Section 3.1 preferred specifications (M2.2 WD and M2.10 WD).
# Uses direct pinch-year evaluation: y^p_t = y_1973 + theta_t * (k_t - k_1973)

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
s50_dir   <- file.path(repo_root, "output", "US", "S50_SECTION31_IMOLS")
s41_csv   <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data", "s41_extended_capital_panel.csv")
s29f_csv  <- file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION", "csv", "S29F_shaikh_tonak_wage_share_panel.csv")
s42_csv   <- file.path(repo_root, "output", "US", "S42_CM_EXTENSION", "csv", "s42a_extended_cm_control_panel.csv")
fred_csv  <- file.path(repo_root, "output", "US", "S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION", "csv", "fred_annual_ad_components_panel.csv")
out_dir   <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY")
csv_dir   <- file.path(out_dir, "csv")
rds_dir   <- file.path(out_dir, "rds")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Aggregate Capacity Utilization Recovery Pipeline (1929-2024)\n")
cat("========================================================================\n")

# 1. Load fitted models
models_path <- file.path(s50_dir, "rds", "s50_fitted_models.rds")
if (!file.exists(models_path)) {
  stop("Fitted models file not found at: ", models_path)
}
fs <- readRDS(models_path)
cat(sprintf("Loaded %d fitted models from S50.\n", length(fs)))

# Verify that M2.2 and M2.10 are present
target_models <- c("M2.2_WD", "M2.10_WD")
if (!all(target_models %in% names(fs))) {
  stop("Missing target models in RDS. Found: ", paste(names(fs), collapse = ", "))
}

# 2. Reconstruct design panel matching S50 inputs
df_cap <- read.csv(s41_csv, stringsAsFactors = FALSE)
df_st  <- read.csv(s29f_csv, stringsAsFactors = FALSE)
df_cm  <- read.csv(s42_csv, stringsAsFactors = FALSE)
df_fred <- read.csv(fred_csv, stringsAsFactors = FALSE)

# Select required variables and merge
df <- df_cap[, c("year", "k_cap", "omega_NFC_GVA_lag1")]
df_st_sub <- df_st[, c("year", "omega_ST_Tier2_GVA_adj")]
df_cm_sub <- df_cm[, c("year", "net_c_share_nom")]
df_fred_sub <- df_fred[, c("year", "GDP_real")]

df <- merge(df, df_st_sub, by = "year", all.x = TRUE)
df <- merge(df, df_cm_sub, by = "year", all.x = TRUE)
df <- merge(df, df_fred_sub, by = "year", all.x = TRUE)

df <- df[df$year >= 1929 & df$year <= 2024, ]
df <- df[order(df$year), ]

# Centering components
df$omega_ST_Tier2_GVA_adj_lag1 <- dplyr::lag(df$omega_ST_Tier2_GVA_adj, 1L)
df$iota_t <- df_cap$IPP_share_capital_plus_IPP[match(df$year, df_cap$year)]
df$iota_lag1 <- dplyr::lag(df$iota_t, 1L)

# Clean and check completeness
req_cols <- c("year", "k_cap", "omega_NFC_GVA_lag1", "omega_ST_Tier2_GVA_adj_lag1", "iota_lag1", "GDP_real")
df_clean <- df[complete.cases(df[, req_cols]), ]
cat(sprintf("Effective Sample: %d - %d (N = %d observations)\n", 
            min(df_clean$year), max(df_clean$year), nrow(df_clean)))

# 3. Direct potential capacity evaluation function
reconstruct_capacity_utilization <- function(df_data, model_id, model_name, is_primary) {
  m <- fs[[model_id]]
  coefs <- m$fit$theta
  
  # Index of stochastic parameters
  d_k <- ncol(m$deter)
  b_idx <- d_k + 1 # k_cap
  d_idx <- d_k + 2 # interaction
  
  theta_0 <- coefs[b_idx]
  theta_1 <- coefs[d_idx]
  
  years <- df_data$year
  N <- nrow(df_data)
  
  # Reconstruct theta_t series
  if (m$Spec_Set == "Set_1") {
    w <- df_data$omega_NFC_GVA_lag1
    w0 <- w[1]
    w_c <- w - w0
    theta <- theta_0 + theta_1 * w_c
  } else {
    # Set 2 centering
    if (grepl("ST_Tier2", m$Wage_Label)) {
      w <- df_data$omega_ST_Tier2_GVA_adj_lag1
    } else {
      w <- df_data$omega_NFC_GVA_lag1
    }
    w0 <- w[1]
    w_c <- w - w0
    
    iota <- df_data$iota_lag1
    iota0 <- iota[1]
    iota_c <- iota - iota0
    
    theta <- theta_0 + theta_1 * w_c * iota_c
  }
  
  # Log Total Real GDP
  y_agg <- log(df_data$GDP_real)
  
  # Extract correct log capital stock (k_cap or k_cap_GT) used in the specification
  # X_mat contains the raw log capital stock in its first column
  k <- m$X_mat[, 1]
  
  # Align years of estimation data with df_data
  val_indices <- match(df_data$year, m$years)
  k_aligned <- k[val_indices]
  
  idx_1973 <- which(years == 1973)
  if (length(idx_1973) == 0) {
    stop("1973 pinch year not found in data.")
  }
  
  y_1973 <- y_agg[idx_1973]
  k_1973 <- k_aligned[idx_1973]
  
  # Direct evaluation: y^p_t = y_1973 + \theta_t * (k_t - k_1973)
  y_p <- y_1973 + theta * (k_aligned - k_1973)
  
  # Compute capacity utilization
  ln_mu <- y_agg - y_p
  mu <- exp(ln_mu)
  
  data.frame(
    year = years,
    GDP_real = df_data$GDP_real,
    k_cap = k_aligned,
    theta = theta,
    y_p = y_p,
    mu = mu,
    is_primary = is_primary
  )
}

# Run recovery for both models (M2.10 is primary, M2.2 is secondary sensitivity)
res_m2_10 <- reconstruct_capacity_utilization(df_clean, "M2.10_WD", "Interactive (M2.10)", is_primary = TRUE)
res_m2_2  <- reconstruct_capacity_utilization(df_clean, "M2.2_WD", "Baseline (M2.2)", is_primary = FALSE)

# Save combined ledger
combined_out <- data.frame(
  year           = res_m2_10$year,
  GDP_real       = res_m2_10$GDP_real,
  k_cap          = res_m2_10$k_cap,
  theta_m2_10    = res_m2_10$theta,
  y_p_m2_10      = res_m2_10$y_p,
  mu_m2_10       = res_m2_10$mu,
  is_primary_m2_10 = res_m2_10$is_primary,
  omega_ST_Tier2_lag1 = df_clean$omega_ST_Tier2_GVA_adj_lag1,
  iota_lag1      = df_clean$iota_lag1,
  omega_NFC_GVA_lag1 = df_clean$omega_NFC_GVA_lag1,
  theta_m2_2     = res_m2_2$theta,
  y_p_m2_2       = res_m2_2$y_p,
  mu_m2_2        = res_m2_2$mu,
  is_primary_m2_2  = res_m2_2$is_primary
)

csv_file <- file.path(csv_dir, "s60_capacity_utilization_series.csv")
write.csv(combined_out, csv_file, row.names = FALSE)
cat(sprintf("Saved recovered series to: %s\n", csv_file))

# Verify anchor condition
err_m2_10 <- abs(combined_out$mu_m2_10[combined_out$year == 1973] - 1.00)
err_m2_2 <- abs(combined_out$mu_m2_2[combined_out$year == 1973] - 1.00)

cat(sprintf("Anchor Validation (mu_1973 == 1.000000 exactly):\n"))
cat(sprintf("  M2.10 (WD) [Primary] : mu = %.15f (absolute error = %.2e) -> %s\n", 
            combined_out$mu_m2_10[combined_out$year == 1973], err_m2_10, 
            if (err_m2_10 < 1e-12) "PASS" else "FAIL"))
cat(sprintf("  M2.2 (WD)  [Baseline]: mu = %.15f (absolute error = %.2e) -> %s\n", 
            combined_out$mu_m2_2[combined_out$year == 1973], err_m2_2, 
            if (err_m2_2 < 1e-12) "PASS" else "FAIL"))

# Save R object
saveRDS(list(res_m2_10 = res_m2_10, res_m2_2 = res_m2_2, combined = combined_out),
        file.path(rds_dir, "s60_capacity_utilization_recovered.rds"))
cat("S60 Capacity utilization recovery complete.\n")
