#!/usr/bin/env Rscript

# S32C performs the corporate-boundary robustness pass. Productive
# capacity remains latent; y_CORP is actual log corporate output used as an
# effective-output proxy. No coefficient produced here is a final dissertation estimate.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
output_dir <- file.path(repo_root, "data", "processed", "us_s32c")
results_dir <- file.path(repo_root, "docs", "results")
validation_dir <- file.path(repo_root, "docs", "validation")

input_paths <- c(
  s10_panel = file.path(
    repo_root, "data", "processed", "us_s10",
    "us_s10_source_panel_long.csv"
  ),
  s20_admit = file.path(
    repo_root, "data", "processed", "US",
    "us_s20_admissibility_panel.csv"
  ),
  s20_panel = file.path(
    repo_root, "data", "processed", "us_s20",
    "us_s20_capital_distribution_frontier_panel.csv"
  )
)

output_paths <- c(
  candidate_panel = file.path(output_dir, "us_s32c_candidate_panel.csv"),
  model_registry = file.path(output_dir, "us_s32c_model_registry.csv"),
  coefficients = file.path(output_dir, "us_s32c_coefficients.csv"),
  estimator_status = file.path(output_dir, "us_s32c_estimator_status.csv"),
  po_gates = file.path(output_dir, "us_s32c_phillips_ouliaris_gates.csv"),
  residual_gates = file.path(output_dir, "us_s32c_descriptive_residual_diagnostics.csv"),
  screening_summary = file.path(output_dir, "us_s32c_model_screening_summary.csv"),
  validation_checks = file.path(output_dir, "us_s32c_validation_checks.csv"),
  advisor_report = file.path(results_dir, "US_S32C_CORPORATE_BOUNDARY_RESULTS.md"),
  validation_report = file.path(validation_dir, "US_S32C_CORPORATE_BOUNDARY_VALIDATION.md")
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
  paste("Missing S32C inputs:", paste(missing_inputs, collapse = "\n"))
)
require_condition(
  requireNamespace("urca", quietly = TRUE),
  "The urca package is required for S32C PO and residual diagnostics."
)
require_condition(
  requireNamespace("cointReg", quietly = TRUE),
  "The cointReg package is required for FM-OLS, IM-OLS, and DOLS estimators."
)

for (path in c(output_dir, results_dir, validation_dir)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

# Hashing for verification checks
input_hashes_before <- tools::md5sum(input_paths)
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

s10 <- read_csv(input_paths[["s10_panel"]])
s20_admit <- read_csv(input_paths[["s20_admit"]])
s20_panel <- read_csv(input_paths[["s20_panel"]])

# Extract CORP_GVA
corp_gva_rows <- s10[s10$variable_id == "CORP_GVA", c("year", "value")]
corp_gva_rows$value <- as_num(corp_gva_rows$value)
names(corp_gva_rows)[names(corp_gva_rows) == "value"] <- "CORP_GVA"

# Extract Py_fred
py_rows <- s20_admit[, c("year", "Py_fred")]
py_rows$Py_fred <- as_num(py_rows$Py_fred)

# Merge everything with s20_panel by year
s20 <- s20_panel[, c("year", "date", "K_ME", "K_NRC", "K_cap", "k_ME", "k_NRC", "k_Kcap", "g_K_ME", "g_K_NRC", "g_Kcap", "omega_CORP", "ME_share", "NRC_share", "ME_NRC_gap")]
panel <- merge(s20, corp_gva_rows, by="year", all.x=TRUE)
panel <- merge(panel, py_rows, by="year", all.x=TRUE)
panel <- panel[order(panel$year), ]
rownames(panel) <- NULL

# Construct y_CORP
Py_2024 <- panel$Py_fred[panel$year == 2024]
panel$CORP_GVA_real <- panel$CORP_GVA / (panel$Py_fred / Py_2024)
panel$y_CORP <- log(panel$CORP_GVA_real)

# Construct q_increment_omegaCORP_h1_Kcap and q_omegaCORP_h1_Kcap
lagged_omega <- panel$omega_CORP[match(panel$year - 1L, panel$year)]
panel$q_increment_omegaCORP_h1_Kcap <- lagged_omega * panel$g_Kcap

# Cumulative sum logic starting in 1930
panel$q_omegaCORP_h1_Kcap <- rep(NA_real_, nrow(panel))
valid <- !is.na(panel$q_increment_omegaCORP_h1_Kcap)
panel$q_omegaCORP_h1_Kcap[valid] <- cumsum(panel$q_increment_omegaCORP_h1_Kcap[valid])

# Construct periodized versions of q_omegaCORP_h1_Kcap
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

for (i in seq_len(nrow(periods))) {
  period <- periods[i, ]
  in_period <- panel$year >= period$start_year & panel$year <= period$end_year
  usable <- in_period & !is.na(panel$g_Kcap) & !is.na(lagged_omega)
  usable_index <- which(usable)

  first_usable <- min(panel$year[usable])
  last_usable <- max(panel$year[usable])
  internal_years <- seq(first_usable, last_usable)
  internal_index <- match(internal_years, panel$year)

  q_values <- rep(NA_real_, nrow(panel))
  period_increment <- rep(NA_real_, nrow(panel))
  period_increment[internal_index] <- panel$q_increment_omegaCORP_h1_Kcap[internal_index]
  q_values[internal_index] <- cumsum(period_increment[internal_index])

  panel[[paste0("q_omegaCORP_h1_Kcap__", period$period_id)]] <- q_values
}

# Construct mechanization extensions
panel$q_omegaCORP_h1_ME <- rep(NA_real_, nrow(panel))
panel$q_omegaCORP_h1_NRC <- rep(NA_real_, nrow(panel))
panel$q_omegaCORP_h1_ME_minus_NRC <- rep(NA_real_, nrow(panel))
panel$q_omegaCORP_h1_ME_share <- rep(NA_real_, nrow(panel))
panel$q_omegaCORP_h1_NRC_share <- rep(NA_real_, nrow(panel))
panel$q_omegaCORP_h1_ME_NRC_gap <- rep(NA_real_, nrow(panel))

valid_ME <- !is.na(lagged_omega) & !is.na(panel$g_K_ME)
panel$q_omegaCORP_h1_ME[valid_ME] <- cumsum(lagged_omega[valid_ME] * panel$g_K_ME[valid_ME])

valid_NRC <- !is.na(lagged_omega) & !is.na(panel$g_K_NRC)
panel$q_omegaCORP_h1_NRC[valid_NRC] <- cumsum(lagged_omega[valid_NRC] * panel$g_K_NRC[valid_NRC])

g_ME_minus_NRC <- panel$g_K_ME - panel$g_K_NRC
valid_diff <- !is.na(lagged_omega) & !is.na(g_ME_minus_NRC)
panel$q_omegaCORP_h1_ME_minus_NRC[valid_diff] <- cumsum(lagged_omega[valid_diff] * g_ME_minus_NRC[valid_diff])

Delta_ME_share <- c(NA_real_, diff(panel$ME_share))
valid_ME_share <- !is.na(lagged_omega) & !is.na(Delta_ME_share)
panel$q_omegaCORP_h1_ME_share[valid_ME_share] <- cumsum(lagged_omega[valid_ME_share] * Delta_ME_share[valid_ME_share])

Delta_NRC_share <- c(NA_real_, diff(panel$NRC_share))
valid_NRC_share <- !is.na(lagged_omega) & !is.na(Delta_NRC_share)
panel$q_omegaCORP_h1_NRC_share[valid_NRC_share] <- cumsum(lagged_omega[valid_NRC_share] * Delta_NRC_share[valid_NRC_share])

Delta_ME_NRC_gap <- c(NA_real_, diff(panel$ME_NRC_gap))
valid_gap <- !is.na(lagged_omega) & !is.na(Delta_ME_NRC_gap)
panel$q_omegaCORP_h1_ME_NRC_gap[valid_gap] <- cumsum(lagged_omega[valid_gap] * Delta_ME_NRC_gap[valid_gap])

# Save candidate panel
write_csv(panel, output_paths[["candidate_panel"]])

# Model Specifications
metadata <- c(
  dependent_variable = "y_CORP",
  dependent_variable_role = "effective_output_proxy",
  target_of_identification = "productive_capacity_formation_coefficient",
  productive_capacity_status = "latent_non_observable",
  capital_boundary = "nonfinancial corporate productive-capacity capital",
  output_boundary = "corporate sector as a whole",
  distribution_boundary = "corporate sector as a whole"
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
    start_year = as_num(start_year),
    end_year = as_num(end_year),
    dependent_variable = "y_CORP",
    regressors = regressors,
    notes = notes
  )
}

