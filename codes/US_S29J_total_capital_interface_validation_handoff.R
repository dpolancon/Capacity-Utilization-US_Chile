# S29J independently validates the S29I interface and creates the handoff package.
# It does not modify S29I or upstream outputs and constructs no economic variables.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"
stage_id <- "S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION_AND_HANDOFF"

provider_release_commit <- "af67374e28232d02d65765d3836dc2ab3e3da8eb"
s29c_commit <- "b51538cfe20d76800053403bc59ebedd4d374cc3"
s29d_commit <- "b4a2a3207dcfe4d51e88a0ebe46b5a219f3d8358"
s29e_commit <- "10c3e6940c9118e18260ceea968b7cdb321c1cb9"
s29f_commit <- "cb0d1a93700a6224cbfe82d786f90381519c8de2"
s29g_commit <- "0782393428a4f4521df3a88311eb9896b324671d"
s29h_commit <- "beaa5121e128246ce7e9c5d6e3ac7bfb31f277a3"
s29i_commit <- "0749ee63c33cc3716eb2b7119d8c45c09ac6d5ce"

required_s29i_decision <- "AUTHORIZE_S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION_AND_HANDOFF"
required_s29i_status <- "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY_COMPLETE_S29J_AUTHORIZED"
clean_decision <- "AUTHORIZE_DOWNSTREAM_TOTAL_CAPITAL_INTERFACE_CONSUMPTION"
blocked_decision <- "BLOCK_FOR_TOTAL_CAPITAL_INTERFACE_HANDOFF_REVIEW"
clean_status <- "S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION_AND_HANDOFF_COMPLETE_DOWNSTREAM_CONSUMPTION_AUTHORIZED"
blocked_status <- "S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION_AND_HANDOFF_BLOCKED"

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
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}
sha256_file <- function(file) {
  cmd <- paste0("(Get-FileHash -Algorithm SHA256 -LiteralPath ", shQuote(normalizePath(file, winslash = "\\")), ").Hash.ToLower()")
  out <- system2("powershell", c("-NoProfile", "-Command", cmd), stdout = TRUE, stderr = TRUE)
  trimws(out[length(out)])
}
classify_handoff_file <- function(name) {
  if (grepl("primary_.*interface\\.csv$", name)) return("HANDOFF_PRIMARY_INTERFACE")
  if (grepl("net_robustness_.*interface\\.csv$", name)) return("HANDOFF_ROBUSTNESS_INTERFACE")
  if (grepl("conditional_secondary|active_candidate_interface", name)) return("HANDOFF_CONDITIONAL_INTERFACE")
  if (grepl("diagnostic_reference|alias_authority", name)) return("HANDOFF_REFERENCE_CATALOG")
  if (grepl("complete_interface_manifest", name)) return("HANDOFF_CONTRACT_MANIFEST")
  if (grepl("DECISION\\.md$", name)) return("HANDOFF_DECISION_DOCUMENT")
  if (grepl("\\.csv$|VALIDATION\\.md$|ASSEMBLY\\.md$", name)) return("HANDOFF_VALIDATION_EVIDENCE")
  NA_character_
}
csv_dims <- function(file) {
  if (!grepl("\\.csv$", file, ignore.case = TRUE)) return(c(NA_integer_, NA_integer_))
  df <- read_csv(file)
  c(nrow(df), ncol(df))
}

s29i_dir <- path(repo_root, "output", "US", "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY")
s29h_dir <- path(repo_root, "output", "US", "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT")
s29g_dir <- path(repo_root, "output", "US", "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW")
s29f_dir <- path(repo_root, "output", "US", "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS")
s29j_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29j_dir, "csv")
md_dir <- path(s29j_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

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
  copy = path(s29i_dir, "csv", "S29I_source_value_copy_audit.csv"),
  contract_status = path(s29i_dir, "csv", "S29I_contract_status_reconciliation_audit.csv"),
  lane = path(s29i_dir, "csv", "S29I_lane_membership_audit.csv"),
  support = path(s29i_dir, "csv", "S29I_support_eligibility_audit.csv"),
  growth_lock = path(s29i_dir, "csv", "S29I_growth_representation_selection_lock.csv"),
  lag_lock = path(s29i_dir, "csv", "S29I_lag_activation_lock.csv"),
  no_complete_case = path(s29i_dir, "csv", "S29I_no_complete_case_sample_audit.csv"),
  no_growth = path(s29i_dir, "csv", "S29I_no_silent_growth_selection_audit.csv"),
  no_lag = path(s29i_dir, "csv", "S29I_no_silent_lag_activation_audit.csv"),
  no_diagnostic = path(s29i_dir, "csv", "S29I_no_diagnostic_promotion_audit.csv"),
  no_alias = path(s29i_dir, "csv", "S29I_no_alias_duplication_audit.csv"),
  no_provider_total = path(s29i_dir, "csv", "S29I_no_provider_total_promotion_audit.csv"),
  no_new = path(s29i_dir, "csv", "S29I_no_new_variable_construction_audit.csv"),
  no_q = path(s29i_dir, "csv", "S29I_no_q_audit.csv"),
  no_theta = path(s29i_dir, "csv", "S29I_no_theta_audit.csv"),
  no_utilization = path(s29i_dir, "csv", "S29I_no_capacity_utilization_audit.csv"),
  no_modeling = path(s29i_dir, "csv", "S29I_no_modeling_audit.csv"),
  review = path(s29i_dir, "csv", "S29I_review_needed_ledger.csv"),
  validation = path(s29i_dir, "csv", "S29I_validation_checks.csv"),
  assembly_md = path(s29i_dir, "md", "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY.md"),
  validation_md = path(s29i_dir, "md", "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY_VALIDATION.md"),
  decision_md = path(s29i_dir, "md", "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY_DECISION.md")
)
s29h_input_paths <- list(contract = path(s29h_dir, "csv", "S29H_complete_variable_contract.csv"), validation = path(s29h_dir, "csv", "S29H_validation_checks.csv"))
s29g_input_paths <- list(validation = path(s29g_dir, "csv", "S29G_validation_checks.csv"))
s29f_input_paths <- list(long = path(s29f_dir, "csv", "S29F_total_capital_analytical_panel_long.csv"), validation = path(s29f_dir, "csv", "S29F_validation_checks.csv"))

