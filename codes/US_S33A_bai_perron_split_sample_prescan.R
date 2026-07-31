#!/usr/bin/env Rscript

# US_S33A_bai_perron_split_sample_prescan.R
# ---------------------------------------------------------------------------
# Step 1 of the binding S0* break-aware pre-testing sequence:
#
#     Bai-Perron (1998, 2003) sequential break search on STATIONARY FIRST
#     DIFFERENCES, run within the Fordist and Post-Fordist sub-samples
#     separately (and on the full sample for Specification B).
#
# Authority:
#   S03 Sec.2A -- BP theory requires stationary I(0) regressors. "BP theory breaks
#                 down if applied directly to non-stationary I(1) levels without
#                 appropriate cointegration structure." Hence differences only.
#   S03 Sec.2C -- Stage 1A: "Run BP sequential Sup F_T(l+1|l) on Delta k^ME_t".
#   S01 Sec.2 Step 1 -- BP on the differenced vector Delta Y_t = [Dy, Dk^cap, Domega]';
#                 Fordist window 1929-1973 with eps = 0.20, candidates 1933 / 1947;
#                 Post-Fordist window 1974-2024 with eps = 0.15, candidates 1982 /
#                 2000 / 2008.
#   S02 Stage 2A -- BP on the five-variable differenced vector
#                 [Dy, Dk^NRC, Dkappa, Domega, Dp^kappa]'; full sample 1929-2024 with
#                 global candidates 1933 / 1947 / 1968 / 1982 / 2008.
#
# Two routes are run because S01 and S03 read the same step differently, and the
# difference is material:
#
#   route = "univariate_mean"  -- S03 Sec.2C's literal instruction. Each differenced
#       series regressed on a constant only, so BP locates shifts in the GROWTH-RATE
#       MEAN of that single series.
#   route = "system_equation"  -- S01 Sec.2 Step 1's differenced VECTOR. The differenced
#       regressand on the remaining differences, lag-augmented, so BP locates shifts in
#       the short-run relation among them.
#
# Neither route is privileged here. Both are written to the ledgers and the
# concordance file scores both against the protocol dates. Adjudication happens in
# the report, not silently in this script.
#
# Break-date policy: this script reports what Bai-Perron ESTIMATES. Where the
# estimate disagrees with the protocol's candidate dates, the concordance ledger
# records the disagreement. Protocol dates are never substituted for estimated ones.
#
# Precedent followed for the BP idiom, the UDmax-first sequential rule, and the
# BIC + Breusch-Godfrey lag escalation:
#   codes/CL_S25_stationary_accumulation_breaks.R
#
# Governance: all artifacts land under output/US/BREAK_AWARE_IMOLS/S33A_BAI_PERRON/.
# Nothing is written to reports/ and nothing under output/CL/ is touched.
#
# Usage:
#   Rscript codes/US_S33A_bai_perron_split_sample_prescan.R
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

suppressPackageStartupMessages({
  library(mbreaks)
  library(lmtest)
})

STAGE    <- "S33A_BAI_PERRON"
OUT_DIR  <- s33_dir(STAGE)
CSV_DIR  <- file.path(OUT_DIR, "csv")
LOG_DIR  <- file.path(OUT_DIR, "logs")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33A_execution_log.txt")
log_msg <- function(...) {
  line <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(line, "\n", sep = "")
  cat(line, "\n", sep = "", file = LOG_PATH, append = TRUE)
}
cat("", file = LOG_PATH)
log_msg("US_S33A start. mbreaks ", as.character(utils::packageVersion("mbreaks")),
        "; ", R.version.string)

# mbreaks 1.0.1 is the version pinned by codes/CL_S15_evidence_reconciliation.R. A
# different version may change the critical-value tables, so it is recorded rather
# than assumed.
MBREAKS_VERSION <- as.character(utils::packageVersion("mbreaks"))

# ---------------------------------------------------------------------------
# 1. Build the differenced vectors
# ---------------------------------------------------------------------------
# Differencing happens on the FULL panel before windowing, so the first observation
# inside each window keeps a real difference instead of being dropped.

diff_frame <- function(df, cols) {
  out <- data.frame(year = df$year[-1L])
  for (nm in cols) out[[paste0("d_", nm)]] <- diff(df[[nm]])
  out
}

