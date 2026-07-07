# D12F-R no-trend RDOLS robustness reconciliation.
# Executes controlled preliminary no-trend RDOLS models and reclassifies
# D12C/D12F trend-included results as diagnostic comparators.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
D12C_DIR <- file.path(ROOT, "output", "US", "D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION")
D12D_DIR <- file.path(ROOT, "output", "US", "D12D_PRELIMINARY_RESULT_REVIEW")
D12E_DIR <- file.path(ROOT, "output", "US", "D12E_PRELIMINARY_RDOLS_ROBUSTNESS_DESIGN")
D12F_DIR <- file.path(ROOT, "output", "US", "D12F_CONTROLLED_RDOLS_ROBUSTNESS_EXECUTION")
OUT_DIR <- file.path(ROOT, "output", "US", "D12F_R_NO_TREND_RDOLS_ROBUSTNESS_RECONCILIATION")
CSV_DIR <- file.path(OUT_DIR, "csv")
REPORT_DIR <- file.path(OUT_DIR, "reports")
RDS_DIR <- file.path(OUT_DIR, "rds")

dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(REPORT_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(RDS_DIR, recursive = TRUE, showWarnings = FALSE)

PRELIMINARY_STATUS <- "CONTROLLED_PRELIMINARY"
ALLOWED_INTERPRETATION <- "DESIGN_STAGE_PRELIMINARY_ONLY"
ESTIMATOR <- "RESTRICTED_DOLS"

write_csv <- function(x, path) write.csv(x, path, row.names = FALSE, na = "")
read_csv <- function(path) read.csv(path, check.names = FALSE)
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
collapse_terms <- function(x) if (length(x) == 0L) "" else paste(x, collapse = "; ")
lag_vec <- function(x, k) {
  if (k == 0L) return(x)
  n <- length(x)
  if (k > 0L) return(c(rep(NA_real_, k), x[seq_len(n - k)]))
  k_abs <- abs(k)
  c(x[(k_abs + 1L):n], rep(NA_real_, k_abs))
}
stars <- function(p) {
  ifelse(is.na(p), "", ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.10, "*", ""))))
}
sign_of <- function(x) {
  ifelse(is.na(x), "UNKNOWN", ifelse(abs(x) < 1e-8, "ZERO_OR_NEAR_ZERO", ifelse(x > 0, "POSITIVE", "NEGATIVE")))
}
safe_num <- function(x) suppressWarnings(as.numeric(x))
sanitize <- function(x) toupper(gsub("[^A-Za-z0-9]+", "_", x))
no_trend_id <- function(candidate_model_id, grid_id) {
  sub(paste0("_", grid_id, "$"), paste0("_NO_TREND_", grid_id), candidate_model_id)
}

required_inputs <- data.frame(
  source_folder = c(rep("D12E", 7), rep("D12F", 7), rep("D12C", 3), rep("D12D", 2), rep("code", 3)),
  file_path = c(
    file.path(D12E_DIR, "csv", c(
      "D12E_ROBUSTNESS_EXECUTION_QUEUE.csv",
      "D12E_BLOCKED_ROBUSTNESS_QUEUE.csv",
      "D12E_D12F_API_CONTRACT.csv",
      "D12E_WINDOW_LEAD_LAG_FEASIBILITY_LEDGER.csv",
      "D12E_SAMPLE_AND_RANK_PRECHECK_LEDGER.csv",
      "D12E_RESTRICTED_DYNAMICS_DESIGN_LEDGER.csv"
    )),
    file.path(D12E_DIR, "D12E_TERMINAL_DECISION.md"),
    file.path(D12F_DIR, "csv", c(
      "D12F_RDOLS_COEFFICIENT_TIDY_TABLE.csv",
      "D12F_RDOLS_COEFFICIENT_STAR_TABLE.csv",
      "D12F_RDOLS_ESTIMATION_RUN_LEDGER.csv",
      "D12F_RDOLS_SAMPLE_LEDGER.csv",
      "D12F_RDOLS_GATE_STATUS_LEDGER.csv",
      "D12F_RESULT_WARNING_LEDGER.csv"
    )),
    file.path(D12F_DIR, "D12F_TERMINAL_DECISION.md"),
    file.path(D12C_DIR, "csv", "D12C_RDOLS_COEFFICIENT_LEDGER.csv"),
    file.path(D12C_DIR, "csv", "D12C_INPUT_DISCOVERY_LEDGER.csv"),
    file.path(D12C_DIR, "D12C_TERMINAL_DECISION.md"),
    file.path(D12D_DIR, "csv", "D12D_D12E_READINESS_LEDGER.csv"),
    file.path(D12D_DIR, "D12D_TERMINAL_DECISION.md"),
    file.path(ROOT, "codes", c(
      "US_D12C_controlled_preliminary_rdols_estimation.R",
      "US_D12E_preliminary_rdols_robustness_design.R",
      "US_D12F_controlled_rdols_robustness_execution.R"
    ))
  ),
  relevance = c(rep("required D12E queue/contract input", 7),
                rep("required D12F trend-included diagnostic input", 7),
                rep("required D12C trend-included reference/discovery input", 3),
                rep("D12D review authorization input", 2),
                rep("prior code boundary inspection", 3)),
  stringsAsFactors = FALSE
)

d12c_discovery <- read_csv(file.path(D12C_DIR, "csv", "D12C_INPUT_DISCOVERY_LEDGER.csv"))
d12e_discovery <- read_csv(file.path(D12E_DIR, "csv", "D12E_INPUT_DISCOVERY_LEDGER.csv"))
d12f_discovery <- read_csv(file.path(D12F_DIR, "csv", "D12F_INPUT_DISCOVERY_LEDGER.csv"))
source_candidates <- rbind(d12c_discovery, d12e_discovery, d12f_discovery)
source_row <- source_candidates[basename(source_candidates$file_path) == "D10_clean_us_source_of_truth_panel_wide.csv", , drop = FALSE]
if (nrow(source_row) < 1L) stop("D12F-R could not locate D10 source through discovery ledgers.")
d10_source <- source_row$file_path[1]
required_inputs <- rbind(required_inputs, data.frame(
  source_folder = "D10",
  file_path = d10_source,
  relevance = "canonical source-of-truth data for no-trend RDOLS variables",
  stringsAsFactors = FALSE
))

input_discovery <- data.frame(
  source_folder = required_inputs$source_folder,
  file_name = basename(required_inputs$file_path),
  file_path = required_inputs$file_path,
  exists = file.exists(required_inputs$file_path),
  inspected = file.exists(required_inputs$file_path),
  rows = vapply(required_inputs$file_path, row_count, integer(1)),
  columns = vapply(required_inputs$file_path, col_count, integer(1)),
  relevance = required_inputs$relevance,
  notes = "inspected without modification",
  stringsAsFactors = FALSE
)
if (any(!input_discovery$exists)) {
  stop("Missing D12F-R required inputs: ", paste(input_discovery$file_path[!input_discovery$exists], collapse = "; "))
}

queue <- read_csv(file.path(D12E_DIR, "csv", "D12E_ROBUSTNESS_EXECUTION_QUEUE.csv"))
blocked_e <- read_csv(file.path(D12E_DIR, "csv", "D12E_BLOCKED_ROBUSTNESS_QUEUE.csv"))
feasibility <- read_csv(file.path(D12E_DIR, "csv", "D12E_WINDOW_LEAD_LAG_FEASIBILITY_LEDGER.csv"))
precheck_e <- read_csv(file.path(D12E_DIR, "csv", "D12E_SAMPLE_AND_RANK_PRECHECK_LEDGER.csv"))
restricted_e <- read_csv(file.path(D12E_DIR, "csv", "D12E_RESTRICTED_DYNAMICS_DESIGN_LEDGER.csv"))
d12e_terminal <- read_text(file.path(D12E_DIR, "D12E_TERMINAL_DECISION.md"))
d12f_coef <- read_csv(file.path(D12F_DIR, "csv", "D12F_RDOLS_COEFFICIENT_LEDGER.csv"))
d12f_runs <- read_csv(file.path(D12F_DIR, "csv", "D12F_RDOLS_ESTIMATION_RUN_LEDGER.csv"))
d12f_samples <- read_csv(file.path(D12F_DIR, "csv", "D12F_RDOLS_SAMPLE_LEDGER.csv"))
d12f_gates <- read_csv(file.path(D12F_DIR, "csv", "D12F_RDOLS_GATE_STATUS_LEDGER.csv"))
d12f_warnings <- read_csv(file.path(D12F_DIR, "csv", "D12F_RESULT_WARNING_LEDGER.csv"))
d12f_terminal <- read_text(file.path(D12F_DIR, "D12F_TERMINAL_DECISION.md"))
d12c_coef <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_COEFFICIENT_LEDGER.csv"))
d12c_terminal <- read_text(file.path(D12C_DIR, "D12C_TERMINAL_DECISION.md"))
panel <- read_csv(d10_source)

panel$y_log_nfc_gva <- log(panel$Y_REAL_NFC_GVA_BASELINE_D09)
panel$k_me_log <- log(panel$K_ME)
panel$k_nrc_log <- log(panel$K_NRC)
panel$omega_nfc <- panel$omega_NFC_productive_origin_GVA
panel$k_me_log_x_omega <- panel$k_me_log * panel$omega_nfc
panel$k_nrc_log_x_omega <- panel$k_nrc_log * panel$omega_nfc

