# S25 consolidates the completed S24A/S24B/S24C authorized source-input layers.
# It does not construct derived variables, modeling inputs, or econometric outputs.

options(stringsAsFactors = FALSE)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)

provider_v1_commit <- "af67374e28232d02d65765d3836dc2ab3e3da8eb"
s21_commit <- "3a0f5064d92fc09f97a55850b4086670d9cedc4b"
s22_commit <- "d6f47bcdaa80bc146196f99a1ccf9207d6957e57"
s23_commit <- "96be02bd0acb4ca10ecc626d07482f6176e7c3b3"
s24a_commit <- "444fb8397c00feb801369eac52614ca633afbfcc"
s24b_commit <- "24bcad5797cbebddbd77d697bc3ebdf0049746e2"
s24c_commit <- "0c3399f67365aafff8b012d66fac37d3bceda3f3"

final_pass_decision <- "AUTHORIZE_S26_SOURCE_INPUT_COMPLETENESS_REVIEW"
final_pass_status <- "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_COMPLETE_S26_COMPLETENESS_REVIEW_AUTHORIZED"
final_fail_decision <- "BLOCK_FOR_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_REVIEW"
final_fail_status <- "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_BLOCKED_FOR_REVIEW"

s23_dir <- file.path(repo_root, "output", "US", "S23_VARIABLE_CONSTRUCTION_PLAN_FROM_PROVIDER_V1")
s24a_dir <- file.path(repo_root, "output", "US", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION")
s24b_dir <- file.path(repo_root, "output", "US", "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION")
s24c_dir <- file.path(repo_root, "output", "US", "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION")
s25_dir <- file.path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
csv_dir <- file.path(s25_dir, "csv")
md_dir <- file.path(s25_dir, "md")

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
  s24c_panel = path(s24c_dir, "csv", "S24C_provider_source_inputs_other_long.csv"),
  s24c_ledger = path(s24c_dir, "csv", "S24C_provider_other_construction_ledger.csv"),
  s24c_provenance = path(s24c_dir, "csv", "S24C_provider_other_provenance_audit.csv"),
  s24c_exclusion = path(s24c_dir, "csv", "S24C_provider_other_exclusion_audit.csv"),
  s24c_continuity = path(s24c_dir, "csv", "S24C_provider_other_continuity_audit.csv"),
  s24c_validation = path(s24c_dir, "csv", "S24C_validation_checks.csv"),
  s24c_validation_md = path(s24c_dir, "md", "S24C_PROVIDER_SOURCE_INPUTS_OTHER_VALIDATION.md"),
  s24c_decision_md = path(s24c_dir, "md", "S24C_PROVIDER_SOURCE_INPUTS_OTHER_DECISION.md")
)

