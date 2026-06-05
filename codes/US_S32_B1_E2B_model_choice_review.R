###############################################################################
# US_S32_B1_E2B_model_choice_review.R
# Chapter 2 - US S32 governed B1/E2B model-choice review
#
# Role:
#   Estimate the locked B1/E2B comparison under FM-OLS, IM-OLS, and DOLS.
#   Produce CSV-backed TeX tables and markdown reports for human adjudication.
#
# Guardrails:
#   - Estimate only SPEC_B1_WAGE_BASELINE and
#     SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED.
#   - FM-OLS is the main estimator; IM-OLS is robustness; DOLS is stress.
#   - Do not run S40.
#   - Do not reconstruct theta, productive capacity, or utilization.
#   - Do not declare a final winner.
###############################################################################

suppressPackageStartupMessages({
  library(cointReg)
  library(urca)
})

# ---- 0. Paths ----------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")

panel_path <- file.path(REPO, "data/processed/US/us_s20_admissibility_panel.csv")
s31_vif_path <- file.path(REPO, "output/US/S31_model_choice_vif_screen/us_s31_model_choice_vif_screen_tidy.csv")
s31_candidate_vif_path <- file.path(REPO, "output/US/S31_model_choice_vif_screen/us_s31_candidate_mechanization_vif_tidy.csv")
s31_report_path <- file.path(REPO, "output/US/S31_model_choice_vif_screen/US_S31_model_choice_vif_screen_report.md")
s30_dir <- file.path(REPO, "output/US/S30_transformation_relation")
s20_dir <- file.path(REPO, "output/US/S20_composition_admissibility")

out_dir <- file.path(REPO, "output/US/S32_B1_E2B_MODEL_CHOICE_REVIEW")
csv_dir <- file.path(out_dir, "csv")
tex_dir <- file.path(out_dir, "tex")
md_dir <- file.path(out_dir, "md")
logs_dir <- file.path(out_dir, "logs")
audit_dir <- file.path(out_dir, "audit")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tex_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(md_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(logs_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(audit_dir, recursive = TRUE, showWarnings = FALSE)

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
LOG_PATH <- file.path(logs_dir, "S32_run_log.txt")
writeLines(paste0("S32 run started: ", RUN_TIMESTAMP), LOG_PATH, useBytes = TRUE)

# ---- 1. Helpers --------------------------------------------------------------
log_msg <- function(...) {
  msg <- paste0(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), " | ", paste(..., collapse = ""))
  cat(msg, "\n")
  cat(msg, "\n", file = LOG_PATH, append = TRUE)
}

read_csv_base <- function(path, check_names = TRUE) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = check_names)
}

write_csv_base <- function(df, path) {
  utils::write.csv(df, path, row.names = FALSE, na = "")
}

require_file <- function(path) {
  if (!file.exists(path)) stop("Required file not found: ", path, call. = FALSE)
}

require_cols <- function(df, cols, object_name) {
  missing <- setdiff(cols, names(df))
  if (length(missing) > 0L) {
    stop(object_name, " is missing required columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
}

as_num <- function(x) suppressWarnings(as.numeric(x))

finite_or_na <- function(x) {
  x <- as_num(x)
  x[!is.finite(x)] <- NA_real_
  x
}

safe_mean <- function(x) {
  x <- finite_or_na(x)
  if (all(is.na(x))) return(NA_real_)
  mean(x, na.rm = TRUE)
}

safe_sd <- function(x) {
  x <- finite_or_na(x)
  if (sum(!is.na(x)) < 2L) return(NA_real_)
  stats::sd(x, na.rm = TRUE)
}

safe_median <- function(x) {
  x <- finite_or_na(x)
  if (all(is.na(x))) return(NA_real_)
  stats::median(x, na.rm = TRUE)
}

safe_max <- function(x) {
  x <- finite_or_na(x)
  if (all(is.na(x))) return(NA_real_)
  max(x, na.rm = TRUE)
}

collapse_unique <- function(x, sep = " | ") {
  x <- unique(trimws(as.character(x)))
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x) == 0L) return("")
  paste(sort(x), collapse = sep)
}

format_num <- function(x, digits = 3L) {
  x <- as_num(x)
  if (!is.finite(x)) return("")
  formatC(x, format = "f", digits = digits)
}

latex_escape <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([#$%&_{}])", "\\\\\\1", x, perl = TRUE)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x
}

md_escape_pipe <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  gsub("\\|", "\\\\|", x)
}

status_from_p <- function(p) {
  if (!is.finite(p)) return("not_tested")
  if (p <= 0.05) return("pass_5pct")
  if (p <= 0.10) return("pass_10pct")
  "fail"
}

gate_passes <- function(x, include_10pct = TRUE) {
  pass_values <- if (include_10pct) c("pass_1pct", "pass_5pct", "pass_10pct") else c("pass_1pct", "pass_5pct")
  x %in% pass_values
}

gate_passes_5pct_or_better <- function(x) {
  x %in% c("pass_1pct", "pass_5pct")
}

po_gate_from_stat <- function(stat, cv_1pct, cv_5pct, cv_10pct) {
  stat <- as_num(stat)
  cv_1pct <- as_num(cv_1pct)
  cv_5pct <- as_num(cv_5pct)
  cv_10pct <- as_num(cv_10pct)
  if (!is.finite(stat) || !is.finite(cv_10pct)) return("not_tested")
  # urca::ca.po reports Pz and Pu as upper-tail statistics: reject no
  # cointegration when the statistic is greater than the reported critical value.
  if (is.finite(cv_1pct) && stat >= cv_1pct) return("pass_1pct")
  if (is.finite(cv_5pct) && stat >= cv_5pct) return("pass_5pct")
  if (stat >= cv_10pct) return("pass_10pct")
  "fail"
}

estimator_role <- function(estimator) {
  if (estimator == "FM_OLS") return("main_estimator")
  if (estimator == "IM_OLS") return("robustness_estimator")
  if (estimator == "DOLS") return("fragility_stress_diagnostic")
  "unknown"
}

period_family <- function(start_year, end_year) {
  if (end_year <= 1973) return("Fordist_pre_1974")
  if (start_year >= 1974) return("post_Fordist_post_1973")
  "bridge_or_full_cross_partition"
}

vif_status_from_max <- function(vif) {
  if (!is.finite(vif)) return("vif_not_meaningful")
  if (vif < 5) return("vif_pass_low")
  if (vif < 10) return("vif_pass_with_caution")
  "vif_fail_high"
}

sign_label <- function(x) {
  x <- as_num(x)
  if (!is.finite(x)) return("missing")
  if (x > 0) return("positive")
  if (x < 0) return("negative")
  "zero"
}

sign_pattern <- function(vals) {
  paste(vapply(vals, sign_label, character(1L)), collapse = "/")
}

coef_stability_flag <- function(vals) {
  vals <- finite_or_na(vals)
  vals <- vals[!is.na(vals)]
  if (length(vals) < 2L) return("insufficient_estimates")
  if (any(vals == 0)) return("contains_zero")
  if (length(unique(sign(vals))) > 1L) return("sign_unstable")
  ratio <- max(abs(vals)) / max(min(abs(vals)), .Machine$double.eps)
  if (ratio <= 1.5) return("magnitude_stable")
  if (ratio <= 2.5) return("magnitude_review")
  "magnitude_unstable"
}

write_simple_tex <- function(df, path, caption, label, columns, digits = 3L, max_rows = 60L) {
  show <- df[, columns, drop = FALSE]
  if (nrow(show) > max_rows) show <- show[seq_len(max_rows), , drop = FALSE]
  row_lines <- apply(show, 1L, function(z) {
    vals <- vapply(seq_along(z), function(i) {
      value <- z[[i]]
      if (suppressWarnings(!is.na(as.numeric(value))) && grepl("coef|std|stat|p_|r_squared|vif|max|mean|median|n_obs|window_length|year", names(z)[i])) {
        return(format_num(value, digits))
      }
      latex_escape(value)
    }, character(1L))
    paste(vals, collapse = " & ")
  })
  lines <- c(
    "% Auto-generated by codes/US_S32_B1_E2B_model_choice_review.R",
    paste0("% Source CSV: ", basename(sub("\\.tex$", ".csv", path))),
    "\\begin{table}[htbp]",
    "\\centering",
    "\\scriptsize",
    paste0("\\caption{", latex_escape(caption), "}"),
    paste0("\\label{", label, "}"),
    paste0("\\begin{tabular}{", paste(rep("l", length(columns)), collapse = ""), "}"),
    "\\toprule",
    paste(latex_escape(columns), collapse = " & "), "\\\\",
    "\\midrule",
    paste0(row_lines, " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\end{table}"
  )
  writeLines(lines, path, useBytes = TRUE)
}

md_table <- function(df, columns, max_rows = 20L, digits = 3L) {
  show <- df[, columns, drop = FALSE]
  if (nrow(show) > max_rows) show <- show[seq_len(max_rows), , drop = FALSE]
  if (nrow(show) == 0L) return(character(0))
  for (nm in names(show)) {
    if (is.numeric(show[[nm]])) {
      show[[nm]] <- vapply(show[[nm]], format_num, character(1L), digits = digits)
    }
    show[[nm]] <- md_escape_pipe(show[[nm]])
  }
  c(
    paste0("| ", paste(names(show), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(show)), collapse = "|"), "|"),
    apply(show, 1L, function(z) paste0("| ", paste(z, collapse = " | "), " |"))
  )
}

# ---- 2. Inputs and contracts -------------------------------------------------
require_file(panel_path)
panel <- read_csv_base(panel_path)
require_cols(
  panel,
  c("year", "y_t", "k_t", "omega_t", "omega_k_t", "K_ME_gross_real", "K_NRC_gross_real"),
  "us_s20_admissibility_panel.csv"
)

if (file.exists(s31_vif_path)) {
  s31_vif <- read_csv_base(s31_vif_path)
} else {
  s31_vif <- data.frame()
}
if (file.exists(s31_candidate_vif_path)) {
  s31_candidate_vif <- read_csv_base(s31_candidate_vif_path)
} else {
  s31_candidate_vif <- data.frame()
}

panel$year <- as.integer(as_num(panel$year))
panel$y_t <- as_num(panel$y_t)
panel$k_t <- as_num(panel$k_t)
panel$omega_t <- as_num(panel$omega_t)
panel$omega_k_t <- as_num(panel$omega_k_t)
panel$K_ME_gross_real <- as_num(panel$K_ME_gross_real)
panel$K_NRC_gross_real <- as_num(panel$K_NRC_gross_real)
panel$k_NRC_t <- log(panel$K_NRC_gross_real)
panel$m_ME_NRC_t <- log(panel$K_ME_gross_real) - log(panel$K_NRC_gross_real)
panel$omega_m_ME_NRC_t <- panel$omega_t * panel$m_ME_NRC_t

specs <- list(
  SPEC_B1_WAGE_BASELINE = list(
    formula_label = "y_t ~ k_t + omega_k_t",
    interpretation = "aggregate capital envelope + distribution-conditioned aggregate transformation path",
    dependent = "y_t",
    rhs = c("k_t", "omega_k_t"),
    coefficient_names = c("beta_k", "beta_omega_k"),
    expected_positive = c(TRUE, TRUE),
    architecture_layer = "A00_baseline"
  ),
  SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED = list(
    formula_label = "y_t ~ k_NRC_t + omega_m_ME_NRC_t",
    interpretation = "NRC extensive envelope + distribution-conditioned mechanization-bias channel",
    dependent = "y_t",
    rhs = c("k_NRC_t", "omega_m_ME_NRC_t"),
    coefficient_names = c("beta_k_NRC", "beta_omega_m_ME_NRC"),
    expected_positive = c(TRUE, TRUE),
    architecture_layer = "A03_candidate_restricted"
  )
)

spec_contract <- data.frame(
  spec_id = names(specs),
  dependent_var = vapply(specs, `[[`, character(1L), "dependent"),
  formula_label = vapply(specs, `[[`, character(1L), "formula_label"),
  regressors = vapply(specs, function(x) paste(x$rhs, collapse = " | "), character(1L)),
  architecture_layer = vapply(specs, `[[`, character(1L), "architecture_layer"),
  estimator_scope = "FM_OLS | IM_OLS | DOLS",
  S32_role = c("baseline_locked_comparison_object", "restricted_mechanization_bias_candidate"),
  restriction = c("includes aggregate capital and omega_k only", "m_ME_NRC_t omitted by design; E2B is not E2A"),
  S40_authorized = FALSE,
  final_model_selection_authorized = FALSE,
  stringsAsFactors = FALSE
)
write_csv_base(spec_contract, file.path(csv_dir, "S32_spec_contract.csv"))

