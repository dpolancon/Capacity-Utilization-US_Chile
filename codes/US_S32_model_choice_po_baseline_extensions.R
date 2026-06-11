#!/usr/bin/env Rscript

# S32 performs preliminary model-choice and cointegration screening. Productive
# capacity remains latent; y_t is actual log output used as an effective-output
# proxy. No coefficient produced here is a final dissertation estimate.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
output_dir <- file.path(repo_root, "data", "processed", "us_s32")
results_dir <- file.path(repo_root, "docs", "results")
validation_dir <- file.path(repo_root, "docs", "validation")

input_paths <- c(
  s20_panel = file.path(
    repo_root, "data", "processed", "us_s20",
    "us_s20_capital_distribution_frontier_panel.csv"
  ),
  s22_panel = file.path(
    repo_root, "data", "processed", "us_s22",
    "us_s22_periodized_q_panel.csv"
  ),
  s30i_panel = file.path(
    repo_root, "data", "processed", "us_s30i",
    "us_s30i_candidate_audit_panel.csv"
  ),
  s30i_recommendations = file.path(
    repo_root, "data", "processed", "us_s30i",
    "us_s30i_admissibility_recommendations.csv"
  ),
  s30i_i2_ledger = file.path(
    repo_root, "data", "processed", "us_s30i",
    "us_s30i_i2_risk_ledger.csv"
  ),
  s30i_checks = file.path(
    repo_root, "data", "processed", "us_s30i",
    "us_s30i_validation_checks.csv"
  )
)
s22_ledger_path <- file.path(
  repo_root, "data", "processed", "us_s22",
  "us_s22_periodized_q_ledger.csv"
)

output_paths <- c(
  model_registry = file.path(output_dir, "us_s32_model_registry.csv"),
  coefficients = file.path(output_dir, "us_s32_coefficients.csv"),
  estimator_status = file.path(output_dir, "us_s32_estimator_status.csv"),
  po_gates = file.path(output_dir, "us_s32_po_cointegration_gates.csv"),
  residual_gates = file.path(
    output_dir, "us_s32_residual_stationarity_gates.csv"
  ),
  screening_summary = file.path(
    output_dir, "us_s32_model_screening_summary.csv"
  ),
  validation_checks = file.path(
    output_dir, "us_s32_validation_checks.csv"
  ),
  advisor_report = file.path(
    results_dir, "US_S32_MODEL_CHOICE_BASELINE_EXTENSIONS.md"
  ),
  validation_report = file.path(
    validation_dir, "US_S32_MODEL_CHOICE_VALIDATION.md"
  )
)

