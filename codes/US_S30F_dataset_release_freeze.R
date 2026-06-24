#!/usr/bin/env Rscript

repo_root <- normalizePath(file.path(dirname(commandArgs(trailingOnly = FALSE)[1]), ".."), winslash = "/", mustWork = FALSE)
if (!dir.exists(file.path(repo_root, "output", "US", "S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY"))) {
  repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

stage_id <- "S30F_DATASET_RELEASE_FREEZE"
release_id <- "chapter2_us_source_of_truth_v1"
release_date <- "2026-06-23"
required_s30e_decision <- "AUTHORIZE_S30F_DATASET_RELEASE_FREEZE"
decision <- "AUTHORIZE_DOWNSTREAM_CHAPTER2_SOURCE_OF_TRUTH_DATASET_CONSUMPTION"
status <- "CHAPTER2_US_SOURCE_OF_TRUTH_DATASET_FROZEN"

s30e_dir <- file.path(repo_root, "output", "US", "S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY")
s30e_csv <- file.path(s30e_dir, "csv")
s30e_md <- file.path(s30e_dir, "md")
out_dir <- file.path(repo_root, "output", "US", stage_id)
out_csv <- file.path(out_dir, "csv")
out_md <- file.path(out_dir, "md")
release_dir <- file.path(repo_root, "data", "releases", release_id)

if (dir.exists(out_dir)) {
  unlink(out_dir, recursive = TRUE, force = TRUE)
}
if (dir.exists(release_dir)) {
  unlink(release_dir, recursive = TRUE, force = TRUE)
}
dir.create(out_csv, recursive = TRUE, showWarnings = FALSE)
dir.create(out_md, recursive = TRUE, showWarnings = FALSE)
dir.create(release_dir, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(path) {
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

rel_path <- function(path) {
  gsub("\\\\", "/", sub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", repo_root), "/?"), "", normalizePath(path, winslash = "/", mustWork = FALSE)))
}

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = "\\", mustWork = TRUE)
  out <- suppressWarnings(system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE, stderr = TRUE))
  hash_line <- out[grepl("^[[:xdigit:][:space:]]{64,}$", out)]
  if (length(hash_line) < 1) {
    stop(sprintf("Unable to compute SHA256 for %s", path), call. = FALSE)
  }
  tolower(gsub("[[:space:]]", "", hash_line[1]))
}

file_rows_columns <- function(path) {
  if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    dat <- read_csv(path)
    return(c(rows = nrow(dat), columns = ncol(dat)))
  }
  if (grepl("\\.md$", path, ignore.case = TRUE)) {
    lines <- readLines(path, warn = FALSE)
    return(c(rows = length(lines), columns = 1L))
  }
  c(rows = NA_integer_, columns = NA_integer_)
}

validation <- data.frame(
  check_id = character(),
  status = character(),
  detail = character(),
  stringsAsFactors = FALSE
)

add_check <- function(check_id, ok, detail) {
  validation <<- rbind(
    validation,
    data.frame(
      check_id = check_id,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      detail = detail,
      stringsAsFactors = FALSE
    )
  )
}

require_file <- function(path, check_id) {
  ok <- file.exists(path)
  add_check(check_id, ok, rel_path(path))
  if (!ok) {
    stop(sprintf("Required file missing: %s", path), call. = FALSE)
  }
  path
}

completion <- read_csv(require_file(file.path(s30e_csv, "S30E_completion_record.csv"), "s30e_completion_record_present"))
add_check(
  "s30e_release_authorization_present",
  nrow(completion) == 1 &&
    identical(completion$decision[1], required_s30e_decision) &&
    identical(completion$status[1], "S30E_INTEGRATED_DATASET_CLOSED_AND_VALIDATED"),
  paste(completion$decision[1], completion$status[1], completion$validation_status[1])
)

long_path <- require_file(file.path(s30e_csv, "S30E_canonical_long.csv"), "s30e_canonical_long_present")
wide_path <- require_file(file.path(s30e_csv, "S30E_canonical_wide.csv"), "s30e_canonical_wide_present")
dict_path <- require_file(file.path(s30e_csv, "S30E_variable_dictionary.csv"), "s30e_variable_dictionary_present")
provenance_path <- require_file(file.path(s30e_csv, "S30E_provenance_ledger.csv"), "s30e_provenance_ledger_present")
admissibility_path <- require_file(file.path(s30e_csv, "S30E_admissibility_ledger.csv"), "s30e_admissibility_ledger_present")
support_path <- require_file(file.path(s30e_csv, "S30E_support_window_ledger.csv"), "s30e_support_window_ledger_present")
registry_path <- require_file(file.path(s30e_csv, "S30E_family_interface_registry.csv"), "s30e_family_interface_registry_present")
contract_path <- require_file(file.path(s30e_md, "S30E_DOWNSTREAM_CONSUMPTION_CONTRACT.md"), "s30e_consumption_contract_present")

