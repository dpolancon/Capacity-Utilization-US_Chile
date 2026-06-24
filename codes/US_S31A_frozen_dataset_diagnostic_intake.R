options(stringsAsFactors = FALSE)

stage_id <- "S31A_FROZEN_DATASET_DIAGNOSTIC_INTAKE"
starting_main <- "0c822ecc37e5403d947e106e1d30d1abfae24a62"
release_tag <- "chapter2-us-source-of-truth-v1-2026-06-23"
release_tag_target <- "3d45baa6d726595126772c1b3774bd60e3cf908c"
completion_decision <- "S31A_FROZEN_DATASET_DIAGNOSTIC_INTAKE_COMPLETE"
completion_status <- "S31_DIAGNOSTIC_BASELINE_REGISTERED"

repo_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
release_dir <- file.path(repo_root, "data", "releases", "chapter2_us_source_of_truth_v1")
out_dir <- file.path(repo_root, "output", "US", stage_id)
csv_dir <- file.path(out_dir, "csv")
md_dir <- file.path(out_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(path) {
  read.csv(
    path,
    check.names = FALSE,
    na.strings = c("", "NA"),
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

rel_path <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(repo_root, "/")
  ifelse(startsWith(path, prefix), substring(path, nchar(prefix) + 1L), path)
}

git <- function(args) {
  out <- system2("git", args, stdout = TRUE, stderr = TRUE)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    stop(paste(out, collapse = "\n"), call. = FALSE)
  }
  trimws(out)
}

sha256_file <- function(path) {
  absolute <- normalizePath(path, winslash = "\\", mustWork = TRUE)
  out <- suppressWarnings(system2(
    "certutil",
    c("-hashfile", shQuote(absolute), "SHA256"),
    stdout = TRUE,
    stderr = TRUE
  ))
  hash_line <- out[grepl("^[[:xdigit:][:space:]]{64,}$", out)]
  if (length(hash_line) < 1L) {
    stop(sprintf("Unable to compute SHA-256 for %s", path), call. = FALSE)
  }
  tolower(gsub("[[:space:]]", "", hash_line[1L]))
}

count_lines <- function(path) {
  length(readLines(path, warn = FALSE, encoding = "UTF-8"))
}

file_dimensions <- function(path) {
  extension <- tolower(tools::file_ext(path))
  if (extension == "csv") {
    x <- read_csv(path)
    c(rows = nrow(x), columns = ncol(x))
  } else {
    c(rows = count_lines(path), columns = 1L)
  }
}

scalar_text <- function(x) {
  if (length(x) == 0L || is.na(x)) "" else as.character(x)
}

internal_gap_count <- function(years, present) {
  observed <- years[present]
  if (length(observed) < 2L) return(0L)
  sum(!present & years > min(observed) & years < max(observed))
}

span_count <- function(years, present, side) {
  observed <- years[present]
  if (length(observed) == 0L) return(length(years))
  if (side == "leading") sum(years < min(observed)) else sum(years > max(observed))
}

transformation_flags <- function(transformation) {
  data.frame(
    available_in_level = transformation == "level",
    available_in_log = transformation == "log_level",
    available_in_difference = transformation == "level_change",
    available_in_growth = transformation == "growth_or_log_difference",
    stringsAsFactors = FALSE
  )
}

diagnostic_status <- function(contract_status, transformation) {
  if (contract_status == "DIAGNOSTIC_ONLY") return("REFERENCE_ONLY")
  if (transformation == "level") return("LEVEL_SERIES_AVAILABLE")
  "TRANSFORMED_SERIES_AVAILABLE"
}

required_release_files <- c(
  "README.md",
  "CH2_US_SOURCE_OF_TRUTH_LONG.csv",
  "CH2_US_SOURCE_OF_TRUTH_WIDE.csv",
  "CH2_US_VARIABLE_DICTIONARY.csv",
  "CH2_US_PROVENANCE_LEDGER.csv",
  "CH2_US_ADMISSIBILITY_LEDGER.csv",
  "CH2_US_SUPPORT_WINDOW_LEDGER.csv",
  "CH2_US_FAMILY_INTERFACE_REGISTRY.csv",
  "CH2_US_DOWNSTREAM_CONSUMPTION_CONTRACT.md",
  "CH2_US_RELEASE_MANIFEST.csv",
  "CH2_US_SHA256_MANIFEST.csv",
  "CH2_US_VALIDATION_SUMMARY.md"
)
required_release_paths <- file.path(release_dir, required_release_files)

s30_evidence_paths <- file.path(repo_root, c(
  "output/US/S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY/csv/S30E_completion_record.csv",
  "output/US/S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY/csv/S30E_validation_checks.csv",
  "output/US/S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY/md/S30E_INTEGRATED_DATASET_CLOSURE_REPORT.md",
  "output/US/S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY/md/S30E_INTEGRATED_DATASET_CLOSURE_VALIDATION.md",
  "output/US/S30F_DATASET_RELEASE_FREEZE/csv/S30F_completion_record.csv",
  "output/US/S30F_DATASET_RELEASE_FREEZE/csv/S30F_release_integrity_checks.csv",
  "output/US/S30F_DATASET_RELEASE_FREEZE/md/S30F_DATASET_RELEASE_FREEZE_REPORT.md",
  "output/US/S30F_DATASET_RELEASE_FREEZE/md/S30F_DATASET_RELEASE_FREEZE_VALIDATION.md",
  "output/US/S30F_DATASET_RELEASE_FREEZE/md/S30F_DATASET_RELEASE_HANDOFF.md",
  "output/US/S30F_DATASET_RELEASE_FREEZE/md/S30F_DECISION.md"
))

all_input_paths <- c(required_release_paths, s30_evidence_paths)
missing_inputs <- all_input_paths[!file.exists(all_input_paths)]
if (length(missing_inputs) > 0L) {
  stop(
    paste(
      "HUMAN_REVIEW_REQUIRED_S30_RELEASE_INTEGRITY",
      "Dataset remediation belongs to S30.",
      paste(rel_path(missing_inputs), collapse = "\n"),
      sep = "\n"
    ),
    call. = FALSE
  )
}

input_hash_before <- vapply(all_input_paths, sha256_file, character(1))

current_branch <- git(c("branch", "--show-current"))
current_head <- git(c("rev-parse", "HEAD"))
tag_target_actual <- git(c("rev-list", "-n", "1", release_tag))

release_manifest_path <- file.path(release_dir, "CH2_US_RELEASE_MANIFEST.csv")
sha_manifest_path <- file.path(release_dir, "CH2_US_SHA256_MANIFEST.csv")
long_path <- file.path(release_dir, "CH2_US_SOURCE_OF_TRUTH_LONG.csv")
wide_path <- file.path(release_dir, "CH2_US_SOURCE_OF_TRUTH_WIDE.csv")
dictionary_path <- file.path(release_dir, "CH2_US_VARIABLE_DICTIONARY.csv")
provenance_path <- file.path(release_dir, "CH2_US_PROVENANCE_LEDGER.csv")
admissibility_path <- file.path(release_dir, "CH2_US_ADMISSIBILITY_LEDGER.csv")
support_path <- file.path(release_dir, "CH2_US_SUPPORT_WINDOW_LEDGER.csv")
family_registry_path <- file.path(release_dir, "CH2_US_FAMILY_INTERFACE_REGISTRY.csv")
contract_path <- file.path(release_dir, "CH2_US_DOWNSTREAM_CONSUMPTION_CONTRACT.md")

release_manifest <- read_csv(release_manifest_path)
sha_manifest <- read_csv(sha_manifest_path)
canonical_long <- read_csv(long_path)
canonical_wide <- read_csv(wide_path)
dictionary <- read_csv(dictionary_path)
provenance <- read_csv(provenance_path)
admissibility <- read_csv(admissibility_path)
support <- read_csv(support_path)
family_registry <- read_csv(family_registry_path)
s30f_completion <- read_csv(file.path(
  repo_root,
  "output/US/S30F_DATASET_RELEASE_FREEZE/csv/S30F_completion_record.csv"
))

manifest_exists <- file.exists(file.path(repo_root, release_manifest$release_path))
manifest_bytes_actual <- file.info(file.path(repo_root, release_manifest$release_path))$size
manifest_hash_actual <- vapply(
  file.path(repo_root, release_manifest$release_path),
  sha256_file,
  character(1)
)
manifest_dimensions <- t(vapply(
  file.path(repo_root, release_manifest$release_path),
  file_dimensions,
  numeric(2)
))

sha_exists <- file.exists(file.path(repo_root, sha_manifest$path))
sha_actual <- vapply(
  file.path(repo_root, sha_manifest$path),
  sha256_file,
  character(1)
)

release_integrity <- data.frame(
  check_id = c(
    paste0("MANIFEST_", seq_len(nrow(release_manifest))),
    paste0("SHA_", seq_len(nrow(sha_manifest)))
  ),
  file = c(release_manifest$release_file, sha_manifest$file),
  path = c(release_manifest$release_path, sha_manifest$path),
  check_type = c(
    rep("release_manifest_file_integrity", nrow(release_manifest)),
    rep("sha256_manifest_verification", nrow(sha_manifest))
  ),
  expected_bytes = c(release_manifest$bytes, rep(NA_real_, nrow(sha_manifest))),
  actual_bytes = c(manifest_bytes_actual, rep(NA_real_, nrow(sha_manifest))),
  expected_rows = c(release_manifest$rows, rep(NA_integer_, nrow(sha_manifest))),
  actual_rows = c(manifest_dimensions[, "rows"], rep(NA_integer_, nrow(sha_manifest))),
  expected_columns = c(release_manifest$columns, rep(NA_integer_, nrow(sha_manifest))),
  actual_columns = c(manifest_dimensions[, "columns"], rep(NA_integer_, nrow(sha_manifest))),
  expected_sha256 = c(release_manifest$sha256, sha_manifest$sha256),
  actual_sha256 = c(manifest_hash_actual, sha_actual),
  exists = c(manifest_exists, sha_exists),
  status = c(
    ifelse(
      manifest_exists &
        manifest_bytes_actual == release_manifest$bytes &
        manifest_dimensions[, "rows"] == release_manifest$rows &
        manifest_dimensions[, "columns"] == release_manifest$columns &
        manifest_hash_actual == tolower(release_manifest$sha256),
      "PASS",
      "FAIL"
    ),
    ifelse(sha_exists & sha_actual == tolower(sha_manifest$sha256), "PASS", "FAIL")
  ),
  stringsAsFactors = FALSE
)

canonical_ids <- unique(canonical_long$variable_id)
dictionary_canonical <- dictionary[match(canonical_ids, dictionary$variable_id), , drop = FALSE]
admissibility_canonical <- admissibility[
  match(canonical_ids, admissibility$variable_id),
  ,
  drop = FALSE
]
support_canonical <- support[match(canonical_ids, support$variable_id), , drop = FALSE]

wide_ids <- setdiff(names(canonical_wide), "year")
long_key_unique <- !any(duplicated(canonical_long[, c("year", "variable_id")]))
wide_year_unique <- !any(duplicated(canonical_wide$year))

reconciliation <- lapply(canonical_ids, function(variable_id) {
  rows <- canonical_long[canonical_long$variable_id == variable_id, c("year", "value")]
  wide_value <- canonical_wide[[variable_id]][match(rows$year, canonical_wide$year)]
  equal <- (is.na(rows$value) & is.na(wide_value)) |
    (!is.na(rows$value) & !is.na(wide_value) & rows$value == wide_value)
  data.frame(
    variable_id = variable_id,
    compared_rows = nrow(rows),
    mismatch_count = sum(!equal),
    status = ifelse(all(equal), "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
})
reconciliation <- do.call(rbind, reconciliation)

years <- canonical_wide$year
inventory_rows <- lapply(canonical_ids, function(variable_id) {
  dict <- dictionary_canonical[dictionary_canonical$variable_id == variable_id, , drop = FALSE]
  adm <- admissibility_canonical[
    admissibility_canonical$variable_id == variable_id,
    ,
    drop = FALSE
  ]
  supp <- support_canonical[support_canonical$variable_id == variable_id, , drop = FALSE]
  values <- canonical_wide[[variable_id]]
  present <- !is.na(values)
  flags <- transformation_flags(dict$transformation[1L])
  status <- diagnostic_status(dict$contract_status[1L], dict$transformation[1L])
  reason <- if (status == "REFERENCE_ONLY") {
    "S30 contract is DIAGNOSTIC_ONLY; retain as a frozen diagnostic reference."
  } else if (status == "LEVEL_SERIES_AVAILABLE") {
    "Frozen canonical object is available in level form for later descriptive diagnostics."
  } else {
    paste0(
      "Frozen canonical object is available only in its existing ",
      dict$transformation[1L],
      " form; S31A creates no transformation."
    )
  }
  observed_years <- years[present]
  data.frame(
    variable_id = variable_id,
    display_name = dict$display_name[1L],
    family = dict$family_id[1L],
    concept = dict$concept[1L],
    unit = dict$unit[1L],
    transformation = dict$transformation[1L],
    S30_contract_status = dict$contract_status[1L],
    analytical_role = dict$analytical_role[1L],
    baseline_or_robustness = dict$baseline_or_robustness[1L],
    S30_canonical_inclusion_status = adm$canonical_inclusion_status[1L],
    contextual_status = ifelse(dict$family_id[1L] == "contextual", "contextual", "not_contextual"),
    alias_status = adm$alias_status[1L],
    S30_metadata_status = adm$metadata_status[1L],
    S30_blocked_status = adm$blocked_status[1L],
    coverage_start = supp$coverage_start[1L],
    coverage_end = supp$coverage_end[1L],
    first_observed_year = ifelse(length(observed_years) > 0L, min(observed_years), NA),
    last_observed_year = ifelse(length(observed_years) > 0L, max(observed_years), NA),
    nonmissing_count = sum(present),
    missing_count = sum(!present),
    missing_share = sum(!present) / length(present),
    internal_gap_count = internal_gap_count(years, present),
    available_in_level = flags$available_in_level,
    available_in_log = flags$available_in_log,
    available_in_difference = flags$available_in_difference,
    available_in_growth = flags$available_in_growth,
    diagnostic_intake_status = status,
    diagnostic_intake_reason = reason,
    stringsAsFactors = FALSE
  )
})
inventory <- do.call(rbind, inventory_rows)
inventory <- inventory[order(inventory$family, inventory$variable_id), ]

support_profile <- inventory[, c(
  "variable_id", "family", "coverage_start", "coverage_end",
  "first_observed_year", "last_observed_year", "nonmissing_count",
  "missing_count", "missing_share", "internal_gap_count"
)]
support_profile$coverage_length <- with(
  support_profile,
  coverage_end - coverage_start + 1L
)
support_profile$leading_missing_span <- vapply(
  inventory$variable_id,
  function(variable_id) {
    present <- !is.na(canonical_wide[[variable_id]])
    span_count(years, present, "leading")
  },
  integer(1)
)
support_profile$trailing_missing_span <- vapply(
  inventory$variable_id,
  function(variable_id) {
    present <- !is.na(canonical_wide[[variable_id]])
    span_count(years, present, "trailing")
  },
  integer(1)
)
support_profile$first_fully_supported_year <- support_canonical$first_fully_supported_year[
  match(support_profile$variable_id, support_canonical$variable_id)
]
support_profile$support_status <- support_canonical$support_status[
  match(support_profile$variable_id, support_canonical$variable_id)
]
support_profile$diagnostic_intake_status <- inventory$diagnostic_intake_status[
  match(support_profile$variable_id, inventory$variable_id)
]

missingness_profile <- support_profile[, c(
  "variable_id", "family", "nonmissing_count", "missing_count",
  "missing_share", "internal_gap_count", "leading_missing_span",
  "trailing_missing_span", "first_observed_year", "last_observed_year"
)]
missingness_profile$policy <- "described_not_modified"

transformation_matrix <- inventory[, c(
  "variable_id", "family", "transformation", "available_in_level",
  "available_in_log", "available_in_difference", "available_in_growth",
  "diagnostic_intake_status"
)]
transformation_matrix$source <- "frozen_S30_variable_dictionary"
transformation_matrix$new_transformation_created <- "no"

contract_audit <- lapply(canonical_ids, function(variable_id) {
  dict <- dictionary_canonical[dictionary_canonical$variable_id == variable_id, , drop = FALSE]
  adm <- admissibility_canonical[
    admissibility_canonical$variable_id == variable_id,
    ,
    drop = FALSE
  ]
  supp <- support_canonical[support_canonical$variable_id == variable_id, , drop = FALSE]
  inv <- inventory[inventory$variable_id == variable_id, , drop = FALSE]
  checks <- c(
    variable_id = identical(inv$variable_id[1L], dict$variable_id[1L]),
    display_name = identical(inv$display_name[1L], dict$display_name[1L]),
    family = identical(inv$family[1L], dict$family_id[1L]),
    concept = identical(inv$concept[1L], dict$concept[1L]),
    unit = identical(inv$unit[1L], dict$unit[1L]),
    transformation = identical(inv$transformation[1L], dict$transformation[1L]),
    contract_status = identical(inv$S30_contract_status[1L], dict$contract_status[1L]),
    analytical_role = identical(inv$analytical_role[1L], dict$analytical_role[1L]),
    baseline_or_robustness = identical(
      inv$baseline_or_robustness[1L],
      dict$baseline_or_robustness[1L]
    ),
    canonical_inclusion_status = identical(
      inv$S30_canonical_inclusion_status[1L],
      adm$canonical_inclusion_status[1L]
    ),
    alias_status = identical(inv$alias_status[1L], adm$alias_status[1L]),
    metadata_status = identical(inv$S30_metadata_status[1L], adm$metadata_status[1L]),
    blocked_status = identical(inv$S30_blocked_status[1L], adm$blocked_status[1L]),
    coverage_start = identical(
      as.integer(inv$coverage_start[1L]),
      as.integer(supp$coverage_start[1L])
    ),
    coverage_end = identical(
      as.integer(inv$coverage_end[1L]),
      as.integer(supp$coverage_end[1L])
    )
  )
  data.frame(
    variable_id = variable_id,
    dictionary_fields_preserved = all(checks),
    canonical_inclusion_status = adm$canonical_inclusion_status[1L],
    alias_status = adm$alias_status[1L],
    metadata_status = adm$metadata_status[1L],
    blocked_status = adm$blocked_status[1L],
    observation_status = adm$observation_status[1L],
    promoted_or_demoted = "no",
    reclassified = "no",
    status = ifelse(all(checks), "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
})
contract_audit <- do.call(rbind, contract_audit)

files_read_manifest <- data.frame(
  path = rel_path(all_input_paths),
  role = c(
    rep("frozen_release_input", length(required_release_paths)),
    rep("committed_S30_intake_evidence", length(s30_evidence_paths))
  ),
  bytes = file.info(all_input_paths)$size,
  sha256 = input_hash_before,
  access_mode = "read_only",
  stringsAsFactors = FALSE
)

checks <- list()
add_check <- function(check_name, condition, evidence) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = sprintf("S31A_VAL_%02d", length(checks) + 1L),
    check_name = check_name,
    status = ifelse(isTRUE(condition), "PASS", "FAIL"),
    evidence = scalar_text(evidence),
    stringsAsFactors = FALSE
  )
}

allowed_execution_branches <- c(
  "feature/s31a-frozen-dataset-diagnostic-intake",
  "integration/s31a-frozen-dataset-diagnostic-intake"
)
add_check(
  "exact_branch",
  current_branch %in% allowed_execution_branches,
  "feature_or_controlled_integration_branch"
)
add_check("exact_base_commit", current_head == starting_main, current_head)
add_check("release_tag_target_unchanged", tag_target_actual == release_tag_target, tag_target_actual)
add_check("all_required_release_files_exist", all(file.exists(required_release_paths)), length(required_release_paths))
add_check("release_manifest_readable", nrow(release_manifest) > 0L, nrow(release_manifest))
add_check("sha256_verification_passes", all(release_integrity$status == "PASS"), paste(table(release_integrity$status), collapse = "; "))
add_check("canonical_long_rows", nrow(canonical_long) == 3637L, nrow(canonical_long))
add_check("canonical_variables", length(canonical_ids) == 37L, length(canonical_ids))
add_check("canonical_wide_rows", nrow(canonical_wide) == 125L, nrow(canonical_wide))
add_check("canonical_wide_variables", length(wide_ids) == 37L, length(wide_ids))
add_check("dataset_union_coverage", min(years) == 1901L && max(years) == 2025L, paste(range(years), collapse = "-"))
add_check("canonical_long_key_unique", long_key_unique, "year + variable_id")
add_check("canonical_wide_year_unique", wide_year_unique, "year")
add_check("long_wide_variable_sets_match", setequal(canonical_ids, wide_ids), length(intersect(canonical_ids, wide_ids)))
add_check("long_wide_values_reconcile", all(reconciliation$status == "PASS"), sum(reconciliation$mismatch_count))
add_check("s30f_decision_matches", s30f_completion$decision[1L] == "AUTHORIZE_DOWNSTREAM_CHAPTER2_SOURCE_OF_TRUTH_DATASET_CONSUMPTION", s30f_completion$decision[1L])
add_check("s30f_status_matches", s30f_completion$status[1L] == "CHAPTER2_US_SOURCE_OF_TRUTH_DATASET_FROZEN", s30f_completion$status[1L])
add_check("all_variables_inventoried", nrow(inventory) == 37L && setequal(inventory$variable_id, canonical_ids), nrow(inventory))
add_check("one_diagnostic_status_per_variable", all(nzchar(inventory$diagnostic_intake_status)) && !anyDuplicated(inventory$variable_id), length(unique(inventory$diagnostic_intake_status)))
add_check("allowed_diagnostic_statuses_only", all(inventory$diagnostic_intake_status %in% c("LEVEL_SERIES_AVAILABLE", "TRANSFORMED_SERIES_AVAILABLE", "REFERENCE_ONLY")), paste(sort(unique(inventory$diagnostic_intake_status)), collapse = "; "))
add_check("s30_contract_fields_preserved", all(contract_audit$status == "PASS"), paste(table(contract_audit$status), collapse = "; "))
add_check("no_new_variable_id", setequal(inventory$variable_id, canonical_ids), "inventory variable IDs equal frozen canonical IDs")
add_check("no_released_value_changed", all(reconciliation$status == "PASS"), "read-only reconciliation")
add_check("no_missing_value_modified", sum(inventory$nonmissing_count) == nrow(canonical_long), sum(inventory$nonmissing_count))
add_check("no_new_transformation", all(transformation_matrix$new_transformation_created == "no"), "frozen transformation metadata only")
add_check("no_estimation_sample", TRUE, "no sample object created")
add_check("no_integration_order_test", TRUE, "S31I remains reserved for integration-order testing")
add_check("no_econometric_test", TRUE, "no econometric routine invoked")
add_check("no_q_theta_capacity_utilization", !any(grepl("(^|_)q($|_)|theta|productive_capacity|capacity_utilization", inventory$variable_id, ignore.case = TRUE)), "canonical ID screen")
add_check("completion_state_is_non_authorizing", !startsWith(completion_decision, "AUTHORIZE_"), completion_decision)
add_check("all_outputs_inside_s31a_namespace", startsWith(rel_path(out_dir), paste0("output/US/", stage_id)), rel_path(out_dir))

validation <- do.call(rbind, checks)

integrity_check_names <- c(
  "release_tag_target_unchanged", "all_required_release_files_exist",
  "release_manifest_readable", "sha256_verification_passes",
  "canonical_long_rows", "canonical_variables", "canonical_wide_rows",
  "canonical_wide_variables", "dataset_union_coverage",
  "canonical_long_key_unique", "canonical_wide_year_unique",
  "long_wide_variable_sets_match", "long_wide_values_reconcile",
  "s30f_decision_matches", "s30f_status_matches"
)
integrity_failed <- any(
  validation$status[validation$check_name %in% integrity_check_names] != "PASS"
)

write_csv(release_integrity, file.path(csv_dir, "S31A_release_integrity_intake.csv"))
write_csv(inventory, file.path(csv_dir, "S31A_released_variable_inventory.csv"))
write_csv(support_profile, file.path(csv_dir, "S31A_variable_support_profile.csv"))
write_csv(missingness_profile, file.path(csv_dir, "S31A_missingness_profile.csv"))
write_csv(transformation_matrix, file.path(csv_dir, "S31A_transformation_availability_matrix.csv"))
write_csv(contract_audit, file.path(csv_dir, "S31A_S30_contract_preservation_audit.csv"))
write_csv(files_read_manifest, file.path(csv_dir, "S31A_files_read_manifest.csv"))
write_csv(validation, file.path(csv_dir, "S31A_validation_checks.csv"))

status_counts <- table(inventory$diagnostic_intake_status)
count_status <- function(status) {
  if (status %in% names(status_counts)) as.integer(status_counts[[status]]) else 0L
}

decision <- if (any(validation$status != "PASS")) "HUMAN_REVIEW_REQUIRED" else completion_decision
status <- if (decision == completion_decision) completion_status else "S31A_DIAGNOSTIC_INTAKE_BLOCKED"
completion <- data.frame(
  stage_id = stage_id,
  decision = decision,
  status = status,
  validation_result = ifelse(all(validation$status == "PASS"), "PASS", "FAIL"),
  validation_status = sprintf("PASS %d/%d", sum(validation$status == "PASS"), nrow(validation)),
  canonical_long_rows = nrow(canonical_long),
  canonical_variables = length(canonical_ids),
  canonical_wide_rows = nrow(canonical_wide),
  coverage_start = min(years),
  coverage_end = max(years),
  level_series_count = count_status("LEVEL_SERIES_AVAILABLE"),
  transformed_series_count = count_status("TRANSFORMED_SERIES_AVAILABLE"),
  level_and_transformed_count = count_status("LEVEL_AND_TRANSFORMED_AVAILABLE"),
  contextual_reference_count = count_status("CONTEXTUAL_REFERENCE"),
  reference_only_count = count_status("REFERENCE_ONLY"),
  not_eligible_count = sum(startsWith(inventory$diagnostic_intake_status, "NOT_ELIGIBLE")),
  human_review_count = sum(startsWith(inventory$diagnostic_intake_status, "HUMAN_REVIEW_REQUIRED")),
  integration_order_tests_run = "no",
  econometric_tests_run = "no",
  stringsAsFactors = FALSE
)
write_csv(completion, file.path(csv_dir, "S31A_completion_record.csv"))

report_lines <- c(
  "# S31A Frozen Dataset Diagnostic Intake Report",
  "",
  paste0("Decision: `", decision, "`"),
  paste0("Status: `", status, "`"),
  "",
  "S31A consumed the frozen S30 source-of-truth release in read-only form. The intake verifies release integrity, registers the 37 canonical variables without changing S30 classifications, and describes only existing support, missingness, and transformation forms.",
  "",
  paste0("- Canonical long rows: `", nrow(canonical_long), "`"),
  paste0("- Canonical variables: `", length(canonical_ids), "`"),
  paste0("- Canonical wide rows: `", nrow(canonical_wide), "`"),
  paste0("- Coverage: `", min(years), "-", max(years), "`"),
  paste0("- Level series: `", count_status("LEVEL_SERIES_AVAILABLE"), "`"),
  paste0("- Existing transformed series: `", count_status("TRANSFORMED_SERIES_AVAILABLE"), "`"),
  paste0("- Reference-only series: `", count_status("REFERENCE_ONLY"), "`"),
  "",
  "No released value, missing value, variable identity, support window, transformation, or S30 classification was changed."
)
writeLines(report_lines, file.path(md_dir, "S31A_FROZEN_DATASET_DIAGNOSTIC_INTAKE_REPORT.md"), useBytes = TRUE)

validation_lines <- c(
  "# S31A Frozen Dataset Diagnostic Intake Validation",
  "",
  paste0("Validation result: `", ifelse(all(validation$status == "PASS"), "PASS", "FAIL"), "`"),
  "",
  paste0("- Passed checks: `", sum(validation$status == "PASS"), "/", nrow(validation), "`"),
  paste0("- SHA-256 failures: `", sum(release_integrity$status != "PASS"), "`"),
  paste0("- Long-wide reconciliation mismatches: `", sum(reconciliation$mismatch_count), "`"),
  paste0("- Contract-preservation failures: `", sum(contract_audit$status != "PASS"), "`"),
  "",
  "Integration-order testing was not run. Econometric testing was not run. S31I remains reserved for integration-order testing."
)
writeLines(validation_lines, file.path(md_dir, "S31A_FROZEN_DATASET_DIAGNOSTIC_INTAKE_VALIDATION.md"), useBytes = TRUE)

roadmap_lines <- c(
  "# S31A Diagnostic Roadmap",
  "",
  "S31A registers the frozen S30 dataset as the immutable baseline for diagnostics. All later S31 work must read the frozen release without correcting, extending, reclassifying, or rebuilding it.",
  "",
  "## Diagnostic Questions After Intake",
  "",
  "- Univariate descriptive diagnostics may examine support, missingness patterns, scale, distribution, and time-profile properties of level and already transformed canonical series.",
  "- Cross-variable diagnostics may compare frozen series only after their support and S30 analytical roles are respected; no complete-case, common-support, or estimation sample is created in S31A.",
  "- Objects with `REFERENCE_ONLY` status remain diagnostic references because S30 classified them as `DIAGNOSTIC_ONLY`.",
  "- Any release-integrity defect, contract ambiguity, or apparent need to alter a variable requires human review and an S30 remediation decision.",
  "- S31I is reserved for integration-order testing.",
  "",
  "Descriptive diagnostics do not authorize modeling. No dataset changes are permitted in S31."
)
writeLines(roadmap_lines, file.path(md_dir, "S31A_DIAGNOSTIC_ROADMAP.md"), useBytes = TRUE)

decision_lines <- c(
  "# S31A Decision",
  "",
  paste0("Decision: `", decision, "`"),
  "",
  paste0("Status: `", status, "`"),
  "",
  if (decision == completion_decision) {
    "The frozen S30 dataset is registered for diagnostic intake. This completion state is not an authorization decision."
  } else {
    "S31A is blocked. Dataset remediation belongs to S30."
  }
)
writeLines(decision_lines, file.path(md_dir, "S31A_DECISION.md"), useBytes = TRUE)

input_hash_after <- vapply(all_input_paths, sha256_file, character(1))
if (!identical(input_hash_before, input_hash_after)) {
  stop("HUMAN_REVIEW_REQUIRED_S30_RELEASE_INTEGRITY\nDataset remediation belongs to S30.\nAn immutable input changed during S31A.", call. = FALSE)
}

if (integrity_failed) {
  stop("HUMAN_REVIEW_REQUIRED_S30_RELEASE_INTEGRITY\nDataset remediation belongs to S30.", call. = FALSE)
}
if (any(validation$status != "PASS")) {
  stop("HUMAN_REVIEW_REQUIRED\nS31A validation failed. Dataset remediation, if required, belongs to S30.", call. = FALSE)
}

message("S31A frozen dataset diagnostic intake completed.")
