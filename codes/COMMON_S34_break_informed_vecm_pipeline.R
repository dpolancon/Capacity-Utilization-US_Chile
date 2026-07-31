#!/usr/bin/env Rscript

# COMMON_S34_break_informed_vecm_pipeline.R
# Evaluates Johansen VECMs under both DRIFT (ecdet="const") and TREND STATIONARITY (ecdet="trend")
# across all window combinatories. Implements Cavaliere et al. (2012) wild bootstrap rank testing
# for non-stationary volatility / small-sample robustness alongside standard residual bootstrap.
# Cointegrating vector normalized strictly with k_NR/k_NRC on the LHS and k_ME on the RHS:
#   k_NR = alpha + gamma * k_ME  =>  beta_knr * k_NR + beta_kme * k_ME = 0  =>  gamma = - beta_kme / beta_knr.
# Extract loading vector (alpha) and short-run lag coefficients via cajorls when r = 1.

suppressMessages({
  if (requireNamespace("urca", quietly = TRUE)) library(urca)
})

set.seed(12345)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
cl_file   <- file.path(repo_root, "data", "processed", "cl_s20", "chile_orthogonalized_panel.csv")
us_file   <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
out_dir   <- file.path(repo_root, "output")

if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

compute_loess_zero_crossings <- function(df, nr_col_name) {
  sub_df <- df[!is.na(df$k_ME) & !is.na(df[[nr_col_name]]), ]
  sub_df$tau <- sub_df$k_ME - sub_df[[nr_col_name]]
  
  l_fit <- loess(tau ~ year, data = sub_df, span = 0.3)
  pred_tau <- predict(l_fit)
  d1 <- c(NA, diff(pred_tau))
  d2 <- c(NA, diff(d1))
  
  inflections <- c()
  for (i in 3:(nrow(sub_df) - 1)) {
    if (!is.na(d2[i]) && !is.na(d2[i+1])) {
      if ((d2[i] > 0 && d2[i+1] < 0) || (d2[i] < 0 && d2[i+1] > 0)) {
        inflections <- c(inflections, sub_df$year[i])
      }
    }
  }
  return(inflections)
}

# Standard i.i.d. residual bootstrap for small-sample Johansen Trace stat
bootstrap_johansen_trace <- function(mat, ec_type, B = 500) {
  n <- nrow(mat)
  if (n < 10) return(NA)
  orig_jo <- tryCatch(urca::ca.jo(mat, type = "trace", ecdet = ec_type, K = 2), error = function(e) NULL)
  if (is.null(orig_jo)) return(NA)
  
  orig_stat <- as.numeric(orig_jo@teststat[2])
  
  diff_mat <- apply(mat, 2, diff)
  boot_stats <- numeric(B)
  for (b in 1:B) {
    boot_idx <- sample(1:nrow(diff_mat), replace = TRUE)
    boot_diff <- diff_mat[boot_idx, ]
    boot_mat <- apply(rbind(mat[1, ], boot_diff), 2, cumsum)
    
    b_jo <- tryCatch(urca::ca.jo(boot_mat, type = "trace", ecdet = ec_type, K = 2), error = function(e) NULL)
    if (!is.null(b_jo)) {
      boot_stats[b] <- as.numeric(b_jo@teststat[2])
    } else {
      boot_stats[b] <- orig_stat
    }
  }
  boot_p <- mean(boot_stats >= orig_stat)
  return(round(boot_p, 3))
}

# Wild Bootstrap Johansen Rank Test (Cavaliere, Rahbek, & Taylor, 2012)
wild_bootstrap_johansen_trace <- function(mat, ec_type, B = 500) {
  n <- nrow(mat)
  if (n < 10) return(NA)
  orig_jo <- tryCatch(urca::ca.jo(mat, type = "trace", ecdet = ec_type, K = 2), error = function(e) NULL)
  if (is.null(orig_jo)) return(NA)
  
  orig_stat <- as.numeric(orig_jo@teststat[2])
  diff_mat  <- apply(mat, 2, diff)
  n_diff    <- nrow(diff_mat)
  
  boot_stats <- numeric(B)
  for (b in 1:B) {
    w <- sample(c(-1, 1), size = n_diff, replace = TRUE)
    wild_diff <- diff_mat * w
    wild_mat  <- apply(rbind(mat[1, ], wild_diff), 2, cumsum)
    
    b_jo <- tryCatch(urca::ca.jo(wild_mat, type = "trace", ecdet = ec_type, K = 2), error = function(e) NULL)
    if (!is.null(b_jo)) {
      boot_stats[b] <- as.numeric(b_jo@teststat[2])
    } else {
      boot_stats[b] <- orig_stat
    }
  }
  wild_p <- mean(boot_stats >= orig_stat)
  return(round(wild_p, 3))
}