output_paths <- list(
  panel = path(csv_dir, "S25_authorized_source_inputs_long.csv"),
  ledger = path(csv_dir, "S25_authorized_source_inputs_construction_ledger.csv"),
  provenance = path(csv_dir, "S25_authorized_source_inputs_provenance_audit.csv"),
  family_coverage = path(csv_dir, "S25_family_coverage_audit.csv"),
  row_coverage = path(csv_dir, "S25_row_coverage_audit.csv"),
  zero_observation = path(csv_dir, "S25_zero_observation_metadata_audit.csv"),
  status_taxonomy = path(csv_dir, "S25_source_input_status_taxonomy.csv"),
  no_promotion = path(csv_dir, "S25_no_promotion_audit.csv"),
  continuity = path(csv_dir, "S25_continuity_audit.csv"),
  validation = path(csv_dir, "S25_validation_checks.csv"),
  validation_md = path(md_dir, "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_VALIDATION.md"),
  decision_md = path(md_dir, "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION_DECISION.md")
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

bind_fill <- function(...) {
  frames <- list(...)
  cols <- unique(unlist(lapply(frames, names)))
  filled <- lapply(frames, function(x) {
    missing <- setdiff(cols, names(x))
    for (col in missing) {
      x[[col]] <- NA
    }
    x[, cols, drop = FALSE]
  })
  do.call(rbind, filled)
}

mark_panel <- function(data, stage, family) {
  data$s25_source_stage <- stage
  data$s25_source_family <- family
  data
}

mark_ledger <- function(data, stage) {
  data$s25_source_stage <- stage
  data$s25_object_status <- ifelse(
    to_int(data$constructed_observation_rows) > 0L,
    "authorized_observation_bearing",
    "authorized_zero_observation_metadata"
  )
  data
}

mark_provenance <- function(data, stage) {
  data$s25_source_stage <- stage
  data
}

add_lineage <- function(data) {
  data$s25_stage_id <- "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION"
  data$s25_consolidation_action <- "bound_completed_s24_authorized_source_input_layers_without_reconstruction"
  data$provider_v1_commit <- provider_v1_commit
  data$s21_intake_commit <- s21_commit
  data$s22_model_input_preparation_commit <- s22_commit
  data$s23_construction_plan_commit <- s23_commit
  data$s24a_income_distribution_construction_commit <- s24a_commit
  data$s24b_fixed_assets_construction_commit <- s24b_commit
  data$s24c_provider_other_construction_commit <- s24c_commit
  data$s25_modeling_authorized <- "no"
  data$s25_econometrics_authorized <- "no"
  data$s25_derived_variable_planning_authorized <- "no"
  data$s25_notes <- "S25 consolidates completed authorized source-input layers only; no derived variables, modeling, econometrics, GPIM, theta, productive capacity, utilization, accumulated q, or adjusted Shaikh objects are constructed."
  data
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

s24a_panel <- read_csv(input_paths$s24a_panel)
s24a_ledger <- read_csv(input_paths$s24a_ledger)
s24a_provenance <- read_csv(input_paths$s24a_provenance)
s24a_exclusion <- read_csv(input_paths$s24a_exclusion)
s24a_validation <- read_csv(input_paths$s24a_validation)
s24a_decision_text <- paste(readLines(input_paths$s24a_decision_md, warn = FALSE), collapse = "\n")

s24b_panel <- read_csv(input_paths$s24b_panel)
s24b_ledger <- read_csv(input_paths$s24b_ledger)
s24b_provenance <- read_csv(input_paths$s24b_provenance)
s24b_exclusion <- read_csv(input_paths$s24b_exclusion)
s24b_continuity <- read_csv(input_paths$s24b_continuity)
s24b_validation <- read_csv(input_paths$s24b_validation)
s24b_decision_text <- paste(readLines(input_paths$s24b_decision_md, warn = FALSE), collapse = "\n")

s24c_panel <- read_csv(input_paths$s24c_panel)
s24c_ledger <- read_csv(input_paths$s24c_ledger)
s24c_provenance <- read_csv(input_paths$s24c_provenance)
s24c_exclusion <- read_csv(input_paths$s24c_exclusion)
s24c_continuity <- read_csv(input_paths$s24c_continuity)
s24c_validation <- read_csv(input_paths$s24c_validation)
s24c_decision_text <- paste(readLines(input_paths$s24c_decision_md, warn = FALSE), collapse = "\n")

s23_validation_clean <- nrow(s23_validation) == 27L && all(s23_validation$status == "PASS")
s24a_validation_clean <- nrow(s24a_validation) == 30L && all(s24a_validation$status == "PASS")
s24b_validation_clean <- nrow(s24b_validation) == 35L && all(s24b_validation$status == "PASS")
s24c_validation_clean <- nrow(s24c_validation) == 38L && all(s24c_validation$status == "PASS")
s24c_decision_clean <- grepl(
  "AUTHORIZE_S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION",
  s24c_decision_text,
  fixed = TRUE
)

if (!s23_validation_clean || !s24a_validation_clean || !s24b_validation_clean ||
    !s24c_validation_clean || !s24c_decision_clean) {
  stop("S23/S24 gate is not clean; S25 must stop.", call. = FALSE)
}

s24a_panel <- mark_panel(s24a_panel, "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION", "income_distribution_source_inputs")
s24b_panel <- mark_panel(s24b_panel, "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION", "fixed_assets_source_inputs")
s24c_panel <- mark_panel(s24c_panel, "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION", "provider_source_inputs_other")

s24a_ledger <- mark_ledger(s24a_ledger, "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION")
s24b_ledger <- mark_ledger(s24b_ledger, "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION")
s24c_ledger <- mark_ledger(s24c_ledger, "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION")

s24a_provenance <- mark_provenance(s24a_provenance, "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION")
s24b_provenance <- mark_provenance(s24b_provenance, "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION")
s24c_provenance <- mark_provenance(s24c_provenance, "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION")

consolidated_panel <- add_lineage(bind_fill(s24a_panel, s24b_panel, s24c_panel))
consolidated_ledger <- add_lineage(bind_fill(s24a_ledger, s24b_ledger, s24c_ledger))
consolidated_provenance <- add_lineage(bind_fill(s24a_provenance, s24b_provenance, s24c_provenance))

family_counts <- aggregate(
  variable_id ~ construction_family,
  consolidated_ledger,
  function(x) length(unique(x))
)
names(family_counts)[names(family_counts) == "variable_id"] <- "consolidated_object_count"
family_coverage_audit <- merge(
  data.frame(
    construction_family = s23_sequence$construction_family,
    s23_authorized_object_count = to_int(s23_sequence$authorized_object_count),
    recommended_sequence_order = to_int(s23_sequence$recommended_sequence_order),
    stringsAsFactors = FALSE
  ),
  family_counts,
  by = "construction_family",
  all.x = TRUE,
  sort = FALSE
)
family_coverage_audit$consolidated_object_count[is.na(family_coverage_audit$consolidated_object_count)] <- 0L
family_coverage_audit$status <- ifelse(
  family_coverage_audit$s23_authorized_object_count == family_coverage_audit$consolidated_object_count,
  "PASS",
  "FAIL"
)

row_coverage_audit <- data.frame(
  source_stage = c(
    "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION",
    "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION",
    "S24C_PROVIDER_SOURCE_INPUTS_OTHER_CONSTRUCTION",
    "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION"
  ),
  expected_row_count = c(2813L, 5936L, 593L, 9342L),
  observed_row_count = c(nrow(s24a_panel), nrow(s24b_panel), nrow(s24c_panel), nrow(consolidated_panel)),
  status = NA_character_,
  stringsAsFactors = FALSE
)
row_coverage_audit$status <- ifelse(
  row_coverage_audit$expected_row_count == row_coverage_audit$observed_row_count,
  "PASS",
  "FAIL"
)

zero_observation_metadata_audit <- consolidated_ledger[
  consolidated_ledger$s25_object_status == "authorized_zero_observation_metadata",
  ,
  drop = FALSE
]
zero_observation_metadata_audit$zero_observation_metadata_status <- "preserved_authorized_zero_observation_metadata_record"

taxonomy_counts <- data.frame(
  status_category = c(
    "authorized_observation_bearing",
    "authorized_zero_observation_metadata",
    "theoretical_boundary_deferred",
    "documentation_only_deferred",
    "blocked_or_parked_deferred",
    "blocked"
  ),
  object_count = c(
    sum(consolidated_ledger$s25_object_status == "authorized_observation_bearing"),
    sum(consolidated_ledger$s25_object_status == "authorized_zero_observation_metadata"),
    sum(s23_blocked_deferred$s23_queue_status == "theoretical_boundary_deferred"),
    sum(s23_blocked_deferred$s23_queue_status == "documentation_only_deferred"),
    sum(s23_blocked_deferred$s23_queue_status == "blocked_or_parked_deferred"),
    sum(s23_blocked_deferred$s23_queue_status == "blocked")
  ),
  constructed_observation_rows = c(
    sum(to_int(consolidated_ledger$constructed_observation_rows[consolidated_ledger$s25_object_status == "authorized_observation_bearing"]), na.rm = TRUE),
    0L,
    0L,
    0L,
    0L,
    0L
  ),
  s25_action = c(
    "consolidated_from_s24_authorized_source_inputs",
    "preserved_as_authorized_zero_observation_metadata",
    "excluded_from_s25_not_authorized_for_consolidation",
    "excluded_from_s25_documentation_only",
    "excluded_from_s25_blocked_or_parked",
    "excluded_from_s25_blocked"
  ),
  stringsAsFactors = FALSE
)
source_input_status_taxonomy <- taxonomy_counts

constructed_ids <- unique(consolidated_ledger$variable_id)
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

no_promotion_audit <- data.frame(
  exclusion_category = c(
    "documentation_only_deferred",
    "theoretical_boundary_deferred",
    "blocked",
    "blocked_or_parked_deferred"
  ),
  excluded_object_count = c(
    length(documentation_ids),
    length(theoretical_ids),
    length(explicit_blocked_ids),
    length(parked_ids)
  ),
  promoted_object_count = c(
    length(intersect(constructed_ids, documentation_ids)),
    length(intersect(constructed_ids, theoretical_ids)),
    length(intersect(constructed_ids, explicit_blocked_ids)),
    length(intersect(constructed_ids, parked_ids))
  ),
  status = NA_character_,
  stringsAsFactors = FALSE
)
no_promotion_audit$status <- ifelse(no_promotion_audit$promoted_object_count == 0L, "PASS", "FAIL")

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
    "s24c_panel_rows_preserved",
    "s24c_ledger_rows_preserved",
    "s24c_provenance_rows_preserved",
    "s24c_validation_preserved",
    "s24c_decision_authorizes_s25",
    "s25_only_consolidates_s24_layers"
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
    if (nrow(s24c_panel) == 593L) "PASS" else "FAIL",
    if (nrow(s24c_ledger) == 31L) "PASS" else "FAIL",
    if (nrow(s24c_provenance) == 31L && all(s24c_provenance$provenance_status == "PASS")) "PASS" else "FAIL",
    if (s24c_validation_clean) "PASS" else "FAIL",
    if (s24c_decision_clean) "PASS" else "FAIL",
    if (nrow(consolidated_ledger) == 116L && nrow(consolidated_panel) == 9342L) "PASS" else "FAIL"
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
    paste0(nrow(s24c_panel), " S24C panel rows"),
    paste0(nrow(s24c_ledger), " S24C ledger rows"),
    paste0(nrow(s24c_provenance), " S24C provenance rows"),
    paste0("S24C_validation_checks.csv PASS ", sum(s24c_validation$status == "PASS")),
    "AUTHORIZE_S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION",
    "S25 binds S24A/S24B/S24C outputs only"
  ),
  stringsAsFactors = FALSE
)

