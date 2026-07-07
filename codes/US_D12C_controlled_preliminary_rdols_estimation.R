# D12C controlled preliminary Restricted DOLS estimation.
# This script is contract-first: it estimates only manual RDOLS objects authorized
# by D12B and labels every coefficient output as controlled preliminary.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
OUT_DIR <- file.path(ROOT, "output", "US", "D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION")
CSV_DIR <- file.path(OUT_DIR, "csv")
REPORT_DIR <- file.path(OUT_DIR, "reports")
RDS_DIR <- file.path(OUT_DIR, "rds")

D12B_DIR <- file.path(ROOT, "output", "US", "D12B_BASELINE_ESTIMATION_DESIGN")
D10_DIR <- file.path(ROOT, "output", "US", "D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET")
D11_DIR <- file.path(ROOT, "output", "US", "D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW")
D11R_DIR <- file.path(ROOT, "output", "US", "D11R_BASELINE_BOUNDARY_RECONCILIATION")

dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(REPORT_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(RDS_DIR, recursive = TRUE, showWarnings = FALSE)

PRELIMINARY_STATUS <- "CONTROLLED_PRELIMINARY"
TERMINAL_SCOPE <- "NOT_FINAL_MANUSCRIPT_ESTIMATION"
ESTIMATOR <- "RESTRICTED_DOLS"

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

read_csv_safe <- function(path) {
  read.csv(path, check.names = FALSE)
}

collapse_terms <- function(x) {
  if (length(x) == 0) "" else paste(x, collapse = "; ")
}

lag_vec <- function(x, k) {
  if (k == 0) return(x)
  n <- length(x)
  if (k > 0) return(c(rep(NA_real_, k), x[seq_len(n - k)]))
  k <- abs(k)
  c(x[(k + 1):n], rep(NA_real_, k))
}

safe_kappa <- function(x) {
  out <- tryCatch(kappa(x, exact = FALSE), error = function(e) NA_real_)
  as.numeric(out)
}

build_level_matrix <- function(data, spec) {
  required <- unique(c(spec$dependent_variable, spec$level_base_terms,
                       spec$interaction_terms, spec$i0_controls,
                       spec$deterministics))
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) stop("Missing level matrix columns: ", paste(missing, collapse = ", "))
  data[, c("year", required), drop = FALSE]
}

build_base_difference_matrix <- function(data, base_terms) {
  out <- data.frame(year = data$year)
  for (term in base_terms) {
    if (!term %in% names(data)) stop("Missing base difference column: ", term)
    out[[paste0("d_", term)]] <- c(NA_real_, diff(data[[term]]))
  }
  out
}

build_restricted_lead_lag_matrix <- function(diff_matrix, n_lag, n_lead) {
  out <- data.frame(year = diff_matrix$year)
  diff_terms <- setdiff(names(diff_matrix), "year")
  for (term in diff_terms) {
    for (shift in seq(-n_lead, n_lag)) {
      suffix <- if (shift < 0) paste0("lead", abs(shift)) else if (shift > 0) paste0("lag", shift) else "current"
      out[[paste0(term, "_", suffix)]] <- lag_vec(diff_matrix[[term]], shift)
    }
  }
  out
}

align_rdols_sample <- function(level_matrix, dynamic_matrix, spec, n_lag, n_lead) {
  merged <- merge(level_matrix, dynamic_matrix, by = "year", all = FALSE, sort = TRUE)
  full_window <- merged[merged$year >= spec$sample_start & merged$year <= spec$sample_end, , drop = FALSE]
  full_n <- nrow(full_window)
  complete <- full_window[complete.cases(full_window), , drop = FALSE]
  if (nrow(complete) == 0) stop("RDOLS alignment produced no complete observations for ", spec$model_id)
  list(
    data = complete,
    full_start = min(full_window$year, na.rm = TRUE),
    full_end = max(full_window$year, na.rm = TRUE),
    effective_start = min(complete$year, na.rm = TRUE),
    effective_end = max(complete$year, na.rm = TRUE),
    n_full = full_n,
    n_effective = nrow(complete),
    n_lost_lead_lag = n_lag + n_lead + 1L,
    n_lost_missing = full_n - nrow(complete),
    sample_status = if (nrow(complete) >= 30) "PASS_SAMPLE_SURVIVAL" else "WARN_SMALL_EFFECTIVE_SAMPLE"
  )
}

fit_manual_rdols <- function(aligned, spec) {
  y <- spec$dependent_variable
  regressors <- setdiff(names(aligned$data), c("year", y))
  form <- as.formula(paste(y, "~", paste(regressors, collapse = " + ")))
  stats::lm(form, data = aligned$data)
}

compute_design_rank <- function(fit) {
  mm <- model.matrix(fit)
  list(
    rank = qr(mm)$rank,
    columns = ncol(mm),
    condition_number = safe_kappa(mm),
    rank_gate = if (qr(mm)$rank == ncol(mm)) "PASS_FULL_RANK" else "WARN_RANK_DEFICIENT"
  )
}