run_vecm_spec <- function(df, start_yr, end_yr, country, window_label, break_dummies = NULL, dummy_type = "None", ec_type = "trend") {
  nr_col <- if ("k_NRC" %in% colnames(df)) "k_NRC" else "k_NR"
  sub_df <- df[df$year >= start_yr & df$year <= end_yr, ]
  sub_df <- sub_df[!is.na(sub_df$k_ME) & !is.na(sub_df[[nr_col]]), ]
  n <- nrow(sub_df)
  if (n < 10) return(NULL)

  # Column order: 1 = k_NR (LHS target), 2 = k_ME (RHS regressor)
  mat <- cbind(k_NR = sub_df[[nr_col]], k_ME = sub_df$k_ME)

  dum_mat <- NULL
  if (!is.null(break_dummies) && length(break_dummies) > 0) {
    d_list <- list()
    for (d_yr in break_dummies) {
      d_list[[paste0("D_", d_yr)]] <- ifelse(sub_df$year >= d_yr, 1, 0)
    }
    dum_mat <- as.matrix(as.data.frame(d_list))
  }

  jo_tr <- tryCatch({
    if (!is.null(dum_mat)) {
      urca::ca.jo(mat, type = "trace", ecdet = ec_type, K = 2, dumvar = dum_mat)
    } else {
      urca::ca.jo(mat, type = "trace", ecdet = ec_type, K = 2)
    }
  }, error = function(e) NULL)

  if (is.null(jo_tr)) return(NULL)

  tr_r0  <- as.numeric(jo_tr@teststat[2])
  tr_cv5 <- as.numeric(jo_tr@cval[2, "5pct"])

  # ca.jo vector normalization: beta_1 * k_NR + beta_2 * k_ME = 0 => k_NR = - (beta_2 / beta_1) * k_ME
  raw_vec  <- jo_tr@V[, 1]
  beta_knr <- unname(raw_vec[1])
  beta_kme <- unname(raw_vec[2])
  gamma_hat <- if (abs(beta_knr) > 1e-6) - beta_kme / beta_knr else 1.0

  dec <- if (isTRUE(tr_r0 > tr_cv5)) "r = 1 (Cointegrated)" else "r = 0 (No Cointegration)"

  # i.i.d. Residual Bootstrap p-value
  boot_p <- bootstrap_johansen_trace(mat, ec_type, B = 500)
  
  # Cavaliere et al. (2012) Wild Bootstrap p-value
  wild_p <- wild_bootstrap_johansen_trace(mat, ec_type, B = 500)

  # Speed of Adjustment (Alpha) and Short-Run Dynamics via cajorls
  alpha_knr <- NA
  alpha_kme <- NA
  t_alpha_knr <- NA
  t_alpha_kme <- NA
  gamma1_knr_knr <- NA
  gamma1_knr_kme <- NA
  gamma1_kme_knr <- NA
  gamma1_kme_kme <- NA

  if (n >= 15) {
    caj_fit <- tryCatch(urca::cajorls(jo_tr, r = 1), error = function(e) NULL)
    if (!is.null(caj_fit)) {
      sum_caj <- summary(caj_fit$rlm)
      
      # Model 1: dk_NR equation
      coef_knr <- sum_caj[[1]]$coefficients
      if ("ect1" %in% rownames(coef_knr)) {
        alpha_knr   <- coef_knr["ect1", "Estimate"] * beta_knr
        t_alpha_knr <- coef_knr["ect1", "t value"]
      }
      if ("k_NR.dl1" %in% rownames(coef_knr)) gamma1_knr_knr <- coef_knr["k_NR.dl1", "Estimate"]
      if ("k_ME.dl1" %in% rownames(coef_knr)) gamma1_knr_kme <- coef_knr["k_ME.dl1", "Estimate"]

      # Model 2: dk_ME equation
      coef_kme <- sum_caj[[2]]$coefficients
      if ("ect1" %in% rownames(coef_kme)) {
        alpha_kme   <- coef_kme["ect1", "Estimate"] * beta_knr
        t_alpha_kme <- coef_kme["ect1", "t value"]
      }
      if ("k_NR.dl1" %in% rownames(coef_kme)) gamma1_kme_knr <- coef_kme["k_NR.dl1", "Estimate"]
      if ("k_ME.dl1" %in% rownames(coef_kme)) gamma1_kme_kme <- coef_kme["k_ME.dl1", "Estimate"]
    }
  }

  return(data.frame(
    Country = country, Window = window_label, Start_Year = start_yr, End_Year = end_yr, N = n,
    EC_Control = ec_type, Dummy_Type = dummy_type,
    Break_Dummies = if (is.null(break_dummies)) "None" else paste(break_dummies, collapse = ","),
    Trace_r0_Stat = round(tr_r0, 2), Trace_CV5 = round(tr_cv5, 2),
    Bootstrap_PVal = round(boot_p, 3),
    Wild_Bootstrap_PVal = round(wild_p, 3),
    Gamma_Hat = round(gamma_hat, 4), 
    Alpha_NR = if (is.na(alpha_knr)) NA else round(alpha_knr, 4),
    T_Alpha_NR = if (is.na(t_alpha_knr)) NA else round(t_alpha_knr, 2),
    Alpha_ME = if (is.na(alpha_kme)) NA else round(alpha_kme, 4),
    T_Alpha_ME = if (is.na(t_alpha_kme)) NA else round(t_alpha_kme, 2),
    Gamma1_NR_NR = if (is.na(gamma1_knr_knr)) NA else round(gamma1_knr_knr, 4),
    Gamma1_NR_ME = if (is.na(gamma1_knr_kme)) NA else round(gamma1_knr_kme, 4),
    Gamma1_ME_NR = if (is.na(gamma1_kme_knr)) NA else round(gamma1_kme_knr, 4),
    Gamma1_ME_ME = if (is.na(gamma1_kme_kme)) NA else round(gamma1_kme_kme, 4),
    Decision = dec, stringsAsFactors = FALSE, row.names = NULL
  ))
}

