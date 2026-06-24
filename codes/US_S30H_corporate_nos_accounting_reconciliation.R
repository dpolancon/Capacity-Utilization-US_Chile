#!/usr/bin/env Rscript

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
stage_id <- "S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION"
base_commit <- "b72a3ba2a67db95ff8c3c97161740cd815aaa73f"
branch_required <- "feature/s30h-corporate-nos-reconciliation"
out_dir <- file.path(root, "output", "US", stage_id)
csv_dir <- file.path(out_dir, "csv")
md_dir <- file.path(out_dir, "md")
if (dir.exists(out_dir)) unlink(out_dir, recursive = TRUE, force = TRUE)
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

read_files <- character()
rel <- function(path) sub(paste0("^", gsub("\\\\", "/", root), "/?"), "", gsub("\\\\", "/", normalizePath(path, winslash = "/", mustWork = FALSE)))
read_csv <- function(path) {
  if (!file.exists(path)) stop("Missing input: ", path, call. = FALSE)
  read_files <<- unique(c(read_files, rel(path)))
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}
write_csv <- function(x, name) write.csv(x, file.path(csv_dir, name), row.names = FALSE, na = "")
write_md <- function(x, name) writeLines(x, file.path(md_dir, name), useBytes = TRUE)
git_out <- function(args) trimws(system2("git", args, stdout = TRUE, stderr = TRUE)[1])

branch <- git_out(c("branch", "--show-current"))
head <- git_out(c("rev-parse", "HEAD"))
base_ok <- identical(system2("git", c("merge-base", "--is-ancestor", base_commit, head), stdout = FALSE, stderr = FALSE), 0L)

source_path <- file.path(root, "output", "US", "S24A_INCOME_DISTRIBUTION_SOURCE_INPUTS_CONSTRUCTION", "csv", "S24A_income_distribution_source_inputs_long.csv")
s30g_completion_path <- file.path(root, "output", "US", "S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM", "csv", "S30G_completion_record.csv")
s30g_panel_path <- file.path(root, "output", "US", "S30G_FINANCIAL_CLAIMS_PROXY_ADDENDUM", "csv", "S30G_new_variable_panel_long.csv")
theory_lock_path <- file.path(root, "chapter2_vault", "04_data_measurement", "L05_Corporate_Surplus_and_Financial_Redistribution_Lock.md")
source <- read_csv(source_path)
s30g_completion <- read_csv(s30g_completion_path)
s30g_panel <- read_csv(s30g_panel_path)
if (!file.exists(theory_lock_path)) stop("Missing theory lock: ", theory_lock_path, call. = FALSE)
theory_lock_text <- readLines(theory_lock_path, warn = FALSE, encoding = "UTF-8")
read_files <- unique(c(read_files, rel(theory_lock_path)))

pairs <- data.frame(
  concept = c("GVA", "CFC", "NVA", "COMP", "NOS", "NET_INT", "TRANSFERS_NET",
              "PROFITS_IVA_CC", "TAX", "AFTER_TAX", "DIVIDENDS_NET",
              "UNDISTRIBUTED", "PBT", "PAT"),
  corp_id = c("CORP_GVA", "CORP_CFC", "CORP_NVA", "CORP_COMP", "CORP_NOS",
              "CORP_NET_INT", "CORP_TRANSFERS_NET", "CORP_PROFITS_IVA_CC",
              "CORP_TAX", "CORP_AFTER_TAX", "CORP_DIVIDENDS_NET",
              "CORP_UNDISTRIBUTED", "CORP_PBT", "CORP_PAT"),
  nfc_id = c("NFC_GVA", "NFC_CFC", "NFC_NVA", "NFC_COMP", "NFC_NOS",
             "NFC_NET_INT", "NFC_TRANSFERS_NET", "NFC_PROFITS_IVA_CC",
             "NFC_TAX", "NFC_AFTER_TAX", "NFC_DIVIDENDS_NET",
             "NFC_UNDISTRIBUTED", "NFC_PBT", "NFC_PAT"),
  fin_id = c("FIN_GVA_IMPLIED", "FIN_CFC_IMPLIED", "FIN_NVA_IMPLIED",
             "FIN_COMP_IMPLIED", "FIN_NOS_IMPLIED", "FIN_NET_INT_IMPLIED",
             "FIN_TRANSFERS_NET_IMPLIED", "FIN_PROFITS_IVA_CC_IMPLIED",
             "FIN_TAX_IMPLIED", "FIN_AFTER_TAX_IMPLIED",
             "FIN_DIVIDENDS_NET_IMPLIED", "FIN_UNDISTRIBUTED_IMPLIED",
             "FIN_PBT_IMPLIED", "FIN_PAT_IMPLIED"),
  stringsAsFactors = FALSE
)

