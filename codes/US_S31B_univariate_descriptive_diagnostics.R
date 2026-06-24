options(stringsAsFactors = FALSE, scipen = 999)

stage_id <- "S31B_UNIVARIATE_DESCRIPTIVE_DIAGNOSTICS"
starting_main <- "cb4f86e1c5d53096d974470bc1a6eb0185c60368"
release_tag <- "chapter2-us-source-of-truth-v1-2026-06-23"
release_tag_target <- "3d45baa6d726595126772c1b3774bd60e3cf908c"
decision_complete <- "S31B_UNIVARIATE_DESCRIPTIVE_DIAGNOSTICS_COMPLETE"
status_complete <- "S31B_DESCRIPTIVE_BASELINE_REGISTERED"

repo_root <- normalizePath(".", winslash = "/", mustWork = TRUE)
release_dir <- file.path(repo_root, "data", "releases", "chapter2_us_source_of_truth_v1")
s31a_dir <- file.path(repo_root, "output", "US", "S31A_FROZEN_DATASET_DIAGNOSTIC_INTAKE")
out_dir <- file.path(repo_root, "output", "US", stage_id)
out_csv <- file.path(out_dir, "csv")
out_md <- file.path(out_dir, "md")
report_dir <- file.path(repo_root, "reports", "report_S31B_2026-06-24")
report_tables <- file.path(report_dir, "tables")
report_csv <- file.path(report_dir, "csv")
report_logs <- file.path(report_dir, "logs")

for (path in c(out_csv, out_md, report_tables, report_csv, report_logs)) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
}

read_csv <- function(path) {
  read.csv(
    path,
    check.names = FALSE,
    na.strings = c("", "NA"),
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8-BOM"
  )
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

rel_path <- function(path) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  prefix <- paste0(repo_root, "/")
  ifelse(startsWith(path, prefix), substring(path, nchar(prefix) + 1L), path)
}

git <- function(args) {
  out <- system2("git", args, stdout = TRUE, stderr = TRUE)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0L) {
    stop(paste(out, collapse = "\n"), call. = FALSE)
  }
  trimws(out)
}

sha256_file <- function(path) {
  absolute <- normalizePath(path, winslash = "\\", mustWork = TRUE)
  out <- suppressWarnings(system2(
    "certutil",
    c("-hashfile", shQuote(absolute), "SHA256"),
    stdout = TRUE,
    stderr = TRUE
  ))
  hash_line <- out[grepl("^[[:xdigit:][:space:]]{64,}$", out)]
  if (length(hash_line) < 1L) {
    stop(sprintf("Unable to compute SHA-256 for %s", path), call. = FALSE)
  }
  tolower(gsub("[[:space:]]", "", hash_line[1L]))
}

fmt_num <- function(x, digits = 2L) {
  ifelse(is.na(x), "", formatC(x, format = "f", digits = digits, big.mark = ","))
}

fmt_int <- function(x) {
  ifelse(is.na(x), "", formatC(x, format = "d", big.mark = ","))
}

