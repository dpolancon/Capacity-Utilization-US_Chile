#!/usr/bin/env Rscript

# S00 imports and validates the locked U.S. BEA provider package.
# It does not construct any Chapter 2 analytical object.

upstream_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"
downstream_repo <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
expected_commit <- "9ca9f79"
expected_tag <- "us-bea-provider-menu-shaikh-blocked-2026-06-09"
validation_only <- "--validation-only" %in% commandArgs(trailingOnly = TRUE)

data_destination <- file.path(
  downstream_repo, "data", "external", "us_bea_provider"
)
docs_destination <- file.path(downstream_repo, "docs", "data_sources")
validation_ledger <- file.path(
  data_destination, "US_BEA_PROVIDER_IMPORT_VALIDATION_LEDGER.csv"
)
validation_report <- file.path(
  docs_destination, "US_BEA_PROVIDER_IMPORT_VALIDATION_REPORT.md"
)

copy_map <- c(
  "data/metadata/us_bea_variable_menu_locked.csv" =
    "data/external/us_bea_provider/us_bea_variable_menu_locked.csv",
  "data/metadata/us_bea_variable_menu_locked.json" =
    "data/external/us_bea_provider/us_bea_variable_menu_locked.json",
  "data/metadata/us_bea_source_provenance_ledger.csv" =
    "data/external/us_bea_provider/us_bea_source_provenance_ledger.csv",
  "data/metadata/us_bea_shaikh_candidate_line_semantic_audit.csv" =
    paste0(
      "data/external/us_bea_provider/",
      "us_bea_shaikh_candidate_line_semantic_audit.csv"
    ),
  "data/staged/us_bea_variable_menu_long.csv" =
    "data/external/us_bea_provider/us_bea_variable_menu_long.csv",
  "docs/US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md" =
    "docs/data_sources/US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md",
  "docs/US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md" =
    "docs/data_sources/US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md",
  "docs/US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md" =
    "docs/data_sources/US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md",
  "docs/US_BEA_SHAIKH_LINE_SEMANTIC_AUDIT.md" =
    "docs/data_sources/US_BEA_SHAIKH_LINE_SEMANTIC_AUDIT.md",
  "docs/US_BEA_SHAIKH_SEMANTIC_PROPAGATION_PATCH.md" =
    "docs/data_sources/US_BEA_SHAIKH_SEMANTIC_PROPAGATION_PATCH.md"
)

run_git <- function(args, allow_failure = FALSE) {
  output <- suppressWarnings(
    system2(
      "git",
      c("-C", upstream_repo, args),
      stdout = TRUE,
      stderr = TRUE
    )
  )
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }
  if (status != 0L && !allow_failure) {
    stop(
      paste0(
        "Git command failed: git -C ", upstream_repo, " ",
        paste(args, collapse = " "), "\n", paste(output, collapse = "\n")
      ),
      call. = FALSE
    )
  }
  list(status = status, output = trimws(paste(output, collapse = "\n")))
}

expected_full_commit <- run_git(
  c("rev-parse", paste0(expected_commit, "^{commit}"))
)$output
observed_head <- run_git(c("rev-parse", "HEAD"))$output
observed_tag_commit <- run_git(
  c("rev-parse", paste0("refs/tags/", expected_tag, "^{commit}"))
)$output
commit_is_ancestor <- run_git(
  c("merge-base", "--is-ancestor", expected_full_commit, observed_head),
  allow_failure = TRUE
)$status == 0L
provider_paths_unchanged <- run_git(
  c("status", "--porcelain", "--", names(copy_map)),
  allow_failure = TRUE
)$output == ""

if (!commit_is_ancestor) {
  stop(
    paste0(
      "Upstream HEAD does not contain expected commit ", expected_commit, "."
    ),
    call. = FALSE
  )
}
if (!identical(observed_tag_commit, expected_full_commit)) {
  stop("The expected upstream tag does not resolve to the expected commit.",
       call. = FALSE)
}
if (!provider_paths_unchanged) {
  stop(
    "Required upstream provider files differ from the checked-out commit.",
    call. = FALSE
  )
}

upstream_files <- file.path(upstream_repo, names(copy_map))
missing_upstream_files <- names(copy_map)[!file.exists(upstream_files)]
if (length(missing_upstream_files) > 0L) {
  stop(
    paste0(
      "Required upstream provider files are missing:\n- ",
      paste(missing_upstream_files, collapse = "\n- ")
    ),
    call. = FALSE
  )
}

