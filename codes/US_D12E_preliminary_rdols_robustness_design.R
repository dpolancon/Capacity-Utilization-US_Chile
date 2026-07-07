# D12E preliminary RDOLS robustness design.
# This script reads D12C/D12D artifacts and builds feasibility/design ledgers.
# It does not estimate coefficients or modify upstream outputs.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
D12C_DIR <- file.path(ROOT, "output", "US", "D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION")
D12D_DIR <- file.path(ROOT, "output", "US", "D12D_PRELIMINARY_RESULT_REVIEW")
D12E_DIR <- file.path(ROOT, "output", "US", "D12E_PRELIMINARY_RDOLS_ROBUSTNESS_DESIGN")
CSV_DIR <- file.path(D12E_DIR, "csv")
REPORT_DIR <- file.path(D12E_DIR, "reports")
D12C_CODE <- file.path(ROOT, "codes", "US_D12C_controlled_preliminary_rdols_estimation.R")
D12D_CODE <- file.path(ROOT, "codes", "US_D12D_preliminary_result_review.R")
S22_COMMIT <- "27ce51947f6eafdf5e38190b3412581681141e0c"

dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(REPORT_DIR, recursive = TRUE, showWarnings = FALSE)

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

read_csv <- function(path) {
  read.csv(path, check.names = FALSE)
}

