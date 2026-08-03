#!/usr/bin/env Rscript

# US_S18_C_and_M_separate_controls_imols_specA.R
#
# Re-runs the S17 demand-control exercise but uses real log consumption (c)
# and real log imports (m) as SEPARATE variables rather than as the
# difference C - M.  This lets the data assign distinct signs to consumption
# demand and import leakage.
#
# Specifications tested:
#   A       : baseline Spec A (y ~ k + k*omega_lag + D)
#   Clvl    : A + real log C level as an extra I(1) regressor
#   Mlvl    : A + real log M level as an extra I(1) regressor
#   CMlvl   : A + both C and M levels as extra I(1) regressors
#   Cint    : A + k*c_lag interaction
#   Mint    : A + k*m_lag interaction
#   CMint   : A + both k*c_lag and k*m_lag interactions
#   CMintlvl: A + both interactions and both levels
#
# Method: cointReg::cointRegIM, Regime B initial-state centering, same
# diagnostic triad as S16/S17.
#
# Inputs:
#   output/gpim_baseline_components_long.csv
#   output/US/S15C_FRED_DEMAND_CONTROL_COINTEGRATION/csv/fred_ad_components_panel.csv
#
# Output:
#   output/US/S18_C_AND_M_SEPARATE_CONTROLS_SPECA/csv/
#     s18_c_and_m_separate_controls_specA_results.csv

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(dplyr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_csv <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")
cm_csv    <- file.path(repo_root, "output", "US",
  "S15C_FRED_DEMAND_CONTROL_COINTEGRATION", "csv",
  "fred_ad_components_panel.csv")
out_dir   <- file.path(repo_root, "output", "US", "S18_C_AND_M_SEPARATE_CONTROLS_SPECA")
csv_dir   <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S18: Separate C and M Controls — IM-OLS Spec A\n")
cat("========================================================================\n")

## ==========================================================
## STEP 1: Load baseline data
## ==========================================================

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_cap) &
         !is.na(df$omega_NFC_GVA) & !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

## ==========================================================
## STEP 2: Merge real C and M from S15C FRED panel
## ==========================================================

if (!file.exists(cm_csv)) stop("S15C FRED panel not found: ", cm_csv)
cm_panel <- read.csv(cm_csv, stringsAsFactors = FALSE)
cm_panel <- cm_panel[, c("year", "C_real", "M_real")]
cm_panel$c_t <- log(cm_panel$C_real)
cm_panel$m_t <- log(cm_panel$M_real)

df <- merge(df, cm_panel[, c("year", "c_t", "m_t")], by = "year", all.x = TRUE)

# Distributed/forward-looking lags parallel to omega_lag
df$c_lag1 <- dplyr::lag(df$c_t, n = 1L)
df$m_lag1 <- dplyr::lag(df$m_t, n = 1L)

cat(sprintf("Merged panel: %d obs, %d-%d  (C/M data: %d-%d)\n",
            nrow(df), min(df$year), max(df$year),
            min(df$year[!is.na(df$c_lag1)], na.rm = TRUE),
            max(df$year[!is.na(df$c_lag1)], na.rm = TRUE)))

## ==========================================================
## STEP 3: Dummies and windows
## ==========================================================

df$D1933 <- ifelse(df$year >= 1933, 1, 0)
df$D1947 <- ifelse(df$year >= 1947, 1, 0)
df$D1974 <- ifelse(df$year >= 1974, 1, 0)
df$D2008 <- ifelse(df$year >= 2008, 1, 0)

windows_list <- list(
  Full_Century_1929_2024          = list(range = c(1929, 2024), label = "Full Sample"),
  Long_Fordist_Era_1929_1973      = list(range = c(1929, 1973), label = "Fordism"),
  Long_Post_Fordist_Era_1974_2024 = list(range = c(1974, 2024), label = "Post-Fordism"),
  Diagnostic_Fordist_GoldenAge_1947_1973   = list(range = c(1947, 1973), label = "Golden Age"),
  Diagnostic_Neoliberal_Restruct_1974_2008 = list(range = c(1974, 2008), label = "Neoliberal Restructuring"),
  Diagnostic_Post_GFC_Stagnation_2009_2024 = list(range = c(2009, 2024), label = "Post-GFC Stagnation")
)

## ==========================================================
## STEP 4: IM-OLS wrapper (identical to S16/S17)
## ==========================================================

safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  val[1]
}

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
  fit <- cointReg::cointRegIM(x = x, y = y, deter = deter,
    selector = c(1, 2), t.test = TRUE, kernel = kernel, bandwidth = bandwidth)

  u <- fit$residuals
  if (any(is.na(u))) u <- u[!is.na(u)]
  T_obs <- length(u)
  m_i1 <- 1 + ncol(x)

  t_adf <- NA; adf_verdict <- ""
  try({
    eg_lm <- stats::lm(diff(u) ~ u[-T_obs] - 1)
    t_adf <- summary(eg_lm)$coefficients[1, 3]
    cv <- cv_adf(m_i1)
    adf_verdict <- if (t_adf <= cv["p01"]) "coint_1pct" else
                   if (t_adf <= cv["p05"]) "coint_5pct" else
                   if (t_adf <= cv["p10"]) "coint_10pct" else "no_coint"
  }, silent = TRUE)

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

  vw <- tryCatch(calc_vw_type2(x, y, deter, fit), error = function(e) list(stat = NA, stars = ""))

  y_mean <- mean(y)
  ss_tot <- sum((y - y_mean)^2)
  ss_res <- sum(u^2)
  r2_level <- max(0, 1 - (ss_res / ss_tot))
  sigma_u <- sqrt(ss_res / max(1, T_obs - ncol(x)))

  Xfull <- if (is.null(deter)) as.matrix(x) else {
    det_cn <- deter[, apply(as.matrix(deter), 2, var, na.rm = TRUE) > 1e-12, drop = FALSE]
    as.matrix(cbind(det_cn, x))
  }
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
## STEP 5: Estimation loop
## ==========================================================

spec_defs <- list(
  A        = list(regs = c("k", "w", "kw"), xtra_det = NULL,
                  label = "A: Original Spec A"),
  CMdiff   = list(regs = c("k", "kcm"), xtra_det = NULL,
                  label = "CMdiff: k*(C-M) interaction (S17 target)"),
  Clvl     = list(regs = c("k", "w", "kw", "c"), xtra_det = NULL,
                  label = "Clvl: A + real log C level"),
  Mlvl     = list(regs = c("k", "w", "kw", "m"), xtra_det = NULL,
                  label = "Mlvl: A + real log M level"),
  CMlvl    = list(regs = c("k", "w", "kw", "c", "m"), xtra_det = NULL,
                  label = "CMlvl: A + C and M levels"),
  Cint     = list(regs = c("k", "w", "kw", "kc"), xtra_det = NULL,
                  label = "Cint: A + k*C interaction"),
  Mint     = list(regs = c("k", "w", "kw", "km"), xtra_det = NULL,
                  label = "Mint: A + k*M interaction"),
  CMint    = list(regs = c("k", "w", "kw", "kc", "km"), xtra_det = NULL,
                  label = "CMint: A + k*C and k*M interactions"),
  CMintlvl = list(regs = c("k", "w", "kw", "c", "m", "kc", "km"), xtra_det = NULL,
                  label = "CMintlvl: A + C/M levels and interactions")
)

results_list <- list()

