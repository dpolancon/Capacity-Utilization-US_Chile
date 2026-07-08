#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
repo_root <- if (length(args) >= 1) args[[1]] else "C:/ReposGitHub/Capacity-Utilization-US_Chile"
stage_dir <- file.path(repo_root, "output", "S34R_A_repaired_design_review_state_dependence")
csv_dir <- file.path(stage_dir, "csv")
input_path <- file.path(csv_dir, "S34R_A_repaired_augmented_panel.csv")
spec_path <- file.path(csv_dir, "S34R_A_eg_model_specs.csv")
output_path <- file.path(csv_dir, "S34R_A_residual_cointegration_eg_ledger.csv")

if (!requireNamespace("aTSA", quietly = TRUE)) {
  install.packages("aTSA", repos = "https://cloud.r-project.org", quiet = TRUE)
}
if (!requireNamespace("aTSA", quietly = TRUE)) {
  stop("aTSA package is required for S34R-A EG gate and could not be installed.", call. = FALSE)
}

panel <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
specs <- read.csv(spec_path, stringsAsFactors = FALSE, check.names = FALSE)
pkg_version <- as.character(utils::packageVersion("aTSA"))

split_regressors <- function(x) {
  if (is.na(x) || !nzchar(x)) return(character(0))
  trimws(strsplit(x, "\\s*\\+\\s*")[[1]])
}

extract_rows <- function(result, design_id, spec, rhs, n_obs, status_note) {
  mat <- NULL
  if (is.matrix(result) || is.data.frame(result)) {
    mat <- as.data.frame(result, stringsAsFactors = FALSE)
  } else if (is.list(result)) {
    for (item in result) {
      if (is.matrix(item) || is.data.frame(item)) {
        mat <- as.data.frame(item, stringsAsFactors = FALSE)
        break
      }
    }
  }
  if (is.null(mat)) {
    return(data.frame(
      design_id = design_id, lhs = spec$lhs, regressors = paste(rhs, collapse = " + "),
      test_type = "unparsed", lag = NA, eg_statistic = NA, p_value = NA,
      n_obs = n_obs, package = "aTSA", package_version = pkg_version,
      model_order_status = spec$model_order_status,
      eg_classification = "EG_NOT_RUN_COLLINEAR",
      notes = paste("Could not parse aTSA return:", paste(capture.output(str(result)), collapse = " ")),
      stringsAsFactors = FALSE
    ))
  }
  pick_col <- function(pattern) {
    hit <- grep(pattern, tolower(names(mat)))
    if (length(hit)) names(mat)[[hit[[1]]]] else NA_character_
  }
  type_col <- pick_col("type")
  lag_col <- pick_col("lag")
  stat_col <- pick_col("^eg$|stat|tau")
  p_col <- pick_col("^p|p.value|p_value")
  if (is.na(type_col)) {
    mat$test_type <- gsub(" ", "", tolower(rownames(mat)))
  } else {
    mat$test_type <- gsub(" ", "", tolower(as.character(mat[[type_col]])))
  }
  n <- nrow(mat)
  value_col <- function(col) {
    if (!is.na(col) && col %in% names(mat)) {
      value <- suppressWarnings(as.numeric(mat[[col]]))
      if (length(value) == n) return(value)
    }
    rep(NA_real_, n)
  }
  data.frame(
    design_id = rep(design_id, n),
    lhs = rep(spec$lhs, n),
    regressors = rep(paste(rhs, collapse = " + "), n),
    test_type = as.character(mat$test_type),
    lag = value_col(lag_col),
    eg_statistic = value_col(stat_col),
    p_value = value_col(p_col),
    n_obs = rep(n_obs, n),
    package = rep("aTSA", n),
    package_version = rep(pkg_version, n),
    model_order_status = rep(spec$model_order_status, n),
    eg_classification = rep("", n),
    notes = rep(status_note, n),
    stringsAsFactors = FALSE
  )
}