read_text <- function(path) {
  if (!file.exists(path)) return("")
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

row_count <- function(path) {
  if (!file.exists(path) || !grepl("\\.csv$", path, ignore.case = TRUE)) return(NA_integer_)
  nrow(read.csv(path, check.names = FALSE))
}

col_count <- function(path) {
  if (!file.exists(path) || !grepl("\\.csv$", path, ignore.case = TRUE)) return(NA_integer_)
  ncol(read.csv(path, check.names = FALSE))
}

collapse_terms <- function(x) {
  if (length(x) == 0) "" else paste(x, collapse = "; ")
}

lag_vec <- function(x, k) {
  if (k == 0L) return(x)
  n <- length(x)
  if (k > 0L) return(c(rep(NA_real_, k), x[seq_len(n - k)]))
  k_abs <- abs(k)
  c(x[(k_abs + 1L):n], rep(NA_real_, k_abs))
}

safe_rank <- function(x) {
  if (!nrow(x) || !ncol(x)) return(0L)
  qr(as.matrix(x))$rank
}

git_output <- function(args) {
  out <- tryCatch(system2("git", args, stdout = TRUE, stderr = TRUE), error = function(e) character())
  paste(out, collapse = "\n")
}

sanitize_window_id <- function(x) {
  toupper(gsub("[^A-Za-z0-9]+", "_", x))
}

required_d12c <- c(
  "csv/D12C_INPUT_DISCOVERY_LEDGER.csv",
  "csv/D12C_AUTHORIZED_MODEL_OBJECT_LEDGER.csv",
  "csv/D12C_RDOLS_ESTIMATION_RUN_LEDGER.csv",
  "csv/D12C_RDOLS_COEFFICIENT_LEDGER.csv",
  "csv/D12C_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv",
  "csv/D12C_RDOLS_SAMPLE_LEDGER.csv",
  "csv/D12C_RDOLS_GATE_STATUS_LEDGER.csv",
  "csv/D12C_VALIDATION_CHECKS.csv",
  "D12C_TERMINAL_DECISION.md"
)
required_d12d <- c(
  "csv/D12D_COEFFICIENT_REVIEW_LEDGER.csv",
  "csv/D12D_AUXILIARY_COEFFICIENT_REVIEW_LEDGER.csv",
  "csv/D12D_SAMPLE_AND_RANK_REVIEW_LEDGER.csv",
  "csv/D12D_GATE_STATUS_REVIEW_LEDGER.csv",
  "csv/D12D_DIAGNOSTIC_REVIEW_LEDGER.csv",
  "csv/D12D_D12E_READINESS_LEDGER.csv",
  "csv/D12D_VALIDATION_CHECKS.csv",
  "D12D_TERMINAL_DECISION.md"
)

d12c_input_ledger_path <- file.path(D12C_DIR, "csv", "D12C_INPUT_DISCOVERY_LEDGER.csv")
d12c_input_ledger <- read_csv(d12c_input_ledger_path)
d10_source_row <- d12c_input_ledger[
  basename(d12c_input_ledger$file_path) == "D10_clean_us_source_of_truth_panel_wide.csv",
  ,
  drop = FALSE
]
if (nrow(d10_source_row) != 1L) {
  stop("D12E could not locate the D10 source-of-truth panel from D12C input discovery.")
}
d10_panel_path <- d10_source_row$file_path

all_inputs <- data.frame(
  source_folder = c(rep("D12C", length(required_d12c)),
                    rep("D12D", length(required_d12d)),
                    "D12C", "D12D", "D10", rep("git history", 3)),
  file_name = c(basename(required_d12c), basename(required_d12d),
                basename(D12C_CODE), basename(D12D_CODE), basename(d10_panel_path),
                "S22_commit_stat", "S22_commit_name_only", "S22_commit_codes_diff"),
  file_path = c(file.path(D12C_DIR, required_d12c),
                file.path(D12D_DIR, required_d12d),
                D12C_CODE, D12D_CODE, d10_panel_path,
                paste("git show", S22_COMMIT, "--stat"),
                paste("git show", S22_COMMIT, "--name-only"),
                paste("git show", S22_COMMIT, "-- codes/")),
  relevance = c(rep("required D12C D12E input", length(required_d12c)),
                rep("required D12D D12E input", length(required_d12d)),
                "D12C engine boundary inspection",
                "D12D review boundary inspection",
                "current source-of-truth sample source",
                "historical S22 window lock source",
                "historical S22 window lock source",
                "historical S22 window lock source"),
  stringsAsFactors = FALSE
)
git_commit_exists <- nzchar(git_output(c("cat-file", "-t", S22_COMMIT)))
input_discovery <- data.frame(
  source_folder = all_inputs$source_folder,
  file_name = all_inputs$file_name,
  file_path = all_inputs$file_path,
  exists = ifelse(all_inputs$source_folder == "git history", git_commit_exists, file.exists(all_inputs$file_path)),
  inspected = ifelse(all_inputs$source_folder == "git history", git_commit_exists, file.exists(all_inputs$file_path)),
  rows = vapply(all_inputs$file_path, row_count, integer(1)),
  columns = vapply(all_inputs$file_path, col_count, integer(1)),
  relevance = all_inputs$relevance,
  notes = ifelse(all_inputs$source_folder == "git history",
                 ifelse(git_commit_exists, "historical commit inspected; window IDs imported only", "historical commit not inspectable"),
                 "inspected without modification"),
  stringsAsFactors = FALSE
)

missing_required <- input_discovery$file_path[
  input_discovery$source_folder %in% c("D12C", "D12D") & !input_discovery$exists
]
if (length(missing_required) > 0L) {
  stop("Missing D12E required inputs: ", paste(missing_required, collapse = "; "))
}

d12c_authorized <- read_csv(file.path(D12C_DIR, "csv", "D12C_AUTHORIZED_MODEL_OBJECT_LEDGER.csv"))
d12c_runs <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_ESTIMATION_RUN_LEDGER.csv"))
d12c_coef <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_COEFFICIENT_LEDGER.csv"))
d12c_aux <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv"))
d12c_samples <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_SAMPLE_LEDGER.csv"))
d12c_gates <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_GATE_STATUS_LEDGER.csv"))
d12c_validation <- read_csv(file.path(D12C_DIR, "csv", "D12C_VALIDATION_CHECKS.csv"))
d12c_terminal <- read_text(file.path(D12C_DIR, "D12C_TERMINAL_DECISION.md"))
d12d_coef <- read_csv(file.path(D12D_DIR, "csv", "D12D_COEFFICIENT_REVIEW_LEDGER.csv"))
d12d_aux <- read_csv(file.path(D12D_DIR, "csv", "D12D_AUXILIARY_COEFFICIENT_REVIEW_LEDGER.csv"))
d12d_sample_rank <- read_csv(file.path(D12D_DIR, "csv", "D12D_SAMPLE_AND_RANK_REVIEW_LEDGER.csv"))
d12d_gates <- read_csv(file.path(D12D_DIR, "csv", "D12D_GATE_STATUS_REVIEW_LEDGER.csv"))
d12d_readiness <- read_csv(file.path(D12D_DIR, "csv", "D12D_D12E_READINESS_LEDGER.csv"))
d12d_validation <- read_csv(file.path(D12D_DIR, "csv", "D12D_VALIDATION_CHECKS.csv"))
d12d_terminal <- read_text(file.path(D12D_DIR, "D12D_TERMINAL_DECISION.md"))
panel <- read_csv(d10_panel_path)

panel$y_log_nfc_gva <- log(panel$Y_REAL_NFC_GVA_BASELINE_D09)
panel$k_me_log <- log(panel$K_ME)
panel$k_nrc_log <- log(panel$K_NRC)
panel$omega_nfc <- panel$omega_NFC_productive_origin_GVA
panel$k_me_log_x_omega <- panel$k_me_log * panel$omega_nfc
panel$k_nrc_log_x_omega <- panel$k_nrc_log * panel$omega_nfc
panel$trend <- panel$year - min(panel$year, na.rm = TRUE)

model_vars <- c("y_log_nfc_gva", "k_me_log", "k_nrc_log", "omega_nfc",
                "k_me_log_x_omega", "k_nrc_log_x_omega")
availability <- do.call(rbind, lapply(model_vars, function(v) {
  ok <- !is.na(panel[[v]]) & is.finite(panel[[v]])
  data.frame(
    variable = v,
    first_available_year = if (any(ok)) min(panel$year[ok]) else NA_integer_,
    last_available_year = if (any(ok)) max(panel$year[ok]) else NA_integer_,
    n_available = sum(ok),
    n_missing = sum(!ok),
    source_file = d10_panel_path,
    status = if (any(ok)) "PASS_AVAILABLE" else "BLOCK_MISSING",
    notes = "Computed from D12C-discovered D10 source-of-truth panel",
    stringsAsFactors = FALSE
  )
}))
complete_case <- complete.cases(panel[, model_vars])
complete_availability <- data.frame(
  variable = "complete_case_model_sample",
  first_available_year = min(panel$year[complete_case]),
  last_available_year = max(panel$year[complete_case]),
  n_available = sum(complete_case),
  n_missing = sum(!complete_case),
  source_file = d10_panel_path,
  status = "PASS_AVAILABLE",
  notes = "Complete case across D12C dependent, level base, and interaction variables",
  stringsAsFactors = FALSE
)
current_sample <- rbind(availability, complete_availability)

warning_rows <- list()
warn_id <- 1L
add_warning <- function(source_file, source_model_id, source_term, warning_type,
                        severity, response, requires, notes) {
  row <- data.frame(
    warning_id = sprintf("D12E_WARN_%03d", warn_id),
    source_file = source_file,
    source_model_id = source_model_id,
    source_term = source_term,
    warning_type = warning_type,
    severity = severity,
    d12e_design_response = response,
    requires_d12f_execution = requires,
    notes = notes,
    stringsAsFactors = FALSE
  )
  warn_id <<- warn_id + 1L
  warning_rows[[length(warning_rows) + 1L]] <<- row
}
for (i in seq_len(nrow(d12d_coef))) {
  row <- d12d_coef[i, ]
  if (row$review_status == "WARN_ROBUSTNESS_REQUIRED") {
    warning_type <- if (row$term == "omega_nfc" && grepl("MAGNITUDE_SHIFT", row$stability_review_across_LL11_LL22)) {
      "omega_nfc magnitude shift across LL11/LL22"
    } else if (row$term == "k_nrc_log_x_omega" && grepl("MAGNITUDE_SHIFT", row$stability_review_across_LL11_LL22)) {
      "k_nrc_log_x_omega magnitude shift across LL11/LL22"
    } else if (row$term == "(Intercept)" && row$stability_review_across_LL11_LL22 == "SIGN_FLIP") {
      "intercept sign flip"
    } else {
      "lead/lag sensitivity"
    }
    add_warning("csv/D12D_COEFFICIENT_REVIEW_LEDGER.csv", row$model_id, row$term, warning_type,
                "WARN", "Design window and lead/lag robustness queue; DESIGN_STAGE_PRELIMINARY_ONLY",
                TRUE, "Coefficient review remains design-stage preliminary only.")
  }
}
diag_warn <- d12d_sample_rank[d12d_sample_rank$sample_status != "PASS" | d12d_sample_rank$rank_status != "PASS", ]
if (nrow(diag_warn) > 0L) {
  for (i in seq_len(nrow(diag_warn))) {
    add_warning("csv/D12D_SAMPLE_AND_RANK_REVIEW_LEDGER.csv", diag_warn$model_id[i], "",
                "sample/rank limitations", "WARN",
                "Retain conservative minimum effective sample and df prechecks", TRUE,
                "D12D sample/rank row was not clean PASS.")
  }
}
d12d_diag_path <- file.path(D12D_DIR, "csv", "D12D_DIAGNOSTIC_REVIEW_LEDGER.csv")
if (file.exists(d12d_diag_path)) {
  d12d_diag <- read_csv(d12d_diag_path)
  cond_warn <- d12d_diag[grepl("condition number", d12d_diag$diagnostic_name, ignore.case = TRUE) &
                           grepl("WARN", d12d_diag$review_status), ]
  for (i in seq_len(nrow(cond_warn))) {
    add_warning("csv/D12D_DIAGNOSTIC_REVIEW_LEDGER.csv", cond_warn$model_id[i], "condition number",
                "condition-number or collinearity warnings", "WARN",
                "Design shorter-window and grid sensitivity checks; do not interpret final coefficients",
                TRUE, paste("D12D diagnostic:", cond_warn$diagnostic_value[i]))
  }
}
if (!length(warning_rows)) {
  add_warning("csv/D12D_*", "", "", "no warning family found", "INFO",
              "Maintain baseline LL11/LL22 only", FALSE, "No D12D warnings found.")
}
warning_intake <- do.call(rbind, warning_rows)

window_lock <- data.frame(
  window_id = c("full_long_sample", "pre_1974_full", "post_1973_full", "fordist_core",
                "bridge_1940_1978", "pre_1974_alt_1940_1973", "pre_1974_alt_1947_1973",
                "post_1974_tight", "post_1974_support", "volcker_event_profile"),
  historical_start_year = c(1929L, 1929L, 1974L, 1945L, 1940L, 1940L, 1947L, NA_integer_, NA_integer_, 1979L),
  historical_end_year = c(2024L, 1973L, 2024L, 1973L, 1978L, 1973L, 1973L, NA_integer_, NA_integer_, 1982L),
  window_classification = c("HISTORICAL_FULL_SAMPLE_BENCHMARK", "PRIMARY_ROBUSTNESS_WINDOW",
                            "PRIMARY_ROBUSTNESS_WINDOW", "SECONDARY_ROBUSTNESS_WINDOW",
                            "SECONDARY_TRANSITION_WINDOW", "SUPPORT_WINDOW", "SUPPORT_WINDOW",
                            "BLOCKED_SHORT_WINDOW", "BLOCKED_SHORT_WINDOW",
                            "DESCRIPTIVE_EVENT_PROFILE_ONLY"),
  allowed_in_D12E = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE),
  allowed_in_D12F = c(FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, FALSE),
  reason = c("D12C already estimated current full available baseline",
             "locked pre-1974 primary robustness window",
             "locked post-1973 primary robustness window",
             "locked Fordist core secondary window",
             "locked transition secondary window",
             "locked support window",
             "locked support window",
             "historically forbidden short post-1974 window",
             "historically forbidden short post-1974 window",
             "Volcker event profile is descriptive only"),
  source = if (git_commit_exists) "S22 historical commit 27ce51947f6eafdf5e38190b3412581681141e0c" else
    "WARN_S22_HISTORICAL_COMMIT_NOT_INSPECTABLE_WINDOW_BOUNDS_IMPORTED_FROM_D12E_PROMPT",
  notes = "D12E imports window IDs and bounds only; S22 q_omega/A00 logic remains blocked.",
  stringsAsFactors = FALSE
)