dir.create(data_destination, recursive = TRUE, showWarnings = FALSE)
dir.create(docs_destination, recursive = TRUE, showWarnings = FALSE)

downstream_files <- file.path(downstream_repo, unname(copy_map))
if (validation_only) {
  missing_downstream_files <- unname(copy_map)[!file.exists(downstream_files)]
  if (length(missing_downstream_files) > 0L) {
    stop(
      paste0(
        "Validation-only mode requires existing imported files:\n- ",
        paste(missing_downstream_files, collapse = "\n- ")
      ),
      call. = FALSE
    )
  }
} else {
  copy_results <- mapply(
    function(source, destination) {
      file.copy(
        source,
        destination,
        overwrite = TRUE,
        copy.mode = TRUE,
        copy.date = TRUE
      )
    },
    source = upstream_files,
    destination = downstream_files,
    USE.NAMES = FALSE
  )
  if (!all(copy_results)) {
    stop(
      paste0(
        "Failed to copy provider files:\n- ",
        paste(names(copy_map)[!copy_results], collapse = "\n- ")
      ),
      call. = FALSE
    )
  }
}

read_provider_csv <- function(filename) {
  read.csv(
    file.path(data_destination, filename),
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

manifest <- read_provider_csv("us_bea_variable_menu_locked.csv")
provenance <- read_provider_csv("us_bea_source_provenance_ledger.csv")
semantic_audit <- read_provider_csv(
  "us_bea_shaikh_candidate_line_semantic_audit.csv"
)
staged <- read_provider_csv("us_bea_variable_menu_long.csv")

required_columns <- list(
  manifest = c(
    "variable_id", "bea_table", "sector_boundary", "asset_block",
    "stock_flow_type", "role_tag", "required_for_downstream_object"
  ),
  provenance = c("variable_id"),
  semantic_audit = c(
    "candidate_id", "semantic_status", "admissible_for_downstream_formula"
  ),
  staged = c(
    "variable_id", "canonical_name", "bea_table", "sector_boundary",
    "asset_block", "stock_flow_type", "role_tag",
    "required_for_downstream_object"
  )
)
for (object_name in names(required_columns)) {
  missing_columns <- setdiff(
    required_columns[[object_name]],
    names(get(object_name))
  )
  if (length(missing_columns) > 0L) {
    stop(
      paste0(
        object_name, " is missing required columns: ",
        paste(missing_columns, collapse = ", ")
      ),
      call. = FALSE
    )
  }
}

read_imported_doc <- function(filename) {
  paste(
    readLines(
      file.path(docs_destination, filename),
      warn = FALSE,
      encoding = "UTF-8"
    ),
    collapse = "\n"
  )
}

provider_contract <- read_imported_doc(
  "US_BEA_VARIABLE_MENU_PROVIDER_CONTRACT.md"
)
provider_validation <- read_imported_doc(
  "US_BEA_VARIABLE_MENU_VALIDATION_REPORT.md"
)
execution_report <- read_imported_doc(
  "US_BEA_VARIABLE_MENU_EXECUTION_REPORT.md"
)
shaikh_audit_doc <- read_imported_doc(
  "US_BEA_SHAIKH_LINE_SEMANTIC_AUDIT.md"
)
semantic_patch <- read_imported_doc(
  "US_BEA_SHAIKH_SEMANTIC_PROPAGATION_PATCH.md"
)
documentation <- paste(
  provider_contract,
  provider_validation,
  execution_report,
  shaikh_audit_doc,
  semantic_patch,
  sep = "\n"
)

manifest_ids <- unique(manifest$variable_id)
provenance_ids <- unique(provenance$variable_id)
staged_ids <- unique(staged$variable_id)
t711_ids <- c(
  "T711_L4", "T711_L44", "T711_L73", "T711_L28",
  "T711_L52", "T711_L91", "T711_L74", "T711_L53"
)
t711_rows <- staged[staged$variable_id %in% t711_ids, , drop = FALSE]

gov_trans_ids <- c(
  "GOV_TRANS__HIGHWAYS_STREETS__gross_investment_current_cost",
  "GOV_TRANS__TRANSPORTATION_STRUCTURES__gross_investment_current_cost"
)
gov_trans_investment <- manifest[
  manifest$variable_id %in% gov_trans_ids,
  ,
  drop = FALSE
]
gov_trans_rows <- manifest[
  manifest$sector_boundary == "GOV_TRANS",
  ,
  drop = FALSE
]
ipp_rows <- manifest[manifest$asset_block == "IPP", , drop = FALSE]
me_nrc_rows <- manifest[
  manifest$asset_block %in% c("ME", "NRC"),
  ,
  drop = FALSE
]

checks <- data.frame(
  check_id = character(),
  validation_check = character(),
  expected = character(),
  observed = character(),
  result = character(),
  stringsAsFactors = FALSE
)

add_check <- function(check_id, validation_check, expected, observed, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      check_id = check_id,
      validation_check = validation_check,
      expected = as.character(expected),
      observed = as.character(observed),
      result = if (isTRUE(pass)) "PASS" else "FAIL",
      stringsAsFactors = FALSE
    )
  )
}

