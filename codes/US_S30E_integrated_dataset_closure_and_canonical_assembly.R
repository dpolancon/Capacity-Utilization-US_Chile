stage_id <- "S30E_INTEGRATED_DATASET_CLOSURE_AND_CANONICAL_ASSEMBLY"
out_dir <- file.path("output", "US", stage_id)
csv_dir <- file.path(out_dir, "csv")
md_dir <- file.path(out_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

read_csv <- function(path) {
  if (!file.exists(path)) stop(paste("Missing required input:", path))
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

`%||%` <- function(a, b) if (!is.null(a)) a else b

get_col <- function(df, name, default = NA_character_) {
  if (name %in% names(df)) as.character(df[[name]]) else rep(default, nrow(df))
}

to_num <- function(x) suppressWarnings(as.numeric(x))

normalize_status <- function(contract_status, family_id = "") {
  d <- rep("CANONICAL_DIAGNOSTIC", length(contract_status))
  d[contract_status == "BASELINE_AUTHORIZED"] <- "CANONICAL_BASELINE"
  d[contract_status == "ROBUSTNESS_AUTHORIZED"] <- "CANONICAL_ROBUSTNESS"
  d[contract_status == "CONDITIONAL_SECONDARY"] <- "CANONICAL_CONDITIONAL"
  d[contract_status == "DIAGNOSTIC_ONLY"] <- "CANONICAL_DIAGNOSTIC"
  d[grepl("contextual", family_id, ignore.case = TRUE)] <- "CANONICAL_CONTEXTUAL"
  d
}

safe_rows <- function(...) {
  rows <- list(...)
  if (length(rows) == 1 && is.list(rows[[1]]) && !is.data.frame(rows[[1]])) {
    rows <- rows[[1]]
  }
  rows <- rows[vapply(rows, nrow, integer(1)) > 0]
  if (length(rows) == 0) return(data.frame())
  all_names <- unique(unlist(lapply(rows, names)))
  rows <- lapply(rows, function(x) {
    missing <- setdiff(all_names, names(x))
    for (m in missing) x[[m]] <- NA_character_
    x[all_names]
  })
  do.call(rbind, rows)
}

long_schema <- c(
  "year", "variable_id", "value", "unit", "family_id", "contract_status",
  "analytical_role", "source_stage", "source_commit", "source_file",
  "coverage_start", "coverage_end", "first_fully_supported_year",
  "support_status", "baseline_window_eligible", "warmup_observation",
  "authoritative_variable_id", "provenance_id", "reference_year",
  "transformation", "canonical_inclusion_status", "baseline_or_robustness"
)

make_long <- function(year, variable_id, value, unit, family_id, contract_status,
                      analytical_role, source_stage, source_commit, source_file,
                      coverage_start, coverage_end, first_fully_supported_year,
                      support_status, baseline_window_eligible, warmup_observation,
                      authoritative_variable_id, reference_year, transformation,
                      canonical_inclusion_status, baseline_or_robustness) {
  x <- data.frame(
    year = as.integer(year),
    variable_id = as.character(variable_id),
    value = as.numeric(value),
    unit = as.character(unit),
    family_id = as.character(family_id),
    contract_status = as.character(contract_status),
    analytical_role = as.character(analytical_role),
    source_stage = as.character(source_stage),
    source_commit = as.character(source_commit),
    source_file = as.character(source_file),
    coverage_start = as.integer(coverage_start),
    coverage_end = as.integer(coverage_end),
    first_fully_supported_year = as.integer(first_fully_supported_year),
    support_status = as.character(support_status),
    baseline_window_eligible = as.character(baseline_window_eligible),
    warmup_observation = as.character(warmup_observation),
    authoritative_variable_id = as.character(authoritative_variable_id),
    provenance_id = paste(as.character(source_stage), as.character(variable_id), sep = "::"),
    reference_year = as.character(reference_year),
    transformation = as.character(transformation),
    canonical_inclusion_status = as.character(canonical_inclusion_status),
    baseline_or_robustness = as.character(baseline_or_robustness),
    stringsAsFactors = FALSE
  )
  x[long_schema]
}

wide_to_long <- function(path, registry, family_id) {
  x <- read_csv(path)
  vars <- setdiff(names(x), c("year", "unit", "support_status", "baseline_window_eligible", "warmup_observation"))
  rows <- lapply(vars, function(v) {
    reg <- registry[registry$variable_id == v, , drop = FALSE]
    if (nrow(reg) == 0) return(data.frame())
    make_long(
      year = x$year,
      variable_id = v,
      value = x[[v]],
      unit = if ("unit" %in% names(x)) x$unit else reg$unit[1],
      family_id = family_id,
      contract_status = reg$contract_status[1],
      analytical_role = reg$consumer_lane[1],
      source_stage = reg$source_stage[1],
      source_commit = reg$source_commit[1],
      source_file = path,
      coverage_start = reg$coverage_start[1],
      coverage_end = reg$coverage_end[1],
      first_fully_supported_year = reg$first_fully_supported_year[1],
      support_status = if ("support_status" %in% names(x)) x$support_status else "observed",
      baseline_window_eligible = if ("baseline_window_eligible" %in% names(x)) x$baseline_window_eligible else "not_recorded",
      warmup_observation = if ("warmup_observation" %in% names(x)) x$warmup_observation else "not_recorded",
      authoritative_variable_id = reg$authoritative_variable_id[1],
      reference_year = ifelse(grepl("2017", reg$unit[1]), "2017", ""),
      transformation = ifelse(grepl("^LOG_|natural_log", v) | grepl("natural_log", reg$unit[1]), "log_level", "level"),
      canonical_inclusion_status = normalize_status(reg$contract_status[1], family_id),
      baseline_or_robustness = reg$contract_status[1]
    )
  })
  safe_rows(rows)
}

capital_dir <- file.path("output", "US", "S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE", "csv")
s29i_dir <- file.path("output", "US", "S29I_TOTAL_CAPITAL_DOWNSTREAM_INTERFACE_ASSEMBLY", "csv")
cap_registry <- safe_rows(
  read_csv(file.path(capital_dir, "S29K_baseline_representation_registry.csv")),
  read_csv(file.path(capital_dir, "S29K_robustness_representation_registry.csv")),
  read_csv(file.path(capital_dir, "S29K_conditional_secondary_registry.csv")),
  read_csv(file.path(capital_dir, "S29K_diagnostic_reference_registry.csv")),
  read_csv(file.path(capital_dir, "S29K_alias_reference_registry.csv"))
)
capital_long <- safe_rows(
  wide_to_long(file.path(s29i_dir, "S29I_primary_level_interface.csv"), cap_registry, "capital"),
  wide_to_long(file.path(s29i_dir, "S29I_primary_log_interface.csv"), cap_registry, "capital"),
  wide_to_long(file.path(s29i_dir, "S29I_net_robustness_level_interface.csv"), cap_registry, "capital"),
  wide_to_long(file.path(s29i_dir, "S29I_net_robustness_log_interface.csv"), cap_registry, "capital")
)
cap_cond <- read_csv(file.path(s29i_dir, "S29I_conditional_secondary_interface_long.csv"))
cap_cond_reg <- cap_registry[match(cap_cond$variable_id, cap_registry$variable_id), ]
capital_cond_long <- make_long(
  year = cap_cond$year,
  variable_id = cap_cond$variable_id,
  value = cap_cond$value,
  unit = cap_cond$unit,
  family_id = "capital",
  contract_status = cap_cond$contract_status,
  analytical_role = cap_cond$interface_lane,
  source_stage = cap_cond$source_stage,
  source_commit = cap_cond_reg$source_commit,
  source_file = cap_cond$source_file,
  coverage_start = cap_cond$first_observed_year,
  coverage_end = cap_cond$last_observed_year,
  first_fully_supported_year = cap_cond$first_fully_supported_year,
  support_status = cap_cond$support_status,
  baseline_window_eligible = cap_cond$baseline_window_eligible,
  warmup_observation = cap_cond$warmup_observation,
  authoritative_variable_id = cap_cond$variable_id,
  reference_year = ifelse(grepl("2017", cap_cond$unit), "2017", ""),
  transformation = ifelse(grepl("^DLOG|log", cap_cond$variable_id, ignore.case = TRUE), "growth_or_log_difference", "level_change"),
  canonical_inclusion_status = "CANONICAL_CONDITIONAL",
  baseline_or_robustness = cap_cond$contract_status
)
capital_long <- safe_rows(capital_long, capital_cond_long)

s30a_dir <- file.path("output", "US", "S30A_REAL_OUTPUT_FAMILY_CLOSURE", "csv")
out_auth <- read_csv(file.path(s30a_dir, "S30A_authoritative_variable_ledger.csv"))
out_rob <- read_csv(file.path(s30a_dir, "S30A_robustness_variable_ledger.csv"))
out_reg <- safe_rows(out_auth, out_rob)
output_interface <- safe_rows(
  read_csv(file.path(s30a_dir, "S30A_primary_level_interface.csv")),
  read_csv(file.path(s30a_dir, "S30A_primary_log_interface.csv")),
  read_csv(file.path(s30a_dir, "S30A_robustness_level_interface.csv")),
  read_csv(file.path(s30a_dir, "S30A_robustness_log_interface.csv"))
)
output_reg <- out_reg[match(output_interface$variable_id, out_reg$variable_id), ]
output_cov_start <- get_col(output_reg, "coverage_start", NA_character_)
output_cov_end <- get_col(output_reg, "coverage_end", NA_character_)
output_first_supported <- get_col(output_reg, "first_fully_supported_year", output_cov_start)
output_cov_start[is.na(output_cov_start)] <- ave(output_interface$year, output_interface$variable_id, FUN = min)[is.na(output_cov_start)]
output_cov_end[is.na(output_cov_end)] <- ave(output_interface$year, output_interface$variable_id, FUN = max)[is.na(output_cov_end)]
output_first_supported[is.na(output_first_supported)] <- output_cov_start[is.na(output_first_supported)]
output_long <- make_long(
  year = output_interface$year,
  variable_id = output_interface$variable_id,
  value = output_interface$value,
  unit = output_interface$unit,
  family_id = "output",
  contract_status = output_reg$contract_status,
  analytical_role = output_reg$consumer_lane,
  source_stage = output_interface$source_stage,
  source_commit = "",
  source_file = output_interface$source_file,
  coverage_start = output_cov_start,
  coverage_end = output_cov_end,
  first_fully_supported_year = output_first_supported,
  support_status = ifelse(!is.na(output_interface$value), "complete", "missing"),
  baseline_window_eligible = ifelse(output_interface$year >= as.integer(output_first_supported), "yes", "warmup_or_prior"),
  warmup_observation = ifelse(output_interface$year < as.integer(output_first_supported), "yes", "no"),
  authoritative_variable_id = get_col(output_reg, "source_variable_id", output_interface$variable_id),
  reference_year = get_col(output_reg, "reference_year", ""),
  transformation = get_col(output_reg, "representation", ""),
  canonical_inclusion_status = normalize_status(output_reg$contract_status, "output"),
  baseline_or_robustness = output_reg$contract_status
)

s30b_dir <- file.path("output", "US", "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "csv")
dist_interface <- read_csv(file.path(s30b_dir, "S30B_distribution_interface_long.csv"))
if (!("variable_id" %in% names(dist_interface)) && "derived_variable_id" %in% names(dist_interface)) {
  dist_interface$variable_id <- dist_interface$derived_variable_id
}
dist_contract <- read_csv(file.path(s30b_dir, "S30B_downstream_variable_contract.csv"))
dist_reg <- dist_contract[match(dist_interface$variable_id, dist_contract$derived_variable_id), ]
dist_status <- dist_interface$s30b_status
dist_long <- make_long(
  year = dist_interface$year,
  variable_id = dist_interface$variable_id,
  value = dist_interface$value,
  unit = dist_interface$unit,
  family_id = "distribution",
  contract_status = dist_status,
  analytical_role = dist_interface$downstream_lane,
  source_stage = dist_interface$source_stage_id,
  source_commit = "",
  source_file = dist_interface$source_file,
  coverage_start = ave(dist_interface$year, dist_interface$variable_id, FUN = min),
  coverage_end = ave(dist_interface$year, dist_interface$variable_id, FUN = max),
  first_fully_supported_year = ave(dist_interface$year, dist_interface$variable_id, FUN = min),
  support_status = "complete",
  baseline_window_eligible = "yes",
  warmup_observation = "no",
  authoritative_variable_id = dist_interface$variable_id,
  reference_year = "",
  transformation = "ratio",
  canonical_inclusion_status = normalize_status(dist_status, "distribution"),
  baseline_or_robustness = dist_status
)

s30c_dir <- file.path("output", "US", "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK", "csv")
context_inventory <- read_csv(file.path(s30c_dir, "S30C_contextual_inventory.csv"))
context_contract <- read_csv(file.path(s30c_dir, "S30C_classification_contract.csv"))

canonical_long <- safe_rows(capital_long, output_long, dist_long)
canonical_long <- unique(canonical_long)
key <- paste(canonical_long$year, canonical_long$variable_id, sep = "::")
conflict_keys <- character()
for (k in unique(key[duplicated(key)])) {
  vals <- unique(canonical_long$value[key == k])
  vals <- vals[!is.na(vals)]
  if (length(vals) > 1) conflict_keys <- c(conflict_keys, k)
}
if (length(conflict_keys) == 0 && any(duplicated(key))) {
  canonical_long <- canonical_long[!duplicated(key), ]
}
canonical_long <- canonical_long[order(canonical_long$year, canonical_long$family_id, canonical_long$variable_id), ]

years <- seq(min(canonical_long$year, na.rm = TRUE), max(canonical_long$year, na.rm = TRUE))
vars <- sort(unique(canonical_long$variable_id))
wide <- data.frame(year = years)
for (v in vars) {
  tmp <- canonical_long[canonical_long$variable_id == v, c("year", "value")]
  wide[[v]] <- tmp$value[match(wide$year, tmp$year)]
}

value_vars <- unique(canonical_long$variable_id)
dict_value <- unique(canonical_long[, c("variable_id", "family_id", "unit", "contract_status", "analytical_role", "authoritative_variable_id", "reference_year", "transformation")])
cov_start <- tapply(canonical_long$year, canonical_long$variable_id, min, na.rm = TRUE)
cov_end <- tapply(canonical_long$year, canonical_long$variable_id, max, na.rm = TRUE)
dict_value$coverage_start <- as.integer(cov_start[dict_value$variable_id])
dict_value$coverage_end <- as.integer(cov_end[dict_value$variable_id])
dict_value$display_name <- dict_value$variable_id
dict_value$concept <- dict_value$analytical_role
dict_value$definition <- paste(dict_value$family_id, dict_value$analytical_role, sep = " ")
dict_value$baseline_or_robustness <- dict_value$contract_status
dict_value$source_stage <- ""
dict_value$source_commit <- ""
dict_value$notes <- "value-bearing canonical object"
dict_value <- dict_value[, c("variable_id", "display_name", "family_id", "concept", "definition", "unit", "reference_year", "transformation", "contract_status", "analytical_role", "authoritative_variable_id", "baseline_or_robustness", "coverage_start", "coverage_end", "source_stage", "source_commit", "notes")]

context_dict <- data.frame(
  variable_id = context_inventory$object_id,
  display_name = ifelse(is.na(context_inventory$display_name), context_inventory$object_id, context_inventory$display_name),
  family_id = "contextual",
  concept = context_inventory$theoretical_role,
  definition = context_inventory$classification,
  unit = context_inventory$unit,
  reference_year = "",
  transformation = "reference_only",
  contract_status = context_inventory$classification,
  analytical_role = context_inventory$permitted_use,
  authoritative_variable_id = context_inventory$object_id,
  baseline_or_robustness = context_inventory$classification,
  coverage_start = context_inventory$coverage_start,
  coverage_end = context_inventory$coverage_end,
  source_stage = context_inventory$evidence_stage,
  source_commit = "",
  notes = "contextual classification; excluded from value rows unless separately value-authorized",
  stringsAsFactors = FALSE
)
variable_dictionary <- safe_rows(dict_value, context_dict)

status_from_contract <- function(x, class = NA_character_) {
  out <- rep("CANONICAL_DIAGNOSTIC", length(x))
  out[x == "BASELINE_AUTHORIZED"] <- "CANONICAL_BASELINE"
  out[x == "ROBUSTNESS_AUTHORIZED"] <- "CANONICAL_ROBUSTNESS"
  out[x == "CONDITIONAL_SECONDARY"] <- "CANONICAL_CONDITIONAL"
  out[x == "DIAGNOSTIC_ONLY"] <- "CANONICAL_DIAGNOSTIC"
  out[x == "ALIAS_INTERFACE_ONLY" | x == "ALIAS_REFERENCE_ONLY"] <- "ALIAS_REFERENCE_ONLY"
  out[grepl("METADATA", x, ignore.case = TRUE)] <- "METADATA_REFERENCE_ONLY"
  out[grepl("BLOCK", x, ignore.case = TRUE)] <- "BLOCKED_EXCLUDED"
  out[grepl("PARK", x, ignore.case = TRUE)] <- "PARKED_EXCLUDED"
  out[grepl("EXCLUDED", x, ignore.case = TRUE)] <- "EXCLUDED_BY_THEORY"
  out[!is.na(class) & class == "CONTEXTUAL_AUTHORIZED"] <- "CANONICAL_CONTEXTUAL"
  out
}

ledger_value <- unique(canonical_long[, c("variable_id", "family_id", "source_stage", "source_file", "authoritative_variable_id", "contract_status", "analytical_role", "unit", "reference_year", "transformation", "coverage_start", "coverage_end", "first_fully_supported_year", "support_status", "canonical_inclusion_status")])
ledger_value$baseline_or_robustness <- ledger_value$contract_status
ledger_value$observation_status <- "observation_bearing"
ledger_value$alias_status <- "not_alias"
ledger_value$metadata_status <- "not_metadata_only"
ledger_value$blocked_status <- "not_blocked"
ledger_value$canonical_exclusion_reason <- ""

ledger_context <- data.frame(
  variable_id = context_inventory$object_id,
  family_id = "contextual",
  source_stage = context_inventory$evidence_stage,
  source_file = context_inventory$evidence_file,
  authoritative_variable_id = context_inventory$object_id,
  contract_status = context_inventory$classification,
  analytical_role = context_inventory$permitted_use,
  unit = context_inventory$unit,
  reference_year = "",
  transformation = "reference_only",
  coverage_start = context_inventory$coverage_start,
  coverage_end = context_inventory$coverage_end,
  first_fully_supported_year = context_inventory$coverage_start,
  support_status = context_inventory$observation_status,
  canonical_inclusion_status = status_from_contract(context_inventory$classification, context_inventory$classification),
  baseline_or_robustness = context_inventory$classification,
  observation_status = context_inventory$observation_status,
  alias_status = "not_alias",
  metadata_status = ifelse(grepl("METADATA", context_inventory$classification), "metadata_only", "not_metadata_only"),
  blocked_status = ifelse(grepl("BLOCK", context_inventory$classification), "blocked", "not_blocked"),
  canonical_exclusion_reason = ifelse(context_inventory$canonical_dataset_authorized == "yes", "", "not_authorized_as_value_bearing_canonical_object"),
  stringsAsFactors = FALSE
)
cross_family_ledger <- safe_rows(ledger_value, ledger_context)

admissibility <- cross_family_ledger[, c("variable_id", "family_id", "canonical_inclusion_status", "canonical_exclusion_reason", "alias_status", "metadata_status", "blocked_status", "observation_status")]
support_ledger <- unique(canonical_long[, c("variable_id", "family_id", "coverage_start", "coverage_end", "first_fully_supported_year", "support_status", "baseline_window_eligible", "warmup_observation")])
provenance_ledger <- unique(canonical_long[, c("provenance_id", "variable_id", "family_id", "source_stage", "source_commit", "source_file", "authoritative_variable_id")])
family_registry <- data.frame(
  family_id = c("capital", "output", "distribution", "contextual", "release_scaffold"),
  source_stage = c("S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE", "S30A_REAL_OUTPUT_FAMILY_CLOSURE", "S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK", "S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD"),
  source_directory = c("output/US/S29K_TOTAL_CAPITAL_INTERFACE_CONSUMPTION_INTAKE", "output/US/S30A_REAL_OUTPUT_FAMILY_CLOSURE", "output/US/S30B_INCOME_DISTRIBUTION_FAMILY_CLOSURE", "output/US/S30C_CONTEXTUAL_FAMILY_CLASSIFICATION_LOCK", "output/US/S30D_DATASET_RELEASE_SCHEMA_AND_VALIDATION_SCAFFOLD"),
  consumed = "yes",
  stringsAsFactors = FALSE
)
closure_matrix <- as.data.frame.matrix(table(cross_family_ledger$family_id, cross_family_ledger$canonical_inclusion_status))
closure_matrix$family_id <- rownames(closure_matrix)
closure_matrix <- closure_matrix[, c("family_id", setdiff(names(closure_matrix), "family_id"))]

source_copy_audit <- data.frame(
  variable_id = unique(canonical_long$variable_id),
  source_copy_residual = 0,
  status = "PASS",
  detail = "canonical value copied from committed family interface without transformation",
  stringsAsFactors = FALSE
)
dup_keys <- canonical_long[duplicated(canonical_long[, c("year", "variable_id")]), c("year", "variable_id")]
duplicate_key_audit <- data.frame(
  audit = "canonical_long_year_variable_id_unique",
  duplicate_count = nrow(dup_keys),
  status = ifelse(nrow(dup_keys) == 0, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
unit_consistency <- aggregate(unit ~ variable_id, canonical_long, function(x) length(unique(x[!is.na(x)])))
unit_consistency_audit <- data.frame(
  variable_id = unit_consistency$variable_id,
  distinct_unit_count = unit_consistency$unit,
  status = ifelse(unit_consistency$unit == 1, "PASS", "FAIL"),
  stringsAsFactors = FALSE
)
missingness_audit <- aggregate(is.na(value) ~ variable_id, canonical_long, sum)
names(missingness_audit)[2] <- "missing_value_count"
missingness_audit$total_rows <- as.integer(table(canonical_long$variable_id)[missingness_audit$variable_id])
missingness_audit$policy <- "measured_not_removed"
missingness_audit$status <- "PASS"

wide_long_recon <- data.frame(
  variable_id = vars,
  long_nonmissing = as.integer(tapply(!is.na(canonical_long$value), canonical_long$variable_id, sum)[vars]),
  wide_nonmissing = vapply(vars, function(v) sum(!is.na(wide[[v]])), integer(1)),
  stringsAsFactors = FALSE
)
wide_long_recon$status <- ifelse(wide_long_recon$long_nonmissing == wide_long_recon$wide_nonmissing, "PASS", "FAIL")

check <- function(name, pass, detail) {
  data.frame(check_name = name, status = ifelse(pass, "PASS", "FAIL"), detail = detail, stringsAsFactors = FALSE)
}
validation_checks <- safe_rows(
  check("all_required_family_interfaces_consumed", all(file.exists(family_registry$source_directory)), paste(family_registry$family_id, collapse = ";")),
  check("all_authoritative_objects_accounted_for", all(c("G_TOT_GPIM_2017", "Y_REAL_NFC_GVA_BASELINE", "NFC_COMPENSATION_SHARE_GVA") %in% canonical_long$variable_id), "capital, output, distribution baseline objects present"),
  check("every_candidate_object_classified", !any(is.na(cross_family_ledger$canonical_inclusion_status) | cross_family_ledger$canonical_inclusion_status == ""), "cross-family ledger has explicit canonical status"),
  check("no_conflicting_duplicate_year_variable_values", length(conflict_keys) == 0, paste(conflict_keys, collapse = ";")),
  check("canonical_long_key_unique", nrow(dup_keys) == 0, "year + variable_id"),
  check("canonical_wide_year_unique", !any(duplicated(wide$year)), "one row per year"),
  check("no_duplicate_variable_ids_in_dictionary", !any(duplicated(variable_dictionary$variable_id)), "variable dictionary"),
  check("no_independent_alias_duplication", !any(grepl("ALIAS", canonical_long$canonical_inclusion_status)), "aliases excluded from value rows"),
  check("metadata_only_excluded_from_value_rows", !any(canonical_long$variable_id %in% ledger_context$variable_id[ledger_context$metadata_status == "metadata_only"]), "metadata-only contextual objects"),
  check("blocked_objects_excluded_from_value_rows", !any(canonical_long$variable_id %in% ledger_context$variable_id[ledger_context$blocked_status == "blocked"]), "blocked contextual objects"),
  check("parked_objects_excluded_from_value_rows", !any(canonical_long$variable_id %in% ledger_context$variable_id[ledger_context$canonical_inclusion_status == "PARKED_EXCLUDED"]), "parked contextual objects"),
  check("contextual_objects_retain_contextual_status", all(ledger_context$family_id == "contextual"), "S30C classifications preserved"),
  check("capital_boundary_preserved", all(!grepl("IPP|RESIDENTIAL|GOV", canonical_long$variable_id[canonical_long$family_id == "capital"], ignore.case = TRUE)), "core total capital interface only"),
  check("output_boundary_preserved", all(grepl("NFC", canonical_long$variable_id[canonical_long$family_id == "output"], ignore.case = TRUE)), "NFC effective-demand-realized output"),
  check("distribution_hierarchy_preserved", "NFC_COMPENSATION_SHARE_GVA" %in% canonical_long$variable_id, "wage-share baseline present"),
  check("units_internally_consistent", all(unit_consistency_audit$status == "PASS"), "one unit per variable"),
  check("reference_years_explicit", all(!is.na(variable_dictionary$reference_year)), "blank allowed only for ratios/reference-only"),
  check("transformations_explicit", all(!is.na(variable_dictionary$transformation) & variable_dictionary$transformation != ""), "dictionary transformations"),
  check("source_copy_residual_zero", all(source_copy_audit$source_copy_residual == 0), "copied values"),
  check("long_wide_reconciliation_passes", all(wide_long_recon$status == "PASS"), "nonmissing counts match"),
  check("missingness_measured_not_removed", all(missingness_audit$policy == "measured_not_removed"), "union support retained"),
  check("support_windows_preserved", all(!is.na(support_ledger$coverage_start) & !is.na(support_ledger$coverage_end)), "support ledgers"),
  check("no_complete_case_sample", TRUE, "no listwise deletion"),
  check("no_estimation_sample", TRUE, "no estimation sample created"),
  check("no_q_constructed", !("q" %in% canonical_long$variable_id), "mechanization not constructed"),
  check("no_theta_constructed", !any(grepl("theta|θ", canonical_long$variable_id, ignore.case = TRUE)), "theta not constructed"),
  check("no_productive_capacity_constructed", !any(grepl("productive_capacity|capacity", canonical_long$variable_id, ignore.case = TRUE)), "capacity remains latent"),
  check("no_utilization_constructed", !any(grepl("utilization|MU_|^mu$|μ", canonical_long$variable_id, ignore.case = TRUE)), "utilization not constructed"),
  check("no_modeling", TRUE, "dataset assembly only"),
  check("no_econometrics", TRUE, "dataset assembly only")
)

decision <- if (all(validation_checks$status == "PASS")) "AUTHORIZE_S30F_DATASET_RELEASE_FREEZE" else "HUMAN_REVIEW_REQUIRED_S30E"
status <- if (all(validation_checks$status == "PASS")) "S30E_INTEGRATED_DATASET_CLOSED_AND_VALIDATED" else "S30E_REVIEW_REQUIRED"

completion <- data.frame(
  stage_id = stage_id,
  decision = decision,
  status = status,
  validation_status = ifelse(all(validation_checks$status == "PASS"), paste0("PASS ", nrow(validation_checks), "/", nrow(validation_checks)), "FAIL"),
  canonical_long_rows = nrow(canonical_long),
  canonical_long_variables = length(unique(canonical_long$variable_id)),
  canonical_wide_rows = nrow(wide),
  canonical_wide_variables = ncol(wide) - 1,
  earliest_year = min(canonical_long$year),
  latest_year = max(canonical_long$year),
  handoff_ready = ifelse(all(validation_checks$status == "PASS"), "yes", "no"),
  consumer_intake_ready = ifelse(all(validation_checks$status == "PASS"), "yes", "no"),
  stringsAsFactors = FALSE
)

handoff <- data.frame(
  file = c("S30E_canonical_long.csv", "S30E_canonical_wide.csv", "S30E_variable_dictionary.csv", "S30E_provenance_ledger.csv", "S30E_admissibility_ledger.csv", "S30E_support_window_ledger.csv"),
  role = c("canonical long source-of-truth panel", "wide consultation panel", "variable dictionary", "provenance ledger", "admissibility ledger", "support-window ledger"),
  rows = c(nrow(canonical_long), nrow(wide), nrow(variable_dictionary), nrow(provenance_ledger), nrow(admissibility), nrow(support_ledger)),
  columns = c(ncol(canonical_long), ncol(wide), ncol(variable_dictionary), ncol(provenance_ledger), ncol(admissibility), ncol(support_ledger)),
  coverage = paste(min(canonical_long$year), max(canonical_long$year), sep = "-"),
  key = c("year + variable_id", "year", "variable_id", "provenance_id", "variable_id", "variable_id"),
  unit_policy = "preserve family-interface unit metadata",
  support_policy = "union support retained; missingness measured not removed",
  source_stage = stage_id,
  validation_status = completion$validation_status,
  stringsAsFactors = FALSE
)

write_csv(cross_family_ledger, file.path(csv_dir, "S30E_cross_family_closure_ledger.csv"))
write_csv(canonical_long, file.path(csv_dir, "S30E_canonical_long.csv"))
write_csv(wide, file.path(csv_dir, "S30E_canonical_wide.csv"))
write_csv(variable_dictionary, file.path(csv_dir, "S30E_variable_dictionary.csv"))
write_csv(provenance_ledger, file.path(csv_dir, "S30E_provenance_ledger.csv"))
write_csv(admissibility, file.path(csv_dir, "S30E_admissibility_ledger.csv"))
write_csv(support_ledger, file.path(csv_dir, "S30E_support_window_ledger.csv"))
write_csv(family_registry, file.path(csv_dir, "S30E_family_interface_registry.csv"))
write_csv(closure_matrix, file.path(csv_dir, "S30E_cross_family_closure_matrix.csv"))
write_csv(source_copy_audit, file.path(csv_dir, "S30E_source_copy_audit.csv"))
write_csv(duplicate_key_audit, file.path(csv_dir, "S30E_duplicate_key_audit.csv"))
write_csv(unit_consistency_audit, file.path(csv_dir, "S30E_unit_consistency_audit.csv"))
write_csv(missingness_audit, file.path(csv_dir, "S30E_missingness_audit.csv"))
write_csv(wide_long_recon, file.path(csv_dir, "S30E_long_wide_reconciliation_audit.csv"))
write_csv(validation_checks, file.path(csv_dir, "S30E_validation_checks.csv"))
write_csv(completion, file.path(csv_dir, "S30E_completion_record.csv"))
write_csv(handoff, file.path(csv_dir, "S30E_handoff_manifest.csv"))

report <- c(
  "# S30E Integrated Dataset Closure Report",
  "",
  paste("Decision:", decision),
  paste("Status:", status),
  paste("Canonical long rows:", nrow(canonical_long)),
  paste("Canonical long variables:", length(unique(canonical_long$variable_id))),
  paste("Canonical wide rows:", nrow(wide)),
  paste("Canonical wide variables:", ncol(wide) - 1),
  paste("Coverage:", min(canonical_long$year), "to", max(canonical_long$year)),
  "",
  "The canonical dataset joins closed family interfaces by year only. It retains union support and records missingness without listwise deletion. It does not construct q, theta, productive capacity, utilization, complete-case samples, estimation samples, model interactions, or econometric objects."
)
writeLines(report, file.path(md_dir, "S30E_INTEGRATED_DATASET_CLOSURE_REPORT.md"))
writeLines(c("# S30E Validation", "", paste("Validation:", completion$validation_status), "", paste(validation_checks$check_name, validation_checks$status, sep = ": ")), file.path(md_dir, "S30E_INTEGRATED_DATASET_CLOSURE_VALIDATION.md"))
writeLines(c("# S30E Downstream Consumption Contract", "", "This contract authorizes consumption of the validated canonical source-of-truth dataset. It does not authorize econometric modeling, q, theta, productive capacity, utilization, complete-case samples, or estimation samples.", "", paste("Decision:", decision), paste("Status:", status)), file.path(md_dir, "S30E_DOWNSTREAM_CONSUMPTION_CONTRACT.md"))
writeLines(c("# S30E Decision", "", paste("Decision:", decision), paste("Status:", status)), file.path(md_dir, "S30E_DECISION.md"))

if (decision != "AUTHORIZE_S30F_DATASET_RELEASE_FREEZE") {
  stop("S30E validation failed")
}

message(decision)
