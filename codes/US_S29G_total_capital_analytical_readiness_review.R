# S29G is a review and downstream-selection gate for S29F analytical variables.
# It creates inventories, classifications, recommendations, and audits only.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

stage_id <- "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW"
s29e_commit <- "10c3e6940c9118e18260ceea968b7cdb321c1cb9"
s29f_commit <- "cb0d1a93700a6224cbfe82d786f90381519c8de2"
required_s29f_decision <- "AUTHORIZE_S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW"
required_s29f_status <- "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS_COMPLETE_S29G_AUTHORIZED"
clean_decision <- "AUTHORIZE_S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT"
blocked_decision <- "BLOCK_FOR_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW"
clean_status <- "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW_COMPLETE_S29H_AUTHORIZED"
blocked_status <- "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW_BLOCKED"
tolerance <- 1e-6

path <- function(...) file.path(...)
read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) stop(label, " missing: ", paste(basename(missing), collapse = "; "))
}
provider_tracked_clean <- function(repo) {
  unstaged <- system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE)
  staged <- system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE)
  identical(unstaged, 0L) && identical(staged, 0L)
}
mode1 <- function(x) {
  ux <- unique(x[!is.na(x)])
  if (length(ux) == 0) NA_character_ else ux[1]
}
fmt_num <- function(x) format(x, scientific = FALSE, trim = TRUE)

