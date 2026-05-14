###############################################################################
# US_S30_formal_stability_adjudication.R
# Chapter 2 - bounded US S30 formal stability adjudication
#
# Role:
#   Adjudicates whether the existing S30 transformation-relation outputs open a
#   restricted B1 pathway into S40.
#
# Guardrails:
#   - Consumes existing S30 outputs only.
#   - Does not expand the estimator grid.
#   - Does not create S40 code.
#   - Does not reconstruct productive capacity.
#   - Does not compute capacity utilization or mu.
#   - Does not produce profitability outputs.
#   - Does not touch Chile outputs.
###############################################################################

# ---- 0. Paths and required files --------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")

out_dir <- file.path(REPO, "output/US/S30_transformation_relation")

required_inputs <- c(
  estimator_grid = "us_s30_estimator_grid.csv",
  window_stability_summary = "us_s30_window_stability_summary.csv",
  rolling_coefficients = "us_s30_rolling_coefficients.csv",
  specification_register = "us_s30_specification_register.csv",
  candidate_window_register_used = "us_s30_candidate_window_register_used.csv",
  run_manifest = "us_s30_run_manifest.csv"
)

input_paths <- file.path(out_dir, required_inputs)
names(input_paths) <- names(required_inputs)

disposition_path <- file.path(out_dir, "us_s30_formal_spec_disposition.csv")
hansen_path <- file.path(out_dir, "us_s30_hansen_stability_tests.csv")
gh_path <- file.path(out_dir, "us_s30_gregory_hansen_stress.csv")
decision_path <- file.path(out_dir, "us_s30_formal_stability_decision.csv")
report_path <- file.path(out_dir, "US_S30_formal_stability_adjudication_report.md")
manifest_path <- file.path(out_dir, "us_s30_formal_stability_manifest.csv")

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

adjudication_warnings <- character(0)

add_warning <- function(msg) {
  adjudication_warnings <<- unique(c(adjudication_warnings, msg))
  warning(msg, call. = FALSE)
}

# ---- 1. Helpers --------------------------------------------------------------
read_csv_base <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_csv_base <- function(df, path) {
  utils::write.csv(df, path, row.names = FALSE, na = "")
}

require_cols <- function(df, cols, object_name) {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0L) {
    stop(
      object_name, " is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

as_bool <- function(x) {
  if (is.logical(x)) return(x)
  y <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(y))
  out[y %in% c("true", "t", "1", "yes", "y")] <- TRUE
  out[y %in% c("false", "f", "0", "no", "n")] <- FALSE
  out
}

as_num <- function(x) suppressWarnings(as.numeric(x))

collapse_or_na <- function(x) {
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x) == 0L) return(NA_character_)
  paste(unique(x), collapse = "; ")
}

bool_text <- function(x) {
  if (length(x) == 0L || is.na(x)) return(NA_character_)
  if (isTRUE(x)) "TRUE" else "FALSE"
}

safe_all_true <- function(x) {
  x <- as_bool(x)
  length(x) > 0L && all(x %in% TRUE)
}

safe_no_true <- function(x) {
  x <- as_bool(x)
  length(x) > 0L && !any(x %in% TRUE)
}

safe_min <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  min(x)
}

safe_max <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  max(x)
}

safe_mean <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  mean(x)
}

safe_median <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  stats::median(x)
}

safe_sd <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) < 2L) return(NA_real_)
  stats::sd(x)
}

sign_clean <- function(x, tol = 1e-8) {
  x <- as_num(x)
  if (length(x) == 0L || !is.finite(x[1L]) || abs(x[1L]) <= tol) return(0L)
  if (x[1L] > 0) 1L else -1L
}

count_sign_reversals <- function(x) {
  s <- vapply(as_num(x), sign_clean, integer(1))
  s <- s[s != 0L]
  if (length(s) < 2L) return(0L)
  sum(s[-1L] != s[-length(s)])
}

has_both_signs <- function(x) {
  s <- unique(vapply(as_num(x), sign_clean, integer(1)))
  any(s == 1L) && any(s == -1L)
}

package_available <- function(package) {
  suppressPackageStartupMessages(
    suppressWarnings(requireNamespace(package, quietly = TRUE))
  )
}

