###############################################################################
# US_S31_model_choice_vif_screen.R
# Chapter 2 - US S31 governed VIF screen for model-choice review
#
# Role:
#   S31 consumes existing S20/S31 outputs, computes VIF-only diagnostics for
#   A05 E candidate specifications, and combines them with existing S31 VIF
#   diagnostics for human model-choice review.
#
# Guardrails:
#   - Does not estimate FM-OLS, IM-OLS, DOLS, OLS, or any coefficient model.
#   - Does not modify S30 outputs.
#   - Does not read S40 outputs.
#   - Does not reconstruct theta_tot.
#   - Does not reconstruct productive capacity or Yp.
#   - Does not compute mu.
#   - Does not choose an anchor.
#   - Does not select a final model.
#   - Does not mark any specification as promoted_for_reconstruction.
###############################################################################

# ---- 0. Paths ----------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")

panel_path <- file.path(REPO, "data/processed/US/us_s20_admissibility_panel.csv")
s31_tables_dir <- file.path(REPO, "output/US/S31_estimation_tables_tex")
s30_dir <- file.path(REPO, "output/US/S30_transformation_relation")
out_dir <- file.path(REPO, "output/US/S31_model_choice_vif_screen")

input_paths <- c(
  s20_panel = panel_path,
  existing_s31_vif = file.path(s31_tables_dir, "us_s31_vif_diagnostics_tidy.csv"),
  existing_s31_manifest = file.path(s31_tables_dir, "us_s31_estimation_table_manifest.csv"),
  existing_s31_window_register = file.path(s31_tables_dir, "us_s31_window_inclusion_register.csv"),
  existing_s31_report = file.path(s31_tables_dir, "US_S31_estimation_tables_report.md")
)

optional_input_paths <- c(
  s30_specification_register = file.path(s30_dir, "us_s30_specification_register.csv"),
  s30_estimator_grid = file.path(s30_dir, "us_s30_estimator_grid.csv"),
  s30_window_stability_summary = file.path(s30_dir, "us_s30_window_stability_summary.csv")
)

output_paths <- c(
  candidate_tidy = file.path(out_dir, "us_s31_candidate_mechanization_vif_tidy.csv"),
  candidate_tex = file.path(out_dir, "us_s31_candidate_mechanization_vif.tex"),
  screen_tidy = file.path(out_dir, "us_s31_model_choice_vif_screen_tidy.csv"),
  screen_tex = file.path(out_dir, "us_s31_model_choice_vif_screen.tex"),
  manifest = file.path(out_dir, "us_s31_model_choice_vif_screen_manifest.csv"),
  report = file.path(out_dir, "US_S31_model_choice_vif_screen_report.md")
)

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

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
  year_start = c(1929, 1929, 1974, 1945, 1940, 1940, 1947),
  year_end = c(2024, 1973, 2024, 1973, 1978, 1973, 1974),
  stringsAsFactors = FALSE
)

existing_screen_specs <- c(
  "SPEC_B1_WAGE_BASELINE",
  "SPEC_C1_COMPOSITION_STOCK",
  "SPEC_C2_FULL_COMPOSITION",
  "SPEC_D1_CURRENT_COST_DIAGNOSTIC",
  "SPEC_D2_PRICE_WEDGE_DIAGNOSTIC"
)

candidate_specs <- list(
  SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS = list(
    formula_label = "VIF only: y_t ~ k_NRC_proxy_t + m_ME_NRC_t",
    rhs = c("k_NRC_proxy_t", "m_ME_NRC_t"),
    distribution_conditioned_variable = ""
  ),
  SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL = list(
    formula_label = "VIF only: y_t ~ k_NRC_proxy_t + m_ME_NRC_t + omega_m_ME_NRC_t",
    rhs = c("k_NRC_proxy_t", "m_ME_NRC_t", "omega_m_ME_NRC_t"),
    distribution_conditioned_variable = "omega_m_ME_NRC_t"
  ),
  SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED = list(
    formula_label = "VIF only: y_t ~ k_NRC_proxy_t + omega_m_ME_NRC_t",
    rhs = c("k_NRC_proxy_t", "omega_m_ME_NRC_t"),
    distribution_conditioned_variable = "omega_m_ME_NRC_t"
  )
)

