###############################################################################
# US_S40_review_and_figures.R
# Chapter 2 - US S40 restricted B1 review and figures
#
# Role:
#   Reviews and visualizes existing S40 restricted B1 reconstruction outputs.
#
# Guardrails:
#   - Reads only output/US/S40_theta_tot_mu_reconstruction.
#   - Writes only output/US/S40_review_and_figures.
#   - Does not reconstruct new objects.
#   - Does not estimate any new model.
#   - Does not modify S40 reconstruction outputs.
#   - Does not compute profitability or move toward S50.
###############################################################################

# ---- 0. Paths ----------------------------------------------------------------
REPO <- Sys.getenv("CU_REPO", unset = "C:/ReposGitHub/Capacity-Utilization-US_Chile")

input_dir <- file.path(REPO, "output/US/S40_theta_tot_mu_reconstruction")
output_dir <- file.path(REPO, "output/US/S40_review_and_figures")

required_inputs <- c(
  theta_tot_path = "us_s40_theta_tot_path.csv",
  productive_capacity_path = "us_s40_productive_capacity_path.csv",
  mu_path = "us_s40_mu_path.csv",
  anchor_register = "us_s40_anchor_register.csv",
  fragility_register = "us_s40_fragility_register.csv",
  reconstruction_manifest = "us_s40_reconstruction_manifest.csv"
)

input_paths <- file.path(input_dir, required_inputs)
names(input_paths) <- names(required_inputs)

review_checks_path <- file.path(output_dir, "us_s40_review_checks.csv")
mu_summary_path <- file.path(output_dir, "us_s40_mu_summary.csv")
theta_summary_path <- file.path(output_dir, "us_s40_theta_summary.csv")
anchor_window_summary_path <- file.path(output_dir, "us_s40_anchor_window_summary.csv")
report_path <- file.path(output_dir, "US_S40_review_and_figures_report.md")

fig_mu_png <- file.path(output_dir, "fig_us_s40_mu_path.png")
fig_mu_pdf <- file.path(output_dir, "fig_us_s40_mu_path.pdf")
fig_y_png <- file.path(output_dir, "fig_us_s40_y_ycapacity_path.png")
fig_y_pdf <- file.path(output_dir, "fig_us_s40_y_ycapacity_path.pdf")
fig_theta_png <- file.path(output_dir, "fig_us_s40_theta_tot_path.png")
fig_theta_pdf <- file.path(output_dir, "fig_us_s40_theta_tot_path.pdf")

RUN_TIMESTAMP <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
TOL <- 1e-4
MU_DIAGNOSTIC_LOWER <- 0
MU_DIAGNOSTIC_UPPER <- 2.5

# ---- 1. Helpers --------------------------------------------------------------
read_csv_base <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

write_csv_base <- function(df, path) {
  utils::write.csv(df, path, row.names = FALSE, na = "")
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

as_bool <- function(x) {
  if (is.logical(x)) return(x)
  y <- tolower(trimws(as.character(x)))
  out <- rep(NA, length(y))
  out[y %in% c("true", "t", "1", "yes", "y")] <- TRUE
  out[y %in% c("false", "f", "0", "no", "n")] <- FALSE
  out
}

as_num <- function(x) suppressWarnings(as.numeric(x))

all_true <- function(x) {
  y <- as_bool(x)
  length(y) > 0L && all(y %in% TRUE)
}

all_false <- function(x) {
  y <- as_bool(x)
  length(y) > 0L && all(y %in% FALSE)
}

manifest_value <- function(manifest, item) {
  hit <- manifest$value[manifest$item == item]
  if (length(hit) == 0L || is.na(hit[1L]) || !nzchar(hit[1L])) return(NA_character_)
  hit[1L]
}

safe_mean <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) return(NA_real_)
  mean(x)
}

safe_sd <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) < 2L) return(NA_real_)
  stats::sd(x)
}

summary_stats <- function(x) {
  x <- as_num(x)
  x <- x[is.finite(x)]
  if (length(x) == 0L) {
    return(data.frame(
      n = 0L, min = NA_real_, q25 = NA_real_, mean = NA_real_,
      median = NA_real_, q75 = NA_real_, max = NA_real_, sd = NA_real_
    ))
  }
  data.frame(
    n = length(x),
    min = min(x),
    q25 = as.numeric(stats::quantile(x, 0.25, names = FALSE)),
    mean = mean(x),
    median = stats::median(x),
    q75 = as.numeric(stats::quantile(x, 0.75, names = FALSE)),
    max = max(x),
    sd = if (length(x) >= 2L) stats::sd(x) else NA_real_
  )
}

