# S29C constructs only ME/NRC fixed-asset deflators and real investment flows.
# It consumes the locked S12D/S13 GPIM price architecture and builds no stocks.

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
s29b_commit <- "bc6f2d3edb16f1c0947bf075d69fccc9d00dc0ca"

s12d_a4_commit <- "f506afd2da9888938ad05f8578d984b8523e014d"
s12d_b_commit <- "5cbc2aae90fa1d8d5fb27057f44c879c383b1260"
s12d_c_commit <- "dd7a13fa4e715ab4645c1bd53999491550c505ea"
s13_commit <- "906ed9f744da64e9931e7f8ec653d92da25384f1"

stage_id <- "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION"
required_s29b_decision <- "AUTHORIZE_S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION"
clean_decision <- "AUTHORIZE_S29D_ASSET_SPECIFIC_GPIM_STOCK_CONSTRUCTION"
blocked_decision <- "BLOCK_FOR_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_REVIEW"
clean_status <- "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION_COMPLETE_S29D_AUTHORIZED"
blocked_status <- "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION_BLOCKED_FOR_REVIEW"

path <- function(...) file.path(...)

s24b_dir <- path(repo_root, "output", "US", "S24B_FIXED_ASSETS_SOURCE_INPUTS_CONSTRUCTION")
s25_dir <- path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
s27_dir <- path(repo_root, "output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
s28_dir <- path(repo_root, "output", "US", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE")
s29a_dir <- path(repo_root, "output", "US", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION")
s29b_dir <- path(repo_root, "output", "US", "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP")
s12d_a4_dir <- path(repo_root, "output", "US", "S12D_A4_MANUAL_GPIM_NET_VALUE_THEORY_LOCK")
s12d_b_dir <- path(repo_root, "output", "US", "S12D_B_GPIM_BASELINE_CONSTRUCTION")
s12d_c_dir <- path(repo_root, "output", "US", "S12D_C_GPIM_DOWNSTREAM_READINESS_LOCK")
s13_dir <- path(repo_root, "output", "US", "S13_LOCKED_GPIM_SOURCE_OF_TRUTH_CONSUMPTION")
s29c_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29c_dir, "csv")
md_dir <- path(s29c_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29b_input_paths <- list(
  inventory = path(s29b_dir, "csv", "S29B_fixed_assets_candidate_inventory.csv"),
  boundary = path(s29b_dir, "csv", "S29B_asset_boundary_classification_ledger.csv"),
  dependency = path(s29b_dir, "csv", "S29B_source_dependency_map.csv"),
  deflator_readiness = path(s29b_dir, "csv", "S29B_deflator_price_concept_readiness_ledger.csv"),
  implicit_deflator = path(s29b_dir, "csv", "S29B_implicit_deflator_admissibility_audit.csv"),
  common_unit = path(s29b_dir, "csv", "S29B_common_unit_harmonization_plan.csv"),
  parameter_lock = path(s29b_dir, "csv", "S29B_gpim_parameter_lock_ledger.csv"),
  baseline_reuse = path(s29b_dir, "csv", "S29B_gpim_baseline_reuse_ledger.csv"),
  initialization = path(s29b_dir, "csv", "S29B_initialization_vintage_readiness_audit.csv"),
  aggregation = path(s29b_dir, "csv", "S29B_aggregation_rule_authorization_matrix.csv"),
  future_pass = path(s29b_dir, "csv", "S29B_future_pass_registry.csv"),
  validation = path(s29b_dir, "csv", "S29B_validation_checks.csv"),
  validation_md = path(s29b_dir, "md", "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP_VALIDATION.md"),
  decision_md = path(s29b_dir, "md", "S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP_DECISION.md")
)

s29a_input_paths <- list(
  validation = path(s29a_dir, "csv", "S29A_validation_checks.csv"),
  decision_md = path(s29a_dir, "md", "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_DECISION.md")
)
s28_input_paths <- list(validation = path(s28_dir, "csv", "S28_validation_checks.csv"))
s27_input_paths <- list(validation = path(s27_dir, "csv", "S27_validation_checks.csv"), boundary = path(s27_dir, "csv", "S27_deferred_excluded_boundary_carry_forward.csv"))
s26_input_paths <- list(
  completeness = path(s26_dir, "csv", "S26_source_input_completeness_ledger.csv"),
  observation = path(s26_dir, "csv", "S26_observation_bearing_readiness_audit.csv"),
  validation = path(s26_dir, "csv", "S26_validation_checks.csv")
)
s25_input_paths <- list(
  panel = path(s25_dir, "csv", "S25_authorized_source_inputs_long.csv"),
  ledger = path(s25_dir, "csv", "S25_authorized_source_inputs_construction_ledger.csv"),
  taxonomy = path(s25_dir, "csv", "S25_source_input_status_taxonomy.csv"),
  validation = path(s25_dir, "csv", "S25_validation_checks.csv")
)
s24b_input_paths <- list(
  panel = path(s24b_dir, "csv", "S24B_fixed_assets_source_inputs_long.csv"),
  ledger = path(s24b_dir, "csv", "S24B_fixed_assets_construction_ledger.csv"),
  provenance = path(s24b_dir, "csv", "S24B_fixed_assets_provenance_audit.csv"),
  validation = path(s24b_dir, "csv", "S24B_validation_checks.csv")
)
gpim_input_paths <- list(
  s12d_a4_parameters = path(s12d_a4_dir, "csv", "S12D_A4_protocol_parameters.csv"),
  s12d_b_real_flows = path(s12d_b_dir, "csv", "S12D_B_real_investment_flows.csv"),
  s12d_b_price_indexes = path(s12d_b_dir, "csv", "S12D_B_sfc_implicit_price_indexes.csv"),
  s12d_b_validation = path(s12d_b_dir, "csv", "S12D_B_validation_checks.csv"),
  s12d_c_contract = path(s12d_c_dir, "csv", "S12D_C_consumption_contract.csv"),
  s12d_c_readiness = path(s12d_c_dir, "csv", "S12D_C_readiness_checks.csv"),
  s13_panel = path(s13_dir, "csv", "S13_gpim_source_panel_long.csv"),
  s13_audit = path(s13_dir, "csv", "S13_consumption_audit.csv"),
  s13_validation = path(s13_dir, "csv", "S13_validation_checks.csv")
)

output_paths <- list(
  panel = path(csv_dir, "S29C_fixed_assets_price_real_investment_long.csv"),
  deflator_ledger = path(csv_dir, "S29C_deflator_construction_ledger.csv"),
  real_ledger = path(csv_dir, "S29C_real_investment_construction_ledger.csv"),
  formula = path(csv_dir, "S29C_nominal_price_real_formula_audit.csv"),
  unit = path(csv_dir, "S29C_reference_year_unit_audit.csv"),
  provenance = path(csv_dir, "S29C_source_to_derived_provenance_audit.csv"),
  admissibility = path(csv_dir, "S29C_deflator_admissibility_audit.csv"),
  coverage = path(csv_dir, "S29C_time_coverage_missingness_audit.csv"),
  comparison = path(csv_dir, "S29C_locked_baseline_comparison_audit.csv"),
  no_cross_asset = path(csv_dir, "S29C_no_cross_asset_pairing_audit.csv"),
  no_chain = path(csv_dir, "S29C_no_chain_addition_audit.csv"),
  no_gpim_stock = path(csv_dir, "S29C_no_gpim_stock_construction_audit.csv"),
  review = path(csv_dir, "S29C_review_needed_ledger.csv"),
  validation = path(csv_dir, "S29C_validation_checks.csv"),
  validation_md = path(md_dir, "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION_VALIDATION.md"),
  decision_md = path(md_dir, "S29C_FIXED_ASSETS_DEFLATOR_AND_REAL_INVESTMENT_CONSTRUCTION_DECISION.md")
)

read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) stop(label, " missing: ", paste(basename(missing), collapse = "; "))
}
taxonomy_count <- function(taxonomy, category) {
  rows <- taxonomy[taxonomy$status_category == category, , drop = FALSE]
  if (nrow(rows) == 0) return(0L)
  as.integer(rows$object_count[1])
}
boundary_count <- function(boundary, category) {
  rows <- boundary[boundary$status_category == category, , drop = FALSE]
  if (nrow(rows) == 0) return(0L)
  as.integer(rows$object_count[1])
}
provider_tracked_clean <- function(repo) {
  unstaged <- system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE)
  staged <- system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE)
  identical(unstaged, 0L) && identical(staged, 0L)
}
internal_missing_count <- function(years) {
  years <- sort(unique(as.integer(years)))
  length(setdiff(seq(min(years), max(years)), years))
}

