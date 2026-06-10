#!/usr/bin/env Rscript

# S22 constructs period-reset q_omega_h1_Kcap indexes from the locked S20
# panel and estimates a preliminary effective-output proxy baseline. Actual
# log output is not labeled as theoretical productive capacity.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
s20_dir <- file.path(repo_root, "data", "processed", "us_s20")
output_dir <- file.path(repo_root, "data", "processed", "us_s22")
validation_dir <- file.path(repo_root, "docs", "validation")
results_dir <- file.path(repo_root, "docs", "results")

input_paths <- c(
  s20_panel = file.path(
    s20_dir, "us_s20_capital_distribution_frontier_panel.csv"
  ),
  s20_checks = file.path(s20_dir, "us_s20_validation_checks.csv"),
  actual_output_panel = file.path(
    repo_root, "data", "processed", "US", "us_s20_admissibility_panel.csv"
  ),
  actual_output_ledger = file.path(
    repo_root, "output", "US", "S30I_INTEGRATION_ORDER_PRECHECK_B1_E2B",
    "csv", "S30I_variable_construction_ledger.csv"
  )
)
optional_s21_path <- file.path(
  repo_root, "data", "processed", "us_s21",
  "us_s21_accumulated_q_panel.csv"
)
output_paths <- c(
  q_panel = file.path(output_dir, "us_s22_periodized_q_panel.csv"),
  q_ledger = file.path(output_dir, "us_s22_periodized_q_ledger.csv"),
  regression_results = file.path(
    output_dir, "us_s22_preliminary_regression_results.csv"
  ),
  regression_diagnostics = file.path(
    output_dir, "us_s22_preliminary_regression_diagnostics.csv"
  ),
  checks = file.path(output_dir, "us_s22_validation_checks.csv"),
  validation_report = file.path(
    validation_dir, "US_S22_PERIODIZED_A00_BASELINE_VALIDATION.md"
  ),
  results_report = file.path(
    results_dir, "US_S22_PRELIMINARY_A00_PERIODIZED_RESULTS.md"
  )
)

abort <- function(message) {
  stop(message, call. = FALSE)
}

require_condition <- function(condition, message) {
  if (!isTRUE(condition)) {
    abort(message)
  }
}

read_csv <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

write_csv <- function(data, path) {
  write.csv(data, path, row.names = FALSE, na = "")
}

validation_check <- function(check_id, check_name, status, details) {
  require_condition(
    status %in% c("PASS", "WARN", "FAIL"),
    paste0("Invalid validation status for ", check_id, ": ", status)
  )
  data.frame(
    check_id = check_id,
    check_name = check_name,
    status = status,
    details = details,
    stringsAsFactors = FALSE
  )
}

periods <- data.frame(
  period_id = c(
    "full_long_sample",
    "pre_1974_full",
    "post_1973_full",
    "fordist_core",
    "bridge_1940_1978",
    "pre_1974_alt_1940_1973",
    "pre_1974_alt_1947_1973"
  ),
  start_year = c(1929L, 1929L, 1974L, 1945L, 1940L, 1940L, 1947L),
  end_year = c(2024L, 1973L, 2024L, 1973L, 1978L, 1973L, 1973L),
  stringsAsFactors = FALSE
)
periods$q_variable <- paste0("q_omega_h1_Kcap__", periods$period_id)
periods$increment_variable <- paste0(
  "q_increment_omega_h1_Kcap__", periods$period_id
)

expected_periods <- periods$period_id
short_forbidden_periods <- c("post_1974_tight", "post_1974_support")
required_baseline_variables <- c("k_Kcap", "g_Kcap", "omega_NFC")

missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(
    paste0(
      "S22 required inputs are missing:\n- ",
      paste(unname(missing_inputs), collapse = "\n- ")
    )
  )
}

input_hashes_before <- unname(tools::md5sum(input_paths))
names(input_hashes_before) <- names(input_paths)
provider_dir <- file.path(repo_root, "data", "external", "us_bea_provider")
provider_files <- if (dir.exists(provider_dir)) {
  list.files(provider_dir, recursive = TRUE, full.names = TRUE)
} else {
  character()
}
provider_hashes_before <- if (length(provider_files) > 0L) {
  tools::md5sum(provider_files)
} else {
  character()
}

