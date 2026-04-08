# ===========================================================================
# 01_unit_root_tests.R
# Chilean TVECM — Integration Order Determination
# Battery: ADF (ur.df), PP (ur.pp), KPSS (ur.kpss), Zivot-Andrews (ur.za)
# Sample: 1940-1978 (N=39)
# ===========================================================================

library(urca)

# ---------------------------------------------------------------------------
# 0. Load data
# ---------------------------------------------------------------------------
root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
df <- read.csv(file.path(root, "data/final/chile_tvecm_panel.csv"))
df$in_sample <- as.logical(df$in_sample)
df <- df[df$in_sample == TRUE, ]

cat("Sample:", min(df$year), "-", max(df$year), " N =", nrow(df), "\n\n")

# ---------------------------------------------------------------------------
# 1. Test functions (plain loops, no purrr — avoids S4 dispatch issues)
# ---------------------------------------------------------------------------

run_adf <- function(x, varname, max_lags = 4) {
  xc <- as.numeric(na.omit(x))
  results <- data.frame()
  for (tp in c("none", "drift", "trend")) {
    # Manual AIC lag selection
    best_aic <- Inf; best_test <- NULL; best_lag <- 0
    for (p in 0:min(max_lags, floor(length(xc)/4) - 2)) {
      tt <- tryCatch(ur.df(xc, type = tp, lags = p), error = function(e) NULL)
      if (is.null(tt) || !is(tt, "ur.df")) next
      res <- tt@testreg$residuals
      k <- length(coef(tt@testreg))
      n_obs <- length(res)
      aic_val <- n_obs * log(sum(res^2) / n_obs) + 2 * k
      if (aic_val < best_aic) { best_aic <- aic_val; best_test <- tt; best_lag <- p }
    }
    if (is.null(best_test)) next
    row <- data.frame(
      variable = varname, test = "ADF", spec = tp,
      stat     = best_test@teststat[1],
      cv_1pct  = best_test@cval[1, 1],
      cv_5pct  = best_test@cval[1, 2],
      cv_10pct = best_test@cval[1, 3],
      lags     = best_lag,
      reject_5 = best_test@teststat[1] < best_test@cval[1, 2],
      break_year = NA_integer_,
      stringsAsFactors = FALSE
    )
    results <- rbind(results, row)
  }
  results
}

run_pp <- function(x, varname) {
  xc <- as.numeric(na.omit(x))
  results <- data.frame()
  for (mod in c("constant", "trend")) {
    tt <- tryCatch(ur.pp(xc, type = "Z-tau", model = mod, lags = "short"),
                   error = function(e) NULL)
    if (is.null(tt) || !is(tt, "ur.pp")) next
    row <- data.frame(
      variable = varname, test = "PP", spec = mod,
      stat     = as.numeric(tt@teststat),
      cv_1pct  = tt@cval[1, 1],
      cv_5pct  = tt@cval[1, 2],
      cv_10pct = tt@cval[1, 3],
      lags     = NA_integer_,
      reject_5 = as.numeric(tt@teststat) < tt@cval[1, 2],
      break_year = NA_integer_,
      stringsAsFactors = FALSE
    )
    results <- rbind(results, row)
  }
  results
}

run_kpss <- function(x, varname) {
  xc <- as.numeric(na.omit(x))
  results <- data.frame()
  for (tp in c("mu", "tau")) {
    tt <- tryCatch(ur.kpss(xc, type = tp, lags = "short"),
                   error = function(e) NULL)
    if (is.null(tt) || !is(tt, "ur.kpss")) next
    row <- data.frame(
      variable = varname, test = "KPSS", spec = tp,
      stat     = as.numeric(tt@teststat),
      cv_1pct  = tt@cval[1, 4],
      cv_5pct  = tt@cval[1, 3],
      cv_10pct = tt@cval[1, 1],
      lags     = NA_integer_,
      reject_5 = as.numeric(tt@teststat) > tt@cval[1, 3],  # KPSS: reject stationarity
      break_year = NA_integer_,
      stringsAsFactors = FALSE
    )
    results <- rbind(results, row)
  }
  results
}

