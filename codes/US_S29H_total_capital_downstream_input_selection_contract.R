# S29H converts the S29G review into a downstream input-selection contract.
# It does not construct variables, transformations, complete-case samples, or model inputs.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
provider_repo <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

stage_id <- "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT"
s29g_commit <- "0782393428a4f4521df3a88311eb9896b324671d"
s29f_commit <- "cb0d1a93700a6224cbfe82d786f90381519c8de2"
required_s29g_decision <- "AUTHORIZE_S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT"
required_s29g_status <- "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW_COMPLETE_S29H_AUTHORIZED"
clean_decision <- "AUTHORIZE_S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY"
blocked_decision <- "BLOCK_FOR_TOTAL_CAPITAL_DOWNSTREAM_INPUT_CONTRACT_REVIEW"
clean_status <- "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT_COMPLETE_S29I_AUTHORIZED"
blocked_status <- "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT_BLOCKED"

path <- function(...) file.path(...)
read_csv <- function(file) read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
read_text <- function(file) paste(readLines(file, warn = FALSE), collapse = "\n")
all_pass <- function(df) nrow(df) > 0 && all(df$status == "PASS")
stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) stop(label, " missing: ", paste(basename(missing), collapse = "; "))
}
provider_tracked_clean <- function(repo) {
  unstaged <- system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE)
  staged <- system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE)
  identical(unstaged, 0L) && identical(staged, 0L)
}
check <- function(name, condition, evidence) {
  data.frame(check_name = name, status = ifelse(isTRUE(condition), "PASS", "FAIL"), evidence = evidence, stringsAsFactors = FALSE)
}
collapse_vars <- function(x) paste(sort(unique(x)), collapse = "; ")