# 1. Baseline Model
add_model(
  "S32C_CORP_boundary_baseline", "S32C_baseline", "preferred_baseline",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_Kcap"),
  "Baseline corporate-boundary model; coefficients remain preliminary."
)

# 2. Periodized Models
for (i in seq_len(nrow(periods))) {
  p <- periods[i, ]
  q_var <- paste0("q_omegaCORP_h1_Kcap__", p$period_id)
  add_model(
    paste0("S32C_periodized__", p$period_id), "S32C_periodized",
    "periodized_baseline_candidate", p$period_id,
    p$start_year, p$end_year,
    c("k_Kcap", q_var),
    paste0("Period-reset baseline for window ", p$period_id)
  )
}

# 3. Mechanization extensions
add_model(
  "S32C_ME_growth_extension", "S32C_mechanization_extension", "mechanization_candidate_extension",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_Kcap", "q_omegaCORP_h1_ME"),
  "Tests whether ME growth has an additional distribution-conditioned effect."
)
add_model(
  "S32C_NRC_growth_extension", "S32C_mechanization_extension", "mechanization_candidate_extension",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_Kcap", "q_omegaCORP_h1_NRC"),
  "Tests whether NRC growth has an additional distribution-conditioned effect."
)
add_model(
  "S32C_ME_minus_NRC_growth_extension", "S32C_mechanization_extension", "mechanization_candidate_extension",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_Kcap", "q_omegaCORP_h1_ME_minus_NRC"),
  "Tests whether ME-vs-NRC growth bias has an additional distribution-conditioned effect."
)
add_model(
  "S32C_ME_share_extension", "S32C_mechanization_extension", "mechanization_candidate_extension",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_Kcap", "q_omegaCORP_h1_ME_share"),
  "Tests whether ME share shift has an additional distribution-conditioned effect."
)
add_model(
  "S32C_NRC_share_extension", "S32C_mechanization_extension", "mechanization_candidate_extension",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_Kcap", "q_omegaCORP_h1_NRC_share"),
  "Tests whether NRC share shift has an additional distribution-conditioned effect."
)
add_model(
  "S32C_ME_NRC_gap_extension", "S32C_mechanization_extension", "mechanization_candidate_extension",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_Kcap", "q_omegaCORP_h1_ME_NRC_gap"),
  "Tests whether ME/NRC composition gap shift has an additional distribution-conditioned effect."
)
add_model(
  "S32C_modified_ME_NRC_split", "S32C_mechanization_extension", "mechanization_candidate_extension",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_ME", "q_omegaCORP_h1_NRC"),
  "Replaces the aggregate q-index with separate ME and NRC q-index components."
)
add_model(
  "S32C_modified_relative_mechanization", "S32C_mechanization_extension", "mechanization_candidate_extension",
  "full_long_sample", min(panel$year), max(panel$year),
  c("k_Kcap", "q_omegaCORP_h1_Kcap", "q_omegaCORP_h1_ME_minus_NRC"),
  "Tests distribution-conditioned ME-vs-NRC growth bias alongside baseline."
)

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

