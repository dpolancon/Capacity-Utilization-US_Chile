#!/usr/bin/env Rscript

# US_S43_auxiliary_dummy_diagnostics.R
#
# S43: diagnostic sweep of auxiliary step/block dummies beyond the WD set
# (D1933, D1947, D1974, D2008, WWII block). Candidates (historical events):
#
#   B1937_38  Roosevelt recession      block  (tier-2, pre-1947)
#   B1950_53  Korean War               block
#   B1957_58  Eisenhower recession     block
#   S1971     Nixon shock              step
#   B1979_82  Volcker shock (episode)  block
#   S1979     Volcker shock (regime)   step
#   B2000_01  Dot-com bust             block
#   B2020_21  COVID                    block
#
# Design (approved plan, 2026-08-01):
#   - Capital A (k_cap) only, on the frozen S41 extended panel (the live
#     gpim_baseline_components_long.csv is under un-reviewed repair and is
#     NOT read here).
#   - Tier 1 (primary): locked FRED (c-m) control, 1947+ (clean I(0)).
#     Windows: Fordism-effective 1949-1973, Post 1974-2024, Full 1949-2024.
#   - Tier 2 (secondary): S42A extended NIPA control, 1929+, for the
#     Roosevelt block and full-Fordist re-checks. Carries the S42
#     I(1)-indicated disclosure.
#   - Reference ND/WD cells re-estimated and wire-checked against the
#     frozen S41/S42 ledgers (<1e-8).
#   - One-at-a-time augmentation on both ND and WD bases; joint cell with
#     all candidates significant at 10% (WD base); residual mean-shift
#     scan + CUSUM on the reference ND residuals (descriptive only).
#   - No halting gates: all verdicts recorded for the report.
#
# Estimator: IM-OLS per the E10V lock; "ba"/"nw" kernel/bandwidth is the
# inference-layer convention only (coefficients kernel-invariant).
# Governance: DIAGNOSTIC branch (S43). No frozen artifact modified. No
# candidate is auto-promoted into the WD set.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(cointReg)
  library(dplyr)
  library(ggplot2)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
ext_csv <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data",
                     "s41_extended_capital_panel.csv")
fred_csv <- file.path(repo_root, "output", "US",
                      "S15C_FRED_DEMAND_CONTROL_COINTEGRATION", "csv",
                      "fred_ad_components_panel.csv")
nipa_csv <- file.path(repo_root, "output", "US", "S42_CM_EXTENSION", "csv",
                      "s42a_extended_cm_control_panel.csv")
s41_ledger_csv <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION",
                            "csv", "s41_estimation_ledger.csv")
s42_ledger_csv <- file.path(repo_root, "output", "US", "S42_CM_EXTENSION",
                            "csv", "s42_estimation_ledger.csv")
out_dir <- file.path(repo_root, "output", "US", "S43_DUMMY_DIAGNOSTICS")
csv_dir <- file.path(out_dir, "csv")
fig_dir <- file.path(out_dir, "figs")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

diagnostic_stamp <- "DIAGNOSTIC_ONLY;S43_BRANCH"

cat("========================================================================\n")
cat("S43: Auxiliary step/block dummy diagnostics\n")
cat("========================================================================\n")

## ==========================================================
## STEP 0: Panels and controls
## ==========================================================

df <- read.csv(ext_csv, stringsAsFactors = FALSE)
df <- df[!is.na(df$y_t) & !is.na(df$k_cap) &
         !is.na(df$omega_NFC_GVA) & !is.na(df$omega_NFC_GVA_lag1), ]
df <- df[order(df$year), ]

# Tier-1 control: locked FRED panel (identical construction to S41)
fred <- read.csv(fred_csv, stringsAsFactors = FALSE)[, c("year", "C_real", "M_real")]
fred$cm_t <- log(fred$C_real) - log(fred$M_real)
fred <- fred %>% arrange(year) %>% mutate(cm_lag1 = dplyr::lag(cm_t, 1L))

# Tier-2 control: S42A extended NIPA panel
nipa <- read.csv(nipa_csv, stringsAsFactors = FALSE)[, c("year", "cm_t", "cm_lag1")]

# all.x = TRUE preserves pre-control panel rows so the anchor point of k
# is the nominal-window start (matches S41/S42 anchoring exactly)
df_fred <- merge(df, fred[, c("year", "cm_t", "cm_lag1")], by = "year",
                 all.x = TRUE)