has_profitability_columns <- function(...) {
  dfs <- list(...)
  cols <- unique(unlist(lapply(dfs, names), use.names = FALSE))
  any(grepl("profit|profitability|profit_rate", cols, ignore.case = TRUE))
}

check_row <- function(check_id, required_condition, observed_value, passed, tolerance = NA_real_, notes = "") {
  data.frame(
    check_id = check_id,
    required_condition = required_condition,
    observed_value = as.character(observed_value),
    passed = isTRUE(passed),
    tolerance = tolerance,
    notes = notes,
    stringsAsFactors = FALSE
  )
}

md_table <- function(df, n = Inf) {
  if (is.null(df) || nrow(df) == 0L) return("_No rows._")
  df <- head(df, n)
  df[] <- lapply(df, function(x) {
    if (is.numeric(x)) {
      ifelse(is.na(x), "", formatC(x, digits = 6, format = "fg"))
    } else {
      y <- as.character(x)
      y[is.na(y)] <- ""
      y
    }
  })
  header <- paste0("| ", paste(names(df), collapse = " | "), " |")
  sep <- paste0("| ", paste(rep("---", ncol(df)), collapse = " | "), " |")
  rows <- apply(df, 1L, function(z) paste0("| ", paste(z, collapse = " | "), " |"))
  c(header, sep, rows)
}

plot_to_files <- function(png_path, pdf_path, draw_fn) {
  grDevices::png(png_path, width = 1800, height = 1100, res = 180)
  draw_fn()
  grDevices::dev.off()

  grDevices::pdf(pdf_path, width = 10, height = 6.4)
  draw_fn()
  grDevices::dev.off()
}

add_anchor_shade <- function(year_min, year_max, y_min, y_max) {
  graphics::rect(
    xleft = year_min,
    ybottom = y_min,
    xright = year_max,
    ytop = y_max,
    col = grDevices::adjustcolor("grey80", alpha.f = 0.45),
    border = NA
  )
}

# ---- 2. Read and validate inputs --------------------------------------------
missing_inputs <- names(input_paths)[!file.exists(input_paths)]
if (length(missing_inputs) > 0L) {
  stop(
    "Missing required S40 input file(s): ",
    paste(unname(required_inputs[missing_inputs]), collapse = ", "),
    call. = FALSE
  )
}

theta_tot_path_df <- read_csv_base(input_paths[["theta_tot_path"]])
productive_capacity_path_df <- read_csv_base(input_paths[["productive_capacity_path"]])
mu_path_df <- read_csv_base(input_paths[["mu_path"]])
anchor_register <- read_csv_base(input_paths[["anchor_register"]])
fragility_register <- read_csv_base(input_paths[["fragility_register"]])
manifest <- read_csv_base(input_paths[["reconstruction_manifest"]])

require_cols(theta_tot_path_df, c("year", "theta_tot", "fragility_flag"), "us_s40_theta_tot_path.csv")
require_cols(
  productive_capacity_path_df,
  c("year", "Y_real", "Yp", "fragility_flag"),
  "us_s40_productive_capacity_path.csv"
)
require_cols(
  mu_path_df,
  c(
    "year", "Y_real", "Yp", "mu_t", "mu_formula", "anchor_window_id",
    "anchor_year_start", "anchor_year_end", "fragility_flag"
  ),
  "us_s40_mu_path.csv"
)
require_cols(
  anchor_register,
  c(
    "anchor_variable", "anchor_window", "anchor_year_start",
    "anchor_year_end", "anchor_value", "anchor_check_mean_mu",
    "fragility_flag"
  ),
  "us_s40_anchor_register.csv"
)
require_cols(
  fragility_register,
  c(
    "fragility_flag", "s40_admissibility_status", "dols_reconstruction_basis",
    "dols_veto"
  ),
  "us_s40_fragility_register.csv"
)
require_cols(manifest, c("item", "value"), "us_s40_reconstruction_manifest.csv")

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# ---- 3. Review checks --------------------------------------------------------
mu_year <- as.integer(as_num(mu_path_df$year))
mu <- as_num(mu_path_df$mu_t)
mu_y <- as_num(mu_path_df$Y_real)
mu_yp <- as_num(mu_path_df$Yp)

cap_year <- as.integer(as_num(productive_capacity_path_df$year))
cap_y <- as_num(productive_capacity_path_df$Y_real)
cap_yp <- as_num(productive_capacity_path_df$Yp)

theta_year <- as.integer(as_num(theta_tot_path_df$year))
theta_tot <- as_num(theta_tot_path_df$theta_tot)

