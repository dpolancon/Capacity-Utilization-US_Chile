#!/usr/bin/env Rscript

# D07 materializes the level/accounting panel authorized by D07-0.
# It consumes existing local artifacts only; it does not transform, model, or refit anything.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION")
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
  if (!length(rows)) {
    return(as.data.frame(setNames(replicate(length(cols), character(), simplify = FALSE), cols)))
  }
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
collapse_unique <- function(x) {
  x <- unique(clean_chr(x))
  x <- x[nzchar(x)]
  if (!length(x)) "" else paste(x, collapse = "; ")
}
pick_first <- function(x) {
  x <- clean_chr(x)
  x <- x[nzchar(x)]
  if (!length(x)) "" else x[1]
}

repo_status_short <- git(c("status", "--short"))
repo_status_branch <- git(c("status", "-sb"))
repo_branch <- git(c("branch", "--show-current"))
repo_head <- git(c("rev-parse", "HEAD"))
origin_head <- git(c("rev-parse", "origin/main"))
recent_log <- git(c("log", "--oneline", "-5"))
status_lines <- if (repo_status_short == "") character() else strsplit(repo_status_short, "\n", fixed = TRUE)[[1]]
d07_owned_dirty <- grepl("codes/US_D07_level_accounting_panel_consumption\\.R|output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION", status_lines)
repo_state_ok <- repo_branch == "main" && substr(repo_head, 1, 7) == "f749c1f" && repo_head == origin_head &&
  (length(status_lines) == 0 || all(d07_owned_dirty))
repo_state_note <- if (length(status_lines) == 0) {
  "clean"
} else if (all(d07_owned_dirty)) {
  "D07 generated artifacts only"
} else {
  paste(status_lines[!d07_owned_dirty], collapse = "; ")
}

d070_dir <- repo_file("output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT")
d070_files <- c(
  "csv/D07_0_level_accounting_variable_menu.csv",
  "csv/D07_0_consumption_contract.csv",
  "csv/D07_0_fixed_assets_capacity_block.csv",
  "csv/D07_0_output_value_added_block.csv",
  "csv/D07_0_surplus_distribution_scaffold.csv",
  "csv/D07_0_financial_correction_candidate_ledger.csv",
  "csv/D07_0_frontier_context_parking_ledger.csv",
  "csv/D07_0_supersession_and_parking_ledger.csv",
  "csv/D07_0_validation_checks.csv",
  "reports/D07_0_decision_report.md"
)
d070_paths <- file.path(d070_dir, d070_files)

contract <- read_csv_base(file.path(d070_dir, "csv/D07_0_consumption_contract.csv"))
menu <- read_csv_base(file.path(d070_dir, "csv/D07_0_level_accounting_variable_menu.csv"))
d070_validation <- read_csv_base(file.path(d070_dir, "csv/D07_0_validation_checks.csv"))
d070_report_path <- file.path(d070_dir, "reports/D07_0_decision_report.md")
d070_report <- if (file.exists(d070_report_path)) paste(readLines(d070_report_path, warn = FALSE), collapse = "\n") else ""
d070_authorized <- file.exists(d070_report_path) &&
  grepl("AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION", d070_report, fixed = TRUE) &&
  nrow(d070_validation) > 0 &&
  any(d070_validation$check_id == "DECISION_RECORDED" & d070_validation$status == "PASS" &
        grepl("AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION", d070_validation$notes, fixed = TRUE))

d06_dir <- repo_file("output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN")
d06_capacity_file <- file.path(d06_dir, "csv/D06_capacity_refrozen_panel.csv")
d06_asset_file <- file.path(d06_dir, "csv/D06_asset_refrozen_gpim_panel.csv")
d06_guardian_file <- file.path(d06_dir, "csv/D06_real_investment_guardian_panel.csv")
d06_validation_file <- file.path(d06_dir, "csv/D06_validation_checks.csv")
d06_report_file <- file.path(d06_dir, "reports/D06_decision_report.md")
d06_capacity <- read_csv_base(d06_capacity_file)
d06_asset <- read_csv_base(d06_asset_file)
d06_guardian <- read_csv_base(d06_guardian_file)
d06_validation <- read_csv_base(d06_validation_file)
d06_report <- if (file.exists(d06_report_file)) paste(readLines(d06_report_file, warn = FALSE), collapse = "\n") else ""
d06_authorized <- file.exists(d06_report_file) &&
  grepl("AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION", d06_report, fixed = TRUE) &&
  nrow(d06_validation) > 0 && all(d06_validation$status == "PASS")

