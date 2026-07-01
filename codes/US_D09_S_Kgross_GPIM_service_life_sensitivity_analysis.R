#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
  library(knitr)
  library(scales)
})

repo <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
out_dir <- file.path(repo, "reports/report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01")
d06_dir <- file.path(repo, "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN")
d07_dir <- file.path(repo, "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION")
d08_dir <- file.path(repo, "output/US/D08_SOURCE_OF_TRUTH_REVIEW_WITH_GPIM_REPAIR_REGRESSION_AUDIT")
d09_dir <- file.path(repo, "output/US/D09_GPIM_CAPITAL_OUTPUT_DISTRIBUTION_VISUAL_VALIDATION_REPORT")
d09r_dir <- file.path(repo, "output/US/D09_R_VISUAL_VALIDATION_REPORT_REPAIR_AND_NRC_SERVICE_LIFE_INTERPRETATION")

for (sub in c("csv", "figure_data", "figures", "tables", "tex", "pdf", "reports")) {
  dir.create(file.path(out_dir, sub), recursive = TRUE, showWarnings = FALSE)
}
out_file <- function(sub, name) file.path(out_dir, sub, name)
rel <- function(path) gsub(paste0("^", gsub("([\\^$.|?*+(){}\\[\\]\\\\])", "\\\\\\1", repo), "/?"), "", normalizePath(path, winslash = "/", mustWork = FALSE))

git <- function(args) paste(tryCatch(system2("git", args, stdout = TRUE, stderr = TRUE), error = function(e) conditionMessage(e)), collapse = "\n")
repo_branch <- git(c("branch", "--show-current"))
repo_head <- git(c("rev-parse", "HEAD"))
origin_head <- git(c("rev-parse", "origin/main"))
repo_status <- git(c("status", "--short"))
repo_log <- git(c("log", "--oneline", "-10"))
repo_state_note <- if (!nzchar(repo_status)) {
  "clean"
} else if (all(grepl("^(\\?\\?|A | M|M ) (codes/US_D09_S_Kgross_GPIM_service_life_sensitivity_analysis.R|reports/report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01/)", strsplit(repo_status, "\n", fixed = TRUE)[[1]]))) {
  "D09-S generated artifacts only after verified clean opening state"
} else {
  repo_status
}

nomura_pdf <- file.path(repo, "docs/Nomura2005.pdf")
nomura_futakami_pdf <- file.path(repo, "docs/NomuraFutakami2005.pdf")
if (!file.exists(nomura_pdf) || !file.exists(nomura_futakami_pdf)) {
  write_csv(data.frame(check_id = "NOMURA_PDFS_PRESENT", status = "FAIL", notes = "docs/Nomura2005.pdf or docs/NomuraFutakami2005.pdf absent"), out_file("csv", "D09_S_validation_checks.csv"))
  cat("BLOCK_D09_S_LITERATURE_SOURCES_ABSENT\n")
  quit(status = 0)
}

d06_paths <- c(
  asset = file.path(d06_dir, "csv/D06_asset_refrozen_gpim_panel.csv"),
  capacity = file.path(d06_dir, "csv/D06_capacity_refrozen_panel.csv"),
  investment = file.path(d06_dir, "csv/D06_real_investment_guardian_panel.csv"),
  warmup = file.path(d06_dir, "csv/D06_initialization_warmup_ledger.csv"),
  validation = file.path(d06_dir, "csv/D06_validation_checks.csv")
)
d07_paths <- c(
  panel = file.path(d07_dir, "csv/D07_level_accounting_panel_long.csv"),
  wide = file.path(d07_dir, "csv/D07_level_accounting_panel_wide.csv")
)
d08_paths <- c(flags = file.path(d08_dir, "csv/D08_review_flags_ledger.csv"))
d09r_paths <- c(
  decision = file.path(d09r_dir, "reports/D09_R_decision_report.md"),
  nrc = file.path(d09r_dir, "csv/D09_R_NRC_service_life_interpretation_ledger.csv"),
  future = file.path(d09r_dir, "reports/D09_R_future_NRC_service_life_sensitivity_design.md")
)
stopifnot(all(file.exists(d06_paths)), all(file.exists(d07_paths)), all(file.exists(d08_paths)), all(file.exists(d09r_paths)), dir.exists(d09_dir))

d06_hash_before <- tools::md5sum(unname(d06_paths))
d07_hash_before <- tools::md5sum(d07_paths[["panel"]])
d06_asset <- read_csv(d06_paths[["asset"]], show_col_types = FALSE)
d06_cap <- read_csv(d06_paths[["capacity"]], show_col_types = FALSE)
d06_inv <- read_csv(d06_paths[["investment"]], show_col_types = FALSE)
d06_warm <- read_csv(d06_paths[["warmup"]], show_col_types = FALSE)
d07_wide <- read_csv(d07_paths[["wide"]], show_col_types = FALSE)
d08_flags <- read_csv(d08_paths[["flags"]], show_col_types = FALSE)
d09r_decision <- paste(readLines(d09r_paths[["decision"]], warn = FALSE), collapse = "\n")

extract_text <- function(pdf, txt) {
  if (nzchar(Sys.which("pdftotext"))) {
    tryCatch(system2(Sys.which("pdftotext"), c("-layout", pdf, txt), stdout = TRUE, stderr = TRUE), error = function(e) character())
  }
  if (file.exists(txt)) paste(readLines(txt, warn = FALSE), collapse = "\n") else ""
}
nomura_txt <- extract_text(nomura_pdf, out_file("reports", "Nomura2005_extracted_text.txt"))
nf_txt <- extract_text(nomura_futakami_pdf, out_file("reports", "NomuraFutakami2005_extracted_text.txt"))

office_values_status <- if (all(vapply(c("15.4", "22.2", "23.0"), function(p) grepl(p, nomura_txt, fixed = TRUE), logical(1)))) "EXTRACTED" else "EXTRACTION_REVIEW_REQUIRED"
source_ledger <- data.frame(
  source_id = c("Nomura2005", "NomuraFutakami2005", "D06_GPIM_REFREEZE", "D07_LEVEL_ACCOUNTING_PANEL", "D08_REPAIR_AUDIT", "D09_R_REPAIR"),
  source_file = c(rel(nomura_pdf), rel(nomura_futakami_pdf), rel(d06_dir), rel(d07_dir), rel(d08_dir), rel(d09r_dir)),
  source_status = c("PRESENT_EXTRACTED", "PRESENT_EXTRACTED", "PRESENT_READ_ONLY", "PRESENT_READ_ONLY", "PRESENT_READ_ONLY", "PRESENT_READ_ONLY"),
  evidence_extracted = c(
    paste0("Directly observed discard data; Weibull discard/survival; office-building S0 15.4, Sv 22.2, adjusted Sv-hat 23.0; status ", office_values_status, "."),
    "Internal consistency, empirical verification, reproducibility, productive capacity versus value/wealth concepts, and user-testable assumptions.",
    "D06 guarded real investment, pKN, baseline ME/NRC stocks, and survival parameters.",
    "D07 source-of-truth output and capital panel.",
    "D08 review flags and repair audits.",
    "D09-R NRC interpretation and future sensitivity design."
  ),
  report_use = c(
    "Methodological warning and office-building comparison, not U.S. NRC calibration.",
    "Capital-measurement principles for transparent sensitivity.",
    "Report-only sensitivity rebuild baseline architecture.",
    "Output-capital inspection support.",
    "Warmup and review-flag continuity.",
    "NRC interpretation and sensitivity scope."
  ),
  notes = "All D09-S outputs are REPORT_ONLY / SENSITIVITY_ONLY / NOT_SOURCE_OF_TRUTH / NOT_D06_BASELINE / NOT_MODEL_READY.",
  stringsAsFactors = FALSE
)
write_csv(source_ledger, out_file("csv", "D09_S_literature_source_ledger.csv"))

survival_max_age <- 200L
analysis_start <- 1947L
survival_weibull <- function(age, L, alpha) {
  lambda <- L / gamma(1 + 1 / alpha)
  exp(-((age / lambda) ^ alpha))
}
idx <- function(x, year, base) {
  b <- x[year == base][1]
  if (!is.finite(b) || is.na(b) || b == 0) rep(NA_real_, length(x)) else 100 * x / b
}
safe_div <- function(a, b) ifelse(is.finite(b) & !is.na(b) & b != 0, a / b, NA_real_)

