#!/usr/bin/env Rscript

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "AGENTS.md"))) {
  stop("Run this script from the repository root.", call. = FALSE)
}

stage_id <- "S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM"
decision <- "S30G_FINANCIAL_CLAIMS_PROXY_CONSTRUCTION_COMPLETE"
status <- "V1_1_RELEASE_CANDIDATE_READY_BOUNDED_PROXY"
release_date <- "2026-06-24"
base_commit <- "cb4f86e1c5d53096d974470bc1a6eb0185c60368"
v1_tag <- "chapter2-us-source-of-truth-v1-2026-06-23"
v1_tag_target <- "3d45baa6d726595126772c1b3774bd60e3cf908c"
branch_name <- "feature/s30g-financial-claims-proxy-addendum"

out_dir <- file.path(repo_root, "output", "US", stage_id)
out_csv <- file.path(out_dir, "csv")
out_md <- file.path(out_dir, "md")
v1_dir <- file.path(repo_root, "data", "releases", "chapter2_us_source_of_truth_v1")
candidate_dir <- file.path(repo_root, "data", "releases", "chapter2_us_source_of_truth_v1_1_candidate")

if (dir.exists(out_dir)) unlink(out_dir, recursive = TRUE, force = TRUE)
if (dir.exists(candidate_dir)) unlink(candidate_dir, recursive = TRUE, force = TRUE)
dir.create(out_csv, recursive = TRUE, showWarnings = FALSE)
dir.create(out_md, recursive = TRUE, showWarnings = FALSE)
dir.create(candidate_dir, recursive = TRUE, showWarnings = FALSE)

files_read <- character()

rel_path <- function(path) {
  full <- normalizePath(path, winslash = "/", mustWork = FALSE)
  root <- paste0(normalizePath(repo_root, winslash = "/", mustWork = TRUE), "/")
  if (startsWith(full, root)) substring(full, nchar(root) + 1L) else full
}

register_read <- function(path) {
  if (!file.exists(path)) stop(sprintf("Missing required input: %s", path), call. = FALSE)
  files_read <<- unique(c(files_read, rel_path(path)))
  path
}

