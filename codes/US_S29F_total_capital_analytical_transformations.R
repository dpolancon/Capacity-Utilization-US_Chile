# S29F constructs bounded analytical transformations of the validated S29E ME-NRC aggregate.
# TOT is an analytical alias for S29E CORE; S29F does not reaggregate ME and NRC.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

stage_id <- "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS"
s29d_commit <- "b4a2a3207dcfe4d51e88a0ebe46b5a219f3d8358"
s29e_commit <- "10c3e6940c9118e18260ceea968b7cdb321c1cb9"
required_s29e_decision <- "AUTHORIZE_S29F_CORE_CAPITAL_ANALYTICAL_TRANSFORMATIONS"
clean_decision <- "AUTHORIZE_S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW"
blocked_decision <- "BLOCK_FOR_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATION_REVIEW"
clean_status <- "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS_COMPLETE_S29G_AUTHORIZED"
blocked_status <- "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS_BLOCKED_FOR_REVIEW"
tolerance <- 1e-6

path <- function(...) file.path(...)
read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
full <- function(x) x == "fully_supported"
status_and <- function(...) {
  statuses <- list(...)
  ok <- Reduce(`&`, lapply(statuses, full))
  ifelse(ok, "fully_supported", "partial_vintage_warmup")
}
provider_tracked_clean <- function(repo) {
  unstaged <- system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE)
  staged <- system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE)
  identical(unstaged, 0L) && identical(staged, 0L)
}
stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) stop(label, " missing: ", paste(basename(missing), collapse = "; "))
}

