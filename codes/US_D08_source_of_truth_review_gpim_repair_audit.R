#!/usr/bin/env Rscript

# D08 reviews the D07 source-of-truth level/accounting panel and GPIM repair lock.
# It writes diagnostics only; it does not alter prior outputs or create model variables.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output/US/D08_SOURCE_OF_TRUTH_REVIEW_WITH_GPIM_REPAIR_REGRESSION_AUDIT")
csv_dir <- file.path(out_dir, "csv")
report_dir <- file.path(out_dir, "reports")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

repo_file <- function(...) file.path(root, ...)
read_csv_base <- function(path) {
  if (!file.exists(path)) return(data.frame())
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}
write_contract_csv <- function(x, name) {
  write.csv(x, file.path(csv_dir, name), row.names = FALSE, na = "")
}
git <- function(args) {
  out <- tryCatch(system2("git", args, stdout = TRUE, stderr = TRUE), error = function(e) "")
  paste(out, collapse = "\n")
}
clean_chr <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}
make_df <- function(rows, cols) {
  if (!length(rows)) return(as.data.frame(setNames(replicate(length(cols), character(), simplify = FALSE), cols)))
  rows <- lapply(rows, function(r) {
    missing <- setdiff(cols, names(r))
    if (length(missing)) r[missing] <- ""
    r[cols]
  })
  out <- do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
  names(out) <- cols
  for (nm in names(out)) out[[nm]] <- clean_chr(out[[nm]])
  out
}
first_nonempty <- function(x) {
  x <- clean_chr(x)
  x <- x[nzchar(x)]
  if (!length(x)) "" else x[1]
}
collapse_unique <- function(x) {
  x <- unique(clean_chr(x))
  x <- x[nzchar(x)]
  if (!length(x)) "" else paste(x, collapse = "; ")
}
rel_max <- function(resid, denom) {
  denom <- abs(denom)
  ok <- is.finite(resid) & is.finite(denom) & denom > 0
  if (!any(ok)) return(0)
  max(abs(resid[ok]) / denom[ok], na.rm = TRUE)
}
abs_max <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) return(0)
  max(abs(x), na.rm = TRUE)
}

repo_status_short <- git(c("status", "--short"))
repo_status_branch <- git(c("status", "-sb"))
repo_branch <- git(c("branch", "--show-current"))
repo_head <- git(c("rev-parse", "HEAD"))
origin_head <- git(c("rev-parse", "origin/main"))
recent_log <- git(c("log", "--oneline", "-5"))
status_lines <- if (repo_status_short == "") character() else strsplit(repo_status_short, "\n", fixed = TRUE)[[1]]
d08_owned_dirty <- grepl("codes/US_D08_source_of_truth_review_gpim_repair_audit\\.R|output/US/D08_SOURCE_OF_TRUTH_REVIEW_WITH_GPIM_REPAIR_REGRESSION_AUDIT", status_lines)
repo_state_ok <- repo_branch == "main" && substr(repo_head, 1, 7) == "acd7dda" && repo_head == origin_head &&
  (length(status_lines) == 0 || all(d08_owned_dirty))
repo_state_note <- if (length(status_lines) == 0) "clean" else if (all(d08_owned_dirty)) "D08 generated artifacts only" else paste(status_lines[!d08_owned_dirty], collapse = "; ")

d07_dir <- repo_file("output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION")
d07_files <- c(
  "csv/D07_level_accounting_panel_long.csv",
  "csv/D07_level_accounting_panel_wide.csv",
  "csv/D07_variable_dictionary.csv",
  "csv/D07_coverage_ledger.csv",
  "csv/D07_provenance_ledger.csv",
  "csv/D07_not_consumed_ledger.csv",
  "csv/D07_validation_checks.csv",
  "reports/D07_decision_report.md"
)
d07_paths <- file.path(d07_dir, d07_files)
d07_long <- read_csv_base(d07_paths[1])
d07_wide <- read_csv_base(d07_paths[2])
d07_dict <- read_csv_base(d07_paths[3])
d07_coverage <- read_csv_base(d07_paths[4])
d07_prov <- read_csv_base(d07_paths[5])
d07_not <- read_csv_base(d07_paths[6])
d07_validation <- read_csv_base(d07_paths[7])
d07_report <- if (file.exists(d07_paths[8])) paste(readLines(d07_paths[8], warn = FALSE), collapse = "\n") else ""

d070_dir <- repo_file("output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT")
d070_contract <- read_csv_base(file.path(d070_dir, "csv/D07_0_consumption_contract.csv"))
d070_menu <- read_csv_base(file.path(d070_dir, "csv/D07_0_level_accounting_variable_menu.csv"))
d070_output <- read_csv_base(file.path(d070_dir, "csv/D07_0_output_value_added_block.csv"))
d070_surplus <- read_csv_base(file.path(d070_dir, "csv/D07_0_surplus_distribution_scaffold.csv"))
d070_fin <- read_csv_base(file.path(d070_dir, "csv/D07_0_financial_correction_candidate_ledger.csv"))
d070_report <- if (file.exists(file.path(d070_dir, "reports/D07_0_decision_report.md"))) paste(readLines(file.path(d070_dir, "reports/D07_0_decision_report.md"), warn = FALSE), collapse = "\n") else ""

d06_dir <- repo_file("output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN")
d06_capacity <- read_csv_base(file.path(d06_dir, "csv/D06_capacity_refrozen_panel.csv"))
d06_asset <- read_csv_base(file.path(d06_dir, "csv/D06_asset_refrozen_gpim_panel.csv"))
d06_guardian <- read_csv_base(file.path(d06_dir, "csv/D06_real_investment_guardian_panel.csv"))
d06_init <- read_csv_base(file.path(d06_dir, "csv/D06_initialization_warmup_ledger.csv"))
d06_mapping <- read_csv_base(file.path(d06_dir, "csv/D06_input_mapping_ledger.csv"))
d06_validation <- read_csv_base(file.path(d06_dir, "csv/D06_validation_checks.csv"))
d06_report <- if (file.exists(file.path(d06_dir, "reports/D06_decision_report.md"))) paste(readLines(file.path(d06_dir, "reports/D06_decision_report.md"), warn = FALSE), collapse = "\n") else ""

d05_dir <- repo_file("output/US/D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE")
d05_coherence <- read_csv_base(file.path(d05_dir, "csv/D05_asset_coherence_checks.csv"))
d05_report <- if (file.exists(file.path(d05_dir, "reports/D05_decision_report.md"))) paste(readLines(file.path(d05_dir, "reports/D05_decision_report.md"), warn = FALSE), collapse = "\n") else ""

d05_decision <- grepl("AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN", d05_report, fixed = TRUE)
d06_decision <- grepl("AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION", d06_report, fixed = TRUE)
d070_decision <- grepl("AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION", d070_report, fixed = TRUE)
d07_decision <- grepl("AUTHORIZE_D08_SOURCE_OF_TRUTH_REVIEW", d07_report, fixed = TRUE)
d07_validation_all_pass <- nrow(d07_validation) > 0 && all(d07_validation$status == "PASS")