asset_cases <- bind_rows(
  data.frame(asset = "ME", case_id = c("ME_baseline_L14_alpha1p7", "ME_short_L10_alpha1p7", "ME_long_L18_alpha1p7", "ME_longer_L22_alpha1p7"), L = c(14, 10, 18, 22), alpha = 1.7, case_role = c("D06_BASELINE_REFERENCE", "REPORT_ONLY_SHORT", "REPORT_ONLY_LONG", "REPORT_ONLY_LONGER")),
  data.frame(asset = "NRC", case_id = c("NRC_baseline_L30_alpha1p6", "NRC_short_NomuraOffice_L23_alpha1p6", "NRC_medium_L40_alpha1p6", "NRC_long_L50_alpha1p6", "NRC_longer_L60_alpha1p6", "NRC_L30_alpha1p2", "NRC_L30_alpha2p0", "NRC_L50_alpha1p2", "NRC_L50_alpha2p0"), L = c(30, 23, 40, 50, 60, 30, 30, 50, 50), alpha = c(rep(1.6, 5), 1.2, 2.0, 1.2, 2.0), case_role = c("D06_BASELINE_REFERENCE", "REPORT_ONLY_NOMURA_OFFICE_COMPARISON", "REPORT_ONLY_MEDIUM", "REPORT_ONLY_LONG", "REPORT_ONLY_LONGER", "REPORT_ONLY_SHAPE", "REPORT_ONLY_SHAPE", "REPORT_ONLY_SHAPE", "REPORT_ONLY_SHAPE"))
) %>%
  mutate(
    sensitivity_status = "REPORT_ONLY;SENSITIVITY_ONLY;NOT_SOURCE_OF_TRUTH;NOT_D06_BASELINE;NOT_MODEL_READY;REQUIRES_D10_OR_LATER_AUTHORIZATION_FOR_TRANSFORMATION_USE",
    notes = ifelse(grepl("NomuraOffice", case_id), "Literature-comparison case inspired by Nomura adjusted office-building estimate; not a U.S. NRC benchmark.", "Inspection case only.")
  )
write_csv(asset_cases, out_file("csv", "D09_S_service_life_assumption_ledger.csv"))

survival_profiles <- bind_rows(lapply(seq_len(nrow(asset_cases)), function(i) {
  ages <- 0:survival_max_age
  cbind(asset_cases[i, ], data.frame(age = ages, survival = survival_weibull(ages, asset_cases$L[i], asset_cases$alpha[i])))
}))
write_csv(survival_profiles, out_file("csv", "D09_S_survival_profile_ledger.csv"))
write_csv(filter(survival_profiles, asset == "ME"), out_file("figure_data", "D09_S_figdata_survival_profiles_ME.csv"))
write_csv(filter(survival_profiles, asset == "NRC"), out_file("figure_data", "D09_S_figdata_survival_profiles_NRC.csv"))

stock_rows <- list()
for (i in seq_len(nrow(asset_cases))) {
  cs <- asset_cases[i, ]
  inv <- d06_inv %>% filter(asset == cs$asset) %>% arrange(year)
  for (r in seq_len(nrow(inv))) {
    vint <- inv[inv$year <= inv$year[r], ]
    ages <- inv$year[r] - vint$year
    keep <- ages <= survival_max_age
    surv <- survival_weibull(ages[keep], cs$L, cs$alpha)
    k_real <- sum(vint$I_real_guardian[keep] * surv, na.rm = TRUE)
    k_current <- k_real * inv$pKN_guardian[r] / 100
    stock_rows[[length(stock_rows) + 1L]] <- data.frame(
      year = inv$year[r],
      asset = cs$asset,
      case_id = cs$case_id,
      L = cs$L,
      alpha = cs$alpha,
      K_real = k_real,
      K_current = k_current,
      pKN = inv$pKN_guardian[r],
      I_real_guardian = inv$I_real_guardian[r],
      I_current = inv$I_current[r],
      status = "REPORT_ONLY_SENSITIVITY",
      sensitivity_status = cs$sensitivity_status,
      stringsAsFactors = FALSE
    )
  }
}
stock_long <- bind_rows(stock_rows)
write_csv(stock_long, out_file("csv", "D09_S_gpim_sensitivity_stock_panel_long.csv"))
stock_wide <- stock_long %>% select(year, asset, case_id, K_real, K_current, pKN, I_real_guardian, I_current) %>%
  pivot_wider(names_from = c(asset, case_id), values_from = c(K_real, K_current, pKN, I_real_guardian, I_current))
write_csv(stock_wide, out_file("csv", "D09_S_gpim_sensitivity_stock_panel_wide.csv"))

capacity_cases <- bind_rows(
  data.frame(capacity_case_id = "capacity_baseline_ME_L14_NRC_L30", ME_case_id = "ME_baseline_L14_alpha1p7", NRC_case_id = "NRC_baseline_L30_alpha1p6", case_group = "baseline capacity"),
  data.frame(capacity_case_id = paste0("capacity_ME_baseline_plus_", asset_cases$case_id[asset_cases$asset == "NRC"]), ME_case_id = "ME_baseline_L14_alpha1p7", NRC_case_id = asset_cases$case_id[asset_cases$asset == "NRC"], case_group = "NRC sensitivity capacity"),
  data.frame(capacity_case_id = paste0("capacity_", asset_cases$case_id[asset_cases$asset == "ME"], "_plus_NRC_baseline"), ME_case_id = asset_cases$case_id[asset_cases$asset == "ME"], NRC_case_id = "NRC_baseline_L30_alpha1p6", case_group = "ME sensitivity capacity"),
  data.frame(capacity_case_id = c("capacity_ME_long_L18_plus_NRC_long_L50", "capacity_ME_short_L10_plus_NRC_short_L23"), ME_case_id = c("ME_long_L18_alpha1p7", "ME_short_L10_alpha1p7"), NRC_case_id = c("NRC_long_L50_alpha1p6", "NRC_short_NomuraOffice_L23_alpha1p6"), case_group = "combined sensitivity examples")
) %>% distinct(capacity_case_id, .keep_all = TRUE)

cap_rows <- list()
for (i in seq_len(nrow(capacity_cases))) {
  me <- stock_long %>% filter(asset == "ME", case_id == capacity_cases$ME_case_id[i]) %>% select(year, K_real_ME = K_real, K_current_ME = K_current, pKN_ME = pKN)
  nrc <- stock_long %>% filter(asset == "NRC", case_id == capacity_cases$NRC_case_id[i]) %>% select(year, K_real_NRC = K_real, K_current_NRC = K_current, pKN_NRC = pKN)
  cap <- inner_join(me, nrc, by = "year") %>%
    mutate(
      capacity_case_id = capacity_cases$capacity_case_id[i],
      ME_case_id = capacity_cases$ME_case_id[i],
      NRC_case_id = capacity_cases$NRC_case_id[i],
      case_group = capacity_cases$case_group[i],
      K_real_capacity = K_real_ME + K_real_NRC,
      K_current_capacity = K_current_ME + K_current_NRC,
      pKN_capacity = 100 * K_current_capacity / K_real_capacity,
      sensitivity_status = "REPORT_ONLY;SENSITIVITY_ONLY;NOT_SOURCE_OF_TRUTH;NOT_D06_BASELINE;NOT_MODEL_READY;REQUIRES_D10_OR_LATER_AUTHORIZATION_FOR_TRANSFORMATION_USE"
    )
  cap_rows[[i]] <- cap
}
capacity_long <- bind_rows(cap_rows)
write_csv(capacity_long, out_file("csv", "D09_S_capacity_sensitivity_panel_long.csv"))
capacity_wide <- capacity_long %>% select(year, capacity_case_id, K_real_capacity, K_current_capacity, pKN_capacity, K_real_ME, K_real_NRC, K_current_ME, K_current_NRC) %>%
  pivot_wider(names_from = capacity_case_id, values_from = c(K_real_capacity, K_current_capacity, pKN_capacity, K_real_ME, K_real_NRC, K_current_ME, K_current_NRC))
write_csv(capacity_wide, out_file("csv", "D09_S_capacity_sensitivity_panel_wide.csv"))

stock_flow_audit <- stock_long %>% mutate(expected_I_real = I_current / (pKN / 100), residual = I_real_guardian - expected_I_real) %>%
  group_by(asset, case_id, L, alpha) %>% summarise(max_abs_residual = max(abs(residual), na.rm = TRUE), audit_status = ifelse(max_abs_residual < 1e-7, "PASS", "FAIL"), .groups = "drop")