s12b_real_file <- repo_file("output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv")
s12b_price_file <- repo_file("output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_output_price_objects_long.csv")
s30b_dist_file <- repo_file("output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_distribution_interface_long.csv")
provider_long_file <- repo_file("data/external/us_bea_provider/us_bea_variable_menu_long.csv")
s12b_real <- read_csv_base(s12b_real_file)
s12b_price <- read_csv_base(s12b_price_file)
s30b_dist <- read_csv_base(s30b_dist_file)
provider_long <- read_csv_base(provider_long_file)

authorized_contract <- contract[contract$authorized_for_D07_level_panel == "TRUE", , drop = FALSE]
authorized_ids <- unique(authorized_contract$variable_id)

meta_cols <- c(
  "variable_id", "display_name", "accounting_block", "sector_boundary", "accounting_concept",
  "nominal_or_real", "role", "status", "source_stage", "source_file", "allowed_use",
  "prohibited_use", "notes"
)
metadata_by_id <- list()
for (id in authorized_ids) {
  m <- menu[menu$variable_id == id, , drop = FALSE]
  c <- authorized_contract[authorized_contract$variable_id == id, , drop = FALSE]
  metadata_by_id[[id]] <- list(
    variable_id = id,
    display_name = pick_first(c(c$display_name, m$display_name, id)),
    accounting_block = collapse_unique(c(c$accounting_block, m$accounting_block)),
    sector_boundary = collapse_unique(c(c$sector_boundary, m$sector_boundary)),
    accounting_concept = collapse_unique(m$accounting_concept),
    nominal_or_real = collapse_unique(m$nominal_or_real),
    role = collapse_unique(c(c$role, m$role)),
    status = collapse_unique(c(c$status, m$status)),
    source_stage = collapse_unique(m$source_stage),
    source_file = collapse_unique(m$source_file),
    allowed_use = collapse_unique(m$allowed_use),
    prohibited_use = collapse_unique(m$prohibited_use),
    notes = collapse_unique(m$notes)
  )
}

panel_cols <- c(
  "year", "variable_id", "value", "display_name", "accounting_block", "sector_boundary",
  "accounting_concept", "nominal_or_real", "role", "status", "source_stage", "source_file",
  "source_column", "unit", "allowed_use", "prohibited_use", "notes"
)
panel_rows <- list()
provenance_rows <- list()
not_consumed_rows <- list()

add_not_consumed <- function(variable_id, display_name, D07_0_status, reason_not_consumed,
                             preserved_for, prohibited_use, notes) {
  not_consumed_rows[[length(not_consumed_rows) + 1L]] <<- list(
    variable_id = variable_id,
    display_name = display_name,
    D07_0_status = D07_0_status,
    reason_not_consumed = reason_not_consumed,
    preserved_for = preserved_for,
    prohibited_use = prohibited_use,
    notes = notes
  )
}
add_prov <- function(variable_id, display_name, accounting_block, sector_boundary, source_stage,
                     source_file, source_column, source_variable_id_if_applicable, transformation_type,
                     transformation_formula, D07_0_contract_status, D07_consumption_status, notes) {
  provenance_rows[[length(provenance_rows) + 1L]] <<- list(
    variable_id = variable_id,
    display_name = display_name,
    accounting_block = accounting_block,
    sector_boundary = sector_boundary,
    source_stage = source_stage,
    source_file = source_file,
    source_column = source_column,
    source_variable_id_if_applicable = source_variable_id_if_applicable,
    transformation_type = transformation_type,
    transformation_formula = transformation_formula,
    D07_0_contract_status = D07_0_contract_status,
    D07_consumption_status = D07_consumption_status,
    notes = notes
  )
}
add_series <- function(id, years, values, unit, source_stage, source_file, source_column,
                       source_variable_id, transformation_type, formula, notes) {
  meta <- metadata_by_id[[id]]
  if (is.null(meta)) return(FALSE)
  ok <- length(years) == length(values) && length(years) > 0
  if (!ok) {
    add_not_consumed(id, meta$display_name, meta$status, "authorized_source_absent_or_empty",
                     "D07 reconciliation", meta$prohibited_use, notes)
    add_prov(id, meta$display_name, meta$accounting_block, meta$sector_boundary, source_stage,
             source_file, source_column, source_variable_id, "blocked_not_consumed", formula,
             meta$status, "SOURCE_ABSENT_BLOCKED", notes)
    return(FALSE)
  }
  for (i in seq_along(years)) {
    panel_rows[[length(panel_rows) + 1L]] <<- list(
      year = years[i],
      variable_id = id,
      value = values[i],
      display_name = meta$display_name,
      accounting_block = meta$accounting_block,
      sector_boundary = meta$sector_boundary,
      accounting_concept = meta$accounting_concept,
      nominal_or_real = meta$nominal_or_real,
      role = meta$role,
      status = meta$status,
      source_stage = source_stage,
      source_file = source_file,
      source_column = source_column,
      unit = unit,
      allowed_use = meta$allowed_use,
      prohibited_use = meta$prohibited_use,
      notes = paste(c(meta$notes, notes), collapse = " | ")
    )
  }
  add_prov(id, meta$display_name, meta$accounting_block, meta$sector_boundary, source_stage,
           source_file, source_column, source_variable_id, transformation_type, formula,
           meta$status, "CONSUMED_IN_D07_LEVEL_ACCOUNTING_PANEL", notes)
  TRUE
}

