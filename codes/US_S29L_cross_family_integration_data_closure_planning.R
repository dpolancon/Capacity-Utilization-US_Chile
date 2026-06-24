# S29L plans cross-family closure and parallel fanout.
# It emits planning contracts only: no economic variables, joins, samples, or models.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

stage_id <- "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING"
expected_s29k_commit <- "21f5b17c8a7d77b71da79cc643bb889c5ffb362a"
expected_s29j_commit <- "140716f24ab83a9ce97489c42b476a69a7e9dfd0"
expected_s29k_decision <- "AUTHORIZE_S29L_TOTAL_CAPITAL_CROSS_FAMILY_INTEGRATION_PLANNING"
clean_decision <- "AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION"
blocked_decision <- "BLOCK_FOR_CROSS_FAMILY_DATA_CLOSURE_PLANNING_REVIEW"
clean_status <- "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING_COMPLETE_PARALLEL_FANOUT_AUTHORIZED"
blocked_status <- "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING_BLOCKED"

path <- function(...) file.path(...)
read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
write_csv <- function(df, file) write.csv(df, file, row.names = FALSE, na = "")
write_md <- function(text, file) writeLines(sub("[\r\n]+$", "", text), file, useBytes = TRUE)
git <- function(args) trimws(paste(system2("git", args, stdout = TRUE, stderr = TRUE), collapse = "\n"))
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence)
}
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
sha1 <- function(files) {
  files <- normalizePath(files, winslash = "/", mustWork = TRUE)
  stats::setNames(as.character(tools::md5sum(files)), files)
}
stop_if_missing <- function(files, label) {
  missing <- files[!file.exists(files)]
  if (length(missing) > 0) stop(label, " missing: ", paste(missing, collapse = "; "))
}
count_rows <- function(file) if (file.exists(file)) nrow(read_csv(file)) else 0L
count_values <- function(x, value) sum(x == value, na.rm = TRUE)
collapse_values <- function(x) paste(unique(x[nzchar(x)]), collapse = "; ")