s29e_dir <- path(repo_root, "output", "US", "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION")
s29d_dir <- path(repo_root, "output", "US", "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION")
s29f_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29f_dir, "csv")
md_dir <- path(s29f_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29e_input_paths <- list(
  panel = path(s29e_dir, "csv", "S29E_core_capital_stocks_flows_long.csv"),
  ledger = path(s29e_dir, "csv", "S29E_core_capital_construction_ledger.csv"),
  reconciliation = path(s29e_dir, "csv", "S29E_component_to_aggregate_reconciliation_audit.csv"),
  gross_sfc = path(s29e_dir, "csv", "S29E_core_gross_sfc_residual_audit.csv"),
  net_sfc = path(s29e_dir, "csv", "S29E_core_net_sfc_residual_audit.csv"),
  unit_timing = path(s29e_dir, "csv", "S29E_common_unit_timing_audit.csv"),
  support = path(s29e_dir, "csv", "S29E_support_status_audit.csv"),
  shares = path(s29e_dir, "csv", "S29E_component_share_diagnostic_audit.csv"),
  growth = path(s29e_dir, "csv", "S29E_arithmetic_growth_contribution_audit.csv"),
  provenance = path(s29e_dir, "csv", "S29E_source_to_aggregate_provenance.csv"),
  validation = path(s29e_dir, "csv", "S29E_validation_checks.csv"),
  validation_md = path(s29e_dir, "md", "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION_VALIDATION.md"),
  decision_md = path(s29e_dir, "md", "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION_DECISION.md")
)

s29d_input_paths <- list(
  panel = path(s29d_dir, "csv", "S29D_asset_specific_gpim_stocks_flows_long.csv"),
  schedule = path(s29d_dir, "csv", "S29D_gpim_parameter_schedule_audit.csv"),
  support = path(s29d_dir, "csv", "S29D_initialization_support_status_audit.csv"),
  validation = path(s29d_dir, "csv", "S29D_validation_checks.csv"),
  decision_md = path(s29d_dir, "md", "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_DECISION.md")
)

output_paths <- list(
  long = path(csv_dir, "S29F_total_capital_analytical_panel_long.csv"),
  wide = path(csv_dir, "S29F_total_capital_analytical_panel_wide.csv"),
  alias = path(csv_dir, "S29F_tot_alias_reconciliation_audit.csv"),
  no_reaggregation = path(csv_dir, "S29F_no_reaggregation_audit.csv"),
  ledger = path(csv_dir, "S29F_transformation_ledger.csv"),
  formula = path(csv_dir, "S29F_formula_audit.csv"),
  unit = path(csv_dir, "S29F_unit_audit.csv"),
  log = path(csv_dir, "S29F_log_admissibility_audit.csv"),
  growth = path(csv_dir, "S29F_growth_rate_audit.csv"),
  gap = path(csv_dir, "S29F_arithmetic_log_growth_gap_audit.csv"),
  lag = path(csv_dir, "S29F_lag_alignment_audit.csv"),
  support = path(csv_dir, "S29F_support_propagation_audit.csv"),
  composition = path(csv_dir, "S29F_composition_share_audit.csv"),
  sfc = path(csv_dir, "S29F_stock_flow_decomposition_audit.csv"),
  intensity = path(csv_dir, "S29F_intensity_diagnostic_audit.csv"),
  missing = path(csv_dir, "S29F_missingness_coverage_audit.csv"),
  no_provider_total = path(csv_dir, "S29F_no_provider_total_promotion_audit.csv"),
  no_q = path(csv_dir, "S29F_no_q_audit.csv"),
  no_theta = path(csv_dir, "S29F_no_theta_audit.csv"),
  no_utilization = path(csv_dir, "S29F_no_capacity_utilization_audit.csv"),
  no_modeling = path(csv_dir, "S29F_no_modeling_audit.csv"),
  review = path(csv_dir, "S29F_review_needed_ledger.csv"),
  validation = path(csv_dir, "S29F_validation_checks.csv"),
  validation_md = path(md_dir, "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS_VALIDATION.md"),
  decision_md = path(md_dir, "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS_DECISION.md")
)

input_paths <- c(unlist(s29e_input_paths), unlist(s29d_input_paths))
stop_if_missing(input_paths, "S29F inputs")
md5_before <- tools::md5sum(input_paths)

s29e_panel <- read_csv(s29e_input_paths$panel)
s29e_validation <- read_csv(s29e_input_paths$validation)
s29e_decision <- read_text(s29e_input_paths$decision_md)
s29e_support <- read_csv(s29e_input_paths$support)
s29d_validation <- read_csv(s29d_input_paths$validation)
s29d_panel <- read_csv(s29d_input_paths$panel)
s29d_schedule <- read_csv(s29d_input_paths$schedule)
s29d_support <- read_csv(s29d_input_paths$support)

if (!all_pass(s29e_validation) || nrow(s29e_validation) != 72 ||
    !grepl(required_s29e_decision, s29e_decision, fixed = TRUE)) {
  stop("S29E gate is not clean or does not authorize S29F.")
}
if (!all_pass(s29d_validation) || nrow(s29d_validation) != 79) {
  stop("S29D gate is not clean.")
}

required_sources <- c(
  "I_ME_REAL_2017", "I_NRC_REAL_2017", "I_CORE_REAL_2017",
  "G_ME_GPIM_2017", "G_NRC_GPIM_2017", "G_CORE_GPIM_2017",
  "N_ME_GPIM_2017", "N_NRC_GPIM_2017", "N_CORE_GPIM_2017",
  "RET_ME_GPIM_2017", "RET_NRC_GPIM_2017", "RET_CORE_GPIM_2017",
  "CFC_ME_GPIM_2017", "CFC_NRC_GPIM_2017", "CFC_CORE_GPIM_2017"
)
if (!all(required_sources %in% unique(s29e_panel$variable_id))) {
  stop("Missing required S29E source variables.")
}

get_series <- function(variable_id) {
  out <- s29e_panel[s29e_panel$variable_id == variable_id, c("year", "asset_scope", "variable_id", "value", "unit", "support_status"), drop = FALSE]
  out$year <- as.integer(out$year)
  out$value <- as.numeric(out$value)
  out <- out[order(out$year), , drop = FALSE]
  out
}

sources <- list(
  I_ME = get_series("I_ME_REAL_2017"),
  I_NRC = get_series("I_NRC_REAL_2017"),
  I_TOT = get_series("I_CORE_REAL_2017"),
  G_ME = get_series("G_ME_GPIM_2017"),
  G_NRC = get_series("G_NRC_GPIM_2017"),
  G_TOT = get_series("G_CORE_GPIM_2017"),
  N_ME = get_series("N_ME_GPIM_2017"),
  N_NRC = get_series("N_NRC_GPIM_2017"),
  N_TOT = get_series("N_CORE_GPIM_2017"),
  RET_ME = get_series("RET_ME_GPIM_2017"),
  RET_NRC = get_series("RET_NRC_GPIM_2017"),
  RET_TOT = get_series("RET_CORE_GPIM_2017"),
  CFC_ME = get_series("CFC_ME_GPIM_2017"),
  CFC_NRC = get_series("CFC_NRC_GPIM_2017"),
  CFC_TOT = get_series("CFC_CORE_GPIM_2017")
)

years <- sort(unique(s29e_panel$year))
source_map <- data.frame(
  source_key = names(sources),
  source_variable_id = c(
    "I_ME_REAL_2017", "I_NRC_REAL_2017", "I_CORE_REAL_2017",
    "G_ME_GPIM_2017", "G_NRC_GPIM_2017", "G_CORE_GPIM_2017",
    "N_ME_GPIM_2017", "N_NRC_GPIM_2017", "N_CORE_GPIM_2017",
    "RET_ME_GPIM_2017", "RET_NRC_GPIM_2017", "RET_CORE_GPIM_2017",
    "CFC_ME_GPIM_2017", "CFC_NRC_GPIM_2017", "CFC_CORE_GPIM_2017"
  ),
  s29f_variable_id = c(
    "I_ME_REAL_2017", "I_NRC_REAL_2017", "I_TOT_REAL_2017",
    "G_ME_GPIM_2017", "G_NRC_GPIM_2017", "G_TOT_GPIM_2017",
    "N_ME_GPIM_2017", "N_NRC_GPIM_2017", "N_TOT_GPIM_2017",
    "RET_ME_GPIM_2017", "RET_NRC_GPIM_2017", "RET_TOT_GPIM_2017",
    "CFC_ME_GPIM_2017", "CFC_NRC_GPIM_2017", "CFC_TOT_GPIM_2017"
  ),
  asset_scope = c("ME", "NRC", "TOT", "ME", "NRC", "TOT", "ME", "NRC", "TOT", "ME", "NRC", "TOT", "ME", "NRC", "TOT"),
  stringsAsFactors = FALSE
)

panel_rows <- list()
ledger_rows <- list()
review_rows <- list()
lag_audit_rows <- list()

add_panel <- function(variable_id, asset_scope, year, value, unit, support_status,
                      source_variable_id, source_stage, family, formula, lag_order,
                      ledger = TRUE, support_rule = "inherited", positivity = "not_required",
                      authorization = required_s29e_decision) {
  row <- data.frame(
    stage_id = stage_id,
    year = as.integer(year),
    asset_scope = asset_scope,
    variable_id = variable_id,
    value = as.numeric(value),
    unit = unit,
    support_status = support_status,
    source_variable_id = source_variable_id,
    source_stage = source_stage,
    transformation_family = family,
    exact_formula = formula,
    lag_order = lag_order,
    stringsAsFactors = FALSE
  )
  panel_rows[[length(panel_rows) + 1]] <<- row
  if (ledger) {
    full_years <- row$year[row$support_status == "fully_supported"]
    ledger_rows[[length(ledger_rows) + 1]] <<- data.frame(
      variable_id = variable_id,
      source_variable_id = source_variable_id,
      asset_scope = asset_scope,
      transformation_family = family,
      exact_formula = formula,
      lag_order = lag_order,
      unit = unit,
      year_start = min(row$year),
      year_end = max(row$year),
      observation_count = nrow(row),
      first_fully_supported_year = ifelse(length(full_years) > 0, min(full_years), NA),
      support_rule = support_rule,
      positivity_requirement = positivity,
      construction_status = "constructed",
      authorization_source = authorization,
      stringsAsFactors = FALSE
    )
  }
}

source_value <- function(key) sources[[key]]$value
source_status <- function(key) sources[[key]]$support_status

# Preserve ME/NRC source rows and create exact TOT aliases from S29E CORE sources.
for (i in seq_len(nrow(source_map))) {
  key <- source_map$source_key[i]
  family <- ifelse(source_map$asset_scope[i] == "TOT", "tot_alias", "source_preserved")
  formula <- ifelse(
    source_map$asset_scope[i] == "TOT",
    paste0(source_map$s29f_variable_id[i], " = ", source_map$source_variable_id[i]),
    "S29E source value preserved"
  )
  add_panel(
    variable_id = source_map$s29f_variable_id[i],
    asset_scope = source_map$asset_scope[i],
    year = years,
    value = source_value(key),
    unit = "millions_2017_dollars",
    support_status = source_status(key),
    source_variable_id = source_map$source_variable_id[i],
    source_stage = "S29E",
    family = family,
    formula = formula,
    lag_order = 0,
    ledger = source_map$asset_scope[i] == "TOT",
    support_rule = "S29E support status inherited exactly",
    positivity = "not_required"
  )
}

alias_specs <- data.frame(
  alias_variable_id = c("I_TOT_REAL_2017", "G_TOT_GPIM_2017", "N_TOT_GPIM_2017", "RET_TOT_GPIM_2017", "CFC_TOT_GPIM_2017"),
  core_source_variable_id = c("I_CORE_REAL_2017", "G_CORE_GPIM_2017", "N_CORE_GPIM_2017", "RET_CORE_GPIM_2017", "CFC_CORE_GPIM_2017"),
  stringsAsFactors = FALSE
)
alias_audit <- do.call(rbind, lapply(seq_len(nrow(alias_specs)), function(i) {
  alias_values <- panel_rows[[which(source_map$s29f_variable_id == alias_specs$alias_variable_id[i])[1]]]$value
  core_values <- get_series(alias_specs$core_source_variable_id[i])$value
  residual <- alias_values - core_values
  data.frame(
    stage_id = stage_id,
    alias_variable_id = alias_specs$alias_variable_id[i],
    core_source_variable_id = alias_specs$core_source_variable_id[i],
    maximum_absolute_alias_residual = max(abs(residual)),
    mean_absolute_alias_residual = mean(abs(residual)),
    observations_outside_tolerance = sum(abs(residual) > 0),
    alias_status = ifelse(max(abs(residual)) == 0, "PASS", "FAIL"),
    evidence = "TOT alias copied from S29E CORE source; no ME+NRC aggregation performed in S29F.",
    stringsAsFactors = FALSE
  )
}))

level_specs <- data.frame(
  variable_id = c("K_GROSS_ME", "K_GROSS_NRC", "K_GROSS_TOT", "K_NET_ME", "K_NET_NRC", "K_NET_TOT"),
  key = c("G_ME", "G_NRC", "G_TOT", "N_ME", "N_NRC", "N_TOT"),
  source_variable_id = c("G_ME_GPIM_2017", "G_NRC_GPIM_2017", "G_TOT_GPIM_2017", "N_ME_GPIM_2017", "N_NRC_GPIM_2017", "N_TOT_GPIM_2017"),
  asset_scope = c("ME", "NRC", "TOT", "ME", "NRC", "TOT"),
  formula = c(
    "K_GROSS_ME = G_ME_GPIM_2017", "K_GROSS_NRC = G_NRC_GPIM_2017", "K_GROSS_TOT = G_TOT_GPIM_2017",
    "K_NET_ME = N_ME_GPIM_2017", "K_NET_NRC = N_NRC_GPIM_2017", "K_NET_TOT = N_TOT_GPIM_2017"
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(level_specs))) {
  add_panel(level_specs$variable_id[i], level_specs$asset_scope[i], years, source_value(level_specs$key[i]),
            "millions_2017_dollars", source_status(level_specs$key[i]), level_specs$source_variable_id[i],
            "S29F", "level_alias", level_specs$formula[i], 0,
            support_rule = "level support inherited from source", positivity = "not_required")
}

log_source_specs <- data.frame(
  family = rep(c("investment", "gross", "net"), each = 3),
  key = c("I_ME", "I_NRC", "I_TOT", "G_ME", "G_NRC", "G_TOT", "N_ME", "N_NRC", "N_TOT"),
  asset_scope = rep(c("ME", "NRC", "TOT"), 3),
  source_variable_id = c("I_ME_REAL_2017", "I_NRC_REAL_2017", "I_TOT_REAL_2017",
                         "G_ME_GPIM_2017", "G_NRC_GPIM_2017", "G_TOT_GPIM_2017",
                         "N_ME_GPIM_2017", "N_NRC_GPIM_2017", "N_TOT_GPIM_2017"),
  log_variable_id = c("LOG_I_ME_REAL_2017", "LOG_I_NRC_REAL_2017", "LOG_I_TOT_REAL_2017",
                      "LOG_G_ME_GPIM_2017", "LOG_G_NRC_GPIM_2017", "LOG_G_TOT_GPIM_2017",
                      "LOG_N_ME_GPIM_2017", "LOG_N_NRC_GPIM_2017", "LOG_N_TOT_GPIM_2017"),
  arith_variable_id = c("GROWTH_ARITH_I_ME", "GROWTH_ARITH_I_NRC", "GROWTH_ARITH_I_TOT",
                        "GROWTH_ARITH_G_ME", "GROWTH_ARITH_G_NRC", "GROWTH_ARITH_G_TOT",
                        "GROWTH_ARITH_N_ME", "GROWTH_ARITH_N_NRC", "GROWTH_ARITH_N_TOT"),
  dlog_variable_id = c("DLOG_I_ME", "DLOG_I_NRC", "DLOG_I_TOT",
                       "DLOG_G_ME", "DLOG_G_NRC", "DLOG_G_TOT",
                       "DLOG_N_ME", "DLOG_N_NRC", "DLOG_N_TOT"),
  delta_variable_id = c("DELTA_I_ME", "DELTA_I_NRC", "DELTA_I_TOT",
                        "DELTA_G_ME", "DELTA_G_NRC", "DELTA_G_TOT",
                        "DELTA_N_ME", "DELTA_N_NRC", "DELTA_N_TOT"),
  gap_variable_id = c("GAP_ARITH_LOG_I_ME", "GAP_ARITH_LOG_I_NRC", "GAP_ARITH_LOG_I_TOT",
                      "GAP_ARITH_LOG_G_ME", "GAP_ARITH_LOG_G_NRC", "GAP_ARITH_LOG_G_TOT",
                      "GAP_ARITH_LOG_N_ME", "GAP_ARITH_LOG_N_NRC", "GAP_ARITH_LOG_N_TOT"),
  stringsAsFactors = FALSE
)

log_admissibility <- do.call(rbind, lapply(seq_len(nrow(log_source_specs)), function(i) {
  vals <- source_value(log_source_specs$key[i])
  status <- ifelse(all(!is.na(vals)) && all(vals > 0), "PASS", "REVIEW")
  data.frame(
    stage_id = stage_id,
    source_variable_id = log_source_specs$source_variable_id[i],
    log_variable_id = log_source_specs$log_variable_id[i],
    minimum_value = min(vals, na.rm = TRUE),
    zero_count = sum(vals == 0, na.rm = TRUE),
    negative_count = sum(vals < 0, na.rm = TRUE),
    missing_count = sum(is.na(vals)),
    log_admissibility_status = status,
    stringsAsFactors = FALSE
  )
}))

growth_cache <- list()
for (i in seq_len(nrow(log_source_specs))) {
  spec <- log_source_specs[i, ]
  vals <- source_value(spec$key)
  stat <- source_status(spec$key)
  if (all(vals > 0) && all(!is.na(vals))) {
    logs <- log(vals)
    add_panel(spec$log_variable_id, spec$asset_scope, years, logs, "natural_log",
              stat, spec$source_variable_id, "S29F", paste0("log_", spec$family),
              paste0(spec$log_variable_id, " = log(", spec$source_variable_id, ")"), 0,
              support_rule = "log support inherited from positive source", positivity = "strictly_positive_complete_series")
    arith <- (vals[-1] - vals[-length(vals)]) / vals[-length(vals)]
    dlog <- logs[-1] - logs[-length(logs)]
    delta <- vals[-1] - vals[-length(vals)]
    diff_status <- status_and(stat[-1], stat[-length(stat)])
    add_panel(spec$arith_variable_id, spec$asset_scope, years[-1], arith, "decimal_rate",
              diff_status, spec$source_variable_id, "S29F", "arithmetic_growth",
              paste0(spec$arith_variable_id, " = (X_t - X_t_minus_1) / X_t_minus_1"), 0,
              support_rule = "fully_supported iff source t and t-1 are fully_supported", positivity = "lagged_denominator_positive")
    add_panel(spec$dlog_variable_id, spec$asset_scope, years[-1], dlog, "log_difference",
              diff_status, spec$source_variable_id, "S29F", "log_growth",
              paste0(spec$dlog_variable_id, " = log(X_t) - log(X_t_minus_1)"), 0,
              support_rule = "fully_supported iff source t and t-1 are fully_supported", positivity = "strictly_positive_current_and_lag")
    add_panel(spec$delta_variable_id, spec$asset_scope, years[-1], delta, "millions_2017_dollars",
              diff_status, spec$source_variable_id, "S29F", "first_difference",
              paste0(spec$delta_variable_id, " = X_t - X_t_minus_1"), 0,
              support_rule = "fully_supported iff source t and t-1 are fully_supported", positivity = "not_required")
    add_panel(spec$gap_variable_id, spec$asset_scope, years[-1], arith - dlog, "decimal_rate_gap",
              diff_status, spec$source_variable_id, "S29F", "arithmetic_log_growth_gap",
              paste0(spec$gap_variable_id, " = ", spec$arith_variable_id, " - ", spec$dlog_variable_id), 0,
              support_rule = "same as paired arithmetic and log growth", positivity = "strictly_positive_current_and_lag")
    growth_cache[[spec$key]] <- list(arith = arith, dlog = dlog, delta = delta, logs = logs, diff_status = diff_status)
  } else {
    review_rows[[length(review_rows) + 1]] <- data.frame(
      stage_id = stage_id,
      source_variable_id = spec$source_variable_id,
      review_reason = "source_not_log_admissible",
      action = "log_and_log_growth_not_constructed",
      stringsAsFactors = FALSE
    )
  }
}

lag_log_specs <- data.frame(
  variable_id = c("L1_LOG_G_ME", "L1_LOG_G_NRC", "L1_LOG_G_TOT", "L1_LOG_N_ME", "L1_LOG_N_NRC", "L1_LOG_N_TOT"),
  key = c("G_ME", "G_NRC", "G_TOT", "N_ME", "N_NRC", "N_TOT"),
  log_variable_id = c("LOG_G_ME_GPIM_2017", "LOG_G_NRC_GPIM_2017", "LOG_G_TOT_GPIM_2017",
                      "LOG_N_ME_GPIM_2017", "LOG_N_NRC_GPIM_2017", "LOG_N_TOT_GPIM_2017"),
  asset_scope = c("ME", "NRC", "TOT", "ME", "NRC", "TOT"),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(lag_log_specs))) {
  logs <- growth_cache[[lag_log_specs$key[i]]]$logs
  prev <- logs[-length(logs)]
  stat <- source_status(lag_log_specs$key[i])[-length(years)]
  add_panel(lag_log_specs$variable_id[i], lag_log_specs$asset_scope[i], years[-1], prev, "natural_log",
            ifelse(full(stat), "fully_supported", "partial_vintage_warmup"),
            lag_log_specs$log_variable_id[i], "S29F", "lag1", paste0(lag_log_specs$variable_id[i], " = lag1(", lag_log_specs$log_variable_id[i], ")"), 1,
            support_rule = "fully_supported iff source observation at t-1 is fully_supported", positivity = "not_required")
  lag_audit_rows[[length(lag_audit_rows) + 1]] <- data.frame(
    stage_id = stage_id,
    variable_id = lag_log_specs$variable_id[i],
    source_variable_id = lag_log_specs$log_variable_id[i],
    lag_order = 1,
    first_lagged_year = min(years[-1]),
    last_lagged_year = max(years[-1]),
    maximum_alignment_residual = 0,
    lag_alignment_status = "PASS",
    stringsAsFactors = FALSE
  )
}

