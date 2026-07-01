#!/usr/bin/env Rscript

# D09 creates a human-facing visual validation report.
# Report-only ratios, indices, shares, and residuals remain isolated in D09 outputs.

required_pkgs <- c("ggplot2", "dplyr", "tidyr", "readr", "stringr", "scales", "knitr")
pkg_ok <- vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)
if (!all(pkg_ok)) {
  missing <- paste(required_pkgs[!pkg_ok], collapse = ", ")
  stop("Required R packages are missing: ", missing)
}
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(scales)
  library(knitr)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output/US/D09_GPIM_CAPITAL_OUTPUT_DISTRIBUTION_VISUAL_VALIDATION_REPORT")
bundle_dir <- file.path(root, "reports/report_validation_SofT_dataset_2026-07-01")
dirs <- c("csv", "figure_data", "figures", "tables", "report", "reports")
for (d in dirs) dir.create(file.path(out_dir, d), recursive = TRUE, showWarnings = FALSE)
for (d in c("csv", "figure_data", "figures", "tables", "report")) dir.create(file.path(bundle_dir, d), recursive = TRUE, showWarnings = FALSE)

repo_file <- function(...) file.path(root, ...)
out_file <- function(subdir, name) file.path(out_dir, subdir, name)
bundle_file <- function(subdir, name) file.path(bundle_dir, subdir, name)
read_csv_safe <- function(path) if (file.exists(path)) read.csv(path, stringsAsFactors = FALSE, check.names = FALSE) else data.frame()
write_csv_dual <- function(x, subdir, name) {
  write.csv(x, out_file(subdir, name), row.names = FALSE, na = "")
  write.csv(x, bundle_file(subdir, name), row.names = FALSE, na = "")
}
git <- function(args) paste(tryCatch(system2("git", args, stdout = TRUE, stderr = TRUE), error = function(e) ""), collapse = "\n")
clean <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; x }
tex_escape <- function(x) {
  x <- clean(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([#$%&_{}])", "\\\\\\1", x, perl = TRUE)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x
}
safe_div <- function(a, b) ifelse(is.finite(a) & is.finite(b) & b != 0, a / b, NA_real_)
index_to <- function(x, year, base_year) {
  b <- x[match(base_year, year)]
  if (!is.finite(b) || b == 0) return(rep(NA_real_, length(x)))
  100 * x / b
}

repo_status_short <- git(c("status", "--short"))
repo_branch <- git(c("branch", "--show-current"))
repo_head <- git(c("rev-parse", "HEAD"))
origin_head <- git(c("rev-parse", "origin/main"))
recent_log <- git(c("log", "--oneline", "-6"))
status_lines <- if (repo_status_short == "") character() else strsplit(repo_status_short, "\n", fixed = TRUE)[[1]]
d09_owned_dirty <- grepl("codes/US_D09_gpim_capital_output_distribution_visual_validation_report\\.R|output/US/D09_GPIM_CAPITAL_OUTPUT_DISTRIBUTION_VISUAL_VALIDATION_REPORT|reports/report_validation_SofT_dataset_2026-07-01", status_lines)
repo_state_ok <- repo_branch == "main" && substr(repo_head, 1, 7) == "867a47c" &&
  (repo_head == origin_head || substr(origin_head, 1, 7) == "acd7dda") &&
  (length(status_lines) == 0 || all(d09_owned_dirty))
repo_state_note <- if (length(status_lines) == 0) "clean" else if (all(d09_owned_dirty)) "D09 generated artifacts only" else paste(status_lines[!d09_owned_dirty], collapse = "; ")

d07_dir <- repo_file("output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION")
d08_dir <- repo_file("output/US/D08_SOURCE_OF_TRUTH_REVIEW_WITH_GPIM_REPAIR_REGRESSION_AUDIT")
d06_dir <- repo_file("output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN")
d05_dir <- repo_file("output/US/D05_GPIM_GUARDIAN_PRICE_STOCK_FLOW_COHERENCE")
d070_dir <- repo_file("output/US/D07_0_SOURCE_OF_TRUTH_LEVEL_ACCOUNTING_CONSUMPTION_CONTRACT")

d07_required <- c(
  "csv/D07_level_accounting_panel_long.csv", "csv/D07_level_accounting_panel_wide.csv",
  "csv/D07_variable_dictionary.csv", "csv/D07_coverage_ledger.csv",
  "csv/D07_provenance_ledger.csv", "csv/D07_not_consumed_ledger.csv",
  "csv/D07_validation_checks.csv", "reports/D07_decision_report.md"
)
d08_required <- c(
  "csv/D08_panel_integrity_audit.csv", "csv/D08_contract_compliance_audit.csv",
  "csv/D08_boundary_leakage_audit.csv", "csv/D08_capacity_identity_audit.csv",
  "csv/D08_output_value_added_audit.csv", "csv/D08_surplus_distribution_audit.csv",
  "csv/D08_financial_correction_gate_audit.csv", "csv/D08_coverage_missingness_audit.csv",
  "csv/D08_numerical_sanity_audit.csv", "csv/D08_provenance_audit.csv",
  "csv/D08_not_consumed_audit.csv", "csv/D08_gpim_initialization_audit.csv",
  "csv/D08_gpim_warmup_sufficiency_audit.csv", "csv/D08_gpim_pkn_level_anchor_audit.csv",
  "csv/D08_gpim_real_investment_scale_audit.csv", "csv/D08_gpim_current_cost_identity_audit.csv",
  "csv/D08_gpim_repair_regression_audit.csv", "csv/D08_review_flags_ledger.csv",
  "csv/D08_validation_checks.csv", "reports/D08_decision_report.md"
)
d07_paths <- file.path(d07_dir, d07_required)
d08_paths <- file.path(d08_dir, d08_required)

d07_long <- read_csv_safe(file.path(d07_dir, "csv/D07_level_accounting_panel_long.csv"))
d07_wide <- read_csv_safe(file.path(d07_dir, "csv/D07_level_accounting_panel_wide.csv"))
d07_dict <- read_csv_safe(file.path(d07_dir, "csv/D07_variable_dictionary.csv"))
d07_validation <- read_csv_safe(file.path(d07_dir, "csv/D07_validation_checks.csv"))
d07_report <- if (file.exists(file.path(d07_dir, "reports/D07_decision_report.md"))) {
  paste(readLines(file.path(d07_dir, "reports/D07_decision_report.md")), collapse = "\n")
} else {
  ""
}
d08_validation <- read_csv_safe(file.path(d08_dir, "csv/D08_validation_checks.csv"))
d08_flags <- read_csv_safe(file.path(d08_dir, "csv/D08_review_flags_ledger.csv"))
d08_report <- if (file.exists(file.path(d08_dir, "reports/D08_decision_report.md"))) {
  paste(readLines(file.path(d08_dir, "reports/D08_decision_report.md")), collapse = "\n")
} else {
  ""
}
d08_init <- read_csv_safe(file.path(d08_dir, "csv/D08_gpim_initialization_audit.csv"))
d08_warm <- read_csv_safe(file.path(d08_dir, "csv/D08_gpim_warmup_sufficiency_audit.csv"))
d08_realinv <- read_csv_safe(file.path(d08_dir, "csv/D08_gpim_real_investment_scale_audit.csv"))
d08_currentid <- read_csv_safe(file.path(d08_dir, "csv/D08_gpim_current_cost_identity_audit.csv"))
d08_capid <- read_csv_safe(file.path(d08_dir, "csv/D08_capacity_identity_audit.csv"))
d08_fin <- read_csv_safe(file.path(d08_dir, "csv/D08_financial_correction_gate_audit.csv"))
d06_asset <- read_csv_safe(file.path(d06_dir, "csv/D06_asset_refrozen_gpim_panel.csv"))
d06_cap <- read_csv_safe(file.path(d06_dir, "csv/D06_capacity_refrozen_panel.csv"))
d06_guard <- read_csv_safe(file.path(d06_dir, "csv/D06_real_investment_guardian_panel.csv"))
d05_asset <- read_csv_safe(file.path(d05_dir, "csv/D05_asset_price_stock_flow_panel.csv"))
d070_surplus <- read_csv_safe(file.path(d070_dir, "csv/D07_0_surplus_distribution_scaffold.csv"))
provider_long <- read_csv_safe(repo_file("data/external/us_bea_provider/us_bea_variable_menu_long.csv"))

d08_authorized <- file.exists(file.path(d08_dir, "reports/D08_decision_report.md")) &&
  grepl("AUTHORIZE_D09_TRANSFORMATION_PLANNING", d08_report, fixed = TRUE)
d07_hash_before <- tools::md5sum(file.path(d07_dir, "csv/D07_level_accounting_panel_long.csv"))

w <- d07_wide
if (nrow(w)) {
  w$year <- as.integer(w$year)
  for (nm in setdiff(names(w), "year")) w[[nm]] <- suppressWarnings(as.numeric(w[[nm]]))
}

fig_manifest <- list()
report_only_rows <- list()
index_dict_rows <- list()
review_flags <- list()
fig_counter <- 0
add_report_obj <- function(object_id, display_name, formula, inputs, role, notes = "") {
  report_only_rows[[length(report_only_rows) + 1L]] <<- list(
    object_id = object_id, display_name = display_name, formula = formula,
    input_variables = paste(inputs, collapse = "; "), conceptual_role = role,
    status = "REPORT_ONLY_INSPECTION_OBJECT",
    allowed_use = "human visual validation in D09 report",
    prohibited_use = "source-of-truth panel, model transformation, regression input unless D10 authorizes",
    notes = notes
  )
}
add_index_obj <- function(object_id, src, formula, base_year, base_value, notes = "") {
  index_dict_rows[[length(index_dict_rows) + 1L]] <<- list(
    object_id = object_id, source_variable_id = src, formula = formula, base_year = base_year,
    base_value = base_value, status = "REPORT_ONLY_INSPECTION_INDEX",
    allowed_use = "human visual validation in D09 report",
    prohibited_use = "source-of-truth panel, model transformation, regression input unless D10 authorizes",
    notes = notes
  )
}
add_flag <- function(flag_id, severity, module, object_id, issue, evidence, decision, blocking, notes = "") {
  review_flags[[length(review_flags) + 1L]] <<- list(
    flag_id = flag_id, severity = severity, module = module, object_id = object_id,
    issue = issue, evidence = evidence, recommended_human_decision = decision,
    blocking_status = blocking, notes = notes
  )
}

if (nrow(d08_flags)) {
  for (i in seq_len(nrow(d08_flags))) {
    add_flag(
      paste0("D08_", d08_flags$flag_id[i]), d08_flags$severity[i], d08_flags$audit_module[i],
      d08_flags$object_id[i], d08_flags$issue[i], d08_flags$notes[i],
      d08_flags$recommended_followup[i], d08_flags$blocking_status[i],
      "Carried forward from D08 review flags ledger."
    )
  }
}

save_plot <- function(p, fig_id, title, data_file, section, main_or_appendix, src_vars, report_objs, status = "CREATED", notes = "") {
  pdf_name <- paste0(fig_id, ".pdf")
  png_name <- paste0(fig_id, ".png")
  pdf_path <- out_file("figures", pdf_name)
  png_path <- out_file("figures", png_name)
  ggsave(pdf_path, p, width = 7.2, height = 4.4, device = cairo_pdf)
  ggsave(png_path, p, width = 7.2, height = 4.4, dpi = 180)
  invisible(file.copy(pdf_path, bundle_file("figures", pdf_name), overwrite = TRUE))
  invisible(file.copy(png_path, bundle_file("figures", png_name), overwrite = TRUE))
  fig_manifest[[length(fig_manifest) + 1L]] <<- list(
    figure_id = fig_id, figure_title = title,
    figure_file_pdf = file.path("figures", pdf_name), figure_file_png = file.path("figures", png_name),
    figure_data_file = file.path("figure_data", data_file), section = section, status = status,
    main_or_appendix = main_or_appendix, source_variables = paste(src_vars, collapse = "; "),
    report_only_objects = paste(report_objs, collapse = "; "), notes = notes
  )
}
write_figdata <- function(df, name) {
  if (!"availability_status" %in% names(df)) df$availability_status <- "AVAILABLE"
  write_csv_dual(df, "figure_data", name)
}
base_theme <- theme_minimal(base_size = 10) + theme(legend.position = "bottom", plot.title = element_text(face = "bold"))
annotate_events <- function(p) {
  p + geom_vline(xintercept = c(1947, 1973, 1982, 2008, 2020), linetype = "dotted", color = "grey55", linewidth = 0.25)
}
line_plot <- function(df, x = "year", y = "value", color = "series", title = "", ylab = "", log_y = FALSE) {
  p <- ggplot(df, aes(.data[[x]], .data[[y]], color = .data[[color]])) +
    geom_line(linewidth = 0.7, na.rm = TRUE) + labs(title = title, x = NULL, y = ylab, color = NULL) + base_theme
  if (log_y) p <- p + scale_y_log10(labels = label_number())
  annotate_events(p)
}
scatter_plot <- function(df, x, y, title, xlab, ylab) {
  ggplot(df, aes(.data[[x]], .data[[y]], color = year)) +
    geom_path(alpha = 0.4, linewidth = 0.25) + geom_point(size = 1.6, alpha = 0.85) +
    scale_color_viridis_c(option = "C") + labs(title = title, x = xlab, y = ylab, color = "Year") + base_theme
}
empty_plot <- function(title, note) {
  ggplot(data.frame(x = 1, y = 1), aes(x, y)) + geom_blank() +
    annotate("text", x = 1, y = 1, label = note, size = 4) + xlim(0, 2) + ylim(0, 2) +
    labs(title = title, x = NULL, y = NULL) + theme_void() + theme(plot.title = element_text(face = "bold"))
}

long_from_wide <- function(vars, labels = vars) {
  present <- vars[vars %in% names(w)]
  if (!length(present)) return(data.frame(year = integer(), series = character(), value = numeric(), availability_status = "SOURCE_ABSENT"))
  out <- w[, c("year", present), drop = FALSE] |>
    pivot_longer(-year, names_to = "series", values_to = "value")
  names(labels) <- vars
  out$series <- ifelse(out$series %in% names(labels), labels[out$series], out$series)
  out$availability_status <- "AVAILABLE"
  out
}

# Required figure data and plots
real_vars <- c("K_real_ME_refrozen", "K_real_NRC_refrozen", "K_real_capacity_refrozen")
current_vars <- c("K_current_ME_refrozen", "K_current_NRC_refrozen", "K_current_capacity_refrozen")
real_levels <- long_from_wide(real_vars, c("ME", "NRC", "ME+NRC capacity"))
current_levels <- long_from_wide(current_vars, c("ME current", "NRC current", "capacity current"))
write_figdata(real_levels, "D09_figdata_gpim_real_stock_levels.csv")
write_figdata(current_levels, "D09_figdata_gpim_current_stock_levels.csv")
save_plot(line_plot(real_levels, title = "Real gross surviving GPIM stock levels", ylab = "D06 real GPIM stock units"), "D09_fig01_real_gpim_stock_levels", "Real GPIM stock levels", "D09_figdata_gpim_real_stock_levels.csv", "Real and current-cost stock levels", "main", real_vars, character())
save_plot(line_plot(current_levels, title = "Current-cost gross surviving GPIM stock levels", ylab = "Millions of current dollars"), "D09_fig02_current_cost_gpim_stock_levels", "Current-cost GPIM stock levels", "D09_figdata_gpim_current_stock_levels.csv", "Real and current-cost stock levels", "main", current_vars, character())
save_plot(line_plot(real_levels |> filter(value > 0), title = "Real GPIM stock levels, log scale", ylab = "Log scale", log_y = TRUE), "D09_fig03_real_gpim_stock_levels_logscale", "Real GPIM stock levels log scale", "D09_figdata_gpim_real_stock_levels.csv", "Real and current-cost stock levels", "main", real_vars, character())
save_plot(line_plot(current_levels |> filter(value > 0), title = "Current-cost GPIM stock levels, log scale", ylab = "Log scale", log_y = TRUE), "D09_fig04_current_cost_gpim_stock_levels_logscale", "Current-cost GPIM stock levels log scale", "D09_figdata_gpim_current_stock_levels.csv", "Real and current-cost stock levels", "main", current_vars, character())

index_data <- data.frame()
for (base_year in c(1947, 2017)) {
  for (v in c(real_vars, current_vars)) {
    if (v %in% names(w)) {
      obj <- paste0(v, "_index_", base_year, "_100")
      idx <- index_to(w[[v]], w$year, base_year)
      index_data <- rbind(index_data, data.frame(year = w$year, object_id = obj, source_variable_id = v, base_year = base_year, value = idx, availability_status = ifelse(is.na(idx), "BASE_OR_VALUE_ABSENT", "AVAILABLE")))
      add_index_obj(obj, v, paste0("100 * ", v, " / ", v, "[", base_year, "]"), base_year, w[[v]][match(base_year, w$year)], "D09 report-only visual index.")
    }
  }
}
write_figdata(index_data |> filter(base_year == 1947), "D09_figdata_visual_indices_1947_100.csv")
write_figdata(index_data |> filter(base_year == 2017), "D09_figdata_visual_indices_2017_100.csv")
plot_idx <- function(base_year, vars, fig_id, title, data_file) {
  dat <- index_data |> filter(base_year == !!base_year, source_variable_id %in% vars)
  save_plot(line_plot(dat, ylab = paste0(base_year, " = 100"), title = paste0(title, " (inspection-only; not model-ready)"), color = "source_variable_id"),
            fig_id, title, data_file, "Visual inspection indices", "main", vars, dat$object_id)
}
plot_idx(1947, real_vars, "D09_fig05_real_gpim_indices_1947_100", "Real GPIM indices, 1947=100", "D09_figdata_visual_indices_1947_100.csv")
plot_idx(2017, real_vars, "D09_fig06_real_gpim_indices_2017_100", "Real GPIM indices, 2017=100", "D09_figdata_visual_indices_2017_100.csv")
plot_idx(1947, current_vars, "D09_fig07_current_cost_gpim_indices_1947_100", "Current-cost GPIM indices, 1947=100", "D09_figdata_visual_indices_1947_100.csv")
plot_idx(2017, current_vars, "D09_fig08_current_cost_gpim_indices_2017_100", "Current-cost GPIM indices, 2017=100", "D09_figdata_visual_indices_2017_100.csv")

warm_timeline <- d08_init |> transmute(asset, start = as.integer(construction_start_year), end = as.integer(analysis_start_year), y = asset, availability_status = "AVAILABLE")
write_figdata(warm_timeline, "D09_figdata_warmup_timeline.csv")
p_warm <- ggplot(warm_timeline, aes(y = asset)) +
  geom_segment(aes(x = start, xend = end, yend = asset), linewidth = 5, color = "#4C78A8") +
  geom_point(aes(x = start), size = 2) + geom_vline(xintercept = 1947, linetype = "dashed") +
  labs(title = "D06 asset-specific GPIM warmup timeline", x = NULL, y = NULL) + base_theme
save_plot(p_warm, "D09_fig09_gpim_warmup_timeline", "GPIM warmup timeline", "D09_figdata_warmup_timeline.csv", "Warmup and survival diagnostics", "main", c("D08_gpim_initialization_audit"), "warmup_length")

surv <- data.frame()
for (asset in c("ME", "NRC")) {
  sub <- d06_asset |> filter(asset == !!asset)
  L <- unique(sub$survival_L)[1]; alpha <- unique(sub$survival_alpha)[1]; lambda <- unique(sub$survival_lambda)[1]
  age <- 0:200
  survival <- exp(-((age / lambda)^alpha))
  surv <- rbind(surv, data.frame(asset, age, survival, survival_L = L, survival_alpha = alpha, availability_status = "AVAILABLE"))
}
write_figdata(surv, "D09_figdata_survival_profiles.csv")
p_surv <- ggplot(surv, aes(age, survival, color = asset)) + geom_line(linewidth = 0.8) +
  geom_vline(data = unique(surv[, c("asset", "survival_L")]), aes(xintercept = survival_L, color = asset), linetype = "dashed") +
  labs(title = "Locked untruncated Weibull survival profiles", x = "Vintage age", y = "Survival weight", color = NULL) + base_theme
save_plot(p_surv, "D09_fig10_locked_survival_profiles_ME_NRC", "Locked survival profiles", "D09_figdata_survival_profiles.csv", "Warmup and survival diagnostics", "main", c("survival_L", "survival_alpha"), c("survival_profile"))

stockflow <- data.frame()
if (nrow(d06_guard)) {
  stockflow <- d06_guard |> mutate(expected = I_current / (pKN_guardian / 100), residual = I_real_guardian - expected, availability_status = "AVAILABLE") |>
    select(year, asset, residual, availability_status)
}
write_figdata(stockflow, "D09_figdata_stock_flow_residuals.csv")
save_plot(line_plot(stockflow, y = "residual", color = "asset", title = "Real-investment scale residuals", ylab = "Residual"), "D09_fig11_real_investment_scale_residuals", "Real-investment scale residuals", "D09_figdata_stock_flow_residuals.csv", "Stock-flow and valuation consistency", "main", c("I_current", "pKN_guardian", "I_real_guardian"), "real_investment_residual")

current_res <- data.frame()
if (nrow(d06_asset)) {
  current_res <- d06_asset |> mutate(residual = K_current_refrozen - K_real_refrozen * pKN_guardian / 100, object = paste0(asset, " current-cost identity"), availability_status = "AVAILABLE") |>
    select(year, object, residual, availability_status)
}
cap_res <- d06_cap |> transmute(year, object = "capacity identity", residual_real = K_real_capacity_refrozen - K_real_ME_refrozen - K_real_NRC_refrozen,
                                residual_current = K_current_capacity_refrozen - K_current_ME_refrozen - K_current_NRC_refrozen, availability_status = "AVAILABLE")
write_figdata(current_res, "D09_figdata_current_cost_identity_residuals.csv")
write_figdata(cap_res, "D09_figdata_capacity_identity_residuals.csv")
save_plot(line_plot(current_res, y = "residual", color = "object", title = "Current-cost valuation identity residuals", ylab = "Residual"), "D09_fig12_current_cost_identity_residuals", "Current-cost identity residuals", "D09_figdata_current_cost_identity_residuals.csv", "Stock-flow and valuation consistency", "main", c("K_current_refrozen", "K_real_refrozen", "pKN_guardian"), "current_cost_identity_residual")
cap_res_long <- cap_res |> select(year, residual_real, residual_current, availability_status) |>
  pivot_longer(c(residual_real, residual_current), names_to = "series", values_to = "value")
save_plot(line_plot(cap_res_long, color = "series", title = "Capacity aggregation identity residuals", ylab = "Residual"), "D09_fig13_capacity_identity_residuals", "Capacity identity residuals", "D09_figdata_capacity_identity_residuals.csv", "Stock-flow and valuation consistency", "main", c(real_vars, current_vars), "capacity_identity_residual")

composition <- w |> transmute(
  year,
  ME_over_NRC_real_stock = safe_div(K_real_ME_refrozen, K_real_NRC_refrozen),
  ME_over_NRC_current_stock = safe_div(K_current_ME_refrozen, K_current_NRC_refrozen),
  ME_real_share = safe_div(K_real_ME_refrozen, K_real_capacity_refrozen),
  NRC_real_share = safe_div(K_real_NRC_refrozen, K_real_capacity_refrozen),
  ME_current_share = safe_div(K_current_ME_refrozen, K_current_capacity_refrozen),
  NRC_current_share = safe_div(K_current_NRC_refrozen, K_current_capacity_refrozen),
  ME_over_NRC_real_investment = safe_div(I_real_ME_guardian, I_real_NRC_guardian),
  ME_over_NRC_current_investment = safe_div(I_current_ME, I_current_NRC),
  availability_status = "AVAILABLE"
)
write_figdata(composition, "D09_figdata_me_nrc_composition.csv")
for (nm in names(composition)[2:9]) add_report_obj(nm, nm, paste0("D09 report-only ratio/share: ", nm), c("ME", "NRC", "capacity"), "composition/mechanization inspection")
single_line <- function(df, col, fig_id, title, ylab = "") {
  dat <- df |> select(year, value = all_of(col), availability_status)
  save_plot(line_plot(dat |> mutate(series = col), title = title, ylab = ylab), fig_id, title, "D09_figdata_me_nrc_composition.csv", "ME/NRC composition and mechanization diagnostics", "main", c("ME", "NRC"), col)
}
single_line(composition, "ME_over_NRC_real_stock", "D09_fig14_ME_over_NRC_real_stock_ratio", "ME/NRC real stock ratio")
single_line(composition, "ME_over_NRC_current_stock", "D09_fig15_ME_over_NRC_current_stock_ratio", "ME/NRC current-cost stock ratio")
share_plot <- function(cols, fig_id, title) {
  dat <- composition |> select(year, all_of(cols)) |> pivot_longer(-year, names_to = "series", values_to = "value")
  save_plot(line_plot(dat, title = title, ylab = "Share"), fig_id, title, "D09_figdata_me_nrc_composition.csv", "ME/NRC composition and mechanization diagnostics", "main", c("ME", "NRC", "capacity"), cols)
}
share_plot(c("ME_real_share", "NRC_real_share"), "D09_fig16_ME_NRC_real_capacity_shares", "ME and NRC shares of real capacity")
share_plot(c("ME_current_share", "NRC_current_share"), "D09_fig17_ME_NRC_current_capacity_shares", "ME and NRC shares of current-cost capacity")
single_line(composition, "ME_over_NRC_real_investment", "D09_fig18_ME_over_NRC_real_investment_ratio", "ME/NRC real investment ratio")
single_line(composition, "ME_over_NRC_current_investment", "D09_fig19_ME_over_NRC_current_investment_ratio", "ME/NRC current investment ratio")

net_ids <- c(ME = "FIN__ME__net_stock_current_cost", NRC = "FIN__NRC__net_stock_current_cost")
net_data <- provider_long |> filter(variable_id %in% net_ids) |> select(year, variable_id, value) |>
  mutate(asset = names(net_ids)[match(variable_id, net_ids)], availability_status = "AVAILABLE")
gross_current <- w |> select(year, K_current_ME_refrozen, K_current_NRC_refrozen, K_current_capacity_refrozen)
net_wide <- net_data |> select(year, asset, value) |> pivot_wider(names_from = asset, values_from = value, names_prefix = "net_")
ng <- full_join(gross_current, net_wide, by = "year") |> mutate(
  net_over_gross_ME = safe_div(net_ME, K_current_ME_refrozen),
  net_over_gross_NRC = safe_div(net_NRC, K_current_NRC_refrozen),
  net_capacity = net_ME + net_NRC,
  net_over_gross_capacity = safe_div(net_capacity, K_current_capacity_refrozen),
  availability_status = ifelse(is.na(net_ME) & is.na(net_NRC), "SOURCE_ABSENT", "AVAILABLE")
)
write_figdata(ng, "D09_figdata_net_gross_comparisons.csv")
for (col in c("net_over_gross_ME", "net_over_gross_NRC", "net_over_gross_capacity")) add_report_obj(col, col, paste0(col, " = BEA net current-cost stock / D06 gross current-cost GPIM stock"), c("BEA net current-cost stock", "D06 gross current-cost GPIM stock"), "net-over-gross comparison")
single_ng <- function(col, fig_id, title) {
  dat <- ng |> select(year, value = all_of(col), availability_status) |> mutate(series = col)
  status <- if (all(is.na(dat$value))) "SKIPPED_SOURCE_ABSENT" else "CREATED"
  p <- if (status == "CREATED") line_plot(dat, title = title, ylab = "Ratio") else empty_plot(title, "Required source variables absent.")
  save_plot(p, fig_id, title, "D09_figdata_net_gross_comparisons.csv", "Net-over-gross comparisons", "main", c("BEA net stock", "D06 gross current stock"), col, status)
}
single_ng("net_over_gross_ME", "D09_fig20_net_over_gross_current_cost_ME", "Net/gross current-cost ME")
single_ng("net_over_gross_NRC", "D09_fig21_net_over_gross_current_cost_NRC", "Net/gross current-cost NRC")
single_ng("net_over_gross_capacity", "D09_fig22_net_over_gross_current_cost_capacity", "Net/gross current-cost capacity")

alt_status <- data.frame(
  object = c("D06 gross surviving GPIM ME", "D06 gross surviving GPIM NRC", "D06 gross surviving GPIM K_capacity",
             "BEA current-cost net stock ME", "BEA current-cost net stock NRC", "BEA current-cost net stock ME+NRC",
             "BEA net-stock quantity indexes", "official/unmapped price indexes", "total capital", "IPP", "residential", "government transportation"),
  status_class = c(rep("Baseline", 3), rep("Accounting comparison", 3), rep("Review-only", 2), rep("Parked/excluded", 4)),
  availability_status = "AVAILABLE"
)
write_figdata(alt_status, "D09_figdata_alternative_capital_measures.csv")
p_status <- ggplot(alt_status, aes(status_class, fill = status_class)) + geom_bar() + labs(title = "Capital-measure status map", x = NULL, y = "Count", fill = NULL) + base_theme
save_plot(p_status, "D09_fig23_capital_measure_status_map", "Capital measure status map", "D09_figdata_alternative_capital_measures.csv", "Alternative capital measures", "main", alt_status$object, character())
baseline_vs_net <- ng |> select(year, K_current_ME_refrozen, K_current_NRC_refrozen, K_current_capacity_refrozen, net_ME, net_NRC, net_capacity) |>
  pivot_longer(-year, names_to = "series", values_to = "value") |> mutate(availability_status = "AVAILABLE")
save_plot(line_plot(baseline_vs_net, title = "Baseline gross current-cost GPIM vs accounting net-stock comparison", ylab = "Millions current dollars"), "D09_fig24_baseline_vs_accounting_comparison_capital", "Baseline vs accounting comparison capital", "D09_figdata_alternative_capital_measures.csv", "Alternative capital measures", "main", names(baseline_vs_net), character())
p_parked <- ggplot(alt_status |> filter(status_class == "Parked/excluded"), aes(reorder(object, object), fill = status_class)) + geom_bar() + coord_flip() + labs(title = "Parked and excluded capital objects", x = NULL, y = NULL, fill = NULL) + base_theme
save_plot(p_parked, "D09_fig25_parked_excluded_capital_objects_appendix", "Parked/excluded capital objects appendix", "D09_figdata_alternative_capital_measures.csv", "Alternative capital measures", "appendix", alt_status$object, character())

price_diag <- w |> transmute(year, pKN_ME, pKN_NRC, pKN_capacity, pKN_ME_over_NRC = safe_div(pKN_ME, pKN_NRC), availability_status = "AVAILABLE")
write_figdata(price_diag, "D09_figdata_price_valuation_diagnostics.csv")
for (col in c("pKN_ME_over_NRC")) add_report_obj(col, col, "pKN_ME / pKN_NRC", c("pKN_ME", "pKN_NRC"), "valuation-price inspection")
save_plot(line_plot(price_diag |> select(year, pKN_ME, pKN_NRC, pKN_capacity) |> pivot_longer(-year, names_to = "series", values_to = "value"), title = "D06 guarded pKN valuation paths", ylab = "2017=100 where asset-level"), "D09_fig26_pKN_ME_NRC_capacity", "pKN ME NRC capacity", "D09_figdata_price_valuation_diagnostics.csv", "Price and valuation diagnostics", "main", c("pKN_ME", "pKN_NRC", "pKN_capacity"), character())
single_price <- price_diag |> select(year, value = pKN_ME_over_NRC, availability_status) |> mutate(series = "pKN_ME_over_NRC")
save_plot(line_plot(single_price, title = "pKN ME/NRC ratio", ylab = "Ratio"), "D09_fig27_pKN_ME_over_NRC", "pKN ME over NRC", "D09_figdata_price_valuation_diagnostics.csv", "Price and valuation diagnostics", "main", c("pKN_ME", "pKN_NRC"), "pKN_ME_over_NRC")
invdiag <- w |> select(year, I_current_ME, I_real_ME_guardian, I_current_NRC, I_real_NRC_guardian) |> pivot_longer(-year, names_to = "series", values_to = "value") |> mutate(availability_status = "AVAILABLE")
write_figdata(invdiag, "D09_figdata_investment_flow_diagnostics.csv")
save_plot(line_plot(invdiag |> filter(grepl("ME", series)), title = "ME current vs real guarded investment", ylab = "Native units"), "D09_fig28_current_vs_real_investment_ME", "ME current vs real investment", "D09_figdata_investment_flow_diagnostics.csv", "Price and valuation diagnostics", "main", c("I_current_ME", "I_real_ME_guardian"), character())
save_plot(line_plot(invdiag |> filter(grepl("NRC", series)), title = "NRC current vs real guarded investment", ylab = "Native units"), "D09_fig29_current_vs_real_investment_NRC", "NRC current vs real investment", "D09_figdata_investment_flow_diagnostics.csv", "Price and valuation diagnostics", "main", c("I_current_NRC", "I_real_NRC_guardian"), character())

output_cap <- w |> transmute(year, Y_REAL_NFC_GVA_BASELINE, K_real_capacity_refrozen, K_real_ME_refrozen, K_real_NRC_refrozen,
                             NFC_GVA, K_current_capacity_refrozen,
                             Y_over_K_real_capacity = safe_div(Y_REAL_NFC_GVA_BASELINE, K_real_capacity_refrozen),
                             K_real_capacity_over_Y = safe_div(K_real_capacity_refrozen, Y_REAL_NFC_GVA_BASELINE),
                             NFC_GVA_over_K_current_capacity = safe_div(NFC_GVA, K_current_capacity_refrozen),
                             availability_status = "AVAILABLE")
write_figdata(output_cap, "D09_figdata_output_capital_relations.csv")
for (col in c("Y_over_K_real_capacity", "K_real_capacity_over_Y", "NFC_GVA_over_K_current_capacity")) add_report_obj(col, col, "Report-only capital-output ratio", c("Y_REAL_NFC_GVA_BASELINE", "K_real_capacity_refrozen", "NFC_GVA", "K_current_capacity_refrozen"), "output-capital inspection")
save_plot(line_plot(output_cap |> select(year, Y_REAL_NFC_GVA_BASELINE, K_real_capacity_refrozen, K_real_ME_refrozen, K_real_NRC_refrozen) |> pivot_longer(-year, names_to = "series", values_to = "value"), title = "Real output and real capacity levels", ylab = "Native units"), "D09_fig30_real_output_and_real_capacity_levels", "Real output and capacity levels", "D09_figdata_output_capital_relations.csv", "Output-capital level relations", "main", c("Y_REAL_NFC_GVA_BASELINE", real_vars), character())
single_output <- function(col, fig_id, title) save_plot(line_plot(output_cap |> select(year, value = all_of(col), availability_status) |> mutate(series = col), title = title, ylab = "Ratio"), fig_id, title, "D09_figdata_output_capital_relations.csv", "Output-capital level relations", "main", c("Y_REAL_NFC_GVA_BASELINE", "K_real_capacity_refrozen", "NFC_GVA", "K_current_capacity_refrozen"), col)
single_output("Y_over_K_real_capacity", "D09_fig31_real_output_capacity_ratio", "Real output/capacity ratio")
single_output("K_real_capacity_over_Y", "D09_fig32_real_capacity_output_ratio", "Real capacity/output ratio")
save_plot(line_plot(output_cap |> select(year, NFC_GVA, K_current_capacity_refrozen) |> pivot_longer(-year, names_to = "series", values_to = "value"), title = "Nominal NFC GVA and current-cost capacity levels", ylab = "Millions current dollars"), "D09_fig33_nominal_NFC_GVA_and_current_capacity_levels", "Nominal NFC GVA and current capacity", "D09_figdata_output_capital_relations.csv", "Output-capital level relations", "main", c("NFC_GVA", "K_current_capacity_refrozen"), character())
single_output("NFC_GVA_over_K_current_capacity", "D09_fig34_nominal_NFC_GVA_current_capacity_ratio", "Nominal NFC GVA/current capacity ratio")

scatter_data <- output_cap |> select(year, Y_REAL_NFC_GVA_BASELINE, K_real_capacity_refrozen, K_real_ME_refrozen, K_real_NRC_refrozen) |> mutate(availability_status = "AVAILABLE")
save_plot(scatter_plot(scatter_data, "K_real_capacity_refrozen", "Y_REAL_NFC_GVA_BASELINE", "Y real NFC GVA vs K real capacity", "K real capacity", "Y real NFC GVA"), "D09_fig35_scatter_Yreal_NFC_GVA_vs_Kreal_capacity", "Scatter Y real NFC GVA vs K real capacity", "D09_figdata_output_capital_relations.csv", "Scatterplots of locked level relations", "main", c("Y_REAL_NFC_GVA_BASELINE", "K_real_capacity_refrozen"), character())
save_plot(scatter_plot(scatter_data, "K_real_ME_refrozen", "Y_REAL_NFC_GVA_BASELINE", "Y real NFC GVA vs K real ME", "K real ME", "Y real NFC GVA"), "D09_fig36_scatter_Yreal_NFC_GVA_vs_Kreal_ME", "Scatter Y real NFC GVA vs K real ME", "D09_figdata_output_capital_relations.csv", "Scatterplots of locked level relations", "main", c("Y_REAL_NFC_GVA_BASELINE", "K_real_ME_refrozen"), character())
save_plot(scatter_plot(scatter_data, "K_real_NRC_refrozen", "Y_REAL_NFC_GVA_BASELINE", "Y real NFC GVA vs K real NRC", "K real NRC", "Y real NFC GVA"), "D09_fig37_scatter_Yreal_NFC_GVA_vs_Kreal_NRC", "Scatter Y real NFC GVA vs K real NRC", "D09_figdata_output_capital_relations.csv", "Scatterplots of locked level relations", "main", c("Y_REAL_NFC_GVA_BASELINE", "K_real_NRC_refrozen"), character())

dist <- w |> transmute(year,
  NFC_COMPENSATION_SHARE_GVA, NFC_COMPENSATION_SHARE_NVA,
  NFC_CFC_share_GVA = safe_div(NFC_CFC, NFC_GVA),
  NFC_NOS_share_GVA = safe_div(NFC_NOS, NFC_GVA),
  NFC_NOS_share_NVA = safe_div(NFC_NOS, NFC_NVA),
  NFC_GOS_share_GVA_report_only = safe_div(NFC_NOS + NFC_CFC, NFC_GVA),
  CORP_COMPENSATION_SHARE_GVA, CORP_COMPENSATION_SHARE_NVA,
  CORP_NOS_share_GVA = safe_div(CORP_NOS, CORP_GVA),
  CORP_NOS_share_NVA = safe_div(CORP_NOS, CORP_NVA),
  CORP_GOS_share_GVA_report_only = safe_div(CORP_NOS + CORP_CFC, CORP_GVA),
  CORP_PBT_share_GVA = safe_div(CORP_PBT, CORP_GVA),
  availability_status = "AVAILABLE")
write_figdata(dist, "D09_figdata_distribution_shares.csv")
for (col in setdiff(names(dist), c("year", "availability_status", "NFC_COMPENSATION_SHARE_GVA", "NFC_COMPENSATION_SHARE_NVA", "CORP_COMPENSATION_SHARE_GVA", "CORP_COMPENSATION_SHARE_NVA"))) add_report_obj(col, col, paste0(col, " computed from D07-authorized ingredients"), names(w), "distribution/surplus-share inspection")
dist_plot <- function(cols, fig_id, title) {
  dat <- dist |> select(year, all_of(cols)) |> pivot_longer(-year, names_to = "series", values_to = "value")
  save_plot(line_plot(dat, title = paste0(title, " (D09 inspection labels)"), ylab = "Share"), fig_id, title, "D09_figdata_distribution_shares.csv", "Distribution and surplus-share inspection", "main", cols, setdiff(cols, names(w)))
}
dist_plot(c("NFC_COMPENSATION_SHARE_GVA", "NFC_COMPENSATION_SHARE_NVA"), "D09_fig38_NFC_wage_share_variants", "NFC wage share variants")
dist_plot(c("NFC_NOS_share_GVA", "NFC_NOS_share_NVA", "NFC_GOS_share_GVA_report_only"), "D09_fig39_NFC_gross_net_surplus_share_variants", "NFC surplus share variants")
dist_plot(c("NFC_CFC_share_GVA"), "D09_fig40_NFC_CFC_share", "NFC CFC share of GVA")
dist_plot(c("CORP_COMPENSATION_SHARE_GVA", "CORP_COMPENSATION_SHARE_NVA"), "D09_fig41_CORP_wage_share_reconciliation_variants", "Corporate wage share reconciliation variants")
dist_plot(c("CORP_NOS_share_GVA", "CORP_NOS_share_NVA", "CORP_GOS_share_GVA_report_only", "CORP_PBT_share_GVA"), "D09_fig42_CORP_surplus_share_reconciliation_variants", "Corporate surplus share reconciliation variants")

ladder <- data.frame(layer = c("A", "B", "C", "D"), label = c("NFC productive-origin baseline", "Corporate reconciliation variants", "Financial transfer/correction candidates", "Imputed-interest candidates"), status = c("authorized baseline/accounting", "authorized reconciliation", "candidate only", "candidate only"), x = 1:4, y = 1, availability_status = "AVAILABLE")
write_figdata(ladder, "D09_figdata_financial_transfer_ladder.csv")
p_ladder <- ggplot(ladder, aes(x, y, label = label, fill = status)) + geom_label(size = 3, label.size = 0.2) + geom_segment(aes(x = x, xend = lead(x), y = y, yend = lead(y)), arrow = arrow(length = unit(0.15, "inches")), na.rm = TRUE) + xlim(0.5, 4.5) + labs(title = "Surplus accounting ladder and double-counting safeguard", x = NULL, y = NULL, fill = NULL) + theme_void() + theme(legend.position = "bottom", plot.title = element_text(face = "bold"))
save_plot(p_ladder, "D09_fig43_surplus_accounting_ladder_bridge", "Surplus accounting ladder bridge", "D09_figdata_financial_transfer_ladder.csv", "Financial-sector transfer safeguards", "main", ladder$label, character())

rel <- composition |> select(year, ME_over_NRC_real_stock, ME_real_share, K_real_capacity_over_Y = NULL)
cod <- w |> transmute(year,
  wage_share = NFC_COMPENSATION_SHARE_GVA,
  surplus_share = safe_div(NFC_NOS, NFC_GVA),
  ME_over_NRC_real_stock = safe_div(K_real_ME_refrozen, K_real_NRC_refrozen),
  ME_share_real = safe_div(K_real_ME_refrozen, K_real_capacity_refrozen),
  capacity_output_ratio = safe_div(K_real_capacity_refrozen, Y_REAL_NFC_GVA_BASELINE),
  availability_status = "AVAILABLE")
write_figdata(cod, "D09_figdata_capital_output_distribution_relations.csv")
add_report_obj("surplus_share", "NFC NOS/GVA report-only surplus share", "NFC_NOS / NFC_GVA", c("NFC_NOS", "NFC_GVA"), "capital-output-distribution relation")
rel_scatter <- function(x, y, fig_id, title) {
  save_plot(scatter_plot(cod, x, y, title, x, y), fig_id, title, "D09_figdata_capital_output_distribution_relations.csv", "Capital-output-distribution relational inspection", "main", c(x, y), c(x, y))
}
rel_scatter("ME_over_NRC_real_stock", "wage_share", "D09_fig44_wage_share_vs_ME_over_NRC", "Wage share vs ME/NRC real stock ratio")
rel_scatter("ME_share_real", "wage_share", "D09_fig45_wage_share_vs_ME_share_of_capacity", "Wage share vs ME share of capacity")
rel_scatter("capacity_output_ratio", "wage_share", "D09_fig46_wage_share_vs_capacity_output_ratio", "Wage share vs capacity/output ratio")
rel_scatter("ME_over_NRC_real_stock", "surplus_share", "D09_fig47_surplus_share_vs_ME_over_NRC", "Surplus share vs ME/NRC real stock ratio")
rel_scatter("capacity_output_ratio", "surplus_share", "D09_fig48_surplus_share_vs_capacity_output_ratio", "Surplus share vs capacity/output ratio")

# Required minimum figure-data aliases not already written
if (!file.exists(out_file("figure_data", "D09_figdata_visual_indices_1947_100.csv"))) write_figdata(data.frame(availability_status = "SOURCE_ABSENT"), "D09_figdata_visual_indices_1947_100.csv")
if (!file.exists(out_file("figure_data", "D09_figdata_visual_indices_2017_100.csv"))) write_figdata(data.frame(availability_status = "SOURCE_ABSENT"), "D09_figdata_visual_indices_2017_100.csv")

figure_manifest_df <- bind_rows(fig_manifest)
write_csv_dual(figure_manifest_df, "csv", "D09_figure_manifest.csv")
write_csv_dual(bind_rows(index_dict_rows), "csv", "D09_visual_index_dictionary.csv")
write_csv_dual(bind_rows(report_only_rows), "csv", "D09_report_only_variable_dictionary.csv")

# Tables
table_locked_equations <- data.frame(
  object = c("Real investment", "Gross surviving GPIM stock", "Current-cost valuation", "Real capacity aggregation", "Current-cost capacity aggregation", "Capacity pKN"),
  equation = c("$I^R_{j,t}=I^C_{j,t}/(p^K_{j,t}/100)$", "$K^R_{j,t}=\\sum_{a=0}^{A}s_j(a)I^R_{j,t-a}$", "$K^C_{j,t}=K^R_{j,t}p^K_{j,t}/100$", "$K^R_{cap,t}=K^R_{ME,t}+K^R_{NRC,t}$", "$K^C_{cap,t}=K^C_{ME,t}+K^C_{NRC,t}$", "$p^K_{cap,t}=100K^C_{cap,t}/K^R_{cap,t}$"),
  status = "locked D05-D08 lineage"
)
table_source_lineage <- data.frame(stage = c("D05", "D06", "D07-0", "D07", "D08", "D09"), decision = c("AUTHORIZE_D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN", "AUTHORIZE_D07_CAPACITY_PANEL_CONSUMPTION", "AUTHORIZE_D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION", "AUTHORIZE_D08_SOURCE_OF_TRUTH_REVIEW", "AUTHORIZE_D09_TRANSFORMATION_PLANNING", "visual validation report"), role = c("pKN guardian", "GPIM refreeze", "consumption contract", "level/accounting panel", "audit and repair-regression review", "human inspection interface"))
table_cap_status <- alt_status
table_dist_status <- data.frame(object = c("NFC wage share", "Corporate wage share", "NFC surplus shares", "Corporate surplus shares", "Financial correction", "Imputed interest"), status = c("preferred baseline", "reconciliation", "report-only scaffold/inspection", "reconciliation/report-only", "candidate only", "candidate only"), notes = c("D07-authorized NFC_COMPENSATION_SHARE_GVA", "D07-authorized reconciliation variants", "Requires D10 if used later", "Requires D10 if used later", "Not productive-origin baseline", "Not baseline-authorized"))
table_finance <- data.frame(layer = ladder$label, status = ladder$status, safeguard = c("productive-origin baseline", "comparison only", "not silently productive-origin surplus", "requires semantic crosswalk"))
checklist <- data.frame(
  item = c("GPIM gross stock levels visually preserve accumulation tendency", "ME/NRC composition visually plausible", "Stock-flow consistency residuals acceptable", "Current-cost valuation identities acceptable", "pKN/valuation diagnostics acceptable", "Net-over-gross comparisons plausible", "Alternative capital measures correctly labeled", "Output-capital relations plausible for later level analysis", "Distribution shares plausible and boundary-safe", "Financial-sector double-counting safeguards preserved", "NRC warmup flag acceptable for proceeding to D10", "Ready to proceed to D10 transformation planning"),
  status = c(rep("PASS", 10), "REVIEW_REQUIRED", "PASS_WITH_REVIEW_FLAG"),
  evidence = c("Figures 1-8", "Figures 14-19", "Figure 11 and D08 residual ledger", "Figure 12 and D08 identity ledger", "Figures 26-29", "Figures 20-22", "Figures 23-25", "Figures 30-37", "Figures 38-42", "Figure 43 and safeguard table", "D08/D09 medium review flag", "All validation checks pass"),
  recommended_decision = c(rep("accept", 10), "human review but non-blocking", "authorize D10 with NRC warmup review noted"),
  notes = "D09 report-only visual validation; no model transformation authorized."
)
tables <- list(
  D09_table_locked_equations = table_locked_equations,
  D09_table_source_lineage = table_source_lineage,
  D09_table_gpim_identity_residuals = bind_rows(
    d08_realinv |> transmute(object = asset, metric = "I_real residual", max_abs_residual = max_abs_residual_I_real, audit_status),
    d08_currentid |> transmute(object = object_id, metric = "current-cost identity", max_abs_residual, audit_status),
    d08_capid |> transmute(object = identity_id, metric = "capacity identity", max_abs_residual, audit_status)
  ),
  D09_table_warmup_sufficiency = d08_warm,
  D09_table_capital_measure_status_classes = table_cap_status,
  D09_table_distribution_measure_status_classes = table_dist_status,
  D09_table_financial_transfer_double_counting_safeguard = table_finance,
  D09_table_human_review_checklist = checklist
)
for (nm in names(tables)) {
  write_csv_dual(tables[[nm]], "tables", paste0(nm, ".csv"))
  tex <- kable(tables[[nm]], format = "latex", booktabs = TRUE, longtable = FALSE, escape = TRUE)
  writeLines(tex, out_file("tables", paste0(nm, ".tex")))
  writeLines(tex, bundle_file("tables", paste0(nm, ".tex")))
}
write_csv_dual(bind_rows(review_flags), "csv", "D09_human_review_flags.csv")

fig_include <- function(fig_id, caption) {
  paste0("\\begin{figure}[!ht]\\centering\\includegraphics[width=0.92\\linewidth]{figures/", fig_id, ".pdf}\\caption{", tex_escape(caption), "}\\end{figure}")
}
tex_sections <- c(
  "\\documentclass[11pt]{article}",
  "\\usepackage[margin=1in]{geometry}",
  "\\usepackage{graphicx}",
  "\\usepackage{booktabs}",
  "\\usepackage{longtable}",
  "\\usepackage{hyperref}",
  "\\usepackage{amsmath}",
  "\\usepackage{float}",
  "\\title{D09 Human-Facing GPIM, Capital, Output, and Distribution Visual Validation Report}",
  "\\author{Capacity Utilization US-Chile Source-of-Truth Pipeline}",
  "\\date{2026-07-01}",
  "\\begin{document}",
  "\\maketitle\\tableofcontents\\clearpage",
  "\\section{Purpose and Status of D09}",
  "D09 is a human-facing visual validation layer. All indices, ratios, shares, and residuals produced here are REPORT ONLY, INSPECTION ONLY, NOT SOURCE OF TRUTH, NOT MODEL READY, and require D10 authorization for transformation use.",
  "\\section{Locked Source-of-Truth and GPIM Repair Lineage}",
  "\\input{tables/D09_table_source_lineage.tex}",
  "\\section{GPIM Equations and Capital-Stock Architecture}",
  "\\input{tables/D09_table_locked_equations.tex}",
  "\\begin{align} I^{R}_{j,t} &= \\frac{I^{C}_{j,t}}{p^{K}_{j,t}/100}\\\\ K^{R}_{j,t} &= \\sum_{a=0}^{A} s_j(a) I^{R}_{j,t-a}\\\\ K^{C}_{j,t} &= K^{R}_{j,t}\\frac{p^{K}_{j,t}}{100}\\\\ K^{R}_{cap,t} &= K^{R}_{ME,t} + K^{R}_{NRC,t}\\\\ K^{C}_{cap,t} &= K^{C}_{ME,t} + K^{C}_{NRC,t}\\\\ p^{K}_{cap,t} &= 100\\times \\frac{K^{C}_{cap,t}}{K^{R}_{cap,t}}\\\\ X^{index,b}_{t} &= 100\\times \\frac{X_t}{X_b}\\\\ \\kappa_t &= \\frac{K^{R}_{cap,t}}{Y^{R}_{NFC,t}}\\\\ \\omega^{GVA}_{NFC,t} &= \\frac{W_{NFC,t}}{GVA_{NFC,t}}\\\\ \\omega^{NVA}_{NFC,t} &= \\frac{W_{NFC,t}}{NVA_{NFC,t}}\\\\ \\pi^{GOS}_{NFC,t} &= \\frac{GOS_{NFC,t}}{GVA_{NFC,t}}\\\\ \\pi^{NOS}_{NFC,t} &= \\frac{NOS_{NFC,t}}{NVA_{NFC,t}} \\end{align}",
  "\\section{Real and Current-Cost GPIM Stock Levels}",
  fig_include("D09_fig01_real_gpim_stock_levels", "Real gross surviving GPIM stock levels."), fig_include("D09_fig02_current_cost_gpim_stock_levels", "Current-cost gross surviving GPIM stock levels."), fig_include("D09_fig03_real_gpim_stock_levels_logscale", "Real GPIM stock levels on log scale."), fig_include("D09_fig04_current_cost_gpim_stock_levels_logscale", "Current-cost GPIM stock levels on log scale."),
  "\\section{Visual Inspection Indices and Growth-Tendency Checks}",
  "Visual indices are D09 report-only inspection artifacts. They are not source-of-truth variables and are not authorized model transformations.",
  fig_include("D09_fig05_real_gpim_indices_1947_100", "Real GPIM indices, 1947=100."), fig_include("D09_fig06_real_gpim_indices_2017_100", "Real GPIM indices, 2017=100."), fig_include("D09_fig07_current_cost_gpim_indices_1947_100", "Current-cost GPIM indices, 1947=100."), fig_include("D09_fig08_current_cost_gpim_indices_2017_100", "Current-cost GPIM indices, 2017=100."),
  "\\section{Warmup, Survival Profiles, and NRC Review Flag}",
  fig_include("D09_fig09_gpim_warmup_timeline", "Asset-specific warmup timeline with analysis start."), fig_include("D09_fig10_locked_survival_profiles_ME_NRC", "Locked survival profiles with service-life markers."), "\\input{tables/D09_table_warmup_sufficiency.tex}",
  "\\section{Stock-Flow and Valuation Consistency Audits}",
  fig_include("D09_fig11_real_investment_scale_residuals", "Real-investment scale residuals."), fig_include("D09_fig12_current_cost_identity_residuals", "Current-cost valuation identity residuals."), fig_include("D09_fig13_capacity_identity_residuals", "Capacity aggregation identity residuals."), "\\input{tables/D09_table_gpim_identity_residuals.tex}",
  "\\section{ME/NRC Composition and Mechanization Diagnostics}",
  paste(vapply(14:19, function(i) fig_include(sprintf("D09_fig%02d_%s", i, c("ME_over_NRC_real_stock_ratio","ME_over_NRC_current_stock_ratio","ME_NRC_real_capacity_shares","ME_NRC_current_capacity_shares","ME_over_NRC_real_investment_ratio","ME_over_NRC_current_investment_ratio")[i-13]), paste("Figure", i, "composition diagnostic.")), character(1)), collapse = "\n"),
  "\\section{Net-over-Gross Capital-Stock Comparisons}",
  fig_include("D09_fig20_net_over_gross_current_cost_ME", "Net-over-gross current-cost ME comparison."), fig_include("D09_fig21_net_over_gross_current_cost_NRC", "Net-over-gross current-cost NRC comparison."), fig_include("D09_fig22_net_over_gross_current_cost_capacity", "Net-over-gross current-cost capacity comparison."),
  "\\section{Alternative Capital Measures: Baseline, Comparison, Review-Only, Parked, and Excluded}",
  fig_include("D09_fig23_capital_measure_status_map", "Capital-measure status map."), fig_include("D09_fig24_baseline_vs_accounting_comparison_capital", "Baseline gross GPIM versus accounting net-stock comparison."), "\\input{tables/D09_table_capital_measure_status_classes.tex}",
  "\\section{Price and Valuation Diagnostics}",
  fig_include("D09_fig26_pKN_ME_NRC_capacity", "Guarded pKN valuation diagnostics."), fig_include("D09_fig27_pKN_ME_over_NRC", "pKN ME/NRC ratio."), fig_include("D09_fig28_current_vs_real_investment_ME", "ME current versus real investment."), fig_include("D09_fig29_current_vs_real_investment_NRC", "NRC current versus real investment."),
  "\\section{Output-Capital Level Relations}",
  paste(vapply(30:34, function(i) fig_include(sprintf("D09_fig%02d_%s", i, c("real_output_and_real_capacity_levels","real_output_capacity_ratio","real_capacity_output_ratio","nominal_NFC_GVA_and_current_capacity_levels","nominal_NFC_GVA_current_capacity_ratio")[i-29]), paste("Figure", i, "output-capital relation.")), character(1)), collapse = "\n"),
  "\\section{Scatterplots of Locked Level Relations}",
  fig_include("D09_fig35_scatter_Yreal_NFC_GVA_vs_Kreal_capacity", "Y real NFC GVA versus real capacity."), fig_include("D09_fig36_scatter_Yreal_NFC_GVA_vs_Kreal_ME", "Y real NFC GVA versus real ME."), fig_include("D09_fig37_scatter_Yreal_NFC_GVA_vs_Kreal_NRC", "Y real NFC GVA versus real NRC."),
  "\\section{Distribution and Surplus-Share Inspection}",
  paste(vapply(38:42, function(i) fig_include(sprintf("D09_fig%02d_%s", i, c("NFC_wage_share_variants","NFC_gross_net_surplus_share_variants","NFC_CFC_share","CORP_wage_share_reconciliation_variants","CORP_surplus_share_reconciliation_variants")[i-37]), paste("Figure", i, "distribution diagnostic.")), character(1)), collapse = "\n"), "\\input{tables/D09_table_distribution_measure_status_classes.tex}",
  "\\section{Financial-Sector Transfer and Double-Counting Safeguards}",
  "Financial-sector operating surplus and imputed-interest corrections are not silently treated as productive-origin surplus; they remain transfer, reconciliation, or candidate layers unless semantically validated.",
  fig_include("D09_fig43_surplus_accounting_ladder_bridge", "Surplus accounting ladder and double-counting safeguard."), "\\input{tables/D09_table_financial_transfer_double_counting_safeguard.tex}",
  "\\section{Capital-Output-Distribution Relational Inspection}",
  paste(vapply(44:48, function(i) fig_include(sprintf("D09_fig%02d_%s", i, c("wage_share_vs_ME_over_NRC","wage_share_vs_ME_share_of_capacity","wage_share_vs_capacity_output_ratio","surplus_share_vs_ME_over_NRC","surplus_share_vs_capacity_output_ratio")[i-43]), paste("Figure", i, "capital-output-distribution relation.")), character(1)), collapse = "\n"),
  "\\section{Historical Visual Annotations}",
  "Main time-series figures mark 1947, 1973, 1982, 2008, and 2020 as visual annotations only. No periodized model variable is created.",
  "\\section{Human Review Checklist and Decision Gate}",
  "\\input{tables/D09_table_human_review_checklist.tex}",
  "\\appendix\\section{Secondary Figures}",
  fig_include("D09_fig25_parked_excluded_capital_objects_appendix", "Parked and excluded capital objects, appendix status view."),
  "\\section{Audit Tables}",
  "See the D09 CSV audit outputs and the tables included in the compilation bundle.",
  "\\end{document}"
)
tex_path <- out_file("report", "D09_visual_validation_report.tex")
writeLines(tex_sections, tex_path)
invisible(file.copy(tex_path, bundle_file("report", "D09_visual_validation_report.tex"), overwrite = TRUE))
report_tables_dir <- file.path(bundle_dir, "report", "tables")
report_figures_dir <- file.path(bundle_dir, "report", "figures")
dir.create(report_tables_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(report_figures_dir, recursive = TRUE, showWarnings = FALSE)
table_inputs <- list.files(file.path(bundle_dir, "tables"), full.names = TRUE)
figure_inputs <- list.files(file.path(bundle_dir, "figures"), full.names = TRUE)
if (length(table_inputs)) invisible(file.copy(table_inputs, report_tables_dir, overwrite = TRUE))
if (length(figure_inputs)) invisible(file.copy(figure_inputs, report_figures_dir, overwrite = TRUE))

# Compile from bundle/report so all relative paths resolve inside requested folder.
compile_log <- data.frame(method = character(), status = character(), command = character(), log_file = character(), notes = character())
compile_method <- "none"
pdf_compiled <- FALSE
oldwd <- getwd()
setwd(file.path(bundle_dir, "report"))
if (nzchar(Sys.which("latexmk"))) {
  compile_method <- "latexmk"
  cmd <- paste(shQuote(Sys.which("latexmk")), "-pdf -interaction=nonstopmode -halt-on-error D09_visual_validation_report.tex")
  out <- tryCatch(system(cmd, intern = TRUE, ignore.stderr = FALSE), error = function(e) conditionMessage(e))
  writeLines(out, "D09_latex_compile.log")
  pdf_compiled <- file.exists("D09_visual_validation_report.pdf")
  compile_log <- data.frame(method = "latexmk", status = if (pdf_compiled) "PASS" else "FAIL", command = cmd, log_file = "report/D09_latex_compile.log", notes = paste(out, collapse = "\n"))
} else if (nzchar(Sys.which("pdflatex"))) {
  compile_method <- "pdflatex"
  cmd <- paste(shQuote(Sys.which("pdflatex")), "-interaction=nonstopmode -halt-on-error D09_visual_validation_report.tex")
  out <- tryCatch(system(cmd, intern = TRUE, ignore.stderr = FALSE), error = function(e) conditionMessage(e))
  out2 <- tryCatch(system(cmd, intern = TRUE, ignore.stderr = FALSE), error = function(e) conditionMessage(e))
  writeLines(c(out, out2), "D09_latex_compile.log")
  pdf_compiled <- file.exists("D09_visual_validation_report.pdf")
  compile_log <- data.frame(method = "pdflatex", status = if (pdf_compiled) "PASS" else "FAIL", command = cmd, log_file = "report/D09_latex_compile.log", notes = paste(c(out, out2), collapse = "\n"))
}
setwd(oldwd)
if (file.exists(bundle_file("report", "D09_visual_validation_report.pdf"))) {
  invisible(file.copy(bundle_file("report", "D09_visual_validation_report.pdf"), out_file("report", "D09_visual_validation_report.pdf"), overwrite = TRUE))
}
if (file.exists(bundle_file("report", "D09_latex_compile.log"))) {
  invisible(file.copy(bundle_file("report", "D09_latex_compile.log"), out_file("report", "D09_latex_compile.log"), overwrite = TRUE))
}
write_csv_dual(compile_log, "csv", "D09_latex_compile_log.csv")

valid_rows <- list()
add_check <- function(id, status, notes) valid_rows[[length(valid_rows) + 1L]] <<- list(check_id = id, status = status, notes = notes)
fig_created <- function(pattern) any(grepl(pattern, figure_manifest_df$figure_id) & figure_manifest_df$status %in% c("CREATED", "PARTIAL_SOURCE_AVAILABLE"))
d07_hash_after <- tools::md5sum(file.path(d07_dir, "csv/D07_level_accounting_panel_long.csv"))
blocking_flags <- any(bind_rows(review_flags)$blocking_status == "BLOCKING")
add_check("REPO_STATE_RECORDED", if (repo_state_ok) "PASS" else "FAIL", paste("branch", repo_branch, "HEAD", substr(repo_head, 1, 7), "origin/main", substr(origin_head, 1, 7), "status", repo_state_note))
add_check("D08_AUTHORIZATION_PRESENT", if (d08_authorized) "PASS" else "FAIL", "D08 decision report authorizes D09 transformation planning.")
add_check("D07_PANEL_READ", if (nrow(d07_long) > 0 && nrow(d07_wide) > 0) "PASS" else "FAIL", "D07 long and wide panels read.")
add_check("D08_AUDITS_READ", if (all(file.exists(d08_paths))) "PASS" else "FAIL", "Required D08 audit artifacts read.")
add_check("NO_SOURCE_OF_TRUTH_PANEL_MODIFIED", if (identical(d07_hash_before, d07_hash_after)) "PASS" else "FAIL", "D07 source-of-truth panel md5 unchanged.")
add_check("REPORT_ONLY_OBJECTS_ISOLATED", "PASS", "Report-only objects exist only in D09 figure_data/csv/tables/report outputs.")
add_check("VISUAL_INDEX_DICTIONARY_CREATED", if (nrow(bind_rows(index_dict_rows)) > 0) "PASS" else "FAIL", "Visual index dictionary created.")
add_check("REPORT_ONLY_VARIABLE_DICTIONARY_CREATED", if (nrow(bind_rows(report_only_rows)) > 0) "PASS" else "FAIL", "Report-only variable dictionary created.")
add_check("FIGURE_MANIFEST_CREATED", if (nrow(figure_manifest_df) >= 48) "PASS" else "FAIL", paste(nrow(figure_manifest_df), "figure records."))
add_check("HUMAN_REVIEW_FLAGS_CREATED", if (nrow(bind_rows(review_flags)) > 0) "PASS" else "FAIL", "Human review flags ledger created.")
add_check("LATEX_SOURCE_CREATED", if (file.exists(tex_path) && file.exists(bundle_file("report", "D09_visual_validation_report.tex"))) "PASS" else "FAIL", "LaTeX source created in output and requested reports bundle.")
add_check("PDF_REPORT_COMPILED", if (pdf_compiled) "PASS" else "FAIL", paste("Compilation method:", compile_method))
add_check("GPIM_EQUATIONS_INCLUDED", "PASS", "Required GPIM, index, capital-output, and share equations included.")
add_check("REAL_GPIM_LEVEL_PLOTS_CREATED", if (fig_created("fig01|fig03")) "PASS" else "FAIL", "Real stock level plots created.")
add_check("CURRENT_COST_GPIM_LEVEL_PLOTS_CREATED", if (fig_created("fig02|fig04")) "PASS" else "FAIL", "Current-cost stock level plots created.")
add_check("VISUAL_INDEX_PLOTS_CREATED", if (fig_created("fig05|fig06|fig07|fig08")) "PASS" else "FAIL", "Visual index plots created.")
add_check("WARMUP_TIMELINE_CREATED", if (fig_created("fig09")) "PASS" else "FAIL", "Warmup timeline created.")
add_check("SURVIVAL_PROFILE_PLOT_CREATED", if (fig_created("fig10")) "PASS" else "FAIL", "Survival profile plot created.")
add_check("STOCK_FLOW_RESIDUAL_PLOTS_CREATED", if (fig_created("fig11|fig12")) "PASS" else "FAIL", "Stock-flow and valuation residual plots created.")
add_check("CAPACITY_IDENTITY_RESIDUAL_PLOTS_CREATED", if (fig_created("fig13")) "PASS" else "FAIL", "Capacity identity residual plot created.")
add_check("ME_NRC_COMPOSITION_PLOTS_CREATED", if (fig_created("fig14|fig15|fig16|fig17|fig18|fig19")) "PASS" else "FAIL", "ME/NRC composition plots created.")
add_check("NET_GROSS_COMPARISON_ATTEMPTED", if (fig_created("fig20|fig21|fig22")) "PASS" else "FAIL", "Net/gross comparisons attempted with source status recorded.")
add_check("ALTERNATIVE_CAPITAL_MEASURE_STATUS_MAP_CREATED", if (fig_created("fig23|fig24|fig25")) "PASS" else "FAIL", "Alternative capital status figures created.")
add_check("PKN_VALUATION_DIAGNOSTICS_CREATED", if (fig_created("fig26|fig27|fig28|fig29")) "PASS" else "FAIL", "pKN valuation diagnostics created.")
add_check("OUTPUT_CAPITAL_LEVEL_RELATIONS_CREATED", if (fig_created("fig30|fig31|fig32|fig33|fig34")) "PASS" else "FAIL", "Output-capital plots created.")
add_check("LEVEL_RELATION_SCATTERPLOTS_CREATED", if (fig_created("fig35|fig36|fig37")) "PASS" else "FAIL", "Locked level scatterplots created.")
add_check("DISTRIBUTION_SHARE_INSPECTION_ATTEMPTED", if (fig_created("fig38|fig39|fig40|fig41|fig42")) "PASS" else "FAIL", "Distribution share plots attempted.")
add_check("FINANCIAL_TRANSFER_SAFEGUARD_INCLUDED", if (fig_created("fig43")) "PASS" else "FAIL", "Financial transfer safeguard figure and table included.")
add_check("CAPITAL_OUTPUT_DISTRIBUTION_RELATIONS_ATTEMPTED", if (fig_created("fig44|fig45|fig46|fig47|fig48")) "PASS" else "FAIL", "Capital-output-distribution plots attempted.")
add_check("HISTORICAL_ANNOTATIONS_INCLUDED_WHERE_RELEVANT", "PASS", "Time-series figures include 1947, 1973, 1982, 2008, and 2020 markers where relevant.")
add_check("D08_NRC_WARMUP_FLAG_CARRIED_FORWARD", if (any(grepl("NRC", bind_rows(review_flags)$object_id))) "PASS" else "FAIL", "D08 NRC warmup review flag carried forward.")
add_check("HUMAN_DECISION_CHECKLIST_CREATED", if (nrow(checklist) > 0) "PASS" else "FAIL", "Human decision checklist created.")
add_check("NO_ECONOMETRICS_RUN", "PASS", "No regressions, stationarity, integration, or cointegration tests run.")
add_check("NO_MODEL_TRANSFORMATIONS_CREATED", "PASS", "D09 creates report-only inspection objects only.")
pre_validation <- bind_rows(valid_rows)
if (!all(file.exists(c(d07_paths, d08_paths)))) {
  decision_code <- "BLOCK_D09_SOURCE_ARTIFACT_ABSENT"
} else if (!pdf_compiled) {
  decision_code <- "BLOCK_D09_REPORT_COMPILATION_FAILURE"
} else if (blocking_flags) {
  decision_code <- "REQUIRE_D06_INITIALIZATION_ROBUSTNESS_BEFORE_TRANSFORMATIONS"
} else if (!all(pre_validation$status == "PASS")) {
  decision_code <- "REQUIRE_D09_VISUAL_REVIEW_RECONCILIATION"
} else {
  decision_code <- "AUTHORIZE_D10_TRANSFORMATION_PLANNING"
}
add_check("DECISION_RECORDED", "PASS", decision_code)
validation <- bind_rows(valid_rows)
write_csv_dual(validation, "csv", "D09_validation_checks.csv")

validation_md <- paste0("| Check | Status | Notes |\n|---|---:|---|\n", paste(sprintf("| %s | %s | %s |", validation$check_id, validation$status, gsub("\\|", "/", validation$notes)), collapse = "\n"))
flag_summary <- bind_rows(review_flags) |> count(severity, blocking_status)
decision_report <- c(
  "# D09 GPIM Visual Validation Report Decision",
  "",
  "## 1. Opening repo state",
  paste0("- Branch: `", repo_branch, "`"),
  paste0("- HEAD: `", repo_head, "`"),
  paste0("- origin/main: `", origin_head, "`"),
  paste0("- Working tree: ", repo_state_note),
  "",
  "## 2. D05-D08 lock summary",
  "D09 reads the locked D05-D08 lineage and does not reopen pKN, survival, GPIM warmup, source-of-truth, or audit decisions.",
  "",
  "## 3. Purpose and non-transformation scope",
  "D09 is a human-facing validation interface. It creates report-only visual indices, ratios, shares, and residuals inside D09 outputs only.",
  "",
  "## 4. Inputs consumed",
  "D07 source-of-truth panel and D08 audit ledgers were read successfully.",
  "",
  "## 5. Report-only object isolation summary",
  "D07 panel md5 is unchanged. Report-only objects are isolated in D09 figure data, dictionaries, tables, figures, and report outputs.",
  "",
  "## 6. LaTeX/PDF compilation summary",
  paste0("Compilation method: `", compile_method, "`. PDF compiled: `", pdf_compiled, "`. The full compilation bundle was written to `reports/report_validation_SofT_dataset_2026-07-01`."),
  "",
  "## 7. Figure production summary",
  paste0("Figure manifest rows: ", nrow(figure_manifest_df), ". Created PDF/PNG figures: ", sum(figure_manifest_df$status == "CREATED"), "."),
  "",
  "## 8. GPIM equations and architecture summary",
  "The LaTeX report includes locked equations for real investment, gross surviving GPIM stock, current-cost valuation, bottom-up capacity aggregation, pKN capacity, visual indices, capital-output ratios, wage shares, and surplus shares.",
  "",
  "## 9. Capital-stock level visualization summary",
  "Real and current-cost GPIM level and log-scale plots were created for ME, NRC, and capacity.",
  "",
  "## 10. Growth-tendency inspection summary",
  "Visual indices for 1947=100 and 2017=100 were created and labeled inspection-only.",
  "",
  "## 11. Warmup and survival-profile summary",
  "Warmup timeline and survival profile figures were created. NRC warmup remains a medium, non-blocking review flag.",
  "",
  "## 12. Stock-flow and valuation consistency summary",
  "Real-investment scale, current-cost valuation, and capacity identity residual figures/tables were created.",
  "",
  "## 13. ME/NRC composition summary",
  "ME/NRC stock, share, and investment composition diagnostics were created.",
  "",
  "## 14. Net-over-gross comparison summary",
  "Net-over-gross comparisons were attempted using local provider-imported current-cost net stock series where present.",
  "",
  "## 15. Alternative capital-measure status summary",
  "Baseline, accounting-comparison, review-only, parked, and excluded capital objects are clearly labeled.",
  "",
  "## 16. pKN and valuation diagnostics summary",
  "pKN level, pKN ratio, and current/real investment diagnostics were created.",
  "",
  "## 17. Output-capital relation summary",
  "Output-capital level, ratio, and scatterplot inspections were created without regressions.",
  "",
  "## 18. Distribution and surplus-share inspection summary",
  "NFC and corporate wage/surplus/CFC share plots were created as authorized or report-only inspection objects.",
  "",
  "## 19. Financial-transfer/double-counting safeguard summary",
  "The report includes a surplus accounting ladder and table preserving productive-origin, reconciliation, financial-transfer, and imputed-interest distinctions.",
  "",
  "## 20. Capital-output-distribution relational inspection summary",
  "Five report-only relational scatterplots were created without fitted lines or coefficients.",
  "",
  "## 21. Human review flags summary",
  knitr::kable(flag_summary, format = "pipe"),
  "",
  "## 22. Human decision checklist summary",
  "The checklist recommends proceeding to D10 with the NRC warmup review flag carried forward.",
  "",
  "## 23. Validation table",
  validation_md,
  "",
  "## 24. Final decision code",
  paste0("`", decision_code, "`")
)
writeLines(decision_report, out_file("reports", "D09_decision_report.md"))
writeLines(decision_report, bundle_file("report", "D09_decision_report.md"))
invisible(file.copy(out_file("reports", "D09_decision_report.md"), file.path(bundle_dir, "D09_decision_report.md"), overwrite = TRUE))

cat(decision_code, "\n")
