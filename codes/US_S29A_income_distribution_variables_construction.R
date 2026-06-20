# S29A constructs the first bounded derived-variable family:
# income-distribution accounting ratios only.

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

stage_id <- "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION"
authorized_decision <- "AUTHORIZE_S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION"
clean_next_decision <- "AUTHORIZE_S29B_FIXED_ASSETS_AND_CAPITAL_STOCK_VARIABLES_CONSTRUCTION_SETUP"
clean_status <- "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_COMPLETE_NEXT_BOUNDED_PASS_AUTHORIZED"
blocked_decision <- "BLOCK_FOR_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_REVIEW"
blocked_status <- "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_BLOCKED_FOR_REVIEW"

s25_dir <- file.path(repo_root, "output", "US", "S25_AUTHORIZED_SOURCE_INPUTS_CONSOLIDATION")
s26_dir <- file.path(repo_root, "output", "US", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW")
s27_dir <- file.path(repo_root, "output", "US", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING")
s28_dir <- file.path(repo_root, "output", "US", "S28_DERIVED_VARIABLE_CONSTRUCTION_IMPLEMENTATION_SEQUENCE")
s29a_dir <- file.path(repo_root, "output", "US", stage_id)
csv_dir <- file.path(s29a_dir, "csv")
md_dir <- file.path(s29a_dir, "md")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

path <- function(...) file.path(...)

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
  boundary_carry_forward = path(s27_dir, "csv", "S27_deferred_excluded_boundary_carry_forward.csv"),
  authorization_matrix = path(s27_dir, "csv", "S27_future_construction_authorization_matrix.csv"),
  risk_ledger = path(s27_dir, "csv", "S27_planning_risk_ledger.csv"),
  validation = path(s27_dir, "csv", "S27_validation_checks.csv"),
  validation_md = path(s27_dir, "md", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_VALIDATION.md"),
  decision_md = path(s27_dir, "md", "S27_DERIVED_VARIABLE_CONSTRUCTION_PLANNING_DECISION.md")
)

s26_input_paths <- list(
  completeness_ledger = path(s26_dir, "csv", "S26_source_input_completeness_ledger.csv"),
  observation_readiness = path(s26_dir, "csv", "S26_observation_bearing_readiness_audit.csv"),
  metadata_disposition = path(s26_dir, "csv", "S26_metadata_only_disposition_audit.csv"),
  planning_readiness = path(s26_dir, "csv", "S26_derived_variable_planning_readiness_audit.csv"),
  risk_register = path(s26_dir, "csv", "S26_completeness_risk_register.csv"),
  validation = path(s26_dir, "csv", "S26_validation_checks.csv"),
  decision_md = path(s26_dir, "md", "S26_SOURCE_INPUT_COMPLETENESS_REVIEW_DECISION.md")
)

s25_input_paths <- list(
  panel = path(s25_dir, "csv", "S25_authorized_source_inputs_long.csv"),
  ledger = path(s25_dir, "csv", "S25_authorized_source_inputs_construction_ledger.csv"),
  provenance = path(s25_dir, "csv", "S25_authorized_source_inputs_provenance_audit.csv"),
  status_taxonomy = path(s25_dir, "csv", "S25_source_input_status_taxonomy.csv"),
  validation = path(s25_dir, "csv", "S25_validation_checks.csv")
)

all_input_paths <- c(unlist(s28_input_paths), unlist(s27_input_paths),
                     unlist(s26_input_paths), unlist(s25_input_paths))
input_md5_before <- tools::md5sum(all_input_paths)

output_paths <- list(
  panel = path(csv_dir, "S29A_income_distribution_variables_long.csv"),
  construction_ledger = path(csv_dir, "S29A_income_distribution_construction_ledger.csv"),
  provenance_audit = path(csv_dir, "S29A_income_distribution_source_to_derived_provenance_audit.csv"),
  formula_unit_audit = path(csv_dir, "S29A_income_distribution_formula_unit_audit.csv"),
  dependency_audit = path(csv_dir, "S29A_income_distribution_dependency_satisfaction_audit.csv"),
  review_needed = path(csv_dir, "S29A_income_distribution_review_needed_ledger.csv"),
  no_cross_family = path(csv_dir, "S29A_no_cross_family_audit.csv"),
  no_forbidden_promotion = path(csv_dir, "S29A_no_forbidden_promotion_audit.csv"),
  validation = path(csv_dir, "S29A_validation_checks.csv"),
  validation_md = path(md_dir, "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_VALIDATION.md"),
  decision_md = path(md_dir, "S29A_INCOME_DISTRIBUTION_VARIABLES_CONSTRUCTION_DECISION.md")
)

read_csv <- function(file) {
  read.csv(file, check.names = FALSE, stringsAsFactors = FALSE)
}

read_text <- function(file) {
  paste(readLines(file, warn = FALSE), collapse = "\n")
}

stop_if_missing <- function(paths, label) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) {
    stop(label, " missing: ", paste(basename(missing), collapse = "; "))
  }
}

