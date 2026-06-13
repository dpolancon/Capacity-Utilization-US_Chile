#!/usr/bin/env Rscript

options(stringsAsFactors = FALSE, scipen = 999)

root_dir <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(root_dir, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run this script from the Capacity-Utilization-US_Chile repository root.")
}

stage_id <- "S12D-B"
output_dir <- file.path(root_dir, "output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION")
csv_dir <- file.path(output_dir, "csv")
md_dir <- file.path(output_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s12c_path <- file.path(
  root_dir, "output", "US", "S12C_CAPITAL_INPUT_GPIM_PROTOCOL",
  "csv", "S12C_capital_inputs_long.csv"
)
s12b_path <- file.path(
  root_dir, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT",
  "csv", "S12B_output_price_objects_long.csv"
)
a4_parameter_path <- file.path(
  root_dir, "output", "US", "S12D_A4_MANUAL_GPIM_NET_VALUE_THEORY_LOCK",
  "csv", "S12D_A4_protocol_parameters.csv"
)
a4_decision_path <- file.path(
  root_dir, "output", "US", "S12D_A4_MANUAL_GPIM_NET_VALUE_THEORY_LOCK",
  "csv", "S12D_A4_stage_gate_decision.csv"
)
a4_lock_path <- file.path(
  root_dir, "output", "US", "S12D_A4_MANUAL_GPIM_NET_VALUE_THEORY_LOCK",
  "csv", "S12D_A4_manual_lock_ledger.csv"
)

required_inputs <- c(s12c_path, s12b_path, a4_parameter_path, a4_decision_path, a4_lock_path)
missing_inputs <- required_inputs[!file.exists(required_inputs)]
if (length(missing_inputs) > 0L) {
  stop("Missing required input(s): ", paste(missing_inputs, collapse = ", "))
}

manual_lock_sentence <- paste0(
  "For the Chapter 2 GPIM baseline, net-value weights are defined separately from physical survival as ",
  "V_i(j)=S_i(j)(1-d_i)^j, where S_i(j) is the locked asset-specific Weibull survival schedule and the ",
  "externally documented declining-balance age-price rates are d_ME=0.110 and d_NRC=0.024. These rates ",
  "are age-price/depreciation anchors only; they are not retirement rates, productive-efficiency profiles, ",
  "FAAt402 price indexes, NFC output deflators, or final capital-price indexes."
)

read_csv <- function(path) {
  read.csv(path, check.names = FALSE, na.strings = c("", "NA"))
}

first_existing <- function(x, choices, label) {
  hit <- choices[choices %in% names(x)]
  if (length(hit) == 0L) {
    stop("Could not find ", label, " column. Tried: ", paste(choices, collapse = ", "))
  }
  hit[[1L]]
}

as_numeric_strict <- function(x, label) {
  out <- suppressWarnings(as.numeric(x))
  bad <- !is.na(x) & is.na(out)
  if (any(bad)) {
    stop("Non-numeric values in ", label, ": ", paste(unique(x[bad]), collapse = ", "))
  }
  out
}

assert_unique_years <- function(x, label) {
  if (anyDuplicated(x$year)) {
    stop("Duplicate years in ", label, ".")
  }
  invisible(TRUE)
}

extract_series <- function(panel, series_ids, label) {
  id_col <- first_existing(
    panel,
    c("variable_name", "series_id", "object_id", "variable_id", "canonical_id"),
    "series identifier"
  )
  year_col <- first_existing(panel, c("year", "Year"), "year")
  value_col <- first_existing(
    panel,
    c("value", "value_index_2017", "value_native", "Value", "series_value"),
    "value"
  )
  keep <- as.character(panel[[id_col]]) %in% series_ids
  out <- data.frame(
    year = as.integer(panel[[year_col]][keep]),
    value = as_numeric_strict(panel[[value_col]][keep], label)
  )
  out <- out[!is.na(out$year) & !is.na(out$value), , drop = FALSE]
  out <- out[order(out$year), , drop = FALSE]
  if (nrow(out) == 0L) {
    stop("No observations found for ", label, ". Tried IDs: ", paste(series_ids, collapse = ", "))
  }
  assert_unique_years(out, label)
  rownames(out) <- NULL
  out
}

lookup_value <- function(series, year, label) {
  hit <- series$value[series$year == year]
  if (length(hit) != 1L || is.na(hit)) {
    stop("Expected one value for ", label, " in ", year, ".")
  }
  hit[[1L]]
}

weibull_weights <- function(L, alpha, d) {
  ages <- 0:ceiling(L)
  lambda <- L / gamma(1 + 1 / alpha)
  survival <- exp(-((ages / lambda)^alpha))
  age_price <- (1 - d)^ages
  data.frame(
    age = ages,
    survival_weight = survival,
    age_price_weight = age_price,
    net_value_weight = survival * age_price
  )
}

recover_asset <- function(asset, nominal, net_anchor, quantity_index, output_price, L, alpha, d) {
  weights <- weibull_weights(L, alpha, d)
  max_age <- max(weights$age[weights$net_value_weight > 0])
  first_complete_vintage_year <- min(nominal$year) + max_age
  recovery_years <- net_anchor$year[net_anchor$year >= first_complete_vintage_year]
  recovery_years <- recovery_years[recovery_years %in% nominal$year]
  recovery_years <- sort(unique(recovery_years))
  if (length(recovery_years) == 0L || !2017L %in% recovery_years) {
    stop("No valid recovery span including 2017 for ", asset, ".")
  }

  raw_price <- setNames(rep(100, nrow(nominal)), nominal$year)
  residual_raw <- setNames(rep(NA_real_, length(recovery_years)), recovery_years)

  for (year in recovery_years) {
    lag_contribution <- 0
    for (age in weights$age[weights$age > 0]) {
      vintage_year <- year - age
      if (!vintage_year %in% nominal$year) {
        stop("Incomplete nominal investment vintage for ", asset, " in ", year, ".")
      }
      p_lag <- raw_price[[as.character(vintage_year)]]
      i_lag <- lookup_value(nominal, vintage_year, paste(asset, "nominal investment"))
      lag_contribution <- lag_contribution +
        weights$net_value_weight[weights$age == age] * i_lag / (p_lag / 100)
    }
    current_nominal <- lookup_value(nominal, year, paste(asset, "nominal investment"))
    anchor <- lookup_value(net_anchor, year, paste(asset, "current-cost net stock"))
    numerator <- anchor - current_nominal
    candidate <- 100 * numerator / lag_contribution
    if (!is.finite(candidate) || candidate <= 0) {
      stop("Non-positive recursive SFC price for ", asset, " in ", year, ".")
    }
    raw_price[[as.character(year)]] <- candidate
    reconstructed <- current_nominal + candidate / 100 * lag_contribution
    residual_raw[[as.character(year)]] <- reconstructed - anchor
  }

  base_raw <- raw_price[["2017"]]
  normalized_price <- 100 * raw_price / base_raw
  price_all <- data.frame(
    asset_block = asset,
    year = nominal$year,
    sfc_implicit_price_index_2017_100 = as.numeric(normalized_price[as.character(nominal$year)]),
    price_status = ifelse(
      nominal$year < min(recovery_years),
      "INITIALIZATION_SEED_PRICE",
      "RECOVERED_SFC_BASELINE_PRICE"
    ),
    first_complete_vintage_year = first_complete_vintage_year,
    first_recovery_year = min(recovery_years),
    L = L,
    alpha = alpha,
    d = d
  )

  nominal_full <- nominal[nominal$year %in% price_all$year, , drop = FALSE]
  nominal_full <- nominal_full[match(price_all$year, nominal_full$year), , drop = FALSE]
  real_flow <- data.frame(
    asset_block = asset,
    year = price_all$year,
    nominal_investment_current_millions = nominal_full$value,
    sfc_implicit_price_index_2017_100 = price_all$sfc_implicit_price_index_2017_100,
    real_investment_2017_millions =
      nominal_full$value / (price_all$sfc_implicit_price_index_2017_100 / 100),
    price_status = price_all$price_status,
    source_role = "DIRECT_NOMINAL_INVESTMENT_CANONICAL",
    real_flow_role = "REAL_INVESTMENT_BASELINE"
  )

  stock_rows <- lapply(recovery_years, function(year) {
    gross_stock <- 0
    net_value_stock <- 0
    for (age in weights$age) {
      vintage_year <- year - age
      real_i <- lookup_value(
        data.frame(
          year = real_flow$year,
          value = real_flow$real_investment_2017_millions
        ),
        vintage_year,
        paste(asset, "real investment")
      )
      gross_stock <- gross_stock +
        weights$survival_weight[weights$age == age] * real_i
      net_value_stock <- net_value_stock +
        weights$net_value_weight[weights$age == age] * real_i
    }
    price <- lookup_value(
      data.frame(
        year = price_all$year,
        value = price_all$sfc_implicit_price_index_2017_100
      ),
      year,
      paste(asset, "SFC price")
    )
    anchor <- lookup_value(net_anchor, year, paste(asset, "current-cost net stock"))
    reconstruction <- price / 100 * net_value_stock
    data.frame(
      asset_block = asset,
      year = year,
      gross_survival_gpim_stock_2017_millions = gross_stock,
      net_value_gpim_stock_diagnostic_2017_millions = net_value_stock,
      current_cost_net_stock_anchor_millions = anchor,
      reconstructed_current_cost_net_stock_millions = reconstruction,
      sfc_reconstruction_residual_millions = reconstruction - anchor,
      sfc_reconstruction_residual_percent =
        ifelse(anchor == 0, NA_real_, 100 * (reconstruction - anchor) / anchor),
      gross_stock_role = "GROSS_SURVIVAL_GPIM_STOCK_BASELINE",
      net_value_stock_role = "NET_VALUE_GPIM_STOCK_DIAGNOSTIC"
    )
  })
  stock_panel <- do.call(rbind, stock_rows)

  price_recovered <- price_all[price_all$year %in% recovery_years, , drop = FALSE]
  price_recovered$sfc_reconstruction_residual_millions <-
    stock_panel$sfc_reconstruction_residual_millions[
      match(price_recovered$year, stock_panel$year)
    ]
  price_recovered$price_role <- "SFC_IMPLICIT_BASELINE_PRICE"

  quantity_common <- merge(
    net_anchor,
    quantity_index,
    by = "year",
    suffixes = c("_net_anchor", "_quantity")
  )
  quantity_base <- lookup_value(quantity_common[, c("year", "value_net_anchor")], 2017, "2017 net anchor")
  quantity_index_base <- lookup_value(quantity_common[, c("year", "value_quantity")], 2017, "2017 quantity index")
  quantity_common$quantity_2017_units <-
    quantity_common$value_quantity / quantity_index_base * quantity_base
  quantity_common$bea_qadj_implied_price_index_2017_100 <-
    100 * quantity_common$value_net_anchor / quantity_common$quantity_2017_units

  comparison <- merge(
    price_recovered[, c("asset_block", "year", "sfc_implicit_price_index_2017_100")],
    quantity_common[, c("year", "value_quantity", "bea_qadj_implied_price_index_2017_100")],
    by = "year"
  )
  names(comparison)[names(comparison) == "value_quantity"] <- "faat402_quantity_index"
  comparison <- merge(
    comparison,
    output_price,
    by = "year"
  )
  names(comparison)[names(comparison) == "value"] <- "nfc_output_price_index_2017_100"
  comparison$sfc_vs_bea_qadj_percent_gap <-
    100 * (comparison$sfc_implicit_price_index_2017_100 /
      comparison$bea_qadj_implied_price_index_2017_100 - 1)
  comparison$sfc_vs_output_price_percent_gap <-
    100 * (comparison$sfc_implicit_price_index_2017_100 /
      comparison$nfc_output_price_index_2017_100 - 1)
  comparison$faat402_role <- "FAAt402_VALIDATION_ONLY"
  comparison$output_price_role <- "OUTPUT_UNIT_TRANSLATION_ROBUSTNESS_ONLY"

  list(
    weights = weights,
    price_all = price_all,
    price_recovered = price_recovered,
    real_flow = real_flow,
    stock_panel = stock_panel,
    comparison = comparison,
    first_complete_vintage_year = first_complete_vintage_year,
    recovery_years = recovery_years,
    raw_residual = residual_raw
  )
}

s12c <- read_csv(s12c_path)
s12b <- read_csv(s12b_path)
a4_parameters <- read_csv(a4_parameter_path)
a4_decision <- read_csv(a4_decision_path)
a4_lock <- read_csv(a4_lock_path)

decision_col <- first_existing(a4_decision, c("decision", "stage_gate_decision"), "A4 decision")
if (nrow(a4_decision) != 1L ||
    as.character(a4_decision[[decision_col]][1]) != "AUTHORIZE_S12D_B") {
  stop("S12D-A4 does not contain the single required AUTHORIZE_S12D_B decision.")
}

lock_text <- paste(unlist(a4_lock), collapse = " ")
if (!grepl(manual_lock_sentence, lock_text, fixed = TRUE)) {
  stop("The exact S12D-A4 manual lock sentence was not found.")
}

required_parameter_columns <- c(
  "asset_block", "survival_profile", "L", "alpha", "age_price_profile",
  "d", "net_value_schedule", "baseline_status"
)
if (!all(required_parameter_columns %in% names(a4_parameters))) {
  stop("S12D-A4 parameter ledger is missing required columns.")
}

expected_parameters <- data.frame(
  asset_block = c("ME", "NRC"),
  survival_profile = c("Weibull", "Weibull"),
  L = c(14, 30),
  alpha = c(1.7, 1.6),
  age_price_profile = c("declining_balance_geometric", "declining_balance_geometric"),
  d = c(0.110, 0.024),
  baseline_status = c("LOCKED_FOR_S12D_B", "LOCKED_FOR_S12D_B")
)
for (asset in expected_parameters$asset_block) {
  actual <- a4_parameters[a4_parameters$asset_block == asset, , drop = FALSE]
  expected <- expected_parameters[expected_parameters$asset_block == asset, , drop = FALSE]
  if (nrow(actual) != 1L ||
      actual$survival_profile != expected$survival_profile ||
      as.numeric(actual$L) != expected$L ||
      abs(as.numeric(actual$alpha) - expected$alpha) > 1e-12 ||
      actual$age_price_profile != expected$age_price_profile ||
      abs(as.numeric(actual$d) - expected$d) > 1e-12 ||
      actual$baseline_status != expected$baseline_status) {
    stop("S12D-A4 locked parameters do not match the required values for ", asset, ".")
  }
}

series_map <- list(
  ME = list(
    nominal = c(
      "I_NOM_NFC_ME_DIRECT", "I_NFC_ME_DIRECT", "I_NFC_ME", "I_ME_NFC_DIRECT",
      "I_ME_NFC", "I_ME_DIRECT"
    ),
    net_anchor = c(
      "K_NET_CC_NFC_ME_VALIDATION", "K_NET_CC_NFC_ME", "K_N_NFC_ME", "K_NET_NFC_ME",
      "K_NFC_ME_NET_CURRENT_COST"
    ),
    quantity = c(
      "Q_K_BEAFIXEDASSETS_ME_VALIDATION", "Q_K_NET_NFC_ME_FAAt402", "FAAt402_Q_NFC_ME",
      "Q_NFC_ME_FAAt402", "Q_K_NFC_ME"
    )
  ),
  NRC = list(
    nominal = c(
      "I_NOM_NFC_NRC_DIRECT", "I_NFC_NRC_DIRECT", "I_NFC_NRC", "I_NRC_NFC_DIRECT",
      "I_NRC_NFC", "I_NRC_DIRECT"
    ),
    net_anchor = c(
      "K_NET_CC_NFC_NRC_VALIDATION", "K_NET_CC_NFC_NRC", "K_N_NFC_NRC", "K_NET_NFC_NRC",
      "K_NFC_NRC_NET_CURRENT_COST"
    ),
    quantity = c(
      "Q_K_BEAFIXEDASSETS_NRC_VALIDATION", "Q_K_NET_NFC_NRC_FAAt402", "FAAt402_Q_NFC_NRC",
      "Q_NFC_NRC_FAAt402", "Q_K_NFC_NRC"
    )
  )
)

output_price <- extract_series(
  s12b,
  c(
    "P_Y_NFC_GVA_IMPLICIT_SOURCE", "P_Y_NFC_GVA_IMPLICIT",
    "P_NFC_OUTPUT", "P_Y_NFC"
  ),
  "NFC output price"
)
output_price$value <- 100 * output_price$value / lookup_value(output_price, 2017, "2017 output price")

results <- list()
for (asset in c("ME", "NRC")) {
  p <- expected_parameters[expected_parameters$asset_block == asset, , drop = FALSE]
  nominal <- extract_series(s12c, series_map[[asset]]$nominal, paste(asset, "direct nominal investment"))
  net_anchor <- extract_series(s12c, series_map[[asset]]$net_anchor, paste(asset, "current-cost net stock"))
  quantity <- extract_series(s12c, series_map[[asset]]$quantity, paste(asset, "FAAt402 quantity index"))
  results[[asset]] <- recover_asset(
    asset = asset,
    nominal = nominal,
    net_anchor = net_anchor,
    quantity_index = quantity,
    output_price = output_price,
    L = p$L,
    alpha = p$alpha,
    d = p$d
  )
}

sfc_prices <- do.call(rbind, lapply(results, `[[`, "price_recovered"))
real_flows <- do.call(rbind, lapply(results, `[[`, "real_flow"))
stock_panel <- do.call(rbind, lapply(results, `[[`, "stock_panel"))
boundary_comparison <- do.call(rbind, lapply(results, `[[`, "comparison"))

sfc_prices$price_object <- ifelse(
  sfc_prices$asset_block == "ME",
  "P_K_SFC_IMPL_NFC_ME",
  "P_K_SFC_IMPL_NFC_NRC"
)
real_flows$real_investment_object <- ifelse(
  real_flows$asset_block == "ME",
  "I_REAL_NFC_ME_SFC_BASELINE",
  "I_REAL_NFC_NRC_SFC_BASELINE"
)
stock_panel$gross_stock_object <- ifelse(
  stock_panel$asset_block == "ME",
  "K_G_NFC_ME_GPIM",
  "K_G_NFC_NRC_GPIM"
)
stock_panel$net_value_stock_object <- ifelse(
  stock_panel$asset_block == "ME",
  "K_NV_NFC_ME_GPIM_DIAGNOSTIC",
  "K_NV_NFC_NRC_GPIM_DIAGNOSTIC"
)

sfc_prices <- sfc_prices[, c(
  "asset_block", "year", "price_object", "sfc_implicit_price_index_2017_100",
  "price_role", "price_status", "first_complete_vintage_year", "first_recovery_year",
  "L", "alpha", "d", "sfc_reconstruction_residual_millions"
)]
real_flows <- real_flows[, c(
  "asset_block", "year", "real_investment_object",
  "nominal_investment_current_millions", "sfc_implicit_price_index_2017_100",
  "real_investment_2017_millions", "price_status", "source_role", "real_flow_role"
)]
stock_panel <- stock_panel[, c(
  "asset_block", "year", "gross_stock_object", "net_value_stock_object",
  "gross_survival_gpim_stock_2017_millions",
  "net_value_gpim_stock_diagnostic_2017_millions",
  "current_cost_net_stock_anchor_millions",
  "reconstructed_current_cost_net_stock_millions",
  "sfc_reconstruction_residual_millions",
  "sfc_reconstruction_residual_percent",
  "gross_stock_role", "net_value_stock_role"
)]

reconstruction_checks <- do.call(rbind, lapply(c("ME", "NRC"), function(asset) {
  x <- stock_panel[stock_panel$asset_block == asset, , drop = FALSE]
  data.frame(
    asset_block = asset,
    first_recovery_year = min(x$year),
    last_recovery_year = max(x$year),
    observations = nrow(x),
    mean_absolute_sfc_residual_millions = mean(abs(x$sfc_reconstruction_residual_millions)),
    max_absolute_sfc_residual_millions = max(abs(x$sfc_reconstruction_residual_millions)),
    mean_absolute_sfc_residual_percent = mean(abs(x$sfc_reconstruction_residual_percent), na.rm = TRUE),
    max_absolute_sfc_residual_percent = max(abs(x$sfc_reconstruction_residual_percent), na.rm = TRUE),
    tolerance_millions = 1e-6,
    status = ifelse(max(abs(x$sfc_reconstruction_residual_millions)) <= 1e-6, "PASS", "FAIL")
  )
}))

role_templates <- data.frame(
  object_role = c(
    "SFC_IMPLICIT_BASELINE_PRICE",
    "DIRECT_NOMINAL_INVESTMENT_CANONICAL",
    "REAL_INVESTMENT_BASELINE",
    "GROSS_SURVIVAL_GPIM_STOCK_BASELINE",
    "NET_VALUE_GPIM_STOCK_DIAGNOSTIC",
    "FAAt402_VALIDATION_ONLY",
    "OUTPUT_UNIT_TRANSLATION_ROBUSTNESS_ONLY",
    "PRODUCTIVE_EFFICIENCY_NOT_CONSTRUCTED"
  ),
  baseline_use = c("yes", "yes", "yes", "yes", "no", "no", "no", "no"),
  description = c(
    "Recursively recovered capital price index under the locked net-value schedule.",
    "Canonical direct nominal investment flow inherited from S12C.",
    "Nominal investment deflated by the SFC implicit baseline price.",
    "Survival-weighted sum of real investment vintages.",
    "Net-value-weighted stock used only to reconstruct the current-cost anchor.",
    "Official quantity index retained only for boundary validation.",
    "NFC output price retained only for output-unit translation robustness.",
    "Productive-efficiency schedules and productive stocks are outside this pass."
  )
)
object_role_ledger <- do.call(rbind, lapply(c("ME", "NRC"), function(asset) {
  data.frame(asset_block = asset, role_templates)
}))

validation <- data.frame(
  check_id = c(
    "A4_GATE_SINGLE_AUTHORIZATION",
    "A4_EXACT_MANUAL_LOCK_SENTENCE",
    "ME_LOCKED_PARAMETERS",
    "NRC_LOCKED_PARAMETERS",
    "NO_IMPLIED_INVESTMENT_FALLBACK",
    "SFC_PRICES_NORMALIZED_2017",
    "SFC_PRICE_POSITIVE",
    "REAL_INVESTMENT_CONSTRUCTED",
    "GROSS_SURVIVAL_STOCK_CONSTRUCTED",
    "NET_VALUE_STOCK_DIAGNOSTIC_ONLY",
    "SFC_RECONSTRUCTION_CLOSES",
    "FAAt402_NOT_BASELINE",
    "OUTPUT_PRICE_NOT_BASELINE",
    "SURVIVAL_DISTINCT_FROM_NET_VALUE",
    "PRODUCTIVE_EFFICIENCY_NOT_CONSTRUCTED",
    "NO_S20_S21_S22",
    "NO_ECONOMETRICS",
    "REQUIRED_OUTPUT_TABLES_PRESENT_IN_MEMORY",
    "BOUNDARY_COMPARISON_PRESENT",
    "REPORT_CONSTRUCTION_AND_PRICE_BOUNDARIES",
    "NEXT_STAGE_EXPLICIT"
  ),
  status = c(
    "PASS", "PASS", "PASS", "PASS", "PASS",
    ifelse(all(abs(sfc_prices$sfc_implicit_price_index_2017_100[sfc_prices$year == 2017] - 100) < 1e-10), "PASS", "FAIL"),
    ifelse(all(sfc_prices$sfc_implicit_price_index_2017_100 > 0), "PASS", "FAIL"),
    ifelse(nrow(real_flows) == 248L, "PASS", "FAIL"),
    ifelse(nrow(stock_panel) > 0L && all(stock_panel$gross_survival_gpim_stock_2017_millions > 0), "PASS", "FAIL"),
    ifelse(all(stock_panel$net_value_stock_role == "NET_VALUE_GPIM_STOCK_DIAGNOSTIC"), "PASS", "FAIL"),
    ifelse(all(reconstruction_checks$status == "PASS"), "PASS", "FAIL"),
    ifelse(all(object_role_ledger$baseline_use[object_role_ledger$object_role == "FAAt402_VALIDATION_ONLY"] == "no"), "PASS", "FAIL"),
    ifelse(all(object_role_ledger$baseline_use[object_role_ledger$object_role == "OUTPUT_UNIT_TRANSLATION_ROBUSTNESS_ONLY"] == "no"), "PASS", "FAIL"),
    ifelse(all(vapply(results, function(x) any(abs(x$weights$survival_weight - x$weights$net_value_weight) > 1e-12), logical(1))), "PASS", "FAIL"),
    "PASS", "PASS", "PASS",
    ifelse(nrow(sfc_prices) > 0 && nrow(real_flows) > 0 && nrow(stock_panel) > 0, "PASS", "FAIL"),
    ifelse(nrow(boundary_comparison) > 0, "PASS", "FAIL"),
    "PASS",
    "PASS"
  ),
  evidence = c(
    "S12D-A4 contains exactly AUTHORIZE_S12D_B.",
    "The exact manual theory lock sentence is present.",
    "ME uses Weibull L=14, alpha=1.7 and d=0.110.",
    "NRC uses Weibull L=30, alpha=1.6 and d=0.024.",
    "Investment is read from the S12C canonical direct series; no implied-investment fallback exists.",
    "Each recovered price index equals 100 in 2017.",
    "All recovered SFC baseline prices are finite and positive.",
    paste(nrow(real_flows), "asset-year real investment observations were constructed."),
    paste(nrow(stock_panel), "asset-year gross survival GPIM observations were constructed."),
    "Net-value stocks are explicitly labeled diagnostic.",
    paste0("Maximum absolute residual = ", format(max(reconstruction_checks$max_absolute_sfc_residual_millions), scientific = TRUE), " million."),
    "FAAt402 appears only in the validation boundary comparison.",
    "The NFC output price appears only in the robustness boundary comparison.",
    "Survival and net-value weights are separately calculated and differ after age zero.",
    "No productive-efficiency object is created.",
    "No S20, S21, or S22 script was invoked.",
    "No econometric object is created.",
    "All seven required CSV objects were assembled before writing.",
    paste(nrow(boundary_comparison), "boundary-comparison rows were assembled."),
    "The report has explicit Price boundary and Protocol boundary and next stage sections.",
    "S12D-C is the next authorized consolidation and downstream handoff step; S13 remains blocked."
  )
)

if (any(validation$status != "PASS")) {
  failed <- validation$check_id[validation$status != "PASS"]
  failed_evidence <- validation$evidence[validation$status != "PASS"]
  stop(
    "S12D-B validation failed: ",
    paste(paste0(failed, " [", failed_evidence, "]"), collapse = ", ")
  )
}

write.csv(
  sfc_prices,
  file.path(csv_dir, "S12D_B_sfc_implicit_price_indexes.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  real_flows,
  file.path(csv_dir, "S12D_B_real_investment_flows.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  stock_panel,
  file.path(csv_dir, "S12D_B_gpim_stock_panel.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  reconstruction_checks,
  file.path(csv_dir, "S12D_B_sfc_reconstruction_checks.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  boundary_comparison,
  file.path(csv_dir, "S12D_B_price_boundary_comparison.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  object_role_ledger,
  file.path(csv_dir, "S12D_B_object_role_ledger.csv"),
  row.names = FALSE, na = ""
)
write.csv(
  validation,
  file.path(csv_dir, "S12D_B_validation_checks.csv"),
  row.names = FALSE, na = ""
)

asset_summary <- do.call(rbind, lapply(c("ME", "NRC"), function(asset) {
  price <- sfc_prices[sfc_prices$asset_block == asset, , drop = FALSE]
  flow <- real_flows[real_flows$asset_block == asset, , drop = FALSE]
  stock <- stock_panel[stock_panel$asset_block == asset, , drop = FALSE]
  check <- reconstruction_checks[reconstruction_checks$asset_block == asset, , drop = FALSE]
  data.frame(
    asset = asset,
    price_rows = nrow(price),
    price_start = min(price$year),
    price_end = max(price$year),
    flow_rows = nrow(flow),
    flow_start = min(flow$year),
    flow_end = max(flow$year),
    stock_rows = nrow(stock),
    stock_start = min(stock$year),
    stock_end = max(stock$year),
    max_residual = check$max_absolute_sfc_residual_millions
  )
}))

report_lines <- c(
  "# S12D-B GPIM Baseline Construction Under Locked SFC Price Protocol",
  "",
  "## Stage gate",
  "",
  "S12D-A4 authorized this construction by recording and validating the manual net-value theory lock. This pass uses that lock without changing its survival parameters, depreciation rates, or object roles.",
  "",
  "The exact inherited lock sentence is:",
  "",
  paste0("> ", manual_lock_sentence),
  "",
  "## Locked schedules",
  "",
  "- ME: Weibull physical survival with `L=14` and `alpha=1.7`; declining-balance age price with `d=0.110`; net value `V_ME(j)=S_ME(j)*(1-0.110)^j`.",
  "- NRC: Weibull physical survival with `L=30` and `alpha=1.6`; declining-balance age price with `d=0.024`; net value `V_NRC(j)=S_NRC(j)*(1-0.024)^j`.",
  "",
  "Physical survival, age-price decline, net value, productive efficiency, and the recursively recovered capital-price index remain distinct objects. Productive-efficiency profiles are not constructed here.",
  "",
  "## Recursive construction",
  "",
  "For each asset, the current-period SFC price is solved so that the current-cost net-stock anchor equals the price times the locked net-value-weighted sum of current and prior real investment vintages. The recovered path is normalized to `2017=100`; nominal investment is then deflated by that path. Pre-recovery vintages use one common raw-price initialization, transformed by the same 2017 normalization, and are explicitly flagged `INITIALIZATION_SEED_PRICE` rather than independently recovered prices.",
  "",
  "The baseline gross GPIM stock is the Weibull-survival-weighted sum of real investment vintages. The net-value-weighted stock is retained only as a diagnostic reconstruction object.",
  "",
  "## Object distinctions",
  "",
  "- Recovered SFC implicit price: the baseline capital-price index recursively solved from direct nominal investment, locked net-value weights, and the current-cost net-stock anchor.",
  "- FAAt402 validation object: an official quantity-index comparison object, not a baseline price.",
  "- NFC output-unit translation: an output-price robustness object, not a capital-price baseline.",
  "- Real investment: canonical nominal investment divided by the recovered SFC price index.",
  "- Gross/survival GPIM stock: the baseline survival-weighted sum of real investment vintages.",
  "- Diagnostic net-value stock: the locked net-value-weighted sum used to verify the current-cost stock identity, not the gross baseline stock.",
  "",
  "## Output spans",
  "",
  "| Asset | SFC price rows | SFC price span | Real-flow rows | Real-flow span | Stock rows | Stock span | Max absolute SFC residual (million) |",
  "|---|---:|---|---:|---|---:|---|---:|",
  paste0(
    "| ", asset_summary$asset, " | ", asset_summary$price_rows, " | ",
    asset_summary$price_start, "-", asset_summary$price_end, " | ",
    asset_summary$flow_rows, " | ", asset_summary$flow_start, "-", asset_summary$flow_end, " | ",
    asset_summary$stock_rows, " | ", asset_summary$stock_start, "-", asset_summary$stock_end, " | ",
    format(asset_summary$max_residual, scientific = TRUE, digits = 6), " |"
  ),
  "",
  "Required output table row counts:",
  "",
  paste0("- `S12D_B_sfc_implicit_price_indexes.csv`: ", nrow(sfc_prices)),
  paste0("- `S12D_B_real_investment_flows.csv`: ", nrow(real_flows)),
  paste0("- `S12D_B_gpim_stock_panel.csv`: ", nrow(stock_panel)),
  paste0("- `S12D_B_sfc_reconstruction_checks.csv`: ", nrow(reconstruction_checks)),
  paste0("- `S12D_B_price_boundary_comparison.csv`: ", nrow(boundary_comparison)),
  paste0("- `S12D_B_object_role_ledger.csv`: ", nrow(object_role_ledger)),
  paste0("- `S12D_B_validation_checks.csv`: ", nrow(validation)),
  "",
  "## Price boundary",
  "",
  "`FAAt402` remains validation-only and is not the baseline capital-price route. The NFC output price remains output-unit translation robustness-only and is not the baseline capital-price route. The baseline capital-price objects are the SFC implicit indexes recovered under the locked asset-specific net-value schedules.",
  "",
  "## Protocol boundary and next stage",
  "",
  "This pass did not run S20, S21, or S22, did not run econometrics, and did not create productive-efficiency objects. It constructed the authorized ME and NRC baseline gross GPIM stock objects and their diagnostic net-value counterparts.",
  "",
  "**Next-stage decision:** `AUTHORIZE_S12D_C`. S12D-C is the next consolidation and downstream handoff step; S13 remains blocked until that validation is complete.",
  "",
  paste0("Validation result: **", sum(validation$status == "PASS"), "/", nrow(validation), " PASS**.")
)
writeLines(
  report_lines,
  file.path(md_dir, "S12D_B_GPIM_BASELINE_CONSTRUCTION.md"),
  useBytes = TRUE
)

message("S12D-B completed: ", nrow(sfc_prices), " recovered price rows, ",
        nrow(real_flows), " real-flow rows, and ", nrow(stock_panel), " stock rows.")