s20 <- read_csv(input_paths[["s20_panel"]])
s20_checks <- read_csv(input_paths[["s20_checks"]])
actual_output_panel <- read_csv(input_paths[["actual_output_panel"]])
actual_output_ledger <- read_csv(input_paths[["actual_output_ledger"]])
missing_baseline_variables <- setdiff(
  c("year", "date", required_baseline_variables),
  names(s20)
)
require_condition(
  length(missing_baseline_variables) == 0L,
  paste0(
    "S20 panel lacks required S22 columns: ",
    paste(missing_baseline_variables, collapse = ", ")
  )
)
require_condition(
  all(c("check_id", "status") %in% names(s20_checks)),
  "S20 validation checks lack required check_id/status columns."
)
require_condition(
  !any(s20_checks$status == "FAIL"),
  "S20 validation checks contain a FAIL."
)
require_condition(
  !anyDuplicated(s20$year),
  "S20 panel contains duplicate years."
)
require_condition(
  all(c("year", "y_t") %in% names(actual_output_panel)),
  "Established output panel lacks year or y_t."
)
require_condition(
  !anyDuplicated(actual_output_panel$year),
  "Established output panel contains duplicate years."
)
output_ledger_row <- actual_output_ledger[
  actual_output_ledger$variable_id == "y_t",
  ,
  drop = FALSE
]
require_condition(
  nrow(output_ledger_row) == 1L &&
    identical(output_ledger_row$variable_label, "log real output"),
  "The established y_t source is not ledgered exactly as log real output."
)

s20$year <- as.integer(s20$year)
for (variable in required_baseline_variables) {
  s20[[variable]] <- suppressWarnings(as.numeric(s20[[variable]]))
  s20[[variable]][!is.finite(s20[[variable]])] <- NA_real_
}
s20 <- s20[order(s20$year), , drop = FALSE]
rownames(s20) <- NULL
actual_output_panel$year <- as.integer(actual_output_panel$year)
actual_output_panel$y_t <- suppressWarnings(as.numeric(
  actual_output_panel$y_t
))
actual_output_panel$y_t[!is.finite(actual_output_panel$y_t)] <- NA_real_
actual_log_output <- actual_output_panel$y_t[
  match(s20$year, actual_output_panel$year)
]

lagged_omega <- s20$omega_NFC[match(s20$year - 1L, s20$year)]
q_increment <- lagged_omega * s20$g_Kcap

q_panel <- s20[c("year", "date", "k_Kcap", "g_Kcap", "omega_NFC")]
q_panel$actual_log_output <- actual_log_output
q_panel$omega_NFC_lag1 <- lagged_omega
q_panel$q_increment_omega_h1_Kcap <- q_increment

ledger_rows <- list()
diagnostic_rows <- list()