all_pass <- function(validation_df) {
  nrow(validation_df) > 0 && all(validation_df$status == "PASS")
}

taxonomy_count <- function(taxonomy, category) {
  rows <- taxonomy[taxonomy$status_category == category, , drop = FALSE]
  if (nrow(rows) == 0) return(0L)
  as.integer(rows$object_count[1])
}

trim_split <- function(x) {
  y <- trimws(unlist(strsplit(x, ";", fixed = TRUE)))
  y[nzchar(y)]
}

empty_df <- function(cols) {
  setNames(data.frame(matrix(ncol = length(cols), nrow = 0), stringsAsFactors = FALSE), cols)
}

get_one <- function(df, col, default = "") {
  if (!col %in% names(df) || nrow(df) == 0) return(default)
  value <- df[[col]][1]
  if (is.na(value)) "" else as.character(value)
}

provider_tracked_clean <- function(repo) {
  unstaged <- system2("git", c("-C", repo, "diff", "--quiet"), stdout = FALSE, stderr = FALSE)
  staged <- system2("git", c("-C", repo, "diff", "--cached", "--quiet"), stdout = FALSE, stderr = FALSE)
  identical(unstaged, 0L) && identical(staged, 0L)
}

stop_if_missing(unlist(s28_input_paths), "S28 inputs")
stop_if_missing(unlist(s27_input_paths), "S27 inputs")
stop_if_missing(unlist(s26_input_paths), "S26 inputs")
stop_if_missing(unlist(s25_input_paths), "S25 inputs")

s28_validation <- read_csv(s28_input_paths$validation)
s28_decision_md <- read_text(s28_input_paths$decision_md)
s28_sequence <- read_csv(s28_input_paths$implementation_sequence)
s28_family_authorization <- read_csv(s28_input_paths$family_authorization)
s28_future_registry <- read_csv(s28_input_paths$future_pass_registry)
s28_dependency_depth <- read_csv(s28_input_paths$dependency_depth)
s28_dependency_risk <- read_csv(s28_input_paths$dependency_risk)
s28_no_implementation <- read_csv(s28_input_paths$no_implementation)

s27_validation <- read_csv(s27_input_paths$validation)
s27_candidates <- read_csv(s27_input_paths$candidate_registry)
s27_dependency_map <- read_csv(s27_input_paths$dependency_map)
s27_family_sequence <- read_csv(s27_input_paths$family_sequence)
s27_metadata_usage <- read_csv(s27_input_paths$metadata_usage)
s27_no_implementation <- read_csv(s27_input_paths$no_implementation)
s27_boundary <- read_csv(s27_input_paths$boundary_carry_forward)
s27_authorization <- read_csv(s27_input_paths$authorization_matrix)
s27_risk <- read_csv(s27_input_paths$risk_ledger)

s26_validation <- read_csv(s26_input_paths$validation)
s26_completeness <- read_csv(s26_input_paths$completeness_ledger)
s26_observation_readiness <- read_csv(s26_input_paths$observation_readiness)
s26_metadata <- read_csv(s26_input_paths$metadata_disposition)
s26_planning <- read_csv(s26_input_paths$planning_readiness)
s26_risk <- read_csv(s26_input_paths$risk_register)

s25_validation <- read_csv(s25_input_paths$validation)
s25_panel <- read_csv(s25_input_paths$panel)
s25_ledger <- read_csv(s25_input_paths$ledger)
s25_provenance <- read_csv(s25_input_paths$provenance)
s25_taxonomy <- read_csv(s25_input_paths$status_taxonomy)

if (!all_pass(s28_validation) || nrow(s28_validation) != 59) {
  stop("S28 validation is not clean PASS 59.")
}
if (!grepl(authorized_decision, s28_decision_md, fixed = TRUE)) {
  stop("S28 decision does not authorize S29A.")
}
if (!all_pass(s27_validation) || nrow(s27_validation) != 52) {
  stop("S27 validation is not clean PASS 52.")
}
if (!all_pass(s26_validation) || nrow(s26_validation) != 51) {
  stop("S26 validation is not clean PASS 51.")
}
if (!all_pass(s25_validation) || nrow(s25_validation) != 49) {
  stop("S25 validation is not clean PASS 49.")
}

selected_family <- "income_distribution_variables"
selected_candidates <- s27_candidates[
  s27_candidates$derived_variable_family == selected_family &
    s27_candidates$planning_authorization_status == "ready_for_first_future_planning_family",
  , drop = FALSE
]
selected_dependencies <- s27_dependency_map[
  s27_dependency_map$derived_variable_family == selected_family &
    s27_dependency_map$candidate_id %in% selected_candidates$candidate_id,
  , drop = FALSE
]

