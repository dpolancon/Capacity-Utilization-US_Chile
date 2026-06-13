#!/usr/bin/env Rscript

# S12D-A2 compares candidate net-value schedules for the diagnostic SFC price
# recovery. It does not lock a baseline schedule or construct final GPIM stocks.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12D-A2 from the downstream repository root.", call. = FALSE)
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
  s12d_a_roles = file.path(
    repo_root, "output", "US", "S12D_A_GPIM_SFC_PRICE_INDEX_TEST",
    "csv", "S12D_A_price_treatment_role_ledger.csv"
  ),
  s12d_a_tests = file.path(
    repo_root, "output", "US", "S12D_A_GPIM_SFC_PRICE_INDEX_TEST",
    "csv", "S12D_A_stock_flow_consistency_tests.csv"
  ),
  s12d_a_validation = file.path(
    repo_root, "output", "US", "S12D_A_GPIM_SFC_PRICE_INDEX_TEST",
    "csv", "S12D_A_gpim_sfc_validation.csv"
  )
)
missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(paste0(
    "Missing S12D-A2 inputs:\n- ",
    paste(unname(missing_inputs), collapse = "\n- ")
  ))
}

capital_inputs <- read_csv(input_paths[["capital_inputs"]])
parameters <- read_csv(input_paths[["parameters"]])
s12d_a_roles <- read_csv(input_paths[["s12d_a_roles"]])
s12d_a_tests <- read_csv(input_paths[["s12d_a_tests"]])
s12d_a_validation <- read_csv(input_paths[["s12d_a_validation"]])

require_condition(
  nrow(s12d_a_validation) > 0L &&
    all(s12d_a_validation$result == "PASS"),
  "S12D-A validation is not fully PASS."
)
require_condition(
  all(c("ME", "NRC") %in% s12d_a_tests$asset_block[
    s12d_a_tests$price_route == "SFC_IMPLICIT" &
      s12d_a_tests$pass_fail == "PASS"
  ]),
  "S12D-A did not recover both conditional SFC implicit price paths."
)
require_condition(
  all(s12d_a_roles$baseline_allowed[
    s12d_a_roles$price_route %in% c(
      "BEA_QADJ_VALIDATION", "OUTPUT_UNIT_TRANSLATION"
    )
  ] == "FALSE"),
  "S12D-A did not preserve the FAAt402/output-price baseline prohibition."
)

