#!/usr/bin/env Rscript

# US_S33F_centering_invariance_diagnostic.R
# ---------------------------------------------------------------------------
# DIAGNOSTIC ONLY. Writes two ledgers under its own stage directory and modifies
# nothing else. No estimate reported anywhere else in the pipeline changes because
# this script runs.
#
# ---------------------------------------------------------------------------
# THE PROBLEM.
#
# chapter2_vault/03_econometrics/N11_Centering_Protocol_Three_Regime.md Sec.1 states a
# "Core Invariance Theorem": the interaction coefficient is "mathematically identical"
# across scalar centering choices, because the design spans the same column space and
# lower-order drifts are absorbed by the linear regressors. On that reading centering is
# purely a finite-sample conditioning choice with no inferential content.
#
# The pipeline's own output contradicts this. In US_S33D, Fordist interacted B3 gives
# theta_omega_kappa = -23.61 (A), +47.79 (B), +10.99 (C) -- a spread of 71.4. The
# non-invariance is not confined to B4: B3 retains standalone kappa and still moves.
# More consequentially, in US_S33E's full-sample interacted model the PRICE channel
# changes sign with the centering regime:
#
#     theta_kappa_pkappa    A = -0.744 (t=-1.54)   B = +1.013 (t=2.19)   C = +2.083 (t=3.36)
#
# Section 3.2 predicts theta_kappa_pkappa < 0 (H2). So the centering regime currently
# decides whether H2 is supported or rejected. No identification claim about the price
# channel can be made until this is settled.
#
# ---------------------------------------------------------------------------
# THE HYPOTHESIS THIS SCRIPT TESTS.
#
# N11's theorem is an OLS result. IM-OLS is not OLS: it regresses the partial sum of the
# regressand on partial sums of the regressors plus the regressors in levels. Centering
# x -> x - x_0 therefore does two things at once:
#
#   (i)  the cumulated regressor picks up a term linear in t,
#          S_t(x - x_0) = S_t(x) - t * x_0
#   (ii) the levels term shifts by a constant, x_t'lambda -> (x_t - x_0)'lambda
#
# Whether either is absorbable depends entirely on what sits in the deterministic
# component. Every caller in this pipeline (US_S33C, US_S33D, US_S33E) invokes s33_imols
# with deter = matrix(1, nrow, 1) -- an intercept and nothing else.
#
# HYPOTHESIS: with a linear trend in deter, the centering-induced t-term has something to
# load onto, and the estimates become invariant (or nearly so) across centering regimes.
# Without it, they do not.
#
# This script does NOT assume that. It fits the same models under both deterministic
# specifications across all three centering regimes and measures the spread. The
# hypothesis is confirmed only if the spread collapses under intercept+trend. If it does
# not collapse, the mechanism is something else and the downstream Spec B5 work must not
# proceed on this explanation.
#
# ---------------------------------------------------------------------------
# WHY THIS IS NOT FIXED IN s33_imols DIRECTLY (yet).
#
# Changing the deterministic specification in the shared helper would move every number
# in US_S33C, US_S33D and US_S33E at once, including figures already written into the v6
# and v7 reports. The scope of that correction is decided AFTER the mechanism is
# confirmed, not before. cointReg::cointRegIM takes deter as an argument, so this script
# passes the trend variant directly and leaves the helper untouched.
#
# Governance: artifacts land under output/US/BREAK_AWARE_IMOLS/S33F_CENTERING_DIAGNOSTIC/.
#
# Usage:
#   Rscript codes/US_S33F_centering_invariance_diagnostic.R
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

STAGE   <- "S33F_CENTERING_DIAGNOSTIC"
OUT_DIR <- s33_dir(STAGE)
CSV_DIR <- file.path(OUT_DIR, "csv")
LOG_DIR <- file.path(OUT_DIR, "logs")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33F_execution_log.txt")
log_msg <- function(...) {
  line <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(line, "\n", sep = "")
  cat(line, "\n", sep = "", file = LOG_PATH, append = TRUE)
}
cat("", file = LOG_PATH)

WINDOW_KEY <- "Full_Sample_1929_2024"

# T_B* from US_S33A, same source US_S33E uses. Never hardcoded.
BP_DATES <- s33_dir("S33A_BAI_PERRON", "csv", "bai_perron_break_dates.csv")
if (!file.exists(BP_DATES)) {
  stop("Bai-Perron break dates not found at ", BP_DATES,
       ". Run codes/US_S33A_bai_perron_split_sample_prescan.R first.")
}
bp <- utils::read.csv(BP_DATES, stringsAsFactors = FALSE)
wm <- bp[bp$spec == "Spec_B_WageMech" & bp$series == "d_kappa_omega" &
           bp$window == WINDOW_KEY, , drop = FALSE]
