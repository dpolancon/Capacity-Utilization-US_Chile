# D01 GPIM gross-survival remediation
# Purpose: repair the U.S. GPIM survival schedule defect before any downstream use.

options(stringsAsFactors = FALSE, warn = 1)

script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
script_path <- if (length(script_arg) == 1) {
  normalizePath(sub("^--file=", "", script_arg), winslash = "/", mustWork = TRUE)
} else {
  normalizePath("codes/US_D01_gpim_gross_survival_remediation.R", winslash = "/", mustWork = TRUE)
}

repo_root <- normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
path <- function(...) file.path(repo_root, ...)

output_dir <- path("output", "US", "D01_GPIM_GROSS_SURVIVAL_REMEDIATION")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

input_path <- path(
  "output", "US", "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION",
  "csv", "S29C_fixed_assets_price_real_investment_long.csv"
)
constitution_path <- path("chapter2_vault", "04_data_measurement", "V02_GPIM_Constitution.md")
diagnostic_report_path <- path(
  "reports", "report_gpim_shaikh_comparison_2026-06-25",
  "report_gpim_shaikh_comparison_2026-06-25.md"
)
finding_matrix_path <- path(
  "reports", "report_gpim_shaikh_comparison_2026-06-25",
  "tables", "table_11_finding_matrix.csv"
)
frozen_headline_path <- path(
  "reports", "report_gpim_shaikh_comparison_2026-06-25",
  "tables", "table_04_headline_series_annual.csv"
)
diagnostic_validation_path <- path(
  "reports", "report_gpim_shaikh_comparison_2026-06-25",
  "validation", "validation_checks.csv"
)

required_inputs <- c(
  input_path,
  constitution_path,
  diagnostic_report_path,
  finding_matrix_path,
  diagnostic_validation_path,
  path("codes", "US_GPIM_shaikh_capital_stock_decay_diagnostic.R")
)

