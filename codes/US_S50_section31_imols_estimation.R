#!/usr/bin/env Rscript

# US_S50_section31_imols_estimation.R
# ---------------------------------------------------------------------------
# Section 3.1 IM-OLS Estimation: U.S. NFC Transformation Elasticity (Aggregate Capital)
#
# Methodology: Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS (Vogelsang et al. 2024)
# - Aggregate Capital: Private Core Capital (k_cap = log(K_ME + K_NRC))
# - Demoted K_cap_GT to mirror Section 3.2 focus on primary private capital aggregate
# - Evaluates 8 nominal wage share measures (4 GVA-basis & 4 NVA-basis)
# - FWL Orthogonalization for all interaction terms
# - Two-Pass Endogenous Bai-Perron structural break audit
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(strucchange)
  library(dplyr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

# Source custom CMPR estimator
source(file.path(repo_root, ".agents", "skills", "cpr-im-ols", "scripts", "cpr_imols_estimator.R"))
source(file.path(repo_root, "codes", "COMMON_cointegration_stability_tests.R"))
source(file.path(repo_root, "codes", "COMMON_VW_fixedb_critical_values.R"))

input_csv <- file.path(repo_root, "output", "gpim_specB_components_long.csv")
if (!file.exists(input_csv)) {
  input_csv <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data", "s41_extended_capital_panel.csv")
}

out_dir <- file.path(repo_root, "output", "US", "S50_SECTION31_IMOLS")
csv_dir <- file.path(out_dir, "csv")
rds_dir <- file.path(out_dir, "rds")
rep_dir <- file.path(repo_root, "reports", "US_Section31_IMOLS_Results")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rep_dir, recursive = TRUE, showWarnings = FALSE)

csv_out <- file.path(csv_dir, "s50_section31_results.csv")
rds_out <- file.path(rds_dir, "s50_fitted_models.rds")

cat("========================================================================\n")
cat("S50: Section 3.1 Aggregate Capital IM-OLS Estimation Engine (1929-2024)\n")
cat("========================================================================\n")

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[df$year >= 1929 & df$year <= 2024, ]
df <- df[order(df$year), ]

df$iota_t    <- df$IPP_share_capital_plus_IPP
df$iota_lag1 <- dplyr::lag(df$iota_t, 1L)

wage_cols <- c(
  "omega_NFC_GVA_lag1", "omega_CORP_GVA_lag1", "omega_ST_Tier1_GVA_lag1", "omega_ST_Tier2_GVA_lag1",
  "omega_NFC_NVA_lag1", "omega_CORP_NVA_lag1", "omega_ST_Tier1_NVA_lag1", "omega_ST_Tier2_NVA_lag1"
)

req_cols <- c("y_t", "k_cap", wage_cols, "iota_lag1")
df_clean <- df[complete.cases(df[, req_cols]), ]

cat(sprintf("Sample Window: %d - %d (N = %d observations)\n", 
            min(df_clean$year), max(df_clean$year), nrow(df_clean)))

safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  val[1]
}

# MacKinnon (2010) critical values for EG-ADF
cv_adf <- function(m) {
  tab <- list(
    `2` = c(p01 = -3.90, p05 = -3.34, p10 = -3.04),
    `3` = c(p01 = -4.29, p05 = -3.74, p10 = -3.45),
    `4` = c(p01 = -4.64, p05 = -4.10, p10 = -3.81),
    `5` = c(p01 = -4.96, p05 = -4.42, p10 = -4.13)
  )
  tab[[as.character(min(max(m, 2), 5))]]
}

fitted_store <- list()

# Helper for FWL Orthogonalization
fwl_orthogonalize <- function(inter_raw, k_vec, deter_mat) {
  aux_df <- data.frame(inter_raw = inter_raw, k = k_vec)
  if (ncol(deter_mat) > 0) {
    aux_df <- cbind(aux_df, deter_mat)
  }
  fit_aux <- lm(inter_raw ~ . - 1, data = aux_df)
  return(fit_aux$residuals)
}

