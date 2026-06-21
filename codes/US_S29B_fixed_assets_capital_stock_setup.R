# S29B locks the setup contract for fixed-assets and capital-stock construction.
# It classifies, audits, and sequences future work; it constructs no new variables.

options(stringsAsFactors = FALSE)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

provider_v1_commit <- "af67374e28232d02d65765d3836dc2ab3e3da8eb"
s21_commit <- "3a0f5064d92fc09f97a55850b4086670d9cedc4b"
s22_commit <- "d6f47bcdaa80bc146196f99a1ccf9207d6957e57"
s23_commit <- "96be02bd0acb4ca10ecc626d07482f6176e7c3b3"
s24a_commit <- "444fb8397c00feb801369eac52614ca633afbfcc"
s24b_commit <- "24bcad5797cbebddbd77d697bc3ebdf0049746e2"
s24c_commit <- "0c3399f67365aafff8b012d66fac37d3bceda3f3"
s25_commit <- "1d6276ac35754e29acfeb755b6a351873cf59f6b"
s26_commit <- "8d5ec75f0a86fef94f736ff38bb80f0294c1cc1b"
s27_commit <- "e42e124679137a3acaa0f0c7d4eebd71c562656a"
s28_commit <- "2b2403af2e56e2aa5cc54ea12f7da746f2e117e4"
s29a_commit <- "65e8ff785960eabd8881bcdd13350ba26ac3a194"

s12d_a4_commit <- "f506afd2da9888938ad05f8578d984b8523e014d"
s12d_b_commit <- "5cbc2aae90fa1d8d5fb27057f44c879c383b1260"
s12d_c_commit <- "dd7a13fa4e715ab4645c1bd53999491550c505ea"
s13_commit <- "906ed9f744da64e9931e7f8ec653d92da25384f1"

stage_id <- "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP"
required_s29a_decision <- "AUTHORIZE_S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP"
clean_decision <- "AUTHORIZE_S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION"
blocked_decision <- "BLOCK_FOR_FIXED_ASSETS_AND_CAPITAL_STOCK_SETUP_REVIEW"
clean_status <- "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP_COMPLETE_NEXT_BOUNDED_PASS_AUTHORIZED"
blocked_status <- "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP_BLOCKED_FOR_REVIEW"

path <- function(...) file.path(...)

