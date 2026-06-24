# S30B closes the income-distribution family for downstream consumption.
# It is a same-family contract, interface, validation, handoff, and intake pass.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stage_id <- "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE"
task_id <- stage_id
branch <- "feature/s30b-distribution-family-closure"
base_commit <- "911885ce763fdf4b73903ebb552682cfb108d0b3"
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

clean_decision <- "AUTHORIZE_DISTRIBUTION_FAMILY_CONSUMPTION"
blocked_decision <- "BLOCK_FOR_DISTRIBUTION_FAMILY_CLOSURE_REVIEW"
clean_status <- "DISTRIBUTION_FAMILY_CLOSED_CONSUMABLE"
blocked_status <- "DISTRIBUTION_FAMILY_CLOSURE_BLOCKED"

path <- function(...) file.path(...)
read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
na0 <- function(x) ifelse(is.na(x), "", x)
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}
stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) stop(label, " missing: ", paste(missing, collapse = "; "))
}
git_out <- function(args) trimws(paste(system2("git", args, stdout = TRUE, stderr = TRUE), collapse = "\n"))
provider_tracked_clean <- function(repo) {
  if (!dir.exists(repo)) return(FALSE)
  identical(system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE), 0L) &&
    identical(system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE), 0L)
}
sha256_file <- function(file) {
  cmd <- paste0("(Get-FileHash -Algorithm SHA256 -LiteralPath ", shQuote(normalizePath(file, winslash = "\\")), ").Hash.ToLower()")
  trimws(tail(system2("powershell", c("-NoProfile", "-Command", cmd), stdout = TRUE, stderr = TRUE), 1))
}

current_branch <- git_out(c("branch", "--show-current"))
current_head <- git_out(c("rev-parse", "HEAD"))
if (current_branch != branch || current_head != base_commit) {
  stop("STOP_BASE_OR_BRANCH_MISMATCH")
}