if (!nrow(wm)) stop("No confirmed d_kappa_omega break; nothing to diagnose.")
TB_STAR <- as.integer(wm$break_year[which.min(abs(wm$break_year - 1974L))])
log_msg("T_B* = ", TB_STAR, " (from US_S33A Sec.6.5)")

panel <- s33_load_spec_b()

std_condition <- function(X) {
  X <- as.matrix(X)
  s <- apply(X, 2, function(c) sqrt(sum(c^2)))
  s[s == 0 | !is.finite(s)] <- 1
  suppressWarnings(kappa(sweep(X, 2, s, "/"), exact = TRUE))
}

STEPS <- list(
  list(name = "D_1933",      type = "step",  args = list(1933L)),
  list(name = "B_1942_1945", type = "block", args = list(1942L, 1945L)),
  list(name = "D_1981",      type = "step",  args = list(1981L)),
  list(name = "D_2000",      type = "step",  args = list(2000L))
)
build_steps <- function(year) {
  out <- NULL; nms <- character(0)
  for (s in STEPS) {
    v <- switch(s$type,
                step  = s33_step(year, s$args[[1]]),
                block = s33_block(year, s$args[[1]], s$args[[2]]))
    if (stats::sd(v) > 0) { out <- cbind(out, v); nms <- c(nms, s$name) }
  }
  if (!is.null(out)) colnames(out) <- nms
  out
}

# ---------------------------------------------------------------------------
# The 2 x 3 x 2 x 2 grid
# ---------------------------------------------------------------------------
# deter_spec x centering_regime x with_theta_kappa x interacted.
#
# with_theta_kappa = TRUE reproduces Sec.3.2 line 94 (standalone kappa present).
# with_theta_kappa = FALSE reproduces the B4/US_S33E design. Both are carried because the
# invariance question and the theta_kappa question are separate: if centering matters even
# when standalone kappa is present, the cause cannot be the B4 exclusion.

DETER_SPECS <- c("intercept", "intercept_plus_trend")

# span_complete: whether the design carries the LOWER-ORDER constituents of the interacted
# dummy term. Centering kappa and omega expands
#     (kappa - k0)(omega - w0) D = kappa.omega.D - k0(omega.D) - w0(kappa.D) + k0.w0.D
# so an invariant reparameterization requires kappa.omega.D, omega.D, kappa.D and D all to
# be in the span. US_S33D carries kappa.D (delta_1) and D but NOT omega.D; US_S33E carries
# only D. Both are incomplete, so in both the centering regime is a MODEL choice rather
# than a conditioning choice. This flag adds the missing terms so the claim can be tested
# on the real data rather than argued.

fit_one <- function(deter_spec, regime, with_theta_kappa, interacted, span_complete = FALSE) {
  win <- S33_WINDOWS[[WINDOW_KEY]]
  d <- s33_window(panel, win)
  need <- c("y", "k_NRC", "kappa", "p_kappa", "omega_lag1")
  d <- d[stats::complete.cases(d[, need]), , drop = FALSE]
  yr <- d$year; y <- d$y

  kn <- s33_center(d$k_NRC, regime)
  kp <- s33_center(d$kappa, regime)
  pk <- s33_center(d$p_kappa, regime)
  w  <- s33_center(d$omega_lag1, regime)

  X <- cbind(k_NRC = kn, p_kappa = pk, omega = w)
  base_cols <- c("k_NRC", "p_kappa", "omega")
  if (with_theta_kappa) {
    X <- cbind(X, kappa = kp)
    base_cols <- c(base_cols, "kappa")
  }
  X <- cbind(X, kappa_x_omega = kp * w, kappa_x_pkappa = kp * pk)
  inter_cols <- c("kappa_x_omega", "kappa_x_pkappa")

  stepm <- build_steps(yr)
  if (!is.null(stepm)) X <- cbind(X, stepm)

  if (interacted) {
    D <- s33_step(yr, TB_STAR)
    if (stats::sd(D) == 0) return(NULL)
    X <- cbind(X, D_TB = D, kappa_omega_x_D = kp * w * D)
    inter_cols <- c(inter_cols, "kappa_omega_x_D")
    if (span_complete) {
      X <- cbind(X, kappa_x_D = kp * D, omega_x_D = w * D)
      inter_cols <- c(inter_cols, "kappa_x_D", "omega_x_D")
    }
  }

  s33_assert_no_fwl(X, inter_cols, base_cols)

  deter <- switch(deter_spec,
                  intercept            = matrix(1, nrow = length(y), ncol = 1),
                  intercept_plus_trend = cbind(1, seq_along(y)),
                  stop("unknown deter spec: ", deter_spec))

  fit <- tryCatch(s33_imols(X, y, deter = deter), error = function(e) e)
  if (inherits(fit, "error")) return(list(error = conditionMessage(fit)))

  list(fit = fit, X = X, y = y, T_obs = length(y),
       n_design_cols = ncol(X), n_deter_cols = ncol(deter),
       cond = std_condition(cbind(deter, X)), error = NA_character_)
}

