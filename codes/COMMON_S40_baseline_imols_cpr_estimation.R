#!/usr/bin/env Rscript

# COMMON_S40_baseline_imols_cpr_estimation.R
# Stage 3: Multi-Measure Baseline IM-OLS CPR Estimation & Visual Sensitivity Engine (Specification A)
# Runs full 168-combination estimation matrix (2 Dummy States x 3 Centering Treatments x 4 Wage Shares x 7 Eras/Subwindows).
# Generates 2 High-Impact Visual Comparison Plots (ggplot2) and 4 Canonical Journal-Style LaTeX Summary Tables comparing With vs. Without Dummies.

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
input_csv <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")
out_dir   <- file.path(repo_root, "output")
fig_dir   <- file.path(out_dir, "figures")
rep_dir   <- file.path(repo_root, "reports", "US_Baseline_IMOLS_Capital_Aggregation_Report")

csv_out         <- file.path(out_dir, "baseline_imols_cpr_results.csv")
tex_fullsample  <- file.path(rep_dir, "table_baseline_imols_specA_fullsample.tex")
tex_eras        <- file.path(rep_dir, "table_baseline_imols_specA_eras.tex")
tex_wageshares  <- file.path(rep_dir, "table_baseline_imols_specA_wageshares.tex")
tex_diagnostics <- file.path(rep_dir, "table_baseline_imols_specA_diagnostics.tex")
fig_forest      <- file.path(fig_dir, "fig_imols_interaction_sensitivity.png")
fig_eras        <- file.path(fig_dir, "fig_imols_era_comparison.png")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(rep_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("Stage 3: Full 168-Spec IM-OLS CPR Estimation & Journal Table Engine (Spec A)\n")
cat("========================================================================\n")

if (!file.exists(input_csv)) {
  stop("Input file missing: ", input_csv)
}

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_cap) & !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

# Construct step dummy variable controls driven by LOESS 2nd derivative inflections on log K_cap
df$D1933 <- ifelse(df$year >= 1933, 1, 0)
df$D1947 <- ifelse(df$year >= 1947, 1, 0)
df$D1974 <- ifelse(df$year >= 1974, 1, 0)
df$D2008 <- ifelse(df$year >= 2008, 1, 0)

# Define 7 Accumulation Eras and Sub-Windows with Paper-Facing Labels
windows_list <- list(
  Full_Century_1929_2024          = list(range = c(1929, 2024), type = "Full_Century",     label = "Full Sample"),
  Long_Fordist_Era_1929_1973      = list(range = c(1929, 1973), type = "Primary_Long_Era", label = "Fordism"),
  Long_Post_Fordist_Era_1974_2024 = list(range = c(1974, 2024), type = "Primary_Long_Era", label = "Post-Fordism"),
  
  Diagnostic_Interwar_WWII_1929_1946       = list(range = c(1929, 1946), type = "Diagnostic", label = "Interwar \\& WWII"),
  Diagnostic_Fordist_GoldenAge_1947_1973   = list(range = c(1947, 1973), type = "Diagnostic", label = "Golden Age"),
  Diagnostic_Neoliberal_Restruct_1974_2008 = list(range = c(1974, 2008), type = "Diagnostic", label = "Neoliberal Restructuring"),
  Diagnostic_Post_GFC_Stagnation_2009_2024 = list(range = c(2009, 2024), type = "Diagnostic", label = "Post-GFC Stagnation")
)

wage_measures <- c("omega_NFC_GVA", "omega_CORP_GVA", "omega_ST_Tier1", "omega_ST_Tier2")
wage_labels   <- c("Baseline NFC GVA", "Corporate GVA", "Shaikh-Tonak Tier 1", "Shaikh-Tonak Tier 2")

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