add_check(
  "git_commit_contained",
  "Upstream HEAD is at or contains the locked commit",
  expected_full_commit,
  observed_head,
  commit_is_ancestor
)
add_check(
  "git_tag_locked",
  "Locked tag resolves to the locked commit",
  expected_full_commit,
  observed_tag_commit,
  identical(observed_tag_commit, expected_full_commit)
)
add_check(
  "provider_paths_locked",
  "Required upstream files match the checked-out commit",
  "no path modifications",
  if (provider_paths_unchanged) "no path modifications" else "modified",
  provider_paths_unchanged
)

upstream_md5 <- unname(tools::md5sum(upstream_files))
downstream_md5 <- unname(tools::md5sum(downstream_files))
add_check(
  "copies_byte_identical",
  "All required provider files copied byte-for-byte",
  length(copy_map),
  sum(upstream_md5 == downstream_md5),
  all(upstream_md5 == downstream_md5)
)
add_check(
  "manifest_rows", "Manifest rows", 175L, nrow(manifest),
  nrow(manifest) == 175L
)
add_check(
  "provenance_rows", "Provenance ledger rows", 175L, nrow(provenance),
  nrow(provenance) == 175L
)
add_check(
  "staged_rows", "Staged long rows", 9438L, nrow(staged),
  nrow(staged) == 9438L
)
add_check(
  "staged_distinct_ids",
  "Distinct staged variable_id values",
  94L,
  length(staged_ids),
  length(staged_ids) == 94L
)
add_check(
  "manifest_id_unique",
  "Manifest variable_id values are unique",
  nrow(manifest),
  length(manifest_ids),
  length(manifest_ids) == nrow(manifest)
)
add_check(
  "provenance_id_unique",
  "Provenance variable_id values are unique",
  nrow(provenance),
  length(provenance_ids),
  length(provenance_ids) == nrow(provenance)
)
add_check(
  "manifest_provenance_identity",
  "Manifest and provenance variable_id sets are identical",
  "identical sets",
  paste0(length(setdiff(manifest_ids, provenance_ids)) +
           length(setdiff(provenance_ids, manifest_ids)), " differences"),
  setequal(manifest_ids, provenance_ids)
)
add_check(
  "staged_ids_manifest",
  "All staged variable_id values exist in manifest",
  "0 missing",
  paste0(length(setdiff(staged_ids, manifest_ids)), " missing"),
  length(setdiff(staged_ids, manifest_ids)) == 0L
)
add_check(
  "staged_ids_provenance",
  "All staged variable_id values exist in provenance ledger",
  "0 missing",
  paste0(length(setdiff(staged_ids, provenance_ids)), " missing"),
  length(setdiff(staged_ids, provenance_ids)) == 0L
)
add_check(
  "t711_ids_present",
  "All eight T711 candidate lines are staged",
  paste(t711_ids, collapse = "; "),
  paste(sort(unique(t711_rows$variable_id)), collapse = "; "),
  setequal(unique(t711_rows$variable_id), t711_ids)
)
add_check(
  "t711_rows",
  "T711 staged rows",
  592L,
  nrow(t711_rows),
  nrow(t711_rows) == 592L
)
add_check(
  "t711_role_tag",
  "Every staged T711 row has the candidate-line role tag",
  "shaikh_candidate_line_ingredient",
  paste(sort(unique(t711_rows$role_tag)), collapse = "; "),
  nrow(t711_rows) > 0L &&
    all(t711_rows$role_tag == "shaikh_candidate_line_ingredient")
)
add_check(
  "t711_required_object",
  "Every staged T711 row is restricted to semantic audit",
  "shaikh_candidate_semantic_audit_only",
  paste(
    sort(unique(t711_rows$required_for_downstream_object)),
    collapse = "; "
  ),
  nrow(t711_rows) > 0L &&
    all(
      t711_rows$required_for_downstream_object ==
        "shaikh_candidate_semantic_audit_only"
    )
)

