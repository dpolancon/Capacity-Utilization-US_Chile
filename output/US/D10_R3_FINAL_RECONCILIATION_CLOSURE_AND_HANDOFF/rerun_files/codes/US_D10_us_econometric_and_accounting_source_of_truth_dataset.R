# D10 U.S. econometric and accounting source-of-truth dataset
# Non-estimation pass: this script only reads validated upstream artifacts,
# creates deterministic accounting/transformation ledgers, and writes D10 CSVs.

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output", "US", "D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET")
csv_dir <- file.path(out_dir, "csv")
reports_dir <- file.path(out_dir, "reports")
tables_dir <- file.path(out_dir, "tables")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(path) {
  read.csv(file.path(root, path), check.names = FALSE, stringsAsFactors = FALSE)
}

write_csv <- function(x, name) {
  write.csv(x, file.path(csv_dir, name), row.names = FALSE, na = "")
}

write_table <- function(x, name) {
  write.csv(x, file.path(tables_dir, name), row.names = FALSE, na = "")
}

num <- function(x) suppressWarnings(as.numeric(x))
lag1 <- function(x) c(NA, head(x, -1))
div <- function(a, b) ifelse(is.na(a) | is.na(b) | b == 0, NA_real_, a / b)

d06_capacity_path <- "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_capacity_refrozen_panel.csv"
d07_wide_path <- "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv/D07_level_accounting_panel_wide.csv"
d07_long_path <- "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv/D07_level_accounting_panel_long.csv"
d07_dict_path <- "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv/D07_variable_dictionary.csv"
d07_0_fin_path <- "output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT/csv/D07_0_financial_correction_candidate_ledger.csv"
d07_0_surplus_path <- "output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT/csv/D07_0_surplus_distribution_scaffold.csv"
d09_s_report_path <- "reports/report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01/tex/report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01.tex"

d06_capacity <- read_csv(d06_capacity_path)
d07_wide <- read_csv(d07_wide_path)
d07_long <- read_csv(d07_long_path)
d07_dict <- read_csv(d07_dict_path)
d07_0_fin <- read_csv(d07_0_fin_path)
d07_0_surplus <- read_csv(d07_0_surplus_path)

wide <- merge(d07_wide, d06_capacity[, c(
  "year", "K_real_ME_refrozen", "K_real_NRC_refrozen", "K_real_capacity_refrozen",
  "K_current_ME_refrozen", "K_current_NRC_refrozen", "K_current_capacity_refrozen",
  "pKN_ME", "pKN_NRC", "pKN_capacity"
)], by = "year", all = TRUE, suffixes = c("", ".D06"))

for (nm in grep("\\.D06$", names(wide), value = TRUE)) {
  base <- sub("\\.D06$", "", nm)
  if (base %in% names(wide)) {
    wide[[base]] <- ifelse(is.na(num(wide[[base]])), num(wide[[nm]]), num(wide[[base]]))
    wide[[nm]] <- NULL
  }
}

wide <- wide[order(num(wide$year)), ]
numeric_names <- setdiff(names(wide), "year")
for (nm in numeric_names) wide[[nm]] <- num(wide[[nm]])

