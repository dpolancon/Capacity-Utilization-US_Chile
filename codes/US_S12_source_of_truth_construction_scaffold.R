#!/usr/bin/env Rscript

# S12 registers pre-econometric source-of-truth constructions from the closed
# provider handoff. It does not fetch data, construct final variables, run
# S20/S21/S22, or estimate econometric models.

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(repo_root, "Capacity-Utilization-US_Chile.Rproj"))) {
  stop("Run S12 from the downstream repository root.", call. = FALSE)
}

abort <- function(message) {
  stop(message, call. = FALSE)
}

require_condition <- function(condition, message) {
  if (!isTRUE(condition)) {
    abort(message)
  }
}

read_csv <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

provider_root <- file.path(
  repo_root, "data", "provider_handoffs", "US_BEA_FixedAssets"
)
handoff_candidates <- list.dirs(
  provider_root, full.names = TRUE, recursive = FALSE
)
handoff_candidates <- handoff_candidates[
  grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", basename(handoff_candidates))
]
require_condition(
  length(handoff_candidates) > 0L,
  "No dated US_BEA_FixedAssets provider handoff directory was found."
)
handoff_dir <- sort(handoff_candidates, decreasing = TRUE)[1L]

input_paths <- c(
  provider_menu = file.path(handoff_dir, "ch2_master_variable_menu.csv"),
  provider_metadata = file.path(
    handoff_dir, "ch2_master_variable_metadata.csv"
  ),
  provider_status = file.path(handoff_dir, "ch2_provider_fetch_status.csv"),
  provider_handoff = file.path(handoff_dir, "HANDOFF.md"),
  provider_manifest = file.path(handoff_dir, "MANIFEST.csv"),
  price_registry = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_READINESS",
    "csv", "S12_price_object_construction_registry.csv"
  ),
  readiness_report = file.path(
    repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_READINESS",
    "md", "S12_SOURCE_OF_TRUTH_READINESS.md"
  ),
  provenance_note = file.path(
    repo_root, "chapter2_vault", "04_data_measurement",
    "V01_DataProvenance_Managment.md"
  )
)

missing_files <- input_paths[!file.exists(input_paths)]
if (length(missing_files) > 0L) {
  abort(
    paste0(
      "Missing S12 scaffold inputs:\n- ",
      paste(unname(missing_files), collapse = "\n- ")
    )
  )
}

provider_menu <- read_csv(input_paths[["provider_menu"]])
provider_metadata <- read_csv(input_paths[["provider_metadata"]])
provider_status <- read_csv(input_paths[["provider_status"]])
price_registry <- read_csv(input_paths[["price_registry"]])
provider_manifest <- read_csv(input_paths[["provider_manifest"]])

required_menu_columns <- c(
  "variable_id", "sector_scope", "asset_scope", "preferred_role",
  "required_for", "preferred_source", "bea_dataset", "bea_table_name",
  "bea_line_number", "bea_series_code", "fetch_status",
  "construction_status", "formula_if_constructed", "notes"
)
required_status_columns <- c(
  "variable_id", "sector_scope", "fetch_status", "validation_status",
  "validation_message"
)
required_registry_columns <- c(
  "variable_name", "object_family", "source_role", "construction_stage",
  "baseline_or_robustness", "source_system", "source_table_or_series",
  "source_line_or_series_id", "source_boundary", "target_boundary",
  "allowed_use", "not_allowed_use", "construction_formula_or_rule",
  "validation_rule", "limitations", "status", "notes"
)

check_columns <- function(data, required, label) {
  missing <- setdiff(required, names(data))
  require_condition(
    length(missing) == 0L,
    paste0(label, " is missing columns: ", paste(missing, collapse = ", "))
  )
}

check_columns(provider_menu, required_menu_columns, "Provider menu")
check_columns(provider_status, required_status_columns, "Provider status")
check_columns(price_registry, required_registry_columns, "Price registry")

require_condition(
  nrow(provider_menu) == 71L,
  paste0("Expected 71 provider-menu rows; found ", nrow(provider_menu), ".")
)
require_condition(
  nrow(provider_metadata) == 71L,
  paste0(
    "Expected 71 provider-metadata rows; found ",
    nrow(provider_metadata), "."
  )
)
require_condition(
  nrow(provider_status) == 71L &&
    all(provider_status$validation_status == "PASS"),
  "Provider handoff validation is not 71 PASS / 0 FAIL."
)
require_condition(
  nrow(price_registry) == 8L,
  paste0("Expected 8 price-registry rows; found ", nrow(price_registry), ".")
)

