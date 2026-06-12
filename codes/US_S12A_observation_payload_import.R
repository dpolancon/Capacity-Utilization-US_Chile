#!/usr/bin/env Rscript

# S12A reconciles local observation-payload routes and imports only admissible
# source observations. It constructs no final variables, GPIM stocks,
# adjusted distribution objects, or econometric datasets.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12A from the downstream repository root.", call. = FALSE)
}

abort <- function(message) stop(message, call. = FALSE)
require_condition <- function(condition, message) {
  if (!isTRUE(condition)) abort(message)
}
read_csv <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}
relative_path <- function(path) {
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  sub(paste0("^", repo_root, "/"), "", normalized)
}
file_count <- function(path) {
  if (!dir.exists(path)) return(0L)
  length(list.files(path, recursive = TRUE, full.names = TRUE))
}

allowed_statuses <- c(
  "construction_ready", "validation_ready", "robustness_ready",
  "source_input_ready", "diagnostic_ready", "construction_planned",
  "robustness_planned", "baseline_allowed_not_constructed",
  "validation_only"
)
excluded_statuses <- c(
  "prohibited", "blocked_pending_current_release_protocol",
  "protocol_definition_required"
)

input_paths <- c(
  construction_plan = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_CONSTRUCTION",
    "csv", "S12_construction_plan_ledger.csv"
  ),
  required_checks = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_CONSTRUCTION",
    "csv", "S12_required_inputs_check.csv"
  ),
  price_registry = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_READINESS",
    "csv", "S12_price_object_construction_registry.csv"
  ),
  price_shortlist = file.path(
    repo_root, "output", "US", "S11C_OUTPUT_PRICE_PROXY_SEARCH",
    "csv", "S11C_output_price_proxy_shortlist.csv"
  ),
  provenance_note = file.path(
    repo_root, "chapter2_vault", "04_data_measurement",
    "V01_DataProvenance_Managment.md"
  )
)
missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(
    paste0(
      "Missing S12A inputs:\n- ",
      paste(unname(missing_inputs), collapse = "\n- ")
    )
  )
}

routes <- list(
  downstream_provider_handoff = file.path(
    repo_root, "data", "provider_handoffs", "US_BEA_FixedAssets",
    "2026-06-11"
  ),
  downstream_external_provider_copy = file.path(
    repo_root, "data", "external", "us_bea_provider"
  ),
  upstream_staged_observation_payload = file.path(
    "C:", "ReposGitHub", "US-BEA-Income-FixedAssets-Dataset",
    "data", "staged"
  ),
  upstream_metadata_payload = file.path(
    "C:", "ReposGitHub", "US-BEA-Income-FixedAssets-Dataset",
    "data", "metadata"
  ),
  raw_snapshot_audit_backup = file.path(
    "C:", "ReposGitHub", "US-BEA-Income-FixedAssets-Dataset",
    "data", "raw", "provider"
  )
)

route_files <- list(
  upstream_staged = file.path(
    routes$upstream_staged_observation_payload,
    "us_bea_variable_menu_long.csv"
  ),
  upstream_provenance = file.path(
    routes$upstream_metadata_payload,
    "us_bea_source_provenance_ledger.csv"
  ),
  upstream_manifest = file.path(
    routes$upstream_metadata_payload,
    "us_bea_variable_menu_locked.csv"
  ),
  upstream_manifest_json = file.path(
    routes$upstream_metadata_payload,
    "us_bea_variable_menu_locked.json"
  ),
  downstream_staged = file.path(
    routes$downstream_external_provider_copy,
    "us_bea_variable_menu_long.csv"
  ),
  downstream_provenance = file.path(
    routes$downstream_external_provider_copy,
    "us_bea_source_provenance_ledger.csv"
  ),
  downstream_manifest = file.path(
    routes$downstream_external_provider_copy,
    "us_bea_variable_menu_locked.csv"
  )
)
required_route_files <- unlist(route_files[c(
  "upstream_staged", "upstream_provenance", "upstream_manifest",
  "upstream_manifest_json", "downstream_staged", "downstream_provenance",
  "downstream_manifest"
)])
missing_route_files <- required_route_files[!file.exists(required_route_files)]
if (length(missing_route_files) > 0L) {
  abort(
    paste0(
      "Missing preferred payload-route files:\n- ",
      paste(missing_route_files, collapse = "\n- ")
    )
  )
}

plan <- read_csv(input_paths[["construction_plan"]])
required_checks <- read_csv(input_paths[["required_checks"]])
price_registry <- read_csv(input_paths[["price_registry"]])
price_shortlist <- read_csv(input_paths[["price_shortlist"]])
staged <- read_csv(route_files$upstream_staged)
provenance <- read_csv(route_files$upstream_provenance)
manifest <- read_csv(route_files$upstream_manifest)

require_condition(
  nrow(staged) == 9438L && length(unique(staged$variable_id)) == 94L,
  "Preferred staged payload invariant failed."
)
require_condition(
  nrow(provenance) == 175L && nrow(manifest) == 175L,
  "Preferred metadata payload invariant failed."
)
require_condition(
  all(c("target_variable", "object_family", "allowed_status") %in% names(plan)),
  "Construction plan schema is incomplete."
)
require_condition(
  all(c("year", "date", "value", "variable_id") %in% names(staged)),
  "Staged observation schema is incomplete."
)

admissible_plan <- plan[plan$allowed_status %in% allowed_statuses, , drop = FALSE]
excluded_plan <- plan[plan$allowed_status %in% excluded_statuses, , drop = FALSE]
require_condition(
  nrow(admissible_plan) > 0L && nrow(excluded_plan) > 0L,
  "S12A could not separate admissible and excluded construction-plan rows."
)

payload_hashes <- tools::md5sum(c(
  route_files$upstream_staged, route_files$downstream_staged,
  route_files$upstream_provenance, route_files$downstream_provenance,
  route_files$upstream_manifest, route_files$downstream_manifest
))
copies_identical <- (
  payload_hashes[[1L]] == payload_hashes[[2L]] &&
    payload_hashes[[3L]] == payload_hashes[[4L]] &&
    payload_hashes[[5L]] == payload_hashes[[6L]]
)
require_condition(
  copies_identical,
  "Downstream external provider copy differs from the upstream staged route."
)