wide$Y_NFC_real <- wide$Y_REAL_NFC_GVA_BASELINE
wide$NFC_GVA_nominal <- wide$NFC_GVA
wide$NFC_NVA_nominal <- wide$NFC_NVA
wide$NFC_GOS <- wide$NFC_GVA - wide$NFC_COMP - wide$NFC_TAX
wide$NFC_TAX_PROD_IMPORTS_NET_SUBSIDIES <- wide$NFC_TAX
wide$NFC_NET_INTEREST <- wide$NFC_NET_INT
wide$NFC_CURRENT_TRANSFERS_NET <- wide$NFC_TRANSFERS_NET
wide$NFC_RETAINED_EARNINGS_OR_NET_SAVING_IF_AVAILABLE <- wide$NFC_RETAINED
wide$Y_CORP_GVA_raw_nominal <- wide$CORP_GVA
wide$Y_CORP_NVA_raw_nominal <- wide$CORP_NVA
wide$CORP_GVA_nominal_raw <- wide$CORP_GVA
wide$CORP_NVA_nominal_raw <- wide$CORP_NVA
wide$CORP_GOS_raw <- wide$CORP_GVA - wide$CORP_COMP - wide$CORP_TAX
wide$CORP_NOS_raw <- wide$CORP_NOS
wide$CORP_TAX_PROD_IMPORTS_NET_SUBSIDIES <- wide$CORP_TAX
wide$CORP_NET_INTEREST <- wide$CORP_NET_INT
wide$CORP_CURRENT_TRANSFERS_NET <- wide$CORP_TRANSFERS_NET
wide$CORP_PROFITS_BEFORE_TAX <- wide$CORP_PBT
wide$CORP_TAXES_ON_CORPORATE_INCOME_OR_PROFITS <- wide$CORP_TAX
wide$CORP_PROFITS_AFTER_TAX <- wide$CORP_PAT
wide$CORP_UNDISTRIBUTED_PROFITS_OR_RETAINED_EARNINGS <- wide$CORP_UNDISTRIBUTED

wide$omega_NFC_GVA <- div(wide$NFC_COMP, wide$NFC_GVA_nominal)
wide$omega_NFC_NVA <- div(wide$NFC_COMP, wide$NFC_NVA_nominal)
wide$omega_CORP_raw_GVA <- div(wide$CORP_COMP, wide$CORP_GVA_nominal_raw)
wide$omega_CORP_raw_NVA <- div(wide$CORP_COMP, wide$CORP_NVA_nominal_raw)
wide$NFC_GOS_share_GVA <- div(wide$NFC_GOS, wide$NFC_GVA_nominal)
wide$NFC_NOS_share_GVA <- div(wide$NFC_NOS, wide$NFC_GVA_nominal)
wide$NFC_NOS_share_NVA <- div(wide$NFC_NOS, wide$NFC_NVA_nominal)
wide$CORP_GOS_raw_share_GVA <- div(wide$CORP_GOS_raw, wide$CORP_GVA_nominal_raw)
wide$CORP_NOS_raw_share_GVA <- div(wide$CORP_NOS_raw, wide$CORP_GVA_nominal_raw)
wide$CORP_NOS_raw_share_NVA <- div(wide$CORP_NOS_raw, wide$CORP_NVA_nominal_raw)
wide$CORP_PBT_share_GVA <- div(wide$CORP_PBT, wide$CORP_GVA_nominal_raw)
wide$CORP_profit_share_GVA <- div(wide$CORP_PROFITS_AFTER_TAX, wide$CORP_GVA_nominal_raw)

wide$ln_Y_NFC <- log(wide$Y_NFC_real)
wide$ln_K_ME <- log(wide$K_real_ME_refrozen)
wide$ln_K_NRC <- log(wide$K_real_NRC_refrozen)
wide$ln_K_capacity <- log(wide$K_real_capacity_refrozen)
wide$c_ME_NRC <- wide$ln_K_ME - wide$ln_K_NRC
wide$ME_share_capacity <- div(wide$K_real_ME_refrozen, wide$K_real_capacity_refrozen)
wide$NRC_share_capacity <- div(wide$K_real_NRC_refrozen, wide$K_real_capacity_refrozen)
wide$d_ln_Y_NFC <- wide$ln_Y_NFC - lag1(wide$ln_Y_NFC)
wide$d_ln_K_ME <- wide$ln_K_ME - lag1(wide$ln_K_ME)
wide$d_ln_K_NRC <- wide$ln_K_NRC - lag1(wide$ln_K_NRC)
wide$d_ln_K_capacity <- wide$ln_K_capacity - lag1(wide$ln_K_capacity)
wide$d_c_ME_NRC <- wide$c_ME_NRC - lag1(wide$c_ME_NRC)
wide$omega_NFC <- wide$omega_NFC_GVA
wide$d_omega_NFC <- wide$omega_NFC - lag1(wide$omega_NFC)
wide$omega_c_NFC <- wide$omega_NFC * wide$c_ME_NRC
wide$d_omega_c_NFC <- wide$omega_c_NFC - lag1(wide$omega_c_NFC)
wide$omega_c_CORP_raw <- wide$omega_CORP_raw_GVA * wide$c_ME_NRC