canonical_long <- read_csv(long_path)
canonical_wide <- read_csv(wide_path)
dictionary <- read_csv(dict_path)
provenance <- read_csv(provenance_path)
admissibility <- read_csv(admissibility_path)
support_windows <- read_csv(support_path)
registry <- read_csv(registry_path)

add_check("long_key_unique", !any(duplicated(canonical_long[, c("year", "variable_id")])), "year + variable_id")
add_check("wide_year_unique", !any(duplicated(canonical_wide$year)), "year")
add_check("long_has_value_column", "value" %in% names(canonical_long), "value")
add_check("no_forbidden_model_outputs", !any(grepl("(^|_)q($|_)|theta|productive_capacity|capacity_utilization|vecm|cointegration|estimation_sample|complete_case", canonical_long$variable_id, ignore.case = TRUE)), "canonical variable_id screen")
add_check("no_metadata_only_rows", all(!is.na(canonical_long$value)), "all canonical long rows carry numeric source values")
add_check("dictionary_covers_long_variables", all(unique(canonical_long$variable_id) %in% dictionary$variable_id), "canonical variable_id subset; dictionary may retain blocked and metadata-only S30E records")
add_check("provenance_covers_long_rows", all(canonical_long$provenance_id %in% provenance$provenance_id), "canonical provenance_id subset")
add_check("admissibility_covers_long_variables", all(unique(canonical_long$variable_id) %in% admissibility$variable_id), "canonical variable_id subset")
add_check("support_covers_long_variables", all(unique(canonical_long$variable_id) %in% support_windows$variable_id), "canonical variable_id subset")
add_check("registry_records_s30a_s30d", all(c("S30A", "S30B", "S30C", "S30D") %in% substr(registry$source_stage, 1, 4)), paste(sort(unique(substr(registry$source_stage, 1, 4))), collapse = ", "))

copy_plan <- data.frame(
  source = c(
    long_path,
    wide_path,
    dict_path,
    provenance_path,
    admissibility_path,
    support_path,
    registry_path,
    contract_path
  ),
  release_file = c(
    "CH2_US_SOURCE_OF_TRUTH_LONG.csv",
    "CH2_US_SOURCE_OF_TRUTH_WIDE.csv",
    "CH2_US_VARIABLE_DICTIONARY.csv",
    "CH2_US_PROVENANCE_LEDGER.csv",
    "CH2_US_ADMISSIBILITY_LEDGER.csv",
    "CH2_US_SUPPORT_WINDOW_LEDGER.csv",
    "CH2_US_FAMILY_INTERFACE_REGISTRY.csv",
    "CH2_US_DOWNSTREAM_CONSUMPTION_CONTRACT.md"
  ),
  role = c(
    "canonical long source-of-truth panel",
    "wide consultation panel",
    "variable dictionary",
    "provenance ledger",
    "admissibility ledger",
    "support-window ledger",
    "family interface registry",
    "downstream consumption contract"
  ),
  stringsAsFactors = FALSE
)
copy_plan$target <- file.path(release_dir, copy_plan$release_file)

for (idx in seq_len(nrow(copy_plan))) {
  ok <- file.copy(copy_plan$source[idx], copy_plan$target[idx], overwrite = TRUE, copy.date = FALSE)
  add_check(paste0("release_copy_", tools::file_path_sans_ext(copy_plan$release_file[idx])), ok, rel_path(copy_plan$target[idx]))
}

release_readme <- file.path(release_dir, "README.md")
readme_lines <- c(
  "# Chapter 2 US Source-of-Truth Dataset v1",
  "",
  paste0("- Release id: `", release_id, "`"),
  paste0("- Release date: `", release_date, "`"),
  paste0("- Source stage: `S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY`"),
  paste0("- Freeze stage: `", stage_id, "`"),
  paste0("- Decision: `", decision, "`"),
  paste0("- Status: `", status, "`"),
  "",
  "This release freezes the canonical S30E integrated Chapter 2 US source-of-truth dataset for downstream chapter consumption.",
  "",
  "The release intentionally excludes productive-capacity, utilization, q, theta, econometric, complete-case, estimation-sample, and S31 artifacts."
)
writeLines(readme_lines, release_readme, useBytes = TRUE)

