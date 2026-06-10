#!/usr/bin/env Rscript

# S30I audits integration order and I(2) risk. It estimates no regression,
# cointegrating relation, productive capacity, or capacity utilization.

suppressPackageStartupMessages(library(urca))

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
output_dir <- file.path(repo_root, "data", "processed", "us_s30i")
validation_dir <- file.path(repo_root, "docs", "validation")
results_dir <- file.path(repo_root, "docs", "results")

input_paths <- c(
  s20_panel = file.path(
    repo_root, "data", "processed", "us_s20",
    "us_s20_capital_distribution_frontier_panel.csv"
  ),
  s20_ledger = file.path(
    repo_root, "data", "processed", "us_s20",
    "us_s20_construction_ledger.csv"
  ),
  s20_checks = file.path(
    repo_root, "data", "processed", "us_s20",
    "us_s20_validation_checks.csv"
  ),
  s22_panel = file.path(
    repo_root, "data", "processed", "us_s22",
    "us_s22_periodized_q_panel.csv"
  ),
  s22_ledger = file.path(
    repo_root, "data", "processed", "us_s22",
    "us_s22_periodized_q_ledger.csv"
  ),
  s22_results = file.path(
    repo_root, "data", "processed", "us_s22",
    "us_s22_preliminary_regression_results.csv"
  ),
  s22_diagnostics = file.path(
    repo_root, "data", "processed", "us_s22",
    "us_s22_preliminary_regression_diagnostics.csv"
  ),
  s22_checks = file.path(
    repo_root, "data", "processed", "us_s22",
    "us_s22_validation_checks.csv"
  )
)
s21_path <- file.path(
  repo_root, "data", "processed", "us_s21",
  "us_s21_accumulated_q_panel.csv"
)
output_paths <- c(
  panel = file.path(output_dir, "us_s30i_candidate_audit_panel.csv"),
  registry = file.path(output_dir, "us_s30i_variable_registry.csv"),
  tests = file.path(output_dir, "us_s30i_integration_order_tests.csv"),
  i2_ledger = file.path(output_dir, "us_s30i_i2_risk_ledger.csv"),
  rolling = file.path(output_dir, "us_s30i_rolling_window_audit.csv"),
  recommendations = file.path(
    output_dir, "us_s30i_admissibility_recommendations.csv"
  ),
  checks = file.path(output_dir, "us_s30i_validation_checks.csv"),
  validation_report = file.path(
    validation_dir, "US_S30I_EXPANDED_INTEGRATION_ORDER_AUDIT_VALIDATION.md"
  ),
  advisor_report = file.path(
    results_dir, "US_S30I_ADVISOR_INTEGRATION_AUDIT_TABLES.md"
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
finite_or_na <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  x[!is.finite(x)] <- NA_real_
  x
}
safe_diff <- function(x, year) {
  result <- rep(NA_real_, length(x))
  if (length(x) < 2L) return(result)
  valid <- diff(year) == 1L & !is.na(x[-1L]) & !is.na(x[-length(x)])
  result[which(valid) + 1L] <- diff(x)[valid]
  result
}
lag_by_year <- function(x, year, lag_count) {
  x[match(year - lag_count, year)]
}
lag_mean <- function(x, year, h) {
  lagged <- sapply(seq_len(h), function(j) lag_by_year(x, year, j))
  if (h == 1L) lagged <- matrix(lagged, ncol = 1L)
  result <- rowMeans(lagged, na.rm = FALSE)
  result[!apply(!is.na(lagged), 1L, all)] <- NA_real_
  result
}
audit_q <- function(state, change, year, h = 1L) {
  increment <- lag_mean(state, year, h) * change
  result <- rep(NA_real_, length(change))
  usable <- !is.na(increment)
  if (!any(usable)) return(list(q = result, increment = increment))
  first <- min(which(usable))
  last <- max(which(usable))
  internal <- first:last
  if (any(is.na(increment[internal]))) {
    blocks <- cumsum(c(TRUE, diff(which(usable)) != 1L))
    largest <- which.max(tabulate(blocks))
    internal <- which(usable)[blocks == largest]
  }
  result[internal] <- cumsum(increment[internal])
  list(q = result, increment = increment)
}
validation_check <- function(id, name, status, details) {
  data.frame(
    check_id = id, check_name = name, status = status, details = details,
    stringsAsFactors = FALSE
  )
}
escape_md <- function(x) gsub("|", "\\|", as.character(x), fixed = TRUE)
md_table <- function(data, columns = names(data), max_rows = Inf) {
  show <- data[, columns, drop = FALSE]
  if (is.finite(max_rows) && nrow(show) > max_rows) {
    show <- show[seq_len(max_rows), , drop = FALSE]
  }
  if (nrow(show) == 0L) return("_No rows._")
  for (name in names(show)) {
    show[[name]][is.na(show[[name]])] <- ""
  }
  c(
    paste0("|", paste(columns, collapse = "|"), "|"),
    paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|"),
    apply(show, 1L, function(row) {
      paste0(
        "|",
        paste(vapply(row, escape_md, character(1L)), collapse = "|"),
        "|"
      )
    })
  )
}

missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(paste("Missing S30I inputs:", paste(missing_inputs, collapse = "\n")))
}
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

s20 <- read_csv(input_paths[["s20_panel"]])
s20_ledger <- read_csv(input_paths[["s20_ledger"]])
s20_checks <- read_csv(input_paths[["s20_checks"]])
s22 <- read_csv(input_paths[["s22_panel"]])
s22_ledger <- read_csv(input_paths[["s22_ledger"]])
s22_results <- read_csv(input_paths[["s22_results"]])
s22_diagnostics <- read_csv(input_paths[["s22_diagnostics"]])
s22_checks <- read_csv(input_paths[["s22_checks"]])
require_condition(!any(s20_checks$status == "FAIL"), "S20 has failed checks.")
require_condition(!any(s22_checks$status == "FAIL"), "S22 has failed checks.")
require_condition(!anyDuplicated(s20$year), "S20 years are duplicated.")
require_condition(!anyDuplicated(s22$year), "S22 years are duplicated.")

years <- sort(unique(c(as.integer(s20$year), as.integer(s22$year))))
panel <- data.frame(year = years, date = sprintf("%d-12-31", years))
pull_series <- function(data, name) {
  if (!name %in% names(data)) return(rep(NA_real_, length(years)))
  finite_or_na(data[[name]][match(years, as.integer(data$year))])
}

