#!/usr/bin/env Rscript

# US_S16_AD_controlled_imols_specA.R
#
# Specification A with Non-Accumulation Aggregate Demand Control (AD_t)
# ---------------------------------------------------------------------
# Tests whether controlling for non-accumulation aggregate demand
# (AD_t = C + G + NX, real annual, FRED chained 2017$) stabilises the
# profit-squeeze interaction theta_1 (k x omega_lag) that proved unstable
# across accumulation regimes in the baseline Spec A (S04 lock).
#
# Nested specifications (all IM-OLS, Regime B initial-state centering):
#   S0  : y ~ k + D                                  (pure scale baseline)
#   A   : y ~ k + omega + k*omega_lag + D            (original Spec A)
#   AD0 : y ~ AD + k + D                              (demand control only)
#   AD1 : y ~ AD + k + k*omega_lag + D                (TARGET SPEC)
#   AD2 : y ~ AD + k + omega + k*omega_lag + D        (full)
#
# Cointegration triad per model: EG-ADF on level residuals (MacKinnon 2010
# m-adjusted critical values), Shin (1994) LM (H0: cointegration), and
# Vogelsang-Wagner Type 2.
#
# Inputs:
#   output/gpim_baseline_components_long.csv
#   output/US/S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION/csv/
#     fred_annual_ad_components_panel.csv
#
# Output:
#   output/US/S16_AD_CONTROLLED_IMOLS_SPECA/csv/s16_ad_controlled_specA_results.csv

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(dplyr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_csv <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")
ad_csv    <- file.path(repo_root, "output", "US",
  "S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION", "csv",
  "fred_annual_ad_components_panel.csv")
out_dir   <- file.path(repo_root, "output", "US", "S16_AD_CONTROLLED_IMOLS_SPECA")
csv_dir   <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S16: AD_t-Controlled Specification A IM-OLS Nested Estimation\n")
cat("========================================================================\n")

## ==========================================================
## STEP 1: Data assembly
## ==========================================================

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_cap) & !is.na(df$omega_NFC_GVA) &
         !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

ad <- read.csv(ad_csv, stringsAsFactors = FALSE)
ad <- ad[, c("year", "log_AD_fred")]

df <- merge(df, ad, by = "year", all.x = TRUE)
df <- df[!is.na(df$log_AD_fred), ]
df <- df[order(df$year), ]

# Structural step-dummy controls (LOESS-inflection dates from baseline pipeline)
df$D1933 <- ifelse(df$year >= 1933, 1, 0)
df$D1947 <- ifelse(df$year >= 1947, 1, 0)
df$D1974 <- ifelse(df$year >= 1974, 1, 0)
df$D2008 <- ifelse(df$year >= 2008, 1, 0)

cat(sprintf("Merged panel: %d obs, %d-%d\n", nrow(df), min(df$year), max(df$year)))

## ==========================================================
## STEP 2: Windows and nested spec definitions
## ==========================================================

windows_list <- list(
  Full_Century_1929_2024          = list(range = c(1929, 2024), label = "Full Sample"),
  Long_Fordist_Era_1929_1973      = list(range = c(1929, 1973), label = "Fordism"),
  Long_Post_Fordist_Era_1974_2024 = list(range = c(1974, 2024), label = "Post-Fordism"),
  Diagnostic_Fordist_GoldenAge_1947_1973   = list(range = c(1947, 1973), label = "Golden Age"),
  Diagnostic_Neoliberal_Restruct_1974_2008   = list(range = c(1974, 2008), label = "Neoliberal Restructuring"),
  Diagnostic_Post_GFC_Stagnation_2009_2024   = list(range = c(2009, 2024), label = "Post-GFC Stagnation")
)

## ==========================================================
## STEP 3: IM-OLS wrapper with cointegration triad
## ==========================================================

safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  val[1]
}

# Asymptotic MacKinnon (2010) EG-ADF critical values by m = # I(1) variables
cv_adf <- function(m) {
  tab <- list(
    `2` = c(p01 = -3.90, p05 = -3.34, p10 = -3.04),
    `3` = c(p01 = -4.29, p05 = -3.74, p10 = -3.45),
    `4` = c(p01 = -4.64, p05 = -4.10, p10 = -3.81),
    `5` = c(p01 = -4.96, p05 = -4.42, p10 = -4.13),
    `6` = c(p01 = -5.25, p05 = -4.72, p10 = -4.43)
  )
  tab[[as.character(min(max(m, 2), 6))]]
}

# Approximate Vogelsang-Wagner Type 2 critical values by # stochastic regressors
cv_vw2 <- function(k) {
  tab <- list(
    `1` = c(p10 = 5.82,  p05 = 7.36,  p01 = 11.24),
    `2` = c(p10 = 8.60,  p05 = 10.33, p01 = 14.22),
    `3` = c(p10 = 11.45, p05 = 13.78, p01 = 18.90),
    `4` = c(p10 = 14.10, p05 = 16.70, p01 = 22.40),
    `5` = c(p10 = 16.60, p05 = 19.60, p01 = 26.00)
  )
  tab[[as.character(min(max(k, 1), 5))]]
}