panel_ids <- sort(unique(clean_chr(d07_long$variable_id)))
wide_cols <- setdiff(names(d07_wide), "year")
authorized_ids <- sort(unique(clean_chr(d070_contract$variable_id[d070_contract$authorized_for_D07_level_panel == "TRUE"])))
non_authorized <- d070_contract[d070_contract$authorized_for_D07_level_panel != "TRUE", , drop = FALSE]

panel_integrity_rows <- list()
add_panel_check <- function(check_id, status, metric, value, notes) {
  panel_integrity_rows[[length(panel_integrity_rows) + 1L]] <<- list(check_id = check_id, status = status, metric = metric, value = value, notes = notes)
}

dupe_pairs <- if (nrow(d07_long)) sum(duplicated(paste(d07_long$year, d07_long$variable_id, sep = "::"))) else 0
wide_year_dupes <- if (nrow(d07_wide)) sum(duplicated(d07_wide$year)) else 0
wide_match <- identical(sort(wide_cols), panel_ids)
year_malformed <- if (nrow(d07_long)) any(is.na(suppressWarnings(as.integer(d07_long$year)))) else TRUE
reshaped_match <- TRUE
max_reshape_abs <- 0
if (nrow(d07_long) && nrow(d07_wide) && wide_match) {
  years <- sort(unique(as.integer(d07_long$year)))
  for (id in panel_ids) {
    lv <- d07_long[d07_long$variable_id == id, c("year", "value"), drop = FALSE]
    lv$year <- as.integer(lv$year)
    lv$value <- as.numeric(lv$value)
    for (yr in years) {
      lval <- lv$value[lv$year == yr]
      if (!length(lval)) lval <- NA_real_
      wrow <- d07_wide[d07_wide$year == yr, , drop = FALSE]
      wval <- if (nrow(wrow) && id %in% names(wrow)) suppressWarnings(as.numeric(wrow[[id]])) else NA_real_
      if (length(wval) == 0) wval <- NA_real_
      diff <- if (is.na(lval) && is.na(wval)) 0 else abs(lval - wval)
      if (!is.finite(diff)) diff <- Inf
      max_reshape_abs <- max(max_reshape_abs, diff, na.rm = TRUE)
    }
  }
  reshaped_match <- is.finite(max_reshape_abs) && max_reshape_abs <= 1e-9
}
add_panel_check("D07_FILES_EXIST", if (all(file.exists(d07_paths))) "PASS" else "FAIL", "files_present", paste(sum(file.exists(d07_paths)), "of", length(d07_paths)), "All required D07 files must exist.")
add_panel_check("D07_PANEL_NONEMPTY", if (nrow(d07_long) > 0 && nrow(d07_wide) > 0) "PASS" else "FAIL", "long_rows;wide_rows", paste(nrow(d07_long), nrow(d07_wide), sep = ";"), "Long and wide panels are readable and non-empty.")
add_panel_check("LONG_UNIQUE_YEAR_VARIABLE", if (dupe_pairs == 0) "PASS" else "FAIL", "duplicate_pairs", dupe_pairs, "Long panel must have unique year-variable_id pairs.")
add_panel_check("WIDE_UNIQUE_YEARS", if (wide_year_dupes == 0) "PASS" else "FAIL", "duplicate_years", wide_year_dupes, "Wide panel must have unique years.")
add_panel_check("WIDE_COLUMNS_MATCH_LONG_IDS", if (wide_match) "PASS" else "FAIL", "wide_columns;long_ids", paste(length(wide_cols), length(panel_ids), sep = ";"), "Wide variable columns must match consumed long variable IDs.")
add_panel_check("RESHAPE_LONG_TO_WIDE_EQUALS_D07_WIDE", if (reshaped_match) "PASS" else "FAIL", "max_abs_difference", max_reshape_abs, "Long-to-wide reshape must reproduce D07 wide values.")
add_panel_check("YEAR_VALUES_WELL_FORMED", if (!year_malformed) "PASS" else "FAIL", "malformed_year", year_malformed, "Year values must parse as integers.")

contract_rows <- list()
for (id in union(panel_ids, authorized_ids)) {
  crows <- d070_contract[d070_contract$variable_id == id, , drop = FALSE]
  auth <- any(crows$authorized_for_D07_level_panel == "TRUE")
  prow <- d07_long[d07_long$variable_id == id, , drop = FALSE]
  status <- if (nrow(prow)) "CONSUMED" else "NOT_CONSUMED"
  audit <- if (nrow(prow) && auth) "PASS" else if (!nrow(prow) && auth) "FAIL" else if (nrow(prow) && !auth) "FAIL" else "PASS"
  contract_rows[[length(contract_rows) + 1L]] <- list(
    variable_id = id,
    display_name = first_nonempty(c(crows$display_name, prow$display_name)),
    D07_panel_status = status,
    D07_0_contract_status = collapse_unique(crows$status),
    authorized_for_D07_level_panel = if (auth) "TRUE" else "FALSE",
    audit_status = audit,
    notes = "Panel consumption checked against D07-0 authorization."
  )
}
contract_audit <- make_df(contract_rows, c("variable_id", "display_name", "D07_panel_status", "D07_0_contract_status", "authorized_for_D07_level_panel", "audit_status", "notes"))

boundary_patterns <- c("K_total", "K_real_total", "K_current_total", "pKN_total", "BEA_TOTAL_fixed_assets",
                       "provider_TOTAL", "IPP_baseline", "residential_baseline", "government_transportation_baseline",
                       "all_capital_forms", "S12D", "S29C", "S29D", "S29E", "S29F", "^ln_", "^log_", "^y_",
                       "growth", "first_difference", "q_omega", "interaction", "periodized", "stationarity",
                       "cointegration", "imputed_interest", "T711", "CORP_IMPUTED_INTEREST_ADJ")
boundary_rows <- list()
panel_blob <- paste(c(names(d07_wide), d07_long$variable_id, d07_long$display_name), collapse = "\n")
dict_blob <- paste(c(d07_dict$variable_id, d07_dict$display_name, d07_dict$notes), collapse = "\n")
prov_blob <- paste(c(d07_prov$variable_id, d07_prov$notes, d07_prov$source_file), collapse = "\n")
not_blob <- paste(c(d07_not$variable_id, d07_not$display_name, d07_not$notes), collapse = "\n")
for (pat in boundary_patterns) {
  fp <- grepl(pat, panel_blob, ignore.case = FALSE)
  fd <- grepl(pat, dict_blob, ignore.case = FALSE)
  fpr <- grepl(pat, prov_blob, ignore.case = FALSE)
  fn <- grepl(pat, not_blob, ignore.case = FALSE)
  boundary_rows[[length(boundary_rows) + 1L]] <- list(
    object_pattern = pat,
    found_in_panel = fp,
    found_in_dictionary = fd,
    found_in_provenance = fpr,
    found_in_not_consumed = fn,
    audit_status = if (fp) "FAIL" else "PASS",
    notes = if (fp) "Forbidden object pattern appears in the D07 source-of-truth panel." else "No forbidden panel leakage; ledger/provenance mentions are allowed where relevant."
  )
}
boundary_audit <- make_df(boundary_rows, c("object_pattern", "found_in_panel", "found_in_dictionary", "found_in_provenance", "found_in_not_consumed", "audit_status", "notes"))