panel_a <- s33_load_spec_a()
panel_b <- s33_load_spec_b()
log_msg("Spec A panel: ", nrow(panel_a), " rows, ", min(panel_a$year), "-", max(panel_a$year))
log_msg("Spec B panel: ", nrow(panel_b), " rows, ", min(panel_b$year), "-", max(panel_b$year))

# S01 Sec.2 Step 1: Delta Y_t = [Dy^NFC, Dk^cap, Domega]'
DIFFS_A <- c("y", "k_cap", "omega")
# S02 Stage 2A: Delta Y_t = [Dy^NFC, Dk^NRC, Dkappa, Domega, Dp^kappa]'
DIFFS_B <- c("y", "k_NRC", "kappa", "omega", "p_kappa")

# break_vars (z) are the coefficients ALLOWED to shift across regimes; control_vars (x)
# are held constant. This is Bai-Perron's partial-structural-change model, and the split
# is not cosmetic: allowing every differenced regressor to break gives (k+1) parameters
# per regime, which on a 42-51 observation window with h ~ 8-9 produces a singular
# segment design. The split follows the protocols' own targets -- S01 Sec.1A breaks the
# capital elasticity beta_Kcap, S02 Sec.3 breaks the kappa terms -- so the capital
# differences carry the regime shift and the distribution/price controls do not.
SPECS <- list(
  Spec_A = list(spec = "Spec_A", panel = panel_a, vars = DIFFS_A,
                regressand = "d_y",
                break_vars = c("d_k_cap"),
                control_vars = c("d_omega"),
                windows = c("Fordist_1929_1973", "Post_Fordist_1974_2024"),
                source = "S01 Sec.2 Step 1"),
  Spec_B = list(spec = "Spec_B", panel = panel_b, vars = DIFFS_B,
                regressand = "d_y",
                break_vars = c("d_k_NRC", "d_kappa"),
                control_vars = c("d_omega", "d_p_kappa"),
                windows = c("Full_Sample_1929_2024", "Fordist_1929_1973",
                            "Post_Fordist_1974_2024"),
                source = "S02 Stage 2A")
)

# S02 Stage 2A names five global break points, so the full sample must be allowed to
# find five. The sub-samples name at most three candidates each.
max_breaks_for <- function(window_key) if (window_key == "Full_Sample_1929_2024") 5L else 3L

# ---------------------------------------------------------------------------
# 2. Extraction helpers for the mbreaks return object
# ---------------------------------------------------------------------------
# Structure of mbreaks::mdl() output (verified against mbreaks 1.0.1):
#   $sbtests$ftest    supF(k) statistics, k = 1..m            (m x 1 matrix)
#   $sbtests$cv_supF  supF critical values                    (4 x m; rows 10/5/2.5/1)
#   $sbtests$UDmax    data.frame: UDMax, 10% CV, 5% CV, 2.5% CV, 1% CV
#   $seqtests$supfl   supF(l+1|l) statistics, l = 0..m-1      (m x 1 matrix)
#   $seqtests$cv      sequential critical values              (4 x m; rows 10/5/2.5/1)
#   $SEQ              sequentially-selected model: $nbreak, $date, $CI, $resid
#
# WDmax is NOT exposed by mbreaks 1.0.1. S03 Sec.2A lists it as part of the double
# maximum family. It is recorded as unavailable rather than approximated -- an absent
# statistic is reported absent.

num_or_na <- function(x, i = 1L) {
  v <- suppressWarnings(as.numeric(x))
  if (length(v) < i || !is.finite(v[i])) NA_real_ else v[i]
}

cv_row5 <- function(cvmat, j) {
  if (is.null(cvmat)) return(NA_real_)
  cvm <- as.matrix(cvmat)
  rn <- rownames(cvm)
  i <- if (!is.null(rn) && "5" %in% rn) which(rn == "5")[1] else 2L
  if (i > nrow(cvm) || j > ncol(cvm)) return(NA_real_)
  num_or_na(cvm[i, j])
}

# ---------------------------------------------------------------------------
# 3. Lag selection (BIC, escalated on residual serial correlation)
# ---------------------------------------------------------------------------
# CL_S25 lines 30-53 and 119-124: pick p by BIC on the common sample, then raise p
# until Breusch-Godfrey(4) stops rejecting, capped at 4.

lag_vector <- function(x, k) if (k == 0L) x else c(rep(NA_real_, k), utils::head(x, -k))

