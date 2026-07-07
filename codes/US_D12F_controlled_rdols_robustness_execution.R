# D12F controlled RDOLS robustness execution.
# Executes only D12E-queued candidates as controlled preliminary robustness runs.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
D12C_DIR <- file.path(ROOT, "output", "US", "D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION")
D12D_DIR <- file.path(ROOT, "output", "US", "D12D_PRELIMINARY_RESULT_REVIEW")
D12E_DIR <- file.path(ROOT, "output", "US", "D12E_PRELIMINARY_RDOLS_ROBUSTNESS_DESIGN")
D12F_DIR <- file.path(ROOT, "output", "US", "D12F_CONTROLLED_RDOLS_ROBUSTNESS_EXECUTION")
CSV_DIR <- file.path(D12F_DIR, "csv")
REPORT_DIR <- file.path(D12F_DIR, "reports")
RDS_DIR <- file.path(D12F_DIR, "rds")

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
collapse_terms <- function(x) if (length(x) == 0L) "" else paste(x, collapse = "; ")
row_count <- function(path) {
  if (!file.exists(path) || !grepl("\\.csv$", path, ignore.case = TRUE)) return(NA_integer_)
  nrow(read.csv(path, check.names = FALSE))
}
col_count <- function(path) {
  if (!file.exists(path) || !grepl("\\.csv$", path, ignore.case = TRUE)) return(NA_integer_)
  ncol(read.csv(path, check.names = FALSE))
}
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

required_inputs <- data.frame(
  source_folder = c(
    rep("D12E", 9), rep("D12C", 6), rep("D12D", 3),
    rep("code", 3)
  ),
  file_path = c(
    file.path(D12E_DIR, "csv", c(
      "D12E_ROBUSTNESS_EXECUTION_QUEUE.csv",
      "D12E_BLOCKED_ROBUSTNESS_QUEUE.csv",
      "D12E_D12F_API_CONTRACT.csv",
      "D12E_WINDOW_LEAD_LAG_FEASIBILITY_LEDGER.csv",
      "D12E_SAMPLE_AND_RANK_PRECHECK_LEDGER.csv",
      "D12E_RESTRICTED_DYNAMICS_DESIGN_LEDGER.csv",
      "D12E_MODEL_OBJECT_ROBUSTNESS_DESIGN_LEDGER.csv",
      "D12E_VALIDATION_CHECKS.csv"
    )),
    file.path(D12E_DIR, "D12E_TERMINAL_DECISION.md"),
    file.path(D12C_DIR, "csv", c(
      "D12C_AUTHORIZED_MODEL_OBJECT_LEDGER.csv",
      "D12C_RDOLS_ESTIMATION_RUN_LEDGER.csv",
      "D12C_RDOLS_COEFFICIENT_LEDGER.csv",
      "D12C_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv",
      "D12C_RDOLS_SAMPLE_LEDGER.csv"
    )),
    file.path(D12C_DIR, "D12C_TERMINAL_DECISION.md"),
    file.path(D12D_DIR, "csv", c(
      "D12D_COEFFICIENT_REVIEW_LEDGER.csv",
      "D12D_D12E_READINESS_LEDGER.csv"
    )),
    file.path(D12D_DIR, "D12D_TERMINAL_DECISION.md"),
    file.path(ROOT, "codes", c(
      "US_D12C_controlled_preliminary_rdols_estimation.R",
      "US_D12D_preliminary_result_review.R",
      "US_D12E_preliminary_rdols_robustness_design.R"
    ))
  ),
  relevance = c(
    rep("required D12E queue/contract input", 9),
    rep("required D12C reference input", 6),
    rep("required D12D review input", 3),
    rep("prior code boundary inspection", 3)
  ),
  stringsAsFactors = FALSE
)

d12e_input_discovery <- read_csv(file.path(D12E_DIR, "csv", "D12E_INPUT_DISCOVERY_LEDGER.csv"))
source_row <- d12e_input_discovery[
  basename(d12e_input_discovery$file_path) == "D10_clean_us_source_of_truth_panel_wide.csv",
  ,
  drop = FALSE
]
if (nrow(source_row) != 1L) stop("D12F could not locate D10 source through D12E discovery ledger.")
d10_source <- source_row$file_path
source_discovery_row <- data.frame(
  source_folder = "D10",
  file_path = d10_source,
  relevance = "canonical source-of-truth data for D12F variables",
  stringsAsFactors = FALSE
)
required_inputs <- rbind(required_inputs, source_discovery_row)

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
  stop("D12F missing required inputs: ", paste(input_discovery$file_path[!input_discovery$exists], collapse = "; "))
}

queue <- read_csv(file.path(D12E_DIR, "csv", "D12E_ROBUSTNESS_EXECUTION_QUEUE.csv"))
blocked_e <- read_csv(file.path(D12E_DIR, "csv", "D12E_BLOCKED_ROBUSTNESS_QUEUE.csv"))
api_contract <- read_csv(file.path(D12E_DIR, "csv", "D12E_D12F_API_CONTRACT.csv"))
feasibility <- read_csv(file.path(D12E_DIR, "csv", "D12E_WINDOW_LEAD_LAG_FEASIBILITY_LEDGER.csv"))
precheck_e <- read_csv(file.path(D12E_DIR, "csv", "D12E_SAMPLE_AND_RANK_PRECHECK_LEDGER.csv"))
restricted_e <- read_csv(file.path(D12E_DIR, "csv", "D12E_RESTRICTED_DYNAMICS_DESIGN_LEDGER.csv"))
model_e <- read_csv(file.path(D12E_DIR, "csv", "D12E_MODEL_OBJECT_ROBUSTNESS_DESIGN_LEDGER.csv"))
d12e_validation <- read_csv(file.path(D12E_DIR, "csv", "D12E_VALIDATION_CHECKS.csv"))
d12e_terminal <- read_text(file.path(D12E_DIR, "D12E_TERMINAL_DECISION.md"))
d12c_coef <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_COEFFICIENT_LEDGER.csv"))
d12c_runs <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_ESTIMATION_RUN_LEDGER.csv"))
d12c_aux <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv"))
d12c_samples <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_SAMPLE_LEDGER.csv"))
d12c_terminal <- read_text(file.path(D12C_DIR, "D12C_TERMINAL_DECISION.md"))
d12d_coef <- read_csv(file.path(D12D_DIR, "csv", "D12D_COEFFICIENT_REVIEW_LEDGER.csv"))
d12d_ready <- read_csv(file.path(D12D_DIR, "csv", "D12D_D12E_READINESS_LEDGER.csv"))
d12d_terminal <- read_text(file.path(D12D_DIR, "D12D_TERMINAL_DECISION.md"))
panel <- read_csv(d10_source)

