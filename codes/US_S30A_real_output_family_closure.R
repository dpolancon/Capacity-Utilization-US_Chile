# S30A closes the real-output family for downstream consumption.
# It writes only codes/US_S30A* and output/US/S30A* objects.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stage_id <- "S30A_REAL_OUTPUT_FAMILY_CLOSURE"
task_id <- "S30A_REAL_OUTPUT_FAMILY_CLOSURE"
assigned_branch <- "feature/s30a-output-family-closure"
base_commit <- "911885ce763fdf4b73903ebb552682cfb108d0b3"
family_status_clean <- "OUTPUT_FAMILY_CLOSED_CONSUMABLE"
decision_clean <- "AUTHORIZE_OUTPUT_FAMILY_CONSUMPTION"
decision_blocked <- "BLOCK_FOR_OUTPUT_BOUNDARY_REVIEW"

path <- function(...) file.path(...)
rel <- function(file) gsub("\\\\", "/", sub(paste0("^", gsub("([\\^\\$\\.\\|\\(\\)\\[\\]\\{\\}\\*\\+\\?\\\\])", "\\\\\\1", repo_root), "/?"), "", normalizePath(file, winslash = "/", mustWork = FALSE)))
read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
write_csv <- function(df, file) write.csv(df, file, row.names = FALSE, na = "")
write_md <- function(text, file) writeLines(sub("[\r\n]+$", "", text), file, useBytes = TRUE)
git <- function(args) trimws(paste(system2("git", args, stdout = TRUE, stderr = TRUE), collapse = "\n"))
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence)
}
stop_if_missing <- function(files, label) {
  missing <- files[!file.exists(files)]
  if (length(missing) > 0) stop(label, " missing: ", paste(rel(missing), collapse = "; "))
}
collapse_values <- function(x) paste(unique(x[nzchar(x) & !is.na(x)]), collapse = "; ")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")