missing_inputs <- required_inputs[!file.exists(required_inputs)]
if (length(missing_inputs) > 0) {
  stop("Required D01 input(s) missing: ", paste(missing_inputs, collapse = "; "), call. = FALSE)
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

read_lines_safe <- function(file) {
  readLines(file, warn = FALSE, encoding = "UTF-8")
}

survival_weibull <- function(age, alpha, lambda) {
  exp(-((age / lambda) ^ alpha))
}

asset_params <- data.frame(
  asset_family = c("ME", "NRC"),
  asset_label = c("Machinery and Equipment", "Nonresidential Structures"),
  mean_life_years = c(14, 30),
  weibull_alpha = c(1.7, 1.6)
)
asset_params$weibull_lambda <- asset_params$mean_life_years /
  gamma(1 + 1 / asset_params$weibull_alpha)

metadata_params <- data.frame(
  asset_family = "GOV_TRANSPORT_METADATA_ONLY",
  asset_label = "Government transportation infrastructure metadata only",
  mean_life_years = 60,
  weibull_alpha = 1.3
)
metadata_params$weibull_lambda <- metadata_params$mean_life_years /
  gamma(1 + 1 / metadata_params$weibull_alpha)

input_long <- read.csv(input_path, check.names = FALSE)
input_flow <- subset(
  input_long,
  variable_role == "asset_specific_real_investment_flow" &
    asset_family %in% asset_params$asset_family &
    derived_variable_id %in% c("I_ME_REAL_2017", "I_NRC_REAL_2017")
)

input_flow$year <- as.integer(input_flow$year)
input_flow$value <- as.numeric(input_flow$value)

dup_key <- paste(input_flow$asset_family, input_flow$year)
if (anyDuplicated(dup_key)) {
  stop("Duplicate asset-year investment rows in S29C input.", call. = FALSE)
}

expected_assets <- sort(asset_params$asset_family)
observed_assets <- sort(unique(input_flow$asset_family))
if (!identical(expected_assets, observed_assets)) {
  stop("D01 expected ME and NRC real-investment inputs only.", call. = FALSE)
}

compute_asset_panel <- function(asset) {
  params <- asset_params[asset_params$asset_family == asset, ]
  asset_input <- input_flow[input_flow$asset_family == asset, ]
  asset_input <- asset_input[order(asset_input$year), ]
  years <- asset_input$year
  investments <- asset_input$value

  stocks <- vapply(years, function(current_year) {
    idx <- years <= current_year
    ages <- current_year - years[idx]
    sum(investments[idx] * survival_weibull(ages, params$weibull_alpha, params$weibull_lambda))
  }, numeric(1))

  base_1947 <- stocks[years == 1947]
  index_1947 <- if (length(base_1947) == 1 && is.finite(base_1947) && base_1947 > 0) {
    100 * stocks / base_1947
  } else {
    rep(NA_real_, length(stocks))
  }

  first_valid <- stocks[which(is.finite(stocks) & stocks > 0)[1]]

  data.frame(
    year = years,
    asset_family = asset,
    asset_label = params$asset_label,
    real_investment_2017_dollars_millions = investments,
    mean_life_years = params$mean_life_years,
    weibull_alpha = params$weibull_alpha,
    weibull_lambda = params$weibull_lambda,
    gross_surviving_stock_2017_dollars_millions = stocks,
    stock_index_1947_100 = index_1947,
    stock_index_first_valid_100 = 100 * stocks / first_valid
  )
}

asset_panel <- do.call(rbind, lapply(asset_params$asset_family, compute_asset_panel))
asset_panel <- asset_panel[order(asset_panel$asset_family, asset_panel$year), ]

me_panel <- asset_panel[asset_panel$asset_family == "ME", c(
  "year", "real_investment_2017_dollars_millions",
  "gross_surviving_stock_2017_dollars_millions"
)]
nrc_panel <- asset_panel[asset_panel$asset_family == "NRC", c(
  "year", "real_investment_2017_dollars_millions",
  "gross_surviving_stock_2017_dollars_millions"
)]
names(me_panel)[2:3] <- c("I_ME_real_2017_dollars_millions", "K_ME_gross_surviving_2017_dollars_millions")
names(nrc_panel)[2:3] <- c("I_NRC_real_2017_dollars_millions", "K_NRC_gross_surviving_2017_dollars_millions")

core_panel <- merge(me_panel, nrc_panel, by = "year", all = FALSE)
core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions <-
  core_panel$K_ME_gross_surviving_2017_dollars_millions +
  core_panel$K_NRC_gross_surviving_2017_dollars_millions
base_core_1947 <- core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions[core_panel$year == 1947]
core_panel$core_stock_index_1947_100 <- if (length(base_core_1947) == 1 && base_core_1947 > 0) {
  100 * core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions / base_core_1947
} else {
  NA_real_
}
core_first_valid <- core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions[
  which(core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions > 0)[1]
]
core_panel$core_stock_index_first_valid_100 <-
  100 * core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions / core_first_valid
core_panel$log_K_core_ME_NRC_gross_surviving <- log(
  core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions
)
core_panel <- core_panel[order(core_panel$year), ]

schedule_params <- rbind(asset_params, metadata_params)
ages <- 0:150
survival_schedule <- do.call(rbind, lapply(seq_len(nrow(schedule_params)), function(i) {
  params <- schedule_params[i, ]
  s <- survival_weibull(ages, params$weibull_alpha, params$weibull_lambda)
  data.frame(
    asset_family = params$asset_family,
    asset_label = params$asset_label,
    metadata_only = params$asset_family == "GOV_TRANSPORT_METADATA_ONLY",
    age = ages,
    mean_life_years = params$mean_life_years,
    weibull_alpha = params$weibull_alpha,
    weibull_lambda = params$weibull_lambda,
    survival_probability = s,
    retirement_mass_from_prior_age = c(NA_real_, head(s, -1) - tail(s, -1))
  )
}))

input_hash <- sha256_file(input_path)
provenance_rows <- lapply(asset_params$asset_family, function(asset) {
  asset_input <- input_flow[input_flow$asset_family == asset, ]
  data.frame(
    ledger_role = "authorized_real_investment_input",
    source_path = normalizePath(input_path, winslash = "/", mustWork = TRUE),
    source_sha256 = input_hash,
    asset_family = asset,
    derived_variable_id = unique(asset_input$derived_variable_id),
    variable_role = "asset_specific_real_investment_flow",
    unit = unique(asset_input$unit),
    price_basis = "2017 dollars",
    start_year = min(asset_input$year),
    end_year = max(asset_input$year),
    observation_count = nrow(asset_input),
    authorization_note = paste(
      "S29C is used as the latest authorized real-investment input.",
      "D01 constructs gross surviving stock only and does not authorize econometric use."
    )
  )
})
evidence_paths <- c(
  constitution_path,
  diagnostic_report_path,
  finding_matrix_path,
  diagnostic_validation_path
)
evidence_rows <- lapply(evidence_paths, function(src) {
  data.frame(
    ledger_role = "governance_or_diagnostic_evidence",
    source_path = normalizePath(src, winslash = "/", mustWork = TRUE),
    source_sha256 = sha256_file(src),
    asset_family = NA_character_,
    derived_variable_id = NA_character_,
    variable_role = NA_character_,
    unit = NA_character_,
    price_basis = NA_character_,
    start_year = NA_integer_,
    end_year = NA_integer_,
    observation_count = NA_integer_,
    authorization_note = "Read for D01 governance, scope locks, and diagnostic context."
  )
})
provenance_ledger <- do.call(rbind, c(provenance_rows, evidence_rows))

asset_panel_path <- file.path(output_dir, "D01_gpim_gross_survival_panel.csv")
core_panel_path <- file.path(output_dir, "D01_gpim_core_capital_panel.csv")
schedule_path <- file.path(output_dir, "D01_survival_schedule_table.csv")
provenance_path <- file.path(output_dir, "D01_input_provenance_ledger.csv")
validation_path <- file.path(output_dir, "D01_validation_checks.csv")
comparison_path <- file.path(output_dir, "D01_vs_frozen_diagnostic_comparison.csv")
report_path <- file.path(output_dir, "D01_remediation_report.md")

write.csv(asset_panel, asset_panel_path, row.names = FALSE)
write.csv(core_panel, core_panel_path, row.names = FALSE)
write.csv(survival_schedule, schedule_path, row.names = FALSE)
write.csv(provenance_ledger, provenance_path, row.names = FALSE)

headline <- read.csv(frozen_headline_path, check.names = FALSE)
years_cmp <- sort(unique(c(core_panel$year, headline$year)))
comparison <- data.frame(year = years_cmp)
add_series <- function(df, series_id, value_name, index_name) {
  series <- df[df$series_id == series_id, c("year", "value", "index_1947")]
  names(series) <- c("year", value_name, index_name)
  merge(comparison, series, by = "year", all.x = TRUE)
}
comparison$d01_K_core_ME_NRC_gross_surviving_2017_dollars_millions <-
  core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions[match(years_cmp, core_panel$year)]
comparison$d01_core_stock_index_1947_100 <-
  core_panel$core_stock_index_1947_100[match(years_cmp, core_panel$year)]
for (series_id in c(
  "chapter2_frozen_G_TOT_GPIM_2017",
  "shaikh_asset_ME_NRC_gross_real",
  "shaikh_aggregate_weibull_KGR_NF_corp",
  "shaikh_canonical_KGCcorp_real"
)) {
  series <- headline[headline$series_id == series_id, c("year", "value", "index_1947")]
  suffix <- gsub("[^A-Za-z0-9]+", "_", series_id)
  names(series) <- c("year", paste0(suffix, "_value"), paste0(suffix, "_index_1947_100"))
  comparison <- merge(comparison, series, by = "year", all.x = TRUE)
}
comparison$comparison_scope_note <- paste(
  "D01 repairs Chapter 2 gross survival for ME+NRC only.",
  "Frozen and Shaikh diagnostic series retain their original boundaries."
)
comparison <- comparison[order(comparison$year), ]
write.csv(comparison, comparison_path, row.names = FALSE)

constitution_lines <- read_lines_safe(constitution_path)
diagnostic_lines <- read_lines_safe(diagnostic_report_path)
finding_matrix <- read.csv(finding_matrix_path, check.names = FALSE)
finding_text <- paste(finding_matrix$Evidence, collapse = " ")

report_lines <- c(
  "# D01 GPIM Gross-Survival Remediation",
  "",
  "**Date:** 2026-06-26",
  "**Status:** Gross-survival remediation output; not authorized for econometric consumption.",
  "",
  "## Governance lock",
  "",
  paste(
    "The V02 GPIM Constitution governs this pass. It supersedes specifications that",
    "treat mean service life as a terminal age, force Weibull survival to zero after",
    "the mean life, or conflate survival, conditional productive intensity, and",
    "economic depreciation."
  ),
  "",
  "D01 therefore repairs only the gross real surviving stock. It does not construct a productive stock, a net or wealth stock, a capital-services series, current-cost valuation, or consumption of fixed capital. The current capital-stock series remains unauthorized as a paper-facing baseline until reimplementation and validation are complete.",
  "",
  "## Diagnostic basis",
  "",
  paste(
    "The GPIM decay diagnostic found that the inherited terminal-exit rule removed",
    "large surviving cohort mass immediately after the stated mean life. It also",
    "found that input-path and initialization differences remain material. D01 is",
    "therefore a first remediation step, not a full refreeze."
  ),
  "",
  paste("Finding-matrix evidence:", finding_text),
  "",
  "## Inputs",
  "",
  paste0("- Real-investment source: `", normalizePath(input_path, winslash = "/", mustWork = TRUE), "`."),
  "- Included D01 assets: ME and NRC.",
  "- Excluded from the core D01 construction: IPP, residential assets, government assets, inventories, land, and government transportation infrastructure.",
  "- Government transportation Weibull parameters are retained only as metadata in the survival schedule table.",
  "",
  "## Method",
  "",
  "The implemented survival function is:",
  "",
  "```text",
  "S(a) = exp(-((a / lambda) ^ alpha))",
  "lambda = L / Gamma(1 + 1 / alpha)",
  "K_asset,t = sum_a I_asset,t-a * S_asset(a)",
  "```",
  "",
  paste0("- ME: L = 14, alpha = 1.7, lambda = ", round(asset_params$weibull_lambda[asset_params$asset_family == "ME"], 6), "."),
  paste0("- NRC: L = 30, alpha = 1.6, lambda = ", round(asset_params$weibull_lambda[asset_params$asset_family == "NRC"], 6), "."),
  paste0("- Government transportation metadata only: L = 60, alpha = 1.3, lambda = ", round(metadata_params$weibull_lambda, 6), "."),
  "",
  "The timing convention is beginning-of-year vintage inclusion for annual cohorts in the exact cohort convolution. No computational cliff is imposed at mean service life; surviving tail mass remains positive beyond L.",
  "",
  "## Outputs",
  "",
  paste0("- `", basename(asset_panel_path), "`"),
  paste0("- `", basename(core_panel_path), "`"),
  paste0("- `", basename(schedule_path), "`"),
  paste0("- `", basename(provenance_path), "`"),
  paste0("- `", basename(validation_path), "`"),
  paste0("- `", basename(comparison_path), "`"),
  "",
  "## Authorization boundary",
  "",
  "D01 authorizes only the isolated gross-survival repair artifact. It does not authorize replacement of the frozen Chapter 2 stock, S31/S32 reruns, VECM estimation, investment-function estimation, paper-facing baseline use, or downstream econometric consumption.",
  "",
  "## Source checks read",
  "",
  paste0("- Constitution line count: ", length(constitution_lines)),
  paste0("- Diagnostic report line count: ", length(diagnostic_lines))
)
writeLines(report_lines, report_path, useBytes = TRUE)

validation <- data.frame(
  check_name = character(),
  status = character(),
  evidence = character()
)
add_check <- function(name, pass, evidence) {
  validation <<- rbind(
    validation,
    data.frame(
      check_name = name,
      status = if (isTRUE(pass)) "PASS" else "FAIL",
      evidence = evidence
    )
  )
}

add_check(
  "lambda_calibration_matches_locked_values",
  abs(asset_params$weibull_lambda[asset_params$asset_family == "ME"] - 15.6908) < 0.01 &&
    abs(asset_params$weibull_lambda[asset_params$asset_family == "NRC"] - 33.4607) < 0.01 &&
    abs(metadata_params$weibull_lambda - 64.9648) < 0.01,
  paste(
    "ME", round(asset_params$weibull_lambda[asset_params$asset_family == "ME"], 6),
    "NRC", round(asset_params$weibull_lambda[asset_params$asset_family == "NRC"], 6),
    "Gov transport metadata", round(metadata_params$weibull_lambda, 6)
  )
)

survival_at_l <- merge(
  schedule_params,
  survival_schedule,
  by = c("asset_family", "asset_label", "mean_life_years", "weibull_alpha", "weibull_lambda")
)
survival_at_l <- survival_at_l[survival_at_l$age == survival_at_l$mean_life_years, ]
add_check(
  "survival_at_mean_life_positive",
  all(survival_at_l$survival_probability > 0),
  paste(paste(survival_at_l$asset_family, round(survival_at_l$survival_probability, 6)), collapse = "; ")
)

mono_ok <- all(tapply(
  survival_schedule$survival_probability,
  survival_schedule$asset_family,
  function(x) all(diff(x) <= 1e-14)
))
add_check("survival_schedule_monotone_nonincreasing", mono_ok, "Survival probabilities do not increase over ages 0..150.")

age_zero <- survival_schedule[survival_schedule$age == 0, ]
add_check("survival_at_age_zero_equals_one", all(abs(age_zero$survival_probability - 1) < 1e-14), "All schedules start at S(0)=1.")

no_cliff <- all(vapply(asset_params$asset_family, function(asset) {
  p <- asset_params[asset_params$asset_family == asset, ]
  s_l <- survival_weibull(p$mean_life_years, p$weibull_alpha, p$weibull_lambda)
  s_lp1 <- survival_weibull(p$mean_life_years + 1, p$weibull_alpha, p$weibull_lambda)
  s_l > 0 && s_lp1 > 0 && s_lp1 < s_l
}, logical(1)))
add_check("no_terminal_cliff_at_mean_life", no_cliff, "S(L) and S(L+1) remain positive for ME and NRC.")

add_check(
  "asset_stocks_nonnegative",
  all(asset_panel$gross_surviving_stock_2017_dollars_millions >= 0),
  paste("Minimum asset stock", min(asset_panel$gross_surviving_stock_2017_dollars_millions))
)

add_check(
  "core_stock_positive_where_observed",
  all(core_panel$K_core_ME_NRC_gross_surviving_2017_dollars_millions > 0),
  paste("Core years", min(core_panel$year), "to", max(core_panel$year))
)

add_check(
  "me_and_nrc_reported_separately",
  identical(sort(unique(asset_panel$asset_family)), c("ME", "NRC")),
  paste(unique(asset_panel$asset_family), collapse = ", ")
)

add_check(
  "isolated_d01_output_directory_only",
  grepl("/output/US/D01_GPIM_GROSS_SURVIVAL_REMEDIATION$", normalizePath(output_dir, winslash = "/", mustWork = TRUE)),
  normalizePath(output_dir, winslash = "/", mustWork = TRUE)
)

forbidden_terms <- c("net", "wealth", "productive", "efficiency")
data_columns <- paste(c(names(asset_panel), names(core_panel), names(survival_schedule)), collapse = " ")
add_check(
  "no_forbidden_downstream_stock_columns",
  !grepl(paste(forbidden_terms, collapse = "|"), data_columns, ignore.case = TRUE),
  "D01 data columns contain only gross-survival stock, input, schedule, index, and provenance fields."
)

add_check(
  "provenance_hashes_present",
  all(!is.na(provenance_ledger$source_sha256) & grepl("^[0-9A-F]{64}$", provenance_ledger$source_sha256)),
  paste("Ledger rows", nrow(provenance_ledger))
)

add_check(
  "index_1947_available_when_1947_observed",
  1947 %in% core_panel$year && all(!is.na(core_panel$core_stock_index_1947_100)),
  "1947 is observed in S29C ME and NRC inputs; D01 index is populated for all core rows."
)

report_text <- paste(read_lines_safe(report_path), collapse = "\n")
add_check(
  "report_states_no_downstream_authorization",
  grepl("does not authorize.*downstream econometric consumption", report_text, ignore.case = TRUE),
  "D01 report limits authorization to isolated gross-survival repair."
)

required_outputs <- c(
  asset_panel_path,
  core_panel_path,
  schedule_path,
  provenance_path,
  validation_path,
  comparison_path,
  report_path
)
write.csv(validation, validation_path, row.names = FALSE)
add_check(
  "required_output_files_generated",
  all(file.exists(required_outputs)),
  paste(basename(required_outputs), collapse = "; ")
)

add_check(
  "no_live_api_or_provider_mutation_dependency",
  all(file.exists(required_inputs)) &&
    !any(grepl("api|http|provider", c(input_path, output_dir), ignore.case = TRUE)),
  "Script reads tracked local repository inputs and writes only the isolated D01 output directory."
)

write.csv(validation, validation_path, row.names = FALSE)

if (any(validation$status != "PASS")) {
  failed <- validation$check_name[validation$status != "PASS"]
  stop("D01 validation failed: ", paste(failed, collapse = ", "), call. = FALSE)
}

message("D01 GPIM gross-survival remediation complete.")
message("Output directory: ", normalizePath(output_dir, winslash = "/", mustWork = TRUE))