run_za <- function(x, varname, year_vec) {
  xc <- as.numeric(na.omit(x))
  valid_years <- year_vec[!is.na(x)]
  results <- data.frame()
  for (mod in c("intercept", "trend", "both")) {
    tt <- tryCatch(ur.za(xc, model = mod, lag = 3), error = function(e) NULL)
    if (is.null(tt) || !is(tt, "ur.za")) next
    bk_idx <- tt@bpoint
    bk_year <- if (bk_idx <= length(valid_years)) valid_years[bk_idx] else NA_integer_
    cv <- as.numeric(tt@cval)  # ZA cval is a plain vector: 1%, 5%, 10%
    row <- data.frame(
      variable   = varname, test = "ZA", spec = mod,
      stat       = as.numeric(tt@teststat),
      cv_1pct    = cv[1],
      cv_5pct    = cv[2],
      cv_10pct   = cv[3],
      lags       = NA_integer_,
      reject_5   = as.numeric(tt@teststat) < cv[2],
      break_year = as.integer(bk_year),
      stringsAsFactors = FALSE
    )
    results <- rbind(results, row)
  }
  results
}

# ---------------------------------------------------------------------------
# 2. Run full battery
# ---------------------------------------------------------------------------
tier1_vars <- c("m", "k_ME", "nrs", "omega", "y", "k_NR", "omega_kME")
tier2_vars <- c("phi", "tot", "pcu", "rer")
all_vars   <- c(tier1_vars, tier2_vars)

results_all <- data.frame()

for (v in all_vars) {
  x  <- as.numeric(df[[v]])
  yr <- as.integer(df$year)
  cat(sprintf("Testing: %-12s (N=%d) ...\n", v, sum(!is.na(x))))

  # Levels
  lev <- rbind(run_adf(x, v), run_pp(x, v), run_kpss(x, v), run_za(x, v, yr))
  lev$transform <- "level"
  results_all <- rbind(results_all, lev)

  # First differences (all series)
  dx  <- diff(x[!is.na(x)])
  dyr <- yr[!is.na(x)][-1]
  dv  <- paste0("d_", v)

  dif <- rbind(run_adf(dx, dv), run_pp(dx, dv), run_kpss(dx, dv), run_za(dx, dv, dyr))
  dif$transform <- "first_diff"
  results_all <- rbind(results_all, dif)
}

# ---------------------------------------------------------------------------
# 3. Near-I(2) protocol: second differences
# ---------------------------------------------------------------------------
cat("\n=== NEAR-I(2) PROTOCOL ===\n")
i2_check <- data.frame()
for (v in c("k_NR", "k_ME", "phi", "omega_kME")) {
  x <- as.numeric(df[[v]])
  dx <- diff(x[!is.na(x)])
  d2x <- diff(dx)
  d2v <- paste0("d2_", v)
  d2 <- rbind(run_adf(d2x, d2v), run_pp(d2x, d2v), run_kpss(d2x, d2v))
  d2$transform <- "second_diff"
  i2_check <- rbind(i2_check, d2)
}
results_all <- rbind(results_all, i2_check)

# k_NR - k_ME spread
cat("Testing spread: k_NR - k_ME ...\n")
spread   <- as.numeric(df$k_NR) - as.numeric(df$k_ME)
spread_d <- diff(spread)
sp_lev <- rbind(run_adf(spread, "k_NR_minus_k_ME"), run_pp(spread, "k_NR_minus_k_ME"),
                run_kpss(spread, "k_NR_minus_k_ME"))
sp_lev$transform <- "level"
sp_dif <- rbind(run_adf(spread_d, "d_spread"), run_pp(spread_d, "d_spread"),
                run_kpss(spread_d, "d_spread"))
sp_dif$transform <- "first_diff"
results_all <- rbind(results_all, sp_lev, sp_dif)

# ---------------------------------------------------------------------------
# 4. Build crosswalk summary
# ---------------------------------------------------------------------------
cat("\n")
cat(strrep("=", 120), "\n")
cat("SECTION A: UNIT ROOT CROSSWALK TABLE\n")
cat("Sample: 1940-1978 (N=39)\n")
cat("* = reject H0 at 5%  |  dag = KPSS rejects stationarity at 5%\n")
cat(strrep("=", 120), "\n\n")

# Helper: extract key stat for a series/transform combo
get_stat <- function(res, vname, trans, test_name, spec_name) {
  sub <- res[res$variable == vname & res$transform == trans &
             res$test == test_name & res$spec == spec_name, ]
  if (nrow(sub) == 0) return(list(stat = NA, reject = NA, bk = NA))
  list(stat = sub$stat[1], reject = sub$reject_5[1], bk = sub$break_year[1])
}

# Print crosswalk
cat(sprintf("%-12s %-6s %12s %12s %12s %12s %12s %8s %6s\n",
            "Series", "Trans", "ADF-drift", "ADF-trend", "PP-const", "KPSS-mu", "ZA-both", "Break", "Lags"))