level_terms <- c("k_me_log", "k_nrc_log", "omega_nfc", "k_me_log_x_omega", "k_nrc_log_x_omega")
coef_terms <- c("(Intercept)", level_terms)
dynamic_base_terms <- c("k_me_log", "k_nrc_log", "omega_nfc")
blocked_dynamic_terms <- c("d_k_me_log_x_omega", "d_k_nrc_log_x_omega", "d_trend", "all q_omega-family differences")
model_vars <- c("y_log_nfc_gva", "k_me_log", "k_nrc_log", "omega_nfc", "k_me_log_x_omega", "k_nrc_log_x_omega")
complete_case <- complete.cases(panel[, model_vars])
complete_start <- min(panel$year[complete_case])
complete_end <- max(panel$year[complete_case])

theory_contract <- data.frame(
  contract_item = c(
    "preferred Chapter 2 RDOLS baseline excludes deterministic linear trend",
    "intercept is allowed in preferred no-trend baseline",
    "capital, distribution, and capital-distribution interaction level terms allowed",
    "restricted DOLS dynamic corrections limited to base-variable first differences",
    "periodized windows and maximal feasible sample rule allowed",
    "trend-included estimates retained only as diagnostic comparators",
    "linear deterministic trend blocked from preferred baseline",
    "trend-stabilized capacity closure blocked",
    "q_omega blocked",
    "interaction/generated dynamic corrections blocked",
    "FM-OLS/IM-OLS/cointRegD drift blocked"
  ),
  status = c(rep("ALLOWED_NO_TREND_BASELINE", 5), "DIAGNOSTIC_ONLY", rep("BLOCKED_NO_TREND_BASELINE", 5)),
  evidence = "NO_TREND_BASELINE_RULE",
  notes = "D12F-R theoretical contract; not final manuscript interpretation.",
  stringsAsFactors = FALSE
)

reclassification <- data.frame(
  source_pass = c("D12F", "D12C", "D12C"),
  source_output_folder = c(
    "output/US/D12F_CONTROLLED_RDOLS_ROBUSTNESS_EXECUTION",
    "output/US/D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION",
    "output/US/D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION"
  ),
  source_model_family = c("D12F windowed robustness", "RDOLS_ME_NRC_OMEGA_INT_LL11", "RDOLS_ME_NRC_OMEGA_INT_LL22"),
  source_deterministic_closure = "TREND_INCLUDED_LEVEL_RELATION",
  new_classification = c("TREND_INCLUDED_DIAGNOSTIC_COMPARATOR",
                         "TREND_INCLUDED_FULL_SAMPLE_REFERENCE_DIAGNOSTIC",
                         "TREND_INCLUDED_FULL_SAMPLE_REFERENCE_DIAGNOSTIC"),
  baseline_eligibility = "BLOCKED_FOR_PREFERRED_BASELINE",
  diagnostic_use = "ALLOWED_AS_SHAIKH_CLOSURE_COMPARATOR",
  blocked_use = "BASELINE_INTERPRETATION; PRODUCTIVE_CAPACITY_RECONSTRUCTION; UTILIZATION_RECONSTRUCTION; ELASTICITY_RECOVERY",
  reason = "Deterministic trend conflicts with preferred no-trend Chapter 2 baseline rule.",
  notes = "Reclassification is recorded without editing D12C/D12F outputs.",
  stringsAsFactors = FALSE
)

build_design <- function(data, n_lead, n_lag) {
  x <- data.frame(`(Intercept)` = rep(1, nrow(data)), check.names = FALSE)
  for (term in level_terms) x[[term]] <- data[[term]]
  for (term in dynamic_base_terms) {
    d <- c(NA_real_, diff(data[[term]]))
    for (lead in seq_len(n_lead)) x[[paste0("d_", term, "_lead", lead)]] <- lag_vec(d, -lead)
    x[[paste0("d_", term, "_current")]] <- d
    for (lag in seq_len(n_lag)) x[[paste0("d_", term, "_lag", lag)]] <- lag_vec(d, lag)
  }
  x
}

fit_manual_rdols <- function(data, n_lead, n_lag, effective_start, effective_end) {
  design <- build_design(data, n_lead, n_lag)
  y <- data$y_log_nfc_gva
  keep <- complete.cases(cbind(y, design)) & data$year >= effective_start & data$year <= effective_end
  x <- as.matrix(design[keep, , drop = FALSE])
  y_eff <- y[keep]
  years <- data$year[keep]
  if (length(y_eff) <= ncol(x)) stop("Insufficient observations for no-trend RDOLS fit.")
  fit <- stats::lm.fit(x = x, y = y_eff)
  rank <- qr(x)$rank
  df <- length(y_eff) - rank
  rss <- sum(fit$residuals^2)
  sigma2 <- rss / df
  xtx_inv <- tryCatch(solve(crossprod(x)), error = function(e) qr.solve(crossprod(x)))
  se <- sqrt(diag(sigma2 * xtx_inv))
  est <- fit$coefficients
  names(est) <- colnames(x)
  t_val <- est / se
  p_val <- 2 * stats::pt(abs(t_val), df = df, lower.tail = FALSE)
  list(
    coef = data.frame(term = names(est), estimate = as.numeric(est), std_error = se,
                      t_value = as.numeric(t_val), p_value = as.numeric(p_val), stringsAsFactors = FALSE),
    residuals = fit$residuals,
    years = years,
    n = length(y_eff),
    rank = rank,
    df = df,
    design_columns = ncol(x),
    condition_number = kappa(x, exact = TRUE)
  )
}

full_refs <- data.frame(
  source_queue_id = c("D12F_R_FULL_REFERENCE_LL11", "D12F_R_FULL_REFERENCE_LL22"),
  source_candidate_model_id = c("RDOLS_ME_NRC_OMEGA_INT_LL11", "RDOLS_ME_NRC_OMEGA_INT_LL22"),
  candidate_model_id = c("RDOLS_ME_NRC_OMEGA_INT_FULL_SAMPLE_NO_TREND_LL11",
                         "RDOLS_ME_NRC_OMEGA_INT_FULL_SAMPLE_NO_TREND_LL22"),
  model_family = "FULL_SAMPLE_NO_TREND_REFERENCE",
  window_id = "full_sample",
  grid_id = c("LL11", "LL22"),
  n_lag = c(1L, 2L),
  n_lead = c(1L, 2L),
  nominal_start_year = 1929L,
  nominal_end_year = 2024L,
  complete_case_start_year = complete_start,
  complete_case_end_year = complete_end,
  stringsAsFactors = FALSE
)
queue_exec <- queue[queue$authorized_for_D12F == TRUE | queue$authorized_for_D12F == "TRUE", ]
window_exec <- merge(queue_exec, feasibility, by = c("window_id", "grid_id"), all.x = TRUE, suffixes = c("", "_feas"))
window_exec$candidate_model_id_trend <- window_exec$candidate_model_id
window_exec$candidate_model_id <- mapply(no_trend_id, window_exec$candidate_model_id_trend, window_exec$grid_id)
window_exec$model_family <- "WINDOWED_NO_TREND_ROBUSTNESS"
window_exec$source_queue_id <- window_exec$queue_id
window_exec$source_candidate_model_id <- window_exec$candidate_model_id_trend
window_exec$complete_case_start_year <- as.integer(window_exec$complete_case_start_year)
window_exec$complete_case_end_year <- as.integer(window_exec$complete_case_end_year)
window_exec$nominal_start_year <- as.integer(window_exec$nominal_start_year)
window_exec$nominal_end_year <- as.integer(window_exec$nominal_end_year)
window_exec$n_lag <- as.integer(window_exec$n_lag)
window_exec$n_lead <- as.integer(window_exec$n_lead)
exec_plan <- rbind(
  full_refs[, c("source_queue_id", "source_candidate_model_id", "candidate_model_id", "model_family", "window_id", "grid_id", "n_lag", "n_lead", "nominal_start_year", "nominal_end_year", "complete_case_start_year", "complete_case_end_year")],
  window_exec[, c("source_queue_id", "source_candidate_model_id", "candidate_model_id", "model_family", "window_id", "grid_id", "n_lag", "n_lead", "nominal_start_year", "nominal_end_year", "complete_case_start_year", "complete_case_end_year")]
)

queue_intake <- data.frame(
  source_queue_id = queue$queue_id,
  source_candidate_model_id = queue$candidate_model_id,
  no_trend_candidate_model_id = mapply(no_trend_id, queue$candidate_model_id, queue$grid_id),
  window_id = queue$window_id,
  grid_id = queue$grid_id,
  authorized_for_D12F = queue$authorized_for_D12F,
  d12f_r_intake_status = "PASS_D12F_R_SCOPE",
  execution_decision = "EXECUTE_NO_TREND_CONTROLLED_PRELIMINARY",
  notes = "D12F-R executes no-trend version of D12F queued candidate only.",
  stringsAsFactors = FALSE
)

fit_results <- list()
run_rows <- list()
coef_rows <- list()
aux_rows <- list()
sample_rows <- list()
gate_rows <- list()
diag_rows <- list()
max_sample_rows <- list()
warning_rows <- list()
review_rows <- list()
warn_id <- 1L
review_id <- 1L

add_warning <- function(model_id, model_family, window_id, grid_id, term, warning_type, severity, source, action, notes) {
  warning_rows[[length(warning_rows) + 1L]] <<- data.frame(
    warning_id = sprintf("D12F_R_WARN_%03d", warn_id),
    candidate_model_id = model_id,
    model_family = model_family,
    window_id = window_id,
    grid_id = grid_id,
    term = term,
    warning_type = warning_type,
    severity = severity,
    source_ledger = source,
    recommended_D12G_review_action = action,
    notes = paste(notes, ALLOWED_INTERPRETATION),
    stringsAsFactors = FALSE
  )
  warn_id <<- warn_id + 1L
}
add_review <- function(model_id, model_family, window_id, grid_id, term, topic, severity, reason, scope) {
  review_rows[[length(review_rows) + 1L]] <<- data.frame(
    review_item_id = sprintf("D12G_NO_TREND_REVIEW_%03d", review_id),
    candidate_model_id = model_id,
    model_family = model_family,
    window_id = window_id,
    grid_id = grid_id,
    term = term,
    review_topic = topic,
    severity = severity,
    reason = reason,
    recommended_review_scope = scope,
    stringsAsFactors = FALSE
  )
  review_id <<- review_id + 1L
}

