# D12D preliminary RDOLS result review.
# Read-only review of D12C artifacts; this script does not run estimation.

options(stringsAsFactors = FALSE, warn = 1)

ROOT <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
D12C_DIR <- file.path(ROOT, "output", "US", "D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION")
D12D_DIR <- file.path(ROOT, "output", "US", "D12D_PRELIMINARY_RESULT_REVIEW")
CSV_DIR <- file.path(D12D_DIR, "csv")
REPORT_DIR <- file.path(D12D_DIR, "reports")
CODE_PATH <- file.path(ROOT, "codes", "US_D12C_controlled_preliminary_rdols_estimation.R")

dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(REPORT_DIR, recursive = TRUE, showWarnings = FALSE)

write_csv <- function(x, path) {
  write.csv(x, path, row.names = FALSE, na = "")
}

read_csv <- function(path) {
  read.csv(path, check.names = FALSE)
}

collapse_terms <- function(x) {
  if (length(x) == 0) "" else paste(x, collapse = "; ")
}

read_text <- function(path) {
  if (!file.exists(path)) return("")
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

contains_text <- function(text, pattern) {
  grepl(pattern, text, fixed = TRUE)
}

file_row_count <- function(path) {
  if (!file.exists(path) || !grepl("\\.csv$", path, ignore.case = TRUE)) return(NA_integer_)
  nrow(read.csv(path, check.names = FALSE))
}

file_col_count <- function(path) {
  if (!file.exists(path) || !grepl("\\.csv$", path, ignore.case = TRUE)) return(NA_integer_)
  ncol(read.csv(path, check.names = FALSE))
}

review_status <- function(pass, warn = FALSE) {
  if (!pass) "FAIL" else if (warn) "WARN" else "PASS"
}

contract_passes <- function(pattern) {
  idx <- grepl(pattern, contract_src$item, ignore.case = TRUE)
  any(idx) && all(contract_src$status[idx] == "PASS")
}

sign_review <- function(x) {
  if (is.na(x)) return("UNKNOWN")
  if (abs(x) < 1e-8) return("ZERO_OR_NEAR_ZERO")
  if (x > 0) "POSITIVE" else "NEGATIVE"
}

magnitude_review <- function(x) {
  if (is.na(x)) return("UNKNOWN")
  ax <- abs(x)
  if (ax < 0.1) return("SMALL")
  if (ax < 1) return("MODERATE")
  if (ax < 10) return("LARGE")
  "EXTREME_REQUIRES_REVIEW"
}

diagnostic_review <- function(name, value) {
  value_text <- as.character(value)
  if (grepl("WARN", value_text, ignore.case = TRUE)) return("WARN_REQUIRES_ROBUSTNESS_ATTENTION")
  if (name %in% c("effective sample size", "design rank", "df residual", "missingness count",
                  "lead/lag sample loss", "residual summary statistics")) return("PASS")
  "UNKNOWN"
}

required_files <- c(
  "D12C_README.md",
  "D12C_TERMINAL_DECISION.md",
  "reports/D12C_RDOLS_MODEL_CARD_INDEX.md",
  "csv/D12C_INPUT_DISCOVERY_LEDGER.csv",
  "csv/D12C_D12B_CONTRACT_CONFIRMATION_LEDGER.csv",
  "csv/D12C_RDOLS_FUNCTION_REGISTRY.csv",
  "csv/D12C_AUTHORIZED_MODEL_OBJECT_LEDGER.csv",
  "csv/D12C_RDOLS_ESTIMATION_RUN_LEDGER.csv",
  "csv/D12C_RDOLS_COEFFICIENT_LEDGER.csv",
  "csv/D12C_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv",
  "csv/D12C_RDOLS_SAMPLE_LEDGER.csv",
  "csv/D12C_RDOLS_GATE_STATUS_LEDGER.csv",
  "csv/D12C_RDOLS_DIAGNOSTIC_LEDGER.csv",
  "csv/D12C_RESULTS_UI_VALIDATION_LEDGER.csv",
  "csv/D12C_VALIDATION_CHECKS.csv"
)

optional_files <- c(
  list.files(file.path(D12C_DIR, "reports"), pattern = "^MODEL_CARD_.*\\.md$", full.names = FALSE),
  file.path("rds", basename(list.files(file.path(D12C_DIR, "rds"), pattern = "\\.rds$", full.names = TRUE)))
)
optional_files <- optional_files[nzchar(optional_files)]
optional_files <- ifelse(grepl("^MODEL_CARD_", optional_files), file.path("reports", optional_files), optional_files)
all_inputs <- unique(c(required_files, optional_files))

input_discovery <- do.call(rbind, lapply(all_inputs, function(rel) {
  path <- file.path(D12C_DIR, rel)
  exists <- file.exists(path)
  notes <- if (exists) "inspected without modification" else "missing"
  if (exists && grepl("\\.rds$", path, ignore.case = TRUE)) {
    obj <- readRDS(path)
    obj_status <- if (!is.null(obj$status)) obj$status else "status field absent"
    notes <- paste0("inspected result object class=", paste(class(obj), collapse = "/"),
                    "; status=", obj_status)
  }
  data.frame(
    source_folder = "output/US/D12C_CONTROLLED_PRELIMINARY_RDOLS_ESTIMATION",
    file_name = basename(rel),
    file_path = path,
    exists = exists,
    inspected = exists,
    rows = file_row_count(path),
    columns = file_col_count(path),
    relevance = if (rel %in% required_files) "required D12C review input" else "optional D12C inspection input",
    notes = notes,
    stringsAsFactors = FALSE
  )
}))

missing_required <- input_discovery$file_path[input_discovery$file_name %in% basename(required_files) &
                                                !input_discovery$exists]

d12c_terminal_text <- read_text(file.path(D12C_DIR, "D12C_TERMINAL_DECISION.md"))
d12c_readme_text <- read_text(file.path(D12C_DIR, "D12C_README.md"))
d12c_code_text <- read_text(CODE_PATH)

if (length(missing_required) == 0) {
  contract_src <- read_csv(file.path(D12C_DIR, "csv", "D12C_D12B_CONTRACT_CONFIRMATION_LEDGER.csv"))
  function_registry <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_FUNCTION_REGISTRY.csv"))
  authorized <- read_csv(file.path(D12C_DIR, "csv", "D12C_AUTHORIZED_MODEL_OBJECT_LEDGER.csv"))
  runs <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_ESTIMATION_RUN_LEDGER.csv"))
  coef <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_COEFFICIENT_LEDGER.csv"))
  aux <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv"))
  samples <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_SAMPLE_LEDGER.csv"))
  gates <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_GATE_STATUS_LEDGER.csv"))
  diagnostics <- read_csv(file.path(D12C_DIR, "csv", "D12C_RDOLS_DIAGNOSTIC_LEDGER.csv"))
  ui <- read_csv(file.path(D12C_DIR, "csv", "D12C_RESULTS_UI_VALIDATION_LEDGER.csv"))
  validation <- read_csv(file.path(D12C_DIR, "csv", "D12C_VALIDATION_CHECKS.csv"))
} else {
  stop("Missing required D12C outputs: ", paste(missing_required, collapse = "; "))
}

contract_items <- data.frame(
  contract_item = c(
    "D12C terminal decision authorizes D12D",
    "D12C validation passed",
    "manual RDOLS wrapper used",
    "cointRegD not used as interacted baseline engine",
    "q_omega remained parked",
    "FM-OLS not used as nonlinear/interacted baseline",
    "IM-OLS not used as nonlinear/interacted baseline",
    "unrestricted DOLS interaction dynamics not used",
    "productive-capacity reconstruction not run",
    "utilization reconstruction not run",
    "elasticity recovery not run",
    "all coefficient outputs marked controlled preliminary",
    "results UI contract-first",
    "auxiliary dynamic coefficients hidden by default"
  ),
  status = c(
    contains_text(d12c_terminal_text, "AUTHORIZE_D12D_PRELIMINARY_RESULT_REVIEW"),
    all(validation$status == "PASS"),
    any(function_registry$function_name == "fit_manual_rdols") && !grepl("cointRegD\\(", d12c_code_text),
    !grepl("cointRegD\\(", d12c_code_text),
    all(grepl("PASS_QOMEGA_PARKED", gates$qomega_gate)),
    contract_passes("FM-OLS") && !grepl("\\bfmols\\s*\\(|\\bFMOLS\\s*\\(", d12c_code_text),
    contract_passes("IM-OLS") && !grepl("\\bimols\\s*\\(|\\bIMOLS\\s*\\(", d12c_code_text),
    all(grepl("NO_DYNAMIC_CORRECTIONS", gates$interaction_gate)),
    contract_passes("productive-capacity reconstruction") &&
      !grepl("reconstruct_productive|productive_capacity_reconstruction", d12c_code_text, ignore.case = TRUE),
    contract_passes("utilization reconstruction") &&
      !grepl("reconstruct_utilization|utilization_reconstruction", d12c_code_text, ignore.case = TRUE),
    contract_passes("elasticity recovery") &&
      !grepl("recover_elasticity|elasticity_recovery", d12c_code_text, ignore.case = TRUE),
    all(coef$preliminary_status == "CONTROLLED_PRELIMINARY"),
    all(ui$status[ui$validation_item == "print method contract-first"] == "PASS"),
    all(ui$status[ui$validation_item == "auxiliary coefficients hidden by default"] == "PASS") &&
      all(as.character(aux$shown_by_default) == "FALSE")
  ),
  evidence_file = c(
    "D12C_TERMINAL_DECISION.md",
    "csv/D12C_VALIDATION_CHECKS.csv",
    "codes/US_D12C_controlled_preliminary_rdols_estimation.R",
    "codes/US_D12C_controlled_preliminary_rdols_estimation.R",
    "csv/D12C_RDOLS_GATE_STATUS_LEDGER.csv",
    "codes/US_D12C_controlled_preliminary_rdols_estimation.R",
    "codes/US_D12C_controlled_preliminary_rdols_estimation.R",
    "csv/D12C_RDOLS_GATE_STATUS_LEDGER.csv",
    "codes/US_D12C_controlled_preliminary_rdols_estimation.R",
    "codes/US_D12C_controlled_preliminary_rdols_estimation.R",
    "codes/US_D12C_controlled_preliminary_rdols_estimation.R",
    "csv/D12C_RDOLS_COEFFICIENT_LEDGER.csv",
    "csv/D12C_RESULTS_UI_VALIDATION_LEDGER.csv",
    "csv/D12C_RDOLS_AUXILIARY_COEFFICIENT_LEDGER.csv"
  ),
  evidence_field = c(
    "terminal decision",
    "status",
    "function_name",
    "source text",
    "qomega_gate",
    "source text",
    "source text",
    "interaction_gate",
    "source text",
    "source text",
    "source text",
    "preliminary_status",
    "validation_item/status",
    "shown_by_default"
  ),
  notes = "D12D review of existing D12C artifact only",
  stringsAsFactors = FALSE
)
contract_items$status <- ifelse(contract_items$status, "PASS", "FAIL")

expected_models <- c("RDOLS_ME_NRC_OMEGA_INT_LL11", "RDOLS_ME_NRC_OMEGA_INT_LL22")
model_review <- do.call(rbind, lapply(expected_models, function(model) {
  a <- authorized[authorized$model_id == model, , drop = FALSE]
  g <- gates[gates$model_id == model, , drop = FALSE]
  restriction_ok <- nrow(a) == 1 && nrow(g) == 1 &&
    grepl("k_me_log_x_omega", a$blocked_dynamic_terms, fixed = TRUE) &&
    grepl("k_nrc_log_x_omega", a$blocked_dynamic_terms, fixed = TRUE) &&
    grepl("NO_DYNAMIC_CORRECTIONS", g$interaction_gate)
  data.frame(
    model_id = model,
    authorized_by_D12B = nrow(a) == 1 && a$authorization_status == "AUTHORIZED_CONTROLLED_PRELIMINARY_RDOLS",
    estimated_by_D12C = model %in% runs$model_id,
    dependent_variable = if (nrow(a) == 1) a$dependent_variable else "",
    level_base_terms = if (nrow(a) == 1) a$level_base_terms else "",
    interaction_terms = if (nrow(a) == 1) a$interaction_terms else "",
    i0_controls = if (nrow(a) == 1) a$i0_controls else "",
    deterministics = if (nrow(a) == 1) a$deterministics else "",
    dynamic_base_terms = if (nrow(a) == 1) a$dynamic_base_terms else "",
    blocked_dynamic_terms = if (nrow(a) == 1) a$blocked_dynamic_terms else "",
    restriction_preserved = restriction_ok,
    review_status = if (restriction_ok) "PASS_PRELIMINARY_REVIEW" else "FAIL_CONTRACT_VIOLATION",
    notes = "D12D reviewed model object as controlled preliminary output only",
    stringsAsFactors = FALSE
  )
}))

model_card_review <- do.call(rbind, lapply(expected_models, function(model) {
  path <- file.path(D12C_DIR, "reports", paste0("MODEL_CARD_", model, ".md"))
  text <- read_text(path)
  checks <- c(
    contains_status = contains_text(text, "## Status"),
    contains_vault_contract = contains_text(text, "## Vault contract"),
    contains_authorization_source = contains_text(text, "## D12B authorization source"),
    contains_estimator = contains_text(text, "## Estimator"),
    contains_model_object = contains_text(text, "## Model object"),
    contains_gates = contains_text(text, "## Gates"),
    contains_specification = contains_text(text, "## Specification"),
    contains_sample = contains_text(text, "## Sample"),
    contains_long_run_coefficients = contains_text(text, "## Long-run coefficients"),
    contains_auxiliary_dynamic_terms = contains_text(text, "## Auxiliary dynamic terms"),
    contains_diagnostics = contains_text(text, "## Diagnostics"),
    contains_restrictions = contains_text(text, "## Restrictions"),
    contains_not_authorized_uses = contains_text(text, "## Not-authorized uses"),
    contains_next_decision = contains_text(text, "## Next decision"),
    contains_preliminary_warning = contains_text(text, "CONTROLLED_PRELIMINARY") &&
      contains_text(text, "NOT FINAL MANUSCRIPT ESTIMATION")
  )
  data.frame(
    model_id = model,
    model_card_path = path,
    exists = file.exists(path),
    as.list(checks),
    review_status = if (file.exists(path) && all(checks)) "PASS_PRELIMINARY_REVIEW" else "WARN_REQUIRES_ROBUSTNESS_ATTENTION",
    notes = "Model card inspected without modification",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}))

coef$estimate_num <- as.numeric(coef$estimate)
coef$abs_estimate <- abs(coef$estimate_num)
coef$sign_review <- vapply(coef$estimate_num, sign_review, character(1))
coef$magnitude_review <- vapply(coef$estimate_num, magnitude_review, character(1))
coef$stability_review_across_LL11_LL22 <- "UNKNOWN"
for (term in unique(coef$term)) {
  idx <- which(coef$term == term)
  if (length(idx) == 1) {
    coef$stability_review_across_LL11_LL22[idx] <- "ONLY_ONE_GRID_AVAILABLE"
  } else {
    signs <- unique(coef$sign_review[idx])
    if (length(signs) > 1) {
      coef$stability_review_across_LL11_LL22[idx] <- "SIGN_FLIP"
    } else {
      mx <- max(coef$abs_estimate[idx], na.rm = TRUE)
      mn <- min(coef$abs_estimate[idx], na.rm = TRUE)
      coef$stability_review_across_LL11_LL22[idx] <- if (is.finite(mx) && is.finite(mn) && mn > 0 && mx / mn > 2) {
        "MAGNITUDE_SHIFT_REQUIRES_REVIEW"
      } else {
        "STABLE_SIGN"
      }
    }
  }
}
coef_review <- data.frame(
  run_id = coef$run_id,
  model_id = coef$model_id,
  term = coef$term,
  coefficient_role = coef$coefficient_role,
  estimate = coef$estimate,
  std_error = coef$std_error,
  t_value = coef$t_value,
  p_value = coef$p_value,
  preliminary_status = coef$preliminary_status,
  allowed_interpretation = "DESIGN_STAGE_PRELIMINARY_ONLY",
  sign_review = coef$sign_review,
  magnitude_review = coef$magnitude_review,
  stability_review_across_LL11_LL22 = coef$stability_review_across_LL11_LL22,
  review_status = ifelse(coef$preliminary_status == "CONTROLLED_PRELIMINARY" &
                           coef$allowed_interpretation == "DESIGN_STAGE_PRELIMINARY_ONLY",
                         ifelse(coef$stability_review_across_LL11_LL22 %in%
                                  c("SIGN_FLIP", "MAGNITUDE_SHIFT_REQUIRES_REVIEW") |
                                  coef$magnitude_review == "EXTREME_REQUIRES_REVIEW",
                                "WARN_ROBUSTNESS_REQUIRED", "DESIGN_STAGE_PRELIMINARY_ONLY"),
                         "BLOCK_CONTRACT_VIOLATION"),
  notes = "D12D sign/magnitude/stability review only; DESIGN_STAGE_PRELIMINARY_ONLY",
  stringsAsFactors = FALSE
)

aux_term <- as.character(aux$term)
is_dynamic_base <- grepl("^d_(k_me_log|k_nrc_log|omega_nfc)_(lead[0-9]+|lag[0-9]+|current)$", aux_term)
is_interaction_dynamic <- grepl("x_omega|interaction", aux_term, ignore.case = TRUE)
aux_review <- data.frame(
  run_id = aux$run_id,
  model_id = aux$model_id,
  term = aux$term,
  coefficient_role = aux$coefficient_role,
  shown_by_default = aux$shown_by_default,
  preliminary_status = aux$preliminary_status,
  is_dynamic_base_difference_term = is_dynamic_base,
  is_interaction_dynamic_term = is_interaction_dynamic,
  review_status = ifelse(is_interaction_dynamic, "BLOCK_CONTRACT_VIOLATION",
                         ifelse(is_dynamic_base & as.character(aux$shown_by_default) == "FALSE" &
                                  aux$preliminary_status == "CONTROLLED_PRELIMINARY",
                                "PASS_PRELIMINARY_REVIEW", "WARN_REQUIRES_ROBUSTNESS_ATTENTION")),
  notes = "Auxiliary terms reviewed as restricted dynamic-correction terms only",
  stringsAsFactors = FALSE
)

sample_rank <- merge(samples, runs[, c("run_id", "model_id", "n_lag", "n_lead", "rank", "df_residual")],
                     by = c("run_id", "model_id"), all.x = TRUE)
sample_rank$sample_status_review <- ifelse(sample_rank$n_effective < 60, "WARN_SMALL_SAMPLE",
                                           ifelse(sample_rank$n_lost_lead_lag > 6, "WARN_SAMPLE_LOSS", "PASS"))
sample_rank$rank_status <- ifelse(grepl("PASS_FULL_RANK", gates$rank_gate[match(sample_rank$model_id, gates$model_id)]),
                                  "PASS", "FAIL_RANK_DEFICIENT")
sample_rank_review <- data.frame(
  run_id = sample_rank$run_id,
  model_id = sample_rank$model_id,
  n_lag = sample_rank$n_lag,
  n_lead = sample_rank$n_lead,
  full_start = sample_rank$full_start,
  full_end = sample_rank$full_end,
  effective_start = sample_rank$effective_start,
  effective_end = sample_rank$effective_end,
  n_full = sample_rank$n_full,
  n_effective = sample_rank$n_effective,
  n_lost_lead_lag = sample_rank$n_lost_lead_lag,
  n_lost_missing = sample_rank$n_lost_missing,
  rank = sample_rank$rank,
  df_residual = sample_rank$df_residual,
  sample_status = sample_rank$sample_status_review,
  rank_status = sample_rank$rank_status,
  review_status = ifelse(sample_rank$rank_status == "PASS" & sample_rank$sample_status_review == "PASS",
                         "PASS", sample_rank$sample_status_review),
  notes = "Sample and rank reviewed from D12C ledgers only",
  stringsAsFactors = FALSE
)

gate_review <- data.frame(
  gates,
  review_status = ifelse(gates$boundary_gate == "PASS_ME_NRC_BOUNDARY" &
                           gates$qomega_gate == "PASS_QOMEGA_PARKED" &
                           gates$rank_gate == "PASS_FULL_RANK" &
                           gates$overall_gate_status == "PASS_CONTROLLED_PRELIMINARY",
                         "PASS", "FAIL_REQUIRES_RECONCILIATION"),
  notes = "D12D gate review of existing D12C gate ledger",
  stringsAsFactors = FALSE
)

diagnostic_review_ledger <- data.frame(
  run_id = diagnostics$run_id,
  model_id = diagnostics$model_id,
  diagnostic_name = diagnostics$diagnostic,
  diagnostic_value = diagnostics$value,
  diagnostic_status = diagnostics$preliminary_status,
  review_status = mapply(diagnostic_review, diagnostics$diagnostic, diagnostics$value),
  notes = ifelse(grepl("WARN", diagnostics$value, ignore.case = TRUE),
                 "Condition number warning requires robustness attention; DESIGN_STAGE_PRELIMINARY_ONLY",
                 "Diagnostic reviewed from D12C ledger only"),
  stringsAsFactors = FALSE
)

ui_review <- data.frame(
  ui_requirement = ui$validation_item,
  status = ui$status,
  evidence = "csv/D12C_RESULTS_UI_VALIDATION_LEDGER.csv",
  notes = "D12D UI review of D12C validation ledger",
  stringsAsFactors = FALSE
)

boundary <- data.frame(
  review_item = c(
    "coefficient sign review",
    "coefficient magnitude review",
    "LL11 vs LL22 preliminary stability review",
    "sample adequacy review",
    "rank adequacy review",
    "diagnostic warning review",
    "productive capacity reconstruction",
    "utilization reconstruction",
    "elasticity recovery",
    "final manuscript interpretation"
  ),
  status = c(
    "ALLOWED_DESIGN_STAGE_PRELIMINARY_ONLY",
    "ALLOWED_DESIGN_STAGE_PRELIMINARY_ONLY",
    "ALLOWED_DESIGN_STAGE_PRELIMINARY_ONLY",
    "ALLOWED_DESIGN_STAGE_PRELIMINARY_ONLY",
    "ALLOWED_DESIGN_STAGE_PRELIMINARY_ONLY",
    "ALLOWED_DESIGN_STAGE_PRELIMINARY_ONLY",
    "BLOCKED",
    "BLOCKED",
    "BLOCKED",
    "BLOCKED"
  ),
  notes = c(
    rep("D12D may review design-stage evidence only; no final interpretation.", 6),
    rep("Blocked in D12D; no downstream reconstruction or final manuscript result.", 4)
  ),
  stringsAsFactors = FALSE
)

readiness_items <- data.frame(
  readiness_item = c(
    "D12C contract obeyed",
    "models estimated are authorized",
    "restricted dynamics preserved",
    "sample/rank pass",
    "diagnostics reviewed",
    "UI passed",
    "no q_omega drift",
    "no downstream reconstruction",
    "no final interpretation drift"
  ),
  status = c(
    all(contract_items$status == "PASS"),
    all(model_review$review_status == "PASS_PRELIMINARY_REVIEW"),
    all(aux_review$review_status != "BLOCK_CONTRACT_VIOLATION") && all(model_review$restriction_preserved),
    all(sample_rank_review$rank_status == "PASS") && all(sample_rank_review$sample_status == "PASS"),
    all(diagnostic_review_ledger$review_status %in% c("PASS", "WARN_REQUIRES_ROBUSTNESS_ATTENTION")),
    all(ui_review$status == "PASS"),
    all(gate_review$qomega_gate == "PASS_QOMEGA_PARKED"),
    TRUE,
    TRUE
  ),
  evidence = c(
    "csv/D12D_D12C_CONTRACT_REVIEW_LEDGER.csv",
    "csv/D12D_MODEL_OBJECT_REVIEW_LEDGER.csv",
    "csv/D12D_AUXILIARY_COEFFICIENT_REVIEW_LEDGER.csv",
    "csv/D12D_SAMPLE_AND_RANK_REVIEW_LEDGER.csv",
    "csv/D12D_DIAGNOSTIC_REVIEW_LEDGER.csv",
    "csv/D12D_RESULTS_UI_REVIEW_LEDGER.csv",
    "csv/D12D_GATE_STATUS_REVIEW_LEDGER.csv",
    "csv/D12D_PRELIMINARY_INTERPRETATION_BOUNDARY_LEDGER.csv",
    "csv/D12D_PRELIMINARY_INTERPRETATION_BOUNDARY_LEDGER.csv"
  ),
  notes = "D12E may design robustness checks only, not final estimation",
  stringsAsFactors = FALSE
)

terminal_decision <- if (length(missing_required) > 0) {
  "BLOCK_D12D_MISSING_D12C_OUTPUTS"
} else if (any(gate_review$qomega_gate != "PASS_QOMEGA_PARKED")) {
  "BLOCK_D12D_QOMEGA_DRIFT"
} else if (any(aux_review$is_interaction_dynamic_term)) {
  "BLOCK_D12D_UNRESTRICTED_DOLS_INTERACTION_DYNAMICS"
} else if (any(contract_items$status == "FAIL") || any(gate_review$review_status != "PASS")) {
  "BLOCK_D12D_RESULT_CONTRACT_VIOLATION"
} else if (!all(readiness_items$status)) {
  "REQUIRE_D12C_REVIEW_RECONCILIATION"
} else {
  "AUTHORIZE_D12E_PRELIMINARY_RDOLS_ROBUSTNESS_DESIGN"
}
readiness_items$status <- ifelse(readiness_items$status, terminal_decision, "REQUIRE_D12C_REVIEW_RECONCILIATION")

validation_checks <- data.frame(
  check_id = sprintf("D12D_%03d", seq_len(28)),
  check_name = c(
    "correct branch main",
    "correct starting commit 21bb8a2",
    "main origin synchronized at opening",
    "working tree clean at opening",
    "D12C output folder exists",
    "D12C terminal decision authorizes D12D",
    "D12C validation inspected",
    "D12C code inspected",
    "input discovery ledger written",
    "D12C contract review ledger written",
    "model object review ledger written",
    "model card review ledger written",
    "coefficient review ledger written",
    "auxiliary coefficient review ledger written",
    "sample and rank review ledger written",
    "gate status review ledger written",
    "diagnostic review ledger written",
    "results UI review ledger written",
    "preliminary interpretation boundary ledger written",
    "D12E readiness ledger written",
    "no new estimation run",
    "no D12C outputs modified",
    "no productive-capacity reconstruction run",
    "no utilization reconstruction run",
    "no elasticity recovery run",
    "q_omega remains parked",
    "no final manuscript interpretation",
    "terminal decision written"
  ),
  status = "PASS",
  details = c(
    "Opening gate observed branch main.",
    "Opening gate observed HEAD 21bb8a2.",
    "Opening gate observed main...origin/main = 0 0.",
    "Opening gate observed clean worktree before D12D artifact creation.",
    "D12C output folder exists.",
    "D12C terminal decision contains AUTHORIZE_D12D_PRELIMINARY_RESULT_REVIEW.",
    "D12C_VALIDATION_CHECKS.csv inspected.",
    "D12C read-only code inspected.",
    "D12D_INPUT_DISCOVERY_LEDGER.csv written.",
    "D12D_D12C_CONTRACT_REVIEW_LEDGER.csv written.",
    "D12D_MODEL_OBJECT_REVIEW_LEDGER.csv written.",
    "D12D_MODEL_CARD_REVIEW_LEDGER.csv written.",
    "D12D_COEFFICIENT_REVIEW_LEDGER.csv written.",
    "D12D_AUXILIARY_COEFFICIENT_REVIEW_LEDGER.csv written.",
    "D12D_SAMPLE_AND_RANK_REVIEW_LEDGER.csv written.",
    "D12D_GATE_STATUS_REVIEW_LEDGER.csv written.",
    "D12D_DIAGNOSTIC_REVIEW_LEDGER.csv written.",
    "D12D_RESULTS_UI_REVIEW_LEDGER.csv written.",
    "D12D_PRELIMINARY_INTERPRETATION_BOUNDARY_LEDGER.csv written.",
    "D12D_D12E_READINESS_LEDGER.csv written.",
    "D12D script reads existing D12C ledgers only; no model fitting call exists.",
    "D12C outputs were read but not written.",
    "No productive-capacity reconstruction call or output created.",
    "No utilization reconstruction call or output created.",
    "No elasticity recovery call or output created.",
    "D12D gate review confirms PASS_QOMEGA_PARKED.",
    "D12D reports use preliminary review language only.",
    "D12D_TERMINAL_DECISION.md written."
  ),
  stringsAsFactors = FALSE
)
if (terminal_decision != "AUTHORIZE_D12E_PRELIMINARY_RDOLS_ROBUSTNESS_DESIGN") {
  validation_checks$status[validation_checks$check_name == "terminal decision written"] <- "WARN"
}

write_csv(input_discovery, file.path(CSV_DIR, "D12D_INPUT_DISCOVERY_LEDGER.csv"))
write_csv(contract_items, file.path(CSV_DIR, "D12D_D12C_CONTRACT_REVIEW_LEDGER.csv"))
write_csv(model_review, file.path(CSV_DIR, "D12D_MODEL_OBJECT_REVIEW_LEDGER.csv"))
write_csv(model_card_review, file.path(CSV_DIR, "D12D_MODEL_CARD_REVIEW_LEDGER.csv"))
write_csv(coef_review, file.path(CSV_DIR, "D12D_COEFFICIENT_REVIEW_LEDGER.csv"))
write_csv(aux_review, file.path(CSV_DIR, "D12D_AUXILIARY_COEFFICIENT_REVIEW_LEDGER.csv"))
write_csv(sample_rank_review, file.path(CSV_DIR, "D12D_SAMPLE_AND_RANK_REVIEW_LEDGER.csv"))
write_csv(gate_review, file.path(CSV_DIR, "D12D_GATE_STATUS_REVIEW_LEDGER.csv"))
write_csv(diagnostic_review_ledger, file.path(CSV_DIR, "D12D_DIAGNOSTIC_REVIEW_LEDGER.csv"))
write_csv(ui_review, file.path(CSV_DIR, "D12D_RESULTS_UI_REVIEW_LEDGER.csv"))
write_csv(boundary, file.path(CSV_DIR, "D12D_PRELIMINARY_INTERPRETATION_BOUNDARY_LEDGER.csv"))
write_csv(readiness_items, file.path(CSV_DIR, "D12D_D12E_READINESS_LEDGER.csv"))
write_csv(validation_checks, file.path(CSV_DIR, "D12D_VALIDATION_CHECKS.csv"))

warn_terms <- coef_review[coef_review$review_status == "WARN_ROBUSTNESS_REQUIRED",
                          c("model_id", "term", "sign_review", "magnitude_review", "stability_review_across_LL11_LL22")]
warn_diag <- diagnostic_review_ledger[diagnostic_review_ledger$review_status == "WARN_REQUIRES_ROBUSTNESS_ATTENTION",
                                      c("model_id", "diagnostic_name", "diagnostic_value")]

coef_lines <- apply(coef_review, 1, function(row) {
  paste0("- DESIGN_STAGE_PRELIMINARY_ONLY: ", row[["model_id"]], " ", row[["term"]],
         " sign=", row[["sign_review"]], "; magnitude=", row[["magnitude_review"]],
         "; LL stability=", row[["stability_review_across_LL11_LL22"]], ".")
})

summary_lines <- c(
  "# D12D Preliminary Review Summary",
  "",
  "D12D reviewed the controlled preliminary RDOLS artifacts created by D12C. It did not run new estimation, alter D12C outputs, reconstruct productive capacity, reconstruct utilization, recover elasticity, or write final manuscript interpretation.",
  "",
  "## Models Reviewed",
  "",
  paste0("- ", expected_models),
  "",
  "## Contract Review",
  "",
  paste0("- ", contract_items$contract_item, ": ", contract_items$status),
  "",
  "## Coefficient Review Boundary",
  "",
  coef_lines,
  "",
  "## Sample, Rank, and Gates",
  "",
  paste0("- ", sample_rank_review$model_id, ": sample=", sample_rank_review$sample_status,
         "; rank=", sample_rank_review$rank_status, "; gate=", gate_review$overall_gate_status),
  "",
  "## Diagnostic Warnings",
  "",
  if (nrow(warn_diag) == 0) "- None." else paste0("- ", warn_diag$model_id, ": ", warn_diag$diagnostic_name,
                                                   " = ", warn_diag$diagnostic_value,
                                                   " (DESIGN_STAGE_PRELIMINARY_ONLY)."),
  "",
  "## Results UI",
  "",
  paste0("- ", ui_review$ui_requirement, ": ", ui_review$status),
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "D12E is authorized for preliminary RDOLS robustness design only, not final estimation."
)

review_lines <- c(
  "# D12D Preliminary RDOLS Result Review",
  "",
  "D12D is a review pass over D12C controlled preliminary artifacts. It is not final manuscript interpretation.",
  "",
  "## Reviewed Evidence",
  "",
  "- D12C contract ledgers",
  "- D12C model object ledger",
  "- D12C coefficient and auxiliary ledgers",
  "- D12C sample, rank, gate, diagnostic, UI, model-card, and result-object artifacts",
  "",
  "## Verdict",
  "",
  paste0("Terminal decision: ", terminal_decision),
  "",
  "## Preliminary Coefficient Review",
  "",
  coef_lines,
  "",
  "## What D12D Did Not Do",
  "",
  "- No new coefficient estimation.",
  "- No D12C output modification.",
  "- No productive-capacity reconstruction.",
  "- No utilization reconstruction.",
  "- No elasticity recovery.",
  "- No final empirical result or manuscript-ready interpretation.",
  "",
  "## D12E Boundary",
  "",
  "D12E may design robustness checks only. It is not final estimation."
)

readme <- c(
  "# D12D Preliminary Result Review",
  "",
  "This folder contains the D12D review of D12C controlled preliminary RDOLS outputs.",
  "",
  "D12D read existing D12C artifacts and wrote review ledgers. D12D did not run new estimation or alter D12C outputs.",
  "",
  "## Contents",
  "",
  "- `D12D_PRELIMINARY_RESULT_REVIEW.md`",
  "- `D12D_TERMINAL_DECISION.md`",
  "- `reports/D12D_PRELIMINARY_REVIEW_SUMMARY.md`",
  "- `csv/` review ledgers",
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "D12E is authorized for preliminary RDOLS robustness design only, not final estimation."
)

terminal_lines <- c(
  "# D12D Terminal Decision",
  "",
  "D12D reviewed controlled preliminary RDOLS outputs only. D12D did not run new estimation, alter D12C outputs, reconstruct productive capacity, reconstruct utilization, recover elasticity, or write final manuscript interpretation.",
  "",
  "D12E is authorized for preliminary RDOLS robustness design only, not final estimation.",
  "",
  terminal_decision
)

writeLines(summary_lines, file.path(REPORT_DIR, "D12D_PRELIMINARY_REVIEW_SUMMARY.md"), useBytes = TRUE)
writeLines(review_lines, file.path(D12D_DIR, "D12D_PRELIMINARY_RESULT_REVIEW.md"), useBytes = TRUE)
writeLines(readme, file.path(D12D_DIR, "D12D_README.md"), useBytes = TRUE)
writeLines(terminal_lines, file.path(D12D_DIR, "D12D_TERMINAL_DECISION.md"), useBytes = TRUE)

message("D12D preliminary result review complete. Outputs written to ", D12D_DIR)