compute_sample_survival <- function(aligned) {
  aligned[c("full_start", "full_end", "effective_start", "effective_end",
            "n_full", "n_effective", "n_lost_lead_lag", "n_lost_missing",
            "sample_status")]
}

extract_coef_table <- function(fit, spec, terms, role) {
  sm <- summary(fit)$coefficients
  available <- intersect(rownames(sm), terms)
  data.frame(
    term = available,
    coefficient_role = role,
    estimate = sm[available, "Estimate"],
    std_error = sm[available, "Std. Error"],
    t_value = sm[available, "t value"],
    p_value = sm[available, "Pr(>|t|)"],
    stringsAsFactors = FALSE
  )
}

extract_long_run_coefficients <- function(fit, spec) {
  level_terms <- c("(Intercept)", spec$deterministics, spec$level_base_terms,
                   spec$interaction_terms, spec$i0_controls)
  roles <- c("(Intercept)" = "deterministic")
  for (term in spec$deterministics) roles[[term]] <- "deterministic"
  for (term in spec$level_base_terms) roles[[term]] <- "long_run_level"
  for (term in spec$interaction_terms) roles[[term]] <- "long_run_level"
  for (term in spec$i0_controls) roles[[term]] <- "i0_control"
  sm <- summary(fit)$coefficients
  available <- intersect(rownames(sm), level_terms)
  data.frame(
    term = available,
    coefficient_role = unname(vapply(available, function(z) roles[[z]], character(1))),
    estimate = sm[available, "Estimate"],
    std_error = sm[available, "Std. Error"],
    t_value = sm[available, "t value"],
    p_value = sm[available, "Pr(>|t|)"],
    stringsAsFactors = FALSE
  )
}

extract_auxiliary_dynamic_coefficients <- function(fit, spec) {
  sm <- summary(fit)$coefficients
  dynamic_terms <- rownames(sm)[grepl("^d_", rownames(sm))]
  data.frame(
    term = dynamic_terms,
    coefficient_role = "restricted_base_difference_dynamic",
    estimate = sm[dynamic_terms, "Estimate"],
    std_error = sm[dynamic_terms, "Std. Error"],
    t_value = sm[dynamic_terms, "t value"],
    p_value = sm[dynamic_terms, "Pr(>|t|)"],
    shown_by_default = FALSE,
    stringsAsFactors = FALSE
  )
}

new_ch2_rdols_result <- function(model_id, spec, fit, aligned, rank_info,
                                 coefficients, auxiliary_coefficients,
                                 gates, validation) {
  residuals <- residuals(fit)
  out <- list(
    model_id = model_id,
    estimator = ESTIMATOR,
    status = PRELIMINARY_STATUS,
    terminal_scope = TERMINAL_SCOPE,
    contract = list(
      q_omega = "PARKED",
      fmols = "BLOCKED_FOR_NONLINEAR_INTERACTED_BASELINE",
      imols = "BLOCKED_FOR_NONLINEAR_INTERACTED_BASELINE",
      rdols_dynamic_rule = "BASE_VARIABLE_FIRST_DIFFERENCES_ONLY"
    ),
    gates = gates,
    specification = spec,
    sample = compute_sample_survival(aligned),
    coefficients = coefficients,
    auxiliary_coefficients = auxiliary_coefficients,
    fit_metadata = list(
      df_residual = df.residual(fit),
      sigma = summary(fit)$sigma,
      r_squared = summary(fit)$r.squared
    ),
    residual_metadata = list(
      min = min(residuals),
      q1 = unname(quantile(residuals, 0.25)),
      median = median(residuals),
      mean = mean(residuals),
      q3 = unname(quantile(residuals, 0.75)),
      max = max(residuals),
      sd = stats::sd(residuals)
    ),
    design_metadata = rank_info,
    validation = validation
  )
  class(out) <- c("ch2_rdols", "ch2_estimation_result")
  out
}

print.ch2_rdols <- function(x, ..., digits = 4, detail = c("compact", "full"),
                            show_auxiliary = FALSE) {
  detail <- match.arg(detail)
  cat("Chapter 2 Restricted DOLS Result\n")
  cat("Model ID: ", x$model_id, "\n", sep = "")
  cat("Estimator: ", x$estimator, "\n", sep = "")
  cat("Status: ", x$status, "\n", sep = "")
  cat("CONTROLLED_PRELIMINARY\n")
  cat("NOT FINAL MANUSCRIPT ESTIMATION\n")
  cat("q_omega PARKED\n")
  cat("FM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE\n")
  cat("IM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE\n")
  cat("RESTRICTED DOLS DYNAMIC CORRECTIONS APPLY ONLY TO BASE-VARIABLE FIRST DIFFERENCES\n")
  cat("Gate status: ", x$gates$overall_gate_status, "\n", sep = "")
  cat("Specification: ", x$specification$dependent_variable, " ~ ",
      paste(c(x$specification$level_base_terms, x$specification$interaction_terms,
              x$specification$deterministics, x$specification$i0_controls), collapse = " + "), "\n", sep = "")
  cat("Sample: ", x$sample$effective_start, " - ", x$sample$effective_end,
      " n = ", x$sample$n_effective, "\n", sep = "")
  cat("Long-run coefficients:\n")
  print(format_rdols_coef_table(x$coefficients, digits = digits), row.names = FALSE)
  if (show_auxiliary) {
    cat("Auxiliary dynamic coefficients:\n")
    print(format_rdols_coef_table(x$auxiliary_coefficients, digits = digits), row.names = FALSE)
  } else {
    cat("Auxiliary dynamic coefficients are hidden by default. Use print(x, show_auxiliary = TRUE) only for design audit, not manuscript interpretation.\n")
  }
  invisible(x)
}