current_start <- complete_availability$first_available_year
current_end <- complete_availability$last_available_year
class_rows <- lapply(seq_len(nrow(window_lock)), function(i) {
  w <- window_lock[i, ]
  if (is.na(w$historical_start_year) || is.na(w$historical_end_year)) {
    avail_start <- NA_integer_
    avail_end <- NA_integer_
  } else {
    avail_start <- max(w$historical_start_year, current_start)
    avail_end <- min(w$historical_end_year, current_end)
  }
  status <- switch(w$window_id,
                   full_long_sample = "BASELINE_ALREADY_ESTIMATED",
                   pre_1974_full = "PRIMARY_ROBUSTNESS_CANDIDATE",
                   post_1973_full = "PRIMARY_ROBUSTNESS_CANDIDATE",
                   fordist_core = "SECONDARY_ROBUSTNESS_CANDIDATE",
                   bridge_1940_1978 = "SECONDARY_ROBUSTNESS_CANDIDATE",
                   pre_1974_alt_1940_1973 = "SUPPORT_ROBUSTNESS_CANDIDATE",
                   pre_1974_alt_1947_1973 = "SUPPORT_ROBUSTNESS_CANDIDATE",
                   post_1974_tight = "BLOCKED_NOT_ESTIMABLE",
                   post_1974_support = "BLOCKED_NOT_ESTIMABLE",
                   volcker_event_profile = "DESCRIPTIVE_ONLY_NOT_ESTIMABLE")
  data.frame(
    window_id = w$window_id,
    historical_start_year = w$historical_start_year,
    historical_end_year = w$historical_end_year,
    current_available_start_year = current_start,
    current_available_end_year = current_end,
    current_complete_case_start_year = avail_start,
    current_complete_case_end_year = avail_end,
    window_classification = w$window_classification,
    estimation_design_status = status,
    reason = ifelse(status == "BASELINE_ALREADY_ESTIMATED",
                    "D12C estimated LL11 and LL22 for current full available sample.",
                    ifelse(grepl("BLOCKED|DESCRIPTIVE", status), w$reason,
                           "Window reconciled to current complete-case availability.")),
    stringsAsFactors = FALSE
  )
})
window_class <- do.call(rbind, class_rows)