df_nipa <- merge(df, nipa, by = "year", all.x = TRUE)

# Existing WD set
add_wd <- function(d) {
  d$D1933 <- as.numeric(d$year >= 1933)
  d$D1947 <- as.numeric(d$year >= 1947)
  d$D1974 <- as.numeric(d$year >= 1974)
  d$D2008 <- as.numeric(d$year >= 2008)
  d$D_WWII <- as.numeric(d$year >= 1942 & d$year <= 1945)
  d
}

# S43 candidates
add_candidates <- function(d) {
  d$B1937_38 <- as.numeric(d$year %in% 1937:1938)
  d$B1950_53 <- as.numeric(d$year %in% 1950:1953)
  d$B1957_58 <- as.numeric(d$year %in% 1957:1958)
  d$S1971    <- as.numeric(d$year >= 1971)
  d$B1979_82 <- as.numeric(d$year %in% 1979:1982)
  d$S1979    <- as.numeric(d$year >= 1979)
  d$B2000_01 <- as.numeric(d$year %in% 2000:2001)
  d$B2020_21 <- as.numeric(d$year %in% 2020:2021)
  d
}

df_fred <- add_candidates(add_wd(df_fred))
df_nipa <- add_candidates(add_wd(df_nipa))

wd_cols <- c("D1933", "D1947", "D1974", "D2008", "D_WWII")
candidates <- data.frame(
  code  = c("B1937_38", "B1950_53", "B1957_58", "S1971",
            "B1979_82", "S1979", "B2000_01", "B2020_21"),
  event = c("Roosevelt recession", "Korean War", "Eisenhower recession",
            "Nixon shock", "Volcker shock (episode)", "Volcker shock (regime)",
            "Dot-com bust", "COVID"),
  form  = c("block", "block", "block", "step", "block", "step", "block", "block"),
  stringsAsFactors = FALSE
)

cat(sprintf("Tier-1 (FRED) panel: %d obs %d-%d | Tier-2 (NIPA): %d obs %d-%d\n",
            nrow(df_fred), min(df_fred$year), max(df_fred$year),
            nrow(df_nipa), min(df_nipa$year), max(df_nipa$year)))

## ==========================================================
## IM-OLS wrapper (verbatim from US_S42B / US_S41 / US_S19)
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

  y_mean <- mean(y)
  ss_tot <- sum((y - y_mean)^2)
  ss_res <- sum(u^2)
  r2_level <- max(0, 1 - (ss_res / ss_tot))
  sigma_u <- sqrt(ss_res / max(1, T_obs - ncol(x)))

  det_cn <- deter[, apply(as.matrix(deter), 2, var, na.rm = TRUE) > 1e-12,
                  drop = FALSE]
  Xfull <- as.matrix(cbind(det_cn, x))
  cn <- tryCatch(kappa(cor(Xfull), exact = TRUE), error = function(e) NA)

  fit$diagnostics <- list(
    T_obs = T_obs,
    t_adf = safe_scalar(t_adf), adf_verdict = adf_verdict,
    C_shin = safe_scalar(C_shin), shin_verdict = shin_verdict,
    r2_level = safe_scalar(r2_level), sigma_u = safe_scalar(sigma_u),
    cond_number = safe_scalar(cn)
  )
  fit
}

get_pars <- function(fit, nm) {
  s_nm <- paste0("S.", nm)
  idx <- which(names(fit$theta) == s_nm)
  if (length(idx) == 1) c(coef = fit$theta[[idx]], t = fit$t.theta[[idx]])
  else c(coef = NA_real_, t = NA_real_)
}

anchor <- function(z) z - z[which(!is.na(z))[1]]

## ==========================================================
## Generalized cell estimator: arbitrary extra dummy columns
## ==========================================================