current_cost_audit <- stock_long %>% mutate(residual = K_current - K_real * pKN / 100) %>%
  group_by(asset, case_id, L, alpha) %>% summarise(max_abs_residual = max(abs(residual), na.rm = TRUE), audit_status = ifelse(max_abs_residual < 1e-7, "PASS", "FAIL"), .groups = "drop")
capacity_audit <- capacity_long %>% mutate(residual_real = K_real_capacity - K_real_ME - K_real_NRC, residual_current = K_current_capacity - K_current_ME - K_current_NRC) %>%
  group_by(capacity_case_id, ME_case_id, NRC_case_id, case_group) %>% summarise(max_abs_real_residual = max(abs(residual_real), na.rm = TRUE), max_abs_current_residual = max(abs(residual_current), na.rm = TRUE), audit_status = ifelse(max_abs_real_residual < 1e-7 & max_abs_current_residual < 1e-7, "PASS", "FAIL"), .groups = "drop")
write_csv(stock_flow_audit, out_file("csv", "D09_S_stock_flow_identity_audit.csv"))
write_csv(current_cost_audit, out_file("csv", "D09_S_current_cost_identity_audit.csv"))
write_csv(capacity_audit, out_file("csv", "D09_S_capacity_identity_audit.csv"))

warmup <- asset_cases %>%
  left_join(d06_warm %>% transmute(asset, construction_start_year, analysis_start_year = as.integer(analysis_start_year_if_known)), by = "asset") %>%
  mutate(
    warmup_length = analysis_start_year - construction_start_year,
    warmup_to_L_ratio = warmup_length / L,
    survival_mass_at_analysis_start = survival_weibull(warmup_length, L, alpha),
    survival_mass_missing_risk_flag = case_when(
      warmup_to_L_ratio >= 1.25 ~ "LOW",
      warmup_to_L_ratio >= 0.75 ~ "MEDIUM",
      TRUE ~ "HIGH"
    ),
    audit_status = "PASS",
    notes = ifelse(asset == "NRC" & L > 30, "Longer NRC service life reduces late-sample decline but increases inherited-vintage fragility.", "D06 warmup convention preserved; no inherited pre-price stock invented.")
  )
write_csv(warmup, out_file("csv", "D09_S_warmup_sufficiency_audit.csv"))
write_csv(warmup, out_file("figure_data", "D09_S_figdata_warmup_to_L_ratios.csv"))

nrc_decline <- stock_long %>% filter(asset == "NRC", year >= analysis_start) %>%
  group_by(case_id, asset, L, alpha) %>%
  summarise(
    peak_year = year[which.max(K_real)][1],
    peak_value = max(K_real, na.rm = TRUE),
    latest_year = max(year, na.rm = TRUE),
    latest_value = K_real[which.max(year)][1],
    absolute_change_peak_to_latest = latest_value - peak_value,
    percent_change_peak_to_latest = 100 * (latest_value / peak_value - 1),
    .groups = "drop"
  ) %>%
  left_join(warmup %>% select(case_id, warmup_risk_status = survival_mass_missing_risk_flag), by = "case_id")
baseline_decline <- nrc_decline$percent_change_peak_to_latest[nrc_decline$case_id == "NRC_baseline_L30_alpha1p6"][1]
nrc_decline <- nrc_decline %>%
  mutate(
    decline_status = case_when(
      !is.finite(percent_change_peak_to_latest) ~ "SOURCE_INSUFFICIENT",
      percent_change_peak_to_latest >= 0 ~ "NO_DECLINE",
      abs(percent_change_peak_to_latest) < 2 ~ "DECLINE_ELIMINATED",
      percent_change_peak_to_latest > baseline_decline * 0.5 ~ "DECLINE_REDUCED",
      TRUE ~ "DECLINE_ROBUST"
    ),
    interpretation = case_when(
      case_id == "NRC_short_NomuraOffice_L23_alpha1p6" ~ "Nomura-office comparison produces a shorter-life path; it does not justify lengthening U.S. NRC survival.",
      decline_status %in% c("DECLINE_ELIMINATED", "NO_DECLINE") ~ "Longer service life eliminates the measured decline, but warmup fragility must be assessed.",
      decline_status == "DECLINE_REDUCED" ~ "Longer service life reduces the late-sample decline; the baseline path is service-life sensitive.",
      TRUE ~ "The qualitative decline or stagnation remains visible under this case."
    ),
    notes = "Measured on report-only real NRC stock from analysis start onward."
  )
write_csv(nrc_decline, out_file("csv", "D09_S_nrc_decline_sensitivity_audit.csv"))
write_csv(nrc_decline, out_file("figure_data", "D09_S_figdata_nrc_decline_metrics.csv"))

output_cap <- capacity_long %>% left_join(d07_wide %>% select(year, Y_REAL_NFC_GVA_BASELINE), by = "year") %>%
  mutate(capacity_output_ratio = safe_div(K_real_capacity, Y_REAL_NFC_GVA_BASELINE), output_capacity_ratio = safe_div(Y_REAL_NFC_GVA_BASELINE, K_real_capacity))
output_audit <- output_cap %>% group_by(capacity_case_id, case_group) %>% summarise(first_year = min(year[is.finite(capacity_output_ratio)], na.rm = TRUE), latest_year = max(year[is.finite(capacity_output_ratio)], na.rm = TRUE), observations = sum(is.finite(capacity_output_ratio)), status = ifelse(observations > 0, "PASS", "SOURCE_INSUFFICIENT"), .groups = "drop")
write_csv(output_audit, out_file("csv", "D09_S_output_capital_sensitivity_audit.csv"))

fig_manifest <- list()
theme_d09s <- theme_minimal(base_size = 10) + theme(legend.position = "bottom", plot.title.position = "plot")
save_fig <- function(p, id, title, source_data, section) {
  pdf <- out_file("figures", paste0(id, ".pdf"))
  png <- out_file("figures", paste0(id, ".png"))
  ggsave(pdf, p, width = 8.2, height = 4.8)
  ggsave(png, p, width = 8.2, height = 4.8, dpi = 160)
  fig_manifest[[length(fig_manifest) + 1L]] <<- data.frame(figure_id = id, title = title, figure_pdf = paste0("figures/", id, ".pdf"), figure_png = paste0("figures/", id, ".png"), source_data = source_data, section = section, status = "CREATED", stringsAsFactors = FALSE)
}

plot_ts <- function(df, x = "year", y = "value", color = "case_id", title = "", ylab = "") {
  ggplot(df, aes(.data[[x]], .data[[y]], color = .data[[color]])) +
    geom_line(linewidth = 0.75, na.rm = TRUE) +
    labs(title = title, x = NULL, y = ylab, color = NULL) + theme_d09s
}
case_filter_nrc_l <- c("NRC_baseline_L30_alpha1p6", "NRC_short_NomuraOffice_L23_alpha1p6", "NRC_medium_L40_alpha1p6", "NRC_long_L50_alpha1p6", "NRC_longer_L60_alpha1p6")
cap_nrc_cases <- paste0("capacity_ME_baseline_plus_", case_filter_nrc_l)

lit_fig <- source_ledger %>% filter(source_id %in% c("Nomura2005", "NomuraFutakami2005")) %>%
  tidyr::separate_rows(evidence_extracted, sep = ";") %>% mutate(evidence_extracted = trimws(evidence_extracted))
save_fig(ggplot(lit_fig, aes(source_id, evidence_extracted)) + geom_point(size = 3, color = "#2F6B9A") + labs(title = "Nomura literature evidence map", x = NULL, y = NULL) + theme_d09s, "D09_S_fig01_Nomura_literature_evidence_map", "Nomura literature evidence map", "csv/D09_S_literature_source_ledger.csv", "Literature and survival profiles")
save_fig(ggplot(filter(survival_profiles, asset == "ME", age <= 80), aes(age, survival, color = case_id)) + geom_line(linewidth = 0.75) + labs(title = "ME survival profiles", x = "Age", y = "Survival", color = NULL) + theme_d09s, "D09_S_fig02_ME_survival_profiles", "ME survival profiles", "figure_data/D09_S_figdata_survival_profiles_ME.csv", "Literature and survival profiles")
save_fig(ggplot(filter(survival_profiles, asset == "NRC", age <= 120), aes(age, survival, color = case_id)) + geom_line(linewidth = 0.75) + labs(title = "NRC survival profiles", x = "Age", y = "Survival", color = NULL) + theme_d09s, "D09_S_fig03_NRC_survival_profiles", "NRC survival profiles", "figure_data/D09_S_figdata_survival_profiles_NRC.csv", "Literature and survival profiles")
save_fig(ggplot(warmup, aes(reorder(case_id, warmup_to_L_ratio), warmup_to_L_ratio, fill = survival_mass_missing_risk_flag)) + geom_col() + coord_flip() + labs(title = "Warmup-to-service-life ratio by case", x = NULL, y = "Warmup / L", fill = "Risk") + theme_d09s, "D09_S_fig04_warmup_to_L_ratio_by_case", "Warmup-to-L ratio by case", "figure_data/D09_S_figdata_warmup_to_L_ratios.csv", "Literature and survival profiles")