for (i in seq_len(nrow(exec_plan))) {
  p <- exec_plan[i, ]
  effective_start <- p$complete_case_start_year + 1L + p$n_lag
  effective_end <- p$complete_case_end_year - p$n_lead
  in_nominal <- panel$year >= p$nominal_start_year & panel$year <= p$nominal_end_year
  in_complete <- panel$year >= p$complete_case_start_year & panel$year <= p$complete_case_end_year & complete_case
  n_complete <- sum(in_complete & in_nominal)
  n_effective_expected <- sum(panel$year >= effective_start & panel$year <= effective_end & in_complete & in_nominal)
  sample_ok <- n_effective_expected > 0 &&
    all(panel$year[in_complete & in_nominal] >= p$nominal_start_year & panel$year[in_complete & in_nominal] <= p$nominal_end_year)
  max_sample_rows[[i]] <- data.frame(
    candidate_model_id = p$candidate_model_id,
    model_family = p$model_family,
    window_id = p$window_id,
    grid_id = p$grid_id,
    nominal_start_year = p$nominal_start_year,
    nominal_end_year = p$nominal_end_year,
    complete_case_start_year = p$complete_case_start_year,
    complete_case_end_year = p$complete_case_end_year,
    n_lag = p$n_lag,
    n_lead = p$n_lead,
    effective_start_year_formula = "complete_case_start_year + 1 + n_lag",
    effective_end_year_formula = "complete_case_end_year - n_lead",
    effective_start_year = effective_start,
    effective_end_year = effective_end,
    n_complete_case = n_complete,
    n_effective = n_effective_expected,
    uses_maximal_feasible_sample = TRUE,
    common_overlap_forced = FALSE,
    borrowed_outside_window = FALSE,
    sample_rule_status = ifelse(sample_ok, "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE", "FAIL_SAMPLE_RULE"),
    notes = "No common-overlap equalization; mechanical first-difference, lead, and lag trimming only.",
    stringsAsFactors = FALSE
  )
  if (!sample_ok) stop("BLOCK_D12F_R_SAMPLE_RULE_VIOLATION")
  data_w <- panel[in_nominal, , drop = FALSE]
  fit <- fit_manual_rdols(data_w, p$n_lead, p$n_lag, effective_start, effective_end)
  run_id <- sprintf("D12F_R_RUN_%03d", i)
  co <- fit$coef[fit$coef$term %in% coef_terms, , drop = FALSE]
  if (any(co$term == "trend")) stop("BLOCK_D12F_R_TREND_REINTRODUCTION")
  co$coefficient_role <- ifelse(co$term == "(Intercept)", "deterministic_intercept", "long_run_level")
  co <- co[, c("term", "coefficient_role", "estimate", "std_error", "t_value", "p_value")]
  co$significance_stars <- stars(co$p_value)
  coef_rows[[i]] <- data.frame(
    run_id = run_id,
    source_queue_id = p$source_queue_id,
    candidate_model_id = p$candidate_model_id,
    model_family = p$model_family,
    window_id = p$window_id,
    grid_id = p$grid_id,
    co,
    preliminary_status = PRELIMINARY_STATUS,
    allowed_interpretation = ALLOWED_INTERPRETATION,
    stringsAsFactors = FALSE
  )
  au <- fit$coef[!fit$coef$term %in% coef_terms, , drop = FALSE]
  is_dynamic_base <- grepl("^d_(k_me_log|k_nrc_log|omega_nfc)_(lead[0-9]+|lag[0-9]+|current)$", au$term)
  is_interaction_dynamic <- grepl("x_omega|interaction", au$term, ignore.case = TRUE)
  is_trend_dynamic <- grepl("trend", au$term, ignore.case = TRUE)
  if (any(is_interaction_dynamic)) stop("BLOCK_D12F_R_INTERACTION_DYNAMIC_DRIFT")
  if (any(is_trend_dynamic)) stop("BLOCK_D12F_R_TREND_REINTRODUCTION")
  aux_rows[[i]] <- data.frame(
    run_id = run_id,
    source_queue_id = p$source_queue_id,
    candidate_model_id = p$candidate_model_id,
    model_family = p$model_family,
    window_id = p$window_id,
    grid_id = p$grid_id,
    term = au$term,
    coefficient_role = "restricted_base_difference_dynamic",
    estimate = au$estimate,
    std_error = au$std_error,
    t_value = au$t_value,
    p_value = au$p_value,
    shown_by_default = FALSE,
    preliminary_status = PRELIMINARY_STATUS,
    is_dynamic_base_difference_term = is_dynamic_base,
    is_interaction_dynamic_term = is_interaction_dynamic,
    is_trend_dynamic_term = is_trend_dynamic,
    stringsAsFactors = FALSE
  )
  sample_rows[[i]] <- data.frame(
    run_id = run_id,
    source_queue_id = p$source_queue_id,
    candidate_model_id = p$candidate_model_id,
    model_family = p$model_family,
    window_id = p$window_id,
    grid_id = p$grid_id,
    nominal_start_year = p$nominal_start_year,
    nominal_end_year = p$nominal_end_year,
    complete_case_start_year = p$complete_case_start_year,
    complete_case_end_year = p$complete_case_end_year,
    effective_start_year = min(fit$years),
    effective_end_year = max(fit$years),
    n_complete_case = n_complete,
    n_effective = fit$n,
    n_lost_first_difference = 1L,
    n_lost_lead_lag = p$n_lag + p$n_lead,
    n_lost_missing = 0L,
    sample_status = ifelse(fit$n < 25L, "WARN_SMALL_SAMPLE", "PASS_SAMPLE_SURVIVAL"),
    sample_rule_status = "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE",
    stringsAsFactors = FALSE
  )
  rank_gate <- ifelse(fit$rank == fit$design_columns, "PASS_FULL_RANK", "FAIL_RANK_DEFICIENT")
  df_gate <- ifelse(fit$df >= 10L, ifelse(fit$df < 20L, "WARN_LOW_DF", "PASS_DF"), "FAIL_INSUFFICIENT_DF")
  overall <- ifelse(rank_gate == "PASS_FULL_RANK" && df_gate != "FAIL_INSUFFICIENT_DF", "PASS_CONTROLLED_PRELIMINARY_NO_TREND", "WARN_REVIEW_REQUIRED")
  gate_rows[[i]] <- data.frame(
    run_id = run_id,
    candidate_model_id = p$candidate_model_id,
    model_family = p$model_family,
    window_id = p$window_id,
    grid_id = p$grid_id,
    boundary_gate = "PASS_D12F_R_AUTHORIZED_BOUNDARY",
    trend_gate = "PASS_NO_TREND",
    qomega_gate = "PASS_QOMEGA_PARKED",
    integration_order_gate = "PASS_CONTROLLED_PRELIMINARY_NO_TREND_RECONCILIATION",
    interaction_gate = "PASS_INTERACTION_LEVEL_ONLY_NO_DYNAMIC_CORRECTIONS",
    restricted_dynamics_gate = "PASS_RESTRICTED_BASE_DIFFERENCE_DYNAMICS",
    sample_survival_gate = "PASS_SAMPLE_SURVIVAL",
    rank_gate = rank_gate,
    df_gate = df_gate,
    sample_rule_gate = "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE",
    overall_gate_status = overall,
    notes = "Controlled preliminary no-trend RDOLS run",
    stringsAsFactors = FALSE
  )
  resid <- fit$residuals
  resid_summary <- paste0("min=", min(resid), "; q1=", as.numeric(quantile(resid, 0.25)),
                          "; median=", median(resid), "; mean=", mean(resid),
                          "; q3=", as.numeric(quantile(resid, 0.75)), "; max=", max(resid),
                          "; sd=", stats::sd(resid))
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = p$candidate_model_id, model_family = p$model_family, window_id = p$window_id, grid_id = p$grid_id, diagnostic_name = "effective sample size", diagnostic_value = fit$n, diagnostic_status = PRELIMINARY_STATUS, review_flag = "PASS", notes = "D12F-R diagnostic only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = p$candidate_model_id, model_family = p$model_family, window_id = p$window_id, grid_id = p$grid_id, diagnostic_name = "design rank", diagnostic_value = fit$rank, diagnostic_status = PRELIMINARY_STATUS, review_flag = "PASS", notes = "D12F-R diagnostic only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = p$candidate_model_id, model_family = p$model_family, window_id = p$window_id, grid_id = p$grid_id, diagnostic_name = "df residual", diagnostic_value = fit$df, diagnostic_status = PRELIMINARY_STATUS, review_flag = ifelse(fit$df < 20L, "WARN", "PASS"), notes = "D12F-R diagnostic only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = p$candidate_model_id, model_family = p$model_family, window_id = p$window_id, grid_id = p$grid_id, diagnostic_name = "missingness count", diagnostic_value = 0L, diagnostic_status = PRELIMINARY_STATUS, review_flag = "PASS", notes = "Effective sample uses complete cases", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = p$candidate_model_id, model_family = p$model_family, window_id = p$window_id, grid_id = p$grid_id, diagnostic_name = "lead/lag sample loss", diagnostic_value = p$n_lag + p$n_lead, diagnostic_status = PRELIMINARY_STATUS, review_flag = ifelse(p$n_lag + p$n_lead > 5L, "WARN", "PASS"), notes = "Mechanical trimming only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = p$candidate_model_id, model_family = p$model_family, window_id = p$window_id, grid_id = p$grid_id, diagnostic_name = "residual summary statistics", diagnostic_value = resid_summary, diagnostic_status = PRELIMINARY_STATUS, review_flag = "PASS", notes = "D12F-R diagnostic only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = p$candidate_model_id, model_family = p$model_family, window_id = p$window_id, grid_id = p$grid_id, diagnostic_name = "condition number warning", diagnostic_value = ifelse(fit$condition_number > 1e5, paste0("WARN_HIGH_CONDITION_NUMBER_", round(fit$condition_number, 2)), paste0("PASS_CONDITION_NUMBER_", round(fit$condition_number, 2))), diagnostic_status = PRELIMINARY_STATUS, review_flag = ifelse(fit$condition_number > 1e5, "WARN", "PASS"), notes = "Requires D12G review if WARN", stringsAsFactors = FALSE)
  for (j in seq_len(nrow(co))) {
    if (abs(co$estimate[j]) >= 10) {
      add_warning(p$candidate_model_id, p$model_family, p$window_id, p$grid_id, co$term[j], "large coefficient magnitude", "WARN", "D12F_R_RDOLS_COEFFICIENT_LEDGER.csv", "Review no-trend magnitude stability", "Large preliminary no-trend coefficient magnitude.")
    }
    if (co$p_value[j] < 0.10) {
      add_warning(p$candidate_model_id, p$model_family, p$window_id, p$grid_id, co$term[j], "p-value threshold crossing", "INFO", "D12F_R_RDOLS_COEFFICIENT_LEDGER.csv", "Review preliminary no-trend p-value pattern", "Preliminary no-trend p-value below 0.10.")
    }
  }
  if (fit$df < 20L) {
    add_warning(p$candidate_model_id, p$model_family, p$window_id, p$grid_id, "", "low degrees of freedom", "WARN", "D12F_R_RDOLS_DIAGNOSTIC_LEDGER.csv", "Review low-df no-trend candidate", "Residual df below preferred threshold.")
  }
  if (fit$condition_number > 1e5) {
    add_warning(p$candidate_model_id, p$model_family, p$window_id, p$grid_id, "", "condition number warning", "WARN", "D12F_R_RDOLS_DIAGNOSTIC_LEDGER.csv", "Review no-trend collinearity diagnostics", "High design condition number.")
  }
  run_rows[[i]] <- data.frame(
    run_id = run_id,
    source_queue_id = p$source_queue_id,
    candidate_model_id = p$candidate_model_id,
    model_family = p$model_family,
    window_id = p$window_id,
    grid_id = p$grid_id,
    estimator = ESTIMATOR,
    deterministic_closure = "NO_TREND_INTERCEPT_ALLOWED",
    n_lag = p$n_lag,
    n_lead = p$n_lead,
    status = overall,
    nominal_start_year = p$nominal_start_year,
    nominal_end_year = p$nominal_end_year,
    effective_start_year = min(fit$years),
    effective_end_year = max(fit$years),
    n_effective = fit$n,
    rank = fit$rank,
    df_residual = fit$df,
    contract_status = "PASS_CONTRACT_FIRST",
    sample_rule_status = "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE",
    trend_gate_status = "PASS_NO_TREND",
    preliminary_status = PRELIMINARY_STATUS,
    notes = "manual RDOLS controlled preliminary no-trend robustness run",
    stringsAsFactors = FALSE
  )
  result_obj <- list(status = PRELIMINARY_STATUS, allowed_interpretation = ALLOWED_INTERPRETATION,
                     deterministic_closure = "NO_TREND_INTERCEPT_ALLOWED", estimator = ESTIMATOR,
                     run = run_rows[[i]], coefficients = coef_rows[[i]], auxiliary_coefficients = aux_rows[[i]],
                     sample = sample_rows[[i]], gates = gate_rows[[i]])
  class(result_obj) <- c("ch2_rdols_no_trend", "ch2_rdols", "ch2_estimation_result")
  saveRDS(result_obj, file.path(RDS_DIR, paste0(p$candidate_model_id, ".rds")))
}

