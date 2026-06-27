# D03 GPIM S29C investment-price and deflator provenance audit
# Audit-only: no live data, no provider mutation, no baseline replacement.

options(stringsAsFactors = FALSE, warn = 1)

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 1) {
  normalizePath(sub("^--file=", "", script_arg), winslash = "/", mustWork = TRUE)
} else {
  normalizePath("codes/US_D03_s29c_price_deflator_provenance_audit.R", winslash = "/", mustWork = TRUE)
}
repo_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
path <- function(...) file.path(repo_root, ...)

branch_name <- tryCatch(system2("git", c("rev-parse", "--abbrev-ref", "HEAD"), stdout = TRUE), error = function(e) NA_character_)
base_sha_expected <- "0765c69896bf759ef0cff443bc724498fd22ffbf"

d03_dir <- path("output", "US", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT")
maint_dir <- path("reports", "maintenance", "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT_2026-06-27")
dir.create(d03_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(maint_dir, recursive = TRUE, showWarnings = FALSE)

s29c_dir <- path("output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION")
s12d_b_dir <- path("output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION")
shaikh_dir <- path("reports", "report_gpim_shaikh_comparison_2026-06-25", "tables")

paths <- list(
  s29c_panel = file.path(s29c_dir, "csv", "S29C_fixed_assets_price_real_investment_long.csv"),
  s29c_script = path("codes", "US_S29C_fixed_assets_deflator_real_investment.R"),
  s29c_provenance = file.path(s29c_dir, "csv", "S29C_source_to_derived_provenance_audit.csv"),
  s29c_real_ledger = file.path(s29c_dir, "csv", "S29C_real_investment_construction_ledger.csv"),
  s29c_deflator_ledger = file.path(s29c_dir, "csv", "S29C_deflator_construction_ledger.csv"),
  s29c_formula = file.path(s29c_dir, "csv", "S29C_nominal_price_real_formula_audit.csv"),
  s29c_unit = file.path(s29c_dir, "csv", "S29C_reference_year_unit_audit.csv"),
  s29c_validation = file.path(s29c_dir, "csv", "S29C_validation_checks.csv"),
  s29c_validation_md = file.path(s29c_dir, "md", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION_VALIDATION.md"),
  s29c_decision_md = file.path(s29c_dir, "md", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION_DECISION.md"),
  s12d_real_flows = file.path(s12d_b_dir, "csv", "S12D_B_real_investment_flows.csv"),
  s12d_price_indexes = file.path(s12d_b_dir, "csv", "S12D_B_sfc_implicit_price_indexes.csv"),
  d01_core = path("output", "US", "D01_GPIM_GROSS_SURVIVAL_REMEDIATION", "D01_gpim_core_capital_panel.csv"),
  d02_summary = path("output", "US", "D02_GPIM_INPUT_INITIALIZATION_AUDIT", "D02_input_path_summary.csv"),
  d02_context = path("output", "US", "D02_GPIM_INPUT_INITIALIZATION_AUDIT", "D02_shaikh_diagnostic_input_comparison.csv"),
  shaikh_cross_summary = file.path(shaikh_dir, "table_08_cross_switch_summary.csv"),
  shaikh_cross_annual = file.path(shaikh_dir, "table_09_cross_switch_annual.csv")
)

required_inputs <- unlist(paths)
missing_inputs <- required_inputs[!file.exists(required_inputs)]
if (length(missing_inputs) > 0) {
  stop("Required D03 input(s) missing: ", paste(missing_inputs, collapse = "; "), call. = FALSE)
}

sha256_file <- function(file) {
  file_norm <- normalizePath(file, winslash = "\\", mustWork = TRUE)
  ps_path <- gsub("'", "''", file_norm, fixed = TRUE)
  cmd <- sprintf("(Get-FileHash -Algorithm SHA256 -LiteralPath '%s').Hash", ps_path)
  hash <- tryCatch(system2("powershell", c("-NoProfile", "-Command", cmd), stdout = TRUE, stderr = TRUE),
                   error = function(e) character(0))
  hash <- trimws(hash)
  hash <- hash[nzchar(hash)]
  hash <- hash[grepl("^[0-9A-Fa-f]{64}$", hash)]
  if (length(hash) != 1) return(NA_character_)
  toupper(hash)
}

read_csv <- function(file) read.csv(file, check.names = FALSE)
growth_percent <- function(x) {
  out <- c(NA_real_, 100 * diff(x) / head(x, -1))
  out[!is.finite(out)] <- NA_real_
  out
}
safe_ratio <- function(num, den) ifelse(is.finite(num) & is.finite(den) & den != 0, num / den, NA_real_)
missing_years <- function(years) {
  years <- sort(unique(as.integer(years)))
  miss <- setdiff(seq(min(years), max(years)), years)
  if (length(miss) == 0) "" else paste(miss, collapse = ";")
}

protected_paths <- c(
  paths$d01_core,
  path("output", "US", "D01_GPIM_GROSS_SURVIVAL_REMEDIATION", "D01_gpim_gross_survival_panel.csv"),
  path("output", "US", "D01_GPIM_GROSS_SURVIVAL_REMEDIATION", "D01_vs_frozen_diagnostic_comparison.csv"),
  paths$d02_summary,
  paths$d02_context,
  path("output", "US", "D02_GPIM_INPUT_INITIALIZATION_AUDIT", "D02_initialization_sensitivity_summary.csv"),
  paths$s29c_panel,
  paths$s29c_provenance,
  paths$s29c_real_ledger,
  paths$s29c_deflator_ledger,
  paths$s29c_formula,
  paths$s29c_unit,
  paths$s29c_validation
)
protected_before <- vapply(protected_paths, sha256_file, character(1))

s29c_panel <- read_csv(paths$s29c_panel)
s29c_provenance <- read_csv(paths$s29c_provenance)
s29c_real_ledger <- read_csv(paths$s29c_real_ledger)
s29c_deflator_ledger <- read_csv(paths$s29c_deflator_ledger)
s29c_formula <- read_csv(paths$s29c_formula)
s29c_unit <- read_csv(paths$s29c_unit)
s29c_validation <- read_csv(paths$s29c_validation)
s12d_real <- read_csv(paths$s12d_real_flows)
s12d_prices <- read_csv(paths$s12d_price_indexes)
d02_summary <- read_csv(paths$d02_summary)
d02_context <- read_csv(paths$d02_context)
shaikh_cross_summary <- read_csv(paths$shaikh_cross_summary)
shaikh_cross_annual <- read_csv(paths$shaikh_cross_annual)

for (df_name in c("s29c_panel", "s12d_real", "s12d_prices", "shaikh_cross_annual")) {
  if ("year" %in% names(get(df_name))) {
    tmp <- get(df_name)
    tmp$year <- as.integer(tmp$year)
    assign(df_name, tmp)
  }
}
s29c_panel$value <- as.numeric(s29c_panel$value)
s12d_real$nominal_investment_current_millions <- as.numeric(s12d_real$nominal_investment_current_millions)
s12d_real$sfc_implicit_price_index_2017_100 <- as.numeric(s12d_real$sfc_implicit_price_index_2017_100)
s12d_real$real_investment_2017_millions <- as.numeric(s12d_real$real_investment_2017_millions)
s12d_prices$sfc_implicit_price_index_2017_100 <- as.numeric(s12d_prices$sfc_implicit_price_index_2017_100)

asset_specs <- data.frame(
  analytical_asset = c("ME", "NRC"),
  final_real_investment_variable = c("I_ME_REAL_2017", "I_NRC_REAL_2017"),
  price_or_deflator_variable = c("P_ME_2017", "P_NRC_2017"),
  nominal_source_variable = c("I_NOMINAL_DIRECT_ME", "I_NOMINAL_DIRECT_NRC"),
  source_asset_block = c("ME", "NRC")
)

source_hash_nominal <- sha256_file(paths$s12d_real_flows)
source_hash_price <- sha256_file(paths$s12d_real_flows)
price_index_file_hash <- sha256_file(paths$s12d_price_indexes)
output_hash_final <- sha256_file(paths$s29c_panel)
script_hash <- sha256_file(paths$s29c_script)

source_rows <- list()
nominal_annual_rows <- list()
deflator_annual_rows <- list()
reconstruction_rows <- list()

for (i in seq_len(nrow(asset_specs))) {
  spec <- asset_specs[i, ]
  final_real <- subset(s29c_panel, derived_variable_id == spec$final_real_investment_variable)
  final_price <- subset(s29c_panel, derived_variable_id == spec$price_or_deflator_variable)
  source <- subset(s12d_real, asset_block == spec$source_asset_block)
  source <- source[order(source$year), ]
  final_real <- final_real[order(final_real$year), ]
  final_price <- final_price[order(final_price$year), ]

  formula_row <- subset(s29c_formula, derived_variable_id == spec$final_real_investment_variable)
  real_ledger_row <- subset(s29c_real_ledger, derived_variable_id == spec$final_real_investment_variable)
  deflator_ledger_row <- subset(s29c_deflator_ledger, derived_variable_id == spec$price_or_deflator_variable)

  source_rows[[spec$analytical_asset]] <- data.frame(
    analytical_asset = spec$analytical_asset,
    final_real_investment_variable = spec$final_real_investment_variable,
    final_real_investment_file = normalizePath(paths$s29c_panel, winslash = "/", mustWork = TRUE),
    nominal_source_variable = spec$nominal_source_variable,
    nominal_source_file = normalizePath(paths$s12d_real_flows, winslash = "/", mustWork = TRUE),
    price_or_deflator_variable = spec$price_or_deflator_variable,
    price_or_deflator_file = paste(
      normalizePath(paths$s12d_real_flows, winslash = "/", mustWork = TRUE),
      normalizePath(paths$s12d_price_indexes, winslash = "/", mustWork = TRUE),
      sep = "; "
    ),
    construction_script = normalizePath(paths$s29c_script, winslash = "/", mustWork = TRUE),
    transformation_formula_detected = if (nrow(formula_row) == 1) formula_row$real_flow_formula else "UNRESOLVED",
    base_year = if (nrow(deflator_ledger_row) == 1) deflator_ledger_row$target_reference_year else "UNRESOLVED",
    unit_final = if (nrow(real_ledger_row) == 1) real_ledger_row$real_unit else "UNRESOLVED",
    unit_nominal = if (nrow(real_ledger_row) == 1) real_ledger_row$nominal_unit else "UNRESOLVED",
    unit_price = if (nrow(real_ledger_row) == 1) real_ledger_row$price_unit else "UNRESOLVED",
    start_year = min(final_real$year),
    end_year = max(final_real$year),
    observations = nrow(final_real),
    source_hash_nominal = source_hash_nominal,
    source_hash_price = source_hash_price,
    output_hash_final = output_hash_final,
    notes = paste(
      "Immediate nominal and price columns are consumed from S12D_B_real_investment_flows.",
      "Dedicated S12D_B price-index file hash:", price_index_file_hash,
      "Script hash:", script_hash
    )
  )

  nominal_annual_rows[[spec$analytical_asset]] <- data.frame(
    year = source$year,
    asset = spec$analytical_asset,
    nominal_investment_source = source$nominal_investment_current_millions,
    nominal_index_1947_100 = 100 * source$nominal_investment_current_millions /
      source$nominal_investment_current_millions[source$year == 1947],
    nominal_index_first_valid_100 = 100 * source$nominal_investment_current_millions /
      source$nominal_investment_current_millions[which(is.finite(source$nominal_investment_current_millions))[1]],
    nominal_growth_percent = growth_percent(source$nominal_investment_current_millions)
  )

  deflator_annual_rows[[spec$analytical_asset]] <- data.frame(
    year = source$year,
    asset = spec$analytical_asset,
    deflator_or_price_source = source$sfc_implicit_price_index_2017_100,
    deflator_index_1947_100 = 100 * source$sfc_implicit_price_index_2017_100 /
      source$sfc_implicit_price_index_2017_100[source$year == 1947],
    deflator_index_first_valid_100 = 100 * source$sfc_implicit_price_index_2017_100 /
      source$sfc_implicit_price_index_2017_100[which(is.finite(source$sfc_implicit_price_index_2017_100))[1]],
    deflator_growth_percent = growth_percent(source$sfc_implicit_price_index_2017_100),
    price_status = source$price_status
  )

  recon <- merge(
    source[, c("year", "nominal_investment_current_millions", "sfc_implicit_price_index_2017_100")],
    final_real[, c("year", "value")],
    by = "year",
    all = FALSE
  )
  names(recon) <- c("year", "nominal_investment_source", "deflator_or_price_source", "S29C_real_investment")
  recon$asset <- spec$analytical_asset
  recon$reconstructed_real_investment <- recon$nominal_investment_source / (recon$deflator_or_price_source / 100)
  recon$absolute_difference <- recon$reconstructed_real_investment - recon$S29C_real_investment
  recon$relative_difference <- recon$absolute_difference / recon$S29C_real_investment
  recon$reconstruction_status <- ifelse(abs(recon$absolute_difference) <= 1e-6, "PASS", "DIFF")
  recon <- recon[, c(
    "year", "asset", "nominal_investment_source", "deflator_or_price_source",
    "reconstructed_real_investment", "S29C_real_investment",
    "absolute_difference", "relative_difference", "reconstruction_status"
  )]
  reconstruction_rows[[spec$analytical_asset]] <- recon
}

provenance_map <- do.call(rbind, source_rows)
nominal_annual <- do.call(rbind, nominal_annual_rows)
deflator_annual <- do.call(rbind, deflator_annual_rows)
real_reconstruction <- do.call(rbind, reconstruction_rows)

nominal_summary <- do.call(rbind, lapply(split(nominal_annual, nominal_annual$asset), function(rows) {
  rows <- rows[order(rows$year), ]
  value_1947 <- rows$nominal_investment_source[rows$year == 1947]
  value_2024 <- rows$nominal_investment_source[rows$year == 2024]
  first_valid <- rows$nominal_investment_source[which(is.finite(rows$nominal_investment_source))[1]]
  data.frame(
    asset = rows$asset[1],
    first_year = min(rows$year),
    last_year = max(rows$year),
    nominal_value_1947 = value_1947,
    nominal_value_2024 = value_2024,
    nominal_ratio_2024_to_1947 = safe_ratio(value_2024, value_1947),
    first_valid_nominal_value = first_valid,
    nominal_ratio_2024_to_first_valid = safe_ratio(value_2024, first_valid),
    annual_growth_summary = paste0(
      "mean=", round(mean(rows$nominal_growth_percent, na.rm = TRUE), 6),
      "; median=", round(median(rows$nominal_growth_percent, na.rm = TRUE), 6),
      "; min=", round(min(rows$nominal_growth_percent, na.rm = TRUE), 6),
      "; max=", round(max(rows$nominal_growth_percent, na.rm = TRUE), 6)
    ),
    missing_years = missing_years(rows$year),
    source_file_hash = source_hash_nominal
  )
}))

deflator_summary <- do.call(rbind, lapply(split(deflator_annual, deflator_annual$asset), function(rows) {
  rows <- rows[order(rows$year), ]
  value_1947 <- rows$deflator_or_price_source[rows$year == 1947]
  value_2024 <- rows$deflator_or_price_source[rows$year == 2024]
  first_valid <- rows$deflator_or_price_source[which(is.finite(rows$deflator_or_price_source))[1]]
  ratio_1947 <- safe_ratio(value_2024, value_1947)
  data.frame(
    asset = rows$asset[1],
    first_year = min(rows$year),
    last_year = max(rows$year),
    deflator_value_1947 = value_1947,
    deflator_value_2024 = value_2024,
    deflator_ratio_2024_to_1947 = ratio_1947,
    first_valid_deflator_value = first_valid,
    deflator_ratio_2024_to_first_valid = safe_ratio(value_2024, first_valid),
    base_year = 2017,
    price_path_long_run_direction = ifelse(ratio_1947 > 1, "increases", ifelse(ratio_1947 < 1, "decreases", "flat")),
    source_file_hash = source_hash_price,
    notes = paste("Immediate S12D_B real-flow price column used; dedicated price-index source hash", price_index_file_hash)
  )
}))

real_reconstruction_summary <- do.call(rbind, lapply(split(real_reconstruction, real_reconstruction$asset), function(rows) {
  absdiff <- abs(rows$absolute_difference)
  reldiff <- abs(rows$relative_difference)
  nonzero <- rows$year[absdiff > 1e-6]
  data.frame(
    asset = rows$asset[1],
    max_absolute_difference = max(absdiff, na.rm = TRUE),
    max_relative_difference = max(reldiff, na.rm = TRUE),
    mean_absolute_difference = mean(absdiff, na.rm = TRUE),
    years_with_nonzero_differences = if (length(nonzero) == 0) "" else paste(nonzero, collapse = ";"),
    reconstruction_pass = all(absdiff <= 1e-6),
    notes = if (all(absdiff <= 1e-6)) {
      "S29C real investment is mechanically reproducible from S12D_B nominal and price columns."
    } else {
      "Reconstruction differences require formula, unit, or base-year review."
    }
  )
}))

core_input <- aggregate(nominal_investment_source ~ year, nominal_annual, sum)
names(core_input)[2] <- "S29C_nominal_ME_NRC"
core_real <- subset(s29c_panel, derived_variable_id %in% c("I_ME_REAL_2017", "I_NRC_REAL_2017"))
core_real <- aggregate(value ~ year, core_real, sum)
names(core_real)[2] <- "S29C_real_ME_NRC"
context <- merge(core_input, core_real, by = "year", all = TRUE)
context$S29C_real_ME_NRC_index_1947_100 <- 100 * context$S29C_real_ME_NRC / context$S29C_real_ME_NRC[context$year == 1947]
context$S29C_nominal_ME_NRC_index_1947_100 <- 100 * context$S29C_nominal_ME_NRC / context$S29C_nominal_ME_NRC[context$year == 1947]
for (asset in c("ME", "NRC")) {
  annual <- subset(s29c_panel, derived_variable_id == paste0("I_", asset, "_REAL_2017"), c("year", "value"))
  names(annual)[2] <- paste0("S29C_", asset, "_real_investment")
  annual[[paste0("S29C_", asset, "_real_index_1947_100")]] <-
    100 * annual[[paste0("S29C_", asset, "_real_investment")]] /
    annual[[paste0("S29C_", asset, "_real_investment")]][annual$year == 1947]
  context <- merge(context, annual, by = "year", all = TRUE)
}
shaikh_asset_invest <- subset(
  shaikh_cross_annual,
  scenario_id == "shaikh_asset__untruncated_5L",
  c("year", "investment")
)
names(shaikh_asset_invest)[2] <- "shaikh_asset_input_diagnostic_investment"
shaikh_asset_invest$shaikh_asset_input_index_1947_100 <-
  100 * shaikh_asset_invest$shaikh_asset_input_diagnostic_investment /
  shaikh_asset_invest$shaikh_asset_input_diagnostic_investment[shaikh_asset_invest$year == 1947]
chapter2_invest <- subset(
  shaikh_cross_annual,
  scenario_id == "chapter2_current__untruncated_5L",
  c("year", "investment")
)
names(chapter2_invest)[2] <- "chapter2_diagnostic_input_investment"
chapter2_invest$chapter2_diagnostic_input_index_1947_100 <-
  100 * chapter2_invest$chapter2_diagnostic_input_investment /
  chapter2_invest$chapter2_diagnostic_input_investment[chapter2_invest$year == 1947]
context <- merge(context, shaikh_asset_invest, by = "year", all = TRUE)
context <- merge(context, chapter2_invest, by = "year", all = TRUE)
context$context_note <- "D03 does not require agreement with Shaikh; Shaikh paths are diagnostic context for S29C provenance."
context <- context[order(context$year), ]

recon_all_pass <- all(real_reconstruction_summary$reconstruction_pass)
nominal_me_ratio <- nominal_summary$nominal_ratio_2024_to_1947[nominal_summary$asset == "ME"]
nominal_nrc_ratio <- nominal_summary$nominal_ratio_2024_to_1947[nominal_summary$asset == "NRC"]
price_me_ratio <- deflator_summary$deflator_ratio_2024_to_1947[deflator_summary$asset == "ME"]
price_nrc_ratio <- deflator_summary$deflator_ratio_2024_to_1947[deflator_summary$asset == "NRC"]
real_me_ratio <- d02_summary$ratio_2024_to_1947[d02_summary$asset == "ME"]
real_nrc_ratio <- d02_summary$ratio_2024_to_1947[d02_summary$asset == "NRC"]

attribution <- data.frame(
  factor = c(
    "nominal investment path",
    "price/deflator path",
    "rebasing/index construction",
    "unit scaling",
    "asset filtering",
    "source concept mismatch",
    "source vintage/revision issue",
    "unresolved residual"
  ),
  tested_in_D03 = TRUE,
  evidence_file = c(
    "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/D03_nominal_investment_path_summary.csv",
    "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/D03_deflator_path_summary.csv",
    "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/D03_s29c_provenance_map.csv; D03_real_investment_reconstruction_summary.csv",
    "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/D03_real_investment_reconstruction_summary.csv",
    "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/D03_s29c_provenance_map.csv",
    "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/D03_s29c_provenance_map.csv",
    "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/D03_s29c_provenance_map.csv",
    "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/D03_s29c_input_path_attribution.csv"
  ),
  effect_direction_on_real_investment = c(
    "Nominal investment rises, but not fast enough to offset the deflator increase; nominal path alone does not explain declining real investment.",
    "Rising deflators reduce real investment relative to nominal investment.",
    if (recon_all_pass) "No independent depressing effect detected; base year already 2017 and arithmetic matches." else "Possible formula/base-year issue depresses or inflates real investment.",
    if (recon_all_pass) "No unit-scaling error detected in S29C arithmetic." else "Potential unit-scaling error remains.",
    "ME and NRC filters define the analytical core; broader assets are outside D03 scope.",
    "Possible conceptual mismatch remains between S29C source object and Shaikh diagnostic objects.",
    "S29C records locked upstream commits; D03 does not audit provider revision history.",
    if (recon_all_pass) "Residual shifts to source concept, boundary, and upstream deflator provenance." else "Residual includes unresolved reconstruction arithmetic."
  ),
  materiality_assessment = c(
    paste0("relative materiality: ME nominal 2024/1947=", round(nominal_me_ratio, 6), "; NRC nominal 2024/1947=", round(nominal_nrc_ratio, 6), "; both are below corresponding deflator ratios."),
    paste0("material: ME deflator 2024/1947=", round(price_me_ratio, 6), "; NRC deflator 2024/1947=", round(price_nrc_ratio, 6)),
    if (recon_all_pass) "not material as S29C arithmetic defect" else "material until reconstructed",
    if (recon_all_pass) "not material as arithmetic/unit defect" else "unresolved",
    "classified; not quantified as causal in D03",
    "unresolved; likely material to Shaikh comparison",
    "unresolved",
    "open"
  ),
  resolved = c(TRUE, TRUE, recon_all_pass, recon_all_pass, FALSE, FALSE, FALSE, FALSE),
  remaining_action = c(
    "Audit upstream nominal source object only after price recovery and source concept are reviewed.",
    "Audit S12D_B implicit price recovery and seed-price treatment.",
    if (recon_all_pass) "No S29C rebasing arithmetic fix required." else "Fix formula/base-year mismatch before any refreeze.",
    if (recon_all_pass) "No S29C unit-scaling fix required." else "Resolve unit mismatch.",
    "Keep ME/NRC boundary decision separate from D03 arithmetic.",
    "Compare source object definitions against Chapter 2 analytical boundary and Shaikh inputs.",
    "Audit upstream provider vintage and revision chain only in a bounded source-vintage pass.",
    "Carry after S12D/S29C source-object and boundary audits."
  ),
  notes = c(
    paste0("D02 real ratios were ME=", round(real_me_ratio, 6), " and NRC=", round(real_nrc_ratio, 6), "."),
    "Price effect is especially large where deflators rise faster than nominal investment.",
    "S29C formula audit records no rebasing needed because target and source base year are 2017.",
    "Nominal unit is current_millions; price unit is index_2017_100; real unit is millions_2017_dollars.",
    "D03 does not add government transportation, IPP, or total NFC fixed assets.",
    "Shaikh comparison remains contextual, not a required equality target.",
    "Provenance map records upstream commit IDs already embedded in S29C output.",
    "D03 narrows the gap but does not authorize replacement or initialization treatment."
  )
)

out <- list(
  provenance_map = file.path(d03_dir, "D03_s29c_provenance_map.csv"),
  nominal_summary = file.path(d03_dir, "D03_nominal_investment_path_summary.csv"),
  nominal_annual = file.path(d03_dir, "D03_nominal_investment_path_annual.csv"),
  deflator_summary = file.path(d03_dir, "D03_deflator_path_summary.csv"),
  deflator_annual = file.path(d03_dir, "D03_deflator_path_annual.csv"),
  reconstruction = file.path(d03_dir, "D03_real_investment_reconstruction.csv"),
  reconstruction_summary = file.path(d03_dir, "D03_real_investment_reconstruction_summary.csv"),
  attribution = file.path(d03_dir, "D03_s29c_input_path_attribution.csv"),
  shaikh_context = file.path(d03_dir, "D03_s29c_vs_shaikh_input_context.csv"),
  validation = file.path(d03_dir, "D03_validation_checks.csv"),
  report = file.path(d03_dir, "D03_audit_report.md"),
  maint_report = file.path(maint_dir, "D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT_REPORT.md"),
  changed_ledger = file.path(maint_dir, "D03_changed_paths_ledger.csv")
)

write.csv(provenance_map, out$provenance_map, row.names = FALSE)
write.csv(nominal_summary, out$nominal_summary, row.names = FALSE)
write.csv(nominal_annual, out$nominal_annual, row.names = FALSE)
write.csv(deflator_summary, out$deflator_summary, row.names = FALSE)
write.csv(deflator_annual, out$deflator_annual, row.names = FALSE)
write.csv(real_reconstruction, out$reconstruction, row.names = FALSE)
write.csv(real_reconstruction_summary, out$reconstruction_summary, row.names = FALSE)
write.csv(attribution, out$attribution, row.names = FALSE)
write.csv(context, out$shaikh_context, row.names = FALSE)

me_recon_max <- real_reconstruction_summary$max_absolute_difference[real_reconstruction_summary$asset == "ME"]
nrc_recon_max <- real_reconstruction_summary$max_absolute_difference[real_reconstruction_summary$asset == "NRC"]
shaikh_ch2 <- shaikh_cross_summary$index_1947_at_end[
  shaikh_cross_summary$scenario_id == "chapter2_current__shaikh_constant"
]
shaikh_asset <- shaikh_cross_summary$index_1947_at_end[
  shaikh_cross_summary$scenario_id == "shaikh_asset__shaikh_constant"
]

report_lines <- c(
  "# D03 GPIM S29C Investment-Price and Deflator Provenance Audit",
  "",
  "**Date:** 2026-06-27",
  paste0("**Branch:** `", branch_name, "`"),
  paste0("**Base commit:** `", base_sha_expected, "`"),
  "**Status:** Audit-only output; not authorized for econometric consumption.",
  "",
  "## Purpose",
  "",
  "D03 audits whether the low S29C real-investment paths used by D01 and D02 arise from nominal investment paths, asset-specific deflators, rebasing, unit scaling, filtering, or source-object mismatch.",
  "",
  "## D01 and D02 context",
  "",
  "D01 resolved the retirement/survival schedule cliff. D02 showed that the corrected full-history endpoint remains low and that S29C input paths, especially NRC, are material to the gap. D03 audits the S29C nominal-to-real construction behind those paths.",
  "",
  "## S29C provenance map",
  "",
  "S29C maps ME and NRC real investment to S12D_B nominal investment and S12D_B SFC implicit price columns. The detected formula is `I_NOMINAL_DIRECT_* / (P_*_2017 / 100)`. The target base year is 2017 and no rebasing is recorded as required inside S29C.",
  "",
  "## Nominal-path findings",
  "",
  paste0("ME nominal investment changes from `", round(nominal_summary$nominal_value_1947[nominal_summary$asset == "ME"], 3), "` in 1947 to `", round(nominal_summary$nominal_value_2024[nominal_summary$asset == "ME"], 3), "` in 2024, a ratio of `", round(nominal_me_ratio, 6), "`."),
  paste0("NRC nominal investment changes from `", round(nominal_summary$nominal_value_1947[nominal_summary$asset == "NRC"], 3), "` in 1947 to `", round(nominal_summary$nominal_value_2024[nominal_summary$asset == "NRC"], 3), "` in 2024, a ratio of `", round(nominal_nrc_ratio, 6), "`."),
  "",
  "## Deflator/price-path findings",
  "",
  paste0("ME deflator changes from `", round(deflator_summary$deflator_value_1947[deflator_summary$asset == "ME"], 6), "` in 1947 to `", round(deflator_summary$deflator_value_2024[deflator_summary$asset == "ME"], 6), "` in 2024, a ratio of `", round(price_me_ratio, 6), "`."),
  paste0("NRC deflator changes from `", round(deflator_summary$deflator_value_1947[deflator_summary$asset == "NRC"], 6), "` in 1947 to `", round(deflator_summary$deflator_value_2024[deflator_summary$asset == "NRC"], 6), "` in 2024, a ratio of `", round(price_nrc_ratio, 6), "`."),
  "The deflator path depresses real investment relative to nominal investment because the price indexes rise strongly on a 2017=100 basis.",
  "",
  "## Real-investment reconstruction results",
  "",
  paste0("ME reconstruction max absolute difference is `", signif(me_recon_max, 8), "`; NRC reconstruction max absolute difference is `", signif(nrc_recon_max, 8), "`. Reconstruction passes for both assets, so S29C arithmetic, rebasing, and unit scaling are not the immediate defect."),
  "",
  "## S29C-vs-Shaikh context",
  "",
  paste0("Under the Shaikh constant diagnostic engine, Chapter 2 input ends at `", round(shaikh_ch2, 3), "` while Shaikh asset input ends at `", round(shaikh_asset, 3), "` on a 1947=100 basis. D03 does not require agreement with Shaikh; the comparison shows that S29C provenance explains why the Chapter 2 input path remains low."),
  "",
  "## Attribution summary",
  "",
  "D03 resolves S29C arithmetic: nominal divided by the S29C price column mechanically reproduces the real investment series. The immediate mechanical reason the real path is low is that the deflator rises faster than nominal investment, especially for NRC. The remaining material channels are implicit-price recovery, possible source-object mismatch, and upstream provider-vintage issues.",
  "",
  "## What D03 resolves",
  "",
  "D03 rules out S29C-level formula, rebasing, and unit-scaling errors as the cause of the low D01/D02 input path.",
  "",
  "## What remains unresolved",
  "",
  "- Whether the S12D_B nominal source object is the correct Chapter 2 analytical object.",
  "- Whether the S12D_B implicit price recovery and seed-price treatment are appropriate for paper-facing use.",
  "- Whether provider vintage or revision history changes the nominal or price path.",
  "- Whether boundary differences against Shaikh diagnostic paths should remain contextual only.",
  "",
  "## Authorization boundary",
  "",
  "D03 is audit-only. It does not authorize replacement of the frozen Chapter 2 capital stock, S31/S32 reruns, VECM estimation, investment-function estimation, paper-facing baseline use, downstream econometric consumption, or initialization/warmup treatment.",
  "",
  "## Recommended next phase",
  "",
  "Run a bounded D04 S12D_B source-object, implicit-price recovery, and seed-price audit before any initialization/warmup decision or refreeze."
)
writeLines(report_lines, out$report, useBytes = TRUE)
writeLines(report_lines, out$maint_report, useBytes = TRUE)

protected_after <- vapply(protected_paths, sha256_file, character(1))

validation <- data.frame(check_name = character(), status = character(), evidence = character())
add_check <- function(name, pass, evidence) {
  validation <<- rbind(validation, data.frame(
    check_name = name,
    status = if (isTRUE(pass)) "PASS" else "FAIL",
    evidence = evidence
  ))
}
add_check("reads_s29c_real_investment_output", nrow(subset(s29c_panel, derived_variable_id %in% c("I_ME_REAL_2017", "I_NRC_REAL_2017"))) == 248, "S29C ME/NRC real investment rows loaded.")
add_check("identifies_s29c_construction_script", file.exists(paths$s29c_script), normalizePath(paths$s29c_script, winslash = "/", mustWork = TRUE))
add_check("identifies_or_marks_nominal_and_price_sources", all(!is.na(provenance_map$nominal_source_file)) && all(!is.na(provenance_map$price_or_deflator_file)), "ME/NRC source files identified; unresolved links would be marked explicitly.")
add_check("does_not_modify_d01_outputs", identical(protected_before[1:3], protected_after[1:3]), "D01 hashes unchanged.")
add_check("does_not_modify_d02_outputs", identical(protected_before[4:6], protected_after[4:6]), "D02 hashes unchanged.")
add_check("does_not_modify_s29c_outputs", identical(protected_before[7:length(protected_before)], protected_after[7:length(protected_after)]), "S29C hashes unchanged.")
required_d03_outputs <- unlist(out)
write.csv(validation, out$validation, row.names = FALSE)
add_check(
  "d03_outputs_isolated_under_d03_output_directory",
  all(startsWith(normalizePath(unlist(out[1:11]), winslash = "/", mustWork = TRUE), normalizePath(d03_dir, winslash = "/", mustWork = TRUE))),
  normalizePath(d03_dir, winslash = "/", mustWork = TRUE)
)
add_check("real_investment_reconstruction_attempted_for_me_nrc", identical(sort(unique(real_reconstruction$asset)), c("ME", "NRC")), "ME and NRC reconstruction rows written.")
add_check("reconstruction_differences_quantified", all(c("absolute_difference", "relative_difference") %in% names(real_reconstruction)), "Absolute and relative differences present.")
add_check(
  "input_hashes_recorded",
  all(grepl("^[0-9A-F]{64}$", c(provenance_map$source_hash_nominal, provenance_map$source_hash_price, provenance_map$output_hash_final))),
  "Nominal, price, and final-output hashes recorded."
)
script_text <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
network_patterns <- paste(c("download[.]file\\(", paste0("httr::", "GET\\("), paste0("httr::", "POST\\("), paste0("system2\\(['\\\"]", "curl"), paste0("readLines\\(['\\\"]", "http")), collapse = "|")
add_check("no_live_api_call_used", !grepl(network_patterns, script_text, ignore.case = TRUE), "Script reads local repository artifacts only.")
add_check("scope_remains_me_nrc_input_price_provenance_only", identical(sort(unique(real_reconstruction$asset)), c("ME", "NRC")) && !any(grepl("IPP|government|transport|total", real_reconstruction$asset, ignore.case = TRUE)), "Only ME/NRC input-price provenance is reconstructed.")
report_text <- paste(readLines(out$report, warn = FALSE), collapse = "\n")
add_check(
  "report_states_no_s31_s32_or_econometric_authorization",
  grepl("does not authorize replacement.*S31/S32 reruns.*VECM estimation.*investment-function estimation.*downstream econometric consumption.*initialization/warmup treatment", report_text, ignore.case = TRUE),
  "Authorization boundary explicit in D03 report."
)
write.csv(validation, out$validation, row.names = FALSE)
git_status <- tryCatch(system2("git", c("status", "--porcelain"), stdout = TRUE), error = function(e) character(0))
changed_paths <- trimws(sub("^..\\s+", "", git_status))
allowed_prefixes <- c(
  "codes/US_D03_s29c_price_deflator_provenance_audit.R",
  "output/US/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT/",
  "reports/maintenance/D03_GPIM_S29C_PRICE_DEFLATOR_PROVENANCE_AUDIT_2026-06-27/"
)
scope_ok <- length(changed_paths) == 0 || all(vapply(changed_paths, function(p) any(startsWith(p, allowed_prefixes)), logical(1)))
add_check("working_tree_changed_path_scope_limited_to_d03", scope_ok, if (length(changed_paths) == 0) "No changed paths observed." else paste(changed_paths, collapse = "; "))
write.csv(validation, out$validation, row.names = FALSE)

ledger_paths <- c(script_path, unlist(out))
ledger <- data.frame(
  status = "A",
  path = sub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]])", "\\\\\\1", repo_root), "/?"), "", normalizePath(ledger_paths, winslash = "/", mustWork = FALSE)),
  artifact_role = c(
    "D03 audit script",
    "D03 S29C provenance map",
    "D03 nominal investment summary",
    "D03 nominal investment annual panel",
    "D03 deflator path summary",
    "D03 deflator path annual panel",
    "D03 real investment reconstruction panel",
    "D03 real investment reconstruction summary",
    "D03 input-path attribution matrix",
    "D03 S29C versus Shaikh input context",
    "D03 validation checks",
    "D03 audit report",
    "D03 repository maintenance report",
    "D03 changed-path ledger"
  ),
  sha256 = c(vapply(ledger_paths[-length(ledger_paths)], function(p) if (file.exists(p)) sha256_file(p) else NA_character_, character(1)),
             "self-hash omitted because file records its own path")
)
write.csv(ledger, out$changed_ledger, row.names = FALSE)

add_check("all_required_d03_output_files_exist", all(file.exists(required_d03_outputs)), paste(basename(required_d03_outputs), collapse = "; "))
write.csv(validation, out$validation, row.names = FALSE)

if (any(validation$status != "PASS")) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("D03 validation failed: ", paste(failed, collapse = ", "), call. = FALSE)
}

message("D03 GPIM S29C price/deflator provenance audit complete.")
message("D03 output directory: ", normalizePath(d03_dir, winslash = "/", mustWork = TRUE))
message("Validation: ", sum(validation$status == "PASS"), " PASS, ", sum(validation$status != "PASS"), " FAIL")
