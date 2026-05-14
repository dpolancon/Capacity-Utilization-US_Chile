# 45_dols_spec_grid_cointReg.R
# ==============================================================================
# U.S. DOLS specification grid using cointReg::cointRegD
# Consolidated version:
#   - corrected data provenance
#   - common active window per economic sample
#   - intercept / no-intercept variants
#   - centered / uncentered interaction variants
#   - collinearity diagnostics
#   - threshold classification
#   - stars for all reported coefficients
#   - split outputs:
#       * paper table = S1 only
#       * appendix tables = S2, S3, S4
# ==============================================================================

suppressPackageStartupMessages({
  library(cointReg)
  library(stats)
})

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

outdir <- file.path(REPO, "output/stage_a/us/cointreg_results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Fixed settings
# ------------------------------------------------------------------------------
DOLS_P <- 2L
CR_KERNEL <- "ba"
CR_BANDWIDTH <- 3L

window_order <- c(
  "Full sample",
  "Pre-1974",
  "Post-1973",
  "Fordist core",
  "Deep comparison"
)

# ------------------------------------------------------------------------------
# 2. Helpers
# ------------------------------------------------------------------------------
starify <- function(p) {
  ifelse(is.na(p), "",
         ifelse(p < 0.01, "***",
                ifelse(p < 0.05, "**",
                       ifelse(p < 0.10, "*", ""))))
}

fmt_est <- function(est, stars = "", digits = 4) {
  if (is.na(est)) return("---")
  sprintf(paste0("%.", digits, "f%s"), est, stars)
}

fmt_se <- function(se, digits = 4) {
  if (is.na(se)) return("")
  sprintf(paste0("(%.", digits, "f)"), se)
}

# ------------------------------------------------------------------------------
# 3. Data loading (corrected provenance)
# ------------------------------------------------------------------------------
d_raw <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
nf_inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))

d_raw <- merge(d_raw, nf_inc[, c("year", "Py_fred")], by = "year")
d_raw <- d_raw[order(d_raw$year), ]

Py_2024 <- d_raw$Py_fred[d_raw$year == 2024]
pK_2024 <- d_raw$pK_NF[d_raw$year == 2024]

if (length(Py_2024) != 1L || length(pK_2024) != 1L) {
  stop("Could not uniquely identify 2024 rebasing values for Py_fred and pK_NF.")
}

d_raw$Y_real  <- d_raw$GVA_NF / (d_raw$Py_fred / Py_2024)
d_raw$K_real  <- d_raw$KGC_NF / (d_raw$pK_NF / pK_2024)
d_raw$y_t     <- log(d_raw$Y_real)
d_raw$k_t     <- log(d_raw$K_real)
d_raw$omega_t <- d_raw$Wsh_NF

cat("Repo audit:\n")
cat(sprintf("  Data span: %d-%d (%d obs)\n", min(d_raw$year), max(d_raw$year), nrow(d_raw)))
cat(sprintf("  DOLS package: cointReg::cointRegD\n"))
cat(sprintf("  Leads/lags: p = %d\n", DOLS_P))
cat(sprintf("  Kernel = %s, bandwidth = %s\n\n", CR_KERNEL, as.character(CR_BANDWIDTH)))

# ------------------------------------------------------------------------------
# 4. Economic windows and specs
# ------------------------------------------------------------------------------
windows <- list(
  list(label = "Full sample",     start = 1929, end = 2024),
  list(label = "Pre-1974",        start = 1929, end = 1973),
  list(label = "Post-1973",       start = 1974, end = 2024),
  list(label = "Fordist core",    start = 1945, end = 1973),
  list(label = "Deep comparison", start = 1940, end = 1978)
)

specs <- list(
  list(id = "S1", intercept = TRUE,  centered = FALSE),
  list(id = "S2", intercept = TRUE,  centered = TRUE),
  list(id = "S3", intercept = FALSE, centered = FALSE),
  list(id = "S4", intercept = FALSE, centered = TRUE)
)

# ------------------------------------------------------------------------------
# 5. Common active-window logic
# ------------------------------------------------------------------------------
compute_active_window <- function(df_full, p = DOLS_P) {
  n <- nrow(df_full)
  
  first_idx <- p + 2L
  last_idx  <- n - p
  
  if (first_idx >= last_idx) {
    stop("Active-window trimming leaves no usable observations.")
  }
  
  data.frame(
    regression_start_year = df_full$year[first_idx],
    regression_end_year   = df_full$year[last_idx],
    first_idx = first_idx,
    last_idx  = last_idx,
    N         = last_idx - first_idx + 1L
  )
}

