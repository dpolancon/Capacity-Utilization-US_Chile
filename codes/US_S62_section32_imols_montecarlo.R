#!/usr/bin/env Rscript
# ==============================================================================
# S62: CMPR IM-OLS Custom Critical Values Simulation Engine for Section 3.2
# ==============================================================================
# Monte Carlo / Bootstrap simulation for CT_IM cointegration test and coefficient
# t-statistics under Specification B integration geometry.
#
# Variants:
# 1. set1: Standard Wage Interaction (kappa * omega) + Relative Price (kappa * p_kappa)
# 2. set1_break: Set 1 + Endogenous Bai-Perron Breaks
# 3. set2: Effective Wage Interaction (kappa * C_t) + Relative Price (kappa * p_kappa)
# 4. set2_break: Set 2 + Endogenous Bai-Perron Breaks
#
# FWL Orthogonalization is strictly applied before estimation.
# ==============================================================================

options(stringsAsFactors = FALSE, scipen = 999)
suppressPackageStartupMessages({
  library(cointReg)
  library(matrixStats)
  library(parallel)
})

set.seed(1929)

# Source CMPR estimator
repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
source(file.path(repo_root, ".agents", "skills", "cpr-im-ols", "scripts", "cpr_imols_estimator.R"))

calc_ct_im <- function(residuals_im, omega_uv) {
  delta_S <- c(0, diff(residuals_im))
  cum_delta_S <- cumsum(delta_S)
  ct_stat <- sum(cum_delta_S^2) / (length(residuals_im)^2 * omega_uv)
  return(ct_stat)
}

fwl_orthogonalize <- function(inter_raw, aux_mat) {
  df_aux <- as.data.frame(aux_mat)
  df_aux$y_inter <- inter_raw
  fit_aux <- tryCatch(lm(y_inter ~ . - 1, data = df_aux), error = function(e) NULL)
  if (is.null(fit_aux)) return(rep(0, length(inter_raw)))
  return(fit_aux$residuals)
}

run_cmpr_sim <- function(T_obs = 94, variant = "set1") {
  has_break <- grepl("_break", variant)
  
  # 1. Generate independent random walks (I(1) base variables)
  k_NRC   <- cumsum(rnorm(T_obs))
  kappa_t <- cumsum(rnorm(T_obs))
  p_kappa <- cumsum(rnorm(T_obs))
  omega_t <- cumsum(rnorm(T_obs))
  iota_t  <- cumsum(rnorm(T_obs))
  
  # 2. Build deterministic base
  deter_base <- matrix(1, nrow = T_obs, ncol = 1)
  colnames(deter_base) <- "const"
  
  # 3. Build interactions
  if (variant %in% c("set1", "set1_break")) {
    inter_raw_1 <- kappa_t * omega_t
    inter_raw_2 <- kappa_t * p_kappa
  } else {
    C_t <- omega_t * (1 - iota_t)
    inter_raw_1 <- kappa_t * C_t
    inter_raw_2 <- kappa_t * p_kappa
  }
  
  # 4. Generate dependent variable under null of cointegration
  # Under H0, y is a stationary I(0) process independent of X, meaning the true cointegrating
  # vector beta_true is 0.
  y <- rnorm(T_obs)
  
  aux_mat_base <- cbind(k_NRC, kappa_t, deter_base)
  ortho_1_base <- fwl_orthogonalize(inter_raw_1, aux_mat_base)
  ortho_2_base <- fwl_orthogonalize(inter_raw_2, aux_mat_base)
  
  X_base <- cbind(k_NRC, kappa_t)
  X_full_base <- cbind(k_NRC, kappa_t, ortho_1_base, ortho_2_base)
  
  deter_final <- deter_base
  X_final <- X_full_base
  
  if (has_break) {
    # Compute base IM-OLS residuals to find breaks
    Sy <- cumsum(y)
    Sd_base <- deter_base
    Sx_base <- matrixStats::colCumsums(X_full_base)
    X_base_df <- data.frame(Sd_base, Sx_base, X_base)
    
    im_mod1 <- tryCatch(lm(Sy ~ . - 1, data = X_base_df), error = function(e) NULL)
    if (!is.null(im_mod1)) {
      u_base <- im_mod1$resid
      bp_res <- tryCatch(strucchange::breakpoints(u_base ~ 1, h = 0.15), error = function(e) NULL)
      
      if (!is.null(bp_res) && !is.null(bp_res$breakpoints) && !all(is.na(bp_res$breakpoints))) {
        bp_idx <- bp_res$breakpoints
        for (byr_idx in bp_idx) {
          step_dummy <- ifelse(1:T_obs >= byr_idx, 1, 0)
          deter_final <- cbind(deter_final, step_dummy)
          colnames(deter_final)[ncol(deter_final)] <- paste0("D", byr_idx)
        }
        # Re-orthogonalize with breaks
        aux_mat_full <- cbind(k_NRC, kappa_t, deter_final)
        ortho_1_full <- fwl_orthogonalize(inter_raw_1, aux_mat_full)
        ortho_2_full <- fwl_orthogonalize(inter_raw_2, aux_mat_full)
        X_final <- cbind(k_NRC, kappa_t, ortho_1_full, ortho_2_full)
      }
    }
  }
  
  fit <- tryCatch({
    cointRegIM_CMPR(x = X_final, y = y, deter = deter_final, x_base = X_base, selector = c(1, 2), kernel = "ba", bandwidth = "nw")
  }, error = function(e) NULL)
  
  if (is.null(fit)) return(NULL)
  
  u_im <- fit$u.plus
  omega2 <- fit$omega.u.v
  
  ct_stat <- NA
  if (!is.na(omega2) && omega2 > 0) {
    ct_stat <- calc_ct_im(u_im, omega2)
  }
  
  if (is.na(ct_stat)) return(NULL)
  
  # Calculate t-stats
  # The true parameters beta_true are 0 under this DGP.
  t_stats <- fit$theta / fit$sd.theta
  
  d.k <- ncol(deter_final)
  x.k <- ncol(X_final) # 4
  
  t_kappa <- abs(t_stats[d.k + 2])
  t_ortho1 <- abs(t_stats[d.k + x.k - 1])
  t_ortho2 <- abs(t_stats[d.k + x.k])
  
  return(list(
    CT_IM = ct_stat,
    t_kappa = t_kappa,
    t_ortho1 = t_ortho1,
    t_ortho2 = t_ortho2
  ))
}