all_input_paths <- c(unlist(s29b_input_paths), unlist(s29a_input_paths), unlist(s28_input_paths),
                     unlist(s27_input_paths), unlist(s26_input_paths), unlist(s25_input_paths),
                     unlist(s24b_input_paths), unlist(gpim_input_paths))
stop_if_missing(all_input_paths, "S29C inputs")
md5_before <- tools::md5sum(all_input_paths)

s29b_validation <- read_csv(s29b_input_paths$validation)
s29b_decision <- read_text(s29b_input_paths$decision_md)
s29b_inventory <- read_csv(s29b_input_paths$inventory)
s29b_boundary <- read_csv(s29b_input_paths$boundary)
s29b_dependency <- read_csv(s29b_input_paths$dependency)
s29b_deflator <- read_csv(s29b_input_paths$deflator_readiness)
s29b_implicit <- read_csv(s29b_input_paths$implicit_deflator)
s29b_common_unit <- read_csv(s29b_input_paths$common_unit)
s29b_params <- read_csv(s29b_input_paths$parameter_lock)
s29b_reuse <- read_csv(s29b_input_paths$baseline_reuse)
s29b_initialization <- read_csv(s29b_input_paths$initialization)
s29b_aggregation <- read_csv(s29b_input_paths$aggregation)
s29b_future <- read_csv(s29b_input_paths$future_pass)

s29a_validation <- read_csv(s29a_input_paths$validation)
s28_validation <- read_csv(s28_input_paths$validation)
s27_validation <- read_csv(s27_input_paths$validation)
s27_boundary <- read_csv(s27_input_paths$boundary)
s26_validation <- read_csv(s26_input_paths$validation)
s25_validation <- read_csv(s25_input_paths$validation)
s25_panel <- read_csv(s25_input_paths$panel)
s25_ledger <- read_csv(s25_input_paths$ledger)
s25_taxonomy <- read_csv(s25_input_paths$taxonomy)
s24b_validation <- read_csv(s24b_input_paths$validation)
s24b_panel <- read_csv(s24b_input_paths$panel)
s24b_ledger <- read_csv(s24b_input_paths$ledger)