# ------------------------------------------------------------------------------
# 6. Collinearity diagnostics
# ------------------------------------------------------------------------------
compute_collinearity <- function(k_vec, inter_vec, intercept_flag = TRUE) {
  X_lr <- cbind(k = k_vec, interaction = inter_vec)
  
  corr_val <- suppressWarnings(cor(X_lr[, "k"], X_lr[, "interaction"]))
  
  fit_k <- lm(k ~ interaction, data = as.data.frame(X_lr))
  fit_i <- lm(interaction ~ k, data = as.data.frame(X_lr))
  
  vif_k <- 1 / (1 - summary(fit_k)$r.squared)
  vif_i <- 1 / (1 - summary(fit_i)$r.squared)
  
  X_full <- if (intercept_flag) cbind(1, X_lr) else X_lr
  XtX <- crossprod(X_full)
  eig <- eigen(XtX, symmetric = TRUE, only.values = TRUE)$values
  min_eig <- max(min(eig), .Machine$double.eps)
  cond_num <- sqrt(max(eig) / min_eig)
  rank_x <- qr(X_full)$rank
  near_sing <- cond_num > 1000 || rank_x < ncol(X_full)
  
  list(
    corr_longrun_regressors = corr_val,
    VIF_regressor_1 = vif_k,
    VIF_regressor_2 = vif_i,
    condition_number_longrun_X = cond_num,
    smallest_eigenvalue_XtX = min_eig,
    rank_longrun_X = rank_x,
    near_singularity_flag = near_sing
  )
}

# ------------------------------------------------------------------------------
# 7. Threshold classification
# ------------------------------------------------------------------------------
classify_threshold <- function(beta2_hat, beta1_hat, omega_bar,
                               omega_min, omega_max, centered_flag) {
  if (is.na(beta2_hat) || abs(beta2_hat) < 1e-12) {
    return(list(omega_H = NA_real_, status = "slope not identified"))
  }
  if (beta2_hat > 0) {
    return(list(omega_H = NA_real_, status = "wrong-sign slope"))
  }
  
  if (centered_flag) {
    omega_H <- omega_bar + (beta1_hat - 1) / (-beta2_hat)
  } else {
    omega_H <- (beta1_hat - 1) / (-beta2_hat)
  }
  
  if (!is.finite(omega_H) || omega_H <= 0) {
    return(list(omega_H = omega_H, status = "no admissible positive threshold"))
  }
  if (omega_H < omega_min || omega_H > omega_max) {
    return(list(omega_H = omega_H, status = "positive threshold outside observed sample range"))
  }
  
  list(omega_H = omega_H, status = "Harrodian-valid threshold in observed sample range")
}

# ------------------------------------------------------------------------------
# 8. Safe extraction from cointRegD
# ------------------------------------------------------------------------------
extract_cointReg_terms <- function(fit, intercept_flag) {
  term_names <- if (intercept_flag) {
    c("const", "k", "interaction")
  } else {
    c("k", "interaction")
  }
  
  theta_hat <- setNames(as.numeric(fit$theta), term_names)
  se_hat    <- setNames(as.numeric(fit$sd.theta), term_names)
  t_hat     <- setNames(as.numeric(fit$t.theta), term_names)
  p_hat     <- setNames(as.numeric(fit$p.theta), term_names)
  
  list(theta = theta_hat, se = se_hat, t = t_hat, p = p_hat)
}