for (win_name in names(windows_list)) {
  win_meta  <- windows_list[[win_name]]
  win_range <- win_meta$range
  win_lbl   <- win_meta$label

  sub <- df[df$year >= win_range[1] & df$year <= win_range[2], , drop = FALSE]
  if (nrow(sub) < 12) next

  # Regime B centering
  anchor <- function(z) z - z[which(!is.na(z))[1]]

  k_c  <- anchor(sub$k_cap)
  w_c  <- anchor(sub$omega_NFC_GVA)
  wl_c <- anchor(sub$omega_NFC_GVA_lag1)
  kw_c <- k_c * wl_c

  c_c   <- anchor(sub$c_lag1)
  m_c   <- anchor(sub$m_lag1)
  kc_c  <- k_c * c_c
  km_c  <- k_c * m_c
  kcm_c <- k_c * (c_c - m_c)

  y <- sub$y_t

  base_det <- as.matrix(cbind(Intercept = 1, sub[, c("D1933", "D1947", "D1974", "D2008")]))
  keep <- apply(base_det, 2, function(z) length(unique(z)) > 1)
  base_det <- base_det[, keep, drop = FALSE]

  reg_mats <- list(
    k    = matrix(k_c,    ncol = 1, dimnames = list(NULL, "k_cap")),
    w    = matrix(w_c,    ncol = 1, dimnames = list(NULL, "omega")),
    kw   = matrix(kw_c,   ncol = 1, dimnames = list(NULL, "k_x_omega_lag")),
    c    = matrix(c_c,    ncol = 1, dimnames = list(NULL, "c_lag")),
    m    = matrix(m_c,    ncol = 1, dimnames = list(NULL, "m_lag")),
    kc   = matrix(kc_c,   ncol = 1, dimnames = list(NULL, "k_x_c_lag")),
    km   = matrix(km_c,   ncol = 1, dimnames = list(NULL, "k_x_m_lag")),
    kcm  = matrix(kcm_c,  ncol = 1, dimnames = list(NULL, "k_x_cm_lag"))
  )

  for (spec_name in names(spec_defs)) {
    sd <- spec_defs[[spec_name]]

    x <- do.call(cbind, reg_mats[sd$regs])

    # Keep rows with valid x
    valid <- complete.cases(x)
    if (sum(valid) < 12) next

    x <- x[valid, , drop = FALSE]
    y_sub <- y[valid]
    det_sub <- base_det[valid, , drop = FALSE]

    # Add extra deterministic controls if any (none for this exercise)
    if (length(sd$xtra_det) > 0) {
      for (v in sd$xtra_det) {
        det_sub <- cbind(det_sub, reg_mats[[v]][valid, , drop = FALSE])
      }
    }

    fit <- tryCatch(
      cointRegIM_with_tests(x, y_sub, det_sub),
      error = function(e) { message("  FAIL ", win_name, "/", spec_name, ": ", e$message); NULL }
    )
    if (is.null(fit)) next

    ct <- fit$diagnostics
    theta <- fit$theta
    t_theta <- fit$t.theta

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
    p_w     <- get_pars("omega")
    p_kw    <- get_pars("k_x_omega_lag")
    p_c     <- get_pars("c_lag")
    p_m     <- get_pars("m_lag")
    p_kc    <- get_pars("k_x_c_lag")
    p_km    <- get_pars("k_x_m_lag")
    p_kcm   <- get_pars("k_x_cm_lag")

    row <- data.frame(
      window = win_lbl, window_id = win_name, spec = spec_name, spec_label = sd$label,
      n_obs = ct$T_obs, m_i1 = ct$m_i1,
      theta0_k     = p_k["coef"],      t_k        = p_k["t"],
      beta_omega   = p_w["coef"],      t_omega    = p_w["t"],
      theta1_kw    = p_kw["coef"],     t_theta1_kw= p_kw["t"],
      beta_c_level = p_c["coef"],      t_c_level  = p_c["t"],
      beta_m_level = p_m["coef"],      t_m_level  = p_m["t"],
      theta1_kc    = p_kc["coef"],     t_theta1_kc= p_kc["t"],
      theta1_km    = p_km["coef"],     t_theta1_km= p_km["t"],
      theta1_kcm   = p_kcm["coef"],    t_theta1_kcm= p_kcm["t"],
      r2_level = ct$r2_level, sigma_u = ct$sigma_u, cond_number = ct$cond_number,
      t_adf = ct$t_adf, adf_verdict = ct$adf_verdict,
      C_shin = ct$C_shin, shin_verdict = ct$shin_verdict,
      S_type2 = ct$S_type2, vw_stars = ct$vw_stars,
      stringsAsFactors = FALSE
    )
    results_list[[paste(win_name, spec_name, sep = "_")]] <- row

    cat(sprintf(
      "  %-24s %-42s  th0=%7.3f  th1_kw=%8.3f (t=%6.2f)  th1_kc=%8.3f (t=%6.2f)  th1_km=%8.3f (t=%6.2f)  Shin=%7.4f  ADF=%6.2f  CN=%7.2f\n",
      win_lbl, sd$label,
      ifelse(is.na(row$theta0_k), 0, row$theta0_k),
      ifelse(is.na(row$theta1_kw), 0, row$theta1_kw),
      ifelse(is.na(row$t_theta1_kw), 0, row$t_theta1_kw),
      ifelse(is.na(row$theta1_kc), 0, row$theta1_kc),
      ifelse(is.na(row$t_theta1_kc), 0, row$t_theta1_kc),
      ifelse(is.na(row$theta1_km), 0, row$theta1_km),
      ifelse(is.na(row$t_theta1_km), 0, row$t_theta1_km),
      safe_scalar(ct$C_shin, 0), safe_scalar(ct$t_adf, 0),
      safe_scalar(ct$cond_number, 0)), "\n")
  }
}

results_df <- do.call(rbind, results_list)
results_df <- results_df[order(results_df$window, results_df$spec), ]
results_file <- file.path(csv_dir, "s18_c_and_m_separate_controls_specA_results.csv")
write.csv(results_df, results_file, row.names = FALSE)

cat("\nSaved:", results_file, "\n")
cat("Rows:", nrow(results_df), "\n")