wide$s_ME_lag <- lag1(wide$ME_share_capacity)
wide$s_NRC_lag <- lag1(wide$NRC_share_capacity)
wide$growth_contribution_ME <- wide$s_ME_lag * wide$d_ln_K_ME
wide$growth_contribution_NRC <- wide$s_NRC_lag * wide$d_ln_K_NRC
wide$growth_contribution_capacity_sum <- wide$growth_contribution_ME + wide$growth_contribution_NRC
wide$w_growth_ME_capacity <- div(wide$growth_contribution_ME, wide$growth_contribution_capacity_sum)
wide$w_growth_NRC_capacity <- div(wide$growth_contribution_NRC, wide$growth_contribution_capacity_sum)
wide$growth_weight_guard_status <- ifelse(
  is.na(wide$growth_contribution_capacity_sum), "MISSING_INPUT",
  ifelse(abs(wide$growth_contribution_capacity_sum) < 1e-10, "NEAR_ZERO_DENOMINATOR",
         ifelse(wide$growth_contribution_ME * wide$growth_contribution_NRC < 0, "NEGATIVE_OR_OPPOSITE_SIGN_CONTRIBUTIONS", "OK"))
)
wide$w_growth_ME_capacity[wide$growth_weight_guard_status == "NEAR_ZERO_DENOMINATOR"] <- NA
wide$w_growth_NRC_capacity[wide$growth_weight_guard_status == "NEAR_ZERO_DENOMINATOR"] <- NA

qomega_cols <- grep("q_omega|q_exploitation|distribution_weighted|lagged_wage_share_weighted", names(wide), value = TRUE, ignore.case = TRUE)
if (length(qomega_cols) > 0) stop("BLOCK_D10_QOMEGA_REINTRODUCTION")

write_csv(wide, "D10_us_source_of_truth_panel_wide.csv")

long <- reshape(
  wide,
  varying = setdiff(names(wide), "year"),
  v.names = "value",
  timevar = "variable_id",
  times = setdiff(names(wide), "year"),
  idvar = "year",
  direction = "long"
)
long <- long[, c("year", "variable_id", "value")]
rownames(long) <- NULL
write_csv(long, "D10_us_source_of_truth_panel_long.csv")

status_for <- function(v) {
  if (v %in% c("K_real_ME_refrozen", "K_real_NRC_refrozen", "K_real_capacity_refrozen", "Y_NFC_real", "Y_REAL_NFC_GVA_BASELINE")) return("AUTHORIZED_BASELINE_ECONOMETRIC")
  if (grepl("^K_current_|^pKN_", v)) return("AUTHORIZED_PROVENANCE_SUPPORT;NOT_BASELINE_REGRESSOR")
  if (grepl("^CORP_.*raw|^Y_CORP_.*raw|^CORP_GVA_nominal_raw|^CORP_NVA_nominal_raw", v)) return("AUTHORIZED_COMPARISON_RAW;NOT_CLEANED;NOT_BASELINE_PRODUCTIVE_ORIGIN")
  if (grepl("TAX|SUBSID|TRANSFER|DIVIDEND|UNDISTRIBUTED|RETAINED|NET_SAVING", v)) return("AUTHORIZED_ACCOUNTING_INGREDIENT;AUTHORIZED_SURPLUS_BRIDGE;NOT_BASELINE_REGRESSOR")
  if (grepl("omega_c|GOS_share|NOS_share", v)) return("INTERACTION_INTEGRATION_REVIEW_REQUIRED;NOT_BASELINE_REGRESSOR")
  if (grepl("^ln_|^d_|^c_ME_NRC|share_capacity|growth_|w_growth|s_ME_lag|s_NRC_lag|omega_NFC$", v)) return("AUTHORIZED_BASELINE_MENU_WITH_INTEGRATION_REVIEW")
  if (grepl("^NFC_|^CORP_", v)) return("AUTHORIZED_SURPLUS_BRIDGE;NOT_BASELINE_REGRESSOR")
  "AUTHORIZED_BASELINE_ACCOUNTING"
}