# ------------------------------------------------------------------------------
# 9. Estimation wrapper
# ------------------------------------------------------------------------------
estimate_spec_cointReg <- function(df_trim, sample_name, economic_start, economic_end,
                                   spec_id, intercept_flag, centered_flag) {
  omega_bar <- mean(df_trim$omega_t)
  
  interaction <- if (centered_flag) {
    (df_trim$omega_t - omega_bar) * df_trim$k_t
  } else {
    df_trim$omega_t * df_trim$k_t
  }
  
  x_mat <- cbind(k = df_trim$k_t, interaction = interaction)
  y_vec <- df_trim$y_t
  
  deter_mat <- if (intercept_flag) {
    matrix(1, nrow = length(y_vec), ncol = 1,
           dimnames = list(NULL, "const"))
  } else {
    NULL
  }
  
  fit <- cointRegD(
    x = x_mat,
    y = y_vec,
    deter = deter_mat,
    kernel = CR_KERNEL,
    bandwidth = CR_BANDWIDTH,
    n.lead = DOLS_P,
    n.lag  = DOLS_P,
    check = TRUE
  )
  
  ext <- extract_cointReg_terms(fit, intercept_flag)
  
  beta1_hat    <- unname(ext$theta["k"])
  beta2_hat    <- unname(ext$theta["interaction"])
  se_beta1     <- unname(ext$se["k"])
  se_beta2     <- unname(ext$se["interaction"])
  t_beta1_hat  <- unname(ext$t["k"])
  t_beta2_hat  <- unname(ext$t["interaction"])
  p_beta1_hat  <- unname(ext$p["k"])
  p_beta2_hat  <- unname(ext$p["interaction"])
  
  const_hat    <- if (intercept_flag) unname(ext$theta["const"]) else NA_real_
  se_const     <- if (intercept_flag) unname(ext$se["const"]) else NA_real_
  t_const_hat  <- if (intercept_flag) unname(ext$t["const"]) else NA_real_
  p_const_hat  <- if (intercept_flag) unname(ext$p["const"]) else NA_real_
  
  thr <- classify_threshold(
    beta2_hat = beta2_hat,
    beta1_hat = beta1_hat,
    omega_bar = omega_bar,
    omega_min = min(df_trim$omega_t),
    omega_max = max(df_trim$omega_t),
    centered_flag = centered_flag
  )
  
  coll <- compute_collinearity(
    k_vec = df_trim$k_t,
    inter_vec = interaction,
    intercept_flag = intercept_flag
  )
  
  data.frame(
    sample_name = sample_name,
    economic_start_year = economic_start,
    economic_end_year = economic_end,
    regression_start_year = min(df_trim$year),
    regression_end_year = max(df_trim$year),
    N = nrow(df_trim),
    spec_id = spec_id,
    intercept_flag = intercept_flag,
    centered_flag = centered_flag,
    interaction_label = ifelse(centered_flag, "(omega_t-omega_bar)k_t", "omega_t k_t"),
    omega_mean = omega_bar,
    omega_min = min(df_trim$omega_t),
    omega_max = max(df_trim$omega_t),
    omega_range = max(df_trim$omega_t) - min(df_trim$omega_t),
    const_hat = const_hat,
    se_const = se_const,
    t_const = t_const_hat,
    p_const = p_const_hat,
    stars_const = starify(p_const_hat),
    beta1_hat = beta1_hat,
    se_beta1 = se_beta1,
    t_beta1 = t_beta1_hat,
    p_beta1 = p_beta1_hat,
    stars_beta1 = starify(p_beta1_hat),
    beta2_hat = beta2_hat,
    se_beta2 = se_beta2,
    t_beta2 = t_beta2_hat,
    p_beta2 = p_beta2_hat,
    stars_beta2 = starify(p_beta2_hat),
    omega_H = thr$omega_H,
    threshold_status = thr$status,
    corr_longrun_regressors = coll$corr_longrun_regressors,
    VIF_regressor_1 = coll$VIF_regressor_1,
    VIF_regressor_2 = coll$VIF_regressor_2,
    condition_number_longrun_X = coll$condition_number_longrun_X,
    smallest_eigenvalue_XtX = coll$smallest_eigenvalue_XtX,
    rank_longrun_X = coll$rank_longrun_X,
    near_singularity_flag = coll$near_singularity_flag,
    stringsAsFactors = FALSE
  )
}

# ------------------------------------------------------------------------------
# 10. Run the 4-spec grid
# ------------------------------------------------------------------------------
all_results <- list()

cat("Running cointRegD specification grid...\n\n")

for (w in windows) {
  df_w <- d_raw[d_raw$year >= w$start & d_raw$year <= w$end, ]
  aw <- compute_active_window(df_w)
  df_trim <- df_w[aw$first_idx:aw$last_idx, ]
  
  cat(sprintf(
    "%-18s economic %d-%d -> active %d-%d (N=%d)\n",
    w$label, w$start, w$end, aw$regression_start_year, aw$regression_end_year, aw$N
  ))
  
  for (sp in specs) {
    res <- estimate_spec_cointReg(
      df_trim = df_trim,
      sample_name = w$label,
      economic_start = w$start,
      economic_end = w$end,
      spec_id = sp$id,
      intercept_flag = sp$intercept,
      centered_flag = sp$centered
    )
    
    all_results[[paste0(w$label, "_", sp$id)]] <- res
    
    cat(sprintf(
      "  %s (%s%s): beta2 = %+.4f%s, t = %+.3f, p = %.4g, status = %s\n",
      sp$id,
      ifelse(sp$intercept, "I", "-"),
      ifelse(sp$centered, "C", "U"),
      res$beta2_hat,
      res$stars_beta2,
      res$t_beta2,
      res$p_beta2,
      res$threshold_status
    ))
  }
  cat("\n")
}

