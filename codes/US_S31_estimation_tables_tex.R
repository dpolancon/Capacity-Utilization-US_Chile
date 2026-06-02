###############################################################################
# US_S31_estimation_tables_tex.R
# Chapter 2 - US S31 reporting/export layer for S30 human review
#
# Role:
#   S31 consumes existing S20/S30 outputs and exports tidy CSV and LaTeX
#   coefficient tables for human adjudication of S30.
#
# Guardrails:
#   - Does not estimate models.
#   - Does not read S40 outputs.
#   - Does not reconstruct theta_tot.
#   - Does not reconstruct productive capacity.
#   - Does not compute capacity utilization.
#   - Does not choose utilization anchors.
###############################################################################

# ---- 0. Paths ----------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")

s20_dir <- file.path(REPO, "output/US/S20_composition_admissibility")
s30_dir <- file.path(REPO, "output/US/S30_transformation_relation")
panel_path <- file.path(REPO, "data/processed/US/us_s20_admissibility_panel.csv")
out_dir <- file.path(REPO, "output/US/S31_estimation_tables_tex")

input_paths <- c(
  s30_estimator_grid = file.path(s30_dir, "us_s30_estimator_grid.csv"),
  s30_specification_register = file.path(s30_dir, "us_s30_specification_register.csv"),
  s30_run_manifest = file.path(s30_dir, "us_s30_run_manifest.csv"),
  s30_window_stability_summary = file.path(s30_dir, "us_s30_window_stability_summary.csv"),
  s30_rolling_coefficients = file.path(s30_dir, "us_s30_rolling_coefficients.csv"),
  s30_report = file.path(s30_dir, "US_S30_transformation_relation_report.md"),
  s20_admissibility_panel = panel_path,
  s20_candidate_window_register = file.path(s20_dir, "us_s20_candidate_window_register.csv"),
  s20_window_admissibility_summary = file.path(s20_dir, "us_s20_window_admissibility_summary.csv"),
  s20_report = file.path(s20_dir, "US_S20_admissibility_summary.md")
)

output_paths <- c(
  a00_tidy = file.path(out_dir, "us_s31_a00_baseline_coefficients_tidy.csv"),
  a00_tex = file.path(out_dir, "us_s31_a00_baseline_coefficients.tex"),
  a03_tidy = file.path(out_dir, "us_s31_a03_proxy_escalation_coefficients_tidy.csv"),
  a03_tex = file.path(out_dir, "us_s31_a03_proxy_escalation_coefficients.tex"),
  diagnostic_tidy = file.path(out_dir, "us_s31_diagnostic_coefficients_tidy.csv"),
  diagnostic_tex = file.path(out_dir, "us_s31_diagnostic_coefficients.tex"),
  vif_tidy = file.path(out_dir, "us_s31_vif_diagnostics_tidy.csv"),
  vif_tex = file.path(out_dir, "us_s31_vif_diagnostics.tex"),
  window_register = file.path(out_dir, "us_s31_window_inclusion_register.csv"),
  manifest = file.path(out_dir, "us_s31_estimation_table_manifest.csv"),
  report = file.path(out_dir, "US_S31_estimation_tables_report.md")
)

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")

main_windows <- c(
  "full_long_sample",
  "pre_1974",
  "post_1973",
  "fordist_core",
  "bridge_1940_1978",
  "pre_1974_alt_1940_1973",
  "pre_1974_alt_1947_1974"
)

excluded_windows <- c(
  "post_1974_tight",
  "post_1974_support",
  "prefordist_core_1929_1944"
)

a00_specs <- "SPEC_B1_WAGE_BASELINE"
a03_specs <- c("SPEC_C1_COMPOSITION_STOCK", "SPEC_C2_FULL_COMPOSITION")
diagnostic_specs <- c("SPEC_D1_CURRENT_COST_DIAGNOSTIC", "SPEC_D2_PRICE_WEDGE_DIAGNOSTIC")
reported_specs <- c(a00_specs, a03_specs, diagnostic_specs)