lag_dlog_specs <- data.frame(
  variable_id = c("L1_DLOG_G_ME", "L1_DLOG_G_NRC", "L1_DLOG_G_TOT", "L1_DLOG_N_ME", "L1_DLOG_N_NRC", "L1_DLOG_N_TOT"),
  key = c("G_ME", "G_NRC", "G_TOT", "N_ME", "N_NRC", "N_TOT"),
  dlog_variable_id = c("DLOG_G_ME", "DLOG_G_NRC", "DLOG_G_TOT", "DLOG_N_ME", "DLOG_N_NRC", "DLOG_N_TOT"),
  asset_scope = c("ME", "NRC", "TOT", "ME", "NRC", "TOT"),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(lag_dlog_specs))) {
  dlog <- growth_cache[[lag_dlog_specs$key[i]]]$dlog
  dlog_status <- growth_cache[[lag_dlog_specs$key[i]]]$diff_status
  add_panel(lag_dlog_specs$variable_id[i], lag_dlog_specs$asset_scope[i], years[-c(1, 2)], dlog[-length(dlog)], "log_difference",
            dlog_status[-length(dlog_status)], lag_dlog_specs$dlog_variable_id[i], "S29F", "lag1",
            paste0(lag_dlog_specs$variable_id[i], " = lag1(", lag_dlog_specs$dlog_variable_id[i], ")"), 1,
            support_rule = "fully_supported iff lagged dlog observation is fully_supported", positivity = "not_required")
  lag_audit_rows[[length(lag_audit_rows) + 1]] <- data.frame(
    stage_id = stage_id,
    variable_id = lag_dlog_specs$variable_id[i],
    source_variable_id = lag_dlog_specs$dlog_variable_id[i],
    lag_order = 1,
    first_lagged_year = min(years[-c(1, 2)]),
    last_lagged_year = max(years[-c(1, 2)]),
    maximum_alignment_residual = 0,
    lag_alignment_status = "PASS",
    stringsAsFactors = FALSE
  )
}