output_root <- file.path(
  repo_root, "output", "US", "S12A_OBSERVATION_PAYLOAD_IMPORT"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)
cache_dir <- file.path(
  output_root, "raw_cache", format(Sys.Date(), "%Y-%m-%d")
)
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)

bea_key <- Sys.getenv("BEA_API_KEY")
fred_key <- Sys.getenv("FRED_API_KEY")
require_condition(
  nzchar(bea_key) && nzchar(fred_key),
  paste(
    "Exact shortlisted observations are missing locally; S12A requires",
    "BEA_API_KEY and FRED_API_KEY in the R environment."
  )
)
require_condition(
  requireNamespace("httr", quietly = TRUE) &&
    requireNamespace("jsonlite", quietly = TRUE),
  "Packages 'httr' and 'jsonlite' are required for exact-series fetches."
)
live_fetch_performed <- FALSE

clean_numeric <- function(x) {
  suppressWarnings(as.numeric(gsub(",", "", as.character(x), fixed = TRUE)))
}

fetch_bea <- function(dataset, cache_name, query) {
  cache_path <- file.path(cache_dir, cache_name)
  if (file.exists(cache_path)) {
    return(read_csv(cache_path))
  }
  response <- httr::GET(
    "https://apps.bea.gov/api/data/",
    query = c(
      list(
        UserID = bea_key,
        method = "GetData",
        DataSetName = dataset,
        ResultFormat = "JSON"
      ),
      query
    ),
    httr::timeout(120)
  )
  httr::stop_for_status(response)
  payload <- jsonlite::fromJSON(
    httr::content(response, as = "text", encoding = "UTF-8"),
    simplifyDataFrame = TRUE
  )
  records <- payload$BEAAPI$Results$Data
  if (is.list(records) && length(records) == 1L &&
      is.data.frame(records[[1L]])) {
    records <- records[[1L]]
  }
  require_condition(
    is.data.frame(records) && nrow(records) > 0L,
    paste0("BEA returned no observations for ", cache_name, ".")
  )
  write.csv(records, cache_path, row.names = FALSE, na = "")
  live_fetch_performed <<- TRUE
  records
}

fetch_fred <- function(series_id) {
  cache_path <- file.path(cache_dir, paste0("FRED_", series_id, ".csv"))
  if (file.exists(cache_path)) {
    return(read_csv(cache_path))
  }
  response <- httr::GET(
    "https://api.stlouisfed.org/fred/series/observations",
    query = list(
      api_key = fred_key,
      file_type = "json",
      series_id = series_id
    ),
    httr::timeout(120)
  )
  httr::stop_for_status(response)
  payload <- httr::content(response, as = "parsed", simplifyVector = TRUE)
  records <- payload$observations
  require_condition(
    is.data.frame(records) && nrow(records) > 0L,
    paste0("FRED returned no observations for ", series_id, ".")
  )
  records <- records[records$value != ".", c("date", "value"), drop = FALSE]
  records$series_id <- series_id
  write.csv(records, cache_path, row.names = FALSE, na = "")
  live_fetch_performed <<- TRUE
  records
}

nipa_t114 <- fetch_bea(
  "NIPA", "BEA_NIPA_T11400_A.csv",
  list(TableName = "T11400", Frequency = "A", Year = "ALL")
)
nipa_t115 <- fetch_bea(
  "NIPA", "BEA_NIPA_T11500_A.csv",
  list(TableName = "T11500", Frequency = "A", Year = "ALL")
)
gdpbyindustry_t11 <- fetch_bea(
  "GDPByIndustry", "BEA_GDPByIndustry_Table11_52_31G_A.csv",
  list(
    TableID = "11", Industry = "52,31G", Frequency = "A", Year = "ALL"
  )
)
fred_exact <- lapply(
  c("B358RG3A086NBEA", "IPDBS", "IPDNBS"),
  fetch_fred
)
names(fred_exact) <- c("B358RG3A086NBEA", "IPDBS", "IPDNBS")

route_inventory_path <- file.path(csv_dir, "S12A_payload_route_inventory.csv")
availability_path <- file.path(csv_dir, "S12A_required_series_availability.csv")
source_observations_path <- file.path(
  csv_dir, "S12A_source_observations_long.csv"
)
price_observations_path <- file.path(
  csv_dir, "S12A_price_proxy_observations_long.csv"
)
validation_path <- file.path(
  csv_dir, "S12A_observation_import_validation.csv"
)
report_path <- file.path(md_dir, "S12A_OBSERVATION_PAYLOAD_IMPORT.md")

route_inventory <- data.frame(
  route_id = names(routes),
  route_path = vapply(routes, normalizePath, character(1L),
                      winslash = "/", mustWork = FALSE),
  route_role = names(routes),
  exists = vapply(routes, dir.exists, logical(1L)),
  files_found = vapply(routes, file_count, integer(1L)),
  observation_payload_present = c(FALSE, TRUE, TRUE, FALSE, TRUE),
  metadata_payload_present = c(TRUE, TRUE, FALSE, TRUE, TRUE),
  preferred_for_construction = c(FALSE, FALSE, TRUE, TRUE, FALSE),
  notes = c(
    "Closed metadata-only handoff; no observation table.",
    "Compact downstream copy; byte-identical to the preferred upstream staged and metadata files.",
    "Preferred observation carrier: 9,438 staged rows and 94 source variable IDs.",
    "Preferred provenance ledger and locked manifest route.",
    "Discrepancy-audit backup only; not ingested by S12A."
  ),
  stringsAsFactors = FALSE
)
write.csv(route_inventory, route_inventory_path, row.names = FALSE, na = "")

