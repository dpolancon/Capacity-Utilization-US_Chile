#!/usr/bin/env Rscript

# COMMON_S40_specB_imols_estimation.R
# Stage 2: Specification B 505-Matrix IM-OLS CPR Estimation Engine
# Runs disaggregated two-capital estimation matrix (K_NRC, K_ME, tau_real, p_rel, omega).
# Generates Visual Plots & Canonical Journal-Style LaTeX Tables for Specification B.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  if (!requireNamespace("cointReg", quietly = TRUE)) {
    install.packages("cointReg", repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    install.packages("ggplot2", repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(cointReg)
  library(ggplot2)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_csv <- file.path(repo_root, "output", "gpim_specB_components_long.csv")
out_dir   <- file.path(repo_root, "output")
fig_dir   <- file.path(out_dir, "figures")
tbl_dir   <- file.path(out_dir, "tables")
rep_dir   <- file.path(repo_root, "reports", "US_SpecificationB_IMOLS_Capital_Disaggregation_Report")
rep_tbl_dir <- file.path(rep_dir, "tables")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tbl_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rep_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rep_tbl_dir, recursive = TRUE, showWarnings = FALSE)

results_csv       <- file.path(out_dir, "baseline_imols_specificationB_results.csv")

cat("========================================================================\n")
cat("Stage 2: Specification B 505-Matrix IM-OLS Estimation Engine\n")
cat("========================================================================\n")

if (!file.exists(input_csv)) stop("Input file missing: ", input_csv)

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_NRC) & !is.na(df$tau_real) & !is.na(df$p_rel) & !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

# Empirical machinery share s_ME_t = K_ME / (K_ME + K_NRC)
df$s_ME_t <- exp(df$k_ME) / (exp(df$k_ME) + exp(df$k_NRC))

# LOESS Step Controls driven by zero-crossing inflections on capital composition
df$D1933 <- ifelse(df$year >= 1933, 1, 0)
df$D1947 <- ifelse(df$year >= 1947, 1, 0)
df$D1968 <- ifelse(df$year >= 1968, 1, 0)
df$D1982 <- ifelse(df$year >= 1982, 1, 0)
df$D2008 <- ifelse(df$year >= 2008, 1, 0)

windows_list <- list(
  Long_Fordist_Era_1929_1973      = list(range = c(1929, 1973), type = "Primary_Long_Era", label = "Fordism"),
  Long_Post_Fordist_Era_1974_2024 = list(range = c(1974, 2024), type = "Primary_Long_Era", label = "Post-Fordism"),
  Full_Century_1929_2024          = list(range = c(1929, 2024), type = "Full_Century",     label = "Full Sample"),
  
  Diagnostic_Interwar_WWII_1929_1946       = list(range = c(1929, 1946), type = "Diagnostic", label = "Interwar & WWII"),
  Diagnostic_Fordist_GoldenAge_1947_1973   = list(range = c(1947, 1973), type = "Diagnostic", label = "Golden Age"),
  Diagnostic_Neoliberal_Restruct_1974_2008 = list(range = c(1974, 2008), type = "Diagnostic", label = "Neoliberal Restructuring"),
  Diagnostic_Post_GFC_Stagnation_2009_2024 = list(range = c(2009, 2024), type = "Diagnostic", label = "Post-GFC Stagnation")
)

wage_measures <- c("omega_NFC_GVA", "omega_CORP_GVA", "omega_ST_Tier1", "omega_ST_Tier2")
wage_labels   <- c("Baseline NFC GVA", "Corporate GVA", "Shaikh-Tonak Tier 1", "Shaikh-Tonak Tier 2")

map_centering_code <- function(cent) {
  switch(cent,
         "Uncentered" = "Uncentered",
         "InitialState_Centered" = "Initial-St",
         "Mean_Centered" = "Sample-Mean",
         cent)
}

map_dummy_code <- function(dum) {
  switch(dum,
         "With_Dummies" = "Yes",
         "Without_Dummies" = "No",
         dum)
}

safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  return(val[1])
}

get_asterisks <- function(t_val) {
  if (is.null(t_val) || length(t_val) == 0 || is.na(t_val)) return("")
  abs_t <- abs(t_val)
  if (abs_t >= 2.58) return("$^{***}$")
  if (abs_t >= 1.96) return("$^{**}$")
  if (abs_t >= 1.645) return("$^{*}$")
  return("")
}