spec_classification <- data.frame(
  spec_id = c(existing_screen_specs, names(candidate_specs)),
  specification_layer = c(
    "A00_baseline",
    "A03_proxy_escalation",
    "A03_proxy_escalation",
    "diagnostic_only",
    "diagnostic_only",
    "A03_candidate",
    "A03_candidate",
    "A03_candidate"
  ),
  architecture_layer = c(
    "A00",
    "A03",
    "A03",
    "diagnostic",
    "diagnostic",
    "A03_candidate",
    "A03_candidate",
    "A03_candidate"
  ),
  screen_role = c(
    "baseline_review_object",
    "proxy_escalation_review_object",
    "proxy_escalation_review_object",
    "diagnostic_only",
    "diagnostic_only",
    "candidate_vif_only",
    "candidate_vif_only",
    "candidate_vif_only"
  ),
  promotable_in_principle = c(TRUE, TRUE, TRUE, FALSE, FALSE, FALSE, FALSE, FALSE),
  estimated_status = c(
    "estimated_in_S30",
    "estimated_in_S30",
    "estimated_in_S30",
    "estimated_in_S30",
    "estimated_in_S30",
    "not_estimated_vif_only",
    "not_estimated_vif_only",
    "not_estimated_vif_only"
  ),
  stringsAsFactors = FALSE
)

# ---- 1. Helpers --------------------------------------------------------------
read_csv_base <- function(path, check_names = FALSE) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = check_names)
}

write_csv_base <- function(df, path) {
  utils::write.csv(df, path, row.names = FALSE, na = "")
}

require_files <- function(paths) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0L) {
    stop(
      "S31 model-choice VIF screen cannot run because required input files are missing:\n  ",
      paste(missing, collapse = "\n  "),
      call. = FALSE
    )
  }
  invisible(TRUE)
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

assert_no_s40_inputs <- function(paths) {
  normalized <- gsub("\\\\", "/", paths)
  blocked <- normalized[grepl("output/US/S40_", normalized, fixed = FALSE)]
  if (length(blocked) > 0L) {
    stop(
      "Internal guardrail failure: S40 output path appears in input list:\n  ",
      paste(blocked, collapse = "\n  "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

as_num <- function(x) suppressWarnings(as.numeric(x))

as_bool <- function(x) {
  if (is.logical(x)) return(x)
  y <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(y))
  out[y %in% c("true", "t", "1", "yes", "y")] <- TRUE
  out[y %in% c("false", "f", "0", "no", "n")] <- FALSE
  out
}

finite_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  mean(x)
}

finite_max <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  max(x)
}

finite_median <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  stats::median(x)
}

collapse_nonempty <- function(x) {
  x <- unique(trimws(as.character(x)))
  x <- x[nzchar(x) & !is.na(x)]
  if (length(x) == 0L) return("")
  paste(sort(x), collapse = " | ")
}

vif_status <- function(vif) {
  if (!is.finite(vif)) return("not_meaningful")
  if (vif < 5) return("low")
  if (vif < 10) return("moderate")
  "high"
}

spec_window_vif_status <- function(max_vif) {
  if (!is.finite(max_vif)) return("vif_not_meaningful")
  if (max_vif < 5) return("vif_pass_low")
  if (max_vif < 10) return("vif_review_moderate")
  "vif_block_high"
}

format_num <- function(x, digits = 3L) {
  x <- suppressWarnings(as.numeric(x))
  if (!is.finite(x)) return("")
  formatC(x, format = "f", digits = digits)
}

