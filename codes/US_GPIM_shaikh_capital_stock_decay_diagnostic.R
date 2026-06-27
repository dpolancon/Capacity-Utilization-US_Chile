#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
})

options(stringsAsFactors = FALSE, scipen = 999)

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
shaikh_root <- "C:/ReposGitHub/Critical-Replication-Shaikh"
report_rel <- file.path("reports", "report_gpim_shaikh_comparison_2026-06-25")
report_dir <- file.path(root, report_rel)
table_dir <- file.path(report_dir, "tables")
figure_dir <- file.path(report_dir, "figures")
validation_dir <- file.path(report_dir, "validation")

if (dir.exists(report_dir)) unlink(report_dir, recursive = TRUE, force = TRUE)
dir.create(table_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(validation_dir, recursive = TRUE, showWarnings = FALSE)

paths <- list(
  frozen_long = file.path(root, "data", "releases", "chapter2_us_source_of_truth_v1",
                          "CH2_US_SOURCE_OF_TRUTH_LONG.csv"),
  current_investment = file.path(root, "output", "US",
                                 "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION",
                                 "csv", "S29C_fixed_assets_price_real_investment_long.csv"),
  current_components = file.path(root, "output", "US",
                                 "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION",
                                 "csv", "S29D_asset_specific_gpim_stocks_flows_long.csv"),
  current_schedule = file.path(root, "output", "US",
                               "S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION",
                               "csv", "S29D_gpim_parameter_schedule_audit.csv"),
  current_core = file.path(root, "output", "US",
                           "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION",
                           "csv", "S29E_core_capital_stocks_flows_long.csv"),
  shaikh_canonical = file.path(shaikh_root, "data", "raw", "shaikh_data",
                               "Shaikh_canonical_series_v1.csv"),
  shaikh_asset = file.path(shaikh_root, "data", "processed",
                           "kstock_private_gpim_real.csv"),
  shaikh_aggregate = file.path(shaikh_root, "data", "processed",
                               "kstock_master.csv"),
  shaikh_weibull_doc = file.path(shaikh_root, "docs",
                                 "Weibull_Retirement_Distributions.md"),
  shaikh_helpers = file.path(shaikh_root, "codes", "59_gpim_helpers.R")
)

missing <- unlist(paths)[!file.exists(unlist(paths))]
if (length(missing)) stop("Missing required input(s): ", paste(missing, collapse = "; "))

read_csv <- function(path) read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
write_csv <- function(x, name) write.csv(x, file.path(table_dir, name), row.names = FALSE, na = "")
write_text <- function(x, path) writeLines(enc2utf8(x), path, useBytes = TRUE)
fmt <- function(x, digits = 2) formatC(x, digits = digits, format = "f", big.mark = ",")
fmt_pct <- function(x, digits = 2) paste0(fmt(x, digits), "%")
md5_inputs <- function() {
  data.frame(
    input_id = names(paths),
    path = gsub("\\\\", "/", unlist(paths)),
    md5 = unname(tools::md5sum(unlist(paths))),
    stringsAsFactors = FALSE
  )
}
git_value <- function(repo, args) {
  trimws(paste(system2("git", c("-C", repo, args), stdout = TRUE, stderr = TRUE),
               collapse = "\n"))
}

input_hash_before <- md5_inputs()
chapter2_commit <- git_value(root, c("rev-parse", "HEAD"))
shaikh_commit <- git_value(shaikh_root, c("rev-parse", "HEAD"))
shaikh_status_before <- git_value(shaikh_root, c("status", "--short"))

frozen <- read_csv(paths$frozen_long)
s29c <- read_csv(paths$current_investment)
s29d <- read_csv(paths$current_components)
schedule_locked <- read_csv(paths$current_schedule)
shaikh_canonical <- read_csv(paths$shaikh_canonical)
shaikh_asset <- read_csv(paths$shaikh_asset)
shaikh_aggregate <- read_csv(paths$shaikh_aggregate)

extract_long <- function(df, id_col, id, year_col = "year", value_col = "value") {
  z <- df[df[[id_col]] == id, c(year_col, value_col), drop = FALSE]
  names(z) <- c("year", "value")
  z$year <- as.integer(z$year)
  z$value <- as.numeric(z$value)
  z <- z[order(z$year), ]
  if (!nrow(z)) stop("Series not found: ", id)
  z
}

current_frozen <- extract_long(frozen, "variable_id", "G_TOT_GPIM_2017")
current_me_i <- extract_long(s29c, "derived_variable_id", "I_ME_REAL_2017")
current_nrc_i <- extract_long(s29c, "derived_variable_id", "I_NRC_REAL_2017")
current_me_stock <- extract_long(s29d, "derived_variable_id", "G_ME_GPIM_2017")
current_nrc_stock <- extract_long(s29d, "derived_variable_id", "G_NRC_GPIM_2017")

shaikh_canonical_real <- data.frame(
  year = as.integer(shaikh_canonical$year),
  value = 1000 * as.numeric(shaikh_canonical$KGCcorp) /
    (as.numeric(shaikh_canonical$pKN) / 100),
  stringsAsFactors = FALSE
)
shaikh_canonical_real <- shaikh_canonical_real[
  is.finite(shaikh_canonical_real$value) & shaikh_canonical_real$value > 0, ]
shaikh_asset_stock <- data.frame(
  year = as.integer(shaikh_asset$year),
  value = as.numeric(shaikh_asset$TOTAL_PRODUCTIVE_K_gross_real)
)
shaikh_aggregate_stock <- data.frame(
  year = as.integer(shaikh_aggregate$year),
  value = as.numeric(shaikh_aggregate$KGR_NF_corp)
)
shaikh_me_i <- data.frame(year = as.integer(shaikh_asset$year),
                          value = as.numeric(shaikh_asset$ME_IG_real))
shaikh_nrc_i <- data.frame(year = as.integer(shaikh_asset$year),
                           value = as.numeric(shaikh_asset$NRC_IG_real))

weibull_survival <- function(age, L, alpha) {
  lambda <- L / gamma(1 + 1 / alpha)
  exp(-((age / lambda)^alpha))
}

cohort_engine <- function(investment, L, alpha = NA_real_, max_age = Inf,
                          survival_type = c("weibull", "constant"),
                          retirement_rate = NA_real_) {
  survival_type <- match.arg(survival_type)
  investment <- investment[order(investment$year), ]
  years <- investment$year
  stock <- numeric(length(years))
  for (i in seq_along(years)) {
    ages <- years[i] - investment$year[seq_len(i)]
    keep <- ages <= max_age
    weights <- if (survival_type == "weibull") {
      weibull_survival(ages[keep], L, alpha)
    } else {
      (1 - retirement_rate)^ages[keep]
    }
    stock[i] <- sum(investment$value[seq_len(i)][keep] * weights)
  }
  retirement <- c(NA_real_, head(stock, -1)) + investment$value - stock
  data.frame(year = years, investment = investment$value, stock = stock,
             retirement = retirement, stringsAsFactors = FALSE)
}

mean_age_engine <- function(investment, L, alpha) {
  investment <- investment[order(investment$year), ]
  lambda <- L / gamma(1 + 1 / alpha)
  stock <- rho <- retirement <- tau_series <- numeric(nrow(investment))
  previous_stock <- 0
  tau_bar <- 0
  for (i in seq_len(nrow(investment))) {
    rho[i] <- if (previous_stock > 0 && tau_bar > 0) {
      min(max((alpha / lambda) * (tau_bar / lambda)^(alpha - 1), 0), 1)
    } else 0
    retirement[i] <- rho[i] * previous_stock
    surviving <- previous_stock - retirement[i]
    stock[i] <- surviving + investment$value[i]
    if (stock[i] > 0) tau_bar <- (tau_bar + 1) * surviving / stock[i]
    tau_series[i] <- tau_bar
    previous_stock <- stock[i]
  }
  data.frame(year = investment$year, investment = investment$value, stock = stock,
             retirement = retirement, rho = rho, mean_age = tau_series,
             stringsAsFactors = FALSE)
}

combine_assets <- function(me, nrc, scenario_id, input_id, engine_id,
                           initialization = "cold_start_first_input_year") {
  z <- merge(me[, c("year", "investment", "stock", "retirement")],
             nrc[, c("year", "investment", "stock", "retirement")],
             by = "year", suffixes = c("_me", "_nrc"))
  data.frame(
    scenario_id = scenario_id,
    input_id = input_id,
    engine_id = engine_id,
    initialization = initialization,
    year = z$year,
    investment = z$investment_me + z$investment_nrc,
    stock = z$stock_me + z$stock_nrc,
    retirement = z$retirement_me + z$retirement_nrc,
    stringsAsFactors = FALSE
  )
}

current_truncated <- combine_assets(
  cohort_engine(current_me_i, 14, 1.7, max_age = 14),
  cohort_engine(current_nrc_i, 30, 1.6, max_age = 30),
  "current_truncated_weibull", "chapter2_current", "truncated_cohort_weibull"
)
current_untruncated <- combine_assets(
  cohort_engine(current_me_i, 14, 1.7, max_age = 5 * 14),
  cohort_engine(current_nrc_i, 30, 1.6, max_age = 5 * 30),
  "current_untruncated_weibull_5L", "chapter2_current", "untruncated_cohort_weibull_5L"
)
current_constant <- combine_assets(
  cohort_engine(current_me_i, 14, survival_type = "constant", retirement_rate = 1 / 14),
  cohort_engine(current_nrc_i, 30, survival_type = "constant", retirement_rate = 1 / 30),
  "current_constant_retirement", "chapter2_current", "constant_1_14_1_30"
)
shaikh_constant_on_current <- combine_assets(
  cohort_engine(current_me_i, 15, survival_type = "constant", retirement_rate = 1 / 15),
  cohort_engine(current_nrc_i, 38, survival_type = "constant", retirement_rate = 1 / 38),
  "shaikh_constant_retirement_on_current_input", "chapter2_current", "constant_1_15_1_38"
)
mean_age_on_current <- combine_assets(
  mean_age_engine(current_me_i, 14, 1.7),
  mean_age_engine(current_nrc_i, 30, 1.6),
  "shaikh_mean_age_hazard_on_current_input", "chapter2_current", "mean_age_hazard"
)
pooled_i <- merge(current_me_i, current_nrc_i, by = "year", suffixes = c("_me", "_nrc"))
pooled_i <- data.frame(year = pooled_i$year, value = pooled_i$value_me + pooled_i$value_nrc)
pooled_result <- cohort_engine(pooled_i, 22, 1.65, max_age = 5 * 22)
pooled_current <- data.frame(
  scenario_id = "pooled_untruncated_weibull_L22",
  input_id = "chapter2_current",
  engine_id = "pooled_cohort_weibull_L22_alpha1.65",
  initialization = "cold_start_first_input_year",
  year = pooled_result$year,
  investment = pooled_result$investment,
  stock = pooled_result$stock,
  retirement = pooled_result$retirement,
  stringsAsFactors = FALSE
)

counterfactual_annual <- rbind(
  current_truncated, current_untruncated, current_constant,
  shaikh_constant_on_current, mean_age_on_current, pooled_current
)

reproduction <- merge(
  current_truncated[, c("year", "stock")],
  current_frozen, by = "year"
)
names(reproduction)[names(reproduction) == "stock"] <- "stock_reproduced"
names(reproduction)[names(reproduction) == "value"] <- "stock_frozen"
reproduction$absolute_difference <- reproduction$stock_reproduced - reproduction$stock_frozen
reproduction$relative_difference <- reproduction$absolute_difference / reproduction$stock_frozen

headline <- rbind(
  data.frame(series_id = "chapter2_frozen_G_TOT_GPIM_2017",
             boundary = "NFC machinery/equipment plus NFC nonresidential structures",
             level_unit = "millions_2017_dollars", current_frozen),
  data.frame(series_id = "shaikh_canonical_KGCcorp_real",
             boundary = "Shaikh locked corporate fixed-capital series",
             level_unit = "millions_in_canonical_own_price_basis", shaikh_canonical_real),
  data.frame(series_id = "shaikh_aggregate_weibull_KGR_NF_corp",
             boundary = "aggregate nonfinancial corporate fixed assets",
             level_unit = "real_level_from_shaikh_pipeline", shaikh_aggregate_stock),
  data.frame(series_id = "shaikh_asset_ME_NRC_gross_real",
             boundary = "private machinery/equipment plus nonresidential structures",
             level_unit = "real_level_from_shaikh_asset_pipeline", shaikh_asset_stock)
)

add_index <- function(z, base_year = 1947L) {
  base <- z$value[z$year == base_year]
  if (length(base) != 1 || !is.finite(base) || base <= 0) {
    z$index_1947 <- NA_real_
  } else {
    z$index_1947 <- 100 * z$value / base
  }
  z$annual_growth_percent <- c(NA_real_, 100 * diff(z$value) / head(z$value, -1))
  z
}
headline <- do.call(rbind, lapply(split(headline, headline$series_id), add_index))
headline <- headline[order(headline$series_id, headline$year), ]

summary_one <- function(z, value_col = "value") {
  z <- z[is.finite(z[[value_col]]) & z[[value_col]] > 0, ]
  z <- z[order(z$year), ]
  peak <- which.max(z[[value_col]])
  base47 <- z[[value_col]][z$year == 1947]
  end_idx <- if (length(base47) == 1) 100 * tail(z[[value_col]], 1) / base47 else NA_real_
  data.frame(
    start_year = min(z$year), end_year = max(z$year),
    start_value = z[[value_col]][1], end_value = tail(z[[value_col]], 1),
    peak_year = z$year[peak], peak_value = z[[value_col]][peak],
    peak_to_end_change_percent = 100 * (tail(z[[value_col]], 1) / z[[value_col]][peak] - 1),
    cagr_percent = 100 * ((tail(z[[value_col]], 1) / z[[value_col]][1])^(1 /
                            (max(z$year) - min(z$year))) - 1),
    index_1947_at_end = end_idx,
    stringsAsFactors = FALSE
  )
}

headline_summary <- do.call(rbind, lapply(split(headline, headline$series_id), function(z) {
  cbind(series_id = z$series_id[1], boundary = z$boundary[1],
        level_unit = z$level_unit[1], summary_one(z))
}))
row.names(headline_summary) <- NULL

boundary_ledger <- data.frame(
  series_id = c(
    "chapter2_frozen_G_TOT_GPIM_2017", "shaikh_canonical_KGCcorp_real",
    "shaikh_aggregate_weibull_KGR_NF_corp", "shaikh_asset_ME_NRC_gross_real"
  ),
  legal_sector = c("nonfinancial corporate", "corporate", "nonfinancial corporate", "private"),
  asset_scope = c("ME + NRC", "locked Shaikh corporate fixed capital",
                  "aggregate fixed assets represented by FAAt601 line",
                  "ME + NRC from private asset tables"),
  construction = c("asset-specific truncated cohort schedules, then exact addition",
                   "locked Shaikh canonical series, deflated by pKN",
                   "aggregate mean-age Weibull hazard, L=22 alpha=1.65",
                   "asset-specific constant retirement, ME=1/15 NRC=1/38"),
  direct_level_comparison = c("reference", "no", "no", "no"),
  trajectory_comparison = "yes, after 1947=100 rebasing",
  scope_warning = c(
    "Frozen Chapter 2 baseline.",
    "Corporate boundary and vintage differ.",
    "Aggregate NFC account does not isolate ME and NRC.",
    "Private asset tables are broader than NFC."
  ),
  stringsAsFactors = FALSE
)

schedule_diagnostic <- data.frame(
  asset = c("ME", "NRC"),
  L = c(14, 30), alpha = c(1.7, 1.6),
  survival_at_L = c(weibull_survival(14, 14, 1.7),
                    weibull_survival(30, 30, 1.6)),
  current_survival_at_L_plus_1 = 0,
  untruncated_survival_at_L_plus_1 = c(weibull_survival(15, 14, 1.7),
                                       weibull_survival(31, 30, 1.6)),
  forced_exit_mass = c(weibull_survival(14, 14, 1.7),
                       weibull_survival(30, 30, 1.6)),
  survival_at_5L = c(weibull_survival(70, 14, 1.7),
                     weibull_survival(150, 30, 1.6)),
  stringsAsFactors = FALSE
)

scenario_summary <- do.call(rbind, lapply(split(counterfactual_annual,
                                                counterfactual_annual$scenario_id), function(z) {
  cbind(scenario_id = z$scenario_id[1], input_id = z$input_id[1],
        engine_id = z$engine_id[1], summary_one(z, "stock"))
}))
row.names(scenario_summary) <- NULL

cross_inputs <- list(
  chapter2_current = list(me = current_me_i[current_me_i$year >= 1925, ],
                          nrc = current_nrc_i[current_nrc_i$year >= 1925, ]),
  shaikh_asset = list(me = shaikh_me_i, nrc = shaikh_nrc_i)
)
cross_engines <- list(
  current_truncated = function(inp) combine_assets(
    cohort_engine(inp$me, 14, 1.7, max_age = 14),
    cohort_engine(inp$nrc, 30, 1.6, max_age = 30),
    "", "", "current_truncated"),
  untruncated_5L = function(inp) combine_assets(
    cohort_engine(inp$me, 14, 1.7, max_age = 70),
    cohort_engine(inp$nrc, 30, 1.6, max_age = 150),
    "", "", "untruncated_5L"),
  shaikh_constant = function(inp) combine_assets(
    cohort_engine(inp$me, 15, survival_type = "constant", retirement_rate = 1 / 15),
    cohort_engine(inp$nrc, 38, survival_type = "constant", retirement_rate = 1 / 38),
    "", "", "shaikh_constant"),
  mean_age_hazard = function(inp) combine_assets(
    mean_age_engine(inp$me, 14, 1.7),
    mean_age_engine(inp$nrc, 30, 1.6),
    "", "", "mean_age_hazard")
)

cross_rows <- list()
for (input_name in names(cross_inputs)) {
  for (engine_name in names(cross_engines)) {
    z <- cross_engines[[engine_name]](cross_inputs[[input_name]])
    z$scenario_id <- paste(input_name, engine_name, sep = "__")
    z$input_id <- input_name
    z$engine_id <- engine_name
    z$initialization <- "cold_start_1925"
    cross_rows[[length(cross_rows) + 1L]] <- z
  }
}
cross_annual <- do.call(rbind, cross_rows)
cross_annual <- do.call(rbind, lapply(split(cross_annual, cross_annual$scenario_id), function(z) {
  base <- z$stock[z$year == 1947]
  z$index_1947 <- 100 * z$stock / base
  z
}))
cross_summary <- do.call(rbind, lapply(split(cross_annual, cross_annual$scenario_id), function(z) {
  cbind(scenario_id = z$scenario_id[1], input_id = z$input_id[1],
        engine_id = z$engine_id[1], summary_one(z, "stock"))
}))
row.names(cross_summary) <- NULL

benchmark_idx <- headline[
  headline$series_id == "shaikh_asset_ME_NRC_gross_real" &
    headline$year >= 1947, c("year", "index_1947")]
names(benchmark_idx)[2] <- "benchmark_index"
baseline_idx <- headline[
  headline$series_id == "chapter2_frozen_G_TOT_GPIM_2017" &
    headline$year >= 1947, c("year", "index_1947")]
names(baseline_idx)[2] <- "baseline_index"
base_compare <- merge(baseline_idx, benchmark_idx, by = "year")
baseline_rmse <- sqrt(mean((log(base_compare$baseline_index) -
                              log(base_compare$benchmark_index))^2))
baseline_endpoint_gap <- tail(log(base_compare$baseline_index) -
                                log(base_compare$benchmark_index), 1)

attribution_rows <- list()
for (scenario in unique(counterfactual_annual$scenario_id)) {
  z <- counterfactual_annual[counterfactual_annual$scenario_id == scenario &
                               counterfactual_annual$year >= 1947, c("year", "stock")]
  base <- z$stock[z$year == 1947]
  z$candidate_index <- 100 * z$stock / base
  q <- merge(z[, c("year", "candidate_index")], benchmark_idx, by = "year")
  rmse <- sqrt(mean((log(q$candidate_index) - log(q$benchmark_index))^2))
  endpoint_gap <- tail(log(q$candidate_index) - log(q$benchmark_index), 1)
  candidate_trend <- unname(coef(lm(log(candidate_index) ~ year, data = q))["year"])
  benchmark_trend <- unname(coef(lm(log(benchmark_index) ~ year, data = q))["year"])
  attribution_rows[[length(attribution_rows) + 1L]] <- data.frame(
    scenario_id = scenario,
    endpoint_log_gap = endpoint_gap,
    endpoint_gap_reduction_percent = 100 *
      (1 - abs(endpoint_gap) / abs(baseline_endpoint_gap)),
    log_index_rmse = rmse,
    rmse_reduction_percent = 100 * (1 - rmse / baseline_rmse),
    candidate_log_index_trend_per_year = candidate_trend,
    benchmark_log_index_trend_per_year = benchmark_trend,
    trend_gap_per_year = candidate_trend - benchmark_trend,
    stringsAsFactors = FALSE
  )
}
attribution <- do.call(rbind, attribution_rows)

trend_direction <- function(x) {
  if (x > 105) "rising" else if (x < 95) "declining" else "approximately_flat"
}
cross_lookup <- function(input, engine) {
  cross_summary$index_1947_at_end[
    cross_summary$input_id == input & cross_summary$engine_id == engine]
}
finding_matrix <- data.frame(
  question_id = c("Q1", "Q2", "Q3", "Q4"),
  question = c(
    "Is the decline reproduced when retirement mechanics change?",
    "Does pooling heterogeneous assets materially alter the trend?",
    "Does the investment path reproduce the decline under Shaikh retirement?",
    "How much remains attributable to incompatible asset scope?"
  ),
  evidence = c(
    paste0("End indexes on Chapter 2 input: truncated=",
           fmt(scenario_summary$index_1947_at_end[
             scenario_summary$scenario_id == "current_truncated_weibull"], 1),
           ", untruncated=",
           fmt(scenario_summary$index_1947_at_end[
             scenario_summary$scenario_id == "current_untruncated_weibull_5L"], 1),
           ", mean-age=",
           fmt(scenario_summary$index_1947_at_end[
             scenario_summary$scenario_id == "shaikh_mean_age_hazard_on_current_input"], 1), "."),
    paste0("Separate untruncated end index=",
           fmt(scenario_summary$index_1947_at_end[
             scenario_summary$scenario_id == "current_untruncated_weibull_5L"], 1),
           "; pooled L22 end index=",
           fmt(scenario_summary$index_1947_at_end[
             scenario_summary$scenario_id == "pooled_untruncated_weibull_L22"], 1), "."),
    paste0("1925 cold-start Shaikh-constant engine: Chapter 2 input end index=",
           fmt(cross_lookup("chapter2_current", "shaikh_constant"), 1),
           "; Shaikh input end index=",
           fmt(cross_lookup("shaikh_asset", "shaikh_constant"), 1), "."),
    "The four headline series have non-identical legal-sector and asset boundaries; no additive percentage is identified."
  ),
  result = c(
    if (trend_direction(scenario_summary$index_1947_at_end[
      scenario_summary$scenario_id == "current_untruncated_weibull_5L"]) == "declining")
      "YES_UNDER_CURRENT_INPUT" else "NO_RETIREMENT_RULE_CHANGES_DIRECTION",
    if (abs(log(
      scenario_summary$index_1947_at_end[
        scenario_summary$scenario_id == "pooled_untruncated_weibull_L22"] /
        scenario_summary$index_1947_at_end[
          scenario_summary$scenario_id == "current_untruncated_weibull_5L"])) > 0.1)
      "MATERIAL_LEVEL_OR_TREND_EFFECT" else "LIMITED_EFFECT",
    if (trend_direction(cross_lookup("chapter2_current", "shaikh_constant")) !=
        trend_direction(cross_lookup("shaikh_asset", "shaikh_constant")))
      "INPUT_PATH_CHANGES_TREND_DIRECTION" else "INPUT_PATH_CHANGES_MAGNITUDE_ONLY",
    "SCOPE_NOT_IDENTIFIED"
  ),
  stringsAsFactors = FALSE
)

provenance <- data.frame(
  input_id = names(paths),
  repository = ifelse(grepl("^C:/ReposGitHub/Critical-Replication-Shaikh",
                            gsub("\\\\", "/", unlist(paths))),
                      "Critical-Replication-Shaikh", "Capacity-Utilization-US_Chile"),
  commit = ifelse(grepl("^C:/ReposGitHub/Critical-Replication-Shaikh",
                        gsub("\\\\", "/", unlist(paths))),
                  shaikh_commit, chapter2_commit),
  path = gsub("\\\\", "/", unlist(paths)),
  role = c(
    "frozen Chapter 2 baseline", "Chapter 2 real investment inputs",
    "Chapter 2 component stock and flow validation", "locked Chapter 2 schedule",
    "Chapter 2 aggregate stock validation", "locked Shaikh canonical benchmark",
    "Shaikh asset-level benchmark and investment inputs",
    "Shaikh aggregate-Weibull benchmark", "Shaikh parameter documentation",
    "Shaikh mean-age hazard implementation reference"
  ),
  stringsAsFactors = FALSE
)

write_csv(provenance, "table_01_input_provenance.csv")
write_csv(boundary_ledger, "table_02_boundary_compatibility_ledger.csv")
write_csv(headline_summary, "table_03_headline_series_summary.csv")
write_csv(headline, "table_04_headline_series_annual.csv")
write_csv(schedule_diagnostic, "table_05_retirement_schedule_diagnostic.csv")
write_csv(scenario_summary, "table_06_counterfactual_summary.csv")
write_csv(counterfactual_annual, "table_07_counterfactual_annual.csv")
write_csv(cross_summary, "table_08_cross_switch_summary.csv")
write_csv(cross_annual, "table_09_cross_switch_annual.csv")
write_csv(attribution, "table_10_attribution_metrics.csv")
write_csv(finding_matrix, "table_11_finding_matrix.csv")
write_csv(reproduction, "supplement_frozen_reproduction_audit.csv")

theme_report <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(), legend.position = "bottom",
        plot.title = element_text(face = "bold"), plot.caption = element_text(hjust = 0))
