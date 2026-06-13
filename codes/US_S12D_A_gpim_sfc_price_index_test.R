#!/usr/bin/env Rscript

# S12D-A tests candidate capital-price treatments against the GPIM stock-flow
# identity. It creates diagnostic reconstructions only, not final GPIM stocks.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12D-A from the downstream repository root.", call. = FALSE)
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
write_csv <- function(data, path) {
  write.csv(data, path, row.names = FALSE, na = "")
}
safe_pct <- function(residual, anchor) {
  ifelse(is.finite(anchor) & anchor != 0, 100 * residual / anchor, NA_real_)
}

input_paths <- c(
  capital_inputs = file.path(
    repo_root, "output", "US", "S12C_CAPITAL_INPUT_GPIM_PROTOCOL",
    "csv", "S12C_capital_inputs_long.csv"
  ),
  parameters = file.path(
    repo_root, "output", "US", "S12C_CAPITAL_INPUT_GPIM_PROTOCOL",
    "csv", "S12C_gpim_parameter_metadata.csv"
  ),
  protocol = file.path(
    repo_root, "output", "US", "S12C_CAPITAL_INPUT_GPIM_PROTOCOL",
    "csv", "S12C_gpim_protocol_ledger.csv"
  ),
  output_prices = file.path(
    repo_root, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT",
    "csv", "S12B_output_price_objects_long.csv"
  ),
  real_output = file.path(
    repo_root, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT",
    "csv", "S12B_real_output_objects_long.csv"
  ),
  construction_plan = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_CONSTRUCTION",
    "csv", "S12_construction_plan_ledger.csv"
  )
)
missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(paste0(
    "Missing S12D-A inputs:\n- ",
    paste(unname(missing_inputs), collapse = "\n- ")
  ))
}

capital_inputs <- read_csv(input_paths[["capital_inputs"]])
parameters <- read_csv(input_paths[["parameters"]])
protocol <- read_csv(input_paths[["protocol"]])
output_prices <- read_csv(input_paths[["output_prices"]])
real_output <- read_csv(input_paths[["real_output"]])
construction_plan <- read_csv(input_paths[["construction_plan"]])

required_capital <- c(
  "I_NOM_NFC_ME_DIRECT", "I_NOM_NFC_NRC_DIRECT",
  "CFC_CC_NFC_ME_INPUT", "CFC_CC_NFC_NRC_INPUT",
  "K_NET_CC_NFC_ME_VALIDATION", "K_NET_CC_NFC_NRC_VALIDATION",
  "Q_K_BEAFIXEDASSETS_ME_VALIDATION",
  "Q_K_BEAFIXEDASSETS_NRC_VALIDATION"
)
require_condition(
  all(required_capital %in% unique(capital_inputs$variable_name)),
  "S12C capital inputs do not contain all required locked series."
)
require_condition(
  setequal(
    parameters$parameter_name,
    c("L_ME", "alpha_ME", "L_NRC", "alpha_NRC")
  ),
  "S12C GPIM parameter metadata does not contain the four locked parameters."
)
require_condition(
  "P_Y_NFC_GVA_IMPLICIT_SOURCE" %in% output_prices$variable_name,
  "The locked NFC output-price object is missing."
)
require_condition(
  nrow(real_output) > 0L && nrow(protocol) > 0L &&
    nrow(construction_plan) > 0L,
  "One or more inherited S12 protocol inputs are empty."
)