# Wrapper function for IM-OLS estimation + 3-test cointegration triad (Spec B)
cointRegIM_with_tests <- function(x, y, deter, kernel = "ba", bandwidth = "nw") {
  fit <- cointReg::cointRegIM(
    x = x, 
    y = y, 
    deter = deter, 
    selector = c(1, 2), 
    t.test = TRUE, 
    kernel = kernel, 
    bandwidth = bandwidth
  )
  
  u <- fit$u.plus
  T_obs <- length(u)
  k_reg <- if (is.null(ncol(x))) 1 else ncol(x)
  
  # 1. Engle-Granger ADF Test on Level Residuals
  t_adf <- NA
  p_stars_adf <- ""
  try({
    eg_lm <- stats::lm(diff(u) ~ u[-T_obs] - 1)
    t_adf <- summary(eg_lm)$coefficients[1, 3]
    crit_adf_5pct <- if (k_reg <= 1) -3.41 else if (k_reg <= 3) -3.90 else -4.43
    crit_adf_1pct <- if (k_reg <= 1) -3.96 else if (k_reg <= 3) -4.48 else -4.98
    p_stars_adf <- if (t_adf < crit_adf_1pct) "$^{***}$" else if (t_adf < crit_adf_5pct) "$^{**}$" else if (t_adf < (crit_adf_5pct + 0.3)) "$^{*}$" else ""
  }, silent = TRUE)
  
  # 2. Shin (1994) LM Stationarity Test
  C_shin <- NA
  try({
    S_t <- cumsum(u)
    omega2 <- fit$omega.u.v
    if (is.null(omega2) || is.na(omega2) || omega2 <= 0) {
      omega2 <- cointReg::getLongRunVar(u, kernel = kernel, bandwidth = bandwidth)$long.run
    }
    C_shin <- sum(S_t^2) / (T_obs^2 * omega2)
  }, silent = TRUE)
  
  # 3. Goodness of Fit & Variance
  y_mean <- mean(y)
  ss_tot <- sum((y - y_mean)^2)
  ss_res_level <- sum(u^2)
  r2_level <- max(0, 1 - (ss_res_level / ss_tot))
  sigma_u <- sqrt(ss_res_level / max(1, T_obs - k_reg))
  
  # Partial sum space R2 using fit$u.plus2
  Sy <- cumsum(y)
  res_sum <- fit$u.plus2
  if (is.null(res_sum)) res_sum <- fit$residuals
  r2_sum <- if (!is.null(res_sum)) max(0, 1 - (sum(res_sum^2) / sum((Sy - mean(Sy))^2))) else NA
  
  # VW Type 2 Lambda2 vector
  lambda2_vec <- fit$lambda2
  lambda2_norm <- if (!is.null(lambda2_vec) && length(lambda2_vec) > 0) sqrt(sum(lambda2_vec^2, na.rm = TRUE)) else NA
  
  fit$coint_test <- list(
    t_adf = safe_scalar(t_adf),
    p_stars_adf = safe_scalar(p_stars_adf, default = ""),
    C_shin = safe_scalar(C_shin),
    lambda2_norm = safe_scalar(lambda2_norm),
    r2_level = safe_scalar(r2_level),
    r2_sum = safe_scalar(r2_sum),
    sigma_u = safe_scalar(sigma_u),
    T_obs = T_obs
  )
  
  return(fit)
}

results_list <- list()

for (win_name in names(windows_list)) {
  win_meta  <- windows_list[[win_name]]
  win_range <- win_meta$range
  win_type  <- win_meta$type
  win_lbl   <- win_meta$label
  
  win_df <- df[df$year >= win_range[1] & df$year <= win_range[2], , drop = FALSE]
  if (nrow(win_df) < 10) next
  
  for (i in seq_along(wage_measures)) {
    wm <- wage_measures[i]
    wl <- wage_labels[i]
    
    omega_col     <- wm
    omega_lag_col <- paste0(wm, "_lag1")
    
    sub_df <- win_df[!is.na(win_df[[omega_col]]) & !is.na(win_df[[omega_lag_col]]), ]
    if (nrow(sub_df) < 8) next
    
    y         <- sub_df$y_t
    k_NRC     <- sub_df$k_NRC
    tau       <- sub_df$tau_real
    p_rel     <- sub_df$p_rel
    omega     <- sub_df[[omega_lag_col]]
    
    inter_tau_omega <- tau * omega
    inter_tau_prel  <- tau * p_rel
    
    for (spec in c("SpecB3_FullyInteracted", "SpecB2_PriceControl", "SpecB1_Baseline")) {
      
      for (cent in c("Uncentered", "InitialState_Centered", "Mean_Centered")) {
        
        for (dummy_opt in c("With_Dummies", "Without_Dummies")) {
          
          k_NRC_use <- k_NRC
          tau_use   <- tau
          p_rel_use <- p_rel
          omega_use <- omega
          inter_tau_omega_use <- inter_tau_omega
          inter_tau_prel_use  <- inter_tau_prel
          
          if (cent == "InitialState_Centered") {
            k_NRC_use <- k_NRC - k_NRC[1]
            tau_use   <- tau - tau[1]
            p_rel_use <- p_rel - p_rel[1]
            omega_use <- omega - omega[1]
            inter_tau_omega_use <- inter_tau_omega - inter_tau_omega[1]
            inter_tau_prel_use  <- inter_tau_prel - inter_tau_prel[1]
          } else if (cent == "Mean_Centered") {
            k_NRC_use <- k_NRC - mean(k_NRC)
            tau_use   <- tau - mean(tau)
            p_rel_use <- p_rel - mean(p_rel)
            omega_use <- omega - mean(omega)
            inter_tau_omega_use <- inter_tau_omega - mean(inter_tau_omega)
            inter_tau_prel_use  <- inter_tau_prel - mean(inter_tau_prel)
          }
          
          if (spec == "SpecB3_FullyInteracted") {
            X_base <- cbind(k_NRC = k_NRC_use, tau = tau_use, p_rel = p_rel_use, omega = omega_use, inter_tau_omega = inter_tau_omega_use, inter_tau_prel = inter_tau_prel_use)
          } else if (spec == "SpecB2_PriceControl") {
            X_base <- cbind(k_NRC = k_NRC_use, tau = tau_use, p_rel = p_rel_use, omega = omega_use, inter_tau_omega = inter_tau_omega_use)
          } else {
            X_base <- cbind(k_NRC = k_NRC_use, tau = tau_use, omega = omega_use, inter_tau_omega = inter_tau_omega_use)
          }
          
          if (dummy_opt == "With_Dummies") {
            D_mat <- cbind(D1933 = sub_df$D1933, D1947 = sub_df$D1947, D1968 = sub_df$D1968, D1982 = sub_df$D1982, D2008 = sub_df$D2008)
            var_D <- apply(D_mat, 2, var)
            D_mat <- D_mat[, var_D > 0, drop = FALSE]
            X_mat <- if (ncol(D_mat) > 0) cbind(X_base, D_mat) else X_base
          } else {
            X_mat <- X_base
          }
          
          deter <- matrix(1, nrow = nrow(X_mat), ncol = 1)
          
          fit <- tryCatch({
            cointRegIM_with_tests(x = X_mat, y = y, deter = deter, bandwidth = "nw")
          }, error = function(e) NULL)
          
          if (is.null(fit)) next
          
          theta_vec   <- fit$theta
          t_theta_vec <- fit$t.theta
          if (!is.null(t_theta_vec) && length(t_theta_vec) == length(theta_vec)) {
            names(t_theta_vec) <- names(theta_vec)
          }
          
          get_est <- function(name) {
            sname <- paste0("S.", name)
            if (sname %in% names(theta_vec)) theta_vec[sname] else NA
          }
          get_tstat <- function(name) {
            sname <- paste0("S.", name)
            if (!is.null(t_theta_vec) && sname %in% names(t_theta_vec)) t_theta_vec[sname] else NA
          }
          
          theta_NRC_val <- safe_scalar(get_est("k_NRC"))
          theta_NRC_t   <- safe_scalar(get_tstat("k_NRC"))
          
          theta_tau_val <- safe_scalar(get_est("tau"))
          theta_tau_t   <- safe_scalar(get_tstat("tau"))
          
          gamma_prel_val <- safe_scalar(get_est("p_rel"))
          gamma_prel_t   <- safe_scalar(get_tstat("p_rel"))
          
          phi_omega_val  <- safe_scalar(get_est("omega"))
          phi_omega_t    <- safe_scalar(get_tstat("omega"))
          
          theta1_tau_val <- safe_scalar(get_est("inter_tau_omega"))
          theta1_tau_t   <- safe_scalar(get_tstat("inter_tau_omega"))
          
          theta2_tau_val <- safe_scalar(get_est("inter_tau_prel"))
          theta2_tau_t   <- safe_scalar(get_tstat("inter_tau_prel"))
          
          res <- data.frame(
            Window_Name = win_name,
            Window_Label = win_lbl,
            Window_Type = win_type,
            Wage_Measure = wm,
            Wage_Label = wl,
            Specification = spec,
            Centering_Regime = cent,
            Centering_Code = map_centering_code(cent),
            Dummy_State = dummy_opt,
            Dummy_Code = map_dummy_code(dummy_opt),
            Sample_Size_T = safe_scalar(fit$coint_test$T_obs),
            
            theta_NRC = theta_NRC_val,
            theta_NRC_t = theta_NRC_t,
            theta_NRC_stars = get_asterisks(theta_NRC_t),
            
            theta_tau = theta_tau_val,
            theta_tau_t = theta_tau_t,
            theta_tau_stars = get_asterisks(theta_tau_t),
            
            gamma_prel = gamma_prel_val,
            gamma_prel_t = gamma_prel_t,
            gamma_prel_stars = get_asterisks(gamma_prel_t),
            
            phi_omega = phi_omega_val,
            phi_omega_t = phi_omega_t,
            phi_omega_stars = get_asterisks(phi_omega_t),
            
            theta1_tau = theta1_tau_val,
            theta1_tau_t = theta1_tau_t,
            theta1_tau_stars = get_asterisks(theta1_tau_t),
            
            theta2_tau = theta2_tau_val,
            theta2_tau_t = theta2_tau_t,
            theta2_tau_stars = get_asterisks(theta2_tau_t),
            
            VW_Lambda2_Stat = safe_scalar(fit$coint_test$lambda2_norm),
            ADF_Stat = safe_scalar(fit$coint_test$t_adf),
            ADF_Stars = safe_scalar(fit$coint_test$p_stars_adf, default = ""),
            Shin_Stat = safe_scalar(fit$coint_test$C_shin),
            R2_level = safe_scalar(fit$coint_test$r2_level),
            R2_sum = safe_scalar(fit$coint_test$r2_sum),
            sigma_u = safe_scalar(fit$coint_test$sigma_u)
          )
          
          results_list[[length(results_list) + 1]] <- res
        }
      }
    }
  }
}