output_root <- file.path(
  repo_root, "output", "US", "S12D_A2_NET_VALUE_SCHEDULE_PROTOCOL"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

paths <- c(
  registry = file.path(csv_dir, "S12D_A2_schedule_registry.csv"),
  sensitivity = file.path(
    csv_dir, "S12D_A2_sfc_recovery_sensitivity.csv"
  ),
  decision = file.path(
    csv_dir, "S12D_A2_protocol_decision_ledger.csv"
  ),
  validation = file.path(csv_dir, "S12D_A2_validation_checks.csv"),
  report = file.path(md_dir, "S12D_A2_NET_VALUE_SCHEDULE_PROTOCOL.md")
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

aggregate_cfc_rate <- function(asset) {
  stock <- series_values(paste0("K_NET_CC_NFC_", asset, "_VALIDATION"))
  cfc <- series_values(paste0("CFC_CC_NFC_", asset, "_INPUT"))
  years <- intersect(stock$year, cfc$year)
  ratios <- lookup_value(cfc, years) / lookup_value(stock, years)
  require_condition(
    all(is.finite(ratios)) && all(ratios > 0 & ratios < 1),
    paste0("Invalid aggregate CFC/net-stock diagnostic for ", asset, ".")
  )
  median(ratios)
}

schedule_ids <- c(
  "SURVIVAL_ONLY_REJECTED",
  "LINEAR_AGE_PRICE_CANDIDATE",
  "GEOMETRIC_AGE_PRICE_CANDIDATE",
  "BEA_STYLE_DECLINING_BALANCE_CANDIDATE",
  "HYBRID_SENSITIVITY_ONLY"
)

schedule_definition <- function(asset, schedule_id) {
  life <- parameter_value(paste0("L_", asset))
  alpha <- parameter_value(paste0("alpha_", asset))
  lambda <- life / gamma(1 + 1 / alpha)
  age <- 0:ceiling(life)
  survival <- exp(-((age / lambda)^alpha))
  linear_factor <- pmax(1 - age / life, 0)
  geometric_rate <- 1 / life
  geometric_factor <- (1 - geometric_rate)^age
  cfc_rate <- aggregate_cfc_rate(asset)
  declining_balance_factor <- (1 - cfc_rate)^age
  hybrid_factor <- 0.5 * linear_factor + 0.5 * declining_balance_factor

  age_price_factor <- switch(
    schedule_id,
    SURVIVAL_ONLY_REJECTED = rep(1, length(age)),
    LINEAR_AGE_PRICE_CANDIDATE = linear_factor,
    GEOMETRIC_AGE_PRICE_CANDIDATE = geometric_factor,
    BEA_STYLE_DECLINING_BALANCE_CANDIDATE = declining_balance_factor,
    HYBRID_SENSITIVITY_ONLY = hybrid_factor,
    abort(paste0("Unknown schedule: ", schedule_id))
  )
  net_value_weight <- survival * age_price_factor

  metadata <- switch(
    schedule_id,
    SURVIVAL_ONLY_REJECTED = list(
      formula = "V(j) = S(j)",
      parameter_source = "locked Weibull survival parameters only",
      classification = "REJECTED",
      reason = paste(
        "Physical survival is not a net age-price schedule; equality is",
        "shown only as a prohibited boundary case."
      )
    ),
    LINEAR_AGE_PRICE_CANDIDATE = list(
      formula = "V(j) = S(j) * max(1 - j/L, 0)",
      parameter_source = "S12D-A candidate using locked L and alpha",
      classification = "SENSITIVITY_ONLY",
      reason = paste(
        "Transparent finite-life candidate retained from S12D-A, but no",
        "independent age-price evidence selects straight-line value decay."
      )
    ),
    GEOMETRIC_AGE_PRICE_CANDIDATE = list(
      formula = "V(j) = S(j) * (1 - 1/L)^j",
      parameter_source = "life-implied geometric rate delta = 1/L",
      classification = "REQUIRES_EXTERNAL_JUSTIFICATION",
      reason = paste(
        "The geometric form and delta=1/L are protocol assumptions, not",
        "identified by the locked downstream observations."
      )
    ),
    BEA_STYLE_DECLINING_BALANCE_CANDIDATE = list(
      formula = "V(j) = S(j) * (1 - delta_CFC)^j",
      parameter_source = paste0(
        "delta_CFC = median(CFC_CC/K_NET_CC) = ",
        format(cfc_rate, digits = 8)
      ),
      classification = "REQUIRES_EXTERNAL_JUSTIFICATION",
      reason = paste(
        "Locked current-cost CFC anchors an aggregate declining-balance rate,",
        "but an aggregate CFC/net-stock ratio does not identify a vintage",
        "age-price profile or establish a BEA asset-specific depreciation form."
      )
    ),
    HYBRID_SENSITIVITY_ONLY = list(
      formula = paste(
        "V(j) = S(j) * 0.5 * [max(1-j/L,0) +",
        "(1-delta_CFC)^j]"
      ),
      parameter_source = "equal-weight linear/CFC-rate sensitivity blend",
      classification = "SENSITIVITY_ONLY",
      reason = paste(
        "The blend measures schedule dependence and has no independent",
        "baseline interpretation."
      )
    )
  )

  list(
    weights = data.frame(
      age = age,
      survival_weight = survival,
      age_price_factor = age_price_factor,
      net_value_weight = net_value_weight,
      stringsAsFactors = FALSE
    ),
    life = life,
    alpha = alpha,
    lambda = lambda,
    cfc_rate = cfc_rate,
    formula = metadata$formula,
    parameter_source = metadata$parameter_source,
    classification = metadata$classification,
    reason = metadata$reason
  )
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
  investment_values <- lookup_value(investment, vintages)
  vintage_prices <- price_at(vintages)
  if (any(!is.finite(investment_values)) ||
      any(!is.finite(vintage_prices)) ||
      any(vintage_prices <= 0)) {
    return(NA_real_)
  }
  sum(
    weights$net_value_weight *
      investment_values / (vintage_prices / 100)
  )
}

recover_sfc_price <- function(asset, schedule_id, definition) {
  investment <- series_values(paste0("I_NOM_NFC_", asset, "_DIRECT"))
  stock <- series_values(paste0("K_NET_CC_NFC_", asset, "_VALIDATION"))
  weights <- definition$weights
  maximum_positive_age <- max(
    weights$age[weights$net_value_weight > 0]
  )
  first_complete_year <- min(investment$year) + maximum_positive_age
  stock <- stock[stock$year >= first_complete_year, , drop = FALSE]
  require_condition(
    nrow(stock) > 0L,
    paste0("No complete-vintage anchors for ", asset, " ", schedule_id, ".")
  )

  years <- stock$year
  seed_years <- investment$year[investment$year < min(years)]
  price_map <- setNames(rep(100, length(seed_years)), seed_years)
  raw_price <- rep(NA_real_, length(years))

  for (i in seq_along(years)) {
    year <- years[i]
    current_investment <- lookup_value(investment, year)
    lag_ages <- weights$age[
      weights$age >= 1L & weights$net_value_weight > 0
    ]
    lag_years <- year - lag_ages
    lag_investment <- lookup_value(investment, lag_years)
    lag_prices <- as.numeric(price_map[as.character(lag_years)])
    denominator <- sum(
      weights$net_value_weight[match(lag_ages, weights$age)] *
        lag_investment / (lag_prices / 100)
    )
    candidate <- 100 * (stock$value[i] - current_investment) / denominator
    if (is.finite(candidate) && candidate > 0) {
      raw_price[i] <- candidate
      price_map[as.character(year)] <- candidate
    }
  }

  normalized <- normalize_price(years, raw_price)
  normalized_seed <- 100 * 100 / raw_price[
    match(normalized$base_year, years)
  ]
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
  residual <- reconstructed_current - stock$value

  data.frame(
    asset_block = asset,
    schedule_id = schedule_id,
    year = years,
    price_index_value = normalized$value,
    base_year = normalized$base_year,
    current_cost_stock_anchor = stock$value,
    reconstructed_current_cost_stock = reconstructed_current,
    sfc_residual = residual,
    sfc_residual_pct = safe_pct(residual, stock$value),
    stringsAsFactors = FALSE
  )
}

registry_parts <- list()
recovery_parts <- list()
for (asset in c("ME", "NRC")) {
  for (schedule_id in schedule_ids) {
    definition <- schedule_definition(asset, schedule_id)
    weights <- definition$weights
    registry_parts[[length(registry_parts) + 1L]] <- data.frame(
      schedule_id = schedule_id,
      asset_block = asset,
      object_type = if (
        schedule_id == "SURVIVAL_ONLY_REJECTED"
      ) "survival_boundary_case" else "candidate_net_value_schedule",
      survival_schedule = paste0(
        "S(j)=exp[-(j/lambda)^alpha], lambda=L/Gamma(1+1/alpha)"
      ),
      age_price_schedule = definition$formula,
      productive_efficiency_schedule = "not_constructed_separate_future_object",
      life_parameter = definition$life,
      weibull_shape = definition$alpha,
      weibull_scale = definition$lambda,
      aggregate_cfc_net_stock_rate = definition$cfc_rate,
      parameter_source = definition$parameter_source,
      survival_equals_net_value = if (
        schedule_id == "SURVIVAL_ONLY_REJECTED"
      ) "prohibited_boundary_case" else "FALSE",
      schedule_admissibility = definition$classification,
      baseline_lockable = "FALSE",
      reason = definition$reason,
      notes = "All schedules are diagnostic; no productive-efficiency claim.",
      stringsAsFactors = FALSE
    )
    recovery_parts[[length(recovery_parts) + 1L]] <-
      recover_sfc_price(asset, schedule_id, definition)
  }
}
schedule_registry <- do.call(rbind, registry_parts)
recovery_long <- do.call(rbind, recovery_parts)
rownames(schedule_registry) <- NULL
rownames(recovery_long) <- NULL

linear_reference <- recovery_long[
  recovery_long$schedule_id == "LINEAR_AGE_PRICE_CANDIDATE",
  c("asset_block", "year", "price_index_value"),
  drop = FALSE
]
names(linear_reference)[3L] <- "linear_price_index"

sensitivity_parts <- list()
for (asset in c("ME", "NRC")) {
  for (schedule_id in schedule_ids) {
    rows <- recovery_long[
      recovery_long$asset_block == asset &
        recovery_long$schedule_id == schedule_id,
      ,
      drop = FALSE
    ]
    reference <- linear_reference[
      linear_reference$asset_block == asset,
      ,
      drop = FALSE
    ]
    common_years <- intersect(rows$year, reference$year)
    price <- rows$price_index_value
    annual_change <- 100 * diff(log(price))
    log_gap <- log(
      rows$price_index_value[match(common_years, rows$year)] /
        reference$linear_price_index[match(common_years, reference$year)]
    )
    registry_row <- schedule_registry[
      schedule_registry$asset_block == asset &
        schedule_registry$schedule_id == schedule_id,
      ,
      drop = FALSE
    ]
    abs_residual <- abs(rows$sfc_residual_pct)
    sensitivity_parts[[length(sensitivity_parts) + 1L]] <- data.frame(
      asset_block = asset,
      schedule_id = schedule_id,
      first_complete_vintage_year = min(rows$year),
      last_recovery_year = max(rows$year),
      observations = nrow(rows),
      price_base_year = unique(rows$base_year),
      minimum_price_index = min(price),
      maximum_price_index = max(price),
      mean_annual_log_change_pct = mean(annual_change),
      max_abs_annual_log_change_pct = max(abs(annual_change)),
      mean_abs_log_gap_vs_linear = mean(abs(log_gap)),
      max_abs_log_gap_vs_linear = max(abs(log_gap)),
      mean_abs_sfc_residual_pct = mean(abs_residual),
      max_abs_sfc_residual_pct = max(abs_residual),
      positive_price_path = all(is.finite(price) & price > 0),
      exact_sfc_fit = max(abs_residual) <= 0.1,
      schedule_admissibility = registry_row$schedule_admissibility,
      baseline_lockable = registry_row$baseline_lockable,
      recovery_status = if (
        all(is.finite(price) & price > 0)
      ) "RECOVERED_DIAGNOSTIC_PATH" else "RECOVERY_FAILED",
      interpretation = registry_row$reason,
      stringsAsFactors = FALSE
    )
  }
}
sensitivity <- do.call(rbind, sensitivity_parts)
rownames(sensitivity) <- NULL

baseline_lockable <- any(
  sensitivity$schedule_admissibility == "BASELINE_LOCKABLE" &
    sensitivity$baseline_lockable == "TRUE"
)
final_decision <- if (baseline_lockable) {
  "PROCEED_TO_S12D_B"
} else {
  "REQUIRE_S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR"
}

decision_ledger <- data.frame(
  protocol_item = c(
    "survival_schedule_role",
    "age_price_net_value_schedule_role",
    "productive_efficiency_schedule_role",
    "sfc_implicit_price_role",
    schedule_ids,
    "final_protocol_decision"
  ),
  asset_block = c(
    "ME_NRC", "ME_NRC", "ME_NRC", "ME_NRC",
    rep("ME_NRC", length(schedule_ids)), "ME_NRC"
  ),
  object_type = c(
    "conceptual_distinction", "conceptual_distinction",
    "conceptual_distinction", "conceptual_distinction",
    rep("schedule_decision", length(schedule_ids)), "stage_gate_decision"
  ),
  status = c(
    "LOCKED_PHYSICAL_SURVIVAL_INPUT",
    "UNRESOLVED_NET_VALUE_PROTOCOL",
    "NOT_CONSTRUCTED",
    "CONDITIONAL_DIAGNOSTIC_OUTPUT",
    "REJECTED", "SENSITIVITY_ONLY",
    "REQUIRES_EXTERNAL_JUSTIFICATION",
    "REQUIRES_EXTERNAL_JUSTIFICATION",
    "SENSITIVITY_ONLY",
    final_decision
  ),
  baseline_allowed = c(
    "survival_role_only", "FALSE", "FALSE", "FALSE",
    rep("FALSE", length(schedule_ids)), "FALSE"
  ),
  decision = c(
    "Physical survival is distinct from remaining current-cost value.",
    "No candidate net-value schedule is identified by locked observations.",
    "Productive service contribution remains a separate future object.",
    "SFC price is conditional on the selected net-value schedule.",
    schedule_registry$reason[
      match(schedule_ids, schedule_registry$schedule_id)
    ],
    paste(
      "No schedule is defensibly baseline-lockable for both ME and NRC.",
      "S12D-B remains blocked."
    )
  ),
  evidence = c(
    "Locked Weibull L and alpha parameters.",
    paste(
      "All mechanically admissible schedules recover exact SFC fits while",
      "producing materially different normalized price paths."
    ),
    "No productive-efficiency observations or protocol are used in S12D-A2.",
    "S12D-A and S12D-A2 recursive identities.",
    rep(
      "Schedule registry and ME/NRC SFC recovery sensitivity table.",
      length(schedule_ids)
    ),
    paste(
      "Zero SFC residuals do not discriminate among schedules; aggregate",
      "CFC/net-stock rates do not identify vintage age-price profiles."
    )
  ),
  next_step = c(
    "retain_for_future_GPIM_retirement_protocol",
    "S12D_A3_external_depreciation_age_price_anchor",
    "defer_until_productive_service_protocol",
    "do_not_promote_before_schedule_lock",
    rep(
      "do_not_promote_to_baseline",
      length(schedule_ids)
    ),
    "S12D_A3_external_depreciation_age_price_anchor"
  ),
  notes = c(
    "",
    "FAAt402 and NFC output-price routes remain prohibited as baseline.",
    "",
    "No final GPIM stock is constructed.",
    rep("", length(schedule_ids)),
    "Decision B selected; decision A and C are not selected."
  ),
  stringsAsFactors = FALSE
)

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
  "all five required schedules registered",
  setequal(unique(schedule_registry$schedule_id), schedule_ids),
  paste(unique(schedule_registry$schedule_id), collapse = "; ")
)
add_check(
  "ME and NRC schedule sensitivity produced",
  nrow(sensitivity) == 2L * length(schedule_ids) &&
    setequal(unique(sensitivity$asset_block), c("ME", "NRC")),
  paste0(nrow(sensitivity), " asset-schedule rows")
)
add_check(
  "schedule admissibility values controlled",
  all(schedule_registry$schedule_admissibility %in% c(
    "BASELINE_LOCKABLE", "SENSITIVITY_ONLY", "REJECTED",
    "REQUIRES_EXTERNAL_JUSTIFICATION"
  )),
  paste(
    sort(unique(schedule_registry$schedule_admissibility)),
    collapse = "; "
  )
)
add_check(
  "survival-only not labeled as net-value baseline",
  all(schedule_registry$schedule_admissibility[
    schedule_registry$schedule_id == "SURVIVAL_ONLY_REJECTED"
  ] == "REJECTED") &&
    all(schedule_registry$baseline_lockable[
      schedule_registry$schedule_id == "SURVIVAL_ONLY_REJECTED"
    ] == "FALSE"),
  "prohibited boundary case only"
)
add_check(
  "survival and age-price schedules separated",
  all(nzchar(schedule_registry$survival_schedule)) &&
    all(nzchar(schedule_registry$age_price_schedule)),
  "separate registry fields"
)
add_check(
  "productive-efficiency schedule remains separate",
  all(schedule_registry$productive_efficiency_schedule ==
        "not_constructed_separate_future_object"),
  "not constructed"
)
add_check(
  "FAAt402 not used as baseline",
  !any(grepl("FAAt402", schedule_registry$parameter_source)) &&
    !any(grepl("FAAt402", decision_ledger$evidence)),
  "no schedule parameter or decision evidence uses FAAt402"
)
add_check(
  "NFC output price not used as baseline",
  !any(grepl("P_Y_NFC", schedule_registry$parameter_source)) &&
    !any(grepl("output.price.*baseline_allowed.*TRUE",
               paste(decision_ledger, collapse = " "),
               ignore.case = TRUE)),
  "no output-price schedule parameter"
)
add_check(
  "no final GPIM stocks constructed",
  !any(grepl("^K_G_NFC_.*GPIM", names(sensitivity))) &&
    !any(grepl("FINAL_GPIM", sensitivity$recovery_status)),
  "diagnostic price-path summaries only"
)
add_check("no S20/S21/S22 run", TRUE, "S12D-A2 script only")
add_check(
  "no econometric output created",
  TRUE,
  "schedule protocol and diagnostic sensitivity only"
)
add_check(
  "explicit protocol decision produced",
  final_decision %in% c(
    "PROCEED_TO_S12D_B",
    "REQUIRE_S12D_A3_EXTERNAL_DEPRECIATION_ANCHOR",
    "PARK_GPIM_BASELINE_USE_OUTPUT_UNIT_ROBUSTNESS_ONLY"
  ),
  final_decision
)
add_check(
  "final decision appears once in decision ledger",
  sum(decision_ledger$protocol_item == "final_protocol_decision") == 1L &&
    decision_ledger$status[
      decision_ledger$protocol_item == "final_protocol_decision"
    ] == final_decision,
  final_decision
)
add_check(
  "S12D-B authorization consistent with baseline lockability",
  (final_decision == "PROCEED_TO_S12D_B") == baseline_lockable,
  paste0("baseline_lockable=", baseline_lockable)
)
add_check(
  "protocol remains diagnostic and bounded",
  all(schedule_registry$baseline_lockable == "FALSE") &&
    final_decision != "PROCEED_TO_S12D_B",
  "no baseline schedule locked"
)

require_condition(
  all(validation$result == "PASS"),
  paste0(
    "S12D-A2 validation failed:\n- ",
    paste(validation$validation_rule[validation$result == "FAIL"],
          collapse = "\n- ")
  )
)

write_csv(schedule_registry, paths[["registry"]])
write_csv(sensitivity, paths[["sensitivity"]])
write_csv(decision_ledger, paths[["decision"]])
write_csv(validation, paths[["validation"]])

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

report_lines <- c(
  "# S12D-A2 Net-Value Schedule Protocol",
  "",
  "## Purpose",
  "",
  paste(
    "S12D-A forced S12D-A2 because the net current-cost stock recursion",
    "recovered ME and NRC implicit prices only after imposing a candidate",
    "net age-price/value schedule. The locked observations identify the",
    "conditional price path, not the schedule that conditions it."
  ),
  "",
  "## Object Distinctions",
  "",
  paste(
    "1. The survival schedule measures physical vintage survival and uses",
    "the locked Weibull L and alpha parameters."
  ),
  paste(
    "2. The age-price/net-value schedule measures remaining current-cost",
    "value conditional on survival. It is not identified by survival alone."
  ),
  paste(
    "3. A productive-efficiency schedule would measure productive service",
    "contribution. It is a separate future object and is not constructed here."
  ),
  paste(
    "4. The SFC implicit price index is recovered from direct nominal",
    "investment, a selected net-value schedule, and current-cost net-stock",
    "anchors. Its path is conditional on that schedule."
  ),
  "",
  "## Candidate Schedule Registry",
  "",
  markdown_table(
    schedule_registry[schedule_registry$asset_block == "ME", ],
    c("schedule_id", "age_price_schedule", "parameter_source",
      "schedule_admissibility", "baseline_lockable")
  ),
  "",
  paste(
    "The formulas are applied separately to ME and NRC using their locked",
    "Weibull parameters. The CFC-rate candidate uses each asset's median",
    "locked current-cost CFC/net-stock ratio only as an internal aggregate",
    "diagnostic."
  ),
  "",
  "## SFC Recovery Sensitivity",
  "",
  markdown_table(
    sensitivity,
    c(
      "asset_block", "schedule_id", "first_complete_vintage_year",
      "minimum_price_index", "maximum_price_index",
      "max_abs_log_gap_vs_linear", "max_abs_sfc_residual_pct",
      "schedule_admissibility"
    )
  ),
  "",
  "## Why Zero Residuals Do Not Validate a Schedule",
  "",
  paste(
    "The recursion solves the current price to reproduce the current-cost",
    "stock anchor for any positive candidate value schedule. Exact SFC fit is",
    "therefore an internal identity result. It cannot choose among linear,",
    "geometric, declining-balance, or hybrid age-price assumptions. The",
    "different normalized price ranges and gaps demonstrate this",
    "under-identification."
  ),
  "",
  "## Schedule Decision",
  "",
  paste(
    "No candidate is baseline-lockable. Survival-only is rejected because",
    "physical survival is not remaining value. The linear and hybrid forms",
    "remain sensitivity-only. The geometric and CFC-rate declining-balance",
    "forms require external age-price or depreciation-profile justification.",
    "The aggregate CFC/net-stock ratio does not identify a vintage profile."
  ),
  "",
  "## Stage Gate Decision",
  "",
  paste0("- Decision: `", final_decision, "`."),
  "- S12D-B authorized: no.",
  "- Final GPIM stock construction authorized: no.",
  paste(
    "- Required next evidence: an external, asset-specific depreciation or",
    "age-price anchor that can justify a net-value schedule for both ME and",
    "NRC without using FAAt402 or the NFC output price as a capital-price",
    "baseline."
  ),
  "",
  "## Boundary Confirmation",
  "",
  "- FAAt402 baseline use: no.",
  "- NFC output-price baseline use: no.",
  "- Survival weights treated as net-value weights: no.",
  "- Productive-efficiency schedule constructed: no.",
  "- Final GPIM stocks constructed: no.",
  "- S20/S21/S22 run: no.",
  "- Econometric output created: no.",
  "",
  "## Validation",
  "",
  markdown_table(
    validation,
    c("validation_rule", "result", "observed")
  )
)
writeLines(report_lines, paths[["report"]], useBytes = TRUE)

message("S12D-A2 net-value schedule protocol passed.")
message("Schedule registry rows: ", nrow(schedule_registry))
message("Sensitivity rows: ", nrow(sensitivity))
message("Validation checks: ", nrow(validation))
message("Decision: ", final_decision)
message("S12D-B authorized: no")
message("Final GPIM stocks constructed: no")
message("S20/S21/S22 run: no")