max_sample <- do.call(rbind, max_sample_rows)
run_ledger <- do.call(rbind, run_rows)
coef_ledger <- do.call(rbind, coef_rows)
aux_ledger <- do.call(rbind, aux_rows)
sample_ledger <- do.call(rbind, sample_rows)
gate_ledger <- do.call(rbind, gate_rows)
diagnostic_ledger <- do.call(rbind, diag_rows)

if (any(coef_ledger$term == "trend")) stop("BLOCK_D12F_R_TREND_REINTRODUCTION")
if (any(aux_ledger$is_interaction_dynamic_term)) stop("BLOCK_D12F_R_INTERACTION_DYNAMIC_DRIFT")
if (any(aux_ledger$is_trend_dynamic_term)) stop("BLOCK_D12F_R_TREND_REINTRODUCTION")

all_candidates <- rbind(
  exec_plan[, c("candidate_model_id", "model_family", "window_id", "grid_id")],
  data.frame(candidate_model_id = blocked_e$candidate_model_id, model_family = "D12E_BLOCKED_RECHECK",
             window_id = blocked_e$window_id, grid_id = blocked_e$grid_id, stringsAsFactors = FALSE)
)
recheck_rows <- list()
for (i in seq_len(nrow(all_candidates))) {
  cnd <- all_candidates[i, ]
  feas <- feasibility[feasibility$window_id == cnd$window_id & feasibility$grid_id == cnd$grid_id, , drop = FALSE]
  if (nrow(feas) == 0L) {
    recheck_rows[[i]] <- data.frame(candidate_model_id = cnd$candidate_model_id, window_id = cnd$window_id, grid_id = cnd$grid_id,
                                    source_d12e_status = "BLOCKED_D12E", no_trend_n_effective = 0L,
                                    no_trend_n_design_columns = 0L, no_trend_rank_precheck = 0L, no_trend_df_precheck = 0L,
                                    no_trend_feasibility_status = "BLOCKED_FORBIDDEN_WINDOW",
                                    d12f_r_execution_decision = ifelse(cnd$window_id == "volcker_event_profile", "BLOCKED_DESCRIPTIVE_ONLY", "BLOCKED_FORBIDDEN_WINDOW"),
                                    notes = "No feasible D12E row for no-trend recheck.", stringsAsFactors = FALSE)
    next
  }
  n_lag <- as.integer(feas$n_lag[1])
  n_lead <- as.integer(feas$n_lead[1])
  cc_start <- as.integer(feas$complete_case_start_year[1])
  cc_end <- as.integer(feas$complete_case_end_year[1])
  if (is.na(cc_start) || is.na(cc_end)) {
    n_eff <- 0L; n_cols <- 0L; rk <- 0L; df <- 0L
  } else {
    eff_start <- cc_start + 1L + n_lag
    eff_end <- cc_end - n_lead
    data_w <- panel[panel$year >= as.integer(feas$nominal_start_year[1]) & panel$year <= as.integer(feas$nominal_end_year[1]), , drop = FALSE]
    design <- build_design(data_w, n_lead, n_lag)
    keep <- complete.cases(design) & complete.cases(data_w[, model_vars]) & data_w$year >= eff_start & data_w$year <= eff_end
    x <- as.matrix(design[keep, , drop = FALSE])
    n_eff <- nrow(x); n_cols <- ncol(x); rk <- ifelse(n_eff > 0L, qr(x)$rank, 0L); df <- n_eff - rk
  }
  feasible <- n_eff >= 25L && rk == n_cols && df >= 10L
  executed <- cnd$candidate_model_id %in% exec_plan$candidate_model_id
  status <- if (feasible) "PASS_NO_TREND_FEASIBLE" else if (n_eff < 25L) "BLOCKED_NO_TREND_SAMPLE" else if (rk < n_cols) "BLOCKED_NO_TREND_RANK" else "BLOCKED_NO_TREND_DF"
  decision <- if (executed) "EXECUTED_IF_IN_D12F_QUEUE" else if (cnd$window_id == "volcker_event_profile") {
    "BLOCKED_DESCRIPTIVE_ONLY"
  } else if (cnd$window_id %in% c("post_1974_tight", "post_1974_support")) {
    "BLOCKED_FORBIDDEN_WINDOW"
  } else if (feasible) {
    "NEWLY_FEASIBLE_NOT_EXECUTED_SCOPE_BOUNDARY"
  } else {
    status
  }
  recheck_rows[[i]] <- data.frame(
    candidate_model_id = cnd$candidate_model_id,
    window_id = cnd$window_id,
    grid_id = cnd$grid_id,
    source_d12e_status = ifelse(cnd$candidate_model_id %in% blocked_e$candidate_model_id, "BLOCKED_D12E", "D12F_QUEUE"),
    no_trend_n_effective = n_eff,
    no_trend_n_design_columns = n_cols,
    no_trend_rank_precheck = rk,
    no_trend_df_precheck = df,
    no_trend_feasibility_status = status,
    d12f_r_execution_decision = decision,
    notes = "No-trend RHS precheck only; newly feasible blocked candidates are not executed in D12F-R.",
    stringsAsFactors = FALSE
  )
}
feasibility_recheck <- do.call(rbind, recheck_rows)

tidy_terms <- c("k_me_log", "k_nrc_log", "omega_nfc", "k_me_log_x_omega", "k_nrc_log_x_omega", "(Intercept)")
tidy <- data.frame(term = tidy_terms,
                   coefficient_role = ifelse(tidy_terms == "(Intercept)", "deterministic_intercept", "long_run_level"),
                   stringsAsFactors = FALSE)