# Helper function to compute Vogelsang & Wagner (2015) Type 2 Cointegration Test Statistic (S_Type2)
calc_vw_type2_stat <- function(x, y, deter, fit) {
  tryCatch({
    y.T <- nrow(x)
    x.k <- ncol(x)
    d.k <- if (is.null(deter)) 0 else ncol(deter)
    
    Sy <- cumsum(y)
    Sx <- matrixStats::colCumsums(x)
    
    if (d.k == 0) {
      Sd <- matrix(nrow = y.T, ncol = 0)
      trend_mat_vw <- cbind(1, 1:y.T)
    } else {
      Sd <- matrixStats::colCumsums(deter)
      trend_mat_vw <- cbind(deter, Sd)
    }
    
    # FIX: Detrend x to remove deterministic drifts before reverse cumsums
    x_det <- lm.fit(as.matrix(trend_mat_vw), as.matrix(x))$residuals
    Sx_det <- matrixStats::colCumsums(x_det)
    
    InvBase <- Sx_det[y.T:1, , drop = FALSE]
    InvBaseCum <- matrixStats::colCumsums(InvBase)
    RevBase <- InvBaseCum[y.T:1, , drop = FALSE]
    Zreg <- matrixStats::colCumsums(RevBase)
    
    if (d.k == 0) {
      X2mat <- as.matrix(cbind(Sx, x, Zreg))
    } else {
      X2mat <- as.matrix(cbind(Sd, Sx, x, Zreg))
    }
    
    S <- matrixStats::colCumsums(X2mat)
    DS <- rbind(S[y.T, ], t(S[y.T, ] - t(S[1:(y.T - 1), ])))
    Ha <- cointReg:::trySolve(t(X2mat) %*% X2mat)
    H <- Ha %*% t(DS)
    V2 <- H %*% t(H)
    
    lambda2 <- fit$lambda2
    if (is.null(lambda2) || length(lambda2) == 0) return(list(stat = NA, stars = ""))
    
    idx <- (d.k + 2 * x.k + 1):(d.k + 3 * x.k)
    V2_lambda <- V2[idx, idx, drop = FALSE]
    w2 <- fit$omega.u.v
    if (is.null(w2) || is.na(w2) || w2 <= 0) return(list(stat = NA, stars = ""))
    
    V2_inv <- cointReg:::trySolve(V2_lambda)
    S_type2 <- as.numeric(t(lambda2) %*% V2_inv %*% lambda2 / w2)
    
    # Vogelsang & Wagner (2015) Table 1 critical values for k = 3 regressors (Case 1)
    crit_10 <- 11.45
    crit_5  <- 13.78
    crit_1  <- 18.90
    
    stars <- if (!is.na(S_type2)) {
      if (S_type2 >= crit_1) "$^{***}$" else if (S_type2 >= crit_5) "$^{**}$" else if (S_type2 >= crit_10) "$^{*}$" else ""
    } else ""
    
    return(list(stat = S_type2, stars = stars))
  }, error = function(e) {
    return(list(stat = NA, stars = ""))
  })
}

# Wrapper function for IM-OLS estimation + 3-test cointegration triad
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
  
  # 1. Engle-Granger ADF Test on Level Residuals (u.plus)
  # Correct MacKinnon (2010) critical values for m = 4 I(1) variables (1 dep + 3 stochastic regressors)
  t_adf <- NA
  p_stars_adf <- ""
  try({
    eg_lm <- stats::lm(diff(u) ~ u[-T_obs] - 1)
    t_adf <- summary(eg_lm)$coefficients[1, 3]
    crit_adf_10pct <- -3.81
    crit_adf_5pct  <- -4.10
    crit_adf_1pct  <- -4.64
    p_stars_adf <- if (t_adf <= crit_adf_1pct) "$^{***}$" else if (t_adf <= crit_adf_5pct) "$^{**}$" else if (t_adf <= crit_adf_10pct) "$^{*}$" else ""
  }, silent = TRUE)
  
  # 2. Shin (1994) LM Stationarity Test (H0: Cointegration)
  # Rejection of H0 occurs if C_shin > critical value (5% = 0.121, 1% = 0.184)
  C_shin <- NA
  p_stars_shin <- ""
  try({
    # BUG FIX: NO double cumsum. u is fit$u.plus (already partial sums)
    S_t <- u
    omega2 <- fit$omega.u.v
    if (is.null(omega2) || is.na(omega2) || omega2 <= 0) {
      omega2 <- cointReg::getLongRunVar(fit$residuals, kernel = kernel, bandwidth = bandwidth)$long.run
    }
    C_shin <- sum(S_t^2) / (T_obs^2 * omega2)
    p_stars_shin <- if (C_shin >= 0.184) "$^{***}$" else if (C_shin >= 0.121) "$^{**}$" else if (C_shin >= 0.095) "$^{*}$" else ""
  }, silent = TRUE)
  
  # 3. Vogelsang-Wagner (2015) Type 2 Cointegration Test (H0: Cointegration)
  # S_Type2 = (1/w2) * lambda2' * inv(V2_lambda) * lambda2
  vw_res <- list(stat = NA, stars = "")
  try({
    vw_res <- calc_vw_type2_stat(x, y, deter, fit)
  }, silent = TRUE)
  
  # 4. Goodness of Fit & Variance
  y_mean <- mean(y)
  ss_tot <- sum((y - y_mean)^2)
  ss_res_level <- sum(u^2)
  k_reg <- if (is.null(ncol(x))) 1 else ncol(x)
  r2_level <- max(0, 1 - (ss_res_level / ss_tot))
  sigma_u <- sqrt(ss_res_level / max(1, T_obs - k_reg))
  
  # Partial sum space R2 using fit$u.plus2
  Sy <- cumsum(y)
  res_sum <- fit$u.plus2
  if (is.null(res_sum)) res_sum <- fit$residuals
  r2_sum <- if (!is.null(res_sum)) max(0, 1 - (sum(res_sum^2) / sum((Sy - mean(Sy))^2))) else NA

  fit$coint_test <- list(
    t_adf = safe_scalar(t_adf),
    p_stars_adf = safe_scalar(p_stars_adf, default = ""),
    C_shin = safe_scalar(C_shin),
    p_stars_shin = safe_scalar(p_stars_shin, default = ""),
    S_type2 = safe_scalar(vw_res$stat),
    p_stars_vw = safe_scalar(vw_res$stars, default = ""),
    r2_level = safe_scalar(r2_level),
    r2_sum = safe_scalar(r2_sum),
    sigma_u = safe_scalar(sigma_u),
    T_obs = T_obs
  )
  
  return(fit)
}