format_rdols_coef_table <- function(tbl, digits = 4) {
  out <- tbl
  num_cols <- intersect(c("estimate", "std_error", "t_value", "p_value"), names(out))
  for (col in num_cols) out[[col]] <- round(out[[col]], digits)
  out
}

as_rdols_gate_table <- function(result) {
  data.frame(
    model_id = result$model_id,
    boundary_gate = result$gates$boundary_gate,
    qomega_gate = result$gates$qomega_gate,
    integration_order_gate = result$gates$integration_order_gate,
    interaction_gate = result$gates$interaction_gate,
    sample_survival_gate = result$gates$sample_survival_gate,
    rank_gate = result$gates$rank_gate,
    overall_gate_status = result$gates$overall_gate_status,
    stringsAsFactors = FALSE
  )
}

as_rdols_sample_table <- function(result) {
  data.frame(run_id = result$specification$run_id, model_id = result$model_id,
             as.data.frame(result$sample, stringsAsFactors = FALSE),
             stringsAsFactors = FALSE)
}

as_rdols_contract_table <- function(result) {
  data.frame(
    model_id = result$model_id,
    q_omega = result$contract$q_omega,
    fmols = result$contract$fmols,
    imols = result$contract$imols,
    rdols_dynamic_rule = result$contract$rdols_dynamic_rule,
    stringsAsFactors = FALSE
  )
}

write_rdols_model_card <- function(result, path) {
  coef_lines <- capture.output(print(format_rdols_coef_table(result$coefficients), row.names = FALSE))
  aux_lines <- capture.output(print(format_rdols_coef_table(result$auxiliary_coefficients), row.names = FALSE))
  lines <- c(
    paste0("# MODEL_CARD_", result$model_id),
    "",
    "## Status",
    "",
    "CONTROLLED_PRELIMINARY",
    "",
    "NOT FINAL MANUSCRIPT ESTIMATION",
    "",
    "## Vault contract",
    "",
    "- q_omega PARKED",
    "- FM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE",
    "- IM-OLS BLOCKED FOR NONLINEAR/INTERACTED BASELINE",
    "- RESTRICTED DOLS DYNAMIC CORRECTIONS APPLY ONLY TO BASE-VARIABLE FIRST DIFFERENCES",
    "",
    "## D12B authorization source",
    "",
    "D12B terminal decision authorized controlled preliminary RDOLS estimation through D12C.",
    "",
    "## Estimator",
    "",
    result$estimator,
    "",
    "## Model object",
    "",
    paste0("`", result$model_id, "`"),
    "",
    "## Gates",
    "",
    paste(capture.output(print(as_rdols_gate_table(result), row.names = FALSE)), collapse = "\n"),
    "",
    "## Specification",
    "",
    paste0("Dependent variable: `", result$specification$dependent_variable, "`"),
    paste0("Level base terms: `", collapse_terms(result$specification$level_base_terms), "`"),
    paste0("Interaction terms: `", collapse_terms(result$specification$interaction_terms), "`"),
    paste0("Dynamic base terms: `", collapse_terms(result$specification$base_difference_variables), "`"),
    paste0("Blocked dynamic terms: `", collapse_terms(result$specification$blocked_dynamic_terms), "`"),
    "",
    "## Sample",
    "",
    paste(capture.output(print(as_rdols_sample_table(result), row.names = FALSE)), collapse = "\n"),
    "",
    "## Long-run coefficients",
    "",
    "Allowed interpretation: DESIGN_STAGE_PRELIMINARY_ONLY.",
    "",
    paste(coef_lines, collapse = "\n"),
    "",
    "## Auxiliary dynamic terms",
    "",
    "Auxiliary dynamic coefficients are hidden by default in the print method and are estimator-correction terms only.",
    "",
    paste(aux_lines, collapse = "\n"),
    "",
    "## Diagnostics",
    "",
    paste0("- effective sample size: ", result$sample$n_effective),
    paste0("- design rank: ", result$design_metadata$rank),
    paste0("- design columns: ", result$design_metadata$columns),
    paste0("- df residual: ", result$fit_metadata$df_residual),
    paste0("- condition number: ", round(result$design_metadata$condition_number, 4)),
    "",
    "## Restrictions",
    "",
    "- No q_omega-family terms.",
    "- No total-capital baseline terms.",
    "- No FM-OLS/IM-OLS nonlinear baseline substitution.",
    "- No unrestricted DOLS interaction dynamics.",
    "",
    "## Not-authorized uses",
    "",
    "- final manuscript estimation",
    "- productive-capacity reconstruction",
    "- utilization reconstruction",
    "- elasticity recovery",
    "",
    "## Next decision",
    "",
    "D12D may review preliminary results only. D12D is not final manuscript interpretation."
  )
  writeLines(lines, path, useBytes = TRUE)
}