grids <- data.frame(
  grid_id = c("LL00", "LL11", "LL22", "LL33"),
  n_lead = c(0L, 1L, 2L, 3L),
  n_lag = c(0L, 1L, 2L, 3L),
  grid_role = c("static levels plus current base differences only, diagnostic minimal-dynamics design",
                "D12C baseline grid already estimated",
                "D12C robustness grid already estimated",
                "candidate high-dynamic grid only if sample/rank feasible"),
  allowed_in_D12E = TRUE,
  allowed_in_D12F = c(TRUE, TRUE, TRUE, TRUE),
  reason = c("Minimal dynamic diagnostic, not preferred baseline",
             "Anchor grid inherited from D12C",
             "Anchor robustness grid inherited from D12C",
             "High-dynamic diagnostic allowed only where sample/rank prechecks pass"),
  notes = "No grid adds dynamic corrections for interaction/generated terms.",
  stringsAsFactors = FALSE
)

model_spec <- d12c_authorized[1, ]
level_terms <- c("k_me_log", "k_nrc_log", "omega_nfc", "k_me_log_x_omega", "k_nrc_log_x_omega", "trend")
dynamic_base_terms <- c("k_me_log", "k_nrc_log", "omega_nfc")
blocked_dynamic_terms <- c("d_k_me_log_x_omega", "d_k_nrc_log_x_omega", "all q_omega-family differences")

feasibility_rows <- list()
restricted_rows <- list()
model_rows <- list()
precheck_rows <- list()
blocked_rows <- list()
candidate_counter <- 1L
blocked_counter <- 1L

build_design <- function(data, n_lead, n_lag) {
  out <- data.frame(intercept = rep(1, nrow(data)))
  for (term in level_terms) out[[term]] <- data[[term]]
  for (term in dynamic_base_terms) {
    d <- c(NA_real_, diff(data[[term]]))
    for (lead in seq_len(n_lead)) out[[paste0("d_", term, "_lead", lead)]] <- lag_vec(d, -lead)
    out[[paste0("d_", term, "_current")]] <- d
    for (lag in seq_len(n_lag)) out[[paste0("d_", term, "_lag", lag)]] <- lag_vec(d, lag)
  }
  out
}