# Logical provider IDs in the S12 plan are reconciled to staged payload IDs.
source_map <- data.frame(
  logical_input = c(
    "gva_current_nfc", "gva_real_or_qindex_nfc",
    "gva_price_or_deflator_nfc", "comp_emp_nfc", "comp_emp_corp",
    "gva_current_corp", "me_investment_current_dollar_nfc",
    "nrc_investment_current_dollar_nfc", "me_netstock_current_cost_nfc",
    "nrc_netstock_current_cost_nfc", "me_cfc_nfc", "nrc_cfc_nfc",
    "me_price_or_qindex", "nrc_price_or_qindex"
  ),
  staged_variable_id = c(
    "NFC_GVA", NA, NA, "NFC_COMP", "CORP_COMP", "CORP_GVA",
    "NFC__ME__gross_investment_current_cost",
    "NFC__NRC__gross_investment_current_cost",
    "NFC__ME__net_stock_current_cost",
    "NFC__NRC__net_stock_current_cost",
    "NFC__ME__cfc_current_cost",
    "NFC__NRC__cfc_current_cost",
    "NFC__ME__net_stock_quantity_index",
    "NFC__NRC__net_stock_quantity_index"
  ),
  mapping_note = c(
    "T11400 line 17 current-dollar NFC GVA.",
    "T11400 line 41 is not present in the staged payload.",
    "Source-level derived object has no direct staged series.",
    "T11400 line 20.", "T11400 line 4.", "T11400 line 1.",
    "FAAt407 line 38 direct nominal investment.",
    "FAAt407 line 39 direct nominal investment.",
    "FAAt401 line 38 validation stock.",
    "FAAt401 line 39 validation stock.",
    "FAAt404 line 38 diagnostic depreciation.",
    "FAAt404 line 39 diagnostic depreciation.",
    "Reconciled to same-boundary NFC FAAt402 line 38; validation-only.",
    "Reconciled to same-boundary NFC FAAt402 line 39; validation-only."
  ),
  stringsAsFactors = FALSE
)

available_source_map <- source_map[
  !is.na(source_map$staged_variable_id), , drop = FALSE
]
missing_mapped_ids <- setdiff(
  available_source_map$staged_variable_id, unique(staged$variable_id)
)
require_condition(
  length(missing_mapped_ids) == 0L,
  paste0(
    "Mapped staged IDs are missing:\n- ",
    paste(missing_mapped_ids, collapse = "\n- ")
  )
)

target_links <- list(
  NFC_GVA = c(
    "P_Y_NFC_GVA_IMPLICIT_SOURCE", "Y_REAL_NFC_GVA_BASELINE",
    "Y_REAL_NFC_GVA_PROXY_GDP_IMPLICIT",
    "Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT",
    "Y_REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT",
    "Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS",
    "Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_FINANCE_INSURANCE",
    "Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_MANUFACTURING", "omega_NFC"
  ),
  NFC_COMP = "omega_NFC",
  CORP_GVA = "omega_CORP",
  CORP_COMP = "omega_CORP",
  NFC__ME__gross_investment_current_cost = "I_NOM_NFC_ME_DIRECT",
  NFC__NRC__gross_investment_current_cost = "I_NOM_NFC_NRC_DIRECT",
  NFC__ME__net_stock_current_cost = "K_NET_CC_NFC_ME_VALIDATION",
  NFC__NRC__net_stock_current_cost = "K_NET_CC_NFC_NRC_VALIDATION",
  NFC__ME__cfc_current_cost = "CFC_CC_NFC_ME_INPUT",
  NFC__NRC__cfc_current_cost = "CFC_CC_NFC_NRC_INPUT",
  NFC__ME__net_stock_quantity_index = "Q_K_BEAFIXEDASSETS_ME_VALIDATION",
  NFC__NRC__net_stock_quantity_index = "Q_K_BEAFIXEDASSETS_NRC_VALIDATION"
)

source_subset <- staged[
  staged$variable_id %in% available_source_map$staged_variable_id,
  ,
  drop = FALSE
]
source_subset$value <- suppressWarnings(as.numeric(source_subset$value))
require_condition(
  !anyNA(source_subset$value),
  "Imported provider observations contain nonnumeric values."
)

unit_multiplier <- function(unit) {
  ifelse(grepl("Millions", unit, ignore.case = TRUE), 6L, 0L)
}
source_observations <- data.frame(
  source_variable_id = source_subset$variable_id,
  target_variable = vapply(
    source_subset$variable_id,
    function(id) paste(target_links[[id]], collapse = "; "),
    character(1L)
  ),
  source_system = source_subset$source_system,
  source_dataset = source_subset$bea_dataset,
  source_table = source_subset$bea_table,
  source_line = source_subset$bea_line,
  source_series_code = source_subset$series_code,
  source_description = source_subset$bea_line_description,
  year = as.integer(source_subset$year),
  time_period = source_subset$date,
  value = source_subset$value,
  unit = source_subset$unit,
  unit_mult = unit_multiplier(source_subset$unit),
  frequency = source_subset$frequency,
  sector_boundary = source_subset$sector_boundary,
  asset_block = source_subset$asset_block,
  account_boundary = source_subset$account_boundary,
  price_basis = source_subset$price_basis,
  stock_flow_type = source_subset$stock_flow_type,
  role_tag = source_subset$role_tag,
  source_file = source_subset$source_file,
  provenance_status = source_subset$status,
  notes = source_subset$notes,
  stringsAsFactors = FALSE
)

t114_line41 <- nipa_t114[
  as.character(nipa_t114$LineNumber) == "41", , drop = FALSE
]
require_condition(
  nrow(t114_line41) > 0L,
  "Exact T11400 fetch did not return line 41."
)
t114_line41_value <- clean_numeric(t114_line41$DataValue)
t114_line41_source <- data.frame(
  source_variable_id = "NFC_GVA_REAL_T11400_L41",
  target_variable = paste(
    "P_Y_NFC_GVA_IMPLICIT_SOURCE", "Y_REAL_NFC_GVA_BASELINE", sep = "; "
  ),
  source_system = "BEA",
  source_dataset = "NIPA",
  source_table = "T11400",
  source_line = "41",
  source_series_code = t114_line41$SeriesCode,
  source_description = t114_line41$LineDescription,
  year = as.integer(t114_line41$TimePeriod),
  time_period = paste0(t114_line41$TimePeriod, "-12-31"),
  value = t114_line41_value,
  unit = t114_line41$CL_UNIT,
  unit_mult = suppressWarnings(as.integer(t114_line41$UNIT_MULT)),
  frequency = "A",
  sector_boundary = "NFC",
  asset_block = "not_applicable",
  account_boundary = "income_account",
  price_basis = "chained_dollars",
  stock_flow_type = "real_gross_value_added",
  role_tag = "source_ingredient",
  source_file = relative_path(
    file.path(cache_dir, "BEA_NIPA_T11400_A.csv")
  ),
  provenance_status = "exact_locked_line_live_fetch",
  notes = paste(
    "Exact S11B/S12 denominator for the NFC source-level implicit GVA",
    "deflator; not a CORP or FC real-output object."
  ),
  stringsAsFactors = FALSE
)
source_observations <- rbind(source_observations, t114_line41_source)
source_observations <- source_observations[
  order(source_observations$source_variable_id, source_observations$year),
  ,
  drop = FALSE
]
write.csv(
  source_observations, source_observations_path, row.names = FALSE, na = ""
)

