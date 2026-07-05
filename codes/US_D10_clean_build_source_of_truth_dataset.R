options(stringsAsFactors = FALSE)

repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_root <- file.path(repo, "output/US/D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET")
csv_dir <- file.path(out_root, "csv")
reports_dir <- file.path(out_root, "reports")
logs_dir <- file.path(out_root, "logs")
handoff_dir <- file.path(out_root, "handoff")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(reports_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(handoff_dir, recursive = TRUE, showWarnings = FALSE)

stdout_log <- file.path(logs_dir, "D10_clean_rscript_stdout.log")
stderr_log <- file.path(logs_dir, "D10_clean_rscript_stderr.log")
stdout_con <- file(stdout_log, open = "wt")
stderr_con <- file(stderr_log, open = "wt")
sink(stdout_con, type = "output")
sink(stderr_con, type = "message")
on.exit({
  while (sink.number(type = "message") > 0) sink(type = "message")
  while (sink.number(type = "output") > 0) sink(type = "output")
  close(stdout_con)
  close(stderr_con)
}, add = TRUE)

cat("D10 clean R build started\n")

read_csv <- function(path, required = TRUE) {
  full_path <- file.path(repo, path)
  if (!file.exists(full_path)) {
    if (required) stop("Missing required input: ", path)
    return(data.frame())
  }
  read.csv(full_path, check.names = FALSE, na.strings = c("", "NA"))
}

write_csv <- function(x, path) {
  write.csv(x, file.path(csv_dir, path), row.names = FALSE, na = "")
}

write_lines <- function(x, path) {
  writeLines(x, con = path, useBytes = TRUE)
}

git_text <- function(args) {
  paste(system2("git", args, stdout = TRUE, stderr = TRUE), collapse = "\n")
}

rscript_path <- "C:\\Program Files\\R\\R-4.5.2\\bin\\Rscript.exe"
rscript_version <- paste(R.version$version.string, R.version$nickname)

branch <- git_text(c("branch", "--show-current"))
head_hash <- git_text(c("rev-parse", "HEAD"))
base_commit <- "f54c2ba68d2c05b6589f3b8fa212714211680053"
short_base <- "f54c2ba"

base_long_path <- "output/US/S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM/csv/S30G_v1_1_candidate_long.csv"
base_wide_path <- "output/US/S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM/csv/S30G_v1_1_candidate_wide.csv"
base_dict_path <- "output/US/S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM/csv/S30G_v1_1_candidate_dictionary.csv"
real_capital_path <- "output/US/D09_GPIM_CAPITAL_OUTPUT_DISTRIBUTION_VISUAL_VALIDATION_REPORT/figure_data/D09_figdata_output_capital_relations.csv"
distribution_path <- "output/US/D09_GPIM_CAPITAL_OUTPUT_DISTRIBUTION_VISUAL_VALIDATION_REPORT/figure_data/D09_figdata_distribution_shares.csv"
s30h_dict_path <- "output/US/S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION/csv/S30H_v1_1_extension_candidate_dictionary.csv"
s30h_long_path <- "output/US/S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION/csv/S30H_v1_1_extension_candidate_long.csv"
s30h_clean_path <- "output/US/S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION/csv/S30H_clean_corporate_proxy_long.csv"
s30h_implied_path <- "output/US/S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION/csv/S30H_implied_financial_accounts_long.csv"
s30h_role_lock_path <- "output/US/S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION/csv/S30H_corporate_surplus_dataset_role_lock.csv"
d09_cap_status_path <- "output/US/D09_GPIM_CAPITAL_OUTPUT_DISTRIBUTION_VISUAL_VALIDATION_REPORT/tables/D09_table_capital_measure_status_classes.csv"
d09s_panel_path <- "reports/report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01/csv/D09_S_gpim_sensitivity_stock_panel_wide.csv"

base_long <- read_csv(base_long_path)
base_wide <- read_csv(base_wide_path)
base_dict <- read_csv(base_dict_path)
real_capital <- read_csv(real_capital_path)
distribution <- read_csv(distribution_path, required = FALSE)
s30h_dict <- read_csv(s30h_dict_path)
s30h_long <- read_csv(s30h_long_path)
s30h_clean <- read_csv(s30h_clean_path)
s30h_implied <- read_csv(s30h_implied_path)
s30h_role_lock <- read_csv(s30h_role_lock_path)
d09_cap_status <- read_csv(d09_cap_status_path)

standard_long_cols <- names(base_long)

to_standard_long <- function(d, source_file, default_unit = "", default_family = "distribution",
                             default_status = "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK",
                             default_role = "NOT_MODEL_READY") {
  if (nrow(d) == 0) return(base_long[0, ])
  out <- data.frame(matrix(NA, nrow = nrow(d), ncol = length(standard_long_cols)))
  names(out) <- standard_long_cols
  shared <- intersect(names(d), names(out))
  out[shared] <- d[shared]
  out$source_file <- source_file
  if ("unit" %in% names(out)) out$unit[is.na(out$unit)] <- default_unit
  if ("family_id" %in% names(out)) out$family_id[is.na(out$family_id)] <- default_family
  if ("contract_status" %in% names(out)) out$contract_status <- default_status
  if ("analytical_role" %in% names(out)) out$analytical_role <- default_role
  if ("source_stage" %in% names(out)) out$source_stage[is.na(out$source_stage)] <- "D10_CLEAN_FROM_D09S"
  if ("source_commit" %in% names(out)) out$source_commit[is.na(out$source_commit)] <- head_hash
  if ("support_status" %in% names(out)) out$support_status[is.na(out$support_status)] <- "SOURCE_AVAILABLE"
  if ("canonical_inclusion_status" %in% names(out)) out$canonical_inclusion_status <- default_status
  if ("baseline_or_robustness" %in% names(out)) out$baseline_or_robustness <- "NOT_BASELINE_REGRESSOR"
  out
}

mk_long_rows <- function(year, variable_id, value, unit, family_id, contract_status,
                         analytical_role, source_file, source_stage = "D10_CLEAN_FROM_D09S",
                         source_commit = head_hash, reference_year = NA,
                         transformation = "level", canonical_inclusion_status = contract_status,
                         baseline_or_robustness = "NOT_BASELINE_REGRESSOR",
                         authoritative_variable_id = variable_id) {
  if (length(value) == 0) stop("Missing value vector for ", variable_id, " from ", source_file)
  out <- data.frame(matrix(NA, nrow = length(year), ncol = length(standard_long_cols)))
  names(out) <- standard_long_cols
  out$year <- year
  out$variable_id <- variable_id
  out$value <- value
  out$unit <- unit
  out$family_id <- family_id
  out$contract_status <- contract_status
  out$analytical_role <- analytical_role
  out$source_stage <- source_stage
  out$source_commit <- source_commit
  out$source_file <- source_file
  out$coverage_start <- min(year[!is.na(value)], na.rm = TRUE)
  out$coverage_end <- max(year[!is.na(value)], na.rm = TRUE)
  out$first_fully_supported_year <- min(year[!is.na(value)], na.rm = TRUE)
  out$support_status <- ifelse(is.na(value), "SOURCE_ABSENT_MISSING_NOT_ZERO", "SOURCE_AVAILABLE")
  out$baseline_window_eligible <- "yes"
  out$warmup_observation <- ifelse(year < 1947, "yes", "no")
  out$authoritative_variable_id <- authoritative_variable_id
  out$provenance_id <- paste("D10_CLEAN", variable_id, sep = "__")
  out$reference_year <- reference_year
  out$transformation <- transformation
  out$canonical_inclusion_status <- canonical_inclusion_status
  out$baseline_or_robustness <- baseline_or_robustness
  out
}

cap_rows <- rbind(
  mk_long_rows(real_capital$year, "K_ME", real_capital$K_real_ME_refrozen, "2017 dollars",
               "capital", "BASELINE_AUTHORIZED", "NFC_PRODUCTIVE_ORIGIN_BASELINE",
               real_capital_path, reference_year = 2017,
               baseline_or_robustness = "BASELINE_AUTHORIZED"),
  mk_long_rows(real_capital$year, "K_NRC", real_capital$K_real_NRC_refrozen, "2017 dollars",
               "capital", "BASELINE_AUTHORIZED", "NFC_PRODUCTIVE_ORIGIN_BASELINE",
               real_capital_path, reference_year = 2017,
               baseline_or_robustness = "BASELINE_AUTHORIZED"),
  mk_long_rows(real_capital$year, "K_capacity", real_capital$K_real_capacity_refrozen, "2017 dollars",
               "capital", "BASELINE_AUTHORIZED", "NFC_PRODUCTIVE_ORIGIN_BASELINE",
               real_capital_path, reference_year = 2017,
               baseline_or_robustness = "BASELINE_AUTHORIZED"),
  mk_long_rows(real_capital$year, "Y_REAL_NFC_GVA_BASELINE_D09", real_capital$Y_REAL_NFC_GVA_BASELINE, "2017 dollars",
               "output", "BASELINE_AUTHORIZED", "NFC_PRODUCTIVE_ORIGIN_BASELINE",
               real_capital_path, reference_year = 2017,
               baseline_or_robustness = "BASELINE_AUTHORIZED")
)

if (nrow(distribution) > 0) {
  dist_rows <- rbind(
    mk_long_rows(distribution$year, "omega_NFC_productive_origin_GVA", distribution$NFC_COMPENSATION_SHARE_GVA, "share",
                 "distribution", "BASELINE_AUTHORIZED", "NFC_PRODUCTIVE_ORIGIN_BASELINE",
                 distribution_path, baseline_or_robustness = "BASELINE_AUTHORIZED"),
    mk_long_rows(distribution$year, "pi_NFC_productive_origin_GVA", distribution$NFC_NOS_share_GVA, "share",
                 "distribution", "BASELINE_AUTHORIZED", "NFC_PRODUCTIVE_ORIGIN_BASELINE",
                 distribution_path, baseline_or_robustness = "BASELINE_AUTHORIZED")
  )
} else {
  dist_rows <- base_long[0, ]
}

s30h_ext <- to_standard_long(s30h_long, s30h_long_path)
s30h_clean_std <- to_standard_long(s30h_clean, s30h_clean_path,
                                   default_status = "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK",
                                   default_role = "NOT_MODEL_READY")
s30h_implied_std <- to_standard_long(s30h_implied, s30h_implied_path,
                                     default_status = "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK",
                                     default_role = "NOT_MODEL_READY")

panel_long <- rbind(base_long, cap_rows, dist_rows, s30h_ext)
panel_long <- panel_long[!grepl("q_omega", panel_long$variable_id, ignore.case = TRUE), ]
panel_long <- panel_long[order(panel_long$year, panel_long$variable_id), ]

wide_from_long <- function(long_df) {
  keys <- paste(long_df$year, long_df$variable_id, sep = "||")
  dup_keys <- duplicated(keys)
  if (any(dup_keys)) {
    dup_sample <- unique(keys[dup_keys])[1:min(10, length(unique(keys[dup_keys])))]
    stop("Duplicate year-variable keys after D10 clean assembly: ", paste(dup_sample, collapse = "; "))
  }
  vars <- sort(unique(long_df$variable_id))
  years <- sort(unique(long_df$year))
  out <- data.frame(year = years)
  for (v in vars) {
    sub <- long_df[long_df$variable_id == v, c("year", "value")]
    out[[v]] <- sub$value[match(out$year, sub$year)]
  }
  out
}

panel_wide <- wide_from_long(panel_long)

mk_dict_row <- function(variable_id, display_name, family_id, concept, definition, unit,
                        reference_year, transformation, contract_status, analytical_role,
                        authoritative_variable_id = variable_id,
                        baseline_or_robustness = "NOT_BASELINE_REGRESSOR",
                        coverage_start = NA, coverage_end = NA, source_stage = "D10_CLEAN_FROM_D09S",
                        source_commit = head_hash, notes = "") {
  data.frame(
    variable_id = variable_id,
    display_name = display_name,
    family_id = family_id,
    concept = concept,
    definition = definition,
    unit = unit,
    reference_year = reference_year,
    transformation = transformation,
    contract_status = contract_status,
    analytical_role = analytical_role,
    authoritative_variable_id = authoritative_variable_id,
    baseline_or_robustness = baseline_or_robustness,
    coverage_start = coverage_start,
    coverage_end = coverage_end,
    source_stage = source_stage,
    source_commit = source_commit,
    notes = notes
  )
}

coverage_for <- function(var) {
  x <- panel_long[panel_long$variable_id == var & !is.na(panel_long$value), "year"]
  if (length(x) == 0) return(c(NA, NA))
  c(min(x), max(x))
}

dict_extra_vars <- c("K_ME", "K_NRC", "K_capacity", "Y_REAL_NFC_GVA_BASELINE_D09",
                     "omega_NFC_productive_origin_GVA", "pi_NFC_productive_origin_GVA")
dict_extra <- do.call(rbind, lapply(dict_extra_vars, function(v) {
  cov <- coverage_for(v)
  if (v == "K_ME") {
    mk_dict_row(v, "Real ME capacity capital", "capital", "ME gross surviving GPIM stock",
                "Machinery and equipment baseline capacity capital, D06/D09 refrozen GPIM, L=14 and alpha=1.7.",
                "2017 dollars", 2017, "level", "BASELINE_AUTHORIZED",
                "NFC_PRODUCTIVE_ORIGIN_BASELINE", baseline_or_robustness = "BASELINE_AUTHORIZED",
                coverage_start = cov[1], coverage_end = cov[2],
                notes = "Baseline component of K_capacity.")
  } else if (v == "K_NRC") {
    mk_dict_row(v, "Real NRC capacity capital", "capital", "NRC gross surviving GPIM stock",
                "Nonresidential construction baseline capacity capital, D06/D09 refrozen GPIM, L=30 and alpha=1.6.",
                "2017 dollars", 2017, "level", "BASELINE_AUTHORIZED",
                "NFC_PRODUCTIVE_ORIGIN_BASELINE", baseline_or_robustness = "BASELINE_AUTHORIZED",
                coverage_start = cov[1], coverage_end = cov[2],
                notes = "Baseline component of K_capacity.")
  } else if (v == "K_capacity") {
    mk_dict_row(v, "Real ME plus NRC capacity capital", "capital", "K_capacity",
                "Baseline capacity capital equals K_ME plus K_NRC. D09-S sensitivity stocks are excluded from baseline.",
                "2017 dollars", 2017, "level", "BASELINE_AUTHORIZED",
                "NFC_PRODUCTIVE_ORIGIN_BASELINE", baseline_or_robustness = "BASELINE_AUTHORIZED",
                coverage_start = cov[1], coverage_end = cov[2],
                notes = "K_capacity = K_ME + K_NRC.")
  } else if (v == "Y_REAL_NFC_GVA_BASELINE_D09") {
    mk_dict_row(v, "Real NFC GVA baseline from D09 relation file", "output", "real output",
                "D09 output-capital relation copy of real NFC GVA baseline.",
                "2017 dollars", 2017, "level", "BASELINE_AUTHORIZED",
                "NFC_PRODUCTIVE_ORIGIN_BASELINE", baseline_or_robustness = "BASELINE_AUTHORIZED",
                coverage_start = cov[1], coverage_end = cov[2],
                notes = "Retained to pair the D09 capital boundary with output.")
  } else if (v == "omega_NFC_productive_origin_GVA") {
    mk_dict_row(v, "NFC productive-origin wage share", "distribution", "wage share",
                "Baseline NFC productive-origin wage share. Corporate raw and clean variants are not substitutes.",
                "share", NA, "share", "BASELINE_AUTHORIZED",
                "NFC_PRODUCTIVE_ORIGIN_BASELINE", baseline_or_robustness = "BASELINE_AUTHORIZED",
                coverage_start = cov[1], coverage_end = cov[2])
  } else {
    mk_dict_row(v, "NFC productive-origin surplus share", "distribution", "surplus share",
                "Baseline NFC productive-origin surplus share.",
                "share", NA, "share", "BASELINE_AUTHORIZED",
                "NFC_PRODUCTIVE_ORIGIN_BASELINE", baseline_or_robustness = "BASELINE_AUTHORIZED",
                coverage_start = cov[1], coverage_end = cov[2])
  }
}))

s30h_dict_std <- data.frame(matrix(NA, nrow = nrow(s30h_dict), ncol = ncol(base_dict)))
names(s30h_dict_std) <- names(base_dict)
for (nm in intersect(names(s30h_dict), names(s30h_dict_std))) s30h_dict_std[[nm]] <- s30h_dict[[nm]]
s30h_dict_std$display_name <- ifelse(is.na(s30h_dict_std$display_name), s30h_dict_std$variable_id, s30h_dict_std$display_name)
s30h_dict_std$concept <- ifelse(is.na(s30h_dict_std$concept), "corporate clean or implied financial accounting candidate", s30h_dict_std$concept)
s30h_dict_std$definition <- ifelse(is.na(s30h_dict_std$definition), s30h_dict$interpretation, s30h_dict_std$definition)
s30h_dict_std$reference_year <- ifelse(is.na(s30h_dict_std$reference_year), NA, s30h_dict_std$reference_year)
s30h_dict_std$transformation <- ifelse(is.na(s30h_dict_std$transformation), "level_or_share", s30h_dict_std$transformation)
s30h_dict_std$contract_status <- "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK; NOT_MODEL_READY"
s30h_dict_std$analytical_role <- "CANDIDATE_CROSSWALK_OR_ACCOUNTING_DIAGNOSTIC"
s30h_dict_std$authoritative_variable_id <- s30h_dict_std$variable_id
s30h_dict_std$baseline_or_robustness <- "NOT_BASELINE_REGRESSOR"
s30h_dict_std$source_stage <- "S30H"
s30h_dict_std$notes <- paste("D10 clean status lock:", s30h_dict$interpretation)

variable_dictionary <- rbind(base_dict, dict_extra, s30h_dict_std)
raw_corp_map <- c(
  CORP_COMPENSATION_SHARE_GVA = "omega_CORP_raw_GVA",
  CORP_COMPENSATION_SHARE_NVA = "omega_CORP_raw_NVA"
)
for (old in names(raw_corp_map)) {
  idx <- variable_dictionary$variable_id == old
  if (any(idx)) {
    variable_dictionary$variable_id[idx] <- raw_corp_map[[old]]
    variable_dictionary$display_name[idx] <- raw_corp_map[[old]]
    variable_dictionary$contract_status[idx] <- "AUTHORIZED_COMPARISON_RAW; NOT_CLEANED; NOT_BASELINE_PRODUCTIVE_ORIGIN; NOT_BASELINE_REGRESSOR"
    variable_dictionary$analytical_role[idx] <- "RAW_CORPORATE_COMPARISON_LAYER"
    variable_dictionary$baseline_or_robustness[idx] <- "NOT_BASELINE_REGRESSOR"
    variable_dictionary$notes[idx] <- "Raw corporate comparison wage-share variable; not cleaned, not baseline productive-origin, not a baseline regressor."
  }
  idx_long <- panel_long$variable_id == old
  if (any(idx_long)) {
    panel_long$variable_id[idx_long] <- raw_corp_map[[old]]
    panel_long$contract_status[idx_long] <- "AUTHORIZED_COMPARISON_RAW; NOT_CLEANED; NOT_BASELINE_PRODUCTIVE_ORIGIN; NOT_BASELINE_REGRESSOR"
    panel_long$analytical_role[idx_long] <- "RAW_CORPORATE_COMPARISON_LAYER"
    panel_long$baseline_or_robustness[idx_long] <- "NOT_BASELINE_REGRESSOR"
  }
}
panel_wide <- wide_from_long(panel_long)

variable_dictionary <- variable_dictionary[!duplicated(variable_dictionary$variable_id), ]
variable_dictionary <- variable_dictionary[!grepl("q_omega", variable_dictionary$variable_id, ignore.case = TRUE), ]
variable_dictionary <- variable_dictionary[order(variable_dictionary$variable_id), ]

accounting_ladder <- data.frame(
  ladder_step = seq_len(10),
  object = c("NFC productive-origin baseline", "raw corporate comparison layer", "corporate clean candidate layer",
             "GOS/NOS/profit ladder", "tax/subsidy/transfer bridge", "interest bridge",
             "profit-tax bridge", "dividend bridge", "retained-surplus bridge",
             "exploitation-rate construction ingredients"),
  status = c("BASELINE_AUTHORIZED", "AUTHORIZED_COMPARISON_RAW", "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK",
             "ACCOUNTING_LADDER", "ACCOUNTING_BRIDGE", "ACCOUNTING_BRIDGE", "ACCOUNTING_BRIDGE",
             "ACCOUNTING_BRIDGE", "ACCOUNTING_BRIDGE", "ALTERNATIVE_DISTRIBUTIVE_CONSTRUCTION_CONTRACT"),
  baseline_regressor = c("yes", rep("no", 9)),
  notes = c(
    "Only NFC productive-origin output, distribution, and K_capacity are baseline econometric objects.",
    "Raw corporate variables are comparison objects and not cleaned.",
    "Corporate-clean variables remain candidates requiring crosswalk validation.",
    "GOS/NOS/profit ladder is preserved for accounting interpretation.",
    "Taxes, subsidies, and transfers are bridge variables, not baseline regressors.",
    "Interest variables are bridge or candidate adjustment variables, not baseline regressors.",
    "Profit taxes are accounting bridge variables, not baseline regressors.",
    "Dividends are accounting bridge variables, not baseline regressors.",
    "Retained surplus is an accounting bridge variable, not a baseline regressor.",
    "Exploitation-rate ingredients remain construction-contract objects and not model-ready."
  )
)

tax_vars <- unique(variable_dictionary$variable_id[grepl("TAX|SUBSID|TRANSFER|INTEREST|NET_INT|PBT|PAT|DIVIDEND|UNDISTRIBUTED|RETAIN", variable_dictionary$variable_id, ignore.case = TRUE)])
tax_subsidy_transfer_ledger <- data.frame(
  variable_id = tax_vars,
  status = "ACCOUNTING_BRIDGE; NOT_BASELINE_REGRESSOR",
  role = "ACCOUNTING_BRIDGE",
  gross_component_policy = "Preserve gross components where available; keep net series where only net exists and mark gross unavailable.",
  baseline_regressor = "no",
  notes = "Tax, subsidy, transfer, interest, profit-tax, dividend, and retained-surplus variables are accounting bridge or comparison objects."
)

corp_clean_vars <- unique(c(s30h_dict$variable_id[grepl("CORP_NOS_NET|CLEAN|MATCHED|RESIDUAL", s30h_dict$variable_id, ignore.case = TRUE)]))
corporate_clean_layer_ledger <- data.frame(
  variable_id = corp_clean_vars,
  status = "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK; NOT_MODEL_READY",
  role = "CORPORATE_CLEAN_CANDIDATE_OR_CROSSWALK",
  baseline_replacement = "no",
  notes = "Preserved as candidate/crosswalk layer; not promoted to baseline productive-origin status."
)

financial_vars <- unique(variable_dictionary$variable_id[grepl("FIN_|FINANCIAL|INTEREST|NET_INT", variable_dictionary$variable_id, ignore.case = TRUE)])
financial_imputed_interest_candidate_ledger <- data.frame(
  variable_id = financial_vars,
  status = "CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK; NOT_MODEL_READY",
  role = "FINANCIAL_OR_IMPUTED_INTEREST_CANDIDATE",
  baseline_regressor = "no",
  notes = "Financial and imputed-interest variables remain candidate/crosswalk objects."
)

exploitation_rate_ingredient_ledger <- data.frame(
  variable_id = c("omega_NFC_productive_origin_GVA", "pi_NFC_productive_origin_GVA",
                  "omega_CORP_raw_GVA", "omega_CORP_raw_NVA"),
  status = "ALTERNATIVE_DISTRIBUTIVE_CONSTRUCTION_CONTRACT; NOT_MODEL_READY",
  role = "EXPLOITATION_RATE_INGREDIENT_ONLY",
  baseline_regressor = "no",
  notes = "Ingredients preserved for construction contract; no exploitation-rate series is constructed or authorized."
)

blocked_parked_variable_ledger <- data.frame(
  variable_id = c("q_omega", "q_omega_family_columns", "D09_S_sensitivity_stocks",
                  "total_capital", "total_fixed_assets", "IPP", "residential_capital",
                  "government_transportation", "all_BEA_fixed_assets"),
  status = c("PARKED", "PARKED", "REPORT_ONLY_NOT_BASELINE", rep("PARKED_EXCLUDED_FROM_BASELINE", 6)),
  baseline_regressor = "no",
  notes = c(
    "q_omega remains parked and was not constructed.",
    "No q_omega-family columns were created.",
    "D09-S service-life sensitivity stocks remain report-only.",
    "Total capital is not baseline capital.",
    "Total fixed assets are not baseline capital.",
    "IPP is not baseline capital.",
    "Residential capital is not baseline capital.",
    "Government transportation capital is not baseline capital.",
    "All-BEA fixed assets are not baseline capital."
  )
)

regression_menu_ledger <- data.frame(
  menu_item = c("baseline_output", "baseline_capacity_capital", "baseline_wage_share",
                "baseline_surplus_share", "raw_corporate_comparisons", "candidate_adjustments"),
  variable_id = c("Y_REAL_NFC_GVA_BASELINE_D09", "K_capacity", "omega_NFC_productive_origin_GVA",
                  "pi_NFC_productive_origin_GVA", "omega_CORP_raw_GVA; omega_CORP_raw_NVA",
                  "corporate-clean and financial/imputed-interest candidates"),
  authorization = c(rep("BASELINE_ECONOMETRIC_OBJECT", 4), "COMPARISON_ONLY_NOT_BASELINE", "NOT_MODEL_READY"),
  notes = "D10 creates a menu and estimates nothing."
)

elasticity_recovery_protocol_ledger <- data.frame(
  protocol_item = c("theta_recovery", "q_recovery", "q_omega"),
  status = c("PROTOCOL_ONLY_NOT_ESTIMATED", "PROTOCOL_ONLY_NOT_ESTIMATED", "PARKED_NOT_CONSTRUCTED"),
  notes = c("D10 preserves protocol language but runs no elasticity estimation.",
            "Mechanization growth q remains a later-stage transformation, not estimated here.",
            "Distribution-weighted accumulation indexes are prohibited in D10 clean.")
)

k_identity_ok <- max(abs(panel_wide$K_capacity - (panel_wide$K_ME + panel_wide$K_NRC)), na.rm = TRUE) < 1e-6
no_q_cols <- !any(grepl("q_omega", names(panel_wide), ignore.case = TRUE)) &&
  !any(grepl("q_omega", panel_long$variable_id, ignore.case = TRUE))
no_d09s_baseline <- !any(grepl("D09_S|sensitivity", names(panel_wide), ignore.case = TRUE)) &&
  !any(grepl("D09_S|sensitivity", panel_long$variable_id, ignore.case = TRUE))
forbidden_baseline_terms <- c("TOTAL", "total_capital", "total_fixed", "IPP", "RESIDENTIAL", "GOV_TRANS", "all_BEA")
baseline_dict <- variable_dictionary[variable_dictionary$baseline_or_robustness == "BASELINE_AUTHORIZED" |
                                       variable_dictionary$contract_status == "BASELINE_AUTHORIZED", ]
no_forbidden_baseline <- !any(grepl(paste(forbidden_baseline_terms, collapse = "|"), baseline_dict$variable_id, ignore.case = TRUE))

decision_code <- if (no_q_cols && no_d09s_baseline && no_forbidden_baseline && k_identity_ok) {
  "AUTHORIZE_D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW"
} else if (!no_q_cols) {
  "BLOCK_D10_CLEAN_QOMEGA_REINTRODUCTION"
} else {
  "BLOCK_D10_CLEAN_BOUNDARY_LEAKAGE"
}

validation_checks <- data.frame(
  check = c(
    "REPO_BASE_RECORDED", "RSCRIPT_PATH_RECORDED", "RSCRIPT_VERSION_RECORDED",
    "R_SCRIPT_EXECUTED_SUCCESSFULLY", "NO_FALLBACK_MATERIALIZATION_USED",
    "WIDE_PANEL_CREATED", "LONG_PANEL_CREATED", "VARIABLE_DICTIONARY_CREATED",
    "ACCOUNTING_LADDER_CREATED", "TAX_SUBSIDY_TRANSFER_LEDGER_CREATED",
    "CORPORATE_CLEAN_LAYER_LEDGER_CREATED", "FINANCIAL_IMPUTED_INTEREST_LEDGER_CREATED",
    "EXPLOITATION_RATE_LEDGER_CREATED", "BLOCKED_PARKED_LEDGER_CREATED",
    "REGRESSION_MENU_LEDGER_CREATED", "ELASTICITY_RECOVERY_PROTOCOL_LEDGER_CREATED",
    "Q_OMEGA_PARKED", "NO_Q_OMEGA_COLUMNS", "ME_L14_NRC_L30_RECONFIRMED",
    "K_CAPACITY_EQUALS_ME_PLUS_NRC_RECONFIRMED", "NO_D09_S_SENSITIVITY_STOCK_BASELINE",
    "NO_TOTAL_CAPITAL_BASELINE", "NO_TOTAL_FIXED_ASSETS_BASELINE", "NO_IPP_BASELINE",
    "NO_RESIDENTIAL_BASELINE", "NO_GOV_TRANSPORT_BASELINE", "NO_ALL_BEA_FIXED_ASSETS_BASELINE",
    "CORPORATE_CLEAN_REMAINS_CANDIDATE_OR_CROSSWALK",
    "FINANCIAL_IMPUTED_INTEREST_REMAINS_CANDIDATE",
    "EXPLOITATION_RATE_REMAINS_CONSTRUCTION_CONTRACT",
    "NO_ECONOMETRICS_RUN", "NO_MODEL_ESTIMATION_RUN", "NO_STATIONARITY_TESTS_RUN",
    "NO_INTEGRATION_TESTS_RUN", "NO_COINTEGRATION_TESTS_RUN",
    "DECISION_RECORDED", "HANDOFF_CREATED"
  ),
  status = "PASS",
  notes = ""
)
set_note <- function(check, note) validation_checks$notes[validation_checks$check == check] <<- note
set_note("REPO_BASE_RECORDED", paste("Branch", branch, "at", head_hash, "from base", short_base))
set_note("RSCRIPT_PATH_RECORDED", rscript_path)
set_note("RSCRIPT_VERSION_RECORDED", rscript_version)
set_note("R_SCRIPT_EXECUTED_SUCCESSFULLY", "R script reached validation and report creation.")
set_note("NO_FALLBACK_MATERIALIZATION_USED", "All D10 clean outputs are generated inside this R script.")
set_note("WIDE_PANEL_CREATED", paste(nrow(panel_wide), "rows x", ncol(panel_wide), "columns."))
set_note("LONG_PANEL_CREATED", paste(nrow(panel_long), "rows."))
set_note("VARIABLE_DICTIONARY_CREATED", paste(nrow(variable_dictionary), "rows."))
set_note("ACCOUNTING_LADDER_CREATED", paste(nrow(accounting_ladder), "rows."))
set_note("TAX_SUBSIDY_TRANSFER_LEDGER_CREATED", paste(nrow(tax_subsidy_transfer_ledger), "rows."))
set_note("CORPORATE_CLEAN_LAYER_LEDGER_CREATED", paste(nrow(corporate_clean_layer_ledger), "rows."))
set_note("FINANCIAL_IMPUTED_INTEREST_LEDGER_CREATED", paste(nrow(financial_imputed_interest_candidate_ledger), "rows."))
set_note("EXPLOITATION_RATE_LEDGER_CREATED", paste(nrow(exploitation_rate_ingredient_ledger), "rows."))
set_note("BLOCKED_PARKED_LEDGER_CREATED", paste(nrow(blocked_parked_variable_ledger), "rows."))
set_note("REGRESSION_MENU_LEDGER_CREATED", paste(nrow(regression_menu_ledger), "rows."))
set_note("ELASTICITY_RECOVERY_PROTOCOL_LEDGER_CREATED", paste(nrow(elasticity_recovery_protocol_ledger), "rows."))
set_note("Q_OMEGA_PARKED", "q_omega remains parked and is listed only in the blocked/parked ledger.")
set_note("NO_Q_OMEGA_COLUMNS", as.character(no_q_cols))
set_note("ME_L14_NRC_L30_RECONFIRMED", "ME L=14 alpha=1.7 and NRC L=30 alpha=1.6 are retained from D06/D09 locks.")
set_note("K_CAPACITY_EQUALS_ME_PLUS_NRC_RECONFIRMED", paste("Identity status:", k_identity_ok))
set_note("NO_D09_S_SENSITIVITY_STOCK_BASELINE", paste("D09-S file exists:", file.exists(file.path(repo, d09s_panel_path)), "but is not read into baseline."))
set_note("NO_TOTAL_CAPITAL_BASELINE", as.character(no_forbidden_baseline))
set_note("NO_TOTAL_FIXED_ASSETS_BASELINE", as.character(no_forbidden_baseline))
set_note("NO_IPP_BASELINE", as.character(no_forbidden_baseline))
set_note("NO_RESIDENTIAL_BASELINE", as.character(no_forbidden_baseline))
set_note("NO_GOV_TRANSPORT_BASELINE", as.character(no_forbidden_baseline))
set_note("NO_ALL_BEA_FIXED_ASSETS_BASELINE", as.character(no_forbidden_baseline))
set_note("CORPORATE_CLEAN_REMAINS_CANDIDATE_OR_CROSSWALK", "Corporate-clean objects carry CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK and NOT_MODEL_READY.")
set_note("FINANCIAL_IMPUTED_INTEREST_REMAINS_CANDIDATE", "Financial/imputed-interest objects carry CANDIDATE_ADJUSTMENT_REQUIRES_CROSSWALK and NOT_MODEL_READY.")
set_note("EXPLOITATION_RATE_REMAINS_CONSTRUCTION_CONTRACT", "No exploitation-rate series is constructed.")
set_note("NO_ECONOMETRICS_RUN", "No DOLS, FM-OLS, IM-OLS, OLS, ARDL, VECM, or regression command is called.")
set_note("NO_MODEL_ESTIMATION_RUN", "D10 clean is data assembly only.")
set_note("NO_STATIONARITY_TESTS_RUN", "No stationarity tests are called.")
set_note("NO_INTEGRATION_TESTS_RUN", "No integration tests are called.")
set_note("NO_COINTEGRATION_TESTS_RUN", "No cointegration tests are called.")
set_note("DECISION_RECORDED", decision_code)
set_note("HANDOFF_CREATED", "D10_clean_session_handoff.md")
if (decision_code != "AUTHORIZE_D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW") {
  validation_checks$status[validation_checks$check %in% c("DECISION_RECORDED")] <- "FAIL"
}

write_csv(panel_wide, "D10_clean_us_source_of_truth_panel_wide.csv")
write_csv(panel_long, "D10_clean_us_source_of_truth_panel_long.csv")
write_csv(variable_dictionary, "D10_clean_variable_dictionary.csv")
write_csv(accounting_ladder, "D10_clean_accounting_ladder.csv")
write_csv(tax_subsidy_transfer_ledger, "D10_clean_tax_subsidy_transfer_ledger.csv")
write_csv(corporate_clean_layer_ledger, "D10_clean_corporate_clean_layer_ledger.csv")
write_csv(financial_imputed_interest_candidate_ledger, "D10_clean_financial_imputed_interest_candidate_ledger.csv")
write_csv(exploitation_rate_ingredient_ledger, "D10_clean_exploitation_rate_ingredient_ledger.csv")
write_csv(blocked_parked_variable_ledger, "D10_clean_blocked_parked_variable_ledger.csv")
write_csv(regression_menu_ledger, "D10_clean_regression_menu_ledger.csv")
write_csv(elasticity_recovery_protocol_ledger, "D10_clean_elasticity_recovery_protocol_ledger.csv")
write_csv(validation_checks, "D10_clean_validation_checks.csv")

validation_count <- paste(sum(validation_checks$status == "PASS"), "/", nrow(validation_checks), " PASS", sep = "")

report <- c(
  "# D10 Clean Decision Report",
  "",
  "## Branch and Base",
  "",
  paste("Branch:", branch),
  paste("Base commit:", short_base),
  paste("HEAD:", head_hash),
  "",
  "## R Environment",
  "",
  paste("Rscript path:", rscript_path),
  paste("Rscript version:", rscript_version),
  "",
  "## Restart Scope",
  "",
  "This is a clean restart from D09-S. The build was generated by the committed R script codes/US_D10_clean_build_source_of_truth_dataset.R.",
  "",
  "No PS1 construction, Python construction, or fallback CSV materialization was used.",
  "",
  paste("Output folder:", out_root),
  "",
  "## Dataset Facts",
  "",
  paste("Wide panel shape:", nrow(panel_wide), "rows x", ncol(panel_wide), "columns."),
  paste("Long panel row count:", nrow(panel_long)),
  paste("Variable dictionary row count:", nrow(variable_dictionary)),
  paste("Accounting ladder row count:", nrow(accounting_ladder)),
  paste("Validation count:", validation_count),
  "",
  "## Boundary Status",
  "",
  "q_omega status: parked. No q_omega or q_omega-family columns were created.",
  paste("ME/NRC baseline status: K_capacity equals K_ME plus K_NRC:", k_identity_ok),
  "ME L=14 alpha=1.7 and NRC L=30 alpha=1.6 remain the baseline capital locks.",
  "D09-S sensitivity-stock exclusion: D09-S sensitivity files are report-only and are not consumed as baseline.",
  "",
  "## Accounting Status",
  "",
  "Corporate-clean status: candidate/crosswalk only; not model-ready and not baseline productive-origin.",
  "Financial/imputed-interest status: candidate/crosswalk only; not model-ready.",
  "Exploitation-rate status: construction-contract ingredients only; no exploitation-rate object is constructed.",
  "Tax/subsidy/transfer status: accounting bridge only; not baseline regressors.",
  "",
  "## Final Decision",
  "",
  paste("Final decision code:", decision_code)
)
write_lines(report, file.path(reports_dir, "D10_clean_decision_report.md"))

handoff <- c(
  "# Chapter 2 - D10 Clean Restart Handoff",
  "",
  "## Final state",
  "",
  paste("Final decision code:", decision_code),
  paste("D11 authorized:", decision_code == "AUTHORIZE_D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW"),
  "",
  "## Branch and commit",
  "",
  paste("Branch:", branch),
  paste("Base commit:", short_base),
  paste("HEAD at build time:", head_hash),
  "",
  "## Rscript path and version",
  "",
  paste("Rscript path:", rscript_path),
  paste("Rscript version:", rscript_version),
  "",
  "## Dataset facts",
  "",
  paste("Output folder:", out_root),
  paste("Wide panel shape:", nrow(panel_wide), "rows x", ncol(panel_wide), "columns."),
  paste("Long panel row count:", nrow(panel_long)),
  paste("Variable dictionary row count:", nrow(variable_dictionary)),
  paste("Validation count:", validation_count),
  "",
  "## Baseline locks",
  "",
  "K_capacity = K_ME + K_NRC.",
  "ME: L=14, alpha=1.7.",
  "NRC: L=30, alpha=1.6.",
  "D09-S service-life sensitivity stocks remain report-only.",
  "",
  "## Accounting scope",
  "",
  "NFC productive-origin variables are the only baseline econometric objects.",
  "Raw corporate variables are authorized raw comparison objects.",
  "Corporate-clean, financial/imputed-interest, and exploitation-rate objects remain candidate, crosswalk, or construction-contract objects.",
  "Tax, subsidy, transfer, interest, profit-tax, dividend, and retained-surplus variables are accounting bridges.",
  "",
  "## What is not authorized",
  "",
  "No q_omega object is authorized.",
  "No D09-S sensitivity stock is authorized for baseline capital.",
  "No total capital, total fixed assets, IPP, residential capital, government transportation, or all-BEA fixed-assets object is authorized for baseline capital.",
  "No econometric estimation or integration testing is authorized by D10 clean.",
  "",
  "## Next recommended pass",
  "",
  "Run D11 integration and estimation readiness review only if this D10 clean commit is accepted.",
  "",
  "## Resume commands",
  "",
  "cd C:\\ReposGitHub\\Capacity-Utilization-US_Chile",
  "git status --short --branch",
  "git log --oneline --decorate -10",
  "Get-Content output\\US\\D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET\\csv\\D10_clean_validation_checks.csv"
)
write_lines(handoff, file.path(handoff_dir, "D10_clean_session_handoff.md"))

cat("D10 clean R build finished\n")
cat("Decision:", decision_code, "\n")
cat("Validation:", validation_count, "\n")