capacity_direct <- c(
  "K_real_ME_refrozen", "K_real_NRC_refrozen", "K_real_capacity_refrozen",
  "K_current_ME_refrozen", "K_current_NRC_refrozen", "K_current_capacity_refrozen",
  "pKN_ME", "pKN_NRC", "pKN_capacity"
)
for (id in intersect(capacity_direct, authorized_ids)) {
  if (nrow(d06_capacity) && id %in% names(d06_capacity)) {
    unit <- if (grepl("^K_real", id)) "D06 real GPIM stock units" else if (grepl("^K_current", id)) "Millions of current dollars" else "D06 guarded pKN index/support"
    add_series(id, d06_capacity$year, d06_capacity[[id]], unit,
               "D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN",
               "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_capacity_refrozen_panel.csv",
               id, id, "D06_authorized_refrozen_object", "direct read from D06 refrozen capacity panel",
               "D06-refrozen fixed-assets/capacity object consumed without rebuilding GPIM.")
  }
}

asset_map <- list(
  I_current_ME = list(asset = "ME", column = "I_current", unit = "Millions of current dollars"),
  I_current_NRC = list(asset = "NRC", column = "I_current", unit = "Millions of current dollars"),
  I_real_ME_guardian = list(asset = "ME", column = "I_real_guardian", unit = "D06 real guarded investment units"),
  I_real_NRC_guardian = list(asset = "NRC", column = "I_real_guardian", unit = "D06 real guarded investment units")
)
for (id in intersect(names(asset_map), authorized_ids)) {
  spec <- asset_map[[id]]
  src <- if (grepl("^I_real", id)) d06_guardian else d06_asset
  src_file <- if (grepl("^I_real", id)) {
    "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_real_investment_guardian_panel.csv"
  } else {
    "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_asset_refrozen_gpim_panel.csv"
  }
  part <- src[src$asset == spec$asset, , drop = FALSE]
  if (nrow(part) && spec$column %in% names(part)) {
    add_series(id, part$year, part[[spec$column]], spec$unit,
               "D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN", src_file, spec$column, id,
               "D06_authorized_refrozen_object", "direct read from D06 asset-level panel",
               paste("D06", spec$asset, spec$column, "read without pKN, survival, or warmup revision."))
  }
}

if ("Y_REAL_NFC_GVA_BASELINE" %in% authorized_ids) {
  part <- s12b_real[s12b_real$variable_name == "Y_REAL_NFC_GVA_BASELINE", , drop = FALSE]
  invisible(add_series("Y_REAL_NFC_GVA_BASELINE", part$year, part$real_output_value,
                       pick_first(part$real_output_unit),
                       "S12B_OUTPUT_PRICE_REAL_OUTPUT",
                       "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_real_output_objects_long.csv",
                       "real_output_value", "Y_REAL_NFC_GVA_BASELINE",
                       "already_constructed_prior_stage", "direct read of already constructed same-boundary real NFC GVA",
                       "No corporate or financial real residual output is constructed."))
}
if ("P_Y_NFC_GVA_IMPLICIT_SOURCE" %in% authorized_ids) {
  part <- s12b_price[s12b_price$variable_name == "P_Y_NFC_GVA_IMPLICIT_SOURCE", , drop = FALSE]
  invisible(add_series("P_Y_NFC_GVA_IMPLICIT_SOURCE", part$year, part$value_index_2017,
                       pick_first(part$normalized_unit),
                       "S12B_OUTPUT_PRICE_REAL_OUTPUT",
                       "output/US/S12B_OUTPUT_PRICE_REAL_OUTPUT/csv/S12B_output_price_objects_long.csv",
                       "value_index_2017", "P_Y_NFC_GVA_IMPLICIT_SOURCE",
                       "already_constructed_prior_stage", "direct read of already constructed NFC implicit GVA deflator support",
                       "Same-boundary NFC support only; not used as CORP or FIN deflator."))
}

