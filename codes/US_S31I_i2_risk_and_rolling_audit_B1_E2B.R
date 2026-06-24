###############################################################################
# US_S31I_i2_risk_and_rolling_audit_B1_E2B.R
# Chapter 2 - US S31I I2-risk and rolling integration-order audit
#
# Role:
#   Audit existing S31I I2-risk classifications and add bounded rolling
#   integration-order window-stability diagnostics for human adjudication.
#
# Guardrails:
#   - Reads existing S31I outputs; does not overwrite original S31I CSV/MD files.
#   - Does not change S31 or S32.
#   - Does not run S40.
#   - Does not reconstruct theta, productive capacity, or utilization.
#   - Does not run model-choice estimation.
###############################################################################

suppressPackageStartupMessages({
  library(urca)
})

# ---- 0. Paths and constants --------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")
RUN_TAG <- "S31I_I2_RISK_AND_ROLLING_AUDIT_B1_E2B"
S31I_TAG <- "S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B"

panel_path <- file.path(REPO, "data/processed/US/us_s20_admissibility_panel.csv")
s31i_dir <- file.path(REPO, "output/US", S31I_TAG)
csv_dir <- file.path(s31i_dir, "csv")
md_dir <- file.path(s31i_dir, "md")
logs_dir <- file.path(s31i_dir, "logs")
audit_dir <- file.path(s31i_dir, "audit")

tests_path <- file.path(csv_dir, "S31I_integration_order_tests_long.csv")
classification_path <- file.path(csv_dir, "S31I_integration_order_classification.csv")
ledger_path <- file.path(csv_dir, "S31I_variable_construction_ledger.csv")
report_path <- file.path(md_dir, "S31I_INTEGRATION_ORDER_PRECHECK_B1_E2B.md")
validation_path <- file.path(md_dir, "S31I_VALIDATION_REPORT.md")

s31_dirs <- c(
  file.path(REPO, "output/US/S31_estimation_tables_tex"),
  file.path(REPO, "output/US/S31_model_choice_vif_screen")
)
s32_dir <- file.path(REPO, "output/US/S32_B1_E2B_MODEL_CHOICE_REVIEW")
s40_dir <- file.path(REPO, "output/US/S40")

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
i2_log_path <- file.path(logs_dir, "S31I_i2_risk_audit_log.txt")
rolling_log_path <- file.path(logs_dir, "S31I_rolling_integration_order_audit_log.txt")
writeLines(paste0(RUN_TAG, " Phase A started: ", RUN_TIMESTAMP), i2_log_path, useBytes = TRUE)
writeLines(paste0(RUN_TAG, " Phase B started: ", RUN_TIMESTAMP), rolling_log_path, useBytes = TRUE)

target_variables <- c(
  "k_t", "k_NRC_t", "k_ME_t", "m_ME_NRC_t",
  "omega_k_t", "omega_m_ME_NRC_t",
  "y_t", "omega_t", "pK_relative_ME_NRC"
)
capital_focus <- c("k_t", "k_NRC_t", "k_ME_t", "m_ME_NRC_t")

# ---- 1. Helpers --------------------------------------------------------------
log_i2 <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste(..., collapse = ""))
  cat(msg, "\n")
  cat(msg, "\n", file = i2_log_path, append = TRUE)
}

log_roll <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste(..., collapse = ""))
  cat(msg, "\n")
  cat(msg, "\n", file = rolling_log_path, append = TRUE)
}

read_csv_base <- function(path, check_names = TRUE) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = check_names)
}

write_csv_base <- function(df, path) {
  utils::write.csv(df, path, row.names = FALSE, na = "")
}

require_file <- function(path) {
  if (!file.exists(path)) stop("Required file not found: ", path, call. = FALSE)
}

as_num <- function(x) suppressWarnings(as.numeric(x))

finite_or_na <- function(x) {
  x <- as_num(x)
  x[!is.finite(x)] <- NA_real_
  x
}

collapse_nonempty <- function(x, sep = " | ") {
  x <- unique(trimws(as.character(x)))
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x) == 0L) return("")
  paste(x, collapse = sep)
}

format_num <- function(x, digits = 3L) {
  x <- as_num(x)
  if (!is.finite(x)) return("")
  formatC(x, format = "f", digits = digits)
}

md_escape_pipe <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  gsub("\\|", "\\\\|", x)
}

md_table <- function(df, columns, max_rows = 40L, digits = 3L) {
  show <- df[, columns, drop = FALSE]
  if (nrow(show) > max_rows) show <- show[seq_len(max_rows), , drop = FALSE]
  if (nrow(show) == 0L) return(character(0))
  for (nm in names(show)) {
    if (is.numeric(show[[nm]])) {
      show[[nm]] <- vapply(show[[nm]], format_num, character(1L), digits = digits)
    }
    show[[nm]] <- md_escape_pipe(show[[nm]])
  }
  c(
    paste0("| ", paste(names(show), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(show)), collapse = "|"), "|"),
    apply(show, 1L, function(z) paste0("| ", paste(z, collapse = " | "), " |"))
  )
}

snapshot_files <- function(paths) {
  files <- unlist(lapply(paths[file.exists(paths)], function(path) {
    list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
  }), use.names = FALSE)
  if (length(files) == 0L) {
    return(data.frame(path = character(0), size = numeric(0), mtime = as.POSIXct(character(0))))
  }
  info <- file.info(files)
  data.frame(
    path = normalizePath(files, winslash = "/", mustWork = FALSE),
    size = as.numeric(info$size),
    mtime = as.POSIXct(info$mtime),
    stringsAsFactors = FALSE
  )
}

same_snapshot <- function(before, after) {
  before <- before[order(before$path), , drop = FALSE]
  after <- after[order(after$path), , drop = FALSE]
  if (!identical(before$path, after$path)) return(FALSE)
  if (!identical(before$size, after$size)) return(FALSE)
  identical(as.numeric(before$mtime), as.numeric(after$mtime))
}

critical_read <- function(row) {
  if (nrow(row) == 0L) return("not_tested")
  if (nzchar(row$error_message[1L])) return(row$error_message[1L])
  if (row$test_name[1L] == "KPSS") {
    return(ifelse(as.logical(row$reject_at_5pct[1L]), "reject_stationarity_5pct", "fail_to_reject_stationarity_5pct"))
  }
  ifelse(as.logical(row$reject_at_5pct[1L]), "reject_unit_root_5pct", "fail_to_reject_unit_root_5pct")
}

primary_det_from_ledger <- function(variable_id, ledger) {
  row <- ledger[ledger$variable_id == variable_id, , drop = FALSE]
  family <- if (nrow(row) == 0L) "" else row$deterministic_family[1L]
  if (family == "trend_family") return("drift_trend")
  "drift"
}