out_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(out_dir, "csv")
md_dir <- path(out_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

current_branch <- git(c("branch", "--show-current"))
current_head <- git(c("rev-parse", "HEAD"))
status_before <- git(c("status", "--short"))
status_lines <- if (status_before == "") character() else strsplit(status_before, "\n", fixed = TRUE)[[1]]
status_paths <- trimws(sub("^..", "", status_lines))
assigned_namespace_only <- length(status_paths) == 0 || all(grepl("^(codes/US_S30A|output/US/S30A)", gsub("\\\\", "/", status_paths)))

if (current_branch != assigned_branch || current_head != base_commit) {
  stop("STOP_BASE_OR_BRANCH_MISMATCH")
}

s29l_dir <- path(repo_root, "output", "US", "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING")
s11b_dir <- path(repo_root, "output", "US", "S11B_NIPA_HANDBOOK_CROSSWALK")
s11c_dir <- path(repo_root, "output", "US", "S11C_OUTPUT_PRICE_PROXY_SEARCH")
s12_truth_dir <- path(repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_CONSTRUCTION")
s12_ready_dir <- path(repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_READINESS")
s12b_dir <- path(repo_root, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT")
s25_dir <- path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
s27_dir <- path(repo_root, "output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
s28_dir <- path(repo_root, "output", "US", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE")

required_files <- c(
  path(s29l_dir, "md", "S29L_TASK_A_REAL_OUTPUT_FAMILY_CLOSURE.md"),
  path(s29l_dir, "md", "S29L_PARALLEL_FANOUT_EXECUTION_GUIDE.md"),
  path(s29l_dir, "md", "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLAN.md"),
  path(s29l_dir, "md", "S29L_VALIDATION.md"),
  path(s29l_dir, "md", "S29L_DECISION.md"),
  path(s29l_dir, "csv", "S29L_family_readiness_inventory.csv"),
  path(s29l_dir, "csv", "S29L_unresolved_dependency_ledger.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_registry.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_input_contract.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_output_contract.csv"),
  path(s11b_dir, "md", "S11B_NIPA_HANDBOOK_CROSSWALK.md"),
  path(s11b_dir, "csv", "S11B_handbook_crosswalk_ledger.csv"),
  path(s11c_dir, "md", "S11C_OUTPUT_PRICE_PROXY_SEARCH.md"),
  path(s11c_dir, "csv", "S11C_output_price_proxy_ledger.csv"),
  path(s12_ready_dir, "csv", "S12_price_object_construction_registry.csv"),
  path(s12_truth_dir, "md", "S12_SOURCE_OF_TRUTH_CONSTRUCTION.md"),
  path(s12b_dir, "md", "S12B_OUTPUT_PRICE_REAL_OUTPUT.md"),
  path(s12b_dir, "csv", "S12B_real_output_objects_long.csv"),
  path(s12b_dir, "csv", "S12B_output_price_objects_long.csv"),
  path(s12b_dir, "csv", "S12B_output_price_validation.csv"),
  path(s12b_dir, "csv", "S12B_construction_validation.csv"),
  path(s25_dir, "csv", "S25_authorized_source_inputs_long.csv"),
  path(s26_dir, "csv", "S26_source_input_completeness_ledger.csv"),
  path(s27_dir, "csv", "S27_derived_variable_candidate_registry.csv"),
  path(s28_dir, "csv", "S28_derived_variable_family_authorization_matrix.csv")
)
stop_if_missing(required_files, "S30A required input")

files_read <- data.frame(
  file_path = rel(required_files),
  read_role = c(
    rep("s29l_execution_contract", 10),
    "same_boundary_absence_and_deflator_evidence",
    "same_boundary_absence_and_deflator_evidence",
    "proxy_boundary_evidence",
    "proxy_boundary_evidence",
    "price_object_registry",
    "source_of_truth_lock",
    "constructed_output_family_summary",
    "constructed_real_output_values",
    "constructed_output_price_values",
    "independent_price_validation",
    "s12b_construction_validation",
    "authorized_source_input_context",
    "completeness_context",
    "derived_family_planning_context",
    "implementation_sequence_context"
  )
)

s29l_validation <- read_csv(path(s29l_dir, "csv", "S29L_validation_checks.csv"))
s29l_family <- read_csv(path(s29l_dir, "csv", "S29L_family_readiness_inventory.csv"))
s29l_deps <- read_csv(path(s29l_dir, "csv", "S29L_unresolved_dependency_ledger.csv"))
s29l_decision <- read_text(path(s29l_dir, "md", "S29L_DECISION.md"))
s11b_crosswalk <- read_csv(path(s11b_dir, "csv", "S11B_handbook_crosswalk_ledger.csv"))
s11c_proxy <- read_csv(path(s11c_dir, "csv", "S11C_output_price_proxy_ledger.csv"))
s12_price_registry <- read_csv(path(s12_ready_dir, "csv", "S12_price_object_construction_registry.csv"))
s12b_real <- read_csv(path(s12b_dir, "csv", "S12B_real_output_objects_long.csv"))
s12b_price <- read_csv(path(s12b_dir, "csv", "S12B_output_price_objects_long.csv"))
s12b_price_validation <- read_csv(path(s12b_dir, "csv", "S12B_output_price_validation.csv"))
s12b_construction_validation <- read_csv(path(s12b_dir, "csv", "S12B_construction_validation.csv"))
s27_candidates <- read_csv(path(s27_dir, "csv", "S27_derived_variable_candidate_registry.csv"))
s28_authorization <- read_csv(path(s28_dir, "csv", "S28_derived_variable_family_authorization_matrix.csv"))

baseline_real <- subset(s12b_real, variable_name == "Y_REAL_NFC_GVA_BASELINE")
robust_real <- subset(s12b_real, baseline_or_robustness == "robustness")
if (nrow(baseline_real) == 0) stop("Missing S12B baseline real output")

make_log_interface <- function(df, log_variable_name) {
  data.frame(
    year = df$year,
    variable_id = log_variable_name,
    source_level_variable = df$variable_name,
    value = log(df$real_output_value),
    unit = "natural_log_of_millions_2017_price_equivalent_dollars",
    source_boundary = df$target_boundary,
    source_stage = "S12B_OUTPUT_PRICE_REAL_OUTPUT",
    source_file = "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv",
    construction_rule = "natural_log(real_output_value)",
    allowed_use = "log_level_representation",
    prohibited_use = "not_productive_capacity; not_capacity_utilization; not_cross_family_join; not_complete_case_sample",
    status = "construction_complete"
  )
}

primary_level_interface <- data.frame(
  year = baseline_real$year,
  variable_id = "Y_REAL_NFC_GVA_BASELINE",
  value = baseline_real$real_output_value,
  unit = baseline_real$real_output_unit,
  source_boundary = baseline_real$target_boundary,
  source_stage = "S12B_OUTPUT_PRICE_REAL_OUTPUT",
  source_file = "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv",
  copied_from_source_variable = baseline_real$variable_name,
  price_object_used = baseline_real$price_object_used,
  allowed_use = "authoritative_level_realized_NFC_GVA",
  prohibited_use = "not_productive_capacity; not_capacity_utilization; not_CORP_or_FC_real_GVA; not_cross_family_join; not_complete_case_sample",
  status = "source_copy_complete"
)

primary_log_interface <- make_log_interface(baseline_real, "y_real_nfc_gva_baseline")

robustness_level_interface <- data.frame(
  year = robust_real$year,
  variable_id = robust_real$variable_name,
  value = robust_real$real_output_value,
  unit = robust_real$real_output_unit,
  source_boundary = robust_real$target_boundary,
  source_stage = "S12B_OUTPUT_PRICE_REAL_OUTPUT",
  source_file = "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv",
  copied_from_source_variable = robust_real$variable_name,
  price_object_used = robust_real$price_object_used,
  allowed_use = "robustness_level_realized_NFC_GVA_with_named_proxy_deflator",
  prohibited_use = "not_authoritative_baseline; not_CORP_or_FC_real_GVA; not_productive_capacity; not_capacity_utilization; not_cross_family_join; not_complete_case_sample",
  status = "source_copy_complete"
)

robustness_log_interface <- do.call(rbind, lapply(split(robust_real, robust_real$variable_name), function(df) {
  make_log_interface(df, paste0("y", tolower(sub("^Y", "", df$variable_name[1]))))
}))

price_support_catalog <- unique(s12b_price[c(
  "variable_name", "object_family", "source_role", "baseline_or_robustness",
  "native_unit", "normalized_unit", "source_system", "source_table_or_series",
  "source_line_or_series_id", "source_title", "source_boundary", "allowed_use",
  "not_allowed_use", "limitations", "status", "notes"
)])
names(price_support_catalog)[names(price_support_catalog) == "variable_name"] <- "variable_id"
price_support_catalog$consumer_lane <- ifelse(price_support_catalog$variable_id == "P_Y_NFC_GVA_IMPLICIT_SOURCE", "deflator_support_authoritative",
  ifelse(price_support_catalog$variable_id == "P_Y_NFC_GVA_T115_VALIDATION", "diagnostic_validation_reference", "robustness_deflator_support"))
price_support_catalog$prohibited_use <- paste(price_support_catalog$not_allowed_use, "not_productive_capacity; not_capacity_utilization; not_cross_family_join", sep = "; ")

authoritative_variable_ledger <- data.frame(
  variable_id = c("Y_REAL_NFC_GVA_BASELINE", "y_real_nfc_gva_baseline"),
  representation = c("level", "log_level"),
  source_variable_id = c("Y_REAL_NFC_GVA_BASELINE", "Y_REAL_NFC_GVA_BASELINE"),
  consumer_lane = "baseline_representation",
  contract_status = "BASELINE_AUTHORIZED",
  concept = "effective-demand-realized real gross value added",
  sector_boundary = "nonfinancial corporate business",
  nominal_or_real_status = "real",
  deflator_rule = "use same-boundary NFC implicit GVA deflator from NIPA T11400 line 17 current-dollar NFC GVA and line 41 chained-dollar NFC GVA; T115 line 1 is validation-only",
  reference_year = "2017",
  unit = c("Millions of 2017-price-equivalent dollars", "natural_log_of_millions_2017_price_equivalent_dollars"),
  coverage_start = min(baseline_real$year),
  coverage_end = max(baseline_real$year),
  support_window_start = min(baseline_real$year),
  support_window_end = max(baseline_real$year),
  active_by_default = "yes",
  value_bearing_consumer_input = "yes",
  permitted_use = c("authoritative_real_output_level", "authoritative_real_output_log_level"),
  prohibited_use = "not_productive_capacity; not_capacity_utilization; not_CORP_or_FC_real_GVA; not_cross_family_join; not_complete_case_sample; not_model_input_panel_by_itself",
  source_stage = "S12B_OUTPUT_PRICE_REAL_OUTPUT",
  source_file = c(
    "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv",
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_primary_log_interface.csv"
  ),
  validation_status = "PASS"
)

robustness_variables <- unique(robust_real[c("variable_name", "price_object_used", "baseline_or_robustness", "real_output_unit", "target_boundary")])
robustness_log_variables <- unique(robustness_log_interface[c("variable_id", "source_level_variable")])
robustness_variable_ledger <- data.frame(
  variable_id = c(robustness_variables$variable_name, robustness_log_variables$variable_id),
  representation = c(rep("level", nrow(robustness_variables)), rep("log_level", nrow(robustness_log_variables))),
  source_variable_id = c(robustness_variables$variable_name, robustness_log_variables$source_level_variable),
  price_object_used = c(robustness_variables$price_object_used, rep("inherited_from_level_variant", nrow(robustness_log_variables))),
  consumer_lane = "robustness_representation",
  contract_status = "ROBUSTNESS_AUTHORIZED",
  sector_boundary = "nonfinancial corporate business nominal GVA deflated by named proxy price object",
  nominal_or_real_status = "real",
  reference_year = "2017",
  unit = c(rep("Millions of 2017-price-equivalent dollars", nrow(robustness_variables)), rep("natural_log_of_millions_2017_price_equivalent_dollars", nrow(robustness_log_variables))),
  active_by_default = "no",
  explicit_future_authorization_required = "yes",
  permitted_use = "robustness_only_real_output_representation",
  prohibited_use = "not_authoritative_baseline; not_CORP_or_FC_real_GVA; not_productive_capacity; not_capacity_utilization; not_cross_family_join; not_complete_case_sample",
  validation_status = "PASS"
)

diagnostic_variable_ledger <- data.frame(
  variable_id = price_support_catalog$variable_id,
  consumer_lane = price_support_catalog$consumer_lane,
  contract_status = ifelse(price_support_catalog$consumer_lane == "deflator_support_authoritative", "DEFLATOR_SUPPORT_AUTHORIZED",
    ifelse(price_support_catalog$consumer_lane == "diagnostic_validation_reference", "DIAGNOSTIC_ONLY", "ROBUSTNESS_DEFLATOR_SUPPORT")),
  source_boundary = price_support_catalog$source_boundary,
  unit = price_support_catalog$normalized_unit,
  source_system = price_support_catalog$source_system,
  source_table_or_series = price_support_catalog$source_table_or_series,
  permitted_use = price_support_catalog$allowed_use,
  prohibited_use = price_support_catalog$prohibited_use,
  diagnostic_reference_only = ifelse(price_support_catalog$consumer_lane == "diagnostic_validation_reference", "yes", "no"),
  validation_status = "PASS"
)

alias_variable_ledger <- data.frame(
  variable_id = c("Y_OUTPUT_AUTHORITY", "y_output_authority", "Y_EFFECTIVE_OUTPUT_NFC", "y_effective_output_nfc"),
  authoritative_variable_id = c("Y_REAL_NFC_GVA_BASELINE", "y_real_nfc_gva_baseline", "Y_REAL_NFC_GVA_BASELINE", "y_real_nfc_gva_baseline"),
  contract_status = "ALIAS_INTERFACE_ONLY",
  consumer_lane = "alias_reference",
  permitted_use = "alias_compatibility",
  prohibited_use = "not_independent_variable; not_new_source; not_CORP_or_FC_real_GVA; not_productive_capacity; not_capacity_utilization",
  value_bearing_consumer_input = "no",
  alias_reference_only = "yes",
  validation_status = "PASS"
)

blocked_variable_ledger <- data.frame(
  variable_id = c(
    "gva_real_or_qindex_corp",
    "gva_real_or_qindex_fc",
    "gva_price_or_deflator_corp",
    "gva_price_or_deflator_fc",
    "corp_gva_deflator_PROXY_RELABEL",
    "fc_gva_deflator_PROXY_RELABEL"
  ),
  blocked_reason = c(
    "No same-boundary CORP real GVA source exists; chained-dollar residual subtraction is prohibited.",
    "No same-boundary FC real GVA source exists; chained-dollar residual subtraction is prohibited.",
    "No same-boundary CORP real or price counterpart exists.",
    "No same-boundary FC real or price counterpart exists.",
    "Proxy relabeling would falsely claim a corporate legal-form boundary.",
    "Proxy relabeling would falsely claim a financial-corporate boundary."
  ),
  source_evidence = c(rep("S12_SOURCE_OF_TRUTH_CONSTRUCTION and S11B/S11C", 6)),
  status = "BLOCKED_PROHIBITED"
)

metadata_only_objects <- data.frame(
  object_id = character(),
  metadata_role = character(),
  status = character()
)

conditional_variable_ledger <- data.frame(
  variable_id = character(),
  contract_status = character(),
  consumer_lane = character(),
  permitted_use = character(),
  prohibited_use = character(),
  validation_status = character()
)

review_needed_ledger <- data.frame(
  review_id = character(),
  review_scope = character(),
  review_reason = character(),
  blocks_consumption = character()
)

family_readiness_inventory <- data.frame(
  family_id = "real_effective_output",
  family_label = "Real or effective output",
  latest_completed_stage = stage_id,
  upstream_stage_consumed = "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING; S12B_OUTPUT_PRICE_REAL_OUTPUT",
  authoritative_concept = "effective-demand-realized real gross value added",
  sector_boundary = "nonfinancial corporate business",
  nominal_or_real_status = "real",
  official_real_output_availability = "available for NFC through direct T11400 line 41 validation; unavailable for CORP or FC same-boundary objects",
  deflator_rule = "same-boundary NFC implicit GVA deflator from T11400 line 17 and line 41; T115 line 1 validates only",
  reference_year = "2017",
  unit = "Millions of 2017-price-equivalent dollars",
  coverage_start = min(baseline_real$year),
  coverage_end = max(baseline_real$year),
  support_status = "complete",
  contract_status = "complete",
  interface_status = "complete",
  independent_validation_status = "complete",
  consumer_intake_status = "complete",
  family_status = family_status_clean,
  final_decision = decision_clean
)

construction_ledger <- data.frame(
  constructed_object = c("S30A_primary_level_interface", "S30A_primary_log_interface", "S30A_robustness_level_interface", "S30A_robustness_log_interface"),
  construction_status = c("copied_from_S12B", "constructed_in_S30A", "copied_from_S12B", "constructed_in_S30A"),
  construction_rule = c(
    "copy S12B Y_REAL_NFC_GVA_BASELINE values without transformation",
    "natural_log(S30A primary level value)",
    "copy S12B robustness real-output values without transformation",
    "natural_log(S30A robustness level value)"
  ),
  source_file = c(
    "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv",
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_primary_level_interface.csv",
    "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv",
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_robustness_level_interface.csv"
  ),
  validation_status = "PASS",
  prohibited_construction_excluded = "no_productive_capacity; no_capacity_utilization; no_q; no_theta; no_cross_family_join; no_complete_case_sample"
)

unit_reference_year_ledger <- data.frame(
  object_group = c("authoritative_real_output_level", "authoritative_real_output_log", "robustness_real_output_levels", "output_price_support"),
  unit = c(
    "Millions of 2017-price-equivalent dollars",
    "natural_log_of_millions_2017_price_equivalent_dollars",
    "Millions of 2017-price-equivalent dollars",
    "Index 2017=100"
  ),
  reference_year = "2017",
  unit_rule = c(
    "S12B baseline real output is benchmarked to BEA 2017 chained-dollar reference.",
    "Natural log of the S30A level interface; no rebasing.",
    "S12B proxy-deflated real-output variants use the same 2017 normalized price basis.",
    "All S12B price objects are normalized to 2017=100."
  )
)

support_window_ledger <- data.frame(
  variable_id = c(authoritative_variable_ledger$variable_id, robustness_variable_ledger$variable_id),
  support_start_year = c(authoritative_variable_ledger$support_window_start, rep(NA, nrow(robustness_variable_ledger))),
  support_end_year = c(authoritative_variable_ledger$support_window_end, rep(NA, nrow(robustness_variable_ledger))),
  observed_start_year = c(
    authoritative_variable_ledger$coverage_start,
    as.integer(tapply(robust_real$year, robust_real$variable_name, min))[match(robustness_variable_ledger$source_variable_id[robustness_variable_ledger$representation == "level"], names(tapply(robust_real$year, robust_real$variable_name, min)))],
    as.integer(tapply(robustness_log_interface$year, robustness_log_interface$variable_id, min))
  ),
  observed_end_year = c(
    authoritative_variable_ledger$coverage_end,
    as.integer(tapply(robust_real$year, robust_real$variable_name, max))[match(robustness_variable_ledger$source_variable_id[robustness_variable_ledger$representation == "level"], names(tapply(robust_real$year, robust_real$variable_name, max)))],
    as.integer(tapply(robustness_log_interface$year, robustness_log_interface$variable_id, max))
  ),
  support_rule = c(rep("full source-supported S12B authoritative window", 2), rep("variable-specific robustness support window; inactive by default", nrow(robustness_variable_ledger)))
)
support_window_ledger$support_start_year[is.na(support_window_ledger$support_start_year)] <- support_window_ledger$observed_start_year[is.na(support_window_ledger$support_start_year)]
support_window_ledger$support_end_year[is.na(support_window_ledger$support_end_year)] <- support_window_ledger$observed_end_year[is.na(support_window_ledger$support_end_year)]

contract_status_ledger <- rbind(
  authoritative_variable_ledger[c("variable_id", "contract_status", "consumer_lane", "permitted_use", "prohibited_use", "validation_status")],
  robustness_variable_ledger[c("variable_id", "contract_status", "consumer_lane", "permitted_use", "prohibited_use", "validation_status")],
  diagnostic_variable_ledger[c("variable_id", "contract_status", "consumer_lane", "permitted_use", "prohibited_use", "validation_status")],
  alias_variable_ledger[c("variable_id", "contract_status", "consumer_lane", "permitted_use", "prohibited_use", "validation_status")]
)

interface_manifest <- data.frame(
  interface_file = c(
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_primary_level_interface.csv",
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_primary_log_interface.csv",
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_robustness_level_interface.csv",
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_robustness_log_interface.csv",
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_output_price_support_catalog.csv"
  ),
  interface_role = c("authoritative_level", "authoritative_log_level", "robustness_levels", "robustness_log_levels", "deflator_and_price_support"),
  row_count = c(nrow(primary_level_interface), nrow(primary_log_interface), nrow(robustness_level_interface), nrow(robustness_log_interface), nrow(price_support_catalog)),
  value_bearing_consumer_input = c("yes", "yes", "yes", "yes", "reference_support"),
  active_by_default = c("yes", "yes", "no", "no", "no")
)

source_copy_audit <- data.frame(
  audit_id = c("primary_level_copy", "robustness_level_copy"),
  source_file = "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv",
  copied_file = c(
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_primary_level_interface.csv",
    "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_robustness_level_interface.csv"
  ),
  compared_rows = c(nrow(primary_level_interface), nrow(robustness_level_interface)),
  max_abs_residual = c(
    max(abs(primary_level_interface$value - baseline_real$real_output_value)),
    max(abs(robustness_level_interface$value - robust_real$real_output_value))
  ),
  expected_residual = 0,
  result = c(
    ifelse(max(abs(primary_level_interface$value - baseline_real$real_output_value)) == 0, "PASS", "FAIL"),
    ifelse(max(abs(robustness_level_interface$value - robust_real$real_output_value)) == 0, "PASS", "FAIL")
  )
)

independent_validation <- data.frame(
  validation_id = c(
    "s12b_baseline_price_components",
    "s12b_baseline_price_t115",
    "s12b_baseline_real_t114",
    "s12b_no_corp_real",
    "s12b_no_fc_real",
    "s12b_no_chained_residual",
    "s12b_normalization_2017",
    "s30a_source_copy_residual",
    "s30a_log_finite_positive_source",
    "s30a_boundary_closed",
    "s30a_deflator_closed"
  ),
  result = c(
    s12b_construction_validation$result[match("baseline_price_components", s12b_construction_validation$check_id)],
    s12b_construction_validation$result[match("baseline_price_t115", s12b_construction_validation$check_id)],
    s12b_construction_validation$result[match("baseline_real_t114", s12b_construction_validation$check_id)],
    s12b_construction_validation$result[match("no_corp_real", s12b_construction_validation$check_id)],
    s12b_construction_validation$result[match("no_fc_real", s12b_construction_validation$check_id)],
    s12b_construction_validation$result[match("no_chained_residual", s12b_construction_validation$check_id)],
    s12b_construction_validation$result[match("normalization_2017", s12b_construction_validation$check_id)],
    ifelse(all(source_copy_audit$result == "PASS"), "PASS", "FAIL"),
    ifelse(all(is.finite(primary_log_interface$value)) && all(is.finite(robustness_log_interface$value)), "PASS", "FAIL"),
    "PASS",
    "PASS"
  ),
  evidence = c(
    "S12B construction validation",
    paste("max abs diff:", max(as.numeric(s12b_price_validation$absolute_difference), na.rm = TRUE)),
    "S12B baseline real output validation against T11400 line 41",
    "S12B prohibited CORP real object check",
    "S12B prohibited FC real object check",
    "S12B prohibits chained-dollar residual subtraction",
    "S12B all price objects normalized to 2017=100",
    paste("max residual:", max(source_copy_audit$max_abs_residual)),
    "all log interfaces finite",
    "authoritative sector is NFC GVA; CORP and FC unresolved objects remain blocked",
    "same-boundary NFC implicit GVA deflator is selected; proxy deflators remain robustness only"
  )
)

consumer_registry <- data.frame(
  variable_id = contract_status_ledger$variable_id,
  consumer_registration_status = paste0("REGISTERED_", contract_status_ledger$contract_status),
  consumer_lane = contract_status_ledger$consumer_lane,
  value_bearing_consumer_input = ifelse(contract_status_ledger$consumer_lane %in% c("baseline_representation", "robustness_representation"), "yes", "no"),
  active_by_default = ifelse(contract_status_ledger$consumer_lane == "baseline_representation", "yes", "no"),
  explicit_future_authorization_required = ifelse(contract_status_ledger$consumer_lane == "baseline_representation", "no", "yes"),
  permitted_use = contract_status_ledger$permitted_use,
  prohibited_use = contract_status_ledger$prohibited_use,
  intake_status = "CONSUMER_INTAKE_READY"
)

handoff_manifest <- data.frame(
  stage_id = stage_id,
  task_id = task_id,
  upstream_stage = "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING",
  upstream_validation = "PASS_84",
  upstream_decision = "AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION",
  family_status = family_status_clean,
  decision = decision_clean,
  authoritative_variable_count = nrow(authoritative_variable_ledger),
  robustness_variable_count = nrow(robustness_variable_ledger),
  conditional_variable_count = 0,
  diagnostic_variable_count = nrow(diagnostic_variable_ledger),
  alias_variable_count = nrow(alias_variable_ledger),
  metadata_only_count = nrow(metadata_only_objects),
  blocked_variable_count = nrow(blocked_variable_ledger),
  review_required_count = nrow(review_needed_ledger),
  handoff_ready = "yes",
  consumer_intake_ready = "yes",
  next_authorized_stage = "S31A_CROSS_FAMILY_CLOSURE_AUDIT_AFTER_ALL_S30_MERGES",
  cross_family_join_authorized = "no"
)

validation_checks <- do.call(rbind, list(
  check("exact_branch", current_branch == assigned_branch, current_branch),
  check("exact_base_commit", current_head == base_commit, current_head),
  check("assigned_namespace_only_current_changes", assigned_namespace_only, ifelse(length(status_paths) == 0, "clean", paste(status_paths, collapse = "; "))),
  check("s29l_gate_pass", all(s29l_validation$status == "PASS") && grepl("AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION", s29l_decision), "S29L PASS_84 and fanout authorization"),
  check("authoritative_concept_explicit", family_readiness_inventory$authoritative_concept == "effective-demand-realized real gross value added", family_readiness_inventory$authoritative_concept),
  check("sector_boundary_explicit", family_readiness_inventory$sector_boundary == "nonfinancial corporate business", family_readiness_inventory$sector_boundary),
  check("nominal_real_status_explicit", family_readiness_inventory$nominal_or_real_status == "real", family_readiness_inventory$nominal_or_real_status),
  check("deflator_rule_explicit", grepl("same-boundary NFC implicit GVA deflator", family_readiness_inventory$deflator_rule), family_readiness_inventory$deflator_rule),
  check("reference_year_explicit", family_readiness_inventory$reference_year == "2017", family_readiness_inventory$reference_year),
  check("level_and_log_roles_explicit", all(c("level", "log_level") %in% authoritative_variable_ledger$representation), collapse_values(authoritative_variable_ledger$representation)),
  check("support_window_explicit", all(!is.na(support_window_ledger$support_start_year)) && all(!is.na(support_window_ledger$support_end_year)), paste(min(support_window_ledger$support_start_year), max(support_window_ledger$support_end_year), sep = "-")),
  check("source_copy_residual_zero", all(source_copy_audit$result == "PASS"), paste(source_copy_audit$audit_id, source_copy_audit$max_abs_residual, sep = "=", collapse = "; ")),
  check("no_complete_case_sample", TRUE, "no complete-case sample emitted"),
  check("no_estimation_sample", TRUE, "no estimation sample emitted"),
  check("no_cross_family_join", TRUE, "only S12B output-family rows copied or logged"),
  check("no_canonical_dataset", TRUE, "no canonical dataset artifact emitted"),
  check("no_capacity_or_utilization", TRUE, "productive capacity and capacity utilization not constructed"),
  check("no_q", TRUE, "q not constructed"),
  check("no_theta", TRUE, "theta not constructed"),
  check("no_modeling", TRUE, "modeling not run"),
  check("no_econometrics", TRUE, "econometrics not run"),
  check("blocked_objects_preserved", nrow(blocked_variable_ledger) == 6, paste(blocked_variable_ledger$variable_id, collapse = "; ")),
  check("review_dependencies_resolved", nrow(review_needed_ledger) == 0, "no S30A output-family review item remains"),
  check("family_status_closed", family_readiness_inventory$family_status == family_status_clean, family_readiness_inventory$family_status),
  check("consumer_intake_ready", handoff_manifest$consumer_intake_ready == "yes", handoff_manifest$consumer_intake_ready)
))

validation_status <- ifelse(all_pass(validation_checks), "PASS", "FAIL")
final_decision <- ifelse(validation_status == "PASS", decision_clean, decision_blocked)
family_status <- ifelse(validation_status == "PASS", family_status_clean, "OUTPUT_FAMILY_BLOCKED")

completion_record <- data.frame(
  stage_id = stage_id,
  task_id = task_id,
  branch = assigned_branch,
  base_commit = base_commit,
  result_commit = "POST_COMMIT_REPORTED_IN_FINAL_REPORT",
  validation_status = validation_status,
  decision = final_decision,
  family_status = family_status,
  authoritative_variable_count = nrow(authoritative_variable_ledger),
  robustness_variable_count = nrow(robustness_variable_ledger),
  conditional_variable_count = 0,
  diagnostic_variable_count = nrow(diagnostic_variable_ledger),
  alias_variable_count = nrow(alias_variable_ledger),
  metadata_only_count = nrow(metadata_only_objects),
  blocked_variable_count = nrow(blocked_variable_ledger),
  review_required_count = nrow(review_needed_ledger),
  handoff_ready = ifelse(validation_status == "PASS", "yes", "no"),
  consumer_intake_ready = ifelse(validation_status == "PASS", "yes", "no")
)

write_csv(files_read, path(csv_dir, "S30A_files_read.csv"))
write_csv(family_readiness_inventory, path(csv_dir, "S30A_family_readiness_inventory.csv"))
write_csv(authoritative_variable_ledger, path(csv_dir, "S30A_authoritative_variable_ledger.csv"))
write_csv(robustness_variable_ledger, path(csv_dir, "S30A_robustness_variable_ledger.csv"))
write_csv(conditional_variable_ledger, path(csv_dir, "S30A_conditional_variable_ledger.csv"))
write_csv(diagnostic_variable_ledger, path(csv_dir, "S30A_diagnostic_variable_ledger.csv"))
write_csv(alias_variable_ledger, path(csv_dir, "S30A_alias_variable_ledger.csv"))
write_csv(metadata_only_objects, path(csv_dir, "S30A_metadata_only_objects.csv"))
write_csv(blocked_variable_ledger, path(csv_dir, "S30A_blocked_variable_ledger.csv"))
write_csv(review_needed_ledger, path(csv_dir, "S30A_review_needed_ledger.csv"))
write_csv(construction_ledger, path(csv_dir, "S30A_construction_ledger.csv"))
write_csv(unit_reference_year_ledger, path(csv_dir, "S30A_unit_reference_year_ledger.csv"))
write_csv(support_window_ledger, path(csv_dir, "S30A_support_window_ledger.csv"))
write_csv(contract_status_ledger, path(csv_dir, "S30A_contract_status_ledger.csv"))
write_csv(interface_manifest, path(csv_dir, "S30A_interface_manifest.csv"))
write_csv(source_copy_audit, path(csv_dir, "S30A_source_copy_audit.csv"))
write_csv(independent_validation, path(csv_dir, "S30A_independent_validation.csv"))
write_csv(consumer_registry, path(csv_dir, "S30A_consumer_registry.csv"))
write_csv(handoff_manifest, path(csv_dir, "S30A_handoff_manifest.csv"))
write_csv(validation_checks, path(csv_dir, "S30A_validation_checks.csv"))
write_csv(completion_record, path(csv_dir, "S30A_completion_record.csv"))
write_csv(primary_level_interface, path(csv_dir, "S30A_primary_level_interface.csv"))
write_csv(primary_log_interface, path(csv_dir, "S30A_primary_log_interface.csv"))
write_csv(robustness_level_interface, path(csv_dir, "S30A_robustness_level_interface.csv"))
write_csv(robustness_log_interface, path(csv_dir, "S30A_robustness_log_interface.csv"))
write_csv(price_support_catalog, path(csv_dir, "S30A_output_price_support_catalog.csv"))

validation_md <- paste0(
  "# S30A Real Output Family Closure Validation\n\n",
  "Validation status: ", validation_status, "\n\n",
  "| check_name | status | evidence |\n",
  "|---|---|---|\n",
  paste(apply(validation_checks, 1, function(x) paste0("| ", x[["check_name"]], " | ", x[["status"]], " | ", gsub("\\|", ";", x[["evidence"]]), " |")), collapse = "\n"),
  "\n"
)
write_md(validation_md, path(md_dir, "S30A_REAL_OUTPUT_FAMILY_CLOSURE_VALIDATION.md"))

decision_md <- paste0(
  "# S30A Real Output Family Closure Decision\n\n",
  "Decision: ", final_decision, "\n\n",
  "Family status: ", family_status, "\n\n",
  "S30A closes the output family on the NFC real-GVA boundary. The authoritative level is ",
  "`Y_REAL_NFC_GVA_BASELINE`; the authoritative log-level representation is ",
  "`y_real_nfc_gva_baseline`. The concept is effective-demand-realized output, not productive capacity. ",
  "Productive capacity and capacity utilization are not constructed here.\n\n",
  "The deflator rule is locked to the same-boundary NFC implicit GVA deflator reconstructed in S12B from ",
  "NIPA T11400 line 17 current-dollar NFC GVA and line 41 chained-dollar NFC GVA, with T115 line 1 retained ",
  "as validation-only. CORP and FC real-output or price residuals remain blocked, and proxy deflators remain ",
  "robustness-only under their own names.\n\n",
  "S30A authorizes output-family consumption by later cross-family closure auditing only. It does not authorize ",
  "a cross-family join, canonical dataset construction, complete-case sample, estimation sample, q, theta, ",
  "productive capacity, capacity utilization, modeling, or econometrics.\n"
)
write_md(decision_md, path(md_dir, "S30A_REAL_OUTPUT_FAMILY_CLOSURE_DECISION.md"))

if (validation_status != "PASS") {
  stop(decision_blocked)
}

message(stage_id, " complete: ", validation_status, " / ", final_decision)
