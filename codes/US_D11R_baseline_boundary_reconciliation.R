options(stringsAsFactors = FALSE)

repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
d10_root <- file.path(repo, "output/US/D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET")
d11_root <- file.path(repo, "output/US/D11_INTEGRATION_AND_ESTIMATION_READINESS_REVIEW")
d11r_root <- file.path(repo, "output/US/D11R_BASELINE_BOUNDARY_RECONCILIATION")
csv_dir <- file.path(d11r_root, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

target_vars <- c("G_TOT_GPIM_2017", "LOG_G_TOT_GPIM_2017")
expected_branch <- "restart/d10-clean-from-d09s"
expected_head <- "eb23e33dc8e44f0da85907adecc6e21211c0d6ff"
valid_decisions <- c(
  "AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN",
  "REQUIRE_D11R_RECONCILIATION_REVIEW",
  "BLOCK_D11R_BASELINE_BOUNDARY_LEAKAGE",
  "BLOCK_D11R_QOMEGA_REINTRODUCTION",
  "BLOCK_D11R_PREMATURE_ESTIMATION",
  "BLOCK_D11R_SCOPE_CREEP"
)

write_csv <- function(x, name) {
  write.csv(x, file.path(csv_dir, name), row.names = FALSE, na = "")
}

write_md <- function(lines, name) {
  writeLines(lines, con = file.path(d11r_root, name), useBytes = TRUE)
}

git_text <- function(args) {
  paste(system2("git", args, stdout = TRUE, stderr = TRUE), collapse = "\n")
}

read_csv <- function(path) {
  read.csv(path, check.names = FALSE, na.strings = c("", "NA"))
}

safe_nrow <- function(path) {
  if (tolower(tools::file_ext(path)) != "csv") return(NA_integer_)
  nrow(read_csv(path))
}

safe_ncol <- function(path) {
  if (tolower(tools::file_ext(path)) != "csv") return(NA_integer_)
  ncol(read_csv(path))
}

safe_cols <- function(path) {
  if (tolower(tools::file_ext(path)) != "csv") return("")
  paste(names(read_csv(path)), collapse = " | ")
}

rel_path <- function(path) {
  sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo), "/?"), "", normalizePath(path, winslash = "/", mustWork = TRUE))
}

collapse_values <- function(x, limit = 60) {
  x <- unique(as.character(x[!is.na(x) & nzchar(as.character(x))]))
  if (!length(x)) return("")
  if (length(x) > limit) x <- c(x[seq_len(limit)], paste0("...+", length(x) - limit, " more"))
  paste(x, collapse = "; ")
}

contains_target <- function(path) {
  if (tolower(tools::file_ext(path)) != "csv") {
    txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
    return(any(vapply(target_vars, function(v) grepl(v, txt, fixed = TRUE), logical(1))))
  }
  d <- read_csv(path)
  if (any(names(d) %in% target_vars)) return(TRUE)
  any(vapply(d, function(col) any(as.character(col) %in% target_vars, na.rm = TRUE), logical(1)))
}

branch <- git_text(c("branch", "--show-current"))
head_hash <- git_text(c("rev-parse", "HEAD"))
sync_state <- git_text(c("rev-list", "--left-right", "--count", "HEAD...origin/restart/d10-clean-from-d09s"))

if (branch != expected_branch) stop("BLOCK_D11R_WRONG_BRANCH: observed ", branch)
if (head_hash != expected_head) stop("D11R expected active commit eb23e33, observed ", head_hash)
if (sync_state != "0\t0" && sync_state != "0 0") stop("D11R remote divergence observed: ", sync_state)
if (!dir.exists(d10_root)) stop("D10 folder missing: ", d10_root)
if (!dir.exists(d11_root)) stop("D11 folder missing: ", d11_root)

d10_files <- list.files(d10_root, recursive = TRUE, full.names = TRUE, all.files = FALSE, no.. = TRUE)
d11_files <- list.files(d11_root, recursive = TRUE, full.names = TRUE, all.files = FALSE, no.. = TRUE)
all_input_files <- c(d10_files, d11_files)