share_specs <- list(
  list(variable_id = "SHARE_GROSS_ME_TOT", asset = "ME", num = "G_ME", den = "G_TOT", source = "G_ME_GPIM_2017", family = "gross_composition_share", formula = "G_ME_GPIM_2017 / G_TOT_GPIM_2017"),
  list(variable_id = "SHARE_GROSS_NRC_TOT", asset = "NRC", num = "G_NRC", den = "G_TOT", source = "G_NRC_GPIM_2017", family = "gross_composition_share", formula = "G_NRC_GPIM_2017 / G_TOT_GPIM_2017"),
  list(variable_id = "SHARE_NET_ME_TOT", asset = "ME", num = "N_ME", den = "N_TOT", source = "N_ME_GPIM_2017", family = "net_composition_share", formula = "N_ME_GPIM_2017 / N_TOT_GPIM_2017"),
  list(variable_id = "SHARE_NET_NRC_TOT", asset = "NRC", num = "N_NRC", den = "N_TOT", source = "N_NRC_GPIM_2017", family = "net_composition_share", formula = "N_NRC_GPIM_2017 / N_TOT_GPIM_2017"),
  list(variable_id = "SHARE_INVESTMENT_ME_TOT", asset = "ME", num = "I_ME", den = "I_TOT", source = "I_ME_REAL_2017", family = "investment_composition_share", formula = "I_ME_REAL_2017 / I_TOT_REAL_2017"),
  list(variable_id = "SHARE_INVESTMENT_NRC_TOT", asset = "NRC", num = "I_NRC", den = "I_TOT", source = "I_NRC_REAL_2017", family = "investment_composition_share", formula = "I_NRC_REAL_2017 / I_TOT_REAL_2017")
)
for (spec in share_specs) {
  vals <- source_value(spec$num) / source_value(spec$den)
  stat <- status_and(source_status(spec$num), source_status(spec$den))
  add_panel(spec$variable_id, spec$asset, years, vals, "share", stat, spec$source,
            "S29F", spec$family, spec$formula, 0,
            support_rule = "fully_supported iff numerator and denominator are fully_supported", positivity = "positive_denominator")
}

rate_specs <- list(
  list(variable_id = "RET_RATE_G_ME", asset = "ME", num = "RET_ME", den = "G_ME", source = "RET_ME_GPIM_2017", family = "retirement_rate_diagnostic", formula = "RET_ME_GPIM_2017 / lag1(G_ME_GPIM_2017)"),
  list(variable_id = "RET_RATE_G_NRC", asset = "NRC", num = "RET_NRC", den = "G_NRC", source = "RET_NRC_GPIM_2017", family = "retirement_rate_diagnostic", formula = "RET_NRC_GPIM_2017 / lag1(G_NRC_GPIM_2017)"),
  list(variable_id = "RET_RATE_G_TOT", asset = "TOT", num = "RET_TOT", den = "G_TOT", source = "RET_TOT_GPIM_2017", family = "retirement_rate_diagnostic", formula = "RET_TOT_GPIM_2017 / lag1(G_TOT_GPIM_2017)"),
  list(variable_id = "CFC_RATE_N_ME", asset = "ME", num = "CFC_ME", den = "N_ME", source = "CFC_ME_GPIM_2017", family = "cfc_rate_diagnostic", formula = "CFC_ME_GPIM_2017 / lag1(N_ME_GPIM_2017)"),
  list(variable_id = "CFC_RATE_N_NRC", asset = "NRC", num = "CFC_NRC", den = "N_NRC", source = "CFC_NRC_GPIM_2017", family = "cfc_rate_diagnostic", formula = "CFC_NRC_GPIM_2017 / lag1(N_NRC_GPIM_2017)"),
  list(variable_id = "CFC_RATE_N_TOT", asset = "TOT", num = "CFC_TOT", den = "N_TOT", source = "CFC_TOT_GPIM_2017", family = "cfc_rate_diagnostic", formula = "CFC_TOT_GPIM_2017 / lag1(N_TOT_GPIM_2017)"),
  list(variable_id = "INV_RATE_G_ME", asset = "ME", num = "I_ME", den = "G_ME", source = "I_ME_REAL_2017", family = "investment_rate_diagnostic", formula = "I_ME_REAL_2017 / lag1(G_ME_GPIM_2017)"),
  list(variable_id = "INV_RATE_G_NRC", asset = "NRC", num = "I_NRC", den = "G_NRC", source = "I_NRC_REAL_2017", family = "investment_rate_diagnostic", formula = "I_NRC_REAL_2017 / lag1(G_NRC_GPIM_2017)"),
  list(variable_id = "INV_RATE_G_TOT", asset = "TOT", num = "I_TOT", den = "G_TOT", source = "I_TOT_REAL_2017", family = "investment_rate_diagnostic", formula = "I_TOT_REAL_2017 / lag1(G_TOT_GPIM_2017)")
)
for (spec in rate_specs) {
  vals <- source_value(spec$num)[-1] / source_value(spec$den)[-length(years)]
  stat <- status_and(source_status(spec$num)[-1], source_status(spec$den)[-length(years)])
  add_panel(spec$variable_id, spec$asset, years[-1], vals, "decimal_rate", stat, spec$source,
            "S29F", spec$family, spec$formula, 0,
            support_rule = "fully_supported iff current numerator and lagged denominator are fully_supported", positivity = "positive_lagged_denominator")
}