sensitivity_det_from_ledger <- function(variable_id, ledger) {
  row <- ledger[ledger$variable_id == variable_id, , drop = FALSE]
  family <- if (nrow(row) == 0L) "" else row$deterministic_family[1L]
  if (family == "trend_family") return("drift")
  "drift_trend"
}

is_unsupported_error <- function(x) {
  grepl("does not support deterministic_spec|should be one of|must be NULL", x)
}

bool5 <- function(row) {
  if (nrow(row) == 0L || nzchar(row$error_message[1L])) return(NA)
  as.logical(row$reject_at_5pct[1L])
}

pick_test <- function(tests, variable_id, window_id, transform, test_name, deterministic_spec) {
  tests[
    tests$variable_id == variable_id &
      tests$window_id == window_id &
      tests$transform == transform &
      tests$test_name == test_name &
      tests$deterministic_spec == deterministic_spec,
    ,
    drop = FALSE
  ]
}

corrected_core_class <- function(tests, variable_id, window_id, level_spec) {
  adf_l <- bool5(pick_test(tests, variable_id, window_id, "level", "ADF", level_spec))
  pp_l <- bool5(pick_test(tests, variable_id, window_id, "level", "Phillips-Perron", level_spec))
  kpss_l <- bool5(pick_test(tests, variable_id, window_id, "level", "KPSS", level_spec))
  adf_d <- bool5(pick_test(tests, variable_id, window_id, "first_difference", "ADF", "drift"))
  pp_d <- bool5(pick_test(tests, variable_id, window_id, "first_difference", "Phillips-Perron", "drift"))
  kpss_d <- bool5(pick_test(tests, variable_id, window_id, "first_difference", "KPSS", "drift"))

  if (all(is.na(c(adf_l, pp_l, kpss_l, adf_d, pp_d, kpss_d)))) return("test_failed")

  diff_ur_available <- sum(!is.na(c(adf_d, pp_d)))
  diff_ur_rejects <- sum(c(adf_d, pp_d) == TRUE, na.rm = TRUE)
  diff_stationarity_reject <- isTRUE(kpss_d)
  level_ur_rejects <- sum(c(adf_l, pp_l) == TRUE, na.rm = TRUE)
  level_stationarity_reject <- isTRUE(kpss_l)

  if (diff_ur_available == 0L && is.na(kpss_d)) return("test_failed")
  if ((diff_ur_available > 0L && diff_ur_rejects == 0L) || diff_stationarity_reject) return("I2_risk")
  if (level_ur_rejects >= 1L && !level_stationarity_reject) return("I0_preferred")
  if (level_ur_rejects == 0L && level_stationarity_reject && diff_ur_rejects >= 1L && !diff_stationarity_reject) return("I1_preferred")
  "ambiguous_hold"
}

corrected_class <- function(tests, variable_id, window_id, ledger) {
  primary <- primary_det_from_ledger(variable_id, ledger)
  sensitivity <- sensitivity_det_from_ledger(variable_id, ledger)
  c1 <- corrected_core_class(tests, variable_id, window_id, primary)
  c2 <- corrected_core_class(tests, variable_id, window_id, sensitivity)
  if (c1 != c2 && c1 %in% c("I1_preferred", "I0_preferred", "I2_risk", "ambiguous_hold") &&
      c2 %in% c("I1_preferred", "I0_preferred", "I2_risk", "ambiguous_hold")) {
    return("deterministic_sensitive")
  }
  c1
}

det_to_urdf_type <- function(spec) {
  if (spec == "drift") return("drift")
  if (spec == "drift_trend") return("trend")
  if (spec == "none") return("none")
  NA_character_
}

det_to_upp_model <- function(spec) {
  if (spec == "drift") return("constant")
  if (spec == "drift_trend") return("trend")
  NA_character_
}

det_to_kpss_type <- function(spec) {
  if (spec == "drift") return("mu")
  if (spec == "drift_trend") return("tau")
  NA_character_
}

critical_values <- function(cval) {
  vals <- as_num(cval)
  names_lower <- tolower(names(cval))
  if (is.null(names_lower) || all(!nzchar(names_lower))) {
    names_lower <- tolower(colnames(as.matrix(cval)))
  }
  c1 <- vals[grep("1pct|1%", names_lower)[1L]]
  c5 <- vals[grep("5pct|5%", names_lower)[1L]]
  c10 <- vals[grep("10pct|10%", names_lower)[1L]]
  if (!is.finite(c1) && length(vals) >= 1L) c1 <- vals[1L]
  if (!is.finite(c5) && length(vals) >= 2L) c5 <- vals[2L]
  if (!is.finite(c10) && length(vals) >= 3L) c10 <- vals[3L]
  c(c1 = c1, c5 = c5, c10 = c10)
}

reject_from_stat <- function(test_name, stat, c1, c5, c10) {
  stat <- as_num(stat)
  c1 <- as_num(c1)
  c5 <- as_num(c5)
  c10 <- as_num(c10)
  if (!is.finite(stat)) return(c(r10 = NA, r5 = NA, r1 = NA))
  if (test_name == "KPSS") {
    return(c(
      r10 = is.finite(c10) && stat >= c10,
      r5 = is.finite(c5) && stat >= c5,
      r1 = is.finite(c1) && stat >= c1
    ))
  }
  c(
    r10 = is.finite(c10) && stat <= c10,
    r5 = is.finite(c5) && stat <= c5,
    r1 = is.finite(c1) && stat <= c1
  )
}

rolling_test_read <- function(test_name, reject5) {
  if (is.na(reject5)) return("not_tested")
  if (test_name == "KPSS") {
    return(ifelse(reject5, "reject_stationarity_5pct", "fail_to_reject_stationarity_5pct"))
  }
  ifelse(reject5, "reject_unit_root_5pct", "fail_to_reject_unit_root_5pct")
}

run_adf_simple <- function(x, det) {
  fit <- tryCatch(urca::ur.df(x, type = det_to_urdf_type(det), selectlags = "AIC"), error = function(e) e)
  if (inherits(fit, "error")) return(list(ok = FALSE, read = "test_failed", error = fit$message, reject = NA))
  stat <- as_num(fit@teststat[1L, 1L])
  cv <- critical_values(fit@cval[1L, ])
  rej <- reject_from_stat("ADF", stat, cv["c1"], cv["c5"], cv["c10"])
  list(ok = TRUE, read = rolling_test_read("ADF", rej["r5"]), error = "", reject = as.logical(rej["r5"]))
}

run_kpss_simple <- function(x, det) {
  fit <- tryCatch(urca::ur.kpss(x, type = det_to_kpss_type(det), lags = "short"), error = function(e) e)
  if (inherits(fit, "error")) return(list(ok = FALSE, read = "test_failed", error = fit$message, reject = NA))
  stat <- as_num(fit@teststat[1L])
  cv <- critical_values(fit@cval[1L, ])
  rej <- reject_from_stat("KPSS", stat, cv["c1"], cv["c5"], cv["c10"])
  list(ok = TRUE, read = rolling_test_read("KPSS", rej["r5"]), error = "", reject = as.logical(rej["r5"]))
}

