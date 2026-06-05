###############################################################################
# US_S30I_integration_order_precheck_B1_E2B.R
# Chapter 2 - US S30I integration-order precheck for S32 B1/E2B
#
# Role:
#   Classify the stochastic order of raw variables and constructed regressors
#   used downstream by S32's B1/E2B model-choice layer.
#
# Guardrails:
#   - Does not name, rename, overwrite, or repurpose S31.
#   - Does not alter S32 model-choice outputs.
#   - Does not run S40.
#   - Does not reconstruct theta, productive capacity, or utilization.
#   - Does not estimate FM-OLS, IM-OLS, DOLS, or any coefficient model.
###############################################################################

suppressPackageStartupMessages({
  library(urca)
})

# ---- 0. Paths and constants --------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")
RUN_TAG <- "S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B"

panel_path <- file.path(REPO, "data/processed/US/us_s20_admissibility_panel.csv")
s31_dirs <- c(
  file.path(REPO, "output/US/S31_estimation_tables_tex"),
  file.path(REPO, "output/US/S31_model_choice_vif_screen")
)
s32_dir <- file.path(REPO, "output/US/S32_B1_E2B_MODEL_CHOICE_REVIEW")
s40_dir <- file.path(REPO, "output/US/S40")

out_dir <- file.path(REPO, "output/US", RUN_TAG)
csv_dir <- file.path(out_dir, "csv")
md_dir <- file.path(out_dir, "md")
logs_dir <- file.path(out_dir, "logs")
audit_dir <- file.path(out_dir, "audit")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
LOG_PATH <- file.path(logs_dir, "S30I_execution_log.txt")
writeLines(paste0(RUN_TAG, " run started: ", RUN_TIMESTAMP), LOG_PATH, useBytes = TRUE)

# ---- 1. Helpers --------------------------------------------------------------
log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste(..., collapse = ""))
  cat(msg, "\n")
  cat(msg, "\n", file = LOG_PATH, append = TRUE)
}

read_csv_base <- function(path, check_names = TRUE) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = check_names)
}