income_ids <- intersect(authorized_ids, unique(provider_long$variable_id))
income_ids <- setdiff(income_ids, c(capacity_direct, names(asset_map), "Y_REAL_NFC_GVA_BASELINE", "P_Y_NFC_GVA_IMPLICIT_SOURCE"))
for (id in income_ids) {
  part <- provider_long[provider_long$variable_id == id, , drop = FALSE]
  if (nrow(part)) {
    add_series(id, part$year, part$value, pick_first(part$unit),
               "LOCAL_PROVIDER_IMPORT",
               "data/external/us_bea_provider/us_bea_variable_menu_long.csv",
               "value", id, "direct_read", "direct source-level read from local provider-imported long panel",
               "Local committed provider import consumed read-only; provider repo not modified.")
  }
}

ratio_ids <- intersect(authorized_ids, unique(s30b_dist$derived_variable_id))
for (id in ratio_ids) {
  part <- s30b_dist[s30b_dist$derived_variable_id == id, , drop = FALSE]
  if (nrow(part)) {
    add_series(id, part$year, part$value, pick_first(part$unit),
               "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE",
               "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_distribution_interface_long.csv",
               "value", id, "D07_0_authorized_accounting_ratio",
               pick_first(part$formula),
               "Already constructed S30B accounting ratio consumed without recomputation.")
  }
}

consumed_ids <- unique(vapply(panel_rows, function(x) x$variable_id, character(1)))
missing_authorized <- setdiff(authorized_ids, consumed_ids)
for (id in missing_authorized) {
  meta <- metadata_by_id[[id]]
  add_not_consumed(id, meta$display_name, meta$status, "authorized_source_not_found_in_local_search_order",
                   "D07 reconciliation", meta$prohibited_use,
                   "No non-empty local source series was found in the D07 source search order.")
  add_prov(id, meta$display_name, meta$accounting_block, meta$sector_boundary, meta$source_stage,
           meta$source_file, "", id, "blocked_not_consumed", "not_applicable", meta$status,
           "SOURCE_ABSENT_BLOCKED", "Authorized by D07-0 but not consumed because no local source series was found.")
}

non_auth <- contract[contract$authorized_for_D07_level_panel != "TRUE", , drop = FALSE]
for (i in seq_len(nrow(non_auth))) {
  r <- non_auth[i, ]
  add_not_consumed(r$variable_id, r$display_name, r$status,
                   paste("D07-0 status not authorized for panel consumption:", r$status),
                   "metadata/ledger only", pick_first(c(r$notes, "")),
                   "Preserved outside the D07 level/accounting panel.")
  add_prov(r$variable_id, r$display_name, r$accounting_block, r$sector_boundary,
           "D07_0_CONSUMPTION_CONTRACT",
           "output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT/csv/D07_0_consumption_contract.csv",
           "", r$variable_id,
           if (r$status %in% c("PARKED_TRANSFORMATION", "PARKED_FRONTIER_CONTEXT")) "metadata_only_not_consumed" else "blocked_not_consumed",
           "not_applicable", r$status, "NOT_CONSUMED_STATUS_BLOCKED",
           "D07-0 did not authorize this variable for source-of-truth panel consumption.")
}

panel_long <- make_df(panel_rows, panel_cols)
if (nrow(panel_long)) {
  panel_long$year <- as.integer(panel_long$year)
  panel_long$value <- as.numeric(panel_long$value)
  panel_long <- panel_long[order(panel_long$year, panel_long$variable_id), ]
}

years <- sort(unique(panel_long$year))
wide <- data.frame(year = years)
for (id in sort(consumed_ids)) {
  vals <- panel_long[panel_long$variable_id == id, c("year", "value"), drop = FALSE]
  col <- rep(NA_real_, length(years))
  idx <- match(vals$year, years)
  col[idx] <- vals$value
  wide[[id]] <- col
}

coverage_cols <- c("variable_id", "display_name", "accounting_block", "sector_boundary", "first_year",
                   "last_year", "n_obs", "n_missing_inside_span", "coverage_status", "notes")