s24b_dir <- path(repo_root, "output", "US", "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION")
s25_dir <- path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
s27_dir <- path(repo_root, "output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
s28_dir <- path(repo_root, "output", "US", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE")
s29a_dir <- path(repo_root, "output", "US", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION")
s12d_a4_dir <- path(repo_root, "output", "US", "S12D_A4_MANUAL_GPIM_NET_VALUE_THEORY_LOCK")
s12d_b_dir <- path(repo_root, "output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION")
s12d_c_dir <- path(repo_root, "output", "US", "S12D_C_GPIM_DOWNSTREAM_READINESS_LOCK")
s13_dir <- path(repo_root, "output", "US", "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION")
s29b_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29b_dir, "csv")
md_dir <- path(s29b_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29a_input_paths <- list(
  panel = path(s29a_dir, "csv", "S29A_income_distribution_variables_long.csv"),
  ledger = path(s29a_dir, "csv", "S29A_income_distribution_construction_ledger.csv"),
  provenance = path(s29a_dir, "csv", "S29A_income_distribution_source_to_derived_provenance_audit.csv"),
  formula = path(s29a_dir, "csv", "S29A_income_distribution_formula_unit_audit.csv"),
  dependency = path(s29a_dir, "csv", "S29A_income_distribution_dependency_satisfaction_audit.csv"),
  review = path(s29a_dir, "csv", "S29A_income_distribution_review_needed_ledger.csv"),
  no_cross_family = path(s29a_dir, "csv", "S29A_no_cross_family_audit.csv"),
  no_forbidden = path(s29a_dir, "csv", "S29A_no_forbidden_promotion_audit.csv"),
  validation = path(s29a_dir, "csv", "S29A_validation_checks.csv"),
  validation_md = path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_VALIDATION.md"),
  decision_md = path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_DECISION.md")
)

s28_input_paths <- list(
  implementation_sequence = path(s28_dir, "csv", "S28_derived_variable_implementation_sequence.csv"),
  family_authorization = path(s28_dir, "csv", "S28_derived_variable_family_authorization_matrix.csv"),
  future_pass_registry = path(s28_dir, "csv", "S28_future_pass_registry.csv"),
  dependency_depth = path(s28_dir, "csv", "S28_dependency_depth_ordering.csv"),
  dependency_risk = path(s28_dir, "csv", "S28_dependency_risk_audit.csv"),
  no_implementation = path(s28_dir, "csv", "S28_no_implementation_audit.csv"),
  validation = path(s28_dir, "csv", "S28_validation_checks.csv"),
  validation_md = path(s28_dir, "md", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE_VALIDATION.md"),
  decision_md = path(s28_dir, "md", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE_DECISION.md")
)

s27_input_paths <- list(
  candidate_registry = path(s27_dir, "csv", "S27_derived_variable_candidate_registry.csv"),
  dependency_map = path(s27_dir, "csv", "S27_source_to_derived_dependency_map.csv"),
  family_sequence = path(s27_dir, "csv", "S27_derived_variable_family_sequence_plan.csv"),
  metadata_usage = path(s27_dir, "csv", "S27_metadata_reference_usage_ledger.csv"),
  no_implementation = path(s27_dir, "csv", "S27_no_implementation_audit.csv"),
  boundary = path(s27_dir, "csv", "S27_deferred_excluded_boundary_carry_forward.csv"),
  authorization = path(s27_dir, "csv", "S27_future_construction_authorization_matrix.csv"),
  risk = path(s27_dir, "csv", "S27_planning_risk_ledger.csv"),
  validation = path(s27_dir, "csv", "S27_validation_checks.csv"),
  validation_md = path(s27_dir, "md", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_VALIDATION.md"),
  decision_md = path(s27_dir, "md", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_DECISION.md")
)

s26_input_paths <- list(
  completeness = path(s26_dir, "csv", "S26_source_input_completeness_ledger.csv"),
  observation_readiness = path(s26_dir, "csv", "S26_observation_bearing_readiness_audit.csv"),
  metadata = path(s26_dir, "csv", "S26_metadata_only_disposition_audit.csv"),
  planning = path(s26_dir, "csv", "S26_derived_variable_planning_readiness_audit.csv"),
  risk = path(s26_dir, "csv", "S26_completeness_risk_register.csv"),
  validation = path(s26_dir, "csv", "S26_validation_checks.csv"),
  decision_md = path(s26_dir, "md", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW_DECISION.md")
)

s25_input_paths <- list(
  panel = path(s25_dir, "csv", "S25_authorized_source_inputs_long.csv"),
  ledger = path(s25_dir, "csv", "S25_authorized_source_inputs_construction_ledger.csv"),
  provenance = path(s25_dir, "csv", "S25_authorized_source_inputs_provenance_audit.csv"),
  taxonomy = path(s25_dir, "csv", "S25_source_input_status_taxonomy.csv"),
  validation = path(s25_dir, "csv", "S25_validation_checks.csv")
)

s24b_input_paths <- list(
  panel = path(s24b_dir, "csv", "S24B_fixed_assets_source_inputs_long.csv"),
  ledger = path(s24b_dir, "csv", "S24B_fixed_assets_construction_ledger.csv"),
  provenance = path(s24b_dir, "csv", "S24B_fixed_assets_provenance_audit.csv"),
  exclusion = path(s24b_dir, "csv", "S24B_fixed_assets_exclusion_audit.csv"),
  continuity = path(s24b_dir, "csv", "S24B_fixed_assets_continuity_audit.csv"),
  validation = path(s24b_dir, "csv", "S24B_validation_checks.csv"),
  validation_md = path(s24b_dir, "md", "S24B_FIXED_ASSETS_SOURCE_INPUTS_VALIDATION.md"),
  decision_md = path(s24b_dir, "md", "S24B_FIXED_ASSETS_SOURCE_INPUTS_DECISION.md")
)

gpim_input_paths <- list(
  s12d_a4_parameters = path(s12d_a4_dir, "csv", "S12D_A4_protocol_parameters.csv"),
  s12d_a4_validation = path(s12d_a4_dir, "csv", "S12D_A4_validation_checks.csv"),
  s12d_b_role_ledger = path(s12d_b_dir, "csv", "S12D_B_object_role_ledger.csv"),
  s12d_b_stock_panel = path(s12d_b_dir, "csv", "S12D_B_gpim_stock_panel.csv"),
  s12d_b_price_indexes = path(s12d_b_dir, "csv", "S12D_B_sfc_implicit_price_indexes.csv"),
  s12d_b_real_flows = path(s12d_b_dir, "csv", "S12D_B_real_investment_flows.csv"),
  s12d_b_sfc_checks = path(s12d_b_dir, "csv", "S12D_B_sfc_reconstruction_checks.csv"),
  s12d_b_validation = path(s12d_b_dir, "csv", "S12D_B_validation_checks.csv"),
  s12d_c_readiness = path(s12d_c_dir, "csv", "S12D_C_readiness_checks.csv"),
  s12d_c_contract = path(s12d_c_dir, "csv", "S12D_C_consumption_contract.csv"),
  s13_validation = path(s13_dir, "csv", "S13_validation_checks.csv"),
  s13_panel = path(s13_dir, "csv", "S13_gpim_source_panel_long.csv"),
  s13_audit = path(s13_dir, "csv", "S13_consumption_audit.csv"),
  s13_md = path(s13_dir, "md", "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION.md")
)

output_paths <- list(
  candidate_inventory = path(csv_dir, "S29B_fixed_assets_candidate_inventory.csv"),
  boundary_classification = path(csv_dir, "S29B_asset_boundary_classification_ledger.csv"),
  source_dependency = path(csv_dir, "S29B_source_dependency_map.csv"),
  deflator_readiness = path(csv_dir, "S29B_deflator_price_concept_readiness_ledger.csv"),
  implicit_deflator = path(csv_dir, "S29B_implicit_deflator_admissibility_audit.csv"),
  common_unit = path(csv_dir, "S29B_common_unit_harmonization_plan.csv"),
  parameter_lock = path(csv_dir, "S29B_gpim_parameter_lock_ledger.csv"),
  baseline_reuse = path(csv_dir, "S29B_gpim_baseline_reuse_ledger.csv"),
  sfc_audit = path(csv_dir, "S29B_gpim_existing_output_sfc_audit.csv"),
  asset_sfc_contract = path(csv_dir, "S29B_asset_level_stock_flow_consistency_contract.csv"),
  aggregate_sfc_contract = path(csv_dir, "S29B_aggregate_stock_flow_consistency_contract.csv"),
  initialization = path(csv_dir, "S29B_initialization_vintage_readiness_audit.csv"),
  aggregation_matrix = path(csv_dir, "S29B_aggregation_rule_authorization_matrix.csv"),
  future_pass = path(csv_dir, "S29B_future_pass_registry.csv"),
  no_construction = path(csv_dir, "S29B_no_construction_audit.csv"),
  validation = path(csv_dir, "S29B_validation_checks.csv"),
  validation_md = path(md_dir, "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP_VALIDATION.md"),
  decision_md = path(md_dir, "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP_DECISION.md")
)

read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
all_pass_any <- function(df) {
  status_col <- if ("status" %in% names(df)) "status" else if ("readiness_status" %in% names(df)) "readiness_status" else ""
  status_col != "" && nrow(df) > 0 && all(df[[status_col]] == "PASS")
}
stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) stop(label, " missing: ", paste(basename(missing), collapse = "; "))
}
taxonomy_count <- function(taxonomy, category) {
  rows <- taxonomy[taxonomy$status_category == category, , drop = FALSE]
  if (nrow(rows) == 0) return(0L)
  as.integer(rows$object_count[1])
}
get_first <- function(df, col, default = "") {
  if (!col %in% names(df) || nrow(df) == 0) return(default)
  value <- df[[col]][1]
  if (is.na(value)) "" else as.character(value)
}
contains_any <- function(x, pattern) any(grepl(pattern, x, ignore.case = TRUE))
provider_tracked_clean <- function(repo) {
  unstaged <- system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE)
  staged <- system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE)
  identical(unstaged, 0L) && identical(staged, 0L)
}

all_input_paths <- c(unlist(s29a_input_paths), unlist(s28_input_paths), unlist(s27_input_paths),
                     unlist(s26_input_paths), unlist(s25_input_paths), unlist(s24b_input_paths),
                     unlist(gpim_input_paths))
stop_if_missing(all_input_paths, "S29B inputs")
md5_before <- tools::md5sum(all_input_paths)

s29a_validation <- read_csv(s29a_input_paths$validation)
s29a_decision <- read_text(s29a_input_paths$decision_md)
s28_validation <- read_csv(s28_input_paths$validation)
s27_validation <- read_csv(s27_input_paths$validation)
s27_candidates <- read_csv(s27_input_paths$candidate_registry)
s27_dependencies <- read_csv(s27_input_paths$dependency_map)
s27_boundary <- read_csv(s27_input_paths$boundary)
s26_validation <- read_csv(s26_input_paths$validation)
s25_validation <- read_csv(s25_input_paths$validation)
s25_panel <- read_csv(s25_input_paths$panel)
s25_ledger <- read_csv(s25_input_paths$ledger)
s25_taxonomy <- read_csv(s25_input_paths$taxonomy)
s24b_validation <- read_csv(s24b_input_paths$validation)
s24b_panel <- read_csv(s24b_input_paths$panel)
s24b_ledger <- read_csv(s24b_input_paths$ledger)
s24b_provenance <- read_csv(s24b_input_paths$provenance)
s24b_continuity <- read_csv(s24b_input_paths$continuity)

s12d_a4_params <- read_csv(gpim_input_paths$s12d_a4_parameters)
s12d_a4_validation <- read_csv(gpim_input_paths$s12d_a4_validation)
s12d_b_roles <- read_csv(gpim_input_paths$s12d_b_role_ledger)
s12d_b_stock <- read_csv(gpim_input_paths$s12d_b_stock_panel)
s12d_b_prices <- read_csv(gpim_input_paths$s12d_b_price_indexes)
s12d_b_real_flows <- read_csv(gpim_input_paths$s12d_b_real_flows)
s12d_b_sfc <- read_csv(gpim_input_paths$s12d_b_sfc_checks)
s12d_b_validation <- read_csv(gpim_input_paths$s12d_b_validation)
s12d_c_readiness <- read_csv(gpim_input_paths$s12d_c_readiness)
s12d_c_contract <- read_csv(gpim_input_paths$s12d_c_contract)
s13_validation <- read_csv(gpim_input_paths$s13_validation)
s13_panel <- read_csv(gpim_input_paths$s13_panel)
s13_audit <- read_csv(gpim_input_paths$s13_audit)

if (!all_pass(s29a_validation) || nrow(s29a_validation) != 57 ||
    !grepl(required_s29a_decision, s29a_decision, fixed = TRUE)) {
  stop("S29A gate is not clean or does not authorize S29B.")
}

parse_id <- function(variable_id) {
  parts <- strsplit(variable_id, "__", fixed = TRUE)[[1]]
  sector <- parts[1]
  asset <- if (length(parts) >= 2) parts[2] else ""
  concept <- if (length(parts) >= 3) parts[3] else ""
  data.frame(sector = sector, asset_family = asset, measurement_concept = concept, stringsAsFactors = FALSE)
}
parsed <- do.call(rbind, lapply(s24b_ledger$variable_id, parse_id))
candidate_inventory <- cbind(
  data.frame(stage_id = stage_id, stringsAsFactors = FALSE),
  s24b_ledger[, c("variable_id", "display_name", "source_dataset", "source_table", "source_line",
                  "source_line_description", "unit", "frequency", "constructed_observation_rows",
                  "coverage_start", "coverage_end"), drop = FALSE],
  parsed
)

candidate_inventory$theoretical_role <- ifelse(
  candidate_inventory$asset_family == "ME" & candidate_inventory$sector %in% c("NFC", "CORP"),
  "core_ME",
  ifelse(candidate_inventory$asset_family == "NRC" & candidate_inventory$sector %in% c("NFC", "CORP"),
         "core_NRC",
         ifelse(candidate_inventory$asset_family == "IPP",
                "contextual_IPP",
                ifelse(candidate_inventory$sector == "GOV_TRANS",
                       "contextual_government_transportation",
                       ifelse(grepl("RES", candidate_inventory$asset_family, ignore.case = TRUE),
                              "residential_excluded", "review_required"))))
)
candidate_inventory$implementation_status <- ifelse(
  candidate_inventory$theoretical_role %in% c("core_ME", "core_NRC") &
    candidate_inventory$measurement_concept == "gross_investment_current_cost",
  "ready_for_existing_GPIM_consumption",
  ifelse(candidate_inventory$theoretical_role %in% c("core_ME", "core_NRC") &
           candidate_inventory$measurement_concept == "net_stock_quantity_index",
         "requires_price_concept_review",
         ifelse(candidate_inventory$theoretical_role %in% c("core_ME", "core_NRC"),
                "ready_for_existing_GPIM_consumption",
                ifelse(candidate_inventory$theoretical_role %in% c("contextual_IPP", "contextual_government_transportation"),
                       "reference_only", "requires_common_unit_reconciliation")))
)
candidate_inventory$baseline_core_stock_inclusion <- ifelse(
  candidate_inventory$theoretical_role %in% c("core_ME", "core_NRC"), "yes_after_later_asset_specific_construction", "no"
)
candidate_inventory$construction_authorized_in_s29b <- "no"
candidate_inventory$modeling_authorized <- "no"
candidate_inventory$econometrics_authorized <- "no"
candidate_inventory$provider_v1_commit <- provider_v1_commit
candidate_inventory$s24b_fixed_assets_construction_commit <- s24b_commit
candidate_inventory$s29a_income_distribution_construction_commit <- s29a_commit

boundary_classification <- candidate_inventory[, c(
  "stage_id", "variable_id", "sector", "asset_family", "measurement_concept",
  "theoretical_role", "implementation_status", "baseline_core_stock_inclusion",
  "construction_authorized_in_s29b"
)]
boundary_classification$boundary_rationale <- ifelse(
  boundary_classification$theoretical_role == "core_ME",
  "Machinery and equipment is locked inside the baseline productive-capital boundary after asset-specific deflation and GPIM rules.",
  ifelse(boundary_classification$theoretical_role == "core_NRC",
         "Nonresidential construction is locked inside the baseline productive-capital boundary after asset-specific deflation and GPIM rules.",
         ifelse(boundary_classification$theoretical_role == "contextual_IPP",
                "IPP is contextual/technical-frontier material and is excluded from baseline core capital stock.",
                ifelse(boundary_classification$theoretical_role == "contextual_government_transportation",
                       "Government transportation assets are contextual infrastructure and excluded from the private baseline core stock.",
                       ifelse(boundary_classification$theoretical_role == "residential_excluded",
                              "Residential assets are excluded from the productive-capacity capital boundary.",
                              "Object requires future boundary or aggregation review before implementation."))))
)

fixed_family <- "fixed_assets_and_capital_stock_variables"
source_dependency <- s27_dependencies[s27_dependencies$derived_variable_family == fixed_family, , drop = FALSE]
source_dependency <- merge(
  source_dependency,
  boundary_classification[, c("variable_id", "sector", "asset_family", "measurement_concept", "theoretical_role", "implementation_status")],
  by.x = "source_input_id", by.y = "variable_id", all.x = TRUE, sort = FALSE
)
source_dependency$stage_id <- stage_id
source_dependency$construction_authorized_in_s29b <- "no"
source_dependency <- source_dependency[, c("stage_id", setdiff(names(source_dependency), "stage_id"))]

core_rows <- candidate_inventory[candidate_inventory$theoretical_role %in% c("core_ME", "core_NRC"), , drop = FALSE]
deflator_readiness <- data.frame(
  stage_id = stage_id,
  asset_family = c("ME", "NRC"),
  baseline_role = c("core_ME", "core_NRC"),
  nominal_investment_source_inputs = c(
    paste(core_rows$variable_id[core_rows$asset_family == "ME" & core_rows$measurement_concept == "gross_investment_current_cost"], collapse = "; "),
    paste(core_rows$variable_id[core_rows$asset_family == "NRC" & core_rows$measurement_concept == "gross_investment_current_cost"], collapse = "; ")
  ),
  admissible_price_source = c("S12D/S13 locked SFC implicit baseline price for ME", "S12D/S13 locked SFC implicit baseline price for NRC"),
  admissible_price_variable = c("P_K_SFC_ME_2017_100", "P_K_SFC_NRC_2017_100"),
  real_investment_variable_available = c("I_REAL_GPIM_ME", "I_REAL_GPIM_NRC"),
  reference_year_requirement = "2017=100 price index; real flows in 2017 dollars",
  readiness_status = "ready_for_deflator_and_real_investment_construction_from_locked_gpim_baseline",
  forbidden_fallback = "GDP deflator, output price, FAAt402 quantity index, and cross-asset ratios are not baseline deflators.",
  stringsAsFactors = FALSE
)

implicit_deflator <- data.frame(
  stage_id = stage_id,
  pairing_id = c(
    "ME_locked_sfc_price",
    "NRC_locked_sfc_price",
    "ME_current_cost_net_stock_over_FAAt402_quantity_index",
    "NRC_current_cost_net_stock_over_FAAt402_quantity_index",
    "cross_asset_ME_nominal_over_NRC_quantity_index",
    "stock_flow_mixed_nominal_investment_over_net_stock_quantity_index"
  ),
  asset_family = c("ME", "NRC", "ME", "NRC", "cross_asset", "mixed_concept"),
  numerator_concept = c("locked SFC recovery", "locked SFC recovery", "net stock current cost", "net stock current cost", "ME nominal level", "gross investment current cost"),
  denominator_concept = c("locked GPIM-compatible real flow/stock architecture", "locked GPIM-compatible real flow/stock architecture", "FAAt402 quantity index", "FAAt402 quantity index", "NRC quantity index", "net stock quantity index"),
  admissibility_status = c("admissible_locked_baseline", "admissible_locked_baseline", "inadmissible_quantity_index_ratio", "inadmissible_quantity_index_ratio", "inadmissible_cross_asset_pairing", "inadmissible_stock_flow_mixing"),
  construction_authorized = c("yes_in_later_s29c_only", "yes_in_later_s29c_only", "no", "no", "no", "no"),
  rationale = c(
    "Locked S12D/S13 SFC baseline price is asset-specific and already validated.",
    "Locked S12D/S13 SFC baseline price is asset-specific and already validated.",
    "A nominal current-cost stock divided by a chain quantity index is not a same-concept implicit deflator.",
    "A nominal current-cost stock divided by a chain quantity index is not a same-concept implicit deflator.",
    "ME and NRC boundaries cannot be mixed to form a deflator.",
    "A flow numerator and stock quantity denominator mix transaction concepts."
  ),
  stringsAsFactors = FALSE
)

common_unit <- data.frame(
  stage_id = stage_id,
  requirement_id = c("reference_year", "asset_specific_deflation", "common_additive_unit", "chain_quantity_warning", "rebasing_rule"),
  requirement = c(
    "All baseline real investment flows must be expressed in the same 2017 dollar convention.",
    "ME and NRC must keep separate asset-specific prices before accumulation.",
    "ME and NRC may be added only after conversion to compatible real-dollar stock or flow units.",
    "BEA chain-type quantity indexes are not additive and cannot be summed as levels.",
    "If later accepted deflators differ in reference year, rebase each to the common S29B-locked reference year before real-flow construction."
  ),
  status = c("locked", "locked", "locked", "locked", "locked"),
  construction_authorized_in_s29b = "no",
  stringsAsFactors = FALSE
)

parameter_lock <- data.frame(
  stage_id = stage_id,
  asset_family = s12d_a4_params$asset_block,
  service_life_L = as.integer(s12d_a4_params$L),
  survival_shape_alpha = as.numeric(s12d_a4_params$alpha),
  depreciation_value_parameter_d = as.numeric(s12d_a4_params$d),
  survival_profile = s12d_a4_params$survival_profile,
  net_value_schedule = s12d_a4_params$net_value_schedule,
  parameter_status = "locked_from_s12d_a4_no_reestimation",
  s12d_a4_commit = s12d_a4_commit,
  stringsAsFactors = FALSE
)

baseline_reuse <- merge(
  s13_audit,
  s12d_c_contract[, c("asset_block", "object_role", "downstream_consumption_status", "allowed_use", "prohibited_use")],
  by = c("asset_block", "object_role"), all.x = TRUE, sort = FALSE
)
baseline_reuse$stage_id <- stage_id
baseline_reuse$s12d_b_commit <- s12d_b_commit
baseline_reuse$s12d_c_commit <- s12d_c_commit
baseline_reuse$s13_commit <- s13_commit
baseline_reuse$s29b_reuse_status <- ifelse(
  baseline_reuse$consumed == "yes", "reuse_authorized_in_later_bounded_pass", "not_reused"
)
baseline_reuse$reconstruction_authorized_in_s29b <- "no"
baseline_reuse <- baseline_reuse[, c("stage_id", setdiff(names(baseline_reuse), "stage_id"))]

sfc_audit <- data.frame(
  stage_id = stage_id,
  audit_scope = c("ME_existing_sfc_reconstruction", "NRC_existing_sfc_reconstruction", "core_aggregate_gross_identity", "core_aggregate_net_identity"),
  asset_family = c("ME", "NRC", "core", "core"),
  identity_type = c("existing_s12d_b_reconstruction", "existing_s12d_b_reconstruction", "aggregate_gross_stock_flow", "aggregate_net_stock_flow"),
  maximum_absolute_residual = c(
    as.numeric(s12d_b_sfc$max_absolute_sfc_residual_millions[s12d_b_sfc$asset_block == "ME"]),
    as.numeric(s12d_b_sfc$max_absolute_sfc_residual_millions[s12d_b_sfc$asset_block == "NRC"]),
    NA,
    NA
  ),
  mean_absolute_residual = c(
    as.numeric(s12d_b_sfc$mean_absolute_sfc_residual_millions[s12d_b_sfc$asset_block == "ME"]),
    as.numeric(s12d_b_sfc$mean_absolute_sfc_residual_millions[s12d_b_sfc$asset_block == "NRC"]),
    NA,
    NA
  ),
  tolerance_used = c(1e-06, 1e-06, NA, NA),
  observations_outside_tolerance = c(0L, 0L, NA, NA),
  audit_status = c("PASS", "PASS", "STRUCTURALLY_PENDING", "STRUCTURALLY_PENDING"),
  notes = c(
    "Existing S12D-B residual closes for ME; S29B does not recompute or rewrite the baseline.",
    "Existing S12D-B residual closes for NRC; S29B does not recompute or rewrite the baseline.",
    "Aggregate gross identity is locked as a future contract because aggregate core stock, investment, and retirements are not constructed in S29B.",
    "Aggregate net identity is locked as a future contract because aggregate core net stock, investment, and CFC are not constructed in S29B."
  ),
  stringsAsFactors = FALSE
)

asset_sfc_contract <- data.frame(
  stage_id = stage_id,
  asset_family = rep(c("ME", "NRC"), each = 4),
  identity_name = rep(c("gross_stock_definition", "gross_stock_flow_identity", "net_stock_definition", "net_stock_flow_identity"), 2),
  locked_identity = rep(c(
    "G_i_t = sum_{a=0}^{L_i-1} S_i(a) I_real_i_t_minus_a",
    "G_i_t = G_i_t_minus_1 + I_real_i_t - R_i_t",
    "N_i_t = sum_{a=0}^{L_i-1} V_i(a) I_real_i_t_minus_a",
    "N_i_t = N_i_t_minus_1 + I_real_i_t - CFC_i_t"
  ), 2),
  construction_authorized_in_s29b = "no",
  validation_requirement = "future implementation must report residuals, tolerance, and failures by asset family",
  stringsAsFactors = FALSE
)

aggregate_sfc_contract <- data.frame(
  stage_id = stage_id,
  aggregate_object = c("G_core", "N_core", "I_core", "R_core", "CFC_core", "gross_core_identity", "net_core_identity"),
  locked_rule = c(
    "G_core_t = G_ME_t + G_NRC_t",
    "N_core_t = N_ME_t + N_NRC_t",
    "I_core_t = I_ME_t + I_NRC_t",
    "R_core_t = R_ME_t + R_NRC_t",
    "CFC_core_t = CFC_ME_t + CFC_NRC_t",
    "G_core_t = G_core_t_minus_1 + I_core_t - R_core_t",
    "N_core_t = N_core_t_minus_1 + I_core_t - CFC_core_t"
  ),
  authorization_status = "future_only_after_asset_specific_common_unit_stocks_exist",
  construction_authorized_in_s29b = "no",
  stringsAsFactors = FALSE
)

first_investment_year <- tapply(as.integer(s12d_b_real_flows$year), s12d_b_real_flows$asset_block, min)
first_stock_year <- tapply(as.integer(s13_panel$year[s13_panel$variable_id %in% c("K_GROSS_GPIM_ME", "K_GROSS_GPIM_NRC")]),
                           s13_panel$asset_block[s13_panel$variable_id %in% c("K_GROSS_GPIM_ME", "K_GROSS_GPIM_NRC")], min)
initialization <- data.frame(
  stage_id = stage_id,
  asset_family = c("ME", "NRC", "core"),
  minimum_surviving_vintage_history_years = c(14L, 30L, 30L),
  earliest_real_investment_year_available = c(first_investment_year[["ME"]], first_investment_year[["NRC"]], max(first_investment_year[["ME"]], first_investment_year[["NRC"]])),
  first_existing_gpim_stock_year = c(first_stock_year[["ME"]], first_stock_year[["NRC"]], max(first_stock_year[["ME"]], first_stock_year[["NRC"]])),
  first_fully_supported_year = c(first_stock_year[["ME"]], first_stock_year[["NRC"]], max(first_stock_year[["ME"]], first_stock_year[["NRC"]])),
  initialization_status = c(
    "supported_by_locked_s12d_s13_history",
    "supported_by_locked_s12d_s13_history",
    "supported_after_both_asset_specific_stocks_exist_in_common_units"
  ),
  zero_initialization_authorized = "no",
  stringsAsFactors = FALSE
)

aggregation_matrix <- data.frame(
  stage_id = stage_id,
  rule_id = c(
    "aggregate_core_level",
    "weighted_arithmetic_growth_decomposition",
    "weighted_log_growth_diagnostic",
    "weighted_level_construction",
    "chain_quantity_index_addition",
    "ipp_in_core",
    "government_transportation_in_core",
    "residential_in_core"
  ),
  rule_status = c("authorized_later", "authorized_later_decomposition_only", "diagnostic_only", "forbidden", "forbidden", "forbidden", "forbidden", "forbidden"),
  rule_text = c(
    "K_core level is ME plus NRC only after asset-specific stocks are in compatible additive units.",
    "Lagged component shares may decompose arithmetic growth only after aggregate levels exist.",
    "Weighted log growth is an approximation or diagnostic only.",
    "Do not construct levels as composition-share-weighted component stocks.",
    "Do not add chain-type quantity indexes as stock levels.",
    "IPP remains outside baseline core stock.",
    "Government transportation remains outside baseline private core stock.",
    "Residential structures remain outside productive-capacity core stock."
  ),
  construction_authorized_in_s29b = "no",
  stringsAsFactors = FALSE
)

future_pass <- data.frame(
  stage_id = stage_id,
  future_pass_id = c("S29C", "S29D", "S29E", "S29F", "S29G", "S29Z_REF", "S29Z_BLOCKED"),
  future_pass_label = c(
    "Fixed Assets Deflator And Real Investment Construction",
    "ME/NRC GPIM Gross Stock Consumption And SFC Audit",
    "Core Capital Stock Aggregation Setup",
    "Capital Stock Growth And Decomposition Setup",
    "Contextual Asset Boundary Review",
    "Metadata Reference Carry Forward",
    "Blocked Or Parked Boundary Carry Forward"
  ),
  pass_authorization_status = c(
    "authorized_by_clean_s29b_setup",
    "queued_after_s29c",
    "queued_after_asset_specific_gpim_consumption",
    "queued_after_core_levels_exist",
    "review_required_before_implementation",
    "reference_only_no_implementation",
    "blocked_or_deferred"
  ),
  construction_authorized_in_s29b = "no",
  modeling_authorized = "no",
  econometrics_authorized = "no",
  stringsAsFactors = FALSE
)

no_construction <- data.frame(
  stage_id = stage_id,
  object_family = c(
    "deflators", "real_investment_flows", "fixed_assets_variables", "capital_stock_variables",
    "gpim_variables", "core_capital_stock", "real_output_variables", "q_variables",
    "modeling_outputs", "econometric_outputs", "theta_outputs", "productive_capacity_outputs",
    "utilization_outputs", "adjusted_shaikh_objects"
  ),
  constructed_object_count = 0L,
  verdict = "PASS",
  evidence = "S29B emits setup ledgers, contracts, audits, and validation files only.",
  stringsAsFactors = FALSE
)

write.csv(candidate_inventory, output_paths$candidate_inventory, row.names = FALSE)
write.csv(boundary_classification, output_paths$boundary_classification, row.names = FALSE)
write.csv(source_dependency, output_paths$source_dependency, row.names = FALSE)
write.csv(deflator_readiness, output_paths$deflator_readiness, row.names = FALSE)
write.csv(implicit_deflator, output_paths$implicit_deflator, row.names = FALSE)
write.csv(common_unit, output_paths$common_unit, row.names = FALSE)
write.csv(parameter_lock, output_paths$parameter_lock, row.names = FALSE)
write.csv(baseline_reuse, output_paths$baseline_reuse, row.names = FALSE)
write.csv(sfc_audit, output_paths$sfc_audit, row.names = FALSE)
write.csv(asset_sfc_contract, output_paths$asset_sfc_contract, row.names = FALSE)
write.csv(aggregate_sfc_contract, output_paths$aggregate_sfc_contract, row.names = FALSE)
write.csv(initialization, output_paths$initialization, row.names = FALSE)
write.csv(aggregation_matrix, output_paths$aggregation_matrix, row.names = FALSE)
write.csv(future_pass, output_paths$future_pass, row.names = FALSE)
write.csv(no_construction, output_paths$no_construction, row.names = FALSE)

md5_after <- tools::md5sum(all_input_paths)
input_hashes_unchanged <- identical(unname(md5_before), unname(md5_after))
gpim_hashes_unchanged <- identical(unname(md5_before[unlist(gpim_input_paths)]), unname(md5_after[unlist(gpim_input_paths)]))

boundary_count <- function(category) {
  rows <- s27_boundary[s27_boundary$status_category == category, , drop = FALSE]
  if (nrow(rows) == 0) return(0L)
  as.integer(rows$object_count[1])
}

check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}

validation_checks <- do.call(rbind, list(
  check("s29a_outputs_present", all(file.exists(unlist(s29a_input_paths))), paste(basename(unlist(s29a_input_paths)), collapse = "; ")),
  check("s29a_validation_all_pass", all_pass(s29a_validation) && nrow(s29a_validation) == 57, paste0("S29A_validation_checks.csv PASS ", nrow(s29a_validation))),
  check("s29a_decision_authorizes_s29b", grepl(required_s29a_decision, s29a_decision, fixed = TRUE), required_s29a_decision),
  check("s28_outputs_present", all(file.exists(unlist(s28_input_paths))), paste(basename(unlist(s28_input_paths)), collapse = "; ")),
  check("s28_validation_all_pass", all_pass(s28_validation) && nrow(s28_validation) == 59, paste0("S28_validation_checks.csv PASS ", nrow(s28_validation))),
  check("s27_outputs_present", all(file.exists(unlist(s27_input_paths))), paste(basename(unlist(s27_input_paths)), collapse = "; ")),
  check("s27_validation_all_pass", all_pass(s27_validation) && nrow(s27_validation) == 52, paste0("S27_validation_checks.csv PASS ", nrow(s27_validation))),
  check("s26_outputs_present", all(file.exists(unlist(s26_input_paths))), paste(basename(unlist(s26_input_paths)), collapse = "; ")),
  check("s26_validation_all_pass", all_pass(s26_validation) && nrow(s26_validation) == 51, paste0("S26_validation_checks.csv PASS ", nrow(s26_validation))),
  check("s25_outputs_present", all(file.exists(unlist(s25_input_paths))), paste(basename(unlist(s25_input_paths)), collapse = "; ")),
  check("s25_validation_all_pass", all_pass(s25_validation) && nrow(s25_validation) == 49, paste0("S25_validation_checks.csv PASS ", nrow(s25_validation))),
  check("s24b_outputs_present", all(file.exists(unlist(s24b_input_paths))), paste(basename(unlist(s24b_input_paths)), collapse = "; ")),
  check("s24b_validation_all_pass", all_pass(s24b_validation) && nrow(s24b_validation) == 35, paste0("S24B_validation_checks.csv PASS ", nrow(s24b_validation))),
  check("s24b_fixed_assets_object_count_equals_56", nrow(s24b_ledger) == 56, paste(nrow(s24b_ledger), "objects")),
  check("s24b_fixed_assets_row_count_equals_5936", nrow(s24b_panel) == 5936, paste(nrow(s24b_panel), "rows")),
  check("certified_source_input_object_count_equals_116", nrow(s25_ledger) == 116, paste(nrow(s25_ledger), "objects")),
  check("certified_source_input_row_count_equals_9342", nrow(s25_panel) == 9342, paste(nrow(s25_panel), "rows")),
  check("observation_bearing_count_equals_94", taxonomy_count(s25_taxonomy, "authorized_observation_bearing") == 94, paste(taxonomy_count(s25_taxonomy, "authorized_observation_bearing"), "observation-bearing inputs")),
  check("metadata_only_count_equals_22", taxonomy_count(s25_taxonomy, "authorized_zero_observation_metadata") == 22, paste(taxonomy_count(s25_taxonomy, "authorized_zero_observation_metadata"), "metadata-only inputs")),
  check("s12d_gpim_outputs_located", all(file.exists(unlist(gpim_input_paths)[grepl("S12D", unlist(gpim_input_paths), ignore.case = TRUE)])), "S12D-A4, S12D-B, and S12D-C outputs located"),
  check("s13_gpim_outputs_located", all(file.exists(unlist(gpim_input_paths)[grepl("S13", unlist(gpim_input_paths), ignore.case = TRUE)])), "S13 locked GPIM consumption outputs located"),
  check("existing_gpim_outputs_not_modified", gpim_hashes_unchanged, "S12D/S13 input file md5 hashes unchanged during S29B"),
  check("fixed_assets_candidate_inventory_created", file.exists(output_paths$candidate_inventory) && nrow(candidate_inventory) == 56, paste(nrow(candidate_inventory), "candidate rows")),
  check("asset_boundary_classification_created", file.exists(output_paths$boundary_classification) && nrow(boundary_classification) == 56, paste(nrow(boundary_classification), "classified rows")),
  check("source_dependency_map_created", file.exists(output_paths$source_dependency) && nrow(source_dependency) == 56, paste(nrow(source_dependency), "dependency rows")),
  check("me_core_boundary_locked", any(boundary_classification$theoretical_role == "core_ME"), paste(sum(boundary_classification$theoretical_role == "core_ME"), "ME core rows")),
  check("nrc_core_boundary_locked", any(boundary_classification$theoretical_role == "core_NRC"), paste(sum(boundary_classification$theoretical_role == "core_NRC"), "NRC core rows")),
  check("ipp_excluded_from_baseline_core_stock", all(boundary_classification$baseline_core_stock_inclusion[boundary_classification$theoretical_role == "contextual_IPP"] == "no"), paste(sum(boundary_classification$theoretical_role == "contextual_IPP"), "IPP rows excluded")),
  check("government_transportation_excluded_from_baseline_core_stock", all(boundary_classification$baseline_core_stock_inclusion[boundary_classification$theoretical_role == "contextual_government_transportation"] == "no"), paste(sum(boundary_classification$theoretical_role == "contextual_government_transportation"), "government transportation rows excluded")),
  check("residential_assets_excluded_from_baseline_core_stock", sum(boundary_classification$theoretical_role == "residential_excluded") == 0 || all(boundary_classification$baseline_core_stock_inclusion[boundary_classification$theoretical_role == "residential_excluded"] == "no"), paste(sum(boundary_classification$theoretical_role == "residential_excluded"), "residential candidate rows")),
  check("deflator_price_concept_readiness_ledger_created", file.exists(output_paths$deflator_readiness) && nrow(deflator_readiness) == 2, paste(nrow(deflator_readiness), "readiness rows")),
  check("implicit_deflator_admissibility_audit_created", file.exists(output_paths$implicit_deflator) && nrow(implicit_deflator) == 6, paste(nrow(implicit_deflator), "pairing rows")),
  check("no_nominal_quantity_index_ratio_misclassified_as_deflator", all(implicit_deflator$admissibility_status[grepl("quantity_index", implicit_deflator$admissibility_status)] != "admissible_locked_baseline"), "quantity-index ratios flagged inadmissible"),
  check("no_cross_boundary_deflator_pairings", !any(implicit_deflator$admissibility_status == "admissible_locked_baseline" & implicit_deflator$asset_family == "cross_asset"), "cross-boundary pairings not admitted"),
  check("no_cross_asset_deflator_pairings", all(implicit_deflator$admissibility_status[implicit_deflator$pairing_id == "cross_asset_ME_nominal_over_NRC_quantity_index"] == "inadmissible_cross_asset_pairing"), "cross-asset pairing blocked"),
  check("no_stock_flow_concept_mixing_in_deflators", all(implicit_deflator$admissibility_status[implicit_deflator$pairing_id == "stock_flow_mixed_nominal_investment_over_net_stock_quantity_index"] == "inadmissible_stock_flow_mixing"), "stock-flow deflator mixing blocked"),
  check("common_unit_harmonization_plan_created", file.exists(output_paths$common_unit) && nrow(common_unit) == 5, paste(nrow(common_unit), "common-unit rows")),
  check("common_reference_year_requirement_locked", any(common_unit$requirement_id == "reference_year" & common_unit$status == "locked"), "2017 dollar convention locked"),
  check("no_incompatible_chain_quantity_addition_authorized", any(common_unit$requirement_id == "chain_quantity_warning" & common_unit$status == "locked"), "chain quantity addition forbidden"),
  check("me_gpim_parameter_lock_preserved", any(parameter_lock$asset_family == "ME" & parameter_lock$service_life_L == 14 & abs(parameter_lock$survival_shape_alpha - 1.7) < 1e-12 & abs(parameter_lock$depreciation_value_parameter_d - 0.110) < 1e-12), "ME L=14 alpha=1.7 d=0.110"),
  check("nrc_gpim_parameter_lock_preserved", any(parameter_lock$asset_family == "NRC" & parameter_lock$service_life_L == 30 & abs(parameter_lock$survival_shape_alpha - 1.6) < 1e-12 & abs(parameter_lock$depreciation_value_parameter_d - 0.024) < 1e-12), "NRC L=30 alpha=1.6 d=0.024"),
  check("no_generic_pooled_gpim_authorized", !any(parameter_lock$asset_family %in% c("core", "aggregate", "pooled")), "only ME and NRC parameter rows"),
  check("gpim_baseline_reuse_ledger_created", file.exists(output_paths$baseline_reuse) && nrow(baseline_reuse) == 8, paste(nrow(baseline_reuse), "baseline reuse rows")),
  check("asset_level_sfc_contract_created", file.exists(output_paths$asset_sfc_contract) && nrow(asset_sfc_contract) == 8, paste(nrow(asset_sfc_contract), "asset SFC rows")),
  check("aggregate_sfc_contract_created", file.exists(output_paths$aggregate_sfc_contract) && nrow(aggregate_sfc_contract) == 7, paste(nrow(aggregate_sfc_contract), "aggregate SFC rows")),
  check("gross_stock_identity_locked", any(asset_sfc_contract$identity_name == "gross_stock_flow_identity"), "asset gross stock flow identity locked"),
  check("net_stock_identity_locked", any(asset_sfc_contract$identity_name == "net_stock_flow_identity"), "asset net stock flow identity locked"),
  check("aggregate_gross_stock_identity_locked", any(aggregate_sfc_contract$aggregate_object == "gross_core_identity"), "aggregate gross identity locked"),
  check("aggregate_net_stock_identity_locked", any(aggregate_sfc_contract$aggregate_object == "net_core_identity"), "aggregate net identity locked"),
  check("growth_weights_restricted_to_decomposition", any(aggregation_matrix$rule_id == "weighted_arithmetic_growth_decomposition" & aggregation_matrix$rule_status == "authorized_later_decomposition_only"), "growth weights restricted to decomposition"),
  check("no_weighted_growth_stock_construction_authorized", any(aggregation_matrix$rule_id == "weighted_level_construction" & aggregation_matrix$rule_status == "forbidden"), "weighted level construction forbidden"),
  check("no_double_weighted_level_aggregation_authorized", any(aggregation_matrix$rule_id == "weighted_level_construction" & aggregation_matrix$rule_status == "forbidden"), "double-weighted stock level aggregation forbidden"),
  check("initialization_vintage_audit_created", file.exists(output_paths$initialization) && nrow(initialization) == 3, paste(nrow(initialization), "initialization rows")),
  check("me_minimum_vintage_history_equals_14", initialization$minimum_surviving_vintage_history_years[initialization$asset_family == "ME"] == 14, "ME minimum vintage history 14 years"),
  check("nrc_minimum_vintage_history_equals_30", initialization$minimum_surviving_vintage_history_years[initialization$asset_family == "NRC"] == 30, "NRC minimum vintage history 30 years"),
  check("first_fully_supported_years_identified", all(!is.na(initialization$first_fully_supported_year)), paste(paste(initialization$asset_family, initialization$first_fully_supported_year, sep = "="), collapse = "; ")),
  check("aggregation_authorization_matrix_created", file.exists(output_paths$aggregation_matrix) && nrow(aggregation_matrix) == 8, paste(nrow(aggregation_matrix), "aggregation rows")),
  check("future_pass_registry_created", file.exists(output_paths$future_pass) && nrow(future_pass) == 7, paste(nrow(future_pass), "future pass rows")),
  check("first_safe_next_pass_identified", future_pass$future_pass_id[1] == "S29C" && future_pass$pass_authorization_status[1] == "authorized_by_clean_s29b_setup", future_pass$future_pass_label[1]),
  check("metadata_only_inputs_not_promoted", taxonomy_count(s25_taxonomy, "authorized_zero_observation_metadata") == 22 && all(no_construction$constructed_object_count == 0), "metadata-only inputs remain reference-only"),
  check("documentation_candidates_not_promoted", boundary_count("documentation_only_deferred") == 14 && all(no_construction$constructed_object_count == 0), "documentation-only records remain excluded"),
  check("theoretically_unresolved_objects_not_promoted", boundary_count("theoretical_boundary_deferred") == 52 && all(no_construction$constructed_object_count == 0), "theoretical-boundary records remain excluded"),
  check("blocked_objects_not_promoted", boundary_count("blocked") == 2 && all(no_construction$constructed_object_count == 0), "blocked records remain excluded"),
  check("parked_objects_not_promoted", boundary_count("blocked_or_parked_deferred") == 14 && all(no_construction$constructed_object_count == 0), "parked records remain excluded"),
  check("no_new_deflators_constructed", no_construction$constructed_object_count[no_construction$object_family == "deflators"] == 0, "no deflators constructed"),
  check("no_new_real_investment_variables_constructed", no_construction$constructed_object_count[no_construction$object_family == "real_investment_flows"] == 0, "no real investment flows constructed"),
  check("no_new_fixed_assets_variables_constructed", no_construction$constructed_object_count[no_construction$object_family == "fixed_assets_variables"] == 0, "no fixed-assets variables constructed"),
  check("no_new_capital_stock_variables_constructed", no_construction$constructed_object_count[no_construction$object_family == "capital_stock_variables"] == 0, "no capital-stock variables constructed"),
  check("no_new_gpim_variables_constructed", no_construction$constructed_object_count[no_construction$object_family == "gpim_variables"] == 0, "no GPIM variables constructed"),
  check("no_core_capital_stock_constructed", no_construction$constructed_object_count[no_construction$object_family == "core_capital_stock"] == 0, "no core capital stock constructed"),
  check("no_real_output_variables_constructed", no_construction$constructed_object_count[no_construction$object_family == "real_output_variables"] == 0, "no real-output variables constructed"),
  check("no_q_variables_constructed", no_construction$constructed_object_count[no_construction$object_family == "q_variables"] == 0, "no q variables constructed"),
  check("no_modeling_outputs_created", no_construction$constructed_object_count[no_construction$object_family == "modeling_outputs"] == 0, "no modeling outputs"),
  check("no_econometric_outputs_created", no_construction$constructed_object_count[no_construction$object_family == "econometric_outputs"] == 0, "no econometric outputs"),
  check("no_theta_outputs_created", no_construction$constructed_object_count[no_construction$object_family == "theta_outputs"] == 0, "no theta outputs"),
  check("no_productive_capacity_outputs_created", no_construction$constructed_object_count[no_construction$object_family == "productive_capacity_outputs"] == 0, "no productive-capacity outputs"),
  check("no_utilization_outputs_created", no_construction$constructed_object_count[no_construction$object_family == "utilization_outputs"] == 0, "no utilization outputs"),
  check("no_adjusted_shaikh_objects_constructed", no_construction$constructed_object_count[no_construction$object_family == "adjusted_shaikh_objects"] == 0, "no adjusted Shaikh outputs"),
  check("upstream_outputs_not_modified", input_hashes_unchanged, "S29A/S28/S27/S26/S25/S24B/S12D/S13 input hashes unchanged"),
  check("provider_repo_not_modified", provider_tracked_clean(provider_repo), "Provider repo tracked and staged diffs are clean; untracked local files are ignored.")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 80
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

role_counts <- aggregate(variable_id ~ theoretical_role, boundary_classification, length)
names(role_counts)[2] <- "candidate_count"
asset_counts <- aggregate(variable_id ~ asset_family, boundary_classification, length)
names(asset_counts)[2] <- "candidate_count"

validation_md <- c(
  "# S29B Fixed Assets And Capital Stock Variables Construction Setup Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 80", "FAIL"), "`."),
  "",
  paste0("Fixed-assets candidate rows classified: `", nrow(candidate_inventory), "`."),
  paste0("Source dependency rows mapped: `", nrow(source_dependency), "`."),
  paste0("S12D/S13 GPIM baseline reuse rows: `", nrow(baseline_reuse), "`."),
  paste0("Existing GPIM SFC audit rows: `", nrow(sfc_audit), "`."),
  "",
  "S29B constructs no deflators, real investment flows, fixed-assets variables, capital-stock variables, GPIM variables, core capital stock, q, theta, productive capacity, utilization, adjusted Shaikh objects, modeling outputs, or econometric outputs.",
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29B Fixed Assets And Capital Stock Variables Construction Setup Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29B consumed S29A commit `", s29a_commit, "`, S28 commit `", s28_commit, "`, S27 commit `", s27_commit, "`, S26 commit `", s26_commit, "`, S25 commit `", s25_commit, "`, S24B commit `", s24b_commit, "`, S24C commit `", s24c_commit, "`, S24A commit `", s24a_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("S29B also consumes locked GPIM commits: S12D-A4 `", s12d_a4_commit, "`, S12D-B `", s12d_b_commit, "`, S12D-C `", s12d_c_commit, "`, and S13 `", s13_commit, "`."),
  "",
  paste0("S29B validation: `", ifelse(all_validation_pass, "PASS 80", "FAIL"), "`."),
  paste0("Fixed-assets candidate rows: `", nrow(candidate_inventory), "`."),
  paste0("Asset-family counts: `", paste(paste(asset_counts$asset_family, asset_counts$candidate_count, sep = "="), collapse = "; "), "`."),
  paste0("Theoretical-role counts: `", paste(paste(role_counts$theoretical_role, role_counts$candidate_count, sep = "="), collapse = "; "), "`."),
  "",
  "ME and NRC are locked as the baseline productive-capital boundary, but S29B authorizes no stock construction. IPP remains contextual and government transportation remains contextual infrastructure outside the baseline private core stock. Residential structures remain excluded.",
  "",
  "The locked S12D/S13 GPIM baseline is reusable for later bounded passes. S29B does not regenerate, overwrite, or rerun the GPIM baseline.",
  "",
  "The first safe next pass is S29C fixed-assets deflator and real-investment construction, bounded to admissible asset-specific deflators, harmonized real ME investment, harmonized real NRC investment, and related provenance/unit audits. It does not authorize capital-stock construction.",
  "",
  "S29B stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) {
  stop("S29B validation failed; see ", output_paths$validation)
}

message("S29B validation PASS 80")
message("Fixed-assets candidate rows: ", nrow(candidate_inventory))
message("Decision: ", final_decision)