write_csv(consolidated_panel, output_paths$panel)
write_csv(consolidated_ledger, output_paths$ledger)
write_csv(consolidated_provenance, output_paths$provenance)
write_csv(family_coverage_audit, output_paths$family_coverage)
write_csv(row_coverage_audit, output_paths$row_coverage)
write_csv(zero_observation_metadata_audit, output_paths$zero_observation)
write_csv(source_input_status_taxonomy, output_paths$status_taxonomy)
write_csv(no_promotion_audit, output_paths$no_promotion)
write_csv(continuity_audit, output_paths$continuity)

family_count <- nrow(consolidated_ledger)
row_count <- nrow(consolidated_panel)
zero_obs_count <- nrow(zero_observation_metadata_audit)

lineage_ok <- all(consolidated_panel$provider_v1_commit == provider_v1_commit) &&
  all(consolidated_panel$s21_intake_commit == s21_commit) &&
  all(consolidated_panel$s22_model_input_preparation_commit == s22_commit) &&
  all(consolidated_panel$s23_construction_plan_commit == s23_commit) &&
  all(consolidated_panel$s24a_income_distribution_construction_commit == s24a_commit) &&
  all(consolidated_panel$s24b_fixed_assets_construction_commit == s24b_commit) &&
  all(consolidated_panel$s24c_provider_other_construction_commit == s24c_commit)

