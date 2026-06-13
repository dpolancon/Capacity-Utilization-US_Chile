#!/usr/bin/env Rscript

# S12C prepares capital source inputs and locks the unresolved GPIM protocol
# boundary. It constructs no GPIM stock, real investment, distribution,
# capacity, utilization, or econometric object.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12C from the downstream repository root.", call. = FALSE)
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

input_paths <- c(
  source_observations = file.path(
    repo_root, "output", "US", "S12A_OBSERVATION_PAYLOAD_IMPORT",
    "csv", "S12A_source_observations_long.csv"
  ),
  availability = file.path(
    repo_root, "output", "US", "S12A_OBSERVATION_PAYLOAD_IMPORT",
    "csv", "S12A_required_series_availability.csv"
  ),
  construction_plan = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_CONSTRUCTION",
    "csv", "S12_construction_plan_ledger.csv"
  ),
  price_registry = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_READINESS",
    "csv", "S12_price_object_construction_registry.csv"
  ),
  s12b_prices = file.path(
    repo_root, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT",
    "csv", "S12B_output_price_objects_long.csv"
  ),
  s12b_real = file.path(
    repo_root, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT",
    "csv", "S12B_real_output_objects_long.csv"
  ),
  handoff_menu = file.path(
    repo_root, "data", "provider_handoffs", "US_BEA_FixedAssets",
    "2026-06-11", "ch2_master_variable_menu.csv"
  )
)
missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  abort(
    paste0(
      "Missing S12C inputs:\n- ",
      paste(unname(missing_inputs), collapse = "\n- ")
    )
  )
}

source_observations <- read_csv(input_paths[["source_observations"]])
availability <- read_csv(input_paths[["availability"]])
construction_plan <- read_csv(input_paths[["construction_plan"]])
price_registry <- read_csv(input_paths[["price_registry"]])
s12b_prices <- read_csv(input_paths[["s12b_prices"]])
s12b_real <- read_csv(input_paths[["s12b_real"]])
handoff_menu <- read_csv(input_paths[["handoff_menu"]])

capital_map <- data.frame(
  variable_name = c(
    "I_NOM_NFC_ME_DIRECT", "I_NOM_NFC_NRC_DIRECT",
    "CFC_CC_NFC_ME_INPUT", "CFC_CC_NFC_NRC_INPUT",
    "K_NET_CC_NFC_ME_VALIDATION", "K_NET_CC_NFC_NRC_VALIDATION",
    "Q_K_BEAFIXEDASSETS_ME_VALIDATION",
    "Q_K_BEAFIXEDASSETS_NRC_VALIDATION"
  ),
  source_variable_id = c(
    "NFC__ME__gross_investment_current_cost",
    "NFC__NRC__gross_investment_current_cost",
    "NFC__ME__cfc_current_cost",
    "NFC__NRC__cfc_current_cost",
    "NFC__ME__net_stock_current_cost",
    "NFC__NRC__net_stock_current_cost",
    "NFC__ME__net_stock_quantity_index",
    "NFC__NRC__net_stock_quantity_index"
  ),
  object_family = c(
    "capital_investment_input", "capital_investment_input",
    "capital_depreciation_input", "capital_depreciation_input",
    "capital_stock_validation_input", "capital_stock_validation_input",
    "capital_quantity_validation_input",
    "capital_quantity_validation_input"
  ),
  source_role = c(
    "canonical_direct_nominal_investment",
    "canonical_direct_nominal_investment",
    "diagnostic_depreciation_input", "diagnostic_depreciation_input",
    "current_cost_stock_validation", "current_cost_stock_validation",
    "quantity_index_validation_only", "quantity_index_validation_only"
  ),
  baseline_or_validation = c(
    "baseline_input", "baseline_input", "diagnostic", "diagnostic",
    "validation", "validation", "validation_only", "validation_only"
  ),
  asset_boundary = c("ME", "NRC", "ME", "NRC", "ME", "NRC", "ME", "NRC"),
  allowed_use = c(
    "canonical nominal ME investment input for future GPIM protocol",
    "canonical nominal NRC investment input for future GPIM protocol",
    "ME depreciation diagnostic and fallback input",
    "NRC depreciation diagnostic and fallback input",
    "validate future ME capital scale and trajectory",
    "validate future NRC capital scale and trajectory",
    "compare future ME real-stock trajectory only",
    "compare future NRC real-stock trajectory only"
  ),
  not_allowed_use = c(
    "do not treat as real investment before price-treatment lock",
    "do not treat as real investment before price-treatment lock",
    "do not construct implied investment without explicit fallback activation",
    "do not construct implied investment without explicit fallback activation",
    "do not promote current-cost net stock to GPIM gross stock",
    "do not promote current-cost net stock to GPIM gross stock",
    "do not use as GPIM stock, price index, revaluation index, or product",
    "do not use as GPIM stock, price index, revaluation index, or product"
  ),
  construction_stage = c(
    "S12C_capital_input_preparation", "S12C_capital_input_preparation",
    "S12C_capital_input_preparation", "S12C_capital_input_preparation",
    "S12C_validation_input_preparation", "S12C_validation_input_preparation",
    "S12C_validation_input_preparation", "S12C_validation_input_preparation"
  ),
  status = c(
    "source_input_ready", "source_input_ready",
    "diagnostic_ready", "diagnostic_ready",
    "validation_ready", "validation_ready",
    "validation_only", "validation_only"
  ),
  stringsAsFactors = FALSE
)