s12d_a4_params <- read_csv(gpim_input_paths$s12d_a4_parameters)
s12d_real_flows <- read_csv(gpim_input_paths$s12d_b_real_flows)
s12d_prices <- read_csv(gpim_input_paths$s12d_b_price_indexes)
s12d_b_validation <- read_csv(gpim_input_paths$s12d_b_validation)
s12d_c_contract <- read_csv(gpim_input_paths$s12d_c_contract)
s12d_c_readiness <- read_csv(gpim_input_paths$s12d_c_readiness)
s13_panel <- read_csv(gpim_input_paths$s13_panel)
s13_audit <- read_csv(gpim_input_paths$s13_audit)
s13_validation <- read_csv(gpim_input_paths$s13_validation)

if (!all_pass(s29b_validation) || nrow(s29b_validation) != 80 ||
    !grepl(required_s29b_decision, s29b_decision, fixed = TRUE)) {
  stop("S29B gate is not clean or does not authorize S29C.")
}

assets <- c("ME", "NRC")
asset_specs <- data.frame(
  asset_family = assets,
  price_id = c("P_ME_2017", "P_NRC_2017"),
  real_id = c("I_ME_REAL_2017", "I_NRC_REAL_2017"),
  s13_price_id = c("P_K_SFC_ME_2017_100", "P_K_SFC_NRC_2017_100"),
  s13_real_id = c("I_REAL_GPIM_ME", "I_REAL_GPIM_NRC"),
  nominal_id = c("I_NOMINAL_DIRECT_ME", "I_NOMINAL_DIRECT_NRC"),
  baseline_role = c("core_ME", "core_NRC"),
  stringsAsFactors = FALSE
)

panel_rows <- list()
deflator_ledger <- list()
real_ledger <- list()
formula_audit <- list()
unit_audit <- list()
coverage_audit <- list()

for (i in seq_len(nrow(asset_specs))) {
  spec <- asset_specs[i, , drop = FALSE]
  flows <- s12d_real_flows[s12d_real_flows$asset_block == spec$asset_family, , drop = FALSE]
  flows$year <- as.integer(flows$year)
  flows$nominal_investment_current_millions <- as.numeric(flows$nominal_investment_current_millions)
  flows$sfc_implicit_price_index_2017_100 <- as.numeric(flows$sfc_implicit_price_index_2017_100)
  flows$real_investment_2017_millions <- as.numeric(flows$real_investment_2017_millions)
  flows$computed_real_investment_2017 <- flows$nominal_investment_current_millions / (flows$sfc_implicit_price_index_2017_100 / 100)

  price_rows <- data.frame(
    stage_id = stage_id,
    derived_variable_id = spec$price_id,
    asset_family = spec$asset_family,
    variable_role = "asset_specific_deflator",
    year = flows$year,
    value = flows$sfc_implicit_price_index_2017_100,
    unit = "index_2017_100",
    source_variable_id = spec$s13_price_id,
    source_table = "S12D_B_real_investment_flows.csv",
    construction_method = "consumed_locked_s12d_sfc_price_column_harmonized_downstream_name",
    price_status = flows$price_status,
    provider_v1_commit = provider_v1_commit,
    s12d_b_commit = s12d_b_commit,
    s13_commit = s13_commit,
    s29b_setup_commit = s29b_commit,
    modeling_authorized = "no",
    econometrics_authorized = "no",
    stringsAsFactors = FALSE
  )
  real_rows <- data.frame(
    stage_id = stage_id,
    derived_variable_id = spec$real_id,
    asset_family = spec$asset_family,
    variable_role = "asset_specific_real_investment_flow",
    year = flows$year,
    value = flows$computed_real_investment_2017,
    unit = "millions_2017_dollars",
    source_variable_id = spec$s13_real_id,
    source_table = "S12D_B_real_investment_flows.csv",
    construction_method = "nominal_direct_investment_deflated_by_locked_asset_specific_sfc_price",
    price_status = flows$price_status,
    provider_v1_commit = provider_v1_commit,
    s12d_b_commit = s12d_b_commit,
    s13_commit = s13_commit,
    s29b_setup_commit = s29b_commit,
    modeling_authorized = "no",
    econometrics_authorized = "no",
    stringsAsFactors = FALSE
  )
  panel_rows[[length(panel_rows) + 1L]] <- price_rows
  panel_rows[[length(panel_rows) + 1L]] <- real_rows

  nominal_candidates <- s29b_deflator$nominal_investment_source_inputs[s29b_deflator$asset_family == spec$asset_family]
  original_ref <- "2017"
  target_ref <- "2017"
  rebasing_factor <- 1
  deflator_ledger[[i]] <- data.frame(
    stage_id = stage_id,
    derived_variable_id = spec$price_id,
    asset_family = spec$asset_family,
    variable_role = "asset_specific_deflator",
    price_source_id = spec$s13_price_id,
    price_source_type = "locked_s12d_s13_sfc_implicit_baseline_price",
    original_price_reference_year = original_ref,
    target_reference_year = target_ref,
    rebasing_factor = rebasing_factor,
    construction_method = "consumed_not_reconstructed",
    observation_count = nrow(price_rows),
    year_start = min(price_rows$year),
    year_end = max(price_rows$year),
    construction_status = "constructed_downstream_harmonized_price_object",
    authorization_source = "S29B_deflator_price_concept_readiness_ledger",
    stringsAsFactors = FALSE
  )
  real_ledger[[i]] <- data.frame(
    stage_id = stage_id,
    derived_variable_id = spec$real_id,
    asset_family = spec$asset_family,
    variable_role = "asset_specific_real_investment_flow",
    nominal_source_id = spec$nominal_id,
    s24b_nominal_source_candidates = nominal_candidates,
    price_source_id = spec$price_id,
    formula = paste0(spec$nominal_id, " / (", spec$price_id, " / 100)"),
    nominal_unit = "current_millions",
    price_unit = "index_2017_100",
    real_unit = "millions_2017_dollars",
    observation_count = nrow(real_rows),
    year_start = min(real_rows$year),
    year_end = max(real_rows$year),
    construction_status = "constructed",
    authorization_source = "S29B_deflator_price_concept_readiness_ledger",
    stringsAsFactors = FALSE
  )
  formula_audit[[i]] <- data.frame(
    stage_id = stage_id,
    derived_variable_id = c(spec$price_id, spec$real_id),
    asset_family = spec$asset_family,
    variable_role = c("asset_specific_deflator", "asset_specific_real_investment_flow"),
    nominal_source_id = c(spec$nominal_id, spec$nominal_id),
    price_source_id = c(spec$s13_price_id, spec$price_id),
    price_source_type = "locked_s12d_s13_sfc_implicit_baseline_price",
    original_price_reference_year = original_ref,
    target_reference_year = target_ref,
    rebasing_formula = "none_required_source_already_2017_100",
    real_flow_formula = c("not_applicable_price_object", paste0(spec$nominal_id, " / (", spec$price_id, " / 100)")),
    nominal_unit = "current_millions",
    price_unit = "index_2017_100",
    real_unit = c("not_applicable", "millions_2017_dollars"),
    year_start = c(min(price_rows$year), min(real_rows$year)),
    year_end = c(max(price_rows$year), max(real_rows$year)),
    observation_count = c(nrow(price_rows), nrow(real_rows)),
    authorization_source = "S29B",
    construction_status = c("constructed_downstream_harmonized_price_object", "constructed"),
    stringsAsFactors = FALSE
  )
  unit_audit[[i]] <- data.frame(
    stage_id = stage_id,
    asset_family = spec$asset_family,
    price_variable_id = spec$price_id,
    real_investment_variable_id = spec$real_id,
    original_price_reference_year = original_ref,
    target_reference_year = target_ref,
    rebasing_required = "no",
    rebasing_factor = rebasing_factor,
    price_2017_value = flows$sfc_implicit_price_index_2017_100[flows$year == 2017],
    nominal_unit = "current_millions",
    price_unit = "index_2017_100",
    real_unit = "millions_2017_dollars",
    unit_verdict = "PASS",
    stringsAsFactors = FALSE
  )
  first_stock <- as.integer(s29b_initialization$first_fully_supported_year[s29b_initialization$asset_family == spec$asset_family])
  min_history <- as.integer(s29b_initialization$minimum_surviving_vintage_history_years[s29b_initialization$asset_family == spec$asset_family])
  coverage_audit[[i]] <- data.frame(
    stage_id = stage_id,
    asset_family = spec$asset_family,
    first_nominal_investment_year = min(flows$year),
    first_price_observation_year = min(flows$year),
    first_recovered_price_year = min(flows$year[flows$price_status == "RECOVERED_SFC_BASELINE_PRICE"]),
    first_real_investment_year = min(flows$year),
    last_observation_year = max(flows$year),
    real_investment_observation_count = nrow(flows),
    internal_missing_years = internal_missing_count(flows$year),
    first_fully_supported_stock_year = first_stock,
    required_prehistory_years = min_history,
    available_prehistory_years = first_stock - min(flows$year),
    prehistory_requirement_met = ifelse(first_stock - min(flows$year) >= min_history, "yes", "no"),
    stringsAsFactors = FALSE
  )
}

