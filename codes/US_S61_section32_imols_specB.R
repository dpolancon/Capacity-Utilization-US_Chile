#!/usr/bin/env Rscript

# US_S61_section32_imols_specB.R
# ---------------------------------------------------------------------------
# Section 3.2 IM-OLS Cointegration Estimation Matrix (Specification B)
#
# Methodology: Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS
# - Disaggregated Capital Stocks: k_NRC (structures) and kappa (mechanization gap)
# - FWL Orthogonalization for all interaction terms
# - Two-Pass Endogenous Bai-Perron structural break audit
# - Standard Wage Pressure (Set 1) vs Effective Wage Pressure (Set 2 with (1-iota) toggle)
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(strucchange)
  library(dplyr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

# Source custom CMPR estimators and diagnostic tools
source(file.path(repo_root, ".agents", "skills", "cpr-im-ols", "scripts", "cpr_imols_estimator.R"))
source(file.path(repo_root, "codes", "COMMON_cointegration_stability_tests.R"))
source(file.path(repo_root, "codes", "COMMON_VW_fixedb_critical_values.R"))

f_in <- file.path(repo_root, "output", "gpim_specB_components_long.csv")

out_dir <- file.path(repo_root, "output", "US", "S61_SECTION32_IMOLS")
csv_dir <- file.path(out_dir, "csv")
rds_dir <- file.path(out_dir, "rds")
rep_dir <- file.path(repo_root, "reports", "US_Section32_IMOLS_Results")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rep_dir, recursive = TRUE, showWarnings = FALSE)

csv_out <- file.path(csv_dir, "s61_section32_results.csv")
rds_out <- file.path(rds_dir, "s61_fitted_models.rds")

cat("========================================================================\n")
cat("S61: Section 3.2 IM-OLS Specification B Estimation Engine (1929-2024)\n")
cat("========================================================================\n")

df <- read.csv(f_in, stringsAsFactors = FALSE)
df <- df[df$year >= 1929 & df$year <= 2024, ]
df <- df[order(df$year), ]

df$iota_t    <- df$IPP_share_capital_plus_IPP
df$iota_lag1 <- dplyr::lag(df$iota_t, 1L)
df$kappa_t   <- df$tau_real
df$p_kappa   <- df$p_rel

req_cols <- c("y_t", "k_NRC", "kappa_t", "p_kappa", "omega_NFC_GVA_lag1", 
              "omega_ST_Tier1_NVA_lag1", "iota_lag1")
df_clean <- df[complete.cases(df[, req_cols]), ]

cat(sprintf("Sample Window: %d - %d (N = %d observations)\n", 
            min(df_clean$year), max(df_clean$year), nrow(df_clean)))

safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  val[1]
}

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

fwl_orthogonalize <- function(inter_raw, aux_df) {
  df_mod <- data.frame(inter_raw = inter_raw)
  df_mod <- cbind(df_mod, aux_df)
  fit_aux <- lm(inter_raw ~ . - 1, data = df_mod)
  return(fit_aux$residuals)
}