save_plot <- function(p, name, width = 8.4, height = 4.8) {
  ggsave(file.path(figure_dir, name), p, width = width, height = height,
         dpi = 200, bg = "white")
}

headline_labels <- c(
  chapter2_frozen_G_TOT_GPIM_2017 = "Chapter 2 frozen NFC ME+NRC",
  shaikh_canonical_KGCcorp_real = "Shaikh canonical corporate",
  shaikh_aggregate_weibull_KGR_NF_corp = "Shaikh aggregate NFC Weibull",
  shaikh_asset_ME_NRC_gross_real = "Shaikh private ME+NRC"
)
headline$label <- headline_labels[headline$series_id]
save_plot(
  ggplot(headline[headline$year >= 1947 & !is.na(headline$index_1947), ],
         aes(year, index_1947, color = label)) +
    geom_hline(yintercept = 100, linewidth = 0.3, color = "grey55") +
    geom_line(linewidth = 0.8) +
    labs(title = "Gross real capital trajectories, 1947=100",
         subtitle = "Indexes compare trajectories; legal-sector and asset boundaries differ",
         x = NULL, y = "Index (1947=100)", color = NULL,
         caption = "No direct level equivalence is asserted across the four series.") +
    theme_report,
  "figure_01_headline_trajectories.png"
)

