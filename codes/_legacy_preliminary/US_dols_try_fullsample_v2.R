# 48_us_theta_window_benchmark_and_robustness.R
# ==============================================================================
# Window-sample benchmark + robustness for theta(omega)
#   - exact historical windows
#   - Fordist benchmark = 1945-1973
#   - estimators: D_fixed, FM, IM (+ optional D_auto sensitivity)
#   - nuisance controls only in deter_mat, OFF by default
#   - console tables + csv exports
# ==============================================================================

suppressPackageStartupMessages({
  library(cointReg)
  library(stats)
})

# ------------------------------------------------------------------------------
# 0. Paths and output
# ------------------------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")
BEA  <- Sys.getenv("BEA_REPO", unset = "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset")

outdir <- file.path(REPO, "output", "US_theta_window_benchmark_and_robustness")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Settings
# ------------------------------------------------------------------------------
REBASE_YEAR <- 2024L

CR_KERNEL    <- "ba"
CR_BANDWIDTH <- 3L

BASE_N_LEAD <- 2L
BASE_N_LAG  <- 2L

AUTO_KMAX    <- "k4"
AUTO_IC      <- "BIC"
FM_BANDWIDTH <- "and"
IM_BANDWIDTH <- "and"
IM_SELECTOR  <- 1

RUN_D_AUTO <- FALSE   # keep FALSE unless you explicitly want the sensitivity layer

# Nuisance controls: additive only, never structural
INCLUDE_NUISANCE_CONTROLS <- FALSE
NUISANCE_MODE <- "none"   # "none", "pulse_2008", "block_2008_2009", "block_2008_2010"

specs <- list(
  list(id = "W1_no_intercept",  intercept = FALSE),
  list(id = "W2_with_intercept", intercept = TRUE)
)

windows <- list(
  list(label = "Fordist_core",      start = 1945L, end = 1973L, role = "benchmark"),
  list(label = "Pre1974_broad",     start = 1929L, end = 1973L, role = "support"),
  list(label = "Bridge_1940_1978",  start = 1940L, end = 1978L, role = "bridge"),
  list(label = "Post1974_tight",    start = 1974L, end = 1983L, role = "support"),
  list(label = "Post1974_support",  start = 1974L, end = 1987L, role = "support")
)

estimators <- c("D_fixed", "FM", "IM")
if (isTRUE(RUN_D_AUTO)) estimators <- c(estimators, "D_auto")

# ------------------------------------------------------------------------------
# 2. Helpers
# ------------------------------------------------------------------------------
fmt_num <- function(x, k = 4) {
  ifelse(is.na(x), NA_character_, formatC(x, digits = k, format = "f"))
}

fmt_sci <- function(x, k = 3) {
  ifelse(is.na(x), NA_character_, formatC(x, digits = k, format = "e"))
}

extract_fit_objects <- function(fit, full_term_names) {
  theta <- as.numeric(fit$theta)
  se    <- as.numeric(fit$sd.theta)
  tt    <- as.numeric(fit$t.theta)
  pp    <- as.numeric(fit$p.theta)
  
  n_theta <- length(theta)
  
  if (n_theta != length(full_term_names)) {
    stop(
      "Length mismatch in theta: got ", n_theta,
      " coefficients but supplied ", length(full_term_names), " names."
    )
  }
  
  names(theta) <- full_term_names
  if (length(se) == n_theta) names(se) <- full_term_names
  if (length(tt) == n_theta) names(tt) <- full_term_names
  if (length(pp) == n_theta) names(pp) <- full_term_names
  
  V_raw <- as.matrix(fit$varmat)
  
  if (nrow(V_raw) < n_theta || ncol(V_raw) < n_theta) {
    V_theta <- matrix(NA_real_, nrow = n_theta, ncol = n_theta)
  } else {
    V_theta <- V_raw[seq_len(n_theta), seq_len(n_theta), drop = FALSE]
  }
  
  dimnames(V_theta) <- list(full_term_names, full_term_names)
  
  list(theta = theta, se = se, t = tt, p = pp, V = V_theta)
}