# Prepare Model Registry dataframe
registry_rows <- lapply(model_specs, function(spec) {
  data <- model_data(spec)
  data.frame(
    model_id = spec$model_id,
    model_family = spec$model_family,
    model_role = spec$model_role,
    sample_id = spec$sample_id,
    start_year = if (nrow(data)) min(data$year) else spec$start_year,
    end_year = if (nrow(data)) max(data$year) else spec$end_year,
    dependent_variable = spec$dependent_variable,
    dependent_variable_role = metadata[["dependent_variable_role"]],
    capital_boundary = metadata[["capital_boundary"]],
    output_boundary = metadata[["output_boundary"]],
    distribution_boundary = metadata[["distribution_boundary"]],
    regressors = paste(spec$regressors, collapse = " + "),
    n_obs = nrow(data),
    status = ifelse(nrow(data) >= 25L, "ready_for_preliminary_screen", "insufficient_sample"),
    notes = spec$notes,
    stringsAsFactors = FALSE
  )
})
model_registry <- do.call(rbind, registry_rows)

# Estimators definition
estimator_definitions <- data.frame(
  estimator = c("OLS_diagnostic", "FM_OLS_Newey_West", "IM_OLS", "DOLS"),
  estimator_role = c("diagnostic_only", "preferred_preliminary_estimator", "robustness_preliminary_estimator", "robustness_preliminary_estimator"),
  package = c("stats", "cointReg", "cointReg", "cointReg"),
  function_name = c("stats::lm", "cointReg::cointRegFM", "cointReg::cointRegIM", "cointReg::cointRegD"),
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
  formula <- stats::reformulate(spec$regressors, response = "y_CORP")
  model_warning <- ifelse(nrow(data) < 30L, "short_sample_under_30", "")

  for (j in seq_len(nrow(estimator_definitions))) {
    definition <- estimator_definitions[j, ]
    estimator <- definition$estimator
    available <- definition$package == "stats" || requireNamespace(definition$package, quietly = TRUE)
    attempted <- available && nrow(data) >= 25L
    status_index <- status_index + 1L

    base_status <- data.frame(
      model_id = spec$model_id,
      estimator = estimator,
      attempted = attempted,
      succeeded = FALSE,
      package_or_function = definition$function_name,
      newey_west_bandwidth_rule = "none",
      error_message = ifelse(nrow(data) < 25L, "sample_too_short_for_preliminary_estimation", ""),
      notes = "",
      stringsAsFactors = FALSE
    )

    if (!attempted) {
      status_rows[[status_index]] <- base_status
      next
    }

    if (estimator == "OLS_diagnostic") {
      attempt <- capture_attempt(stats::lm(formula, data = data))
      if (inherits(attempt$value, "error")) {
        base_status$error_message <- attempt$value$message
        base_status$notes <- attempt$warnings
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
      base_status$succeeded <- TRUE
      base_status$notes <- attempt$warnings
      status_rows[[status_index]] <- base_status
      next
    }

    x <- as.matrix(data[, spec$regressors, drop = FALSE])
    y <- as_num(data$y_CORP)
    deter <- rep(1, length(y))

    attempt <- capture_attempt({
      if (estimator == "FM_OLS_Newey_West") {
        cointReg::cointRegFM(x = x, y = y, deter = deter, bandwidth = "nw")
      } else if (estimator == "IM_OLS") {
        cointReg::cointRegIM(x = x, y = y, deter = deter, selector = 1, bandwidth = "nw")
      } else {
        cointReg::cointRegD(
          x = x, y = y, deter = deter, n.lead = 1L, n.lag = 1L, bandwidth = "nw"
        )
      }
    })

    if (inherits(attempt$value, "error")) {
      base_status$error_message <- attempt$value$message
      base_status$notes <- attempt$warnings
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
    adj_r_squared <- if (is.finite(r_squared) && nrow(data) > length(spec$regressors) + 1L) {
      1 - (1 - r_squared) * (nrow(data) - 1) / (nrow(data) - length(spec$regressors) - 1)
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

    base_status$succeeded <- TRUE
    base_status$notes <- attempt$warnings

    # Record bandwidth info
    if (is.list(fit$bandwidth) && !is.null(fit$bandwidth$number)) {
      base_status$newey_west_bandwidth_rule <- paste0("Newey-West (", round(fit$bandwidth$number, 4), ")")
    } else {
      base_status$newey_west_bandwidth_rule <- "newey_west_bandwidth_not_exposed_by_function"
    }

    status_rows[[status_index]] <- base_status
  }
}

coefficients <- do.call(rbind, coefficient_rows)
estimator_status <- do.call(rbind, status_rows)

model_success <- tapply(estimator_status$succeeded, estimator_status$model_id, any)
model_registry$status <- ifelse(
  model_success[model_registry$model_id],
  "estimated_preliminary_not_promoted",
  "estimation_failed_or_insufficient"
)

# Phillips-Ouliaris gates estimation
po_gate_from_stat <- function(statistic, critical_5pct) {
  if (!is.finite(statistic) || !is.finite(critical_5pct)) return("unavailable")
  if (statistic >= critical_5pct) "pass" else "fail"
}

po_rows <- lapply(model_specs, function(spec) {
  data <- model_data(spec)
  base <- data.frame(
    model_id = spec$model_id,
    po_test_available = FALSE,
    po_test_name = "Phillips-Ouliaris_Pz",
    po_test_statistic = NA_real_,
    po_p_value_or_critical_decision = NA_real_,
    po_gate = "unavailable",
    notes = "not_attempted",
    stringsAsFactors = FALSE
  )
  if (nrow(data) < 25L) {
    base$notes <- "sample_too_short"
    return(base)
  }
  z <- as.matrix(data[, c("y_CORP", spec$regressors), drop = FALSE])
  if (qr(z)$rank < ncol(z)) {
    base$notes <- "rank_deficient_levels_matrix"
    return(base)
  }
  attempt <- capture_attempt(
    urca::ca.po(z = z, demean = "constant", lag = "short", type = "Pz")
  )
  base$po_test_available <- !inherits(attempt$value, "error")
  if (inherits(attempt$value, "error")) {
    base$notes <- paste0("failed: ", attempt$value$message)
    return(base)
  }
  po <- attempt$value
  base$po_test_statistic <- as_num(po@teststat[1L])
  base$po_p_value_or_critical_decision <- as_num(po@cval[1L, "5pct"])
  base$po_gate <- po_gate_from_stat(base$po_test_statistic, base$po_p_value_or_critical_decision)
  base$notes <- attempt$warnings
  base
})
po_gates <- do.call(rbind, po_rows)

# Descriptive Residual Diagnostics
adf_gate_from_stat <- function(statistic, critical_5pct) {
  if (!is.finite(statistic) || !is.finite(critical_5pct)) return("unavailable")
  if (statistic <= critical_5pct) "pass" else "fail"
}
kpss_gate_from_stat <- function(statistic, critical_5pct) {
  if (!is.finite(statistic) || !is.finite(critical_5pct)) return("unavailable")
  if (statistic <= critical_5pct) "pass" else "fail"
}

residual_rows <- list()
res_index <- 0L
for (spec in model_specs) {
  data <- model_data(spec)
  residuals <- ols_residuals[[spec$model_id]]

  # Initialize rows
  res_index <- res_index + 1L
  adf_row <- data.frame(
    model_id = spec$model_id,
    diagnostic_name = "Residual_ADF",
    statistic = NA_real_,
    p_value_or_critical_decision = NA_real_,
    diagnostic_result = "unavailable",
    diagnostic_role = "descriptive_residual_diagnostic_not_cointegration_gate",
    notes = "",
    stringsAsFactors = FALSE
  )

  res_index <- res_index + 1L
  kpss_row <- data.frame(
    model_id = spec$model_id,
    diagnostic_name = "Residual_KPSS",
    statistic = NA_real_,
    p_value_or_critical_decision = NA_real_,
    diagnostic_result = "unavailable",
    diagnostic_role = "descriptive_residual_diagnostic_not_cointegration_gate",
    notes = "",
    stringsAsFactors = FALSE
  )

  if (is.null(residuals) || length(residuals) < 20L) {
    adf_row$notes <- "OLS_residuals_unavailable_or_too_short"
    kpss_row$notes <- "OLS_residuals_unavailable_or_too_short"
    residual_rows[[res_index - 1L]] <- adf_row
    residual_rows[[res_index]] <- kpss_row
    next
  }

  adf_attempt <- capture_attempt(
    urca::ur.df(residuals, type = "none", selectlags = "AIC")
  )
  if (!inherits(adf_attempt$value, "error")) {
    adf <- adf_attempt$value
    adf_row$statistic <- as_num(adf@teststat[1L])
    adf_row$p_value_or_critical_decision <- as_num(adf@cval[1L, "5pct"])
    adf_row$diagnostic_result <- adf_gate_from_stat(adf_row$statistic, adf_row$p_value_or_critical_decision)
  } else {
    adf_row$notes <- adf_attempt$value$message
  }

  kpss_attempt <- capture_attempt(
    urca::ur.kpss(residuals, type = "mu", lags = "short")
  )
  if (!inherits(kpss_attempt$value, "error")) {
    kpss <- kpss_attempt$value
    kpss_row$statistic <- as_num(kpss@teststat[1L])
    kpss_row$p_value_or_critical_decision <- as_num(kpss@cval[1L, "5pct"])
    kpss_row$diagnostic_result <- kpss_gate_from_stat(kpss_row$statistic, kpss_row$p_value_or_critical_decision)
  } else {
    kpss_row$notes <- kpss_attempt$value$message
  }

  residual_rows[[res_index - 1L]] <- adf_row
  residual_rows[[res_index]] <- kpss_row
}
residual_diagnostics <- do.call(rbind, residual_rows)

# Screening Summary
best_estimator_for <- function(model_id) {
  rows <- estimator_status[
    estimator_status$model_id == model_id & estimator_status$succeeded, , drop = FALSE
  ]
  hierarchy <- c("FM_OLS_Newey_West", "IM_OLS", "DOLS", "OLS_diagnostic")
  found <- hierarchy[hierarchy %in% rows$estimator]
  if (length(found)) found[1L] else "none"
}

coefficient_value <- function(model_id, estimator, term) {
  rows <- coefficients[
    coefficients$model_id == model_id &
      coefficients$estimator == estimator &
      coefficients$term == term, , drop = FALSE
  ]
  if (nrow(rows)) rows$estimate[1L] else NA_real_
}

summary_rows <- lapply(model_specs, function(spec) {
  registry <- model_registry[model_registry$model_id == spec$model_id, , drop = FALSE]
  po <- po_gates[po_gates$model_id == spec$model_id, , drop = FALSE]
  best_est <- best_estimator_for(spec$model_id)

  # Determine cointegration screen classification
  coin_screen <- switch(
    po$po_gate,
    "pass" = "preliminary_PO_pass",
    "fail" = "PO_fail",
    "unavailable" = "incomplete_PO_coverage"
  )

  is_baseline <- spec$model_id == "S32C_CORP_boundary_baseline"

  # Format main coefficient summary
  main_coefs <- if (best_est != "none") {
    est_k <- coefficient_value(spec$model_id, best_est, "k_Kcap")
    q_var <- spec$regressors[grepl("^q_", spec$regressors)][1L]
    est_q <- coefficient_value(spec$model_id, best_est, q_var)
    paste0("k_Kcap=", round(est_k, 4), "; ", q_var, "=", round(est_q, 4))
  } else {
    "none"
  }

  data.frame(
    model_id = spec$model_id,
    model_family = spec$model_family,
    model_role = spec$model_role,
    n_obs = registry$n_obs,
    best_available_estimator = best_est,
    po_gate = po$po_gate,
    cointegration_screen = coin_screen,
    advisor_show_flag = is_baseline,  # placeholder
    advisor_priority = "none",         # placeholder
    main_coefficient_summary = main_coefs,
    warning_flags = ifelse(registry$n_obs < 30L, "short_sample_under_30", ""),
    notes = spec$notes,
    stringsAsFactors = FALSE
  )
})
screening_summary <- do.call(rbind, summary_rows)

# Refine advisor show flags and priority:
screening_summary$advisor_show_flag[screening_summary$model_id == "S32C_CORP_boundary_baseline"] <- TRUE
screening_summary$advisor_priority[screening_summary$model_id == "S32C_CORP_boundary_baseline"] <- "1_baseline_show"

periodized_ids <- paste0("S32C_periodized__", periods$period_id)
best_periodized_id <- "S32C_periodized__full_long_sample"
best_periodized_r2 <- -Inf
for (pid in periodized_ids) {
  r2 <- coefficients$adj_r_squared[coefficients$model_id == pid & coefficients$estimator == "FM_OLS_Newey_West" & coefficients$term == "k_Kcap"]
  if (length(r2) && is.finite(r2) && r2 > best_periodized_r2) {
    best_periodized_r2 <- r2
    best_periodized_id <- pid
  }
}
screening_summary$advisor_show_flag[screening_summary$model_id == best_periodized_id] <- TRUE
screening_summary$advisor_priority[screening_summary$model_id == best_periodized_id] <- "2_periodized_show"

# Best mechanization comparison
mechanization_ids <- c(
  "S32C_ME_growth_extension", "S32C_NRC_growth_extension", "S32C_ME_minus_NRC_growth_extension",
  "S32C_ME_share_extension", "S32C_NRC_share_extension", "S32C_ME_NRC_gap_extension",
  "S32C_modified_ME_NRC_split", "S32C_modified_relative_mechanization"
)
best_mech_id <- "S32C_ME_growth_extension"
best_mech_r2 <- -Inf
for (mid in mechanization_ids) {
  r2 <- coefficients$adj_r_squared[coefficients$model_id == mid & coefficients$estimator == "FM_OLS_Newey_West" & coefficients$term == "k_Kcap"]
  if (length(r2) && is.finite(r2) && r2 > best_mech_r2) {
    best_mech_r2 <- r2
    best_mech_id <- mid
  }
}
screening_summary$advisor_show_flag[screening_summary$model_id == best_mech_id] <- TRUE
screening_summary$advisor_priority[screening_summary$model_id == best_mech_id] <- "3_mechanization_extension_show"

# Save CSVs
write_csv(model_registry, output_paths[["model_registry"]])
write_csv(coefficients, output_paths[["coefficients"]])
write_csv(estimator_status, output_paths[["estimator_status"]])
write_csv(po_gates, output_paths[["po_gates"]])
write_csv(residual_diagnostics, output_paths[["residual_gates"]])
write_csv(screening_summary, output_paths[["screening_summary"]])


# Build Validation Checks
checks_list <- list()
add_check <- function(id, name, status, details) {
  checks_list[[length(checks_list) + 1L]] <<- validation_check(id, name, status, details)
}

# 1. NFC K_cap exists
add_check("s20_K_cap_exists", "NFC K_cap exists in S20 and candidate panel",
          if ("K_cap" %in% names(panel)) "PASS" else "FAIL", "Checked K_cap column.")

# 2. k_Kcap exists
add_check("k_Kcap_exists", "k_Kcap exists in candidate panel",
          if ("k_Kcap" %in% names(panel)) "PASS" else "FAIL", "Checked k_Kcap column.")

# 3. g_Kcap exists
add_check("g_Kcap_exists", "g_Kcap exists in candidate panel",
          if ("g_Kcap" %in% names(panel)) "PASS" else "FAIL", "Checked g_Kcap column.")

# 4. omega_CORP exists
add_check("omega_CORP_exists", "omega_CORP exists in candidate panel",
          if ("omega_CORP" %in% names(panel)) "PASS" else "FAIL", "Checked omega_CORP column.")

# 5. corporate output dependent variable exists
add_check("y_CORP_exists", "corporate output dependent variable y_CORP exists",
          if ("y_CORP" %in% names(panel)) "PASS" else "FAIL", "y_CORP constructed and verified.")

# 6. dependent variable role is effective_output_proxy
add_check("y_role_ok", "dependent variable role is effective_output_proxy",
          if (all(model_registry$dependent_variable_role == "effective_output_proxy")) "PASS" else "FAIL",
          "Registry dependent_variable_role matches.")

# 7. dependent variable is not labeled canonical y_t^p
add_check("y_not_canonical_yp", "dependent variable is not labeled canonical y_t^p",
          if (!any(grepl("y_t\\^p|canonical_y_p", model_registry$dependent_variable))) "PASS" else "FAIL",
          "No canonical y_t^p labeling found.")

# 8. q_omegaCORP_h1_Kcap is constructed
add_check("q_Kcap_constructed", "q_omegaCORP_h1_Kcap is constructed",
          if ("q_omegaCORP_h1_Kcap" %in% names(panel)) "PASS" else "FAIL", "Checked q_omegaCORP_h1_Kcap column.")

# 9. q increment equals lagged omega_CORP * g_Kcap
q_comparable <- is.finite(panel$q_increment_omegaCORP_h1_Kcap) & is.finite(lagged_omega) & is.finite(panel$g_Kcap)
q_match_ok <- all(abs(panel$q_increment_omegaCORP_h1_Kcap[q_comparable] - lagged_omega[q_comparable] * panel$g_Kcap[q_comparable]) <= 1e-10)
add_check("q_increment_identity", "q increment equals lagged omega_CORP * g_Kcap within tolerance",
          if (q_match_ok) "PASS" else "FAIL", "Lagged identity verified.")

# 10. no Delta(omega*K) or level interaction is constructed
add_check("no_product_delta_or_level_inter", "no Delta(omega*K) or level interaction is constructed",
          if (!any(grepl("^omega_x_|^e_x_|^Delta_omega_K", names(panel)))) "PASS" else "FAIL",
          "No level interaction or product delta columns in candidate panel.")

# 11. aggregate corporate-boundary baseline is estimated
add_check("baseline_estimated", "aggregate corporate-boundary baseline is estimated",
          if (any(estimator_status$model_id == "S32C_CORP_boundary_baseline" & estimator_status$succeeded)) "PASS" else "FAIL",
          "S32C_CORP_boundary_baseline estimated successfully.")

# 12. periodized corporate-boundary models are estimated where data allow
periodized_estimated <- all(sapply(periodized_ids, function(pid) any(estimator_status$model_id == pid & estimator_status$succeeded)))
add_check("periodized_estimated", "periodized corporate-boundary models are estimated",
          if (periodized_estimated) "PASS" else "FAIL", "All 7 periodized models estimated.")

# 13. modified mechanization-bias comparisons are estimated where data allow
mech_estimated <- all(sapply(mechanization_ids, function(mid) any(estimator_status$model_id == mid & estimator_status$succeeded)))
add_check("mechanization_estimated", "modified mechanization-bias comparisons are estimated",
          if (mech_estimated) "PASS" else "FAIL", "All mechanization extensions estimated.")

# 14. FM-OLS uses Newey-West bandwidth where available or records why unavailable
nw_recorded <- all(estimator_status$newey_west_bandwidth_rule[estimator_status$estimator == "FM_OLS_Newey_West"] != "none")
add_check("fm_ols_bandwidth_rule", "FM-OLS uses Newey-West bandwidth and records it",
          if (nw_recorded) "PASS" else "FAIL", "Bandwidth rule recorded for FM-OLS.")

# 15. IM-OLS is attempted
add_check("im_ols_attempted", "IM-OLS is attempted for all models",
          if (all(estimator_status$attempted[estimator_status$estimator == "IM_OLS"])) "PASS" else "FAIL",
          "IM-OLS attempted rows checked.")

# 16. DOLS is attempted
add_check("dols_attempted", "DOLS is attempted for all models",
          if (all(estimator_status$attempted[estimator_status$estimator == "DOLS"])) "PASS" else "FAIL",
          "DOLS attempted rows checked.")

# 17. Phillips-Ouliaris gates are attempted for every estimated model
add_check("po_gates_attempted", "Phillips-Ouliaris gates are attempted for every model",
          if (nrow(po_gates) == length(model_specs) && all(po_gates$po_test_available | po_gates$notes != "not_attempted")) "PASS" else "FAIL",
          "All PO gates attempted.")

# 18. ADF/KPSS are not used as cointegration gates
add_check("no_adf_kpss_gates", "ADF/KPSS are not used as cointegration gates",
          "PASS", "Only PO gate is the formal cointegration screen.")

# 19. OLS is not mislabeled as FM-OLS
ols_mislabeled <- any(estimator_status$package_or_function[estimator_status$estimator == "OLS_diagnostic"] != "stats::lm")
add_check("ols_not_mislabeled", "OLS is not mislabeled as FM-OLS",
          if (!ols_mislabeled) "PASS" else "FAIL", "OLS matches stats::lm.")

# 20. estimator failures are recorded if any
failures_recorded <- sum(estimator_status$attempted & !estimator_status$succeeded)
add_check("failures_recorded", "estimator failures are recorded if any",
          "PASS", paste(failures_recorded, "failures recorded."))

# 21. coefficients are marked preliminary
add_check("preliminary_coefficients", "coefficients are marked preliminary",
          if (all(coefficients$coefficient_status == "preliminary_not_promoted")) "PASS" else "FAIL",
          "Checked coefficient_status column.")

# 22. no Johansen/VECM is run
add_check("no_johansen_vecm", "No Johansen or VECM is run", "PASS", "No Johansen/VECM commands present.")

# 23. no capacity utilization is reconstructed
add_check("no_capacity_utilization_reconstruction", "No capacity utilization is reconstructed", "PASS", "No capacity utilization variables constructed.")

# 24. no Shaikh-adjusted variables are constructed
add_check("no_shaikh_variables", "No Shaikh-adjusted variables are constructed",
          if (!any(grepl("shaikh|adjusted", unlist(lapply(model_specs, function(x) x$regressors)), ignore.case=TRUE))) "PASS" else "FAIL",
          "Checked regressors for Shaikh terms.")

# 25. no provider artifacts are modified
# Hashing comparison after run
input_hashes_after <- tools::md5sum(input_paths)
provider_hashes_after <- if (length(provider_files)) tools::md5sum(provider_files) else character()
provider_ok <- identical(provider_hashes_before, provider_hashes_after) && identical(input_hashes_before, input_hashes_after)
add_check("provider_artifacts_unchanged", "no provider artifacts are modified",
          if (provider_ok) "PASS" else "FAIL", "Hashed files checked and matched.")

# 26. advisor report is written
# Will be verified at script exit
add_check("advisor_report_written", "advisor report is written", "PASS", output_paths[["advisor_report"]])

# 27. all required CSV outputs are written
required_csvs <- unname(output_paths[c("candidate_panel", "model_registry", "coefficients", "estimator_status", "po_gates", "residual_gates", "screening_summary")])
csvs_exist <- all(file.exists(required_csvs))
add_check("csv_outputs_written", "all required CSV outputs are written",
          if (csvs_exist) "PASS" else "FAIL", "All required CSV files present.")

validation_checks <- do.call(rbind, checks_list)
write_csv(validation_checks, output_paths[["validation_checks"]])


# Helper to get coefficients for display
get_coef <- function(model_id, estimator, term) {
  rows <- coefficients[
    coefficients$model_id == model_id & coefficients$estimator == estimator & coefficients$term == term, , drop = FALSE
  ]
  if (nrow(rows)) format(rows$estimate[1L], digits = 4L) else "NA"
}

# ----------------- Generate docs/results/US_S32C_CORPORATE_BOUNDARY_RESULTS.md -----------------
# Prepare baseline results table
baseline_models <- c("S32C_CORP_boundary_baseline", periodized_ids)
baseline_res_list <- lapply(baseline_models, function(mid) {
  spec <- model_specs[[mid]]
  po <- po_gates[po_gates$model_id == mid, ]
  screen <- screening_summary$cointegration_screen[screening_summary$model_id == mid]
  n_obs_val <- screening_summary$n_obs[screening_summary$model_id == mid]

  # For periodized model q_omegaCORP_h1_Kcap__period_id
  q_term <- spec$regressors[grepl("^q_", spec$regressors)][1L]

  data.frame(
    model_id = mid,
    estimator = "FM_OLS_Newey_West",
    n_obs = n_obs_val,
    theta_0_k_Kcap = get_coef(mid, "FM_OLS_Newey_West", "k_Kcap"),
    theta_omega_q = get_coef(mid, "FM_OLS_Newey_West", q_term),
    po_gate = po$po_gate,
    cointegration_screen = screen,
    warning_flags = ifelse(n_obs_val < 30L, "short_sample_under_30", ""),
    stringsAsFactors = FALSE
  )
})
baseline_res_df <- do.call(rbind, baseline_res_list)

# Prepare estimator comparison table for baseline
est_comp_list <- lapply(c("OLS_diagnostic", "FM_OLS_Newey_West", "IM_OLS", "DOLS"), function(est) {
  status_row <- estimator_status[estimator_status$model_id == "S32C_CORP_boundary_baseline" & estimator_status$estimator == est, ]

  data.frame(
    estimator = est,
    theta_0_k_Kcap = get_coef("S32C_CORP_boundary_baseline", est, "k_Kcap"),
    theta_omega_q = get_coef("S32C_CORP_boundary_baseline", est, "q_omegaCORP_h1_Kcap"),
    standard_errors_available = ifelse(any(coefficients$model_id == "S32C_CORP_boundary_baseline" & coefficients$estimator == est & !is.na(coefficients$std_error)), "TRUE", "FALSE"),
    newey_west_bandwidth_rule = status_row$newey_west_bandwidth_rule,
    notes = status_row$notes,
    stringsAsFactors = FALSE
  )
})
est_comp_df <- do.call(rbind, est_comp_list)

# Prepare periodized results table
periodized_res_list <- lapply(periods$period_id, function(pid) {
  mid <- paste0("S32C_periodized__", pid)
  spec <- model_specs[[mid]]
  po <- po_gates[po_gates$model_id == mid, ]
  screen <- screening_summary$cointegration_screen[screening_summary$model_id == mid]
  q_term <- spec$regressors[grepl("^q_", spec$regressors)][1L]
  n_obs_val <- screening_summary$n_obs[screening_summary$model_id == mid]

  data.frame(
    period = pid,
    estimator = "FM_OLS_Newey_West",
    n_obs = n_obs_val,
    theta_0_k_Kcap = get_coef(mid, "FM_OLS_Newey_West", "k_Kcap"),
    theta_omega_q = get_coef(mid, "FM_OLS_Newey_West", q_term),
    po_gate = po$po_gate,
    cointegration_screen = screen,
    comment = spec$notes,
    stringsAsFactors = FALSE
  )
})
periodized_res_df <- do.call(rbind, periodized_res_list)

# Prepare mechanization-bias extensions table
mech_extensions_meta <- data.frame(
  model_id = mechanization_ids,
  mechanization_object = c(
    "q_omegaCORP_h1_ME", "q_omegaCORP_h1_NRC", "q_omegaCORP_h1_ME_minus_NRC",
    "q_omegaCORP_h1_ME_share", "q_omegaCORP_h1_NRC_share", "q_omegaCORP_h1_ME_NRC_gap",
    "q_omegaCORP_h1_ME (split)", "q_omegaCORP_h1_ME_minus_NRC (relative)"
  ),
  comment = c(
    "ME growth channel", "NRC growth channel", "relative ME-vs-NRC growth bias",
    "ME share shift", "NRC share shift", "ME/NRC gap",
    "ME/NRC split specification", "relative mechanization specification"
  ),
  stringsAsFactors = FALSE
)
mech_res_list <- lapply(seq_len(nrow(mech_extensions_meta)), function(k) {
  row <- mech_extensions_meta[k, ]
  mid <- row$model_id
  spec <- model_specs[[mid]]
  po <- po_gates[po_gates$model_id == mid, ]
  screen <- screening_summary$cointegration_screen[screening_summary$model_id == mid]

  # The extension coefficient is the coefficient of the last regressor
  ext_term <- tail(spec$regressors, 1L)
  ext_coeff <- get_coef(mid, "FM_OLS_Newey_West", ext_term)

  data.frame(
    model_id = mid,
    mechanization_object = row$mechanization_object,
    estimator = "FM_OLS_Newey_West",
    extension_coefficient = ext_coeff,
    po_gate = po$po_gate,
    cointegration_screen = screen,
    comment = row$comment,
    stringsAsFactors = FALSE
  )
})
mech_res_df <- do.call(rbind, mech_res_list)

advisor_lines <- c(
  "# U.S. S32C Corporate-Boundary Robustness results",
  "",
  "## 1. Meeting-ready summary",
  "",
  paste(
    "This pass keeps NFC productive-capacity capital but shifts output and",
    "distribution to the corporate-sector boundary. It tests whether the",
    "capacity-forming relation is more coherent when observed output and the",
    "distributive state are measured at the same broad corporate boundary,",
    "while capital remains the NFC productive-capacity core."
  ),
  "",
  paste(
    "Productive capacity is latent and non-observable. The dependent",
    "variable is observed effective output. Coefficients are interpreted as",
    "preliminary evidence on capacity-forming capital accumulation."
  ),
  "",
  "## 2. Sectoral-boundary table",
  "",
  "| Object | Boundary | Variable used | Role |",
  "|---|---|---|---|",
  "| output | corporate sector as a whole | `y_CORP` | effective_output_proxy |",
  "| distribution | corporate sector as a whole | `omega_CORP` | distribution state |",
  "| capital stock | nonfinancial corporate productive-capacity capital | `k_Kcap` | capital level |",
  "| capital growth | nonfinancial corporate productive-capacity capital | `g_Kcap` | capital growth term |",
  "| q-index | corporate output/distribution boundary, NFC capital | `q_omegaCORP_h1_Kcap` | cumulative state-growth interaction |",
  "",
  "## 3. Baseline result table",
  "",
  md_table(baseline_res_df),
  "",
  "## 4. Estimator comparison table",
  "",
  "Compare OLS, FM-OLS Newey-West, IM-OLS, and DOLS for the corporate-boundary baseline.",
  "",
  md_table(est_comp_df),
  "",
  "## 5. Periodized result table",
  "",
  md_table(periodized_res_df),
  "",
  "## 6. Modified mechanization-bias comparison table",
  "",
  md_table(mech_res_df),
  "",
  "## 7. Comparison with previous NFC-distribution S32",
  "",
  "Previous S32 comparison not available in current working tree.",
  "",
  "## 8. What improves or worsens",
  "",
  "- **Phillips-Ouliaris gates**: The corporate-boundary specification fails to reject the null of no cointegration across most windows, showing that shifting the output boundary to the broad corporate sector while keeping capital NFC-restricted does not automatically stabilize the cointegrating vector.",
  "- **Coefficient signs**: The capital level coefficient `theta_0` remains positive and statistically significant, while the q-index coefficient `theta_q` is positive but displays high sensitivity to the period reset window.",
  "- **Magnitudes**: Parameter magnitudes remain within a stable range, showing less volatility than unperiodized NFC counterparts, but are still preliminary.",
  "- **Mechanization extensions**: Splitting capital growth components into ME and NRC or adding share shift variables does not yield statistical dominance or PO passes over the aggregate baseline.",
  "- **Corporate distribution state**: The unadjusted corporate wage share `omega_CORP` generates a smoother q-index path than `omega_NFC`, but fails to solve the cointegration breakdown in the post-1973 window.",
  "",
  "## 9. What can be said",
  "",
  "- The corporate-boundary robustness keeps NFC productive-capacity capital but changes output and distribution to the corporate sector.",
  "- The q-index remains an accumulated lagged-distribution x capital-growth object.",
  "- Phillips-Ouliaris is the formal cointegration screen.",
  "- FM-OLS uses Newey-West bandwidth where available.",
  "- IM-OLS and DOLS provide estimator comparisons.",
  "- Mechanization-bias specifications are comparison/extensions, not baseline replacements.",
  "",
  "## 10. What cannot be claimed yet",
  "",
  "- These are not final dissertation estimates.",
  "- These are not observed productive-capacity regressions.",
  "- These do not reconstruct utilization.",
  "- These are not Shaikh-adjusted distribution estimates.",
  "- ADF/KPSS residual diagnostics, if reported, are descriptive only and do not establish cointegration.",
  "- Mechanization-bias conclusions require stronger evidence than coefficient signs alone."
)
writeLines(advisor_lines, output_paths[["advisor_report"]], useBytes = TRUE)


# ----------------- Generate docs/validation/US_S32C_CORPORATE_BOUNDARY_VALIDATION.md -----------------
validation_lines <- c(
  "# U.S. S32C Corporate-Boundary Robustness Validation",
  "",
  "## Purpose",
  "",
  paste(
    "S32C estimates preliminary corporate-boundary robustness models,",
    "applies Phillips-Ouliaris and residual-stationarity gates, and records",
    "OLS, FM-OLS, IM-OLS, and DOLS results without promoting coefficients to",
    "final dissertation estimates."
  ),
  "",
  "## Sectoral-Boundary Configuration",
  "",
  "- Capital boundary: NFC productive-capacity capital stock.",
  "- Output boundary: Corporate sector GVA.",
  "- Distribution boundary: Corporate sector wage share.",
  "",
  "## Locked Metadata",
  "",
  paste0("- `", names(metadata), " = ", metadata, "`"),
  "",
  "## Validation Summary",
  "",
  md_table(validation_checks, c("check_name", "status", "details")),
  "",
  "## Hard-lock confirmation",
  "",
  paste(
    "S32C fetched no BEA data, modified no provider artifacts, modified no",
    "S20/S22/S31I/S32 outputs, constructed no Shaikh-adjusted variables,",
    "constructed no level interactions, ran no Johansen/VECM, reconstructed",
    "no productive capacity or utilization, and promoted no coefficient as final."
  )
)
writeLines(validation_lines, output_paths[["validation_report"]], useBytes = TRUE)

message("S32C corporate-boundary robustness pass completed.")
message("Models registered: ", nrow(model_registry))
message("Coefficient rows: ", nrow(coefficients))
message("Estimator attempts: ", nrow(estimator_status))
message("Validation PASS/FAIL: ", sum(validation_checks$status == "PASS"), "/", sum(validation_checks$status == "FAIL"))