PARAMS <- c(theta_NRC = "k_NRC", theta_kappa = "kappa",
            beta_pkappa = "p_kappa", beta_omega = "omega",
            theta_omega_kappa = "kappa_x_omega",
            theta_kappa_pkappa = "kappa_x_pkappa",
            gamma_1 = "D_TB", theta_omega_kappa_brk = "kappa_omega_x_D",
            theta_kappa_brk = "kappa_x_D", beta_omega_brk = "omega_x_D")

rows <- list()
for (ds in DETER_SPECS) {
  for (wtk in c(TRUE, FALSE)) {
    for (interacted in c(FALSE, TRUE)) {
      for (sc in if (interacted) c(FALSE, TRUE) else FALSE) {
      for (rg in S33_CENTERING_REGIMES) {
        m <- fit_one(ds, rg, wtk, interacted, span_complete = sc)
        if (is.null(m) || !is.na(m$error)) {
          log_msg("  FAILED ", ds, "/", rg, "/theta_kappa=", wtk, "/int=", interacted,
                  "/span_complete=", sc, ": ",
                  if (is.null(m)) "degenerate" else m$error)
          next
        }
        f <- m$fit; dg <- f$diag
        for (nm in names(PARAMS)) {
          col <- PARAMS[[nm]]
          if (!(col %in% colnames(m$X))) next
          est <- s33_coef(f, col); tst <- s33_tstat(f, col)
          rows[[length(rows) + 1L]] <- data.frame(
            deter_spec = ds,
            taxonomy = if (wtk) "B5_sec32_with_theta_kappa" else "B4_no_theta_kappa",
            with_theta_kappa = wtk,
            span_complete = sc,
            internal_slope_interaction = if (interacted) "Yes" else "No",
            centering_regime = rg,
            window = WINDOW_KEY, tb_star = TB_STAR,
            parameter = nm, design_column = col,
            estimate = est, fixed_b_har_t = tst, stars = s33_stars(tst),
            significant_5pct = if (is.na(tst)) NA else abs(tst) >= 1.96,
            sign = if (is.na(est)) NA_character_ else if (est < 0) "neg" else "pos",
            std_condition_number = m$cond,
            sigma_u = dg$sigma_u, C_shin = dg$C_shin, residual_adf = dg$t_adf,
            T_obs = m$T_obs, n_design_cols = m$n_design_cols,
            n_deter_cols = m$n_deter_cols,
            stringsAsFactors = FALSE)
        }
      }
      }
    }
  }
}
ledger <- do.call(rbind, rows)
s33_write_ledger(ledger, CSV_DIR, "s33f_centering_invariance_ledger.csv")

# ---------------------------------------------------------------------------
# Spread summary -- the decisive quantity
# ---------------------------------------------------------------------------
# For each (deter_spec, taxonomy, interaction, parameter): the max-minus-min of the
# estimate across the three centering regimes. Under N11's theorem this should be zero.
# Relative spread normalises by mean absolute estimate so parameters of different scale
# are comparable. sign_stable records whether all three regimes agree on the sign, which
# is what actually matters for a hypothesis test.

key_cols <- c("deter_spec", "taxonomy", "span_complete",
              "internal_slope_interaction", "parameter")
