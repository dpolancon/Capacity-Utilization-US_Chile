#!/usr/bin/env Rscript

# US_S17_AD_control_alternatives_imols_specA.R
#
# Tests two alternatives to the level AD_t control that was rejected in S16:
#
#   1. Nominal non-accumulation demand share of GDP:
#      AD_share_t = 1 - I_t^n / GDP_t^n   (nominal investment share residual)
#      Placed as a deterministic (I(0)) control alongside step dummies.
#      Target: y ~ k + k*omega_lag + D + AD_share
#
#   2. Real log consumption-minus-imports (c - m) as a distributionally
#      induced control replacing the wage-share interaction:
#      cm_t = log(C_t^{real}) - log(M_t^{real})
#      Standalone cm enters as deterministic control;
#      interaction k*cm_lag enters in x.
#      Target: y ~ k + k*cm_lag + D (+ optional cm_lag)
#
# Method: cointReg::cointRegIM, Regime B initial-state centering, same
# triad diagnostics as S16.
#
# Inputs:
#   output/gpim_baseline_components_long.csv
#   output/US/S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION/csv/
#     fred_annual_ad_components_panel.csv
#   FRED annual nominal series: GDPA, GPDIA
#
# Output:
#   output/US/S17_AD_CONTROL_ALTERNATIVES_IMOLS_SPECA/csv/
#     s17_ad_control_alternatives_specA_results.csv

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
out_dir   <- file.path(repo_root, "output", "US", "S17_AD_CONTROL_ALTERNATIVES_IMOLS_SPECA")
csv_dir   <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S17: AD-Share and C-M Alternative Controls — IM-OLS Spec A\n")
cat("========================================================================\n")

## ==========================================================
## STEP 1: Load baseline data
## ==========================================================

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_cap) & !is.na(df$omega_NFC_GVA) &
         !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

# C-M uses the S15C FRED quarterly-to-annual panel which has C_real and M_real
s15c_csv <- file.path(repo_root, "output", "US",
  "S15C_FRED_DEMAND_CONTROL_COINTEGRATION", "csv",
  "fred_ad_components_panel.csv")

if (!file.exists(s15c_csv)) stop("S15C FRED panel not found: ", s15c_csv)
cm_panel <- read.csv(s15c_csv, stringsAsFactors = FALSE)
cm_panel <- cm_panel[, c("year", "C_real", "M_real")]
cm_panel$cm_t <- log(cm_panel$C_real) - log(cm_panel$M_real)

df <- merge(df, cm_panel[, c("year", "cm_t")], by = "year", all.x = TRUE)

## ==========================================================
## STEP 2: Fetch nominal AD share from FRED (GDPA, GPDIA annual)
## ==========================================================

FRED_KEY <- Sys.getenv("FRED_API_KEY")
if (!nzchar(FRED_KEY)) stop("FRED_API_KEY is not set.")

fetch_fred_annual <- function(series_id) {
  resp <- httr::GET(
    "https://api.stlouisfed.org/fred/series/observations",
    query = list(api_key = FRED_KEY, file_type = "json", series_id = series_id,
                 frequency = "a", aggregation_method = "avg", units = "lin"),
    httr::timeout(120)
  )
  httr::stop_for_status(resp)
  payload <- httr::content(resp, as = "parsed", simplifyVector = FALSE)
  obs <- payload$observations
  df <- data.frame(
    year = suppressWarnings(as.integer(substr(sapply(obs, function(x) x$date), 1, 4))),
    value = suppressWarnings(as.numeric(sapply(obs, function(x) x$value))),
    stringsAsFactors = FALSE
  )
  df <- df[!is.na(df$year) & !is.na(df$value), ] |> arrange(year)
  message(sprintf("  %s: %d obs (%d-%d), last = %.3f",
                  series_id, nrow(df), min(df$year), max(df$year), tail(df$value, 1)))
  df
}