implied_theta_mappings <- c(
  SPEC_B1_WAGE_BASELINE =
    "theta_A00_t = beta_k + beta_omega_k * omega_t",
  SPEC_C1_COMPOSITION_STOCK =
    "theta_A03_C1_t = beta_k + beta_omega_k * omega_t + beta_s_k * centered_s_t_proxy",
  SPEC_C2_FULL_COMPOSITION =
    "theta_A03_C2_t = beta_k + beta_omega_k * omega_t + beta_s_k * centered_s_t_proxy + beta_omega_s_k * omega_t * centered_s_t_proxy",
  SPEC_D1_CURRENT_COST_DIAGNOSTIC =
    "diagnostic-only current-cost composition-proxy coefficient block; not eligible for baseline promotion",
  SPEC_D2_PRICE_WEDGE_DIAGNOSTIC =
    "diagnostic-only relative-price-wedge coefficient block; not eligible for baseline promotion"
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
      "S31 cannot run because required S20/S30 input files are missing:\n  ",
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

as_num <- function(x) suppressWarnings(as.numeric(x))

as_bool <- function(x) {
  if (is.logical(x)) return(x)
  y <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(y))
  out[y %in% c("true", "t", "1", "yes", "y")] <- TRUE
  out[y %in% c("false", "f", "0", "no", "n")] <- FALSE
  out
}

safe_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  mean(x)
}

safe_max <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  max(x)
}

split_terms <- function(x) {
  if (is.na(x) || !nzchar(x)) return(character(0))
  strsplit(x, "\\|", fixed = FALSE)[[1L]]
}

manifest_value <- function(manifest, item, default = NA_character_) {
  hit <- manifest$value[manifest$item == item]
  if (length(hit) == 0L || is.na(hit[1L]) || !nzchar(hit[1L])) return(default)
  hit[1L]
}

collapse_unique <- function(x, sep = "; ") {
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  if (length(x) == 0L) return("")
  paste(unique(x), collapse = sep)
}

format_num <- function(x, digits = 3L) {
  x <- as_num(x)
  if (!is.finite(x)) return("")
  formatC(x, digits = digits, format = "f")
}