cat(strrep("-", 100), "\n")

for (v in all_vars) {
  for (tr in c("level", "first_diff")) {
    vname <- if (tr == "level") v else paste0("d_", v)
    tr_label <- if (tr == "level") "level" else "delta"

    adf_dr  <- get_stat(results_all, vname, tr, "ADF", "drift")
    adf_tr  <- get_stat(results_all, vname, tr, "ADF", "trend")
    pp_c    <- get_stat(results_all, vname, tr, "PP", "constant")
    kpss_m  <- get_stat(results_all, vname, tr, "KPSS", "mu")
    za_b    <- get_stat(results_all, vname, tr, "ZA", "both")

    # ADF lags
    adf_sub <- results_all[results_all$variable == vname & results_all$transform == tr &
                           results_all$test == "ADF" & results_all$spec == "drift", ]
    lag_str <- if (nrow(adf_sub) > 0) as.character(adf_sub$lags[1]) else "-"

    fmt <- function(s, rej, kpss = FALSE) {
      if (is.na(s)) return(sprintf("%12s", "-"))
      mark <- if (!is.na(rej) && rej) { if (kpss) "\u2020" else "*" } else ""
      sprintf("%11.3f%s", s, mark)
    }

    bk_str <- if (!is.na(za_b$bk)) sprintf("%8d", za_b$bk) else sprintf("%8s", "-")

    cat(sprintf("%-12s %-6s %s %s %s %s %s %s %6s\n",
                v, tr_label,
                fmt(adf_dr$stat, adf_dr$reject),
                fmt(adf_tr$stat, adf_tr$reject),
                fmt(pp_c$stat, pp_c$reject),
                fmt(kpss_m$stat, kpss_m$reject, kpss = TRUE),
                fmt(za_b$stat, za_b$reject),
                bk_str, lag_str))
  }
}

# Near-I(2) second differences
cat("\n--- Second differences (near-I(2) check) ---\n")
for (v in c("k_NR", "k_ME", "phi", "omega_kME")) {
  d2v <- paste0("d2_", v)
  adf_d2 <- results_all[results_all$variable == d2v & results_all$test == "ADF" &
                         results_all$spec == "drift", ]
  if (nrow(adf_d2) > 0) {
    cat(sprintf("  d2_%-10s ADF-drift: %7.3f (cv5=%7.3f) %s\n",
                v, adf_d2$stat, adf_d2$cv_5pct,
                ifelse(adf_d2$reject_5, "REJECT -> I(2) confirmed", "fail to reject -> I(3)??")))
  }
}

cat("\n--- k_NR - k_ME spread ---\n")
sp_adf <- results_all[results_all$variable == "k_NR_minus_k_ME" & results_all$test == "ADF" &
                       results_all$spec == "drift", ]
sp_d_adf <- results_all[results_all$variable == "d_spread" & results_all$test == "ADF" &
                         results_all$spec == "drift", ]
if (nrow(sp_adf) > 0)
  cat(sprintf("  Level:  ADF = %.3f (cv5=%.3f) %s\n", sp_adf$stat, sp_adf$cv_5pct,
              ifelse(sp_adf$reject_5, "REJECT -> spread I(0), stocks CI", "no rejection")))
if (nrow(sp_d_adf) > 0)
  cat(sprintf("  Delta:  ADF = %.3f (cv5=%.3f) %s\n", sp_d_adf$stat, sp_d_adf$cv_5pct,
              ifelse(sp_d_adf$reject_5, "REJECT -> spread I(1)", "no rejection")))

# ---------------------------------------------------------------------------
# 5. Integration order determination
# ---------------------------------------------------------------------------
cat("\n")
cat(strrep("=", 100), "\n")
cat("SECTION A.1: INTEGRATION ORDER SUMMARY\n")
cat(strrep("=", 100), "\n\n")

cat(sprintf("%-12s %-8s %-25s %8s\n", "Variable", "I(d)", "Flag", "ZA break"))
cat(strrep("-", 60), "\n")