function_available <- function(package, function_name) {
  if (!package_available(package)) return(FALSE)
  exists(function_name, envir = asNamespace(package), mode = "function", inherits = FALSE)
}

md_table <- function(df, n = Inf) {
  if (is.null(df) || nrow(df) == 0L) return("_No rows._")
  df <- head(df, n)
  df[] <- lapply(df, function(x) {
    if (is.numeric(x)) {
      ifelse(is.na(x), "", formatC(x, digits = 4, format = "fg"))
    } else {
      y <- as.character(x)
      y[is.na(y)] <- ""
      y
    }
  })
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1L, function(z) paste0("| ", paste(z, collapse = " | "), " |"))
  c(header, sep, rows)
}

# ---- 2. Read and validate inputs --------------------------------------------
input_detected <- file.exists(input_paths)
if (!all(input_detected)) {
  missing <- names(input_paths)[!input_detected]
  stop(
    "Missing required S30 input file(s): ",
    paste(required_inputs[missing], collapse = ", "),
    call. = FALSE
  )
}

estimator_grid <- read_csv_base(input_paths[["estimator_grid"]])
stability_summary <- read_csv_base(input_paths[["window_stability_summary"]])
rolling_coefficients <- read_csv_base(input_paths[["rolling_coefficients"]])
spec_register <- read_csv_base(input_paths[["specification_register"]])
window_register <- read_csv_base(input_paths[["candidate_window_register_used"]])
run_manifest <- read_csv_base(input_paths[["run_manifest"]])

require_cols(
  estimator_grid,
  c(
    "window_id", "estimator", "spec_id", "coefficient", "estimate",
    "status", "estimator_status", "year_start", "year_end", "n_effective"
  ),
  "us_s30_estimator_grid.csv"
)
require_cols(
  stability_summary,
  c(
    "window_id", "window_role", "year_start", "year_end", "spec_id",
    "fm_ols_ok", "im_ols_ok", "dols_ok",
    "im_ols_overturns_fm_sign_pattern",
    "dols_catastrophic_contradiction",
    "neighborhood_reversal_count", "severe_collinearity_flag",
    "rolling_proxy_reversal_count"
  ),
  "us_s30_window_stability_summary.csv"
)
require_cols(
  rolling_coefficients,
  c(
    "rolling_window_start", "rolling_window_end", "estimator",
    "spec_id", "coefficient", "estimate", "status"
  ),
  "us_s30_rolling_coefficients.csv"
)
require_cols(
  spec_register,
  c(
    "spec_id", "formula_label", "regressors", "promotion_eligible",
    "diagnostic_only", "role"
  ),
  "us_s30_specification_register.csv"
)
require_cols(
  window_register,
  c("window_id", "year_start", "year_end", "role", "available"),
  "us_s30_candidate_window_register_used.csv"
)
require_cols(run_manifest, c("item", "value"), "us_s30_run_manifest.csv")

# ---- 3. Formal specification disposition ------------------------------------
formal_disposition_map <- data.frame(
  spec_id = c(
    "SPEC_B0_CAPITAL_ONLY",
    "SPEC_B1_WAGE_BASELINE",
    "SPEC_C1_COMPOSITION_STOCK",
    "SPEC_C2_FULL_COMPOSITION",
    "SPEC_D1_CURRENT_COST_DIAGNOSTIC",
    "SPEC_D2_PRICE_WEDGE_DIAGNOSTIC"
  ),
  formal_short_label = c("B0", "B1", "C1", "C2", "D1", "D2"),
  formal_disposition = c(
    "supporting_benchmark_only",
    "restricted_s40_pathway_candidate",
    "mechanism_evidence_only",
    "diagnostic_only",
    "diagnostic_only",
    "diagnostic_only"
  ),
  under_formal_evaluation = c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  restricted_s40_candidate = c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  formal_promotion_allowed = c(FALSE, TRUE, FALSE, FALSE, FALSE, FALSE),
  formal_notes = c(
    "B0 is retained only as a supporting benchmark contrast.",
    "B1 is the only formally admissible restricted S40-pathway candidate.",
    "C1 can inform mechanism evidence but cannot open the S40 pathway.",
    "C2 is diagnostic-only and cannot open the S40 pathway.",
    "D1 is diagnostic-only and cannot open the S40 pathway.",
    "D2 is diagnostic-only and cannot open the S40 pathway."
  ),
  stringsAsFactors = FALSE
)