run_pp_simple <- function(x, det) {
  fit <- tryCatch(urca::ur.pp(x, type = "Z-tau", model = det_to_upp_model(det), lags = "short"), error = function(e) e)
  if (inherits(fit, "error")) return(list(ok = FALSE, read = "test_failed", error = fit$message, reject = NA))
  stat <- as_num(fit@teststat[1L])
  cv <- critical_values(fit@cval[1L, ])
  rej <- reject_from_stat("Phillips-Perron", stat, cv["c1"], cv["c5"], cv["c10"])
  list(ok = TRUE, read = rolling_test_read("Phillips-Perron", rej["r5"]), error = "", reject = as.logical(rej["r5"]))
}

rolling_primary_det <- function(variable_id) {
  if (variable_id %in% c("y_t", "k_t", "k_NRC_t", "k_ME_t")) return("drift_trend")
  "drift"
}

rolling_classify <- function(level_adf, level_kpss, diff_adf, diff_kpss, level_pp, diff_pp, failed_count) {
  if (failed_count > 0L && is.na(diff_adf$reject) && is.na(diff_kpss$reject)) return("test_failed")
  diff_ur_rejects <- sum(c(diff_adf$reject, diff_pp$reject) == TRUE, na.rm = TRUE)
  diff_ur_available <- sum(!is.na(c(diff_adf$reject, diff_pp$reject)))
  level_ur_rejects <- sum(c(level_adf$reject, level_pp$reject) == TRUE, na.rm = TRUE)
  level_stationarity_reject <- isTRUE(level_kpss$reject)
  diff_stationarity_reject <- isTRUE(diff_kpss$reject)

  if ((diff_ur_available > 0L && diff_ur_rejects == 0L) || diff_stationarity_reject) return("I2_risk")
  if (level_ur_rejects >= 1L && !level_stationarity_reject) return("I0_preferred")
  if (level_ur_rejects == 0L && level_stationarity_reject && diff_ur_rejects >= 1L && !diff_stationarity_reject) return("I1_preferred")
  "mixed_test_evidence"
}

series_for <- function(variable_id, df) {
  switch(variable_id,
    y_t = df$y_t,
    k_t = df$k_t,
    omega_t = df$omega_t,
    omega_k_t = df$omega_k_t,
    k_NRC_t = df$k_NRC_t,
    k_ME_t = df$k_ME_t,
    m_ME_NRC_t = df$m_ME_NRC_t,
    omega_m_ME_NRC_t = df$omega_m_ME_NRC_t,
    pK_relative_ME_NRC = df$pK_relative_ME_NRC,
    rep(NA_real_, nrow(df))
  )
}

# ---- 2. Existing inputs ------------------------------------------------------
for (path in c(panel_path, tests_path, classification_path, ledger_path, report_path, validation_path)) {
  require_file(path)
}

original_snapshot <- snapshot_files(c(tests_path, classification_path, ledger_path, report_path, validation_path))
s31_before <- snapshot_files(s31_dirs)
s32_before <- snapshot_files(s32_dir)

tests <- read_csv_base(tests_path)
classification <- read_csv_base(classification_path)
ledger <- read_csv_base(ledger_path)
panel <- read_csv_base(panel_path, check_names = FALSE)

log_i2("Read existing S31I outputs.")

targets_present <- target_variables[target_variables %in% ledger$variable_id]
missing_targets <- setdiff(target_variables, targets_present)
if (length(missing_targets) > 0L) {
  log_i2("Missing target variables in ledger: ", paste(missing_targets, collapse = ", "))
}

# ---- 3. Phase A: I2-risk audit ----------------------------------------------
target_class <- classification[classification$variable_id %in% targets_present, , drop = FALSE]
target_tests <- tests[tests$variable_id %in% targets_present, , drop = FALSE]

trace <- target_tests
trace$run_tag <- RUN_TAG
trace$included_in_original_classification <- FALSE
trace$included_in_original_classification[
  trace$transform == "first_difference" &
    trace$test_name %in% c("ADF", "Phillips-Perron", "KPSS") &
    trace$deterministic_spec == "drift"
] <- TRUE
for (i in seq_len(nrow(trace))) {
  primary <- primary_det_from_ledger(trace$variable_id[i], ledger)
  if (trace$transform[i] == "level" &&
      trace$test_name[i] %in% c("ADF", "Phillips-Perron", "KPSS") &&
      trace$deterministic_spec[i] == primary) {
    trace$included_in_original_classification[i] <- TRUE
  }
}
trace$included_in_audit_read <- trace$included_in_original_classification & !nzchar(trace$error_message)
trace$trace_read <- trace$test_result_read
trace$notes <- ""
trace$notes[nzchar(trace$error_message) & is_unsupported_error(trace$error_message)] <- "unsupported deterministic specification; excluded from audit evidence"
trace$notes[nzchar(trace$error_message) & !is_unsupported_error(trace$error_message)] <- "failed or skipped test row; excluded from audit evidence"
trace <- trace[, c(
  "run_tag", "variable_id", "window_id", "transform", "test_name", "deterministic_spec",
  "n_obs", "test_null", "test_statistic", "p_value", "critical_1pct", "critical_5pct",
  "critical_10pct", "reject_at_10pct", "reject_at_5pct", "reject_at_1pct",
  "error_message", "included_in_original_classification", "included_in_audit_read",
  "trace_read", "notes"
)]
write_csv_base(trace, file.path(csv_dir, "S31I_i2_risk_test_trace.csv"))