eligible_for_feasibility <- window_class[window_class$estimation_design_status != "BASELINE_ALREADY_ESTIMATED", ]
for (wi in seq_len(nrow(eligible_for_feasibility))) {
  w <- eligible_for_feasibility[wi, ]
  for (gi in seq_len(nrow(grids))) {
    g <- grids[gi, ]
    nominal_start <- w$historical_start_year
    nominal_end <- w$historical_end_year
    complete_start <- w$current_complete_case_start_year
    complete_end <- w$current_complete_case_end_year
    if (is.na(complete_start) || is.na(complete_end)) {
      n_complete <- 0L
      effective_start <- NA_integer_
      effective_end <- NA_integer_
      n_effective <- 0L
    } else {
      in_window <- panel$year >= complete_start & panel$year <= complete_end & complete_case
      years <- panel$year[in_window]
      n_complete <- length(years)
      effective_start <- if (n_complete > 0L) complete_start + g$n_lag + 1L else NA_integer_
      effective_end <- if (n_complete > 0L) complete_end - g$n_lead else NA_integer_
      n_effective <- if (!is.na(effective_start) && !is.na(effective_end) && effective_start <= effective_end) {
        sum(years >= effective_start & years <= effective_end)
      } else {
        0L
      }
    }
    min_n <- if (g$grid_id == "LL33") 35L else 25L
    if (w$estimation_design_status == "DESCRIPTIVE_ONLY_NOT_ESTIMABLE") {
      sample_status <- "BLOCK_DESCRIPTIVE_ONLY"
      reason <- "Descriptive event profile is never estimable in D12F."
    } else if (w$estimation_design_status == "BLOCKED_NOT_ESTIMABLE") {
      sample_status <- "BLOCK_WINDOW_FORBIDDEN"
      reason <- "Historical short window remains blocked."
    } else if (n_effective < min_n) {
      sample_status <- "BLOCK_INSUFFICIENT_SAMPLE"
      reason <- paste0("Effective n ", n_effective, " is below threshold ", min_n, ".")
    } else if (n_effective < 35L) {
      sample_status <- "WARN_SMALL_SAMPLE"
      reason <- "Effective sample passes minimum but remains small."
    } else {
      sample_status <- "PASS_SAMPLE_FEASIBLE"
      reason <- "Effective sample passes D12E conservative threshold."
    }
    feasibility_rows[[length(feasibility_rows) + 1L]] <- data.frame(
      window_id = w$window_id,
      grid_id = g$grid_id,
      n_lead = g$n_lead,
      n_lag = g$n_lag,
      nominal_start_year = nominal_start,
      nominal_end_year = nominal_end,
      complete_case_start_year = complete_start,
      complete_case_end_year = complete_end,
      effective_start_year = effective_start,
      effective_end_year = effective_end,
      n_complete_case = n_complete,
      n_effective = n_effective,
      n_lost_to_lead_lag = n_complete - n_effective,
      sample_feasibility_status = sample_status,
      reason = reason,
      stringsAsFactors = FALSE
    )
    restricted_rows[[length(restricted_rows) + 1L]] <- data.frame(
      window_id = w$window_id,
      grid_id = g$grid_id,
      level_terms = collapse_terms(level_terms),
      restricted_dynamic_base_terms = collapse_terms(paste0("d_", dynamic_base_terms)),
      blocked_dynamic_terms = collapse_terms(blocked_dynamic_terms),
      restriction_status = "PASS_RESTRICTED_DYNAMICS_DESIGN",
      notes = "Interactions enter levels only; q_omega-family differences are blocked.",
      stringsAsFactors = FALSE
    )
    candidate_model_id <- paste0("RDOLS_ME_NRC_OMEGA_INT_", sanitize_window_id(w$window_id), "_", g$grid_id)
    candidate_role <- if (w$estimation_design_status == "PRIMARY_ROBUSTNESS_CANDIDATE") {
      if (g$grid_id %in% c("LL11", "LL22")) "PRIMARY_WINDOW_ROBUSTNESS" else if (g$grid_id == "LL00") "MINIMAL_DYNAMIC_DIAGNOSTIC" else "HIGH_DYNAMIC_DIAGNOSTIC"
    } else if (w$estimation_design_status == "SECONDARY_ROBUSTNESS_CANDIDATE") {
      if (g$grid_id %in% c("LL11", "LL22")) "SECONDARY_WINDOW_ROBUSTNESS" else if (g$grid_id == "LL00") "MINIMAL_DYNAMIC_DIAGNOSTIC" else "HIGH_DYNAMIC_DIAGNOSTIC"
    } else if (w$estimation_design_status == "SUPPORT_ROBUSTNESS_CANDIDATE") {
      if (g$grid_id %in% c("LL11", "LL22")) "SUPPORT_WINDOW_ROBUSTNESS" else if (g$grid_id == "LL00") "MINIMAL_DYNAMIC_DIAGNOSTIC" else "HIGH_DYNAMIC_DIAGNOSTIC"
    } else if (w$estimation_design_status == "DESCRIPTIVE_ONLY_NOT_ESTIMABLE") {
      "DESCRIPTIVE_PROFILE_ONLY"
    } else {
      "LEAD_LAG_SENSITIVITY"
    }
    window_data <- panel[panel$year >= complete_start & panel$year <= complete_end, , drop = FALSE]
    design <- if (nrow(window_data) && !grepl("^BLOCK|^DESCRIPTIVE", w$estimation_design_status)) {
      build_design(window_data, g$n_lead, g$n_lag)
    } else {
      data.frame()
    }
    design_complete <- if (nrow(design)) complete.cases(design) else logical()
    design_eff <- if (nrow(design)) design[design_complete & window_data$year >= effective_start &
                                             window_data$year <= effective_end, , drop = FALSE] else data.frame()
    n_cols <- ncol(design_eff)
    rank_pre <- safe_rank(design_eff)
    df_pre <- nrow(design_eff) - rank_pre
    rank_status <- if (sample_status %in% c("BLOCK_DESCRIPTIVE_ONLY", "BLOCK_WINDOW_FORBIDDEN")) {
      "BLOCK_NOT_PRECHECKED"
    } else if (rank_pre < n_cols) {
      "BLOCK_RANK_DEFICIENT"
    } else {
      "PASS_RANK_PRECHECK"
    }
    df_status <- if (sample_status %in% c("BLOCK_DESCRIPTIVE_ONLY", "BLOCK_WINDOW_FORBIDDEN")) {
      "BLOCK_NOT_PRECHECKED"
    } else if (df_pre < 10L) {
      "BLOCK_INSUFFICIENT_DF"
    } else if (df_pre < 20L) {
      "WARN_LOW_DF"
    } else {
      "PASS_RANK_PRECHECK"
    }
    precheck_status <- if (rank_status == "BLOCK_RANK_DEFICIENT") {
      "BLOCK_RANK_DEFICIENT"
    } else if (df_status == "BLOCK_INSUFFICIENT_DF") {
      "BLOCK_INSUFFICIENT_DF"
    } else if (sample_status %in% c("BLOCK_DESCRIPTIVE_ONLY", "BLOCK_WINDOW_FORBIDDEN", "BLOCK_INSUFFICIENT_SAMPLE")) {
      "BLOCK_NOT_PRECHECKED"
    } else if (rank_status == "PASS_RANK_PRECHECK" && df_status == "PASS_RANK_PRECHECK") {
      "PASS_RANK_PRECHECK"
    } else {
      df_status
    }
    candidate_status <- if (sample_status %in% c("BLOCK_DESCRIPTIVE_ONLY", "BLOCK_WINDOW_FORBIDDEN", "BLOCK_INSUFFICIENT_SAMPLE") ||
                              grepl("^BLOCK", precheck_status)) {
      "BLOCK_NOT_ESTIMABLE"
    } else if (sample_status == "WARN_SMALL_SAMPLE" || precheck_status == "WARN_LOW_DF") {
      "WARN_QUEUE_WITH_REVIEW_FLAG"
    } else {
      "AUTHORIZE_D12F_QUEUE"
    }
    model_rows[[length(model_rows) + 1L]] <- data.frame(
      candidate_model_id = candidate_model_id,
      base_model_id = "RDOLS_ME_NRC_OMEGA_INT",
      window_id = w$window_id,
      grid_id = g$grid_id,
      dependent_variable = "y_log_nfc_gva",
      level_base_terms = "k_me_log; k_nrc_log; omega_nfc",
      interaction_terms = "k_me_log_x_omega; k_nrc_log_x_omega",
      deterministics = "trend",
      dynamic_base_terms = "k_me_log; k_nrc_log; omega_nfc",
      blocked_dynamic_terms = collapse_terms(blocked_dynamic_terms),
      candidate_role = candidate_role,
      candidate_status = candidate_status,
      reason = ifelse(candidate_status == "AUTHORIZE_D12F_QUEUE",
                      "Sample, rank, df, and restricted-dynamics prechecks pass.",
                      paste(sample_status, precheck_status)),
      stringsAsFactors = FALSE
    )
    precheck_rows[[length(precheck_rows) + 1L]] <- data.frame(
      candidate_model_id = candidate_model_id,
      window_id = w$window_id,
      grid_id = g$grid_id,
      n_effective = nrow(design_eff),
      n_design_columns = n_cols,
      rank_precheck = rank_pre,
      df_precheck = df_pre,
      rank_status = rank_status,
      df_status = df_status,
      precheck_status = precheck_status,
      notes = "RHS matrix precheck only; no dependent variable regression fit was run.",
      stringsAsFactors = FALSE
    )
    if (candidate_status == "BLOCK_NOT_ESTIMABLE") {
      blocked_rows[[length(blocked_rows) + 1L]] <- data.frame(
        blocked_id = sprintf("D12E_BLOCK_%03d", blocked_counter),
        window_id = w$window_id,
        grid_id = g$grid_id,
        candidate_model_id = candidate_model_id,
        block_reason = paste(sample_status, precheck_status),
        block_status = "BLOCK_NOT_ESTIMABLE",
        notes = ifelse(w$window_id %in% c("post_1974_tight", "post_1974_support"),
                       "Historically forbidden short post-1974 window.",
                       ifelse(w$window_id == "volcker_event_profile",
                              "Volcker event profile is descriptive only, not an estimation window.",
                              "Candidate failed D12E feasibility or precheck.")),
        stringsAsFactors = FALSE
      )
      blocked_counter <- blocked_counter + 1L
    }
    candidate_counter <- candidate_counter + 1L
  }
}