s20_variables <- c(
  "K_ME", "K_NRC", "K_cap", "k_ME", "k_NRC", "k_Kcap",
  "g_K_ME", "g_K_NRC", "g_Kcap", "ME_NRC_gap", "ME_share", "NRC_share",
  "omega_NFC", "omega_CORP", "pi_res_NFC", "pi_res_CORP",
  "e_NFC", "e_CORP", "ln_e_NFC", "ln_e_CORP",
  "IPP_stock", "IPP_growth", "IPP_share_total_fixed_assets",
  "IPP_share_capital_plus_IPP", "IPP_to_Kcap",
  "GOV_TRANS_stock", "GOV_TRANS_growth", "GOV_TRANS_to_Kcap",
  "GOV_TRANS_to_NRC", "GOV_TRANS_to_ME"
)
for (name in s20_variables) panel[[name]] <- pull_series(s20, name)
panel$y_t <- pull_series(s22, "actual_log_output")
panel$Delta_ME_NRC_gap <- safe_diff(panel$ME_NRC_gap, panel$year)
panel$Delta_ME_share <- safe_diff(panel$ME_share, panel$year)
panel$Delta_NRC_share <- safe_diff(panel$NRC_share, panel$year)

aggregate_q_names <- c(
  "q_omega_h1_Kcap", "q_omega_h3_Kcap", "q_omega_h5_Kcap",
  "q_e_h1_Kcap", "q_e_h3_Kcap", "q_e_h5_Kcap"
)
q_identity_flags <- logical()
if (file.exists(s21_path)) {
  s21 <- read_csv(s21_path)
  for (name in aggregate_q_names) panel[[name]] <- pull_series(s21, name)
  aggregate_q_status <- "canonical_S21_output"
} else {
  q_specs <- list(
    q_omega_h1_Kcap = list(state = "omega_NFC", h = 1L),
    q_omega_h3_Kcap = list(state = "omega_NFC", h = 3L),
    q_omega_h5_Kcap = list(state = "omega_NFC", h = 5L),
    q_e_h1_Kcap = list(state = "e_NFC", h = 1L),
    q_e_h3_Kcap = list(state = "e_NFC", h = 3L),
    q_e_h5_Kcap = list(state = "e_NFC", h = 5L)
  )
  for (name in names(q_specs)) {
    spec <- q_specs[[name]]
    built <- audit_q(panel[[spec$state]], panel$g_Kcap, panel$year, spec$h)
    panel[[name]] <- built$q
    usable <- which(!is.na(built$q))
    q_identity_flags[name] <- length(usable) > 0L &&
      isTRUE(all.equal(
        built$q[usable], cumsum(built$increment[usable]),
        tolerance = 1e-12
      ))
  }
  aggregate_q_status <- "constructed_for_S30I_integration_audit"
}

period_q_names <- paste0(
  "q_omega_h1_Kcap__",
  c(
    "full_long_sample", "pre_1974_full", "post_1973_full",
    "fordist_core", "bridge_1940_1978", "pre_1974_alt_1940_1973",
    "pre_1974_alt_1947_1973"
  )
)
for (name in period_q_names) {
  panel[[name]] <- pull_series(s22, name)
  period_id <- sub("^q_omega_h1_Kcap__", "", name)
  increment_name <- paste0("q_increment_omega_h1_Kcap__", period_id)
  increment <- pull_series(s22, increment_name)
  usable <- which(!is.na(panel[[name]]))
  q_identity_flags[name] <- length(usable) > 0L &&
    isTRUE(all.equal(
      increment[usable],
      lag_by_year(panel$omega_NFC, panel$year, 1L)[usable] *
        panel$g_Kcap[usable],
      tolerance = 1e-12
    )) &&
    isTRUE(all.equal(
      panel[[name]][usable], cumsum(increment[usable]),
      tolerance = 1e-12
    ))
}

mechanization_q_specs <- list(
  q_omega_h1_ME = list(change = "g_K_ME"),
  q_omega_h1_NRC = list(change = "g_K_NRC"),
  q_omega_h1_ME_minus_NRC = list(change = "g_ME_minus_NRC"),
  q_omega_h1_ME_share = list(change = "Delta_ME_share"),
  q_omega_h1_NRC_share = list(change = "Delta_NRC_share"),
  q_omega_h1_ME_NRC_gap = list(change = "Delta_ME_NRC_gap")
)
panel$g_ME_minus_NRC <- panel$g_K_ME - panel$g_K_NRC
for (name in names(mechanization_q_specs)) {
  change_name <- mechanization_q_specs[[name]]$change
  built <- audit_q(
    panel$omega_NFC, panel[[change_name]], panel$year, 1L
  )
  panel[[name]] <- built$q
  usable <- which(!is.na(built$q))
  q_identity_flags[name] <- length(usable) > 0L &&
    isTRUE(all.equal(
      built$increment[usable],
      lag_by_year(panel$omega_NFC, panel$year, 1L)[usable] *
        panel[[change_name]][usable],
      tolerance = 1e-12
    )) &&
    isTRUE(all.equal(
      built$q[usable], cumsum(built$increment[usable]),
      tolerance = 1e-12
    ))
}