expected_price_ids <- c(
  "P_Y_NFC_GVA_IMPLICIT_SOURCE",
  "P_Y_NFC_GVA_T115_VALIDATION",
  "P_Y_PROXY_GDP_IMPLICIT",
  "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT",
  "P_Y_PROXY_BUSINESS_OUTPUT",
  "P_Y_PROXY_NONFARM_BUSINESS_OUTPUT_BLS",
  "P_Y_PROXY_GDPBYIND_VA_FINANCE_INSURANCE",
  "P_Y_PROXY_GDPBYIND_VA_MANUFACTURING"
)
require_condition(
  setequal(price_registry$variable_name, expected_price_ids),
  "The S12 price registry does not contain the locked eight-object hierarchy."
)

baseline_price <- price_registry[
  price_registry$baseline_or_robustness == "baseline", , drop = FALSE
]
require_condition(
  nrow(baseline_price) == 1L &&
    baseline_price$variable_name == "P_Y_NFC_GVA_IMPLICIT_SOURCE" &&
    baseline_price$status == "construction_ready",
  "The S12 baseline price lock failed."
)
require_condition(
  all(
    price_registry$status[
      price_registry$baseline_or_robustness == "robustness"
    ] == "robustness_ready"
  ),
  "One or more S12 robustness price objects are not robustness_ready."
)