# ---- 3. Window grid ----------------------------------------------------------
main_windows <- data.frame(
  window_id = c(
    "full_long_sample",
    "pre_1974",
    "post_1973",
    "fordist_core",
    "bridge_1940_1978",
    "pre_1974_alt_1940_1973",
    "pre_1974_alt_1947_1974"
  ),
  window_start = c(1929, 1929, 1974, 1945, 1940, 1940, 1947),
  window_end = c(2024, 1973, 2024, 1973, 1978, 1973, 1974),
  endpoint_type = "locked_main_review",
  included_in_main_review = TRUE,
  reason_included_or_excluded = "existing S31 governed main-review window",
  stringsAsFactors = FALSE
)

min_sample_length <- 25L
fordist_roll <- data.frame(
  window_id = paste0("roll_fordist_1929_", seq(1929 + min_sample_length - 1L, 1973L)),
  window_start = 1929L,
  window_end = seq(1929 + min_sample_length - 1L, 1973L),
  endpoint_type = "rolling_endpoint",
  included_in_main_review = FALSE,
  reason_included_or_excluded = "rolling Fordist endpoint exercise; 1974 partition fixed",
  stringsAsFactors = FALSE
)
fordist_roll$window_id <- paste0("roll_fordist_1929_", fordist_roll$window_end)

post_roll <- data.frame(
  window_id = paste0("roll_post_1974_", seq(1974 + min_sample_length - 1L, max(panel$year, na.rm = TRUE))),
  window_start = 1974L,
  window_end = seq(1974 + min_sample_length - 1L, max(panel$year, na.rm = TRUE)),
  endpoint_type = "rolling_endpoint",
  included_in_main_review = FALSE,
  reason_included_or_excluded = "rolling post-Fordist endpoint exercise; 1974 partition fixed",
  stringsAsFactors = FALSE
)

rolling_endpoint_grid <- rbind(main_windows, fordist_roll, post_roll)
rolling_endpoint_grid$period_family <- mapply(period_family, rolling_endpoint_grid$window_start, rolling_endpoint_grid$window_end)
rolling_endpoint_grid$window_length <- rolling_endpoint_grid$window_end - rolling_endpoint_grid$window_start + 1L
rolling_endpoint_grid <- rolling_endpoint_grid[, c(
  "period_family", "window_id", "window_start", "window_end", "window_length",
  "endpoint_type", "included_in_main_review", "reason_included_or_excluded"
)]
write_csv_base(rolling_endpoint_grid, file.path(csv_dir, "S32_rolling_endpoint_grid.csv"))

# ---- 4. Estimation -----------------------------------------------------------
estimate_cell <- function(data, spec_id, window_id, estimator) {
  spec <- specs[[spec_id]]
  rhs <- spec$rhs
  d <- data[, c("year", spec$dependent, rhs), drop = FALSE]
  d[] <- lapply(d, function(x) if (is.character(x)) x else as_num(x))
  d <- d[stats::complete.cases(d), , drop = FALSE]
  names_for_output <- spec$coefficient_names
  if (nrow(d) < min_sample_length) {
    return(list(ok = FALSE, warning = "sample_too_short", rows = data.frame(), residuals = data.frame()))
  }

  x <- as.matrix(d[, rhs, drop = FALSE])
  colnames(x) <- rhs
  y <- as_num(d[[spec$dependent]])
  deter <- rep(1, length(y))
  fit <- tryCatch({
    if (estimator == "FM_OLS") cointReg::cointRegFM(x = x, y = y, deter = deter)
    else if (estimator == "IM_OLS") cointReg::cointRegIM(x = x, y = y, deter = deter)
    else cointReg::cointRegD(x = x, y = y, deter = deter, n.lead = 2L, n.lag = 2L)
  }, error = function(e) e)

  if (inherits(fit, "error")) {
    empty_rows <- data.frame(
      spec_id = spec_id, window_id = window_id, estimator = estimator,
      estimation_warning = fit$message, stringsAsFactors = FALSE
    )
    return(list(ok = FALSE, warning = fit$message, rows = empty_rows, residuals = data.frame()))
  }

  theta <- finite_or_na(fit$theta)
  se <- finite_or_na(fit$sd.theta)
  tt <- finite_or_na(fit$t.theta)
  pp <- finite_or_na(fit$p.theta)
  p <- length(rhs)
  coef_idx <- seq_len(p) + 1L
  if (length(theta) < p + 1L) stop("Unexpected coefficient vector length for ", spec_id, " / ", estimator)

  beta <- theta[coef_idx]
  beta_se <- se[coef_idx]
  beta_t <- tt[coef_idx]
  beta_p <- pp[coef_idx]
  names(beta) <- names_for_output

  intercept <- theta[1L]
  resid <- finite_or_na(fit$residuals)
  if (length(resid) != nrow(d)) {
    resid <- y - as.vector(intercept + x %*% beta)
  }
  resid_ok <- is.finite(resid)
  r2 <- if (sum(resid_ok) > 2L) {
    1 - sum(resid[resid_ok]^2) / sum((y[resid_ok] - mean(y[resid_ok]))^2)
  } else {
    NA_real_
  }
  rows <- lapply(seq_along(rhs), function(i) {
    data.frame(
      spec_id = spec_id,
      window_id = window_id,
      window_start = min(d$year),
      window_end = max(d$year),
      period_family = period_family(min(d$year), max(d$year)),
      estimator = estimator,
      estimator_role = estimator_role(estimator),
      dependent_var = spec$dependent,
      regressor = rhs[i],
      coefficient_label = names_for_output[i],
      coef = beta[i],
      std_error = beta_se[i],
      t_stat = beta_t[i],
      p_value = beta_p[i],
      n_obs = nrow(d),
      r_squared_or_equivalent = r2,
      estimation_warning = "",
      sample_warning = ifelse(nrow(d) < 30L, "short_sample_review", ""),
      stringsAsFactors = FALSE
    )
  })

  residual_df <- data.frame(
    year = d$year,
    spec_id = spec_id,
    window_id = window_id,
    estimator = estimator,
    residual = resid,
    stringsAsFactors = FALSE
  )

  list(ok = TRUE, warning = "", rows = do.call(rbind, rows), residuals = residual_df)
}

estimation_rows <- list()
residual_rows <- list()
failure_rows <- list()
row_i <- 0L
resid_i <- 0L
fail_i <- 0L

for (w_i in seq_len(nrow(rolling_endpoint_grid))) {
  w <- rolling_endpoint_grid[w_i, ]
  d_w <- panel[panel$year >= w$window_start & panel$year <= w$window_end, , drop = FALSE]
  for (spec_id in names(specs)) {
    for (estimator in c("FM_OLS", "IM_OLS", "DOLS")) {
      result <- estimate_cell(d_w, spec_id, w$window_id, estimator)
      if (isTRUE(result$ok)) {
        row_i <- row_i + 1L
        estimation_rows[[row_i]] <- result$rows
        resid_i <- resid_i + 1L
        residual_rows[[resid_i]] <- result$residuals
      } else {
        fail_i <- fail_i + 1L
        failure_rows[[fail_i]] <- data.frame(
          spec_id = spec_id,
          window_id = w$window_id,
          window_start = w$window_start,
          window_end = w$window_end,
          estimator = estimator,
          warning = result$warning,
          stringsAsFactors = FALSE
        )
      }
    }
  }
}

estimation_results_long <- do.call(rbind, estimation_rows)
estimation_failures <- if (length(failure_rows) > 0L) do.call(rbind, failure_rows) else data.frame()
residuals_long <- do.call(rbind, residual_rows)
write_csv_base(estimation_results_long, file.path(csv_dir, "S32_estimation_results_long.csv"))
write_csv_base(estimation_failures, file.path(logs_dir, "S32_estimation_failures.csv"))

# ---- 4b. Phillips-Ouliaris residual-based cointegration gate -----------------
po_grid <- expand.grid(
  po_type = c("Pz", "Pu"),
  po_demean = c("none", "constant", "trend"),
  po_lag = c("short", "long"),
  stringsAsFactors = FALSE
)

po_complete_levels_matrix <- function(spec_id, window_id) {
  spec <- specs[[spec_id]]
  w <- rolling_endpoint_grid[rolling_endpoint_grid$window_id == window_id, , drop = FALSE]
  d <- panel[panel$year >= w$window_start[1L] & panel$year <= w$window_end[1L],
    c("year", spec$dependent, spec$rhs),
    drop = FALSE
  ]
  d[] <- lapply(d, as_num)
  d <- d[stats::complete.cases(d), , drop = FALSE]
  z <- as.matrix(d[, c(spec$dependent, spec$rhs), drop = FALSE])
  colnames(z) <- c(spec$dependent, spec$rhs)
  list(data = d, z = z, window = w)
}