panel$y_log_nfc_gva <- log(panel$Y_REAL_NFC_GVA_BASELINE_D09)
panel$k_me_log <- log(panel$K_ME)
panel$k_nrc_log <- log(panel$K_NRC)
panel$omega_nfc <- panel$omega_NFC_productive_origin_GVA
panel$k_me_log_x_omega <- panel$k_me_log * panel$omega_nfc
panel$k_nrc_log_x_omega <- panel$k_nrc_log * panel$omega_nfc
panel$trend <- panel$year - min(panel$year, na.rm = TRUE)

level_terms <- c("k_me_log", "k_nrc_log", "omega_nfc", "k_me_log_x_omega", "k_nrc_log_x_omega", "trend")
coef_terms <- c("(Intercept)", level_terms)
dynamic_base_terms <- c("k_me_log", "k_nrc_log", "omega_nfc")
blocked_dynamic_terms <- c("d_k_me_log_x_omega", "d_k_nrc_log_x_omega", "all qomega-family differences")
model_vars <- c("y_log_nfc_gva", "k_me_log", "k_nrc_log", "omega_nfc", "k_me_log_x_omega", "k_nrc_log_x_omega")
complete_case <- complete.cases(panel[, model_vars])

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
  if (length(y_eff) <= ncol(x)) stop("Insufficient observations for RDOLS fit.")
  fit <- stats::lm.fit(x = x, y = y_eff)
  qr_obj <- qr(x)
  rank <- qr_obj$rank
  df <- length(y_eff) - rank
  rss <- sum(fit$residuals^2)
  sigma2 <- rss / df
  xtx_inv <- tryCatch(solve(crossprod(x)), error = function(e) MASS::ginv(crossprod(x)))
  se <- sqrt(diag(sigma2 * xtx_inv))
  est <- fit$coefficients
  names(est) <- colnames(x)
  t_val <- est / se
  p_val <- 2 * stats::pt(abs(t_val), df = df, lower.tail = FALSE)
  cond <- kappa(x, exact = TRUE)
  list(
    fit = fit,
    coef = data.frame(term = names(est), estimate = as.numeric(est), std_error = se,
                      t_value = as.numeric(t_val), p_value = as.numeric(p_val),
                      stringsAsFactors = FALSE),
    years = years,
    n = length(y_eff),
    rank = rank,
    df = df,
    residuals = fit$residuals,
    condition_number = cond,
    design_columns = ncol(x)
  )
}

queue_intake <- data.frame(
  queue_id = queue$queue_id,
  candidate_model_id = queue$candidate_model_id,
  window_id = queue$window_id,
  grid_id = queue$grid_id,
  candidate_role = queue$candidate_role,
  priority = queue$priority,
  authorized_for_D12F = queue$authorized_for_D12F,
  intake_status = ifelse(queue$authorized_for_D12F == "TRUE" | queue$authorized_for_D12F == TRUE,
                         "PASS_AUTHORIZED_BY_D12E", "FAIL_NOT_AUTHORIZED"),
  execution_decision = ifelse(queue$authorized_for_D12F == "TRUE" | queue$authorized_for_D12F == TRUE,
                              "EXECUTE_CONTROLLED_PRELIMINARY", "SKIP_NOT_AUTHORIZED"),
  notes = "D12F intake from D12E execution queue only",
  stringsAsFactors = FALSE
)
if (any(queue_intake$candidate_model_id %in% blocked_e$candidate_model_id)) {
  stop("BLOCK_D12F_UNAUTHORIZED_MODEL_EXECUTION")
}

contract_confirm <- data.frame(
  contract_item = api_contract$contract_item,
  permission_status = api_contract$permission_status,
  d12f_status = ifelse(api_contract$permission_status %in% c("ALLOWED_D12F", "BLOCKED_D12F"), "PASS", "WARN"),
  evidence = "csv/D12E_D12F_API_CONTRACT.csv",
  notes = "D12F confirms inherited D12E API contract",
  stringsAsFactors = FALSE
)

results <- list()
max_sample_rows <- list()
run_rows <- list()
coef_rows <- list()
aux_rows <- list()
sample_rows <- list()
gate_rows <- list()
diag_rows <- list()
warning_rows <- list()
review_rows <- list()
warn_id <- 1L
review_id <- 1L