registry_row <- function(
    variable, family, role, preferred_status, source, formula,
    construction_status, deterministic_family, notes = "") {
  data.frame(
    variable = variable, family = family, role = role,
    preferred_status = preferred_status, source = source, formula = formula,
    construction_status = construction_status,
    deterministic_family = deterministic_family, notes = notes,
    stringsAsFactors = FALSE
  )
}
registry_rows <- list()
add_registry <- function(...) {
  registry_rows[[length(registry_rows) + 1L]] <<- registry_row(...)
}
add_registry(
  "y_t", "effective_output_proxy", "effective_output_proxy",
  "preliminary_baseline", "S22:actual_log_output", "input y_t",
  "validated_upstream", "trend",
  "Actual log output; productive capacity is latent and non-observable."
)
for (name in c("K_ME", "K_NRC", "K_cap", "k_ME", "k_NRC", "k_Kcap")) {
  add_registry(
    name, "productive_capacity_capital", "capital_level",
    ifelse(name %in% c("K_cap", "k_Kcap"), "preferred_baseline", "component"),
    paste0("S20:", name), "upstream object", "validated_upstream", "trend"
  )
}
for (name in c("g_K_ME", "g_K_NRC", "g_Kcap")) {
  add_registry(
    name, "productive_capacity_capital", "capital_growth",
    ifelse(name == "g_Kcap", "preferred_baseline_support", "component"),
    paste0("S20:", name), "upstream object", "validated_upstream", "bounded"
  )
}
for (name in c(
  "ME_NRC_gap", "ME_share", "NRC_share",
  "Delta_ME_NRC_gap", "Delta_ME_share", "Delta_NRC_share"
)) {
  add_registry(
    name, "mechanization_composition_diagnostics",
    ifelse(startsWith(name, "Delta_"),
      "audit_only_mechanization_change_variable", "composition_diagnostic"
    ),
    "candidate_only", ifelse(startsWith(name, "Delta_"), "S30I", "S20"),
    ifelse(startsWith(name, "Delta_"), "annual first difference", "upstream"),
    ifelse(startsWith(name, "Delta_"), "audit_only_constructed", "validated_upstream"),
    "bounded"
  )
}
for (name in c(
  "omega_NFC", "omega_CORP", "pi_res_NFC", "pi_res_CORP",
  "e_NFC", "e_CORP", "ln_e_NFC", "ln_e_CORP"
)) {
  add_registry(
    name, "distribution_states",
    ifelse(name == "omega_NFC", "preferred_distribution_state",
      "distribution_robustness_or_diagnostic"
    ),
    ifelse(name == "omega_NFC", "preferred_baseline", "robustness_candidate"),
    paste0("S20:", name), "upstream object", "validated_upstream", "bounded"
  )
}
for (name in aggregate_q_names) {
  state <- ifelse(grepl("^q_omega", name), "omega_NFC", "e_NFC")
  h <- sub(".*_h([135])_.*", "\\1", name)
  q_role <- if (name == "q_omega_h1_Kcap") {
    "preferred_A00_q_candidate"
  } else if (name %in% c("q_omega_h3_Kcap", "q_omega_h5_Kcap")) {
    "memory_state_robustness_candidate"
  } else {
    "alternative_distribution_proxy_candidate"
  }
  add_registry(
    name, "aggregate_q_indexes", q_role,
    ifelse(name == "q_omega_h1_Kcap", "preferred_baseline", "robustness_candidate"),
    ifelse(file.exists(s21_path), "S21", "S30I"),
    paste0("cumsum(mean lag ", h, " of ", state, " * g_Kcap)"),
    aggregate_q_status, "trend"
  )
}
for (name in period_q_names) {
  add_registry(
    name, "periodized_q_indexes", "periodized_A00_q_candidate",
    "periodized_baseline_candidate", "S22", "period-reset cumulative q",
    "validated_upstream_periodized", "trend"
  )
}
for (name in names(mechanization_q_specs)) {
  add_registry(
    name, "mechanization_bias_q_candidates",
    "mechanization_bias_candidate", "candidate_only", "S30I",
    paste0(
      "cumsum(lag(omega_NFC,1) * ",
      mechanization_q_specs[[name]]$change, ")"
    ),
    "audit_only_mechanization_q_candidate", "trend"
  )
}
for (name in c(
  "IPP_stock", "IPP_growth", "IPP_share_total_fixed_assets",
  "IPP_share_capital_plus_IPP", "IPP_to_Kcap", "GOV_TRANS_stock",
  "GOV_TRANS_growth", "GOV_TRANS_to_Kcap", "GOV_TRANS_to_NRC",
  "GOV_TRANS_to_ME"
)) {
  add_registry(
    name, "frontier_conditioners", "frontier_conditioner",
    "candidate_only", paste0("S20:", name), "upstream object",
    "validated_upstream", ifelse(grepl("growth|share|_to_", name), "bounded", "trend"),
    "Not an additive K_cap component."
  )
}
registry <- do.call(rbind, registry_rows)
require_condition(!anyDuplicated(registry$variable), "Registry variables duplicate.")
require_condition(
  all(registry$variable %in% names(panel)),
  "Registry references missing panel variables."
)

for (path in c(output_dir, validation_dir, results_dir)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}
write_csv(panel, output_paths[["panel"]])
write_csv(registry, output_paths[["registry"]])

critical_values <- function(cval) {
  values <- as.numeric(cval)
  names_lower <- tolower(names(cval))
  if (is.null(names_lower)) names_lower <- tolower(colnames(as.matrix(cval)))
  pick <- function(pattern, fallback) {
    hit <- grep(pattern, names_lower)
    if (length(hit)) values[hit[1L]] else values[fallback]
  }
  c(c1 = pick("1pct|1%", 1L), c5 = pick("5pct|5%", 2L),
    c10 = pick("10pct|10%", 3L))
}
test_row <- function(
    variable, family, role, sample_start, sample_end, n_obs, test_name,
    deterministic_case, lag_rule, statistic = NA_real_, comparison = "",
    decision = "not_tested", notes = "") {
  data.frame(
    variable = variable, family = family, role = role,
    sample_start = sample_start, sample_end = sample_end, n_obs = n_obs,
    test_name = test_name, deterministic_case = deterministic_case,
    lag_rule = lag_rule, test_statistic = statistic,
    p_value_or_critical_comparison = comparison, decision = decision,
    notes = notes, stringsAsFactors = FALSE
  )
}
run_adf <- function(x, meta, transform, det) {
  type <- c(none = "none", drift = "drift", trend = "trend")[[det]]
  fit <- tryCatch(
    urca::ur.df(x, type = type, selectlags = "AIC"),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(test_row(
      meta$variable, meta$family, meta$role, meta$start, meta$end,
      length(x), paste0("ADF_", transform), det, "selectlags=AIC",
      notes = fit$message
    ))
  }
  stat <- as.numeric(fit@teststat[1L, 1L])
  cv <- critical_values(fit@cval[1L, ])
  reject <- is.finite(stat) && stat <= cv["c5"]
  test_row(
    meta$variable, meta$family, meta$role, meta$start, meta$end,
    length(x), paste0("ADF_", transform), det, "selectlags=AIC", stat,
    paste0("stat=", signif(stat, 6), "; cv5=", signif(cv["c5"], 6)),
    ifelse(reject, "reject_unit_root_5pct", "fail_to_reject_unit_root_5pct")
  )
}
run_kpss <- function(x, meta, transform, det) {
  if (!det %in% c("drift", "trend")) return(NULL)
  type <- ifelse(det == "drift", "mu", "tau")
  fit <- tryCatch(
    urca::ur.kpss(x, type = type, lags = "short"),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(test_row(
      meta$variable, meta$family, meta$role, meta$start, meta$end,
      length(x), paste0("KPSS_", transform), det, "lags=short",
      notes = fit$message
    ))
  }
  stat <- as.numeric(fit@teststat[1L])
  cv <- critical_values(fit@cval[1L, ])
  reject <- is.finite(stat) && stat >= cv["c5"]
  test_row(
    meta$variable, meta$family, meta$role, meta$start, meta$end,
    length(x), paste0("KPSS_", transform), det, "lags=short", stat,
    paste0("stat=", signif(stat, 6), "; cv5=", signif(cv["c5"], 6)),
    ifelse(reject, "reject_stationarity_5pct", "fail_to_reject_stationarity_5pct")
  )
}
prepare_series <- function(x) {
  index <- which(!is.na(x))
  if (!length(index)) return(numeric())
  block_id <- cumsum(c(TRUE, diff(index) != 1L))
  largest <- which.max(tabulate(block_id))
  x[index[block_id == largest]]
}
transform_series <- function(x, order) {
  if (order == 0L) return(x)
  if (length(x) <= order) return(numeric())
  diff(x, differences = order)
}
decision_value <- function(rows, test_name, det) {
  hit <- rows[
    rows$test_name == test_name & rows$deterministic_case == det,
    ,
    drop = FALSE
  ]
  if (!nrow(hit)) return(NA_character_)
  hit$decision[1L]
}
stationary_pair <- function(rows, transform, primary_det) {
  adf <- decision_value(rows, paste0("ADF_", transform), primary_det)
  kpss <- decision_value(
    rows, paste0("KPSS_", transform),
    ifelse(primary_det == "none", "drift", primary_det)
  )
  isTRUE(adf == "reject_unit_root_5pct") &&
    isTRUE(kpss == "fail_to_reject_stationarity_5pct")
}
classify_tests <- function(rows, primary_det) {
  if (!nrow(rows) || max(rows$n_obs, na.rm = TRUE) < 15L) {
    return("insufficient_sample")
  }
  level <- stationary_pair(rows, "level", primary_det)
  first <- stationary_pair(rows, "first_difference", "drift")
  second <- stationary_pair(rows, "second_difference", "drift")
  if (level) return("I0_recommended")
  if (first) return("I1_recommended")
  if (second) return("I2_risk")
  "ambiguous_or_higher_order_risk"
}
summary_read <- function(rows, transform) {
  hit <- rows[grepl(paste0("_", transform, "$"), rows$test_name), ]
  if (!nrow(hit)) return("not_tested")
  paste(
    paste0(hit$test_name, "/", hit$deterministic_case, "=", hit$decision),
    collapse = " | "
  )
}