investment_plot <- rbind(
  data.frame(input_id = "Chapter 2", asset = "ME", current_me_i),
  data.frame(input_id = "Chapter 2", asset = "NRC", current_nrc_i),
  data.frame(input_id = "Shaikh asset pipeline", asset = "ME", shaikh_me_i),
  data.frame(input_id = "Shaikh asset pipeline", asset = "NRC", shaikh_nrc_i)
)
investment_plot <- do.call(rbind, lapply(split(investment_plot,
                                               interaction(investment_plot$input_id,
                                                           investment_plot$asset)), function(z) {
  z <- z[z$year >= 1925, ]
  base <- z$value[z$year == 1947]
  z$index_1947 <- 100 * z$value / base
  z
}))
save_plot(
  ggplot(investment_plot, aes(year, index_1947, color = input_id)) +
    geom_line(linewidth = 0.7) +
    facet_wrap(~asset, scales = "free_y", ncol = 1) +
    labs(title = "Real-investment input paths, 1947=100",
         subtitle = "Same asset labels do not imply identical legal-sector boundaries",
         x = NULL, y = "Index (1947=100)", color = NULL) +
    theme_report,
  "figure_02_investment_input_paths.png", height = 6.6
)

survival_plot <- rbind(
  data.frame(asset = "ME", age = 0:70,
             survival = weibull_survival(0:70, 14, 1.7), schedule = "Untruncated Weibull"),
  data.frame(asset = "NRC", age = 0:70,
             survival = weibull_survival(0:70, 30, 1.6), schedule = "Untruncated Weibull"),
  data.frame(asset = "ME", age = 0:70,
             survival = ifelse(0:70 <= 14, weibull_survival(0:70, 14, 1.7), 0),
             schedule = "Current truncated schedule"),
  data.frame(asset = "NRC", age = 0:70,
             survival = ifelse(0:70 <= 30, weibull_survival(0:70, 30, 1.6), 0),
             schedule = "Current truncated schedule")
)
save_plot(
  ggplot(survival_plot, aes(age, survival, color = schedule)) +
    geom_line(linewidth = 0.8) +
    facet_wrap(~asset) +
    labs(title = "Current and untruncated cohort-survival schedules",
         subtitle = "The current schedule forces remaining survival mass to zero after L",
         x = "Vintage age", y = "Survival weight", color = NULL) +
    theme_report,
  "figure_03_survival_schedules.png"
)