for (v in all_vars) {
  # Levels tests
  adf_l  <- get_stat(results_all, v, "level", "ADF", "drift")
  pp_l   <- get_stat(results_all, v, "level", "PP", "constant")
  kpss_l <- get_stat(results_all, v, "level", "KPSS", "mu")
  za_l   <- get_stat(results_all, v, "level", "ZA", "both")

  # First diff tests
  dv <- paste0("d_", v)
  adf_d  <- get_stat(results_all, dv, "first_diff", "ADF", "drift")
  pp_d   <- get_stat(results_all, dv, "first_diff", "PP", "constant")
  kpss_d <- get_stat(results_all, dv, "first_diff", "KPSS", "mu")

  level_rej  <- sum(c(!is.na(adf_l$reject) & adf_l$reject,
                      !is.na(pp_l$reject) & pp_l$reject,
                      !is.na(za_l$reject) & za_l$reject), na.rm = TRUE)
  kpss_l_rej <- !is.na(kpss_l$reject) & kpss_l$reject
  diff_rej   <- sum(c(!is.na(adf_d$reject) & adf_d$reject,
                      !is.na(pp_d$reject) & pp_d$reject), na.rm = TRUE)
  kpss_d_rej <- !is.na(kpss_d$reject) & kpss_d$reject

  if (level_rej >= 2 && !kpss_l_rej) {
    order <- "I(0)"; flag <- "stationary"
  } else if (level_rej == 0 && kpss_l_rej && diff_rej >= 1 && !kpss_d_rej) {
    order <- "I(1)"; flag <- "confirmed (ADF+KPSS)"
  } else if (level_rej == 0 && diff_rej >= 1) {
    order <- "I(1)"; flag <- "likely"
  } else if (level_rej == 0 && diff_rej == 0) {
    order <- "I(2)?"; flag <- "near-I(2)"
  } else if (level_rej >= 1 && kpss_l_rej) {
    order <- "I(1)"; flag <- "break-induced ADF rejection"
  } else if (level_rej == 1 && !kpss_l_rej && diff_rej >= 1) {
    order <- "I(1)"; flag <- "borderline (1 test rejects in levels)"
  } else {
    order <- "ambig"; flag <- "check manually"
  }

  bk_str <- if (!is.na(za_l$bk)) as.character(za_l$bk) else "-"
  cat(sprintf("%-12s %-8s %-25s %8s\n", v, order, flag, bk_str))
}

# ---------------------------------------------------------------------------
# 6. Estimation readiness verdict (Section C)
# ---------------------------------------------------------------------------
cat("\n")
cat(strrep("=", 100), "\n")
cat("SECTION C: ESTIMATION READINESS VERDICT\n")
cat(strrep("=", 100), "\n\n")

cat(sprintf("%-15s %-30s %-12s %s\n", "System", "Series", "Verdict", "Condition"))
cat(strrep("-", 100), "\n")

# (Manually assess from the printed results above — the logic is embedded
#  in the order determination. Here we print a structured template.)

s1 <- c("m", "k_ME", "nrs", "omega")
s2 <- c("y", "k_NR", "k_ME", "omega_kME")
exog <- c("tot", "pcu", "rer")
post <- c("phi")

for (sys in list(
  list(n = "Stage 1 VECM",  v = s1),
  list(n = "Stage 2 TVECM", v = s2),
  list(n = "Exogenous",     v = exog),
  list(n = "Post-estimation", v = post)
)) {
  # Collect orders for this system
  issues <- c()
  for (vv in sys$v) {
    adf_l <- get_stat(results_all, vv, "level", "ADF", "drift")
    dv <- paste0("d_", vv)
    adf_d <- get_stat(results_all, dv, "first_diff", "ADF", "drift")
    pp_d  <- get_stat(results_all, dv, "first_diff", "PP", "constant")

    level_rej <- !is.na(adf_l$reject) & adf_l$reject
    diff_rej  <- sum(c(!is.na(adf_d$reject) & adf_d$reject,
                       !is.na(pp_d$reject) & pp_d$reject), na.rm = TRUE)

    if (level_rej) issues <- c(issues, paste0(vv, " (rejects in levels)"))
    if (diff_rej == 0) issues <- c(issues, paste0(vv, " (near-I(2))"))
  }

  verdict <- if (length(issues) == 0) "READY" else "CAUTION"
  cond <- if (length(issues) == 0) "All series I(1)" else paste(issues, collapse = "; ")
  cat(sprintf("%-15s %-30s %-12s %s\n", sys$n, paste(sys$v, collapse = ", "), verdict, cond))
}

# ---------------------------------------------------------------------------
# 7. Write crosswalk to markdown
# ---------------------------------------------------------------------------
out_dir <- file.path(root, "output/diagnostics")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