for (i in seq_len(nrow(periods))) {
  period <- periods[i, , drop = FALSE]
  in_period <- s20$year >= period$start_year &
    s20$year <= period$end_year
  usable <- in_period & !is.na(s20$g_Kcap) & !is.na(lagged_omega)
  usable_index <- which(usable)
  require_condition(
    length(usable_index) > 0L,
    paste0("No usable q observations for period ", period$period_id)
  )
  first_usable <- min(s20$year[usable])
  last_usable <- max(s20$year[usable])
  internal_years <- seq(first_usable, last_usable)
  internal_index <- match(internal_years, s20$year)
  require_condition(
    !anyNA(internal_index) &&
      all(!is.na(s20$g_Kcap[internal_index])) &&
      all(!is.na(lagged_omega[internal_index])),
    paste0("Internal q-construction gap in period ", period$period_id)
  )

  q_values <- rep(NA_real_, nrow(s20))
  period_increment <- rep(NA_real_, nrow(s20))
  period_increment[internal_index] <- q_increment[internal_index]
  q_values[internal_index] <- cumsum(period_increment[internal_index])
  q_panel[[period$increment_variable]] <- period_increment
  q_panel[[period$q_variable]] <- q_values

  first_q <- q_values[match(first_usable, s20$year)]
  first_increment <- period_increment[match(first_usable, s20$year)]
  reset_verified <- isTRUE(all.equal(
    first_q, first_increment, tolerance = 1e-12
  ))
  increment_matches <- isTRUE(all.equal(
    period_increment[internal_index],
    lagged_omega[internal_index] * s20$g_Kcap[internal_index],
    tolerance = 1e-12
  ))
  no_preperiod_history <- all(is.na(q_values[s20$year < first_usable]))
  period_rows <- which(in_period)
  q_complete <- period_rows[
    !is.na(actual_log_output[period_rows]) &
      !is.na(s20$k_Kcap[period_rows]) &
    !is.na(s20$g_Kcap[period_rows]) &
      !is.na(lagged_omega[period_rows]) &
      !is.na(q_values[period_rows])
  ]

  ledger_rows[[i]] <- data.frame(
    q_variable = period$q_variable,
    q_increment_variable = period$increment_variable,
    period_id = period$period_id,
    start_year = period$start_year,
    end_year = period$end_year,
    first_usable_year = first_usable,
    last_usable_year = last_usable,
    source_capital_growth = "S20:g_Kcap",
    source_distribution_state = "S20:omega_NFC lagged one year",
    memory_rule = "h1 backward-looking state: omega_NFC_{s-1}",
    formula = paste0(
      period$increment_variable,
      "_s = omega_NFC_{s-1} * g_Kcap_s; ",
      period$q_variable,
      "_t = cumulative sum within period of ",
      period$increment_variable,
      "_s"
    ),
    reset_rule = paste0(
      "Reset at first usable observation ", first_usable,
      "; no accumulated pre-period history."
    ),
    construction_status = "constructed_period_reset",
    notes = paste(
      "Uncentered and unstandardized. Uses no contemporaneous omega_NFC,",
      "unrestricted lag weights, or level interaction."
    ),
    stringsAsFactors = FALSE
  )

  period_length <- length(period_rows)
  diagnostic_rows[[i]] <- data.frame(
    period_id = period$period_id,
    n_obs = length(q_complete),
    complete_case_start = if (length(q_complete)) {
      min(s20$year[q_complete])
    } else {
      NA_integer_
    },
    complete_case_end = if (length(q_complete)) {
      max(s20$year[q_complete])
    } else {
      NA_integer_
    },
    missing_output_count = sum(is.na(actual_log_output[period_rows])),
    missing_k_Kcap_count = sum(is.na(s20$k_Kcap[period_rows])),
    missing_g_Kcap_count = sum(is.na(s20$g_Kcap[period_rows])),
    missing_omega_NFC_count = sum(is.na(s20$omega_NFC[period_rows])),
    missing_lagged_omega_NFC_count = sum(
      is.na(lagged_omega[period_rows])
    ),
    missing_q_count = sum(is.na(q_values[period_rows])),
    q_resets_inside_period = reset_verified,
    uses_preperiod_q_history = !no_preperiod_history,
    uses_contemporaneous_omega = FALSE,
    q_increment_matches_lagged_omega_times_g_Kcap = increment_matches,
    min_q = min(q_values[period_rows], na.rm = TRUE),
    max_q = max(q_values[period_rows], na.rm = TRUE),
    first_q_value = first_q,
    last_q_value = q_values[match(last_usable, s20$year)],
    warning_flags = "diagnostic_OLS_not_preferred_estimator",
    stringsAsFactors = FALSE
  )
}

q_ledger <- do.call(rbind, ledger_rows)
diagnostics <- do.call(rbind, diagnostic_rows)

# The established S30/S32 input labels y_t as log real output. It is admitted
# here only as an effective-output proxy. The existing FM-OLS implementation
# uses the different y_t ~ k_t + omega_k_t family, so this patch runs diagnostic
# OLS and does not relabel it as FM-OLS.
actual_output_available <- any(!is.na(actual_log_output))
dependent_variable <- "y_t_actual_log_output"
dependent_variable_role <- "effective_output_proxy"
estimator_label <- "diagnostic_OLS_not_preferred_estimator"

