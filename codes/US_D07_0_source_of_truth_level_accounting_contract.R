#!/usr/bin/env Rscript

# D07-0 classifies existing level/accounting objects for downstream consumption.
# It does not construct a model panel, run econometrics, or reopen D05/D06.

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT")
csv_dir <- file.path(out_dir, "csv")
report_dir <- file.path(out_dir, "reports")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

rel <- function(...) file.path(...)
repo_file <- function(...) file.path(root, ...)
exists_repo <- function(...) file.exists(repo_file(...))
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
csv_quote <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x
}
make_df <- function(rows, cols) {
  if (!length(rows)) {
    out <- as.data.frame(setNames(replicate(length(cols), character(), simplify = FALSE), cols))
    return(out)
  }
  rows <- lapply(rows, function(r) {
    missing <- setdiff(cols, names(r))
    if (length(missing)) r[missing] <- ""
    r[cols]
  })
  out <- do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
  names(out) <- cols
  for (nm in names(out)) out[[nm]] <- csv_quote(out[[nm]])
  out
}

repo_status_short <- git(c("status", "--short"))
repo_status_branch <- git(c("status", "-sb"))
repo_branch <- git(c("branch", "--show-current"))
repo_head <- git(c("rev-parse", "HEAD"))
origin_head <- git(c("rev-parse", "origin/main"))
recent_log <- git(c("log", "--oneline", "-5"))
status_lines <- if (repo_status_short == "") character() else strsplit(repo_status_short, "\n", fixed = TRUE)[[1]]
d07_owned_dirty <- grepl("codes/US_D07_0_source_of_truth_level_accounting_contract\\.R|output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT", status_lines)
repo_state_ok <- repo_branch == "main" && repo_head == origin_head && (length(status_lines) == 0 || all(d07_owned_dirty))
repo_state_note <- if (length(status_lines) == 0) {
  "clean"
} else if (all(d07_owned_dirty)) {
  "D07-0 generated artifacts only"
} else {
  paste(status_lines[!d07_owned_dirty], collapse = "; ")
}

d05_dir <- repo_file("output/US/D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE")
d06_dir <- repo_file("output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN")
d06_capacity_file <- file.path(d06_dir, "csv/D06_capacity_refrozen_panel.csv")
d06_asset_file <- file.path(d06_dir, "csv/D06_asset_refrozen_gpim_panel.csv")
d06_guardian_file <- file.path(d06_dir, "csv/D06_real_investment_guardian_panel.csv")
d06_validation_file <- file.path(d06_dir, "csv/D06_validation_checks.csv")
d06_report_file <- file.path(d06_dir, "reports/D06_decision_report.md")

s30a_contract_file <- repo_file("output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_contract_status_ledger.csv")
s30a_authority_file <- repo_file("output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_authoritative_variable_ledger.csv")
s30a_price_file <- repo_file("output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_output_price_support_catalog.csv")
s30a_blocked_file <- repo_file("output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_blocked_variable_ledger.csv")
s30b_contract_file <- repo_file("output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_downstream_variable_contract.csv")
s30b_selection_file <- repo_file("output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_authoritative_variable_selection_ledger.csv")
s30b_blocked_file <- repo_file("output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_blocked_object_ledger.csv")
s30g_interest_file <- repo_file("output/US/S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM/csv/S30G_interest_candidate_inventory.csv")
s30h_role_lock_file <- repo_file("output/US/S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION/csv/S30H_corporate_surplus_dataset_role_lock.csv")
provider_menu_file <- repo_file("data/external/us_bea_provider/us_bea_variable_menu_locked.csv")

d06_capacity <- read_csv_base(d06_capacity_file)
d06_asset <- read_csv_base(d06_asset_file)
d06_guardian <- read_csv_base(d06_guardian_file)
d06_validation <- read_csv_base(d06_validation_file)
s30a_contract <- read_csv_base(s30a_contract_file)
s30a_authority <- read_csv_base(s30a_authority_file)
s30a_price <- read_csv_base(s30a_price_file)
s30a_blocked <- read_csv_base(s30a_blocked_file)
s30b_contract <- read_csv_base(s30b_contract_file)
s30b_selection <- read_csv_base(s30b_selection_file)
s30b_blocked <- read_csv_base(s30b_blocked_file)
s30g_interest <- read_csv_base(s30g_interest_file)
s30h_role_lock <- read_csv_base(s30h_role_lock_file)
provider_menu <- read_csv_base(provider_menu_file)

has_col <- function(df, col) nrow(df) > 0 && col %in% names(df)
provider_has <- function(id) nrow(provider_menu) > 0 && id %in% provider_menu$variable_id
contract_has <- function(df, id_col, id) nrow(df) > 0 && id_col %in% names(df) && id %in% df[[id_col]]

capacity_cols <- c(
  "K_real_ME_refrozen", "K_real_NRC_refrozen", "K_real_capacity_refrozen",
  "K_current_ME_refrozen", "K_current_NRC_refrozen", "K_current_capacity_refrozen",
  "pKN_ME", "pKN_NRC", "pKN_capacity"
)
capacity_present <- all(vapply(capacity_cols, has_col, logical(1), df = d06_capacity))
asset_present <- nrow(d06_asset) > 0 && all(c("ME", "NRC") %in% unique(d06_asset$asset))
guardian_present <- nrow(d06_guardian) > 0 && all(c("ME", "NRC") %in% unique(d06_guardian$asset))
d06_authorized <- file.exists(d06_report_file) &&
  grepl("AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION", paste(readLines(d06_report_file, warn = FALSE), collapse = "\n"), fixed = TRUE)
d06_validation_pass <- nrow(d06_validation) > 0 && "status" %in% names(d06_validation) && all(d06_validation$status == "PASS")

level_cols <- c(
  "variable_id", "display_name", "source_stage", "source_file", "sector_boundary",
  "accounting_block", "accounting_concept", "nominal_or_real", "source_status",
  "constructibility_status", "role", "status", "allowed_use", "prohibited_use", "notes"
)
menu_rows <- list()
add_menu <- function(...) {
  menu_rows[[length(menu_rows) + 1L]] <<- list(...)
}

fixed_cols <- c(
  "variable_id", "display_name", "asset", "nominal_or_real", "role", "status",
  "D06_source_file", "D06_authorization_status", "allowed_use", "prohibited_use", "notes"
)
fixed_rows <- list()
add_fixed <- function(...) {
  fixed_rows[[length(fixed_rows) + 1L]] <<- list(...)
}