calc_vw_type2 <- function(x, y, deter, fit) {
  tryCatch({
    y.T <- nrow(x); x.k <- ncol(x)
    d.k <- if (is.null(deter)) 0 else ncol(deter)
    Sx <- matrixStats::colCumsums(x)
    if (d.k == 0) Sd <- matrix(nrow = y.T, ncol = 0) else Sd <- matrixStats::colCumsums(deter)
    InvBase <- Sx[y.T:1, , drop = FALSE]
    InvBaseCum <- matrixStats::colCumsums(InvBase)
    RevBase <- InvBaseCum[y.T:1, , drop = FALSE]
    Zreg <- matrixStats::colCumsums(RevBase)
    if (d.k == 0) X2mat <- as.matrix(cbind(Sx, x, Zreg)) else X2mat <- as.matrix(cbind(Sd, Sx, x, Zreg))
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
    cv <- cv_vw2(x.k)
    stars <- if (!is.na(S_type2)) {
      if (S_type2 >= cv["p01"]) "***" else if (S_type2 >= cv["p05"]) "**" else if (S_type2 >= cv["p10"]) "*" else ""
    } else ""
    list(stat = S_type2, stars = stars)
  }, error = function(e) list(stat = NA, stars = ""))
}

cointRegIM_with_tests <- function(x, y, deter, kernel = "ba", bandwidth = "nw") {
  fit <- cointReg::cointRegIM(
    x = x, y = y, deter = deter,
    selector = c(1, 2), t.test = TRUE,
    kernel = kernel, bandwidth = bandwidth
  )

  # Stationary level residuals: fit$residuals[-1] (first entry is NA by IM-OLS)
  u <- fit$residuals
  if (any(is.na(u))) u <- u[!is.na(u)]
  T_obs <- length(u)
  m_i1 <- 1 + ncol(x)

  # 1. Engle-Granger ADF on level residuals
  t_adf <- NA; adf_verdict <- ""
  try({
    eg_lm <- stats::lm(diff(u) ~ u[-T_obs] - 1)
    t_adf <- summary(eg_lm)$coefficients[1, 3]
    cv <- cv_adf(m_i1)
    adf_verdict <- if (t_adf <= cv["p01"]) "coint_1pct" else
                   if (t_adf <= cv["p05"]) "coint_5pct" else
                   if (t_adf <= cv["p10"]) "coint_10pct" else "no_coint"
  }, silent = TRUE)

  # 2. Shin (1994) LM (H0: cointegration)
  C_shin <- NA; shin_verdict <- ""
  try({
    S_t <- cumsum(u)
    omega2 <- fit$omega.u.v
    if (is.null(omega2) || is.na(omega2) || omega2 <= 0) {
      omega2 <- cointReg::getLongRunVar(u, kernel = kernel, bandwidth = bandwidth)$long.run
    }
    C_shin <- sum(S_t^2) / (T_obs^2 * omega2)
    shin_verdict <- if (C_shin >= 0.184) "reject_1pct" else
                    if (C_shin >= 0.121) "reject_5pct" else
                    if (C_shin >= 0.095) "reject_10pct" else "coint_ok"
  }, silent = TRUE)

  # 3. VW Type 2
  vw <- tryCatch(calc_vw_type2(x, y, deter, fit), error = function(e) list(stat = NA, stars = ""))

  # 4. R2 and residual variance in levels
  y_mean <- mean(y)
  ss_tot <- sum((y - y_mean)^2)
  ss_res <- sum(u^2)
  r2_level <- max(0, 1 - (ss_res / ss_tot))
  sigma_u <- sqrt(ss_res / max(1, T_obs - ncol(x)))

  # 5. Condition number on regressor correlation matrix (matches baseline protocol CN <= 100)
  Xfull <- if (is.null(deter)) as.matrix(x) else as.matrix(cbind(deter, x))
  cn <- tryCatch(kappa(cor(Xfull), exact = TRUE), error = function(e) NA)

  fit$diagnostics <- list(
    T_obs = T_obs, m_i1 = m_i1,
    t_adf = safe_scalar(t_adf), adf_verdict = adf_verdict,
    C_shin = safe_scalar(C_shin), shin_verdict = shin_verdict,
    S_type2 = safe_scalar(vw$stat), vw_stars = vw$stars,
    r2_level = safe_scalar(r2_level), sigma_u = safe_scalar(sigma_u),
    cond_number = safe_scalar(cn)
  )
  fit
}

## ==========================================================
## STEP 4: Estimation loop (Regime B initial-state centering)
## ==========================================================

spec_defs <- list(
  S0  = list(regs = c("k"),                          label = "S0: Pure scale"),
  A   = list(regs = c("k", "w", "kw"),                 label = "A: Original Spec A"),
  AD0 = list(regs = c("ad", "k"),                      label = "AD0: Demand + scale"),
  AD1 = list(regs = c("ad", "k", "kw"),                 label = "AD1: Demand + scale + interaction"),
  AD2 = list(regs = c("ad", "k", "w", "kw"),           label = "AD2: Full")
)

