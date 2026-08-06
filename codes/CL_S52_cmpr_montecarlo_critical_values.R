#!/usr/bin/env Rscript
# ==============================================================================
# CL_S52_cmpr_montecarlo_critical_values.R
# ==============================================================================
# Monte Carlo / Bootstrap simulation for CT_IM cointegration test and coefficient
# t-statistics under I(1) x I(1) interaction terms and endogenous threshold selection.
# 
# For the Chilean peripheral model, this simulates the Profile LS grid search
# over the capacity to import variable on every pass to correctly size the bounds.
# ==============================================================================

suppressPackageStartupMessages({
  library(cointReg)
  library(matrixStats)
  library(parallel)
})

set.seed(1929)
repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

# Fallback functions if cpr_imols_estimator.R isn't exported perfectly to cluster
calc_ct_im <- function(residuals_im, omega_uv) {
  delta_S <- c(0, diff(residuals_im))
  cum_delta_S <- cumsum(delta_S)
  ct_stat <- sum(cum_delta_S^2) / (length(residuals_im)^2 * omega_uv)
  return(ct_stat)
}

fwl_orthogonalize <- function(inter_raw, aux_df) {
  df_mod <- data.frame(inter_raw = inter_raw)
  df_mod <- cbind(df_mod, aux_df)
  fit_aux <- lm(inter_raw ~ . - 1, data = df_mod)
  return(fit_aux$residuals)
}

run_chile_cmpr_sim <- function(T_obs = 104) {
  # Simulate 5 independent random walks
  # e1: k_NR, e2: kappa, e3: omega, e4: p_kappa, e5: M_cap
  e1 <- rnorm(T_obs)
  e2 <- rnorm(T_obs)
  e3 <- rnorm(T_obs)
  e4 <- rnorm(T_obs)
  e5 <- rnorm(T_obs)
  
  k_NR <- cumsum(e1)
  kappa <- cumsum(e2)
  omega <- cumsum(e3)
  p_kappa <- cumsum(e4)
  M_cap <- cumsum(e5)
  
  omega_kappa <- omega * kappa
  
  # Base regressors
  x_base_base <- cbind(k_NR, kappa)
  
  u_t <- rnorm(T_obs)
  y_t <- u_t # Under H0 of cointegration, y is just stationary noise (or cointegrated directly)
  
  deter_base <- matrix(1, nrow = T_obs, ncol = 1)
  colnames(deter_base) <- "const"
  
  # Grid search over M_cap (15th to 85th percentile)
  gamma_grid <- quantile(M_cap, probs = seq(0.15, 0.85, by = 0.05), na.rm = TRUE)
  best_ssr <- Inf
  best_fit_info <- NULL
  
  for (g in gamma_grid) {
    D_ext <- ifelse(M_cap <= g, 1, 0)
    kappa_D <- kappa * D_ext
    omega_kappa_D <- omega_kappa * D_ext
    
    # Normally we'd FWL orthogonalize interactions against base variables here if strict.
    # We follow the same matrix layout as CL_S50
    # X matrix: k_NR, kappa, omega_kappa, kappa_D, omega_kappa_D, p_kappa
    x_levels_full <- cbind(k_NR, kappa, omega_kappa, kappa_D, omega_kappa_D, p_kappa)
    
    # Fast IM-OLS step
    Sd <- matrixStats::colCumsums(deter_base)
    Sx <- matrixStats::colCumsums(x_levels_full)
    Sy <- cumsum(y_t)
    
    Sxrow <- nrow(Sx)
    InvBase <- Sx[Sxrow:1, , drop = FALSE]
    InvBaseCum <- matrixStats::colCumsums(InvBase)
    RevBase <- InvBaseCum[Sxrow:1, , drop = FALSE]
    Zreg <- matrixStats::colCumsums(RevBase)
    
    X2 <- data.frame(Sd, Sx, x_base_base, Zreg)
    im_fit <- tryCatch({ lm(Sy ~ . - 1, data = X2) }, error = function(e) NULL)
    
    if (!is.null(im_fit)) {
      ssr <- sum(im_fit$residuals^2)
      if (ssr < best_ssr) {
        best_ssr <- ssr
        best_fit_info <- list(
          im_fit = im_fit,
          x_levels_full = x_levels_full
        )
      }
    }
  }
  
  if (is.null(best_fit_info)) return(NULL)
  
  im_fit <- best_fit_info$im_fit
  x_levels_full <- best_fit_info$x_levels_full
  
  # Calculate Long Run Variance for standard errors and CT_IM test
  fit_lvl <- tryCatch({ lm.fit(cbind(deter_base, x_levels_full), y_t) }, error = function(e) NULL)
  if (is.null(fit_lvl)) return(NULL)
  
  u_hat <- fit_lvl$residuals
  dx_base <- rbind(rep(0, ncol(x_base_base)), apply(x_base_base, 2, diff))
  eta_t <- cbind(u_hat, dx_base)
  
  lrv_res <- tryCatch({ cointReg::getLongRunVar(eta_t, kernel = "ba") }, error = function(e) NULL)
  if (is.null(lrv_res) || is.null(lrv_res$Omega)) return(NULL)
  
  omega2_eta <- lrv_res$Omega
  xb_k <- ncol(x_base_base)
  Omega11 <- omega2_eta[1, 1]
  Omega22 <- omega2_eta[2:(xb_k + 1), 2:(xb_k + 1), drop = FALSE]
  Omega12 <- omega2_eta[1, 2:(xb_k + 1), drop = FALSE]
  Omega21 <- omega2_eta[2:(xb_k + 1), 1, drop = FALSE]
  
  O22inv <- cointReg:::trySolve(Omega22)
  if (is.null(O22inv)) return(NULL)
  
  omega_uv <- as.numeric(Omega11 - Omega12 %*% O22inv %*% Omega21)
  if (is.na(omega_uv) || omega_uv <= 0) return(NULL)
  
  ct_stat <- calc_ct_im(im_fit$residuals, omega_uv)
  
  # T-statistics
  Xmat <- as.matrix(data.frame(Sd, Sx, x_base_base))
  S_mat <- matrixStats::colCumsums(Xmat)
  DS <- rbind(S_mat[T_obs, ], t(S_mat[T_obs, ] - t(S_mat[1:(T_obs - 1), ])))
  Ha <- cointReg:::trySolve(t(Xmat) %*% Xmat)
  if (is.null(Ha)) return(NULL)
  H <- Ha %*% t(DS)
  V <- H %*% t(H)
  
  diag_V <- diag(V)
  if (any(is.na(diag_V)) || any(diag_V <= 0)) return(NULL)
  
  sd_theta <- sqrt(omega_uv * diag_V)
  coefs <- im_fit$coefficients[1:ncol(Xmat)]
  t_stats <- coefs / sd_theta
  
  # Indexes in Xmat:
  # Sd is 1 col (const)
  # Sx is 6 cols: k_NR (2), kappa (3), omega_kappa (4), kappa_D (5), omega_kappa_D (6), p_kappa (7)
  # x_base_base is 2 cols
  
  return(list(
    ct_im = ct_stat,
    t_omega_kappa = abs(t_stats[4]),
    t_kappa_D = abs(t_stats[5]),
    t_omega_kappa_D = abs(t_stats[6])
  ))
}

