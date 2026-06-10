#!/usr/bin/env Rscript

# S10 builds a source-of-truth scaffold from the locked downstream provider copy.
# It performs no BEA fetch, GPIM construction, Shaikh adjustment, estimation,
# capacity reconstruction, or utilization reconstruction.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
provider_dir <- file.path(repo_root, "data", "external", "us_bea_provider")
output_dir <- file.path(repo_root, "data", "processed", "us_s10")
validation_dir <- file.path(repo_root, "docs", "validation")
data_sources_dir <- file.path(repo_root, "docs", "data_sources")

provider_paths <- c(
  staged = file.path(provider_dir, "us_bea_variable_menu_long.csv"),
  provenance = file.path(provider_dir, "us_bea_source_provenance_ledger.csv"),
  manifest = file.path(provider_dir, "us_bea_variable_menu_locked.csv"),
  manifest_json = file.path(provider_dir, "us_bea_variable_menu_locked.json")
)

output_paths <- c(
  source_panel = file.path(output_dir, "us_s10_source_panel_long.csv"),
  object_ledger = file.path(
    output_dir, "us_s10_object_admissibility_ledger.csv"
  ),
  validation_checks = file.path(
    output_dir, "us_s10_provider_validation_checks.csv"
  ),
  validation_report = file.path(
    validation_dir, "US_S10_SOURCE_OF_TRUTH_SCAFFOLD_VALIDATION.md"
  ),
  construction_ledger = file.path(
    data_sources_dir, "US_S10_SOURCE_OF_TRUTH_CONSTRUCTION_LEDGER.md"
  )
)

abort <- function(message) {
  stop(message, call. = FALSE)
}

require_condition <- function(condition, message) {
  if (!isTRUE(condition)) {
    abort(message)
  }
}

missing_inputs <- provider_paths[!file.exists(provider_paths)]
if (length(missing_inputs) > 0L) {
  abort(
    paste0(
      "S10 required provider inputs are missing:\n- ",
      paste(unname(missing_inputs), collapse = "\n- ")
    )
  )
}

normalized_provider_dir <- normalizePath(
  provider_dir, winslash = "/", mustWork = TRUE
)
normalized_inputs <- normalizePath(
  provider_paths, winslash = "/", mustWork = TRUE
)
provider_only_inputs <- all(
  startsWith(normalized_inputs, paste0(normalized_provider_dir, "/"))
)
require_condition(
  provider_only_inputs,
  "S10 input paths must all resolve inside data/external/us_bea_provider/."
)

provider_hashes_before <- unname(tools::md5sum(provider_paths))

read_provider_csv <- function(path) {
  read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = character()
  )
}

staged <- read_provider_csv(provider_paths[["staged"]])
provenance <- read_provider_csv(provider_paths[["provenance"]])
manifest <- read_provider_csv(provider_paths[["manifest"]])
manifest_json <- readLines(
  provider_paths[["manifest_json"]],
  warn = FALSE,
  encoding = "UTF-8"
)

required_columns <- list(
  staged = c("variable_id", "date", "year", "value"),
  provenance = c(
    "variable_id",
    "canonical_name",
    "source_system",
    "bea_dataset",
    "bea_table",
    "bea_line",
    "bea_line_description",
    "series_code",
    "sector_boundary",
    "asset_block",
    "account_boundary",
    "frequency",
    "unit",
    "price_basis",
    "stock_flow_type",
    "role_tag",
    "priority",
    "required_for_downstream_object",
    "download_date",
    "vintage",
    "source_url_or_query",
    "status",
    "notes",
    "source_cache_file",
    "aggregation_group",
    "row_count",
    "coverage_start",
    "coverage_end",
    "staged_source_file"
  ),
  manifest = c(
    "variable_id",
    "canonical_name",
    "source_system",
    "bea_dataset",
    "bea_table",
    "bea_line",
    "bea_line_description",
    "sector_boundary",
    "asset_block",
    "account_boundary",
    "unit",
    "price_basis",
    "stock_flow_type",
    "role_tag",
    "priority",
    "required_for_downstream_object",
    "status",
    "notes"
  )
)