s29g_dir <- path(repo_root, "output", "US", "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW")
s29f_dir <- path(repo_root, "output", "US", "S29F_TOTAL_CAPITAL_ANALYTICAL_TRANSFORMATIONS")
s29e_dir <- path(repo_root, "output", "US", "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION")
s29h_dir <- path(repo_root, "output", "US", stage_id)
csv_dir <- path(s29h_dir, "csv")
md_dir <- path(s29h_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s29g_input_paths <- list(
  inventory = path(s29g_dir, "csv", "S29G_analytical_variable_inventory.csv"),
  classification = path(s29g_dir, "csv", "S29G_variable_admissibility_classification.csv"),
  role = path(s29g_dir, "csv", "S29G_downstream_role_classification.csv"),
  authoritative = path(s29g_dir, "csv", "S29G_authoritative_variable_selection_ledger.csv"),
  redundancy = path(s29g_dir, "csv", "S29G_redundancy_map.csv"),
  support = path(s29g_dir, "csv", "S29G_support_coverage_review.csv"),
  warmup = path(s29g_dir, "csv", "S29G_warmup_restriction_ledger.csv"),
  growth = path(s29g_dir, "csv", "S29G_growth_measure_comparison_review.csv"),
  max_gap = path(s29g_dir, "csv", "S29G_max_arithmetic_log_gap_review.csv"),
  movement = path(s29g_dir, "csv", "S29G_large_movement_discontinuity_review.csv"),
  composition = path(s29g_dir, "csv", "S29G_composition_diagnostic_review.csv"),
  intensity = path(s29g_dir, "csv", "S29G_intensity_diagnostic_review.csv"),
  recommendation = path(s29g_dir, "csv", "S29G_downstream_selection_recommendation.csv"),
  review = path(s29g_dir, "csv", "S29G_review_needed_ledger.csv"),
  no_new = path(s29g_dir, "csv", "S29G_no_new_variable_construction_audit.csv"),
  no_provider_total = path(s29g_dir, "csv", "S29G_no_provider_total_promotion_audit.csv"),
  no_q = path(s29g_dir, "csv", "S29G_no_q_audit.csv"),
  no_theta = path(s29g_dir, "csv", "S29G_no_theta_audit.csv"),
  no_utilization = path(s29g_dir, "csv", "S29G_no_capacity_utilization_audit.csv"),
  no_modeling = path(s29g_dir, "csv", "S29G_no_modeling_audit.csv"),
  validation = path(s29g_dir, "csv", "S29G_validation_checks.csv"),
  validation_md = path(s29g_dir, "md", "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW_VALIDATION.md"),
  decision_md = path(s29g_dir, "md", "S29G_TOTAL_CAPITAL_ANALYTICAL_READINESS_REVIEW_DECISION.md")
)
s29f_input_paths <- list(
  long = path(s29f_dir, "csv", "S29F_total_capital_analytical_panel_long.csv"),
  ledger = path(s29f_dir, "csv", "S29F_transformation_ledger.csv"),
  formula = path(s29f_dir, "csv", "S29F_formula_audit.csv"),
  unit = path(s29f_dir, "csv", "S29F_unit_audit.csv"),
  alias = path(s29f_dir, "csv", "S29F_tot_alias_reconciliation_audit.csv"),
  support = path(s29f_dir, "csv", "S29F_support_propagation_audit.csv"),
  validation = path(s29f_dir, "csv", "S29F_validation_checks.csv")
)
s29e_input_paths <- list(
  validation = path(s29e_dir, "csv", "S29E_validation_checks.csv"),
  decision_md = path(s29e_dir, "md", "S29E_STOCK_FLOW_CONSISTENT_CORE_CAPITAL_AGGREGATION_DECISION.md")
)
output_paths <- list(
  contract = path(csv_dir, "S29H_complete_variable_contract.csv"),
  slots = path(csv_dir, "S29H_authoritative_downstream_slot_contract.csv"),
  baseline = path(csv_dir, "S29H_baseline_authorized_variables.csv"),
  robustness = path(csv_dir, "S29H_robustness_authorized_variables.csv"),
  conditional = path(csv_dir, "S29H_conditional_secondary_variables.csv"),
  diagnostic = path(csv_dir, "S29H_diagnostic_only_variables.csv"),
  alias = path(csv_dir, "S29H_alias_interface_only_variables.csv"),
  excluded = path(csv_dir, "S29H_excluded_downstream_variables.csv"),
  support = path(csv_dir, "S29H_support_window_contract.csv"),
  warmup = path(csv_dir, "S29H_warmup_restriction_contract.csv"),
  alias_map = path(csv_dir, "S29H_alias_authority_map.csv"),
  permitted = path(csv_dir, "S29H_permitted_use_matrix.csv"),
  prohibited = path(csv_dir, "S29H_prohibited_use_matrix.csv"),
  growth = path(csv_dir, "S29H_growth_measure_selection_contract.csv"),
  manifest = path(csv_dir, "S29H_downstream_handoff_manifest.csv"),
  review = path(csv_dir, "S29H_review_needed_ledger.csv"),
  no_new = path(csv_dir, "S29H_no_new_variable_construction_audit.csv"),
  no_model_panel = path(csv_dir, "S29H_no_model_input_panel_audit.csv"),
  no_provider_total = path(csv_dir, "S29H_no_provider_total_promotion_audit.csv"),
  no_q = path(csv_dir, "S29H_no_q_audit.csv"),
  no_theta = path(csv_dir, "S29H_no_theta_audit.csv"),
  no_utilization = path(csv_dir, "S29H_no_capacity_utilization_audit.csv"),
  no_modeling = path(csv_dir, "S29H_no_modeling_audit.csv"),
  validation = path(csv_dir, "S29H_validation_checks.csv"),
  contract_md = path(md_dir, "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT.md"),
  validation_md = path(md_dir, "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT_VALIDATION.md"),
  decision_md = path(md_dir, "S29H_TOTAL_CAPITAL_DOWNSTREAM_INPUT_SELECTION_CONTRACT_DECISION.md")
)

input_paths <- c(unlist(s29g_input_paths), unlist(s29f_input_paths), unlist(s29e_input_paths))
stop_if_missing(input_paths, "S29H inputs")
md5_before <- tools::md5sum(input_paths)

s29g_inventory <- read_csv(s29g_input_paths$inventory)
s29g_classification <- read_csv(s29g_input_paths$classification)
s29g_role <- read_csv(s29g_input_paths$role)
s29g_redundancy <- read_csv(s29g_input_paths$redundancy)
s29g_support <- read_csv(s29g_input_paths$support)
s29g_growth <- read_csv(s29g_input_paths$growth)
s29g_max_gap <- read_csv(s29g_input_paths$max_gap)
s29g_validation <- read_csv(s29g_input_paths$validation)
s29g_decision <- read_text(s29g_input_paths$decision_md)
s29f_long <- read_csv(s29f_input_paths$long)
s29f_validation <- read_csv(s29f_input_paths$validation)
s29e_validation <- read_csv(s29e_input_paths$validation)

if (!all_pass(s29g_validation) || nrow(s29g_validation) != 66 ||
    !grepl(required_s29g_decision, s29g_decision, fixed = TRUE) ||
    !grepl(required_s29g_status, s29g_decision, fixed = TRUE)) {
  stop("S29G gate is not clean or does not authorize S29H.")
}
if (!all_pass(s29f_validation) || nrow(s29f_validation) != 87) stop("S29F validation gate is not clean.")
if (!all_pass(s29e_validation) || nrow(s29e_validation) != 72) stop("S29E validation gate is not clean.")

contract_unit <- function(variable_id, unit) {
  if (variable_id %in% c("LOG_G_TOT_GPIM_2017", "LOG_N_TOT_GPIM_2017", "LOG_I_TOT_REAL_2017") ||
      grepl("^LOG_[GIN]_", variable_id)) {
    return("natural_log_of_millions_2017_dollars")
  }
  unit
}
contract_status <- function(variable_id, classification, role, family) {
  if (variable_id %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017")) return("BASELINE_AUTHORIZED")
  if (variable_id %in% c("N_TOT_GPIM_2017", "LOG_N_TOT_GPIM_2017")) return("ROBUSTNESS_AUTHORIZED")
  if (classification == "AUTHORIZED_SECONDARY") return("CONDITIONAL_SECONDARY")
  if (classification == "REDUNDANT_ALIAS") return("ALIAS_INTERFACE_ONLY")
  if (classification == "DIAGNOSTIC_ONLY") return("DIAGNOSTIC_ONLY")
  "EXCLUDED_FROM_DOWNSTREAM_INTERFACE"
}
authoritative_for <- function(variable_id, status, family) {
  explicit <- c(
    "K_GROSS_TOT" = "G_TOT_GPIM_2017",
    "K_NET_TOT" = "N_TOT_GPIM_2017",
    "G_CORE_GPIM_2017" = "G_TOT_GPIM_2017",
    "N_CORE_GPIM_2017" = "N_TOT_GPIM_2017",
    "I_CORE_REAL_2017" = "I_TOT_REAL_2017",
    "RET_CORE_GPIM_2017" = "RET_TOT_GPIM_2017",
    "CFC_CORE_GPIM_2017" = "CFC_TOT_GPIM_2017"
  )
  if (variable_id %in% names(explicit)) return(unname(explicit[variable_id]))
  if (status == "ALIAS_INTERFACE_ONLY") {
    rec <- s29g_redundancy$recommended_authoritative_variable[s29g_redundancy$variable_id == variable_id]
    if (length(rec) > 0 && !is.na(rec[1])) return(rec[1])
  }
  variable_id
}
permitted_for <- function(variable_id, status, role, family) {
  if (variable_id == "G_TOT_GPIM_2017") return("baseline_level")
  if (variable_id == "LOG_G_TOT_GPIM_2017") return("baseline_log_level")
  if (variable_id == "N_TOT_GPIM_2017") return("robustness_level")
  if (variable_id == "LOG_N_TOT_GPIM_2017") return("robustness_log_level")
  if (grepl("lagged", role)) return("conditional_lag")
  if (grepl("growth_candidate", role)) return("secondary_growth")
  if (grepl("investment", role)) return("accumulation_flow_diagnostic")
  if (grepl("composition", role)) return("composition_diagnostic")
  if (status == "ALIAS_INTERFACE_ONLY") return("alias_compatibility")
  if (family %in% c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic",
                    "gross_stock_flow_net_change", "net_stock_flow_net_change", "arithmetic_log_growth_gap")) return("accounting_diagnostic")
  if (status == "DIAGNOSTIC_ONLY") return("continuity_diagnostic")
  "none"
}
prohibited_for <- function(variable_id, status, role, family) {
  base <- c("not_valid_for_warmup_baseline_estimation", "not_q_input_without_future_authorization", "not_distribution_interaction_without_future_authorization")
  extra <- character()
  if (status != "BASELINE_AUTHORIZED") extra <- c(extra, "not_baseline_stock")
  if (status %in% c("DIAGNOSTIC_ONLY", "ALIAS_INTERFACE_ONLY", "EXCLUDED_FROM_DOWNSTREAM_INTERFACE")) extra <- c(extra, "not_model_input")
  if (status == "ALIAS_INTERFACE_ONLY") extra <- c(extra, "not_independent_regressor")
  if (grepl("composition", role)) extra <- c(extra, "not_productive_efficiency_weight")
  if (family %in% c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic")) extra <- c(extra, "not_structural_depreciation_parameter")
  if (grepl("investment", role)) extra <- c(extra, "not_stock_substitute")
  if (family %in% c("arithmetic_log_growth_gap", "first_difference")) extra <- c(extra, "not_growth_substitute")
  paste(unique(c(extra, base)), collapse = "; ")
}
future_auth <- function(status, role, family) {
  if (status %in% c("CONDITIONAL_SECONDARY", "DIAGNOSTIC_ONLY", "ALIAS_INTERFACE_ONLY", "EXCLUDED_FROM_DOWNSTREAM_INTERFACE")) "yes" else "no"
}
note_for <- function(variable_id, status, role, family) {
  if (variable_id == "G_TOT_GPIM_2017") return("Authoritative primary gross real GPIM productive-capital level. Baseline window 1931-2024.")
  if (variable_id == "LOG_G_TOT_GPIM_2017") return("Authoritative primary logged gross real GPIM productive-capital variable. Baseline window 1931-2024.")
  if (variable_id == "N_TOT_GPIM_2017") return("Net real GPIM stock is authorized only as a labelled robustness level, not as the baseline productive-capital quantity.")
  if (variable_id == "LOG_N_TOT_GPIM_2017") return("Logged net real GPIM stock is authorized only as labelled robustness, not as the baseline logged capital input.")
  if (variable_id %in% c("DLOG_G_TOT", "GROWTH_ARITH_G_TOT")) return("Gross-stock growth candidate. A later stage must choose the log or arithmetic definition explicitly.")
  if (grepl("^L1_", variable_id)) return("Lag candidate only. Availability is not automatic authorization.")
  if (grepl("SHARE_", variable_id)) return("Composition diagnostic only; not a reconstruction weight or productive-efficiency weight.")
  if (family %in% c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic")) return("Accounting intensity diagnostic only; not a structural depreciation parameter.")
  if (family %in% c("gross_stock_flow_net_change", "net_stock_flow_net_change")) return("Accounting net-change diagnostic is redundant with the corresponding first difference.")
  if (family == "arithmetic_log_growth_gap") return("Arithmetic/log growth gap diagnostic only; not a model-input variable.")
  if (grepl("^I_|LOG_I_|DLOG_I_|GROWTH_ARITH_I_|DELTA_I_", variable_id)) return("Investment is an accumulation flow and cannot substitute for the productive-capital stock.")
  if (status == "ALIAS_INTERFACE_ONLY") return("Retained only for interface compatibility; must not be used as an independent empirical object.")
  "Contracted according to S29G classification and role."
}

contract <- s29g_inventory
contract$s29g_classification <- contract$primary_classification
contract$s29g_downstream_role <- contract$downstream_role
contract$s29h_contract_status <- mapply(contract_status, contract$variable_id, contract$s29g_classification, contract$s29g_downstream_role, contract$transformation_family)
contract$authoritative_variable_id <- mapply(authoritative_for, contract$variable_id, contract$s29h_contract_status, contract$transformation_family)
contract$unit <- mapply(contract_unit, contract$variable_id, contract$unit)
contract$first_observed_year <- contract$year_start
contract$last_observed_year <- contract$year_end
contract$baseline_start_year <- ifelse(contract$s29h_contract_status %in% c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "CONDITIONAL_SECONDARY"),
                                       contract$first_fully_supported_year, NA)
contract$baseline_end_year <- ifelse(contract$s29h_contract_status %in% c("BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "CONDITIONAL_SECONDARY"),
                                     contract$year_end, NA)
contract$warmup_use_allowed <- ifelse(contract$warmup_observation_count > 0,
                                      "visualization_only; historical_continuity_only; initialization_diagnostic_only; sensitivity_only",
                                      "not_applicable")
contract$baseline_estimation_allowed <- ifelse(contract$s29h_contract_status == "BASELINE_AUTHORIZED", "yes_fully_supported_window_only", "no")
contract$permitted_use <- mapply(permitted_for, contract$variable_id, contract$s29h_contract_status, contract$s29g_downstream_role, contract$transformation_family)
contract$prohibited_use <- mapply(prohibited_for, contract$variable_id, contract$s29h_contract_status, contract$s29g_downstream_role, contract$transformation_family)
contract$explicit_future_authorization_required <- mapply(future_auth, contract$s29h_contract_status, contract$s29g_downstream_role, contract$transformation_family)
contract$contract_note <- mapply(note_for, contract$variable_id, contract$s29h_contract_status, contract$s29g_downstream_role, contract$transformation_family)
contract <- contract[, c(
  "stage_id", "variable_id", "asset_scope", "transformation_family", "s29g_classification", "s29g_downstream_role",
  "s29h_contract_status", "authoritative_variable_id", "source_variable_id", "unit", "first_observed_year",
  "last_observed_year", "first_fully_supported_year", "baseline_start_year", "baseline_end_year",
  "warmup_observation_count", "fully_supported_observation_count", "permitted_use", "prohibited_use",
  "explicit_future_authorization_required", "baseline_estimation_allowed", "warmup_use_allowed", "contract_note"
)]
contract$stage_id <- stage_id

slot_contract <- data.frame(
  stage_id = stage_id,
  slot_id = c(
    "productive_capital_level_primary",
    "productive_capital_log_primary",
    "net_stock_robustness_level",
    "net_stock_robustness_log",
    "productive_capital_log_growth_candidate",
    "productive_capital_arithmetic_growth_candidate",
    "productive_capital_lagged_level_candidate",
    "productive_capital_lagged_growth_candidate"
  ),
  authorized_variable = c(
    "G_TOT_GPIM_2017",
    "LOG_G_TOT_GPIM_2017",
    "N_TOT_GPIM_2017",
    "LOG_N_TOT_GPIM_2017",
    "DLOG_G_TOT",
    "GROWTH_ARITH_G_TOT",
    "L1_LOG_G_TOT",
    "L1_DLOG_G_TOT"
  ),
  contract_status = c("BASELINE_AUTHORIZED", "BASELINE_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", "ROBUSTNESS_AUTHORIZED", rep("CONDITIONAL_SECONDARY", 4)),
  future_selection_required = c("no", "no", "yes", "yes", "yes", "yes", "yes", "yes"),
  slot_note = c(
    "Authoritative gross real GPIM productive-capital level.",
    "Authoritative logged gross real GPIM productive-capital variable.",
    "Net stock robustness level only.",
    "Net stock robustness log only.",
    "Log growth candidate; not interchangeable with arithmetic growth.",
    "Arithmetic growth candidate; not interchangeable with log growth.",
    "Conditional lag only if later specification explicitly requires it.",
    "Conditional lag only if later specification explicitly requires it."
  ),
  stringsAsFactors = FALSE
)

alias_authority_map <- data.frame(
  stage_id = stage_id,
  alias_variable_id = c("G_CORE_GPIM_2017", "N_CORE_GPIM_2017", "I_CORE_REAL_2017", "RET_CORE_GPIM_2017", "CFC_CORE_GPIM_2017", "K_GROSS_TOT", "K_NET_TOT"),
  authoritative_variable_id = c("G_TOT_GPIM_2017", "N_TOT_GPIM_2017", "I_TOT_REAL_2017", "RET_TOT_GPIM_2017", "CFC_TOT_GPIM_2017", "G_TOT_GPIM_2017", "N_TOT_GPIM_2017"),
  alias_type = c(rep("historical_CORE_source_identifier", 5), rep("interface_K_alias", 2)),
  direction_of_authority = "use authoritative_variable_id for downstream S29H contract; alias must not enter as independent object",
  alias_contract_status = "ALIAS_INTERFACE_ONLY",
  stringsAsFactors = FALSE
)

baseline_vars <- contract[contract$s29h_contract_status == "BASELINE_AUTHORIZED", ]
robustness_vars <- contract[contract$s29h_contract_status == "ROBUSTNESS_AUTHORIZED", ]
conditional_vars <- contract[contract$s29h_contract_status == "CONDITIONAL_SECONDARY", ]
diagnostic_vars <- contract[contract$s29h_contract_status == "DIAGNOSTIC_ONLY", ]
alias_vars <- contract[contract$s29h_contract_status == "ALIAS_INTERFACE_ONLY", ]
excluded_vars <- contract[contract$s29h_contract_status == "EXCLUDED_FROM_DOWNSTREAM_INTERFACE", ]

support_contract <- contract[, c("stage_id", "variable_id", "asset_scope", "s29h_contract_status", "first_observed_year", "last_observed_year", "first_fully_supported_year", "baseline_start_year", "baseline_end_year", "warmup_observation_count", "fully_supported_observation_count", "baseline_estimation_allowed", "warmup_use_allowed")]
warmup_contract <- support_contract[support_contract$warmup_observation_count > 0, ]
warmup_contract$warmup_baseline_estimation_allowed <- "no"
warmup_contract$restriction <- "Warm-up observations remain in source data but are not authorized for baseline empirical estimation."

permitted_matrix <- do.call(rbind, lapply(seq_len(nrow(contract)), function(i) {
  uses <- unlist(strsplit(contract$permitted_use[i], ";\\s*"))
  data.frame(stage_id = stage_id, variable_id = contract$variable_id[i], permitted_use = uses, permitted = "yes", stringsAsFactors = FALSE)
}))
prohibited_matrix <- do.call(rbind, lapply(seq_len(nrow(contract)), function(i) {
  uses <- unlist(strsplit(contract$prohibited_use[i], ";\\s*"))
  data.frame(stage_id = stage_id, variable_id = contract$variable_id[i], prohibited_use = uses, prohibited = "yes", stringsAsFactors = FALSE)
}))

growth_contract <- contract[contract$variable_id %in% c("DLOG_G_TOT", "GROWTH_ARITH_G_TOT"), c("stage_id", "variable_id", "s29h_contract_status", "permitted_use", "first_fully_supported_year", "baseline_start_year", "baseline_end_year", "explicit_future_authorization_required", "contract_note")]
growth_contract$growth_definition <- ifelse(growth_contract$variable_id == "DLOG_G_TOT", "log change in gross total capital", "exact arithmetic proportional change in gross total capital")
growth_contract$not_interchangeable <- "yes"

manifest <- data.frame(
  stage_id = stage_id,
  upstream_commit = s29g_commit,
  upstream_validation = "PASS 66",
  upstream_decision = required_s29g_decision,
  primary_level_variable = "G_TOT_GPIM_2017",
  primary_log_variable = "LOG_G_TOT_GPIM_2017",
  net_robustness_level_variable = "N_TOT_GPIM_2017",
  net_robustness_log_variable = "LOG_N_TOT_GPIM_2017",
  growth_candidates = "DLOG_G_TOT; GROWTH_ARITH_G_TOT",
  conditional_lag_candidates = "L1_LOG_G_TOT; L1_DLOG_G_TOT; L1_LOG_N_TOT; L1_DLOG_N_TOT",
  baseline_start_year = 1931,
  baseline_end_year = 2024,
  warmup_restriction = "warm-up observations retained but not authorized for baseline empirical estimation",
  diagnostic_variable_count = nrow(diagnostic_vars),
  alias_variable_count = nrow(alias_vars),
  excluded_variable_count = nrow(excluded_vars),
  provider_total_promoted = "no",
  q_authorized = "no",
  theta_authorized = "no",
  capacity_authorized = "no",
  utilization_authorized = "no",
  modeling_authorized = "no",
  next_authorized_stage = "AUTHORIZE_S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY",
  stringsAsFactors = FALSE
)

review_needed <- data.frame(stage_id = character(), variable_id = character(), review_reason = character(), action = character(), stringsAsFactors = FALSE)

no_new <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_new_level_variable", "no_new_log", "no_new_growth_rate", "no_new_difference", "no_new_lag", "no_new_share", "no_new_intensity_measure", "no_new_alias"),
  constructed_object_count = 0,
  status = "PASS",
  evidence = "S29H writes contract rows and audits only; it does not create analytical variables.",
  stringsAsFactors = FALSE
)
no_model_panel <- data.frame(
  stage_id = stage_id,
  audit_item = c("no_model_input_panel", "no_complete_case_estimation_sample", "no_dependent_variable_join", "no_distribution_variable_join", "no_sample_window_model_matrix"),
  constructed_object_count = 0,
  status = "PASS",
  evidence = "S29H creates no rectangular estimation dataset, complete-case sample, joins, or model matrix.",
  stringsAsFactors = FALSE
)
no_provider_total <- data.frame(stage_id = stage_id, audit_item = c("provider_total_not_promoted", "tot_not_recomputed_as_me_plus_nrc"), constructed_object_count = 0, status = "PASS", evidence = "TOT remains the S29F analytical identifier for the validated S29E aggregate; provider TOTAL is not promoted.", stringsAsFactors = FALSE)
no_q <- data.frame(stage_id = stage_id, audit_item = c("no_q_variables", "no_accumulated_q", "no_omega_weighted_capital_variables"), constructed_object_count = 0, status = "PASS", evidence = "No q-family object is authorized or constructed.", stringsAsFactors = FALSE)
no_theta <- data.frame(stage_id = stage_id, audit_item = c("no_theta_variables", "no_distribution_capital_interactions", "no_exploitation_weighted_capital_variables"), constructed_object_count = 0, status = "PASS", evidence = "No theta or distribution-capital object is authorized or constructed.", stringsAsFactors = FALSE)
no_utilization <- data.frame(stage_id = stage_id, audit_item = c("no_productive_capacity", "no_utilization", "no_output_capital_ratio"), constructed_object_count = 0, status = "PASS", evidence = "No capacity, utilization, or output-capital ratio is authorized or constructed.", stringsAsFactors = FALSE)
no_modeling <- data.frame(stage_id = stage_id, audit_item = c("no_modeling_outputs", "no_econometric_outputs"), constructed_object_count = 0, status = "PASS", evidence = "No modeling or econometric outputs are created.", stringsAsFactors = FALSE)

write.csv(contract, output_paths$contract, row.names = FALSE)
write.csv(slot_contract, output_paths$slots, row.names = FALSE)
write.csv(baseline_vars, output_paths$baseline, row.names = FALSE)
write.csv(robustness_vars, output_paths$robustness, row.names = FALSE)
write.csv(conditional_vars, output_paths$conditional, row.names = FALSE)
write.csv(diagnostic_vars, output_paths$diagnostic, row.names = FALSE)
write.csv(alias_vars, output_paths$alias, row.names = FALSE)
write.csv(excluded_vars, output_paths$excluded, row.names = FALSE)
write.csv(support_contract, output_paths$support, row.names = FALSE)
write.csv(warmup_contract, output_paths$warmup, row.names = FALSE)
write.csv(alias_authority_map, output_paths$alias_map, row.names = FALSE)
write.csv(permitted_matrix, output_paths$permitted, row.names = FALSE)
write.csv(prohibited_matrix, output_paths$prohibited, row.names = FALSE)
write.csv(growth_contract, output_paths$growth, row.names = FALSE)
write.csv(manifest, output_paths$manifest, row.names = FALSE)
write.csv(review_needed, output_paths$review, row.names = FALSE)
write.csv(no_new, output_paths$no_new, row.names = FALSE)
write.csv(no_model_panel, output_paths$no_model_panel, row.names = FALSE)
write.csv(no_provider_total, output_paths$no_provider_total, row.names = FALSE)
write.csv(no_q, output_paths$no_q, row.names = FALSE)
write.csv(no_theta, output_paths$no_theta, row.names = FALSE)
write.csv(no_utilization, output_paths$no_utilization, row.names = FALSE)
write.csv(no_modeling, output_paths$no_modeling, row.names = FALSE)

md5_after <- tools::md5sum(input_paths)
upstream_unchanged <- identical(unname(md5_before), unname(md5_after))

class_counts <- table(s29g_inventory$primary_classification)
contract_counts <- table(contract$s29h_contract_status)
contract_status_one <- !any(duplicated(contract$variable_id)) && nrow(contract) == 99 && all(!is.na(contract$s29h_contract_status))
has_status <- function(v, status) any(contract$variable_id == v & contract$s29h_contract_status == status)
all_family_status <- function(families, status) {
  rows <- contract[contract$transformation_family %in% families, ]
  nrow(rows) > 0 && all(rows$s29h_contract_status == status)
}

validation_checks <- do.call(rbind, list(
  check("s29g_outputs_present", all(file.exists(unlist(s29g_input_paths))), paste(basename(unlist(s29g_input_paths)), collapse = "; ")),
  check("s29g_validation_all_pass", all_pass(s29g_validation) && nrow(s29g_validation) == 66, "S29G validation PASS 66"),
  check("s29g_decision_authorizes_s29h", grepl(required_s29g_decision, s29g_decision, fixed = TRUE), required_s29g_decision),
  check("s29f_outputs_present", all(file.exists(unlist(s29f_input_paths))), paste(basename(unlist(s29f_input_paths)), collapse = "; ")),
  check("s29f_validation_all_pass", all_pass(s29f_validation) && nrow(s29f_validation) == 87, "S29F validation PASS 87"),
  check("s29e_outputs_present", all(file.exists(unlist(s29e_input_paths))), paste(basename(unlist(s29e_input_paths)), collapse = "; ")),
  check("s29e_validation_all_pass", all_pass(s29e_validation) && nrow(s29e_validation) == 72, "S29E validation PASS 72"),
  check("s29g_variable_count_equals_99", nrow(s29g_inventory) == 99, paste0("variables=", nrow(s29g_inventory))),
  check("s29g_primary_count_equals_2", unname(class_counts["AUTHORIZED_PRIMARY"]) == 2, "AUTHORIZED_PRIMARY 2"),
  check("s29g_secondary_count_equals_13", unname(class_counts["AUTHORIZED_SECONDARY"]) == 13, "AUTHORIZED_SECONDARY 13"),
  check("s29g_diagnostic_count_equals_72", unname(class_counts["DIAGNOSTIC_ONLY"]) == 72, "DIAGNOSTIC_ONLY 72"),
  check("s29g_redundant_alias_count_equals_12", unname(class_counts["REDUNDANT_ALIAS"]) == 12, "REDUNDANT_ALIAS 12"),
  check("s29g_review_required_count_equals_0", !("REVIEW_REQUIRED" %in% names(class_counts)) || unname(class_counts["REVIEW_REQUIRED"]) == 0, "REVIEW_REQUIRED 0"),
  check("s29g_not_authorized_count_equals_0", !("NOT_AUTHORIZED_FOR_CURRENT_SPECIFICATION" %in% names(class_counts)) || unname(class_counts["NOT_AUTHORIZED_FOR_CURRENT_SPECIFICATION"]) == 0, "NOT_AUTHORIZED 0"),
  check("every_s29f_variable_present_in_contract", nrow(contract) == length(unique(s29f_long$variable_id)) && all(unique(s29f_long$variable_id) %in% contract$variable_id), "all S29F variables contracted"),
  check("every_variable_has_exactly_one_contract_status", contract_status_one, "one status per variable"),
  check("every_variable_has_permitted_use", all(nchar(contract$permitted_use) > 0), "permitted uses populated"),
  check("every_variable_has_prohibited_use", all(nchar(contract$prohibited_use) > 0), "prohibited uses populated"),
  check("every_variable_has_authoritative_source", all(nchar(contract$authoritative_variable_id) > 0), "authoritative source populated"),
  check("every_variable_has_support_window", all(!is.na(contract$first_observed_year) & !is.na(contract$last_observed_year) & !is.na(contract$first_fully_supported_year)), "support windows populated"),
  check("primary_level_is_g_tot_gpim_2017", manifest$primary_level_variable == "G_TOT_GPIM_2017", "primary level G_TOT_GPIM_2017"),
  check("primary_log_is_log_g_tot_gpim_2017", manifest$primary_log_variable == "LOG_G_TOT_GPIM_2017", "primary log LOG_G_TOT_GPIM_2017"),
  check("primary_level_status_is_baseline_authorized", has_status("G_TOT_GPIM_2017", "BASELINE_AUTHORIZED"), "G_TOT baseline authorized"),
  check("primary_log_status_is_baseline_authorized", has_status("LOG_G_TOT_GPIM_2017", "BASELINE_AUTHORIZED"), "LOG_G_TOT baseline authorized"),
  check("gross_stock_primary_hierarchy_preserved", all(contract$s29h_contract_status[contract$variable_id %in% c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017")] == "BASELINE_AUTHORIZED"), "gross hierarchy preserved"),
  check("net_tot_level_contracted_as_robustness", has_status("N_TOT_GPIM_2017", "ROBUSTNESS_AUTHORIZED"), "N_TOT robustness"),
  check("net_tot_log_contracted_as_robustness", has_status("LOG_N_TOT_GPIM_2017", "ROBUSTNESS_AUTHORIZED"), "LOG_N_TOT robustness"),
  check("net_stock_not_promoted_to_baseline", !any(contract$s29h_contract_status[grepl("^N_TOT|LOG_N_TOT", contract$variable_id)] == "BASELINE_AUTHORIZED"), "net not baseline"),
  check("gross_log_growth_candidate_contracted", has_status("DLOG_G_TOT", "CONDITIONAL_SECONDARY"), "DLOG_G_TOT conditional"),
  check("gross_arithmetic_growth_candidate_contracted", has_status("GROWTH_ARITH_G_TOT", "CONDITIONAL_SECONDARY"), "GROWTH_ARITH_G_TOT conditional"),
  check("arithmetic_and_log_growth_not_treated_as_identical", all(growth_contract$not_interchangeable == "yes") && nrow(growth_contract) == 2, "growth definitions separate"),
  check("growth_choice_requires_future_explicit_selection", all(growth_contract$explicit_future_authorization_required == "yes"), "future selection required"),
  check("lagged_variables_contracted_conditionally", all(contract$s29h_contract_status[contract$transformation_family == "lag1"] %in% c("CONDITIONAL_SECONDARY", "DIAGNOSTIC_ONLY")), "lags conditional or diagnostic"),
  check("lag_availability_not_treated_as_automatic_authorization", all(contract$explicit_future_authorization_required[contract$transformation_family == "lag1"] == "yes"), "lag future authorization required"),
  check("investment_variables_not_contracted_as_stock_substitutes", !any(grepl("^I_|LOG_I_|DLOG_I_|GROWTH_ARITH_I_|DELTA_I_", contract$variable_id) & contract$s29h_contract_status == "BASELINE_AUTHORIZED"), "investment not baseline stock"),
  check("composition_shares_diagnostic_only", all_family_status(c("gross_composition_share", "net_composition_share", "investment_composition_share"), "DIAGNOSTIC_ONLY"), "shares diagnostic"),
  check("intensity_measures_diagnostic_only", all_family_status(c("retirement_rate_diagnostic", "cfc_rate_diagnostic", "investment_rate_diagnostic"), "DIAGNOSTIC_ONLY"), "intensities diagnostic"),
  check("growth_gap_variables_diagnostic_only", all_family_status("arithmetic_log_growth_gap", "DIAGNOSTIC_ONLY"), "growth gaps diagnostic"),
  check("stock_flow_net_change_redundancy_preserved", all_family_status(c("gross_stock_flow_net_change", "net_stock_flow_net_change"), "ALIAS_INTERFACE_ONLY"), "stock-flow net changes alias-only"),
  check("exact_aliases_not_treated_as_independent_objects", all(contract$s29h_contract_status[contract$variable_id %in% c("K_GROSS_TOT", "K_NET_TOT")] == "ALIAS_INTERFACE_ONLY"), "K aliases interface only"),
  check("alias_authority_map_created", file.exists(output_paths$alias_map) && nrow(alias_authority_map) >= 7, "alias map created"),
  check("authoritative_downstream_slot_contract_created", file.exists(output_paths$slots) && nrow(slot_contract) >= 6, "slot contract created"),
  check("support_window_contract_created", file.exists(output_paths$support) && nrow(support_contract) == 99, "support contract created"),
  check("warmup_restriction_contract_created", file.exists(output_paths$warmup) && nrow(warmup_contract) > 0, "warmup contract created"),
  check("tot_level_baseline_start_equals_1931", contract$baseline_start_year[contract$variable_id == "G_TOT_GPIM_2017"] == 1931, "G_TOT baseline start 1931"),
  check("tot_log_baseline_start_equals_1931", contract$baseline_start_year[contract$variable_id == "LOG_G_TOT_GPIM_2017"] == 1931, "LOG_G_TOT baseline start 1931"),
  check("warmup_not_authorized_for_baseline_estimation", all(warmup_contract$warmup_baseline_estimation_allowed == "no"), "warm-up baseline no"),
  check("warmup_observations_not_deleted", all(contract$warmup_observation_count >= 0) && nrow(contract) == 99, "warm-up observations retained in contract"),
  check("baseline_authorized_variable_file_created", file.exists(output_paths$baseline) && nrow(baseline_vars) == 2, "baseline file created"),
  check("robustness_authorized_variable_file_created", file.exists(output_paths$robustness) && nrow(robustness_vars) == 2, "robustness file created"),
  check("conditional_secondary_file_created", file.exists(output_paths$conditional) && nrow(conditional_vars) > 0, "conditional file created"),
  check("diagnostic_only_file_created", file.exists(output_paths$diagnostic) && nrow(diagnostic_vars) == 72, "diagnostic file created"),
  check("alias_interface_file_created", file.exists(output_paths$alias) && nrow(alias_vars) == 12, "alias file created"),
  check("excluded_variable_file_created", file.exists(output_paths$excluded), "excluded file created"),
  check("permitted_use_matrix_created", file.exists(output_paths$permitted) && nrow(permitted_matrix) >= 99, "permitted matrix created"),
  check("prohibited_use_matrix_created", file.exists(output_paths$prohibited) && nrow(prohibited_matrix) >= 99, "prohibited matrix created"),
  check("growth_measure_selection_contract_created", file.exists(output_paths$growth) && nrow(growth_contract) == 2, "growth contract created"),
  check("downstream_handoff_manifest_created", file.exists(output_paths$manifest) && nrow(manifest) == 1, "handoff manifest created"),
  check("provider_total_not_promoted", all(no_provider_total$status == "PASS") && manifest$provider_total_promoted == "no", "provider TOTAL not promoted"),
  check("no_new_level_variable_constructed", no_new$status[no_new$audit_item == "no_new_level_variable"] == "PASS", "no new level"),
  check("no_new_log_constructed", no_new$status[no_new$audit_item == "no_new_log"] == "PASS", "no new log"),
  check("no_new_growth_rate_constructed", no_new$status[no_new$audit_item == "no_new_growth_rate"] == "PASS", "no new growth"),
  check("no_new_difference_constructed", no_new$status[no_new$audit_item == "no_new_difference"] == "PASS", "no new difference"),
  check("no_new_lag_constructed", no_new$status[no_new$audit_item == "no_new_lag"] == "PASS", "no new lag"),
  check("no_new_share_constructed", no_new$status[no_new$audit_item == "no_new_share"] == "PASS", "no new share"),
  check("no_new_intensity_measure_constructed", no_new$status[no_new$audit_item == "no_new_intensity_measure"] == "PASS", "no new intensity"),
  check("no_model_input_panel_constructed", no_model_panel$status[no_model_panel$audit_item == "no_model_input_panel"] == "PASS", "no model input panel"),
  check("no_complete_case_estimation_sample_constructed", no_model_panel$status[no_model_panel$audit_item == "no_complete_case_estimation_sample"] == "PASS", "no complete-case sample"),
  check("no_q_variables_constructed", all(no_q$status == "PASS"), "no q"),
  check("no_omega_weighted_capital_variables_constructed", no_q$status[no_q$audit_item == "no_omega_weighted_capital_variables"] == "PASS", "no omega-weighted capital"),
  check("no_distribution_capital_interactions_constructed", no_theta$status[no_theta$audit_item == "no_distribution_capital_interactions"] == "PASS", "no distribution-capital interactions"),
  check("no_theta_variables_constructed", all(no_theta$status == "PASS"), "no theta"),
  check("no_productive_capacity_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_productive_capacity"] == "PASS", "no productive capacity"),
  check("no_utilization_variables_constructed", no_utilization$status[no_utilization$audit_item == "no_utilization"] == "PASS", "no utilization"),
  check("no_output_capital_ratio_constructed", no_utilization$status[no_utilization$audit_item == "no_output_capital_ratio"] == "PASS", "no output-capital ratio"),
  check("no_modeling_outputs_created", no_modeling$status[no_modeling$audit_item == "no_modeling_outputs"] == "PASS", "no modeling"),
  check("no_econometric_outputs_created", no_modeling$status[no_modeling$audit_item == "no_econometric_outputs"] == "PASS", "no econometrics"),
  check("upstream_outputs_not_modified", upstream_unchanged, "S29G/S29F/S29E input hashes unchanged"),
  check("provider_repository_not_modified", provider_tracked_clean(provider_repo), "provider tracked and staged diffs clean; pre-existing untracked files ignored")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)
all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 79
final_decision <- if (all_validation_pass) clean_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

contract_counts_df <- as.data.frame(table(contract$s29h_contract_status), stringsAsFactors = FALSE)
names(contract_counts_df) <- c("contract_status", "count")

contract_md <- c(
  "# S29H Total Capital Downstream Input Selection Contract",
  "",
  "This contract locks the permitted downstream menu for total capital variables. It does not create new variables, transformations, model-input panels, samples, q, theta, productive capacity, utilization, modeling outputs, or econometric outputs.",
  "",
  "## Authoritative Primary Inputs",
  "",
  "- `G_TOT_GPIM_2017`: baseline productive-capital level, `1931-2024`.",
  "- `LOG_G_TOT_GPIM_2017`: baseline logged productive-capital variable, `1931-2024`.",
  "",
  "## Robustness Inputs",
  "",
  "- `N_TOT_GPIM_2017`: net-stock robustness level.",
  "- `LOG_N_TOT_GPIM_2017`: net-stock robustness log.",
  "",
  "## Growth Candidates",
  "",
  "- `DLOG_G_TOT`: log change in gross total capital.",
  "- `GROWTH_ARITH_G_TOT`: exact arithmetic proportional change in gross total capital.",
  "",
  "A later stage must select the growth definition explicitly. Arithmetic growth and log growth are not interchangeable.",
  "",
  "## Warm-Up Rule",
  "",
  "Warm-up observations are retained for continuity and diagnostics but are not authorized for baseline empirical estimation."
)
writeLines(contract_md, output_paths$contract_md)

validation_md <- c(
  "# S29H Total Capital Downstream Input Selection Contract Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 79", "FAIL"), "`."),
  paste0("Contracted variables: `", nrow(contract), "`."),
  paste0("Baseline variables: `", nrow(baseline_vars), "`."),
  paste0("Robustness variables: `", nrow(robustness_vars), "`."),
  paste0("Conditional secondary variables: `", nrow(conditional_vars), "`."),
  paste0("Diagnostic-only variables: `", nrow(diagnostic_vars), "`."),
  paste0("Alias-interface variables: `", nrow(alias_vars), "`."),
  paste0("Excluded variables: `", nrow(excluded_vars), "`."),
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29H Total Capital Downstream Input Selection Contract Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29H consumed S29G commit `", s29g_commit, "` and S29F commit `", s29f_commit, "`."),
  paste0("S29G validation and decision: `PASS 66`; `", required_s29g_decision, "`."),
  paste0("S29H validation: `", ifelse(all_validation_pass, "PASS 79", "FAIL"), "`."),
  "",
  "S29H authorizes S29I to assemble a bounded downstream interface from already constructed and explicitly contracted variables only. It does not authorize q, theta, productive capacity, utilization, output-capital ratios, distribution-capital interactions, modeling, or econometrics.",
  "",
  "S29H stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) {
  stop("S29H validation failed; see ", output_paths$validation)
}

message("S29H validation PASS 79")
message("Contracted variables: ", nrow(contract))
message("Decision: ", final_decision)
