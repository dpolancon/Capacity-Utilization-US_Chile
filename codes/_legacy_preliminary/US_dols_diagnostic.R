# 46_us_dols_stress_test_registry.R
# ==============================================================================
# U.S. DOLS stress test registry
#   1) rolling-window collinearity / VIF registry
#   2) lead-lag sensitivity registry
# Diagnostic only: flags, no automatic exclusion
# ==============================================================================

suppressPackageStartupMessages({
  library(cointReg)
  library(stats)
})

# ------------------------------------------------------------------------------
# 0. Paths and run folder
# ------------------------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")
BEA  <- Sys.getenv("BEA_REPO", unset = "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset")

run_id <- format(Sys.time(), "%Y%m%d_%H%M%S")

outdir <- file.path(REPO, "output", "US_dols_diagnostics")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Fixed settings
# ------------------------------------------------------------------------------
CR_KERNEL    <- "ba"
CR_BANDWIDTH <- 3L

# Baseline DOLS augmentation used in the rolling registry
BASE_N_LEAD <- 2L
BASE_N_LAG  <- 2L

# Rolling-window setup
ROLL_WIDTHS <- c(25L, 35L)
ROLL_STEP   <- 1L

# Lead-lag sensitivity grid
LEAD_GRID <- 0:4
LAG_GRID  <- 0:4

# Design flags: leverage only, no binding exclusions
VIF_WARN_1  <- 5
VIF_WARN_2  <- 10
COND_WARN_1 <- 30
COND_WARN_2 <- 100
COND_WARN_3 <- 1000

window_order <- c(
  "Full sample",
  "Pre-1974",
  "Post-1973",
  "Fordist core",
  "Deep comparison"
)

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
# 2. Helpers
# ------------------------------------------------------------------------------
safe_cor <- function(x, y) {
  out <- suppressWarnings(cor(x, y, use = "complete.obs"))
  if (!is.finite(out)) NA_real_ else out
}

safe_vif <- function(lhs, rhs) {
  fit <- tryCatch(lm(lhs ~ rhs), error = function(e) NULL)
  if (is.null(fit)) return(NA_real_)
  rsq <- tryCatch(summary(fit)$r.squared, error = function(e) NA_real_)
  if (!is.finite(rsq)) return(NA_real_)
  if ((1 - rsq) <= .Machine$double.eps) return(Inf)
  1 / (1 - rsq)
}

design_flag <- function(max_vif, cond_num, near_singularity_flag) {
  if (isTRUE(near_singularity_flag) || isTRUE(cond_num > COND_WARN_3)) {
    return("near-singular")
  }
  if (is.finite(max_vif) && max_vif > VIF_WARN_2) {
    return("high-VIF")
  }
  if (is.finite(max_vif) && max_vif > VIF_WARN_1) {
    return("moderate-VIF")
  }
  if (is.finite(cond_num) && cond_num > COND_WARN_2) {
    return("high-condition-number")
  }
  if (is.finite(cond_num) && cond_num > COND_WARN_1) {
    return("moderate-condition-number")
  }
  "ok"
}

compute_active_window <- function(df_full, n.lead, n.lag) {
  n <- nrow(df_full)
  
  # first usable row must allow:
  #   - one lag to build Delta x
  #   - n.lag lagged Delta x terms
  # last usable row must allow n.lead lead Delta x terms
  first_idx <- n.lag + 2L
  last_idx  <- n - n.lead
  
  if (first_idx >= last_idx) return(NULL)
  
  data.frame(
    regression_start_year = df_full$year[first_idx],
    regression_end_year   = df_full$year[last_idx],
    first_idx = first_idx,
    last_idx  = last_idx,
    N = last_idx - first_idx + 1L
  )
}

compute_collinearity <- function(k_vec, inter_vec, intercept_flag = TRUE) {
  X_lr <- cbind(k = k_vec, interaction = inter_vec)
  
  corr_val <- safe_cor(X_lr[, "k"], X_lr[, "interaction"])
  vif_k    <- safe_vif(X_lr[, "k"], X_lr[, "interaction"])
  vif_i    <- safe_vif(X_lr[, "interaction"], X_lr[, "k"])
  
  X_full <- if (intercept_flag) cbind(1, X_lr) else X_lr
  XtX <- crossprod(X_full)
  
  eig <- tryCatch(
    eigen(XtX, symmetric = TRUE, only.values = TRUE)$values,
    error = function(e) rep(NA_real_, ncol(X_full))
  )
  
  max_eig <- suppressWarnings(max(eig, na.rm = TRUE))
  min_eig_raw <- suppressWarnings(min(eig, na.rm = TRUE))
  min_eig <- if (is.finite(min_eig_raw)) max(min_eig_raw, .Machine$double.eps) else NA_real_
  cond_num <- if (is.finite(max_eig) && is.finite(min_eig)) sqrt(max_eig / min_eig) else NA_real_
  
  rank_x <- tryCatch(qr(X_full)$rank, error = function(e) NA_integer_)
  near_sing <- isTRUE(cond_num > COND_WARN_3) || (!is.na(rank_x) && rank_x < ncol(X_full))
  max_vif <- suppressWarnings(max(c(vif_k, vif_i), na.rm = TRUE))
  if (!is.finite(max_vif)) max_vif <- NA_real_
  
  data.frame(
    corr_longrun_regressors = corr_val,
    VIF_regressor_1 = vif_k,
    VIF_regressor_2 = vif_i,
    max_vif = max_vif,
    condition_number_longrun_X = cond_num,
    smallest_eigenvalue_XtX = min_eig,
    rank_longrun_X = rank_x,
    near_singularity_flag = near_sing,
    design_flag = design_flag(max_vif, cond_num, near_sing),
    stringsAsFactors = FALSE
  )
}