release_validation_summary <- file.path(release_dir, "CH2_US_VALIDATION_SUMMARY.md")
release_validation_summary_lines <- c(
  "# Chapter 2 US Source-of-Truth Dataset v1 Validation Summary",
  "",
  paste0("- S30E decision: `", required_s30e_decision, "`"),
  paste0("- S30F decision: `", decision, "`"),
  paste0("- S30F status: `", status, "`"),
  paste0("- Canonical long rows: `", nrow(canonical_long), "`"),
  paste0("- Canonical long variables: `", length(unique(canonical_long$variable_id)), "`"),
  paste0("- Canonical wide rows: `", nrow(canonical_wide), "`"),
  paste0("- Canonical wide variables: `", ncol(canonical_wide) - 1, "`"),
  "",
  "S30F performs no analytical recomputation. It freezes validated S30E artifacts, records file integrity evidence, and preserves the no-go boundaries for downstream consumption."
)
writeLines(release_validation_summary_lines, release_validation_summary, useBytes = TRUE)

release_manifest_seed <- data.frame(
  release_file = c(basename(release_readme), copy_plan$release_file, basename(release_validation_summary)),
  role = c("release readme", copy_plan$role, "release validation summary"),
  source_file = c("", rel_path(copy_plan$source), ""),
  stringsAsFactors = FALSE
)
release_manifest_seed$release_path <- file.path(release_dir, release_manifest_seed$release_file)

release_manifest <- release_manifest_seed
release_manifest$release_id <- release_id
release_manifest$stage_id <- stage_id
release_manifest$release_date <- release_date
release_manifest$rows <- NA_integer_
release_manifest$columns <- NA_integer_
release_manifest$bytes <- NA_real_
release_manifest$sha256 <- NA_character_

for (idx in seq_len(nrow(release_manifest))) {
  dims <- file_rows_columns(release_manifest$release_path[idx])
  info <- file.info(release_manifest$release_path[idx])
  release_manifest$rows[idx] <- dims[["rows"]]
  release_manifest$columns[idx] <- dims[["columns"]]
  release_manifest$bytes[idx] <- info$size
  release_manifest$sha256[idx] <- sha256_file(release_manifest$release_path[idx])
}

release_manifest <- release_manifest[, c(
  "release_id", "stage_id", "release_date", "release_file", "release_path",
  "role", "source_file", "rows", "columns", "bytes", "sha256"
)]
release_manifest$release_path <- rel_path(release_manifest$release_path)

release_manifest_path <- file.path(release_dir, "CH2_US_RELEASE_MANIFEST.csv")
write_csv(release_manifest, release_manifest_path)

sha_manifest <- data.frame(
  release_id = release_id,
  release_date = release_date,
  file = c(release_manifest$release_file, basename(release_manifest_path)),
  path = c(release_manifest$release_path, rel_path(release_manifest_path)),
  sha256 = c(release_manifest$sha256, sha256_file(release_manifest_path)),
  stringsAsFactors = FALSE
)
sha_manifest_path <- file.path(release_dir, "CH2_US_SHA256_MANIFEST.csv")
write_csv(sha_manifest, sha_manifest_path)

release_manifest_self <- file_rows_columns(release_manifest_path)
sha_manifest_self <- file_rows_columns(sha_manifest_path)
all_release_files <- c(release_manifest_seed$release_path, release_manifest_path, sha_manifest_path)

release_audit <- data.frame(
  file = basename(all_release_files),
  path = rel_path(all_release_files),
  bytes = file.info(all_release_files)$size,
  sha256 = vapply(all_release_files, sha256_file, character(1)),
  stringsAsFactors = FALSE
)
write_csv(release_audit, file.path(out_csv, "S30F_release_file_inventory.csv"))
write_csv(release_manifest, file.path(out_csv, "S30F_release_manifest.csv"))
write_csv(sha_manifest, file.path(out_csv, "S30F_sha256_manifest.csv"))

copy_audit <- data.frame(
  source_file = rel_path(copy_plan$source),
  release_file = rel_path(copy_plan$target),
  source_sha256 = vapply(copy_plan$source, sha256_file, character(1)),
  release_sha256 = vapply(copy_plan$target, sha256_file, character(1)),
  byte_identical = vapply(seq_len(nrow(copy_plan)), function(i) identical(sha256_file(copy_plan$source[i]), sha256_file(copy_plan$target[i])), logical(1)),
  stringsAsFactors = FALSE
)
write_csv(copy_audit, file.path(out_csv, "S30F_release_copy_audit.csv"))