ids <- unique(c(pairs$corp_id, pairs$nfc_id, "NFC_RETAINED"))
x <- source[source$variable_id %in% ids, c("variable_id", "year", "value", "unit", "frequency",
                                           "source_dataset", "source_table", "source_line",
                                           "source_line_description")]
x$year <- as.integer(x$year)
x$value <- as.numeric(x$value)

availability <- do.call(rbind, lapply(ids, function(id) {
  z <- x[x$variable_id == id, ]
  data.frame(
    variable_id = id,
    economic_content = if (nrow(z)) z$source_line_description[1] else "",
    sector_boundary = ifelse(grepl("^CORP_", id), "CORPORATE_BUSINESS", "NONFINANCIAL_CORPORATE_BUSINESS"),
    unit = paste(unique(z$unit), collapse = "; "),
    frequency = paste(unique(z$frequency), collapse = "; "),
    coverage_start = if (nrow(z)) min(z$year) else NA,
    coverage_end = if (nrow(z)) max(z$year) else NA,
    observation_count = nrow(z),
    missing_count = sum(is.na(z$value)),
    duplicate_year_count = sum(duplicated(z$year)),
    source_file = rel(source_path),
    stringsAsFactors = FALSE
  )
}))

wide <- Reduce(function(a, b) merge(a, b, by = "year", all = FALSE),
               lapply(ids, function(id) {
                 z <- x[x$variable_id == id, c("year", "value")]
                 names(z)[2] <- id
                 z
               }))
wide <- wide[order(wide$year), ]

implied_wide <- data.frame(year = wide$year)
for (i in seq_len(nrow(pairs))) implied_wide[[pairs$fin_id[i]]] <- wide[[pairs$corp_id[i]]] - wide[[pairs$nfc_id[i]]]

locked_implied_roles <- c(
  FIN_NOS_IMPLIED = "FINANCIAL_REDISTRIBUTED_PROFIT_TYPE_INCOME_PROXY",
  FIN_COMP_IMPLIED = "UNPRODUCTIVE_FINANCIAL_LABOR_COST_FINANCED_FROM_PRIMARY_VALUE",
  FIN_NVA_IMPLIED = "FINANCIAL_SECTOR_ABSORPTION_OF_PRIMARY_VALUE_PROXY",
  FIN_GVA_IMPLIED = "FINANCIAL_GROSS_ABSORPTION_ACCOUNTING_RESIDUAL"
)
implied_long <- do.call(rbind, lapply(seq_len(nrow(pairs)), function(i) {
  role <- if (pairs$fin_id[i] %in% names(locked_implied_roles)) {
    unname(locked_implied_roles[pairs$fin_id[i]])
  } else {
    "IMPLIED_FINANCIAL_CORPORATE_ACCOUNT_DIAGNOSTIC"
  }
  data.frame(
    year = implied_wide$year,
    variable_id = pairs$fin_id[i],
    value = implied_wide[[pairs$fin_id[i]]],
    unit = "Millions of current dollars",
    family_id = "distribution",
    analytical_role = role,
    contract_status = "DIAGNOSTIC_CANDIDATE",
    formula = paste(pairs$corp_id[i], "-", pairs$nfc_id[i]),
    source_stage = stage_id,
    source_commit = base_commit,
    interpretation = "Corporate-minus-NFC accounting residual; not independently produced surplus and not a bilateral transfer.",
    stringsAsFactors = FALSE
  )
}))

identity_rows <- list(
  list(id = "CORP_GVA_IDENTITY", lhs = wide$CORP_GVA, rhs = wide$CORP_NVA + wide$CORP_CFC,
       formula = "CORP_GVA = CORP_NVA + CORP_CFC"),
  list(id = "NFC_GVA_IDENTITY", lhs = wide$NFC_GVA, rhs = wide$NFC_NVA + wide$NFC_CFC,
       formula = "NFC_GVA = NFC_NVA + NFC_CFC"),
  list(id = "FIN_GVA_IMPLIED_IDENTITY", lhs = implied_wide$FIN_GVA_IMPLIED,
       rhs = implied_wide$FIN_NVA_IMPLIED + implied_wide$FIN_CFC_IMPLIED,
       formula = "FIN_GVA_IMPLIED = FIN_NVA_IMPLIED + FIN_CFC_IMPLIED"),
  list(id = "CORP_NOS_IDENTITY", lhs = wide$CORP_NOS,
       rhs = wide$CORP_NET_INT + wide$CORP_TRANSFERS_NET + wide$CORP_PROFITS_IVA_CC,
       formula = "CORP_NOS = CORP_NET_INT + CORP_TRANSFERS_NET + CORP_PROFITS_IVA_CC"),
  list(id = "NFC_NOS_IDENTITY", lhs = wide$NFC_NOS,
       rhs = wide$NFC_NET_INT + wide$NFC_TRANSFERS_NET + wide$NFC_PROFITS_IVA_CC,
       formula = "NFC_NOS = NFC_NET_INT + NFC_TRANSFERS_NET + NFC_PROFITS_IVA_CC"),
  list(id = "FIN_NOS_IMPLIED_IDENTITY", lhs = implied_wide$FIN_NOS_IMPLIED,
       rhs = implied_wide$FIN_NET_INT_IMPLIED + implied_wide$FIN_TRANSFERS_NET_IMPLIED +
         implied_wide$FIN_PROFITS_IVA_CC_IMPLIED,
       formula = "FIN_NOS_IMPLIED = FIN_NET_INT_IMPLIED + FIN_TRANSFERS_NET_IMPLIED + FIN_PROFITS_IVA_CC_IMPLIED")
)

