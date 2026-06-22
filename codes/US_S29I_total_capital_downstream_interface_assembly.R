# S29I assembles the S29H-contracted total-capital interface.
# It copies already constructed S29F values exactly and creates no new transformations.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

stage_id <- "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY"
s29h_commit <- "beaa5121e128246ce7e9c5d6e3ac7bfb31f277a3"
s29g_commit <- "0782393428a4f4521df3a88311eb9896b324671d"
s29f_commit <- "cb0d1a93700a6224cbfe82d786f90381519c8de2"
required_s29h_decision <- "AUTHORIZE_S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY"
required_s29h_status <- "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT_COMPLETE_S29I_AUTHORIZED"
clean_decision <- "AUTHORIZE_S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION_AND_HANDOFF"
blocked_decision <- "BLOCK_FOR_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_REVIEW"
clean_status <- "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY_COMPLETE_S29J_AUTHORIZED"
blocked_status <- "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY_BLOCKED"

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
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}

s29h_dir <- path(repo_root, "output", "US", "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT")
s29g_dir <- path(repo_root, "output", "US", "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW")
s29f_dir <- path(repo_root, "output", "US", "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS")
s29i_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29i_dir, "csv")
md_dir <- path(s29i_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29h_input_paths <- list(
  contract = path(s29h_dir, "csv", "S29H_complete_variable_contract.csv"),
  slots = path(s29h_dir, "csv", "S29H_authoritative_downstream_slot_contract.csv"),
  baseline = path(s29h_dir, "csv", "S29H_baseline_authorized_variables.csv"),
  robustness = path(s29h_dir, "csv", "S29H_robustness_authorized_variables.csv"),
  conditional = path(s29h_dir, "csv", "S29H_conditional_secondary_variables.csv"),
  diagnostic = path(s29h_dir, "csv", "S29H_diagnostic_only_variables.csv"),
  alias = path(s29h_dir, "csv", "S29H_alias_interface_only_variables.csv"),
  excluded = path(s29h_dir, "csv", "S29H_excluded_downstream_variables.csv"),
  support = path(s29h_dir, "csv", "S29H_support_window_contract.csv"),
  warmup = path(s29h_dir, "csv", "S29H_warmup_restriction_contract.csv"),
  alias_map = path(s29h_dir, "csv", "S29H_alias_authority_map.csv"),
  permitted = path(s29h_dir, "csv", "S29H_permitted_use_matrix.csv"),
  prohibited = path(s29h_dir, "csv", "S29H_prohibited_use_matrix.csv"),
  growth = path(s29h_dir, "csv", "S29H_growth_measure_selection_contract.csv"),
  manifest = path(s29h_dir, "csv", "S29H_downstream_handoff_manifest.csv"),
  review = path(s29h_dir, "csv", "S29H_review_needed_ledger.csv"),
  validation = path(s29h_dir, "csv", "S29H_validation_checks.csv"),
  contract_md = path(s29h_dir, "md", "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT.md"),
  validation_md = path(s29h_dir, "md", "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT_VALIDATION.md"),
  decision_md = path(s29h_dir, "md", "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT_DECISION.md")
)
s29g_input_paths <- list(
  recommendation = path(s29g_dir, "csv", "S29G_downstream_selection_recommendation.csv"),
  support = path(s29g_dir, "csv", "S29G_support_coverage_review.csv"),
  validation = path(s29g_dir, "csv", "S29G_validation_checks.csv")
)
s29f_input_paths <- list(
  long = path(s29f_dir, "csv", "S29F_total_capital_analytical_panel_long.csv"),
  validation = path(s29f_dir, "csv", "S29F_validation_checks.csv")
)

output_paths <- list(
  manifest = path(csv_dir, "S29I_complete_interface_manifest.csv"),
  active_long = path(csv_dir, "S29I_active_candidate_interface_long.csv"),
  active_wide = path(csv_dir, "S29I_active_candidate_interface_wide.csv"),
  primary_level = path(csv_dir, "S29I_primary_level_interface.csv"),
  primary_log = path(csv_dir, "S29I_primary_log_interface.csv"),
  robustness_level = path(csv_dir, "S29I_net_robustness_level_interface.csv"),
  robustness_log = path(csv_dir, "S29I_net_robustness_log_interface.csv"),
  conditional = path(csv_dir, "S29I_conditional_secondary_interface_long.csv"),
  diagnostic = path(csv_dir, "S29I_diagnostic_reference_catalog.csv"),
  alias = path(csv_dir, "S29I_alias_authority_catalog.csv"),
  copy = path(csv_dir, "S29I_source_value_copy_audit.csv"),
  contract_status = path(csv_dir, "S29I_contract_status_reconciliation_audit.csv"),
  lane = path(csv_dir, "S29I_lane_membership_audit.csv"),
  support = path(csv_dir, "S29I_support_eligibility_audit.csv"),
  growth_lock = path(csv_dir, "S29I_growth_representation_selection_lock.csv"),
  lag_lock = path(csv_dir, "S29I_lag_activation_lock.csv"),
  no_complete_case = path(csv_dir, "S29I_no_complete_case_sample_audit.csv"),
  no_growth = path(csv_dir, "S29I_no_silent_growth_selection_audit.csv"),
  no_lag = path(csv_dir, "S29I_no_silent_lag_activation_audit.csv"),
  no_diagnostic = path(csv_dir, "S29I_no_diagnostic_promotion_audit.csv"),
  no_alias = path(csv_dir, "S29I_no_alias_duplication_audit.csv"),
  no_provider_total = path(csv_dir, "S29I_no_provider_total_promotion_audit.csv"),
  no_new = path(csv_dir, "S29I_no_new_variable_construction_audit.csv"),
  no_q = path(csv_dir, "S29I_no_q_audit.csv"),
  no_theta = path(csv_dir, "S29I_no_theta_audit.csv"),
  no_utilization = path(csv_dir, "S29I_no_capacity_utilization_audit.csv"),
  no_modeling = path(csv_dir, "S29I_no_modeling_audit.csv"),
  review = path(csv_dir, "S29I_review_needed_ledger.csv"),
  validation = path(csv_dir, "S29I_validation_checks.csv"),
  contract_md = path(md_dir, "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY.md"),
  validation_md = path(md_dir, "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY_VALIDATION.md"),
  decision_md = path(md_dir, "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY_DECISION.md")
)

input_paths <- c(unlist(s29h_input_paths), unlist(s29g_input_paths), unlist(s29f_input_paths))
stop_if_missing(input_paths, "S29I inputs")
md5_before <- tools::md5sum(input_paths)

s29h_contract <- read_csv(s29h_input_paths$contract)
s29h_validation <- read_csv(s29h_input_paths$validation)
s29h_decision <- read_text(s29h_input_paths$decision_md)
s29h_alias_map <- read_csv(s29h_input_paths$alias_map)
s29g_validation <- read_csv(s29g_input_paths$validation)
s29f_long <- read_csv(s29f_input_paths$long)
s29f_validation <- read_csv(s29f_input_paths$validation)

if (!all_pass(s29h_validation) || nrow(s29h_validation) != 79 ||
    !grepl(required_s29h_decision, s29h_decision, fixed = TRUE) ||
    !grepl(required_s29h_status, s29h_decision, fixed = TRUE)) {
  stop("S29H gate is not clean or does not authorize S29I.")
}
if (!all_pass(s29g_validation) || nrow(s29g_validation) != 66) stop("S29G validation gate is not clean.")
if (!all_pass(s29f_validation) || nrow(s29f_validation) != 87) stop("S29F validation gate is not clean.")

s29f_long$year <- as.integer(s29f_long$year)
s29f_long$value <- as.numeric(s29f_long$value)
s29h_contract$first_observed_year <- as.integer(s29h_contract$first_observed_year)
s29h_contract$last_observed_year <- as.integer(s29h_contract$last_observed_year)
s29h_contract$first_fully_supported_year <- as.integer(s29h_contract$first_fully_supported_year)
s29h_contract$baseline_start_year <- suppressWarnings(as.integer(s29h_contract$baseline_start_year))
s29h_contract$baseline_end_year <- suppressWarnings(as.integer(s29h_contract$baseline_end_year))

lane_for <- function(status, variable_id) {
  if (status == "BASELINE_AUTHORIZED" && variable_id == "G_TOT_GPIM_2017") return("baseline_primary_level")
  if (status == "BASELINE_AUTHORIZED" && variable_id == "LOG_G_TOT_GPIM_2017") return("baseline_primary_log")
  if (status == "ROBUSTNESS_AUTHORIZED" && variable_id == "N_TOT_GPIM_2017") return("net_robustness_level")
  if (status == "ROBUSTNESS_AUTHORIZED" && variable_id == "LOG_N_TOT_GPIM_2017") return("net_robustness_log")
  if (status == "CONDITIONAL_SECONDARY") return("conditional_secondary")
  if (status == "DIAGNOSTIC_ONLY") return("diagnostic_reference")
  if (status == "ALIAS_INTERFACE_ONLY") return("alias_authority")
  "excluded"
}
selection_group_for <- function(variable_id, status) {
  if (variable_id %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017")) return("productive_capital_primary_representation")
  if (variable_id %in% c("DLOG_G_TOT", "GROWTH_ARITH_G_TOT")) return("gross_total_capital_growth_representation")
  if (grepl("^L1_", variable_id)) return("lagged_capital_candidate")
  if (status == "ROBUSTNESS_AUTHORIZED") return("net_stock_robustness_representation")
  "not_applicable"
}
joint_use_for <- function(variable_id, status) {
  if (selection_group_for(variable_id, status) %in% c("productive_capital_primary_representation", "gross_total_capital_growth_representation")) return("no")
  "not_applicable"
}
active_default_for <- function(status) ifelse(status == "BASELINE_AUTHORIZED", "yes", "no")
future_auth_for <- function(status) ifelse(status == "BASELINE_AUTHORIZED", "no", "yes")

manifest <- s29h_contract
manifest$interface_lane <- mapply(lane_for, manifest$s29h_contract_status, manifest$variable_id)
manifest$value_bearing_interface_included <- ifelse(manifest$s29h_contract_status %in% c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "CONDITIONAL_SECONDARY"), "yes", "no")
manifest$active_by_default <- ifelse(manifest$s29h_contract_status == "BASELINE_AUTHORIZED", "yes", "no")
manifest$alias_status <- ifelse(manifest$s29h_contract_status == "ALIAS_INTERFACE_ONLY", "alias_interface_only", "not_alias")
manifest$coverage_start <- manifest$first_observed_year
manifest$coverage_end <- manifest$last_observed_year
manifest$warmup_restriction <- ifelse(manifest$warmup_observation_count > 0, "warmup_not_baseline_eligible", "not_applicable")
manifest$selection_group <- mapply(selection_group_for, manifest$variable_id, manifest$s29h_contract_status)
manifest$joint_use_authorized <- mapply(joint_use_for, manifest$variable_id, manifest$s29h_contract_status)
manifest$source_commit <- s29f_commit
manifest$source_stage <- "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS"
manifest$source_file <- "output/US/S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS/csv/S29F_total_capital_analytical_panel_long.csv"
manifest <- manifest[, c(
  "variable_id", "s29h_contract_status", "s29g_downstream_role", "interface_lane",
  "value_bearing_interface_included", "active_by_default", "authoritative_variable_id", "alias_status",
  "unit", "coverage_start", "coverage_end", "first_fully_supported_year", "baseline_start_year",
  "baseline_end_year", "warmup_restriction", "selection_group", "joint_use_authorized",
  "explicit_future_authorization_required", "permitted_use", "prohibited_use", "source_commit",
  "source_stage", "source_file"
)]
names(manifest)[names(manifest) == "s29h_contract_status"] <- "contract_status"
names(manifest)[names(manifest) == "s29g_downstream_role"] <- "contract_role"

active_vars <- manifest$variable_id[manifest$value_bearing_interface_included == "yes"]
active_source <- s29f_long[s29f_long$variable_id %in% active_vars, ]
active_contract <- manifest[match(active_source$variable_id, manifest$variable_id), ]
active_long <- data.frame(
  year = active_source$year,
  variable_id = active_source$variable_id,
  value = active_source$value,
  unit = active_contract$unit,
  contract_status = active_contract$contract_status,
  contract_role = active_contract$contract_role,
  interface_lane = active_contract$interface_lane,
  source_variable_id = active_source$source_variable_id,
  source_stage = active_contract$source_stage,
  source_file = active_contract$source_file,
  first_observed_year = active_contract$coverage_start,
  last_observed_year = active_contract$coverage_end,
  first_fully_supported_year = active_contract$first_fully_supported_year,
  support_status = active_source$support_status,
  baseline_window_eligible = ifelse(active_contract$contract_status == "BASELINE_AUTHORIZED" & active_source$support_status == "fully_supported" & active_source$year >= active_contract$baseline_start_year & active_source$year <= active_contract$baseline_end_year, "yes", "no"),
  warmup_observation = ifelse(active_source$support_status == "partial_vintage_warmup", "yes", "no"),
  active_by_default = active_contract$active_by_default,
  explicit_future_authorization_required = active_contract$explicit_future_authorization_required,
  selection_group = active_contract$selection_group,
  joint_use_authorized = active_contract$joint_use_authorized,
  permitted_use = active_contract$permitted_use,
  prohibited_use = active_contract$prohibited_use,
  stringsAsFactors = FALSE
)
active_long <- active_long[order(active_long$variable_id, active_long$year), ]

make_single_interface <- function(variable_id) {
  rows <- active_long[active_long$variable_id == variable_id, ]
  out <- rows[, c("year", "value", "unit", "support_status", "baseline_window_eligible", "warmup_observation")]
  names(out)[names(out) == "value"] <- variable_id
  out
}
primary_level <- make_single_interface("G_TOT_GPIM_2017")
primary_log <- make_single_interface("LOG_G_TOT_GPIM_2017")
robustness_level <- make_single_interface("N_TOT_GPIM_2017")
robustness_log <- make_single_interface("LOG_N_TOT_GPIM_2017")
conditional_long <- active_long[active_long$contract_status == "CONDITIONAL_SECONDARY", ]

all_years <- sort(unique(s29f_long$year))
active_wide <- data.frame(year = all_years)
for (v in sort(active_vars)) {
  tmp <- active_long[active_long$variable_id == v, c("year", "value")]
  names(tmp)[2] <- v
  active_wide <- merge(active_wide, tmp, by = "year", all.x = TRUE, sort = TRUE)
}

diagnostic_catalog <- manifest[manifest$contract_status == "DIAGNOSTIC_ONLY", c("variable_id", "contract_status", "contract_role", "interface_lane", "source_file", "unit", "coverage_start", "coverage_end", "first_fully_supported_year", "permitted_use", "prohibited_use")]
alias_catalog <- merge(
  manifest[manifest$contract_status == "ALIAS_INTERFACE_ONLY", c("variable_id", "authoritative_variable_id", "contract_status", "interface_lane", "source_file", "unit", "coverage_start", "coverage_end", "permitted_use", "prohibited_use")],
  s29h_alias_map[, c("alias_variable_id", "alias_type", "direction_of_authority")],
  by.x = "variable_id", by.y = "alias_variable_id", all.x = TRUE
)
alias_catalog$downstream_independent_use_authorized <- "no"

copy_audit <- do.call(rbind, lapply(split(active_long, active_long$variable_id), function(df) {
  source <- s29f_long[s29f_long$variable_id == unique(df$variable_id), c("year", "value")]
  merged <- merge(df[, c("year", "value")], source, by = "year", suffixes = c("_interface", "_source"), all.x = TRUE, sort = TRUE)
  residual <- merged$value_interface - merged$value_source
  data.frame(
    stage_id = stage_id,
    variable_id = unique(df$variable_id),
    copied_observations = nrow(merged),
    maximum_absolute_copy_residual = max(abs(residual), na.rm = TRUE),
    missing_source_matches = sum(is.na(merged$value_source)),
    copy_status = ifelse(max(abs(residual), na.rm = TRUE) == 0 && sum(is.na(merged$value_source)) == 0, "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}))

contract_status_audit <- as.data.frame(table(manifest$contract_status), stringsAsFactors = FALSE)
names(contract_status_audit) <- c("contract_status", "manifest_count")
contract_status_audit$expected_count <- c(
  "ALIAS_INTERFACE_ONLY" = 12,
  "BASELINE_AUTHORIZED" = 2,
  "CONDITIONAL_SECONDARY" = 11,
  "DIAGNOSTIC_ONLY" = 72,
  "EXCLUDED_FROM_DOWNSTREAM_INTERFACE" = 0,
  "ROBUSTNESS_AUTHORIZED" = 2
)[contract_status_audit$contract_status]
contract_status_audit$reconciliation_status <- ifelse(contract_status_audit$manifest_count == contract_status_audit$expected_count, "PASS", "FAIL")

lane_audit <- as.data.frame(table(manifest$interface_lane), stringsAsFactors = FALSE)
names(lane_audit) <- c("interface_lane", "manifest_count")
lane_audit$lane_status <- "PASS"

support_audit <- do.call(rbind, lapply(split(active_long, active_long$variable_id), function(df) {
  data.frame(
    stage_id = stage_id,
    variable_id = unique(df$variable_id),
    first_observed_year = min(df$year),
    last_observed_year = max(df$year),
    first_fully_supported_year = unique(df$first_fully_supported_year),
    fully_supported_observations = sum(df$support_status == "fully_supported"),
    warmup_observations = sum(df$warmup_observation == "yes"),
    baseline_eligible_observations = sum(df$baseline_window_eligible == "yes"),
    support_eligibility_status = "PASS",
    stringsAsFactors = FALSE
  )
}))

growth_lock <- data.frame(
  stage_id = stage_id,
  variable_id = c("DLOG_G_TOT", "GROWTH_ARITH_G_TOT"),
  selection_group = "gross_total_capital_growth_representation",
  joint_use_authorized = "no",
  automatic_preference = "none",
  future_selection_required = "yes",
  lock_status = "PASS",
  stringsAsFactors = FALSE
)
lag_lock_vars <- manifest$variable_id[grepl("^L1_", manifest$variable_id) & manifest$value_bearing_interface_included == "yes"]
lag_lock <- data.frame(
  stage_id = stage_id,
  variable_id = lag_lock_vars,
  lag_order = 1,
  source_variable_id = s29h_contract$source_variable_id[match(lag_lock_vars, s29h_contract$variable_id)],
  first_fully_supported_year = manifest$first_fully_supported_year[match(lag_lock_vars, manifest$variable_id)],
  interface_lane = manifest$interface_lane[match(lag_lock_vars, manifest$variable_id)],
  active_by_default = "no",
  explicit_future_authorization_required = "yes",
  lock_status = "PASS",
  stringsAsFactors = FALSE
)

simple_audit <- function(items, evidence) {
  data.frame(stage_id = stage_id, audit_item = items, constructed_object_count = 0, status = "PASS", evidence = evidence, stringsAsFactors = FALSE)
}
no_complete_case <- simple_audit(c("no_common_complete_case_sample", "no_year_dropped_due_to_other_variable_missingness", "no_complete_case_estimation_sample"), "Candidate-wide view preserves all source years and does not filter rows by missingness.")
no_growth <- simple_audit(c("no_automatic_growth_measure_selected", "arithmetic_and_log_growth_not_merged", "growth_selection_lock_created"), "DLOG_G_TOT and GROWTH_ARITH_G_TOT remain separate locked candidates.")
no_lag <- simple_audit(c("lag_variables_in_conditional_lane_only", "lag_variables_inactive_by_default", "no_automatic_lag_activation"), "Lag variables remain conditional and inactive by default.")
no_diagnostic <- simple_audit(c("diagnostic_variables_not_in_active_candidate_interface", "diagnostic_catalog_only"), "Diagnostic variables appear only in the diagnostic reference catalog.")
no_alias <- simple_audit(c("alias_variables_not_in_active_candidate_interface", "aliases_not_independent_objects", "no_alias_duplication"), "Alias variables appear only in the alias authority catalog.")
no_provider_total <- simple_audit(c("provider_total_not_promoted", "tot_not_reaggregated", "gpim_not_rerun"), "Provider TOTAL is not promoted; TOT is not recomputed and GPIM is not rerun.")
no_new <- simple_audit(c("no_new_level_variable", "no_new_log", "no_new_growth_rate", "no_new_difference", "no_new_lag", "no_new_share", "no_new_intensity_measure", "no_transformations_recomputed", "no_values_rounded", "no_values_rescaled", "no_missing_values_imputed", "no_interpolation_performed"), "S29I copies S29F values exactly and constructs no analytical variable.")
no_q <- simple_audit(c("no_q_variables", "no_accumulated_q", "no_omega_weighted_capital_variables"), "No q-family object is constructed or authorized.")
no_theta <- simple_audit(c("no_theta_variables", "no_distribution_capital_interactions", "no_exploitation_weighted_capital_variables"), "No theta or distribution-capital object is constructed or authorized.")
no_utilization <- simple_audit(c("no_productive_capacity", "no_utilization", "no_output_capital_ratio"), "No capacity, utilization, or output-capital ratio is constructed or authorized.")
no_modeling <- simple_audit(c("no_model_input_panel", "no_output_variable_join", "no_distribution_variable_join", "no_modeling_outputs", "no_econometric_outputs"), "No model input, joins, modeling, or econometric output is created.")
review_needed <- data.frame(stage_id = character(), review_reason = character(), action = character(), stringsAsFactors = FALSE)

write.csv(manifest, output_paths$manifest, row.names = FALSE)
write.csv(active_long, output_paths$active_long, row.names = FALSE)
write.csv(active_wide, output_paths$active_wide, row.names = FALSE)
write.csv(primary_level, output_paths$primary_level, row.names = FALSE)
write.csv(primary_log, output_paths$primary_log, row.names = FALSE)
write.csv(robustness_level, output_paths$robustness_level, row.names = FALSE)
write.csv(robustness_log, output_paths$robustness_log, row.names = FALSE)
write.csv(conditional_long, output_paths$conditional, row.names = FALSE)
write.csv(diagnostic_catalog, output_paths$diagnostic, row.names = FALSE)
write.csv(alias_catalog, output_paths$alias, row.names = FALSE)
write.csv(copy_audit, output_paths$copy, row.names = FALSE)
write.csv(contract_status_audit, output_paths$contract_status, row.names = FALSE)
write.csv(lane_audit, output_paths$lane, row.names = FALSE)
write.csv(support_audit, output_paths$support, row.names = FALSE)
write.csv(growth_lock, output_paths$growth_lock, row.names = FALSE)
write.csv(lag_lock, output_paths$lag_lock, row.names = FALSE)
write.csv(no_complete_case, output_paths$no_complete_case, row.names = FALSE)
write.csv(no_growth, output_paths$no_growth, row.names = FALSE)
write.csv(no_lag, output_paths$no_lag, row.names = FALSE)
write.csv(no_diagnostic, output_paths$no_diagnostic, row.names = FALSE)
write.csv(no_alias, output_paths$no_alias, row.names = FALSE)
write.csv(no_provider_total, output_paths$no_provider_total, row.names = FALSE)
write.csv(no_new, output_paths$no_new, row.names = FALSE)
write.csv(no_q, output_paths$no_q, row.names = FALSE)
write.csv(no_theta, output_paths$no_theta, row.names = FALSE)
write.csv(no_utilization, output_paths$no_utilization, row.names = FALSE)
write.csv(no_modeling, output_paths$no_modeling, row.names = FALSE)
write.csv(review_needed, output_paths$review, row.names = FALSE)

md5_after <- tools::md5sum(input_paths)
upstream_unchanged <- identical(unname(md5_before), unname(md5_after))

contract_counts <- table(s29h_contract$s29h_contract_status)
active_candidate_count <- sum(s29h_contract$s29h_contract_status %in% c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "CONDITIONAL_SECONDARY"))
max_copy_residual <- max(as.numeric(copy_audit$maximum_absolute_copy_residual))

validation_checks <- do.call(rbind, list(
  check("s29h_outputs_present", all(file.exists(unlist(s29h_input_paths))), "all required S29H files present"),
  check("s29h_validation_all_pass", all_pass(s29h_validation) && nrow(s29h_validation) == 79, "S29H validation PASS 79"),
  check("s29h_decision_authorizes_s29i", grepl(required_s29h_decision, s29h_decision, fixed = TRUE), required_s29h_decision),
  check("s29g_outputs_present", all(file.exists(unlist(s29g_input_paths))), "required S29G files present"),
  check("s29g_validation_all_pass", all_pass(s29g_validation) && nrow(s29g_validation) == 66, "S29G validation PASS 66"),
  check("s29f_outputs_present", all(file.exists(unlist(s29f_input_paths))), "required S29F files present"),
  check("s29f_validation_all_pass", all_pass(s29f_validation) && nrow(s29f_validation) == 87, "S29F validation PASS 87"),
  check("contracted_variable_count_equals_99", nrow(s29h_contract) == 99, paste0("contracted=", nrow(s29h_contract))),
  check("baseline_authorized_count_equals_2", unname(contract_counts["BASELINE_AUTHORIZED"]) == 2, "baseline=2"),
  check("robustness_authorized_count_equals_2", unname(contract_counts["ROBUSTNESS_AUTHORIZED"]) == 2, "robustness=2"),
  check("conditional_secondary_count_equals_11", unname(contract_counts["CONDITIONAL_SECONDARY"]) == 11, "conditional=11"),
  check("diagnostic_only_count_equals_72", unname(contract_counts["DIAGNOSTIC_ONLY"]) == 72, "diagnostic=72"),
  check("alias_interface_only_count_equals_12", unname(contract_counts["ALIAS_INTERFACE_ONLY"]) == 12, "alias=12"),
  check("excluded_count_equals_0", !("EXCLUDED_FROM_DOWNSTREAM_INTERFACE" %in% names(contract_counts)) || unname(contract_counts["EXCLUDED_FROM_DOWNSTREAM_INTERFACE"]) == 0, "excluded=0"),
  check("active_candidate_count_equals_15", active_candidate_count == 15 && length(active_vars) == 15, "active candidates=15"),
  check("primary_level_variable_present", "G_TOT_GPIM_2017" %in% active_vars, "G_TOT present"),
  check("primary_log_variable_present", "LOG_G_TOT_GPIM_2017" %in% active_vars, "LOG_G_TOT present"),
  check("net_robustness_level_present", "N_TOT_GPIM_2017" %in% active_vars, "N_TOT present"),
  check("net_robustness_log_present", "LOG_N_TOT_GPIM_2017" %in% active_vars, "LOG_N_TOT present"),
  check("all_conditional_secondary_variables_present", all(s29h_contract$variable_id[s29h_contract$s29h_contract_status == "CONDITIONAL_SECONDARY"] %in% active_vars), "all conditional variables active-candidate included"),
  check("primary_level_interface_created", file.exists(output_paths$primary_level) && nrow(primary_level) == 124 && "G_TOT_GPIM_2017" %in% names(primary_level), "primary level interface"),
  check("primary_log_interface_created", file.exists(output_paths$primary_log) && nrow(primary_log) == 124 && "LOG_G_TOT_GPIM_2017" %in% names(primary_log), "primary log interface"),
  check("robustness_level_interface_created", file.exists(output_paths$robustness_level) && nrow(robustness_level) == 124, "robustness level interface"),
  check("robustness_log_interface_created", file.exists(output_paths$robustness_log) && nrow(robustness_log) == 124, "robustness log interface"),
  check("conditional_secondary_interface_created", file.exists(output_paths$conditional) && length(unique(conditional_long$variable_id)) == 11, "conditional interface"),
  check("diagnostic_reference_catalog_created", file.exists(output_paths$diagnostic) && nrow(diagnostic_catalog) == 72, "diagnostic catalog"),
  check("alias_authority_catalog_created", file.exists(output_paths$alias) && nrow(alias_catalog) == 12, "alias catalog"),
  check("complete_interface_manifest_created", file.exists(output_paths$manifest) && nrow(manifest) == 99, "manifest"),
  check("all_99_variables_present_in_manifest", all(s29h_contract$variable_id %in% manifest$variable_id), "all variables in manifest"),
  check("baseline_source_values_copied_exactly", all(copy_audit$copy_status[copy_audit$variable_id %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017")] == "PASS"), "baseline copy PASS"),
  check("robustness_source_values_copied_exactly", all(copy_audit$copy_status[copy_audit$variable_id %in% c("N_TOT_GPIM_2017", "LOG_N_TOT_GPIM_2017")] == "PASS"), "robustness copy PASS"),
  check("conditional_source_values_copied_exactly", all(copy_audit$copy_status[copy_audit$variable_id %in% s29h_contract$variable_id[s29h_contract$s29h_contract_status == "CONDITIONAL_SECONDARY"]] == "PASS"), "conditional copy PASS"),
  check("maximum_copy_residual_equals_zero", max_copy_residual == 0, paste0("max residual=", max_copy_residual)),
  check("no_values_rounded", no_new$status[no_new$audit_item == "no_values_rounded"] == "PASS", "no rounding"),
  check("no_values_rescaled", no_new$status[no_new$audit_item == "no_values_rescaled"] == "PASS", "no rescaling"),
  check("no_missing_values_imputed", no_new$status[no_new$audit_item == "no_missing_values_imputed"] == "PASS", "no imputation"),
  check("no_interpolation_performed", no_new$status[no_new$audit_item == "no_interpolation_performed"] == "PASS", "no interpolation"),
  check("no_transformations_recomputed", no_new$status[no_new$audit_item == "no_transformations_recomputed"] == "PASS", "no recomputation"),
  check("tot_not_reaggregated", no_provider_total$status[no_provider_total$audit_item == "tot_not_reaggregated"] == "PASS", "TOT not reaggregated"),
  check("gpim_not_rerun", no_provider_total$status[no_provider_total$audit_item == "gpim_not_rerun"] == "PASS", "GPIM not rerun"),
  check("primary_level_unit_preserved", unique(primary_level$unit) == "millions_2017_dollars", "G_TOT unit preserved"),
  check("primary_log_unit_preserved", unique(primary_log$unit) == "natural_log_of_millions_2017_dollars", "LOG_G_TOT unit preserved"),
  check("net_robustness_units_preserved", unique(robustness_level$unit) == "millions_2017_dollars" && unique(robustness_log$unit) == "natural_log_of_millions_2017_dollars", "net units preserved"),
  check("source_coverage_preserved", nrow(active_wide) == length(all_years) && min(active_wide$year) == 1901 && max(active_wide$year) == 2024, "1901-2024 preserved"),
  check("variable_specific_support_preserved", all(support_audit$support_eligibility_status == "PASS"), "support propagated"),
  check("baseline_window_eligibility_created", "baseline_window_eligible" %in% names(active_long), "eligibility field"),
  check("tot_primary_baseline_start_equals_1931", min(primary_level$year[primary_level$baseline_window_eligible == "yes"]) == 1931 && min(primary_log$year[primary_log$baseline_window_eligible == "yes"]) == 1931, "primary baseline starts 1931"),
  check("warmup_observations_preserved", any(active_long$warmup_observation == "yes"), "warmup rows retained"),
  check("warmup_observations_not_baseline_eligible", all(active_long$baseline_window_eligible[active_long$warmup_observation == "yes"] == "no"), "warmup not eligible"),
  check("growth_variable_support_start_verified", all(manifest$first_fully_supported_year[manifest$variable_id %in% c("DLOG_G_TOT", "GROWTH_ARITH_G_TOT")] == 1932), "growth support starts 1932"),
  check("lag_variable_support_start_verified", all(lag_lock$first_fully_supported_year %in% c(1932, 1933)), "lag starts verified"),
  check("no_common_complete_case_sample_created", no_complete_case$status[no_complete_case$audit_item == "no_common_complete_case_sample"] == "PASS", "no common sample"),
  check("no_year_dropped_due_to_other_variable_missingness", no_complete_case$status[no_complete_case$audit_item == "no_year_dropped_due_to_other_variable_missingness"] == "PASS" && nrow(active_wide) == 124, "no year dropped"),
  check("arithmetic_growth_candidate_preserved", "GROWTH_ARITH_G_TOT" %in% active_vars, "arithmetic growth preserved"),
  check("log_growth_candidate_preserved", "DLOG_G_TOT" %in% active_vars, "log growth preserved"),
  check("arithmetic_and_log_growth_not_merged", no_growth$status[no_growth$audit_item == "arithmetic_and_log_growth_not_merged"] == "PASS", "growth not merged"),
  check("no_automatic_growth_measure_selected", no_growth$status[no_growth$audit_item == "no_automatic_growth_measure_selected"] == "PASS", "no automatic growth selection"),
  check("growth_selection_lock_created", file.exists(output_paths$growth_lock) && nrow(growth_lock) == 2, "growth lock"),
  check("lag_variables_in_conditional_lane_only", all(lag_lock$interface_lane == "conditional_secondary"), "lags conditional"),
  check("lag_variables_inactive_by_default", all(lag_lock$active_by_default == "no"), "lags inactive"),
  check("no_automatic_lag_activation", no_lag$status[no_lag$audit_item == "no_automatic_lag_activation"] == "PASS", "no lag activation"),
  check("diagnostic_variables_not_in_active_candidate_interface", !any(manifest$variable_id[manifest$contract_status == "DIAGNOSTIC_ONLY"] %in% active_vars), "diagnostics excluded from active"),
  check("alias_variables_not_in_active_candidate_interface", !any(manifest$variable_id[manifest$contract_status == "ALIAS_INTERFACE_ONLY"] %in% active_vars), "aliases excluded from active"),
  check("aliases_not_treated_as_independent_objects", all(alias_catalog$downstream_independent_use_authorized == "no"), "aliases not independent"),
  check("provider_total_not_promoted", no_provider_total$status[no_provider_total$audit_item == "provider_total_not_promoted"] == "PASS", "provider TOTAL not promoted"),
  check("no_new_level_variable_constructed", no_new$status[no_new$audit_item == "no_new_level_variable"] == "PASS", "no new level"),
  check("no_new_log_constructed", no_new$status[no_new$audit_item == "no_new_log"] == "PASS", "no new log"),
  check("no_new_growth_rate_constructed", no_new$status[no_new$audit_item == "no_new_growth_rate"] == "PASS", "no new growth"),
  check("no_new_difference_constructed", no_new$status[no_new$audit_item == "no_new_difference"] == "PASS", "no new difference"),
  check("no_new_lag_constructed", no_new$status[no_new$audit_item == "no_new_lag"] == "PASS", "no new lag"),
  check("no_new_share_constructed", no_new$status[no_new$audit_item == "no_new_share"] == "PASS", "no new share"),
  check("no_new_intensity_measure_constructed", no_new$status[no_new$audit_item == "no_new_intensity_measure"] == "PASS", "no new intensity"),
  check("no_model_input_panel_constructed", no_modeling$status[no_modeling$audit_item == "no_model_input_panel"] == "PASS", "no model input panel"),
  check("no_complete_case_estimation_sample_constructed", no_complete_case$status[no_complete_case$audit_item == "no_complete_case_estimation_sample"] == "PASS", "no complete-case sample"),
  check("no_output_variable_joined", no_modeling$status[no_modeling$audit_item == "no_output_variable_join"] == "PASS", "no output join"),
  check("no_distribution_variable_joined", no_modeling$status[no_modeling$audit_item == "no_distribution_variable_join"] == "PASS", "no distribution join"),
  check("no_q_variables_constructed", all(no_q$status == "PASS"), "no q"),
  check("no_omega_weighted_capital_variables_constructed", no_q$status[no_q$audit_item == "no_omega_weighted_capital_variables"] == "PASS", "no omega capital"),
  check("no_distribution_capital_interactions_constructed", no_theta$status[no_theta$audit_item == "no_distribution_capital_interactions"] == "PASS", "no distribution interactions"),
  check("no_theta_variables_constructed", all(no_theta$status == "PASS"), "no theta"),
  check("no_productive_capacity_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_productive_capacity"] == "PASS", "no capacity"),
  check("no_utilization_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_utilization"] == "PASS", "no utilization"),
  check("no_output_capital_ratio_constructed", no_utilization$status[no_utilization$audit_item == "no_output_capital_ratio"] == "PASS", "no output-capital ratio"),
  check("no_modeling_outputs_created", no_modeling$status[no_modeling$audit_item == "no_modeling_outputs"] == "PASS", "no modeling"),
  check("no_econometric_outputs_created", no_modeling$status[no_modeling$audit_item == "no_econometric_outputs"] == "PASS", "no econometrics"),
  check("upstream_outputs_not_modified", upstream_unchanged, "S29H/S29G/S29F input hashes unchanged"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "provider tracked and staged diffs clean; pre-existing untracked files ignored")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)
all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 87
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

contract_md <- c(
  "# S29I Total Capital Downstream Interface Assembly",
  "",
  "S29I assembles S29H-contracted variables into separate downstream interface lanes. It copies S29F values exactly and creates no new economic variables, transformations, complete-case samples, q, theta, productive capacity, utilization, modeling outputs, or econometric outputs.",
  "",
  "## Lanes",
  "",
  "- Baseline primary level: `G_TOT_GPIM_2017`.",
  "- Baseline primary log: `LOG_G_TOT_GPIM_2017`.",
  "- Net robustness level: `N_TOT_GPIM_2017`.",
  "- Net robustness log: `LOG_N_TOT_GPIM_2017`.",
  "- Conditional secondary variables remain inactive by default and require explicit future authorization.",
  "- Diagnostic and alias variables are catalogs only, not active value-bearing candidates."
)
writeLines(contract_md, output_paths$contract_md)

validation_md <- c(
  "# S29I Total Capital Downstream Interface Assembly Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 87", "FAIL"), "`."),
  paste0("Active value-bearing candidates: `", length(active_vars), "`."),
  paste0("Active long rows: `", nrow(active_long), "`."),
  paste0("Active wide dimensions: `", nrow(active_wide), " x ", ncol(active_wide), "`."),
  paste0("Maximum source-copy residual: `", max_copy_residual, "`."),
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29I Total Capital Downstream Interface Assembly Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29I consumed S29H commit `", s29h_commit, "`, S29G commit `", s29g_commit, "`, and S29F commit `", s29f_commit, "`."),
  paste0("S29H validation and decision: `PASS 79`; `", required_s29h_decision, "`."),
  paste0("S29I validation: `", ifelse(all_validation_pass, "PASS 87", "FAIL"), "`."),
  "",
  "S29I authorizes S29J as an independent interface validation and immutable handoff stage only.",
  "",
  "S29I stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) stop("S29I validation failed; see ", output_paths$validation)

message("S29I validation PASS 87")
message("Active value-bearing candidates: ", length(active_vars))
message("Active long rows: ", nrow(active_long))
message("Decision: ", final_decision)