output_root <- file.path(
  repo_root, "output", "US", "S12_SOURCE_OF_TRUTH_CONSTRUCTION"
)
csv_dir <- file.path(output_root, "csv")
md_dir <- file.path(output_root, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

ledger_path <- file.path(csv_dir, "S12_construction_plan_ledger.csv")
input_check_path <- file.path(csv_dir, "S12_required_inputs_check.csv")
report_path <- file.path(md_dir, "S12_SOURCE_OF_TRUTH_CONSTRUCTION.md")

ledger_columns <- c(
  "target_variable", "object_family", "construction_stage",
  "required_inputs", "input_source_files", "provider_variable_ids",
  "price_object_used", "baseline_or_robustness", "construction_formula",
  "allowed_status", "blocked_reason", "validation_rule",
  "downstream_stage_owner", "notes"
)

ledger_rows <- list()

add_plan <- function(
    target_variable, object_family, construction_stage, required_inputs,
    input_source_files, provider_variable_ids = "", price_object_used = "",
    baseline_or_robustness, construction_formula, allowed_status,
    blocked_reason = "", validation_rule, downstream_stage_owner, notes = "") {
  ledger_rows[[length(ledger_rows) + 1L]] <<- data.frame(
    target_variable = target_variable,
    object_family = object_family,
    construction_stage = construction_stage,
    required_inputs = required_inputs,
    input_source_files = input_source_files,
    provider_variable_ids = provider_variable_ids,
    price_object_used = price_object_used,
    baseline_or_robustness = baseline_or_robustness,
    construction_formula = construction_formula,
    allowed_status = allowed_status,
    blocked_reason = blocked_reason,
    validation_rule = validation_rule,
    downstream_stage_owner = downstream_stage_owner,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

relative_path <- function(path) {
  prefix <- paste0(repo_root, "/")
  normalized <- normalizePath(path, winslash = "/", mustWork = FALSE)
  sub(paste0("^", prefix), "", normalized)
}

registry_source <- relative_path(input_paths[["price_registry"]])
menu_source <- relative_path(input_paths[["provider_menu"]])
status_source <- relative_path(input_paths[["provider_status"]])
handoff_source <- relative_path(input_paths[["provider_handoff"]])
provenance_source <- relative_path(input_paths[["provenance_note"]])
provider_sources <- paste(menu_source, status_source, handoff_source, sep = "; ")

for (i in seq_len(nrow(price_registry))) {
  row <- price_registry[i, ]
  add_plan(
    target_variable = row$variable_name,
    object_family = row$object_family,
    construction_stage = row$construction_stage,
    required_inputs = paste(
      row$source_table_or_series,
      row$source_line_or_series_id,
      sep = " / "
    ),
    input_source_files = registry_source,
    provider_variable_ids = if (
      row$variable_name == "P_Y_NFC_GVA_IMPLICIT_SOURCE"
    ) {
      "gva_current_nfc; gva_real_or_qindex_nfc; gva_price_or_deflator_nfc"
    } else if (row$variable_name == "P_Y_NFC_GVA_T115_VALIDATION") {
      "T11500 line 1 A455RD (S11C validation metadata)"
    } else {
      ""
    },
    price_object_used = row$variable_name,
    baseline_or_robustness = row$baseline_or_robustness,
    construction_formula = row$construction_formula_or_rule,
    allowed_status = row$status,
    blocked_reason = "",
    validation_rule = row$validation_rule,
    downstream_stage_owner = "S12_source_of_truth",
    notes = paste(row$allowed_use, row$not_allowed_use, row$limitations, sep = " | ")
  )
}

add_plan(
  "Y_REAL_NFC_GVA_BASELINE",
  "real_output",
  "S12_real_output_construction",
  "NFC current-dollar GVA and same-boundary NFC implicit GVA deflator",
  paste(provider_sources, registry_source, sep = "; "),
  "gva_current_nfc; gva_real_or_qindex_nfc; gva_price_or_deflator_nfc",
  "P_Y_NFC_GVA_IMPLICIT_SOURCE",
  "baseline",
  "100 * gva_current_nfc / P_Y_NFC_GVA_IMPLICIT_SOURCE after harmonizing units and index scale",
  "construction_planned",
  "Observation payload is not included in the provider handoff bundle.",
  "Compare with direct T11400 line 41 chained-dollar NFC GVA and preserve the NFC boundary.",
  "S12_source_of_truth",
  "No CORP or FC substitution is allowed."
)

proxy_rows <- price_registry[
  price_registry$baseline_or_robustness == "robustness", , drop = FALSE
]
for (i in seq_len(nrow(proxy_rows))) {
  proxy <- proxy_rows[i, ]
  output_name <- sub(
    "^P_Y_PROXY_", "Y_REAL_NFC_GVA_PROXY_", proxy$variable_name
  )
  add_plan(
    output_name,
    "real_output_proxy",
    "S12_real_output_robustness",
    paste("NFC current-dollar GVA and", proxy$variable_name),
    paste(provider_sources, registry_source, sep = "; "),
    "gva_current_nfc",
    proxy$variable_name,
    "robustness",
    paste0(
      "100 * gva_current_nfc / ", proxy$variable_name,
      " after frequency, unit, and index-base harmonization"
    ),
    "robustness_planned",
    "Proxy observations are not included in the provider handoff bundle.",
    "Compare only with Y_REAL_NFC_GVA_BASELINE; retain the P_Y_PROXY source name and boundary limitation.",
    "S12_source_of_truth",
    "Robustness-only real-output variant; never relabel as CORP or FC real GVA."
  )
}

capital_inputs <- list(
  list(
    id = "I_NOM_NFC_ME_DIRECT",
    provider = "me_investment_current_dollar_nfc",
    family = "capital_investment_input",
    status = "source_input_ready",
    formula = "Import direct FAAt407 NFC equipment current-dollar investment.",
    validation = "Match FAAt407 line 38 and preserve nominal millions-of-dollars units.",
    notes = "Canonical ME investment input."
  ),
  list(
    id = "I_NOM_NFC_NRC_DIRECT",
    provider = "nrc_investment_current_dollar_nfc",
    family = "capital_investment_input",
    status = "source_input_ready",
    formula = "Import direct FAAt407 NFC structures current-dollar investment.",
    validation = "Match FAAt407 line 39 and preserve nominal millions-of-dollars units.",
    notes = "Canonical NRC investment input."
  ),
  list(
    id = "K_NET_CC_NFC_ME_VALIDATION",
    provider = "me_netstock_current_cost_nfc",
    family = "capital_stock_validation_input",
    status = "validation_ready",
    formula = "Import FAAt401 NFC equipment current-cost net stock for validation only.",
    validation = "Use only to validate scale and trajectory of downstream ME capital.",
    notes = "Not a GPIM gross-stock product."
  ),
  list(
    id = "K_NET_CC_NFC_NRC_VALIDATION",
    provider = "nrc_netstock_current_cost_nfc",
    family = "capital_stock_validation_input",
    status = "validation_ready",
    formula = "Import FAAt401 NFC structures current-cost net stock for validation only.",
    validation = "Use only to validate scale and trajectory of downstream NRC capital.",
    notes = "Not a GPIM gross-stock product."
  ),
  list(
    id = "CFC_CC_NFC_ME_INPUT",
    provider = "me_cfc_nfc",
    family = "capital_depreciation_input",
    status = "diagnostic_ready",
    formula = "Import FAAt404 NFC equipment current-cost depreciation.",
    validation = "Match FAAt404 line 38; do not infer real investment by residual.",
    notes = "Fallback and validation ingredient."
  ),
  list(
    id = "CFC_CC_NFC_NRC_INPUT",
    provider = "nrc_cfc_nfc",
    family = "capital_depreciation_input",
    status = "diagnostic_ready",
    formula = "Import FAAt404 NFC structures current-cost depreciation.",
    validation = "Match FAAt404 line 39; do not infer real investment by residual.",
    notes = "Fallback and validation ingredient."
  ),
  list(
    id = "Q_K_BEAFIXEDASSETS_ME_VALIDATION",
    provider = "me_price_or_qindex",
    family = "capital_quantity_validation_input",
    status = "validation_only",
    formula = "Import the FAAt402 ME Fisher quantity index for comparison only.",
    validation = "Compare trajectories only; do not use as a price, revaluation index, GPIM input, or GPIM output.",
    notes = "FAAt402 baseline use is prohibited."
  ),
  list(
    id = "Q_K_BEAFIXEDASSETS_NRC_VALIDATION",
    provider = "nrc_price_or_qindex",
    family = "capital_quantity_validation_input",
    status = "validation_only",
    formula = "Import the FAAt402 NRC Fisher quantity index for comparison only.",
    validation = "Compare trajectories only; do not use as a price, revaluation index, GPIM input, or GPIM output.",
    notes = "FAAt402 baseline use is prohibited."
  )
)

for (item in capital_inputs) {
  add_plan(
    item$id,
    item$family,
    "S12_capital_input_staging",
    item$provider,
    provider_sources,
    item$provider,
    "",
    if (grepl("VALIDATION", item$id)) "validation" else "baseline_input",
    item$formula,
    item$status,
    "Observation payload is not included in the provider handoff bundle.",
    item$validation,
    "S12_source_of_truth",
    item$notes
  )
}

gpim_targets <- c(
  "K_G_NFC_ME_GPIM",
  "K_G_NFC_NRC_GPIM",
  "K_G_NFC_KCAP_GPIM"
)
for (target in gpim_targets) {
  is_me <- grepl("_ME_", target)
  is_nrc <- grepl("_NRC_", target)
  provider_ids <- if (is_me) {
    "me_investment_current_dollar_nfc; me_cfc_nfc; alpha_ME; L_ME"
  } else if (is_nrc) {
    "nrc_investment_current_dollar_nfc; nrc_cfc_nfc; alpha_NRC; L_NRC"
  } else {
    "K_G_NFC_ME_GPIM; K_G_NFC_NRC_GPIM"
  }
  formula <- if (is_me) {
    "Apply the downstream-approved ME GPIM recursion using direct nominal ME investment and approved ME price, survival, depreciation, and initialization rules."
  } else if (is_nrc) {
    "Apply the downstream-approved NRC GPIM recursion using direct nominal NRC investment and approved NRC price, survival, depreciation, and initialization rules."
  } else {
    "K_G_NFC_ME_GPIM + K_G_NFC_NRC_GPIM after confirming common real-price basis."
  }
  add_plan(
    target,
    "gpim_gross_capital",
    "S12_GPIM_construction_plan",
    provider_ids,
    provider_sources,
    provider_ids,
    "",
    "baseline",
    formula,
    "protocol_definition_required",
    paste(
      "Exact GPIM initialization and admissible capital-price treatment",
      "remain downstream protocol work; FAAt402 cannot fill that role."
    ),
    "Validate separately against FAAt401 current-cost stocks and FAAt402 quantity-index trajectories without promoting either to the GPIM baseline.",
    "S12_source_of_truth",
    "Registered only; no GPIM stock is constructed by this scaffold."
  )
}

distribution_targets <- list(
  list(
    id = "omega_NFC",
    inputs = "comp_emp_nfc; gva_current_nfc",
    formula = "comp_emp_nfc / gva_current_nfc after matching frequency, units, and NFC boundary",
    validation = "Require 0 <= omega_NFC <= 1 where both inputs are positive."
  ),
  list(
    id = "omega_CORP",
    inputs = "comp_emp_corp; gva_current_corp",
    formula = "comp_emp_corp / gva_current_corp after matching frequency, units, and CORP boundary",
    validation = "Require 0 <= omega_CORP <= 1 where both inputs are positive."
  )
)
for (item in distribution_targets) {
  add_plan(
    item$id,
    "distribution_placeholder",
    "S12_distribution_plan",
    item$inputs,
    provider_sources,
    item$inputs,
    "",
    "baseline",
    item$formula,
    "baseline_allowed_not_constructed",
    "Observation payload is not included in the provider handoff bundle.",
    item$validation,
    "S12_source_of_truth",
    "Unadjusted wage share is allowed as the first-pass baseline."
  )
}

shaikh_targets <- c(
  "BankMonIntPaid_t", "CorpNFNetImpIntPaid_t", "CorpImpIntAdj_t",
  "GVAcorp_adj_t", "NOScorp_adj_t", "VAcorp_adj_t",
  "omega_adj_CORP_t", "pi_adj_res_CORP_t", "e_adj_CORP_t"
)
for (target in shaikh_targets) {
  add_plan(
    target,
    "distribution_protocol_placeholder",
    "S12_current_release_Shaikh_protocol",
    "Protocol-approved current-release T711 and corporate income-account ingredients",
    provenance_source,
    "T711 candidate ingredients only",
    "",
    "gated",
    "No formula is admissible until the current-release Shaikh protocol passes.",
    "blocked_pending_current_release_protocol",
    "Current BEA candidate lines are provenance ingredients, not formula-admissible inputs.",
    "Require a separately documented semantic and accounting protocol before construction.",
    "S12_source_of_truth",
    "Must not overwrite the unadjusted distribution baseline."
  )
}

prohibited <- list(
  list(
    id = "gva_real_or_qindex_corp",
    family = "prohibited_real_output",
    inputs = "CORP and NFC chained-dollar GVA",
    formula = "CORP real GVA minus NFC real GVA",
    reason = "No same-boundary CORP real GVA source exists; chained-dollar residual subtraction is prohibited."
  ),
  list(
    id = "gva_real_or_qindex_fc",
    family = "prohibited_real_output",
    inputs = "CORP and NFC chained-dollar GVA",
    formula = "CORP real GVA minus NFC real GVA",
    reason = "No same-boundary FC real GVA source exists; chained-dollar residual subtraction is prohibited."
  ),
  list(
    id = "gva_price_or_deflator_corp",
    family = "prohibited_output_price",
    inputs = "CORP nominal GVA and any proxy or residual real GVA",
    formula = "Any residual or proxy-relabeled CORP GVA deflator",
    reason = "No same-boundary CORP real/price counterpart exists."
  ),
  list(
    id = "gva_price_or_deflator_fc",
    family = "prohibited_output_price",
    inputs = "FC nominal GVA and any proxy or residual real GVA",
    formula = "Any residual or proxy-relabeled FC GVA deflator",
    reason = "No same-boundary FC real/price counterpart exists."
  ),
  list(
    id = "corp_gva_deflator_PROXY_RELABEL",
    family = "prohibited_proxy_relabel",
    inputs = "Any P_Y_PROXY_* object",
    formula = "Rename a proxy as corp_gva_deflator",
    reason = "Proxy relabeling would falsely claim a corporate legal-form boundary."
  ),
  list(
    id = "fc_gva_deflator_PROXY_RELABEL",
    family = "prohibited_proxy_relabel",
    inputs = "Any P_Y_PROXY_* object",
    formula = "Rename a proxy as fc_gva_deflator",
    reason = "Proxy relabeling would falsely claim a financial-corporate boundary."
  ),
  list(
    id = "me_investment_implied_fallback_nfc_BASELINE",
    family = "prohibited_fallback_promotion",
    inputs = "me_netstock_current_cost_nfc; me_cfc_nfc; missing ME revaluation index",
    formula = "Promote stock-flow-implied ME investment to baseline",
    reason = "Direct FAAt407 ME investment is available and canonical."
  ),
  list(
    id = "nrc_investment_implied_fallback_nfc_BASELINE",
    family = "prohibited_fallback_promotion",
    inputs = "nrc_netstock_current_cost_nfc; nrc_cfc_nfc; missing NRC revaluation index",
    formula = "Promote stock-flow-implied NRC investment to baseline",
    reason = "Direct FAAt407 NRC investment is available and canonical."
  ),
  list(
    id = "FAAt402_GPIM_BASELINE",
    family = "prohibited_capital_index_promotion",
    inputs = "me_price_or_qindex; nrc_price_or_qindex",
    formula = "Use FAAt402 as a GPIM stock, price index, or revaluation index",
    reason = "FAAt402 is a Fisher quantity-index comparison object only."
  )
)
for (item in prohibited) {
  add_plan(
    item$id,
    item$family,
    "S12_prohibited_registry",
    item$inputs,
    paste(provider_sources, registry_source, sep = "; "),
    "",
    "",
    "prohibited",
    item$formula,
    "prohibited",
    item$reason,
    "The object must remain absent from all source-of-truth datasets.",
    "S12_source_of_truth",
    "Registry row documents a hard construction prohibition."
  )
}

ledger <- do.call(rbind, ledger_rows)
ledger <- ledger[, ledger_columns, drop = FALSE]
rownames(ledger) <- NULL

required_provider_ids <- c(
  "gva_current_nfc", "gva_real_or_qindex_nfc",
  "gva_price_or_deflator_nfc", "comp_emp_nfc", "comp_emp_corp",
  "gva_current_corp", "me_investment_current_dollar_nfc",
  "nrc_investment_current_dollar_nfc", "me_cfc_nfc", "nrc_cfc_nfc",
  "me_netstock_current_cost_nfc", "nrc_netstock_current_cost_nfc",
  "me_price_or_qindex", "nrc_price_or_qindex",
  "me_investment_implied_fallback_nfc",
  "nrc_investment_implied_fallback_nfc", "alpha_ME", "alpha_NRC",
  "L_ME", "L_NRC"
)
missing_provider_ids <- setdiff(
  required_provider_ids, provider_menu$variable_id
)
require_condition(
  length(missing_provider_ids) == 0L,
  paste0(
    "Required provider IDs missing from handoff:\n- ",
    paste(missing_provider_ids, collapse = "\n- ")
  )
)

input_checks <- data.frame(
  check_id = character(),
  input_kind = character(),
  input_reference = character(),
  required_for = character(),
  required = logical(),
  present = logical(),
  metadata_status = character(),
  observation_status = character(),
  check_status = character(),
  notes = character(),
  stringsAsFactors = FALSE
)

add_input_check <- function(
    check_id, input_kind, input_reference, required_for, required, present,
    metadata_status, observation_status, check_status, notes) {
  input_checks <<- rbind(
    input_checks,
    data.frame(
      check_id = check_id,
      input_kind = input_kind,
      input_reference = input_reference,
      required_for = required_for,
      required = required,
      present = present,
      metadata_status = metadata_status,
      observation_status = observation_status,
      check_status = check_status,
      notes = notes,
      stringsAsFactors = FALSE
    )
  )
}

for (name in names(input_paths)) {
  add_input_check(
    paste0("file_", name),
    "file",
    relative_path(input_paths[[name]]),
    "S12 scaffold metadata and lock validation",
    TRUE,
    file.exists(input_paths[[name]]),
    "available",
    if (name %in% c("provider_menu", "provider_metadata", "provider_status")) {
      "metadata_only"
    } else {
      "not_applicable"
    },
    if (file.exists(input_paths[[name]])) "PASS" else "FAIL",
    "Required local input."
  )
}

for (id in required_provider_ids) {
  row <- provider_menu[provider_menu$variable_id == id, , drop = FALSE]
  status_row <- provider_status[
    provider_status$variable_id == id, , drop = FALSE
  ]
  present <- nrow(row) == 1L && nrow(status_row) == 1L
  metadata_status <- if (present) {
    paste(row$fetch_status, row$construction_status, sep = " / ")
  } else {
    "missing"
  }
  add_input_check(
    paste0("provider_id_", id),
    "provider_variable_id",
    id,
    "Output, capital, GPIM, or distribution construction plan",
    TRUE,
    present,
    metadata_status,
    "not_in_handoff_bundle",
    if (present && status_row$validation_status == "PASS") "PASS" else "FAIL",
    "The closed handoff validates metadata and source mappings; it contains no observation payload."
  )
}

for (id in expected_price_ids) {
  row <- price_registry[
    price_registry$variable_name == id, , drop = FALSE
  ]
  add_input_check(
    paste0("price_registry_", id),
    "price_object_registry",
    id,
    "Locked output-price hierarchy",
    TRUE,
    nrow(row) == 1L,
    if (nrow(row) == 1L) row$status else "missing",
    if (id %in% c(
      "P_Y_NFC_GVA_IMPLICIT_SOURCE",
      "P_Y_NFC_GVA_T115_VALIDATION"
    )) {
      "provider_component_observations_not_in_bundle"
    } else {
      "proxy_observations_not_in_bundle"
    },
    if (nrow(row) == 1L) "PASS" else "FAIL",
    "Registry readiness is confirmed; observation import is a later pre-econometric implementation step."
  )
}

add_input_check(
  "observation_payload_boundary",
  "scope_boundary",
  relative_path(handoff_dir),
  "Numerical source-of-truth construction",
  FALSE,
  FALSE,
  "handoff_is_metadata_complete",
  "observations_pending",
  "PENDING",
  "This scaffold intentionally does not fetch or construct observations."
)

required_targets <- c(
  expected_price_ids,
  "Y_REAL_NFC_GVA_BASELINE",
  sub("^P_Y_PROXY_", "Y_REAL_NFC_GVA_PROXY_",
      expected_price_ids[grepl("^P_Y_PROXY_", expected_price_ids)]),
  vapply(capital_inputs, `[[`, character(1L), "id"),
  gpim_targets,
  vapply(distribution_targets, `[[`, character(1L), "id"),
  shaikh_targets,
  vapply(prohibited, `[[`, character(1L), "id")
)
missing_targets <- setdiff(required_targets, ledger$target_variable)
require_condition(
  length(missing_targets) == 0L,
  paste0(
    "Required S12 plan targets are missing:\n- ",
    paste(missing_targets, collapse = "\n- ")
  )
)

forbidden_baseline <- ledger$baseline_or_robustness == "baseline" &
  (
    ledger$allowed_status == "prohibited" |
      grepl("P_Y_PROXY_", ledger$price_object_used, fixed = TRUE)
  )
require_condition(
  !any(forbidden_baseline),
  "A prohibited or proxy price object was promoted to the baseline."
)
require_condition(
  all(
    ledger$allowed_status[
      ledger$target_variable %in% c(
        "gva_real_or_qindex_corp", "gva_real_or_qindex_fc",
        "gva_price_or_deflator_corp", "gva_price_or_deflator_fc"
      )
    ] == "prohibited"
  ),
  "CORP/FC real-price residual locks were not preserved."
)
require_condition(
  all(
    ledger$allowed_status[
      ledger$target_variable %in% shaikh_targets
    ] == "blocked_pending_current_release_protocol"
  ),
  "A Shaikh-adjusted object escaped its current-release protocol gate."
)
require_condition(
  all(input_checks$check_status != "FAIL"),
  "One or more required S12 input checks failed."
)

write.csv(ledger, ledger_path, row.names = FALSE, na = "")
write.csv(input_checks, input_check_path, row.names = FALSE, na = "")

escape_md <- function(x) {
  x <- gsub("\r|\n", " ", as.character(x))
  gsub("|", "\\|", x, fixed = TRUE)
}

markdown_table <- function(data, columns) {
  header <- paste0("| ", paste(columns, collapse = " | "), " |")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(data[, columns, drop = FALSE], 1L, function(row) {
    paste0(
      "| ",
      paste(vapply(row, escape_md, character(1L)), collapse = " | "),
      " |"
    )
  })
  c(header, divider, body)
}

status_summary <- as.data.frame(table(ledger$allowed_status))
names(status_summary) <- c("allowed_status", "rows")
blocked_rows <- ledger[
  ledger$allowed_status %in% c(
    "prohibited", "blocked_pending_current_release_protocol",
    "protocol_definition_required"
  ),
  c("target_variable", "allowed_status", "blocked_reason"),
  drop = FALSE
]

report_lines <- c(
  "# S12 Source-of-Truth Construction Scaffold",
  "",
  "## Purpose",
  "",
  paste(
    "This scaffold translates the closed provider handoff and S11B/S11C",
    "price hierarchy into a pre-econometric construction plan. It validates",
    "metadata, required provider IDs, object roles, and hard prohibitions.",
    "It does not construct final series."
  ),
  "",
  "## Inputs",
  "",
  paste0("- Provider handoff: `", relative_path(handoff_dir), "`"),
  paste0("- Price registry: `", registry_source, "`"),
  paste0("- Provenance authority: `", provenance_source, "`"),
  paste0("- Provider menu rows: ", nrow(provider_menu)),
  paste0("- Provider validation: ", sum(provider_status$validation_status == "PASS"),
         " PASS / ", sum(provider_status$validation_status != "PASS"), " FAIL"),
  paste0("- Price registry rows: ", nrow(price_registry)),
  paste(
    "- The handoff is metadata-complete but contains no observation payload;",
    "numerical imports remain pending."
  ),
  "",
  "## Locked Price Hierarchy",
  "",
  "- Baseline: `P_Y_NFC_GVA_IMPLICIT_SOURCE`.",
  "- Validation: `P_Y_NFC_GVA_T115_VALIDATION`.",
  "- Robustness: the six explicitly named `P_Y_PROXY_*` objects.",
  "- No proxy is admissible as a CORP or FC GVA deflator.",
  "",
  "## Construction Plan Summary",
  "",
  paste0("- Construction-plan rows: ", nrow(ledger)),
  markdown_table(status_summary, c("allowed_status", "rows")),
  "",
  "## Baseline and Validation Objects",
  "",
  paste(
    "The baseline real-output plan uses NFC current-dollar GVA and the",
    "same-boundary NFC implicit deflator, with direct T11400 line 41",
    "chained-dollar NFC GVA as validation. T11500 line 1 remains a",
    "validation-only price counterpart."
  ),
  paste(
    "Direct FAAt407 nominal ME and NRC investment remains canonical.",
    "FAAt401 stocks, FAAt404 depreciation, and FAAt402 quantity indexes",
    "remain validation or diagnostic ingredients according to their locked",
    "roles."
  ),
  "",
  "## GPIM Boundary",
  "",
  paste(
    "`K_G_NFC_ME_GPIM`, `K_G_NFC_NRC_GPIM`, and",
    "`K_G_NFC_KCAP_GPIM` are registered as planned downstream objects.",
    "Their exact initialization, survival/depreciation parameterization,",
    "and admissible capital-price treatment require a separate construction",
    "protocol. FAAt402 cannot be used as a GPIM baseline input or output."
  ),
  "",
  "## Distribution Boundary",
  "",
  paste(
    "Unadjusted `omega_NFC` and `omega_CORP` are allowed first-pass",
    "baseline placeholders. All current-release Shaikh-adjusted objects",
    "remain `blocked_pending_current_release_protocol` and may not overwrite",
    "the unadjusted baseline."
  ),
  "",
  "## Blocked and Prohibited Objects",
  "",
  markdown_table(
    blocked_rows,
    c("target_variable", "allowed_status", "blocked_reason")
  ),
  "",
  "## Execution Boundary",
  "",
  "- No provider discovery or provider-menu modification occurred.",
  "- No live API fetch occurred.",
  "- No final output, capital, GPIM, or distribution variable was constructed.",
  "- No S20/S21/S22 script or econometric estimation was run.",
  "",
  "## Next Pre-Econometric Step",
  "",
  paste(
    "The next implementation may load versioned observation payloads for",
    "the registered provider IDs and price series, harmonize frequency and",
    "units, and construct only rows marked construction, validation, or",
    "robustness ready. It must preserve all prohibited and protocol-gated",
    "rows in this ledger."
  )
)
writeLines(report_lines, report_path, useBytes = TRUE)

message("S12 source-of-truth construction scaffold passed.")
message("Construction-plan rows: ", nrow(ledger))
message("Required-input checks: ", nrow(input_checks))
message("Blocked/prohibited/protocol rows: ", nrow(blocked_rows))
message("Observation construction performed: no")
message("S20/S21/S22 run: no")
