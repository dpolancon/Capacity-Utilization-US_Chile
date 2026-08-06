# ==============================================================================
# S52: CMPR IM-OLS Custom Critical Values Simulation Engine (Vogelsang et al. 2024)
# ==============================================================================
# Monte Carlo / Bootstrap simulation for CT_IM cointegration test and coefficient
# t-statistics under I(1) x I(1) interaction terms and pseudo-ordering expansion.
#
# Variants:
# 1. spec1: Double Interaction (k * omega)
# 2. spec1_break: Double Interaction + Bai-Perron Breaks
# 3. spec2: Triple Interaction (k * omega * (1 - iota))
# 4. spec2_break: Triple Interaction + Bai-Perron Breaks
#
# FWL Orthogonalization is strictly applied before estimation.
# ==============================================================================

suppressPackageStartupMessages({
  library(cointReg)
  library(matrixStats)
  library(parallel)
})

set.seed(1929)

calc_ct_im <- function(residuals_im, omega_uv) {
  delta_S <- c(0, diff(residuals_im))
  cum_delta_S <- cumsum(delta_S)
  ct_stat <- sum(cum_delta_S^2) / (length(residuals_im)^2 * omega_uv)
  return(ct_stat)
}

fwl_orthogonalize <- function(inter_raw, k_vec, deter_mat) {
  aux_df <- data.frame(inter_raw = inter_raw, k = k_vec)
  if (ncol(deter_mat) > 0) aux_df <- cbind(aux_df, deter_mat)
  fit_aux <- lm(inter_raw ~ . - 1, data = aux_df)
  return(fit_aux$residuals)
}

run_cmpr_sim <- function(T_obs = 94, variant = "spec1") {
  has_break <- grepl("_break", variant)
  
  e1 <- rnorm(T_obs)
  e2 <- rnorm(T_obs)
  e3 <- rnorm(T_obs)
  
  k_t <- cumsum(e1)
  w_t <- cumsum(e2)
  i_t <- cumsum(e3)
  
  c_vec <- NULL
  if (variant %in% c("spec1", "spec1_break")) {
    inter_raw <- k_t * w_t
    x_base_base <- cbind(k_t)
  } else {
    C_t <- w_t * (1 - i_t)
    inter_raw <- k_t * C_t
    c_vec <- C_t
    x_base_base <- cbind(k_t)
  }
  
  u_t <- rnorm(T_obs)
  y_t <- u_t
  
  deter_base <- matrix(1, nrow = T_obs, ncol = 1)
  colnames(deter_base) <- "const"
  
  inter_ortho_base <- fwl_orthogonalize(inter_raw, k_t, deter_base)
  x_levels_base <- cbind(k_t, inter_ortho_base)
  
  deter_final <- deter_base
  x_levels_final <- x_levels_base
  
  if (has_break) {
    # Compute u.plus for the Bai-Perron audit (IM-OLS residual)
    Sy <- cumsum(y_t)
    Sd_base <- deter_base
    Sx_base <- matrixStats::colCumsums(x_levels_base)
    X_base_df <- data.frame(Sd_base, Sx_base, x_base_base)
    
    im.mod1 <- lm(Sy ~ . - 1, data = X_base_df)
    u_base <- im.mod1$resid
    
    bp_res <- tryCatch({
      strucchange::breakpoints(u_base ~ 1, h = 0.15)
    }, error = function(e) NULL)
    
    if (!is.null(bp_res) && !is.null(bp_res$breakpoints) && !all(is.na(bp_res$breakpoints))) {
      bp_idx <- bp_res$breakpoints
      for (byr_idx in bp_idx) {
        step_dummy <- ifelse(1:T_obs >= byr_idx, 1, 0)
        deter_final <- cbind(deter_final, step_dummy)
        colnames(deter_final)[ncol(deter_final)] <- paste0("D", byr_idx)
      }
      inter_ortho_full <- fwl_orthogonalize(inter_raw, k_t, deter_final)
      x_levels_final <- cbind(k_t, inter_ortho_full)
    }
  }
  
  d_k <- ncol(deter_final)
  Sd <- matrixStats::colCumsums(deter_final)
  Sx <- matrixStats::colCumsums(x_levels_final)
  Sy <- cumsum(y_t)
  
  Sxrow <- nrow(Sx)
  InvBase <- Sx[Sxrow:1, , drop = FALSE]
  InvBaseCum <- matrixStats::colCumsums(InvBase)
  RevBase <- InvBaseCum[Sxrow:1, , drop = FALSE]
  Zreg <- matrixStats::colCumsums(RevBase)
  
  X2 <- data.frame(Sd, Sx, x_base_base, Zreg)
  im_fit <- tryCatch({ lm(Sy ~ . - 1, data = X2) }, error = function(e) NULL)
  if (is.null(im_fit)) return(NULL)
  
  fit_lvl <- tryCatch({ lm.fit(cbind(deter_final, x_levels_final), y_t) }, error = function(e) NULL)
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
  if (any(is.na(sd_theta)) || any(sd_theta <= 0)) return(NULL)
  
  coefs <- im_fit$coefficients[1:ncol(Xmat)]
  t_stats <- coefs / sd_theta
  
  idx_k <- d_k + 1
  idx_inter <- d_k + 2
  
  return(list(
    ct_im = ct_stat,
    t_k0 = abs(t_stats[idx_k]),
    t_inter = abs(t_stats[idx_inter])
  ))
}