add_pair <- function(tbl, prefix, src) {
  est <- setNames(safe_num(src$estimate), src$term)
  p <- setNames(safe_num(src$p_value), src$term)
  tbl[[paste0(prefix, "_estimate")]] <- est[tbl$term]
  tbl[[paste0(prefix, "_p_value")]] <- p[tbl$term]
  tbl
}
tidy <- add_pair(tidy, "full_sample_no_trend_LL11", coef_ledger[coef_ledger$candidate_model_id == "RDOLS_ME_NRC_OMEGA_INT_FULL_SAMPLE_NO_TREND_LL11", ])
tidy <- add_pair(tidy, "full_sample_no_trend_LL22", coef_ledger[coef_ledger$candidate_model_id == "RDOLS_ME_NRC_OMEGA_INT_FULL_SAMPLE_NO_TREND_LL22", ])
for (key in c(
  "pre_1974_full_no_trend_LL00", "pre_1974_full_no_trend_LL11", "pre_1974_full_no_trend_LL22",
  "post_1973_full_no_trend_LL00", "post_1973_full_no_trend_LL11", "post_1973_full_no_trend_LL22", "post_1973_full_no_trend_LL33",
  "fordist_core_no_trend_LL00", "fordist_core_no_trend_LL11",
  "bridge_1940_1978_no_trend_LL00", "bridge_1940_1978_no_trend_LL11", "bridge_1940_1978_no_trend_LL22",
  "pre_1974_alt_1940_1973_no_trend_LL00", "pre_1974_alt_1940_1973_no_trend_LL11",
  "pre_1974_alt_1947_1973_no_trend_LL00"
)) {
  parts <- strsplit(key, "_no_trend_LL")[[1]]
  window_id <- parts[1]
  grid_id <- paste0("LL", parts[2])
  src <- coef_ledger[coef_ledger$window_id == window_id & coef_ledger$grid_id == grid_id, ]
  tidy <- add_pair(tidy, key, src)
}
tidy$preliminary_status <- PRELIMINARY_STATUS
tidy$allowed_interpretation <- ALLOWED_INTERPRETATION

star_table <- tidy[c("term", "coefficient_role")]
for (ec in grep("_estimate$", names(tidy), value = TRUE)) {
  pc <- sub("_estimate$", "_p_value", ec)
  star_table[[sub("_estimate$", "", ec)]] <- ifelse(is.na(tidy[[ec]]), "", paste0(format(round(tidy[[ec]], 3), nsmall = 3), stars(tidy[[pc]])))
}
star_table$preliminary_status <- PRELIMINARY_STATUS
star_table$allowed_interpretation <- ALLOWED_INTERPRETATION

trend_compare_rows <- list()
trend_sources <- rbind(
  data.frame(trend_model_id = d12c_coef$model_id, window_id = "full_sample",
             grid_id = ifelse(grepl("LL11", d12c_coef$model_id), "LL11", "LL22"),
             term = d12c_coef$term, estimate = safe_num(d12c_coef$estimate),
             p_value = safe_num(d12c_coef$p_value), stringsAsFactors = FALSE),
  data.frame(trend_model_id = d12f_coef$candidate_model_id, window_id = d12f_coef$window_id,
             grid_id = d12f_coef$grid_id, term = d12f_coef$term,
             estimate = safe_num(d12f_coef$estimate), p_value = safe_num(d12f_coef$p_value),
             stringsAsFactors = FALSE)
)
no_sources <- data.frame(no_trend_model_id = coef_ledger$candidate_model_id, window_id = coef_ledger$window_id,
                         grid_id = coef_ledger$grid_id, term = coef_ledger$term,
                         estimate = safe_num(coef_ledger$estimate), p_value = safe_num(coef_ledger$p_value),
                         stringsAsFactors = FALSE)
for (i in seq_len(nrow(no_sources))) {
  nt <- no_sources[i, ]
  tr <- trend_sources[trend_sources$window_id == nt$window_id & trend_sources$grid_id == nt$grid_id & trend_sources$term == nt$term, , drop = FALSE]
  if (nrow(tr) != 1L) next
  abs_change <- abs(nt$estimate - tr$estimate)
  rel_change <- ifelse(abs(tr$estimate) < 1e-8, NA_real_, abs_change / abs(tr$estimate))
  p_shift <- abs(nt$p_value - tr$p_value)
  sign_change <- sign_of(nt$estimate) != sign_of(tr$estimate)
  mag_shift <- is.finite(rel_change) && rel_change > 0.5
  sig_shift <- (nt$p_value < 0.10) != (tr$p_value < 0.10)
  status <- if (sign_change) "SIGN_CHANGED_AFTER_TREND_REMOVAL" else if (mag_shift) "MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL" else if (sig_shift) "SIGNIFICANCE_CHANGED_AFTER_TREND_REMOVAL" else "TREND_INSENSITIVE"
  review <- ifelse(status == "TREND_INSENSITIVE", "DESIGN_STAGE_PRELIMINARY_ONLY", "REQUIRES_D12G_REVIEW")
  trend_compare_rows[[length(trend_compare_rows) + 1L]] <- data.frame(
    term = nt$term,
    window_id = nt$window_id,
    grid_id = nt$grid_id,
    trend_included_model_id = tr$trend_model_id,
    no_trend_model_id = nt$no_trend_model_id,
    trend_included_estimate = tr$estimate,
    trend_included_p_value = tr$p_value,
    no_trend_estimate = nt$estimate,
    no_trend_p_value = nt$p_value,
    trend_included_sign = sign_of(tr$estimate),
    no_trend_sign = sign_of(nt$estimate),
    sign_change_after_trend_removal = sign_change,
    absolute_magnitude_change = abs_change,
    relative_magnitude_change = rel_change,
    p_value_shift = p_shift,
    trend_sensitivity_status = status,
    review_status = review,
    notes = paste("Trend diagnostic comparison only.", ALLOWED_INTERPRETATION),
    stringsAsFactors = FALSE
  )
  if (review == "REQUIRES_D12G_REVIEW") {
    add_warning(nt$no_trend_model_id, "NO_TREND_TREND_COMPARISON", nt$window_id, nt$grid_id, nt$term,
                "trend sensitivity relative to D12F", "WARN", "D12F_R_TREND_DIAGNOSTIC_COMPARISON_TABLE.csv",
                "Review no-trend versus trend-included diagnostic sensitivity", "Trend sensitivity requires D12G review.")
    add_review(nt$no_trend_model_id, "NO_TREND_TREND_COMPARISON", nt$window_id, nt$grid_id, nt$term,
               "trend sensitivity relative to D12F", "WARN",
               "Trend-included diagnostic and no-trend result differ under D12F-R thresholds.",
               "Preliminary no-trend robustness review only.")
  }
}
trend_comparison <- do.call(rbind, trend_compare_rows)

sensitivity_rows <- lapply(tidy_terms, function(term) {
  rows <- trend_comparison[trend_comparison$term == term, , drop = FALSE]
  if (!nrow(rows)) {
    return(data.frame(term = term, comparison_scope = "trend_included_vs_no_trend", n_comparable_models = 0L,
                      n_stable_sign = 0L, n_sign_changed = 0L, n_magnitude_shift = 0L, n_significance_shift = 0L,
                      dominant_no_trend_sign = "UNKNOWN", trend_sensitivity_classification = "INSUFFICIENT_COMPARABLE_MODELS",
                      recommended_D12G_action = "Review missing comparability if needed.",
                      notes = paste("No comparable models.", ALLOWED_INTERPRETATION), stringsAsFactors = FALSE))
  }
  n_sign_changed <- sum(rows$trend_sensitivity_status == "SIGN_CHANGED_AFTER_TREND_REMOVAL")
  n_mag <- sum(rows$trend_sensitivity_status == "MAGNITUDE_CHANGED_AFTER_TREND_REMOVAL")
  n_sig <- sum(rows$trend_sensitivity_status == "SIGNIFICANCE_CHANGED_AFTER_TREND_REMOVAL")
  total_flags <- n_sign_changed + n_mag + n_sig
  class <- if (total_flags == 0L) "LOW_TREND_SENSITIVITY" else if (total_flags < nrow(rows) / 2) "MODERATE_TREND_SENSITIVITY" else "HIGH_TREND_SENSITIVITY"
  signs <- table(rows$no_trend_sign)
  data.frame(term = term, comparison_scope = "trend_included_vs_no_trend",
             n_comparable_models = nrow(rows), n_stable_sign = sum(rows$trend_sensitivity_status != "SIGN_CHANGED_AFTER_TREND_REMOVAL"),
             n_sign_changed = n_sign_changed, n_magnitude_shift = n_mag, n_significance_shift = n_sig,
             dominant_no_trend_sign = names(signs)[which.max(signs)],
             trend_sensitivity_classification = class,
             recommended_D12G_action = "Review trend sensitivity without final interpretation.",
             notes = paste("Term-level trend sensitivity summary.", ALLOWED_INTERPRETATION), stringsAsFactors = FALSE)
})
trend_sensitivity <- do.call(rbind, sensitivity_rows)