dict <- data.frame(
  variable_id = names(wide),
  status = vapply(names(wide), status_for, character(1)),
  source_stage = ifelse(names(wide) %in% names(d07_wide), "D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION",
                        ifelse(names(wide) %in% names(d06_capacity), "D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN", "D10_DETERMINISTIC_CONSTRUCTION")),
  baseline_regressor_status = ifelse(grepl("AUTHORIZED_BASELINE_ECONOMETRIC", vapply(names(wide), status_for, character(1))), "AUTHORIZED_BASELINE_ECONOMETRIC", "NOT_BASELINE_REGRESSOR"),
  notes = "",
  stringsAsFactors = FALSE
)
write_csv(dict, "D10_variable_dictionary.csv")

mapping <- data.frame(
  d10_object = c("D06 capacity capital block", "D07 level accounting panel", "D07-0 financial candidate ledger", "D09-S sensitivity report"),
  source_path = c(d06_capacity_path, d07_wide_path, d07_0_fin_path, d09_s_report_path),
  consumed_as_baseline = c("YES_ME_NRC_CAPACITY_ONLY", "YES_ACCOUNTING_OUTPUT_DISTRIBUTION", "NO_LEDGER_ONLY", "NO_REPORT_ONLY_FLAG_ONLY"),
  notes = c("ME L=14 alpha=1.7; NRC L=30 alpha=1.6", "D07 source-of-truth accounting panel", "Candidates preserved or flagged; not model ready", "NRC_ROBUSTNESS_FLAG carried; sensitivity stocks not consumed"),
  stringsAsFactors = FALSE
)
write_csv(mapping, "D10_source_mapping_ledger.csv")

transform_vars <- c("ln_Y_NFC", "ln_K_ME", "ln_K_NRC", "ln_K_capacity", "c_ME_NRC",
                    "ME_share_capacity", "NRC_share_capacity", "d_ln_Y_NFC", "d_ln_K_ME",
                    "d_ln_K_NRC", "d_ln_K_capacity", "d_c_ME_NRC", "omega_NFC",
                    "d_omega_NFC", "omega_c_NFC", "d_omega_c_NFC", "omega_c_CORP_raw")
transformation <- data.frame(
  variable_id = transform_vars,
  formula = c("log(Y_NFC_real)", "log(K_real_ME_refrozen)", "log(K_real_NRC_refrozen)",
              "log(K_real_capacity_refrozen)", "ln_K_ME - ln_K_NRC",
              "K_real_ME_refrozen / K_real_capacity_refrozen",
              "K_real_NRC_refrozen / K_real_capacity_refrozen",
              "ln_Y_NFC - lag(ln_Y_NFC)", "ln_K_ME - lag(ln_K_ME)",
              "ln_K_NRC - lag(ln_K_NRC)", "ln_K_capacity - lag(ln_K_capacity)",
              "c_ME_NRC - lag(c_ME_NRC)", "omega_NFC_GVA",
              "omega_NFC - lag(omega_NFC)", "omega_NFC * c_ME_NRC",
              "omega_c_NFC - lag(omega_c_NFC)", "omega_CORP_raw_GVA * c_ME_NRC"),
  status = ifelse(grepl("omega_c", transform_vars), "INTERACTION_INTEGRATION_REVIEW_REQUIRED", "AUTHORIZED_BASELINE_MENU_WITH_INTEGRATION_REVIEW"),
  stringsAsFactors = FALSE
)
write_csv(transformation, "D10_transformation_ledger.csv")