augment_lags <- function(d, cols, max_lag = 4L) {
  for (nm in cols) for (k in seq_len(max_lag)) {
    d[[sprintf("L%d_%s", k, nm)]] <- lag_vector(d[[nm]], k)
  }
  d
}

select_lag_order <- function(d, regressand, regressors, max_lag = 4L) {
  common <- d[stats::complete.cases(d), , drop = FALSE]
  rows <- list()
  for (p in 0:max_lag) {
    rhs <- c(regressors, if (p > 0L) as.vector(outer(seq_len(p), c(regressand, regressors),
                                                     function(k, nm) sprintf("L%d_%s", k, nm))))
    fit <- try(stats::lm(stats::reformulate(rhs, regressand), data = common), silent = TRUE)
    if (inherits(fit, "try-error")) next
    bg <- try(lmtest::bgtest(fit, order = 4)$p.value, silent = TRUE)
    rows[[length(rows) + 1L]] <- data.frame(
      lag = p, n_common = stats::nobs(fit), BIC = stats::BIC(fit),
      residual_serial_p_BG4 = if (inherits(bg, "try-error")) NA_real_ else as.numeric(bg),
      stringsAsFactors = FALSE)
  }
  if (!length(rows)) return(list(p = 0L, ledger = NULL))
  ledger <- do.call(rbind, rows)
  p <- ledger$lag[which.min(ledger$BIC)]
  # Escalate while BG(4) still rejects at 5%.
  repeat {
    pr <- ledger$residual_serial_p_BG4[ledger$lag == p]
    if (!length(pr) || is.na(pr) || pr >= 0.05 || p >= max_lag) break
    p <- p + 1L
  }
  list(p = p, ledger = ledger)
}

# ---------------------------------------------------------------------------
# 4. UDmax-first sequential selection rule (CL_S25 lines 78-89)
# ---------------------------------------------------------------------------
# Accept l+1 breaks only if (i) UDmax rejects at 5% and (ii) every sequential
# supF(l+1|l) up to that point rejects at 5%. This is stricter than reading
# $SEQ$nbreak straight off mbreaks and is the rule already in force on the Chile side.

apply_udmax_first <- function(fit, m) {
  udmax     <- num_or_na(fit$sbtests$UDmax[1, 1])
  udmax_cv5 <- num_or_na(fit$sbtests$UDmax[1, 3])
  seq_stats <- suppressWarnings(as.numeric(fit$seqtests$supfl[, 1]))
  seq_cv5   <- vapply(seq_len(length(seq_stats)), function(j) cv_row5(fit$seqtests$cv, j), numeric(1))

  selected <- 0L
  if (is.finite(udmax) && is.finite(udmax_cv5) && udmax > udmax_cv5) {
    for (l in seq_along(seq_stats)) {
      if (l > m) break
      if (is.finite(seq_stats[l]) && is.finite(seq_cv5[l]) && seq_stats[l] > seq_cv5[l]) {
        selected <- l
      } else break
    }
  }
  list(selected = selected, udmax = udmax, udmax_cv5 = udmax_cv5,
       seq_stats = seq_stats, seq_cv5 = seq_cv5)
}

# ---------------------------------------------------------------------------
# 5. One Bai-Perron run
# ---------------------------------------------------------------------------

run_bp <- function(d, regressand, z_names, x_names, eps1, m, years) {
  fit <- try(mbreaks::mdl(regressand, z_name = z_names, x_name = x_names, data = d,
                          eps1 = eps1, m = m,
                          prewhit = 1, robust = 1,
                          hetdat = 1, hetvar = 1, hetomega = 0, hetq = 1,
                          signif = 2, printd = 0), silent = TRUE)
  if (inherits(fit, "try-error")) {
    return(list(ok = FALSE, error = trimws(as.character(fit))))
  }

  rule <- apply_udmax_first(fit, m)

  model <- NULL
  if (rule$selected > 0L) {
    model <- if (!is.null(fit$SEQ) && identical(as.integer(fit$SEQ$nbreak), rule$selected)) {
      fit$SEQ
    } else {
      mm <- try(mbreaks::dofix(regressand, z_name = z_names, x_name = x_names, data = d,
                               fixn = rule$selected, eps1 = eps1,
                               prewhit = 1, robust = 1,
                               hetdat = 1, hetvar = 1, hetomega = 0, hetq = 1,
                               printd = 0), silent = TRUE)
      if (inherits(mm, "try-error")) NULL else mm
    }
  }

  idx <- if (!is.null(model) && !is.null(model$date)) as.integer(model$date[, 1]) else integer()
  yrs <- if (length(idx)) years[idx] else integer()

  ci <- NULL
  if (length(idx) && !is.null(model$CI)) {
    cim <- as.matrix(model$CI)
    safe_year <- function(v) {
      v <- suppressWarnings(as.integer(v))
      v[v < 1L] <- 1L; v[v > length(years)] <- length(years)
      years[v]
    }
    ci <- data.frame(
      break_number = seq_along(idx),
      break_year   = yrs,
      ci95_low     = safe_year(cim[, 1]),
      ci95_high    = safe_year(cim[, 2]),
      stringsAsFactors = FALSE)
  }

  list(ok = TRUE, error = NA_character_, fit = fit, model = model, rule = rule,
       break_years = yrs, ci = ci, n_obs = nrow(d))
}