# ------------------------------------------------------------------------------
# 11. Consolidated summary output
# ------------------------------------------------------------------------------
summary_df <- do.call(rbind, all_results)
summary_df$sample_name <- factor(summary_df$sample_name, levels = window_order)
summary_df <- summary_df[order(summary_df$sample_name, summary_df$spec_id), ]

write.csv(
  summary_df,
  file.path(outdir, "dols_spec_grid_cointReg_summary_us.csv"),
  row.names = FALSE
)

cat("Saved: dols_spec_grid_cointReg_summary_us.csv\n\n")

# ------------------------------------------------------------------------------
# 12. Compact console summary
# ------------------------------------------------------------------------------
cat("Package-native DOLS regression summary:\n")
cat(sprintf(
  "%-18s %-3s %4s %10s %10s %10s %10s %8s %s\n",
  "Sample", "Sp", "N", "const", "beta1", "beta2", "se(beta2)", "t", "stars"
))
cat(strrep("-", 95), "\n")

for (i in seq_len(nrow(summary_df))) {
  r <- summary_df[i, ]
  const_txt <- ifelse(is.na(r$const_hat), "", sprintf("%.4f", r$const_hat))
  cat(sprintf(
    "%-18s %-3s %4d %10s %10.4f %10.4f %10.4f %8.2f %s\n",
    as.character(r$sample_name), r$spec_id, r$N,
    const_txt, r$beta1_hat, r$beta2_hat, r$se_beta2, r$t_beta2, r$stars_beta2
  ))
}

# ------------------------------------------------------------------------------
# 13. Split outputs: paper table (S1) and appendix tables (S2-S4)
# ------------------------------------------------------------------------------
paper_df <- subset(summary_df, spec_id == "S1")
appendix_df <- subset(summary_df, spec_id %in% c("S2", "S3", "S4"))

write.csv(paper_df, file.path(outdir, "paper_table_us_s1.csv"), row.names = FALSE)
write.csv(appendix_df, file.path(outdir, "appendix_tables_us_s2_s4.csv"), row.names = FALSE)

# ------------------------------------------------------------------------------
# 14. LaTeX builders
# ------------------------------------------------------------------------------
make_panel_lines <- function(df_spec, panel_title, beta2_label, include_const = TRUE) {
  df_spec <- df_spec[match(window_order, as.character(df_spec$sample_name)), ]
  
  lines <- c(
    sprintf("\\multicolumn{6}{l}{\\textit{%s}} \\\\", panel_title)
  )
  
  if (include_const) {
    lines <- c(
      lines,
      paste0("$\\delta$ & ",
             paste(mapply(fmt_est, df_spec$const_hat, df_spec$stars_const), collapse = " & "),
             " \\\\"),
      paste0(" & ",
             paste(vapply(df_spec$se_const, fmt_se, character(1)), collapse = " & "),
             " \\\\")
    )
  }
  
  lines <- c(
    lines,
    paste0("$\\beta_1$ on $k_t$ & ",
           paste(mapply(fmt_est, df_spec$beta1_hat, df_spec$stars_beta1), collapse = " & "),
           " \\\\"),
    paste0(" & ",
           paste(vapply(df_spec$se_beta1, fmt_se, character(1)), collapse = " & "),
           " \\\\"),
    paste0(beta2_label, " & ",
           paste(mapply(fmt_est, df_spec$beta2_hat, df_spec$stars_beta2), collapse = " & "),
           " \\\\"),
    paste0(" & ",
           paste(vapply(df_spec$se_beta2, fmt_se, character(1)), collapse = " & "),
           " \\\\"),
    paste0("$N$ & ", paste(df_spec$N, collapse = " & "), " \\\\")
  )
  
  lines
}