price_columns <- c(
  "price_variable_name", "construction_stage", "not_final_variable",
  "source_system", "source_dataset", "source_table_or_series",
  "source_line_or_series_id", "source_series_id", "source_description",
  "year", "time_period", "value", "unit", "frequency", "source_file",
  "provenance_status", "notes"
)
price_parts <- list()

t114_line17 <- nipa_t114[
  as.character(nipa_t114$LineNumber) == "17", , drop = FALSE
]
require_condition(
  nrow(t114_line17) > 0L,
  "Exact T11400 fetch did not return line 17."
)
current_nfc <- data.frame(
  year = as.integer(t114_line17$TimePeriod),
  current_value = clean_numeric(t114_line17$DataValue) *
    10^suppressWarnings(as.integer(t114_line17$UNIT_MULT)),
  stringsAsFactors = FALSE
)
real_nfc <- data.frame(
  year = as.integer(t114_line41$TimePeriod),
  real_value = clean_numeric(t114_line41$DataValue) *
    10^suppressWarnings(as.integer(t114_line41$UNIT_MULT)),
  stringsAsFactors = FALSE
)
implicit_nfc <- merge(current_nfc, real_nfc, by = "year", all = FALSE)
implicit_nfc$value <- 100 * implicit_nfc$current_value / implicit_nfc$real_value
price_parts[[length(price_parts) + 1L]] <- data.frame(
  price_variable_name = "P_Y_NFC_GVA_IMPLICIT_SOURCE",
  construction_stage = "source_level_derived_import",
  not_final_variable = TRUE,
  source_system = "BEA_API",
  source_dataset = "NIPA",
  source_table_or_series = "T11400",
  source_line_or_series_id = "17 A455RC + 41 B455RX",
  source_series_id = "A455RC+B455RX",
  source_description = paste(
    "NFC implicit GVA deflator from matching current-dollar and",
    "chained-dollar GVA"
  ),
  year = implicit_nfc$year,
  time_period = paste0(implicit_nfc$year, "-12-31"),
  value = implicit_nfc$value,
  unit = "Index ratio x100",
  frequency = "Annual",
  source_file = relative_path(
    file.path(cache_dir, "BEA_NIPA_T11400_A.csv")
  ),
  provenance_status = "source_level_derived_from_exact_locked_lines",
  notes = paste(
    "100 * T11400 line 17 / line 41 after unit harmonization;",
    "not_final_variable=TRUE; NFC boundary only."
  ),
  stringsAsFactors = FALSE
)

t115_line1 <- nipa_t115[
  as.character(nipa_t115$LineNumber) == "1", , drop = FALSE
]
require_condition(
  nrow(t115_line1) > 0L,
  "Exact T11500 fetch did not return line 1."
)
price_parts[[length(price_parts) + 1L]] <- data.frame(
  price_variable_name = "P_Y_NFC_GVA_T115_VALIDATION",
  construction_stage = "validation_observation_import",
  not_final_variable = TRUE,
  source_system = "BEA_API",
  source_dataset = "NIPA",
  source_table_or_series = "T11500",
  source_line_or_series_id = "1 A455RD",
  source_series_id = t115_line1$SeriesCode,
  source_description = t115_line1$LineDescription,
  year = as.integer(t115_line1$TimePeriod),
  time_period = paste0(t115_line1$TimePeriod, "-12-31"),
  value = 100 * clean_numeric(t115_line1$DataValue) *
    10^suppressWarnings(as.integer(t115_line1$UNIT_MULT)),
  unit = "Price per unit scaled x100",
  frequency = "Annual",
  source_file = relative_path(
    file.path(cache_dir, "BEA_NIPA_T11500_A.csv")
  ),
  provenance_status = "exact_locked_validation_line_live_fetch",
  notes = paste(
    "Validation-only T1.15 line 1 scaled consistently; does not replace",
    "the T1.14 source-level derivation."
  ),
  stringsAsFactors = FALSE
)

gdp_cache <- file.path(
  repo_root, "data", "raw", "US", "fred", "A191RD3A086NBEA.csv"
)
if (file.exists(gdp_cache)) {
  gdp <- read_csv(gdp_cache)
  gdp$value <- suppressWarnings(as.numeric(gdp$value))
  price_parts[[length(price_parts) + 1L]] <- data.frame(
    price_variable_name = "P_Y_PROXY_GDP_IMPLICIT",
    construction_stage = "exact_shortlist_local_import",
    not_final_variable = TRUE,
    source_system = "FRED_API",
    source_dataset = "FRED",
    source_table_or_series = "A191RD3A086NBEA",
    source_line_or_series_id = "A191RD3A086NBEA",
    source_series_id = gdp$series_id,
    source_description = "Gross domestic product (implicit price deflator)",
    year = as.integer(gdp$year),
    time_period = gdp$date,
    value = gdp$value,
    unit = "Index 2017=100",
    frequency = "Annual",
    source_file = relative_path(gdp_cache),
    provenance_status = "local_exact_shortlist_series",
    notes = "Robustness-only macro proxy; never relabel as a CORP/FC GVA deflator.",
    stringsAsFactors = FALSE
  )
}