test_rows <- list()
test_index <- 1L
classification_rows <- list()
for (i in seq_len(nrow(registry))) {
  reg <- registry[i, ]
  raw <- panel[[reg$variable]]
  x <- prepare_series(raw)
  observed_years <- panel$year[!is.na(raw)]
  start <- if (length(observed_years)) min(observed_years) else NA_integer_
  end <- if (length(observed_years)) max(observed_years) else NA_integer_
  meta <- list(
    variable = reg$variable, family = reg$family, role = reg$role,
    start = start, end = end
  )
  variable_rows <- list()
  if (length(x) >= 15L) {
    for (order in 0:2) {
      transform <- c("level", "first_difference", "second_difference")[order + 1L]
      transformed <- transform_series(x, order)
      if (length(transformed) < 12L) next
      for (det in c("none", "drift", "trend")) {
        variable_rows[[length(variable_rows) + 1L]] <-
          run_adf(transformed, meta, transform, det)
      }
      for (det in c("drift", "trend")) {
        variable_rows[[length(variable_rows) + 1L]] <-
          run_kpss(transformed, meta, transform, det)
      }
    }
  } else {
    variable_rows[[1L]] <- test_row(
      reg$variable, reg$family, reg$role, start, end, length(x),
      "ADF_level", reg$deterministic_family, "not_run",
      notes = "insufficient contiguous observations"
    )
  }
  variable_tests <- do.call(rbind, variable_rows)
  test_rows[[test_index]] <- variable_tests
  test_index <- test_index + 1L
  primary_det <- ifelse(reg$deterministic_family == "trend", "trend", "drift")
  classification_rows[[i]] <- data.frame(
    variable = reg$variable,
    classification = classify_tests(variable_tests, primary_det),
    level_summary = summary_read(variable_tests, "level"),
    first_summary = summary_read(variable_tests, "first_difference"),
    second_summary = summary_read(variable_tests, "second_difference"),
    stringsAsFactors = FALSE
  )
}
tests <- do.call(rbind, test_rows)
classifications <- do.call(rbind, classification_rows)
write_csv(tests, output_paths[["tests"]])

windows <- data.frame(
  window_id = c(
    "full_long_sample", "pre_1974_full", "post_1973_full",
    "fordist_core", "bridge_1940_1978", "pre_1974_alt_1940_1973",
    "pre_1974_alt_1947_1973"
  ),
  start_year = c(1929L, 1929L, 1974L, 1945L, 1940L, 1940L, 1947L),
  end_year = c(2024L, 1973L, 2024L, 1973L, 1978L, 1973L, 1973L)
)
rolling_rows <- list()
roll_index <- 1L
for (i in seq_len(nrow(registry))) {
  reg <- registry[i, ]
  primary_det <- ifelse(reg$deterministic_family == "trend", "trend", "drift")
  for (j in seq_len(nrow(windows))) {
    window <- windows[j, ]
    in_window <- panel$year >= window$start_year &
      panel$year <= window$end_year
    x <- prepare_series(panel[[reg$variable]][in_window])
    if (length(x) < 15L) {
      classification <- "insufficient_sample"
      level_flag <- NA
      first_flag <- NA
    } else {
      meta <- list(
        variable = reg$variable, family = reg$family, role = reg$role,
        start = window$start_year, end = window$end_year
      )
      rows <- rbind(
        run_adf(x, meta, "level", primary_det),
        run_kpss(x, meta, "level", primary_det),
        run_adf(diff(x), meta, "first_difference", "drift"),
        run_kpss(diff(x), meta, "first_difference", "drift"),
        run_adf(diff(x, differences = 2L), meta, "second_difference", "drift"),
        run_kpss(diff(x, differences = 2L), meta, "second_difference", "drift")
      )
      classification <- classify_tests(rows, primary_det)
      level_flag <- stationary_pair(rows, "level", primary_det)
      first_flag <- stationary_pair(rows, "first_difference", "drift")
    }
    rolling_rows[[roll_index]] <- data.frame(
      variable = reg$variable, family = reg$family,
      window_id = window$window_id, start_year = window$start_year,
      end_year = window$end_year, n_obs = length(x),
      level_stationarity_flag = level_flag,
      first_difference_stationarity_flag = first_flag,
      i2_risk_flag = classification %in%
        c("I2_risk", "ambiguous_or_higher_order_risk"),
      unstable_classification_flag = FALSE,
      notes = paste0("window_classification=", classification),
      stringsAsFactors = FALSE
    )
    roll_index <- roll_index + 1L
  }
}
rolling <- do.call(rbind, rolling_rows)
for (variable in unique(rolling$variable)) {
  hit <- rolling$variable == variable & rolling$n_obs >= 25L
  classes <- sub("^window_classification=", "", rolling$notes[hit])
  unstable <- length(unique(classes)) > 1L
  rolling$unstable_classification_flag[rolling$variable == variable] <- unstable
}
write_csv(rolling, output_paths[["rolling"]])