forbidden_t711_values <- c(
  "shaikh_imputed_interest_ingredient",
  "BankMonIntPaid",
  "CorpNFNetImpIntPaid"
)
t711_exact_values <- unique(unlist(t711_rows, use.names = FALSE))
t711_forbidden_found <- intersect(forbidden_t711_values, t711_exact_values)
add_check(
  "t711_forbidden_values",
  "No staged T711 field equals a prohibited role or constructed object",
  "none",
  if (length(t711_forbidden_found) == 0L) {
    "none"
  } else {
    paste(t711_forbidden_found, collapse = "; ")
  },
  length(t711_forbidden_found) == 0L
)

audit_ids <- unique(semantic_audit$candidate_id)
blocked_in_docs <- grepl(
  "shaikh formula semantic admissibility:[[:space:]`*]*blocked",
  documentation,
  ignore.case = TRUE,
  perl = TRUE
) && grepl(
  "construction.*blocked pending a legacy-to-current semantic crosswalk",
  shaikh_audit_doc,
  ignore.case = TRUE
)
add_check(
  "shaikh_audit_identity",
  "Semantic audit contains exactly the eight T711 candidates",
  paste(t711_ids, collapse = "; "),
  paste(sort(audit_ids), collapse = "; "),
  nrow(semantic_audit) == 8L && setequal(audit_ids, t711_ids)
)
add_check(
  "shaikh_blocked",
  "Shaikh semantic admissibility is BLOCKED",
  "BLOCKED pending historical/current semantic crosswalk",
  if (blocked_in_docs) "BLOCKED" else "not documented as BLOCKED",
  blocked_in_docs
)
add_check(
  "wage_share_preferred",
  "wage share documented as preferred distributive state",
  "preferred distributive state",
  if (grepl(
    "wage share.*preferred.*distributive state",
    documentation,
    ignore.case = TRUE
  )) "documented" else "not documented",
  grepl(
    "wage share.*preferred.*distributive state",
    documentation,
    ignore.case = TRUE
  )
)
add_check(
  "exploitation_alternative",
  "exploitation rate documented as alternative proxy",
  "alternative proxy",
  if (grepl(
    "exploitation rate.*alternative proxy",
    documentation,
    ignore.case = TRUE
  )) "documented" else "not documented",
  grepl(
    "exploitation rate.*alternative proxy",
    documentation,
    ignore.case = TRUE
  )
)

gov_trans_mapping_ok <- (
  nrow(gov_trans_investment) == 2L &&
    setequal(gov_trans_investment$variable_id, gov_trans_ids) &&
    all(gov_trans_investment$bea_table == "FAAt705") &&
    all(gov_trans_investment$stock_flow_type == "gross_investment")
)
add_check(
  "gov_trans_faat705",
  "Required GOV_TRANS gross-investment variables map to FAAt705",
  paste(gov_trans_ids, collapse = "; "),
  paste(
    paste0(
      gov_trans_investment$variable_id,
      " -> ",
      gov_trans_investment$bea_table
    ),
    collapse = "; "
  ),
  gov_trans_mapping_ok
)
add_check(
  "gov_trans_conditioner",
  "GOV_TRANS remains a frontier conditioner",
  "frontier_conditioner",
  paste(sort(unique(gov_trans_rows$role_tag)), collapse = "; "),
  nrow(gov_trans_rows) > 0L &&
    all(gov_trans_rows$role_tag == "frontier_conditioner")
)
add_check(
  "ipp_conditioner",
  "IPP remains a frontier conditioner",
  "frontier_conditioner",
  paste(sort(unique(ipp_rows$role_tag)), collapse = "; "),
  nrow(ipp_rows) > 0L && all(ipp_rows$role_tag == "frontier_conditioner")
)
add_check(
  "me_nrc_direct",
  "ME and NRC remain direct productive-capacity capital",
  "direct_productive_capacity_capital",
  paste(sort(unique(me_nrc_rows$role_tag)), collapse = "; "),
  nrow(me_nrc_rows) > 0L &&
    all(me_nrc_rows$role_tag == "direct_productive_capacity_capital") &&
    setequal(unique(me_nrc_rows$asset_block), c("ME", "NRC"))
)