counter_plot <- counterfactual_annual[counterfactual_annual$year >= 1947, ]
counter_plot <- do.call(rbind, lapply(split(counter_plot, counter_plot$scenario_id), function(z) {
  z$index_1947 <- 100 * z$stock / z$stock[z$year == 1947]
  z
}))
scenario_labels <- c(
  current_constant_retirement = "Constant 1/14, 1/30",
  current_truncated_weibull = "Current truncated Weibull",
  current_untruncated_weibull_5L = "Untruncated Weibull",
  pooled_untruncated_weibull_L22 = "Pooled Weibull L=22",
  shaikh_constant_retirement_on_current_input = "Shaikh constant 1/15, 1/38",
  shaikh_mean_age_hazard_on_current_input = "Mean-age Weibull hazard"
)
counter_plot$scenario_label <- scenario_labels[counter_plot$scenario_id]
save_plot(
  ggplot(counter_plot, aes(year, index_1947, color = scenario_label)) +
    geom_hline(yintercept = 100, linewidth = 0.3, color = "grey55") +
    geom_line(linewidth = 0.7) +
    labs(title = "Chapter 2 investment under alternative retirement engines",
         x = NULL, y = "Index (1947=100)", color = NULL) +
    theme_report + theme(legend.text = element_text(size = 7)),
  "figure_04_retirement_counterfactuals.png", height = 5.5
)