results_list <- list()

for (win_name in names(windows_list)) {
  win_meta  <- windows_list[[win_name]]
  win_range <- win_meta$range
  win_lbl   <- win_meta$label

  sub <- df[df$year >= win_range[1] & df$year <= win_range[2], , drop = FALSE]
  if (nrow(sub) < 12) next

  # Regime B: initial-state centering within window
  k_c   <- sub$k_cap - sub$k_cap[1]
  w_c   <- sub$omega_NFC_GVA - sub$omega_NFC_GVA[1]
  wl_c  <- sub$omega_NFC_GVA_lag1 - sub$omega_NFC_GVA_lag1[1]
  ad_c  <- sub$log_AD_fred - sub$log_AD_fred[1]
  kw_c  <- k_c * wl_c
  y     <- sub$y_t

  # Deterministics: intercept + step dummies; drop any column constant within window
  deter <- as.matrix(cbind(Intercept = 1, sub[, c("D1933", "D1947", "D1974", "D2008")]))
  keep <- apply(deter, 2, function(z) length(unique(z)) > 1)
  if (sum(keep) == 0) {
    deter <- NULL
  } else {
    deter <- deter[, keep, drop = FALSE]
  }

  reg_mats <- list(
    k  = matrix(k_c,  ncol = 1, dimnames = list(NULL, "k_cap")),
    w  = matrix(w_c,  ncol = 1, dimnames = list(NULL, "omega")),
    ad = matrix(ad_c, ncol = 1, dimnames = list(NULL, "AD_t")),
    kw = matrix(kw_c, ncol = 1, dimnames = list(NULL, "k_x_omega_lag"))
  )

  for (spec_name in names(spec_defs)) {
    sd <- spec_defs[[spec_name]]
    x <- do.call(cbind, reg_mats[sd$regs])

    fit <- tryCatch(
      cointRegIM_with_tests(x, y, deter),
      error = function(e) { message("  FAIL ", win_name, "/", spec_name, ": ", e$message); NULL }
    )
    if (is.null(fit)) next

    ct <- fit$diagnostics
    theta <- fit$theta
    t_theta <- fit$t.theta

    # cointRegIM names stochastic coefficients with an "S." prefix.
    # t.theta is an unnamed numeric vector aligned with theta.
    get_pars <- function(nm) {
      s_nm <- paste0("S.", nm)
      idx <- which(names(theta) == s_nm)
      if (length(idx) == 1) {
        stats::setNames(c(theta[idx], t_theta[idx]), c("coef", "t"))
      } else {
        stats::setNames(c(NA_real_, NA_real_), c("coef", "t"))
      }
    }

    p_k     <- get_pars("k_cap")
    p_ad    <- get_pars("AD_t")
    p_w     <- get_pars("omega")
    p_kw    <- get_pars("k_x_omega_lag")

    row <- data.frame(
      window = win_lbl, window_id = win_name, spec = spec_name, spec_label = sd$label,
      n_obs = ct$T_obs, m_i1 = ct$m_i1,
      beta_AD    = p_ad["coef"], t_AD    = p_ad["t"],
      beta_k     = p_k["coef"],  t_k     = p_k["t"],
      beta_omega = p_w["coef"],  t_omega = p_w["t"],
      theta1     = p_kw["coef"], t_theta1= p_kw["t"],
      r2_level = ct$r2_level, sigma_u = ct$sigma_u, cond_number = ct$cond_number,
      t_adf = ct$t_adf, adf_verdict = ct$adf_verdict,
      C_shin = ct$C_shin, shin_verdict = ct$shin_verdict,
      S_type2 = ct$S_type2, vw_stars = ct$vw_stars,
      stringsAsFactors = FALSE
    )
    results_list[[paste(win_name, spec_name, sep = "_")]] <- row

    cat(sprintf("  %-24s %-38s  b_AD=%7.3f  th0=%7.3f  phi=%7.3f  th1=%8.3f (t=%6.2f)  Shin=%7.4f  ADF=%6.2f  CN=%7.2f  R2=%.3f\n",
                win_lbl, sd$label,
                ifelse(is.na(row$beta_AD), NA, row$beta_AD),
                ifelse(is.na(row$beta_k),  NA, row$beta_k),
                ifelse(is.na(row$beta_omega), NA, row$beta_omega),
                ifelse(is.na(row$theta1),  NA, row$theta1),
                ifelse(is.na(row$t_theta1), NA, row$t_theta1),
                ct$C_shin, ct$t_adf, ct$cond_number, ct$r2_level))
  }
}

results_df <- do.call(rbind, results_list)
rownames(results_df) <- NULL

write.csv(results_df, file.path(csv_dir, "s16_ad_controlled_specA_results.csv"), row.names = FALSE, na = "")
cat(sprintf("\n=== Written: %s ===\n", file.path(csv_dir, "s16_ad_controlled_specA_results.csv")))