run_cell_s43 <- function(sub, cell_id, window_label, base_dummies, extra_dummies,
                         tier) {
  k_c  <- anchor(sub$k_cap)
  wl_c <- anchor(sub$omega_NFC_GVA_lag1)
  kw_c <- k_c * wl_c
  cm_c <- anchor(sub$cm_lag1)

  x <- cbind(k_cap = k_c, k_x_omega_lag = kw_c)
  valid <- complete.cases(x) & !is.na(cm_c)
  if (sum(valid) < 12) return(NULL)

  dum_all <- c(base_dummies, extra_dummies)
  det <- as.matrix(cbind(Intercept = rep(1, nrow(sub)),
    if (length(dum_all)) sub[, dum_all, drop = FALSE]))

  x_s <- x[valid, , drop = FALSE]
  det_v <- det[valid, , drop = FALSE]
  keep <- apply(det_v, 2, function(z) length(unique(z)) > 1)
  keep["Intercept"] <- TRUE
  dropped <- setdiff(colnames(det_v)[!keep], "Intercept")
  det_v <- det_v[, keep, drop = FALSE]
  # If the candidate itself is degenerate on the effective sample, the cell
  # is uninformative about it — record and skip.
  if (length(extra_dummies) && all(extra_dummies %in% dropped)) {
    return(list(skipped = TRUE, cell_id = cell_id, dropped = dropped))
  }
  det_s <- cbind(det_v, cm_lag1 = cm_c[valid])
  y_s <- sub$y_t[valid]

  fit <- tryCatch(cointRegIM_with_tests(x_s, y_s, det_s),
    error = function(e) { message("  FAIL ", cell_id, ": ", e$message); NULL })
  if (is.null(fit)) return(NULL)

  ct <- fit$diagnostics
  p_k  <- get_pars(fit, "k_cap")
  p_kw <- get_pars(fit, "k_x_omega_lag")
  p_cm <- get_pars(fit, "cm_lag1")
  cand_coef <- if (length(extra_dummies) == 1) {
    get_pars(fit, extra_dummies)
  } else c(coef = NA_real_, t = NA_real_)
  eff_years <- sub$year[valid]

  list(skipped = FALSE, row = data.frame(
    cell_id = cell_id, window = window_label, tier = tier,
    base = if (length(base_dummies)) "WD" else "ND",
    candidate = if (length(extra_dummies) == 1) extra_dummies else
                if (length(extra_dummies) == 0) "(none)" else
                paste(extra_dummies, collapse = "+"),
    n_obs = ct$T_obs, eff_start = min(eff_years), eff_end = max(eff_years),
    theta0_k = p_k[["coef"]], t_k = p_k[["t"]],
    theta1_kw = p_kw[["coef"]], t_theta1_kw = p_kw[["t"]],
    beta_cm = p_cm[["coef"]], t_cm = p_cm[["t"]],
    gamma_cand = cand_coef[["coef"]], t_gamma_cand = cand_coef[["t"]],
    dropped_degenerate = paste(dropped, collapse = ";"),
    r2_level = ct$r2_level, sigma_u = ct$sigma_u,
    cond_number = ct$cond_number,
    t_adf = ct$t_adf, adf_verdict = ct$adf_verdict,
    C_shin = ct$C_shin, shin_verdict = ct$shin_verdict,
    stamp = diagnostic_stamp, stringsAsFactors = FALSE
  ), residuals = fit$residuals, years = eff_years)
}

## ==========================================================
## STEP 1: Reference cells + wiring check
## ==========================================================

cat("\n--- Reference cells + wiring check ---\n")

windows_t1 <- list(
  Fordism = c(1929, 1973),   # effective 1949-1973 under FRED control
  `Post-Fordism` = c(1974, 2024),
  `Full` = c(1929, 2024)     # effective 1949-2024 under FRED control
)

refs <- list(); resid_store <- list(); rows <- list(); skips <- list()

for (win in names(windows_t1)) {
  sub <- df_fred[df_fred$year >= windows_t1[[win]][1] &
                 df_fred$year <= windows_t1[[win]][2], , drop = FALSE]
  for (base in c("ND", "WD")) {
    cell_id <- sprintf("T1-%s-%s-REF", win, base)
    res <- run_cell_s43(sub, cell_id, win,
                        if (base == "WD") wd_cols else character(0),
                        character(0), "T1_FRED")
    if (is.null(res) || isTRUE(res$skipped)) next
    refs[[paste(win, base, "T1")]] <- res$row
    rows[[cell_id]] <- res$row
    if (base == "ND") resid_store[[paste0("T1-", win)]] <-
      list(u = res$residuals, years = res$years)
    cat(sprintf("  %-28s T=%3d th1=%8.3f (t=%6.2f)\n",
                cell_id, res$row$n_obs, res$row$theta1_kw, res$row$t_theta1_kw))
  }
}