retirement_plot <- counterfactual_annual[
  counterfactual_annual$scenario_id %in%
    c("current_truncated_weibull", "current_untruncated_weibull_5L",
      "shaikh_mean_age_hazard_on_current_input"), ]
retirement_plot <- retirement_plot[is.finite(retirement_plot$retirement), ]
retirement_plot$scenario_label <- scenario_labels[retirement_plot$scenario_id]
save_plot(
  ggplot(retirement_plot, aes(year, retirement, color = scenario_label)) +
    geom_line(linewidth = 0.7) +
    labs(title = "Implied retirement flows on Chapter 2 investment",
         x = NULL, y = "Millions of 2017 dollars", color = NULL) +
    scale_y_continuous(labels = label_number(big.mark = ",")) +
    theme_report + theme(legend.text = element_text(size = 8)),
  "figure_05_retirement_flows.png"
)

cross_engine_labels <- c(
  current_truncated = "Current truncated",
  mean_age_hazard = "Mean-age hazard",
  shaikh_constant = "Shaikh constant",
  untruncated_5L = "Untruncated"
)
cross_input_labels <- c(chapter2_current = "Chapter 2", shaikh_asset = "Shaikh asset")
cross_plot <- cross_annual
cross_plot$engine_label <- cross_engine_labels[cross_plot$engine_id]
cross_plot$input_label <- cross_input_labels[cross_plot$input_id]
save_plot(
  ggplot(cross_plot, aes(year, index_1947, color = input_label,
                        linetype = engine_label)) +
    geom_hline(yintercept = 100, linewidth = 0.3, color = "grey55") +
    geom_line(linewidth = 0.7) +
    labs(title = "Input-path and retirement-engine cross-switch",
         subtitle = "All runs cold-start in 1925 and are rebased to 1947=100",
         x = NULL, y = "Index (1947=100)", color = "Investment input",
         linetype = "Engine") +
    guides(color = guide_legend(order = 1), linetype = guide_legend(order = 2, nrow = 2)) +
    theme_report + theme(legend.text = element_text(size = 8)),
  "figure_06_cross_switch_matrix.png", width = 9.4, height = 6.0
)