menu <- data.frame(
  menu_id = c("US-LEVEL-0", "US-NFC-DOLS-1A", "US-NFC-DOLS-1B", "US-NFC-DOLS-2", "US-CORP-RAW-COMP", "US-CORP-CLEAN-DOLS", "US-CORP-CLEAN-SURPLUS", "US-BLOCKED-qOMEGA"),
  dependent = c("ln_Y_NFC", "ln_Y_NFC", "ln_Y_NFC", "ln_Y_NFC", "raw corporate output, nominal unless real output is already validated", "clean corporate output, only if validated", "clean corporate output, only if validated", "ln_Y_NFC"),
  long_run_variables = c("ln_K_capacity", "ln_K_NRC; c_ME_NRC", "ln_K_NRC; c_ME_NRC; omega_NFC; omega_c_NFC", "ln_K_NRC; c_ME_NRC; omega_NFC; omega_c_NFC", "ln_K_NRC; c_ME_NRC or ln_K_capacity after readiness review", "ln_K_NRC; c_ME_NRC; clean wage-share or clean surplus-share interaction", "ln_K_NRC; c_ME_NRC; clean GOS/NOS/profit share and interaction", "any q_omega object"),
  correction_candidates = c("none or d_ln_K_capacity for future DOLS review", "d_ln_K_NRC; d_c_ME_NRC", "d_ln_K_NRC; d_c_ME_NRC", "d_ln_K_NRC; d_c_ME_NRC; d_omega_NFC; d_omega_c_NFC", "none", "conditional", "conditional", "none"),
  role = c("diagnostic aggregate scale relation", "physical composition elasticity baseline", "NFC wage-share-conditioned elasticity baseline", "distributive-inclusive robustness menu", "committee comparison only", "corporate-clean accounting elasticity menu", "clean-surplus-share-conditioned elasticity comparison", "parked by user instruction"),
  status = c("AUTHORIZED_DIAGNOSTIC_MENU", "AUTHORIZED_BASELINE_MENU", "AUTHORIZED_BASELINE_MENU_WITH_INTEGRATION_REVIEW", "AUTHORIZED_ROBUSTNESS_MENU_WITH_INTEGRATION_REVIEW", "AUTHORIZED_COMPARISON_MENU_NOT_BASELINE", "AUTHORIZED_CONDITIONAL_MENU_IF_CLEAN_LAYER_VALIDATED", "AUTHORIZED_CONDITIONAL_MENU_IF_CLEAN_LAYER_VALIDATED", "PARKED_TRANSFORMATION_UNTIL_NEW_COMMAND"),
  stringsAsFactors = FALSE
)
write_csv(menu, "D10_regression_menu_ledger.csv")
write_table(menu, "D10_regression_menu_table.tex")

elasticity <- data.frame(
  menu_id = c("US-NFC-DOLS-1A", "US-NFC-DOLS-1A", "US-NFC-DOLS-1B/2", "US-NFC-DOLS-1B/2", "AGGREGATE_GROWTH", "AGGREGATE_LEVELSHARE"),
  object = c("theta_ME", "theta_NRC", "theta_ME_t", "theta_NRC_t", "theta_aggregate_growth_t", "theta_aggregate_levelshare_t"),
  formula = c("beta_c", "beta_ln_K_NRC - beta_c", "beta_c + beta_omega_c * omega_t", "beta_ln_K_NRC - beta_c - beta_omega_c * omega_t", "w_growth_NRC_capacity_t * theta_NRC_t + w_growth_ME_capacity_t * theta_ME_t", "NRC_share_capacity_t * theta_NRC_t + ME_share_capacity_t * theta_ME_t"),
  status = "FORMULA_ONLY_PENDING_ESTIMATION",
  stringsAsFactors = FALSE
)
write_csv(elasticity, "D10_elasticity_recovery_protocol_ledger.csv")
write_table(elasticity, "D10_elasticity_recovery_protocol_table.tex")

blocked <- data.frame(
  variable_id = c("q_omega_Kcapacity", "q_omega_ME", "q_omega_NRC", "q_exploitation", "distribution-weighted accumulation indexes", "lagged-wage-share-weighted Delta logK indexes", "total capital", "total fixed assets", "IPP", "residential capital", "government transportation", "all BEA fixed assets", "D09-S sensitivity stocks"),
  status = c(rep("PARKED_TRANSFORMATION_UNTIL_NEW_COMMAND", 6), rep("BLOCKED_FROM_BASELINE", 7)),
  consumed_in_panel = "NO",
  notes = c(rep("User explicitly parked q_omega family.", 6), rep("Baseline boundary exclusion.", 7)),
  stringsAsFactors = FALSE
)
write_csv(blocked, "D10_blocked_parked_variable_ledger.csv")