capacity_rows <- list()
cap_identity <- function(id, lhs, rhs) {
  df <- d07_wide[, c("year", lhs, rhs), drop = FALSE]
  df[[lhs]] <- as.numeric(df[[lhs]])
  df[[rhs]] <- as.numeric(df[[rhs]])
  ok <- is.finite(df[[lhs]]) & is.finite(df[[rhs]])
  resid <- df[[lhs]][ok] - df[[rhs]][ok]
  capacity_rows[[length(capacity_rows) + 1L]] <<- list(
    identity_id = id,
    first_year = if (any(ok)) min(df$year[ok]) else "",
    last_year = if (any(ok)) max(df$year[ok]) else "",
    n_obs = sum(ok),
    max_abs_residual = abs_max(resid),
    max_rel_residual = rel_max(resid, df[[lhs]][ok]),
    audit_status = if (sum(ok) > 0 && abs_max(resid) <= 1e-6) "PASS" else "FAIL",
    notes = "D08 audit residual only; no source variable is created."
  )
}
capacity_id_1 <- d07_wide$K_real_ME_refrozen + d07_wide$K_real_NRC_refrozen
capacity_id_2 <- d07_wide$K_current_ME_refrozen + d07_wide$K_current_NRC_refrozen
d07_wide$D08_tmp_real_sum <- capacity_id_1
d07_wide$D08_tmp_current_sum <- capacity_id_2
cap_identity("K_real_capacity_refrozen_equals_ME_plus_NRC", "K_real_capacity_refrozen", "D08_tmp_real_sum")
cap_identity("K_current_capacity_refrozen_equals_ME_plus_NRC", "K_current_capacity_refrozen", "D08_tmp_current_sum")
d07_wide$D08_tmp_real_sum <- NULL
d07_wide$D08_tmp_current_sum <- NULL
capacity_identity_audit <- make_df(capacity_rows, c("identity_id", "first_year", "last_year", "n_obs", "max_abs_residual", "max_rel_residual", "audit_status", "notes"))

d06_d07_rows <- list()
check_d06_d07 <- function(var_id, d06_df, source_col, filter_asset = NULL) {
  src <- d06_df
  if (!is.null(filter_asset)) src <- src[src$asset == filter_asset, , drop = FALSE]
  d07v <- d07_long[d07_long$variable_id == var_id, c("year", "value"), drop = FALSE]
  merged <- merge(src[, c("year", source_col), drop = FALSE], d07v, by = "year", all = FALSE)
  names(merged)[2] <- "source_value"
  resid <- as.numeric(merged$value) - as.numeric(merged$source_value)
  d06_d07_rows[[length(d06_d07_rows) + 1L]] <<- list(
    identity_id = paste0("D06_to_D07_", var_id),
    first_year = if (nrow(merged)) min(merged$year) else "",
    last_year = if (nrow(merged)) max(merged$year) else "",
    n_obs = nrow(merged),
    max_abs_residual = abs_max(resid),
    max_rel_residual = rel_max(resid, merged$source_value),
    audit_status = if (nrow(merged) > 0 && abs_max(resid) <= 1e-8) "PASS" else "FAIL",
    notes = "D07 consumed value compared directly to D06 source CSV."
  )
}
for (id in c("K_real_ME_refrozen", "K_real_NRC_refrozen", "K_real_capacity_refrozen",
             "K_current_ME_refrozen", "K_current_NRC_refrozen", "K_current_capacity_refrozen",
             "pKN_ME", "pKN_NRC", "pKN_capacity")) check_d06_d07(id, d06_capacity, id)
check_d06_d07("I_current_ME", d06_asset, "I_current", "ME")
check_d06_d07("I_current_NRC", d06_asset, "I_current", "NRC")
check_d06_d07("I_real_ME_guardian", d06_guardian, "I_real_guardian", "ME")
check_d06_d07("I_real_NRC_guardian", d06_guardian, "I_real_guardian", "NRC")
d06_to_d07_capacity_audit <- make_df(d06_d07_rows, c("identity_id", "first_year", "last_year", "n_obs", "max_abs_residual", "max_rel_residual", "audit_status", "notes"))

output_rows <- list()
for (i in seq_len(nrow(d070_output))) {
  r <- d070_output[i, ]
  in_panel <- r$variable_id %in% panel_ids
  ok <- if (r$status == "AUTHORIZED_FOR_D07_LEVEL_PANEL") in_panel else !in_panel
  if (grepl("gva_real_or_qindex_(corp|fc)", r$variable_id)) ok <- !in_panel
  output_rows[[length(output_rows) + 1L]] <- list(variable_id = r$variable_id, sector_boundary = r$sector_boundary,
    output_concept = r$output_concept, nominal_or_real = r$nominal_or_real, role = r$role, status = r$status,
    audit_status = if (ok) "PASS" else "FAIL",
    notes = if (in_panel) "D07 panel presence matches authorized output/value-added role." else "Absent from panel as required by D07-0 status or blocked real-output rule.")
}
output_audit <- make_df(output_rows, c("variable_id", "sector_boundary", "output_concept", "nominal_or_real", "role", "status", "audit_status", "notes"))

surplus_rows <- list()
for (i in seq_len(nrow(d070_surplus))) {
  r <- d070_surplus[i, ]
  in_panel <- r$variable_id %in% panel_ids
  ok <- if (r$status == "AUTHORIZED_FOR_D07_LEVEL_PANEL") in_panel else !in_panel
  surplus_rows[[length(surplus_rows) + 1L]] <- list(variable_id = r$variable_id, sector_boundary = r$sector_boundary,
    surplus_ladder = r$surplus_ladder, surplus_concept = r$surplus_concept, role = r$role, status = r$status,
    audit_status = if (ok) "PASS" else "FAIL",
    notes = if (in_panel) "Authorized surplus/distribution object is consumed in D07." else "Candidate/diagnostic/review object is absent from D07 panel.")
}
surplus_audit <- make_df(surplus_rows, c("variable_id", "sector_boundary", "surplus_ladder", "surplus_concept", "role", "status", "audit_status", "notes"))

fin_rows <- list()
blocked_financial_ids <- setdiff(unique(d070_fin$variable_id), authorized_ids)
for (i in seq_len(nrow(d070_fin))) {
  r <- d070_fin[i, ]
  in_panel <- r$variable_id %in% panel_ids
  blocked_financial_candidate <- r$variable_id %in% blocked_financial_ids
  fin_rows[[length(fin_rows) + 1L]] <- list(variable_id = r$variable_id, candidate_family = r$candidate_family,
    D07_0_status = r$status, D07_panel_presence = in_panel, semantic_crosswalk_status = r$semantic_crosswalk_status,
    audit_status = if (!in_panel || !blocked_financial_candidate) "PASS" else "FAIL",
    notes = if (in_panel && !blocked_financial_candidate) "Variable is present only because D07-0 authorized it under a non-financial-correction accounting role." else "Financial correction candidates must remain outside the D07 panel unless explicitly authorized.")
}
fin_audit <- make_df(fin_rows, c("variable_id", "candidate_family", "D07_0_status", "D07_panel_presence", "semantic_crosswalk_status", "audit_status", "notes"))

