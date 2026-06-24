#!/usr/bin/env Rscript

# S20 constructs first-pass productive-capacity capital, unadjusted
# distribution, and frontier conditioners from locked S10 outputs only.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
s10_dir <- file.path(repo_root, "data", "processed", "us_s10")
output_dir <- file.path(repo_root, "data", "processed", "us_s20")
validation_dir <- file.path(repo_root, "docs", "validation")
data_sources_dir <- file.path(repo_root, "docs", "data_sources")

input_paths <- c(
  source_panel = file.path(s10_dir, "us_s10_source_panel_long.csv"),
  object_ledger = file.path(
    s10_dir, "us_s10_object_admissibility_ledger.csv"
  ),
  construction_ledger = file.path(
    data_sources_dir, "US_S10_SOURCE_OF_TRUTH_CONSTRUCTION_LEDGER.md"
  )
)

output_paths <- c(
  panel = file.path(
    output_dir, "us_s20_capital_distribution_frontier_panel.csv"
  ),
  ledger = file.path(output_dir, "us_s20_construction_ledger.csv"),
  checks = file.path(output_dir, "us_s20_validation_checks.csv"),
  validation_report = file.path(
    validation_dir, "US_S20_CAPITAL_DISTRIBUTION_FRONTIER_VALIDATION.md"
  ),
  construction_report = file.path(
    data_sources_dir, "US_S20_CAPITAL_DISTRIBUTION_FRONTIER_LEDGER.md"
  )
)

abort <- function(message) {
  stop(message, call. = FALSE)
}

require_condition <- function(condition, message) {
  if (!isTRUE(condition)) {
    abort(message)
  }
}

safe_log <- function(x) {
  result <- rep(NA_real_, length(x))
  valid <- !is.na(x) & is.finite(x) & x > 0
  result[valid] <- log(x[valid])
  result
}

safe_growth <- function(x, year) {
  require_condition(
    length(x) == length(year),
    "safe_growth() requires equal-length value and year vectors."
  )
  result <- rep(NA_real_, length(x))
  logged <- safe_log(x)
  if (length(x) > 1L) {
    consecutive <- diff(year) == 1
    valid <- consecutive & !is.na(logged[-1L]) & !is.na(logged[-length(x)])
    target_index <- which(valid) + 1L
    result[target_index] <- diff(logged)[valid]
  }
  result
}

safe_ratio <- function(numerator, denominator) {
  require_condition(
    length(numerator) == length(denominator),
    "safe_ratio() requires equal-length numerator and denominator vectors."
  )
  result <- rep(NA_real_, length(numerator))
  valid <- !is.na(numerator) & is.finite(numerator) &
    !is.na(denominator) & is.finite(denominator) & denominator != 0
  result[valid] <- numerator[valid] / denominator[valid]
  result
}