lincomb_test <- function(b, V, w, label = "") {
  est <- as.numeric(sum(w * b))
  
  if (any(is.na(V))) {
    return(data.frame(
      label = label,
      estimate = est,
      se = NA_real_,
      z = NA_real_,
      p_value = NA_real_,
      stringsAsFactors = FALSE
    ))
  }
  
  var <- as.numeric(t(w) %*% V %*% w)
  se  <- if (is.finite(var) && var >= 0) sqrt(var) else NA_real_
  z   <- if (is.finite(se) && se > 0) est / se else NA_real_
  p   <- if (is.finite(z)) 2 * pnorm(-abs(z)) else NA_real_
  
  data.frame(
    label = label,
    estimate = est,
    se = se,
    z = z,
    p_value = p,
    stringsAsFactors = FALSE
  )
}

make_nuisance_block <- function(df, mode = "none") {
  if (mode == "none") return(NULL)
  
  z <- list()
  
  if (mode == "pulse_2008") {
    z[["pulse_2008"]] <- as.numeric(df$year == 2008L)
  } else if (mode == "block_2008_2009") {
    z[["block_2008_2009"]] <- as.numeric(df$year >= 2008L & df$year <= 2009L)
  } else if (mode == "block_2008_2010") {
    z[["block_2008_2010"]] <- as.numeric(df$year >= 2008L & df$year <= 2010L)
  } else {
    stop("Unknown NUISANCE_MODE: ", mode)
  }
  
  ans <- do.call(cbind, z)
  if (is.null(dim(ans))) {
    ans <- matrix(ans, ncol = 1)
    colnames(ans) <- names(z)
  }
  
  # drop all-zero nuisance columns inside windows where they do not apply
  keep <- colSums(abs(ans), na.rm = TRUE) > 0
  if (!any(keep)) return(NULL)
  
  ans[, keep, drop = FALSE]
}

build_deter_mat <- function(df, intercept_flag, include_nuisance = FALSE, nuisance_mode = "none") {
  cols <- list()
  
  if (intercept_flag) {
    cols[["const"]] <- rep(1, nrow(df))
  }
  
  if (isTRUE(include_nuisance)) {
    Z <- make_nuisance_block(df, nuisance_mode)
    if (!is.null(Z)) {
      for (j in seq_len(ncol(Z))) cols[[colnames(Z)[j]]] <- Z[, j]
    }
  }
  
  if (length(cols) == 0L) return(NULL)
  
  ans <- do.call(cbind, cols)
  if (is.null(dim(ans))) {
    ans <- matrix(ans, ncol = 1)
    colnames(ans) <- names(cols)
  }
  ans
}

compute_window_summary <- function(df, b, V) {
  omega_min  <- min(df$omega_t, na.rm = TRUE)
  omega_mean <- mean(df$omega_t, na.rm = TRUE)
  omega_max  <- max(df$omega_t, na.rm = TRUE)
  
  beta1 <- b["k"]
  beta2 <- b["wk"]
  
  w_min  <- rep(0, length(b)); names(w_min)  <- names(b)
  w_mean <- rep(0, length(b)); names(w_mean) <- names(b)
  w_max  <- rep(0, length(b)); names(w_max)  <- names(b)
  
  w_min["k"]  <- 1; w_min["wk"]  <- omega_min
  w_mean["k"] <- 1; w_mean["wk"] <- omega_mean
  w_max["k"]  <- 1; w_max["wk"]  <- omega_max
  
  lc_min  <- lincomb_test(b, V, w_min,  label = "theta_min")
  lc_mean <- lincomb_test(b, V, w_mean, label = "theta_mean")
  lc_max  <- lincomb_test(b, V, w_max,  label = "theta_max")
  
  data.frame(
    omega_min = omega_min,
    omega_mean = omega_mean,
    omega_max = omega_max,
    beta1_hat = beta1,
    beta1_se  = if ("k" %in% names(diag(V))) sqrt(V["k", "k"]) else NA_real_,
    beta1_p   = if ("k" %in% names(b)) NA_real_ else NA_real_,
    beta2_hat = beta2,
    beta2_se  = if ("wk" %in% rownames(V) && is.finite(V["wk", "wk"]) && V["wk", "wk"] >= 0) sqrt(V["wk", "wk"]) else NA_real_,
    beta2_p   = NA_real_,
    theta_at_omega_min = lc_min$estimate,
    theta_at_omega_mean = lc_mean$estimate,
    theta_at_omega_max = lc_max$estimate,
    theta_se_min = lc_min$se,
    theta_se_mean = lc_mean$se,
    theta_se_max = lc_max$se,
    delta_theta_obs = lc_max$estimate - lc_min$estimate,
    stringsAsFactors = FALSE
  )
}