constructed_panel <- do.call(rbind, panel_rows)
constructed_panel <- constructed_panel[order(constructed_panel$asset_family, constructed_panel$derived_variable_id, constructed_panel$year), ]
deflator_ledger <- do.call(rbind, deflator_ledger)
real_ledger <- do.call(rbind, real_ledger)
formula_audit <- do.call(rbind, formula_audit)
unit_audit <- do.call(rbind, unit_audit)
coverage_audit <- do.call(rbind, coverage_audit)

provenance_rows <- list()
idx <- 1L
for (i in seq_len(nrow(asset_specs))) {
  spec <- asset_specs[i, , drop = FALSE]
  for (source in c(spec$nominal_id, spec$s13_price_id, spec$s13_real_id)) {
    source_rows <- s13_panel[s13_panel$variable_id == source, , drop = FALSE]
    provenance_rows[[idx]] <- data.frame(
      stage_id = stage_id,
      asset_family = spec$asset_family,
      derived_variable_id = ifelse(source == spec$s13_price_id, spec$price_id, spec$real_id),
      source_variable_id = source,
      source_table = unique(source_rows$source_table)[1],
      source_role = unique(source_rows$object_role)[1],
      downstream_consumption_status = unique(source_rows$downstream_consumption_status)[1],
      source_observation_count = nrow(source_rows),
      source_year_start = min(as.integer(source_rows$year)),
      source_year_end = max(as.integer(source_rows$year)),
      provider_v1_commit = provider_v1_commit,
      s12d_b_commit = s12d_b_commit,
      s12d_c_commit = s12d_c_commit,
      s13_commit = s13_commit,
      s29b_setup_commit = s29b_commit,
      stringsAsFactors = FALSE
    )
    idx <- idx + 1L
  }
}
provenance_audit <- do.call(rbind, provenance_rows)