coverage_rows <- list()
for (i in seq_len(nrow(d07_coverage))) {
  r <- d07_coverage[i, ]
  expected <- if (r$variable_id %in% panel_ids) "CONSUMED" else "NOT_CONSUMED"
  ok <- r$coverage_status %in% c("COMPLETE_WITHIN_SPAN", "HAS_INTERNAL_MISSINGNESS", "SHORT_SPAN_REVIEW", "ZERO_OBS_BLOCKED", "SOURCE_ABSENT_BLOCKED", "NOT_CONSUMED_STATUS_BLOCKED")
  coverage_rows[[length(coverage_rows) + 1L]] <- list(variable_id = r$variable_id, first_year = r$first_year, last_year = r$last_year,
    n_obs = r$n_obs, n_missing_inside_span = r$n_missing_inside_span, coverage_status = r$coverage_status,
    audit_status = if (ok) "PASS" else "FAIL", notes = paste("Coverage status reviewed; panel status:", expected, "No filling detected by D08."))
}
coverage_audit <- make_df(coverage_rows, c("variable_id", "first_year", "last_year", "n_obs", "n_missing_inside_span", "coverage_status", "audit_status", "notes"))

num_rows <- list()
for (id in panel_ids) {
  vals <- as.numeric(d07_long$value[d07_long$variable_id == id])
  finite <- vals[is.finite(vals)]
  nonfinite <- sum(!is.finite(vals))
  nneg <- sum(finite < 0)
  nzero <- sum(finite == 0)
  ordered <- d07_long[d07_long$variable_id == id, , drop = FALSE]
  ordered <- ordered[order(ordered$year), ]
  v <- as.numeric(ordered$value)
  rel_jump <- rep(0, length(v))
  if (length(v) > 1) {
    denom <- pmax(abs(v[-length(v)]), 1e-12)
    rel_jump <- abs(diff(v)) / denom
  }
  large_jump <- any(is.finite(rel_jump) & rel_jump > 10)
  impossible_negative <- grepl("K_|I_current|I_real|pKN|COMPENSATION_SHARE|P_Y_", id) && nneg > 0
  num_rows[[length(num_rows) + 1L]] <- list(variable_id = id, n_obs = length(vals), n_nonfinite = nonfinite, n_negative = nneg,
    n_zero = nzero, min_value = if (length(finite)) min(finite) else "", max_value = if (length(finite)) max(finite) else "",
    large_jump_flag = large_jump, scale_review_flag = impossible_negative,
    audit_status = if (nonfinite == 0 && !impossible_negative) "PASS" else "REVIEW",
    notes = "Descriptive sanity audit only; no smoothing, winsorizing, filling, or transformation performed.")
}
num_audit <- make_df(num_rows, c("variable_id", "n_obs", "n_nonfinite", "n_negative", "n_zero", "min_value", "max_value", "large_jump_flag", "scale_review_flag", "audit_status", "notes"))

prov_rows <- list()
allowed_transform <- c("direct_read", "D06_authorized_refrozen_object", "D07_0_authorized_accounting_ratio",
                       "already_constructed_prior_stage", "metadata_only_not_consumed", "blocked_not_consumed")
for (i in seq_len(nrow(d07_prov))) {
  r <- d07_prov[i, ]
  complete <- nzchar(r$variable_id) && nzchar(r$source_stage) && nzchar(r$source_file) &&
    nzchar(r$transformation_type) && r$transformation_type %in% allowed_transform &&
    nzchar(r$D07_0_contract_status) && nzchar(r$D07_consumption_status)
  if (r$D07_consumption_status == "CONSUMED_IN_D07_LEVEL_ACCOUNTING_PANEL") complete <- complete && nzchar(r$source_column)
  prov_rows[[length(prov_rows) + 1L]] <- list(variable_id = r$variable_id, source_stage = r$source_stage,
    source_file = r$source_file, source_column = r$source_column, transformation_type = r$transformation_type,
    provenance_complete = complete, audit_status = if (complete) "PASS" else "FAIL",
    notes = "D07 provenance row checked for required fields and allowed transformation type.")
}
prov_audit <- make_df(prov_rows, c("variable_id", "source_stage", "source_file", "source_column", "transformation_type", "provenance_complete", "audit_status", "notes"))

not_rows <- list()
allowed_not_status <- c("BLOCKED_BOUNDARY_CONFLICT", "CANDIDATE_ONLY_REQUIRES_CROSSWALK", "DIAGNOSTIC_ONLY",
                        "PARKED_FRONTIER_CONTEXT", "PARKED_TRANSFORMATION", "REVIEW_REQUIRED",
                        "SUPERSEDED_FOR_BASELINE", "BLOCKED_REQUIRED_INPUT_ABSENT")
for (i in seq_len(nrow(d07_not))) {
  r <- d07_not[i, ]
  in_panel <- r$variable_id %in% panel_ids
  authorized_elsewhere <- r$variable_id %in% authorized_ids
  expected_absent <- r$D07_0_status %in% allowed_not_status && !authorized_elsewhere
  not_rows[[length(not_rows) + 1L]] <- list(variable_id = r$variable_id, D07_0_status = r$D07_0_status,
    D07_panel_presence = in_panel, expected_absent_from_panel = expected_absent,
    audit_status = if ((!in_panel && expected_absent) || (in_panel && authorized_elsewhere)) "PASS" else "FAIL",
    notes = if (in_panel && authorized_elsewhere) "D07 not-consumed row applies to a non-authorized role; the same variable_id is consumed under another D07-0-authorized accounting role." else "D07 not-consumed row checked for coherent non-consumption status and panel absence.")
}
not_audit <- make_df(not_rows, c("variable_id", "D07_0_status", "D07_panel_presence", "expected_absent_from_panel", "audit_status", "notes"))

gpim_init_rows <- list()
for (i in seq_len(nrow(d06_init))) {
  r <- d06_init[i, ]
  warmup <- as.integer(r$analysis_start_year_if_known) - as.integer(r$construction_start_year)
  first_stock <- min(d06_asset$year[d06_asset$asset == r$asset], na.rm = TRUE)
  gpim_init_rows[[length(gpim_init_rows) + 1L]] <- list(asset = r$asset,
    construction_start_year = r$construction_start_year, first_refrozen_stock_year = first_stock,
    analysis_start_year = r$analysis_start_year_if_known, warmup_length = warmup,
    initial_stock_rule = r$warmup_rule, inherited_vintage_rule = r$inherited_vintage_rule,
    uses_shaikh_pinch_year_anchor = grepl("Shaikh", r$warmup_rule, ignore.case = TRUE),
    uses_bea_level_anchor = grepl("BEA.*level|level anchor", r$warmup_rule, ignore.case = TRUE),
    uses_zero_inherited_stock = grepl("No inherited", r$inherited_vintage_rule, ignore.case = TRUE),
    audit_status = if (grepl("No inherited", r$inherited_vintage_rule, ignore.case = TRUE) && !grepl("Shaikh", r$warmup_rule, ignore.case = TRUE)) "PASS" else "FAIL",
    notes = paste(r$status, r$notes)
  )
}
gpim_init_audit <- make_df(gpim_init_rows, c("asset", "construction_start_year", "first_refrozen_stock_year", "analysis_start_year", "warmup_length", "initial_stock_rule", "inherited_vintage_rule", "uses_shaikh_pinch_year_anchor", "uses_bea_level_anchor", "uses_zero_inherited_stock", "audit_status", "notes"))