estimate_window_model <- function(df, intercept_flag, estimator_label) {
  x_mat <- cbind(
    k  = df$k_t,
    wk = df$omega_t * df$k_t
  )
  
  deter_mat <- build_deter_mat(
    df = df,
    intercept_flag = intercept_flag,
    include_nuisance = INCLUDE_NUISANCE_CONTROLS,
    nuisance_mode = NUISANCE_MODE
  )
  
  fit <- tryCatch(
    switch(
      estimator_label,
      D_fixed = cointRegD(
        x = x_mat,
        y = df$y_t,
        deter = deter_mat,
        kernel = CR_KERNEL,
        bandwidth = CR_BANDWIDTH,
        n.lead = BASE_N_LEAD,
        n.lag  = BASE_N_LAG,
        check = TRUE
      ),
      D_auto = cointRegD(
        x = x_mat,
        y = df$y_t,
        deter = deter_mat,
        kernel = CR_KERNEL,
        bandwidth = CR_BANDWIDTH,
        n.lead = NULL,
        n.lag  = NULL,
        kmax = AUTO_KMAX,
        info.crit = AUTO_IC,
        check = TRUE
      ),
      FM = cointRegFM(
        x = x_mat,
        y = df$y_t,
        deter = deter_mat,
        kernel = CR_KERNEL,
        bandwidth = FM_BANDWIDTH,
        check = TRUE
      ),
      IM = cointRegIM(
        x = x_mat,
        y = df$y_t,
        deter = deter_mat,
        selector = IM_SELECTOR,
        t.test = TRUE,
        kernel = CR_KERNEL,
        bandwidth = IM_BANDWIDTH,
        check = TRUE
      ),
      stop("Unknown estimator")
    ),
    error = function(e) e
  )
  
  if (inherits(fit, "error")) {
    return(list(
      fit_ok = FALSE,
      fit_message = conditionMessage(fit)
    ))
  }
  
  deter_names <- if (!is.null(deter_mat)) colnames(deter_mat) else character(0)
  x_names <- colnames(x_mat)
  term_names <- c(deter_names, x_names)
  
  ext <- extract_fit_objects(fit, term_names)
  
  b_full <- ext$theta
  V_full <- ext$V
  
  b <- b_full[x_names]
  V <- V_full[x_names, x_names, drop = FALSE]
  
  coef_table <- data.frame(
    term = names(b_full),
    estimate = as.numeric(b_full),
    se = as.numeric(ext$se),
    z = as.numeric(ext$t),
    p_value = as.numeric(ext$p),
    stringsAsFactors = FALSE
  )
  
  # direct p-values from fitted object when available
  beta2_p <- coef_table$p_value[coef_table$term == "wk"]
  beta1_p <- coef_table$p_value[coef_table$term == "k"]
  
  summary_tab <- compute_window_summary(df, b, V)
  summary_tab$beta1_p <- if (length(beta1_p) == 1L) beta1_p else NA_real_
  summary_tab$beta2_p <- if (length(beta2_p) == 1L) beta2_p else NA_real_
  
  theta_t <- data.frame(
    year = df$year,
    omega_t = df$omega_t,
    theta_hat = b["k"] + b["wk"] * df$omega_t,
    stringsAsFactors = FALSE
  )
  
  if (!any(is.na(V))) {
    theta_se <- vapply(seq_len(nrow(df)), function(i) {
      w <- c(1, df$omega_t[i])
      names(w) <- c("k", "wk")
      var <- as.numeric(t(w) %*% V[c("k", "wk"), c("k", "wk"), drop = FALSE] %*% w)
      if (is.finite(var) && var >= 0) sqrt(var) else NA_real_
    }, numeric(1))
    
    theta_t$theta_se <- theta_se
    theta_t$theta_lo95 <- theta_t$theta_hat - 1.96 * theta_t$theta_se
    theta_t$theta_hi95 <- theta_t$theta_hat + 1.96 * theta_t$theta_se
  } else {
    theta_t$theta_se <- NA_real_
    theta_t$theta_lo95 <- NA_real_
    theta_t$theta_hi95 <- NA_real_
  }
  
  list(
    fit_ok = TRUE,
    fit_message = "",
    coef_table = coef_table,
    summary_tab = summary_tab,
    theta_t = theta_t
  )
}

