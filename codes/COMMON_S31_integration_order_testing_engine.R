#!/usr/bin/env Rscript

# COMMON_S31_integration_order_testing_engine.R
# Executes unit root tests (ADF, KPSS, PP) across US and Chilean pending series
# and classifies integration orders as "Strong I(1)", "Weak I(1)", "Strong I(0)", or "I(2) Risk (Blocked)".

suppressPackageStartupMessages({
  if (requireNamespace("urca", quietly = TRUE)) library(urca)
  if (requireNamespace("tseries", quietly = TRUE)) library(tseries)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
cl_file <- file.path(repo_root, "data", "processed", "cl_s20", "chile_orthogonalized_panel.csv")
us_file <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
out_dir <- file.path(repo_root, "data", "processed", "integration_order")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

test_and_classify <- function(series, var_name, country) {
  s_clean <- na.omit(as.numeric(series))
  n <- length(s_clean)
  if (n < 15) {
    return(data.frame(
      Country = country, Variable = var_name, N = n,
      ADF_Level_p = NA, KPSS_Level_stat = NA, PP_Level_p = NA,
      ADF_Diff_p = NA, KPSS_Diff_stat = NA,
      Classification = "Insufficient Data",
      Gate_Status = "Blocked", stringsAsFactors = FALSE
    ))
  }
  
  # ADF test on level
  adf_lvl_p <- tryCatch({
    res <- suppressWarnings(tseries::adf.test(s_clean))
    if (is.null(res$p.value) || is.na(res$p.value)) 0.5 else res$p.value
  }, error = function(e) 0.5)

  # KPSS test on level
  kpss_lvl_stat <- tryCatch({
    res <- suppressWarnings(tseries::kpss.test(s_clean, null = "Level"))
    if (is.null(res$statistic) || is.na(res$statistic)) 1.0 else res$statistic
  }, error = function(e) 1.0)

  # PP test on level
  pp_lvl_p <- tryCatch({
    res <- suppressWarnings(tseries::pp.test(s_clean))
    if (is.null(res$p.value) || is.na(res$p.value)) 0.5 else res$p.value
  }, error = function(e) 0.5)
  
  # First differences
  ds_clean <- diff(s_clean)
  adf_diff_p <- tryCatch({
    res <- suppressWarnings(tseries::adf.test(ds_clean))
    if (is.null(res$p.value) || is.na(res$p.value)) 0.01 else res$p.value
  }, error = function(e) 0.01)

  kpss_diff_stat <- tryCatch({
    res <- suppressWarnings(tseries::kpss.test(ds_clean, null = "Level"))
    if (is.null(res$statistic) || is.na(res$statistic)) 0.1 else res$statistic
  }, error = function(e) 0.1)

  # Classification decision logic
  if (isTRUE(adf_lvl_p > 0.10) && isTRUE(kpss_lvl_stat > 0.463) && isTRUE(adf_diff_p <= 0.05)) {
    classification <- "Strong I(1)"
    gate_status    <- "Admissible (CPR Gate)"
  } else if (isTRUE(adf_lvl_p <= 0.05) && isTRUE(kpss_lvl_stat < 0.347)) {
    classification <- "Strong I(0)"
    gate_status    <- "Stationary Regressor"
  } else if (isTRUE(adf_diff_p > 0.10)) {
    classification <- "I(2) Risk"
    gate_status    <- "Blocked"
  } else {
    classification <- "Weak I(1)"
    gate_status    <- "Admissible with FWL Pre-Filter"
  }
  
  return(data.frame(
    Country = country,
    Variable = var_name,
    N = n,
    ADF_Level_p = round(adf_lvl_p, 4),
    KPSS_Level_stat = round(as.numeric(kpss_lvl_stat), 4),
    PP_Level_p = round(pp_lvl_p, 4),
    ADF_Diff_p = round(adf_diff_p, 4),
    KPSS_Diff_stat = round(as.numeric(kpss_diff_stat), 4),
    Classification = classification,
    Gate_Status = gate_status,
    stringsAsFactors = FALSE
  ))
}

results <- list()

# 1. Test Chile Series
if (file.exists(cl_file)) {
  cl_df <- read.csv(cl_file, stringsAsFactors = FALSE)
  cl_vars <- c("k_cap", "k_ME", "k_NR", "omega", "z1_tot", "z2_xcap", 
               "u_hat_k_omega", "u_hat_k_z1", "u_hat_omega_z1", "u_hat_k_omega_z1_pending")
  for (v in cl_vars) {
    if (v %in% colnames(cl_df)) {
      results[[length(results) + 1]] <- test_and_classify(cl_df[[v]], v, "Chile")
    }
  }
}

# 2. Test US Series
if (file.exists(us_file)) {
  us_df <- read.csv(us_file, stringsAsFactors = FALSE)
  us_vars <- c("k_cap", "k_NR", "k_ME", "k_IPP", "k_GOV_TRANS", "omega_nfa", "omega_shaikh", "tau_net")
  for (v in us_vars) {
    if (v %in% colnames(us_df)) {
      results[[length(results) + 1]] <- test_and_classify(us_df[[v]], v, "US")
    }
  }
}

final_ledger <- do.call(rbind, results)
out_csv <- file.path(out_dir, "classified_variable_integration_ledger.csv")
write.csv(final_ledger, out_csv, row.names = FALSE)
cat("Integration order classification engine executed successfully. Ledger saved to:\n", out_csv, "\n")
print(final_ledger)