latex_escape <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([_&#%$])", "\\\\\\1", x)
  x <- gsub("\\{", "\\\\{", x)
  x <- gsub("\\}", "\\\\}", x)
  x
}

estimator_role <- function(estimator) {
  out <- rep("reported_by_S30", length(estimator))
  out[estimator == "FM_OLS"] <- "main_estimator"
  out[estimator == "IM_OLS"] <- "robustness_check"
  out[estimator == "DOLS"] <- "fragility_stress_check"
  out
}

extract_note_value <- function(notes, key) {
  notes <- as.character(notes)
  pattern <- paste0(key, "=([^;\\.]+)")
  out <- rep("", length(notes))
  for (i in seq_along(notes)) {
    m <- regexpr(pattern, notes[i], perl = TRUE)
    if (m[1L] > 0L) {
      out[i] <- sub(paste0("^", key, "="), "", regmatches(notes[i], m))
    }
  }
  out
}

estimator_kernel <- function(estimator, notes) {
  kernel <- extract_note_value(notes, "kernel")
  kernel[!estimator %in% c("FM_OLS", "IM_OLS", "DOLS")] <- ""
  kernel
}

estimator_bandwidth <- function(estimator, notes, manifest) {
  bandwidth <- extract_note_value(notes, "bandwidth")
  bandwidth[estimator == "FM_OLS" & !nzchar(bandwidth)] <- manifest_value(manifest, "fm_ols_bandwidth", "")
  bandwidth[estimator == "IM_OLS" & !nzchar(bandwidth)] <- manifest_value(manifest, "im_ols_bandwidth", "")
  bandwidth[estimator == "DOLS" & !nzchar(bandwidth)] <- manifest_value(manifest, "dols_bandwidth", "")
  bandwidth
}

center_window_var <- function(x) {
  x <- as_num(x)
  m <- safe_mean(x)
  if (!is.finite(m)) return(rep(NA_real_, length(x)))
  x - m
}

prepare_window_data <- function(df) {
  d <- df
  d$k_t <- as_num(d$k_t)
  d$omega_t <- as_num(d$omega_t)
  d$omega_k_t <- d$omega_t * d$k_t

  for (nm in c("s_t_proxy", "phi_t_proxy", "s_t_proxy_cc", "phi_t_proxy_cc",
               "pK_relative_ME_NRC")) {
    if (!nm %in% names(d)) d[[nm]] <- NA_real_
    d[[nm]] <- as_num(d[[nm]])
  }

  d$s_t_proxy_c <- center_window_var(d$s_t_proxy)
  d$s_t_proxy_cc_c <- center_window_var(d$s_t_proxy_cc)
  d$pK_relative_ME_NRC_c <- center_window_var(d$pK_relative_ME_NRC)

  d$s_proxy_k_t <- d$s_t_proxy_c * d$k_t
  d$omega_s_proxy_k_t <- d$omega_t * d$s_t_proxy_c * d$k_t
  d$s_proxy_cc_k_t <- d$s_t_proxy_cc_c * d$k_t
  d$omega_s_proxy_cc_k_t <- d$omega_t * d$s_t_proxy_cc_c * d$k_t
  d$pKrel_k_t <- d$pK_relative_ME_NRC_c * d$k_t
  d
}

compute_vif <- function(df, rhs) {
  if (length(rhs) == 0L) return(numeric(0))
  if (length(rhs) == 1L) return(setNames(NA_real_, rhs))

  out <- rep(NA_real_, length(rhs))
  names(out) <- rhs
  for (var in rhs) {
    others <- setdiff(rhs, var)
    d <- df[, c(var, others), drop = FALSE]
    d[] <- lapply(d, as_num)
    d <- d[stats::complete.cases(d), , drop = FALSE]
    if (nrow(d) <= length(others) + 1L) next
    if (!is.finite(stats::var(d[[var]])) || stats::var(d[[var]]) == 0) next

    fit <- tryCatch(
      stats::lm(stats::as.formula(paste(var, "~", paste(others, collapse = " + "))), data = d),
      error = function(e) NULL
    )
    if (is.null(fit)) next
    r2 <- summary(fit)$r.squared
    if (!is.finite(r2)) next
    out[var] <- if (r2 >= 1) Inf else 1 / (1 - r2)
  }
  out
}

vif_status <- function(vif) {
  if (!is.finite(vif)) return("not_meaningful")
  if (vif < 5) return("low")
  if (vif < 10) return("moderate")
  "high"
}

spec_family <- function(spec_id) {
  if (spec_id == "SPEC_B1_WAGE_BASELINE") return("A00_baseline")
  if (spec_id %in% a03_specs) return("A03_composition_proxy_escalation")
  if (spec_id %in% diagnostic_specs) return("diagnostic_appendix")
  "other"
}

coef_table_note <- function(extra_note = NULL) {
  base <- paste(
    "FM-OLS is the main estimator; IM-OLS is a robustness check; DOLS is a",
    "fragility/stress check. S31 exports S30 estimates for human adjudication",
    "and does not reconstruct theta_tot, productive capacity, or utilization."
  )
  if (!is.null(extra_note)) paste(base, extra_note) else base
}

write_coef_tex <- function(df, path, caption, label, extra_note = NULL) {
  show <- df[, c(
    "window_id", "year_start", "year_end", "spec_id", "estimator",
    "estimator_role", "rhs_variable", "estimate", "std_error", "t_stat",
    "p_value", "estimator_status", "classification"
  ), drop = FALSE]
  show <- show[order(show$year_start, show$year_end, show$window_id,
                     show$spec_id, show$estimator, show$rhs_variable), ]

  row_lines <- apply(show, 1L, function(z) {
    paste(
      latex_escape(z["window_id"]),
      paste0(latex_escape(z["year_start"]), "--", latex_escape(z["year_end"])),
      latex_escape(z["spec_id"]),
      latex_escape(z["estimator"]),
      latex_escape(z["rhs_variable"]),
      format_num(z["estimate"]),
      format_num(z["std_error"]),
      format_num(z["t_stat"]),
      format_num(z["p_value"]),
      latex_escape(z["estimator_status"]),
      latex_escape(z["classification"]),
      sep = " & "
    )
  })

  lines <- c(
    "% Auto-generated by codes/US_S31_estimation_tables_tex.R",
    paste0("% Generated: ", RUN_TIMESTAMP),
    "\\begin{table}[htbp]",
    "\\centering",
    paste0("\\caption{", latex_escape(caption), "}"),
    paste0("\\label{", label, "}"),
    "\\scriptsize",
    "\\begin{tabular}{lllllrrrrll}",
    "\\toprule",
    "Window & Years & Spec & Estimator & RHS & Estimate & SE & t & p & Status & Class \\\\",
    "\\midrule",
    paste0(row_lines, " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\vspace{0.5em}",
    "\\begin{minipage}{0.96\\linewidth}",
    "\\footnotesize",
    paste0("Notes: ", latex_escape(coef_table_note(extra_note))),
    "\\end{minipage}",
    "\\end{table}"
  )
  writeLines(lines, path, useBytes = TRUE)
}

write_vif_tex <- function(vif_tidy, path) {
  cell_cols <- c(
    "spec_id", "spec_family", "window_id", "year_start", "year_end", "n_obs",
    "max_vif_in_spec_window", "mean_vif_in_spec_window", "collinearity_flag",
    "diagnostic_role"
  )
  cells <- unique(vif_tidy[, cell_cols, drop = FALSE])
  high <- vif_tidy[vif_tidy$vif_status == "high", c("spec_id", "window_id", "rhs_variable"), drop = FALSE]
  if (nrow(high) > 0L) {
    high <- stats::aggregate(
      rhs_variable ~ spec_id + window_id,
      data = high,
      FUN = function(x) paste(unique(x), collapse = ", ")
    )
    names(high)[names(high) == "rhs_variable"] <- "high_vif_variables"
    cells <- merge(cells, high, by = c("spec_id", "window_id"), all.x = TRUE)
  } else {
    cells$high_vif_variables <- ""
  }
  cells$high_vif_variables[is.na(cells$high_vif_variables) | !nzchar(cells$high_vif_variables)] <- "none"
  cells$diagnostic_note <- ifelse(
    as_bool(cells$collinearity_flag),
    "High VIF: coefficient-interpretation fragility flag.",
    "No high VIF."
  )
  cells <- cells[order(cells$year_start, cells$year_end, cells$window_id, cells$spec_id), ]

  row_lines <- apply(cells, 1L, function(z) {
    paste(
      latex_escape(z["spec_id"]),
      latex_escape(z["window_id"]),
      paste0(latex_escape(z["year_start"]), "--", latex_escape(z["year_end"])),
      latex_escape(z["n_obs"]),
      format_num(z["max_vif_in_spec_window"], 2L),
      latex_escape(z["high_vif_variables"]),
      latex_escape(z["collinearity_flag"]),
      latex_escape(z["diagnostic_note"]),
      sep = " & "
    )
  })

  lines <- c(
    "% Auto-generated by codes/US_S31_estimation_tables_tex.R",
    paste0("% Generated: ", RUN_TIMESTAMP),
    "\\begin{table}[htbp]",
    "\\centering",
    "\\caption{US S31 VIF and Collinearity Diagnostics}",
    "\\label{tab:us_s31_vif_diagnostics}",
    "\\scriptsize",
    "\\begin{tabular}{lllrlp{0.18\\linewidth}lp{0.24\\linewidth}}",
    "\\toprule",
    "Spec & Window & Years & N & Max VIF & VIF $\\geq$ 10 variables & Flag & Note \\\\",
    "\\midrule",
    paste0(row_lines, " \\\\"),
    "\\bottomrule",
    "\\end{tabular}",
    "\\vspace{0.5em}",
    "\\begin{minipage}{0.96\\linewidth}",
    "\\footnotesize",
    paste0(
      "Notes: ",
      latex_escape(paste(
        "FM-OLS is the main estimator; IM-OLS is a robustness check; DOLS is a",
        "fragility/stress check. S31 exports S30 estimates for human adjudication",
        "and does not reconstruct theta_tot, productive capacity, or utilization.",
        "VIF is a coefficient-interpretation fragility diagnostic, not an automatic",
        "model-rejection rule. It does not adjudicate cointegration, replace",
        "FM-OLS/IM-OLS/DOLS comparison, or promote or demote A00/A03 specifications."
      ))
    ),
    "\\end{minipage}",
    "\\end{table}"
  )
  writeLines(lines, path, useBytes = TRUE)
}

# ---- 2. Validate and read inputs --------------------------------------------
require_files(input_paths)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

estimator_grid <- read_csv_base(input_paths["s30_estimator_grid"])
spec_register <- read_csv_base(input_paths["s30_specification_register"])
s30_manifest <- read_csv_base(input_paths["s30_run_manifest"])
stability <- read_csv_base(input_paths["s30_window_stability_summary"])
rolling <- read_csv_base(input_paths["s30_rolling_coefficients"])
s20_window_register <- read_csv_base(input_paths["s20_candidate_window_register"])
s20_admissibility <- read_csv_base(input_paths["s20_window_admissibility_summary"])
panel <- read_csv_base(panel_path, check_names = TRUE)

require_cols(
  estimator_grid,
  c("window_id", "window_role", "year_start", "year_end", "estimator",
    "spec_id", "coefficient", "estimate", "std_error", "t_stat", "p_value",
    "n_raw", "n_effective", "status", "estimator_status", "notes"),
  "us_s30_estimator_grid.csv"
)
require_cols(
  spec_register,
  c("spec_id", "formula_label", "regressors", "architecture_layer",
    "identification_role", "promotion_eligible", "diagnostic_only", "role"),
  "us_s30_specification_register.csv"
)
require_cols(
  s30_manifest,
  c("item", "value"),
  "us_s30_run_manifest.csv"
)
require_cols(
  stability,
  c("window_id", "spec_id", "classification", "promotion_status",
    "severe_collinearity_flag", "neighborhood_reversal_count",
    "rolling_proxy_reversal_count"),
  "us_s30_window_stability_summary.csv"
)
require_cols(panel, c("year", "k_t", "omega_t"), "us_s20_admissibility_panel.csv")

if (any(grepl("S40|s40", input_paths))) {
  stop("Internal guardrail failure: S31 input list contains an S40 path.", call. = FALSE)
}

missing_main_windows <- setdiff(main_windows, unique(estimator_grid$window_id))
if (length(missing_main_windows) > 0L) {
  stop(
    "S31 cannot run because required main windows are absent from S30: ",
    paste(missing_main_windows, collapse = ", "),
    call. = FALSE
  )
}

missing_specs <- setdiff(reported_specs, unique(estimator_grid$spec_id))
if (length(missing_specs) > 0L) {
  stop(
    "S31 cannot run because required reported specs are absent from S30: ",
    paste(missing_specs, collapse = ", "),
    call. = FALSE
  )
}

preferred_asymmetric_patterns <- c(
  "k_NRC_t", "k_ME_t", "omega_ME_k_t", "omega_t * k_ME_t"
)
preferred_asymmetric_found <- any(grepl(
  paste(preferred_asymmetric_patterns, collapse = "|"),
  paste(spec_register$spec_id, spec_register$formula_label, spec_register$regressors),
  ignore.case = FALSE
))
proxy_a03_used <- !preferred_asymmetric_found

# ---- 3. Window inclusion register -------------------------------------------
window_meta <- unique(estimator_grid[, c("window_id", "year_start", "year_end", "window_role"), drop = FALSE])
window_meta <- window_meta[order(window_meta$year_start, window_meta$year_end, window_meta$window_id), ]
window_register <- data.frame(
  window_id = window_meta$window_id,
  year_start = window_meta$year_start,
  year_end = window_meta$year_end,
  role = window_meta$window_role,
  included_in_main_s31_tables = window_meta$window_id %in% main_windows,
  exclusion_reason = "",
  diagnostic_retention_status = "reported_in_main_s31_tables",
  stringsAsFactors = FALSE
)
window_register$exclusion_reason[window_register$window_id == "post_1974_tight"] <-
  "Excluded from main S31 tables: short 1974-1983 support window is too short for main FM-OLS/IM-OLS/DOLS comparison."
window_register$exclusion_reason[window_register$window_id == "post_1974_support"] <-
  "Excluded from main S31 tables: short 1974-1987 support window is too short for main FM-OLS/IM-OLS/DOLS comparison."
window_register$exclusion_reason[window_register$window_id == "prefordist_core_1929_1944"] <-
  "Excluded from main S31 tables: predecessor window, retained only as diagnostic/event context."
window_register$exclusion_reason[!(window_register$window_id %in% main_windows) &
                                    !nzchar(window_register$exclusion_reason)] <-
  "Excluded from main S31 tables by S31 window rule."
window_register$diagnostic_retention_status[!(window_register$window_id %in% main_windows)] <-
  "retained_in_S30_machine_diagnostics_only"
write_csv_base(window_register, output_paths["window_register"])

# ---- 4. Coefficient exports --------------------------------------------------
grid_main <- estimator_grid[
  estimator_grid$window_id %in% main_windows & estimator_grid$spec_id %in% reported_specs,
  ,
  drop = FALSE
]

coef <- merge(
  grid_main,
  spec_register,
  by = "spec_id",
  all.x = TRUE,
  suffixes = c("", "_spec")
)
coef <- merge(
  coef,
  stability[, c(
    "window_id", "spec_id", "classification", "promotion_status",
    "severe_collinearity_flag", "neighborhood_reversal_count",
    "rolling_proxy_reversal_count"
  ), drop = FALSE],
  by = c("window_id", "spec_id"),
  all.x = TRUE
)
coef$country <- "US"
coef$stage <- "S31_estimation_tables_tex"
coef$estimator_role <- estimator_role(coef$estimator)
coef$rhs_variable <- coef$coefficient
coef$cell_status <- coef$status
coef$implied_theta_mapping <- implied_theta_mappings[coef$spec_id]
coef$estimator_kernel <- estimator_kernel(coef$estimator, coef$notes)
coef$bandwidth_selector <- estimator_bandwidth(coef$estimator, coef$notes, s30_manifest)
coef$im_selector <- ifelse(coef$estimator == "IM_OLS", manifest_value(s30_manifest, "im_selector", "1"), "")
coef$dols_leads_lags <- ifelse(coef$estimator == "DOLS", manifest_value(s30_manifest, "dols_leads_lags", ""), "")
coef$tuning_metadata <- coef$notes

tidy_cols <- c(
  "country", "stage", "window_id", "year_start", "year_end", "n_effective",
  "spec_id", "formula_label", "architecture_layer", "identification_role",
  "estimator", "estimator_role", "estimator_kernel", "bandwidth_selector",
  "im_selector", "dols_leads_lags", "rhs_variable", "estimate", "std_error",
  "t_stat", "p_value", "estimator_status", "cell_status", "classification",
  "promotion_status", "severe_collinearity_flag", "neighborhood_reversal_count",
  "rolling_proxy_reversal_count", "composition_status", "composition_basis",
  "composition_tier", "direct_sector_asset_split", "tuning_metadata",
  "implied_theta_mapping"
)
for (col in tidy_cols) {
  if (!col %in% names(coef)) coef[[col]] <- ""
}
coef_tidy <- coef[, tidy_cols, drop = FALSE]
names(coef_tidy)[names(coef_tidy) == "n_effective"] <- "n_obs"

a00_tidy <- coef_tidy[coef_tidy$spec_id %in% a00_specs, , drop = FALSE]
a03_tidy <- coef_tidy[coef_tidy$spec_id %in% a03_specs, , drop = FALSE]
diagnostic_tidy <- coef_tidy[coef_tidy$spec_id %in% diagnostic_specs, , drop = FALSE]

write_csv_base(a00_tidy, output_paths["a00_tidy"])
write_csv_base(a03_tidy, output_paths["a03_tidy"])
write_csv_base(diagnostic_tidy, output_paths["diagnostic_tidy"])

write_coef_tex(
  a00_tidy,
  output_paths["a00_tex"],
  "US S31 A00 Baseline Transformation Relation Estimates",
  "tab:us_s31_a00_baseline_coefficients"
)
write_coef_tex(
  a03_tidy,
  output_paths["a03_tex"],
  "US S31 A03 Composition-Proxy Escalation Estimates",
  "tab:us_s31_a03_proxy_escalation_coefficients",
  paste(
    "The current US A03 estimates are Tier-B ME/NRC composition-proxy",
    "escalation specifications. They are not direct NFCorp-by-asset-type",
    "ME/NRC estimates and do not identify the preferred asymmetric",
    "NRC-envelope / ME-distribution mechanism."
  )
)
write_coef_tex(
  diagnostic_tidy,
  output_paths["diagnostic_tex"],
  "US S31 Diagnostic Specification Estimates",
  "tab:us_s31_diagnostic_coefficients"
)

# ---- 5. VIF diagnostics ------------------------------------------------------
panel$year <- as.integer(as_num(panel$year))
vif_rows <- list()
row_i <- 0L
vif_cells <- unique(coef_tidy[, c("spec_id", "architecture_layer", "window_id", "year_start", "year_end"), drop = FALSE])
vif_cells$spec_family <- vapply(vif_cells$spec_id, spec_family, character(1L))
vif_cells <- vif_cells[order(vif_cells$year_start, vif_cells$year_end, vif_cells$window_id, vif_cells$spec_id), ]

for (i in seq_len(nrow(vif_cells))) {
  spec_id <- vif_cells$spec_id[i]
  spec_row <- spec_register[spec_register$spec_id == spec_id, , drop = FALSE]
  rhs <- split_terms(spec_row$regressors[1L])
  year_start <- as.integer(as_num(vif_cells$year_start[i]))
  year_end <- as.integer(as_num(vif_cells$year_end[i]))
  df_w <- panel[panel$year >= year_start & panel$year <= year_end, , drop = FALSE]
  df_w <- prepare_window_data(df_w)
  missing_rhs <- setdiff(rhs, names(df_w))
  if (length(missing_rhs) > 0L) {
    stop(
      "S31 VIF cannot run because RHS variables are missing for ", spec_id,
      " / ", vif_cells$window_id[i], ": ", paste(missing_rhs, collapse = ", "),
      call. = FALSE
    )
  }
  rhs_df <- df_w[, rhs, drop = FALSE]
  rhs_df[] <- lapply(rhs_df, as_num)
  rhs_ok <- stats::complete.cases(rhs_df)
  n_obs <- sum(rhs_ok)
  vifs <- compute_vif(rhs_df[rhs_ok, , drop = FALSE], rhs)
  max_vif <- safe_max(vifs)
  mean_vif <- safe_mean(vifs)
  collinearity_flag <- is.finite(max_vif) && max_vif >= 10
  diagnostic_role <- ifelse(spec_id %in% diagnostic_specs, "diagnostic_only", "human_review_support")

  for (rhs_var in rhs) {
    row_i <- row_i + 1L
    vif_rows[[row_i]] <- data.frame(
      country = "US",
      stage = "S31_VIF_collinearity_diagnostics",
      spec_id = spec_id,
      spec_family = vif_cells$spec_family[i],
      architecture_layer = vif_cells$architecture_layer[i],
      window_id = vif_cells$window_id[i],
      year_start = year_start,
      year_end = year_end,
      n_obs = n_obs,
      rhs_variable = rhs_var,
      vif = unname(vifs[rhs_var]),
      vif_status = vif_status(unname(vifs[rhs_var])),
      max_vif_in_spec_window = max_vif,
      mean_vif_in_spec_window = mean_vif,
      collinearity_flag = collinearity_flag,
      diagnostic_role = diagnostic_role,
      stringsAsFactors = FALSE
    )
  }
}

vif_tidy <- do.call(rbind, vif_rows)
write_csv_base(vif_tidy, output_paths["vif_tidy"])
write_vif_tex(vif_tidy, output_paths["vif_tex"])

# ---- 6. Manifest and report --------------------------------------------------
manifest_rows <- data.frame(
  item = c(
    "run_timestamp",
    "input_files_used",
    "output_files_written",
    "included_windows",
    "excluded_windows",
    "baseline_specification_selection_rule",
    "A03_proxy_specification_selection_rule",
    "diagnostic_specification_selection_rule",
    "preferred_asymmetric_ME_NRC_specification_found",
    "fallback_proxy_A03_reporting_used",
    "VIF_computed",
    "no_estimation_performed",
    "no_S40_outputs_read",
    "no_theta_tot_reconstructed",
    "no_Yp_reconstructed",
    "no_mu_computed",
    "no_anchor_chosen"
  ),
  value = c(
    RUN_TIMESTAMP,
    paste(input_paths, collapse = " | "),
    paste(output_paths, collapse = " | "),
    paste(main_windows, collapse = " | "),
    paste(excluded_windows, collapse = " | "),
    "Include only SPEC_B1_WAGE_BASELINE; SPEC_B0_CAPITAL_ONLY is a reference/null comparison and is not the Chapter 2 baseline.",
    "Include only existing S30 Tier-B composition-proxy escalation specs SPEC_C1_COMPOSITION_STOCK and SPEC_C2_FULL_COMPOSITION.",
    "Export SPEC_D1_CURRENT_COST_DIAGNOSTIC and SPEC_D2_PRICE_WEDGE_DIAGNOSTIC only in the diagnostic appendix table.",
    as.character(preferred_asymmetric_found),
    as.character(proxy_a03_used),
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE",
    "TRUE"
  ),
  stringsAsFactors = FALSE
)
write_csv_base(manifest_rows, output_paths["manifest"])

asymmetry_sentence <- if (preferred_asymmetric_found) {
  "A preferred asymmetric ME/NRC A03 specification appears in the current S30 specification register; S31 did not estimate or alter it."
} else {
  paste(
    "The preferred asymmetric ME/NRC A03 specification is absent from current",
    "S30 estimates. Current S30 contains only A03 composition-proxy escalation",
    "specifications based on Tier-B ME/NRC component proxies. These are useful",
    "proxy/escalation evidence, not direct identification of the asymmetric",
    "NRC-envelope and ME-distribution mechanism."
  )
}

report_lines <- c(
  "# US S31 Estimation Tables Report",
  "",
  paste0("Run timestamp: ", RUN_TIMESTAMP),
  "",
  "## 1. Purpose of S31",
  "",
  paste(
    "S31 is a reporting/export layer for human review of S30 estimates.",
    "S31 does not estimate new models. S31 does not adjudicate S30.",
    "S31 exports S30 estimates for human adjudication."
  ),
  "",
  "## 2. Inputs Consumed",
  "",
  paste0("- ", names(input_paths), ": `", input_paths, "`"),
  "",
  "## 3. Included and Excluded Windows",
  "",
  paste0("- Included main S31 windows: ", paste(main_windows, collapse = ", ")),
  paste0("- Excluded diagnostic/event/predecessor windows: ", paste(excluded_windows, collapse = ", ")),
  "",
  "## 4. A00 Baseline Table Contents",
  "",
  paste(
    "The A00 baseline table includes only SPEC_B1_WAGE_BASELINE:",
    "y_t ~ k_t + omega_k_t. Its implied mapping is",
    "theta_A00_t = beta_k + beta_omega_k * omega_t.",
    "SPEC_B0_CAPITAL_ONLY is not treated as the Chapter 2 baseline."
  ),
  "",
  "## 5. A03 Proxy-Escalation Table Contents",
  "",
  paste(
    "The A03 proxy table includes SPEC_C1_COMPOSITION_STOCK and",
    "SPEC_C2_FULL_COMPOSITION. C1 reports y_t ~ k_t + omega_k_t +",
    "s_proxy_k_t. C2 reports y_t ~ k_t + omega_k_t + s_proxy_k_t +",
    "omega_s_proxy_k_t. They are composition-proxy escalation evidence,",
    "not baseline replacements."
  ),
  "",
  "## 6. Preferred Asymmetric ME/NRC Specification",
  "",
  asymmetry_sentence,
  "",
  "## 7. Diagnostic Appendix Contents",
  "",
  paste(
    "The diagnostic appendix exports SPEC_D1_CURRENT_COST_DIAGNOSTIC and",
    "SPEC_D2_PRICE_WEDGE_DIAGNOSTIC. D1/D2 are diagnostic-only and are not",
    "eligible for baseline promotion."
  ),
  "",
  "## 8. Estimator Roles",
  "",
  "- FM-OLS = main estimator.",
  "- IM-OLS = robustness check.",
  "- DOLS = fragility/stress check.",
  "",
  "## 9. Estimator Tuning Metadata Reported from S30",
  "",
  paste0("- FM-OLS kernel/bandwidth: kernel reported in coefficient notes where available; bandwidth = ", manifest_value(s30_manifest, "fm_ols_bandwidth", "")),
  paste0("- IM-OLS kernel/bandwidth/selector: kernel reported in coefficient notes where available; bandwidth = ", manifest_value(s30_manifest, "im_ols_bandwidth", ""), "; selector = ", manifest_value(s30_manifest, "im_selector", "1")),
  paste0("- DOLS bandwidth and lead/lag setting: bandwidth = ", manifest_value(s30_manifest, "dols_bandwidth", ""), "; leads/lags = ", manifest_value(s30_manifest, "dols_leads_lags", "")),
  "",
  "## 10. VIF Diagnostics and Interpretation Rule",
  "",
  paste(
    "S31 computes VIF diagnostics for every reported spec_id x window_id cell",
    "where VIF is meaningful, using the exact S30 RHS regressors and the same",
    "window sample from the S20 admissibility panel. VIF status bins are low",
    "(VIF < 5), moderate (5 <= VIF < 10), and high (VIF >= 10). VIF is a",
    "coefficient-interpretation fragility diagnostic, not an automatic",
    "model-rejection rule. It does not adjudicate cointegration, does not",
    "replace FM-OLS/IM-OLS/DOLS comparison, and does not promote or demote",
    "A00/A03 specifications by itself."
  ),
  "",
  "## 11. Limitations",
  "",
  "S31 does not reconstruct theta_tot.",
  "S31 does not reconstruct productive capacity.",
  "S31 does not compute mu.",
  "S31 does not choose utilization anchors.",
  "S31 does not read S40 outputs.",
  "S31 does not activate S40.",
  "",
  "## 12. Required Human Decisions Before S40 Can Be Unparked",
  "",
  paste(
    "Human review must adjudicate the S30 coefficient evidence, decide whether",
    "an admissible coefficient object can be promoted, document the preferred",
    "A00/A03 interpretation, and only then explicitly unpark S40. S31 does not",
    "perform that promotion."
  )
)
writeLines(report_lines, output_paths["report"], useBytes = TRUE)

cat("US S31 estimation-table export complete.\n")
cat("Output folder: ", out_dir, "\n", sep = "")
cat("Outputs written:\n")
cat(paste0("  ", output_paths, "\n"), sep = "")