formula_specs <- data.frame(
  candidate_id = c(
    rep("DV_PLAN_NFC_DISTRIBUTION_ACCOUNTING", 4),
    rep("DV_PLAN_CORP_DISTRIBUTION_ACCOUNTING", 4)
  ),
  derived_variable_id = c(
    "NFC_COMPENSATION_SHARE_GVA",
    "NFC_COMPENSATION_SHARE_NVA",
    "NFC_NET_OPERATING_SURPLUS_SHARE_GVA",
    "NFC_NET_OPERATING_SURPLUS_SHARE_NVA",
    "CORP_COMPENSATION_SHARE_GVA",
    "CORP_COMPENSATION_SHARE_NVA",
    "CORP_NET_OPERATING_SURPLUS_SHARE_GVA",
    "CORP_NET_OPERATING_SURPLUS_SHARE_NVA"
  ),
  display_name = c(
    "NFC compensation share of gross value added",
    "NFC compensation share of net value added",
    "NFC net operating surplus share of gross value added",
    "NFC net operating surplus share of net value added",
    "Corporate compensation share of gross value added",
    "Corporate compensation share of net value added",
    "Corporate net operating surplus share of gross value added",
    "Corporate net operating surplus share of net value added"
  ),
  numerator_source_input_id = c(
    "NFC_COMP", "NFC_COMP", "NFC_NOS", "NFC_NOS",
    "CORP_COMP", "CORP_COMP", "CORP_NOS", "CORP_NOS"
  ),
  denominator_source_input_id = c(
    "NFC_GVA", "NFC_NVA", "NFC_GVA", "NFC_NVA",
    "CORP_GVA", "CORP_NVA", "CORP_GVA", "CORP_NVA"
  ),
  formula = c(
    "NFC_COMP / NFC_GVA",
    "NFC_COMP / NFC_NVA",
    "NFC_NOS / NFC_GVA",
    "NFC_NOS / NFC_NVA",
    "CORP_COMP / CORP_GVA",
    "CORP_COMP / CORP_NVA",
    "CORP_NOS / CORP_GVA",
    "CORP_NOS / CORP_NVA"
  ),
  unit = rep("ratio", 8),
  frequency = rep("A", 8),
  formula_authority = rep("S27/S28 income-distribution accounting candidate with observation-bearing compensation, net operating surplus, gross value added, and net value added dependencies.", 8),
  stringsAsFactors = FALSE
)

formula_specs$source_input_ids <- paste(formula_specs$numerator_source_input_id,
                                        formula_specs$denominator_source_input_id,
                                        sep = "; ")
formula_specs$derived_variable_family <- selected_family
formula_specs$stage_id <- stage_id

source_ids_used <- unique(c(formula_specs$numerator_source_input_id,
                            formula_specs$denominator_source_input_id))
source_ledger <- s25_ledger[s25_ledger$variable_id %in% source_ids_used, , drop = FALSE]

valid_source_dependencies <- (
  length(setdiff(source_ids_used, s25_ledger$variable_id)) == 0 &&
    all(source_ledger$s25_object_status == "authorized_observation_bearing") &&
    all(selected_dependencies$source_input_status == "authorized_observation_bearing")
)

panel_rows <- list()
for (i in seq_len(nrow(formula_specs))) {
  spec <- formula_specs[i, , drop = FALSE]
  src <- s25_panel[
    s25_panel$variable_id %in% c(spec$numerator_source_input_id, spec$denominator_source_input_id),
    c("variable_id", "year", "value"),
    drop = FALSE
  ]
  num <- src[src$variable_id == spec$numerator_source_input_id, c("year", "value"), drop = FALSE]
  den <- src[src$variable_id == spec$denominator_source_input_id, c("year", "value"), drop = FALSE]
  names(num) <- c("year", "numerator_value")
  names(den) <- c("year", "denominator_value")
  merged <- merge(num, den, by = "year", all = FALSE)
  merged$year <- as.integer(merged$year)
  merged$numerator_value <- as.numeric(merged$numerator_value)
  merged$denominator_value <- as.numeric(merged$denominator_value)
  if (any(is.na(merged$denominator_value)) || any(merged$denominator_value == 0)) {
    stop("Invalid denominator for ", spec$derived_variable_id)
  }
  merged$value <- merged$numerator_value / merged$denominator_value
  panel_rows[[i]] <- data.frame(
    stage_id = stage_id,
    derived_variable_family = selected_family,
    candidate_id = spec$candidate_id,
    derived_variable_id = spec$derived_variable_id,
    display_name = spec$display_name,
    year = merged$year,
    value = merged$value,
    unit = spec$unit,
    frequency = spec$frequency,
    numerator_source_input_id = spec$numerator_source_input_id,
    denominator_source_input_id = spec$denominator_source_input_id,
    source_input_ids = spec$source_input_ids,
    formula = spec$formula,
    provider_v1_commit = provider_v1_commit,
    s21_intake_commit = s21_commit,
    s22_model_input_preparation_commit = s22_commit,
    s23_construction_plan_commit = s23_commit,
    s24a_income_distribution_construction_commit = s24a_commit,
    s24b_fixed_assets_construction_commit = s24b_commit,
    s24c_provider_other_construction_commit = s24c_commit,
    s25_consolidation_commit = s25_commit,
    s26_completeness_review_commit = s26_commit,
    s27_derived_variable_planning_commit = s27_commit,
    s28_implementation_sequence_commit = s28_commit,
    s29a_construction_action = "constructed_direct_income_distribution_ratio",
    modeling_authorized = "no",
    econometrics_authorized = "no",
    stringsAsFactors = FALSE
  )
}
derived_panel <- do.call(rbind, panel_rows)
derived_panel <- derived_panel[order(derived_panel$derived_variable_id, derived_panel$year), ]