audit_rows <- list()
idx <- 1L
for (i in seq_len(nrow(target_class))) {
  row <- target_class[i, ]
  vid <- row$variable_id
  wid <- row$window_id
  primary <- primary_det_from_ledger(vid, ledger)
  sensitivity <- sensitivity_det_from_ledger(vid, ledger)
  vtests <- tests[tests$variable_id == vid & tests$window_id == wid, , drop = FALSE]

  level_primary <- vtests[vtests$transform == "level" & vtests$deterministic_spec == primary &
    vtests$test_name %in% c("ADF", "Phillips-Perron", "KPSS"), , drop = FALSE]
  level_sensitivity <- vtests[vtests$transform == "level" & vtests$deterministic_spec == sensitivity &
    vtests$test_name %in% c("ADF", "Phillips-Perron", "KPSS"), , drop = FALSE]

  adf_d <- pick_test(tests, vid, wid, "first_difference", "ADF", "drift")
  pp_d <- pick_test(tests, vid, wid, "first_difference", "Phillips-Perron", "drift")
  kpss_d <- pick_test(tests, vid, wid, "first_difference", "KPSS", "drift")

  adf_rej <- bool5(adf_d)
  pp_rej <- bool5(pp_d)
  kpss_rej <- bool5(kpss_d)
  support_stationarity <- sum(c(adf_rej, pp_rej) == TRUE, na.rm = TRUE) + sum(kpss_rej == FALSE, na.rm = TRUE)
  support_unit_root <- sum(c(adf_rej, pp_rej) == FALSE, na.rm = TRUE) + sum(kpss_rej == TRUE, na.rm = TRUE)

  failed_tests <- vtests[nzchar(vtests$error_message), , drop = FALSE]
  unsupported <- failed_tests[is_unsupported_error(failed_tests$error_message), , drop = FALSE]
  skipped <- failed_tests[grepl("insufficient observations|not_run|source variable missing", failed_tests$error_message), , drop = FALSE]
  primary_failed <- vtests[vtests$included_in_original_classification %in% TRUE & nzchar(vtests$error_message), , drop = FALSE]
  corrected <- corrected_class(tests, vid, wid, ledger)
  short_window <- as_num(row$n_obs) < 30

  audit_read <- "needs_manual_review"
  if (row$classification != "I2_risk") {
    audit_read <- "not_I2_risk"
  } else if (nrow(primary_failed) > 0L && corrected != "I2_risk") {
    audit_read <- "likely_rule_artifact"
  } else if (as.logical(row$deterministic_sensitivity)) {
    audit_read <- "deterministic_sensitivity"
  } else if (short_window) {
    audit_read <- "short_window_fragility"
  } else if (support_unit_root >= 2L) {
    audit_read <- "genuine_I2_risk"
  } else if (support_stationarity > 0L && support_unit_root > 0L) {
    audit_read <- "mixed_test_evidence"
  }

  recommended <- switch(audit_read,
    genuine_I2_risk = "Treat as substantive I2-risk until redesigned or externally adjudicated.",
    likely_rule_artifact = "Do not read original I2-risk mechanically; inspect corrected classification logic.",
    short_window_fragility = "Hold for review; result is under the preferred 30-observation threshold.",
    deterministic_sensitivity = "Carry deterministic-specification caveat into S32 human review.",
    mixed_test_evidence = "Hold for review because ADF/PP/KPSS evidence conflicts.",
    not_I2_risk = "No I2-specific action; retain original non-I2 caveat if any.",
    "Manual review required."
  )

  audit_rows[[idx]] <- data.frame(
    run_tag = RUN_TAG,
    variable_id = vid,
    variable_label = row$variable_label,
    window_id = wid,
    window_start = row$window_start,
    window_end = row$window_end,
    n_obs = row$n_obs,
    original_classification = row$classification,
    original_confidence = row$confidence,
    original_s32_implication = row$s32_implication,
    is_i2_risk = row$classification == "I2_risk",
    level_primary_read = collapse_nonempty(level_primary$test_result_read),
    level_sensitivity_read = collapse_nonempty(level_sensitivity$test_result_read),
    diff_adf_primary_stat = ifelse(nrow(adf_d) > 0L, adf_d$test_statistic[1L], NA),
    diff_adf_primary_p_or_cv_read = critical_read(adf_d),
    diff_adf_primary_reject_5pct = adf_rej,
    diff_pp_primary_stat = ifelse(nrow(pp_d) > 0L, pp_d$test_statistic[1L], NA),
    diff_pp_primary_p_or_cv_read = critical_read(pp_d),
    diff_pp_primary_reject_5pct = pp_rej,
    diff_kpss_primary_stat = ifelse(nrow(kpss_d) > 0L, kpss_d$test_statistic[1L], NA),
    diff_kpss_primary_p_or_cv_read = critical_read(kpss_d),
    diff_kpss_primary_reject_5pct = kpss_rej,
    diff_tests_support_stationarity = support_stationarity,
    diff_tests_support_unit_root = support_unit_root,
    failed_tests_count = nrow(failed_tests),
    skipped_tests_count = nrow(skipped),
    unsupported_spec_count = nrow(unsupported),
    deterministic_sensitivity = row$deterministic_sensitivity,
    short_window_flag = short_window,
    audit_read = audit_read,
    recommended_interpretation = recommended,
    notes = paste0("corrected_class_excluding_failed_rows=", corrected),
    stringsAsFactors = FALSE
  )
  idx <- idx + 1L
}
i2_audit <- do.call(rbind, audit_rows)
write_csv_base(i2_audit, file.path(csv_dir, "S31I_i2_risk_audit_capital_variables.csv"))

i2_only <- i2_audit[i2_audit$is_i2_risk, , drop = FALSE]
likely_artifact <- i2_only[i2_only$audit_read == "likely_rule_artifact", , drop = FALSE]
primary_failed_target <- trace[
  trace$included_in_original_classification & nzchar(trace$error_message),
  ,
  drop = FALSE
]

rule_diagnostics <- data.frame(
  run_tag = RUN_TAG,
  diagnostic_id = c(
    "D01_existing_outputs_read",
    "D02_unsupported_none_rows",
    "D03_primary_failed_rows",
    "D04_i2_corrected_changes",
    "D05_original_code_location"
  ),
  diagnostic_question = c(
    "Were existing S31I outputs readable?",
    "Do unsupported first-difference none rows exist?",
    "Were failed/skipped rows included in target primary classification evidence?",
    "Would excluding failed/skipped primary rows change target I2-risk calls?",
    "Where is the original classification rule located?"
  ),
  result = c(
    "yes",
    ifelse(any(is_unsupported_error(trace$error_message)), "yes", "no"),
    ifelse(nrow(primary_failed_target) > 0L, "yes", "no"),
    ifelse(nrow(likely_artifact) > 0L, "yes", "no"),
    "codes/US_S31I_integration_order_precheck_B1_E2B.R:435-480"
  ),
  evidence = c(
    paste(c(tests_path, classification_path, ledger_path), collapse = " | "),
    paste(unique(trace$error_message[is_unsupported_error(trace$error_message)]), collapse = " | "),
    ifelse(nrow(primary_failed_target) > 0L, paste(unique(primary_failed_target$variable_id), collapse = " | "), "No target primary first-difference drift rows failed."),
    ifelse(nrow(likely_artifact) > 0L, paste(unique(paste(likely_artifact$variable_id, likely_artifact$window_id, sep = "/")), collapse = " | "), "No target I2-risk calls changed under corrected failed-row exclusion."),
    "decision() excludes error rows as NA; core_classification() sums TRUE rejections with na.rm=TRUE and assigns I2_risk when diff_ur_rejects == 0L or diff KPSS rejects."
  ),
  affected_variables = c(
    paste(targets_present, collapse = " | "),
    paste(unique(trace$variable_id[is_unsupported_error(trace$error_message)]), collapse = " | "),
    ifelse(nrow(primary_failed_target) > 0L, paste(unique(primary_failed_target$variable_id), collapse = " | "), ""),
    ifelse(nrow(likely_artifact) > 0L, paste(unique(likely_artifact$variable_id), collapse = " | "), ""),
    paste(targets_present, collapse = " | ")
  ),
  affected_windows = c(
    paste(unique(classification$window_id), collapse = " | "),
    paste(unique(trace$window_id[is_unsupported_error(trace$error_message)]), collapse = " | "),
    ifelse(nrow(primary_failed_target) > 0L, paste(unique(primary_failed_target$window_id), collapse = " | "), ""),
    ifelse(nrow(likely_artifact) > 0L, paste(unique(likely_artifact$window_id), collapse = " | "), ""),
    paste(unique(classification$window_id), collapse = " | ")
  ),
  severity = c("none", "low", ifelse(nrow(primary_failed_target) > 0L, "medium", "none"), ifelse(nrow(likely_artifact) > 0L, "high", "none"), "low"),
  recommended_action = c(
    "Proceed to audit.",
    "Keep unsupported none rows visible; do not count them as evidence.",
    ifelse(nrow(primary_failed_target) > 0L, "Inspect corrected classification table before using affected calls.", "No corrected target classification output required."),
    ifelse(nrow(likely_artifact) > 0L, "Write corrected classification output with suffix _corrected.", "Do not patch original S31I outputs."),
    "Document the rule and keep failed/skipped rows excluded from audit read."
  ),
  stringsAsFactors = FALSE
)
write_csv_base(rule_diagnostics, file.path(csv_dir, "S31I_i2_risk_rule_diagnostics.csv"))