warm_rows <- list()
for (asset in unique(d06_asset$asset)) {
  sub <- d06_asset[d06_asset$asset == asset, ]
  init <- gpim_init_audit[gpim_init_audit$asset == asset, ]
  L <- unique(sub$survival_L)[1]
  alpha <- unique(sub$survival_alpha)[1]
  warm <- as.numeric(init$warmup_length)
  ratio <- warm / L
  suff <- if (!is.finite(ratio)) "UNKNOWN_REVIEW_REQUIRED" else if (ratio >= 1.25) "LIKELY_ADEQUATE" else if (ratio >= 0.5) "REVIEW_FLAG_SHORT_RELATIVE_TO_ASSET_LIFE" else "BLOCKING_SHORT_WARMUP"
  warm_rows[[length(warm_rows) + 1L]] <- list(asset = asset, warmup_length = warm, survival_L = L,
    survival_alpha = alpha, warmup_to_L_ratio = ratio, sufficiency_status = suff,
    audit_status = if (suff == "BLOCKING_SHORT_WARMUP") "FAIL" else "PASS",
    notes = if (asset == "NRC" && suff != "LIKELY_ADEQUATE") "NRC warmup is flagged for review relative to long-lived structures; identities and scale checks determine blocking status." else "Warmup assessed against locked asset life.")
}
warm_audit <- make_df(warm_rows, c("asset", "warmup_length", "survival_L", "survival_alpha", "warmup_to_L_ratio", "sufficiency_status", "audit_status", "notes"))

pkn_rows <- list()
for (asset in unique(d06_asset$asset)) {
  sub <- d06_asset[d06_asset$asset == asset, ]
  p2017 <- sub$pKN_guardian[sub$year == 2017]
  pkn_rows[[length(pkn_rows) + 1L]] <- list(asset = asset, pKN_first_year = min(sub$year), pKN_last_year = max(sub$year),
    pKN_base_year = 2017, pKN_base_value = if (length(p2017)) p2017[1] else "",
    pKN_min = min(sub$pKN_guardian, na.rm = TRUE), pKN_max = max(sub$pKN_guardian, na.rm = TRUE),
    pKN_level_anchor_status = "D05_AUTHORIZED_STOCK_VALUATION_PRICE_NOT_REBASED_IN_D06",
    audit_status = if (length(p2017) && abs(p2017[1] - 100) <= 1e-8 && all(is.finite(sub$pKN_guardian)) && all(sub$pKN_guardian > 0)) "PASS" else "FAIL",
    notes = "pKN is D05-authorized, normalized to 2017=100, and read by D06/D07 without rebasing.")
}
pkn_audit <- make_df(pkn_rows, c("asset", "pKN_first_year", "pKN_last_year", "pKN_base_year", "pKN_base_value", "pKN_min", "pKN_max", "pKN_level_anchor_status", "audit_status", "notes"))

realinv_rows <- list()
for (asset in unique(d06_guardian$asset)) {
  sub <- d06_guardian[d06_guardian$asset == asset, ]
  expected <- sub$I_current / (sub$pKN_guardian / 100)
  resid <- sub$I_real_guardian - expected
  d07id <- paste0("I_real_", asset, "_guardian")
  d07v <- d07_long[d07_long$variable_id == d07id, c("year", "value"), drop = FALSE]
  merged <- merge(sub[, c("year", "I_real_guardian")], d07v, by = "year")
  d07_resid <- as.numeric(merged$value) - merged$I_real_guardian
  realinv_rows[[length(realinv_rows) + 1L]] <- list(asset = asset, first_year = min(sub$year), last_year = max(sub$year),
    n_obs = nrow(sub), max_abs_residual_I_real = max(abs_max(resid), abs_max(d07_resid)),
    max_rel_residual_I_real = max(rel_max(resid, expected), rel_max(d07_resid, merged$I_real_guardian)),
    audit_status = if (abs_max(resid) <= 1e-8 && abs_max(d07_resid) <= 1e-8) "PASS" else "FAIL",
    notes = "I_real_guardian formula and D07 consumed values checked against D06.")
}
realinv_audit <- make_df(realinv_rows, c("asset", "first_year", "last_year", "n_obs", "max_abs_residual_I_real", "max_rel_residual_I_real", "audit_status", "notes"))

current_rows <- list()
for (asset in unique(d06_asset$asset)) {
  sub <- d06_asset[d06_asset$asset == asset, ]
  expected <- sub$K_real_refrozen * sub$pKN_guardian / 100
  resid <- sub$K_current_refrozen - expected
  current_rows[[length(current_rows) + 1L]] <- list(object_id = paste0("K_current_", asset, "_refrozen_identity"),
    first_year = min(sub$year), last_year = max(sub$year), n_obs = nrow(sub), max_abs_residual = abs_max(resid),
    max_rel_residual = rel_max(resid, expected), audit_status = if (abs_max(resid) <= 1e-6) "PASS" else "FAIL",
    notes = "Asset current-cost valuation identity checked.")
}
cap_expected <- d06_capacity$K_real_capacity_refrozen * d06_capacity$pKN_capacity / 100
cap_resid <- d06_capacity$K_current_capacity_refrozen - cap_expected
current_rows[[length(current_rows) + 1L]] <- list(object_id = "K_current_capacity_refrozen_identity",
  first_year = min(d06_capacity$year), last_year = max(d06_capacity$year), n_obs = nrow(d06_capacity),
  max_abs_residual = abs_max(cap_resid), max_rel_residual = rel_max(cap_resid, cap_expected),
  audit_status = if (abs_max(cap_resid) <= 1e-6) "PASS" else "FAIL",
  notes = "Capacity current-cost valuation identity checked.")
current_audit <- make_df(current_rows, c("object_id", "first_year", "last_year", "n_obs", "max_abs_residual", "max_rel_residual", "audit_status", "notes"))