run_cmpr_simulation_suite <- function(N_sim = 100, T_obs = 94, out_csv = NULL) {
  cat(sprintf("\nStarting CMPR Custom Critical Value Simulation Suite (N_sim = %d, T = %d)...\n", N_sim, T_obs))
  
  num_cores <- min(10, detectCores() - 2)
  if (num_cores < 1) num_cores <- 1
  cat(sprintf("Using %d cores for parallel cluster execution.\n", num_cores))
  cl <- makeCluster(num_cores)
  
  clusterEvalQ(cl, {
    library(cointReg)
    library(matrixStats)
    library(strucchange)
  })
  
  clusterExport(cl, c("run_cmpr_sim", "calc_ct_im", "fwl_orthogonalize"))
  
  variants <- c("spec1", "spec1_break", "spec2", "spec2_break")
  results_summary <- list()
  
  for (v in variants) {
    cat(sprintf("  Executing variant: %s ... ", v))
    
    ct_vec <- numeric()
    tk0_vec <- numeric()
    tinter_vec <- numeric()
    
    chunk_size <- max(100, N_sim / 10)
    attempts <- 0
    
    while (length(ct_vec) < N_sim && attempts < N_sim * 5) {
      current_needed <- N_sim - length(ct_vec)
      run_size <- max(current_needed, num_cores * 2)
      attempts <- attempts + run_size
      
      sim_results <- parLapply(cl, 1:run_size, function(i, T_obs, v) {
        run_cmpr_sim(T_obs = T_obs, variant = v)
      }, T_obs = T_obs, v = v)
      
      for (res in sim_results) {
        if (!is.null(res) && !is.na(res$ct_im) && !is.na(res$t_k0) && !is.na(res$t_inter)) {
          ct_vec <- c(ct_vec, res$ct_im)
          tk0_vec <- c(tk0_vec, res$t_k0)
          tinter_vec <- c(tinter_vec, res$t_inter)
        }
      }
    }
    
    if (length(ct_vec) > N_sim) {
      ct_vec <- ct_vec[1:N_sim]
      tk0_vec <- tk0_vec[1:N_sim]
      tinter_vec <- tinter_vec[1:N_sim]
    }
    
    res_row <- data.frame(
      Variant = v,
      Valid_Sims = length(ct_vec),
      CT_IM_p90 = quantile(ct_vec, 0.90, na.rm = TRUE),
      CT_IM_p95 = quantile(ct_vec, 0.95, na.rm = TRUE),
      CT_IM_p99 = quantile(ct_vec, 0.99, na.rm = TRUE),
      t_k0_p90  = quantile(tk0_vec, 0.90, na.rm = TRUE),
      t_k0_p95  = quantile(tk0_vec, 0.95, na.rm = TRUE),
      t_k0_p99  = quantile(tk0_vec, 0.99, na.rm = TRUE),
      t_inter_p90 = quantile(tinter_vec, 0.90, na.rm = TRUE),
      t_inter_p95 = quantile(tinter_vec, 0.95, na.rm = TRUE),
      t_inter_p99 = quantile(tinter_vec, 0.99, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
    
    results_summary[[v]] <- res_row
    cat("Done.\n")
  }
  
  stopCluster(cl)
  
  final_df <- do.call(rbind, results_summary)
  if (is.null(out_csv)) {
    out_csv <- sprintf("output/US/S50_SECTION31_IMOLS/csv/cmpr_custom_critical_values_N%d.csv", N_sim)
  }
  
  dir.create(dirname(out_csv), recursive = TRUE, showWarnings = FALSE)
  
  write.csv(final_df, out_csv, row.names = FALSE)
  cat(sprintf("\nSuccessfully saved simulation results to: %s\n", out_csv))
  print(final_df)
}

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 2) {
  nsim <- as.integer(args[1])
  out_file <- args[2]
  run_cmpr_simulation_suite(N_sim = nsim, T_obs = 94, out_csv = out_file)
} else if (length(args) == 1) {
  nsim <- as.integer(args[1])
  run_cmpr_simulation_suite(N_sim = nsim, T_obs = 94)
} else {
  run_cmpr_simulation_suite(N_sim = 100, T_obs = 94)
}