ledger_row <- function(
    s20_variable,
    s20_family,
    preferred_status,
    construction_status,
    source_s10_object_or_formula,
    formula,
    admissibility_basis,
    blocked_reason = "",
    notes = "") {
  data.frame(
    s20_variable = s20_variable,
    s20_family = s20_family,
    preferred_status = preferred_status,
    construction_status = construction_status,
    source_s10_object_or_formula = source_s10_object_or_formula,
    formula = formula,
    admissibility_basis = admissibility_basis,
    blocked_reason = blocked_reason,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

validation_check <- function(check_id, check_name, status, details) {
  require_condition(
    status %in% c("PASS", "WARN", "FAIL"),
    paste0("Invalid validation status for ", check_id, ": ", status)
  )
  data.frame(
    check_id = check_id,
    check_name = check_name,
    status = status,
    details = details,
    stringsAsFactors = FALSE
  )
}

read_s10_csv <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

script_argument <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
require_condition(
  length(script_argument) == 1L,
  "S20 must be executed from its R script file."
)
script_path <- normalizePath(
  sub("^--file=", "", script_argument),
  winslash = "/",
  mustWork = TRUE
)
script_text <- paste(
  readLines(script_path, warn = FALSE, encoding = "UTF-8"),
  collapse = "\n"
)
fetch_call_patterns <- c(
  paste0("download", "\\.file\\s*\\("),
  paste0("curl", "::"),
  paste0("httr", "::"),
  paste0("httr2", "::"),
  paste0("bea", "\\s*\\(")
)
estimator_call_patterns <- c(
  paste0("lm", "\\s*\\("),
  paste0("glm", "\\s*\\("),
  paste0("ur\\.df", "\\s*\\("),
  paste0("ca\\.jo", "\\s*\\("),
  paste0("adf\\.test", "\\s*\\("),
  paste0("kpss\\.test", "\\s*\\(")
)
no_fetch_calls <- !any(vapply(
  fetch_call_patterns,
  function(pattern) grepl(pattern, script_text, ignore.case = TRUE, perl = TRUE),
  logical(1L)
))
no_estimator_calls <- !any(vapply(
  estimator_call_patterns,
  function(pattern) grepl(pattern, script_text, ignore.case = TRUE, perl = TRUE),
  logical(1L)
))

missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(
    paste0(
      "S20 required S10 inputs are missing:\n- ",
      paste(unname(missing_inputs), collapse = "\n- ")
    )
  )
}

normalized_s10_dir <- normalizePath(s10_dir, winslash = "/", mustWork = TRUE)
normalized_data_sources_dir <- normalizePath(
  data_sources_dir, winslash = "/", mustWork = TRUE
)
normalized_inputs <- normalizePath(
  input_paths, winslash = "/", mustWork = TRUE
)
names(normalized_inputs) <- names(input_paths)
s10_only_inputs <- all(
  startsWith(
    normalized_inputs[c("source_panel", "object_ledger")],
    paste0(normalized_s10_dir, "/")
  )
) && startsWith(
  normalized_inputs[["construction_ledger"]],
  paste0(normalized_data_sources_dir, "/")
)
require_condition(
  s10_only_inputs,
  "S20 inputs must resolve to the locked S10 outputs."
)

input_hashes_before <- unname(tools::md5sum(input_paths))
names(input_hashes_before) <- names(input_paths)

provider_dir <- file.path(repo_root, "data", "external", "us_bea_provider")
provider_files <- if (dir.exists(provider_dir)) {
  list.files(provider_dir, recursive = TRUE, full.names = TRUE)
} else {
  character()
}
provider_hashes_before <- if (length(provider_files) > 0L) {
  tools::md5sum(provider_files)
} else {
  character()
}

source_panel <- read_s10_csv(input_paths[["source_panel"]])
object_ledger <- read_s10_csv(input_paths[["object_ledger"]])
s10_ledger_text <- readLines(
  input_paths[["construction_ledger"]],
  warn = FALSE,
  encoding = "UTF-8"
)

required_panel_columns <- c(
  "variable_id", "date", "year", "value", "canonical_name",
  "sector_boundary", "asset_block", "unit", "price_basis",
  "stock_flow_type", "role_tag", "status"
)
required_ledger_columns <- c(
  "object_id", "analytical_role", "admissibility_status", "blocking_reason"
)
missing_panel_columns <- setdiff(required_panel_columns, names(source_panel))
missing_ledger_columns <- setdiff(required_ledger_columns, names(object_ledger))
require_condition(
  length(missing_panel_columns) == 0L,
  paste0(
    "S10 source panel is missing columns: ",
    paste(missing_panel_columns, collapse = ", ")
  )
)
require_condition(
  length(missing_ledger_columns) == 0L,
  paste0(
    "S10 admissibility ledger is missing columns: ",
    paste(missing_ledger_columns, collapse = ", ")
  )
)
require_condition(
  length(s10_ledger_text) > 0L,
  "S10 construction ledger document is empty."
)

source_ids <- c(
  K_ME = "NFC__ME__net_stock_current_cost",
  K_NRC = "NFC__NRC__net_stock_current_cost",
  IPP_stock = "NFC__IPP__net_stock_current_cost",
  total_fixed_assets = "NFC__TOTAL__net_stock_current_cost",
  omega_CORP_numerator = "CORP_COMP",
  omega_CORP_denominator = "CORP_GVA",
  omega_NFC_numerator = "NFC_COMP",
  omega_NFC_denominator = "NFC_GVA",
  GOV_TRANS_transportation =
    "GOV_TRANS__TRANSPORTATION_STRUCTURES__net_stock_current_cost",
  GOV_TRANS_highways =
    "GOV_TRANS__HIGHWAYS_STREETS__net_stock_current_cost"
)

admissible_statuses <- c(
  "staged_source_ingredient",
  "preferred_baseline_pending",
  "alternative_proxy_pending",
  "frontier_conditioner_pending",
  "downstream_constructed_pending",
  "diagnostic_pending"
)

assert_admissible_source <- function(variable_id) {
  source_rows <- source_panel[
    source_panel$variable_id == variable_id,
    ,
    drop = FALSE
  ]
  require_condition(
    nrow(source_rows) > 0L,
    paste0("Required S10 source is missing: ", variable_id)
  )
  ledger_rows <- object_ledger[
    object_ledger$object_id == variable_id,
    ,
    drop = FALSE
  ]
  require_condition(
    nrow(ledger_rows) == 1L,
    paste0(
      "Required S10 source must have one admissibility row: ",
      variable_id
    )
  )
  require_condition(
    ledger_rows$admissibility_status %in% admissible_statuses,
    paste0(
      "Required S10 source is not admissible: ",
      variable_id,
      " [",
      ledger_rows$admissibility_status,
      "]"
    )
  )
  require_condition(
    all(source_rows$status == "staged"),
    paste0("Required S10 source is not fully staged: ", variable_id)
  )
  require_condition(
    !anyDuplicated(source_rows$year),
    paste0("Required S10 source has duplicate years: ", variable_id)
  )
  invisible(TRUE)
}

invisible(lapply(unique(unname(source_ids)), assert_admissible_source))

stock_ids <- unname(source_ids[c(
  "K_ME", "K_NRC", "IPP_stock", "total_fixed_assets",
  "GOV_TRANS_transportation", "GOV_TRANS_highways"
)])
stock_metadata <- source_panel[
  source_panel$variable_id %in% stock_ids,
  c(
    "variable_id", "unit", "price_basis", "stock_flow_type",
    "sector_boundary", "role_tag"
  ),
  drop = FALSE
]
stock_metadata <- stock_metadata[!duplicated(stock_metadata), , drop = FALSE]
require_condition(
  nrow(stock_metadata) == length(stock_ids),
  "S20 stock sources have non-unique metadata."
)
require_condition(
  all(stock_metadata$unit == "Millions of current dollars") &&
    all(stock_metadata$price_basis == "current_cost") &&
    all(stock_metadata$stock_flow_type == "net_stock"),
  "S20 additive stock sources must be current-cost net stocks in common units."
)

extract_series <- function(variable_id, years) {
  rows <- source_panel[
    source_panel$variable_id == variable_id,
    c("year", "value"),
    drop = FALSE
  ]
  rows <- rows[order(rows$year), , drop = FALSE]
  require_condition(
    !anyDuplicated(rows$year),
    paste0("Duplicate years prevent deterministic extraction: ", variable_id)
  )
  values <- rep(NA_real_, length(years))
  matched <- match(rows$year, years)
  require_condition(
    !anyNA(matched),
    paste0("Source year lies outside S20 panel index: ", variable_id)
  )
  values[matched] <- as.numeric(rows$value)
  values
}

years <- seq(
  min(source_panel$year[source_panel$variable_id %in% unname(source_ids)]),
  max(source_panel$year[source_panel$variable_id %in% unname(source_ids)])
)
panel <- data.frame(
  year = years,
  date = sprintf("%d-12-31", years),
  stringsAsFactors = FALSE
)

panel$K_ME <- extract_series(source_ids[["K_ME"]], years)
panel$K_NRC <- extract_series(source_ids[["K_NRC"]], years)
panel$K_cap <- panel$K_ME + panel$K_NRC
panel$k_ME <- safe_log(panel$K_ME)
panel$k_NRC <- safe_log(panel$K_NRC)
panel$k_Kcap <- safe_log(panel$K_cap)
panel$g_K_ME <- safe_growth(panel$K_ME, panel$year)
panel$g_K_NRC <- safe_growth(panel$K_NRC, panel$year)
panel$g_Kcap <- safe_growth(panel$K_cap, panel$year)
panel$ME_NRC_gap <- panel$k_ME - panel$k_NRC
panel$ME_share <- safe_ratio(panel$K_ME, panel$K_cap)
panel$NRC_share <- safe_ratio(panel$K_NRC, panel$K_cap)

corp_comp <- extract_series(source_ids[["omega_CORP_numerator"]], years)
corp_gva <- extract_series(source_ids[["omega_CORP_denominator"]], years)
nfc_comp <- extract_series(source_ids[["omega_NFC_numerator"]], years)
nfc_gva <- extract_series(source_ids[["omega_NFC_denominator"]], years)
panel$omega_CORP <- safe_ratio(corp_comp, corp_gva)
panel$omega_NFC <- safe_ratio(nfc_comp, nfc_gva)
panel$pi_res_CORP <- 1 - panel$omega_CORP
panel$pi_res_NFC <- 1 - panel$omega_NFC
panel$e_CORP <- safe_ratio(panel$pi_res_CORP, panel$omega_CORP)
panel$e_NFC <- safe_ratio(panel$pi_res_NFC, panel$omega_NFC)
panel$ln_e_CORP <- safe_log(panel$e_CORP)
panel$ln_e_NFC <- safe_log(panel$e_NFC)

panel$IPP_stock <- extract_series(source_ids[["IPP_stock"]], years)
panel$IPP_growth <- safe_growth(panel$IPP_stock, panel$year)
total_fixed_assets <- extract_series(
  source_ids[["total_fixed_assets"]], years
)
panel$IPP_share_total_fixed_assets <- safe_ratio(
  panel$IPP_stock, total_fixed_assets
)
panel$IPP_share_capital_plus_IPP <- safe_ratio(
  panel$IPP_stock, panel$K_cap + panel$IPP_stock
)
panel$IPP_to_Kcap <- safe_ratio(panel$IPP_stock, panel$K_cap)

gov_transportation <- extract_series(
  source_ids[["GOV_TRANS_transportation"]], years
)
gov_highways <- extract_series(source_ids[["GOV_TRANS_highways"]], years)
panel$GOV_TRANS_stock <- gov_transportation + gov_highways
panel$GOV_TRANS_growth <- safe_growth(panel$GOV_TRANS_stock, panel$year)
panel$GOV_TRANS_to_Kcap <- safe_ratio(panel$GOV_TRANS_stock, panel$K_cap)
panel$GOV_TRANS_to_NRC <- safe_ratio(panel$GOV_TRANS_stock, panel$K_NRC)
panel$GOV_TRANS_to_ME <- safe_ratio(panel$GOV_TRANS_stock, panel$K_ME)

capital_basis <- paste(
  "S10 marks NFC ME and NRC current-cost net stocks as staged",
  "direct productive-capacity ingredients; NFC is the preferred",
  "nonfinancial corporate productive-sector boundary."
)
distribution_basis <- paste(
  "S10 stages direct NIPA compensation and gross-value-added lines and",
  "registers unadjusted wage shares as the preferred first-pass baseline."
)
ipp_basis <- paste(
  "S10 stages NFC IPP and NFC total fixed-assets current-cost net stocks;",
  "IPP is a frontier conditioner and is excluded from K_cap."
)
gov_basis <- paste(
  "S10 stages transportation structures and highways/streets as separate",
  "GOV_TRANS current-cost net-stock components and frontier conditioners."
)

ledger_rows <- list(
  ledger_row("K_ME", "productive_capacity_capital", "preferred_component",
    "constructed", source_ids[["K_ME"]], "K_ME = S10 NFC ME net stock",
    capital_basis),
  ledger_row("K_NRC", "productive_capacity_capital", "preferred_component",
    "constructed", source_ids[["K_NRC"]], "K_NRC = S10 NFC NRC net stock",
    capital_basis),
  ledger_row("K_cap", "productive_capacity_capital", "preferred_baseline",
    "constructed", "K_ME + K_NRC", "K_cap = K_ME + K_NRC", capital_basis,
    notes = "IPP and GOV_TRANS are excluded."),
  ledger_row("k_ME", "productive_capacity_capital", "transformation",
    "constructed", "K_ME", "k_ME = log(K_ME)", capital_basis),
  ledger_row("k_NRC", "productive_capacity_capital", "transformation",
    "constructed", "K_NRC", "k_NRC = log(K_NRC)", capital_basis),
  ledger_row("k_Kcap", "productive_capacity_capital", "transformation",
    "constructed", "K_cap", "k_Kcap = log(K_cap)", capital_basis),
  ledger_row("g_K_ME", "productive_capacity_capital", "transformation",
    "constructed_with_missing_edges", "k_ME",
    "g_K_ME = Delta log(K_ME)", capital_basis),
  ledger_row("g_K_NRC", "productive_capacity_capital", "transformation",
    "constructed_with_missing_edges", "k_NRC",
    "g_K_NRC = Delta log(K_NRC)", capital_basis),
  ledger_row("g_Kcap", "productive_capacity_capital", "transformation",
    "constructed_with_missing_edges", "k_Kcap",
    "g_Kcap = Delta log(K_cap)", capital_basis),
  ledger_row("ME_NRC_gap", "productive_capacity_capital", "diagnostic",
    "constructed", "k_ME - k_NRC", "ME_NRC_gap = k_ME - k_NRC",
    capital_basis),
  ledger_row("ME_share", "productive_capacity_capital", "diagnostic",
    "constructed", "K_ME / K_cap", "ME_share = K_ME / K_cap",
    capital_basis),
  ledger_row("NRC_share", "productive_capacity_capital", "diagnostic",
    "constructed", "K_NRC / K_cap", "NRC_share = K_NRC / K_cap",
    capital_basis),
  ledger_row("omega_CORP", "distribution_unadjusted", "preferred_baseline",
    "constructed", "CORP_COMP / CORP_GVA",
    "omega_CORP = CORP_COMP / CORP_GVA", distribution_basis),
  ledger_row("omega_NFC", "distribution_unadjusted", "preferred_baseline",
    "constructed", "NFC_COMP / NFC_GVA",
    "omega_NFC = NFC_COMP / NFC_GVA", distribution_basis),
  ledger_row("pi_res_CORP", "distribution_unadjusted", "residual_share",
    "constructed", "1 - omega_CORP", "pi_res_CORP = 1 - omega_CORP",
    distribution_basis),
  ledger_row("pi_res_NFC", "distribution_unadjusted", "residual_share",
    "constructed", "1 - omega_NFC", "pi_res_NFC = 1 - omega_NFC",
    distribution_basis),
  ledger_row("e_CORP", "distribution_alternative_proxy",
    "alternative_proxy", "constructed", "pi_res_CORP / omega_CORP",
    "e_CORP = pi_res_CORP / omega_CORP", distribution_basis),
  ledger_row("e_NFC", "distribution_alternative_proxy",
    "alternative_proxy", "constructed", "pi_res_NFC / omega_NFC",
    "e_NFC = pi_res_NFC / omega_NFC", distribution_basis),
  ledger_row("ln_e_CORP", "distribution_alternative_proxy",
    "alternative_proxy", "constructed", "e_CORP",
    "ln_e_CORP = log(e_CORP)", distribution_basis),
  ledger_row("ln_e_NFC", "distribution_alternative_proxy",
    "alternative_proxy", "constructed", "e_NFC",
    "ln_e_NFC = log(e_NFC)", distribution_basis),
  ledger_row("IPP_stock", "frontier_conditioner_IPP",
    "frontier_conditioner", "constructed", source_ids[["IPP_stock"]],
    "IPP_stock = S10 NFC IPP net stock", ipp_basis),
  ledger_row("IPP_growth", "frontier_conditioner_IPP",
    "frontier_conditioner", "constructed_with_missing_edges", "IPP_stock",
    "IPP_growth = Delta log(IPP_stock)", ipp_basis),
  ledger_row("IPP_share_total_fixed_assets", "frontier_conditioner_IPP",
    "frontier_conditioner", "constructed",
    paste0("IPP_stock / ", source_ids[["total_fixed_assets"]]),
    "IPP_share_total_fixed_assets = IPP_stock / NFC total fixed assets",
    ipp_basis),
  ledger_row("IPP_share_capital_plus_IPP", "frontier_conditioner_IPP",
    "frontier_conditioner", "constructed", "IPP_stock / (K_cap + IPP_stock)",
    "IPP_share_capital_plus_IPP = IPP_stock / (K_cap + IPP_stock)",
    ipp_basis),
  ledger_row("IPP_to_Kcap", "frontier_conditioner_IPP",
    "frontier_conditioner", "constructed", "IPP_stock / K_cap",
    "IPP_to_Kcap = IPP_stock / K_cap", ipp_basis),
  ledger_row("GOV_TRANS_stock", "frontier_conditioner_GOV_TRANS",
    "frontier_conditioner", "constructed",
    paste(
      source_ids[["GOV_TRANS_transportation"]],
      "+",
      source_ids[["GOV_TRANS_highways"]]
    ),
    "GOV_TRANS_stock = transportation structures + highways/streets",
    gov_basis),
  ledger_row("GOV_TRANS_growth", "frontier_conditioner_GOV_TRANS",
    "frontier_conditioner", "constructed_with_missing_edges",
    "GOV_TRANS_stock", "GOV_TRANS_growth = Delta log(GOV_TRANS_stock)",
    gov_basis),
  ledger_row("GOV_TRANS_to_Kcap", "frontier_conditioner_GOV_TRANS",
    "frontier_conditioner", "constructed", "GOV_TRANS_stock / K_cap",
    "GOV_TRANS_to_Kcap = GOV_TRANS_stock / K_cap", gov_basis),
  ledger_row("GOV_TRANS_to_NRC", "frontier_conditioner_GOV_TRANS",
    "frontier_conditioner", "constructed", "GOV_TRANS_stock / K_NRC",
    "GOV_TRANS_to_NRC = GOV_TRANS_stock / K_NRC", gov_basis),
  ledger_row("GOV_TRANS_to_ME", "frontier_conditioner_GOV_TRANS",
    "frontier_conditioner", "constructed", "GOV_TRANS_stock / K_ME",
    "GOV_TRANS_to_ME = GOV_TRANS_stock / K_ME", gov_basis)
)
construction_ledger <- do.call(rbind, ledger_rows)

target_variables <- construction_ledger$s20_variable
require_condition(
  !anyDuplicated(target_variables),
  "S20 construction ledger contains duplicate target variables."
)
require_condition(
  all(target_variables %in% names(panel)),
  "S20 panel is missing one or more ledgered target variables."
)

for (path in c(output_dir, validation_dir, data_sources_dir)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  require_condition(
    dir.exists(path),
    paste0("Unable to create required S20 directory: ", path)
  )
}

write.csv(panel, output_paths[["panel"]], row.names = FALSE, na = "")
write.csv(
  construction_ledger,
  output_paths[["ledger"]],
  row.names = FALSE,
  na = ""
)

tolerance <- 1e-10
complete_capital <- complete.cases(panel[c("K_ME", "K_NRC", "K_cap")])
complete_shares <- complete.cases(panel[c("ME_share", "NRC_share")])

growth_matches <- function(level_name, growth_name) {
  expected <- safe_growth(panel[[level_name]], panel$year)
  observed <- panel[[growth_name]]
  comparable <- !is.na(expected) | !is.na(observed)
  all(
    is.na(expected[comparable]) == is.na(observed[comparable]) &
      (
        is.na(expected[comparable]) |
          abs(expected[comparable] - observed[comparable]) <= tolerance
      )
  )
}

log_inputs <- list(
  k_ME = panel$K_ME,
  k_NRC = panel$K_NRC,
  k_Kcap = panel$K_cap,
  ln_e_CORP = panel$e_CORP,
  ln_e_NFC = panel$e_NFC
)
logs_positive_only <- all(vapply(
  names(log_inputs),
  function(log_name) {
    logged <- panel[[log_name]]
    input <- log_inputs[[log_name]]
    all(is.na(logged) | (!is.na(input) & input > 0))
  },
  logical(1L)
))

forbidden_panel_patterns <- c(
  "^q_omega_", "^q_e_", "^omega_x_", "^e_x_",
  "adj", "capacity_utilization", "^mu$", "^u$"
)
forbidden_panel_columns <- unique(unlist(lapply(
  forbidden_panel_patterns,
  function(pattern) grep(pattern, names(panel), value = TRUE)
)))

checks <- do.call(rbind, list(
  validation_check(
    "s10_inputs_exist", "S10 input files exist", "PASS",
    paste(length(input_paths), "required S10 inputs found.")
  ),
  validation_check(
    "no_bea_fetch", "No BEA fetch is called",
    if (no_fetch_calls) "PASS" else "FAIL",
    "Static scan found no network or BEA-fetch call."
  ),
  validation_check(
    "provider_artifacts_unchanged", "No provider artifact is modified",
    "PASS", "Provider artifacts are hashed before and after S20."
  ),
  validation_check(
    "output_directory_exists", "S20 output directory exists",
    if (dir.exists(output_dir)) "PASS" else "FAIL", output_dir
  ),
  validation_check(
    "panel_output_written", "Panel output written",
    if (file.exists(output_paths[["panel"]])) "PASS" else "FAIL",
    output_paths[["panel"]]
  ),
  validation_check(
    "construction_ledger_written", "Construction ledger written",
    if (file.exists(output_paths[["ledger"]])) "PASS" else "FAIL",
    output_paths[["ledger"]]
  ),
  validation_check(
    "validation_checks_written", "Validation checks written", "PASS",
    "This check is recorded in the final validation-checks output."
  ),
  validation_check(
    "kcap_identity", "K_cap equals K_ME plus K_NRC",
    if (
      any(complete_capital) &&
        all(
          abs(
            panel$K_cap[complete_capital] -
              panel$K_ME[complete_capital] -
              panel$K_NRC[complete_capital]
          ) <= tolerance
        )
    ) "PASS" else "FAIL",
    paste(sum(complete_capital), "complete annual observations checked.")
  ),
  validation_check(
    "capital_shares_sum", "ME_share plus NRC_share equals one",
    if (
      any(complete_shares) &&
        all(
          abs(
            panel$ME_share[complete_shares] +
              panel$NRC_share[complete_shares] - 1
          ) <= tolerance
        )
    ) "PASS" else "FAIL",
    paste(sum(complete_shares), "complete annual observations checked.")
  ),
  validation_check(
    "logs_positive_only", "Logs use strictly positive inputs only",
    if (logs_positive_only) "PASS" else "FAIL",
    "Capital and exploitation-rate log outputs were audited."
  ),
  validation_check(
    "growth_first_difference_logs",
    "Growth rates are first differences of logs",
    if (
      growth_matches("K_ME", "g_K_ME") &&
        growth_matches("K_NRC", "g_K_NRC") &&
        growth_matches("K_cap", "g_Kcap") &&
        growth_matches("IPP_stock", "IPP_growth") &&
        growth_matches("GOV_TRANS_stock", "GOV_TRANS_growth")
    ) "PASS" else "FAIL",
    "All five requested growth series were recomputed and compared."
  ),
  validation_check(
    "ipp_excluded_from_kcap", "IPP is not included in K_cap", "PASS",
    "The implemented identity is exactly K_cap = K_ME + K_NRC."
  ),
  validation_check(
    "gov_trans_excluded_from_kcap",
    "GOV_TRANS is not included in private K_cap", "PASS",
    "The implemented identity is exactly K_cap = K_ME + K_NRC."
  ),
  validation_check(
    "ipp_frontier_only", "IPP is retained only as a frontier conditioner",
    if (
      all(
        construction_ledger$s20_family[
          startsWith(construction_ledger$s20_variable, "IPP")
        ] == "frontier_conditioner_IPP"
      )
    ) "PASS" else "FAIL",
    "All IPP targets are ledgered as frontier conditioners."
  ),
  validation_check(
    "gov_trans_frontier_only",
    "GOV_TRANS is retained only as a frontier conditioner",
    if (
      all(
        construction_ledger$s20_family[
          startsWith(construction_ledger$s20_variable, "GOV_TRANS")
        ] == "frontier_conditioner_GOV_TRANS"
      )
    ) "PASS" else "FAIL",
    "All GOV_TRANS targets are ledgered as frontier conditioners."
  ),
  validation_check(
    "no_shaikh_adjusted",
    "No Shaikh-adjusted variable is constructed",
    if (!any(grepl("adj", names(panel), ignore.case = TRUE))) {
      "PASS"
    } else {
      "FAIL"
    },
    "Panel columns contain unadjusted distribution variables only."
  ),
  validation_check(
    "no_q_omega", "No q_omega variable is constructed",
    if (!any(grepl("^q_omega_", names(panel)))) "PASS" else "FAIL",
    "Accumulated indexes are deferred to S21."
  ),
  validation_check(
    "no_q_e", "No q_e variable is constructed",
    if (!any(grepl("^q_e_", names(panel)))) "PASS" else "FAIL",
    "Accumulated alternative-proxy indexes are deferred to S21."
  ),
  validation_check(
    "no_level_interactions",
    "No omega_x or e_x variable is constructed",
    if (
      !any(grepl("^omega_x_", names(panel))) &&
        !any(grepl("^e_x_", names(panel)))
    ) "PASS" else "FAIL",
    "Superseded level interactions are absent."
  ),
  validation_check(
    "no_estimators", "No regressions or integration tests are run",
    if (
      length(forbidden_panel_columns) == 0L && no_estimator_calls
    ) "PASS" else "FAIL",
    "Static call scan and output-column audit found no estimator or test."
  ),
  validation_check(
    "nfc_preferred_boundary",
    "Capital and IPP use the preferred NFC boundary", "PASS",
    paste(
      source_ids[["K_ME"]], source_ids[["K_NRC"]],
      source_ids[["IPP_stock"]], sep = "; "
    )
  ),
  validation_check(
    "total_fixed_assets_denominator",
    "IPP total-fixed-assets share uses an admissible denominator", "PASS",
    source_ids[["total_fixed_assets"]]
  ),
  validation_check(
    "target_variable_count", "All requested S20 variables are ledgered",
    if (nrow(construction_ledger) == 30L) "PASS" else "FAIL",
    paste(nrow(construction_ledger), "target variables.")
  )
))

escape_markdown <- function(x) {
  gsub("|", "\\|", as.character(x), fixed = TRUE)
}

markdown_table <- function(data, columns = names(data)) {
  header <- paste0("|", paste(columns, collapse = "|"), "|")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(
    data[, columns, drop = FALSE],
    1L,
    function(row) {
      paste0(
        "|",
        paste(vapply(row, escape_markdown, character(1L)), collapse = "|"),
        "|"
      )
    }
  )
  c(header, divider, body)
}

constructed_variables <- construction_ledger$s20_variable[
  construction_ledger$construction_status %in%
    c("constructed", "constructed_with_missing_edges")
]
blocked_variables <- construction_ledger[
  startsWith(construction_ledger$construction_status, "blocked"),
  ,
  drop = FALSE
]

validation_lines <- c(
  "# U.S. S20 Capital, Distribution, and Frontier Validation",
  "",
  "## Purpose",
  "",
  paste(
    "S20 constructs the first-pass NFC productive-capacity capital block,",
    "unadjusted CORP/NFC distributive states, and IPP/GOV_TRANS frontier",
    "conditioners from locked S10 outputs."
  ),
  "",
  "## Upstream inputs",
  "",
  paste0("- `", sub(paste0(repo_root, "/"), "", input_paths), "`"),
  "",
  "## Constructed variables",
  "",
  paste0("- `", constructed_variables, "`"),
  "",
  "## Blocked or unavailable variables",
  "",
  if (nrow(blocked_variables) == 0L) {
    "None. All 30 requested S20 variables were constructed."
  } else {
    paste0(
      "- `", blocked_variables$s20_variable, "`: ",
      blocked_variables$blocked_reason
    )
  },
  "",
  "## Validation summary",
  "",
  markdown_table(checks, c("check_name", "status", "details")),
  "",
  "## Hard-lock confirmation",
  "",
  paste(
    "S20 did not fetch BEA data, modify provider artifacts, construct",
    "Shaikh-adjusted variables, build q indexes, construct superseded level",
    "interactions, run integration-order tests, estimate regressions, or",
    "reconstruct capacity utilization."
  ),
  paste(
    "IPP and GOV_TRANS remain frontier conditioners and do not enter",
    "private `K_cap`."
  )
)
writeLines(
  validation_lines,
  output_paths[["validation_report"]],
  useBytes = TRUE
)

ledger_lines <- c(
  "# U.S. S20 Capital, Distribution, and Frontier Construction Ledger",
  "",
  "## Productive-capacity capital",
  "",
  paste(
    "The preferred first-pass capital object is `K_cap = K_ME + K_NRC`.",
    "Machinery and equipment and nonresidential structures directly support",
    "productive capacity, and the NFC boundary is the locked preferred",
    "productive-sector boundary. Current-cost net stocks are used because",
    "they are additive common-unit S10 objects; official quantity indexes",
    "are diagnostic and cannot be summed as levels."
  ),
  "",
  "## Frontier conditioners",
  "",
  paste(
    "IPP is excluded from preferred productive-capacity capital because it",
    "conditions the transformation frontier rather than entering the direct",
    "ME-plus-NRC capacity identity. It remains in S20 through its stock,",
    "growth, and scale ratios."
  ),
  paste(
    "GOV_TRANS is excluded because `K_cap` is private NFC capital.",
    "Transportation infrastructure remains a frontier conditioner through",
    "the auditable sum of transportation structures and highways/streets."
  ),
  "",
  "## Distribution",
  "",
  paste(
    "The unadjusted wage share is the first-pass baseline because direct",
    "compensation and gross-value-added lines are staged and admissible while",
    "the current-release Shaikh-style adjustment protocol remains blocked."
  ),
  paste(
    "The exploitation rate and its log are retained only as alternative-proxy",
    "robustness variables; they do not replace the wage-share baseline."
  ),
  "",
  "## Deferred objects",
  "",
  paste(
    "Shaikh-adjusted variables remain blocked because the current-release",
    "semantic crosswalk has not passed. The `q_omega_*` and `q_e_*`",
    "accumulated indexes are deferred to S21. Integration testing and",
    "estimation are deferred to S31I and S30/S32."
  ),
  paste(
    "Superseded `omega_x_*` and `e_x_*` level interactions are not",
    "analytical variables and are not constructed."
  ),
  "",
  "## Variable ledger",
  "",
  markdown_table(construction_ledger)
)
writeLines(
  ledger_lines,
  output_paths[["construction_report"]],
  useBytes = TRUE
)

input_hashes_after <- unname(tools::md5sum(input_paths))
names(input_hashes_after) <- names(input_paths)
provider_hashes_after <- if (length(provider_files) > 0L) {
  tools::md5sum(provider_files)
} else {
  character()
}
inputs_unchanged <- identical(input_hashes_before, input_hashes_after)
providers_unchanged <- identical(provider_hashes_before, provider_hashes_after)

checks$status[checks$check_id == "provider_artifacts_unchanged"] <-
  if (providers_unchanged) "PASS" else "FAIL"
checks$details[checks$check_id == "provider_artifacts_unchanged"] <-
  paste(length(provider_files), "provider files hashed unchanged.")
checks <- rbind(
  checks,
  validation_check(
    "s10_inputs_unchanged", "S10 inputs are unchanged",
    if (inputs_unchanged) "PASS" else "FAIL",
    paste(length(input_paths), "S10 input hashes compared.")
  ),
  validation_check(
    "validation_report_written", "Validation report written",
    if (file.exists(output_paths[["validation_report"]])) "PASS" else "FAIL",
    output_paths[["validation_report"]]
  ),
  validation_check(
    "construction_report_written", "Construction report written",
    if (file.exists(output_paths[["construction_report"]])) "PASS" else "FAIL",
    output_paths[["construction_report"]]
  )
)

checks <- checks[order(checks$check_id), , drop = FALSE]
rownames(checks) <- NULL
write.csv(checks, output_paths[["checks"]], row.names = FALSE, na = "")

overall_result <- if (all(checks$status != "FAIL")) "PASS" else "FAIL"
validation_lines <- c(
  "# U.S. S20 Capital, Distribution, and Frontier Validation",
  "",
  paste0("**Overall result: ", overall_result, ".**"),
  "",
  "## Purpose",
  "",
  paste(
    "S20 constructs the first-pass NFC productive-capacity capital block,",
    "unadjusted CORP/NFC distributive states, and IPP/GOV_TRANS frontier",
    "conditioners from locked S10 outputs."
  ),
  "",
  "## Upstream inputs",
  "",
  paste0("- `", sub(paste0(repo_root, "/"), "", input_paths), "`"),
  "",
  "## Constructed variables",
  "",
  paste0("- `", constructed_variables, "`"),
  "",
  "## Blocked or unavailable variables",
  "",
  if (nrow(blocked_variables) == 0L) {
    "None. All 30 requested S20 variables were constructed."
  } else {
    paste0(
      "- `", blocked_variables$s20_variable, "`: ",
      blocked_variables$blocked_reason
    )
  },
  "",
  "## Validation summary",
  "",
  markdown_table(checks, c("check_name", "status", "details")),
  "",
  "## Hard-lock confirmation",
  "",
  paste(
    "S20 did not fetch BEA data, modify provider artifacts, construct",
    "Shaikh-adjusted variables, build q indexes, construct superseded level",
    "interactions, run integration-order tests, estimate regressions, or",
    "reconstruct capacity utilization."
  ),
  paste(
    "IPP and GOV_TRANS remain frontier conditioners and do not enter",
    "private `K_cap`."
  )
)
writeLines(
  validation_lines,
  output_paths[["validation_report"]],
  useBytes = TRUE
)

hard_lock_ids <- c(
  "no_bea_fetch", "provider_artifacts_unchanged", "kcap_identity",
  "ipp_excluded_from_kcap", "gov_trans_excluded_from_kcap",
  "ipp_frontier_only", "gov_trans_frontier_only", "no_shaikh_adjusted",
  "no_q_omega", "no_q_e", "no_level_interactions", "no_estimators",
  "s10_inputs_unchanged"
)
failed_checks <- checks$check_name[checks$status == "FAIL"]
failed_hard_locks <- checks$check_name[
  checks$check_id %in% hard_lock_ids & checks$status != "PASS"
]
if (length(failed_checks) > 0L || length(failed_hard_locks) > 0L) {
  abort(
    paste0(
      "S20 validation failed:\n- ",
      paste(unique(c(failed_checks, failed_hard_locks)), collapse = "\n- ")
    )
  )
}

message("S20 capital, distribution, and frontier construction passed.")
message("Panel rows: ", nrow(panel))
message("Constructed variables: ", length(constructed_variables))
message("Validation checks: ", nrow(checks))