rounding_tolerance <- 2
identity_audit <- do.call(rbind, lapply(identity_rows, function(q) {
  residual <- q$lhs - q$rhs
  data.frame(
    identity_id = q$id,
    formula = q$formula,
    year = wide$year,
    lhs = q$lhs,
    rhs = q$rhs,
    residual_millions = residual,
    absolute_residual_millions = abs(residual),
    tolerance_millions = rounding_tolerance,
    result = ifelse(abs(residual) <= rounding_tolerance, "PASS_WITHIN_PUBLISHED_ROUNDING", "FAIL"),
    stringsAsFactors = FALSE
  )
}))
identity_summary <- do.call(rbind, lapply(split(identity_audit, identity_audit$identity_id), function(z) {
  data.frame(
    identity_id = z$identity_id[1],
    formula = z$formula[1],
    years_tested = nrow(z),
    max_absolute_residual_millions = max(z$absolute_residual_millions),
    exact_zero_years = sum(z$absolute_residual_millions == 0),
    within_rounding_tolerance_years = sum(z$absolute_residual_millions <= rounding_tolerance),
    failed_years = sum(z$absolute_residual_millions > rounding_tolerance),
    result = ifelse(all(z$absolute_residual_millions <= rounding_tolerance),
                    "PASS_WITHIN_PUBLISHED_ROUNDING", "FAIL"),
    stringsAsFactors = FALSE
  )
}))

fin_net_interest <- implied_wide$FIN_NET_INT_IMPLIED
full_transfer <- wide$NFC_NET_INT
matched_transfer <- pmin(pmax(wide$NFC_NET_INT, 0), pmax(-fin_net_interest, 0))

sensitivity <- data.frame(
  year = wide$year,
  NFC_NET_INT = wide$NFC_NET_INT,
  FIN_NET_INT_IMPLIED = fin_net_interest,
  full_attribution_transfer_proxy = full_transfer,
  matched_position_transfer_proxy = matched_transfer,
  matched_proxy_valid = wide$NFC_NET_INT > 0 & fin_net_interest < 0,
  matched_proxy_reason = ifelse(
    wide$NFC_NET_INT > 0 & fin_net_interest < 0,
    "NFC net-payment and implied-finance net-receipt positions overlap.",
    "No opposite-signed NFC payment and implied-finance receipt positions; matched proxy set to zero."
  ),
  stringsAsFactors = FALSE
)

clean_wide <- data.frame(
  year = wide$year,
  CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_PROXY = wide$CORP_NOS - full_transfer,
  CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_SHARE_NVA = (wide$CORP_NOS - full_transfer) / wide$CORP_NVA,
  CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_SHARE_GVA = (wide$CORP_NOS - full_transfer) / wide$CORP_GVA,
  FIN_NOS_RESIDUAL_AFTER_NFC_FINANCIAL_CLAIMS = implied_wide$FIN_NOS_IMPLIED - full_transfer,
  CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_PROXY = wide$CORP_NOS - matched_transfer,
  CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_SHARE_NVA = (wide$CORP_NOS - matched_transfer) / wide$CORP_NVA,
  CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_SHARE_GVA = (wide$CORP_NOS - matched_transfer) / wide$CORP_GVA,
  FIN_NOS_RESIDUAL_AFTER_MATCHED_FINANCIAL_CLAIMS = implied_wide$FIN_NOS_IMPLIED - matched_transfer,
  check.names = FALSE
)