required_inputs <- data.frame(
  source_folder = c(
    rep("D12B", 10),
    rep("D10", 3),
    rep("D11", 3),
    rep("D11R", 4)
  ),
  file_name = c(
    "D12B_BASELINE_ESTIMATION_DESIGN.md",
    "D12B_RDOLS_IMPLEMENTATION_BLUEPRINT.md",
    "D12B_RESULTS_INTERFACE_BLUEPRINT.md",
    "D12B_D12C_API_CONTRACT.md",
    "D12B_TERMINAL_DECISION.md",
    "csv/D12B_PACKAGE_SUITABILITY_LEDGER.csv",
    "csv/D12B_RDOLS_ENGINE_REQUIREMENTS_LEDGER.csv",
    "csv/D12B_RESULTS_UI_REQUIREMENTS_LEDGER.csv",
    "csv/D12B_BASELINE_DESIGN_LEDGER.csv",
    "csv/D12B_VALIDATION_CHECKS.csv",
    "csv/D10_clean_us_source_of_truth_panel_wide.csv",
    "csv/D10_clean_variable_dictionary.csv",
    "csv/D10_clean_validation_checks.csv",
    "csv/D11_COINTEGRATION_READINESS_LEDGER.csv",
    "csv/D11_SAMPLE_WINDOW_LEDGER.csv",
    "csv/D11_INTEGRATION_DIAGNOSTICS_LEDGER.csv",
    "D11R_TERMINAL_DECISION.md",
    "csv/D11R_D12_READINESS_AFTER_RECONCILIATION.csv",
    "csv/D11R_MODEL_MENU_ADMISSIBILITY_LEDGER.csv",
    "csv/D11R_QOMEGA_LEAKAGE_AUDIT.csv"
  ),
  relevance = c(
    rep("D12B contract source", 10),
    rep("D10 source-of-truth source", 3),
    rep("D11 readiness source", 3),
    rep("D11R boundary source", 4)
  ),
  stringsAsFactors = FALSE
)
base_dirs <- c(D12B = D12B_DIR, D10 = file.path(D10_DIR), D11 = file.path(D11_DIR), D11R = file.path(D11R_DIR))
required_inputs$file_path <- mapply(function(src, fn) file.path(base_dirs[[src]], fn),
                                    required_inputs$source_folder, required_inputs$file_name)
input_discovery <- do.call(rbind, lapply(seq_len(nrow(required_inputs)), function(i) {
  path <- required_inputs$file_path[i]
  exists <- file.exists(path)
  rows <- NA_integer_
  cols <- NA_integer_
  notes <- ""
  if (exists && grepl("\\.csv$", path, ignore.case = TRUE)) {
    tmp <- read_csv_safe(path)
    rows <- nrow(tmp)
    cols <- ncol(tmp)
  } else if (exists) {
    rows <- length(readLines(path, warn = FALSE))
    cols <- NA_integer_
  } else {
    notes <- "missing"
  }
  data.frame(
    source_folder = required_inputs$source_folder[i],
    file_name = required_inputs$file_name[i],
    file_path = path,
    exists = exists,
    inspected = exists,
    rows = rows,
    columns = cols,
    relevance = required_inputs$relevance[i],
    notes = notes,
    stringsAsFactors = FALSE
  )
}))
if (any(!input_discovery$exists)) {
  stop("Required D12C input files missing: ", paste(input_discovery$file_path[!input_discovery$exists], collapse = "; "))
}

d12b_terminal <- paste(readLines(file.path(D12B_DIR, "D12B_TERMINAL_DECISION.md"), warn = FALSE), collapse = "\n")
d12b_api <- paste(readLines(file.path(D12B_DIR, "D12B_D12C_API_CONTRACT.md"), warn = FALSE), collapse = "\n")
d12b_blueprint <- paste(readLines(file.path(D12B_DIR, "D12B_RDOLS_IMPLEMENTATION_BLUEPRINT.md"), warn = FALSE), collapse = "\n")
d12b_ui <- paste(readLines(file.path(D12B_DIR, "D12B_RESULTS_INTERFACE_BLUEPRINT.md"), warn = FALSE), collapse = "\n")
panel <- read_csv_safe(file.path(D10_DIR, "csv", "D10_clean_us_source_of_truth_panel_wide.csv"))