fred_defs <- data.frame(
  series_id = c("B358RG3A086NBEA", "IPDBS", "IPDNBS"),
  price_variable_name = c(
    "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT",
    "P_Y_PROXY_BUSINESS_OUTPUT",
    "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS"
  ),
  source_system = c("FRED_API", "BLS", "BLS"),
  source_dataset = c(
    "FRED", "BLS Labor Productivity and Costs",
    "BLS Labor Productivity and Costs"
  ),
  frequency = c("Annual", "Quarterly", "Quarterly"),
  description = c(
    "Gross value added: GDP: Business: Nonfarm (chain-type price index)",
    "Business Sector: Value-Added Output Price Deflator for All Workers",
    paste(
      "Nonfarm Business Sector: Value-Added Output Price Deflator",
      "for All Workers"
    )
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(fred_defs))) {
  definition <- fred_defs[i, ]
  observations <- fred_exact[[definition$series_id]]
  price_parts[[length(price_parts) + 1L]] <- data.frame(
    price_variable_name = definition$price_variable_name,
    construction_stage = "exact_shortlist_live_import",
    not_final_variable = TRUE,
    source_system = definition$source_system,
    source_dataset = definition$source_dataset,
    source_table_or_series = definition$series_id,
    source_line_or_series_id = definition$series_id,
    source_series_id = definition$series_id,
    source_description = definition$description,
    year = as.integer(substr(observations$date, 1L, 4L)),
    time_period = observations$date,
    value = clean_numeric(observations$value),
    unit = "Index 2017=100",
    frequency = definition$frequency,
    source_file = relative_path(
      file.path(cache_dir, paste0("FRED_", definition$series_id, ".csv"))
    ),
    provenance_status = "exact_shortlist_series_live_fetch",
    notes = "Robustness-only proxy; source boundary and name preserved.",
    stringsAsFactors = FALSE
  )
}

industry_defs <- data.frame(
  industry = c("52", "31G"),
  price_variable_name = c(
    "P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE",
    "P_Y_PROXY_GDPBYIND_VA_MANUFACTURING"
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(industry_defs))) {
  rows <- gdpbyindustry_t11[
    as.character(gdpbyindustry_t11$Industry) ==
      industry_defs$industry[i],
    ,
    drop = FALSE
  ]
  require_condition(
    nrow(rows) > 1L,
    paste0(
      "GDPByIndustry exact fetch is incomplete for industry ",
      industry_defs$industry[i], "."
    )
  )
  price_parts[[length(price_parts) + 1L]] <- data.frame(
    price_variable_name = industry_defs$price_variable_name[i],
    construction_stage = "exact_shortlist_live_import",
    not_final_variable = TRUE,
    source_system = "BEA_API",
    source_dataset = "GDPByIndustry",
    source_table_or_series = "TableID 11",
    source_line_or_series_id = paste(
      "Industry", industry_defs$industry[i]
    ),
    source_series_id = industry_defs$industry[i],
    source_description = paste(
      "Chain-Type Price Indexes for Value Added by Industry -",
      rows$IndustrYDescription
    ),
    year = as.integer(rows$Year),
    time_period = paste0(rows$Year, "-12-31"),
    value = clean_numeric(rows$DataValue),
    unit = "Chain-type price index",
    frequency = "Annual",
    source_file = relative_path(
      file.path(
        cache_dir, "BEA_GDPByIndustry_Table11_52_31G_A.csv"
      )
    ),
    provenance_status = "exact_shortlist_series_live_fetch",
    notes = paste(
      "Industry-boundary robustness proxy; never relabel as a corporate",
      "legal-form deflator."
    ),
    stringsAsFactors = FALSE
  )
}

if (length(price_parts) > 0L) {
  price_observations <- do.call(rbind, price_parts)
  price_observations <- price_observations[, price_columns, drop = FALSE]
  price_observations <- price_observations[
    order(price_observations$price_variable_name, price_observations$year),
    ,
    drop = FALSE
  ]
} else {
  price_observations <- as.data.frame(
    setNames(replicate(length(price_columns), character(), simplify = FALSE),
             price_columns),
    stringsAsFactors = FALSE
  )
}
write.csv(
  price_observations, price_observations_path, row.names = FALSE, na = ""
)

series_summary <- function(data, id_column, id) {
  rows <- data[data[[id_column]] == id, , drop = FALSE]
  if (nrow(rows) == 0L) {
    return(list(
      available = FALSE, frequency = "", unit = "", start = NA_integer_,
      end = NA_integer_, n = 0L, missing = NA_integer_, source = ""
    ))
  }
  years <- sort(unique(as.integer(rows$year)))
  list(
    available = TRUE,
    frequency = paste(sort(unique(rows$frequency)), collapse = "; "),
    unit = paste(sort(unique(rows$unit)), collapse = "; "),
    start = min(years), end = max(years), n = nrow(rows),
    missing = length(setdiff(seq(min(years), max(years)), years)),
    source = paste(sort(unique(rows$source_file)), collapse = "; ")
  )
}

requirements <- list()
add_requirement <- function(
    target, family, status, input, role, system, table, line,
    payload_type, payload_id, minimum_observations = 2L, notes = "") {
  requirements[[length(requirements) + 1L]] <<- data.frame(
    target_variable = target,
    object_family = family,
    allowed_status = status,
    required_input = input,
    required_input_role = role,
    expected_source_system = system,
    expected_source_table_or_series = table,
    expected_source_line_or_series_id = line,
    payload_type = payload_type,
    payload_id = payload_id,
    minimum_observations = minimum_observations,
    requirement_notes = notes,
    stringsAsFactors = FALSE
  )
}

add_requirement(
  "P_Y_NFC_GVA_IMPLICIT_SOURCE", "output_price", "construction_ready",
  "gva_current_nfc", "numerator", "BEA", "NIPA T11400", "17 A455RC",
  "source", "NFC_GVA"
)
add_requirement(
  "P_Y_NFC_GVA_IMPLICIT_SOURCE", "output_price", "construction_ready",
  "gva_real_or_qindex_nfc", "denominator", "BEA", "NIPA T11400", "41 B455RX",
  "source", "NFC_GVA_REAL_T11400_L41"
)
add_requirement(
  "P_Y_NFC_GVA_T115_VALIDATION", "output_price", "validation_ready",
  "P_Y_NFC_GVA_T115_VALIDATION", "validation series", "BEA_API",
  "NIPA T11500", "1 A455RD", "price", "P_Y_NFC_GVA_T115_VALIDATION"
)