required_targets <- capital_map$variable_name
availability_rows <- availability[
  availability$target_variable %in% required_targets, , drop = FALSE
]
require_condition(
  setequal(availability_rows$target_variable, required_targets) &&
    all(tolower(availability_rows$ready_for_construction) == "true"),
  "One or more required S12C capital inputs are not ready in S12A."
)
plan_rows <- construction_plan[
  construction_plan$target_variable %in% required_targets, , drop = FALSE
]
require_condition(
  setequal(plan_rows$target_variable, required_targets),
  "The S12 construction plan does not contain all capital inputs."
)

capital_parts <- vector("list", nrow(capital_map))
for (i in seq_len(nrow(capital_map))) {
  mapping <- capital_map[i, ]
  rows <- source_observations[
    source_observations$source_variable_id == mapping$source_variable_id,
    ,
    drop = FALSE
  ]
  require_condition(
    nrow(rows) > 0L,
    paste0("Missing source observations for ", mapping$variable_name, ".")
  )
  capital_parts[[i]] <- data.frame(
    variable_name = mapping$variable_name,
    object_family = mapping$object_family,
    source_role = mapping$source_role,
    baseline_or_validation = mapping$baseline_or_validation,
    year = as.integer(rows$year),
    value = suppressWarnings(as.numeric(rows$value)),
    unit = rows$unit,
    frequency = rows$frequency,
    source_system = rows$source_system,
    source_dataset = rows$source_dataset,
    source_table = rows$source_table,
    source_line = rows$source_line,
    source_series_code = rows$source_series_code,
    source_title = rows$source_description,
    sector_boundary = rows$sector_boundary,
    asset_boundary = mapping$asset_boundary,
    asset_block = rows$asset_block,
    price_basis = rows$price_basis,
    stock_flow_type = rows$stock_flow_type,
    allowed_use = mapping$allowed_use,
    not_allowed_use = mapping$not_allowed_use,
    construction_stage = mapping$construction_stage,
    status = mapping$status,
    notes = paste(
      rows$notes,
      "Imported without transformation from the validated S12A source layer.",
      sep = " | "
    ),
    stringsAsFactors = FALSE
  )
}
capital_inputs <- do.call(rbind, capital_parts)
capital_inputs <- capital_inputs[
  order(match(capital_inputs$variable_name, required_targets),
        capital_inputs$year),
  ,
  drop = FALSE
]
rownames(capital_inputs) <- NULL
require_condition(
  all(is.finite(capital_inputs$value)),
  "Capital input layer contains nonnumeric values."
)
require_condition(
  !any(grepl("^K_G_.*_GPIM$", capital_inputs$variable_name)),
  "A GPIM stock was constructed in the capital input layer."
)

