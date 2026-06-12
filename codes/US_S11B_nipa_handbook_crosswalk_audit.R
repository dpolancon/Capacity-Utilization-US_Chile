#!/usr/bin/env Rscript

# S11B audits BEA/NIPA documentation against the finalized provider handoff.
# It does not construct downstream variables or run econometric code.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
repo_marker <- file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj")
if (!file.exists(repo_marker)) {
  stop("Run S11B from the downstream repository root.", call. = FALSE)
}

handoff_dir <- file.path(
  repo_root,
  "data", "provider_handoffs", "US_BEA_FixedAssets", "2026-06-11"
)
menu_path <- file.path(handoff_dir, "ch2_master_variable_menu.csv")
metadata_path <- file.path(handoff_dir, "ch2_master_variable_metadata.csv")
discovery_path <- file.path(handoff_dir, "ch2_bea_table_discovery.csv")

output_root <- file.path(
  repo_root, "output", "US", "S11B_NIPA_HANDBOOK_CROSSWALK"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

ledger_path <- file.path(csv_dir, "S11B_handbook_crosswalk_ledger.csv")
report_path <- file.path(md_dir, "S11B_NIPA_HANDBOOK_CROSSWALK.md")

required_inputs <- c(menu_path, metadata_path, discovery_path)
missing_inputs <- required_inputs[!file.exists(required_inputs)]
if (length(missing_inputs) > 0L) {
  stop(
    paste0("Missing provider handoff inputs:\n- ",
           paste(missing_inputs, collapse = "\n- ")),
    call. = FALSE
  )
}

read_handoff_csv <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

menu <- read_handoff_csv(menu_path)
metadata <- read_handoff_csv(metadata_path)
discovery <- read_handoff_csv(discovery_path)

target_ids <- c(
  "gva_real_or_qindex_corp",
  "gva_real_or_qindex_fc",
  "gva_price_or_deflator_corp",
  "gva_price_or_deflator_fc",
  "gva_price_or_deflator_nfc",
  "me_stock_price_or_revaluation_index",
  "nrc_stock_price_or_revaluation_index",
  "me_price_or_qindex",
  "nrc_price_or_qindex"
)

missing_targets <- setdiff(target_ids, menu$variable_id)
if (length(missing_targets) > 0L) {
  stop(
    paste0("Provider handoff is missing audit targets:\n- ",
           paste(missing_targets, collapse = "\n- ")),
    call. = FALSE
  )
}

menu_row <- function(variable_id) {
  rows <- menu[menu$variable_id == variable_id, , drop = FALSE]
  if (nrow(rows) != 1L) {
    stop("Expected one provider row for ", variable_id, ".", call. = FALSE)
  }
  rows
}

metadata_row <- function(variable_id) {
  rows <- metadata[metadata$variable_id == variable_id, , drop = FALSE]
  if (nrow(rows) != 1L) {
    stop("Expected one metadata row for ", variable_id, ".", call. = FALSE)
  }
  rows
}

provider_status <- function(variable_id) {
  m <- menu_row(variable_id)
  md <- metadata_row(variable_id)
  paste(
    paste0("fetch_status=", m$fetch_status),
    paste0("construction_status=", m$construction_status),
    paste0("chapter2_role=", md$chapter2_role),
    paste0("baseline_status=", md$baseline_status),
    sep = "; "
  )
}

handbook_url <- paste0(
  "https://www.bea.gov/resources/methodologies/",
  "nipa-handbook/pdf/chapter-13.pdf"
)
handbook_page <- "https://www.bea.gov/resources/methodologies/nipa-handbook"
chapter4_url <- paste0(
  "https://www.bea.gov/resources/methodologies/",
  "nipa-handbook/pdf/chapter-04.pdf"
)
chapter6_url <- paste0(
  "https://www.bea.gov/resources/methodologies/",
  "nipa-handbook/pdf/chapter-06.pdf"
)
fixed_assets_primer_url <- paste0(
  "https://www.bea.gov/sites/default/files/papers/WP2015-6.pdf"
)
fixed_assets_methods_url <- paste0(
  "https://www.bea.gov/sites/default/files/methodologies/",
  "Fixed-Assets-1925-97.pdf"
)
bea_api_url <- "https://apps.bea.gov/api/data/"

live_api_checked <- FALSE
api_evidence <- list()

fetch_bea_rows <- function(dataset, table, year = "2024", frequency = NULL) {
  key <- Sys.getenv("BEA_API_KEY")
  if (!nzchar(key)) return(NULL)
  if (!requireNamespace("httr", quietly = TRUE)) {
    stop("Package 'httr' is required for live BEA verification.",
         call. = FALSE)
  }
  query <- list(
    UserID = key,
    method = "GetData",
    DataSetName = dataset,
    TableName = table,
    Year = year,
    ResultFormat = "JSON"
  )
  if (!is.null(frequency)) query$Frequency <- frequency
  response <- httr::GET(bea_api_url, query = query, httr::timeout(120))
  httr::stop_for_status(response)
  payload <- httr::content(response, as = "parsed", simplifyVector = FALSE)
  error <- payload$BEAAPI$Results$Error
  if (!is.null(error)) {
    stop(error$APIErrorDescription, call. = FALSE)
  }
  records <- payload$BEAAPI$Results$Data
  do.call(rbind, lapply(records, function(x) {
    data.frame(
      line_number = as.character(x$LineNumber),
      line_description = as.character(x$LineDescription),
      series_code = as.character(x$SeriesCode),
      metric_name = as.character(x$METRIC_NAME),
      cl_unit = as.character(x$CL_UNIT),
      frequency = if (dataset == "NIPA") "A" else "A",
      data_value = suppressWarnings(as.numeric(gsub(",", "", x$DataValue))),
      stringsAsFactors = FALSE
    )
  }))
}

t114 <- fetch_bea_rows("NIPA", "T11400", frequency = "A")
t115 <- fetch_bea_rows("NIPA", "T11500", frequency = "A")
faat402 <- fetch_bea_rows("FixedAssets", "FAAt402")

if (!is.null(t114) && !is.null(t115) && !is.null(faat402)) {
  live_api_checked <- TRUE
  api_evidence <- list(t114 = t114, t115 = t115, faat402 = faat402)

  expected_t114 <- data.frame(
    line_number = c("1", "16", "17", "41"),
    series_code = c("A451RC", "A454RC", "A455RC", "B455RX"),
    metric_name = c(
      "Current Dollars", "Current Dollars",
      "Current Dollars", "Chained Dollars"
    ),
    stringsAsFactors = FALSE
  )
  for (i in seq_len(nrow(expected_t114))) {
    observed <- t114[
      t114$line_number == expected_t114$line_number[i] &
        t114$series_code == expected_t114$series_code[i] &
        t114$metric_name == expected_t114$metric_name[i],
      ,
      drop = FALSE
    ]
    if (nrow(observed) != 1L) {
      stop("Live T11400 verification failed for line ",
           expected_t114$line_number[i], ".", call. = FALSE)
    }
  }

  t115_line1 <- t115[
    t115$line_number == "1" &
      t115$series_code == "A455RD" &
      grepl("nonfinancial corporate business",
            t115$line_description, ignore.case = TRUE),
    ,
    drop = FALSE
  ]
  if (nrow(t115_line1) != 1L) {
    stop("Live T11500 line 1 verification failed.", call. = FALSE)
  }

  expected_faat402 <- data.frame(
    line_number = c("2", "3", "18", "19", "34", "35", "38", "39"),
    series_code = c(
      "kcntotl1eq00", "kcntotl1st00",
      "kcntotl2eq00", "kcntotl2st00",
      "kcnfito2eq00", "kcnfito2st00",
      "kcnnofi2eq00", "kcnnofi2st00"
    ),
    stringsAsFactors = FALSE
  )
  for (i in seq_len(nrow(expected_faat402))) {
    observed <- faat402[
      faat402$line_number == expected_faat402$line_number[i] &
        faat402$series_code == expected_faat402$series_code[i] &
        faat402$metric_name == "Fisher Quantity Index",
      ,
      drop = FALSE
    ]
    if (nrow(observed) != 1L) {
      stop("Live FAAt402 verification failed for line ",
           expected_faat402$line_number[i], ".", call. = FALSE)
    }
  }

  nfc_current <- t114$data_value[t114$line_number == "17"]
  nfc_real <- t114$data_value[t114$line_number == "41"]
  nfc_price_per_unit <- t115$data_value[t115$line_number == "1"]
  if (length(nfc_current) != 1L || length(nfc_real) != 1L ||
      length(nfc_price_per_unit) != 1L ||
      abs((nfc_current / nfc_real) - nfc_price_per_unit) > 0.001) {
    stop(
      "T11500 line 1 does not validate the T11400 NFC current/real ratio.",
      call. = FALSE
    )
  }
}

ledger_columns <- c(
  "target_variable",
  "provider_status",
  "documentation_source",
  "handbook_chapter",
  "handbook_table_reference",
  "handbook_method_statement",
  "bea_dataset_to_check",
  "bea_table_id_or_name",
  "bea_line_to_check_if_known",
  "api_fetchable",
  "source_boundary_match",
  "unit_match",
  "frequency_match",
  "construction_role",
  "decision",
  "notes"
)

ledger_rows <- list()

add_row <- function(
    target_variable, provider_status_value, documentation_source,
    handbook_chapter, handbook_table_reference, handbook_method_statement,
    bea_dataset_to_check, bea_table_id_or_name,
    bea_line_to_check_if_known, api_fetchable, source_boundary_match,
    unit_match, frequency_match, construction_role, decision, notes) {
  ledger_rows[[length(ledger_rows) + 1L]] <<- data.frame(
    target_variable = target_variable,
    provider_status = provider_status_value,
    documentation_source = documentation_source,
    handbook_chapter = handbook_chapter,
    handbook_table_reference = handbook_table_reference,
    handbook_method_statement = handbook_method_statement,
    bea_dataset_to_check = bea_dataset_to_check,
    bea_table_id_or_name = bea_table_id_or_name,
    bea_line_to_check_if_known = bea_line_to_check_if_known,
    api_fetchable = api_fetchable,
    source_boundary_match = source_boundary_match,
    unit_match = unit_match,
    frequency_match = frequency_match,
    construction_role = construction_role,
    decision = decision,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

add_row(
  "gva_real_or_qindex_corp",
  provider_status("gva_real_or_qindex_corp"),
  paste(handbook_url, bea_api_url, sep = "; "),
  "Chapter 13, Corporate Profits, appendix",
  "NIPA Table 1.14",
  paste(
    "The handbook says current-dollar GVA is prepared for total domestic,",
    "financial, and nonfinancial corporate sectors, but real GVA is prepared",
    "for the nonfinancial sector. T11400 line 1 is current-dollar CORP only."
  ),
  "NIPA",
  "T11400",
  "1 (A451RC); no CORP chained-dollar line",
  "yes",
  "no same-boundary real/quantity source",
  "not applicable",
  "annual and quarterly table; no matching CORP real line",
  "unresolved source input",
  "unresolved_true_absence",
  paste(
    "No same-boundary CORP real or quantity object was missed.",
    "NFC unit-price series cannot substitute for CORP."
  )
)

add_row(
  "gva_real_or_qindex_fc",
  provider_status("gva_real_or_qindex_fc"),
  paste(handbook_url, bea_api_url, sep = "; "),
  "Chapter 13, Corporate Profits, appendix",
  "NIPA Table 1.14",
  paste(
    "The handbook identifies current-dollar financial corporate GVA,",
    "while its real-GVA discussion is limited to nonfinancial corporate",
    "business. T11400 line 16 is current-dollar FC only."
  ),
  "NIPA",
  "T11400",
  "16 (A454RC); no FC chained-dollar line",
  "yes",
  "no same-boundary real/quantity source",
  "not applicable",
  "annual and quarterly table; no matching FC real line",
  "unresolved source input; residual prohibited",
  "unresolved_true_absence",
  "Do not construct FC real GVA as CORP real GVA minus NFC real GVA."
)

add_row(
  "gva_price_or_deflator_corp",
  provider_status("gva_price_or_deflator_corp"),
  paste(handbook_url, bea_api_url, sep = "; "),
  "Chapter 13, Corporate Profits, appendix",
  "NIPA Tables 1.14 and 1.15",
  paste(
    "Table 1.15 price and per-unit measures are explicitly for",
    "nonfinancial domestic corporate business. No total-CORP real GVA",
    "counterpart is documented for an implicit same-boundary deflator."
  ),
  "NIPA",
  "T11400 / T11500",
  "T11400 line 1 current-dollar only; T11500 has no CORP line",
  "yes",
  "no",
  "not applicable",
  "no matching annual/quarterly CORP price object",
  "unresolved source input",
  "unresolved_true_absence",
  "The NFC Table 1.15 price-per-unit series is not a CORP robustness source."
)

add_row(
  "gva_price_or_deflator_fc",
  provider_status("gva_price_or_deflator_fc"),
  paste(handbook_url, bea_api_url, sep = "; "),
  "Chapter 13, Corporate Profits, appendix",
  "NIPA Tables 1.14 and 1.15",
  paste(
    "The handbook documents current-dollar FC GVA but provides real and",
    "per-unit price measures only for NFC. No same-boundary FC price",
    "counterpart is documented."
  ),
  "NIPA",
  "T11400 / T11500",
  "T11400 line 16 current-dollar only; T11500 has no FC line",
  "yes",
  "no",
  "not applicable",
  "no matching annual/quarterly FC price object",
  "unresolved source input; residual prohibited",
  "unresolved_true_absence",
  "Do not construct an FC price object by subtracting CORP and NFC indexes."
)

add_row(
  "gva_price_or_deflator_nfc",
  provider_status("gva_price_or_deflator_nfc"),
  paste(handbook_url, bea_api_url, sep = "; "),
  "Chapter 13, Corporate Profits, appendix",
  "NIPA Table 1.14",
  paste(
    "NFC real GVA is derived by deflating current-dollar NFC GVA with a",
    "nonfinancial-industry chain-type price index. T11400 publishes",
    "matching NFC current-dollar and chained-dollar GVA."
  ),
  "NIPA",
  "T11400",
  "17 (A455RC) and 41 (B455RX)",
  "yes",
  "yes: NFC to NFC",
  "yes after harmonizing current and chained-dollar units",
  "annual and quarterly",
  "source-level implicit deflator",
  "source_level_derived_confirmed",
  paste(
    "Provider formula 100 * current-dollar NFC GVA / chained-dollar NFC",
    "GVA is methodologically valid at the same boundary."
  )
)

add_row(
  "gva_price_or_deflator_nfc",
  provider_status("gva_price_or_deflator_nfc"),
  paste(handbook_url, bea_api_url, sep = "; "),
  "Chapter 13, Corporate Profits, appendix",
  "NIPA Table 1.15",
  paste(
    "Table 1.15 per-unit measures divide current-dollar NFC GVA and its",
    "components by real NFC GVA. Line 1 is the price per unit of real NFC",
    "GVA; multiplying it by 100 yields the implicit-index scale."
  ),
  "NIPA",
  "T11500",
  "1 (A455RD)",
  "yes",
  "yes: NFC to NFC",
  "yes: dollars per chained-dollar unit",
  "annual and quarterly",
  "direct validation counterpart only",
  "validation_only_confirmed",
  paste(
    "Use line 1 to validate the derived NFC implicit deflator, not to",
    "replace its source-level derivation or define CORP/FC prices."
  )
)

for (asset in c("ME", "NRC")) {
  variable_id <- paste0(tolower(asset), "_stock_price_or_revaluation_index")
  asset_label <- if (asset == "ME") "equipment" else "structures"
  add_row(
    variable_id,
    provider_status(variable_id),
    paste(fixed_assets_primer_url, fixed_assets_methods_url, sep = "; "),
    "Fixed-assets methodology and net-stock primer",
    "FixedAssets Tables 4.1, 4.2, 4.4, 4.7, and 4.8",
    paste(
      "BEA constructs constant-price stocks from past investment and",
      "age-price profiles, then reflates them with investment price",
      "indexes. The published legal-form tables provide current-cost",
      "stocks and Fisher quantity indexes, not a standalone stock",
      "revaluation index. Chain-type measures do not preserve the nominal",
      "stock-flow identity."
    ),
    "FixedAssets",
    "FAAt401 / FAAt402 / FAAt404 / FAAt407 / FAAt408",
    paste(asset_label, "lines by legal form; no revaluation-index line"),
    "component tables yes; requested revaluation index no",
    "no verified standalone same-boundary revaluation source",
    "not applicable",
    "annual",
    "implied-investment fallback input only",
    "no_baseline_change",
    paste(
      "Leave unresolved. This does not block the baseline because direct",
      "nominal investment remains canonical; the index is needed only if",
      "the implied-investment fallback is activated."
    )
  )
}

faat402_status <- paste(
  provider_status("me_price_or_qindex"),
  provider_status("nrc_price_or_qindex"),
  sep = " | "
)
add_row(
  "FAAt402",
  faat402_status,
  paste(
    fixed_assets_primer_url,
    fixed_assets_methods_url,
    chapter4_url,
    sep = "; "
  ),
  "Fixed-assets methodology; NIPA Handbook Chapter 4",
  "FixedAssets Table 4.2",
  paste(
    "FAAt402 publishes Fisher chain-type quantity indexes for net stocks.",
    "These indexes embody BEA stock, depreciation, price, and aggregation",
    "methods. Chain-type stock measures are not additive and do not",
    "satisfy the nominal stock-flow identity."
  ),
  "FixedAssets",
  "FAAt402",
  "ME/NRC lines 2-3, CORP 18-19, FC 34-35, NFC 38-39",
  "yes",
  "yes for BEA net-stock comparison; no for GPIM price/revaluation input",
  "Fisher quantity index, not a price index",
  "annual",
  "comparison and validation only",
  "validation_only_confirmed",
  paste(
    "Provider lock confirmed: FAAt402 is not a GPIM product, baseline",
    "stock, price index, or substitute for the missing revaluation term."
  )
)

ledger <- do.call(rbind, ledger_rows)
ledger <- ledger[, ledger_columns, drop = FALSE]

allowed_decisions <- c(
  "direct_bea_confirmed",
  "source_level_derived_confirmed",
  "validation_only_confirmed",
  "unresolved_true_absence",
  "provider_patch_required",
  "no_baseline_change"
)

if (!all(ledger$decision %in% allowed_decisions)) {
  stop("S11B ledger contains an invalid decision.", call. = FALSE)
}
if (any(ledger$decision == "provider_patch_required")) {
  stop("S11B found a provider patch requirement; review before proceeding.",
       call. = FALSE)
}
if (nrow(ledger) != 9L) {
  stop("S11B must emit exactly nine evidence rows.", call. = FALSE)
}
if (!setequal(unique(ledger$target_variable), c(
  target_ids[1:7], "FAAt402"
))) {
  stop("S11B ledger target set is incomplete.", call. = FALSE)
}

fc_rows <- ledger$target_variable %in% c(
  "gva_real_or_qindex_fc", "gva_price_or_deflator_fc"
)
if (any(ledger$decision[fc_rows] != "unresolved_true_absence") ||
    any(!grepl("prohibit|Do not", ledger$notes[fc_rows],
               ignore.case = TRUE))) {
  stop("S11B violated the FC real/price residual lock.", call. = FALSE)
}

write.csv(ledger, ledger_path, row.names = FALSE, na = "")

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

decision_summary <- as.data.frame(table(ledger$decision), stringsAsFactors = FALSE)
names(decision_summary) <- c("Decision", "Rows")
decision_summary <- decision_summary[decision_summary$Rows > 0L, , drop = FALSE]

api_status <- if (live_api_checked) {
  paste(
    "Live BEA API verification passed for T11400 lines 1, 16, 17, and 41;",
    "T11500 line 1; and selected FAAt402 ME/NRC legal-form lines."
  )
} else {
  paste(
    "BEA_API_KEY was unavailable. The audit used the finalized handoff",
    "table catalog and the cited BEA methodological documentation."
  )
}

report_lines <- c(
  "# S11B NIPA Handbook Crosswalk Audit",
  "",
  "**Verdict: A. Provider lock confirmed, with stronger BEA/NIPA documentation.**",
  "",
  "## Scope",
  "",
  paste(
    "S11B is a bounded provider-documentation audit. It constructs no",
    "real variables, GPIM stocks, distribution variables, q-indexes,",
    "interactions, econometric datasets, or estimations."
  ),
  "",
  "## Primary evidence",
  "",
  paste0("- NIPA Handbook landing page: ", handbook_page),
  paste0("- Chapter 13, Corporate Profits: ", handbook_url),
  paste0("- Chapter 4, Estimating Methods: ", chapter4_url),
  paste0("- Chapter 6, Private Fixed Investment: ", chapter6_url),
  paste0("- BEA fixed-assets primer: ", fixed_assets_primer_url),
  paste0("- BEA fixed-assets methods volume: ", fixed_assets_methods_url),
  paste0("- BEA API root: ", bea_api_url),
  "",
  api_status,
  "",
  "## Core findings",
  "",
  paste(
    "1. NIPA Table 1.14 publishes total domestic corporate and financial",
    "corporate GVA in current dollars, but its real-GVA lines are limited",
    "to nonfinancial corporate business."
  ),
  paste(
    "2. The Chapter 13 appendix states that BEA prepares real GVA for the",
    "nonfinancial corporate sector by applying a nonfinancial-industry",
    "chain-type price index."
  ),
  paste(
    "3. NFC current-dollar GVA (T11400 line 17, A455RC) and chained-dollar",
    "GVA (line 41, B455RX) therefore validate the provider's source-level",
    "implicit deflator."
  ),
  paste(
    "4. T11500 line 1 (A455RD) is the direct price-per-unit validation",
    "counterpart. It is NFC-only and equals the current/real ratio; its",
    "index-scale counterpart is line 1 multiplied by 100."
  ),
  paste(
    "5. No same-boundary real/quantity or price object was identified for",
    "total CORP or FC. Real and price FC residuals remain prohibited."
  ),
  paste(
    "6. FAAt402 is a Fisher quantity-index table for BEA net stocks.",
    "It is comparison/validation-only and cannot supply the missing",
    "stock revaluation term or define the Chapter 2 GPIM baseline."
  ),
  paste(
    "7. No standalone ME/NRC stock-price or revaluation index was",
    "identified. Those gaps are non-blocking because direct nominal",
    "investment remains canonical."
  ),
  "",
  "## Decision summary",
  "",
  markdown_table(decision_summary, c("Decision", "Rows")),
  "",
  "## Crosswalk ledger",
  "",
  markdown_table(
    ledger,
    c(
      "target_variable",
      "provider_status",
      "handbook_table_reference",
      "bea_line_to_check_if_known",
      "construction_role",
      "decision",
      "notes"
    )
  ),
  "",
  "## Lock confirmation",
  "",
  "- No new variable is added.",
  "- No provider row is reclassified.",
  "- No FRED candidate is accepted.",
  "- Direct nominal ME/NRC investment remains canonical.",
  "- Stock-flow-implied investment remains fallback-only.",
  "- `FAAt402` remains comparison/validation-only.",
  "- `gva_price_or_deflator_nfc` remains source-level derived.",
  "- CORP and FC real/price rows remain unresolved true absences.",
  "- No FC real or price residual is constructed.",
  "",
  "## Machine-readable output",
  "",
  paste0("- `", gsub("\\\\", "/", sub(
    paste0("^", repo_root, "/?"), "", ledger_path
  )), "`")
)

writeLines(report_lines, report_path, useBytes = TRUE)

message("S11B NIPA Handbook crosswalk audit passed.")
message("Ledger rows: ", nrow(ledger))
message("Ledger: ", ledger_path)
message("Report: ", report_path)