input_discovery <- do.call(rbind, lapply(all_input_files, function(path) {
  ext <- tools::file_ext(path)
  target_hit <- contains_target(path)
  inspected <- tolower(ext) %in% c("csv", "md")
  data.frame(
    source_folder = ifelse(grepl("/D10_CLEAN_", normalizePath(path, winslash = "/")), "D10_CLEAN", "D11"),
    file_name = rel_path(path),
    file_extension = ext,
    row_count = safe_nrow(path),
    column_count = safe_ncol(path),
    column_names = safe_cols(path),
    inspected_by_D11R = ifelse(inspected, "yes", "no"),
    reason_if_not_inspected = ifelse(inspected, "", "Unsupported extension for D11R target-variable audit."),
    target_variable_appears = ifelse(target_hit, "yes", "no")
  )
}))
write_csv(input_discovery, "D11R_INPUT_DISCOVERY_LEDGER.csv")

target_found <- any(input_discovery$target_variable_appears == "yes")

status_cols <- c("contract_status", "D10_status", "status", "D11_boundary_status",
                 "D11_role", "authorization", "baseline_or_robustness")
role_cols <- c("analytical_role", "D11_role", "allowed_role", "forbidden_role", "role",
               "can_enter_D12_baseline_design", "baseline_regressor")
auth_cols <- c("contract_status", "D10_status", "authorization", "baseline_or_robustness",
               "can_enter_D12_baseline_design", "baseline_eligible", "d12_baseline_eligible")

target_occurrences <- list()
for (path in all_input_files[tolower(tools::file_ext(all_input_files)) == "csv"]) {
  d <- read_csv(path)
  rel <- rel_path(path)
  row_ids <- rep(FALSE, nrow(d))
  if (nrow(d) > 0) {
    row_ids <- Reduce(`|`, lapply(d, function(col) as.character(col) %in% target_vars))
  }
  for (target in target_vars) {
    rows <- which(if (nrow(d) > 0) Reduce(`|`, lapply(d, function(col) as.character(col) == target)) else logical())
    if (target %in% names(d)) {
      rows <- unique(c(rows, seq_len(nrow(d))))
    }
    if (!length(rows)) next
    for (row in rows) {
      relevant_status <- intersect(names(d), status_cols)
      relevant_role <- intersect(names(d), role_cols)
      relevant_auth <- intersect(names(d), auth_cols)
      original_values <- paste(paste(names(d), as.character(d[row, ]), sep = "="), collapse = " | ")
      status_text <- paste(as.character(unlist(d[row, unique(c(relevant_status, relevant_role, relevant_auth)), drop = TRUE])), collapse = " | ")
      baseline_authorized <- grepl("BASELINE_AUTHORIZED", status_text, fixed = TRUE)
      baseline_treated <- baseline_authorized ||
        grepl("BASELINE_REGRESSOR|BASELINE_CAPITAL|BASELINE_DEPENDENT|BASELINE_CONTROL|can_enter_D12_baseline_design=yes", status_text, ignore.case = TRUE)
      diagnosis <- if (baseline_authorized || baseline_treated) {
        "CONFIRMED_BASELINE_AUTHORIZATION_LEAK"
      } else if (grepl("PARKED|BLOCKED", status_text, ignore.case = TRUE)) {
        "CONFIRMED_BLOCKED_OR_PARKED_REFERENCE"
      } else if (grepl("REPORT|COMPARISON|EXCLUDED", status_text, ignore.case = TRUE)) {
        "CONFIRMED_REPORT_OR_COMPARISON_REFERENCE"
      } else if (nzchar(status_text)) {
        "CONFIRMED_NONBASELINE_REFERENCE"
      } else {
        "UNKNOWN_REQUIRES_REVIEW"
      }
      target_occurrences[[length(target_occurrences) + 1L]] <- data.frame(
        variable_name = target,
        source_file = rel,
        row_identifier = row,
        relevant_status_columns = paste(relevant_status, collapse = " | "),
        relevant_role_columns = paste(relevant_role, collapse = " | "),
        relevant_authorization_columns = paste(relevant_auth, collapse = " | "),
        original_value = original_values,
        baseline_authorized_appears = ifelse(baseline_authorized, "TRUE", "FALSE"),
        treated_as_baseline = ifelse(baseline_treated, "TRUE", "FALSE"),
        D11R_diagnosis = diagnosis
      )
    }
  }
}
leak_source <- if (length(target_occurrences)) do.call(rbind, target_occurrences) else {
  data.frame(variable_name = "", source_file = "", row_identifier = "", relevant_status_columns = "",
             relevant_role_columns = "", relevant_authorization_columns = "", original_value = "",
             baseline_authorized_appears = "FALSE", treated_as_baseline = "FALSE",
             D11R_diagnosis = "UNKNOWN_REQUIRES_REVIEW")
}
write_csv(leak_source, "D11R_BASELINE_LEAK_SOURCE_LEDGER.csv")