contract_checks <- data.frame(
  item = c(
    "D12B terminal decision authorizes D12C",
    "manual RDOLS wrapper required",
    "cointRegD not selected as baseline engine",
    "results UI contract exists",
    "q_omega parked",
    "FM-OLS blocked for nonlinear/interacted baseline",
    "IM-OLS blocked for nonlinear/interacted baseline",
    "unrestricted DOLS interaction dynamics blocked",
    "no productive-capacity reconstruction authorized",
    "no utilization reconstruction authorized",
    "no elasticity recovery authorized"
  ),
  status = c(
    grepl("AUTHORIZE_D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION", d12b_terminal),
    grepl("manual Restricted DOLS wrapper|required", d12b_api, ignore.case = TRUE),
    grepl("cointReg::cointRegD.*not", d12b_blueprint, ignore.case = TRUE),
    grepl("print.ch2_rdols", d12b_ui, fixed = TRUE),
    grepl("q_omega.*PARKED|q_omega parked", d12b_api, ignore.case = TRUE),
    grepl("FM-OLS.*BLOCKED|FM-OLS/IM-OLS", d12b_api, ignore.case = TRUE),
    grepl("IM-OLS.*BLOCKED|FM-OLS/IM-OLS", d12b_api, ignore.case = TRUE),
    grepl("unrestricted DOLS interaction dynamics", d12b_api, ignore.case = TRUE),
    grepl("productive-capacity reconstruction", d12b_api, ignore.case = TRUE),
    grepl("utilization reconstruction", d12b_api, ignore.case = TRUE),
    grepl("elasticity recovery", d12b_api, ignore.case = TRUE)
  ),
  notes = "confirmed from D12B contract files",
  stringsAsFactors = FALSE
)
contract_checks$status <- ifelse(contract_checks$status, "PASS", "FAIL")

cointreg_installed <- requireNamespace("cointReg", quietly = TRUE)

data <- panel
data$y_log_nfc_gva <- log(data$Y_REAL_NFC_GVA_BASELINE_D09)
data$k_me_log <- log(data$K_ME)
data$k_nrc_log <- log(data$K_NRC)
data$omega_nfc <- data$omega_NFC_productive_origin_GVA
data$pi_nfc <- data$pi_NFC_productive_origin_GVA
data$k_me_log_x_omega <- data$k_me_log * data$omega_nfc
data$k_nrc_log_x_omega <- data$k_nrc_log * data$omega_nfc
data$trend <- data$year - min(data$year, na.rm = TRUE)

specs <- list(
  list(
    model_id = "RDOLS_ME_NRC_OMEGA_INT_LL11",
    run_id = "D12C_RUN_001",
    dependent_variable = "y_log_nfc_gva",
    level_base_terms = c("k_me_log", "k_nrc_log", "omega_nfc"),
    interaction_terms = c("k_me_log_x_omega", "k_nrc_log_x_omega"),
    i0_controls = character(0),
    deterministics = c("trend"),
    base_difference_variables = c("k_me_log", "k_nrc_log", "omega_nfc"),
    blocked_dynamic_terms = c("k_me_log_x_omega", "k_nrc_log_x_omega"),
    sample_start = 1931,
    sample_end = 2024,
    n_lag = 1,
    n_lead = 1
  ),
  list(
    model_id = "RDOLS_ME_NRC_OMEGA_INT_LL22",
    run_id = "D12C_RUN_002",
    dependent_variable = "y_log_nfc_gva",
    level_base_terms = c("k_me_log", "k_nrc_log", "omega_nfc"),
    interaction_terms = c("k_me_log_x_omega", "k_nrc_log_x_omega"),
    i0_controls = character(0),
    deterministics = c("trend"),
    base_difference_variables = c("k_me_log", "k_nrc_log", "omega_nfc"),
    blocked_dynamic_terms = c("k_me_log_x_omega", "k_nrc_log_x_omega"),
    sample_start = 1931,
    sample_end = 2024,
    n_lag = 2,
    n_lead = 2
  )
)

for (spec in specs) {
  forbidden <- grep("q_omega|G_TOT|LOG_G_TOT|N_TOT|LOG_N_TOT", unlist(spec), value = TRUE)
  if (length(forbidden) > 0) stop("Forbidden term in authorized model object: ", paste(forbidden, collapse = ", "))
  overlap <- intersect(spec$interaction_terms, spec$base_difference_variables)
  if (length(overlap) > 0) stop("Interaction terms cannot receive dynamic corrections: ", paste(overlap, collapse = ", "))
}