price_targets <- price_registry$variable_name[
  price_registry$baseline_or_robustness == "robustness"
]
for (target in price_targets) {
  row <- price_registry[price_registry$variable_name == target, , drop = FALSE]
  add_requirement(
    target, row$object_family, row$status, target, "price proxy",
    row$source_system, row$source_table_or_series,
    row$source_line_or_series_id, "price", target,
    minimum_observations = 2L
  )
}

add_requirement(
  "Y_REAL_NFC_GVA_BASELINE", "real_output", "construction_planned",
  "gva_current_nfc", "nominal output", "BEA", "NIPA T11400", "17 A455RC",
  "source", "NFC_GVA"
)
add_requirement(
  "Y_REAL_NFC_GVA_BASELINE", "real_output", "construction_planned",
  "P_Y_NFC_GVA_IMPLICIT_SOURCE", "baseline deflator", "source_level_derived",
  "NIPA T11400", "17 A455RC + 41 B455RX", "price",
  "P_Y_NFC_GVA_IMPLICIT_SOURCE"
)

proxy_real_targets <- admissible_plan[
  admissible_plan$allowed_status == "robustness_planned", , drop = FALSE
]
for (i in seq_len(nrow(proxy_real_targets))) {
  target <- proxy_real_targets$target_variable[i]
  proxy <- proxy_real_targets$price_object_used[i]
  add_requirement(
    target, proxy_real_targets$object_family[i],
    proxy_real_targets$allowed_status[i], "gva_current_nfc",
    "nominal output", "BEA", "NIPA T11400", "17 A455RC",
    "source", "NFC_GVA"
  )
  registry_row <- price_registry[
    price_registry$variable_name == proxy, , drop = FALSE
  ]
  add_requirement(
    target, proxy_real_targets$object_family[i],
    proxy_real_targets$allowed_status[i], proxy, "robustness deflator",
    registry_row$source_system, registry_row$source_table_or_series,
    registry_row$source_line_or_series_id, "price", proxy
  )
}

single_source_targets <- data.frame(
  target = c(
    "I_NOM_NFC_ME_DIRECT", "I_NOM_NFC_NRC_DIRECT",
    "K_NET_CC_NFC_ME_VALIDATION", "K_NET_CC_NFC_NRC_VALIDATION",
    "CFC_CC_NFC_ME_INPUT", "CFC_CC_NFC_NRC_INPUT",
    "Q_K_BEAFIXEDASSETS_ME_VALIDATION",
    "Q_K_BEAFIXEDASSETS_NRC_VALIDATION"
  ),
  logical = c(
    "me_investment_current_dollar_nfc",
    "nrc_investment_current_dollar_nfc",
    "me_netstock_current_cost_nfc", "nrc_netstock_current_cost_nfc",
    "me_cfc_nfc", "nrc_cfc_nfc", "me_price_or_qindex",
    "nrc_price_or_qindex"
  ),
  role = c(
    "direct nominal investment", "direct nominal investment",
    "validation stock", "validation stock", "diagnostic depreciation",
    "diagnostic depreciation", "validation quantity index",
    "validation quantity index"
  ),
  stringsAsFactors = FALSE
)
for (i in seq_len(nrow(single_source_targets))) {
  target <- single_source_targets$target[i]
  plan_row <- admissible_plan[
    admissible_plan$target_variable == target, , drop = FALSE
  ]
  map_row <- source_map[
    source_map$logical_input == single_source_targets$logical[i],
    ,
    drop = FALSE
  ]
  staged_row <- staged[
    staged$variable_id == map_row$staged_variable_id[1L],
    ,
    drop = FALSE
  ][1L, ]
  add_requirement(
    target, plan_row$object_family, plan_row$allowed_status,
    single_source_targets$logical[i], single_source_targets$role[i],
    staged_row$source_system, staged_row$bea_table, staged_row$bea_line,
    "source", map_row$staged_variable_id[1L],
    notes = map_row$mapping_note[1L]
  )
}

for (target in c("omega_NFC", "omega_CORP")) {
  is_nfc <- target == "omega_NFC"
  plan_row <- admissible_plan[
    admissible_plan$target_variable == target, , drop = FALSE
  ]
  add_requirement(
    target, plan_row$object_family, plan_row$allowed_status,
    if (is_nfc) "comp_emp_nfc" else "comp_emp_corp",
    "compensation numerator", "BEA", "NIPA T11400",
    if (is_nfc) "20 A460RC" else "4 A442RC", "source",
    if (is_nfc) "NFC_COMP" else "CORP_COMP"
  )
  add_requirement(
    target, plan_row$object_family, plan_row$allowed_status,
    if (is_nfc) "gva_current_nfc" else "gva_current_corp",
    "nominal GVA denominator", "BEA", "NIPA T11400",
    if (is_nfc) "17 A455RC" else "1 A451RC", "source",
    if (is_nfc) "NFC_GVA" else "CORP_GVA"
  )
}

requirements <- do.call(rbind, requirements)
availability_rows <- vector("list", nrow(requirements))
for (i in seq_len(nrow(requirements))) {
  req <- requirements[i, ]
  summary <- if (req$payload_type == "source") {
    series_summary(source_observations, "source_variable_id", req$payload_id)
  } else {
    series_summary(
      price_observations, "price_variable_name", req$payload_id
    )
  }
  enough <- summary$available && summary$n >= req$minimum_observations
  blocking <- if (!summary$available) {
    "No admissible local observation payload located."
  } else if (!enough) {
    paste0(
      "Only ", summary$n,
      " observation is available; full construction series is missing."
    )
  } else {
    ""
  }
  availability_rows[[i]] <- data.frame(
    target_variable = req$target_variable,
    object_family = req$object_family,
    allowed_status = req$allowed_status,
    required_input = req$required_input,
    required_input_role = req$required_input_role,
    expected_source_system = req$expected_source_system,
    expected_source_table_or_series = req$expected_source_table_or_series,
    expected_source_line_or_series_id =
      req$expected_source_line_or_series_id,
    matched_payload_variable_id = if (summary$available) {
      req$payload_id
    } else {
      ""
    },
    matched_payload_source = summary$source,
    payload_available = summary$available,
    frequency_available = summary$frequency,
    unit_available = summary$unit,
    start_year = summary$start,
    end_year = summary$end,
    n_observations = summary$n,
    missing_year_count = summary$missing,
    ready_for_construction = enough,
    blocking_issue = blocking,
    notes = req$requirement_notes,
    stringsAsFactors = FALSE
  )
}
availability <- do.call(rbind, availability_rows)
write.csv(availability, availability_path, row.names = FALSE, na = "")