run_s61_model <- function(df_data, y_var, tax_key, w_var_lag, set_id, model_id, wage_lbl, break_mode = "Yes") {
  y     <- df_data[[y_var]]
  kn    <- df_data$k_NRC - df_data$k_NRC[1]
  kp    <- df_data$kappa_t - df_data$kappa_t[1]
  pk    <- df_data$p_kappa - df_data$p_kappa[1]
  w     <- df_data[[w_var_lag]]
  w_c   <- w - w[1]
  
  if (set_id == "Set_1") {
    inter_raw_1 <- kp * w_c
  } else {
    iota <- df_data$iota_lag1
    C_idx <- w * (1 - iota)
    C_idx_c <- C_idx - C_idx[1]
    inter_raw_1 <- kp * C_idx_c
  }
  inter_raw_2 <- kp * pk
  
  deter_base <- matrix(1, nrow = length(y), ncol = 1)
  colnames(deter_base) <- "const"
  
  # Base Orthogonalization Space
  if (tax_key == "B1") {
    X_mat_base  <- cbind(k_NRC = kn, kappa = kp)
    X_base_base <- cbind(k_NRC = kn, kappa = kp)
  } else if (tax_key %in% c("B3", "B3e")) {
    aux_b <- data.frame(k_NRC = kn, kappa = kp, const = 1)
    o1 <- fwl_orthogonalize(inter_raw_1, aux_b)
    o2 <- fwl_orthogonalize(inter_raw_2, aux_b)
    X_mat_base  <- cbind(k_NRC = kn, kappa = kp, inter_w = o1, inter_p = o2)
    X_base_base <- cbind(k_NRC = kn, kappa = kp)
  } else if (tax_key %in% c("B4", "B4e")) {
    aux_b <- data.frame(k_NRC = kn, const = 1)
    o1 <- fwl_orthogonalize(inter_raw_1, aux_b)
    o2 <- fwl_orthogonalize(inter_raw_2, aux_b)
    X_mat_base  <- cbind(k_NRC = kn, inter_w = o1, inter_p = o2)
    X_base_base <- cbind(k_NRC = kn)
  }
  
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
      
      # Re-FWL with step dummies
      if (tax_key == "B1") {
        X_mat_full <- X_mat_base
      } else if (tax_key %in% c("B3", "B3e")) {
        aux_f <- as.data.frame(cbind(k_NRC = kn, kappa = kp, deter_full))
        o1_f <- fwl_orthogonalize(inter_raw_1, aux_f)
        o2_f <- fwl_orthogonalize(inter_raw_2, aux_f)
        X_mat_full <- cbind(k_NRC = kn, kappa = kp, inter_w = o1_f, inter_p = o2_f)
      } else if (tax_key %in% c("B4", "B4e")) {
        aux_f <- as.data.frame(cbind(k_NRC = kn, deter_full))
        o1_f <- fwl_orthogonalize(inter_raw_1, aux_f)
        o2_f <- fwl_orthogonalize(inter_raw_2, aux_f)
        X_mat_full <- cbind(k_NRC = kn, inter_w = o1_f, inter_p = o2_f)
      }
      
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
  
  p_stars_adf <- if (t_adf <= crit_val["p01"]) "$^{***}$" else if (t_adf <= crit_val["p05"]) "$^{**}$" else if (t_adf <= crit_val["p10"]) "$^{*}$" else ""
  
  shin_res <- calc_shin_lm_stat(fit, T_obs)
  C_shin <- shin_res$stat
  p_stars_shin <- shin_res$stars
  
  vw_res <- calc_vw_type2_stat(X_mat_final, y, deter_final, fit, x_base = X_base_base)
  
  cor_X <- tryCatch(cor(X_mat_final), error = function(e) NULL)
  vif_vals <- tryCatch({
    diag(solve(cor_X))
  }, error = function(e) rep(NA, ncol(X_mat_final)))
  names(vif_vals) <- colnames(X_mat_final)
  
  coefs <- as.vector(fit$theta)
  sds   <- as.vector(fit$sd.theta)
  nms   <- names(fit$theta)
  d_k   <- ncol(deter_final)
  
  # Map parameters
  alpha_est <- coefs[1]; alpha_sd <- sds[1]
  
  get_param <- function(p_name) {
    if (p_name %in% colnames(X_mat_final)) {
      idx <- d_k + match(p_name, colnames(X_mat_final))
      return(c(est = coefs[idx], sd = sds[idx], vif = vif_vals[p_name]))
    }
    return(c(est = NA, sd = NA, vif = NA))
  }
  
  p_kn <- get_param("k_NRC")
  p_kp <- get_param("kappa")
  p_iw <- get_param("inter_w")
  p_ip <- get_param("inter_p")
  
  fitted_store[[model_id]] <<- list(
    Model_ID    = model_id,
    Spec_Set    = set_id,
    Wage_Label  = wage_lbl,
    Taxonomy    = tax_key,
    years       = df_data$year,
    y           = y,
    X_mat       = X_mat_final,
    deter       = deter_final,
    fit         = fit,
    u_plus      = u,
    b_hat       = safe_scalar(vw_res$b_hat),
    k_reg       = safe_scalar(vw_res$k_reg),
    T_obs       = T_obs,
    Break_Years = break_years_str,
    Shin_stat   = safe_scalar(C_shin),
    omega_u_v   = safe_scalar(fit$omega.u.v)
  )

  data.frame(
    Model_ID     = model_id,
    Spec_Set     = set_id,
    Taxonomy     = tax_key,
    Wage_Label   = wage_lbl,
    Break_Mode   = break_mode,
    Break_Years  = break_years_str,
    Alpha_Est    = safe_scalar(alpha_est),
    Alpha_SD     = safe_scalar(alpha_sd),
    Theta_kn_Est = safe_scalar(p_kn["est"]),
    Theta_kn_SD  = safe_scalar(p_kn["sd"]),
    VIF_kn       = safe_scalar(p_kn["vif.k_NRC"]),
    Theta_kp_Est = safe_scalar(p_kp["est"]),
    Theta_kp_SD  = safe_scalar(p_kp["sd"]),
    VIF_kp       = safe_scalar(p_kp["vif.kappa"]),
    Theta_iw_Est = safe_scalar(p_iw["est"]),
    Theta_iw_SD  = safe_scalar(p_iw["sd"]),
    VIF_iw       = safe_scalar(p_iw["vif.inter_w"]),
    Theta_ip_Est = safe_scalar(p_ip["est"]),
    Theta_ip_SD  = safe_scalar(p_ip["sd"]),
    VIF_ip       = safe_scalar(p_ip["vif.inter_p"]),
    t_ADF        = safe_scalar(t_adf),
    ADF_Stars    = p_stars_adf,
    Shin_LM      = safe_scalar(C_shin),
    Shin_Stars   = p_stars_shin,
    VW_Type2     = safe_scalar(vw_res$stat),
    VW_Stars     = safe_scalar(vw_res$stars, ""),
    Bandwidth_b  = safe_scalar(vw_res$b_hat),
    Sample_T     = T_obs,
    stringsAsFactors = FALSE
  )
}

