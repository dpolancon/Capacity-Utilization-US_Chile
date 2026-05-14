# 47_us_theta_break_core_1929_1978.R
# ==============================================================================
# U.S. historical-core theta model with known breaks
#   - one extended yearly theta_t series
#   - slope breaks at 1945 and 1974 by default
#   - estimators: fixed DOLS, auto DOLS, FM-OLS, IM-OLS
#   - console report tables + csv exports
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

outdir <- file.path(REPO, "output", "US_theta_break_core_1929_1978")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Core settings
# ------------------------------------------------------------------------------
SAMPLE_START <- 1929L
SAMPLE_END   <- 1978L

BREAK_45_START  <- 1945L
BREAK_73_START  <- 1974L   # set to 1973L if you want activation at 1973

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

INCLUDE_ADDITIVE_BREAK_STEPS <- FALSE  # keep FALSE for clean first pass

specs <- list(
  list(id = "B1_no_intercept",  intercept = FALSE),
  list(id = "B2_with_intercept", intercept = TRUE)
)

estimators <- c("D_fixed", "D_auto", "FM", "IM")

# ------------------------------------------------------------------------------
# 2. Helpers
# ------------------------------------------------------------------------------
fmt_num <- function(x, k = 4) {
  ifelse(is.na(x), NA_character_, formatC(x, digits = k, format = "f"))
}

fmt_sci <- function(x, k = 3) {
  ifelse(is.na(x), NA_character_, formatC(x, digits = k, format = "e"))
}

build_deter_mat <- function(df, intercept_flag, include_break_steps = FALSE) {
  cols <- list()
  
  if (intercept_flag) {
    cols[["const"]] <- rep(1, nrow(df))
  }
  if (include_break_steps) {
    cols[["D45"]] <- df$D45
    cols[["D73"]] <- df$D73
  }
  
  if (length(cols) == 0L) return(NULL)
  
  ans <- do.call(cbind, cols)
  if (is.null(dim(ans))) {
    ans <- matrix(ans, ncol = 1)
    colnames(ans) <- names(cols)
  }
  ans
}

extract_fit_objects <- function(fit, full_term_names, x_term_names) {
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
    stop(
      "varmat is too small to recover covariance of theta. ",
      "varmat is ", nrow(V_raw), "x", ncol(V_raw),
      " but theta has length ", n_theta, "."
    )
  }
  
  # For D-OLS, varmat can be for theta.all (includes auxiliary lead/lag regressors).
  # The reported theta / sd.theta / t.theta / p.theta correspond to the first n_theta terms.
  V_theta <- V_raw[seq_len(n_theta), seq_len(n_theta), drop = FALSE]
  dimnames(V_theta) <- list(full_term_names, full_term_names)
  
  list(theta = theta, se = se, t = tt, p = pp, V = V_theta)
}

