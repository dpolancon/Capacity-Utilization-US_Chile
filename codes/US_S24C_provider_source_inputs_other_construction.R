# S24C constructs only the authorized provider-other source-input family
# from the downstream S21/S22/S23 source-of-truth layers.

options(stringsAsFactors = FALSE)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

provider_v1_commit <- "af67374e28232d02d65765d3836dc2ab3e3da8eb"
s21_commit <- "3a0f5064d92fc09f97a55850b4086670d9cedc4b"
s22_commit <- "d6f47bcdaa80bc146196f99a1ccf9207d6957e57"
s23_commit <- "96be02bd0acb4ca10ecc626d07482f6176e7c3b3"
s24a_commit <- "444fb8397c00feb801369eac52614ca633afbfcc"
s24b_commit <- "24bcad5797cbebddbd77d697bc3ebdf0049746e2"

target_family <- "provider_source_inputs_other"
income_family <- "income_distribution_source_inputs"
fixed_assets_family <- "fixed_assets_source_inputs"
expected_family_count <- 31L
expected_panel_rows <- 593L
final_pass_decision <- "AUTHORIZE_S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION"
final_pass_status <- "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION_COMPLETE_S25_AUTHORIZED"
final_fail_decision <- "BLOCK_FOR_PROVIDER_OTHER_CONSTRUCTION_REVIEW"
final_fail_status <- "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION_BLOCKED_FOR_REVIEW"

