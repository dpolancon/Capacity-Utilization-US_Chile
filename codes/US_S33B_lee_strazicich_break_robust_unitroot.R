#!/usr/bin/env Rscript

# US_S33B_lee_strazicich_break_robust_unitroot.R
# ---------------------------------------------------------------------------
# Step 2 of the binding S0* break-aware pre-testing sequence:
#
#     Lee-Strazicich (2003) Minimum-LM unit root test on the LEVELS, with breaks
#     entering under BOTH the null and the alternative, to establish that the
#     capital series are I(1)-with-break rather than spuriously I(2).
#
# Authority:
#   S03 Sec.2B  -- Zivot-Andrews and Lumsdaine-Papell admit breaks only under H1,
#                  producing size distortions and spurious rejections. The LS Minimum-LM
#                  test puts breaks under both hypotheses, which is why it is the
#                  mandated engine here.
#   S03 Sec.2C  -- Stage 1B decision matrix. LS rejects  -> series is I(1) conditionally
#                  on T_B; construct D_t and DT_t and proceed to the cointegration stage.
#                  LS fails to reject -> a true I(2) process persists; switch the Stage 1
#                  level specification to investment flows.
#   S01 Sec.2 Step 2 -- run on the sub-sample levels of k_t^cap, with Z_t carrying BOTH
#                  level terms D_t and trend-break terms DT_t. That is Model C.
#   S02 Stage 2B     -- same, on k_t^NRC and kappa_t.
#
# MANDATED ENGINE: C:/ReposGitHub/LeeStrazicichUnitRoot (ur.ls). P05 forbids a
# hand-rolled substitute, and none is used. See section 9 of US_S33_break_aware_common.R
# for the pinned adapter.
#
# ---------------------------------------------------------------------------
# DEVIATION ON RECORD -- read before quoting any number this script produces.
#
# S01 Sec.2 Step 2 and S02 Stage 2B ask for the LM test AT THE CANDIDATE BREAK DATES
# returned by Bai-Perron. ur.ls() cannot do that. It locates breaks ENDOGENOUSLY by
# grid-minimising the LM statistic, exposes no fixed-break-date argument, and defines
# its LM regression helper (myLSfunc) inside the function body where it cannot be
# reached. The options were: hand-roll a fixed-date LM test (forbidden by P05), or run
# the mandated engine as designed and report the date agreement honestly.
#
# This script does the latter. It runs the endogenous search and writes
# ls_bp_break_concordance.csv scoring the LS dates against the US_S33A Bai-Perron dates
# and against the protocol candidates. The integration-order verdict comes from the LM
# statistic; the date agreement is reported separately and is never used to launder a
# protocol date into an estimated one.
# ---------------------------------------------------------------------------
#
# SECOND CAVEAT ON RECORD. Every ur.ls() critical value is tabulated at T = 100. The
# Fordist window carries T ~ 45 and the Post-Fordist window T ~ 51, so in the
# sub-samples these are approximations and the test is over-sized. Each ledger row
# carries the actual T and the ratio, and both report drafts state it in prose.
#
# ---------------------------------------------------------------------------
# THIRD DEVIATION ON RECORD -- the S03 Sec.2C decision matrix is mis-specified, and
# following it literally gives the wrong integration order. This matters more than the
# other two, so it is documented in full.
#
# S03 Sec.2C runs the LM test on the LEVELS and branches:
#     "LS Rejects Unit Root Null -> k^ME_t is I(1) conditionally on T_B"
#     "LS Fails to Reject        -> True I(2) process persists"
#
# That inverts the standard reading. The LS null is a unit root IN THE SERIES TESTED.
# For a series that is genuinely I(1), a unit root in levels is exactly what is present,
# so failing to reject in levels is the CORRECT and EXPECTED outcome -- not evidence of
# I(2). Rejection in levels would instead mean the series is I(0)/trend-stationary
# around breaks, which is a different finding altogether. Levels alone cannot separate
# I(1) from I(2): both fail to reject.
#
# This is not hypothetical here. Run against levels only, the matrix returned
# "persistent_I2_risk" for k_t^cap, k_t^NRC and kappa_t in almost every window -- the
# very series the v5 and v6 reports estimate as I(1), and which the S31I integration
# audit already classifies as I(1). A pre-testing stage that blocks its own capital
# stocks as I(2) is diagnosing itself, not the data.
#
# What actually discriminates I(1) from I(2), and what S03 Sec.2B says it wants
# ("eliminating spurious I(2) classification"), is the LM test on the FIRST DIFFERENCE:
# if Delta y_t rejects the unit root under broken deterministics, then Delta y_t is
# I(0)-with-break and y_t is I(1)-with-break, not I(2).
#
# This script therefore runs the mandated engine on BOTH the levels and the first
# differences and adjudicates on the pair. The levels result is retained exactly as the
# protocol asks and reported; it simply stops being read as an I(2) verdict on its own.
# Every verdict row carries both statistics and names the branch it took, so the
# departure from the literal matrix is auditable rather than silent.
# ---------------------------------------------------------------------------
#
# Governance: artifacts land under output/US/BREAK_AWARE_IMOLS/S33B_LEE_STRAZICICH/.
#
# Usage:
#   Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R
#   Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R --probe
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