anchor_start <- as.integer(as_num(anchor_register$anchor_year_start[1L]))
anchor_end <- as.integer(as_num(anchor_register$anchor_year_end[1L]))
anchor_window <- anchor_register$anchor_window[1L]
anchor_rows <- mu_year >= anchor_start & mu_year <= anchor_end
anchor_mean_mu <- safe_mean(mu[anchor_rows])
finite_mu <- mu[is.finite(mu)]
mu_range_text <- if (length(finite_mu) == 0L) {
  "no finite mu_t values"
} else {
  paste0("range=", min(finite_mu), "-", max(finite_mu))
}
mu_nonpathological <- length(mu) > 0L &&
  all(is.finite(mu)) &&
  all(mu > MU_DIAGNOSTIC_LOWER & mu < MU_DIAGNOSTIC_UPPER)

fragility_all_true <- all_true(mu_path_df$fragility_flag) &&
  all_true(theta_tot_path_df$fragility_flag) &&
  all_true(productive_capacity_path_df$fragility_flag) &&
  all_true(anchor_register$fragility_flag) &&
  all_true(fragility_register$fragility_flag) &&
  identical(manifest_value(manifest, "fragility_flag"), "TRUE")

manifest_profitability_false <- identical(manifest_value(manifest, "profitability_computed"), "FALSE")
manifest_chile_false <- identical(manifest_value(manifest, "chile_outputs_touched"), "FALSE")
manifest_hard_false <- identical(manifest_value(manifest, "hard_prohibitions_violated"), "FALSE")

profitability_columns_detected <- has_profitability_columns(
  theta_tot_path_df,
  productive_capacity_path_df,
  mu_path_df,
  anchor_register,
  fragility_register
)

checks <- do.call(
  rbind,
  list(
    check_row(
      "fragility_flag_true",
      "fragility_flag = TRUE",
      fragility_all_true,
      fragility_all_true,
      notes = "Checked path tables, registers, and reconstruction manifest."
    ),
    check_row(
      "s40_admissibility_status",
      "s40_admissibility_status = admissible_restricted_b1_under_fragility",
      paste(unique(fragility_register$s40_admissibility_status), collapse = "; "),
      all(fragility_register$s40_admissibility_status == "admissible_restricted_b1_under_fragility")
    ),
    check_row(
      "dols_reconstruction_basis_false",
      "dols_reconstruction_basis = FALSE",
      paste(unique(fragility_register$dols_reconstruction_basis), collapse = "; "),
      all_false(fragility_register$dols_reconstruction_basis)
    ),
    check_row(
      "dols_veto_false",
      "dols_veto = FALSE",
      paste(unique(fragility_register$dols_veto), collapse = "; "),
      all_false(fragility_register$dols_veto)
    ),
    check_row(
      "mu_formula",
      "mu_formula = Y_real / Yp",
      paste(unique(mu_path_df$mu_formula), collapse = "; "),
      all(mu_path_df$mu_formula == "Y_real / Yp")
    ),
    check_row(
      "anchor_window",
      "anchor window = fordist_core",
      anchor_window,
      identical(anchor_window, "fordist_core")
    ),
    check_row(
      "anchor_years",
      "anchor years = 1945-1973",
      paste(anchor_start, anchor_end, sep = "-"),
      identical(anchor_start, 1945L) && identical(anchor_end, 1973L)
    ),
    check_row(
      "anchor_mean_mu",
      "anchor mean(mu_t) = 1 within tolerance",
      anchor_mean_mu,
      is.finite(anchor_mean_mu) && abs(anchor_mean_mu - 1) <= TOL,
      tolerance = TOL
    ),
    check_row(
      "all_mu_finite",
      "all mu_t values finite",
      paste0(sum(is.finite(mu)), "/", length(mu), " finite"),
      length(mu) > 0L && all(is.finite(mu))
    ),
    check_row(
      "mu_nonpathological",
      "diagnostic guardrail: 0 < mu_t < 2.5",
      mu_range_text,
      mu_nonpathological,
      notes = "Diagnostic guardrail only; not a theoretical restriction on utilization."
    ),
    check_row(
      "all_yp_positive_finite",
      "all Yp values positive and finite",
      paste0(sum(is.finite(mu_yp) & mu_yp > 0), "/", length(mu_yp), " positive finite"),
      length(mu_yp) > 0L && all(is.finite(mu_yp) & mu_yp > 0) &&
        all(is.finite(cap_yp) & cap_yp > 0)
    ),
    check_row(
      "no_profitability_variables",
      "no profitability variables",
      paste0(
        "profitability_columns_detected=", profitability_columns_detected,
        "; manifest_profitability_computed=", manifest_value(manifest, "profitability_computed")
      ),
      !profitability_columns_detected && manifest_profitability_false
    ),
    check_row(
      "no_chile_outputs",
      "no Chile outputs",
      paste0("manifest_chile_outputs_touched=", manifest_value(manifest, "chile_outputs_touched")),
      manifest_chile_false
    ),
    check_row(
      "hard_prohibitions_violated",
      "hard_prohibitions_violated = FALSE",
      manifest_value(manifest, "hard_prohibitions_violated"),
      manifest_hard_false
    )
  )
)