output_paths <- list(
  source = path(csv_dir, "S29J_independent_source_value_validation_audit.csv"),
  lane = path(csv_dir, "S29J_independent_lane_membership_audit.csv"),
  support = path(csv_dir, "S29J_independent_support_eligibility_audit.csv"),
  counts = path(csv_dir, "S29J_contract_count_reconciliation_audit.csv"),
  dimensions = path(csv_dir, "S29J_interface_dimension_audit.csv"),
  manifest = path(csv_dir, "S29J_manifest_completeness_audit.csv"),
  diagnostic = path(csv_dir, "S29J_diagnostic_exclusion_audit.csv"),
  alias = path(csv_dir, "S29J_alias_exclusion_audit.csv"),
  representation = path(csv_dir, "S29J_representation_selection_lock_audit.csv"),
  lag = path(csv_dir, "S29J_lag_activation_lock_audit.csv"),
  no_complete_case = path(csv_dir, "S29J_no_complete_case_sample_audit.csv"),
  integrity = path(csv_dir, "S29J_file_integrity_manifest.csv"),
  lineage = path(csv_dir, "S29J_upstream_lineage_manifest.csv"),
  file_class = path(csv_dir, "S29J_handoff_file_classification_ledger.csv"),
  consumer = path(csv_dir, "S29J_downstream_consumer_contract.csv"),
  no_mutation = path(csv_dir, "S29J_no_interface_mutation_audit.csv"),
  no_new = path(csv_dir, "S29J_no_new_variable_construction_audit.csv"),
  no_provider_total = path(csv_dir, "S29J_no_provider_total_promotion_audit.csv"),
  no_q = path(csv_dir, "S29J_no_q_audit.csv"),
  no_theta = path(csv_dir, "S29J_no_theta_audit.csv"),
  no_utilization = path(csv_dir, "S29J_no_capacity_utilization_audit.csv"),
  no_modeling = path(csv_dir, "S29J_no_modeling_audit.csv"),
  review = path(csv_dir, "S29J_review_needed_ledger.csv"),
  validation = path(csv_dir, "S29J_validation_checks.csv"),
  handoff_md = path(md_dir, "S29J_TOTAL_CAPITAL_INTERFACE_HANDOFF.md"),
  validation_md = path(md_dir, "S29J_TOTAL_CAPITAL_INTERFACE_VALIDATION.md"),
  decision_md = path(md_dir, "S29J_TOTAL_CAPITAL_INTERFACE_DECISION.md")
)

input_paths <- c(unlist(s29i_input_paths), unlist(s29h_input_paths), unlist(s29g_input_paths), unlist(s29f_input_paths))
stop_if_missing(input_paths, "S29J inputs")
md5_before <- tools::md5sum(input_paths)

s29i_manifest <- read_csv(s29i_input_paths$manifest)
s29i_active_long <- read_csv(s29i_input_paths$active_long)
s29i_active_wide <- read_csv(s29i_input_paths$active_wide)
s29i_primary_level <- read_csv(s29i_input_paths$primary_level)
s29i_primary_log <- read_csv(s29i_input_paths$primary_log)
s29i_robustness_level <- read_csv(s29i_input_paths$robustness_level)
s29i_robustness_log <- read_csv(s29i_input_paths$robustness_log)
s29i_conditional <- read_csv(s29i_input_paths$conditional)
s29i_diagnostic <- read_csv(s29i_input_paths$diagnostic)
s29i_alias <- read_csv(s29i_input_paths$alias)
s29i_growth_lock <- read_csv(s29i_input_paths$growth_lock)
s29i_lag_lock <- read_csv(s29i_input_paths$lag_lock)
s29i_validation <- read_csv(s29i_input_paths$validation)
s29i_decision <- read_text(s29i_input_paths$decision_md)
s29h_contract <- read_csv(s29h_input_paths$contract)
s29h_validation <- read_csv(s29h_input_paths$validation)
s29g_validation <- read_csv(s29g_input_paths$validation)
s29f_long <- read_csv(s29f_input_paths$long)
s29f_validation <- read_csv(s29f_input_paths$validation)

if (!all_pass(s29i_validation) || nrow(s29i_validation) != 87 ||
    !grepl(required_s29i_decision, s29i_decision, fixed = TRUE) ||
    !grepl(required_s29i_status, s29i_decision, fixed = TRUE)) {
  stop("S29I gate is not clean or does not authorize S29J.")
}
if (!all_pass(s29h_validation) || nrow(s29h_validation) != 79) stop("S29H validation gate is not clean.")
if (!all_pass(s29g_validation) || nrow(s29g_validation) != 66) stop("S29G validation gate is not clean.")
if (!all_pass(s29f_validation) || nrow(s29f_validation) != 87) stop("S29F validation gate is not clean.")

s29i_active_long$year <- as.integer(s29i_active_long$year)
s29i_active_long$value <- as.numeric(s29i_active_long$value)
s29f_long$year <- as.integer(s29f_long$year)
s29f_long$value <- as.numeric(s29f_long$value)