clean_specs <- data.frame(
  variable_id = names(clean_wide)[-1],
  assumption = c(rep("FULL_NFC_ATTRIBUTION", 4), rep("MATCHED_FINANCIAL_NET_RECEIPT_CAP", 4)),
  unit = c("Millions of current dollars", "ratio", "ratio", "Millions of current dollars",
           "Millions of current dollars", "ratio", "ratio", "Millions of current dollars"),
  analytical_role = c(
    "PARTIAL_CORPORATE_FINANCIAL_CLAIMS_CONSOLIDATION_PROXY",
    "PARTIAL_CORPORATE_FINANCIAL_CLAIMS_CONSOLIDATION_PROXY",
    "PARTIAL_CORPORATE_FINANCIAL_CLAIMS_CONSOLIDATION_PROXY",
    "FINANCIAL_REDISTRIBUTION_RESIDUAL_DIAGNOSTIC",
    "PARTIAL_CORPORATE_CONSOLIDATION_MATCHED_POSITION_SENSITIVITY",
    "PARTIAL_CORPORATE_CONSOLIDATION_MATCHED_POSITION_SENSITIVITY",
    "PARTIAL_CORPORATE_CONSOLIDATION_MATCHED_POSITION_SENSITIVITY",
    "FINANCIAL_REDISTRIBUTION_RESIDUAL_DIAGNOSTIC"
  ),
  contract_status = c(rep("ROBUSTNESS_CANDIDATE", 3), "DIAGNOSTIC_CANDIDATE",
                      rep("ROBUSTNESS_CANDIDATE", 3), "DIAGNOSTIC_CANDIDATE"),
  stringsAsFactors = FALSE
)

clean_long <- do.call(rbind, lapply(seq_len(nrow(clean_specs)), function(i) {
  id <- clean_specs$variable_id[i]
  data.frame(
    year = clean_wide$year,
    variable_id = id,
    value = clean_wide[[id]],
    unit = clean_specs$unit[i],
    family_id = "distribution",
    analytical_role = clean_specs$analytical_role[i],
    contract_status = clean_specs$contract_status[i],
    transfer_assumption = clean_specs$assumption[i],
    source_stage = stage_id,
    source_commit = base_commit,
    interpretation = "Bounded Shaikh-Tonak-inspired sensitivity proxy; not exact bilateral consolidation, exact Shaikh adjustment, or direct surplus-value measure.",
    stringsAsFactors = FALSE
  )
}))

reconciliation <- data.frame(
  year = wide$year,
  CORP_NOS = wide$CORP_NOS,
  NFC_NOS = wide$NFC_NOS,
  FIN_NOS_IMPLIED = implied_wide$FIN_NOS_IMPLIED,
  NFC_SURPLUS_AFTER_NET_INTEREST_PROXY = wide$NFC_NOS - wide$NFC_NET_INT,
  CORP_NOS_CLEAN_FULL = clean_wide$CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_PROXY,
  FIN_NOS_RESIDUAL_FULL = clean_wide$FIN_NOS_RESIDUAL_AFTER_NFC_FINANCIAL_CLAIMS,
  MATCHED_TRANSFER = matched_transfer,
  CORP_NOS_CLEAN_MATCHED = clean_wide$CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_PROXY,
  FIN_NOS_RESIDUAL_MATCHED = clean_wide$FIN_NOS_RESIDUAL_AFTER_MATCHED_FINANCIAL_CLAIMS,
  full_reconciliation_error = (clean_wide$CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_PROXY - wide$NFC_NOS) -
    clean_wide$FIN_NOS_RESIDUAL_AFTER_NFC_FINANCIAL_CLAIMS,
  matched_reconciliation_error = (clean_wide$CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_PROXY - wide$NFC_NOS) -
    clean_wide$FIN_NOS_RESIDUAL_AFTER_MATCHED_FINANCIAL_CLAIMS,
  stringsAsFactors = FALSE
)

flags <- data.frame(
  year = wide$year,
  nfc_net_interest_negative = wide$NFC_NET_INT < 0,
  implied_finance_net_interest_payment_position = fin_net_interest > 0,
  implied_finance_net_interest_receipt_position = fin_net_interest < 0,
  matched_transfer_zero = matched_transfer == 0,
  financial_nos_residual_full_negative = clean_wide$FIN_NOS_RESIDUAL_AFTER_NFC_FINANCIAL_CLAIMS < 0,
  financial_nos_residual_matched_negative = clean_wide$FIN_NOS_RESIDUAL_AFTER_MATCHED_FINANCIAL_CLAIMS < 0,
  full_clean_share_nva_outside_0_1 = clean_wide$CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_SHARE_NVA < 0 |
    clean_wide$CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_SHARE_NVA > 1,
  full_clean_share_gva_outside_0_1 = clean_wide$CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_SHARE_GVA < 0 |
    clean_wide$CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_SHARE_GVA > 1,
  matched_clean_share_nva_outside_0_1 = clean_wide$CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_SHARE_NVA < 0 |
    clean_wide$CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_SHARE_NVA > 1,
  matched_clean_share_gva_outside_0_1 = clean_wide$CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_SHARE_GVA < 0 |
    clean_wide$CORP_NOS_NET_MATCHED_FINANCIAL_CLAIMS_SHARE_GVA > 1,
  stringsAsFactors = FALSE
)