# ------------------------------------------------------------------------------
# 3. Data load
# ------------------------------------------------------------------------------
d_raw <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
nf_inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))

d_raw <- merge(d_raw, nf_inc[, c("year", "Py_fred")], by = "year")
d_raw <- d_raw[order(d_raw$year), ]

Py_base <- d_raw$Py_fred[d_raw$year == REBASE_YEAR]
pK_base <- d_raw$pK_NF[d_raw$year == REBASE_YEAR]

if (length(Py_base) != 1L || length(pK_base) != 1L) {
  stop("Could not uniquely identify rebase-year values.")
}

d_raw$Y_real  <- d_raw$GVA_NF / (d_raw$Py_fred / Py_base)
d_raw$K_real  <- d_raw$KGC_NF / (d_raw$pK_NF / pK_base)
d_raw$y_t     <- log(d_raw$Y_real)
d_raw$k_t     <- log(d_raw$K_real)
d_raw$omega_t <- d_raw$Wsh_NF

# ------------------------------------------------------------------------------
# 4. Estimate all window models
# ------------------------------------------------------------------------------
all_coef_rows <- list()
all_sum_rows  <- list()
all_theta_rows <- list()

idx_coef <- 1L
idx_sum  <- 1L
idx_theta <- 1L

for (ww in windows) {
  df_w <- d_raw[d_raw$year >= ww$start & d_raw$year <= ww$end, ]
  if (nrow(df_w) == 0L) next
  
  for (sp in specs) {
    for (est in estimators) {
      res <- estimate_window_model(
        df = df_w,
        intercept_flag = sp$intercept,
        estimator_label = est
      )
      
      model_id <- paste(ww$label, sp$id, est, sep = "__")
      
      cat("\n============================================================\n")
      cat("MODEL:", model_id, "\n")
      cat("Window:", ww$start, "-", ww$end, "| Role:", ww$role, "\n")
      cat("============================================================\n")
      
      if (!isTRUE(res$fit_ok)) {
        cat("Fit failed:", res$fit_message, "\n")
        next
      }
      
      coef_tab <- res$coef_table
      coef_tab$model_id <- model_id
      coef_tab$window_label <- ww$label
      coef_tab$window_start <- ww$start
      coef_tab$window_end <- ww$end
      coef_tab$window_role <- ww$role
      coef_tab$spec_id <- sp$id
      coef_tab$estimator <- est
      coef_tab$intercept_flag <- sp$intercept
      all_coef_rows[[idx_coef]] <- coef_tab
      idx_coef <- idx_coef + 1L
      
      sum_tab <- res$summary_tab
      sum_tab$model_id <- model_id
      sum_tab$window_label <- ww$label
      sum_tab$window_start <- ww$start
      sum_tab$window_end <- ww$end
      sum_tab$window_role <- ww$role
      sum_tab$spec_id <- sp$id
      sum_tab$estimator <- est
      sum_tab$intercept_flag <- sp$intercept
      sum_tab$N <- nrow(df_w)
      all_sum_rows[[idx_sum]] <- sum_tab
      idx_sum <- idx_sum + 1L
      
      theta_tab <- res$theta_t
      theta_tab$model_id <- model_id
      theta_tab$window_label <- ww$label
      theta_tab$window_start <- ww$start
      theta_tab$window_end <- ww$end
      theta_tab$window_role <- ww$role
      theta_tab$spec_id <- sp$id
      theta_tab$estimator <- est
      theta_tab$intercept_flag <- sp$intercept
      all_theta_rows[[idx_theta]] <- theta_tab
      idx_theta <- idx_theta + 1L
      
      key_coef <- coef_tab[coef_tab$term %in% c("const", "k", "wk"), c("term", "estimate", "se", "z", "p_value")]
      key_coef$estimate <- fmt_num(key_coef$estimate, 4)
      key_coef$se       <- fmt_num(key_coef$se, 4)
      key_coef$z        <- fmt_num(key_coef$z, 3)
      key_coef$p_value  <- fmt_sci(key_coef$p_value, 3)
      
      cat("\n[Key coefficients]\n")
      print(key_coef, row.names = FALSE)
      
      sum_print <- sum_tab[, c(
        "omega_min", "omega_mean", "omega_max",
        "beta1_hat", "beta1_p",
        "beta2_hat", "beta2_p",
        "theta_at_omega_min", "theta_at_omega_mean", "theta_at_omega_max",
        "delta_theta_obs"
      )]
      for (nm in names(sum_print)) sum_print[[nm]] <- fmt_num(sum_print[[nm]], 4)
      
      cat("\n[Window summary]\n")
      print(sum_print, row.names = FALSE)
    }
  }
}

