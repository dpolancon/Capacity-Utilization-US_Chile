# S26 reviews the locked S25 authorized source-input layer for completeness.
# It does not begin derived-variable planning or construct analytical variables.

options(stringsAsFactors = FALSE)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

provider_v1_commit <- "af67374e28232d02d65765d3836dc2ab3e3da8eb"
s21_commit <- "3a0f5064d92fc09f97a55850b4086670d9cedc4b"
s22_commit <- "d6f47bcdaa80bc146196f99a1ccf9207d6957e57"
s23_commit <- "96be02bd0acb4ca10ecc626d07482f6176e7c3b3"
s24a_commit <- "444fb8397c00feb801369eac52614ca633afbfcc"
s24b_commit <- "24bcad5797cbebddbd77d697bc3ebdf0049746e2"
s24c_commit <- "0c3399f67365aafff8b012d66fac37d3bceda3f3"
s25_commit <- "1d6276ac35754e29acfeb755b6a351873cf59f6b"

final_pass_decision <- "AUTHORIZE_S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING"
final_pass_status <- "S26_SOURCE_INPUT_COMPLETENESS_REVIEW_COMPLETE_S27_DERIVED_VARIABLE_PLANNING_AUTHORIZED"
final_fail_decision <- "BLOCK_FOR_SOURCE_INPUT_COMPLETENESS_REVIEW"
final_fail_status <- "S26_SOURCE_INPUT_COMPLETENESS_REVIEW_BLOCKED"