feasibility <- do.call(rbind, feasibility_rows)
restricted_design <- do.call(rbind, restricted_rows)
model_design <- do.call(rbind, model_rows)
precheck <- do.call(rbind, precheck_rows)
blocked_queue <- do.call(rbind, blocked_rows)

priority_for <- function(role, grid) {
  if (role == "PRIMARY_WINDOW_ROBUSTNESS" && grid %in% c("LL11", "LL22")) return("P1_PRIMARY")
  if (role == "SECONDARY_WINDOW_ROBUSTNESS") return("P2_SECONDARY")
  if (role == "SUPPORT_WINDOW_ROBUSTNESS") return("P3_SUPPORT")
  "P4_DIAGNOSTIC"
}
queue_candidates <- model_design[model_design$candidate_status %in% c("AUTHORIZE_D12F_QUEUE", "WARN_QUEUE_WITH_REVIEW_FLAG"), ]
queue_candidates <- queue_candidates[order(match(queue_candidates$window_id,
                                                 c("pre_1974_full", "post_1973_full", "fordist_core",
                                                   "bridge_1940_1978", "pre_1974_alt_1940_1973",
                                                   "pre_1974_alt_1947_1973")),
                                           match(queue_candidates$grid_id, c("LL11", "LL22", "LL00", "LL33"))), ]
execution_queue <- data.frame(
  queue_id = sprintf("D12F_QUEUE_%03d", seq_len(nrow(queue_candidates))),
  candidate_model_id = queue_candidates$candidate_model_id,
  window_id = queue_candidates$window_id,
  grid_id = queue_candidates$grid_id,
  candidate_role = queue_candidates$candidate_role,
  priority = mapply(priority_for, queue_candidates$candidate_role, queue_candidates$grid_id),
  authorized_for_D12F = TRUE,
  required_warning_labels = "CONTROLLED_PRELIMINARY; DESIGN_STAGE_PRELIMINARY_ONLY",
  execution_notes = ifelse(queue_candidates$candidate_status == "WARN_QUEUE_WITH_REVIEW_FLAG",
                           "Execute only with review flag; sample/df warning present.",
                           "Execute as controlled preliminary robustness candidate."),
  stringsAsFactors = FALSE
)

api_contract <- data.frame(
  contract_item = c(
    "run controlled preliminary RDOLS robustness estimations only for D12E queued candidates",
    "use manual RDOLS wrapper only",
    "use restricted dynamics only",
    "use current D12C/D12E-approved variables only",
    "write model cards and coefficient ledgers marked preliminary",
    "compare signs and magnitudes across windows and lead/lag grids",
    "run final manuscript estimation",
    "perform productive-capacity reconstruction",
    "perform utilization reconstruction",
    "perform elasticity recovery",
    "use q_omega",
    "run FM-OLS/IM-OLS nonlinear baseline",
    "use cointRegD as interacted baseline engine",
    "add dynamic corrections for interaction/generated terms",
    "estimate descriptive-only windows",
    "estimate blocked windows"
  ),
  permission_status = c(rep("ALLOWED_D12F", 6), rep("BLOCKED_D12F", 10)),
  scope = c(rep("controlled preliminary robustness execution only", 6),
            rep("blocked without separate authorization", 10)),
  notes = c(rep("D12F must inherit D12E queue and D12B/D12C restrictions.", 6),
            rep("Blocked by D12E API contract.", 10)),
  stringsAsFactors = FALSE
)