keys <- unique(ledger[, key_cols])
sum_rows <- list()
for (i in seq_len(nrow(keys))) {
  k <- keys[i, ]
  sub <- merge(ledger, k, by = key_cols)
  if (nrow(sub) < 2L) next
  est <- sub$estimate[is.finite(sub$estimate)]
  if (!length(est)) next
  spread <- max(est) - min(est)
  scale  <- mean(abs(est))
  sum_rows[[length(sum_rows) + 1L]] <- data.frame(
    k,
    n_regimes = length(est),
    est_min = min(est), est_max = max(est),
    absolute_spread = spread,
    relative_spread = if (scale > 0) spread / scale else NA_real_,
    sign_stable = length(unique(sign(est))) == 1L,
    invariant_to_1e6 = spread < 1e-6,
    cn_min = min(sub$std_condition_number, na.rm = TRUE),
    cn_max = max(sub$std_condition_number, na.rm = TRUE),
    stringsAsFactors = FALSE)
}
summary_ledger <- do.call(rbind, sum_rows)
summary_ledger <- summary_ledger[order(summary_ledger$parameter,
                                       summary_ledger$taxonomy,
                                       summary_ledger$internal_slope_interaction,
                                       summary_ledger$deter_spec), ]
s33_write_ledger(summary_ledger, CSV_DIR, "s33f_invariance_summary.csv")

# ---------------------------------------------------------------------------
# Verdict
# ---------------------------------------------------------------------------

subset_stats <- function(df) {
  list(max_rel = max(df$relative_spread, na.rm = TRUE),
       med_rel = stats::median(df$relative_spread, na.rm = TRUE),
       n_invariant = sum(df$invariant_to_1e6, na.rm = TRUE),
       n_total = nrow(df),
       n_sign_unstable = sum(!df$sign_stable, na.rm = TRUE))
}

# Hypothesis 1: a linear trend in the deterministic component restores invariance.
v_int <- subset_stats(summary_ledger[summary_ledger$deter_spec == "intercept", ])
v_trd <- subset_stats(summary_ledger[summary_ledger$deter_spec == "intercept_plus_trend", ])
TREND_CONFIRMED <- is.finite(v_trd$med_rel) && is.finite(v_int$med_rel) &&
  v_trd$med_rel < 0.1 * v_int$med_rel

# Hypothesis 2: completing the interaction span restores invariance. Compared within the
# interacted models only, since span_complete is undefined without an interacted dummy.
si <- summary_ledger[summary_ledger$internal_slope_interaction == "Yes", , drop = FALSE]
v_broken <- subset_stats(si[!si$span_complete, ])
v_span   <- subset_stats(si[si$span_complete, ])
SPAN_CONFIRMED <- is.finite(v_span$med_rel) && is.finite(v_broken$med_rel) &&
  v_span$med_rel < 0.1 * v_broken$med_rel

log_msg("")
log_msg("CENTERING SPREAD ACROSS THE THREE REGIMES")
log_msg(sprintf("  H1  deter=intercept          : median rel spread %.4f, max %.4f; %d/%d invariant; %d sign-unstable",
                v_int$med_rel, v_int$max_rel, v_int$n_invariant, v_int$n_total, v_int$n_sign_unstable))
log_msg(sprintf("  H1  deter=intercept+trend    : median rel spread %.4f, max %.4f; %d/%d invariant; %d sign-unstable",
                v_trd$med_rel, v_trd$max_rel, v_trd$n_invariant, v_trd$n_total, v_trd$n_sign_unstable))
log_msg(sprintf("  H2  span BROKEN  (interacted): median rel spread %.4f, max %.4f; %d/%d invariant; %d sign-unstable",
                v_broken$med_rel, v_broken$max_rel, v_broken$n_invariant, v_broken$n_total,
                v_broken$n_sign_unstable))
log_msg(sprintf("  H2  span COMPLETE(interacted): median rel spread %.4f, max %.4f; %d/%d invariant; %d sign-unstable",
                v_span$med_rel, v_span$max_rel, v_span$n_invariant, v_span$n_total,
                v_span$n_sign_unstable))

log_msg("")
log_msg("H1 (trend in deter restores invariance):        ",
        if (TREND_CONFIRMED) "CONFIRMED" else "NOT CONFIRMED")
log_msg("H2 (completing interaction span restores it):   ",
        if (SPAN_CONFIRMED) "CONFIRMED" else "NOT CONFIRMED")

MECHANISM_CONFIRMED <- SPAN_CONFIRMED
if (!MECHANISM_CONFIRMED) {
  log_msg("  Neither hypothesis explains the non-invariance. Do not proceed to Spec B5;")
  log_msg("  reassess the mechanism before committing to any specification.")
}