spec_disposition <- merge(
  formal_disposition_map,
  spec_register,
  by = "spec_id",
  all.x = TRUE,
  sort = FALSE
)
spec_disposition <- spec_disposition[match(formal_disposition_map$spec_id, spec_disposition$spec_id), ]
spec_disposition$input_spec_detected <- !is.na(spec_disposition$formula_label)
spec_disposition$input_promotion_eligible <- as_bool(spec_disposition$promotion_eligible)
spec_disposition$input_diagnostic_only <- as_bool(spec_disposition$diagnostic_only)
spec_disposition <- spec_disposition[
  ,
  c(
    "formal_short_label", "spec_id", "formula_label", "regressors", "role",
    "input_spec_detected", "input_promotion_eligible", "input_diagnostic_only",
    "formal_disposition", "under_formal_evaluation",
    "restricted_s40_candidate", "formal_promotion_allowed", "formal_notes"
  ),
  drop = FALSE
]

write_csv_base(spec_disposition, disposition_path)

# ---- 4. Tier 1 B1 object admissibility --------------------------------------
b1_spec_id <- "SPEC_B1_WAGE_BASELINE"
b1_stability <- stability_summary[stability_summary$spec_id == b1_spec_id, , drop = FALSE]
b1_grid <- estimator_grid[estimator_grid$spec_id == b1_spec_id, , drop = FALSE]

if (nrow(b1_stability) == 0L) {
  add_warning("B1 stability rows were not found in us_s30_window_stability_summary.csv.")
}
if (nrow(b1_grid) == 0L) {
  add_warning("B1 estimator rows were not found in us_s30_estimator_grid.csv.")
}

b1_under_evaluation <- any(
  spec_disposition$spec_id == b1_spec_id &
    as_bool(spec_disposition$under_formal_evaluation)
)

b1_severe_collinearity_detected <- nrow(b1_stability) > 0L &&
  any(as_bool(b1_stability$severe_collinearity_flag) %in% TRUE)
b1_no_severe_collinearity <- !isTRUE(b1_severe_collinearity_detected)

b1_fm_ols_available <- nrow(b1_stability) > 0L && all(as_bool(b1_stability$fm_ols_ok), na.rm = TRUE)
b1_im_ols_available <- nrow(b1_stability) > 0L && all(as_bool(b1_stability$im_ols_ok), na.rm = TRUE)
b1_im_ols_contradicts_fm <- nrow(b1_stability) > 0L &&
  any(as_bool(b1_stability$im_ols_overturns_fm_sign_pattern) %in% TRUE)
b1_fm_im_noncontradictory <- !isTRUE(b1_im_ols_contradicts_fm)

b1_dols_rows <- b1_stability[as_bool(b1_stability$dols_ok) %in% TRUE, , drop = FALSE]
b1_surviving_dols_count <- nrow(b1_dols_rows)
b1_surviving_dols_noncontradictory <- if (b1_surviving_dols_count == 0L) {
  NA
} else {
  !any(as_bool(b1_dols_rows$dols_catastrophic_contradiction) %in% TRUE)
}

b1_dols_contradiction_count <- if (b1_surviving_dols_count == 0L) {
  0L
} else {
  sum(as_bool(b1_dols_rows$dols_catastrophic_contradiction) %in% TRUE)
}

b1_dols_contradiction_windows <- if (b1_dols_contradiction_count == 0L) {
  NA_character_
} else {
  collapse_or_na(b1_dols_rows$window_id[as_bool(b1_dols_rows$dols_catastrophic_contradiction) %in% TRUE])
}

dols_fragility_flag <- b1_dols_contradiction_count > 0L
dols_veto <- FALSE
dols_contradiction_note <- if (isTRUE(dols_fragility_flag)) {
  paste0(
    "Surviving DOLS stress diagnostic contradicts FM-OLS/IM-OLS evidence",
    if (!is.na(b1_dols_contradiction_windows)) {
      paste0(" in window(s): ", b1_dols_contradiction_windows)
    } else {
      ""
    },
    ". Under the locked R09 rule, DOLS is recorded as a fragility diagnostic",
    " only and cannot veto Tier 1 or independently block S40."
  )
} else if (b1_surviving_dols_count > 0L) {
  "No surviving DOLS contradiction is detected; DOLS remains a non-veto fragility diagnostic under R09."
} else {
  "No surviving DOLS estimate is available; DOLS remains a non-veto fragility diagnostic under R09."
}