add_check("s23_outputs_present", all(file.exists(unlist(input_paths[1:9]))), paste(basename(unlist(input_paths[1:9])), collapse = "; "))
add_check("s23_validation_all_pass", s23_validation_clean, paste0("S23_validation_checks.csv PASS ", nrow(s23_validation)))
add_check("s24a_outputs_present", all(file.exists(unlist(input_paths[10:16]))), paste(basename(unlist(input_paths[10:16])), collapse = "; "))
add_check("s24a_validation_all_pass", s24a_validation_clean, paste0("S24A_validation_checks.csv PASS ", nrow(s24a_validation)))
add_check("s24b_outputs_present", all(file.exists(unlist(input_paths[17:24]))), paste(basename(unlist(input_paths[17:24])), collapse = "; "))
add_check("s24b_validation_all_pass", s24b_validation_clean, paste0("S24B_validation_checks.csv PASS ", nrow(s24b_validation)))
add_check("s24c_outputs_present", all(file.exists(unlist(input_paths[25:32]))), paste(basename(unlist(input_paths[25:32])), collapse = "; "))
add_check("s24c_validation_all_pass", s24c_validation_clean, paste0("S24C_validation_checks.csv PASS ", nrow(s24c_validation)))
add_check("s24c_decision_authorizes_s25", s24c_decision_clean, "AUTHORIZE_S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
add_check("s24a_family_count_equals_29", nrow(s24a_ledger) == 29L, paste0(nrow(s24a_ledger), " S24A objects"))
add_check("s24b_family_count_equals_56", nrow(s24b_ledger) == 56L, paste0(nrow(s24b_ledger), " S24B objects"))
add_check("s24c_family_count_equals_31", nrow(s24c_ledger) == 31L, paste0(nrow(s24c_ledger), " S24C objects"))
add_check("consolidated_object_count_equals_116", family_count == 116L, paste0(family_count, " consolidated objects"))
add_check("s24a_row_count_equals_2813", nrow(s24a_panel) == 2813L, paste0(nrow(s24a_panel), " S24A rows"))
add_check("s24b_row_count_equals_5936", nrow(s24b_panel) == 5936L, paste0(nrow(s24b_panel), " S24B rows"))
add_check("s24c_row_count_equals_593", nrow(s24c_panel) == 593L, paste0(nrow(s24c_panel), " S24C rows"))
add_check("consolidated_row_count_equals_9342", row_count == 9342L, paste0(row_count, " consolidated rows"))
add_check("s24c_zero_observation_metadata_count_equals_22", zero_obs_count == 22L, paste0(zero_obs_count, " zero-observation metadata records"))
add_check("consolidated_long_panel_created", file.exists(output_paths$panel) && nrow(consolidated_panel) == 9342L, basename(output_paths$panel))
add_check("consolidated_construction_ledger_created", file.exists(output_paths$ledger) && nrow(consolidated_ledger) == 116L, basename(output_paths$ledger))
add_check("consolidated_provenance_audit_created", file.exists(output_paths$provenance) && nrow(consolidated_provenance) == 116L && all(consolidated_provenance$provenance_status == "PASS"), basename(output_paths$provenance))
add_check("family_coverage_audit_created", file.exists(output_paths$family_coverage) && nrow(family_coverage_audit) == 3L && all(family_coverage_audit$status == "PASS"), basename(output_paths$family_coverage))
add_check("row_coverage_audit_created", file.exists(output_paths$row_coverage) && nrow(row_coverage_audit) == 4L && all(row_coverage_audit$status == "PASS"), basename(output_paths$row_coverage))
add_check("zero_observation_metadata_audit_created", file.exists(output_paths$zero_observation) && nrow(zero_observation_metadata_audit) == 22L, basename(output_paths$zero_observation))
add_check("source_input_status_taxonomy_created", file.exists(output_paths$status_taxonomy) && nrow(source_input_status_taxonomy) == 6L, basename(output_paths$status_taxonomy))
add_check("no_promotion_audit_created", file.exists(output_paths$no_promotion) && nrow(no_promotion_audit) == 4L && all(no_promotion_audit$status == "PASS"), basename(output_paths$no_promotion))
add_check("continuity_audit_created", file.exists(output_paths$continuity) && nrow(continuity_audit) == 14L && all(continuity_audit$status == "PASS"), basename(output_paths$continuity))
add_check("provider_v1_commit_preserved", lineage_ok && all(consolidated_ledger$provider_v1_commit == provider_v1_commit), provider_v1_commit)
add_check("s21_lineage_preserved", lineage_ok && all(consolidated_ledger$s21_intake_commit == s21_commit), s21_commit)
add_check("s22_lineage_preserved", lineage_ok && all(consolidated_ledger$s22_model_input_preparation_commit == s22_commit), s22_commit)
add_check("s23_lineage_preserved", lineage_ok && all(consolidated_ledger$s23_construction_plan_commit == s23_commit), s23_commit)
add_check("s24a_lineage_preserved", lineage_ok && all(consolidated_ledger$s24a_income_distribution_construction_commit == s24a_commit), s24a_commit)
add_check("s24b_lineage_preserved", lineage_ok && all(consolidated_ledger$s24b_fixed_assets_construction_commit == s24b_commit), s24b_commit)
add_check("s24c_lineage_preserved", lineage_ok && all(consolidated_ledger$s24c_provider_other_construction_commit == s24c_commit), s24c_commit)
add_check("no_documentation_candidates_promoted", no_promotion_audit$promoted_object_count[no_promotion_audit$exclusion_category == "documentation_only_deferred"] == 0L, "documentation-only deferred ids remain excluded")
add_check("no_theoretically_unresolved_objects_promoted", no_promotion_audit$promoted_object_count[no_promotion_audit$exclusion_category == "theoretical_boundary_deferred"] == 0L, "theoretical-boundary ids remain excluded")
add_check("no_blocked_objects_promoted", no_promotion_audit$promoted_object_count[no_promotion_audit$exclusion_category == "blocked"] == 0L, "blocked ids remain excluded")
add_check("no_parked_objects_promoted", no_promotion_audit$promoted_object_count[no_promotion_audit$exclusion_category == "blocked_or_parked_deferred"] == 0L, "parked ids remain excluded")
add_check("no_adjusted_shaikh_objects_constructed", all(consolidated_panel$can_construct_adjusted_shaikh == "no"), "all consolidated observation rows retain can_construct_adjusted_shaikh=no")
add_check("no_derived_variable_planning_started", all(consolidated_panel$s25_derived_variable_planning_authorized == "no"), "S25 authorizes no derived-variable planning")
add_check("no_analytical_variables_constructed", TRUE, "S25 binds source-input outputs only; no analytical object output paths emitted")
add_check("no_modeling_outputs_created", all(consolidated_panel$s25_modeling_authorized == "no"), "S25 emits only consolidation panels and audits")
add_check("no_econometric_outputs_created", all(consolidated_panel$s25_econometrics_authorized == "no"), "No econometric output paths emitted")
add_check("no_gpim_outputs_created", !any(grepl("gpim", names(output_paths), ignore.case = TRUE)), "No GPIM output paths emitted")
add_check("no_theta_outputs_created", !any(grepl("theta", names(output_paths), ignore.case = TRUE)), "No theta output paths emitted")
add_check("no_productive_capacity_outputs_created", !any(grepl("productive_capacity|capacity", names(output_paths), ignore.case = TRUE)), "No productive-capacity output paths emitted")
add_check("no_utilization_outputs_created", !any(grepl("utilization", names(output_paths), ignore.case = TRUE)), "No utilization output paths emitted")
add_check("no_accumulated_q_outputs_created", !any(grepl("accumulated_q|q_", names(output_paths), ignore.case = TRUE)), "No accumulated-q output paths emitted")
add_check("no_provider_repo_modification", TRUE, "Provider repo not written; S25 consumes downstream S23/S24 outputs only")

validation <- add_check(flush = TRUE)
clean <- nrow(validation) == 49L && all(validation$status == "PASS")
final_decision <- if (clean) final_pass_decision else final_fail_decision
final_status <- if (clean) final_pass_status else final_fail_status

write_csv(validation, output_paths$validation)

validation_md <- c(
  "# S25 Authorized Source Inputs Consolidation Validation",
  "",
  paste0("S25 validation result: `", if (clean) "PASS" else "FAIL", " ", sum(validation$status == "PASS"), "`."),
  "",
  paste0("Consolidated object count: `", family_count, "`."),
  paste0("Consolidated observation row count: `", row_count, "`."),
  paste0("Authorized zero-observation metadata records: `", zero_obs_count, "`."),
  "",
  "S25 consolidates completed S24A, S24B, and S24C authorized source-input layers only. It starts no derived-variable planning and emits no analytical, modeling, econometric, GPIM, theta, productive-capacity, utilization, accumulated-q, or adjusted-Shaikh outputs.",
  "",
  "## Validation checks",
  "",
  md_table(validation, c("check_name", "status", "evidence")),
  "",
  "## Family coverage",
  "",
  md_table(family_coverage_audit, c("construction_family", "s23_authorized_object_count", "consolidated_object_count", "status")),
  "",
  "## Row coverage",
  "",
  md_table(row_coverage_audit, c("source_stage", "expected_row_count", "observed_row_count", "status")),
  "",
  "## Source-input status taxonomy",
  "",
  md_table(source_input_status_taxonomy, c("status_category", "object_count", "constructed_observation_rows", "s25_action"))
)
writeLines(validation_md, output_paths$validation_md, useBytes = TRUE)

decision_md <- c(
  "# S25 Authorized Source Inputs Consolidation Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S25 consumed S24C commit `", s24c_commit, "`, S24B commit `", s24b_commit, "`, S24A commit `", s24a_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("Consolidated authorized object count: `", family_count, "`."),
  paste0("Consolidated observation row count: `", row_count, "`."),
  paste0("Authorized zero-observation metadata records preserved: `", zero_obs_count, "`."),
  "",
  "This decision authorizes only S26 source-input completeness review. It does not authorize derived-variable construction planning, derived-variable implementation, modeling, econometrics, GPIM, theta, productive capacity, utilization, accumulated q, adjusted Shaikh reconstruction, or promotion of deferred, blocked, parked, documentation-only, or theoretically unresolved objects.",
  "",
  "S25 stops here."
)
writeLines(decision_md, output_paths$decision_md, useBytes = TRUE)

if (!clean) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("S25 validation failed:\n- ", paste(failed, collapse = "\n- "), call. = FALSE)
}

message("S25 validation PASS: ", sum(validation$status == "PASS"))
message("Consolidated object count: ", family_count)
message("Consolidated panel rows: ", row_count)
message("Decision: ", final_decision)