message("=== Fetching nominal GDP and investment for AD share ===")
gdp_n <- fetch_fred_annual("GDPA") |> rename(GDP_n = value)
inv_n <- fetch_fred_annual("GPDIA") |> rename(I_n = value)
share_df <- gdp_n |>
  inner_join(inv_n, by = "year") |>
  mutate(AD_share = 1 - I_n / GDP_n) |>
  select(year, AD_share)

df <- merge(df, share_df, by = "year", all.x = TRUE)
df <- df[order(df$year), ]

# Construct lagged cm (distributed/forward-looking, parallel to omega_lag)
df$cm_lag1 <- dplyr::lag(df$cm_t, n = 1L)

cat(sprintf("Merged panel: %d obs, %d-%d  (AD share: %d-%d, C-M: %d-%d)\n",
            nrow(df), min(df$year), max(df$year),
            min(df$year[!is.na(df$AD_share)]), max(df$year[!is.na(df$AD_share)]),
            min(df$year[!is.na(df$cm_lag1)], na.rm = TRUE),
            max(df$year[!is.na(df$cm_lag1)], na.rm = TRUE)))

# Step dummies
df$D1933 <- ifelse(df$year >= 1933, 1, 0)
df$D1947 <- ifelse(df$year >= 1947, 1, 0)
df$D1974 <- ifelse(df$year >= 1974, 1, 0)
df$D2008 <- ifelse(df$year >= 2008, 1, 0)

## ==========================================================
## STEP 3: Windows and nested spec definitions
## ==========================================================

windows_list <- list(
  Full_Century_1929_2024          = list(range = c(1929, 2024), label = "Full Sample"),
  Long_Fordist_Era_1929_1973      = list(range = c(1929, 1973), label = "Fordism"),
  Long_Post_Fordist_Era_1974_2024 = list(range = c(1974, 2024), label = "Post-Fordism"),
  Diagnostic_Fordist_GoldenAge_1947_1973   = list(range = c(1947, 1973), label = "Golden Age"),
  Diagnostic_Neoliberal_Restruct_1974_2008 = list(range = c(1974, 2008), label = "Neoliberal Restructuring"),
  Diagnostic_Post_GFC_Stagnation_2009_2024 = list(range = c(2009, 2024), label = "Post-GFC Stagnation")
)

## ==========================================================
## STEP 4: IM-OLS wrapper (same as S16)
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
    # Remove any deterministic columns with zero variance (e.g. step dummies
    # that become constant after trimming for non-missing C-M observations)
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

# Spec naming:<parameter name="spec_defs"> list for JSON </parameter>
spec_defs <- list(
  S0      = list(regs = c("k"), xtra_det = NULL,
                 label = "S0: Pure scale"),
  A       = list(regs = c("k", "w", "kw"), xtra_det = NULL,
                 label = "A: Original Spec A"),
  Ash0    = list(regs = c("k"), xtra_det = c("AD_share"),
                 label = "Ash0: AD share + scale"),
  Ash1    = list(regs = c("k", "kw"), xtra_det = c("AD_share"),
                 label = "Ash1: AD share + k*omega (target)"),
  Ash2    = list(regs = c("k", "w", "kw"), xtra_det = c("AD_share"),
                 label = "Ash2: AD share + full wage-share"),
  CM0     = list(regs = c("k"), xtra_det = c("cm_lag1"),
                 label = "CM0: C-M level + scale"),
  CM1     = list(regs = c("k", "kcm"), xtra_det = NULL,
                 label = "CM1: k*(C-M) interaction only (target)"),
  CM2     = list(regs = c("k", "kcm"), xtra_det = c("cm_lag1"),
                 label = "CM2: k*(C-M) + C-M level"),
  CM3     = list(regs = c("k", "kw", "kcm"), xtra_det = NULL,
                 label = "CM3: Both k*omega and k*(C-M)")
)

results_list <- list()