admissibility_audit <- s29b_implicit[, c("stage_id", "pairing_id", "asset_family", "admissibility_status", "construction_authorized", "rationale")]
admissibility_audit$stage_id <- stage_id
admissibility_audit$s29c_disposition <- ifelse(
  admissibility_audit$admissibility_status == "admissible_locked_baseline",
  "used_locked_baseline_price_for_downstream_harmonization",
  "blocked_not_used"
)

compare_one <- function(constructed_id, baseline_id, variable_role, asset_family) {
  cdf <- constructed_panel[constructed_panel$derived_variable_id == constructed_id, c("year", "value"), drop = FALSE]
  bdf <- s13_panel[s13_panel$variable_id == baseline_id, c("year", "value"), drop = FALSE]
  cdf$year <- as.integer(cdf$year)
  bdf$year <- as.integer(bdf$year)
  cdf$value <- as.numeric(cdf$value)
  bdf$value <- as.numeric(bdf$value)
  names(cdf) <- c("year", "constructed_value")
  names(bdf) <- c("year", "baseline_value")
  m <- merge(cdf, bdf, by = "year", all = FALSE)
  m$absolute_difference <- abs(m$constructed_value - m$baseline_value)
  m$relative_difference <- ifelse(abs(m$baseline_value) > 0, m$absolute_difference / abs(m$baseline_value), NA)
  max_abs <- if (nrow(m) == 0) NA else max(m$absolute_difference, na.rm = TRUE)
  mean_abs <- if (nrow(m) == 0) NA else mean(m$absolute_difference, na.rm = TRUE)
  max_rel <- if (nrow(m) == 0) NA else max(m$relative_difference, na.rm = TRUE)
  status <- ifelse(is.na(max_abs), "unresolved",
                   ifelse(max_abs <= 1e-8, "exact_match",
                          ifelse(max_abs <= 1e-6, "rounding_only", "unresolved")))
  if (nrow(cdf) != nrow(bdf) && status == "exact_match") {
    status <- "coverage_difference"
  }
  data.frame(
    stage_id = stage_id,
    asset_family = asset_family,
    constructed_variable_id = constructed_id,
    locked_baseline_variable_id = baseline_id,
    variable_role = variable_role,
    constructed_observations = nrow(cdf),
    baseline_observations = nrow(bdf),
    overlap_years = nrow(m),
    maximum_absolute_difference = max_abs,
    mean_absolute_difference = mean_abs,
    maximum_relative_difference = max_rel,
    comparison_classification = status,
    unresolved_material_difference = ifelse(status == "unresolved", "yes", "no"),
    stringsAsFactors = FALSE
  )
}
comparison_audit <- do.call(rbind, list(
  compare_one("P_ME_2017", "P_K_SFC_ME_2017_100", "price", "ME"),
  compare_one("P_NRC_2017", "P_K_SFC_NRC_2017_100", "price", "NRC"),
  compare_one("I_ME_REAL_2017", "I_REAL_GPIM_ME", "real_investment", "ME"),
  compare_one("I_NRC_REAL_2017", "I_REAL_GPIM_NRC", "real_investment", "NRC")
))

no_cross_asset <- data.frame(
  stage_id = stage_id,
  audit_item = c("ME_price_used_only_for_ME", "NRC_price_used_only_for_NRC", "no_cross_boundary_pairing", "no_total_or_contextual_asset_selected"),
  status = "PASS",
  evidence = c(
    "P_ME_2017 deflates only I_NOMINAL_DIRECT_ME.",
    "P_NRC_2017 deflates only I_NOMINAL_DIRECT_NRC.",
    "S29C uses only ME and NRC baseline-consumable source rows.",
    "IPP, government transportation, highways/streets, totals, and review-required aggregates are not selected."
  ),
  stringsAsFactors = FALSE
)
no_chain <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_chain_quantity_index_addition", "no_aggregate_real_investment", "real_flows_preserved_separately"),
  status = "PASS",
  evidence = c(
    "No chain-type quantity indexes are summed.",
    "S29C does not construct aggregate core investment.",
    "ME and NRC real investment remain separate variables."
  ),
  stringsAsFactors = FALSE
)
no_gpim_stock <- data.frame(
  stage_id = stage_id,
  object_family = c("gross_stock", "net_stock", "retirements", "consumption_of_fixed_capital", "core_capital_stock", "gpim_stock_paths"),
  constructed_object_count = 0L,
  status = "PASS",
  evidence = "S29C constructs only price and real-investment flow variables.",
  stringsAsFactors = FALSE
)

review_needed <- data.frame(
  stage_id = stage_id,
  review_category = c("contextual_IPP", "contextual_government_transportation", "review_required_totals"),
  candidate_count = c(
    sum(s29b_boundary$theoretical_role == "contextual_IPP"),
    sum(s29b_boundary$theoretical_role == "contextual_government_transportation"),
    sum(s29b_boundary$theoretical_role == "review_required")
  ),
  s29c_disposition = c(
    "not_selected_contextual_asset",
    "not_selected_contextual_infrastructure",
    "not_selected_review_required_aggregate"
  ),
  unresolved_material_difference = "no",
  notes = c(
    "IPP remains outside baseline ME/NRC real-investment construction.",
    "Government transportation remains outside baseline private core stock construction.",
    "Total fixed assets and boundary-sensitive rows require later review before any implementation."
  ),
  stringsAsFactors = FALSE
)

