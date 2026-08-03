#!/usr/bin/env Rscript

# US_S19_final_demand_controls_imols_specA.R
#
# Final demand-control robustness for Spec A:
#
#   1. Stationary C-M spread as a deterministic control:
#      y ~ k + k*omega + (c - m)_{t-1} + D
#
#   2. C-M spread + interaction (CM2 from S17) for completeness.
#
#   3. Separate real log C and M growth rates as deterministic controls:
#      y ~ k + k*omega + Δc_t + Δm_t + D      (lagged one period)
#      y ~ k + k*omega + Δc_t + D
#      y ~ k + k*omega + Δm_t + D
#
# Because all added variables are I(0), they enter through the deterministic
# matrix and do not expand the cointegrating space.
#
# Inputs:
#   output/gpim_baseline_components_long.csv
#   output/US/S15C_FRED_DEMAND_CONTROL_COINTEGRATION/csv/fred_ad_components_panel.csv
#
# Output:
#   output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/csv/
#     s19_final_demand_controls_specA_results.csv

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
out_dir   <- file.path(repo_root, "output", "US", "S19_FINAL_DEMAND_CONTROLS_SPECA")
csv_dir   <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S19: I(0) Demand Controls — CM spread and C/M growth rates — IM-OLS Spec A\n")
cat("========================================================================\n")

## ==========================================================
## STEP 1: Load baseline data and merge C/M panel
## ==========================================================

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_cap) &
         !is.na(df$omega_NFC_GVA) & !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

if (!file.exists(cm_csv)) stop("S15C FRED panel not found: ", cm_csv)
cm_panel <- read.csv(cm_csv, stringsAsFactors = FALSE)
cm_panel <- cm_panel[, c("year", "C_real", "M_real")]
cm_panel$c_t <- log(cm_panel$C_real)
cm_panel$m_t <- log(cm_panel$M_real)
cm_panel$cm_t <- cm_panel$c_t - cm_panel$m_t

# One-period log differences (annual growth rates), lead/lag-safe via dplyr
cm_panel <- cm_panel %>%
  arrange(year) %>%
  mutate(dc_t = c_t - dplyr::lag(c_t, 1L),
         dm_t = m_t - dplyr::lag(m_t, 1L),
         dcm_t = cm_t - dplyr::lag(cm_t, 1L))

# Use lagged growth rates as demand controls (induced changes, avoid simultaneity)
cm_panel$dc_lag1 <- dplyr::lag(cm_panel$dc_t, 1L)
cm_panel$dm_lag1 <- dplyr::lag(cm_panel$dm_t, 1L)
cm_panel$cm_lag1 <- dplyr::lag(cm_panel$cm_t, 1L)

df <- merge(df, cm_panel[, c("year", "c_t", "m_t", "cm_t",
                              "dc_lag1", "dm_lag1", "cm_lag1")],
            by = "year", all.x = TRUE)

cat(sprintf("Merged panel: %d obs, %d-%d  (C/M demand controls: %d-%d)\n",
            nrow(df), min(df$year), max(df$year),
            min(df$year[!is.na(df$cm_lag1)], na.rm = TRUE),
            max(df$year[!is.na(df$cm_lag1)], na.rm = TRUE)))

## ==========================================================
## STEP 2: Dummies and windows
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
## STEP 3: IM-OLS wrapper (identical to S17/S18)
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
## STEP 4: Estimation loop
## ==========================================================

spec_defs <- list(
  A         = list(regs = c("k", "w", "kw"), xtra_det = NULL,
                   label = "A: Original Spec A"),
  CMlevel   = list(regs = c("k", "w", "kw"), xtra_det = c("cm_lag1"),
                   label = "A + (c-m)_{t-1} level"),
  CMboth    = list(regs = c("k", "w", "kw", "kcm"), xtra_det = c("cm_lag1"),
                   label = "A + (c-m)_{t-1} + k*(c-m)_{t-1}"),
  Dc        = list(regs = c("k", "w", "kw"), xtra_det = c("dc_lag1"),
                   label = "A + Δc_{t-1}"),
  Dm        = list(regs = c("k", "w", "kw"), xtra_det = c("dm_lag1"),
                   label = "A + Δm_{t-1}"),
  DcDm      = list(regs = c("k", "w", "kw"), xtra_det = c("dc_lag1", "dm_lag1"),
                   label = "A + Δc_{t-1} + Δm_{t-1}")
)

results_list <- list()