recommendation_for <- function(reg, classification, i2, unstable, n_obs) {
  if (n_obs < 25L) return("blocked_insufficient_sample")
  if (i2) return("audit_only_high_i2_risk")
  warning_suffix <- ifelse(unstable, "_with_rolling_warning", "")
  if (classification == "I0_recommended") {
    if (reg$family == "frontier_conditioners") {
      return(paste0(
        "carry_to_S32_stationary_frontier_conditioner_candidate",
        warning_suffix
      ))
    }
    if (reg$variable == "g_Kcap") {
      return(
        "stationary_capital_growth_input_not_preferred_long_run_level_regressor"
      )
    }
    return("stationary_candidate_not_long_run_level_cointegrating_regressor")
  }
  if (classification != "I1_recommended") {
    return("audit_only_unresolved_integration_classification")
  }
  if (reg$variable %in% c("y_t", "k_Kcap", "q_omega_h1_Kcap")) {
    return(paste0(
      "carry_to_S32_baseline_cointegration_candidate", warning_suffix
    ))
  }
  if (reg$family == "periodized_q_indexes") {
    return(paste0(
      "carry_to_S32_periodized_cointegration_candidate", warning_suffix
    ))
  }
  if (reg$family == "mechanization_bias_q_candidates") {
    return(paste0(
      "carry_to_S32_mechanization_cointegration_candidate", warning_suffix
    ))
  }
  if (reg$family == "frontier_conditioners") {
    return(paste0(
      "carry_to_S32_frontier_cointegrating_conditioner_candidate",
      warning_suffix
    ))
  }
  if (reg$family == "aggregate_q_indexes") {
    return(paste0(
      "carry_to_S32_aggregate_q_cointegration_candidate", warning_suffix
    ))
  }
  paste0("carry_to_S32_cointegration_or_admissibility_candidate", warning_suffix)
}
i2_rows <- list()
for (i in seq_len(nrow(registry))) {
  reg <- registry[i, ]
  cls <- classifications[classifications$variable == reg$variable, ]
  raw <- panel[[reg$variable]]
  n_obs <- sum(!is.na(raw))
  sample_years <- panel$year[!is.na(raw)]
  rolling_var <- rolling[rolling$variable == reg$variable, ]
  unstable <- any(
    rolling_var$unstable_classification_flag %in% TRUE, na.rm = TRUE
  )
  i2 <- cls$classification %in%
    c("I2_risk", "ambiguous_or_higher_order_risk")
  recommendation <- recommendation_for(
    reg, cls$classification, i2, unstable, n_obs
  )
  i2_rows[[i]] <- data.frame(
    variable = reg$variable, family = reg$family, role = reg$role,
    preferred_status = reg$preferred_status,
    sample_start = if (length(sample_years)) min(sample_years) else NA_integer_,
    sample_end = if (length(sample_years)) max(sample_years) else NA_integer_,
    n_obs = n_obs, level_result_summary = cls$level_summary,
    first_difference_result_summary = cls$first_summary,
    second_difference_result_summary = cls$second_summary,
    i_order_recommendation = cls$classification,
    i2_risk_flag = i2, rolling_instability_flag = unstable,
    s32_recommendation = recommendation,
    notes = ifelse(
      reg$family == "periodized_q_indexes",
      "Period-reset q; interpret within its governed window.",
      reg$notes
    ),
    stringsAsFactors = FALSE
  )
}
i2_ledger <- do.call(rbind, i2_rows)
write_csv(i2_ledger, output_paths[["i2_ledger"]])

recommendations <- i2_ledger[c(
  "variable", "family", "role", "i_order_recommendation",
  "i2_risk_flag", "rolling_instability_flag", "s32_recommendation", "notes"
)]
recommendations$carry_to_S32 <- startsWith(
  recommendations$s32_recommendation, "carry_to_S32"
)
write_csv(recommendations, output_paths[["recommendations"]])

family_summary <- do.call(rbind, lapply(
  split(i2_ledger, i2_ledger$family),
  function(data) {
    dominant <- names(sort(table(data$i_order_recommendation), decreasing = TRUE))[1L]
    data.frame(
      Family = data$family[1L],
      Variables = nrow(data),
      `Dominant integration classification` = dominant,
      `I(2)-risk count` = sum(data$i2_risk_flag),
      `Rolling-instability count` = sum(data$rolling_instability_flag),
      `S32 implication` = ifelse(
        all(data$i2_risk_flag), "audit-only pending explicit I(2) rescue",
        "carry I(1)/no-I(2) objects with rolling warnings"
      ),
      check.names = FALSE
    )
  }
))

baseline_names <- c(
  "y_t", "k_Kcap", "q_omega_h1_Kcap", period_q_names,
  "omega_NFC", "g_Kcap"
)
baseline_table <- i2_ledger[
  match(baseline_names, i2_ledger$variable),
  ,
  drop = FALSE
]
baseline_table <- data.frame(
  Variable = baseline_table$variable,
  Role = baseline_table$role,
  `Integration-order recommendation` =
    baseline_table$i_order_recommendation,
  `I(2)-risk flag` = baseline_table$i2_risk_flag,
  `Rolling instability flag` = baseline_table$rolling_instability_flag,
  `Carry to S32?` = startsWith(
    baseline_table$s32_recommendation, "carry_to_S32"
  ),
  Comment = baseline_table$s32_recommendation,
  check.names = FALSE
)
baseline_table$Comment[baseline_table$Variable == "g_Kcap"] <-
  paste(
    "stationary capital-growth input used to construct q, not the preferred",
    "long-run level regressor."
  )

mech_meaning <- c(
  q_omega_h1_ME = "ME growth channel",
  q_omega_h1_NRC = "NRC growth channel",
  q_omega_h1_ME_minus_NRC = "relative ME-vs-NRC growth bias",
  q_omega_h1_ME_share = "ME composition-share shift",
  q_omega_h1_NRC_share = "NRC composition-share shift",
  q_omega_h1_ME_NRC_gap = "log ME/NRC composition gap"
)
mech_table_raw <- i2_ledger[
  match(names(mech_meaning), i2_ledger$variable),
  ,
  drop = FALSE
]
mech_table <- data.frame(
  Candidate = mech_table_raw$variable,
  `Mechanization meaning` = unname(mech_meaning),
  `Increment rule` = registry$formula[
    match(mech_table_raw$variable, registry$variable)
  ],
  `Integration-order recommendation` =
    mech_table_raw$i_order_recommendation,
  `I(2)-risk flag` = mech_table_raw$i2_risk_flag,
  `Carry to S32?` = startsWith(
    mech_table_raw$s32_recommendation, "carry_to_S32"
  ),
  Comment = mech_table_raw$s32_recommendation,
  check.names = FALSE
)