failed_checks <- checks[!checks$passed, , drop = FALSE]

# ---- 4. Summaries ------------------------------------------------------------
mu_stats <- summary_stats(mu)
mu_summary <- data.frame(
  run_timestamp = RUN_TIMESTAMP,
  variable = "mu_t",
  year_min = min(mu_year, na.rm = TRUE),
  year_max = max(mu_year, na.rm = TRUE),
  mu_stats,
  anchor_window = anchor_window,
  anchor_year_start = anchor_start,
  anchor_year_end = anchor_end,
  anchor_mean_mu = anchor_mean_mu,
  fragility_flag = TRUE,
  stringsAsFactors = FALSE
)

theta_stats <- summary_stats(theta_tot)
theta_summary <- data.frame(
  run_timestamp = RUN_TIMESTAMP,
  variable = "theta_tot",
  year_min = min(theta_year, na.rm = TRUE),
  year_max = max(theta_year, na.rm = TRUE),
  theta_stats,
  fragility_flag = TRUE,
  figure_scope = "theta_tot_only",
  stringsAsFactors = FALSE
)

anchor_window_summary <- data.frame(
  run_timestamp = RUN_TIMESTAMP,
  anchor_window = anchor_window,
  anchor_year_start = anchor_start,
  anchor_year_end = anchor_end,
  observations = sum(anchor_rows),
  mean_mu_t = anchor_mean_mu,
  min_mu_t = min(mu[anchor_rows], na.rm = TRUE),
  max_mu_t = max(mu[anchor_rows], na.rm = TRUE),
  sd_mu_t = safe_sd(mu[anchor_rows]),
  mean_Y_real = safe_mean(mu_y[anchor_rows]),
  mean_Yp = safe_mean(mu_yp[anchor_rows]),
  mean_theta_tot = safe_mean(theta_tot[theta_year >= anchor_start & theta_year <= anchor_end]),
  anchor_tolerance = TOL,
  anchor_mean_passed = is.finite(anchor_mean_mu) && abs(anchor_mean_mu - 1) <= TOL,
  fragility_flag = TRUE,
  stringsAsFactors = FALSE
)

write_csv_base(checks, review_checks_path)
write_csv_base(mu_summary, mu_summary_path)
write_csv_base(theta_summary, theta_summary_path)
write_csv_base(anchor_window_summary, anchor_window_summary_path)

# ---- 5. Figures --------------------------------------------------------------
plot_to_files(fig_mu_png, fig_mu_pdf, function() {
  ylim <- range(mu, na.rm = TRUE)
  pad <- diff(ylim) * 0.08
  if (!is.finite(pad) || pad == 0) pad <- 0.05
  ylim <- c(ylim[1L] - pad, ylim[2L] + pad)
  graphics::plot(mu_year, mu, type = "n", xlab = "Year", ylab = "mu_t", ylim = ylim)
  add_anchor_shade(anchor_start, anchor_end, ylim[1L], ylim[2L])
  graphics::abline(h = 1, col = "grey35", lty = 2, lwd = 1.2)
  graphics::lines(mu_year, mu, col = "#1f6f8b", lwd = 2.2)
  graphics::box()
  graphics::title(
    main = "US S40 mu_t path: restricted B1 under fragility",
    sub = "Shaded anchor window: fordist_core, 1945-1973; anchor mean(mu_t)=1"
  )
  graphics::legend(
    "topright",
    legend = c("mu_t", "anchor mean = 1", "anchor window"),
    col = c("#1f6f8b", "grey35", grDevices::adjustcolor("grey80", alpha.f = 0.45)),
    lty = c(1, 2, NA),
    lwd = c(2.2, 1.2, NA),
    pch = c(NA, NA, 15),
    bty = "n"
  )
})