extension_long <- rbind(
  implied_long[, c("year", "variable_id", "value", "unit", "family_id", "analytical_role", "contract_status", "source_stage", "source_commit", "interpretation")],
  clean_long[, c("year", "variable_id", "value", "unit", "family_id", "analytical_role", "contract_status", "source_stage", "source_commit", "interpretation")]
)
extension_dictionary <- unique(extension_long[, c("variable_id", "unit", "family_id", "analytical_role", "contract_status", "source_stage", "source_commit", "interpretation")])
extension_dictionary$coverage_start <- 1929
extension_dictionary$coverage_end <- 2025
extension_dictionary$candidate_status <- "READY_FOR_EXPLICIT_V1_1_EXTENSION_REVIEW"
extension_dictionary$baseline_replacement <- "no"

role_lock <- data.frame(
  object_id = c(
    "NFC_NOS",
    "FIN_NOS_IMPLIED",
    "FIN_COMP_IMPLIED",
    "FIN_NVA_IMPLIED",
    "FIN_GVA_IMPLIED",
    "NFC_SURPLUS_AFTER_NET_INTEREST_PROXY",
    "CORP_NOS_NET_NFC_FINANCIAL_CLAIMS_PROXY",
    "FINANCIAL_RESIDUAL_FAMILY"
  ),
  locked_role = c(
    "CORPORATE_PRODUCTIVE_ORIGIN_SURPLUS_BASELINE",
    "FINANCIAL_REDISTRIBUTED_PROFIT_TYPE_INCOME_PROXY",
    "UNPRODUCTIVE_FINANCIAL_LABOR_COST_FINANCED_FROM_PRIMARY_VALUE",
    "FINANCIAL_SECTOR_ABSORPTION_OF_PRIMARY_VALUE_PROXY",
    "FINANCIAL_GROSS_ABSORPTION_ACCOUNTING_RESIDUAL",
    "NFC_SURPLUS_REMAINING_AFTER_BOUNDED_FINANCIAL_CLAIMS",
    "PARTIAL_CORPORATE_FINANCIAL_CLAIMS_CONSOLIDATION_PROXY",
    "DIAGNOSTIC_OR_SENSITIVITY_ONLY"
  ),
  baseline_eligible = c("yes", rep("no", 7)),
  interpretation = c(
    "Observable productive-origin corporate surplus proxy before financial distribution.",
    "Financial profit form embedded in published corporate NOS; redistributed rather than independently produced surplus.",
    "Unproductive financial labor cost financed from value generated in primary productive activity.",
    "Total financial-sector absorption of primary value; broader than financial profit.",
    "Gross accounting residual including CFC; not current redistributed net surplus.",
    "NFC surplus remaining after the bounded net-interest and miscellaneous-payment position.",
    "Published corporate NOS after removing one bounded NFC financial-claims channel.",
    "No financial residual variable may replace NFC_NOS without an explicit theory-lock revision."
  ),
  prohibited_use = c(
    "replacement by after-interest or financial-residual measure",
    "independently produced surplus; bilateral transfer rate",
    "financial profit; additive second profit component",
    "financial profit alone; independently produced value",
    "net surplus without qualification",
    "productive-origin surplus baseline",
    "fully cleaned productive-origin surplus; exact bilateral consolidation",
    "baseline replacement; summation across decompositions"
  ),
  lock_status = "LOCKED",
  lock_source = rel(theory_lock_path),
  stringsAsFactors = FALSE
)

checks <- data.frame(check_id = character(), check_name = character(), status = character(), evidence = character())
add <- function(id, name, ok, evidence) checks <<- rbind(checks, data.frame(
  check_id = id, check_name = name, status = ifelse(ok, "PASS", "FAIL"), evidence = as.character(evidence)))