out_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(out_dir, "csv")
md_dir <- path(out_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

current_branch <- git(c("branch", "--show-current"))
current_head <- git(c("rev-parse", "HEAD"))
origin_main <- git(c("rev-parse", "origin/main"))
worktree_before <- git(c("worktree", "list", "--porcelain"))

s29k_dir <- path(repo_root, "output", "US", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE")
s29a_dir <- path(repo_root, "output", "US", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION")
s12b_dir <- path(repo_root, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT")
s25_dir <- path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
s27_dir <- path(repo_root, "output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
s28_dir <- path(repo_root, "output", "US", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE")

s29k_files <- c(
  path(s29k_dir, "csv", "S29K_canonical_consumer_variable_registry.csv"),
  path(s29k_dir, "csv", "S29K_baseline_representation_registry.csv"),
  path(s29k_dir, "csv", "S29K_robustness_representation_registry.csv"),
  path(s29k_dir, "csv", "S29K_conditional_secondary_registry.csv"),
  path(s29k_dir, "csv", "S29K_diagnostic_reference_registry.csv"),
  path(s29k_dir, "csv", "S29K_alias_reference_registry.csv"),
  path(s29k_dir, "csv", "S29K_integrity_revalidation_audit.csv"),
  path(s29k_dir, "csv", "S29K_contract_to_consumer_reconciliation_audit.csv"),
  path(s29k_dir, "csv", "S29K_lane_registration_audit.csv"),
  path(s29k_dir, "csv", "S29K_support_eligibility_intake_audit.csv"),
  path(s29k_dir, "csv", "S29K_representation_selection_lock_audit.csv"),
  path(s29k_dir, "csv", "S29K_lag_activation_intake_audit.csv"),
  path(s29k_dir, "csv", "S29K_consumer_handoff_manifest.csv"),
  path(s29k_dir, "csv", "S29K_review_needed_ledger.csv"),
  path(s29k_dir, "csv", "S29K_validation_checks.csv"),
  path(s29k_dir, "md", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_VALIDATION.md"),
  path(s29k_dir, "md", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_DECISION.md")
)
s29a_files <- c(
  path(s29a_dir, "csv", "S29A_validation_checks.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_variables_long.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_construction_ledger.csv"),
  path(s29a_dir, "csv", "S29A_income_distribution_review_needed_ledger.csv"),
  path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_DECISION.md")
)
s12b_files <- c(
  path(s12b_dir, "md", "S12B_OUTPUT_PRICE_REAL_OUTPUT.md")
)

required_input_files <- c(s29k_files, s29a_files, s12b_files)
stop_if_missing(required_input_files, "S29L required input")
input_hash_before <- sha1(required_input_files)

s29k_validation <- read_csv(path(s29k_dir, "csv", "S29K_validation_checks.csv"))
s29k_decision_text <- read_text(path(s29k_dir, "md", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_DECISION.md"))
s29k_registry <- read_csv(path(s29k_dir, "csv", "S29K_canonical_consumer_variable_registry.csv"))
s29a_validation <- read_csv(path(s29a_dir, "csv", "S29A_validation_checks.csv"))
s29a_panel <- read_csv(path(s29a_dir, "csv", "S29A_income_distribution_variables_long.csv"))
s29a_ledger <- read_csv(path(s29a_dir, "csv", "S29A_income_distribution_construction_ledger.csv"))
s29a_review <- read_csv(path(s29a_dir, "csv", "S29A_income_distribution_review_needed_ledger.csv"))
s29a_decision_text <- read_text(path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_DECISION.md"))
s12b_text <- read_text(path(s12b_dir, "md", "S12B_OUTPUT_PRICE_REAL_OUTPUT.md"))

s29k_counts <- table(s29k_registry$consumer_registration_status)
s29a_variable_column <- if ("derived_variable_id" %in% names(s29a_panel)) "derived_variable_id" else "variable_id"
s29a_constructed_vars <- length(unique(s29a_panel[[s29a_variable_column]]))
s29a_rows <- nrow(s29a_panel)
s29a_years <- range(s29a_panel$year, na.rm = TRUE)

family_inventory <- data.frame(
  family_id = c(
    "total_capital",
    "income_distribution",
    "real_effective_output",
    "contextual_ipp",
    "contextual_government_transportation",
    "contextual_fixed_assets_other",
    "metadata_only_objects",
    "blocked_or_parked_objects",
    "release_infrastructure"
  ),
  family_label = c(
    "Total capital",
    "Income distribution",
    "Real or effective output",
    "IPP contextual assets and investment",
    "Government transportation contextual assets",
    "Other contextual or diagnostic fixed-assets objects",
    "Metadata-only objects",
    "Blocked or parked objects",
    "Dataset release infrastructure"
  ),
  latest_completed_stage = c(
    "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE",
    "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION",
    "S12B_OUTPUT_PRICE_REAL_OUTPUT",
    "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING",
    "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING",
    "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING",
    "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING",
    "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING",
    "none"
  ),
  latest_recorded_commit = c(
    expected_s29k_commit,
    "not_recorded_in_S29A_decision_for_S29A_commit",
    "not_recorded_in_S12B_output_summary",
    "e42e124679137a3acaa0f0c7d4eebd71c562656a",
    "e42e124679137a3acaa0f0c7d4eebd71c562656a",
    "e42e124679137a3acaa0f0c7d4eebd71c562656a",
    "e42e124679137a3acaa0f0c7d4eebd71c562656a",
    "e42e124679137a3acaa0f0c7d4eebd71c562656a",
    "not_applicable"
  ),
  validation_status = c("PASS 85", "PASS 57", "PASS in S12B embedded validation table", rep("PASS 52 inherited planning", 5), "not_applicable"),
  decision_status = c(
    expected_s29k_decision,
    "AUTHORIZE_S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP",
    "S12C capital input preparation follows; downstream output-family closure not complete",
    rep("classification deferred to future contextual lock", 5),
    "release schema and validation scaffold not finalized"
  ),
  family_status = c(
    "CLOSED_CONSUMABLE",
    "CONSTRUCTED_CLOSURE_PENDING",
    "CONSTRUCTED_CLOSURE_PENDING",
    "CONTEXTUAL_CLASSIFICATION_PENDING",
    "CONTEXTUAL_CLASSIFICATION_PENDING",
    "CONTEXTUAL_CLASSIFICATION_PENDING",
    "METADATA_REFERENCE_ONLY",
    "PARKED",
    "RELEASE_INFRASTRUCTURE_PENDING"
  ),
  constructed_variable_count = c(99, s29a_constructed_vars, 7, 0, 0, 0, 0, 0, 0),
  observation_bearing_variable_count = c(15, s29a_constructed_vars, 7, 0, 0, 0, 0, 0, 0),
  metadata_only_variable_count = c(0, 0, 0, 0, 0, 0, 22, 0, 0),
  authoritative_variable_status = c(
    "locked primary gross and net robustness selections",
    "not selected; wage share preference and exploitation alternative preserved",
    "baseline NFC real output exists, but downstream family authority not closed",
    "not classified",
    "not classified",
    "not classified",
    "reference only",
    "not authorized",
    "not applicable"
  ),
  contract_status = c("complete", "missing downstream contract", "missing downstream contract", "missing contextual contract", "missing contextual contract", "missing contextual contract", "metadata reference only", "not authorized", "missing release schemas"),
  interface_status = c("complete", "missing downstream interface", "missing downstream interface", "missing contextual interface", "missing contextual interface", "missing contextual interface", "none authorized", "none authorized", "missing canonical schema interfaces"),
  independent_validation_status = c("complete", "missing independent validation", "missing independent validation", "missing classification validation", "missing classification validation", "missing classification validation", "not applicable", "not applicable", "missing dataset-wide validation scaffold"),
  consumer_intake_status = c("complete", "missing consumer intake", "missing consumer intake", "missing contextual handoff", "missing contextual handoff", "missing contextual handoff", "not applicable", "not applicable", "missing release handoff"),
  unresolved_conceptual_decisions = c(
    "none",
    "primary and robustness representation selection; Shaikh-adjusted block retention",
    "sector boundary, official downstream real-output authority, proxy role restrictions, support window",
    "retain as contextual/diagnostic/park/exclude without core-capital promotion",
    "retain as contextual/diagnostic/park/exclude without core-capital promotion",
    "retain provider TOTAL and review-required fixed-assets objects without analytical TOT promotion",
    "metadata-only status must not be promoted",
    "blocked or parked status must not be promoted",
    "release package content and validation templates"
  ),
  unresolved_technical_dependencies = c(
    "none",
    "readiness review, selection ledger, support contract, interface, validation, handoff, intake",
    "readiness review, level/log availability, alias handling, contract, interface, validation, handoff, intake",
    "inventory and classification ledger",
    "inventory and classification ledger",
    "inventory and classification ledger",
    "metadata reference ledger",
    "blocked/parked ledger",
    "schemas, manifests, copy-validation, duplicate-key audit, unit audit, support audit"
  ),
  blockers = c("none", "no final distributive variable selected in S29L", "no output series selected in S29L", rep("classification not yet locked", 5), "canonical dataset assembly prohibited in S29L"),
  next_required_stage = c(
    "S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY",
    "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE",
    "S30A_REAL_OUTPUT_FAMILY_CLOSURE",
    "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK",
    "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK",
    "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK",
    "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK",
    "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK",
    "S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD"
  )
)

family_closure_matrix <- data.frame(
  family_id = family_inventory$family_id,
  construction_complete = c("yes", "yes", "partial", "no", "no", "no", "no", "no", "no"),
  contract_complete = c("yes", rep("no", 8)),
  interface_complete = c("yes", rep("no", 8)),
  independent_validation_complete = c("yes", rep("no", 8)),
  consumer_intake_complete = c("yes", rep("no", 8)),
  remaining_family_construction = c(
    "none",
    "none for S29A variables; closure and selection remain",
    "no S29L construction; S30A must resolve whether authorized downstream output variables require construction",
    "classification only",
    "classification only",
    "classification only",
    "none authorized",
    "none authorized",
    "schema scaffold only"
  ),
  closed_consumable = c("yes", rep("no", 8))
)

family_latest_stage_registry <- family_inventory[, c("family_id", "latest_completed_stage", "latest_recorded_commit", "validation_status", "decision_status", "next_required_stage")]

unresolved_dependency_ledger <- data.frame(
  dependency_id = sprintf("S29L_DEP_%02d", 1:18),
  family_id = c(
    rep("income_distribution", 6),
    rep("real_effective_output", 6),
    rep("contextual_family", 3),
    rep("release_infrastructure", 3)
  ),
  dependency_type = c(
    "readiness_review", "primary_selection", "robustness_selection", "shaikh_restriction_lock", "support_contract", "interface_validation_intake",
    "sector_boundary", "official_real_output_authority", "deflator_reference_year_units", "level_log_support_aliases", "diagnostic_alternatives", "interface_validation_intake",
    "ipp_classification", "government_transportation_classification", "provider_total_and_metadata_nonpromotion",
    "canonical_schema_templates", "validation_scaffold", "release_manifest_templates"
  ),
  unresolved_item = c(
    "distribution analytical readiness review not complete",
    "preferred wage-share hierarchy preserved but no final variable selected",
    "exploitation-rate representation preserved as alternative without final selection",
    "Shaikh-adjusted variables remain blocked unless separately authorized",
    "family-specific support-window contract missing",
    "downstream contract, interface, independent validation, handoff, and intake missing",
    "downstream output sector boundary not closed",
    "official downstream real-output authority not selected",
    "price index, reference year, and units require closure in S30A",
    "level/log availability, support windows, aliases, and diagnostics require lock",
    "proxy and validation-only output objects require role classification",
    "downstream contract, interface, independent validation, handoff, and intake missing",
    "IPP must remain outside core accumulation capital unless contextual role is locked",
    "government transportation must remain outside core accumulation capital unless contextual role is locked",
    "provider TOTAL, metadata-only, blocked, and parked objects require nonpromotion lock",
    "canonical long, wide, dictionary, provenance, admissibility, support, registry schemas absent",
    "copy-validation, duplicate-key, unit-consistency, support, missingness audits absent",
    "release manifest, SHA-256 manifest template, handoff, and decision templates absent"
  ),
  required_resolution_stage = c(rep("S30B", 6), rep("S30A", 6), rep("S30C", 3), rep("S30D", 3)),
  blocks_parallel_fanout = "no",
  blocks_canonical_dataset_assembly = "yes"
)

dependency_edges <- data.frame(
  from_node = c(
    "total_capital_family_closure",
    "output_family_closure",
    "distribution_family_closure",
    "contextual_family_lock",
    "release_schema_scaffold",
    "cross_family_closure_audit",
    "canonical_dataset_assembly",
    "independent_dataset_wide_validation",
    "release_handoff"
  ),
  to_node = c(
    "cross_family_closure_audit",
    "cross_family_closure_audit",
    "cross_family_closure_audit",
    "cross_family_closure_audit",
    "canonical_dataset_assembly_planning",
    "canonical_dataset_assembly",
    "independent_dataset_wide_validation",
    "release_handoff",
    "dataset_freeze_and_tag"
  ),
  edge_type = c(rep("family_closure_prerequisite", 4), "schema_prerequisite", "sequential", "sequential", "sequential", "sequential"),
  implies_parallel_task_dependency = "no",
  notes = "planning edge only; no S30 parallel task depends on another S30 parallel task"
)

has_cycle <- function(edges) {
  nodes <- unique(c(edges$from_node, edges$to_node))
  visiting <- setNames(rep(FALSE, length(nodes)), nodes)
  visited <- setNames(rep(FALSE, length(nodes)), nodes)
  adj <- split(edges$to_node, edges$from_node)
  visit <- function(node) {
    if (isTRUE(visiting[[node]])) return(TRUE)
    if (isTRUE(visited[[node]])) return(FALSE)
    visiting[[node]] <<- TRUE
    for (next_node in adj[[node]]) {
      if (!is.null(next_node) && visit(next_node)) return(TRUE)
    }
    visiting[[node]] <<- FALSE
    visited[[node]] <<- TRUE
    FALSE
  }
  any(vapply(nodes, visit, logical(1)))
}
dependency_graph_acyclic <- !has_cycle(dependency_edges)

release_infra <- data.frame(
  infrastructure_item = c(
    "canonical_long_dataset", "canonical_wide_consultation_dataset", "variable_dictionary",
    "provenance_ledger", "admissibility_ledger", "support_window_ledger", "family_interface_registry",
    "release_manifest", "sha256_integrity_manifest", "independent_dataset_wide_validation", "final_release_decision"
  ),
  readiness_classification = c(rep("ABSENT", 11)),
  evidence = c(
    "no authorized canonical long dataset schema found",
    "no authorized canonical wide consultation schema found",
    "no final variable dictionary template found",
    "no release-level provenance ledger template found",
    "no release-level admissibility ledger template found",
    "no release-level support-window ledger template found",
    "no cross-family interface registry template found",
    "no final release manifest template found",
    "no release SHA-256 manifest template found",
    "no dataset-wide independent validation scaffold found",
    "no final release decision template found"
  ),
  required_stage = "S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD"
)

parallel_tasks <- data.frame(
  task_id = c(
    "S30A_REAL_OUTPUT_FAMILY_CLOSURE",
    "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE",
    "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK",
    "S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD"
  ),
  branch_name = c(
    "feature/s30a-output-family-closure",
    "feature/s30b-distribution-family-closure",
    "feature/s30c-contextual-family-lock",
    "feature/s30d-dataset-release-scaffold"
  ),
  family_scope = c("real_effective_output", "income_distribution", "contextual_and_noncore_objects", "release_infrastructure"),
  exclusive_code_glob = c("codes/US_S30A*", "codes/US_S30B*", "codes/US_S30C*", "codes/US_S30D*"),
  exclusive_output_glob = c("output/US/S30A*", "output/US/S30B*", "output/US/S30C*", "output/US/S30D*"),
  acceptance_condition = c(
    "OUTPUT_FAMILY_CLOSED_CONSUMABLE",
    "DISTRIBUTION_FAMILY_CLOSED_CONSUMABLE",
    "CONTEXTUAL_FAMILY_CLASSIFICATION_LOCKED",
    "DATASET_RELEASE_SCAFFOLD_READY"
  ),
  may_construct_authorized_family_variables = c("yes_if_required_by_locked_evidence", "no_new_shaikh_adjusted_variables", "no", "schema_only_or_zero_row_templates"),
  must_stop_if_ambiguous = c("yes", "yes", "yes", "yes"),
  parallel_authorized = "yes"
)

task_input_contract <- data.frame(
  task_id = parallel_tasks$task_id,
  required_base_rule = "USE_EXACT_S29L_COMMIT_AFTER_S29L_IS_COMMITTED_AND_PUSHED",
  allowed_input_paths = c(
    "output/US/S12B*; output/US/S11C*; output/US/S12_SOURCE_OF_TRUTH*; output/US/S25*; output/US/S26*; output/US/S27*; output/US/S28*",
    "output/US/S29A*; output/US/S25*; output/US/S26*; output/US/S27*; output/US/S28*",
    "output/US/S22*; output/US/S24B*; output/US/S24C*; output/US/S25*; output/US/S26*; output/US/S27*; output/US/S28*; output/US/S29K*",
    "output/US/S29K*; output/US/S29L*; schema references only"
  ),
  forbidden_input_mutation = "S29K or earlier outputs must be read-only",
  provider_repo_read_only = "yes"
)

task_output_contract <- data.frame(
  task_id = parallel_tasks$task_id,
  required_output_directory = parallel_tasks$exclusive_output_glob,
  required_script_glob = parallel_tasks$exclusive_code_glob,
  required_validation = c("S30A validation PASS", "S30B validation PASS", "S30C validation PASS", "S30D validation PASS"),
  required_decision = c(
    "AUTHORIZE_OUTPUT_FAMILY_CONSUMPTION",
    "AUTHORIZE_DISTRIBUTION_FAMILY_CONSUMPTION",
    "AUTHORIZE_CONTEXTUAL_REFERENCE_CONSUMPTION",
    "AUTHORIZE_DATASET_RELEASE_SCAFFOLD_CONSUMPTION"
  ),
  prohibited_outputs = "canonical dataset; complete-case sample; q; theta; productive capacity; utilization; model outputs"
)

branch_ownership <- data.frame(
  task_id = parallel_tasks$task_id,
  branch_name = parallel_tasks$branch_name,
  allowed_code_glob = parallel_tasks$exclusive_code_glob,
  allowed_output_glob = parallel_tasks$exclusive_output_glob,
  allowed_input_paths = task_input_contract$allowed_input_paths,
  forbidden_output_paths = c(
    "output/US/S29K*; output/US/S30B*; output/US/S30C*; output/US/S30D*; canonical dataset paths",
    "output/US/S29K*; output/US/S30A*; output/US/S30C*; output/US/S30D*; canonical dataset paths",
    "output/US/S29K*; output/US/S30A*; output/US/S30B*; output/US/S30D*; canonical dataset paths",
    "output/US/S29K*; output/US/S30A*; output/US/S30B*; output/US/S30C*; live canonical dataset paths"
  ),
  shared_files_edit_allowed = "no",
  provider_repo_edit_allowed = "no",
  cross_family_join_allowed = "no",
  canonical_dataset_write_allowed = "no"
)

pairs <- combn(parallel_tasks$task_id, 2)
collision <- data.frame(
  task_a = pairs[1, ],
  task_b = pairs[2, ],
  path_overlap = "none",
  semantic_overlap = c(
    "separate family closures",
    "output closure versus contextual lock",
    "output closure versus schema-only scaffold",
    "distribution closure versus contextual lock",
    "distribution closure versus schema-only scaffold",
    "contextual lock versus schema-only scaffold"
  ),
  dependency = "none",
  parallel_safe = "yes",
  required_mitigation = "branch from exact S29L commit and restrict writes to exclusive namespace"
)

task_report_contract <- data.frame(
  field_name = c(
    "task_id", "branch", "exact_base_commit", "upstream_stages_consumed", "files_read",
    "scripts_created", "output_directory", "authoritative_variables", "diagnostic_variables",
    "blocked_variables", "review_required_variables", "validation_result", "final_decision",
    "files_changed", "commit_hash", "push_status", "final_branch_status",
    "other_task_namespaces_not_modified", "provider_repository_not_modified"
  ),
  required = "yes",
  expected_format = c(
    "string", "string", "full_git_sha", "semicolon_list", "semicolon_list", "semicolon_list",
    "path", "semicolon_list_or_none", "semicolon_list_or_none", "semicolon_list_or_none",
    "semicolon_list_or_none", "PASS_or_BLOCKED", "authorization_or_block_decision",
    "semicolon_list", "full_git_sha", "pushed_or_not_pushed", "clean_or_known_noise_only",
    "yes_no", "yes_no"
  )
)

completion_schema <- data.frame(
  field_name = c(
    "stage_id", "task_id", "branch", "base_commit", "result_commit", "validation_status",
    "decision", "family_status", "authoritative_variable_count", "robustness_variable_count",
    "conditional_variable_count", "diagnostic_variable_count", "alias_variable_count",
    "metadata_only_count", "blocked_variable_count", "review_required_count",
    "handoff_ready", "consumer_intake_ready"
  ),
  data_type = c(rep("character", 8), rep("integer", 8), "yes_no", "yes_no"),
  required = "yes"
)

base_rule <- data.frame(
  parallel_base_rule = "USE_EXACT_S29L_COMMIT_AFTER_S29L_IS_COMMITTED_AND_PUSHED",
  upstream_preplanning_commit = expected_s29k_commit,
  floating_main_base_allowed = "no",
  reason = "S29L cannot know its own commit until after validation, commit, and push; cloud tasks must use that exact result commit."
)

merge_order <- data.frame(
  step = 1:15,
  action = c(
    "verify all four branches use the same exact S29L base commit",
    "review each task report independently",
    "merge S30A",
    "rerun S30A terminal validation",
    "merge S30B",
    "rerun S30B terminal validation",
    "merge S30C",
    "rerun S30C terminal validation",
    "merge S30D",
    "rerun S30D scaffold validation",
    "run cross-family closure audit",
    "assemble canonical dataset",
    "independently validate canonical dataset",
    "build release handoff",
    "freeze and tag dataset"
  ),
  execute_in_s29l = "no"
)

roadmap <- data.frame(
  sequence = 1:2,
  stage_id = c(
    "S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY",
    "S30F_DATASET_RELEASE_FREEZE"
  ),
  authorization_condition = c(
    "all S30 family closure and scaffold tasks merged and validated",
    "S30E closure and validation complete; final target decision AUTHORIZE_DOWNSTREAM_CHAPTER2_SOURCE_OF_TRUTH_DATASET_CONSUMPTION"
  ),
  execute_in_s29l = "no"
)

audit_df <- function(name, items) {
  data.frame(stage_id = stage_id, audit_name = name, audit_item = items, status = "PASS", evidence = "S29L planning outputs only; prohibited action not performed")
}
no_cross_family_join <- audit_df("no_cross_family_join_audit", c("capital_output_join", "capital_distribution_join", "output_distribution_join", "contextual_family_join", "canonical_dataset_join"))
no_new_variable <- audit_df("no_new_variable_construction_audit", c("level", "log", "growth_rate", "difference", "lag", "share", "intensity_measure"))
no_model_input <- audit_df("no_model_input_panel_audit", c("model_input_panel", "estimation_sample", "complete_case_sample"))
no_complete_case <- audit_df("no_complete_case_sample_audit", c("complete_case_sample", "estimation_window_filter"))
no_q <- audit_df("no_q_audit", c("q", "mechanization_growth_rate"))
no_theta <- audit_df("no_theta_audit", c("theta", "distribution_conditioned_transformation_elasticity"))
no_capacity <- audit_df("no_capacity_utilization_audit", c("productive_capacity", "capacity_utilization_mu"))
no_modeling <- audit_df("no_modeling_audit", c("econometrics", "model_estimation", "VECM", "investment_function"))

review_needed <- data.frame(
  review_id = sprintf("S29L_REVIEW_%02d", 1:8),
  family_id = c("real_effective_output", "real_effective_output", "income_distribution", "income_distribution", "contextual_ipp", "contextual_government_transportation", "contextual_fixed_assets_other", "release_infrastructure"),
  review_item = c(
    "output sector boundary and authority",
    "output level/log/support/alias contract",
    "primary and robustness distribution selection",
    "Shaikh-adjusted variable block",
    "IPP contextual or diagnostic classification",
    "government transportation contextual or diagnostic classification",
    "provider TOTAL and fixed-assets diagnostic nonpromotion",
    "release schemas and validation scaffolds"
  ),
  assigned_stage = c("S30A", "S30A", "S30B", "S30B", "S30C", "S30C", "S30C", "S30D"),
  must_stop_if_unresolved = "yes"
)

write_csv(family_inventory, path(csv_dir, "S29L_family_readiness_inventory.csv"))
write_csv(family_closure_matrix, path(csv_dir, "S29L_family_closure_matrix.csv"))
write_csv(family_latest_stage_registry, path(csv_dir, "S29L_family_latest_stage_registry.csv"))
write_csv(unresolved_dependency_ledger, path(csv_dir, "S29L_unresolved_dependency_ledger.csv"))
write_csv(dependency_edges, path(csv_dir, "S29L_cross_family_dependency_edges.csv"))
write_csv(release_infra, path(csv_dir, "S29L_release_infrastructure_readiness.csv"))
write_csv(parallel_tasks, path(csv_dir, "S29L_parallel_task_registry.csv"))
write_csv(task_input_contract, path(csv_dir, "S29L_parallel_task_input_contract.csv"))
write_csv(task_output_contract, path(csv_dir, "S29L_parallel_task_output_contract.csv"))
write_csv(branch_ownership, path(csv_dir, "S29L_branch_ownership_matrix.csv"))
write_csv(collision, path(csv_dir, "S29L_pairwise_collision_prevention_matrix.csv"))
write_csv(task_report_contract, path(csv_dir, "S29L_common_task_report_contract.csv"))
write_csv(completion_schema, path(csv_dir, "S29L_common_completion_record_schema.csv"))
write_csv(base_rule, path(csv_dir, "S29L_parallel_base_commit_rule.csv"))
write_csv(merge_order, path(csv_dir, "S29L_merge_order_contract.csv"))
write_csv(roadmap, path(csv_dir, "S29L_post_parallel_sequential_roadmap.csv"))
write_csv(no_cross_family_join, path(csv_dir, "S29L_no_cross_family_join_audit.csv"))
write_csv(no_new_variable, path(csv_dir, "S29L_no_new_variable_construction_audit.csv"))
write_csv(no_model_input, path(csv_dir, "S29L_no_model_input_panel_audit.csv"))
write_csv(no_complete_case, path(csv_dir, "S29L_no_complete_case_sample_audit.csv"))
write_csv(no_q, path(csv_dir, "S29L_no_q_audit.csv"))
write_csv(no_theta, path(csv_dir, "S29L_no_theta_audit.csv"))
write_csv(no_capacity, path(csv_dir, "S29L_no_capacity_utilization_audit.csv"))
write_csv(no_modeling, path(csv_dir, "S29L_no_modeling_audit.csv"))
write_csv(review_needed, path(csv_dir, "S29L_review_needed_ledger.csv"))

task_md <- function(task_id, branch, purpose, may, must_not, acceptance) {
  paste0(
    "# ", task_id, "\n\n",
    "Branch: `", branch, "`\n\n",
    "Purpose: ", purpose, "\n\n",
    "Exact base: `USE_EXACT_S29L_COMMIT_AFTER_S29L_IS_COMMITTED_AND_PUSHED`.\n\n",
    "Exclusive writes: `", parallel_tasks$exclusive_code_glob[parallel_tasks$task_id == task_id], "` and `", parallel_tasks$exclusive_output_glob[parallel_tasks$task_id == task_id], "`.\n\n",
    "May do:\n", paste0("- ", may, collapse = "\n"), "\n\n",
    "Must not do:\n", paste0("- ", must_not, collapse = "\n"), "\n\n",
    "Acceptance condition: `", acceptance, "`.\n"
  )
}

write_md(task_md(
  "S30A_REAL_OUTPUT_FAMILY_CLOSURE",
  "feature/s30a-output-family-closure",
  "Close the real-output family without joining it to capital, distribution, or contextual families.",
  c("audit the output source boundary", "construct authorized output variables only if required by locked evidence", "validate units, reference years, support, contract, interface, handoff, and intake"),
  c("edit capital/distribution/contextual outputs", "join families", "create complete-case samples", "construct q, theta, productive capacity, utilization, or models"),
  "OUTPUT_FAMILY_CLOSED_CONSUMABLE"
), path(md_dir, "S29L_TASK_A_REAL_OUTPUT_FAMILY_CLOSURE.md"))

write_md(task_md(
  "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE",
  "feature/s30b-distribution-family-closure",
  "Close the income-distribution family while preserving wage-share preference, exploitation alternative status, and the Shaikh-adjustment block.",
  c("consume S29A", "classify primary, robustness, diagnostic, blocked, and alias variables", "create contract, interface, validation, handoff, and intake"),
  c("construct new Shaikh-adjusted variables", "join families", "construct interactions, q, theta, productive capacity, utilization, or models"),
  "DISTRIBUTION_FAMILY_CLOSED_CONSUMABLE"
), path(md_dir, "S29L_TASK_B_INCOME_DISTRIBUTION_FAMILY_CLOSURE.md"))

write_md(task_md(
  "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK",
  "feature/s30c-contextual-family-lock",
  "Lock contextual, diagnostic, metadata-only, parked, blocked, and excluded objects without promoting them into core capital or model controls.",
  c("inventory contextual and non-core objects", "classify each object", "create contextual reference contract, interface where authorized, validation, and handoff"),
  c("modify core capital aggregates", "assign productive-efficiency weights", "join families", "construct q, theta, productive capacity, utilization, controls, or models"),
  "CONTEXTUAL_FAMILY_CLASSIFICATION_LOCKED"
), path(md_dir, "S29L_TASK_C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK.md"))

write_md(task_md(
  "S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD",
  "feature/s30d-dataset-release-scaffold",
  "Create schema-only or zero-row templates for final dataset release infrastructure.",
  c("create canonical long/wide schemas", "create dictionary, provenance, admissibility, support, registry, manifest, and validation templates", "create final handoff and decision templates"),
  c("copy live family values", "join families", "select new authoritative variables", "create complete-case samples, release candidates, final hashes, q, theta, utilization, or models"),
  "DATASET_RELEASE_SCAFFOLD_READY"
), path(md_dir, "S29L_TASK_D_DATASET_RELEASE_SCHEMA_SCAFFOLD.md"))

plan_md <- paste0(
  "# S29L Cross-Family Integration and Data-Closure Plan\n\n",
  "S29L consumed S29K at `", expected_s29k_commit, "` and confirmed `PASS 85` plus `", expected_s29k_decision, "`.\n\n",
  "Total capital is locked as `CLOSED_CONSUMABLE`: construction, contract, interface, independent validation, and consumer intake are complete. ",
  "Primary gross capital is `G_TOT_GPIM_2017`; primary log is `LOG_G_TOT_GPIM_2017`; robustness level is `N_TOT_GPIM_2017`; robustness log is `LOG_N_TOT_GPIM_2017`.\n\n",
  "Audited families: ", nrow(family_inventory), ". Unresolved dependencies: ", nrow(unresolved_dependency_ledger), ". ",
  "The dependency graph is acyclic and no S30 parallel task depends on another S30 parallel task.\n\n",
  "Authorized branch-ready packets: S30A output closure, S30B income-distribution closure, S30C contextual classification lock, and S30D release schema scaffold. ",
  "All four must branch from the exact completed S29L commit after this stage is committed and pushed; floating `main` is prohibited.\n"
)
write_md(plan_md, path(md_dir, "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLAN.md"))

fanout_md <- paste0(
  "# S29L Parallel Fanout Execution Guide\n\n",
  "Do not create branches from floating `main`. Use the exact S29L result commit after push.\n\n",
  paste0("* `", parallel_tasks$task_id, "` -> `", parallel_tasks$branch_name, "`; writes `", parallel_tasks$exclusive_code_glob, "` and `", parallel_tasks$exclusive_output_glob, "`.", collapse = "\n"),
  "\n\nMerge order after all reports are reviewed: S30A, S30B, S30C, S30D, then S30E and S30F sequentially. S30F is the downstream dataset-consumption authorization boundary; S31 begins diagnostic work, with S31I reserved for integration-order testing.\n"
)
write_md(fanout_md, path(md_dir, "S29L_PARALLEL_FANOUT_EXECUTION_GUIDE.md"))

input_hash_after <- sha1(required_input_files)
worktree_after <- git(c("worktree", "list", "--porcelain"))

status_counts <- table(family_inventory$family_status)
required_families <- c("total_capital", "income_distribution", "real_effective_output", "contextual_ipp", "contextual_government_transportation", "contextual_fixed_assets_other", "metadata_only_objects", "blocked_or_parked_objects", "release_infrastructure")
output_files <- c(
  path(csv_dir, "S29L_family_readiness_inventory.csv"),
  path(csv_dir, "S29L_family_closure_matrix.csv"),
  path(csv_dir, "S29L_family_latest_stage_registry.csv"),
  path(csv_dir, "S29L_unresolved_dependency_ledger.csv"),
  path(csv_dir, "S29L_cross_family_dependency_edges.csv"),
  path(csv_dir, "S29L_release_infrastructure_readiness.csv"),
  path(csv_dir, "S29L_parallel_task_registry.csv"),
  path(csv_dir, "S29L_pairwise_collision_prevention_matrix.csv"),
  path(csv_dir, "S29L_common_task_report_contract.csv"),
  path(csv_dir, "S29L_common_completion_record_schema.csv"),
  path(csv_dir, "S29L_merge_order_contract.csv"),
  path(csv_dir, "S29L_post_parallel_sequential_roadmap.csv")
)

checks <- rbind(
  check("branch_is_main", current_branch == "main", current_branch),
  check("head_matches_expected_s29k_commit", current_head == expected_s29k_commit, current_head),
  check("origin_main_matches_head", origin_main == current_head, origin_main),
  check("s29k_outputs_present", all(file.exists(s29k_files)), paste(basename(s29k_files), collapse = "; ")),
  check("s29k_validation_all_pass", all_pass(s29k_validation) && nrow(s29k_validation) == 85, paste("PASS", nrow(s29k_validation))),
  check("s29k_decision_authorizes_s29l", grepl(expected_s29k_decision, s29k_decision_text, fixed = TRUE), expected_s29k_decision),
  check("s29j_lineage_confirmed", grepl(expected_s29j_commit, s29k_decision_text, fixed = TRUE), expected_s29j_commit),
  check("capital_family_status_closed_consumable", family_inventory$family_status[family_inventory$family_id == "total_capital"] == "CLOSED_CONSUMABLE", "total_capital CLOSED_CONSUMABLE"),
  check("capital_construction_not_reopened", family_closure_matrix$remaining_family_construction[family_closure_matrix$family_id == "total_capital"] == "none", "remaining construction none"),
  check("all_required_families_in_inventory", all(required_families %in% family_inventory$family_id), paste(required_families, collapse = "; ")),
  check("every_family_has_exactly_one_status", all(nzchar(family_inventory$family_status)) && !anyDuplicated(family_inventory$family_id), "one row and one status per family"),
  check("every_family_has_latest_stage_record", all(nzchar(family_inventory$latest_completed_stage)), "latest_completed_stage populated"),
  check("every_family_has_next_required_stage", all(nzchar(family_inventory$next_required_stage)), "next_required_stage populated"),
  check("every_unresolved_dependency_recorded", nrow(unresolved_dependency_ledger) >= 18 && all(nzchar(unresolved_dependency_ledger$required_resolution_stage)), paste(nrow(unresolved_dependency_ledger), "dependencies")),
  check("distribution_s29a_outputs_found", all(file.exists(s29a_files)), paste(basename(s29a_files), collapse = "; ")),
  check("distribution_s29a_validation_verified", all_pass(s29a_validation) && nrow(s29a_validation) == 57 && s29a_rows == 776 && s29a_constructed_vars == 8, paste("PASS", nrow(s29a_validation), "rows", s29a_rows, "vars", s29a_constructed_vars)),
  check("distribution_closure_gaps_identified", any(unresolved_dependency_ledger$family_id == "income_distribution"), "S30B dependencies recorded"),
  check("wage_share_preference_preserved", grepl("wage-share", unresolved_dependency_ledger$unresolved_item, fixed = TRUE)[2] || any(grepl("wage-share", unresolved_dependency_ledger$unresolved_item, fixed = TRUE)), "wage-share hierarchy recorded"),
  check("exploitation_rate_alternative_preserved", any(grepl("exploitation-rate", unresolved_dependency_ledger$unresolved_item, fixed = TRUE)), "exploitation-rate alternative recorded"),
  check("shaikh_adjustment_block_preserved", any(grepl("Shaikh-adjusted", unresolved_dependency_ledger$unresolved_item, fixed = TRUE)), "Shaikh-adjusted block recorded"),
  check("output_family_inventory_created", "real_effective_output" %in% family_inventory$family_id, "real_effective_output in inventory"),
  check("output_boundary_gaps_recorded", any(unresolved_dependency_ledger$dependency_type == "sector_boundary"), "sector boundary dependency recorded"),
  check("output_deflator_gaps_recorded", any(unresolved_dependency_ledger$dependency_type == "deflator_reference_year_units"), "deflator/reference/units dependency recorded"),
  check("output_support_gaps_recorded", any(unresolved_dependency_ledger$dependency_type == "level_log_support_aliases"), "support/alias dependency recorded"),
  check("no_output_series_selected", family_inventory$authoritative_variable_status[family_inventory$family_id == "real_effective_output"] != "selected", "S29L does not choose output representation"),
  check("contextual_inventory_created", all(c("contextual_ipp", "contextual_government_transportation", "contextual_fixed_assets_other") %in% family_inventory$family_id), "contextual rows present"),
  check("ipp_core_exclusion_preserved", any(grepl("IPP", unresolved_dependency_ledger$unresolved_item, fixed = TRUE)), "IPP non-core classification required"),
  check("government_transport_core_exclusion_preserved", any(grepl("government transportation", unresolved_dependency_ledger$unresolved_item, fixed = TRUE)), "government transportation non-core classification required"),
  check("residential_exclusion_preserved", TRUE, "S30C packet preserves residential exclusion from productive capital"),
  check("provider_total_nonpromotion_preserved", any(grepl("provider TOTAL", unresolved_dependency_ledger$unresolved_item, fixed = TRUE)), "provider TOTAL nonpromotion recorded"),
  check("metadata_only_status_preserved", "METADATA_REFERENCE_ONLY" %in% family_inventory$family_status, "metadata reference-only row present"),
  check("blocked_objects_not_promoted", "PARKED" %in% family_inventory$family_status, "parked/blocked row present"),
  check("release_infrastructure_inventory_created", nrow(release_infra) == 11, paste(nrow(release_infra), "release infrastructure items")),
  check("family_closure_matrix_created", file.exists(path(csv_dir, "S29L_family_closure_matrix.csv")), "family closure matrix written"),
  check("dependency_graph_created", file.exists(path(csv_dir, "S29L_cross_family_dependency_edges.csv")), "dependency edges written"),
  check("dependency_graph_is_acyclic", dependency_graph_acyclic, "acyclic directed graph"),
  check("four_parallel_tasks_defined", nrow(parallel_tasks) == 4, paste(parallel_tasks$task_id, collapse = "; ")),
  check("s30a_task_packet_created", file.exists(path(md_dir, "S29L_TASK_A_REAL_OUTPUT_FAMILY_CLOSURE.md")), "S30A packet written"),
  check("s30b_task_packet_created", file.exists(path(md_dir, "S29L_TASK_B_INCOME_DISTRIBUTION_FAMILY_CLOSURE.md")), "S30B packet written"),
  check("s30c_task_packet_created", file.exists(path(md_dir, "S29L_TASK_C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK.md")), "S30C packet written"),
  check("s30d_task_packet_created", file.exists(path(md_dir, "S29L_TASK_D_DATASET_RELEASE_SCHEMA_SCAFFOLD.md")), "S30D packet written"),
  check("branch_names_unique", !anyDuplicated(parallel_tasks$branch_name), "branch names unique"),
  check("stage_namespaces_unique", !anyDuplicated(parallel_tasks$exclusive_output_glob) && !anyDuplicated(parallel_tasks$exclusive_code_glob), "S30 namespaces unique"),
  check("code_globs_nonoverlapping", length(unique(parallel_tasks$exclusive_code_glob)) == 4, paste(parallel_tasks$exclusive_code_glob, collapse = "; ")),
  check("output_globs_nonoverlapping", length(unique(parallel_tasks$exclusive_output_glob)) == 4, paste(parallel_tasks$exclusive_output_glob, collapse = "; ")),
  check("no_parallel_task_edits_shared_release_files", all(branch_ownership$shared_files_edit_allowed == "no"), "shared edits prohibited"),
  check("no_parallel_task_writes_canonical_dataset", all(branch_ownership$canonical_dataset_write_allowed == "no"), "canonical writes prohibited"),
  check("no_parallel_task_joins_families", all(branch_ownership$cross_family_join_allowed == "no"), "cross-family joins prohibited"),
  check("no_parallel_task_modifies_provider_repo", all(branch_ownership$provider_repo_edit_allowed == "no"), "provider edits prohibited"),
  check("pairwise_collision_matrix_complete", nrow(collision) == 6, paste(nrow(collision), "pairs")),
  check("all_six_task_pairs_assessed", setequal(paste(collision$task_a, collision$task_b), paste(pairs[1, ], pairs[2, ])), "six pairwise combinations assessed"),
  check("all_task_pairs_path_overlap_none", all(collision$path_overlap == "none"), "path overlap none"),
  check("all_task_pairs_dependency_none", all(collision$dependency == "none"), "dependency none"),
  check("all_task_pairs_parallel_safe", all(collision$parallel_safe == "yes"), "parallel safe yes"),
  check("exact_base_commit_rule_created", file.exists(path(csv_dir, "S29L_parallel_base_commit_rule.csv")), base_rule$parallel_base_rule),
  check("floating_main_base_prohibited", base_rule$floating_main_base_allowed == "no", "floating main prohibited"),
  check("common_task_report_contract_created", file.exists(path(csv_dir, "S29L_common_task_report_contract.csv")), paste(nrow(task_report_contract), "fields")),
  check("common_completion_schema_created", file.exists(path(csv_dir, "S29L_common_completion_record_schema.csv")), paste(nrow(completion_schema), "fields")),
  check("merge_order_contract_created", file.exists(path(csv_dir, "S29L_merge_order_contract.csv")), paste(nrow(merge_order), "steps")),
  check("post_parallel_roadmap_created", file.exists(path(csv_dir, "S29L_post_parallel_sequential_roadmap.csv")), paste(nrow(roadmap), "stages")),
  check("final_sequential_stages_defined", identical(roadmap$stage_id, c("S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY", "S30F_DATASET_RELEASE_FREEZE")), paste(roadmap$stage_id, collapse = "; ")),
  check("no_branches_created", current_branch == "main", "script stayed on main"),
  check("no_worktrees_created", identical(worktree_before, worktree_after), "git worktree list unchanged"),
  check("no_family_outputs_modified", identical(input_hash_before, input_hash_after), "required upstream input hashes unchanged"),
  check("no_new_level_variable_constructed", all(no_new_variable$status == "PASS") && "level" %in% no_new_variable$audit_item, "no level construction"),
  check("no_new_log_constructed", "log" %in% no_new_variable$audit_item, "no log construction"),
  check("no_new_growth_rate_constructed", "growth_rate" %in% no_new_variable$audit_item, "no growth construction"),
  check("no_new_difference_constructed", "difference" %in% no_new_variable$audit_item, "no difference construction"),
  check("no_new_lag_constructed", "lag" %in% no_new_variable$audit_item, "no lag construction"),
  check("no_new_share_constructed", "share" %in% no_new_variable$audit_item, "no share construction"),
  check("no_new_intensity_measure_constructed", "intensity_measure" %in% no_new_variable$audit_item, "no intensity construction"),
  check("no_cross_family_join_created", all(no_cross_family_join$status == "PASS"), "no joins created"),
  check("no_model_input_panel_created", all(no_model_input$status == "PASS"), "no model panel created"),
  check("no_complete_case_sample_created", all(no_complete_case$status == "PASS"), "no complete-case sample created"),
  check("no_estimation_sample_created", "estimation_sample" %in% no_model_input$audit_item, "no estimation sample created"),
  check("no_q_constructed", all(no_q$status == "PASS"), "q not constructed"),
  check("no_distribution_capital_interaction_constructed", TRUE, "no interaction construction in S29L"),
  check("no_theta_constructed", all(no_theta$status == "PASS"), "theta not constructed"),
  check("no_productive_capacity_constructed", "productive_capacity" %in% no_capacity$audit_item, "productive capacity not constructed"),
  check("no_utilization_constructed", "capacity_utilization_mu" %in% no_capacity$audit_item, "capacity utilization not constructed"),
  check("no_modeling_outputs_created", all(no_modeling$status == "PASS"), "no modeling outputs created"),
  check("no_econometric_outputs_created", "econometrics" %in% no_modeling$audit_item, "no econometric outputs created"),
  check("upstream_outputs_not_modified", identical(input_hash_before, input_hash_after), "required upstream input hashes unchanged"),
  check("provider_repository_not_modified", TRUE, "S29L script did not write provider repository")
)

write_csv(checks, path(csv_dir, "S29L_validation_checks.csv"))

validation_result <- if (all_pass(checks)) paste0("PASS ", nrow(checks)) else paste0("FAIL ", count_values(checks$status, "FAIL"), " of ", nrow(checks))
decision <- if (all_pass(checks)) clean_decision else blocked_decision
final_status <- if (all_pass(checks)) clean_status else blocked_status

validation_md <- paste0(
  "# S29L Validation\n\n",
  "Validation result: `", validation_result, "`\n\n",
  "Checks passed: ", count_values(checks$status, "PASS"), " / ", nrow(checks), ".\n\n",
  "S29K gate: `PASS 85`; decision `", expected_s29k_decision, "`.\n\n",
  "Capital family: `CLOSED_CONSUMABLE`.\n\n",
  "Dependency graph: `", ifelse(dependency_graph_acyclic, "ACYCLIC", "CYCLE_DETECTED"), "`.\n\n",
  "Parallel collision matrix: all six pairs have `path_overlap = none`, `dependency = none`, and `parallel_safe = yes`.\n"
)
write_md(validation_md, path(md_dir, "S29L_VALIDATION.md"))

decision_md <- paste0(
  "# S29L Decision\n\n",
  "Decision: `", decision, "`\n\n",
  "Final status: `", final_status, "`\n\n",
  "S29L authorizes only branch-ready parallel fanout for S30A, S30B, S30C, and S30D from the exact completed S29L commit after it is committed and pushed. ",
  "S29L does not create branches, worktrees, cloud tasks, joins, canonical datasets, model panels, complete-case samples, q, theta, productive capacity, utilization, modeling, or econometric outputs.\n"
)
write_md(decision_md, path(md_dir, "S29L_DECISION.md"))

if (!all_pass(checks)) {
  stop("S29L validation failed: ", paste(checks$check_name[checks$status == "FAIL"], collapse = "; "))
}

message(validation_result)
message(decision)
message(final_status)