if (nrow(likely_artifact) > 0L) {
  corrected_out <- classification
  for (i in seq_len(nrow(corrected_out))) {
    if (corrected_out$variable_id[i] %in% targets_present) {
      corrected_out$classification[i] <- corrected_class(tests, corrected_out$variable_id[i], corrected_out$window_id[i], ledger)
    }
  }
  corrected_out$run_tag <- RUN_TAG
  write_csv_base(corrected_out, file.path(csv_dir, "S31I_integration_order_classification_corrected.csv"))
}

i2_report <- c(
  "# S31I I2-Risk Audit",
  "",
  "## 1. Executive read",
  paste0("Run tag: `", RUN_TAG, "`."),
  paste0("Target I2-risk calls audited: ", nrow(i2_only), "."),
  paste0("Audit labels among I2-risk calls: ", paste(names(table(i2_only$audit_read)), as.integer(table(i2_only$audit_read)), sep = "=", collapse = "; "), "."),
  if (nrow(likely_artifact) > 0L) "## Classification rule bug found" else "## Classification rule bug check",
  if (nrow(likely_artifact) > 0L) {
    c(
      "A target classification-rule bug was found.",
      "Exact code location: `codes/US_S31I_integration_order_precheck_B1_E2B.R:435-480`.",
      md_table(likely_artifact, c("variable_id", "window_id", "original_classification", "audit_read", "notes"), max_rows = 80L),
      "Recommended patch: preserve original outputs and use the `_corrected` classification table for human review."
    )
  } else {
    c(
      "No target I2-risk classification was driven by failed or unsupported primary first-difference rows.",
      "Exact code location inspected: `codes/US_S31I_integration_order_precheck_B1_E2B.R:435-480`.",
      "Unsupported `none` rows exist for PP/KPSS/ERS, but they are outside the original primary classification evidence for the target I2-risk calls.",
      "No corrected classification table was necessary."
    )
  },
  "",
  "## 2. Why the audit was run",
  "The original S31I pass produced I2-risk, deterministic-sensitive, and fragile classifications. This audit separates genuine first-difference nonstationarity from deterministic sensitivity, short-window weakness, failed-test handling, and mixed ADF/PP/KPSS evidence.",
  "",
  "## 3. Target variables and original S31I windows",
  md_table(i2_audit, c("variable_id", "window_id", "n_obs", "original_classification", "audit_read", "recommended_interpretation"), max_rows = 80L),
  "",
  "## 4. Explanation of each I2-risk classification",
  md_table(i2_only, c("variable_id", "window_id", "diff_tests_support_stationarity", "diff_tests_support_unit_root", "failed_tests_count", "unsupported_spec_count", "audit_read", "notes"), max_rows = 80L),
  "",
  "## 5. Test-trace summary for capital variables",
  md_table(i2_audit[i2_audit$variable_id %in% capital_focus, ],
    c("variable_id", "window_id", "diff_adf_primary_p_or_cv_read", "diff_pp_primary_p_or_cv_read", "diff_kpss_primary_p_or_cv_read", "audit_read"),
    max_rows = 80L
  ),
  "",
  "## 6. Check on failed/skipped test handling",
  md_table(rule_diagnostics, c("diagnostic_id", "result", "severity", "recommended_action"), max_rows = 20L),
  "",
  "## 7. Deterministic-sensitivity assessment",
  md_table(i2_audit[i2_audit$deterministic_sensitivity %in% TRUE, ],
    c("variable_id", "window_id", "original_classification", "audit_read", "notes"), max_rows = 80L
  ),
  "",
  "## 8. Short-window fragility assessment",
  md_table(i2_audit[i2_audit$short_window_flag %in% TRUE, ],
    c("variable_id", "window_id", "n_obs", "original_classification", "audit_read"), max_rows = 80L
  ),
  "",
  "## 9. Implications for B1",
  "The B1 question is whether k_t and omega_k_t can be treated as admissible long-run regressors alongside y_t. If k_t is genuinely I2-risk, B1 cannot be read as a clean I(1) cointegrating-regression design without redesign. If the I2-risk call is an artifact of deterministic sensitivity or failed-test handling, B1 remains admissible for review but must carry the S31I caveat.",
  "",
  "## 10. Implications for E2B",
  "The E2B question is whether k_NRC_t, m_ME_NRC_t, and omega_m_ME_NRC_t can support the NRC-envelope / distribution-conditioned mechanization-bias interpretation. If k_NRC_t and m_ME_NRC_t are genuinely I2-risk, E2B cannot be promoted mechanically from S32 coefficient results. If the I2-risk call is mostly rule-driven or short-window fragile, E2B remains a review candidate but must be documented as integration-order sensitive.",
  "",
  "## 11. Recommendation on corrected reclassification",
  if (nrow(likely_artifact) > 0L) "A corrected classification table was written because target I2-risk calls changed after failed/skipped primary rows were excluded." else "No corrected reclassification table was necessary for the target variables.",
  "",
  "## 12. Guardrail statement",
  "S31, S32, and S40 remain untouched. This audit does not choose a model and does not reinterpret integration-order tests as cointegration evidence."
)
writeLines(i2_report, file.path(md_dir, "S31I_I2_RISK_AUDIT.md"), useBytes = TRUE)