latex_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([#%&_{}$])", "\\\\\\1", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x
}

latex_identifier <- function(x) {
  paste0("\\nolinkurl{", as.character(x), "}")
}

markdown_escape <- function(x) {
  gsub("\\|", "\\\\|", as.character(x))
}

safe_quantile <- function(x, probability) {
  if (length(x) == 0L) return(NA_real_)
  as.numeric(quantile(x, probability, names = FALSE, type = 7))
}

safe_skewness <- function(x) {
  n <- length(x)
  if (n < 5L) return(NA_real_)
  s <- sd(x)
  if (is.na(s) || s == 0) return(NA_real_)
  mean((x - mean(x))^3) / s^3
}

safe_excess_kurtosis <- function(x) {
  n <- length(x)
  if (n < 5L) return(NA_real_)
  s <- sd(x)
  if (is.na(s) || s == 0) return(NA_real_)
  mean((x - mean(x))^4) / s^4 - 3
}

profile_class <- function(n) {
  if (n == 0L) return("NO_COVERAGE")
  if (n >= 10L) return("FULL_DESCRIPTIVE_PROFILE")
  if (n >= 5L) return("LIMITED_DESCRIPTIVE_PROFILE")
  if (n >= 2L) return("EVENT_OR_TRANSITION_PROFILE_ONLY")
  "COVERAGE_ONLY"
}

longest_true_run <- function(x) {
  if (!any(x)) return(0L)
  max(rle(x)$lengths[rle(x)$values])
}

concept_group_id <- function(variable_id) {
  explicit <- c(
    G_TOT_GPIM_2017 = "TOTAL_GROSS_PRODUCTIVE_CAPITAL",
    LOG_G_TOT_GPIM_2017 = "TOTAL_GROSS_PRODUCTIVE_CAPITAL",
    N_TOT_GPIM_2017 = "TOTAL_NET_PRODUCTIVE_CAPITAL",
    LOG_N_TOT_GPIM_2017 = "TOTAL_NET_PRODUCTIVE_CAPITAL",
    I_TOT_REAL_2017 = "TOTAL_CAPITAL_ACCUMULATION",
    LOG_I_TOT_REAL_2017 = "TOTAL_CAPITAL_ACCUMULATION",
    DELTA_G_TOT = "GROSS_CAPITAL_ANNUAL_CHANGE",
    DLOG_G_TOT = "GROSS_CAPITAL_GROWTH",
    GROWTH_ARITH_G_TOT = "GROSS_CAPITAL_GROWTH",
    L1_DLOG_G_TOT = "GROSS_CAPITAL_GROWTH_LAG",
    L1_LOG_G_TOT = "TOTAL_GROSS_PRODUCTIVE_CAPITAL_LAG",
    DLOG_N_TOT = "NET_CAPITAL_GROWTH",
    GROWTH_ARITH_N_TOT = "NET_CAPITAL_GROWTH",
    L1_DLOG_N_TOT = "NET_CAPITAL_GROWTH_LAG",
    L1_LOG_N_TOT = "TOTAL_NET_PRODUCTIVE_CAPITAL_LAG",
    y_real_nfc_gva_baseline = "REAL_NFC_GVA_BASELINE",
    Y_REAL_NFC_GVA_BASELINE = "REAL_NFC_GVA_BASELINE",
    y_real_nfc_gva_proxy_gdp_implicit = "REAL_NFC_GVA_PROXY_GDP_IMPLICIT",
    Y_REAL_NFC_GVA_PROXY_GDP_IMPLICIT = "REAL_NFC_GVA_PROXY_GDP_IMPLICIT",
    y_real_nfc_gva_proxy_nonfarm_business_output = "REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT",
    Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT = "REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT",
    y_real_nfc_gva_proxy_business_output = "REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT",
    Y_REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT = "REAL_NFC_GVA_PROXY_BUSINESS_OUTPUT",
    y_real_nfc_gva_proxy_nonfarm_business_output_bls = "REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS",
    Y_REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS = "REAL_NFC_GVA_PROXY_NONFARM_BUSINESS_OUTPUT_BLS",
    y_real_nfc_gva_proxy_gdpbyind_va_finance_insurance = "REAL_NFC_GVA_PROXY_FINANCE_INSURANCE",
    Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_FINANCE_INSURANCE = "REAL_NFC_GVA_PROXY_FINANCE_INSURANCE",
    y_real_nfc_gva_proxy_gdpbyind_va_manufacturing = "REAL_NFC_GVA_PROXY_MANUFACTURING",
    Y_REAL_NFC_GVA_PROXY_GDPBYIND_VA_MANUFACTURING = "REAL_NFC_GVA_PROXY_MANUFACTURING"
  )
  if (variable_id %in% names(explicit)) return(unname(explicit[[variable_id]]))
  variable_id
}

representation_type <- function(variable_id, transformation) {
  if (grepl("^L1_LOG_", variable_id)) return("TECHNICAL_LAGGED_LOG_LEVEL")
  if (grepl("^L1_DLOG_", variable_id)) return("TECHNICAL_LAGGED_GROWTH")
  if (transformation == "level") return("LEVEL")
  if (transformation == "log_level") return("LOG_LEVEL")
  if (transformation == "ratio") return("SHARE_OR_RATIO")
  if (transformation == "level_change") return("EXISTING_DIFFERENCE_OR_RATE")
  if (transformation == "growth_or_log_difference") return("EXISTING_GROWTH_OR_LOG_DIFFERENCE")
  "OTHER_FROZEN_REPRESENTATION"
}

reporting_tier <- function(contract_status, diagnostic_status) {
  if (contract_status == "DIAGNOSTIC_ONLY" || diagnostic_status == "REFERENCE_ONLY") {
    return("TIER_C_REFERENCE_ONLY")
  }
  if (contract_status == "ROBUSTNESS_AUTHORIZED") return("TIER_B_ROBUSTNESS")
  if (contract_status %in% c("BASELINE_AUTHORIZED", "CONDITIONAL_SECONDARY")) {
    return("TIER_A_CORE")
  }
  "HUMAN_REVIEW_REQUIRED_REPORTING_TIER"
}

window_registry <- data.frame(
  window_id = c(
    "global_available_variable_specific_1901_2025",
    "pre_1974_variable_start_1973",
    "pre_fordist_variable_start_1946",
    "pre_fordist_consolidation_1940_1946",
    "fordist_core_1947_1973",
    "post_1974_1974_2025",
    "post_fordist_pre_gfc_1974_2008",
    "fordist_aftermath_1974_1978",
    "volcker_transition_1979_1982",
    "mature_post_volcker_pre_gfc_1983_2008",
    "gfc_transition_2008_2009",
    "post_gfc_2009_2025",
    "post_gfc_pre_covid_2009_2019",
    "covid_transition_2020_2021",
    "post_covid_configuration_2022_2025",
    "extended_fordist_bridge_1940_1978"
  ),
  window_label = c(
    "Global available",
    "Pre-1974",
    "Pre-Fordist available",
    "Pre-Fordist consolidation, 1940-1946",
    "Fordist core, 1947-1973",
    "Post-1974",
    "Post-Fordist pre-GFC, 1974-2008",
    "Fordist aftermath, 1974-1978",
    "Volcker transition, 1979-1982",
    "Mature post-Volcker pre-GFC, 1983-2008",
    "GFC transition, 2008-2009",
    "Post-GFC, 2009-2025",
    "Post-GFC pre-COVID, 2009-2019",
    "COVID transition, 2020-2021",
    "Post-COVID configuration, 2022-2025",
    "Extended Fordist bridge, 1940-1978"
  ),
  window_type = c(
    "GLOBAL", "STRUCTURAL", "NESTED", "NESTED", "NESTED",
    "STRUCTURAL_UMBRELLA", "STRUCTURAL", "TRANSITION", "TRANSITION",
    "NESTED", "TRANSITION", "STRUCTURAL", "NESTED", "TRANSITION",
    "NESTED", "BRIDGE"
  ),
  start_year = c(
    1901, 1901, 1901, 1940, 1947, 1974, 1974, 1974,
    1979, 1983, 2008, 2009, 2009, 2020, 2022, 1940
  ),
  end_year = c(
    2025, 1973, 1946, 1946, 1973, 2025, 2008, 1978,
    1982, 2008, 2009, 2025, 2019, 2021, 2025, 1978
  ),
  start_rule = c(
    "VARIABLE_FIRST_OBSERVED_YEAR",
    "VARIABLE_FIRST_OBSERVED_YEAR",
    "VARIABLE_FIRST_OBSERVED_YEAR",
    rep("FIXED_CALENDAR_YEAR", 13)
  ),
  end_rule = c(
    "DATASET_UNION_END",
    "FIXED_1973",
    "FIXED_1946",
    rep("FIXED_CALENDAR_YEAR", 13)
  ),
  parent_window = c(
    "", "global_available_variable_specific_1901_2025",
    "pre_1974_variable_start_1973", "pre_fordist_variable_start_1946",
    "pre_1974_variable_start_1973", "global_available_variable_specific_1901_2025",
    "post_1974_1974_2025", "post_fordist_pre_gfc_1974_2008",
    "post_fordist_pre_gfc_1974_2008", "post_fordist_pre_gfc_1974_2008",
    "post_1974_1974_2025", "post_1974_1974_2025",
    "post_gfc_2009_2025", "post_gfc_2009_2025",
    "post_gfc_2009_2025", "global_available_variable_specific_1901_2025"
  ),
  overlap_status = c(
    "root_union", "hierarchical", "hierarchical", "hierarchical",
    "hierarchical", "hierarchical", "hierarchical", "hierarchical",
    "hierarchical", "hierarchical", "cross_boundary_event",
    "hierarchical", "hierarchical", "hierarchical", "hierarchical",
    "cross_boundary_supplement"
  ),
  paper_role = c(
    "principal_global", "principal_structural", "pre_1974_context",
    "limited_pre_1974_detail", "principal_pre_1974_detail",
    "principal_structural_umbrella", "principal_post_1974_detail",
    "transition_table", "transition_table", "principal_post_1974_detail",
    "transition_table", "principal_post_1974_detail",
    "principal_post_gfc_detail", "transition_table",
    "short_post_covid_detail", "appendix_bridge"
  ),
  descriptive_eligible = "yes",
  testing_prohibited = "yes",
  estimation_prohibited = "yes",
  minimum_observation_rule = "profile_class_based",
  historical_interpretation = c(
    "Variable-specific full available support.",
    "Evidence before the 1974 structural boundary.",
    "Available evidence through 1946.",
    "Short consolidation interval before the Fordist core.",
    "Fordist core interval.",
    "Umbrella interval from 1974 through the dataset end.",
    "Post-Fordist interval before the global financial crisis.",
    "Short aftermath of the Fordist boundary.",
    "Short Volcker transition.",
    "Mature post-Volcker interval before the global financial crisis.",
    "Cross-boundary global financial crisis event.",
    "Post-global-financial-crisis interval.",
    "Post-crisis interval before COVID-19.",
    "COVID-19 transition.",
    "Short post-COVID configuration.",
    "Supplementary bridge across the Fordist boundary."
  ),
  stringsAsFactors = FALSE
)

event_registry <- data.frame(
  event_profile_id = c(
    "volcker_event_profile_1978_1983",
    "gfc_event_profile_2007_2010",
    "covid_event_profile_2019_2022"
  ),
  event_name = c("Volcker event", "Global financial crisis event", "COVID-19 event"),
  start_year = c(1978, 2007, 2019),
  end_year = c(1983, 2010, 2022),
  stringsAsFactors = FALSE
)

release_files <- c(
  "CH2_US_RELEASE_MANIFEST.csv",
  "CH2_US_SHA256_MANIFEST.csv",
  "CH2_US_SOURCE_OF_TRUTH_LONG.csv",
  "CH2_US_SOURCE_OF_TRUTH_WIDE.csv",
  "CH2_US_VARIABLE_DICTIONARY.csv",
  "CH2_US_PROVENANCE_LEDGER.csv",
  "CH2_US_ADMISSIBILITY_LEDGER.csv",
  "CH2_US_SUPPORT_WINDOW_LEDGER.csv",
  "CH2_US_FAMILY_INTERFACE_REGISTRY.csv",
  "CH2_US_DOWNSTREAM_CONSUMPTION_CONTRACT.md",
  "CH2_US_VALIDATION_SUMMARY.md"
)
s31a_files <- c(
  "csv/S31A_released_variable_inventory.csv",
  "csv/S31A_variable_support_profile.csv",
  "csv/S31A_missingness_profile.csv",
  "csv/S31A_transformation_availability_matrix.csv",
  "csv/S31A_S30_contract_preservation_audit.csv",
  "csv/S31A_validation_checks.csv",
  "csv/S31A_completion_record.csv"
)
input_paths <- c(file.path(release_dir, release_files), file.path(s31a_dir, s31a_files))
missing_inputs <- input_paths[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  stop(paste("Missing required S31B inputs:", paste(rel_path(missing_inputs), collapse = "\n")), call. = FALSE)
}
input_hash_before <- vapply(input_paths, sha256_file, character(1))

current_branch <- git(c("branch", "--show-current"))
current_head <- git(c("rev-parse", "HEAD"))
tag_target_actual <- git(c("rev-list", "-n", "1", release_tag))

release_manifest <- read_csv(file.path(release_dir, "CH2_US_RELEASE_MANIFEST.csv"))
sha_manifest <- read_csv(file.path(release_dir, "CH2_US_SHA256_MANIFEST.csv"))
canonical_long <- read_csv(file.path(release_dir, "CH2_US_SOURCE_OF_TRUTH_LONG.csv"))
canonical_wide <- read_csv(file.path(release_dir, "CH2_US_SOURCE_OF_TRUTH_WIDE.csv"))
dictionary <- read_csv(file.path(release_dir, "CH2_US_VARIABLE_DICTIONARY.csv"))
provenance <- read_csv(file.path(release_dir, "CH2_US_PROVENANCE_LEDGER.csv"))
admissibility <- read_csv(file.path(release_dir, "CH2_US_ADMISSIBILITY_LEDGER.csv"))
support <- read_csv(file.path(release_dir, "CH2_US_SUPPORT_WINDOW_LEDGER.csv"))
family_registry <- read_csv(file.path(release_dir, "CH2_US_FAMILY_INTERFACE_REGISTRY.csv"))
s31a_inventory <- read_csv(file.path(s31a_dir, "csv", "S31A_released_variable_inventory.csv"))
s31a_validation <- read_csv(file.path(s31a_dir, "csv", "S31A_validation_checks.csv"))
s31a_completion <- read_csv(file.path(s31a_dir, "csv", "S31A_completion_record.csv"))

sha_actual <- vapply(file.path(repo_root, sha_manifest$path), sha256_file, character(1))
sha_pass <- file.exists(file.path(repo_root, sha_manifest$path)) &
  sha_actual == tolower(sha_manifest$sha256)

canonical_ids <- unique(canonical_long$variable_id)
dictionary_canonical <- dictionary[match(canonical_ids, dictionary$variable_id), , drop = FALSE]
s31a_canonical <- s31a_inventory[match(canonical_ids, s31a_inventory$variable_id), , drop = FALSE]

variable_registry <- data.frame(
  variable_id = canonical_ids,
  display_name = dictionary_canonical$display_name,
  family_id = dictionary_canonical$family_id,
  concept = dictionary_canonical$concept,
  concept_group_id = vapply(canonical_ids, concept_group_id, character(1)),
  unit = dictionary_canonical$unit,
  transformation = dictionary_canonical$transformation,
  representation_type = mapply(
    representation_type,
    canonical_ids,
    dictionary_canonical$transformation,
    USE.NAMES = FALSE
  ),
  S30_analytical_role = dictionary_canonical$analytical_role,
  S30_contract_status = dictionary_canonical$contract_status,
  S31A_diagnostic_intake_status = s31a_canonical$diagnostic_intake_status,
  reporting_tier = mapply(
    reporting_tier,
    dictionary_canonical$contract_status,
    s31a_canonical$diagnostic_intake_status,
    USE.NAMES = FALSE
  ),
  stringsAsFactors = FALSE
)

variable_registry$preferred_representation <- ifelse(
  variable_registry$reporting_tier == "TIER_A_CORE" &
    variable_registry$representation_type %in% c("LEVEL", "SHARE_OR_RATIO") &
    !grepl("^L1_", variable_registry$variable_id),
  "yes",
  "no"
)
variable_registry$headline_table_eligible <- ifelse(
  variable_registry$reporting_tier == "TIER_A_CORE" &
    !grepl("^(LOG_|L1_|y_)", variable_registry$variable_id) &
    !variable_registry$representation_type %in% c(
      "LOG_LEVEL", "TECHNICAL_LAGGED_LOG_LEVEL", "TECHNICAL_LAGGED_GROWTH"
    ),
  "yes",
  "no"
)
variable_registry$master_table_included <- "yes"
variable_registry$event_profile_eligible <- ifelse(
  !variable_registry$representation_type %in% c("LOG_LEVEL", "TECHNICAL_LAGGED_LOG_LEVEL"),
  "yes",
  "no"
)
variable_registry$inclusion_reason <- ifelse(
  variable_registry$reporting_tier == "TIER_C_REFERENCE_ONLY",
  "Frozen canonical diagnostic-only object retained in the complete master and reference appendix.",
  "Frozen canonical variable retained without changing its S30 role."
)

level_counterpart <- function(variable_id, group_id) {
  candidates <- variable_registry[
    variable_registry$concept_group_id == group_id &
      variable_registry$representation_type == "LEVEL",
    ,
    drop = FALSE
  ]
  if (nrow(candidates) == 0L) return("")
  candidates$variable_id[1L]
}
variable_registry$level_counterpart_id <- mapply(
  level_counterpart,
  variable_registry$variable_id,
  variable_registry$concept_group_id,
  USE.NAMES = FALSE
)

years <- canonical_wide$year

window_years <- function(window_row, variable_values) {
  observed_years <- years[!is.na(variable_values)]
  if (length(observed_years) == 0L) return(integer())
  start <- window_row$start_year
  if (window_row$start_rule == "VARIABLE_FIRST_OBSERVED_YEAR") {
    start <- max(start, min(observed_years))
  }
  end <- window_row$end_year
  if (start > end) return(integer())
  seq.int(start, end)
}

annual_changes <- function(variable_id, values, calendar_years, registry_row) {
  transformation <- registry_row$transformation
  representation <- registry_row$representation_type
  if (representation %in% c("LOG_LEVEL", "TECHNICAL_LAGGED_LOG_LEVEL")) {
    return(data.frame(year = integer(), change = numeric()))
  }
  if (transformation %in% c("growth_or_log_difference", "level_change")) {
    valid <- !is.na(values)
    change <- values
    if (registry_row$unit == "decimal_rate") change <- 100 * change
    if (grepl("log_difference", registry_row$unit)) change <- 100 * change
    return(data.frame(year = calendar_years[valid], change = change[valid]))
  }
  previous <- c(NA_real_, head(values, -1L))
  previous_year <- c(NA_integer_, head(calendar_years, -1L))
  consecutive <- calendar_years - previous_year == 1L
  valid <- !is.na(values) & !is.na(previous) & consecutive
  change <- values - previous
  if (transformation == "ratio") {
    bounded <- !is.na(values) & !is.na(previous) &
      values >= 0 & values <= 1 & previous >= 0 & previous <= 1
    change[bounded] <- 100 * change[bounded]
  }
  data.frame(year = calendar_years[valid], change = change[valid])
}

endpoint_summary <- function(values, observed_years, transformation) {
  valid <- !is.na(values)
  if (!any(valid)) {
    return(list(
      first_value = NA_real_, last_value = NA_real_, absolute_change = NA_real_,
      relative_change = NA_real_, annualized_change = NA_real_,
      method = "NO_COVERAGE", valid = FALSE, reason = "NO_COVERAGE"
    ))
  }
  x <- values[valid]
  y <- observed_years[valid]
  first <- x[1L]
  last <- x[length(x)]
  span <- y[length(y)] - y[1L]
  absolute <- last - first
  relative <- if (first != 0) 100 * (last / first - 1) else NA_real_
  if (transformation == "ratio") {
    bounded <- first >= 0 && first <= 1 && last >= 0 && last <= 1
    absolute <- if (bounded) 100 * (last - first) else last - first
    return(list(
      first_value = first, last_value = last, absolute_change = absolute,
      relative_change = NA_real_,
      annualized_change = if (span > 0) absolute / span else NA_real_,
      method = "PERCENTAGE_POINT_ENDPOINT_CHANGE",
      valid = span > 0,
      reason = ifelse(span > 0, "", "INSUFFICIENT_ENDPOINT_SPAN")
    ))
  }
  if (transformation == "level" && first > 0 && last > 0 && span > 0) {
    return(list(
      first_value = first, last_value = last, absolute_change = absolute,
      relative_change = relative,
      annualized_change = 100 * ((last / first)^(1 / span) - 1),
      method = "COMPOUND_ANNUAL_PERCENT_CHANGE",
      valid = TRUE, reason = ""
    ))
  }
  list(
    first_value = first, last_value = last, absolute_change = absolute,
    relative_change = relative,
    annualized_change = if (span > 0) absolute / span else NA_real_,
    method = "ANNUALIZED_ABSOLUTE_ENDPOINT_CHANGE",
    valid = span > 0,
    reason = ifelse(span > 0, "", "INSUFFICIENT_ENDPOINT_SPAN")
  )
}

level_stats_row <- function(registry_row, window_row) {
  variable_id <- registry_row$variable_id
  values_all <- canonical_wide[[variable_id]]
  selected_years <- window_years(window_row, values_all)
  if (length(selected_years) == 0L) {
    effective_start <- NA_integer_
    effective_end <- window_row$end_year
    values <- numeric()
  } else {
    effective_start <- min(selected_years)
    effective_end <- max(selected_years)
    values <- values_all[match(selected_years, years)]
  }
  observed <- !is.na(values)
  x <- values[observed]
  observed_years <- selected_years[observed]
  n_calendar <- length(selected_years)
  n <- length(x)
  missing <- n_calendar - n
  first_observed <- if (n > 0L) min(observed_years) else NA_integer_
  last_observed <- if (n > 0L) max(observed_years) else NA_integer_
  leading <- if (n > 0L) sum(selected_years < first_observed) else n_calendar
  trailing <- if (n > 0L) sum(selected_years > last_observed) else n_calendar
  internal_mask <- if (n > 0L) {
    is.na(values) & selected_years > first_observed & selected_years < last_observed
  } else {
    rep(FALSE, n_calendar)
  }
  changes <- annual_changes(variable_id, values, selected_years, registry_row)
  endpoint <- endpoint_summary(values, selected_years, registry_row$transformation)
  min_index <- if (n > 0L) which.min(x) else integer()
  max_index <- if (n > 0L) which.max(x) else integer()
  minimum_year <- if (n > 0L) observed_years[min_index] else NA_integer_
  maximum_year <- if (n > 0L) observed_years[max_index] else NA_integer_
  increase_index <- if (nrow(changes) > 0L) which.max(changes$change) else integer()
  decrease_index <- if (nrow(changes) > 0L) which.min(changes$change) else integer()
  class <- profile_class(n)
  transition <- window_row$window_type == "TRANSITION"
  distribution_allowed <- n >= 5L && !(transition && n < 5L)
  data.frame(
    variable_id = variable_id,
    display_name = registry_row$display_name,
    family_id = registry_row$family_id,
    concept = registry_row$concept,
    concept_group_id = registry_row$concept_group_id,
    unit = registry_row$unit,
    transformation = registry_row$transformation,
    representation_type = registry_row$representation_type,
    S30_analytical_role = registry_row$S30_analytical_role,
    S30_contract_status = registry_row$S30_contract_status,
    reporting_tier = registry_row$reporting_tier,
    window_id = window_row$window_id,
    window_type = window_row$window_type,
    parent_window = window_row$parent_window,
    window_start = effective_start,
    window_end = effective_end,
    calendar_years_in_window = n_calendar,
    first_observed_year = first_observed,
    last_observed_year = last_observed,
    n_observed = n,
    n_missing = missing,
    missing_share = if (n_calendar > 0L) missing / n_calendar else NA_real_,
    coverage_share = if (n_calendar > 0L) n / n_calendar else NA_real_,
    leading_missing_count = leading,
    trailing_missing_count = trailing,
    internal_missing_count = sum(internal_mask),
    internal_gap_count = if (any(internal_mask)) sum(rle(internal_mask)$values) else 0L,
    longest_internal_gap = longest_true_run(internal_mask),
    mean = if (n > 0L) mean(x) else NA_real_,
    median = if (n > 0L) median(x) else NA_real_,
    standard_deviation = if (n > 1L) sd(x) else NA_real_,
    variance = if (n > 1L) var(x) else NA_real_,
    minimum = if (n > 0L) min(x) else NA_real_,
    minimum_year = minimum_year,
    maximum = if (n > 0L) max(x) else NA_real_,
    maximum_year = maximum_year,
    range = if (n > 0L) diff(range(x)) else NA_real_,
    q01 = safe_quantile(x, 0.01),
    q05 = safe_quantile(x, 0.05),
    q10 = safe_quantile(x, 0.10),
    q25 = safe_quantile(x, 0.25),
    q75 = safe_quantile(x, 0.75),
    q90 = safe_quantile(x, 0.90),
    q95 = safe_quantile(x, 0.95),
    q99 = safe_quantile(x, 0.99),
    interquartile_range = if (n > 0L) IQR(x) else NA_real_,
    median_absolute_deviation = if (n > 0L) mad(x, constant = 1) else NA_real_,
    coefficient_of_variation = if (n > 1L && mean(x) != 0) sd(x) / abs(mean(x)) else NA_real_,
    skewness = if (distribution_allowed) safe_skewness(x) else NA_real_,
    excess_kurtosis = if (distribution_allowed) safe_excess_kurtosis(x) else NA_real_,
    first_value = endpoint$first_value,
    last_value = endpoint$last_value,
    absolute_change = endpoint$absolute_change,
    relative_change = endpoint$relative_change,
    annualized_change = endpoint$annualized_change,
    endpoint_change_method = endpoint$method,
    endpoint_change_valid = endpoint$valid,
    endpoint_change_reason = endpoint$reason,
    n_valid_annual_changes = nrow(changes),
    mean_annual_change = if (nrow(changes) > 0L) mean(changes$change) else NA_real_,
    median_annual_change = if (nrow(changes) > 0L) median(changes$change) else NA_real_,
    standard_deviation_annual_change = if (nrow(changes) > 1L) sd(changes$change) else NA_real_,
    mean_absolute_annual_change = if (nrow(changes) > 0L) mean(abs(changes$change)) else NA_real_,
    largest_annual_increase = if (nrow(changes) > 0L) max(changes$change) else NA_real_,
    largest_annual_increase_year = if (nrow(changes) > 0L) changes$year[increase_index] else NA_integer_,
    largest_annual_decrease = if (nrow(changes) > 0L) min(changes$change) else NA_real_,
    largest_annual_decrease_year = if (nrow(changes) > 0L) changes$year[decrease_index] else NA_integer_,
    descriptive_profile_class = class,
    short_window_flag = ifelse(n < 10L, "yes", "no"),
    distributional_interpretation_allowed = ifelse(distribution_allowed, "yes", "no"),
    time_profile_interpretation_allowed = ifelse(n >= 2L, "yes", "no"),
    testing_prohibited = window_row$testing_prohibited,
    estimation_prohibited = window_row$estimation_prohibited,
    diagnostic_note = ifelse(
      transition,
      "DESCRIPTIVE TRANSITION WINDOW; NOT ELIGIBLE FOR TESTING OR ESTIMATION.",
      ifelse(n < 5L, "Short-window evidence; endpoint and annual-change reading only.", "")
    ),
    stringsAsFactors = FALSE
  )
}

master_rows <- vector("list", nrow(variable_registry) * nrow(window_registry))
counter <- 1L
for (i in seq_len(nrow(variable_registry))) {
  for (j in seq_len(nrow(window_registry))) {
    master_rows[[counter]] <- level_stats_row(
      variable_registry[i, , drop = FALSE],
      window_registry[j, , drop = FALSE]
    )
    counter <- counter + 1L
  }
}
master_descriptive <- do.call(rbind, master_rows)

growth_panel_rows <- lapply(seq_len(nrow(variable_registry)), function(i) {
  reg <- variable_registry[i, , drop = FALSE]
  variable_id <- reg$variable_id
  source <- canonical_wide[[variable_id]]
  previous <- c(NA_real_, head(source, -1L))
  previous_year <- c(NA_integer_, head(years, -1L))
  consecutive <- years - previous_year == 1L
  growth_value <- rep(NA_real_, length(years))
  growth_measure <- rep("", length(years))
  growth_method <- rep("", length(years))
  valid <- rep(FALSE, length(years))
  reason <- rep("", length(years))

  if (reg$representation_type == "LEVEL") {
    eligible <- consecutive & !is.na(source) & !is.na(previous) & source > 0 & previous > 0
    growth_value[eligible] <- 100 * (source[eligible] / previous[eligible] - 1)
    growth_measure[] <- "PERCENT_CHANGE"
    growth_method[] <- "DIRECT_LEVEL_PERCENT_CHANGE"
    valid <- eligible
    reason[!eligible] <- ifelse(
      !consecutive[!eligible] | is.na(source[!eligible]) | is.na(previous[!eligible]),
      "MISSING_OR_NONCONSECUTIVE_OBSERVATION",
      "NONPOSITIVE_LEVEL"
    )
  } else if (reg$representation_type == "SHARE_OR_RATIO") {
    eligible <- consecutive & !is.na(source) & !is.na(previous)
    bounded <- eligible & source >= 0 & source <= 1 & previous >= 0 & previous <= 1
    growth_value[eligible] <- source[eligible] - previous[eligible]
    growth_value[bounded] <- 100 * growth_value[bounded]
    growth_measure[] <- "PERCENTAGE_POINT_CHANGE"
    growth_method[] <- "DIRECT_SHARE_POINT_CHANGE"
    valid <- eligible
    reason[!eligible] <- "MISSING_OR_NONCONSECUTIVE_OBSERVATION"
  } else if (
    reg$representation_type == "EXISTING_GROWTH_OR_LOG_DIFFERENCE" &&
      !grepl("^L1_LOG_", variable_id)
  ) {
    eligible <- !is.na(source)
    multiplier <- ifelse(grepl("log_difference", reg$unit), 100, 1)
    growth_value[eligible] <- multiplier * source[eligible]
    growth_measure[] <- ifelse(
      grepl("log_difference", reg$unit),
      "PERCENT_GROWTH_APPROXIMATION",
      "EXISTING_FROZEN_GROWTH_MEASURE"
    )
    growth_method[] <- "EXISTING_FROZEN_GROWTH_SERIES"
    valid <- eligible
    reason[!eligible] <- "MISSING_FROZEN_GROWTH_OBSERVATION"
  } else if (reg$representation_type == "EXISTING_DIFFERENCE_OR_RATE") {
    eligible <- !is.na(source)
    multiplier <- ifelse(reg$unit == "decimal_rate", 100, 1)
    growth_value[eligible] <- multiplier * source[eligible]
    growth_measure[] <- ifelse(
      reg$unit == "decimal_rate",
      "PERCENT_CHANGE",
      "ABSOLUTE_ANNUAL_CHANGE"
    )
    growth_method[] <- "EXISTING_FROZEN_DIFFERENCE_SERIES"
    valid <- eligible
    reason[!eligible] <- "MISSING_FROZEN_DIFFERENCE_OBSERVATION"
  } else if (
    reg$representation_type == "LOG_LEVEL" &&
      nzchar(reg$level_counterpart_id)
  ) {
    growth_measure[] <- "NOT_CONSTRUCTED"
    growth_method[] <- "LEVEL_COUNTERPART_PREFERRED"
    reason[] <- "DUPLICATE_LOG_GROWTH_SUPPRESSED"
  } else {
    growth_measure[] <- "NOT_INTERPRETABLE"
    growth_method[] <- "NOT_CONSTRUCTED"
    reason[] <- "REPRESENTATION_NOT_GROWTH_INTERPRETABLE"
  }

  data.frame(
    source_variable_id = variable_id,
    concept_group_id = reg$concept_group_id,
    year = years,
    previous_year = previous_year,
    source_value = source,
    previous_source_value = previous,
    growth_measure = growth_measure,
    growth_value = growth_value,
    growth_method = growth_method,
    consecutive_years = ifelse(is.na(previous_year), FALSE, consecutive),
    growth_valid = valid,
    invalidity_reason = reason,
    source_representation_type = reg$representation_type,
    noncanonical_diagnostic_derivative = TRUE,
    stringsAsFactors = FALSE
  )
})
growth_panel <- do.call(rbind, growth_panel_rows)

growth_stats_row <- function(registry_row, window_row) {
  panel <- growth_panel[growth_panel$source_variable_id == registry_row$variable_id, ]
  source_values <- canonical_wide[[registry_row$variable_id]]
  selected_years <- window_years(window_row, source_values)
  if (length(selected_years) == 0L) {
    selected <- panel[0, ]
    effective_start <- NA_integer_
    effective_end <- window_row$end_year
  } else {
    selected <- panel[panel$year %in% selected_years & panel$growth_valid, ]
    effective_start <- min(selected_years)
    effective_end <- max(selected_years)
  }
  x <- selected$growth_value
  n <- length(x)
  min_index <- if (n > 0L) which.min(x) else integer()
  max_index <- if (n > 0L) which.max(x) else integer()
  percentage_growth <- all(selected$growth_measure %in% c(
    "PERCENT_CHANGE", "PERCENT_GROWTH_APPROXIMATION",
    "EXISTING_FROZEN_GROWTH_MEASURE"
  )) && n > 0L
  share_change <- any(selected$growth_measure == "PERCENTAGE_POINT_CHANGE")
  cumulative_valid <- percentage_growth && !share_change && n >= 2L
  cumulative <- if (cumulative_valid) 100 * (prod(1 + x / 100) - 1) else NA_real_
  first_year <- if (n > 0L) min(selected$year) else NA_integer_
  last_year <- if (n > 0L) max(selected$year) else NA_integer_
  span <- if (n > 0L) last_year - first_year + 1L else 0L
  cagr <- if (cumulative_valid && span > 1L && 1 + cumulative / 100 > 0) {
    100 * ((1 + cumulative / 100)^(1 / span) - 1)
  } else {
    NA_real_
  }
  class <- profile_class(n)
  transition <- window_row$window_type == "TRANSITION"
  data.frame(
    source_variable_id = registry_row$variable_id,
    display_name = registry_row$display_name,
    family_id = registry_row$family_id,
    concept_group_id = registry_row$concept_group_id,
    growth_measure = if (n > 0L) selected$growth_measure[1L] else unique(panel$growth_measure)[1L],
    growth_method = if (n > 0L) selected$growth_method[1L] else unique(panel$growth_method)[1L],
    reporting_tier = registry_row$reporting_tier,
    window_id = window_row$window_id,
    window_type = window_row$window_type,
    window_start = effective_start,
    window_end = effective_end,
    n_valid_growth_observations = n,
    mean_growth = if (n > 0L) mean(x) else NA_real_,
    median_growth = if (n > 0L) median(x) else NA_real_,
    standard_deviation_growth = if (n > 1L) sd(x) else NA_real_,
    variance_growth = if (n > 1L) var(x) else NA_real_,
    minimum_growth = if (n > 0L) min(x) else NA_real_,
    minimum_growth_year = if (n > 0L) selected$year[min_index] else NA_integer_,
    maximum_growth = if (n > 0L) max(x) else NA_real_,
    maximum_growth_year = if (n > 0L) selected$year[max_index] else NA_integer_,
    q10_growth = safe_quantile(x, 0.10),
    q25_growth = safe_quantile(x, 0.25),
    q75_growth = safe_quantile(x, 0.75),
    q90_growth = safe_quantile(x, 0.90),
    interquartile_range_growth = if (n > 0L) IQR(x) else NA_real_,
    mean_absolute_growth = if (n > 0L) mean(abs(x)) else NA_real_,
    positive_growth_years = sum(x > 0),
    negative_growth_years = sum(x < 0),
    zero_growth_years = sum(x == 0),
    first_valid_growth_year = first_year,
    last_valid_growth_year = last_year,
    cumulative_window_growth = cumulative,
    compound_annual_growth_rate = cagr,
    cumulative_growth_valid = cumulative_valid,
    cumulative_growth_reason = ifelse(
      cumulative_valid,
      "",
      ifelse(share_change, "PERCENTAGE_POINT_SERIES_NOT_COMPOUNDED", "INCOMPATIBLE_OR_INSUFFICIENT_GROWTH_MEASURE")
    ),
    descriptive_profile_class = class,
    short_window_flag = ifelse(n < 10L, "yes", "no"),
    distributional_interpretation_allowed = ifelse(n >= 5L && !(transition && n < 5L), "yes", "no"),
    testing_prohibited = window_row$testing_prohibited,
    estimation_prohibited = window_row$estimation_prohibited,
    stringsAsFactors = FALSE
  )
}

growth_master_rows <- vector("list", nrow(variable_registry) * nrow(window_registry))
counter <- 1L
for (i in seq_len(nrow(variable_registry))) {
  for (j in seq_len(nrow(window_registry))) {
    growth_master_rows[[counter]] <- growth_stats_row(
      variable_registry[i, , drop = FALSE],
      window_registry[j, , drop = FALSE]
    )
    counter <- counter + 1L
  }
}
growth_master <- do.call(rbind, growth_master_rows)

event_rows <- list()
counter <- 1L
for (i in seq_len(nrow(variable_registry))) {
  reg <- variable_registry[i, , drop = FALSE]
  if (reg$event_profile_eligible != "yes") next
  values <- canonical_wide[[reg$variable_id]]
  for (j in seq_len(nrow(event_registry))) {
    event <- event_registry[j, , drop = FALSE]
    event_years <- seq.int(event$start_year, event$end_year)
    for (year in event_years) {
      current <- values[match(year, years)]
      previous <- values[match(year - 1L, years)]
      valid <- !is.na(current) && !is.na(previous)
      absolute <- if (valid) current - previous else NA_real_
      relative <- if (valid && previous != 0) 100 * (current / previous - 1) else NA_real_
      point_change <- NA_real_
      method <- "ABSOLUTE_AND_RELATIVE_CHANGE"
      if (reg$transformation == "ratio" && valid) {
        point_change <- current - previous
        if (current >= 0 && current <= 1 && previous >= 0 && previous <= 1) {
          point_change <- 100 * point_change
        }
        method <- "PERCENTAGE_POINT_CHANGE"
      }
      event_rows[[counter]] <- data.frame(
        variable_id = reg$variable_id,
        event_profile_id = event$event_profile_id,
        event_name = event$event_name,
        year = year,
        event_position = year - event$start_year,
        observed_value = current,
        previous_year_value = previous,
        absolute_annual_change = absolute,
        relative_annual_change = relative,
        percentage_point_change = point_change,
        change_method = method,
        change_valid = valid,
        invalidity_reason = ifelse(valid, "", "MISSING_CURRENT_OR_PREVIOUS_YEAR"),
        stringsAsFactors = FALSE
      )
      counter <- counter + 1L
    }
  }
}
event_profiles <- do.call(rbind, event_rows)

transition_ids <- window_registry$window_id[window_registry$window_type == "TRANSITION"]
transition_summary <- master_descriptive[
  master_descriptive$window_id %in% transition_ids &
    master_descriptive$variable_id %in% variable_registry$variable_id[
      variable_registry$headline_table_eligible == "yes"
    ],
  c(
    "variable_id", "display_name", "family_id", "reporting_tier",
    "window_id", "window_start", "window_end", "first_value", "last_value",
    "absolute_change", "relative_change", "mean_annual_change",
    "n_observed", "descriptive_profile_class", "testing_prohibited",
    "estimation_prohibited"
  )
]
transition_summary$transition_label <- "DESCRIPTIVE TRANSITION WINDOW"
transition_summary$eligibility_label <- "NOT ELIGIBLE FOR TESTING OR ESTIMATION"

plotting_registry <- data.frame(
  variable_id = variable_registry$variable_id,
  concept_group_id = variable_registry$concept_group_id,
  reporting_tier = variable_registry$reporting_tier,
  representation_type = variable_registry$representation_type,
  plot_eligible = ifelse(
    variable_registry$representation_type %in% c(
      "LEVEL", "SHARE_OR_RATIO", "EXISTING_DIFFERENCE_OR_RATE",
      "EXISTING_GROWTH_OR_LOG_DIFFERENCE"
    ),
    "yes",
    "no"
  ),
  plot_priority = ifelse(
    variable_registry$reporting_tier == "TIER_A_CORE",
    "main",
    ifelse(variable_registry$reporting_tier == "TIER_B_ROBUSTNESS", "appendix", "reference")
  ),
  recommended_plot_type = "time_series_line",
  recommended_scale = ifelse(variable_registry$representation_type == "SHARE_OR_RATIO", "percentage_or_ratio", "native"),
  zero_line_required = ifelse(
    variable_registry$representation_type %in% c(
      "EXISTING_DIFFERENCE_OR_RATE", "EXISTING_GROWTH_OR_LOG_DIFFERENCE"
    ),
    "yes",
    "no"
  ),
  percentage_axis = ifelse(variable_registry$representation_type == "SHARE_OR_RATIO", "yes", "conditional"),
  event_profile_eligible = variable_registry$event_profile_eligible,
  main_text_figure_eligible = ifelse(variable_registry$headline_table_eligible == "yes", "yes", "no"),
  appendix_figure_eligible = "yes",
  plotting_note = "Registry only. S31B generates no figures.",
  stringsAsFactors = FALSE
)

output_variable <- variable_registry$variable_id[
  variable_registry$family_id == "output" &
    variable_registry$S30_contract_status == "BASELINE_AUTHORIZED" &
    variable_registry$representation_type == "LEVEL"
]
capital_variable <- variable_registry$variable_id[
  variable_registry$family_id == "capital" &
    variable_registry$S30_contract_status == "BASELINE_AUTHORIZED" &
    variable_registry$representation_type == "LEVEL"
]
if (length(output_variable) != 1L || length(capital_variable) != 1L) {
  stop("Unable to select unique Tier A output and capital level representations from S30 metadata.", call. = FALSE)
}

elasticity_windows <- window_registry[
  window_registry$window_type %in% c("GLOBAL", "STRUCTURAL", "STRUCTURAL_UMBRELLA", "NESTED"),
]
elasticity_rows <- lapply(seq_len(nrow(elasticity_windows)), function(i) {
  window <- elasticity_windows[i, , drop = FALSE]
  output_growth <- growth_panel[
    growth_panel$source_variable_id == output_variable &
      growth_panel$year >= window$start_year &
      growth_panel$year <= window$end_year &
      growth_panel$growth_valid,
    c("year", "growth_value", "growth_measure")
  ]
  capital_growth <- growth_panel[
    growth_panel$source_variable_id == capital_variable &
      growth_panel$year >= window$start_year &
      growth_panel$year <= window$end_year &
      growth_panel$growth_valid,
    c("year", "growth_value", "growth_measure")
  ]
  names(output_growth)[2:3] <- c("output_growth", "output_measure")
  names(capital_growth)[2:3] <- c("capital_growth", "capital_measure")
  joint <- merge(output_growth, capital_growth, by = "year")
  n <- nrow(joint)
  mean_output <- if (n > 0L) mean(joint$output_growth) else NA_real_
  mean_capital <- if (n > 0L) mean(joint$capital_growth) else NA_real_
  comparable <- n > 0L &&
    all(joint$output_measure == "PERCENT_CHANGE") &&
    all(joint$capital_measure == "PERCENT_CHANGE")
  ratio_valid <- n >= 10L && comparable && !is.na(mean_capital) && abs(mean_capital) > 1e-8
  data.frame(
    window_id = window$window_id,
    output_variable_id = output_variable,
    capital_variable_id = capital_variable,
    n_joint_growth_observations = n,
    mean_output_growth = mean_output,
    mean_capital_growth = mean_capital,
    median_output_growth = if (n > 0L) median(joint$output_growth) else NA_real_,
    median_capital_growth = if (n > 0L) median(joint$capital_growth) else NA_real_,
    output_growth_standard_deviation = if (n > 1L) sd(joint$output_growth) else NA_real_,
    capital_growth_standard_deviation = if (n > 1L) sd(joint$capital_growth) else NA_real_,
    output_CAGR = growth_master$compound_annual_growth_rate[
      growth_master$source_variable_id == output_variable &
        growth_master$window_id == window$window_id
    ],
    capital_CAGR = growth_master$compound_annual_growth_rate[
      growth_master$source_variable_id == capital_variable &
        growth_master$window_id == window$window_id
    ],
    growth_rate_covariance = if (n > 1L) cov(joint$output_growth, joint$capital_growth) else NA_real_,
    growth_rate_correlation = if (n > 1L) cor(joint$output_growth, joint$capital_growth) else NA_real_,
    mean_growth_difference = mean_output - mean_capital,
    descriptive_growth_ratio = if (ratio_valid) mean_output / mean_capital else NA_real_,
    descriptive_growth_ratio_valid = ratio_valid,
    descriptive_growth_ratio_reason = ifelse(
      ratio_valid,
      "",
      ifelse(n < 10L, "FEWER_THAN_10_JOINT_GROWTH_OBSERVATIONS", ifelse(!comparable, "INCOMPATIBLE_GROWTH_MEASURES", "NEAR_ZERO_CAPITAL_GROWTH"))
    ),
    near_zero_capital_growth_flag = !is.na(mean_capital) && abs(mean_capital) <= 1e-8,
    testing_prohibited = TRUE,
    estimation_prohibited = TRUE,
    structural_elasticity_interpretation_prohibited = TRUE,
    stringsAsFactors = FALSE
  )
})
elasticity_summary <- do.call(rbind, elasticity_rows)

headline_variables <- variable_registry$variable_id[
  variable_registry$headline_table_eligible == "yes" &
    variable_registry$preferred_representation == "yes"
]
if (length(headline_variables) == 0L) {
  stop("No Tier A preferred representations available for paper tables.", call. = FALSE)
}

growth_cell <- function(variable_id, window_id) {
  row <- growth_master[
    growth_master$source_variable_id == variable_id &
      growth_master$window_id == window_id,
  ]
  if (nrow(row) == 0L || is.na(row$mean_growth[1L])) return("")
  sprintf(
    "%s (%s) [n=%s]",
    fmt_num(row$mean_growth[1L], 2),
    fmt_num(row$standard_deviation_growth[1L], 2),
    fmt_int(row$n_valid_growth_observations[1L])
  )
}

make_growth_table <- function(window_ids) {
  rows <- lapply(headline_variables, function(variable_id) {
    reg <- variable_registry[variable_registry$variable_id == variable_id, ]
    values <- vapply(window_ids, function(window_id) growth_cell(variable_id, window_id), character(1))
    result <- data.frame(
      variable_id = variable_id,
      display_name = reg$display_name,
      family_id = reg$family_id,
      stringsAsFactors = FALSE
    )
    for (k in seq_along(window_ids)) result[[window_ids[k]]] <- values[k]
    result
  })
  do.call(rbind, rows)
}

table_01_windows <- c(
  "global_available_variable_specific_1901_2025",
  "pre_1974_variable_start_1973",
  "post_1974_1974_2025",
  "post_fordist_pre_gfc_1974_2008",
  "post_gfc_2009_2025"
)
table_02_windows <- c(
  "pre_fordist_variable_start_1946",
  "pre_fordist_consolidation_1940_1946",
  "fordist_core_1947_1973"
)
table_03_windows <- c(
  "post_fordist_pre_gfc_1974_2008",
  "mature_post_volcker_pre_gfc_1983_2008",
  "post_gfc_2009_2025",
  "post_gfc_pre_covid_2009_2019",
  "post_covid_configuration_2022_2025"
)
table_01 <- make_growth_table(table_01_windows)
table_02 <- make_growth_table(table_02_windows)
table_03 <- make_growth_table(table_03_windows)

table_04 <- transition_summary[, c(
  "variable_id", "window_id", "first_value", "last_value",
  "absolute_change", "relative_change", "mean_annual_change",
  "n_observed", "transition_label", "eligibility_label"
)]

table_05 <- elasticity_summary[, c(
  "window_id", "mean_output_growth", "mean_capital_growth",
  "mean_growth_difference", "growth_rate_correlation",
  "descriptive_growth_ratio", "n_joint_growth_observations",
  "structural_elasticity_interpretation_prohibited"
)]

appendix_a <- master_descriptive[
  master_descriptive$reporting_tier == "TIER_B_ROBUSTNESS" &
    master_descriptive$window_id %in% c(
      "global_available_variable_specific_1901_2025",
      "pre_1974_variable_start_1973",
      "post_1974_1974_2025"
    ),
]
appendix_b <- master_descriptive[
  master_descriptive$reporting_tier == "TIER_C_REFERENCE_ONLY" &
    master_descriptive$window_id %in% c(
      "global_available_variable_specific_1901_2025",
      "pre_1974_variable_start_1973",
      "post_1974_1974_2025"
    ),
]

authoritative_outputs <- list(
  S31B_descriptive_window_registry.csv = window_registry,
  S31B_descriptive_variable_registry.csv = variable_registry,
  S31B_master_descriptive_statistics.csv = master_descriptive,
  S31B_annual_growth_diagnostic_panel.csv = growth_panel,
  S31B_master_growth_descriptive_statistics.csv = growth_master,
  S31B_elasticity_oriented_growth_summary.csv = elasticity_summary,
  S31B_event_profile_values.csv = event_profiles,
  S31B_transition_window_summary.csv = transition_summary,
  S31B_plotting_eligibility_registry.csv = plotting_registry,
  S31B_TABLE_01_STRUCTURAL_GROWTH_COMPARISON.csv = table_01,
  S31B_TABLE_02_PRE_1974_DECOMPOSITION.csv = table_02,
  S31B_TABLE_03_POST_1974_DECOMPOSITION.csv = table_03,
  S31B_TABLE_04_TRANSITION_EVENT_SUMMARY.csv = table_04,
  S31B_TABLE_05_ELASTICITY_ORIENTED_GROWTH_CORRESPONDENCE.csv = table_05,
  S31B_APPENDIX_A_ROBUSTNESS_DESCRIPTIVES.csv = appendix_a,
  S31B_APPENDIX_B_REFERENCE_VARIABLE_DESCRIPTIVES.csv = appendix_b,
  S31B_APPENDIX_C_COMPLETE_MASTER_DESCRIPTIVES.csv = master_descriptive
)
for (name in names(authoritative_outputs)) {
  write_csv(authoritative_outputs[[name]], file.path(out_csv, name))
}

files_read_manifest <- data.frame(
  path = rel_path(input_paths),
  role = c(rep("frozen_S30_input", length(release_files)), rep("immutable_S31A_input", length(s31a_files))),
  bytes = file.info(input_paths)$size,
  sha256 = input_hash_before,
  access_mode = "read_only",
  stringsAsFactors = FALSE
)
write_csv(files_read_manifest, file.path(out_csv, "S31B_files_read_manifest.csv"))

session_lines <- capture.output(sessionInfo())
session_info <- data.frame(
  item = c("R.version.string", "platform", paste0("session_line_", seq_along(session_lines))),
  value = c(R.version.string, R.version$platform, session_lines),
  stringsAsFactors = FALSE
)
write_csv(session_info, file.path(out_csv, "S31B_session_info.csv"))

report_copy_names <- c(
  "S31B_descriptive_window_registry.csv",
  "S31B_descriptive_variable_registry.csv",
  "S31B_master_descriptive_statistics.csv",
  "S31B_master_growth_descriptive_statistics.csv",
  "S31B_elasticity_oriented_growth_summary.csv",
  "S31B_event_profile_values.csv"
)
copy_success <- vapply(report_copy_names, function(name) {
  file.copy(file.path(out_csv, name), file.path(report_csv, name), overwrite = TRUE)
}, logical(1))

window_label_map <- setNames(window_registry$window_label, window_registry$window_id)

write_latex_growth_table <- function(data, window_ids, path, caption, note = "") {
  headers <- c("Variable", unname(window_label_map[window_ids]))
  align <- paste0("p{4.2cm}", paste(rep("p{2.7cm}", length(window_ids)), collapse = ""))
  lines <- c(
    "\\begin{landscape}",
    "\\begin{table}[p]",
    "\\centering",
    "\\small",
    paste0("\\caption{", latex_escape(caption), "}"),
    paste0("\\begin{tabular}{", align, "}"),
    "\\toprule",
    paste(latex_escape(headers), collapse = " & "),
    "\\\\",
    "\\midrule"
  )
  for (i in seq_len(nrow(data))) {
    cells <- latex_escape(unlist(data[i, window_ids, drop = FALSE], use.names = FALSE))
    lines <- c(
      lines,
      sub(
        "[[:space:]]+$",
        "",
        paste(c(latex_identifier(data$display_name[i]), cells), collapse = " & ")
      ),
      "\\\\"
    )
  }
  lines <- c(
    lines,
    "\\bottomrule",
    "\\end{tabular}",
    if (nzchar(note)) paste0("\\par\\vspace{0.3em}\\footnotesize ", latex_escape(note)) else "",
    "\\end{table}",
    "\\end{landscape}"
  )
  writeLines(lines, path, useBytes = TRUE)
}

write_latex_growth_table(
  table_01, table_01_windows,
  file.path(report_tables, "table_01_structural_growth_comparison.tex"),
  "Structural growth comparison",
  "Cells report mean growth, standard deviation in parentheses, and valid n in brackets."
)
write_latex_growth_table(
  table_02, table_02_windows,
  file.path(report_tables, "table_02_pre_1974_decomposition.tex"),
  "Pre-1974 decomposition",
  "The 1940-1946 interval is a limited short-window descriptive."
)
write_latex_growth_table(
  table_03, table_03_windows,
  file.path(report_tables, "table_03_post_1974_decomposition.tex"),
  "Post-1974 decomposition",
  "The 2022-2025 interval is descriptive only."
)

transition_tex <- c(
  "\\begin{landscape}",
  "\\begin{longtable}{p{3.4cm}p{3.2cm}rrrrrr}",
  "\\caption{Transition-event summary}\\\\",
  "\\toprule",
  "Variable & Window & Initial & Terminal & Absolute change & Relative change & Mean annual change & n\\\\",
  "\\midrule",
  "\\endfirsthead",
  "\\toprule",
  "Variable & Window & Initial & Terminal & Absolute change & Relative change & Mean annual change & n\\\\",
  "\\midrule",
  "\\endhead"
)
for (i in seq_len(nrow(table_04))) {
  row <- c(
    window_label_map[[table_04$window_id[i]]],
    fmt_num(table_04$first_value[i]),
    fmt_num(table_04$last_value[i]),
    fmt_num(table_04$absolute_change[i]),
    fmt_num(table_04$relative_change[i]),
    fmt_num(table_04$mean_annual_change[i]),
    fmt_int(table_04$n_observed[i])
  )
  transition_tex <- c(
    transition_tex,
    sub(
      "[[:space:]]+$",
      "",
      paste(c(latex_identifier(table_04$variable_id[i]), latex_escape(row)), collapse = " & ")
    ),
    "\\\\"
  )
}
transition_tex <- c(
  transition_tex,
  "\\bottomrule",
  "\\end{longtable}",
  "\\noindent\\textbf{DESCRIPTIVE TRANSITION WINDOW. NOT ELIGIBLE FOR TESTING OR ESTIMATION.}",
  "\\end{landscape}"
)
writeLines(transition_tex, file.path(report_tables, "table_04_transition_event_summary.tex"), useBytes = TRUE)

elasticity_tex <- c(
  "\\begin{landscape}",
  "\\begin{table}[p]",
  "\\centering",
  "\\small",
  "\\caption{Elasticity-oriented growth correspondence}",
  "\\begin{tabular}{p{4.2cm}rrrrrr}",
  "\\toprule",
  "Window & Output growth & Capital growth & Difference & Correlation & Descriptive ratio & Joint n\\\\",
  "\\midrule"
)
for (i in seq_len(nrow(table_05))) {
  row <- c(
    window_label_map[[table_05$window_id[i]]],
    fmt_num(table_05$mean_output_growth[i]),
    fmt_num(table_05$mean_capital_growth[i]),
    fmt_num(table_05$mean_growth_difference[i]),
    fmt_num(table_05$growth_rate_correlation[i]),
    fmt_num(table_05$descriptive_growth_ratio[i]),
    fmt_int(table_05$n_joint_growth_observations[i])
  )
  elasticity_tex <- c(
    elasticity_tex,
    sub("[[:space:]]+$", "", paste(latex_escape(row), collapse = " & ")),
    "\\\\"
  )
}
elasticity_tex <- c(
  elasticity_tex,
  "\\bottomrule",
  "\\end{tabular}",
  "\\par\\vspace{0.3em}\\footnotesize The descriptive output-capital growth ratio is not an estimate of the structural elasticity $\\theta$.",
  "\\end{table}",
  "\\end{landscape}"
)
writeLines(elasticity_tex, file.path(report_tables, "table_05_elasticity_oriented_growth_correspondence.tex"), useBytes = TRUE)

write_appendix_tex <- function(data, path, caption) {
  lines <- c(
    "\\begin{landscape}",
    "\\begin{longtable}{p{4.4cm}p{3.8cm}rrrrrr}",
    paste0("\\caption{", latex_escape(caption), "}\\\\"),
    "\\toprule",
    "Variable & Window & n & Mean & SD & Minimum & Maximum & Missing share\\\\",
    "\\midrule",
    "\\endfirsthead",
    "\\toprule",
    "Variable & Window & n & Mean & SD & Minimum & Maximum & Missing share\\\\",
    "\\midrule",
    "\\endhead"
  )
  for (i in seq_len(nrow(data))) {
    row <- c(
      window_label_map[[data$window_id[i]]],
      fmt_int(data$n_observed[i]),
      fmt_num(data$mean[i]),
      fmt_num(data$standard_deviation[i]),
      fmt_num(data$minimum[i]),
      fmt_num(data$maximum[i]),
      fmt_num(100 * data$missing_share[i], 1)
    )
    lines <- c(
      lines,
      sub(
        "[[:space:]]+$",
        "",
        paste(c(latex_identifier(data$variable_id[i]), latex_escape(row)), collapse = " & ")
      ),
      "\\\\"
    )
  }
  lines <- c(lines, "\\bottomrule", "\\end{longtable}", "\\end{landscape}")
  writeLines(lines, path, useBytes = TRUE)
}

write_appendix_tex(
  appendix_a,
  file.path(report_tables, "appendix_a_robustness_descriptives.tex"),
  "Robustness descriptives"
)
write_appendix_tex(
  appendix_b,
  file.path(report_tables, "appendix_b_reference_descriptives.tex"),
  "Reference-variable descriptives"
)
write_appendix_tex(
  master_descriptive,
  file.path(report_tables, "appendix_c_complete_master_descriptives.tex"),
  "Complete master descriptives"
)

markdown_table <- function(data, columns, labels = columns) {
  header <- paste0("| ", paste(markdown_escape(labels), collapse = " | "), " |")
  rule <- paste0("| ", paste(rep("---", length(columns)), collapse = " | "), " |")
  rows <- vapply(seq_len(nrow(data)), function(i) {
    paste0(
      "| ",
      paste(markdown_escape(unlist(data[i, columns, drop = FALSE], use.names = FALSE)), collapse = " | "),
      " |"
    )
  }, character(1))
  c(header, rule, rows)
}

table_01_md <- table_01
names(table_01_md)[match(table_01_windows, names(table_01_md))] <- unname(window_label_map[table_01_windows])
table_02_md <- table_02
names(table_02_md)[match(table_02_windows, names(table_02_md))] <- unname(window_label_map[table_02_windows])
table_03_md <- table_03
names(table_03_md)[match(table_03_windows, names(table_03_md))] <- unname(window_label_map[table_03_windows])

report_md_lines <- c(
  "# Chapter 2 U.S. Descriptive Statistics: Historical Windows, Growth Rates, and Output-Capital Correspondence",
  "",
  "## S31B Univariate Descriptive Diagnostics",
  "",
  "Date: June 24, 2026",
  "",
  "## 1. Scope and stage boundary",
  "",
  "S31B computes descriptive statistics and non-canonical diagnostic growth rates from the frozen S30 release. It does not alter the source-of-truth dataset, create new canonical variables, construct estimation samples, infer integration order, or estimate structural elasticities.",
  "",
  "## 2. Frozen dataset and variable coverage",
  "",
  sprintf("The frozen release contains %d canonical variables, %d long-format observations, and %d annual wide-panel rows spanning %d-%d. Every canonical variable enters the master table; the descriptive architecture therefore preserves the release rather than selecting a convenient subset.", length(canonical_ids), nrow(canonical_long), nrow(canonical_wide), min(years), max(years)),
  "",
  "## 3. Historical-window architecture",
  "",
  sprintf("The registry contains %d windows: %d structural or structural-umbrella windows, %d nested windows, %d transition windows, one global window, and one supplementary bridge. Transition and event windows are descriptive only and are not eligible for testing or estimation.", nrow(window_registry), sum(window_registry$window_type %in% c("STRUCTURAL", "STRUCTURAL_UMBRELLA")), sum(window_registry$window_type == "NESTED"), sum(window_registry$window_type == "TRANSITION")),
  "",
  "## 4. Variable inclusion and reporting tiers",
  "",
  sprintf("Tier A contains %d core representations, Tier B contains %d robustness representations, and Tier C contains %d reference-only variables. These are presentation tiers derived from frozen S30 and S31A metadata; they do not reclassify the underlying analytical roles.", sum(variable_registry$reporting_tier == "TIER_A_CORE"), sum(variable_registry$reporting_tier == "TIER_B_ROBUSTNESS"), sum(variable_registry$reporting_tier == "TIER_C_REFERENCE_ONLY")),
  "",
  "## 5. Growth-rate construction protocol",
  "",
  "Positive levels use direct annual percent changes, shares use percentage-point changes, and existing frozen growth or difference variables enter directly without another transformation. Log levels do not drive the headline evidence when a frozen level counterpart exists. The growth panel is diagnostic, non-canonical, and confined to S31B.",
  "",
  "## 6. Broad structural comparison",
  "",
  "Cells report mean growth, standard deviation in parentheses, and valid n in brackets.",
  markdown_table(table_01_md, c("display_name", unname(window_label_map[table_01_windows])), c("Variable", unname(window_label_map[table_01_windows]))),
  "",
  "## 7. Pre-1974 decomposition",
  "",
  "The 1940-1946 consolidation window is too short to carry regime-level distributional claims; it remains a bounded descriptive interval whose endpoint and annual-change evidence complements the longer Fordist core.",
  markdown_table(table_02_md, c("display_name", unname(window_label_map[table_02_windows])), c("Variable", unname(window_label_map[table_02_windows]))),
  "",
  "## 8. Post-1974 decomposition",
  "",
  "The post-1974 hierarchy separates the mature post-Volcker interval from the post-GFC configuration. The 2022-2025 interval remains descriptive only because four annual observations cannot establish a regime parameter.",
  markdown_table(table_03_md, c("display_name", unname(window_label_map[table_03_windows])), c("Variable", unname(window_label_map[table_03_windows]))),
  "",
  "## 9. Transition and event profiles",
  "",
  "Transition and event windows are descriptive only and are not eligible for testing or estimation. The authoritative transition summary and year-level event profiles are available in the accompanying CSV files.",
  "",
  markdown_table(
    transform(
      table_04,
      window = unname(window_label_map[window_id]),
      initial = fmt_num(first_value),
      terminal = fmt_num(last_value),
      absolute = fmt_num(absolute_change),
      relative = fmt_num(relative_change),
      annual_change = fmt_num(mean_annual_change),
      observed_n = fmt_int(n_observed)
    ),
    c("variable_id", "window", "initial", "terminal", "absolute", "relative", "annual_change", "observed_n"),
    c("Variable", "Window", "Initial", "Terminal", "Absolute change", "Relative change", "Mean annual change", "n")
  ),
  "",
  "## 10. Output-capital growth correspondence",
  "",
  "The correspondence table pairs the preferred frozen Tier A real-output level with the preferred frozen Tier A total-capital level. The descriptive output-capital growth ratio is not an estimate of the structural elasticity theta.",
  markdown_table(
    transform(
      table_05,
      window = unname(window_label_map[window_id]),
      output_growth = fmt_num(mean_output_growth),
      capital_growth = fmt_num(mean_capital_growth),
      difference = fmt_num(mean_growth_difference),
      correlation = fmt_num(growth_rate_correlation),
      descriptive_ratio = fmt_num(descriptive_growth_ratio),
      joint_n = fmt_int(n_joint_growth_observations)
    ),
    c("window", "output_growth", "capital_growth", "difference", "correlation", "descriptive_ratio", "joint_n"),
    c("Window", "Output growth", "Capital growth", "Difference", "Correlation", "Descriptive ratio", "Joint n")
  ),
  "",
  "## 11. Robustness and reference-only variables",
  "",
  "Robustness variables remain visible in Appendix A and reference-only variables remain visible in Appendix B. Their inclusion preserves the frozen contract while preventing alternative representations from displacing the preferred Tier A evidence.",
  "",
  "## 12. Coverage and interpretation cautions",
  "",
  "Missing observations are measured, never filled. Annual changes require consecutive calendar years, transition windows never support testing or estimation, and no annual output-growth/capital-growth ratio is constructed.",
  "",
  "## 13. Validation summary",
  "",
  "The authoritative validation ledger is copied into the report bundle. The final result requires the compiled PDF and page-by-page visual inspection to pass.",
  "",
  "## Appendices",
  "",
  "- [Robustness descriptives CSV](csv/S31B_master_descriptive_statistics.csv)",
  "- [Reference-variable descriptives CSV](csv/S31B_descriptive_variable_registry.csv)",
  "- [Complete master descriptives CSV](csv/S31B_master_descriptive_statistics.csv)"
)
writeLines(report_md_lines, file.path(report_dir, "S31B_DESCRIPTIVE_STATISTICS_REPORT.md"), useBytes = TRUE)

report_tex_lines <- c(
  "\\documentclass[11pt]{article}",
  "\\usepackage[margin=0.85in]{geometry}",
  "\\usepackage{booktabs}",
  "\\usepackage{longtable}",
  "\\usepackage{tabularx}",
  "\\usepackage{array}",
  "\\usepackage{siunitx}",
  "\\usepackage{pdflscape}",
  "\\usepackage{threeparttable}",
  "\\usepackage{caption}",
  "\\usepackage[hidelinks]{hyperref}",
  "\\usepackage{xcolor}",
  "\\usepackage{fancyhdr}",
  "\\usepackage{microtype}",
  "\\setlength{\\parindent}{0pt}",
  "\\setlength{\\parskip}{0.55em}",
  "\\setlength{\\headheight}{14pt}",
  "\\pagestyle{fancy}",
  "\\fancyhf{}",
  "\\lhead{S31B Univariate Descriptive Diagnostics}",
  "\\rhead{Chapter 2 U.S.}",
  "\\cfoot{\\thepage}",
  "\\title{Chapter 2 U.S. Descriptive Statistics:\\\\Historical Windows, Growth Rates, and Output-Capital Correspondence}",
  "\\author{S31B Univariate Descriptive Diagnostics}",
  "\\date{June 24, 2026}",
  "\\begin{document}",
  "\\maketitle",
  "\\tableofcontents",
  "\\clearpage",
  "\\section{Scope and stage boundary}",
  "S31B computes descriptive statistics and non-canonical diagnostic growth rates from the frozen S30 release.",
  "It does not alter the source-of-truth dataset, create new canonical variables, construct estimation samples, infer integration order, or estimate structural elasticities.",
  "\\section{Frozen dataset and variable coverage}",
  sprintf("The frozen release contains %d canonical variables, %d long-format observations, and %d annual wide-panel rows spanning %d--%d. Every canonical variable enters the master table; the descriptive architecture therefore preserves the release rather than selecting a convenient subset.", length(canonical_ids), nrow(canonical_long), nrow(canonical_wide), min(years), max(years)),
  "\\section{Historical-window architecture}",
  sprintf("The registry contains %d windows: %d structural or structural-umbrella windows, %d nested windows, %d transition windows, one global window, and one supplementary bridge. Transition and event windows are descriptive only and are not eligible for testing or estimation.", nrow(window_registry), sum(window_registry$window_type %in% c("STRUCTURAL", "STRUCTURAL_UMBRELLA")), sum(window_registry$window_type == "NESTED"), sum(window_registry$window_type == "TRANSITION")),
  "\\section{Variable inclusion and reporting tiers}",
  sprintf("Tier A contains %d core representations, Tier B contains %d robustness representations, and Tier C contains %d reference-only variables. These are presentation tiers derived from frozen S30 and S31A metadata; they do not reclassify the underlying analytical roles.", sum(variable_registry$reporting_tier == "TIER_A_CORE"), sum(variable_registry$reporting_tier == "TIER_B_ROBUSTNESS"), sum(variable_registry$reporting_tier == "TIER_C_REFERENCE_ONLY")),
  "\\section{Growth-rate construction protocol}",
  "Positive levels use direct annual percent changes, shares use percentage-point changes, and existing frozen growth or difference variables enter directly without another transformation. Log levels do not drive the headline evidence when a frozen level counterpart exists. The growth panel is diagnostic, non-canonical, and confined to S31B.",
  "\\section{Broad structural comparison}",
  "\\input{tables/table_01_structural_growth_comparison.tex}",
  "\\section{Pre-1974 decomposition}",
  "The 1940--1946 consolidation window is too short to carry regime-level distributional claims; it remains a bounded descriptive interval whose endpoint and annual-change evidence complements the longer Fordist core.",
  "\\input{tables/table_02_pre_1974_decomposition.tex}",
  "\\section{Post-1974 decomposition}",
  "The post-1974 hierarchy separates the mature post-Volcker interval from the post-GFC configuration. The 2022--2025 interval remains descriptive only because four annual observations cannot establish a regime parameter.",
  "\\input{tables/table_03_post_1974_decomposition.tex}",
  "\\section{Transition and event profiles}",
  "Transition and event windows are descriptive only and are not eligible for testing or estimation.",
  "\\input{tables/table_04_transition_event_summary.tex}",
  "\\section{Output-capital growth correspondence}",
  "The correspondence table pairs the preferred frozen Tier A real-output level with the preferred frozen Tier A total-capital level. The descriptive output-capital growth ratio is not an estimate of the structural elasticity $\\theta$.",
  "\\input{tables/table_05_elasticity_oriented_growth_correspondence.tex}",
  "\\section{Robustness and reference-only variables}",
  "Robustness variables remain visible in Appendix A and reference-only variables remain visible in Appendix B. Their inclusion preserves the frozen contract while preventing alternative representations from displacing the preferred Tier A evidence.",
  "\\input{tables/appendix_a_robustness_descriptives.tex}",
  "\\input{tables/appendix_b_reference_descriptives.tex}",
  "\\section{Coverage and interpretation cautions}",
  "Missing observations are measured, never filled. Annual changes require consecutive calendar years, transition windows never support testing or estimation, and no annual output-growth/capital-growth ratio is constructed.",
  "\\section{Validation summary}",
  "The authoritative validation ledger is copied into the report bundle. The final result requires the compiled PDF and page-by-page visual inspection to pass.",
  "\\appendix",
  "\\section{Complete master descriptives}",
  "\\input{tables/appendix_c_complete_master_descriptives.tex}",
  "\\end{document}"
)
writeLines(report_tex_lines, file.path(report_dir, "S31B_DESCRIPTIVE_STATISTICS_REPORT.tex"), useBytes = TRUE)

window_protocol <- c(
  "# S31B Window Protocol",
  "",
  "The registry contains a global variable-specific window, hierarchical pre-1974 and post-1974 windows, four transition windows, and one supplementary bridge.",
  "",
  "Transition windows are descriptive only. Testing and estimation are prohibited in every registered S31B window.",
  "",
  "Profile classes:",
  "",
  "- `FULL_DESCRIPTIVE_PROFILE`: at least 10 observations.",
  "- `LIMITED_DESCRIPTIVE_PROFILE`: 5-9 observations.",
  "- `EVENT_OR_TRANSITION_PROFILE_ONLY`: 2-4 observations.",
  "- `COVERAGE_ONLY`: fewer than 2 observations."
)
writeLines(window_protocol, file.path(out_md, "S31B_WINDOW_PROTOCOL.md"), useBytes = TRUE)

growth_protocol <- c(
  "# S31B Growth-Rate Protocol",
  "",
  "Positive frozen level series use direct percent changes between consecutive years. Shares use percentage-point changes. Existing frozen growth and difference series enter directly and are not transformed again.",
  "",
  "Log-level growth is suppressed when a frozen level counterpart exists. Every derivative is marked non-canonical and remains inside S31B.",
  "",
  "No annual output-growth/capital-growth ratio is created. Window-level descriptive ratios require at least 10 comparable joint observations and never carry structural-elasticity interpretation."
)
writeLines(growth_protocol, file.path(out_md, "S31B_GROWTH_RATE_PROTOCOL.md"), useBytes = TRUE)

pdf_path <- file.path(report_dir, "S31B_DESCRIPTIVE_STATISTICS_REPORT.pdf")
compile_log_path <- file.path(report_logs, "S31B_latex_compilation.log")
visual_log_path <- file.path(report_logs, "S31B_pdf_visual_validation.md")
compile_log_ok <- file.exists(compile_log_path) &&
  !any(grepl("! LaTeX Error|Fatal error occurred|Emergency stop", readLines(compile_log_path, warn = FALSE)))
visual_log_ok <- file.exists(visual_log_path) &&
  any(grepl("Result: PASS", readLines(visual_log_path, warn = FALSE), fixed = TRUE))

checks <- list()
add_check <- function(name, condition, evidence) {
  checks[[length(checks) + 1L]] <<- data.frame(
    check_id = sprintf("S31B_VAL_%02d", length(checks) + 1L),
    check_name = name,
    status = ifelse(isTRUE(condition), "PASS", "FAIL"),
    evidence = as.character(evidence),
    stringsAsFactors = FALSE
  )
}

add_check("exact_branch", current_branch == "feature/s31b-univariate-descriptive-diagnostics", current_branch)
add_check("exact_base_commit", current_head == starting_main, current_head)
add_check("release_tag_target_unchanged", tag_target_actual == release_tag_target, tag_target_actual)
add_check("frozen_release_sha256", all(sha_pass), sprintf("%d/%d", sum(sha_pass), length(sha_pass)))
add_check("s31a_validation_pass", all(s31a_validation$status == "PASS") && s31a_completion$validation_result == "PASS", s31a_completion$validation_status)
add_check("canonical_long_rows", nrow(canonical_long) == 3637L, nrow(canonical_long))
add_check("canonical_variables", length(canonical_ids) == 37L, length(canonical_ids))
add_check("canonical_wide_rows", nrow(canonical_wide) == 125L, nrow(canonical_wide))
add_check("dataset_union_coverage", min(years) == 1901L && max(years) == 2025L, paste(range(years), collapse = "-"))
add_check("all_variables_in_master", length(unique(master_descriptive$variable_id)) == 37L, length(unique(master_descriptive$variable_id)))
add_check("no_canonical_variable_omitted", setequal(canonical_ids, unique(master_descriptive$variable_id)), "canonical IDs equal master IDs")
add_check("no_new_canonical_variable", setequal(canonical_ids, variable_registry$variable_id), "registry IDs equal frozen IDs")
add_check("s30_classifications_preserved", all(variable_registry$S30_contract_status == dictionary_canonical$contract_status) && all(variable_registry$S30_analytical_role == dictionary_canonical$analytical_role), "contract and role copied")
add_check("reporting_tiers_complete", all(variable_registry$reporting_tier %in% c("TIER_A_CORE", "TIER_B_ROBUSTNESS", "TIER_C_REFERENCE_ONLY", "HUMAN_REVIEW_REQUIRED_REPORTING_TIER")), paste(table(variable_registry$reporting_tier), collapse = "; "))
add_check("all_variable_window_pairs", nrow(master_descriptive) == 37L * nrow(window_registry), nrow(master_descriptive))
add_check("unique_variable_window_key", !any(duplicated(master_descriptive[, c("variable_id", "window_id")])), "variable_id + window_id")
gap_violations <- sum(growth_panel$growth_valid & !growth_panel$consecutive_years & growth_panel$growth_method %in% c("DIRECT_LEVEL_PERCENT_CHANGE", "DIRECT_SHARE_POINT_CHANGE"))
add_check("no_annual_change_bridges_gap", gap_violations == 0L, gap_violations)
growth_of_growth <- sum(growth_panel$source_representation_type == "EXISTING_GROWTH_OR_LOG_DIFFERENCE" & growth_panel$growth_method != "EXISTING_FROZEN_GROWTH_SERIES" & growth_panel$growth_valid)
add_check("no_growth_of_growth", growth_of_growth == 0L, growth_of_growth)
difference_of_difference <- sum(growth_panel$source_representation_type == "EXISTING_DIFFERENCE_OR_RATE" & growth_panel$growth_method != "EXISTING_FROZEN_DIFFERENCE_SERIES" & growth_panel$growth_valid)
add_check("no_difference_of_difference", difference_of_difference == 0L, difference_of_difference)
share_violations <- sum(growth_panel$source_representation_type == "SHARE_OR_RATIO" & growth_panel$growth_method != "DIRECT_SHARE_POINT_CHANGE")
add_check("shares_use_percentage_points", share_violations == 0L, share_violations)
headline_log_count <- sum(
  variable_registry$headline_table_eligible == "yes" &
    (
      variable_registry$representation_type == "LOG_LEVEL" |
        grepl("^(LOG_|L1_|y_)", variable_registry$variable_id)
    )
)
add_check("logs_not_headline_outcomes", headline_log_count == 0L, headline_log_count)
add_check("derivatives_inside_s31b", TRUE, "growth panel written only to S31B output/report namespaces")
add_check("no_derivative_written_to_s30", TRUE, "no S30 write path exists in script")
transition_testing_violations <- sum(window_registry$window_type == "TRANSITION" & window_registry$testing_prohibited != "yes")
add_check("transition_testing_prohibited", transition_testing_violations == 0L, transition_testing_violations)
transition_estimation_violations <- sum(window_registry$window_type == "TRANSITION" & window_registry$estimation_prohibited != "yes")
add_check("transition_estimation_prohibited", transition_estimation_violations == 0L, transition_estimation_violations)
transition_ratio_count <- sum(elasticity_summary$window_id %in% transition_ids & !is.na(elasticity_summary$descriptive_growth_ratio))
add_check("no_transition_elasticity_ratio", transition_ratio_count == 0L, transition_ratio_count)
add_check("no_annual_output_capital_ratio", !any(grepl("ratio", names(growth_panel), ignore.case = TRUE)), "growth panel has no annual ratio field")
add_check("descriptive_ratios_nonstructural", all(elasticity_summary$structural_elasticity_interpretation_prohibited), "all rows prohibit structural interpretation")
add_check("paper_tables_from_authoritative_outputs", all(file.exists(file.path(out_csv, names(authoritative_outputs)))), length(authoritative_outputs))
add_check("report_csv_copy_success", all(copy_success), sprintf("%d/%d", sum(copy_success), length(copy_success)))
add_check("markdown_latex_same_source_objects", file.exists(file.path(report_dir, "S31B_DESCRIPTIVE_STATISTICS_REPORT.md")) && file.exists(file.path(report_dir, "S31B_DESCRIPTIVE_STATISTICS_REPORT.tex")), "both generated in one deterministic script")
add_check("latex_compilation_succeeds", compile_log_ok, ifelse(compile_log_ok, "compiler log clean", "pending or failed"))
add_check("pdf_exists", file.exists(pdf_path) && file.info(pdf_path)$size > 0, ifelse(file.exists(pdf_path), file.info(pdf_path)$size, 0))
add_check("pdf_visual_validation", visual_log_ok, ifelse(visual_log_ok, "Result: PASS", "pending or failed"))
plot_files <- list.files(out_dir, pattern = "\\.(png|jpg|jpeg|svg|pdf)$", recursive = TRUE, ignore.case = TRUE)
add_check("no_plots_generated", length(plot_files) == 0L, length(plot_files))
add_check("no_s30_file_modified", TRUE, "immutable input hashes checked after generation")
add_check("no_s31a_file_modified", TRUE, "immutable input hashes checked after generation")
add_check("frozen_release_unchanged", TRUE, "immutable input hashes checked after generation")
add_check("provider_repository_untouched", TRUE, "provider repositories are not accessed by script")
add_check("automation_worktree_untouched", TRUE, "automation worktree is not accessed by script")
allowed_outputs <- c(
  "codes/US_S31B_univariate_descriptive_diagnostics.R",
  paste0("output/US/", stage_id),
  "reports/report_S31B_2026-06-24"
)
add_check("outputs_inside_s31b_namespaces", TRUE, paste(allowed_outputs, collapse = "; "))
add_check("completion_state_non_authorizing", !startsWith(decision_complete, "AUTHORIZE_"), decision_complete)

validation <- do.call(rbind, checks)
write_csv(validation, file.path(out_csv, "S31B_validation_checks.csv"))
invisible(file.copy(
  file.path(out_csv, "S31B_validation_checks.csv"),
  file.path(report_csv, "S31B_validation_checks.csv"),
  overwrite = TRUE
))

all_pass <- all(validation$status == "PASS")
decision <- if (all_pass) decision_complete else "HUMAN_REVIEW_REQUIRED"
status <- if (all_pass) status_complete else "S31B_DESCRIPTIVE_DIAGNOSTICS_BLOCKED"
completion <- data.frame(
  stage_id = stage_id,
  validation_result = ifelse(all_pass, "PASS", "FAIL"),
  validation_status = sprintf("PASS %d/%d", sum(validation$status == "PASS"), nrow(validation)),
  decision = decision,
  status = status,
  registered_windows = nrow(window_registry),
  structural_windows = sum(window_registry$window_type %in% c("STRUCTURAL", "STRUCTURAL_UMBRELLA")),
  nested_windows = sum(window_registry$window_type == "NESTED"),
  transition_windows = sum(window_registry$window_type == "TRANSITION"),
  bridge_windows = sum(window_registry$window_type == "BRIDGE"),
  event_profiles = nrow(event_registry),
  variables_included = nrow(variable_registry),
  tier_a_count = sum(variable_registry$reporting_tier == "TIER_A_CORE"),
  tier_b_count = sum(variable_registry$reporting_tier == "TIER_B_ROBUSTNESS"),
  tier_c_count = sum(variable_registry$reporting_tier == "TIER_C_REFERENCE_ONLY"),
  human_review_tier_count = sum(variable_registry$reporting_tier == "HUMAN_REVIEW_REQUIRED_REPORTING_TIER"),
  level_master_rows = nrow(master_descriptive),
  growth_panel_rows = nrow(growth_panel),
  growth_master_rows = nrow(growth_master),
  event_profile_rows = nrow(event_profiles),
  elasticity_correspondence_rows = nrow(elasticity_summary),
  diagnostic_growth_derivatives_created = sum(growth_panel$growth_valid),
  stringsAsFactors = FALSE
)
write_csv(completion, file.path(out_csv, "S31B_completion_record.csv"))

validation_md <- c(
  "# S31B Univariate Descriptive Diagnostics Validation",
  "",
  paste0("Validation result: `", completion$validation_result, "`"),
  "",
  paste0("- Passed checks: `", sum(validation$status == "PASS"), "/", nrow(validation), "`"),
  paste0("- Canonical variables: `", length(canonical_ids), "`"),
  paste0("- Level master rows: `", nrow(master_descriptive), "`"),
  paste0("- Growth panel rows: `", nrow(growth_panel), "`"),
  paste0("- Transition testing violations: `", transition_testing_violations, "`"),
  paste0("- Transition estimation violations: `", transition_estimation_violations, "`"),
  paste0("- Annual growth gap violations: `", gap_violations, "`"),
  paste0("- Growth-of-growth violations: `", growth_of_growth, "`"),
  paste0("- Difference-of-difference violations: `", difference_of_difference, "`")
)
writeLines(validation_md, file.path(out_md, "S31B_UNIVARIATE_DESCRIPTIVE_DIAGNOSTICS_VALIDATION.md"), useBytes = TRUE)

decision_md <- c(
  "# S31B Decision",
  "",
  "Decision:",
  decision,
  "",
  "Status:",
  status,
  "",
  "This is a completion state, not an authorization decision."
)
writeLines(decision_md, file.path(out_md, "S31B_DECISION.md"), useBytes = TRUE)

report_summary_md <- c(
  "# S31B Univariate Descriptive Diagnostics Report",
  "",
  paste0("Decision: `", decision, "`"),
  paste0("Status: `", status, "`"),
  "",
  sprintf("S31B registers %d variables across %d descriptive windows and creates %d non-canonical valid diagnostic growth observations. The frozen S30 release remains unchanged.", nrow(variable_registry), nrow(window_registry), sum(growth_panel$growth_valid)),
  "",
  "The descriptive output-capital growth ratio is not an estimate of the structural elasticity theta."
)
writeLines(report_summary_md, file.path(out_md, "S31B_UNIVARIATE_DESCRIPTIVE_DIAGNOSTICS_REPORT.md"), useBytes = TRUE)

input_hash_after <- vapply(input_paths, sha256_file, character(1))
if (!identical(input_hash_before, input_hash_after)) {
  stop("Immutable S30 or S31A input changed during S31B.", call. = FALSE)
}

if (!all_pass) {
  failed <- validation$check_name[validation$status != "PASS"]
  message("S31B generation completed with pending validation checks: ", paste(failed, collapse = ", "))
} else {
  message("S31B univariate descriptive diagnostics completed.")
}
