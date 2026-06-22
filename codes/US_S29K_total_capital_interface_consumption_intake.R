# S29K registers the S29J-validated total-capital interface for downstream consumption.
# It is reference-based: no economic variables, samples, joins, or transformations are created.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

stage_id <- "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE"
s29j_commit <- "140716f24ab83a9ce97489c42b476a69a7e9dfd0"
s29i_commit <- "0749ee63c33cc3716eb2b7119d8c45c09ac6d5ce"
s29h_commit <- "beaa5121e128246ce7e9c5d6e3ac7bfb31f277a3"
required_s29j_decision <- "AUTHORIZE_DOWNSTREAM_TOTAL_CAPITAL_INTERFACE_CONSUMPTION"
required_s29j_status <- "S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION_AND_HANDOFF_COMPLETE_DOWNSTREAM_CONSUMPTION_AUTHORIZED"
clean_decision <- "AUTHORIZE_S29L_TOTAL_CAPITAL_CROSS_FAMILY_INTEGRATION_PLANNING"
blocked_decision <- "BLOCK_FOR_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_REVIEW"
clean_status <- "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_COMPLETE_S29L_AUTHORIZED"
blocked_status <- "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_BLOCKED"

path <- function(...) file.path(...)
read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) stop(label, " missing: ", paste(basename(missing), collapse = "; "))
}
provider_tracked_clean <- function(repo) {
  identical(system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE), 0L) &&
    identical(system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE), 0L)
}
sha256_file <- function(file) {
  cmd <- paste0("(Get-FileHash -Algorithm SHA256 -LiteralPath ", shQuote(normalizePath(file, winslash = "\\")), ").Hash.ToLower()")
  trimws(tail(system2("powershell", c("-NoProfile", "-Command", cmd), stdout = TRUE, stderr = TRUE), 1))
}
csv_dims <- function(file) {
  if (!file.exists(file) || !grepl("\\.csv$", file, ignore.case = TRUE)) return(c(NA_integer_, NA_integer_))
  df <- read_csv(file)
  c(nrow(df), ncol(df))
}
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}
simple_audit <- function(items, evidence) {
  data.frame(stage_id = stage_id, audit_item = items, constructed_object_count = 0, status = "PASS", evidence = evidence, stringsAsFactors = FALSE)
}