i2_validation <- data.frame(
  run_tag = RUN_TAG,
  check = c(
    "Existing S31I outputs found",
    "Classification CSV read",
    "Tests-long CSV read",
    "Construction ledger read",
    "All target variables audited",
    "All original S31I windows attempted",
    "Failed/skipped handling inspected",
    "Rule diagnostics written"
  ),
  pass = c(
    all(file.exists(c(tests_path, classification_path, ledger_path, report_path, validation_path))),
    nrow(classification) > 0L,
    nrow(tests) > 0L,
    nrow(ledger) > 0L,
    all(targets_present %in% unique(i2_audit$variable_id)),
    all(unique(classification$window_id) %in% unique(i2_audit$window_id)),
    nrow(rule_diagnostics) > 0L,
    file.exists(file.path(csv_dir, "S31I_i2_risk_rule_diagnostics.csv"))
  ),
  evidence = c(
    s31i_dir,
    classification_path,
    tests_path,
    ledger_path,
    paste(targets_present, collapse = " | "),
    paste(unique(classification$window_id), collapse = " | "),
    "See S31I_i2_risk_rule_diagnostics.csv",
    file.path(csv_dir, "S31I_i2_risk_rule_diagnostics.csv")
  ),
  stringsAsFactors = FALSE
)
writeLines(c(
  "# S31I I2-Risk Audit Validation",
  "",
  md_table(i2_validation, c("check", "pass", "evidence"), max_rows = 20L),
  "",
  paste0("Validation status: ", ifelse(all(i2_validation$pass), "PASS", "FAIL"), ".")
), file.path(md_dir, "S31I_I2_RISK_AUDIT_VALIDATION.md"), useBytes = TRUE)

if (!all(i2_validation$pass)) stop("Phase A validation failed.", call. = FALSE)
log_i2("Phase A completed.")

# ---- 4. Phase B: rolling integration-order audit -----------------------------
panel$year <- as.integer(as_num(panel$year))
for (col in c("y_t", "k_t", "omega_t", "omega_k_t", "K_ME_gross_real", "K_NRC_gross_real", "pK_relative_ME_NRC")) {
  if (!col %in% names(panel)) panel[[col]] <- NA_real_
  panel[[col]] <- finite_or_na(panel[[col]])
}
panel$k_ME_t <- ifelse(is.finite(panel$K_ME_gross_real) & panel$K_ME_gross_real > 0, log(panel$K_ME_gross_real), NA_real_)
panel$k_NRC_t <- ifelse(is.finite(panel$K_NRC_gross_real) & panel$K_NRC_gross_real > 0, log(panel$K_NRC_gross_real), NA_real_)
panel$m_ME_NRC_t <- panel$k_ME_t - panel$k_NRC_t
panel$omega_m_ME_NRC_t <- panel$omega_t * panel$m_ME_NRC_t

min_year <- min(panel$year, na.rm = TRUE)
max_year <- max(panel$year, na.rm = TRUE)

make_window_grid <- function() {
  rows <- list()
  idx <- 1L
  for (end_year in seq(min_year + 24L, 1973L)) {
    rows[[idx]] <- data.frame(window_family = "pre_1974_expanding", window_start = min_year, window_end = end_year, window_type = "expanding_endpoint", width = NA_integer_, endpoint_year = end_year, stringsAsFactors = FALSE)
    idx <- idx + 1L
  }
  for (end_year in seq(1974L + 24L, max_year)) {
    rows[[idx]] <- data.frame(window_family = "post_1973_expanding", window_start = 1974L, window_end = end_year, window_type = "expanding_endpoint", width = NA_integer_, endpoint_year = end_year, stringsAsFactors = FALSE)
    idx <- idx + 1L
  }
  for (width in c(30L, 35L, 40L)) {
    starts_pre <- seq(min_year, 1973L - width + 1L)
    for (start_year in starts_pre) {
      rows[[idx]] <- data.frame(window_family = paste0("fixed_width_", width, "_pre_1974"), window_start = start_year, window_end = start_year + width - 1L, window_type = "fixed_width", width = width, endpoint_year = start_year + width - 1L, stringsAsFactors = FALSE)
      idx <- idx + 1L
    }
    starts_post <- seq(1974L, max_year - width + 1L)
    for (start_year in starts_post) {
      rows[[idx]] <- data.frame(window_family = paste0("fixed_width_", width, "_post_1973"), window_start = start_year, window_end = start_year + width - 1L, window_type = "fixed_width", width = width, endpoint_year = start_year + width - 1L, stringsAsFactors = FALSE)
      idx <- idx + 1L
    }
  }
  grid <- do.call(rbind, rows)
  grid$rolling_window_id <- paste(grid$window_family, grid$window_start, grid$window_end, sep = "_")
  grid
}

rolling_grid <- make_window_grid()
rolling_rows <- list()
idx <- 1L

for (vid in targets_present) {
  for (i in seq_len(nrow(rolling_grid))) {
    w <- rolling_grid[i, ]
    d <- panel[panel$year >= w$window_start & panel$year <= w$window_end, , drop = FALSE]
    x <- finite_or_na(series_for(vid, d))
    x <- x[is.finite(x)]
    n_obs <- length(x)
    short <- n_obs >= 25L && n_obs < 30L
    det <- rolling_primary_det(vid)
    failed_count <- 0L
    skipped_count <- 0L
    notes <- ""

    if (n_obs < 25L) {
      level_adf <- level_kpss <- diff_adf <- diff_kpss <- level_pp <- diff_pp <- list(read = "not_run", reject = NA, error = "insufficient_observations")
      classification_roll <- "insufficient_observations"
      skipped_count <- 6L
      notes <- "n_obs below 25; rolling test skipped"
    } else {
      dx <- diff(x)
      dx <- dx[is.finite(dx)]
      level_adf <- run_adf_simple(x, det)
      level_kpss <- run_kpss_simple(x, det)
      diff_adf <- run_adf_simple(dx, "drift")
      diff_kpss <- run_kpss_simple(dx, "drift")
      level_pp <- run_pp_simple(x, det)
      diff_pp <- run_pp_simple(dx, "drift")
      failed_count <- sum(!vapply(list(level_adf, level_kpss, diff_adf, diff_kpss, level_pp, diff_pp), `[[`, logical(1L), "ok"))
      classification_roll <- rolling_classify(level_adf, level_kpss, diff_adf, diff_kpss, level_pp, diff_pp, failed_count)
      if (short) notes <- "exploratory window with 25 <= n < 30"
    }

    rolling_rows[[idx]] <- data.frame(
      run_tag = RUN_TAG,
      variable_id = vid,
      window_family = w$window_family,
      rolling_window_id = w$rolling_window_id,
      window_start = w$window_start,
      window_end = w$window_end,
      n_obs = n_obs,
      window_type = w$window_type,
      width = w$width,
      endpoint_year = w$endpoint_year,
      level_adf_read = level_adf$read,
      level_kpss_read = level_kpss$read,
      diff_adf_read = diff_adf$read,
      diff_kpss_read = diff_kpss$read,
      level_pp_read = level_pp$read,
      diff_pp_read = diff_pp$read,
      classification = classification_roll,
      short_window_flag = short,
      deterministic_spec_used = det,
      failed_tests_count = failed_count,
      skipped_tests_count = skipped_count,
      notes = notes,
      stringsAsFactors = FALSE
    )
    idx <- idx + 1L
  }
}
rolling_windows <- do.call(rbind, rolling_rows)
write_csv_base(rolling_windows, file.path(csv_dir, "S31I_rolling_integration_order_windows.csv"))