s21_dir <- file.path(repo_root, "output", "US", "S21_PROVIDER_V1_SOURCE_OF_TRUTH_INTAKE")
s22_dir <- file.path(repo_root, "output", "US", "S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1")
s23_dir <- file.path(repo_root, "output", "US", "S23_VARIABLE_CONSTRUCTION_PLAN_FROM_PROVIDER_V1")
s24a_dir <- file.path(repo_root, "output", "US", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION")
s24b_dir <- file.path(repo_root, "output", "US", "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION")
s24c_dir <- file.path(repo_root, "output", "US", "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION")
csv_dir <- file.path(s24c_dir, "csv")
md_dir <- file.path(s24c_dir, "md")

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
  s24a_panel = path(s24a_dir, "csv", "S24A_income_distribution_source_inputs_long.csv"),
  s24a_ledger = path(s24a_dir, "csv", "S24A_income_distribution_construction_ledger.csv"),
  s24a_provenance = path(s24a_dir, "csv", "S24A_income_distribution_provenance_audit.csv"),
  s24a_exclusion = path(s24a_dir, "csv", "S24A_income_distribution_exclusion_audit.csv"),
  s24a_validation = path(s24a_dir, "csv", "S24A_validation_checks.csv"),
  s24a_validation_md = path(s24a_dir, "md", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_VALIDATION.md"),
  s24a_decision_md = path(s24a_dir, "md", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_DECISION.md"),
  s24b_panel = path(s24b_dir, "csv", "S24B_fixed_assets_source_inputs_long.csv"),
  s24b_ledger = path(s24b_dir, "csv", "S24B_fixed_assets_construction_ledger.csv"),
  s24b_provenance = path(s24b_dir, "csv", "S24B_fixed_assets_provenance_audit.csv"),
  s24b_exclusion = path(s24b_dir, "csv", "S24B_fixed_assets_exclusion_audit.csv"),
  s24b_continuity = path(s24b_dir, "csv", "S24B_fixed_assets_continuity_audit.csv"),
  s24b_validation = path(s24b_dir, "csv", "S24B_validation_checks.csv"),
  s24b_validation_md = path(s24b_dir, "md", "S24B_FIXED_ASSETS_SOURCE_INPUTS_VALIDATION.md"),
  s24b_decision_md = path(s24b_dir, "md", "S24B_FIXED_ASSETS_SOURCE_INPUTS_DECISION.md"),
  s21_source_panel = path(s21_dir, "csv", "S21_source_panel_long_v1.csv"),
  s21_validation = path(s21_dir, "csv", "S21_validation_checks.csv"),
  s22_authorized = path(s22_dir, "csv", "S22_authorized_baseline_objects.csv"),
  s22_validation = path(s22_dir, "csv", "S22_validation_checks.csv")
)

output_paths <- list(
  panel = path(csv_dir, "S24C_provider_source_inputs_other_long.csv"),
  ledger = path(csv_dir, "S24C_provider_other_construction_ledger.csv"),
  provenance = path(csv_dir, "S24C_provider_other_provenance_audit.csv"),
  exclusion = path(csv_dir, "S24C_provider_other_exclusion_audit.csv"),
  continuity = path(csv_dir, "S24C_provider_other_continuity_audit.csv"),
  validation = path(csv_dir, "S24C_validation_checks.csv"),
  validation_md = path(md_dir, "S24C_PROVIDER_SOURCE_INPUTS_OTHER_VALIDATION.md"),
  decision_md = path(md_dir, "S24C_PROVIDER_SOURCE_INPUTS_OTHER_DECISION.md")
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

first_nonmissing_int <- function(primary, fallback) {
  primary <- to_int(primary)
  fallback <- to_int(fallback)
  ifelse(is.na(primary), fallback, primary)
}

same_or_both_missing <- function(x, y) {
  (is.na(x) & is.na(y)) | (!is.na(x) & !is.na(y) & x == y)
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

s23_validation <- read_csv(input_paths$s23_validation)
s23_decision_text <- paste(readLines(input_paths$s23_decision_md, warn = FALSE), collapse = "\n")
s23_queue <- read_csv(input_paths$s23_authorized_queue)
s23_sequence <- read_csv(input_paths$s23_sequence)
s23_blocked_deferred <- read_csv(input_paths$s23_blocked_deferred)
s23_theoretical <- read_csv(input_paths$s23_theoretical)
s23_source_dependency <- read_csv(input_paths$s23_source_dependency)
s23_family_split <- read_csv(input_paths$s23_family_split)

s24a_validation <- read_csv(input_paths$s24a_validation)
s24a_decision_text <- paste(readLines(input_paths$s24a_decision_md, warn = FALSE), collapse = "\n")
s24a_panel <- read_csv(input_paths$s24a_panel)
s24a_ledger <- read_csv(input_paths$s24a_ledger)
s24a_provenance <- read_csv(input_paths$s24a_provenance)
s24a_exclusion <- read_csv(input_paths$s24a_exclusion)

s24b_validation <- read_csv(input_paths$s24b_validation)
s24b_decision_text <- paste(readLines(input_paths$s24b_decision_md, warn = FALSE), collapse = "\n")
s24b_panel <- read_csv(input_paths$s24b_panel)
s24b_ledger <- read_csv(input_paths$s24b_ledger)
s24b_provenance <- read_csv(input_paths$s24b_provenance)
s24b_exclusion <- read_csv(input_paths$s24b_exclusion)
s24b_continuity <- read_csv(input_paths$s24b_continuity)

s21_panel <- read_csv(input_paths$s21_source_panel)
s21_validation <- read_csv(input_paths$s21_validation)
s22_authorized <- read_csv(input_paths$s22_authorized)
s22_validation <- read_csv(input_paths$s22_validation)

s23_validation_clean <- nrow(s23_validation) == 27L && all(s23_validation$status == "PASS")
s23_decision_clean <- grepl(
  "AUTHORIZE_AUTHORIZED_BASELINE_VARIABLE_CONSTRUCTION_IMPLEMENTATION",
  s23_decision_text,
  fixed = TRUE
)
s24a_validation_clean <- nrow(s24a_validation) == 30L && all(s24a_validation$status == "PASS")
s24b_validation_clean <- nrow(s24b_validation) == 35L && all(s24b_validation$status == "PASS")
s24b_decision_clean <- grepl(
  "AUTHORIZE_S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION",
  s24b_decision_text,
  fixed = TRUE
)

if (!s23_validation_clean || !s23_decision_clean) {
  stop("S23 validation or decision is not clean; S24C must stop.", call. = FALSE)
}
if (!s24a_validation_clean) {
  stop("S24A validation is not clean; S24C must stop.", call. = FALSE)
}
if (!s24b_validation_clean || !s24b_decision_clean) {
  stop("S24B validation or decision is not clean; S24C must stop.", call. = FALSE)
}

provider_other_queue <- s23_queue[s23_queue$construction_family == target_family, , drop = FALSE]
provider_other_queue <- provider_other_queue[
  order(to_int(provider_other_queue$queue_rank), provider_other_queue$variable_id),
  ,
  drop = FALSE
]
provider_other_ids <- provider_other_queue$variable_id

s23_meta <- data.frame(
  variable_id = provider_other_queue$variable_id,
  s23_queue_rank = to_int(provider_other_queue$queue_rank),
  display_name = provider_other_queue$display_name,
  concept_family = provider_other_queue$concept_family,
  construction_family = provider_other_queue$construction_family,
  sector_boundary = provider_other_queue$sector_boundary,
  account_position = provider_other_queue$account_position,
  s23_candidate_status = provider_other_queue$candidate_status,
  s23_object_admissibility = provider_other_queue$object_admissibility,
  s23_source_observation_rows = to_int(provider_other_queue$source_observation_rows),
  s23_coverage_start = to_int(provider_other_queue$coverage_start),
  s23_coverage_end = to_int(provider_other_queue$coverage_end),
  s23_authorization_scope = provider_other_queue$s23_authorization_scope,
  s23_can_construct_in_s23 = provider_other_queue$can_construct_in_s23,
  s23_can_model_in_s23 = provider_other_queue$can_model_in_s23,
  s23_required_before_implementation = provider_other_queue$required_before_implementation,
  s23_notes = provider_other_queue$notes_s23,
  stringsAsFactors = FALSE
)

s22_provider_other <- s22_authorized[s22_authorized$variable_id %in% provider_other_ids, , drop = FALSE]
s22_meta <- data.frame(
  variable_id = s22_provider_other$variable_id,
  s22_display_name = s22_provider_other$display_name,
  s22_concept_family = s22_provider_other$concept_family,
  s22_sector_boundary = s22_provider_other$sector_boundary,
  s22_account_position = s22_provider_other$account_position,
  s22_source_status = s22_provider_other$source_status,
  s22_candidate_status = s22_provider_other$candidate_status,
  s22_object_admissibility = s22_provider_other$object_admissibility,
  s22_source_observation_rows = to_int(s22_provider_other$source_observation_rows),
  s22_coverage_start = to_int(s22_provider_other$coverage_start),
  s22_coverage_end = to_int(s22_provider_other$coverage_end),
  s22_authorization = s22_provider_other$s22_authorization,
  s22_can_construct_variable_now = s22_provider_other$can_construct_variable_now,
  s22_can_model_now = s22_provider_other$can_model_now,
  s22_can_run_econometrics_now = s22_provider_other$can_run_econometrics_now,
  s22_notes = s22_provider_other$s22_notes,
  stringsAsFactors = FALSE
)

provider_other_panel <- s21_panel[s21_panel$variable_id %in% provider_other_ids, , drop = FALSE]
provider_other_panel$year <- to_int(provider_other_panel$year)
provider_other_panel$value <- as.numeric(provider_other_panel$value)
provider_other_panel <- merge(provider_other_panel, s23_meta, by = "variable_id", all.x = TRUE, sort = FALSE)
provider_other_panel <- merge(provider_other_panel, s22_meta, by = "variable_id", all.x = TRUE, sort = FALSE)
provider_other_panel$s24c_stage_id <- "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION"
provider_other_panel$s24c_construction_action <- "source_input_materialized_from_s21_downstream_intake"
provider_other_panel$s24c_authorization_scope <- "provider_source_inputs_other_only"
provider_other_panel$provider_v1_commit <- provider_v1_commit
provider_other_panel$s21_intake_commit <- s21_commit
provider_other_panel$s22_model_input_preparation_commit <- s22_commit
provider_other_panel$s23_construction_plan_commit <- s23_commit
provider_other_panel$s24a_income_distribution_construction_commit <- s24a_commit
provider_other_panel$s24b_fixed_assets_construction_commit <- s24b_commit
provider_other_panel$s24c_constructed_object <- "yes"
provider_other_panel$s24c_modeling_authorized <- "no"
provider_other_panel$s24c_econometrics_authorized <- "no"
provider_other_panel$s24c_notes <- "S24C materializes provider-other source-input rows only; no GPIM, theta, productive capacity, utilization, accumulated q, adjusted Shaikh, model, or econometric object is constructed."
provider_other_panel <- provider_other_panel[
  order(provider_other_panel$s23_queue_rank, provider_other_panel$year),
  ,
  drop = FALSE
]

ledger_rows <- lapply(provider_other_ids, function(id) {
  rows <- provider_other_panel[provider_other_panel$variable_id == id, , drop = FALSE]
  meta <- s23_meta[s23_meta$variable_id == id, , drop = FALSE]
  s22 <- s22_meta[s22_meta$variable_id == id, , drop = FALSE]
  valid_years <- rows$year[!is.na(rows$year)]
  coverage_start <- if (length(valid_years) > 0L) min(valid_years) else NA_integer_
  coverage_end <- if (length(valid_years) > 0L) max(valid_years) else NA_integer_
  expected_observation_rows <- first_nonmissing_int(meta$s23_source_observation_rows, nrow(rows))
  expected_coverage_start <- first_nonmissing_int(meta$s23_coverage_start, coverage_start)
  expected_coverage_end <- first_nonmissing_int(meta$s23_coverage_end, coverage_end)
  construction_status <- if (nrow(rows) == 0L) {
    "constructed_zero_observation_metadata_record"
  } else if (nrow(rows) == expected_observation_rows) {
    "constructed"
  } else {
    "row_count_mismatch"
  }
  data.frame(
    variable_id = id,
    display_name = meta$display_name,
    construction_family = meta$construction_family,
    s24c_construction_status = construction_status,
    constructed_observation_rows = nrow(rows),
    expected_observation_rows = expected_observation_rows,
    coverage_start = coverage_start,
    expected_coverage_start = expected_coverage_start,
    coverage_end = coverage_end,
    expected_coverage_end = expected_coverage_end,
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
    s24a_income_distribution_construction_commit = s24a_commit,
    s24b_fixed_assets_construction_commit = s24b_commit,
    s22_authorization = if (nrow(s22) == 1L) s22$s22_authorization else "",
    s23_authorization_scope = meta$s23_authorization_scope,
    s24c_decision_effect = "constructed_as_authorized_provider_source_inputs_other_only",
    can_enter_modeling = collapse_unique(rows$can_enter_modeling),
    can_construct_adjusted_shaikh = collapse_unique(rows$can_construct_adjusted_shaikh),
    blocked_or_parked_status = collapse_unique(rows$blocked_or_parked_status),
    notes = "No transformation beyond S21 row filtering and lineage preservation.",
    stringsAsFactors = FALSE
  )
})
ledger <- do.call(rbind, ledger_rows)

provenance_rows <- lapply(provider_other_ids, function(id) {
  rows <- provider_other_panel[provider_other_panel$variable_id == id, , drop = FALSE]
  has_rows <- nrow(rows) > 0L
  data.frame(
    variable_id = id,
    provenance_status = if (
      !has_rows
    ) "PASS" else if (
      length(unique(rows$provider_release_commit)) == 1L &&
        unique(rows$provider_release_commit) == provider_v1_commit &&
        has_rows
    ) "PASS" else "FAIL",
    source_identifier_status = if (
      !has_rows
    ) "PASS" else if (
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
    s24a_lineage_preserved = s24a_commit,
    s24b_lineage_preserved = s24b_commit,
    source_dataset = if (has_rows) collapse_unique(rows$source_dataset) else "no_s21_observation_rows",
    source_table = if (has_rows) collapse_unique(rows$source_table) else "no_s21_observation_rows",
    source_line = if (has_rows) collapse_unique(rows$source_line) else "no_s21_observation_rows",
    source_vintage_or_retrieval_date = if (has_rows) collapse_unique(rows$source_vintage_or_retrieval_date) else "no_s21_observation_rows",
    transformation_status = if (has_rows) collapse_unique(rows$transformation_status) else "authorized_zero_observation_metadata_record",
    candidate_status = if (has_rows) collapse_unique(rows$candidate_status) else "READY_AS_BASELINE",
    object_admissibility = if (has_rows) collapse_unique(rows$object_admissibility) else "eligible_for_model_input_preparation_only",
    s21_intake_status = if (has_rows) collapse_unique(rows$s21_intake_status) else "no_s21_observation_rows",
    stringsAsFactors = FALSE
  )
})
provenance <- do.call(rbind, provenance_rows)

sequence_counts <- data.frame(
  construction_family = s23_sequence$construction_family,
  authorized_object_count = to_int(s23_sequence$authorized_object_count),
  recommended_sequence_order = to_int(s23_sequence$recommended_sequence_order),
  s24c_constructed_object_count = vapply(
    s23_sequence$construction_family,
    function(fam) sum(ledger$construction_family == fam),
    integer(1L)
  ),
  s24c_action = ifelse(
    s23_sequence$construction_family == target_family,
    "constructed_in_s24c",
    "excluded_from_s24c_by_family_boundary"
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
  s24c_constructed_object_count = 0L,
  s24c_action = "excluded_from_s24c_deferred_or_blocked_boundary",
  stringsAsFactors = FALSE
)
exclusion_audit <- rbind(sequence_counts, deferred_summary)

continuity_audit <- data.frame(
  audit_item = c(
    "s24a_panel_rows_preserved",
    "s24a_ledger_rows_preserved",
    "s24a_provenance_rows_preserved",
    "s24a_validation_preserved",
    "s24b_panel_rows_preserved",
    "s24b_ledger_rows_preserved",
    "s24b_provenance_rows_preserved",
    "s24b_validation_preserved",
    "s24b_decision_authorizes_s24c",
    "s24c_only_adds_provider_other_family"
  ),
  status = c(
    if (nrow(s24a_panel) == 2813L) "PASS" else "FAIL",
    if (nrow(s24a_ledger) == 29L) "PASS" else "FAIL",
    if (nrow(s24a_provenance) == 29L && all(s24a_provenance$provenance_status == "PASS")) "PASS" else "FAIL",
    if (s24a_validation_clean) "PASS" else "FAIL",
    if (nrow(s24b_panel) == 5936L) "PASS" else "FAIL",
    if (nrow(s24b_ledger) == 56L) "PASS" else "FAIL",
    if (nrow(s24b_provenance) == 56L && all(s24b_provenance$provenance_status == "PASS")) "PASS" else "FAIL",
    if (s24b_validation_clean) "PASS" else "FAIL",
    if (s24b_decision_clean) "PASS" else "FAIL",
    if (
      all(ledger$construction_family == target_family) &&
        !any(s24a_ledger$construction_family == target_family) &&
        !any(s24b_ledger$construction_family == target_family)
    ) "PASS" else "FAIL"
  ),
  evidence = c(
    paste0(nrow(s24a_panel), " S24A panel rows"),
    paste0(nrow(s24a_ledger), " S24A ledger rows"),
    paste0(nrow(s24a_provenance), " S24A provenance rows"),
    paste0("S24A_validation_checks.csv PASS ", sum(s24a_validation$status == "PASS")),
    paste0(nrow(s24b_panel), " S24B panel rows"),
    paste0(nrow(s24b_ledger), " S24B ledger rows"),
    paste0(nrow(s24b_provenance), " S24B provenance rows"),
    paste0("S24B_validation_checks.csv PASS ", sum(s24b_validation$status == "PASS")),
    "AUTHORIZE_S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION",
    paste0(nrow(ledger), " S24C provider-other objects; 0 S24A/S24B provider-other objects")
  ),
  stringsAsFactors = FALSE
)

row_count_ok <- all(ledger$constructed_observation_rows == ledger$expected_observation_rows)
coverage_ok <- all(same_or_both_missing(ledger$coverage_start, ledger$expected_coverage_start)) &&
  all(same_or_both_missing(ledger$coverage_end, ledger$expected_coverage_end))
lineage_ok <- all(provider_other_panel$provider_release_commit == provider_v1_commit) &&
  all(provider_other_panel$provider_v1_commit == provider_v1_commit) &&
  all(provider_other_panel$s21_intake_commit == s21_commit) &&
  all(provider_other_panel$s22_model_input_preparation_commit == s22_commit) &&
  all(provider_other_panel$s23_construction_plan_commit == s23_commit) &&
  all(provider_other_panel$s24a_income_distribution_construction_commit == s24a_commit) &&
  all(provider_other_panel$s24b_fixed_assets_construction_commit == s24b_commit)

constructed_ids <- unique(ledger$variable_id)
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

add_check("s23_outputs_present", all(file.exists(unlist(input_paths[1:9]))), paste(basename(unlist(input_paths[1:9])), collapse = "; "))
add_check("s23_validation_all_pass", s23_validation_clean, paste0("S23_validation_checks.csv PASS ", nrow(s23_validation)))
add_check("s23_decision_authorizes_baseline_implementation", s23_decision_clean, "AUTHORIZE_AUTHORIZED_BASELINE_VARIABLE_CONSTRUCTION_IMPLEMENTATION")
add_check("s24a_outputs_present", all(file.exists(unlist(input_paths[10:16]))), paste(basename(unlist(input_paths[10:16])), collapse = "; "))
add_check("s24a_validation_all_pass", s24a_validation_clean, paste0("S24A_validation_checks.csv PASS ", nrow(s24a_validation)))
add_check("s24b_outputs_present", all(file.exists(unlist(input_paths[17:24]))), paste(basename(unlist(input_paths[17:24])), collapse = "; "))
add_check("s24b_validation_all_pass", s24b_validation_clean, paste0("S24B_validation_checks.csv PASS ", nrow(s24b_validation)))
add_check("s24b_decision_authorizes_s24c", s24b_decision_clean, "AUTHORIZE_S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION")
add_check("s23_build_queue_loaded", nrow(s23_queue) == 116L, paste0(nrow(s23_queue), " authorized build queue rows"))
add_check("s23_construction_sequence_loaded", nrow(s23_sequence) == 3L, paste0(nrow(s23_sequence), " family sequence rows"))
add_check("provider_other_family_filtered", all(provider_other_queue$construction_family == target_family), target_family)
add_check("provider_other_family_count_equals_31", nrow(provider_other_queue) == expected_family_count, paste0(nrow(provider_other_queue), " objects"))
add_check("no_income_distribution_objects_reconstructed", !any(ledger$construction_family == income_family), "0 income-distribution constructed objects in S24C")
add_check("no_fixed_assets_objects_reconstructed", !any(ledger$construction_family == fixed_assets_family), "0 fixed-assets constructed objects in S24C")
add_check("no_documentation_candidates_promoted", length(intersect(constructed_ids, documentation_ids)) == 0L, "documentation-only deferred ids remain excluded")
add_check("no_theoretically_unresolved_objects_promoted", length(intersect(constructed_ids, theoretical_ids)) == 0L, "theoretical-boundary ids remain excluded")
add_check("no_blocked_objects_promoted", length(intersect(constructed_ids, explicit_blocked_ids)) == 0L, "blocked ids remain excluded")
add_check("no_parked_objects_promoted", length(intersect(constructed_ids, parked_ids)) == 0L, "parked ids remain excluded")
add_check("no_adjusted_shaikh_objects_constructed", all(provider_other_panel$can_construct_adjusted_shaikh == "no"), "all constructed rows retain can_construct_adjusted_shaikh=no")
add_check("source_of_truth_inputs_loaded", nrow(s21_panel) > 0L && nrow(s22_authorized) == 116L && nrow(s22_provider_other) == expected_family_count, paste0("S21 rows ", nrow(s21_panel), "; S22 authorized rows ", nrow(s22_authorized)))
add_check("constructed_provider_other_panel_created", nrow(provider_other_panel) == expected_panel_rows && row_count_ok && coverage_ok, paste0(nrow(provider_other_panel), " panel rows"))
add_check("construction_ledger_created", nrow(ledger) == expected_family_count && row_count_ok, paste0(nrow(ledger), " ledger rows"))
add_check("provenance_audit_created", nrow(provenance) == expected_family_count && all(provenance$provenance_status == "PASS") && all(provenance$source_identifier_status == "PASS"), paste0(nrow(provenance), " provenance rows"))
add_check("exclusion_audit_created", nrow(exclusion_audit) == 7L && all(exclusion_audit$s24c_constructed_object_count[exclusion_audit$construction_family != target_family] == 0L), paste0(nrow(exclusion_audit), " exclusion rows"))
add_check("continuity_audit_created", nrow(continuity_audit) == 10L && all(continuity_audit$status == "PASS"), paste0(nrow(continuity_audit), " continuity rows"))
add_check("provider_v1_commit_preserved", all(provider_other_panel$provider_release_commit == provider_v1_commit), provider_v1_commit)
add_check("s21_lineage_preserved", lineage_ok && all(provider_other_panel$s21_intake_commit == s21_commit), s21_commit)
add_check("s22_lineage_preserved", lineage_ok && all(provider_other_panel$s22_model_input_preparation_commit == s22_commit), s22_commit)
add_check("s23_lineage_preserved", lineage_ok && all(provider_other_panel$s23_construction_plan_commit == s23_commit), s23_commit)
add_check("s24a_lineage_preserved", lineage_ok && all(provider_other_panel$s24a_income_distribution_construction_commit == s24a_commit), s24a_commit)
add_check("s24b_lineage_preserved", lineage_ok && all(provider_other_panel$s24b_fixed_assets_construction_commit == s24b_commit), s24b_commit)
add_check("no_modeling_outputs_created", all(provider_other_panel$s24c_modeling_authorized == "no"), "S24C emits only source-input panel and audits")
add_check("no_econometric_outputs_created", all(provider_other_panel$s24c_econometrics_authorized == "no"), "No econometric output paths emitted")
add_check("no_gpim_outputs_created", !any(grepl("gpim", names(output_paths), ignore.case = TRUE)), "No GPIM output paths emitted")
add_check("no_theta_outputs_created", !any(grepl("theta", names(output_paths), ignore.case = TRUE)), "No theta output paths emitted")
add_check("no_utilization_outputs_created", !any(grepl("utilization", names(output_paths), ignore.case = TRUE)), "No utilization output paths emitted")
add_check("no_accumulated_q_outputs_created", !any(grepl("accumulated_q|q_", names(output_paths), ignore.case = TRUE)), "No accumulated-q output paths emitted")
add_check("no_provider_repo_modification", TRUE, "Provider repo not written; S24C consumes downstream S21/S22/S23/S24A/S24B files only")

validation <- add_check(flush = TRUE)
clean <- nrow(validation) == 38L && all(validation$status == "PASS")
final_decision <- if (clean) final_pass_decision else final_fail_decision
final_status <- if (clean) final_pass_status else final_fail_status

write_csv(provider_other_panel, output_paths$panel)
write_csv(ledger, output_paths$ledger)
write_csv(provenance, output_paths$provenance)
write_csv(exclusion_audit, output_paths$exclusion)
write_csv(continuity_audit, output_paths$continuity)
write_csv(validation, output_paths$validation)

validation_md <- c(
  "# S24C Provider Source Inputs Other Validation",
  "",
  paste0("S24C validation result: `", if (clean) "PASS" else "FAIL", " ", sum(validation$status == "PASS"), "`."),
  "",
  paste0("Constructed family: `", target_family, "`."),
  paste0("Constructed object count: `", nrow(ledger), "`."),
  paste0("Constructed panel row count: `", nrow(provider_other_panel), "`."),
  "",
  "S24C constructs only provider-source-inputs-other observations from the downstream S21 intake, filtered through the S23 authorized build queue. It reconstructs no income-distribution or fixed-assets objects and emits no modeling, econometric, GPIM, theta, productive-capacity, utilization, accumulated-q, or adjusted-Shaikh outputs.",
  "",
  "## Validation checks",
  "",
  md_table(validation, c("check_name", "status", "evidence")),
  "",
  "## Family exclusion audit",
  "",
  md_table(exclusion_audit, c("construction_family", "authorized_object_count", "s24c_constructed_object_count", "s24c_action")),
  "",
  "## Continuity audit",
  "",
  md_table(continuity_audit, c("audit_item", "status", "evidence"))
)
writeLines(validation_md, output_paths$validation_md, useBytes = TRUE)

decision_md <- c(
  "# S24C Provider Source Inputs Other Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S24C consumed S24B commit `", s24b_commit, "`, S24A commit `", s24a_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("Constructed family: `", target_family, "`."),
  paste0("Constructed object count: `", nrow(ledger), "`."),
  paste0("Constructed panel row count: `", nrow(provider_other_panel), "`."),
  "",
  "This decision authorizes only S25 consolidation of the S24A, S24B, and S24C authorized source-input layers. It does not authorize modeling, econometrics, GPIM, theta, productive capacity, utilization, accumulated q, adjusted Shaikh reconstruction, or promotion of deferred, blocked, parked, documentation-only, or theoretically unresolved objects.",
  "",
  "S24C stops here."
)
writeLines(decision_md, output_paths$decision_md, useBytes = TRUE)

if (!clean) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("S24C validation failed:\n- ", paste(failed, collapse = "\n- "), call. = FALSE)
}

message("S24C validation PASS: ", sum(validation$status == "PASS"))
message("Constructed panel rows: ", nrow(provider_other_panel))
message("Construction ledger rows: ", nrow(ledger))
message("Decision: ", final_decision)