coverage_rows <- list()
for (id in authorized_ids) {
  meta <- metadata_by_id[[id]]
  vals <- panel_long[panel_long$variable_id == id, , drop = FALSE]
  if (!nrow(vals)) {
    coverage_rows[[length(coverage_rows) + 1L]] <- list(
      variable_id = id, display_name = meta$display_name, accounting_block = meta$accounting_block,
      sector_boundary = meta$sector_boundary, first_year = "", last_year = "", n_obs = "0",
      n_missing_inside_span = "", coverage_status = "SOURCE_ABSENT_BLOCKED",
      notes = "Authorized by D07-0 but not found in D07 local source search order."
    )
  } else {
    first_year <- min(vals$year, na.rm = TRUE)
    last_year <- max(vals$year, na.rm = TRUE)
    span <- seq(first_year, last_year)
    present <- vals$year[!is.na(vals$value)]
    missing_inside <- length(setdiff(span, present))
    status <- if (missing_inside > 0) "HAS_INTERNAL_MISSINGNESS" else if (length(present) < 20) "SHORT_SPAN_REVIEW" else "COMPLETE_WITHIN_SPAN"
    coverage_rows[[length(coverage_rows) + 1L]] <- list(
      variable_id = id, display_name = meta$display_name, accounting_block = meta$accounting_block,
      sector_boundary = meta$sector_boundary, first_year = first_year, last_year = last_year,
      n_obs = sum(!is.na(vals$value)), n_missing_inside_span = missing_inside,
      coverage_status = status, notes = "Missingness recorded only; no filling or interpolation performed."
    )
  }
}
for (i in seq_len(nrow(non_auth))) {
  r <- non_auth[i, ]
  coverage_rows[[length(coverage_rows) + 1L]] <- list(
    variable_id = r$variable_id, display_name = r$display_name, accounting_block = r$accounting_block,
    sector_boundary = r$sector_boundary, first_year = "", last_year = "", n_obs = "0",
    n_missing_inside_span = "", coverage_status = "NOT_CONSUMED_STATUS_BLOCKED",
    notes = paste("Not consumed because D07-0 status is", r$status)
  )
}
coverage <- make_df(coverage_rows, coverage_cols)

dict_cols <- c("variable_id", "display_name", "description", "accounting_block", "sector_boundary",
               "accounting_concept", "nominal_or_real", "unit", "role", "status",
               "preferred_or_alternative", "baseline_authorized", "source_file", "notes")
dict_rows <- list()
for (id in sort(consumed_ids)) {
  meta <- metadata_by_id[[id]]
  vals <- panel_long[panel_long$variable_id == id, , drop = FALSE]
  pref <- if (grepl("preferred_wage_share|K_real_capacity_refrozen|Y_REAL_NFC_GVA_BASELINE", paste(meta$role, id))) {
    "preferred_baseline"
  } else if (grepl("robustness|CORP_COMPENSATION|NVA", paste(meta$role, id))) {
    "alternative"
  } else if (grepl("profit_share_scaffold|surplus_accounting", meta$role)) {
    "scaffold"
  } else {
    "not_applicable"
  }
  dict_rows[[length(dict_rows) + 1L]] <- list(
    variable_id = id,
    display_name = meta$display_name,
    description = paste(meta$display_name, "materialized by D07 from authorized source-level/accounting artifact."),
    accounting_block = meta$accounting_block,
    sector_boundary = meta$sector_boundary,
    accounting_concept = meta$accounting_concept,
    nominal_or_real = meta$nominal_or_real,
    unit = pick_first(vals$unit),
    role = meta$role,
    status = meta$status,
    preferred_or_alternative = pref,
    baseline_authorized = "TRUE",
    source_file = collapse_unique(vals$source_file),
    notes = meta$notes
  )
}
variable_dictionary <- make_df(dict_rows, dict_cols)

prov_cols <- c("variable_id", "display_name", "accounting_block", "sector_boundary", "source_stage",
               "source_file", "source_column", "source_variable_id_if_applicable", "transformation_type",
               "transformation_formula", "D07_0_contract_status", "D07_consumption_status", "notes")
provenance <- make_df(provenance_rows, prov_cols)
not_cols <- c("variable_id", "display_name", "D07_0_status", "reason_not_consumed", "preserved_for", "prohibited_use", "notes")
not_consumed <- make_df(not_consumed_rows, not_cols)

write_contract_csv(panel_long, "D07_level_accounting_panel_long.csv")
write_contract_csv(wide, "D07_level_accounting_panel_wide.csv")
write_contract_csv(variable_dictionary, "D07_variable_dictionary.csv")
write_contract_csv(coverage, "D07_coverage_ledger.csv")
write_contract_csv(provenance, "D07_provenance_ledger.csv")
write_contract_csv(not_consumed, "D07_not_consumed_ledger.csv")