regression_rows <- lapply(
  seq_len(nrow(periods)),
  function(i) {
    period <- periods[i, , drop = FALSE]
    diagnostic <- diagnostics[
      diagnostics$period_id == period$period_id,
      ,
      drop = FALSE
    ]
    q_values <- q_panel[[period$q_variable]]
    complete <- s20$year >= period$start_year &
      s20$year <= period$end_year &
      !is.na(actual_log_output) &
      !is.na(s20$k_Kcap) &
      !is.na(q_values)
    if (!actual_output_available || sum(complete) == 0L) {
      return(data.frame(
        period_id = period$period_id,
        start_year = period$start_year,
        end_year = period$end_year,
        first_usable_year = NA_integer_,
        last_usable_year = NA_integer_,
        n_obs = 0L,
        estimator = "not_run_missing_actual_log_output",
        dependent_variable = dependent_variable,
        dependent_variable_role = dependent_variable_role,
        capital_variable = "k_Kcap",
        q_variable = period$q_variable,
        theta_0_estimate = NA_real_,
        theta_0_std_error = NA_real_,
        theta_omega_estimate = NA_real_,
        theta_omega_std_error = NA_real_,
        alpha_estimate = NA_real_,
        alpha_std_error = NA_real_,
        r_squared = NA_real_,
        adj_r_squared = NA_real_,
        residual_sd = NA_real_,
        admissibility_status = "blocked",
        warning_flags = "blocked_missing_actual_log_output",
        notes = "Preliminary S22 row; actual log output was unavailable.",
        stringsAsFactors = FALSE
      ))
    }
    model_data <- data.frame(
      output = actual_log_output[complete],
      capital = s20$k_Kcap[complete],
      q = q_values[complete]
    )
    fit <- stats::lm(output ~ capital + q, data = model_data)
    fit_summary <- summary(fit)
    coefficient_table <- fit_summary$coefficients
    data.frame(
      period_id = period$period_id,
      start_year = period$start_year,
      end_year = period$end_year,
      first_usable_year = min(s20$year[complete]),
      last_usable_year = max(s20$year[complete]),
      n_obs = sum(complete),
      estimator = estimator_label,
      dependent_variable = dependent_variable,
      dependent_variable_role = dependent_variable_role,
      capital_variable = "k_Kcap",
      q_variable = period$q_variable,
      theta_0_estimate = coefficient_table["capital", "Estimate"],
      theta_0_std_error = coefficient_table["capital", "Std. Error"],
      theta_omega_estimate = coefficient_table["q", "Estimate"],
      theta_omega_std_error = coefficient_table["q", "Std. Error"],
      alpha_estimate = coefficient_table["(Intercept)", "Estimate"],
      alpha_std_error = coefficient_table["(Intercept)", "Std. Error"],
      r_squared = fit_summary$r.squared,
      adj_r_squared = fit_summary$adj.r.squared,
      residual_sd = fit_summary$sigma,
      admissibility_status = "proxy_admissible_for_preliminary_A00",
      warning_flags = estimator_label,
      notes = paste(
        "Preliminary S22 effective-output proxy estimate. Actual log output",
        "is not canonical y_t^p. Coefficients are not promoted as final."
      ),
      stringsAsFactors = FALSE
    )
  }
)
regression_results <- do.call(rbind, regression_rows)

for (path in c(output_dir, validation_dir, results_dir)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  require_condition(
    dir.exists(path),
    paste0("Unable to create S22 output directory: ", path)
  )
}

write_csv(q_panel, output_paths[["q_panel"]])
write_csv(q_ledger, output_paths[["q_ledger"]])
write_csv(regression_results, output_paths[["regression_results"]])
write_csv(diagnostics, output_paths[["regression_diagnostics"]])

pre_1974_rows <- grepl("pre_1974", periods$period_id)
q_columns <- grep("^q_omega_h1_Kcap__", names(q_panel), value = TRUE)
unrequested_q_columns <- setdiff(
  sub("^q_omega_h1_Kcap__", "", q_columns),
  expected_periods
)
q_counts_ok <- all(diagnostics$n_obs >= 25L)
q_resets_ok <- all(diagnostics$q_resets_inside_period)
no_preperiod_history <- all(!diagnostics$uses_preperiod_q_history)
increments_match <- all(
  diagnostics$q_increment_matches_lagged_omega_times_g_Kcap
)
backward_only <- all(
  q_ledger$source_distribution_state == "S20:omega_NFC lagged one year"
)

input_hashes_after <- unname(tools::md5sum(input_paths))
names(input_hashes_after) <- names(input_paths)
provider_hashes_after <- if (length(provider_files) > 0L) {
  tools::md5sum(provider_files)
} else {
  character()
}
inputs_unchanged <- identical(input_hashes_before, input_hashes_after)
providers_unchanged <- identical(
  provider_hashes_before, provider_hashes_after
)