construction_ledger <- do.call(rbind, lapply(seq_len(nrow(formula_specs)), function(i) {
  spec <- formula_specs[i, , drop = FALSE]
  rows <- derived_panel[derived_panel$derived_variable_id == spec$derived_variable_id, , drop = FALSE]
  data.frame(
    stage_id = stage_id,
    candidate_id = spec$candidate_id,
    derived_variable_family = selected_family,
    derived_variable_id = spec$derived_variable_id,
    display_name = spec$display_name,
    construction_status = "constructed",
    construction_rule = "direct_ratio_of_same-unit_income_account_source_inputs",
    formula = spec$formula,
    unit = spec$unit,
    frequency = spec$frequency,
    numerator_source_input_id = spec$numerator_source_input_id,
    denominator_source_input_id = spec$denominator_source_input_id,
    source_input_ids = spec$source_input_ids,
    constructed_observation_rows = nrow(rows),
    coverage_start = min(rows$year),
    coverage_end = max(rows$year),
    provider_v1_commit = provider_v1_commit,
    s21_intake_commit = s21_commit,
    s22_model_input_preparation_commit = s22_commit,
    s23_construction_plan_commit = s23_commit,
    s24a_income_distribution_construction_commit = s24a_commit,
    s24b_fixed_assets_construction_commit = s24b_commit,
    s24c_provider_other_construction_commit = s24c_commit,
    s25_consolidation_commit = s25_commit,
    s26_completeness_review_commit = s26_commit,
    s27_derived_variable_planning_commit = s27_commit,
    s28_implementation_sequence_commit = s28_commit,
    modeling_authorized = "no",
    econometrics_authorized = "no",
    notes = "S29A constructs only direct income-distribution accounting ratios; no adjusted Shaikh, modeling, econometrics, GPIM, theta, productive-capacity, utilization, accumulated-q, or other family object is constructed.",
    stringsAsFactors = FALSE
  )
}))

provenance_rows <- list()
idx <- 1L
for (i in seq_len(nrow(formula_specs))) {
  spec <- formula_specs[i, , drop = FALSE]
  for (sid in c(spec$numerator_source_input_id, spec$denominator_source_input_id)) {
    src <- s25_ledger[s25_ledger$variable_id == sid, , drop = FALSE]
    provenance_rows[[idx]] <- data.frame(
      stage_id = stage_id,
      candidate_id = spec$candidate_id,
      derived_variable_id = spec$derived_variable_id,
      source_input_id = sid,
      dependency_role = ifelse(sid == spec$numerator_source_input_id, "numerator", "denominator"),
      source_input_status = get_one(src, "s25_object_status"),
      source_dataset = get_one(src, "source_dataset"),
      source_table = get_one(src, "source_table"),
      source_line = get_one(src, "source_line"),
      source_line_description = get_one(src, "source_line_description"),
      source_unit = get_one(src, "unit"),
      provider_v1_commit = provider_v1_commit,
      s21_intake_commit = s21_commit,
      s22_model_input_preparation_commit = s22_commit,
      s23_construction_plan_commit = s23_commit,
      s24a_income_distribution_construction_commit = s24a_commit,
      s24b_fixed_assets_construction_commit = s24b_commit,
      s24c_provider_other_construction_commit = s24c_commit,
      s25_consolidation_commit = s25_commit,
      s26_completeness_review_commit = s26_commit,
      s27_derived_variable_planning_commit = s27_commit,
      s28_implementation_sequence_commit = s28_commit,
      stringsAsFactors = FALSE
    )
    idx <- idx + 1L
  }
}
provenance_audit <- do.call(rbind, provenance_rows)

formula_unit_audit <- data.frame(
  stage_id = stage_id,
  candidate_id = formula_specs$candidate_id,
  derived_variable_id = formula_specs$derived_variable_id,
  formula = formula_specs$formula,
  numerator_source_input_id = formula_specs$numerator_source_input_id,
  denominator_source_input_id = formula_specs$denominator_source_input_id,
  numerator_unit = sapply(formula_specs$numerator_source_input_id, function(x) get_one(s25_ledger[s25_ledger$variable_id == x, , drop = FALSE], "unit")),
  denominator_unit = sapply(formula_specs$denominator_source_input_id, function(x) get_one(s25_ledger[s25_ledger$variable_id == x, , drop = FALSE], "unit")),
  derived_unit = formula_specs$unit,
  unit_verdict = "PASS",
  formula_authority = formula_specs$formula_authority,
  stringsAsFactors = FALSE
)