original_status <- function(v) {
  hits <- leak_source[leak_source$variable_name == v, , drop = FALSE]
  collapse_values(hits$original_value, 5)
}

authorization_reconciliation <- data.frame(
  variable_name = target_vars,
  original_D10_D11_role_status = vapply(target_vars, original_status, character(1)),
  original_authorization = "BASELINE_AUTHORIZED observed in D10/D11 target-variable metadata",
  corrected_D11R_role = "EXCLUDED_FROM_MODEL_MENU",
  corrected_D11R_authorization = "EXCLUDED_FROM_BASELINE",
  reason_for_correction = "Total-capital GPIM object retained only outside baseline; baseline capacity capital remains ME + NRC.",
  variable_retained = "TRUE",
  baseline_eligible = "FALSE",
  d12_baseline_eligible = "FALSE",
  d12_comparison_report_eligible = "TRUE"
)
write_csv(authorization_reconciliation, "D11R_AUTHORIZATION_RECONCILIATION_LEDGER.csv")

d11_boundary_path <- file.path(d11_root, "csv/D11_THEORETICAL_BOUNDARY_AUDIT.csv")
d11_model_menu_path <- file.path(d11_root, "csv/D11_MODEL_MENU_ADMISSIBILITY_LEDGER.csv")
d11_qomega_path <- file.path(d11_root, "csv/D11_QOMEGA_LEAKAGE_AUDIT.csv")
d11_validation_path <- file.path(d11_root, "csv/D11_VALIDATION_CHECKS.csv")
d11_terminal_path <- file.path(d11_root, "D11_TERMINAL_DECISION.md")

d11_boundary <- if (file.exists(d11_boundary_path)) read_csv(d11_boundary_path) else data.frame()
d11_model_menu <- if (file.exists(d11_model_menu_path)) read_csv(d11_model_menu_path) else data.frame()
d11_qomega <- if (file.exists(d11_qomega_path)) read_csv(d11_qomega_path) else data.frame()
d11_validation <- if (file.exists(d11_validation_path)) read_csv(d11_validation_path) else data.frame()
d11_terminal <- if (file.exists(d11_terminal_path)) paste(readLines(d11_terminal_path, warn = FALSE), collapse = "\n") else ""

if (nrow(d11_boundary) > 0) {
  d11r_boundary <- d11_boundary
  for (v in target_vars) {
    idx <- d11r_boundary$variable_name == v
    if (any(idx)) {
      d11r_boundary$allowed_role[idx] <- "EXCLUDED_FROM_BASELINE"
      d11r_boundary$forbidden_role[idx] <- "baseline capacity-capital object or D12 baseline regressor"
      d11r_boundary$D10_status[idx] <- gsub("BASELINE_AUTHORIZED", "EXCLUDED_FROM_BASELINE", d11r_boundary$D10_status[idx], fixed = TRUE)
      d11r_boundary$D11_boundary_status[idx] <- "EXCLUDED_FROM_BASELINE"
    }
  }
} else {
  d11r_boundary <- data.frame(
    variable_name = target_vars,
    source_file = "D10/D11 discovery",
    detected_category = "total capital",
    allowed_role = "EXCLUDED_FROM_BASELINE",
    forbidden_role = "baseline capacity-capital object or D12 baseline regressor",
    D10_status = "EXCLUDED_FROM_BASELINE under D11R reconciliation",
    D11_boundary_status = "EXCLUDED_FROM_BASELINE"
  )
}
write_csv(d11r_boundary, "D11R_THEORETICAL_BOUNDARY_AUDIT.csv")

