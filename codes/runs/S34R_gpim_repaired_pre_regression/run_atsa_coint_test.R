#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
repo_root <- if (length(args) >= 1) args[[1]] else "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_path <- file.path(repo_root, "output", "S34R_gpim_repaired_pre_regression", "csv", "S34R_repaired_candidate_panel.csv")
output_path <- file.path(repo_root, "output", "S34R_gpim_repaired_pre_regression", "csv", "S34R_residual_cointegration_eg_ledger.csv")

if (!requireNamespace("aTSA", quietly = TRUE)) {
  install.packages("aTSA", repos = "https://cloud.r-project.org", quiet = TRUE)
}
if (!requireNamespace("aTSA", quietly = TRUE)) {
  stop("aTSA package is required for S34R EG gate and could not be installed.", call. = FALSE)
}

panel <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)
pkg_version <- as.character(utils::packageVersion("aTSA"))

model_specs <- list(
  EG0 = list(lhs = "y_t", rhs = c("k_Kcap"), order = "PURE_I1_CORE"),
  EG1 = list(lhs = "y_t", rhs = c("k_ME", "k_NRC"), order = "PURE_I1_CORE"),
  EG2 = list(lhs = "y_t", rhs = c("k_Kcap", "Q_MEshare"), order = "PURE_I1_CORE"),
  EG3 = list(lhs = "y_t", rhs = c("k_Kcap", "Q_omega"), order = "PURE_I1_CORE"),
  EG4 = list(lhs = "y_t", rhs = c("k_Kcap", "Q_MEshare", "Q_omega"), order = "PURE_I1_CORE"),
  EGD1 = list(lhs = "y_t", rhs = c("k_Kcap", "Q_MEshare", "omega_NFC"), order = "MIXED_ORDER_CONTROL"),
  EGD2 = list(lhs = "y_t", rhs = c("k_Kcap", "Q_omega", "omega_NFC"), order = "MIXED_ORDER_CONTROL")
)

extract_rows <- function(result, model_id, spec, n_obs, status_note) {
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
      model_id = model_id, lhs = spec$lhs, rhs = paste(spec$rhs, collapse = " + "),
      test_type = "unparsed", lag = NA, eg_statistic = NA, p_value = NA,
      n_obs = n_obs, package = "aTSA", package_version = pkg_version,
      model_order_status = spec$order, eg_classification = "EG_NOT_RUN_COLLINEAR",
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
    model_id = rep(model_id, n),
    lhs = rep(spec$lhs, n),
    rhs = rep(paste(spec$rhs, collapse = " + "), n),
    test_type = as.character(mat$test_type),
    lag = value_col(lag_col),
    eg_statistic = value_col(stat_col),
    p_value = value_col(p_col),
    n_obs = rep(n_obs, n),
    package = rep("aTSA", n),
    package_version = rep(pkg_version, n),
    model_order_status = rep(spec$order, n),
    eg_classification = rep("", n),
    notes = rep(status_note, n),
    stringsAsFactors = FALSE
  )
}

rows <- list()
for (model_id in names(model_specs)) {
  spec <- model_specs[[model_id]]
  vars <- c(spec$lhs, spec$rhs)
  if (!all(vars %in% names(panel))) {
    rows[[length(rows) + 1L]] <- data.frame(
      model_id = model_id, lhs = spec$lhs, rhs = paste(spec$rhs, collapse = " + "),
      test_type = "not_run", lag = NA, eg_statistic = NA, p_value = NA,
      n_obs = 0, package = "aTSA", package_version = pkg_version,
      model_order_status = spec$order, eg_classification = "EG_NOT_RUN_ORDER_INCOMPATIBLE",
      notes = "Missing model variable.", stringsAsFactors = FALSE
    )
    next
  }
  data <- panel[, vars, drop = FALSE]
  data[] <- lapply(data, function(x) suppressWarnings(as.numeric(x)))
  data <- data[complete.cases(data), , drop = FALSE]
  if (nrow(data) < length(vars) + 10 || qr(as.matrix(data[, spec$rhs, drop = FALSE]))$rank < length(spec$rhs)) {
    rows[[length(rows) + 1L]] <- data.frame(
      model_id = model_id, lhs = spec$lhs, rhs = paste(spec$rhs, collapse = " + "),
      test_type = "not_run", lag = NA, eg_statistic = NA, p_value = NA,
      n_obs = nrow(data), package = "aTSA", package_version = pkg_version,
      model_order_status = spec$order, eg_classification = "EG_NOT_RUN_COLLINEAR",
      notes = "Insufficient observations or rank-deficient RHS.", stringsAsFactors = FALSE
    )
    next
  }
  attempt <- tryCatch(
    aTSA::coint.test(data[[spec$lhs]], as.matrix(data[, spec$rhs, drop = FALSE]), d = 0, nlag = NULL, output = FALSE),
    error = function(e) e
  )
  if (inherits(attempt, "error")) {
    rows[[length(rows) + 1L]] <- data.frame(
      model_id = model_id, lhs = spec$lhs, rhs = paste(spec$rhs, collapse = " + "),
      test_type = "not_run", lag = NA, eg_statistic = NA, p_value = NA,
      n_obs = nrow(data), package = "aTSA", package_version = pkg_version,
      model_order_status = spec$order, eg_classification = "EG_NOT_RUN_ORDER_INCOMPATIBLE",
      notes = attempt$message, stringsAsFactors = FALSE
    )
  } else {
    rows[[length(rows) + 1L]] <- extract_rows(attempt, model_id, spec, nrow(data), "aTSA coint.test completed.")
  }
}
ledger <- do.call(rbind, rows)
primary <- ledger$test_type == "type1"
for (model_id in unique(ledger$model_id)) {
  hit <- ledger[ledger$model_id == model_id & primary, , drop = FALSE]
  if (!nrow(hit)) next
  p <- hit$p_value[1]
  cls <- if (hit$model_order_status[1] == "MIXED_ORDER_CONTROL") {
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
  ledger$eg_classification[ledger$model_id == model_id] <- cls
}
ledger$eg_classification[ledger$eg_classification == ""] <- "EG_FAIL"
write.csv(ledger, output_path, row.names = FALSE, na = "")