ARGS  <- commandArgs(trailingOnly = TRUE)
PROBE <- "--probe" %in% ARGS

STAGE   <- "S33B_LEE_STRAZICICH"
OUT_DIR <- s33_dir(STAGE)
CSV_DIR <- file.path(OUT_DIR, "csv")
LOG_DIR <- file.path(OUT_DIR, "logs")
RAW_DIR <- file.path(OUT_DIR, "raw")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR); s33_ensure_dir(RAW_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33B_execution_log.txt")
log_msg <- function(...) {
  line <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(line, "\n", sep = "")
  cat(line, "\n", sep = "", file = LOG_PATH, append = TRUE)
}
cat("", file = LOG_PATH)

# ---------------------------------------------------------------------------
# 1. Bind the mandated engine
# ---------------------------------------------------------------------------

log_msg("Binding Lee-Strazicich engine at ", S33_LS_REPO)
LS_ENV <- s33_ls_load()
log_msg("  load route: ", attr(LS_ENV, "route"))

if (PROBE) {
  cat("\nCallables exposed by ", S33_LS_REPO, ":\n\n", sep = "")
  print(s33_ls_catalogue(LS_ENV))
  cat("\nPinned entry point: ", S33_LS_FUN, "\n", sep = "")
  cat("Date mode         : ", S33_LS_DATE_MODE, "\n", sep = "")
  quit(save = "no", status = 0)
}

LS_FUN <- s33_ls_resolve(LS_ENV)
log_msg("  resolved entry point: ", LS_FUN)

# ---------------------------------------------------------------------------
# 2. Series under test
# ---------------------------------------------------------------------------
# S01 Sec.2 Step 2 names k_t^cap. S02 Stage 2B names k_t^NRC and kappa_t. y_t and
# omega_{t-1} are added because the Interaction_Term_Integration_Order_Gate requires
# the BASE variables (y, k, kappa, omega) to be classified before any interacted
# specification advances to estimator selection -- US_S33C/D read those verdicts.

panel_a <- s33_load_spec_a()
panel_b <- s33_load_spec_b()

TARGETS <- list(
  list(spec = "Spec_A", panel = panel_a, var = "k_cap",
       label = "k_t^cap", role = "capital_stock",
       source = "S01 Sec.2 Step 2 (named target)"),
  list(spec = "Spec_A", panel = panel_a, var = "y",
       label = "y_t^NFC", role = "regressand",
       source = "Interaction gate item 1 (base variable)"),
  list(spec = "Spec_A", panel = panel_a, var = "omega_lag1",
       label = "omega_{t-1}", role = "distribution",
       source = "Interaction gate item 1 (base variable)"),
  list(spec = "Spec_B", panel = panel_b, var = "k_NRC",
       label = "k_t^NRC", role = "capital_stock",
       source = "S02 Stage 2B (named target)"),
  list(spec = "Spec_B", panel = panel_b, var = "kappa",
       label = "kappa_t", role = "mechanization_gap",
       source = "S02 Stage 2B (named target)"),
  list(spec = "Spec_B", panel = panel_b, var = "p_kappa",
       label = "p_t^kappa", role = "relative_price",
       source = "Interaction gate item 1 (base variable)")
)

WINDOW_KEYS <- c("Full_Sample_1929_2024", "Fordist_1929_1973", "Post_Fordist_1974_2024")

# Model A ("crash") = intercept break only; Model C ("break") = intercept AND trend
# break. S01 Sec.2 Step 2 requires Z_t to carry both D_t and DT_t, so Model C is the
# protocol-relevant run. Model A is retained as the reported companion.
MODELS <- c(C = "protocol (S01 Step 2: Z_t carries D_t and DT_t)",
            A = "companion (intercept break only)")

LS_MAX_LAG <- 4L   # GTOS maximum, matching the max_lag used in the S33A lag ladder.

# levels           -- what S01 Sec.2 Step 2 and S02 Stage 2B literally request.
# first_difference -- what actually separates I(1)-with-break from I(2), per the third
#                     deviation note at the head of this file.
TRANSFORMS <- list(
  levels = list(key = "levels", fun = function(y) y, drops = 0L,
                source = "S01 Sec.2 Step 2 / S02 Stage 2B (literal protocol request)"),
  first_difference = list(key = "first_difference", fun = function(y) diff(y), drops = 1L,
                          source = "discriminates I(1)-with-break from I(2); S03 Sec.2B intent")
)

# ---------------------------------------------------------------------------
# 3. Run the endogenous minimum-LM grid
# ---------------------------------------------------------------------------

lm_rows <- list()

for (tg in TARGETS) {
  for (wkey in WINDOW_KEYS) {
    win <- S33_WINDOWS[[wkey]]
    d <- s33_window(tg$panel, win)
    d <- d[!is.na(d[[tg$var]]), , drop = FALSE]
    y_lev <- d[[tg$var]]
    yrs_lev <- d$year

    if (length(y_lev) < 25L) {
      log_msg(tg$spec, "/", tg$var, "/", wkey, ": SKIPPED (T=", length(y_lev), " < 25)")
      next
    }

    for (tf in TRANSFORMS) {
    y   <- tf$fun(y_lev)
    yrs <- if (tf$drops > 0L) yrs_lev[-seq_len(tf$drops)] else yrs_lev
    T_obs <- length(y)

    for (mk in names(MODELS)) {
      for (nb in 1:S33_LS_MAX_BREAKS) {
        dump <- file.path(RAW_DIR, sprintf("ls_raw_%s_%s_%s_%s_model%s_%dbreak.txt",
                                           tg$spec, tg$var, wkey, tf$key, mk, nb))
        r <- s33_ls_run(LS_ENV, LS_FUN, y = y, years = yrs, model = mk, breaks = nb,
                        max_lag = LS_MAX_LAG, trim = win$epsilon, dump_path = dump)

        cv <- s33_ls_cval(mk, nb, lambda1 = r$lambda1, lambda2 = r$lambda2)
        c1  <- suppressWarnings(as.numeric(cv[["crit_1"]]))
        c5  <- suppressWarnings(as.numeric(cv[["crit_5"]]))
        c10 <- suppressWarnings(as.numeric(cv[["crit_10"]]))
        stat <- r$lm_statistic

        rej5 <- if (!is.finite(stat) || !is.finite(c5)) NA else stat < c5

        lm_rows[[length(lm_rows) + 1L]] <- data.frame(
          spec = tg$spec, variable = tg$var, notation = tg$label, role = tg$role,
          target_source = tg$source,
          transform = tf$key, transform_source = tf$source,
          window = wkey, sample_start = min(yrs), sample_end = max(yrs), T_obs = T_obs,
          ls_model = mk,
          ls_model_arg = s33_ls_model_arg(mk),
          ls_model_role = unname(MODELS[[mk]]),
          breaks = nb,
          trim_pn = win$epsilon, trim_source = win$eps_source,
          lag_method = "GTOS", max_lag = LS_MAX_LAG, selected_lag = r$selected_lag,
          lm_statistic = stat,
          crit_1 = c1, crit_5 = c5, crit_10 = c10,
          cval_basis = unname(cv[["basis"]]),
          cval_tabulated_T = S33_LS_CVAL_SAMPLE_SIZE,
          cval_sample_size_caveat = sprintf(
            "critical values tabulated at T=%d; this window has T=%d (ratio %.2f)",
            S33_LS_CVAL_SAMPLE_SIZE, T_obs, T_obs / S33_LS_CVAL_SAMPLE_SIZE),
          rejects_unit_root_5pct = rej5,
          break_positions = r$break_positions,
          ls_break_years = r$break_years,
          lambda1 = r$lambda1, lambda2 = r$lambda2,
          date_mode = S33_LS_DATE_MODE,
          engine = paste0(LS_FUN, " @ ", S33_LS_REPO),
          normalised = r$normalised,
          error = r$error,
          stringsAsFactors = FALSE)

        log_msg(sprintf("  %-6s %-10s %-22s %-16s model%s %dbrk: LM=%s cv5=%s -> %s",
                        tg$spec, tg$var, wkey, tf$key, mk, nb,
                        ifelse(is.finite(stat), sprintf("%7.3f", stat), "     NA"),
                        ifelse(is.finite(c5), sprintf("%7.3f", c5), "     NA"),
                        ifelse(is.na(rej5), "INDETERMINATE",
                               ifelse(rej5, "REJECT", "fail-to-reject"))))
      }
    }
    }
  }
}

lm_ledger <- do.call(rbind, lm_rows)
s33_write_ledger(lm_ledger, CSV_DIR, "lee_strazicich_lm_ledger.csv")

# ---------------------------------------------------------------------------
# 4. Concordance: LS endogenous dates vs Bai-Perron vs protocol candidates
# ---------------------------------------------------------------------------

BP_DATES_PATH <- s33_dir("S33A_BAI_PERRON", "csv", "bai_perron_break_dates.csv")
bp_dates <- if (file.exists(BP_DATES_PATH)) {
  utils::read.csv(BP_DATES_PATH, stringsAsFactors = FALSE)
} else {
  log_msg("WARNING: ", BP_DATES_PATH, " not found. Run US_S33A first; ",
          "concordance will record BP dates as unavailable.")
  NULL
}

nearest <- function(target, pool) {
  pool <- pool[is.finite(pool)]
  if (!length(pool)) return(c(value = NA_real_, distance = NA_real_))
  i <- which.min(abs(pool - target))
  c(value = pool[i], distance = abs(pool[i] - target))
}

conc_rows <- list()
for (i in seq_len(nrow(lm_ledger))) {
  row <- lm_ledger[i, ]
  if (is.na(row$ls_break_years)) next
  ls_years <- as.integer(strsplit(row$ls_break_years, ";", fixed = TRUE)[[1]])
  win <- S33_WINDOWS[[row$window]]

  bp_pool <- if (!is.null(bp_dates)) {
    bp_dates$break_year[bp_dates$spec == row$spec & bp_dates$window == row$window]
  } else numeric(0)

  for (k in seq_along(ls_years)) {
    nb_bp  <- nearest(ls_years[k], as.numeric(bp_pool))
    nb_pr  <- nearest(ls_years[k], as.numeric(win$protocol_dates))
    conc_rows[[length(conc_rows) + 1L]] <- data.frame(
      spec = row$spec, variable = row$variable, window = row$window,
      ls_model = row$ls_model, breaks = row$breaks,
      ls_break_number = k, ls_break_year = ls_years[k],
      nearest_bp_break = nb_bp[["value"]], bp_year_distance = nb_bp[["distance"]],
      concordant_with_bp_within_2yr = if (is.na(nb_bp[["distance"]])) NA else nb_bp[["distance"]] <= 2,
      nearest_protocol_date = nb_pr[["value"]], protocol_year_distance = nb_pr[["distance"]],
      concordant_with_protocol_within_2yr = if (is.na(nb_pr[["distance"]])) NA else nb_pr[["distance"]] <= 2,
      protocol_candidates = paste(win$protocol_dates, collapse = ";"),
      bp_dates_available = !is.null(bp_dates) && length(bp_pool) > 0,
      note = "LS dates are endogenous; they are compared with, never replaced by, BP or protocol dates",
      stringsAsFactors = FALSE)
  }
}
conc_ledger <- if (length(conc_rows)) do.call(rbind, conc_rows) else
  data.frame(spec = character(), variable = character(), window = character(),
             ls_break_year = integer())
s33_write_ledger(conc_ledger, CSV_DIR, "ls_bp_break_concordance.csv")

# ---------------------------------------------------------------------------
# 5. Integration-order verdict (S03 Sec.2C decision matrix)
# ---------------------------------------------------------------------------
# Adjudicated on the (levels, first-difference) PAIR rather than on levels alone -- see
# the third deviation note at the head of this file. Model C is the protocol model and
# decides; Model A is recorded but does not.
#
#   levels reject                      -> I0_trend_stationary_with_break. The series is
#       stationary around broken deterministics. It is not an I(1) cointegration
#       candidate, and forcing it into one would be a levels regression on a stationary
#       variable.
#
#   levels fail, differences reject    -> I1_with_break. The unit root survives in
#       levels and dies in first differences: exactly the S03 Sec.2B target, "eliminating
#       spurious I(2) classification". This is the S03 Sec.2C LEFT branch outcome --
#       construct D_t(T_B) and DT_t(T_B) and proceed.
#
#   levels fail, differences fail      -> persistent_I2_risk. The unit root survives
#       differencing under broken deterministics. S03 Sec.2C RIGHT branch: switch the
#       level specification to investment flows before estimating.
#
# Within each transform, a rejection at ANY break count counts: the null is a unit root
# and one valid rejection is evidence against it.

reject_any <- function(df) any(df$rejects_unit_root_5pct %in% TRUE)
best_row <- function(df) if (nrow(df) && any(is.finite(df$lm_statistic)))
  df[which.min(df$lm_statistic), ] else df[0, ]
pick <- function(r, col, default = NA) if (nrow(r)) r[[col]] else default

verdict_rows <- list()
for (sp in unique(lm_ledger$spec)) {
  for (v in unique(lm_ledger$variable[lm_ledger$spec == sp])) {
    for (w in unique(lm_ledger$window[lm_ledger$spec == sp & lm_ledger$variable == v])) {
      sub <- lm_ledger[lm_ledger$spec == sp & lm_ledger$variable == v &
                         lm_ledger$window == w, , drop = FALSE]
      pc   <- sub[sub$ls_model == "C", , drop = FALSE]
      comp <- sub[sub$ls_model == "A", , drop = FALSE]
      lev  <- pc[pc$transform == "levels", , drop = FALSE]
      dif  <- pc[pc$transform == "first_difference", , drop = FALSE]

      lev_rej <- reject_any(lev)
      dif_rej <- reject_any(dif)
      testable <- any(is.finite(lev$lm_statistic)) && any(is.finite(dif$lm_statistic))

      verdict <- if (!testable) "INDETERMINATE_TEST_FAILED" else
        if (lev_rej) "I0_trend_stationary_with_break" else
          if (dif_rej) "I1_with_break" else "persistent_I2_risk"

      disposition <- switch(verdict,
        I1_with_break = paste("S03 Sec.2C left branch: unit root survives in levels and is",
                              "rejected in first differences; spurious I(2) ruled out.",
                              "Construct D_t(T_B) and DT_t(T_B) and proceed to",
                              "break-interacted IM-OLS."),
        I0_trend_stationary_with_break = paste("Unit root rejected in LEVELS under broken",
                              "deterministics: series is stationary around breaks, not I(1).",
                              "Not an admissible cointegration regressor without redesign."),
        persistent_I2_risk = paste("S03 Sec.2C right branch: unit root rejected in neither",
                              "levels nor first differences; switch the level specification",
                              "to investment flows before estimating."),
        "no usable LM statistic in one or both transforms; window is not adjudicated")

      gate <- if (verdict == "I1_with_break") "PASS" else "BLOCK"

      bl <- best_row(lev); bd <- best_row(dif)

      verdict_rows[[length(verdict_rows) + 1L]] <- data.frame(
        spec = sp, variable = v, notation = sub$notation[1], role = sub$role[1],
        window = w, T_obs = pick(bl, "T_obs", NA_integer_),
        adjudicating_model = "C (intercept and trend break)",
        adjudication_basis = "levels x first-difference pair (see script header, deviation 3)",
        levels_min_lm = pick(bl, "lm_statistic", NA_real_),
        levels_crit_5 = pick(bl, "crit_5", NA_real_),
        levels_rejects_5pct = lev_rej,
        levels_breaks_at_min = pick(bl, "breaks", NA_integer_),
        levels_break_years_at_min = pick(bl, "ls_break_years", NA_character_),
        diff_min_lm = pick(bd, "lm_statistic", NA_real_),
        diff_crit_5 = pick(bd, "crit_5", NA_real_),
        diff_rejects_5pct = dif_rej,
        diff_breaks_at_min = pick(bd, "breaks", NA_integer_),
        diff_break_years_at_min = pick(bd, "ls_break_years", NA_character_),
        rejections_modelC_levels = paste0(sum(lev$rejects_unit_root_5pct %in% TRUE),
                                          "/", nrow(lev)),
        rejections_modelC_diffs = paste0(sum(dif$rejects_unit_root_5pct %in% TRUE),
                                         "/", nrow(dif)),
        rejections_modelA_all = paste0(sum(comp$rejects_unit_root_5pct %in% TRUE),
                                       "/", nrow(comp)),
        integration_verdict = verdict,
        s03_2c_disposition = disposition,
        step3_gate = gate,
        cval_sample_size_caveat = pick(bl, "cval_sample_size_caveat", NA_character_),
        date_mode = S33_LS_DATE_MODE,
        stringsAsFactors = FALSE)
    }
  }
}
verdict_ledger <- do.call(rbind, verdict_rows)
s33_write_ledger(verdict_ledger, CSV_DIR, "integration_order_verdict.csv")

# ---------------------------------------------------------------------------
# 6. Stage integrity
# ---------------------------------------------------------------------------

engine_files <- list.files(S33_LS_REPO, pattern = "\\.[Rr]$", full.names = FALSE)

integrity <- s33_integrity(
  checks = c(
    "mandated_engine_bound_not_reimplemented",
    "engine_signature_matches_pin",
    "protocol_model_C_run_for_every_target",
    "named_protocol_targets_covered",
    "levels_and_differences_both_tested",
    "trimming_from_protocol_windows",
    "critical_value_sample_size_caveat_recorded",
    "endogenous_date_deviation_declared",
    "concordance_ledger_written",
    "verdict_encodes_s03_2c_branches",
    "no_fixed_date_lm_substitute_computed",
    "outputs_confined_to_break_aware_tree"
  ),
  passed = c(
    identical(LS_FUN, "ur.ls") && dir.exists(S33_LS_REPO) &&
      "LeeStrazicichUnitRootTest.R" %in% engine_files,
    all(c("y", "model", "breaks", "lags", "method", "pn", "print.results") %in%
          names(formals(get(LS_FUN, envir = LS_ENV)))),
    all(vapply(split(lm_ledger, list(lm_ledger$spec, lm_ledger$variable,
                                     lm_ledger$window), drop = TRUE),
               function(g) "C" %in% g$ls_model, logical(1))),
    all(c("k_cap", "k_NRC", "kappa") %in% unique(lm_ledger$variable)),
    all(vapply(split(lm_ledger, list(lm_ledger$spec, lm_ledger$variable,
                                     lm_ledger$window), drop = TRUE),
               function(g) all(c("levels", "first_difference") %in% g$transform),
               logical(1))),
    all(vapply(unique(lm_ledger$window), function(w) {
      e <- unique(lm_ledger$trim_pn[lm_ledger$window == w])
      length(e) == 1L && isTRUE(all.equal(e, S33_WINDOWS[[w]]$epsilon))
    }, logical(1))),
    all(nzchar(lm_ledger$cval_sample_size_caveat)),
    all(lm_ledger$date_mode == "endogenous_search_with_bp_concordance"),
    nrow(conc_ledger) > 0,
    all(verdict_ledger$integration_verdict %in%
          c("I1_with_break", "I0_trend_stationary_with_break",
            "persistent_I2_risk", "INDETERMINATE_TEST_FAILED")),
    !exists("ls_stat") && !exists("ls_two_break_search"),
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
          fixed = TRUE)
  ),
  detail = c(
    paste0("bound ", LS_FUN, " from ", S33_LS_REPO, " (", attr(LS_ENV, "route"), ")"),
    paste("formals:", paste(names(formals(get(LS_FUN, envir = LS_ENV))), collapse = ", ")),
    paste0(sum(lm_ledger$ls_model == "C"), " Model C runs across ",
           length(unique(paste(lm_ledger$spec, lm_ledger$variable, lm_ledger$window))),
           " target-window cells"),
    paste("targets:", paste(sort(unique(lm_ledger$variable)), collapse = ", ")),
    paste("levels run as S01/S02 request; first differences added because levels alone",
          "cannot separate I(1) from I(2) (see script header, deviation 3)"),
    paste(vapply(unique(lm_ledger$window), function(w)
      sprintf("%s pn=%.2f", w, S33_WINDOWS[[w]]$epsilon), character(1)), collapse = "; "),
    sprintf("all critical values tabulated at T=%d; per-row actual T recorded",
            S33_LS_CVAL_SAMPLE_SIZE),
    paste("ur.ls() has no fixed-break-date argument;", S33_LS_DATE_MODE),
    paste0(nrow(conc_ledger), " LS break dates scored against BP and protocol candidates"),
    paste0(sum(verdict_ledger$integration_verdict == "I1_with_break"), " I(1)-with-break, ",
           sum(verdict_ledger$integration_verdict == "I0_trend_stationary_with_break"),
           " I(0)-with-break, ",
           sum(verdict_ledger$integration_verdict == "persistent_I2_risk"), " I(2)-risk, ",
           sum(verdict_ledger$integration_verdict == "INDETERMINATE_TEST_FAILED"),
           " indeterminate"),
    "no local minimum-LM implementation defined in this script (P05 acceptance criterion)",
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE)
  )
)

s33_write_ledger(integrity, CSV_DIR, "s33b_lee_strazicich_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33B")

log_msg("US_S33B complete. ", nrow(lm_ledger), " LM runs; ",
        sum(verdict_ledger$step3_gate == "PASS"), "/", nrow(verdict_ledger),
        " target-window cells pass the Step 3 gate.")
log_msg("Next: Rscript codes/US_S33C_break_interacted_imols_specA.R")