tier1_estimator_triangulation_noncontradictory <- isTRUE(b1_fm_im_noncontradictory)

tier1_pass <- isTRUE(b1_under_evaluation) &&
  isTRUE(b1_no_severe_collinearity) &&
  isTRUE(tier1_estimator_triangulation_noncontradictory)

# ---- 5. Tier 2 Hansen-type/proxy stability evidence -------------------------
package_rows <- data.frame(
  package = c("cointReg", "strucchange", "urca", "tseries"),
  function_name = c("cointRegFM", "efp", "ca.po", "adf.test"),
  diagnostic_role = c(
    "S30 estimator provenance",
    "generic parameter-instability tools",
    "cointegration test helper, not Gregory-Hansen",
    "unit-root helper, not formal S30 adjudication"
  ),
  package_available = c(
    package_available("cointReg"),
    package_available("strucchange"),
    package_available("urca"),
    package_available("tseries")
  ),
  function_available = c(
    function_available("cointReg", "cointRegFM"),
    function_available("strucchange", "efp"),
    function_available("urca", "ca.po"),
    function_available("tseries", "adf.test")
  ),
  stringsAsFactors = FALSE
)

b1_key_coefficient <- "omega_k_t"
b1_roll <- rolling_coefficients[
  rolling_coefficients$spec_id == b1_spec_id &
    rolling_coefficients$coefficient == b1_key_coefficient &
    rolling_coefficients$status == "estimated",
  ,
  drop = FALSE
]
b1_roll <- b1_roll[order(as_num(b1_roll$rolling_window_start), as_num(b1_roll$rolling_window_end)), ]

exact_hansen_implementable <- FALSE
exact_hansen_status <- paste(
  "unavailable_exact_test_requires_raw_cointegrating_regression_objects;",
  "current script is bounded to S30 output tables"
)

rolling_proxy_available <- nrow(b1_roll) > 0L
rolling_sign_reversal_count <- if (rolling_proxy_available) {
  count_sign_reversals(b1_roll$estimate)
} else {
  NA_integer_
}
rolling_has_both_signs <- if (rolling_proxy_available) {
  has_both_signs(b1_roll$estimate)
} else {
  NA
}

b1_stability_reversal_values <- as_num(b1_stability$rolling_proxy_reversal_count)
b1_stability_reversal_values <- b1_stability_reversal_values[is.finite(b1_stability_reversal_values)]
summary_proxy_reversal_count <- if (length(b1_stability_reversal_values) == 0L) {
  NA_integer_
} else {
  as.integer(max(b1_stability_reversal_values))
}

tier2_evidence_class <- if (!rolling_proxy_available && !exact_hansen_implementable) {
  "unavailable"
} else if (
  isTRUE(rolling_proxy_available) &&
    isFALSE(rolling_has_both_signs) &&
    (is.na(summary_proxy_reversal_count) || summary_proxy_reversal_count == 0L)
) {
  "supportive"
} else if (
  isTRUE(rolling_proxy_available) &&
    (isTRUE(rolling_has_both_signs) ||
       (is.finite(summary_proxy_reversal_count) && summary_proxy_reversal_count > 0L))
) {
  "mixed"
} else {
  "contradictory"
}

hansen_tests <- data.frame(
  test_id = "B1_HANSEN_TYPE_ROLLING_PROXY",
  spec_id = b1_spec_id,
  coefficient = b1_key_coefficient,
  exact_or_proxy_status = if (exact_hansen_implementable) {
    "exact"
  } else if (rolling_proxy_available) {
    "proxy_from_existing_s30_rolling_coefficients"
  } else {
    "unavailable"
  },
  exact_hansen_implementable = exact_hansen_implementable,
  proxy_implemented = rolling_proxy_available,
  diagnostic_method = paste(
    "Hansen-type parameter-instability audit is proxied by the existing",
    "S30 rolling FM-OLS coefficient path; no new estimator grid is run."
  ),
  package_function_basis = "base R over S30 rolling-coefficient output",
  rolling_windows = nrow(b1_roll),
  rolling_start_min = safe_min(b1_roll$rolling_window_start),
  rolling_end_max = safe_max(b1_roll$rolling_window_end),
  estimate_min = safe_min(b1_roll$estimate),
  estimate_max = safe_max(b1_roll$estimate),
  estimate_mean = safe_mean(b1_roll$estimate),
  estimate_median = safe_median(b1_roll$estimate),
  estimate_sd = safe_sd(b1_roll$estimate),
  rolling_adjacent_sign_reversal_count = rolling_sign_reversal_count,
  summary_proxy_reversal_count = summary_proxy_reversal_count,
  both_positive_and_negative_estimates = rolling_has_both_signs,
  evidence_class = tier2_evidence_class,
  notes = exact_hansen_status,
  stringsAsFactors = FALSE
)

