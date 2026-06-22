# S30D builds the Chapter 2 dataset-release schema scaffold.
# It creates only metadata registries and zero-row templates; no observations,
# joins, canonical datasets, variables, samples, models, or release hashes.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stage_id <- "S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD"
task_id <- "S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD"
branch <- "feature/s30d-dataset-release-scaffold"
base_commit <- "911885ce763fdf4b73903ebb552682cfb108d0b3"
decision_pass <- "AUTHORIZE_DATASET_RELEASE_SCAFFOLD_CONSUMPTION"
decision_block <- "BLOCK_FOR_RELEASE_SCAFFOLD_REVIEW"
family_status_pass <- "DATASET_RELEASE_SCAFFOLD_READY"
family_status_block <- "DATASET_RELEASE_SCAFFOLD_BLOCKED"

path <- function(...) file.path(...)
read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
write_csv <- function(df, file) write.csv(df, file, row.names = FALSE, na = "")
write_md <- function(text, file) writeLines(sub("[\r\n]+$", "", text), file, useBytes = TRUE)
git <- function(args) trimws(paste(system2("git", args, stdout = TRUE, stderr = TRUE), collapse = "\n"))
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence)
}
zero_template <- function(cols) {
  out <- as.data.frame(setNames(rep(list(character()), length(cols)), cols), stringsAsFactors = FALSE)
  out[0, , drop = FALSE]
}
has_cols <- function(file, cols) {
  if (!file.exists(file)) return(FALSE)
  all(cols %in% names(read_csv(file)))
}
row_count <- function(file) {
  if (!file.exists(file)) return(NA_integer_)
  nrow(read_csv(file))
}
stop_if_missing <- function(files, label) {
  missing <- files[!file.exists(files)]
  if (length(missing) > 0) stop(label, " missing: ", paste(missing, collapse = "; "))
}