plot_to_files(fig_y_png, fig_y_pdf, function() {
  ylim <- range(c(cap_y, cap_yp), na.rm = TRUE)
  pad <- diff(ylim) * 0.08
  if (!is.finite(pad) || pad == 0) pad <- 1
  ylim <- c(ylim[1L] - pad, ylim[2L] + pad)
  graphics::plot(cap_year, cap_y, type = "n", xlab = "Year", ylab = "Real output", ylim = ylim)
  add_anchor_shade(anchor_start, anchor_end, ylim[1L], ylim[2L])
  graphics::lines(cap_year, cap_y, col = "#2b5d34", lwd = 2.1)
  graphics::lines(cap_year, cap_yp, col = "#8c3f2b", lwd = 2.1)
  graphics::box()
  graphics::title(
    main = "US S40 observed Y and reconstructed Yp: restricted B1 under fragility",
    sub = "Observed Y_real compared with reconstructed productive capacity Yp"
  )
  graphics::legend(
    "topleft",
    legend = c("Observed Y_real", "Reconstructed Yp", "anchor window"),
    col = c("#2b5d34", "#8c3f2b", grDevices::adjustcolor("grey80", alpha.f = 0.45)),
    lty = c(1, 1, NA),
    lwd = c(2.1, 2.1, NA),
    pch = c(NA, NA, 15),
    bty = "n"
  )
})

plot_to_files(fig_theta_png, fig_theta_pdf, function() {
  ylim <- range(theta_tot, na.rm = TRUE)
  pad <- diff(ylim) * 0.08
  if (!is.finite(pad) || pad == 0) pad <- 0.05
  ylim <- c(ylim[1L] - pad, ylim[2L] + pad)
  graphics::plot(theta_year, theta_tot, type = "n", xlab = "Year", ylab = "theta_tot", ylim = ylim)
  add_anchor_shade(anchor_start, anchor_end, ylim[1L], ylim[2L])
  graphics::lines(theta_year, theta_tot, col = "#4f5d95", lwd = 2.2)
  graphics::box()
  graphics::title(
    main = "US S40 theta_tot path: restricted B1 under fragility",
    sub = "Theta figure reports theta_tot only; theta_M is not directly estimated"
  )
  graphics::legend(
    "topright",
    legend = c("theta_tot", "anchor window"),
    col = c("#4f5d95", grDevices::adjustcolor("grey80", alpha.f = 0.45)),
    lty = c(1, NA),
    lwd = c(2.2, NA),
    pch = c(NA, 15),
    bty = "n"
  )
})

# ---- 6. Report ---------------------------------------------------------------
created_files <- c(
  review_checks_path,
  mu_summary_path,
  theta_summary_path,
  anchor_window_summary_path,
  report_path,
  fig_mu_png,
  fig_mu_pdf,
  fig_y_png,
  fig_y_pdf,
  fig_theta_png,
  fig_theta_pdf
)

hard_prohibition_violated <- !manifest_hard_false ||
  profitability_columns_detected ||
  !manifest_profitability_false ||
  !manifest_chile_false ||
  !all_false(fragility_register$dols_reconstruction_basis)

report_lines <- c(
  "# US S40 Review and Figures Report",
  "",
  "## 1. Purpose",
  "",
  paste(
    "This pass reviews and visualizes the existing S40 restricted B1",
    "reconstruction outputs. It does not reconstruct new objects, estimate",
    "new models, alter S40 outputs, compute profitability, or move toward S50."
  ),
  "",
  "All figures are labeled as restricted B1 under fragility.",
  paste(
    "The anchor check uses a reconstruction-consistency tolerance rather than",
    "an exact-arithmetic tolerance. The bounded mu_t check is a diagnostic",
    "guardrail against bad anchoring, coding errors, or explosive paths; it is",
    "not a theory restriction."
  ),
  "",
  "## 2. Required checks",
  "",
  md_table(checks),
  "",
  "## 3. Failed checks",
  "",
  if (nrow(failed_checks) == 0L) "- none" else md_table(failed_checks),
  "",
  "## 4. Summaries",
  "",
  "### mu_t",
  "",
  md_table(mu_summary),
  "",
  "### theta_tot",
  "",
  md_table(theta_summary),
  "",
  "### Anchor window",
  "",
  md_table(anchor_window_summary),
  "",
  "## 5. Hard prohibitions",
  "",
  paste0("- Hard prohibition violated: ", hard_prohibition_violated),
  "- No new model was estimated.",
  "- No S40 reconstruction output was modified.",
  "- DOLS was not used as a reconstruction basis.",
  "- Profitability was not computed.",
  "- Chile and comparative outputs were not touched.",
  "",
  "## 6. Output files",
  "",
  md_table(data.frame(file = basename(created_files), path = created_files, stringsAsFactors = FALSE))
)

writeLines(report_lines, report_path, useBytes = TRUE)

message("US S40 review and figures complete.")
message("Failed checks: ", nrow(failed_checks))
message("Hard prohibition violated: ", hard_prohibition_violated)