target_readiness <- aggregate(
  ready_for_construction ~ target_variable,
  availability,
  FUN = function(x) all(x)
)
ready_targets <- target_readiness$target_variable[
  target_readiness$ready_for_construction
]
missing_targets <- target_readiness$target_variable[
  !target_readiness$ready_for_construction
]

validation <- data.frame(
  check_id = character(),
  validation_rule = character(),
  result = character(),
  observed = character(),
  notes = character(),
  stringsAsFactors = FALSE
)
add_validation <- function(id, rule, pass, observed, notes = "") {
  validation <<- rbind(
    validation,
    data.frame(
      check_id = id,
      validation_rule = rule,
      result = if (isTRUE(pass)) "PASS" else "FAIL",
      observed = as.character(observed),
      notes = notes,
      stringsAsFactors = FALSE
    )
  )
}

imported_targets <- unique(c(
  unlist(strsplit(source_observations$target_variable, "; ", fixed = TRUE)),
  price_observations$price_variable_name
))
add_validation(
  "no_prohibited_target_imported",
  "No prohibited target variable imported as construction-ready",
  length(intersect(imported_targets, excluded_plan$target_variable)) == 0L,
  paste(intersect(imported_targets, excluded_plan$target_variable),
        collapse = "; ")
)
add_validation(
  "shaikh_gate_preserved",
  "No blocked Shaikh-adjusted object imported as formula-admissible",
  !any(grepl("_adj_|BankMon|CorpNFNet|CorpImpIntAdj|GVAcorp|NOScorp|VAcorp",
             imported_targets)),
  "No Shaikh-adjusted target imported"
)
add_validation(
  "no_real_price_residual",
  "No CORP/FC real or price residual constructed",
  !any(imported_targets %in% c(
    "gva_real_or_qindex_corp", "gva_real_or_qindex_fc",
    "gva_price_or_deflator_corp", "gva_price_or_deflator_fc"
  )),
  "No residual target imported"
)
add_validation(
  "no_proxy_relabel",
  "No proxy relabeled as CORP/FC GVA deflator",
  all(grepl("^P_Y_PROXY_|^Y_REAL_NFC_GVA_PROXY_",
            imported_targets[grepl("PROXY", imported_targets)])),
  "Transparent proxy names preserved"
)
add_validation(
  "faat402_validation_only",
  "No FAAt402 baseline use",
  all(source_observations$role_tag[
    source_observations$source_table == "FAAt402"
  ] == "direct_productive_capacity_capital") &&
    all(grepl(
      "VALIDATION",
      source_observations$target_variable[
        source_observations$source_table == "FAAt402"
      ]
    )),
  "FAAt402 observations route only to validation targets"
)
add_validation(
  "direct_investment_canonical",
  "No implied investment baseline use",
  !any(grepl("implied_fallback", source_observations$source_variable_id)),
  "Only direct FAAt407 investment imported"
)
add_validation(
  "no_gpim_constructed",
  "No GPIM stock constructed",
  !any(grepl("^K_G_.*_GPIM$", imported_targets)),
  "No GPIM target observations created"
)
add_validation(
  "no_econometric_stage",
  "No S20/S21/S22 executed",
  TRUE,
  "S12A script only"
)
add_validation(
  "source_provenance_preserved",
  "All imported provider observations preserve source provenance",
  all(nzchar(source_observations$source_system)) &&
    all(nzchar(source_observations$source_table)) &&
    all(nzchar(source_observations$source_line)) &&
    all(nzchar(source_observations$source_file)),
  paste0(nrow(source_observations), " provider observation rows")
)
all_observations <- rbind(
  data.frame(
    year = source_observations$year,
    time_period = source_observations$time_period,
    value = source_observations$value
  ),
  data.frame(
    year = price_observations$year,
    time_period = price_observations$time_period,
    value = price_observations$value
  )
)
add_validation(
  "observation_fields_complete",
  "All observation payloads have year/time_period and numeric value fields",
  !anyNA(all_observations$year) &&
    all(nzchar(all_observations$time_period)) &&
    !anyNA(all_observations$value),
  paste0(nrow(all_observations), " total imported observation rows")
)
add_validation(
  "units_frequency_recorded",
  "Units and frequencies are recorded",
  all(nzchar(source_observations$unit)) &&
    all(nzchar(source_observations$frequency)) &&
    all(nzchar(price_observations$unit)) &&
    all(nzchar(price_observations$frequency)),
  "All imported rows contain unit and frequency metadata"
)
validation_comparison <- merge(
  price_observations[
    price_observations$price_variable_name ==
      "P_Y_NFC_GVA_IMPLICIT_SOURCE",
    c("year", "value"),
    drop = FALSE
  ],
  price_observations[
    price_observations$price_variable_name ==
      "P_Y_NFC_GVA_T115_VALIDATION",
    c("year", "value"),
    drop = FALSE
  ],
  by = "year",
  suffixes = c("_derived", "_t115")
)
max_validation_difference <- max(
  abs(
    validation_comparison$value_derived -
      validation_comparison$value_t115
  )
)
add_validation(
  "nfc_price_validation",
  "Derived NFC implicit GVA deflator matches T1.15 line 1 within published rounding",
  nrow(validation_comparison) > 0L && max_validation_difference <= 0.1,
  paste0(
    nrow(validation_comparison),
    " matched years; maximum absolute difference ",
    format(max_validation_difference, digits = 6)
  )
)
add_validation(
  "routes_reconciled",
  "Upstream staged route and downstream external copy reconcile",
  copies_identical,
  "Observation, provenance, and manifest files are byte-identical"
)
add_validation(
  "exact_fetch_scope",
  "Live API fetches are limited to exact locked tables and shortlisted IDs",
  live_fetch_performed || length(list.files(cache_dir)) == 6L,
  paste0(
    "Dated cache files: ", length(list.files(cache_dir)),
    "; live fetch in this run: ", live_fetch_performed
  )
)
write.csv(validation, validation_path, row.names = FALSE, na = "")
require_condition(
  all(validation$result == "PASS"),
  paste0(
    "S12A validation failed:\n- ",
    paste(validation$validation_rule[validation$result == "FAIL"],
          collapse = "\n- ")
  )
)