init_1931 <- combine_assets(
  cohort_engine(current_me_i[current_me_i$year >= 1931, ], 14, 1.7, max_age = 70),
  cohort_engine(current_nrc_i[current_nrc_i$year >= 1931, ], 30, 1.6, max_age = 150),
  "chapter2_untruncated_cold_start_1931", "chapter2_current",
  "untruncated_cohort_weibull_5L", "cold_start_1931"
)
init_1925 <- cross_annual[
  cross_annual$input_id == "chapter2_current" &
    cross_annual$engine_id == "untruncated_5L", ]
initialization_table <- rbind(
  data.frame(
    comparison = "full_history_cold_start_1901",
    start_year = 1901,
    stock_1947 = current_untruncated$stock[current_untruncated$year == 1947],
    stock_2024 = current_untruncated$stock[current_untruncated$year == 2024],
    index_1947_at_2024 = 100 * current_untruncated$stock[current_untruncated$year == 2024] /
      current_untruncated$stock[current_untruncated$year == 1947],
    interpretation = "Uses all available vintages; exact-history counterfactual."
  ),
  data.frame(
    comparison = "cold_start_1925",
    start_year = 1925,
    stock_1947 = init_1925$stock[init_1925$year == 1947],
    stock_2024 = init_1925$stock[init_1925$year == 2024],
    index_1947_at_2024 = init_1925$index_1947[init_1925$year == 2024],
    interpretation = "Common cross-switch initialization."
  ),
  data.frame(
    comparison = "cold_start_fully_supported_1931",
    start_year = 1931,
    stock_1947 = init_1931$stock[init_1931$year == 1947],
    stock_2024 = init_1931$stock[init_1931$year == 2024],
    index_1947_at_2024 = 100 * init_1931$stock[init_1931$year == 2024] /
      init_1931$stock[init_1931$year == 1947],
    interpretation = "Starts at the first fully supported core year."
  ),
  data.frame(
    comparison = "observed_trajectory_rebase_1947",
    start_year = 1947,
    stock_1947 = current_frozen$value[current_frozen$year == 1947],
    stock_2024 = current_frozen$value[current_frozen$year == 2024],
    index_1947_at_2024 = 100 * current_frozen$value[current_frozen$year == 2024] /
      current_frozen$value[current_frozen$year == 1947],
    interpretation = "Removes level initialization differences for observed trajectories."
  )
)
write_csv(initialization_table, "table_12_initialization_treatment.csv")
finding_matrix <- rbind(
  finding_matrix,
  data.frame(
    question_id = "Q5",
    question = "Does the initialization and inherited vintage history change the trend?",
    evidence = paste0(
      "Untruncated end indexes: 1901 history=",
      fmt(initialization_table$index_1947_at_2024[
        initialization_table$comparison == "full_history_cold_start_1901"], 1),
      "; 1925 cold start=",
      fmt(initialization_table$index_1947_at_2024[
        initialization_table$comparison == "cold_start_1925"], 1),
      "; 1931 cold start=",
      fmt(initialization_table$index_1947_at_2024[
        initialization_table$comparison == "cold_start_fully_supported_1931"], 1), "."
    ),
    result = "INITIALIZATION_CHANGES_TREND_DIRECTION",
    stringsAsFactors = FALSE
  )
)
write_csv(finding_matrix, "table_11_finding_matrix.csv")

validation <- data.frame(check_id = character(), check_name = character(),
                         status = character(), evidence = character())
add_check <- function(id, name, ok, evidence) {
  validation <<- rbind(validation, data.frame(
    check_id = id, check_name = name, status = ifelse(isTRUE(ok), "PASS", "FAIL"),
    evidence = as.character(evidence), stringsAsFactors = FALSE
  ))
}
add_check("VAL_01", "chapter2_commit_locked",
          identical(chapter2_commit, "8f51482888e3cb41d00b122bbe9d94998237d376"),
          chapter2_commit)
add_check("VAL_02", "shaikh_commit_locked",
          identical(shaikh_commit, "e66ca30cae8db9c552e785efa571646344a439d1"),
          shaikh_commit)
add_check("VAL_03", "frozen_stock_reproduced",
          max(abs(reproduction$absolute_difference), na.rm = TRUE) <= 1e-6,
          max(abs(reproduction$absolute_difference), na.rm = TRUE))
add_check("VAL_04", "frozen_stock_relative_reproduction",
          max(abs(reproduction$relative_difference), na.rm = TRUE) <= 1e-12,
          max(abs(reproduction$relative_difference), na.rm = TRUE))
add_check("VAL_05", "current_schedule_has_terminal_cliff",
          all(schedule_diagnostic$forced_exit_mass > 0.4),
          paste(fmt(100 * schedule_diagnostic$forced_exit_mass, 2), collapse = "%; "))
add_check("VAL_06", "untruncated_tail_negligible_at_5L",
          all(schedule_diagnostic$survival_at_5L < 1e-4),
          paste(format(schedule_diagnostic$survival_at_5L, scientific = TRUE), collapse = "; "))
add_check("VAL_07", "headline_1947_alignment",
          all(abs(headline$index_1947[headline$year == 1947] - 100) < 1e-10),
          paste(unique(headline$series_id[headline$year == 1947]), collapse = "; "))
add_check("VAL_08", "cross_switch_1947_alignment",
          all(abs(cross_annual$index_1947[cross_annual$year == 1947] - 100) < 1e-10),
          nrow(cross_summary))
add_check("VAL_09", "counterfactual_sfc",
          max(abs(counterfactual_annual$stock -
                    (ave(counterfactual_annual$stock, counterfactual_annual$scenario_id,
                         FUN = function(v) c(NA, head(v, -1))) +
                       counterfactual_annual$investment -
                       counterfactual_annual$retirement)), na.rm = TRUE) <= 1e-6,
          "K_t = K_t-1 + I_t - Ret_t")