write_csv_base(hansen_tests, hansen_path)

# ---- 6. Tier 3 Gregory-Hansen stress diagnostic -----------------------------
gregory_hansen_function_available <- FALSE

gh_stress <- data.frame(
  test_id = "B1_GREGORY_HANSEN_ONE_BREAK_STRESS",
  spec_id = b1_spec_id,
  diagnostic_scope = "optional_one_break_diagnostic_only",
  implementation_status = "not_implemented",
  evidence_class = "unavailable",
  package_function_available = gregory_hansen_function_available,
  windows_redefined = FALSE,
  non_b1_specs_promoted = FALSE,
  s40_gate_effect = "none",
  notes = paste(
    "Not implemented because the bounded adjudication consumes S30 output",
    "tables rather than the raw cointegrating-regression panel required for",
    "an endogenous one-break Gregory-Hansen search."
  ),
  stringsAsFactors = FALSE
)

write_csv_base(gh_stress, gh_path)

# ---- 7. Decision logic -------------------------------------------------------
s40_gate <- if (isTRUE(tier1_pass) && identical(tier2_evidence_class, "supportive")) {
  "pass_restricted"
} else if (isTRUE(tier1_pass) && identical(tier2_evidence_class, "mixed")) {
  "pass_restricted_fragility_flag"
} else {
  "blocked"
}

fragility_flag <- isTRUE(dols_fragility_flag) ||
  identical(s40_gate, "pass_restricted_fragility_flag") ||
  !isTRUE(tier1_pass) ||
  !identical(tier2_evidence_class, "supportive")

gate_reason <- if (identical(s40_gate, "blocked")) {
  if (!isTRUE(b1_under_evaluation)) {
    "Tier 1 failed: B1 is not under formal evaluation."
  } else if (!isTRUE(b1_no_severe_collinearity)) {
    "Tier 1 failed: B1 has at least one severe collinearity flag."
  } else if (!isTRUE(tier1_estimator_triangulation_noncontradictory)) {
    "Tier 1 failed: IM-OLS substantively contradicts FM-OLS."
  } else {
    paste0("Tier 2 evidence is ", tier2_evidence_class, ".")
  }
} else if (identical(s40_gate, "pass_restricted_fragility_flag")) {
  "Tier 1 passes, but Tier 2 stability evidence is mixed; S40 can proceed only as restricted B1 with a Tier 2 fragility flag."
} else {
  paste(
    "Tier 1 passes and Tier 2 stability evidence is supportive; S40 can",
    "proceed only as restricted B1. DOLS is recorded separately as a",
    "non-veto fragility diagnostic."
  )
}