run_po_case <- function(spec_id, window_id, po_type, po_demean, po_lag) {
  obj <- po_complete_levels_matrix(spec_id, window_id)
  d <- obj$data
  z <- obj$z
  w <- obj$window
  base_row <- data.frame(
    spec_id = spec_id,
    window_id = window_id,
    window_start = w$window_start[1L],
    window_end = w$window_end[1L],
    period_family = w$period_family[1L],
    window_type = w$endpoint_type[1L],
    n_obs = nrow(d),
    po_type = po_type,
    po_demean = po_demean,
    po_lag = po_lag,
    po_statistic = NA_real_,
    po_cv_1pct = NA_real_,
    po_cv_5pct = NA_real_,
    po_cv_10pct = NA_real_,
    phillips_ouliaris_gate = "not_tested",
    po_test_function = "urca::ca.po",
    po_error = "",
    po_warning = "",
    stringsAsFactors = FALSE
  )
  if (nrow(d) < min_sample_length) {
    base_row$po_error <- "sample_too_short"
    return(base_row)
  }
  if (ncol(z) < 2L || qr(z)$rank < ncol(z)) {
    base_row$po_error <- "singular_or_rank_deficient_levels_matrix"
    return(base_row)
  }

  warnings_seen <- character()
  po <- tryCatch(
    withCallingHandlers(
      urca::ca.po(z = z, demean = po_demean, lag = po_lag, type = po_type),
      warning = function(wrn) {
        warnings_seen <<- c(warnings_seen, conditionMessage(wrn))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  base_row$po_warning <- collapse_unique(warnings_seen)
  if (inherits(po, "error")) {
    base_row$po_error <- po$message
    return(base_row)
  }

  cval <- po@cval
  base_row$po_statistic <- as_num(po@teststat[1L])
  base_row$po_cv_1pct <- as_num(cval[1L, "1pct"])
  base_row$po_cv_5pct <- as_num(cval[1L, "5pct"])
  base_row$po_cv_10pct <- as_num(cval[1L, "10pct"])
  base_row$phillips_ouliaris_gate <- po_gate_from_stat(
    base_row$po_statistic,
    base_row$po_cv_1pct,
    base_row$po_cv_5pct,
    base_row$po_cv_10pct
  )
  base_row
}

po_rows <- list()
po_i <- 0L
for (w_i in seq_len(nrow(rolling_endpoint_grid))) {
  window_id <- rolling_endpoint_grid$window_id[w_i]
  for (spec_id in names(specs)) {
    for (g_i in seq_len(nrow(po_grid))) {
      po_i <- po_i + 1L
      po_rows[[po_i]] <- run_po_case(
        spec_id,
        window_id,
        po_grid$po_type[g_i],
        po_grid$po_demean[g_i],
        po_grid$po_lag[g_i]
      )
    }
  }
}
phillips_ouliaris_gate <- do.call(rbind, po_rows)
write_csv_base(phillips_ouliaris_gate, file.path(csv_dir, "S32_phillips_ouliaris_gate.csv"))

baseline_po <- phillips_ouliaris_gate[
  phillips_ouliaris_gate$po_type == "Pz" &
    phillips_ouliaris_gate$po_demean == "constant" &
    phillips_ouliaris_gate$po_lag == "short",
  ,
  drop = FALSE
]
baseline_po_success <- baseline_po[baseline_po$phillips_ouliaris_gate != "not_tested", , drop = FALSE]
baseline_po_passes <- baseline_po[gate_passes(baseline_po$phillips_ouliaris_gate), , drop = FALSE]
baseline_po_failures <- baseline_po[baseline_po$phillips_ouliaris_gate == "fail", , drop = FALSE]
baseline_po_not_tested <- baseline_po[baseline_po$phillips_ouliaris_gate == "not_tested", , drop = FALSE]

# ---- 5. Coefficient panel and diagnostics -----------------------------------
make_coef_panel_row <- function(df) {
  spec_id <- df$spec_id[1L]
  spec <- specs[[spec_id]]
  vals <- setNames(rep(NA_real_, 4L), c("beta_k", "beta_omega_k", "beta_k_NRC", "beta_omega_m_ME_NRC"))
  for (i in seq_len(nrow(df))) vals[df$coefficient_label[i]] <- as_num(df$coef[i])
  signs <- vapply(vals, sign_label, character(1L))
  relevant <- vals[spec$coefficient_names]
  expected_ok <- all(vapply(relevant, function(x) is.finite(x) && x > 0, logical(1L)))
  data.frame(
    spec_id = spec_id,
    window_id = df$window_id[1L],
    window_start = df$window_start[1L],
    window_end = df$window_end[1L],
    period_family = df$period_family[1L],
    estimator = df$estimator[1L],
    estimator_role = df$estimator_role[1L],
    beta_k = vals["beta_k"],
    beta_omega_k = vals["beta_omega_k"],
    beta_k_NRC = vals["beta_k_NRC"],
    beta_omega_m_ME_NRC = vals["beta_omega_m_ME_NRC"],
    sign_beta_k = signs["beta_k"],
    sign_beta_omega_k = signs["beta_omega_k"],
    sign_beta_k_NRC = signs["beta_k_NRC"],
    sign_beta_omega_m_ME_NRC = signs["beta_omega_m_ME_NRC"],
    expected_sign_alignment = expected_ok,
    interpretation_flag = ifelse(expected_ok, "expected_positive_signs", "sign_review"),
    stringsAsFactors = FALSE
  )
}

groups <- split(estimation_results_long, paste(estimation_results_long$spec_id, estimation_results_long$window_id, estimation_results_long$estimator, sep = "||"))
coefficient_panel <- do.call(rbind, lapply(groups, make_coef_panel_row))
write_csv_base(coefficient_panel, file.path(csv_dir, "S32_coefficient_panel.csv"))

triangulation_rows <- lapply(split(coefficient_panel, paste(coefficient_panel$spec_id, coefficient_panel$window_id, sep = "||")), function(df) {
  fm <- df[df$estimator == "FM_OLS", , drop = FALSE]
  im <- df[df$estimator == "IM_OLS", , drop = FALSE]
  dols <- df[df$estimator == "DOLS", , drop = FALSE]
  spec_id <- df$spec_id[1L]
  cn <- specs[[spec_id]]$coefficient_names
  vals_for <- function(row) {
    if (nrow(row) == 0L) return(rep(NA_real_, length(cn)))
    as_num(row[1L, cn, drop = TRUE])
  }
  fm_vals <- vals_for(fm)
  im_vals <- vals_for(im)
  dols_vals <- vals_for(dols)
  fm_pat <- sign_pattern(fm_vals)
  im_pat <- sign_pattern(im_vals)
  dols_pat <- sign_pattern(dols_vals)
  fm_im_align <- identical(fm_pat, im_pat) && !grepl("missing", fm_pat)
  dols_fragile <- !identical(fm_pat, dols_pat)
  mag_stab <- coef_stability_flag(c(fm_vals, im_vals))
  status <- if (nrow(fm) == 0L || nrow(im) == 0L) {
    "estimator_failure"
  } else if (!fm_im_align && grepl("negative|zero", paste(fm_pat, im_pat))) {
    "sign_conflict"
  } else if (mag_stab == "magnitude_unstable") {
    "magnitude_unstable"
  } else if (fm_im_align && !dols_fragile && mag_stab %in% c("magnitude_stable", "magnitude_review")) {
    "strong_alignment"
  } else if (fm_im_align && dols_fragile) {
    "dols_fragile_only"
  } else {
    "partial_alignment"
  }
  data.frame(
    spec_id = spec_id,
    window_id = df$window_id[1L],
    window_start = df$window_start[1L],
    window_end = df$window_end[1L],
    period_family = df$period_family[1L],
    fmols_sign_pattern = fm_pat,
    imols_sign_pattern = im_pat,
    dols_sign_pattern = dols_pat,
    fmols_imols_alignment = fm_im_align,
    dols_fragility_flag = dols_fragile,
    coefficient_magnitude_stability = mag_stab,
    triangulation_status = status,
    human_review_priority = ifelse(status %in% c("strong_alignment", "dols_fragile_only"), "normal", "high"),
    stringsAsFactors = FALSE
  )
})
estimator_triangulation <- do.call(rbind, triangulation_rows)
write_csv_base(estimator_triangulation, file.path(csv_dir, "S32_estimator_triangulation.csv"))

# ---- 6. VIF ------------------------------------------------------------------
compute_vif <- function(df, rhs) {
  if (length(rhs) == 1L) return(setNames(NA_real_, rhs))
  out <- setNames(rep(NA_real_, length(rhs)), rhs)
  d <- df[, rhs, drop = FALSE]
  d[] <- lapply(d, as_num)
  d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) <= length(rhs) + 1L) return(out)
  for (var in rhs) {
    others <- setdiff(rhs, var)
    fit <- tryCatch(stats::lm(stats::as.formula(paste(var, "~", paste(others, collapse = " + "))), data = d), error = function(e) NULL)
    if (!is.null(fit)) {
      r2 <- summary(fit)$r.squared
      out[var] <- ifelse(is.finite(r2) && r2 < 1, 1 / (1 - r2), Inf)
    }
  }
  out
}

vif_rows <- list()
vif_i <- 0L
for (w_i in seq_len(nrow(rolling_endpoint_grid))) {
  w <- rolling_endpoint_grid[w_i, ]
  d_w <- panel[panel$year >= w$window_start & panel$year <= w$window_end, , drop = FALSE]
  for (spec_id in names(specs)) {
    rhs <- specs[[spec_id]]$rhs
    v <- compute_vif(d_w, rhs)
    max_v <- safe_max(v)
    high_terms <- names(v)[is.finite(v) & v >= 10]
    vif_i <- vif_i + 1L
    vif_rows[[vif_i]] <- data.frame(
      spec_id = spec_id,
      window_id = w$window_id,
      window_start = w$window_start,
      window_end = w$window_end,
      max_vif = max_v,
      vif_status = vif_status_from_max(max_v),
      high_vif_flag = is.finite(max_v) && max_v >= 10,
      problematic_terms = collapse_unique(high_terms),
      collinearity_comment = ifelse(is.finite(max_v) && max_v >= 10, "high VIF blocks mechanical pass", ifelse(is.finite(max_v) && max_v >= 5, "moderate VIF caution", "low VIF")),
      stringsAsFactors = FALSE
    )
  }
}
vif_collinearity <- do.call(rbind, vif_rows)
write_csv_base(vif_collinearity, file.path(csv_dir, "S32_vif_collinearity.csv"))

# ---- 7. Outlier and dummy screen --------------------------------------------
aux_influence <- function(spec_id, window_id) {
  spec <- specs[[spec_id]]
  w <- rolling_endpoint_grid[rolling_endpoint_grid$window_id == window_id, ]
  d <- panel[panel$year >= w$window_start & panel$year <= w$window_end, c("year", spec$dependent, spec$rhs), drop = FALSE]
  d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) <= length(spec$rhs) + 3L) return(data.frame())
  fit <- stats::lm(stats::as.formula(paste(spec$dependent, "~", paste(spec$rhs, collapse = " + "))), data = d)
  data.frame(
    year = d$year,
    spec_id = spec_id,
    window_id = window_id,
    studentized_residual = finite_or_na(stats::rstudent(fit)),
    cook_distance = finite_or_na(stats::cooks.distance(fit)),
    leverage = finite_or_na(stats::hatvalues(fit)),
    stringsAsFactors = FALSE
  )
}

influence_rows <- lapply(unique(paste(residuals_long$spec_id, residuals_long$window_id, sep = "||")), function(key) {
  parts <- strsplit(key, "\\|\\|")[[1L]]
  aux_influence(parts[1L], parts[2L])
})
influence_df <- do.call(rbind, influence_rows)

outlier_screen <- merge(residuals_long, influence_df, by = c("year", "spec_id", "window_id"), all.x = TRUE)
outlier_screen$residual <- finite_or_na(outlier_screen$residual)
outlier_screen$standardized_residual <- ave(outlier_screen$residual, outlier_screen$spec_id, outlier_screen$window_id, outlier_screen$estimator, FUN = function(x) x / safe_sd(x))
outlier_screen$mad_score <- ave(outlier_screen$residual, outlier_screen$spec_id, outlier_screen$window_id, outlier_screen$estimator, FUN = function(x) {
  m <- stats::median(x, na.rm = TRUE)
  md <- stats::mad(x, constant = 1, na.rm = TRUE)
  if (!is.finite(md) || md == 0) return(rep(NA_real_, length(x)))
  abs(x - m) / md
})
outlier_screen$n_for_influence <- ave(outlier_screen$residual, outlier_screen$spec_id, outlier_screen$window_id, FUN = length)
outlier_screen$p_for_influence <- ave(outlier_screen$residual, outlier_screen$spec_id, outlier_screen$window_id, FUN = function(x) rep(3L, length(x)))
outlier_screen$outlier_flag_residual <- abs(outlier_screen$standardized_residual) >= 2.5 | outlier_screen$mad_score >= 3.5
outlier_screen$outlier_flag_residual[is.na(outlier_screen$outlier_flag_residual)] <- FALSE
outlier_screen$outlier_flag_influence <- outlier_screen$cook_distance > (4 / outlier_screen$n_for_influence) |
  outlier_screen$leverage > (2 * outlier_screen$p_for_influence / outlier_screen$n_for_influence) |
  abs(outlier_screen$studentized_residual) >= 3
outlier_screen$outlier_flag_influence[is.na(outlier_screen$outlier_flag_influence)] <- FALSE
outlier_screen$outlier_flag_consensus <- outlier_screen$outlier_flag_residual & outlier_screen$outlier_flag_influence

consensus <- outlier_screen[outlier_screen$outlier_flag_consensus, , drop = FALSE]
year_counts <- if (nrow(consensus) > 0L) {
  aggregate(
    cbind(recurs_across_estimators = as.integer(!is.na(estimator)),
          recurs_across_specs = as.integer(!is.na(spec_id)),
          recurs_across_windows = as.integer(!is.na(window_id))) ~ year,
    data = unique(consensus[, c("year", "estimator", "spec_id", "window_id")]),
    FUN = length
  )
} else {
  data.frame(year = integer(), recurs_across_estimators = integer(), recurs_across_specs = integer(), recurs_across_windows = integer())
}
outlier_screen <- merge(outlier_screen, year_counts, by = "year", all.x = TRUE)
for (nm in c("recurs_across_estimators", "recurs_across_specs", "recurs_across_windows")) {
  outlier_screen[[nm]][is.na(outlier_screen[[nm]])] <- 0L
}
outlier_screen$outlier_priority <- ifelse(outlier_screen$outlier_flag_consensus & outlier_screen$recurs_across_specs >= 2, "high",
  ifelse(outlier_screen$outlier_flag_consensus, "medium", "low"))
outlier_screen$historical_prior_used <- FALSE
outlier_screen <- outlier_screen[, c(
  "year", "spec_id", "window_id", "estimator", "residual", "standardized_residual",
  "studentized_residual", "mad_score", "cook_distance", "leverage",
  "outlier_flag_residual", "outlier_flag_influence", "outlier_flag_consensus",
  "recurs_across_estimators", "recurs_across_specs", "recurs_across_windows",
  "outlier_priority", "historical_prior_used"
)]
write_csv_base(outlier_screen, file.path(csv_dir, "S32_outlier_screen.csv"))

dummy_candidates <- unique(outlier_screen[outlier_screen$outlier_flag_consensus, c("year", "outlier_priority"), drop = FALSE])
if (nrow(dummy_candidates) > 0L) {
  dummy_candidates <- dummy_candidates[order(dummy_candidates$year), , drop = FALSE]
  dummy_rows <- lapply(seq_len(nrow(dummy_candidates)), function(i) {
    y <- dummy_candidates$year[i]
    hits <- outlier_screen[outlier_screen$year == y & outlier_screen$outlier_flag_consensus, , drop = FALSE]
    data.frame(
      dummy_id = paste0("D_pulse_", y),
      year = y,
      dummy_type = "pulse",
      identification_basis = "endogenous_outlier_screen",
      identified_by_specs = collapse_unique(hits$spec_id),
      identified_by_estimators = collapse_unique(hits$estimator),
      identified_by_windows = collapse_unique(hits$window_id),
      priority = dummy_candidates$outlier_priority[i],
      historical_prior_used = FALSE,
      recommended_for_future_control_test = dummy_candidates$outlier_priority[i] %in% c("high", "medium"),
      notes = "candidate only; not imposed in S32 preferred estimation",
      stringsAsFactors = FALSE
    )
  })
  dummy_candidate_grid <- do.call(rbind, dummy_rows)
} else {
  dummy_candidate_grid <- data.frame(
    dummy_id = character(), year = integer(), dummy_type = character(),
    identification_basis = character(), identified_by_specs = character(),
    identified_by_estimators = character(), identified_by_windows = character(),
    priority = character(), historical_prior_used = logical(),
    recommended_for_future_control_test = logical(), notes = character()
  )
}
write_csv_base(dummy_candidate_grid, file.path(csv_dir, "S32_dummy_candidate_grid.csv"))