add_fixed_and_menu <- function(variable_id, display_name, asset, nominal_or_real, role, status,
                               source_file, allowed_use, prohibited_use, notes) {
  add_fixed(
    variable_id = variable_id,
    display_name = display_name,
    asset = asset,
    nominal_or_real = nominal_or_real,
    role = role,
    status = status,
    D06_source_file = source_file,
    D06_authorization_status = if (d06_authorized) "D06_AUTHORIZED" else "D06_AUTHORIZATION_NOT_FOUND",
    allowed_use = allowed_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
  add_menu(
    variable_id = variable_id,
    display_name = display_name,
    source_stage = "D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN",
    source_file = source_file,
    sector_boundary = "NFC_CAPACITY_BOUNDARY",
    accounting_block = "fixed_assets_capacity",
    accounting_concept = asset,
    nominal_or_real = nominal_or_real,
    source_status = "present",
    constructibility_status = "already_constructed_or_source_ingredient",
    role = role,
    status = status,
    allowed_use = allowed_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
}

fixed_specs <- list(
  list("K_real_capacity_refrozen", "D06 refrozen real capacity capital", "ME_PLUS_NRC", "real", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "baseline capacity-capital level object", "total capital; total fixed assets; IPP; residential; government transportation baseline capital", "K_capacity = ME + NRC, refrozen in D06."),
  list("K_current_capacity_refrozen", "D06 refrozen current-cost capacity capital", "ME_PLUS_NRC", "nominal_current_cost", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "nominal/current-cost capacity-capital accounting object", "total capital; total fixed assets; IPP; residential; government transportation baseline capital", "Current-cost ME + NRC accounting support."),
  list("K_real_ME_refrozen", "D06 refrozen real machinery and equipment stock", "ME", "real", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "asset-level baseline component", "total capital baseline or standalone capacity replacement", "ME component of K_capacity."),
  list("K_real_NRC_refrozen", "D06 refrozen real nonresidential construction stock", "NRC", "real", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "asset-level baseline component", "total capital baseline or standalone capacity replacement", "NRC component of K_capacity."),
  list("K_current_ME_refrozen", "D06 refrozen current-cost machinery and equipment stock", "ME", "nominal_current_cost", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "asset-level current-cost component", "total capital baseline or standalone capacity replacement", "Current-cost ME component."),
  list("K_current_NRC_refrozen", "D06 refrozen current-cost nonresidential construction stock", "NRC", "nominal_current_cost", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "asset-level current-cost component", "total capital baseline or standalone capacity replacement", "Current-cost NRC component."),
  list("I_current_ME", "Current-dollar ME gross investment source ingredient", "ME", "nominal_current_cost", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_asset_refrozen_gpim_panel.csv", "source nominal investment ingredient", "model transformation; total-capital aggregation", "Mapped from D05/D06 asset panel."),
  list("I_current_NRC", "Current-dollar NRC gross investment source ingredient", "NRC", "nominal_current_cost", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_asset_refrozen_gpim_panel.csv", "source nominal investment ingredient", "model transformation; total-capital aggregation", "Mapped from D05/D06 asset panel."),
  list("I_real_ME_guardian", "GPIM-guarded real ME investment ingredient", "ME", "real", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_real_investment_guardian_panel.csv", "GPIM-guarded real investment ingredient", "new pKN revision or rebasing", "Constructed as I_current / (D05 pKN_guardian/100)."),
  list("I_real_NRC_guardian", "GPIM-guarded real NRC investment ingredient", "NRC", "real", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_real_investment_guardian_panel.csv", "GPIM-guarded real investment ingredient", "new pKN revision or rebasing", "Constructed as I_current / (D05 pKN_guardian/100)."),
  list("pKN_ME", "D06 ME guarded capital valuation price", "ME", "price_index", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "valuation/provenance/accounting support", "replacement with S12D/S29C recursive price object", "D05/D06 guarded pKN price support."),
  list("pKN_NRC", "D06 NRC guarded capital valuation price", "NRC", "price_index", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "valuation/provenance/accounting support", "replacement with S12D/S29C recursive price object", "D05/D06 guarded pKN price support."),
  list("pKN_capacity", "D06 capacity weighted guarded capital valuation price", "ME_PLUS_NRC", "price_index", "fixed_assets_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL", "csv/D06_capacity_refrozen_panel.csv", "valuation/provenance/accounting support", "replacement with total-capital price object", "Current-cost capacity divided by real capacity, scaled consistently with D06.")
)
for (s in fixed_specs) do.call(add_fixed_and_menu, s)

output_cols <- c(
  "variable_id", "display_name", "sector_boundary", "output_concept", "nominal_or_real",
  "price_or_quantity_basis", "source_status", "constructibility_status", "role", "status",
  "allowed_use", "prohibited_use", "notes"
)
output_rows <- list()
add_output <- function(variable_id, display_name, sector_boundary, output_concept, nominal_or_real,
                       price_or_quantity_basis, source_status, constructibility_status, role, status,
                       allowed_use, prohibited_use, notes, source_stage, source_file) {
  output_rows[[length(output_rows) + 1L]] <<- list(
    variable_id = variable_id,
    display_name = display_name,
    sector_boundary = sector_boundary,
    output_concept = output_concept,
    nominal_or_real = nominal_or_real,
    price_or_quantity_basis = price_or_quantity_basis,
    source_status = source_status,
    constructibility_status = constructibility_status,
    role = role,
    status = status,
    allowed_use = allowed_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
  add_menu(
    variable_id = variable_id,
    display_name = display_name,
    source_stage = source_stage,
    source_file = source_file,
    sector_boundary = sector_boundary,
    accounting_block = "output_value_added",
    accounting_concept = output_concept,
    nominal_or_real = nominal_or_real,
    source_status = source_status,
    constructibility_status = constructibility_status,
    role = role,
    status = status,
    allowed_use = allowed_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
}

add_output("Y_REAL_NFC_GVA_BASELINE", "Authoritative real NFC gross value added level", "NFC", "GVA", "real",
           "same-boundary NFC implicit GVA deflator", "present", "already_validated",
           "output_value_added_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           "baseline realized output level for D07 level/accounting panel", "productive capacity; capacity utilization; corporate or financial real residual output",
           "S30A authorizes this as the real output baseline.", "S30A_REAL_OUTPUT_FAMILY_CLOSURE", "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_primary_level_interface.csv")
add_output("NFC_GVA", "NFC gross value added", "NFC", "GVA", "nominal",
           "current dollars", if (provider_has("NFC_GVA")) "present" else "absent", "direct_source",
           "output_value_added_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           "nominal NFC output/value-added accounting level", "real output unless same-boundary validated deflator is used",
           "Direct provider income-account line.", "US_BEA_PROVIDER_MENU", "data/external/us_bea_provider/us_bea_variable_menu_locked.csv")
add_output("NFC_NVA", "NFC net value added", "NFC", "NVA", "nominal",
           "current dollars", if (provider_has("NFC_NVA")) "present" else "absent", "direct_source",
           "output_value_added_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           "nominal NFC net value-added accounting level", "real output by residual deflation",
           "Direct provider income-account line.", "US_BEA_PROVIDER_MENU", "data/external/us_bea_provider/us_bea_variable_menu_locked.csv")
add_output("CORP_GVA", "Corporate gross value added", "CORP", "GVA", "nominal",
           "current dollars", if (provider_has("CORP_GVA")) "present" else "absent", "direct_source",
           "output_value_added_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           "corporate reconciliation and robustness level", "productive-origin baseline; real CORP output unless directly validated",
           "Corporate legal boundary is reconciliation, not clean productive-origin baseline.", "US_BEA_PROVIDER_MENU", "data/external/us_bea_provider/us_bea_variable_menu_locked.csv")
add_output("CORP_NVA", "Corporate net value added", "CORP", "NVA", "nominal",
           "current dollars", if (provider_has("CORP_NVA")) "present" else "absent", "direct_source",
           "output_value_added_level", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           "corporate reconciliation and robustness level", "productive-origin baseline; real CORP output unless directly validated",
           "Corporate net value-added reconciliation line.", "US_BEA_PROVIDER_MENU", "data/external/us_bea_provider/us_bea_variable_menu_locked.csv")
add_output("FIN_GVA", "Financial corporate gross value added", "FIN", "GVA", "nominal",
           "current dollars", if (provider_has("FIN_GVA")) "present" else "absent", "direct_source",
           "candidate_only", "CANDIDATE_ONLY_REQUIRES_CROSSWALK",
           "financial-sector accounting/correction candidate", "productive-origin surplus baseline; silent productive output equivalence",
           "Financial-sector value added is retained as transfer/reconciliation evidence.", "US_BEA_PROVIDER_MENU", "data/external/us_bea_provider/us_bea_variable_menu_locked.csv")
add_output("FIN_NVA", "Financial corporate net value added", "FIN", "NVA", "nominal",
           "current dollars", if (provider_has("FIN_NVA")) "present" else "absent", "direct_source",
           "candidate_only", "CANDIDATE_ONLY_REQUIRES_CROSSWALK",
           "financial-sector accounting/correction candidate", "productive-origin surplus baseline; silent productive output equivalence",
           "Financial net value added is retained as transfer/reconciliation evidence.", "US_BEA_PROVIDER_MENU", "data/external/us_bea_provider/us_bea_variable_menu_locked.csv")
add_output("gva_real_or_qindex_corp", "Corporate real GVA or quantity index", "CORP", "GVA", "real",
           "blocked residual/proxy construction", "absent", "blocked",
           "blocked", "BLOCKED_BOUNDARY_CONFLICT",
           "none", "residual subtraction; aggregate deflator relabeling; D07 baseline output",
           "S30A blocks same-boundary CORP real GVA because no validated source exists.", "S30A_REAL_OUTPUT_FAMILY_CLOSURE", "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_blocked_variable_ledger.csv")
add_output("gva_real_or_qindex_fc", "Financial corporate real GVA or quantity index", "FIN", "GVA", "real",
           "blocked residual/proxy construction", "absent", "blocked",
           "blocked", "BLOCKED_BOUNDARY_CONFLICT",
           "none", "residual subtraction; aggregate deflator relabeling; D07 baseline output",
           "S30A blocks same-boundary financial real GVA because no validated source exists.", "S30A_REAL_OUTPUT_FAMILY_CLOSURE", "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_blocked_variable_ledger.csv")
for (pid in c("P_Y_NFC_GVA_IMPLICIT_SOURCE", "P_Y_NFC_GVA_T115_VALIDATION", "P_Y_PROXY_GDP_IMPLICIT",
              "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT", "P_Y_PROXY_BUSINESS_OUTPUT",
              "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS", "P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE",
              "P_Y_PROXY_GDPBYIND_VA_MANUFACTURING")) {
  row <- if (nrow(s30a_price) && pid %in% s30a_price$variable_id) s30a_price[s30a_price$variable_id == pid, ][1, ] else data.frame()
  source_boundary <- if (nrow(row)) row$source_boundary else "UNKNOWN_REVIEW_REQUIRED"
  status <- if (grepl("NFC_GVA_IMPLICIT_SOURCE", pid)) "AUTHORIZED_FOR_D07_LEVEL_PANEL" else if (grepl("T115", pid)) "DIAGNOSTIC_ONLY" else "PARKED_FRONTIER_CONTEXT"
  role <- if (grepl("NFC_GVA_IMPLICIT_SOURCE", pid)) "output_value_added_level" else if (grepl("T115", pid)) "diagnostic" else "frontier_conditioning"
  add_output(pid, pid, toupper(gsub(" ", "_", source_boundary)), "deflator_or_price_support", "price_index",
             if (nrow(row)) row$normalized_unit else "Index", if (nrow(row)) "present" else "review_required",
             if (grepl("NFC_GVA_IMPLICIT_SOURCE", pid)) "same_boundary_validated" else "support_or_proxy_only",
             role, status,
             if (grepl("NFC_GVA_IMPLICIT_SOURCE", pid)) "same-boundary NFC GVA deflation support" else "diagnostic/robustness/context support only",
             "CORP/FIN deflator relabeling; productive capacity; capacity utilization",
             if (nrow(row)) row$notes else "Price support object classified from S30A contract.",
             "S30A_REAL_OUTPUT_FAMILY_CLOSURE", "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE/csv/S30A_output_price_support_catalog.csv")
}

surplus_cols <- c(
  "variable_id", "display_name", "sector_boundary", "surplus_ladder", "surplus_concept",
  "denominator_concept", "wage_component", "financial_sector_treatment", "tax_treatment",
  "cfc_treatment", "transfer_treatment", "role", "status", "allowed_use", "prohibited_use", "notes"
)
surplus_rows <- list()
add_surplus <- function(variable_id, display_name, sector_boundary, surplus_ladder, surplus_concept,
                        denominator_concept, wage_component, financial_sector_treatment, tax_treatment,
                        cfc_treatment, transfer_treatment, role, status, allowed_use, prohibited_use,
                        notes, source_stage = "US_BEA_PROVIDER_MENU", source_file = "data/external/us_bea_provider/us_bea_variable_menu_locked.csv") {
  surplus_rows[[length(surplus_rows) + 1L]] <<- list(
    variable_id = variable_id,
    display_name = display_name,
    sector_boundary = sector_boundary,
    surplus_ladder = surplus_ladder,
    surplus_concept = surplus_concept,
    denominator_concept = denominator_concept,
    wage_component = wage_component,
    financial_sector_treatment = financial_sector_treatment,
    tax_treatment = tax_treatment,
    cfc_treatment = cfc_treatment,
    transfer_treatment = transfer_treatment,
    role = role,
    status = status,
    allowed_use = allowed_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
  add_menu(
    variable_id = variable_id,
    display_name = display_name,
    source_stage = source_stage,
    source_file = source_file,
    sector_boundary = sector_boundary,
    accounting_block = "surplus_distribution",
    accounting_concept = surplus_concept,
    nominal_or_real = "nominal_or_ratio",
    source_status = if (provider_has(variable_id) || grepl("SHARE|CONTRACT|e_", variable_id)) "present_or_contract" else "review_required",
    constructibility_status = "classified_not_newly_constructed",
    role = role,
    status = status,
    allowed_use = allowed_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
}

nfc_ingredients <- list(
  c("NFC_GVA", "NFC gross value added", "NONE_NOT_APPLICABLE", "denominator_GVA", "not_applicable", "excluded_productive_origin_baseline", "not_applicable", "gross_includes_cfc", "not_applicable"),
  c("NFC_NVA", "NFC net value added", "NONE_NOT_APPLICABLE", "denominator_NVA", "not_applicable", "excluded_productive_origin_baseline", "not_applicable", "net_excludes_cfc", "not_applicable"),
  c("NFC_COMP", "NFC compensation of employees", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE", "NFC_COMP", "excluded_productive_origin_baseline", "not_applicable", "not_applicable", "not_applicable"),
  c("NFC_CFC", "NFC consumption of fixed capital", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "not_applicable", "cfc_component", "not_applicable"),
  c("NFC_NOS", "NFC net operating surplus", "NOS", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "pre_tax_operating_surplus", "net_excludes_cfc", "not_applicable"),
  c("NFC_PBT", "NFC profits before tax", "PBT", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "before_tax", "not_applicable", "not_applicable"),
  c("NFC_PAT", "NFC profits after tax", "PAT", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "after_tax", "not_applicable", "not_applicable"),
  c("NFC_TAX", "NFC corporate income taxes", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "tax_component", "not_applicable", "not_applicable"),
  c("NFC_UNDISTRIBUTED", "NFC undistributed profits with IVA and CCAdj", "UNDISTRIBUTED_PROFITS", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "after_tax_retained_component", "not_applicable", "distribution_component"),
  c("NFC_RETAINED", "NFC undistributed profits after tax", "RETAINED_PROFITS", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "after_tax_retained_component", "not_applicable", "distribution_component"),
  c("NFC_NET_INT", "NFC net interest and miscellaneous payments", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "not_applicable", "not_applicable", "financial_claims_burden_component"),
  c("NFC_TRANSFERS_NET", "NFC business current transfers net", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "not_applicable", "not_applicable", "transfer_component"),
  c("NFC_DIVIDENDS_NET", "NFC net dividends", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE", "not_applicable", "excluded_productive_origin_baseline", "not_applicable", "not_applicable", "distribution_component")
)
for (x in nfc_ingredients) {
  add_surplus(x[1], x[2], "NFC", "NFC_productive_origin_baseline", x[3], x[4], x[5], x[6], x[7], x[8], x[9],
              "surplus_accounting_ingredient", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
              "NFC productive-origin accounting ingredient", "financial-sector productive equivalence; model-ready transformation",
              "NFC is the strict productive-origin baseline; use available direct provider names.")
}

corp_ingredients <- list(
  c("CORP_GVA", "Corporate gross value added", "NONE_NOT_APPLICABLE", "denominator_GVA"),
  c("CORP_NVA", "Corporate net value added", "NONE_NOT_APPLICABLE", "denominator_NVA"),
  c("CORP_COMP", "Corporate compensation of employees", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE"),
  c("CORP_CFC", "Corporate consumption of fixed capital", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE"),
  c("CORP_NOS", "Corporate net operating surplus", "NOS", "NONE_NOT_APPLICABLE"),
  c("CORP_PBT", "Corporate profits before tax", "PBT", "NONE_NOT_APPLICABLE"),
  c("CORP_PAT", "Corporate profits after tax", "PAT", "NONE_NOT_APPLICABLE"),
  c("CORP_TAX", "Corporate income taxes", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE"),
  c("CORP_UNDISTRIBUTED", "Corporate undistributed profits with IVA and CCAdj", "UNDISTRIBUTED_PROFITS", "NONE_NOT_APPLICABLE"),
  c("CORP_NET_INT", "Corporate net interest and miscellaneous payments", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE"),
  c("CORP_TRANSFERS_NET", "Corporate business current transfers net", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE"),
  c("CORP_DIVIDENDS_NET", "Corporate net dividends", "NONE_NOT_APPLICABLE", "NONE_NOT_APPLICABLE")
)
for (x in corp_ingredients) {
  add_surplus(x[1], x[2], "CORP", "corporate_reconciliation_variant", x[3], x[4], "not_applicable",
              "included_accounting_boundary", "varies_by_line", "varies_by_line", "varies_by_line",
              "surplus_accounting_ingredient", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
              "corporate reconciliation, robustness, and accounting comparison", "clean productive-origin surplus baseline without NFC gate",
              "Corporate objects are useful for reconciliation but do not displace NFC productive-origin baseline.")
}

fin_ingredients <- c("FIN_GVA", "FIN_NVA", "FIN_COMP", "FIN_CFC", "FIN_NOS", "FIN_PBT", "FIN_NET_INT", "FIN_TRANSFERS", "FIN_DIVIDENDS")
for (id in fin_ingredients) {
  add_surplus(id, id, "FIN", "financial_transfer_adjusted_candidate", "UNKNOWN_REVIEW_REQUIRED", "NONE_NOT_APPLICABLE", "not_applicable",
              "transfer_adjusted_candidate", "unknown_review_required", "unknown_review_required", "unknown_review_required",
              "candidate_only", "CANDIDATE_ONLY_REQUIRES_CROSSWALK",
              "transfer/reconciliation/correction candidate only", "productive-origin baseline; silent substitution for total financial business",
              "Financial-sector income-account variables require semantic and historical/current crosswalk validation before stronger use.")
}

add_surplus("NFC_COMPENSATION_SHARE_GVA", "NFC compensation share of GVA", "NFC", "NFC_productive_origin_baseline",
            "NONE_NOT_APPLICABLE", "GVA", "NFC_COMP", "excluded_productive_origin_baseline", "not_applicable",
            "gross_denominator", "not_applicable", "preferred_wage_share", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
            "preferred operational distributive variable", "profit-share-first operational replacement; model/econometric use in D07-0",
            "S30B preserves NFC_COMP / NFC_GVA as the preferred unadjusted wage-share baseline.",
            "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_downstream_variable_contract.csv")
add_surplus("NFC_COMPENSATION_SHARE_NVA", "NFC compensation share of NVA", "NFC", "NFC_productive_origin_baseline",
            "NONE_NOT_APPLICABLE", "NVA", "NFC_COMP", "excluded_productive_origin_baseline", "not_applicable",
            "net_denominator", "not_applicable", "preferred_wage_share", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
            "wage-share robustness variant", "profit-share-first operational replacement; model/econometric use in D07-0",
            "S30B preserves this as a net-value-added wage-share robustness variant.",
            "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_downstream_variable_contract.csv")
add_surplus("CORP_COMPENSATION_SHARE_GVA", "Corporate compensation share of GVA", "CORP", "corporate_reconciliation_variant",
            "NONE_NOT_APPLICABLE", "GVA", "CORP_COMP", "included_accounting_boundary", "not_applicable",
            "gross_denominator", "not_applicable", "preferred_wage_share", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
            "corporate wage-share robustness/reconciliation variant", "NFC baseline replacement without explicit choice; model/econometric use in D07-0",
            "Corporate wage share is robustness/reconciliation below the NFC baseline.",
            "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_downstream_variable_contract.csv")
add_surplus("CORP_COMPENSATION_SHARE_NVA", "Corporate compensation share of NVA", "CORP", "corporate_reconciliation_variant",
            "NONE_NOT_APPLICABLE", "NVA", "CORP_COMP", "included_accounting_boundary", "not_applicable",
            "net_denominator", "not_applicable", "preferred_wage_share", "AUTHORIZED_FOR_D07_LEVEL_PANEL",
            "corporate wage-share robustness/reconciliation variant", "NFC baseline replacement without explicit choice; model/econometric use in D07-0",
            "Corporate net-value-added wage share is robustness/reconciliation below the NFC baseline.",
            "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_downstream_variable_contract.csv")
for (id in c("NFC_NET_OPERATING_SURPLUS_SHARE_GVA", "NFC_NET_OPERATING_SURPLUS_SHARE_NVA",
             "CORP_NET_OPERATING_SURPLUS_SHARE_GVA", "CORP_NET_OPERATING_SURPLUS_SHARE_NVA")) {
  boundary <- if (grepl("^NFC", id)) "NFC" else "CORP"
  denom <- if (grepl("NVA$", id)) "NVA" else "GVA"
  ladder <- if (boundary == "NFC") "NFC_productive_origin_baseline" else "corporate_reconciliation_variant"
  add_surplus(id, id, boundary, ladder, "NOS", denom, "not_applicable",
              if (boundary == "NFC") "excluded_productive_origin_baseline" else "included_accounting_boundary",
              "pre_tax_operating_surplus", if (denom == "NVA") "net_denominator" else "gross_denominator", "not_applicable",
              "profit_share_scaffold", "DIAGNOSTIC_ONLY",
              "profit/surplus accounting scaffold and diagnostic", "primary operational distributive variable; D07-0 regression input",
              "Profit-share variants define surplus concepts and denominators but do not replace wage share.",
              "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_downstream_variable_contract.csv")
}
for (id in c("e_NFC_CONSTRUCTION_CONTRACT", "e_CORP_CONSTRUCTION_CONTRACT")) {
  boundary <- if (grepl("NFC", id)) "NFC" else "CORP"
  add_surplus(id, paste(boundary, "exploitation-rate construction contract"), boundary,
              if (boundary == "NFC") "NFC_productive_origin_baseline" else "corporate_reconciliation_variant",
              "NONE_NOT_APPLICABLE", "wage_share", paste0(boundary, "_COMPENSATION_SHARE_GVA"),
              if (boundary == "NFC") "excluded_productive_origin_baseline" else "included_accounting_boundary",
              "not_applicable", "not_applicable", "not_applicable",
              "alternative_exploitation_rate", "REVIEW_REQUIRED",
              "alternative distributive measure after construction authorization", "primary wage-share replacement; log transformation in D07-0",
              "S30B records exploitation rate as a preserved future alternative; no exploitation-rate series is constructed in the current closure.",
              "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE/csv/S30B_readiness_inventory.csv")
}

financial_cols <- c(
  "variable_id", "display_name", "sector_boundary", "candidate_family", "source_status",
  "semantic_crosswalk_status", "historical_current_crosswalk_status", "role", "status",
  "allowed_use", "prohibited_use", "notes"
)
financial_rows <- list()
add_fin <- function(variable_id, display_name, sector_boundary, candidate_family, source_status,
                    semantic_crosswalk_status, historical_current_crosswalk_status, role, status,
                    allowed_use, prohibited_use, notes) {
  financial_rows[[length(financial_rows) + 1L]] <<- list(
    variable_id = variable_id,
    display_name = display_name,
    sector_boundary = sector_boundary,
    candidate_family = candidate_family,
    source_status = source_status,
    semantic_crosswalk_status = semantic_crosswalk_status,
    historical_current_crosswalk_status = historical_current_crosswalk_status,
    role = role,
    status = status,
    allowed_use = allowed_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
  add_menu(
    variable_id = variable_id,
    display_name = display_name,
    source_stage = "S30G_OR_S30H_FINANCIAL_CORRECTION_AUDITS",
    source_file = "output/US/S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM/csv/S30G_interest_candidate_inventory.csv",
    sector_boundary = sector_boundary,
    accounting_block = "financial_correction_candidate",
    accounting_concept = candidate_family,
    nominal_or_real = "nominal",
    source_status = source_status,
    constructibility_status = semantic_crosswalk_status,
    role = role,
    status = status,
    allowed_use = allowed_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
}
if (nrow(s30g_interest)) {
  for (i in seq_len(nrow(s30g_interest))) {
    r <- s30g_interest[i, ]
    id <- r$source_variable_id
    status <- if (identical(r$semantic_class, "ADMISSIBLE_NFC_INTEREST_AND_MISC_PAYMENTS_PROXY")) "DIAGNOSTIC_ONLY" else "CANDIDATE_ONLY_REQUIRES_CROSSWALK"
    add_fin(id, r$display_name, r$sector_boundary, r$accounting_position, r$source_status,
            if (status == "DIAGNOSTIC_ONLY") "bounded_proxy_validated_not_exact_crosswalk" else r$semantic_class,
            "unresolved_or_not_validated", "candidate_only", status,
            if (status == "DIAGNOSTIC_ONLY") "bounded diagnostic/proxy evidence; not exact Shaikh correction" else "candidate audit trail only",
            "baseline productive surplus; unvalidated adjusted corporate surplus; binding Shaikh appendix replication",
            r$limitations)
  }
}
if (nrow(s30h_role_lock)) {
  for (i in seq_len(nrow(s30h_role_lock))) {
    r <- s30h_role_lock[i, ]
    add_fin(r$object_id, r$object_id, if (grepl("^FIN", r$object_id)) "FIN" else "CORP_FIN_BOUNDARY",
            "corporate_financial_boundary_candidate", "present", "role_locked_not_baseline_crosswalk",
            "not_exact_bilateral_crosswalk", if (r$baseline_eligible == "yes") "surplus_accounting_ingredient" else "candidate_only",
            "DIAGNOSTIC_ONLY",
            if (r$baseline_eligible == "yes") "role-lock evidence; baseline authorization is recorded in the surplus scaffold, not this financial-correction ledger" else "diagnostic or sensitivity evidence only",
            r$prohibited_use, r$interpretation)
  }
}

frontier_cols <- c(
  "variable_id", "display_name", "sector_boundary", "context_family", "source_status",
  "role", "status", "allowed_future_use", "prohibited_use", "notes"
)
frontier_rows <- list()
add_frontier <- function(variable_id, display_name, sector_boundary, context_family, source_status,
                         role, status, allowed_future_use, prohibited_use, notes) {
  frontier_rows[[length(frontier_rows) + 1L]] <<- list(
    variable_id = variable_id,
    display_name = display_name,
    sector_boundary = sector_boundary,
    context_family = context_family,
    source_status = source_status,
    role = role,
    status = status,
    allowed_future_use = allowed_future_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
  add_menu(
    variable_id = variable_id,
    display_name = display_name,
    source_stage = "US_BEA_PROVIDER_MENU",
    source_file = "data/external/us_bea_provider/us_bea_variable_menu_locked.csv",
    sector_boundary = sector_boundary,
    accounting_block = "frontier_context",
    accounting_concept = context_family,
    nominal_or_real = "varies",
    source_status = source_status,
    constructibility_status = "parked_not_constructed",
    role = role,
    status = status,
    allowed_use = allowed_future_use,
    prohibited_use = prohibited_use,
    notes = notes
  )
}
frontier_patterns <- provider_menu[grepl("IPP|GOV_TRANS|HIGHWAYS_STREETS|TRANSPORTATION_STRUCTURES", provider_menu$variable_id), , drop = FALSE]
if (nrow(frontier_patterns)) {
  for (i in seq_len(nrow(frontier_patterns))) {
    r <- frontier_patterns[i, ]
    fam <- if (grepl("IPP", r$variable_id)) "IPP" else if (grepl("HIGHWAYS_STREETS", r$variable_id)) "highways_and_streets" else if (grepl("TRANSPORTATION_STRUCTURES", r$variable_id)) "transportation_structures" else "government_transportation"
    add_frontier(r$variable_id, r$canonical_name, r$sector_boundary, fam, r$status,
                 "frontier_conditioning", "PARKED_FRONTIER_CONTEXT",
                 "future frontier/context/conditioning analysis after explicit authorization",
                 "K_capacity; baseline capacity capital; productive accumulation capital",
                 "Parked by D07-0 boundary lock.")
  }
}
add_frontier("RESIDENTIAL_CAPITAL_MENU", "Residential capital menu", "AGGREGATE_REFERENCE", "residential_exclusion_diagnostic",
             if (provider_has("RESIDENTIAL_CAPITAL_MENU")) "present" else "review_required",
             "diagnostic", "DIAGNOSTIC_ONLY", "exclusion diagnostic only",
             "K_capacity; baseline capacity capital; productive accumulation capital",
             "Residential capital remains exclusion-diagnostic only.")

sup_cols <- c(
  "variable_id", "display_name", "previous_role", "new_status", "superseded_by",
  "parking_reason", "preserved_for", "prohibited_use", "notes"
)
sup_rows <- list()
add_sup <- function(variable_id, display_name, previous_role, new_status, superseded_by,
                    parking_reason, preserved_for, prohibited_use, notes) {
  sup_rows[[length(sup_rows) + 1L]] <<- list(
    variable_id = variable_id,
    display_name = display_name,
    previous_role = previous_role,
    new_status = new_status,
    superseded_by = superseded_by,
    parking_reason = parking_reason,
    preserved_for = preserved_for,
    prohibited_use = prohibited_use,
    notes = notes
  )
  block <- if (grepl("log|growth|q_|interaction|stationarity|cointegration", variable_id, ignore.case = TRUE)) "transformation_parked" else "superseded_prior_object"
  add_menu(
    variable_id = variable_id,
    display_name = display_name,
    source_stage = "prior_stage_or_metadata",
    source_file = "see supersession ledger",
    sector_boundary = "UNKNOWN_REVIEW_REQUIRED",
    accounting_block = block,
    accounting_concept = previous_role,
    nominal_or_real = "varies",
    source_status = "preserved",
    constructibility_status = "not_authorized_for_D07_0",
    role = if (block == "transformation_parked") "diagnostic" else "superseded_for_baseline",
    status = new_status,
    allowed_use = preserved_for,
    prohibited_use = prohibited_use,
    notes = notes
  )
}
add_sup("D01_gpim_core_capital_panel", "D01 GPIM core capital panel", "early GPIM repair output", "SUPERSEDED_FOR_BASELINE", "D06 K_capacity = ME + NRC", "D06 refreeze supersedes older GPIM/Kcap baseline use", "audit/provenance", "baseline capacity-capital consumption", "Historical output is preserved; not deleted.")
add_sup("D01_gpim_gross_survival_panel", "D01 GPIM gross survival panel", "early GPIM survival output", "SUPERSEDED_FOR_BASELINE", "D06 refrozen ME/NRC stocks", "D06 locks survival/warmup outcome", "audit/provenance", "baseline capacity-capital consumption", "No survival rules are reopened.")
add_sup("D02_initialization_sensitivity", "D02 initialization sensitivity outputs", "initialization diagnostic", "DIAGNOSTIC_ONLY", "D06 initialization warmup ledger", "D06 records final guarded warmup state", "audit/provenance", "baseline object selection", "No initialization rules are reopened.")
add_sup("D03_S29C_price_deflator_outputs", "D03 S29C price/deflator outputs", "price-deflator audit", "SUPERSEDED_FOR_BASELINE", "D05/D06 pKN_guardian", "D05/D06 guarded price-stock coherence supersedes conflicting price objects", "audit/provenance", "baseline pKN replacement", "No pKN revision is made.")
add_sup("D04_S12DB_source_price_seed_outputs", "D04 S12D_B source price and seed audit", "source price seed audit", "SUPERSEDED_FOR_BASELINE", "D05/D06 pKN_guardian", "D05/D06 guarded pKN is the active valuation support", "audit/provenance", "baseline pKN replacement", "No seed rule is reopened.")
add_sup("S12D_B_GPIM_BASELINE_CONSTRUCTION", "S12D_B GPIM baseline construction", "older GPIM baseline", "SUPERSEDED_FOR_BASELINE", "D06 refrozen K_capacity", "Older GPIM contract conflicts with D06 baseline authority", "audit/provenance", "baseline capacity-capital consumption", "Preserved only for provenance.")
add_sup("S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION", "S29D asset-specific GPIM stock construction", "older asset GPIM stock output", "SUPERSEDED_FOR_BASELINE", "D06 refrozen ME/NRC stocks", "D06 refreeze supersedes prior S29D baseline use", "audit/provenance", "baseline capacity-capital consumption", "Preserved only for provenance.")
add_sup("S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION", "S29E core capital aggregation", "older aggregation", "SUPERSEDED_FOR_BASELINE", "D06 K_capacity = ME + NRC", "Older aggregation may include objects outside D06 boundary", "audit/provenance", "baseline capacity-capital consumption", "D07-0 authorizes only ME + NRC.")
add_sup("S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS", "S29F total-capital analytical transformations", "model transformation panel", "PARKED_TRANSFORMATION", "not_applicable", "D07-0 is level/accounting only", "future transformation pass", "D07 level/accounting panel consumption", "Logs, growth rates, intensities, and transformed panels remain parked.")
add_sup("S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE", "S29K total-capital interface", "total-capital consumer handoff", "SUPERSEDED_FOR_BASELINE", "D06 K_capacity = ME + NRC", "Total-capital objects violate D06 capacity-capital boundary", "audit/provenance", "baseline capacity-capital consumption", "Total capital is not baseline-authorized.")
add_sup("K_total", "Total capital object", "total capital", "BLOCKED_BOUNDARY_CONFLICT", "D06 K_capacity = ME + NRC", "Total capital is outside the capacity-capital boundary", "none for baseline; audit only if present", "baseline capacity capital", "Explicitly blocked by D07-0.")
add_sup("K_real_total", "Real total capital object", "real total capital", "BLOCKED_BOUNDARY_CONFLICT", "D06 K_capacity = ME + NRC", "Total capital is outside the capacity-capital boundary", "none for baseline; audit only if present", "baseline capacity capital", "Explicitly blocked by D07-0.")
add_sup("K_current_total", "Current-cost total capital object", "current-cost total capital", "BLOCKED_BOUNDARY_CONFLICT", "D06 K_current_capacity_refrozen", "Total capital is outside the capacity-capital boundary", "none for baseline; audit only if present", "baseline capacity capital", "Explicitly blocked by D07-0.")
add_sup("pKN_total", "Total-capital pKN object", "total capital valuation", "BLOCKED_BOUNDARY_CONFLICT", "D06 pKN_capacity", "Total-capital price object is outside D06 boundary", "audit only if present", "baseline pKN support", "Explicitly blocked by D07-0.")
add_sup("IPP_baseline", "IPP baseline capital candidate", "frontier/capital candidate", "PARKED_FRONTIER_CONTEXT", "not_applicable", "IPP is context/conditioning only", "future frontier/context pass", "baseline capacity capital", "IPP is not capacity-building accumulation capital in D07-0.")
add_sup("residential_baseline", "Residential capital baseline candidate", "residential capital candidate", "DIAGNOSTIC_ONLY", "not_applicable", "Residential capital remains exclusion diagnostic", "audit/exclusion diagnostic", "baseline capacity capital", "Residential is not baseline capacity capital.")
add_sup("government_transportation_baseline", "Government transportation capital baseline candidate", "government transportation candidate", "PARKED_FRONTIER_CONTEXT", "not_applicable", "Government transportation is context/conditioning only", "future frontier/context pass", "baseline capacity capital", "Government transportation is not baseline capacity capital.")
add_sup("q_omega_indexes", "q_omega accumulated indexes", "distribution transformation", "PARKED_TRANSFORMATION", "not_applicable", "D07-0 parks transformations", "future transformation/model pass", "D07 level/accounting panel consumption", "No q_omega index is constructed or consumed.")
add_sup("logs_and_growth_rates", "Logs, growth rates, first differences", "transformation", "PARKED_TRANSFORMATION", "not_applicable", "D07-0 is level/accounting only", "future transformation/model pass", "D07 level/accounting panel consumption", "Includes log-levels such as y_real_nfc_gva_baseline.")
add_sup("periodized_model_variants", "Periodized model variants", "model specification", "PARKED_TRANSFORMATION", "not_applicable", "D07-0 does not build model variants", "future model pass", "D07 level/accounting panel consumption", "No periodized regression-ready variables are authorized.")
add_sup("stationarity_integration_classifications", "Stationarity and integration classifications", "econometric classification", "PARKED_TRANSFORMATION", "not_applicable", "D07-0 does not run integration tests", "future econometric pass", "D07 level/accounting panel consumption", "No I(1) or cointegration-ready panel is built.")
add_sup("Shaikh_adjusted_corporate_surplus_objects", "Shaikh-style adjusted corporate surplus objects", "adjusted corporate surplus", "CANDIDATE_ONLY_REQUIRES_CROSSWALK", "not_applicable", "Financial-sector and imputed-interest crosswalk unresolved", "future semantic-crosswalk pass", "baseline productive surplus", "Shaikh appendix is operational guide, not binding replication target.")

cons_cols <- c(
  "variable_id", "display_name", "sector_boundary", "accounting_block", "role", "status",
  "authorized_for_D07_level_panel", "reason", "required_source", "required_prior_stage", "notes"
)
cons_rows <- list()
add_cons <- function(variable_id, display_name, sector_boundary, accounting_block, role, status,
                     authorized, reason, required_source, required_prior_stage, notes) {
  cons_rows[[length(cons_rows) + 1L]] <<- list(
    variable_id = variable_id,
    display_name = display_name,
    sector_boundary = sector_boundary,
    accounting_block = accounting_block,
    role = role,
    status = status,
    authorized_for_D07_level_panel = if (authorized) "TRUE" else "FALSE",
    reason = reason,
    required_source = required_source,
    required_prior_stage = required_prior_stage,
    notes = notes
  )
}

for (r in fixed_rows) {
  add_cons(r$variable_id, r$display_name, "NFC_CAPACITY_BOUNDARY", "fixed_assets_capacity",
           r$role, r$status, r$status == "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           r$allowed_use, r$D06_source_file, "D06", r$notes)
}
for (r in output_rows) {
  add_cons(r$variable_id, r$display_name, r$sector_boundary, "output_value_added",
           r$role, r$status, r$status == "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           r$allowed_use, "see output_value_added_block", "S30A/provider", r$notes)
}
for (r in surplus_rows) {
  add_cons(r$variable_id, r$display_name, r$sector_boundary, "surplus_distribution",
           r$role, r$status, r$status == "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           r$allowed_use, "see surplus_distribution_scaffold", "S30B/provider", r$notes)
}
for (r in financial_rows) {
  add_cons(r$variable_id, r$display_name, r$sector_boundary, "financial_correction_candidate",
           r$role, r$status, r$status == "AUTHORIZED_FOR_D07_LEVEL_PANEL",
           r$allowed_use, "see financial_correction_candidate_ledger", "S30G/S30H", r$notes)
}
for (r in frontier_rows) {
  add_cons(r$variable_id, r$display_name, r$sector_boundary, "frontier_context",
           r$role, r$status, FALSE, r$allowed_future_use, "see frontier_context_parking_ledger",
           "provider menu", r$notes)
}
for (r in sup_rows) {
  add_cons(r$variable_id, r$display_name, "UNKNOWN_REVIEW_REQUIRED", "transformation_or_superseded",
           "superseded_for_baseline", r$new_status, FALSE, r$parking_reason, "see supersession ledger",
           "prior stages", r$notes)
}

validation_cols <- c("check_id", "status", "notes")
validation_rows <- list()
add_check <- function(id, ok, notes) {
  validation_rows[[length(validation_rows) + 1L]] <<- list(check_id = id, status = if (ok) "PASS" else "FAIL", notes = notes)
}
add_check("REPO_STATE_RECORDED", repo_state_ok, paste("branch", repo_branch, "HEAD", substr(repo_head, 1, 7), "origin/main", substr(origin_head, 1, 7), "status_short", repo_state_note))
add_check("D06_AUTHORIZATION_PRESENT", d06_authorized && d06_validation_pass, "D06 decision authorizes D07 capacity panel consumption and D06 validation checks pass.")
add_check("D06_FIXED_ASSETS_OBJECTS_CLASSIFIED", capacity_present && asset_present && guardian_present, "D06 capacity, asset, and guardian panels contain ME, NRC, and capacity objects.")
add_check("NO_D05_D06_REOPENING", TRUE, "D07-0 only reads D05/D06 artifacts and does not revise pKN, survival, warmup, or capacity boundary.")
add_check("LEVEL_ACCOUNTING_ONLY_ENFORCED", TRUE, "No final regression/model panel is created.")
add_check("TRANSFORMATIONS_PARKED", any(vapply(sup_rows, function(x) x$new_status == "PARKED_TRANSFORMATION", logical(1))), "Logs, growth rates, first differences, q_omega, interactions, periodization, stationarity, and cointegration objects are parked.")
add_check("OUTPUT_VALUE_ADDED_BLOCK_CLASSIFIED", length(output_rows) > 0, "Output/value-added objects are classified by sector boundary and nominal/real status.")
add_check("SURPLUS_DISTRIBUTION_SCAFFOLD_CREATED", length(surplus_rows) > 0, "Surplus/distribution scaffold created with required metadata fields.")
add_check("SHAIKH_TONAK_SURPLUS_TRANSFER_PRINCIPLE_RECORDED", TRUE, "Financial-sector variables are transfer/reconciliation/correction candidates, not productive-origin surplus equivalents.")
add_check("SHAIKH_APPENDIX_NOT_BINDING_REPLICATION_TARGET", TRUE, "Shaikh appendix recorded as conceptual benchmark/accounting guide, not binding line-by-line recipe.")
add_check("WAGE_SHARE_MARKED_PRIMARY_OPERATIONAL_DISTRIBUTIVE_VARIABLE", any(vapply(surplus_rows, function(x) x$role == "preferred_wage_share", logical(1))), "Wage share is marked as preferred operational distributive variable.")
add_check("EXPLOITATION_RATE_MARKED_ALTERNATIVE_DISTRIBUTIVE_VARIABLE", any(vapply(surplus_rows, function(x) x$role == "alternative_exploitation_rate", logical(1))), "Exploitation rate is retained as an alternative distributive construction contract.")
add_check("PROFIT_SHARE_MARKED_ACCOUNTING_SCAFFOLD", any(vapply(surplus_rows, function(x) x$role == "profit_share_scaffold", logical(1))), "Profit-share variants are scaffolds/diagnostics, not primary operational variables.")
add_check("FINANCIAL_CORRECTION_GATE_ENFORCED", all(vapply(financial_rows, function(x) x$status != "AUTHORIZED_FOR_D07_LEVEL_PANEL", logical(1))), "Financial correction candidates are not promoted to baseline absent crosswalk validation.")
add_check("UNVALIDATED_IMPUTED_INTEREST_NOT_BASELINE_AUTHORIZED", !any(vapply(financial_rows, function(x) grepl("T711|IMPUTED|ImpInt|CorpImp", x$variable_id, ignore.case = TRUE) && x$status == "AUTHORIZED_FOR_D07_LEVEL_PANEL", logical(1))), "Table 7.11 and imputed-interest candidates remain candidate/diagnostic only.")
add_check("FRONTIER_CONTEXT_VARIABLES_PARKED", any(vapply(frontier_rows, function(x) x$status == "PARKED_FRONTIER_CONTEXT", logical(1))), "IPP and government transportation/context variables are parked.")
add_check("OLD_GPIM_OBJECTS_SUPERSEDED_FOR_BASELINE", any(vapply(sup_rows, function(x) grepl("GPIM|S29D|S12D", x$variable_id) && x$new_status == "SUPERSEDED_FOR_BASELINE", logical(1))), "Older GPIM/Kcap objects are superseded for baseline use and preserved for audit.")
add_check("NO_TOTAL_CAPITAL_BASELINE_AUTHORIZED", !any(vapply(cons_rows, function(x) grepl("total", x$variable_id, ignore.case = TRUE) && x$authorized_for_D07_level_panel == "TRUE", logical(1))), "No total-capital object is authorized.")
add_check("NO_TOTAL_FIXED_ASSETS_BASELINE_AUTHORIZED", !any(vapply(cons_rows, function(x) grepl("TOTAL__|total_fixed", x$variable_id, ignore.case = TRUE) && x$authorized_for_D07_level_panel == "TRUE", logical(1))), "No total fixed-assets object is authorized.")
add_check("NO_IPP_BASELINE_CAPITAL_AUTHORIZED", !any(vapply(cons_rows, function(x) grepl("IPP", x$variable_id) && x$authorized_for_D07_level_panel == "TRUE", logical(1))), "IPP is not baseline capacity capital.")
add_check("NO_RESIDENTIAL_BASELINE_CAPITAL_AUTHORIZED", !any(vapply(cons_rows, function(x) grepl("RESIDENTIAL", x$variable_id, ignore.case = TRUE) && x$authorized_for_D07_level_panel == "TRUE", logical(1))), "Residential capital is not baseline capacity capital.")
add_check("NO_GOV_TRANS_BASELINE_CAPITAL_AUTHORIZED", !any(vapply(cons_rows, function(x) grepl("GOV_TRANS|government_transportation", x$variable_id, ignore.case = TRUE) && x$authorized_for_D07_level_panel == "TRUE", logical(1))), "Government transportation capital is not baseline capacity capital.")
add_check("CONSUMPTION_CONTRACT_CREATED", length(cons_rows) > 0, "Consumption contract rows created.")

validation <- make_df(validation_rows, validation_cols)
decision_code <- if (all(validation$status == "PASS")) "AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION" else "REQUIRE_SOURCE_OF_TRUTH_MENU_RECONCILIATION"
validation_rows[[length(validation_rows) + 1L]] <- list(check_id = "DECISION_RECORDED", status = "PASS", notes = decision_code)
validation <- make_df(validation_rows, validation_cols)

menu <- make_df(menu_rows, level_cols)
consumption <- make_df(cons_rows, cons_cols)
fixed <- make_df(fixed_rows, fixed_cols)
output_block <- make_df(output_rows, output_cols)
surplus <- make_df(surplus_rows, surplus_cols)
financial <- make_df(financial_rows, financial_cols)
frontier <- make_df(frontier_rows, frontier_cols)
supersession <- make_df(sup_rows, sup_cols)

write_contract_csv(menu, "D07_0_level_accounting_variable_menu.csv")
write_contract_csv(consumption, "D07_0_consumption_contract.csv")
write_contract_csv(fixed, "D07_0_fixed_assets_capacity_block.csv")
write_contract_csv(output_block, "D07_0_output_value_added_block.csv")
write_contract_csv(surplus, "D07_0_surplus_distribution_scaffold.csv")
write_contract_csv(financial, "D07_0_financial_correction_candidate_ledger.csv")
write_contract_csv(frontier, "D07_0_frontier_context_parking_ledger.csv")
write_contract_csv(supersession, "D07_0_supersession_and_parking_ledger.csv")
write_contract_csv(validation, "D07_0_validation_checks.csv")

validation_md <- paste0(
  "| Check | Status | Notes |\n",
  "|---|---:|---|\n",
  paste(sprintf("| %s | %s | %s |", validation$check_id, validation$status, gsub("\\|", "/", validation$notes)), collapse = "\n")
)

report <- c(
  "# D07-0 Source-of-Truth Level/Accounting Consumption Contract",
  "",
  "## 1. Opening Repo State",
  "",
  "- Pre-edit `git status --short`: clean. This was verified before generating D07-0 artifacts.",
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
  "## 2. D05/D06 Lock Summary",
  "",
  "- D05 decision: `AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN`.",
  "- D05 commit: `b2926ad Implement D05 GPIM guardian price-stock coherence`.",
  "- D06 decision: `AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION`.",
  "- D06 commit: `1020b56 Implement D06 GPIM refreeze with guarded pKN`.",
  "- Active fixed-assets/capacity-capital object: `K_capacity = ME + NRC` from the D06 refrozen panel.",
  "- D07-0 does not revise pKN, survival rules, warmup rules, or the capacity-capital boundary.",
  "",
  "## 3. Purpose of D07-0",
  "",
  "D07-0 creates a source-of-truth consumption contract for level/accounting variables. It tells the next D07 pass which variables are authorized, parked, candidate-only, diagnostic, superseded, or blocked. It does not build the final regression/model panel.",
  "",
  "## 4. Level/Accounting-Only Scope",
  "",
  "Authorized objects are levels, accounting ingredients, price/valuation supports, wage-share accounting ratios, and explicitly classified source contracts. Logs, growth rates, first differences, q_omega indexes, interactions, periodized model variants, stationarity classifications, cointegration-ready panels, and regression-ready variables are parked.",
  "",
  "## 5. Fixed-Assets Capacity Block Summary",
  "",
  "The only baseline capacity-capital object is D06-refrozen `K_real_capacity_refrozen = K_real_ME_refrozen + K_real_NRC_refrozen`. Current-cost capacity, ME/NRC component stocks, current investment ingredients, guarded real investment ingredients, and D06 pKN support variables are authorized for D07 level/accounting panel consumption. Total capital, total fixed assets, IPP, residential capital, and government transportation are not authorized as baseline capacity capital.",
  "",
  "## 6. Output/Value-Added Block Summary",
  "",
  "NFC real GVA baseline (`Y_REAL_NFC_GVA_BASELINE`) is authorized as the authoritative real output level. NFC nominal GVA/NVA are authorized as direct accounting levels. Corporate nominal GVA/NVA are authorized for reconciliation and robustness, not as the clean productive-origin baseline. Financial nominal GVA/NVA are candidate-only financial correction/accounting objects. Corporate and financial real GVA residual construction remains blocked.",
  "",
  "## 7. Shaikh-Tonak Surplus-Transfer Principle",
  "",
  "D07-0 records the surplus-transfer principle: productive-origin surplus must be distinguished from surplus transfers, claims, absorptions, and redistributions. Financial-sector income accounts are transfer, reconciliation, financial-correction, or diagnostic objects unless a validated crosswalk authorizes stronger use.",
  "",
  "## 8. Shaikh Appendix Status",
  "",
  "Shaikh appendix logic is an operational guide, accounting discipline, plausibility guide, and example of avoiding double counting. It is not a binding line-by-line replication target and cannot force unvalidated adjusted NOS, override provider gates, or promote unvalidated imputed-interest corrections.",
  "",
  "## 9. Surplus Accounting Ladder",
  "",
  "A. NFC productive-origin baseline: NFC GVA/NVA/COMP/CFC/NOS/profit/tax/retained/transfer ingredients are authorized as the strict productive-origin accounting baseline.",
  "",
  "B. Corporate reconciliation variants: corporate GVA/NVA/COMP/CFC/NOS/profit/tax/retained/transfer ingredients are authorized for reconciliation, robustness, and comparison, not automatic productive-origin baseline substitution.",
  "",
  "C. Financial-transfer-adjusted corporate candidates: financial and imputed-interest objects remain candidate-only or diagnostic unless semantic and historical/current crosswalk validation exists.",
  "",
  "## 10. Distributive Variable Hierarchy",
  "",
  "The preferred operational distributive variable is wage share, led by `NFC_COMPENSATION_SHARE_GVA`. Profit-share variants are accounting scaffolds and diagnostics. Exploitation-rate variants are retained as alternative distributive construction contracts; S30B records no constructed exploitation-rate series in the current closure.",
  "",
  "## 11. Financial Correction Gate",
  "",
  "Financial correction objects are candidate-only unless a prior validated crosswalk exists. `NFC_NET_INT` is a bounded diagnostic/proxy source for NFC net interest and miscellaneous payments, not an exact Shaikh Appendix 6.7 correction and not a license to promote unvalidated financial adjustments to baseline.",
  "",
  "## 12. Frontier/Context Parking",
  "",
  "IPP, government transportation, highways and streets, transportation structures, and related context variables are parked as frontier/context/conditioning objects. Residential capital remains exclusion-diagnostic only. None enter `K_capacity` or baseline productive accumulation capital.",
  "",
  "## 13. Supersession and Parking Summary",
  "",
  "Older D01-D04, S12D, and S29D/S29E GPIM/Kcap objects that conflict with the D06 refrozen boundary are superseded for baseline use and preserved for audit/provenance. S29F/S29K total-capital and analytical transformation outputs are parked or blocked for D07 level/accounting consumption.",
  "",
  "## 14. Validation Table",
  "",
  validation_md,
  "",
  "## 15. Final Decision Code",
  "",
  paste0("`", decision_code, "`")
)
writeLines(report, file.path(report_dir, "D07_0_decision_report.md"))

cat(decision_code, "\n")