parameter_defs <- data.frame(
  parameter_name = c("L_ME", "alpha_ME", "L_NRC", "alpha_NRC"),
  asset_block = c("ME", "ME", "NRC", "NRC"),
  parameter_value = c(14, 1.7, 30, 1.6),
  parameter_unit = c(
    "years", "Weibull shape parameter", "years",
    "Weibull shape parameter"
  ),
  stringsAsFactors = FALSE
)
handoff_params <- handoff_menu[
  handoff_menu$variable_id %in% parameter_defs$parameter_name, , drop = FALSE
]
require_condition(
  setequal(handoff_params$variable_id, parameter_defs$parameter_name),
  "The closed provider handoff is missing GPIM parameter metadata."
)
extract_locked_value <- function(note) {
  match <- regmatches(
    note,
    regexpr("Locked parameter value: [0-9]+(\\.[0-9]+)?", note)
  )
  suppressWarnings(as.numeric(sub(".*: ", "", match)))
}
handoff_values <- vapply(
  parameter_defs$parameter_name,
  function(id) {
    extract_locked_value(
      handoff_params$notes[match(id, handoff_params$variable_id)]
    )
  },
  numeric(1L)
)
require_condition(
  all(abs(handoff_values - parameter_defs$parameter_value) < 1e-12),
  "Requested GPIM parameter values differ from the closed handoff."
)
parameter_metadata <- data.frame(
  parameter_name = parameter_defs$parameter_name,
  asset_block = parameter_defs$asset_block,
  parameter_value = parameter_defs$parameter_value,
  parameter_unit = parameter_defs$parameter_unit,
  source_type = "provider_methodological_metadata",
  source_note = handoff_params$notes[
    match(parameter_defs$parameter_name, handoff_params$variable_id)
  ],
  allowed_use = paste(
    "future GPIM retirement-distribution protocol after price-treatment lock"
  ),
  not_allowed_use = paste(
    "does not authorize GPIM construction or resolve real-investment pricing"
  ),
  status = "methodological_metadata_ready",
  notes = paste(
    "Closed handoff value; lambda may be derived later as",
    "L / Gamma(1 + 1 / alpha)."
  ),
  stringsAsFactors = FALSE
)