# Tier-2 reference: full Fordist window with NIPA control (matches S42 A-Ford)
sub_t2 <- df_nipa[df_nipa$year >= 1929 & df_nipa$year <= 1973, , drop = FALSE]
for (base in c("ND", "WD")) {
  cell_id <- sprintf("T2-Fordism-%s-REF", base)
  res <- run_cell_s43(sub_t2, cell_id, "Fordism",
                      if (base == "WD") wd_cols else character(0),
                      character(0), "T2_NIPA")
  if (is.null(res) || isTRUE(res$skipped)) next
  refs[[paste("Fordism", base, "T2")]] <- res$row
  rows[[cell_id]] <- res$row
  if (base == "ND") resid_store[["T2-Fordism"]] <-
    list(u = res$residuals, years = res$years)
  cat(sprintf("  %-28s T=%3d th1=%8.3f (t=%6.2f)\n",
              cell_id, res$row$n_obs, res$row$theta1_kw, res$row$t_theta1_kw))
}

# Wiring check: T1 Fordism ND must equal S41 A-Ford; T2 Fordism ND/WD must
# equal S42 A-Ford-ND/WD.
s41_led <- read.csv(s41_ledger_csv, stringsAsFactors = FALSE)
s42_led <- read.csv(s42_ledger_csv, stringsAsFactors = FALSE)
wiring <- rbind(
  data.frame(check = "T1_Ford_ND_vs_S41_AFord",
    s43 = refs[["Fordism ND T1"]]$theta1_kw,
    frozen = s41_led$theta1_kw[grepl("^A-Ford", s41_led$cell_id)][1]),
  data.frame(check = "T2_Ford_ND_vs_S42_AFordND",
    s43 = refs[["Fordism ND T2"]]$theta1_kw,
    frozen = s42_led$theta1_kw[s42_led$cell_id == "A-Ford-ND"]),
  data.frame(check = "T2_Ford_WD_vs_S42_AFordWD",
    s43 = refs[["Fordism WD T2"]]$theta1_kw,
    frozen = s42_led$theta1_kw[s42_led$cell_id == "A-Ford-WD"])
)
wiring$abs_diff <- abs(wiring$s43 - wiring$frozen)
wiring$pass <- wiring$abs_diff < 1e-8
write.csv(wiring, file.path(csv_dir, "s43_wiring_check.csv"), row.names = FALSE)
cat("\nWiring check:\n"); print(wiring, digits = 10)
if (!all(wiring$pass)) cat("  WARNING: wiring mismatch recorded (not halting)\n")

## ==========================================================
## STEP 2: One-at-a-time candidate grid
## ==========================================================

cat("\n--- One-at-a-time candidate cells ---\n")

grid_windows <- list(
  list(win = "Fordism",       tier = "T1_FRED", data = df_fred, rng = c(1929, 1973)),
  list(win = "Post-Fordism",  tier = "T1_FRED", data = df_fred, rng = c(1974, 2024)),
  list(win = "Full",          tier = "T1_FRED", data = df_fred, rng = c(1929, 2024)),
  list(win = "Fordism",       tier = "T2_NIPA", data = df_nipa, rng = c(1929, 1973))
)

for (g in grid_windows) {
  sub <- g$data[g$data$year >= g$rng[1] & g$data$year <= g$rng[2], , drop = FALSE]
  tshort <- if (g$tier == "T1_FRED") "T1" else "T2"
  for (cand in candidates$code) {
    for (base in c("ND", "WD")) {
      cell_id <- sprintf("%s-%s-%s+%s", tshort, g$win, base, cand)
      res <- run_cell_s43(sub, cell_id, g$win,
                          if (base == "WD") wd_cols else character(0),
                          cand, g$tier)
      if (is.null(res)) next
      if (isTRUE(res$skipped)) {
        skips[[cell_id]] <- data.frame(cell_id = cell_id,
          reason = "candidate degenerate on effective sample")
        next
      }
      ref <- refs[[paste(g$win, base, tshort)]]
      res$row$d_theta1 <- res$row$theta1_kw - ref$theta1_kw
      res$row$d_t_theta1 <- res$row$t_theta1_kw - ref$t_theta1_kw
      res$row$d_cn <- res$row$cond_number - ref$cond_number
      rows[[cell_id]] <- res$row
      cat(sprintf("  %-26s th1=%8.3f (d=%+6.3f) gam=%8.3f (t=%6.2f) CN=%7.1f\n",
                  cell_id, res$row$theta1_kw, res$row$d_theta1,
                  res$row$gamma_cand, res$row$t_gamma_cand, res$row$cond_number))
    }
  }
}