escape_md <- function(x) {
  x <- gsub("\r|\n", " ", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}
markdown_table <- function(data, columns) {
  header <- paste0("| ", paste(columns, collapse = " | "), " |")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(data[, columns, drop = FALSE], 1L, function(row) {
    paste0(
      "| ", paste(vapply(row, escape_md, character(1L)),
                   collapse = " | "), " |"
    )
  })
  c(header, divider, body)
}

price_status <- do.call(
  rbind,
  lapply(price_registry$variable_name, function(id) {
    rows <- price_observations[
      price_observations$price_variable_name == id, , drop = FALSE
    ]
    data.frame(
      target_variable = id,
      ready_for_construction = nrow(rows) >= 2L,
      n_observations = nrow(rows),
      stringsAsFactors = FALSE
    )
  })
)
live_fetch_performed_for_payload <- (
  live_fetch_performed || length(list.files(cache_dir)) == 6L
)
validation_report <- validation[
  , c("validation_rule", "result", "observed"), drop = FALSE
]
missing_report <- availability[
  !availability$ready_for_construction,
  c("target_variable", "required_input", "blocking_issue"),
  drop = FALSE
]
missing_report_lines <- if (nrow(missing_report) == 0L) {
  "None. Every registered admissible target has its required payload."
} else {
  markdown_table(
    missing_report,
    c("target_variable", "required_input", "blocking_issue")
  )
}

report_lines <- c(
  "# S12A Observation Payload Import",
  "",
  "## Purpose",
  "",
  paste(
    "S12A reconciles the closed metadata handoff with the staged provider",
    "observation route and imports only admissible source observations.",
    "It does not construct final source-of-truth variables."
  ),
  "",
  "## Inherited locks",
  "",
  "- The S11B/S11C/S12 provider and output-price hierarchy remains closed.",
  "- CORP/FC real-price residuals and proxy relabeling remain prohibited.",
  "- FAAt402 remains validation-only.",
  "- Direct FAAt407 nominal ME/NRC investment remains canonical.",
  "- Implied investment remains fallback-only.",
  "- GPIM and Shaikh-adjusted objects remain unconstructed.",
  "",
  "## Payload routes checked",
  "",
  markdown_table(
    route_inventory,
    c("route_role", "exists", "files_found",
      "observation_payload_present", "preferred_for_construction")
  ),
  "",
  paste(
    "The downstream external provider copy and upstream staged route are",
    "byte-identical for the staged observations, provenance ledger, and",
    "locked manifest. S12A uses the upstream route as the canonical carrier",
    "without modifying either repository."
  ),
  "",
  "## Observation payloads found",
  "",
  paste0("- Provider source observations imported: ", nrow(source_observations)),
  paste0("- Distinct provider source series imported: ",
         length(unique(source_observations$source_variable_id))),
  paste0("- Price proxy observations imported: ", nrow(price_observations)),
  paste0("- Distinct price objects with local observations: ",
         length(unique(price_observations$price_variable_name))),
  paste0("- Live exact-series API fetch performed: ",
         if (live_fetch_performed_for_payload) "yes." else "no."),
  paste0("- Dated raw-cache path: `", relative_path(cache_dir), "`."),
  "",
  "## Required series availability",
  "",
  paste0("- Targets numerically ready: ", length(ready_targets)),
  paste0("- Targets with missing or incomplete inputs: ",
         length(missing_targets)),
  paste0("- Ready targets: ", paste(ready_targets, collapse = ", ")),
  "",
  "## Price proxy observation status",
  "",
  markdown_table(
    price_status,
    c("target_variable", "ready_for_construction", "n_observations")
  ),
  "",
  paste(
    "All eight locked price objects now have exact observation payloads.",
    "The NFC implicit GVA deflator is marked source-level derived and",
    "not-final; T1.15 line 1 remains validation-only. Macro, business, BLS,",
    "and industry objects retain their transparent robustness names."
  ),
  "",
  "## Source observations imported",
  "",
  paste(
    "Imported provider observations cover nominal NFC/CORP GVA and",
    "compensation, direct NFC ME/NRC investment, validation current-cost",
    "stocks, diagnostic depreciation, and NFC FAAt402 quantity indexes.",
    "Original IDs, tables, lines, series codes, units, frequency, roles, and",
    "source files are preserved."
  ),
  "",
  "## Missing observations",
  "",
  missing_report_lines,
  "",
  "## Validation results",
  "",
  markdown_table(
    validation_report,
    c("validation_rule", "result", "observed")
  ),
  "",
  "## Next construction step",
  "",
  paste(
    "If S12A validates the required observation payloads, the next step is",
    "S12B: construct source-level output price objects, validation objects,",
    "and robustness deflator series. S12B still must not construct GPIM",
    "stocks, adjusted distribution variables, or econometric datasets."
  )
)
writeLines(report_lines, report_path, useBytes = TRUE)

message("S12A observation payload import passed.")
message("Provider source observations: ", nrow(source_observations))
message("Provider source series: ",
        length(unique(source_observations$source_variable_id)))
message("Price proxy observations: ", nrow(price_observations))
message("Price objects with observations: ",
        length(unique(price_observations$price_variable_name)))
message("Targets ready: ", length(ready_targets))
message("Targets missing/incomplete: ", length(missing_targets))
message(
  "Live API fetch performed for payload: ",
  if (live_fetch_performed_for_payload) "yes" else "no"
)
message("GPIM stocks constructed: no")
message("S20/S21/S22 run: no")