run_s50_model <- function(df_data, y_var, k_var, w_var_lag, set_id, model_id, wage_lbl, k_lbl, break_mode = "Yes") {
  y <- df_data[[y_var]]
  k <- df_data[[k_var]]
  w <- df_data[[w_var_lag]]
  w_c <- w - w[1]
  
  if (set_id == "Set_1") {
    inter_raw <- k * w_c
  } else {
    iota <- df_data[["iota_lag1"]]
    C_index <- w * (1 - iota)
    C_index_c <- C_index - C_index[1]
    inter_raw <- k * C_index_c
  }
  
  deter_base <- matrix(1, nrow = length(y), ncol = 1)
  colnames(deter_base) <- "const"
  
  # PASS 1: Base estimation
  inter_ortho_base <- fwl_orthogonalize(inter_raw, k, deter_base)
  
  X_mat_base <- cbind(k_cap = k, k_x_omega = inter_ortho_base)
  X_base_base <- cbind(k_cap = k)
  
  fit_base <- cointRegIM_CMPR(x = X_mat_base, y = y, deter = deter_base, x_base = X_base_base, selector = c(1, 2), kernel = "ba", bandwidth = "nw")
  
  break_years_str <- "None"
  if (break_mode == "Yes") {
    u_base <- fit_base$u.plus
    bp_res <- tryCatch({
      strucchange::breakpoints(u_base ~ 1, h = 0.15)
    }, error = function(e) NULL)
    
    if (!is.null(bp_res) && !is.null(bp_res$breakpoints) && !all(is.na(bp_res$breakpoints))) {
      bp_idx <- bp_res$breakpoints
      bp_years <- df_data$year[bp_idx]
      
      deter_full <- deter_base
      for (byr in bp_years) {
        step_dummy <- ifelse(df_data$year >= byr, 1, 0)
        deter_full <- cbind(deter_full, step_dummy)
        colnames(deter_full)[ncol(deter_full)] <- paste0("D", byr)
      }
      break_years_str <- paste(bp_years, collapse = ", ")
      
      # PASS 2: Re-FWL and Re-Estimate
      inter_ortho_full <- fwl_orthogonalize(inter_raw, k, deter_full)
      X_mat_full <- cbind(k_cap = k, k_x_omega = inter_ortho_full)
      
      fit <- tryCatch({
        cointRegIM_CMPR(x = X_mat_full, y = y, deter = deter_full, x_base = X_base_base, selector = c(1, 2), kernel = "ba", bandwidth = "nw")
      }, error = function(e) fit_base)
      
      X_mat_final <- X_mat_full
      deter_final <- deter_full
    } else {
      fit <- fit_base
      X_mat_final <- X_mat_base
      deter_final <- deter_base
    }
  } else {
    fit <- fit_base
    X_mat_final <- X_mat_base
    deter_final <- deter_base
  }
  
  u <- fit$u.plus
  u_level <- fit$residuals
  T_obs <- length(u)
  
  m_vars <- ncol(X_mat_final) + 1
  crit_val <- cv_adf(m_vars)
  adf_res <- adf_t_augmented(u_level, max_lag = 8L, ic = "aic")
  t_adf <- as.numeric(adf_res)
  adf_lag <- attr(adf_res, "lag")
  p_stars_adf <- if (t_adf <= crit_val["p01"]) "$^{***}$" else if (t_adf <= crit_val["p05"]) "$^{**}$" else if (t_adf <= crit_val["p10"]) "$^{*}$" else ""
  
  shin_res <- calc_shin_lm_stat(fit, T_obs)
  C_shin <- shin_res$stat
  p_stars_shin <- shin_res$stars
  
  vw_res <- calc_vw_type2_stat(X_mat_final, y, deter_final, fit, x_base = X_base_base)
  
  Sy <- cumsum(y)
  res_sum <- fit$u.plus2
  if (is.null(res_sum)) res_sum <- fit$residuals
  r2_sum <- if (!is.null(res_sum)) max(0, 1 - (sum(res_sum^2) / sum((Sy - mean(Sy))^2))) else NA
  
  cor_X <- tryCatch(cor(X_mat_final), error = function(e) NULL)
  vif_vals <- tryCatch({
    diag(solve(cor_X))
  }, error = function(e) rep(NA, ncol(X_mat_final)))
  names(vif_vals) <- colnames(X_mat_final)
  
  coefs  <- as.vector(fit$theta)
  sds    <- as.vector(fit$sd.theta)
  nms    <- names(fit$theta)
  
  d_k <- ncol(deter_final)
  b_idx <- d_k + 1  # k_cap
  d_idx <- d_k + 2  # interaction
  
  dummy_coefs_str <- ""
  dummy_sds_str   <- ""
  dummy_names_str <- ""
  if (d_k > 1) {
    d_coefs <- coefs[2:d_k]
    d_sds   <- sds[2:d_k]
    d_nms   <- nms[2:d_k]
    dummy_coefs_str <- paste(sprintf("%.6f", d_coefs), collapse = "|")
    dummy_sds_str   <- paste(sprintf("%.6f", d_sds), collapse = "|")
    dummy_names_str <- paste(d_nms, collapse = "|")
  }
  
  fitted_store[[model_id]] <<- list(
    Model_ID       = model_id,
    Spec_Set       = set_id,
    Wage_Label     = wage_lbl,
    Capital_Label  = k_lbl,
    years          = df_data$year,
    y              = y,
    X_mat          = X_mat_final,
    deter          = deter_final,
    fit            = fit,
    u_plus         = u,
    b_hat          = safe_scalar(vw_res$b_hat),
    k_reg          = safe_scalar(vw_res$k_reg),
    T_obs          = T_obs,
    Break_Years    = break_years_str,
    Shin_stat      = safe_scalar(C_shin),
    omega_u_v      = safe_scalar(fit$omega.u.v)
  )

  data.frame(
    Model_ID = model_id,
    Spec_Set = set_id,
    Wage_Label = wage_lbl,
    Capital_Label = k_lbl,
    T_obs = T_obs,
    alpha = safe_scalar(coefs[1]),
    alpha_sd = safe_scalar(sds[1]),
    dummy_names = dummy_names_str,
    dummy_coefs = dummy_coefs_str,
    dummy_sds = dummy_sds_str,
    theta_0 = safe_scalar(coefs[b_idx]),
    theta_0_sd = safe_scalar(sds[b_idx]),
    phi_w = NA,
    phi_w_sd = NA,
    gam_c = NA,
    gam_c_sd = NA,
    theta_1 = safe_scalar(coefs[d_idx]),
    theta_1_sd = safe_scalar(sds[d_idx]),
    VIF_k = safe_scalar(vif_vals[1]),
    VIF_w = NA,
    VIF_c = NA,
    VIF_inter = safe_scalar(vif_vals[2]),
    R2_sum = safe_scalar(r2_sum),
    EG_ADF_stat = safe_scalar(t_adf),
    EG_ADF_stars = safe_scalar(p_stars_adf, default = ""),
    EG_ADF_lag = safe_scalar(adf_lag),
    Shin_stat = safe_scalar(C_shin),
    Shin_stars = safe_scalar(p_stars_shin, default = ""),
    VW_stat = safe_scalar(vw_res$stat),
    VW_stars = safe_scalar(vw_res$stars, default = ""),
    K_Reg = safe_scalar(vw_res$k_reg),
    B_Hat = safe_scalar(vw_res$b_hat),
    Break_Years = break_years_str,
    stringsAsFactors = FALSE
  )
}