for (win_name in names(windows_list)) {
  win_meta  <- windows_list[[win_name]]
  win_range <- win_meta$range
  win_lbl   <- win_meta$label

  sub <- df[df$year >= win_range[1] & df$year <= win_range[2], , drop = FALSE]
  if (nrow(sub) < 12) next

  anchor <- function(z) z - z[which(!is.na(z))[1]]

  k_c   <- anchor(sub$k_cap)
  w_c   <- anchor(sub$omega_NFC_GVA)
  wl_c  <- anchor(sub$omega_NFC_GVA_lag1)
  kw_c  <- k_c * wl_c
  cm_c  <- anchor(sub$cm_lag1)
  kcm_c <- k_c * cm_c
  dc_c  <- sub$dc_lag1
  dm_c  <- sub$dm_lag1
  y     <- sub$y_t

  base_det <- as.matrix(cbind(Intercept = 1, sub[, c("D1933", "D1947", "D1974", "D2008")]))
  keep <- apply(base_det, 2, function(z) length(unique(z)) > 1)
  base_det <- base_det[, keep, drop = FALSE]

  reg_mats <- list(
    k    = matrix(k_c,    ncol = 1, dimnames = list(NULL, "k_cap")),
    w    = matrix(w_c,    ncol = 1, dimnames = list(NULL, "omega")),
    kw   = matrix(kw_c,   ncol = 1, dimnames = list(NULL, "k_x_omega_lag")),
    kcm  = matrix(kcm_c,  ncol = 1, dimnames = list(NULL, "k_x_cm_lag"))
  )

  det_cols <- list(
    cm_lag1 = matrix(cm_c, ncol = 1, dimnames = list(NULL, "cm_lag1")),
    dc_lag1 = matrix(dc_c, ncol = 1, dimnames = list(NULL, "dc_lag1")),
    dm_lag1 = matrix(dm_c, ncol = 1, dimnames = list(NULL, "dm_lag1"))
  )

  for (spec_name in names(spec_defs)) {
    sd <- spec_defs[[spec_name]]

    x <- do.call(cbind, reg_mats[sd$regs])

    valid <- complete.cases(x)
    extra_names <- unique(c(sd$xtra_det, if ("kcm" %in% sd$regs) "cm_lag1" else NULL))
    if (length(extra_names) > 0) {
      for (v in extra_names) valid <- valid & !is.na(det_cols[[v]][, 1])
    }
    if (sum(valid) < 12) next

    x <- x[valid, , drop = FALSE]
    y_sub <- y[valid]
    det_sub <- base_det[valid, , drop = FALSE]

    if (length(sd$xtra_det) > 0) {
      for (v in sd$xtra_det) {
        det_sub <- cbind(det_sub, det_cols[[v]][valid, , drop = FALSE])
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
    p_kcm   <- get_pars("k_x_cm_lag")

    # Deterministic control coefficients are also in fit$theta / sd.theta / t.theta
    p_cm <- get_pars("cm_lag1")
    p_dc <- get_pars("dc_lag1")
    p_dm <- get_pars("dm_lag1")

    row <- data.frame(
      window = win_lbl, window_id = win_name, spec = spec_name, spec_label = sd$label,
      n_obs = ct$T_obs, m_i1 = ct$m_i1,
      theta0_k    = p_k["coef"],  t_k     = p_k["t"],
      beta_omega  = p_w["coef"],  t_omega = p_w["t"],
      theta1_kw   = p_kw["coef"], t_theta1_kw = p_kw["t"],
      theta1_kcm  = p_kcm["coef"],t_theta1_kcm= p_kcm["t"],
      beta_cm     = p_cm["coef"], t_cm    = p_cm["t"],
      beta_dc     = p_dc["coef"], t_dc    = p_dc["t"],
      beta_dm     = p_dm["coef"], t_dm    = p_dm["t"],
      r2_level = ct$r2_level, sigma_u = ct$sigma_u, cond_number = ct$cond_number,
      t_adf = ct$t_adf, adf_verdict = ct$adf_verdict,
      C_shin = ct$C_shin, shin_verdict = ct$shin_verdict,
      S_type2 = ct$S_type2, vw_stars = ct$vw_stars,
      stringsAsFactors = FALSE
    )

    results_list[[paste(win_name, spec_name, sep = "_")]] <- row

    cat(sprintf("  %-24s %-48s  th0=%7.3f  th1_kw=%9.2f (t=%6.2f)  th1_kcm=%9.2f (t=%6.2f)  dc=%7.3f(t=%5.2f) dm=%7.3f(t=%5.2f) cm=%7.3f(t=%5.2f)  C_Shin=%7.4f  CN=%7.2f\n",
                win_lbl, sd$label,
                ifelse(is.na(row$theta0_k), 0, row$theta0_k),
                ifelse(is.na(row$theta1_kw), 0, row$theta1_kw),
                ifelse(is.na(row$t_theta1_kw), 0, row$t_theta1_kw),
                ifelse(is.na(row$theta1_kcm), 0, row$theta1_kcm),
                ifelse(is.na(row$t_theta1_kcm), 0, row$t_theta1_kcm),
                ifelse(is.na(row$beta_dc), 0, row$beta_dc),
                ifelse(is.na(row$t_dc), 0, row$t_dc),
                ifelse(is.na(row$beta_dm), 0, row$beta_dm),
                ifelse(is.na(row$t_dm), 0, row$t_dm),
                ifelse(is.na(row$beta_cm), 0, row$beta_cm),
                ifelse(is.na(row$t_cm), 0, row$t_cm),
                safe_scalar(ct$C_shin, 0),
                safe_scalar(ct$cond_number, 0)), "\n")
  }
}

results_df <- do.call(rbind, results_list)
results_df <- results_df[order(results_df$window, results_df$spec), ]
results_file <- file.path(csv_dir, "s19_final_demand_controls_specA_results.csv")
write.csv(results_df, results_file, row.names = FALSE)

cat("\nSaved:", results_file, "\n")
cat("Rows:", nrow(results_df), "\n")