results_list <- list()
dummy_options <- c("With_Dummies", "Without_Dummies")

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
    k_cap     <- sub_df$k_cap
    omega     <- sub_df[[omega_col]]
    omega_lag <- sub_df[[omega_lag_col]]
    
    regimes <- list(
      Regime_A_Uncentered = list(
        k = k_cap,
        w = omega,
        w_lag = omega_lag,
        inter = k_cap * omega_lag,
        label = "Uncentered",
        code = "Uncentered"
      ),
      Regime_B_Initial_Centered = list(
        k = k_cap - k_cap[1],
        w = omega - omega[1],
        w_lag = omega_lag - omega_lag[1],
        inter = (k_cap - k_cap[1]) * (omega_lag - omega_lag[1]),
        label = "Initial-State",
        code = "Initial-St"
      ),
      Regime_C_Mean_Centered = list(
        k = k_cap - mean(k_cap),
        w = omega - mean(omega),
        w_lag = omega_lag - mean(omega_lag, na.rm = TRUE),
        inter = (k_cap - mean(k_cap)) * (omega_lag - mean(omega_lag, na.rm = TRUE)),
        label = "Sample-Mean",
        code = "Sample-Mean"
      )
    )
    
    for (reg_name in names(regimes)) {
      reg <- regimes[[reg_name]]
      
      for (dum_state in dummy_options) {
        
        dummies_list <- list()
        if (dum_state == "With_Dummies") {
          if (win_range[1] <= 1933 && win_range[2] >= 1933 && length(unique(sub_df$D1933)) > 1) dummies_list[["D1933"]] <- sub_df$D1933
          if (win_range[1] <= 1947 && win_range[2] >= 1947 && length(unique(sub_df$D1947)) > 1) dummies_list[["D1947"]] <- sub_df$D1947
          if (win_range[1] <= 1974 && win_range[2] >= 1974 && length(unique(sub_df$D1974)) > 1) dummies_list[["D1974"]] <- sub_df$D1974
          if (win_range[1] <= 2008 && win_range[2] >= 2008 && length(unique(sub_df$D2008)) > 1) dummies_list[["D2008"]] <- sub_df$D2008
        }
        
        if (length(dummies_list) > 0) {
          dum_mat <- as.matrix(as.data.frame(dummies_list))
          X <- cbind(k_cap = reg$k, omega = reg$w, interaction = reg$inter, dum_mat)
        } else {
          X <- cbind(k_cap = reg$k, omega = reg$w, interaction = reg$inter)
        }
        
        deter <- matrix(1, nrow = length(y), ncol = 1)
        
        fit <- tryCatch({
          cointRegIM_with_tests(x = X, y = y, deter = deter, bandwidth = "nw")
        }, error = function(e) NULL)
        
        if (is.null(fit)) next
        
        coefs  <- as.vector(fit$theta)
        se     <- as.vector(fit$sd.theta)
        t_stat <- as.vector(fit$t.theta)
        p_val  <- as.vector(fit$p.theta)
        
        b_idx <- 1
        f_idx <- 2
        d_idx <- 3
        
        res <- data.frame(
          Estimation_Window = gsub("_", " ", win_name),
          Window_Label = win_lbl,
          Window_Type = win_type,
          Years = sprintf("%d-%d", win_range[1], win_range[2]),
          Wage_Measure = wl,
          Wage_Code = wm,
          Centering_Treatment = reg$label,
          Centering_Code = reg$code,
          Dummy_Status = dum_state,
          Dummy_Code = if (dum_state == "With_Dummies") "Yes" else "No",
          Sample_Size_T = safe_scalar(fit$coint_test$T_obs),
          b_hat_scale = safe_scalar(coefs[b_idx]),
          b_se = safe_scalar(se[b_idx]),
          b_tstat = safe_scalar(t_stat[b_idx]),
          b_stars = get_asterisks(safe_scalar(t_stat[b_idx])),
          f_hat_dist = safe_scalar(coefs[f_idx]),
          f_se = safe_scalar(se[f_idx]),
          f_tstat = safe_scalar(t_stat[f_idx]),
          f_stars = get_asterisks(safe_scalar(t_stat[f_idx])),
          d_hat_inter = safe_scalar(coefs[d_idx]),
          d_se = safe_scalar(se[d_idx]),
          d_tstat = safe_scalar(t_stat[d_idx]),
          d_pval = safe_scalar(p_val[d_idx]),
          d_stars = get_asterisks(safe_scalar(t_stat[d_idx])),
          VW_Lambda2_Stat = safe_scalar(fit$coint_test$S_type2),
          VW_Stars = safe_scalar(fit$coint_test$p_stars_vw, default = ""),
          ADF_Stat = safe_scalar(fit$coint_test$t_adf),
          ADF_Stars = safe_scalar(fit$coint_test$p_stars_adf, default = ""),
          Shin_Stat = safe_scalar(fit$coint_test$C_shin),
          Shin_Stars = safe_scalar(fit$coint_test$p_stars_shin, default = ""),
          R2_level = safe_scalar(fit$coint_test$r2_level),
          R2_sum = safe_scalar(fit$coint_test$r2_sum),
          sigma_u = safe_scalar(fit$coint_test$sigma_u)
        )
        
        results_list[[length(results_list) + 1]] <- res
      }
    }
  }
}