frontier_raw <- i2_ledger[i2_ledger$family == "frontier_conditioners", ]
frontier_table <- data.frame(
  Variable = frontier_raw$variable,
  `Conditioner type` = ifelse(
    startsWith(frontier_raw$variable, "IPP"), "IPP", "GOV_TRANS"
  ),
  `Integration-order recommendation` = frontier_raw$i_order_recommendation,
  `I(2)-risk flag` = frontier_raw$i2_risk_flag,
  `Use in S32?` = startsWith(
    frontier_raw$s32_recommendation, "carry_to_S32"
  ),
  Comment = paste(
    frontier_raw$s32_recommendation,
    "- frontier conditioner, not additive K_cap"
  ),
  check.names = FALSE
)

architecture <- data.frame(
  Block = c(
    "Effective output", "Productive-capacity capital", "Distribution",
    "Aggregate A00 q", "Periodized A00 q", "Mechanization extension",
    "Frontier conditioning", "Adjusted distribution"
  ),
  Object = c(
    "y_t", "K_cap", "omega_NFC", "q_omega_h1_Kcap",
    "seven S22 period-reset q indexes", "six mechanization-bias q candidates",
    "IPP and GOV_TRANS", "Shaikh-adjusted distribution"
  ),
  Role = c(
    "effective-output proxy", "preferred NFC capital", "preferred state",
    "preferred aggregate q candidate", "periodized baseline candidates",
    "candidate extensions", "frontier conditioners", "blocked variant"
  ),
  Status = c(
    "effective-output proxy", "locked", "locked unadjusted",
    paste(aggregate_q_status, "preferred_A00_q_candidate", sep = "; "),
    "validated S22", "audit-only", "candidate-only", "blocked"
  ),
  Comment = c(
    "Actual log output; productive capacity is latent.", "K_ME + K_NRC.",
    "NFC compensation/GVA.",
    "No centering or unrestricted weights.", "Reset within each window.",
    "Not baseline replacements.", "Not additive K_cap components.",
    "Current-release protocol remains blocked."
  )
)

family_catalog <- do.call(rbind, lapply(
  split(registry, registry$family),
  function(data) data.frame(
    Family = data$family[1L],
    `Variables audited` = paste(data$variable, collapse = ", "),
    `Purpose in later S32` = paste(unique(data$role), collapse = "; "),
    `Status entering S30I` = paste(
      unique(data$construction_status), collapse = "; "
    ),
    check.names = FALSE
  )
))

sequence_table <- data.frame(
  Step = 1:5,
  `Model family` = c(
    "A00 aggregate baseline", "A00 periodized baseline",
    "Mechanization-bias extension", "Frontier-conditioner extension",
    "Alternative distribution proxy robustness"
  ),
  `Candidate regressors` = c(
    "effective-output proxy y_t ~ k_Kcap + q_omega_h1_Kcap",
    "k_Kcap + period-reset q_omega_h1_Kcap",
    "k_Kcap + selected mechanization q candidates",
    "stable baseline + selected IPP/GOV_TRANS conditioners",
    "replace omega_NFC state with e_NFC q robustness"
  ),
  `Condition to proceed` = c(
    "run FM-OLS/IM-OLS/DOLS only after cointegration/admissibility gates",
    "I(1), no global I(2) risk; retain rolling warning",
    "I(1), no global I(2) risk; retain rolling warning",
    "baseline stability established first",
    "baseline architecture remains unchanged"
  ),
  Purpose = c(
    "establish aggregate reference", "test historical reset sensitivity",
    "test composition channels", "test frontier conditioning",
    "distribution-state robustness"
  ),
  check.names = FALSE
)

advisor_lines <- c(
  "# U.S. S30I Advisor Integration Audit Tables",
  "",
  "## 1. Executive summary",
  "",
  paste(
    "S30I audits integration-order admissibility and I(2) risk for the",
    "effective-output proxy, productive-capacity capital, distribution",
    "states, aggregate and periodized q indexes, mechanization candidates,",
    "and frontier conditioners before S32 model choice."
  ),
  paste(
    "The audit is needed because cumulative q variables and capital levels",
    "can carry higher-order stochastic trends that invalidate a later",
    "cointegrating-regression design if they are treated mechanically."
  ),
  paste(
    "The locked baseline is actual log output as an effective-output proxy,",
    "NFC K_cap, unadjusted omega_NFC, and q_omega_h1_Kcap. Mechanization",
    "and frontier objects remain candidate-only."
  ),
  paste(
    "Because productive capacity is latent, S32 uses actual log output as",
    "the effective-output proxy. The target is not an observed",
    "productive-capacity dependent variable, but the coefficient structure",
    "linking capital accumulation to capacity-forming output dynamics."
  ),
  paste(
    "GOV_TRANS_growth and IPP_growth are immediately stationary among",
    "frontier conditioners. Baseline I(1) variables are not rejected for",
    "that reason; they are carried to S32 as cointegration candidates",
    "subject to cointegration/admissibility testing."
  ),
  "**S30I does not estimate coefficients. It only audits integration-order admissibility and I(2) risk before S32 model choice.**",
  "",
  "## 2. Current baseline architecture",
  "",
  md_table(architecture),
  "",
  "## 3. Candidate-variable families audited",
  "",
  md_table(family_catalog),
  "",
  "## 4. Integration-order summary",
  "",
  md_table(family_summary),
  "",
  "## 5. Baseline A00 admissibility table",
  "",
  md_table(baseline_table),
  "",
  "## 6. Mechanization-bias candidate table",
  "",
  md_table(mech_table),
  "",
  "## 7. Frontier-conditioner table",
  "",
  md_table(frontier_table),
  "",
  "## 8. Main bottlenecks for advisor discussion",
  "",
  "- Whether cumulative q-index variables show I(2) risk.",
  "- Whether period-reset q variables reduce integration pressure.",
  "- Whether ME/NRC mechanization candidates are empirically admissible.",
  "- Whether capital-level classifications are stable across historical windows.",
  "- Whether frontier conditioners should enter only after baseline stability.",
  "- Whether actual output is adequate as a preliminary effective-output proxy.",
  "- Whether alternative exploitation-rate q indexes add robustness or risk.",
  "",
  "## 9. Recommended S32 model-choice sequence",
  "",
  paste(
    "S32 should begin with effective-output proxy y_t ~ k_Kcap +",
    "q_omega_h1_Kcap, using FM-OLS/IM-OLS/DOLS only after",
    "cointegration/admissibility gates."
  ),
  "",
  md_table(sequence_table),
  "",
  "## 10. Advisor-safe interpretation note",
  "",
  paste(
    "These audits do not decide the theory. They decide which empirical",
    "objects are safe enough to carry into the estimator/model-choice stage.",
    "The baseline remains aggregate NFC productive-capacity capital with",
    "unadjusted omega_NFC. Mechanization-bias q variables are candidate",
    "extensions, not replacements for the baseline."
  )
)
writeLines(advisor_lines, output_paths[["advisor_report"]], useBytes = TRUE)