stability_rows <- list()
idx <- 1L
for (vid in unique(rolling_windows$variable_id)) {
  for (fam in unique(rolling_windows$window_family)) {
    rw <- rolling_windows[rolling_windows$variable_id == vid & rolling_windows$window_family == fam, , drop = FALSE]
    valid <- rw[!rw$classification %in% c("insufficient_observations", "test_failed"), , drop = FALSE]
    n_valid <- nrow(valid)
    counts <- table(factor(rw$classification, levels = c("I1_preferred", "I0_preferred", "I2_risk", "deterministic_sensitive", "mixed_test_evidence", "insufficient_observations", "test_failed")))
    share_i1 <- ifelse(n_valid > 0L, counts["I1_preferred"] / n_valid, NA_real_)
    share_i2 <- ifelse(n_valid > 0L, counts["I2_risk"] / n_valid, NA_real_)
    valid_counts <- table(valid$classification)
    dominant <- ifelse(n_valid == 0L, "none", names(valid_counts)[which.max(valid_counts)])
    near <- rw[order(rw$endpoint_year), , drop = FALSE]
    near_valid <- near[!near$classification %in% c("insufficient_observations", "test_failed"), , drop = FALSE]
    near_class <- ifelse(nrow(near_valid) == 0L, "none", near_valid$classification[nrow(near_valid)])
    last3 <- tail(near_valid$classification, 3L)

    label <- "insufficient_evidence"
    if (n_valid >= 3L) {
      if (mean(valid$short_window_flag) > 0.5) label <- "short_window_fragile"
      else if (share_i1 >= 0.70) label <- "stable_I1"
      else if (share_i2 >= 0.70) label <- "stable_I2_risk"
      else if (counts["I0_preferred"] / n_valid >= 0.70) label <- "stable_I0"
      else if (length(unique(last3)) > 1L) label <- "endpoint_fragile"
      else if (counts["deterministic_sensitive"] / n_valid >= 0.30) label <- "deterministic_fragile"
      else label <- "mixed_unstable"
    }

    implication <- switch(label,
      stable_I1 = "supports_window_review",
      stable_I2_risk = "not_compatible_without_redesign",
      stable_I0 = "supports_with_caveat",
      endpoint_fragile = "endpoint_fragile_hold",
      deterministic_fragile = "endpoint_fragile_hold",
      mixed_unstable = "supports_with_caveat",
      short_window_fragile = "supports_with_caveat",
      insufficient_evidence = "insufficient_evidence",
      "insufficient_evidence"
    )

    stability_rows[[idx]] <- data.frame(
      run_tag = RUN_TAG,
      variable_id = vid,
      window_family = fam,
      n_windows_attempted = nrow(rw),
      n_windows_valid = n_valid,
      n_I1_preferred = as.integer(counts["I1_preferred"]),
      n_I0_preferred = as.integer(counts["I0_preferred"]),
      n_I2_risk = as.integer(counts["I2_risk"]),
      n_deterministic_sensitive = as.integer(counts["deterministic_sensitive"]),
      n_mixed_test_evidence = as.integer(counts["mixed_test_evidence"]),
      n_insufficient_observations = as.integer(counts["insufficient_observations"]),
      n_test_failed = as.integer(counts["test_failed"]),
      share_I1_preferred = share_i1,
      share_I2_risk = share_i2,
      dominant_classification = dominant,
      near_endpoint_classification = near_class,
      rolling_stability_label = label,
      s32_window_implication = implication,
      human_review_flag = label %in% c("stable_I2_risk", "endpoint_fragile", "deterministic_fragile", "mixed_unstable", "short_window_fragile", "insufficient_evidence"),
      notes = "Rolling integration-order diagnostic only; not model-choice evidence.",
      stringsAsFactors = FALSE
    )
    idx <- idx + 1L
  }
}
rolling_stability <- do.call(rbind, stability_rows)
write_csv_base(rolling_stability, file.path(csv_dir, "S31I_rolling_integration_order_stability.csv"))

rolling_report <- c(
  "# S31I Rolling Integration-Order Audit",
  "",
  "## 1. Executive read",
  paste0("Rolling windows generated: ", nrow(rolling_windows), "."),
  paste0("Rolling stability cells: ", nrow(rolling_stability), "."),
  paste0("Stability labels: ", paste(names(table(rolling_stability$rolling_stability_label)), as.integer(table(rolling_stability$rolling_stability_label)), sep = "=", collapse = "; "), "."),
  "",
  "## 2. Rolling protocol used",
  "Pre-1974 expanding windows hold the start at the earliest available year and vary endpoints through 1973. Post-1973 expanding windows hold the start at 1974. Fixed-width windows use widths 30, 35, and 40 without crossing the 1974 partition.",
  "",
  "## 3. Variables included",
  paste(targets_present, collapse = ", "),
  "",
  "## 4. Window families included",
  paste(unique(rolling_windows$window_family), collapse = ", "),
  "",
  "## 5. Compact rolling-stability table",
  md_table(rolling_stability, c("variable_id", "window_family", "n_windows_valid", "dominant_classification", "near_endpoint_classification", "rolling_stability_label", "s32_window_implication"), max_rows = 120L),
  "",
  "## 6. Pre-1974 endpoint-stability assessment",
  md_table(rolling_stability[rolling_stability$window_family == "pre_1974_expanding", ],
    c("variable_id", "share_I1_preferred", "share_I2_risk", "near_endpoint_classification", "rolling_stability_label", "s32_window_implication"),
    max_rows = 40L
  ),
  "",
  "## 7. Post-1973 endpoint-stability assessment",
  md_table(rolling_stability[rolling_stability$window_family == "post_1973_expanding", ],
    c("variable_id", "share_I1_preferred", "share_I2_risk", "near_endpoint_classification", "rolling_stability_label", "s32_window_implication"),
    max_rows = 40L
  ),
  "",
  "## 8. Fixed-width rolling-window assessment",
  md_table(rolling_stability[grepl("^fixed_width", rolling_stability$window_family), ],
    c("variable_id", "window_family", "n_windows_valid", "dominant_classification", "rolling_stability_label", "s32_window_implication"),
    max_rows = 120L
  ),
  "",
  "## 9. Capital-variable implications",
  md_table(rolling_stability[rolling_stability$variable_id %in% capital_focus, ],
    c("variable_id", "window_family", "rolling_stability_label", "s32_window_implication", "human_review_flag"),
    max_rows = 120L
  ),
  "",
  "## 10. B1 implication",
  "The B1 question is whether k_t and omega_k_t can be treated as admissible long-run regressors alongside y_t. If k_t is genuinely I2-risk, B1 cannot be read as a clean I(1) cointegrating-regression design without redesign. If the I2-risk call is an artifact of deterministic sensitivity or failed-test handling, B1 remains admissible for review but must carry the S31I caveat.",
  "",
  "## 11. E2B implication",
  "The E2B question is whether k_NRC_t, m_ME_NRC_t, and omega_m_ME_NRC_t can support the NRC-envelope / distribution-conditioned mechanization-bias interpretation. If k_NRC_t and m_ME_NRC_t are genuinely I2-risk, E2B cannot be promoted mechanically from S32 coefficient results. If the I2-risk call is mostly rule-driven or short-window fragile, E2B remains a review candidate but must be documented as integration-order sensitive.",
  "",
  "## 12. Guardrail statement",
  "Rolling integration-order diagnostics are window-reliability evidence, not model-choice evidence. Stable I(1) behavior supports human review of the corresponding estimation window family. Stable I2-risk behavior blocks clean I(1) cointegrating-regression interpretation unless the specification is redesigned. Endpoint-fragile behavior should be held for review rather than promoted mechanically.",
  "This rolling audit does not choose the model and does not authorize S40."
)
writeLines(rolling_report, file.path(md_dir, "S31I_ROLLING_INTEGRATION_ORDER_AUDIT.md"), useBytes = TRUE)
log_roll("Phase B completed.")