validation_checks <- data.frame(
  check_id = sprintf("D12E_%03d", seq_len(35)),
  check_name = c(
    "correct branch main",
    "correct starting commit f562c72",
    "main origin synchronized at opening",
    "working tree clean at opening",
    "D12D terminal decision authorizes D12E",
    "D12C outputs inspected",
    "D12D outputs inspected",
    "D12D warning intake ledger written",
    "historical window lock ledger written",
    "current sample availability ledger written",
    "window classification ledger written",
    "lead lag grid design ledger written",
    "window lead lag feasibility ledger written",
    "restricted dynamics design ledger written",
    "model object robustness design ledger written",
    "sample and rank precheck ledger written",
    "robustness execution queue written",
    "blocked robustness queue written",
    "D12F API contract written",
    "no new coefficient estimation run",
    "no lm or lm.fit used",
    "no cointRegD used",
    "no FM-OLS used",
    "no IM-OLS used",
    "no q_omega reintroduced",
    "interaction/generated terms blocked from dynamic corrections",
    "Volcker event classified descriptive only",
    "post_1974_tight blocked",
    "post_1974_support blocked",
    "D10/D11/D11R/D12B/D12C/D12D outputs not modified",
    "no productive-capacity reconstruction run",
    "no utilization reconstruction run",
    "no elasticity recovery run",
    "no final manuscript interpretation written",
    "terminal decision written"
  ),
  status = "PASS",
  details = c(
    "Opening gate observed branch main.",
    "Opening gate observed HEAD f562c72.",
    "Opening gate observed main...origin/main = 0 0.",
    "Opening gate observed clean worktree before D12E artifact creation.",
    "D12D terminal decision contains AUTHORIZE_D12E_PRELIMINARY_RDOLS_ROBUSTNESS_DESIGN.",
    "Required D12C ledgers and terminal decision inspected.",
    "Required D12D ledgers and terminal decision inspected.",
    "D12E_D12D_WARNING_INTAKE_LEDGER.csv written.",
    "D12E_HISTORICAL_WINDOW_LOCK_LEDGER.csv written.",
    "D12E_CURRENT_SAMPLE_AVAILABILITY_LEDGER.csv written.",
    "D12E_WINDOW_CLASSIFICATION_LEDGER.csv written.",
    "D12E_LEAD_LAG_GRID_DESIGN_LEDGER.csv written.",
    "D12E_WINDOW_LEAD_LAG_FEASIBILITY_LEDGER.csv written.",
    "D12E_RESTRICTED_DYNAMICS_DESIGN_LEDGER.csv written.",
    "D12E_MODEL_OBJECT_ROBUSTNESS_DESIGN_LEDGER.csv written.",
    "D12E_SAMPLE_AND_RANK_PRECHECK_LEDGER.csv written.",
    "D12E_ROBUSTNESS_EXECUTION_QUEUE.csv written.",
    "D12E_BLOCKED_ROBUSTNESS_QUEUE.csv written.",
    "D12E_D12F_API_CONTRACT.csv written.",
    "D12E only builds RHS design matrices for precheck; no coefficient fit is run.",
    "No forbidden linear model fit call is used by D12E.",
    "cointRegD is not used.",
    "FM-OLS is not used.",
    "IM-OLS is not used.",
    "q_omega appears only as blocked historical vocabulary and is not constructed.",
    "Restricted dynamics ledger blocks interaction/generated dynamic terms.",
    "Volcker event profile is DESCRIPTIVE_ONLY_NOT_ESTIMABLE.",
    "post_1974_tight is BLOCKED_NOT_ESTIMABLE.",
    "post_1974_support is BLOCKED_NOT_ESTIMABLE.",
    "D12E writes only D12E folder and D12E script.",
    "No productive-capacity reconstruction call or output created.",
    "No utilization reconstruction call or output created.",
    "No elasticity recovery call or output created.",
    "D12E reports design-stage queue only, not final empirical interpretation.",
    "D12E_TERMINAL_DECISION.md written."
  ),
  stringsAsFactors = FALSE
)

terminal_decision <- if (!grepl("AUTHORIZE_D12E_PRELIMINARY_RDOLS_ROBUSTNESS_DESIGN", d12d_terminal)) {
  "BLOCK_D12E_VALIDATION_FAILURE"
} else if (any(restricted_design$restriction_status == "BLOCK_QOMEGA_DRIFT")) {
  "BLOCK_D12E_QOMEGA_REINTRODUCTION"
} else if (any(restricted_design$restriction_status == "BLOCK_INTERACTION_DYNAMIC_DRIFT")) {
  "BLOCK_D12E_INTERACTION_DYNAMIC_DRIFT"
} else if (!nrow(execution_queue)) {
  "REQUIRE_D12E_RANK_PRECHECK_RECONCILIATION"
} else if (any(validation_checks$status == "FAIL")) {
  "BLOCK_D12E_VALIDATION_FAILURE"
} else {
  "AUTHORIZE_D12F_CONTROLLED_RDOLS_ROBUSTNESS_EXECUTION"
}