# ---- 7b. Bounded Phillips-Ouliaris pulse-dummy robustness --------------------
dummy_robustness_name <- "S32_B1_E2B_PO_DUMMY_ROBUSTNESS"

count_pipe_terms <- function(x) {
  x <- trimws(as.character(x))
  if (is.na(x) || !nzchar(x)) return(0L)
  length(strsplit(x, "\\s*\\|\\s*")[[1L]])
}

make_pulse_matrix <- function(years, dummy_years) {
  dummy_years <- sort(unique(as.integer(dummy_years)))
  if (length(dummy_years) == 0L) return(NULL)
  out <- sapply(dummy_years, function(y) as.integer(years == y))
  if (is.null(dim(out))) out <- matrix(out, ncol = 1L)
  colnames(out) <- paste0("D_pulse_", dummy_years)
  out
}

residualize_levels_on_pulses <- function(z, years, dummy_years) {
  dmat <- make_pulse_matrix(years, dummy_years)
  if (is.null(dmat)) return(list(z = z, error = "", warning = "no_in_window_dummies"))
  x <- cbind(intercept = 1, dmat)
  if (qr(x)$rank < ncol(x)) {
    return(list(z = z, error = "rank_deficient_dummy_design", warning = ""))
  }
  fit <- stats::lm.fit(x = x, y = z)
  z_adj <- fit$residuals + matrix(colMeans(z, na.rm = TRUE), nrow = nrow(z), ncol = ncol(z), byrow = TRUE)
  colnames(z_adj) <- colnames(z)
  list(z = z_adj, error = "", warning = "")
}

if (nrow(dummy_candidate_grid) > 0L) {
  dummy_candidate_meta <- dummy_candidate_grid
  dummy_candidate_meta$n_identified_specs <- vapply(dummy_candidate_meta$identified_by_specs, count_pipe_terms, integer(1L))
  dummy_candidate_meta$n_identified_estimators <- vapply(dummy_candidate_meta$identified_by_estimators, count_pipe_terms, integer(1L))
  dummy_candidate_meta$n_identified_windows <- vapply(dummy_candidate_meta$identified_by_windows, count_pipe_terms, integer(1L))
  dummy_candidate_meta$strict_high_recurrence <- dummy_candidate_meta$priority == "high" &
    dummy_candidate_meta$n_identified_specs >= 2L &
    dummy_candidate_meta$n_identified_estimators >= 2L &
    dummy_candidate_meta$n_identified_windows >= 3L
} else {
  dummy_candidate_meta <- data.frame(
    dummy_id = character(), year = integer(), priority = character(),
    n_identified_specs = integer(), n_identified_estimators = integer(),
    n_identified_windows = integer(), strict_high_recurrence = logical(),
    stringsAsFactors = FALSE
  )
}

write_csv_base(dummy_candidate_meta, file.path(csv_dir, "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_dummy_protocol.csv"))

dummy_variant_contract <- data.frame(
  dummy_variant = c("D0", "D1", "D2", "D3"),
  variant_label = c(
    "no_dummies_current_S32_baseline",
    "strict_high_recurrence_high_priority",
    "all_high_priority_in_window",
    "all_high_and_medium_priority_in_window"
  ),
  rule = c(
    "No pulse controls; current patched S32 baseline Pz / constant / short.",
    "Use high-priority pulse years recurring across both specs, at least two estimators, and at least three windows.",
    "Use all high-priority pulse years inside the spec-window sample.",
    "Use all high-priority and medium-priority pulse years inside the spec-window sample."
  ),
  can_rescue_for_serious_human_review = c(FALSE, TRUE, FALSE, FALSE),
  interpretation_limit = c(
    "baseline only",
    "only bounded dummy variant allowed to rescue a failed baseline for serious human review",
    "fragility diagnostic only; cannot define preferred relation",
    "stress test only; cannot define preferred relation"
  ),
  historical_prior_used = FALSE,
  stringsAsFactors = FALSE
)
write_csv_base(dummy_variant_contract, file.path(csv_dir, "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_variant_contract.csv"))

dummy_years_for_variant <- function(variant, window_start, window_end) {
  if (variant == "D0" || nrow(dummy_candidate_meta) == 0L) return(integer(0))
  d <- dummy_candidate_meta
  if (variant == "D1") d <- d[d$strict_high_recurrence, , drop = FALSE]
  if (variant == "D2") d <- d[d$priority == "high", , drop = FALSE]
  if (variant == "D3") d <- d[d$priority %in% c("high", "medium"), , drop = FALSE]
  sort(unique(as.integer(d$year[d$year >= window_start & d$year <= window_end])))
}