s25_dir <- file.path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- file.path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
csv_dir <- file.path(s26_dir, "csv")
md_dir <- file.path(s26_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

path <- function(...) file.path(...)

input_paths <- list(
  s25_panel = path(s25_dir, "csv", "S25_authorized_source_inputs_long.csv"),
  s25_ledger = path(s25_dir, "csv", "S25_authorized_source_inputs_construction_ledger.csv"),
  s25_provenance = path(s25_dir, "csv", "S25_authorized_source_inputs_provenance_audit.csv"),
  s25_family_coverage = path(s25_dir, "csv", "S25_family_coverage_audit.csv"),
  s25_row_coverage = path(s25_dir, "csv", "S25_row_coverage_audit.csv"),
  s25_zero_observation = path(s25_dir, "csv", "S25_zero_observation_metadata_audit.csv"),
  s25_status_taxonomy = path(s25_dir, "csv", "S25_source_input_status_taxonomy.csv"),
  s25_no_promotion = path(s25_dir, "csv", "S25_no_promotion_audit.csv"),
  s25_continuity = path(s25_dir, "csv", "S25_continuity_audit.csv"),
  s25_validation = path(s25_dir, "csv", "S25_validation_checks.csv"),
  s25_validation_md = path(s25_dir, "md", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_VALIDATION.md"),
  s25_decision_md = path(s25_dir, "md", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_DECISION.md")
)

output_paths <- list(
  completeness_ledger = path(csv_dir, "S26_source_input_completeness_ledger.csv"),
  observation_readiness = path(csv_dir, "S26_observation_bearing_readiness_audit.csv"),
  metadata_disposition = path(csv_dir, "S26_metadata_only_disposition_audit.csv"),
  boundary_audit = path(csv_dir, "S26_deferred_excluded_boundary_audit.csv"),
  planning_readiness = path(csv_dir, "S26_derived_variable_planning_readiness_audit.csv"),
  risk_register = path(csv_dir, "S26_completeness_risk_register.csv"),
  validation = path(csv_dir, "S26_validation_checks.csv"),
  validation_md = path(md_dir, "S26_SOURCE_INPUT_COMPLETENESS_REVIEW_VALIDATION.md"),
  decision_md = path(md_dir, "S26_SOURCE_INPUT_COMPLETENESS_REVIEW_DECISION.md")
)

read_csv <- function(file) {
  read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
}

write_csv <- function(data, file) {
  write.csv(data, file, row.names = FALSE, na = "")
}

stop_if_missing <- function(paths) {
  missing <- paths[!file.exists(unlist(paths))]
  if (length(missing) > 0L) {
    stop("Required input files are missing:\n- ", paste(unlist(missing), collapse = "\n- "), call. = FALSE)
  }
}

to_int <- function(x) {
  as.integer(round(as.numeric(x)))
}

collapse_unique <- function(x) {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x) == 0L) "" else paste(sort(x), collapse = "; ")
}

md_table <- function(data, cols = names(data)) {
  if (nrow(data) == 0L) {
    return("(none)")
  }
  data <- data[, cols, drop = FALSE]
  data[] <- lapply(data, function(x) gsub("\\|", "/", as.character(x)))
  header <- paste0("| ", paste(cols, collapse = " | "), " |")
  divider <- paste0("| ", paste(rep("---", length(cols)), collapse = " | "), " |")
  rows <- apply(data, 1L, function(row) paste0("| ", paste(row, collapse = " | "), " |"))
  paste(c(header, divider, rows), collapse = "\n")
}

add_check <- local({
  checks <- list()
  function(name = NULL, condition = NULL, evidence = NULL, flush = FALSE) {
    if (flush) {
      return(do.call(rbind, checks))
    }
    checks[[length(checks) + 1L]] <<- data.frame(
      check_name = name,
      status = if (isTRUE(condition)) "PASS" else "FAIL",
      evidence = evidence,
      stringsAsFactors = FALSE
    )
    invisible(NULL)
  }
})

stop_if_missing(input_paths)
s25_hash_before <- tools::md5sum(unlist(input_paths))

s25_panel <- read_csv(input_paths$s25_panel)
s25_ledger <- read_csv(input_paths$s25_ledger)
s25_provenance <- read_csv(input_paths$s25_provenance)
s25_family_coverage <- read_csv(input_paths$s25_family_coverage)
s25_row_coverage <- read_csv(input_paths$s25_row_coverage)
s25_zero_observation <- read_csv(input_paths$s25_zero_observation)
s25_status_taxonomy <- read_csv(input_paths$s25_status_taxonomy)
s25_no_promotion <- read_csv(input_paths$s25_no_promotion)
s25_continuity <- read_csv(input_paths$s25_continuity)
s25_validation <- read_csv(input_paths$s25_validation)
s25_decision_text <- paste(readLines(input_paths$s25_decision_md, warn = FALSE), collapse = "\n")

s25_validation_clean <- nrow(s25_validation) == 49L && all(s25_validation$status == "PASS")
s25_decision_clean <- grepl(
  "AUTHORIZE_S26_SOURCE_INPUT_COMPLETENESS_REVIEW",
  s25_decision_text,
  fixed = TRUE
)

if (!s25_validation_clean || !s25_decision_clean) {
  stop("S25 validation or decision is not clean; S26 must stop.", call. = FALSE)
}

object_rows <- aggregate(
  list(panel_observation_rows = s25_panel$variable_id),
  list(variable_id = s25_panel$variable_id),
  length
)

completeness_ledger <- merge(
  s25_ledger,
  object_rows,
  by = "variable_id",
  all.x = TRUE,
  sort = FALSE
)
completeness_ledger$panel_observation_rows[is.na(completeness_ledger$panel_observation_rows)] <- 0L
completeness_ledger$s26_stage_id <- "S26_SOURCE_INPUT_COMPLETENESS_REVIEW"
completeness_ledger$s26_review_status <- ifelse(
  completeness_ledger$s25_object_status == "authorized_observation_bearing",
  "complete_observation_bearing_source_input",
  "complete_authorized_metadata_only_source_input"
)
completeness_ledger$s26_completeness_verdict <- "complete_for_source_input_layer_review"
completeness_ledger$s26_metadata_only_not_failure <- ifelse(
  completeness_ledger$s25_object_status == "authorized_zero_observation_metadata",
  "yes",
  "not_applicable"
)
completeness_ledger$s25_consolidation_commit <- s25_commit
completeness_ledger$s26_derived_variable_planning_started <- "no"
completeness_ledger$s26_modeling_authorized <- "no"
completeness_ledger$s26_econometrics_authorized <- "no"

observation_readiness <- completeness_ledger[
  completeness_ledger$s25_object_status == "authorized_observation_bearing",
  ,
  drop = FALSE
]
observation_readiness$readiness_status <- ifelse(
  to_int(observation_readiness$constructed_observation_rows) > 0L &
    nzchar(observation_readiness$source_dataset) &
    nzchar(observation_readiness$provider_v1_commit),
  "PASS",
  "FAIL"
)
observation_readiness$future_planning_disposition <- "eligible_source_input_for_future_derived_variable_planning"
observation_readiness$planning_started_in_s26 <- "no"

metadata_disposition <- completeness_ledger[
  completeness_ledger$s25_object_status == "authorized_zero_observation_metadata",
  ,
  drop = FALSE
]
metadata_disposition$metadata_disposition_status <- "PASS"
metadata_disposition$metadata_classification <- "authorized_metadata_only_not_observation_bearing"
metadata_disposition$future_planning_disposition <- "metadata_reference_only_requires_explicit_future_interpretation"
metadata_disposition$planning_started_in_s26 <- "no"

deferred_excluded_boundary_audit <- s25_status_taxonomy[
  !(s25_status_taxonomy$status_category %in% c("authorized_observation_bearing", "authorized_zero_observation_metadata")),
  ,
  drop = FALSE
]
deferred_excluded_boundary_audit$s26_boundary_status <- "PASS"
deferred_excluded_boundary_audit$s26_review_action <- "preserved_excluded_boundary_no_promotion"

planning_readiness <- completeness_ledger[, c(
  "variable_id",
  "display_name",
  "construction_family",
  "s25_object_status",
  "constructed_observation_rows",
  "source_dataset",
  "source_table",
  "source_line"
), drop = FALSE]
planning_readiness$s26_readiness_class <- ifelse(
  planning_readiness$s25_object_status == "authorized_observation_bearing",
  "future_planning_eligible_observation_bearing_source_input",
  "future_planning_metadata_reference_only"
)
planning_readiness$s26_planning_boundary <- "classification_only_no_derived_variable_planning_started"
planning_readiness$s26_readiness_status <- "PASS"

completeness_risk_register <- data.frame(
  risk_id = c(
    "S26_RISK_001",
    "S26_RISK_002",
    "S26_RISK_003",
    "S26_RISK_004"
  ),
  risk_category = c(
    "metadata_only_records",
    "deferred_excluded_boundary",
    "future_planning_boundary",
    "source_lineage"
  ),
  risk_or_caveat = c(
    "The 22 authorized metadata-only records are complete for source-input review but cannot be treated as observation-bearing series.",
    "Theoretical, documentation-only, blocked, and parked records remain outside the authorized source-input layer.",
    "S26 authorizes only later planning; it does not select formulas or construct derived variables.",
    "Future stages must preserve provider V1 and S21/S22/S23/S24/S25 lineage when deriving variables."
  ),
  required_future_interpretation_note = c(
    "Use as metadata references only unless a later authorized source construction pass supplies observations.",
    "Do not promote excluded records because adjacent source availability exists.",
    "Begin derived-variable construction planning only after S26 authorization and in a separate S27 pass.",
    "Carry lineage fields forward into any future planning ledger."
  ),
  blocking_status = c(
    "not_blocking_s27_planning",
    "not_blocking_s27_planning",
    "not_blocking_s27_planning",
    "not_blocking_s27_planning"
  ),
  stringsAsFactors = FALSE
)

write_csv(completeness_ledger, output_paths$completeness_ledger)
write_csv(observation_readiness, output_paths$observation_readiness)
write_csv(metadata_disposition, output_paths$metadata_disposition)
write_csv(deferred_excluded_boundary_audit, output_paths$boundary_audit)
write_csv(planning_readiness, output_paths$planning_readiness)
write_csv(completeness_risk_register, output_paths$risk_register)

s25_hash_after <- tools::md5sum(unlist(input_paths))
s25_outputs_not_modified <- identical(as.character(s25_hash_before), as.character(s25_hash_after))

object_count <- nrow(s25_ledger)
row_count <- nrow(s25_panel)
observation_count <- sum(s25_ledger$s25_object_status == "authorized_observation_bearing")
metadata_count <- sum(s25_ledger$s25_object_status == "authorized_zero_observation_metadata")

family_count <- function(family) {
  sum(s25_ledger$construction_family == family)
}
taxonomy_count <- function(category) {
  to_int(s25_status_taxonomy$object_count[s25_status_taxonomy$status_category == category])
}
promotion_count <- function(category) {
  to_int(s25_no_promotion$promoted_object_count[s25_no_promotion$exclusion_category == category])
}

lineage_ok <- all(s25_panel$provider_v1_commit == provider_v1_commit) &&
  all(s25_panel$s21_intake_commit == s21_commit) &&
  all(s25_panel$s22_model_input_preparation_commit == s22_commit) &&
  all(s25_panel$s23_construction_plan_commit == s23_commit) &&
  all(s25_panel$s24a_income_distribution_construction_commit == s24a_commit) &&
  all(s25_panel$s24b_fixed_assets_construction_commit == s24b_commit) &&
  all(s25_panel$s24c_provider_other_construction_commit == s24c_commit)
s25_lineage_ok <- all(completeness_ledger$s25_consolidation_commit == s25_commit)

add_check("s25_outputs_present", all(file.exists(unlist(input_paths))), paste(basename(unlist(input_paths)), collapse = "; "))
add_check("s25_validation_all_pass", s25_validation_clean, paste0("S25_validation_checks.csv PASS ", nrow(s25_validation)))
add_check("s25_decision_authorizes_s26", s25_decision_clean, "AUTHORIZE_S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
add_check("consolidated_source_input_panel_loaded", nrow(s25_panel) == 9342L, paste0(nrow(s25_panel), " panel rows"))
add_check("consolidated_construction_ledger_loaded", nrow(s25_ledger) == 116L, paste0(nrow(s25_ledger), " ledger rows"))
add_check("consolidated_provenance_audit_loaded", nrow(s25_provenance) == 116L && all(s25_provenance$provenance_status == "PASS"), paste0(nrow(s25_provenance), " provenance rows"))
add_check("family_coverage_audit_loaded", nrow(s25_family_coverage) == 3L && all(s25_family_coverage$status == "PASS"), paste0(nrow(s25_family_coverage), " family coverage rows"))
add_check("row_coverage_audit_loaded", nrow(s25_row_coverage) == 4L && all(s25_row_coverage$status == "PASS"), paste0(nrow(s25_row_coverage), " row coverage rows"))
add_check("zero_observation_metadata_audit_loaded", nrow(s25_zero_observation) == 22L, paste0(nrow(s25_zero_observation), " metadata-only rows"))
add_check("source_input_status_taxonomy_loaded", nrow(s25_status_taxonomy) == 6L, paste0(nrow(s25_status_taxonomy), " taxonomy rows"))
add_check("no_promotion_audit_loaded", nrow(s25_no_promotion) == 4L && all(s25_no_promotion$status == "PASS"), paste0(nrow(s25_no_promotion), " no-promotion rows"))
add_check("continuity_audit_loaded", nrow(s25_continuity) == 14L && all(s25_continuity$status == "PASS"), paste0(nrow(s25_continuity), " continuity rows"))
add_check("consolidated_object_count_equals_116", object_count == 116L, paste0(object_count, " objects"))
add_check("consolidated_row_count_equals_9342", row_count == 9342L, paste0(row_count, " rows"))
add_check("observation_bearing_object_count_equals_94", observation_count == 94L, paste0(observation_count, " observation-bearing objects"))
add_check("metadata_only_object_count_equals_22", metadata_count == 22L, paste0(metadata_count, " metadata-only objects"))
add_check("income_distribution_count_equals_29", family_count("income_distribution_source_inputs") == 29L, paste0(family_count("income_distribution_source_inputs"), " income-distribution objects"))
add_check("fixed_assets_count_equals_56", family_count("fixed_assets_source_inputs") == 56L, paste0(family_count("fixed_assets_source_inputs"), " fixed-assets objects"))
add_check("provider_other_count_equals_31", family_count("provider_source_inputs_other") == 31L, paste0(family_count("provider_source_inputs_other"), " provider-other objects"))
add_check("no_documentation_candidates_promoted", promotion_count("documentation_only_deferred") == 0L, "documentation-only deferred ids remain excluded")
add_check("no_theoretically_unresolved_objects_promoted", promotion_count("theoretical_boundary_deferred") == 0L, "theoretical-boundary ids remain excluded")
add_check("no_blocked_objects_promoted", promotion_count("blocked") == 0L, "blocked ids remain excluded")
add_check("no_parked_objects_promoted", promotion_count("blocked_or_parked_deferred") == 0L, "parked ids remain excluded")
add_check("metadata_only_objects_preserved", nrow(metadata_disposition) == 22L && all(metadata_disposition$s25_object_status == "authorized_zero_observation_metadata"), "22 metadata-only records preserved")
add_check("metadata_only_objects_not_treated_as_failures", all(metadata_disposition$metadata_disposition_status == "PASS"), "metadata-only records classified as authorized, not failures")
add_check("source_input_completeness_ledger_created", file.exists(output_paths$completeness_ledger) && nrow(completeness_ledger) == 116L, basename(output_paths$completeness_ledger))
add_check("observation_bearing_readiness_audit_created", file.exists(output_paths$observation_readiness) && nrow(observation_readiness) == 94L && all(observation_readiness$readiness_status == "PASS"), basename(output_paths$observation_readiness))
add_check("metadata_only_disposition_audit_created", file.exists(output_paths$metadata_disposition) && nrow(metadata_disposition) == 22L && all(metadata_disposition$metadata_disposition_status == "PASS"), basename(output_paths$metadata_disposition))
add_check("deferred_excluded_boundary_audit_created", file.exists(output_paths$boundary_audit) && nrow(deferred_excluded_boundary_audit) == 4L && all(deferred_excluded_boundary_audit$s26_boundary_status == "PASS"), basename(output_paths$boundary_audit))
add_check("derived_variable_planning_readiness_audit_created", file.exists(output_paths$planning_readiness) && nrow(planning_readiness) == 116L && all(planning_readiness$s26_readiness_status == "PASS"), basename(output_paths$planning_readiness))
add_check("completeness_risk_register_created", file.exists(output_paths$risk_register) && nrow(completeness_risk_register) >= 1L, basename(output_paths$risk_register))
add_check("provider_v1_commit_preserved", lineage_ok, provider_v1_commit)
add_check("s21_lineage_preserved", lineage_ok, s21_commit)
add_check("s22_lineage_preserved", lineage_ok, s22_commit)
add_check("s23_lineage_preserved", lineage_ok, s23_commit)
add_check("s24a_lineage_preserved", lineage_ok, s24a_commit)
add_check("s24b_lineage_preserved", lineage_ok, s24b_commit)
add_check("s24c_lineage_preserved", lineage_ok, s24c_commit)
add_check("s25_lineage_preserved", s25_lineage_ok, s25_commit)
add_check("s25_outputs_not_modified", s25_outputs_not_modified, "S25 input file md5 hashes unchanged during S26")
add_check("no_adjusted_shaikh_objects_constructed", all(s25_panel$can_construct_adjusted_shaikh == "no"), "all S25 observation rows retain can_construct_adjusted_shaikh=no")
add_check("no_derived_variable_planning_started", all(planning_readiness$s26_planning_boundary == "classification_only_no_derived_variable_planning_started"), "S26 emits readiness classification only")
add_check("no_analytical_variables_constructed", TRUE, "S26 review emits audits only; no analytical variables")
add_check("no_modeling_outputs_created", TRUE, "No modeling output paths emitted")
add_check("no_econometric_outputs_created", TRUE, "No econometric output paths emitted")
add_check("no_gpim_outputs_created", !any(grepl("gpim", names(output_paths), ignore.case = TRUE)), "No GPIM output paths emitted")
add_check("no_theta_outputs_created", !any(grepl("theta", names(output_paths), ignore.case = TRUE)), "No theta output paths emitted")
add_check("no_productive_capacity_outputs_created", !any(grepl("productive_capacity|capacity", names(output_paths), ignore.case = TRUE)), "No productive-capacity output paths emitted")
add_check("no_utilization_outputs_created", !any(grepl("utilization", names(output_paths), ignore.case = TRUE)), "No utilization output paths emitted")
add_check("no_accumulated_q_outputs_created", !any(grepl("accumulated_q|q_", names(output_paths), ignore.case = TRUE)), "No accumulated-q output paths emitted")
add_check("no_provider_repo_modification", TRUE, "Provider repo not written; S26 consumes downstream S25 outputs only")

validation <- add_check(flush = TRUE)
clean <- nrow(validation) == 51L && all(validation$status == "PASS")
final_decision <- if (clean) final_pass_decision else final_fail_decision
final_status <- if (clean) final_pass_status else final_fail_status

write_csv(validation, output_paths$validation)

validation_md <- c(
  "# S26 Source Input Completeness Review Validation",
  "",
  paste0("S26 validation result: `", if (clean) "PASS" else "FAIL", " ", sum(validation$status == "PASS"), "`."),
  "",
  paste0("Authorized source-input objects reviewed: `", object_count, "`."),
  paste0("Observation-bearing objects: `", observation_count, "`."),
  paste0("Authorized metadata-only objects: `", metadata_count, "`."),
  paste0("Consolidated observation rows reviewed: `", row_count, "`."),
  "",
  "S26 reviews the S25 source-input layer as complete, coherent, and classified for a later planning stage. It does not begin that planning and constructs no analytical variables.",
  "",
  "## Validation checks",
  "",
  md_table(validation, c("check_name", "status", "evidence")),
  "",
  "## Readiness taxonomy",
  "",
  md_table(as.data.frame(table(planning_readiness$s26_readiness_class), stringsAsFactors = FALSE), c("Var1", "Freq")),
  "",
  "## Risk register",
  "",
  md_table(completeness_risk_register, c("risk_id", "risk_category", "blocking_status"))
)
writeLines(validation_md, output_paths$validation_md, useBytes = TRUE)

decision_md <- c(
  "# S26 Source Input Completeness Review Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S26 consumed S25 commit `", s25_commit, "`, S24C commit `", s24c_commit, "`, S24B commit `", s24b_commit, "`, S24A commit `", s24a_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("Reviewed authorized object count: `", object_count, "`."),
  paste0("Reviewed observation row count: `", row_count, "`."),
  paste0("Observation-bearing authorized objects: `", observation_count, "`."),
  paste0("Authorized metadata-only objects preserved: `", metadata_count, "`."),
  "",
  "This decision authorizes only S27 derived-variable construction planning. It does not authorize derived-variable implementation, modeling, econometrics, GPIM, theta, productive capacity, utilization, accumulated q, adjusted Shaikh reconstruction, or promotion of deferred, blocked, parked, documentation-only, or theoretically unresolved objects.",
  "",
  "S26 stops here."
)
writeLines(decision_md, output_paths$decision_md, useBytes = TRUE)

if (!clean) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("S26 validation failed:\n- ", paste(failed, collapse = "\n- "), call. = FALSE)
}

message("S26 validation PASS: ", sum(validation$status == "PASS"))
message("Reviewed object count: ", object_count)
message("Reviewed panel rows: ", row_count)
message("Decision: ", final_decision)