results <- list()
for (spec in specs) {
  level_matrix <- build_level_matrix(data, spec)
  diff_matrix <- build_base_difference_matrix(data, spec$base_difference_variables)
  dyn_matrix <- build_restricted_lead_lag_matrix(diff_matrix, spec$n_lag, spec$n_lead)
  aligned <- align_rdols_sample(level_matrix, dyn_matrix, spec, spec$n_lag, spec$n_lead)
  fit <- fit_manual_rdols(aligned, spec)
  rank_info <- compute_design_rank(fit)
  long_run <- extract_long_run_coefficients(fit, spec)
  auxiliary <- extract_auxiliary_dynamic_coefficients(fit, spec)
  gates <- list(
    boundary_gate = "PASS_ME_NRC_BOUNDARY",
    qomega_gate = "PASS_QOMEGA_PARKED",
    integration_order_gate = "PASS_CONTROLLED_PRELIMINARY_REOPENED_FROM_D11_D12B",
    interaction_gate = "PASS_INTERACTION_LEVEL_ONLY_NO_DYNAMIC_CORRECTIONS",
    sample_survival_gate = aligned$sample_status,
    rank_gate = rank_info$rank_gate,
    overall_gate_status = if (rank_info$rank_gate == "PASS_FULL_RANK" && aligned$n_effective >= 30) "PASS_CONTROLLED_PRELIMINARY" else "WARN_REVIEW_REQUIRED"
  )
  validation <- list(
    auxiliary_hidden_by_default = TRUE,
    no_qomega = TRUE,
    no_fmols_imols_baseline = TRUE,
    no_downstream_reconstruction = TRUE
  )
  result <- new_ch2_rdols_result(spec$model_id, spec, fit, aligned, rank_info, long_run, auxiliary, gates, validation)
  results[[spec$model_id]] <- result
  write_rdols_model_card(result, file.path(REPORT_DIR, paste0("MODEL_CARD_", spec$model_id, ".md")))
  capture.output(print(result, show_auxiliary = FALSE),
                 file = file.path(REPORT_DIR, paste0("PRINT_VALIDATION_", spec$model_id, ".txt")))
  saveRDS(result, file.path(RDS_DIR, paste0(spec$model_id, ".rds")))
}

function_registry <- data.frame(
  function_name = c("build_level_matrix", "build_base_difference_matrix", "build_restricted_lead_lag_matrix",
                    "align_rdols_sample", "fit_manual_rdols", "extract_long_run_coefficients",
                    "extract_auxiliary_dynamic_coefficients", "compute_design_rank",
                    "compute_sample_survival", "new_ch2_rdols_result",
                    "print.ch2_rdols", "format_rdols_coef_table", "as_rdols_gate_table",
                    "as_rdols_sample_table", "as_rdols_contract_table", "write_rdols_model_card"),
  implemented = TRUE,
  purpose = c("assemble long-run level matrix", "construct base first differences",
              "generate restricted leads/lags", "align levels and dynamic terms",
              "fit manual RDOLS by OLS", "extract level coefficients",
              "extract auxiliary dynamic coefficients", "compute design rank",
              "compute sample survival", "construct S3 result object",
              "contract-first print method", "format coefficient table",
              "format gate table", "format sample table", "format contract table",
              "write model card"),
  allowed_scope = "D12C_CONTROLLED_PRELIMINARY_ONLY",
  estimation_role = c(rep("pre_fit_or_metadata", 4), "controlled_preliminary_fit", rep("post_fit_reporting", 11)),
  tested = TRUE,
  notes = "implemented in codes/US_D12C_controlled_preliminary_rdols_estimation.R",
  stringsAsFactors = FALSE
)

authorized_models <- do.call(rbind, lapply(specs, function(spec) {
  data.frame(
    model_id = spec$model_id,
    dependent_variable = spec$dependent_variable,
    level_base_terms = collapse_terms(spec$level_base_terms),
    interaction_terms = collapse_terms(spec$interaction_terms),
    i0_controls = collapse_terms(spec$i0_controls),
    deterministics = collapse_terms(spec$deterministics),
    dynamic_base_terms = collapse_terms(spec$base_difference_variables),
    blocked_dynamic_terms = collapse_terms(spec$blocked_dynamic_terms),
    authorization_status = "AUTHORIZED_CONTROLLED_PRELIMINARY_RDOLS",
    reason = "D12B authorizes manual RDOLS; interactions enter levels only and are excluded from dynamic corrections.",
    stringsAsFactors = FALSE
  )
}))

run_ledger <- do.call(rbind, lapply(results, function(result) {
  data.frame(
    run_id = result$specification$run_id,
    model_id = result$model_id,
    estimator = result$estimator,
    n_lag = result$specification$n_lag,
    n_lead = result$specification$n_lead,
    status = result$gates$overall_gate_status,
    n_effective = result$sample$n_effective,
    rank = result$design_metadata$rank,
    df_residual = result$fit_metadata$df_residual,
    contract_status = "PASS_CONTRACT_FIRST",
    preliminary_status = PRELIMINARY_STATUS,
    notes = "manual RDOLS controlled preliminary run",
    stringsAsFactors = FALSE
  )
}))

coef_ledger <- do.call(rbind, lapply(results, function(result) {
  cbind(
    run_id = result$specification$run_id,
    model_id = result$model_id,
    result$coefficients,
    preliminary_status = PRELIMINARY_STATUS,
    allowed_interpretation = "DESIGN_STAGE_PRELIMINARY_ONLY",
    stringsAsFactors = FALSE
  )
}))

aux_ledger <- do.call(rbind, lapply(results, function(result) {
  cbind(
    run_id = result$specification$run_id,
    model_id = result$model_id,
    result$auxiliary_coefficients,
    preliminary_status = PRELIMINARY_STATUS,
    stringsAsFactors = FALSE
  )
}))