extract_cointReg_terms <- function(fit, intercept_flag) {
  term_names <- if (intercept_flag) c("const", "k", "interaction") else c("k", "interaction")
  
  theta_hat <- setNames(as.numeric(fit$theta), term_names)
  se_hat    <- setNames(as.numeric(fit$sd.theta), term_names)
  t_hat     <- setNames(as.numeric(fit$t.theta), term_names)
  p_hat     <- setNames(as.numeric(fit$p.theta), term_names)
  
  list(theta = theta_hat, se = se_hat, t = t_hat, p = p_hat)
}

estimate_dols_one <- function(df_trim,
                              intercept_flag,
                              centered_flag,
                              n.lead,
                              n.lag,
                              kernel,
                              bandwidth) {
  omega_bar <- mean(df_trim$omega_t)
  
  interaction <- if (centered_flag) {
    (df_trim$omega_t - omega_bar) * df_trim$k_t
  } else {
    df_trim$omega_t * df_trim$k_t
  }
  
  coll <- compute_collinearity(
    k_vec = df_trim$k_t,
    inter_vec = interaction,
    intercept_flag = intercept_flag
  )
  
  x_mat <- cbind(k = df_trim$k_t, interaction = interaction)
  y_vec <- df_trim$y_t
  
  deter_mat <- if (intercept_flag) {
    matrix(1, nrow = length(y_vec), ncol = 1, dimnames = list(NULL, "const"))
  } else {
    NULL
  }
  
  fit <- tryCatch(
    cointRegD(
      x = x_mat,
      y = y_vec,
      deter = deter_mat,
      kernel = kernel,
      bandwidth = bandwidth,
      n.lead = n.lead,
      n.lag = n.lag,
      check = TRUE
    ),
    error = function(e) e
  )
  
  if (inherits(fit, "error")) {
    return(cbind(
      data.frame(
        omega_mean = omega_bar,
        omega_min = min(df_trim$omega_t),
        omega_max = max(df_trim$omega_t),
        omega_range = max(df_trim$omega_t) - min(df_trim$omega_t),
        beta1_hat = NA_real_,
        se_beta1 = NA_real_,
        t_beta1 = NA_real_,
        p_beta1 = NA_real_,
        beta2_hat = NA_real_,
        se_beta2 = NA_real_,
        t_beta2 = NA_real_,
        p_beta2 = NA_real_,
        const_hat = NA_real_,
        se_const = NA_real_,
        t_const = NA_real_,
        p_const = NA_real_,
        fit_ok = FALSE,
        fit_message = conditionMessage(fit),
        stringsAsFactors = FALSE
      ),
      coll
    ))
  }
  
  ext <- extract_cointReg_terms(fit, intercept_flag)
  
  cbind(
    data.frame(
      omega_mean = omega_bar,
      omega_min = min(df_trim$omega_t),
      omega_max = max(df_trim$omega_t),
      omega_range = max(df_trim$omega_t) - min(df_trim$omega_t),
      beta1_hat = unname(ext$theta["k"]),
      se_beta1 = unname(ext$se["k"]),
      t_beta1 = unname(ext$t["k"]),
      p_beta1 = unname(ext$p["k"]),
      beta2_hat = unname(ext$theta["interaction"]),
      se_beta2 = unname(ext$se["interaction"]),
      t_beta2 = unname(ext$t["interaction"]),
      p_beta2 = unname(ext$p["interaction"]),
      const_hat = if (intercept_flag) unname(ext$theta["const"]) else NA_real_,
      se_const = if (intercept_flag) unname(ext$se["const"]) else NA_real_,
      t_const = if (intercept_flag) unname(ext$t["const"]) else NA_real_,
      p_const = if (intercept_flag) unname(ext$p["const"]) else NA_real_,
      fit_ok = TRUE,
      fit_message = "",
      stringsAsFactors = FALSE
    ),
    coll
  )
}