coef_out  <- do.call(rbind, all_coef_rows)
sum_out   <- do.call(rbind, all_sum_rows)
theta_out <- do.call(rbind, all_theta_rows)

# ------------------------------------------------------------------------------
# 4B. Add-on: Pre-Fordist comparison block
#   Paste AFTER the main estimation loop and BEFORE the export section
# ------------------------------------------------------------------------------

pre_fordist_windows <- list(
  list(label = "PreFordist_core_1929_1944", start = 1929L, end = 1944L, role = "predecessor"),
  list(label = "PreFordist_sensitivity_1929_1945", start = 1929L, end = 1945L, role = "predecessor_sensitivity")
)

pre_fordist_coef_rows <- list()
pre_fordist_sum_rows  <- list()
pre_fordist_theta_rows <- list()

idx_pf_coef  <- 1L
idx_pf_sum   <- 1L
idx_pf_theta <- 1L

for (ww in pre_fordist_windows) {
  df_w <- d_raw[d_raw$year >= ww$start & d_raw$year <= ww$end, ]
  if (nrow(df_w) == 0L) next
  
  for (sp in specs) {
    for (est in estimators) {
      res <- estimate_window_model(
        df = df_w,
        intercept_flag = sp$intercept,
        estimator_label = est
      )
      
      model_id <- paste(ww$label, sp$id, est, sep = "__")
      
      cat("\n============================================================\n")
      cat("MODEL:", model_id, "\n")
      cat("Window:", ww$start, "-", ww$end, "| Role:", ww$role, "\n")
      cat("============================================================\n")
      
      if (!isTRUE(res$fit_ok)) {
        cat("Fit failed:", res$fit_message, "\n")
        next
      }
      
      coef_tab <- res$coef_table
      coef_tab$model_id <- model_id
      coef_tab$window_label <- ww$label
      coef_tab$window_start <- ww$start
      coef_tab$window_end <- ww$end
      coef_tab$window_role <- ww$role
      coef_tab$spec_id <- sp$id
      coef_tab$estimator <- est
      coef_tab$intercept_flag <- sp$intercept
      pre_fordist_coef_rows[[idx_pf_coef]] <- coef_tab
      idx_pf_coef <- idx_pf_coef + 1L
      
      sum_tab <- res$summary_tab
      sum_tab$model_id <- model_id
      sum_tab$window_label <- ww$label
      sum_tab$window_start <- ww$start
      sum_tab$window_end <- ww$end
      sum_tab$window_role <- ww$role
      sum_tab$spec_id <- sp$id
      sum_tab$estimator <- est
      sum_tab$intercept_flag <- sp$intercept
      sum_tab$N <- nrow(df_w)
      pre_fordist_sum_rows[[idx_pf_sum]] <- sum_tab
      idx_pf_sum <- idx_pf_sum + 1L
      
      theta_tab <- res$theta_t
      theta_tab$model_id <- model_id
      theta_tab$window_label <- ww$label
      theta_tab$window_start <- ww$start
      theta_tab$window_end <- ww$end
      theta_tab$window_role <- ww$role
      theta_tab$spec_id <- sp$id
      theta_tab$estimator <- est
      theta_tab$intercept_flag <- sp$intercept
      pre_fordist_theta_rows[[idx_pf_theta]] <- theta_tab
      idx_pf_theta <- idx_pf_theta + 1L
      
      key_coef <- coef_tab[coef_tab$term %in% c("const", "k", "wk"), c("term", "estimate", "se", "z", "p_value")]
      key_coef$estimate <- fmt_num(key_coef$estimate, 4)
      key_coef$se       <- fmt_num(key_coef$se, 4)
      key_coef$z        <- fmt_num(key_coef$z, 3)
      key_coef$p_value  <- fmt_sci(key_coef$p_value, 3)
      
      cat("\n[Key coefficients]\n")
      print(key_coef, row.names = FALSE)
      
      sum_print <- sum_tab[, c(
        "omega_min", "omega_mean", "omega_max",
        "beta1_hat", "beta1_p",
        "beta2_hat", "beta2_p",
        "theta_at_omega_min", "theta_at_omega_mean", "theta_at_omega_max",
        "delta_theta_obs"
      )]
      for (nm in names(sum_print)) sum_print[[nm]] <- fmt_num(sum_print[[nm]], 4)
      
      cat("\n[Window summary]\n")
      print(sum_print, row.names = FALSE)
    }
  }
}