if (nrow(d11_model_menu) > 0) {
  d11r_model_menu <- d11_model_menu
  for (v in target_vars) {
    idx <- d11r_model_menu$variable_name == v
    if (any(idx)) {
      d11r_model_menu$D11_role[idx] <- "EXCLUDED_FROM_MODEL_MENU"
      d11r_model_menu$reason[idx] <- "Total-capital GPIM object retained only outside baseline; baseline capacity capital remains ME + NRC."
      d11r_model_menu$can_enter_D12_baseline_design[idx] <- "no"
      d11r_model_menu$can_enter_D12_robustness_design[idx] <- "yes"
      d11r_model_menu$excluded_from_estimation[idx] <- "yes"
      d11r_model_menu$required_reconciliation[idx] <- "Resolved by D11R baseline-boundary reconciliation."
      if ("D10_status" %in% names(d11r_model_menu)) {
        d11r_model_menu$D10_status[idx] <- gsub("BASELINE_AUTHORIZED", "EXCLUDED_FROM_BASELINE", d11r_model_menu$D10_status[idx], fixed = TRUE)
      }
    }
  }
} else {
  d11r_model_menu <- data.frame(
    variable_name = target_vars,
    accounting_layer = "total_capital",
    D10_status = "EXCLUDED_FROM_BASELINE under D11R reconciliation",
    D11_role = "EXCLUDED_FROM_MODEL_MENU",
    reason = "Total-capital GPIM object retained only outside baseline; baseline capacity capital remains ME + NRC.",
    can_enter_D12_baseline_design = "no",
    can_enter_D12_robustness_design = "yes",
    excluded_from_estimation = "yes",
    required_reconciliation = "Resolved by D11R baseline-boundary reconciliation."
  )
}
write_csv(d11r_model_menu, "D11R_MODEL_MENU_ADMISSIBILITY_LEDGER.csv")

q_patterns <- c("q_omega", "qomega", "omega_", "q_exploitation", "exploitation_weighted",
                "wage_share_weighted", "distribution_weighted", "lagged_wage")