decision <- data.frame(
  run_timestamp = RUN_TIMESTAMP,
  candidate_spec_id = b1_spec_id,
  tier1_b1_under_evaluation = b1_under_evaluation,
  tier1_no_severe_collinearity = b1_no_severe_collinearity,
  tier1_fm_ols_available_all_b1_windows = b1_fm_ols_available,
  tier1_im_ols_available_all_b1_windows = b1_im_ols_available,
  tier1_im_ols_contradicts_fm = b1_im_ols_contradicts_fm,
  tier1_fm_im_noncontradictory = b1_fm_im_noncontradictory,
  tier1_surviving_dols_count = b1_surviving_dols_count,
  tier1_surviving_dols_noncontradictory = b1_surviving_dols_noncontradictory,
  tier1_surviving_dols_contradiction_count = b1_dols_contradiction_count,
  tier1_surviving_dols_contradiction_windows = b1_dols_contradiction_windows,
  dols_fragility_flag = dols_fragility_flag,
  dols_veto = dols_veto,
  dols_contradiction_note = dols_contradiction_note,
  tier1_estimator_triangulation_noncontradictory =
    tier1_estimator_triangulation_noncontradictory,
  tier1_pass = tier1_pass,
  tier2_test_id = hansen_tests$test_id[1L],
  tier2_exact_or_proxy_status = hansen_tests$exact_or_proxy_status[1L],
  tier2_evidence_class = tier2_evidence_class,
  tier3_test_id = gh_stress$test_id[1L],
  tier3_implementation_status = gh_stress$implementation_status[1L],
  tier3_evidence_class = gh_stress$evidence_class[1L],
  s40_gate = s40_gate,
  fragility_flag = fragility_flag,
  gate_reason = gate_reason,
  non_b1_specs_promoted = FALSE,
  no_s40_code = TRUE,
  no_mu_computation = TRUE,
  no_chile_outputs = TRUE,
  stringsAsFactors = FALSE
)

write_csv_base(decision, decision_path)

# ---- 8. Manifest -------------------------------------------------------------
input_manifest_rows <- data.frame(
  item = paste0("input_detected_", names(required_inputs)),
  value = as.character(input_detected),
  stringsAsFactors = FALSE
)

input_path_rows <- data.frame(
  item = paste0("input_path_", names(required_inputs)),
  value = unname(input_paths),
  stringsAsFactors = FALSE
)

output_rows <- data.frame(
  item = paste0(
    "output_",
    c(
      "formal_spec_disposition",
      "hansen_stability_tests",
      "gregory_hansen_stress",
      "formal_stability_decision",
      "formal_stability_adjudication_report",
      "formal_stability_manifest"
    )
  ),
  value = c(
    disposition_path,
    hansen_path,
    gh_path,
    decision_path,
    report_path,
    manifest_path
  ),
  stringsAsFactors = FALSE
)

package_manifest_rows <- do.call(
  rbind,
  lapply(seq_len(nrow(package_rows)), function(i) {
    data.frame(
      item = c(
        paste0("package_available_", package_rows$package[i]),
        paste0("function_available_", package_rows$package[i], "::", package_rows$function_name[i])
      ),
      value = c(
        as.character(package_rows$package_available[i]),
        as.character(package_rows$function_available[i])
      ),
      stringsAsFactors = FALSE
    )
  })
)

manifest <- rbind(
  data.frame(
    item = c(
      "script",
      "run_timestamp",
      "output_dir",
      "bounded_to_existing_s30_outputs",
      "no_estimator_grid_expansion",
      "no_s40_code",
      "no_productive_capacity_reconstruction",
      "no_mu_computation",
      "no_profitability_outputs",
      "no_chile_outputs",
      "b1_only_restricted_s40_candidate",
      "dols_fragility_flag",
      "dols_veto",
      "tier2_evidence_class",
      "s40_gate",
      "warnings"
    ),
    value = c(
      "codes/US_S30_formal_stability_adjudication.R",
      RUN_TIMESTAMP,
      out_dir,
      "TRUE",
      "TRUE",
      "TRUE",
      "TRUE",
      "TRUE",
      "TRUE",
      "TRUE",
      "TRUE",
      as.character(dols_fragility_flag),
      as.character(dols_veto),
      tier2_evidence_class,
      s40_gate,
      if (length(adjudication_warnings) == 0L) "none" else paste(adjudication_warnings, collapse = "; ")
    ),
    stringsAsFactors = FALSE
  ),
  input_manifest_rows,
  input_path_rows,
  package_manifest_rows,
  output_rows
)

write_csv_base(manifest, manifest_path)

# ---- 9. Report ---------------------------------------------------------------
decision_report <- decision[
  ,
  c(
    "candidate_spec_id", "tier1_pass", "tier2_evidence_class",
    "dols_fragility_flag", "dols_veto", "tier3_implementation_status",
    "s40_gate", "fragility_flag"
  ),
  drop = FALSE
]