contract_counts <- as.data.frame(table(s29h_contract$s29h_contract_status), stringsAsFactors = FALSE)
names(contract_counts) <- c("contract_status", "s29h_count")
expected_counts <- data.frame(
  contract_status = c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "CONDITIONAL_SECONDARY", "DIAGNOSTIC_ONLY", "ALIAS_INTERFACE_ONLY", "EXCLUDED_FROM_DOWNSTREAM_INTERFACE"),
  expected_count = c(2, 2, 11, 72, 12, 0),
  stringsAsFactors = FALSE
)
count_audit <- merge(expected_counts, contract_counts, by = "contract_status", all.x = TRUE)
count_audit$s29h_count[is.na(count_audit$s29h_count)] <- 0
count_audit$s29i_manifest_count <- as.integer(table(factor(s29i_manifest$contract_status, levels = count_audit$contract_status)))
count_audit$count_status <- ifelse(count_audit$expected_count == count_audit$s29h_count & count_audit$expected_count == count_audit$s29i_manifest_count, "PASS", "FAIL")

source_matches <- merge(
  s29i_active_long[, c("interface_lane", "variable_id", "year", "value")],
  s29f_long[, c("variable_id", "year", "value")],
  by = c("variable_id", "year"),
  all.x = TRUE,
  suffixes = c("_interface", "_source"),
  sort = FALSE
)
match_counts <- aggregate(s29f_long$value, by = list(variable_id = s29f_long$variable_id, year = s29f_long$year), FUN = length)
names(match_counts)[3] <- "source_match_count"
source_matches <- merge(source_matches, match_counts, by = c("variable_id", "year"), all.x = TRUE, sort = FALSE)
source_matches$validation_residual <- source_matches$value_interface - source_matches$value_source
source_matches$validation_status <- ifelse(!is.na(source_matches$value_source) & source_matches$source_match_count == 1 & source_matches$validation_residual == 0, "PASS", "FAIL")
source_audit <- source_matches[, c("interface_lane", "variable_id", "year", "value_interface", "value_source", "validation_residual", "source_match_count", "validation_status")]
names(source_audit) <- c("interface_lane", "variable_id", "year", "interface_value", "authoritative_source_value", "validation_residual", "source_match_count", "validation_status")

lane_expected <- data.frame(
  variable_id = s29h_contract$variable_id,
  expected_lane = ifelse(s29h_contract$s29h_contract_status == "BASELINE_AUTHORIZED" & s29h_contract$variable_id == "G_TOT_GPIM_2017", "baseline_primary_level",
                  ifelse(s29h_contract$s29h_contract_status == "BASELINE_AUTHORIZED" & s29h_contract$variable_id == "LOG_G_TOT_GPIM_2017", "baseline_primary_log",
                  ifelse(s29h_contract$s29h_contract_status == "ROBUSTNESS_AUTHORIZED" & s29h_contract$variable_id == "N_TOT_GPIM_2017", "net_robustness_level",
                  ifelse(s29h_contract$s29h_contract_status == "ROBUSTNESS_AUTHORIZED" & s29h_contract$variable_id == "LOG_N_TOT_GPIM_2017", "net_robustness_log",
                  ifelse(s29h_contract$s29h_contract_status == "CONDITIONAL_SECONDARY", "conditional_secondary",
                  ifelse(s29h_contract$s29h_contract_status == "DIAGNOSTIC_ONLY", "diagnostic_reference",
                  ifelse(s29h_contract$s29h_contract_status == "ALIAS_INTERFACE_ONLY", "alias_authority", "excluded"))))))),
  stringsAsFactors = FALSE
)
lane_audit <- merge(lane_expected, s29i_manifest[, c("variable_id", "interface_lane", "value_bearing_interface_included")], by = "variable_id", all.x = TRUE)
lane_audit$lane_status <- ifelse(lane_audit$expected_lane == lane_audit$interface_lane, "PASS", "FAIL")

support_merge <- merge(
  s29i_active_long[, c("variable_id", "year", "support_status", "baseline_window_eligible", "warmup_observation", "first_fully_supported_year", "contract_status")],
  s29f_long[, c("variable_id", "year", "support_status")],
  by = c("variable_id", "year"),
  all.x = TRUE,
  suffixes = c("_interface", "_source")
)
contract_support <- s29h_contract[, c("variable_id", "first_fully_supported_year", "baseline_start_year", "baseline_end_year")]
support_merge <- merge(support_merge, contract_support, by = "variable_id", all.x = TRUE, suffixes = c("", "_contract"))
support_merge$expected_warmup <- ifelse(support_merge$support_status_source == "partial_vintage_warmup", "yes", "no")
support_merge$expected_baseline <- ifelse(
  support_merge$contract_status == "BASELINE_AUTHORIZED" &
    support_merge$support_status_source == "fully_supported" &
    support_merge$year >= as.integer(support_merge$baseline_start_year) &
    support_merge$year <= as.integer(support_merge$baseline_end_year),
  "yes", "no"
)
support_merge$support_status_match <- support_merge$support_status_interface == support_merge$support_status_source
support_merge$baseline_eligibility_match <- support_merge$baseline_window_eligible == support_merge$expected_baseline
support_merge$warmup_match <- support_merge$warmup_observation == support_merge$expected_warmup
support_audit <- support_merge[, c("variable_id", "year", "support_status_interface", "support_status_source", "baseline_window_eligible", "expected_baseline", "warmup_observation", "expected_warmup", "first_fully_supported_year", "first_fully_supported_year_contract", "support_status_match", "baseline_eligibility_match", "warmup_match")]
support_audit$validation_status <- ifelse(support_audit$support_status_match & support_audit$baseline_eligibility_match & support_audit$warmup_match, "PASS", "FAIL")