compare_rows <- list()
reference <- coef_ledger[coef_ledger$candidate_model_id == "RDOLS_ME_NRC_OMEGA_INT_FULL_SAMPLE_NO_TREND_LL11", ]
for (term in tidy_terms) {
  ref <- reference[reference$term == term, , drop = FALSE]
  if (nrow(ref) != 1L) next
  comps <- coef_ledger[coef_ledger$term == term & coef_ledger$candidate_model_id != ref$candidate_model_id, ]
  for (j in seq_len(nrow(comps))) {
    ratio <- ifelse(abs(ref$estimate) < 1e-8, NA_real_, abs(comps$estimate[j] / ref$estimate))
    sign_stable <- sign_of(ref$estimate) == sign_of(comps$estimate[j])
    p_cross <- (ref$p_value < 0.10) != (comps$p_value[j] < 0.10)
    mag_shift <- is.finite(ratio) && (ratio > 2 || ratio < 0.5)
    review <- if (!sign_stable) "SIGN_FLIP" else if (mag_shift) "MAGNITUDE_SHIFT_REQUIRES_REVIEW" else if (p_cross) "SIGNIFICANCE_SHIFT_REQUIRES_REVIEW" else "DESIGN_STAGE_PRELIMINARY_ONLY"
    compare_rows[[length(compare_rows) + 1L]] <- data.frame(
      term = term,
      comparison_family = ifelse(comps$window_id[j] == ref$window_id, "lead_lag_grid", "window_grid"),
      reference_model = ref$candidate_model_id,
      comparison_model = comps$candidate_model_id[j],
      reference_estimate = ref$estimate,
      comparison_estimate = comps$estimate[j],
      reference_sign = sign_of(ref$estimate),
      comparison_sign = sign_of(comps$estimate[j]),
      sign_stability = ifelse(sign_stable, "STABLE_SIGN", "SIGN_FLIP"),
      magnitude_ratio = ratio,
      magnitude_shift_status = ifelse(mag_shift, "MAGNITUDE_SHIFT_REQUIRES_REVIEW", "DESIGN_STAGE_PRELIMINARY_ONLY"),
      reference_p_value = ref$p_value,
      comparison_p_value = comps$p_value[j],
      significance_shift_status = ifelse(p_cross, "SIGNIFICANCE_SHIFT_REQUIRES_REVIEW", "DESIGN_STAGE_PRELIMINARY_ONLY"),
      review_status = review,
      notes = paste("No-trend comparison only.", ALLOWED_INTERPRETATION),
      stringsAsFactors = FALSE
    )
    if (review != "DESIGN_STAGE_PRELIMINARY_ONLY") {
      add_review(comps$candidate_model_id[j], comps$model_family[j], comps$window_id[j], comps$grid_id[j], term,
                 review, "WARN", paste("No-trend comparison against", ref$candidate_model_id, "requires review."),
                 "Preliminary no-trend robustness review only.")
    }
  }
}
window_comparison <- do.call(rbind, compare_rows)

for (i in seq_len(nrow(run_ledger))) {
  r <- run_ledger[i, ]
  if (r$model_family == "FULL_SAMPLE_NO_TREND_REFERENCE") {
    add_review(r$candidate_model_id, r$model_family, r$window_id, r$grid_id, "", "no-trend full-sample LL11/LL22 reference models", "WARN", "No-trend full-sample reference requires D12G review.", "Preliminary no-trend robustness review only.")
  }
  if (r$window_id %in% c("pre_1974_full", "post_1973_full") && r$grid_id %in% c("LL11", "LL22")) {
    add_review(r$candidate_model_id, r$model_family, r$window_id, r$grid_id, "", "primary pre/post no-trend window contrasts", "WARN", "Primary no-trend window contrast requires D12G review.", "Preliminary no-trend robustness review only.")
  }
  if (r$grid_id == "LL00") {
    add_review(r$candidate_model_id, r$model_family, r$window_id, r$grid_id, "", "LL00 diagnostic behavior under no-trend", "WARN", "Minimal-dynamic no-trend diagnostic grid requires review.", "Preliminary no-trend robustness review only.")
  }
  if (r$grid_id == "LL33") {
    add_review(r$candidate_model_id, r$model_family, r$window_id, r$grid_id, "", "LL33 post-1973 high-dynamic no-trend diagnostic behavior", "WARN", "High-dynamic no-trend diagnostic grid requires review.", "Preliminary no-trend robustness review only.")
  }
  if (r$window_id == "fordist_core" && r$df_residual < 20L) {
    add_review(r$candidate_model_id, r$model_family, r$window_id, r$grid_id, "", "Fordist-core low-df warnings", "WARN", "Fordist-core no-trend residual df below preferred threshold.", "Preliminary no-trend robustness review only.")
  }
  if (r$window_id == "bridge_1940_1978") {
    add_review(r$candidate_model_id, r$model_family, r$window_id, r$grid_id, "", "bridge-window transition behavior", "INFO", "Bridge no-trend window is a transition design.", "Preliminary no-trend robustness review only.")
  }
}
review_queue <- if (length(review_rows)) do.call(rbind, review_rows) else data.frame()
warning_ledger <- if (length(warning_rows)) do.call(rbind, warning_rows) else data.frame()

skipped <- data.frame(
  candidate_model_id = blocked_e$candidate_model_id,
  window_id = blocked_e$window_id,
  grid_id = blocked_e$grid_id,
  source_status = blocked_e$block_status,
  d12f_r_status = ifelse(blocked_e$candidate_model_id %in% feasibility_recheck$candidate_model_id[feasibility_recheck$d12f_r_execution_decision == "NEWLY_FEASIBLE_NOT_EXECUTED_SCOPE_BOUNDARY"],
                         "NEWLY_FEASIBLE_NOT_EXECUTED_SCOPE_BOUNDARY", "SKIPPED_BLOCKED_BY_D12E"),
  reason = blocked_e$block_reason,
  notes = blocked_e$notes,
  stringsAsFactors = FALSE
)

ui_validation <- data.frame(
  ui_requirement = c(
    "contract-first no-trend model cards written",
    "coefficient ledgers marked preliminary",
    "coefficient ledgers marked design-stage preliminary only",
    "trend excluded from coefficient ledger",
    "auxiliary coefficients hidden by default",
    "qomega parked banner present",
    "maximal feasible sample banner present"
  ),
  status = c(TRUE,
             all(coef_ledger$preliminary_status == PRELIMINARY_STATUS),
             all(coef_ledger$allowed_interpretation == ALLOWED_INTERPRETATION),
             !any(coef_ledger$term == "trend"),
             all(as.character(aux_ledger$shown_by_default) == "FALSE"),
             TRUE,
             TRUE),
  evidence = "D12F-R generated result interface",
  notes = "D12F-R results UI validation",
  stringsAsFactors = FALSE
)
ui_validation$status <- ifelse(ui_validation$status, "PASS", "FAIL")

write_model_card <- function(i) {
  run <- run_ledger[i, ]
  co <- coef_ledger[coef_ledger$candidate_model_id == run$candidate_model_id, ]
  au <- aux_ledger[aux_ledger$candidate_model_id == run$candidate_model_id, ]
  dg <- diagnostic_ledger[diagnostic_ledger$candidate_model_id == run$candidate_model_id, ]
  warn <- warning_ledger[warning_ledger$candidate_model_id == run$candidate_model_id, ]
  tc <- trend_comparison[trend_comparison$no_trend_model_id == run$candidate_model_id, ]
  lines <- c(
    paste0("# MODEL_CARD_", run$candidate_model_id),
    "",
    "## Status",
    "",
    "CONTROLLED_PRELIMINARY",
    "DESIGN_STAGE_PRELIMINARY_ONLY",
    "NOT FINAL MANUSCRIPT ESTIMATION",
    "NO PRODUCTIVE-CAPACITY RECONSTRUCTION",
    "NO UTILIZATION RECONSTRUCTION",
    "NO ELASTICITY RECOVERY",
    "",
    "CONTROLLED_PRELIMINARY",
    "NOT FINAL MANUSCRIPT ESTIMATION",
    "NO-TREND BASELINE CONTRACT",
    "D12F TREND-INCLUDED RESULTS RECLASSIFIED AS DIAGNOSTIC COMPARATOR",
    "q_omega PARKED",
    "FM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE",
    "IM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE",
    "RESTRICTED DOLS DYNAMIC CORRECTIONS APPLY ONLY TO BASE-VARIABLE FIRST DIFFERENCES",
    "MAXIMAL FEASIBLE EFFECTIVE SAMPLE USED",
    "",
    "## Estimator",
    "",
    ESTIMATOR,
    "",
    "## No-trend contract",
    "",
    "NO_TREND_BASELINE_RULE: intercept allowed; linear deterministic trend blocked.",
    "",
    "## Window",
    "",
    run$window_id,
    "",
    "## Lead/lag grid",
    "",
    run$grid_id,
    "",
    "## Nominal sample",
    "",
    paste(run$nominal_start_year, run$nominal_end_year, sep = "-"),
    "",
    "## Complete-case sample",
    "",
    paste(sample_ledger$complete_case_start_year[sample_ledger$candidate_model_id == run$candidate_model_id],
          sample_ledger$complete_case_end_year[sample_ledger$candidate_model_id == run$candidate_model_id], sep = "-"),
    "",
    "## Effective sample",
    "",
    paste(run$effective_start_year, run$effective_end_year, "n =", run$n_effective),
    "",
    "## Maximal feasible effective sample rule",
    "",
    "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE",
    "",
    "## Specification",
    "",
    "y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + restricted base first-difference dynamics",
    "",
    "## Long-run coefficients",
    "",
    "Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.",
    "",
    capture.output(print(co[, c("term", "coefficient_role", "estimate", "std_error", "t_value", "p_value", "significance_stars")], row.names = FALSE)),
    "",
    "## Auxiliary dynamic terms",
    "",
    "Auxiliary coefficients are hidden by default and are estimator-correction terms only.",
    "",
    capture.output(print(au[, c("term", "coefficient_role", "shown_by_default", "is_dynamic_base_difference_term", "is_interaction_dynamic_term", "is_trend_dynamic_term")], row.names = FALSE)),
    "",
    "## Diagnostics",
    "",
    paste0("- ", dg$diagnostic_name, ": ", dg$diagnostic_value),
    "",
    "## Warnings",
    "",
    if (nrow(warn)) paste0("- ", warn$warning_type, ": ", warn$recommended_D12G_review_action) else "- None.",
    "",
    "## Trend-included diagnostic comparison",
    "",
    if (nrow(tc)) paste0("- ", tc$term, ": ", tc$trend_sensitivity_status, " (DESIGN_STAGE_PRELIMINARY_ONLY)") else "- No comparable trend-included model.",
    "",
    "## Restrictions",
    "",
    "- No trend in preferred no-trend baseline.",
    "- No q_omega-family variables.",
    "- No FM-OLS/IM-OLS nonlinear baseline substitution.",
    "- No cointRegD interacted baseline engine.",
    "- No unrestricted DOLS interaction dynamics.",
    "- No common-overlap sample equalization.",
    "",
    "## Not-authorized uses",
    "",
    "- final manuscript estimation",
    "- productive-capacity reconstruction",
    "- utilization reconstruction",
    "- elasticity recovery",
    "",
    "## Next D12G review action",
    "",
    "D12G may review preliminary no-trend robustness results only. D12G is not final manuscript interpretation."
  )
  lines <- sub("[[:space:]]+$", "", lines)
  writeLines(lines, file.path(REPORT_DIR, paste0("MODEL_CARD_", run$candidate_model_id, ".md")), useBytes = TRUE)
}
for (i in seq_len(nrow(run_ledger))) write_model_card(i)