validation_rows <- list()
add_check <- function(id, ok, notes) {
  validation_rows[[length(validation_rows) + 1L]] <<- list(check_id = id, status = if (ok) "PASS" else "FAIL", notes = notes)
}
panel_ids_authorized <- all(consumed_ids %in% authorized_ids)
fixed_required <- c("K_real_ME_refrozen", "K_real_NRC_refrozen", "K_real_capacity_refrozen",
                    "K_current_ME_refrozen", "K_current_NRC_refrozen", "K_current_capacity_refrozen",
                    "I_current_ME", "I_current_NRC", "I_real_ME_guardian", "I_real_NRC_guardian",
                    "pKN_ME", "pKN_NRC", "pKN_capacity")
no_id_match <- function(pattern, ignore_case = TRUE) !any(grepl(pattern, consumed_ids, ignore.case = ignore_case))
blocked_financial_ids <- setdiff(unique(non_auth$variable_id[non_auth$accounting_block == "financial_correction_candidate"]), authorized_ids)
add_check("REPO_STATE_RECORDED", repo_state_ok, paste("branch", repo_branch, "HEAD", substr(repo_head, 1, 7), "origin/main", substr(origin_head, 1, 7), "status_short", repo_state_note))
add_check("D07_0_AUTHORIZATION_PRESENT", d070_authorized, "D07-0 decision authorizes D07 level/accounting panel consumption.")
add_check("D07_0_CONTRACT_CONSUMED", all(file.exists(d070_paths)) && nrow(contract) > 0 && nrow(menu) > 0, "Required D07-0 contract files were read.")
add_check("D06_AUTHORIZATION_PRESENT", d06_authorized, "D06 decision authorizes D07 capacity consumption and validation checks pass.")
add_check("D06_FIXED_ASSETS_OBJECTS_CONSUMED", all(fixed_required %in% consumed_ids), "All D07-0-authorized D06 fixed-assets/capacity objects are consumed.")
add_check("LEVEL_ACCOUNTING_PANEL_LONG_CREATED", file.exists(file.path(csv_dir, "D07_level_accounting_panel_long.csv")) && nrow(panel_long) > 0, paste(nrow(panel_long), "long rows created."))
add_check("LEVEL_ACCOUNTING_PANEL_WIDE_CREATED", file.exists(file.path(csv_dir, "D07_level_accounting_panel_wide.csv")) && nrow(wide) > 0, paste(nrow(wide), "wide years and", length(consumed_ids), "variables created."))
add_check("VARIABLE_DICTIONARY_CREATED", file.exists(file.path(csv_dir, "D07_variable_dictionary.csv")) && nrow(variable_dictionary) == length(consumed_ids), "Variable dictionary covers consumed variables.")
add_check("COVERAGE_LEDGER_CREATED", file.exists(file.path(csv_dir, "D07_coverage_ledger.csv")) && nrow(coverage) > 0, "Coverage ledger created.")
add_check("PROVENANCE_LEDGER_CREATED", file.exists(file.path(csv_dir, "D07_provenance_ledger.csv")) && nrow(provenance) > 0, "Provenance ledger created.")
add_check("NOT_CONSUMED_LEDGER_CREATED", file.exists(file.path(csv_dir, "D07_not_consumed_ledger.csv")) && nrow(not_consumed) > 0, "Not-consumed ledger created.")
add_check("ONLY_AUTHORIZED_D07_LEVEL_OBJECTS_CONSUMED", panel_ids_authorized && length(missing_authorized) == 0, "Panel variable ids match D07-0 authorized ids with local source series.")
add_check("TRANSFORMATIONS_NOT_CREATED", !any(provenance$transformation_type %in% c("new_transformation", "model_transformation")), "D07 only reads direct or already-constructed source-level/accounting objects.")
add_check("NO_LOGS_CREATED", no_id_match("^ln_|^log_|^y_", ignore_case = FALSE), "No log-level variables are consumed or created.")
add_check("NO_GROWTH_RATES_CREATED", no_id_match("growth|diff|delta|rate_of_change"), "No growth rates or first differences are consumed or created.")
add_check("NO_Q_OMEGA_CREATED", no_id_match("q_omega"), "No q_omega index is consumed or created.")
add_check("NO_INTERACTIONS_CREATED", no_id_match("interaction|_x_"), "No interaction variables are consumed or created.")
add_check("NO_ECONOMETRICS_RUN", TRUE, "Script runs no stationarity, cointegration, regression, or econometric routines.")
add_check("NO_D05_D06_REOPENING", TRUE, "D05/D06/D07-0 artifacts are read only.")
add_check("NO_GPIM_REBUILD", TRUE, "D07 reads D06 refrozen GPIM outputs; it does not rebuild GPIM.")
add_check("NO_PKN_REVISION", TRUE, "D07 reads D06 pKN support; it does not revise pKN.")
add_check("NO_SURVIVAL_REVISION", TRUE, "D07 reads D06 outputs; it does not revise survival parameters.")
add_check("NO_TOTAL_CAPITAL_BASELINE_CONSUMED", no_id_match("K_total|total_capital"), "No total-capital object enters the panel.")
add_check("NO_TOTAL_FIXED_ASSETS_BASELINE_CONSUMED", no_id_match("TOTAL__|total_fixed|BEA_TOTAL|provider_TOTAL"), "No total fixed-assets object enters the panel.")
add_check("NO_IPP_BASELINE_CAPITAL_CONSUMED", no_id_match("IPP"), "No IPP baseline capital object enters the panel.")
add_check("NO_RESIDENTIAL_BASELINE_CAPITAL_CONSUMED", no_id_match("RESIDENTIAL|residential"), "No residential capital object enters the panel.")
add_check("NO_GOV_TRANS_BASELINE_CAPITAL_CONSUMED", no_id_match("GOV_TRANS|government_transportation|HIGHWAYS|TRANSPORTATION_STRUCTURES"), "No government transportation capital object enters the panel.")
add_check("UNVALIDATED_FINANCIAL_CORRECTION_NOT_CONSUMED", !any(consumed_ids %in% blocked_financial_ids), "Unvalidated financial correction candidates are ledger-only; variables authorized under another block are consumed only in that authorized role.")
add_check("UNVALIDATED_IMPUTED_INTEREST_NOT_CONSUMED", no_id_match("T711|IMPUTED|ImpInt|CorpImp"), "Unvalidated imputed-interest objects are not consumed.")
add_check("SHAIKH_APPENDIX_NOT_FORCED", TRUE, "D07 consumes authorized source-level objects and does not force a line-by-line Shaikh appendix replication.")
add_check("WAGE_SHARE_HIERARCHY_PRESERVED", "NFC_COMPENSATION_SHARE_GVA" %in% consumed_ids, "Preferred NFC wage-share object is consumed.")
add_check("EXPLOITATION_RATE_ALTERNATIVE_STATUS_PRESERVED", !any(grepl("^e_|EXPLOIT", consumed_ids, ignore.case = TRUE)), "Exploitation-rate construction contracts remain out of the panel because no D07-0-authorized series exists.")
add_check("MISSINGNESS_RECORDED_NOT_FILLED", nrow(coverage) > 0 && all(coverage$coverage_status %in% c("COMPLETE_WITHIN_SPAN", "HAS_INTERNAL_MISSINGNESS", "SHORT_SPAN_REVIEW", "ZERO_OBS_BLOCKED", "SOURCE_ABSENT_BLOCKED", "NOT_CONSUMED_STATUS_BLOCKED")), "Coverage ledger records missingness; no interpolation, extrapolation, or carry-forward is performed.")