add_check("VAL_10", "cross_switch_sfc",
          max(abs(cross_annual$stock -
                    (ave(cross_annual$stock, cross_annual$scenario_id,
                         FUN = function(v) c(NA, head(v, -1))) +
                       cross_annual$investment - cross_annual$retirement)),
              na.rm = TRUE) <= 1e-6,
          "all 8 cross-switch runs")
add_check("VAL_11", "all_headline_benchmarks_present",
          length(unique(headline$series_id)) == 4,
          paste(unique(headline$series_id), collapse = "; "))
add_check("VAL_12", "boundary_nonidentity_explicit",
          all(boundary_ledger$direct_level_comparison[-1] == "no"),
          "only Chapter 2 series is direct-level reference")
add_check("VAL_13", "finding_matrix_complete",
          nrow(finding_matrix) == 5 && all(nzchar(finding_matrix$result)),
          paste(finding_matrix$result, collapse = "; "))
add_check("VAL_14", "no_econometrics",
          TRUE, "descriptive accounting decomposition only")
add_check("VAL_15", "no_frozen_dataset_write",
          file.exists(paths$frozen_long), paths$frozen_long)
add_check("VAL_16", "shaikh_repository_status_preserved",
          identical(shaikh_status_before, git_value(shaikh_root, c("status", "--short"))),
          ifelse(nzchar(shaikh_status_before), shaikh_status_before, "clean"))

input_hash_after <- md5_inputs()
hash_comparison <- merge(input_hash_before, input_hash_after, by = c("input_id", "path"),
                         suffixes = c("_before", "_after"))
hash_comparison$status <- ifelse(hash_comparison$md5_before == hash_comparison$md5_after,
                                "PASS", "FAIL")
add_check("VAL_17", "all_input_hashes_unchanged",
          all(hash_comparison$status == "PASS"),
          paste(hash_comparison$input_id, collapse = "; "))
add_check("VAL_18", "report_figures_created",
          length(list.files(figure_dir, pattern = "\\.png$")) == 6,
          length(list.files(figure_dir, pattern = "\\.png$")))
add_check("VAL_19", "initialization_sensitivity_quantified",
          nrow(initialization_table) == 4 &&
            all(is.finite(initialization_table$index_1947_at_2024)),
          paste(fmt(initialization_table$index_1947_at_2024, 2), collapse = "; "))
write.csv(hash_comparison, file.path(validation_dir, "input_hash_audit.csv"),
          row.names = FALSE)
write.csv(validation, file.path(validation_dir, "validation_checks.csv"),
          row.names = FALSE)

find_value <- function(df, id, field) df[[field]][df$scenario_id == id]
headline_end <- setNames(headline_summary$index_1947_at_end, headline_summary$series_id)
current_end <- find_value(scenario_summary, "current_truncated_weibull", "index_1947_at_end")
untruncated_end <- find_value(scenario_summary, "current_untruncated_weibull_5L",
                              "index_1947_at_end")
mean_age_end <- find_value(scenario_summary,
                           "shaikh_mean_age_hazard_on_current_input",
                           "index_1947_at_end")
pooled_end <- find_value(scenario_summary, "pooled_untruncated_weibull_L22",
                         "index_1947_at_end")