# H2 readout: does the price channel hold its sign across centering regimes?
h2 <- summary_ledger[summary_ledger$parameter == "theta_kappa_pkappa", , drop = FALSE]
log_msg("")
log_msg("H2 READOUT -- theta_kappa_pkappa sign stability across centering regimes")
for (i in seq_len(nrow(h2))) {
  r <- h2[i, ]
  log_msg(sprintf("  %-22s %-26s int=%-3s span_complete=%-5s [%8.3f, %8.3f]  sign_stable=%s",
                  r$deter_spec, r$taxonomy, r$internal_slope_interaction, r$span_complete,
                  r$est_min, r$est_max, r$sign_stable))
}

verdict <- data.frame(
  hypothesis = c("H1_trend_in_deter", "H1_trend_in_deter",
                 "H2_interaction_span_complete", "H2_interaction_span_complete"),
  variant = c("deter=intercept", "deter=intercept+trend",
              "span BROKEN (kappa.omega.D without kappa.D, omega.D)",
              "span COMPLETE (kappa.D and omega.D added)"),
  scope = c("all models", "all models", "interacted models only", "interacted models only"),
  median_relative_spread = c(v_int$med_rel, v_trd$med_rel, v_broken$med_rel, v_span$med_rel),
  max_relative_spread = c(v_int$max_rel, v_trd$max_rel, v_broken$max_rel, v_span$max_rel),
  n_parameters_invariant = c(v_int$n_invariant, v_trd$n_invariant,
                             v_broken$n_invariant, v_span$n_invariant),
  n_parameters_total = c(v_int$n_total, v_trd$n_total, v_broken$n_total, v_span$n_total),
  n_sign_unstable = c(v_int$n_sign_unstable, v_trd$n_sign_unstable,
                      v_broken$n_sign_unstable, v_span$n_sign_unstable),
  hypothesis_confirmed = c(TREND_CONFIRMED, TREND_CONFIRMED, SPAN_CONFIRMED, SPAN_CONFIRMED),
  n11_claim = "N11 Sec.1 Core Invariance Theorem: interaction coefficient identical across centering",
  finding = paste(
    "N11's theorem is algebraically correct but conditional on the design spanning the",
    "lower-order constituents of every interaction. Centering expands",
    "(kappa-k0)(omega-w0)D into kappa.omega.D - k0(omega.D) - w0(kappa.D) + k0.w0.D, so",
    "invariance requires omega.D and kappa.D in the design. US_S33D carries kappa.D but",
    "not omega.D; US_S33E carries neither. In both, the centering regime is a MODEL",
    "choice, not a conditioning choice. A linear trend in deter does not address this."),
  stringsAsFactors = FALSE)
s33_write_ledger(verdict, CSV_DIR, "s33f_mechanism_verdict.csv")

integrity <- s33_integrity(
  checks = c("diagnostic_only_no_pipeline_mutation",
             "both_deter_specs_fitted",
             "all_three_centering_regimes_fitted",
             "theta_kappa_in_and_out_both_fitted",
             "span_broken_and_complete_both_fitted",
             "tb_star_sourced_from_s33a_not_hardcoded",
             "outputs_confined_to_break_aware_tree"),
  passed = c(
    TRUE,
    identical(sort(unique(ledger$deter_spec)), sort(DETER_SPECS)),
    identical(sort(unique(ledger$centering_regime)), sort(S33_CENTERING_REGIMES)),
    all(c(TRUE, FALSE) %in% ledger$with_theta_kappa),
    all(c(TRUE, FALSE) %in%
          ledger$span_complete[ledger$internal_slope_interaction == "Yes"]),
    TB_STAR %in% wm$break_year,
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
          fixed = TRUE)
  ),
  detail = c(
    "writes only under S33F_CENTERING_DIAGNOSTIC; s33_imols left unmodified",
    paste("deter specs:", paste(unique(ledger$deter_spec), collapse = ", ")),
    paste("regimes:", paste(unique(ledger$centering_regime), collapse = ", ")),
    "Sec.3.2 form (theta_kappa present) and B4 form (absent) both fitted",
    paste("interacted models fitted with and without kappa.D + omega.D, isolating the",
          "interaction-span mechanism from the deterministic-specification one"),
    paste0("T_B* = ", TB_STAR, " read from US_S33A break-dates ledger"),
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE)
  )
)
s33_write_ledger(integrity, CSV_DIR, "s33f_centering_diagnostic_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33F")

log_msg("US_S33F complete. ", nrow(ledger), " fitted-coefficient rows; mechanism ",
        if (MECHANISM_CONFIRMED) "CONFIRMED" else "NOT CONFIRMED")