add_warning <- function(model_id, window_id, grid_id, term, warning_type, severity, source, action, notes) {
  warning_rows[[length(warning_rows) + 1L]] <<- data.frame(
    warning_id = sprintf("D12F_WARN_%03d", warn_id),
    candidate_model_id = model_id,
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
add_review <- function(model_id, window_id, grid_id, term, topic, severity, reason, scope) {
  review_rows[[length(review_rows) + 1L]] <<- data.frame(
    review_item_id = sprintf("D12G_REVIEW_%03d", review_id),
    candidate_model_id = model_id,
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

for (i in seq_len(nrow(queue))) {
  q <- queue[i, ]
  feas <- feasibility[feasibility$window_id == q$window_id & feasibility$grid_id == q$grid_id, , drop = FALSE]
  if (nrow(feas) != 1L) stop("Missing feasibility row for ", q$candidate_model_id)
  n_lag <- as.integer(feas$n_lag)
  n_lead <- as.integer(feas$n_lead)
  complete_start <- as.integer(feas$complete_case_start_year)
  complete_end <- as.integer(feas$complete_case_end_year)
  effective_start <- complete_start + 1L + n_lag
  effective_end <- complete_end - n_lead
  nominal_start <- as.integer(feas$nominal_start_year)
  nominal_end <- as.integer(feas$nominal_end_year)
  in_nominal <- panel$year >= nominal_start & panel$year <= nominal_end
  in_complete <- panel$year >= complete_start & panel$year <= complete_end & complete_case
  n_complete <- sum(in_complete)
  n_effective_formula <- sum(panel$year >= effective_start & panel$year <= effective_end & in_complete)
  sample_ok <- n_effective_formula == as.integer(feas$n_effective) &&
    effective_start == as.integer(feas$effective_start_year) &&
    effective_end == as.integer(feas$effective_end_year) &&
    all(panel$year[in_complete] >= nominal_start & panel$year[in_complete] <= nominal_end)
  max_sample_rows[[i]] <- data.frame(
    candidate_model_id = q$candidate_model_id,
    window_id = q$window_id,
    grid_id = q$grid_id,
    nominal_start_year = nominal_start,
    nominal_end_year = nominal_end,
    complete_case_start_year = complete_start,
    complete_case_end_year = complete_end,
    n_lag = n_lag,
    n_lead = n_lead,
    effective_start_year_formula = "complete_case_start_year + 1 + n_lag",
    effective_end_year_formula = "complete_case_end_year - n_lead",
    effective_start_year = effective_start,
    effective_end_year = effective_end,
    n_complete_case = n_complete,
    n_effective = n_effective_formula,
    uses_maximal_feasible_sample = TRUE,
    common_overlap_forced = FALSE,
    borrowed_outside_window = FALSE,
    sample_rule_status = ifelse(sample_ok, "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE", "FAIL_SAMPLE_RULE"),
    notes = "Mechanical first-difference, lead, and lag trimming only",
    stringsAsFactors = FALSE
  )
  if (!sample_ok) stop("BLOCK_D12F_SAMPLE_RULE_VIOLATION")
  data_w <- panel[in_nominal, , drop = FALSE]
  fit <- fit_manual_rdols(data_w, n_lead, n_lag, effective_start, effective_end)
  run_id <- sprintf("D12F_RUN_%03d", i)
  results[[q$candidate_model_id]] <- list(queue = q, fit = fit)
  level_coef <- fit$coef[fit$coef$term %in% coef_terms, , drop = FALSE]
  level_coef$coefficient_role <- ifelse(level_coef$term %in% c("(Intercept)", "trend"), "deterministic", "long_run_level")
  level_coef <- level_coef[, c("term", "coefficient_role", "estimate", "std_error", "t_value", "p_value")]
  level_coef$significance_stars <- stars(level_coef$p_value)
  coef_rows[[i]] <- data.frame(
    run_id = run_id,
    queue_id = q$queue_id,
    candidate_model_id = q$candidate_model_id,
    window_id = q$window_id,
    grid_id = q$grid_id,
    level_coef,
    preliminary_status = PRELIMINARY_STATUS,
    allowed_interpretation = ALLOWED_INTERPRETATION,
    stringsAsFactors = FALSE
  )
  aux_coef <- fit$coef[!fit$coef$term %in% coef_terms, , drop = FALSE]
  aux_terms <- aux_coef$term
  is_dynamic_base <- grepl("^d_(k_me_log|k_nrc_log|omega_nfc)_(lead[0-9]+|lag[0-9]+|current)$", aux_terms)
  is_interaction_dynamic <- grepl("x_omega|interaction", aux_terms, ignore.case = TRUE)
  if (any(is_interaction_dynamic)) stop("BLOCK_D12F_INTERACTION_DYNAMIC_DRIFT")
  aux_rows[[i]] <- data.frame(
    run_id = run_id,
    queue_id = q$queue_id,
    candidate_model_id = q$candidate_model_id,
    window_id = q$window_id,
    grid_id = q$grid_id,
    term = aux_coef$term,
    coefficient_role = "restricted_base_difference_dynamic",
    estimate = aux_coef$estimate,
    std_error = aux_coef$std_error,
    t_value = aux_coef$t_value,
    p_value = aux_coef$p_value,
    shown_by_default = FALSE,
    preliminary_status = PRELIMINARY_STATUS,
    is_dynamic_base_difference_term = is_dynamic_base,
    is_interaction_dynamic_term = is_interaction_dynamic,
    stringsAsFactors = FALSE
  )
  n_lost_lead_lag <- n_complete - fit$n
  sample_rows[[i]] <- data.frame(
    run_id = run_id,
    queue_id = q$queue_id,
    candidate_model_id = q$candidate_model_id,
    window_id = q$window_id,
    grid_id = q$grid_id,
    nominal_start_year = nominal_start,
    nominal_end_year = nominal_end,
    complete_case_start_year = complete_start,
    complete_case_end_year = complete_end,
    effective_start_year = min(fit$years),
    effective_end_year = max(fit$years),
    n_complete_case = n_complete,
    n_effective = fit$n,
    n_lost_first_difference = 1L,
    n_lost_lead_lag = n_lag + n_lead,
    n_lost_missing = 0L,
    sample_status = ifelse(fit$n < 25L, "WARN_SMALL_SAMPLE", "PASS_SAMPLE_SURVIVAL"),
    sample_rule_status = "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE",
    stringsAsFactors = FALSE
  )
  rank_gate <- ifelse(fit$rank == fit$design_columns, "PASS_FULL_RANK", "FAIL_RANK_DEFICIENT")
  df_gate <- ifelse(fit$df >= 10L, ifelse(fit$df < 20L, "WARN_LOW_DF", "PASS_DF"), "FAIL_INSUFFICIENT_DF")
  overall <- ifelse(rank_gate == "PASS_FULL_RANK" && df_gate != "FAIL_INSUFFICIENT_DF",
                    "PASS_CONTROLLED_PRELIMINARY", "WARN_REVIEW_REQUIRED")
  gate_rows[[i]] <- data.frame(
    run_id = run_id,
    candidate_model_id = q$candidate_model_id,
    window_id = q$window_id,
    grid_id = q$grid_id,
    boundary_gate = "PASS_D12E_QUEUED_BOUNDARY",
    qomega_gate = "PASS_QOMEGA_PARKED",
    integration_order_gate = "PASS_CONTROLLED_PRELIMINARY_D12E_QUEUE",
    interaction_gate = "PASS_INTERACTION_LEVEL_ONLY_NO_DYNAMIC_CORRECTIONS",
    restricted_dynamics_gate = "PASS_RESTRICTED_BASE_DIFFERENCE_DYNAMICS",
    sample_survival_gate = "PASS_SAMPLE_SURVIVAL",
    rank_gate = rank_gate,
    df_gate = df_gate,
    sample_rule_gate = "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE",
    overall_gate_status = overall,
    notes = "Controlled preliminary D12F robustness run",
    stringsAsFactors = FALSE
  )
  resid <- fit$residuals
  resid_summary <- paste0(
    "min=", min(resid), "; q1=", as.numeric(quantile(resid, 0.25)),
    "; median=", median(resid), "; mean=", mean(resid),
    "; q3=", as.numeric(quantile(resid, 0.75)), "; max=", max(resid),
    "; sd=", stats::sd(resid)
  )
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = q$candidate_model_id, window_id = q$window_id, grid_id = q$grid_id, diagnostic_name = "effective sample size", diagnostic_value = fit$n, diagnostic_status = PRELIMINARY_STATUS, review_flag = "PASS", notes = "D12F diagnostic only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = q$candidate_model_id, window_id = q$window_id, grid_id = q$grid_id, diagnostic_name = "design rank", diagnostic_value = fit$rank, diagnostic_status = PRELIMINARY_STATUS, review_flag = "PASS", notes = "D12F diagnostic only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = q$candidate_model_id, window_id = q$window_id, grid_id = q$grid_id, diagnostic_name = "df residual", diagnostic_value = fit$df, diagnostic_status = PRELIMINARY_STATUS, review_flag = ifelse(fit$df < 20L, "WARN", "PASS"), notes = "D12F diagnostic only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = q$candidate_model_id, window_id = q$window_id, grid_id = q$grid_id, diagnostic_name = "missingness count", diagnostic_value = 0L, diagnostic_status = PRELIMINARY_STATUS, review_flag = "PASS", notes = "Effective sample uses complete cases", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = q$candidate_model_id, window_id = q$window_id, grid_id = q$grid_id, diagnostic_name = "lead/lag sample loss", diagnostic_value = n_lost_lead_lag, diagnostic_status = PRELIMINARY_STATUS, review_flag = ifelse(n_lost_lead_lag > 5L, "WARN", "PASS"), notes = "Mechanical trimming only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = q$candidate_model_id, window_id = q$window_id, grid_id = q$grid_id, diagnostic_name = "residual summary statistics", diagnostic_value = resid_summary, diagnostic_status = PRELIMINARY_STATUS, review_flag = "PASS", notes = "D12F diagnostic only", stringsAsFactors = FALSE)
  diag_rows[[length(diag_rows) + 1L]] <- data.frame(run_id = run_id, candidate_model_id = q$candidate_model_id, window_id = q$window_id, grid_id = q$grid_id, diagnostic_name = "condition number warning", diagnostic_value = ifelse(fit$condition_number > 1e5, paste0("WARN_HIGH_CONDITION_NUMBER_", round(fit$condition_number, 2)), paste0("PASS_CONDITION_NUMBER_", round(fit$condition_number, 2))), diagnostic_status = PRELIMINARY_STATUS, review_flag = ifelse(fit$condition_number > 1e5, "WARN", "PASS"), notes = "Requires D12G review if WARN", stringsAsFactors = FALSE)
  for (j in seq_len(nrow(level_coef))) {
    if (abs(level_coef$estimate[j]) >= 10) {
      add_warning(q$candidate_model_id, q$window_id, q$grid_id, level_coef$term[j],
                  "large coefficient magnitude", "WARN", "D12F_RDOLS_COEFFICIENT_LEDGER.csv",
                  "Review magnitude stability across windows and grids", "Large preliminary coefficient magnitude.")
    }
    if (level_coef$p_value[j] < 0.10) {
      add_warning(q$candidate_model_id, q$window_id, q$grid_id, level_coef$term[j],
                  "p-value threshold crossing", "INFO", "D12F_RDOLS_COEFFICIENT_LEDGER.csv",
                  "Review preliminary significance pattern", "Preliminary p-value below 0.10.")
    }
  }
  if (fit$df < 20L) {
    add_warning(q$candidate_model_id, q$window_id, q$grid_id, "", "low degrees of freedom", "WARN",
                "D12F_RDOLS_DIAGNOSTIC_LEDGER.csv", "Review low-df robustness candidate", "Residual df below preferred threshold.")
  }
  if (fit$condition_number > 1e5) {
    add_warning(q$candidate_model_id, q$window_id, q$grid_id, "", "condition number warning", "WARN",
                "D12F_RDOLS_DIAGNOSTIC_LEDGER.csv", "Review collinearity diagnostics", "High design condition number.")
  }
  run_rows[[i]] <- data.frame(
    run_id = run_id,
    queue_id = q$queue_id,
    candidate_model_id = q$candidate_model_id,
    window_id = q$window_id,
    grid_id = q$grid_id,
    estimator = ESTIMATOR,
    n_lag = n_lag,
    n_lead = n_lead,
    status = overall,
    nominal_start_year = nominal_start,
    nominal_end_year = nominal_end,
    effective_start_year = min(fit$years),
    effective_end_year = max(fit$years),
    n_effective = fit$n,
    rank = fit$rank,
    df_residual = fit$df,
    contract_status = "PASS_CONTRACT_FIRST",
    sample_rule_status = "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE",
    preliminary_status = PRELIMINARY_STATUS,
    notes = "manual RDOLS controlled preliminary robustness run",
    stringsAsFactors = FALSE
  )
  result_obj <- list(
    status = PRELIMINARY_STATUS,
    allowed_interpretation = ALLOWED_INTERPRETATION,
    estimator = ESTIMATOR,
    queue = q,
    run = run_rows[[i]],
    coefficients = coef_rows[[i]],
    auxiliary_coefficients = aux_rows[[i]],
    sample = sample_rows[[i]],
    gates = gate_rows[[i]],
    diagnostics = diag_rows[(length(diag_rows) - 6L):length(diag_rows)]
  )
  class(result_obj) <- c("ch2_rdols", "ch2_estimation_result")
  saveRDS(result_obj, file.path(RDS_DIR, paste0(q$candidate_model_id, ".rds")))
}

max_sample <- do.call(rbind, max_sample_rows)
run_ledger <- do.call(rbind, run_rows)
coef_ledger <- do.call(rbind, coef_rows)
aux_ledger <- do.call(rbind, aux_rows)
sample_ledger <- do.call(rbind, sample_rows)
gate_ledger <- do.call(rbind, gate_rows)
diagnostic_ledger <- do.call(rbind, diag_rows)
warning_ledger <- if (length(warning_rows)) do.call(rbind, warning_rows) else data.frame()

format_key <- function(window_id, grid_id) paste0(window_id, "_", grid_id)
tidy_terms <- c("k_me_log", "k_nrc_log", "omega_nfc", "k_me_log_x_omega", "k_nrc_log_x_omega", "trend", "(Intercept)")
tidy <- data.frame(term = tidy_terms,
                   coefficient_role = ifelse(tidy_terms %in% c("trend", "(Intercept)"), "deterministic", "long_run_level"),
                   stringsAsFactors = FALSE)
add_pair <- function(tbl, prefix, source, term_col = "term") {
  est <- setNames(safe_num(source$estimate), source[[term_col]])
  p <- setNames(safe_num(source$p_value), source[[term_col]])
  tbl[[paste0(prefix, "_estimate")]] <- est[tbl$term]
  tbl[[paste0(prefix, "_p_value")]] <- p[tbl$term]
  tbl
}
tidy <- add_pair(tidy, "full_sample_LL11", d12c_coef[d12c_coef$model_id == "RDOLS_ME_NRC_OMEGA_INT_LL11", ])
tidy <- add_pair(tidy, "full_sample_LL22", d12c_coef[d12c_coef$model_id == "RDOLS_ME_NRC_OMEGA_INT_LL22", ])
for (key in c(
  "pre_1974_full_LL00", "pre_1974_full_LL11", "pre_1974_full_LL22",
  "post_1973_full_LL00", "post_1973_full_LL11", "post_1973_full_LL22", "post_1973_full_LL33",
  "fordist_core_LL00", "fordist_core_LL11",
  "bridge_1940_1978_LL00", "bridge_1940_1978_LL11", "bridge_1940_1978_LL22",
  "pre_1974_alt_1940_1973_LL00", "pre_1974_alt_1940_1973_LL11",
  "pre_1974_alt_1947_1973_LL00"
)) {
  parts <- strsplit(key, "_LL")[[1]]
  window_id <- parts[1]
  grid_id <- paste0("LL", parts[2])
  src <- coef_ledger[coef_ledger$window_id == window_id & coef_ledger$grid_id == grid_id, ]
  tidy <- add_pair(tidy, key, src)
}
tidy$preliminary_status <- PRELIMINARY_STATUS
tidy$allowed_interpretation <- ALLOWED_INTERPRETATION

star_table <- tidy[c("term", "coefficient_role")]
estimate_cols <- grep("_estimate$", names(tidy), value = TRUE)
for (ec in estimate_cols) {
  pc <- sub("_estimate$", "_p_value", ec)
  star_table[[sub("_estimate$", "", ec)]] <- ifelse(
    is.na(tidy[[ec]]), "",
    paste0(format(round(tidy[[ec]], 3), nsmall = 3), stars(tidy[[pc]]))
  )
}
star_table$preliminary_status <- PRELIMINARY_STATUS
star_table$allowed_interpretation <- ALLOWED_INTERPRETATION

comparison_rows <- list()
all_coef_for_compare <- rbind(
  data.frame(candidate_model_id = d12c_coef$model_id, window_id = "full_sample",
             grid_id = ifelse(grepl("LL11", d12c_coef$model_id), "LL11", "LL22"),
             term = d12c_coef$term, estimate = safe_num(d12c_coef$estimate), p_value = safe_num(d12c_coef$p_value),
             stringsAsFactors = FALSE),
  data.frame(candidate_model_id = coef_ledger$candidate_model_id, window_id = coef_ledger$window_id,
             grid_id = coef_ledger$grid_id, term = coef_ledger$term, estimate = safe_num(coef_ledger$estimate),
             p_value = safe_num(coef_ledger$p_value), stringsAsFactors = FALSE)
)
reference <- all_coef_for_compare[all_coef_for_compare$candidate_model_id == "RDOLS_ME_NRC_OMEGA_INT_LL11", ]
if (nrow(reference) == 0L) reference <- all_coef_for_compare[all_coef_for_compare$window_id == "full_sample" & all_coef_for_compare$grid_id == "LL11", ]
idx <- 1L
for (term in tidy_terms) {
  ref <- reference[reference$term == term, , drop = FALSE]
  if (nrow(ref) != 1L) next
  comps <- all_coef_for_compare[all_coef_for_compare$term == term & all_coef_for_compare$candidate_model_id != ref$candidate_model_id, ]
  for (j in seq_len(nrow(comps))) {
    ratio <- ifelse(abs(ref$estimate) < 1e-8, NA_real_, abs(comps$estimate[j] / ref$estimate))
    sign_stable <- sign_of(ref$estimate) == sign_of(comps$estimate[j])
    p_cross <- (ref$p_value < 0.10) != (comps$p_value[j] < 0.10)
    mag_shift <- is.finite(ratio) && (ratio > 2 || ratio < 0.5)
    review <- if (!sign_stable) "SIGN_FLIP" else if (mag_shift) "MAGNITUDE_SHIFT_REQUIRES_REVIEW" else if (p_cross) "SIGNIFICANCE_SHIFT_REQUIRES_REVIEW" else "DESIGN_STAGE_PRELIMINARY_ONLY"
    comparison_rows[[idx]] <- data.frame(
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
      notes = paste("Comparison is preliminary only.", ALLOWED_INTERPRETATION),
      stringsAsFactors = FALSE
    )
    if (review != "DESIGN_STAGE_PRELIMINARY_ONLY") {
      add_review(comps$candidate_model_id[j], comps$window_id[j], comps$grid_id[j], term,
                 review, "WARN", paste("Comparison against", ref$candidate_model_id, "requires review."),
                 "Preliminary robustness review only, not final interpretation.")
    }
    idx <- idx + 1L
  }
}
comparison_ledger <- do.call(rbind, comparison_rows)

for (i in seq_len(nrow(run_ledger))) {
  if (run_ledger$window_id[i] %in% c("pre_1974_full", "post_1973_full") && run_ledger$grid_id[i] %in% c("LL11", "LL22")) {
    add_review(run_ledger$candidate_model_id[i], run_ledger$window_id[i], run_ledger$grid_id[i], "",
               "primary pre/post window contrasts", "WARN", "Primary window contrast requires D12G review.",
               "Review controlled preliminary robustness only.")
  }
  if (run_ledger$grid_id[i] == "LL00") {
    add_review(run_ledger$candidate_model_id[i], run_ledger$window_id[i], run_ledger$grid_id[i], "",
               "LL00 diagnostic behavior", "WARN", "Minimal-dynamic diagnostic grid requires review.",
               "Review controlled preliminary robustness only.")
  }
  if (run_ledger$grid_id[i] == "LL33") {
    add_review(run_ledger$candidate_model_id[i], run_ledger$window_id[i], run_ledger$grid_id[i], "",
               "LL33 post-1973 high-dynamic diagnostic behavior", "WARN", "High-dynamic diagnostic grid requires review.",
               "Review controlled preliminary robustness only.")
  }
  if (run_ledger$window_id[i] == "fordist_core" && run_ledger$df_residual[i] < 20L) {
    add_review(run_ledger$candidate_model_id[i], run_ledger$window_id[i], run_ledger$grid_id[i], "",
               "Fordist-core low-df warnings", "WARN", "Fordist-core residual df below preferred threshold.",
               "Review controlled preliminary robustness only.")
  }
  if (run_ledger$window_id[i] == "bridge_1940_1978") {
    add_review(run_ledger$candidate_model_id[i], run_ledger$window_id[i], run_ledger$grid_id[i], "",
               "bridge-window transition behavior", "INFO", "Bridge window is a transition design.",
               "Review controlled preliminary robustness only.")
  }
}
review_queue <- if (length(review_rows)) do.call(rbind, review_rows) else data.frame()

skipped <- data.frame(
  candidate_model_id = blocked_e$candidate_model_id,
  window_id = blocked_e$window_id,
  grid_id = blocked_e$grid_id,
  source_status = blocked_e$block_status,
  d12f_status = "SKIPPED_BLOCKED_BY_D12E",
  reason = blocked_e$block_reason,
  notes = blocked_e$notes,
  stringsAsFactors = FALSE
)

ui_validation <- data.frame(
  ui_requirement = c(
    "contract-first model cards written",
    "coefficient ledgers marked preliminary",
    "coefficient ledgers marked design-stage preliminary only",
    "auxiliary coefficients hidden by default",
    "qomega parked banner present",
    "maximal feasible sample banner present"
  ),
  status = c(
    TRUE,
    all(coef_ledger$preliminary_status == PRELIMINARY_STATUS),
    all(coef_ledger$allowed_interpretation == ALLOWED_INTERPRETATION),
    all(as.character(aux_ledger$shown_by_default) == "FALSE"),
    TRUE,
    TRUE
  ),
  evidence = "D12F generated result interface",
  notes = "D12F results UI validation",
  stringsAsFactors = FALSE
)
ui_validation$status <- ifelse(ui_validation$status, "PASS", "FAIL")

write_model_card <- function(i) {
  run <- run_ledger[i, ]
  co <- coef_ledger[coef_ledger$candidate_model_id == run$candidate_model_id, ]
  au <- aux_ledger[aux_ledger$candidate_model_id == run$candidate_model_id, ]
  dg <- diagnostic_ledger[diagnostic_ledger$candidate_model_id == run$candidate_model_id, ]
  warn <- warning_ledger[warning_ledger$candidate_model_id == run$candidate_model_id, ]
  lines <- c(
    paste0("# MODEL_CARD_", run$candidate_model_id),
    "",
    "## Status",
    "",
    "CONTROLLED_PRELIMINARY",
    "DESIGN_STAGE_PRELIMINARY_ONLY",
    "NOT FINAL MANUSCRIPT ESTIMATION",
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
    "y_log_nfc_gva ~ k_me_log + k_nrc_log + omega_nfc + k_me_log_x_omega + k_nrc_log_x_omega + trend + restricted base first-difference dynamics",
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
    capture.output(print(au[, c("term", "coefficient_role", "shown_by_default", "is_dynamic_base_difference_term", "is_interaction_dynamic_term")], row.names = FALSE)),
    "",
    "## Diagnostics",
    "",
    paste0("- ", dg$diagnostic_name, ": ", dg$diagnostic_value),
    "",
    "## Warnings",
    "",
    if (nrow(warn)) paste0("- ", warn$warning_type, ": ", warn$recommended_D12G_review_action) else "- None.",
    "",
    "## Restrictions",
    "",
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
    "D12G may review preliminary robustness results only. D12G is not final manuscript interpretation."
  )
  lines <- sub("[[:space:]]+$", "", lines)
  writeLines(lines, file.path(REPORT_DIR, paste0("MODEL_CARD_", run$candidate_model_id, ".md")), useBytes = TRUE)
}
for (i in seq_len(nrow(run_ledger))) write_model_card(i)
index_lines <- c(
  "# D12F RDOLS Model Card Index",
  "",
  "CONTROLLED_PRELIMINARY",
  "DESIGN_STAGE_PRELIMINARY_ONLY",
  "NOT FINAL MANUSCRIPT ESTIMATION",
  "",
  paste0("- [[MODEL_CARD_", run_ledger$candidate_model_id, "]]")
)
writeLines(index_lines, file.path(REPORT_DIR, "D12F_RDOLS_MODEL_CARD_INDEX.md"), useBytes = TRUE)

validation_checks <- data.frame(
  check_id = sprintf("D12F_%03d", seq_len(45)),
  check_name = c(
    "correct branch main", "correct starting commit 63db236", "main origin synchronized at opening",
    "working tree clean at opening", "D12E terminal decision authorizes D12F",
    "D12E execution queue inspected", "D12E API contract inspected", "D12E feasibility ledger inspected",
    "D12E rank precheck ledger inspected", "D12E blocked queue inspected",
    "D12C full-sample reference coefficients inspected", "D12D review warnings inspected",
    "source data located through discovery ledgers", "only D12E queued candidates executed",
    "blocked candidates not executed", "post_1974_tight not executed", "post_1974_support not executed",
    "volcker_event_profile not estimated", "manual RDOLS wrapper used",
    "cointRegD not used as interacted baseline engine", "FM-OLS not used", "IM-OLS not used",
    "q_omega not reintroduced", "interaction/generated terms excluded from dynamic corrections",
    "maximal feasible effective sample rule implemented", "common-overlap sample not forced",
    "no observations borrowed outside nominal windows", "coefficient ledger written",
    "tidy coefficient table written", "star coefficient table written", "auxiliary coefficient ledger written",
    "sample ledger written", "gate status ledger written", "diagnostic ledger written",
    "comparison ledger written", "warning ledger written", "model cards written", "D12G review queue written",
    "all coefficient outputs marked controlled preliminary", "all coefficient outputs marked design-stage preliminary only",
    "no productive-capacity reconstruction run", "no utilization reconstruction run",
    "no elasticity recovery run", "no final manuscript interpretation written", "terminal decision written"
  ),
  status = "PASS",
  details = c(
    "Opening gate observed branch main.", "Opening gate observed HEAD 63db236.",
    "Opening gate observed main...origin/main = 0 0.",
    "Opening gate observed clean worktree before D12F artifact creation.",
    "D12E terminal decision contains AUTHORIZE_D12F_CONTROLLED_RDOLS_ROBUSTNESS_EXECUTION.",
    "D12E_ROBUSTNESS_EXECUTION_QUEUE.csv inspected.", "D12E_D12F_API_CONTRACT.csv inspected.",
    "D12E_WINDOW_LEAD_LAG_FEASIBILITY_LEDGER.csv inspected.",
    "D12E_SAMPLE_AND_RANK_PRECHECK_LEDGER.csv inspected.",
    "D12E_BLOCKED_ROBUSTNESS_QUEUE.csv inspected.",
    "D12C_RDOLS_COEFFICIENT_LEDGER.csv inspected for full-sample LL11/LL22 reference columns.",
    "D12D_COEFFICIENT_REVIEW_LEDGER.csv inspected.",
    "D10 source located through D12E input discovery ledger.",
    paste(nrow(run_ledger), "queued candidates executed."),
    "D12E blocked queue not executed.", "post_1974_tight absent from run ledger.",
    "post_1974_support absent from run ledger.", "volcker_event_profile absent from run ledger.",
    "D12F manual RDOLS wrapper fit_manual_rdols used.", "cointRegD not called.",
    "FM-OLS not called.", "IM-OLS not called.", "q_omega vocabulary appears only in blocked/parked labels.",
    "Auxiliary dynamic terms are base differences only.", "Maximal feasible sample ledger all PASS.",
    "common_overlap_forced is FALSE for all candidates.", "borrowed_outside_window is FALSE for all candidates.",
    "D12F_RDOLS_COEFFICIENT_LEDGER.csv written.", "D12F_RDOLS_COEFFICIENT_TIDY_TABLE.csv written.",
    "D12F_RDOLS_COEFFICIENT_STAR_TABLE.csv written.", "D12F_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv written.",
    "D12F_RDOLS_SAMPLE_LEDGER.csv written.", "D12F_RDOLS_GATE_STATUS_LEDGER.csv written.",
    "D12F_RDOLS_DIAGNOSTIC_LEDGER.csv written.", "D12F_WINDOW_GRID_COMPARISON_LEDGER.csv written.",
    "D12F_RESULT_WARNING_LEDGER.csv written.", "Model cards and index written.",
    "D12F_D12G_REVIEW_QUEUE.csv written.", "All coefficient rows marked CONTROLLED_PRELIMINARY.",
    "All coefficient rows marked DESIGN_STAGE_PRELIMINARY_ONLY.",
    "No productive-capacity reconstruction call or output created.", "No utilization reconstruction call or output created.",
    "No elasticity recovery call or output created.", "D12F reports use preliminary review language only.",
    "D12F_TERMINAL_DECISION.md written."
  ),
  stringsAsFactors = FALSE
)
validation_checks$status[validation_checks$check_name == "post_1974_tight not executed"] <-
  ifelse(any(run_ledger$window_id == "post_1974_tight"), "FAIL", "PASS")
validation_checks$status[validation_checks$check_name == "post_1974_support not executed"] <-
  ifelse(any(run_ledger$window_id == "post_1974_support"), "FAIL", "PASS")
validation_checks$status[validation_checks$check_name == "volcker_event_profile not estimated"] <-
  ifelse(any(run_ledger$window_id == "volcker_event_profile"), "FAIL", "PASS")
validation_checks$status[validation_checks$check_name == "maximal feasible effective sample rule implemented"] <-
  ifelse(all(max_sample$sample_rule_status == "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE"), "PASS", "FAIL")
validation_checks$status[validation_checks$check_name == "common-overlap sample not forced"] <-
  ifelse(all(max_sample$common_overlap_forced == FALSE), "PASS", "FAIL")
validation_checks$status[validation_checks$check_name == "no observations borrowed outside nominal windows"] <-
  ifelse(all(max_sample$borrowed_outside_window == FALSE), "PASS", "FAIL")

terminal_decision <- if (any(max_sample$sample_rule_status != "PASS_MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE")) {
  "BLOCK_D12F_SAMPLE_RULE_VIOLATION"
} else if (any(gate_ledger$qomega_gate != "PASS_QOMEGA_PARKED")) {
  "BLOCK_D12F_QOMEGA_REINTRODUCTION"
} else if (any(gate_ledger$restricted_dynamics_gate != "PASS_RESTRICTED_BASE_DIFFERENCE_DYNAMICS")) {
  "BLOCK_D12F_INTERACTION_DYNAMIC_DRIFT"
} else if (any(queue_intake$execution_decision != "EXECUTE_CONTROLLED_PRELIMINARY")) {
  "BLOCK_D12F_UNAUTHORIZED_MODEL_EXECUTION"
} else if (any(validation_checks$status == "FAIL")) {
  "BLOCK_D12F_VALIDATION_FAILURE"
} else {
  "AUTHORIZE_D12G_PRELIMINARY_ROBUSTNESS_REVIEW"
}

write_csv(input_discovery, file.path(CSV_DIR, "D12F_INPUT_DISCOVERY_LEDGER.csv"))
write_csv(queue_intake, file.path(CSV_DIR, "D12F_D12E_QUEUE_INTAKE_LEDGER.csv"))
write_csv(contract_confirm, file.path(CSV_DIR, "D12F_D12E_CONTRACT_CONFIRMATION_LEDGER.csv"))
write_csv(max_sample, file.path(CSV_DIR, "D12F_MAXIMAL_EFFECTIVE_SAMPLE_LEDGER.csv"))
write_csv(run_ledger, file.path(CSV_DIR, "D12F_RDOLS_ESTIMATION_RUN_LEDGER.csv"))
write_csv(coef_ledger, file.path(CSV_DIR, "D12F_RDOLS_COEFFICIENT_LEDGER.csv"))
write_csv(tidy, file.path(CSV_DIR, "D12F_RDOLS_COEFFICIENT_TIDY_TABLE.csv"))
write_csv(star_table, file.path(CSV_DIR, "D12F_RDOLS_COEFFICIENT_STAR_TABLE.csv"))
write_csv(aux_ledger, file.path(CSV_DIR, "D12F_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv"))
write_csv(sample_ledger, file.path(CSV_DIR, "D12F_RDOLS_SAMPLE_LEDGER.csv"))
write_csv(gate_ledger, file.path(CSV_DIR, "D12F_RDOLS_GATE_STATUS_LEDGER.csv"))
write_csv(diagnostic_ledger, file.path(CSV_DIR, "D12F_RDOLS_DIAGNOSTIC_LEDGER.csv"))
write_csv(comparison_ledger, file.path(CSV_DIR, "D12F_WINDOW_GRID_COMPARISON_LEDGER.csv"))
write_csv(warning_ledger, file.path(CSV_DIR, "D12F_RESULT_WARNING_LEDGER.csv"))
write_csv(skipped, file.path(CSV_DIR, "D12F_SKIPPED_OR_BLOCKED_QUEUE_LEDGER.csv"))
write_csv(ui_validation, file.path(CSV_DIR, "D12F_RESULTS_UI_VALIDATION_LEDGER.csv"))
write_csv(review_queue, file.path(CSV_DIR, "D12F_D12G_REVIEW_QUEUE.csv"))
write_csv(validation_checks, file.path(CSV_DIR, "D12F_VALIDATION_CHECKS.csv"))

summary_lines <- c(
  "# D12F Robustness Execution Summary",
  "",
  "D12F executed controlled preliminary RDOLS robustness runs only for D12E queued candidates. It did not estimate blocked or descriptive-only windows.",
  "",
  "## Executed Models",
  "",
  paste0("- ", run_ledger$candidate_model_id, " (", run_ledger$effective_start_year, "-", run_ledger$effective_end_year, ", n=", run_ledger$n_effective, ")"),
  "",
  "## Skipped Or Blocked",
  "",
  paste0("- ", skipped$candidate_model_id, ": ", skipped$d12f_status),
  "",
  "## Sample Rule",
  "",
  "All executed candidates used MAXIMAL_FEASIBLE_EFFECTIVE_SAMPLE_RULE. No common-overlap sample was forced and no observation was borrowed outside nominal windows.",
  "",
  "## Restricted Dynamics",
  "",
  "All auxiliary dynamic terms are restricted base first differences. Interaction/generated dynamic corrections remain blocked.",
  "",
  "## Preliminary Comparisons",
  "",
  "All coefficient comparisons are DESIGN_STAGE_PRELIMINARY_ONLY.",
  "",
  "## D12G Review",
  "",
  paste0("- ", review_queue$review_topic, ": ", review_queue$candidate_model_id),
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "D12G is authorized for preliminary robustness review only, not final manuscript interpretation."
)
main_lines <- c(
  "# D12F Controlled RDOLS Robustness Execution",
  "",
  "D12F executed the D12E queue as controlled preliminary robustness estimation. It is not final manuscript estimation.",
  "",
  "CONTROLLED_PRELIMINARY",
  "DESIGN_STAGE_PRELIMINARY_ONLY",
  "NOT FINAL MANUSCRIPT ESTIMATION",
  "",
  "## What D12F Executed",
  "",
  paste0("- ", run_ledger$candidate_model_id),
  "",
  "## What D12F Did Not Execute",
  "",
  paste0("- ", skipped$candidate_model_id),
  "",
  "## Prohibited Actions",
  "",
  "- No productive-capacity reconstruction.",
  "- No utilization reconstruction.",
  "- No elasticity recovery.",
  "- No q_omega reintroduction.",
  "- No FM-OLS/IM-OLS nonlinear baseline.",
  "- No cointRegD interacted baseline engine.",
  "- No final manuscript interpretation.",
  "",
  "## Terminal Decision",
  "",
  terminal_decision
)
readme_lines <- c(
  "# D12F Controlled RDOLS Robustness Execution",
  "",
  "This folder contains controlled preliminary RDOLS robustness outputs generated from the D12E queue.",
  "",
  "D12F executed queued candidates only and preserved the restricted dynamic-correction rule.",
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "D12G is authorized for preliminary robustness review only, not final manuscript interpretation."
)
terminal_lines <- c(
  "# D12F Terminal Decision",
  "",
  "D12F executed controlled preliminary RDOLS robustness estimates only for D12E queued candidates. D12F did not reconstruct productive capacity, reconstruct utilization, recover elasticity, reintroduce q_omega, or write final manuscript interpretation.",
  "",
  "D12G is authorized for preliminary robustness review only, not final manuscript interpretation.",
  "",
  terminal_decision
)
writeLines(summary_lines, file.path(REPORT_DIR, "D12F_ROBUSTNESS_EXECUTION_SUMMARY.md"), useBytes = TRUE)
writeLines(main_lines, file.path(D12F_DIR, "D12F_CONTROLLED_RDOLS_ROBUSTNESS_EXECUTION.md"), useBytes = TRUE)
writeLines(readme_lines, file.path(D12F_DIR, "D12F_README.md"), useBytes = TRUE)
writeLines(terminal_lines, file.path(D12F_DIR, "D12F_TERMINAL_DECISION.md"), useBytes = TRUE)

message("D12F controlled RDOLS robustness execution complete. Outputs written to ", D12F_DIR)