# ------------------------------------------------------------------------------
# 15. Paper LaTeX table: S1 only
# ------------------------------------------------------------------------------
paper_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{U.S. DOLS cointegrating regressions as estimated: main specification}",
  "\\label{tab:us_dols_main_s1}",
  "\\small",
  "\\begin{tabular}{lccccc}",
  "\\hline",
  " & Full sample & Pre-1974 & Post-1973 & Fordist core & Deep comparison \\\\",
  "\\hline"
)

paper_lines <- c(
  paper_lines,
  make_panel_lines(
    df_spec = paper_df,
    panel_title = "Panel A. S1: intercept + uncentered",
    beta2_label = "$\\beta_2$ on $\\omega_t k_t$",
    include_const = TRUE
  ),
  "\\hline",
  "\\multicolumn{6}{l}{\\footnotesize Standard errors in parentheses.} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize Estimates from \\texttt{cointRegD}, $p=2$, Bartlett kernel, fixed bandwidth = 3.} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize Stars: $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(paper_lines, file.path(outdir, "paper_table_us_s1.tex"))

# ------------------------------------------------------------------------------
# 16. Appendix LaTeX table: S2, S3, S4
# ------------------------------------------------------------------------------
s2_df <- subset(appendix_df, spec_id == "S2")
s3_df <- subset(appendix_df, spec_id == "S3")
s4_df <- subset(appendix_df, spec_id == "S4")

appendix_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{U.S. DOLS cointegrating regressions: alternative parameterizations and restrictions}",
  "\\label{tab:us_dols_appendix_s2_s4}",
  "\\scriptsize",
  "\\begin{tabular}{lccccc}",
  "\\hline",
  " & Full sample & Pre-1974 & Post-1973 & Fordist core & Deep comparison \\\\",
  "\\hline"
)

appendix_lines <- c(
  appendix_lines,
  make_panel_lines(
    df_spec = s2_df,
    panel_title = "Panel B. S2: intercept + centered",
    beta2_label = "$\\beta_2$ on $(\\omega_t-\\bar\\omega)k_t$",
    include_const = TRUE
  ),
  "\\hline",
  make_panel_lines(
    df_spec = s3_df,
    panel_title = "Panel C. S3: no intercept + uncentered",
    beta2_label = "$\\beta_2$ on $\\omega_t k_t$",
    include_const = FALSE
  ),
  "\\hline",
  make_panel_lines(
    df_spec = s4_df,
    panel_title = "Panel D. S4: no intercept + centered",
    beta2_label = "$\\beta_2$ on $(\\omega_t-\\bar\\omega)k_t$",
    include_const = FALSE
  ),
  "\\hline",
  "\\multicolumn{6}{l}{\\footnotesize Standard errors in parentheses.} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize Estimates from \\texttt{cointRegD}, $p=2$, Bartlett kernel, fixed bandwidth = 3.} \\\\",
  "\\multicolumn{6}{l}{\\footnotesize Stars: $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$.} \\\\",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(appendix_lines, file.path(outdir, "appendix_tables_us_s2_s4.tex"))

# ------------------------------------------------------------------------------
# 17. Collinearity sheet export
# ------------------------------------------------------------------------------
coll_df <- summary_df[, c(
  "sample_name", "economic_start_year", "economic_end_year",
  "regression_start_year", "regression_end_year", "N", "spec_id",
  "intercept_flag", "centered_flag", "interaction_label",
  "omega_mean", "omega_min", "omega_max", "omega_range",
  "corr_longrun_regressors", "VIF_regressor_1", "VIF_regressor_2",
  "condition_number_longrun_X", "smallest_eigenvalue_XtX",
  "rank_longrun_X", "near_singularity_flag"
)]

write.csv(coll_df, file.path(outdir, "dols_spec_grid_cointReg_collinearity_us.csv"), row.names = FALSE)

# ------------------------------------------------------------------------------
# 18. Final audit
# ------------------------------------------------------------------------------
cat("\nSaved split-output files:\n")
cat(sprintf("  - %s\n", file.path(outdir, "dols_spec_grid_cointReg_summary_us.csv")))
cat(sprintf("  - %s\n", file.path(outdir, "paper_table_us_s1.csv")))
cat(sprintf("  - %s\n", file.path(outdir, "appendix_tables_us_s2_s4.csv")))
cat(sprintf("  - %s\n", file.path(outdir, "dols_spec_grid_cointReg_collinearity_us.csv")))
cat(sprintf("  - %s\n", file.path(outdir, "paper_table_us_s1.tex")))
cat(sprintf("  - %s\n", file.path(outdir, "appendix_tables_us_s2_s4.tex")))