# Run Specifications Matrix
results_list <- list()
m_idx <- 1

wage_permutations <- list(
  c(var = "omega_NFC_GVA_lag1",      label = "NFC GVA Baseline"),
  c(var = "omega_NFC_NVA_lag1",      label = "NFC NVA Baseline"),
  c(var = "omega_ST_Tier1_GVA_lag1", label = "Shaikh-Tonak Tier 1 (GVA)"),
  c(var = "omega_ST_Tier1_NVA_lag1", label = "Shaikh-Tonak Tier 1 (NVA)"),
  c(var = "omega_ST_Tier2_GVA_lag1", label = "Shaikh-Tonak Tier 2 (GVA Super)"),
  c(var = "omega_ST_Tier2_NVA_lag1", label = "Shaikh-Tonak Tier 2 (NVA Super)")
)

# Loop over Set 1 (Standard) and Set 2 (Effective (1-iota))
for (set_type in c("Set_1", "Set_2")) {
  spec_base <- if (set_type == "Set_1") "B3" else "B3e"
  for (wp in wage_permutations) {
    w_var <- wp["var"]
    w_lbl <- wp["label"]
    for (b_mode in c("No", "Yes")) {
      m_id <- sprintf("M2.%d%s", m_idx, if (b_mode == "No") "a" else "b")
      results_list[[m_idx]] <- run_s61_model(df_clean, "y_t", spec_base, w_var, set_type, m_id, w_lbl, b_mode)
      m_idx <- m_idx + 1
    }
  }
}

res_df <- do.call(rbind, results_list)

write.csv(res_df, csv_out, row.names = FALSE)
saveRDS(fitted_store, rds_out)

cat(sprintf("Successfully estimated %d models for Section 3.2 Spec B.\n", nrow(res_df)))
cat("Saved results to:", csv_out, "\n")