run_cmpr_simulation_suite <- function(N_sim = 100, T_obs = 94, out_csv = NULL) {
  cat(sprintf("\nStarting Section 3.2 CMPR Simulation Suite (N_sim = %d, T = %d)...\n", N_sim, T_obs))
  
  num_cores <- min(10, detectCores() - 2)
  if (num_cores < 1) num_cores <- 1
  cat(sprintf("Using %d cores for parallel cluster execution.\n", num_cores))
  cl <- makeCluster(num_cores)
  
  clusterEvalQ(cl, {
    library(cointReg)
    library(matrixStats)
    library(strucchange)
    repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
    source(file.path(repo_root, ".agents", "skills", "cpr-im-ols", "scripts", "cpr_imols_estimator.R"))
  })
  
  clusterExport(cl, c("run_cmpr_sim", "calc_ct_im", "fwl_orthogonalize"))
  
  variants <- c("set1", "set1_break", "set2", "set2_break")
  results_summary <- list()
  
  for (v in variants) {
    cat(sprintf("  Executing variant: %s ... ", v))
    
    ct_vec <- numeric()
    tk_vec <- numeric()
    to1_vec <- numeric()
    to2_vec <- numeric()
    
    attempts <- 0
    while (length(ct_vec) < N_sim && attempts < N_sim * 5) {
      current_needed <- N_sim - length(ct_vec)
      run_size <- max(current_needed, num_cores * 2)
      attempts <- attempts + run_size
      
      sim_results <- parLapply(cl, 1:run_size, function(i, T_obs, v) {
        run_cmpr_sim(T_obs = T_obs, variant = v)
      }, T_obs = T_obs, v = v)
      
      for (res in sim_results) {
        if (!is.null(res) && !is.na(res$CT_IM)) {
          ct_vec <- c(ct_vec, res$CT_IM)
          tk_vec <- c(tk_vec, res$t_kappa)
          to1_vec <- c(to1_vec, res$t_ortho1)
          to2_vec <- c(to2_vec, res$t_ortho2)
        }
      }
    }
    
    if (length(ct_vec) > N_sim) {
      ct_vec <- ct_vec[1:N_sim]
      tk_vec <- tk_vec[1:N_sim]
      to1_vec <- to1_vec[1:N_sim]
      to2_vec <- to2_vec[1:N_sim]
    }
    
    res_row <- data.frame(
      Variant = v,
      Valid_Sims = length(ct_vec),
      CT_IM_p90 = quantile(ct_vec, 0.90, na.rm = TRUE),
      CT_IM_p95 = quantile(ct_vec, 0.95, na.rm = TRUE),
      CT_IM_p99 = quantile(ct_vec, 0.99, na.rm = TRUE),
      t_kappa_p90  = quantile(tk_vec, 0.90, na.rm = TRUE),
      t_kappa_p95  = quantile(tk_vec, 0.95, na.rm = TRUE),
      t_kappa_p99  = quantile(tk_vec, 0.99, na.rm = TRUE),
      t_ortho1_p90 = quantile(to1_vec, 0.90, na.rm = TRUE),
      t_ortho1_p95 = quantile(to1_vec, 0.95, na.rm = TRUE),
      t_ortho1_p99 = quantile(to1_vec, 0.99, na.rm = TRUE),
      t_ortho2_p90 = quantile(to2_vec, 0.90, na.rm = TRUE),
      t_ortho2_p95 = quantile(to2_vec, 0.95, na.rm = TRUE),
      t_ortho2_p99 = quantile(to2_vec, 0.99, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
    
    results_summary[[v]] <- res_row
    cat("Done.\n")
  }
  
  stopCluster(cl)
  
  final_df <- do.call(rbind, results_summary)
  if (is.null(out_csv)) {
    repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
    out_csv <- file.path(repo_root, "output", "US", "S62_SECTION32_MC", "csv", sprintf("cmpr_s32_critical_values_T%d_N%d.csv", T_obs, N_sim))
  }
  
  dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)
  
  write.csv(final_df, out_csv, row.names = FALSE)
  cat(sprintf("\nSuccessfully saved simulation results to: %s\n", out_csv))
  print(final_df)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 3) {
  nsim <- as.integer(args[1])
  tobs <- as.integer(args[2])
  out_file <- args[3]
  run_cmpr_simulation_suite(N_sim = nsim, T_obs = tobs, out_csv = out_file)
} else if (length(args) == 2) {
  nsim <- as.integer(args[1])
  tobs <- as.integer(args[2])
  run_cmpr_simulation_suite(N_sim = nsim, T_obs = tobs)
} else if (length(args) == 1) {
  nsim <- as.integer(args[1])
  run_cmpr_simulation_suite(N_sim = nsim, T_obs = 94)
} else {
  run_cmpr_simulation_suite(N_sim = 100, T_obs = 94)
}