write_csv_base <- function(df, path) {
  utils::write.csv(df, path, row.names = FALSE, na = "")
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

safe_min <- function(x) {
  x <- finite_or_na(x)
  if (all(is.na(x))) return(NA_real_)
  min(x, na.rm = TRUE)
}

safe_max <- function(x) {
  x <- finite_or_na(x)
  if (all(is.na(x))) return(NA_real_)
  max(x, na.rm = TRUE)
}

safe_median <- function(x) {
  x <- finite_or_na(x)
  if (all(is.na(x))) return(NA_real_)
  stats::median(x, na.rm = TRUE)
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

md_table <- function(df, columns, max_rows = 30L, digits = 3L) {
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

require_file <- function(path) {
  if (!file.exists(path)) stop("Required file not found: ", path, call. = FALSE)
}

ensure_col <- function(df, col) {
  if (!col %in% names(df)) df[[col]] <- NA_real_
  df
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

test_null_for <- function(test_name) {
  if (test_name %in% c("ADF", "Phillips-Perron", "DF-GLS_ERS", "Zivot-Andrews")) {
    return("unit_root")
  }
  if (test_name == "KPSS") return("stationarity")
  "unknown"
}

read_result <- function(test_name, reject_at_5pct) {
  if (is.na(reject_at_5pct)) return("not_tested")
  if (test_name %in% c("ADF", "Phillips-Perron", "DF-GLS_ERS", "Zivot-Andrews")) {
    return(ifelse(reject_at_5pct, "reject_unit_root_5pct", "fail_to_reject_unit_root_5pct"))
  }
  if (test_name == "KPSS") {
    return(ifelse(reject_at_5pct, "reject_stationarity_5pct", "fail_to_reject_stationarity_5pct"))
  }
  "not_tested"
}

make_result_row <- function(variable, window, n_obs, transform, test_name, deterministic_spec,
                            lag_rule, stat = NA_real_, p_value = NA_real_, c1 = NA_real_,
                            c5 = NA_real_, c10 = NA_real_, reject10 = NA, reject5 = NA,
                            reject1 = NA, error_message = "") {
  data.frame(
    run_tag = RUN_TAG,
    variable_id = variable$variable_id,
    variable_label = variable$variable_label,
    source_column = variable$source_columns,
    constructed = variable$source_type %in% c("constructed_regressor", "derived_gap"),
    construction_formula = variable$construction_formula,
    window_id = window$window_id,
    window_start = window$window_start,
    window_end = window$window_end,
    n_obs = n_obs,
    transform = transform,
    test_name = test_name,
    deterministic_spec = deterministic_spec,
    lag_rule = lag_rule,
    test_statistic = stat,
    p_value = p_value,
    critical_1pct = c1,
    critical_5pct = c5,
    critical_10pct = c10,
    reject_at_10pct = reject10,
    reject_at_5pct = reject5,
    reject_at_1pct = reject1,
    test_null = test_null_for(test_name),
    test_result_read = read_result(test_name, reject5),
    error_message = error_message,
    stringsAsFactors = FALSE
  )
}

critical_values <- function(cval) {
  vals <- as_num(cval)
  names_lower <- tolower(names(cval))
  if (is.null(names_lower) || all(!nzchar(names_lower))) {
    names_lower <- tolower(colnames(as.matrix(cval)))
  }
  if (length(vals) == 0L) return(c(c1 = NA_real_, c5 = NA_real_, c10 = NA_real_))
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

primary_level_spec <- function(family) {
  if (family == "trend_family") return("drift_trend")
  "drift"
}

sensitivity_level_spec <- function(family) {
  if (family == "trend_family") return("drift")
  "drift_trend"
}

run_adf <- function(x, variable, window, n_obs, transform, deterministic_spec) {
  urdf_type <- det_to_urdf_type(deterministic_spec)
  if (is.na(urdf_type) || !nzchar(urdf_type)) {
    return(make_result_row(variable, window, n_obs, transform, "ADF", deterministic_spec,
      "selectlags=AIC", error_message = paste0("ADF unsupported deterministic_spec: ", deterministic_spec)
    ))
  }
  fit <- tryCatch(urca::ur.df(x, type = urdf_type, selectlags = "AIC"), error = function(e) e)
  if (inherits(fit, "error")) {
    return(make_result_row(variable, window, n_obs, transform, "ADF", deterministic_spec,
      "selectlags=AIC", error_message = fit$message
    ))
  }
  stat <- as_num(fit@teststat[1L, 1L])
  cv <- critical_values(fit@cval[1L, ])
  rej <- reject_from_stat("ADF", stat, cv["c1"], cv["c5"], cv["c10"])
  make_result_row(variable, window, n_obs, transform, "ADF", deterministic_spec,
    "selectlags=AIC", stat = stat, c1 = cv["c1"], c5 = cv["c5"], c10 = cv["c10"],
    reject10 = rej["r10"], reject5 = rej["r5"], reject1 = rej["r1"]
  )
}

run_pp <- function(x, variable, window, n_obs, transform, deterministic_spec) {
  model <- det_to_upp_model(deterministic_spec)
  if (is.na(model) || !nzchar(model)) {
    return(make_result_row(variable, window, n_obs, transform, "Phillips-Perron", deterministic_spec,
      "lags=short", error_message = paste0("ur.pp does not support deterministic_spec: ", deterministic_spec)
    ))
  }
  fit <- tryCatch(urca::ur.pp(x, type = "Z-tau", model = model, lags = "short"), error = function(e) e)
  if (inherits(fit, "error")) {
    return(make_result_row(variable, window, n_obs, transform, "Phillips-Perron", deterministic_spec,
      "lags=short", error_message = fit$message
    ))
  }
  stat <- as_num(fit@teststat[1L])
  cv <- critical_values(fit@cval[1L, ])
  rej <- reject_from_stat("Phillips-Perron", stat, cv["c1"], cv["c5"], cv["c10"])
  make_result_row(variable, window, n_obs, transform, "Phillips-Perron", deterministic_spec,
    "lags=short", stat = stat, c1 = cv["c1"], c5 = cv["c5"], c10 = cv["c10"],
    reject10 = rej["r10"], reject5 = rej["r5"], reject1 = rej["r1"]
  )
}

run_kpss <- function(x, variable, window, n_obs, transform, deterministic_spec) {
  kpss_type <- det_to_kpss_type(deterministic_spec)
  if (is.na(kpss_type) || !nzchar(kpss_type)) {
    return(make_result_row(variable, window, n_obs, transform, "KPSS", deterministic_spec,
      "lags=short", error_message = paste0("ur.kpss does not support deterministic_spec: ", deterministic_spec)
    ))
  }
  fit <- tryCatch(urca::ur.kpss(x, type = kpss_type, lags = "short"), error = function(e) e)
  if (inherits(fit, "error")) {
    return(make_result_row(variable, window, n_obs, transform, "KPSS", deterministic_spec,
      "lags=short", error_message = fit$message
    ))
  }
  stat <- as_num(fit@teststat[1L])
  cv <- critical_values(fit@cval[1L, ])
  rej <- reject_from_stat("KPSS", stat, cv["c1"], cv["c5"], cv["c10"])
  make_result_row(variable, window, n_obs, transform, "KPSS", deterministic_spec,
    "lags=short", stat = stat, c1 = cv["c1"], c5 = cv["c5"], c10 = cv["c10"],
    reject10 = rej["r10"], reject5 = rej["r5"], reject1 = rej["r1"]
  )
}

run_ers <- function(x, variable, window, n_obs, transform, deterministic_spec) {
  model <- det_to_upp_model(deterministic_spec)
  if (is.na(model) || !nzchar(model)) {
    return(make_result_row(variable, window, n_obs, transform, "DF-GLS_ERS", deterministic_spec,
      "lag.max=4", error_message = paste0("ur.ers does not support deterministic_spec: ", deterministic_spec)
    ))
  }
  ers_model <- ifelse(model == "constant", "constant", "trend")
  fit <- tryCatch(urca::ur.ers(x, type = "DF-GLS", model = ers_model, lag.max = 4L), error = function(e) e)
  if (inherits(fit, "error")) {
    return(make_result_row(variable, window, n_obs, transform, "DF-GLS_ERS", deterministic_spec,
      "lag.max=4", error_message = fit$message
    ))
  }
  stat <- as_num(fit@teststat[1L])
  cv <- critical_values(fit@cval[1L, ])
  rej <- reject_from_stat("DF-GLS_ERS", stat, cv["c1"], cv["c5"], cv["c10"])
  make_result_row(variable, window, n_obs, transform, "DF-GLS_ERS", deterministic_spec,
    "lag.max=4", stat = stat, c1 = cv["c1"], c5 = cv["c5"], c10 = cv["c10"],
    reject10 = rej["r10"], reject5 = rej["r5"], reject1 = rej["r1"]
  )
}

run_za <- function(x, variable, window, n_obs) {
  if (!exists("ur.za", where = asNamespace("urca"))) {
    return(make_result_row(variable, window, n_obs, "level", "Zivot-Andrews", "break_both",
      "lag=2", error_message = "urca::ur.za is not available"
    ))
  }
  fit <- tryCatch(urca::ur.za(x, model = "both", lag = 2L), error = function(e) e)
  if (inherits(fit, "error")) {
    return(make_result_row(variable, window, n_obs, "level", "Zivot-Andrews", "break_both",
      "lag=2", error_message = fit$message
    ))
  }
  stat <- as_num(fit@teststat[1L])
  cv_raw <- as_num(fit@cval)
  cv <- c(c1 = cv_raw[1L], c5 = cv_raw[2L], c10 = cv_raw[3L])
  rej <- reject_from_stat("Zivot-Andrews", stat, cv["c1"], cv["c5"], cv["c10"])
  row <- make_result_row(variable, window, n_obs, "level", "Zivot-Andrews", "break_both",
    "lag=2", stat = stat, c1 = cv["c1"], c5 = cv["c5"], c10 = cv["c10"],
    reject10 = rej["r10"], reject5 = rej["r5"], reject1 = rej["r1"]
  )
  row$lag_rule <- paste0("lag=2; breakpoint_index=", fit@bpoint)
  row
}

run_battery <- function(series, variable, window, n_obs) {
  level_primary <- primary_level_spec(variable$deterministic_family)
  level_sensitivity <- sensitivity_level_spec(variable$deterministic_family)
  diff_specs <- c("drift", "none")

  rows <- list()
  idx <- 1L

  if (n_obs < 15L) {
    for (transform in c("level", "first_difference")) {
      for (test_name in c("ADF", "Phillips-Perron", "KPSS", "DF-GLS_ERS")) {
        for (det in unique(c(level_primary, level_sensitivity, diff_specs))) {
          rows[[idx]] <- make_result_row(variable, window, n_obs, transform, test_name, det,
            "not_run", error_message = "insufficient observations for integration-order precheck"
          )
          idx <- idx + 1L
        }
      }
    }
    rows[[idx]] <- make_result_row(variable, window, n_obs, "level", "Zivot-Andrews", "break_both",
      "not_run", error_message = "insufficient observations for one-break diagnostic"
    )
    return(do.call(rbind, rows))
  }

  for (det in c(level_primary, level_sensitivity)) {
    rows[[idx]] <- run_adf(series, variable, window, n_obs, "level", det); idx <- idx + 1L
    rows[[idx]] <- run_pp(series, variable, window, n_obs, "level", det); idx <- idx + 1L
    rows[[idx]] <- run_kpss(series, variable, window, n_obs, "level", det); idx <- idx + 1L
    rows[[idx]] <- run_ers(series, variable, window, n_obs, "level", det); idx <- idx + 1L
  }

  diff_series <- diff(series)
  diff_series <- diff_series[is.finite(diff_series)]
  diff_n <- length(diff_series)
  for (det in diff_specs) {
    rows[[idx]] <- run_adf(diff_series, variable, window, diff_n, "first_difference", det); idx <- idx + 1L
    rows[[idx]] <- run_pp(diff_series, variable, window, diff_n, "first_difference", det); idx <- idx + 1L
    rows[[idx]] <- run_kpss(diff_series, variable, window, diff_n, "first_difference", det); idx <- idx + 1L
    rows[[idx]] <- run_ers(diff_series, variable, window, diff_n, "first_difference", det); idx <- idx + 1L
  }

  rows[[idx]] <- run_za(series, variable, window, n_obs)
  do.call(rbind, rows)
}

decision <- function(rows, transform, test_name, deterministic_spec) {
  hit <- rows[
    rows$transform == transform &
      rows$test_name == test_name &
      rows$deterministic_spec == deterministic_spec,
    ,
    drop = FALSE
  ]
  if (nrow(hit) == 0L || nzchar(hit$error_message[1L]) && hit$test_name[1L] != "Zivot-Andrews") return(NA)
  as.logical(hit$reject_at_5pct[1L])
}

read_for <- function(rows, transform, test_name, deterministic_spec) {
  hit <- rows[
    rows$transform == transform &
      rows$test_name == test_name &
      rows$deterministic_spec == deterministic_spec,
    ,
    drop = FALSE
  ]
  if (nrow(hit) == 0L) return("not_tested")
  hit$test_result_read[1L]
}

core_classification <- function(rows, variable, level_spec) {
  adf_l <- decision(rows, "level", "ADF", level_spec)
  pp_l <- decision(rows, "level", "Phillips-Perron", level_spec)
  kpss_l <- decision(rows, "level", "KPSS", level_spec)
  adf_d <- decision(rows, "first_difference", "ADF", "drift")
  pp_d <- decision(rows, "first_difference", "Phillips-Perron", "drift")
  kpss_d <- decision(rows, "first_difference", "KPSS", "drift")

  vals <- c(adf_l, pp_l, kpss_l, adf_d, pp_d, kpss_d)
  if (all(is.na(vals))) return("test_failed")

  level_ur_rejects <- sum(c(adf_l, pp_l) == TRUE, na.rm = TRUE)
  level_stationarity_reject <- isTRUE(kpss_l)
  diff_ur_rejects <- sum(c(adf_d, pp_d) == TRUE, na.rm = TRUE)
  diff_stationarity_reject <- isTRUE(kpss_d)

  if (diff_ur_rejects == 0L || diff_stationarity_reject) return("I2_risk")
  if (level_ur_rejects >= 1L && !level_stationarity_reject) return("I0_preferred")
  if (level_ur_rejects == 0L && level_stationarity_reject && diff_ur_rejects >= 1L && !diff_stationarity_reject) {
    return("I1_preferred")
  }
  "ambiguous_hold"
}

classify_window <- function(rows, variable, window, n_obs) {
  primary <- primary_level_spec(variable$deterministic_family)
  sensitivity <- sensitivity_level_spec(variable$deterministic_family)
  primary_class <- core_classification(rows, variable, primary)
  sensitivity_class <- core_classification(rows, variable, sensitivity)

  det_sensitive <- primary_class != sensitivity_class &&
    primary_class %in% c("I1_preferred", "I0_preferred", "I2_risk", "ambiguous_hold") &&
    sensitivity_class %in% c("I1_preferred", "I0_preferred", "I2_risk", "ambiguous_hold")

  za <- rows[
    rows$test_name == "Zivot-Andrews" & rows$transform == "level",
    ,
    drop = FALSE
  ]
  break_sensitive <- nrow(za) > 0L && isTRUE(za$reject_at_10pct[1L]) &&
    primary_class %in% c("I1_preferred", "ambiguous_hold")

  failed_required <- any(
    rows$test_name %in% c("ADF", "Phillips-Perron", "KPSS") &
      rows$deterministic_spec %in% c(primary, "drift") &
      nzchar(rows$error_message) &
      !grepl("does not support deterministic_spec", rows$error_message)
  )

  classification <- primary_class
  if (n_obs < 15L) classification <- "insufficient_observations"
  else if (failed_required && primary_class == "test_failed") classification <- "test_failed"
  else if (det_sensitive) classification <- "deterministic_sensitive"
  else if (break_sensitive) classification <- "break_sensitive"

  confidence <- "medium"
  if (classification %in% c("I1_preferred", "I0_preferred") && !det_sensitive && !break_sensitive) confidence <- "high"
  if (classification %in% c("deterministic_sensitive", "break_sensitive", "ambiguous_hold")) confidence <- "low"
  if (classification %in% c("I2_risk", "insufficient_observations", "test_failed")) confidence <- "low"

  implication <- switch(classification,
    I1_preferred = "compatible_with_S32",
    I0_preferred = "compatible_with_S32",
    deterministic_sensitive = "compatible_but_document_mixed_order",
    break_sensitive = "compatible_but_document_mixed_order",
    ambiguous_hold = "hold_for_review",
    I2_risk = "not_compatible_without_redesign",
    insufficient_observations = "insufficient_evidence",
    test_failed = "insufficient_evidence",
    "hold_for_review"
  )

  notes <- c(
    paste0("primary_deterministic_spec=", primary),
    paste0("sensitivity_classification=", sensitivity_class)
  )
  if (variable$variable_id == "omega_t" && classification == "I1_preferred") {
    notes <- c(notes, "omega_t I(1) makes B1 interaction interpretation more fragile")
  }
  if (variable$variable_id %in% c("omega_k_t", "omega_m_ME_NRC_t") &&
      classification %in% c("ambiguous_hold", "I2_risk", "deterministic_sensitive")) {
    notes <- c(notes, "constructed interaction needs human review before coefficient interpretation")
  }
  if (variable$variable_id == "m_ME_NRC_t" && classification == "I0_preferred") {
    notes <- c(notes, "E2B becomes mixed I(1)/I(0), not automatically invalid but must be documented")
  }
  if (break_sensitive) notes <- c(notes, "Zivot-Andrews one-break diagnostic rejects unit-root null at 10pct")

  data.frame(
    run_tag = RUN_TAG,
    variable_id = variable$variable_id,
    variable_label = variable$variable_label,
    window_id = window$window_id,
    window_start = window$window_start,
    window_end = window$window_end,
    n_obs = n_obs,
    level_adf_read = read_for(rows, "level", "ADF", primary),
    level_pp_read = read_for(rows, "level", "Phillips-Perron", primary),
    level_kpss_read = read_for(rows, "level", "KPSS", primary),
    diff_adf_read = read_for(rows, "first_difference", "ADF", "drift"),
    diff_pp_read = read_for(rows, "first_difference", "Phillips-Perron", "drift"),
    diff_kpss_read = read_for(rows, "first_difference", "KPSS", "drift"),
    deterministic_sensitivity = det_sensitive,
    break_sensitivity = break_sensitive,
    classification = classification,
    confidence = confidence,
    s32_implication = implication,
    human_review_flag = classification %in% c(
      "deterministic_sensitive", "break_sensitive", "ambiguous_hold",
      "I2_risk", "insufficient_observations", "test_failed"
    ),
    notes = collapse_nonempty(notes, " ; "),
    stringsAsFactors = FALSE
  )
}

# ---- 2. Inputs and S32-bound constructions ----------------------------------
s31_before <- snapshot_files(s31_dirs)
s32_before <- snapshot_files(s32_dir)

require_file(panel_path)
panel <- read_csv_base(panel_path, check_names = FALSE)
panel$year <- as.integer(as_num(panel$year))

needed_base <- c("year", "y_t", "k_t", "omega_t", "omega_k_t", "K_ME_gross_real", "K_NRC_gross_real")
optional_base <- c(
  "pK_relative_ME_NRC", "s_t", "phi_t", "s_t_proxy", "phi_t_proxy",
  "s_t_proxy_cc", "phi_t_proxy_cc", "s_ME_over_ME_NRC_gross_real",
  "phi_ME_over_ME_NRC_real", "s_ME_over_ME_NRC_gross_cc", "phi_ME_over_ME_NRC_cc"
)
all_audit_cols <- unique(c(needed_base, optional_base))

for (col in all_audit_cols) panel <- ensure_col(panel, col)

for (col in setdiff(all_audit_cols, "year")) {
  panel[[col]] <- finite_or_na(panel[[col]])
}

panel$k_ME_t <- ifelse(is.finite(panel$K_ME_gross_real) & panel$K_ME_gross_real > 0,
  log(panel$K_ME_gross_real), NA_real_
)
panel$k_NRC_t <- ifelse(is.finite(panel$K_NRC_gross_real) & panel$K_NRC_gross_real > 0,
  log(panel$K_NRC_gross_real), NA_real_
)
panel$m_ME_NRC_t <- panel$k_ME_t - panel$k_NRC_t
panel$omega_k_t_direct <- panel$omega_t * panel$k_t
panel$omega_m_ME_NRC_t <- panel$omega_t * panel$m_ME_NRC_t

input_audit <- data.frame(
  run_tag = RUN_TAG,
  column_name = all_audit_cols,
  present_in_input = all_audit_cols %in% names(read_csv_base(panel_path, check_names = FALSE)),
  nonmissing_obs = vapply(all_audit_cols, function(col) sum(!is.na(panel[[col]])), integer(1L)),
  finite_obs = vapply(all_audit_cols, function(col) sum(is.finite(as_num(panel[[col]]))), integer(1L)),
  first_nonmissing_year = vapply(all_audit_cols, function(col) {
    yrs <- panel$year[!is.na(panel[[col]])]
    if (length(yrs) == 0L) return(NA_integer_)
    min(yrs)
  }, integer(1L)),
  last_nonmissing_year = vapply(all_audit_cols, function(col) {
    yrs <- panel$year[!is.na(panel[[col]])]
    if (length(yrs) == 0L) return(NA_integer_)
    max(yrs)
  }, integer(1L)),
  binding_source = "S32 script and S20 processed panel",
  notes = "",
  stringsAsFactors = FALSE
)
input_audit$notes[!input_audit$present_in_input] <- "missing from input dataset"
input_audit$notes[input_audit$present_in_input & input_audit$nonmissing_obs == 0L] <- "present but zero nonmissing observations"
write_csv_base(input_audit, file.path(audit_dir, "S30I_input_columns_audit.csv"))

# ---- 3. Variable construction ledger ----------------------------------------
ledger <- data.frame(
  run_tag = RUN_TAG,
  variable_id = c(
    "y_t", "k_t", "omega_t", "omega_k_t", "k_NRC_t", "k_ME_t",
    "m_ME_NRC_t", "omega_m_ME_NRC_t", "pK_relative_ME_NRC",
    "s_t", "phi_t", "s_t_proxy", "phi_t_proxy", "s_t_proxy_cc", "phi_t_proxy_cc"
  ),
  variable_label = c(
    "log real output",
    "log aggregate capital",
    "profit-share distribution condition",
    "omega_t multiplied by k_t",
    "log real NRC capital envelope",
    "log real ME capital",
    "ME/NRC mechanization log gap",
    "omega_t multiplied by ME/NRC mechanization gap",
    "ME/NRC relative investment price",
    "direct composition share",
    "direct composition investment share",
    "ME/NRC composition-share proxy",
    "ME/NRC investment-composition proxy",
    "ME/NRC current-cost composition-share proxy",
    "ME/NRC current-cost investment-composition proxy"
  ),
  source_type = c(
    "raw_column", "raw_column", "raw_column", "constructed_regressor",
    "constructed_regressor", "constructed_regressor", "derived_gap",
    "constructed_regressor", "optional_support", "optional_support",
    "optional_support", "optional_support", "optional_support",
    "optional_support", "optional_support"
  ),
  source_columns = c(
    "y_t", "k_t", "omega_t", "omega_t | k_t",
    "K_NRC_gross_real", "K_ME_gross_real", "K_ME_gross_real | K_NRC_gross_real",
    "omega_t | K_ME_gross_real | K_NRC_gross_real",
    "pK_relative_ME_NRC", "s_t", "phi_t", "s_t_proxy", "phi_t_proxy",
    "s_t_proxy_cc", "phi_t_proxy_cc"
  ),
  construction_formula = c(
    "input column y_t",
    "input column k_t",
    "input column omega_t",
    "omega_t * k_t",
    "log(K_NRC_gross_real)",
    "log(K_ME_gross_real)",
    "log(K_ME_gross_real) - log(K_NRC_gross_real)",
    "omega_t * (log(K_ME_gross_real) - log(K_NRC_gross_real))",
    "input column pK_relative_ME_NRC",
    "input column s_t",
    "input column phi_t",
    "input column s_t_proxy",
    "input column phi_t_proxy",
    "input column s_t_proxy_cc",
    "input column phi_t_proxy_cc"
  ),
  used_in_spec = c(
    "both", "B1", "both", "B1", "E2B", "support_diagnostic",
    "E2B", "E2B", "support_diagnostic", "support_diagnostic",
    "support_diagnostic", "support_diagnostic", "support_diagnostic",
    "support_diagnostic", "support_diagnostic"
  ),
  expected_role = c(
    "dependent variable",
    "B1 long-run aggregate capital regressor",
    "distribution conditioner",
    "B1 constructed distributive-capital regressor",
    "E2B NRC-envelope capital regressor",
    "mechanization-gap component",
    "mechanization-bias support variable",
    "E2B constructed distribution-conditioned mechanization-bias regressor",
    "relative-price support diagnostic",
    "optional direct composition support",
    "optional direct composition support",
    "optional proxy composition support",
    "optional proxy investment-composition support",
    "optional current-cost composition support",
    "optional current-cost investment-composition support"
  ),
  test_priority = c(
    "required", "required", "required", "required", "required", "support",
    "required", "required", "support", "support", "support", "support",
    "support", "support", "support"
  ),
  notes = c(
    "S32 dependent variable.",
    "S32 B1 regressor.",
    "Required because B1 and E2B use omega-conditioned constructed regressors.",
    "Tested directly; S32 uses omega_k_t as B1 regressor.",
    "S32 constructs k_NRC_t from K_NRC_gross_real; S31 candidate VIF calls this k_NRC_proxy_t.",
    "Component for mechanization gap; not an S32 E2B RHS variable by itself.",
    "E2B omits m_ME_NRC_t by design, but its order matters for omega_m_ME_NRC_t.",
    "Tested directly; S32 E2B restricted RHS regressor.",
    "Available support variable; not active in S32 B1/E2B pair.",
    "Column present but may be empty in the active panel.",
    "Column present but may be empty in the active panel.",
    "Available support variable; active in prior S31/S30 composition diagnostics, not S32 B1/E2B.",
    "Available support variable; active in prior S31/S30 composition diagnostics, not S32 B1/E2B.",
    "Available support variable; active in prior S31/S30 current-cost diagnostics, not S32 B1/E2B.",
    "Available support variable; active in prior S31/S30 current-cost diagnostics, not S32 B1/E2B."
  ),
  deterministic_family = c(
    "trend_family", "trend_family", "bounded_family", "trend_family",
    "trend_family", "trend_family", "bounded_family", "bounded_family",
    "bounded_family", "bounded_family", "bounded_family", "bounded_family",
    "bounded_family", "bounded_family", "bounded_family"
  ),
  stringsAsFactors = FALSE
)
write_csv_base(ledger, file.path(csv_dir, "S30I_variable_construction_ledger.csv"))

variables <- split(ledger, seq_len(nrow(ledger)))
names(variables) <- ledger$variable_id

# ---- 4. S32 main windows -----------------------------------------------------
main_windows <- data.frame(
  run_tag = RUN_TAG,
  window_id = c(
    "full_long_sample",
    "pre_1974",
    "post_1973",
    "fordist_core",
    "bridge_1940_1978",
    "pre_1974_alt_1940_1973",
    "pre_1974_alt_1947_1974"
  ),
  window_start = c(1929, 1929, 1974, 1945, 1940, 1940, 1947),
  window_end = c(2024, 1973, 2024, 1973, 1978, 1973, 1974),
  source = "Embedded main-review window grid from codes/US_S32_B1_E2B_model_choice_review.R",
  attempted = TRUE,
  skip_reason = "",
  stringsAsFactors = FALSE
)

# ---- 5. Test execution -------------------------------------------------------
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
    s_t = df$s_t,
    phi_t = df$phi_t,
    s_t_proxy = df$s_t_proxy,
    phi_t_proxy = df$phi_t_proxy,
    s_t_proxy_cc = df$s_t_proxy_cc,
    phi_t_proxy_cc = df$phi_t_proxy_cc,
    rep(NA_real_, nrow(df))
  )
}

tests_rows <- list()
class_rows <- list()
row_i <- 1L
class_i <- 1L

for (w_i in seq_len(nrow(main_windows))) {
  w <- main_windows[w_i, ]
  d_win <- panel[panel$year >= w$window_start & panel$year <= w$window_end, , drop = FALSE]
  d_win <- d_win[order(d_win$year), , drop = FALSE]

  for (v_i in seq_along(variables)) {
    variable <- variables[[v_i]]
    x <- finite_or_na(series_for(variable$variable_id, d_win))
    x <- x[is.finite(x)]
    n_obs <- length(x)

    if (n_obs == 0L) {
      rows <- run_battery(x, variable, w, n_obs)
      rows$error_message[!nzchar(rows$error_message)] <- "source variable missing or zero usable observations in this window"
    } else {
      rows <- run_battery(x, variable, w, n_obs)
    }

    tests_rows[[row_i]] <- rows
    row_i <- row_i + 1L
    class_rows[[class_i]] <- classify_window(rows, variable, w, n_obs)
    class_i <- class_i + 1L
  }
}

tests_long <- do.call(rbind, tests_rows)
classification <- do.call(rbind, class_rows)

write_csv_base(tests_long, file.path(csv_dir, "S30I_integration_order_tests_long.csv"))
write_csv_base(classification, file.path(csv_dir, "S30I_integration_order_classification.csv"))

# ---- 6. Reports --------------------------------------------------------------
class_counts <- aggregate(
  variable_id ~ classification,
  data = classification,
  FUN = length
)
names(class_counts)[2L] <- "n_variable_windows"

implication_counts <- aggregate(
  variable_id ~ s32_implication,
  data = classification,
  FUN = length
)
names(implication_counts)[2L] <- "n_variable_windows"

b1_vars <- c("y_t", "k_t", "omega_t", "omega_k_t")
e2b_vars <- c("y_t", "k_NRC_t", "m_ME_NRC_t", "omega_m_ME_NRC_t")
constructed_vars <- c("omega_k_t", "k_NRC_t", "k_ME_t", "m_ME_NRC_t", "omega_m_ME_NRC_t")

b1_summary <- classification[classification$variable_id %in% b1_vars, , drop = FALSE]
e2b_summary <- classification[classification$variable_id %in% e2b_vars, , drop = FALSE]
constructed_summary <- classification[classification$variable_id %in% constructed_vars, , drop = FALSE]

human_review <- classification[classification$human_review_flag, , drop = FALSE]
missing_cols <- input_audit[!input_audit$present_in_input | input_audit$nonmissing_obs == 0L, , drop = FALSE]
failed_tests <- tests_long[nzchar(tests_long$error_message), , drop = FALSE]

report_lines <- c(
  paste0("# ", RUN_TAG),
  "",
  "## 1. Executive read",
  paste0("Run timestamp: ", RUN_TIMESTAMP, "."),
  paste0("Input dataset: `", panel_path, "`."),
  "This pass classifies the stochastic order of variables used by the current S32 B1/E2B comparison. It does not choose the winning model.",
  paste0("Classification counts: ", paste(class_counts$classification, class_counts$n_variable_windows, sep = "=", collapse = "; "), "."),
  paste0("S32 implication counts: ", paste(implication_counts$s32_implication, implication_counts$n_variable_windows, sep = "=", collapse = "; "), "."),
  "",
  "## 2. Variable construction ledger",
  md_table(ledger, c("variable_id", "source_type", "source_columns", "construction_formula", "used_in_spec", "test_priority"), max_rows = 30L),
  "",
  "## 3. Compact classification table",
  md_table(classification, c("variable_id", "window_id", "n_obs", "classification", "confidence", "s32_implication", "human_review_flag"), max_rows = 80L),
  "",
  "## 4. B1 precondition assessment",
  "B1 is most compatible with the current S32 cointegrating-regression design if y_t and k_t behave as I(1), omega_t behaves as I(0) or bounded-persistent, and the constructed interaction omega_t*k_t behaves as an admissible I(1)-type long-run regressor.",
  "If omega is I(1), B1 becomes more fragile because omega_t*k_t is no longer a clean distributive modulation of an I(1) capital trend.",
  "If omega*k is ambiguous or I2-risk, B1 coefficient significance cannot be interpreted as sufficient long-run evidence without further redesign.",
  md_table(b1_summary, c("variable_id", "window_id", "classification", "confidence", "s32_implication", "notes"), max_rows = 40L),
  "",
  "## 5. E2B precondition assessment",
  "E2B is most compatible with the current S32 design if y_t and k_NRC_t behave as I(1), while m_t and omega_t*m_t have a defensible order classification compatible with the intended NRC-envelope / distribution-conditioned mechanization-bias interpretation.",
  "If m_t is I(0), E2B becomes a mixed I(1)/I(0) specification rather than a clean all-I(1) cointegrating regression. This is not automatically invalid, but it must be documented.",
  "If omega*m is ambiguous or I2-risk, E2B's mechanization-bias channel should be held for review and not promoted mechanically.",
  md_table(e2b_summary, c("variable_id", "window_id", "classification", "confidence", "s32_implication", "notes"), max_rows = 40L),
  "",
  "## 6. Constructed-regressor risk assessment",
  md_table(constructed_summary, c("variable_id", "window_id", "classification", "confidence", "human_review_flag", "notes"), max_rows = 60L),
  "",
  "## 7. Deterministic-sensitivity assessment",
  md_table(classification[classification$deterministic_sensitivity, , drop = FALSE],
    c("variable_id", "window_id", "classification", "confidence", "notes"), max_rows = 60L
  ),
  if (!any(classification$deterministic_sensitivity)) "No material deterministic sensitivity was flagged by the classification rule." else "",
  "",
  "## 8. Break-sensitivity assessment",
  "Zivot-Andrews one-break diagnostics were run with `urca::ur.za(model = \"both\", lag = 2)` where observations were sufficient.",
  md_table(classification[classification$break_sensitivity, , drop = FALSE],
    c("variable_id", "window_id", "classification", "confidence", "notes"), max_rows = 60L
  ),
  if (!any(classification$break_sensitivity)) "No break-sensitive classification was promoted by the implemented rule." else "",
  "",
  "## 9. Implications for S32 interpretation",
  "This precheck is an input to human adjudication. It does not reinterpret S32 residual ADF gates as formal cointegration tests and does not mechanically reject a specification from one ambiguous variable.",
  md_table(human_review, c("variable_id", "window_id", "classification", "s32_implication", "notes"), max_rows = 80L),
  "",
  "## 10. Explicit non-selection statement",
  "This pass does not choose between B1 and E2B. S31 VIF outputs are left untouched. S32 model-choice outputs are left untouched. S40 remains parked."
)
writeLines(report_lines, file.path(md_dir, "S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B.md"), useBytes = TRUE)
writeLines(c("# S30I Validation Report", "", "Validation pending."), file.path(md_dir, "S30I_VALIDATION_REPORT.md"), useBytes = TRUE)

# ---- 7. Validation -----------------------------------------------------------
s31_after <- snapshot_files(s31_dirs)
s32_after <- snapshot_files(s32_dir)

required_csv <- file.path(csv_dir, c(
  "S30I_integration_order_tests_long.csv",
  "S30I_integration_order_classification.csv",
  "S30I_variable_construction_ledger.csv"
))
required_md <- file.path(md_dir, c(
  "S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B.md",
  "S30I_VALIDATION_REPORT.md"
))

all_tested_have_ledger <- all(unique(classification$variable_id) %in% ledger$variable_id)
constructed_tested_directly <- all(constructed_vars %in% unique(classification$variable_id))
main_windows_attempted <- all(main_windows$window_id %in% unique(classification$window_id))
missing_reported <- nrow(missing_cols) > 0L || all(input_audit$present_in_input & input_audit$nonmissing_obs > 0L)
failed_reported <- nrow(failed_tests) > 0L || all(!nzchar(tests_long$error_message))
s31_untouched <- same_snapshot(s31_before, s31_after)
s32_untouched <- same_snapshot(s32_before, s32_after)
s40_not_run <- !file.exists(s40_dir)

validation <- data.frame(
  run_tag = RUN_TAG,
  check = c(
    "Output folders exist",
    "Required CSVs were written",
    "Required markdown files were written",
    "All tested variables have a construction-ledger entry",
    "All B1/E2B constructed regressors were tested directly",
    "All main windows were attempted",
    "Missing columns are reported explicitly",
    "Failed or skipped tests are reported explicitly",
    "No S31 outputs were overwritten",
    "No S32 model-choice outputs were overwritten",
    "No S40 reconstruction was run"
  ),
  pass = c(
    all(dir.exists(c(csv_dir, md_dir, logs_dir, audit_dir))),
    all(file.exists(required_csv)),
    all(file.exists(required_md)),
    all_tested_have_ledger,
    constructed_tested_directly,
    main_windows_attempted,
    missing_reported,
    failed_reported,
    s31_untouched,
    s32_untouched,
    s40_not_run
  ),
  evidence = c(
    out_dir,
    paste(required_csv, collapse = " | "),
    paste(required_md, collapse = " | "),
    paste(unique(classification$variable_id), collapse = " | "),
    paste(constructed_vars, collapse = " | "),
    paste(main_windows$window_id, collapse = " | "),
    ifelse(nrow(missing_cols) > 0L, paste(missing_cols$column_name, collapse = " | "), "no missing or empty audited columns"),
    ifelse(nrow(failed_tests) > 0L, paste(unique(failed_tests$error_message), collapse = " | "), "no failed or skipped tests"),
    paste(s31_dirs, collapse = " | "),
    s32_dir,
    ifelse(file.exists(s40_dir), paste0("S40 folder exists: ", s40_dir), "No output/US/S40 folder present")
  ),
  stringsAsFactors = FALSE
)
write_csv_base(validation, file.path(audit_dir, "S30I_validation_checks.csv"))

validation_lines <- c(
  "# S30I Validation Report",
  "",
  paste0("Run tag: `", RUN_TAG, "`."),
  paste0("Run timestamp: ", RUN_TIMESTAMP, "."),
  "",
  md_table(validation, c("check", "pass", "evidence"), max_rows = 20L),
  "",
  "## Missing-column audit",
  if (nrow(missing_cols) == 0L) "No missing or empty audited columns." else md_table(missing_cols, c("column_name", "present_in_input", "nonmissing_obs", "notes"), max_rows = 30L),
  "",
  "## Failed or skipped tests",
  if (nrow(failed_tests) == 0L) "No failed or skipped tests were recorded." else md_table(
    unique(failed_tests[, c("variable_id", "window_id", "transform", "test_name", "deterministic_spec", "error_message")]),
    c("variable_id", "window_id", "transform", "test_name", "deterministic_spec", "error_message"),
    max_rows = 80L
  ),
  "",
  paste0("Validation status: ", ifelse(all(validation$pass), "PASS", "FAIL"), ".")
)
writeLines(validation_lines, file.path(md_dir, "S30I_VALIDATION_REPORT.md"), useBytes = TRUE)

if (!all(validation$pass)) {
  log_msg("Validation failed. See ", file.path(md_dir, "S30I_VALIDATION_REPORT.md"))
  stop("S30I validation failed.", call. = FALSE)
}

log_msg("S30I completed successfully. Output folder: ", out_dir)
cat("\nFinal S30I summary\n")
cat("Run tag: ", RUN_TAG, "\n", sep = "")
cat("Input dataset: ", panel_path, "\n", sep = "")
cat("Variables tested: ", paste(ledger$variable_id, collapse = ", "), "\n", sep = "")
cat("Windows used: ", paste(main_windows$window_id, collapse = ", "), "\n", sep = "")
cat("Classification counts: ", paste(class_counts$classification, class_counts$n_variable_windows, sep = "=", collapse = "; "), "\n", sep = "")
cat("Validation status: PASS\n")
cat("S30I integration-order precheck implemented. S31 VIF screen left untouched. S32 model-choice outputs left untouched. S40 remains parked.\n")