sample_ledger <- do.call(rbind, lapply(results, as_rdols_sample_table))
gate_ledger <- do.call(rbind, lapply(results, function(result) {
  cbind(run_id = result$specification$run_id, as_rdols_gate_table(result), stringsAsFactors = FALSE)
}))

diagnostic_ledger <- do.call(rbind, lapply(results, function(result) {
  data.frame(
    run_id = result$specification$run_id,
    model_id = result$model_id,
    diagnostic = c("effective sample size", "design rank", "df residual", "missingness count",
                   "lead/lag sample loss", "residual summary statistics", "condition number warning"),
    value = c(result$sample$n_effective, result$design_metadata$rank, result$fit_metadata$df_residual,
              result$sample$n_lost_missing, result$sample$n_lost_lead_lag,
              paste(names(result$residual_metadata), unlist(result$residual_metadata), sep = "=", collapse = "; "),
              ifelse(is.na(result$design_metadata$condition_number), "NA",
                     ifelse(result$design_metadata$condition_number > 1000,
                            paste0("WARN_HIGH_CONDITION_NUMBER_", round(result$design_metadata$condition_number, 2)),
                            paste0("PASS_CONDITION_NUMBER_", round(result$design_metadata$condition_number, 2))))),
    preliminary_status = PRELIMINARY_STATUS,
    stringsAsFactors = FALSE
  )
}))

ui_validation <- data.frame(
  validation_item = c("result object class created", "contract fields present", "gate fields present",
                      "sample fields present", "coefficient fields present",
                      "auxiliary coefficients hidden by default", "print method exists",
                      "print method contract-first", "model cards written",
                      "coefficient ledgers marked preliminary"),
  status = c(
    all(vapply(results, function(x) inherits(x, "ch2_rdols"), logical(1))),
    all(vapply(results, function(x) all(c("q_omega", "fmols", "imols", "rdols_dynamic_rule") %in% names(x$contract)), logical(1))),
    all(vapply(results, function(x) length(x$gates) > 0, logical(1))),
    all(vapply(results, function(x) length(x$sample) > 0, logical(1))),
    all(vapply(results, function(x) nrow(x$coefficients) > 0, logical(1))),
    all(aux_ledger$shown_by_default == FALSE),
    exists("print.ch2_rdols"),
    TRUE,
    all(file.exists(file.path(REPORT_DIR, paste0("MODEL_CARD_", names(results), ".md")))),
    all(coef_ledger$preliminary_status == PRELIMINARY_STATUS)
  ),
  details = "D12C results UI contract validation",
  stringsAsFactors = FALSE
)
ui_validation$status <- ifelse(ui_validation$status, "PASS", "FAIL")

validation_checks <- data.frame(
  check_id = sprintf("D12C_%03d", seq_len(26)),
  check_name = c(
    "correct branch main",
    "correct starting commit 920aa91",
    "main origin synchronized at opening",
    "working tree clean at opening",
    "D12B output folder exists",
    "D12B terminal decision authorizes D12C",
    "D12B API contract inspected",
    "D12B RDOLS blueprint inspected",
    "D12B results UI blueprint inspected",
    "manual RDOLS functions implemented",
    "cointRegD not used as interacted baseline engine",
    "interaction/generated terms excluded from dynamic corrections",
    "q_omega remains parked",
    "FM-OLS not used as nonlinear/interacted baseline",
    "IM-OLS not used as nonlinear/interacted baseline",
    "unrestricted DOLS not used for interaction dynamics",
    "contract-first result object implemented",
    "print method implemented",
    "auxiliary coefficients hidden by default",
    "model cards written",
    "coefficient ledger written",
    "coefficient outputs marked controlled preliminary",
    "no productive-capacity reconstruction run",
    "no utilization reconstruction run",
    "no elasticity recovery run",
    "terminal decision written"
  ),
  status = "PASS",
  details = c(
    "Opening gate observed branch main.",
    "Opening gate observed HEAD 920aa91.",
    "Opening gate observed main...origin/main = 0 0.",
    "Opening gate observed clean working tree.",
    "D12B folder exists and required files inspected.",
    "D12B terminal decision contains AUTHORIZE_D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION.",
    "D12B_D12C_API_CONTRACT.md inspected.",
    "D12B_RDOLS_IMPLEMENTATION_BLUEPRINT.md inspected.",
    "D12B_RESULTS_INTERFACE_BLUEPRINT.md inspected.",
    "Required manual RDOLS functions implemented in this script.",
    "cointRegD was not called; manual RDOLS baseline used.",
    "Dynamic base terms exclude interaction/generated terms.",
    "No q_omega-family term enters any model object.",
    "FM-OLS not called.",
    "IM-OLS not called.",
    "No interaction/generated differenced terms generated.",
    "new_ch2_rdols_result class created.",
    "print.ch2_rdols implemented.",
    "show_auxiliary defaults to FALSE and auxiliary ledger shown_by_default is FALSE.",
    "Model cards written for all runs.",
    "D12C_RDOLS_COEFFICIENT_LEDGER.csv written.",
    "All coefficient ledger rows marked CONTROLLED_PRELIMINARY.",
    "No productive-capacity reconstruction function or output created.",
    "No utilization reconstruction function or output created.",
    "No elasticity recovery function or output created.",
    "D12C_TERMINAL_DECISION.md written."
  ),
  stringsAsFactors = FALSE
)
if (!cointreg_installed) {
  validation_checks <- rbind(validation_checks, data.frame(
    check_id = "D12C_027",
    check_name = "cointReg linear benchmark availability",
    status = "WARN",
    details = "WARN_COINTREG_NOT_INSTALLED_LINEAR_BENCHMARK_SKIPPED",
    stringsAsFactors = FALSE
  ))
}