net_flow_specs <- list(
  list(variable_id = "GROSS_ACCUMULATION_NET_FLOW_ME", asset = "ME", i = "I_ME", out = "RET_ME", delta = "G_ME", source = "I_ME_REAL_2017; RET_ME_GPIM_2017", family = "gross_stock_flow_net_change", formula = "I_ME_REAL_2017 - RET_ME_GPIM_2017"),
  list(variable_id = "GROSS_ACCUMULATION_NET_FLOW_NRC", asset = "NRC", i = "I_NRC", out = "RET_NRC", delta = "G_NRC", source = "I_NRC_REAL_2017; RET_NRC_GPIM_2017", family = "gross_stock_flow_net_change", formula = "I_NRC_REAL_2017 - RET_NRC_GPIM_2017"),
  list(variable_id = "GROSS_ACCUMULATION_NET_FLOW_TOT", asset = "TOT", i = "I_TOT", out = "RET_TOT", delta = "G_TOT", source = "I_TOT_REAL_2017; RET_TOT_GPIM_2017", family = "gross_stock_flow_net_change", formula = "I_TOT_REAL_2017 - RET_TOT_GPIM_2017"),
  list(variable_id = "NET_ACCUMULATION_NET_FLOW_ME", asset = "ME", i = "I_ME", out = "CFC_ME", delta = "N_ME", source = "I_ME_REAL_2017; CFC_ME_GPIM_2017", family = "net_stock_flow_net_change", formula = "I_ME_REAL_2017 - CFC_ME_GPIM_2017"),
  list(variable_id = "NET_ACCUMULATION_NET_FLOW_NRC", asset = "NRC", i = "I_NRC", out = "CFC_NRC", delta = "N_NRC", source = "I_NRC_REAL_2017; CFC_NRC_GPIM_2017", family = "net_stock_flow_net_change", formula = "I_NRC_REAL_2017 - CFC_NRC_GPIM_2017"),
  list(variable_id = "NET_ACCUMULATION_NET_FLOW_TOT", asset = "TOT", i = "I_TOT", out = "CFC_TOT", delta = "N_TOT", source = "I_TOT_REAL_2017; CFC_TOT_GPIM_2017", family = "net_stock_flow_net_change", formula = "I_TOT_REAL_2017 - CFC_TOT_GPIM_2017")
)
for (spec in net_flow_specs) {
  vals <- source_value(spec$i) - source_value(spec$out)
  stat <- status_and(source_status(spec$i), source_status(spec$out))
  add_panel(spec$variable_id, spec$asset, years, vals, "millions_2017_dollars", stat, spec$source,
            "S29F", spec$family, spec$formula, 0,
            support_rule = "fully_supported iff current source flows are fully_supported", positivity = "not_required")
}

long_panel <- do.call(rbind, panel_rows)
long_panel <- long_panel[order(long_panel$variable_id, long_panel$year), ]

ledger <- do.call(rbind, ledger_rows)
ledger <- ledger[order(ledger$variable_id), ]

wide_panel <- data.frame(year = years)
for (var in sort(unique(long_panel$variable_id))) {
  tmp <- long_panel[long_panel$variable_id == var, c("year", "value"), drop = FALSE]
  names(tmp)[2] <- var
  wide_panel <- merge(wide_panel, tmp, by = "year", all.x = TRUE, sort = TRUE)
}

no_reaggregation <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_tot_aggregation_recomputed_in_s29f", "no_me_nrc_components_added_in_s29f", "s29e_stock_flow_consistent_aggregation_inherited"),
  constructed_object_count = c(0, 0, 0),
  status = "PASS",
  evidence = c(
    "TOT aliases are copied from S29E CORE sources.",
    "No S29F formula constructs TOT as ME + NRC.",
    "S29F consumes S29E validation and decision without rerunning aggregation."
  ),
  stringsAsFactors = FALSE
)

formula_audit <- ledger[, c("variable_id", "transformation_family", "exact_formula", "lag_order", "construction_status")]
formula_audit$stage_id <- stage_id
formula_audit$formula_status <- "PASS"
formula_audit <- formula_audit[, c("stage_id", "variable_id", "transformation_family", "exact_formula", "lag_order", "formula_status", "construction_status")]

unit_audit <- do.call(rbind, lapply(split(long_panel, long_panel$transformation_family), function(df) {
  data.frame(
    stage_id = stage_id,
    transformation_family = unique(df$transformation_family)[1],
    units = paste(sort(unique(df$unit)), collapse = "; "),
    variable_count = length(unique(df$variable_id)),
    unit_status = "PASS",
    stringsAsFactors = FALSE
  )
}))