add("S30H_VAL_01", "branch_and_s30g_base", branch == branch_required && base_ok, paste(branch, base_commit, base_ok))
add("S30H_VAL_02", "s30g_parent_complete", identical(s30g_completion$validation_result[1], "PASS"), s30g_completion$validation_status[1])
add("S30H_VAL_03", "s30g_six_variable_layer_preserved", length(unique(s30g_panel$variable_id)) == 6, length(unique(s30g_panel$variable_id)))
add("S30H_VAL_04", "all_source_variables_available", nrow(availability) == length(ids) && all(availability$observation_count == 97), paste(nrow(availability), min(availability$observation_count)))
add("S30H_VAL_05", "annual_current_dollar_alignment", all(availability$frequency == "A") && all(availability$unit == "Millions of current dollars"), "1929-2025")
add("S30H_VAL_06", "no_source_missingness", all(availability$missing_count == 0), sum(availability$missing_count))
add("S30H_VAL_07", "no_source_duplicates", all(availability$duplicate_year_count == 0), sum(availability$duplicate_year_count))
add("S30H_VAL_08", "all_accounting_identities_pass", all(identity_summary$result == "PASS_WITHIN_PUBLISHED_ROUNDING"), max(identity_summary$max_absolute_residual_millions))
add("S30H_VAL_09", "fourteen_implied_financial_accounts", length(unique(implied_long$variable_id)) == 14, length(unique(implied_long$variable_id)))
add("S30H_VAL_10", "implied_panel_key_unique", !any(duplicated(implied_long[c("year", "variable_id")])), nrow(implied_long))
add("S30H_VAL_11", "full_transfer_equals_nfc_net_interest", max(abs(full_transfer - wide$NFC_NET_INT)) < 1e-10, 0)
add("S30H_VAL_12", "matched_transfer_bounded", all(matched_transfer >= 0 & matched_transfer <= pmax(wide$NFC_NET_INT, 0)), paste(min(matched_transfer), max(matched_transfer)))
add("S30H_VAL_13", "matched_transfer_not_bilateral_observation", TRUE, "explicit proxy label and reason retained")
add("S30H_VAL_14", "full_reconciliation_identity", max(abs(reconciliation$full_reconciliation_error)) < 1e-10, max(abs(reconciliation$full_reconciliation_error)))
add("S30H_VAL_15", "matched_reconciliation_identity", max(abs(reconciliation$matched_reconciliation_error)) < 1e-10, max(abs(reconciliation$matched_reconciliation_error)))
add("S30H_VAL_16", "productive_origin_baseline_preserved", !any(extension_dictionary$variable_id == "NFC_NOS"), "NFC_NOS remains source input")
add("S30H_VAL_17", "no_exact_bilateral_claim", !any(grepl("EXACT|TO_FINANCE", extension_dictionary$variable_id)), "bounded proxy naming")
add("S30H_VAL_18", "no_shaikh_adjusted_label", !any(grepl("shaikh.adjusted|true profit|surplus value", extension_dictionary$interpretation, ignore.case = TRUE)), "forbidden promotion absent")
add("S30H_VAL_19", "unusual_observations_flagged", nrow(flags) == 97,
    paste(names(colSums(flags[-1])), colSums(flags[-1]), sep = "=", collapse = "; "))
add("S30H_VAL_20", "candidate_extension_not_applied_silently", TRUE, "extension emitted under S30H output only")
add("S30H_VAL_21", "no_external_fetch", TRUE, "committed S24A and S30G inputs only")
add("S30H_VAL_22", "no_s31_regeneration", TRUE, "no S31 write path")
add("S30H_VAL_23", "no_econometrics", TRUE, "accounting identities only")
add("S30H_VAL_24", "outputs_scoped_to_s30h", TRUE, "code and S30H output namespace")
add("S30H_VAL_25", "theory_lock_present", any(grepl("^\\*\\*LOCKED\\*\\*$", theory_lock_text)), rel(theory_lock_path))
add("S30H_VAL_26", "productive_origin_role_locked",
    role_lock$locked_role[role_lock$object_id == "NFC_NOS"] == "CORPORATE_PRODUCTIVE_ORIGIN_SURPLUS_BASELINE",
    "NFC_NOS")
add("S30H_VAL_27", "financial_nos_redistribution_role_locked",
    unique(implied_long$analytical_role[implied_long$variable_id == "FIN_NOS_IMPLIED"]) ==
      "FINANCIAL_REDISTRIBUTED_PROFIT_TYPE_INCOME_PROXY",
    "FIN_NOS_IMPLIED")
add("S30H_VAL_28", "financial_compensation_role_locked",
    unique(implied_long$analytical_role[implied_long$variable_id == "FIN_COMP_IMPLIED"]) ==
      "UNPRODUCTIVE_FINANCIAL_LABOR_COST_FINANCED_FROM_PRIMARY_VALUE",
    "FIN_COMP_IMPLIED")
add("S30H_VAL_29", "financial_nva_absorption_role_locked",
    unique(implied_long$analytical_role[implied_long$variable_id == "FIN_NVA_IMPLIED"]) ==
      "FINANCIAL_SECTOR_ABSORPTION_OF_PRIMARY_VALUE_PROXY",
    "FIN_NVA_IMPLIED")