pre_fordist_coef_out  <- if (length(pre_fordist_coef_rows)  > 0L) do.call(rbind, pre_fordist_coef_rows)  else data.frame()
pre_fordist_sum_out   <- if (length(pre_fordist_sum_rows)   > 0L) do.call(rbind, pre_fordist_sum_rows)   else data.frame()
pre_fordist_theta_out <- if (length(pre_fordist_theta_rows) > 0L) do.call(rbind, pre_fordist_theta_rows) else data.frame()

cat("\n\n============================================================\n")
cat("POOLED PRE-FORDIST SUMMARY TABLE\n")
cat("============================================================\n")

if (nrow(pre_fordist_sum_out) > 0L) {
  pre_fordist_print <- pre_fordist_sum_out[, c(
    "window_label", "window_start", "window_end", "window_role",
    "spec_id", "estimator", "intercept_flag", "N",
    "beta2_hat", "beta2_p",
    "theta_at_omega_min", "theta_at_omega_mean", "theta_at_omega_max",
    "delta_theta_obs"
  )]
  
  num_cols_pf <- setdiff(names(pre_fordist_print), c(
    "window_label", "window_start", "window_end", "window_role",
    "spec_id", "estimator", "intercept_flag"
  ))
  pre_fordist_print[num_cols_pf] <- lapply(pre_fordist_print[num_cols_pf], fmt_num, k = 4)
  
  print(pre_fordist_print, row.names = FALSE)
} else {
  cat("No pre-Fordist results were produced.\n")
}
# ------------------------------------------------------------------------------
# 5. Console pooled summary table
# ------------------------------------------------------------------------------
cat("\n\n============================================================\n")
cat("POOLED WINDOW SUMMARY TABLE\n")
cat("============================================================\n")

sum_print <- sum_out[, c(
  "window_label", "window_start", "window_end", "window_role",
  "spec_id", "estimator", "intercept_flag", "N",
  "beta2_hat", "beta2_p",
  "theta_at_omega_min", "theta_at_omega_mean", "theta_at_omega_max",
  "delta_theta_obs"
)]

num_cols <- setdiff(names(sum_print), c(
  "window_label", "window_start", "window_end", "window_role",
  "spec_id", "estimator", "intercept_flag"
))
sum_print[num_cols] <- lapply(sum_print[num_cols], fmt_num, k = 4)

print(sum_print, row.names = FALSE)

# ------------------------------------------------------------------------------
# 6. Export
# ------------------------------------------------------------------------------
write.csv(coef_out,  file.path(outdir, "window_model_coefficients.csv"), row.names = FALSE)
write.csv(sum_out,   file.path(outdir, "window_model_summary.csv"), row.names = FALSE)
write.csv(theta_out, file.path(outdir, "window_model_theta_t_series.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(outdir, "sessionInfo_window_models.txt"))

cat("\nSaved outputs to:\n", outdir, "\n")