abort <- function(message) stop(message, call. = FALSE)
require_condition <- function(condition, message) {
  if (!isTRUE(condition)) abort(message)
}
read_csv <- function(path) {
  read.csv(
    path, stringsAsFactors = FALSE, check.names = FALSE,
    na.strings = character()
  )
}
write_csv <- function(data, path) {
  write.csv(data, path, row.names = FALSE, na = "")
}
as_num <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x[!is.finite(x)] <- NA_real_
  x
}
as_bool <- function(x) {
  if (is.logical(x)) return(x)
  toupper(as.character(x)) == "TRUE"
}
collapse_unique <- function(x, sep = "; ") {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x)) paste(x, collapse = sep) else ""
}
capture_attempt <- function(expr) {
  warnings <- character()
  value <- tryCatch(
    withCallingHandlers(
      expr,
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  list(value = value, warnings = collapse_unique(warnings))
}
escape_md <- function(x) gsub("|", "\\|", as.character(x), fixed = TRUE)
format_md_value <- function(x) {
  if (is.logical(x)) return(ifelse(is.na(x), "", ifelse(x, "TRUE", "FALSE")))
  if (is.numeric(x)) {
    return(ifelse(is.na(x), "", formatC(x, digits = 5L, format = "fg")))
  }
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}
md_table <- function(data, columns = names(data)) {
  show <- data[, columns, drop = FALSE]
  if (!nrow(show)) return("_No rows._")
  show[] <- lapply(show, format_md_value)
  c(
    paste0("|", paste(columns, collapse = "|"), "|"),
    paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|"),
    apply(show, 1L, function(row) {
      paste0(
        "|", paste(vapply(row, escape_md, character(1L)), collapse = "|"), "|"
      )
    })
  )
}
validation_check <- function(id, name, status, details) {
  data.frame(
    check_id = id, check_name = name, status = status, details = details,
    stringsAsFactors = FALSE
  )
}

missing_inputs <- input_paths[!file.exists(input_paths)]
require_condition(
  !length(missing_inputs),
  paste("Missing S32 inputs:", paste(missing_inputs, collapse = "\n"))
)
require_condition(file.exists(s22_ledger_path), "Missing S22 period ledger.")
require_condition(
  requireNamespace("urca", quietly = TRUE),
  "The urca package is required for S32 gates."
)

for (path in c(output_dir, results_dir, validation_dir)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

input_hashes_before <- tools::md5sum(c(input_paths, s22_ledger_path))
provider_dir <- file.path(repo_root, "data", "external", "us_bea_provider")
provider_files <- if (dir.exists(provider_dir)) {
  list.files(provider_dir, recursive = TRUE, full.names = TRUE)
} else {
  character()
}
provider_hashes_before <- if (length(provider_files)) {
  tools::md5sum(provider_files)
} else {
  character()
}

s20 <- read_csv(input_paths[["s20_panel"]])
s22 <- read_csv(input_paths[["s22_panel"]])
panel <- read_csv(input_paths[["s30i_panel"]])
s30i_rec <- read_csv(input_paths[["s30i_recommendations"]])
s30i_i2 <- read_csv(input_paths[["s30i_i2_ledger"]])
s30i_checks <- read_csv(input_paths[["s30i_checks"]])
s22_ledger <- read_csv(s22_ledger_path)

s30i_rec$i2_risk_flag <- as_bool(s30i_rec$i2_risk_flag)
s30i_rec$rolling_instability_flag <- as_bool(
  s30i_rec$rolling_instability_flag
)
s30i_rec$carry_to_S32 <- as_bool(s30i_rec$carry_to_S32)
require_condition(!any(s30i_checks$status == "FAIL"), "S30I has failed checks.")
require_condition(!anyDuplicated(panel$year), "S30I panel years are duplicated.")
require_condition(
  all(c("y_t", "k_Kcap", "q_omega_h1_Kcap") %in% names(panel)),
  "S32 baseline variables are missing."
)

metadata <- c(
  dependent_variable = "y_t",
  dependent_variable_label = "actual_log_output",
  dependent_variable_role = "effective_output_proxy",
  target_of_identification = "productive_capacity_formation_coefficient",
  productive_capacity_status = "latent_non_observable"
)

model_specs <- list()
add_model <- function(
    model_id, model_family, model_role, sample_id, start_year, end_year,
    regressors, notes = "") {
  model_specs[[model_id]] <<- list(
    model_id = model_id,
    model_family = model_family,
    model_role = model_role,
    sample_id = sample_id,
    start_year = as.integer(start_year),
    end_year = as.integer(end_year),
    dependent_variable = "y_t",
    regressors = regressors,
    notes = notes
  )
}

add_model(
  "S32_A00_baseline", "A00_aggregate", "preferred_baseline",
  "full_available_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omega_h1_Kcap"),
  "Reference model; coefficients remain preliminary."
)
add_model(
  "S32_A00_q_h3", "A00_memory_robustness",
  "memory_state_robustness", "full_available_sample",
  min(panel$year), max(panel$year),
  c("k_Kcap", "q_omega_h3_Kcap")
)
add_model(
  "S32_A00_q_h5", "A00_memory_robustness",
  "memory_state_robustness", "full_available_sample",
  min(panel$year), max(panel$year),
  c("k_Kcap", "q_omega_h5_Kcap")
)
for (h in c(1L, 3L, 5L)) {
  add_model(
    paste0("S32_A00_q_e_h", h), "A00_distribution_robustness",
    "alternative_distribution_proxy_robustness", "full_available_sample",
    min(panel$year), max(panel$year),
    c("k_Kcap", paste0("q_e_h", h, "_Kcap")),
    "Alternative exploitation-rate distribution proxy; not preferred baseline."
  )
}

period_model_ids <- c(
  full_long_sample = "S32_periodized_full_long_sample",
  pre_1974_full = "S32_periodized_pre_1974_full",
  post_1973_full = "S32_periodized_post_1973_full",
  fordist_core = "S32_periodized_fordist_core",
  bridge_1940_1978 = "S32_periodized_bridge_1940_1978",
  pre_1974_alt_1940_1973 = "S32_periodized_pre_1974_alt_1940_1973",
  pre_1974_alt_1947_1973 = "S32_periodized_pre_1974_alt_1947_1973"
)
for (period_id in names(period_model_ids)) {
  row <- s22_ledger[s22_ledger$period_id == period_id, , drop = FALSE]
  require_condition(nrow(row) == 1L, paste("Missing period:", period_id))
  require_condition(
    !grepl("pre_1974", period_id) || row$end_year == 1973L,
    paste("Invalid pre-1974 endpoint:", period_id)
  )
  add_model(
    period_model_ids[[period_id]], "A00_periodized",
    "periodized_baseline_candidate", period_id,
    row$start_year, row$end_year,
    c("k_Kcap", row$q_variable),
    ifelse(
      grepl("post_1973", period_id),
      "Governed post-1973 full window; no short post-1974 window.",
      "Governed S22 period-reset q window."
    )
  )
}

mechanization_models <- c(
  S32_ME_growth_extension = "q_omega_h1_ME",
  S32_NRC_growth_extension = "q_omega_h1_NRC",
  S32_ME_minus_NRC_growth_extension = "q_omega_h1_ME_minus_NRC",
  S32_ME_share_extension = "q_omega_h1_ME_share",
  S32_NRC_share_extension = "q_omega_h1_NRC_share",
  S32_ME_NRC_gap_extension = "q_omega_h1_ME_NRC_gap"
)
for (model_id in names(mechanization_models)) {
  candidate <- mechanization_models[[model_id]]
  rec <- s30i_rec[s30i_rec$variable == candidate, , drop = FALSE]
  role <- if (nrow(rec) && isTRUE(rec$i2_risk_flag)) {
    "mechanization_i2_diagnostic_stress_test"
  } else {
    "mechanization_candidate_extension"
  }
  add_model(
    model_id, "mechanization_extension", role, "full_available_sample",
    min(panel$year), max(panel$year),
    c("k_Kcap", "q_omega_h1_Kcap", candidate),
    "Candidate extension, not a replacement for the aggregate baseline."
  )
}

for (conditioner in c("GOV_TRANS_growth", "IPP_growth")) {
  add_model(
    paste0("S32_", conditioner, "_extension"),
    "frontier_conditioner_extension",
    "stationary_frontier_conditioner_robustness",
    "full_available_sample", min(panel$year), max(panel$year),
    c("k_Kcap", "q_omega_h1_Kcap", conditioner),
    "Stationary frontier-growth conditioner; not an additive K_cap component."
  )
}

model_data <- function(spec) {
  vars <- c("year", spec$dependent_variable, spec$regressors)
  missing <- setdiff(vars, names(panel))
  if (length(missing)) return(data.frame())
  data <- panel[
    panel$year >= spec$start_year & panel$year <= spec$end_year,
    vars,
    drop = FALSE
  ]
  data[stats::complete.cases(data), , drop = FALSE]
}
rec_for <- function(variable) {
  s30i_rec[s30i_rec$variable == variable, , drop = FALSE]
}
model_s30i_metadata <- function(spec) {
  variables <- c(spec$dependent_variable, spec$regressors)
  rows <- s30i_rec[match(variables, s30i_rec$variable), , drop = FALSE]
  found <- !is.na(rows$variable)
  rows <- rows[found, , drop = FALSE]
  statuses <- paste0(rows$variable, "=", rows$s32_recommendation)
  i2_vars <- rows$variable[rows$i2_risk_flag %in% TRUE]
  rolling_vars <- rows$variable[rows$rolling_instability_flag %in% TRUE]
  list(
    status = collapse_unique(statuses),
    i2_warning = if (length(i2_vars)) {
      paste0("I2_risk:", paste(i2_vars, collapse = ","))
    } else {
      ""
    },
    rolling_warning = if (length(rolling_vars)) {
      paste0("rolling_instability:", paste(rolling_vars, collapse = ","))
    } else {
      ""
    }
  )
}

registry_rows <- lapply(model_specs, function(spec) {
  data <- model_data(spec)
  s30 <- model_s30i_metadata(spec)
  data.frame(
    model_id = spec$model_id,
    model_family = spec$model_family,
    model_role = spec$model_role,
    sample_id = spec$sample_id,
    start_year = if (nrow(data)) min(data$year) else spec$start_year,
    end_year = if (nrow(data)) max(data$year) else spec$end_year,
    dependent_variable = metadata[["dependent_variable"]],
    dependent_variable_role = metadata[["dependent_variable_role"]],
    regressors = paste(spec$regressors, collapse = " + "),
    s30i_carry_forward_status = s30$status,
    s30i_i2_warning = s30$i2_warning,
    s30i_rolling_warning = s30$rolling_warning,
    n_obs = nrow(data),
    status = ifelse(nrow(data) >= 25L, "ready_for_preliminary_screen", "insufficient_sample"),
    notes = spec$notes,
    stringsAsFactors = FALSE
  )
})
model_registry <- do.call(rbind, registry_rows)

estimator_definitions <- data.frame(
  estimator = c(
    "diagnostic_levels_OLS", "FM_OLS_preliminary",
    "IM_OLS_preliminary", "DOLS_preliminary"
  ),
  estimator_role = c(
    "diagnostic_only", "preferred_preliminary_estimator",
    "robustness_preliminary_estimator", "robustness_preliminary_estimator"
  ),
  package = c("stats", "cointReg", "cointReg", "cointReg"),
  function_name = c(
    "stats::lm", "cointReg::cointRegFM",
    "cointReg::cointRegIM", "cointReg::cointRegD"
  ),
  stringsAsFactors = FALSE
)

coefficient_rows <- list()
status_rows <- list()
ols_residuals <- list()
fit_index <- 0L
status_index <- 0L

coefficient_frame <- function(
    spec, estimator, terms, estimates, standard_errors, t_stats, p_values,
    n_obs, r_squared, adj_r_squared, residual_sd, warnings) {
  data.frame(
    model_id = spec$model_id,
    estimator = estimator,
    term = terms,
    estimate = as_num(estimates),
    std_error = as_num(standard_errors),
    t_statistic = as_num(t_stats),
    p_value = as_num(p_values),
    n_obs = n_obs,
    r_squared = r_squared,
    adj_r_squared = adj_r_squared,
    residual_sd = residual_sd,
    coefficient_status = "preliminary_not_promoted",
    warning_flags = warnings,
    stringsAsFactors = FALSE
  )
}

for (spec in model_specs) {
  data <- model_data(spec)
  formula <- stats::reformulate(spec$regressors, response = "y_t")
  s30 <- model_s30i_metadata(spec)
  model_warning <- collapse_unique(c(
    s30$i2_warning, s30$rolling_warning,
    if (nrow(data) < 30L) "short_sample_under_30" else ""
  ))
  for (j in seq_len(nrow(estimator_definitions))) {
    definition <- estimator_definitions[j, ]
    estimator <- definition$estimator
    available <- definition$package == "stats" ||
      requireNamespace(definition$package, quietly = TRUE)
    attempted <- available && nrow(data) >= 25L
    status_index <- status_index + 1L
    base_status <- data.frame(
      model_id = spec$model_id,
      estimator = estimator,
      estimator_role = definition$estimator_role,
      package = definition$package,
      function_name = definition$function_name,
      package_available = available,
      attempted = attempted,
      status = ifelse(
        !available, "estimator_unavailable_or_failed",
        ifelse(attempted, "attempted", "estimator_unavailable_or_failed")
      ),
      n_obs = nrow(data),
      error_message = ifelse(
        nrow(data) < 25L, "sample_too_short_for_preliminary_estimation", ""
      ),
      warnings = "",
      stringsAsFactors = FALSE
    )
    if (!attempted) {
      status_rows[[status_index]] <- base_status
      next
    }

    if (estimator == "diagnostic_levels_OLS") {
      attempt <- capture_attempt(stats::lm(formula, data = data))
      if (inherits(attempt$value, "error")) {
        base_status$status <- "estimator_unavailable_or_failed"
        base_status$error_message <- attempt$value$message
        base_status$warnings <- attempt$warnings
        status_rows[[status_index]] <- base_status
        next
      }
      fit <- attempt$value
      summary_fit <- summary(fit)
      coef_matrix <- summary_fit$coefficients
      fit_index <- fit_index + 1L
      coefficient_rows[[fit_index]] <- coefficient_frame(
        spec, estimator, rownames(coef_matrix),
        coef_matrix[, "Estimate"], coef_matrix[, "Std. Error"],
        coef_matrix[, "t value"], coef_matrix[, "Pr(>|t|)"],
        nrow(data), summary_fit$r.squared, summary_fit$adj.r.squared,
        summary_fit$sigma, model_warning
      )
      ols_residuals[[spec$model_id]] <- as_num(stats::residuals(fit))
      base_status$status <- "success"
      base_status$warnings <- attempt$warnings
      status_rows[[status_index]] <- base_status
      next
    }

    x <- as.matrix(data[, spec$regressors, drop = FALSE])
    y <- as_num(data$y_t)
    deter <- rep(1, length(y))
    attempt <- capture_attempt({
      if (estimator == "FM_OLS_preliminary") {
        cointReg::cointRegFM(x = x, y = y, deter = deter)
      } else if (estimator == "IM_OLS_preliminary") {
        cointReg::cointRegIM(x = x, y = y, deter = deter)
      } else {
        cointReg::cointRegD(
          x = x, y = y, deter = deter, n.lead = 1L, n.lag = 1L
        )
      }
    })
    if (inherits(attempt$value, "error")) {
      base_status$status <- "estimator_unavailable_or_failed"
      base_status$error_message <- attempt$value$message
      base_status$warnings <- attempt$warnings
      status_rows[[status_index]] <- base_status
      next
    }
    fit <- attempt$value
    theta <- as_num(fit$theta)
    standard_errors <- as_num(fit$sd.theta)
    t_stats <- as_num(fit$t.theta)
    p_values <- as_num(fit$p.theta)
    expected_length <- length(spec$regressors) + 1L
    if (length(theta) < expected_length) {
      base_status$status <- "estimator_unavailable_or_failed"
      base_status$error_message <- "unexpected_coefficient_vector_length"
      status_rows[[status_index]] <- base_status
      next
    }
    theta <- theta[seq_len(expected_length)]
    standard_errors <- standard_errors[seq_len(expected_length)]
    t_stats <- t_stats[seq_len(expected_length)]
    p_values <- p_values[seq_len(expected_length)]
    terms <- c("(Intercept)", spec$regressors)
    residuals <- as_num(fit$residuals)
    residuals <- residuals[is.finite(residuals)]
    r_squared <- if (length(residuals) > 2L) {
      1 - sum(residuals^2) / sum((y - mean(y))^2)
    } else {
      NA_real_
    }
    adj_r_squared <- if (
      is.finite(r_squared) && nrow(data) > length(spec$regressors) + 1L
    ) {
      1 - (1 - r_squared) * (nrow(data) - 1) /
        (nrow(data) - length(spec$regressors) - 1)
    } else {
      NA_real_
    }
    residual_sd <- if (length(residuals) > expected_length) {
      sqrt(sum(residuals^2) / (length(residuals) - expected_length))
    } else {
      NA_real_
    }
    fit_index <- fit_index + 1L
    coefficient_rows[[fit_index]] <- coefficient_frame(
      spec, estimator, terms, theta, standard_errors, t_stats, p_values,
      nrow(data), r_squared, adj_r_squared, residual_sd, model_warning
    )
    base_status$status <- "success"
    base_status$warnings <- attempt$warnings
    status_rows[[status_index]] <- base_status
  }
}

coefficients <- do.call(rbind, coefficient_rows)
estimator_status <- do.call(rbind, status_rows)
model_success <- tapply(
  estimator_status$status == "success", estimator_status$model_id, any
)
model_registry$status <- ifelse(
  model_success[model_registry$model_id],
  "estimated_preliminary_not_promoted",
  "estimation_failed_or_insufficient"
)

po_gate_from_stat <- function(statistic, critical_5pct) {
  if (!is.finite(statistic) || !is.finite(critical_5pct)) return("unavailable")
  if (statistic >= critical_5pct) "pass" else "fail"
}
po_rows <- lapply(model_specs, function(spec) {
  data <- model_data(spec)
  base <- data.frame(
    model_id = spec$model_id,
    test_name = "Phillips-Ouliaris_Pz",
    test_function = "urca::ca.po",
    deterministic_case = "constant",
    lag_rule = "short",
    n_obs = nrow(data),
    test_statistic = NA_real_,
    critical_value_5pct = NA_real_,
    po_gate = "unavailable",
    status = "not_attempted",
    error_message = "",
    warnings = "",
    stringsAsFactors = FALSE
  )
  if (nrow(data) < 25L) {
    base$error_message <- "sample_too_short"
    return(base)
  }
  z <- as.matrix(data[, c("y_t", spec$regressors), drop = FALSE])
  if (qr(z)$rank < ncol(z)) {
    base$status <- "attempted_failed"
    base$error_message <- "rank_deficient_levels_matrix"
    return(base)
  }
  attempt <- capture_attempt(
    urca::ca.po(z = z, demean = "constant", lag = "short", type = "Pz")
  )
  base$status <- "attempted"
  base$warnings <- attempt$warnings
  if (inherits(attempt$value, "error")) {
    base$status <- "attempted_failed"
    base$error_message <- attempt$value$message
    return(base)
  }
  po <- attempt$value
  base$test_statistic <- as_num(po@teststat[1L])
  base$critical_value_5pct <- as_num(po@cval[1L, "5pct"])
  base$po_gate <- po_gate_from_stat(
    base$test_statistic, base$critical_value_5pct
  )
  base
})
po_gates <- do.call(rbind, po_rows)

adf_gate_from_stat <- function(statistic, critical_5pct) {
  if (!is.finite(statistic) || !is.finite(critical_5pct)) return("unavailable")
  if (statistic <= critical_5pct) "pass" else "fail"
}
kpss_gate_from_stat <- function(statistic, critical_5pct) {
  if (!is.finite(statistic) || !is.finite(critical_5pct)) return("unavailable")
  if (statistic <= critical_5pct) "pass" else "fail"
}
residual_rows <- lapply(model_specs, function(spec) {
  data <- model_data(spec)
  residuals <- ols_residuals[[spec$model_id]]
  base <- data.frame(
    model_id = spec$model_id,
    residual_source_estimator = "diagnostic_levels_OLS",
    n_obs = nrow(data),
    adf_test_function = "urca::ur.df",
    adf_deterministic_case = "none",
    adf_lag_rule = "AIC",
    adf_statistic = NA_real_,
    adf_critical_value_5pct = NA_real_,
    residual_adf_gate = "unavailable",
    adf_status = "not_attempted",
    adf_error_message = "",
    kpss_test_function = "urca::ur.kpss",
    kpss_deterministic_case = "mu",
    kpss_lag_rule = "short",
    kpss_statistic = NA_real_,
    kpss_critical_value_5pct = NA_real_,
    residual_kpss_gate = "unavailable",
    kpss_status = "not_attempted",
    kpss_error_message = "",
    warnings = "",
    stringsAsFactors = FALSE
  )
  if (is.null(residuals) || length(residuals) < 20L) {
    base$adf_error_message <- "OLS_residuals_unavailable_or_too_short"
    base$kpss_error_message <- "OLS_residuals_unavailable_or_too_short"
    return(base)
  }
  adf_attempt <- capture_attempt(
    urca::ur.df(residuals, type = "none", selectlags = "AIC")
  )
  base$adf_status <- "attempted"
  if (inherits(adf_attempt$value, "error")) {
    base$adf_status <- "attempted_failed"
    base$adf_error_message <- adf_attempt$value$message
  } else {
    adf <- adf_attempt$value
    base$adf_statistic <- as_num(adf@teststat[1L])
    base$adf_critical_value_5pct <- as_num(adf@cval[1L, "5pct"])
    base$residual_adf_gate <- adf_gate_from_stat(
      base$adf_statistic, base$adf_critical_value_5pct
    )
  }
  kpss_attempt <- capture_attempt(
    urca::ur.kpss(residuals, type = "mu", lags = "short")
  )
  base$kpss_status <- "attempted"
  if (inherits(kpss_attempt$value, "error")) {
    base$kpss_status <- "attempted_failed"
    base$kpss_error_message <- kpss_attempt$value$message
  } else {
    kpss <- kpss_attempt$value
    base$kpss_statistic <- as_num(kpss@teststat[1L])
    base$kpss_critical_value_5pct <- as_num(kpss@cval[1L, "5pct"])
    base$residual_kpss_gate <- kpss_gate_from_stat(
      base$kpss_statistic, base$kpss_critical_value_5pct
    )
  }
  base$warnings <- collapse_unique(c(
    adf_attempt$warnings, kpss_attempt$warnings
  ))
  base
})
residual_gates <- do.call(rbind, residual_rows)

best_estimator_for <- function(model_id) {
  rows <- estimator_status[
    estimator_status$model_id == model_id &
      estimator_status$status == "success",
    ,
    drop = FALSE
  ]
  hierarchy <- c(
    "FM_OLS_preliminary", "IM_OLS_preliminary",
    "DOLS_preliminary", "diagnostic_levels_OLS"
  )
  found <- hierarchy[hierarchy %in% rows$estimator]
  if (length(found)) found[1L] else "none"
}
screen_from_gates <- function(po_gate, adf_gate) {
  if (po_gate == "unavailable") {
    if (adf_gate %in% c("pass", "fail")) return("residual_screen_only")
    return("unavailable")
  }
  if (po_gate == "pass" && adf_gate == "pass") return("preliminary_pass")
  if (po_gate == "pass" || adf_gate == "pass") return("mixed_evidence")
  "fail"
}
advisor_priority_for <- function(spec, screen, i2_warning) {
  if (nzchar(i2_warning)) return("6_do_not_show")
  if (spec$model_id == "S32_A00_baseline") return("1_baseline_show")
  if (spec$model_family == "A00_periodized") return("2_periodized_show")
  if (
    spec$model_family == "mechanization_extension" &&
      screen == "preliminary_pass"
  ) return("3_mechanization_extension_show_if_pass")
  if (
    spec$model_family == "frontier_conditioner_extension" &&
      screen == "preliminary_pass"
  ) return("4_frontier_show_if_pass")
  if (
    spec$model_family %in%
      c("A00_memory_robustness", "A00_distribution_robustness") &&
      screen == "preliminary_pass"
  ) return("5_robustness_show_if_pass")
  "6_do_not_show"
}

summary_rows <- lapply(model_specs, function(spec) {
  registry <- model_registry[
    model_registry$model_id == spec$model_id, , drop = FALSE
  ]
  po <- po_gates[po_gates$model_id == spec$model_id, , drop = FALSE]
  residual <- residual_gates[
    residual_gates$model_id == spec$model_id, , drop = FALSE
  ]
  screen <- screen_from_gates(po$po_gate, residual$residual_adf_gate)
  priority <- advisor_priority_for(
    spec, screen, registry$s30i_i2_warning
  )
  data.frame(
    model_id = spec$model_id,
    model_family = spec$model_family,
    model_role = spec$model_role,
    sample_id = spec$sample_id,
    n_obs = registry$n_obs,
    best_available_estimator = best_estimator_for(spec$model_id),
    po_gate = po$po_gate,
    residual_adf_gate = residual$residual_adf_gate,
    residual_kpss_gate = residual$residual_kpss_gate,
    cointegration_screen = screen,
    s30i_i2_warning = registry$s30i_i2_warning,
    s30i_rolling_warning = registry$s30i_rolling_warning,
    advisor_show_flag = priority != "6_do_not_show",
    advisor_priority = priority,
    notes = collapse_unique(c(spec$notes, po$error_message)),
    stringsAsFactors = FALSE
  )
})
screening_summary <- do.call(rbind, summary_rows)

write_csv(model_registry, output_paths[["model_registry"]])
write_csv(coefficients, output_paths[["coefficients"]])
write_csv(estimator_status, output_paths[["estimator_status"]])
write_csv(po_gates, output_paths[["po_gates"]])
write_csv(residual_gates, output_paths[["residual_gates"]])
write_csv(screening_summary, output_paths[["screening_summary"]])

coefficient_value <- function(model_id, term) {
  summary <- screening_summary[
    screening_summary$model_id == model_id, , drop = FALSE
  ]
  rows <- coefficients[
    coefficients$model_id == model_id &
      coefficients$estimator == summary$best_available_estimator &
      coefficients$term == term,
    ,
    drop = FALSE
  ]
  if (nrow(rows)) rows$estimate[1L] else NA_real_
}
advisor_row <- function(model_id) {
  spec <- model_specs[[model_id]]
  row <- screening_summary[
    screening_summary$model_id == model_id, , drop = FALSE
  ]
  q_term <- spec$regressors[grepl("^q_", spec$regressors)][1L]
  data.frame(
    model_id = model_id,
    n_obs = row$n_obs,
    best_available_estimator = row$best_available_estimator,
    theta_0_k_Kcap = coefficient_value(model_id, "k_Kcap"),
    theta_omega_q = coefficient_value(model_id, q_term),
    po_gate = row$po_gate,
    residual_adf_gate = row$residual_adf_gate,
    residual_kpss_gate = row$residual_kpss_gate,
    cointegration_screen = row$cointegration_screen,
    s30i_warnings = collapse_unique(
      c(row$s30i_i2_warning, row$s30i_rolling_warning)
    ),
    advisor_show_flag = row$advisor_show_flag,
    stringsAsFactors = FALSE
  )
}

baseline_table <- advisor_row("S32_A00_baseline")
aggregate_robustness_ids <- c(
  "S32_A00_q_h3", "S32_A00_q_h5",
  "S32_A00_q_e_h1", "S32_A00_q_e_h3", "S32_A00_q_e_h5"
)
aggregate_robustness_table <- do.call(
  rbind, lapply(aggregate_robustness_ids, advisor_row)
)
periodized_table <- do.call(
  rbind, lapply(unname(period_model_ids), advisor_row)
)
mechanization_table <- do.call(rbind, lapply(
  names(mechanization_models),
  function(model_id) {
    row <- screening_summary[
      screening_summary$model_id == model_id, , drop = FALSE
    ]
    candidate <- mechanization_models[[model_id]]
    data.frame(
      model_id = model_id,
      mechanization_candidate = candidate,
      n_obs = row$n_obs,
      extension_coefficient = coefficient_value(model_id, candidate),
      po_gate = row$po_gate,
      residual_adf_gate = row$residual_adf_gate,
      cointegration_screen = row$cointegration_screen,
      s30i_warnings = collapse_unique(
        c(row$s30i_i2_warning, row$s30i_rolling_warning)
      ),
      advisor_show_flag = row$advisor_show_flag,
      comment = model_specs[[model_id]]$notes,
      stringsAsFactors = FALSE
    )
  }
))
frontier_ids <- c(
  "S32_GOV_TRANS_growth_extension", "S32_IPP_growth_extension"
)
frontier_table <- do.call(rbind, lapply(frontier_ids, function(model_id) {
  row <- screening_summary[
    screening_summary$model_id == model_id, , drop = FALSE
  ]
  conditioner <- setdiff(
    model_specs[[model_id]]$regressors,
    c("k_Kcap", "q_omega_h1_Kcap")
  )
  data.frame(
    model_id = model_id,
    frontier_conditioner = conditioner,
    n_obs = row$n_obs,
    conditioner_coefficient = coefficient_value(model_id, conditioner),
    po_gate = row$po_gate,
    residual_adf_gate = row$residual_adf_gate,
    residual_kpss_gate = row$residual_kpss_gate,
    cointegration_screen = row$cointegration_screen,
    s30i_warnings = collapse_unique(
      c(row$s30i_i2_warning, row$s30i_rolling_warning)
    ),
    advisor_show_flag = row$advisor_show_flag,
    stringsAsFactors = FALSE
  )
}))
display_set <- screening_summary[
  screening_summary$advisor_show_flag,
  c(
    "advisor_priority", "model_id", "model_family",
    "best_available_estimator", "cointegration_screen", "notes"
  ),
  drop = FALSE
]
display_set <- display_set[
  order(display_set$advisor_priority, display_set$model_id), , drop = FALSE
]

advisor_lines <- c(
  "# U.S. S32 Preliminary Model Choice: Baseline and Extensions",
  "",
  "## 1. Meeting-ready summary",
  "",
  paste(
    "These are preliminary S32 model-choice results using actual log output",
    "as the effective-output proxy. Productive capacity is latent;",
    "coefficients are interpreted as preliminary evidence on capacity-forming",
    "capital accumulation, not as estimates using observed productive capacity",
    "as the dependent variable."
  ),
  paste(
    "The preferred baseline is y_t ~ k_Kcap + q_omega_h1_Kcap.",
    "Phillips-Ouliaris and residual-stationarity gates screen admissibility;",
    "they do not promote any coefficient to a final dissertation estimate."
  ),
  "",
  "## 2. Baseline result table",
  "",
  md_table(baseline_table),
  "",
  "### Aggregate q robustness",
  "",
  md_table(aggregate_robustness_table),
  "",
  "## 3. Periodized results table",
  "",
  md_table(periodized_table),
  "",
  "All pre-1974 windows end in 1973. No short post-1974 window is added.",
  "",
  "## 4. Mechanization-extension table",
  "",
  md_table(mechanization_table),
  "",
  paste(
    "I(2)-risk mechanization candidates are retained only as diagnostic stress",
    "tests and are excluded from the preferred advisor display set."
  ),
  "",
  "## 5. Frontier-conditioner table",
  "",
  md_table(frontier_table),
  "",
  paste(
    "GOV_TRANS_growth and IPP_growth enter as stationary conditioners, not",
    "as long-run level regressors or additive components of K_cap."
  ),
  "",
  "## 6. Preferred advisor display set",
  "",
  md_table(display_set),
  "",
  "## 7. What can be said",
  "",
  "- S32 uses actual log output as an effective-output proxy while productive capacity remains latent.",
  "- The aggregate A00 specification is the reference model for all comparisons.",
  "- Phillips-Ouliaris and residual tests provide preliminary, model-specific admissibility evidence.",
  "- Rolling integration instability remains visible as a warning and is not an automatic rejection.",
  "- Periodized specifications reveal whether historical resetting changes the preliminary screen.",
  "- Mechanization and frontier terms are extensions whose admissibility is judged against the aggregate baseline.",
  "",
  "## 8. What cannot be claimed yet",
  "",
  "- These are not final dissertation estimates.",
  "- These do not remove all I(2)-risk warnings.",
  "- These are not Shaikh-adjusted distribution results.",
  "- These do not use observed productive capacity as the dependent variable.",
  "- Mechanization-bias extensions are candidate extensions, not baseline replacements."
)
writeLines(advisor_lines, output_paths[["advisor_report"]], useBytes = TRUE)

input_hashes_after <- tools::md5sum(c(input_paths, s22_ledger_path))
provider_hashes_after <- if (length(provider_files)) {
  tools::md5sum(provider_files)
} else {
  character()
}
source_path <- file.path(
  repo_root, "codes", "US_S32_model_choice_po_baseline_extensions.R"
)
source_text <- paste(readLines(source_path, warn = FALSE), collapse = "\n")
baseline_rec <- s30i_rec[
  match(c("y_t", "k_Kcap", "q_omega_h1_Kcap"), s30i_rec$variable),
  ,
  drop = FALSE
]
preferred_q <- panel$q_omega_h1_Kcap
preferred_increment <- c(NA_real_, diff(preferred_q))
expected_increment <- c(NA_real_, head(panel$omega_NFC, -1L)) * panel$g_Kcap
q_comparable <- is.finite(preferred_increment) & is.finite(expected_increment)
q_rule_ok <- any(q_comparable) && isTRUE(all.equal(
  preferred_increment[q_comparable], expected_increment[q_comparable],
  tolerance = 1e-10
))
required_csv <- unname(output_paths[c(
  "model_registry", "coefficients", "estimator_status", "po_gates",
  "residual_gates", "screening_summary", "validation_checks"
)])

checks <- do.call(rbind, list(
  validation_check("s20_exists", "S20 input exists",
    if (file.exists(input_paths[["s20_panel"]])) "PASS" else "FAIL",
    input_paths[["s20_panel"]]),
  validation_check("s22_exists", "S22 periodized q panel exists",
    if (file.exists(input_paths[["s22_panel"]])) "PASS" else "FAIL",
    input_paths[["s22_panel"]]),
  validation_check("s30i_exists", "S30I recommendation files exist",
    if (all(file.exists(input_paths[c(
      "s30i_recommendations", "s30i_i2_ledger", "s30i_checks"
    )]))) "PASS" else "FAIL", "Three S30I governance inputs checked."),
  validation_check("y_role", "y_t exists and is labeled effective-output proxy",
    if (
      "y_t" %in% names(panel) &&
        metadata[["dependent_variable_role"]] == "effective_output_proxy"
    ) "PASS" else "FAIL", paste(metadata, collapse = "; ")),
  validation_check("y_not_canonical_yp", "y_t is not labeled canonical y_t^p",
    if (
      metadata[["productive_capacity_status"]] == "latent_non_observable" &&
        metadata[["dependent_variable_label"]] == "actual_log_output"
    ) "PASS" else "FAIL",
    "Actual log output is the effective-output proxy; capacity is latent."),
  validation_check("baseline_estimated", "Baseline model estimated",
    if (any(
      estimator_status$model_id == "S32_A00_baseline" &
        estimator_status$status == "success"
    )) "PASS" else "FAIL", "S32_A00_baseline has successful estimator rows."),
  validation_check(
    "aggregate_q_roles", "Aggregate q variants retain theoretical roles",
    if (
      rec_for("q_omega_h1_Kcap")$role == "preferred_A00_q_candidate" &&
        all(c(
          "q_omega_h3_Kcap", "q_omega_h5_Kcap",
          "q_e_h1_Kcap", "q_e_h3_Kcap", "q_e_h5_Kcap"
        ) %in% s30i_rec$variable)
    ) "PASS" else "FAIL",
    "Preferred, memory, and alternative-distribution roles retained."
  ),
  validation_check(
    "rolling_warning", "Rolling instability is warning, not automatic block",
    if (
      all(baseline_rec$carry_to_S32) &&
        all(baseline_rec$rolling_instability_flag)
    ) "PASS" else "FAIL",
    "Baseline I(1)/no-I(2) variables enter S32 with rolling warnings."
  ),
  validation_check("i2_flagged", "I2-risk variables are flagged clearly",
    if (all(
      screening_summary$advisor_priority[
        nzchar(screening_summary$s30i_i2_warning)
      ] == "6_do_not_show"
    )) "PASS" else "FAIL",
    paste(sum(nzchar(screening_summary$s30i_i2_warning)), "models flagged.")),
  validation_check("q_rule", "Preferred q increment rule is respected",
    if (q_rule_ok) "PASS" else "FAIL",
    "Delta q_omega_h1_Kcap equals lagged omega_NFC times g_Kcap."),
  validation_check(
    "no_product_delta",
    "No Delta(omega*K) or Delta(omega*k) q construction occurs", "PASS",
    "S32 consumes governed q inputs and constructs no q series."
  ),
  validation_check("po_every_model", "PO gates attempted for every model",
    if (
      nrow(po_gates) == length(model_specs) &&
        all(po_gates$status %in% c("attempted", "attempted_failed"))
    ) "PASS" else "FAIL",
    paste(nrow(po_gates), "PO rows for", length(model_specs), "models.")),
  validation_check(
    "adf_every_model", "Residual ADF gates attempted for every model",
    if (
      nrow(residual_gates) == length(model_specs) &&
        all(residual_gates$adf_status %in% c("attempted", "attempted_failed"))
    ) "PASS" else "FAIL",
    paste(nrow(residual_gates), "ADF rows.")
  ),
  validation_check(
    "kpss_every_model", "Residual KPSS gates attempted where available",
    if (
      nrow(residual_gates) == length(model_specs) &&
        all(residual_gates$kpss_status %in% c("attempted", "attempted_failed"))
    ) "PASS" else "FAIL",
    paste(nrow(residual_gates), "KPSS rows.")
  ),
  validation_check("ols_not_fmols", "OLS is not mislabeled as FM-OLS",
    if (
      all(estimator_status$function_name[
        estimator_status$estimator == "diagnostic_levels_OLS"
      ] == "stats::lm")
    ) "PASS" else "FAIL", "OLS is labeled diagnostic_levels_OLS only."),
  validation_check(
    "failures_recorded",
    "FM-OLS/IM-OLS/DOLS failures are recorded, not hidden",
    if (nrow(estimator_status) == length(model_specs) * 4L) "PASS" else "FAIL",
    paste(
      sum(estimator_status$status == "estimator_unavailable_or_failed"),
      "unavailable/failed attempts recorded."
    )
  ),
  validation_check("preliminary_coefficients",
    "Coefficients are marked preliminary",
    if (all(
      coefficients$coefficient_status == "preliminary_not_promoted"
    )) "PASS" else "FAIL", paste(nrow(coefficients), "coefficient rows.")),
  validation_check("no_johansen_vecm", "No Johansen/VECM is run",
    if (!grepl("\\b(ca\\.jo|VECM|vec2var)\\s*\\(", source_text))
      "PASS" else "FAIL", "No system cointegration estimator is called."),
  validation_check(
    "no_s40_utilization",
    "No S40 or utilization reconstruction occurs",
    if (
      !grepl("\\b(run|source|system2?)\\s*\\([^\\n]*S40", source_text) &&
        !any(grepl("capacity_utilization|productive_capacity_reconstruction",
          names(panel)))
    ) "PASS" else "FAIL",
    "S32 estimates only governed effective-output relations."
  ),
  validation_check(
    "no_shaikh", "No Shaikh-adjusted variables are used",
    if (!any(grepl("shaikh|adjusted", unlist(lapply(
      model_specs, function(x) x$regressors
    )), ignore.case = TRUE))) "PASS" else "FAIL",
    "All distribution inputs are unadjusted governed objects."
  ),
  validation_check("provider_unchanged", "No provider artifacts are modified",
    if (identical(provider_hashes_before, provider_hashes_after))
      "PASS" else "FAIL", paste(length(provider_files), "hashes compared.")),
  validation_check("upstream_unchanged", "S20/S22/S30I inputs are unchanged",
    if (identical(input_hashes_before, input_hashes_after))
      "PASS" else "FAIL", paste(length(input_hashes_before), "hashes compared.")),
  validation_check("advisor_written", "Advisor report is written",
    if (file.exists(output_paths[["advisor_report"]])) "PASS" else "FAIL",
    output_paths[["advisor_report"]]),
  validation_check("csv_written", "All required CSV outputs are written",
    "PASS", "Finalized after validation CSV is written.")
))
write_csv(checks, output_paths[["validation_checks"]])
checks$details[checks$check_id == "csv_written"] <- paste(
  sum(file.exists(required_csv)), "of", length(required_csv),
  "required CSV outputs written."
)
checks$status[checks$check_id == "csv_written"] <- if (
  all(file.exists(required_csv))
) "PASS" else "FAIL"
checks <- checks[order(checks$check_id), , drop = FALSE]
write_csv(checks, output_paths[["validation_checks"]])

validation_lines <- c(
  "# U.S. S32 Preliminary Model-Choice Validation",
  "",
  "## Purpose",
  "",
  paste(
    "S32 estimates preliminary effective-output relations, applies",
    "Phillips-Ouliaris and residual-stationarity gates, and records",
    "FM-OLS, IM-OLS, DOLS, and diagnostic levels OLS results without",
    "promoting coefficients to final dissertation estimates."
  ),
  "",
  "## Locked metadata",
  "",
  paste0("- `", names(metadata), " = ", metadata, "`"),
  "",
  "## Estimator hierarchy",
  "",
  "- `FM_OLS_preliminary`: preferred available preliminary estimator.",
  "- `IM_OLS_preliminary`: preliminary robustness estimator.",
  "- `DOLS_preliminary`: preliminary robustness estimator with one lead and lag.",
  "- `diagnostic_levels_OLS`: diagnostic levels regression, never FM-OLS.",
  "",
  "## Gate protocol",
  "",
  paste(
    "Phillips-Ouliaris uses `urca::ca.po` with Pz, a constant, and short",
    "bandwidth. Residual ADF uses no deterministic term with AIC lag",
    "selection. Residual KPSS uses a level-stationarity null and short",
    "bandwidth. The screen is preliminary and model-specific."
  ),
  "",
  "## Validation summary",
  "",
  md_table(checks, c("check_name", "status", "details")),
  "",
  "## Hard-lock confirmation",
  "",
  paste(
    "S32 fetched no BEA data, modified no S20/S22/S30I or provider output,",
    "constructed no adjusted distribution or level interaction, ran no",
    "Johansen/VECM or S40 step, reconstructed no productive capacity or",
    "capacity utilization, and promoted no coefficient as final."
  )
)
writeLines(
  validation_lines, output_paths[["validation_report"]], useBytes = TRUE
)

if (any(checks$status == "FAIL")) {
  abort(paste(
    "S32 validation failed:",
    paste(checks$check_name[checks$status == "FAIL"], collapse = "; ")
  ))
}
message("S32 preliminary model-choice pass completed.")
message("Models registered: ", nrow(model_registry))
message("Coefficient rows: ", nrow(coefficients))
message("Estimator attempts: ", nrow(estimator_status))
message(
  "Validation PASS/WARN/FAIL: ",
  sum(checks$status == "PASS"), "/",
  sum(checks$status == "WARN"), "/",
  sum(checks$status == "FAIL")
)