md <- c(
  "# Unit Root Crosswalk — Chile TVECM",
  sprintf("Generated: %s | Sample: 1940-1978 (N=39)", Sys.Date()),
  "",
  "## Section A: Crosswalk table",
  "",
  "`*` = reject H0 (unit root) at 5% | `†` = KPSS rejects stationarity at 5%",
  "",
  "| Series | Trans | ADF-drift | ADF-trend | PP-const | KPSS-mu | ZA-both | Break | Lags |",
  "|--------|-------|-----------|-----------|----------|---------|---------|-------|------|"
)

for (v in all_vars) {
  for (tr in c("level", "first_diff")) {
    vname <- if (tr == "level") v else paste0("d_", v)
    tr_label <- if (tr == "level") "level" else "\u0394"

    fmt_md <- function(res, vn, tr2, tn, sn, kpss = FALSE) {
      s <- get_stat(res, vn, tr2, tn, sn)
      if (is.na(s$stat)) return("-")
      mark <- if (!is.na(s$reject) && s$reject) { if (kpss) "\u2020" else "\\*" } else ""
      sprintf("%.3f%s", s$stat, mark)
    }

    adf_sub <- results_all[results_all$variable == vname & results_all$transform == tr &
                           results_all$test == "ADF" & results_all$spec == "drift", ]
    lag_s <- if (nrow(adf_sub) > 0) as.character(adf_sub$lags[1]) else "-"

    za_b <- get_stat(results_all, vname, tr, "ZA", "both")
    bk_s <- if (!is.na(za_b$bk)) as.character(za_b$bk) else "-"

    md <- c(md, sprintf("| %s | %s | %s | %s | %s | %s | %s | %s | %s |",
      v, tr_label,
      fmt_md(results_all, vname, tr, "ADF", "drift"),
      fmt_md(results_all, vname, tr, "ADF", "trend"),
      fmt_md(results_all, vname, tr, "PP", "constant"),
      fmt_md(results_all, vname, tr, "KPSS", "mu", kpss = TRUE),
      fmt_md(results_all, vname, tr, "ZA", "both"),
      bk_s, lag_s))
  }
}

# Integration order summary
md <- c(md, "", "## Integration order summary", "",
  "| Variable | I(d) | Flag | ZA break |",
  "|----------|------|------|----------|")

for (v in all_vars) {
  adf_l <- get_stat(results_all, v, "level", "ADF", "drift")
  pp_l  <- get_stat(results_all, v, "level", "PP", "constant")
  kpss_l <- get_stat(results_all, v, "level", "KPSS", "mu")
  za_l  <- get_stat(results_all, v, "level", "ZA", "both")
  dv <- paste0("d_", v)
  adf_d <- get_stat(results_all, dv, "first_diff", "ADF", "drift")
  pp_d  <- get_stat(results_all, dv, "first_diff", "PP", "constant")
  kpss_d <- get_stat(results_all, dv, "first_diff", "KPSS", "mu")

  lr <- sum(c(!is.na(adf_l$reject) & adf_l$reject,
              !is.na(pp_l$reject) & pp_l$reject,
              !is.na(za_l$reject) & za_l$reject), na.rm = TRUE)
  kl <- !is.na(kpss_l$reject) & kpss_l$reject
  dr <- sum(c(!is.na(adf_d$reject) & adf_d$reject,
              !is.na(pp_d$reject) & pp_d$reject), na.rm = TRUE)
  kd <- !is.na(kpss_d$reject) & kpss_d$reject

  if (lr >= 2 && !kl) { ord <- "I(0)"; fl <- "stationary" }
  else if (lr == 0 && kl && dr >= 1 && !kd) { ord <- "I(1)"; fl <- "confirmed" }
  else if (lr == 0 && dr >= 1) { ord <- "I(1)"; fl <- "likely" }
  else if (lr == 0 && dr == 0) { ord <- "I(2)?"; fl <- "near-I(2)" }
  else if (lr >= 1 && kl) { ord <- "I(1)"; fl <- "break-induced rejection" }
  else if (lr == 1 && !kl && dr >= 1) { ord <- "I(1)"; fl <- "borderline" }
  else { ord <- "ambig"; fl <- "check" }

  bk <- if (!is.na(za_l$bk)) as.character(za_l$bk) else "-"
  md <- c(md, sprintf("| %s | %s | %s | %s |", v, ord, fl, bk))
}

# Write
writeLines(md, file.path(out_dir, "unit_root_crosswalk.md"))
cat(sprintf("\nCrosswalk written to: %s\n", file.path(out_dir, "unit_root_crosswalk.md")))

# ---------------------------------------------------------------------------
# 8. Session info
# ---------------------------------------------------------------------------
cat("\n")
sessionInfo()