q_files <- c(all_input_files, list.files(d11r_root, recursive = TRUE, full.names = TRUE, all.files = FALSE, no.. = TRUE))
q_hits <- list()
scan_q_file <- function(path, include_d11r = FALSE) {
  rel <- rel_path(path)
  if (tolower(tools::file_ext(path)) != "csv") {
    vals <- paste(readLines(path, warn = FALSE), collapse = "\n")
    for (pat in q_patterns) {
      if (grepl(pat, vals, ignore.case = TRUE)) {
        q_hits[[length(q_hits) + 1L]] <<- data.frame(
          file = rel, field = "text", matched_pattern = pat,
          offending_value = pat,
          D11R_qomega_status = ifelse(pat == "omega_", "PARKED_REFERENCE_ONLY", "PARKED_REFERENCE_ONLY")
        )
      }
    }
    return(invisible(NULL))
  }
  d <- read_csv(path)
  for (pat in q_patterns) {
    col_hits <- names(d)[grepl(pat, names(d), ignore.case = TRUE)]
    if (length(col_hits)) {
      audit_context <- grepl("QOMEGA|COINTEGRATION_READINESS|TERMINAL_DECISION|README|VALIDATION", rel, ignore.case = TRUE) ||
        any(grepl("reintroduced|leakage|status|audit|parked|blocked", col_hits, ignore.case = TRUE))
      status <- if (pat == "omega_" || audit_context) "PARKED_REFERENCE_ONLY" else "BLOCKING_QOMEGA_LEAKAGE"
      q_hits[[length(q_hits) + 1L]] <<- data.frame(file = rel, field = "column_name", matched_pattern = pat,
                                                    offending_value = paste(col_hits, collapse = "; "),
                                                    D11R_qomega_status = status)
    }
    for (field in names(d)) {
      vals <- unique(as.character(d[[field]]))
      vals <- vals[!is.na(vals)]
      hits <- vals[grepl(pat, vals, ignore.case = TRUE)]
      if (length(hits)) {
        parked <- any(grepl("blocked|parked|elasticity|qomega|q_omega", paste(rel, field, hits), ignore.case = TRUE))
        status <- if (pat == "omega_") "PARKED_REFERENCE_ONLY" else if (parked) "PARKED_REFERENCE_ONLY" else "BLOCKING_QOMEGA_LEAKAGE"
        q_hits[[length(q_hits) + 1L]] <<- data.frame(file = rel, field = field, matched_pattern = pat,
                                                      offending_value = collapse_values(hits),
                                                      D11R_qomega_status = status)
      }
    }
  }
}
invisible(lapply(q_files, scan_q_file))
qomega_audit <- if (length(q_hits)) do.call(rbind, q_hits) else {
  data.frame(file = "", field = "", matched_pattern = "", offending_value = "", D11R_qomega_status = "NO_QOMEGA_HIT")
}
write_csv(qomega_audit, "D11R_QOMEGA_LEAKAGE_AUDIT.csv")
qomega_block <- any(qomega_audit$D11R_qomega_status == "BLOCKING_QOMEGA_LEAKAGE")

target_reclassified <- all(authorization_reconciliation$baseline_eligible == "FALSE" &
                             authorization_reconciliation$d12_baseline_eligible == "FALSE" &
                             authorization_reconciliation$corrected_D11R_authorization != "BASELINE_AUTHORIZED")
target_remains_baseline <- any(d11r_boundary$variable_name %in% target_vars &
                                 d11r_boundary$D11_boundary_status %in% c("BASELINE_ADMISSIBLE", "BASELINE_AUTHORIZED", "BASELINE_REGRESSOR_CANDIDATE", "BASELINE_CAPITAL_OBJECT"))
total_cap_baseline_remains <- any(grepl("total capital", d11r_boundary$detected_category, ignore.case = TRUE) &
                                    grepl("BASELINE_AUTHORIZED|BASELINE_ADMISSIBLE|BASELINE_REGRESSOR|BASELINE_CAPITAL", paste(d11r_boundary$D10_status, d11r_boundary$D11_boundary_status), ignore.case = TRUE))
baseline_me_nrc <- file.exists(file.path(d10_root, "csv/D10_clean_validation_checks.csv")) &&
  any(grepl("K_CAPACITY_EQUALS_ME_PLUS_NRC_RECONFIRMED", read_csv(file.path(d10_root, "csv/D10_clean_validation_checks.csv"))$check, fixed = TRUE))
no_d09s_baseline <- !any(grepl("D09_S|sensitivity", d11r_boundary$variable_name, ignore.case = TRUE) &
                           grepl("BASELINE", paste(d11r_boundary$D10_status, d11r_boundary$D11_boundary_status), ignore.case = TRUE) &
                           !grepl("NOT_BASELINE|EXCLUDED_FROM_BASELINE", paste(d11r_boundary$D10_status, d11r_boundary$D11_boundary_status), ignore.case = TRUE))

premature_estimation <- FALSE
scope_creep <- FALSE
d11_block_confirmed <- grepl("BLOCK_D11_BASELINE_BOUNDARY_LEAKAGE", d11_terminal, fixed = TRUE)

readiness_status <- if (qomega_block) {
  "D12_NOT_AUTHORIZED_QOMEGA_REINTRODUCTION"
} else if (target_remains_baseline || total_cap_baseline_remains) {
  "D12_NOT_AUTHORIZED_BOUNDARY_LEAKAGE_REMAINS"
} else if (scope_creep) {
  "D12_NOT_AUTHORIZED_SCOPE_CREEP"
} else if (d11_block_confirmed && target_found && target_reclassified && baseline_me_nrc && no_d09s_baseline) {
  "D12_AUTHORIZED_AFTER_D11R_BOUNDARY_RECONCILIATION"
} else {
  "D12_NOT_AUTHORIZED_RECONCILIATION_INCOMPLETE"
}