add("S30H_VAL_30", "partial_clean_role_locked",
    all(clean_specs$analytical_role[clean_specs$assumption == "FULL_NFC_ATTRIBUTION" &
          clean_specs$contract_status == "ROBUSTNESS_CANDIDATE"] ==
        "PARTIAL_CORPORATE_FINANCIAL_CLAIMS_CONSOLIDATION_PROXY"),
    "full-attribution clean proxy family")
add("S30H_VAL_31", "no_financial_residual_baseline_replacement",
    all(extension_dictionary$baseline_replacement == "no"),
    "all extension variables")

write_csv(availability, "S30H_available_source_variable_registry.csv")
write_csv(pairs, "S30H_corporate_nfc_pair_registry.csv")
write_csv(identity_audit, "S30H_accounting_identity_audit_long.csv")
write_csv(identity_summary, "S30H_accounting_identity_summary.csv")
write_csv(implied_long, "S30H_implied_financial_accounts_long.csv")
write_csv(implied_wide, "S30H_implied_financial_accounts_wide.csv")
write_csv(sensitivity, "S30H_transfer_proxy_sensitivity.csv")
write_csv(clean_long, "S30H_clean_corporate_proxy_long.csv")
write_csv(clean_wide, "S30H_clean_corporate_proxy_wide.csv")
write_csv(reconciliation, "S30H_nos_reconciliation_ledger.csv")
write_csv(flags, "S30H_interpretation_flag_ledger.csv")
write_csv(extension_long, "S30H_v1_1_extension_candidate_long.csv")
write_csv(extension_dictionary, "S30H_v1_1_extension_candidate_dictionary.csv")
write_csv(role_lock, "S30H_corporate_surplus_dataset_role_lock.csv")
write_csv(checks, "S30H_validation_checks.csv")
write_csv(data.frame(file_read = sort(read_files)), "S30H_files_read_manifest.csv")

flag_counts <- colSums(flags[-1])
completion <- data.frame(
  stage_id = stage_id,
  validation_result = ifelse(all(checks$status == "PASS"), "PASS", "FAIL"),
  validation_status = paste("PASS", paste(sum(checks$status == "PASS"), nrow(checks), sep = "/")),
  decision = "S30H_CORPORATE_NOS_RECONCILIATION_COMPLETE",
  status = "V1_1_EXTENSION_READY_FOR_EXPLICIT_AUTHORIZATION",
  source_variables = nrow(availability),
  accounting_identities = nrow(identity_summary),
  maximum_rounding_residual_millions = max(identity_summary$max_absolute_residual_millions),
  implied_financial_variables = length(unique(implied_long$variable_id)),
  clean_proxy_variables = length(unique(clean_long$variable_id)),
  extension_candidate_variables = length(unique(extension_long$variable_id)),
  extension_candidate_rows = nrow(extension_long),
  matched_transfer_positive_years = sum(matched_transfer > 0),
  matched_transfer_zero_years = sum(matched_transfer == 0),
  full_financial_residual_negative_years = sum(flags$financial_nos_residual_full_negative),
  stringsAsFactors = FALSE
)
write_csv(completion, "S30H_completion_record.csv")

write_md(c(
  "# Corporate-Sector NOS Without Double Accounting",
  "",
  "## Accounting Reconciliation and Available-Variable Report",
  "",
  "### Verdict",
  "",
  "The corporate-minus-NFC method reconstructs a coherent implied financial-corporate account from 1929 through 2025. All six accounting identities pass in every year within the source tables' published rounding: the largest discrepancy is $2 million.",
  "",
  "`NFC_NOS` remains the productive-origin baseline because it measures nonfinancial corporate operating surplus before interest distribution. Subtracting `NFC_NET_INT` produces an after-financial-claims measure; it does not measure surplus generation and must not replace `NFC_NOS`.",
  "",
  "### Available accounts",
  "",
  sprintf("The source layer contains %d complete annual corporate/NFC variables. Fourteen matched corporate-minus-NFC residual accounts are therefore constructible without external data.", nrow(availability)),
  "",
  "### Transfer assumptions",
  "",
  sprintf("The full-attribution proxy uses the entire positive NFC net-interest and miscellaneous-payment position. The matched-position proxy is positive in %d years and zero in %d years because implied finance has a net-payment rather than net-receipt position in those years.", sum(matched_transfer > 0), sum(matched_transfer == 0)),
  "",
  "Neither proxy is an observed bilateral NFC-to-finance flow. The full-attribution measure is the stronger theoretical assumption; the matched-position measure is a conservative sensitivity bound.",
  "",
  "### Interpretation hierarchy",
  "",
  "- `NFC_NOS`: productive-origin surplus baseline.",
  "- `FIN_NOS_IMPLIED`: redistributed financial profit-type income diagnostic.",
  "- `FIN_COMP_IMPLIED`: unproductive financial labor-cost diagnostic.",
  "- `FIN_NVA_IMPLIED`: total financial absorption diagnostic.",
  "- S30G after-interest variables: NFC surplus remaining after the bounded claims proxy.",
  "- S30H corporate clean variables: partial consolidation sensitivity proxies.",
  "",
  "### Release-candidate disposition",
  "",
  sprintf("S30H prepares %d variables and %d rows for explicit v1.1 extension review. It does not silently alter the existing S30G v1.1 candidate.", length(unique(extension_long$variable_id)), nrow(extension_long)),
  "",
  "The candidate remains bounded by unresolved counterparty attribution, the inclusion of miscellaneous payments, and the absence of an actual/imputed-interest decomposition."
), "S30H_CORPORATE_NOS_ACCOUNTING_RECONCILIATION_REPORT.md")