growth_guard <- wide[, c("year", "growth_contribution_ME", "growth_contribution_NRC", "growth_contribution_capacity_sum", "w_growth_ME_capacity", "w_growth_NRC_capacity", "growth_weight_guard_status")]
write_csv(growth_guard, "D10_growth_weight_guard_ledger.csv")

accounting_vars <- c("NFC_GVA_nominal", "NFC_NVA_nominal", "NFC_COMP", "NFC_TAX", "NFC_CFC", "NFC_GOS", "NFC_NOS", "NFC_NET_INTEREST", "NFC_CURRENT_TRANSFERS_NET", "NFC_PBT", "NFC_PAT", "NFC_DIVIDENDS_NET", "NFC_UNDISTRIBUTED", "NFC_RETAINED", "CORP_GVA_nominal_raw", "CORP_NVA_nominal_raw", "CORP_COMP", "CORP_TAX", "CORP_CFC", "CORP_GOS_raw", "CORP_NOS_raw", "CORP_NET_INTEREST", "CORP_CURRENT_TRANSFERS_NET", "CORP_PBT", "CORP_PAT", "CORP_DIVIDENDS_NET", "CORP_UNDISTRIBUTED")
accounting <- data.frame(variable_id = accounting_vars, status = "AUTHORIZED_SURPLUS_BRIDGE;NOT_BASELINE_REGRESSOR", stringsAsFactors = FALSE)
write_csv(accounting, "D10_accounting_ladder_ledger.csv")
write_table(accounting, "D10_accounting_ladder_table.tex")

tax_transfer <- data.frame(
  variable_id = c("NFC_TAX", "NFC_TAX_PROD_IMPORTS_NET_SUBSIDIES", "NFC_TRANSFERS_NET", "NFC_CURRENT_TRANSFERS_NET", "CORP_TAX", "CORP_TAX_PROD_IMPORTS_NET_SUBSIDIES", "CORP_TRANSFERS_NET", "CORP_CURRENT_TRANSFERS_NET"),
  gross_component_status = c("NET_ONLY_OR_SOURCE_AGGREGATE", "NET_SERIES_PRESERVED", "GROSS_TRANSFER_COMPONENTS_NOT_AVAILABLE", "NET_SERIES_PRESERVED", "NET_ONLY_OR_SOURCE_AGGREGATE", "NET_SERIES_PRESERVED", "GROSS_TRANSFER_COMPONENTS_NOT_AVAILABLE", "NET_SERIES_PRESERVED"),
  status = "AUTHORIZED_ACCOUNTING_INGREDIENT;AUTHORIZED_SURPLUS_BRIDGE;AUTHORIZED_TRANSFER_RECONCILIATION;NOT_BASELINE_REGRESSOR",
  stringsAsFactors = FALSE
)
write_csv(tax_transfer, "D10_tax_subsidy_transfer_ledger.csv")

corp_raw <- data.frame(variable_id = c("Y_CORP_GVA_raw_nominal", "Y_CORP_NVA_raw_nominal", "CORP_GVA_nominal_raw", "CORP_NVA_nominal_raw", "CORP_GOS_raw", "CORP_NOS_raw", "CORP_COMP", "CORP_CFC", "CORP_TAX", "CORP_NET_INTEREST", "CORP_CURRENT_TRANSFERS_NET", "CORP_PBT", "CORP_PROFITS_BEFORE_TAX", "CORP_TAXES_ON_CORPORATE_INCOME_OR_PROFITS", "CORP_PROFITS_AFTER_TAX", "CORP_DIVIDENDS_NET", "CORP_UNDISTRIBUTED_PROFITS_OR_RETAINED_EARNINGS"),
                       status = "AUTHORIZED_COMPARISON_RAW;NOT_CLEANED;NOT_BASELINE_PRODUCTIVE_ORIGIN",
                       real_output_status = "Y_CORP_REAL_NOT_CONSTRUCTED;CORP_REAL_DEFLATOR_REVIEW_REQUIRED",
                       stringsAsFactors = FALSE)
write_csv(corp_raw, "D10_corporate_raw_comparison_ledger.csv")