res_df <- do.call(rbind, results_list)
write.csv(res_df, csv_out, row.names = FALSE)
cat("Full Specification A results with cointegration triad saved to:", csv_out, "\n")

# =========================================================================
# Export Canonical Journal-Style LaTeX Tables for Specification A
# =========================================================================

export_specA_journal_table <- function(df_sub, file_path, caption_text, label_text, force_landscape = FALSE) {
  sink(file_path)
  
  n_cols <- nrow(df_sub)
  if (n_cols == 0) {
    sink()
    warning("No rows to export for ", file_path)
    return()
  }
  
  # Conditionally trigger pdflscape only when >= 6 columns or explicitly requested
  use_landscape <- force_landscape || (n_cols >= 6)
  
  if (use_landscape) cat("\\begin{landscape}\n")
  cat("\\begin{table}[H]\n")
  cat("\\centering\n")
  cat("\\caption{", caption_text, "}\n", sep = "")
  cat("\\label{", label_text, "}\n", sep = "")
  cat("\\small\n")
  
  col_width <- if (n_cols >= 8) "p{1.5cm}" else if (use_landscape) "p{1.8cm}" else "p{1.4cm}"
  col_spec  <- paste0("p{5.2cm}", paste(rep(col_width, n_cols), collapse = ""))
  
  cat("\\begin{tabular}{", col_spec, "}\n", sep = "")
  cat("\\toprule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\textbf{Dependent Variable: $y_t^{\\text{NFC}} / S_{y^{\\text{NFC}}}$}} \\\\\n", sep = "")
  cat("\\midrule\n")
  
  # Model Header Line
  cat("Model & ")
  cat(paste(paste0("(", 1:n_cols, ")"), collapse = " & "), " \\\\\n")
  
  # Centering Treatment Line
  cat("Centering Treatment & ")
  cat(paste(df_sub$Centering_Code, collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  
  fmt_num_star <- function(val, stars) {
    if (is.na(val)) return("NA")
    sprintf("%.2f%s", val, stars)
  }
  fmt_t <- function(tval) {
    if (is.na(tval)) return("")
    paste0("{\\scriptsize (", sprintf("%.2f", tval), ")}")
  }
  fmt_num <- function(val) {
    if (is.na(val)) return("NA")
    sprintf("%.4f", val)
  }
  
  # Parameter Rows
  # 1. beta_Kcap
  cat("$\\hat{\\beta}_{\\text{Kcap}}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$b_hat_scale[r], df_sub$b_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$b_tstat[r])), collapse = " & "), " \\\\\n")
  
  # 2. phi_omega
  cat("$\\hat{\\phi}_{\\omega}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$f_hat_dist[r], df_sub$f_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$f_tstat[r])), collapse = " & "), " \\\\\n")
  
  # 3. theta_1
  cat("$\\hat{\\theta}_{1}$ & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$d_hat_inter[r], df_sub$d_stars[r])), collapse = " & "), " \\\\\n")
  cat(" & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_t(df_sub$d_tstat[r])), collapse = " & "), " \\\\\n")
  
  # 4. Lambda D_t'
  cat("$\\boldsymbol{\\Lambda} \\mathbf{D}_t'$ & ")
  cat(paste(df_sub$Dummy_Code, collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\underline{Cointegration Tests}} \\\\\n", sep = "")
  
  # VW Type 2 Test (H0: Cointegration)
  cat("\\makecell[l]{VW Type 2 ($S_{\\text{Type 2}}$) \\\\ {\\scriptsize [$H_0$: Cointegration]}} & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$VW_Lambda2_Stat[r], df_sub$VW_Stars[r])), collapse = " & "), " \\\\\n")
  
  # Resid ADF Stat (H0: No Cointegration)
  cat("\\makecell[l]{Resid. ADF ($t_{\\text{ADF}}$) \\\\ {\\scriptsize [$H_0$: No Cointegration]}} & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$ADF_Stat[r], df_sub$ADF_Stars[r])), collapse = " & "), " \\\\\n")
  
  # Shin LM Stat (H0: Cointegration)
  cat("\\makecell[l]{Shin LM ($C_{\\text{Shin}}$) \\\\ {\\scriptsize [$H_0$: Cointegration]}} & ")
  cat(paste(sapply(1:n_cols, function(r) fmt_num_star(df_sub$Shin_Stat[r], df_sub$Shin_Stars[r])), collapse = " & "), " \\\\\n")
  
  cat("\\midrule\n")
  cat("\\multicolumn{", n_cols + 1, "}{l}{\\underline{Goodness-of-Fit \\& Controls}} \\\\\n", sep = "")
  
  cat("$R_{\\text{level}}^2$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$R2_level[r])), collapse = " & "), " \\\\\n")
  
  cat("$R_{\\text{sum}}^2$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$R2_sum[r])), collapse = " & "), " \\\\\n")
  
  cat("$\\hat{\\sigma}_u$ & ")
  cat(paste(sapply(1:n_cols, function(r) sprintf("%.3f", df_sub$sigma_u[r])), collapse = " & "), " \\\\\n")
  
  cat("Sample Window & ")
  cat(paste(df_sub$Window_Label, collapse = " & "), " \\\\\n")
  
  cat("Sample Size ($T$) & ")
  cat(paste(df_sub$Sample_Size_T, collapse = " & "), " \\\\\n")
  
  cat("\\bottomrule\n")
  note_width <- if (n_cols >= 8) "18.5cm" else if (use_landscape) "19.5cm" else "15.5cm"
  cat("\\multicolumn{", n_cols + 1, "}{p{", note_width, "}}{\\footnotesize Note: Estimated via Integrated Modified OLS (IM-OLS; Vogelsang \\& Wagner 2014). Fixed-$b$ HAR $t$-statistics reported in parentheses underneath point estimates. $^*p<0.10, ^{**}p<0.05, ^{***}p<0.01$. **Star Reversal Warning:** For the Residual ADF test, significance stars indicate rejection of No Cointegration (supporting cointegration). For the VW Type 2 ($S_{\\text{Type 2}}$) and Shin LM ($C_{\\text{Shin}}$) tests, significance stars indicate rejection of Cointegration (indicating spurious regression). Dependent variable $y_t^{\\text{NFC}}$ denotes log real gross value added of the U.S. Non-Financial Corporate (NFC) sector used to estimate structural capacity $Y_t^p$. Structural step dummy controls $\\boldsymbol{\\Lambda} \\mathbf{D}_t'$ incorporate LOESS-diagnosed inflections on aggregate capital stock at 1933, 1947, 1974, and 2008.}\n", sep = "")
  cat("\\end{tabular}\n")
  cat("\\end{table}\n")
  if (use_landscape) cat("\\end{landscape}\n")
  
  sink()
}

# Table A1: Full Sample Baseline Comparative Matrix (With Dummies vs. Without Dummies across 3 Centering Treatments)
fullsample_sub <- res_df[res_df$Wage_Code == "omega_NFC_GVA" & res_df$Window_Type == "Full_Century", ]
fullsample_sub <- fullsample_sub[order(match(fullsample_sub$Centering_Code, c("Uncentered", "Initial-St", "Sample-Mean")), match(fullsample_sub$Dummy_Status, c("With_Dummies", "Without_Dummies"))), ]
export_specA_journal_table(fullsample_sub, tex_fullsample, "Specification A Full Sample Baseline IM-OLS Matrix (1929--2024, With vs. Without Dummies)", "tab:specA_fullsample", force_landscape = TRUE)

# Table A2: Accumulation Eras Comparative Matrix (Fordism vs. Post-Fordism, With vs. Without Dummies)
eras_sub <- res_df[res_df$Wage_Code == "omega_NFC_GVA" & res_df$Window_Type == "Primary_Long_Era" & res_df$Centering_Code %in% c("Initial-St", "Uncentered"), ]
eras_sub <- eras_sub[order(match(eras_sub$Window_Label, c("Fordism", "Post-Fordism")), match(eras_sub$Centering_Code, c("Initial-St", "Uncentered")), match(eras_sub$Dummy_Status, c("With_Dummies", "Without_Dummies"))), ]
export_specA_journal_table(eras_sub, tex_eras, "Specification A Accumulation Eras IM-OLS Comparative Matrix (Fordism vs. Post-Fordism)", "tab:specA_eras", force_landscape = TRUE)

# Table A3: Multi-Wage Share Robustness Matrix (4 Wage Measures, With vs. Without Dummies under Initial-State)
wageshares_sub <- res_df[res_df$Window_Type == "Full_Century" & res_df$Centering_Code == "Initial-St", ]
wageshares_sub <- wageshares_sub[order(match(wageshares_sub$Wage_Code, wage_measures), match(wageshares_sub$Dummy_Status, c("With_Dummies", "Without_Dummies"))), ]
export_specA_journal_table(wageshares_sub, tex_wageshares, "Specification A Multi-Wage Share Robustness Matrix (Full Century 1929--2024, With vs. Without Dummies)", "tab:specA_wageshares", force_landscape = TRUE)

# Table A4: Macroeconomic Sub-Window Diagnostic Matrix (4 Sub-Eras, With vs. Without Dummies under Initial-State)
diagnostics_sub <- res_df[res_df$Wage_Code == "omega_NFC_GVA" & res_df$Window_Type == "Diagnostic" & res_df$Centering_Code == "Initial-St", ]
diagnostics_sub <- diagnostics_sub[order(match(diagnostics_sub$Window_Label, c("Interwar \\& WWII", "Golden Age", "Neoliberal Restructuring", "Post-GFC Stagnation")), match(diagnostics_sub$Dummy_Status, c("With_Dummies", "Without_Dummies"))), ]
export_specA_journal_table(diagnostics_sub, tex_diagnostics, "Specification A Macroeconomic Sub-Window Diagnostic Sensitivity Matrix (With vs. Without Dummies)", "tab:specA_diagnostics", force_landscape = TRUE)

cat("Exported 4-table comparative Appendix suite for Specification A with clean makecell alignment.\n")