run_chile_cmpr_simulation_suite <- function(N_sim = 100, T_obs = 104, out_csv = NULL) {
  cat(sprintf("\nStarting Chile CMPR Threshold Critical Value Simulation Suite (N_sim = %d, T = %d)...\n", N_sim, T_obs))
  
  num_cores <- min(12, detectCores() - 2)
  if (num_cores < 1) num_cores <- 1
  cat(sprintf("Using %d cores for parallel cluster execution.\n", num_cores))
  cl <- makeCluster(num_cores)
  
  clusterEvalQ(cl, {
    library(cointReg)
    library(matrixStats)
  })
  
  clusterExport(cl, c("run_chile_cmpr_sim", "calc_ct_im", "fwl_orthogonalize"))
  
  ct_vec <- numeric()
  tok_vec <- numeric()
  tkd_vec <- numeric()
  tokd_vec <- numeric()
  
  attempts <- 0
  
  while (length(ct_vec) < N_sim && attempts < N_sim * 5) {
    current_needed <- N_sim - length(ct_vec)
    run_size <- max(current_needed, num_cores * 2)
    attempts <- attempts + run_size
    
    sim_results <- parLapply(cl, 1:run_size, function(i, T_obs) {
      run_chile_cmpr_sim(T_obs = T_obs)
    }, T_obs = T_obs)
    
    for (res in sim_results) {
      if (!is.null(res) && !is.na(res$ct_im) && !is.na(res$t_omega_kappa_D)) {
        ct_vec <- c(ct_vec, res$ct_im)
        tok_vec <- c(tok_vec, res$t_omega_kappa)
        tkd_vec <- c(tkd_vec, res$t_kappa_D)
        tokd_vec <- c(tokd_vec, res$t_omega_kappa_D)
      }
    }
    
    # Progress check
    if (length(ct_vec) %% 1000 == 0 && length(ct_vec) > 0) {
      cat(sprintf("  Completed %d / %d valid sims...\n", length(ct_vec), N_sim))
    }
  }
  
  if (length(ct_vec) > N_sim) {
    ct_vec <- ct_vec[1:N_sim]
    tok_vec <- tok_vec[1:N_sim]
    tkd_vec <- tkd_vec[1:N_sim]
    tokd_vec <- tokd_vec[1:N_sim]
  }
  
  stopCluster(cl)
  
  res_row <- data.frame(
    Variant = "Chile_Threshold",
    Valid_Sims = length(ct_vec),
    CT_IM_p90 = quantile(ct_vec, 0.90, na.rm = TRUE),
    CT_IM_p95 = quantile(ct_vec, 0.95, na.rm = TRUE),
    CT_IM_p99 = quantile(ct_vec, 0.99, na.rm = TRUE),
    t_omega_kappa_D_p90 = quantile(tokd_vec, 0.90, na.rm = TRUE),
    t_omega_kappa_D_p95 = quantile(tokd_vec, 0.95, na.rm = TRUE),
    t_omega_kappa_D_p99 = quantile(tokd_vec, 0.99, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
  
  if (is.null(out_csv)) {
    out_csv <- sprintf("output/Chile_S52_cmpr_critical_values_N%d.csv", N_sim)
  }
  
  dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)
  write.csv(res_row, out_csv, row.names = FALSE)
  cat(sprintf("\nSuccessfully saved simulation results to: %s\n", out_csv))
  print(res_row)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 2) {
  nsim <- as.integer(args[1])
  out_file <- args[2]
  run_chile_cmpr_simulation_suite(N_sim = nsim, T_obs = 104, out_csv = out_file)
} else if (length(args) == 1) {
  nsim <- as.integer(args[1])
  run_chile_cmpr_simulation_suite(N_sim = nsim, T_obs = 104)
} else {
  run_chile_cmpr_simulation_suite(N_sim = 100000, T_obs = 104)
}