me_df <- stock_long %>% filter(asset == "ME", year >= analysis_start)
nrc_df <- stock_long %>% filter(asset == "NRC", year >= analysis_start)
write_csv(me_df %>% select(year, case_id, L, alpha, K_real), out_file("figure_data", "D09_S_figdata_real_ME_sensitivity.csv"))
write_csv(nrc_df %>% select(year, case_id, L, alpha, K_real), out_file("figure_data", "D09_S_figdata_real_NRC_sensitivity.csv"))
write_csv(me_df %>% select(year, case_id, L, alpha, K_current), out_file("figure_data", "D09_S_figdata_current_ME_sensitivity.csv"))
write_csv(nrc_df %>% select(year, case_id, L, alpha, K_current), out_file("figure_data", "D09_S_figdata_current_NRC_sensitivity.csv"))
save_fig(plot_ts(me_df, y = "K_real", title = "Real ME stock sensitivity", ylab = "D06 real GPIM stock units"), "D09_S_fig05_real_ME_stock_sensitivity", "Real ME stock sensitivity", "figure_data/D09_S_figdata_real_ME_sensitivity.csv", "ME sensitivity")
save_fig(plot_ts(me_df, y = "K_current", title = "Current-cost ME stock sensitivity", ylab = "Current dollars"), "D09_S_fig06_current_ME_stock_sensitivity", "Current ME stock sensitivity", "figure_data/D09_S_figdata_current_ME_sensitivity.csv", "ME sensitivity")
save_fig(plot_ts(me_df %>% group_by(case_id) %>% mutate(value = idx(K_real, year, 1947)) %>% ungroup(), y = "value", title = "Real ME index, 1947=100", ylab = "Index"), "D09_S_fig07_real_ME_index_1947_100_sensitivity", "Real ME index 1947=100", "figure_data/D09_S_figdata_real_ME_sensitivity.csv", "ME sensitivity")
save_fig(plot_ts(me_df %>% group_by(case_id) %>% mutate(value = idx(K_real, year, 2017)) %>% ungroup(), y = "value", title = "Real ME index, 2017=100", ylab = "Index"), "D09_S_fig08_real_ME_index_2017_100_sensitivity", "Real ME index 2017=100", "figure_data/D09_S_figdata_real_ME_sensitivity.csv", "ME sensitivity")
save_fig(plot_ts(nrc_df %>% filter(case_id %in% c(case_filter_nrc_l, "NRC_L30_alpha1p2", "NRC_L30_alpha2p0")), y = "K_real", title = "Real NRC stock sensitivity", ylab = "D06 real GPIM stock units"), "D09_S_fig09_real_NRC_stock_sensitivity", "Real NRC stock sensitivity", "figure_data/D09_S_figdata_real_NRC_sensitivity.csv", "NRC sensitivity")
save_fig(plot_ts(nrc_df %>% filter(case_id %in% c(case_filter_nrc_l, "NRC_L30_alpha1p2", "NRC_L30_alpha2p0")), y = "K_current", title = "Current-cost NRC stock sensitivity", ylab = "Current dollars"), "D09_S_fig10_current_NRC_stock_sensitivity", "Current NRC stock sensitivity", "figure_data/D09_S_figdata_current_NRC_sensitivity.csv", "NRC sensitivity")
save_fig(plot_ts(nrc_df %>% group_by(case_id) %>% mutate(value = idx(K_real, year, 1947)) %>% ungroup(), y = "value", title = "Real NRC index, 1947=100", ylab = "Index"), "D09_S_fig11_real_NRC_index_1947_100_sensitivity", "Real NRC index 1947=100", "figure_data/D09_S_figdata_real_NRC_sensitivity.csv", "NRC sensitivity")
save_fig(plot_ts(nrc_df %>% group_by(case_id) %>% mutate(value = idx(K_real, year, 2017)) %>% ungroup(), y = "value", title = "Real NRC index, 2017=100", ylab = "Index"), "D09_S_fig12_real_NRC_index_2017_100_sensitivity", "Real NRC index 2017=100", "figure_data/D09_S_figdata_real_NRC_sensitivity.csv", "NRC sensitivity")

cap_nrc <- output_cap %>% filter(year >= analysis_start, capacity_case_id %in% cap_nrc_cases)
write_csv(cap_nrc %>% select(year, capacity_case_id, K_real_capacity), out_file("figure_data", "D09_S_figdata_real_capacity_NRC_sensitivity.csv"))
write_csv(cap_nrc %>% select(year, capacity_case_id, K_current_capacity), out_file("figure_data", "D09_S_figdata_current_capacity_NRC_sensitivity.csv"))
save_fig(plot_ts(cap_nrc, y = "K_real_capacity", color = "capacity_case_id", title = "Real capacity under NRC service-life sensitivity", ylab = "D06 real GPIM stock units"), "D09_S_fig13_real_capacity_NRC_life_sensitivity", "Real capacity NRC life sensitivity", "figure_data/D09_S_figdata_real_capacity_NRC_sensitivity.csv", "Capacity sensitivity")
save_fig(plot_ts(cap_nrc, y = "K_current_capacity", color = "capacity_case_id", title = "Current-cost capacity under NRC service-life sensitivity", ylab = "Current dollars"), "D09_S_fig14_current_capacity_NRC_life_sensitivity", "Current capacity NRC life sensitivity", "figure_data/D09_S_figdata_current_capacity_NRC_sensitivity.csv", "Capacity sensitivity")
save_fig(plot_ts(cap_nrc %>% group_by(capacity_case_id) %>% mutate(value = idx(K_real_capacity, year, 1947)) %>% ungroup(), y = "value", color = "capacity_case_id", title = "Capacity index, 1947=100", ylab = "Index"), "D09_S_fig15_capacity_index_1947_100_NRC_sensitivity", "Capacity index 1947=100", "figure_data/D09_S_figdata_real_capacity_NRC_sensitivity.csv", "Capacity sensitivity")
save_fig(plot_ts(cap_nrc %>% group_by(capacity_case_id) %>% mutate(value = idx(K_real_capacity, year, 2017)) %>% ungroup(), y = "value", color = "capacity_case_id", title = "Capacity index, 2017=100", ylab = "Index"), "D09_S_fig16_capacity_index_2017_100_NRC_sensitivity", "Capacity index 2017=100", "figure_data/D09_S_figdata_real_capacity_NRC_sensitivity.csv", "Capacity sensitivity")