## ==========================================================
## STEP 3: Joint cells (candidates significant at 10% on WD base)
## ==========================================================

cat("\n--- Joint cells (|t_gamma| >= 1.645 on WD base) ---\n")

ledger_tmp <- bind_rows(rows)
for (g in grid_windows) {
  tshort <- if (g$tier == "T1_FRED") "T1" else "T2"
  sig <- ledger_tmp %>%
    filter(window == g$win, tier == g$tier, base == "WD",
           candidate %in% candidates$code,
           !is.na(t_gamma_cand), abs(t_gamma_cand) >= 1.645) %>%
    pull(candidate)
  # S1979/B1979_82 are alternative forms of the same event; if both pass,
  # keep the more significant one to avoid near-collinear duplication.
  if (all(c("S1979", "B1979_82") %in% sig)) {
    tv <- ledger_tmp %>% filter(window == g$win, tier == g$tier, base == "WD",
                                candidate %in% c("S1979", "B1979_82"))
    drop_form <- tv$candidate[which.min(abs(tv$t_gamma_cand))]
    sig <- setdiff(sig, drop_form)
  }
  if (length(sig) < 2) {
    cat(sprintf("  %s-%s: %d significant candidate(s) — joint cell skipped\n",
                tshort, g$win, length(sig)))
    next
  }
  sub <- g$data[g$data$year >= g$rng[1] & g$data$year <= g$rng[2], , drop = FALSE]
  cell_id <- sprintf("%s-%s-WD+JOINT", tshort, g$win)
  res <- run_cell_s43(sub, cell_id, g$win, wd_cols, sig, g$tier)
  if (is.null(res) || isTRUE(res$skipped)) next
  ref <- refs[[paste(g$win, "WD", tshort)]]
  res$row$d_theta1 <- res$row$theta1_kw - ref$theta1_kw
  res$row$d_t_theta1 <- res$row$t_theta1_kw - ref$t_theta1_kw
  res$row$d_cn <- res$row$cond_number - ref$cond_number
  rows[[cell_id]] <- res$row
  cat(sprintf("  %-26s [%s] th1=%8.3f (d=%+6.3f) CN=%7.1f\n",
              cell_id, paste(sig, collapse = ","),
              res$row$theta1_kw, res$row$d_theta1, res$row$cond_number))
}

## ==========================================================
## STEP 4: Residual mean-shift scan + CUSUM (descriptive)
## ==========================================================

cat("\n--- Residual mean-shift scan (15% trimming) ---\n")

scan_rows <- list()
for (nm in names(resid_store)) {
  u <- resid_store[[nm]]$u; yrs <- resid_store[[nm]]$years
  Tn <- length(u)
  lo <- ceiling(0.15 * Tn); hi <- floor(0.85 * Tn)
  for (i in lo:hi) {
    d <- as.numeric(seq_len(Tn) > i)
    tt <- tryCatch(summary(lm(u ~ d))$coefficients["d", 3],
                   error = function(e) NA_real_)
    scan_rows[[paste(nm, yrs[i])]] <- data.frame(
      series = nm, break_after_year = yrs[i], shift_t = tt)
  }
  # CUSUM of residuals (standardized)
  cus <- cumsum(u - mean(u)) / (sd(u) * sqrt(Tn))
  for (i in seq_len(Tn)) {
    scan_rows[[paste(nm, yrs[i], "cusum")]] <- NULL  # cusum kept separately
  }
  resid_store[[nm]]$cusum <- cus
  best <- which.max(abs(sapply(lo:hi, function(i) {
    d <- as.numeric(seq_len(Tn) > i)
    tryCatch(summary(lm(u ~ d))$coefficients["d", 3], error = function(e) 0)
  })))
  cat(sprintf("  %-14s sup-|t| break after %d\n", nm, yrs[(lo:hi)[best]]))
}
scan_df <- bind_rows(scan_rows)
write.csv(scan_df, file.path(csv_dir, "s43_residual_scan.csv"), row.names = FALSE)

## ==========================================================
## STEP 5: Ledger, wide table, figures
## ==========================================================

ledger <- bind_rows(rows)
write.csv(ledger, file.path(csv_dir, "s43_candidate_ledger.csv"),
          row.names = FALSE)
if (length(skips)) write.csv(bind_rows(skips),
  file.path(csv_dir, "s43_skipped_cells.csv"), row.names = FALSE)

