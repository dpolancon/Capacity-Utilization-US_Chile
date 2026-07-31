#!/usr/bin/env Rscript

# COMMON_S33_relative_price_urca_battery.R
# Integration Order & Andrews-Zivot (AZ) Unit Root Testing Battery for Capital Relative Asset Prices
# Evaluates Levels and First Differences for ln_P_ME, ln_P_NRC, p_rel, and interaction terms (1925-2024).

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  if (!requireNamespace("urca", quietly = TRUE)) {
    install.packages("urca", repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(urca)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
s29c_csv  <- file.path(repo_root, "output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION", "csv", "S29C_fixed_assets_price_real_investment_long.csv")
gpim_csv  <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")
out_csv   <- file.path(repo_root, "output", "relative_price_urca_unit_root_matrix.csv")

cat("========================================================================\n")
cat("Stage 3: URCA & Andrews-Zivot Unit Root Testing Battery for Relative Prices\n")
cat("========================================================================\n")

if (!file.exists(s29c_csv)) stop("Missing S29C input: ", s29c_csv)
if (!file.exists(gpim_csv)) stop("Missing GPIM input: ", gpim_csv)

s29c_df <- read.csv(s29c_csv, stringsAsFactors = FALSE)
gpim_df <- read.csv(gpim_csv, stringsAsFactors = FALSE)

# Extract P_ME_2017 and P_NRC_2017 using derived_variable_id
p_me_df  <- s29c_df[s29c_df$derived_variable_id == "P_ME_2017", c("year", "value")]
colnames(p_me_df) <- c("year", "P_ME")

p_nrc_df <- s29c_df[s29c_df$derived_variable_id == "P_NRC_2017", c("year", "value")]
colnames(p_nrc_df) <- c("year", "P_NRC")

df <- merge(p_me_df, p_nrc_df, by = "year")
df <- df[df$year >= 1925 & df$year <= 2024, ]
df <- merge(df, gpim_df[, c("year", "tau", "omega_NFC_GVA_lag1")], by = "year", all.x = TRUE)

df <- df[order(df$year), ]
df$ln_P_ME  <- log(df$P_ME)
df$ln_P_NRC <- log(df$P_NRC)
df$p_rel    <- df$ln_P_ME - df$ln_P_NRC
df$p_rel_lag1 <- c(NA, df$p_rel[-nrow(df)])
df$inter_tau_prel <- df$tau * df$p_rel_lag1

test_vars <- c("ln_P_ME", "ln_P_NRC", "p_rel", "inter_tau_prel")
results_list <- list()

run_urca_tests <- function(vec, var_name, series_type) {
  clean_idx <- !is.na(vec)
  vec_clean <- vec[clean_idx]
  years_clean <- df$year[clean_idx]
  n <- length(vec_clean)
  if (n < 15) return(NULL)

  # 1. ADF (Trend)
  adf_tr <- tryCatch(ur.df(vec_clean, type = "trend", selectlags = "AIC"), error = function(e) NULL)
  if (!is.null(adf_tr)) {
    stat <- as.numeric(adf_tr@teststat[1, 1])
    cv5  <- as.numeric(adf_tr@cval[1, "5pct"])
    dec  <- if (!is.na(stat) && !is.na(cv5) && stat < cv5) "Stationary (Reject H0)" else "Unit Root (Fail to Reject)"
    results_list[[length(results_list) + 1]] <<- data.frame(
      Variable = var_name, Series = series_type, Test = "ADF", Model = "Trend",
      Stat = round(stat, 3), CV_5pct = round(cv5, 3), Break_Year = NA, Decision = dec, stringsAsFactors = FALSE
    )
  }

  # 2. ADF (Drift)
  adf_dr <- tryCatch(ur.df(vec_clean, type = "drift", selectlags = "AIC"), error = function(e) NULL)
  if (!is.null(adf_dr)) {
    stat <- as.numeric(adf_dr@teststat[1, 1])
    cv5  <- as.numeric(adf_dr@cval[1, "5pct"])
    dec  <- if (!is.na(stat) && !is.na(cv5) && stat < cv5) "Stationary (Reject H0)" else "Unit Root (Fail to Reject)"
    results_list[[length(results_list) + 1]] <<- data.frame(
      Variable = var_name, Series = series_type, Test = "ADF", Model = "Drift",
      Stat = round(stat, 3), CV_5pct = round(cv5, 3), Break_Year = NA, Decision = dec, stringsAsFactors = FALSE
    )
  }

  # 3. ERS (DF-GLS Trend)
  ers_tr <- tryCatch(ur.ers(vec_clean, type = "DF-GLS", model = "trend", lag.max = 4), error = function(e) NULL)
  if (!is.null(ers_tr)) {
    stat <- as.numeric(ers_tr@teststat[1])
    cv5  <- as.numeric(ers_tr@cval[1, "5pct"])
    dec  <- if (!is.na(stat) && !is.na(cv5) && stat < cv5) "Stationary (Reject H0)" else "Unit Root (Fail to Reject)"
    results_list[[length(results_list) + 1]] <<- data.frame(
      Variable = var_name, Series = series_type, Test = "ERS (DF-GLS)", Model = "Trend",
      Stat = round(stat, 3), CV_5pct = round(cv5, 3), Break_Year = NA, Decision = dec, stringsAsFactors = FALSE
    )
  }

  # 4. KPSS (Trend)
  kpss_tr <- tryCatch(ur.kpss(vec_clean, type = "tau", lags = "short"), error = function(e) NULL)
  if (!is.null(kpss_tr)) {
    stat <- as.numeric(kpss_tr@teststat[1])
    cv5  <- as.numeric(kpss_tr@cval[1, "5pct"])
    dec  <- if (!is.na(stat) && !is.na(cv5) && stat > cv5) "Unit Root (Reject H0)" else "Stationary (Fail to Reject)"
    results_list[[length(results_list) + 1]] <<- data.frame(
      Variable = var_name, Series = series_type, Test = "KPSS", Model = "Trend",
      Stat = round(stat, 3), CV_5pct = round(cv5, 3), Break_Year = NA, Decision = dec, stringsAsFactors = FALSE
    )
  }

  # 5. PP (Z-tau Trend)
  pp_tr <- tryCatch(ur.pp(vec_clean, type = "Z-tau", model = "trend", lags = "short"), error = function(e) NULL)
  if (!is.null(pp_tr)) {
    stat <- as.numeric(pp_tr@teststat[1])
    cv5  <- as.numeric(pp_tr@cval[1, "5pct"])
    dec  <- if (!is.na(stat) && !is.na(cv5) && stat < cv5) "Stationary (Reject H0)" else "Unit Root (Fail to Reject)"
    results_list[[length(results_list) + 1]] <<- data.frame(
      Variable = var_name, Series = series_type, Test = "PP", Model = "Trend",
      Stat = round(stat, 3), CV_5pct = round(cv5, 3), Break_Year = NA, Decision = dec, stringsAsFactors = FALSE
    )
  }

  # 6. Andrews-Zivot (AZ) Endogenous Break Test (model = "both")
  az_both <- tryCatch(ur.za(vec_clean, model = "both"), error = function(e) NULL)
  if (!is.null(az_both)) {
    stat <- as.numeric(az_both@teststat[1])
    cv5  <- as.numeric(az_both@cval[2]) # 5pct is 2nd entry
    bidx <- as.integer(az_both@bpoint)
    byear <- if (!is.na(bidx) && bidx > 0 && bidx <= length(years_clean)) years_clean[bidx] else NA
    dec  <- if (!is.na(stat) && !is.na(cv5) && stat < cv5) "Stationary with Break (Reject H0)" else "Unit Root (Fail to Reject)"
    results_list[[length(results_list) + 1]] <<- data.frame(
      Variable = var_name, Series = series_type, Test = "Andrews-Zivot (AZ)", Model = "Both (Inter/Trend)",
      Stat = round(stat, 3), CV_5pct = round(cv5, 3), Break_Year = byear, Decision = dec, stringsAsFactors = FALSE
    )
  }

  # 7. Andrews-Zivot (AZ) Endogenous Break Test (model = "intercept")
  az_int <- tryCatch(ur.za(vec_clean, model = "intercept"), error = function(e) NULL)
  if (!is.null(az_int)) {
    stat <- as.numeric(az_int@teststat[1])
    cv5  <- as.numeric(az_int@cval[2]) # 5pct is 2nd entry
    bidx <- as.integer(az_int@bpoint)
    byear <- if (!is.na(bidx) && bidx > 0 && bidx <= length(years_clean)) years_clean[bidx] else NA
    dec  <- if (!is.na(stat) && !is.na(cv5) && stat < cv5) "Stationary with Break (Reject H0)" else "Unit Root (Fail to Reject)"
    results_list[[length(results_list) + 1]] <<- data.frame(
      Variable = var_name, Series = series_type, Test = "Andrews-Zivot (AZ)", Model = "Intercept Break",
      Stat = round(stat, 3), CV_5pct = round(cv5, 3), Break_Year = byear, Decision = dec, stringsAsFactors = FALSE
    )
  }
}

for (v in test_vars) {
  cat("Testing variable:", v, "...\n")
  run_urca_tests(df[[v]], v, "Level")
  
  diff_vec <- c(NA, diff(df[[v]]))
  run_urca_tests(diff_vec, v, "First Difference")
}

res_df <- do.call(rbind, results_list)
write.csv(res_df, out_csv, row.names = FALSE)

cat("\n========================================================================\n")
cat("Unit Root Testing Battery Complete. Output saved to:\n", out_csv, "\n")
cat("========================================================================\n\n")

print(res_df, row.names = FALSE)