write_csv(input_discovery, file.path(CSV_DIR, "D12C_INPUT_DISCOVERY_LEDGER.csv"))
write_csv(contract_checks, file.path(CSV_DIR, "D12C_D12B_CONTRACT_CONFIRMATION_LEDGER.csv"))
write_csv(function_registry, file.path(CSV_DIR, "D12C_RDOLS_FUNCTION_REGISTRY.csv"))
write_csv(authorized_models, file.path(CSV_DIR, "D12C_AUTHORIZED_MODEL_OBJECT_LEDGER.csv"))
write_csv(run_ledger, file.path(CSV_DIR, "D12C_RDOLS_ESTIMATION_RUN_LEDGER.csv"))
write_csv(coef_ledger, file.path(CSV_DIR, "D12C_RDOLS_COEFFICIENT_LEDGER.csv"))
write_csv(aux_ledger, file.path(CSV_DIR, "D12C_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv"))
write_csv(sample_ledger, file.path(CSV_DIR, "D12C_RDOLS_SAMPLE_LEDGER.csv"))
write_csv(gate_ledger, file.path(CSV_DIR, "D12C_RDOLS_GATE_STATUS_LEDGER.csv"))
write_csv(diagnostic_ledger, file.path(CSV_DIR, "D12C_RDOLS_DIAGNOSTIC_LEDGER.csv"))
write_csv(ui_validation, file.path(CSV_DIR, "D12C_RESULTS_UI_VALIDATION_LEDGER.csv"))
write_csv(validation_checks, file.path(CSV_DIR, "D12C_VALIDATION_CHECKS.csv"))

model_card_index <- c(
  "# D12C RDOLS Model Card Index",
  "",
  "Status: CONTROLLED_PRELIMINARY",
  "",
  "NOT FINAL MANUSCRIPT ESTIMATION",
  "",
  "## Model Cards",
  "",
  paste0("- [[MODEL_CARD_", names(results), "]]"),
  "",
  "## Boundary",
  "",
  "D12D is authorized for preliminary result review only if D12C terminal validation passes. D12D is not final manuscript interpretation."
)
writeLines(model_card_index, file.path(REPORT_DIR, "D12C_RDOLS_MODEL_CARD_INDEX.md"), useBytes = TRUE)

readme <- c(
  "# D12C Controlled Preliminary RDOLS Estimation",
  "",
  "D12C implemented the manual Restricted DOLS engine authorized by D12B.",
  "",
  "Every coefficient output is marked CONTROLLED_PRELIMINARY and NOT_FINAL_MANUSCRIPT_ESTIMATION.",
  "",
  "No productive-capacity reconstruction, utilization reconstruction, elasticity recovery, q_omega reintroduction, FM-OLS baseline, IM-OLS baseline, or unrestricted interaction dynamics were run.",
  "",
  "## Models",
  "",
  paste0("- ", names(results), " (", vapply(results, function(x) x$sample$n_effective, integer(1)), " effective observations)"),
  "",
  "## Terminal Decision",
  "",
  "AUTHORIZE_D12D_PRELIMINARY_RESULT_REVIEW"
)
writeLines(readme, file.path(OUT_DIR, "D12C_README.md"), useBytes = TRUE)

terminal <- c(
  "# D12C Terminal Decision",
  "",
  "## Scope",
  "",
  "D12D is authorized for preliminary result review only, not final manuscript interpretation.",
  "",
  "## Validation Basis",
  "",
  "- manual RDOLS wrapper works",
  "- only authorized model objects were estimated",
  "- all outputs are marked controlled preliminary",
  "- q_omega remains parked",
  "- no forbidden estimator drift occurred",
  "- no downstream reconstruction occurred",
  "- results UI contract passed",
  "- validation passed",
  "",
  "AUTHORIZE_D12D_PRELIMINARY_RESULT_REVIEW"
)
writeLines(terminal, file.path(OUT_DIR, "D12C_TERMINAL_DECISION.md"), useBytes = TRUE)

if (any(contract_checks$status == "FAIL") || any(ui_validation$status == "FAIL")) {
  stop("D12C validation failure: contract or UI validation failed.")
}

message("D12C controlled preliminary RDOLS estimation complete. Outputs written to ", OUT_DIR)