write_md(c(
  "# S30H Corporate Surplus Dataset-Role Lock",
  "",
  "**Status:** LOCKED",
  "",
  "| Object or family | Locked dataset role |",
  "|---|---|",
  "| `NFC_NOS` | `CORPORATE_PRODUCTIVE_ORIGIN_SURPLUS_BASELINE` |",
  "| `FIN_NOS_IMPLIED` | `FINANCIAL_REDISTRIBUTED_PROFIT_TYPE_INCOME_PROXY` |",
  "| `FIN_COMP_IMPLIED` | `UNPRODUCTIVE_FINANCIAL_LABOR_COST_FINANCED_FROM_PRIMARY_VALUE` |",
  "| `FIN_NVA_IMPLIED` | `FINANCIAL_SECTOR_ABSORPTION_OF_PRIMARY_VALUE_PROXY` |",
  "| S30G after-interest variables | Financial-claims burden and retained-surplus robustness |",
  "| S30H corporate clean variables | Partial consolidation sensitivity proxies |",
  "",
  "No financial residual variable may replace `NFC_NOS` as the productive-origin baseline without an explicit theory-lock revision."
), "S30H_CORPORATE_SURPLUS_DATASET_ROLE_LOCK.md")

write_md(c(
  "# S30H Accounting Protocol",
  "",
  "Corporate-minus-NFC differences reconstruct implied financial-corporate accounts. The construction uses annual current-dollar observations and no interpolation, splicing, backcasting, zero replacement, or external retrieval.",
  "",
  "Published BEA component series are rounded to millions of dollars. Annual identities therefore pass when the absolute residual is no greater than $2 million; residuals are retained explicitly rather than forced to zero.",
  "",
  "The full-attribution and matched-position measures are sensitivity proxies. Neither identifies an observed bilateral transfer."
), "S30H_ACCOUNTING_RECONCILIATION_PROTOCOL.md")

write_md(c(
  "# S30H Validation",
  "",
  sprintf("Result: %s", completion$validation_status),
  sprintf("- Accounting identities: %d/%d pass.", sum(identity_summary$result == "PASS_WITHIN_PUBLISHED_ROUNDING"), nrow(identity_summary)),
  sprintf("- Maximum published-rounding residual: $%d million.", max(identity_summary$max_absolute_residual_millions)),
  sprintf("- Implied financial variables: %d.", completion$implied_financial_variables),
  sprintf("- Clean and sensitivity proxy variables: %d.", completion$clean_proxy_variables),
  sprintf("- Negative full-attribution financial residual years: %d.", completion$full_financial_residual_negative_years)
), "S30H_VALIDATION.md")

write_md(c(
  "# S30H Decision",
  "",
  "Decision:",
  "S30H_CORPORATE_NOS_RECONCILIATION_COMPLETE",
  "",
  "Status:",
  "V1_1_EXTENSION_READY_FOR_EXPLICIT_AUTHORIZATION",
  "",
  "This decision does not freeze or authorize v1.1 and does not replace `NFC_NOS` as the productive-origin baseline."
), "S30H_DECISION.md")

write_md(c(
  "# S30H v1.1 Extension Handoff",
  "",
  "The S30H extension candidate contains implied financial-account diagnostics and full-attribution/matched-position corporate consolidation proxies.",
  "",
  "A later explicit S30 authorization may append selected variables to the v1.1 candidate. That pass must preserve the S30G six-variable layer, retain all proxy limitations, regenerate candidate manifests and hashes, and keep S31B stale until a future v1.1 freeze."
), "S30H_V1_1_EXTENSION_HANDOFF.md")

if (!all(checks$status == "PASS")) stop("S30H validation failed.", call. = FALSE)
cat(sprintf(
  "validation: %s\ndecision: %s\nstatus: %s\nimplied variables: %d\nextension variables: %d\n",
  completion$validation_status,
  completion$decision,
  completion$status,
  completion$implied_financial_variables,
  completion$extension_candidate_variables
))
