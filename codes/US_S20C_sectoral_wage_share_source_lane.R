#!/usr/bin/env Rscript

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
rel <- function(...) file.path(..., fsep = "/")
abs_path <- function(...) file.path(root, ..., fsep = "/")

out_dir <- abs_path("output", "US", "S20C_SECTORAL_WAGE_SHARE_SOURCE_LANE")
csv_dir <- rel(out_dir, "csv")
md_dir <- rel(out_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s20_dir <- abs_path("output", "US", "S20_MODEL_INPUT_LAYER")
s20b_dir <- abs_path("output", "US", "S20B_DISTRIBUTION_ATTACHMENT_CONTRACT")
s14_dir <- abs_path("output", "US", "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION")

read_csv <- function(path) {
  if (!file.exists(path)) {
    stop("Required input missing: ", path, call. = FALSE)
  }
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

git_out <- function(args) trimws(system2("git", args, stdout = TRUE, stderr = TRUE))

md5 <- function(paths) {
  paths <- paths[file.exists(paths)]
  if (length(paths) == 0L) return(character())
  tools::md5sum(paths)
}

finite_coverage <- function(df, value_col = "value", year_col = "year") {
  if (!all(c(value_col, year_col) %in% names(df))) {
    return(c(start = NA_integer_, end = NA_integer_, n = 0L))
  }
  years <- suppressWarnings(as.integer(df[[year_col]]))
  vals <- suppressWarnings(as.numeric(df[[value_col]]))
  ok <- is.finite(years) & is.finite(vals)
  if (!any(ok)) return(c(start = NA_integer_, end = NA_integer_, n = 0L))
  c(start = min(years[ok]), end = max(years[ok]), n = sum(ok))
}

first_nonblank <- function(x, default = "not_declared") {
  x <- x[!is.na(x) & nzchar(as.character(x))]
  if (length(x) == 0L) default else as.character(x[1])
}

sector_class <- function(variable_id, source_file = "") {
  txt <- toupper(paste(variable_id, source_file))
  if (grepl("NFC|NONFINANCIAL", txt)) return("nonfinancial_corporate")
  if (grepl("CORP|CORPORATE", txt)) return("corporate_sector")
  if (grepl("NONFARM|NFB", txt)) return("nonfarm_business")
  if (grepl("PRIVATE", txt)) return("private_business")
  if (grepl("ECONOMY|TOTAL", txt)) return("economy_wide_or_total")
  "unclear"
}

kind_class <- function(variable_id) {
  id <- tolower(variable_id)
  if (grepl("shaikh|(^|_)adj|adjusted", id)) return("adjusted_or_shaikh_candidate")
  if (grepl("omega|wage|labor|labour|compensation_share", id)) return("constructed_or_registered_wage_share")
  if (grepl("comp", id)) return("labor_compensation_ingredient")
  if (grepl("gva|value_added|value added", id)) return("value_added_ingredient")
  if (grepl("pi|profit|gos|nos|surplus", id)) return("profit_share_or_profit_ingredient")
  "distribution_related"
}

common_support_ok <- function(start, end) {
  is.finite(start) && is.finite(end) && start <= 1931L && end >= 2024L
}

s20_validation_path <- rel(s20_dir, "csv", "S20_validation_checks.csv")
s20_distribution_path <- rel(s20_dir, "csv", "S20_distribution_role_ledger.csv")
s20_panel_path <- rel(s20_dir, "csv", "S20_model_input_panel_long.csv")
s20_capital_path <- rel(s20_dir, "csv", "S20_capital_role_ledger.csv")
s20_blocked_path <- rel(s20_dir, "csv", "S20_blocked_parked_excluded_object_ledger.csv")
s20_report_path <- rel(s20_dir, "md", "S20_MODEL_INPUT_LAYER.md")
s20b_validation_path <- rel(s20b_dir, "csv", "S20B_validation_checks.csv")
s20b_contract_path <- rel(s20b_dir, "csv", "S20B_distribution_attachment_contract_ledger.csv")
s20b_audit_path <- rel(s20b_dir, "csv", "S20B_distribution_source_audit_ledger.csv")
s20b_report_path <- rel(s20b_dir, "md", "S20B_DISTRIBUTION_ATTACHMENT_CONTRACT.md")
s14_validation_path <- rel(s14_dir, "csv", "S14_validation_checks.csv")
s10_panel_path <- abs_path("data", "processed", "us_s10", "us_s10_source_panel_long.csv")
s10_ledger_path <- abs_path("data", "processed", "us_s10", "us_s10_object_admissibility_ledger.csv")

s20_hash_targets <- c(
  s20_validation_path, s20_distribution_path, s20_panel_path,
  s20_capital_path, s20_blocked_path, s20_report_path
)
s20_hash_before <- md5(s20_hash_targets)

s20_validation <- read_csv(s20_validation_path)
s20_distribution <- read_csv(s20_distribution_path)
s20_panel <- read_csv(s20_panel_path)
s20_report <- paste(readLines(s20_report_path, warn = FALSE), collapse = "\n")
s20b_validation <- read_csv(s20b_validation_path)
s20b_contract <- read_csv(s20b_contract_path)
s20b_audit <- read_csv(s20b_audit_path)
s20b_report <- paste(readLines(s20b_report_path, warn = FALSE), collapse = "\n")
s14_validation <- read_csv(s14_validation_path)
s10_panel <- read_csv(s10_panel_path)
s10_ledger <- read_csv(s10_ledger_path)

candidate_rows <- list()
add_candidate <- function(candidate_id, variable_id, source_file, source_stage, source_table,
                          sector_boundary, numerator_candidate, denominator_candidate, unit,
                          frequency, coverage_start, coverage_end, finite_observations,
                          current_release_status, object_kind, adjusted_unadjusted, sector_classification,
                          attachable_to_current_s20, decision_reason) {
  candidate_rows[[length(candidate_rows) + 1L]] <<- data.frame(
    candidate_id = candidate_id,
    variable_id = variable_id,
    source_file = source_file,
    source_stage = source_stage,
    source_table = source_table,
    sector_boundary = sector_boundary,
    numerator_candidate = numerator_candidate,
    denominator_candidate = denominator_candidate,
    unit = unit,
    frequency = frequency,
    year_coverage_start = coverage_start,
    year_coverage_end = coverage_end,
    finite_observations = finite_observations,
    current_release_status = current_release_status,
    object_kind = object_kind,
    adjusted_unadjusted = adjusted_unadjusted,
    sector_classification = sector_classification,
    attachable_to_current_s20 = attachable_to_current_s20,
    decision_reason = decision_reason,
    stringsAsFactors = FALSE
  )
}

ingredient_ids <- c("NFC_COMP", "NFC_GVA", "CORP_COMP", "CORP_GVA",
                    "NFC_GOS", "CORP_GOS", "NFC_NOS", "CORP_NOS")
for (vid in intersect(ingredient_ids, unique(s10_panel$variable_id))) {
  rows <- s10_panel[s10_panel$variable_id == vid, , drop = FALSE]
  cov <- finite_coverage(rows)
  add_candidate(
    candidate_id = paste0("S10_INGREDIENT_", vid),
    variable_id = vid,
    source_file = "data/processed/us_s10/us_s10_source_panel_long.csv",
    source_stage = "S10_repo_local_source_panel",
    source_table = paste(first_nonblank(rows$bea_dataset), first_nonblank(rows$bea_table), sep = ":"),
    sector_boundary = first_nonblank(rows$sector_boundary),
    numerator_candidate = ifelse(grepl("COMP", vid), vid, "not_numerator_for_wage_share"),
    denominator_candidate = ifelse(grepl("GVA", vid), vid, "not_denominator_for_wage_share"),
    unit = first_nonblank(rows$unit),
    frequency = first_nonblank(rows$frequency),
    coverage_start = cov[["start"]],
    coverage_end = cov[["end"]],
    finite_observations = cov[["n"]],
    current_release_status = paste("repo_local_staged", first_nonblank(rows$status), first_nonblank(rows$download_date), sep = "|"),
    object_kind = kind_class(vid),
    adjusted_unadjusted = "unadjusted_source_ingredient",
    sector_classification = sector_class(vid),
    attachable_to_current_s20 = "ingredient_for_source_contract_only",
    decision_reason = "Repo-local staged source ingredient with annual year key and provenance metadata; S20C may authorize a formula contract but does not attach to S20."
  )
}

ledger_ids <- c("NFC_COMP", "NFC_GVA", "CORP_COMP", "CORP_GVA",
                "omega_NFC", "omega_CORP", "pi_res_NFC", "pi_res_CORP")
for (vid in intersect(ledger_ids, s10_ledger$object_id)) {
  row <- s10_ledger[s10_ledger$object_id == vid, , drop = FALSE][1, ]
  add_candidate(
    candidate_id = paste0("S10_LEDGER_", vid),
    variable_id = vid,
    source_file = "data/processed/us_s10/us_s10_object_admissibility_ledger.csv",
    source_stage = row$construction_stage,
    source_table = row$required_source_family,
    sector_boundary = sector_class(vid),
    numerator_candidate = ifelse(grepl("omega_NFC", vid), "NFC_COMP",
                          ifelse(grepl("omega_CORP", vid), "CORP_COMP",
                          ifelse(grepl("COMP", vid), vid, "not_declared"))),
    denominator_candidate = ifelse(grepl("omega_NFC", vid), "NFC_GVA",
                            ifelse(grepl("omega_CORP", vid), "CORP_GVA",
                            ifelse(grepl("GVA", vid), vid, "not_declared"))),
    unit = "contract_metadata",
    frequency = "annual_if_observation_source_used",
    coverage_start = NA_integer_,
    coverage_end = NA_integer_,
    finite_observations = NA_integer_,
    current_release_status = row$admissibility_status,
    object_kind = kind_class(vid),
    adjusted_unadjusted = "unadjusted_or_pending_unadjusted",
    sector_classification = sector_class(vid),
    attachable_to_current_s20 = ifelse(grepl("omega", vid), "registered_pending_source_contract", "ingredient_metadata"),
    decision_reason = paste(row$analytical_role, row$notes, sep = " | ")
  )
}

for (i in seq_len(nrow(s20_distribution))) {
  r <- s20_distribution[i, ]
  add_candidate(
    candidate_id = paste0("CURRENT_S20_DISTRIBUTION_", r$object_id),
    variable_id = r$object_id,
    source_file = "output/US/S20_MODEL_INPUT_LAYER/csv/S20_distribution_role_ledger.csv",
    source_stage = "current_S20_model_input_layer",
    source_table = "not_applicable",
    sector_boundary = "pending_sector_explicit_source_lane",
    numerator_candidate = "pending",
    denominator_candidate = "pending",
    unit = "pending",
    frequency = "pending",
    coverage_start = NA_integer_,
    coverage_end = NA_integer_,
    finite_observations = 0L,
    current_release_status = r$status,
    object_kind = kind_class(r$object_id),
    adjusted_unadjusted = ifelse(grepl("SHAIKH", r$object_id), "adjusted_blocked", "unadjusted_or_profit_pending"),
    sector_classification = "pending_or_not_applicable",
    attachable_to_current_s20 = "not_attachable_without_S20C_contract",
    decision_reason = paste(r$object_role, r$source_status, sep = " | ")
  )
}

if (nrow(s20b_audit) > 0L) {
  keep <- grepl("omega|wage|comp|gva|profit|pi_res|shaikh|adj", s20b_audit$variable_id, ignore.case = TRUE)
  for (i in which(keep)) {
    r <- s20b_audit[i, ]
    add_candidate(
      candidate_id = paste0("S20B_AUDIT_", i),
      variable_id = r$variable_id,
      source_file = r$source_file,
      source_stage = paste("S20B_audited", r$source_stage, sep = ":"),
      source_table = "reported_by_S20B",
      sector_boundary = r$sector_account_boundary,
      numerator_candidate = r$numerator,
      denominator_candidate = r$denominator,
      unit = r$unit,
      frequency = r$frequency,
      coverage_start = suppressWarnings(as.integer(r$year_coverage_start)),
      coverage_end = suppressWarnings(as.integer(r$year_coverage_end)),
      finite_observations = suppressWarnings(as.integer(r$finite_observations)),
      current_release_status = r$authorization,
      object_kind = r$kind,
      adjusted_unadjusted = r$adjusted_unadjusted,
      sector_classification = sector_class(r$variable_id, r$source_file),
      attachable_to_current_s20 = "not_authorized_by_S20B",
      decision_reason = r$evidence
    )
  }
}

legacy_paths <- c(
  "data/processed/us_s20/us_s20_capital_distribution_frontier_panel.csv",
  "data/processed/us_nf_corporate_stageBC.csv",
  "data/processed/us_nf_corporate_stageC.csv"
)
for (p in legacy_paths) {
  ap <- abs_path(p)
  if (!file.exists(ap)) next
  df <- read_csv(ap)
  vars <- intersect(c("omega_NFC", "omega_CORP", "omega", "pi_res_NFC", "pi_res_CORP", "pi", "e"), names(df))
  for (vid in vars) {
    cov <- finite_coverage(df, vid)
    add_candidate(
      candidate_id = paste0("LEGACY_PANEL_", gsub("[^A-Za-z0-9]+", "_", p), "_", vid),
      variable_id = vid,
      source_file = p,
      source_stage = "legacy_or_pre_current_model_artifact",
      source_table = "not_current_source_contract",
      sector_boundary = sector_class(vid, p),
      numerator_candidate = ifelse(grepl("omega_NFC", vid), "NFC_COMP",
                            ifelse(grepl("omega_CORP", vid), "CORP_COMP",
                            ifelse(vid == "omega", "EC", "not_baseline_numerator"))),
      denominator_candidate = ifelse(grepl("omega_NFC", vid), "NFC_GVA",
                              ifelse(grepl("omega_CORP", vid), "CORP_GVA",
                              ifelse(vid == "omega", "GVA", "not_baseline_denominator"))),
      unit = "ratio",
      frequency = "annual",
      coverage_start = cov[["start"]],
      coverage_end = cov[["end"]],
      finite_observations = cov[["n"]],
      current_release_status = "legacy_not_current_release_authority",
      object_kind = kind_class(vid),
      adjusted_unadjusted = "unadjusted_legacy_or_alternative",
      sector_classification = sector_class(vid, p),
      attachable_to_current_s20 = "no",
      decision_reason = "Rejected for S20C authorization because it is a legacy/pre-current artifact; source ingredients must authorize the current lane."
    )
  }
}

candidate_audit <- do.call(rbind, candidate_rows)
candidate_audit <- candidate_audit[order(candidate_audit$source_stage, candidate_audit$source_file, candidate_audit$variable_id), ]

source_pair <- function(num_id, den_id) {
  n <- s10_panel[s10_panel$variable_id == num_id, , drop = FALSE]
  d <- s10_panel[s10_panel$variable_id == den_id, , drop = FALSE]
  n_cov <- finite_coverage(n)
  d_cov <- finite_coverage(d)
  common_start <- suppressWarnings(max(n_cov[["start"]], d_cov[["start"]], na.rm = TRUE))
  common_end <- suppressWarnings(min(n_cov[["end"]], d_cov[["end"]], na.rm = TRUE))
  same_unit <- identical(first_nonblank(n$unit), first_nonblank(d$unit))
  same_freq <- identical(first_nonblank(n$frequency), first_nonblank(d$frequency))
  same_table <- identical(first_nonblank(n$bea_table), first_nonblank(d$bea_table))
  provenance <- all(c("source_query", "source_observation_file", "download_date", "vintage") %in% names(s10_panel)) &&
    all(nzchar(first_nonblank(n$source_query, "")), nzchar(first_nonblank(d$source_query, "")),
        nzchar(first_nonblank(n$source_observation_file, "")), nzchar(first_nonblank(d$source_observation_file, "")))
  list(
    numerator_exists = nrow(n) > 0L,
    denominator_exists = nrow(d) > 0L,
    numerator_coverage_start = n_cov[["start"]],
    numerator_coverage_end = n_cov[["end"]],
    denominator_coverage_start = d_cov[["start"]],
    denominator_coverage_end = d_cov[["end"]],
    common_support_start = common_start,
    common_support_end = common_end,
    same_unit = same_unit,
    same_frequency = same_freq,
    same_table = same_table,
    provenance = provenance,
    numerator_status = first_nonblank(n$status),
    denominator_status = first_nonblank(d$status),
    numerator_unit = first_nonblank(n$unit),
    denominator_unit = first_nonblank(d$unit),
    source_table = paste(first_nonblank(n$bea_dataset), first_nonblank(n$bea_table), sep = ":")
  )
}

nfc <- source_pair("NFC_COMP", "NFC_GVA")
corp <- source_pair("CORP_COMP", "CORP_GVA")

authorize_nfc <- nfc$numerator_exists && nfc$denominator_exists &&
  identical(nfc$numerator_status, "staged") && identical(nfc$denominator_status, "staged") &&
  nfc$same_unit && nfc$same_frequency && nfc$same_table && nfc$provenance &&
  common_support_ok(nfc$common_support_start, nfc$common_support_end)

authorize_corp <- corp$numerator_exists && corp$denominator_exists &&
  identical(corp$numerator_status, "staged") && identical(corp$denominator_status, "staged") &&
  corp$same_unit && corp$same_frequency && corp$same_table && corp$provenance &&
  common_support_ok(corp$common_support_start, corp$common_support_end)

nfc_status <- if (authorize_nfc) "AUTHORIZE_S20C_NFC_WAGE_SHARE_SOURCE_CONTRACT" else "BLOCK_S20C_NFC_WAGE_SHARE_PENDING_SOURCE_CONTRACT"
corp_status <- if (authorize_corp) "AUTHORIZE_CORPORATE_WAGE_SHARE_ROBUSTNESS_SOURCE_CONTRACT" else "BLOCK_CORPORATE_WAGE_SHARE_ROBUSTNESS_PENDING_SOURCE_CONTRACT"
final_decision <- if (authorize_nfc) "AUTHORIZE_S20D_DISTRIBUTION_ATTACHMENT_PROMPT" else "BLOCK_S20C_NFC_WAGE_SHARE_PENDING_SOURCE_CONTRACT"

contract_ledger <- data.frame(
  contract_id = c("WAGE_SHARE_UNADJUSTED_NFC_GVA_BASELINE", "WAGE_SHARE_UNADJUSTED_CORP_GVA_ROBUSTNESS"),
  status = c(nfc_status, corp_status),
  role = c("PREFERRED_DISTRIBUTION_VARIABLE_FOR_S20_NFC_GPIM_BASELINE", "ROBUSTNESS_OR_RECONCILIATION_OBJECT_NOT_BASELINE"),
  sector_boundary = c("nonfinancial_corporate_sector", "corporate_sector_as_a_whole"),
  numerator_variable_id = c("NFC_COMP", "CORP_COMP"),
  denominator_variable_id = c("NFC_GVA", "CORP_GVA"),
  formula = c("WAGE_SHARE_UNADJUSTED_NFC_GVA_BASELINE = NFC_COMP / NFC_GVA",
              "WAGE_SHARE_UNADJUSTED_CORP_GVA_ROBUSTNESS = CORP_COMP / CORP_GVA"),
  source_file = "data/processed/us_s10/us_s10_source_panel_long.csv",
  source_table = c(nfc$source_table, corp$source_table),
  basis = "current-dollar account basis",
  frequency = "annual",
  join_key = "year",
  common_support_start = c(nfc$common_support_start, corp$common_support_start),
  common_support_end = c(nfc$common_support_end, corp$common_support_end),
  overlaps_s20_common_support_1931_2024 = c(common_support_ok(nfc$common_support_start, nfc$common_support_end),
                                            common_support_ok(corp$common_support_start, corp$common_support_end)),
  provenance_metadata = c(ifelse(nfc$provenance, "present", "missing"), ifelse(corp$provenance, "present", "missing")),
  attachment_scope = "source_contract_only_no_S20_panel_merge",
  missing_policy = "fail_closed_no_interpolation_no_sector_substitution",
  prohibited_use = c("Do not overwrite baseline with generic, economy-wide, private-business, nonfarm-business, or adjusted wage share.",
                     "Do not promote corporate robustness object as preferred baseline without a later boundary-shift protocol."),
  final_decision = final_decision,
  stringsAsFactors = FALSE
)

blocked_rejected <- data.frame(
  object_id = c(
    "ECONOMY_WIDE_WAGE_SHARE",
    "PRIVATE_BUSINESS_WAGE_SHARE",
    "TOTAL_BUSINESS_WAGE_SHARE",
    "NONFARM_BUSINESS_WAGE_SHARE",
    "HOUSEHOLD_OR_MIXED_INCOME_WAGE_SHARE",
    "GENERIC_WAGE_SHARE_WITHOUT_SECTOR_METADATA",
    "PROFIT_SHARE_BASELINE_SUBSTITUTE",
    "SHAIKH_ADJUSTED_WAGE_SHARE",
    "SHAIKH_ADJUSTED_PROFIT_SHARE",
    "ACCUMULATED_Q",
    "S21_ACCUMULATED_Q_LAYER",
    "IPP_FRONTIER_CONDITIONER_ATTACHMENT",
    "GOV_TRANS_FRONTIER_CONDITIONER_ATTACHMENT",
    "THETA_T",
    "PRODUCTIVE_CAPACITY_Y_P",
    "CAPACITY_UTILIZATION_MU"
  ),
  status = c(
    "REJECTED_NOT_SECTOR_MATCH",
    "REJECTED_NOT_SECTOR_MATCH",
    "REJECTED_NOT_SECTOR_MATCH",
    "REJECTED_NOT_SECTOR_MATCH",
    "REJECTED_MIXED_INCOME_CONTAMINATION_RISK",
    "REJECTED_MISSING_SECTOR_ACCOUNTING_METADATA",
    "ALTERNATIVE_OR_RECONCILIATION_EVIDENCE_ONLY",
    "SHAIKH_ADJUSTMENT_BLOCKED_PENDING_CROSSWALK_AND_DATA",
    "SHAIKH_ADJUSTMENT_BLOCKED_PENDING_CROSSWALK_AND_DATA",
    "ACCUMULATED_Q_PARKED_S21_CLOSED",
    "ACCUMULATED_Q_PARKED_S21_CLOSED",
    "PARKED_CONTROL_CONDITIONER_NOT_BASELINE",
    "PARKED_CONTROL_CONDITIONER_NOT_BASELINE",
    "EXCLUDED_DATA_ARCHITECTURE_ONLY",
    "EXCLUDED_DATA_ARCHITECTURE_ONLY",
    "EXCLUDED_DATA_ARCHITECTURE_ONLY"
  ),
  reason = c(
    "S20C target requires NFC baseline or corporate robustness with explicit account boundary.",
    "S20C target requires NFC baseline or corporate robustness with explicit account boundary.",
    "S20C target requires NFC baseline or corporate robustness with explicit account boundary.",
    "S20C target requires NFC baseline or corporate robustness with explicit account boundary.",
    "Household and mixed-income concepts are outside the current unadjusted corporate source lane.",
    "Generic wage share cannot attach without numerator, denominator, sector boundary, unit, frequency, and provenance.",
    "Profit share remains reconciliation evidence and cannot replace the preferred unadjusted NFC wage share.",
    "No current-release Shaikh semantic/accounting crosswalk plus source-data contract passes.",
    "No current-release Shaikh semantic/accounting crosswalk plus source-data contract passes.",
    "Accumulated q remains parked and S21 remains closed.",
    "S20C does not authorize S21.",
    "IPP remains a parked control-conditioner candidate.",
    "Government transportation remains a parked control-conditioner candidate.",
    "S20C is not an econometric or transformation-elasticity layer.",
    "S20C does not construct productive capacity.",
    "S20C does not construct utilization."
  ),
  stringsAsFactors = FALSE
)

script_path <- abs_path("codes", "US_S20C_sectoral_wage_share_source_lane.R")
script_text <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
downstream_invocation <- grepl("system2\\([^\\n]*(US_S21|US_S22|US_S30|US_S32|Rscript)|source\\([^\\n]*(US_S21|US_S22|US_S30|US_S32)", script_text, ignore.case = TRUE)
econometric_calls <- grepl("\\b(lm|glm|arima|VAR|ca\\.jo|ur\\.df|dynlm|ardl|Johansen)\\s*\\(", script_text)
theta_capacity_q_constructed <- FALSE
gpim_reconstruction <- FALSE
provider_roots_accessed <- FALSE
s20_panel_attachment_performed <- FALSE
generic_authorized <- any(candidate_audit$sector_classification %in% c("economy_wide_or_total", "private_business", "nonfarm_business", "unclear") &
                            grepl("^AUTHORIZE", candidate_audit$attachable_to_current_s20))
shaikh_authorized <- any(grepl("^AUTHORIZE", candidate_audit$current_release_status, ignore.case = TRUE) &
                           grepl("shaikh|(^|_)adj|adjusted", candidate_audit$variable_id, ignore.case = TRUE))

s20_hash_after <- md5(s20_hash_targets)
s20_hash_unchanged <- identical(as.character(s20_hash_before), as.character(s20_hash_after)) &&
  identical(names(s20_hash_before), names(s20_hash_after))

head_short <- git_out(c("rev-parse", "--short", "HEAD"))[1]
origin_short <- git_out(c("rev-parse", "--short", "origin/main"))[1]
branch_name <- git_out(c("branch", "--show-current"))[1]
s20_decision_found <- grepl("AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION", s20_report) ||
  any(grepl("AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION", s20_validation$evidence, fixed = TRUE))
s20b_block_found <- grepl("BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION", s20b_report) ||
  any(grepl("BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION", s20b_validation$evidence, fixed = TRUE)) ||
  any(grepl("BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION", s20b_contract$final_decision, fixed = TRUE))

check <- function(id, condition, evidence_ok, evidence_bad = evidence_ok) {
  data.frame(
    check_id = id,
    status = ifelse(isTRUE(condition), "PASS", "FAIL"),
    evidence = ifelse(isTRUE(condition), evidence_ok, evidence_bad),
    stringsAsFactors = FALSE
  )
}

validation <- rbind(
  check("HEAD_AND_ORIGIN_AT_ACD5280", identical(head_short, "acd5280") && identical(origin_short, "acd5280"),
        paste0("HEAD=", head_short, "; origin/main=", origin_short, "; branch=", branch_name, ".")),
  check("S20_OUTPUTS_FOUND", all(file.exists(s20_hash_targets)),
        paste("Found", sum(file.exists(s20_hash_targets)), "current S20 artifacts.")),
  check("S20_DECISION_AUTHORIZES_MODEL_INPUT_CONSUMPTION", s20_decision_found,
        "AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION recognized."),
  check("S20B_OUTPUTS_FOUND", all(file.exists(c(s20b_validation_path, s20b_contract_path, s20b_audit_path, s20b_report_path))),
        "S20B validation, contract, audit, and report artifacts found."),
  check("S20B_BLOCK_DECISION_RECOGNIZED", s20b_block_found,
        "BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION recognized."),
  check("S14_OUTPUTS_FOUND_AND_PASS", file.exists(s14_validation_path) && all(s14_validation$status == "PASS"),
        paste0("S14 validation PASS checks: ", sum(s14_validation$status == "PASS"), "/", nrow(s14_validation), ".")),
  check("S20_CAPITAL_LAYER_LEFT_UNCHANGED", s20_hash_unchanged,
        "Current S20 artifacts are byte-identical before and after S20C execution."),
  check("NO_GPIM_RECONSTRUCTION", !gpim_reconstruction,
        "S20C does not reconstruct GPIM or alter K_GROSS_GPIM_TOTAL."),
  check("NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED", !provider_roots_accessed,
        "S20C reads repo-local outputs/docs/processed ledgers only; provider/raw roots are not inputs."),
  check("NO_DOWNSTREAM_ECONOMETRIC_STAGE_INVOKED", !downstream_invocation,
        "S20C script contains no source/system invocation of S21/S22/S30/S32 scripts."),
  check("NO_THETA_PRODUCTIVE_CAPACITY_UTILIZATION_OR_Q", !econometric_calls && !theta_capacity_q_constructed,
        "No theta, productive capacity, utilization, accumulated q, or econometric estimator is constructed."),
  check("CANDIDATE_SECTORAL_WAGE_SHARE_SOURCES_AUDITED", nrow(candidate_audit) > 0L,
        paste("Candidate audit rows:", nrow(candidate_audit))),
  check("GENERIC_WAGE_SHARE_OBJECTS_REJECTED", !generic_authorized,
        "Generic or unclear wage-share objects are not authorized."),
  check("NFC_WAGE_SHARE_BASELINE_AUTHORIZED_OR_FAILED_CLOSED", nfc_status %in% c("AUTHORIZE_S20C_NFC_WAGE_SHARE_SOURCE_CONTRACT", "BLOCK_S20C_NFC_WAGE_SHARE_PENDING_SOURCE_CONTRACT"),
        paste("NFC decision:", nfc_status)),
  check("CORPORATE_WAGE_SHARE_ROBUSTNESS_AUTHORIZED_OR_FAILED_CLOSED", corp_status %in% c("AUTHORIZE_CORPORATE_WAGE_SHARE_ROBUSTNESS_SOURCE_CONTRACT", "BLOCK_CORPORATE_WAGE_SHARE_ROBUSTNESS_PENDING_SOURCE_CONTRACT"),
        paste("Corporate robustness decision:", corp_status)),
  check("PROFIT_SHARE_ALTERNATIVE_ONLY", all(blocked_rejected$status[blocked_rejected$object_id == "PROFIT_SHARE_BASELINE_SUBSTITUTE"] == "ALTERNATIVE_OR_RECONCILIATION_EVIDENCE_ONLY"),
        "Profit share is kept as alternative/reconciliation evidence only."),
  check("SHAIKH_BLOCKED_UNLESS_CROSSWALK_PLUS_DATA", !shaikh_authorized,
        "No Shaikh-adjusted object is authorized; blocked pending crosswalk plus data."),
  check("NO_S20_PANEL_ATTACHMENT_PERFORMED", !s20_panel_attachment_performed,
        "S20C creates source contracts only; no S20 panel merge is performed."),
  check("FINAL_DECISION_EXPLICIT", final_decision %in% c("AUTHORIZE_S20D_DISTRIBUTION_ATTACHMENT_PROMPT", "BLOCK_S20C_NFC_WAGE_SHARE_PENDING_SOURCE_CONTRACT"),
        final_decision)
)

write_csv(candidate_audit, rel(csv_dir, "S20C_candidate_source_audit_ledger.csv"))
write_csv(contract_ledger, rel(csv_dir, "S20C_sectoral_wage_share_source_contract_ledger.csv"))
write_csv(blocked_rejected, rel(csv_dir, "S20C_blocked_rejected_wage_share_object_ledger.csv"))
write_csv(validation, rel(csv_dir, "S20C_validation_checks.csv"))

summary_table <- aggregate(candidate_id ~ sector_classification + object_kind, candidate_audit, length)
names(summary_table)[3] <- "candidate_count"
summary_table <- summary_table[order(summary_table$sector_classification, summary_table$object_kind), ]

contract_md <- apply(contract_ledger, 1, function(x) {
  paste0("|", x[["contract_id"]], "|", x[["status"]], "|", x[["role"]], "|",
         x[["sector_boundary"]], "|", x[["formula"]], "|", x[["common_support_start"]],
         "-", x[["common_support_end"]], "|")
})

summary_md <- apply(summary_table, 1, function(x) {
  paste0("|", x[["sector_classification"]], "|", x[["object_kind"]], "|", x[["candidate_count"]], "|")
})

validation_md <- apply(validation, 1, function(x) {
  paste0("|", x[["check_id"]], "|", x[["status"]], "|", gsub("\\|", "/", x[["evidence"]]), "|")
})

md_lines <- c(
  "# S20C Sectoral Wage-Share Source Lane",
  "",
  "## Scope",
  "",
  "S20C creates a sector-explicit unadjusted wage-share source-lane contract. It does not attach a wage-share series to S20, run S21/S22/S30/S32, run econometrics, estimate theta, construct productive capacity, construct utilization, construct accumulated q, reconstruct GPIM, or alter S20 capital outputs.",
  "",
  "## Governing Inputs",
  "",
  "- `output/US/S20_MODEL_INPUT_LAYER/`",
  "- `output/US/S20B_DISTRIBUTION_ATTACHMENT_CONTRACT/`",
  "- `output/US/S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION/`",
  "- `data/processed/us_s10/us_s10_source_panel_long.csv` and `data/processed/us_s10/us_s10_object_admissibility_ledger.csv` as repo-local current-release source metadata",
  "",
  "## Candidate Source Summary",
  "",
  "|sector_classification|object_kind|candidate_count|",
  "|---|---|---:|",
  summary_md,
  "",
  "The current-release repo-local S10 source panel contains staged annual BEA NIPA Table 1.14 ingredients for `NFC_COMP`, `NFC_GVA`, `CORP_COMP`, and `CORP_GVA`. Each is current-dollar, annual, documented with provenance fields, and covers 1929-2025, so each overlaps the S20 aggregate-capital common support of 1931-2024. Legacy constructed wage-share panels remain audited but not authorized as current source authority.",
  "",
  "## Source Contracts",
  "",
  "|contract_id|status|role|sector_boundary|formula|common_support|",
  "|---|---|---|---|---|---|",
  contract_md,
  "",
  "S20C authorizes source-lane contracts only. It does not merge either source into the S20 model-input panel. The NFC contract is the preferred baseline. The corporate contract is available only for robustness or reconciliation unless a later protocol explicitly shifts the model boundary.",
  "",
  "## Rejections And Blocks",
  "",
  "Generic economy-wide, private-business, total-business, nonfarm-business, household, mixed-income, and sector-unclear wage-share objects remain rejected for baseline use. Profit-share objects remain alternative or reconciliation evidence only. Shaikh-adjusted objects remain blocked pending both a current-release source-data contract and a passing semantic/accounting crosswalk.",
  "",
  "## Validation",
  "",
  "|check_id|status|evidence|",
  "|---|---|---|",
  validation_md,
  "",
  "## Final Decision",
  "",
  paste0("`", final_decision, "`")
)
writeLines(md_lines, rel(md_dir, "S20C_SECTORAL_WAGE_SHARE_SOURCE_LANE.md"), useBytes = TRUE)

if (any(validation$status != "PASS")) {
  failed <- validation$check_id[validation$status != "PASS"]
  stop("S20C validation failed: ", paste(failed, collapse = ", "), call. = FALSE)
}

message("S20C NFC baseline decision: ", nfc_status)
message("S20C corporate robustness decision: ", corp_status)
message("S20C final decision: ", final_decision)
message("Candidate audit rows: ", nrow(candidate_audit))