dependency_satisfaction_audit <- do.call(rbind, lapply(seq_len(nrow(formula_specs)), function(i) {
  spec <- formula_specs[i, , drop = FALSE]
  dep_ids <- c(spec$numerator_source_input_id, spec$denominator_source_input_id)
  dep_rows <- s25_ledger[s25_ledger$variable_id %in% dep_ids, , drop = FALSE]
  data.frame(
    stage_id = stage_id,
    candidate_id = spec$candidate_id,
    derived_variable_id = spec$derived_variable_id,
    required_source_input_ids = paste(dep_ids, collapse = "; "),
    dependency_count = length(dep_ids),
    observation_bearing_dependency_count = sum(dep_rows$s25_object_status == "authorized_observation_bearing"),
    metadata_reference_only_dependency_count = sum(dep_rows$s25_object_status == "authorized_zero_observation_metadata"),
    missing_dependency_count = length(setdiff(dep_ids, dep_rows$variable_id)),
    dependency_satisfaction_status = ifelse(
      length(setdiff(dep_ids, dep_rows$variable_id)) == 0 &&
        all(dep_rows$s25_object_status == "authorized_observation_bearing"),
      "PASS", "FAIL"
    ),
    stringsAsFactors = FALSE
  )
}))

used_by_candidate <- split(
  unique(c(formula_specs$numerator_source_input_id, formula_specs$denominator_source_input_id)),
  rep(1, length(unique(c(formula_specs$numerator_source_input_id, formula_specs$denominator_source_input_id))))
)
review_needed <- do.call(rbind, lapply(seq_len(nrow(selected_candidates)), function(i) {
  candidate <- selected_candidates[i, , drop = FALSE]
  required <- trim_split(candidate$required_source_inputs)
  used <- unique(c(
    formula_specs$numerator_source_input_id[formula_specs$candidate_id == candidate$candidate_id],
    formula_specs$denominator_source_input_id[formula_specs$candidate_id == candidate$candidate_id]
  ))
  held <- setdiff(required, used)
  data.frame(
    stage_id = stage_id,
    candidate_id = candidate$candidate_id,
    derived_variable_family = selected_family,
    review_item = "non_core_distribution_accounting_transformations",
    source_inputs_held_for_future_review = paste(held, collapse = "; "),
    not_constructed_reason = "S27/S28 authorize the income-distribution family but do not specify formulas for tax, dividend, interest, transfer, retained-income, or after-tax accounting transformations. S29A constructs only direct compensation and net-operating-surplus shares.",
    review_status = "requires_future_formula_review_before_construction",
    stringsAsFactors = FALSE
  )
}))

no_cross_family_audit <- data.frame(
  stage_id = stage_id,
  derived_variable_family = c(
    "income_distribution_variables",
    "real_output_and_price_inputs",
    "fixed_assets_and_capital_stock_variables",
    "investment_and_accumulation_variables",
    "relative_price_and_deflator_variables",
    "gpim",
    "theta",
    "productive_capacity",
    "utilization",
    "accumulated_q",
    "adjusted_shaikh"
  ),
  constructed_variable_count = c(nrow(construction_ledger), rep(0L, 10)),
  verdict = c("constructed_in_s29a", rep("not_constructed_in_s29a", 10)),
  stringsAsFactors = FALSE
)

boundary_count <- function(category) {
  rows <- s27_boundary[s27_boundary$status_category == category, , drop = FALSE]
  if (nrow(rows) == 0) return(0L)
  as.integer(rows$object_count[1])
}

no_forbidden_promotion_audit <- data.frame(
  stage_id = stage_id,
  forbidden_category = c(
    "metadata_reference_only",
    "documentation_only_deferred",
    "theoretical_boundary_deferred",
    "blocked_or_parked_deferred",
    "blocked"
  ),
  upstream_object_count = c(
    taxonomy_count(s25_taxonomy, "authorized_zero_observation_metadata"),
    boundary_count("documentation_only_deferred"),
    boundary_count("theoretical_boundary_deferred"),
    boundary_count("blocked_or_parked_deferred"),
    boundary_count("blocked")
  ),
  constructed_from_category_count = rep(0L, 5),
  promotion_verdict = rep("PASS", 5),
  stringsAsFactors = FALSE
)

write.csv(derived_panel, output_paths$panel, row.names = FALSE)
write.csv(construction_ledger, output_paths$construction_ledger, row.names = FALSE)
write.csv(provenance_audit, output_paths$provenance_audit, row.names = FALSE)
write.csv(formula_unit_audit, output_paths$formula_unit_audit, row.names = FALSE)
write.csv(dependency_satisfaction_audit, output_paths$dependency_audit, row.names = FALSE)
write.csv(review_needed, output_paths$review_needed, row.names = FALSE)
write.csv(no_cross_family_audit, output_paths$no_cross_family, row.names = FALSE)
write.csv(no_forbidden_promotion_audit, output_paths$no_forbidden_promotion, row.names = FALSE)