results <- list()

# 1. Chile Pipeline
if (file.exists(cl_file)) {
  cl_df <- read.csv(cl_file)
  cl_loess_selected <- c(1936, 1971, 1982)
  
  cl_specs <- list(
    list(1920, 1938, "Chile Nitrate Crisis & Early State", NULL, "None"),
    list(1939, 1973, "Chile Pre-1973 ISI Era", NULL, "None"),
    list(1974, 1989, "Chile Dictatorship Shock", NULL, "None"),
    list(1990, 2024, "Chile Democratic Neoliberal", NULL, "None"),
    list(1920, 2024, "Chile Full Century (Un-augmented)", NULL, "None"),
    list(1920, 2024, "Chile Full Century (Institutional Break)", c(1973, 1982), "Institutional"),
    list(1920, 2024, "Chile Full Century (LOESS 2nd Deriv Zero-Crossing)", cl_loess_selected, "LOESS 2nd Derivative Zero-Crossing")
  )
  for (ec in c("const", "trend")) {
    for (sp in cl_specs) {
      res <- run_vecm_spec(cl_df, sp[[1]], sp[[2]], "Chile", sp[[3]], sp[[4]], sp[[5]], ec_type = ec)
      if (!is.null(res)) results[[length(results) + 1]] <- res
    }
  }
}

# 2. US Pipeline
if (file.exists(us_file)) {
  us_df <- read.csv(us_file)
  us_loess_selected <- c(1933, 1968, 2008)
  
  us_specs <- list(
    list(1925, 1946, "US Interwar & WWII Era", NULL, "None"),
    list(1947, 1973, "US Fordist Expansion", NULL, "None"),
    list(1974, 2008, "US Neoliberal Restructuring", NULL, "None"),
    list(2009, 2021, "US Post-GFC Stagnation", NULL, "None"),
    list(1925, 2021, "US Long-Fordism Century (Un-augmented)", NULL, "None"),
    list(1925, 2021, "US Long-Fordism Century (Institutional Break)", c(1973, 2008), "Institutional"),
    list(1925, 2021, "US Long-Fordism Century (LOESS 2nd Deriv Zero-Crossing)", us_loess_selected, "LOESS 2nd Derivative Zero-Crossing")
  )
  for (ec in c("const", "trend")) {
    for (sp in us_specs) {
      res <- run_vecm_spec(us_df, sp[[1]], sp[[2]], "US", sp[[3]], sp[[4]], sp[[5]], ec_type = ec)
      if (!is.null(res)) results[[length(results) + 1]] <- res
    }
  }
}

final_ledger <- do.call(rbind, results)
out_csv <- file.path(out_dir, "break_informed_johansen_vecm_ledger.csv")
write.csv(final_ledger, out_csv, row.names = FALSE)

cat("Break-informed Johansen VECM pipeline executed successfully.\n")