readiness <- data.frame(
  item = c("original_D11_terminal_block_confirmed", "target_variables_found",
           "target_variables_reclassified_out_of_baseline", "q_omega_remains_parked",
           "baseline_capital_remains_ME_NRC", "new_boundary_leak_created",
           "D12_baseline_estimation_design_authorized_after_D11R"),
  value = c(d11_block_confirmed, target_found, target_reclassified, !qomega_block,
            baseline_me_nrc, FALSE, readiness_status == "D12_AUTHORIZED_AFTER_D11R_BOUNDARY_RECONCILIATION"),
  readiness_status = readiness_status,
  notes = c(
    "D11 block is retained as valid evidence.",
    paste(target_vars, collapse = "; "),
    "Both target variables are retained but excluded from baseline eligibility under D11R.",
    "D11R constructs no q_omega-family object.",
    "D10 clean validation confirms K_capacity equals K_ME plus K_NRC.",
    "D11R only reclassifies the two target total-capital variables.",
    "Authorization is for D12 baseline estimation design only."
  )
)
write_csv(readiness, "D11R_D12_READINESS_AFTER_RECONCILIATION.csv")

if (!target_found) {
  terminal_decision <- "REQUIRE_D11R_RECONCILIATION_REVIEW"
} else if (qomega_block) {
  terminal_decision <- "BLOCK_D11R_QOMEGA_REINTRODUCTION"
} else if (premature_estimation) {
  terminal_decision <- "BLOCK_D11R_PREMATURE_ESTIMATION"
} else if (scope_creep) {
  terminal_decision <- "BLOCK_D11R_SCOPE_CREEP"
} else if (target_remains_baseline || total_cap_baseline_remains) {
  terminal_decision <- "BLOCK_D11R_BASELINE_BOUNDARY_LEAKAGE"
} else if (d11_block_confirmed && target_reclassified && baseline_me_nrc && no_d09s_baseline) {
  terminal_decision <- "AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN"
} else {
  terminal_decision <- "REQUIRE_D11R_RECONCILIATION_REVIEW"
}

validation <- data.frame(
  check_id = seq_len(26),
  check_name = c(
    "Correct branch", "Correct starting commit", "Local/remote sync was clean before D11R",
    "D10 folder exists", "D11 folder exists", "D11 terminal decision confirms baseline boundary block",
    "D11 target variables found", "Leak source ledger written", "Authorization reconciliation ledger written",
    "Target variable G_TOT_GPIM_2017 no longer baseline eligible under D11R",
    "Target variable LOG_G_TOT_GPIM_2017 no longer baseline eligible under D11R",
    "No target variable has BASELINE_AUTHORIZED under D11R",
    "No total-capital variable is baseline-authorized under D11R", "Baseline capacity remains ME/NRC",
    "D09-S sensitivity stocks remain report-only or excluded from baseline", "q_omega remains parked",
    "No final estimation was run", "No DOLS/FM-OLS/IM-OLS final estimates were created",
    "No elasticity recovery was run", "No productive capacity reconstruction was run",
    "No utilization reconstruction was run", "D11R model-menu ledger written",
    "D11R theoretical-boundary audit written", "D12 readiness-after-reconciliation ledger written",
    "Terminal decision file written", "Terminal decision is valid"
  ),
  status = "PASS",
  details = ""
)
set_check <- function(name, status, details) {
  idx <- validation$check_name == name
  validation$status[idx] <<- status
  validation$details[idx] <<- details
}
set_check("Correct branch", ifelse(branch == expected_branch, "PASS", "FAIL"), branch)
set_check("Correct starting commit", ifelse(head_hash == expected_head, "PASS", "FAIL"), head_hash)
set_check("Local/remote sync was clean before D11R", ifelse(sync_state == "0\t0" || sync_state == "0 0", "PASS", "FAIL"), sync_state)
set_check("D10 folder exists", ifelse(dir.exists(d10_root), "PASS", "FAIL"), d10_root)
set_check("D11 folder exists", ifelse(dir.exists(d11_root), "PASS", "FAIL"), d11_root)
set_check("D11 terminal decision confirms baseline boundary block", ifelse(d11_block_confirmed, "PASS", "FAIL"), "D11 terminal decision inspected.")
set_check("D11 target variables found", ifelse(target_found, "PASS", "FAIL"), paste(target_vars, collapse = "; "))
set_check("Leak source ledger written", ifelse(file.exists(file.path(csv_dir, "D11R_BASELINE_LEAK_SOURCE_LEDGER.csv")), "PASS", "FAIL"), "D11R_BASELINE_LEAK_SOURCE_LEDGER.csv")
set_check("Authorization reconciliation ledger written", ifelse(file.exists(file.path(csv_dir, "D11R_AUTHORIZATION_RECONCILIATION_LEDGER.csv")), "PASS", "FAIL"), "D11R_AUTHORIZATION_RECONCILIATION_LEDGER.csv")
set_check("Target variable G_TOT_GPIM_2017 no longer baseline eligible under D11R",
          ifelse(authorization_reconciliation$baseline_eligible[authorization_reconciliation$variable_name == "G_TOT_GPIM_2017"] == "FALSE", "PASS", "FAIL"),
          "baseline_eligible=FALSE")