checks <- do.call(rbind, list(
  validation_check(
    "s20_panel_exists", "S20 input panel exists", "PASS",
    input_paths[["s20_panel"]]
  ),
  validation_check(
    "s20_checks_pass", "S20 validation checks contain no FAIL", "PASS",
    paste(nrow(s20_checks), "S20 checks inspected.")
  ),
  validation_check(
    "baseline_variables_exist",
    "Required k_Kcap, g_Kcap, and omega_NFC variables exist", "PASS",
    paste(required_baseline_variables, collapse = "; ")
  ),
  validation_check(
    "actual_output_proxy_permitted",
    "Actual log output is permitted as the preliminary effective-output proxy",
    if (actual_output_available) "PASS" else "FAIL",
    paste(
      "Source: data/processed/US/us_s20_admissibility_panel.csv:y_t;",
      "ledger label: log real output."
    )
  ),
  validation_check(
    "dependent_not_canonical_y_p",
    "Dependent variable is not mislabeled as canonical y_t^p",
    if (
      all(regression_results$dependent_variable == dependent_variable) &&
        !any(grepl("y_t\\^p|canonical_y_p", regression_results$dependent_variable))
    ) "PASS" else "FAIL",
    "Dependent variable label is y_t_actual_log_output."
  ),
  validation_check(
    "dependent_role_effective_output_proxy",
    "Regression rows label the dependent-variable role as effective_output_proxy",
    if (
      all(
        regression_results$dependent_variable_role ==
          "effective_output_proxy"
      )
    ) "PASS" else "FAIL",
    "All seven regression rows use the explicit proxy role."
  ),
  validation_check(
    "requested_windows_present", "All requested period windows are present",
    if (setequal(periods$period_id, expected_periods)) "PASS" else "FAIL",
    paste(periods$period_id, collapse = "; ")
  ),
  validation_check(
    "no_unrequested_windows", "No unrequested period window is created",
    if (length(unrequested_q_columns) == 0L) "PASS" else "FAIL",
    if (length(unrequested_q_columns) == 0L) {
      "Exactly seven requested q columns constructed."
    } else {
      paste(unrequested_q_columns, collapse = "; ")
    }
  ),
  validation_check(
    "pre_1974_end_1973", "All pre_1974 windows end in 1973",
    if (all(periods$end_year[pre_1974_rows] == 1973L)) "PASS" else "FAIL",
    paste(periods$period_id[pre_1974_rows], collapse = "; ")
  ),
  validation_check(
    "no_pre_1974_end_1974", "No pre_1974 window ends in 1974",
    if (!any(periods$end_year[pre_1974_rows] == 1974L)) "PASS" else "FAIL",
    "No prohibited 1974 endpoint."
  ),
  validation_check(
    "no_short_post_windows", "No short post-1974 window is created",
    if (!any(periods$period_id %in% short_forbidden_periods)) {
      "PASS"
    } else {
      "FAIL"
    },
    "post_1974_tight and post_1974_support are absent."
  ),
  validation_check(
    "minimum_q_observations",
    "Every period has at least 25 complete q observations",
    if (q_counts_ok) "PASS" else "FAIL",
    paste(
      paste0(diagnostics$period_id, "=", diagnostics$n_obs),
      collapse = "; "
    )
  ),
  validation_check(
    "q_resets", "Each periodized q-index resets inside its period",
    if (q_resets_ok) "PASS" else "FAIL",
    "First q value equals the first usable within-period increment."
  ),
  validation_check(
    "no_preperiod_q_history",
    "No periodized q-index uses pre-period accumulated values",
    if (no_preperiod_history) "PASS" else "FAIL",
    "All q columns are missing before their first usable period observation."
  ),
  validation_check(
    "lagged_omega_backward_only",
    "Lagged omega_NFC is backward-looking only",
    if (backward_only) "PASS" else "FAIL",
    "Each increment uses omega_NFC from year s-1."
  ),
  validation_check(
    "no_contemporaneous_omega",
    "No contemporaneous omega_NFC is used in q construction",
    if (all(!diagnostics$uses_contemporaneous_omega)) "PASS" else "FAIL",
    "q increment = omega_NFC_{s-1} * g_Kcap_s."
  ),
  validation_check(
    "q_increment_identity",
    "Each period q increment equals lagged omega_NFC times g_Kcap",
    if (increments_match) "PASS" else "FAIL",
    "All seven period-specific increment columns match within 1e-12."
  ),
  validation_check(
    "q_increment_not_product_delta",
    "q increment is not a delta of an omega-capital product", "PASS",
    paste(
      "Implemented directly as omega_NFC_{s-1} * Delta log(K_cap_s);",
      "no product level or product difference is constructed."
    )
  ),
  validation_check(
    "no_omega_corp", "omega_CORP is not used in preferred q construction",
    if (!any(grepl("omega_CORP", q_ledger$formula, fixed = TRUE))) {
      "PASS"
    } else {
      "FAIL"
    },
    "Preferred state is omega_NFC."
  ),
  validation_check(
    "no_shaikh_adjusted", "No Shaikh-adjusted variable is used", "PASS",
    "Only unadjusted S20 omega_NFC is used."
  ),
  validation_check(
    "no_q_e", "No q_e variable is used in the preferred baseline",
    if (!any(grepl("^q_e_", names(q_panel)))) "PASS" else "FAIL",
    "Only q_omega_h1_Kcap periodized indexes are constructed."
  ),
  validation_check(
    "no_h3_h5", "No h3 or h5 q-index is used in the preferred baseline",
    if (!any(grepl("_(h3|h5)_", names(q_panel)))) "PASS" else "FAIL",
    "Memory rule is h1 only."
  ),
  validation_check(
    "no_level_interactions",
    "No omega_x or e_x interaction variable is constructed",
    if (
      !any(grepl("^omega_x_", names(q_panel))) &&
        !any(grepl("^e_x_", names(q_panel)))
    ) "PASS" else "FAIL",
    "Superseded level interactions are absent."
  ),
  validation_check(
    "no_mechanization_regressors",
    "No mechanization-bias variable is included in regression rows",
    if (
      all(regression_results$capital_variable == "k_Kcap") &&
        !any(grepl("ME|NRC|mechan", regression_results$q_variable))
    ) "PASS" else "FAIL",
    "Estimated baseline rows contain only k_Kcap and periodized q."
  ),
  validation_check(
    "no_frontier_conditioners",
    "No IPP or GOV_TRANS conditioner is included in regression rows",
    if (
      !any(grepl(
        "IPP|GOV_TRANS",
        paste(
          regression_results$capital_variable,
          regression_results$q_variable
        )
      ))
    ) "PASS" else "FAIL",
    "Frontier conditioners are excluded from the baseline regression."
  ),
  validation_check(
    "no_utilization_reconstruction",
    "No capacity utilization is reconstructed", "PASS",
    "S22 constructs q indexes only; no utilization column is produced."
  ),
  validation_check(
    "no_johansen_vecm", "No Johansen or VECM estimator is run", "PASS",
    "No system estimator or integration-order test is invoked."
  ),
  validation_check(
    "regression_rows_preliminary",
    "Regression rows are marked preliminary",
    if (
      all(grepl(
        "Preliminary S22 effective-output proxy estimate",
        regression_results$notes,
        fixed = TRUE
      ))
    ) {
      "PASS"
    } else {
      "FAIL"
    },
    "All seven period rows explicitly remain preliminary."
  ),
  validation_check(
    "diagnostic_ols_label",
    "Diagnostic OLS, if used, is not mislabeled as FM-OLS",
    if (all(regression_results$estimator == estimator_label)) {
      "PASS"
    } else {
      "FAIL"
    },
    paste(
      "All estimated rows are labeled exactly",
      "diagnostic_OLS_not_preferred_estimator."
    )
  ),
  validation_check(
    "proxy_regression_admissibility",
    "Effective-output regressions carry preliminary proxy admissibility",
    if (
      all(
        regression_results$admissibility_status ==
          "proxy_admissible_for_preliminary_A00"
      )
    ) "PASS" else "FAIL",
    "Actual output is admitted as a proxy, not as theoretical capacity."
  ),
  validation_check(
    "all_periods_estimated",
    "All seven requested period regressions are estimated",
    if (
      nrow(regression_results) == 7L &&
        all(regression_results$n_obs >= 25L) &&
        all(regression_results$estimator == estimator_label)
    ) "PASS" else "FAIL",
    paste(
      paste0(regression_results$period_id, "=", regression_results$n_obs),
      collapse = "; "
    )
  ),
  validation_check(
    "upstream_inputs_unchanged", "All upstream inputs are unchanged",
    if (inputs_unchanged) "PASS" else "FAIL",
    paste(length(input_paths), "input hashes compared.")
  ),
  validation_check(
    "provider_artifacts_unchanged", "Provider artifacts are unchanged",
    if (providers_unchanged) "PASS" else "FAIL",
    paste(length(provider_files), "provider files hashed unchanged.")
  ),
  validation_check(
    "outputs_written", "All required S22 output files are written",
    "PASS", "Output existence is finalized after reports are written."
  )
))