for (win_name in names(windows_list)) {
  win_meta  <- windows_list[[win_name]]
  win_range <- win_meta$range
  win_lbl   <- win_meta$label

  sub <- df[df$year >= win_range[1] & df$year <= win_range[2], , drop = FALSE]
  if (nrow(sub) < 12) next

  # Regime B centering: anchor to the first *non-NA* observation in the window
  anchor <- function(z) z - z[which(!is.na(z))[1]]

  k_c   <- anchor(sub$k_cap)
  w_c   <- anchor(sub$omega_NFC_GVA)
  wl_c  <- anchor(sub$omega_NFC_GVA_lag1)
  kw_c  <- k_c * wl_c

  adshare_c <- anchor(sub$AD_share)
  cm_c      <- anchor(sub$cm_lag1)
  kcm_c     <- k_c * cm_c
  y         <- sub$y_t

  # Base deterministics (intercept + step dummies); drop constant columns
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
    AD_share = matrix(adshare_c, ncol = 1, dimnames = list(NULL, "AD_share")),
    cm_lag1  = matrix(cm_c,      ncol = 1, dimnames = list(NULL, "cm_lag1"))
  )

  for (spec_name in names(spec_defs)) {
    sd <- spec_defs[[spec_name]]

    # Build x from I(1) regressors
    x <- do.call(cbind, reg_mats[sd$regs])

    # Filter rows with non-missing x AND any extra deterministic variables
    required <- c(sd$xtra_det, "cm_lag1")  # cm_lag1 used for kcm product
    extra_names <- unique(c(sd$xtra_det, if ("kcm" %in% sd$regs) "cm_lag1" else NULL))
    valid <- complete.cases(x)
    if (length(extra_names) > 0) {
      for (v in extra_names) valid <- valid & !is.na(det_cols[[v]][, 1])
    }
    if (sum(valid) < 12) next

    x <- x[valid, , drop = FALSE]
    y_sub <- y[valid]
    det_sub <- base_det[valid, , drop = FALSE]

    # Add extra deterministic controls
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

    p_k    <- get_pars("k_cap")
    p_w    <- get_pars("omega")
    p_kw   <- get_pars("k_x_omega_lag")
    p_kcm  <- get_pars("k_x_cm_lag")

    row <- data.frame(
      window = win_lbl, window_id = win_name, spec = spec_name, spec_label = sd$label,
      n_obs = ct$T_obs, m_i1 = ct$m_i1,
      theta0_k    = p_k["coef"],  t_k    = p_k["t"],
      beta_omega  = p_w["coef"],  t_omega = p_w["t"],
      theta1_kw   = p_kw["coef"], t_theta1_kw = p_kw["t"],
      theta1_kcm  = p_kcm["coef"], t_theta1_kcm = p_kcm["t"],
      r2_level = ct$r2_level, sigma_u = ct$sigma_u, cond_number = ct$cond_number,
      t_adf = ct$t_adf, adf_verdict = ct$adf_verdict,
      C_shin = ct$C_shin, shin_verdict = ct$shin_verdict,
      S_type2 = ct$S_type2, vw_stars = ct$vw_stars,
      stringsAsFactors = FALSE
    )
    results_list[[paste(win_name, spec_name, sep = "_")]] <- row

    cat(sprintf("  %-24s %-38s  th0=%7.3f  th1_kw=%8.3f (t=%6.2f)  th1_kcm=%8.3f (t=%6.2f)  Shin=%7.4f  ADF=%6.2f  CN=%7.2f\n",
                win_lbl, sd$label,
                ifelse(is.na(row$theta0_k), 0, row$theta0_k),
                ifelse(is.na(row$theta1_kw), 0, row$theta1_kw),
                ifelse(is.na(row$t_theta1_kw), 0, row$t_theta1_kw),
                ifelse(is.na(row$theta1_kcm), 0, row$theta1_kcm),
                ifelse(is.na(row$t_theta1_kcm), 0, row$t_theta1_kcm),
                ct$C_shin, ct$t_adf, ct$cond_number))
  }
}

results_df <- do.call(rbind, results_list)
rownames(results_df) <- NULL

write.csv(results_df, file.path(csv_dir, "s17_ad_control_alternatives_specA_results.csv"), row.names = FALSE, na = "")
cat(sprintf("\n=== Written: %s ===\n", file.path(csv_dir, "s17_ad_control_alternatives_specA_results.csv")))