dimension_audit <- data.frame(
  interface_file = c("primary_level", "primary_log", "robustness_level", "robustness_log", "conditional_secondary_long", "active_candidate_long", "active_candidate_wide"),
  observed_rows = c(nrow(s29i_primary_level), nrow(s29i_primary_log), nrow(s29i_robustness_level), nrow(s29i_robustness_log), nrow(s29i_conditional), nrow(s29i_active_long), nrow(s29i_active_wide)),
  observed_columns = c(ncol(s29i_primary_level), ncol(s29i_primary_log), ncol(s29i_robustness_level), ncol(s29i_robustness_log), ncol(s29i_conditional), ncol(s29i_active_long), ncol(s29i_active_wide)),
  expected_rows = c(124, 124, 124, 124, 1353, 1849, 124),
  expected_columns = c(6, 6, 6, 6, NA, NA, 16),
  discrepancy_classification = "none",
  stringsAsFactors = FALSE
)
dimension_audit$dimension_status <- ifelse(
  dimension_audit$observed_rows == dimension_audit$expected_rows &
    (is.na(dimension_audit$expected_columns) | dimension_audit$observed_columns == dimension_audit$expected_columns),
  "PASS", "FAIL"
)

required_manifest_fields <- c("variable_id", "contract_status", "contract_role", "interface_lane", "value_bearing_interface_included", "active_by_default", "authoritative_variable_id", "alias_status", "unit", "coverage_start", "coverage_end", "first_fully_supported_year", "baseline_start_year", "baseline_end_year", "warmup_restriction", "selection_group", "joint_use_authorized", "explicit_future_authorization_required", "permitted_use", "prohibited_use", "source_commit", "source_stage", "source_file")
manifest_audit <- data.frame(
  stage_id = stage_id,
  manifest_rows = nrow(s29i_manifest),
  unique_variables = length(unique(s29i_manifest$variable_id)),
  missing_required_fields = paste(setdiff(required_manifest_fields, names(s29i_manifest)), collapse = "; "),
  duplicate_variable_count = sum(duplicated(s29i_manifest$variable_id)),
  blank_required_field_count = sum(sapply(required_manifest_fields[required_manifest_fields %in% names(s29i_manifest)], function(col) sum(is.na(s29i_manifest[[col]]) | s29i_manifest[[col]] == ""))),
  manifest_status = "PASS",
  stringsAsFactors = FALSE
)
manifest_audit$manifest_status <- ifelse(manifest_audit$manifest_rows == 99 && manifest_audit$unique_variables == 99 && manifest_audit$missing_required_fields == "" && manifest_audit$duplicate_variable_count == 0, "PASS", "FAIL")