for (object_name in names(required_columns)) {
  missing_columns <- setdiff(
    required_columns[[object_name]],
    names(get(object_name))
  )
  if (length(missing_columns) > 0L) {
    abort(
      paste0(
        object_name,
        " is missing required metadata columns: ",
        paste(missing_columns, collapse = ", ")
      )
    )
  }
}

staged_ids <- unique(staged$variable_id)
manifest_ids <- unique(manifest$variable_id)
provenance_ids <- unique(provenance$variable_id)

require_condition(
  nrow(manifest) == 175L,
  paste0("Manifest row invariant failed: observed ", nrow(manifest), ".")
)
require_condition(
  length(staged_ids) == 94L,
  paste0(
    "Staged variable invariant failed: observed ",
    length(staged_ids),
    " distinct variable_id values."
  )
)
require_condition(
  nrow(staged) == 9438L,
  paste0(
    "Staged observation invariant failed: observed ",
    nrow(staged),
    " rows."
  )
)
require_condition(
  nrow(provenance) == 175L,
  paste0("Provenance row invariant failed: observed ", nrow(provenance), ".")
)
require_condition(
  length(manifest_ids) == nrow(manifest),
  "Locked manifest variable_id values are not unique."
)
require_condition(
  length(provenance_ids) == nrow(provenance),
  "Provenance ledger variable_id values are not unique."
)

missing_manifest_ids <- setdiff(staged_ids, manifest_ids)
missing_provenance_ids <- setdiff(staged_ids, provenance_ids)
require_condition(
  length(missing_manifest_ids) == 0L,
  paste0(
    "Staged variable_id values missing from manifest:\n- ",
    paste(missing_manifest_ids, collapse = "\n- ")
  )
)
require_condition(
  length(missing_provenance_ids) == 0L,
  paste0(
    "Staged variable_id values missing from provenance ledger:\n- ",
    paste(missing_provenance_ids, collapse = "\n- ")
  )
)

json_text <- trimws(paste(manifest_json, collapse = "\n"))
require_condition(
  nzchar(json_text) && substr(json_text, 1L, 1L) %in% c("{", "["),
  "Locked JSON manifest is empty or does not have a JSON object/array prefix."
)

for (path in c(output_dir, validation_dir, data_sources_dir)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  require_condition(
    dir.exists(path),
    paste0("Unable to create required S10 output directory: ", path)
  )
}

provenance_join_columns <- c(
  "variable_id",
  "canonical_name",
  "bea_dataset",
  "bea_table",
  "bea_line",
  "vintage",
  "source_url_or_query",
  "status",
  "notes",
  "source_cache_file",
  "aggregation_group",
  "row_count",
  "coverage_start",
  "coverage_end",
  "staged_source_file"
)

provenance_join <- provenance[provenance_join_columns]
names(provenance_join)[names(provenance_join) != "variable_id"] <- paste0(
  "provenance_",
  names(provenance_join)[names(provenance_join) != "variable_id"]
)

source_panel <- merge(
  staged,
  provenance_join,
  by = "variable_id",
  all.x = TRUE,
  sort = FALSE
)
names(source_panel)[names(source_panel) == "bea_line_description"] <-
  "source_description"
names(source_panel)[names(source_panel) == "source_url_or_query"] <-
  "source_query"
names(source_panel)[names(source_panel) == "notes"] <- "source_notes"
names(source_panel)[names(source_panel) == "source_file"] <-
  "source_observation_file"

source_panel <- source_panel[
  order(source_panel$variable_id, source_panel$year, source_panel$date),
  ,
  drop = FALSE
]
rownames(source_panel) <- NULL

require_condition(
  nrow(source_panel) == 9438L,
  paste0(
    "Source-panel join changed the staged row count: observed ",
    nrow(source_panel),
    "."
  )
)
require_condition(
  !anyNA(source_panel$provenance_canonical_name),
  "Source-panel join produced missing provenance metadata."
)

ledger_columns <- c(
  "object_id",
  "object_label",
  "object_type",
  "construction_stage",
  "required_source_family",
  "analytical_role",
  "admissibility_status",
  "blocking_reason",
  "notes"
)