latex_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([#$%&_{}])", "\\\\\\1", x, perl = TRUE)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x
}

write_lines <- function(lines, path) {
  writeLines(lines, path, useBytes = TRUE)
}

compute_vif_from_correlation <- function(df, rhs) {
  if (length(rhs) == 0L) return(numeric(0))
  if (length(rhs) == 1L) return(setNames(NA_real_, rhs))

  d <- df[, rhs, drop = FALSE]
  d[] <- lapply(d, as_num)
  d <- d[stats::complete.cases(d), , drop = FALSE]
  if (nrow(d) <= length(rhs)) return(setNames(rep(NA_real_, length(rhs)), rhs))

  vars <- vapply(d, stats::var, numeric(1), na.rm = TRUE)
  if (any(!is.finite(vars)) || any(vars == 0)) {
    return(setNames(rep(NA_real_, length(rhs)), rhs))
  }

  r <- stats::cor(d)
  inv <- tryCatch(solve(r), error = function(e) NULL)
  if (is.null(inv)) return(setNames(rep(Inf, length(rhs)), rhs))
  out <- diag(inv)
  names(out) <- colnames(inv)
  out[rhs]
}

screen_note <- function(max_vif, high_vars) {
  if (!is.finite(max_vif)) return("VIF not meaningful for this cell.")
  if (max_vif < 5) return("Low VIF; no collinearity block for review.")
  if (max_vif < 10) return("Moderate VIF; review coefficient interpretation with caution.")
  paste0("High VIF block for review variables: ", high_vars)
}

write_candidate_tex <- function(df, path) {
  sw <- unique(df[, c(
    "spec_id", "window_id", "year_start", "year_end", "n_obs",
    "max_vif_in_spec_window", "high_vif_variables", "collinearity_flag"
  ), drop = FALSE])
  sw$note <- mapply(screen_note, sw$max_vif_in_spec_window, sw$high_vif_variables)
  sw <- sw[order(sw$spec_id, sw$year_start, sw$year_end, sw$window_id), ]

  row_lines <- apply(sw, 1L, function(z) {
    paste(
      latex_escape(z["spec_id"]),
      latex_escape(z["window_id"]),
      paste0(latex_escape(z["year_start"]), "--", latex_escape(z["year_end"])),
      latex_escape(z["n_obs"]),
      format_num(z["max_vif_in_spec_window"]),
      latex_escape(z["high_vif_variables"]),
      latex_escape(z["collinearity_flag"]),
      latex_escape(z["note"]),
      sep = " & "
    )
  })

  lines <- c(
    "\\begin{table}[!htbp]",
    "\\centering",
    "\\small",
    "\\caption{US S31 Candidate NRC-Envelope / Mechanization-Bias VIF Diagnostics}",
    "\\label{tab:us_s31_candidate_mechanization_vif}",
    "\\begin{tabular}{lllrrlll}",
    "\\hline",
    "Spec & Window & Years & N & Max VIF & High-VIF variables & Flag & Diagnostic note \\\\",
    "\\hline",
    paste0(row_lines, " \\\\"),
    "\\hline",
    "\\end{tabular}",
    "\\begin{minipage}{0.98\\textwidth}",
    "\\footnotesize \\textit{Note:} These specifications are VIF-only candidate diagnostics. They are not estimated S30 specifications and report no coefficients. The envelope variable is log real NRC capital. The mechanization-bias variable is log(ME/NRC), so higher values indicate greater machinery intensity relative to the NRC envelope. VIF is a collinearity feasibility diagnostic and does not adjudicate cointegration or select a final model.",
    "\\end{minipage}",
    "\\end{table}"
  )
  write_lines(lines, path)
}

write_screen_tex <- function(df, path) {
  layer_order <- c("A00_baseline", "A03_proxy_escalation", "A03_candidate", "diagnostic_only")
  df$.layer_order <- match(df$specification_layer, layer_order)
  df <- df[order(df$.layer_order, df$spec_id), ]

  row_lines <- apply(df, 1L, function(z) {
    paste(
      latex_escape(z["spec_id"]),
      latex_escape(z["specification_layer"]),
      latex_escape(z["estimated_status"]),
      format_num(z["max_vif_all_windows"]),
      latex_escape(z["n_high_vif_windows"]),
      latex_escape(z["worst_window_id"]),
      latex_escape(z["vif_screen_recommendation"]),
      latex_escape(z["final_screen_status"]),
      sep = " & "
    )
  })

  lines <- c(
    "\\begin{table}[!htbp]",
    "\\centering",
    "\\small",
    "\\caption{US S31 VIF Screen for Model-Choice Review}",
    "\\label{tab:us_s31_model_choice_vif_screen}",
    "\\begin{tabular}{lllrrlll}",
    "\\hline",
    "Spec & Layer & Estimated status & Max VIF & High windows & Worst window & VIF recommendation & Final screen status \\\\",
    "\\hline",
    paste0(row_lines, " \\\\"),
    "\\hline",
    "\\end{tabular}",
    "\\begin{minipage}{0.98\\textwidth}",
    "\\footnotesize \\textit{Note:} VIF is a collinearity screen for coefficient interpretation. It does not adjudicate cointegration, does not select a final model, and does not authorize S40 reconstruction. A00/B1 remains the baseline review object. A03 proxy specifications and A03 candidate specifications require human adjudication before any further use.",
    "\\end{minipage}",
    "\\end{table}"
  )
  write_lines(lines, path)
}

# ---- 2. Validate inputs ------------------------------------------------------
assert_no_s40_inputs(c(input_paths, optional_input_paths))
require_files(input_paths)

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

panel <- read_csv_base(input_paths["s20_panel"], check_names = TRUE)
existing_vif <- read_csv_base(input_paths["existing_s31_vif"], check_names = TRUE)
existing_manifest <- read_csv_base(input_paths["existing_s31_manifest"], check_names = TRUE)
window_register <- read_csv_base(input_paths["existing_s31_window_register"], check_names = TRUE)
existing_report <- readLines(input_paths["existing_s31_report"], warn = FALSE)

require_cols(
  panel,
  c("year", "omega_t", "K_ME_gross_real", "K_NRC_gross_real"),
  "us_s20_admissibility_panel.csv"
)
require_cols(
  existing_vif,
  c(
    "country", "stage", "spec_id", "spec_family", "architecture_layer",
    "window_id", "year_start", "year_end", "n_obs", "rhs_variable", "vif",
    "vif_status", "max_vif_in_spec_window", "mean_vif_in_spec_window",
    "collinearity_flag", "diagnostic_role"
  ),
  "us_s31_vif_diagnostics_tidy.csv"
)
require_cols(existing_manifest, c("item", "value"), "us_s31_estimation_table_manifest.csv")
require_cols(
  window_register,
  c("window_id", "year_start", "year_end", "included_in_main_s31_tables"),
  "us_s31_window_inclusion_register.csv"
)

missing_windows <- setdiff(main_windows$window_id, unique(existing_vif$window_id))
if (length(missing_windows) > 0L) {
  stop(
    "Existing S31 VIF diagnostics lack required main windows: ",
    paste(missing_windows, collapse = ", "),
    call. = FALSE
  )
}

missing_existing_specs <- setdiff(existing_screen_specs, unique(existing_vif$spec_id))
if (length(missing_existing_specs) > 0L) {
  stop(
    "Existing S31 VIF diagnostics lack required specs: ",
    paste(missing_existing_specs, collapse = ", "),
    call. = FALSE
  )
}

optional_inputs_used <- optional_input_paths[file.exists(optional_input_paths)]
assert_no_s40_inputs(optional_inputs_used)
if (length(optional_inputs_used) > 0L) {
  invisible(lapply(optional_inputs_used, read_csv_base))
}

# ---- 3. Candidate E-spec VIF diagnostics ------------------------------------
panel$year <- as.integer(as_num(panel$year))
panel$omega_t <- as_num(panel$omega_t)
panel$K_ME_gross_real <- as_num(panel$K_ME_gross_real)
panel$K_NRC_gross_real <- as_num(panel$K_NRC_gross_real)

candidate_rows <- list()
row_idx <- 1L

for (w_i in seq_len(nrow(main_windows))) {
  w <- main_windows[w_i, ]
  window_data <- panel[panel$year >= w$year_start & panel$year <= w$year_end, , drop = FALSE]
  if (nrow(window_data) == 0L) {
    stop("S20 panel has no observations for window: ", w$window_id, call. = FALSE)
  }

  invalid <- !is.finite(window_data$K_ME_gross_real) |
    !is.finite(window_data$K_NRC_gross_real) |
    window_data$K_ME_gross_real <= 0 |
    window_data$K_NRC_gross_real <= 0
  if (any(invalid)) {
    bad_years <- paste(window_data$year[invalid], collapse = ", ")
    stop(
      "Candidate E-spec VIF is inadmissible because ME/NRC capital is missing, non-finite, zero, or negative in window ",
      w$window_id, " for years: ", bad_years,
      call. = FALSE
    )
  }

  window_data$k_ME_proxy_t <- log(window_data$K_ME_gross_real)
  window_data$k_NRC_proxy_t <- log(window_data$K_NRC_gross_real)
  window_data$m_ME_NRC_t <- window_data$k_ME_proxy_t - window_data$k_NRC_proxy_t
  window_data$c_NRC_ME_t <- window_data$k_NRC_proxy_t - window_data$k_ME_proxy_t
  window_data$omega_m_ME_NRC_t <- window_data$omega_t * window_data$m_ME_NRC_t

  for (spec_id in names(candidate_specs)) {
    spec <- candidate_specs[[spec_id]]
    rhs <- spec$rhs
    vif_values <- compute_vif_from_correlation(window_data, rhs)
    max_vif <- finite_max(vif_values)
    mean_vif <- finite_mean(vif_values)
    high_vars <- names(vif_values)[is.finite(vif_values) & vif_values >= 10]
    high_var_text <- collapse_nonempty(high_vars)
    flag <- length(high_vars) > 0L

    for (rhs_variable in rhs) {
      candidate_rows[[row_idx]] <- data.frame(
        country = "US",
        stage = "S31",
        diagnostic_type = "candidate_vif_only",
        spec_id = spec_id,
        spec_family = "NRC_envelope_mechanization_bias",
        architecture_layer = "A03_candidate",
        identification_role = "envelope_vs_mechanization_candidate",
        estimated_in_s30 = FALSE,
        estimated_in_s32 = FALSE,
        vif_only_candidate = TRUE,
        s40_eligible = FALSE,
        window_id = w$window_id,
        year_start = w$year_start,
        year_end = w$year_end,
        n_obs = sum(stats::complete.cases(window_data[, rhs, drop = FALSE])),
        rhs_variable = rhs_variable,
        vif = unname(vif_values[rhs_variable]),
        vif_status = vif_status(unname(vif_values[rhs_variable])),
        max_vif_in_spec_window = max_vif,
        mean_vif_in_spec_window = mean_vif,
        collinearity_flag = flag,
        high_vif_variables = high_var_text,
        formula_label = spec$formula_label,
        mechanization_bias_sign = "higher_m_ME_NRC_t_indicates_more_machinery_intensity_relative_to_NRC_envelope",
        envelope_variable = "k_NRC_proxy_t",
        mechanization_bias_variable = "m_ME_NRC_t",
        distribution_conditioned_variable = spec$distribution_conditioned_variable,
        diagnostic_role = "model_choice_review_screen_only",
        candidate_use = "do_not_treat_as_estimated_result",
        stringsAsFactors = FALSE
      )
      row_idx <- row_idx + 1L
    }
  }
}

candidate_tidy <- do.call(rbind, candidate_rows)

candidate_cols <- c(
  "country", "stage", "diagnostic_type", "spec_id", "spec_family",
  "architecture_layer", "identification_role", "estimated_in_s30",
  "estimated_in_s32", "vif_only_candidate", "s40_eligible", "window_id",
  "year_start", "year_end", "n_obs", "rhs_variable", "vif", "vif_status",
  "max_vif_in_spec_window", "mean_vif_in_spec_window", "collinearity_flag",
  "high_vif_variables", "formula_label", "mechanization_bias_sign",
  "envelope_variable", "mechanization_bias_variable",
  "distribution_conditioned_variable", "diagnostic_role", "candidate_use"
)
candidate_tidy <- candidate_tidy[, candidate_cols, drop = FALSE]

# ---- 4. Combined model-choice VIF screen ------------------------------------
existing_vif$year_start <- as.integer(as_num(existing_vif$year_start))
existing_vif$year_end <- as.integer(as_num(existing_vif$year_end))
existing_vif$n_obs <- as.integer(as_num(existing_vif$n_obs))
existing_vif$vif <- as_num(existing_vif$vif)
existing_vif$max_vif_in_spec_window <- as_num(existing_vif$max_vif_in_spec_window)
existing_vif$mean_vif_in_spec_window <- as_num(existing_vif$mean_vif_in_spec_window)
existing_vif$collinearity_flag <- as_bool(existing_vif$collinearity_flag)

existing_vif_screen <- existing_vif[
  existing_vif$window_id %in% main_windows$window_id &
    existing_vif$spec_id %in% existing_screen_specs &
    existing_vif$spec_id != "SPEC_B0_CAPITAL_ONLY",
  ,
  drop = FALSE
]

candidate_for_screen <- candidate_tidy[, c(
  "country", "stage", "spec_id", "spec_family", "architecture_layer",
  "window_id", "year_start", "year_end", "n_obs", "rhs_variable", "vif",
  "vif_status", "max_vif_in_spec_window", "mean_vif_in_spec_window",
  "collinearity_flag", "diagnostic_role", "high_vif_variables"
), drop = FALSE]

for (col in setdiff(names(candidate_for_screen), names(existing_vif_screen))) {
  existing_vif_screen[[col]] <- ""
}
for (col in setdiff(names(existing_vif_screen), names(candidate_for_screen))) {
  candidate_for_screen[[col]] <- ""
}
combined_vif <- rbind(
  existing_vif_screen[, names(existing_vif_screen), drop = FALSE],
  candidate_for_screen[, names(existing_vif_screen), drop = FALSE]
)
combined_vif$max_vif_in_spec_window <- as_num(combined_vif$max_vif_in_spec_window)
combined_vif$vif <- as_num(combined_vif$vif)

spec_window <- unique(combined_vif[, c(
  "spec_id", "window_id", "year_start", "year_end", "n_obs",
  "max_vif_in_spec_window"
), drop = FALSE])
spec_window$vif_screen_status <- vapply(
  spec_window$max_vif_in_spec_window,
  spec_window_vif_status,
  character(1)
)

high_var_by_cell <- aggregate(
  rhs_variable ~ spec_id + window_id,
  data = combined_vif[is.finite(combined_vif$vif) & combined_vif$vif >= 10, , drop = FALSE],
  FUN = collapse_nonempty
)
names(high_var_by_cell)[names(high_var_by_cell) == "rhs_variable"] <- "high_vif_variables"
spec_window <- merge(spec_window, high_var_by_cell, by = c("spec_id", "window_id"), all.x = TRUE)
spec_window$high_vif_variables[is.na(spec_window$high_vif_variables)] <- ""

summary_rows <- list()
for (spec_id in spec_classification$spec_id) {
  sw <- spec_window[spec_window$spec_id == spec_id, , drop = FALSE]
  if (nrow(sw) == 0L) {
    stop("No VIF screen cells found for spec: ", spec_id, call. = FALSE)
  }

  max_vif_all <- finite_max(sw$max_vif_in_spec_window)
  worst_idx <- which.max(ifelse(is.finite(sw$max_vif_in_spec_window), sw$max_vif_in_spec_window, -Inf))
  worst_window <- sw$window_id[worst_idx]
  worst_value <- sw$max_vif_in_spec_window[worst_idx]
  n_high <- sum(sw$vif_screen_status == "vif_block_high", na.rm = TRUE)
  n_moderate <- sum(sw$vif_screen_status == "vif_review_moderate", na.rm = TRUE)
  n_low <- sum(sw$vif_screen_status == "vif_pass_low", na.rm = TRUE)

  rec <- if (n_high == 0L && is.finite(max_vif_all) && max_vif_all < 5) {
    "vif_feasible_for_human_review"
  } else if (n_high == 0L && is.finite(max_vif_all) && max_vif_all < 10) {
    "vif_feasible_with_caution"
  } else {
    "vif_block_before_estimation_or_promotion"
  }

  class <- spec_classification[spec_classification$spec_id == spec_id, , drop = FALSE]
  final_status <- if (class$specification_layer == "diagnostic_only") {
    "diagnostic_only_not_promotable"
  } else if (class$specification_layer == "A03_candidate" && n_high == 0L) {
    "vif_feasible_for_possible_future_S30b_or_S32_review"
  } else if (class$specification_layer == "A03_candidate" && n_high > 0L) {
    "vif_blocks_candidate_estimation_pending_human_override"
  } else if (class$specification_layer == "A00_baseline" && n_high == 0L && max_vif_all < 5) {
    "baseline_vif_clear_for_human_adjudication"
  } else if (class$specification_layer == "A00_baseline") {
    "baseline_vif_fragile_for_human_adjudication"
  } else if (class$specification_layer == "A03_proxy_escalation" && n_high == 0L && max_vif_all < 5) {
    "proxy_escalation_vif_clear_for_human_adjudication"
  } else {
    "proxy_escalation_vif_fragile_for_human_adjudication"
  }

  notes <- if (class$specification_layer == "diagnostic_only") {
    "Diagnostic-only row; non-promotable regardless of VIF."
  } else if (class$specification_layer == "A03_candidate") {
    "A05 E-spec candidate VIF-only row; human approval required before estimation."
  } else if (class$specification_layer == "A00_baseline") {
    "A00/B1 remains the binding baseline review object; VIF does not promote it."
  } else {
    "A03 proxy-escalation row; human adjudication required before further use."
  }

  summary_rows[[length(summary_rows) + 1L]] <- data.frame(
    country = "US",
    stage = "S31",
    spec_id = spec_id,
    specification_layer = class$specification_layer,
    architecture_layer = class$architecture_layer,
    screen_role = class$screen_role,
    estimated_status = class$estimated_status,
    promotable_in_principle = class$promotable_in_principle,
    n_windows = nrow(sw),
    n_low_vif_windows = n_low,
    n_moderate_vif_windows = n_moderate,
    n_high_vif_windows = n_high,
    share_high_vif_windows = n_high / nrow(sw),
    max_vif_all_windows = max_vif_all,
    median_max_vif = finite_median(sw$max_vif_in_spec_window),
    worst_window_id = worst_window,
    worst_window_max_vif = worst_value,
    high_vif_variables_union = collapse_nonempty(sw$high_vif_variables),
    vif_screen_recommendation = rec,
    final_screen_status = final_status,
    human_adjudication_required = class$specification_layer != "diagnostic_only",
    s40_eligible = FALSE,
    final_model_selected = FALSE,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

screen_tidy <- do.call(rbind, summary_rows)
screen_cols <- c(
  "country", "stage", "spec_id", "specification_layer", "architecture_layer",
  "screen_role", "estimated_status", "promotable_in_principle", "n_windows",
  "n_low_vif_windows", "n_moderate_vif_windows", "n_high_vif_windows",
  "share_high_vif_windows", "max_vif_all_windows", "median_max_vif",
  "worst_window_id", "worst_window_max_vif", "high_vif_variables_union",
  "vif_screen_recommendation", "final_screen_status",
  "human_adjudication_required", "s40_eligible", "final_model_selected", "notes"
)
screen_tidy <- screen_tidy[, screen_cols, drop = FALSE]

# ---- 5. Outputs --------------------------------------------------------------
write_csv_base(candidate_tidy, output_paths["candidate_tidy"])
write_candidate_tex(candidate_tidy, output_paths["candidate_tex"])
write_csv_base(screen_tidy, output_paths["screen_tidy"])
write_screen_tex(screen_tidy, output_paths["screen_tex"])

manifest <- data.frame(
  item = c(
    "run_timestamp",
    "input_files_used",
    "optional_input_files_used",
    "output_files_written",
    "existing_s31_vif_input",
    "s20_panel_input",
    "candidate_E_specs_computed",
    "candidate_E_specs_estimated",
    "S40_outputs_read",
    "theta_tot_reconstructed",
    "Yp_reconstructed",
    "mu_computed",
    "anchor_chosen",
    "final_model_selected",
    "human_adjudication_required",
    "governed_by_A05",
    "governed_by_R10",
    "governed_by_D04"
  ),
  value = c(
    RUN_TIMESTAMP,
    paste(unname(input_paths), collapse = " | "),
    if (length(optional_inputs_used) == 0L) "" else paste(optional_inputs_used, collapse = " | "),
    paste(unname(output_paths), collapse = " | "),
    unname(input_paths["existing_s31_vif"]),
    unname(input_paths["s20_panel"]),
    "TRUE",
    "FALSE",
    "FALSE",
    "FALSE",
    "FALSE",
    "FALSE",
    "FALSE",
    "FALSE",
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE"
  ),
  stringsAsFactors = FALSE
)
write_csv_base(manifest, output_paths["manifest"])

result_lines <- apply(screen_tidy, 1L, function(z) {
  sprintf(
    "| `%s` | `%s` | `%s` | %s | %s | `%s` | `%s` |",
    z[["spec_id"]],
    z[["specification_layer"]],
    z[["estimated_status"]],
    format_num(z[["max_vif_all_windows"]]),
    z[["n_high_vif_windows"]],
    z[["vif_screen_recommendation"]],
    z[["final_screen_status"]]
  )
})

candidate_cell_count <- nrow(unique(candidate_tidy[, c("spec_id", "window_id"), drop = FALSE]))
existing_report_lines <- length(existing_report)

report_lines <- c(
  "# US S31 Model-Choice VIF Screen Report",
  "",
  sprintf("Run timestamp: `%s`.", RUN_TIMESTAMP),
  "",
  "## 1. Purpose",
  "",
  "This script adds a governed S31 VIF screen for model-choice review. It combines existing S31 VIF diagnostics for reported S30 specifications with new A05 E-specification VIF-only diagnostics. It reports collinearity feasibility; it does not estimate coefficients, adjudicate cointegration, or choose a model.",
  "",
  "## 2. Governance from A05/R10/D04",
  "",
  "A00/B1 remains the baseline review object. C1/C2 are A03 proxy-escalation specifications. E1/E2A/E2B are A03 candidate specifications and are not estimated. D1/D2 are diagnostic-only and non-promotable. VIF can block or caution coefficient interpretation, but it cannot promote a model.",
  "",
  "## 3. Existing S30 Specs Included in the Screen",
  "",
  "- `SPEC_B1_WAGE_BASELINE`: A00 baseline review object.",
  "- `SPEC_C1_COMPOSITION_STOCK`: A03 proxy-escalation review object.",
  "- `SPEC_C2_FULL_COMPOSITION`: A03 proxy-escalation review object.",
  "- `SPEC_D1_CURRENT_COST_DIAGNOSTIC`: diagnostic-only, non-promotable.",
  "- `SPEC_D2_PRICE_WEDGE_DIAGNOSTIC`: diagnostic-only, non-promotable.",
  "",
  "## 4. Candidate A05 E-Specs Included as VIF-Only Diagnostics",
  "",
  "- `SPEC_E1_NRC_ENVELOPE_MECHANIZATION_BIAS`: VIF only, `y_t ~ k_NRC_proxy_t + m_ME_NRC_t`.",
  "- `SPEC_E2A_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_FULL`: VIF only, `y_t ~ k_NRC_proxy_t + m_ME_NRC_t + omega_m_ME_NRC_t`.",
  "- `SPEC_E2B_NRC_ENVELOPE_DISTRIBUTIVE_MECHANIZATION_RESTRICTED`: VIF only, `y_t ~ k_NRC_proxy_t + omega_m_ME_NRC_t`.",
  "",
  "The envelope variable is log real NRC capital. The mechanization-bias variable is log(ME/NRC), so higher values indicate greater machinery intensity relative to the NRC envelope. The reverse-sign construction `c_NRC_ME_t = -m_ME_NRC_t` is documentation-only and is not used in VIF regressions.",
  "",
  "## 5. Window Set",
  "",
  paste0("- `", main_windows$window_id, "`: ", main_windows$year_start, "-", main_windows$year_end),
  "",
  "Excluded windows remain excluded from this screen: `prefordist_core_1929_1944`, `post_1974_tight`, and `post_1974_support`.",
  "",
  "## 6. VIF Thresholds",
  "",
  "- `low`: VIF < 5.",
  "- `moderate`: 5 <= VIF < 10.",
  "- `high`: VIF >= 10.",
  "",
  "## 7. Spec-Level Screen Results",
  "",
  "| Spec | Layer | Estimated status | Max VIF | High windows | Recommendation | Final screen status |",
  "|---|---|---:|---:|---:|---|---|",
  result_lines,
  "",
  "## 8. Main Interpretation",
  "",
  sprintf("The candidate E-spec VIF output contains `%d` spec-window cells across the seven governed S31 windows.", candidate_cell_count),
  sprintf("The existing S31 report was read as a required reference input (`%d` lines). Existing S31 coefficient tables were not overwritten.", existing_report_lines),
  "The screen ranks and flags specifications for human review. A high VIF blocks estimation or promotion pending human override. Moderate VIF requires caution. Low VIF only clears the collinearity screen; it does not authorize promotion.",
  "",
  "## 9. No Final Model Is Selected",
  "",
  "No row selects a final model. No row is marked `promoted_for_reconstruction`. The VIF screen alone never makes a model S40-eligible.",
  "",
  "## 10. S40 Remains Parked",
  "",
  "S40 remains parked. This run reads no S40 outputs, reconstructs no theta_tot, reconstructs no Yp, computes no mu, and chooses no anchor.",
  "",
  "## 11. Recommended Next Human Decisions",
  "",
  "- Decide whether B1/A00 remains adequate as the baseline review object after inspecting coefficient stability and VIF.",
  "- Decide whether C1/C2 proxy-escalation rows remain interpretable or are blocked by high VIF.",
  "- Decide whether any E1/E2A/E2B candidate with feasible VIF should be authorized for a separate estimation pass.",
  "- Decide whether any estimated specification should move toward S40 reconstruction; that movement requires human adjudication and is not authorized here."
)
write_lines(report_lines, output_paths["report"])

cat("S31 model-choice VIF screen complete.\n")
cat("Output folder: ", out_dir, "\n", sep = "")