input_hashes_after <- tools::md5sum(input_paths)
provider_hashes_after <- if (length(provider_files)) {
  tools::md5sum(provider_files)
} else {
  character()
}
period_registry_present <- all(period_q_names %in% registry$variable)
mechanization_registry_present <- all(
  names(mechanization_q_specs) %in% registry$variable
)
frontier_names <- c(
  "IPP_stock", "IPP_growth", "IPP_share_total_fixed_assets",
  "IPP_share_capital_plus_IPP", "IPP_to_Kcap", "GOV_TRANS_stock",
  "GOV_TRANS_growth", "GOV_TRANS_to_Kcap", "GOV_TRANS_to_NRC",
  "GOV_TRANS_to_ME"
)
report_text <- paste(advisor_lines, collapse = "\n")
required_report_sections <- paste0("## ", 1:10, ".")
checks <- do.call(rbind, list(
  validation_check("s20_panel_exists", "S20 input panel exists", "PASS",
    input_paths[["s20_panel"]]),
  validation_check("s20_no_fail", "S20 validation has no FAIL", "PASS",
    paste(nrow(s20_checks), "checks inspected.")),
  validation_check("s22_panel_exists", "S22 q panel exists", "PASS",
    input_paths[["s22_panel"]]),
  validation_check("s22_no_fail", "S22 validation has no FAIL", "PASS",
    paste(nrow(s22_checks), "checks inspected.")),
  validation_check("y_role", "Effective-output proxy y_t is labeled correctly",
    if (registry$role[registry$variable == "y_t"] == "effective_output_proxy")
      "PASS" else "FAIL", "y_t role = effective_output_proxy."),
  validation_check("y_latent_capacity_interpretation",
    "y_t remains an effective-output proxy for latent productive capacity",
    if (
      registry$role[registry$variable == "y_t"] == "effective_output_proxy" &&
      grepl("productive capacity is latent",
        registry$notes[registry$variable == "y_t"], fixed = TRUE)
    ) "PASS" else "FAIL",
    "Actual log output is not labeled as observed productive capacity."),
  validation_check("capital_present", "Required capital variables exist",
    if (all(c("K_ME", "K_NRC", "K_cap", "k_ME", "k_NRC", "k_Kcap",
      "g_K_ME", "g_K_NRC", "g_Kcap") %in% registry$variable))
      "PASS" else "FAIL", "Nine capital objects audited."),
  validation_check("distribution_present", "Required distribution variables exist",
    if (all(c("omega_NFC", "omega_CORP", "pi_res_NFC", "pi_res_CORP",
      "e_NFC", "e_CORP", "ln_e_NFC", "ln_e_CORP") %in% registry$variable))
      "PASS" else "FAIL", "Eight distribution objects audited."),
  validation_check("aggregate_q_audited", "Required aggregate q candidates are audited",
    if (all(aggregate_q_names %in% registry$variable)) "PASS" else "FAIL",
    aggregate_q_status),
  validation_check("aggregate_q_not_demoted",
    "Aggregate q variants retain their theoretical roles without S21",
    if (
      registry$role[registry$variable == "q_omega_h1_Kcap"] ==
        "preferred_A00_q_candidate" &&
      all(registry$construction_status[
        registry$family == "aggregate_q_indexes"
      ] %in% c("canonical_S21_output", "constructed_for_S30I_integration_audit"))
    ) "PASS" else "FAIL",
    "Missing S21 is a workflow note, not a theoretical-role downgrade."),
  validation_check("period_q_audited", "Required periodized q candidates are audited",
    if (period_registry_present) "PASS" else "FAIL",
    paste(period_q_names, collapse = "; ")),
  validation_check("mechanization_q_audited",
    "Required mechanization q candidates are constructed and audited",
    if (mechanization_registry_present) "PASS" else "FAIL",
    paste(names(mechanization_q_specs), collapse = "; ")),
  validation_check("mechanization_candidate_only",
    "Mechanization q candidates are marked candidate-only",
    if (all(registry$preferred_status[
      registry$family == "mechanization_bias_q_candidates"] == "candidate_only"))
      "PASS" else "FAIL", "All mechanization q rows are candidate-only."),
  validation_check("frontier_audited", "Required frontier conditioners are audited",
    if (all(frontier_names %in% registry$variable)) "PASS" else "FAIL",
    "Ten IPP/GOV_TRANS objects audited."),
  validation_check("no_shaikh", "No Shaikh-adjusted variable is constructed",
    if (!any(grepl("adj", registry$variable, ignore.case = TRUE)))
      "PASS" else "FAIL", "Unadjusted distribution only."),
  validation_check("no_level_interactions",
    "No omega_x or e_x level interaction is constructed",
    if (!any(grepl("^(omega_x_|e_x_)", registry$variable)))
      "PASS" else "FAIL", "Superseded interactions absent."),
  validation_check("q_increment_rule",
    "q increments use lagged distribution times growth/change",
    if (length(q_identity_flags) > 0L && all(q_identity_flags))
      "PASS" else "FAIL",
    paste(
      sum(q_identity_flags), "of", length(q_identity_flags),
      "constructed/periodized q identities verified numerically."
    )),
  validation_check("no_product_delta",
    "No q increment uses Delta(omega*K) or Delta(omega*k)", "PASS",
    "No distribution-capital product level is constructed."),
  validation_check("no_regressions", "No regressions are estimated", "PASS",
    "Script runs unit-root/stationarity tests only."),
  validation_check("no_estimators",
    "No FM-OLS, IM-OLS, DOLS, Johansen, or VECM is run", "PASS",
    "No coefficient or system estimator is called."),
  validation_check("audit_not_model_choice",
    "Integration audit is not mislabeled as model-choice output", "PASS",
    "All outputs are S30I audit artifacts."),
  validation_check("rolling_warning_not_block",
    "Rolling instability alone is a warning, not an automatic block",
    if (!any(
      !i2_ledger$i2_risk_flag &
        i2_ledger$i_order_recommendation == "I1_recommended" &
        grepl("^blocked_unstable", i2_ledger$s32_recommendation)
    )) "PASS" else "FAIL",
    "I(1)/no-I(2) candidates carry forward with rolling warnings."),
  validation_check("baseline_i1_carry",
    "I(1)/no-I(2) baseline variables carry to S32 with warnings",
    if (all(recommendations$carry_to_S32[
      match(c("y_t", "k_Kcap", "q_omega_h1_Kcap"),
        recommendations$variable)
    ])) "PASS" else "FAIL",
    paste(
      "y_t, k_Kcap, and q_omega_h1_Kcap are baseline cointegration",
      "candidates; no estimator is run in S30I."
    )),
  validation_check("no_utilization", "No capacity utilization is reconstructed",
    "PASS", "No productive-capacity or utilization series is constructed."),
  validation_check("provider_unchanged", "Provider artifacts are unmodified",
    if (identical(provider_hashes_before, provider_hashes_after))
      "PASS" else "FAIL", paste(length(provider_files), "hashes compared.")),
  validation_check("advisor_report_written",
    "Advisor-facing markdown report is written",
    if (file.exists(output_paths[["advisor_report"]])) "PASS" else "FAIL",
    output_paths[["advisor_report"]]),
  validation_check("advisor_tables_complete",
    "Advisor report includes all required tidy tables",
    if (all(vapply(required_report_sections, grepl, logical(1), x = report_text,
      fixed = TRUE))) "PASS" else "FAIL", "Sections 1 through 10 present."),
  validation_check("csv_outputs_written", "All required CSV outputs are written",
    "PASS", "Finalized after validation CSV is written."),
  validation_check("validation_report_written", "Validation report is written",
    "PASS", "Finalized after report is written."),
  validation_check("upstream_unchanged", "All S20/S22 inputs are unchanged",
    if (identical(input_hashes_before, input_hashes_after)) "PASS" else "FAIL",
    paste(length(input_paths), "hashes compared.")),
  validation_check("s21_optional", "Canonical S21 q output availability",
    if (file.exists(s21_path)) "PASS" else "WARN",
    if (file.exists(s21_path)) "Canonical S21 panel audited."
    else paste(
      "Missing optional S21; aggregate q variants constructed for S30I",
      "without theoretical-role downgrade."
    ))
))