ledger_columns <- c(
  "protocol_item", "object_family", "asset_block", "input_required",
  "input_status", "baseline_allowed", "validation_allowed",
  "fallback_allowed", "prohibited", "decision", "construction_rule",
  "reason", "next_stage", "notes"
)
protocol_rows <- list()
add_protocol <- function(
    item, family, asset, input_required, input_status,
    baseline_allowed, validation_allowed, fallback_allowed, prohibited,
    decision, construction_rule, reason,
    next_stage = "S12D_after_price_treatment_lock", notes = "") {
  protocol_rows[[length(protocol_rows) + 1L]] <<- data.frame(
    protocol_item = item,
    object_family = family,
    asset_block = asset,
    input_required = input_required,
    input_status = input_status,
    baseline_allowed = baseline_allowed,
    validation_allowed = validation_allowed,
    fallback_allowed = fallback_allowed,
    prohibited = prohibited,
    decision = decision,
    construction_rule = construction_rule,
    reason = reason,
    next_stage = next_stage,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

add_protocol(
  "direct_nominal_ME_investment", "investment_input", "ME",
  "I_NOM_NFC_ME_DIRECT", "available", "TRUE", "TRUE", "FALSE", "FALSE",
  "canonical_input_confirmed",
  "Use direct FAAt407 ME current-dollar investment as the nominal flow.",
  "Direct BEA investment is available and is the canonical source."
)
add_protocol(
  "direct_nominal_NRC_investment", "investment_input", "NRC",
  "I_NOM_NFC_NRC_DIRECT", "available", "TRUE", "TRUE", "FALSE", "FALSE",
  "canonical_input_confirmed",
  "Use direct FAAt407 NRC current-dollar investment as the nominal flow.",
  "Direct BEA investment is available and is the canonical source."
)
for (asset in c("ME", "NRC")) {
  add_protocol(
    paste0("current_cost_", asset, "_netstock_validation"),
    "stock_validation_input", asset,
    paste0("K_NET_CC_NFC_", asset, "_VALIDATION"),
    "available", "FALSE", "TRUE", "FALSE", "FALSE",
    "validation_only_confirmed",
    "Retain FAAt401 current-cost net stock for scale and trajectory checks.",
    "A current-cost net stock is not a GPIM gross stock."
  )
  add_protocol(
    paste0(asset, "_CFC_input"), "depreciation_input", asset,
    paste0("CFC_CC_NFC_", asset, "_INPUT"),
    "available", "FALSE", "TRUE", "TRUE", "FALSE",
    "diagnostic_and_fallback_input",
    "Retain FAAt404 current-cost CFC for diagnostics and fallback accounting.",
    "CFC does not resolve real-investment pricing."
  )
  add_protocol(
    paste0("FAAt402_", asset, "_validation_only"),
    "quantity_index_validation", asset,
    paste0("Q_K_BEAFIXEDASSETS_", asset, "_VALIDATION"),
    "available", "FALSE", "TRUE", "FALSE", "TRUE",
    "prohibited_for_baseline",
    "Use only to compare a future GPIM real-stock trajectory.",
    paste(
      "FAAt402 is a BEA Fisher quantity-index comparison object, not a",
      "GPIM price index or GPIM product."
    )
  )
}
for (row in seq_len(nrow(parameter_metadata))) {
  p <- parameter_metadata[row, ]
  item <- if (grepl("^L_", p$parameter_name)) {
    paste0(p$asset_block, "_service_life_parameter")
  } else {
    paste0(p$asset_block, "_weibull_shape_parameter")
  }
  add_protocol(
    item, "retirement_parameter", p$asset_block, p$parameter_name,
    "methodological_metadata_ready", "pending_protocol_lock", "TRUE",
    "FALSE", "FALSE", "parameter_confirmed",
    paste0("Use ", p$parameter_name, " = ", p$parameter_value,
           " in the future Weibull retirement schedule."),
    "Parameter is locked, but GPIM construction still requires price treatment."
  )
}

# Main unresolved price-treatment rows.
for (asset in c("ME", "NRC")) {
  add_protocol(
    paste0(asset, "_real_investment_price_treatment"),
    "gpim_price_treatment", asset,
    paste0("I_NOM_NFC_", asset, "_DIRECT plus an admissible price rule"),
    "nominal_input_available_price_rule_unresolved",
    "pending_protocol_lock", "FALSE", "FALSE", "FALSE",
    "protocol_decision_required",
    paste(
      "Do not construct real investment until one admissible treatment is",
      "selected and documented."
    ),
    paste(
      "No same-boundary canonical asset-specific investment price index",
      "has been locked; FAAt402 is prohibited for this role."
    ),
    "protocol_review_before_S12D"
  )
}

# Asset-specific classification of options A-D.
for (asset in c("ME", "NRC")) {
  add_protocol(
    paste0(asset, "_price_option_A_direct_asset_specific_index"),
    "gpim_price_option", asset, "locked asset-specific investment price index",
    "not_available", "FALSE", "FALSE", "FALSE", "FALSE",
    "not_available_or_not_locked",
    "No construction rule is authorized.",
    paste(
      "No same-boundary canonical", asset,
      "investment price index has been locked for the GPIM baseline."
    ),
    "protocol_review_before_S12D"
  )
  add_protocol(
    paste0(asset, "_price_option_B_FAAt402_quantity_index"),
    "gpim_price_option", asset,
    paste0("Q_K_BEAFIXEDASSETS_", asset, "_VALIDATION"),
    "available_validation_only", "FALSE", "TRUE", "FALSE", "TRUE",
    "prohibited_for_baseline",
    "Retain only for ex post trajectory comparison.",
    paste(
      "FAAt402 is a BEA Fisher quantity-index comparison object, not a",
      "GPIM price index or GPIM product."
    ),
    "validation_only"
  )
  add_protocol(
    paste0(asset, "_price_option_C_output_price_deflation"),
    "gpim_price_option", asset, "P_Y_NFC_GVA_IMPLICIT_SOURCE",
    "available", "pending_protocol_lock", "TRUE", "FALSE", "FALSE",
    "candidate_protocol_option",
    paste(
      "Candidate: deflate direct nominal investment by the same-boundary NFC",
      "output-price index after explicit common-output-unit justification."
    ),
    paste(
      "This may provide a common-output-unit normalization but is not an",
      "asset-specific investment price."
    ),
    "protocol_review_before_S12D"
  )
  add_protocol(
    paste0(asset, "_price_option_D_nominal_current_cost_bookkeeping"),
    "gpim_price_option", asset,
    paste0("I_NOM_NFC_", asset, "_DIRECT and current-cost validation inputs"),
    "available", "pending_protocol_lock", "TRUE", "FALSE", "FALSE",
    "candidate_protocol_option",
    paste(
      "Candidate: preserve nominal/current-cost bookkeeping without claiming",
      "a real productive-capacity stock."
    ),
    paste(
      "Nominal consistency does not by itself yield a real productive-capacity",
      "capital stock."
    ),
    "protocol_review_before_S12D"
  )
}
for (asset in c("ME", "NRC")) {
  add_protocol(
    paste0(asset, "_implied_investment_fallback"),
    "investment_fallback", asset,
    paste0("current-cost net stock, CFC, and missing ", asset,
           " revaluation term"),
    "revaluation_index_unavailable", "FALSE", "TRUE", "TRUE", "FALSE",
    "fallback_only",
    "Do not activate unless the revaluation term is valid and fallback use is explicitly approved.",
    paste(
      "Direct FAAt407 nominal investment is canonical; implied investment",
      "requires a revaluation term and remains fallback/validation only."
    ),
    "fallback_review_only"
  )
}
for (target in c(
  "K_G_NFC_ME_GPIM", "K_G_NFC_NRC_GPIM", "K_G_NFC_KCAP_GPIM"
)) {
  asset <- if (grepl("_ME_", target)) "ME" else if (
    grepl("_NRC_", target)
  ) "NRC" else "KCAP"
  add_protocol(
    paste0(target, "_future_target"), "future_gpim_target", asset,
    if (asset == "KCAP") {
      "K_G_NFC_ME_GPIM and K_G_NFC_NRC_GPIM"
    } else {
      paste0(
        "direct nominal ", asset,
        " investment, parameters, initialization, and locked price treatment"
      )
    },
    "blocked_pending_price_treatment", "pending_protocol_lock", "TRUE",
    "FALSE", "FALSE", "future_target_not_constructed",
    if (asset == "KCAP") {
      "Future identity: K_G_NFC_ME_GPIM + K_G_NFC_NRC_GPIM on a common real basis."
    } else {
      "Future Weibull GPIM recursion after the full protocol is locked."
    },
    "S12C does not construct this object.",
    "S12D_after_price_treatment_lock"
  )
}

protocol_ledger <- do.call(rbind, protocol_rows)
protocol_ledger <- protocol_ledger[, ledger_columns, drop = FALSE]
rownames(protocol_ledger) <- NULL

required_protocol_items <- c(
  "direct_nominal_ME_investment", "direct_nominal_NRC_investment",
  "current_cost_ME_netstock_validation",
  "current_cost_NRC_netstock_validation", "ME_CFC_input", "NRC_CFC_input",
  "FAAt402_ME_validation_only", "FAAt402_NRC_validation_only",
  "ME_service_life_parameter", "NRC_service_life_parameter",
  "ME_weibull_shape_parameter", "NRC_weibull_shape_parameter",
  "ME_real_investment_price_treatment",
  "NRC_real_investment_price_treatment",
  "ME_implied_investment_fallback", "NRC_implied_investment_fallback",
  "K_G_NFC_ME_GPIM_future_target", "K_G_NFC_NRC_GPIM_future_target",
  "K_G_NFC_KCAP_GPIM_future_target"
)
require_condition(
  all(required_protocol_items %in% protocol_ledger$protocol_item),
  "The S12C protocol ledger is missing required items."
)

output_root <- file.path(
  repo_root, "output", "US", "S12C_CAPITAL_INPUT_GPIM_PROTOCOL"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

capital_path <- file.path(csv_dir, "S12C_capital_inputs_long.csv")
parameter_path <- file.path(csv_dir, "S12C_gpim_parameter_metadata.csv")
protocol_path <- file.path(csv_dir, "S12C_gpim_protocol_ledger.csv")
validation_path <- file.path(csv_dir, "S12C_capital_input_validation.csv")
report_path <- file.path(md_dir, "S12C_CAPITAL_INPUT_GPIM_PROTOCOL.md")

write.csv(capital_inputs, capital_path, row.names = FALSE, na = "")
write.csv(parameter_metadata, parameter_path, row.names = FALSE, na = "")
write.csv(protocol_ledger, protocol_path, row.names = FALSE, na = "")

validation <- data.frame(
  validation_rule = character(),
  result = character(),
  observed = character(),
  notes = character(),
  stringsAsFactors = FALSE
)
add_check <- function(rule, pass, observed, notes = "") {
  validation <<- rbind(
    validation,
    data.frame(
      validation_rule = rule,
      result = if (isTRUE(pass)) "PASS" else "FAIL",
      observed = as.character(observed),
      notes = notes,
      stringsAsFactors = FALSE
    )
  )
}
present <- function(id) {
  rows <- capital_inputs[capital_inputs$variable_name == id, , drop = FALSE]
  nrow(rows) > 0L && all(is.finite(rows$value))
}
add_check(
  "direct ME nominal investment input present",
  present("I_NOM_NFC_ME_DIRECT"),
  sum(capital_inputs$variable_name == "I_NOM_NFC_ME_DIRECT")
)
add_check(
  "direct NRC nominal investment input present",
  present("I_NOM_NFC_NRC_DIRECT"),
  sum(capital_inputs$variable_name == "I_NOM_NFC_NRC_DIRECT")
)
add_check(
  "ME current-cost net-stock validation input present",
  present("K_NET_CC_NFC_ME_VALIDATION"),
  sum(capital_inputs$variable_name == "K_NET_CC_NFC_ME_VALIDATION")
)
add_check(
  "NRC current-cost net-stock validation input present",
  present("K_NET_CC_NFC_NRC_VALIDATION"),
  sum(capital_inputs$variable_name == "K_NET_CC_NFC_NRC_VALIDATION")
)
add_check(
  "ME CFC/depreciation input present",
  present("CFC_CC_NFC_ME_INPUT"),
  sum(capital_inputs$variable_name == "CFC_CC_NFC_ME_INPUT")
)
add_check(
  "NRC CFC/depreciation input present",
  present("CFC_CC_NFC_NRC_INPUT"),
  sum(capital_inputs$variable_name == "CFC_CC_NFC_NRC_INPUT")
)
for (asset in c("ME", "NRC")) {
  id <- paste0("Q_K_BEAFIXEDASSETS_", asset, "_VALIDATION")
  rows <- capital_inputs[capital_inputs$variable_name == id, , drop = FALSE]
  add_check(
    paste0("FAAt402 ", asset,
           " observations retained only as validation/comparison"),
    nrow(rows) > 0L &&
      all(rows$baseline_or_validation == "validation_only") &&
      all(grepl("do not use as GPIM", rows$not_allowed_use)),
    paste0(nrow(rows), " validation-only rows")
  )
}
add_check(
  "GPIM parameters present",
  setequal(parameter_metadata$parameter_name, parameter_defs$parameter_name) &&
    all(parameter_metadata$status == "methodological_metadata_ready"),
  paste(parameter_metadata$parameter_name, collapse = "; ")
)
add_check(
  "no GPIM stock constructed",
  !any(grepl("^K_G_.*_GPIM$", capital_inputs$variable_name)),
  "capital source inputs only"
)
add_check(
  "no FAAt402 baseline use",
  !any(
    capital_inputs$source_table == "FAAt402" &
      capital_inputs$baseline_or_validation == "baseline_input"
  ),
  "FAAt402 appears only in validation_only rows"
)
add_check(
  "no implied investment baseline use",
  !any(grepl("implied", capital_inputs$variable_name, ignore.case = TRUE)) &&
    all(protocol_ledger$baseline_allowed[
      grepl("implied_investment", protocol_ledger$protocol_item)
    ] == "FALSE"),
  "fallback ledger only; no implied observation series"
)
add_check(
  "no revaluation-index fallback activated",
  all(protocol_ledger$input_status[
    grepl("implied_investment", protocol_ledger$protocol_item)
  ] == "revaluation_index_unavailable"),
  "ME/NRC revaluation terms remain unavailable"
)
add_check(
  "capital-price treatment remains pending",
  all(protocol_ledger$decision[
    grepl("real_investment_price_treatment",
          protocol_ledger$protocol_item)
  ] == "protocol_decision_required"),
  "S12D remains blocked pending protocol lock"
)
add_check(
  "no S20/S21/S22 run",
  TRUE,
  "S12C script only"
)
add_check(
  "no econometric outputs created",
  TRUE,
  "capital inputs and protocol metadata only"
)
write.csv(validation, validation_path, row.names = FALSE, na = "")
require_condition(
  all(validation$result == "PASS"),
  paste0(
    "S12C validation failed:\n- ",
    paste(validation$validation_rule[validation$result == "FAIL"],
          collapse = "\n- ")
  )
)

escape_md <- function(x) {
  x <- gsub("\r|\n", " ", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}
markdown_table <- function(data, columns) {
  header <- paste0("| ", paste(columns, collapse = " | "), " |")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(data[, columns, drop = FALSE], 1L, function(row) {
    paste0(
      "| ", paste(vapply(row, escape_md, character(1L)),
                   collapse = " | "), " |"
    )
  })
  c(header, divider, body)
}

input_summary <- do.call(
  rbind,
  lapply(required_targets, function(id) {
    rows <- capital_inputs[capital_inputs$variable_name == id, , drop = FALSE]
    data.frame(
      variable_name = id,
      role = rows$baseline_or_validation[1L],
      source_table = rows$source_table[1L],
      start_year = min(rows$year),
      end_year = max(rows$year),
      observations = nrow(rows),
      stringsAsFactors = FALSE
    )
  })
)
price_options <- protocol_ledger[
  protocol_ledger$object_family == "gpim_price_option",
  c(
    "protocol_item", "asset_block", "baseline_allowed", "decision",
    "reason"
  ),
  drop = FALSE
]

report_lines <- c(
  "# S12C Capital Input and GPIM Protocol",
  "",
  "## Purpose",
  "",
  paste(
    "S12C prepares the locked NFC ME/NRC capital source observations and",
    "records the GPIM protocol boundary. It does not construct real",
    "investment or any GPIM stock."
  ),
  "",
  "## Inherited locks",
  "",
  "- Direct FAAt407 nominal ME/NRC investment is canonical.",
  "- FAAt402 is comparison/validation-only.",
  "- Implied investment is fallback-only and requires a valid revaluation term.",
  "- GPIM stocks remain blocked pending a real-investment price-treatment lock.",
  "- No S20/S21/S22, adjusted distribution, or econometric code is run.",
  "",
  "## Capital inputs prepared",
  "",
  markdown_table(
    input_summary,
    c("variable_name", "role", "source_table", "start_year",
      "end_year", "observations")
  ),
  "",
  paste0("- Capital input observation rows: ", nrow(capital_inputs)),
  "",
  "## GPIM parameters",
  "",
  markdown_table(
    parameter_metadata,
    c("parameter_name", "asset_block", "parameter_value",
      "parameter_unit", "status")
  ),
  "",
  "## FAAt402 status",
  "",
  paste(
    "NFC ME and NRC FAAt402 Fisher quantity indexes are retained only for",
    "comparison with a future real-stock trajectory. They are prohibited as",
    "baseline stocks, capital prices, revaluation indexes, GPIM inputs, or",
    "GPIM products."
  ),
  "",
  "## Implied-investment fallback status",
  "",
  paste(
    "The stock-flow-implied ME/NRC investment formulas are not activated.",
    "Direct FAAt407 nominal investment remains canonical, and the missing",
    "asset revaluation terms keep implied investment fallback-only."
  ),
  "",
  "## Capital-price treatment options",
  "",
  markdown_table(
    price_options,
    c("protocol_item", "asset_block", "baseline_allowed", "decision",
      "reason")
  ),
  "",
  "## Protocol decision required before GPIM construction",
  "",
  paste(
    "S12C prepares the capital inputs but does not construct GPIM stocks.",
    "Before S12D can construct GPIM stocks, the project must lock the",
    "real-investment price treatment. FAAt402 cannot supply this role.",
    "Direct nominal ME/NRC investment remains canonical, while implied",
    "investment remains fallback-only."
  ),
  "",
  "The admissible candidates still requiring review are:",
  "",
  paste(
    "- Output-price deflation with `P_Y_NFC_GVA_IMPLICIT_SOURCE` as a",
    "common-output-unit normalization."
  ),
  paste(
    "- Nominal/current-cost bookkeeping that preserves nominal consistency",
    "without claiming a real productive-capacity stock."
  ),
  "",
  "## Validation results",
  "",
  markdown_table(
    validation,
    c("validation_rule", "result", "observed")
  ),
  "",
  "## Next construction step",
  "",
  paste(
    "The next step is S12D only after a GPIM price-treatment protocol is",
    "locked. S12D may then construct GPIM ME/NRC gross stocks and Kcap.",
    "Until then, proceed only to protocol review, not GPIM construction."
  )
)
writeLines(report_lines, report_path, useBytes = TRUE)

message("S12C capital input and GPIM protocol validation passed.")
message("Capital input rows: ", nrow(capital_inputs))
message("Capital input series: ", length(unique(capital_inputs$variable_name)))
message("GPIM parameter rows: ", nrow(parameter_metadata))
message("Protocol ledger rows: ", nrow(protocol_ledger))
message("Validation checks: ", nrow(validation))
message("Capital-price treatment locked: no")
message("GPIM stocks constructed: no")
message("S20/S21/S22 run: no")