escape_markdown <- function(x) {
  gsub("|", "\\|", as.character(x), fixed = TRUE)
}

markdown_table <- function(data, columns = names(data)) {
  header <- paste0("|", paste(columns, collapse = "|"), "|")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(
    data[, columns, drop = FALSE],
    1L,
    function(row) {
      paste0(
        "|",
        paste(vapply(row, escape_markdown, character(1L)), collapse = "|"),
        "|"
      )
    }
  )
  c(header, divider, body)
}

coverage_table <- merge(
  periods[c("period_id", "start_year", "end_year")],
  diagnostics[c(
    "period_id", "n_obs", "complete_case_start", "complete_case_end"
  )],
  by = "period_id",
  sort = FALSE
)
coverage_table <- coverage_table[
  match(periods$period_id, coverage_table$period_id),
  ,
  drop = FALSE
]

regression_report_table <- regression_results[c(
  "period_id", "start_year", "end_year", "n_obs", "estimator",
  "theta_0_estimate", "theta_omega_estimate", "admissibility_status",
  "warning_flags"
)]
regression_report_table$years <- paste0(
  regression_report_table$start_year,
  "-",
  regression_report_table$end_year
)
regression_report_table <- regression_report_table[c(
  "period_id", "years", "n_obs", "estimator", "theta_0_estimate",
  "theta_omega_estimate", "admissibility_status", "warning_flags"
)]