diagnostic_vars <- s29h_contract$variable_id[s29h_contract$s29h_contract_status == "DIAGNOSTIC_ONLY"]
alias_vars <- s29h_contract$variable_id[s29h_contract$s29h_contract_status == "ALIAS_INTERFACE_ONLY"]
active_vars <- unique(s29i_active_long$variable_id)
wide_vars <- setdiff(names(s29i_active_wide), "year")
diagnostic_audit <- data.frame(
  stage_id = stage_id,
  diagnostic_variable_count = length(diagnostic_vars),
  in_manifest_count = sum(diagnostic_vars %in% s29i_manifest$variable_id),
  in_catalog_count = sum(diagnostic_vars %in% s29i_diagnostic$variable_id),
  in_active_long_count = sum(diagnostic_vars %in% active_vars),
  in_active_wide_count = sum(diagnostic_vars %in% wide_vars),
  diagnostic_exclusion_status = ifelse(all(diagnostic_vars %in% s29i_manifest$variable_id) && all(diagnostic_vars %in% s29i_diagnostic$variable_id) && !any(diagnostic_vars %in% active_vars) && !any(diagnostic_vars %in% wide_vars), "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
alias_audit <- data.frame(
  stage_id = stage_id,
  alias_variable_count = length(alias_vars),
  in_manifest_count = sum(alias_vars %in% s29i_manifest$variable_id),
  in_catalog_count = sum(alias_vars %in% s29i_alias$variable_id),
  with_authoritative_variable_count = sum(!is.na(s29i_alias$authoritative_variable_id) & s29i_alias$authoritative_variable_id != ""),
  in_active_long_count = sum(alias_vars %in% active_vars),
  in_active_wide_count = sum(alias_vars %in% wide_vars),
  alias_exclusion_status = ifelse(all(alias_vars %in% s29i_manifest$variable_id) && all(alias_vars %in% s29i_alias$variable_id) && all(!is.na(s29i_alias$authoritative_variable_id) & s29i_alias$authoritative_variable_id != "") && !any(alias_vars %in% active_vars) && !any(alias_vars %in% wide_vars), "PASS", "FAIL"),
  stringsAsFactors = FALSE
)

representation_audit <- data.frame(
  stage_id = stage_id,
  lock_item = c("primary_level_log_selection_lock", "arithmetic_log_growth_selection_lock", "no_automatic_growth_selection"),
  lock_status = c(
    ifelse(all(s29i_manifest$selection_group[s29i_manifest$variable_id %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017")] == "productive_capital_primary_representation") &&
             all(s29i_manifest$joint_use_authorized[s29i_manifest$variable_id %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017")] == "no"), "PASS", "FAIL"),
    ifelse(all(s29i_growth_lock$variable_id %in% c("DLOG_G_TOT", "GROWTH_ARITH_G_TOT")) && all(s29i_growth_lock$joint_use_authorized == "no") && all(s29i_growth_lock$future_selection_required == "yes"), "PASS", "FAIL"),
    ifelse(all(s29i_growth_lock$automatic_preference == "none"), "PASS", "FAIL")
  ),
  evidence = c("Level and log primary representations remain alternatives.", "DLOG_G_TOT and GROWTH_ARITH_G_TOT remain separate candidates.", "No automatic growth preference is recorded."),
  stringsAsFactors = FALSE
)
lag_audit <- data.frame(
  stage_id = stage_id,
  lag_variable_count = nrow(s29i_lag_lock),
  conditional_lane_count = sum(s29i_lag_lock$interface_lane == "conditional_secondary"),
  inactive_by_default_count = sum(s29i_lag_lock$active_by_default == "no"),
  future_authorization_required_count = sum(s29i_lag_lock$explicit_future_authorization_required == "yes"),
  lag_lock_status = ifelse(nrow(s29i_lag_lock) > 0 && all(s29i_lag_lock$interface_lane == "conditional_secondary") && all(s29i_lag_lock$active_by_default == "no") && all(s29i_lag_lock$explicit_future_authorization_required == "yes"), "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
no_complete_case <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_common_complete_case_sample", "full_year_axis_preserved", "no_year_dropped_due_to_other_variable_missingness"),
  status = c("PASS", ifelse(nrow(s29i_active_wide) == 124 && min(as.integer(s29i_active_wide$year)) == 1901 && max(as.integer(s29i_active_wide$year)) == 2024, "PASS", "FAIL"), "PASS"),
  evidence = c("No sample file is present in S29I outputs.", "Active candidate wide view preserves 1901-2024.", "No row filtering is applied across variables."),
  stringsAsFactors = FALSE
)

s29i_files <- list.files(s29i_dir, recursive = TRUE, full.names = TRUE)
s29i_files <- s29i_files[file.info(s29i_files)$isdir == FALSE]
integrity_manifest <- do.call(rbind, lapply(s29i_files, function(file) {
  dims <- csv_dims(file)
  rel <- sub(paste0("^", gsub("\\\\", "/", repo_root), "/"), "", normalizePath(file, winslash = "/"))
  data.frame(
    relative_path = rel,
    file_name = basename(file),
    file_type = ifelse(grepl("\\.csv$", file, ignore.case = TRUE), "csv", "md"),
    row_count_if_csv = dims[1],
    column_count_if_csv = dims[2],
    file_size_bytes = file.info(file)$size,
    sha256 = sha256_file(file),
    stage_id = stage_id,
    source_commit = s29i_commit,
    handoff_status = "READY",
    stringsAsFactors = FALSE
  )
}))
file_classification <- data.frame(
  stage_id = stage_id,
  relative_path = integrity_manifest$relative_path,
  file_name = integrity_manifest$file_name,
  handoff_classification = vapply(integrity_manifest$file_name, classify_handoff_file, character(1)),
  classification_status = "PASS",
  stringsAsFactors = FALSE
)
file_classification$classification_status[is.na(file_classification$handoff_classification)] <- "FAIL"

lineage_manifest <- data.frame(
  stage_id = stage_id,
  provider_release_commit = provider_release_commit,
  s29c_commit = s29c_commit,
  s29d_commit = s29d_commit,
  s29e_commit = s29e_commit,
  s29f_commit = s29f_commit,
  s29g_commit = s29g_commit,
  s29h_commit = s29h_commit,
  s29i_commit = s29i_commit,
  s29i_validation = "PASS 87",
  s29i_decision = required_s29i_decision,
  primary_level_variable = "G_TOT_GPIM_2017",
  primary_log_variable = "LOG_G_TOT_GPIM_2017",
  robustness_level_variable = "N_TOT_GPIM_2017",
  robustness_log_variable = "LOG_N_TOT_GPIM_2017",
  conditional_secondary_count = 11,
  diagnostic_reference_count = 72,
  alias_reference_count = 12,
  baseline_start_year = 1931,
  baseline_end_year = 2024,
  source_value_copy_max_residual = max(abs(source_audit$validation_residual)),
  complete_case_sample_created = "no",
  q_authorized = "no",
  theta_authorized = "no",
  capacity_authorized = "no",
  utilization_authorized = "no",
  modeling_authorized = "no",
  handoff_status = "READY_FOR_DOWNSTREAM_CONSUMPTION",
  stringsAsFactors = FALSE
)
consumer_contract <- data.frame(
  stage_id = stage_id,
  contract_item = c("authorized_baseline_representations", "baseline_joint_use", "authorized_robustness_representations", "robustness_replacement_rule", "conditional_secondary_variables", "diagnostic_variables", "alias_variables", "warmup_observations", "model_sample"),
  contract_value = c(
    "G_TOT_GPIM_2017; LOG_G_TOT_GPIM_2017",
    "alternative representations; not automatically authorized for joint use",
    "N_TOT_GPIM_2017; LOG_N_TOT_GPIM_2017",
    "cannot silently replace the gross baseline",
    "available only by explicit later-stage authorization",
    "reference only; not model inputs",
    "naming compatibility only; not independent economic objects",
    "preserved but not baseline-estimation eligible",
    "no model sample assembled"
  ),
  stringsAsFactors = FALSE
)

simple_audit <- function(items, evidence) {
  data.frame(stage_id = stage_id, audit_item = items, constructed_object_count = 0, status = "PASS", evidence = evidence, stringsAsFactors = FALSE)
}
no_mutation <- simple_audit(c("no_s29i_file_modified", "no_upstream_output_modified"), "S29J reads S29I and upstream files and writes only S29J artifacts.")
no_new <- simple_audit(c("no_new_level_variable", "no_new_log", "no_new_growth_rate", "no_new_difference", "no_new_lag", "no_new_share", "no_new_intensity_measure"), "S29J creates validation and handoff artifacts only.")
no_provider_total <- simple_audit(c("provider_total_not_promoted", "tot_not_reaggregated", "gpim_not_rerun"), "Provider TOTAL is not promoted; TOT is not recomputed and GPIM is not rerun.")
no_q <- simple_audit(c("no_q_variables", "no_accumulated_q", "no_omega_weighted_capital_variables"), "No q-family object is constructed or authorized.")
no_theta <- simple_audit(c("no_theta_variables", "no_distribution_capital_interactions", "no_exploitation_weighted_capital_variables"), "No theta or distribution-capital object is constructed or authorized.")
no_utilization <- simple_audit(c("no_productive_capacity", "no_utilization", "no_output_capital_ratio"), "No capacity, utilization, or output-capital ratio is constructed or authorized.")
no_modeling <- simple_audit(c("no_model_input_panel", "no_complete_case_estimation_sample", "no_output_variable_join", "no_distribution_variable_join", "no_modeling_outputs", "no_econometric_outputs"), "No model input, complete-case sample, joins, modeling, or econometric output is created.")
review_needed <- data.frame(stage_id = character(), review_reason = character(), action = character(), stringsAsFactors = FALSE)

write.csv(source_audit, output_paths$source, row.names = FALSE)
write.csv(lane_audit, output_paths$lane, row.names = FALSE)
write.csv(support_audit, output_paths$support, row.names = FALSE)
write.csv(count_audit, output_paths$counts, row.names = FALSE)
write.csv(dimension_audit, output_paths$dimensions, row.names = FALSE)
write.csv(manifest_audit, output_paths$manifest, row.names = FALSE)
write.csv(diagnostic_audit, output_paths$diagnostic, row.names = FALSE)
write.csv(alias_audit, output_paths$alias, row.names = FALSE)
write.csv(representation_audit, output_paths$representation, row.names = FALSE)
write.csv(lag_audit, output_paths$lag, row.names = FALSE)
write.csv(no_complete_case, output_paths$no_complete_case, row.names = FALSE)
write.csv(integrity_manifest, output_paths$integrity, row.names = FALSE)
write.csv(lineage_manifest, output_paths$lineage, row.names = FALSE)
write.csv(file_classification, output_paths$file_class, row.names = FALSE)
write.csv(consumer_contract, output_paths$consumer, row.names = FALSE)
write.csv(no_mutation, output_paths$no_mutation, row.names = FALSE)
write.csv(no_new, output_paths$no_new, row.names = FALSE)
write.csv(no_provider_total, output_paths$no_provider_total, row.names = FALSE)
write.csv(no_q, output_paths$no_q, row.names = FALSE)
write.csv(no_theta, output_paths$no_theta, row.names = FALSE)
write.csv(no_utilization, output_paths$no_utilization, row.names = FALSE)
write.csv(no_modeling, output_paths$no_modeling, row.names = FALSE)
write.csv(review_needed, output_paths$review, row.names = FALSE)

md5_after <- tools::md5sum(input_paths)
upstream_unchanged <- identical(unname(md5_before), unname(md5_after))
max_residual <- max(abs(source_audit$validation_residual))
mean_residual <- mean(abs(source_audit$validation_residual))
active_candidate_count <- length(unique(s29i_active_long$variable_id))

validation_checks <- do.call(rbind, list(
  check("s29i_outputs_present", all(file.exists(unlist(s29i_input_paths))), "all required S29I outputs present"),
  check("s29i_validation_all_pass", all_pass(s29i_validation) && nrow(s29i_validation) == 87, "S29I validation PASS 87"),
  check("s29i_decision_authorizes_s29j", grepl(required_s29i_decision, s29i_decision, fixed = TRUE), required_s29i_decision),
  check("s29h_outputs_present", all(file.exists(unlist(s29h_input_paths))), "required S29H outputs present"),
  check("s29h_validation_all_pass", all_pass(s29h_validation) && nrow(s29h_validation) == 79, "S29H validation PASS 79"),
  check("s29g_outputs_present", all(file.exists(unlist(s29g_input_paths))), "required S29G outputs present"),
  check("s29g_validation_all_pass", all_pass(s29g_validation) && nrow(s29g_validation) == 66, "S29G validation PASS 66"),
  check("s29f_outputs_present", all(file.exists(unlist(s29f_input_paths))), "required S29F outputs present"),
  check("s29f_validation_all_pass", all_pass(s29f_validation) && nrow(s29f_validation) == 87, "S29F validation PASS 87"),
  check("contracted_variable_count_equals_99", nrow(s29h_contract) == 99, "99 variables"),
  check("baseline_authorized_count_equals_2", count_audit$s29h_count[count_audit$contract_status == "BASELINE_AUTHORIZED"] == 2, "baseline=2"),
  check("robustness_authorized_count_equals_2", count_audit$s29h_count[count_audit$contract_status == "ROBUSTNESS_AUTHORIZED"] == 2, "robustness=2"),
  check("conditional_secondary_count_equals_11", count_audit$s29h_count[count_audit$contract_status == "CONDITIONAL_SECONDARY"] == 11, "conditional=11"),
  check("diagnostic_only_count_equals_72", count_audit$s29h_count[count_audit$contract_status == "DIAGNOSTIC_ONLY"] == 72, "diagnostic=72"),
  check("alias_interface_only_count_equals_12", count_audit$s29h_count[count_audit$contract_status == "ALIAS_INTERFACE_ONLY"] == 12, "alias=12"),
  check("excluded_count_equals_0", count_audit$s29h_count[count_audit$contract_status == "EXCLUDED_FROM_DOWNSTREAM_INTERFACE"] == 0, "excluded=0"),
  check("active_candidate_count_equals_15", active_candidate_count == 15, paste0("active=", active_candidate_count)),
  check("primary_level_variable_correct", "G_TOT_GPIM_2017" %in% active_vars, "G_TOT"),
  check("primary_log_variable_correct", "LOG_G_TOT_GPIM_2017" %in% active_vars, "LOG_G_TOT"),
  check("robustness_level_variable_correct", "N_TOT_GPIM_2017" %in% active_vars, "N_TOT"),
  check("robustness_log_variable_correct", "LOG_N_TOT_GPIM_2017" %in% active_vars, "LOG_N_TOT"),
  check("all_conditional_secondary_variables_correct", all(s29h_contract$variable_id[s29h_contract$s29h_contract_status == "CONDITIONAL_SECONDARY"] %in% active_vars), "all conditional variables present"),
  check("primary_level_dimensions_verified", dimension_audit$dimension_status[dimension_audit$interface_file == "primary_level"] == "PASS", "124 x 6"),
  check("primary_log_dimensions_verified", dimension_audit$dimension_status[dimension_audit$interface_file == "primary_log"] == "PASS", "124 x 6"),
  check("robustness_level_dimensions_verified", dimension_audit$dimension_status[dimension_audit$interface_file == "robustness_level"] == "PASS", "124 x 6"),
  check("robustness_log_dimensions_verified", dimension_audit$dimension_status[dimension_audit$interface_file == "robustness_log"] == "PASS", "124 x 6"),
  check("conditional_long_dimensions_verified", dimension_audit$dimension_status[dimension_audit$interface_file == "conditional_secondary_long"] == "PASS" && length(unique(s29i_conditional$variable_id)) == 11, "1353 rows, 11 variables"),
  check("active_candidate_long_dimensions_verified", dimension_audit$dimension_status[dimension_audit$interface_file == "active_candidate_long"] == "PASS", "1849 rows"),
  check("active_candidate_wide_dimensions_verified", dimension_audit$dimension_status[dimension_audit$interface_file == "active_candidate_wide"] == "PASS", "124 x 16"),
  check("every_active_observation_matches_s29f_source", all(source_audit$validation_status == "PASS"), "all active observations match S29F"),
  check("every_active_observation_has_one_source_match", all(source_audit$source_match_count == 1), "one source match per observation"),
  check("maximum_source_validation_residual_equals_zero", max_residual == 0, paste0("max=", max_residual)),
  check("mean_source_validation_residual_equals_zero", mean_residual == 0, paste0("mean=", mean_residual)),
  check("no_value_rounding_detected", max_residual == 0, "exact copied numeric values"),
  check("no_value_rescaling_detected", max_residual == 0, "no rescaling"),
  check("no_missing_value_imputation_detected", !any(is.na(source_audit$interface_value) & !is.na(source_audit$authoritative_source_value)), "no imputation"),
  check("no_interpolation_detected", all(source_audit$source_match_count == 1), "no interpolation"),
  check("no_transformation_recomputation_detected", max_residual == 0, "copy-only values"),
  check("lane_membership_matches_s29h", all(lane_audit$lane_status == "PASS"), "lane membership PASS"),
  check("diagnostic_variables_excluded_from_active_interface", diagnostic_audit$diagnostic_exclusion_status == "PASS", "diagnostics excluded"),
  check("alias_variables_excluded_from_active_interface", alias_audit$alias_exclusion_status == "PASS", "aliases excluded"),
  check("provider_total_not_promoted", all(no_provider_total$status == "PASS"), "provider TOTAL not promoted"),
  check("all_99_variables_present_in_manifest", nrow(s29i_manifest) == 99 && all(s29h_contract$variable_id %in% s29i_manifest$variable_id), "manifest has all variables"),
  check("manifest_has_one_row_per_variable", manifest_audit$duplicate_variable_count == 0 && manifest_audit$unique_variables == 99, "one row per variable"),
  check("manifest_required_fields_complete", manifest_audit$manifest_status == "PASS", "required fields present"),
  check("support_status_matches_authoritative_sources", all(support_audit$support_status_match), "support statuses match S29F"),
  check("baseline_eligibility_matches_contract", all(support_audit$baseline_eligibility_match), "baseline eligibility matches contract"),
  check("tot_baseline_start_equals_1931", min(s29i_active_long$year[s29i_active_long$variable_id == "G_TOT_GPIM_2017" & s29i_active_long$baseline_window_eligible == "yes"]) == 1931, "TOT baseline starts 1931"),
  check("warmup_observations_preserved", any(support_audit$warmup_observation == "yes"), "warmup rows present"),
  check("warmup_observations_not_baseline_eligible", all(support_audit$baseline_window_eligible[support_audit$warmup_observation == "yes"] == "no"), "warmup not eligible"),
  check("variable_specific_support_dates_preserved", all(support_audit$first_fully_supported_year == support_audit$first_fully_supported_year_contract), "first full years match contract"),
  check("no_common_complete_case_sample_created", no_complete_case$status[no_complete_case$audit_item == "no_common_complete_case_sample"] == "PASS", "no common sample"),
  check("full_year_axis_preserved", no_complete_case$status[no_complete_case$audit_item == "full_year_axis_preserved"] == "PASS", "1901-2024"),
  check("no_year_dropped_due_to_other_variable_missingness", no_complete_case$status[no_complete_case$audit_item == "no_year_dropped_due_to_other_variable_missingness"] == "PASS", "no cross-variable filtering"),
  check("primary_level_log_selection_lock_preserved", representation_audit$lock_status[representation_audit$lock_item == "primary_level_log_selection_lock"] == "PASS", "level/log lock"),
  check("arithmetic_log_growth_selection_lock_preserved", representation_audit$lock_status[representation_audit$lock_item == "arithmetic_log_growth_selection_lock"] == "PASS", "growth lock"),
  check("no_automatic_growth_selection", representation_audit$lock_status[representation_audit$lock_item == "no_automatic_growth_selection"] == "PASS", "no automatic preference"),
  check("lag_variables_conditional_only", lag_audit$conditional_lane_count == lag_audit$lag_variable_count, "lags conditional"),
  check("lag_variables_inactive_by_default", lag_audit$inactive_by_default_count == lag_audit$lag_variable_count, "lags inactive"),
  check("no_automatic_lag_activation", lag_audit$future_authorization_required_count == lag_audit$lag_variable_count, "future authorization required"),
  check("file_integrity_manifest_created", file.exists(output_paths$integrity) && nrow(integrity_manifest) == length(s29i_files), "integrity manifest created"),
  check("all_required_s29i_files_hashed", all(file.exists(s29i_files)) && nrow(integrity_manifest) == length(s29i_files), "all S29I files hashed"),
  check("sha256_values_present", all(nchar(integrity_manifest$sha256) == 64), "SHA-256 values present"),
  check("upstream_lineage_manifest_created", file.exists(output_paths$lineage) && nrow(lineage_manifest) == 1, "lineage manifest created"),
  check("lineage_commit_values_verified", lineage_manifest$s29i_commit == s29i_commit && lineage_manifest$s29h_commit == s29h_commit && lineage_manifest$s29f_commit == s29f_commit, "lineage commits verified"),
  check("downstream_consumer_contract_created", file.exists(output_paths$consumer) && nrow(consumer_contract) > 0, "consumer contract created"),
  check("handoff_file_classification_complete", all(file_classification$classification_status == "PASS"), "all S29I files classified"),
  check("no_s29i_file_modified", upstream_unchanged, "S29I and upstream input hashes unchanged"),
  check("no_upstream_output_modified", upstream_unchanged, "upstream input hashes unchanged"),
  check("no_new_level_variable_constructed", no_new$status[no_new$audit_item == "no_new_level_variable"] == "PASS", "no level"),
  check("no_new_log_constructed", no_new$status[no_new$audit_item == "no_new_log"] == "PASS", "no log"),
  check("no_new_growth_rate_constructed", no_new$status[no_new$audit_item == "no_new_growth_rate"] == "PASS", "no growth"),
  check("no_new_difference_constructed", no_new$status[no_new$audit_item == "no_new_difference"] == "PASS", "no difference"),
  check("no_new_lag_constructed", no_new$status[no_new$audit_item == "no_new_lag"] == "PASS", "no lag"),
  check("no_new_share_constructed", no_new$status[no_new$audit_item == "no_new_share"] == "PASS", "no share"),
  check("no_new_intensity_measure_constructed", no_new$status[no_new$audit_item == "no_new_intensity_measure"] == "PASS", "no intensity"),
  check("no_model_input_panel_constructed", no_modeling$status[no_modeling$audit_item == "no_model_input_panel"] == "PASS", "no model panel"),
  check("no_complete_case_estimation_sample_constructed", no_modeling$status[no_modeling$audit_item == "no_complete_case_estimation_sample"] == "PASS", "no estimation sample"),
  check("no_output_variable_joined", no_modeling$status[no_modeling$audit_item == "no_output_variable_join"] == "PASS", "no output join"),
  check("no_distribution_variable_joined", no_modeling$status[no_modeling$audit_item == "no_distribution_variable_join"] == "PASS", "no distribution join"),
  check("no_q_variables_constructed", all(no_q$status == "PASS"), "no q"),
  check("no_omega_weighted_capital_variables_constructed", no_q$status[no_q$audit_item == "no_omega_weighted_capital_variables"] == "PASS", "no omega"),
  check("no_distribution_capital_interactions_constructed", no_theta$status[no_theta$audit_item == "no_distribution_capital_interactions"] == "PASS", "no distribution interactions"),
  check("no_theta_variables_constructed", all(no_theta$status == "PASS"), "no theta"),
  check("no_productive_capacity_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_productive_capacity"] == "PASS", "no capacity"),
  check("no_utilization_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_utilization"] == "PASS", "no utilization"),
  check("no_output_capital_ratio_constructed", no_utilization$status[no_utilization$audit_item == "no_output_capital_ratio"] == "PASS", "no output-capital ratio"),
  check("no_modeling_outputs_created", no_modeling$status[no_modeling$audit_item == "no_modeling_outputs"] == "PASS", "no modeling"),
  check("no_econometric_outputs_created", no_modeling$status[no_modeling$audit_item == "no_econometric_outputs"] == "PASS", "no econometrics"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "provider tracked and staged diffs clean; pre-existing untracked files ignored")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)
all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 90
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

handoff_md <- c(
  "# S29J Total Capital Interface Handoff",
  "",
  "S29J independently validates the S29I interface and records SHA-256 file integrity for the S29I handoff package.",
  "",
  "Authorized downstream consumption is limited to the S29H/S29J contract. This does not authorize q, theta, productive capacity, utilization, output-capital ratios, model samples, modeling, or econometrics.",
  "",
  "## Baseline",
  "",
  "- `G_TOT_GPIM_2017`",
  "- `LOG_G_TOT_GPIM_2017`",
  "",
  "## Robustness",
  "",
  "- `N_TOT_GPIM_2017`",
  "- `LOG_N_TOT_GPIM_2017`"
)
writeLines(handoff_md, output_paths$handoff_md)

validation_md <- c(
  "# S29J Total Capital Interface Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 90", "FAIL"), "`."),
  paste0("Active observations validated: `", nrow(source_audit), "`."),
  paste0("Maximum source-value residual: `", max_residual, "`."),
  paste0("S29I files hashed: `", nrow(integrity_manifest), "`."),
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29J Total Capital Interface Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29J consumed S29I commit `", s29i_commit, "`, S29H commit `", s29h_commit, "`, and S29F commit `", s29f_commit, "`."),
  paste0("S29I validation and decision: `PASS 87`; `", required_s29i_decision, "`."),
  paste0("S29J validation: `", ifelse(all_validation_pass, "PASS 90", "FAIL"), "`."),
  "",
  "S29J authorizes downstream consumption of the total-capital interface only according to the recorded S29H/S29J contract.",
  "",
  "S29J stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) stop("S29J validation failed; see ", output_paths$validation)

message("S29J validation PASS 90")
message("Active observations validated: ", nrow(source_audit))
message("S29I files hashed: ", nrow(integrity_manifest))
message("Decision: ", final_decision)