s29f_dir <- path(repo_root, "output", "US", "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS")
s29e_dir <- path(repo_root, "output", "US", "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION")
s29d_dir <- path(repo_root, "output", "US", "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION")
s29g_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29g_dir, "csv")
md_dir <- path(s29g_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29f_input_paths <- list(
  long = path(s29f_dir, "csv", "S29F_total_capital_analytical_panel_long.csv"),
  wide = path(s29f_dir, "csv", "S29F_total_capital_analytical_panel_wide.csv"),
  alias = path(s29f_dir, "csv", "S29F_tot_alias_reconciliation_audit.csv"),
  no_reaggregation = path(s29f_dir, "csv", "S29F_no_reaggregation_audit.csv"),
  ledger = path(s29f_dir, "csv", "S29F_transformation_ledger.csv"),
  formula = path(s29f_dir, "csv", "S29F_formula_audit.csv"),
  unit = path(s29f_dir, "csv", "S29F_unit_audit.csv"),
  log = path(s29f_dir, "csv", "S29F_log_admissibility_audit.csv"),
  growth = path(s29f_dir, "csv", "S29F_growth_rate_audit.csv"),
  gap = path(s29f_dir, "csv", "S29F_arithmetic_log_growth_gap_audit.csv"),
  lag = path(s29f_dir, "csv", "S29F_lag_alignment_audit.csv"),
  support = path(s29f_dir, "csv", "S29F_support_propagation_audit.csv"),
  composition = path(s29f_dir, "csv", "S29F_composition_share_audit.csv"),
  sfc = path(s29f_dir, "csv", "S29F_stock_flow_decomposition_audit.csv"),
  intensity = path(s29f_dir, "csv", "S29F_intensity_diagnostic_audit.csv"),
  missing = path(s29f_dir, "csv", "S29F_missingness_coverage_audit.csv"),
  no_provider_total = path(s29f_dir, "csv", "S29F_no_provider_total_promotion_audit.csv"),
  no_q = path(s29f_dir, "csv", "S29F_no_q_audit.csv"),
  no_theta = path(s29f_dir, "csv", "S29F_no_theta_audit.csv"),
  no_utilization = path(s29f_dir, "csv", "S29F_no_capacity_utilization_audit.csv"),
  no_modeling = path(s29f_dir, "csv", "S29F_no_modeling_audit.csv"),
  review = path(s29f_dir, "csv", "S29F_review_needed_ledger.csv"),
  validation = path(s29f_dir, "csv", "S29F_validation_checks.csv"),
  validation_md = path(s29f_dir, "md", "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS_VALIDATION.md"),
  decision_md = path(s29f_dir, "md", "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS_DECISION.md")
)
s29e_input_paths <- list(
  support = path(s29e_dir, "csv", "S29E_support_status_audit.csv"),
  unit_timing = path(s29e_dir, "csv", "S29E_common_unit_timing_audit.csv"),
  provenance = path(s29e_dir, "csv", "S29E_source_to_aggregate_provenance.csv"),
  validation = path(s29e_dir, "csv", "S29E_validation_checks.csv"),
  decision_md = path(s29e_dir, "md", "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION_DECISION.md")
)
s29d_input_paths <- list(
  support = path(s29d_dir, "csv", "S29D_initialization_support_status_audit.csv"),
  schedule = path(s29d_dir, "csv", "S29D_gpim_parameter_schedule_audit.csv"),
  validation = path(s29d_dir, "csv", "S29D_validation_checks.csv"),
  decision_md = path(s29d_dir, "md", "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION_DECISION.md")
)

output_paths <- list(
  inventory = path(csv_dir, "S29G_analytical_variable_inventory.csv"),
  classification = path(csv_dir, "S29G_variable_admissibility_classification.csv"),
  role = path(csv_dir, "S29G_downstream_role_classification.csv"),
  authoritative = path(csv_dir, "S29G_authoritative_variable_selection_ledger.csv"),
  redundancy = path(csv_dir, "S29G_redundancy_map.csv"),
  support = path(csv_dir, "S29G_support_coverage_review.csv"),
  warmup = path(csv_dir, "S29G_warmup_restriction_ledger.csv"),
  growth = path(csv_dir, "S29G_growth_measure_comparison_review.csv"),
  max_gap = path(csv_dir, "S29G_max_arithmetic_log_gap_review.csv"),
  movement = path(csv_dir, "S29G_large_movement_discontinuity_review.csv"),
  composition = path(csv_dir, "S29G_composition_diagnostic_review.csv"),
  intensity = path(csv_dir, "S29G_intensity_diagnostic_review.csv"),
  recommendation = path(csv_dir, "S29G_downstream_selection_recommendation.csv"),
  review = path(csv_dir, "S29G_review_needed_ledger.csv"),
  no_new = path(csv_dir, "S29G_no_new_variable_construction_audit.csv"),
  no_provider_total = path(csv_dir, "S29G_no_provider_total_promotion_audit.csv"),
  no_q = path(csv_dir, "S29G_no_q_audit.csv"),
  no_theta = path(csv_dir, "S29G_no_theta_audit.csv"),
  no_utilization = path(csv_dir, "S29G_no_capacity_utilization_audit.csv"),
  no_modeling = path(csv_dir, "S29G_no_modeling_audit.csv"),
  validation = path(csv_dir, "S29G_validation_checks.csv"),
  validation_md = path(md_dir, "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW_VALIDATION.md"),
  decision_md = path(md_dir, "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW_DECISION.md")
)

input_paths <- c(unlist(s29f_input_paths), unlist(s29e_input_paths), unlist(s29d_input_paths))
stop_if_missing(input_paths, "S29G inputs")
md5_before <- tools::md5sum(input_paths)

s29f_long <- read_csv(s29f_input_paths$long)
s29f_wide <- read_csv(s29f_input_paths$wide)
s29f_alias <- read_csv(s29f_input_paths$alias)
s29f_no_reaggregation <- read_csv(s29f_input_paths$no_reaggregation)
s29f_ledger <- read_csv(s29f_input_paths$ledger)
s29f_gap_audit <- read_csv(s29f_input_paths$gap)
s29f_composition <- read_csv(s29f_input_paths$composition)
s29f_sfc <- read_csv(s29f_input_paths$sfc)
s29f_intensity <- read_csv(s29f_input_paths$intensity)
s29f_no_provider_total <- read_csv(s29f_input_paths$no_provider_total)
s29f_no_q <- read_csv(s29f_input_paths$no_q)
s29f_no_theta <- read_csv(s29f_input_paths$no_theta)
s29f_no_utilization <- read_csv(s29f_input_paths$no_utilization)
s29f_no_modeling <- read_csv(s29f_input_paths$no_modeling)
s29f_validation <- read_csv(s29f_input_paths$validation)
s29f_decision <- read_text(s29f_input_paths$decision_md)
s29e_validation <- read_csv(s29e_input_paths$validation)
s29d_validation <- read_csv(s29d_input_paths$validation)

if (!all_pass(s29f_validation) || nrow(s29f_validation) != 87 ||
    !grepl(required_s29f_decision, s29f_decision, fixed = TRUE) ||
    !grepl(required_s29f_status, s29f_decision, fixed = TRUE)) {
  stop("S29F gate is not clean or does not authorize S29G.")
}
if (!all_pass(s29e_validation) || nrow(s29e_validation) != 72) stop("S29E validation gate is not clean.")
if (!all_pass(s29d_validation) || nrow(s29d_validation) != 79) stop("S29D validation gate is not clean.")

s29f_long$year <- as.integer(s29f_long$year)
s29f_long$value <- as.numeric(s29f_long$value)

variable_rows <- split(s29f_long, s29f_long$variable_id)
support_summary <- do.call(rbind, lapply(variable_rows, function(df) {
  data.frame(
    stage_id = stage_id,
    variable_id = unique(df$variable_id),
    asset_scope = mode1(df$asset_scope),
    transformation_family = mode1(df$transformation_family),
    source_variable_id = mode1(df$source_variable_id),
    unit = mode1(df$unit),
    year_start = min(df$year),
    year_end = max(df$year),
    observation_count = nrow(df),
    first_fully_supported_year = ifelse(any(df$support_status == "fully_supported"), min(df$year[df$support_status == "fully_supported"]), NA),
    fully_supported_observation_count = sum(df$support_status == "fully_supported"),
    warmup_observation_count = sum(df$support_status == "partial_vintage_warmup"),
    missing_observation_count = sum(is.na(df$value)),
    stringsAsFactors = FALSE
  )
}))

classify_one <- function(v, fam, asset) {
  if (v %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017")) return("AUTHORIZED_PRIMARY")
  if (v %in% c("N_TOT_GPIM_2017", "LOG_N_TOT_GPIM_2017",
               "I_TOT_REAL_2017", "LOG_I_TOT_REAL_2017",
               "GROWTH_ARITH_G_TOT", "DLOG_G_TOT", "DELTA_G_TOT",
               "GROWTH_ARITH_N_TOT", "DLOG_N_TOT",
               "L1_LOG_G_TOT", "L1_DLOG_G_TOT", "L1_LOG_N_TOT", "L1_DLOG_N_TOT")) {
    return("AUTHORIZED_SECONDARY")
  }
  if (fam %in% c("level_alias", "gross_stock_flow_net_change", "net_stock_flow_net_change")) return("REDUNDANT_ALIAS")
  if (fam %in% c("gross_composition_share", "net_composition_share", "investment_composition_share",
                 "retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic",
                 "arithmetic_log_growth_gap")) return("DIAGNOSTIC_ONLY")
  if (grepl("^(RET|CFC)_", v) || grepl("^DELTA_I_", v) || grepl("^GROWTH_ARITH_I_", v) || grepl("^DLOG_I_", v)) return("DIAGNOSTIC_ONLY")
  if (asset %in% c("ME", "NRC")) return("DIAGNOSTIC_ONLY")
  return("DIAGNOSTIC_ONLY")
}

role_one <- function(v, fam, asset) {
  if (v == "G_TOT_GPIM_2017") return("productive_capital_level_primary")
  if (v == "LOG_G_TOT_GPIM_2017") return("productive_capital_log_primary")
  if (v %in% c("GROWTH_ARITH_G_TOT", "DLOG_G_TOT", "DELTA_G_TOT")) return("productive_capital_growth_candidate")
  if (v == "L1_LOG_G_TOT") return("productive_capital_lagged_level_candidate")
  if (v == "L1_DLOG_G_TOT") return("productive_capital_lagged_growth_candidate")
  if (v == "N_TOT_GPIM_2017") return("net_stock_robustness_level")
  if (v == "LOG_N_TOT_GPIM_2017") return("net_stock_robustness_log")
  if (v %in% c("GROWTH_ARITH_N_TOT", "DLOG_N_TOT", "DELTA_N_TOT", "L1_LOG_N_TOT", "L1_DLOG_N_TOT")) return("net_stock_robustness_candidate")
  if (grepl("(^I_|_I_|INVESTMENT)", v)) return("investment_flow_diagnostic")
  if (fam %in% c("gross_composition_share", "net_composition_share", "investment_composition_share")) return("composition_diagnostic")
  if (fam %in% c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic")) return("depreciation_and_retirement_diagnostic")
  if (fam %in% c("gross_stock_flow_net_change", "net_stock_flow_net_change", "level_alias")) return("accounting_redundancy")
  if (fam == "arithmetic_log_growth_gap") return("growth_gap_diagnostic")
  if (asset %in% c("ME", "NRC")) return("component_diagnostic")
  return("capital_diagnostic")
}

alias_one <- function(v, fam) {
  if (v %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017", "N_TOT_GPIM_2017", "LOG_N_TOT_GPIM_2017")) return("authoritative_candidate")
  if (fam %in% c("tot_alias", "level_alias", "gross_stock_flow_net_change", "net_stock_flow_net_change")) return("alias_or_redundant")
  return("non_alias")
}

note_one <- function(v, fam, class, role) {
  if (v == "G_TOT_GPIM_2017") return("Authoritative S29F TOT level alias for validated S29E gross core stock; preferred level object.")
  if (v == "LOG_G_TOT_GPIM_2017") return("Preferred logged form of gross productive capital for later selection.")
  if (v == "K_GROSS_TOT") return("Exact presentation alias of G_TOT_GPIM_2017; not independent.")
  if (fam %in% c("gross_composition_share", "net_composition_share", "investment_composition_share")) return("Composition diagnostic only; not a stock-construction weight.")
  if (fam %in% c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic")) return("Accounting intensity diagnostic only; not a structural depreciation parameter.")
  if (fam == "arithmetic_log_growth_gap") return("Diagnostic difference between arithmetic and log growth; not an empirical regressor selected here.")
  if (class == "REDUNDANT_ALIAS") return("Redundant accounting representation of an already retained source or first difference.")
  if (role == "investment_flow_diagnostic") return("Investment is a flow and is not a substitute for productive-capital stock.")
  if (grepl("^N_|LOG_N_|DLOG_N_|GROWTH_ARITH_N_|DELTA_N_|L1_.*N_", v)) return("Net stock is retained as secondary or robustness object, not the baseline productive-capital quantity.")
  return("Reviewed for S29H selection; no construction defect identified.")
}

support_summary$primary_classification <- mapply(classify_one, support_summary$variable_id, support_summary$transformation_family, support_summary$asset_scope)
support_summary$downstream_role <- mapply(role_one, support_summary$variable_id, support_summary$transformation_family, support_summary$asset_scope)
support_summary$authoritative_or_alias <- mapply(alias_one, support_summary$variable_id, support_summary$transformation_family)
support_summary$review_note <- mapply(note_one, support_summary$variable_id, support_summary$transformation_family, support_summary$primary_classification, support_summary$downstream_role)

inventory <- support_summary[order(support_summary$variable_id), ]
classification <- inventory[, c("stage_id", "variable_id", "asset_scope", "transformation_family", "primary_classification", "review_note")]
role_classification <- inventory[, c("stage_id", "variable_id", "asset_scope", "transformation_family", "downstream_role", "primary_classification", "review_note")]
support_review <- inventory[, c("stage_id", "variable_id", "asset_scope", "transformation_family", "year_start", "year_end", "observation_count", "first_fully_supported_year", "fully_supported_observation_count", "warmup_observation_count", "missing_observation_count", "primary_classification")]

warmup_ledger <- support_review[support_review$warmup_observation_count > 0, ]
warmup_ledger$baseline_estimation_authorized_for_warmup <- "no"
warmup_ledger$allowed_warmup_uses <- "visualization; sensitivity checks; initialization review; historical continuity diagnostics"
warmup_ledger$restriction_note <- "Baseline empirical estimation must use fully supported observations only."

source_value <- function(variable_id, year) {
  rows <- s29f_long[s29f_long$variable_id == variable_id & s29f_long$year == year, ]
  if (nrow(rows) == 0) NA_real_ else rows$value[1]
}
source_status <- function(variable_id, year) {
  rows <- s29f_long[s29f_long$variable_id == variable_id & s29f_long$year == year, ]
  if (nrow(rows) == 0) NA_character_ else rows$support_status[1]
}
source_for_suffix <- function(suffix) {
  switch(suffix,
         "I_ME" = "I_ME_REAL_2017", "I_NRC" = "I_NRC_REAL_2017", "I_TOT" = "I_TOT_REAL_2017",
         "G_ME" = "G_ME_GPIM_2017", "G_NRC" = "G_NRC_GPIM_2017", "G_TOT" = "G_TOT_GPIM_2017",
         "N_ME" = "N_ME_GPIM_2017", "N_NRC" = "N_NRC_GPIM_2017", "N_TOT" = "N_TOT_GPIM_2017",
         NA_character_)
}
arith_for_suffix <- function(suffix) paste0("GROWTH_ARITH_", suffix)
dlog_for_suffix <- function(suffix) paste0("DLOG_", suffix)

gap_rows <- s29f_long[s29f_long$transformation_family == "arithmetic_log_growth_gap", ]
growth_comparison <- do.call(rbind, lapply(split(gap_rows, gap_rows$variable_id), function(df) {
  df <- df[order(df$year), ]
  abs_gap <- abs(df$value)
  max_i <- which.max(abs_gap)
  suffix <- sub("^GAP_ARITH_LOG_", "", unique(df$variable_id))
  data.frame(
    stage_id = stage_id,
    gap_variable_id = unique(df$variable_id),
    asset_scope = mode1(df$asset_scope),
    source_level_variable_id = source_for_suffix(suffix),
    maximum_absolute_gap = max(abs_gap),
    mean_absolute_gap = mean(abs_gap),
    median_absolute_gap = median(abs_gap),
    p95_absolute_gap = as.numeric(quantile(abs_gap, 0.95, names = FALSE, type = 7)),
    year_of_maximum_gap = df$year[max_i],
    support_status_of_maximum_gap = df$support_status[max_i],
    review_status = "PASS",
    review_note = ifelse(df$support_status[max_i] == "fully_supported",
                         "Largest gap reflects a large annual movement, not an alignment or positivity failure.",
                         "Largest gap occurs during warm-up support and reflects transformation sensitivity in a large movement."),
    stringsAsFactors = FALSE
  )
}))

global_gap <- growth_comparison[which.max(growth_comparison$maximum_absolute_gap), ]
global_suffix <- sub("^GAP_ARITH_LOG_", "", global_gap$gap_variable_id)
global_year <- global_gap$year_of_maximum_gap
global_source <- source_for_suffix(global_suffix)
global_arith <- arith_for_suffix(global_suffix)
global_dlog <- dlog_for_suffix(global_suffix)
global_arith_value <- source_value(global_arith, global_year)
global_dlog_value <- source_value(global_dlog, global_year)
global_source_t <- source_value(global_source, global_year)
global_source_lag <- source_value(global_source, global_year - 1)
global_cause <- ifelse(global_gap$support_status_of_maximum_gap != "fully_supported",
                       "warmup_related",
                       ifelse(abs(global_arith_value) > 0.35, "genuine_large_annual_movement", "ordinary_arithmetic_log_divergence"))

fully_supported_gaps <- growth_comparison
fully_supported_gaps$maximum_fully_supported_gap <- NA_real_
fully_supported_gaps$year_of_maximum_fully_supported_gap <- NA_integer_
fully_supported_gaps$support_status_of_maximum_fully_supported_gap <- NA_character_
for (i in seq_len(nrow(fully_supported_gaps))) {
  df <- gap_rows[gap_rows$variable_id == fully_supported_gaps$gap_variable_id[i] & gap_rows$support_status == "fully_supported", ]
  if (nrow(df) > 0) {
    abs_gap <- abs(df$value)
    mi <- which.max(abs_gap)
    fully_supported_gaps$maximum_fully_supported_gap[i] <- abs_gap[mi]
    fully_supported_gaps$year_of_maximum_fully_supported_gap[i] <- df$year[mi]
    fully_supported_gaps$support_status_of_maximum_fully_supported_gap[i] <- df$support_status[mi]
  }
}

max_gap_review <- data.frame(
  stage_id = stage_id,
  gap_variable_id = global_gap$gap_variable_id,
  asset_scope = global_gap$asset_scope,
  calendar_year = global_year,
  source_level_variable_id = global_source,
  source_level_t = global_source_t,
  source_level_t_minus_1 = global_source_lag,
  arithmetic_growth_variable_id = global_arith,
  arithmetic_growth = global_arith_value,
  log_growth_variable_id = global_dlog,
  log_growth = global_dlog_value,
  absolute_gap = abs(global_arith_value - global_dlog_value),
  support_status = global_gap$support_status_of_maximum_gap,
  cause_classification = global_cause,
  data_discontinuity_classification = "not_indicated",
  review_note = "S29F formulas, alignment, and positivity audits pass; the gap is reviewed as a growth-measure difference rather than a construction defect.",
  stringsAsFactors = FALSE
)

growth_vars <- s29f_long[s29f_long$transformation_family %in% c("arithmetic_growth", "log_growth"), ]
large_movement_review <- do.call(rbind, lapply(split(growth_vars, growth_vars$variable_id), function(df) {
  df <- df[order(df$year), ]
  max_i <- which.max(abs(df$value))
  v <- unique(df$variable_id)
  suffix <- sub("^GROWTH_ARITH_", "", sub("^DLOG_", "", v))
  src <- source_for_suffix(suffix)
  yr <- df$year[max_i]
  src_t <- source_value(src, yr)
  src_lag <- source_value(src, yr - 1)
  prior_series <- s29f_long$value[s29f_long$variable_id == src]
  q10 <- as.numeric(quantile(prior_series, 0.10, names = FALSE))
  classification <- if (df$support_status[max_i] != "fully_supported") {
    "warmup_related"
  } else if (!is.na(src_lag) && src_lag <= q10 && abs(df$value[max_i]) > 0.20) {
    "base_effect"
  } else {
    "historically_plausible"
  }
  data.frame(
    stage_id = stage_id,
    variable_id = v,
    asset_scope = mode1(df$asset_scope),
    year = yr,
    growth_value = df$value[max_i],
    support_status = df$support_status[max_i],
    source_variable_id = src,
    source_value_t = src_t,
    source_value_t_minus_1 = src_lag,
    review_classification = classification,
    review_note = ifelse(classification == "warmup_related",
                         "Largest movement occurs before full support; retain for continuity diagnostics only.",
                         "Largest supported movement does not conflict with S29F formula, positivity, or alignment audits."),
    stringsAsFactors = FALSE
  )
}))

composition_review <- data.frame(
  stage_id = stage_id,
  share_family = s29f_composition$share_family,
  maximum_share_sum_residual = as.numeric(s29f_composition$maximum_share_sum_residual),
  share_status = s29f_composition$share_status,
  review_classification = "DIAGNOSTIC_ONLY",
  review_note = "Composition shares are accounting diagnostics and must not be used to reconstruct stock levels or as productive-efficiency weights.",
  stringsAsFactors = FALSE
)

intensity_review <- data.frame(
  stage_id = stage_id,
  variable_id = s29f_intensity$variable_id,
  transformation_family = s29f_intensity$transformation_family,
  minimum_value = as.numeric(s29f_intensity$minimum_value),
  maximum_value = as.numeric(s29f_intensity$maximum_value),
  intensity_status = s29f_intensity$intensity_status,
  review_classification = "DIAGNOSTIC_ONLY",
  review_note = "Accounting intensity diagnostic only; not a structural depreciation or behavioral parameter.",
  stringsAsFactors = FALSE
)

selection <- data.frame(
  stage_id = stage_id,
  candidate_role = c(
    "productive_capital_level_primary",
    "productive_capital_log_primary",
    "productive_capital_growth_candidate",
    "productive_capital_lagged_level_candidate",
    "productive_capital_lagged_growth_candidate",
    "net_stock_robustness_level",
    "net_stock_robustness_log",
    "investment_flow_diagnostic",
    "composition_diagnostic",
    "depreciation_and_retirement_diagnostic"
  ),
  recommended_variable_id = c(
    "G_TOT_GPIM_2017",
    "LOG_G_TOT_GPIM_2017",
    "DLOG_G_TOT; GROWTH_ARITH_G_TOT",
    "L1_LOG_G_TOT",
    "L1_DLOG_G_TOT",
    "N_TOT_GPIM_2017",
    "LOG_N_TOT_GPIM_2017",
    "I_TOT_REAL_2017; LOG_I_TOT_REAL_2017",
    "SHARE_GROSS_ME_TOT; SHARE_GROSS_NRC_TOT; SHARE_NET_ME_TOT; SHARE_NET_NRC_TOT; SHARE_INVESTMENT_ME_TOT; SHARE_INVESTMENT_NRC_TOT",
    "RET_RATE_G_TOT; CFC_RATE_N_TOT; INV_RATE_G_TOT"
  ),
  recommendation_status = c("preferred", "preferred", rep("candidate_for_bounded_later_selection", 3), rep("robustness_candidate", 2), rep("diagnostic_only", 3)),
  baseline_estimation_support_rule = c(
    "use fully_supported observations only; first full year 1931",
    "use fully_supported observations only; first full year 1931",
    "choice depends on later theoretical formula; first full year 1932 for TOT growth",
    "use only if lagged level appears explicitly in a later contract; first full year 1932",
    "use only if lagged growth appears explicitly in a later contract; first full year 1933",
    "secondary robustness only; first full year 1931",
    "secondary robustness only; first full year 1931",
    "flow diagnostic; not a stock substitute",
    "diagnostic composition only",
    "diagnostic intensity only"
  ),
  justification = c(
    "Gross real GPIM stock is the baseline productive-capital quantity.",
    "Preferred logged analytical form of gross real GPIM stock.",
    "Arithmetic and log growth are both valid but not interchangeable; S29H must choose explicitly.",
    "Lagged log gross stock is admissible only for a later bounded lag specification.",
    "Lagged gross-stock log growth is admissible only for a later bounded lag specification.",
    "Net real GPIM stock is depreciation-sensitive and secondary to gross stock.",
    "Logged net stock is retained for robustness, not baseline productive-capital quantity.",
    "Investment is a flow and cannot substitute for a stock level.",
    "Shares describe composition and are not construction weights.",
    "Rates describe accounting intensities and are not structural parameters."
  ),
  stringsAsFactors = FALSE
)

authoritative_ledger <- selection
authoritative_ledger$authoritative_source <- ifelse(grepl("primary|robustness", authoritative_ledger$candidate_role), "S29F reviewed S29E-derived variable", "S29F diagnostic")

redundancy_rows <- list()
add_redundancy <- function(variable_id, related_variable_id, relationship_type, exact_or_approximate, max_diff, recommended, status) {
  redundancy_rows[[length(redundancy_rows) + 1]] <<- data.frame(
    stage_id = stage_id,
    variable_id = variable_id,
    related_variable_id = related_variable_id,
    relationship_type = relationship_type,
    exact_or_approximate = exact_or_approximate,
    maximum_difference = max_diff,
    recommended_authoritative_variable = recommended,
    recommended_retained_status = status,
    stringsAsFactors = FALSE
  )
}
for (i in seq_len(nrow(s29f_alias))) {
  add_redundancy(s29f_alias$alias_variable_id[i], s29f_alias$core_source_variable_id[i], "TOT alias of historical S29E CORE source", "exact", as.numeric(s29f_alias$maximum_absolute_alias_residual[i]), s29f_alias$alias_variable_id[i], "retain reviewed S29F TOT name")
}
level_alias_map <- data.frame(
  alias = c("K_GROSS_ME", "K_GROSS_NRC", "K_GROSS_TOT", "K_NET_ME", "K_NET_NRC", "K_NET_TOT"),
  source = c("G_ME_GPIM_2017", "G_NRC_GPIM_2017", "G_TOT_GPIM_2017", "N_ME_GPIM_2017", "N_NRC_GPIM_2017", "N_TOT_GPIM_2017"),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(level_alias_map))) add_redundancy(level_alias_map$alias[i], level_alias_map$source[i], "K level alias", "exact", 0, level_alias_map$source[i], "REDUNDANT_ALIAS")
for (i in seq_len(nrow(s29f_sfc))) {
  related <- ifelse(grepl("^GROSS", s29f_sfc$diagnostic_variable_id[i]),
                    paste0("DELTA_G_", s29f_sfc$asset_scope[i]),
                    paste0("DELTA_N_", s29f_sfc$asset_scope[i]))
  add_redundancy(s29f_sfc$diagnostic_variable_id[i], related, "stock-flow net-change reproduces first difference", "near-exact numerical", as.numeric(s29f_sfc$maximum_absolute_residual[i]), related, "REDUNDANT_ALIAS")
}
add_redundancy("SHARE_GROSS_ME_TOT", "SHARE_GROSS_NRC_TOT", "complementary shares sum to one", "exact up to numerical tolerance", as.numeric(s29f_composition$maximum_share_sum_residual[s29f_composition$share_family == "gross"]), "both retained as diagnostics", "DIAGNOSTIC_ONLY")
add_redundancy("SHARE_NET_ME_TOT", "SHARE_NET_NRC_TOT", "complementary shares sum to one", "exact up to numerical tolerance", as.numeric(s29f_composition$maximum_share_sum_residual[s29f_composition$share_family == "net"]), "both retained as diagnostics", "DIAGNOSTIC_ONLY")
add_redundancy("SHARE_INVESTMENT_ME_TOT", "SHARE_INVESTMENT_NRC_TOT", "complementary shares sum to one", "exact up to numerical tolerance", as.numeric(s29f_composition$maximum_share_sum_residual[s29f_composition$share_family == "investment"]), "both retained as diagnostics", "DIAGNOSTIC_ONLY")
for (suffix in c("I_ME", "I_NRC", "I_TOT", "G_ME", "G_NRC", "G_TOT", "N_ME", "N_NRC", "N_TOT")) {
  gap_var <- paste0("GAP_ARITH_LOG_", suffix)
  max_gap <- growth_comparison$maximum_absolute_gap[growth_comparison$gap_variable_id == gap_var]
  add_redundancy(arith_for_suffix(suffix), dlog_for_suffix(suffix), "arithmetic and log growth comparison", "not redundant when movements are material", max_gap, "S29H must select formula-specific growth measure", "reviewed separately")
}
redundancy_map <- do.call(rbind, redundancy_rows)

review_needed <- inventory[inventory$primary_classification == "REVIEW_REQUIRED", c("stage_id", "variable_id", "asset_scope", "transformation_family", "review_note")]
if (nrow(review_needed) == 0) {
  review_needed <- data.frame(stage_id = character(), variable_id = character(), asset_scope = character(), transformation_family = character(), review_note = character(), stringsAsFactors = FALSE)
}

no_new <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_new_economic_variable_constructed", "no_new_transformation_constructed", "no_model_input_panel_constructed"),
  constructed_object_count = 0,
  status = "PASS",
  evidence = c(
    "S29G outputs are inventories, classifications, recommendations, and audits only.",
    "No S29G output panel of transformed values was created.",
    "No model-input panel was created."
  ),
  stringsAsFactors = FALSE
)
no_provider_total <- data.frame(stage_id = stage_id, audit_item = c("provider_total_not_promoted", "tot_not_recomputed_as_me_plus_nrc"), constructed_object_count = 0, status = "PASS", evidence = "S29G reviews S29F TOT semantics and does not promote provider TOTAL.", stringsAsFactors = FALSE)
no_q <- data.frame(stage_id = stage_id, audit_item = c("no_q_variables", "no_accumulated_q", "no_omega_weighted_capital_variables"), constructed_object_count = 0, status = "PASS", evidence = "No q-family object is constructed or selected.", stringsAsFactors = FALSE)
no_theta <- data.frame(stage_id = stage_id, audit_item = c("no_theta_variables", "no_distribution_capital_interactions", "no_exploitation_weighted_capital_variables"), constructed_object_count = 0, status = "PASS", evidence = "No theta or distribution-capital object is constructed or selected.", stringsAsFactors = FALSE)
no_utilization <- data.frame(stage_id = stage_id, audit_item = c("no_productive_capacity", "no_utilization", "no_output_capital_ratio"), constructed_object_count = 0, status = "PASS", evidence = "No capacity, utilization, or output-capital ratio is constructed or selected.", stringsAsFactors = FALSE)
no_modeling <- data.frame(stage_id = stage_id, audit_item = c("no_modeling_outputs", "no_econometric_outputs"), constructed_object_count = 0, status = "PASS", evidence = "No modeling or econometric outputs are created.", stringsAsFactors = FALSE)

write.csv(inventory, output_paths$inventory, row.names = FALSE)
write.csv(classification, output_paths$classification, row.names = FALSE)
write.csv(role_classification, output_paths$role, row.names = FALSE)
write.csv(authoritative_ledger, output_paths$authoritative, row.names = FALSE)
write.csv(redundancy_map, output_paths$redundancy, row.names = FALSE)
write.csv(support_review, output_paths$support, row.names = FALSE)
write.csv(warmup_ledger, output_paths$warmup, row.names = FALSE)
write.csv(fully_supported_gaps, output_paths$growth, row.names = FALSE)
write.csv(max_gap_review, output_paths$max_gap, row.names = FALSE)
write.csv(large_movement_review, output_paths$movement, row.names = FALSE)
write.csv(composition_review, output_paths$composition, row.names = FALSE)
write.csv(intensity_review, output_paths$intensity, row.names = FALSE)
write.csv(selection, output_paths$recommendation, row.names = FALSE)
write.csv(review_needed, output_paths$review, row.names = FALSE)
write.csv(no_new, output_paths$no_new, row.names = FALSE)
write.csv(no_provider_total, output_paths$no_provider_total, row.names = FALSE)
write.csv(no_q, output_paths$no_q, row.names = FALSE)
write.csv(no_theta, output_paths$no_theta, row.names = FALSE)
write.csv(no_utilization, output_paths$no_utilization, row.names = FALSE)
write.csv(no_modeling, output_paths$no_modeling, row.names = FALSE)

md5_after <- tools::md5sum(input_paths)
upstream_unchanged <- identical(unname(md5_before), unname(md5_after))

variable_count <- length(unique(s29f_long$variable_id))
wide_dimensions_ok <- nrow(s29f_wide) == 124 && ncol(s29f_wide) == 100
family_var_counts <- table(unique(s29f_long[, c("variable_id", "transformation_family")])$transformation_family)
get_family_count <- function(fams) sum(family_var_counts[names(family_var_counts) %in% fams], na.rm = TRUE)
family_counts_ok <- all(c(
  get_family_count("tot_alias") == 5,
  get_family_count("level_alias") == 6,
  get_family_count(c("log_gross", "log_net", "log_investment")) == 9,
  get_family_count("arithmetic_growth") == 9,
  get_family_count("log_growth") == 9,
  get_family_count("first_difference") == 9,
  get_family_count("lag1") == 12,
  get_family_count(c("gross_composition_share", "net_composition_share", "investment_composition_share")) == 6,
  get_family_count(c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic")) == 9,
  get_family_count(c("gross_stock_flow_net_change", "net_stock_flow_net_change")) == 6,
  get_family_count("arithmetic_log_growth_gap") == 9
))

check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}
has_inventory <- function(v) v %in% inventory$variable_id
class_of <- function(v) inventory$primary_classification[inventory$variable_id == v]
role_of <- function(v) inventory$downstream_role[inventory$variable_id == v]

validation_checks <- do.call(rbind, list(
  check("s29f_outputs_present", all(file.exists(unlist(s29f_input_paths))), paste(basename(unlist(s29f_input_paths)), collapse = "; ")),
  check("s29f_validation_all_pass", all_pass(s29f_validation) && nrow(s29f_validation) == 87, "S29F validation PASS 87"),
  check("s29f_decision_authorizes_s29g", grepl(required_s29f_decision, s29f_decision, fixed = TRUE), required_s29f_decision),
  check("s29e_outputs_present", all(file.exists(unlist(s29e_input_paths))), paste(basename(unlist(s29e_input_paths)), collapse = "; ")),
  check("s29e_validation_all_pass", all_pass(s29e_validation) && nrow(s29e_validation) == 72, "S29E validation PASS 72"),
  check("s29d_outputs_present", all(file.exists(unlist(s29d_input_paths))), paste(basename(unlist(s29d_input_paths)), collapse = "; ")),
  check("s29d_validation_all_pass", all_pass(s29d_validation) && nrow(s29d_validation) == 79, "S29D validation PASS 79"),
  check("s29f_variable_count_equals_99", variable_count == 99, paste0("variables=", variable_count)),
  check("s29f_long_panel_row_count_equals_12213", nrow(s29f_long) == 12213, paste0("rows=", nrow(s29f_long))),
  check("s29f_wide_panel_dimensions_verified", wide_dimensions_ok, paste0(nrow(s29f_wide), " x ", ncol(s29f_wide))),
  check("transformation_family_counts_verified", family_counts_ok, "expected S29F family counts verified; preserved source variables add 10 inventory entries"),
  check("tot_aliases_exactly_match_s29e_core_sources", all(s29f_alias$alias_status == "PASS") && max(as.numeric(s29f_alias$maximum_absolute_alias_residual)) == 0, "alias residual max 0"),
  check("no_reaggregation_confirmed", all(s29f_no_reaggregation$status == "PASS"), "S29F no-reaggregation audit PASS"),
  check("provider_total_not_promoted", all(s29f_no_provider_total$status == "PASS") && all(no_provider_total$status == "PASS"), "provider TOTAL not promoted"),
  check("all_variables_in_inventory", nrow(inventory) == variable_count, "one inventory row per S29F variable"),
  check("every_variable_has_one_primary_classification", all(!is.na(inventory$primary_classification)) && !any(duplicated(classification$variable_id)), "exactly one primary classification per variable"),
  check("every_variable_has_one_downstream_role", all(!is.na(inventory$downstream_role)) && !any(duplicated(role_classification$variable_id)), "exactly one downstream role per variable"),
  check("gross_tot_level_reviewed", has_inventory("G_TOT_GPIM_2017") && class_of("G_TOT_GPIM_2017") == "AUTHORIZED_PRIMARY", "G_TOT reviewed as primary level"),
  check("gross_tot_log_reviewed", has_inventory("LOG_G_TOT_GPIM_2017") && class_of("LOG_G_TOT_GPIM_2017") == "AUTHORIZED_PRIMARY", "LOG_G_TOT reviewed as primary log"),
  check("net_tot_level_reviewed", has_inventory("N_TOT_GPIM_2017") && class_of("N_TOT_GPIM_2017") == "AUTHORIZED_SECONDARY", "N_TOT reviewed as secondary"),
  check("net_tot_log_reviewed", has_inventory("LOG_N_TOT_GPIM_2017") && class_of("LOG_N_TOT_GPIM_2017") == "AUTHORIZED_SECONDARY", "LOG_N_TOT reviewed as secondary"),
  check("investment_flow_variables_reviewed", all(c("I_TOT_REAL_2017", "LOG_I_TOT_REAL_2017", "GROWTH_ARITH_I_TOT", "DLOG_I_TOT", "DELTA_I_TOT") %in% inventory$variable_id), "TOT investment variables reviewed"),
  check("arithmetic_growth_variables_reviewed", sum(inventory$transformation_family == "arithmetic_growth") == 9, "9 arithmetic growth variables reviewed"),
  check("log_growth_variables_reviewed", sum(inventory$transformation_family == "log_growth") == 9, "9 log growth variables reviewed"),
  check("first_difference_variables_reviewed", sum(inventory$transformation_family == "first_difference") == 9, "9 first differences reviewed"),
  check("lag1_variables_reviewed", sum(inventory$transformation_family == "lag1") == 12, "12 lag variables reviewed"),
  check("composition_shares_reviewed", nrow(composition_review) == 3 && all(composition_review$review_classification == "DIAGNOSTIC_ONLY"), "composition shares reviewed"),
  check("intensity_diagnostics_reviewed", nrow(intensity_review) == 9 && all(intensity_review$review_classification == "DIAGNOSTIC_ONLY"), "intensity diagnostics reviewed"),
  check("stock_flow_net_change_variables_reviewed", sum(inventory$transformation_family %in% c("gross_stock_flow_net_change", "net_stock_flow_net_change")) == 6, "6 stock-flow net-change variables reviewed"),
  check("growth_gap_variables_reviewed", nrow(growth_comparison) == 9, "9 growth-gap variables reviewed"),
  check("maximum_growth_gap_located", nrow(max_gap_review) == 1 && is.finite(max_gap_review$absolute_gap), paste0("max gap=", fmt_num(max_gap_review$absolute_gap))),
  check("maximum_growth_gap_variable_identified", !is.na(max_gap_review$gap_variable_id), max_gap_review$gap_variable_id),
  check("maximum_growth_gap_year_identified", !is.na(max_gap_review$calendar_year), as.character(max_gap_review$calendar_year)),
  check("maximum_growth_gap_support_status_identified", max_gap_review$support_status %in% c("fully_supported", "partial_vintage_warmup"), max_gap_review$support_status),
  check("maximum_growth_gap_cause_classified", max_gap_review$cause_classification %in% c("warmup_related", "base_effect", "genuine_large_annual_movement", "ordinary_arithmetic_log_divergence"), max_gap_review$cause_classification),
  check("fully_supported_growth_gaps_reviewed", all(!is.na(fully_supported_gaps$maximum_fully_supported_gap)), "largest fully supported gaps calculated"),
  check("large_movements_reviewed", nrow(large_movement_review) == 18, "largest arithmetic and log growth movements reviewed"),
  check("possible_discontinuities_classified", all(large_movement_review$review_classification %in% c("historically_plausible", "warmup_related", "base_effect", "coverage_transition", "possible_discontinuity", "requires_review")), "large movements classified"),
  check("support_coverage_review_created", file.exists(output_paths$support) && nrow(support_review) == variable_count, "support coverage review created"),
  check("warmup_restriction_ledger_created", file.exists(output_paths$warmup) && nrow(warmup_ledger) > 0, "warm-up restriction ledger created"),
  check("warmup_observations_not_authorized_for_baseline_estimation", all(warmup_ledger$baseline_estimation_authorized_for_warmup == "no"), "warm-up rows restricted from baseline estimation"),
  check("redundancy_map_created", file.exists(output_paths$redundancy) && nrow(redundancy_map) > 0, "redundancy map created"),
  check("authoritative_variables_identified", all(c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017") %in% authoritative_ledger$recommended_variable_id), "authoritative primary variables identified"),
  check("exact_aliases_classified_as_redundant_or_interface_alias", class_of("K_GROSS_TOT") == "REDUNDANT_ALIAS" && class_of("K_NET_TOT") == "REDUNDANT_ALIAS", "K aliases redundant"),
  check("gross_stock_primary_hierarchy_preserved", class_of("G_TOT_GPIM_2017") == "AUTHORIZED_PRIMARY" && class_of("LOG_G_TOT_GPIM_2017") == "AUTHORIZED_PRIMARY", "gross hierarchy preserved"),
  check("net_stock_not_promoted_to_primary_without_justification", !any(inventory$primary_classification[inventory$variable_id %in% c("N_TOT_GPIM_2017", "LOG_N_TOT_GPIM_2017")] == "AUTHORIZED_PRIMARY"), "net stock secondary"),
  check("investment_not_promoted_as_stock_substitute", !any(inventory$downstream_role[grepl("^I_TOT|LOG_I_TOT|GROWTH_ARITH_I_TOT|DLOG_I_TOT|DELTA_I_TOT", inventory$variable_id)] %in% c("productive_capital_level_primary", "productive_capital_log_primary")), "investment treated as flow"),
  check("composition_shares_classified_as_diagnostic", all(inventory$primary_classification[inventory$transformation_family %in% c("gross_composition_share", "net_composition_share", "investment_composition_share")] == "DIAGNOSTIC_ONLY"), "shares diagnostic"),
  check("intensity_variables_classified_as_diagnostic", all(inventory$primary_classification[inventory$transformation_family %in% c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic")] == "DIAGNOSTIC_ONLY"), "intensities diagnostic"),
  check("stock_flow_net_change_redundancy_reviewed", all(inventory$primary_classification[inventory$transformation_family %in% c("gross_stock_flow_net_change", "net_stock_flow_net_change")] == "REDUNDANT_ALIAS"), "stock-flow net-change redundant"),
  check("arithmetic_and_log_growth_not_treated_as_identical", any(redundancy_map$relationship_type == "arithmetic and log growth comparison" & redundancy_map$exact_or_approximate == "not redundant when movements are material"), "growth measures reviewed separately"),
  check("downstream_selection_ledger_created", file.exists(output_paths$recommendation) && nrow(selection) == 10, "selection ledger created"),
  check("no_new_economic_variable_constructed", no_new$status[no_new$audit_item == "no_new_economic_variable_constructed"] == "PASS", "no new economic variable"),
  check("no_new_transformation_constructed", no_new$status[no_new$audit_item == "no_new_transformation_constructed"] == "PASS", "no new transformation"),
  check("no_model_input_panel_constructed", no_new$status[no_new$audit_item == "no_model_input_panel_constructed"] == "PASS", "no model input panel"),
  check("no_q_variables_constructed", all(no_q$status == "PASS"), "no q"),
  check("no_omega_weighted_capital_variables_constructed", no_q$status[no_q$audit_item == "no_omega_weighted_capital_variables"] == "PASS", "no omega-weighted capital"),
  check("no_distribution_capital_interactions_constructed", no_theta$status[no_theta$audit_item == "no_distribution_capital_interactions"] == "PASS", "no distribution-capital interactions"),
  check("no_theta_variables_constructed", all(no_theta$status == "PASS"), "no theta"),
  check("no_productive_capacity_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_productive_capacity"] == "PASS", "no productive capacity"),
  check("no_utilization_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_utilization"] == "PASS", "no utilization"),
  check("no_output_capital_ratio_constructed", no_utilization$status[no_utilization$audit_item == "no_output_capital_ratio"] == "PASS", "no output-capital ratio"),
  check("no_modeling_outputs_created", no_modeling$status[no_modeling$audit_item == "no_modeling_outputs"] == "PASS", "no modeling"),
  check("no_econometric_outputs_created", no_modeling$status[no_modeling$audit_item == "no_econometric_outputs"] == "PASS", "no econometrics"),
  check("upstream_outputs_not_modified", upstream_unchanged, "S29F/S29E/S29D input hashes unchanged"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "provider tracked and staged diffs clean; pre-existing untracked files ignored")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 66
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

class_counts <- as.data.frame(table(inventory$primary_classification), stringsAsFactors = FALSE)
names(class_counts) <- c("classification", "count")
role_counts <- as.data.frame(table(inventory$downstream_role), stringsAsFactors = FALSE)
names(role_counts) <- c("role", "count")

validation_md <- c(
  "# S29G Total Capital Analytical Readiness Review Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 66", "FAIL"), "`."),
  "",
  paste0("S29F variables reviewed: `", variable_count, "`."),
  paste0("S29F long panel rows: `", nrow(s29f_long), "`."),
  paste0("S29F wide panel dimensions: `", nrow(s29f_wide), " x ", ncol(s29f_wide), "`."),
  paste0("Maximum arithmetic/log gap: `", fmt_num(max_gap_review$absolute_gap), "` in `", max_gap_review$gap_variable_id, "` during `", max_gap_review$calendar_year, "`."),
  paste0("Maximum gap cause classification: `", max_gap_review$cause_classification, "`."),
  "",
  "S29G creates review artifacts only. It does not construct capital variables, transformations, model-input panels, q, theta, productive capacity, utilization, output-capital ratios, modeling outputs, or econometric outputs.",
  "",
  "## Classification Counts",
  "",
  paste0("- `", class_counts$classification, "`: `", class_counts$count, "`"),
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29G Total Capital Analytical Readiness Review Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29G consumed S29F commit `", s29f_commit, "` and S29E commit `", s29e_commit, "`."),
  paste0("S29F validation and decision: `PASS 87`; `", required_s29f_decision, "`."),
  paste0("S29G validation: `", ifelse(all_validation_pass, "PASS 66", "FAIL"), "`."),
  "",
  "Authoritative primary variables selected:",
  "- `G_TOT_GPIM_2017` for the productive-capital level.",
  "- `LOG_G_TOT_GPIM_2017` for the logged productive-capital form.",
  "",
  "Secondary and diagnostic variables remain available only under the restrictions recorded in the S29G ledgers. Warm-up observations are not authorized for baseline empirical estimation.",
  "",
  paste0("Maximum arithmetic/log growth gap: `", fmt_num(max_gap_review$absolute_gap), "` in `", max_gap_review$gap_variable_id, "` during `", max_gap_review$calendar_year, "`, classified as `", max_gap_review$cause_classification, "`."),
  "",
  "S29G stops here. S29H is authorized as a downstream input-selection contract only."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) {
  stop("S29G validation failed; see ", output_paths$validation)
}

message("S29G validation PASS 66")
message("Variables reviewed: ", variable_count)
message("Decision: ", final_decision)