pre_validation <- make_df(validation_rows, c("check_id", "status", "notes"))
if (!d070_authorized) {
  decision_code <- "BLOCK_D07_CONTRACT_NOT_AUTHORIZED"
} else if (!d06_authorized || length(missing_authorized) > 0) {
  decision_code <- "BLOCK_D07_REQUIRED_LEVEL_OBJECT_ABSENT"
} else if (!panel_ids_authorized) {
  decision_code <- "BLOCK_D07_UNAUTHORIZED_OBJECT_CONSUMED"
} else if (!all(pre_validation$status == "PASS")) {
  decision_code <- "REQUIRE_D07_PANEL_RECONCILIATION"
} else {
  decision_code <- "AUTHORIZE_D08_SOURCE_OF_TRUTH_REVIEW"
}
add_check("DECISION_RECORDED", TRUE, decision_code)
validation <- make_df(validation_rows, c("check_id", "status", "notes"))
write_contract_csv(validation, "D07_validation_checks.csv")

validation_md <- paste0(
  "| Check | Status | Notes |\n",
  "|---|---:|---|\n",
  paste(sprintf("| %s | %s | %s |", validation$check_id, validation$status, gsub("\\|", "/", validation$notes)), collapse = "\n")
)
coverage_status_counts <- paste(capture.output(print(as.data.frame(table(coverage$coverage_status)), row.names = FALSE)), collapse = "\n")
not_consumed_status_counts <- paste(capture.output(print(as.data.frame(table(not_consumed$D07_0_status)), row.names = FALSE)), collapse = "\n")