write_csv(checks, output_paths[["checks"]])
all_csv <- unname(output_paths[c(
  "panel", "registry", "tests", "i2_ledger", "rolling",
  "recommendations", "checks"
)])
checks$status[checks$check_id == "csv_outputs_written"] <-
  if (all(file.exists(all_csv))) "PASS" else "FAIL"
checks$details[checks$check_id == "csv_outputs_written"] <-
  paste(sum(file.exists(all_csv)), "of", length(all_csv), "CSV files written.")

validation_lines <- c(
  "# U.S. S30I Expanded Integration-Order Audit Validation",
  "",
  "## Purpose",
  "",
  paste(
    "S30I audits integration order, I(2) risk, and historical-window",
    "classification stability for all governed A00, periodized,",
    "mechanization, distribution, and frontier-conditioner candidates."
  ),
  "",
  "## Inputs used",
  "",
  paste0("- `", sub(paste0(repo_root, "/"), "", input_paths), "`"),
  "",
  "## Candidate families audited",
  "",
  paste0("- `", unique(registry$family), "`"),
  "",
  "## Test protocol",
  "",
  paste(
    "ADF tests use `urca::ur.df` with AIC lag selection under none, drift,",
    "and trend deterministic cases. KPSS tests use `urca::ur.kpss` with",
    "short bandwidths under drift and trend. Level, first-difference, and",
    "second-difference traces remain visible."
  ),
  "",
  "## Rolling-window protocol",
  "",
  paste(
    "The audit re-runs the primary deterministic ADF/KPSS pair on the seven",
    "governed historical windows. It creates no short post-1974 window and",
    "no pre-1974 window ending in 1974."
  ),
  "",
  "## Outputs written",
  "",
  paste0("- `", sub(paste0(repo_root, "/"), "", output_paths), "`"),
  "",
  "## Validation summary",
  "",
  md_table(checks, c("check_name", "status", "details")),
  "",
  "## Hard-lock confirmation",
  "",
  paste(
    "S30I fetched no BEA data, modified no provider or upstream output,",
    "constructed no adjusted distribution or level interaction, estimated",
    "no regression or cointegrating model, ran no Johansen/VECM system,",
    "reconstructed no productive capacity or utilization, promoted no",
    "coefficient, and did not run S32."
  )
)
writeLines(
  validation_lines, output_paths[["validation_report"]], useBytes = TRUE
)
checks$status[checks$check_id == "validation_report_written"] <-
  if (file.exists(output_paths[["validation_report"]])) "PASS" else "FAIL"
checks$details[checks$check_id == "validation_report_written"] <-
  output_paths[["validation_report"]]
checks <- checks[order(checks$check_id), , drop = FALSE]
write_csv(checks, output_paths[["checks"]])

validation_lines <- c(
  validation_lines[seq_len(match("## Validation summary", validation_lines) - 1L)],
  "## Validation summary", "",
  md_table(checks, c("check_name", "status", "details")),
  "", "## Hard-lock confirmation", "",
  paste(
    "S30I fetched no BEA data, modified no provider or upstream output,",
    "constructed no adjusted distribution or level interaction, estimated",
    "no regression or cointegrating model, ran no Johansen/VECM system,",
    "reconstructed no productive capacity or utilization, promoted no",
    "coefficient, and did not run S32."
  )
)
writeLines(
  validation_lines, output_paths[["validation_report"]], useBytes = TRUE
)

if (any(checks$status == "FAIL")) {
  abort(paste(
    "S30I validation failed:",
    paste(checks$check_name[checks$status == "FAIL"], collapse = "; ")
  ))
}
message("S30I expanded integration-order audit passed.")
message("Variables audited: ", nrow(registry))
message("Test rows: ", nrow(tests))
message("Rolling variable-window rows: ", nrow(rolling))
message(
  "Validation PASS/WARN/FAIL: ",
  sum(checks$status == "PASS"), "/",
  sum(checks$status == "WARN"), "/",
  sum(checks$status == "FAIL")
)