# Landscape wide table: params/deltas as rows, cells as columns
fmt <- function(v, d = 3) ifelse(is.na(v), "—", sprintf(paste0("%.", d, "f"), v))
wide <- data.frame(parameter = c(
  "theta1", "  t", "d_theta1 vs ref", "gamma_cand", "  t", "CN", "d_CN",
  "T", "eff. sample", "ADF verdict", "Shin verdict"))
for (cid in ledger$cell_id) {
  r <- ledger[ledger$cell_id == cid, ]
  wide[[cid]] <- c(fmt(r$theta1_kw), fmt(r$t_theta1_kw, 2),
    if ("d_theta1" %in% names(r)) fmt(r$d_theta1) else "—",
    fmt(r$gamma_cand), fmt(r$t_gamma_cand, 2),
    fmt(r$cond_number, 1),
    if ("d_cn" %in% names(r)) fmt(r$d_cn, 1) else "—",
    as.character(r$n_obs), sprintf("%d-%d", r$eff_start, r$eff_end),
    r$adf_verdict, r$shin_verdict)
}
write.csv(wide, file.path(csv_dir, "s43_delta_table_wide.csv"),
          row.names = FALSE)

# Figure 1: theta1 sensitivity per candidate vs reference
plt <- ledger %>% filter(candidate %in% candidates$code)
refline <- ledger %>% filter(candidate == "(none)") %>%
  select(window, tier, base, ref_theta1 = theta1_kw)
plt <- plt %>% left_join(refline, by = c("window", "tier", "base"))
g1 <- ggplot(plt, aes(x = candidate, y = theta1_kw, color = base)) +
  geom_hline(aes(yintercept = ref_theta1, linetype = base),
             color = "grey40", linewidth = 0.4) +
  geom_point(size = 2.2) +
  facet_wrap(~ paste(tier, window), scales = "free_y") +
  labs(title = "theta1 sensitivity to auxiliary dummies (S43)",
       subtitle = "Grey lines = reference ND/WD theta1 per window",
       x = NULL, y = "theta1", color = "Base set", linetype = "Base set") +
  theme_minimal(base_size = 10) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
ggsave(file.path(fig_dir, "s43_theta1_sensitivity.png"), g1,
       width = 12, height = 7, dpi = 150)
ggsave(file.path(fig_dir, "s43_theta1_sensitivity.pdf"), g1,
       width = 12, height = 7)

# Figure 2: residual scan t-path + CUSUM
scan_plot <- scan_df
event_years <- c(1937, 1950, 1957, 1971, 1979, 2000, 2020)
g2 <- ggplot(scan_plot, aes(x = break_after_year, y = shift_t)) +
  geom_line(color = "steelblue") +
  geom_hline(yintercept = c(-2, 2), linetype = "dashed", color = "red") +
  geom_vline(xintercept = event_years, linetype = "dotted", color = "grey50") +
  facet_wrap(~ series, scales = "free", ncol = 2) +
  labs(title = "Residual mean-shift scan (reference ND cells)",
       subtitle = "Dotted verticals = candidate events; dashed = |t| = 2 flag line",
       x = "Break after year", y = "Mean-shift t-statistic") +
  theme_minimal(base_size = 10)
ggsave(file.path(fig_dir, "s43_residual_scan.png"), g2,
       width = 11, height = 7, dpi = 150)
ggsave(file.path(fig_dir, "s43_residual_scan.pdf"), g2,
       width = 11, height = 7)

cusum_df <- bind_rows(lapply(names(resid_store), function(nm)
  data.frame(series = nm, year = resid_store[[nm]]$years,
             cusum = resid_store[[nm]]$cusum)))
g3 <- ggplot(cusum_df, aes(x = year, y = cusum)) +
  geom_line(color = "darkorange") +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_vline(xintercept = event_years, linetype = "dotted", color = "grey50") +
  facet_wrap(~ series, scales = "free", ncol = 2) +
  labs(title = "Standardized CUSUM of reference ND residuals",
       x = NULL, y = "CUSUM") +
  theme_minimal(base_size = 10)
ggsave(file.path(fig_dir, "s43_residual_cusum.png"), g3,
       width = 11, height = 7, dpi = 150)
ggsave(file.path(fig_dir, "s43_residual_cusum.pdf"), g3,
       width = 11, height = 7)

cat(sprintf("\nSaved: %d ledger rows, %d skipped cells, scan + 3 figures\n",
            nrow(ledger), length(skips)))