analytical_patterns <- c(
  "S10", "S20", "S30", "GPIM", "BankMonIntPaid",
  "CorpNFNetImpIntPaid", "CorpImpIntAdj", "wage_share",
  "profit_share", "exploitation", "interaction", "capacity", "utilization"
)
generated_paths <- c(unname(copy_map), basename(validation_ledger),
                     basename(validation_report))
analytical_outputs <- generated_paths[
  Reduce(
    `|`,
    lapply(
      analytical_patterns,
      function(pattern) grepl(pattern, generated_paths, ignore.case = TRUE)
    )
  )
]
add_check(
  "no_analytical_objects",
  "No downstream analytical object is constructed in S00",
  "none",
  if (length(analytical_outputs) == 0L) {
    "provider artifacts and validation outputs only"
  } else {
    paste(analytical_outputs, collapse = "; ")
  },
  length(analytical_outputs) == 0L
)

write.csv(checks, validation_ledger, row.names = FALSE, na = "")

escape_markdown <- function(x) {
  gsub("|", "\\|", x, fixed = TRUE)
}
check_table <- c(
  "| Validation check | Expected | Observed | Result |",
  "|---|---|---|:---:|",
  apply(
    checks,
    1L,
    function(row) {
      paste0(
        "| ", escape_markdown(row[["validation_check"]]),
        " | ", escape_markdown(row[["expected"]]),
        " | ", escape_markdown(row[["observed"]]),
        " | ", row[["result"]], " |"
      )
    }
  )
)

copied_file_lines <- paste0(
  "- `", names(copy_map), "` -> `", unname(copy_map), "`"
)
failed_checks <- checks$validation_check[checks$result == "FAIL"]
overall_result <- if (length(failed_checks) == 0L) "PASS" else "FAIL"

report_lines <- c(
  "# U.S. BEA Provider Import Validation Report",
  "",
  "## Import identity",
  "",
  paste0("- Upstream repo: `", upstream_repo, "`"),
  paste0("- Locked upstream commit: `", expected_full_commit, "`"),
  paste0("- Locked upstream tag: `", expected_tag, "`"),
  paste0("- Observed upstream HEAD: `", observed_head, "`"),
  paste0("- Downstream repo: `", downstream_repo, "`"),
  "- Import layer: `S00` provider artifact import and validation only",
  "",
  "## Imported files",
  "",
  copied_file_lines,
  "",
  "## Validation",
  "",
  check_table,
  "",
  paste0("**Overall result: ", overall_result, ".**"),
  "",
  "## T711 blocked status",
  "",
  paste(
    "All eight T711 candidate lines are imported as",
    "`shaikh_candidate_line_ingredient` rows restricted to",
    "`shaikh_candidate_semantic_audit_only`."
  ),
  paste(
    "Shaikh-adjusted construction remains **BLOCKED** pending a documented",
    "historical/current semantic crosswalk."
  ),
  "",
  "## Scope boundary",
  "",
  paste(
    "This S00 pass imports provider artifacts only and does not construct",
    "analytical Chapter 2 variables."
  ),
  paste(
    "S00 validates only provider-artifact import and the distributive-state",
    "hierarchy. It does not define, validate, or construct downstream",
    "interaction variables. The econometric operationalization of",
    "distribution-conditioned accumulation is governed by the Chapter 2",
    "vault/econometric implementation notes and must not be inferred from",
    "provider metadata."
  ),
  paste(
    "It constructs no GPIM stocks, Shaikh-adjusted income variables,",
    "distributive variables, interactions, capacity or utilization variables,",
    "S10/S20/S30 datasets, or econometric outputs."
  ),
  "",
  "The machine-readable validation ledger is:",
  "",
  paste0("- `", sub(
    paste0("^", downstream_repo, "/?"),
    "",
    gsub("\\\\", "/", validation_ledger)
  ), "`")
)
writeLines(report_lines, validation_report, useBytes = TRUE)

if (overall_result == "FAIL") {
  stop(
    paste0(
      "S00 provider import validation failed. See ", validation_report,
      "\nFailed checks:\n- ", paste(failed_checks, collapse = "\n- ")
    ),
    call. = FALSE
  )
}

message("S00 provider import validation passed.")
message(
  if (validation_only) {
    "Validation outputs regenerated without copying provider files."
  } else {
    paste0("Copied provider files: ", length(copy_map))
  }
)
message("Validation ledger: ", validation_ledger)
message("Validation report: ", validation_report)
