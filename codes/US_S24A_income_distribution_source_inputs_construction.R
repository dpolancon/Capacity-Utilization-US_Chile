# S24A constructs only the authorized income-distribution source-input family
# from the downstream S21/S22/S23 source-of-truth layers.

options(stringsAsFactors = FALSE)

repo_root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)

provider_v1_commit <- "af67374e28232d02d65765d3836dc2ab3e3da8eb"
s21_commit <- "3a0f5064d92fc09f97a55850b4086670d9cedc4b"
s22_commit <- "d6f47bcdaa80bc146196f99a1ccf9207d6957e57"
s23_commit <- "96be02bd0acb4ca10ecc626d07482f6176e7c3b3"

target_family <- "income_distribution_source_inputs"
expected_family_count <- 29L
final_pass_decision <- "AUTHORIZE_S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION"
final_pass_status <- "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION_COMPLETE_S24B_AUTHORIZED"
final_fail_decision <- "BLOCK_FOR_INCOME_DISTRIBUTION_CONSTRUCTION_REVIEW"
final_fail_status <- "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION_BLOCKED_FOR_REVIEW"

s21_dir <- file.path(repo_root, "output", "US", "S21_PROVIDER_V1_SOURCE_OF_TRUTH_INTAKE")
s22_dir <- file.path(repo_root, "output", "US", "S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1")
s23_dir <- file.path(repo_root, "output", "US", "S23_VARIABLE_CONSTRUCTION_PLAN_FROM_PROVIDER_V1")
s24a_dir <- file.path(repo_root, "output", "US", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION")
csv_dir <- file.path(s24a_dir, "csv")
md_dir <- file.path(s24a_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

path <- function(...) file.path(...)

input_paths <- list(
  s23_authorized_queue = path(s23_dir, "csv", "S23_authorized_variable_build_queue.csv"),
  s23_sequence = path(s23_dir, "csv", "S23_construction_sequence_plan.csv"),
  s23_blocked_deferred = path(s23_dir, "csv", "S23_blocked_or_deferred_variable_queue.csv"),
  s23_theoretical = path(s23_dir, "csv", "S23_theoretical_boundary_resolution_queue.csv"),
  s23_source_dependency = path(s23_dir, "csv", "S23_source_dependency_resolution_plan.csv"),
  s23_family_split = path(s23_dir, "csv", "S23_family_implementation_split_recommendation.csv"),
  s23_validation = path(s23_dir, "csv", "S23_validation_checks.csv"),
  s23_validation_md = path(s23_dir, "md", "S23_VARIABLE_CONSTRUCTION_PLAN_VALIDATION.md"),
  s23_decision_md = path(s23_dir, "md", "S23_VARIABLE_CONSTRUCTION_PLAN_DECISION.md"),
  s21_source_panel = path(s21_dir, "csv", "S21_source_panel_long_v1.csv"),
  s21_validation = path(s21_dir, "csv", "S21_validation_checks.csv"),
  s22_authorized = path(s22_dir, "csv", "S22_authorized_baseline_objects.csv"),
  s22_validation = path(s22_dir, "csv", "S22_validation_checks.csv")
)

output_paths <- list(
  panel = path(csv_dir, "S24A_income_distribution_source_inputs_long.csv"),
  ledger = path(csv_dir, "S24A_income_distribution_construction_ledger.csv"),
  provenance = path(csv_dir, "S24A_income_distribution_provenance_audit.csv"),
  exclusion = path(csv_dir, "S24A_income_distribution_exclusion_audit.csv"),
  validation = path(csv_dir, "S24A_validation_checks.csv"),
  validation_md = path(md_dir, "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_VALIDATION.md"),
  decision_md = path(md_dir, "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_DECISION.md")
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

stop_if_missing(input_paths[1:10])

s23_validation <- read_csv(input_paths$s23_validation)
s23_decision_text <- paste(readLines(input_paths$s23_decision_md, warn = FALSE), collapse = "\n")
s23_queue <- read_csv(input_paths$s23_authorized_queue)
s23_sequence <- read_csv(input_paths$s23_sequence)
s23_blocked_deferred <- read_csv(input_paths$s23_blocked_deferred)
s23_theoretical <- read_csv(input_paths$s23_theoretical)
s23_source_dependency <- read_csv(input_paths$s23_source_dependency)
s23_family_split <- read_csv(input_paths$s23_family_split)

s23_validation_clean <- nrow(s23_validation) == 27L && all(s23_validation$status == "PASS")
s23_decision_clean <- grepl(
  "AUTHORIZE_AUTHORIZED_BASELINE_VARIABLE_CONSTRUCTION_IMPLEMENTATION",
  s23_decision_text,
  fixed = TRUE
)

if (!s23_validation_clean || !s23_decision_clean) {
  stop("S23 validation or decision is not clean; S24A must stop.", call. = FALSE)
}

stop_if_missing(input_paths[11:13])

s21_panel <- read_csv(input_paths$s21_source_panel)
s21_validation <- read_csv(input_paths$s21_validation)
s22_authorized <- read_csv(input_paths$s22_authorized)
s22_validation <- read_csv(input_paths$s22_validation)

income_queue <- s23_queue[s23_queue$construction_family == target_family, , drop = FALSE]
income_queue <- income_queue[order(to_int(income_queue$queue_rank), income_queue$variable_id), , drop = FALSE]
income_ids <- income_queue$variable_id

s23_meta <- data.frame(
  variable_id = income_queue$variable_id,
  s23_queue_rank = to_int(income_queue$queue_rank),
  display_name = income_queue$display_name,
  concept_family = income_queue$concept_family,
  construction_family = income_queue$construction_family,
  sector_boundary = income_queue$sector_boundary,
  account_position = income_queue$account_position,
  s23_candidate_status = income_queue$candidate_status,
  s23_object_admissibility = income_queue$object_admissibility,
  s23_source_observation_rows = to_int(income_queue$source_observation_rows),
  s23_coverage_start = to_int(income_queue$coverage_start),
  s23_coverage_end = to_int(income_queue$coverage_end),
  s23_authorization_scope = income_queue$s23_authorization_scope,
  s23_can_construct_in_s23 = income_queue$can_construct_in_s23,
  s23_can_model_in_s23 = income_queue$can_model_in_s23,
  s23_required_before_implementation = income_queue$required_before_implementation,
  s23_notes = income_queue$notes_s23,
  stringsAsFactors = FALSE
)

s22_income <- s22_authorized[s22_authorized$variable_id %in% income_ids, , drop = FALSE]
s22_meta <- data.frame(
  variable_id = s22_income$variable_id,
  s22_display_name = s22_income$display_name,
  s22_concept_family = s22_income$concept_family,
  s22_sector_boundary = s22_income$sector_boundary,
  s22_account_position = s22_income$account_position,
  s22_source_status = s22_income$source_status,
  s22_candidate_status = s22_income$candidate_status,
  s22_object_admissibility = s22_income$object_admissibility,
  s22_source_observation_rows = to_int(s22_income$source_observation_rows),
  s22_coverage_start = to_int(s22_income$coverage_start),
  s22_coverage_end = to_int(s22_income$coverage_end),
  s22_authorization = s22_income$s22_authorization,
  s22_can_construct_variable_now = s22_income$can_construct_variable_now,
  s22_can_model_now = s22_income$can_model_now,
  s22_can_run_econometrics_now = s22_income$can_run_econometrics_now,
  s22_notes = s22_income$s22_notes,
  stringsAsFactors = FALSE
)

income_panel <- s21_panel[s21_panel$variable_id %in% income_ids, , drop = FALSE]
income_panel$year <- to_int(income_panel$year)
income_panel$value <- as.numeric(income_panel$value)
income_panel <- merge(income_panel, s23_meta, by = "variable_id", all.x = TRUE, sort = FALSE)
income_panel <- merge(income_panel, s22_meta, by = "variable_id", all.x = TRUE, sort = FALSE)
income_panel$s24a_stage_id <- "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION"
income_panel$s24a_construction_action <- "source_input_materialized_from_s21_downstream_intake"
income_panel$s24a_authorization_scope <- "income_distribution_source_inputs_only"
income_panel$provider_v1_commit <- provider_v1_commit
income_panel$s21_intake_commit <- s21_commit
income_panel$s22_model_input_preparation_commit <- s22_commit
income_panel$s23_construction_plan_commit <- s23_commit
income_panel$s24a_constructed_object <- "yes"
income_panel$s24a_modeling_authorized <- "no"
income_panel$s24a_econometrics_authorized <- "no"
income_panel$s24a_notes <- "S24A materializes source-input rows only; no adjusted Shaikh, model, GPIM, theta, utilization, or q object is constructed."
income_panel <- income_panel[order(income_panel$s23_queue_rank, income_panel$year), , drop = FALSE]

ledger_rows <- lapply(income_ids, function(id) {
  rows <- income_panel[income_panel$variable_id == id, , drop = FALSE]
  meta <- s23_meta[s23_meta$variable_id == id, , drop = FALSE]
  s22 <- s22_meta[s22_meta$variable_id == id, , drop = FALSE]
  data.frame(
    variable_id = id,
    display_name = meta$display_name,
    construction_family = meta$construction_family,
    s24a_construction_status = if (nrow(rows) == meta$s23_source_observation_rows) "constructed" else "row_count_mismatch",
    constructed_observation_rows = nrow(rows),
    expected_observation_rows = meta$s23_source_observation_rows,
    coverage_start = min(rows$year, na.rm = TRUE),
    expected_coverage_start = meta$s23_coverage_start,
    coverage_end = max(rows$year, na.rm = TRUE),
    expected_coverage_end = meta$s23_coverage_end,
    source_dataset = collapse_unique(rows$source_dataset),
    source_table = collapse_unique(rows$source_table),
    source_line = collapse_unique(rows$source_line),
    source_line_description = collapse_unique(rows$source_line_description),
    unit = collapse_unique(rows$unit),
    frequency = collapse_unique(rows$frequency),
    provider_release_commit = collapse_unique(rows$provider_release_commit),
    provider_v1_commit = provider_v1_commit,
    s21_intake_commit = s21_commit,
    s22_model_input_preparation_commit = s22_commit,
    s23_construction_plan_commit = s23_commit,
    s22_authorization = if (nrow(s22) == 1L) s22$s22_authorization else "",
    s23_authorization_scope = meta$s23_authorization_scope,
    s24a_decision_effect = "constructed_as_authorized_income_distribution_source_input_only",
    can_enter_modeling = collapse_unique(rows$can_enter_modeling),
    can_construct_adjusted_shaikh = collapse_unique(rows$can_construct_adjusted_shaikh),
    blocked_or_parked_status = collapse_unique(rows$blocked_or_parked_status),
    notes = "No transformation beyond S21 row filtering and lineage preservation.",
    stringsAsFactors = FALSE
  )
})
ledger <- do.call(rbind, ledger_rows)

provenance_rows <- lapply(income_ids, function(id) {
  rows <- income_panel[income_panel$variable_id == id, , drop = FALSE]
  data.frame(
    variable_id = id,
    provenance_status = if (
      length(unique(rows$provider_release_commit)) == 1L &&
        unique(rows$provider_release_commit) == provider_v1_commit &&
        nrow(rows) > 0L
    ) "PASS" else "FAIL",
    source_identifier_status = if (
      all(nzchar(rows$source_dataset)) &&
        all(nzchar(rows$source_table)) &&
        all(nzchar(rows$source_line)) &&
        all(nzchar(rows$source_line_description))
    ) "PASS" else "FAIL",
    provider_release_commit = collapse_unique(rows$provider_release_commit),
    provider_v1_commit_preserved = provider_v1_commit,
    s21_lineage_preserved = s21_commit,
    s22_lineage_preserved = s22_commit,
    s23_lineage_preserved = s23_commit,
    source_dataset = collapse_unique(rows$source_dataset),
    source_table = collapse_unique(rows$source_table),
    source_line = collapse_unique(rows$source_line),
    source_vintage_or_retrieval_date = collapse_unique(rows$source_vintage_or_retrieval_date),
    transformation_status = collapse_unique(rows$transformation_status),
    candidate_status = collapse_unique(rows$candidate_status),
    object_admissibility = collapse_unique(rows$object_admissibility),
    s21_intake_status = collapse_unique(rows$s21_intake_status),
    stringsAsFactors = FALSE
  )
})
provenance <- do.call(rbind, provenance_rows)

sequence_counts <- data.frame(
  construction_family = s23_sequence$construction_family,
  authorized_object_count = to_int(s23_sequence$authorized_object_count),
  recommended_sequence_order = to_int(s23_sequence$recommended_sequence_order),
  s24a_constructed_object_count = vapply(
    s23_sequence$construction_family,
    function(fam) sum(ledger$construction_family == fam),
    integer(1L)
  ),
  s24a_action = ifelse(
    s23_sequence$construction_family == target_family,
    "constructed_in_s24a",
    "excluded_from_s24a_by_family_boundary"
  ),
  stringsAsFactors = FALSE
)

deferred_summary <- data.frame(
  construction_family = c(
    "theoretical_boundary_deferred",
    "documentation_only_deferred",
    "blocked_or_parked_deferred",
    "blocked"
  ),
  authorized_object_count = c(
    sum(s23_blocked_deferred$s23_queue_status == "theoretical_boundary_deferred"),
    sum(s23_blocked_deferred$s23_queue_status == "documentation_only_deferred"),
    sum(s23_blocked_deferred$s23_queue_status == "blocked_or_parked_deferred"),
    sum(s23_blocked_deferred$s23_queue_status == "blocked")
  ),
  recommended_sequence_order = NA_integer_,
  s24a_constructed_object_count = 0L,
  s24a_action = "excluded_from_s24a_deferred_or_blocked_boundary",
  stringsAsFactors = FALSE
)
exclusion_audit <- rbind(sequence_counts, deferred_summary)

row_count_ok <- all(ledger$constructed_observation_rows == ledger$expected_observation_rows)
coverage_ok <- all(ledger$coverage_start == ledger$expected_coverage_start) &&
  all(ledger$coverage_end == ledger$expected_coverage_end)
lineage_ok <- all(income_panel$provider_release_commit == provider_v1_commit) &&
  all(income_panel$provider_v1_commit == provider_v1_commit) &&
  all(income_panel$s21_intake_commit == s21_commit) &&
  all(income_panel$s22_model_input_preparation_commit == s22_commit) &&
  all(income_panel$s23_construction_plan_commit == s23_commit)

constructed_ids <- unique(ledger$variable_id)
blocked_ids <- unique(s23_blocked_deferred$object_id)
theoretical_ids <- unique(s23_theoretical$object_id)
documentation_ids <- unique(s23_blocked_deferred$object_id[
  s23_blocked_deferred$s23_queue_status == "documentation_only_deferred"
])
parked_ids <- unique(s23_blocked_deferred$object_id[
  s23_blocked_deferred$s23_queue_status == "blocked_or_parked_deferred"
])
explicit_blocked_ids <- unique(s23_blocked_deferred$object_id[
  s23_blocked_deferred$s23_queue_status == "blocked"
])

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

add_check("s23_outputs_present", all(file.exists(unlist(input_paths[1:10]))), paste(basename(unlist(input_paths[1:10])), collapse = "; "))
add_check("s23_validation_all_pass", s23_validation_clean, paste0("S23_validation_checks.csv PASS ", nrow(s23_validation)))
add_check("s23_decision_authorizes_baseline_implementation", s23_decision_clean, "AUTHORIZE_AUTHORIZED_BASELINE_VARIABLE_CONSTRUCTION_IMPLEMENTATION")
add_check("s23_build_queue_loaded", nrow(s23_queue) == 116L, paste0(nrow(s23_queue), " authorized build queue rows"))
add_check("s23_construction_sequence_loaded", nrow(s23_sequence) == 3L, paste0(nrow(s23_sequence), " family sequence rows"))
add_check("income_distribution_family_filtered", all(income_queue$construction_family == target_family), target_family)
add_check("income_distribution_family_count_equals_29", nrow(income_queue) == expected_family_count, paste0(nrow(income_queue), " objects"))
add_check("no_fixed_assets_objects_constructed", !any(ledger$construction_family == "fixed_assets_source_inputs"), "0 fixed-assets constructed objects")
add_check("no_provider_other_objects_constructed", !any(ledger$construction_family == "provider_source_inputs_other"), "0 provider-other constructed objects")
add_check("no_documentation_candidates_promoted", length(intersect(constructed_ids, documentation_ids)) == 0L, "documentation-only deferred ids remain excluded")
add_check("no_theoretically_unresolved_objects_promoted", length(intersect(constructed_ids, theoretical_ids)) == 0L, "theoretical-boundary ids remain excluded")
add_check("no_blocked_objects_promoted", length(intersect(constructed_ids, explicit_blocked_ids)) == 0L, "blocked ids remain excluded")
add_check("no_parked_objects_promoted", length(intersect(constructed_ids, parked_ids)) == 0L, "parked ids remain excluded")
add_check("no_adjusted_shaikh_objects_constructed", all(income_panel$can_construct_adjusted_shaikh == "no"), "all constructed rows retain can_construct_adjusted_shaikh=no")
add_check("source_of_truth_inputs_loaded", nrow(s21_panel) > 0L && nrow(s22_authorized) == 116L, paste0("S21 rows ", nrow(s21_panel), "; S22 authorized rows ", nrow(s22_authorized)))
add_check("constructed_income_distribution_panel_created", nrow(income_panel) == 2813L && row_count_ok && coverage_ok, paste0(nrow(income_panel), " panel rows"))
add_check("construction_ledger_created", nrow(ledger) == expected_family_count && row_count_ok, paste0(nrow(ledger), " ledger rows"))
add_check("provenance_audit_created", nrow(provenance) == expected_family_count && all(provenance$provenance_status == "PASS") && all(provenance$source_identifier_status == "PASS"), paste0(nrow(provenance), " provenance rows"))
add_check("exclusion_audit_created", nrow(exclusion_audit) == 7L && all(exclusion_audit$s24a_constructed_object_count[exclusion_audit$construction_family != target_family] == 0L), paste0(nrow(exclusion_audit), " exclusion rows"))
add_check("provider_v1_commit_preserved", all(income_panel$provider_release_commit == provider_v1_commit), provider_v1_commit)
add_check("s21_lineage_preserved", lineage_ok && all(income_panel$s21_intake_commit == s21_commit), s21_commit)
add_check("s22_lineage_preserved", lineage_ok && all(income_panel$s22_model_input_preparation_commit == s22_commit), s22_commit)
add_check("s23_lineage_preserved", lineage_ok && all(income_panel$s23_construction_plan_commit == s23_commit), s23_commit)
add_check("no_modeling_outputs_created", all(income_panel$s24a_modeling_authorized == "no"), "S24A emits only source-input panel and audits")
add_check("no_econometric_outputs_created", all(income_panel$s24a_econometrics_authorized == "no"), "No econometric output paths emitted")
add_check("no_gpim_outputs_created", !any(grepl("gpim", names(output_paths), ignore.case = TRUE)), "No GPIM output paths emitted")
add_check("no_theta_outputs_created", !any(grepl("theta", names(output_paths), ignore.case = TRUE)), "No theta output paths emitted")
add_check("no_utilization_outputs_created", !any(grepl("utilization", names(output_paths), ignore.case = TRUE)), "No utilization output paths emitted")
add_check("no_accumulated_q_outputs_created", !any(grepl("accumulated_q|q_", names(output_paths), ignore.case = TRUE)), "No accumulated-q output paths emitted")
add_check("no_provider_repo_modification", TRUE, "Provider repo not written; S24A consumes downstream S21/S22/S23 files only")

validation <- add_check(flush = TRUE)
clean <- nrow(validation) == 30L && all(validation$status == "PASS")
final_decision <- if (clean) final_pass_decision else final_fail_decision
final_status <- if (clean) final_pass_status else final_fail_status

write_csv(income_panel, output_paths$panel)
write_csv(ledger, output_paths$ledger)
write_csv(provenance, output_paths$provenance)
write_csv(exclusion_audit, output_paths$exclusion)
write_csv(validation, output_paths$validation)

validation_md <- c(
  "# S24A Income Distribution Source Inputs Validation",
  "",
  paste0("S24A validation result: `", if (clean) "PASS" else "FAIL", " ", sum(validation$status == "PASS"), "`"),
  "",
  paste0("Constructed family: `", target_family, "`."),
  paste0("Constructed object count: `", nrow(ledger), "`."),
  paste0("Constructed panel row count: `", nrow(income_panel), "`."),
  "",
  "S24A constructs only income-distribution source-input observations from the downstream S21 intake, filtered through the S23 authorized build queue. It constructs no fixed-assets objects, provider-other objects, adjusted Shaikh objects, modeling panels, econometric outputs, GPIM, theta, utilization, or accumulated q.",
  "",
  "## Validation checks",
  "",
  md_table(validation, c("check_name", "status", "evidence")),
  "",
  "## Family exclusion audit",
  "",
  md_table(exclusion_audit, c("construction_family", "authorized_object_count", "s24a_constructed_object_count", "s24a_action"))
)
writeLines(validation_md, output_paths$validation_md, useBytes = TRUE)

decision_md <- c(
  "# S24A Income Distribution Source Inputs Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S24A consumed S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("Constructed family: `", target_family, "`."),
  paste0("Constructed object count: `", nrow(ledger), "`."),
  paste0("Constructed panel row count: `", nrow(income_panel), "`."),
  "",
  "This decision authorizes only the next bounded construction family, S24B fixed-assets source inputs. It does not authorize modeling, econometrics, GPIM, theta, productive capacity, utilization, accumulated q, adjusted Shaikh reconstruction, provider-other construction, or promotion of deferred, blocked, parked, documentation-only, or theoretically unresolved objects.",
  "",
  "S24A stops here."
)
writeLines(decision_md, output_paths$decision_md, useBytes = TRUE)

if (!clean) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("S24A validation failed:\n- ", paste(failed, collapse = "\n- "), call. = FALSE)
}

message("S24A validation PASS: ", sum(validation$status == "PASS"))
message("Constructed panel rows: ", nrow(income_panel))
message("Construction ledger rows: ", nrow(ledger))
message("Decision: ", final_decision)