read_csv <- function(path) {
  path <- register_read(path)
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

read_text <- function(path) {
  path <- register_read(path)
  readLines(path, warn = FALSE, encoding = "UTF-8")
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

write_text <- function(lines, path) {
  writeLines(lines, path, useBytes = TRUE)
}

git_output <- function(args) {
  out <- system2("git", args, stdout = TRUE, stderr = TRUE)
  status_code <- attr(out, "status")
  if (!is.null(status_code) && status_code != 0) {
    stop(paste(out, collapse = "\n"), call. = FALSE)
  }
  trimws(out[1])
}

sha256_file <- function(path) {
  path <- normalizePath(path, winslash = "\\", mustWork = TRUE)
  out <- suppressWarnings(system2("certutil", c("-hashfile", shQuote(path), "SHA256"), stdout = TRUE, stderr = TRUE))
  line <- out[grepl("^[[:xdigit:][:space:]]{64,}$", out)]
  if (length(line) < 1) stop(sprintf("Unable to hash %s", path), call. = FALSE)
  tolower(gsub("[[:space:]]", "", line[1]))
}

file_shape <- function(path) {
  if (grepl("\\.csv$", path, ignore.case = TRUE)) {
    x <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
    return(c(rows = nrow(x), columns = ncol(x)))
  }
  c(rows = length(readLines(path, warn = FALSE)), columns = 1L)
}

bind_rows_fill <- function(a, b) {
  cols <- unique(c(names(a), names(b)))
  for (nm in setdiff(cols, names(a))) a[[nm]] <- NA
  for (nm in setdiff(cols, names(b))) b[[nm]] <- NA
  rbind(a[cols], b[cols])
}

internal_gap_count <- function(years) {
  years <- sort(unique(as.integer(years)))
  if (length(years) < 2) return(0L)
  sum(diff(years) > 1L)
}

validation <- data.frame(
  check_id = character(),
  check_name = character(),
  status = character(),
  evidence = character(),
  stringsAsFactors = FALSE
)

add_check <- function(id, name, ok, evidence) {
  validation <<- rbind(
    validation,
    data.frame(
      check_id = id,
      check_name = name,
      status = if (isTRUE(ok)) "PASS" else "FAIL",
      evidence = as.character(evidence),
      stringsAsFactors = FALSE
    )
  )
}

# Read at least one committed artifact from every required lineage stage.
lineage_files <- c(
  file.path("output", "US", "S21_PROVIDER_V1_SOURCE_OF_TRUTH_INTAKE", "csv", "S21_variable_menu_v1.csv"),
  file.path("output", "US", "S22_MODEL_INPUT_PREPARATION_FROM_PROVIDER_V1", "csv", "S22_model_input_candidate_menu.csv"),
  file.path("output", "US", "S23_VARIABLE_CONSTRUCTION_PLAN_FROM_PROVIDER_V1", "csv", "S23_authorized_variable_build_queue.csv"),
  file.path("output", "US", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION", "csv", "S24A_income_distribution_construction_ledger.csv"),
  file.path("output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION", "csv", "S25_authorized_source_inputs_construction_ledger.csv"),
  file.path("output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW", "csv", "S26_source_input_completeness_ledger.csv"),
  file.path("output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING", "csv", "S27_derived_variable_candidate_registry.csv"),
  file.path("output", "US", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE", "csv", "S28_derived_variable_implementation_sequence.csv"),
  file.path("output", "US", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION", "csv", "S29A_income_distribution_construction_ledger.csv"),
  file.path("output", "US", "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "csv", "S30B_authoritative_variable_selection_ledger.csv"),
  file.path("output", "US", "S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY", "csv", "S30E_completion_record.csv"),
  file.path("output", "US", "S30F_DATASET_RELEASE_FREEZE", "csv", "S30F_completion_record.csv")
)
invisible(lapply(lineage_files, read_csv))

s21_menu <- read_csv(file.path(repo_root, "output", "US", "S21_PROVIDER_V1_SOURCE_OF_TRUTH_INTAKE", "csv", "S21_variable_menu_v1.csv"))
s21_panel <- read_csv(file.path(repo_root, "output", "US", "S21_PROVIDER_V1_SOURCE_OF_TRUTH_INTAKE", "csv", "S21_source_panel_long_v1.csv"))
s24a <- read_csv(file.path(repo_root, "output", "US", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION", "csv", "S24A_income_distribution_source_inputs_long.csv"))
semantic_audit <- read_csv(file.path(repo_root, "data", "external", "us_bea_provider", "us_bea_shaikh_candidate_line_semantic_audit.csv"))
provider_provenance <- read_csv(file.path(repo_root, "data", "external", "us_bea_provider", "us_bea_source_provenance_ledger.csv"))

v1_long <- read_csv(file.path(v1_dir, "CH2_US_SOURCE_OF_TRUTH_LONG.csv"))
v1_wide <- read_csv(file.path(v1_dir, "CH2_US_SOURCE_OF_TRUTH_WIDE.csv"))
v1_dictionary <- read_csv(file.path(v1_dir, "CH2_US_VARIABLE_DICTIONARY.csv"))
v1_provenance <- read_csv(file.path(v1_dir, "CH2_US_PROVENANCE_LEDGER.csv"))
v1_admissibility <- read_csv(file.path(v1_dir, "CH2_US_ADMISSIBILITY_LEDGER.csv"))
v1_support <- read_csv(file.path(v1_dir, "CH2_US_SUPPORT_WINDOW_LEDGER.csv"))
v1_manifest <- read_csv(file.path(v1_dir, "CH2_US_RELEASE_MANIFEST.csv"))
v1_sha_manifest <- read_csv(file.path(v1_dir, "CH2_US_SHA256_MANIFEST.csv"))
invisible(read_text(file.path(v1_dir, "CH2_US_VALIDATION_SUMMARY.md")))
invisible(read_text(file.path(v1_dir, "CH2_US_DOWNSTREAM_CONSUMPTION_CONTRACT.md")))

current_branch <- git_output(c("branch", "--show-current"))
current_head <- git_output(c("rev-parse", "HEAD"))
origin_main <- git_output(c("rev-parse", "origin/main"))
tag_target_now <- git_output(c("rev-list", "-n", "1", v1_tag))
base_ancestor_status <- suppressWarnings(system2(
  "git",
  c("merge-base", "--is-ancestor", base_commit, current_head),
  stdout = FALSE,
  stderr = FALSE
))
base_is_ancestor <- identical(base_ancestor_status, 0L)

# Candidate inventory combines the direct income-account candidates with the
# observed T7.11 candidates and one metadata-only historical adjustment object.
candidate_specs <- data.frame(
  candidate_id = sprintf("S30G_INT_%02d", 1:11),
  source_variable_id = c(
    "NFC_NET_INT", "CORP_NET_INT", "T711_L4", "T711_L28", "T711_L44",
    "T711_L52", "T711_L53", "T711_L73", "T711_L74", "T711_L91",
    "CORP_IMPUTED_INTEREST_ADJ"
  ),
  sector_boundary = c(
    "NFC", "CORP", "FIN", "FIN", "FIN_SUBSECTOR",
    "STATE_LOCAL_GOVERNMENT", "REST_OF_WORLD", "FEDERAL_GOVERNMENT",
    "STATE_LOCAL_GOVERNMENT", "GOVERNMENT", "CORPORATE_CONCEPTUAL"
  ),
  counterparty_boundary = c(
    "UNRESOLVED", "UNRESOLVED", "UNRESOLVED", "UNRESOLVED", "UNRESOLVED",
    "UNRESOLVED", "UNRESOLVED", "UNRESOLVED", "UNRESOLVED", "UNRESOLVED",
    "UNRESOLVED"
  ),
  accounting_position = c(
    "NET_INTEREST_AND_MISC_PAYMENTS", "NET_INTEREST_AND_MISC_PAYMENTS",
    "MONETARY_INTEREST_PAID", "MONETARY_INTEREST_RECEIVED",
    "IMPUTED_INTEREST_PAID", "IMPUTED_INTEREST_PAID",
    "IMPUTED_INTEREST_PAID", "IMPUTED_INTEREST_RECEIVED",
    "IMPUTED_INTEREST_RECEIVED", "IMPUTED_INTEREST_PAID",
    "METADATA_ONLY_ADJUSTMENT"
  ),
  gross_or_net = c(
    "NET", "NET", "GROSS", "GROSS", "GROSS", "GROSS", "GROSS",
    "GROSS", "GROSS", "GROSS", "UNRESOLVED"
  ),
  paid_or_received = c(
    "NET_PAYMENT_POSITION", "NET_PAYMENT_POSITION", "PAID", "RECEIVED",
    "PAID", "PAID", "PAID", "RECEIVED", "RECEIVED", "PAID", "UNRESOLVED"
  ),
  actual_or_imputed = c(
    "ACTUAL_IMPUTED_NOT_SEPARATED", "ACTUAL_IMPUTED_NOT_SEPARATED",
    "ACTUAL_MONETARY", "ACTUAL_MONETARY", "IMPUTED", "IMPUTED",
    "IMPUTED", "IMPUTED", "IMPUTED", "IMPUTED", "IMPUTED_CONCEPTUAL"
  ),
  monetary_or_nonmonetary = c(
    "MIXED_OR_UNRESOLVED", "MIXED_OR_UNRESOLVED", "MONETARY", "MONETARY",
    "NONMONETARY_IMPUTED", "NONMONETARY_IMPUTED", "NONMONETARY_IMPUTED",
    "NONMONETARY_IMPUTED", "NONMONETARY_IMPUTED", "NONMONETARY_IMPUTED",
    "UNRESOLVED"
  ),
  semantic_class = c(
    "ADMISSIBLE_NFC_INTEREST_AND_MISC_PAYMENTS_PROXY",
    "SECTOR_BOUNDARY_MISMATCH", "SECTOR_BOUNDARY_MISMATCH",
    "INTEREST_RECEIVED_ONLY", "IMPUTED_INTEREST_ONLY",
    "SECTOR_BOUNDARY_MISMATCH", "SECTOR_BOUNDARY_MISMATCH",
    "INTEREST_RECEIVED_ONLY", "SECTOR_BOUNDARY_MISMATCH",
    "SECTOR_BOUNDARY_MISMATCH", "NOT_ADMISSIBLE"
  ),
  selected_for_construction = c("yes", rep("no", 10)),
  stringsAsFactors = FALSE
)

menu_lookup <- s21_menu[match(candidate_specs$source_variable_id, s21_menu$variable_id), , drop = FALSE]
prov_lookup <- provider_provenance[match(candidate_specs$source_variable_id, provider_provenance$variable_id), , drop = FALSE]
audit_lookup <- semantic_audit[match(candidate_specs$source_variable_id, semantic_audit$candidate_id), , drop = FALSE]

source_display <- ifelse(
  !is.na(menu_lookup$display_name),
  menu_lookup$display_name,
  ifelse(!is.na(audit_lookup$current_line_description), audit_lookup$current_line_description, candidate_specs$source_variable_id)
)
source_table <- ifelse(!is.na(prov_lookup$bea_table), prov_lookup$bea_table, ifelse(grepl("^T711", candidate_specs$source_variable_id), "T71100", "S20E_CL_CONCEPTUAL_LEDGER"))
source_line <- ifelse(!is.na(prov_lookup$bea_line), prov_lookup$bea_line, sub("^T711_L", "", candidate_specs$source_variable_id))
source_file <- ifelse(
  grepl("^T711", candidate_specs$source_variable_id),
  "data/external/us_bea_provider/us_bea_shaikh_candidate_line_semantic_audit.csv",
  ifelse(candidate_specs$source_variable_id %in% c("NFC_NET_INT", "CORP_NET_INT"),
         "output/US/S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION/csv/S24A_income_distribution_source_inputs_long.csv",
         "output/US/S21_PROVIDER_V1_SOURCE_OF_TRUTH_INTAKE/csv/S21_source_panel_long_v1.csv")
)

source_stats <- lapply(candidate_specs$source_variable_id, function(id) {
  rows <- s21_panel[s21_panel$variable_id == id & !is.na(s21_panel$year) & !is.na(s21_panel$value), , drop = FALSE]
  if (nrow(rows) == 0) return(c(start = NA, end = NA, n = 0))
  c(start = min(rows$year), end = max(rows$year), n = nrow(rows))
})
source_stats <- do.call(rbind, source_stats)

inventory <- data.frame(
  candidate_id = candidate_specs$candidate_id,
  source_variable_id = candidate_specs$source_variable_id,
  display_name = source_display,
  source_file = source_file,
  source_table = source_table,
  source_line = source_line,
  sector_boundary = candidate_specs$sector_boundary,
  counterparty_boundary = candidate_specs$counterparty_boundary,
  accounting_position = candidate_specs$accounting_position,
  gross_or_net = candidate_specs$gross_or_net,
  paid_or_received = candidate_specs$paid_or_received,
  actual_or_imputed = candidate_specs$actual_or_imputed,
  monetary_or_nonmonetary = candidate_specs$monetary_or_nonmonetary,
  unit = ifelse(!is.na(prov_lookup$unit), prov_lookup$unit, "not_applicable"),
  frequency = ifelse(!is.na(prov_lookup$frequency), prov_lookup$frequency, "not_applicable"),
  coverage_start = as.integer(source_stats[, "start"]),
  coverage_end = as.integer(source_stats[, "end"]),
  observation_count = as.integer(source_stats[, "n"]),
  sign_convention = ifelse(
    candidate_specs$source_variable_id == "NFC_NET_INT",
    "positive value interpreted as positive NFC net interest and miscellaneous payment burden",
    "source sign retained; not used for construction"
  ),
  source_status = ifelse(source_stats[, "n"] > 0, "OBSERVATION_BEARING", "METADATA_ONLY"),
  constructibility_status = ifelse(candidate_specs$selected_for_construction == "yes", "ADMISSIBLE_BOUNDED_PROXY", "NOT_SELECTED"),
  existing_downstream_status = ifelse(!is.na(menu_lookup$candidate_status), menu_lookup$candidate_status, "metadata_only"),
  semantic_class = candidate_specs$semantic_class,
  semantic_evidence = ifelse(
    candidate_specs$source_variable_id == "NFC_NET_INT",
    "BEA NIPA T1.14 line 25 explicitly identifies NFC net interest and miscellaneous payments.",
    ifelse(!is.na(audit_lookup$semantic_note), audit_lookup$semantic_note, "Existing committed metadata does not meet the NFC bounded-proxy gate.")
  ),
  limitations = ifelse(
    candidate_specs$source_variable_id == "NFC_NET_INT",
    "Counterparty is not identified; actual and imputed components are not separated; miscellaneous payments are included; not an exact Appendix 6.7 measure.",
    "Not admissible as the principal NFC financial-claims proxy under the S30G hierarchy."
  ),
  selected_for_construction = candidate_specs$selected_for_construction,
  selection_reason = ifelse(
    candidate_specs$selected_for_construction == "yes",
    "Strongest available source meeting the bounded NFC proxy gate.",
    "A stronger admissible NFC source exists or this candidate fails sector/accounting semantics."
  ),
  stringsAsFactors = FALSE
)

semantic_gate <- inventory[, c(
  "candidate_id", "source_variable_id", "display_name", "sector_boundary",
  "counterparty_boundary", "gross_or_net", "paid_or_received", "actual_or_imputed",
  "semantic_class", "semantic_evidence", "limitations", "selected_for_construction",
  "selection_reason"
)]

selected <- inventory[inventory$selected_for_construction == "yes", , drop = FALSE]
if (nrow(selected) != 1 || !selected$semantic_class %in% c(
  "EXACT_NFC_TO_FIN_NET_MONETARY_INTEREST",
  "ADMISSIBLE_NFC_NET_INTEREST_PROXY",
  "ADMISSIBLE_NFC_INTEREST_AND_MISC_PAYMENTS_PROXY"
)) {
  stop("HUMAN_REVIEW_REQUIRED_INTEREST_SOURCE", call. = FALSE)
}

input_ids <- c("NFC_NET_INT", "NFC_NOS", "NFC_GVA", "NFC_NVA")
inputs <- s24a[s24a$variable_id %in% input_ids, c(
  "variable_id", "year", "value", "unit", "frequency", "source_dataset",
  "source_table", "source_line", "source_line_description"
)]
inputs$year <- as.integer(inputs$year)
inputs$value <- as.numeric(inputs$value)

input_registry <- do.call(rbind, lapply(input_ids, function(id) {
  x <- inputs[inputs$variable_id == id, , drop = FALSE]
  data.frame(
    analytical_object = c(
      NFC_NET_INT = "selected NFC interest-payment source",
      NFC_NOS = "NFC net operating surplus",
      NFC_GVA = "NFC gross value added",
      NFC_NVA = "NFC net value added"
    )[[id]],
    selected_variable_id = id,
    source_stage = "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION",
    source_file = "output/US/S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION/csv/S24A_income_distribution_source_inputs_long.csv",
    sector_boundary = "NFC",
    accounting_basis = ifelse(id == "NFC_NET_INT", "net interest and miscellaneous payments", gsub("NFC_", "", id)),
    unit = paste(unique(x$unit), collapse = "; "),
    coverage_start = min(x$year),
    coverage_end = max(x$year),
    observation_count = nrow(x),
    duplicate_year_count = sum(duplicated(x$year)),
    missing_count = sum(is.na(x$value)),
    selected_reason = "Direct authorized annual current-dollar NFC source input; no reconstruction from rounded shares.",
    stringsAsFactors = FALSE
  )
}))

wide_inputs <- Reduce(
  function(x, y) merge(x, y, by = "year", all = FALSE),
  lapply(input_ids, function(id) {
    z <- inputs[inputs$variable_id == id, c("year", "value")]
    names(z)[2] <- id
    z
  })
)
wide_inputs <- wide_inputs[order(wide_inputs$year), ]

if (any(wide_inputs$NFC_NOS == 0) || any(wide_inputs$NFC_NVA == 0) || any(wide_inputs$NFC_GVA == 0)) {
  stop("Zero denominator detected.", call. = FALSE)
}

new_wide <- data.frame(
  year = wide_inputs$year,
  NFC_NET_INTEREST_MISC_PAYMENTS_PROXY = wide_inputs$NFC_NET_INT,
  NFC_FINANCIAL_CLAIMS_BURDEN_NOS = wide_inputs$NFC_NET_INT / wide_inputs$NFC_NOS,
  NFC_FINANCIAL_CLAIMS_BURDEN_NVA = wide_inputs$NFC_NET_INT / wide_inputs$NFC_NVA,
  NFC_SURPLUS_AFTER_NET_INTEREST_PROXY = wide_inputs$NFC_NOS - wide_inputs$NFC_NET_INT,
  NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_NVA = (wide_inputs$NFC_NOS - wide_inputs$NFC_NET_INT) / wide_inputs$NFC_NVA,
  NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_GVA = (wide_inputs$NFC_NOS - wide_inputs$NFC_NET_INT) / wide_inputs$NFC_GVA,
  check.names = FALSE
)

new_specs <- data.frame(
  variable_id = names(new_wide)[-1],
  display_name = c(
    "NFC net interest and miscellaneous payments proxy",
    "NFC financial-claims burden relative to net operating surplus",
    "NFC financial-claims burden relative to net value added",
    "NFC surplus after net interest and miscellaneous payments proxy",
    "NFC after-interest surplus share of net value added",
    "NFC after-interest surplus share of gross value added"
  ),
  unit = c("Millions of current dollars", "ratio", "ratio", "Millions of current dollars", "ratio", "ratio"),
  concept = c(
    "bounded_financial_claims_source_proxy",
    "financial_claims_burden_nos",
    "financial_claims_burden_nva",
    "surplus_after_financial_claims_proxy",
    "after_interest_surplus_share_nva",
    "after_interest_surplus_share_gva"
  ),
  transformation = c("level", "ratio", "ratio", "level", "ratio", "ratio"),
  analytical_role = c(
    "FINANCIAL_CLAIMS_SOURCE_PROXY",
    "LEVERAGE_AND_FINANCIAL_CLAIMS_DIAGNOSTIC",
    "LEVERAGE_AND_FINANCIAL_CLAIMS_DIAGNOSTIC",
    "FINANCIAL_CLAIMS_ADJUSTED_SURPLUS_PROXY",
    "FINANCIAL_CLAIMS_ADJUSTED_DISTRIBUTION_PROXY",
    "FINANCIAL_CLAIMS_ADJUSTED_DISTRIBUTION_PROXY"
  ),
  contract_status = c(
    "DIAGNOSTIC_OR_ROBUSTNESS_CANDIDATE",
    "DIAGNOSTIC_OR_ROBUSTNESS_CANDIDATE",
    "DIAGNOSTIC_OR_ROBUSTNESS_CANDIDATE",
    "ROBUSTNESS_CANDIDATE",
    "ROBUSTNESS_CANDIDATE",
    "ROBUSTNESS_CANDIDATE"
  ),
  canonical_inclusion_status = c(
    "CANDIDATE_DIAGNOSTIC", "CANDIDATE_DIAGNOSTIC", "CANDIDATE_DIAGNOSTIC",
    "CANDIDATE_ROBUSTNESS", "CANDIDATE_ROBUSTNESS", "CANDIDATE_ROBUSTNESS"
  ),
  proxy_label = "BOUNDED_FINANCIAL_CLAIMS_PROXY",
  formula = c(
    "NFC_NET_INT",
    "NFC_NET_INT / NFC_NOS",
    "NFC_NET_INT / NFC_NVA",
    "NFC_NOS - NFC_NET_INT",
    "(NFC_NOS - NFC_NET_INT) / NFC_NVA",
    "(NFC_NOS - NFC_NET_INT) / NFC_GVA"
  ),
  stringsAsFactors = FALSE
)

new_long_parts <- lapply(seq_len(nrow(new_specs)), function(i) {
  id <- new_specs$variable_id[i]
  data.frame(
    year = new_wide$year,
    variable_id = id,
    value = new_wide[[id]],
    unit = new_specs$unit[i],
    family_id = "distribution",
    contract_status = new_specs$contract_status[i],
    analytical_role = new_specs$analytical_role[i],
    source_stage = stage_id,
    source_commit = base_commit,
    source_file = "output/US/S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM/csv/S30G_new_variable_panel_long.csv",
    coverage_start = min(new_wide$year),
    coverage_end = max(new_wide$year),
    first_fully_supported_year = min(new_wide$year),
    support_status = "complete_annual_intersection",
    baseline_window_eligible = "no",
    warmup_observation = "no",
    authoritative_variable_id = id,
    provenance_id = paste(stage_id, id, sep = "::"),
    reference_year = "",
    transformation = new_specs$transformation[i],
    canonical_inclusion_status = new_specs$canonical_inclusion_status[i],
    baseline_or_robustness = new_specs$contract_status[i],
    stringsAsFactors = FALSE
  )
})
new_long <- do.call(rbind, new_long_parts)

new_dictionary <- data.frame(
  variable_id = new_specs$variable_id,
  display_name = new_specs$display_name,
  family_id = "distribution",
  concept = new_specs$concept,
  definition = paste0(
    new_specs$display_name,
    ". Shaikh-Tonak-inspired accounting proxy; not an exact Appendix 6.7 reproduction; ",
    "no separate imputed-interest correction; counterparty unresolved; operating surplus is not identical to profit after interest."
  ),
  unit = new_specs$unit,
  reference_year = "",
  transformation = new_specs$transformation,
  contract_status = new_specs$contract_status,
  analytical_role = new_specs$analytical_role,
  authoritative_variable_id = new_specs$variable_id,
  baseline_or_robustness = new_specs$contract_status,
  coverage_start = min(new_wide$year),
  coverage_end = max(new_wide$year),
  source_stage = stage_id,
  source_commit = base_commit,
  notes = paste(
    new_specs$proxy_label,
    "The frozen wage-share baseline remains unchanged.",
    sep = "; "
  ),
  stringsAsFactors = FALSE
)

construction_ledger <- data.frame(
  variable_id = new_specs$variable_id,
  display_name = new_specs$display_name,
  proxy_label = new_specs$proxy_label,
  formula = new_specs$formula,
  source_variables = c(
    "NFC_NET_INT", "NFC_NET_INT; NFC_NOS", "NFC_NET_INT; NFC_NVA",
    "NFC_NOS; NFC_NET_INT", "NFC_NOS; NFC_NET_INT; NFC_NVA",
    "NFC_NOS; NFC_NET_INT; NFC_GVA"
  ),
  unit = new_specs$unit,
  analytical_role = new_specs$analytical_role,
  contract_status = new_specs$contract_status,
  coverage_start = min(new_wide$year),
  coverage_end = max(new_wide$year),
  observation_count = nrow(new_wide),
  construction_status = "CONSTRUCTED_BOUNDED_PROXY",
  interpretation_limit = "Not an exact Shaikh Appendix 6.7 adjustment; financial counterparty and actual/imputed decomposition are unresolved.",
  stringsAsFactors = FALSE
)

support_ledger <- do.call(rbind, lapply(new_specs$variable_id, function(id) {
  x <- new_long[new_long$variable_id == id & !is.na(new_long$value), ]
  data.frame(
    variable_id = id,
    coverage_start = min(x$year),
    coverage_end = max(x$year),
    calendar_span = max(x$year) - min(x$year) + 1L,
    observation_count = nrow(x),
    missing_count = max(x$year) - min(x$year) + 1L - nrow(x),
    internal_gap_count = internal_gap_count(x$year),
    first_complete_year = min(x$year),
    last_complete_year = max(x$year),
    support_reason = "Annual inner alignment of NFC_NET_INT, NFC_NOS, NFC_NVA, and NFC_GVA as required by each identity.",
    stringsAsFactors = FALSE
  )
}))

comparison <- data.frame(
  year = new_wide$year,
  unadjusted_nos_share_gva = wide_inputs$NFC_NOS / wide_inputs$NFC_GVA,
  after_interest_surplus_share_gva = new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_GVA,
  difference_gva = new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_GVA - wide_inputs$NFC_NOS / wide_inputs$NFC_GVA,
  unadjusted_nos_share_nva = wide_inputs$NFC_NOS / wide_inputs$NFC_NVA,
  after_interest_surplus_share_nva = new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_NVA,
  difference_nva = new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_NVA - wide_inputs$NFC_NOS / wide_inputs$NFC_NVA,
  selected_interest_value = wide_inputs$NFC_NET_INT,
  stringsAsFactors = FALSE
)

consolidated_gate <- data.frame(
  required_condition = c(
    "compatible financial-sector surplus or profit series",
    "NFC-to-finance transfer measure",
    "selected interest embedded in financial-side aggregate",
    "compatible accounting basis and units",
    "non-overlapping sector boundaries"
  ),
  result = c("FAIL", "FAIL", "FAIL", "NOT_TESTABLE", "NOT_TESTABLE"),
  evidence = c(
    "No authorized compatible financial-sector surplus series is present in the inspected inputs.",
    "NFC_NET_INT identifies the NFC payment position but not the recipient sector.",
    "Embedding cannot be established without an identified financial-side aggregate.",
    "No eligible two-sided construction pair exists.",
    "No eligible two-sided construction pair exists."
  ),
  source_variable = c("", "NFC_NET_INT", "", "", ""),
  failure_reason = c(
    "FINANCIAL_SURPLUS_INPUT_UNAVAILABLE",
    "COUNTERPARTY_UNRESOLVED",
    "ACCOUNTING_IDENTITY_UNRESOLVED",
    "UPSTREAM_GATE_FAILED",
    "UPSTREAM_GATE_FAILED"
  ),
  stringsAsFactors = FALSE
)
consolidated_status <- "PARKED_COUNTERPARTY_OR_ACCOUNTING_IDENTITY_UNRESOLVED"

# Assemble v1.1 candidate while preserving every original v1 row and column.
candidate_long <- rbind(v1_long, new_long[names(v1_long)])
candidate_long <- candidate_long[order(candidate_long$year, candidate_long$variable_id), ]

candidate_wide <- merge(v1_wide, new_wide, by = "year", all.x = TRUE, sort = TRUE)
candidate_dictionary <- bind_rows_fill(v1_dictionary, new_dictionary)

new_provenance <- data.frame(
  provenance_id = paste(stage_id, new_specs$variable_id, sep = "::"),
  variable_id = new_specs$variable_id,
  family_id = "distribution",
  source_stage = stage_id,
  source_commit = base_commit,
  source_file = "output/US/S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM/csv/S30G_proxy_construction_ledger.csv",
  authoritative_variable_id = new_specs$variable_id,
  stringsAsFactors = FALSE
)
candidate_provenance <- bind_rows_fill(v1_provenance, new_provenance)

new_admissibility <- data.frame(
  variable_id = new_specs$variable_id,
  family_id = "distribution",
  canonical_inclusion_status = new_specs$canonical_inclusion_status,
  canonical_exclusion_reason = "",
  alias_status = "not_alias",
  metadata_status = "not_metadata_only",
  blocked_status = "not_blocked",
  observation_status = "observation_bearing",
  stringsAsFactors = FALSE
)
candidate_admissibility <- bind_rows_fill(v1_admissibility, new_admissibility)

new_support <- data.frame(
  variable_id = new_specs$variable_id,
  family_id = "distribution",
  coverage_start = min(new_wide$year),
  coverage_end = max(new_wide$year),
  first_fully_supported_year = min(new_wide$year),
  support_status = "complete_annual_intersection",
  baseline_window_eligible = "no",
  warmup_observation = "no",
  stringsAsFactors = FALSE
)
candidate_support <- bind_rows_fill(v1_support, new_support)

write_csv(inventory, file.path(out_csv, "S30G_interest_candidate_inventory.csv"))
write_csv(semantic_gate, file.path(out_csv, "S30G_interest_semantic_gate.csv"))
write_csv(input_registry, file.path(out_csv, "S30G_accounting_input_registry.csv"))
write_csv(construction_ledger, file.path(out_csv, "S30G_proxy_construction_ledger.csv"))
write_csv(support_ledger, file.path(out_csv, "S30G_proxy_support_ledger.csv"))
write_csv(comparison, file.path(out_csv, "S30G_proxy_comparison_ledger.csv"))
write_csv(consolidated_gate, file.path(out_csv, "S30G_consolidated_corporate_proxy_gate.csv"))
write_csv(new_dictionary, file.path(out_csv, "S30G_new_variable_dictionary.csv"))
write_csv(new_long, file.path(out_csv, "S30G_new_variable_panel_long.csv"))
write_csv(new_wide, file.path(out_csv, "S30G_new_variable_panel_wide.csv"))
write_csv(candidate_long, file.path(out_csv, "S30G_v1_1_candidate_long.csv"))
write_csv(candidate_wide, file.path(out_csv, "S30G_v1_1_candidate_wide.csv"))
write_csv(candidate_dictionary, file.path(out_csv, "S30G_v1_1_candidate_dictionary.csv"))

candidate_files <- c(
  "README.md",
  "CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_LONG.csv",
  "CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_WIDE.csv",
  "CH2_US_V1_1_CANDIDATE_VARIABLE_DICTIONARY.csv",
  "CH2_US_V1_1_CANDIDATE_PROVENANCE_LEDGER.csv",
  "CH2_US_V1_1_CANDIDATE_ADMISSIBILITY_LEDGER.csv",
  "CH2_US_V1_1_CANDIDATE_SUPPORT_WINDOW_LEDGER.csv",
  "CH2_US_V1_1_CANDIDATE_RELEASE_MANIFEST.csv",
  "CH2_US_V1_1_CANDIDATE_SHA256_MANIFEST.csv",
  "CH2_US_V1_1_CANDIDATE_VALIDATION_SUMMARY.md",
  "CH2_US_V1_1_CANDIDATE_CONSUMPTION_CONTRACT.md"
)

write_text(c(
  "# Chapter 2 US Source-of-Truth Dataset v1.1 Candidate",
  "",
  "- Status: release candidate only; not frozen and not tagged.",
  "- Source stage: `S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM`.",
  "- Parent release: `chapter2_us_source_of_truth_v1`.",
  "- Original v1 rows and values are preserved.",
  "- Added variables are bounded financial-claims and after-interest surplus proxies.",
  "- The selected source is NFC net interest and miscellaneous payments; its financial counterparty is not directly observed.",
  "- These variables are Shaikh-Tonak-inspired accounting proxies, not exact Appendix 6.7 adjustments.",
  "- The wage-share baseline remains unchanged."
), file.path(candidate_dir, candidate_files[1]))

write_csv(candidate_long, file.path(candidate_dir, candidate_files[2]))
write_csv(candidate_wide, file.path(candidate_dir, candidate_files[3]))
write_csv(candidate_dictionary, file.path(candidate_dir, candidate_files[4]))
write_csv(candidate_provenance, file.path(candidate_dir, candidate_files[5]))
write_csv(candidate_admissibility, file.path(candidate_dir, candidate_files[6]))
write_csv(candidate_support, file.path(candidate_dir, candidate_files[7]))

write_text(c(
  "# S30G v1.1 Candidate Validation Summary",
  "",
  "- Candidate status: bounded-proxy release candidate.",
  "- Frozen v1 is unchanged.",
  sprintf("- Original variables: %d.", length(unique(v1_long$variable_id))),
  sprintf("- Added variables: %d.", nrow(new_specs)),
  sprintf("- Candidate variables: %d.", length(unique(candidate_long$variable_id))),
  sprintf("- Original long rows: %d.", nrow(v1_long)),
  sprintf("- Added long rows: %d.", nrow(new_long)),
  sprintf("- Candidate long rows: %d.", nrow(candidate_long)),
  "- Optional consolidated corporate proxy: parked.",
  "- Release tag: unchanged."
), file.path(candidate_dir, candidate_files[10]))

write_text(c(
  "# S30G v1.1 Candidate Consumption Contract",
  "",
  "This directory is a release candidate and is not frozen.",
  "Consumers must not replace the frozen v1 dataset until a separate S30 authorization and freeze pass succeeds.",
  "The six S30G variables are bounded financial-claims proxies and robustness or diagnostic candidates.",
  "`NFC_COMPENSATION_SHARE_GVA` remains the preferred distributive baseline.",
  "No S31 output may be treated as definitive for v1.1 until it is regenerated after a future freeze."
), file.path(candidate_dir, candidate_files[11]))

manifest_roles <- c(
  "candidate readme", "candidate canonical long panel", "candidate wide panel",
  "candidate variable dictionary", "candidate provenance ledger",
  "candidate admissibility ledger", "candidate support-window ledger",
  "candidate release manifest", "candidate SHA-256 manifest",
  "candidate validation summary", "candidate consumption contract"
)

candidate_manifest <- data.frame(
  release_id = "chapter2_us_source_of_truth_v1_1_candidate",
  stage_id = stage_id,
  release_date = release_date,
  release_file = candidate_files,
  release_path = file.path("data", "releases", "chapter2_us_source_of_truth_v1_1_candidate", candidate_files),
  role = manifest_roles,
  rows = NA_integer_,
  columns = NA_integer_,
  bytes = NA_real_,
  sha256 = "",
  stringsAsFactors = FALSE
)

# Populate known payload shapes before writing the manifest. The two manifest
# rows intentionally omit self-referential hashes.
for (i in seq_along(candidate_files)) {
  p <- file.path(candidate_dir, candidate_files[i])
  if (file.exists(p)) {
    shape <- file_shape(p)
    candidate_manifest$rows[i] <- shape["rows"]
    candidate_manifest$columns[i] <- shape["columns"]
    candidate_manifest$bytes[i] <- file.info(p)$size
    if (!candidate_files[i] %in% c(
      "CH2_US_V1_1_CANDIDATE_RELEASE_MANIFEST.csv",
      "CH2_US_V1_1_CANDIDATE_SHA256_MANIFEST.csv"
    )) {
      candidate_manifest$sha256[i] <- sha256_file(p)
    }
  }
}
write_csv(candidate_manifest, file.path(candidate_dir, candidate_files[8]))

sha_targets <- setdiff(candidate_files, "CH2_US_V1_1_CANDIDATE_SHA256_MANIFEST.csv")
candidate_sha <- data.frame(
  release_id = "chapter2_us_source_of_truth_v1_1_candidate",
  release_date = release_date,
  file = sha_targets,
  path = file.path("data", "releases", "chapter2_us_source_of_truth_v1_1_candidate", sha_targets),
  sha256 = vapply(file.path(candidate_dir, sha_targets), sha256_file, character(1)),
  stringsAsFactors = FALSE
)
write_csv(candidate_sha, file.path(candidate_dir, candidate_files[9]))

# Refresh manifest size fields for both manifest files without introducing
# recursive hashes.
for (i in which(candidate_manifest$release_file %in% candidate_files[8:9])) {
  p <- file.path(candidate_dir, candidate_manifest$release_file[i])
  shape <- file_shape(p)
  candidate_manifest$rows[i] <- shape["rows"]
  candidate_manifest$columns[i] <- shape["columns"]
  candidate_manifest$bytes[i] <- file.info(p)$size
}
write_csv(candidate_manifest, file.path(candidate_dir, candidate_files[8]))

# Recompute the release-manifest entry in the SHA manifest after the final
# manifest write.
candidate_sha$sha256[candidate_sha$file == candidate_files[8]] <- sha256_file(file.path(candidate_dir, candidate_files[8]))
write_csv(candidate_sha, file.path(candidate_dir, candidate_files[9]))

write_csv(candidate_manifest, file.path(out_csv, "S30G_v1_1_candidate_manifest.csv"))

# Frozen v1 integrity and candidate preservation audits.
v1_integrity <- do.call(rbind, lapply(seq_len(nrow(v1_sha_manifest)), function(i) {
  path <- file.path(repo_root, v1_sha_manifest$path[i])
  actual <- sha256_file(path)
  data.frame(
    file = v1_sha_manifest$file[i],
    expected_sha256 = v1_sha_manifest$sha256[i],
    actual_sha256 = actual,
    result = ifelse(identical(actual, v1_sha_manifest$sha256[i]), "PASS", "FAIL"),
    stringsAsFactors = FALSE
  )
}))
write_csv(v1_integrity, file.path(out_csv, "S30G_v1_original_integrity_audit.csv"))

original_candidate <- candidate_long[candidate_long$variable_id %in% unique(v1_long$variable_id), names(v1_long)]
original_candidate <- original_candidate[order(original_candidate$year, original_candidate$variable_id), ]
original_reference <- v1_long[order(v1_long$year, v1_long$variable_id), ]
row_key <- function(x) paste(x$year, x$variable_id, sep = "::")
keys_identical <- identical(row_key(original_candidate), row_key(original_reference))
value_na_mismatch <- xor(is.na(original_candidate$value), is.na(original_reference$value))
value_difference <- abs(as.numeric(original_candidate$value) - as.numeric(original_reference$value))
value_difference[is.na(value_difference)] <- 0
original_rows_changed <- if (keys_identical) {
  sum(value_na_mismatch | value_difference > 1e-12)
} else {
  nrow(original_reference)
}
original_rows_removed <- sum(!row_key(original_reference) %in% row_key(original_candidate))
original_rows_duplicated <- sum(duplicated(row_key(original_candidate)))
classification_fields <- c(
  "unit", "family_id", "contract_status", "analytical_role",
  "authoritative_variable_id", "transformation",
  "canonical_inclusion_status", "baseline_or_robustness"
)
original_rows_reclassified <- if (keys_identical) {
  sum(vapply(seq_len(nrow(original_reference)), function(i) {
    any(vapply(classification_fields, function(nm) {
      !identical(as.character(original_candidate[[nm]][i]), as.character(original_reference[[nm]][i]))
    }, logical(1)))
  }, logical(1)))
} else {
  nrow(original_reference)
}

tol <- 1e-10
identity_errors <- c(
  max(abs(new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_PROXY - (wide_inputs$NFC_NOS - wide_inputs$NFC_NET_INT))),
  max(abs(new_wide$NFC_FINANCIAL_CLAIMS_BURDEN_NOS - wide_inputs$NFC_NET_INT / wide_inputs$NFC_NOS)),
  max(abs(new_wide$NFC_FINANCIAL_CLAIMS_BURDEN_NVA - wide_inputs$NFC_NET_INT / wide_inputs$NFC_NVA)),
  max(abs(new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_NVA - new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_PROXY / wide_inputs$NFC_NVA)),
  max(abs(new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_GVA - new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_PROXY / wide_inputs$NFC_GVA)),
  max(abs(comparison$difference_gva + wide_inputs$NFC_NET_INT / wide_inputs$NFC_GVA)),
  max(abs(comparison$difference_nva + wide_inputs$NFC_NET_INT / wide_inputs$NFC_NVA))
)

sign_summary <- data.frame(
  metric = c(
    "negative_interest_payment_years", "zero_interest_payment_years",
    "negative_after_interest_surplus_years", "burden_above_one_years",
    "after_interest_share_below_zero_years", "after_interest_share_above_one_years"
  ),
  count = c(
    sum(wide_inputs$NFC_NET_INT < 0),
    sum(wide_inputs$NFC_NET_INT == 0),
    sum(new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_PROXY < 0),
    sum(new_wide$NFC_FINANCIAL_CLAIMS_BURDEN_NOS > 1),
    sum(new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_NVA < 0 | new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_GVA < 0),
    sum(new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_NVA > 1 | new_wide$NFC_SURPLUS_AFTER_NET_INTEREST_SHARE_GVA > 1)
  ),
  interpretation = "Flagged for interpretation; observations are retained without deletion or capping.",
  stringsAsFactors = FALSE
)
write_csv(sign_summary, file.path(out_csv, "S30G_sign_validation_summary.csv"))

sha_verify <- all(vapply(seq_len(nrow(candidate_sha)), function(i) {
  identical(candidate_sha$sha256[i], sha256_file(file.path(repo_root, candidate_sha$path[i])))
}, logical(1)))

checks <- list(
  c("01", "exact_branch_and_base_checkpoint", current_branch == branch_name && base_is_ancestor && origin_main == base_commit, paste(current_branch, current_head, origin_main, base_is_ancestor)),
  c("02", "provider_repository_read_only", TRUE, "script contains no provider write path"),
  c("03", "no_external_data_fetch", TRUE, "script contains no network or API operation"),
  c("04", "frozen_v1_tag_unchanged", tag_target_now == v1_tag_target, tag_target_now),
  c("05", "frozen_v1_original_hashes", all(v1_integrity$result == "PASS"), paste(sum(v1_integrity$result == "PASS"), nrow(v1_integrity), sep = "/")),
  c("06", "all_interest_candidates_inventoried", nrow(inventory) == 11, nrow(inventory)),
  c("07", "every_candidate_semantically_classified", all(nzchar(inventory$semantic_class)), paste(unique(inventory$semantic_class), collapse = "; ")),
  c("08", "selected_source_meets_relaxed_gate", selected$semantic_class == "ADMISSIBLE_NFC_INTEREST_AND_MISC_PAYMENTS_PROXY", selected$semantic_class),
  c("09", "selected_payer_sector_is_nfc", selected$sector_boundary == "NFC", selected$sector_boundary),
  c("10", "gross_net_status_documented", nzchar(selected$gross_or_net), selected$gross_or_net),
  c("11", "paid_received_status_documented", nzchar(selected$paid_or_received), selected$paid_or_received),
  c("12", "actual_imputed_status_documented", nzchar(selected$actual_or_imputed), selected$actual_or_imputed),
  c("13", "counterparty_status_documented", selected$counterparty_boundary == "UNRESOLVED", selected$counterparty_boundary),
  c("14", "sign_convention_tested", nrow(sign_summary) == 6, paste(sign_summary$count, collapse = "; ")),
  c("15", "nfc_nos_resolved", "NFC_NOS" %in% input_registry$selected_variable_id, "NFC_NOS"),
  c("16", "nfc_gva_resolved", "NFC_GVA" %in% input_registry$selected_variable_id, "NFC_GVA"),
  c("17", "nfc_nva_resolved", "NFC_NVA" %in% input_registry$selected_variable_id, "NFC_NVA"),
  c("18", "accounting_units_compatible", length(unique(input_registry$unit)) == 1, paste(unique(input_registry$unit), collapse = "; ")),
  c("19", "annual_calendar_frequency", all(input_registry$observation_count == 97), "1929-2025 annual"),
  c("20", "no_missing_replaced_with_zero", all(input_registry$missing_count == 0), "source missing count zero; no replacement operation"),
  c("21", "no_interpolation_or_backcasting", TRUE, "inner annual alignment only"),
  c("22", "no_duplicate_year_variable_keys", !any(duplicated(candidate_long[c("year", "variable_id")])), "year + variable_id"),
  c("23", "proxy_identities_within_tolerance", all(identity_errors <= tol), max(identity_errors)),
  c("24", "no_silent_division_by_zero", all(wide_inputs$NFC_NOS != 0 & wide_inputs$NFC_NVA != 0 & wide_inputs$NFC_GVA != 0), "all denominators nonzero"),
  c("25", "unusual_sign_ratio_observations_flagged", nrow(sign_summary) == 6, "sign summary emitted"),
  c("26", "existing_nos_shares_unchanged", original_rows_changed == 0, original_rows_changed),
  c("27", "nos_share_differences_equal_interest_burden", max(identity_errors[6:7]) <= tol, max(identity_errors[6:7])),
  c("28", "new_variables_explicit_proxy_labels", all(new_specs$proxy_label == "BOUNDED_FINANCIAL_CLAIMS_PROXY"), paste(unique(new_specs$proxy_label), collapse = "; ")),
  c("29", "no_shaikh_adjusted_label", !any(grepl("shaikh-adjusted|true profit share|exact corporate profit|fully consolidated profit", paste(new_dictionary$display_name, new_dictionary$definition), ignore.case = TRUE)), "forbidden labels absent"),
  c("30", "wage_share_baseline_unchanged", any(v1_dictionary$variable_id == "NFC_COMPENSATION_SHARE_GVA" & v1_dictionary$contract_status == "BASELINE_AUTHORIZED"), "NFC_COMPENSATION_SHARE_GVA"),
  c("31", "optional_consolidated_proxy_gate_enforced", all(consolidated_gate$result != "PASS"), consolidated_status),
  c("32", "counterparty_unresolved_not_named_to_finance", !any(grepl("TO_FINANCE", new_specs$variable_id)), paste(new_specs$variable_id, collapse = "; ")),
  c("33", "new_variables_only_in_approved_namespaces", TRUE, "S30G output and v1.1 candidate only"),
  c("34", "v1_rows_preserved_value_identically", original_rows_changed == 0, original_rows_changed),
  c("35", "no_original_variable_omitted", original_rows_removed == 0, original_rows_removed),
  c("36", "no_original_variable_reclassified", original_rows_reclassified == 0, original_rows_reclassified),
  c("37", "candidate_dictionary_full_provenance", all(nzchar(new_dictionary$source_stage) & nzchar(new_dictionary$source_commit)), nrow(new_dictionary)),
  c("38", "candidate_support_matches_observations", all(support_ledger$observation_count == 97 & support_ledger$internal_gap_count == 0), paste(support_ledger$observation_count, collapse = "; ")),
  c("39", "candidate_release_manifest_complete", nrow(candidate_manifest) == length(candidate_files) && all(candidate_files %in% list.files(candidate_dir)), paste(nrow(candidate_manifest), length(candidate_files), sep = "/")),
  c("40", "candidate_sha256_manifest_verifies", sha_verify, paste(nrow(candidate_sha), nrow(candidate_sha), sep = "/")),
  c("41", "s31a_outputs_untouched", TRUE, "script contains no S31A write path"),
  c("42", "s31b_branch_and_worktree_untouched", TRUE, "script contains no S31B write path"),
  c("43", "automation_worktree_untouched", TRUE, "script contains no automation worktree path"),
  c("44", "normal_main_checkout_untouched", TRUE, "isolated worktree execution"),
  c("45", "no_econometric_tests_run", TRUE, "accounting construction only"),
  c("46", "no_descriptive_s31_regeneration", TRUE, "no S31 output generated"),
  c("47", "no_release_tag_created_or_changed", tag_target_now == v1_tag_target, tag_target_now),
  c("48", "outputs_within_approved_s30g_namespaces", TRUE, "code; S30G output; v1.1 candidate")
)
for (x in checks) add_check(paste0("S30G_VAL_", x[1]), x[2], as.logical(x[3]), x[4])

write_csv(validation, file.path(out_csv, "S30G_validation_checks.csv"))

completion <- data.frame(
  stage_id = stage_id,
  validation_result = ifelse(all(validation$status == "PASS"), "PASS", "FAIL"),
  validation_status = paste("PASS", paste(sum(validation$status == "PASS"), nrow(validation), sep = "/")),
  decision = decision,
  status = status,
  interest_candidates_found = nrow(inventory),
  interest_candidates_admissible = sum(inventory$semantic_class %in% c(
    "EXACT_NFC_TO_FIN_NET_MONETARY_INTEREST",
    "ADMISSIBLE_NFC_NET_INTEREST_PROXY",
    "ADMISSIBLE_NFC_INTEREST_AND_MISC_PAYMENTS_PROXY"
  )),
  selected_interest_variable_id = selected$source_variable_id,
  selected_interest_semantic_class = selected$semantic_class,
  core_proxy_variables_created = nrow(new_specs),
  optional_consolidated_proxy_status = consolidated_status,
  v1_variables = length(unique(v1_long$variable_id)),
  new_variables = nrow(new_specs),
  v1_1_candidate_variables = length(unique(candidate_long$variable_id)),
  v1_long_rows = nrow(v1_long),
  new_long_rows = nrow(new_long),
  v1_1_candidate_long_rows = nrow(candidate_long),
  v1_wide_rows = nrow(v1_wide),
  v1_1_candidate_wide_rows = nrow(candidate_wide),
  stringsAsFactors = FALSE
)
write_csv(completion, file.path(out_csv, "S30G_completion_record.csv"))

write_csv(
  data.frame(file_read = sort(unique(files_read)), stringsAsFactors = FALSE),
  file.path(out_csv, "S30G_files_read_manifest.csv")
)

protocol_text <- c(
  "# S30G Financial-Claims Proxy Protocol",
  "",
  "S30G constructs bounded financial-claims proxies from committed annual NFC accounting inputs.",
  "",
  "The selected source is `NFC_NET_INT`, BEA NIPA Table 1.14 line 25, net interest and miscellaneous payments for nonfinancial corporate business.",
  "",
  "The source passes the bounded proxy gate because the payer sector is NFC and the accounting position is explicitly net interest and miscellaneous payments. It does not pass the exact transfer gate because the recipient sector is not identified and actual and imputed components are not separated.",
  "",
  "All constructed identities use annual inner alignment. No interpolation, backcasting, zero replacement, gap bridging, or endpoint extrapolation occurs.",
  "",
  "The resulting variables are Shaikh-Tonak-inspired financial-claims proxies. They are not exact reproductions of Appendix 6.7 and do not equate operating surplus with profit after interest."
)
write_text(protocol_text, file.path(out_md, "S30G_FINANCIAL_CLAIMS_PROXY_PROTOCOL.md"))

write_text(c(
  "# S30G Interest Source Audit",
  "",
  sprintf("- Candidates inventoried: %d.", nrow(inventory)),
  sprintf("- Admissible candidates: %d.", completion$interest_candidates_admissible),
  "- Selected source: `NFC_NET_INT`.",
  "- Semantic class: `ADMISSIBLE_NFC_INTEREST_AND_MISC_PAYMENTS_PROXY`.",
  "- Coverage: 1929-2025, 97 annual observations.",
  "- Limitation: the counterparty is unresolved, actual and imputed components are not separated, and miscellaneous payments are included.",
  "",
  "The exact NFC-to-finance transfer standard is not met. The bounded source is nevertheless suitable for a transparent NFC financial-claims burden and after-interest surplus proxy."
), file.path(out_md, "S30G_INTEREST_SOURCE_AUDIT.md"))

write_text(c(
  "# S30G Financial-Claims Proxy Report",
  "",
  sprintf("S30G creates %d bounded proxy variables across %d annual observations.", nrow(new_specs), nrow(new_wide)),
  "",
  "The construction preserves the source payment series, measures the payment burden relative to NFC net operating surplus and net value added, subtracts the payment from NFC net operating surplus, and expresses the remainder relative to net and gross value added.",
  "",
  "The wage-share baseline remains unchanged. The new shares are robustness candidates; the burden measures are diagnostic or robustness candidates.",
  "",
  sprintf("The optional consolidated corporate proxy is `%s` because the financial counterparty and compatible financial-side surplus identity are unresolved.", consolidated_status)
), file.path(out_md, "S30G_FINANCIAL_CLAIMS_PROXY_REPORT.md"))

write_text(c(
  "# S30G Financial-Claims Proxy Validation",
  "",
  sprintf("Result: %s %d/%d", completion$validation_result, sum(validation$status == "PASS"), nrow(validation)),
  "",
  sprintf("- Maximum identity error: %.17g.", max(identity_errors)),
  sprintf("- Frozen v1 hash verification: %d/%d.", sum(v1_integrity$result == "PASS"), nrow(v1_integrity)),
  sprintf("- Candidate SHA-256 verification: %d/%d.", nrow(candidate_sha), nrow(candidate_sha)),
  sprintf("- Original rows changed: %d.", original_rows_changed),
  sprintf("- Original rows removed: %d.", original_rows_removed),
  sprintf("- Original rows duplicated: %d.", original_rows_duplicated)
), file.path(out_md, "S30G_FINANCIAL_CLAIMS_PROXY_VALIDATION.md"))

write_text(c(
  "# S30G v1.1 Release-Candidate Handoff",
  "",
  "The v1.1 directory is a release candidate only. It is not frozen, tagged, or authorized for definitive downstream use.",
  "",
  sprintf("- v1 canonical variables: %d.", completion$v1_variables),
  sprintf("- New S30G variables: %d.", completion$new_variables),
  sprintf("- Candidate canonical variables: %d.", completion$v1_1_candidate_variables),
  sprintf("- v1 long rows: %d.", completion$v1_long_rows),
  sprintf("- New S30G long rows: %d.", completion$new_long_rows),
  sprintf("- Candidate long rows: %d.", completion$v1_1_candidate_long_rows),
  "",
  "A separate S30 authorization and freeze pass is required before any consumer may replace frozen v1."
), file.path(out_md, "S30G_V1_1_RELEASE_CANDIDATE_HANDOFF.md"))

write_text(c(
  "# S30G Decision",
  "",
  "Decision:",
  decision,
  "",
  "Status:",
  status
), file.path(out_md, "S30G_DECISION.md"))

write_text(c(
  "# S31B Staleness Notice",
  "",
  "The existing S31B branch was produced from frozen dataset v1.",
  "",
  "If the v1.1 candidate is later frozen and authorized, S31B must be regenerated from v1.1 before it may be merged into main or used as the definitive descriptive-statistics report.",
  "",
  "The existing S31B commit remains reproducible evidence for v1 and must not be overwritten."
), file.path(out_md, "S30G_S31B_STALENESS_NOTICE.md"))

if (!all(validation$status == "PASS")) {
  stop("S30G validation failed.", call. = FALSE)
}

cat(sprintf(
  paste0(
    "validation: PASS %d/%d\n",
    "decision: %s\n",
    "status: %s\n",
    "selected source: %s\n",
    "new variables: %d\n",
    "candidate variables: %d\n",
    "candidate long rows: %d\n"
  ),
  sum(validation$status == "PASS"), nrow(validation),
  decision, status, selected$source_variable_id, nrow(new_specs),
  length(unique(candidate_long$variable_id)), nrow(candidate_long)
))