tier1_report <- data.frame(
  check = c(
    "B1 under formal evaluation",
    "B1 has no severe collinearity flag",
    "FM-OLS main estimator available across B1 windows",
    "IM-OLS robustness estimator available across B1 windows",
    "IM-OLS does not substantively contradict FM-OLS",
    "DOLS fragility diagnostic active",
    "DOLS veto applied",
    "Tier 1 object admissibility"
  ),
  result = c(
    bool_text(b1_under_evaluation),
    bool_text(b1_no_severe_collinearity),
    bool_text(b1_fm_ols_available),
    bool_text(b1_im_ols_available),
    bool_text(b1_fm_im_noncontradictory),
    bool_text(dols_fragility_flag),
    bool_text(dols_veto),
    bool_text(tier1_pass)
  ),
  detail = c(
    "B1 is the only restricted S40-pathway candidate.",
    "Evaluated from us_s30_window_stability_summary.csv.",
    "FM-OLS is the main estimator under the locked R09 rule.",
    "IM-OLS is the robustness estimator under the locked R09 rule.",
    "A substantive IM-OLS contradiction of FM-OLS is the only estimator contradiction that can fail Tier 1.",
    dols_contradiction_note,
    paste0(
      "DOLS is a fragility/stress diagnostic, not a veto estimator; dols_veto = ",
      bool_text(dols_veto),
      "."
    ),
    gate_reason
  ),
  stringsAsFactors = FALSE
)

report_lines <- c(
  "# US S30 Formal Stability Adjudication Report",
  "",
  "## 1. Purpose",
  "",
  paste(
    "This script adjudicates the existing S30 transformation-relation outputs",
    "for the restricted B1 pathway. It does not expand the estimator grid,",
    "create S40 code, reconstruct productive capacity, compute capacity",
    "utilization or mu, produce profitability outputs, or touch Chile outputs."
  ),
  "",
  paste(
    "Estimator roles follow the locked R09 rule: FM-OLS is the main estimator,",
    "IM-OLS is the robustness estimator, and DOLS is a fragility/stress",
    "diagnostic. DOLS contradiction is recorded but does not veto Tier 1 and",
    "does not independently block S40."
  ),
  "",
  "## 2. Required inputs detected",
  "",
  md_table(data.frame(input = unname(required_inputs), detected = input_detected, stringsAsFactors = FALSE)),
  "",
  "## 3. Formal specification disposition",
  "",
  md_table(
    spec_disposition[
      ,
      c(
        "formal_short_label", "spec_id", "formal_disposition",
        "under_formal_evaluation", "restricted_s40_candidate",
        "formal_promotion_allowed"
      ),
      drop = FALSE
    ]
  ),
  "",
  "## 4. Tier 1 object admissibility",
  "",
  md_table(tier1_report),
  "",
  "## 5. Tier 2 stability evidence",
  "",
  paste(
    "Exact Hansen-type parameter-instability testing is unavailable in this",
    "bounded pass because the required raw cointegrating-regression objects are",
    "not part of the S30 output-only input contract. The exported diagnostic",
    "therefore reports a proxy status and uses the existing S30 rolling FM-OLS",
    "coefficient path."
  ),
  "",
  md_table(
    hansen_tests[
      ,
      c(
        "test_id", "exact_or_proxy_status", "rolling_windows",
        "rolling_adjacent_sign_reversal_count",
        "summary_proxy_reversal_count", "evidence_class"
      ),
      drop = FALSE
    ]
  ),
  "",
  "## 6. Tier 3 Gregory-Hansen stress",
  "",
  paste(
    "Gregory-Hansen is exported as a not_implemented diagnostic row. The pass",
    "does not redefine windows and does not promote non-B1 specifications."
  ),
  "",
  md_table(gh_stress[, c("test_id", "implementation_status", "evidence_class", "windows_redefined", "non_b1_specs_promoted"), drop = FALSE]),
  "",
  "## 7. Decision",
  "",
  md_table(decision_report),
  "",
  paste0("- Gate reason: ", gate_reason),
  "",
  "## 8. Package/function availability",
  "",
  md_table(package_rows),
  "",
  "## 9. Output files",
  "",
  md_table(data.frame(output = basename(output_rows$value), path = output_rows$value, stringsAsFactors = FALSE)),
  "",
  "## 10. Warnings",
  "",
  if (length(adjudication_warnings) == 0L) "- none" else paste0("- ", adjudication_warnings)
)

writeLines(report_lines, report_path, useBytes = TRUE)

message("US S30 formal stability adjudication complete.")
message("S40 gate: ", s40_gate)