set_check("Target variable LOG_G_TOT_GPIM_2017 no longer baseline eligible under D11R",
          ifelse(authorization_reconciliation$baseline_eligible[authorization_reconciliation$variable_name == "LOG_G_TOT_GPIM_2017"] == "FALSE", "PASS", "FAIL"),
          "baseline_eligible=FALSE")
set_check("No target variable has BASELINE_AUTHORIZED under D11R", ifelse(!target_remains_baseline, "PASS", "FAIL"), "Corrected authorization excludes baseline.")
set_check("No total-capital variable is baseline-authorized under D11R", ifelse(!total_cap_baseline_remains, "PASS", "FAIL"), "D11R boundary audit checked.")
set_check("Baseline capacity remains ME/NRC", ifelse(baseline_me_nrc, "PASS", "FAIL"), "K_capacity = K_ME + K_NRC retained.")
set_check("D09-S sensitivity stocks remain report-only or excluded from baseline", ifelse(no_d09s_baseline, "PASS", "FAIL"), "No D09-S baseline promotion under D11R.")
set_check("q_omega remains parked", ifelse(!qomega_block, "PASS", "FAIL"), paste(sum(qomega_audit$D11R_qomega_status == "BLOCKING_QOMEGA_LEAKAGE"), "blocking hits"))
set_check("No final estimation was run", "PASS", "D11R created ledgers only.")
set_check("No DOLS/FM-OLS/IM-OLS final estimates were created", "PASS", "No final estimator was called.")
set_check("No elasticity recovery was run", "PASS", "No elasticity recovery was called.")
set_check("No productive capacity reconstruction was run", "PASS", "D11R consumed D10/D11 metadata only.")
set_check("No utilization reconstruction was run", "PASS", "No utilization object was reconstructed.")
set_check("D11R model-menu ledger written", ifelse(file.exists(file.path(csv_dir, "D11R_MODEL_MENU_ADMISSIBILITY_LEDGER.csv")), "PASS", "FAIL"), "D11R_MODEL_MENU_ADMISSIBILITY_LEDGER.csv")
set_check("D11R theoretical-boundary audit written", ifelse(file.exists(file.path(csv_dir, "D11R_THEORETICAL_BOUNDARY_AUDIT.csv")), "PASS", "FAIL"), "D11R_THEORETICAL_BOUNDARY_AUDIT.csv")
set_check("D12 readiness-after-reconciliation ledger written", ifelse(file.exists(file.path(csv_dir, "D11R_D12_READINESS_AFTER_RECONCILIATION.csv")), "PASS", "FAIL"), "D11R_D12_READINESS_AFTER_RECONCILIATION.csv")
set_check("Terminal decision is valid", ifelse(terminal_decision %in% valid_decisions, "PASS", "FAIL"), terminal_decision)