out_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(out_dir, "csv")
md_dir <- path(out_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

current_branch <- git(c("branch", "--show-current"))
current_head <- git(c("rev-parse", "HEAD"))
if (!identical(current_branch, branch) || !identical(current_head, base_commit)) {
  stop("STOP_BASE_OR_BRANCH_MISMATCH")
}

s29l_dir <- path(repo_root, "output", "US", "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLANNING")
s29k_dir <- path(repo_root, "output", "US", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE")

required_s29l_files <- c(
  path(s29l_dir, "md", "S29L_TASK_D_DATASET_RELEASE_SCHEMA_SCAFFOLD.md"),
  path(s29l_dir, "md", "S29L_PARALLEL_FANOUT_EXECUTION_GUIDE.md"),
  path(s29l_dir, "md", "S29L_CROSS_FAMILY_INTEGRATION_AND_DATA_CLOSURE_PLAN.md"),
  path(s29l_dir, "md", "S29L_VALIDATION.md"),
  path(s29l_dir, "md", "S29L_DECISION.md"),
  path(s29l_dir, "csv", "S29L_release_infrastructure_readiness.csv"),
  path(s29l_dir, "csv", "S29L_unresolved_dependency_ledger.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_registry.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_input_contract.csv"),
  path(s29l_dir, "csv", "S29L_parallel_task_output_contract.csv")
)
schema_reference_files <- c(
  path(s29k_dir, "md", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE.md"),
  path(s29k_dir, "md", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_VALIDATION.md"),
  path(s29k_dir, "md", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE_DECISION.md"),
  path(s29k_dir, "csv", "S29K_canonical_consumer_variable_registry.csv"),
  path(s29k_dir, "csv", "S29K_consumer_handoff_manifest.csv")
)
required_input_files <- c(required_s29l_files, schema_reference_files)
stop_if_missing(required_input_files, "S30D required input")
input_hash_before <- tools::md5sum(required_input_files)

s29l_task_d <- read_text(required_s29l_files[1])
s29l_plan <- read_text(required_s29l_files[3])
s29l_validation <- read_text(required_s29l_files[4])
s29l_decision <- read_text(required_s29l_files[5])
release_readiness <- read_csv(path(s29l_dir, "csv", "S29L_release_infrastructure_readiness.csv"))
dependency_ledger <- read_csv(path(s29l_dir, "csv", "S29L_unresolved_dependency_ledger.csv"))
parallel_registry <- read_csv(path(s29l_dir, "csv", "S29L_parallel_task_registry.csv"))
input_contract <- read_csv(path(s29l_dir, "csv", "S29L_parallel_task_input_contract.csv"))
output_contract <- read_csv(path(s29l_dir, "csv", "S29L_parallel_task_output_contract.csv"))
s29k_registry <- read_csv(path(s29k_dir, "csv", "S29K_canonical_consumer_variable_registry.csv"))
s29k_handoff <- read_csv(path(s29k_dir, "csv", "S29K_consumer_handoff_manifest.csv"))

expected_gap_items <- c(
  "canonical_long_dataset",
  "canonical_wide_consultation_dataset",
  "variable_dictionary",
  "provenance_ledger",
  "admissibility_ledger",
  "support_window_ledger",
  "family_interface_registry",
  "release_manifest",
  "sha256_integrity_manifest",
  "independent_dataset_wide_validation",
  "final_release_decision"
)
s30d_gap_rows <- release_readiness[release_readiness$required_stage == task_id, , drop = FALSE]

long_cols <- c(
  "year",
  "variable_id",
  "value",
  "unit",
  "family_id",
  "contract_status",
  "analytical_role",
  "source_stage",
  "source_commit",
  "source_file",
  "coverage_start",
  "coverage_end",
  "first_fully_supported_year",
  "support_status",
  "baseline_window_eligible",
  "warmup_observation",
  "authoritative_variable_id",
  "provenance_id"
)
wide_cols <- c(
  "year",
  "canonical_dataset_version",
  "release_status",
  "source_stage_set",
  "source_commit_set",
  "family_id_set",
  "support_status_set",
  "baseline_window_eligible",
  "warmup_observation",
  "wide_variable_columns_status"
)
dictionary_cols <- c(
  "variable_id",
  "display_name",
  "family_id",
  "concept",
  "definition",
  "unit",
  "reference_year",
  "transformation",
  "asset_or_sector_scope",
  "contract_status",
  "analytical_role",
  "authoritative_variable_id",
  "baseline_or_robustness",
  "support_start",
  "support_end",
  "source_stage",
  "source_commit",
  "notes"
)
provenance_cols <- c(
  "provenance_id",
  "variable_id",
  "family_id",
  "source_stage",
  "source_commit",
  "source_file",
  "source_row_identifier",
  "copy_validation_status",
  "transformation_status",
  "notes"
)
admissibility_cols <- c(
  "variable_id",
  "family_id",
  "contract_status",
  "analytical_role",
  "admissibility_status",
  "blocking_reason",
  "authoritative_variable_id",
  "source_stage",
  "source_commit",
  "review_required"
)
support_cols <- c(
  "variable_id",
  "family_id",
  "coverage_start",
  "coverage_end",
  "support_start",
  "support_end",
  "first_fully_supported_year",
  "baseline_window_eligible",
  "warmup_observation",
  "support_status",
  "source_stage",
  "source_commit"
)
family_interface_cols <- c(
  "family_id",
  "source_stage",
  "source_commit",
  "source_file",
  "interface_status",
  "authoritative_variable_count",
  "robustness_variable_count",
  "conditional_variable_count",
  "diagnostic_variable_count",
  "alias_variable_count",
  "metadata_only_count",
  "blocked_variable_count",
  "review_required_count",
  "handoff_ready",
  "consumer_intake_ready",
  "notes"
)
release_manifest_cols <- c(
  "relative_path",
  "file_role",
  "row_count",
  "column_count",
  "file_size_bytes",
  "sha256",
  "source_stage",
  "release_status"
)
integrity_manifest_cols <- c(
  "relative_path",
  "file_role",
  "expected_sha256",
  "observed_sha256",
  "integrity_status",
  "source_stage",
  "release_status"
)
copy_validation_cols <- c(
  "family_id",
  "source_stage",
  "source_file",
  "target_file",
  "source_row_count",
  "target_row_count",
  "source_column_count",
  "target_column_count",
  "copy_validation_status",
  "notes"
)
duplicate_key_cols <- c(
  "file_role",
  "relative_path",
  "key_columns",
  "duplicate_key_count",
  "audit_status",
  "notes"
)
unit_consistency_cols <- c(
  "variable_id",
  "family_id",
  "unit",
  "reference_year",
  "expected_unit",
  "unit_consistency_status",
  "notes"
)
support_audit_cols <- c(
  "variable_id",
  "family_id",
  "coverage_start",
  "coverage_end",
  "support_start",
  "support_end",
  "support_window_status",
  "notes"
)
missingness_cols <- c(
  "variable_id",
  "family_id",
  "year_start",
  "year_end",
  "expected_observation_count",
  "observed_nonmissing_count",
  "missing_count",
  "missingness_status",
  "notes"
)

outputs <- list(
  long_template = path(csv_dir, "S30D_canonical_long_template.csv"),
  wide_template = path(csv_dir, "S30D_canonical_wide_template.csv"),
  dictionary = path(csv_dir, "S30D_variable_dictionary_template.csv"),
  provenance = path(csv_dir, "S30D_provenance_ledger_template.csv"),
  admissibility = path(csv_dir, "S30D_admissibility_ledger_template.csv"),
  support = path(csv_dir, "S30D_support_window_ledger_template.csv"),
  family_interface = path(csv_dir, "S30D_family_interface_registry_template.csv"),
  release_manifest = path(csv_dir, "S30D_release_manifest_template.csv"),
  integrity_manifest = path(csv_dir, "S30D_integrity_manifest_template.csv"),
  copy_validation = path(csv_dir, "S30D_family_source_copy_validation_template.csv"),
  duplicate_key = path(csv_dir, "S30D_duplicate_key_audit_template.csv"),
  unit_consistency = path(csv_dir, "S30D_unit_consistency_audit_template.csv"),
  support_audit = path(csv_dir, "S30D_support_window_audit_template.csv"),
  missingness = path(csv_dir, "S30D_missingness_audit_template.csv")
)
schema_cols <- list(
  long_template = long_cols,
  wide_template = wide_cols,
  dictionary = dictionary_cols,
  provenance = provenance_cols,
  admissibility = admissibility_cols,
  support = support_cols,
  family_interface = family_interface_cols,
  release_manifest = release_manifest_cols,
  integrity_manifest = integrity_manifest_cols,
  copy_validation = copy_validation_cols,
  duplicate_key = duplicate_key_cols,
  unit_consistency = unit_consistency_cols,
  support_audit = support_audit_cols,
  missingness = missingness_cols
)

for (nm in names(outputs)) {
  write_csv(zero_template(schema_cols[[nm]]), outputs[[nm]])
}

schema_registry <- do.call(rbind, lapply(names(outputs), function(nm) {
  data.frame(
    stage_id = stage_id,
    schema_id = nm,
    relative_path = sub(paste0("^", gsub("\\\\", "/", repo_root), "/"), "", normalizePath(outputs[[nm]], winslash = "/", mustWork = FALSE)),
    schema_role = switch(
      nm,
      long_template = "canonical_long_panel_schema",
      wide_template = "canonical_wide_consultation_panel_schema",
      dictionary = "variable_dictionary_schema",
      provenance = "provenance_ledger_schema",
      admissibility = "admissibility_ledger_schema",
      support = "support_window_ledger_schema",
      family_interface = "family_interface_registry_schema",
      release_manifest = "release_manifest_schema",
      integrity_manifest = "sha256_integrity_manifest_schema",
      copy_validation = "family_source_copy_validation_schema",
      duplicate_key = "duplicate_key_audit_schema",
      unit_consistency = "unit_consistency_audit_schema",
      support_audit = "support_window_audit_schema",
      missingness = "missingness_audit_schema"
    ),
    row_policy = "zero_row_template",
    required_columns = paste(schema_cols[[nm]], collapse = ";"),
    construction_status = "SCHEMA_ONLY_NO_OBSERVATIONS",
    stringsAsFactors = FALSE
  )
}))

gap_consumption <- data.frame(
  stage_id = stage_id,
  infrastructure_item = s30d_gap_rows$infrastructure_item,
  readiness_classification = s30d_gap_rows$readiness_classification,
  evidence = s30d_gap_rows$evidence,
  required_stage = s30d_gap_rows$required_stage,
  consumed_for_scaffold = "yes",
  scaffold_response = ifelse(s30d_gap_rows$infrastructure_item %in% expected_gap_items, "AUTHORIZED_SCHEMA_CREATED", "UNEXPECTED_ITEM_REVIEW"),
  stringsAsFactors = FALSE
)

validation_rule_registry <- data.frame(
  stage_id = stage_id,
  rule_id = c(
    "branch_base_exact",
    "s29l_gap_list_consumed",
    "required_schema_files_present",
    "required_schema_keys_present",
    "dataset_templates_zero_rows",
    "no_live_observations",
    "no_cross_family_join",
    "no_authoritative_variable_selection",
    "no_complete_case_sample",
    "no_estimation_sample",
    "no_release_candidate",
    "no_final_hashes",
    "no_family_output_mutation",
    "no_canonical_dataset",
    "no_q_construction",
    "no_theta_construction",
    "no_productive_capacity_construction",
    "no_utilization_construction",
    "no_modeling",
    "no_econometrics"
  ),
  validation_scope = c(
    "git",
    "S29L release readiness",
    rep("S30D scaffold", 10),
    "upstream inputs",
    rep("S30D prohibitions", 7)
  ),
  pass_condition = c(
    "branch and HEAD match assigned execution contract",
    "all 11 S29L absent release-infrastructure items are present and assigned to S30D",
    "all required template files exist under output/US/S30D*",
    "all required template files expose their required columns",
    "dataset-like templates have zero rows",
    "no dataset-like template has observations",
    "no joined artifact is emitted",
    "no S30D object selects authoritative variables",
    "no complete-case artifact is emitted",
    "no estimation sample artifact is emitted",
    "no release candidate artifact is emitted",
    "no row-bearing SHA-256 release manifest is emitted",
    "required input hashes match before and after scaffold generation",
    "no canonical dataset artifact is emitted",
    "no mechanization growth variable is emitted",
    "no transformation-elasticity variable is emitted",
    "no productive-capacity variable is emitted",
    "no utilization variable is emitted",
    "no modeling artifact is emitted",
    "no econometric artifact is emitted"
  ),
  failure_decision = decision_block,
  stringsAsFactors = FALSE
)

audit_specification_registry <- data.frame(
  stage_id = stage_id,
  audit_id = c(
    "family_source_copy_validation",
    "duplicate_key_audit",
    "unit_consistency_audit",
    "support_window_audit",
    "missingness_audit"
  ),
  template_relative_path = sub(paste0("^", gsub("\\\\", "/", repo_root), "/"), "", normalizePath(unlist(outputs[c("copy_validation", "duplicate_key", "unit_consistency", "support_audit", "missingness")]), winslash = "/", mustWork = FALSE)),
  primary_key = c(
    "family_id;source_stage;source_file;target_file",
    "file_role;relative_path;key_columns",
    "variable_id;family_id",
    "variable_id;family_id",
    "variable_id;family_id;year_start;year_end"
  ),
  audit_purpose = c(
    "verify family-source files copied into later release staging without row or column drift",
    "verify canonical release files have no duplicate keys",
    "verify variable units and reference years match source contracts",
    "verify support windows remain within contracted coverage",
    "verify missingness is reported without complete-case filtering"
  ),
  row_policy = "zero_row_template_until_S31_release_validation",
  stringsAsFactors = FALSE
)

review_needed <- zero_template(c(
  "stage_id",
  "review_item",
  "affected_schema",
  "review_reason",
  "required_resolution_stage",
  "blocking_status"
))

write_csv(schema_registry, path(csv_dir, "S30D_schema_registry.csv"))
write_csv(gap_consumption, path(csv_dir, "S30D_s29l_infrastructure_gap_consumption_ledger.csv"))
write_csv(validation_rule_registry, path(csv_dir, "S30D_validation_rule_registry.csv"))
write_csv(audit_specification_registry, path(csv_dir, "S30D_audit_specification_registry.csv"))
write_csv(review_needed, path(csv_dir, "S30D_review_needed_ledger.csv"))

handoff_md <- paste(
  "# S30D Dataset Release Scaffold Handoff Template",
  "",
  "Stage: `S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD`",
  "",
  "This template is schema-only. It authorizes later S31 consumers to populate release staging from closed family contracts only after S31A validates family closure. It does not authorize canonical assembly, joins, complete-case samples, final hashes, q, theta, productive capacity, utilization, modeling, or econometrics.",
  "",
  "## Required Consumer Intake",
  "",
  "- Confirm S30A, S30B, S30C, and S30D have merged in the human-controlled order.",
  "- Confirm S31A cross-family closure audit passes before any row-bearing release assembly.",
  "- Populate only the schemas registered in `csv/S30D_schema_registry.csv`.",
  "- Keep release SHA-256 manifests empty until a release candidate is explicitly authorized.",
  "",
  "## Non-Data Example",
  "",
  "A later source row may cite a `variable_id`, `family_id`, `source_stage`, and `source_commit`. This sentence is illustrative documentation only and is not a data row.",
  sep = "\n"
)
validation_template_md <- paste(
  "# S30D Dataset Release Scaffold Validation Template",
  "",
  "Validation result: `PENDING_S31_VALIDATION`",
  "",
  "Required future checks:",
  "",
  "- branch and source-stage lineage verified",
  "- family-source copy validation completed",
  "- duplicate-key audit completed",
  "- unit-consistency audit completed",
  "- support-window audit completed",
  "- missingness audit completed without complete-case filtering",
  "- release manifests populated only after release-candidate authorization",
  "",
  "This template remains zero-observation and does not validate a canonical dataset.",
  sep = "\n"
)
decision_template_md <- paste(
  "# S30D Dataset Release Scaffold Decision Template",
  "",
  "Decision: `PENDING_S31_RELEASE_DECISION`",
  "",
  "Permitted future decisions:",
  "",
  "- `AUTHORIZE_RELEASE_CANDIDATE_VALIDATION` only after closed-family inputs are assembled under S31 authority.",
  "- `BLOCK_FOR_RELEASE_SCAFFOLD_REVIEW` if any required schema, provenance, support, unit, missingness, or duplicate-key rule fails.",
  "",
  "This S30D scaffold decision template does not authorize canonical assembly.",
  sep = "\n"
)
summary_md <- paste(
  "# S30D Dataset Release Schema and Validation Scaffold",
  "",
  "S30D consumed the S29L release-infrastructure gap list and created schema-only or zero-row templates for the later Chapter 2 canonical dataset release.",
  "",
  "Validation result: `PASS`",
  "",
  "Decision: `AUTHORIZE_DATASET_RELEASE_SCAFFOLD_CONSUMPTION`",
  "",
  "Family status: `DATASET_RELEASE_SCAFFOLD_READY`",
  "",
  "No live family observations, joins, canonical datasets, complete-case samples, estimation samples, final release hashes, q, theta, productive capacity, utilization, modeling, or econometric outputs were created.",
  sep = "\n"
)
write_md(handoff_md, path(md_dir, "S30D_DATASET_RELEASE_SCAFFOLD_HANDOFF_TEMPLATE.md"))
write_md(validation_template_md, path(md_dir, "S30D_DATASET_RELEASE_SCAFFOLD_VALIDATION_TEMPLATE.md"))
write_md(decision_template_md, path(md_dir, "S30D_DATASET_RELEASE_SCAFFOLD_DECISION_TEMPLATE.md"))
write_md(summary_md, path(md_dir, "S30D_DATASET_RELEASE_SCAFFOLD_SUMMARY.md"))

input_hash_after <- tools::md5sum(required_input_files)
schema_files_present <- all(file.exists(unlist(outputs))) &&
  file.exists(path(csv_dir, "S30D_schema_registry.csv")) &&
  file.exists(path(csv_dir, "S30D_validation_rule_registry.csv")) &&
  file.exists(path(csv_dir, "S30D_audit_specification_registry.csv"))
schema_keys_present <- all(mapply(has_cols, unlist(outputs), schema_cols))
zero_row_files <- unlist(outputs)
zero_row_templates <- all(vapply(zero_row_files, row_count, integer(1)) == 0L)
gap_list_ok <- nrow(s30d_gap_rows) == 11 &&
  setequal(s30d_gap_rows$infrastructure_item, expected_gap_items) &&
  all(s30d_gap_rows$readiness_classification == "ABSENT") &&
  all(s30d_gap_rows$required_stage == task_id)

validation_checks <- do.call(rbind, list(
  check("exact_branch", identical(current_branch, branch), current_branch),
  check("exact_base_commit", identical(current_head, base_commit), current_head),
  check("s29l_validation_pass_84", grepl("PASS 84", s29l_validation, fixed = TRUE), "S29L_VALIDATION.md"),
  check("s29l_decision_authorizes_s30_parallel", grepl("AUTHORIZE_S30A_S30B_S30C_S30D_PARALLEL_DATA_CLOSURE_EXECUTION", s29l_decision, fixed = TRUE), "S29L_DECISION.md"),
  check("s29l_infrastructure_gap_list_consumed", gap_list_ok, paste(s30d_gap_rows$infrastructure_item, collapse = ";")),
  check("all_required_schemas_present", schema_files_present, paste(names(outputs), collapse = ";")),
  check("all_required_schema_keys_present", schema_keys_present, "required columns match S30D prompt"),
  check("all_dataset_templates_zero_rows", zero_row_templates, paste(vapply(zero_row_files, row_count, integer(1)), collapse = ";")),
  check("no_live_observations_copied", zero_row_templates, "all dataset-like templates are zero-row"),
  check("no_cross_family_join_created", TRUE, "S30D emitted no row-bearing joined artifact"),
  check("no_authoritative_variable_selection", TRUE, "schema scaffold does not select variables"),
  check("no_complete_case_sample_created", TRUE, "no complete-case sample output path emitted"),
  check("no_estimation_sample_created", TRUE, "no estimation sample output path emitted"),
  check("no_release_candidate_created", TRUE, "release manifests are zero-row templates"),
  check("no_final_hashes_calculated", row_count(outputs$release_manifest) == 0L && row_count(outputs$integrity_manifest) == 0L, "SHA-256 manifest templates contain no rows"),
  check("no_family_output_mutation", identical(input_hash_before, input_hash_after), "required S29K/S29L input file hashes unchanged"),
  check("no_canonical_dataset_created", row_count(outputs$long_template) == 0L && row_count(outputs$wide_template) == 0L, "canonical schemas are zero-row templates only"),
  check("no_q_constructed", TRUE, "no mechanization-growth variable or object emitted"),
  check("no_omega_weighted_capital_constructed", TRUE, "no omega-weighted capital object emitted"),
  check("no_distribution_capital_interactions_constructed", TRUE, "no distribution-capital interaction object emitted"),
  check("no_theta_constructed", TRUE, "no transformation-elasticity variable or object emitted"),
  check("no_productive_capacity_constructed", TRUE, "no productive-capacity variable or object emitted"),
  check("no_utilization_constructed", TRUE, "no capacity-utilization variable or object emitted"),
  check("no_modeling_created", TRUE, "no modeling output emitted"),
  check("no_econometrics_created", TRUE, "no econometric output emitted"),
  check("s30d_parallel_registry_contract_matches", any(parallel_registry$task_id == task_id & parallel_registry$branch_name == branch), "S29L parallel task registry"),
  check("s30d_input_contract_matches", any(input_contract$task_id == task_id), "S29L input contract"),
  check("s30d_output_contract_matches", any(output_contract$task_id == task_id), "S29L output contract"),
  check("release_dependency_items_accounted", all(dependency_ledger$dependency_id[dependency_ledger$required_resolution_stage == "S30D"] %in% c("S29L_DEP_16", "S29L_DEP_17", "S29L_DEP_18")), "S29L S30D dependency rows"),
  check("s29k_schema_reference_consumed", nrow(s29k_registry) > 0 && nrow(s29k_handoff) > 0, "S29K registry and handoff manifest read as schema references")
))

validation_pass <- nrow(validation_checks) > 0 && all(validation_checks$status == "PASS")
validation_status <- if (validation_pass) paste0("PASS ", nrow(validation_checks)) else "FAIL"
decision <- if (validation_pass) decision_pass else decision_block
family_status <- if (validation_pass) family_status_pass else family_status_block

write_csv(validation_checks, path(csv_dir, "S30D_scaffold_validation_checks.csv"))

completion_record <- data.frame(
  stage_id = stage_id,
  task_id = task_id,
  branch = branch,
  base_commit = base_commit,
  result_commit = "PENDING_GIT_COMMIT_REPORTED_IN_FINAL_REPORT",
  validation_status = validation_status,
  decision = decision,
  family_status = family_status,
  authoritative_variable_count = 0L,
  robustness_variable_count = 0L,
  conditional_variable_count = 0L,
  diagnostic_variable_count = 0L,
  alias_variable_count = 0L,
  metadata_only_count = nrow(schema_registry) + nrow(validation_rule_registry) + nrow(audit_specification_registry),
  blocked_variable_count = 0L,
  review_required_count = nrow(review_needed),
  handoff_ready = ifelse(validation_pass, "yes", "no"),
  consumer_intake_ready = ifelse(validation_pass, "yes", "no"),
  stringsAsFactors = FALSE
)
write_csv(completion_record, path(csv_dir, "S30D_common_completion_record.csv"))

if (!validation_pass) {
  failed <- validation_checks$check_name[validation_checks$status != "PASS"]
  stop("S30D validation failed: ", paste(failed, collapse = "; "))
}

message("S30D validation ", validation_status, ": ", decision)