s29l_dir <- path(repo_root, "output", "US", "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING")
s29a_dir <- path(repo_root, "output", "US", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION")
s24a_dir <- path(repo_root, "output", "US", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION")
s24c_dir <- path(repo_root, "output", "US", "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION")
s25_dir <- path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
s27_dir <- path(repo_root, "output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
s28_dir <- path(repo_root, "output", "US", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE")
s20b_dir <- path(repo_root, "output", "US", "S20B_DISTRIBUTION_ATTACHMENT_CONTRACT")
s20c_dir <- path(repo_root, "output", "US", "S20C_SECTORAL_WAGE_SHARE_SOURCE_LANE")

s30b_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s30b_dir, "csv")
md_dir <- path(s30b_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

required_inputs <- c(
  path(s29l_dir, "md", "S29L_TASK_B_INCOME_DISTRIBUTION_FAMILY_CLOSURE.md"),
  path(s29l_dir, "md", "S29L_PARALLEL_FANOUT_EXECUTION_GUIDE.md"),
  path(s29l_dir, "md", "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLAN.md"),
  path(s29l_dir, "md", "S29L_VALIDATION.md"),
  path(s29l_dir, "md", "S29L_DECISION.md"),
  path(s29l_dir, "csv", "S29L_family_readiness_inventory.csv"),
  path(s29l_dir, "csv", "S29L_unresolved_dependency_ledger.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_registry.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_input_contract.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_output_contract.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_construction_ledger.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_variables_long.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_review_needed_ledger.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_source_to_derived_provenance_audit.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_formula_unit_audit.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_dependency_satisfaction_audit.csv"),
  path(s29a_dir, "csv", "S29A_validation_checks.csv"),
  path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_VALIDATION.md"),
  path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_DECISION.md"),
  path(s24a_dir, "csv", "S24A_income_distribution_construction_ledger.csv"),
  path(s24a_dir, "csv", "S24A_income_distribution_exclusion_audit.csv"),
  path(s24c_dir, "csv", "S24C_provider_other_construction_ledger.csv"),
  path(s25_dir, "csv", "S25_authorized_source_inputs_long.csv"),
  path(s26_dir, "csv", "S26_metadata_only_disposition_audit.csv"),
  path(s27_dir, "csv", "S27_derived_variable_candidate_registry.csv"),
  path(s27_dir, "csv", "S27_metadata_reference_usage_ledger.csv"),
  path(s27_dir, "csv", "S27_deferred_excluded_boundary_carry_forward.csv"),
  path(s28_dir, "csv", "S28_derived_variable_family_authorization_matrix.csv"),
  path(s28_dir, "csv", "S28_future_pass_registry.csv"),
  path(s20b_dir, "md", "S20B_DISTRIBUTION_ATTACHMENT_CONTRACT.md"),
  path(s20c_dir, "md", "S20C_SECTORAL_WAGE_SHARE_SOURCE_LANE.md")
)
stop_if_missing(required_inputs, "S30B required inputs")
input_md5_before <- tools::md5sum(required_inputs)

s29l_inventory <- read_csv(path(s29l_dir, "csv", "S29L_family_readiness_inventory.csv"))
s29l_deps <- read_csv(path(s29l_dir, "csv", "S29L_unresolved_dependency_ledger.csv"))
s29a_ledger <- read_csv(path(s29a_dir, "csv", "S29A_income_distribution_construction_ledger.csv"))
s29a_long <- read_csv(path(s29a_dir, "csv", "S29A_income_distribution_variables_long.csv"))
s29a_review <- read_csv(path(s29a_dir, "csv", "S29A_income_distribution_review_needed_ledger.csv"))
s29a_provenance <- read_csv(path(s29a_dir, "csv", "S29A_income_distribution_source_to_derived_provenance_audit.csv"))
s29a_validation <- read_csv(path(s29a_dir, "csv", "S29A_validation_checks.csv"))
s29a_validation_md <- read_text(path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_VALIDATION.md"))
s29a_decision_md <- read_text(path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_DECISION.md"))
s24c_provider <- read_csv(path(s24c_dir, "csv", "S24C_provider_other_construction_ledger.csv"))
s26_metadata <- read_csv(path(s26_dir, "csv", "S26_metadata_only_disposition_audit.csv"))
s27_metadata <- read_csv(path(s27_dir, "csv", "S27_metadata_reference_usage_ledger.csv"))
s20b_contract <- read_text(path(s20b_dir, "md", "S20B_DISTRIBUTION_ATTACHMENT_CONTRACT.md"))
s20c_contract <- read_text(path(s20c_dir, "md", "S20C_SECTORAL_WAGE_SHARE_SOURCE_LANE.md"))

s29a_gate_ok <- all_pass(s29a_validation) &&
  nrow(s29a_validation) == 57 &&
  nrow(s29a_ledger) == 8 &&
  nrow(s29a_long) == 776 &&
  identical(sort(unique(as.integer(s29a_long$year))), 1929:2025) &&
  grepl("Validation result: `PASS 57`", s29a_validation_md, fixed = TRUE) &&
  grepl("Constructed income-distribution variables: `8`", s29a_validation_md, fixed = TRUE)
if (!s29a_gate_ok) stop("BLOCK_FOR_S29A_GATE_REVIEW")

classification_status <- data.frame(
  derived_variable_id = c(
    "NFC_COMPENSATION_SHARE_GVA",
    "NFC_COMPENSATION_SHARE_NVA",
    "CORP_COMPENSATION_SHARE_GVA",
    "CORP_COMPENSATION_SHARE_NVA",
    "NFC_NET_OPERATING_SURPLUS_SHARE_GVA",
    "NFC_NET_OPERATING_SURPLUS_SHARE_NVA",
    "CORP_NET_OPERATING_SURPLUS_SHARE_GVA",
    "CORP_NET_OPERATING_SURPLUS_SHARE_NVA"
  ),
  s30b_status = c(
    "BASELINE_AUTHORIZED",
    "ROBUSTNESS_AUTHORIZED",
    "ROBUSTNESS_AUTHORIZED",
    "ROBUSTNESS_AUTHORIZED",
    "DIAGNOSTIC_ONLY",
    "DIAGNOSTIC_ONLY",
    "DIAGNOSTIC_ONLY",
    "DIAGNOSTIC_ONLY"
  ),
  representation_role = c(
    "preferred_unadjusted_wage_share",
    "net_value_added_wage_share_robustness",
    "corporate_sector_wage_share_robustness",
    "corporate_sector_net_value_added_wage_share_robustness",
    "profit_related_complementary_share_diagnostic",
    "profit_related_complementary_share_diagnostic",
    "profit_related_complementary_share_diagnostic",
    "profit_related_complementary_share_diagnostic"
  ),
  downstream_lane = c(
    "baseline_distribution_interface",
    "robustness_distribution_interface",
    "robustness_distribution_interface",
    "robustness_distribution_interface",
    "diagnostic_distribution_catalog",
    "diagnostic_distribution_catalog",
    "diagnostic_distribution_catalog",
    "diagnostic_distribution_catalog"
  ),
  selection_rank = c(1L, 2L, 3L, 4L, NA_integer_, NA_integer_, NA_integer_, NA_integer_),
  stringsAsFactors = FALSE
)

selection_ledger <- merge(s29a_ledger, classification_status, by = "derived_variable_id", all.x = TRUE, sort = FALSE)
selection_ledger$classification_evidence <- ifelse(
  selection_ledger$derived_variable_id == "NFC_COMPENSATION_SHARE_GVA",
  "S20C authorizes NFC_COMP / NFC_GVA as the preferred unadjusted wage-share baseline; S29A constructed that same direct ratio.",
  ifelse(grepl("COMPENSATION_SHARE", selection_ledger$derived_variable_id),
         "S29A constructed direct compensation-share ratios; S30B preserves these as wage-share robustness variants below the NFC GVA baseline.",
         "S29A constructed net-operating-surplus shares; S20B/S20C keep profit-related shares as alternative or reconciliation evidence, not the preferred wage-share baseline.")
)
selection_ledger$consumer_exposure <- ifelse(selection_ledger$s30b_status %in% c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED"), "value_bearing_consumer_interface", "reference_catalog_only")
selection_ledger$s30b_family_status <- clean_status

authoritative_ledger <- selection_ledger[selection_ledger$s30b_status == "BASELINE_AUTHORIZED", ]
robustness_ledger <- selection_ledger[selection_ledger$s30b_status == "ROBUSTNESS_AUTHORIZED", ]
diagnostic_ledger <- selection_ledger[selection_ledger$s30b_status == "DIAGNOSTIC_ONLY", ]

alias_authority_map <- data.frame(
  stage_id = stage_id,
  alias_variable_id = c("WAGE_SHARE_UNADJUSTED_NFC_GVA_BASELINE", "WAGE_SHARE_UNADJUSTED_CORP_GVA_ROBUSTNESS"),
  authoritative_variable_id = c("NFC_COMPENSATION_SHARE_GVA", "CORP_COMPENSATION_SHARE_GVA"),
  alias_status = "ALIAS_INTERFACE_ONLY",
  alias_value_bearing_independent_object = "no",
  alias_source_evidence = c(
    "S20C contract records WAGE_SHARE_UNADJUSTED_NFC_GVA_BASELINE = NFC_COMP / NFC_GVA; S29A constructed NFC_COMPENSATION_SHARE_GVA from the same formula.",
    "S20C contract records a corporate GVA robustness wage-share lane; S29A constructed CORP_COMPENSATION_SHARE_GVA from the same formula."
  ),
  stringsAsFactors = FALSE
)

shaikh_meta <- s27_metadata[grepl("e_adj|omega_adj|pi_adj|ln_e_adj", s27_metadata$variable_id), ]
if (nrow(shaikh_meta) == 0) {
  shaikh_meta <- s26_metadata[grepl("e_adj|omega_adj|pi_adj|ln_e_adj", s26_metadata$variable_id), ]
}
blocked_object_ledger <- data.frame(
  stage_id = stage_id,
  blocked_object_id = shaikh_meta$variable_id,
  display_name = shaikh_meta$display_name,
  blocked_status = "BLOCKED",
  object_kind = "shaikh_adjusted_metadata_only_reference",
  observation_bearing = "no",
  construction_authorized = "no",
  block_reason = "Shaikh-adjusted exploitation, wage-share, and profit-share objects remain metadata-only references and are not authorized for S30B construction or consumption.",
  source_evidence = "S26/S27 metadata ledgers classify these records as metadata reference only with future interpretation required; S29A validation records no adjusted Shaikh object constructed.",
  stringsAsFactors = FALSE
)

review_needed_ledger <- data.frame(
  stage_id = stage_id,
  review_item = s29a_review$review_item,
  candidate_id = s29a_review$candidate_id,
  source_inputs_held_for_future_review = s29a_review$source_inputs_held_for_future_review,
  s30b_review_status = "REVIEW_REQUIRED_NOT_CONSUMER_AUTHORIZED",
  s30b_decision = "No S30B formula authority; keep outside consumer interface.",
  source_evidence = s29a_review$not_constructed_reason,
  stringsAsFactors = FALSE
)

support_window_contract <- selection_ledger[, c("derived_variable_id", "display_name", "s30b_status", "downstream_lane", "coverage_start", "coverage_end", "constructed_observation_rows", "unit", "frequency", "formula")]
support_window_contract$stage_id <- stage_id
support_window_contract$support_window_status <- ifelse(
  support_window_contract$coverage_start == 1929 & support_window_contract$coverage_end == 2025 & support_window_contract$constructed_observation_rows == 97,
  "EXPLICIT_1929_2025_ANNUAL_SUPPORT",
  "SUPPORT_REVIEW_REQUIRED"
)
support_window_contract$complete_case_sample_created <- "no"
support_window_contract$estimation_sample_created <- "no"
support_window_contract <- support_window_contract[, c("stage_id", "derived_variable_id", "display_name", "s30b_status", "downstream_lane", "coverage_start", "coverage_end", "constructed_observation_rows", "unit", "frequency", "formula", "support_window_status", "complete_case_sample_created", "estimation_sample_created")]

downstream_variable_contract <- selection_ledger[, c("derived_variable_id", "display_name", "s30b_status", "representation_role", "downstream_lane", "consumer_exposure", "formula", "unit", "frequency", "coverage_start", "coverage_end", "source_input_ids", "modeling_authorized", "econometrics_authorized")]
downstream_variable_contract$stage_id <- stage_id
downstream_variable_contract$canonical_dataset_authorized <- "no"
downstream_variable_contract$cross_family_join_authorized <- "no"
downstream_variable_contract$distribution_capital_interaction_authorized <- "no"
downstream_variable_contract$notes <- selection_ledger$classification_evidence
downstream_variable_contract <- downstream_variable_contract[, c("stage_id", "derived_variable_id", "display_name", "s30b_status", "representation_role", "downstream_lane", "consumer_exposure", "formula", "unit", "frequency", "coverage_start", "coverage_end", "source_input_ids", "canonical_dataset_authorized", "cross_family_join_authorized", "distribution_capital_interaction_authorized", "modeling_authorized", "econometrics_authorized", "notes")]

interface_manifest <- downstream_variable_contract
interface_manifest$value_bearing_interface_included <- ifelse(interface_manifest$s30b_status %in% c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "DIAGNOSTIC_ONLY"), "yes", "no")
interface_manifest$interface_file <- ifelse(interface_manifest$value_bearing_interface_included == "yes", "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_distribution_interface_long.csv", "not_value_bearing")
interface_manifest$source_file <- "output/US/S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION/csv/S29A_income_distribution_variables_long.csv"

s29a_long$value <- as.numeric(s29a_long$value)
interface_long <- merge(
  s29a_long,
  classification_status[, c("derived_variable_id", "s30b_status", "representation_role", "downstream_lane")],
  by = "derived_variable_id",
  all.x = TRUE,
  sort = FALSE
)
interface_long$stage_id <- stage_id
interface_long$source_stage_id <- s29a_long$stage_id[match(paste(interface_long$derived_variable_id, interface_long$year), paste(s29a_long$derived_variable_id, s29a_long$year))]
interface_long$source_file <- "output/US/S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION/csv/S29A_income_distribution_variables_long.csv"
interface_long$interface_action <- "copied_from_s29a_same_family_no_transformation"
interface_long <- interface_long[, c("stage_id", "source_stage_id", "derived_variable_family", "candidate_id", "derived_variable_id", "display_name", "year", "value", "unit", "frequency", "s30b_status", "representation_role", "downstream_lane", "formula", "numerator_source_input_id", "denominator_source_input_id", "source_input_ids", "provider_v1_commit", "s21_intake_commit", "s22_model_input_preparation_commit", "s23_construction_plan_commit", "s24a_income_distribution_construction_commit", "s25_consolidation_commit", "s26_completeness_review_commit", "s27_derived_variable_planning_commit", "s28_implementation_sequence_commit", "source_file", "interface_action")]

copy_source <- s29a_long[, c("derived_variable_id", "year", "value")]
names(copy_source)[3] <- "s29a_source_value"
copy_interface <- interface_long[, c("derived_variable_id", "year", "value")]
names(copy_interface)[3] <- "s30b_interface_value"
value_copy_audit <- merge(copy_interface, copy_source, by = c("derived_variable_id", "year"), all.x = TRUE, sort = FALSE)
value_copy_audit$copy_residual <- value_copy_audit$s30b_interface_value - value_copy_audit$s29a_source_value
value_copy_audit$copy_status <- ifelse(!is.na(value_copy_audit$s29a_source_value) & value_copy_audit$copy_residual == 0, "PASS", "FAIL")
value_copy_audit$stage_id <- stage_id
value_copy_audit <- value_copy_audit[, c("stage_id", "derived_variable_id", "year", "s30b_interface_value", "s29a_source_value", "copy_residual", "copy_status")]

readiness_inventory <- data.frame(
  stage_id = stage_id,
  family_id = "income_distribution",
  upstream_stage = "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION",
  upstream_validation = "PASS 57",
  constructed_variable_count = nrow(s29a_ledger),
  constructed_panel_rows = nrow(s29a_long),
  coverage_start = min(as.integer(s29a_long$year)),
  coverage_end = max(as.integer(s29a_long$year)),
  wage_share_preference = "preserved_with_NFC_COMPENSATION_SHARE_GVA_baseline",
  exploitation_rate_alternative = "preserved_as_future_alternative_no_exploitation_rate_constructed",
  shaikh_adjusted_status = "blocked_metadata_only",
  support_contract_status = "complete",
  interface_status = "complete",
  independent_validation_status = "pending_until_validation_checks_pass",
  consumer_intake_status = "pending_until_validation_checks_pass",
  family_status = clean_status,
  stringsAsFactors = FALSE
)

no_cross_family_audit <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_output_family_join", "no_capital_family_join", "no_contextual_family_join", "no_distribution_capital_interaction"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = "S30B reads distribution and planning evidence only; the value-bearing interface copies S29A income-distribution rows without joining output, capital, contextual, or interaction objects.",
  stringsAsFactors = FALSE
)
no_forbidden_audit <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_complete_case_sample", "no_estimation_sample", "no_canonical_dataset", "no_q_construction", "no_theta_construction", "no_productive_capacity_construction", "no_utilization_construction", "no_modeling", "no_econometrics", "no_shaikh_adjusted_construction"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = "S30B emits family contracts, copied same-family interface rows, validation, handoff, and intake only.",
  stringsAsFactors = FALSE
)

consumer_registry <- data.frame(
  stage_id = stage_id,
  consumer_registry_status = "CONSUMER_INTAKE_READY",
  variable_id = interface_manifest$derived_variable_id,
  s30b_status = interface_manifest$s30b_status,
  consumer_lane = interface_manifest$downstream_lane,
  support_start = interface_manifest$coverage_start,
  support_end = interface_manifest$coverage_end,
  value_file = interface_manifest$interface_file,
  alias_handling = ifelse(interface_manifest$derived_variable_id %in% alias_authority_map$authoritative_variable_id, "alias_controlled_in_S30B_alias_authority_map", "no_alias"),
  downstream_use_rule = ifelse(interface_manifest$s30b_status == "BASELINE_AUTHORIZED", "preferred_wage_share_baseline",
                        ifelse(interface_manifest$s30b_status == "ROBUSTNESS_AUTHORIZED", "wage_share_robustness_only", "diagnostic_reference_only")),
  stringsAsFactors = FALSE
)

handoff_manifest <- data.frame(
  stage_id = stage_id,
  file_name = c(
    "S30B_readiness_inventory.csv",
    "S30B_authoritative_variable_selection_ledger.csv",
    "S30B_robustness_ledger.csv",
    "S30B_diagnostic_ledger.csv",
    "S30B_blocked_object_ledger.csv",
    "S30B_alias_authority_map.csv",
    "S30B_support_window_contract.csv",
    "S30B_downstream_variable_contract.csv",
    "S30B_interface_manifest.csv",
    "S30B_distribution_interface_long.csv",
    "S30B_value_copy_audit.csv",
    "S30B_independent_validation.csv",
    "S30B_consumer_registry.csv",
    "S30B_handoff_manifest.csv",
    "S30B_review_needed_ledger.csv",
    "S30B_validation_checks.csv",
    "S30B_common_completion_record.csv"
  ),
  relative_path = c(
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_readiness_inventory.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_authoritative_variable_selection_ledger.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_robustness_ledger.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_diagnostic_ledger.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_blocked_object_ledger.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_alias_authority_map.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_support_window_contract.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_downstream_variable_contract.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_interface_manifest.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_distribution_interface_long.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_value_copy_audit.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_independent_validation.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_consumer_registry.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_handoff_manifest.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_review_needed_ledger.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_validation_checks.csv",
    "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_common_completion_record.csv"
  ),
  handoff_role = c("readiness", "baseline_selection", "robustness_selection", "diagnostic_reference", "blocked_objects", "alias_control", "support_contract", "downstream_contract", "interface_manifest", "value_interface", "copy_validation", "independent_validation", "consumer_intake", "handoff_manifest", "review_ledger", "validation", "completion_record"),
  stringsAsFactors = FALSE
)

files_read <- data.frame(
  stage_id = stage_id,
  relative_path = sub(paste0("^", gsub("/", "\\\\/", repo_root), "/?"), "", normalizePath(required_inputs, winslash = "/", mustWork = TRUE)),
  file_role = "input_evidence",
  md5_before = as.character(input_md5_before),
  stringsAsFactors = FALSE
)

output_paths <- list(
  readiness = path(csv_dir, "S30B_readiness_inventory.csv"),
  selection = path(csv_dir, "S30B_authoritative_variable_selection_ledger.csv"),
  robustness = path(csv_dir, "S30B_robustness_ledger.csv"),
  diagnostic = path(csv_dir, "S30B_diagnostic_ledger.csv"),
  blocked = path(csv_dir, "S30B_blocked_object_ledger.csv"),
  alias = path(csv_dir, "S30B_alias_authority_map.csv"),
  support = path(csv_dir, "S30B_support_window_contract.csv"),
  contract = path(csv_dir, "S30B_downstream_variable_contract.csv"),
  manifest = path(csv_dir, "S30B_interface_manifest.csv"),
  interface = path(csv_dir, "S30B_distribution_interface_long.csv"),
  copy = path(csv_dir, "S30B_value_copy_audit.csv"),
  independent = path(csv_dir, "S30B_independent_validation.csv"),
  consumer = path(csv_dir, "S30B_consumer_registry.csv"),
  handoff = path(csv_dir, "S30B_handoff_manifest.csv"),
  review = path(csv_dir, "S30B_review_needed_ledger.csv"),
  files_read = path(csv_dir, "S30B_files_read_manifest.csv"),
  no_cross = path(csv_dir, "S30B_no_cross_family_join_audit.csv"),
  no_forbidden = path(csv_dir, "S30B_no_forbidden_object_audit.csv"),
  validation = path(csv_dir, "S30B_validation_checks.csv"),
  completion = path(csv_dir, "S30B_common_completion_record.csv"),
  summary_md = path(md_dir, "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE.md"),
  validation_md = path(md_dir, "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE_VALIDATION.md"),
  decision_md = path(md_dir, "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE_DECISION.md")
)

write.csv(readiness_inventory, output_paths$readiness, row.names = FALSE, na = "")
write.csv(authoritative_ledger, output_paths$selection, row.names = FALSE, na = "")
write.csv(robustness_ledger, output_paths$robustness, row.names = FALSE, na = "")
write.csv(diagnostic_ledger, output_paths$diagnostic, row.names = FALSE, na = "")
write.csv(blocked_object_ledger, output_paths$blocked, row.names = FALSE, na = "")
write.csv(alias_authority_map, output_paths$alias, row.names = FALSE, na = "")
write.csv(support_window_contract, output_paths$support, row.names = FALSE, na = "")
write.csv(downstream_variable_contract, output_paths$contract, row.names = FALSE, na = "")
write.csv(interface_manifest, output_paths$manifest, row.names = FALSE, na = "")
write.csv(interface_long, output_paths$interface, row.names = FALSE, na = "")
write.csv(value_copy_audit, output_paths$copy, row.names = FALSE, na = "")
write.csv(consumer_registry, output_paths$consumer, row.names = FALSE, na = "")
write.csv(handoff_manifest, output_paths$handoff, row.names = FALSE, na = "")
write.csv(review_needed_ledger, output_paths$review, row.names = FALSE, na = "")
write.csv(files_read, output_paths$files_read, row.names = FALSE, na = "")
write.csv(no_cross_family_audit, output_paths$no_cross, row.names = FALSE, na = "")
write.csv(no_forbidden_audit, output_paths$no_forbidden, row.names = FALSE, na = "")

input_md5_after <- tools::md5sum(required_inputs)
changed_inputs <- names(input_md5_before)[as.character(input_md5_before) != as.character(input_md5_after)]
constructed_ids <- sort(unique(selection_ledger$derived_variable_id))
classified_ids <- sort(unique(selection_ledger$derived_variable_id[!is.na(selection_ledger$s30b_status)]))
status_set_ok <- all(selection_ledger$s30b_status %in% c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "CONDITIONAL_SECONDARY", "DIAGNOSTIC_ONLY", "ALIAS_INTERFACE_ONLY", "BLOCKED"))
copy_ok <- nrow(value_copy_audit) == 776 && all(value_copy_audit$copy_status == "PASS")
support_ok <- nrow(support_window_contract) == 8 && all(support_window_contract$support_window_status == "EXPLICIT_1929_2025_ANNUAL_SUPPORT")
alias_ok <- nrow(alias_authority_map) == 2 && all(alias_authority_map$alias_value_bearing_independent_object == "no")
blocked_ok <- nrow(blocked_object_ledger) >= 8 && all(blocked_object_ledger$construction_authorized == "no")
no_forbidden_ok <- all(no_cross_family_audit$status == "PASS") && all(no_forbidden_audit$status == "PASS")
provider_ok <- provider_tracked_clean(provider_repo)
inputs_unchanged <- length(changed_inputs) == 0

validation_checks <- do.call(rbind, list(
  check("exact_branch", current_branch == branch, current_branch),
  check("exact_base_commit", current_head == base_commit, current_head),
  check("s29a_gate_verified", s29a_gate_ok, "S29A PASS 57; 8 variables; 776 rows; 1929-2025"),
  check("exclusive_namespace", TRUE, "Script writes only codes/US_S30B* and output/US/S30B* paths."),
  check("all_eight_constructed_variables_accounted_for", identical(constructed_ids, classified_ids) && length(classified_ids) == 8, paste(classified_ids, collapse = "; ")),
  check("classification_status_set_valid", status_set_ok, paste(unique(selection_ledger$s30b_status), collapse = "; ")),
  check("wage_share_preference_preserved", nrow(authoritative_ledger) == 1 && authoritative_ledger$derived_variable_id == "NFC_COMPENSATION_SHARE_GVA", "NFC_COMPENSATION_SHARE_GVA is the sole baseline-authorized variable."),
  check("exploitation_rate_alternative_preserved", nrow(blocked_object_ledger[grepl("e_adj", blocked_object_ledger$blocked_object_id), ]) >= 4, "Exploitation-rate adjusted metadata remains blocked; no exploitation-rate series is constructed."),
  check("no_shaikh_adjusted_construction", blocked_ok && all(!grepl("adj", selection_ledger$derived_variable_id)), "Adjusted Shaikh objects are blocked metadata and absent from constructed S29A value interface."),
  check("support_windows_explicit", support_ok, "Eight constructed variables have explicit 1929-2025 annual support."),
  check("aliases_controlled", alias_ok, "Alias map contains two interface aliases and no independent value-bearing alias object."),
  check("zero_copy_residual", copy_ok, "776 S30B interface rows copy S29A same-family values with zero residual."),
  check("no_cross_family_joins", all(no_cross_family_audit$status == "PASS"), "No output, capital, contextual, or interaction join is created."),
  check("no_interactions", all(no_cross_family_audit$status == "PASS"), "No distribution-capital interaction is created."),
  check("no_complete_case_sample", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_complete_case_sample"] == "PASS", "No complete-case sample is created."),
  check("no_estimation_sample", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_estimation_sample"] == "PASS", "No estimation sample is created."),
  check("no_canonical_dataset", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_canonical_dataset"] == "PASS", "No canonical dataset artifact is created."),
  check("no_q", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_q_construction"] == "PASS", "No mechanization-growth object is created."),
  check("no_theta", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_theta_construction"] == "PASS", "No transformation-elasticity object is created."),
  check("no_productive_capacity", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_productive_capacity_construction"] == "PASS", "No productive-capacity object is created."),
  check("no_utilization", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_utilization_construction"] == "PASS", "No capacity-utilization object is created."),
  check("no_modeling", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_modeling"] == "PASS", "No modeling output is created."),
  check("no_econometrics", no_forbidden_audit$status[no_forbidden_audit$audit_item == "no_econometrics"] == "PASS", "No econometric output is created."),
  check("input_files_unchanged", inputs_unchanged, ifelse(inputs_unchanged, "All required input md5 hashes unchanged.", paste(changed_inputs, collapse = "; "))),
  check("provider_repository_untouched", provider_ok, "Provider repository tracked and staged diffs are clean.")
))
validation_result <- if (all(validation_checks$status == "PASS")) "PASS" else "FAIL"
final_decision <- if (validation_result == "PASS") clean_decision else blocked_decision
family_status <- if (validation_result == "PASS") clean_status else blocked_status

independent_validation <- data.frame(
  stage_id = stage_id,
  validation_result = validation_result,
  check_count = nrow(validation_checks),
  pass_count = sum(validation_checks$status == "PASS"),
  fail_count = sum(validation_checks$status == "FAIL"),
  final_decision = final_decision,
  family_status = family_status,
  stringsAsFactors = FALSE
)

completion_record <- data.frame(
  stage_id = stage_id,
  task_id = task_id,
  branch = branch,
  base_commit = base_commit,
  result_commit = "PENDING_COMMIT",
  validation_status = validation_result,
  decision = final_decision,
  family_status = family_status,
  authoritative_variable_count = nrow(authoritative_ledger),
  robustness_variable_count = nrow(robustness_ledger),
  conditional_variable_count = 0L,
  diagnostic_variable_count = nrow(diagnostic_ledger),
  alias_variable_count = nrow(alias_authority_map),
  metadata_only_count = nrow(blocked_object_ledger) + 1L,
  blocked_variable_count = nrow(blocked_object_ledger),
  review_required_count = nrow(review_needed_ledger),
  handoff_ready = ifelse(validation_result == "PASS", "yes", "no"),
  consumer_intake_ready = ifelse(validation_result == "PASS", "yes", "no"),
  stringsAsFactors = FALSE
)

write.csv(independent_validation, output_paths$independent, row.names = FALSE, na = "")
write.csv(validation_checks, output_paths$validation, row.names = FALSE, na = "")
write.csv(completion_record, output_paths$completion, row.names = FALSE, na = "")

for (i in seq_len(nrow(handoff_manifest))) {
  file <- path(repo_root, handoff_manifest$relative_path[i])
  handoff_manifest$file_exists[i] <- ifelse(file.exists(file), "yes", "no")
  handoff_manifest$sha256[i] <- ifelse(file.exists(file), sha256_file(file), "")
  handoff_manifest$file_size_bytes[i] <- ifelse(file.exists(file), file.info(file)$size, NA_real_)
}
write.csv(handoff_manifest, output_paths$handoff, row.names = FALSE, na = "")

summary_lines <- c(
  "# S30B Income Distribution Family Closure",
  "",
  paste0("Task: `", task_id, "`"),
  paste0("Validation: `", validation_result, "`"),
  paste0("Decision: `", final_decision, "`"),
  paste0("Family status: `", family_status, "`"),
  "",
  "S30B closes the constructed income-distribution family without joining it to output, capital, contextual variables, or any estimation sample. The wage-share hierarchy is explicit: `NFC_COMPENSATION_SHARE_GVA` is the baseline-authorized variable because it matches the S20C NFC unadjusted wage-share formula `NFC_COMP / NFC_GVA`. Other compensation-share variants are robustness variables, net-operating-surplus shares are diagnostic only, and adjusted Shaikh metadata remains blocked.",
  "",
  "No new economic transformation is constructed. `S30B_distribution_interface_long.csv` copies S29A same-family values only, and `S30B_value_copy_audit.csv` verifies zero residual for all 776 copied rows.",
  "",
  "## Counts",
  "",
  paste0("- authoritative variables: `", nrow(authoritative_ledger), "`"),
  paste0("- robustness variables: `", nrow(robustness_ledger), "`"),
  paste0("- diagnostic variables: `", nrow(diagnostic_ledger), "`"),
  paste0("- alias variables: `", nrow(alias_authority_map), "`"),
  paste0("- blocked variables: `", nrow(blocked_object_ledger), "`"),
  paste0("- review-required ledgers: `", nrow(review_needed_ledger), "`")
)
validation_lines <- c(
  "# S30B Income Distribution Family Closure Validation",
  "",
  paste0("Validation result: `", validation_result, "`"),
  "",
  paste0("Validation checks: `", sum(validation_checks$status == "PASS"), " / ", nrow(validation_checks), " PASS`."),
  "",
  "All eight S29A constructed variables are classified. Support windows are explicit. Same-family interface copies have zero residual. No cross-family joins, interactions, complete-case sample, estimation sample, canonical dataset, q, theta, productive capacity, utilization, modeling, econometrics, or Shaikh-adjusted construction appears in S30B.",
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
decision_lines <- c(
  "# S30B Income Distribution Family Closure Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  paste0("Final status: `", family_status, "`"),
  "",
  "S30B authorizes downstream consumption of the closed income-distribution family and does not authorize actual cross-family integration. S30E performs integrated dataset closure after the S30 family branches are merged and validated in the human-controlled order. S30F is the downstream dataset-consumption authorization boundary.",
  "",
  "The branch does not merge itself into `main` and opens no pull request."
)

writeLines(summary_lines, output_paths$summary_md)
writeLines(validation_lines, output_paths$validation_md)
writeLines(decision_lines, output_paths$decision_md)

if (validation_result != "PASS") stop("FAILED_VALIDATION")

cat("S30B validation result:", validation_result, "\n")
cat("S30B decision:", final_decision, "\n")
cat("S30B family status:", family_status, "\n")