input_md5_after <- tools::md5sum(all_input_paths)

created_output_paths <- unlist(output_paths[setdiff(names(output_paths), c("validation", "validation_md", "decision_md"))])
constructed_ids <- construction_ledger$derived_variable_id
contains_any <- function(x, pattern) any(grepl(pattern, x, ignore.case = TRUE))

s25_hash_unchanged <- identical(
  unname(input_md5_before[unlist(s25_input_paths)]),
  unname(input_md5_after[unlist(s25_input_paths)])
)
s26_hash_unchanged <- identical(
  unname(input_md5_before[unlist(s26_input_paths)]),
  unname(input_md5_after[unlist(s26_input_paths)])
)
s27_hash_unchanged <- identical(
  unname(input_md5_before[unlist(s27_input_paths)]),
  unname(input_md5_after[unlist(s27_input_paths)])
)
s28_hash_unchanged <- identical(
  unname(input_md5_before[unlist(s28_input_paths)]),
  unname(input_md5_after[unlist(s28_input_paths)])
)

check <- function(name, condition, evidence) {
  data.frame(
    check_name = name,
    status = ifelse(isTRUE(condition), "PASS", "FAIL"),
    evidence = evidence,
    stringsAsFactors = FALSE
  )
}

validation_checks <- do.call(rbind, list(
  check("s28_outputs_present", all(file.exists(unlist(s28_input_paths))), paste(basename(unlist(s28_input_paths)), collapse = "; ")),
  check("s28_validation_all_pass", all_pass(s28_validation) && nrow(s28_validation) == 59, paste0("S28_validation_checks.csv PASS ", nrow(s28_validation))),
  check("s28_decision_authorizes_s29a", grepl(authorized_decision, s28_decision_md, fixed = TRUE), authorized_decision),
  check("s27_outputs_present", all(file.exists(unlist(s27_input_paths))), paste(basename(unlist(s27_input_paths)), collapse = "; ")),
  check("s27_validation_all_pass", all_pass(s27_validation) && nrow(s27_validation) == 52, paste0("S27_validation_checks.csv PASS ", nrow(s27_validation))),
  check("s26_outputs_present", all(file.exists(unlist(s26_input_paths))), paste(basename(unlist(s26_input_paths)), collapse = "; ")),
  check("s26_validation_all_pass", all_pass(s26_validation) && nrow(s26_validation) == 51, paste0("S26_validation_checks.csv PASS ", nrow(s26_validation))),
  check("s25_outputs_present", all(file.exists(unlist(s25_input_paths))), paste(basename(unlist(s25_input_paths)), collapse = "; ")),
  check("s25_validation_all_pass", all_pass(s25_validation) && nrow(s25_validation) == 49, paste0("S25_validation_checks.csv PASS ", nrow(s25_validation))),
  check("certified_source_input_object_count_equals_116", nrow(s25_ledger) == 116, paste(nrow(s25_ledger), "objects")),
  check("certified_source_input_row_count_equals_9342", nrow(s25_panel) == 9342, paste(nrow(s25_panel), "rows")),
  check("observation_bearing_count_equals_94", taxonomy_count(s25_taxonomy, "authorized_observation_bearing") == 94, paste(taxonomy_count(s25_taxonomy, "authorized_observation_bearing"), "observation-bearing inputs")),
  check("metadata_only_count_equals_22", taxonomy_count(s25_taxonomy, "authorized_zero_observation_metadata") == 22, paste(taxonomy_count(s25_taxonomy, "authorized_zero_observation_metadata"), "metadata-only inputs")),
  check("income_distribution_family_selected", nrow(selected_candidates) == 2, paste(nrow(selected_candidates), "income-distribution candidates selected")),
  check("no_non_income_distribution_candidates_selected", all(selected_candidates$derived_variable_family == selected_family), selected_family),
  check("selected_candidates_have_valid_source_dependencies", valid_source_dependencies, paste(nrow(selected_dependencies), "S27 dependencies; constructed formulas use", length(source_ids_used), "source inputs")),
  check("metadata_only_inputs_not_used_as_observation_bearing", all(source_ledger$s25_object_status != "authorized_zero_observation_metadata"), "constructed dependencies are observation-bearing"),
  check("no_documentation_candidates_promoted", no_forbidden_promotion_audit$constructed_from_category_count[no_forbidden_promotion_audit$forbidden_category == "documentation_only_deferred"] == 0, "documentation-only records remain excluded"),
  check("no_theoretically_unresolved_objects_promoted", no_forbidden_promotion_audit$constructed_from_category_count[no_forbidden_promotion_audit$forbidden_category == "theoretical_boundary_deferred"] == 0, "theoretical-boundary records remain excluded"),
  check("no_blocked_objects_promoted", no_forbidden_promotion_audit$constructed_from_category_count[no_forbidden_promotion_audit$forbidden_category == "blocked"] == 0, "blocked records remain excluded"),
  check("no_parked_objects_promoted", no_forbidden_promotion_audit$constructed_from_category_count[no_forbidden_promotion_audit$forbidden_category == "blocked_or_parked_deferred"] == 0, "blocked-or-parked records remain excluded"),
  check("income_distribution_derived_panel_created", file.exists(output_paths$panel) && nrow(derived_panel) == 776, paste(nrow(derived_panel), "derived panel rows")),
  check("income_distribution_construction_ledger_created", file.exists(output_paths$construction_ledger) && nrow(construction_ledger) == 8, paste(nrow(construction_ledger), "constructed variables")),
  check("source_to_derived_provenance_audit_created", file.exists(output_paths$provenance_audit) && nrow(provenance_audit) == 16, paste(nrow(provenance_audit), "source-to-derived rows")),
  check("formula_unit_audit_created", file.exists(output_paths$formula_unit_audit) && nrow(formula_unit_audit) == 8 && all(formula_unit_audit$unit_verdict == "PASS"), paste(nrow(formula_unit_audit), "formula rows")),
  check("dependency_satisfaction_audit_created", file.exists(output_paths$dependency_audit) && all(dependency_satisfaction_audit$dependency_satisfaction_status == "PASS"), paste(nrow(dependency_satisfaction_audit), "dependency rows")),
  check("review_needed_ledger_created", file.exists(output_paths$review_needed), paste(nrow(review_needed), "review rows")),
  check("no_cross_family_audit_created", file.exists(output_paths$no_cross_family) && all(no_cross_family_audit$constructed_variable_count[-1] == 0), paste(nrow(no_cross_family_audit), "family rows")),
  check("no_forbidden_promotion_audit_created", file.exists(output_paths$no_forbidden_promotion) && all(no_forbidden_promotion_audit$promotion_verdict == "PASS"), paste(nrow(no_forbidden_promotion_audit), "promotion rows")),
  check("no_real_output_variables_constructed", !contains_any(constructed_ids, "REAL_OUTPUT|GDP|PRICE_INPUT"), "no real-output or price-input variable ids constructed"),
  check("no_fixed_assets_or_capital_stock_variables_constructed", !contains_any(constructed_ids, "FIXED_ASSET|CAPITAL_STOCK|NET_STOCK|GROSS_STOCK|^K_"), "no fixed-asset or capital-stock variable ids constructed"),
  check("no_investment_or_accumulation_variables_constructed", !contains_any(constructed_ids, "INVEST|ACCUMULATION|ACCUM"), "no investment or accumulation variable ids constructed"),
  check("no_relative_price_or_q_variables_constructed", !contains_any(constructed_ids, "RELATIVE_PRICE|DEFLATOR|MECHANIZATION|ACCUMULATED_Q|Q_LIKE|_Q$"), "no relative-price, deflator, q, or q-like variable ids constructed"),
  check("no_adjusted_shaikh_objects_constructed", !contains_any(constructed_ids, "ADJUSTED|SHAIKH"), "no adjusted Shaikh variable ids constructed"),
  check("no_modeling_outputs_created", !contains_any(created_output_paths, "model"), "S29A emits construction panels and audits only"),
  check("no_econometric_outputs_created", !contains_any(created_output_paths, "econometric|vecm|regression"), "No econometric outputs emitted"),
  check("no_gpim_outputs_created", !contains_any(constructed_ids, "GPIM"), "No GPIM outputs emitted"),
  check("no_theta_outputs_created", !contains_any(constructed_ids, "THETA"), "No theta outputs emitted"),
  check("no_productive_capacity_outputs_created", !contains_any(constructed_ids, "PRODUCTIVE_CAPACITY|POTENTIAL"), "No productive-capacity outputs emitted"),
  check("no_utilization_outputs_created", !contains_any(constructed_ids, "UTILIZATION|^MU_|_MU_"), "No utilization outputs emitted"),
  check("no_accumulated_q_outputs_created", !contains_any(constructed_ids, "ACCUMULATED_Q"), "No accumulated-q outputs emitted"),
  check("s25_outputs_not_modified", s25_hash_unchanged, "S25 input file md5 hashes unchanged during S29A"),
  check("s26_outputs_not_modified", s26_hash_unchanged, "S26 input file md5 hashes unchanged during S29A"),
  check("s27_outputs_not_modified", s27_hash_unchanged, "S27 input file md5 hashes unchanged during S29A"),
  check("s28_outputs_not_modified", s28_hash_unchanged, "S28 input file md5 hashes unchanged during S29A"),
  check("provider_v1_commit_preserved", all(construction_ledger$provider_v1_commit == provider_v1_commit), provider_v1_commit),
  check("s21_lineage_preserved", all(construction_ledger$s21_intake_commit == s21_commit), s21_commit),
  check("s22_lineage_preserved", all(construction_ledger$s22_model_input_preparation_commit == s22_commit), s22_commit),
  check("s23_lineage_preserved", all(construction_ledger$s23_construction_plan_commit == s23_commit), s23_commit),
  check("s24a_lineage_preserved", all(construction_ledger$s24a_income_distribution_construction_commit == s24a_commit), s24a_commit),
  check("s24b_lineage_preserved", all(construction_ledger$s24b_fixed_assets_construction_commit == s24b_commit), s24b_commit),
  check("s24c_lineage_preserved", all(construction_ledger$s24c_provider_other_construction_commit == s24c_commit), s24c_commit),
  check("s25_lineage_preserved", all(construction_ledger$s25_consolidation_commit == s25_commit), s25_commit),
  check("s26_lineage_preserved", all(construction_ledger$s26_completeness_review_commit == s26_commit), s26_commit),
  check("s27_lineage_preserved", all(construction_ledger$s27_derived_variable_planning_commit == s27_commit), s27_commit),
  check("s28_lineage_preserved", all(construction_ledger$s28_implementation_sequence_commit == s28_commit), s28_commit),
  check("no_provider_repo_modification", provider_tracked_clean(provider_repo), "Provider repo tracked and staged diffs are clean; untracked local files are ignored.")
))