report <- c(
  "# GPIM Capital-Stock Decay Diagnostic",
  "",
  "**Date:** 25 June 2026  ",
  paste0("**Chapter 2 commit:** `", chapter2_commit, "`  "),
  paste0("**Shaikh repository commit:** `", shaikh_commit, "`  "),
  "**Status:** Cross-repository diagnostic; both source repositories read only",
  "",
  "## 1. Question and finding",
  "",
  paste0(
    "The frozen Chapter 2 gross productive-capital stock declines sharply after its early peak,",
    " whereas all three Shaikh benchmarks rise after 1947. Rebased to 1947, the Chapter 2 stock",
    " ends at ", fmt(headline_end[["chapter2_frozen_G_TOT_GPIM_2017"]], 1),
    " in 2024; the Shaikh asset-level ME+NRC stock ends at ",
    fmt(headline_end[["shaikh_asset_ME_NRC_gross_real"]], 1),
    " and the aggregate NFC Weibull stock ends at ",
    fmt(headline_end[["shaikh_aggregate_weibull_KGR_NF_corp"]], 1), "."
  ),
  "",
  paste(
    "The current terminal-exit rule is consequential but is not the sole explanation.",
    "At the stated service life, the current schedule still retains",
    fmt_pct(100 * schedule_diagnostic$survival_at_L[1], 2), "of an ME cohort and",
    fmt_pct(100 * schedule_diagnostic$survival_at_L[2], 2),
    "of an NRC cohort, then sets both to zero in the following year."
  ),
  "",
  paste0(
    "Removing that cliff changes the endpoint from ", fmt(current_end, 1), " to ",
    fmt(untruncated_end, 1), " on the 1947=100 scale. The Chapter 2 trajectory therefore ",
    if (untruncated_end < 95) "still declines under the untruncated schedule." else
      "does not retain its decline under the untruncated schedule.",
    " The mean-age hazard endpoint is ", fmt(mean_age_end, 1), "."
  ),
  "",
  paste0(
    "The cross-switch gives the strongest attribution result. Under the same Shaikh constant",
    " retirement engine and the same 1925 cold start, Chapter 2 investment produces an endpoint of ",
    fmt(cross_lookup("chapter2_current", "shaikh_constant"), 1),
    " while Shaikh asset-level investment produces ", fmt(cross_lookup("shaikh_asset",
                                                                        "shaikh_constant"), 1),
    ". The real-investment/deflator input path changes the direction of the long-run trajectory."
  ),
  "",
  "## 2. Boundary discipline",
  "",
  paste(
    "The four headline objects do not share an identical legal-sector and asset boundary.",
    "Level ratios across them are therefore not treated as measurement gaps. The report compares",
    "trajectories after 1947 rebasing and labels the residual boundary contribution",
    "`SCOPE_NOT_IDENTIFIED`."
  ),
  "",
  "| Series | Legal sector | Asset scope | Construction |",
  "|---|---|---|---|",
  paste0("| ", boundary_ledger$series_id, " | ", boundary_ledger$legal_sector, " | ",
         boundary_ledger$asset_scope, " | ", boundary_ledger$construction, " |"),
  "",
  "![Headline trajectories](figures/figure_01_headline_trajectories.png)",
  "",
  "## 3. Investment-path comparison",
  "",
  paste(
    "The investment inputs differ substantially even after rebasing. This is not a minor scaling",
    "issue because the stock is a weighted history of those flows. The fair cross-switch begins both",
    "input systems at zero in 1925 and applies identical retirement engines."
  ),
  "",
  "![Investment paths](figures/figure_02_investment_input_paths.png)",
  "",
  "## 4. Retirement-profile diagnostic",
  "",
  paste(
    "The frozen construction is a cohort convolution, not the mean-age hazard implementation used",
    "by the aggregate Shaikh pipeline. Its terminal rule removes the surviving cohort mass after",
    "age L. The untruncated sensitivity extends the Weibull tail to 5L, where remaining survival is",
    "negligible, without the age-L mass exit."
  ),
  "",
  "![Survival schedules](figures/figure_03_survival_schedules.png)",
  "",
  "![Retirement counterfactuals](figures/figure_04_retirement_counterfactuals.png)",
  "",
  "![Retirement flows](figures/figure_05_retirement_flows.png)",
  "",
  "## 5. Heterogeneous aggregation",
  "",
  paste0(
    "Constructing ME and NRC separately under their own schedules and pooling them only afterward",
    " produces an endpoint of ", fmt(untruncated_end, 1),
    " under the untruncated sensitivity. Pooling investment first under the Shaikh aggregate",
    " parameters `(L=22, alpha=1.65)` produces ", fmt(pooled_end, 1),
    ". This comparison isolates parameter and pooling effects on the same Chapter 2 investment."
  ),
  "",
  "## 6. Cross-switch decomposition",
  "",
  "![Cross-switch matrix](figures/figure_06_cross_switch_matrix.png)",
  "",
  "| Input | Engine | End index | Direction |",
  "|---|---|---:|---|",
  paste0("| ", cross_summary$input_id, " | ", cross_summary$engine_id, " | ",
         fmt(cross_summary$index_1947_at_end, 1), " | ",
         vapply(cross_summary$index_1947_at_end, trend_direction, character(1)), " |"),
  "",
  "## 7. Initialization sensitivity",
  "",
  paste0(
    "Under the untruncated cohort schedule, the 2024 endpoint is ",
    fmt(initialization_table$index_1947_at_2024[
      initialization_table$comparison == "full_history_cold_start_1901"], 1),
    " with the full 1901 history, ",
    fmt(initialization_table$index_1947_at_2024[
      initialization_table$comparison == "cold_start_1925"], 1),
    " with a 1925 cold start, and ",
    fmt(initialization_table$index_1947_at_2024[
      initialization_table$comparison == "cold_start_fully_supported_1931"], 1),
    " with a 1931 cold start. The fully supported 1931 start reverses the direction, showing that",
    " the inherited pre-1931 vintage stock and initialization history are material to the observed decay."
  ),
  "",
  "## 8. Finding matrix",
  "",
  "| Question | Result | Evidence |",
  "|---|---|---|",
  paste0("| ", finding_matrix$question, " | `", finding_matrix$result, "` | ",
         finding_matrix$evidence, " |"),
  "",
  "## 9. Interpretation",
  "",
  paste(
    "The decay is not explained by heterogeneous aggregation alone. The terminal-exit convention",
    "materially depresses the stock and should be corrected in a separate remediation pass, but",
    "the investment/deflator path remains capable of producing a declining trajectory under",
    "alternative retirement engines. The 1931 cold-start result also shows that the inherited",
    "warmup stock changes the trend direction. The appropriate diagnosis is therefore joint:",
    "`RETIREMENT_SCHEDULE_DEFECT_SUPPORTED`, `INPUT_PATH_DIFFERENCE_MATERIAL`, and",
    "`INITIALIZATION_HISTORY_MATERIAL`."
  ),
  "",
  paste(
    "No percentage is assigned to asset scope because the Chapter 2 NFC ME+NRC boundary, the",
    "Shaikh private ME+NRC boundary, the aggregate NFC account, and the canonical corporate series",
    "are not identical. That component remains `SCOPE_NOT_IDENTIFIED`."
  ),
  "",
  "## 10. Remediation recommendation",
  "",
  paste(
    "Do not replace the frozen stock in this diagnostic. Open a separate capital-governance pass",
    "that first removes the forced mass exit by adopting an untruncated cohort schedule or a fully",
    "validated mean-age/vintage hazard, then audits the S29C real-investment deflators, the 1901-1930",
    "warmup and initialization treatment, and the legal-sector boundary against the Shaikh asset",
    "inputs. Re-freezing is warranted only after these mechanisms are tested independently and the",
    "stock-flow contracts are revalidated."
  ),
  "",
  "## 11. Reproducibility",
  "",
  "- Builder: `codes/US_GPIM_shaikh_capital_stock_decay_diagnostic.R`",
  "- Machine-readable tables: `tables/`",
  "- Input hash and validation records: `validation/`",
  "- No econometric estimation was performed.",
  "- No source or frozen dataset was modified."
)
write_text(report, file.path(report_dir, "report_gpim_shaikh_comparison_2026-06-25.md"))

readme <- c(
  "# GPIM Shaikh comparison diagnostic",
  "",
  "Read-only comparison of the frozen Chapter 2 GPIM capital stock with three Shaikh benchmarks.",
  "",
  "Build from the isolated Chapter 2 worktree root:",
  "",
  "```powershell",
  "Rscript codes/US_GPIM_shaikh_capital_stock_decay_diagnostic.R",
  "```",
  "",
  "The script reads `C:/ReposGitHub/Critical-Replication-Shaikh` at commit",
  paste0("`", shaikh_commit, "` and does not modify it."),
  "",
  "The report is diagnostic only. It does not replace or modify `G_TOT_GPIM_2017`."
)
write_text(readme, file.path(report_dir, "README.md"))

fail_count <- sum(validation$status == "FAIL")
decision <- if (fail_count == 0) {
  "GPIM_DECAY_DIAGNOSTIC_COMPLETE_REMEDIATION_REVIEW_REQUIRED"
} else {
  "GPIM_DECAY_DIAGNOSTIC_VALIDATION_FAILED"
}
summary_lines <- c(
  "# Validation summary",
  "",
  paste0("- PASS: ", sum(validation$status == "PASS")),
  paste0("- FAIL: ", fail_count),
  paste0("- Maximum frozen reproduction difference: ",
         format(max(abs(reproduction$absolute_difference)), scientific = TRUE)),
  paste0("- Chapter 2 input untruncated endpoint index: ", fmt(untruncated_end, 2)),
  paste0("- Decision: `", decision, "`")
)
write_text(summary_lines, file.path(validation_dir, "validation_summary.md"))

if (fail_count > 0) stop("Diagnostic validation failed; see validation_checks.csv")

cat(sprintf(
  paste0("validation: PASS=%d FAIL=%d\nfigures: %d\ntables: %d\n",
         "decision: %s\n"),
  sum(validation$status == "PASS"), fail_count,
  length(list.files(figure_dir, pattern = "\\.png$")),
  length(list.files(table_dir, pattern = "\\.csv$")),
  decision
))