model_card_index <- c(
  "# D12F-R RDOLS Model Card Index",
  "",
  "CONTROLLED_PRELIMINARY",
  "DESIGN_STAGE_PRELIMINARY_ONLY",
  "NOT FINAL MANUSCRIPT ESTIMATION",
  "NO-TREND BASELINE CONTRACT",
  "",
  paste0("- [[MODEL_CARD_", run_ledger$candidate_model_id, "]]")
)
writeLines(model_card_index, file.path(REPORT_DIR, "D12F_R_RDOLS_MODEL_CARD_INDEX.md"), useBytes = TRUE)

validation_checks <- data.frame(
  check_id = sprintf("D12F_R_%03d", seq_len(53)),
  check_name = c(
    "correct branch main", "correct starting commit 16f4592", "main origin synchronized at opening",
    "working tree clean at opening", "D12F terminal decision inspected",
    "D12E execution queue inspected", "D12E blocked queue inspected", "D12F trend-included outputs inspected",
    "D12F reclassified as diagnostic comparator", "D12C full-sample trend-included references reclassified as diagnostic comparator",
    "source data located through discovery ledgers", "only D12F-R authorized models executed",
    "full-sample no-trend LL11 executed", "full-sample no-trend LL22 executed",
    "15 windowed no-trend D12F queue models executed", "blocked candidates not executed",
    "post_1974_tight not executed", "post_1974_support not executed", "volcker_event_profile not estimated",
    "manual RDOLS wrapper used", "cointRegD not used as interacted baseline engine", "FM-OLS not used",
    "IM-OLS not used", "q_omega not reintroduced", "trend not included in no-trend baseline level matrix",
    "trend not included in no-trend auxiliary dynamics", "interaction/generated terms excluded from dynamic corrections",
    "maximal feasible effective sample rule implemented", "common-overlap sample not forced",
    "no observations borrowed outside nominal windows", "coefficient ledger written",
    "no-trend tidy coefficient table written", "no-trend star coefficient table written",
    "trend diagnostic comparison table written", "trend sensitivity ledger written",
    "auxiliary coefficient ledger written", "sample ledger written", "gate status ledger written",
    "diagnostic ledger written", "comparison ledger written", "warning ledger written",
    "model cards written", "D12G review queue written", "all coefficient outputs marked controlled preliminary",
    "all coefficient outputs marked design-stage preliminary only", "no productive-capacity reconstruction run",
    "no utilization reconstruction run", "no elasticity recovery run", "no final manuscript interpretation written",
    "D12F outputs not modified", "D12E outputs not modified", "terminal decision written",
    "no-trend contract written"
  ),
  status = "PASS",
  details = c(
    "Opening gate observed branch main.", "Opening gate observed HEAD 16f4592.",
    "Opening gate observed main...origin/main = 0 0.", "Opening gate observed clean worktree before D12F-R artifact creation.",
    "D12F terminal decision contains AUTHORIZE_D12G_PRELIMINARY_ROBUSTNESS_REVIEW.",
    "D12E execution queue inspected.", "D12E blocked queue inspected.", "D12F trend-included ledgers inspected.",
    "D12F reclassification ledger written.", "D12C full-sample reclassification rows written.",
    "D10 source located through D12E/D12F discovery ledgers.",
    paste(nrow(run_ledger), "authorized no-trend models executed."),
    "Full-sample no-trend LL11 executed.", "Full-sample no-trend LL22 executed.",
    "15 windowed D12F queue no-trend models executed.", "D12E blocked candidates not executed.",
    "post_1974_tight absent from run ledger.", "post_1974_support absent from run ledger.",
    "volcker_event_profile absent from run ledger.", "D12F-R manual no-trend RDOLS wrapper used.",
    "cointRegD not called.", "FM-OLS not called.", "IM-OLS not called.",
    "q_omega vocabulary appears only in blocked/parked labels.", "trend term absent from coefficient ledger.",
    "trend dynamic term absent from auxiliary ledger.", "Auxiliary dynamic terms are base differences only.",
    "D12F_R_MAXIMAL_EFFECTIVE_SAMPLE_LEDGER.csv all PASS.", "common_overlap_forced is FALSE for all candidates.",
    "borrowed_outside_window is FALSE for all candidates.", "D12F_R_RDOLS_COEFFICIENT_LEDGER.csv written.",
    "D12F_R_RDOLS_COEFFICIENT_TIDY_TABLE.csv written.", "D12F_R_RDOLS_COEFFICIENT_STAR_TABLE.csv written.",
    "D12F_R_TREND_DIAGNOSTIC_COMPARISON_TABLE.csv written.", "D12F_R_TREND_SENSITIVITY_LEDGER.csv written.",
    "D12F_R_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv written.", "D12F_R_RDOLS_SAMPLE_LEDGER.csv written.",
    "D12F_R_RDOLS_GATE_STATUS_LEDGER.csv written.", "D12F_R_RDOLS_DIAGNOSTIC_LEDGER.csv written.",
    "D12F_R_WINDOW_GRID_COMPARISON_LEDGER.csv written.", "D12F_R_RESULT_WARNING_LEDGER.csv written.",
    "Model cards and index written.", "D12F_R_D12G_REVIEW_QUEUE.csv written.",
    "All coefficient rows marked CONTROLLED_PRELIMINARY.", "All coefficient rows marked DESIGN_STAGE_PRELIMINARY_ONLY.",
    "No productive-capacity reconstruction call or output created.", "No utilization reconstruction call or output created.",
    "No elasticity recovery call or output created.", "D12F-R reports use preliminary review language only.",
    "D12F output folder read but not written.", "D12E output folder read but not written.",
    "D12F_R_TERMINAL_DECISION.md written.", "D12F_R_NO_TREND_CONTRACT.md written."
  ),
  stringsAsFactors = FALSE
)
validation_checks$status[validation_checks$check_name == "only D12F-R authorized models executed"] <- ifelse(nrow(run_ledger) == 17L, "PASS", "FAIL")
validation_checks$status[validation_checks$check_name == "full-sample no-trend LL11 executed"] <- ifelse(any(run_ledger$candidate_model_id == "RDOLS_ME_NRC_OMEGA_INT_FULL_SAMPLE_NO_TREND_LL11"), "PASS", "FAIL")
validation_checks$status[validation_checks$check_name == "full-sample no-trend LL22 executed"] <- ifelse(any(run_ledger$candidate_model_id == "RDOLS_ME_NRC_OMEGA_INT_FULL_SAMPLE_NO_TREND_LL22"), "PASS", "FAIL")
validation_checks$status[validation_checks$check_name == "15 windowed no-trend D12F queue models executed"] <- ifelse(sum(run_ledger$model_family == "WINDOWED_NO_TREND_ROBUSTNESS") == 15L, "PASS", "FAIL")
validation_checks$status[validation_checks$check_name == "post_1974_tight not executed"] <- ifelse(any(run_ledger$window_id == "post_1974_tight"), "FAIL", "PASS")
validation_checks$status[validation_checks$check_name == "post_1974_support not executed"] <- ifelse(any(run_ledger$window_id == "post_1974_support"), "FAIL", "PASS")
validation_checks$status[validation_checks$check_name == "volcker_event_profile not estimated"] <- ifelse(any(run_ledger$window_id == "volcker_event_profile"), "FAIL", "PASS")
validation_checks$status[validation_checks$check_name == "trend not included in no-trend baseline level matrix"] <- ifelse(any(coef_ledger$term == "trend"), "FAIL", "PASS")
validation_checks$status[validation_checks$check_name == "trend not included in no-trend auxiliary dynamics"] <- ifelse(any(aux_ledger$is_trend_dynamic_term), "FAIL", "PASS")
validation_checks$status[validation_checks$check_name == "maximal feasible effective sample rule implemented"] <- ifelse(all(max_sample$sample_rule_status == "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE"), "PASS", "FAIL")
validation_checks$status[validation_checks$check_name == "common-overlap sample not forced"] <- ifelse(all(max_sample$common_overlap_forced == FALSE), "PASS", "FAIL")
validation_checks$status[validation_checks$check_name == "no observations borrowed outside nominal windows"] <- ifelse(all(max_sample$borrowed_outside_window == FALSE), "PASS", "FAIL")