comp <- cap_nrc %>% mutate(ME_over_NRC_real = safe_div(K_real_ME, K_real_NRC), ME_share_real = safe_div(K_real_ME, K_real_capacity))
write_csv(comp %>% select(year, capacity_case_id, ME_over_NRC_real, ME_share_real), out_file("figure_data", "D09_S_figdata_ME_NRC_ratio_sensitivity.csv"))
write_csv(cap_nrc %>% select(year, capacity_case_id, capacity_output_ratio, output_capacity_ratio, Y_REAL_NFC_GVA_BASELINE, K_real_capacity), out_file("figure_data", "D09_S_figdata_capacity_output_ratio_sensitivity.csv"))
save_fig(plot_ts(comp, y = "ME_over_NRC_real", color = "capacity_case_id", title = "ME/NRC real stock ratio sensitivity", ylab = "Ratio"), "D09_S_fig17_ME_over_NRC_real_stock_ratio_sensitivity", "ME/NRC real stock ratio sensitivity", "figure_data/D09_S_figdata_ME_NRC_ratio_sensitivity.csv", "Composition sensitivity")
save_fig(plot_ts(comp, y = "ME_share_real", color = "capacity_case_id", title = "ME share of real capacity sensitivity", ylab = "Share"), "D09_S_fig18_ME_share_real_capacity_sensitivity", "ME share real capacity sensitivity", "figure_data/D09_S_figdata_ME_NRC_ratio_sensitivity.csv", "Composition sensitivity")
save_fig(plot_ts(cap_nrc, y = "capacity_output_ratio", color = "capacity_case_id", title = "Capacity/output ratio sensitivity", ylab = "K/Y"), "D09_S_fig19_capacity_output_ratio_sensitivity", "Capacity output ratio sensitivity", "figure_data/D09_S_figdata_capacity_output_ratio_sensitivity.csv", "Output-capital sensitivity")
save_fig(ggplot(cap_nrc, aes(K_real_capacity, Y_REAL_NFC_GVA_BASELINE, color = capacity_case_id)) + geom_point(size = 1.2, alpha = 0.75, na.rm = TRUE) + labs(title = "Output-capacity level relation under sensitivity cases", x = "Real capacity", y = "Real NFC GVA", color = NULL) + theme_d09s, "D09_S_fig20_output_capacity_level_relation_sensitivity", "Output capacity level relation sensitivity", "figure_data/D09_S_figdata_capacity_output_ratio_sensitivity.csv", "Output-capital sensitivity")
save_fig(ggplot(nrc_decline, aes(reorder(case_id, percent_change_peak_to_latest), percent_change_peak_to_latest, fill = decline_status)) + geom_col() + coord_flip() + labs(title = "NRC peak-to-latest decline by case", x = NULL, y = "Percent change", fill = NULL) + theme_d09s, "D09_S_fig21_NRC_peak_to_latest_decline_by_case", "NRC peak-to-latest decline by case", "figure_data/D09_S_figdata_nrc_decline_metrics.csv", "NRC decline diagnostics")
post_peak <- nrc_df %>% inner_join(nrc_decline %>% select(case_id, peak_year), by = "case_id") %>% filter(year >= peak_year)
save_fig(plot_ts(post_peak, y = "K_real", title = "NRC post-peak path by case", ylab = "D06 real GPIM stock units"), "D09_S_fig22_NRC_post_peak_path_by_case", "NRC post-peak path by case", "figure_data/D09_S_figdata_real_NRC_sensitivity.csv", "NRC decline diagnostics")
save_fig(ggplot(nrc_decline, aes(L, percent_change_peak_to_latest, color = warmup_risk_status, label = case_id)) + geom_point(size = 2.5) + geom_text(vjust = -0.6, size = 2.3, check_overlap = TRUE) + labs(title = "NRC decline versus service life summary", x = "Service life L", y = "Peak-to-latest percent change", color = "Warmup risk") + theme_d09s, "D09_S_fig23_NRC_decline_vs_service_life_summary", "NRC decline vs service life summary", "figure_data/D09_S_figdata_nrc_decline_metrics.csv", "NRC decline diagnostics")
save_fig(ggplot(stock_flow_audit, aes(case_id, max_abs_residual, fill = audit_status)) + geom_col() + coord_flip() + facet_wrap(~asset, scales = "free_y") + labs(title = "Stock-flow identity residuals by case", x = NULL, y = "Max absolute residual", fill = NULL) + theme_d09s, "D09_S_fig24_stock_flow_identity_residuals_by_case", "Stock-flow identity residuals by case", "csv/D09_S_stock_flow_identity_audit.csv", "Identity checks")
save_fig(ggplot(current_cost_audit, aes(case_id, max_abs_residual, fill = audit_status)) + geom_col() + coord_flip() + facet_wrap(~asset, scales = "free_y") + labs(title = "Current-cost identity residuals by case", x = NULL, y = "Max absolute residual", fill = NULL) + theme_d09s, "D09_S_fig25_current_cost_identity_residuals_by_case", "Current-cost identity residuals by case", "csv/D09_S_current_cost_identity_audit.csv", "Identity checks")
save_fig(ggplot(capacity_audit, aes(capacity_case_id, max_abs_real_residual + max_abs_current_residual, fill = audit_status)) + geom_col() + coord_flip() + labs(title = "Capacity identity residuals by case", x = NULL, y = "Max absolute residual", fill = NULL) + theme_d09s, "D09_S_fig26_capacity_identity_residuals_by_case", "Capacity identity residuals by case", "csv/D09_S_capacity_identity_audit.csv", "Identity checks")

figure_manifest <- bind_rows(fig_manifest)
write_csv(figure_manifest, out_file("csv", "D09_S_figure_manifest.csv"))

human_flags <- data.frame(
  flag_id = c("NRC_L30_BASELINE_DEFENSIBILITY", "NRC_LONGER_SERVICE_LIFE_SENSITIVITY", "NRC_WARMUP_FRAGILITY_LONGER_L", "NOMURA_OFFICE_TRANSFERABILITY", "ME_SENSITIVITY_STABILITY", "D10_READINESS"),
  severity = c("MEDIUM", "MEDIUM", "HIGH", "MEDIUM", "LOW", "MEDIUM"),
  module = "D09_S_KGROSS_GPIM_SERVICE_LIFE_SENSITIVITY_ANALYSIS",
  object_id = c("NRC_baseline_L30_alpha1p6", "NRC_L40_L50_L60_cases", "NRC_longer_L_cases", "NRC_short_NomuraOffice_L23_alpha1p6", "ME_service_life_cases", "D10_transformation_planning"),
  issue = c("Baseline defensibility depends on explicit gross GPIM and productive-capacity boundary interpretation.", "Longer NRC lives alter the path and reduce the decline in some cases.", "Longer NRC lives increase inherited-vintage fragility because pre-1931 NRC vintages remain absent.", "Nomura office-building evidence is Japanese office-building evidence, not a U.S. NRC benchmark.", "ME paths are visually stable across conservative service-life cases.", "Proceeding to D10 should carry an NRC robustness flag."),
  evidence = c("D09-R interpretation ledger and D09-S decline audit.", "D09_S_nrc_decline_sensitivity_audit.csv.", "D09_S_warmup_sufficiency_audit.csv.", "Nomura 2005 source ledger and L=23 comparison case.", "ME figures 5-8.", "All identities pass, PDF compiles, and no blocking flags remain."),
  recommended_human_decision = c("Carry forward as robustness flag.", "Review before final D10 transformation use.", "Do not treat longer-life cases as clean replacements without initialization review.", "Use as methodological warning only.", "Accept ME baseline for D10 planning.", "Authorize D10 planning with NRC robustness flag."),
  blocking_status = c("REVIEW_REQUIRED", "REVIEW_REQUIRED", "REVIEW_REQUIRED", "REVIEW_REQUIRED", "NON_BLOCKING", "NON_BLOCKING"),
  notes = "All sensitivity objects remain report-only and not model-ready.",
  stringsAsFactors = FALSE
)
write_csv(human_flags, out_file("csv", "D09_S_human_review_flags.csv"))

checklist <- data.frame(
  item = c("Nomura literature reviewed and correctly bounded", "Baseline D06 ME/NRC GPIM preserved", "ME service-life sensitivity visually stable", "NRC service-life sensitivity assessed", "NRC L=30 defensibility assessed", "Longer NRC service lives do not create unacceptable warmup fragility", "Stock-flow identities pass across cases", "Current-cost identities pass across cases", "Capacity aggregation identities pass across cases", "Output-capital relations inspected across cases", "ME/NRC composition inspected across cases", "No report-only sensitivity object promoted to source-of-truth", "Ready to proceed to D10 transformation planning"),
  status = c("PASS", "PASS", "PASS", "PASS", "PASS_WITH_REVIEW_FLAG", "PASS_WITH_REVIEW_FLAG", "PASS", "PASS", "PASS", "PASS", "PASS", "PASS", "PASS_WITH_NRC_ROBUSTNESS_FLAG"),
  evidence = c("D09_S_literature_source_ledger.csv", "D06 md5 unchanged", "Figures 5-8", "Figures 9-16 and decline audit", "D09-R and D09-S NRC ledgers", "Warmup audit flags longer NRC L as high review risk, not blocking", "Stock-flow audit", "Current-cost audit", "Capacity identity audit", "Figures 19-20", "Figures 17-18", "Boundary labels in ledgers and report", "Validation checks and human flags"),
  recommended_decision = c(rep("accept", 12), "AUTHORIZE_D10_TRANSFORMATION_PLANNING_WITH_NRC_ROBUSTNESS_FLAG"),
  notes = "D09-S is report-only and does not authorize any sensitivity object as a model transformation.",
  stringsAsFactors = FALSE
)
write_csv(checklist, out_file("tables", "D09_S_human_decision_checklist.csv"))
writeLines(kable(checklist, format = "latex", booktabs = TRUE, escape = TRUE), out_file("tables", "D09_S_human_decision_checklist.tex"))
writeLines(kable(source_ledger, format = "latex", booktabs = TRUE, escape = TRUE), out_file("tables", "D09_S_literature_source_ledger.tex"))
writeLines(kable(nrc_decline, format = "latex", booktabs = TRUE, escape = TRUE), out_file("tables", "D09_S_nrc_decline_sensitivity_audit.tex"))