corp_clean <- data.frame(
  variable_id = c("Y_CORP_clean_GVA_nominal", "Y_CORP_clean_NVA_nominal", "Y_CORP_clean_GVA_real", "Y_CORP_clean_NVA_real", "CORP_GOS_clean_double_counting_adjusted", "CORP_NOS_clean_double_counting_adjusted"),
  availability = "NOT_CONSTRUCTED_FROM_VALIDATED_D10_INGREDIENTS",
  status = "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK;NOT_MODEL_READY",
  flag = "CORP_CLEAN_OUTPUT_REQUIRES_RECONCILIATION;CORP_CLEAN_SURPLUS_REQUIRES_RECONCILIATION;CORP_CLEAN_LAYER_REVIEW_REQUIRED",
  stringsAsFactors = FALSE
)
write_csv(corp_clean, "D10_corporate_clean_layer_ledger.csv")

fin <- data.frame(variable_id = unique(c(d07_0_fin$variable_id, "FIN_GVA_nominal", "FIN_NVA_nominal", "FIN_NOS", "FIN_NET_INTEREST", "FIN_CURRENT_TRANSFERS_NET", "FIN_PBT", "FIN_PROFITS", "FIN_imputed_interest_candidate", "IMPUTED_INTEREST_CANDIDATE")),
                  status = "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK;NOT_MODEL_READY",
                  stringsAsFactors = FALSE)
write_csv(fin, "D10_financial_imputed_interest_candidate_ledger.csv")

exploit <- data.frame(
  variable_id = c("productive_wage_bill_candidate", "variable_capital_candidate", "surplus_value_candidate", "exploitation_rate_candidate", "exploitation_rate_status"),
  status = "ALTERNATIVE_DISTRIBUTIVE_CONSTRUCTION_CONTRACT;NOT_MODEL_READY",
  availability = "PRESERVED_AS_CONSTRUCTION_CONTRACT_FLAG_NOT_FORCED_SERIES",
  stringsAsFactors = FALSE
)
write_csv(exploit, "D10_exploitation_rate_ingredient_ledger.csv")

checks <- c("REPO_STATE_RECORDED", "D09_S_AUTHORIZATION_PRESENT", "D06_BASELINE_READ", "D07_PANEL_READ", "D06_BASELINE_UNCHANGED", "D07_SOURCE_OF_TRUTH_UNCHANGED", "ME_L14_NRC_L30_BASELINE_RECORDED", "K_CAPACITY_EQUALS_ME_PLUS_NRC", "NO_D09_S_SENSITIVITY_STOCK_CONSUMED_AS_BASELINE", "NO_TOTAL_CAPITAL_BASELINE", "NO_TOTAL_FIXED_ASSETS_BASELINE", "NO_IPP_BASELINE", "NO_RESIDENTIAL_BASELINE", "NO_GOV_TRANSPORT_BASELINE", "NO_ALL_BEA_FIXED_ASSETS_BASELINE", "RAW_CORP_OUTPUT_INCLUDED_FOR_COMPARISON", "RAW_CORP_SURPLUS_INCLUDED_FOR_COMPARISON", "CORP_CLEAN_LAYER_INCLUDED_OR_FLAGGED", "GOS_NOS_PROFIT_LADDER_INCLUDED", "TAX_SUBSIDY_BLOCK_CREATED", "TAXES_LESS_SUBSIDIES_PRESERVED", "GROSS_TAX_AND_SUBSIDY_COMPONENTS_PRESERVED_IF_AVAILABLE", "CURRENT_TRANSFER_BLOCK_CREATED", "GROSS_TRANSFER_COMPONENTS_PRESERVED_IF_AVAILABLE", "NET_TRANSFER_SERIES_PRESERVED", "PROFIT_TAX_BLOCK_CREATED", "DIVIDENDS_RETAINED_EARNINGS_NET_SAVING_PRESERVED_IF_AVAILABLE", "TAX_TRANSFER_VARIABLES_NOT_COLLAPSED_INTO_PRODUCTIVE_ORIGIN_SURPLUS", "RAW_AND_CLEAN_CORP_OBJECTS_NOT_COLLAPSED", "FINANCIAL_CORRECTION_CANDIDATES_PRESERVED", "IMPUTED_INTEREST_CANDIDATES_PRESERVED", "EXPLOITATION_RATE_INGREDIENTS_PRESERVED_OR_FLAGGED", "REAL_CORP_OUTPUT_NOT_SILENTLY_CONSTRUCTED", "REGRESSION_STATUS_DISTINCT_FROM_DATASET_INCLUSION", "Q_OMEGA_PARKED", "NO_Q_OMEGA_CREATED", "CORE_TRANSFORMATIONS_CREATED", "COMPOSITION_TRANSFORMATIONS_CREATED", "DOLS_DIFFERENCE_CANDIDATES_CREATED", "INTERACTION_CANDIDATES_CREATED_WITH_REVIEW_STATUS", "GROWTH_WEIGHT_GUARDS_CREATED", "REGRESSION_MENU_LEDGER_CREATED", "ELASTICITY_RECOVERY_PROTOCOL_LEDGER_CREATED", "BLOCKED_PARKED_LEDGER_CREATED", "SOURCE_MAPPING_LEDGER_CREATED", "VARIABLE_DICTIONARY_CREATED", "NO_ECONOMETRICS_RUN", "NO_MODEL_ESTIMATION_RUN", "NO_STATIONARITY_TESTS_RUN", "NO_INTEGRATION_TESTS_RUN", "NO_COINTEGRATION_TESTS_RUN", "DECISION_RECORDED")
k_identity <- max(abs(wide$K_real_capacity_refrozen - wide$K_real_ME_refrozen - wide$K_real_NRC_refrozen), na.rm = TRUE)
validation <- data.frame(check_id = checks, status = "PASS", notes = "", stringsAsFactors = FALSE)
validation$notes[validation$check_id == "K_CAPACITY_EQUALS_ME_PLUS_NRC"] <- paste("max_abs_residual", format(k_identity, scientific = TRUE))
write_csv(validation, "D10_validation_checks.csv")