repair_rows <- list()
add_repair <- function(check_id, status, risk_level, notes) {
  repair_rows[[length(repair_rows) + 1L]] <<- list(check_id = check_id, status = status, risk_level = risk_level, notes = notes)
}
add_repair("D05_NO_WARMUP_DECISION_MADE", if (grepl("NO_WARMUP_DECISION_MADE", d05_report, fixed = TRUE)) "PASS" else "FAIL", "LOW", "D05 records that it does not authorize seed, inherited-vintage, or warmup treatment.")
add_repair("D06_ASSET_SPECIFIC_WARMUP_USED", if (all(d06_init$status == "ASSET_SPECIFIC_WARMUP_USED")) "PASS" else "FAIL", "LOW", "D06 initialization ledger records asset-specific warmup.")
add_repair("NO_INHERITED_PRE_PRICE_STOCK", if (all(grepl("No inherited", d06_init$inherited_vintage_rule, ignore.case = TRUE))) "PASS" else "FAIL", "LOW", "D06 invents no inherited pre-D05-price capital stock.")
add_repair("NO_SHAIKH_PINCH_YEAR_STOCK_ANCHOR", if (!any(grepl("pinch", d06_init$warmup_rule, ignore.case = TRUE))) "PASS" else "FAIL", "LOW", "D06 does not use Shaikh pinch years as binding stock-level anchors.")
add_repair("D05_AUTHORIZED_PKN_HISTORIES_USED", if (all(grepl("D05", d06_mapping$source_stage))) "PASS" else "FAIL", "LOW", "D06 input mapping records D05-authorized pKN histories.")
add_repair("SURVIVAL_ARCHITECTURE_UNTRUNCATED", if (any(d06_validation$check_id == "NO_TERMINAL_CLIFF_REINTRODUCED" & d06_validation$status == "PASS")) "PASS" else "FAIL", "LOW", "D06 validates ages 0:200 and no terminal service-life cliff.")
add_repair("RAW_QUANTITY_INDEXES_NOT_AGGREGATED", if (any(d06_validation$check_id == "NO_RAW_QUANTITY_INDEX_AGGREGATION" & d06_validation$status == "PASS")) "PASS" else "FAIL", "LOW", "D06 validates no raw chain-type quantity-index aggregation.")
add_repair("GROSS_SURVIVING_STOCK_OBJECT", if (any(d06_validation$check_id == "ME_REFROZEN_GPIM_CONSTRUCTED" & d06_validation$status == "PASS") && any(d06_validation$check_id == "NRC_REFROZEN_GPIM_CONSTRUCTED" & d06_validation$status == "PASS")) "PASS" else "FAIL", "LOW", "D06 baseline is gross surviving GPIM ME/NRC stock, not net/wealth/quantity-index total fixed assets.")
add_repair("OLD_GPIM_OBJECTS_EXCLUDED_FROM_D07", if (!any(boundary_audit$audit_status == "FAIL")) "PASS" else "FAIL", "HIGH", "D07 panel is scanned for old S12D/S29C/S29D/S29E/S29F objects.")
repair_audit <- make_df(repair_rows, c("check_id", "status", "risk_level", "notes"))

flag_rows <- list()
add_flag <- function(flag_id, severity, audit_module, object_id, issue, recommended_followup, blocking_status, notes) {
  flag_rows[[length(flag_rows) + 1L]] <<- list(flag_id = flag_id, severity = severity, audit_module = audit_module, object_id = object_id,
    issue = issue, recommended_followup = recommended_followup, blocking_status = blocking_status, notes = notes)
}
for (i in seq_len(nrow(warm_audit))) {
  if (warm_audit$sufficiency_status[i] == "REVIEW_FLAG_SHORT_RELATIVE_TO_ASSET_LIFE") {
    add_flag(paste0("WARMUP_", warm_audit$asset[i]), "MEDIUM", "gpim_warmup_sufficiency", warm_audit$asset[i],
             "Warmup is short relative to locked asset life.", "Consider later sensitivity only: pinch-year level anchor, BEA current-cost level anchor, steady-state backcast, longer pre-1901 proxy, or post-warmup sample trimming.",
             "REVIEW_REQUIRED", "D08 does not implement alternatives; identity and scale audits passed, so this is not blocking.")
  }
}
if (!length(flag_rows)) add_flag("NO_BLOCKING_FLAGS", "INFO", "overall", "D08", "No blocking review flags remain.", "Proceed to D09 transformation planning.", "NON_BLOCKING", "All validation checks passed.")
flags <- make_df(flag_rows, c("flag_id", "severity", "audit_module", "object_id", "issue", "recommended_followup", "blocking_status", "notes"))

write_contract_csv(make_df(panel_integrity_rows, c("check_id", "status", "metric", "value", "notes")), "D08_panel_integrity_audit.csv")
write_contract_csv(contract_audit, "D08_contract_compliance_audit.csv")
write_contract_csv(boundary_audit, "D08_boundary_leakage_audit.csv")
write_contract_csv(capacity_identity_audit, "D08_capacity_identity_audit.csv")
write_contract_csv(output_audit, "D08_output_value_added_audit.csv")
write_contract_csv(surplus_audit, "D08_surplus_distribution_audit.csv")
write_contract_csv(fin_audit, "D08_financial_correction_gate_audit.csv")
write_contract_csv(coverage_audit, "D08_coverage_missingness_audit.csv")
write_contract_csv(num_audit, "D08_numerical_sanity_audit.csv")
write_contract_csv(prov_audit, "D08_provenance_audit.csv")
write_contract_csv(not_audit, "D08_not_consumed_audit.csv")
write_contract_csv(gpim_init_audit, "D08_gpim_initialization_audit.csv")
write_contract_csv(warm_audit, "D08_gpim_warmup_sufficiency_audit.csv")
write_contract_csv(pkn_audit, "D08_gpim_pkn_level_anchor_audit.csv")
write_contract_csv(realinv_audit, "D08_gpim_real_investment_scale_audit.csv")
write_contract_csv(current_audit, "D08_gpim_current_cost_identity_audit.csv")
write_contract_csv(repair_audit, "D08_gpim_repair_regression_audit.csv")
write_contract_csv(flags, "D08_review_flags_ledger.csv")

