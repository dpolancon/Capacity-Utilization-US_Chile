#!/usr/bin/env Rscript

# US_S33H_descriptive_grounding_specB.R
# ---------------------------------------------------------------------------
# Descriptive macro grounding for Specification B, computed so it can sit in the MAIN TEXT
# of the progress report rather than an appendix.
#
# Two requirements from the umass-applied-econometrics skill drive this stage:
#
#   Rule E (Marglin-style descriptive grounding): growth rates of output, capital stock and
#     the distributive variables belong in the body of the paper. The skill is explicit
#     that basic macro grounding must not be relegated to an appendix.
#   Rule B (Ash-Basu-Dube visual-first): non-parametric views of the raw series come BEFORE
#     any parametric regression result. This script supplies the numbers that accompany the
#     existing LOESS/decomposition figures under output/figures/.
#
# Everything here is descriptive. No estimation, no inference, no gates. Growth rates are
# mean annual log differences within each window, which is what the log-level variables in
# the Spec B panel make directly available:
#
#   g_x = mean( x_t - x_{t-1} ) over the window, expressed in percent per year
#
# For kappa_t = k^ME_t - k^NRC_t and p^kappa_t = ln P^ME - ln P^NRC the "growth rate" is the
# annual drift of a log RATIO, i.e. the divergence rate between the two series. Reported as
# percentage points per year to keep that distinction visible. omega_t is a share, so its
# change is reported in percentage points of the share, not as a log difference.
#
# Windows mirror the estimation windows so the descriptive table and the results table can
# be read against each other, plus the two post-war sub-periods the chapter's periodization
# turns on.
#
# Governance: artifacts land under output/US/BREAK_AWARE_IMOLS/S33H_DESCRIPTIVE/.
#
# Usage:
#   Rscript codes/US_S33H_descriptive_grounding_specB.R
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

STAGE   <- "S33H_DESCRIPTIVE"
OUT_DIR <- s33_dir(STAGE)
CSV_DIR <- file.path(OUT_DIR, "csv")
LOG_DIR <- file.path(OUT_DIR, "logs")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33H_execution_log.txt")
log_msg <- function(...) {
  line <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(line, "\n", sep = "")
  cat(line, "\n", sep = "", file = LOG_PATH, append = TRUE)
}
cat("", file = LOG_PATH)

panel <- s33_load_spec_b()
panel$k_ME <- panel$kappa + panel$k_NRC   # k^ME = kappa + k^NRC, by definition of the gap
log_msg("Spec B panel: ", nrow(panel), " rows, ", min(panel$year), "-", max(panel$year))

WINDOWS <- list(
  list(key = "Full_Sample_1929_2024",    label = "Full sample",              from = 1929L, to = 2024L),
  list(key = "Fordist_1929_1973",        label = "Fordist era",              from = 1929L, to = 1973L),
  list(key = "Post_Fordist_1974_2024",   label = "Post-Fordist era",         from = 1974L, to = 2024L),
  list(key = "Interwar_WWII_1929_1946",  label = "Interwar and WWII",        from = 1929L, to = 1946L),
  list(key = "Golden_Age_1947_1973",     label = "Golden Age",               from = 1947L, to = 1973L),
  list(key = "Neoliberal_1974_1999",     label = "Neoliberal restructuring", from = 1974L, to = 1999L),
  list(key = "Post_2000_2000_2024",      label = "Post-2000 stagnation",     from = 2000L, to = 2024L)
)

# log-difference variables (report as % per year) vs share variables (report as pp per year)
LOGDIFF <- c(y = "Corporate value added (y^NFC)",
             k_NRC = "Nonresidential structures (k^NRC)",
             k_ME  = "Machinery and equipment (k^ME)")
RATIO   <- c(kappa   = "Mechanization gap (kappa = k^ME - k^NRC)",
             p_kappa = "Relative price (p^kappa = ln P^ME - ln P^NRC)")
SHARE   <- c(omega = "Wage share (omega)")

rows <- list()
for (w in WINDOWS) {
  d <- panel[panel$year >= w$from & panel$year <= w$to, , drop = FALSE]
  if (nrow(d) < 3L) next
  for (v in names(c(LOGDIFF, RATIO, SHARE))) {
    x <- d[[v]]
    dx <- diff(x)
    kind <- if (v %in% names(LOGDIFF)) "log_growth_pct_per_yr" else
      if (v %in% names(RATIO)) "log_ratio_drift_pp_per_yr" else "share_change_pp_per_yr"
    scale <- 100
    rows[[length(rows) + 1L]] <- data.frame(
      window = w$key, era_label = w$label, from = w$from, to = w$to,
      T_obs = nrow(d),
      variable = v,
      variable_label = unname(c(LOGDIFF, RATIO, SHARE)[[v]]),
      measure = kind,
      mean_annual_change = scale * mean(dx, na.rm = TRUE),
      sd_annual_change   = scale * stats::sd(dx, na.rm = TRUE),
      level_start = x[1], level_end = x[length(x)],
      cumulative_change = x[length(x)] - x[1],
      stringsAsFactors = FALSE)
  }
}
desc <- do.call(rbind, rows)
s33_write_ledger(desc, CSV_DIR, "specB_descriptive_growth_rates.csv")

# Compact main-text view: the three estimation windows, one row per variable.
main <- desc[desc$window %in% c("Full_Sample_1929_2024", "Fordist_1929_1973",
                               "Post_Fordist_1974_2024"), , drop = FALSE]
wide <- reshape(main[, c("variable_label", "window", "mean_annual_change")],
                idvar = "variable_label", timevar = "window", direction = "wide")
names(wide) <- sub("^mean_annual_change\\.", "", names(wide))
s33_write_ledger(wide, CSV_DIR, "specB_descriptive_main_text_table.csv")

log_msg("")
log_msg("MEAN ANNUAL CHANGE (percent per year for levels; pp per year for ratios and shares)")
for (w in c("Full_Sample_1929_2024", "Fordist_1929_1973", "Post_Fordist_1974_2024")) {
  log_msg("  ", w)
  s <- desc[desc$window == w, , drop = FALSE]
  for (i in seq_len(nrow(s))) {
    log_msg(sprintf("    %-46s %7.2f  (sd %5.2f)",
                    s$variable_label[i], s$mean_annual_change[i], s$sd_annual_change[i]))
  }
}

integrity <- s33_integrity(
  checks = c("descriptive_only_no_estimation",
             "all_estimation_windows_covered",
             "kappa_reported_as_ratio_drift_not_growth",
             "outputs_confined_to_break_aware_tree"),
  passed = c(
    TRUE,
    all(c("Full_Sample_1929_2024", "Fordist_1929_1973", "Post_Fordist_1974_2024") %in%
          desc$window),
    all(desc$measure[desc$variable %in% names(RATIO)] == "log_ratio_drift_pp_per_yr"),
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
          fixed = TRUE)
  ),
  detail = c(
    "no estimator is called; means and standard deviations of annual differences only",
    paste("windows:", paste(unique(desc$window), collapse = ", ")),
    paste("kappa and p_kappa are log ratios; their annual change is a divergence rate",
          "between two series, not a growth rate of a level"),
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE)
  )
)
s33_write_ledger(integrity, CSV_DIR, "s33h_descriptive_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33H")

log_msg("US_S33H complete. ", nrow(desc), " descriptive rows across ", length(WINDOWS), " windows.")