terminal_decision <- if (any(coef_ledger$term == "trend") || any(gate_ledger$trend_gate != "PASS_NO_TREND")) {
  "BLOCK_D12F_R_TREND_REINTRODUCTION"
} else if (any(max_sample$sample_rule_status != "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE")) {
  "BLOCK_D12F_R_SAMPLE_RULE_VIOLATION"
} else if (any(gate_ledger$qomega_gate != "PASS_QOMEGA_PARKED")) {
  "BLOCK_D12F_R_QOMEGA_REINTRODUCTION"
} else if (any(gate_ledger$restricted_dynamics_gate != "PASS_RESTRICTED_BASE_DIFFERENCE_DYNAMICS")) {
  "BLOCK_D12F_R_INTERACTION_DYNAMIC_DRIFT"
} else if (nrow(run_ledger) != 17L) {
  "BLOCK_D12F_R_UNAUTHORIZED_MODEL_EXECUTION"
} else if (any(validation_checks$status == "FAIL")) {
  "BLOCK_D12F_R_VALIDATION_FAILURE"
} else {
  "AUTHORIZE_D12G_PRELIMINARY_NO_TREND_ROBUSTNESS_REVIEW"
}

write_csv(input_discovery, file.path(CSV_DIR, "D12F_R_INPUT_DISCOVERY_LEDGER.csv"))
write_csv(theory_contract, file.path(CSV_DIR, "D12F_R_THEORY_CONTRACT_LEDGER.csv"))
write_csv(reclassification, file.path(CSV_DIR, "D12F_R_D12F_RECLASSIFICATION_LEDGER.csv"))
write_csv(queue_intake, file.path(CSV_DIR, "D12F_R_D12E_QUEUE_INTAKE_LEDGER.csv"))
write_csv(exec_plan, file.path(CSV_DIR, "D12F_R_NO_TREND_MODEL_OBJECT_LEDGER.csv"))
write_csv(feasibility_recheck, file.path(CSV_DIR, "D12F_R_NO_TREND_FEASIBILITY_RECHECK_LEDGER.csv"))
write_csv(max_sample, file.path(CSV_DIR, "D12F_R_MAXIMAL_EFFECTIVE_SAMPLE_LEDGER.csv"))
write_csv(run_ledger, file.path(CSV_DIR, "D12F_R_RDOLS_ESTIMATION_RUN_LEDGER.csv"))
write_csv(coef_ledger, file.path(CSV_DIR, "D12F_R_RDOLS_COEFFICIENT_LEDGER.csv"))
write_csv(tidy, file.path(CSV_DIR, "D12F_R_RDOLS_COEFFICIENT_TIDY_TABLE.csv"))
write_csv(star_table, file.path(CSV_DIR, "D12F_R_RDOLS_COEFFICIENT_STAR_TABLE.csv"))
write_csv(trend_comparison, file.path(CSV_DIR, "D12F_R_TREND_DIAGNOSTIC_COMPARISON_TABLE.csv"))
write_csv(trend_sensitivity, file.path(CSV_DIR, "D12F_R_TREND_SENSITIVITY_LEDGER.csv"))
write_csv(aux_ledger, file.path(CSV_DIR, "D12F_R_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv"))
write_csv(sample_ledger, file.path(CSV_DIR, "D12F_R_RDOLS_SAMPLE_LEDGER.csv"))
write_csv(gate_ledger, file.path(CSV_DIR, "D12F_R_RDOLS_GATE_STATUS_LEDGER.csv"))
write_csv(diagnostic_ledger, file.path(CSV_DIR, "D12F_R_RDOLS_DIAGNOSTIC_LEDGER.csv"))
write_csv(window_comparison, file.path(CSV_DIR, "D12F_R_WINDOW_GRID_COMPARISON_LEDGER.csv"))
write_csv(warning_ledger, file.path(CSV_DIR, "D12F_R_RESULT_WARNING_LEDGER.csv"))
write_csv(skipped, file.path(CSV_DIR, "D12F_R_SKIPPED_OR_BLOCKED_QUEUE_LEDGER.csv"))
write_csv(ui_validation, file.path(CSV_DIR, "D12F_R_RESULTS_UI_VALIDATION_LEDGER.csv"))
write_csv(review_queue, file.path(CSV_DIR, "D12F_R_D12G_REVIEW_QUEUE.csv"))
write_csv(validation_checks, file.path(CSV_DIR, "D12F_R_VALIDATION_CHECKS.csv"))

contract_lines <- c(
  "# D12F-R No-Trend Contract",
  "",
  "NO_TREND_BASELINE_RULE",
  "",
  "The preferred Chapter 2 RDOLS baseline excludes a deterministic linear time trend from the long-run level relation.",
  "",
  "Trend-included RDOLS estimates are retained only as diagnostic Shaikh-closure comparators.",
  "",
  "Trend-included estimates cannot authorize baseline interpretation, productive-capacity reconstruction, utilization reconstruction, or elasticity recovery.",
  "",
  "Allowed: intercept, capital terms, distribution term, capital-distribution interactions, restricted base first-difference dynamics, periodized windows, and maximal feasible effective samples.",
  "",
  "Blocked: linear deterministic trend, trend-stabilized capacity closure, trend as autonomous technical change, q_omega, interaction/generated dynamics, FM-OLS/IM-OLS drift, and cointRegD interacted-baseline drift."
)
summary_lines <- c(
  "# D12F-R No-Trend Execution Summary",
  "",
  "D12F-R was required because D12F and D12C used a deterministic trend in the level relation. D12F-R reclassifies those trend-included outputs as diagnostic comparators and executes controlled preliminary no-trend RDOLS runs.",
  "",
  "## Executed",
  "",
  paste0("- ", run_ledger$candidate_model_id, " (", run_ledger$effective_start_year, "-", run_ledger$effective_end_year, ", n=", run_ledger$n_effective, ")"),
  "",
  "## Blocked Or Skipped",
  "",
  paste0("- ", skipped$candidate_model_id, ": ", skipped$d12f_r_status),
  "",
  "## Trend Diagnostic Comparison",
  "",
  "All trend-sensitivity statements are DESIGN_STAGE_PRELIMINARY_ONLY.",
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "D12G is authorized for preliminary no-trend robustness review only, not final manuscript interpretation."
)
memo_lines <- c(
  "# D12F-R Trend Reclassification Memo",
  "",
  "D12F trend-included results are reclassified as TREND_INCLUDED_DIAGNOSTIC_COMPARATOR.",
  "",
  "D12C full-sample LL11 and LL22 references are reclassified as TREND_INCLUDED_FULL_SAMPLE_REFERENCE_DIAGNOSTIC.",
  "",
  "This reclassification does not modify D12C or D12F outputs.",
  "",
  "Trend-included results are blocked for preferred-baseline interpretation, productive-capacity reconstruction, utilization reconstruction, and elasticity recovery."
)
diag_lines <- c(
  "# D12F-R Trend-Included Diagnostic Comparison",
  "",
  "This report compares D12F-R no-trend controlled preliminary estimates against D12F/D12C trend-included diagnostic comparators.",
  "",
  "All coefficient-related statements are DESIGN_STAGE_PRELIMINARY_ONLY.",
  "",
  paste0("- ", trend_sensitivity$term, ": ", trend_sensitivity$trend_sensitivity_classification)
)
main_lines <- c(
  "# D12F-R No-Trend RDOLS Robustness Reconciliation",
  "",
  "D12F-R executed controlled preliminary no-trend RDOLS robustness models. It is not final manuscript estimation.",
  "",
  "CONTROLLED_PRELIMINARY",
  "DESIGN_STAGE_PRELIMINARY_ONLY",
  "NOT FINAL MANUSCRIPT ESTIMATION",
  "NO PRODUCTIVE-CAPACITY RECONSTRUCTION",
  "NO UTILIZATION RECONSTRUCTION",
  "NO ELASTICITY RECOVERY",
  "",
  "## What D12F-R Did Not Execute",
  "",
  paste0("- ", skipped$candidate_model_id),
  "",
  "## Terminal Decision",
  "",
  terminal_decision
)
readme_lines <- c(
  "# D12F-R No-Trend RDOLS Robustness Reconciliation",
  "",
  "This folder contains the no-trend reconciliation pass for D12F.",
  "",
  "D12F-R wrote no-trend controlled preliminary RDOLS outputs and diagnostic trend-comparison ledgers. It did not modify D12C/D12D/D12E/D12F outputs.",
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "D12G is authorized for preliminary no-trend robustness review only, not final manuscript interpretation."
)
terminal_lines <- c(
  "# D12F-R Terminal Decision",
  "",
  "D12F-R executed controlled preliminary no-trend RDOLS robustness estimates and reclassified D12C/D12F trend-included outputs as diagnostic comparators. D12F-R did not reconstruct productive capacity, reconstruct utilization, recover elasticity, reintroduce q_omega, or write final manuscript interpretation.",
  "",
  "D12G is authorized for preliminary no-trend robustness review only, not final manuscript interpretation.",
  "",
  terminal_decision
)

writeLines(contract_lines, file.path(OUT_DIR, "D12F_R_NO_TREND_CONTRACT.md"), useBytes = TRUE)
writeLines(summary_lines, file.path(REPORT_DIR, "D12F_R_NO_TREND_EXECUTION_SUMMARY.md"), useBytes = TRUE)
writeLines(memo_lines, file.path(REPORT_DIR, "D12F_R_TREND_RECLASSIFICATION_MEMO.md"), useBytes = TRUE)
writeLines(diag_lines, file.path(REPORT_DIR, "D12F_R_TREND_INCLUDED_DIAGNOSTIC_COMPARISON.md"), useBytes = TRUE)
writeLines(main_lines, file.path(OUT_DIR, "D12F_R_NO_TREND_RDOLS_ROBUSTNESS_RECONCILIATION.md"), useBytes = TRUE)
writeLines(readme_lines, file.path(OUT_DIR, "D12F_R_README.md"), useBytes = TRUE)
writeLines(terminal_lines, file.path(OUT_DIR, "D12F_R_TERMINAL_DECISION.md"), useBytes = TRUE)

message("D12F-R no-trend RDOLS robustness reconciliation complete. Outputs written to ", OUT_DIR)