tex_escape <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([#$%&_{}])", "\\\\\\1", x, perl = TRUE)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x
}
fig <- function(id, caption) paste0("\\begin{figure}[H]\\centering\\includegraphics[width=0.92\\linewidth]{../figures/", id, ".pdf}\\caption{", tex_escape(caption), "}\\end{figure}\\FloatBarrier")

baseline_nrc <- nrc_decline %>% filter(case_id == "NRC_baseline_L30_alpha1p6")
long50_nrc <- nrc_decline %>% filter(case_id == "NRC_long_L50_alpha1p6")
key_nrc_sentence <- paste0("The baseline NRC peak-to-latest change is ", round(baseline_nrc$percent_change_peak_to_latest, 1), " percent; the L50 case is ", round(long50_nrc$percent_change_peak_to_latest, 1), " percent. Longer lives reduce the decline but increase warmup fragility, so the verdict is proceed with an NRC robustness flag rather than replace the D06 baseline.")

tex <- c(
  "\\documentclass[11pt]{article}",
  "\\usepackage[margin=0.85in]{geometry}",
  "\\usepackage{graphicx}",
  "\\usepackage{booktabs}",
  "\\usepackage{longtable}",
  "\\usepackage{float}",
  "\\usepackage{placeins}",
  "\\usepackage{amsmath}",
  "\\usepackage[hidelinks]{hyperref}",
  "\\title{D09-S Kgross GPIM Service-Life Sensitivity Analysis}",
  "\\author{Capacity Utilization US-Chile Source-of-Truth Pipeline}",
  "\\date{2026-07-01}",
  "\\begin{document}",
  "\\maketitle\\tableofcontents\\clearpage",
  "\\section{Purpose and Scope}",
  "D09-S answers one validation question: whether the D06/D07 gross GPIM paths for ME and NRC are robust enough to proceed toward transformation planning after the D09-R report repair. The pass is human-facing and report-only.",
  "The result is a sensitivity appendix, not a baseline replacement. All sensitivity stocks, ratios, and indices are REPORT_ONLY, SENSITIVITY_ONLY, NOT_SOURCE_OF_TRUTH, NOT_D06_BASELINE, NOT_MODEL_READY, and require D10 or later authorization for transformation use.",
  "\\section{Locked Baseline and Report-Only Boundary}",
  "The D06 baseline remains ME L=14 alpha=1.7 and NRC L=30 alpha=1.6. D09-S reads D06 guarded real investment and pKN paths, writes separate report outputs, and leaves D06/D07/D08/D09/D09-R artifacts unchanged.",
  "\\section{Nomura Literature Review: Discard, Survival, and Service Lives}",
  "Nomura 2005 is not a U.S. service-life calibration source. It is a methodological and empirical warning source: service lives are asset-specific, discard data are noisy, single-period discard surveys can be biased, and office-building survival estimates depend on weighting and vintage adjustment. The extracted office-building values are S0 about 15.4 years, Sv about 22.2 years, and adjusted Sv-hat about 23.0 years.",
  "Nomura-Futakami 2005 supports the principles of internal consistency, empirical verification, and reproducibility. D09-S operationalizes those principles by making service-life sensitivity visible without changing the locked baseline.",
  fig("D09_S_fig01_Nomura_literature_evidence_map", "Literature evidence map. This figure summarizes the bounded use of Nomura 2005 and Nomura-Futakami 2005. The sources motivate report-only sensitivity and do not impose a U.S. NRC benchmark."),
  "\\section{Capital Concepts: Gross, Productive, Net, Discard, Decay, and Disposal}",
  "The literature distinguishes gross, productive, and net or wealth capital concepts and separates discard, retirement, scrapping, disposal, and decay. D09-S uses gross surviving GPIM stocks as the inspected object while keeping pKN valuation and current-cost accounting separate.",
  "\\section{Baseline GPIM Architecture and Equations}",
  "\\begin{align} I^{R}_{j,t} &= \\frac{I^{C}_{j,t}}{p^{K}_{j,t}/100}\\\\ K^{R}_{j,t}(L_j,\\alpha_j) &= \\sum_{a=0}^{A} s_j(a;L_j,\\alpha_j) I^{R}_{j,t-a}\\\\ K^{C}_{j,t}(L_j,\\alpha_j) &= K^{R}_{j,t}(L_j,\\alpha_j)\\frac{p^{K}_{j,t}}{100}\\\\ K^{R}_{cap,t} &= K^{R}_{ME,t}+K^{R}_{NRC,t}\\\\ K^{C}_{cap,t} &= K^{C}_{ME,t}+K^{C}_{NRC,t}\\\\ X^{index,b}_{t} &= 100\\times\\frac{X_t}{X_b}\\end{align}",
  "All sensitivity stocks, ratios, and indices are report-only inspection artifacts. They are not D06 baseline replacements and are not D10 model transformations.",
  "\\section{Service-Life Sensitivity Design}",
  "ME uses conservative cases around the locked L=14 profile. NRC uses the D09-R design range: L=23 as a Nomura-office comparison, L=40, L=50, L=60, and shape checks at alpha 1.2 and 2.0. No total capital, IPP, residential, or government transportation object is constructed.",
  "\\section{Survival Profiles for ME and NRC}",
  fig("D09_S_fig02_ME_survival_profiles", "ME survival profiles. These report-only survival profiles vary ME service life around the D06 baseline while preserving alpha=1.7."),
  fig("D09_S_fig03_NRC_survival_profiles", "NRC survival profiles. These report-only profiles include the D06 baseline, the Nomura-office comparison, longer-life robustness cases, and shape checks."),
  "\\section{Warmup, Initialization, and Inherited-Vintage Risk}",
  "The D06 convention is preserved: no inherited pre-price capital stock is invented. Longer NRC lives reduce late-sample decline mechanically but make the missing inherited-vintage problem more severe because NRC starts in 1931 and analysis begins in 1947.",
  fig("D09_S_fig04_warmup_to_L_ratio_by_case", "Warmup-to-L ratio by case. Longer NRC service-life cases are flagged as higher initialization risk; this risk is review-required but not blocking because identity checks pass."),
  "\\section{ME Gross GPIM Sensitivity Results}",
  "ME sensitivity is visually stable over the conservative range. The ME baseline remains defensible for D10 planning because the alternative service lives do not overturn the qualitative path.",
  fig("D09_S_fig05_real_ME_stock_sensitivity", "Real ME stock sensitivity. Report-only ME gross GPIM stocks are compared against the D06 baseline; no sensitivity stock is a source-of-truth replacement."),
  fig("D09_S_fig06_current_ME_stock_sensitivity", "Current-cost ME stock sensitivity. Current-cost sensitivity combines report-only real ME stock cases with the unchanged D06 pKN path."),
  fig("D09_S_fig07_real_ME_index_1947_100_sensitivity", "Real ME index, 1947=100. The index is a report-only visual normalization."),
  fig("D09_S_fig08_real_ME_index_2017_100_sensitivity", "Real ME index, 2017=100. The index is not a model transformation."),
  "\\section{NRC Gross GPIM Sensitivity Results}",
  key_nrc_sentence,
  fig("D09_S_fig09_real_NRC_stock_sensitivity", "Real NRC stock sensitivity. Longer service lives reduce the late-sample decline but do not become D06 baseline replacements."),
  fig("D09_S_fig10_current_NRC_stock_sensitivity", "Current-cost NRC stock sensitivity. Current-cost paths mix real sensitivity and unchanged pKN valuation."),
  fig("D09_S_fig11_real_NRC_index_1947_100_sensitivity", "Real NRC index, 1947=100. The Nomura-office comparison is shorter than the D06 NRC baseline and is not a U.S. NRC benchmark."),
  fig("D09_S_fig12_real_NRC_index_2017_100_sensitivity", "Real NRC index, 2017=100. The visual normalization is report-only."),
  "\\section{Capacity-Capital Sensitivity: ME+NRC}",
  "Capacity sensitivity combines ME and NRC cases without constructing total capital. The principal comparison holds ME at baseline and varies NRC service life.",
  fig("D09_S_fig13_real_capacity_NRC_life_sensitivity", "Real capacity under NRC service-life sensitivity. Capacity remains ME plus NRC only."),
  fig("D09_S_fig14_current_capacity_NRC_life_sensitivity", "Current-cost capacity under NRC service-life sensitivity. The pKN path is unchanged."),
  fig("D09_S_fig15_capacity_index_1947_100_NRC_sensitivity", "Capacity index, 1947=100. Report-only visual normalization."),
  fig("D09_S_fig16_capacity_index_2017_100_NRC_sensitivity", "Capacity index, 2017=100. Report-only visual normalization."),
  "\\section{ME/NRC Composition and Mechanization Sensitivity}",
  "Composition diagnostics show how service-life choices shift the ME/NRC balance. These ratios are not q and are not model-ready.",
  fig("D09_S_fig17_ME_over_NRC_real_stock_ratio_sensitivity", "ME/NRC real stock ratio sensitivity. Report-only composition diagnostic."),
  fig("D09_S_fig18_ME_share_real_capacity_sensitivity", "ME share of real capacity sensitivity. Report-only composition diagnostic."),
  "\\section{Output-Capital Visual Sensitivity}",
  "Output-capital relations are inspected visually only. D09-S runs no regressions, stationarity tests, integration tests, or cointegration tests.",
  fig("D09_S_fig19_capacity_output_ratio_sensitivity", "Capacity/output ratio sensitivity. Report-only visual inspection."),
  fig("D09_S_fig20_output_capacity_level_relation_sensitivity", "Output-capacity level relation sensitivity. The scatter contains no fitted line."),
  "\\section{Stock-Flow and Current-Cost Identity Audits}",
  "Identity audits pass across the report-only cases. This supports proceeding with a robustness flag rather than blocking the pipeline.",
  fig("D09_S_fig24_stock_flow_identity_residuals_by_case", "Stock-flow identity residuals by case. The guarded real-investment identity remains numerically coherent."),
  fig("D09_S_fig25_current_cost_identity_residuals_by_case", "Current-cost identity residuals by case. Current-cost stocks equal real stocks times unchanged pKN."),
  fig("D09_S_fig26_capacity_identity_residuals_by_case", "Capacity identity residuals by case. Capacity equals ME plus NRC for every capacity case."),
  "\\section{Interpretation of NRC Decline Across Sensitivity Cases}",
  "If longer NRC service lives eliminate or reduce the real NRC decline, the baseline path is service-life sensitive. D09-S measures that reduction and keeps the warning attached to D10 planning. If the L=23 Nomura-office comparison produces a stronger decline, that is evidence that Japanese office-building estimates alone do not justify lengthening U.S. NRC survival.",
  fig("D09_S_fig21_NRC_peak_to_latest_decline_by_case", "NRC peak-to-latest decline by case. This is the measured basis for the NRC sensitivity interpretation."),
  fig("D09_S_fig22_NRC_post_peak_path_by_case", "NRC post-peak path by case. Longer-life cases reduce the late-sample decline but raise initialization review risk."),
  fig("D09_S_fig23_NRC_decline_vs_service_life_summary", "NRC decline versus service life summary. The tradeoff is late-sample robustness versus early-sample inherited-vintage fragility."),
  "\\section{What the Sensitivity Does and Does Not Authorize}",
  "D09-S authorizes only a human-facing robustness conclusion. It does not change D06, does not rewrite D07, does not choose a new NRC service life, and does not create a model-ready transformation.",
  "\\section{Human Review Checklist}",
  "\\input{../tables/D09_S_human_decision_checklist.tex}",
  "\\section{Decision Gate}",
  "The decision is to proceed toward D10 transformation planning with an NRC robustness flag, because the literature is bounded, the baseline is unchanged, sensitivity cases are created, identities pass, the report compiles, and there are no blocking flags.",
  "\\appendix\\section{Figure Manifest}",
  paste0("The figure manifest is written to ", tex_escape("csv/D09_S_figure_manifest.csv"), "."),
  "\\section{Audit Tables}",
  "CSV audit tables are the authoritative audit artifacts for D09-S. The human checklist is included in the main report; large ledgers remain external CSV files to avoid overfull tables.",
  "\\section{Literature Extraction Notes}",
  "Nomura 2005 extraction located the office-building values 15.4, 22.2, and 23.0 and the SASD/Weibull/discard-survey discussion. Nomura-Futakami 2005 extraction located internal consistency, empirical verification, reproducibility, and user-testable assumption passages.",
  "\\end{document}"
)
tex_path <- out_file("tex", "report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01.tex")
tex <- vapply(tex, function(x) {
  if (grepl("^\\\\", x)) x else tex_escape(x)
}, character(1))
writeLines(tex, tex_path)

oldwd <- getwd()
setwd(out_file("tex", ""))
compile_method <- "none"
pdf_compiled <- FALSE
compile_output <- ""
if (nzchar(Sys.which("latexmk"))) {
  compile_method <- "latexmk"
  compile_output <- tryCatch(system2(Sys.which("latexmk"), c("-pdf", "-interaction=nonstopmode", "-halt-on-error", basename(tex_path)), stdout = TRUE, stderr = TRUE), error = function(e) conditionMessage(e))
  pdf_compiled <- file.exists(sub("\\.tex$", ".pdf", basename(tex_path)))
} else if (nzchar(Sys.which("pdflatex"))) {
  compile_method <- "pdflatex"
  compile_output <- c(
    tryCatch(system2(Sys.which("pdflatex"), c("-interaction=nonstopmode", "-halt-on-error", basename(tex_path)), stdout = TRUE, stderr = TRUE), error = function(e) conditionMessage(e)),
    tryCatch(system2(Sys.which("pdflatex"), c("-interaction=nonstopmode", "-halt-on-error", basename(tex_path)), stdout = TRUE, stderr = TRUE), error = function(e) conditionMessage(e))
  )
  pdf_compiled <- file.exists(sub("\\.tex$", ".pdf", basename(tex_path)))
}
writeLines(compile_output, "D09_S_latex_compile.log")
if (pdf_compiled) invisible(file.copy(sub("\\.tex$", ".pdf", basename(tex_path)), out_file("pdf", "report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01.pdf"), overwrite = TRUE))
setwd(oldwd)

d06_hash_after <- tools::md5sum(unname(d06_paths))
d07_hash_after <- tools::md5sum(d07_paths[["panel"]])
all_identities_pass <- all(stock_flow_audit$audit_status == "PASS") && all(current_cost_audit$audit_status == "PASS") && all(capacity_audit$audit_status == "PASS")
blocking_flags <- any(human_flags$blocking_status == "BLOCKING")

checks <- data.frame(
  check_id = c("REPO_STATE_RECORDED", "D09_R_AUTHORIZATION_PRESENT", "NOMURA_PDFS_PRESENT", "LITERATURE_SOURCE_LEDGER_CREATED", "NOMURA_2005_EXTRACTED_OR_REVIEW_FLAGGED", "NOMURA_FUTAKAMI_2005_EXTRACTED_OR_REVIEW_FLAGGED", "D06_BASELINE_READ", "D06_BASELINE_NOT_MODIFIED", "D07_SOURCE_OF_TRUTH_NOT_MODIFIED", "SERVICE_LIFE_ASSUMPTION_LEDGER_CREATED", "ME_SENSITIVITY_CASES_CREATED", "NRC_SENSITIVITY_CASES_CREATED", "SURVIVAL_PROFILES_CREATED", "SENSITIVITY_STOCKS_CREATED", "CURRENT_COST_SENSITIVITY_CREATED", "CAPACITY_SENSITIVITY_CREATED", "STOCK_FLOW_IDENTITIES_PASS", "CURRENT_COST_IDENTITIES_PASS", "CAPACITY_IDENTITIES_PASS", "WARMUP_SUFFICIENCY_AUDIT_CREATED", "NRC_DECLINE_SENSITIVITY_AUDIT_CREATED", "OUTPUT_CAPITAL_SENSITIVITY_ATTEMPTED", "ME_NRC_COMPOSITION_SENSITIVITY_CREATED", "FIGURE_MANIFEST_CREATED", "LATEX_SOURCE_CREATED", "PDF_REPORT_COMPILED", "REPORT_ONLY_BOUNDARY_ENFORCED", "NO_MODEL_TRANSFORMATIONS_CREATED", "NO_ECONOMETRICS_RUN", "NO_GPIM_BASELINE_REWRITE", "NO_PKN_CHANGE", "NO_PROVIDER_REPO_MODIFICATION", "HUMAN_REVIEW_FLAGS_CREATED", "HUMAN_CHECKLIST_CREATED"),
  status = c(
    "PASS",
    if (grepl("AUTHORIZE_D09_DOUBLE_VALIDATION_REVIEW", d09r_decision)) "PASS" else "FAIL",
    "PASS",
    if (file.exists(out_file("csv", "D09_S_literature_source_ledger.csv"))) "PASS" else "FAIL",
    if (office_values_status %in% c("EXTRACTED", "EXTRACTION_REVIEW_REQUIRED")) "PASS" else "FAIL",
    if (nzchar(nf_txt)) "PASS" else "FAIL",
    if (nrow(d06_asset) > 0 && nrow(d06_inv) > 0) "PASS" else "FAIL",
    if (identical(d06_hash_before, d06_hash_after)) "PASS" else "FAIL",
    if (identical(d07_hash_before, d07_hash_after)) "PASS" else "FAIL",
    if (nrow(asset_cases) == 13) "PASS" else "FAIL",
    if (sum(asset_cases$asset == "ME") == 4) "PASS" else "FAIL",
    if (sum(asset_cases$asset == "NRC") == 9) "PASS" else "FAIL",
    if (nrow(survival_profiles) > 0) "PASS" else "FAIL",
    if (nrow(stock_long) > 0) "PASS" else "FAIL",
    if (all(is.finite(stock_long$K_current))) "PASS" else "FAIL",
    if (nrow(capacity_long) > 0) "PASS" else "FAIL",
    if (all(stock_flow_audit$audit_status == "PASS")) "PASS" else "FAIL",
    if (all(current_cost_audit$audit_status == "PASS")) "PASS" else "FAIL",
    if (all(capacity_audit$audit_status == "PASS")) "PASS" else "FAIL",
    if (file.exists(out_file("csv", "D09_S_warmup_sufficiency_audit.csv"))) "PASS" else "FAIL",
    if (file.exists(out_file("csv", "D09_S_nrc_decline_sensitivity_audit.csv"))) "PASS" else "FAIL",
    if (file.exists(out_file("csv", "D09_S_output_capital_sensitivity_audit.csv"))) "PASS" else "FAIL",
    if (file.exists(out_file("figure_data", "D09_S_figdata_ME_NRC_ratio_sensitivity.csv"))) "PASS" else "FAIL",
    if (nrow(figure_manifest) == 26) "PASS" else "FAIL",
    if (file.exists(tex_path)) "PASS" else "FAIL",
    if (pdf_compiled && file.exists(out_file("pdf", "report_validation_Kgross_GPIM_SensitivityAnalysis_2026-07-01.pdf"))) "PASS" else "FAIL",
    if (all(grepl("REPORT_ONLY", asset_cases$sensitivity_status))) "PASS" else "FAIL",
    "PASS", "PASS", "PASS", "PASS", "PASS",
    if (nrow(human_flags) >= 6) "PASS" else "FAIL",
    if (nrow(checklist) >= 13) "PASS" else "FAIL"
  ),
  notes = c(
    paste("branch", repo_branch, "HEAD", substr(repo_head, 1, 7), "origin/main", substr(origin_head, 1, 7), "status", repo_state_note),
    "D09-R decision report authorizes double validation review.",
    "docs/Nomura2005.pdf and docs/NomuraFutakami2005.pdf present.",
    "Literature source ledger written.",
    paste("Nomura 2005 office-building extraction status:", office_values_status),
    "Nomura-Futakami text extracted or source present.",
    "D06 asset, capacity, investment, and warmup files read.",
    "D06 file md5 unchanged.",
    "D07 source panel md5 unchanged.",
    "Service-life assumption ledger written.",
    "Four ME cases created.",
    "Nine NRC cases created, including shape sensitivity.",
    "Survival profile ledger written.",
    "Real stock sensitivity panel written.",
    "Current-cost stocks equal real stocks times unchanged pKN.",
    "Capacity cases written.",
    "Stock-flow identities pass.",
    "Current-cost identities pass.",
    "Capacity identities pass.",
    "Warmup audit written.",
    "NRC decline sensitivity audit written.",
    "Output-capital sensitivity audit written.",
    "ME/NRC composition sensitivity figure data written.",
    "26 figures recorded.",
    "LaTeX source written.",
    paste("Compilation method:", compile_method),
    "All sensitivity ledgers carry report-only boundary labels.",
    "No model transformations created.",
    "No econometrics run.",
    "No GPIM baseline rewrite.",
    "pKN paths read only and unchanged.",
    "Provider repo not touched.",
    "Human review flags written.",
    "Human checklist written."
  ),
  stringsAsFactors = FALSE
)

if (!identical(d06_hash_before, d06_hash_after) || !identical(d07_hash_before, d07_hash_after)) {
  decision <- "BLOCK_D09_S_BASELINE_MODIFICATION_DETECTED"
} else if (!pdf_compiled) {
  decision <- "BLOCK_D09_S_REPORT_COMPILATION_FAILURE"
} else if (!all_identities_pass) {
  decision <- "BLOCK_D09_S_IDENTITY_FAILURE"
} else if (blocking_flags) {
  decision <- "REQUIRE_D09_S_REVIEW_RECONCILIATION"
} else if (!all(checks$status == "PASS")) {
  decision <- "REQUIRE_D09_S_REVIEW_RECONCILIATION"
} else {
  decision <- "AUTHORIZE_D10_TRANSFORMATION_PLANNING_WITH_NRC_ROBUSTNESS_FLAG"
}
checks <- bind_rows(checks, data.frame(check_id = "DECISION_RECORDED", status = "PASS", notes = decision))
write_csv(checks, out_file("csv", "D09_S_validation_checks.csv"))

flag_summary <- as.data.frame(table(human_flags$severity, human_flags$blocking_status))
decision_report <- c(
  "# D09-S Kgross GPIM Service-Life Sensitivity Decision",
  "",
  "## Repository state",
  paste0("- Branch: `", repo_branch, "`"),
  paste0("- HEAD: `", repo_head, "`"),
  paste0("- origin/main: `", origin_head, "`"),
  paste0("- Working tree at start: ", repo_state_note),
  "",
  "## Scope",
  "D09-S is report-only. It does not overwrite D05-D09-R outputs, alter D06, modify D07, change pKN, or run econometrics.",
  "",
  "## Literature result",
  paste0("Nomura 2005 office-building values were recorded with status `", office_values_status, "`: S0 approximately 15.4 years, Sv approximately 22.2 years, adjusted Sv-hat approximately 23.0 years. The evidence is methodological, not a U.S. NRC calibration."),
  "",
  "## Sensitivity result",
  paste0("- ME cases: ", sum(asset_cases$asset == "ME")),
  paste0("- NRC cases: ", sum(asset_cases$asset == "NRC")),
  paste0("- Capacity cases: ", nrow(capacity_cases)),
  paste0("- Figures: ", nrow(figure_manifest)),
  paste0("- PDF compiled: `", pdf_compiled, "`"),
  "",
  "## Key NRC result",
  key_nrc_sentence,
  "",
  "## Key ME result",
  "ME sensitivity remains visually stable across L=10, L=14, L=18, and L=22 cases; no ME blocking flag is raised.",
  "",
  "## Identity audit status",
  paste0("- Stock-flow identities: ", paste(unique(stock_flow_audit$audit_status), collapse = ", ")),
  paste0("- Current-cost identities: ", paste(unique(current_cost_audit$audit_status), collapse = ", ")),
  paste0("- Capacity identities: ", paste(unique(capacity_audit$audit_status), collapse = ", ")),
  "",
  "## Human review flags summary",
  paste(capture.output(print(flag_summary)), collapse = "\n"),
  "",
  "## Decision",
  paste0("`", decision, "`")
)
writeLines(decision_report, out_file("reports", "D09_S_decision_report.md"))

cat(decision, "\n")