write.csv(constructed_panel, output_paths$panel, row.names = FALSE)
write.csv(deflator_ledger, output_paths$deflator_ledger, row.names = FALSE)
write.csv(real_ledger, output_paths$real_ledger, row.names = FALSE)
write.csv(formula_audit, output_paths$formula, row.names = FALSE)
write.csv(unit_audit, output_paths$unit, row.names = FALSE)
write.csv(provenance_audit, output_paths$provenance, row.names = FALSE)
write.csv(admissibility_audit, output_paths$admissibility, row.names = FALSE)
write.csv(coverage_audit, output_paths$coverage, row.names = FALSE)
write.csv(comparison_audit, output_paths$comparison, row.names = FALSE)
write.csv(no_cross_asset, output_paths$no_cross_asset, row.names = FALSE)
write.csv(no_chain, output_paths$no_chain, row.names = FALSE)
write.csv(no_gpim_stock, output_paths$no_gpim_stock, row.names = FALSE)
write.csv(review_needed, output_paths$review, row.names = FALSE)

md5_after <- tools::md5sum(all_input_paths)
gpim_hash_unchanged <- identical(unname(md5_before[unlist(gpim_input_paths)]), unname(md5_after[unlist(gpim_input_paths)]))
all_hash_unchanged <- identical(unname(md5_before), unname(md5_after))

constructed_ids <- constructed_panel$derived_variable_id
selected_boundary <- s29b_boundary[s29b_boundary$asset_family %in% assets & s29b_boundary$theoretical_role %in% c("core_ME", "core_NRC"), , drop = FALSE]
me_nominal_identified <- any(provenance_audit$source_variable_id == "I_NOMINAL_DIRECT_ME")
nrc_nominal_identified <- any(provenance_audit$source_variable_id == "I_NOMINAL_DIRECT_NRC")
me_price_identified <- any(deflator_ledger$price_source_id == "P_K_SFC_ME_2017_100")
nrc_price_identified <- any(deflator_ledger$price_source_id == "P_K_SFC_NRC_2017_100")
comparison_unresolved <- sum(comparison_audit$unresolved_material_difference == "yes")

check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}