summarize_registry <- function(df, group_cols) {
  if (nrow(df) == 0L) return(data.frame())
  
  grp_key <- interaction(df[, group_cols], drop = TRUE, lex.order = TRUE)
  spl <- split(df, grp_key)
  
  out <- lapply(spl, function(z) {
    anchor <- z[1, group_cols, drop = FALSE]
    
    data.frame(
      anchor,
      n_rows = nrow(z),
      fit_failures = sum(!z$fit_ok, na.rm = TRUE),
      pct_fit_failures = mean(!z$fit_ok),
      mean_omega_range = mean(z$omega_range, na.rm = TRUE),
      min_omega_range = min(z$omega_range, na.rm = TRUE),
      median_corr = median(z$corr_longrun_regressors, na.rm = TRUE),
      max_abs_corr = max(abs(z$corr_longrun_regressors), na.rm = TRUE),
      median_max_vif = median(z$max_vif, na.rm = TRUE),
      p95_max_vif = as.numeric(quantile(z$max_vif, probs = 0.95, na.rm = TRUE, names = FALSE)),
      max_max_vif = max(z$max_vif, na.rm = TRUE),
      median_cond_num = median(z$condition_number_longrun_X, na.rm = TRUE),
      p95_cond_num = as.numeric(quantile(z$condition_number_longrun_X, probs = 0.95, na.rm = TRUE, names = FALSE)),
      max_cond_num = max(z$condition_number_longrun_X, na.rm = TRUE),
      near_singularity_share = mean(z$near_singularity_flag, na.rm = TRUE),
      high_vif_share = mean(z$max_vif > VIF_WARN_2, na.rm = TRUE),
      moderate_vif_share = mean(z$max_vif > VIF_WARN_1, na.rm = TRUE),
      high_cond_share = mean(z$condition_number_longrun_X > COND_WARN_2, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out
}

# ------------------------------------------------------------------------------
# 3. Data loading
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

# ------------------------------------------------------------------------------
# 4. Rolling registry
# ------------------------------------------------------------------------------
run_rolling_registry <- function(df,
                                 windows,
                                 specs,
                                 widths,
                                 step,
                                 n.lead,
                                 n.lag,
                                 kernel,
                                 bandwidth) {
  out <- list()
  idx <- 1L
  
  for (w in windows) {
    df_w <- df[df$year >= w$start & df$year <= w$end, ]
    if (nrow(df_w) == 0L) next
    
    for (width in widths) {
      if (nrow(df_w) < width) next
      
      starts <- seq.int(1L, nrow(df_w) - width + 1L, by = step)
      
      for (s in starts) {
        e <- s + width - 1L
        df_roll <- df_w[s:e, ]
        aw <- compute_active_window(df_roll, n.lead = n.lead, n.lag = n.lag)
        if (is.null(aw)) next
        
        df_trim <- df_roll[aw$first_idx:aw$last_idx, ]
        
        for (sp in specs) {
          est <- estimate_dols_one(
            df_trim = df_trim,
            intercept_flag = sp$intercept,
            centered_flag = sp$centered,
            n.lead = n.lead,
            n.lag = n.lag,
            kernel = kernel,
            bandwidth = bandwidth
          )
          
          est$registry_type <- "rolling"
          est$sample_name <- w$label
          est$economic_start_year <- w$start
          est$economic_end_year <- w$end
          est$window_width <- width
          est$rolling_start_year <- min(df_roll$year)
          est$rolling_end_year <- max(df_roll$year)
          est$regression_start_year <- min(df_trim$year)
          est$regression_end_year <- max(df_trim$year)
          est$N <- nrow(df_trim)
          est$spec_id <- sp$id
          est$intercept_flag <- sp$intercept
          est$centered_flag <- sp$centered
          est$interaction_label <- if (sp$centered) "(omega_t-omega_bar)k_t" else "omega_t k_t"
          est$n_lead <- n.lead
          est$n_lag <- n.lag
          est$kernel <- kernel
          est$bandwidth <- bandwidth
          
          out[[idx]] <- est
          idx <- idx + 1L
        }
      }
    }
  }
  
  if (length(out) == 0L) return(data.frame())
  ans <- do.call(rbind, out)
  rownames(ans) <- NULL
  ans
}

# ------------------------------------------------------------------------------
# 5. Lead-lag sensitivity registry
# ------------------------------------------------------------------------------
run_leadlag_registry <- function(df,
                                 windows,
                                 specs,
                                 lead_grid,
                                 lag_grid,
                                 kernel,
                                 bandwidth) {
  out <- list()
  idx <- 1L
  
  for (w in windows) {
    df_w <- df[df$year >= w$start & df$year <= w$end, ]
    if (nrow(df_w) == 0L) next
    
    for (n.lead in lead_grid) {
      for (n.lag in lag_grid) {
        aw <- compute_active_window(df_w, n.lead = n.lead, n.lag = n.lag)
        if (is.null(aw)) next
        
        df_trim <- df_w[aw$first_idx:aw$last_idx, ]
        
        for (sp in specs) {
          est <- estimate_dols_one(
            df_trim = df_trim,
            intercept_flag = sp$intercept,
            centered_flag = sp$centered,
            n.lead = n.lead,
            n.lag = n.lag,
            kernel = kernel,
            bandwidth = bandwidth
          )
          
          est$registry_type <- "leadlag"
          est$sample_name <- w$label
          est$economic_start_year <- w$start
          est$economic_end_year <- w$end
          est$window_width <- NA_integer_
          est$rolling_start_year <- NA_integer_
          est$rolling_end_year <- NA_integer_
          est$regression_start_year <- min(df_trim$year)
          est$regression_end_year <- max(df_trim$year)
          est$N <- nrow(df_trim)
          est$spec_id <- sp$id
          est$intercept_flag <- sp$intercept
          est$centered_flag <- sp$centered
          est$interaction_label <- if (sp$centered) "(omega_t-omega_bar)k_t" else "omega_t k_t"
          est$n_lead <- n.lead
          est$n_lag <- n.lag
          est$kernel <- kernel
          est$bandwidth <- bandwidth
          
          out[[idx]] <- est
          idx <- idx + 1L
        }
      }
    }
  }
  
  if (length(out) == 0L) return(data.frame())
  ans <- do.call(rbind, out)
  rownames(ans) <- NULL
  ans
}

# ------------------------------------------------------------------------------
# 6. Run registries
# ------------------------------------------------------------------------------
cat("Running rolling design-geometry registry...\n")
rolling_df <- run_rolling_registry(
  df = d_raw,
  windows = windows,
  specs = specs,
  widths = ROLL_WIDTHS,
  step = ROLL_STEP,
  n.lead = BASE_N_LEAD,
  n.lag = BASE_N_LAG,
  kernel = CR_KERNEL,
  bandwidth = CR_BANDWIDTH
)

cat("Running lead-lag sensitivity registry...\n")
leadlag_df <- run_leadlag_registry(
  df = d_raw,
  windows = windows,
  specs = specs,
  lead_grid = LEAD_GRID,
  lag_grid = LAG_GRID,
  kernel = CR_KERNEL,
  bandwidth = CR_BANDWIDTH
)

# ------------------------------------------------------------------------------
# 7. Summaries
# ------------------------------------------------------------------------------
rolling_summary <- summarize_registry(
  rolling_df,
  group_cols = c("sample_name", "window_width", "spec_id", "interaction_label", "n_lead", "n_lag")
)

leadlag_summary <- summarize_registry(
  leadlag_df,
  group_cols = c("sample_name", "spec_id", "interaction_label", "n_lead", "n_lag")
)

# Helpful “worst windows” table
rolling_worst <- rolling_df[
  order(
    -ifelse(is.na(rolling_df$max_vif), -Inf, rolling_df$max_vif),
    -ifelse(is.na(rolling_df$condition_number_longrun_X), -Inf, rolling_df$condition_number_longrun_X)
  ),
]

leadlag_worst <- leadlag_df[
  order(
    -ifelse(is.na(leadlag_df$max_vif), -Inf, leadlag_df$max_vif),
    -ifelse(is.na(leadlag_df$condition_number_longrun_X), -Inf, leadlag_df$condition_number_longrun_X)
  ),
]

# ------------------------------------------------------------------------------
# 8. Ordering and export
# ------------------------------------------------------------------------------
if (nrow(rolling_df) > 0L) {
  rolling_df$sample_name <- factor(rolling_df$sample_name, levels = window_order)
  rolling_df <- rolling_df[order(rolling_df$sample_name, rolling_df$window_width, rolling_df$rolling_start_year, rolling_df$spec_id), ]
}

if (nrow(leadlag_df) > 0L) {
  leadlag_df$sample_name <- factor(leadlag_df$sample_name, levels = window_order)
  leadlag_df <- leadlag_df[order(leadlag_df$sample_name, leadlag_df$spec_id, leadlag_df$n_lead, leadlag_df$n_lag), ]
}

write.csv(rolling_df, file.path(outdir, "rolling_vif_registry_us.csv"), row.names = FALSE)
write.csv(leadlag_df, file.path(outdir, "leadlag_sensitivity_registry_us.csv"), row.names = FALSE)
write.csv(rolling_summary, file.path(outdir, "rolling_vif_registry_summary_us.csv"), row.names = FALSE)
write.csv(leadlag_summary, file.path(outdir, "leadlag_sensitivity_summary_us.csv"), row.names = FALSE)
write.csv(head(rolling_worst, 100L), file.path(outdir, "rolling_vif_registry_worst100_us.csv"), row.names = FALSE)
write.csv(head(leadlag_worst, 100L), file.path(outdir, "leadlag_sensitivity_worst100_us.csv"), row.names = FALSE)

# Manifest
manifest <- data.frame(
  run_id = run_id,
  kernel = CR_KERNEL,
  bandwidth = CR_BANDWIDTH,
  base_n_lead = BASE_N_LEAD,
  base_n_lag = BASE_N_LAG,
  roll_widths = paste(ROLL_WIDTHS, collapse = ","),
  roll_step = ROLL_STEP,
  lead_grid = paste(LEAD_GRID, collapse = ","),
  lag_grid = paste(LAG_GRID, collapse = ","),
  data_start = min(d_raw$year),
  data_end = max(d_raw$year),
  stringsAsFactors = FALSE
)

write.csv(manifest, file.path(outdir, "run_manifest_us.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(outdir, "sessionInfo.txt"))

cat("\nSaved stress-test outputs to:\n")
cat(outdir, "\n\n")

cat("Quick counts:\n")
cat(sprintf("  Rolling rows:  %d\n", nrow(rolling_df)))
cat(sprintf("  Lead-lag rows: %d\n", nrow(leadlag_df)))

if (nrow(rolling_summary) > 0L) {
  cat("\nRolling summary preview:\n")
  print(utils::head(rolling_summary, 10L))
}

if (nrow(leadlag_summary) > 0L) {
  cat("\nLead-lag summary preview:\n")
  print(utils::head(leadlag_summary, 10L))
}




# ------------------------------------------------------------------------------
# 9. Estimator-family comparator registry
# ------------------------------------------------------------------------------

# Comparator settings
AUTO_KMAX      <- "k4"     # D-OLS automatic lag/lead search cap
AUTO_IC        <- "BIC"    # D-OLS automatic lag/lead selector
FM_BANDWIDTH   <- "and"    # Andrews automatic bandwidth
IM_BANDWIDTH   <- "and"    # Andrews automatic bandwidth
IM_SELECTOR    <- 1        # IM-OLS selector
PATH_SE_EPS    <- 1e-10    # pathology flag for near-zero SE on beta2

safe_named <- function(x, nm) {
  if (is.null(x)) return(NA_real_)
  x <- as.numeric(x)
  if (length(x) < 1L) return(NA_real_)
  unname(x[nm])
}

compute_theta_profile <- function(beta1, beta2,
                                  omega_mean, omega_min, omega_max,
                                  centered_flag) {
  if (!is.finite(beta1) || !is.finite(beta2)) {
    return(data.frame(
      theta_at_omega_min = NA_real_,
      theta_at_omega_mean = NA_real_,
      theta_at_omega_max = NA_real_,
      delta_theta_obs = NA_real_,
      omega_cross_theta1 = NA_real_,
      theta_crosses_one_in_support = NA,
      stringsAsFactors = FALSE
    ))
  }
  
  if (centered_flag) {
    theta_min  <- beta1 + beta2 * (omega_min  - omega_mean)
    theta_mean <- beta1
    theta_max  <- beta1 + beta2 * (omega_max  - omega_mean)
    omega_star <- if (abs(beta2) <= .Machine$double.eps) NA_real_ else omega_mean + (1 - beta1) / beta2
  } else {
    theta_min  <- beta1 + beta2 * omega_min
    theta_mean <- beta1 + beta2 * omega_mean
    theta_max  <- beta1 + beta2 * omega_max
    omega_star <- if (abs(beta2) <= .Machine$double.eps) NA_real_ else (1 - beta1) / beta2
  }
  
  lo <- min(theta_min, theta_max, na.rm = TRUE)
  hi <- max(theta_min, theta_max, na.rm = TRUE)
  
  data.frame(
    theta_at_omega_min = theta_min,
    theta_at_omega_mean = theta_mean,
    theta_at_omega_max = theta_max,
    delta_theta_obs = theta_max - theta_min,
    omega_cross_theta1 = omega_star,
    theta_crosses_one_in_support =
      is.finite(omega_star) &&
      is.finite(omega_min) &&
      is.finite(omega_max) &&
      omega_star >= min(omega_min, omega_max) &&
      omega_star <= max(omega_min, omega_max) &&
      lo <= 1 && hi >= 1,
    stringsAsFactors = FALSE
  )
}

estimate_coint_family_one <- function(df_in,
                                      intercept_flag,
                                      centered_flag,
                                      estimator_label) {
  omega_bar <- mean(df_in$omega_t, na.rm = TRUE)
  
  interaction <- if (centered_flag) {
    (df_in$omega_t - omega_bar) * df_in$k_t
  } else {
    df_in$omega_t * df_in$k_t
  }
  
  coll <- compute_collinearity(
    k_vec = df_in$k_t,
    inter_vec = interaction,
    intercept_flag = intercept_flag
  )
  
  x_mat <- cbind(k = df_in$k_t, interaction = interaction)
  y_vec <- df_in$y_t
  
  deter_mat <- if (intercept_flag) {
    matrix(1, nrow = length(y_vec), ncol = 1, dimnames = list(NULL, "const"))
  } else {
    NULL
  }
  
  fit <- tryCatch(
    switch(
      estimator_label,
      D_fixed = cointRegD(
        x = x_mat,
        y = y_vec,
        deter = deter_mat,
        kernel = CR_KERNEL,
        bandwidth = CR_BANDWIDTH,
        n.lead = BASE_N_LEAD,
        n.lag = BASE_N_LAG,
        check = TRUE
      ),
      D_auto = cointRegD(
        x = x_mat,
        y = y_vec,
        deter = deter_mat,
        kernel = CR_KERNEL,
        bandwidth = CR_BANDWIDTH,
        n.lead = NULL,
        n.lag = NULL,
        kmax = AUTO_KMAX,
        info.crit = AUTO_IC,
        check = TRUE
      ),
      FM = cointRegFM(
        x = x_mat,
        y = y_vec,
        deter = deter_mat,
        kernel = CR_KERNEL,
        bandwidth = FM_BANDWIDTH,
        check = TRUE
      ),
      IM = cointRegIM(
        x = x_mat,
        y = y_vec,
        deter = deter_mat,
        selector = IM_SELECTOR,
        t.test = TRUE,
        kernel = CR_KERNEL,
        bandwidth = IM_BANDWIDTH,
        check = TRUE
      ),
      stop("Unknown estimator_label: ", estimator_label)
    ),
    error = function(e) e
  )
  
  if (inherits(fit, "error")) {
    return(cbind(
      data.frame(
        estimator = estimator_label,
        auto_kmax = if (estimator_label == "D_auto") AUTO_KMAX else "",
        auto_ic = if (estimator_label == "D_auto") AUTO_IC else "",
        im_selector = if (estimator_label == "IM") IM_SELECTOR else NA_integer_,
        omega_mean = omega_bar,
        omega_min = min(df_in$omega_t, na.rm = TRUE),
        omega_max = max(df_in$omega_t, na.rm = TRUE),
        omega_range = max(df_in$omega_t, na.rm = TRUE) - min(df_in$omega_t, na.rm = TRUE),
        beta1_hat = NA_real_,
        se_beta1 = NA_real_,
        t_beta1 = NA_real_,
        p_beta1 = NA_real_,
        beta2_hat = NA_real_,
        se_beta2 = NA_real_,
        t_beta2 = NA_real_,
        p_beta2 = NA_real_,
        const_hat = NA_real_,
        se_const = NA_real_,
        t_const = NA_real_,
        p_const = NA_real_,
        theta_at_omega_min = NA_real_,
        theta_at_omega_mean = NA_real_,
        theta_at_omega_max = NA_real_,
        delta_theta_obs = NA_real_,
        omega_cross_theta1 = NA_real_,
        theta_crosses_one_in_support = NA,
        pathological_beta2_inference = NA,
        fit_ok = FALSE,
        fit_message = conditionMessage(fit),
        stringsAsFactors = FALSE
      ),
      coll
    ))
  }
  
  ext <- extract_cointReg_terms(fit, intercept_flag)
  
  beta1_hat <- unname(ext$theta["k"])
  beta2_hat <- unname(ext$theta["interaction"])
  se_beta2  <- unname(ext$se["interaction"])
  t_beta2   <- unname(ext$t["interaction"])
  
  theta_prof <- compute_theta_profile(
    beta1 = beta1_hat,
    beta2 = beta2_hat,
    omega_mean = omega_bar,
    omega_min = min(df_in$omega_t, na.rm = TRUE),
    omega_max = max(df_in$omega_t, na.rm = TRUE),
    centered_flag = centered_flag
  )
  
  pathology_beta2 <- (!is.finite(se_beta2)) ||
    (!is.finite(t_beta2)) ||
    (is.finite(se_beta2) && se_beta2 <= PATH_SE_EPS)
  
  cbind(
    data.frame(
      estimator = estimator_label,
      auto_kmax = if (estimator_label == "D_auto") AUTO_KMAX else "",
      auto_ic = if (estimator_label == "D_auto") AUTO_IC else "",
      im_selector = if (estimator_label == "IM") IM_SELECTOR else NA_integer_,
      omega_mean = omega_bar,
      omega_min = min(df_in$omega_t, na.rm = TRUE),
      omega_max = max(df_in$omega_t, na.rm = TRUE),
      omega_range = max(df_in$omega_t, na.rm = TRUE) - min(df_in$omega_t, na.rm = TRUE),
      beta1_hat = beta1_hat,
      se_beta1 = unname(ext$se["k"]),
      t_beta1 = unname(ext$t["k"]),
      p_beta1 = unname(ext$p["k"]),
      beta2_hat = beta2_hat,
      se_beta2 = se_beta2,
      t_beta2 = t_beta2,
      p_beta2 = unname(ext$p["interaction"]),
      const_hat = if (intercept_flag) unname(ext$theta["const"]) else NA_real_,
      se_const = if (intercept_flag) unname(ext$se["const"]) else NA_real_,
      t_const = if (intercept_flag) unname(ext$t["const"]) else NA_real_,
      p_const = if (intercept_flag) unname(ext$p["const"]) else NA_real_,
      pathological_beta2_inference = pathology_beta2,
      fit_ok = TRUE,
      fit_message = "",
      stringsAsFactors = FALSE
    ),
    theta_prof,
    coll
  )
}

run_estimator_compare_registry <- function(df, windows, specs) {
  estimators <- c("D_fixed", "D_auto", "FM", "IM")
  out <- list()
  idx <- 1L
  
  for (w in windows) {
    df_w <- df[df$year >= w$start & df$year <= w$end, ]
    if (nrow(df_w) == 0L) next
    
    for (sp in specs) {
      for (est in estimators) {
        est_row <- estimate_coint_family_one(
          df_in = df_w,
          intercept_flag = sp$intercept,
          centered_flag = sp$centered,
          estimator_label = est
        )
        
        est_row$sample_name <- w$label
        est_row$economic_start_year <- w$start
        est_row$economic_end_year <- w$end
        est_row$input_start_year <- min(df_w$year)
        est_row$input_end_year <- max(df_w$year)
        est_row$input_N <- nrow(df_w)
        est_row$spec_id <- sp$id
        est_row$intercept_flag <- sp$intercept
        est_row$centered_flag <- sp$centered
        est_row$interaction_label <- if (sp$centered) "(omega_t-omega_bar)k_t" else "omega_t k_t"
        est_row$beta2_family <- if (sp$intercept) "with_intercept" else "no_intercept"
        est_row$kernel_used <- CR_KERNEL
        est_row$bandwidth_used <- if (est %in% c("FM", "IM")) "and" else as.character(CR_BANDWIDTH)
        
        out[[idx]] <- est_row
        idx <- idx + 1L
      }
    }
  }
  
  ans <- do.call(rbind, out)
  rownames(ans) <- NULL
  ans
}

summarize_estimator_compare <- function(df) {
  keys <- c("sample_name", "beta2_family", "estimator")
  grp_key <- interaction(df[, keys], drop = TRUE, lex.order = TRUE)
  spl <- split(df, grp_key)
  
  out <- lapply(spl, function(z) {
    anchor <- z[1, keys, drop = FALSE]
    data.frame(
      anchor,
      n_rows = nrow(z),
      fit_failures = sum(!z$fit_ok, na.rm = TRUE),
      pathological_beta2_share = mean(z$pathological_beta2_inference, na.rm = TRUE),
      min_beta2_hat = min(z$beta2_hat, na.rm = TRUE),
      max_beta2_hat = max(z$beta2_hat, na.rm = TRUE),
      min_delta_theta_obs = min(z$delta_theta_obs, na.rm = TRUE),
      max_delta_theta_obs = max(z$delta_theta_obs, na.rm = TRUE),
      any_theta_crossing_one = any(z$theta_crosses_one_in_support, na.rm = TRUE),
      median_max_vif = median(z$max_vif, na.rm = TRUE),
      median_cond_num = median(z$condition_number_longrun_X, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  
  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out
}

cat("\nRunning estimator-family comparator registry...\n")
estimator_compare_df <- run_estimator_compare_registry(
  df = d_raw,
  windows = windows,
  specs = specs
)

if (nrow(estimator_compare_df) > 0L) {
  estimator_compare_df$sample_name <- factor(estimator_compare_df$sample_name, levels = window_order)
  estimator_compare_df <- estimator_compare_df[
    order(estimator_compare_df$sample_name,
          estimator_compare_df$beta2_family,
          estimator_compare_df$spec_id,
          estimator_compare_df$estimator),
  ]
}

estimator_compare_summary <- summarize_estimator_compare(estimator_compare_df)

write.csv(
  estimator_compare_df,
  file.path(outdir, "estimator_family_registry_us.csv"),
  row.names = FALSE
)

write.csv(
  estimator_compare_summary,
  file.path(outdir, "estimator_family_summary_us.csv"),
  row.names = FALSE
)

cat("\nEstimator-family comparator preview:\n")
print(utils::head(estimator_compare_df, 12L))

cat("\nEstimator-family summary preview:\n")
print(utils::head(estimator_compare_summary, 12L))


# ------------------------------------------------------------------------------
# 10. Pre-regression dummy-candidate diagnostic from existing objects
#    No new estimation. Uses rolling / lead-lag / estimator-family outputs.
# ------------------------------------------------------------------------------

# Safety checks
required_objs <- c("rolling_df", "leadlag_df")
missing_objs <- required_objs[!vapply(required_objs, exists, logical(1))]
if (length(missing_objs) > 0L) {
  stop("Missing required objects in memory: ", paste(missing_objs, collapse = ", "))
}

# Thresholds already implicit in your diagnostics
VIF_CANDIDATE  <- 5
COND_CANDIDATE <- 1000

# 1) Flag bad windows from rolling diagnostics
rolling_bad <- subset(
  rolling_df,
  max_vif > VIF_CANDIDATE |
    condition_number_longrun_X > COND_CANDIDATE |
    near_singularity_flag
)

# 2) Year-incidence map: which calendar years are repeatedly contained
#    in "bad" rolling windows?
year_grid <- data.frame(
  year = seq(
    min(rolling_df$rolling_start_year, na.rm = TRUE),
    max(rolling_df$rolling_end_year,   na.rm = TRUE),
    by = 1L
  )
)

year_grid$bad_window_incidence <- vapply(
  year_grid$year,
  function(y) {
    sum(rolling_bad$rolling_start_year <= y &
          rolling_bad$rolling_end_year >= y,
        na.rm = TRUE)
  },
  numeric(1)
)

# Decompose incidence by source of badness
rolling_bad_vif <- subset(rolling_df, max_vif > VIF_CANDIDATE)
rolling_bad_cond <- subset(
  rolling_df,
  condition_number_longrun_X > COND_CANDIDATE | near_singularity_flag
)

year_grid$vif_bad_incidence <- vapply(
  year_grid$year,
  function(y) {
    sum(rolling_bad_vif$rolling_start_year <= y &
          rolling_bad_vif$rolling_end_year >= y,
        na.rm = TRUE)
  },
  numeric(1)
)

year_grid$cond_bad_incidence <- vapply(
  year_grid$year,
  function(y) {
    sum(rolling_bad_cond$rolling_start_year <= y &
          rolling_bad_cond$rolling_end_year >= y,
        na.rm = TRUE)
  },
  numeric(1)
)

# 3) Endpoint pressure map:
#    years that appear disproportionately at the start/end of bad windows
endpoint_tab <- rbind(
  data.frame(year = rolling_bad$rolling_start_year, endpoint = "start"),
  data.frame(year = rolling_bad$rolling_end_year,   endpoint = "end")
)

if (nrow(endpoint_tab) > 0L) {
  endpoint_summary <- aggregate(
    rep(1, nrow(endpoint_tab)),
    by = list(year = endpoint_tab$year, endpoint = endpoint_tab$endpoint),
    FUN = sum
  )
  names(endpoint_summary)[3] <- "count"
  
  endpoint_wide <- reshape(
    endpoint_summary,
    idvar = "year",
    timevar = "endpoint",
    direction = "wide"
  )
  
  if (!"count.start" %in% names(endpoint_wide)) endpoint_wide$count.start <- 0
  if (!"count.end"   %in% names(endpoint_wide)) endpoint_wide$count.end   <- 0
  
  endpoint_wide$endpoint_pressure <- endpoint_wide$count.start + endpoint_wide$count.end
} else {
  endpoint_wide <- data.frame(
    year = integer(),
    count.start = integer(),
    count.end = integer(),
    endpoint_pressure = integer()
  )
}

# 4) Lead-lag instability map:
#    does beta2 vary a lot across lead/lag toggles by sample/spec?
grp_keys <- c("sample_name", "spec_id", "intercept_flag", "centered_flag")

leadlag_beta2_min <- aggregate(
  beta2_hat ~ sample_name + spec_id + intercept_flag + centered_flag,
  data = leadlag_df,
  FUN = function(z) min(z, na.rm = TRUE)
)
names(leadlag_beta2_min)[names(leadlag_beta2_min) == "beta2_hat"] <- "beta2_min"

leadlag_beta2_max <- aggregate(
  beta2_hat ~ sample_name + spec_id + intercept_flag + centered_flag,
  data = leadlag_df,
  FUN = function(z) max(z, na.rm = TRUE)
)
names(leadlag_beta2_max)[names(leadlag_beta2_max) == "beta2_hat"] <- "beta2_max"

leadlag_sign_instability <- merge(
  leadlag_beta2_min,
  leadlag_beta2_max,
  by = grp_keys,
  all = TRUE
)

leadlag_sign_instability$sign_flip_across_toggles <-
  with(leadlag_sign_instability, beta2_min < 0 & beta2_max > 0)

leadlag_sign_instability$beta2_span <-
  with(leadlag_sign_instability, beta2_max - beta2_min)

# 5) Candidate-year score
year_diag <- merge(
  year_grid,
  endpoint_wide[, c("year", "endpoint_pressure")],
  by = "year",
  all.x = TRUE
)
year_diag$endpoint_pressure[is.na(year_diag$endpoint_pressure)] <- 0

rescale01 <- function(x) {
  rng <- range(x, na.rm = TRUE)
  if (!is.finite(rng[1]) || !is.finite(rng[2]) || diff(rng) == 0) {
    return(rep(0, length(x)))
  }
  (x - rng[1]) / diff(rng)
}

year_diag$score_bad_windows <- rescale01(year_diag$bad_window_incidence)
year_diag$score_vif_tail    <- rescale01(year_diag$vif_bad_incidence)
year_diag$score_cond_tail   <- rescale01(year_diag$cond_bad_incidence)
year_diag$score_endpoint    <- rescale01(year_diag$endpoint_pressure)

# More weight on conditioning than VIF
year_diag$dummy_candidate_score <-
  0.40 * year_diag$score_cond_tail +
  0.25 * year_diag$score_bad_windows +
  0.20 * year_diag$score_endpoint +
  0.15 * year_diag$score_vif_tail

year_diag <- year_diag[order(-year_diag$dummy_candidate_score, year_diag$year), ]

# 6) Suggest period blocks rather than single-year dummies
suggest_blocks <- function(df, score_cut = 0.70) {
  keep <- df[df$dummy_candidate_score >= score_cut, c("year", "dummy_candidate_score")]
  keep <- keep[order(keep$year), ]   # <-- add this line
  if (nrow(keep) == 0L) {
    return(data.frame(
      start_year = integer(),
      end_year = integer(),
      peak_score = numeric()
    ))
  }
  
  grp <- cumsum(c(1, diff(keep$year) > 1))
  starts <- tapply(keep$year, grp, min)
  ends   <- tapply(keep$year, grp, max)
  peaks  <- tapply(keep$dummy_candidate_score, grp, max)
  
  data.frame(
    start_year = as.integer(starts),
    end_year   = as.integer(ends),
    peak_score = as.numeric(peaks),
    row.names = NULL
  )
}

candidate_blocks <- suggest_blocks(year_diag, score_cut = 0.70)

# 7) Export
write.csv(year_diag,
          file.path(outdir, "dummy_candidate_year_diagnostic_us.csv"),
          row.names = FALSE)

write.csv(head(year_diag, 50),
          file.path(outdir, "dummy_candidate_year_top50_us.csv"),
          row.names = FALSE)

write.csv(candidate_blocks,
          file.path(outdir, "dummy_candidate_blocks_us.csv"),
          row.names = FALSE)

write.csv(leadlag_sign_instability,
          file.path(outdir, "leadlag_sign_instability_us.csv"),
          row.names = FALSE)

cat("\nSaved pre-regression dummy diagnostic files:\n")
cat(sprintf("  - %s\n", file.path(outdir, "dummy_candidate_year_diagnostic_us.csv")))
cat(sprintf("  - %s\n", file.path(outdir, "dummy_candidate_year_top50_us.csv")))
cat(sprintf("  - %s\n", file.path(outdir, "dummy_candidate_blocks_us.csv")))
cat(sprintf("  - %s\n", file.path(outdir, "leadlag_sign_instability_us.csv")))

cat("\nTop candidate years:\n")
print(utils::head(
  year_diag[, c(
    "year", "dummy_candidate_score", "bad_window_incidence",
    "vif_bad_incidence", "cond_bad_incidence", "endpoint_pressure"
  )],
  20
))

cat("\nLead-lag sign instability:\n")
print(leadlag_sign_instability)

cat("\nCandidate blocks:\n")
print(candidate_blocks)