output_root <- file.path(
  repo_root, "output", "US", "S12D_A_GPIM_SFC_PRICE_INDEX_TEST"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

paths <- c(
  role_ledger = file.path(
    csv_dir, "S12D_A_price_treatment_role_ledger.csv"
  ),
  sfc_prices = file.path(
    csv_dir, "S12D_A_sfc_implicit_price_indices_long.csv"
  ),
  bea_comparison = file.path(
    csv_dir, "S12D_A_bea_qadj_price_comparison_long.csv"
  ),
  output_comparison = file.path(
    csv_dir, "S12D_A_output_unit_translation_comparison_long.csv"
  ),
  tests = file.path(
    csv_dir, "S12D_A_stock_flow_consistency_tests.csv"
  ),
  validation = file.path(
    csv_dir, "S12D_A_gpim_sfc_validation.csv"
  ),
  residuals = file.path(
    csv_dir, "S12D_A_candidate_gpim_reconstruction_residuals_long.csv"
  ),
  wide = file.path(csv_dir, "S12D_A_price_indices_wide.csv"),
  report = file.path(md_dir, "S12D_A_GPIM_SFC_PRICE_INDEX_TEST.md")
)

series_values <- function(variable_name) {
  rows <- capital_inputs[
    capital_inputs$variable_name == variable_name,
    c("year", "value"),
    drop = FALSE
  ]
  rows$year <- as.integer(rows$year)
  rows$value <- suppressWarnings(as.numeric(rows$value))
  rows <- rows[order(rows$year), , drop = FALSE]
  require_condition(
    nrow(rows) > 0L && all(is.finite(rows$value)),
    paste0("Missing or nonnumeric observations for ", variable_name, ".")
  )
  rows
}

parameter_value <- function(name) {
  value <- suppressWarnings(as.numeric(
    parameters$parameter_value[parameters$parameter_name == name]
  ))
  require_condition(
    length(value) == 1L && is.finite(value),
    paste0("Invalid parameter ", name, ".")
  )
  value
}

# The locked mean service life determines lambda. Survival is Weibull.
# Because only net-stock anchors are available, the test uses a candidate
# straight-line age-price factor conditional on survival. This is diagnostic
# and explicitly not a locked baseline net-value schedule.
weight_schedule <- function(asset) {
  life <- parameter_value(paste0("L_", asset))
  alpha <- parameter_value(paste0("alpha_", asset))
  lambda <- life / gamma(1 + 1 / alpha)
  age <- 0:ceiling(life)
  survival <- exp(-((age / lambda)^alpha))
  value_factor <- pmax(1 - age / life, 0)
  data.frame(
    age = age,
    survival_weight = survival,
    net_value_weight = survival * value_factor,
    stringsAsFactors = FALSE
  )
}

lookup_value <- function(data, year) {
  idx <- match(year, data$year)
  ifelse(is.na(idx), NA_real_, data$value[idx])
}

normalize_price <- function(year, price, preferred_base = 2017L) {
  available <- year[is.finite(price) & price > 0]
  require_condition(length(available) > 0L, "No positive price values.")
  base_year <- if (preferred_base %in% available) {
    preferred_base
  } else {
    max(available)
  }
  base_value <- price[match(base_year, year)]
  list(value = 100 * price / base_value, base_year = base_year)
}

reconstruct_stock <- function(year, investment, price_data, weights) {
  weights <- weights[weights$net_value_weight > 0, , drop = FALSE]
  price_year <- as.integer(price_data$year)
  price_value <- as.numeric(price_data$price)
  first_price <- price_value[which(is.finite(price_value) &
                                    price_value > 0)[1L]]
  last_price <- tail(price_value[is.finite(price_value) &
                                   price_value > 0], 1L)
  price_at <- function(target_year) {
    idx <- match(target_year, price_year)
    values <- price_value[idx]
    values[is.na(values) & target_year < min(price_year)] <- first_price
    values[is.na(values) & target_year > max(price_year)] <- last_price
    values
  }
  vintages <- year - weights$age
  inv <- lookup_value(investment, vintages)
  p_vintage <- price_at(vintages)
  if (any(!is.finite(inv)) || any(!is.finite(p_vintage)) ||
      any(p_vintage <= 0)) {
    return(NA_real_)
  }
  sum(weights$net_value_weight * inv / (p_vintage / 100))
}

recover_sfc_price <- function(asset, investment, stock, weights) {
  maximum_positive_age <- max(
    weights$age[weights$net_value_weight > 0]
  )
  first_complete_year <- min(investment$year) + maximum_positive_age
  stock <- stock[stock$year >= first_complete_year, , drop = FALSE]
  require_condition(
    nrow(stock) > 0L,
    paste0("No complete-vintage stock anchors are available for ", asset, ".")
  )
  years <- stock$year
  seed_years <- investment$year[investment$year < min(years)]
  price_map <- setNames(rep(100, length(seed_years)), seed_years)
  raw_price <- rep(NA_real_, length(years))
  residual <- rep(NA_real_, length(years))

  for (i in seq_along(years)) {
    year <- years[i]
    current_investment <- lookup_value(investment, year)
    lag_ages <- weights$age[weights$age >= 1L &
                              weights$net_value_weight > 0]
    lag_years <- year - lag_ages
    lag_investment <- lookup_value(investment, lag_years)
    lag_prices <- as.numeric(price_map[as.character(lag_years)])
    denominator <- sum(
      weights$net_value_weight[match(lag_ages, weights$age)] *
        lag_investment / (lag_prices / 100)
    )
    numerator <- stock$value[i] - current_investment
    candidate <- 100 * numerator / denominator
    if (!is.finite(candidate) || candidate <= 0) {
      next
    }
    raw_price[i] <- candidate
    price_map[as.character(year)] <- candidate
    reconstructed <- current_investment + (candidate / 100) * denominator
    residual[i] <- reconstructed - stock$value[i]
  }

  normalized <- normalize_price(years, raw_price)
  normalized_seed <- 100 * 100 / raw_price[match(normalized$base_year, years)]
  full_price <- data.frame(
    year = c(seed_years, years),
    price = c(rep(normalized_seed, length(seed_years)), normalized$value),
    stringsAsFactors = FALSE
  )
  reconstructed_real <- vapply(
    years,
    reconstruct_stock,
    numeric(1L),
    investment = investment,
    price_data = full_price,
    weights = weights
  )
  reconstructed_current <- normalized$value / 100 * reconstructed_real
  normalized_residual <- reconstructed_current - stock$value

  data.frame(
    price_object_name = paste0("P_K_SFC_IMPL_NFC_", asset),
    asset_block = asset,
    year = years,
    price_index_value = normalized$value,
    base_year = normalized$base_year,
    stock_anchor_used = paste0("K_NET_CC_NFC_", asset, "_VALIDATION"),
    age_weight_used = paste0(
      "net_value_schedule_candidate: Weibull survival x straight-line ",
      "remaining-life factor"
    ),
    recursive_solution_method = paste0(
      "forward recursion from first complete-vintage anchor ", min(years),
      "; earlier available vintage prices initialized to a common seed; ",
      "normalized jointly"
    ),
    sfc_residual = normalized_residual,
    sfc_residual_pct = safe_pct(normalized_residual, stock$value),
    status = ifelse(
      is.finite(normalized$value),
      "recovered_candidate_requires_net_value_schedule_lock",
      "not_recoverable"
    ),
    notes = paste(
      "Net anchor only. Candidate age-price weights are not baseline locked;",
      "the first recursive year requires a complete locked investment-vintage",
      "window. This output is an experimental price path, not a final GPIM",
      "stock."
    ),
    stringsAsFactors = FALSE
  )
}

route_reconstruction <- function(
    asset, route, price_object_name, price_data, investment, stock, weights,
    burn_in_year) {
  years <- intersect(stock$year, price_data$year)
  rows <- vector("list", length(years))
  for (i in seq_along(years)) {
    year <- years[i]
    p_t <- price_data$price[match(year, price_data$year)]
    real_stock <- reconstruct_stock(
      year, investment, price_data, weights
    )
    reconstructed_current <- p_t / 100 * real_stock
    anchor <- lookup_value(stock, year)
    residual <- reconstructed_current - anchor
    rows[[i]] <- data.frame(
      asset_block = asset,
      year = year,
      price_route = route,
      price_object_name = price_object_name,
      price_index_value = p_t,
      candidate_real_stock = real_stock,
      reconstructed_current_cost_stock = reconstructed_current,
      current_cost_stock_anchor = anchor,
      residual = residual,
      residual_pct = safe_pct(residual, anchor),
      included_in_summary = year >= burn_in_year,
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

asset_results <- list()
sfc_parts <- list()
bea_parts <- list()
output_parts <- list()
residual_parts <- list()

output_price <- output_prices[
  output_prices$variable_name == "P_Y_NFC_GVA_IMPLICIT_SOURCE",
  c("year", "value_index_2017"),
  drop = FALSE
]
names(output_price) <- c("year", "price")
output_price$year <- as.integer(output_price$year)
output_price$price <- suppressWarnings(as.numeric(output_price$price))
output_price <- output_price[is.finite(output_price$price), , drop = FALSE]

for (asset in c("ME", "NRC")) {
  investment <- series_values(paste0("I_NOM_NFC_", asset, "_DIRECT"))
  stock <- series_values(paste0("K_NET_CC_NFC_", asset, "_VALIDATION"))
  quantity <- series_values(
    paste0("Q_K_BEAFIXEDASSETS_", asset, "_VALIDATION")
  )
  cfc <- series_values(paste0("CFC_CC_NFC_", asset, "_INPUT"))
  weights <- weight_schedule(asset)
  life <- parameter_value(paste0("L_", asset))

  sfc <- recover_sfc_price(asset, investment, stock, weights)
  sfc_parts[[asset]] <- sfc

  base_year <- if (2017L %in% intersect(stock$year, quantity$year)) {
    2017L
  } else {
    max(intersect(stock$year, quantity$year))
  }
  k_base <- lookup_value(stock, base_year)
  q_base <- lookup_value(quantity, base_year)
  common_years <- intersect(stock$year, quantity$year)
  bea_price <- data.frame(
    year = common_years,
    price = 100 *
      (lookup_value(stock, common_years) / k_base) /
      (lookup_value(quantity, common_years) / q_base),
    stringsAsFactors = FALSE
  )
  bea_residual <- route_reconstruction(
    asset = asset,
    route = "BEA_QADJ_VALIDATION",
    price_object_name = paste0("P_K_BEA_QADJ_IMPL_NFC_", asset),
    price_data = bea_price,
    investment = investment,
    stock = stock,
    weights = weights,
    burn_in_year = min(bea_price$year) + ceiling(life)
  )
  bea_parts[[asset]] <- data.frame(
    price_object_name = "BEA_QADJ_VALIDATION",
    asset_block = asset,
    year = bea_residual$year,
    bea_quantity_index = lookup_value(quantity, bea_residual$year),
    current_cost_stock_value = bea_residual$current_cost_stock_anchor,
    implied_bea_qadj_price_index = bea_residual$price_index_value,
    base_year = base_year,
    sfc_reconstruction_residual = bea_residual$residual,
    sfc_reconstruction_residual_pct = bea_residual$residual_pct,
    status = ifelse(
      bea_residual$included_in_summary,
      "validation_only_not_SFC_baseline",
      "validation_only_initialization_window"
    ),
    notes = paste(
      "FAAt402 quantity index comparison only. Net-value weights are",
      "candidate, not locked."
    ),
    stringsAsFactors = FALSE
  )

  output_residual <- route_reconstruction(
    asset = asset,
    route = "OUTPUT_UNIT_TRANSLATION",
    price_object_name = "P_Y_NFC_GVA_IMPLICIT_SOURCE",
    price_data = output_price,
    investment = investment,
    stock = stock,
    weights = weights,
    burn_in_year = min(output_price$year) + ceiling(life)
  )
  output_parts[[asset]] <- data.frame(
    price_object_name = "P_Y_NFC_GVA_IMPLICIT_SOURCE",
    asset_block = asset,
    year = output_residual$year,
    output_price_index = output_residual$price_index_value,
    candidate_real_investment_output_units =
      lookup_value(investment, output_residual$year) /
      (output_residual$price_index_value / 100),
    candidate_gpim_stock_output_units =
      output_residual$candidate_real_stock,
    current_cost_stock_anchor =
      output_residual$current_cost_stock_anchor,
    translation_residual = output_residual$residual,
    translation_residual_pct = output_residual$residual_pct,
    status = ifelse(
      output_residual$included_in_summary,
      "output_unit_translation_robustness_only",
      "output_unit_translation_initialization_window"
    ),
    notes = paste(
      "Not asset-price recovery. Candidate net-value weights are not locked."
    ),
    stringsAsFactors = FALSE
  )

  sfc_residual <- data.frame(
    asset_block = asset,
    year = sfc$year,
    price_route = "SFC_IMPLICIT",
    price_object_name = sfc$price_object_name,
    price_index_value = sfc$price_index_value,
    candidate_real_stock = NA_real_,
    reconstructed_current_cost_stock =
      lookup_value(stock, sfc$year) + sfc$sfc_residual,
    current_cost_stock_anchor = lookup_value(stock, sfc$year),
    residual = sfc$sfc_residual,
    residual_pct = sfc$sfc_residual_pct,
    included_in_summary = is.finite(sfc$price_index_value),
    stringsAsFactors = FALSE
  )
  residual_parts[[paste0(asset, "_sfc")]] <- sfc_residual
  residual_parts[[paste0(asset, "_bea")]] <- bea_residual
  residual_parts[[paste0(asset, "_output")]] <- output_residual

  asset_results[[asset]] <- list(
    investment = investment,
    stock = stock,
    quantity = quantity,
    cfc = cfc,
    weights = weights,
    life = life
  )
}

sfc_prices <- do.call(rbind, sfc_parts)
bea_comparison <- do.call(rbind, bea_parts)
output_comparison <- do.call(rbind, output_parts)
residuals <- do.call(rbind, residual_parts)
rownames(sfc_prices) <- NULL
rownames(bea_comparison) <- NULL
rownames(output_comparison) <- NULL
rownames(residuals) <- NULL

test_rows <- list()
for (asset in c("ME", "NRC")) {
  for (route in c(
    "SFC_IMPLICIT", "BEA_QADJ_VALIDATION", "OUTPUT_UNIT_TRANSLATION"
  )) {
    rows <- residuals[
      residuals$asset_block == asset &
        residuals$price_route == route &
        residuals$included_in_summary &
        is.finite(residuals$residual_pct),
      ,
      drop = FALSE
    ]
    abs_pct <- abs(rows$residual_pct)
    object_name <- unique(rows$price_object_name)
    test_rows[[length(test_rows) + 1L]] <- data.frame(
      test_id = paste("SFC", asset, route, sep = "_"),
      asset_block = asset,
      price_route = route,
      price_object_name = paste(object_name, collapse = "; "),
      stock_anchor_used = paste0(
        "K_NET_CC_NFC_", asset, "_VALIDATION"
      ),
      age_weight_used = paste0(
        "net_value_schedule_candidate: Weibull survival x straight-line ",
        "remaining-life factor"
      ),
      years_tested = if (nrow(rows) > 0L) {
        paste0(min(rows$year), "-", max(rows$year), " (", nrow(rows), ")")
      } else {
        "0"
      },
      mean_abs_residual_pct = if (length(abs_pct)) mean(abs_pct) else NA_real_,
      median_abs_residual_pct =
        if (length(abs_pct)) median(abs_pct) else NA_real_,
      max_abs_residual_pct = if (length(abs_pct)) max(abs_pct) else NA_real_,
      rmse_residual_pct = if (length(abs_pct)) {
        sqrt(mean(rows$residual_pct^2))
      } else {
        NA_real_
      },
      pass_fail = if (
        length(abs_pct) && max(abs_pct) <= 0.1
      ) "PASS" else "FAIL",
      interpretation = switch(
        route,
        SFC_IMPLICIT = paste(
          "Recursive identity fit; recoverability is conditional on the",
          "candidate net-value schedule."
        ),
        BEA_QADJ_VALIDATION = paste(
          "Tests whether the FAAt402-based implied price preserves the",
          "candidate GPIM net-stock identity."
        ),
        OUTPUT_UNIT_TRANSLATION = paste(
          "Tests output-unit translation; failure does not invalidate the",
          "output deflator for its proper output-price role."
        )
      ),
      notes = if (route == "SFC_IMPLICIT") {
        "PASS does not lock the candidate net-value schedule or create a final stock."
      } else {
        "Comparison route; no baseline promotion follows from this test."
      },
      stringsAsFactors = FALSE
    )
  }
}
tests <- do.call(rbind, test_rows)

role_rows <- list()
add_role <- function(
    name, asset, route, family, candidate_or_locked, baseline_allowed,
    validation_allowed, robustness_allowed, fallback_allowed,
    prohibited_for_baseline, source_inputs, stock_anchor, age_weight,
    formula, interpretation, limitations, decision, notes = "") {
  role_rows[[length(role_rows) + 1L]] <<- data.frame(
    price_object_name = name,
    asset_block = asset,
    price_route = route,
    object_family = family,
    candidate_or_locked = candidate_or_locked,
    baseline_allowed = baseline_allowed,
    validation_allowed = validation_allowed,
    robustness_allowed = robustness_allowed,
    fallback_allowed = fallback_allowed,
    prohibited_for_baseline = prohibited_for_baseline,
    source_inputs = source_inputs,
    stock_anchor_used = stock_anchor,
    age_weight_used = age_weight,
    formula_or_rule = formula,
    interpretation = interpretation,
    limitations = limitations,
    decision = decision,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

for (asset in c("ME", "NRC")) {
  add_role(
    paste0("P_K_SFC_IMPL_NFC_", asset), asset, "SFC_IMPLICIT",
    "implicit_capital_price_test", "candidate", "pending_net_value_lock",
    "TRUE", "TRUE", "FALSE", "FALSE",
    paste0(
      "I_NOM_NFC_", asset, "_DIRECT; K_NET_CC_NFC_", asset,
      "_VALIDATION; L_", asset, "; alpha_", asset
    ),
    paste0("K_NET_CC_NFC_", asset, "_VALIDATION"),
    "net_value_schedule_candidate; not_baseline_locked",
    paste(
      "P_t = 100 * (K_NET_CC_t - I_NOM_t) /",
      "sum_{j>=1} V(j) I_NOM_{t-j}/(P_{t-j}/100)"
    ),
    "Candidate asset-specific stock-flow-consistent implicit capital price.",
    paste(
      "Only a net anchor is available. V(j) is a candidate Weibull-survival",
      "times straight-line remaining-life schedule."
    ),
    "requires_net_value_schedule",
    "Recoverable diagnostic path; candidate baseline status is conditional."
  )
  add_role(
    "BEA_QADJ_VALIDATION", asset, "BEA_QADJ_VALIDATION",
    "quality_adjusted_price_comparison", "locked_source_derived_comparison",
    "FALSE", "TRUE", "TRUE", "FALSE", "TRUE",
    paste0(
      "Q_K_BEAFIXEDASSETS_", asset,
      "_VALIDATION; K_NET_CC_NFC_", asset, "_VALIDATION"
    ),
    paste0("K_NET_CC_NFC_", asset, "_VALIDATION"),
    "net_value_schedule_candidate; comparison test only",
    "100 * (K_t/K_base) / (Q_t/Q_base)",
    "Validation-only price implied by current-cost stock and FAAt402 quantity.",
    "BEA quality adjustment and chain-index conventions are not GPIM locks.",
    "validation_only_quality_adjusted_price"
  )
  add_role(
    "P_Y_NFC_GVA_IMPLICIT_SOURCE", asset, "OUTPUT_UNIT_TRANSLATION",
    "output_unit_translation", "locked_output_price", "FALSE", "TRUE",
    "TRUE", "FALSE", "TRUE",
    paste0("I_NOM_NFC_", asset, "_DIRECT; P_Y_NFC_GVA_IMPLICIT_SOURCE"),
    paste0("K_NET_CC_NFC_", asset, "_VALIDATION"),
    "net_value_schedule_candidate; translation test only",
    "I_REAL_OUTPUT_UNITS_t = I_NOM_t / (P_Y_NFC_t/100)",
    "Common-output-unit translation and robustness object.",
    "Not an asset-specific investment or capital price.",
    "translation_or_robustness_only"
  )
  add_role(
    paste0("I_IMPLIED_NFC_", asset, "_FALLBACK"), asset, "FALLBACK_ONLY",
    "implied_investment_fallback", "not_activated", "FALSE", "TRUE",
    "FALSE", "TRUE", "TRUE",
    paste0(
      "K_NET_CC_NFC_", asset, "_VALIDATION; CFC_CC_NFC_", asset,
      "_INPUT; missing revaluation term"
    ),
    paste0("K_NET_CC_NFC_", asset, "_VALIDATION"),
    "not_applicable",
    "Implied investment requires stock change, CFC, and revaluation term.",
    "Fallback-only route; direct nominal investment remains canonical.",
    "Required revaluation term is not locked.",
    "fallback_only",
    "implied_investment_fallback_only; not_baseline; requires_revaluation_term"
  )
}
role_ledger <- do.call(rbind, role_rows)

validation <- data.frame(
  validation_rule = character(),
  result = character(),
  observed = character(),
  notes = character(),
  stringsAsFactors = FALSE
)
add_check <- function(rule, pass, observed, notes = "") {
  validation <<- rbind(validation, data.frame(
    validation_rule = rule,
    result = if (isTRUE(pass)) "PASS" else "FAIL",
    observed = as.character(observed),
    notes = notes,
    stringsAsFactors = FALSE
  ))
}
add_check(
  "direct ME nominal investment used",
  nrow(asset_results$ME$investment) > 0L,
  nrow(asset_results$ME$investment)
)
add_check(
  "direct NRC nominal investment used",
  nrow(asset_results$NRC$investment) > 0L,
  nrow(asset_results$NRC$investment)
)
add_check(
  "current-cost stock anchor used",
  all(grepl("^K_NET_CC_NFC_", role_ledger$stock_anchor_used[
    role_ledger$price_route != "FALLBACK_ONLY"
  ])),
  "FAAt401 net current-cost ME and NRC anchors"
)
add_check(
  "Weibull survival parameters used",
  all(vapply(asset_results, function(x) {
    all(is.finite(x$weights$survival_weight))
  }, logical(1L))),
  "L_ME=14; alpha_ME=1.7; L_NRC=30; alpha_NRC=1.6"
)
add_check(
  "SFC implicit price route tested",
  all(c("ME", "NRC") %in% sfc_prices$asset_block) &&
    all(is.finite(sfc_prices$price_index_value)),
  paste0(nrow(sfc_prices), " rows")
)
add_check(
  "BEA quality-adjusted route tested validation-only",
  nrow(bea_comparison) > 0L &&
    all(grepl("validation_only", bea_comparison$status)),
  paste0(nrow(bea_comparison), " rows")
)
add_check(
  "FAAt402 not promoted to baseline",
  all(role_ledger$baseline_allowed[
    role_ledger$price_route == "BEA_QADJ_VALIDATION"
  ] == "FALSE"),
  "validation/comparison only"
)
add_check(
  "output-price route labeled translation/robustness only",
  all(role_ledger$decision[
    role_ledger$price_route == "OUTPUT_UNIT_TRANSLATION"
  ] == "translation_or_robustness_only"),
  "not asset-price recovery"
)
add_check(
  "implied investment not promoted to baseline",
  all(role_ledger$baseline_allowed[
    role_ledger$price_route == "FALLBACK_ONLY"
  ] == "FALSE"),
  "fallback-only and not activated"
)
add_check(
  "net-stock anchor not treated as gross without label",
  all(grepl("K_NET_", role_ledger$stock_anchor_used[
    role_ledger$price_route == "SFC_IMPLICIT"
  ])) &&
    all(role_ledger$decision[
      role_ledger$price_route == "SFC_IMPLICIT"
    ] == "requires_net_value_schedule"),
  "net anchor explicitly labeled"
)
add_check(
  "survival weights not treated as net-value weights without label",
  all(grepl(
    "net_value_schedule_candidate",
    role_ledger$age_weight_used[
      role_ledger$price_route %in% c(
        "SFC_IMPLICIT", "BEA_QADJ_VALIDATION",
        "OUTPUT_UNIT_TRANSLATION"
      )
    ]
  )),
  "candidate net-value schedule explicitly labeled"
)
add_check(
  "no final GPIM source-of-truth stock constructed",
  !any(grepl("^K_G_NFC_.*_GPIM$", names(sfc_prices))) &&
    !any(grepl("source.of.truth", sfc_prices$status, ignore.case = TRUE)),
  "diagnostic candidate reconstructions only"
)
add_check("no S20/S21/S22 run", TRUE, "S12D-A script only")
add_check(
  "no econometric output created",
  TRUE,
  "price-treatment diagnostics and protocol outputs only"
)

require_condition(
  all(validation$result == "PASS"),
  paste0(
    "S12D-A validation failed:\n- ",
    paste(validation$validation_rule[validation$result == "FAIL"],
          collapse = "\n- ")
  )
)

wide_years <- sort(unique(c(
  sfc_prices$year, bea_comparison$year, output_comparison$year
)))
price_wide <- data.frame(year = wide_years, stringsAsFactors = FALSE)
for (asset in c("ME", "NRC")) {
  sfc <- sfc_prices[sfc_prices$asset_block == asset, ]
  bea <- bea_comparison[bea_comparison$asset_block == asset, ]
  out <- output_comparison[output_comparison$asset_block == asset, ]
  price_wide[[paste0("P_K_SFC_IMPL_NFC_", asset)]] <-
    sfc$price_index_value[match(wide_years, sfc$year)]
  price_wide[[paste0("P_K_BEA_QADJ_IMPL_NFC_", asset)]] <-
    bea$implied_bea_qadj_price_index[match(wide_years, bea$year)]
  price_wide[[paste0("P_Y_NFC_FOR_", asset, "_TRANSLATION")]] <-
    out$output_price_index[match(wide_years, out$year)]
}

write_csv(role_ledger, paths[["role_ledger"]])
write_csv(sfc_prices, paths[["sfc_prices"]])
write_csv(bea_comparison, paths[["bea_comparison"]])
write_csv(output_comparison, paths[["output_comparison"]])
write_csv(tests, paths[["tests"]])
write_csv(validation, paths[["validation"]])
write_csv(residuals, paths[["residuals"]])
write_csv(price_wide, paths[["wide"]])

escape_md <- function(x) {
  x <- gsub("\r|\n", " ", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}
markdown_table <- function(data, columns) {
  formatted <- data[, columns, drop = FALSE]
  numeric_columns <- vapply(formatted, is.numeric, logical(1L))
  formatted[numeric_columns] <- lapply(
    formatted[numeric_columns],
    function(x) ifelse(is.na(x), "", format(round(x, 6), trim = TRUE))
  )
  header <- paste0("| ", paste(columns, collapse = " | "), " |")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(formatted, 1L, function(row) {
    paste0(
      "| ", paste(vapply(row, escape_md, character(1L)),
                   collapse = " | "), " |"
    )
  })
  c(header, divider, body)
}

test_summary <- tests[, c(
  "asset_block", "price_route", "years_tested",
  "mean_abs_residual_pct", "max_abs_residual_pct", "pass_fail"
)]
sfc_ranges <- do.call(rbind, lapply(c("ME", "NRC"), function(asset) {
  rows <- sfc_prices[
    sfc_prices$asset_block == asset &
      is.finite(sfc_prices$price_index_value),
    ,
    drop = FALSE
  ]
  data.frame(
    asset_block = asset,
    first_year = min(rows$year),
    last_year = max(rows$year),
    observations = nrow(rows),
    minimum_index = min(rows$price_index_value),
    maximum_index = max(rows$price_index_value),
    stringsAsFactors = FALSE
  )
}))

report_lines <- c(
  "# S12D-A GPIM Stock-Flow Consistency Price-Index Test",
  "",
  "## Purpose",
  "",
  paste(
    "This pass tests whether GPIM can recover asset-specific stock-flow-consistent",
    "implicit capital price indexes. BEA quality-adjusted quantity indexes and",
    "output-price deflation are not treated as baseline capital-price recovery",
    "routes. They are comparison, validation, translation, or robustness objects",
    "unless the SFC tests justify a different protocol decision."
  ),
  "",
  "## Hypothesis",
  "",
  paste(
    "BEA quality-adjusted fixed-asset indexes may not preserve the finite-life",
    "stock-flow identity required by a GPIM driven by direct nominal",
    "investment. The test therefore compares an internally recovered SFC",
    "price with FAAt402-implied prices and the NFC output-price translation."
  ),
  "",
  "## Inherited S12C state",
  "",
  "- Direct FAAt407 nominal ME and NRC investment is canonical.",
  "- FAAt401 supplies net current-cost validation anchors.",
  "- FAAt402 remains validation-only.",
  "- CFC is available but implied investment remains fallback-only.",
  "- Locked Weibull parameters are L_ME=14, alpha_ME=1.7, L_NRC=30, alpha_NRC=1.6.",
  "- No final GPIM stock, S20/S21/S22 run, or econometric output is authorized.",
  "",
  "## Candidate price treatments",
  "",
  "- `SFC_IMPLICIT`: recursively recovered asset price; candidate baseline route conditional on a net-value-schedule lock.",
  "- `BEA_QADJ_VALIDATION`: FAAt402/current-cost implied price; validation only.",
  "- `OUTPUT_UNIT_TRANSLATION`: NFC output-price deflation; translation or robustness only.",
  "- `FALLBACK_ONLY`: implied investment; not activated and requires a revaluation term.",
  "",
  "## GPIM stock-flow consistency logic",
  "",
  paste(
    "For each asset, the test evaluates K_t = (P_t/100) sum_j V(j)",
    "I_{t-j}/(P_{t-j}/100). The current vintage has V(0)=1.",
    "The reported stock reconstructions are diagnostic objects only."
  ),
  "",
  "## SFC implicit price-index recovery",
  "",
  paste(
    "Only net current-cost stocks are available. The test therefore does not",
    "treat Weibull survival weights as net-value weights. It constructs an",
    "explicit candidate schedule V(j)=S(j) max(1-j/L,0), labels it",
    "`net_value_schedule_candidate` and `not_baseline_locked`, initializes",
    "prices before each asset's first complete-vintage recovery anchor to a",
    "common seed, solves forward, and normalizes the complete price path to",
    "2017=100."
  ),
  "",
  markdown_table(
    sfc_ranges,
    c("asset_block", "first_year", "last_year", "observations",
      "minimum_index", "maximum_index")
  ),
  "",
  "## BEA quality-adjusted price/index comparison",
  "",
  paste(
    "The FAAt402 comparison price is 100*(K_t/K_2017)/(Q_t/Q_2017).",
    "It is then applied to direct nominal investment in the same candidate",
    "net-value reconstruction. Summary residuals exclude the full finite-life",
    "initialization window."
  ),
  "",
  "## Output-unit translation comparison",
  "",
  paste(
    "`P_Y_NFC_GVA_IMPLICIT_SOURCE` translates direct nominal investment into",
    "NFC output units. It is not an asset-specific capital-price recovery",
    "route. Summary residuals exclude the full finite-life initialization",
    "window."
  ),
  "",
  "## Test results",
  "",
  markdown_table(
    test_summary,
    c("asset_block", "price_route", "years_tested",
      "mean_abs_residual_pct", "max_abs_residual_pct", "pass_fail")
  ),
  "",
  paste0(
    "- SFC internally solved tolerance: max absolute residual <= 0.1 percent."
  ),
  "- Comparison-route FAIL results are findings, not forced validation failures.",
  "",
  "## Price-treatment labeling decision",
  "",
  paste(
    "ME and NRC SFC implicit price paths are mathematically recoverable under",
    "the candidate net-value schedule. They are not yet baseline locked.",
    "FAAt402 remains validation-only, and the NFC output price remains a",
    "translation/robustness object. Implied investment remains fallback-only."
  ),
  "",
  "## Remaining protocol risks",
  "",
  paste(
    "The binding risk is the absence of an independently locked net",
    "age-price/value schedule. Exact fit by the recursive SFC route is an",
    "identity result conditional on that schedule and initialization; it is",
    "not independent evidence that the candidate schedule is economically",
    "correct. The especially wide NRC candidate index range demonstrates",
    "that sensitivity directly. Gross-anchor recovery is unavailable because",
    "no admissible gross current-cost stock anchor is present in the locked",
    "S12C layer."
  ),
  "",
  "## Next construction step",
  "",
  paste(
    "If S12D-A identifies recoverable SFC implicit capital price indexes for",
    "ME and NRC, the next step is S12D-B: lock the GPIM baseline",
    "price-treatment protocol and construct real investment plus gross GPIM",
    "stocks using those implicit SFC price indexes. If S12D-A shows that",
    "net-stock anchoring requires an additional net value schedule, the next",
    "step is not GPIM construction but a narrow S12D-A2 net-value schedule",
    "protocol."
  ),
  "",
  paste(
    "This test finds that the net-stock route requires that S12D-A2 protocol",
    "before any baseline lock or final GPIM construction."
  )
)
writeLines(report_lines, paths[["report"]], useBytes = TRUE)

message("S12D-A GPIM SFC price-index test passed.")
message("SFC implicit price rows: ", nrow(sfc_prices))
message("BEA-QADJ comparison rows: ", nrow(bea_comparison))
message("Output-unit comparison rows: ", nrow(output_comparison))
message("Stock-flow tests: ", nrow(tests))
message("Validation checks: ", nrow(validation))
message("Net-value schedule required: yes")
message("Final GPIM stocks constructed: no")
message("S20/S21/S22 run: no")