lincomb_test <- function(b, V, w, label = "") {
  est <- as.numeric(sum(w * b))
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

wald_test <- function(b, V, R, r = NULL, label = "") {
  R <- as.matrix(R)
  if (is.null(r)) r <- rep(0, nrow(R))
  r <- as.numeric(r)
  
  q <- as.numeric(R %*% b - r)
  M <- R %*% V %*% t(R)
  
  stat <- tryCatch(
    as.numeric(t(q) %*% solve(M, q)),
    error = function(e) NA_real_
  )
  
  df <- nrow(R)
  p  <- if (is.finite(stat)) pchisq(stat, df = df, lower.tail = FALSE) else NA_real_
  
  data.frame(
    label = label,
    chi_sq = stat,
    df = df,
    p_value = p,
    stringsAsFactors = FALSE
  )
}

regime_rows <- function(df) {
  data.frame(
    regime = c("Pre-1945", "Fordist_1945_1973", "Aftermath_1974_1978"),
    start_year = c(min(df$year), BREAK_45_START, BREAK_73_START),
    end_year = c(BREAK_45_START - 1L, BREAK_73_START - 1L, max(df$year)),
    stringsAsFactors = FALSE
  )
}

compute_regime_lincombs <- function(df, b, V) {
  regs <- regime_rows(df)
  out <- list()
  
  for (i in seq_len(nrow(regs))) {
    rg <- regs[i, ]
    d45 <- as.numeric(rg$start_year >= BREAK_45_START)
    d73 <- as.numeric(rg$start_year >= BREAK_73_START)
    
    w_alpha <- rep(0, length(b)); names(w_alpha) <- names(b)
    w_beta  <- rep(0, length(b)); names(w_beta)  <- names(b)
    
    w_alpha["k"] <- 1
    w_beta["wk"] <- 1
    
    if ("D45_k" %in% names(b))  w_alpha["D45_k"]  <- d45
    if ("D73_k" %in% names(b))  w_alpha["D73_k"]  <- d73
    if ("D45_wk" %in% names(b)) w_beta["D45_wk"]  <- d45
    if ("D73_wk" %in% names(b)) w_beta["D73_wk"]  <- d73
    
    alpha_row <- lincomb_test(b, V, w_alpha, label = paste0(rg$regime, "_alpha"))
    beta_row  <- lincomb_test(b, V, w_beta,  label = paste0(rg$regime, "_beta2"))
    
    df_rg <- df[df$year >= rg$start_year & df$year <= rg$end_year, ]
    omega_min <- min(df_rg$omega_t, na.rm = TRUE)
    omega_max <- max(df_rg$omega_t, na.rm = TRUE)
    omega_mean <- mean(df_rg$omega_t, na.rm = TRUE)
    
    alpha_hat <- alpha_row$estimate
    beta_hat  <- beta_row$estimate
    
    theta_min  <- alpha_hat + beta_hat * omega_min
    theta_mean <- alpha_hat + beta_hat * omega_mean
    theta_max  <- alpha_hat + beta_hat * omega_max
    delta_theta_obs <- theta_max - theta_min
    
    out[[i]] <- data.frame(
      regime = rg$regime,
      start_year = rg$start_year,
      end_year = rg$end_year,
      omega_min = omega_min,
      omega_mean = omega_mean,
      omega_max = omega_max,
      alpha_hat = alpha_row$estimate,
      alpha_se  = alpha_row$se,
      alpha_p   = alpha_row$p_value,
      beta2_hat = beta_row$estimate,
      beta2_se  = beta_row$se,
      beta2_p   = beta_row$p_value,
      theta_at_omega_min = theta_min,
      theta_at_omega_mean = theta_mean,
      theta_at_omega_max = theta_max,
      delta_theta_obs = delta_theta_obs,
      stringsAsFactors = FALSE
    )
  }
  
  do.call(rbind, out)
}

compute_theta_t_series <- function(df, b, V) {
  key_terms <- c("k", "wk", "D45_k", "D45_wk", "D73_k", "D73_wk")
  missing_terms <- setdiff(key_terms, names(b))
  if (length(missing_terms) > 0L) {
    stop("Missing terms in coefficient vector: ", paste(missing_terms, collapse = ", "))
  }
  
  theta_rows <- vector("list", nrow(df))
  
  for (i in seq_len(nrow(df))) {
    yy <- df$year[i]
    ww <- df$omega_t[i]
    
    w <- rep(0, length(b)); names(w) <- names(b)
    w["k"]      <- 1
    w["wk"]     <- ww
    w["D45_k"]  <- df$D45[i]
    w["D45_wk"] <- df$D45[i] * ww
    w["D73_k"]  <- df$D73[i]
    w["D73_wk"] <- df$D73[i] * ww
    
    lc <- lincomb_test(b, V, w, label = as.character(yy))
    
    theta_rows[[i]] <- data.frame(
      year = yy,
      omega_t = ww,
      D45 = df$D45[i],
      D73 = df$D73[i],
      theta_hat = lc$estimate,
      theta_se  = lc$se,
      theta_lo95 = lc$estimate - 1.96 * lc$se,
      theta_hi95 = lc$estimate + 1.96 * lc$se,
      stringsAsFactors = FALSE
    )
  }
  
  do.call(rbind, theta_rows)
}

estimate_break_model <- function(df, intercept_flag, estimator_label) {
  x_mat <- cbind(
    k      = df$k_t,
    wk     = df$omega_t * df$k_t,
    D45_k  = df$D45 * df$k_t,
    D45_wk = df$D45 * df$omega_t * df$k_t,
    D73_k  = df$D73 * df$k_t,
    D73_wk = df$D73 * df$omega_t * df$k_t
  )
  
  deter_mat <- build_deter_mat(
    df = df,
    intercept_flag = intercept_flag,
    include_break_steps = INCLUDE_ADDITIVE_BREAK_STEPS
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
  
  ext <- extract_fit_objects(fit, term_names, x_names)
  
  # full coefficient vector for reporting
  b_full <- ext$theta
  
  # x-block only for regime calculations, Wald tests, theta_t
  b <- b_full[x_names]
  V <- ext$V[x_names, x_names, drop = FALSE]
  
  coef_table <- data.frame(
    term = names(b_full),
    estimate = as.numeric(b_full),
    se = as.numeric(ext$se),
    z = as.numeric(ext$t),
    p_value = as.numeric(ext$p),
    stringsAsFactors = FALSE
  )
  
  regime_table <- compute_regime_lincombs(df, b, V)
  
  wald_rows <- list()
  
  if ("D45_wk" %in% names(b)) {
    R <- matrix(0, nrow = 1, ncol = length(b), dimnames = list(NULL, names(b)))
    R[1, "D45_wk"] <- 1
    wald_rows[[length(wald_rows) + 1L]] <- wald_test(b, V, R, label = "Break_1945_interaction_only")
  }
  
  if ("D73_wk" %in% names(b)) {
    R <- matrix(0, nrow = 1, ncol = length(b), dimnames = list(NULL, names(b)))
    R[1, "D73_wk"] <- 1
    wald_rows[[length(wald_rows) + 1L]] <- wald_test(b, V, R, label = "Break_1974_interaction_only")
  }
  
  if (all(c("D45_k", "D45_wk") %in% names(b))) {
    R <- matrix(0, nrow = 2, ncol = length(b), dimnames = list(NULL, names(b)))
    R[1, "D45_k"]  <- 1
    R[2, "D45_wk"] <- 1
    wald_rows[[length(wald_rows) + 1L]] <- wald_test(b, V, R, label = "Break_1945_joint_k_and_interaction")
  }
  
  if (all(c("D73_k", "D73_wk") %in% names(b))) {
    R <- matrix(0, nrow = 2, ncol = length(b), dimnames = list(NULL, names(b)))
    R[1, "D73_k"]  <- 1
    R[2, "D73_wk"] <- 1
    wald_rows[[length(wald_rows) + 1L]] <- wald_test(b, V, R, label = "Break_1974_joint_k_and_interaction")
  }
  
  wald_table <- do.call(rbind, wald_rows)
  
  theta_t <- compute_theta_t_series(df, b, V)
  
  list(
    fit_ok = TRUE,
    fit_message = "",
    coef_table = coef_table,
    regime_table = regime_table,
    wald_table = wald_table,
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

d <- d_raw[d_raw$year >= SAMPLE_START & d_raw$year <= SAMPLE_END, ]
d$D45 <- as.numeric(d$year >= BREAK_45_START)
d$D73 <- as.numeric(d$year >= BREAK_73_START)

if (nrow(d) == 0L) stop("No data in requested sample.")

# ------------------------------------------------------------------------------
# 4. Estimate all models
# ------------------------------------------------------------------------------
all_coef_rows <- list()
all_regime_rows <- list()
all_wald_rows <- list()
all_theta_rows <- list()
summary_rows <- list()

idx_coef <- 1L
idx_reg  <- 1L
idx_wald <- 1L
idx_theta <- 1L
idx_sum <- 1L

for (sp in specs) {
  for (est in estimators) {
    res <- estimate_break_model(
      df = d,
      intercept_flag = sp$intercept,
      estimator_label = est
    )
    
    model_id <- paste(sp$id, est, sep = "__")
    cat("\n============================================================\n")
    cat("MODEL:", model_id, "\n")
    cat("Sample:", SAMPLE_START, "-", SAMPLE_END,
        "| Breaks:", BREAK_45_START, "and", BREAK_73_START, "\n")
    cat("============================================================\n")
    
    if (!isTRUE(res$fit_ok)) {
      cat("Fit failed:", res$fit_message, "\n")
      next
    }
    
    coef_tab <- res$coef_table
    coef_tab$model_id <- model_id
    coef_tab$spec_id <- sp$id
    coef_tab$estimator <- est
    coef_tab$intercept_flag <- sp$intercept
    all_coef_rows[[idx_coef]] <- coef_tab
    idx_coef <- idx_coef + 1L
    
    reg_tab <- res$regime_table
    reg_tab$model_id <- model_id
    reg_tab$spec_id <- sp$id
    reg_tab$estimator <- est
    reg_tab$intercept_flag <- sp$intercept
    all_regime_rows[[idx_reg]] <- reg_tab
    idx_reg <- idx_reg + 1L
    
    wald_tab <- res$wald_table
    wald_tab$model_id <- model_id
    wald_tab$spec_id <- sp$id
    wald_tab$estimator <- est
    wald_tab$intercept_flag <- sp$intercept
    all_wald_rows[[idx_wald]] <- wald_tab
    idx_wald <- idx_wald + 1L
    
    theta_tab <- res$theta_t
    theta_tab$model_id <- model_id
    theta_tab$spec_id <- sp$id
    theta_tab$estimator <- est
    theta_tab$intercept_flag <- sp$intercept
    all_theta_rows[[idx_theta]] <- theta_tab
    idx_theta <- idx_theta + 1L
    
    # Console report 1: key coefficients
    key_terms <- c("const", "D45", "D73", "k", "wk", "D45_k", "D45_wk", "D73_k", "D73_wk")
    key_coef <- coef_tab[coef_tab$term %in% key_terms, c("term", "estimate", "se", "z", "p_value")]
    key_coef$estimate <- fmt_num(key_coef$estimate, 4)
    key_coef$se       <- fmt_num(key_coef$se, 4)
    key_coef$z        <- fmt_num(key_coef$z, 3)
    key_coef$p_value  <- fmt_sci(key_coef$p_value, 3)
    
    cat("\n[Key coefficients]\n")
    print(key_coef, row.names = FALSE)
    
    # Console report 2: regime summaries
    reg_print <- reg_tab[, c(
      "regime", "start_year", "end_year",
      "omega_min", "omega_mean", "omega_max",
      "alpha_hat", "beta2_hat", "beta2_p",
      "theta_at_omega_min", "theta_at_omega_mean", "theta_at_omega_max",
      "delta_theta_obs"
    )]
    num_cols <- setdiff(names(reg_print), c("regime", "start_year", "end_year"))
    for (nm in num_cols) reg_print[[nm]] <- as.numeric(reg_print[[nm]])
    reg_print[num_cols] <- lapply(reg_print[num_cols], fmt_num, k = 4)
    
    cat("\n[Regime-specific beta2 and theta(omega)]\n")
    print(reg_print, row.names = FALSE)
    
    # Console report 3: break tests
    wald_print <- wald_tab[, c("label", "chi_sq", "df", "p_value")]
    wald_print$chi_sq <- fmt_num(wald_print$chi_sq, 4)
    wald_print$p_value <- fmt_sci(wald_print$p_value, 3)
    
    cat("\n[Known-break Wald tests]\n")
    print(wald_print, row.names = FALSE)
    
    # Compact summary row for pooled table
    reg_pre  <- reg_tab[reg_tab$regime == "Pre-1945", ]
    reg_for  <- reg_tab[reg_tab$regime == "Fordist_1945_1973", ]
    reg_post <- reg_tab[reg_tab$regime == "Aftermath_1974_1978", ]
    
    p45_int <- wald_tab$p_value[wald_tab$label == "Break_1945_interaction_only"]
    p74_int <- wald_tab$p_value[wald_tab$label == "Break_1974_interaction_only"]
    
    summary_rows[[idx_sum]] <- data.frame(
      model_id = model_id,
      spec_id = sp$id,
      estimator = est,
      intercept_flag = sp$intercept,
      beta2_pre = reg_pre$beta2_hat,
      p_beta2_pre = reg_pre$beta2_p,
      beta2_ford = reg_for$beta2_hat,
      p_beta2_ford = reg_for$beta2_p,
      beta2_post = reg_post$beta2_hat,
      p_beta2_post = reg_post$beta2_p,
      theta_ford_min = reg_for$theta_at_omega_min,
      theta_ford_mean = reg_for$theta_at_omega_mean,
      theta_ford_max = reg_for$theta_at_omega_max,
      p_break_1945_interaction = if (length(p45_int) == 0L) NA_real_ else p45_int,
      p_break_1974_interaction = if (length(p74_int) == 0L) NA_real_ else p74_int,
      stringsAsFactors = FALSE
    )
    idx_sum <- idx_sum + 1L
  }
}

coef_out   <- do.call(rbind, all_coef_rows)
regime_out <- do.call(rbind, all_regime_rows)
wald_out   <- do.call(rbind, all_wald_rows)
theta_out  <- do.call(rbind, all_theta_rows)
summary_out <- do.call(rbind, summary_rows)

# ------------------------------------------------------------------------------
# 5. Console pooled summary tables
# ------------------------------------------------------------------------------
cat("\n\n============================================================\n")
cat("POOLED SUMMARY TABLE\n")
cat("============================================================\n")

sum_print <- summary_out
num_cols <- setdiff(names(sum_print), c("model_id", "spec_id", "estimator", "intercept_flag"))
sum_print[num_cols] <- lapply(sum_print[num_cols], fmt_num, k = 4)
print(sum_print, row.names = FALSE)

# ------------------------------------------------------------------------------
# 6. Export
# ------------------------------------------------------------------------------
write.csv(coef_out,   file.path(outdir, "break_model_coefficients_1929_1978.csv"), row.names = FALSE)
write.csv(regime_out, file.path(outdir, "break_model_regime_summary_1929_1978.csv"), row.names = FALSE)
write.csv(wald_out,   file.path(outdir, "break_model_wald_tests_1929_1978.csv"), row.names = FALSE)
write.csv(theta_out,  file.path(outdir, "break_model_theta_t_series_1929_1978.csv"), row.names = FALSE)
write.csv(summary_out,file.path(outdir, "break_model_pooled_summary_1929_1978.csv"), row.names = FALSE)

writeLines(capture.output(sessionInfo()), file.path(outdir, "sessionInfo_break_model.txt"))

cat("\nSaved outputs to:\n", outdir, "\n")