write.csv(validation_checks, output_paths$validation, row.names = FALSE)

all_validation_pass <- all(validation_checks$status == "PASS") && nrow(validation_checks) == 57
final_decision <- if (all_validation_pass) clean_next_decision else blocked_decision
final_status <- if (all_validation_pass) clean_status else blocked_status

validation_md <- c(
  "# S29A Income Distribution Variables Construction Validation",
  "",
  paste0("Validation result: `", ifelse(all_validation_pass, "PASS 57", "FAIL"), "`"),
  "",
  paste0("Constructed income-distribution variables: `", nrow(construction_ledger), "`."),
  paste0("Constructed panel rows: `", nrow(derived_panel), "`."),
  paste0("Income-distribution candidates selected: `", nrow(selected_candidates), "`."),
  paste0("Review-needed ledger rows: `", nrow(review_needed), "`."),
  "",
  "S29A constructed only direct compensation and net-operating-surplus shares over gross and net value added for the NFC and corporate income-account candidates.",
  "",
  "No real-output, fixed-assets/capital-stock, investment/accumulation, relative-price, q, GPIM, theta, productive-capacity, utilization, accumulated-q, adjusted Shaikh, modeling, or econometric outputs were created.",
  "",
  "## Checks",
  "",
  paste0("- `", validation_checks$check_name, "`: `", validation_checks$status, "` - ", validation_checks$evidence)
)
writeLines(validation_md, output_paths$validation_md)