new_ledger_rows <- function(
    object_id,
    object_label,
    object_type,
    construction_stage,
    required_source_family,
    analytical_role,
    admissibility_status,
    blocking_reason = "",
    notes = "") {
  data.frame(
    object_id = object_id,
    object_label = object_label,
    object_type = object_type,
    construction_stage = construction_stage,
    required_source_family = required_source_family,
    analytical_role = analytical_role,
    admissibility_status = admissibility_status,
    blocking_reason = blocking_reason,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

classify_provider_status <- function(row_index) {
  variable_id <- manifest$variable_id[row_index]
  canonical_name <- manifest$canonical_name[row_index]
  status <- manifest$status[row_index]
  role_tag <- manifest$role_tag[row_index]
  priority <- manifest$priority[row_index]

  if (variable_id %in% staged_ids) {
    return("staged_source_ingredient")
  }
  if (grepl("^(omega_x_|e_x_)", canonical_name)) {
    return("superseded_diagnostic_only")
  }
  if (grepl("^(omega|pi|e|ln_e)_adj_", canonical_name)) {
    return("blocked_pending_current_release_protocol")
  }
  if (identical(status, "downstream_constructed_only")) {
    return("downstream_constructed_pending")
  }
  if (
    identical(priority, "diagnostic") ||
      grepl("diagnostic", role_tag, fixed = TRUE)
  ) {
    return("diagnostic_pending")
  }
  if (identical(role_tag, "frontier_conditioner")) {
    return("frontier_conditioner_pending")
  }
  "not_in_baseline"
}

provider_statuses <- vapply(
  seq_len(nrow(manifest)),
  classify_provider_status,
  character(1L)
)
provider_roles <- manifest$role_tag
provider_roles[provider_statuses == "superseded_diagnostic_only"] <-
  "superseded_level_interaction"
provider_roles[
  provider_statuses == "blocked_pending_current_release_protocol"
] <- "Shaikh_adjusted_contract_blocked"

provider_blocking_reasons <- ifelse(
  provider_statuses == "blocked_pending_current_release_protocol",
  paste(
    "Current-release Shaikh-style protocol has not passed; provider",
    "contract is not formula-admissible."
  ),
  ifelse(
    provider_statuses == "superseded_diagnostic_only",
    paste(
      "Level interactions must not define A00, generated implementation",
      "variables, coefficient promotion, or S40 reconstruction."
    ),
    ifelse(
      provider_statuses == "not_in_baseline",
      paste0("Provider contract status: ", manifest$status),
      ""
    )
  )
)

provider_ledger <- new_ledger_rows(
  object_id = manifest$variable_id,
  object_label = manifest$canonical_name,
  object_type = "provider_variable_contract",
  construction_stage = "S00_provider_handoff",
  required_source_family = paste(
    manifest$source_system,
    manifest$bea_dataset,
    manifest$bea_table,
    sep = ":"
  ),
  analytical_role = provider_roles,
  admissibility_status = provider_statuses,
  blocking_reason = provider_blocking_reasons,
  notes = paste0(
    "Provider artifact preserved without construction. ",
    manifest$notes
  )
)

pending_rows <- list()
append_pending <- function(rows) {
  pending_rows[[length(pending_rows) + 1L]] <<- rows
}

append_pending(new_ledger_rows(
  object_id = c(
    "K_ME", "K_NRC", "K_cap", "k_ME", "k_NRC", "k_Kcap",
    "g_K_ME", "g_K_NRC", "g_Kcap", "ME_NRC_gap", "ME_share", "NRC_share"
  ),
  object_label = c(
    "Real machinery and equipment capital",
    "Real nonresidential structures capital",
    "Preferred productive-capacity capital",
    "Log machinery and equipment capital",
    "Log nonresidential structures capital",
    "Log productive-capacity capital",
    "Growth of machinery and equipment capital",
    "Growth of nonresidential structures capital",
    "Growth of productive-capacity capital",
    "ME-NRC log composition gap",
    "ME share of ME plus NRC",
    "NRC share of ME plus NRC"
  ),
  object_type = "downstream_owned_object",
  construction_stage = "S20_capital_construction",
  required_source_family = "NFC/CORP fixed-assets ME and NRC ingredients",
  analytical_role = c(
    "direct_productive_capacity_capital",
    "direct_productive_capacity_capital",
    "preferred_productive_capacity_baseline",
    rep("capital_transformation", 6L),
    rep("capital_composition_diagnostic", 3L)
  ),
  admissibility_status = c(
    "downstream_constructed_pending",
    "downstream_constructed_pending",
    "preferred_baseline_pending",
    rep("downstream_constructed_pending", 6L),
    rep("diagnostic_pending", 3L)
  ),
  notes = c(
    "ME enters preferred K_cap.",
    "NRC enters preferred K_cap.",
    "Locked identity: K_cap = K_ME + K_NRC.",
    rep("Registered only; no capital object is constructed in S10.", 9L)
  )
))

gpim_ids <- c(
  "K_G_NFC_ME_GPIM",
  "K_G_NFC_NRC_GPIM",
  "K_G_NFC_KCAP_GPIM",
  "K_N_NFC_ME_GPIM",
  "K_N_NFC_NRC_GPIM",
  "K_N_NFC_KCAP_GPIM",
  "P_K_NFC_ME_GPIM",
  "P_K_NFC_NRC_GPIM"
)
append_pending(new_ledger_rows(
  object_id = gpim_ids,
  object_label = gsub("_", " ", gpim_ids, fixed = TRUE),
  object_type = "downstream_owned_object",
  construction_stage = "S20_GPIM_construction",
  required_source_family = "NFC fixed-assets stock, investment, and CFC",
  analytical_role = "GPIM_capital_object",
  admissibility_status = "downstream_constructed_pending",
  notes = "Registered only; S10 does not construct GPIM stocks or prices."
))

frontier_ids <- c(
  "IPP_stock",
  "IPP_growth",
  "IPP_share_total_fixed_assets",
  "IPP_share_capital_plus_IPP",
  "IPP_to_Kcap",
  "GOV_TRANS_stock",
  "GOV_TRANS_growth",
  "GOV_TRANS_to_Kcap",
  "GOV_TRANS_to_NRC",
  "GOV_TRANS_to_ME"
)
append_pending(new_ledger_rows(
  object_id = frontier_ids,
  object_label = gsub("_", " ", frontier_ids, fixed = TRUE),
  object_type = "downstream_owned_object",
  construction_stage = "S20_frontier_conditioning",
  required_source_family = ifelse(
    startsWith(frontier_ids, "IPP"),
    "IPP fixed-assets ingredients",
    "GOV_TRANS fixed-assets ingredients"
  ),
  analytical_role = "frontier_conditioner",
  admissibility_status = "frontier_conditioner_pending",
  notes = ifelse(
    startsWith(frontier_ids, "IPP"),
    "IPP is excluded from K_cap and retained as a frontier conditioner.",
    paste(
      "GOV_TRANS is excluded from private K_cap and retained as a",
      "frontier conditioner."
    )
  )
))

distribution_ids <- c(
  "omega_CORP", "omega_NFC", "pi_res_CORP", "pi_res_NFC",
  "e_CORP", "e_NFC", "ln_e_CORP", "ln_e_NFC"
)
append_pending(new_ledger_rows(
  object_id = distribution_ids,
  object_label = gsub("_", " ", distribution_ids, fixed = TRUE),
  object_type = "downstream_owned_object",
  construction_stage = "S20_distribution_construction",
  required_source_family = "Unadjusted corporate/NFC income-account ingredients",
  analytical_role = c(
    "preferred_distributive_state",
    "preferred_distributive_state",
    "residual_profit_share",
    "residual_profit_share",
    rep("alternative_distributive_proxy", 4L)
  ),
  admissibility_status = c(
    "preferred_baseline_pending",
    "preferred_baseline_pending",
    "downstream_constructed_pending",
    "downstream_constructed_pending",
    rep("alternative_proxy_pending", 4L)
  ),
  notes = c(
    rep(
      "Unadjusted wage share is the first-pass baseline while the current-release protocol is blocked.",
      2L
    ),
    rep("Registered only; no distributive variable is constructed in S10.", 6L)
  )
))

q_ids <- c(
  "q_omega_h1_Kcap",
  "q_omega_h3_Kcap",
  "q_omega_h5_Kcap",
  "q_e_h1_Kcap",
  "q_e_h3_Kcap",
  "q_e_h5_Kcap"
)
append_pending(new_ledger_rows(
  object_id = q_ids,
  object_label = c(
    "Inherited one-period wage-share accumulated Kcap index",
    "Three-year wage-share accumulated Kcap index",
    "Five-year wage-share accumulated Kcap index",
    "Inherited one-period exploitation-rate accumulated Kcap index",
    "Three-year exploitation-rate accumulated Kcap index",
    "Five-year exploitation-rate accumulated Kcap index"
  ),
  object_type = "downstream_owned_object",
  construction_stage = "S30_A00_variable_construction",
  required_source_family = c(
    rep("K_cap growth and unadjusted wage share", 3L),
    rep("K_cap growth and unadjusted exploitation-rate proxy", 3L)
  ),
  analytical_role = c(
    "preferred_A00_accumulated_index",
    "preferred_A00_accumulated_index_robustness",
    "preferred_A00_accumulated_index_robustness",
    rep("alternative_proxy_accumulated_index_robustness", 3L)
  ),
  admissibility_status = c(
    "preferred_baseline_pending",
    "robustness_pending",
    "robustness_pending",
    rep("alternative_proxy_pending", 3L)
  ),
  notes = c(
    "Preferred A00 inherited one-period wage-share state; not constructed in S10.",
    "Restricted three-year wage-share robustness state; not constructed in S10.",
    "Restricted five-year wage-share robustness state; not constructed in S10.",
    rep(
      "Exploitation-rate alternative-proxy robustness object; not constructed in S10.",
      3L
    )
  )
))

shaikh_ids <- c(
  "BankMonIntPaid_t",
  "CorpNFNetImpIntPaid_t",
  "CorpImpIntAdj_t",
  "GVAcorp_adj_t",
  "NOScorp_adj_t",
  "VAcorp_adj_t",
  "omega_adj_CORP_t",
  "pi_adj_res_CORP_t",
  "e_adj_CORP_t"
)
append_pending(new_ledger_rows(
  object_id = shaikh_ids,
  object_label = gsub("_", " ", shaikh_ids, fixed = TRUE),
  object_type = "downstream_owned_object",
  construction_stage = "S20_current_release_Shaikh_protocol",
  required_source_family = c(
    rep("T711 candidate semantic-audit ingredients", 3L),
    rep("Protocol-approved corporate income-account adjustment", 3L),
    rep("Protocol-approved adjusted distribution objects", 3L)
  ),
  analytical_role = c(
    rep("Shaikh_style_interest_adjustment", 3L),
    rep("Shaikh_adjusted_income", 3L),
    "preferred_distributive_state_adjusted_variant",
    "adjusted_residual_profit_share",
    "alternative_distributive_proxy_adjusted_variant"
  ),
  admissibility_status = "blocked_pending_current_release_protocol",
  blocking_reason = paste(
    "Current BEA candidate lines are provenance/candidate ingredients only,",
    "not formula-admissible inputs."
  ),
  notes = "Registered as blocked; S10 constructs no Shaikh-adjusted variable."
))

legacy_ids <- c(
  "omega_x_Kcap",
  "omega_x_ME",
  "omega_x_NRC",
  "omega_x_ME_NRC_gap",
  "e_x_Kcap",
  "e_x_ME",
  "e_x_NRC",
  "e_x_ME_NRC_gap"
)
append_pending(new_ledger_rows(
  object_id = legacy_ids,
  object_label = gsub("_", " ", legacy_ids, fixed = TRUE),
  object_type = "downstream_owned_object",
  construction_stage = "S30_superseded_diagnostics",
  required_source_family = "Not applicable",
  analytical_role = "superseded_level_interaction",
  admissibility_status = "superseded_diagnostic_only",
  blocking_reason = paste(
    "Level interactions must not define A00, generated implementation",
    "variables, coefficient promotion, or S40 reconstruction."
  ),
  notes = "Diagnostic registry only; no level-interaction variable is created."
))

downstream_ledger <- do.call(rbind, pending_rows)
object_ledger <- rbind(provider_ledger, downstream_ledger)
object_ledger <- object_ledger[
  order(
    object_ledger$construction_stage,
    object_ledger$analytical_role,
    object_ledger$object_id
  ),
  ledger_columns,
  drop = FALSE
]
rownames(object_ledger) <- NULL

required_downstream_ids <- c(
  "K_ME", "K_NRC", "K_cap", "k_ME", "k_NRC", "k_Kcap",
  "g_K_ME", "g_K_NRC", "g_Kcap", "ME_NRC_gap", "ME_share", "NRC_share",
  gpim_ids,
  frontier_ids,
  distribution_ids,
  q_ids,
  shaikh_ids
)
missing_required_objects <- setdiff(
  required_downstream_ids,
  downstream_ledger$object_id
)
require_condition(
  length(missing_required_objects) == 0L,
  paste0(
    "Required downstream objects missing from S10 ledger:\n- ",
    paste(missing_required_objects, collapse = "\n- ")
  )
)

write.csv(
  source_panel,
  output_paths[["source_panel"]],
  row.names = FALSE,
  na = ""
)
write.csv(
  object_ledger,
  output_paths[["object_ledger"]],
  row.names = FALSE,
  na = ""
)

checks <- data.frame(
  check_id = character(),
  validation_check = character(),
  expected = character(),
  observed = character(),
  result = character(),
  stringsAsFactors = FALSE
)

add_check <- function(check_id, validation_check, expected, observed, pass) {
  checks <<- rbind(
    checks,
    data.frame(
      check_id = check_id,
      validation_check = validation_check,
      expected = as.character(expected),
      observed = as.character(observed),
      result = if (isTRUE(pass)) "PASS" else "FAIL",
      stringsAsFactors = FALSE
    )
  )
}

add_check(
  "provider_inputs_present",
  "All four locked provider inputs are present",
  4L,
  sum(file.exists(provider_paths)),
  all(file.exists(provider_paths))
)
add_check(
  "provider_only_paths",
  "All source files resolve inside the downstream provider directory",
  "provider-only paths",
  if (provider_only_inputs) "provider-only paths" else "path violation",
  provider_only_inputs
)
add_check(
  "no_bea_fetch",
  "No BEA fetch occurred",
  "local file reads only",
  "local provider artifacts read; no network/fetch function executed",
  TRUE
)
add_check("manifest_rows", "Manifest rows", 175L, nrow(manifest), nrow(manifest) == 175L)
add_check(
  "staged_variables",
  "Distinct staged source variables",
  94L,
  length(staged_ids),
  length(staged_ids) == 94L
)
add_check(
  "staged_observations",
  "Staged annual observations",
  9438L,
  nrow(staged),
  nrow(staged) == 9438L
)
add_check(
  "provenance_rows",
  "Provenance rows",
  175L,
  nrow(provenance),
  nrow(provenance) == 175L
)
add_check(
  "staged_ids_manifest",
  "Every staged variable_id exists in the manifest",
  "0 missing",
  paste0(length(missing_manifest_ids), " missing"),
  length(missing_manifest_ids) == 0L
)
add_check(
  "staged_ids_provenance",
  "Every staged variable_id exists in the provenance ledger",
  "0 missing",
  paste0(length(missing_provenance_ids), " missing"),
  length(missing_provenance_ids) == 0L
)
add_check(
  "source_panel_rows",
  "S10 source-panel rows",
  9438L,
  nrow(source_panel),
  nrow(source_panel) == 9438L
)
add_check(
  "source_panel_variables",
  "S10 source-panel distinct variable_id values",
  94L,
  length(unique(source_panel$variable_id)),
  length(unique(source_panel$variable_id)) == 94L
)
add_check(
  "required_objects_registered",
  "All required pending downstream objects are registered",
  length(required_downstream_ids),
  length(intersect(required_downstream_ids, downstream_ledger$object_id)),
  length(missing_required_objects) == 0L
)
add_check(
  "shaikh_blocked",
  "All Shaikh-style and adjusted contracts are blocked pending the current-release protocol",
  "all matched rows blocked",
  paste0(
    sum(
      object_ledger$admissibility_status ==
        "blocked_pending_current_release_protocol"
    ),
    " blocked rows"
  ),
  all(
    object_ledger$admissibility_status[
      object_ledger$object_id %in% shaikh_ids |
        grepl(
          "^(omega|pi|e|ln_e)_adj_",
          object_ledger$object_label
        )
    ] == "blocked_pending_current_release_protocol"
  )
)
add_check(
  "q_objects_pending",
  "All q_omega/q_e objects are pending and not constructed",
  length(q_ids),
  sum(downstream_ledger$object_id %in% q_ids),
  all(
    downstream_ledger$admissibility_status[
      match(q_ids, downstream_ledger$object_id)
    ] %in% c(
      "preferred_baseline_pending",
      "robustness_pending",
      "alternative_proxy_pending"
    )
  )
)
add_check(
  "frontier_roles",
  "IPP and GOV_TRANS objects remain frontier conditioners",
  length(frontier_ids),
  sum(
    downstream_ledger$object_id %in% frontier_ids &
      downstream_ledger$analytical_role == "frontier_conditioner"
  ),
  all(
    downstream_ledger$analytical_role[
      match(frontier_ids, downstream_ledger$object_id)
    ] == "frontier_conditioner"
  )
)
add_check(
  "level_interactions_superseded",
  "All level-interaction objects and provider contracts are superseded diagnostics only",
  "all matched rows superseded",
  paste0(
    sum(object_ledger$admissibility_status == "superseded_diagnostic_only"),
    " superseded rows"
  ),
  all(
    object_ledger$admissibility_status[
      object_ledger$object_id %in% legacy_ids |
        grepl("^(omega_x_|e_x_)", object_ledger$object_label)
    ] == "superseded_diagnostic_only"
  )
)
add_check(
  "no_gpim_constructed",
  "S10 constructs no GPIM stocks",
  "pending registry only",
  "pending registry only",
  TRUE
)
add_check(
  "no_shaikh_constructed",
  "S10 constructs no Shaikh-adjusted variables",
  "blocked registry only",
  "blocked registry only",
  TRUE
)
add_check(
  "no_regressions",
  "S10 estimates no regressions",
  "none",
  "none",
  TRUE
)

provider_hashes_after <- unname(tools::md5sum(provider_paths))
provider_unchanged <- identical(provider_hashes_before, provider_hashes_after)
add_check(
  "provider_artifacts_unchanged",
  "Provider artifacts are unchanged by S10",
  "all hashes unchanged",
  paste0(sum(provider_hashes_before == provider_hashes_after), "/4 unchanged"),
  provider_unchanged
)

checks <- checks[order(checks$check_id), , drop = FALSE]
rownames(checks) <- NULL
write.csv(
  checks,
  output_paths[["validation_checks"]],
  row.names = FALSE,
  na = ""
)

escape_markdown <- function(x) {
  gsub("|", "\\|", x, fixed = TRUE)
}

markdown_table <- function(data, columns = names(data)) {
  header <- paste0("|", paste(columns, collapse = "|"), "|")
  divider <- paste0("|", paste(rep("---", length(columns)), collapse = "|"), "|")
  body <- apply(
    data[columns],
    1L,
    function(row) {
      paste0(
        "|",
        paste(vapply(row, escape_markdown, character(1L)), collapse = "|"),
        "|"
      )
    }
  )
  c(header, divider, body)
}

overall_result <- if (all(checks$result == "PASS")) "PASS" else "FAIL"
status_counts <- as.data.frame(table(object_ledger$admissibility_status))
names(status_counts) <- c("Admissibility status", "Rows")
status_counts <- status_counts[order(status_counts[[1L]]), , drop = FALSE]

validation_lines <- c(
  "# U.S. S10 Source-of-Truth Scaffold Validation",
  "",
  paste0("**Overall result: ", overall_result, ".**"),
  "",
  "## Scope lock",
  "",
  "- S10 reads only from downstream provider artifacts.",
  "- S10 performs no BEA fetch.",
  "- S10 does not alter provider artifacts.",
  "- S10 does not construct GPIM stocks yet.",
  "- S10 does not construct Shaikh-adjusted variables.",
  "- S10 does not estimate regressions.",
  paste(
    "- S10 registers unadjusted wage share as the first-pass baseline",
    "pending construction."
  ),
  "- S10 registers all Shaikh-adjusted variables as blocked.",
  "- S10 preserves the q_omega/q_e accumulated-index locks.",
  "- S10 preserves IPP and GOV_TRANS as frontier conditioners.",
  paste(
    "- S10 is a source-of-truth scaffold, not the final model-ready",
    "dataset."
  ),
  "",
  "## Validation checks",
  "",
  markdown_table(
    checks,
    c("validation_check", "expected", "observed", "result")
  ),
  "",
  "## Output counts",
  "",
  paste0("- Source panel rows: ", nrow(source_panel)),
  paste0("- Object admissibility ledger rows: ", nrow(object_ledger)),
  paste0("- Provider validation checks: ", nrow(checks)),
  "",
  "## Locked analytical boundary",
  "",
  paste(
    "`q_omega_h1_Kcap` is the preferred inherited one-period A00 object.",
    "`q_omega_h3_Kcap` and `q_omega_h5_Kcap` are restricted robustness",
    "states. The `q_e_*` family is alternative-proxy robustness."
  ),
  paste(
    "All Shaikh-style adjusted objects remain",
    "`blocked_pending_current_release_protocol`; current T711 lines remain",
    "candidate provenance ingredients only."
  ),
  paste(
    "IPP and GOV_TRANS remain frontier conditioners and do not enter",
    "private `K_cap` as additive capital terms."
  )
)
writeLines(
  validation_lines,
  output_paths[["validation_report"]],
  useBytes = TRUE
)

downstream_report <- downstream_ledger[
  order(
    downstream_ledger$construction_stage,
    downstream_ledger$analytical_role,
    downstream_ledger$object_id
  ),
  c(
    "object_id",
    "construction_stage",
    "analytical_role",
    "admissibility_status",
    "blocking_reason"
  ),
  drop = FALSE
]

ledger_lines <- c(
  "# U.S. S10 Source-of-Truth Construction Ledger",
  "",
  "## Purpose",
  "",
  paste(
    "This ledger records provider ingredients and downstream-owned objects",
    "without constructing the pending analytical variables."
  ),
  "",
  "## Admissibility summary",
  "",
  markdown_table(status_counts),
  "",
  "## Downstream object registry",
  "",
  markdown_table(downstream_report),
  "",
  "## Locks",
  "",
  "- `K_cap = K_ME + K_NRC` is the preferred productive-capacity identity.",
  "- IPP and GOV_TRANS are frontier conditioners, not additive capital terms.",
  "- Unadjusted wage share is the first-pass preferred distributive state.",
  "- Exploitation rate is an alternative proxy.",
  "- `q_omega_*` is the preferred A00 accumulated-index family.",
  "- `q_e_*` is alternative-proxy robustness.",
  paste(
    "- `omega_x_*` and `e_x_*` level interactions are",
    "`superseded_diagnostic_only`."
  ),
  paste(
    "- Shaikh-adjusted objects are",
    "`blocked_pending_current_release_protocol`."
  ),
  "- S10 creates no GPIM, regression, capacity, or utilization object."
)
writeLines(
  ledger_lines,
  output_paths[["construction_ledger"]],
  useBytes = TRUE
)

if (overall_result != "PASS") {
  failed <- checks$validation_check[checks$result == "FAIL"]
  abort(
    paste0(
      "S10 validation failed:\n- ",
      paste(failed, collapse = "\n- ")
    )
  )
}

message("S10 source-of-truth scaffold validation passed.")
message("Source panel rows: ", nrow(source_panel))
message("Object ledger rows: ", nrow(object_ledger))
message("Validation checks: ", nrow(checks))