not_run_row <- function(design_id, spec, rhs, classification, note, n_obs = 0) {
  data.frame(
    design_id = design_id, lhs = spec$lhs, regressors = paste(rhs, collapse = " + "),
    test_type = "not_run", lag = NA, eg_statistic = NA, p_value = NA,
    n_obs = n_obs, package = "aTSA", package_version = pkg_version,
    model_order_status = spec$model_order_status,
    eg_classification = classification,
    notes = note,
    stringsAsFactors = FALSE
  )
}

rows <- list()
for (i in seq_len(nrow(specs))) {
  spec <- specs[i, , drop = FALSE]
  design_id <- spec$design_id[[1]]
  rhs <- split_regressors(spec$regressors[[1]])
  vars <- c(spec$lhs[[1]], rhs)
  run_eg_flag <- toupper(as.character(spec$run_eg[[1]])) == "TRUE"
  if (!run_eg_flag) {
    rows[[length(rows) + 1L]] <- not_run_row(
      design_id, spec, rhs, spec$skip_classification[[1]], spec$skip_reason[[1]]
    )
    next
  }
  if (!all(vars %in% names(panel))) {
    rows[[length(rows) + 1L]] <- not_run_row(
      design_id, spec, rhs, "EG_NOT_RUN_MISSING_DATA", "Missing model variable."
    )
    next
  }
  data <- panel[, vars, drop = FALSE]
  data[] <- lapply(data, function(x) suppressWarnings(as.numeric(x)))
  data <- data[complete.cases(data), , drop = FALSE]
  if (nrow(data) < length(vars) + 10) {
    rows[[length(rows) + 1L]] <- not_run_row(
      design_id, spec, rhs, "EG_NOT_RUN_MISSING_DATA", "Insufficient complete observations.", nrow(data)
    )
    next
  }
  if (qr(as.matrix(data[, rhs, drop = FALSE]))$rank < length(rhs)) {
    rows[[length(rows) + 1L]] <- not_run_row(
      design_id, spec, rhs, "EG_NOT_RUN_COLLINEAR", "Rank-deficient RHS.", nrow(data)
    )
    next
  }
  attempt <- tryCatch(
    aTSA::coint.test(data[[spec$lhs[[1]]]], as.matrix(data[, rhs, drop = FALSE]), d = 0, nlag = NULL, output = FALSE),
    error = function(e) e
  )
  if (inherits(attempt, "error")) {
    rows[[length(rows) + 1L]] <- not_run_row(
      design_id, spec, rhs, "EG_NOT_RUN_ORDER_INCOMPATIBLE", attempt$message, nrow(data)
    )
  } else {
    rows[[length(rows) + 1L]] <- extract_rows(attempt, design_id, spec, rhs, nrow(data), "aTSA coint.test completed.")
  }
}

ledger <- do.call(rbind, rows)
for (design_id in unique(ledger$design_id)) {
  hit <- ledger[ledger$design_id == design_id & ledger$test_type == "type1", , drop = FALSE]
  if (!nrow(hit)) next
  p <- hit$p_value[1]
  cls <- if (hit$model_order_status[1] == "EG_MIXED_ORDER_CONTROL_DIAGNOSTIC") {
    "EG_MIXED_ORDER_CONTROL_DIAGNOSTIC"
  } else if (is.na(p)) {
    "EG_FAIL"
  } else if (p <= 0.05) {
    "EG_PASS_STRONG"
  } else if (p <= 0.10) {
    "EG_PASS_WEAK"
  } else {
    "EG_FAIL"
  }
  ledger$eg_classification[ledger$design_id == design_id] <- cls
}
ledger$eg_classification[ledger$eg_classification == ""] <- ifelse(
  ledger$test_type[ledger$eg_classification == ""] == "not_run",
  ledger$eg_classification[ledger$eg_classification == ""],
  "EG_FAIL"
)
write.csv(ledger, output_path, row.names = FALSE, na = "")