add_check("all_release_targets_exist", all(file.exists(all_release_files)), paste(length(all_release_files), "release files"))
add_check("copied_files_byte_identical", all(copy_audit$byte_identical), paste(nrow(copy_audit), "copied files"))
add_check("manifest_written", file.exists(release_manifest_path) && release_manifest_self[["rows"]] == nrow(release_manifest), basename(release_manifest_path))
add_check("sha_manifest_written", file.exists(sha_manifest_path) && sha_manifest_self[["rows"]] == nrow(sha_manifest), basename(sha_manifest_path))
add_check("hash_manifest_covers_release_payload", setequal(sha_manifest$file, setdiff(basename(all_release_files), basename(sha_manifest_path))), "sha manifest covers every release file except itself")
add_check("s30f_output_file_inventory_written", file.exists(file.path(out_csv, "S30F_release_file_inventory.csv")), "S30F_release_file_inventory.csv")
add_check("release_folder_contains_no_s31", !any(grepl("S31", all_release_files, ignore.case = TRUE)), "release paths")
add_check("release_folder_contains_only_manifested_files", setequal(normalizePath(list.files(release_dir, full.names = TRUE), winslash = "/", mustWork = TRUE), normalizePath(all_release_files, winslash = "/", mustWork = TRUE)), "release directory inventory equals S30F manifest set")

completion_record <- data.frame(
  stage_id = stage_id,
  release_id = release_id,
  release_date = release_date,
  decision = decision,
  status = status,
  validation_status = sprintf("PASS %d/%d", sum(validation$status == "PASS"), nrow(validation)),
  release_files = length(all_release_files),
  canonical_long_rows = nrow(canonical_long),
  canonical_long_variables = length(unique(canonical_long$variable_id)),
  canonical_wide_rows = nrow(canonical_wide),
  canonical_wide_variables = ncol(canonical_wide) - 1,
  earliest_year = min(canonical_long$year, na.rm = TRUE),
  latest_year = max(canonical_long$year, na.rm = TRUE),
  downstream_consumption_ready = "yes",
  stringsAsFactors = FALSE
)

add_check("completion_record_authorizes_downstream_consumption", identical(completion_record$decision[1], decision) && identical(completion_record$status[1], status), paste(completion_record$decision[1], completion_record$status[1]))

completion_record$validation_status <- sprintf("PASS %d/%d", sum(validation$status == "PASS"), nrow(validation))
write_csv(validation, file.path(out_csv, "S30F_release_integrity_checks.csv"))
write_csv(completion_record, file.path(out_csv, "S30F_completion_record.csv"))

validation_lines <- c(
  "# S30F Dataset Release Freeze Validation",
  "",
  paste0("- Decision: `", decision, "`"),
  paste0("- Status: `", status, "`"),
  paste0("- Validation: `", completion_record$validation_status[1], "`"),
  paste0("- Release files: `", completion_record$release_files[1], "`"),
  "",
  "All release payload files are materialized in `data/releases/chapter2_us_source_of_truth_v1/`; copied S30E artifacts are hash-identical to their S30E sources."
)
writeLines(validation_lines, file.path(out_md, "S30F_DATASET_RELEASE_FREEZE_VALIDATION.md"), useBytes = TRUE)

handoff_lines <- c(
  "# S30F Dataset Release Handoff",
  "",
  paste0("- Release directory: `", rel_path(release_dir), "`"),
  paste0("- Release manifest: `", rel_path(release_manifest_path), "`"),
  paste0("- SHA-256 manifest: `", rel_path(sha_manifest_path), "`"),
  paste0("- Decision: `", decision, "`"),
  "",
  "S30F is the authorization boundary for downstream Chapter 2 source-of-truth dataset consumption. The S30F dataset-consumption decision governs S31 diagnostic work, with S31I reserved for integration-order testing. This handoff does not permit econometric estimation, model selection, q, theta, productive capacity, utilization, complete-case samples, or estimation samples."
)
writeLines(handoff_lines, file.path(out_md, "S30F_DATASET_RELEASE_HANDOFF.md"), useBytes = TRUE)

decision_lines <- c(
  "# S30F Decision",
  "",
  paste0("Decision: `", decision, "`"),
  "",
  paste0("Status: `", status, "`")
)
writeLines(decision_lines, file.path(out_md, "S30F_DECISION.md"), useBytes = TRUE)

release_report_lines <- c(
  "# S30F Dataset Release Freeze Report",
  "",
  paste0("The S30E integrated dataset is frozen as `", release_id, "` for Chapter 2 downstream consumption."),
  "",
  paste0("- Canonical long rows: `", nrow(canonical_long), "`"),
  paste0("- Canonical long variables: `", length(unique(canonical_long$variable_id)), "`"),
  paste0("- Canonical wide rows: `", nrow(canonical_wide), "`"),
  paste0("- Release manifest: `", rel_path(release_manifest_path), "`"),
  paste0("- SHA256 manifest: `", rel_path(sha_manifest_path), "`")
)
writeLines(release_report_lines, file.path(out_md, "S30F_DATASET_RELEASE_FREEZE_REPORT.md"), useBytes = TRUE)

if (any(validation$status != "PASS")) {
  write_csv(validation, file.path(out_csv, "S30F_release_integrity_checks.csv"))
  stop("S30F validation failed; release freeze not authorized", call. = FALSE)
}

cat(decision, "\n")