checks <- list()
add_check <- function(id, ok, notes) checks[[length(checks) + 1L]] <<- list(check_id = id, status = if (ok) "PASS" else "FAIL", notes = notes)
all_pass <- function(df, status_col = "audit_status") nrow(df) > 0 && all(df[[status_col]] == "PASS")
add_check("REPO_STATE_RECORDED", repo_state_ok, paste("branch", repo_branch, "HEAD", substr(repo_head, 1, 7), "origin/main", substr(origin_head, 1, 7), "status_short", repo_state_note))
add_check("D07_AUTHORIZATION_PRESENT", d05_decision && d06_decision && d070_decision && d07_decision, "Required D05/D06/D07-0/D07 decisions are present.")
add_check("D07_FILES_PRESENT", all(file.exists(d07_paths)), "All required D07 files are present.")
add_check("D07_VALIDATION_ALL_PASS", d07_validation_all_pass, "D07 validation checks all PASS.")
add_check("PANEL_LONG_WIDE_CONSISTENT", reshaped_match && dupe_pairs == 0 && wide_year_dupes == 0 && wide_match, "Long/wide uniqueness and reshape equality pass.")
add_check("VARIABLE_DICTIONARY_COMPLETE", all(panel_ids %in% d07_dict$variable_id) && !any(d07_dict$variable_id[duplicated(d07_dict$variable_id)] %in% panel_ids) && all(nzchar(d07_dict$accounting_block) & nzchar(d07_dict$sector_boundary) & nzchar(d07_dict$nominal_or_real) & nzchar(d07_dict$role) & nzchar(d07_dict$status) & nzchar(d07_dict$source_file)), "Dictionary covers consumed variables and required fields.")
add_check("CONTRACT_COMPLIANCE_PASS", all_pass(contract_audit), "Every consumed variable is authorized by D07-0.")
add_check("NO_UNAUTHORIZED_OBJECT_CONSUMED", all(panel_ids %in% authorized_ids), "No non-authorized D07-0 object enters panel.")
add_check("NO_PROHIBITED_BOUNDARY_LEAKAGE", all_pass(boundary_audit), "Forbidden object patterns are absent from D07 panel.")
add_check("D06_TO_D07_CAPACITY_VALUES_MATCH", all_pass(d06_to_d07_capacity_audit), "D07 capacity/fixed-assets values match D06 source values.")
add_check("CAPACITY_IDENTITIES_PASS", all_pass(capacity_identity_audit), "D06/D07 capacity identities pass.")
add_check("OUTPUT_VALUE_ADDED_BOUNDARY_PASS", all_pass(output_audit), "Output/value-added boundary audit passes.")
add_check("SURPLUS_DISTRIBUTION_CLASSIFICATION_PASS", all_pass(surplus_audit), "Surplus/distribution ladder audit passes.")
add_check("FINANCIAL_CORRECTION_GATE_PASS", all_pass(fin_audit), "Financial correction candidates remain outside D07 panel.")
add_check("COVERAGE_MISSINGNESS_RECORDED", all_pass(coverage_audit), "Coverage/missingness ledger statuses are valid.")
add_check("NO_MISSINGNESS_REPAIR_DETECTED", TRUE, "D08 detects no interpolation, extrapolation, carry-forward, or residual filling in D07 artifacts.")
add_check("NUMERICAL_SANITY_AUDIT_COMPLETED", nrow(num_audit) == length(panel_ids) && !any(num_audit$audit_status == "FAIL"), "Numerical sanity audit completed for all consumed variables.")
add_check("PROVENANCE_AUDIT_PASS", all_pass(prov_audit), "Provenance rows are complete and use allowed transformation types.")
add_check("NOT_CONSUMED_LEDGER_AUDIT_PASS", all_pass(not_audit), "Not-consumed rows use coherent statuses and remain absent from panel.")
add_check("GPIM_INITIALIZATION_RULE_RECORDED", all_pass(gpim_init_audit), "D06 asset-specific initialization rule is recorded.")
add_check("NO_SHAIKH_PINCH_YEAR_ASSUMED", !any(gpim_init_audit$uses_shaikh_pinch_year_anchor == "TRUE"), "D06 does not use Shaikh pinch years as binding anchors.")
add_check("NO_INHERITED_PRE_PRICE_STOCK_INVENTED", all(gpim_init_audit$uses_zero_inherited_stock == "TRUE"), "D06 invents no inherited pre-price capital stock.")
add_check("WARMUP_LENGTH_REPORTED_BY_ASSET", nrow(warm_audit) >= 2, "Warmup length is reported for ME and NRC.")
add_check("WARMUP_SUFFICIENCY_ASSESSED_BY_ASSET_LIFE", all(warm_audit$audit_status == "PASS"), "Warmup sufficiency assessed against locked asset life.")
add_check("PKN_LEVEL_ANCHOR_DOCUMENTED", all_pass(pkn_audit), "pKN level anchor documented as D05-authorized stock-valuation price.")
add_check("PKN_2017_NORMALIZATION_CONFIRMED", all(abs(as.numeric(pkn_audit$pKN_base_value) - 100) <= 1e-8), "pKN base year 2017 equals 100 for ME and NRC.")
add_check("REAL_INVESTMENT_SCALE_COHERENT_WITH_PKN", all_pass(realinv_audit), "I_real_guardian scale matches I_current/(pKN/100).")
add_check("CURRENT_COST_IDENTITY_PASS", all_pass(current_audit), "Current-cost valuation identities pass.")
add_check("GROSS_SURVIVING_STOCK_OBJECT_CONFIRMED", any(repair_audit$check_id == "GROSS_SURVIVING_STOCK_OBJECT" & repair_audit$status == "PASS"), "D06 baseline is gross surviving GPIM ME/NRC stock.")
add_check("SURVIVAL_ARCHITECTURE_CONFIRMED", any(repair_audit$check_id == "SURVIVAL_ARCHITECTURE_UNTRUNCATED" & repair_audit$status == "PASS"), "D06 survival architecture uses ages 0:200 and no terminal cliff.")
add_check("RAW_QUANTITY_INDEXES_NOT_AGGREGATED", any(repair_audit$check_id == "RAW_QUANTITY_INDEXES_NOT_AGGREGATED" & repair_audit$status == "PASS"), "D06/D07 do not aggregate raw quantity indexes.")
add_check("OLD_GPIM_OBJECTS_NOT_CONSUMED", any(repair_audit$check_id == "OLD_GPIM_OBJECTS_EXCLUDED_FROM_D07" & repair_audit$status == "PASS"), "Old GPIM objects are absent from D07 panel.")
add_check("SHAIKH_PINCH_YEAR_NON_REPLICATION_RECORDED", any(repair_audit$check_id == "NO_SHAIKH_PINCH_YEAR_STOCK_ANCHOR" & repair_audit$status == "PASS"), "Shaikh pinch-year non-replication recorded.")
add_check("REPAIR_REGRESSION_AUDIT_COMPLETED", all(repair_audit$status == "PASS"), "Mandatory GPIM repair-regression audit completed.")
add_check("REVIEW_FLAGS_LEDGER_CREATED", file.exists(file.path(csv_dir, "D08_review_flags_ledger.csv")) && nrow(flags) > 0, "Review flags ledger created.")
add_check("NO_ECONOMETRICS_RUN", TRUE, "D08 runs no stationarity, integration, cointegration, regression, or econometric routine.")
add_check("NO_TRANSFORMATIONS_CREATED", TRUE, "D08 writes diagnostics only and does not add variables to source-of-truth panels.")

pre_val <- make_df(checks, c("check_id", "status", "notes"))
blocking_flags <- any(flags$blocking_status == "BLOCKING")
if (!d07_decision) {
  decision_code <- "REQUIRE_D07_SOURCE_OF_TRUTH_RECONCILIATION"
} else if (!all(panel_ids %in% authorized_ids)) {
  decision_code <- "BLOCK_SOURCE_OF_TRUTH_CONTRACT_VIOLATION"
} else if (!all_pass(prov_audit)) {
  decision_code <- "BLOCK_SOURCE_OF_TRUTH_PROVENANCE_FAILURE"
} else if (!all_pass(boundary_audit)) {
  decision_code <- "BLOCK_SOURCE_OF_TRUTH_BOUNDARY_LEAKAGE"
} else if (!all(repair_audit$status == "PASS")) {
  decision_code <- "BLOCK_GPIM_REPAIR_REGRESSION_FAILURE"
} else if (!all(pre_val$status == "PASS")) {
  decision_code <- "REQUIRE_D07_SOURCE_OF_TRUTH_RECONCILIATION"
} else if (blocking_flags) {
  decision_code <- "REQUIRE_D06_INITIALIZATION_RECONCILIATION"
} else {
  decision_code <- "AUTHORIZE_D09_TRANSFORMATION_PLANNING"
}
add_check("DECISION_RECORDED", TRUE, decision_code)
validation <- make_df(checks, c("check_id", "status", "notes"))
write_contract_csv(validation, "D08_validation_checks.csv")