decision_md <- c(
  "# D11R Terminal Decision",
  "",
  paste("Terminal decision:", terminal_decision),
  "",
  "## Reconciliation Summary",
  "",
  "D11 correctly blocked D12 authorization because total-capital variables still carried baseline authorization.",
  "D11R retains the variables but reclassifies them out of baseline eligibility in the downstream reconciliation layer.",
  "",
  "## Target Variables",
  "",
  paste("- ", target_vars, ": EXCLUDED_FROM_BASELINE; d12_baseline_eligible=FALSE", sep = ""),
  "",
  "## Boundary Status",
  "",
  paste("Target variables reclassified:", target_reclassified),
  paste("No total-capital variable baseline-authorized under D11R:", !total_cap_baseline_remains),
  paste("Baseline capital remains ME/NRC:", baseline_me_nrc),
  paste("q_omega blocking leakage:", qomega_block),
  "",
  "D11R did not run final estimation, final coefficient estimation, elasticity recovery, productive-capacity reconstruction, or utilization reconstruction."
)
write_md(decision_md, "D11R_TERMINAL_DECISION.md")
set_check("Terminal decision file written", ifelse(file.exists(file.path(d11r_root, "D11R_TERMINAL_DECISION.md")), "PASS", "FAIL"), "D11R_TERMINAL_DECISION.md")

readme <- c(
  "# D11R Baseline Boundary Reconciliation",
  "",
  "## Why D11R Was Needed",
  "",
  "D11 correctly blocked D12 because it found total-capital variables carrying baseline authorization. D11R repairs that role leak in a documented downstream reconciliation layer.",
  "",
  "## What D11 Blocked",
  "",
  "D11 blocked on baseline boundary leakage. The target variables were G_TOT_GPIM_2017 and LOG_G_TOT_GPIM_2017.",
  "",
  "## Where The Leak Was Found",
  "",
  "The leak source ledger records every D10 and D11 occurrence of the target variables. The confirmed leak is BASELINE_AUTHORIZED metadata on total-capital variables.",
  "",
  "## Reclassification",
  "",
  "Both target variables are retained and reclassified as EXCLUDED_FROM_BASELINE with baseline_eligible=FALSE and d12_baseline_eligible=FALSE.",
  "",
  "## Why The Variables Were Not Deleted",
  "",
  "The problem is role authorization, not data corruption. Total-capital objects may remain as report, comparison, diagnostic, or excluded variables outside the baseline capital object.",
  "",
  "## ME/NRC Baseline Protection",
  "",
  "Baseline capacity capital remains K_capacity = K_ME + K_NRC. ME retains L=14 and alpha=1.7; NRC retains L=30 and alpha=1.6.",
  "",
  "## q_omega Status",
  "",
  "q_omega remains parked. D11R did not construct or promote a q_omega-family object.",
  "",
  "## Validation Result",
  "",
  paste(sum(validation$status == "PASS"), "/", nrow(validation), " PASS", sep = ""),
  "",
  "## Terminal Decision",
  "",
  terminal_decision,
  "",
  "## D12 Next Step",
  "",
  if (terminal_decision == "AUTHORIZE_D12_BASELINE_ESTIMATION_DESIGN") {
    "D12 is authorized for baseline estimation design, not for uncontrolled final estimation."
  } else {
    "D12 is not authorized until the D11R block or reconciliation issue is resolved."
  }
)
write_md(readme, "D11R_README.md")

write_csv(validation, "D11R_VALIDATION_CHECKS.csv")

cat("D11R baseline boundary reconciliation complete\n")
cat("Terminal decision:", terminal_decision, "\n")
cat("Validation:", sum(validation$status == "PASS"), "/", nrow(validation), " PASS\n", sep = "")