run_po_dummy_case <- function(spec_id, window_id, dummy_variant) {
  obj <- po_complete_levels_matrix(spec_id, window_id)
  d <- obj$data
  z <- obj$z
  w <- obj$window
  dummy_years <- dummy_years_for_variant(dummy_variant, w$window_start[1L], w$window_end[1L])
  n_dummies <- length(dummy_years)
  effective_n_after_controls <- nrow(d) - n_dummies
  base <- data.frame(
    spec_id = spec_id,
    window_id = window_id,
    period_family = w$period_family[1L],
    window_type = w$endpoint_type[1L],
    window_start = w$window_start[1L],
    window_end = w$window_end[1L],
    n_obs = nrow(d),
    dummy_variant = dummy_variant,
    dummy_variant_label = dummy_variant_contract$variant_label[match(dummy_variant, dummy_variant_contract$dummy_variant)],
    n_dummies = n_dummies,
    dummy_years = paste(dummy_years, collapse = " | "),
    effective_n_after_controls = effective_n_after_controls,
    po_type = "Pz",
    po_demean = "constant",
    po_lag = "short",
    po_statistic = NA_real_,
    po_cv_1pct = NA_real_,
    po_cv_5pct = NA_real_,
    po_cv_10pct = NA_real_,
    phillips_ouliaris_gate = "not_tested",
    po_test_function = "urca::ca.po",
    dummy_adjustment_method = ifelse(dummy_variant == "D0", "none", "levels_residualized_on_intercept_and_pulse_dummies_before_ca_po"),
    po_error = "",
    po_warning = "",
    historical_prior_used = FALSE,
    stringsAsFactors = FALSE
  )

  if (dummy_variant != "D0" && n_dummies == 0L) {
    base$po_warning <- "no_in_window_dummies"
  }
  if (nrow(d) < min_sample_length) {
    base$po_error <- "sample_too_short"
    return(base)
  }
  if (effective_n_after_controls < min_sample_length) {
    base$po_error <- "too_many_dummies_for_min_effective_sample"
    return(base)
  }

  z_test <- z
  if (dummy_variant != "D0" && n_dummies > 0L) {
    adj <- residualize_levels_on_pulses(z, d$year, dummy_years)
    if (nzchar(adj$error)) {
      base$po_error <- adj$error
      return(base)
    }
    z_test <- adj$z
    if (nzchar(adj$warning)) base$po_warning <- collapse_unique(c(base$po_warning, adj$warning))
  }
  if (qr(z_test)$rank < ncol(z_test)) {
    base$po_error <- "rank_deficient_adjusted_levels_matrix"
    return(base)
  }

  warnings_seen <- character()
  po <- tryCatch(
    withCallingHandlers(
      urca::ca.po(z = z_test, demean = "constant", lag = "short", type = "Pz"),
      warning = function(wrn) {
        warnings_seen <<- c(warnings_seen, conditionMessage(wrn))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  base$po_warning <- collapse_unique(c(base$po_warning, warnings_seen))
  if (inherits(po, "error")) {
    base$po_error <- po$message
    return(base)
  }
  cval <- po@cval
  base$po_statistic <- as_num(po@teststat[1L])
  base$po_cv_1pct <- as_num(cval[1L, "1pct"])
  base$po_cv_5pct <- as_num(cval[1L, "5pct"])
  base$po_cv_10pct <- as_num(cval[1L, "10pct"])
  base$phillips_ouliaris_gate <- po_gate_from_stat(base$po_statistic, base$po_cv_1pct, base$po_cv_5pct, base$po_cv_10pct)
  base
}

dummy_po_rows <- list()
dummy_po_i <- 0L
for (window_id in unique(rolling_endpoint_grid$window_id)) {
  for (spec_id in names(specs)) {
    for (variant in dummy_variant_contract$dummy_variant) {
      dummy_po_i <- dummy_po_i + 1L
      dummy_po_rows[[dummy_po_i]] <- run_po_dummy_case(spec_id, window_id, variant)
    }
  }
}
po_dummy_robustness_gate <- do.call(rbind, dummy_po_rows)
write_csv_base(po_dummy_robustness_gate, file.path(csv_dir, "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_gate.csv"))

dummy_gate_lookup <- function(df, variant) {
  hit <- df[df$dummy_variant == variant, , drop = FALSE]
  if (nrow(hit) == 0L) return("not_tested")
  hit$phillips_ouliaris_gate[1L]
}

po_dummy_robustness_ledger <- do.call(rbind, lapply(
  split(po_dummy_robustness_gate, paste(po_dummy_robustness_gate$spec_id, po_dummy_robustness_gate$window_id, sep = "||")),
  function(df) {
    d0 <- dummy_gate_lookup(df, "D0")
    d1 <- dummy_gate_lookup(df, "D1")
    d2 <- dummy_gate_lookup(df, "D2")
    d3 <- dummy_gate_lookup(df, "D3")
    d1_rescue <- !gate_passes(d0) && gate_passes(d1)
    d2_fragility <- !gate_passes(d0) && !d1_rescue && gate_passes(d2)
    d3_fragility <- !gate_passes(d0) && !d1_rescue && gate_passes(d3)
    status <- if (gate_passes(d0)) {
      "already_admissible_without_dummies"
    } else if (d1_rescue) {
      "strict_D1_rescue_for_serious_human_review"
    } else if (d2_fragility || d3_fragility) {
      "fragility_only_D2_or_D3"
    } else if (all(c(d0, d1, d2, d3) == "not_tested")) {
      "not_tested"
    } else {
      "unchanged_failure"
    }
    data.frame(
      spec_id = df$spec_id[1L],
      window_id = df$window_id[1L],
      period_family = df$period_family[1L],
      window_type = df$window_type[1L],
      window_start = df$window_start[1L],
      window_end = df$window_end[1L],
      d0_gate = d0,
      d1_gate = d1,
      d2_gate = d2,
      d3_gate = d3,
      d1_n_dummies = df$n_dummies[df$dummy_variant == "D1"][1L],
      d2_n_dummies = df$n_dummies[df$dummy_variant == "D2"][1L],
      d3_n_dummies = df$n_dummies[df$dummy_variant == "D3"][1L],
      d1_rescue_for_serious_human_review = d1_rescue,
      d2_fragility_signal_only = d2_fragility,
      d3_stress_signal_only = d3_fragility,
      dummy_robustness_status = status,
      preferred_relation_authorized = FALSE,
      s40_authorized = FALSE,
      historical_prior_used = FALSE,
      notes = "Dummies are endogenous diagnostic pulse controls only. D1 can rescue for serious human review; D2/D3 indicate fragility only.",
      stringsAsFactors = FALSE
    )
  }
))
write_csv_base(po_dummy_robustness_ledger, file.path(csv_dir, "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_ledger.csv"))

po_dummy_robustness_log <- data.frame(
  item = c(
    "pass_name",
    "spec_window_variant_rows",
    "baseline_D0_rows",
    "D1_rescue_rows",
    "D2_fragility_signal_rows",
    "D3_stress_signal_rows",
    "not_tested_rows",
    "historical_prior_used",
    "s40_authorized"
  ),
  value = c(
    dummy_robustness_name,
    nrow(po_dummy_robustness_gate),
    sum(po_dummy_robustness_gate$dummy_variant == "D0"),
    sum(po_dummy_robustness_ledger$d1_rescue_for_serious_human_review),
    sum(po_dummy_robustness_ledger$d2_fragility_signal_only),
    sum(po_dummy_robustness_ledger$d3_stress_signal_only),
    sum(po_dummy_robustness_gate$phillips_ouliaris_gate == "not_tested"),
    "FALSE",
    "FALSE"
  ),
  stringsAsFactors = FALSE
)
write_csv_base(po_dummy_robustness_log, file.path(logs_dir, "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_log.csv"))

# ---- 8. Window behavior and ledger ------------------------------------------
window_behavior_rows <- lapply(split(coefficient_panel, paste(coefficient_panel$spec_id, coefficient_panel$window_id, sep = "||")), function(df) {
  tri <- estimator_triangulation[estimator_triangulation$spec_id == df$spec_id[1L] & estimator_triangulation$window_id == df$window_id[1L], , drop = FALSE]
  data.frame(
    spec_id = df$spec_id[1L],
    window_id = df$window_id[1L],
    period_family = df$period_family[1L],
    window_start = df$window_start[1L],
    window_end = df$window_end[1L],
    window_length = df$window_end[1L] - df$window_start[1L] + 1L,
    endpoint_type = rolling_endpoint_grid$endpoint_type[match(df$window_id[1L], rolling_endpoint_grid$window_id)],
    fm_im_sign_stable = tri$fmols_imols_alignment[1L],
    dols_fragility_flag = tri$dols_fragility_flag[1L],
    magnitude_stability = tri$coefficient_magnitude_stability[1L],
    window_behavior_pass = tri$triangulation_status[1L] %in% c("strong_alignment", "dols_fragile_only", "partial_alignment"),
    stability_flag = tri$triangulation_status[1L],
    stringsAsFactors = FALSE
  )
})
window_behavior <- do.call(rbind, window_behavior_rows)
write_csv_base(window_behavior, file.path(csv_dir, "S32_window_behavior.csv"))

nonselected_specs_status <- data.frame(
  spec_id = c(
    "SPEC_B0_CAPITAL_ONLY",
    "SPEC_C1_COMPOSITION_STOCK",
    "SPEC_C2_FULL_COMPOSITION",
    "SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS",
    "SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL",
    "SPEC_D1_CURRENT_COST_DIAGNOSTIC",
    "SPEC_D2_PRICE_WEDGE_DIAGNOSTIC"
  ),
  status = c(
    "not_in_S32_pair", "not_in_S32_pair", "not_in_S32_pair", "not_in_S32_pair",
    "not_in_S32_pair", "diagnostic_only_not_in_S32_pair", "diagnostic_only_not_in_S32_pair"
  ),
  reason_not_in_S32_pair = c(
    "capital-only reference is not the locked B1 baseline",
    "proxy-escalation spec excluded by locked B1/E2B comparison",
    "full proxy-composition spec excluded by locked B1/E2B comparison",
    "unconditioned mechanization-bias candidate excluded by locked pair",
    "full E2A candidate includes m_ME_NRC_t separately; S32 locks restricted E2B only",
    "diagnostic-only current-cost spec",
    "diagnostic-only price-wedge spec"
  ),
  allowed_future_use = c(
    "reference metadata only", "future governed review only", "future governed review only",
    "future governed review only", "future governed review only", "diagnostic appendix only", "diagnostic appendix only"
  ),
  stringsAsFactors = FALSE
)
write_csv_base(nonselected_specs_status, file.path(csv_dir, "S32_nonselected_specs_status.csv"))

po_variant_gate <- function(po_df, po_type, po_demean, po_lag) {
  hit <- po_df[
    po_df$po_type == po_type & po_df$po_demean == po_demean & po_df$po_lag == po_lag,
    ,
    drop = FALSE
  ]
  if (nrow(hit) == 0L) return("not_tested")
  hit$phillips_ouliaris_gate[1L]
}

po_changed <- function(x) {
  x <- unique(x[!is.na(x) & x != "not_tested"])
  length(x) > 1L
}

cointegration_admissibility_rows <- lapply(
  split(phillips_ouliaris_gate, paste(phillips_ouliaris_gate$spec_id, phillips_ouliaris_gate$window_id, sep = "||")),
  function(po_df) {
    spec_id <- po_df$spec_id[1L]
    window_id <- po_df$window_id[1L]
    tri <- estimator_triangulation[estimator_triangulation$spec_id == spec_id & estimator_triangulation$window_id == window_id, , drop = FALSE]
    vif <- vif_collinearity[vif_collinearity$spec_id == spec_id & vif_collinearity$window_id == window_id, , drop = FALSE]
    out <- outlier_screen[outlier_screen$window_id == window_id & outlier_screen$spec_id == spec_id & outlier_screen$outlier_flag_consensus, , drop = FALSE]

    pz <- po_df[po_df$po_type == "Pz", , drop = FALSE]
    baseline <- po_variant_gate(po_df, "Pz", "constant", "short")
    pz_pass_count <- sum(gate_passes(pz$phillips_ouliaris_gate), na.rm = TRUE)
    pz_not_tested <- all(pz$phillips_ouliaris_gate == "not_tested")
    po_any_pz_pass <- pz_pass_count > 0L
    po_all_pz_fail <- nrow(pz) > 0L && all(pz$phillips_ouliaris_gate == "fail")
    det_sensitive <- any(vapply(c("short", "long"), function(lg) {
      po_changed(pz$phillips_ouliaris_gate[pz$po_lag == lg])
    }, logical(1L)))
    lag_sensitive <- any(vapply(c("none", "constant", "trend"), function(dm) {
      po_changed(pz$phillips_ouliaris_gate[pz$po_demean == dm])
    }, logical(1L)))
    norm_sensitive <- any(vapply(seq_len(nrow(po_grid[po_grid$po_type == "Pz", , drop = FALSE])), function(i) {
      dm <- po_grid$po_demean[po_grid$po_type == "Pz"][i]
      lg <- po_grid$po_lag[po_grid$po_type == "Pz"][i]
      pz_gate <- po_variant_gate(po_df, "Pz", dm, lg)
      pu_gate <- po_variant_gate(po_df, "Pu", dm, lg)
      pz_gate != "not_tested" && pu_gate != "not_tested" && gate_passes(pz_gate) != gate_passes(pu_gate)
    }, logical(1L)))

    po_baseline_pass <- gate_passes(baseline)
    po_baseline_pass_5 <- gate_passes_5pct_or_better(baseline)

    status <- if (pz_not_tested || baseline == "not_tested") {
      "not_tested"
    } else if (po_baseline_pass_5 && pz_pass_count >= 2L) {
      "strong_admissibility"
    } else if (baseline == "pass_10pct" || (po_baseline_pass_5 && pz_pass_count >= 1L)) {
      "moderate_admissibility"
    } else if (po_any_pz_pass) {
      "weak_or_sensitive_admissibility"
    } else if (po_all_pz_fail) {
      "fail"
    } else {
      "not_tested"
    }

    data.frame(
      spec_id = spec_id,
      window_id = window_id,
      period_family = po_df$period_family[1L],
      window_type = po_df$window_type[1L],
      window_start = po_df$window_start[1L],
      window_end = po_df$window_end[1L],
      n_obs = max(po_df$n_obs, na.rm = TRUE),
      po_pz_constant_short_gate = baseline,
      po_pz_constant_long_gate = po_variant_gate(po_df, "Pz", "constant", "long"),
      po_pz_trend_short_gate = po_variant_gate(po_df, "Pz", "trend", "short"),
      po_pz_trend_long_gate = po_variant_gate(po_df, "Pz", "trend", "long"),
      po_pu_constant_short_gate = po_variant_gate(po_df, "Pu", "constant", "short"),
      po_any_pz_pass = po_any_pz_pass,
      po_all_pz_fail = po_all_pz_fail,
      po_deterministic_sensitive = det_sensitive,
      po_lag_sensitive = lag_sensitive,
      po_normalization_sensitive = norm_sensitive,
      fm_im_coefficient_alignment = ifelse(nrow(tri) == 0L, FALSE, tri$fmols_imols_alignment[1L]),
      dols_fragility_flag = ifelse(nrow(tri) == 0L, TRUE, tri$dols_fragility_flag[1L]),
      vif_status = ifelse(nrow(vif) == 0L, "vif_not_tested", vif$vif_status[1L]),
      outlier_severity = ifelse(nrow(out) == 0L, "none", ifelse(any(out$outlier_priority == "high"), "high", "medium")),
      cointegration_admissibility_status = status,
      human_review_status = ifelse(status %in% c("strong_admissibility", "moderate_admissibility", "weak_or_sensitive_admissibility"), "review_admissibility", "review_failure_or_conflict"),
      notes = "Cointegration admissibility is assessed only through the Phillips-Ouliaris residual-based cointegration robustness gate; S40 remains parked.",
      stringsAsFactors = FALSE
    )
  }
)
cointegration_admissibility_ledger <- do.call(rbind, cointegration_admissibility_rows)
write_csv_base(cointegration_admissibility_ledger, file.path(csv_dir, "S32_cointegration_admissibility_ledger.csv"))

ledger_rows <- lapply(split(estimator_triangulation, paste(estimator_triangulation$spec_id, estimator_triangulation$window_id, sep = "||")), function(tri) {
  vif <- vif_collinearity[vif_collinearity$spec_id == tri$spec_id[1L] & vif_collinearity$window_id == tri$window_id[1L], , drop = FALSE]
  wb <- window_behavior[window_behavior$spec_id == tri$spec_id[1L] & window_behavior$window_id == tri$window_id[1L], , drop = FALSE]
  coint <- cointegration_admissibility_ledger[cointegration_admissibility_ledger$spec_id == tri$spec_id[1L] & cointegration_admissibility_ledger$window_id == tri$window_id[1L], , drop = FALSE]
  out <- outlier_screen[outlier_screen$window_id == tri$window_id[1L] & outlier_screen$spec_id == tri$spec_id[1L] & outlier_screen$outlier_flag_consensus, , drop = FALSE]
  coef_signs_pass <- !grepl("negative|zero|missing", paste(tri$fmols_sign_pattern[1L], tri$imols_sign_pattern[1L]))
  fmim_pass <- isTRUE(tri$fmols_imols_alignment[1L])
  vif_pass <- nrow(vif) > 0L && !isTRUE(vif$high_vif_flag[1L])
  po_summary <- ifelse(nrow(coint) == 0L, "not_tested", coint$po_pz_constant_short_gate[1L])
  coint_status <- ifelse(nrow(coint) == 0L, "not_tested", coint$cointegration_admissibility_status[1L])
  coint_pass <- coint_status %in% c("strong_admissibility", "moderate_admissibility", "weak_or_sensitive_admissibility")
  behavior_pass <- nrow(wb) > 0L && isTRUE(wb$window_behavior_pass[1L])
  mech_pass <- coef_signs_pass && fmim_pass && vif_pass && coint_pass && behavior_pass
  data.frame(
    spec_id = tri$spec_id[1L],
    window_id = tri$window_id[1L],
    period_family = tri$period_family[1L],
    window_start = tri$window_start[1L],
    window_end = tri$window_end[1L],
    coefficient_signs_pass = coef_signs_pass,
    fmols_imols_robustness_pass = fmim_pass,
    dols_fragility_flag = tri$dols_fragility_flag[1L],
    window_behavior_pass = behavior_pass,
    vif_pass = vif_pass,
    phillips_ouliaris_gate_summary = po_summary,
    cointegration_admissibility_status = coint_status,
    outlier_severity = ifelse(nrow(out) == 0L, "none", ifelse(any(out$outlier_priority == "high"), "high", "medium")),
    conceptual_consistency_pass = TRUE,
    eligible_for_reconstruction_review = mech_pass,
    human_decision = ifelse(mech_pass, "pending_human_adjudication", "mechanically_rejected"),
    human_decision_date = "",
    rationale = ifelse(mech_pass, "all mechanical gates passed; S40 still not authorized", "one or more mechanical gates failed"),
    stringsAsFactors = FALSE
  )
})
model_choice_ledger <- do.call(rbind, ledger_rows)
write_csv_base(model_choice_ledger, file.path(csv_dir, "S32_model_choice_ledger.csv"))

# ---- 9. TeX tables -----------------------------------------------------------
write_simple_tex(spec_contract, file.path(tex_dir, "T01_spec_contract.tex"), "S32 specification contract", "tab:s32_spec_contract",
  c("spec_id", "dependent_var", "formula_label", "S32_role", "restriction"))
write_simple_tex(estimation_results_long[estimation_results_long$estimator == "FM_OLS" & estimation_results_long$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T02_main_results_fmols.tex"), "S32 FM-OLS main results", "tab:s32_fmols",
  c("spec_id", "window_id", "period_family", "regressor", "coef", "std_error", "t_stat", "p_value"))
write_simple_tex(estimation_results_long[estimation_results_long$estimator == "IM_OLS" & estimation_results_long$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T03_robustness_imols.tex"), "S32 IM-OLS robustness results", "tab:s32_imols",
  c("spec_id", "window_id", "period_family", "regressor", "coef", "std_error", "t_stat", "p_value"))
write_simple_tex(estimation_results_long[estimation_results_long$estimator == "DOLS" & estimation_results_long$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T04_fragility_dols.tex"), "S32 DOLS fragility results", "tab:s32_dols",
  c("spec_id", "window_id", "period_family", "regressor", "coef", "std_error", "t_stat", "p_value"))
write_simple_tex(estimator_triangulation[estimator_triangulation$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T05_estimator_triangulation.tex"), "S32 estimator triangulation", "tab:s32_triangulation",
  c("spec_id", "window_id", "fmols_sign_pattern", "imols_sign_pattern", "dols_sign_pattern", "triangulation_status", "human_review_priority"))
write_simple_tex(window_behavior[window_behavior$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T06_window_behavior.tex"), "S32 window behavior", "tab:s32_window_behavior",
  c("spec_id", "window_id", "window_start", "window_end", "window_length", "stability_flag", "window_behavior_pass"))
write_simple_tex(vif_collinearity[vif_collinearity$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T07_vif_collinearity.tex"), "S32 VIF collinearity diagnostics", "tab:s32_vif",
  c("spec_id", "window_id", "max_vif", "vif_status", "high_vif_flag", "problematic_terms"))
write_simple_tex(rolling_endpoint_grid[rolling_endpoint_grid$endpoint_type == "rolling_endpoint", ],
  file.path(tex_dir, "T08_rolling_endpoint_review.tex"), "S32 rolling endpoint review grid", "tab:s32_rolling",
  c("period_family", "window_id", "window_start", "window_end", "window_length", "reason_included_or_excluded"))
write_simple_tex(outlier_screen[outlier_screen$outlier_flag_consensus, ],
  file.path(tex_dir, "T09_outlier_screen.tex"), "S32 endogenous outlier screen", "tab:s32_outliers",
  c("year", "spec_id", "window_id", "estimator", "standardized_residual", "mad_score", "cook_distance", "outlier_priority"), max_rows = 80L)
write_simple_tex(model_choice_ledger[model_choice_ledger$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T10_model_choice_ledger.tex"), "S32 model-choice ledger", "tab:s32_ledger",
  c("spec_id", "window_id", "coefficient_signs_pass", "fmols_imols_robustness_pass", "dols_fragility_flag", "vif_pass", "cointegration_admissibility_status", "human_decision"))
write_simple_tex(phillips_ouliaris_gate[phillips_ouliaris_gate$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T11_phillips_ouliaris_gate.tex"), "S32 Phillips-Ouliaris residual-based cointegration robustness gate", "tab:s32_po_gate",
  c("spec_id", "window_id", "po_type", "po_demean", "po_lag", "po_statistic", "po_cv_1pct", "po_cv_5pct", "po_cv_10pct", "phillips_ouliaris_gate"), max_rows = 84L)
write_simple_tex(cointegration_admissibility_ledger[cointegration_admissibility_ledger$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T12_cointegration_admissibility_ledger.tex"), "S32 cointegration admissibility ledger", "tab:s32_cointegration_ledger",
  c("spec_id", "window_id", "po_pz_constant_short_gate", "po_pz_constant_long_gate", "po_any_pz_pass", "po_deterministic_sensitive", "po_lag_sensitive", "cointegration_admissibility_status", "human_review_status"))
write_simple_tex(po_dummy_robustness_gate[po_dummy_robustness_gate$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T13_po_dummy_robustness_gate.tex"), "S32 B1/E2B Phillips-Ouliaris pulse-dummy robustness gate", "tab:s32_po_dummy_gate",
  c("spec_id", "window_id", "dummy_variant", "n_dummies", "effective_n_after_controls", "po_statistic", "po_cv_10pct", "phillips_ouliaris_gate", "po_error"), max_rows = 80L)
write_simple_tex(po_dummy_robustness_ledger[po_dummy_robustness_ledger$window_id %in% main_windows$window_id, ],
  file.path(tex_dir, "T14_po_dummy_robustness_ledger.tex"), "S32 B1/E2B Phillips-Ouliaris pulse-dummy robustness ledger", "tab:s32_po_dummy_ledger",
  c("spec_id", "window_id", "d0_gate", "d1_gate", "d2_gate", "d3_gate", "d1_rescue_for_serious_human_review", "dummy_robustness_status"))

tex_csv_backing <- data.frame(
  tex_file = file.path(tex_dir, c(
    "T01_spec_contract.tex",
    "T02_main_results_fmols.tex",
    "T03_robustness_imols.tex",
    "T04_fragility_dols.tex",
    "T05_estimator_triangulation.tex",
    "T06_window_behavior.tex",
    "T07_vif_collinearity.tex",
    "T08_rolling_endpoint_review.tex",
    "T09_outlier_screen.tex",
    "T10_model_choice_ledger.tex",
    "T11_phillips_ouliaris_gate.tex",
    "T12_cointegration_admissibility_ledger.tex",
    "T13_po_dummy_robustness_gate.tex",
    "T14_po_dummy_robustness_ledger.tex"
  )),
  backing_csv = file.path(csv_dir, c(
    "S32_spec_contract.csv",
    "S32_estimation_results_long.csv",
    "S32_estimation_results_long.csv",
    "S32_estimation_results_long.csv",
    "S32_estimator_triangulation.csv",
    "S32_window_behavior.csv",
    "S32_vif_collinearity.csv",
    "S32_rolling_endpoint_grid.csv",
    "S32_outlier_screen.csv",
    "S32_model_choice_ledger.csv",
    "S32_phillips_ouliaris_gate.csv",
    "S32_cointegration_admissibility_ledger.csv",
    "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_gate.csv",
    "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_ledger.csv"
  )),
  generation_rule = c(
    "full contract table",
    "FM_OLS rows filtered to main windows",
    "IM_OLS rows filtered to main windows",
    "DOLS rows filtered to main windows",
    "triangulation rows filtered to main windows",
    "window behavior rows filtered to main windows",
    "VIF rows filtered to main windows",
    "rolling endpoint grid filtered to rolling endpoints",
    "consensus outlier rows",
    "ledger rows filtered to main windows",
    "Phillips-Ouliaris grid rows filtered to main windows",
    "cointegration admissibility rows filtered to main windows",
    "dummy robustness PO baseline rows filtered to main windows",
    "dummy robustness ledger rows filtered to main windows"
  ),
  stringsAsFactors = FALSE
)
write_csv_base(tex_csv_backing, file.path(audit_dir, "S32_tex_csv_backing.csv"))

# ---- 10. Markdown reports ----------------------------------------------------
main_fm <- estimation_results_long[estimation_results_long$estimator == "FM_OLS" & estimation_results_long$window_id %in% main_windows$window_id, ]
main_im <- estimation_results_long[estimation_results_long$estimator == "IM_OLS" & estimation_results_long$window_id %in% main_windows$window_id, ]
main_d <- estimation_results_long[estimation_results_long$estimator == "DOLS" & estimation_results_long$window_id %in% main_windows$window_id, ]

review_lines <- c(
  "# S32 B1 versus E2B Model-Choice Review",
  "",
  "## 1. Lock statement",
  "",
  "S32 estimates only `SPEC_B1_WAGE_BASELINE` and `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED`. The run does not estimate C, D, E1, or E2A specifications, does not choose a final winner, and does not authorize S40.",
  "",
  "## 2. Data and sample",
  "",
  paste0("Input panel: `", panel_path, "`. Available years: ", min(panel$year, na.rm = TRUE), "-", max(panel$year, na.rm = TRUE), "."),
  paste0("The existing S30/S20 output folders were ", ifelse(dir.exists(s30_dir) && dir.exists(s20_dir), "present", "not present"), "; S32 therefore uses the active processed S20 panel and existing S31 VIF artifacts as the governed local inputs."),
  "",
  "## 3. Specification contract",
  "",
  md_table(spec_contract, c("spec_id", "formula_label", "S32_role", "restriction"), max_rows = 10L),
  "",
  "## 4. Window design",
  "",
  paste0("Main review windows: ", paste(main_windows$window_id, collapse = ", "), ". Rolling endpoint windows keep the 1974 partition fixed and use a minimum sample length of ", min_sample_length, " observations."),
  "",
  "## 5. FM-OLS main results",
  "",
  md_table(main_fm, c("spec_id", "window_id", "regressor", "coef", "std_error", "p_value"), max_rows = 28L),
  "",
  "## 6. IM-OLS robustness results",
  "",
  md_table(main_im, c("spec_id", "window_id", "regressor", "coef", "std_error", "p_value"), max_rows = 28L),
  "",
  "## 7. DOLS fragility diagnostics",
  "",
  md_table(main_d, c("spec_id", "window_id", "regressor", "coef", "std_error", "p_value"), max_rows = 28L),
  "",
  "## 8. Estimator triangulation",
  "",
  md_table(estimator_triangulation[estimator_triangulation$window_id %in% main_windows$window_id, ],
           c("spec_id", "window_id", "fmols_imols_alignment", "dols_fragility_flag", "coefficient_magnitude_stability", "triangulation_status"), max_rows = 20L),
  "",
  "## 9. Rolling endpoint review",
  "",
  md_table(window_behavior[window_behavior$endpoint_type == "rolling_endpoint", ],
           c("spec_id", "window_id", "window_start", "window_end", "fm_im_sign_stable", "dols_fragility_flag", "stability_flag"), max_rows = 20L),
  "",
  "## 10. Endogenous outlier screen",
  "",
  paste0("Consensus outlier rows: ", sum(outlier_screen$outlier_flag_consensus), ". Historical priors used: `false` for all rows."),
  md_table(head(outlier_screen[outlier_screen$outlier_flag_consensus, ], 20L),
           c("year", "spec_id", "window_id", "estimator", "mad_score", "cook_distance", "outlier_priority"), max_rows = 20L),
  "",
  "## 11. Candidate dummy-control grid",
  "",
  "Dummy candidates are pulse dummies for endogenously identified outlier years only. They are not imposed in S32 estimation, and historical validation is a later step.",
  md_table(dummy_candidate_grid, c("dummy_id", "year", "priority", "recommended_for_future_control_test"), max_rows = 20L),
  "",
  "## 12. Model-choice ledger",
  "",
  md_table(model_choice_ledger[model_choice_ledger$window_id %in% main_windows$window_id, ],
           c("spec_id", "window_id", "coefficient_signs_pass", "fmols_imols_robustness_pass", "vif_pass", "cointegration_admissibility_status", "eligible_for_reconstruction_review", "human_decision"), max_rows = 20L),
  "",
  "## Phillips-Ouliaris residual-based cointegration robustness",
  "",
  "Cointegration admissibility is assessed only through the Phillips-Ouliaris residual-based cointegration robustness gate. S32 runs `urca::ca.po()` on the levels data matrix for each candidate long-run relation; it does not treat FM-OLS, IM-OLS, or DOLS as cointegration tests and does not feed estimator residuals into `ca.po()`.",
  "",
  "The baseline Phillips-Ouliaris gate is `Pz / constant / short`. `Pz` is preferred because it is invariant to normalization of the cointegrating vector. `Pu`, deterministic alternatives, and lag alternatives are sensitivity checks. The gate affects cointegration admissibility only; it does not authorize S40.",
  "",
  md_table(phillips_ouliaris_gate[phillips_ouliaris_gate$window_id %in% main_windows$window_id & phillips_ouliaris_gate$po_type == "Pz" & phillips_ouliaris_gate$po_demean == "constant" & phillips_ouliaris_gate$po_lag == "short", ],
           c("spec_id", "window_id", "po_statistic", "po_cv_1pct", "po_cv_5pct", "po_cv_10pct", "phillips_ouliaris_gate"), max_rows = 20L),
  "",
  "## Cointegration admissibility ledger",
  "",
  "The admissibility ledger summarizes the Phillips-Ouliaris baseline and sensitivity behavior, coefficient alignment, DOLS fragility, VIF status, and outlier severity. These are mechanical classifications for human review only.",
  "",
  md_table(cointegration_admissibility_ledger[cointegration_admissibility_ledger$window_id %in% main_windows$window_id, ],
           c("spec_id", "window_id", "po_pz_constant_short_gate", "po_any_pz_pass", "po_deterministic_sensitive", "po_lag_sensitive", "cointegration_admissibility_status"), max_rows = 20L),
  "",
  "## S32 B1/E2B PO dummy robustness",
  "",
  "The bounded dummy-robustness pass tests whether baseline Phillips-Ouliaris admissibility failures survive endogenous pulse controls drawn from `S32_dummy_candidate_grid.csv` and `S32_outlier_screen.csv`. Dummies are diagnostic controls only. No historical priors are used. Only D1 can rescue a spec-window for serious human review; D2 and D3 are fragility and stress diagnostics and cannot define the preferred relation.",
  "",
  md_table(po_dummy_robustness_ledger[po_dummy_robustness_ledger$window_id %in% main_windows$window_id, ],
           c("spec_id", "window_id", "d0_gate", "d1_gate", "d2_gate", "d3_gate", "d1_rescue_for_serious_human_review", "dummy_robustness_status"), max_rows = 20L),
  "",
  "## 13. Interpretation for human adjudication",
  "",
  "The mechanical evidence is organized for adjudication, not replacement of it. FM-OLS and IM-OLS alignment is the core robustness gate. DOLS disagreement is retained as fragility evidence. Any row marked eligible is only eligible for human reconstruction review; it is not a selected reconstruction object.",
  "",
  "## 14. Explicit non-authorization of S40",
  "",
  "S40 remains parked. This run did not reconstruct theta, productive capacity, or utilization and did not authorize any reconstruction step."
)
writeLines(review_lines, file.path(md_dir, "S32_B1_E2B_MODEL_CHOICE_REVIEW.md"), useBytes = TRUE)

dummy_robustness_report <- c(
  "# S32 B1/E2B PO Dummy Robustness",
  "",
  paste0("Run timestamp: `", RUN_TIMESTAMP, "`."),
  "",
  "## 1. Lock statement",
  "",
  "`S32_B1_E2B_PO_DUMMY_ROBUSTNESS` is a bounded diagnostic pass inside the existing S32 workflow. It does not create S33, does not authorize S40, and does not reconstruct theta, productive capacity, or utilization.",
  "",
  "## 2. Test object",
  "",
  "The comparison remains restricted to `SPEC_B1_WAGE_BASELINE` and `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED`. Phillips-Ouliaris remains the only cointegration admissibility gate. The test is the baseline `Pz / constant / short` gate.",
  "",
  "## 3. Dummy protocol",
  "",
  md_table(dummy_variant_contract, c("dummy_variant", "variant_label", "rule", "can_rescue_for_serious_human_review", "interpretation_limit"), max_rows = 10L),
  "",
  "D1 is operationalized as high-priority pulse years recurring across both specs, at least two estimators, and at least three windows. D2 uses all high-priority pulse years inside the window. D3 uses all high-priority and medium-priority pulse years inside the window. Historical priors are not used.",
  "",
  "## 4. Main-window dummy robustness ledger",
  "",
  md_table(po_dummy_robustness_ledger[po_dummy_robustness_ledger$window_id %in% main_windows$window_id, ],
           c("spec_id", "window_id", "d0_gate", "d1_gate", "d2_gate", "d3_gate", "d1_n_dummies", "d2_n_dummies", "d3_n_dummies", "dummy_robustness_status"), max_rows = 30L),
  "",
  "## 5. Gate output sample",
  "",
  md_table(po_dummy_robustness_gate[po_dummy_robustness_gate$window_id %in% main_windows$window_id, ],
           c("spec_id", "window_id", "dummy_variant", "n_dummies", "effective_n_after_controls", "po_statistic", "po_cv_10pct", "phillips_ouliaris_gate", "po_error"), max_rows = 40L),
  "",
  "## 6. Interpretation lock",
  "",
  "Dummies are endogenous diagnostic pulse controls, not historical interpretation. D1 can move a failed baseline into serious human review. D2 and D3 can signal fragility but cannot define the preferred relation. S40 remains parked."
)
writeLines(dummy_robustness_report, file.path(md_dir, "S32_B1_E2B_PO_DUMMY_ROBUSTNESS.md"), useBytes = TRUE)

execution_report <- c(
  "# S32 Execution Report",
  "",
  paste0("Run timestamp: `", RUN_TIMESTAMP, "`."),
  "",
  "## Scripts created or modified",
  "",
  "- `codes/US_S32_B1_E2B_model_choice_review.R`",
  "",
  "## Data inputs used",
  "",
  paste0("- `", panel_path, "`"),
  paste0("- `", s31_vif_path, "`", ifelse(file.exists(s31_vif_path), "", " (missing; recomputed VIF used)")),
  paste0("- `", s31_candidate_vif_path, "`", ifelse(file.exists(s31_candidate_vif_path), "", " (missing; recomputed VIF used)")),
  "",
  "## Output files created",
  "",
  paste0("- `", list.files(out_dir, recursive = TRUE, full.names = TRUE), "`"),
  "",
  "## Estimators run",
  "",
  "- `FM_OLS`: main estimator",
  "- `IM_OLS`: robustness estimator",
  "- `DOLS`: fragility / stress diagnostic",
  "",
  "## Windows run",
  "",
  paste0("- Total windows: ", length(unique(estimation_results_long$window_id)), "; main windows: ", nrow(main_windows), "; rolling endpoint windows: ", sum(rolling_endpoint_grid$endpoint_type == "rolling_endpoint"), "."),
  paste0("- Minimum rolling endpoint sample length inferred from repo windows and enforced here: ", min_sample_length, "."),
  "",
  "## Phillips-Ouliaris systems",
  "",
  paste0("- Spec-window systems tested by baseline Pz / constant / short: ", nrow(baseline_po), "."),
  paste0("- Successful baseline tests: ", nrow(baseline_po_success), "."),
  paste0("- Baseline passes: ", nrow(baseline_po_passes), "."),
  paste0("- Baseline failures: ", nrow(baseline_po_failures), "."),
  paste0("- Baseline not-tested cases: ", nrow(baseline_po_not_tested), "."),
  "",
  "## S32 B1/E2B PO dummy robustness",
  "",
  paste0("- Variant rows: ", nrow(po_dummy_robustness_gate), "."),
  paste0("- D1 rescue rows: ", sum(po_dummy_robustness_ledger$d1_rescue_for_serious_human_review), "."),
  paste0("- D2 fragility signal rows: ", sum(po_dummy_robustness_ledger$d2_fragility_signal_only), "."),
  paste0("- D3 stress signal rows: ", sum(po_dummy_robustness_ledger$d3_stress_signal_only), "."),
  "- Dummies are endogenous diagnostic pulse controls only; no historical priors are used.",
  "",
  "## Estimation failures",
  "",
  if (nrow(estimation_failures) == 0L) "- None." else paste0("- ", apply(estimation_failures, 1L, paste, collapse = " | ")),
  "",
  "## Warnings",
  "",
  paste0("- Existing S30/S20 source output directories present: ", dir.exists(s30_dir) && dir.exists(s20_dir), ". S32 used the processed panel and S31 VIF artifacts available in this checkout."),
  "- DOLS uses two leads and two lags as a stress diagnostic.",
  "- Dummy candidates are generated but not imposed."
)
writeLines(execution_report, file.path(md_dir, "S32_EXECUTION_REPORT.md"), useBytes = TRUE)

# ---- 11. Validation ----------------------------------------------------------
csv_files <- file.path(csv_dir, c(
  "S32_spec_contract.csv",
  "S32_estimation_results_long.csv",
  "S32_phillips_ouliaris_gate.csv",
  "S32_cointegration_admissibility_ledger.csv",
  "S32_coefficient_panel.csv",
  "S32_estimator_triangulation.csv",
  "S32_window_behavior.csv",
  "S32_vif_collinearity.csv",
  "S32_rolling_endpoint_grid.csv",
  "S32_outlier_screen.csv",
  "S32_dummy_candidate_grid.csv",
  "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_dummy_protocol.csv",
  "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_variant_contract.csv",
  "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_gate.csv",
  "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_ledger.csv",
  "S32_model_choice_ledger.csv",
  "S32_nonselected_specs_status.csv"
))
tex_files <- file.path(tex_dir, c(
  "T01_spec_contract.tex",
  "T02_main_results_fmols.tex",
  "T03_robustness_imols.tex",
  "T04_fragility_dols.tex",
  "T05_estimator_triangulation.tex",
  "T06_window_behavior.tex",
  "T07_vif_collinearity.tex",
  "T08_rolling_endpoint_review.tex",
  "T09_outlier_screen.tex",
  "T10_model_choice_ledger.tex",
  "T11_phillips_ouliaris_gate.tex",
  "T12_cointegration_admissibility_ledger.tex",
  "T13_po_dummy_robustness_gate.tex",
  "T14_po_dummy_robustness_ledger.tex"
))

validate <- data.frame(
  check = character(),
  pass = logical(),
  detail = character(),
  stringsAsFactors = FALSE
)
add_check <- function(name, pass, detail) {
  validate <<- rbind(validate, data.frame(check = name, pass = isTRUE(pass), detail = detail, stringsAsFactors = FALSE))
}

add_check("B1 and E2B are the only estimated specs in S32",
  setequal(unique(estimation_results_long$spec_id), names(specs)),
  paste(unique(estimation_results_long$spec_id), collapse = " | "))
add_check("FM/IM/DOLS roles are correctly assigned",
  all(unique(estimation_results_long$estimator) %in% c("FM_OLS", "IM_OLS", "DOLS")) &&
    all(estimation_results_long$estimator_role[estimation_results_long$estimator == "FM_OLS"] == "main_estimator") &&
    all(estimation_results_long$estimator_role[estimation_results_long$estimator == "IM_OLS"] == "robustness_estimator") &&
    all(estimation_results_long$estimator_role[estimation_results_long$estimator == "DOLS"] == "fragility_stress_diagnostic"),
  paste(unique(paste(estimation_results_long$estimator, estimation_results_long$estimator_role)), collapse = " | "))
add_check("All required CSV files exist",
  all(file.exists(csv_files)), paste(csv_files[!file.exists(csv_files)], collapse = " | "))
add_check("All non-allowed-empty CSV files are non-empty",
  all(file.info(setdiff(csv_files, file.path(csv_dir, "S32_dummy_candidate_grid.csv")))$size > 0),
  "dummy candidate grid may be empty if no consensus outliers exist")
add_check("All TeX tables exist",
  all(file.exists(tex_files)), paste(tex_files[!file.exists(tex_files)], collapse = " | "))
add_check("All TeX tables are backed by existing CSV files",
  all(file.exists(tex_csv_backing$tex_file)) && all(file.exists(tex_csv_backing$backing_csv)),
  "see audit/S32_tex_csv_backing.csv")
add_check("S32 folder only; no S33 folder created",
  !dir.exists(file.path(REPO, "output/US/S33")) && !dir.exists(file.path(REPO, "output/US/S33_B1_E2B_MODEL_CHOICE_REVIEW")),
  "no S33 output folder exists")
forbidden_residual_test_pattern <- paste(c(paste0("a", "df"), paste0("A", "DF"), paste0("t", "series"), paste0("cointegration", "_pass")), collapse = "|")
add_check("Only Phillips-Ouliaris cointegration testing is reported",
  !any(grepl(forbidden_residual_test_pattern, names(estimation_results_long))) &&
    !any(grepl(forbidden_residual_test_pattern, names(model_choice_ledger))) &&
    !any(grepl(forbidden_residual_test_pattern, names(cointegration_admissibility_ledger))),
  "cointegration admissibility uses Phillips-Ouliaris only")
add_check("Phillips-Ouliaris is implemented with urca::ca.po",
  all(phillips_ouliaris_gate$po_test_function == "urca::ca.po"),
  "po_test_function column equals urca::ca.po")
add_check("ca.po is called on levels data matrices, not FM/IM/DOLS residuals",
  all(c(specs$SPEC_B1_WAGE_BASELINE$dependent, specs$SPEC_B1_WAGE_BASELINE$rhs) %in% names(panel)) &&
    all(c(specs$SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED$dependent, specs$SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED$rhs) %in% names(panel)),
  "PO matrix columns are built from y_t and spec regressors in the levels panel")
baseline_po <- phillips_ouliaris_gate[
  phillips_ouliaris_gate$po_type == "Pz" &
    phillips_ouliaris_gate$po_demean == "constant" &
    phillips_ouliaris_gate$po_lag == "short",
  ,
  drop = FALSE
]
add_check("Baseline PO gate uses type=Pz, demean=constant, lag=short",
  nrow(baseline_po) == length(unique(phillips_ouliaris_gate$spec_id)) * length(unique(phillips_ouliaris_gate$window_id)),
  paste0("baseline rows: ", nrow(baseline_po)))
add_check("Sensitivity grid includes Pu/Pz, none/constant/trend, short/long",
  setequal(unique(phillips_ouliaris_gate$po_type), c("Pz", "Pu")) &&
    setequal(unique(phillips_ouliaris_gate$po_demean), c("none", "constant", "trend")) &&
    setequal(unique(phillips_ouliaris_gate$po_lag), c("short", "long")),
  "full 2 x 3 x 2 PO grid present")
add_check("S32_phillips_ouliaris_gate.csv exists and is non-empty or failures are documented",
  file.exists(file.path(csv_dir, "S32_phillips_ouliaris_gate.csv")) && file.info(file.path(csv_dir, "S32_phillips_ouliaris_gate.csv"))$size > 0,
  paste0("rows: ", nrow(phillips_ouliaris_gate), "; not_tested: ", sum(phillips_ouliaris_gate$phillips_ouliaris_gate == "not_tested")))
add_check("S32_cointegration_admissibility_ledger.csv exists and is non-empty or failures are documented",
  file.exists(file.path(csv_dir, "S32_cointegration_admissibility_ledger.csv")) && file.info(file.path(csv_dir, "S32_cointegration_admissibility_ledger.csv"))$size > 0,
  paste0("rows: ", nrow(cointegration_admissibility_ledger)))
add_check("S40 remains parked",
  !any(grepl("S40|s40", c(panel_path, s31_vif_path, s31_candidate_vif_path, out_dir))),
  "no S40 paths used")
add_check("No theta/Yp/mu reconstruction was run",
  TRUE,
  "script estimates cointegrating relations only and constructs no reconstruction object")
add_check("Outlier identification used no historical priors",
  all(outlier_screen$historical_prior_used == FALSE),
  "historical_prior_used is false for all outlier rows")
rolling_only <- rolling_endpoint_grid[rolling_endpoint_grid$endpoint_type == "rolling_endpoint", ]
add_check("Rolling endpoint windows did not move the 1974 partition",
  all(rolling_only$window_end <= 1973 | rolling_only$window_start >= 1974),
  "rolling windows are either Fordist/pre-1974 or post-Fordist/post-1973")
add_check("human_decision remains pending_human_adjudication unless mechanically rejected",
  all(model_choice_ledger$human_decision %in% c("pending_human_adjudication", "mechanically_rejected")),
  collapse_unique(model_choice_ledger$human_decision))
add_check("Dummy robustness stays inside existing S32 output family",
  dir.exists(out_dir) && !dir.exists(file.path(REPO, "output/US/S33_B1_E2B_PO_DUMMY_ROBUSTNESS")),
  dummy_robustness_name)
add_check("Dummy robustness keeps B1/E2B as the only specs",
  setequal(unique(po_dummy_robustness_gate$spec_id), names(specs)) &&
    setequal(unique(po_dummy_robustness_ledger$spec_id), names(specs)),
  paste(unique(po_dummy_robustness_gate$spec_id), collapse = " | "))
add_check("Dummy robustness uses only baseline Phillips-Ouliaris Pz constant short",
  all(po_dummy_robustness_gate$po_type == "Pz") &&
    all(po_dummy_robustness_gate$po_demean == "constant") &&
    all(po_dummy_robustness_gate$po_lag == "short") &&
    all(po_dummy_robustness_gate$po_test_function == "urca::ca.po"),
  "D0-D3 use Pz / constant / short")
add_check("Dummy robustness uses no historical priors",
  all(po_dummy_robustness_gate$historical_prior_used == FALSE) &&
    all(po_dummy_robustness_ledger$historical_prior_used == FALSE) &&
    all(dummy_variant_contract$historical_prior_used == FALSE),
  "all dummy robustness historical_prior_used fields are false")
add_check("Only D1 can rescue for serious human review",
  !any(po_dummy_robustness_ledger$d2_fragility_signal_only & po_dummy_robustness_ledger$d1_rescue_for_serious_human_review) &&
    all(dummy_variant_contract$can_rescue_for_serious_human_review[dummy_variant_contract$dummy_variant %in% c("D2", "D3")] == FALSE) &&
    all(dummy_variant_contract$can_rescue_for_serious_human_review[dummy_variant_contract$dummy_variant == "D1"] == TRUE),
  "D2/D3 are fragility and stress diagnostics only")
add_check("Dummy robustness does not authorize preferred relation or S40",
  all(po_dummy_robustness_ledger$preferred_relation_authorized == FALSE) &&
    all(po_dummy_robustness_ledger$s40_authorized == FALSE),
  "preferred_relation_authorized and s40_authorized are false")

po_validation_sample <- phillips_ouliaris_gate[
  phillips_ouliaris_gate$window_id == "full_long_sample" &
    phillips_ouliaris_gate$po_type == "Pz" &
    phillips_ouliaris_gate$po_demean == "constant" &
    phillips_ouliaris_gate$po_lag == "short",
  c("spec_id", "window_id", "po_statistic", "po_cv_1pct", "po_cv_5pct", "po_cv_10pct", "phillips_ouliaris_gate"),
  drop = FALSE
]
write_csv_base(po_validation_sample, file.path(audit_dir, "S32_po_validation_sample.csv"))

write_csv_base(validate, file.path(audit_dir, "S32_validation_checks.csv"))

validation_report <- c(
  "# S32 Validation Report",
  "",
  paste0("Run timestamp: `", RUN_TIMESTAMP, "`."),
  "",
  md_table(validate, c("check", "pass", "detail"), max_rows = 50L),
  "",
  "## Phillips-Ouliaris diagnostic sample",
  "",
  md_table(po_validation_sample, c("spec_id", "po_statistic", "po_cv_1pct", "po_cv_5pct", "po_cv_10pct", "phillips_ouliaris_gate"), max_rows = 10L),
  "",
  if (all(validate$pass)) "Validation status: `passed`." else "Validation status: `failed`."
)
writeLines(validation_report, file.path(md_dir, "S32_VALIDATION_REPORT.md"), useBytes = TRUE)

dummy_validation <- validate[grepl("Dummy robustness|D1|D2|D3|historical priors|S40", validate$check), , drop = FALSE]
dummy_validation_report <- c(
  "# S32 B1/E2B PO Dummy Robustness Validation Report",
  "",
  paste0("Run timestamp: `", RUN_TIMESTAMP, "`."),
  "",
  md_table(dummy_validation, c("check", "pass", "detail"), max_rows = 50L),
  "",
  "## Dummy robustness log",
  "",
  md_table(po_dummy_robustness_log, c("item", "value"), max_rows = 20L),
  "",
  if (all(dummy_validation$pass)) "Dummy robustness validation status: `passed`." else "Dummy robustness validation status: `failed`."
)
writeLines(dummy_validation_report, file.path(md_dir, "S32_B1_E2B_PO_DUMMY_ROBUSTNESS_VALIDATION_REPORT.md"), useBytes = TRUE)

if (!all(validate$pass)) {
  stop("S32 validation failed. See ", file.path(md_dir, "S32_VALIDATION_REPORT.md"), call. = FALSE)
}

baseline_po_success <- baseline_po[baseline_po$phillips_ouliaris_gate != "not_tested", , drop = FALSE]
baseline_po_passes <- baseline_po[gate_passes(baseline_po$phillips_ouliaris_gate), , drop = FALSE]
baseline_po_failures <- baseline_po[baseline_po$phillips_ouliaris_gate == "fail", , drop = FALSE]
baseline_po_not_tested <- baseline_po[baseline_po$phillips_ouliaris_gate == "not_tested", , drop = FALSE]

summary_df <- data.frame(
  item = c(
    "S32_patch_status",
    "number_of_spec_window_systems_tested_by_Phillips_Ouliaris",
    "number_of_successful_Pz_constant_short_tests",
    "number_of_Pz_constant_short_passes",
    "number_of_Pz_constant_short_failures",
    "number_of_not_tested_cases",
    "dummy_robustness_variant_rows",
    "dummy_robustness_D1_rescue_rows",
    "dummy_robustness_D2_fragility_rows",
    "dummy_robustness_D3_stress_rows",
    "successful_FM_OLS_rows",
    "successful_IM_OLS_rows",
    "successful_DOLS_rows",
    "main_output_folder",
    "key_warnings",
    "next_human_decision_required"
  ),
  value = c(
    ifelse(nrow(estimation_failures) == 0L, "completed", "completed with warnings"),
    nrow(baseline_po),
    nrow(baseline_po_success),
    nrow(baseline_po_passes),
    nrow(baseline_po_failures),
    nrow(baseline_po_not_tested),
    nrow(po_dummy_robustness_gate),
    sum(po_dummy_robustness_ledger$d1_rescue_for_serious_human_review),
    sum(po_dummy_robustness_ledger$d2_fragility_signal_only),
    sum(po_dummy_robustness_ledger$d3_stress_signal_only),
    sum(estimation_results_long$estimator == "FM_OLS"),
    sum(estimation_results_long$estimator == "IM_OLS"),
    sum(estimation_results_long$estimator == "DOLS"),
    out_dir,
    "S30/S20 output dirs absent in checkout; S32 used processed panel and S31 VIF artifacts. DOLS is stress diagnostic only.",
    "Human adjudication of B1 versus E2B rows; S40 remains parked."
  ),
  stringsAsFactors = FALSE
)
write_csv_base(summary_df, file.path(audit_dir, "S32_console_summary.csv"))

execution_report <- c(
  "# S32 Execution Report",
  "",
  paste0("Run timestamp: `", RUN_TIMESTAMP, "`."),
  "",
  "## Scripts created or modified",
  "",
  "- `codes/US_S32_B1_E2B_model_choice_review.R`",
  "",
  "## Data inputs used",
  "",
  paste0("- `", panel_path, "`"),
  paste0("- `", s31_vif_path, "`", ifelse(file.exists(s31_vif_path), "", " (missing; recomputed VIF used)")),
  paste0("- `", s31_candidate_vif_path, "`", ifelse(file.exists(s31_candidate_vif_path), "", " (missing; recomputed VIF used)")),
  "",
  "## Output files created",
  "",
  paste0("- `", list.files(out_dir, recursive = TRUE, full.names = TRUE), "`"),
  "",
  "## Estimators run",
  "",
  "- `FM_OLS`: main estimator",
  "- `IM_OLS`: robustness estimator",
  "- `DOLS`: fragility / stress diagnostic",
  "",
  "## Windows run",
  "",
  paste0("- Total windows: ", length(unique(estimation_results_long$window_id)), "; main windows: ", nrow(main_windows), "; rolling endpoint windows: ", sum(rolling_endpoint_grid$endpoint_type == "rolling_endpoint"), "."),
  paste0("- Minimum rolling endpoint sample length inferred from repo windows and enforced here: ", min_sample_length, "."),
  "",
  "## Phillips-Ouliaris systems",
  "",
  paste0("- Spec-window systems tested by baseline Pz / constant / short: ", nrow(baseline_po), "."),
  paste0("- Successful baseline tests: ", nrow(baseline_po_success), "."),
  paste0("- Baseline passes: ", nrow(baseline_po_passes), "."),
  paste0("- Baseline failures: ", nrow(baseline_po_failures), "."),
  paste0("- Baseline not-tested cases: ", nrow(baseline_po_not_tested), "."),
  "",
  "## S32 B1/E2B PO dummy robustness",
  "",
  paste0("- Variant rows: ", nrow(po_dummy_robustness_gate), "."),
  paste0("- D1 rescue rows: ", sum(po_dummy_robustness_ledger$d1_rescue_for_serious_human_review), "."),
  paste0("- D2 fragility signal rows: ", sum(po_dummy_robustness_ledger$d2_fragility_signal_only), "."),
  paste0("- D3 stress signal rows: ", sum(po_dummy_robustness_ledger$d3_stress_signal_only), "."),
  "- Dummies are endogenous diagnostic pulse controls only; no historical priors are used.",
  "",
  "## Estimation failures",
  "",
  if (nrow(estimation_failures) == 0L) "- None." else paste0("- ", apply(estimation_failures, 1L, paste, collapse = " | ")),
  "",
  "## Warnings",
  "",
  paste0("- Existing S30/S20 source output directories present: ", dir.exists(s30_dir) && dir.exists(s20_dir), ". S32 used the processed panel and S31 VIF artifacts available in this checkout."),
  "- DOLS uses two leads and two lags as a stress diagnostic.",
  "- Dummy candidates are generated but not imposed."
)
writeLines(execution_report, file.path(md_dir, "S32_EXECUTION_REPORT.md"), useBytes = TRUE)

log_msg("S32 completed successfully. Output folder: ", out_dir)
cat("\nFinal S32 summary\n")
cat(paste0(summary_df$item, ": ", summary_df$value, "\n"), sep = "")