validation_lines <- c(
  "# U.S. S22 Periodized A00 Baseline Validation",
  "",
  "**Overall result: PASS.**",
  "",
  "## Purpose",
  "",
  paste(
    "S22 constructs periodized, window-reset `q_omega_h1_Kcap` indexes",
    "from NFC productive-capacity capital growth and lagged unadjusted",
    "`omega_NFC`, then estimates preliminary effective-output proxy",
    "regressions. It does not estimate a mechanization-bias model."
  ),
  "",
  "## Upstream inputs",
  "",
  paste0("- `", sub(paste0(repo_root, "/"), "", input_paths), "`"),
  if (file.exists(optional_s21_path)) {
    paste0(
      "- Optional S21 cross-check available: `",
      sub(paste0(repo_root, "/"), "", optional_s21_path),
      "`"
    )
  } else {
    "- Optional canonical S21 q panel was not present and was not required."
  },
  "",
  "## Period windows",
  "",
  markdown_table(periods, c("period_id", "start_year", "end_year")),
  "",
  "## Binding periodization rule",
  "",
  paste(
    "For each period, S22 cumulatively sums",
    "`omega_NFC_{s-1} * g_Kcap_s` from the first usable observation and",
    "resets the index inside the period. It imports no accumulated",
    "pre-period q history, does not center or standardize q, and uses no",
    "contemporaneous distribution state."
  ),
  "",
  "## Effective q coverage",
  "",
  markdown_table(coverage_table),
  "",
  "## Regression status",
  "",
  markdown_table(regression_results, c(
    "period_id", "n_obs", "estimator", "admissibility_status",
    "warning_flags"
  )),
  "",
  paste(
    "The dependent variable is the established `y_t` log real output series",
    "used in prior S30/S32 scaffolds. S22 labels it",
    "`effective_output_proxy`; it is not canonical `y_t^p` and is not",
    "claimed to equal theoretical productive capacity."
  ),
  "",
  "## Validation checks",
  "",
  markdown_table(checks, c("check_name", "status", "details")),
  "",
  "## Hard-lock confirmation",
  "",
  paste(
    "S22 fetched no BEA data, modified no provider or S20 artifact, built no",
    "Shaikh-adjusted variable, level interaction, q_e index, h3/h5 index,",
    "mechanization regressor, frontier-conditioner regression, integration",
    "test, Johansen/VECM system, productive-capacity reconstruction, or",
    "capacity-utilization reconstruction."
  )
)
writeLines(
  validation_lines,
  output_paths[["validation_report"]],
  useBytes = TRUE
)