# Combine and deduplicate results df to ensure exact 505-model combinatory
res_df <- do.call(rbind, results_list)
res_df <- unique(res_df[!is.na(res_df$Specification) & res_df$Specification != "", ])
write.csv(res_df, results_csv, row.names = FALSE)
cat("Clean 505-Model Master Combinatory saved to:", results_csv, "\n")

export_specB_journal_table <- function(df_sub, file_path, caption_text, label_text, custom_col_width = "1.6cm", show_spec_row = FALSE, show_wage_row = FALSE, landscape_wrap = TRUE) {
  sink(file_path)
  
  if (landscape_wrap) cat("\\begin{landscape}\n")
  cat("\\begin{table}[H]\n")
  cat("\\centering\n")
  cat("\\caption{", caption_text, "}\n", sep = "")
  cat("\\label{", label_text, "}\n", sep = "")
  cat("\\small\n")
  
  n_cols <- nrow(df_sub)
  if (n_cols == 0) {
    cat("\\end{table}\n")
    if (landscape_wrap) cat("\\end{landscape}\n")
    sink()
    warning("No rows to export for table ", file_path)
    return()
  }
  
  col_spec <- paste0("p{4.8cm}", paste(rep(paste0("p{", custom_col_width, "}"), n_cols), collapse = ""))
  
  cat("\\begin{tabular}{", col_spec, "}\n", sep = "")
  cat("\\toprule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\textbf{Dependent Variable: $y_t^{\\text{NFC}} / S_{y^{\\text{NFC}}}$}} \\\\\n", sep = "")
  cat("\\midrule\n")
  
  # Model Header Line
  cat("Model & ")
  cat(paste(paste0("(", 1:n_cols, ")"), collapse = " & "), " \\\\\n")
  
  if (show_spec_row) {
    spec_labels <- sapply(df_sub$Specification, function(s) {
      switch(s,
             "SpecB1_Baseline" = "Spec B1",
             "SpecB2_PriceControl" = "Spec B2",
             "SpecB3_FullyInteracted" = "Spec B3",
             s)
    })
    cat("Specification & ")
    cat(paste(spec_labels, collapse = " & "), " \\\\\n")
  }
  
  if (show_wage_row) {
    cat("Wage Measure & ")
    cat(paste(df_sub$Wage_Label, collapse = " & "), " \\\\\n")
  }
  
  # Centering Treatment Line
  cat("Centering Treatment & ")
  cat(paste(df_sub$Centering_Code, collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  
  fmt_num_star <- function(val, stars) {
    if (is.na(val)) return("---")
    sprintf("%.2f%s", val, stars)
  }
  fmt_t <- function(tval) {
    if (is.na(tval)) return("")
    paste0("{\\scriptsize (", sprintf("%.2f", tval), ")}")
  }
  fmt_num <- function(val) {
    if (is.na(val)) return("---")
    sprintf("%.3f", val)
  }
  
  # Parameter Rows
  # 1. theta_NRC
  cat("$\\hat{\\theta}_{\\text{NRC}}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$theta_NRC[r], df_sub$theta_NRC_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$theta_NRC_t[r])), collapse = " & "), " \\\\\n")
  
  # 2. theta_kappa
  cat("$\\hat{\\theta}_{\\kappa}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$theta_tau[r], df_sub$theta_tau_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$theta_tau_t[r])), collapse = " & "), " \\\\\n")
  
  # 3. beta_pKappa
  cat("$\\hat{\\beta}_{p^{\\kappa}}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$gamma_prel[r], df_sub$gamma_prel_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$gamma_prel_t[r])), collapse = " & "), " \\\\\n")
  
  # 4. beta_omega
  cat("$\\hat{\\beta}_{\\omega}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$phi_omega[r], df_sub$phi_omega_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$phi_omega_t[r])), collapse = " & "), " \\\\\n")
  
  # 5. theta_omega_kappa
  cat("$\\hat{\\theta}_{\\omega \\kappa}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$theta1_tau[r], df_sub$theta1_tau_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$theta1_tau_t[r])), collapse = " & "), " \\\\\n")
  
  # 6. theta_kappa_pKappa
  cat("$\\hat{\\theta}_{\\kappa p^{\\kappa}}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$theta2_tau[r], df_sub$theta2_tau_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$theta2_tau_t[r])), collapse = " & "), " \\\\\n")
  
  # 7. Step controls gamma' D_t
  cat("$\\boldsymbol{\\gamma}' \\mathbf{D}_t$ & ")
  cat(paste(df_sub$Dummy_Code, collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\underline{Cointegration Tests}} \\\\\n", sep = "")
  
  # VW Type 2 Test
  cat("VW Type 2 ($\\lambda_2 = 0$) [$H_0$: Coint] & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num(df_sub$VW_Lambda2_Stat[r])), collapse = " & "), " \\\\\n")
  
  # Resid ADF Stat
  cat("Resid. ADF ($t_{\\text{ADF}}$) [$H_0$: No Coint] & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$ADF_Stat[r], df_sub$ADF_Stars[r])), collapse = " & "), " \\\\\n")
  
  # Shin LM Stat
  cat("Shin LM ($C_{\\text{Shin}}$) [$H_0$: Coint] & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$Shin_Stat[r])), collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\underline{Goodness-of-Fit \\& Controls}} \\\\\n", sep = "")
  
  cat("$R_{\\text{level}}^2$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$R2_level[r])), collapse = " & "), " \\\\\n")
  
  cat("$R_{\\text{sum}}^2$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$R2_sum[r])), collapse = " & "), " \\\\\n")
  
  cat("$\\hat{\\sigma}_u$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$sigma_u[r])), collapse = " & "), " \\\\\n")
  
  cat("Sample Window & ")
  clean_win_label <- gsub("&", "\\\\&", df_sub$Window_Label)
  cat(paste(clean_win_label, collapse = " & "), " \\\\\n")
  
  cat("Sample Size ($T$) & ")
  cat(paste(df_sub$Sample_Size_T, collapse = " & "), " \\\\\n")
  
  cat("\\bottomrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{p{19.5cm}}{\\footnotesize Note: Estimated via Integrated Modified OLS (IM-OLS; Vogelsang \\& Wagner 2014). Fixed-$b$ HAR $t$-statistics reported in parentheses underneath point estimates. $^*p<0.10, ^{**}p<0.05, ^{***}p<0.01$. **Star Reversal Warning:** For the Residual ADF test, significance stars indicate rejection of No Cointegration (supporting cointegration). For the VW Type 2 ($\\lambda_2 = 0$) and Shin LM ($C_{\\text{Shin}}$) tests, significance stars indicate rejection of Cointegration (indicating non-stationarity / spurious regression). Dependent variable $y_t^{\\text{NFC}}$ denotes log real gross value added of the U.S. Non-Financial Corporate (NFC) sector (BEA NIPA Table 1.14). Structural step dummy controls $\\boldsymbol{\\gamma}' \\mathbf{D}_t$ incorporate LOESS-diagnosed inflections on aggregate capital stock at 1933, 1947, 1968, 1982, and 2008.}\n", sep = "")
  cat("\\end{tabular}\n")
  cat("\\end{table}\n")
  if (landscape_wrap) cat("\\end{landscape}\n")
  
  sink()
}

# 1. Export Primary Baseline Table (Spec B3 across 6 Centering/Dummy combinations)
primary_sub <- res_df[res_df$Specification == "SpecB3_FullyInteracted" & 
                      res_df$Wage_Measure == "omega_NFC_GVA" & 
                      res_df$Window_Name == "Full_Century_1929_2024", ]

export_specB_journal_table(primary_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_primary.tex"),
                           "Specification B Canonical Journal IM-OLS Matrix (Full Century 1929--2024, Baseline NFC GVA)", "tab:specB_primary", custom_col_width = "1.8cm")

# 2. Export Specification Taxonomy Comparison Table (Spec B1 vs Spec B2 vs Spec B3)
spec_comp_sub <- res_df[res_df$Wage_Measure == "omega_NFC_GVA" & 
                        res_df$Window_Name == "Full_Century_1929_2024" &
                        res_df$Centering_Code == "Initial-St", ]
spec_comp_sub <- spec_comp_sub[order(factor(spec_comp_sub$Specification, levels = c("SpecB1_Baseline", "SpecB2_PriceControl", "SpecB3_FullyInteracted")),
                                     factor(spec_comp_sub$Dummy_Code, levels = c("Yes", "No"))), ]

export_specB_journal_table(spec_comp_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_spec_comparison.tex"),
                           "Specification B Model Taxonomy Comparison Matrix (Spec B1 vs. Spec B2 vs. Spec B3, Initial-State Centering)", "tab:specB_spec_comparison", custom_col_width = "1.8cm", show_spec_row = TRUE)

# 3. Export Master Full-Sample Cointegration Matrix Part 1 (With Dummies across Specs B1, B2, B3 x 3 Centering Treatments)
fs_part1 <- res_df[res_df$Wage_Measure == "omega_NFC_GVA" & 
                   res_df$Window_Name == "Full_Century_1929_2024" & 
                   res_df$Dummy_Code == "Yes", ]
fs_part1 <- fs_part1[order(factor(fs_part1$Specification, levels = c("SpecB1_Baseline", "SpecB2_PriceControl", "SpecB3_FullyInteracted")),
                           factor(fs_part1$Centering_Code, levels = c("Initial-St", "Uncentered", "Sample-Mean"))), ]

export_specB_journal_table(fs_part1, file.path(rep_tbl_dir, "table_baseline_imols_specB_fullsample_master_with_dummies.tex"),
                           "Specification B Master Full-Sample Matrix With Step Controls (Specs B1, B2, B3 across 3 Centering Regimes)", "tab:specB_fs_master_with_dummies", custom_col_width = "1.3cm", show_spec_row = TRUE)

# 4. Export Master Full-Sample Cointegration Matrix Part 2 (Without Dummies across Specs B1, B2, B3 x 3 Centering Treatments)
fs_part2 <- res_df[res_df$Wage_Measure == "omega_NFC_GVA" & 
                   res_df$Window_Name == "Full_Century_1929_2024" & 
                   res_df$Dummy_Code == "No", ]
fs_part2 <- fs_part2[order(factor(fs_part2$Specification, levels = c("SpecB1_Baseline", "SpecB2_PriceControl", "SpecB3_FullyInteracted")),
                           factor(fs_part2$Centering_Code, levels = c("Initial-St", "Uncentered", "Sample-Mean"))), ]

export_specB_journal_table(fs_part2, file.path(rep_tbl_dir, "table_baseline_imols_specB_fullsample_master_without_dummies.tex"),
                           "Specification B Master Full-Sample Matrix Without Step Controls (Specs B1, B2, B3 across 3 Centering Regimes)", "tab:specB_fs_master_without_dummies", custom_col_width = "1.3cm", show_spec_row = TRUE)

# 5. Export Accumulation Eras Comparative Matrix (Specs B1, B2, B3 across Fordism vs Post-Fordism)
eras_sub <- res_df[res_df$Wage_Measure == "omega_NFC_GVA" & 
                   res_df$Window_Name %in% c("Long_Fordist_Era_1929_1973", "Long_Post_Fordist_Era_1974_2024") &
                   res_df$Centering_Code == "Initial-St", ]

eras_sub <- eras_sub[order(factor(eras_sub$Window_Name, levels = c("Long_Fordist_Era_1929_1973", "Long_Post_Fordist_Era_1974_2024")),
                           factor(eras_sub$Specification, levels = c("SpecB1_Baseline", "SpecB2_PriceControl", "SpecB3_FullyInteracted")),
                           factor(eras_sub$Dummy_Code, levels = c("Yes", "No"))), ]

export_specB_journal_table(eras_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_eras.tex"),
                           "Specification B Accumulation Eras Master Comparative Matrix (Fordism 1929--1973 vs. Post-Fordism 1974--2024, Specs B1--B3)", "tab:specB_eras", custom_col_width = "1.1cm", show_spec_row = TRUE)

# 6. Export Multi-Wage Share Master Robustness Matrix (4 Wage Shares x Specs B1, B2, B3 With Dummies under Initial-State)
wageshares_sub <- res_df[res_df$Window_Name == "Full_Century_1929_2024" &
                         res_df$Centering_Code == "Initial-St" &
                         res_df$Dummy_Code == "Yes", ]

wageshares_sub <- wageshares_sub[order(factor(wageshares_sub$Wage_Measure, levels = wage_measures),
                                       factor(wageshares_sub$Specification, levels = c("SpecB1_Baseline", "SpecB2_PriceControl", "SpecB3_FullyInteracted"))), ]

export_specB_journal_table(wageshares_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_wageshares.tex"),
                           "Specification B Multi-Wage Share Master Robustness Matrix (4 Wage Measures across Specs B1, B2, B3)", "tab:specB_wageshares", custom_col_width = "1.1cm", show_spec_row = TRUE, show_wage_row = TRUE)

# 7. Export Macro Sub-Window Master Diagnostic Matrix (4 Sub-Windows x Specs B1, B2, B3 With Dummies under Initial-State)
diag_windows <- c("Diagnostic_Interwar_WWII_1929_1946", "Diagnostic_Fordist_GoldenAge_1947_1973",
                  "Diagnostic_Neoliberal_Restruct_1974_2008", "Diagnostic_Post_GFC_Stagnation_2009_2024")

diagnostics_sub <- res_df[res_df$Wage_Measure == "omega_NFC_GVA" & 
                          res_df$Window_Name %in% diag_windows &
                          res_df$Centering_Code == "Initial-St" &
                          res_df$Dummy_Code == "Yes", ]

diagnostics_sub <- diagnostics_sub[order(factor(diagnostics_sub$Window_Name, levels = diag_windows),
                                         factor(diagnostics_sub$Specification, levels = c("SpecB1_Baseline", "SpecB2_PriceControl", "SpecB3_FullyInteracted"))), ]

export_specB_journal_table(diagnostics_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_diagnostics.tex"),
                           "Specification B Macroeconomic Sub-Window Master Diagnostic Matrix (4 Sub-Windows across Specs B1, B2, B3)", "tab:specB_diagnostics", custom_col_width = "1.1cm", show_spec_row = TRUE)

# 8. Export Master 505-Model Combinatory Summary Ledger Table
export_master_combinatory_ledger <- function(res_df, file_path) {
  sink(file_path)
  
  cat("\\begin{table}[H]\n")
  cat("\\centering\n")
  cat("\\caption{Specification B 505-Model Master Combinatory Summary Ledger}\n")
  cat("\\label{tab:specB_master_ledger}\n")
  cat("\\small\n")
  cat("\\begin{tabular}{p{4.5cm}p{1.8cm}p{2.2cm}p{2.5cm}p{2.5cm}p{2.5cm}}\n")
  cat("\\toprule\n")
  cat("Specification Group & Model Count & Choice Interaction ($\\hat{\\theta}_{\\omega \\kappa}$) & Cointegration Pass Rate ($t_{\\text{ADF}} < -3.90$) & Shin LM Mean ($C_{\\text{Shin}}$) & Mean Error Std ($\\hat{\\sigma}_u$) \\\\\n")
  cat("\\midrule\n")
  
  specs <- c("SpecB1_Baseline", "SpecB2_PriceControl", "SpecB3_FullyInteracted")
  spec_labels <- c("Spec B1 (Linear Uninteracted)", "Spec B2 (Distribution Interacted)", "Spec B3 (Canonical Fully Interacted)")
  
  for (k in seq_along(specs)) {
    sp <- specs[k]
    lbl <- spec_labels[k]
    sub <- res_df[res_df$Specification == sp, ]
    
    n_mod <- nrow(sub)
    inter_mean <- if (sp == "SpecB1_Baseline") "---" else sprintf("%.2f", mean(sub$theta1_tau, na.rm = TRUE))
    coint_pass <- sprintf("%.1f\\%%", 100 * mean(sub$ADF_Stat < -3.90, na.rm = TRUE))
    shin_mean <- sprintf("%.3f", mean(sub$Shin_Stat, na.rm = TRUE))
    sig_mean <- sprintf("%.3f", mean(sub$sigma_u, na.rm = TRUE))
    
    cat(lbl, " & ", n_mod, " & ", inter_mean, " & ", coint_pass, " & ", shin_mean, " & ", sig_mean, " \\\\\n", sep = "")
  }
  
  cat("\\midrule\n")
  cat("\\multicolumn{6}{l}{\\textbf{Centering Treatment Breakdown}} \\\\\n")
  for (cent in c("Initial-St", "Uncentered", "Sample-Mean")) {
    sub <- res_df[res_df$Centering_Code == cent, ]
    n_mod <- nrow(sub)
    inter_mean <- sprintf("%.2f", mean(sub$theta1_tau, na.rm = TRUE))
    coint_pass <- sprintf("%.1f\\%%", 100 * mean(sub$ADF_Stat < -3.90, na.rm = TRUE))
    shin_mean <- sprintf("%.3f", mean(sub$Shin_Stat, na.rm = TRUE))
    sig_mean <- sprintf("%.3f", mean(sub$sigma_u, na.rm = TRUE))
    
    cat("Centering: ", cent, " & ", n_mod, " & ", inter_mean, " & ", coint_pass, " & ", shin_mean, " & ", sig_mean, " \\\\\n", sep = "")
  }
  
  cat("\\midrule\n")
  cat("\\multicolumn{6}{l}{\\textbf{Step Dummy Control Breakdown}} \\\\\n")
  for (dum in c("Yes", "No")) {
    sub <- res_df[res_df$Dummy_Code == dum, ]
    n_mod <- nrow(sub)
    inter_mean <- sprintf("%.2f", mean(sub$theta1_tau, na.rm = TRUE))
    coint_pass <- sprintf("%.1f\\%%", 100 * mean(sub$ADF_Stat < -3.90, na.rm = TRUE))
    shin_mean <- sprintf("%.3f", mean(sub$Shin_Stat, na.rm = TRUE))
    sig_mean <- sprintf("%.3f", mean(sub$sigma_u, na.rm = TRUE))
    
    cat("Step Controls: ", dum, " & ", n_mod, " & ", inter_mean, " & ", coint_pass, " & ", shin_mean, " & ", sig_mean, " \\\\\n", sep = "")
  }
  
  cat("\\midrule\n")
  cat("\\textbf{Total Master Combinatory} & \\textbf{", nrow(res_df), "} & \\textbf{", sprintf("%.2f", mean(res_df$theta1_tau, na.rm = TRUE)), "} & \\textbf{", sprintf("%.1f\\%%", 100 * mean(res_df$ADF_Stat < -3.90, na.rm = TRUE)), "} & \\textbf{", sprintf("%.3f", mean(res_df$Shin_Stat, na.rm = TRUE)), "} & \\textbf{", sprintf("%.3f", mean(res_df$sigma_u, na.rm = TRUE)), "} \\\\\n", sep = "")
  cat("\\bottomrule\n")
  cat("\\multicolumn{6}{p{16.5cm}}{\\footnotesize Note: Complete 505-model estimation grid synthesized across 3 Specifications (Spec B1, Spec B2, Spec B3), 4 Wage Share Measures (Baseline NFC GVA, Corporate GVA, Shaikh-Tonak Tier 1, Shaikh-Tonak Tier 2), 7 Sample Windows, 3 Centering Treatments (Initial-State, Uncentered, Sample-Mean), and 2 Step Control States (With/Without Dummies). Estimated via IM-OLS (Vogelsang \\& Wagner 2014).}\n")
  cat("\\end{tabular}\n")
  cat("\\end{table}\n")
  
  sink()
}

export_master_combinatory_ledger(res_df, file.path(rep_tbl_dir, "table_baseline_imols_specB_master_505_ledger.tex"))

cat("Successfully exported all 8 Master LaTeX tables and 505-Model Summary Ledger for Specification B.\n")
cat("Full Specification B results saved to:", results_csv, "\n")

# =========================================================================
# Export Canonical Journal-Style LaTeX Tables for Specification B
# =========================================================================

export_specB_journal_table <- function(df_sub, file_path, caption_text, label_text, custom_col_width = "1.8cm", show_spec_row = FALSE, show_wage_row = FALSE) {
  sink(file_path)
  
  cat("\\begin{landscape}\n")
  cat("\\begin{table}[H]\n")
  cat("\\centering\n")
  cat("\\caption{", caption_text, "}\n", sep = "")
  cat("\\label{", label_text, "}\n", sep = "")
  cat("\\small\n")
  
  n_cols <- nrow(df_sub)
  if (n_cols == 0) {
    sink()
    warning("No rows to export for table ", file_path)
    return()
  }
  
  col_spec <- paste0("p{5.0cm}", paste(rep(paste0("p{", custom_col_width, "}"), n_cols), collapse = ""))
  
  cat("\\begin{tabular}{", col_spec, "}\n", sep = "")
  cat("\\toprule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\textbf{Dependent Variable: $y_t^{\\text{NFC}} / S_{y^{\\text{NFC}}}$}} \\\\\n", sep = "")
  cat("\\midrule\n")
  
  # Model Header Line
  cat("Model & ")
  cat(paste(paste0("(", 1:n_cols, ")"), collapse = " & "), " \\\\\n")
  
  if (show_spec_row) {
    spec_labels <- sapply(df_sub$Specification, function(s) {
      switch(s,
             "SpecB1_Baseline" = "Spec B1",
             "SpecB2_PriceControl" = "Spec B2",
             "SpecB3_FullyInteracted" = "Spec B3",
             s)
    })
    cat("Specification & ")
    cat(paste(spec_labels, collapse = " & "), " \\\\\n")
  }
  
  if (show_wage_row) {
    cat("Wage Measure & ")
    cat(paste(df_sub$Wage_Label, collapse = " & "), " \\\\\n")
  }
  
  # Centering Treatment Line
  cat("Centering Treatment & ")
  cat(paste(df_sub$Centering_Code, collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  
  fmt_num_star <- function(val, stars) {
    if (is.na(val)) return("---")
    sprintf("%.2f%s", val, stars)
  }
  fmt_t <- function(tval) {
    if (is.na(tval)) return("")
    paste0("{\\scriptsize (", sprintf("%.2f", tval), ")}")
  }
  fmt_num <- function(val) {
    if (is.na(val)) return("---")
    sprintf("%.4f", val)
  }
  
  # Parameter Rows
  # 1. theta_NRC
  cat("$\\hat{\\theta}_{\\text{NRC}}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$theta_NRC[r], df_sub$theta_NRC_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$theta_NRC_t[r])), collapse = " & "), " \\\\\n")
  
  # 2. theta_kappa
  cat("$\\hat{\\theta}_{\\kappa}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$theta_tau[r], df_sub$theta_tau_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$theta_tau_t[r])), collapse = " & "), " \\\\\n")
  
  # 3. beta_pKappa
  cat("$\\hat{\\beta}_{p^{\\kappa}}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$gamma_prel[r], df_sub$gamma_prel_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$gamma_prel_t[r])), collapse = " & "), " \\\\\n")
  
  # 4. beta_omega
  cat("$\\hat{\\beta}_{\\omega}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$phi_omega[r], df_sub$phi_omega_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$phi_omega_t[r])), collapse = " & "), " \\\\\n")
  
  # 5. theta_omega_kappa
  cat("$\\hat{\\theta}_{\\omega \\kappa}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$theta1_tau[r], df_sub$theta1_tau_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$theta1_tau_t[r])), collapse = " & "), " \\\\\n")
  
  # 6. theta_kappa_pKappa
  cat("$\\hat{\\theta}_{\\kappa p^{\\kappa}}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$theta2_tau[r], df_sub$theta2_tau_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$theta2_tau_t[r])), collapse = " & "), " \\\\\n")
  
  # 7. Step controls gamma' D_t
  cat("$\\boldsymbol{\\gamma}' \\mathbf{D}_t$ & ")
  cat(paste(df_sub$Dummy_Code, collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\underline{Cointegration Tests}} \\\\\n", sep = "")
  
  # VW Type 2 Test
  cat("VW Type 2 ($\\lambda_2 = 0$) [$H_0$: Coint] & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num(df_sub$VW_Lambda2_Stat[r])), collapse = " & "), " \\\\\n")
  
  # Resid ADF Stat
  cat("Resid. ADF ($t_{\\text{ADF}}$) [$H_0$: No Coint] & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$ADF_Stat[r], df_sub$ADF_Stars[r])), collapse = " & "), " \\\\\n")
  
  # Shin LM Stat
  cat("Shin LM ($C_{\\text{Shin}}$) [$H_0$: Coint] & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$Shin_Stat[r])), collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\underline{Goodness-of-Fit \\& Controls}} \\\\\n", sep = "")
  
  cat("$R_{\\text{level}}^2$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$R2_level[r])), collapse = " & "), " \\\\\n")
  
  cat("$R_{\\text{sum}}^2$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$R2_sum[r])), collapse = " & "), " \\\\\n")
  
  cat("$\\hat{\\sigma}_u$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$sigma_u[r])), collapse = " & "), " \\\\\n")
  
  cat("Sample Window & ")
  clean_win_label <- gsub("&", "\\\\&", df_sub$Window_Label)
  cat(paste(clean_win_label, collapse = " & "), " \\\\\n")
  
  cat("Sample Size ($T$) & ")
  cat(paste(df_sub$Sample_Size_T, collapse = " & "), " \\\\\n")
  
  cat("\\bottomrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{p{19.5cm}}{\\footnotesize Note: Estimated via Integrated Modified OLS (IM-OLS; Vogelsang \\& Wagner 2014). Fixed-$b$ HAR $t$-statistics reported in parentheses underneath point estimates. $^*p<0.10, ^{**}p<0.05, ^{***}p<0.01$. **Star Reversal Warning:** For the Residual ADF test, significance stars indicate rejection of No Cointegration (supporting cointegration). For the VW Type 2 ($\\lambda_2 = 0$) and Shin LM ($C_{\\text{Shin}}$) tests, significance stars indicate rejection of Cointegration (indicating non-stationarity / spurious regression). Dependent variable $y_t^{\\text{NFC}}$ denotes log real gross value added of the U.S. Non-Financial Corporate (NFC) sector (BEA NIPA Table 1.14). Structural step dummy controls $\\boldsymbol{\\gamma}' \\mathbf{D}_t$ incorporate LOESS-diagnosed inflections on aggregate capital stock at 1933, 1947, 1968, 1982, and 2008.}\n", sep = "")
  cat("\\end{tabular}\n")
  cat("\\end{table}\n")
  cat("\\end{landscape}\n")
  
  sink()
}

# 1. Primary Baseline Table (Spec B3 across 6 Centering/Dummy combinations)
primary_sub <- res_df[res_df$Specification == "SpecB3_FullyInteracted" & 
                      res_df$Wage_Measure == "omega_NFC_GVA" & 
                      res_df$Window_Name == "Full_Century_1929_2024", ]

export_specB_journal_table(primary_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_primary.tex"),
                           "Specification B Canonical Journal IM-OLS Matrix (Full Century 1929--2024, Baseline NFC GVA)", "tab:specB_primary")

# 2. Specification Taxonomy Comparison Table (Spec B1 vs Spec B2 vs Spec B3)
spec_comp_sub <- res_df[res_df$Wage_Measure == "omega_NFC_GVA" & 
                        res_df$Window_Name == "Full_Century_1929_2024" &
                        res_df$Centering_Code == "Initial-St", ]
# Order Spec B1, B2, B3 with Dummies then without Dummies
spec_comp_sub <- spec_comp_sub[order(factor(spec_comp_sub$Specification, levels = c("SpecB1_Baseline", "SpecB2_PriceControl", "SpecB3_FullyInteracted")),
                                     factor(spec_comp_sub$Dummy_Code, levels = c("Yes", "No"))), ]

export_specB_journal_table(spec_comp_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_spec_comparison.tex"),
                           "Specification B Model Taxonomy Comparison Matrix (Spec B1 vs. Spec B2 vs. Spec B3, Initial-State Centering)", "tab:specB_spec_comparison", custom_col_width = "1.8cm", show_spec_row = TRUE)

# 3. Accumulation Eras Comparative Matrix (8 columns)
eras_sub <- res_df[res_df$Specification == "SpecB3_FullyInteracted" & 
                   res_df$Wage_Measure == "omega_NFC_GVA" & 
                   res_df$Window_Name %in% c("Long_Fordist_Era_1929_1973", "Long_Post_Fordist_Era_1974_2024") &
                   res_df$Centering_Code %in% c("Initial-St", "Uncentered"), ]

eras_sub <- eras_sub[order(factor(eras_sub$Window_Name, levels = c("Long_Fordist_Era_1929_1973", "Long_Post_Fordist_Era_1974_2024")),
                           factor(eras_sub$Centering_Code, levels = c("Initial-St", "Uncentered")),
                           factor(eras_sub$Dummy_Code, levels = c("Yes", "No"))), ]

export_specB_journal_table(eras_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_eras.tex"),
                           "Specification B Accumulation Eras Comparative Matrix (Fordism 1929--1973 vs. Post-Fordism 1974--2024)", "tab:specB_eras", custom_col_width = "1.5cm")

# 4. Multi-Wage Share Robustness Matrix (8 columns under Initial-State Centering)
wageshares_sub <- res_df[res_df$Specification == "SpecB3_FullyInteracted" & 
                         res_df$Window_Name == "Full_Century_1929_2024" &
                         res_df$Centering_Code == "Initial-St", ]

wageshares_sub <- wageshares_sub[order(factor(wageshares_sub$Wage_Measure, levels = wage_measures),
                                       factor(wageshares_sub$Dummy_Code, levels = c("Yes", "No"))), ]

export_specB_journal_table(wageshares_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_wageshares.tex"),
                           "Specification B Multi-Wage Share Robustness Matrix (Full Century 1929--2024, Initial-State Centering)", "tab:specB_wageshares", custom_col_width = "1.5cm", show_wage_row = TRUE)

# 5. Macro Sub-Window Diagnostic Sensitivity Matrix (8 columns under Initial-State Centering)
diag_windows <- c("Diagnostic_Interwar_WWII_1929_1946", "Diagnostic_Fordist_GoldenAge_1947_1973",
                  "Diagnostic_Neoliberal_Restruct_1974_2008", "Diagnostic_Post_GFC_Stagnation_2009_2024")

diagnostics_sub <- res_df[res_df$Specification == "SpecB3_FullyInteracted" & 
                          res_df$Wage_Measure == "omega_NFC_GVA" & 
                          res_df$Window_Name %in% diag_windows &
                          res_df$Centering_Code == "Initial-St", ]

diagnostics_sub <- diagnostics_sub[order(factor(diagnostics_sub$Window_Name, levels = diag_windows),
                                         factor(diagnostics_sub$Dummy_Code, levels = c("Yes", "No"))), ]

export_specB_journal_table(diagnostics_sub, file.path(rep_tbl_dir, "table_baseline_imols_specB_diagnostics.tex"),
                           "Specification B Macroeconomic Sub-Window Diagnostic Sensitivity Matrix (Initial-State Centering)", "tab:specB_diagnostics", custom_col_width = "1.5cm")

cat("Successfully exported all 5 canonical vertical journal LaTeX tables for Specification B.\n")
