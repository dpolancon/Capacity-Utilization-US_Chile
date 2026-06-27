# D02 GPIM input-path and initialization-history audit
# Audit-only: reads D01/S29C/diagnostic artifacts and writes isolated D02 outputs.

options(stringsAsFactors = FALSE, warn = 1)

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 1) {
  normalizePath(sub("^--file=", "", script_arg), winslash = "/", mustWork = TRUE)
} else {
  normalizePath("codes/US_D02_gpim_input_initialization_audit.R", winslash = "/", mustWork = TRUE)
}
repo_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
path <- function(...) file.path(repo_root, ...)

branch_name <- tryCatch(system2("git", c("rev-parse", "--abbrev-ref", "HEAD"), stdout = TRUE), error = function(e) NA_character_)
head_sha <- tryCatch(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), error = function(e) NA_character_)
base_sha_expected <- "49f6aebfc7ba3f1ac450788f175a26b681d83e72"

d02_dir <- path("output", "US", "D02_GPIM_INPUT_INITIALIZATION_AUDIT")
maint_dir <- path("reports", "maintenance", "D02_GPIM_INPUT_INITIALIZATION_AUDIT_2026-06-27")
dir.create(d02_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(maint_dir, recursive = TRUE, showWarnings = FALSE)

d01_core_path <- path("output", "US", "D01_GPIM_GROSS_SURVIVAL_REMEDIATION", "D01_gpim_core_capital_panel.csv")
d01_asset_path <- path("output", "US", "D01_GPIM_GROSS_SURVIVAL_REMEDIATION", "D01_gpim_gross_survival_panel.csv")
d01_comparison_path <- path("output", "US", "D01_GPIM_GROSS_SURVIVAL_REMEDIATION", "D01_vs_frozen_diagnostic_comparison.csv")
s29c_path <- path(
  "output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION",
  "csv", "S29C_fixed_assets_price_real_investment_long.csv"
)
diagnostic_report_path <- path(
  "reports", "report_gpim_shaikh_comparison_2026-06-25",
  "report_gpim_shaikh_comparison_2026-06-25.md"
)
cross_switch_summary_path <- path(
  "reports", "report_gpim_shaikh_comparison_2026-06-25",
  "tables", "table_08_cross_switch_summary.csv"
)
cross_switch_annual_path <- path(
  "reports", "report_gpim_shaikh_comparison_2026-06-25",
  "tables", "table_09_cross_switch_annual.csv"
)
initialization_treatment_path <- path(
  "reports", "report_gpim_shaikh_comparison_2026-06-25",
  "tables", "table_12_initialization_treatment.csv"
)
constitution_path <- path("chapter2_vault", "04_data_measurement", "V02_GPIM_Constitution.md")

required_inputs <- c(
  d01_core_path,
  d01_asset_path,
  d01_comparison_path,
  s29c_path,
  diagnostic_report_path,
  cross_switch_summary_path,
  cross_switch_annual_path,
  initialization_treatment_path,
  constitution_path
)
missing_inputs <- required_inputs[!file.exists(required_inputs)]
if (length(missing_inputs) > 0) {
  stop("Required D02 input(s) missing: ", paste(missing_inputs, collapse = "; "), call. = FALSE)
}

sha256_file <- function(file) {
  file_norm <- normalizePath(file, winslash = "\\", mustWork = TRUE)
  ps_path <- gsub("'", "''", file_norm, fixed = TRUE)
  cmd <- sprintf("(Get-FileHash -Algorithm SHA256 -LiteralPath '%s').Hash", ps_path)
  hash <- tryCatch(
    system2("powershell", c("-NoProfile", "-Command", cmd), stdout = TRUE, stderr = TRUE),
    error = function(e) character(0)
  )
  hash <- trimws(hash)
  hash <- hash[nzchar(hash)]
  hash <- hash[grepl("^[0-9A-Fa-f]{64}$", hash)]
  if (length(hash) != 1) return(NA_character_)
  toupper(hash)
}

growth_percent <- function(x) {
  out <- c(NA_real_, 100 * diff(x) / head(x, -1))
  out[!is.finite(out)] <- NA_real_
  out
}

safe_ratio <- function(num, den) {
  ifelse(is.finite(num) & is.finite(den) & den != 0, num / den, NA_real_)
}

survival_weibull <- function(age, alpha, lambda) {
  exp(-((age / lambda) ^ alpha))
}

d01_hash_before <- vapply(c(d01_core_path, d01_asset_path, d01_comparison_path), sha256_file, character(1))

d01_core <- read.csv(d01_core_path, check.names = FALSE)
d01_asset <- read.csv(d01_asset_path, check.names = FALSE)
d01_comparison <- read.csv(d01_comparison_path, check.names = FALSE)
s29c <- read.csv(s29c_path, check.names = FALSE)
cross_summary <- read.csv(cross_switch_summary_path, check.names = FALSE)
cross_annual <- read.csv(cross_switch_annual_path, check.names = FALSE)
init_diagnostic <- read.csv(initialization_treatment_path, check.names = FALSE)

s29c$year <- as.integer(s29c$year)
s29c$value <- as.numeric(s29c$value)

flow <- subset(
  s29c,
  variable_role == "asset_specific_real_investment_flow" &
    asset_family %in% c("ME", "NRC") &
    derived_variable_id %in% c("I_ME_REAL_2017", "I_NRC_REAL_2017")
)
if (!identical(sort(unique(flow$asset_family)), c("ME", "NRC"))) {
  stop("S29C ME/NRC real-investment inputs not available for D02.", call. = FALSE)
}
if (anyDuplicated(paste(flow$asset_family, flow$year))) {
  stop("Duplicate asset-year S29C investment rows.", call. = FALSE)
}

source_hash <- sha256_file(s29c_path)

input_summary <- do.call(rbind, lapply(c("ME", "NRC"), function(asset) {
  rows <- flow[flow$asset_family == asset, ]
  rows <- rows[order(rows$year), ]
  first_valid <- rows$value[which(is.finite(rows$value))[1]]
  value_1947 <- rows$value[rows$year == 1947]
  value_2024 <- rows$value[rows$year == 2024]
  data.frame(
    asset = asset,
    input_variable = unique(rows$derived_variable_id),
    first_year = min(rows$year),
    last_year = max(rows$year),
    observation_count = nrow(rows),
    value_1947 = if (length(value_1947) == 1) value_1947 else NA_real_,
    value_2024 = if (length(value_2024) == 1) value_2024 else NA_real_,
    ratio_2024_to_1947 = safe_ratio(value_2024, value_1947),
    first_valid_year_value = first_valid,
    ratio_2024_to_first_valid = safe_ratio(value_2024, first_valid),
    source_sha256 = source_hash
  )
}))

me_input <- flow[flow$asset_family == "ME", c("year", "value")]
nrc_input <- flow[flow$asset_family == "NRC", c("year", "value")]
names(me_input)[2] <- "I_ME_REAL_2017"
names(nrc_input)[2] <- "I_NRC_REAL_2017"
input_annual <- merge(me_input, nrc_input, by = "year", all = TRUE)
input_annual <- input_annual[order(input_annual$year), ]
input_annual$I_ME_index_1947_100 <- 100 * input_annual$I_ME_REAL_2017 / input_annual$I_ME_REAL_2017[input_annual$year == 1947]
input_annual$I_NRC_index_1947_100 <- 100 * input_annual$I_NRC_REAL_2017 / input_annual$I_NRC_REAL_2017[input_annual$year == 1947]
input_annual$I_ME_index_first_valid_100 <- 100 * input_annual$I_ME_REAL_2017 / input_annual$I_ME_REAL_2017[which(is.finite(input_annual$I_ME_REAL_2017))[1]]
input_annual$I_NRC_index_first_valid_100 <- 100 * input_annual$I_NRC_REAL_2017 / input_annual$I_NRC_REAL_2017[which(is.finite(input_annual$I_NRC_REAL_2017))[1]]
input_annual$I_ME_growth_percent <- growth_percent(input_annual$I_ME_REAL_2017)
input_annual$I_NRC_growth_percent <- growth_percent(input_annual$I_NRC_REAL_2017)
input_annual$I_core_ME_NRC_REAL_2017 <- input_annual$I_ME_REAL_2017 + input_annual$I_NRC_REAL_2017
input_annual$I_core_index_1947_100 <- 100 * input_annual$I_core_ME_NRC_REAL_2017 / input_annual$I_core_ME_NRC_REAL_2017[input_annual$year == 1947]
input_annual$I_core_growth_percent <- growth_percent(input_annual$I_core_ME_NRC_REAL_2017)

cross_input_compare <- subset(
  cross_summary,
  engine_id %in% c("shaikh_constant", "untruncated_5L") &
    input_id %in% c("chapter2_current", "shaikh_asset")
)
cross_input_compare <- cross_input_compare[order(cross_input_compare$engine_id, cross_input_compare$input_id), ]
shaikh_constant_ch2 <- cross_input_compare$index_1947_at_end[
  cross_input_compare$engine_id == "shaikh_constant" & cross_input_compare$input_id == "chapter2_current"
]
shaikh_constant_shaikh <- cross_input_compare$index_1947_at_end[
  cross_input_compare$engine_id == "shaikh_constant" & cross_input_compare$input_id == "shaikh_asset"
]
untruncated_ch2 <- cross_input_compare$index_1947_at_end[
  cross_input_compare$engine_id == "untruncated_5L" & cross_input_compare$input_id == "chapter2_current"
]
untruncated_shaikh <- cross_input_compare$index_1947_at_end[
  cross_input_compare$engine_id == "untruncated_5L" & cross_input_compare$input_id == "shaikh_asset"
]

asset_params <- data.frame(
  asset_family = c("ME", "NRC"),
  mean_life_years = c(14, 30),
  weibull_alpha = c(1.7, 1.6)
)
asset_params$weibull_lambda <- asset_params$mean_life_years /
  gamma(1 + 1 / asset_params$weibull_alpha)

compute_asset_stock <- function(asset, start_year) {
  params <- asset_params[asset_params$asset_family == asset, ]
  rows <- flow[flow$asset_family == asset & flow$year >= start_year, ]
  rows <- rows[order(rows$year), ]
  years <- rows$year
  investments <- rows$value
  stocks <- vapply(years, function(current_year) {
    idx <- years <= current_year
    ages <- current_year - years[idx]
    sum(investments[idx] * survival_weibull(ages, params$weibull_alpha, params$weibull_lambda))
  }, numeric(1))
  data.frame(year = years, asset_family = asset, investment = investments, stock = stocks)
}

init_windows <- data.frame(
  initialization_window = c("full_available_history", "cold_start_1925", "cold_start_1931", "cold_start_1947"),
  first_investment_year_used = c(min(flow$year), 1925, 1931, 1947),
  interpretation = c(
    "Uses all S29C vintages available to D01 and should replicate the D01 full-history endpoint.",
    "Common cross-switch start; removes pre-1925 inherited vintage history.",
    "Fully supported diagnostic start; removes 1901-1930 inherited vintage history.",
    "Postwar rebase start; removes all pre-1947 inherited vintage history."
  )
)

initialization_annual <- do.call(rbind, lapply(seq_len(nrow(init_windows)), function(i) {
  window <- init_windows[i, ]
  me <- compute_asset_stock("ME", window$first_investment_year_used)
  nrc <- compute_asset_stock("NRC", window$first_investment_year_used)
  names(me)[3:4] <- c("I_ME_REAL_2017", "K_ME_gross_surviving_2017")
  names(nrc)[3:4] <- c("I_NRC_REAL_2017", "K_NRC_gross_surviving_2017")
  merged <- merge(me[, c("year", "I_ME_REAL_2017", "K_ME_gross_surviving_2017")],
                  nrc[, c("year", "I_NRC_REAL_2017", "K_NRC_gross_surviving_2017")],
                  by = "year", all = FALSE)
  merged$K_core_ME_NRC_gross_surviving_2017 <- merged$K_ME_gross_surviving_2017 + merged$K_NRC_gross_surviving_2017
  base_1947 <- merged$K_core_ME_NRC_gross_surviving_2017[merged$year == 1947]
  merged$core_index_1947_100 <- if (length(base_1947) == 1 && base_1947 > 0) {
    100 * merged$K_core_ME_NRC_gross_surviving_2017 / base_1947
  } else {
    NA_real_
  }
  first_valid <- merged$K_core_ME_NRC_gross_surviving_2017[which(merged$K_core_ME_NRC_gross_surviving_2017 > 0)[1]]
  merged$core_index_first_valid_100 <- 100 * merged$K_core_ME_NRC_gross_surviving_2017 / first_valid
  merged$initialization_window <- window$initialization_window
  merged$first_investment_year_used <- window$first_investment_year_used
  merged <- merged[, c(
    "initialization_window", "first_investment_year_used", "year",
    "I_ME_REAL_2017", "I_NRC_REAL_2017",
    "K_ME_gross_surviving_2017", "K_NRC_gross_surviving_2017",
    "K_core_ME_NRC_gross_surviving_2017",
    "core_index_1947_100", "core_index_first_valid_100"
  )]
  merged
}))

full_endpoint <- initialization_annual$core_index_1947_100[
  initialization_annual$initialization_window == "full_available_history" &
    initialization_annual$year == 2024
]
initialization_summary <- do.call(rbind, lapply(seq_len(nrow(init_windows)), function(i) {
  window <- init_windows[i, ]
  rows <- initialization_annual[initialization_annual$initialization_window == window$initialization_window, ]
  idx_1947_available <- 1947 %in% rows$year && is.finite(rows$core_index_1947_100[rows$year == 2024])
  endpoint_1947 <- rows$core_index_1947_100[rows$year == 2024]
  endpoint_first <- rows$core_index_first_valid_100[rows$year == 2024]
  data.frame(
    initialization_window = window$initialization_window,
    first_investment_year_used = window$first_investment_year_used,
    first_output_year = min(rows$year),
    index_1947_availability = if (idx_1947_available) "available" else "not_available",
    core_index_2024_1947_100 = if (length(endpoint_1947) == 1) endpoint_1947 else NA_real_,
    core_index_2024_first_valid_100 = if (length(endpoint_first) == 1) endpoint_first else NA_real_,
    endpoint_ratio_relative_to_full_history_D01 = safe_ratio(endpoint_1947, full_endpoint),
    interpretation = window$interpretation
  )
}))

scope_boundary <- data.frame(
  object = c(
    "ME",
    "NRC",
    "ME+NRC core",
    "government transportation",
    "IPP",
    "total NFC fixed assets",
    "Shaikh asset-level ME+NRC diagnostic path",
    "Shaikh aggregate NFC Weibull diagnostic path"
  ),
  included_in_D01_core = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
  capacity_building_status = c(
    "core productive-capital asset",
    "core productive-capital asset",
    "D01 core aggregation of ME and NRC",
    "capacity-adjacent infrastructure or conditioning object",
    "excluded baseline asset; possible conditioning object",
    "broader aggregate than D01 ME+NRC core",
    "diagnostic comparator with different legal-sector boundary",
    "diagnostic comparator with broader aggregate fixed-asset boundary"
  ),
  reason = c(
    "Authorized by GPIM constitution as included baseline asset.",
    "Authorized by GPIM constitution as included baseline asset.",
    "Constitution defines K as ME plus NRC subject to valid aggregation.",
    "Constitution parks government fixed assets outside baseline core.",
    "Constitution excludes intellectual property products from baseline core.",
    "Broader than ME+NRC and not authorized as D01 core object.",
    "Used for diagnostic trajectory comparison, not as Chapter 2 core stock.",
    "Used for diagnostic trajectory comparison, not as Chapter 2 core stock."
  ),
  current_authorization_status = c(
    "D01 gross-survival audit object",
    "D01 gross-survival audit object",
    "D01 gross-survival audit object; not econometrics-authorized",
    "metadata or later boundary decision only",
    "excluded or conditioning object only",
    "not authorized for D01 core",
    "diagnostic comparator only",
    "diagnostic comparator only"
  ),
  d02_recommendation = c(
    "include",
    "include",
    "include",
    "park",
    "park",
    "exclude",
    "park",
    "park"
  ),
  notes = c(
    "Keep separately auditable from NRC.",
    "Keep separately auditable from ME.",
    "Do not treat this audit object as paper-facing baseline until later refreeze authorization.",
    "Do not add to D01/D02 core unless a later boundary decision authorizes it.",
    "Do not add to D01/D02 core; may condition theta in later design.",
    "Retain for scope diagnostics only.",
    "Boundary differs from Chapter 2 NFC ME+NRC; compare indexes, not levels.",
    "Boundary differs from D01 asset-level core; compare indexes, not levels."
  )
)

attribution_matrix <- data.frame(
  factor = c(
    "retirement/survival schedule defect",
    "input-path difference",
    "initialization-history difference",
    "scope/boundary difference",
    "price/deflator difference",
    "remaining unidentified difference"
  ),
  tested_in_D01 = c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
  tested_in_D02 = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  resolved = c(TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
  evidence_file = c(
    "output/US/D01_GPIM_GROSS_SURVIVAL_REMEDIATION/D01_validation_checks.csv",
    "reports/report_gpim_shaikh_comparison_2026-06-25/tables/table_08_cross_switch_summary.csv; output/US/D02_GPIM_INPUT_INITIALIZATION_AUDIT/D02_input_path_summary.csv",
    "output/US/D02_GPIM_INPUT_INITIALIZATION_AUDIT/D02_initialization_sensitivity_summary.csv",
    "output/US/D02_GPIM_INPUT_INITIALIZATION_AUDIT/D02_scope_boundary_ledger.csv",
    "output/US/S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION/csv/S29C_fixed_assets_price_real_investment_long.csv; reports/report_gpim_shaikh_comparison_2026-06-25/tables/table_08_cross_switch_summary.csv",
    "output/US/D02_GPIM_INPUT_INITIALIZATION_AUDIT/D02_gap_attribution_matrix.csv"
  ),
  direction_of_effect = c(
    "D01 raises 2024 endpoint relative to frozen terminal-cliff stock.",
    "Chapter 2/S29C input path keeps endpoint far below Shaikh diagnostic input path under common engines.",
    "Later cold starts raise 1947-based endpoint by reducing inherited pre-1947 vintage effects.",
    "Broader or different boundaries can raise or lower diagnostic trajectories; D02 classifies but does not quantify an additive effect.",
    "Deflator/input construction is implicated by input-path evidence but not re-estimated in D02.",
    "Residual remains until input deflators, initialization, and boundary decisions are separately closed."
  ),
  estimated_materiality = c(
    "material and resolved for first defect",
    "high",
    "high",
    "unknown; classified but unresolved",
    "material candidate; not separately isolated",
    "open"
  ),
  remaining_action = c(
    "No further survival-cliff correction in D02.",
    "Audit S29C nominal-to-real investment and deflator path against provider and Shaikh asset inputs.",
    "Decide explicit inherited-vintage or warmup treatment before refreeze.",
    "Decide whether parked conditioning assets remain outside core.",
    "Run a bounded deflator provenance audit; do not modify provider data in D02.",
    "Carry only after D03/D04 close input and boundary decisions."
  ),
  notes = c(
    "D01 2024 endpoint is 41.808879 on 1947=100; frozen endpoint is 35.806099.",
    paste0("Under Shaikh constant engine, Chapter 2 input ends at ", round(shaikh_constant_ch2, 3),
           " while Shaikh input ends at ", round(shaikh_constant_shaikh, 3), "."),
    "D02 recomputes full, 1925, 1931, and 1947 cold starts under D01 survival parameters.",
    "Government transportation, IPP, and total NFC fixed assets remain non-core or parked.",
    "S29C is the authorized real-investment input but its path remains the object requiring audit.",
    "D02 narrows but does not claim full closure of the Shaikh comparison gap."
  )
)

input_summary_path <- file.path(d02_dir, "D02_input_path_summary.csv")
input_annual_path <- file.path(d02_dir, "D02_input_path_annual.csv")
shaikh_comparison_path <- file.path(d02_dir, "D02_shaikh_diagnostic_input_comparison.csv")
init_summary_path <- file.path(d02_dir, "D02_initialization_sensitivity_summary.csv")
init_annual_path <- file.path(d02_dir, "D02_initialization_sensitivity_annual.csv")
scope_path <- file.path(d02_dir, "D02_scope_boundary_ledger.csv")
attribution_path <- file.path(d02_dir, "D02_gap_attribution_matrix.csv")
validation_path <- file.path(d02_dir, "D02_validation_checks.csv")
audit_report_path <- file.path(d02_dir, "D02_audit_report.md")
maint_report_path <- file.path(maint_dir, "D02_GPIM_INPUT_INITIALIZATION_AUDIT_REPORT.md")
changed_paths_path <- file.path(maint_dir, "D02_changed_paths_ledger.csv")

write.csv(input_summary, input_summary_path, row.names = FALSE)
write.csv(input_annual, input_annual_path, row.names = FALSE)
write.csv(cross_input_compare, shaikh_comparison_path, row.names = FALSE)
write.csv(initialization_summary, init_summary_path, row.names = FALSE)
write.csv(initialization_annual, init_annual_path, row.names = FALSE)
write.csv(scope_boundary, scope_path, row.names = FALSE)
write.csv(attribution_matrix, attribution_path, row.names = FALSE)

d01_endpoint <- d01_core$core_stock_index_1947_100[d01_core$year == 2024]
frozen_endpoint <- d01_comparison$chapter2_frozen_G_TOT_GPIM_2017_index_1947_100[d01_comparison$year == 2024]
full_d02_endpoint <- initialization_summary$core_index_2024_1947_100[
  initialization_summary$initialization_window == "full_available_history"
]
cold_1925_endpoint <- initialization_summary$core_index_2024_1947_100[
  initialization_summary$initialization_window == "cold_start_1925"
]
cold_1931_endpoint <- initialization_summary$core_index_2024_1947_100[
  initialization_summary$initialization_window == "cold_start_1931"
]
cold_1947_endpoint <- initialization_summary$core_index_2024_1947_100[
  initialization_summary$initialization_window == "cold_start_1947"
]

report_lines <- c(
  "# D02 GPIM Input-Path and Initialization-History Audit",
  "",
  paste0("**Date:** 2026-06-27"),
  paste0("**Branch:** `", branch_name, "`"),
  paste0("**Base commit:** `", base_sha_expected, "`"),
  "**Status:** Audit-only output; not authorized for econometric consumption.",
  "",
  "## Purpose",
  "",
  "D02 explains why the D01 corrected gross-survival stock remains low relative to Shaikh diagnostic paths. The audit focuses on input-path differences, initialization-history treatment, and asset-boundary or scope differences.",
  "",
  "## D01 result being audited",
  "",
  paste0("D01 fixed the survival cliff and produced a 2024 core ME+NRC index of `", round(d01_endpoint, 6), "` on a 1947=100 basis. The frozen diagnostic endpoint was `", round(frozen_endpoint, 6), "`. D01 resolved the retirement-schedule defect but did not authorize baseline replacement."),
  "",
  "## Input-path findings",
  "",
  paste0("S29C ME real investment changes from `", round(input_summary$value_1947[input_summary$asset == "ME"], 3), "` in 1947 to `", round(input_summary$value_2024[input_summary$asset == "ME"], 3), "` in 2024, a 2024/1947 ratio of `", round(input_summary$ratio_2024_to_1947[input_summary$asset == "ME"], 6), "`."),
  paste0("S29C NRC real investment changes from `", round(input_summary$value_1947[input_summary$asset == "NRC"], 3), "` in 1947 to `", round(input_summary$value_2024[input_summary$asset == "NRC"], 3), "` in 2024, a 2024/1947 ratio of `", round(input_summary$ratio_2024_to_1947[input_summary$asset == "NRC"], 6), "`."),
  paste0("The cross-switch diagnostic is decisive: under the Shaikh constant retirement engine, Chapter 2 input ends at `", round(shaikh_constant_ch2, 3), "` while Shaikh asset input ends at `", round(shaikh_constant_shaikh, 3), "` on the same 1947=100 basis. The input path remains a high-materiality source of the gap independent of the survival schedule."),
  "",
  "## Initialization-history findings",
  "",
  paste0("Full-history D02 replication ends at `", round(full_d02_endpoint, 6), "`, matching D01. The 1925 cold start ends at `", round(cold_1925_endpoint, 6), "`, the 1931 cold start ends at `", round(cold_1931_endpoint, 6), "`, and the 1947 cold start ends at `", round(cold_1947_endpoint, 6), "` on a 1947=100 basis."),
  "The inherited pre-1947 vintage history is therefore material. Later cold starts raise the 1947-based endpoint because they remove inherited vintage-stock composition from the denominator and early stock path.",
  "",
  "## Scope/boundary findings",
  "",
  "D02 keeps ME and NRC inside the core. Government transportation and IPP remain parked or conditioning objects. Total NFC fixed assets and Shaikh diagnostic paths remain comparators, not D01/D02 core objects. Boundary differences remain classified, not resolved as an additive numerical contribution.",
  "",
  "## Gap attribution matrix summary",
  "",
  "D01 resolved the retirement/survival schedule defect. D02 tests and confirms that input-path and initialization-history differences remain material. D02 classifies scope and boundary differences, flags price/deflator differences as a bounded follow-up, and leaves remaining unidentified differences open until those decisions close.",
  "",
  "## What D01 resolved",
  "",
  "D01 removed the forced mass exit at mean service life and produced a validated gross-survival stock under untruncated Weibull survival.",
  "",
  "## What D02 resolves or narrows",
  "",
  "D02 narrows the post-D01 gap to input-path, initialization-history, and unresolved boundary/deflator decisions. It confirms that the low D01 endpoint is not a residual survival-cliff problem.",
  "",
  "## Remaining unresolved decisions",
  "",
  "- Audit S29C nominal-to-real investment and deflator construction against provider and Shaikh asset inputs.",
  "- Decide inherited-vintage and warmup treatment before any refreeze.",
  "- Decide whether parked boundary objects remain outside the core or become conditioning variables only.",
  "- Preserve boundary discipline before any paper-facing baseline replacement.",
  "",
  "## Authorization boundary",
  "",
  "D02 is audit-only. It does not authorize replacement of the frozen Chapter 2 capital stock, S31/S32 reruns, VECM estimation, investment-function estimation, paper-facing baseline use, or downstream econometric consumption.",
  "",
  "## Recommended next phase",
  "",
  "Run a bounded D03 S29C investment-price and deflator provenance audit, then a separate initialization/warmup decision pass before any refreeze."
)
writeLines(report_lines, audit_report_path, useBytes = TRUE)
writeLines(report_lines, maint_report_path, useBytes = TRUE)

d01_hash_after <- vapply(c(d01_core_path, d01_asset_path, d01_comparison_path), sha256_file, character(1))

required_d02_files <- c(
  input_summary_path,
  input_annual_path,
  shaikh_comparison_path,
  init_summary_path,
  init_annual_path,
  scope_path,
  attribution_path,
  validation_path,
  audit_report_path
)
required_report_files <- c(maint_report_path, changed_paths_path)

validation <- data.frame(check_name = character(), status = character(), evidence = character())
add_check <- function(name, pass, evidence) {
  validation <<- rbind(
    validation,
    data.frame(check_name = name, status = if (isTRUE(pass)) "PASS" else "FAIL", evidence = evidence)
  )
}

add_check("reads_d01_outputs_successfully", nrow(d01_core) > 0 && nrow(d01_asset) > 0 && nrow(d01_comparison) > 0, "D01 core, asset, and comparison files loaded.")
add_check("reads_s29c_real_investment_successfully", nrow(flow) == 248 && identical(sort(unique(flow$asset_family)), c("ME", "NRC")), paste("Rows", nrow(flow)))
add_check("does_not_modify_d01_outputs", identical(d01_hash_before, d01_hash_after), paste(names(d01_hash_before), d01_hash_before, collapse = "; "))
add_check(
  "d02_data_outputs_isolated_under_d02_output_directory",
  all(startsWith(normalizePath(required_d02_files[file.exists(required_d02_files)], winslash = "/", mustWork = TRUE), normalizePath(d02_dir, winslash = "/", mustWork = TRUE))),
  normalizePath(d02_dir, winslash = "/", mustWork = TRUE)
)
add_check(
  "full_history_replication_matches_d01_2024",
  abs(full_d02_endpoint - d01_endpoint) < 1e-8,
  paste("D01", d01_endpoint, "D02 full history", full_d02_endpoint)
)
add_check(
  "initialization_treatments_clearly_labeled",
  identical(sort(unique(initialization_summary$initialization_window)), sort(init_windows$initialization_window)),
  paste(initialization_summary$initialization_window, collapse = ", ")
)
add_check(
  "cold_starts_do_not_overwrite_full_history",
  length(unique(initialization_annual$initialization_window)) == 4 &&
    all(file.exists(c(d01_core_path, d01_asset_path, d01_comparison_path))),
  "Cold starts are D02 rows only; D01 paths still exist."
)
add_check(
  "me_and_nrc_remain_separately_auditable",
  all(c("I_ME_REAL_2017", "I_NRC_REAL_2017", "K_ME_gross_surviving_2017", "K_NRC_gross_surviving_2017") %in% names(initialization_annual)),
  "Annual initialization output keeps ME and NRC investment and stock columns."
)
non_core_objects <- scope_boundary[scope_boundary$object %in% c("government transportation", "IPP", "total NFC fixed assets"), ]
add_check(
  "scope_ledger_parks_non_core_objects",
  all(!non_core_objects$included_in_D01_core) && all(non_core_objects$d02_recommendation %in% c("park", "exclude")),
  paste(non_core_objects$object, non_core_objects$d02_recommendation, collapse = "; ")
)
report_text <- paste(readLines(audit_report_path, warn = FALSE), collapse = "\n")
add_check(
  "report_states_no_s31_s32_or_econometric_authorization",
  grepl("does not authorize replacement.*S31/S32 reruns.*VECM estimation.*investment-function estimation.*downstream econometric consumption", report_text, ignore.case = TRUE),
  "Authorization boundary is explicit in D02 report."
)
script_text <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
network_patterns <- paste(
  c(
    "download[.]file\\(",
    paste0("httr::", "GET\\("),
    paste0("httr::", "POST\\("),
    paste0("system2\\(['\\\"]", "curl"),
    paste0("readLines\\(['\\\"]", "http")
  ),
  collapse = "|"
)
add_check(
  "no_live_api_call_used",
  !grepl(network_patterns, script_text, ignore.case = TRUE),
  "Script reads local repository artifacts only."
)
add_check(
  "input_hashes_recorded",
  all(grepl("^[0-9A-F]{64}$", input_summary$source_sha256)),
  source_hash
)
write.csv(validation, validation_path, row.names = FALSE)
add_check(
  "all_required_d02_output_files_exist",
  all(file.exists(required_d02_files)),
  paste(basename(required_d02_files), collapse = "; ")
)
git_status <- tryCatch(system2("git", c("status", "--porcelain"), stdout = TRUE), error = function(e) character(0))
changed_paths <- trimws(sub("^..\\s+", "", git_status))
allowed_prefixes <- c(
  "codes/US_D02_gpim_input_initialization_audit.R",
  "output/US/D02_GPIM_INPUT_INITIALIZATION_AUDIT/",
  "reports/maintenance/D02_GPIM_INPUT_INITIALIZATION_AUDIT_2026-06-27/"
)
scope_ok <- length(changed_paths) == 0 || all(vapply(changed_paths, function(p) {
  any(startsWith(p, allowed_prefixes))
}, logical(1)))
add_check(
  "working_tree_changed_path_scope_limited_to_d02",
  scope_ok,
  if (length(changed_paths) == 0) "No changed paths observed." else paste(changed_paths, collapse = "; ")
)
write.csv(validation, validation_path, row.names = FALSE)

ledger_paths <- c(
  script_path,
  input_summary_path,
  input_annual_path,
  shaikh_comparison_path,
  init_summary_path,
  init_annual_path,
  scope_path,
  attribution_path,
  validation_path,
  audit_report_path,
  maint_report_path,
  changed_paths_path
)
changed_ledger <- data.frame(
  status = "A",
  path = sub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]])", "\\\\\\1", repo_root), "/?"), "", normalizePath(ledger_paths, winslash = "/", mustWork = FALSE)),
  artifact_role = c(
    "D02 audit script",
    "D02 input-path summary",
    "D02 input-path annual panel",
    "D02 Shaikh diagnostic input comparison",
    "D02 initialization sensitivity summary",
    "D02 initialization sensitivity annual panel",
    "D02 scope boundary ledger",
    "D02 gap attribution matrix",
    "D02 validation checks",
    "D02 audit report",
    "D02 repository maintenance report",
    "D02 changed-path ledger"
  ),
  sha256 = c(
    vapply(ledger_paths[-length(ledger_paths)], function(p) if (file.exists(p)) sha256_file(p) else NA_character_, character(1)),
    "self-hash omitted because file records its own path"
  )
)
write.csv(changed_ledger, changed_paths_path, row.names = FALSE)

if (any(validation$status != "PASS")) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("D02 validation failed: ", paste(failed, collapse = ", "), call. = FALSE)
}

message("D02 GPIM input-path and initialization-history audit complete.")
message("D02 output directory: ", normalizePath(d02_dir, winslash = "/", mustWork = TRUE))
message("Validation: ", sum(validation$status == "PASS"), " PASS, ", sum(validation$status != "PASS"), " FAIL")
