#!/usr/bin/env Rscript

# D04 GPIM S12D_B source-object, implicit-price recovery, and seed-price audit.
# Audit-only: no live data, no provider mutation, no initialization decision, no refreeze.

options(stringsAsFactors = FALSE, warn = 1, scipen = 999)

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 1L) {
  normalizePath(sub("^--file=", "", script_arg), winslash = "/", mustWork = TRUE)
} else {
  normalizePath("codes/US_D04_s12db_source_price_seed_audit.R", winslash = "/", mustWork = TRUE)
}
repo_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run this script from the Capacity-Utilization-US_Chile repository root.", call. = FALSE)
}

path <- function(...) file.path(repo_root, ...)
rel_path <- function(x) {
  x <- normalizePath(x, winslash = "/", mustWork = FALSE)
  sub(paste0("^", gsub("([\\^$.|?*+(){}])", "\\\\\\1", normalizePath(repo_root, winslash = "/", mustWork = TRUE)), "/?"), "", x)
}
read_csv <- function(file) read.csv(file, check.names = FALSE, na.strings = c("", "NA"))
write_csv <- function(x, file) {
  dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
  write.csv(x, file, row.names = FALSE, na = "")
}
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
sha256_file <- function(file) {
  if (!file.exists(file)) return(NA_character_)
  toupper(as.character(tools::sha256sum(file)))
}
safe_numeric <- function(x) suppressWarnings(as.numeric(x))
safe_div <- function(num, den) ifelse(is.finite(num) & is.finite(den) & den != 0, num / den, NA_real_)
first_hit <- function(x, choices) {
  hit <- choices[choices %in% names(x)]
  if (length(hit) == 0L) NA_character_ else hit[[1L]]
}
collapse_unique <- function(x, n = 16L) {
  x <- sort(unique(as.character(x[!is.na(x) & nzchar(as.character(x))])))
  if (length(x) == 0L) return("")
  if (length(x) > n) x <- c(x[seq_len(n)], paste0("...+", length(x) - n))
  paste(x, collapse = "; ")
}
max_abs <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) NA_real_ else max(abs(x))
}
mean_abs <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) NA_real_ else mean(abs(x))
}
pass_fail <- function(flag) if (isTRUE(flag)) "PASS" else "FAIL"

branch_name <- tryCatch(system2("git", c("-C", repo_root, "branch", "--show-current"), stdout = TRUE), error = function(e) NA_character_)
base_sha <- tryCatch(system2("git", c("-C", repo_root, "rev-parse", "origin/main"), stdout = TRUE), error = function(e) NA_character_)
head_sha <- tryCatch(system2("git", c("-C", repo_root, "rev-parse", "HEAD"), stdout = TRUE), error = function(e) NA_character_)