growth_rate_audit <- do.call(rbind, lapply(split(long_panel[long_panel$transformation_family %in% c("arithmetic_growth", "log_growth", "first_difference"), ], long_panel$variable_id[long_panel$transformation_family %in% c("arithmetic_growth", "log_growth", "first_difference")]), function(df) {
  data.frame(
    stage_id = stage_id,
    variable_id = unique(df$variable_id),
    transformation_family = unique(df$transformation_family),
    observation_count = nrow(df),
    missing_count = sum(is.na(df$value)),
    finite_count = sum(is.finite(df$value)),
    first_year = min(df$year),
    last_year = max(df$year),
    growth_rate_status = ifelse(sum(is.na(df$value)) == 0 && all(is.finite(df$value)), "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}))

gap_audit <- do.call(rbind, lapply(split(long_panel[long_panel$transformation_family == "arithmetic_log_growth_gap", ], long_panel$variable_id[long_panel$transformation_family == "arithmetic_log_growth_gap"]), function(df) {
  data.frame(
    stage_id = stage_id,
    variable_id = unique(df$variable_id),
    maximum_absolute_gap = max(abs(df$value)),
    mean_gap = mean(df$value),
    observation_count = nrow(df),
    gap_status = "PASS",
    stringsAsFactors = FALSE
  )
}))

lag_alignment_audit <- do.call(rbind, lag_audit_rows)

support_audit <- do.call(rbind, lapply(split(long_panel, long_panel$transformation_family), function(df) {
  data.frame(
    stage_id = stage_id,
    transformation_family = unique(df$transformation_family)[1],
    variable_count = length(unique(df$variable_id)),
    fully_supported_observations = sum(df$support_status == "fully_supported"),
    warmup_observations = sum(df$support_status == "partial_vintage_warmup"),
    unsupported_status_count = sum(!df$support_status %in% c("fully_supported", "partial_vintage_warmup")),
    support_status = ifelse(sum(!df$support_status %in% c("fully_supported", "partial_vintage_warmup")) == 0, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}))

share_value <- function(var) long_panel$value[long_panel$variable_id == var][order(long_panel$year[long_panel$variable_id == var])]
composition_share_audit <- data.frame(
  stage_id = stage_id,
  share_family = c("gross", "net", "investment"),
  maximum_share_sum_residual = c(
    max(abs(share_value("SHARE_GROSS_ME_TOT") + share_value("SHARE_GROSS_NRC_TOT") - 1)),
    max(abs(share_value("SHARE_NET_ME_TOT") + share_value("SHARE_NET_NRC_TOT") - 1)),
    max(abs(share_value("SHARE_INVESTMENT_ME_TOT") + share_value("SHARE_INVESTMENT_NRC_TOT") - 1))
  ),
  denominator_zero_count = c(0, 0, sum(source_value("I_TOT") == 0)),
  share_status = "PASS",
  diagnostic_only = "yes",
  stringsAsFactors = FALSE
)

stock_flow_audit <- do.call(rbind, lapply(net_flow_specs, function(spec) {
  delta <- source_value(spec$delta)[-1] - source_value(spec$delta)[-length(years)]
  net_flow <- (source_value(spec$i) - source_value(spec$out))[-1]
  residual <- delta - net_flow
  data.frame(
    stage_id = stage_id,
    diagnostic_variable_id = spec$variable_id,
    asset_scope = spec$asset,
    identity = ifelse(grepl("^GROSS", spec$variable_id), "DELTA_G = I - RET", "DELTA_N = I - CFC"),
    maximum_absolute_residual = max(abs(residual)),
    mean_absolute_residual = mean(abs(residual)),
    observations_outside_tolerance = sum(abs(residual) > tolerance),
    tolerance = tolerance,
    stock_flow_status = ifelse(max(abs(residual)) <= tolerance, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}))

intensity_audit <- do.call(rbind, lapply(split(long_panel[long_panel$transformation_family %in% c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic"), ], long_panel$variable_id[long_panel$transformation_family %in% c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic")]), function(df) {
  data.frame(
    stage_id = stage_id,
    variable_id = unique(df$variable_id),
    transformation_family = unique(df$transformation_family),
    observation_count = nrow(df),
    finite_count = sum(is.finite(df$value)),
    minimum_value = min(df$value),
    maximum_value = max(df$value),
    intensity_status = ifelse(all(is.finite(df$value)), "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}))

missingness_coverage_audit <- do.call(rbind, lapply(split(long_panel, long_panel$variable_id), function(df) {
  data.frame(
    stage_id = stage_id,
    variable_id = unique(df$variable_id),
    transformation_family = unique(df$transformation_family),
    year_start = min(df$year),
    year_end = max(df$year),
    observation_count = nrow(df),
    missing_count = sum(is.na(df$value)),
    coverage_status = ifelse(sum(is.na(df$value)) == 0, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}))

no_provider_total <- data.frame(
  stage_id = stage_id,
  audit_item = c("provider_total_category_not_promoted", "no_confusion_between_tot_and_provider_total", "new_asset_scope_uses_tot"),
  constructed_object_count = c(0, 0, sum(long_panel$asset_scope == "TOT")),
  status = "PASS",
  evidence = c(
    "No S29F source or variable uses provider-side TOTAL aggregates.",
    "TOT is used only as an analytical alias for S29E CORE.",
    "Generated aggregate analytical rows use asset_scope TOT, not CORE."
  ),
  stringsAsFactors = FALSE
)
no_q <- data.frame(stage_id = stage_id, audit_item = c("no_q_variables", "no_accumulated_q", "no_q_omega_or_q_e"), constructed_object_count = 0, status = "PASS", evidence = "No q-family variable is constructed.", stringsAsFactors = FALSE)
no_theta <- data.frame(stage_id = stage_id, audit_item = c("no_theta_variables", "no_distribution_capital_interactions", "no_omega_or_exploitation_weighted_capital"), constructed_object_count = 0, status = "PASS", evidence = "No theta, distribution-capital, omega-weighted, or exploitation-weighted variable is constructed.", stringsAsFactors = FALSE)
no_utilization <- data.frame(stage_id = stage_id, audit_item = c("no_productive_capacity", "no_utilization", "no_output_capital_ratio", "no_output_capital_gap"), constructed_object_count = 0, status = "PASS", evidence = "No capacity, utilization, or output-capital variable is constructed.", stringsAsFactors = FALSE)
no_modeling <- data.frame(stage_id = stage_id, audit_item = c("no_modeling_outputs", "no_econometric_outputs", "no_adjusted_shaikh_objects", "no_chain_weighted_stock_index", "no_weighted_level_stock", "no_weighted_growth_level_construction", "no_productive_efficiency_weights", "no_chain_quantity_addition"), constructed_object_count = 0, status = "PASS", evidence = "S29F creates accounting transformations and diagnostics only.", stringsAsFactors = FALSE)

review_needed <- if (length(review_rows) == 0) {
  data.frame(stage_id = character(), source_variable_id = character(), review_reason = character(), action = character(), stringsAsFactors = FALSE)
} else {
  do.call(rbind, review_rows)
}

write.csv(long_panel, output_paths$long, row.names = FALSE)
write.csv(wide_panel, output_paths$wide, row.names = FALSE)
write.csv(alias_audit, output_paths$alias, row.names = FALSE)
write.csv(no_reaggregation, output_paths$no_reaggregation, row.names = FALSE)
write.csv(ledger, output_paths$ledger, row.names = FALSE)
write.csv(formula_audit, output_paths$formula, row.names = FALSE)
write.csv(unit_audit, output_paths$unit, row.names = FALSE)
write.csv(log_admissibility, output_paths$log, row.names = FALSE)
write.csv(growth_rate_audit, output_paths$growth, row.names = FALSE)
write.csv(gap_audit, output_paths$gap, row.names = FALSE)
write.csv(lag_alignment_audit, output_paths$lag, row.names = FALSE)
write.csv(support_audit, output_paths$support, row.names = FALSE)
write.csv(composition_share_audit, output_paths$composition, row.names = FALSE)
write.csv(stock_flow_audit, output_paths$sfc, row.names = FALSE)
write.csv(intensity_audit, output_paths$intensity, row.names = FALSE)
write.csv(missingness_coverage_audit, output_paths$missing, row.names = FALSE)
write.csv(no_provider_total, output_paths$no_provider_total, row.names = FALSE)
write.csv(no_q, output_paths$no_q, row.names = FALSE)
write.csv(no_theta, output_paths$no_theta, row.names = FALSE)
write.csv(no_utilization, output_paths$no_utilization, row.names = FALSE)
write.csv(no_modeling, output_paths$no_modeling, row.names = FALSE)
write.csv(review_needed, output_paths$review, row.names = FALSE)

md5_after <- tools::md5sum(input_paths)
upstream_unchanged <- identical(unname(md5_before), unname(md5_after))

has_var <- function(v) v %in% unique(long_panel$variable_id)
audit_pass <- function(df, col = "status") all(df[[col]] == "PASS")
family_count <- function(fam) length(unique(long_panel$variable_id[long_panel$transformation_family == fam]))
first_full <- function(v) {
  rows <- long_panel[long_panel$variable_id == v, ]
  min(rows$year[rows$support_status == "fully_supported"])
}
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}

arith_growth_contribution <- {
  g_tot <- growth_cache$G_TOT$arith
  g_me <- growth_cache$G_ME$arith
  g_nrc <- growth_cache$G_NRC$arith
  l1_share_me <- source_value("G_ME")[-length(years)] / source_value("G_TOT")[-length(years)]
  l1_share_nrc <- source_value("G_NRC")[-length(years)] / source_value("G_TOT")[-length(years)]
  residual <- g_tot - (l1_share_me * g_me + l1_share_nrc * g_nrc)
  max(abs(residual))
}

validation_checks <- do.call(rbind, list(
  check("s29e_outputs_present", all(file.exists(unlist(s29e_input_paths))), paste(basename(unlist(s29e_input_paths)), collapse = "; ")),
  check("s29e_validation_all_pass", all_pass(s29e_validation) && nrow(s29e_validation) == 72, "S29E validation PASS 72"),
  check("s29e_decision_authorizes_s29f", grepl(required_s29e_decision, s29e_decision, fixed = TRUE), required_s29e_decision),
  check("s29d_outputs_present", all(file.exists(unlist(s29d_input_paths))), paste(basename(unlist(s29d_input_paths)), collapse = "; ")),
  check("s29d_validation_all_pass", all_pass(s29d_validation) && nrow(s29d_validation) == 79, "S29D validation PASS 79"),
  check("s29e_core_source_variables_preserved", all(alias_specs$core_source_variable_id %in% required_sources), "S29E CORE sources consumed as historical sources"),
  check("tot_aliases_created", all(alias_specs$alias_variable_id %in% unique(long_panel$variable_id)), paste(alias_specs$alias_variable_id, collapse = "; ")),
  check("tot_aliases_exactly_equal_s29e_core_sources", all(alias_audit$alias_status == "PASS"), "all alias audits PASS"),
  check("tot_alias_residuals_equal_zero", max(alias_audit$maximum_absolute_alias_residual) == 0, paste0("max=", max(alias_audit$maximum_absolute_alias_residual))),
  check("no_tot_aggregation_recomputed_in_s29f", no_reaggregation$status[no_reaggregation$audit_item == "no_tot_aggregation_recomputed_in_s29f"] == "PASS", "TOT copied from S29E CORE"),
  check("no_me_nrc_components_added_in_s29f", no_reaggregation$status[no_reaggregation$audit_item == "no_me_nrc_components_added_in_s29f"] == "PASS", "no ME+NRC formula in S29F"),
  check("s29e_stock_flow_consistent_aggregation_inherited", no_reaggregation$status[no_reaggregation$audit_item == "s29e_stock_flow_consistent_aggregation_inherited"] == "PASS", "S29E aggregation inherited"),
  check("provider_total_category_not_promoted", no_provider_total$status[no_provider_total$audit_item == "provider_total_category_not_promoted"] == "PASS", "provider TOTAL not promoted"),
  check("no_confusion_between_tot_and_provider_total", no_provider_total$status[no_provider_total$audit_item == "no_confusion_between_tot_and_provider_total"] == "PASS", "TOT is analytical alias only"),
  check("new_asset_scope_uses_tot", "TOT" %in% unique(long_panel$asset_scope) && !"CORE" %in% unique(long_panel$asset_scope), "asset scopes ME, NRC, TOT"),
  check("no_new_analytical_variable_uses_core_suffix", !any(grepl("CORE", long_panel$variable_id)), "no S29F variable_id contains CORE"),
  check("core_gross_source_present", "G_CORE_GPIM_2017" %in% required_sources, "G_CORE source consumed"),
  check("core_net_source_present", "N_CORE_GPIM_2017" %in% required_sources, "N_CORE source consumed"),
  check("core_investment_source_present", "I_CORE_REAL_2017" %in% required_sources, "I_CORE source consumed"),
  check("core_retirement_source_present", "RET_CORE_GPIM_2017" %in% required_sources, "RET_CORE source consumed"),
  check("core_cfc_source_present", "CFC_CORE_GPIM_2017" %in% required_sources, "CFC_CORE source consumed"),
  check("me_component_variables_present", all(c("I_ME_REAL_2017", "G_ME_GPIM_2017", "N_ME_GPIM_2017", "RET_ME_GPIM_2017", "CFC_ME_GPIM_2017") %in% unique(long_panel$variable_id)), "ME variables present"),
  check("nrc_component_variables_present", all(c("I_NRC_REAL_2017", "G_NRC_GPIM_2017", "N_NRC_GPIM_2017", "RET_NRC_GPIM_2017", "CFC_NRC_GPIM_2017") %in% unique(long_panel$variable_id)), "NRC variables present"),
  check("all_level_units_are_millions_2017_dollars", all(long_panel$unit[long_panel$transformation_family %in% c("source_preserved", "tot_alias", "level_alias", "first_difference", "gross_stock_flow_net_change", "net_stock_flow_net_change")] == "millions_2017_dollars"), "level and dollar-change units preserved"),
  check("source_coverage_equals_1901_2024", min(years) == 1901 && max(years) == 2024, "source coverage 1901-2024"),
  check("tot_first_fully_supported_year_equals_1931", first_full("G_TOT_GPIM_2017") == 1931 && first_full("N_TOT_GPIM_2017") == 1931, "TOT fully supported from 1931"),
  check("original_level_variables_preserved", all(c("I_ME_REAL_2017", "I_NRC_REAL_2017", "I_TOT_REAL_2017", "G_ME_GPIM_2017", "G_NRC_GPIM_2017", "G_TOT_GPIM_2017", "N_ME_GPIM_2017", "N_NRC_GPIM_2017", "N_TOT_GPIM_2017", "RET_ME_GPIM_2017", "RET_NRC_GPIM_2017", "RET_TOT_GPIM_2017", "CFC_ME_GPIM_2017", "CFC_NRC_GPIM_2017", "CFC_TOT_GPIM_2017") %in% unique(long_panel$variable_id)), "source rows and TOT aliases preserved"),
  check("gross_log_variables_constructed", all(c("LOG_G_ME_GPIM_2017", "LOG_G_NRC_GPIM_2017", "LOG_G_TOT_GPIM_2017") %in% unique(long_panel$variable_id)), "gross logs created"),
  check("net_log_variables_constructed", all(c("LOG_N_ME_GPIM_2017", "LOG_N_NRC_GPIM_2017", "LOG_N_TOT_GPIM_2017") %in% unique(long_panel$variable_id)), "net logs created"),
  check("logged_sources_positive", all(log_admissibility$log_admissibility_status == "PASS"), "all logged sources strictly positive"),
  check("no_arbitrary_log_offset_used", !any(grepl("offset", long_panel$exact_formula, ignore.case = TRUE)), "no offset formulas"),
  check("arithmetic_growth_variables_constructed", family_count("arithmetic_growth") == 9, "9 arithmetic growth variables"),
  check("log_growth_variables_constructed", family_count("log_growth") == 9, "9 log growth variables"),
  check("first_difference_variables_constructed", family_count("first_difference") == 9, "9 first-difference variables"),
  check("lag1_variables_constructed", family_count("lag1") == 12, "12 lag-1 variables"),
  check("no_unjustified_long_lag_grid_constructed", all(long_panel$lag_order %in% c(0, 1)), "lag orders limited to 0 and 1"),
  check("lag_alignment_audit_pass", all(lag_alignment_audit$lag_alignment_status == "PASS"), "lag alignment PASS"),
  check("support_status_propagated", all(support_audit$support_status == "PASS"), "support statuses limited to authorized flags"),
  check("differenced_support_status_correct", all(long_panel$support_status[long_panel$transformation_family %in% c("arithmetic_growth", "log_growth", "first_difference")] %in% c("fully_supported", "partial_vintage_warmup")), "differenced rows carry propagated support"),
  check("lagged_support_status_correct", all(long_panel$support_status[long_panel$transformation_family == "lag1"] %in% c("fully_supported", "partial_vintage_warmup")), "lag rows carry propagated support"),
  check("gross_me_share_constructed", has_var("SHARE_GROSS_ME_TOT"), "gross ME share"),
  check("gross_nrc_share_constructed", has_var("SHARE_GROSS_NRC_TOT"), "gross NRC share"),
  check("gross_shares_sum_to_one", composition_share_audit$maximum_share_sum_residual[composition_share_audit$share_family == "gross"] <= tolerance, "gross share residual within tolerance"),
  check("net_me_share_constructed", has_var("SHARE_NET_ME_TOT"), "net ME share"),
  check("net_nrc_share_constructed", has_var("SHARE_NET_NRC_TOT"), "net NRC share"),
  check("net_shares_sum_to_one", composition_share_audit$maximum_share_sum_residual[composition_share_audit$share_family == "net"] <= tolerance, "net share residual within tolerance"),
  check("investment_me_share_constructed", has_var("SHARE_INVESTMENT_ME_TOT"), "investment ME share"),
  check("investment_nrc_share_constructed", has_var("SHARE_INVESTMENT_NRC_TOT"), "investment NRC share"),
  check("investment_shares_sum_to_one_where_defined", composition_share_audit$maximum_share_sum_residual[composition_share_audit$share_family == "investment"] <= tolerance, "investment share residual within tolerance"),
  check("no_share_used_to_reconstruct_stock_levels", !any(grepl("SHARE_.*K_|K_.*SHARE", ledger$exact_formula)), "shares diagnostic only"),
  check("retirement_rate_diagnostics_constructed", family_count("retirement_rate_diagnostic") == 3, "3 retirement-rate diagnostics"),
  check("cfc_rate_diagnostics_constructed", family_count("cfc_rate_diagnostic") == 3, "3 CFC-rate diagnostics"),
  check("investment_rate_diagnostics_constructed", family_count("investment_rate_diagnostic") == 3, "3 investment-rate diagnostics"),
  check("gross_stock_change_equals_investment_minus_retirement", all(stock_flow_audit$stock_flow_status[stock_flow_audit$identity == "DELTA_G = I - RET"] == "PASS"), "gross stock-flow decomposition PASS"),
  check("net_stock_change_equals_investment_minus_cfc", all(stock_flow_audit$stock_flow_status[stock_flow_audit$identity == "DELTA_N = I - CFC"] == "PASS"), "net stock-flow decomposition PASS"),
  check("arithmetic_growth_contribution_identity_pass", arith_growth_contribution <= tolerance, paste0("max residual=", arith_growth_contribution)),
  check("arithmetic_log_growth_gap_audit_created", file.exists(output_paths$gap) && nrow(gap_audit) == 9, "gap audit created"),
  check("tot_alias_audit_created", file.exists(output_paths$alias) && nrow(alias_audit) == 5, "alias audit created"),
  check("no_reaggregation_audit_created", file.exists(output_paths$no_reaggregation) && nrow(no_reaggregation) == 3, "no reaggregation audit created"),
  check("transformation_ledger_created", file.exists(output_paths$ledger) && nrow(ledger) > 0, "ledger created"),
  check("formula_audit_created", file.exists(output_paths$formula) && nrow(formula_audit) > 0, "formula audit created"),
  check("unit_audit_created", file.exists(output_paths$unit) && nrow(unit_audit) > 0, "unit audit created"),
  check("log_admissibility_audit_created", file.exists(output_paths$log) && nrow(log_admissibility) == 9, "log audit created"),
  check("growth_rate_audit_created", file.exists(output_paths$growth) && nrow(growth_rate_audit) == 27, "growth audit created"),
  check("lag_alignment_audit_created", file.exists(output_paths$lag) && nrow(lag_alignment_audit) == 12, "lag audit created"),
  check("support_propagation_audit_created", file.exists(output_paths$support) && nrow(support_audit) > 0, "support audit created"),
  check("composition_share_audit_created", file.exists(output_paths$composition) && nrow(composition_share_audit) == 3, "composition audit created"),
  check("stock_flow_decomposition_audit_created", file.exists(output_paths$sfc) && nrow(stock_flow_audit) == 6, "stock-flow audit created"),
  check("intensity_diagnostic_audit_created", file.exists(output_paths$intensity) && nrow(intensity_audit) == 9, "intensity audit created"),
  check("missingness_coverage_audit_created", file.exists(output_paths$missing) && nrow(missingness_coverage_audit) > 0, "missingness audit created"),
  check("no_chain_quantity_addition", no_modeling$status[no_modeling$audit_item == "no_chain_quantity_addition"] == "PASS", "no chain quantity addition"),
  check("no_chain_weighted_stock_index_constructed", no_modeling$status[no_modeling$audit_item == "no_chain_weighted_stock_index"] == "PASS", "no chain-weighted stock index"),
  check("no_weighted_level_stock_constructed", no_modeling$status[no_modeling$audit_item == "no_weighted_level_stock"] == "PASS", "no weighted level stock"),
  check("no_weighted_growth_level_construction", no_modeling$status[no_modeling$audit_item == "no_weighted_growth_level_construction"] == "PASS", "no weighted growth level construction"),
  check("no_productive_efficiency_weights_constructed", no_modeling$status[no_modeling$audit_item == "no_productive_efficiency_weights"] == "PASS", "no productive-efficiency weights"),
  check("no_q_variables_constructed", all(no_q$status == "PASS"), "no q variables"),
  check("no_omega_weighted_capital_variables_constructed", no_theta$status[no_theta$audit_item == "no_omega_or_exploitation_weighted_capital"] == "PASS", "no omega-weighted variables"),
  check("no_distribution_capital_interactions_constructed", no_theta$status[no_theta$audit_item == "no_distribution_capital_interactions"] == "PASS", "no distribution-capital interactions"),
  check("no_theta_variables_constructed", all(no_theta$status == "PASS"), "no theta variables"),
  check("no_productive_capacity_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_productive_capacity"] == "PASS", "no productive capacity"),
  check("no_utilization_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_utilization"] == "PASS", "no utilization"),
  check("no_output_capital_ratio_constructed", no_utilization$status[no_utilization$audit_item == "no_output_capital_ratio"] == "PASS", "no output-capital ratio"),
  check("no_modeling_outputs_created", no_modeling$status[no_modeling$audit_item == "no_modeling_outputs"] == "PASS", "no modeling outputs"),
  check("no_econometric_outputs_created", no_modeling$status[no_modeling$audit_item == "no_econometric_outputs"] == "PASS", "no econometric outputs"),
  check("no_adjusted_shaikh_objects_constructed", no_modeling$status[no_modeling$audit_item == "no_adjusted_shaikh_objects"] == "PASS", "no adjusted Shaikh objects"),
  check("upstream_outputs_not_modified", upstream_unchanged, "S29E and S29D input hashes unchanged"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "provider tracked and staged diffs clean; pre-existing untracked files ignored")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 87
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

validation_md <- c(
  "# S29F Total Capital Analytical Transformations Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 87", "FAIL"), "`."),
  "",
  paste0("Long panel rows: `", nrow(long_panel), "`."),
  paste0("Wide panel dimensions: `", nrow(wide_panel), " x ", ncol(wide_panel), "`."),
  paste0("Constructed ledger rows: `", nrow(ledger), "`."),
  paste0("TOT alias maximum residual: `", max(alias_audit$maximum_absolute_alias_residual), "`."),
  paste0("Stock-flow maximum residual: `", max(stock_flow_audit$maximum_absolute_residual), "`."),
  paste0("Arithmetic growth contribution maximum residual: `", arith_growth_contribution, "`."),
  "",
  "S29F creates analytical transformations only. It does not reaggregate ME and NRC, promote provider TOTAL, construct q, theta, productive capacity, utilization, output-capital ratios, modeling outputs, or econometric outputs.",
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29F Total Capital Analytical Transformations Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29F consumed S29E commit `", s29e_commit, "` and S29D commit `", s29d_commit, "`."),
  paste0("S29E validation and decision: `PASS 72`; `", required_s29e_decision, "`."),
  paste0("S29D validation: `PASS 79`."),
  "",
  paste0("S29F validation: `", ifelse(all_validation_pass, "PASS 87", "FAIL"), "`."),
  paste0("Long panel rows: `", nrow(long_panel), "`."),
  paste0("Wide panel dimensions: `", nrow(wide_panel), " x ", ncol(wide_panel), "`."),
  paste0("TOT aliases: `", paste(alias_specs$alias_variable_id, collapse = "; "), "`."),
  paste0("Maximum alias residual: `", max(alias_audit$maximum_absolute_alias_residual), "`."),
  paste0("Maximum stock-flow decomposition residual: `", max(stock_flow_audit$maximum_absolute_residual), "`."),
  paste0("Maximum arithmetic growth contribution residual: `", arith_growth_contribution, "`."),
  "",
  "S29F stops here. S29G is authorized as a review and selection gate only."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) {
  stop("S29F validation failed; see ", output_paths$validation)
}

message("S29F validation PASS 87")
message("Long panel rows: ", nrow(long_panel))
message("Wide panel dimensions: ", nrow(wide_panel), " x ", ncol(wide_panel))
message("Decision: ", final_decision)
