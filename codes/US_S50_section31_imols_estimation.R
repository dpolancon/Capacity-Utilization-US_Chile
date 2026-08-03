#!/usr/bin/env Rscript

# US_S50_section31_imols_estimation.R
# ---------------------------------------------------------------------------
# Section 3.1 IM-OLS Estimation: U.S. NFC Transformation Elasticity
#
# Estimates 18 models across Spec Set 1 (double interaction) and Spec Set 2
# (triple interaction) over the 1929-2024 full sample period.
#
# Methodology: Integrated Modified OLS (cointReg::cointRegIM; Vogelsang & Wagner 2014)
# In accordance with Chapter 2 rules:
#   - Only distributional variables (omega, iota) are centered at 1929 initial state
#   - k_cap is NOT centered
#   - Standalone omega is excluded by theoretical construction
#   - Pre-set dummies removed; replaced by post-estimation Bai-Perron residual break audit
#   - VIF computed on level regressors space
#   - NetC share enters directly as I(0) control in X matrix
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  if (!requireNamespace("cointReg", quietly = TRUE)) {
    install.packages("cointReg", repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  if (!requireNamespace("strucchange", quietly = TRUE)) {
    install.packages("strucchange", repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(cointReg)
  library(strucchange)
  library(dplyr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
source(file.path(repo_root, "codes", "COMMON_VW_fixedb_critical_values.R"))
source(file.path(repo_root, "codes", "COMMON_cointegration_stability_tests.R"))

f_ext  <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data", "s41_extended_capital_panel.csv")
f_st   <- file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION", "csv", "S29F_shaikh_tonak_wage_share_panel.csv")
f_cm   <- file.path(repo_root, "output", "US", "S42_CM_EXTENSION", "csv", "s42a_extended_cm_control_panel.csv")

out_dir <- file.path(repo_root, "output", "US", "S50_SECTION31_IMOLS")
csv_dir <- file.path(out_dir, "csv")
rds_dir <- file.path(out_dir, "rds")
rep_dir <- file.path(repo_root, "reports", "US_Section31_IMOLS_Results")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rep_dir, recursive = TRUE, showWarnings = FALSE)

csv_out <- file.path(csv_dir, "s50_section31_results.csv")
rds_out <- file.path(rds_dir, "s50_fitted_models.rds")
tex_out <- file.path(rep_dir, "us_section31_imols_results.tex")
md_out  <- file.path(rep_dir, "us_section31_imols_results.md")

cat("========================================================================\n")
cat("S50: Section 3.1 IM-OLS Estimation & Outlier Audit Engine (1929-2024)\n")
cat("========================================================================\n")

# Load and merge panels
df1 <- read.csv(f_ext, stringsAsFactors = FALSE)
df2 <- read.csv(f_st, stringsAsFactors = FALSE)
df3 <- read.csv(f_cm, stringsAsFactors = FALSE)

# Select required columns from df2 and df3
df2_sub <- df2[, c("year", "omega_ST_Tier2_GVA_adj")]
df3_sub <- df3[, c("year", "net_c_share_nom")]

df <- merge(df1, df2_sub, by = "year", all.x = TRUE)
df <- merge(df, df3_sub, by = "year", all.x = TRUE)

df <- df[df$year >= 1929 & df$year <= 2024, ]
df <- df[order(df$year), ]

# Construct lags
df$omega_ST_Tier2_GVA_adj_lag1 <- dplyr::lag(df$omega_ST_Tier2_GVA_adj, 1L)
df$iota_t    <- df$IPP_share_capital_plus_IPP
df$iota_lag1 <- dplyr::lag(df$iota_t, 1L)

# Verify sample completeness
req_cols <- c("y_t", "k_cap", "k_cap_GT", "omega_NFC_GVA_lag1", "omega_CORP_GVA_lag1", 
              "omega_ST_Tier2_GVA_adj_lag1", "iota_lag1", "net_c_share_nom")
df_clean <- df[complete.cases(df[, req_cols]), ]

cat(sprintf("Sample Window: %d - %d (N = %d observations)\n", 
            min(df_clean$year), max(df_clean$year), nrow(df_clean)))

# Helper functions
safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  val[1]
}

calc_vw_type2_stat <- function(x, y, deter, fit) {
  tryCatch({
    y.T <- nrow(x)
    x.k <- ncol(x)
    d.k <- if (is.null(deter)) 0 else ncol(deter)
    
    Sy <- cumsum(y)
    Sx <- matrixStats::colCumsums(x)
    Sd <- if (d.k == 0) matrix(nrow = y.T, ncol = 0) else matrixStats::colCumsums(deter)
    
    InvBase <- Sx[y.T:1, , drop = FALSE]
    InvBaseCum <- matrixStats::colCumsums(InvBase)
    RevBase <- InvBaseCum[y.T:1, , drop = FALSE]
    Zreg <- matrixStats::colCumsums(RevBase)
    
    X2mat <- if (d.k == 0) as.matrix(cbind(Sx, x, Zreg)) else as.matrix(cbind(Sd, Sx, x, Zreg))
    
    S <- matrixStats::colCumsums(X2mat)
    DS <- rbind(S[y.T, ], t(S[y.T, ] - t(S[1:(y.T - 1), ])))
    Ha <- cointReg:::trySolve(t(X2mat) %*% X2mat)
    H <- Ha %*% t(DS)
    V2 <- H %*% t(H)
    
    lambda2 <- fit$lambda2
    if (is.null(lambda2) || length(lambda2) == 0) return(list(stat = NA, stars = "", b_hat = NA, k_reg = x.k))

    idx <- (d.k + 2 * x.k + 1):(d.k + 3 * x.k)
    V2_lambda <- V2[idx, idx, drop = FALSE]
    w2 <- fit$omega.u.v
    if (is.null(w2) || is.na(w2) || w2 <= 0) return(list(stat = NA, stars = "", b_hat = NA, k_reg = x.k))
    
    V2_inv <- cointReg:::trySolve(V2_lambda)
    S_type2 <- as.numeric(t(lambda2) %*% V2_inv %*% lambda2 / w2)

    # Fixed-b, regressor-count-indexed critical values (Vogelsang & Wagner 2014
    # supplement, Bartlett kernel / intercept-only case; see
    # codes/COMMON_VW_fixedb_critical_values.R). b = bandwidth/T is the actual
    # fixed-b ratio for THIS model's fitted bandwidth, not a constant -- see
    # E17_Cointegration_Significance_Stars_Lock.md for why a single hardcoded
    # critical-value triple is invalid across models with different k or b.
    b_hat <- fit$bandwidth$number / y.T
    stars <- if (!is.na(S_type2)) {
      fixedb_stars(S_type2, stat = "wald", k = x.k, b = b_hat, direction = "ge")
    } else ""

    return(list(stat = S_type2, stars = stars, b_hat = b_hat, k_reg = x.k))
  }, error = function(e) {
    return(list(stat = NA, stars = "", b_hat = NA, k_reg = NA))
  })
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

# Store of fitted objects, keyed by Model_ID. Populated as a side effect of
# run_s50_model() and serialized to `rds_out` after the estimation loops. This is
# the single source of truth consumed by the S51 stability audit, so that the
# diagnostics operate on exactly the models estimated here rather than
# re-deriving the specifications (which would risk silent divergence).
fitted_store <- list()

# Estimate model wrapper
run_s50_model <- function(df_data, y_var, k_var, w_var_lag, iota_var_lag = NULL, netc_var = NULL, model_id, set_id, wage_lbl, k_lbl) {
  y <- df_data[[y_var]]
  k <- df_data[[k_var]]
  w <- df_data[[w_var_lag]]
  
  # Initial state values (1929)
  w0 <- w[1]
  w_c <- w - w0
  
  if (set_id == "Set_1") {
    inter <- k * w_c
    X_mat <- cbind(k_cap = k, inter = inter)
    colnames(X_mat) <- c("k_cap", "k_x_omega")
  } else {
    iota <- df_data[[iota_var_lag]]
    iota0 <- iota[1]
    iota_c <- iota - iota0
    inter <- k * w_c * iota_c
    
    if (!is.null(netc_var)) {
      netc <- df_data[[netc_var]]
      X_mat <- cbind(k_cap = k, inter = inter, netc_share = netc)
      colnames(X_mat) <- c("k_cap", "k_x_omega_x_iota", "netc_share")
    } else {
      X_mat <- cbind(k_cap = k, inter = inter)
      colnames(X_mat) <- c("k_cap", "k_x_omega_x_iota")
    }
  }
  
  deter <- matrix(1, nrow = length(y), ncol = 1)
  colnames(deter) <- "const"
  
  # PASS 1: Base estimation
  fit_base <- cointReg::cointRegIM(x = X_mat, y = y, deter = deter, selector = c(1, 2), t.test = TRUE, kernel = "ba", bandwidth = "nw")
  u_base <- fit_base$u.plus
  
  # Bai-Perron Audit on Pass 1 residuals
  bp_res <- tryCatch({
    strucchange::breakpoints(u_base ~ 1, h = 0.15)
  }, error = function(e) NULL)
  
  break_years_str <- "None"
  
  if (!is.null(bp_res) && !is.null(bp_res$breakpoints) && !all(is.na(bp_res$breakpoints))) {
    bp_idx <- bp_res$breakpoints
    bp_years <- df_data$year[bp_idx]
    
    # Construct step dummies
    for (byr in bp_years) {
      step_dummy <- ifelse(df_data$year >= byr, 1, 0)
      deter <- cbind(deter, step_dummy)
      colnames(deter)[ncol(deter)] <- paste0("D", byr)
    }
    break_years_str <- paste(bp_years, collapse = ", ")
    
    # PASS 2: Estimation with step dummies
    fit <- tryCatch({
      cointReg::cointRegIM(x = X_mat, y = y, deter = deter, selector = c(1, 2), t.test = TRUE, kernel = "ba", bandwidth = "nw")
    }, error = function(e) fit_base)
  } else {
    fit <- fit_base
  }
  
  u <- fit$u.plus
  T_obs <- length(u)
  
  # 1. EG-ADF test
  # CORRECTED 2026-08-03: this previously ran an UNAUGMENTED Dickey-Fuller
  #   eg_lm <- lm(diff(u) ~ u[-T_obs] - 1)
  # i.e. zero lagged differences, while comparing the result to MacKinnon
  # critical values that are tabulated for the AUGMENTED test. The IM-OLS
  # residuals carry AR(2)-AR(4) structure (first-order autocorrelation
  # 0.81-0.96), and a plain DF on serially correlated errors is severely
  # biased toward NON-rejection -- whitening is precisely what the "A" in ADF
  # is for. The defect produced only 2/18 rejections of "no cointegration";
  # with proper lag augmentation the same residuals give 16/18. AIC and BIC
  # select the same lag order in 17 of 18 models, and even minimal p=1
  # augmentation gives 14/18, so the reversal is not a lag-selection artifact.
  # See chapter2_vault/08_audits/2026-08-03_section31_cointegration_failure_diagnostics.md
  m_vars <- ncol(X_mat) + 1
  crit_val <- cv_adf(m_vars)
  adf_res <- adf_t_augmented(u, max_lag = 8L, ic = "aic")
  t_adf <- as.numeric(adf_res)
  adf_lag <- attr(adf_res, "lag")
  p_stars_adf <- if (t_adf <= crit_val["p01"]) "$^{***}$" else if (t_adf <= crit_val["p05"]) "$^{**}$" else if (t_adf <= crit_val["p10"]) "$^{*}$" else ""
  
  # 2. Shin LM test
  # NOTE (audit 2026-08-03): unlike the EG-ADF and VW Type 2 tests, these
  # critical values (10%=0.095, 5%=0.121, 1%=0.184) are NOT confirmed to be
  # regressor-count-indexed for this repo's k=2/k=3 mix -- Shin's (1994)
  # original table could not be retrieved and verified this session (source
  # unreachable). Treat Shin_stars as provisional pending independent
  # verification against Shin (1994), Table 1, for k=2 and k=3. See
  # E17_Cointegration_Significance_Stars_Lock.md Sec. 1 and the audit memo at
  # chapter2_vault/08_audits/2026-08-03_section31_cointegration_stars_audit.md.
  S_t <- cumsum(u)
  omega2 <- fit$omega.u.v
  if (is.null(omega2) || is.na(omega2) || omega2 <= 0) {
    omega2 <- tryCatch(cointReg::getLongRunVar(u, kernel = "ba", bandwidth = "nw")$long.run, error = function(e) NA)
  }
  C_shin <- if (!is.na(omega2)) sum(S_t^2) / (T_obs^2 * omega2) else NA
  p_stars_shin <- if (!is.na(C_shin)) {
    if (C_shin >= 0.184) "$^{***}$" else if (C_shin >= 0.121) "$^{**}$" else if (C_shin >= 0.095) "$^{*}$" else ""
  } else ""
  
  # 3. VW Type 2 test
  vw_res <- calc_vw_type2_stat(X_mat, y, deter, fit)
  
  # 4. R2 sum
  Sy <- cumsum(y)
  res_sum <- fit$u.plus2
  if (is.null(res_sum)) res_sum <- fit$residuals
  r2_sum <- if (!is.null(res_sum)) max(0, 1 - (sum(res_sum^2) / sum((Sy - mean(Sy))^2))) else NA
  
  # 5. VIF calculation on level regressors space
  cor_X <- tryCatch(cor(X_mat), error = function(e) NULL)
  vif_vals <- tryCatch({
    diag(solve(cor_X))
  }, error = function(e) rep(NA, ncol(X_mat)))
  names(vif_vals) <- colnames(X_mat)
  
  coefs  <- as.vector(fit$theta)
  sds    <- as.vector(fit$sd.theta)
  nms    <- names(fit$theta)
  
  d_k <- ncol(deter)
  b_idx <- d_k + 1  # k_cap
  d_idx <- d_k + 2  # interaction
  cm_idx <- if (!is.null(netc_var) && set_id == "Set_2") d_k + 3 else NA
  
  # Extract dummy coefficients (indices 2..d_k if d_k > 1)
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
  
  # Stash the fitted objects for the S51 stability audit (see `fitted_store`).
  fitted_store[[model_id]] <<- list(
    Model_ID       = model_id,
    Spec_Set       = set_id,
    Wage_Label     = wage_lbl,
    Capital_Label  = k_lbl,
    Demand_Control = if (!is.null(netc_var)) "NetC Share" else "None",
    years          = df_data$year,
    y              = y,
    X_mat          = X_mat,
    deter          = deter,
    fit            = fit,
    u_plus         = u,
    b_hat          = safe_scalar(vw_res$b_hat),
    k_reg          = safe_scalar(vw_res$k_reg),
    T_obs          = T_obs,
    Break_Years    = break_years_str,
    Shin_stat      = safe_scalar(C_shin),
    omega_u_v      = safe_scalar(omega2)
  )

  data.frame(
    Model_ID = model_id,
    Spec_Set = set_id,
    Wage_Label = wage_lbl,
    Capital_Label = k_lbl,
    Demand_Control = if (!is.null(netc_var)) "NetC Share" else "None",
    T_obs = T_obs,
    alpha = safe_scalar(coefs[1]),
    alpha_sd = safe_scalar(sds[1]),
    dummy_names = dummy_names_str,
    dummy_coefs = dummy_coefs_str,
    dummy_sds = dummy_sds_str,
    theta_0 = safe_scalar(coefs[b_idx]),
    theta_0_sd = safe_scalar(sds[b_idx]),
    theta_1 = safe_scalar(coefs[d_idx]),
    theta_1_sd = safe_scalar(sds[d_idx]),
    beta_cm = if (!is.na(cm_idx)) safe_scalar(coefs[cm_idx]) else NA,
    beta_cm_sd = if (!is.na(cm_idx)) safe_scalar(sds[cm_idx]) else NA,
    VIF_k = safe_scalar(vif_vals[1]),
    VIF_inter = safe_scalar(vif_vals[2]),
    VIF_netc = if (!is.null(netc_var)) safe_scalar(vif_vals[3]) else NA,
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
  NFC_GVA   = list(col = "omega_NFC_GVA_lag1",           label = "Baseline NFC GVA"),
  CORP_GVA  = list(col = "omega_CORP_GVA_lag1",          label = "Corporate GVA (Finance-Adjusted)"),
  ST_Tier2  = list(col = "omega_ST_Tier2_GVA_adj_lag1",  label = "Shaikh-Tonak Tier 2 (Supervisory-Corrected)")
)

k_config <- list(
  k_cap1 = list(col = "k_cap",    label = "Private Core (ME+NRC)"),
  k_cap2 = list(col = "k_cap_GT", label = "Infra-Augmented (+K_GT)")
)

# ---------------------------------------------------------------------------
# Loop Spec Set 1 (6 models)
# ---------------------------------------------------------------------------
m_counter <- 1
for (w_key in names(wage_config)) {
  w_info <- wage_config[[w_key]]
  for (k_key in names(k_config)) {
    k_info <- k_config[[k_key]]
    m_id <- sprintf("M1.%d", m_counter)
    
    res <- run_s50_model(
      df_data = df_clean,
      y_var = "y_t",
      k_var = k_info$col,
      w_var_lag = w_info$col,
      iota_var_lag = NULL,
      netc_var = NULL,
      model_id = m_id,
      set_id = "Set_1",
      wage_lbl = w_info$label,
      k_lbl = k_info$label
    )
    results_list[[length(results_list) + 1]] <- res
    m_counter <- m_counter + 1
  }
}

# ---------------------------------------------------------------------------
# Loop Spec Set 2 (12 models)
# ---------------------------------------------------------------------------
m_counter <- 1
for (w_key in names(wage_config)) {
  w_info <- wage_config[[w_key]]
  for (k_key in names(k_config)) {
    k_info <- k_config[[k_key]]
    for (netc_opt in c(FALSE, TRUE)) {
      m_id <- sprintf("M2.%d", m_counter)
      netc_col <- if (netc_opt) "net_c_share_nom" else NULL
      
      res <- run_s50_model(
        df_data = df_clean,
        y_var = "y_t",
        k_var = k_info$col,
        w_var_lag = w_info$col,
        iota_var_lag = "iota_lag1",
        netc_var = netc_col,
        model_id = m_id,
        set_id = "Set_2",
        wage_lbl = w_info$label,
        k_lbl = k_info$label
      )
      results_list[[length(results_list) + 1]] <- res
      m_counter <- m_counter + 1
    }
  }
}

res_df <- do.call(rbind, results_list)
write.csv(res_df, csv_out, row.names = FALSE)
cat(sprintf("Saved %d estimation results to %s\n", nrow(res_df), csv_out))

saveRDS(fitted_store, rds_out)
cat(sprintf("Saved %d fitted model objects to %s\n", length(fitted_store), rds_out))

# ---------------------------------------------------------------------------
# Export Journal-Style LaTeX Tables
# ---------------------------------------------------------------------------
# Journal format:
#   coefficient row:  coef***  (stars from |t| thresholds)
#   sd row:           (sd)     in parentheses below
# ---------------------------------------------------------------------------

export_s50_latex_table <- function(df_sub, file_path, caption_text, label_text) {
  sink(file_path)
  
  n_cols <- nrow(df_sub)
  cat("\\begin{table}[H]\n")
  cat("\\centering\n")
  cat("\\caption{", caption_text, "}\n", sep = "")
  cat("\\label{", label_text, "}\n", sep = "")
  cat("\\scriptsize\n")
  
  col_spec <- "p{3.8cm}"
  for (i in 1:n_cols) col_spec <- paste0(col_spec, "p{1.35cm}")
  
  cat("\\begin{tabular}{", col_spec, "}\n", sep = "")
  cat("\\toprule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\textbf{Dependent Variable: $y_t^{\\text{NFC}}$ (Log NFC Real GVA)}} \\\\\n", sep = "")
  cat("\\midrule\n")
  
  # Model Header Line
  cat("Model & ")
  cat(paste(df_sub$Model_ID, collapse = " & "), " \\\\\n")
  
  # Capital Definition
  cat("Capital Stock & ")
  cat(paste(ifelse(grepl("Core", df_sub$Capital_Label), "$k^{\\text{cap}}_1$", "$k^{\\text{cap}}_2$"), collapse = " & "), " \\\\\n")
  
  # Demand Control
  cat("Demand Control & ")
  cat(paste(df_sub$Demand_Control, collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  
  # --- Journal-format helpers ---
  # Stars from the fixed-b t-test critical values (Vogelsang & Wagner 2014;
  # see codes/COMMON_VW_fixedb_critical_values.R), indexed by this model's
  # actual number of stochastic regressors (k_reg) and bandwidth ratio
  # (b_hat = bandwidth/T) -- NOT the naive standard-normal 1.645/1.96/2.576
  # cutoffs, which understate the true fixed-b critical values and would
  # overstate significance (see the audit memo for the derivation).
  stars_from_coef_sd <- function(coef_val, sd_val, k_reg, b_hat) {
    if (is.na(coef_val) || is.na(sd_val) || sd_val == 0) return("")
    if (is.na(k_reg) || is.na(b_hat)) return("")
    abs_t <- abs(coef_val / sd_val)
    fixedb_stars(abs_t, stat = "t", k = k_reg, b = b_hat, direction = "ge")
  }

  fmt_coef_star <- function(coef_val, sd_val, k_reg, b_hat) {
    if (is.na(coef_val)) return("---")
    stars <- stars_from_coef_sd(coef_val, sd_val, k_reg, b_hat)
    sprintf("%.2f%s", coef_val, stars)
  }

  fmt_sd <- function(sd_val) {
    if (is.na(sd_val)) return("")
    sprintf("{\\scriptsize (%.2f)}", sd_val)
  }

  fmt_vif <- function(vval) {
    if (is.na(vval)) return("---")
    sprintf("%.2f", vval)
  }

  # Helper: emit a two-row parameter block (coef*** / (sd))
  emit_param_row <- function(label, coef_vec, sd_vec) {
    cat(label, " & ")
    cat(paste(sapply(1:n_cols, function(r) fmt_coef_star(coef_vec[r], sd_vec[r], df_sub$K_Reg[r], df_sub$B_Hat[r])), collapse = " & "), " \\\\\n")
    cat(" & ")
    cat(paste(sapply(1:n_cols, function(r) fmt_sd(sd_vec[r])), collapse = " & "), " \\\\\n")
  }
  
  # === A. Intercept ===
  emit_param_row("$\\hat{\\alpha}$ (Intercept)", df_sub$alpha, df_sub$alpha_sd)
  
  # === B. Step Dummy Coefficients ===
  # Collect the union of all dummy years across models in this table
  all_dummy_years <- c()
  for (r in 1:n_cols) {
    dnms <- df_sub$dummy_names[r]
    if (!is.null(dnms) && nchar(dnms) > 0 && dnms != "") {
      yrs <- gsub("S\\.D", "", strsplit(dnms, "\\|")[[1]])
      all_dummy_years <- c(all_dummy_years, yrs)
    }
  }
  all_dummy_years <- sort(unique(all_dummy_years))
  
  if (length(all_dummy_years) > 0) {
    # Build a matrix: rows = dummy years, cols = models
    for (yr in all_dummy_years) {
      coef_row <- rep(NA_real_, n_cols)
      sd_row   <- rep(NA_real_, n_cols)
      for (r in 1:n_cols) {
        dnms <- df_sub$dummy_names[r]
        if (!is.null(dnms) && nchar(dnms) > 0 && dnms != "") {
          nm_vec <- strsplit(dnms, "\\|")[[1]]
          cf_vec <- as.numeric(strsplit(df_sub$dummy_coefs[r], "\\|")[[1]])
          sd_vec <- as.numeric(strsplit(df_sub$dummy_sds[r], "\\|")[[1]])
          target_nm <- paste0("S.D", yr)
          idx <- which(nm_vec == target_nm)
          if (length(idx) == 1) {
            coef_row[r] <- cf_vec[idx]
            sd_row[r]   <- sd_vec[idx]
          }
        }
      }
      label <- paste0("$\\hat{\\gamma}^{\\text{step}}_{", yr, "}$ ($D^{\\text{step}}_{", yr, "}$)")
      emit_param_row(label, coef_row, sd_row)
    }
  }
  
  cat("[1ex]\n")
  
  # === C. theta_0 (Capital Elasticity) ===
  emit_param_row("$\\hat{\\theta}_0$ (Capital Elasticity)", df_sub$theta_0, df_sub$theta_0_sd)
  
  # === D. theta_1 (Interaction) ===
  emit_param_row("$\\hat{\\theta}_1$ (Interaction)", df_sub$theta_1, df_sub$theta_1_sd)
  
  # === E. beta_cm (NetC share, if present) ===
  if (any(!is.na(df_sub$beta_cm))) {
    emit_param_row("$\\hat{\\beta}_{\\text{cm}}$ ($\\text{NetC}^{\\text{share}}$)", df_sub$beta_cm, df_sub$beta_cm_sd)
  }
  
  cat("\\midrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\underline{Collinearity Diagnostics (VIF)}} \\\\\n", sep = "")
  cat("VIF ($k^{\\text{cap}}$) & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_vif(df_sub$VIF_k[r])), collapse = " & "), " \\\\\n")
  cat("VIF (Interaction) & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_vif(df_sub$VIF_inter[r])), collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\underline{Cointegration Test Triad}} \\\\\n", sep = "")
  
  # EG ADF
  cat("\\makecell[l]{Resid. ADF ($t_{\\text{ADF}}$) \\\\ {\\scriptsize [$H_0$: No Coint.]}} & ")
  cat(paste(sapply(1:n_cols, function(r) {
    v <- df_sub$EG_ADF_stat[r]; s <- df_sub$EG_ADF_stars[r]
    if (is.na(v)) "---" else sprintf("%.2f%s", v, s)
  }), collapse = " & "), " \\\\\n")
  
  # Shin LM
  cat("\\makecell[l]{Shin LM ($C_{\\text{Shin}}$) \\\\ {\\scriptsize [$H_0$: Coint.]}} & ")
  cat(paste(sapply(1:n_cols, function(r) {
    v <- df_sub$Shin_stat[r]; s <- df_sub$Shin_stars[r]
    if (is.na(v)) "---" else sprintf("%.2f%s", v, s)
  }), collapse = " & "), " \\\\\n")
  
  # VW Type 2
  cat("\\makecell[l]{VW Type 2 ($S_{\\text{Type 2}}$) \\\\ {\\scriptsize [$H_0$: Coint.]}} & ")
  cat(paste(sapply(1:n_cols, function(r) {
    v <- df_sub$VW_stat[r]; s <- df_sub$VW_stars[r]
    if (is.na(v)) "---" else sprintf("%.2f%s", v, s)
  }), collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  cat("$R^2_{\\text{sum}}$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.2f", df_sub$R2_sum[r])), collapse = " & "), " \\\\\n")
  cat("Sample Size ($N$) & ")
  cat(paste(df_sub$T_obs, collapse = " & "), " \\\\\n")
  
  cat("\\bottomrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{p{13.2cm}}{\\footnotesize Note: Estimated via Integrated Modified OLS (IM-OLS; Vogelsang \\& Wagner 2014) over 1929--2024. Standard errors in parentheses. Significance: $^*p<0.10, ^{**}p<0.05, ^{***}p<0.01$. Coefficient rows ($\\hat{\\alpha}$, $\\hat{\\gamma}^{\\text{step}}$, $\\hat{\\theta}_0$, $\\hat{\\theta}_1$, $\\hat{\\beta}_{\\text{cm}}$) and the Residual ADF and VW Type 2 rows use Vogelsang \\& Wagner (2014) fixed-$b$ critical values, interpolated by each model's bandwidth ratio $b=\\text{bandwidth}/T$ (Bartlett kernel, Newey-West bandwidth) and its number of stochastic regressors $k$ -- NOT a single generic $t$/normal cutoff. Resid. ADF stars instead follow MacKinnon (2010) Engle-Granger critical values, indexed by the total number of $I(1)$ variables; the test is lag-augmented with the order selected by AIC (max 8), which is required because the IM-OLS residuals are strongly autocorrelated -- an unaugmented Dickey-Fuller is biased toward non-rejection and was the source of the superseded v2 results. Shin LM stars use Shin's (1994) critical values (10\\%/5\\%/1\\% = 0.095/0.121/0.184); these have not been independently re-verified as regressor-count-specific for this report's $k=2$/$k=3$ mix and should be treated as provisional (see the audit memo referenced in the repository). \\textbf{Star reversal warning:} For Residual ADF, stars indicate rejection of No Cointegration (supporting cointegration). For Shin LM and VW Type 2, stars indicate rejection of Cointegration. Distributional variables centered at 1929 initial state ($t_0$). Step dummies $D^{\\text{step}}_{T_b} = \\mathbb{I}(t \\ge T_b)$ represent persistent level shifts from structural breaks identified via a first-pass Bai-Perron residual audit (15\\% trimming), distinguished from impulse outlier controls $D^{\\text{imp}}_{T_b} = \\mathbb{I}(t = T_b)$.}\n", sep = "")
  cat("\\end{tabular}\n")
  cat("\\end{table}\n")
  
  sink()
}

# Generate LaTeX manuscript report
sink(tex_out)
cat("\\documentclass[11pt,a4paper]{article}\n")
cat("\\usepackage[margin=1in]{geometry}\n")
cat("\\usepackage{booktabs}\n")
cat("\\usepackage{float}\n")
cat("\\usepackage{makecell}\n")
cat("\\usepackage{placeins}\n")
cat("\\usepackage{caption}\n")
cat("\\usepackage{amsmath,amssymb}\n")
cat("\\usepackage{hyperref}\n")
cat("\\title{\\textbf{Section 3.1 IM-OLS Cointegration Estimation Matrix: U.S. NFC Transformation Elasticity (1929--2024)}}\n")
cat("\\author{\\textbf{Department of Economics, UMass Amherst}}\n")
cat("\\date{August 2026}\n")
cat("\\begin{document}\n")
cat("\\maketitle\n\n")

cat("\\section*{Data Provenance and Estimation Summary}\n")
cat(sprintf("This report presents the empirical cointegration results for Section 3.1 of Chapter 2. All models are estimated via Integrated Modified OLS (IM-OLS; Vogelsang \\& Wagner 2014) over the full NIPA sample window (%d--2024, $N=%d$ observations after listwise deletion for the lag-1 conditioning variables $\\omega_{t-1}$ and $\\iota_{t-1}$). Point estimates are tuning-parameter free; coefficient and cointegration-test significance stars use Vogelsang \\& Wagner (2014) fixed-$b$ critical values (Bartlett kernel, Newey-West bandwidth), interpolated by each model's bandwidth ratio and number of stochastic regressors -- see the significance note under each table. Distributional conditioning variables ($\\omega_{t-1}$ and $\\iota_{t-1}$) are centered at their 1929 initial values, preserving $\\hat{\\theta}_0$ as the capital elasticity at the initial state. VIF statistics are computed on the level regressors space. To ensure robustness against structural instability, each specification dynamically incorporates step level-shift dummies $D^{\\text{step}}_{T_b}$ for structural breaks identified by a first-pass Bai-Perron residual audit.\n\n", min(df_clean$year), nrow(df_clean)))
cat("\\FloatBarrier\n")

cat("\\section{Specification Set 1: Double Interactions ($k^{\\text{cap}} \\cdot \\omega_{t-1}$)}\n")
cat("\\FloatBarrier\n")

set1_df <- res_df[res_df$Spec_Set == "Set_1", ]
export_s50_latex_table(set1_df, file.path(rep_dir, "table_spec_set_1.tex"), "Specification Set 1: Double Interaction IM-OLS Cointegration Estimates (1929--2024)", "tab:spec_set_1")
cat("\\input{table_spec_set_1.tex}\n\n")

cat("\\FloatBarrier\n")
cat("\\section{Specification Set 2: Triple Interactions ($k^{\\text{cap}} \\cdot \\omega_{t-1} \\cdot \\iota_{t-1}$)}\n")
cat("\\FloatBarrier\n")

set2_df <- res_df[res_df$Spec_Set == "Set_2", ]
set2_part1 <- set2_df[1:6, ]
set2_part2 <- set2_df[7:12, ]

export_s50_latex_table(set2_part1, file.path(rep_dir, "table_spec_set_2_part1.tex"), "Specification Set 2 (Part A: Baseline NFC \\& Corporate GVA Wage Shares): Triple Interaction IM-OLS Cointegration Estimates", "tab:spec_set_2_a")
export_s50_latex_table(set2_part2, file.path(rep_dir, "table_spec_set_2_part2.tex"), "Specification Set 2 (Part B: Shaikh-Tonak Tier 2 Wage Share): Triple Interaction IM-OLS Cointegration Estimates", "tab:spec_set_2_b")

cat("\\input{table_spec_set_2_part1.tex}\n\n")
cat("\\FloatBarrier\n")
cat("\\input{table_spec_set_2_part2.tex}\n\n")

cat("\\end{document}\n")
sink()

cat("Generated full LaTeX report:", tex_out, "\n")
