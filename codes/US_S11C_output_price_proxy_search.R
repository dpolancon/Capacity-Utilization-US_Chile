#!/usr/bin/env Rscript

# S11C searches and classifies output-price proxies without reopening the
# provider menu or constructing downstream real/econometric variables.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S11C from the downstream repository root.", call. = FALSE)
}

s11b_ledger_path <- file.path(
  repo_root, "output", "US", "S11B_NIPA_HANDBOOK_CROSSWALK",
  "csv", "S11B_handbook_crosswalk_ledger.csv"
)
handoff_dir <- file.path(
  repo_root, "data", "provider_handoffs", "US_BEA_FixedAssets", "2026-06-11"
)
provider_menu_path <- file.path(handoff_dir, "ch2_master_variable_menu.csv")

output_root <- file.path(
  repo_root, "output", "US", "S11C_OUTPUT_PRICE_PROXY_SEARCH"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

ledger_path <- file.path(csv_dir, "S11C_output_price_proxy_ledger.csv")
shortlist_path <- file.path(csv_dir, "S11C_output_price_proxy_shortlist.csv")
fred_raw_path <- file.path(csv_dir, "S11C_fred_output_price_raw_candidates.csv")
bea_raw_path <- file.path(csv_dir, "S11C_bea_output_price_raw_candidates.csv")
report_path <- file.path(md_dir, "S11C_OUTPUT_PRICE_PROXY_SEARCH.md")

required_inputs <- c(s11b_ledger_path, provider_menu_path)
missing_inputs <- required_inputs[!file.exists(required_inputs)]
if (length(missing_inputs) > 0L) {
  stop(
    paste0("Missing S11C inputs:\n- ", paste(missing_inputs, collapse = "\n- ")),
    call. = FALSE
  )
}

s11b <- read.csv(
  s11b_ledger_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = character()
)
provider_menu <- read.csv(
  provider_menu_path,
  stringsAsFactors = FALSE,
  check.names = FALSE,
  na.strings = character()
)

required_s11b_decisions <- c(
  "source_level_derived_confirmed",
  "validation_only_confirmed",
  "unresolved_true_absence",
  "no_baseline_change"
)
if (!all(s11b$decision %in% required_s11b_decisions) ||
    any(s11b$decision == "provider_patch_required")) {
  stop("S11B is not in the locked no-provider-patch state.", call. = FALSE)
}

bea_key <- Sys.getenv("BEA_API_KEY")
fred_key <- Sys.getenv("FRED_API_KEY")
if (!nzchar(bea_key) || !nzchar(fred_key)) {
  stop("S11C requires BEA_API_KEY and FRED_API_KEY for live search.",
       call. = FALSE)
}
if (!requireNamespace("httr", quietly = TRUE)) {
  stop("Package 'httr' is required.", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required.", call. = FALSE)
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

clean_text <- function(x) {
  trimws(gsub("[[:space:]]+", " ", as.character(x %||% "")))
}

fred_search <- function(search_text, limit = 20L) {
  response <- httr::GET(
    "https://api.stlouisfed.org/fred/series/search",
    query = list(
      api_key = fred_key,
      file_type = "json",
      search_text = search_text,
      limit = limit,
      order_by = "search_rank"
    ),
    httr::timeout(120)
  )
  httr::stop_for_status(response)
  payload <- httr::content(response, as = "parsed", simplifyVector = FALSE)
  records <- payload$seriess
  if (is.null(records) || length(records) == 0L) return(data.frame())
  do.call(rbind, lapply(records, function(x) {
    data.frame(
      search_text = search_text,
      series_id = as.character(x$id %||% ""),
      title = clean_text(x$title),
      frequency = clean_text(x$frequency),
      units = clean_text(x$units),
      seasonal_adjustment = clean_text(x$seasonal_adjustment),
      observation_start = as.character(x$observation_start %||% ""),
      observation_end = as.character(x$observation_end %||% ""),
      popularity = suppressWarnings(as.integer(x$popularity %||% NA_character_)),
      notes = clean_text(x$notes),
      retrieved_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
      stringsAsFactors = FALSE
    )
  }))
}

fred_series <- function(series_id) {
  response <- httr::GET(
    "https://api.stlouisfed.org/fred/series",
    query = list(
      api_key = fred_key,
      file_type = "json",
      series_id = series_id
    ),
    httr::timeout(120)
  )
  httr::stop_for_status(response)
  payload <- httr::content(response, as = "parsed", simplifyVector = FALSE)
  x <- payload$seriess[[1L]]
  data.frame(
    series_id = as.character(x$id %||% ""),
    title = clean_text(x$title),
    frequency = clean_text(x$frequency),
    units = clean_text(x$units),
    seasonal_adjustment = clean_text(x$seasonal_adjustment),
    observation_start = as.character(x$observation_start %||% ""),
    observation_end = as.character(x$observation_end %||% ""),
    notes = clean_text(x$notes),
    stringsAsFactors = FALSE
  )
}

bea_parameter_values <- function(dataset, parameter) {
  response <- httr::GET(
    "https://apps.bea.gov/api/data/",
    query = list(
      UserID = bea_key,
      method = "GetParameterValues",
      DataSetName = dataset,
      ParameterName = parameter,
      ResultFormat = "JSON"
    ),
    httr::timeout(120)
  )
  httr::stop_for_status(response)
  payload <- jsonlite::fromJSON(
    httr::content(response, as = "text", encoding = "UTF-8"),
    simplifyDataFrame = TRUE
  )
  records <- payload$BEAAPI$Results$ParamValue
  data.frame(
    dataset = dataset,
    parameter = parameter,
    key = as.character(records$Key),
    description = vapply(records$Desc, clean_text, character(1L)),
    retrieved_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    stringsAsFactors = FALSE
  )
}

bea_gdpbyindustry <- function(table_id, industries, year = "2024") {
  response <- httr::GET(
    "https://apps.bea.gov/api/data/",
    query = list(
      UserID = bea_key,
      method = "GetData",
      DataSetName = "GDPByIndustry",
      TableID = table_id,
      Industry = paste(industries, collapse = ","),
      Frequency = "A",
      Year = year,
      ResultFormat = "JSON"
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
  data.frame(
    dataset = "GDPByIndustry",
    table_id = as.character(records$TableID),
    industry = as.character(records$Industry),
    industry_description = vapply(
      records$IndustrYDescription, clean_text, character(1L)
    ),
    frequency = "Annual",
    year = as.character(records$Year),
    data_value = as.character(records$DataValue),
    note_ref = as.character(records$NoteRef),
    retrieved_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    stringsAsFactors = FALSE
  )
}

fred_queries <- c(
  "gross domestic product implicit price deflator",
  "gross domestic product chain-type price index",
  "gross domestic business price index",
  "business sector value-added output price deflator",
  "nonfarm business value-added output price deflator",
  "gross value added chain-type price index",
  "GDPByIndustry value added chain-type price index",
  "GDPByIndustry gross output chain-type price index",
  "finance and insurance value added price index",
  "finance and insurance gross output price index",
  "producer price index final demand",
  "producer price index financial services",
  "private nonresidential equipment chain-type price index",
  "private nonresidential structures chain-type price index"
)

fred_parts <- lapply(fred_queries, function(query) {
  result <- fred_search(query)
  Sys.sleep(0.2)
  result
})
fred_raw <- do.call(rbind, fred_parts)
fred_raw <- unique(fred_raw)
fred_raw <- fred_raw[order(fred_raw$search_text, -fred_raw$popularity), , drop = FALSE]
write.csv(fred_raw, fred_raw_path, row.names = FALSE, na = "")

bea_tables <- bea_parameter_values("GDPByIndustry", "TableID")
bea_industries <- bea_parameter_values("GDPByIndustry", "Industry")
bea_candidate_tables <- bea_tables[
  bea_tables$key %in% c("8", "10", "11", "15", "16", "18", "208"),
  ,
  drop = FALSE
]
bea_candidate_industries <- bea_industries[
  bea_industries$key %in% c("GDP", "II", "31G", "52", "FIRE"),
  ,
  drop = FALSE
]
bea_data <- rbind(
  bea_gdpbyindustry(11L, c("31G", "52", "FIRE")),
  bea_gdpbyindustry(18L, c("II", "31G", "52", "FIRE"))
)
bea_table_descriptions <- setNames(
  bea_candidate_tables$description,
  bea_candidate_tables$key
)
bea_raw <- bea_data
bea_raw$description <- unname(bea_table_descriptions[bea_raw$table_id])
bea_raw <- bea_raw[
  order(as.integer(bea_raw$table_id), bea_raw$industry),
  ,
  drop = FALSE
]
write.csv(bea_raw, bea_raw_path, row.names = FALSE, na = "")

ledger_columns <- c(
  "candidate_variable_id", "candidate_label", "source_system",
  "source_dataset", "source_table_or_series", "source_line_or_series_id",
  "source_title", "source_description", "source_units", "source_frequency",
  "source_start", "source_end", "source_url_or_query",
  "output_object_type", "price_object_type", "boundary_type",
  "sector_boundary_claimed", "boundary_distance_from_target",
  "target_use_case", "same_boundary_match", "allowed_as_baseline",
  "allowed_as_validation", "allowed_as_proxy", "allowed_as_robustness",
  "allowed_as_diagnostic", "recommended_variable_name", "recommended_role",
  "decision", "limitations", "notes"
)

ledger_rows <- list()

add_candidate <- function(
    candidate_variable_id, candidate_label, source_system, source_dataset,
    source_table_or_series, source_line_or_series_id, source_title,
    source_description, source_units, source_frequency, source_start,
    source_end, source_url_or_query, output_object_type, price_object_type,
    boundary_type, sector_boundary_claimed, boundary_distance_from_target,
    target_use_case, same_boundary_match, allowed_as_baseline,
    allowed_as_validation, allowed_as_proxy, allowed_as_robustness,
    allowed_as_diagnostic, recommended_variable_name, recommended_role,
    decision, limitations, notes) {
  ledger_rows[[length(ledger_rows) + 1L]] <<- data.frame(
    candidate_variable_id, candidate_label, source_system, source_dataset,
    source_table_or_series, source_line_or_series_id, source_title,
    source_description, source_units, source_frequency, source_start,
    source_end, source_url_or_query, output_object_type, price_object_type,
    boundary_type, sector_boundary_claimed, boundary_distance_from_target,
    target_use_case, same_boundary_match,
    allowed_as_baseline = as.logical(allowed_as_baseline),
    allowed_as_validation = as.logical(allowed_as_validation),
    allowed_as_proxy = as.logical(allowed_as_proxy),
    allowed_as_robustness = as.logical(allowed_as_robustness),
    allowed_as_diagnostic = as.logical(allowed_as_diagnostic),
    recommended_variable_name, recommended_role, decision, limitations, notes,
    stringsAsFactors = FALSE
  )
}

add_fred_candidate <- function(
    series_id, candidate_variable_id, recommended_variable_name,
    recommended_role, output_object_type, price_object_type, boundary_type,
    sector_boundary_claimed, boundary_distance_from_target, target_use_case,
    allowed_as_proxy, allowed_as_robustness, allowed_as_diagnostic, decision,
    limitations, source_system = "FRED_API", source_dataset = "FRED",
    allowed_as_validation = FALSE) {
  x <- fred_series(series_id)
  add_candidate(
    candidate_variable_id = candidate_variable_id,
    candidate_label = x$title,
    source_system = source_system,
    source_dataset = source_dataset,
    source_table_or_series = series_id,
    source_line_or_series_id = series_id,
    source_title = x$title,
    source_description = x$notes,
    source_units = x$units,
    source_frequency = x$frequency,
    source_start = x$observation_start,
    source_end = x$observation_end,
    source_url_or_query = paste0(
      "https://fred.stlouisfed.org/series/", series_id
    ),
    output_object_type = output_object_type,
    price_object_type = price_object_type,
    boundary_type = boundary_type,
    sector_boundary_claimed = sector_boundary_claimed,
    boundary_distance_from_target = boundary_distance_from_target,
    target_use_case = target_use_case,
    same_boundary_match = FALSE,
    allowed_as_baseline = FALSE,
    allowed_as_validation = allowed_as_validation,
    allowed_as_proxy = allowed_as_proxy,
    allowed_as_robustness = allowed_as_robustness,
    allowed_as_diagnostic = allowed_as_diagnostic,
    recommended_variable_name = recommended_variable_name,
    recommended_role = recommended_role,
    decision = decision,
    limitations = limitations,
    notes = "Proxy classification does not alter S11B provider conclusions."
  )
}

add_candidate(
  "nfc_gva_implicit_source",
  "NFC GVA implicit price deflator from matching current and real GVA",
  "BEA_API", "NIPA", "T11400", "17 A455RC + 41 B455RX",
  "Gross value added of nonfinancial corporate business",
  "Source-level same-boundary implicit deflator.",
  "Index after unit harmonization", "Annual and Quarterly", "1929", "2025",
  paste0(
    "https://apps.bea.gov/api/data/?UserID=${BEA_API_KEY}",
    "&method=GetData&DataSetName=NIPA&TableName=T11400",
    "&Frequency=A&Year=ALL&ResultFormat=JSON"
  ),
  "GVA", "implicit_price_deflator", "same_boundary", "NFC", "exact",
  "NFC baseline output-price normalization", TRUE, TRUE, TRUE, FALSE, FALSE,
  TRUE, "P_Y_NFC_GVA_IMPLICIT_SOURCE", "baseline_source",
  "same_boundary_source_confirmed", "Available only for NFC.",
  "S11B-confirmed source-level derivation."
)

add_candidate(
  "nfc_gva_t115_validation",
  "Price per unit of real GVA of nonfinancial corporate business",
  "BEA_API", "NIPA", "T11500", "1 A455RD",
  "Price per unit of real gross value added of nonfinancial corporate business",
  "Direct BEA validation counterpart for the NFC current/real GVA ratio.",
  "Chained-dollar IPD ratio", "Annual and Quarterly", "1947", "2025",
  paste0(
    "https://apps.bea.gov/api/data/?UserID=${BEA_API_KEY}",
    "&method=GetData&DataSetName=NIPA&TableName=T11500",
    "&Frequency=A&Year=ALL&ResultFormat=JSON"
  ),
  "GVA", "price_per_unit", "same_boundary", "NFC", "exact",
  "Validate NFC implicit GVA deflator", TRUE, FALSE, TRUE, FALSE, FALSE, TRUE,
  "P_Y_NFC_GVA_T115_VALIDATION", "validation_only",
  "validation_only_confirmed",
  "Validation counterpart, not an independent CORP or FC deflator.",
  "Multiply the price-per-unit ratio by 100 for index-scale comparison."
)

add_fred_candidate(
  "A191RD3A086NBEA", "gdp_implicit_price_deflator_annual",
  "P_Y_PROXY_GDP_IMPLICIT", "robustness_deflator", "GDP",
  "implicit_price_deflator", "macro_economy_wide", "total economy",
  "macro_proxy", "Macro output-price robustness normalization",
  TRUE, TRUE, FALSE, "robustness_candidate_shortlist",
  "Economy-wide GDP boundary includes households, government, and noncorporate activity."
)

add_fred_candidate(
  "GDPDEF", "gdp_implicit_price_deflator_quarterly",
  "P_Y_PROXY_GDP_IMPLICIT_Q", "diagnostic_only", "GDP",
  "implicit_price_deflator", "macro_economy_wide", "total economy",
  "macro_proxy", "Higher-frequency GDP deflator comparison",
  FALSE, FALSE, TRUE, "diagnostic_only",
  "Quarterly duplicate of the GDP-wide concept; annual series is preferred for robustness."
)

add_fred_candidate(
  "B358RG3A086NBEA", "nonfarm_business_gva_chain_price",
  "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT", "robustness_deflator",
  "business_output", "chain_type_price_index", "nonfarm_business_sector",
  "nonfarm business", "near",
  "Business-sector output-price robustness normalization",
  TRUE, TRUE, TRUE, "proxy_candidate_shortlist",
  "Nearer to corporate production than GDP but includes noncorporate nonfarm business."
)

add_fred_candidate(
  "IPDBS", "bls_business_value_added_output_deflator",
  "P_Y_PROXY_BUSINESS_OUTPUT", "robustness_deflator", "business_output",
  "implicit_price_deflator", "business_sector", "business sector", "near",
  "BLS business-output normalization robustness",
  TRUE, TRUE, TRUE, "proxy_candidate_shortlist",
  "BLS productivity-program business boundary is not the NIPA corporate boundary.",
  source_system = "BLS", source_dataset = "BLS Labor Productivity and Costs"
)

add_fred_candidate(
  "IPDNBS", "bls_nonfarm_business_value_added_output_deflator",
  "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS", "robustness_deflator",
  "nonfarm_business_output", "implicit_price_deflator",
  "nonfarm_business_sector", "nonfarm business sector", "near",
  "BLS nonfarm-business normalization robustness",
  TRUE, TRUE, TRUE, "proxy_candidate_shortlist",
  "Excludes farms but still includes noncorporate business and does not match CORP/NFC.",
  source_system = "BLS", source_dataset = "BLS Labor Productivity and Costs"
)

gdpbyindustry_defs <- list(
  list(
    table = "11", industry = "52", id = "gdpbyindustry_va_finance_price",
    name = "P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE",
    object = "industry_value_added", boundary = "industry_boundary",
    distance = "industry_proxy", role = "robustness_deflator",
    decision = "robustness_candidate_shortlist",
    use = "Finance-and-insurance industry price robustness",
    limitation = "NAICS industry boundary is not financial corporate business."
  ),
  list(
    table = "11", industry = "31G", id = "gdpbyindustry_va_manufacturing_price",
    name = "P_Y_PROXY_GDPBYIND_VA_MANUFACTURING",
    object = "industry_value_added", boundary = "industry_boundary",
    distance = "industry_proxy", role = "robustness_deflator",
    decision = "robustness_candidate_shortlist",
    use = "Goods-producing price-normalization robustness",
    limitation = "Manufacturing is a narrow industry proxy, not the NFC boundary."
  ),
  list(
    table = "18", industry = "52", id = "gdpbyindustry_go_finance_price",
    name = "P_Y_PROXY_GDPBYIND_GROSS_OUTPUT_FINANCE_INSURANCE",
    object = "industry_gross_output", boundary = "gross_output_boundary",
    distance = "gross_output_proxy", role = "diagnostic_only",
    decision = "diagnostic_only",
    use = "Finance gross-output price comparison",
    limitation = "Gross output includes intermediate transactions and is not value added."
  ),
  list(
    table = "18", industry = "II", id = "gdpbyindustry_go_all_price",
    name = "P_Y_PROXY_GDPBYIND_GROSS_OUTPUT_ALL_INDUSTRIES",
    object = "industry_gross_output", boundary = "gross_output_boundary",
    distance = "gross_output_proxy", role = "diagnostic_only",
    decision = "diagnostic_only",
    use = "All-industries gross-output price comparison",
    limitation = "Gross-output and all-industries boundaries are both wider than corporate GVA."
  )
)

for (definition in gdpbyindustry_defs) {
  row <- bea_raw[
    bea_raw$table_id == definition$table &
      bea_raw$industry == definition$industry,
    ,
    drop = FALSE
  ]
  if (nrow(row) != 1L) {
    stop("Missing curated GDPByIndustry candidate: table ",
         definition$table, ", industry ", definition$industry, ".",
         call. = FALSE)
  }
  add_candidate(
    definition$id,
    paste(row$description, "-", row$industry_description),
    "BEA_API", "GDPByIndustry", paste0("TableID ", definition$table),
    definition$industry, row$industry_description,
    row$description, "Chain-type price index", "Annual", "1997", "2024",
    paste0(
      "https://apps.bea.gov/api/data/?UserID=${BEA_API_KEY}",
      "&method=GetData&DataSetName=GDPByIndustry&TableID=",
      definition$table, "&Industry=", definition$industry,
      "&Frequency=A&Year=ALL&ResultFormat=JSON"
    ),
    definition$object, "chain_type_price_index", definition$boundary,
    row$industry_description, definition$distance, definition$use,
    FALSE, FALSE, FALSE,
    definition$role == "robustness_deflator",
    definition$role == "robustness_deflator",
    TRUE, definition$name, definition$role, definition$decision,
    definition$limitation,
    "Official BEA industry price index; never relabel as CORP or FC GVA."
  )
}

add_fred_candidate(
  "PPIFIS", "ppi_final_demand",
  "P_Y_DIAG_PPI_FINAL_DEMAND", "diagnostic_only", "producer_price",
  "producer_price_index", "producer_price_boundary", "final demand",
  "external_proxy", "Producer-price comparison only",
  FALSE, FALSE, TRUE, "diagnostic_only",
  "Short post-2009 sample and transaction-price boundary; not GVA.",
  source_system = "BLS", source_dataset = "BLS Producer Price Index"
)

add_fred_candidate(
  "PPIACO", "ppi_all_commodities",
  "P_Y_DIAG_PPI_ALL_COMMODITIES", "diagnostic_only", "producer_price",
  "producer_price_index", "producer_price_boundary", "commodity production",
  "external_proxy", "Long-span producer-price comparison",
  FALSE, FALSE, TRUE, "diagnostic_only",
  "Commodity mix and transaction-price boundary do not represent corporate GVA.",
  source_system = "BLS", source_dataset = "BLS Producer Price Index"
)

add_fred_candidate(
  "Y033RG3A086NBEA", "equipment_investment_chain_price",
  "P_K_DIAG_FIXEDASSETS_ME", "diagnostic_only", "investment_price",
  "chain_type_price_index", "capital_asset_boundary", "ME investment",
  "capital_side_only", "Capital-side equipment price diagnostic",
  FALSE, FALSE, TRUE, "diagnostic_only",
  "Investment price, not an output deflator or stock revaluation index."
)

add_fred_candidate(
  "B009RG3A086NBEA", "structures_investment_chain_price",
  "P_K_DIAG_FIXEDASSETS_NRC", "diagnostic_only", "investment_price",
  "chain_type_price_index", "capital_asset_boundary", "NRC investment",
  "capital_side_only", "Capital-side structures price diagnostic",
  FALSE, FALSE, TRUE, "diagnostic_only",
  "Investment price, not an output deflator or stock revaluation index."
)

faat402_rows <- provider_menu[
  provider_menu$variable_id %in% c("me_price_or_qindex", "nrc_price_or_qindex"),
  ,
  drop = FALSE
]
add_candidate(
  "faat402_net_stock_quantity_indexes",
  "FAAt402 net-stock Fisher quantity indexes",
  "BEA_API", "FixedAssets", "FAAt402", "ME/NRC lines by legal form",
  "Chain-Type Quantity Indexes for Net Stock of Private Nonresidential Fixed Assets",
  paste(faat402_rows$notes, collapse = " "),
  "Fisher quantity index", "Annual", "1925", "2024",
  paste0(
    "https://apps.bea.gov/api/data/?UserID=${BEA_API_KEY}",
    "&method=GetData&DataSetName=FixedAssets&TableName=FAAt402",
    "&Year=ALL&ResultFormat=JSON"
  ),
  "capital_stock_quantity", "quantity_index", "capital_asset_boundary",
  "ME/NRC net stocks by legal form", "capital_side_only",
  "Compare BEA real-stock trajectories only", FALSE, FALSE, FALSE, FALSE,
  FALSE, TRUE, "P_K_DIAG_FIXEDASSETS_FAAT402", "diagnostic_only",
  "diagnostic_only",
  "Not an output price, GPIM product, baseline stock, or revaluation index.",
  "S11B lock preserved."
)

# Explicitly retain representative search failures to document rejected scope.
rejected_defs <- list(
  list(
    id = "fred_financial_auditing_ppi",
    series = "WPU45210101",
    name = "",
    object = "producer_price",
    price = "producer_price_index",
    boundary = "producer_price_boundary",
    sector = "financial auditing service",
    distance = "mismatch",
    decision = "reject_boundary_mismatch",
    limitation = "Narrow professional-service PPI does not represent financial corporate GVA."
  ),
  list(
    id = "fred_nonfarm_business_real_output",
    series = "OUTNFB",
    name = "",
    object = "nonfarm_business_output",
    price = "real_quantity_counterpart",
    boundary = "nonfarm_business_sector",
    sector = "nonfarm business sector",
    distance = "near",
    decision = "reject_not_price_object",
    limitation = "Real output index is not itself a price object."
  )
)

for (definition in rejected_defs) {
  add_fred_candidate(
    definition$series, definition$id, definition$name, "reject",
    definition$object, definition$price, definition$boundary,
    definition$sector, definition$distance, "Rejected search candidate",
    FALSE, FALSE, FALSE, definition$decision, definition$limitation
  )
}

ledger <- do.call(rbind, ledger_rows)
ledger <- ledger[, ledger_columns, drop = FALSE]

allowed_values <- list(
  source_system = c("BEA_API", "FRED_API", "BLS", "manual_documentation",
                    "other_official"),
  output_object_type = c(
    "GVA", "GDP", "gross_output", "business_output",
    "nonfarm_business_output", "industry_value_added",
    "industry_gross_output", "producer_price", "investment_price",
    "capital_stock_quantity", "unknown"
  ),
  price_object_type = c(
    "implicit_price_deflator", "chain_type_price_index", "quantity_index",
    "price_per_unit", "producer_price_index", "real_quantity_counterpart",
    "not_price_object", "unknown"
  ),
  boundary_type = c(
    "same_boundary", "macro_economy_wide", "business_sector",
    "nonfarm_business_sector", "industry_boundary", "gross_output_boundary",
    "producer_price_boundary", "capital_asset_boundary",
    "external_proxy_boundary", "unknown_boundary"
  ),
  boundary_distance_from_target = c(
    "exact", "near", "macro_proxy", "industry_proxy",
    "gross_output_proxy", "external_proxy", "capital_side_only",
    "mismatch", "unknown"
  ),
  recommended_role = c(
    "baseline_source", "validation_only", "proxy_deflator",
    "robustness_deflator", "diagnostic_only", "reject"
  ),
  decision = c(
    "same_boundary_source_confirmed", "validation_only_confirmed",
    "proxy_candidate_shortlist", "robustness_candidate_shortlist",
    "diagnostic_only", "reject_boundary_mismatch",
    "reject_not_price_object", "reject_unclear_metadata"
  )
)

for (field in names(allowed_values)) {
  bad <- setdiff(unique(ledger[[field]]), allowed_values[[field]])
  if (length(bad) > 0L) {
    stop("Invalid ", field, " values: ", paste(bad, collapse = ", "),
         call. = FALSE)
  }
}

forbidden_names <- c(
  "gva_price_or_deflator_corp", "gva_price_or_deflator_fc",
  "corp_gva_deflator", "fc_gva_deflator"
)
if (any(tolower(ledger$recommended_variable_name) %in% forbidden_names)) {
  stop("A proxy was assigned a forbidden same-boundary name.", call. = FALSE)
}

baseline_rows <- ledger$allowed_as_baseline
if (sum(baseline_rows) != 1L ||
    ledger$recommended_variable_name[baseline_rows] !=
      "P_Y_NFC_GVA_IMPLICIT_SOURCE" ||
    !ledger$same_boundary_match[baseline_rows]) {
  stop("S11C baseline lock failed.", call. = FALSE)
}

fc_corp_claim <- ledger$same_boundary_match &
  ledger$sector_boundary_claimed %in% c("CORP", "FC")
if (any(fc_corp_claim)) {
  stop("S11C incorrectly found a same-boundary CORP/FC object.",
       call. = FALSE)
}

shortlist <- ledger[
  ledger$recommended_role %in% c(
    "baseline_source", "validation_only", "proxy_deflator",
    "robustness_deflator"
  ) &
    ledger$decision %in% c(
      "same_boundary_source_confirmed", "validation_only_confirmed",
      "proxy_candidate_shortlist", "robustness_candidate_shortlist"
    ),
  ,
  drop = FALSE
]

write.csv(ledger, ledger_path, row.names = FALSE, na = "")
write.csv(shortlist, shortlist_path, row.names = FALSE, na = "")

escape_md <- function(x) {
  x <- gsub("\r|\n", " ", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}

markdown_table <- function(data, columns) {
  header <- paste0("| ", paste(columns, collapse = " | "), " |")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(data[, columns, drop = FALSE], 1L, function(row) {
    paste0("| ", paste(vapply(row, escape_md, character(1L)),
                       collapse = " | "), " |")
  })
  c(header, divider, body)
}

same_boundary <- ledger[ledger$decision == "same_boundary_source_confirmed", ]
validation <- ledger[ledger$decision == "validation_only_confirmed", ]
proxy_shortlist <- ledger[
  ledger$decision %in% c(
    "proxy_candidate_shortlist", "robustness_candidate_shortlist"
  ),
]
rejected <- ledger[grepl("^reject_", ledger$decision), ]

report_lines <- c(
  "# S11C Output Price Proxy Search",
  "",
  "## Purpose",
  "",
  paste(
    "S11C searches broadly for official output-price proxy objects and",
    "classifies them without redefining the Chapter 2 baseline or reopening",
    "the provider menu."
  ),
  "",
  "## Link to S11B",
  "",
  paste(
    "S11B confirmed that CORP and FC same-boundary GVA real/price objects",
    "are unavailable in the audited BEA/NIPA documentation and API tables.",
    "S11C does not reverse that result. S11C searches for proxy deflators",
    "and robustness objects to support dataset closure while preserving",
    "correct metadata labels."
  ),
  "",
  "## Search scope",
  "",
  paste0("- FRED searches executed: ", length(fred_queries)),
  paste0("- Raw FRED candidate rows retained: ", nrow(fred_raw)),
  paste0("- BEA GDPByIndustry tables reviewed: ",
         paste(bea_candidate_tables$key, collapse = ", ")),
  "- BEA GDPByIndustry candidate boundaries: all industries, manufacturing, finance and insurance, and FIRE.",
  "- BLS business/nonfarm-business output deflators and PPI series were reviewed through their official-origin FRED metadata.",
  "- Investment price indexes and FAAt402 were retained only as capital-side diagnostics.",
  "",
  "## Classification rules",
  "",
  "- Baseline requires an exact same-boundary GVA source or same-boundary source-level derivation.",
  "- Validation objects may check the baseline but do not replace it.",
  "- Proxy and robustness objects keep transparent `P_Y_PROXY_*` names.",
  "- PPI, investment-price, and capital-stock indexes remain diagnostic-only.",
  "- Industry and gross-output indexes are never relabeled as corporate-sector GVA deflators.",
  "",
  "## Same-boundary results",
  "",
  markdown_table(
    same_boundary,
    c("recommended_variable_name", "source_title", "recommended_role",
      "limitations")
  ),
  "",
  "## Validation-only results",
  "",
  markdown_table(
    validation,
    c("recommended_variable_name", "source_title", "recommended_role",
      "limitations")
  ),
  "",
  "## Proxy shortlist",
  "",
  markdown_table(
    proxy_shortlist,
    c("recommended_variable_name", "source_system", "source_title",
      "boundary_distance_from_target", "recommended_role", "limitations")
  ),
  "",
  "## Rejected candidates",
  "",
  paste0("- Rejected candidate rows: ", nrow(rejected)),
  markdown_table(
    rejected,
    c("candidate_variable_id", "source_title", "decision", "limitations")
  ),
  "",
  "## Naming convention",
  "",
  "- `P_Y` identifies output-price objects.",
  "- `SOURCE` identifies the same-boundary NFC source-level derivation.",
  "- `VALIDATION` identifies direct checks of that derivation.",
  "- `PROXY` identifies non-equivalent macro, business, or industry objects.",
  "- `DIAG` identifies diagnostic-only price or quantity indexes.",
  "",
  "## Recommended dataset-closure path",
  "",
  paste(
    "**B. Baseline uses the NFC same-boundary GVA implicit deflator;",
    "GDP, business/nonfarm-business, and selected GDPByIndustry price",
    "indexes are retained only as explicitly named robustness variants.**"
  ),
  paste(
    "CORP and FC same-boundary real/price rows remain absent. The preferred",
    "first robustness proxies are the annual GDP implicit deflator, BEA",
    "nonfarm-business GVA chain-price index, and BLS business/nonfarm-business",
    "value-added output deflators. Industry indexes are narrower robustness",
    "options; gross-output, PPI, investment-price, and FAAt402 objects remain",
    "diagnostic-only."
  ),
  "",
  "## Non-negotiable locks preserved",
  "",
  "- The provider menu and provider repository are unchanged.",
  "- No CORP or FC real/price residual is constructed.",
  "- No chained-dollar series is raw-subtracted.",
  "- No macro, business, or industry proxy is called a CORP/FC GVA deflator.",
  "- Direct nominal ME/NRC investment remains canonical.",
  "- Stock-flow-implied investment remains fallback-only.",
  "- FAAt402 remains comparison/validation-only.",
  "- No S20/S21/S22 or econometric code was run.",
  "",
  "## Machine-readable outputs",
  "",
  "- `output/US/S11C_OUTPUT_PRICE_PROXY_SEARCH/csv/S11C_output_price_proxy_ledger.csv`",
  "- `output/US/S11C_OUTPUT_PRICE_PROXY_SEARCH/csv/S11C_output_price_proxy_shortlist.csv`",
  "- `output/US/S11C_OUTPUT_PRICE_PROXY_SEARCH/csv/S11C_fred_output_price_raw_candidates.csv`",
  "- `output/US/S11C_OUTPUT_PRICE_PROXY_SEARCH/csv/S11C_bea_output_price_raw_candidates.csv`"
)

writeLines(report_lines, report_path, useBytes = TRUE)

message("S11C output price proxy search passed.")
message("Proxy ledger rows: ", nrow(ledger))
message("Shortlist rows: ", nrow(shortlist))
message("Raw FRED candidates: ", nrow(fred_raw))
message("Raw BEA candidates: ", nrow(bea_raw))
message("Recommended closure path: B")