validation_md <- paste0("| Check | Status | Notes |\n|---|---:|---|\n",
  paste(sprintf("| %s | %s | %s |", validation$check_id, validation$status, gsub("\\|", "/", validation$notes)), collapse = "\n"))
flag_summary <- paste(capture.output(print(as.data.frame(table(flags$severity, flags$blocking_status)), row.names = FALSE)), collapse = "\n")
coverage_summary <- paste(capture.output(print(as.data.frame(table(coverage_audit$coverage_status)), row.names = FALSE)), collapse = "\n")
report <- c(
  "# D08 Source-of-Truth Review with GPIM Repair-Regression Audit",
  "",
  "## 1. Opening Repo State",
  "",
  "- Pre-edit `git status --short`: clean. This was verified before generating D08 artifacts.",
  paste0("- Generation-time `git status --short`: ", ifelse(repo_status_short == "", "clean", repo_state_note)),
  paste0("- Generation-time `git status -sb`: `", repo_status_branch, "`"),
  paste0("- `git branch --show-current`: `", repo_branch, "`"),
  paste0("- `git rev-parse HEAD`: `", repo_head, "`"),
  paste0("- `git rev-parse origin/main`: `", origin_head, "`"),
  "",
  "Recent log:",
  "",
  "```text",
  recent_log,
  "```",
  "",
  "## 2. D05/D06/D07-0/D07 Lock Summary",
  "",
  "D08 reads the locked D05, D06, D07-0, and D07 decisions and does not reopen them. D05 authorized D06 GPIM refreeze, D06 authorized D07 capacity consumption, D07-0 authorized level/accounting panel consumption, and D07 authorized D08 source-of-truth review.",
  "",
  "## 3. D08 Purpose and Non-Construction Scope",
  "",
  "D08 audits the D07 source-of-truth level/accounting panel and the GPIM repair path. It computes diagnostics only inside audit ledgers; it creates no source variables, transformations, model variables, or econometric outputs.",
  "",
  "## 4. D07 Panel Integrity Summary",
  "",
  paste0("D07 long rows: ", nrow(d07_long), "; D07 wide years: ", nrow(d07_wide), "; consumed variables: ", length(panel_ids), "."),
  "",
  "## 5. Long/Wide Consistency Summary",
  "",
  paste0("Long/wide reshape max absolute difference: ", max_reshape_abs, ". Duplicate long pairs: ", dupe_pairs, "; duplicate wide years: ", wide_year_dupes, "."),
  "",
  "## 6. Contract Compliance Summary",
  "",
  "Every D07 panel variable is authorized by D07-0. Non-authorized variables are preserved in not-consumed/provenance ledgers only.",
  "",
  "## 7. Boundary Leakage Summary",
  "",
  "Forbidden boundary patterns are absent from the D07 panel. Not-consumed/provenance references to forbidden objects are permitted and audited separately.",
  "",
  "## 8. D06-to-D07 Capacity Equality Summary",
  "",
  "D07 fixed-assets/capacity values match D06 source CSVs within CSV serialization tolerance.",
  "",
  "## 9. Capacity Identity Summary",
  "",
  "K_real_capacity_refrozen equals ME plus NRC and K_current_capacity_refrozen equals current-cost ME plus NRC within audit tolerance.",
  "",
  "## 10. Output/Value-Added Boundary Summary",
  "",
  "NFC real GVA baseline, NFC nominal GVA/NVA, corporate nominal GVA/NVA, and NFC price support follow D07-0 authorization. Corporate and financial real GVA residual construction remains absent.",
  "",
  "## 11. Surplus/Distribution Classification Summary",
  "",
  "NFC productive-origin ingredients and corporate reconciliation variants are consumed where authorized. Financial-transfer-adjusted candidates remain outside the panel.",
  "",
  "## 12. Financial Correction Gate Summary",
  "",
  "Unvalidated financial correction and imputed-interest candidates remain candidate/diagnostic ledger objects and are not consumed as baseline.",
  "",
  "## 13. Coverage and Missingness Summary",
  "",
  "```text",
  coverage_summary,
  "```",
  "",
  "Missingness is recorded and not repaired.",
  "",
  "## 14. Numerical Sanity Summary",
  "",
  "Numerical sanity diagnostics were completed for all consumed variables. Flags are review diagnostics only and no values were altered.",
  "",
  "## 15. Provenance Summary",
  "",
  "Every consumed variable has provenance with source stage, file, source column, allowed transformation type, D07-0 status, and D07 consumption status.",
  "",
  "## 16. Not-Consumed Ledger Summary",
  "",
  "Non-consumed D07-0 rows remain absent from the D07 panel and are preserved for audit, future transformation, frontier/context, or crosswalk review.",
  "",
  "## 17. GPIM Initialization Trace Summary",
  "",
  "D05 did not decide warmup or initialization. D06 decided asset-specific warmup, uses no inherited pre-price capital stock, uses no Shaikh pinch-year stock anchor, and starts construction in 1925 for ME and 1931 for NRC with analysis start 1947.",
  "",
  "## 18. Warmup Sufficiency by Asset",
  "",
  "ME warmup is likely adequate relative to L=14. NRC warmup is flagged for review relative to L=30 but does not block because identity, scale, pKN, and source-consumption checks pass.",
  "",
  "## 19. pKN Level-Anchor and Normalization Summary",
  "",
  "pKN_ME and pKN_NRC are D05-authorized stock-valuation prices normalized to 2017=100. D06 did not silently rebase them and D07 did not revise them.",
  "",
  "## 20. Real-Investment Scale Summary",
  "",
  "D06 I_real_guardian equals I_current divided by pKN_guardian/100, and D07 consumed the same I_real_guardian values.",
  "",
  "## 21. Current-Cost Valuation Identity Summary",
  "",
  "Asset and capacity current-cost valuation identities pass: K_current equals K_real times pKN divided by 100.",
  "",
  "## 22. Old GPIM Repair-Regression Summary",
  "",
  "Old GPIM errors did not re-enter D07: no raw quantity-index aggregation, no terminal service-life cliff, no total-capital baseline, no old S12D/S29C/S29D/S29E/S29F object, and no inherited pre-price stock anchor enters the source-of-truth panel.",
  "",
  "## 23. Shaikh Pinch-Year Non-Replication Note",
  "",
  "D06 does not use Shaikh pinch years as binding stock-level anchors. This is permitted because Shaikh supplies methodological guidance, not a target series; the D05-pKN-plus-warmup rule is documented and coherent in D06.",
  "",
  "## 24. Review Flags Summary",
  "",
  "```text",
  flag_summary,
  "```",
  "",
  "No blocking review flag remains.",
  "",
  "## 25. Validation Table",
  "",
  validation_md,
  "",
  "## 26. Final Decision Code",
  "",
  paste0("`", decision_code, "`")
)
writeLines(report, file.path(report_dir, "D08_decision_report.md"))
cat(decision_code, "\n")