results_list <- list()

wage_config <- list(
  NFC_GVA      = list(col = "omega_NFC_GVA_lag1",      label = "Baseline NFC GVA"),
  CORP_GVA     = list(col = "omega_CORP_GVA_lag1",     label = "Corporate GVA"),
  ST_Tier1_GVA = list(col = "omega_ST_Tier1_GVA_lag1", label = "Shaikh-Tonak Tier 1 GVA"),
  ST_Tier2_GVA = list(col = "omega_ST_Tier2_GVA_lag1", label = "Shaikh-Tonak Tier 2 GVA"),
  NFC_NVA      = list(col = "omega_NFC_NVA_lag1",      label = "Baseline NFC NVA"),
  CORP_NVA     = list(col = "omega_CORP_NVA_lag1",     label = "Corporate NVA (Finance-Adjusted)"),
  ST_Tier1_NVA = list(col = "omega_ST_Tier1_NVA_lag1", label = "Shaikh-Tonak Tier 1 NVA"),
  ST_Tier2_NVA = list(col = "omega_ST_Tier2_NVA_lag1", label = "Shaikh-Tonak Tier 2 NVA")
)

# Set 1 Models (M1.1a through M1.8b)
m_counter <- 1
for (w_key in names(wage_config)) {
  w_info <- wage_config[[w_key]]
  m_id_base <- sprintf("M1.%d", m_counter)
  
  for (b_mode in c("No", "Yes")) {
    m_id <- paste0(m_id_base, if (b_mode == "Yes") "b" else "a")
    res <- run_s50_model(
      df_data = df_clean,
      y_var = "y_t",
      k_var = "k_cap",
      w_var_lag = w_info$col,
      set_id = "Set_1",
      model_id = m_id,
      wage_lbl = w_info$label,
      k_lbl = "Private Core (ME+NRC)",
      break_mode = b_mode
    )
    res$Break_Mode <- b_mode
    res$Base_Model_ID <- m_id_base
    results_list[[length(results_list) + 1]] <- res
  }
  m_counter <- m_counter + 1
}

# Set 2 Models (M2.1a through M2.8b)
m_counter <- 1
for (w_key in names(wage_config)) {
  w_info <- wage_config[[w_key]]
  m_id_base <- sprintf("M2.%d", m_counter)
  
  for (b_mode in c("No", "Yes")) {
    m_id <- paste0(m_id_base, if (b_mode == "Yes") "b" else "a")
    res <- run_s50_model(
      df_data = df_clean,
      y_var = "y_t",
      k_var = "k_cap",
      w_var_lag = w_info$col,
      set_id = "Set_2",
      model_id = m_id,
      wage_lbl = w_info$label,
      k_lbl = "Private Core (ME+NRC)",
      break_mode = b_mode
    )
    res$Break_Mode <- b_mode
    res$Base_Model_ID <- m_id_base
    results_list[[length(results_list) + 1]] <- res
  }
  m_counter <- m_counter + 1
}

res_df <- do.call(rbind, results_list)
write.csv(res_df, csv_out, row.names = FALSE)
cat(sprintf("Saved %d estimation results to %s\n", nrow(res_df), csv_out))
saveRDS(fitted_store, rds_out)
cat(sprintf("Saved %d fitted model objects to %s\n", length(fitted_store), rds_out))

cat("Section 3.1 estimation pipeline finished cleanly.\n")