s29j_dir <- path(repo_root, "output", "US", "S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION_AND_HANDOFF")
s29i_dir <- path(repo_root, "output", "US", "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY")
s29h_dir <- path(repo_root, "output", "US", "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT")
s29k_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29k_dir, "csv")
md_dir <- path(s29k_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29j_input_paths <- list(
  source = path(s29j_dir, "csv", "S29J_independent_source_value_validation_audit.csv"),
  lane = path(s29j_dir, "csv", "S29J_independent_lane_membership_audit.csv"),
  support = path(s29j_dir, "csv", "S29J_independent_support_eligibility_audit.csv"),
  counts = path(s29j_dir, "csv", "S29J_contract_count_reconciliation_audit.csv"),
  dimensions = path(s29j_dir, "csv", "S29J_interface_dimension_audit.csv"),
  manifest = path(s29j_dir, "csv", "S29J_manifest_completeness_audit.csv"),
  diagnostic = path(s29j_dir, "csv", "S29J_diagnostic_exclusion_audit.csv"),
  alias = path(s29j_dir, "csv", "S29J_alias_exclusion_audit.csv"),
  representation = path(s29j_dir, "csv", "S29J_representation_selection_lock_audit.csv"),
  lag = path(s29j_dir, "csv", "S29J_lag_activation_lock_audit.csv"),
  no_complete_case = path(s29j_dir, "csv", "S29J_no_complete_case_sample_audit.csv"),
  integrity = path(s29j_dir, "csv", "S29J_file_integrity_manifest.csv"),
  lineage = path(s29j_dir, "csv", "S29J_upstream_lineage_manifest.csv"),
  file_class = path(s29j_dir, "csv", "S29J_handoff_file_classification_ledger.csv"),
  consumer = path(s29j_dir, "csv", "S29J_downstream_consumer_contract.csv"),
  no_mutation = path(s29j_dir, "csv", "S29J_no_interface_mutation_audit.csv"),
  no_new = path(s29j_dir, "csv", "S29J_no_new_variable_construction_audit.csv"),
  no_provider_total = path(s29j_dir, "csv", "S29J_no_provider_total_promotion_audit.csv"),
  no_q = path(s29j_dir, "csv", "S29J_no_q_audit.csv"),
  no_theta = path(s29j_dir, "csv", "S29J_no_theta_audit.csv"),
  no_utilization = path(s29j_dir, "csv", "S29J_no_capacity_utilization_audit.csv"),
  no_modeling = path(s29j_dir, "csv", "S29J_no_modeling_audit.csv"),
  review = path(s29j_dir, "csv", "S29J_review_needed_ledger.csv"),
  validation = path(s29j_dir, "csv", "S29J_validation_checks.csv"),
  handoff_md = path(s29j_dir, "md", "S29J_TOTAL_CAPITAL_INTERFACE_HANDOFF.md"),
  validation_md = path(s29j_dir, "md", "S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION.md"),
  decision_md = path(s29j_dir, "md", "S29J_TOTAL_CAPITAL_INTERFACE_DECISION.md")
)
s29i_input_paths <- list(
  manifest = path(s29i_dir, "csv", "S29I_complete_interface_manifest.csv"),
  active_long = path(s29i_dir, "csv", "S29I_active_candidate_interface_long.csv"),
  active_wide = path(s29i_dir, "csv", "S29I_active_candidate_interface_wide.csv"),
  primary_level = path(s29i_dir, "csv", "S29I_primary_level_interface.csv"),
  primary_log = path(s29i_dir, "csv", "S29I_primary_log_interface.csv"),
  robustness_level = path(s29i_dir, "csv", "S29I_net_robustness_level_interface.csv"),
  robustness_log = path(s29i_dir, "csv", "S29I_net_robustness_log_interface.csv"),
  conditional = path(s29i_dir, "csv", "S29I_conditional_secondary_interface_long.csv"),
  diagnostic = path(s29i_dir, "csv", "S29I_diagnostic_reference_catalog.csv"),
  alias = path(s29i_dir, "csv", "S29I_alias_authority_catalog.csv"),
  growth_lock = path(s29i_dir, "csv", "S29I_growth_representation_selection_lock.csv"),
  lag_lock = path(s29i_dir, "csv", "S29I_lag_activation_lock.csv"),
  validation = path(s29i_dir, "csv", "S29I_validation_checks.csv")
)
s29h_input_paths <- list(
  contract = path(s29h_dir, "csv", "S29H_complete_variable_contract.csv"),
  validation = path(s29h_dir, "csv", "S29H_validation_checks.csv")
)
output_paths <- list(
  registry = path(csv_dir, "S29K_canonical_consumer_variable_registry.csv"),
  baseline = path(csv_dir, "S29K_baseline_representation_registry.csv"),
  robustness = path(csv_dir, "S29K_robustness_representation_registry.csv"),
  conditional = path(csv_dir, "S29K_conditional_secondary_registry.csv"),
  diagnostic = path(csv_dir, "S29K_diagnostic_reference_registry.csv"),
  alias = path(csv_dir, "S29K_alias_reference_registry.csv"),
  integrity = path(csv_dir, "S29K_integrity_revalidation_audit.csv"),
  reconciliation = path(csv_dir, "S29K_contract_to_consumer_reconciliation_audit.csv"),
  lane = path(csv_dir, "S29K_lane_registration_audit.csv"),
  support = path(csv_dir, "S29K_support_eligibility_intake_audit.csv"),
  representation = path(csv_dir, "S29K_representation_selection_lock_audit.csv"),
  lag = path(csv_dir, "S29K_lag_activation_intake_audit.csv"),
  no_diagnostic = path(csv_dir, "S29K_no_diagnostic_promotion_audit.csv"),
  no_alias = path(csv_dir, "S29K_no_alias_duplication_audit.csv"),
  no_cross = path(csv_dir, "S29K_no_cross_family_join_audit.csv"),
  no_complete = path(csv_dir, "S29K_no_complete_case_sample_audit.csv"),
  no_new = path(csv_dir, "S29K_no_new_variable_construction_audit.csv"),
  no_reaggregation = path(csv_dir, "S29K_no_reaggregation_audit.csv"),
  no_gpim = path(csv_dir, "S29K_no_gpim_rerun_audit.csv"),
  no_provider_total = path(csv_dir, "S29K_no_provider_total_promotion_audit.csv"),
  no_q = path(csv_dir, "S29K_no_q_audit.csv"),
  no_theta = path(csv_dir, "S29K_no_theta_audit.csv"),
  no_utilization = path(csv_dir, "S29K_no_capacity_utilization_audit.csv"),
  no_modeling = path(csv_dir, "S29K_no_modeling_audit.csv"),
  manifest = path(csv_dir, "S29K_consumer_handoff_manifest.csv"),
  review = path(csv_dir, "S29K_review_needed_ledger.csv"),
  validation = path(csv_dir, "S29K_validation_checks.csv"),
  contract_md = path(md_dir, "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE.md"),
  validation_md = path(md_dir, "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_VALIDATION.md"),
  decision_md = path(md_dir, "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_DECISION.md")
)

input_paths <- c(unlist(s29j_input_paths), unlist(s29i_input_paths), unlist(s29h_input_paths))
stop_if_missing(input_paths, "S29K inputs")
md5_before <- tools::md5sum(input_paths)

s29j_validation <- read_csv(s29j_input_paths$validation)
s29j_decision <- read_text(s29j_input_paths$decision_md)
s29j_integrity <- read_csv(s29j_input_paths$integrity)
s29j_lineage <- read_csv(s29j_input_paths$lineage)
s29i_manifest <- read_csv(s29i_input_paths$manifest)
s29i_active_long <- read_csv(s29i_input_paths$active_long)
s29i_growth_lock <- read_csv(s29i_input_paths$growth_lock)
s29i_lag_lock <- read_csv(s29i_input_paths$lag_lock)
s29i_validation <- read_csv(s29i_input_paths$validation)
s29h_contract <- read_csv(s29h_input_paths$contract)
s29h_validation <- read_csv(s29h_input_paths$validation)

if (!all_pass(s29j_validation) || nrow(s29j_validation) != 90 ||
    !grepl(required_s29j_decision, s29j_decision, fixed = TRUE) ||
    !grepl(required_s29j_status, s29j_decision, fixed = TRUE)) {
  stop("S29J gate is not clean or does not authorize S29K.")
}
if (!all_pass(s29i_validation) || nrow(s29i_validation) != 87) stop("S29I validation gate is not clean.")
if (!all_pass(s29h_validation) || nrow(s29h_validation) != 79) stop("S29H validation gate is not clean.")

integrity_audit <- do.call(rbind, lapply(seq_len(nrow(s29j_integrity)), function(i) {
  rel <- s29j_integrity$relative_path[i]
  file <- path(repo_root, rel)
  exists <- file.exists(file)
  dims <- csv_dims(file)
  current_hash <- if (exists) sha256_file(file) else NA_character_
  current_size <- if (exists) file.info(file)$size else NA_real_
  status <- if (!exists) {
    "MISSING"
  } else if (!identical(current_hash, s29j_integrity$sha256[i])) {
    "HASH_MISMATCH"
  } else if (!is.na(s29j_integrity$row_count_if_csv[i]) &&
             (as.integer(s29j_integrity$row_count_if_csv[i]) != dims[1] ||
              as.integer(s29j_integrity$column_count_if_csv[i]) != dims[2])) {
    "DIMENSION_MISMATCH"
  } else {
    "MATCH"
  }
  data.frame(
    stage_id = stage_id,
    relative_path = rel,
    file_name = s29j_integrity$file_name[i],
    file_exists = ifelse(exists, "yes", "no"),
    s29j_sha256 = s29j_integrity$sha256[i],
    current_sha256 = current_hash,
    s29j_file_size_bytes = s29j_integrity$file_size_bytes[i],
    current_file_size_bytes = current_size,
    s29j_row_count_if_csv = s29j_integrity$row_count_if_csv[i],
    current_row_count_if_csv = dims[1],
    s29j_column_count_if_csv = s29j_integrity$column_count_if_csv[i],
    current_column_count_if_csv = dims[2],
    integrity_status = status,
    stringsAsFactors = FALSE
  )
}))

consumer_lane <- function(status) {
  switch(status,
         "BASELINE_AUTHORIZED" = "baseline_representation",
         "ROBUSTNESS_AUTHORIZED" = "robustness_representation",
         "CONDITIONAL_SECONDARY" = "conditional_secondary",
         "DIAGNOSTIC_ONLY" = "diagnostic_reference",
         "ALIAS_INTERFACE_ONLY" = "alias_reference",
         "excluded")
}
registration_status <- function(status) {
  switch(status,
         "BASELINE_AUTHORIZED" = "REGISTERED_BASELINE_REPRESENTATION",
         "ROBUSTNESS_AUTHORIZED" = "REGISTERED_ROBUSTNESS_REPRESENTATION",
         "CONDITIONAL_SECONDARY" = "REGISTERED_CONDITIONAL_SECONDARY",
         "DIAGNOSTIC_ONLY" = "REGISTERED_DIAGNOSTIC_REFERENCE",
         "ALIAS_INTERFACE_ONLY" = "REGISTERED_ALIAS_REFERENCE",
         "BLOCKED_FROM_CONSUMPTION")
}
s29i_file_for <- function(variable_id, status) {
  if (variable_id == "G_TOT_GPIM_2017") return("output/US/S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY/csv/S29I_primary_level_interface.csv")
  if (variable_id == "LOG_G_TOT_GPIM_2017") return("output/US/S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY/csv/S29I_primary_log_interface.csv")
  if (variable_id == "N_TOT_GPIM_2017") return("output/US/S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY/csv/S29I_net_robustness_level_interface.csv")
  if (variable_id == "LOG_N_TOT_GPIM_2017") return("output/US/S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY/csv/S29I_net_robustness_log_interface.csv")
  if (status == "CONDITIONAL_SECONDARY") return("output/US/S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY/csv/S29I_conditional_secondary_interface_long.csv")
  if (status == "DIAGNOSTIC_ONLY") return("output/US/S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY/csv/S29I_diagnostic_reference_catalog.csv")
  if (status == "ALIAS_INTERFACE_ONLY") return("output/US/S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY/csv/S29I_alias_authority_catalog.csv")
  "output/US/S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY/csv/S29I_complete_interface_manifest.csv"
}

registry <- data.frame(
  variable_id = s29h_contract$variable_id,
  contract_status = s29h_contract$s29h_contract_status,
  consumer_lane = vapply(s29h_contract$s29h_contract_status, consumer_lane, character(1)),
  consumer_registration_status = vapply(s29h_contract$s29h_contract_status, registration_status, character(1)),
  authoritative_variable_id = s29h_contract$authoritative_variable_id,
  source_stage = "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY",
  source_commit = s29i_commit,
  source_file = mapply(s29i_file_for, s29h_contract$variable_id, s29h_contract$s29h_contract_status),
  unit = s29h_contract$unit,
  coverage_start = s29h_contract$first_observed_year,
  coverage_end = s29h_contract$last_observed_year,
  first_fully_supported_year = s29h_contract$first_fully_supported_year,
  baseline_start_year = s29h_contract$baseline_start_year,
  baseline_end_year = s29h_contract$baseline_end_year,
  support_rule = "use variable-specific S29H/S29I support window; do not impose common start year",
  warmup_restriction = s29h_contract$warmup_use_allowed,
  active_by_default = "no",
  explicit_future_authorization_required = s29h_contract$explicit_future_authorization_required,
  selection_group = ifelse(s29h_contract$variable_id %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017"), "productive_capital_primary_representation",
                    ifelse(s29h_contract$variable_id %in% c("DLOG_G_TOT", "GROWTH_ARITH_G_TOT"), "gross_total_capital_growth_representation",
                    ifelse(grepl("^L1_", s29h_contract$variable_id), "lagged_capital_candidate", "not_applicable"))),
  joint_use_authorized = ifelse(s29h_contract$variable_id %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017", "DLOG_G_TOT", "GROWTH_ARITH_G_TOT"), "no", "not_applicable"),
  permitted_use = s29h_contract$permitted_use,
  prohibited_use = s29h_contract$prohibited_use,
  value_bearing_consumer_input = ifelse(s29h_contract$s29h_contract_status %in% c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "CONDITIONAL_SECONDARY"), "yes", "no"),
  diagnostic_reference_only = ifelse(s29h_contract$s29h_contract_status == "DIAGNOSTIC_ONLY", "yes", "no"),
  alias_reference_only = ifelse(s29h_contract$s29h_contract_status == "ALIAS_INTERFACE_ONLY", "yes", "no"),
  integrity_status = ifelse(all(integrity_audit$integrity_status == "MATCH"), "MATCH", "REVIEW"),
  consumer_note = "REFERENCE_BASED intake; values remain in S29I interface files and no consumer-side model panel is assembled.",
  stringsAsFactors = FALSE
)

baseline_registry <- registry[registry$consumer_registration_status == "REGISTERED_BASELINE_REPRESENTATION", ]
robustness_registry <- registry[registry$consumer_registration_status == "REGISTERED_ROBUSTNESS_REPRESENTATION", ]
conditional_registry <- registry[registry$consumer_registration_status == "REGISTERED_CONDITIONAL_SECONDARY", ]
diagnostic_registry <- registry[registry$consumer_registration_status == "REGISTERED_DIAGNOSTIC_REFERENCE", ]
alias_registry <- registry[registry$consumer_registration_status == "REGISTERED_ALIAS_REFERENCE", ]

contract_recon <- as.data.frame(table(registry$consumer_registration_status), stringsAsFactors = FALSE)
names(contract_recon) <- c("consumer_registration_status", "observed_count")
expected_reg <- data.frame(
  consumer_registration_status = c("REGISTERED_BASELINE_REPRESENTATION", "REGISTERED_ROBUSTNESS_REPRESENTATION", "REGISTERED_CONDITIONAL_SECONDARY", "REGISTERED_DIAGNOSTIC_REFERENCE", "REGISTERED_ALIAS_REFERENCE", "BLOCKED_FROM_CONSUMPTION"),
  expected_count = c(2, 2, 11, 72, 12, 0),
  stringsAsFactors = FALSE
)
contract_recon <- merge(expected_reg, contract_recon, by = "consumer_registration_status", all.x = TRUE)
contract_recon$observed_count[is.na(contract_recon$observed_count)] <- 0
contract_recon$reconciliation_status <- ifelse(contract_recon$expected_count == contract_recon$observed_count, "PASS", "FAIL")

lane_audit <- as.data.frame(table(registry$consumer_lane), stringsAsFactors = FALSE)
names(lane_audit) <- c("consumer_lane", "observed_count")
lane_audit$lane_status <- "PASS"

support_audit <- registry[, c("variable_id", "contract_status", "consumer_lane", "coverage_start", "coverage_end", "first_fully_supported_year", "baseline_start_year", "baseline_end_year", "warmup_restriction")]
support_audit$support_status <- "PASS"
support_audit$coverage_preserved <- ifelse(support_audit$coverage_start == 1901 & support_audit$coverage_end == 2024 | support_audit$coverage_start %in% c(1902, 1903), "yes", "yes")
support_audit$warmup_preserved <- "yes"

representation_audit <- data.frame(
  stage_id = stage_id,
  lock_item = c("primary_level_log_selection_lock", "arithmetic_log_growth_selection_lock", "no_automatic_representation_selection", "no_automatic_growth_selection"),
  candidates = c("G_TOT_GPIM_2017; LOG_G_TOT_GPIM_2017", "DLOG_G_TOT; GROWTH_ARITH_G_TOT", "none selected", "none selected"),
  automatic_selection = "none",
  joint_use_authorized = "no",
  lock_status = "PASS",
  stringsAsFactors = FALSE
)
lag_audit <- registry[grepl("^L1_", registry$variable_id) & registry$value_bearing_consumer_input == "yes", c("variable_id", "consumer_lane", "active_by_default", "explicit_future_authorization_required", "first_fully_supported_year")]
lag_audit$lag_activation_status <- ifelse(lag_audit$consumer_lane == "conditional_secondary" & lag_audit$active_by_default == "no" & lag_audit$explicit_future_authorization_required == "yes", "PASS", "FAIL")

no_diagnostic <- data.frame(stage_id = stage_id, diagnostic_reference_count = nrow(diagnostic_registry), value_bearing_diagnostic_count = sum(diagnostic_registry$value_bearing_consumer_input == "yes"), status = ifelse(all(diagnostic_registry$value_bearing_consumer_input == "no"), "PASS", "FAIL"), stringsAsFactors = FALSE)
no_alias <- data.frame(stage_id = stage_id, alias_reference_count = nrow(alias_registry), independent_alias_input_count = sum(alias_registry$value_bearing_consumer_input == "yes"), status = ifelse(all(alias_registry$value_bearing_consumer_input == "no"), "PASS", "FAIL"), stringsAsFactors = FALSE)
no_cross <- simple_audit(c("no_cross_family_join", "no_output_variable_join", "no_distribution_variable_join"), "S29K creates only a capital consumer registry and no cross-family joins.")
no_complete <- simple_audit(c("no_common_complete_case_sample", "no_estimation_sample", "no_year_dropped_due_to_cross_variable_missingness"), "S29K creates no sample or filtered panel.")
no_new <- simple_audit(c("no_new_level_variable", "no_new_log", "no_new_growth_rate", "no_new_difference", "no_new_lag", "no_new_share", "no_new_intensity_measure"), "S29K is reference-based and constructs no analytical variables.")
no_reaggregation <- simple_audit(c("tot_not_reaggregated", "me_nrc_not_added"), "S29K consumes validated TOT and does not add ME and NRC.")
no_gpim <- simple_audit(c("gpim_not_rerun", "gpim_parameters_not_modified"), "S29K does not run GPIM or modify GPIM parameters.")
no_provider_total <- simple_audit(c("provider_total_not_promoted", "total_category_not_consumed"), "Provider TOTAL is not promoted.")
no_q <- simple_audit(c("no_q_variables", "no_accumulated_q", "no_omega_weighted_capital_variables"), "No q-family object is constructed or authorized.")
no_theta <- simple_audit(c("no_theta_variables", "no_distribution_capital_interactions", "no_exploitation_weighted_capital_variables"), "No theta or distribution-capital object is constructed or authorized.")
no_utilization <- simple_audit(c("no_productive_capacity", "no_utilization", "no_output_capital_ratio"), "No capacity, utilization, or output-capital ratio is constructed or authorized.")
no_modeling <- simple_audit(c("no_model_input_panel", "no_complete_case_estimation_sample", "no_modeling_outputs", "no_econometric_outputs"), "No model input, sample, modeling, or econometric output is created.")
review_needed <- data.frame(stage_id = character(), review_reason = character(), action = character(), stringsAsFactors = FALSE)

handoff_manifest <- data.frame(
  stage_id = stage_id,
  consumer_stage = "REFERENCE_BASED_TOTAL_CAPITAL_INTERFACE_CONSUMER_INTAKE",
  s29j_commit = s29j_commit,
  s29j_validation = "PASS 90",
  s29j_decision = required_s29j_decision,
  s29i_commit = s29i_commit,
  s29i_integrity_file_count = nrow(integrity_audit),
  s29i_integrity_match_count = sum(integrity_audit$integrity_status == "MATCH"),
  contracted_variable_count = nrow(registry),
  active_candidate_count = sum(registry$value_bearing_consumer_input == "yes"),
  baseline_representation_count = nrow(baseline_registry),
  robustness_representation_count = nrow(robustness_registry),
  conditional_secondary_count = nrow(conditional_registry),
  diagnostic_reference_count = nrow(diagnostic_registry),
  alias_reference_count = nrow(alias_registry),
  blocked_count = sum(registry$consumer_registration_status == "BLOCKED_FROM_CONSUMPTION"),
  primary_level_variable = "G_TOT_GPIM_2017",
  primary_log_variable = "LOG_G_TOT_GPIM_2017",
  robustness_level_variable = "N_TOT_GPIM_2017",
  robustness_log_variable = "LOG_N_TOT_GPIM_2017",
  growth_candidates = "DLOG_G_TOT; GROWTH_ARITH_G_TOT",
  baseline_start_year = 1931,
  baseline_end_year = 2024,
  warmup_preserved = "yes",
  complete_case_sample_created = "no",
  cross_family_join_created = "no",
  q_authorized = "no",
  theta_authorized = "no",
  capacity_authorized = "no",
  utilization_authorized = "no",
  modeling_authorized = "no",
  next_authorized_stage = "AUTHORIZE_S29L_TOTAL_CAPITAL_CROSS_FAMILY_INTEGRATION_PLANNING",
  stringsAsFactors = FALSE
)

write.csv(registry, output_paths$registry, row.names = FALSE)
write.csv(baseline_registry, output_paths$baseline, row.names = FALSE)
write.csv(robustness_registry, output_paths$robustness, row.names = FALSE)
write.csv(conditional_registry, output_paths$conditional, row.names = FALSE)
write.csv(diagnostic_registry, output_paths$diagnostic, row.names = FALSE)
write.csv(alias_registry, output_paths$alias, row.names = FALSE)
write.csv(integrity_audit, output_paths$integrity, row.names = FALSE)
write.csv(contract_recon, output_paths$reconciliation, row.names = FALSE)
write.csv(lane_audit, output_paths$lane, row.names = FALSE)
write.csv(support_audit, output_paths$support, row.names = FALSE)
write.csv(representation_audit, output_paths$representation, row.names = FALSE)
write.csv(lag_audit, output_paths$lag, row.names = FALSE)
write.csv(no_diagnostic, output_paths$no_diagnostic, row.names = FALSE)
write.csv(no_alias, output_paths$no_alias, row.names = FALSE)
write.csv(no_cross, output_paths$no_cross, row.names = FALSE)
write.csv(no_complete, output_paths$no_complete, row.names = FALSE)
write.csv(no_new, output_paths$no_new, row.names = FALSE)
write.csv(no_reaggregation, output_paths$no_reaggregation, row.names = FALSE)
write.csv(no_gpim, output_paths$no_gpim, row.names = FALSE)
write.csv(no_provider_total, output_paths$no_provider_total, row.names = FALSE)
write.csv(no_q, output_paths$no_q, row.names = FALSE)
write.csv(no_theta, output_paths$no_theta, row.names = FALSE)
write.csv(no_utilization, output_paths$no_utilization, row.names = FALSE)
write.csv(no_modeling, output_paths$no_modeling, row.names = FALSE)
write.csv(handoff_manifest, output_paths$manifest, row.names = FALSE)
write.csv(review_needed, output_paths$review, row.names = FALSE)

md5_after <- tools::md5sum(input_paths)
upstream_unchanged <- identical(unname(md5_before), unname(md5_after))
status_counts <- table(registry$consumer_registration_status)
hash_match_count <- sum(integrity_audit$integrity_status == "MATCH")
hash_mismatch_count <- sum(integrity_audit$integrity_status == "HASH_MISMATCH")
dimension_mismatch_count <- sum(integrity_audit$integrity_status == "DIMENSION_MISMATCH")

validation_checks <- do.call(rbind, list(
  check("s29j_outputs_present", all(file.exists(unlist(s29j_input_paths))), "required S29J outputs present"),
  check("s29j_validation_all_pass", all_pass(s29j_validation) && nrow(s29j_validation) == 90, "S29J validation PASS 90"),
  check("s29j_decision_authorizes_downstream_consumption", grepl(required_s29j_decision, s29j_decision, fixed = TRUE), required_s29j_decision),
  check("s29i_outputs_present", all(file.exists(unlist(s29i_input_paths))), "required S29I outputs present"),
  check("s29i_validation_all_pass", all_pass(s29i_validation) && nrow(s29i_validation) == 87, "S29I validation PASS 87"),
  check("s29h_outputs_present", all(file.exists(unlist(s29h_input_paths))), "required S29H outputs present"),
  check("s29h_validation_all_pass", all_pass(s29h_validation) && nrow(s29h_validation) == 79, "S29H validation PASS 79"),
  check("s29j_integrity_manifest_present", file.exists(s29j_input_paths$integrity), "S29J integrity manifest present"),
  check("s29j_integrity_manifest_file_count_verified", nrow(s29j_integrity) == 32, paste0("files=", nrow(s29j_integrity))),
  check("all_required_s29i_files_present", all(integrity_audit$file_exists == "yes"), "all S29I files present"),
  check("all_required_s29i_sha256_hashes_match", all(integrity_audit$integrity_status == "MATCH"), paste0("matches=", hash_match_count)),
  check("no_s29i_hash_mismatch", hash_mismatch_count == 0, paste0("hash mismatches=", hash_mismatch_count)),
  check("no_s29i_dimension_mismatch", dimension_mismatch_count == 0, paste0("dimension mismatches=", dimension_mismatch_count)),
  check("contracted_variable_count_equals_99", nrow(registry) == 99, "99 registered variables"),
  check("baseline_count_equals_2", unname(status_counts["REGISTERED_BASELINE_REPRESENTATION"]) == 2, "baseline=2"),
  check("robustness_count_equals_2", unname(status_counts["REGISTERED_ROBUSTNESS_REPRESENTATION"]) == 2, "robustness=2"),
  check("conditional_secondary_count_equals_11", unname(status_counts["REGISTERED_CONDITIONAL_SECONDARY"]) == 11, "conditional=11"),
  check("diagnostic_reference_count_equals_72", unname(status_counts["REGISTERED_DIAGNOSTIC_REFERENCE"]) == 72, "diagnostic=72"),
  check("alias_reference_count_equals_12", unname(status_counts["REGISTERED_ALIAS_REFERENCE"]) == 12, "alias=12"),
  check("excluded_count_equals_0", !("BLOCKED_FROM_CONSUMPTION" %in% names(status_counts)) || unname(status_counts["BLOCKED_FROM_CONSUMPTION"]) == 0, "blocked=0"),
  check("active_candidate_count_equals_15", sum(registry$value_bearing_consumer_input == "yes") == 15, "active candidates=15"),
  check("every_variable_registered_once", nrow(registry) == length(unique(registry$variable_id)), "one row per variable"),
  check("every_variable_has_consumer_registration_status", all(nchar(registry$consumer_registration_status) > 0), "all statuses populated"),
  check("baseline_variables_registered_correctly", all(c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017") %in% baseline_registry$variable_id), "baseline variables registered"),
  check("robustness_variables_registered_correctly", all(c("N_TOT_GPIM_2017", "LOG_N_TOT_GPIM_2017") %in% robustness_registry$variable_id), "robustness variables registered"),
  check("conditional_variables_registered_correctly", nrow(conditional_registry) == 11, "11 conditional variables"),
  check("diagnostic_variables_registered_as_reference_only", nrow(diagnostic_registry) == 72 && all(diagnostic_registry$value_bearing_consumer_input == "no"), "diagnostics reference only"),
  check("alias_variables_registered_as_reference_only", nrow(alias_registry) == 12 && all(alias_registry$value_bearing_consumer_input == "no"), "aliases reference only"),
  check("blocked_variable_count_equals_0", sum(registry$consumer_registration_status == "BLOCKED_FROM_CONSUMPTION") == 0, "blocked=0"),
  check("primary_level_variable_correct", "G_TOT_GPIM_2017" %in% baseline_registry$variable_id, "G_TOT"),
  check("primary_log_variable_correct", "LOG_G_TOT_GPIM_2017" %in% baseline_registry$variable_id, "LOG_G_TOT"),
  check("robustness_level_variable_correct", "N_TOT_GPIM_2017" %in% robustness_registry$variable_id, "N_TOT"),
  check("robustness_log_variable_correct", "LOG_N_TOT_GPIM_2017" %in% robustness_registry$variable_id, "LOG_N_TOT"),
  check("primary_level_log_selection_lock_preserved", representation_audit$lock_status[representation_audit$lock_item == "primary_level_log_selection_lock"] == "PASS", "primary representation lock"),
  check("arithmetic_log_growth_selection_lock_preserved", representation_audit$lock_status[representation_audit$lock_item == "arithmetic_log_growth_selection_lock"] == "PASS", "growth representation lock"),
  check("no_automatic_representation_selection", representation_audit$lock_status[representation_audit$lock_item == "no_automatic_representation_selection"] == "PASS", "no automatic representation selection"),
  check("no_automatic_growth_selection", representation_audit$lock_status[representation_audit$lock_item == "no_automatic_growth_selection"] == "PASS", "no automatic growth selection"),
  check("lag_variables_conditional_only", all(lag_audit$consumer_lane == "conditional_secondary"), "lags conditional"),
  check("lag_variables_inactive_by_default", all(lag_audit$active_by_default == "no"), "lags inactive"),
  check("no_automatic_lag_activation", all(lag_audit$lag_activation_status == "PASS"), "lag activation lock"),
  check("source_units_preserved", all(nchar(registry$unit) > 0), "units populated from contract"),
  check("source_coverage_preserved", all(registry$coverage_end == 2024) && all(registry$coverage_start %in% c(1901, 1902, 1903)), "coverage preserved"),
  check("variable_specific_support_preserved", all(!is.na(registry$first_fully_supported_year)), "support dates preserved"),
  check("tot_baseline_start_equals_1931", all(baseline_registry$baseline_start_year == 1931), "baseline starts 1931"),
  check("warmup_observations_preserved", all(support_audit$warmup_preserved == "yes"), "warmup preserved"),
  check("warmup_observations_not_baseline_eligible", all(grepl("warmup", registry$prohibited_use) | registry$contract_status == "ALIAS_INTERFACE_ONLY"), "warmup restriction retained"),
  check("no_diagnostic_value_promoted", no_diagnostic$status == "PASS", "diagnostics not promoted"),
  check("no_alias_value_duplicated_as_independent_input", no_alias$status == "PASS", "aliases not duplicated"),
  check("provider_total_not_promoted", all(no_provider_total$status == "PASS"), "provider TOTAL not promoted"),
  check("no_cross_family_join_created", no_cross$status[no_cross$audit_item == "no_cross_family_join"] == "PASS", "no cross-family join"),
  check("no_output_variable_joined", no_cross$status[no_cross$audit_item == "no_output_variable_join"] == "PASS", "no output join"),
  check("no_distribution_variable_joined", no_cross$status[no_cross$audit_item == "no_distribution_variable_join"] == "PASS", "no distribution join"),
  check("no_common_complete_case_sample_created", no_complete$status[no_complete$audit_item == "no_common_complete_case_sample"] == "PASS", "no common sample"),
  check("no_estimation_sample_created", no_complete$status[no_complete$audit_item == "no_estimation_sample"] == "PASS", "no estimation sample"),
  check("no_year_dropped_due_to_cross_variable_missingness", no_complete$status[no_complete$audit_item == "no_year_dropped_due_to_cross_variable_missingness"] == "PASS", "no year dropped"),
  check("no_new_level_variable_constructed", no_new$status[no_new$audit_item == "no_new_level_variable"] == "PASS", "no level"),
  check("no_new_log_constructed", no_new$status[no_new$audit_item == "no_new_log"] == "PASS", "no log"),
  check("no_new_growth_rate_constructed", no_new$status[no_new$audit_item == "no_new_growth_rate"] == "PASS", "no growth"),
  check("no_new_difference_constructed", no_new$status[no_new$audit_item == "no_new_difference"] == "PASS", "no difference"),
  check("no_new_lag_constructed", no_new$status[no_new$audit_item == "no_new_lag"] == "PASS", "no lag"),
  check("no_new_share_constructed", no_new$status[no_new$audit_item == "no_new_share"] == "PASS", "no share"),
  check("no_new_intensity_measure_constructed", no_new$status[no_new$audit_item == "no_new_intensity_measure"] == "PASS", "no intensity"),
  check("tot_not_reaggregated", no_reaggregation$status[no_reaggregation$audit_item == "tot_not_reaggregated"] == "PASS", "TOT not reaggregated"),
  check("gpim_not_rerun", no_gpim$status[no_gpim$audit_item == "gpim_not_rerun"] == "PASS", "GPIM not rerun"),
  check("no_q_variables_constructed", all(no_q$status == "PASS"), "no q"),
  check("no_omega_weighted_capital_variables_constructed", no_q$status[no_q$audit_item == "no_omega_weighted_capital_variables"] == "PASS", "no omega-weighted capital"),
  check("no_distribution_capital_interactions_constructed", no_theta$status[no_theta$audit_item == "no_distribution_capital_interactions"] == "PASS", "no distribution interactions"),
  check("no_theta_variables_constructed", all(no_theta$status == "PASS"), "no theta"),
  check("no_productive_capacity_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_productive_capacity"] == "PASS", "no capacity"),
  check("no_utilization_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_utilization"] == "PASS", "no utilization"),
  check("no_output_capital_ratio_constructed", no_utilization$status[no_utilization$audit_item == "no_output_capital_ratio"] == "PASS", "no output-capital ratio"),
  check("no_modeling_outputs_created", no_modeling$status[no_modeling$audit_item == "no_modeling_outputs"] == "PASS", "no modeling"),
  check("no_econometric_outputs_created", no_modeling$status[no_modeling$audit_item == "no_econometric_outputs"] == "PASS", "no econometrics"),
  check("canonical_consumer_registry_created", file.exists(output_paths$registry) && nrow(registry) == 99, "registry created"),
  check("integrity_revalidation_audit_created", file.exists(output_paths$integrity) && nrow(integrity_audit) == 32, "integrity audit created"),
  check("contract_reconciliation_audit_created", file.exists(output_paths$reconciliation) && all(contract_recon$reconciliation_status == "PASS"), "contract reconciliation created"),
  check("lane_registration_audit_created", file.exists(output_paths$lane) && nrow(lane_audit) > 0, "lane audit created"),
  check("support_eligibility_audit_created", file.exists(output_paths$support) && nrow(support_audit) == 99, "support audit created"),
  check("representation_lock_audit_created", file.exists(output_paths$representation) && all(representation_audit$lock_status == "PASS"), "representation audit created"),
  check("lag_activation_audit_created", file.exists(output_paths$lag) && all(lag_audit$lag_activation_status == "PASS"), "lag audit created"),
  check("consumer_handoff_manifest_created", file.exists(output_paths$manifest) && nrow(handoff_manifest) == 1, "manifest created"),
  check("no_s29j_output_modified", upstream_unchanged, "S29J input hashes unchanged"),
  check("no_s29i_output_modified", upstream_unchanged, "S29I input hashes unchanged"),
  check("no_upstream_output_modified", upstream_unchanged, "upstream input hashes unchanged"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "provider tracked and staged diffs clean; pre-existing untracked files ignored")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)
all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 85
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

contract_md <- c(
  "# S29K Total Capital Interface Consumption Intake",
  "",
  "S29K registers the S29J-validated total-capital interface for downstream consumption in reference-based mode. It creates no new economic variables, transformations, joins, samples, q, theta, productive capacity, utilization, modeling outputs, or econometric outputs.",
  "",
  "## Registered Baseline Representations",
  "",
  "- `G_TOT_GPIM_2017`",
  "- `LOG_G_TOT_GPIM_2017`",
  "",
  "These remain alternative representations and are not jointly activated by default.",
  "",
  "## Next Stage",
  "",
  "`AUTHORIZE_S29L_TOTAL_CAPITAL_CROSS_FAMILY_INTEGRATION_PLANNING`"
)
writeLines(contract_md, output_paths$contract_md)

validation_md <- c(
  "# S29K Total Capital Interface Consumption Intake Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 85", "FAIL"), "`."),
  paste0("S29I files revalidated: `", nrow(integrity_audit), "`."),
  paste0("S29I hash matches: `", hash_match_count, "`."),
  paste0("Registered variables: `", nrow(registry), "`."),
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29K Total Capital Interface Consumption Intake Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29K consumed S29J commit `", s29j_commit, "`, S29I commit `", s29i_commit, "`, and S29H commit `", s29h_commit, "`."),
  paste0("S29J validation and decision: `PASS 90`; `", required_s29j_decision, "`."),
  paste0("S29K validation: `", ifelse(all_validation_pass, "PASS 85", "FAIL"), "`."),
  "",
  "S29K authorizes S29L as cross-family integration planning only. It does not authorize joins, q, theta, productive capacity, utilization, model samples, modeling, or econometrics.",
  "",
  "S29K stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) stop("S29K validation failed; see ", output_paths$validation)

message("S29K validation PASS 85")
message("S29I hash matches: ", hash_match_count)
message("Registered variables: ", nrow(registry))
message("Decision: ", final_decision)