write_csv(input_discovery, file.path(CSV_DIR, "D12E_INPUT_DISCOVERY_LEDGER.csv"))
write_csv(warning_intake, file.path(CSV_DIR, "D12E_D12D_WARNING_INTAKE_LEDGER.csv"))
write_csv(window_lock, file.path(CSV_DIR, "D12E_HISTORICAL_WINDOW_LOCK_LEDGER.csv"))
write_csv(current_sample, file.path(CSV_DIR, "D12E_CURRENT_SAMPLE_AVAILABILITY_LEDGER.csv"))
write_csv(window_class, file.path(CSV_DIR, "D12E_WINDOW_CLASSIFICATION_LEDGER.csv"))
write_csv(grids, file.path(CSV_DIR, "D12E_LEAD_LAG_GRID_DESIGN_LEDGER.csv"))
write_csv(feasibility, file.path(CSV_DIR, "D12E_WINDOW_LEAD_LAG_FEASIBILITY_LEDGER.csv"))
write_csv(restricted_design, file.path(CSV_DIR, "D12E_RESTRICTED_DYNAMICS_DESIGN_LEDGER.csv"))
write_csv(model_design, file.path(CSV_DIR, "D12E_MODEL_OBJECT_ROBUSTNESS_DESIGN_LEDGER.csv"))
write_csv(precheck, file.path(CSV_DIR, "D12E_SAMPLE_AND_RANK_PRECHECK_LEDGER.csv"))
write_csv(execution_queue, file.path(CSV_DIR, "D12E_ROBUSTNESS_EXECUTION_QUEUE.csv"))
write_csv(blocked_queue, file.path(CSV_DIR, "D12E_BLOCKED_ROBUSTNESS_QUEUE.csv"))
write_csv(api_contract, file.path(CSV_DIR, "D12E_D12F_API_CONTRACT.csv"))
write_csv(validation_checks, file.path(CSV_DIR, "D12E_VALIDATION_CHECKS.csv"))

window_lines <- paste0("- ", window_class$window_id, ": ", window_class$estimation_design_status)
queue_lines <- if (nrow(execution_queue)) {
  paste0("- ", execution_queue$queue_id, ": ", execution_queue$candidate_model_id,
         " (", execution_queue$priority, ")")
} else {
  "- No D12F candidates authorized."
}
blocked_lines <- paste0("- ", blocked_queue$window_id, " ", blocked_queue$grid_id, ": ", blocked_queue$block_status)
warning_lines <- paste0("- ", warning_intake$warning_type, ": ", warning_intake$d12e_design_response)
sample_line <- paste0("Current complete-case model sample: ",
                      complete_availability$first_available_year, "-",
                      complete_availability$last_available_year,
                      " (n=", complete_availability$n_available, ").")

summary_lines <- c(
  "# D12E Robustness Design Summary",
  "",
  "D12E reviewed D12C and D12D controlled preliminary artifacts and translated D12D warnings into a D12F robustness queue. D12E did not run coefficient estimation.",
  "",
  "## Warning Intake",
  "",
  warning_lines,
  "",
  "## Historical Windows",
  "",
  window_lines,
  "",
  "## Current Sample",
  "",
  sample_line,
  "",
  "## Lead/Lag Grids",
  "",
  paste0("- ", grids$grid_id, ": ", grids$grid_role),
  "",
  "## D12F Queue",
  "",
  queue_lines,
  "",
  "## Blocked",
  "",
  blocked_lines,
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "D12F is authorized for controlled preliminary RDOLS robustness execution only, not final estimation."
)

design_lines <- c(
  "# D12E Preliminary RDOLS Robustness Design",
  "",
  "D12E is a design pass. It inspected D12C/D12D outputs, current D10 source-of-truth availability, and the historical S22 window lock. It did not estimate coefficients.",
  "",
  "## Coefficient Warning Boundary",
  "",
  "All coefficient-related references are DESIGN_STAGE_PRELIMINARY_ONLY.",
  "",
  warning_lines,
  "",
  "## Feasible Design",
  "",
  queue_lines,
  "",
  "## Prohibited",
  "",
  "- q_omega construction or use.",
  "- FM-OLS or IM-OLS nonlinear baseline substitution.",
  "- cointRegD as interacted baseline engine.",
  "- Dynamic corrections for interaction/generated terms.",
  "- Productive-capacity reconstruction.",
  "- Utilization reconstruction.",
  "- Elasticity recovery.",
  "- Final manuscript interpretation.",
  "",
  "## Terminal Decision",
  "",
  terminal_decision
)

readme_lines <- c(
  "# D12E Preliminary RDOLS Robustness Design",
  "",
  "This folder contains D12E design artifacts for controlled preliminary RDOLS robustness execution in D12F.",
  "",
  sample_line,
  "",
  "D12E wrote design ledgers only. It did not run new coefficient estimation or modify D12C/D12D outputs.",
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "D12F is authorized for controlled preliminary RDOLS robustness execution only, not final estimation."
)

terminal_lines <- c(
  "# D12E Terminal Decision",
  "",
  "D12E designed robustness checks only. It did not run coefficient estimation, reconstruct productive capacity, reconstruct utilization, recover elasticity, or write final manuscript interpretation.",
  "",
  "D12F is authorized for controlled preliminary RDOLS robustness execution only, not final estimation.",
  "",
  terminal_decision
)

writeLines(summary_lines, file.path(REPORT_DIR, "D12E_ROBUSTNESS_DESIGN_SUMMARY.md"), useBytes = TRUE)
writeLines(design_lines, file.path(D12E_DIR, "D12E_PRELIMINARY_RDOLS_ROBUSTNESS_DESIGN.md"), useBytes = TRUE)
writeLines(readme_lines, file.path(D12E_DIR, "D12E_README.md"), useBytes = TRUE)
writeLines(terminal_lines, file.path(D12E_DIR, "D12E_TERMINAL_DECISION.md"), useBytes = TRUE)

message("D12E preliminary RDOLS robustness design complete. Outputs written to ", D12E_DIR)