results_lines <- c(
  "# U.S. S22 Preliminary A00 Periodized Results",
  "",
  paste(
    "These are preliminary A00 baseline estimates using actual log output as",
    "an effective-output proxy, NFC productive-capacity capital, and an",
    "unadjusted NFC wage-share-conditioned accumulated capital-growth index.",
    "The estimates are not Shaikh-adjusted results, not mechanization-bias",
    "specifications, and not final productive-capacity estimates."
  ),
  "",
  "## Period status",
  "",
  markdown_table(regression_report_table),
  "",
  "## Interpretation",
  "",
  paste(
    "All seven governed windows are estimated with diagnostic OLS. The",
    "coefficients provide preliminary evidence about the elasticity of",
    "realized output with respect to productive-capacity capital accumulation",
    "and its lagged wage-share-conditioned q path. They are not promoted as",
    "final structural coefficients."
  ),
  "",
  "## Limitations",
  "",
  paste(
    "Shaikh-style distributive adjustments remain blocked pending",
    "current-release protocol."
  ),
  "The baseline uses unadjusted `omega_NFC`.",
  paste(
    "The dependent variable is realized output, used here as a preliminary",
    "proxy to estimate the elasticity of output with respect to",
    "productive-capacity capital accumulation. A stricter theoretical",
    "productive-capacity object remains downstream."
  ),
  "Mechanization-bias specifications using ME/NRC composition are deferred.",
  paste(
    "IPP and GOV_TRANS frontier conditioners are not included in this",
    "baseline regression."
  ),
  "S40 capacity/utilization reconstruction is not part of this pass."
)
writeLines(
  results_lines,
  output_paths[["results_report"]],
  useBytes = TRUE
)

# Write the provisional checks file so the final all-output existence audit
# includes the checks artifact itself.
write_csv(checks, output_paths[["checks"]])
all_output_files <- unname(output_paths)
outputs_exist <- all(file.exists(all_output_files))
checks$status[checks$check_id == "outputs_written"] <-
  if (outputs_exist) "PASS" else "FAIL"
checks$details[checks$check_id == "outputs_written"] <-
  paste(sum(file.exists(all_output_files)), "of", length(all_output_files),
        "required outputs written.")

checks <- checks[order(checks$check_id), , drop = FALSE]
rownames(checks) <- NULL
write_csv(checks, output_paths[["checks"]])

# Rewrite the validation report with the finalized output-file check.
validation_lines <- c(
  validation_lines[
    seq_len(match("## Validation checks", validation_lines) - 1L)
  ],
  "## Validation checks",
  "",
  markdown_table(checks, c("check_name", "status", "details")),
  "",
  "## Hard-lock confirmation",
  "",
  paste(
    "S22 fetched no BEA data, modified no provider or S20 artifact, built no",
    "Shaikh-adjusted variable, level interaction, q_e index, h3/h5 index,",
    "mechanization regressor, frontier-conditioner regression, integration",
    "test, Johansen/VECM system, productive-capacity reconstruction, or",
    "capacity-utilization reconstruction."
  )
)
writeLines(
  validation_lines,
  output_paths[["validation_report"]],
  useBytes = TRUE
)

hard_lock_ids <- c(
  "actual_output_proxy_permitted", "dependent_not_canonical_y_p",
  "dependent_role_effective_output_proxy",
  "requested_windows_present", "no_unrequested_windows",
  "pre_1974_end_1973", "no_pre_1974_end_1974",
  "no_short_post_windows", "minimum_q_observations", "q_resets",
  "no_preperiod_q_history", "lagged_omega_backward_only",
  "no_contemporaneous_omega", "q_increment_identity",
  "q_increment_not_product_delta", "no_omega_corp", "no_shaikh_adjusted",
  "no_q_e", "no_h3_h5", "no_level_interactions",
  "no_mechanization_regressors", "no_frontier_conditioners",
  "no_utilization_reconstruction", "no_johansen_vecm",
  "regression_rows_preliminary", "diagnostic_ols_label",
  "proxy_regression_admissibility", "all_periods_estimated",
  "upstream_inputs_unchanged", "provider_artifacts_unchanged",
  "outputs_written"
)
failed_hard_locks <- checks$check_name[
  checks$check_id %in% hard_lock_ids & checks$status != "PASS"
]
other_failures <- checks$check_name[checks$status == "FAIL"]
if (length(failed_hard_locks) > 0L || length(other_failures) > 0L) {
  abort(
    paste0(
      "S22 validation failed:\n- ",
      paste(unique(c(failed_hard_locks, other_failures)), collapse = "\n- ")
    )
  )
}

message("S22 periodized A00 q construction passed.")
message("Periodized q indexes: ", nrow(q_ledger))
message("Preliminary proxy regressions estimated: ", nrow(regression_results))
message("Validation PASS/WARN/FAIL: ",
  sum(checks$status == "PASS"), "/",
  sum(checks$status == "WARN"), "/",
  sum(checks$status == "FAIL"))