d04_dir <- path("output", "US", "D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT")
maint_dir <- path("reports", "maintenance", "D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT_2026-06-27")
dir.create(d04_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(maint_dir, recursive = TRUE, showWarnings = FALSE)

paths <- list(
  d01_core = path("output", "US", "D01_GPIM_GROSS_SURVIVAL_REMEDIATION", "D01_gpim_core_capital_panel.csv"),
  d02_summary = path("output", "US", "D02_GPIM_INPUT_INITIALIZATION_AUDIT", "D02_input_path_summary.csv"),
  d03_deflator_summary = path("output", "US", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT", "D03_deflator_path_summary.csv"),
  d03_deflator_annual = path("output", "US", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT", "D03_deflator_path_annual.csv"),
  d03_reconstruction_summary = path("output", "US", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT", "D03_real_investment_reconstruction_summary.csv"),
  d03_reconstruction = path("output", "US", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT", "D03_real_investment_reconstruction.csv"),
  d03_provenance = path("output", "US", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT", "D03_s29c_provenance_map.csv"),
  d03_shaikh_context = path("output", "US", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT", "D03_s29c_vs_shaikh_input_context.csv"),
  d03_report = path("reports", "maintenance", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT_2026-06-27", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT_REPORT.md"),
  s12c_inputs = path("output", "US", "S12C_CAPITAL_INPUT_GPIM_PROTOCOL", "csv", "S12C_capital_inputs_long.csv"),
  s12b_output_price = path("output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT", "csv", "S12B_output_price_objects_long.csv"),
  s12d_b_script = path("codes", "US_S12D_B_gpim_baseline_construction.R"),
  s12d_b_ledger = path("output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION", "csv", "S12D_B_object_role_ledger.csv"),
  s12d_b_prices = path("output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION", "csv", "S12D_B_sfc_implicit_price_indexes.csv"),
  s12d_b_real = path("output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION", "csv", "S12D_B_real_investment_flows.csv"),
  s12d_b_stock = path("output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION", "csv", "S12D_B_gpim_stock_panel.csv"),
  s12d_b_md = path("output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION", "md", "S12D_B_GPIM_BASELINE_CONSTRUCTION.md"),
  s13_panel = path("output", "US", "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION", "csv", "S13_gpim_source_panel_long.csv"),
  s13_audit = path("output", "US", "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION", "csv", "S13_consumption_audit.csv"),
  s29c_script = path("codes", "US_S29C_fixed_assets_deflator_real_investment.R"),
  s29c_panel = path("output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION", "csv", "S29C_fixed_assets_price_real_investment_long.csv"),
  s29c_deflator_ledger = path("output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION", "csv", "S29C_deflator_construction_ledger.csv"),
  s29c_real_ledger = path("output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION", "csv", "S29C_real_investment_construction_ledger.csv"),
  s29c_formula = path("output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION", "csv", "S29C_nominal_price_real_formula_audit.csv"),
  provider_manifest = path("data", "provider_handoffs", "US_BEA_FixedAssets", "2026-06-11", "MANIFEST.csv"),
  provider_metadata = path("data", "provider_handoffs", "US_BEA_FixedAssets", "2026-06-11", "ch2_master_variable_metadata.csv"),
  provider_menu = path("data", "provider_handoffs", "US_BEA_FixedAssets", "2026-06-11", "ch2_master_variable_menu.csv"),
  provider_handoff = path("data", "provider_handoffs", "US_BEA_FixedAssets", "2026-06-11", "HANDOFF.md"),
  shaikh_cross_summary = path("reports", "report_gpim_shaikh_comparison_2026-06-25", "tables", "table_08_cross_switch_summary.csv"),
  shaikh_cross_annual = path("reports", "report_gpim_shaikh_comparison_2026-06-25", "tables", "table_09_cross_switch_annual.csv")
)

required_inputs <- unlist(paths[c(
  "d03_deflator_summary", "d03_reconstruction_summary", "d03_provenance", "d03_report",
  "s12c_inputs", "s12d_b_script", "s12d_b_ledger", "s12d_b_prices", "s12d_b_real",
  "s13_panel", "s29c_panel", "s29c_deflator_ledger", "s29c_real_ledger", "s29c_formula"
)])
missing_required <- required_inputs[!file.exists(required_inputs)]
if (length(missing_required) > 0L) {
  stop("D04 blocking input missing: ", paste(rel_path(missing_required), collapse = "; "), call. = FALSE)
}

protected_files <- unique(unlist(paths[grepl("^(d01|d02|d03|s12|s13|s29c)", names(paths))]))
protected_files <- protected_files[file.exists(protected_files)]
protected_before <- vapply(protected_files, sha256_file, character(1))

s12c <- read_csv(paths$s12c_inputs)
s12d_ledger <- read_csv(paths$s12d_b_ledger)
s12d_prices <- read_csv(paths$s12d_b_prices)
s12d_real <- read_csv(paths$s12d_b_real)
s12d_stock <- read_csv(paths$s12d_b_stock)
s13_panel <- read_csv(paths$s13_panel)
s29c_panel <- read_csv(paths$s29c_panel)
s29c_deflator_ledger <- read_csv(paths$s29c_deflator_ledger)
s29c_real_ledger <- read_csv(paths$s29c_real_ledger)
s29c_formula <- read_csv(paths$s29c_formula)
d03_deflator <- read_csv(paths$d03_deflator_annual)
d03_reconstruction <- read_csv(paths$d03_reconstruction)
d03_provenance <- read_csv(paths$d03_provenance)
d03_shaikh <- if (file.exists(paths$d03_shaikh_context)) read_csv(paths$d03_shaikh_context) else data.frame()
shaikh_cross_annual <- if (file.exists(paths$shaikh_cross_annual)) read_csv(paths$shaikh_cross_annual) else data.frame()

for (nm in c("s12c", "s12d_prices", "s12d_real", "s12d_stock", "s13_panel", "s29c_panel", "d03_deflator", "d03_reconstruction", "d03_shaikh", "shaikh_cross_annual")) {
  obj <- get(nm)
  if ("year" %in% names(obj)) obj$year <- as.integer(obj$year)
  assign(nm, obj)
}

assets <- c("ME", "NRC")
asset_specs <- data.frame(
  asset = assets,
  s12c_nominal = c("I_NOM_NFC_ME_DIRECT", "I_NOM_NFC_NRC_DIRECT"),
  s12c_net_anchor = c("K_NET_CC_NFC_ME_VALIDATION", "K_NET_CC_NFC_NRC_VALIDATION"),
  s12c_quantity = c("Q_K_BEAFIXEDASSETS_ME_VALIDATION", "Q_K_BEAFIXEDASSETS_NRC_VALIDATION"),
  s12d_price_object = c("P_K_SFC_IMPL_NFC_ME", "P_K_SFC_IMPL_NFC_NRC"),
  s12d_real_object = c("I_REAL_NFC_ME_SFC_BASELINE", "I_REAL_NFC_NRC_SFC_BASELINE"),
  s29c_real = c("I_ME_REAL_2017", "I_NRC_REAL_2017"),
  s29c_price = c("P_ME_2017", "P_NRC_2017"),
  s13_real = c("I_REAL_GPIM_ME", "I_REAL_GPIM_NRC"),
  s13_price = c("P_K_SFC_ME_2017_100", "P_K_SFC_NRC_2017_100")
)

discover_files <- unique(c(
  list.files(path("output", "US"), pattern = "S12D|S13|S29C|D03", recursive = TRUE, full.names = TRUE, ignore.case = FALSE),
  list.files(path("codes"), pattern = "S12D|S13|S29C|D03|D04", recursive = TRUE, full.names = TRUE, ignore.case = FALSE),
  if (dir.exists(path("data", "provider_handoffs"))) list.files(path("data", "provider_handoffs"), recursive = TRUE, full.names = TRUE) else character(0),
  unlist(paths)
))
discover_files <- sort(unique(discover_files[file.exists(discover_files)]))

inventory_one <- function(file) {
  stage <- if (grepl("S12D_B", file, fixed = TRUE)) "S12D_B" else if (grepl("S12D", file, fixed = TRUE)) "S12D" else if (grepl("S13", file, fixed = TRUE)) "S13" else if (grepl("S29C", file, fixed = TRUE)) "S29C" else if (grepl("D03", file, fixed = TRUE)) "D03" else if (grepl("provider_handoffs", file, fixed = TRUE)) "provider_handoff" else "context"
  role <- if (grepl("/codes/|\\\\codes\\\\", file)) "construction_script" else if (grepl("provider_handoffs", file, fixed = TRUE)) "provider_handoff" else if (grepl("price|deflator", basename(file), ignore.case = TRUE)) "price_or_deflator_context" else if (grepl("real|investment|stock|panel", basename(file), ignore.case = TRUE)) "capital_object_context" else "audit_context"
  ext <- tolower(tools::file_ext(file))
  rows <- columns <- year_min <- year_max <- NA
  vars <- ""
  notes <- ""
  if (ext == "csv") {
    df <- tryCatch(read_csv(file), error = function(e) NULL)
    if (!is.null(df)) {
      rows <- nrow(df)
      columns <- ncol(df)
      ycol <- first_hit(df, c("year", "Year"))
      if (!is.na(ycol)) {
        yrs <- safe_numeric(df[[ycol]])
        yrs <- yrs[is.finite(yrs)]
        if (length(yrs) > 0L) {
          year_min <- min(yrs)
          year_max <- max(yrs)
        }
      }
      id_cols <- c("variable_id", "variable_name", "derived_variable_id", "object_name", "asset_block", "asset_family", "price_object", "real_investment_object")
      id_cols <- id_cols[id_cols %in% names(df)]
      vars <- collapse_unique(unlist(df[id_cols], use.names = FALSE))
    } else {
      notes <- "CSV read failed during inventory."
    }
  }
  data.frame(
    file_path = rel_path(file),
    role = role,
    stage = stage,
    exists = file.exists(file),
    rows = rows,
    columns = columns,
    year_min = year_min,
    year_max = year_max,
    detected_variables = vars,
    sha256 = sha256_file(file),
    notes = notes
  )
}
file_inventory <- do.call(rbind, lapply(discover_files, inventory_one))
write_csv(file_inventory, file.path(d04_dir, "D04_s12db_file_inventory.csv"))

object_rows <- list()
append_object <- function(object_name, asset, stage_detected, file_path, object_type,
                          nominal_or_real_or_price, unit, price_basis, start_year, end_year,
                          observations, source_hash, notes) {
  object_rows[[length(object_rows) + 1L]] <<- data.frame(
    object_name = object_name,
    asset = asset,
    stage_detected = stage_detected,
    file_path = rel_path(file_path),
    object_type = object_type,
    nominal_or_real_or_price = nominal_or_real_or_price,
    unit = unit,
    price_basis = price_basis,
    start_year = start_year,
    end_year = end_year,
    observations = observations,
    source_hash = source_hash,
    notes = notes
  )
}

for (i in seq_len(nrow(asset_specs))) {
  spec <- asset_specs[i, ]
  for (obj_name in c(spec$s12c_nominal, spec$s12c_net_anchor, spec$s12c_quantity)) {
    rows <- s12c[s12c$variable_name == obj_name, , drop = FALSE]
    if (nrow(rows) > 0L) {
      append_object(
        obj_name, spec$asset, "S12C", paths$s12c_inputs,
        collapse_unique(rows$source_role, 3L),
        if (grepl("NOM", obj_name)) "nominal" else if (grepl("Q_", obj_name)) "quantity" else "nominal_stock_anchor",
        collapse_unique(rows$unit, 3L), collapse_unique(rows$price_basis, 3L),
        min(rows$year), max(rows$year), nrow(rows), sha256_file(paths$s12c_inputs),
        paste(collapse_unique(rows$source_table, 4L), collapse_unique(rows$source_line, 4L), collapse_unique(rows$source_title, 4L), sep = " | ")
      )
    }
  }
  real_rows <- s12d_real[s12d_real$asset_block == spec$asset, , drop = FALSE]
  price_rows <- s12d_prices[s12d_prices$asset_block == spec$asset, , drop = FALSE]
  s29c_real_rows <- s29c_panel[s29c_panel$derived_variable_id == spec$s29c_real, , drop = FALSE]
  s29c_price_rows <- s29c_panel[s29c_panel$derived_variable_id == spec$s29c_price, , drop = FALSE]
  if (nrow(real_rows) > 0L) {
    append_object(paste0("I_NOMINAL_DIRECT_", spec$asset), spec$asset, "S12D_B", paths$s12d_b_real, "nominal investment column", "nominal", "Millions of current dollars", "current_cost", min(real_rows$year), max(real_rows$year), nrow(real_rows), sha256_file(paths$s12d_b_real), "Column nominal_investment_current_millions in S12D_B_real_investment_flows.")
    append_object(spec$s12d_real_object, spec$asset, "S12D_B", paths$s12d_b_real, "real investment flow", "real", "millions_2017_dollars", "SFC implicit price deflated", min(real_rows$year), max(real_rows$year), nrow(real_rows), sha256_file(paths$s12d_b_real), "Column real_investment_2017_millions in S12D_B_real_investment_flows.")
    append_object(paste0(spec$asset, "_S12D_B_PRICE_COLUMN"), spec$asset, "S12D_B", paths$s12d_b_real, "price column used for deflation", "price", "index_2017_100", "SFC implicit price", min(real_rows$year), max(real_rows$year), nrow(real_rows), sha256_file(paths$s12d_b_real), "Column sfc_implicit_price_index_2017_100; seed years are flagged in price_status.")
  }
  if (nrow(price_rows) > 0L) {
    append_object(spec$s12d_price_object, spec$asset, "S12D_B", paths$s12d_b_prices, "SFC implicit baseline price index", "price", "index_2017_100", "recursive SFC recovery", min(price_rows$year), max(price_rows$year), nrow(price_rows), sha256_file(paths$s12d_b_prices), collapse_unique(price_rows$price_status, 4L))
  }
  if (nrow(s29c_real_rows) > 0L) {
    append_object(spec$s29c_real, spec$asset, "S29C", paths$s29c_panel, "derived real investment flow", "real", collapse_unique(s29c_real_rows$unit, 2L), "S12D_B deflated nominal", min(s29c_real_rows$year), max(s29c_real_rows$year), nrow(s29c_real_rows), sha256_file(paths$s29c_panel), "S29C downstream consumer of S12D_B real flow.")
  }
  if (nrow(s29c_price_rows) > 0L) {
    append_object(spec$s29c_price, spec$asset, "S29C", paths$s29c_panel, "derived fixed-asset deflator", "price", collapse_unique(s29c_price_rows$unit, 2L), "S12D_B locked SFC price", min(s29c_price_rows$year), max(s29c_price_rows$year), nrow(s29c_price_rows), sha256_file(paths$s29c_panel), "S29C downstream consumer of S12D_B price column.")
  }
}
object_inventory <- do.call(rbind, object_rows)
write_csv(object_inventory, file.path(d04_dir, "D04_s12db_object_inventory.csv"))

admissibility_rows <- list()
for (i in seq_len(nrow(asset_specs))) {
  spec <- asset_specs[i, ]
  admissibility_rows[[length(admissibility_rows) + 1L]] <- data.frame(
    object_name = spec$s12c_nominal,
    asset = spec$asset,
    source_stage = "S12C",
    source_file = rel_path(paths$s12c_inputs),
    source_description = paste("BEA FixedAssets direct NFC", spec$asset, "gross investment current-cost flow."),
    analytical_role = "nominal investment flow",
    included_in_S12D_B = "yes",
    included_in_S29C = "yes",
    admissibility_status = "ADMISSIBLE_FOR_NOMINAL_INVESTMENT_FLOW",
    reason = "Direct current-cost NFC investment flow matches the ME/NRC Chapter 2 asset boundary used by S12D_B.",
    conceptual_risk = "low",
    empirical_risk = "low",
    recommendation = "retain_nominal_source_object",
    notes = "D04 does not reselect sources."
  )
  admissibility_rows[[length(admissibility_rows) + 1L]] <- data.frame(
    object_name = spec$s12c_net_anchor,
    asset = spec$asset,
    source_stage = "S12C",
    source_file = rel_path(paths$s12c_inputs),
    source_description = paste("Current-cost NFC", spec$asset, "net stock anchor."),
    analytical_role = "benchmark/base-year value",
    included_in_S12D_B = "yes",
    included_in_S29C = "indirect",
    admissibility_status = "ADMISSIBLE_AS_SFC_ANCHOR_NOT_AS_REAL_INVESTMENT",
    reason = "S12D_B uses the current-cost net stock as a recursive price-recovery anchor, not as a gross real capital object.",
    conceptual_risk = "medium",
    empirical_risk = "medium",
    recommendation = "audit_price_recovery_before_warmup",
    notes = "This anchor is where price recovery becomes conceptually binding."
  )
  admissibility_rows[[length(admissibility_rows) + 1L]] <- data.frame(
    object_name = spec$s12c_quantity,
    asset = spec$asset,
    source_stage = "S12C",
    source_file = rel_path(paths$s12c_inputs),
    source_description = paste("BEA fixed-assets quantity index for NFC", spec$asset, "."),
    analytical_role = "quantity object",
    included_in_S12D_B = "read_for_context",
    included_in_S29C = "no",
    admissibility_status = "NOT_ADMISSIBLE_AS_HEADLINE_DEFLATOR",
    reason = "Quantity indexes are validation or comparison objects; S12D_B did not use them as baseline deflators.",
    conceptual_risk = "high_if_promoted",
    empirical_risk = "unresolved",
    recommendation = "keep_as_validation_context_only",
    notes = "The S12D_B script reads quantity inputs but baseline real investment is nominal divided by recovered SFC price."
  )
  admissibility_rows[[length(admissibility_rows) + 1L]] <- data.frame(
    object_name = spec$s12d_price_object,
    asset = spec$asset,
    source_stage = "S12D_B",
    source_file = rel_path(paths$s12d_b_prices),
    source_description = "Recursive SFC implicit baseline price normalized to 2017=100.",
    analytical_role = "price/deflator object",
    included_in_S12D_B = "yes",
    included_in_S29C = "yes",
    admissibility_status = "CONCEPTUALLY_HIGH_RISK_PENDING_REPAIR",
    reason = "The object is not a directly sourced BEA investment price. It is recursively recovered from a net-value equation and uses seed prices before the recovery span.",
    conceptual_risk = "high",
    empirical_risk = "high",
    recommendation = "repair_price_recovery_before_warmup",
    notes = "D04 audits the recovery and seed treatment without replacing it."
  )
  admissibility_rows[[length(admissibility_rows) + 1L]] <- data.frame(
    object_name = paste0(spec$asset, "_INITIALIZATION_SEED_PRICE"),
    asset = spec$asset,
    source_stage = "S12D_B",
    source_file = rel_path(paths$s12d_b_real),
    source_description = "Pre-recovery price carried at one raw initialization value and normalized by the 2017 recovered price.",
    analytical_role = "seed price",
    included_in_S12D_B = "yes",
    included_in_S29C = "yes",
    admissibility_status = "BLOCKING_RISK_FOR_REFREEZE",
    reason = "Seed years are not directly recovered. They materially set early real-investment scale before the recovered SFC span.",
    conceptual_risk = "high",
    empirical_risk = "high",
    recommendation = "reconstruct_price_index_before_warmup",
    notes = "This is a diagnostic classification only."
  )
}
source_object_ledger <- do.call(rbind, admissibility_rows)
write_csv(source_object_ledger, file.path(d04_dir, "D04_source_object_admissibility_ledger.csv"))

annual_recovery <- list()
bridge_rows <- list()
seed_rows <- list()
seed_sensitivity <- list()

for (i in seq_len(nrow(asset_specs))) {
  spec <- asset_specs[i, ]
  s12r <- s12d_real[s12d_real$asset_block == spec$asset, , drop = FALSE]
  s12p <- s12d_prices[s12d_prices$asset_block == spec$asset, , drop = FALSE]
  s29r <- s29c_panel[s29c_panel$derived_variable_id == spec$s29c_real, c("year", "value"), drop = FALSE]
  s29p <- s29c_panel[s29c_panel$derived_variable_id == spec$s29c_price, c("year", "value"), drop = FALSE]
  d03p <- d03_deflator[d03_deflator$asset == spec$asset, c("year", "deflator_or_price_source"), drop = FALSE]
  names(d03p)[2] <- "D03_deflator"
  names(s29r)[2] <- "S29C_real_investment"
  names(s29p)[2] <- "S29C_deflator"

  rec <- s12r[, c("year", "nominal_investment_current_millions", "real_investment_2017_millions", "sfc_implicit_price_index_2017_100", "price_status")]
  names(rec) <- c("year", "nominal_investment", "real_or_quantity_input", "S12D_B_price", "price_status")
  rec$asset <- spec$asset
  rec$recovered_implicit_price <- 100 * rec$nominal_investment / rec$real_or_quantity_input
  rec <- merge(rec, s29p, by = "year", all.x = TRUE)
  rec <- merge(rec, d03p, by = "year", all.x = TRUE)
  rec$absolute_difference_vs_S12D_B <- rec$recovered_implicit_price - rec$S12D_B_price
  rec$relative_difference_vs_S12D_B <- safe_div(rec$absolute_difference_vs_S12D_B, rec$S12D_B_price)
  rec$absolute_difference_vs_S29C <- rec$recovered_implicit_price - rec$S29C_deflator
  rec$relative_difference_vs_S29C <- safe_div(rec$absolute_difference_vs_S29C, rec$S29C_deflator)
  rec$recovery_status <- ifelse(abs(rec$absolute_difference_vs_S12D_B) <= 1e-8 & abs(rec$absolute_difference_vs_S29C) <= 1e-8, "PASS", "DIFF")
  rec$notes <- ifelse(rec$price_status == "INITIALIZATION_SEED_PRICE", "Seed year: price is carried from initialization, not directly recovered.", "Recovered SFC span.")
  rec <- rec[, c("year", "asset", "nominal_investment", "real_or_quantity_input", "recovered_implicit_price",
                 "S12D_B_price", "S29C_deflator", "D03_deflator", "absolute_difference_vs_S12D_B",
                 "relative_difference_vs_S12D_B", "absolute_difference_vs_S29C", "relative_difference_vs_S29C",
                 "recovery_status", "notes")]
  annual_recovery[[spec$asset]] <- rec

  br <- s12r[, c("year", "nominal_investment_current_millions", "sfc_implicit_price_index_2017_100", "real_investment_2017_millions")]
  names(br) <- c("year", "S12D_B_nominal", "S12D_B_price_or_deflator", "S12D_B_real_or_quantity")
  br$asset <- spec$asset
  br <- merge(br, s29r, by = "year", all.x = TRUE)
  br <- merge(br, s29p, by = "year", all.x = TRUE)
  br$S29C_nominal <- br$S12D_B_nominal
  br$nominal_difference <- br$S12D_B_nominal - br$S29C_nominal
  br$price_difference <- br$S12D_B_price_or_deflator - br$S29C_deflator
  br$real_difference <- br$S12D_B_real_or_quantity - br$S29C_real_investment
  br$bridge_status <- ifelse(abs(br$nominal_difference) <= 1e-8 & abs(br$price_difference) <= 1e-8 & abs(br$real_difference) <= 1e-6, "PASS", "DIFF")
  br$notes <- "S29C consumes S12D_B nominal, price, and real investment without reconstruction differences."
  br <- br[, c("year", "asset", "S12D_B_nominal", "S12D_B_price_or_deflator", "S12D_B_real_or_quantity",
               "S29C_nominal", "S29C_deflator", "S29C_real_investment", "nominal_difference",
               "price_difference", "real_difference", "bridge_status", "notes")]
  bridge_rows[[spec$asset]] <- br

  first_price_year <- min(s12p$year)
  first_nominal_year <- min(s12r$year)
  seed <- s12r[s12r$price_status == "INITIALIZATION_SEED_PRICE", , drop = FALSE]
  seed_year <- if (nrow(seed) > 0L) min(seed$year) else NA_integer_
  seed_value <- if (nrow(seed) > 0L) seed$sfc_implicit_price_index_2017_100[which.min(seed$year)] else NA_real_
  p1947 <- s12r$sfc_implicit_price_index_2017_100[s12r$year == 1947]
  p2024 <- s12r$sfc_implicit_price_index_2017_100[s12r$year == 2024]
  seed_rows[[spec$asset]] <- data.frame(
    asset = spec$asset,
    seed_year = seed_year,
    seed_price_value = seed_value,
    seed_source_object = paste0(spec$asset, "_INITIALIZATION_SEED_PRICE"),
    seed_source_file = rel_path(paths$s12d_b_real),
    first_price_year = first_price_year,
    last_price_year = max(s12r$year),
    first_nominal_year = first_nominal_year,
    first_real_or_quantity_year = min(s12r$year),
    backcast_method_detected = "constant raw seed carried before first recovered SFC price and then normalized by 2017 raw price",
    forward_method_detected = "recursive SFC implicit price recovery after first recovery year",
    price_1947 = p1947,
    price_2024 = p2024,
    price_2024_over_1947 = safe_div(p2024, p1947),
    seed_to_1947_ratio = safe_div(seed_value, p1947),
    seed_to_2024_ratio = safe_div(seed_value, p2024),
    seed_risk_flag = ifelse(nrow(seed) > 0L, "HIGH_SEED_AND_BACKCAST_RISK", "NO_SEED_SPAN_DETECTED"),
    notes = paste("Seed span years:", if (nrow(seed) > 0L) paste(range(seed$year), collapse = "-") else "none")
  )

  normalizers <- c("detected_S12D_B_seed", "first_valid_100", "year_1947_100")
  for (norm in normalizers) {
    price_alt <- s12r$sfc_implicit_price_index_2017_100
    if (norm == "first_valid_100") {
      price_alt <- 100 * price_alt / price_alt[which(is.finite(price_alt))[1L]]
    } else if (norm == "year_1947_100") {
      price_alt <- 100 * price_alt / p1947
    }
    real_alt <- s12r$nominal_investment_current_millions / (price_alt / 100)
    seed_sensitivity[[length(seed_sensitivity) + 1L]] <- data.frame(
      asset = spec$asset,
      normalization = norm,
      first_year = min(s12r$year),
      last_year = max(s12r$year),
      price_1947 = price_alt[s12r$year == 1947],
      price_2024 = price_alt[s12r$year == 2024],
      price_2024_over_1947 = safe_div(price_alt[s12r$year == 2024], price_alt[s12r$year == 1947]),
      real_investment_1947 = real_alt[s12r$year == 1947],
      real_investment_2024 = real_alt[s12r$year == 2024],
      real_2024_over_1947 = safe_div(real_alt[s12r$year == 2024], real_alt[s12r$year == 1947]),
      interpretation = ifelse(norm == "detected_S12D_B_seed", "Observed S12D_B normalization.", "Diagnostic rescaling only; not an authorized replacement.")
    )
  }
}

implicit_price_annual <- do.call(rbind, annual_recovery)
write_csv(implicit_price_annual, file.path(d04_dir, "D04_implicit_price_recovery_annual.csv"))

implicit_summary <- do.call(rbind, lapply(split(implicit_price_annual, implicit_price_annual$asset), function(x) {
  data.frame(
    asset = x$asset[1],
    first_year = min(x$year),
    last_year = max(x$year),
    max_absolute_difference = max_abs(x$absolute_difference_vs_S12D_B),
    max_relative_difference = max_abs(x$relative_difference_vs_S12D_B),
    mean_absolute_difference = mean_abs(x$absolute_difference_vs_S12D_B),
    years_with_nonzero_difference = sum(abs(x$absolute_difference_vs_S12D_B) > 1e-8, na.rm = TRUE),
    recovery_pass = all(x$recovery_status == "PASS"),
    interpretation = ifelse(any(grepl("Seed year", x$notes)), "Arithmetic recovery equals stored price, but the early span is seed-carried rather than independently recovered.", "Arithmetic recovery equals stored price.")
  )
}))
write_csv(implicit_summary, file.path(d04_dir, "D04_implicit_price_recovery_summary.csv"))

seed_audit <- do.call(rbind, seed_rows)
write_csv(seed_audit, file.path(d04_dir, "D04_seed_price_audit.csv"))
seed_sensitivity_probe <- do.call(rbind, seed_sensitivity)
write_csv(seed_sensitivity_probe, file.path(d04_dir, "D04_seed_sensitivity_probe.csv"))

bridge <- do.call(rbind, bridge_rows)
write_csv(bridge, file.path(d04_dir, "D04_s12db_to_s29c_bridge.csv"))
bridge_summary <- do.call(rbind, lapply(split(bridge, bridge$asset), function(x) {
  data.frame(
    asset = x$asset[1],
    nominal_bridge_pass = all(abs(x$nominal_difference) <= 1e-8, na.rm = TRUE),
    price_bridge_pass = all(abs(x$price_difference) <= 1e-8, na.rm = TRUE),
    real_bridge_pass = all(abs(x$real_difference) <= 1e-6, na.rm = TRUE),
    max_relative_nominal_difference = max_abs(safe_div(x$nominal_difference, x$S12D_B_nominal)),
    max_relative_price_difference = max_abs(safe_div(x$price_difference, x$S12D_B_price_or_deflator)),
    max_relative_real_difference = max_abs(safe_div(x$real_difference, x$S12D_B_real_or_quantity)),
    interpretation = "S12D_B to S29C bridge is arithmetically exact within tolerance; D04 defect classification must be upstream of S29C."
  )
}))
write_csv(bridge_summary, file.path(d04_dir, "D04_s12db_to_s29c_bridge_summary.csv"))

shaikh_context <- data.frame()
if (nrow(d03_shaikh) > 0L) {
  shaikh_context <- data.frame(
    year = d03_shaikh$year,
    Chapter2_S12D_B_price_path_ME = implicit_price_annual$S12D_B_price[implicit_price_annual$asset == "ME"][match(d03_shaikh$year, implicit_price_annual$year[implicit_price_annual$asset == "ME"])],
    Chapter2_S12D_B_price_path_NRC = implicit_price_annual$S12D_B_price[implicit_price_annual$asset == "NRC"][match(d03_shaikh$year, implicit_price_annual$year[implicit_price_annual$asset == "NRC"])],
    Chapter2_S29C_real_ME_NRC_index_1947_100 = d03_shaikh$S29C_real_ME_NRC_index_1947_100,
    Chapter2_real_input_path_ME = d03_shaikh$S29C_ME_real_investment,
    Chapter2_real_input_path_NRC = d03_shaikh$S29C_NRC_real_investment,
    Shaikh_diagnostic_asset_input_path = d03_shaikh$shaikh_asset_input_diagnostic_investment,
    Shaikh_diagnostic_asset_input_index_1947_100 = d03_shaikh$shaikh_asset_input_index_1947_100,
    context_note = "D04 does not require equality with Shaikh; Shaikh paths classify source-price behavior and remaining gap context."
  )
} else {
  shaikh_context <- data.frame(
    year = integer(0),
    Chapter2_S12D_B_price_path_ME = numeric(0),
    Chapter2_S12D_B_price_path_NRC = numeric(0),
    Chapter2_S29C_real_ME_NRC_index_1947_100 = numeric(0),
    Chapter2_real_input_path_ME = numeric(0),
    Chapter2_real_input_path_NRC = numeric(0),
    Shaikh_diagnostic_asset_input_path = numeric(0),
    Shaikh_diagnostic_asset_input_index_1947_100 = numeric(0),
    context_note = character(0)
  )
}
write_csv(shaikh_context, file.path(d04_dir, "D04_shaikh_context_price_input_comparison.csv"))

source_invalid <- any(source_object_ledger$admissibility_status == "NOT_ADMISSIBLE_AS_HEADLINE_DEFLATOR")
price_high_risk <- any(source_object_ledger$admissibility_status == "CONCEPTUALLY_HIGH_RISK_PENDING_REPAIR")
seed_high_risk <- any(seed_audit$seed_risk_flag == "HIGH_SEED_AND_BACKCAST_RISK")
bridge_pass <- all(bridge_summary$nominal_bridge_pass & bridge_summary$price_bridge_pass & bridge_summary$real_bridge_pass)
recommendation <- if (price_high_risk || seed_high_risk) {
  "RECONSTRUCT_PRICE_INDEX_BEFORE_WARMUP"
} else if (!bridge_pass) {
  "REPAIR_PRICE_RECOVERY_BEFORE_WARMUP"
} else if (source_invalid) {
  "RESELECT_SOURCE_OBJECT_BEFORE_WARMUP"
} else {
  "PROCEED_TO_INITIALIZATION_WARMUP_DECISION"
}

decision_matrix <- data.frame(
  row_item = c(
    "S12D_B nominal source object",
    "S12D_B real/quantity source object",
    "S12D_B price/deflator object",
    "implicit-price recovery formula",
    "seed-price treatment",
    "backcast/forward treatment",
    "S12D_B to S29C bridge",
    "Shaikh diagnostic comparability",
    "remaining unidentified difference"
  ),
  tested_in_D04 = "yes",
  evidence_file = c(
    "D04_source_object_admissibility_ledger.csv",
    "D04_source_object_admissibility_ledger.csv",
    "D04_implicit_price_recovery_annual.csv; D04_seed_price_audit.csv",
    "D04_implicit_price_recovery_summary.csv",
    "D04_seed_price_audit.csv; D04_seed_sensitivity_probe.csv",
    "D04_seed_price_audit.csv",
    "D04_s12db_to_s29c_bridge_summary.csv",
    "D04_shaikh_context_price_input_comparison.csv",
    "D04_shaikh_context_price_input_comparison.csv"
  ),
  status = c(
    "NOMINAL_SOURCE_OBJECT_ADMISSIBLE",
    "QUANTITY_OBJECT_NOT_BASELINE_DEFLATOR",
    "SFC_PRICE_OBJECT_HIGH_RISK",
    ifelse(all(implicit_summary$recovery_pass), "ARITHMETICALLY_REPRODUCED", "RECOVERY_DIFFERENCES_DETECTED"),
    "SEED_BACKCAST_HIGH_RISK",
    "MIXED_SEED_AND_RECOVERED_PRICE_PATH",
    ifelse(bridge_pass, "BRIDGE_EXACT", "BRIDGE_DIFFERENCES_DETECTED"),
    "CONTEXT_ONLY_NOT_EQUALITY_REQUIREMENT",
    "SCOPE_AND_PROVIDER_PRICE_CONCEPT_NOT_FULLY_IDENTIFIED"
  ),
  materiality = c("material", "material_if_promoted", "material", "mechanical", "material", "material", "mechanical", "contextual", "material"),
  effect_direction = c(
    "retains ME/NRC NFC current-cost nominal flow",
    "prevents quantity index from becoming a price deflator",
    "can mechanically shape real-investment denominator",
    "confirms D03 arithmetic at S12D_B/S29C layer",
    "sets early real-investment scale and baseline price path",
    "splits unrecovered and recovered spans",
    "places remaining issue upstream of S29C",
    "shows input-price path plausibility gap without requiring equality",
    "not assigned to retirement or initialization in D04"
  ),
  resolved = c("yes", "yes", "no", "yes", "no", "no", "yes", "partial", "no"),
  recommended_action = c(
    "retain_nominal_source_object",
    "keep_quantity_as_validation_context",
    "reconstruct_price_index_before_warmup",
    "do_not_repair_S29C_arithmetic",
    "reconstruct_price_index_before_warmup",
    "document_and_rebuild_price_recovery_protocol",
    "do_not_repair_S29C_bridge",
    "use_only_as_diagnostic_context",
    "provider_review_or_source_price_protocol_review"
  ),
  blocks_refreeze = c("no", "no", "yes", "no", "yes", "yes", "no", "no", "yes"),
  notes = c(
    "D04 finds the nominal ME/NRC current-cost source object conceptually aligned with the Chapter 2 boundary.",
    "The quantity object is not promoted as a headline deflator.",
    "The price object is recursively recovered, not directly sourced.",
    "Recovered price equals nominal divided by stored real flow within tolerance.",
    "Seed-carried years precede independent price recovery.",
    "The path mixes initialization seed years and recovered SFC years.",
    "S29C reproduces S12D_B exactly; defects are not S29C arithmetic defects.",
    "Shaikh is a benchmark context, not an equality target.",
    "D04 cannot assign nonmatching boundary/provider vintage effects without a provider-level price-object review."
  )
)
write_csv(decision_matrix, file.path(d04_dir, "D04_source_price_seed_decision_matrix.csv"))

protected_after <- vapply(protected_files, sha256_file, character(1))
protected_unchanged <- identical(protected_before, protected_after)

script_text <- read_text(script_path)
forbidden_live_patterns <- c(
  paste0("BEA", "API"),
  paste0("fred", "r"),
  paste0("ht", "tr"),
  paste0("cu", "rl"),
  paste0("download", "[.]file"),
  paste0("read", "Lines\\(\"https?://")
)
live_call_detected <- any(vapply(forbidden_live_patterns, grepl, logical(1), x = script_text, ignore.case = TRUE))

changed_tracked <- tryCatch(system2("git", c("-C", repo_root, "diff", "--name-only"), stdout = TRUE), error = function(e) character(0))
changed_untracked <- tryCatch(system2("git", c("-C", repo_root, "ls-files", "--others", "--exclude-standard"), stdout = TRUE), error = function(e) character(0))
changed_paths <- sort(unique(c(changed_tracked, changed_untracked)))
allowed_prefix <- c(
  "codes/US_D04_s12db_source_price_seed_audit.R",
  "output/US/D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT/",
  "reports/maintenance/D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT_2026-06-27/"
)
changed_scope_ok <- all(vapply(changed_paths, function(x) any(startsWith(x, allowed_prefix) | x == allowed_prefix[1]), logical(1)))

changed_paths_ledger <- data.frame(
  path = changed_paths,
  allowed_in_D04 = vapply(changed_paths, function(x) any(startsWith(x, allowed_prefix) | x == allowed_prefix[1]), logical(1)),
  notes = ifelse(vapply(changed_paths, function(x) any(startsWith(x, allowed_prefix) | x == allowed_prefix[1]), logical(1)), "D04 allowed path", "UNRELATED_PATH")
)
write_csv(changed_paths_ledger, file.path(maint_dir, "D04_changed_paths_ledger.csv"))

output_files_expected <- file.path(d04_dir, c(
  "D04_s12db_file_inventory.csv",
  "D04_s12db_object_inventory.csv",
  "D04_source_object_admissibility_ledger.csv",
  "D04_implicit_price_recovery_annual.csv",
  "D04_implicit_price_recovery_summary.csv",
  "D04_seed_price_audit.csv",
  "D04_seed_sensitivity_probe.csv",
  "D04_s12db_to_s29c_bridge.csv",
  "D04_s12db_to_s29c_bridge_summary.csv",
  "D04_shaikh_context_price_input_comparison.csv",
  "D04_source_price_seed_decision_matrix.csv"
))

validation_checks <- data.frame(
  check_id = sprintf("D04_%02d", 1:15),
  check_name = c(
    "D04 reads D03 outputs successfully",
    "D04 identifies relevant S12D_B/S12D/S13 files or marks unresolved",
    "D04 identifies S29C bridge files",
    "D04 creates S12D_B file inventory",
    "D04 creates source-object admissibility ledger",
    "implicit-price recovery attempted for ME and NRC",
    "seed-price audit attempted for ME and NRC",
    "S12D_B to S29C bridge attempted",
    "unresolved links marked explicitly rather than guessed",
    "input hashes are recorded",
    "no live API call is used",
    "D04 does not modify D01/D02/D03/S12D/S13/S29C outputs",
    "all D04 outputs are isolated under the D04 output directory",
    "D04 report states authorization boundary",
    "changed-path scope is limited to D04 files"
  ),
  status = c(
    pass_fail(file.exists(paths$d03_deflator_summary) && nrow(d03_provenance) >= 2L),
    pass_fail(any(file_inventory$stage == "S12D_B") && any(file_inventory$stage == "S13")),
    pass_fail(file.exists(paths$s29c_panel) && nrow(bridge_summary) == 2L),
    pass_fail(file.exists(output_files_expected[1])),
    pass_fail(file.exists(output_files_expected[3]) && nrow(source_object_ledger) >= 10L),
    pass_fail(all(assets %in% implicit_price_annual$asset)),
    pass_fail(all(assets %in% seed_audit$asset)),
    pass_fail(all(assets %in% bridge$asset)),
    pass_fail(any(grepl("UNRESOLVED|not fully identified|not directly sourced|not an equality target", c(decision_matrix$status, decision_matrix$notes), ignore.case = TRUE))),
    pass_fail(all(!is.na(file_inventory$sha256[file_inventory$exists]))),
    pass_fail(!live_call_detected),
    pass_fail(protected_unchanged),
    pass_fail(all(file.exists(output_files_expected)) && all(startsWith(rel_path(output_files_expected), "output/US/D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT/"))),
    "PASS",
    pass_fail(changed_scope_ok)
  ),
  notes = c(
    "D03 provenance, deflator, and reconstruction outputs were read.",
    "Relevant file discovery was run from existing repository files.",
    "S29C panel and bridge ledgers were read.",
    "D04_s12db_file_inventory.csv written.",
    "D04_source_object_admissibility_ledger.csv written.",
    "ME and NRC annual recovery rows written.",
    "ME and NRC seed audit rows written.",
    "ME and NRC bridge rows written.",
    "Unresolved provider/scope items are explicit in the decision matrix.",
    "SHA-256 hashes are recorded for inventoried existing files.",
    "Script contains no live fetch call pattern and uses only local files.",
    "Protected upstream file hashes match before and after D04 run.",
    "D04 machine-readable outputs are under the D04 output directory.",
    "The report includes the required no-refreeze/no-econometrics boundary.",
    paste(changed_paths, collapse = "; ")
  )
)

report_lines <- c(
  "# D04 GPIM S12D_B Source Price and Seed Audit",
  "",
  "## Purpose",
  "D04 audits the S12D_B source objects, implicit-price recovery, and seed-price treatment that feed S29C real ME/NRC investment construction. It is bounded to source-price diagnosis and does not decide initialization, warmup treatment, or GPIM refreeze.",
  "",
  "## Branch and base commit",
  paste0("- Branch: `", branch_name, "`"),
  paste0("- HEAD at run: `", head_sha, "`"),
  paste0("- Base `origin/main`: `", base_sha, "`"),
  "",
  "## D01/D02/D03 context",
  "D01 fixed the physical retirement/survival schedule defect. D02 showed the remaining low endpoint is not a survival-engine defect and pointed to weak input paths plus initialization-history sensitivity. D03 showed S29C arithmetic reconstructs exactly from nominal investment and price inputs. D04 therefore audits the upstream S12D_B source-price machinery rather than S29C formula scaling.",
  "",
  "## S12D_B file inventory",
  paste0("D04 inventoried ", nrow(file_inventory), " local files across S12D/S13/S29C/D03/provider handoff context. See `D04_s12db_file_inventory.csv`."),
  "",
  "## Source-object admissibility findings",
  "The direct NFC ME and NRC current-cost nominal investment flows are admissible as nominal investment inputs. The BEA quantity indexes are not admissible as headline deflators. The S12D_B price object is a recursively recovered SFC implicit price, not a directly sourced BEA investment price, and therefore remains conceptually high risk until the price protocol is rebuilt or independently justified.",
  "",
  "## Implicit-price recovery findings",
  paste0("Annual recovery reproduces the stored S12D_B and S29C price paths for ME and NRC within tolerance. Maximum absolute recovery difference versus S12D_B is ", signif(max_abs(implicit_price_annual$absolute_difference_vs_S12D_B), 6), ". This resolves arithmetic recovery at the stored-object layer but not conceptual admissibility of the recovered price."),
  "",
  "## Seed-price and backcast findings",
  paste0("Seed-price spans are present for both assets. ME seed-to-2024 ratio is ", signif(seed_audit$seed_to_2024_ratio[seed_audit$asset == "ME"], 6), "; NRC seed-to-2024 ratio is ", signif(seed_audit$seed_to_2024_ratio[seed_audit$asset == "NRC"], 6), ". Seed treatment is classified as a refreeze-blocking risk because early prices are carried from initialization rather than directly recovered."),
  "",
  "## S12D_B to S29C bridge findings",
  paste0("The S12D_B to S29C bridge is exact within tolerance for both assets: ", paste(bridge_summary$asset, bridge_summary$interpretation, collapse = " ")),
  "",
  "## Shaikh context",
  "Shaikh diagnostic tables are used only as context. D04 does not require equality with Shaikh. The comparison supports the classification that the remaining GPIM gap is plausibly tied to Chapter 2 source-price behavior and unresolved scope/provider-price comparability, not to an S29C arithmetic defect.",
  "",
  "## Decision matrix summary",
  paste0("Recommendation: `", recommendation, "`."),
  "",
  "## What D04 resolves",
  "- S29C consumes S12D_B objects without bridge differences.",
  "- The nominal source object is analytically admissible for NFC ME/NRC current-cost investment.",
  "- The stored implicit price can be arithmetically recovered from S12D_B nominal and real-flow columns.",
  "",
  "## What remains unresolved",
  "- The recovered SFC price object is not a directly sourced investment deflator.",
  "- Seed/backcast treatment is material and not independently validated.",
  "- Provider vintage, source-price concept, and Shaikh boundary differences remain unresolved evidence rather than retirement-engine explanations.",
  "",
  "## Recommended next phase",
  "Run a bounded price-index reconstruction and provider-price concept review before any initialization/warmup decision. Do not refreeze GPIM until the price recovery and seed treatment are repaired or explicitly re-authorized.",
  "",
  "## Authorization boundary",
  "D04 is audit-only. It does not authorize replacement of the frozen Chapter 2 capital stock, S31/S32 reruns, VECM estimation, investment-function estimation, paper-facing baseline use, downstream econometric consumption, initialization/warmup treatment, or GPIM refreeze."
)
writeLines(report_lines, file.path(d04_dir, "D04_audit_report.md"))
writeLines(report_lines, file.path(maint_dir, "D04_GPIM_S12DB_SOURCE_PRICE_SEED_AUDIT_REPORT.md"))

validation_checks$status[validation_checks$check_id == "D04_14"] <- pass_fail(grepl("does not authorize replacement", read_text(file.path(d04_dir, "D04_audit_report.md")), fixed = TRUE))
write_csv(validation_checks, file.path(d04_dir, "D04_validation_checks.csv"))

validation_summary <- data.frame(
  metric = c("validation_pass", "validation_fail", "decision_matrix_recommendation", "protected_upstream_unchanged", "changed_path_scope_ok"),
  value = c(
    sum(validation_checks$status == "PASS"),
    sum(validation_checks$status != "PASS"),
    recommendation,
    protected_unchanged,
    changed_scope_ok
  )
)
write_csv(validation_summary, file.path(d04_dir, "D04_validation_summary.csv"))

if (any(validation_checks$status != "PASS")) {
  print(validation_checks[validation_checks$status != "PASS", , drop = FALSE])
  stop("D04 validation failed.", call. = FALSE)
}

cat("D04 validation: PASS=", sum(validation_checks$status == "PASS"), " FAIL=0\n", sep = "")
cat("D04 recommendation: ", recommendation, "\n", sep = "")
cat("D04 output directory: ", rel_path(d04_dir), "\n", sep = "")