# ---------------------------------------------------------------------------
# 6. Drive both routes across every spec x window
# ---------------------------------------------------------------------------

test_rows  <- list()
date_rows  <- list()
lag_rows   <- list()

add_test_rows <- function(res, meta) {
  r <- res$rule
  m <- length(r$seq_stats)
  base <- data.frame(
    spec = meta$spec, route = meta$route, window = meta$window,
    series = meta$series, regressand = meta$regressand,
    epsilon = meta$epsilon, m_max = meta$m, lag_order = meta$lag_order,
    n_obs = res$n_obs, stringsAsFactors = FALSE)

  ftest <- suppressWarnings(as.numeric(res$fit$sbtests$ftest[, 1]))
  rows <- list()
  for (k in seq_along(ftest)) {
    rows[[length(rows) + 1L]] <- cbind(base, data.frame(
      test = sprintf("supF(%d)", k),
      statistic = ftest[k],
      critical_5pct = cv_row5(res$fit$sbtests$cv_supF, k),
      stringsAsFactors = FALSE))
  }
  rows[[length(rows) + 1L]] <- cbind(base, data.frame(
    test = "UDmax", statistic = r$udmax, critical_5pct = r$udmax_cv5,
    stringsAsFactors = FALSE))
  # S03 Sec.2A also names WDmax. mbreaks 1.0.1 does not expose it; recorded as absent.
  rows[[length(rows) + 1L]] <- cbind(base, data.frame(
    test = "WDmax", statistic = NA_real_, critical_5pct = NA_real_,
    stringsAsFactors = FALSE))
  for (l in seq_len(m)) {
    rows[[length(rows) + 1L]] <- cbind(base, data.frame(
      test = sprintf("supF(%d|%d)", l, l - 1L),
      statistic = r$seq_stats[l], critical_5pct = r$seq_cv5[l],
      stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, rows)
  out$rejects_5pct <- ifelse(is.na(out$statistic) | is.na(out$critical_5pct), NA,
                             out$statistic > out$critical_5pct)
  out$note <- ifelse(out$test == "WDmax",
                     "not exposed by mbreaks 1.0.1; S03 Sec.2A lists it, no substitute computed",
                     NA_character_)
  out$selected_break_count <- r$selected
  out$selected_break_years <- if (length(res$break_years))
    paste(res$break_years, collapse = ";") else NA_character_
  out$selection_rule <- "UDmax at 5% must reject, then sequential supF(l+1|l) at 5%"
  out$mbreaks_version <- MBREAKS_VERSION
  out
}

for (sp in SPECS) {
  dv <- diff_frame(sp$panel, sp$vars)
  dcols <- setdiff(names(dv), "year")

  for (wkey in sp$windows) {
    win <- S33_WINDOWS[[wkey]]
    dw  <- dv[dv$year >= win$range[1] & dv$year <= win$range[2], , drop = FALSE]
    dw  <- dw[stats::complete.cases(dw), , drop = FALSE]
    m   <- max_breaks_for(wkey)
    log_msg(sp$spec, " / ", wkey, ": ", nrow(dw), " differenced obs, eps=", win$epsilon,
            ", m=", m)

    if (nrow(dw) < 20L) {
      log_msg("  SKIPPED: fewer than 20 usable observations")
      next
    }

    # -- Route 1: univariate growth-rate mean shifts (S03 Sec.2C literal reading) ----
    for (series in dcols) {
      d1 <- data.frame(year = dw$year, v = dw[[series]])
      names(d1)[2] <- series
      res <- run_bp(d1, series, z_names = NULL, x_names = NULL,
                    eps1 = win$epsilon, m = m, years = d1$year)
      if (!res$ok) { log_msg("  [univariate_mean] ", series, " FAILED: ", res$error); next }
      meta <- list(spec = sp$spec, route = "univariate_mean", window = wkey,
                   series = series, regressand = series, epsilon = win$epsilon,
                   m = m, lag_order = 0L)
      tr <- add_test_rows(res, meta)
      tr$break_specification <- "intercept_only_mean_shift"
      test_rows[[length(test_rows) + 1L]] <- tr
      if (!is.null(res$ci)) {
        date_rows[[length(date_rows) + 1L]] <- cbind(
          data.frame(spec = sp$spec, route = "univariate_mean", window = wkey,
                     series = series, stringsAsFactors = FALSE), res$ci)
      }
      log_msg("  [univariate_mean] ", series, ": ", res$rule$selected, " break(s) ",
              if (length(res$break_years)) paste(res$break_years, collapse = ";") else "none")
    }

    # -- Route 2: differenced-vector relation (S01 Sec.2 Step 1 reading) -------------
    regressors <- setdiff(dcols, sp$regressand)
    daug <- augment_lags(dw, dcols, max_lag = 4L)
    sel  <- select_lag_order(daug, sp$regressand, regressors, max_lag = 4L)
    p    <- sel$p
    if (!is.null(sel$ledger)) {
      lag_rows[[length(lag_rows) + 1L]] <- cbind(
        data.frame(spec = sp$spec, window = wkey, regressand = sp$regressand,
                   selected_lag = p, stringsAsFactors = FALSE), sel$ledger)
    }

    # Estimability ladder. mbreaks' partial-structural-change routine solves the
    # segment-wise normal equations iteratively, and on these 42-51 observation windows it
    # goes singular once the constant-coefficient block x carries lag augmentation: every
    # window with p > 0 fails while every window with p = 0 estimates. Rather than drop
    # those windows, walk down the lag order (BIC choice first, then p-1 ... 0) and, at
    # each level, try the protocol-targeted capital break before retreating to an
    # intercept-only break. Whatever combination first estimates is recorded in
    # break_specification and lag_order, so a weakened fit is never reported as if the
    # richer model had been fitted.
    build_attempts <- function(pp) {
      ln <- if (pp > 0L) as.vector(outer(seq_len(pp), dcols,
                                         function(k, nm) sprintf("L%d_%s", k, nm))) else NULL
      list(
        list(tag = sprintf("partial_break_capital_terms(p=%d)", pp), p = pp, lag_names = ln,
             z = sp$break_vars, x = c(sp$control_vars, ln)),
        list(tag = sprintf("intercept_only_break_fallback(p=%d)", pp), p = pp, lag_names = ln,
             z = NULL, x = c(regressors, ln))
      )
    }

    res <- NULL; used <- NULL
    for (pp in seq(p, 0L, by = -1L)) {
      for (att in build_attempts(pp)) {
        keep <- c("year", sp$regressand, regressors, att$lag_names)
        d2 <- daug[, keep, drop = FALSE]
        d2 <- d2[stats::complete.cases(d2), , drop = FALSE]
        cand <- run_bp(d2, sp$regressand, z_names = att$z, x_names = att$x,
                       eps1 = win$epsilon, m = m, years = d2$year)
        if (cand$ok) { res <- cand; used <- att; break }
        log_msg("  [system_equation] ", att$tag, " not estimable")
        res <- cand; used <- att
      }
      if (!is.null(res) && isTRUE(res$ok)) break
    }
    p <- used$p

    if (!res$ok) {
      # Record the failure in the ledger so the window is visibly attempted-and-failed
      # rather than silently absent.
      test_rows[[length(test_rows) + 1L]] <- data.frame(
        spec = sp$spec, route = "system_equation", window = wkey,
        series = paste(dcols, collapse = "+"), regressand = sp$regressand,
        epsilon = win$epsilon, m_max = m, lag_order = p, n_obs = nrow(d2),
        test = "ESTIMATION_FAILED", statistic = NA_real_, critical_5pct = NA_real_,
        rejects_5pct = NA, note = paste("all break specifications singular;", res$error),
        selected_break_count = NA_integer_, selected_break_years = NA_character_,
        selection_rule = "UDmax at 5% must reject, then sequential supF(l+1|l) at 5%",
        mbreaks_version = MBREAKS_VERSION, break_specification = used$tag,
        stringsAsFactors = FALSE)
      log_msg("  [system_equation] no specification estimable in ", wkey)
    } else {
      meta <- list(spec = sp$spec, route = "system_equation", window = wkey,
                   series = paste(dcols, collapse = "+"), regressand = sp$regressand,
                   epsilon = win$epsilon, m = m, lag_order = p)
      tr <- add_test_rows(res, meta)
      tr$break_specification <- used$tag
      test_rows[[length(test_rows) + 1L]] <- tr
      if (!is.null(res$ci)) {
        date_rows[[length(date_rows) + 1L]] <- cbind(
          data.frame(spec = sp$spec, route = "system_equation", window = wkey,
                     series = paste(dcols, collapse = "+"), stringsAsFactors = FALSE),
          res$ci)
      }
      log_msg("  [system_equation] p=", p, ", spec=", used$tag, ": ",
              res$rule$selected, " break(s) ",
              if (length(res$break_years)) paste(res$break_years, collapse = ";") else "none")
    }
  }
}

# ---------------------------------------------------------------------------
# 6.5. Wage-mechanization channel: full-sample break search on Delta(kappa . omega)
# ---------------------------------------------------------------------------
# Feeds T_B* to US_S33E. Three things about this block are deliberate.
#
# WHY A SEPARATE BLOCK, NOT A SPECS ENTRY. A SPECS entry drives both routes, and the
# derived product kappa_t * omega_{t-1} has no companion regressors for a
# system_equation reading -- forcing one would enter a CPR cross-product as a base
# regressor in a differenced-vector relation. Only the univariate route applies.
#
# WHY UNIVARIATE ON THE FULL SAMPLE. On Full_Sample_1929_2024 the system_equation route
# over the five-variable vector returns zero confirmed breaks: the joint UDmax/sequential
# rule cannot localise a shift across 94 years of five series at once. The univariate
# route on a single series does confirm breaks in that same window (d_p_kappa lands
# 1945/1995/2008). Single-channel search is what has power at full-sample length.
#
# WHY THIS CHANNEL ONLY. ch2_sec2_theoretical_foundations_prelatex.md Sec.2.6 predicts
# regime change in the wage-mechanization nexus specifically -- Fordist coupling giving
# way to Post-Fordist institutional decoupling. It makes no comparable prediction for the
# price-conditioning channel, so kappa . p^kappa is not searched and enters US_S33E
# additively with no internal break.
#
# T_B* ADJUDICATION. If several breaks clear the UDmax-first rule, US_S33E takes the one
# nearest 1974 and reports the distance. The search is NOT restricted to a band around
# the theoretical date: a break landing far from 1974 is evidence about when the
# decoupling actually bit, and constraining the window would make the test incapable of
# falsifying the periodization it is supposed to examine.

WAGE_MECH_WINDOW <- "Full_Sample_1929_2024"
wm_win <- S33_WINDOWS[[WAGE_MECH_WINDOW]]

pb <- panel_b
pb$kappa_omega <- pb$kappa * pb$omega_lag1
pb <- pb[stats::complete.cases(pb[, c("year", "kappa", "omega_lag1", "kappa_omega")]), ,
         drop = FALSE]
pb <- pb[order(pb$year), , drop = FALSE]

dwm <- diff_frame(pb, "kappa_omega")
dwm <- dwm[dwm$year >= wm_win$range[1] & dwm$year <= wm_win$range[2], , drop = FALSE]
dwm <- dwm[stats::complete.cases(dwm), , drop = FALSE]

wage_mech_searched <- FALSE
log_msg("Spec_B_WageMech / ", WAGE_MECH_WINDOW, ": ", nrow(dwm),
        " differenced obs on d_kappa_omega, eps=", wm_win$epsilon, ", m=",
        max_breaks_for(WAGE_MECH_WINDOW))

if (nrow(dwm) < 20L) {
  log_msg("  SKIPPED: fewer than 20 usable observations")
} else {
  wm_m   <- max_breaks_for(WAGE_MECH_WINDOW)
  wm_res <- run_bp(dwm, "d_kappa_omega", z_names = NULL, x_names = NULL,
                   eps1 = wm_win$epsilon, m = wm_m, years = dwm$year)
  if (!wm_res$ok) {
    log_msg("  [univariate_mean] d_kappa_omega FAILED: ", wm_res$error)
  } else {
    wage_mech_searched <- TRUE
    wm_meta <- list(spec = "Spec_B_WageMech", route = "univariate_mean",
                    window = WAGE_MECH_WINDOW, series = "d_kappa_omega",
                    regressand = "d_kappa_omega", epsilon = wm_win$epsilon,
                    m = wm_m, lag_order = 0L)
    wm_tr <- add_test_rows(wm_res, wm_meta)
    wm_tr$break_specification <- "intercept_only_mean_shift"
    test_rows[[length(test_rows) + 1L]] <- wm_tr
    if (!is.null(wm_res$ci)) {
      date_rows[[length(date_rows) + 1L]] <- cbind(
        data.frame(spec = "Spec_B_WageMech", route = "univariate_mean",
                   window = WAGE_MECH_WINDOW, series = "d_kappa_omega",
                   stringsAsFactors = FALSE), wm_res$ci)
    }
    log_msg("  [univariate_mean] d_kappa_omega: ", wm_res$rule$selected, " break(s) ",
            if (length(wm_res$break_years))
              paste(wm_res$break_years, collapse = ";") else "none")
    if (length(wm_res$break_years)) {
      nearest <- wm_res$break_years[which.min(abs(wm_res$break_years - 1974L))]
      log_msg("  T_B* nearest 1974: ", nearest, " (distance ",
              abs(nearest - 1974L), " years)")
    }
  }
}

test_ledger <- if (length(test_rows)) do.call(rbind, test_rows) else
  data.frame(spec = character(), route = character(), window = character())
date_ledger <- if (length(date_rows)) do.call(rbind, date_rows) else
  data.frame(spec = character(), route = character(), window = character(),
             series = character(), break_number = integer(), break_year = integer(),
             ci95_low = integer(), ci95_high = integer())
lag_ledger  <- if (length(lag_rows)) do.call(rbind, lag_rows) else
  data.frame(spec = character(), window = character())

# ---------------------------------------------------------------------------
# 7. Protocol-date concordance
# ---------------------------------------------------------------------------
# For every protocol candidate date, the nearest Bai-Perron estimate in that window and
# the distance between them. A protocol date with no estimate within two years is
# reported as unsupported. This is the ledger the reports must quote before repeating
# 1933 / 1947 / 1968 / 1982 / 2000 / 2008 as if they were established.

conc_rows <- list()
for (sp in SPECS) {
  for (wkey in sp$windows) {
    win <- S33_WINDOWS[[wkey]]
    est <- date_ledger[date_ledger$spec == sp$spec & date_ledger$window == wkey, , drop = FALSE]
    for (pd in win$protocol_dates) {
      if (nrow(est)) {
        dist <- abs(est$break_year - pd)
        i <- which.min(dist)
        nearest <- est$break_year[i]; dmin <- dist[i]
        route <- est$route[i]; series <- est$series[i]
      } else {
        nearest <- NA_integer_; dmin <- NA_real_; route <- NA_character_; series <- NA_character_
      }
      conc_rows[[length(conc_rows) + 1L]] <- data.frame(
        spec = sp$spec, window = wkey, protocol_date = pd,
        protocol_source = win$dates_source,
        nearest_bp_estimate = nearest, nearest_route = route, nearest_series = series,
        year_distance = dmin,
        supported_within_2yr = if (is.na(dmin)) FALSE else dmin <= 2,
        n_bp_estimates_in_window = nrow(est),
        stringsAsFactors = FALSE)
    }
  }
}
conc_ledger <- if (length(conc_rows)) do.call(rbind, conc_rows) else
  data.frame(spec = character(), window = character(), protocol_date = integer())

s33_write_ledger(test_ledger, CSV_DIR, "bai_perron_test_ledger.csv")
s33_write_ledger(date_ledger, CSV_DIR, "bai_perron_break_dates.csv")
s33_write_ledger(lag_ledger,  CSV_DIR, "bai_perron_lag_selection.csv")
s33_write_ledger(conc_ledger, CSV_DIR, "bai_perron_protocol_concordance.csv")

# ---------------------------------------------------------------------------
# 8. Stage integrity
# ---------------------------------------------------------------------------

windows_covered <- unique(test_ledger$window)
expected_windows <- unique(unlist(lapply(SPECS, `[[`, "windows")))

# Every series and regressand handed to mbreaks must be a differenced column. This is
# the S03 Sec.2A constraint, and it is checked against the ledger rather than asserted.
all_terms <- unique(unlist(strsplit(c(test_ledger$series, test_ledger$regressand), "+", fixed = TRUE)))
diffs_only <- length(all_terms) > 0 && all(grepl("^d_", all_terms))

# No concordance row may carry a "nearest estimate" that is not an actual Bai-Perron
# estimate from the same spec and window: this is what proves protocol dates were not
# quietly written in as if they had been estimated.
no_substitution <- nrow(conc_ledger) > 0 && all(vapply(seq_len(nrow(conc_ledger)), function(i) {
  ne <- conc_ledger$nearest_bp_estimate[i]
  if (is.na(ne)) return(TRUE)
  ne %in% date_ledger$break_year[date_ledger$spec == conc_ledger$spec[i] &
                                   date_ledger$window == conc_ledger$window[i]]
}, logical(1)))

integrity <- s33_integrity(
  checks = c(
    "differences_only_no_levels",
    "both_protocol_routes_run",
    "all_protocol_windows_covered",
    "trimming_parameters_from_protocol",
    "udmax_first_sequential_rule_applied",
    "wdmax_absence_declared_not_approximated",
    "protocol_dates_not_substituted_for_estimates",
    "concordance_ledger_written",
    "wage_mech_derived_series_searched",
    "outputs_confined_to_break_aware_tree",
    "mbreaks_version_recorded"
  ),
  passed = c(
    diffs_only,
    all(c("univariate_mean", "system_equation") %in% unique(test_ledger$route)),
    all(expected_windows %in% windows_covered),
    all(vapply(expected_windows, function(w) {
      e <- unique(test_ledger$epsilon[test_ledger$window == w])
      length(e) == 1L && isTRUE(all.equal(e, S33_WINDOWS[[w]]$epsilon))
    }, logical(1))),
    all(test_ledger$selection_rule ==
          "UDmax at 5% must reject, then sequential supF(l+1|l) at 5%"),
    all(is.na(test_ledger$statistic[test_ledger$test == "WDmax"])),
    no_substitution,
    nrow(conc_ledger) > 0,
    wage_mech_searched &&
      any(test_ledger$spec == "Spec_B_WageMech" &
            test_ledger$series == "d_kappa_omega" &
            test_ledger$window == WAGE_MECH_WINDOW),
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE), fixed = TRUE),
    nzchar(MBREAKS_VERSION)
  ),
  detail = c(
    "BP run on first differences only; levels never passed to mbreaks::mdl (S03 Sec.2A)",
    paste("routes present:", paste(unique(test_ledger$route), collapse = ", ")),
    paste("windows:", paste(windows_covered, collapse = ", ")),
    paste(vapply(expected_windows, function(w)
      sprintf("%s eps=%.2f (%s)", w, S33_WINDOWS[[w]]$epsilon, S33_WINDOWS[[w]]$eps_source),
      character(1)), collapse = "; "),
    "CL_S25 rule: UDmax first, then sequential supF; mbreaks $SEQ$nbreak not read directly",
    "WDmax reported as NA with an explicit note; no approximation substituted",
    paste0(sum(conc_ledger$supported_within_2yr), " of ", nrow(conc_ledger),
           " protocol dates have a BP estimate within 2 years"),
    paste0(nrow(conc_ledger), " protocol-date rows written"),
    {
      wmd <- date_ledger[date_ledger$spec == "Spec_B_WageMech", , drop = FALSE]
      if (!nrow(wmd)) {
        "d_kappa_omega searched on the full sample; no break cleared the UDmax-first rule"
      } else {
        nearest <- wmd$break_year[which.min(abs(wmd$break_year - 1974L))]
        paste0("d_kappa_omega full-sample breaks: ",
               paste(wmd$break_year, collapse = ";"),
               "; nearest 1974 is ", nearest, " (distance ",
               abs(nearest - 1974L), " yr) -- feeds T_B* to US_S33E")
      }
    },
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
    paste("mbreaks", MBREAKS_VERSION)
  )
)

s33_write_ledger(integrity, CSV_DIR, "s33a_bai_perron_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33A")

log_msg("US_S33A complete. ", nrow(test_ledger), " test rows, ",
        nrow(date_ledger), " break dates, ",
        sum(conc_ledger$supported_within_2yr), "/", nrow(conc_ledger),
        " protocol dates supported within 2 years.")
log_msg("Next: Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R")