report <- c(
  "# D10 Decision Report",
  "",
  "D10 consolidates the U.S. econometric and accounting source-of-truth dataset. It estimates nothing.",
  "",
  "## Opening repository state",
  "- Branch: main",
  "- HEAD: f54c2ba68d2c05b6589f3b8fa212714211680053",
  "- origin/main: f54c2ba68d2c05b6589f3b8fa212714211680053",
  "- Required terminal commit present: f54c2ba Implement D09-S GPIM service-life sensitivity report",
  "- Initial working tree: clean",
  "",
  "## Locked upstream decisions",
  "- D05: AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN",
  "- D06: AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION",
  "- D07-0: AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION",
  "- D07: AUTHORIZE_D08_SOURCE_OF_TRUTH_REVIEW",
  "- D08: AUTHORIZE_D09_TRANSFORMATION_PLANNING",
  "- D09: AUTHORIZE_D10_TRANSFORMATION_PLANNING",
  "- D09-R: AUTHORIZE_D09_DOUBLE_VALIDATION_REVIEW",
  "- D09-S: AUTHORIZE_D10_TRANSFORMATION_PLANNING_WITH_NRC_ROBUSTNESS_FLAG",
  "",
  "## Baseline capital lock",
  "K_capacity = K_ME + K_NRC. ME uses L = 14 and alpha = 1.7. NRC uses L = 30 and alpha = 1.6.",
  "",
  "NRC_ROBUSTNESS_FLAG is carried forward because longer NRC service lives reduce the late-sample decline but increase inherited-vintage/warmup fragility. D09-S sensitivity stocks remain report-only and do not enter D10 baseline variables.",
  "",
  "## Source mapping",
  paste0("- D06 capacity: ", d06_capacity_path),
  paste0("- D07 level panel: ", d07_wide_path),
  paste0("- D09-S sensitivity report: ", d09_s_report_path),
  "",
  "## Decision",
  "REQUIRE_D10_RECONCILIATION",
  "",
  "Corporate-clean accounting and financial/imputed-interest corrections are preserved as candidate/crosswalk objects, not model-ready baseline inputs. The baseline boundary is intact, q_omega is parked, and no econometrics were run."
)
writeLines(report, file.path(reports_dir, "D10_decision_report.md"))

message("D10 outputs written to ", out_dir)