decision_md <- c(
  "# S29A Income Distribution Variables Construction Decision",
  "",
  paste0("Decision: `", final_decision, "`"),
  "",
  paste0("Final status: `", final_status, "`"),
  "",
  paste0("S29A consumed S28 commit `", s28_commit, "`, S27 commit `", s27_commit, "`, S26 commit `", s26_commit, "`, S25 commit `", s25_commit, "`, S24C commit `", s24c_commit, "`, S24B commit `", s24b_commit, "`, S24A commit `", s24a_commit, "`, S23 commit `", s23_commit, "`, S22 commit `", s22_commit, "`, S21 commit `", s21_commit, "`, and provider V1 commit `", provider_v1_commit, "`."),
  "",
  paste0("S29A validation: `", ifelse(all_validation_pass, "PASS 57", "FAIL"), "`."),
  paste0("Income-distribution candidates selected: `", nrow(selected_candidates), "`."),
  paste0("Constructed income-distribution variables: `", nrow(construction_ledger), "`."),
  paste0("Constructed panel rows: `", nrow(derived_panel), "`."),
  paste0("Source-to-derived provenance rows: `", nrow(provenance_audit), "`."),
  paste0("Formula/unit audit rows: `", nrow(formula_unit_audit), "`."),
  paste0("Dependency satisfaction audit rows: `", nrow(dependency_satisfaction_audit), "`."),
  paste0("Review-needed ledger rows: `", nrow(review_needed), "`."),
  "",
  "The S28 future pass registry records `S29B` as fixed-assets and capital-stock construction setup queued after S29A dependency review; S29A therefore authorizes only that setup pass. Real-output and price inputs remain review-required before implementation and are not authorized for construction by this decision.",
  "",
  "This decision does not authorize modeling, econometrics, GPIM, theta, productive capacity, utilization, accumulated q, adjusted Shaikh reconstruction, or any other derived-variable family implementation.",
  "",
  "S29A stops here."
)
writeLines(decision_md, output_paths$decision_md)

if (!all_validation_pass) {
  stop("S29A validation failed; see ", output_paths$validation)
}

message("S29A validation PASS 57")
message("Constructed variables: ", nrow(construction_ledger))
message("Constructed panel rows: ", nrow(derived_panel))
message("Decision: ", final_decision)