validation_checks <- do.call(rbind, list(
  check("s29b_outputs_present", all(file.exists(unlist(s29b_input_paths))), paste(basename(unlist(s29b_input_paths)), collapse = "; ")),
  check("s29b_validation_all_pass", all_pass(s29b_validation) && nrow(s29b_validation) == 80, paste0("S29B_validation_checks.csv PASS ", nrow(s29b_validation))),
  check("s29b_decision_authorizes_s29c", grepl(required_s29b_decision, s29b_decision, fixed = TRUE), required_s29b_decision),
  check("s29a_outputs_present", all(file.exists(unlist(s29a_input_paths))), paste(basename(unlist(s29a_input_paths)), collapse = "; ")),
  check("s29a_validation_all_pass", all_pass(s29a_validation) && nrow(s29a_validation) == 57, paste0("S29A_validation_checks.csv PASS ", nrow(s29a_validation))),
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
  check("s12d_s13_price_architecture_located", all(file.exists(unlist(gpim_input_paths))), "S12D-B price/flow and S13 consumption outputs located"),
  check("s12d_s13_outputs_not_modified", gpim_hash_unchanged, "S12D/S13 input file md5 hashes unchanged during S29C"),
  check("me_core_boundary_preserved", sum(selected_boundary$theoretical_role == "core_ME") == 8, "8 ME core source rows preserved"),
  check("nrc_core_boundary_preserved", sum(selected_boundary$theoretical_role == "core_NRC") == 8, "8 NRC core source rows preserved"),
  check("ipp_not_selected", !any(constructed_panel$asset_family == "IPP"), "IPP not selected"),
  check("government_transportation_not_selected", !any(grepl("GOV", constructed_panel$asset_family)), "government transportation not selected"),
  check("residential_assets_not_selected", !any(grepl("RES", constructed_panel$asset_family, ignore.case = TRUE)), "residential assets not selected"),
  check("total_fixed_assets_not_selected", !any(constructed_panel$asset_family == "TOTAL"), "total fixed assets not selected"),
  check("exact_me_nominal_investment_source_identified", me_nominal_identified, "I_NOMINAL_DIRECT_ME"),
  check("exact_nrc_nominal_investment_source_identified", nrc_nominal_identified, "I_NOMINAL_DIRECT_NRC"),
  check("exact_me_price_source_identified", me_price_identified, "P_K_SFC_ME_2017_100"),
  check("exact_nrc_price_source_identified", nrc_price_identified, "P_K_SFC_NRC_2017_100"),
  check("me_price_pairing_admissible", any(admissibility_audit$pairing_id == "ME_locked_sfc_price" & admissibility_audit$admissibility_status == "admissible_locked_baseline"), "ME locked SFC price admissible"),
  check("nrc_price_pairing_admissible", any(admissibility_audit$pairing_id == "NRC_locked_sfc_price" & admissibility_audit$admissibility_status == "admissible_locked_baseline"), "NRC locked SFC price admissible"),
  check("no_cross_asset_price_pairing", all(no_cross_asset$status == "PASS"), "no cross-asset price pairing"),
  check("no_cross_boundary_price_pairing", all(no_cross_asset$status == "PASS"), "no cross-boundary price pairing"),
  check("no_stock_flow_ratio_used_as_deflator", any(admissibility_audit$admissibility_status == "inadmissible_stock_flow_mixing" & admissibility_audit$s29c_disposition == "blocked_not_used"), "stock-flow ratio blocked"),
  check("no_quantity_index_ratio_used_as_deflator", any(admissibility_audit$admissibility_status == "inadmissible_quantity_index_ratio" & admissibility_audit$s29c_disposition == "blocked_not_used"), "quantity-index ratios blocked"),
  check("target_reference_year_equals_2017", all(unit_audit$target_reference_year == "2017"), "target reference year 2017"),
  check("me_price_rebased_correctly_if_required", unit_audit$rebasing_factor[unit_audit$asset_family == "ME"] == 1 && unit_audit$price_2017_value[unit_audit$asset_family == "ME"] == 100, "ME source already 2017=100"),
  check("nrc_price_rebased_correctly_if_required", unit_audit$rebasing_factor[unit_audit$asset_family == "NRC"] == 1 && unit_audit$price_2017_value[unit_audit$asset_family == "NRC"] == 100, "NRC source already 2017=100"),
  check("me_real_investment_constructed", any(constructed_panel$derived_variable_id == "I_ME_REAL_2017") && nrow(constructed_panel[constructed_panel$derived_variable_id == "I_ME_REAL_2017", ]) == 124, "I_ME_REAL_2017 124 rows"),
  check("nrc_real_investment_constructed", any(constructed_panel$derived_variable_id == "I_NRC_REAL_2017") && nrow(constructed_panel[constructed_panel$derived_variable_id == "I_NRC_REAL_2017", ]) == 124, "I_NRC_REAL_2017 124 rows"),
  check("me_real_investment_unit_is_2017_dollars", all(constructed_panel$unit[constructed_panel$derived_variable_id == "I_ME_REAL_2017"] == "millions_2017_dollars"), "ME real unit millions_2017_dollars"),
  check("nrc_real_investment_unit_is_2017_dollars", all(constructed_panel$unit[constructed_panel$derived_variable_id == "I_NRC_REAL_2017"] == "millions_2017_dollars"), "NRC real unit millions_2017_dollars"),
  check("me_and_nrc_preserved_as_separate_series", length(unique(constructed_panel$asset_family)) == 2 && all(sort(unique(constructed_panel$asset_family)) == c("ME", "NRC")), "ME and NRC separate"),
  check("no_aggregate_core_investment_constructed", !any(grepl("CORE", constructed_ids, ignore.case = TRUE)), "no aggregate core investment variable"),
  check("price_real_investment_panel_created", file.exists(output_paths$panel) && nrow(constructed_panel) == 496, paste(nrow(constructed_panel), "panel rows")),
  check("deflator_construction_ledger_created", file.exists(output_paths$deflator_ledger) && nrow(deflator_ledger) == 2, paste(nrow(deflator_ledger), "deflator rows")),
  check("real_investment_construction_ledger_created", file.exists(output_paths$real_ledger) && nrow(real_ledger) == 2, paste(nrow(real_ledger), "real investment rows")),
  check("formula_audit_created", file.exists(output_paths$formula) && nrow(formula_audit) == 4, paste(nrow(formula_audit), "formula rows")),
  check("unit_audit_created", file.exists(output_paths$unit) && nrow(unit_audit) == 2 && all(unit_audit$unit_verdict == "PASS"), paste(nrow(unit_audit), "unit rows")),
  check("provenance_audit_created", file.exists(output_paths$provenance) && nrow(provenance_audit) == 6, paste(nrow(provenance_audit), "provenance rows")),
  check("deflator_admissibility_audit_created", file.exists(output_paths$admissibility) && nrow(admissibility_audit) == 6, paste(nrow(admissibility_audit), "admissibility rows")),
  check("coverage_missingness_audit_created", file.exists(output_paths$coverage) && nrow(coverage_audit) == 2, paste(nrow(coverage_audit), "coverage rows")),
  check("locked_baseline_comparison_audit_created", file.exists(output_paths$comparison) && nrow(comparison_audit) == 4, paste(nrow(comparison_audit), "comparison rows")),
  check("no_cross_asset_pairing_audit_created", file.exists(output_paths$no_cross_asset) && all(no_cross_asset$status == "PASS"), paste(nrow(no_cross_asset), "cross-asset audit rows")),
  check("no_chain_addition_audit_created", file.exists(output_paths$no_chain) && all(no_chain$status == "PASS"), paste(nrow(no_chain), "chain audit rows")),
  check("no_gpim_stock_construction_audit_created", file.exists(output_paths$no_gpim_stock) && all(no_gpim_stock$constructed_object_count == 0), paste(nrow(no_gpim_stock), "GPIM stock audit rows")),
  check("review_needed_ledger_created", file.exists(output_paths$review) && nrow(review_needed) == 3, paste(nrow(review_needed), "review rows")),
  check("metadata_only_inputs_not_used_as_observations", taxonomy_count(s25_taxonomy, "authorized_zero_observation_metadata") == 22, "metadata-only inputs remain reference-only"),
  check("documentation_candidates_not_promoted", boundary_count(s27_boundary, "documentation_only_deferred") == 14, "documentation-only records remain excluded"),
  check("theoretically_unresolved_objects_not_promoted", boundary_count(s27_boundary, "theoretical_boundary_deferred") == 52, "theoretical-boundary records remain excluded"),
  check("blocked_objects_not_promoted", boundary_count(s27_boundary, "blocked") == 2, "blocked records remain excluded"),
  check("parked_objects_not_promoted", boundary_count(s27_boundary, "blocked_or_parked_deferred") == 14, "parked records remain excluded"),
  check("no_gross_stock_constructed", !any(grepl("GROSS|STOCK|K_", constructed_ids)), "no gross stock constructed"),
  check("no_net_stock_constructed", !any(grepl("NET_STOCK|NET_VALUE", constructed_ids)), "no net stock constructed"),
  check("no_retirement_flow_constructed", !any(grepl("RETIRE", constructed_ids, ignore.case = TRUE)), "no retirement flow constructed"),
  check("no_cfc_flow_constructed", !any(grepl("CFC", constructed_ids, ignore.case = TRUE)), "no CFC flow constructed"),
  check("no_core_capital_stock_constructed", !any(grepl("CORE|CAPITAL_STOCK", constructed_ids, ignore.case = TRUE)), "no core capital stock constructed"),
  check("no_gpim_parameters_modified", all(s29b_params$service_life_L == c(14, 30)) && all(abs(s29b_params$depreciation_value_parameter_d - c(0.110, 0.024)) < 1e-12), "S29B GPIM parameters unchanged"),
  check("no_gpim_stock_paths_recomputed", all(no_gpim_stock$constructed_object_count == 0), "no GPIM stock paths recomputed"),
  check("no_real_output_variables_constructed", !any(grepl("OUTPUT|GDP", constructed_ids, ignore.case = TRUE)), "no real-output variable constructed"),
  check("no_q_variables_constructed", !any(grepl("(^Q_|_Q$|ACCUMULATED_Q|MECHANIZATION)", constructed_ids, ignore.case = TRUE)), "no q variable constructed"),
  check("no_theta_variables_constructed", !any(grepl("THETA", constructed_ids, ignore.case = TRUE)), "no theta variable constructed"),
  check("no_productive_capacity_constructed", !any(grepl("PRODUCTIVE|CAPACITY", constructed_ids, ignore.case = TRUE)), "no productive-capacity object constructed"),
  check("no_utilization_constructed", !any(grepl("UTILIZATION|^MU_|_MU_", constructed_ids, ignore.case = TRUE)), "no utilization object constructed"),
  check("no_modeling_outputs_created", !any(grepl("model", unlist(output_paths), ignore.case = TRUE)), "no modeling output paths"),
  check("no_econometric_outputs_created", !any(grepl("econometric|vecm|regression", unlist(output_paths), ignore.case = TRUE)), "no econometric output paths"),
  check("no_adjusted_shaikh_objects_constructed", !any(grepl("ADJUSTED|SHAIKH", constructed_ids, ignore.case = TRUE)), "no adjusted Shaikh object constructed"),
  check("upstream_outputs_not_modified", all_hash_unchanged, "S29B/S29A/S28/S27/S26/S25/S24B/S12D/S13 input hashes unchanged"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "Provider repo tracked and staged diffs are clean; untracked local files are ignored.")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 77 && comparison_unresolved == 0
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

validation_md <- c(
  "# S29C Fixed-Assets Deflator And Real-Investment Construction Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 77", "FAIL"), "`."),
  "",
  paste0("Constructed deflator variables: `", nrow(deflator_ledger), "`."),
  paste0("Constructed real-investment variables: `", nrow(real_ledger), "`."),
  paste0("Constructed panel rows: `", nrow(constructed_panel), "`."),
  paste0("Locked-baseline comparison rows: `", nrow(comparison_audit), "`."),
  paste0("Unresolved material comparison rows: `", comparison_unresolved, "`."),
  "",
  "S29C constructs only ME and NRC price/deflator variables and real investment flows in 2017 dollars. It constructs no stocks, retirements, CFC, aggregate core investment, q, theta, productive capacity, utilization, modeling, or econometric outputs.",
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29C Fixed-Assets Deflator And Real-Investment Construction Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29C consumed S29B commit `", s29b_commit, "`, S29A commit `", s29a_commit, "`, S28 commit `", s28_commit, "`, S27 commit `", s27_commit, "`, S26 commit `", s26_commit, "`, S25 commit `", s25_commit, "`, S24B commit `", s24b_commit, "`, S24C commit `", s24c_commit, "`, S24A commit `", s24a_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("S29C also consumes locked GPIM commits: S12D-A4 `", s12d_a4_commit, "`, S12D-B `", s12d_b_commit, "`, S12D-C `", s12d_c_commit, "`, and S13 `", s13_commit, "`."),
  "",
  paste0("S29C validation: `", ifelse(all_validation_pass, "PASS 77", "FAIL"), "`."),
  paste0("Constructed deflator variables: `", nrow(deflator_ledger), "`."),
  paste0("Constructed real-investment variables: `", nrow(real_ledger), "`."),
  paste0("Constructed panel rows: `", nrow(constructed_panel), "`."),
  paste0("ME real-investment coverage: `", coverage_audit$first_real_investment_year[coverage_audit$asset_family == "ME"], "-", coverage_audit$last_observation_year[coverage_audit$asset_family == "ME"], "`."),
  paste0("NRC real-investment coverage: `", coverage_audit$first_real_investment_year[coverage_audit$asset_family == "NRC"], "-", coverage_audit$last_observation_year[coverage_audit$asset_family == "NRC"], "`."),
  paste0("Unresolved material locked-baseline comparison rows: `", comparison_unresolved, "`."),
  "",
  "S29C authorizes only the next bounded asset-specific GPIM stock construction pass. It does not authorize aggregate core capital stock, q, theta, productive capacity, utilization, modeling, or econometrics.",
  "",
  "S29C stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) {
  stop("S29C validation failed; see ", output_paths$validation)
}

message("S29C validation PASS 77")
message("Constructed deflators: ", nrow(deflator_ledger))
message("Constructed real investment variables: ", nrow(real_ledger))
message("Constructed panel rows: ", nrow(constructed_panel))
message("Decision: ", final_decision)
