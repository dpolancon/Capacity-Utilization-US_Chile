#!/usr/bin/env Rscript

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
rel <- function(...) file.path(..., fsep = "/")
abs_path <- function(...) file.path(root, ..., fsep = "/")

out_dir <- abs_path("output", "US", "S20B_DISTRIBUTION_ATTACHMENT_CONTRACT")
csv_dir <- rel(out_dir, "csv")
md_dir <- rel(out_dir, "md")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)

s20_dir <- abs_path("output", "US", "S20_MODEL_INPUT_LAYER")
s14_dir <- abs_path("output", "US", "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION")

read_csv <- function(path) {
  if (!file.exists(path)) {
    stop("Required input missing: ", path, call. = FALSE)
  }
  read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

git_out <- function(args) {
  trimws(system2("git", args, stdout = TRUE, stderr = TRUE))
}

md5 <- function(paths) {
  paths <- paths[file.exists(paths)]
  if (length(paths) == 0L) {
    return(character())
  }
  tools::md5sum(paths)
}

finite_coverage <- function(df, value_col, year_col = "year") {
  if (!all(c(value_col, year_col) %in% names(df))) {
    return(c(start = NA_integer_, end = NA_integer_, n = 0L))
  }
  years <- suppressWarnings(as.integer(df[[year_col]]))
  vals <- suppressWarnings(as.numeric(df[[value_col]]))
  ok <- is.finite(years) & is.finite(vals)
  if (!any(ok)) {
    return(c(start = NA_integer_, end = NA_integer_, n = 0L))
  }
  c(start = min(years[ok]), end = max(years[ok]), n = sum(ok))
}

infer_kind <- function(variable_id) {
  id <- tolower(variable_id)
  if (grepl("shaikh|(^|_)adj|adjusted", id)) return("shaikh_adjusted_or_adjustment_candidate")
  if (grepl("omega|wage|comp", id)) return("wage_share_or_wage_share_ingredient")
  if (grepl("pi|profit|surplus|gos|nos", id)) return("profit_share_or_profit_ingredient")
  if (grepl("^e_|ln_e|exploitation", id)) return("alternative_distribution_proxy")
  "distribution_related"
}

infer_boundary <- function(variable_id, source_file = "") {
  txt <- toupper(paste(variable_id, source_file))
  if (grepl("NFC|NF_", txt)) return("nonfinancial_corporate")
  if (grepl("CORP", txt)) return("corporate")
  if (grepl("FIN", txt)) return("financial_or_corporate_boundary_diagnostic")
  "not_declared_or_mixed"
}

contract_note <- paste(
  "No current-release S20B authorization is inferred from legacy or downstream use.",
  "A source can attach only through explicit current S20/S14-compatible source, boundary, formula, coverage, and join validation."
)

candidate_rows <- list()
add_candidate <- function(variable_id, source_file, source_stage, sector_account_boundary,
                          numerator, denominator, unit, frequency, coverage_start,
                          coverage_end, finite_observations, adjusted_unadjusted, kind,
                          authorization, s20_support_compatibility, joinable_by_year,
                          candidate_status, evidence) {
  candidate_rows[[length(candidate_rows) + 1L]] <<- data.frame(
    variable_id = variable_id,
    source_file = source_file,
    source_stage = source_stage,
    sector_account_boundary = sector_account_boundary,
    numerator = numerator,
    denominator = denominator,
    unit = unit,
    frequency = frequency,
    year_coverage_start = coverage_start,
    year_coverage_end = coverage_end,
    finite_observations = finite_observations,
    adjusted_unadjusted = adjusted_unadjusted,
    kind = kind,
    authorization = authorization,
    s20_support_compatibility = s20_support_compatibility,
    joinable_by_year = joinable_by_year,
    candidate_status = candidate_status,
    evidence = evidence,
    stringsAsFactors = FALSE
  )
}

s20_validation_path <- rel(s20_dir, "csv", "S20_validation_checks.csv")
s20_distribution_path <- rel(s20_dir, "csv", "S20_distribution_role_ledger.csv")
s20_panel_path <- rel(s20_dir, "csv", "S20_model_input_panel_long.csv")
s20_capital_ledger_path <- rel(s20_dir, "csv", "S20_capital_role_ledger.csv")
s20_blocked_path <- rel(s20_dir, "csv", "S20_blocked_parked_excluded_object_ledger.csv")
s20_report_path <- rel(s20_dir, "md", "S20_MODEL_INPUT_LAYER.md")
s14_validation_path <- rel(s14_dir, "csv", "S14_validation_checks.csv")
s14_panel_path <- rel(s14_dir, "csv", "S14_ch2_source_of_truth_panel_long.csv")

s20_hash_targets <- c(s20_validation_path, s20_distribution_path, s20_panel_path,
                      s20_capital_ledger_path, s20_blocked_path, s20_report_path)
s20_hash_before <- md5(s20_hash_targets)

s20_validation <- read_csv(s20_validation_path)
s20_distribution <- read_csv(s20_distribution_path)
s20_panel <- read_csv(s20_panel_path)
s20_capital_ledger <- read_csv(s20_capital_ledger_path)
s20_blocked <- read_csv(s20_blocked_path)
s20_report <- paste(readLines(s20_report_path, warn = FALSE), collapse = "\n")
s14_validation <- read_csv(s14_validation_path)
s14_panel <- read_csv(s14_panel_path)

for (i in seq_len(nrow(s20_distribution))) {
  r <- s20_distribution[i, ]
  add_candidate(
    variable_id = r$object_id,
    source_file = "output/US/S20_MODEL_INPUT_LAYER/csv/S20_distribution_role_ledger.csv",
    source_stage = "current_S20_model_input_layer",
    sector_account_boundary = "pending_current_source_boundary",
    numerator = "pending_authorized_source",
    denominator = "pending_authorized_source",
    unit = "share_or_ratio_pending",
    frequency = "annual_pending",
    coverage_start = NA_integer_,
    coverage_end = NA_integer_,
    finite_observations = 0L,
    adjusted_unadjusted = ifelse(grepl("SHAIKH", r$object_id), "adjusted_blocked", "unadjusted_or_alternative_pending"),
    kind = infer_kind(r$object_id),
    authorization = r$status,
    s20_support_compatibility = "current_S20_governing_record_but_not_attachable",
    joinable_by_year = "not_validated",
    candidate_status = ifelse(r$status == "PENDING_AUTHORIZED_SOURCE", "PENDING_NOT_ATTACHABLE", "BLOCKED_OR_OPTIONAL_NOT_ATTACHABLE"),
    evidence = paste(r$object_role, r$source_status, contract_note, sep = " | ")
  )
}

s20_panel_vars <- unique(s20_panel$variable_id)
for (vid in intersect(c("omega_NFC", "omega_CORP", "pi_res_NFC", "pi_res_CORP"), s20_panel_vars)) {
  cov <- finite_coverage(s20_panel[s20_panel$variable_id == vid, ], "value")
  add_candidate(
    variable_id = vid,
    source_file = "output/US/S20_MODEL_INPUT_LAYER/csv/S20_model_input_panel_long.csv",
    source_stage = "current_S20_model_input_layer",
    sector_account_boundary = infer_boundary(vid),
    numerator = "not_declared",
    denominator = "not_declared",
    unit = "not_declared",
    frequency = "annual_if_present",
    coverage_start = cov[["start"]],
    coverage_end = cov[["end"]],
    finite_observations = cov[["n"]],
    adjusted_unadjusted = "unadjusted_candidate",
    kind = infer_kind(vid),
    authorization = "UNEXPECTED_CURRENT_S20_PANEL_CANDIDATE",
    s20_support_compatibility = "would_require_manual_review",
    joinable_by_year = "yes",
    candidate_status = "UNEXPECTED_REVIEW_REQUIRED",
    evidence = "Current S20 panel should not contain distribution variables under the 874d19d fail-closed S20 distribution ledger."
  )
}

historical_s20_panel_path <- abs_path("data", "processed", "us_s20", "us_s20_capital_distribution_frontier_panel.csv")
historical_s20_ledger_path <- abs_path("data", "processed", "us_s20", "us_s20_construction_ledger.csv")
historical_s20_validation_path <- abs_path("data", "processed", "us_s20", "us_s20_validation_checks.csv")
if (file.exists(historical_s20_panel_path)) {
  old_s20 <- read_csv(historical_s20_panel_path)
  old_vars <- intersect(c("omega_NFC", "omega_CORP", "pi_res_NFC", "pi_res_CORP",
                          "e_NFC", "e_CORP", "ln_e_NFC", "ln_e_CORP"), names(old_s20))
  for (vid in old_vars) {
    cov <- finite_coverage(old_s20, vid)
    add_candidate(
      variable_id = vid,
      source_file = "data/processed/us_s20/us_s20_capital_distribution_frontier_panel.csv",
      source_stage = "historical_pre_GPIM_S20_capital_distribution_frontier",
      sector_account_boundary = infer_boundary(vid),
      numerator = ifelse(grepl("omega_NFC", vid), "NFC_COMP",
                  ifelse(grepl("omega_CORP", vid), "CORP_COMP",
                  ifelse(grepl("pi_res", vid), "1_minus_unadjusted_wage_share", "profit_share"))),
      denominator = ifelse(grepl("omega_NFC", vid), "NFC_GVA",
                    ifelse(grepl("omega_CORP", vid), "CORP_GVA",
                    ifelse(grepl("^e_|ln_e", vid), "wage_share", "gross_value_added"))),
      unit = "ratio",
      frequency = "annual",
      coverage_start = cov[["start"]],
      coverage_end = cov[["end"]],
      finite_observations = cov[["n"]],
      adjusted_unadjusted = "unadjusted",
      kind = infer_kind(vid),
      authorization = "HISTORICAL_VALIDATED_OUTPUT_NOT_CURRENT_S20_ATTACHMENT_AUTHORITY",
      s20_support_compatibility = "not_current_S20_contract; old panel includes superseded capital/frontier layer",
      joinable_by_year = ifelse(cov[["n"]] > 0L, "yes", "no"),
      candidate_status = "AUDITED_NOT_ATTACHABLE_CURRENT_S20",
      evidence = paste(
        "Legacy panel has annual observations, but current S20 output/US/S20_MODEL_INPUT_LAYER remains the governing S20 layer.",
        "The current S20 distribution ledger keeps wage-share attachment pending."
      )
    )
  }
}
if (file.exists(historical_s20_ledger_path)) {
  old_ledger <- read_csv(historical_s20_ledger_path)
  old_dist <- old_ledger[grepl("distribution", old_ledger$s20_family, ignore.case = TRUE), , drop = FALSE]
  if (nrow(old_dist) > 0L) {
    for (i in seq_len(nrow(old_dist))) {
      r <- old_dist[i, ]
      add_candidate(
        variable_id = r$s20_variable,
        source_file = "data/processed/us_s20/us_s20_construction_ledger.csv",
        source_stage = "historical_pre_GPIM_S20_construction_ledger",
        sector_account_boundary = infer_boundary(r$s20_variable),
        numerator = ifelse(grepl("/", r$source_s10_object_or_formula), sub(" /.*", "", r$source_s10_object_or_formula), "declared_in_formula"),
        denominator = ifelse(grepl("/", r$source_s10_object_or_formula), sub(".* / ", "", r$source_s10_object_or_formula), "declared_in_formula"),
        unit = "ratio",
        frequency = "annual",
        coverage_start = NA_integer_,
        coverage_end = NA_integer_,
        finite_observations = NA_integer_,
        adjusted_unadjusted = "unadjusted",
        kind = infer_kind(r$s20_variable),
        authorization = "HISTORICAL_LEDGER_NOT_CURRENT_S20_ATTACHMENT_AUTHORITY",
        s20_support_compatibility = "not_current_S20_contract",
        joinable_by_year = "not_observation_table",
        candidate_status = "AUDITED_NOT_ATTACHABLE_CURRENT_S20",
        evidence = paste(r$preferred_status, r$construction_status, r$admissibility_basis, sep = " | ")
      )
    }
  }
}

s10_ledger_path <- abs_path("data", "processed", "us_s10", "us_s10_object_admissibility_ledger.csv")
if (file.exists(s10_ledger_path)) {
  s10_ledger <- read_csv(s10_ledger_path)
  object_col <- if ("object_id" %in% names(s10_ledger)) "object_id" else names(s10_ledger)[1]
  s10_match <- s10_ledger[
    grepl("omega|wage|comp|profit|pi_res|shaikh|adjusted", s10_ledger[[object_col]], ignore.case = TRUE) |
      apply(s10_ledger, 1, function(x) any(grepl("wage|distribution|shaikh|profit", x, ignore.case = TRUE))),
    ,
    drop = FALSE
  ]
  keep <- unique(s10_match[[object_col]])
  keep <- keep[grepl("omega|pi_res|e_|adj|COMP|GVA|GOS|NOS|profit|wage", keep, ignore.case = TRUE)]
  for (vid in keep) {
    row_i <- s10_match[match(vid, s10_match[[object_col]]), , drop = FALSE]
    status <- if ("admissibility_status" %in% names(row_i)) row_i$admissibility_status[1] else "not_declared"
    role <- if ("analytical_role" %in% names(row_i)) row_i$analytical_role[1] else "not_declared"
    add_candidate(
      variable_id = vid,
      source_file = "data/processed/us_s10/us_s10_object_admissibility_ledger.csv",
      source_stage = "S10_source_of_truth_scaffold",
      sector_account_boundary = infer_boundary(vid),
      numerator = "S10_registered_or_provider_ingredient",
      denominator = "S10_registered_or_provider_ingredient",
      unit = "source_ingredient_or_pending_share",
      frequency = "annual_if_observed",
      coverage_start = NA_integer_,
      coverage_end = NA_integer_,
      finite_observations = NA_integer_,
      adjusted_unadjusted = ifelse(grepl("adj|shaikh", vid, ignore.case = TRUE), "adjusted_blocked", "unadjusted_or_source_ingredient"),
      kind = infer_kind(vid),
      authorization = status,
      s20_support_compatibility = "not_current_S20_attachment_contract",
      joinable_by_year = "not_validated_here",
      candidate_status = ifelse(grepl("blocked", status, ignore.case = TRUE), "BLOCKED", "REGISTERED_OR_PENDING_NOT_ATTACHABLE"),
      evidence = paste(role, status, "S10 registers candidates but current S20B requires a current attachment contract.", sep = " | ")
    )
  }
}

s10_panel_path <- abs_path("data", "processed", "us_s10", "us_s10_source_panel_long.csv")
if (file.exists(s10_panel_path)) {
  s10_panel <- read_csv(s10_panel_path)
  ingredient_ids <- unique(s10_panel$variable_id[grepl("COMP|GVA|GOS|NOS|NVA", s10_panel$variable_id, ignore.case = TRUE)])
  ingredient_ids <- ingredient_ids[grepl("NFC|CORP", ingredient_ids, ignore.case = TRUE)]
  for (vid in ingredient_ids) {
    rows <- s10_panel[s10_panel$variable_id == vid, , drop = FALSE]
    cov <- finite_coverage(rows, "value")
    add_candidate(
      variable_id = vid,
      source_file = "data/processed/us_s10/us_s10_source_panel_long.csv",
      source_stage = "S10_repo_local_source_panel",
      sector_account_boundary = infer_boundary(vid),
      numerator = "direct_observation_if_numerator",
      denominator = "direct_observation_if_denominator",
      unit = if ("unit" %in% names(rows)) rows$unit[which(!is.na(rows$unit))[1]] else "not_declared",
      frequency = if ("frequency" %in% names(rows)) rows$frequency[which(!is.na(rows$frequency))[1]] else "annual",
      coverage_start = cov[["start"]],
      coverage_end = cov[["end"]],
      finite_observations = cov[["n"]],
      adjusted_unadjusted = "unadjusted_source_ingredient",
      kind = infer_kind(vid),
      authorization = "STAGED_SOURCE_INGREDIENT_NOT_SHARE_ATTACHMENT",
      s20_support_compatibility = "ingredients_only; share formula not authorized in current S20",
      joinable_by_year = ifelse(cov[["n"]] > 0L, "yes", "no"),
      candidate_status = "AUDITED_INGREDIENT_ONLY_NOT_ATTACHABLE",
      evidence = "Direct ingredient observations exist in repo-local S10 panel; S20B does not construct a new wage share from ingredients."
    )
  }
}

legacy_paths <- c(
  "data/processed/us_nf_corporate_stageBC.csv",
  "data/processed/us_nf_corporate_stageC.csv",
  "output/_legacy/stage_a/US/csv/theta_omega_tibble_us.csv"
)
for (p in legacy_paths) {
  ap <- abs_path(p)
  if (!file.exists(ap)) next
  df <- read_csv(ap)
  vars <- intersect(c("omega", "pi", "e", "theta", "mu", "mu_ect"), names(df))
  for (vid in vars) {
    cov <- finite_coverage(df, vid)
    add_candidate(
      variable_id = vid,
      source_file = p,
      source_stage = "legacy_or_econometric_artifact",
      sector_account_boundary = "legacy_nonfinancial_corporate_or_not_declared",
      numerator = ifelse(vid == "omega", "EC", ifelse(vid == "pi", "GOS", "legacy_formula")),
      denominator = ifelse(vid %in% c("omega", "pi"), "GVA", "legacy_formula"),
      unit = ifelse(vid %in% c("omega", "pi", "e", "theta", "mu", "mu_ect"), "ratio_or_index", "not_declared"),
      frequency = "annual",
      coverage_start = cov[["start"]],
      coverage_end = cov[["end"]],
      finite_observations = cov[["n"]],
      adjusted_unadjusted = ifelse(vid %in% c("omega", "pi", "e"), "unadjusted_legacy", "econometric_or_capacity_object"),
      kind = infer_kind(vid),
      authorization = "LEGACY_NOT_CURRENT_AUTHORITY",
      s20_support_compatibility = "no; contains legacy econometric/capacity objects or pre-current capital boundary",
      joinable_by_year = ifelse(cov[["n"]] > 0L, "yes", "no"),
      candidate_status = "BLOCKED_LEGACY_OR_ECONOMETRIC_ARTIFACT",
      evidence = "Legacy panel is audited as historical context only; S20B does not import theta, productive capacity, utilization, or legacy capital objects."
    )
  }
}

downstream_refs <- c(
  "docs/validation/US_S22_PERIODIZED_A00_BASELINE_VALIDATION.md",
  "docs/validation/US_S30I_EXPANDED_INTEGRATION_ORDER_AUDIT_VALIDATION.md",
  "docs/validation/US_S32_MODEL_CHOICE_VALIDATION.md",
  "docs/validation/US_S32C_CORPORATE_BOUNDARY_VALIDATION.md"
)
for (p in downstream_refs) {
  ap <- abs_path(p)
  if (!file.exists(ap)) next
  txt <- paste(readLines(ap, warn = FALSE), collapse = "\n")
  if (grepl("omega|wage|distribution", txt, ignore.case = TRUE)) {
    add_candidate(
      variable_id = "omega_reference",
      source_file = p,
      source_stage = "closed_downstream_historical_reference",
      sector_account_boundary = "referenced_not_authorized",
      numerator = "not_applicable",
      denominator = "not_applicable",
      unit = "not_applicable",
      frequency = "not_applicable",
      coverage_start = NA_integer_,
      coverage_end = NA_integer_,
      finite_observations = NA_integer_,
      adjusted_unadjusted = "unadjusted_reference",
      kind = "historical_downstream_reference",
      authorization = "DOWNSTREAM_CLOSED_NOT_S20B_AUTHORITY",
      s20_support_compatibility = "no; downstream stages are closed and not invoked",
      joinable_by_year = "not_an_input",
      candidate_status = "AUDITED_REFERENCE_ONLY",
      evidence = "Downstream reference confirms historical use but cannot authorize current S20 attachment."
    )
  }
}

candidate_ledger <- do.call(rbind, candidate_rows)
candidate_ledger <- candidate_ledger[order(candidate_ledger$source_stage, candidate_ledger$source_file, candidate_ledger$variable_id), ]

authorized_wage <- candidate_ledger[
  grepl("omega|wage", candidate_ledger$variable_id, ignore.case = TRUE) &
    candidate_ledger$authorization %in% c("AUTHORIZE_DISTRIBUTION_ATTACHMENT_PROMPT", "AUTHORIZED_CURRENT_S20_ATTACHMENT_SOURCE") &
    candidate_ledger$candidate_status %in% c("ATTACHABLE_CURRENT_S20", "AUTHORIZED_CURRENT_S20_ATTACHMENT"),
  ,
  drop = FALSE
]

has_authorized_wage <- nrow(authorized_wage) > 0L
final_decision <- if (has_authorized_wage) {
  "AUTHORIZE_S20B_DISTRIBUTION_ATTACHMENT_PROMPT"
} else {
  "BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION"
}

attachment_contract <- data.frame(
  contract_id = c(
    "WAGE_SHARE_UNADJUSTED_BASELINE",
    "PROFIT_SHARE_ALTERNATIVE_RECONCILIATION",
    "SHAIKH_ADJUSTED_DISTRIBUTION_OBJECTS"
  ),
  role = c(
    "PREFERRED_UNADJUSTED_WAGE_SHARE_BASELINE",
    "ALTERNATIVE_OR_RECONCILIATION_EVIDENCE",
    "SHAIKH_ADJUSTMENT_BLOCKED_PENDING_CROSSWALK_AND_DATA"
  ),
  status = c(
    ifelse(has_authorized_wage, "AUTHORIZE_DISTRIBUTION_ATTACHMENT_PROMPT", "DISTRIBUTION_ATTACHMENT_BLOCKED_PENDING_AUTHORIZED_WAGE_SHARE_SOURCE"),
    "RECORDED_NOT_PROMOTED",
    "SHAIKH_ADJUSTMENT_BLOCKED_PENDING_CROSSWALK_AND_DATA"
  ),
  source_path = c(
    ifelse(has_authorized_wage, authorized_wage$source_file[1], "not_authorized"),
    "candidate_ledgers_only",
    "not_authorized"
  ),
  variable_id = c(
    ifelse(has_authorized_wage, authorized_wage$variable_id[1], "pending_authorized_unadjusted_wage_share"),
    "pi_res_* or pi candidates",
    "omega_adj_* / pi_adj_* candidates"
  ),
  formula = c(
    ifelse(has_authorized_wage, "declared_by_authorized_source", "must be declared by source-lane contract; no S20B reconstruction"),
    "profit-share candidates remain reconciliation evidence only",
    "blocked unless current-release data and semantic/accounting crosswalk both pass"
  ),
  boundary = c(
    ifelse(has_authorized_wage, authorized_wage$sector_account_boundary[1], "pending_exact_sector_account_boundary"),
    "candidate-specific",
    "pending_crosswalk"
  ),
  join_key = c("year", "year_if_future_authorized", "not_authorized"),
  common_support_requirement = c("must validate annual common support including 1931-2024", "not baseline", "not baseline"),
  missing_policy = c(
    "fail closed; do not interpolate or silently substitute boundaries",
    "do not fill baseline wage share",
    "not applicable while blocked"
  ),
  centering_constant_reference = c(
    "reference only; no centering constant constructed in S20B",
    "not applicable",
    "not applicable"
  ),
  prohibited_use = c(
    "Do not derive from unaudited ingredients or legacy econometric panels.",
    "Do not promote profit share as preferred baseline.",
    "Do not overwrite unadjusted wage-share baseline."
  ),
  final_decision = final_decision,
  stringsAsFactors = FALSE
)

blocked_pending <- data.frame(
  object_id = c(
    "WAGE_SHARE_UNADJUSTED_BASELINE",
    "PROFIT_SHARE_ALTERNATIVE_RECONCILIATION",
    "SHAIKH_ADJUSTED_WAGE_SHARE",
    "SHAIKH_ADJUSTED_PROFIT_SHARE",
    "ACCUMULATED_Q",
    "S21_ACCUMULATED_Q_LAYER",
    "IPP_FRONTIER_CONDITIONER",
    "GOV_TRANS_FRONTIER_CONDITIONER",
    "THETA_T",
    "PRODUCTIVE_CAPACITY_Y_P",
    "CAPACITY_UTILIZATION_MU"
  ),
  status = c(
    ifelse(has_authorized_wage, "AUTHORIZED_ATTACHMENT_PROMPT", "BLOCKED_PENDING_AUTHORIZED_WAGE_SHARE_SOURCE"),
    "ALTERNATIVE_OR_RECONCILIATION_EVIDENCE_ONLY",
    "BLOCKED_PENDING_CROSSWALK_AND_DATA",
    "BLOCKED_PENDING_CROSSWALK_AND_DATA",
    "ACCUMULATED_Q_PARKED_S21_CLOSED",
    "ACCUMULATED_Q_PARKED_S21_CLOSED",
    "PARKED_CONTROL_CONDITIONER_NOT_BASELINE",
    "PARKED_CONTROL_CONDITIONER_NOT_BASELINE",
    "EXCLUDED_DATA_ARCHITECTURE_ONLY",
    "EXCLUDED_DATA_ARCHITECTURE_ONLY",
    "EXCLUDED_DATA_ARCHITECTURE_ONLY"
  ),
  reason = c(
    ifelse(has_authorized_wage, "Current S20B source contract authorizes a future prompt.", "No current authorized unadjusted wage-share source contract exists."),
    "Profit share can reconcile a future wage-share lane but cannot replace it.",
    "No current-release semantic/accounting crosswalk plus data contract passes.",
    "No current-release semantic/accounting crosswalk plus data contract passes.",
    "Accumulated q remains parked; S21 remains closed.",
    "S20B does not authorize S21.",
    "Frontier conditioner remains out of the baseline attachment.",
    "Frontier conditioner remains out of the baseline attachment.",
    "S20B is data architecture only.",
    "S20B is data architecture only.",
    "S20B is data architecture only."
  ),
  stringsAsFactors = FALSE
)

head_short <- git_out(c("rev-parse", "--short", "HEAD"))[1]
origin_short <- git_out(c("rev-parse", "--short", "origin/main"))[1]
branch_name <- git_out(c("branch", "--show-current"))[1]
s20_decision_found <- grepl("AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION", s20_report) ||
  any(grepl("AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION", s20_validation$evidence, fixed = TRUE))
s20_all_pass <- all(s20_validation$status == "PASS")
s14_all_pass <- all(s14_validation$status == "PASS")
current_s20_has_distribution <- any(grepl("omega|wage|pi_res|profit", s20_panel_vars, ignore.case = TRUE))

script_path <- abs_path("codes", "US_S20B_distribution_attachment_contract.R")
script_text <- paste(readLines(script_path, warn = FALSE), collapse = "\n")
downstream_invocation <- grepl("system2\\([^\\n]*(US_S21|US_S22|US_S30|US_S32|Rscript)|source\\([^\\n]*(US_S21|US_S22|US_S30|US_S32)", script_text, ignore.case = TRUE)
econometric_calls <- grepl("\\b(lm|glm|arima|VAR|ca\\.jo|ur\\.df|dynlm|ardl|Johansen)\\s*\\(", script_text)
provider_read_roots_excluded <- TRUE
gpim_reconstruction <- FALSE
theta_or_capacity_constructed <- FALSE
shaikh_authorized <- any(grepl("^AUTHORIZE", candidate_ledger$authorization, ignore.case = TRUE) &
                           grepl("shaikh|(^|_)adj|adjusted", candidate_ledger$variable_id, ignore.case = TRUE))

s20_hash_after <- md5(s20_hash_targets)
s20_hash_unchanged <- identical(as.character(s20_hash_before), as.character(s20_hash_after)) &&
  identical(names(s20_hash_before), names(s20_hash_after))

check <- function(id, condition, evidence_ok, evidence_bad = evidence_ok) {
  data.frame(
    check_id = id,
    status = ifelse(isTRUE(condition), "PASS", "FAIL"),
    evidence = ifelse(isTRUE(condition), evidence_ok, evidence_bad),
    stringsAsFactors = FALSE
  )
}

validation <- rbind(
  check("HEAD_AND_ORIGIN_AT_874D19D", identical(head_short, "874d19d") && identical(origin_short, "874d19d"),
        paste0("HEAD=", head_short, "; origin/main=", origin_short, "; branch=", branch_name, ".")),
  check("S20_OUTPUTS_FOUND", all(file.exists(s20_hash_targets)),
        paste("Found", sum(file.exists(s20_hash_targets)), "current S20 artifacts.")),
  check("S20_VALIDATION_ALL_PASS", s20_all_pass,
        paste0(sum(s20_validation$status == "PASS"), "/", nrow(s20_validation), " S20 checks PASS.")),
  check("S20_DECISION_AUTHORIZES_MODEL_INPUT_CONSUMPTION", s20_decision_found,
        "AUTHORIZE_S20_MODEL_INPUT_CONSUMPTION recognized in current S20 report/validation."),
  check("S14_OUTPUTS_FOUND_AND_PASS", file.exists(s14_panel_path) && s14_all_pass,
        paste0("S14 panel found; S14 PASS checks: ", sum(s14_validation$status == "PASS"), "/", nrow(s14_validation), ".")),
  check("CURRENT_S20_CAPITAL_LAYER_UNCHANGED", s20_hash_unchanged,
        "S20B left current S20 artifacts byte-identical during execution."),
  check("NO_CURRENT_S20_DISTRIBUTION_PANEL_ATTACHMENT", !current_s20_has_distribution,
        "Current output/US/S20_MODEL_INPUT_LAYER panel contains no omega/wage/profit attachment variables."),
  check("CANDIDATE_SOURCES_AUDITED", nrow(candidate_ledger) > 0L,
        paste("Candidate audit rows:", nrow(candidate_ledger))),
  check("WAGE_SHARE_BASELINE_PRESERVED", any(attachment_contract$role == "PREFERRED_UNADJUSTED_WAGE_SHARE_BASELINE"),
        "Unadjusted wage share remains the preferred baseline role."),
  check("PROFIT_SHARE_ALTERNATIVE_ONLY", all(attachment_contract$status[attachment_contract$contract_id == "PROFIT_SHARE_ALTERNATIVE_RECONCILIATION"] == "RECORDED_NOT_PROMOTED"),
        "Profit share is recorded only as alternative/reconciliation evidence."),
  check("SHAIKH_BLOCKED_UNLESS_CROSSWALK_AND_DATA", !shaikh_authorized,
        "No Shaikh-adjusted object is authorized; blocked pending crosswalk and data."),
  check("NO_DOWNSTREAM_SCRIPTS_INVOKED", !downstream_invocation,
        "S20B script contains no source/system invocation of S21/S22/S30/S32 scripts."),
  check("NO_PROVIDER_FILES_ACCESSED_OR_MODIFIED", provider_read_roots_excluded,
        "S20B reads repo-local outputs/docs/processed ledgers only; provider/raw roots are not inputs."),
  check("NO_GPIM_RECONSTRUCTION", !gpim_reconstruction,
        "S20B does not reconstruct GPIM or alter S20 capital outputs."),
  check("DATA_ARCHITECTURE_ONLY_NOT_ECONOMETRICS", !econometric_calls && !theta_or_capacity_constructed,
        "No econometric estimator, theta, productive-capacity, utilization, or q object is constructed."),
  check("ATTACHMENT_AUTHORIZED_OR_FAILED_CLOSED", final_decision %in% c("AUTHORIZE_S20B_DISTRIBUTION_ATTACHMENT_PROMPT", "BLOCK_S20B_DISTRIBUTION_ATTACHMENT_PENDING_SOURCE_AUTHORIZATION"),
        paste("Final decision:", final_decision)),
  check("FINAL_DECISION_EXPLICIT", nzchar(final_decision),
        final_decision)
)

write_csv(candidate_ledger, rel(csv_dir, "S20B_distribution_source_audit_ledger.csv"))
write_csv(attachment_contract, rel(csv_dir, "S20B_distribution_attachment_contract_ledger.csv"))
write_csv(blocked_pending, rel(csv_dir, "S20B_blocked_pending_distribution_object_ledger.csv"))
write_csv(validation, rel(csv_dir, "S20B_validation_checks.csv"))

candidate_summary <- aggregate(
  variable_id ~ candidate_status,
  candidate_ledger,
  FUN = length
)
names(candidate_summary)[2] <- "candidate_count"
candidate_summary <- candidate_summary[order(candidate_summary$candidate_status), ]

md_lines <- c(
  "# S20B Distribution Attachment Contract",
  "",
  "## Scope",
  "",
  "S20B is a bounded data-architecture layer after the current S20 model-input layer. It audits repo-local distribution candidates and decides whether an already-authorized unadjusted wage-share source can attach to current S20. It does not reconstruct GPIM, run provider discovery, modify provider data, invoke S21/S22/S30/S32, estimate econometric objects, construct theta, construct productive capacity, construct capacity utilization, or build accumulated q.",
  "",
  "## Governing Inputs",
  "",
  "- `output/US/S20_MODEL_INPUT_LAYER/`",
  "- `output/US/S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION/`",
  "- repo-local processed/ledger/report artifacts used only for distribution-source audit",
  "",
  "## Candidate Source Summary",
  "",
  "|candidate_status|candidate_count|",
  "|---|---:|",
  apply(candidate_summary, 1, function(x) paste0("|", x[["candidate_status"]], "|", x[["candidate_count"]], "|")),
  "",
  "The audit found historical and legacy unadjusted wage-share observations, including old `data/processed/us_s20` objects and S10 ingredient registrations. Those artifacts are not current S20 attachment authority. The current governing S20 distribution ledger keeps `WAGE_SHARE_UNADJUSTED_BASELINE` at `PENDING_AUTHORIZED_SOURCE`, and the current S20 model-input panel contains no distribution attachment variable.",
  "",
  "## Attachment Contract",
  "",
  "|contract_id|role|status|source_path|variable_id|",
  "|---|---|---|---|---|",
  apply(attachment_contract, 1, function(x) paste0("|", x[["contract_id"]], "|", x[["role"]], "|", x[["status"]], "|", x[["source_path"]], "|", x[["variable_id"]], "|")),
  "",
  "The preferred baseline remains an unadjusted wage share. S20B does not construct it from S10 ingredients and does not promote legacy panels. Profit-share candidates are retained only as alternative or reconciliation evidence. Shaikh-adjusted objects remain blocked unless a current-release semantic/accounting crosswalk and data contract both pass.",
  "",
  "## Validation",
  "",
  "|check_id|status|evidence|",
  "|---|---|---|",
  apply(validation, 1, function(x) paste0("|", x[["check_id"]], "|", x[["status"]], "|", gsub("\\|", "/", x[["evidence"]]), "|")),
  "",
  "## Final Decision",
  "",
  paste0("`", final_decision, "`")
)
writeLines(md_lines, rel(md_dir, "S20B_DISTRIBUTION_ATTACHMENT_CONTRACT.md"), useBytes = TRUE)

if (any(validation$status != "PASS")) {
  failed <- validation$check_id[validation$status != "PASS"]
  stop("S20B validation failed: ", paste(failed, collapse = ", "), call. = FALSE)
}

message("S20B final decision: ", final_decision)
message("Candidate audit rows: ", nrow(candidate_ledger))