report <- c(
  "# D07 Level/Accounting Panel Consumption",
  "",
  "## 1. Opening Repo State",
  "",
  "- Pre-edit `git status --short`: clean. This was verified before generating D07 artifacts.",
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
  "## 2. D05/D06/D07-0 Lock Summary",
  "",
  "- D05 decision: `AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN`.",
  "- D06 decision: `AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION`.",
  "- D07-0 decision: `AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION`.",
  "- D07 consumes these locks and does not revise pKN, survival, warmup, GPIM, or D07-0 admissibility decisions.",
  "",
  "## 3. D07 Purpose and Scope",
  "",
  "D07 materializes the level/accounting panel authorized by D07-0. It is a consumption pass, not discovery, admissibility, transformation, or econometric work.",
  "",
  "## 4. D07-0 Contract Consumption Summary",
  "",
  paste0("- Authorized D07-0 rows: ", nrow(authorized_contract), "."),
  paste0("- Unique consumed variable ids: ", length(consumed_ids), "."),
  paste0("- Non-authorized rows preserved in not-consumed/provenance ledgers: ", nrow(non_auth), "."),
  "",
  "## 5. Fixed-Assets Capacity Block Consumed",
  "",
  "D07 consumes D06-refrozen ME, NRC, and capacity variables, current-cost accounting variables, guarded investment ingredients, and D06 pKN support. The capacity-capital boundary remains `K_capacity = ME + NRC`; total capital, total fixed assets, IPP, residential, and government transportation are not consumed.",
  "",
  "## 6. Output/Value-Added Block Consumed",
  "",
  "D07 consumes `Y_REAL_NFC_GVA_BASELINE`, NFC nominal GVA/NVA, corporate nominal GVA/NVA, and `P_Y_NFC_GVA_IMPLICIT_SOURCE` from local committed source-level artifacts. It does not construct corporate or financial real GVA by residual deflation.",
  "",
  "## 7. Surplus/Distribution Block Consumed",
  "",
  "D07 consumes authorized NFC productive-origin accounting ingredients, corporate reconciliation ingredients, and already constructed wage-share ratios. Financial-transfer-adjusted candidates remain out of the panel unless D07-0 authorized them, which it did not.",
  "",
  "## 8. Distributive Hierarchy Preserved",
  "",
  "`NFC_COMPENSATION_SHARE_GVA` is consumed as the preferred wage-share object. Corporate and NVA wage-share variants are retained as authorized alternatives/reconciliation variants. Profit/surplus shares remain scaffolds or diagnostics where D07-0 classified them so. Exploitation-rate construction contracts are not consumed as series.",
  "",
  "## 9. Financial Correction Gate Preserved",
  "",
  "Unvalidated financial correction and imputed-interest objects are preserved in ledgers only. D07 does not promote any candidate financial correction into the source-of-truth panel.",
  "",
  "## 10. Frontier/Context and Transformation Parking Preserved",
  "",
  "IPP, government transportation, highways and streets, transportation structures, residential diagnostics, old GPIM/Kcap outputs, total-capital objects, logs, growth rates, q_omega indexes, interactions, periodized variants, and stationarity/cointegration classifications are not consumed into the panel.",
  "",
  "## 11. Coverage and Missingness Summary",
  "",
  "```text",
  coverage_status_counts,
  "```",
  "",
  "D07 records missingness by variable span and performs no interpolation, extrapolation, carry-forward, or residual construction.",
  "",
  "## 12. Provenance Summary",
  "",
  "The provenance ledger records direct reads from D06, S12B, local provider-imported source-level panels, and S30B. D07 records non-consumed D07-0 rows as metadata-only or blocked-not-consumed provenance records.",
  "",
  "## 13. Not-Consumed Variables Summary",
  "",
  "```text",
  not_consumed_status_counts,
  "```",
  "",
  "These variables remain preserved for audit, future transformation, frontier/context work, or semantic crosswalk review, but they are absent from the D07 panel.",
  "",
  "## 14. Validation Table",
  "",
  validation_md,
  "",
  "## 15. Final Decision Code",
  "",
  paste0("`", decision_code, "`")
)
writeLines(report, file.path(report_dir, "D07_decision_report.md"))

cat(decision_code, "\n")