# ---- 5. Combined validation --------------------------------------------------
original_after <- snapshot_files(c(tests_path, classification_path, ledger_path, report_path, validation_path))
s31_after <- snapshot_files(s31_dirs)
s32_after <- snapshot_files(s32_dir)

required_new <- c(
  file.path(csv_dir, "S31I_i2_risk_audit_capital_variables.csv"),
  file.path(csv_dir, "S31I_i2_risk_test_trace.csv"),
  file.path(csv_dir, "S31I_i2_risk_rule_diagnostics.csv"),
  file.path(md_dir, "S31I_I2_RISK_AUDIT.md"),
  file.path(md_dir, "S31I_I2_RISK_AUDIT_VALIDATION.md"),
  i2_log_path,
  file.path(csv_dir, "S31I_rolling_integration_order_windows.csv"),
  file.path(csv_dir, "S31I_rolling_integration_order_stability.csv"),
  file.path(md_dir, "S31I_ROLLING_INTEGRATION_ORDER_AUDIT.md"),
  rolling_log_path
)

combined_validation <- data.frame(
  run_tag = RUN_TAG,
  check = c(
    "Existing S31I outputs were found",
    "Existing classification CSV was read",
    "Existing tests-long CSV was read",
    "Existing construction ledger was read",
    "All target variables were audited",
    "All original S31I windows were attempted",
    "Rolling-window families were attempted",
    "Failed/skipped test handling was inspected",
    "Rule diagnostics were written",
    "Rolling-window outputs were written",
    "Original S31I outputs were not overwritten",
    "S31 outputs were not overwritten",
    "S32 outputs were not overwritten",
    "S40 was not run"
  ),
  pass = c(
    all(file.exists(c(tests_path, classification_path, ledger_path, report_path, validation_path))),
    nrow(classification) > 0L,
    nrow(tests) > 0L,
    nrow(ledger) > 0L,
    all(targets_present %in% unique(i2_audit$variable_id)),
    all(unique(classification$window_id) %in% unique(i2_audit$window_id)),
    all(c("pre_1974_expanding", "post_1973_expanding") %in% unique(rolling_windows$window_family)) && any(grepl("^fixed_width", rolling_windows$window_family)),
    nrow(rule_diagnostics) > 0L,
    file.exists(file.path(csv_dir, "S31I_i2_risk_rule_diagnostics.csv")),
    all(file.exists(c(file.path(csv_dir, "S31I_rolling_integration_order_windows.csv"), file.path(csv_dir, "S31I_rolling_integration_order_stability.csv")))),
    same_snapshot(original_snapshot, original_after),
    same_snapshot(s31_before, s31_after),
    same_snapshot(s32_before, s32_after),
    !file.exists(s40_dir)
  ),
  evidence = c(
    s31i_dir,
    classification_path,
    tests_path,
    ledger_path,
    paste(targets_present, collapse = " | "),
    paste(unique(classification$window_id), collapse = " | "),
    paste(unique(rolling_windows$window_family), collapse = " | "),
    file.path(csv_dir, "S31I_i2_risk_rule_diagnostics.csv"),
    file.path(csv_dir, "S31I_i2_risk_rule_diagnostics.csv"),
    paste(file.path(csv_dir, c("S31I_rolling_integration_order_windows.csv", "S31I_rolling_integration_order_stability.csv")), collapse = " | "),
    paste(c(tests_path, classification_path, ledger_path, report_path, validation_path), collapse = " | "),
    paste(s31_dirs, collapse = " | "),
    s32_dir,
    ifelse(file.exists(s40_dir), s40_dir, "No output/US/S40 folder present")
  ),
  stringsAsFactors = FALSE
)
writeLines(c(
  "# S31I I2-Risk and Rolling Audit Validation",
  "",
  md_table(combined_validation, c("check", "pass", "evidence"), max_rows = 20L),
  "",
  paste0("Validation status: ", ifelse(all(combined_validation$pass), "PASS", "FAIL"), ".")
), file.path(md_dir, "S31I_I2_RISK_AND_ROLLING_AUDIT_VALIDATION.md"), useBytes = TRUE)

if (!all(combined_validation$pass)) {
  stop("Combined audit validation failed.", call. = FALSE)
}

log_i2("Combined audit validation passed.")
log_roll("Combined audit validation passed.")

cat("\nFinal S31I I2-risk and rolling audit summary\n")
cat("Run tag: ", RUN_TAG, "\n", sep = "")
cat("Target variables audited: ", paste(targets_present, collapse = ", "), "\n", sep = "")
cat("Original windows audited: ", paste(unique(classification$window_id), collapse = ", "), "\n", sep = "")
cat("Rolling families attempted: ", paste(unique(rolling_windows$window_family), collapse = ", "), "\n", sep = "")
cat("Rolling windows generated: ", nrow(rolling_windows), "\n", sep = "")
cat("I2-risk calls audited: ", nrow(i2_only), "\n", sep = "")
cat("Audit labels: ", paste(names(table(i2_only$audit_read)), as.integer(table(i2_only$audit_read)), sep = "=", collapse = "; "), "\n", sep = "")
cat("Corrected classification output necessary: ", ifelse(nrow(likely_artifact) > 0L, "yes", "no"), "\n", sep = "")
cat("Validation status: PASS\n")
cat("S31I I2-risk and rolling-window audit implemented. Original S31I outputs preserved. S31 VIF screen left untouched. S32 model-choice outputs left untouched. S40 remains parked.\n")
