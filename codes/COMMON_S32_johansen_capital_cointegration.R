#!/usr/bin/env Rscript

# COMMON_S32_johansen_capital_cointegration.R
# Evaluates Johansen Trace and Maximum Eigenvalue cointegration tests between k_ME and k_NR/k_NRC
# across historical sub-sample windows for US and Chile.
# Extracts normalized cointegrating vectors beta = [1, -gamma]' and multicointegrated ECT terms.

suppressPackageStartupMessages({
  if (requireNamespace("urca", quietly = TRUE)) library(urca)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
cl_file <- file.path(repo_root, "data", "processed", "cl_s20", "chile_orthogonalized_panel.csv")
us_file <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
out_dir <- file.path(repo_root, "data", "processed", "johansen_capital")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

run_johansen_window <- function(df, start_yr, end_yr, country, window_label) {
  # Harmonize structures column name
  nr_col <- if ("k_NRC" %in% colnames(df)) "k_NRC" else "k_NR"
  
  sub_df <- df[df$year >= start_yr & df$year <= end_yr, ]
  sub_df <- sub_df[!is.na(sub_df$k_ME) & !is.na(sub_df[[nr_col]]), ]
  n <- nrow(sub_df)
  
  if (n < 15) return(NULL)
  
  data_mat <- cbind(k_ME = sub_df$k_ME, k_NR = sub_df[[nr_col]])
  
  # Johansen Trace Test with linear trend in cointegration space
  jo_trace <- tryCatch({
    urca::ca.jo(data_mat, type = "trace", ecdet = "trend", K = 2)
  }, error = function(e) NULL)
  
  # Johansen Max-Eigenvalue Test
  jo_eigen <- tryCatch({
    urca::ca.jo(data_mat, type = "eigen", ecdet = "trend", K = 2)
  }, error = function(e) NULL)
  
  if (is.null(jo_trace) || is.null(jo_eigen)) return(NULL)
  
  tr_stat_r0 <- as.numeric(jo_trace@teststat[2])
  tr_cv5_r0  <- as.numeric(jo_trace@cval[2, "5pct"])
  tr_stat_r1 <- as.numeric(jo_trace@teststat[1])
  tr_cv5_r1  <- as.numeric(jo_trace@cval[1, "5pct"])
  
  eig_stat_r0 <- as.numeric(jo_eigen@teststat[2])
  eig_cv5_r0  <- as.numeric(jo_eigen@cval[2, "5pct"])
  
  raw_vec <- jo_trace@V[, 1]
  beta_kme <- unname(raw_vec[1])
  beta_knr <- unname(raw_vec[2])
  
  gamma_hat <- if (abs(beta_kme) > 1e-6) - beta_knr / beta_kme else 1.0
  
  rank_decision <- if (tr_stat_r0 > tr_cv5_r0 && tr_stat_r1 <= tr_cv5_r1) {
    "r = 1 (Cointegrated)"
  } else if (tr_stat_r0 > tr_cv5_r0 && tr_stat_r1 > tr_cv5_r1) {
    "r = 2 (Stationary System)"
  } else {
    "r = 0 (No Cointegration)"
  }
  
  sub_df$ect_mechanization_bias <- sub_df$k_ME - gamma_hat * sub_df[[nr_col]]
  
  res_row <- data.frame(
    Country = country,
    Window = window_label,
    Start_Year = start_yr,
    End_Year = end_yr,
    N = n,
    Trace_r0_stat = round(tr_stat_r0, 2),
    Trace_r0_cv5 = round(tr_cv5_r0, 2),
    MaxEig_r0_stat = round(eig_stat_r0, 2),
    MaxEig_r0_cv5 = round(eig_cv5_r0, 2),
    Gamma_Hat = round(gamma_hat, 4),
    Rank_Decision = rank_decision,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  
  sub_ect <- data.frame(
    year = sub_df$year,
    k_ME = sub_df$k_ME,
    k_NR = sub_df[[nr_col]],
    ect_mechanization_bias = sub_df$ect_mechanization_bias,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  
  return(list(summary = res_row, ect_df = sub_ect))
}

results_list <- list()
ect_data_list <- list()

# 1. Process US Windows
if (file.exists(us_file)) {
  us_df <- read.csv(us_file, stringsAsFactors = FALSE)
  us_windows <- list(
    c(1947, 1973, "Fordist Golden Age"),
    c(1974, 2007, "Neoliberal Restructuring"),
    c(1947, 2021, "Full Sample (1947-2021)")
  )
  for (w in us_windows) {
    res <- run_johansen_window(us_df, as.numeric(w[1]), as.numeric(w[2]), "US", w[3])
    if (!is.null(res)) {
      results_list[[length(results_list) + 1]] <- res$summary
      res$ect_df$Country <- "US"
      res$ect_df$Window <- w[3]
      ect_data_list[[length(ect_data_list) + 1]] <- res$ect_df
    }
  }
}

# 2. Process Chile Windows
if (file.exists(cl_file)) {
  cl_df <- read.csv(cl_file, stringsAsFactors = FALSE)
  cl_windows <- list(
    c(1920, 1973, "ISI Developmentalist Era"),
    c(1974, 2024, "Neoliberal Transition & Export Model"),
    c(1920, 2024, "Full Sample (1920-2024)")
  )
  for (w in cl_windows) {
    res <- run_johansen_window(cl_df, as.numeric(w[1]), as.numeric(w[2]), "Chile", w[3])
    if (!is.null(res)) {
      results_list[[length(results_list) + 1]] <- res$summary
      res$ect_df$Country <- "Chile"
      res$ect_df$Window <- w[3]
      ect_data_list[[length(ect_data_list) + 1]] <- res$ect_df
    }
  }
}

final_summary <- do.call(rbind, results_list)
out_summary_csv <- file.path(out_dir, "johansen_capital_cointegration_ledger.csv")
write.csv(final_summary, out_summary_csv, row.names = FALSE)

final_ect <- do.call(rbind, ect_data_list)
out_ect_csv <- file.path(out_dir, "extracted_mechanization_bias_ect_panel.csv")
write.csv(final_ect, out_ect_csv, row.names = FALSE)

cat("Johansen capital cointegration analysis completed successfully.\n")
cat("Summary ledger saved to:", out_summary_csv, "\n")
print(final_summary)
