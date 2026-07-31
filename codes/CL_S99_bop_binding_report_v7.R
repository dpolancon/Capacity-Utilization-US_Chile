#!/usr/bin/env Rscript

# CL_BOP_BINDING v7 / S99: report assembly.
#
# Stages ledgers and figures, records the SHA-256 hash of every consumed input,
# and writes the Markdown and LaTeX sources. Performs no estimation.
#
# Exposition follows chapter2_vault/07_WrittingSkills_and_Rules/
# C02_Advisor_Michael_Facing_Exposition_Prompt.md: name the relation, say what is
# observed and what is estimated, give the simplest equation, say what the
# coefficient means, state the test, state the finding as bounded, say what
# follows. Method vocabulary is translated, never left standing on its own.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(digest)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release_dir <- file.path(root, "data", "releases", "chile_bop_binding_v1_1")
v6_root <- file.path(root, "output", "CL", "BOP_BINDING_V6")
v7_root <- file.path(root, "output", "CL", "BOP_BINDING_V7")
v1_root <- file.path(root, "output", "CL", "BOP_BINDING")
s60 <- file.path(v7_root, "S60_LINEAR_VECM")
s70 <- file.path(v7_root, "S70_BINDING_STATE")
report_dir <- file.path(root, "reports", "Chile_BOP_Binding_Import_ECT_Report",
                        "v7")
data_dir <- file.path(report_dir, "data")
figure_dir <- file.path(report_dir, "figures")
assembly_dir <- file.path(v7_root, "S99_REPORT_ASSEMBLY")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(assembly_dir, recursive = TRUE, showWarnings = FALSE)

release_file <- file.path(release_dir,
                          "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv")

inputs <- c(
  release          = release_file,
  provenance       = file.path(release_dir,
                               "CHILE_BOP_BINDING_PROVENANCE_LEDGER.csv"),
  rer_audit        = file.path(root, "data", "processed", "CL_BOP_BINDING",
                               "S20_RER_SPLICE", "rer_splice_validation.csv"),
  battery          = file.path(v6_root, "S30_INTEGRATION_BREAKS",
                               "sequential_urca_long_ledger.csv"),
  verdict          = file.path(v6_root, "S30_INTEGRATION_BREAKS",
                               "sequential_integration_verdict.csv"),
  ladder           = file.path(s60, "nested_specification_ladder.csv"),
  order_audit      = file.path(s60, "specification_integration_order_audit.csv"),
  rank_grid        = file.path(s60, "johansen_trace_rank_grid.csv"),
  beta             = file.path(s60, "cointegrating_vector_ledger.csv"),
  alpha            = file.path(s60, "adjustment_speed_exogeneity_ledger.csv"),
  gamma            = file.path(s60, "short_run_structure_ledger.csv"),
  diagnostics      = file.path(s60, "vecm_model_diagnostic_ledger.csv"),
  promotion_req    = file.path(s60, "promotion_requirement_ledger.csv"),
  promoted         = file.path(s60, "promoted_model_ledger.csv"),
  misalignment     = file.path(s60, "import_misalignment_panel.csv"),
  trend_comparison = file.path(s60, "long_run_coefficient_trend_comparison.csv"),
  beta_bootstrap   = file.path(s60, "beta_bootstrap_summary.csv"),
  lag_selection    = file.path(s60, "lag_selection_ledger.csv"),
  s60_integrity    = file.path(s60, "s60_stage_integrity.csv"),
  episode_panel    = file.path(s70, "bop_binding_episode_panel.csv"),
  episode_summary  = file.path(s70, "binding_episode_summary.csv"),
  class_counts     = file.path(s70, "binding_classification_counts.csv"),
  class_rules      = file.path(s70, "binding_classification_rules_plain_language.csv"),
  index_components = file.path(s70, "bop_pressure_index_components.csv"),
  benchmark        = file.path(s70, "historical_benchmark_ledger.csv"),
  year_accounting  = file.path(s70, "s70_year_accounting.csv"),
  dating_audit     = file.path(s70, "misalignment_dating_audit.csv"),
  s70_integrity    = file.path(s70, "s70_binding_state_integrity.csv")
)
missing <- inputs[!file.exists(inputs)]
if (length(missing)) {
  stop("missing report inputs:\n",
       paste(names(missing), missing, sep = ": ", collapse = "\n"))
}

rd <- function(nm) read.csv(inputs[[nm]], check.names = FALSE,
                            stringsAsFactors = FALSE)
panel <- rd("release"); rer_audit <- rd("rer_audit")
battery <- rd("battery"); verdict <- rd("verdict")
ladder <- rd("ladder"); order_audit <- rd("order_audit")
rank_grid <- rd("rank_grid"); beta <- rd("beta"); alpha <- rd("alpha")
gamma <- rd("gamma"); diagnostics <- rd("diagnostics")
promoted <- rd("promoted"); misalignment <- rd("misalignment")
trend_comparison <- rd("trend_comparison"); beta_boot <- rd("beta_bootstrap")
episode_panel <- rd("episode_panel"); episode_summary <- rd("episode_summary")
class_counts <- rd("class_counts"); class_rules <- rd("class_rules")
index_components <- rd("index_components"); benchmark <- rd("benchmark")
year_accounting <- rd("year_accounting"); dating_audit <- rd("dating_audit")
s60_integrity <- rd("s60_integrity"); s70_integrity <- rd("s70_integrity")

samples <- c("full_1920_2024", "pre_1920_1973", "post_1974_2024")
stopifnot(
  identical(range(panel$year), c(1920L, 2024L)),
  all(rer_audit$passed), all(s60_integrity$passed), all(s70_integrity$passed),
  setequal(promoted$sample, samples),
  all(dating_audit$exact_match[!is.na(dating_audit$exact_match)]),
  # v7 consumes no threshold-model ledger.
  !any(grepl("tvecm|threshold", tolower(inputs)))
)
expected_classes <- c("binding_confirmed", "imports_short_only",
                      "external_stress_only", "not_binding",
                      "no_estimate_for_year",
                      "external_stress_no_usable_model_signal",
                      "no_stress_no_usable_model_signal")
unknown <- setdiff(unique(class_counts$classification), expected_classes)
if (length(unknown)) {
  stop("unrecognised S70 classification(s): ", paste(unknown, collapse = ", "))
}

for (nm in setdiff(names(inputs), c("release", "provenance"))) {
  file.copy(inputs[[nm]], file.path(data_dir, basename(inputs[[nm]])),
            overwrite = TRUE)
}
file.copy(inputs[["provenance"]],
          file.path(data_dir, basename(inputs[["provenance"]])),
          overwrite = TRUE)

figure_sources <- c(
  rer_overlap = file.path(v1_root, "S20_RER_SPLICE", "fig_rer_overlap.pdf"),
  raw_system = file.path(v1_root, "S30_VECM",
                         "fig_raw_import_system_loess.pdf"),
  rank_grid = file.path(s60, "figures", "fig_rank_grid.pdf"),
  misalignment = file.path(s60, "figures", "fig_import_misalignment.pdf"),
  misalignment_usability = file.path(s70, "figures",
                                     "fig_import_misalignment_usability.pdf"),
  shortfall_vs_accounts = file.path(s70, "figures",
                                    "fig_shortfall_vs_accounts.pdf"),
  pressure_index = file.path(s70, "figures", "fig_bop_pressure_index.pdf")
)
stopifnot(all(file.exists(figure_sources)))
for (nm in names(figure_sources)) {
  file.copy(figure_sources[[nm]], file.path(figure_dir, paste0(nm, ".pdf")),
            overwrite = TRUE)
}

# ---------------------------------------------------------------------------
# Helpers.
# ---------------------------------------------------------------------------
fmt <- function(x, digits = 3) formatC(as.numeric(x), digits = digits,
                                       format = "f")
tex_escape <- function(x) {
  x <- gsub("\\\\", "\\\\textbackslash{}", as.character(x))
  x <- gsub("([#$%&_{}])", "\\\\\\1", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x
}
ps_tex <- function(s) c(full_1920_2024 = "1920--2024",
                        pre_1920_1973 = "1920--1973",
                        post_1974_2024 = "1974--2024")[s]
ps_md <- function(s) c(full_1920_2024 = "1920–2024",
                       pre_1920_1973 = "1920–1973",
                       post_1974_2024 = "1974–2024")[s]
plain_var <- c(
  log_imports = "real imports", log_K_ME_gross = "machinery stock",
  log_non_reinvested_surplus = "non-reinvested surplus",
  log_RER = "real exchange rate", wage_share = "wage share",
  log_K_NR_gross = "structures stock",
  d_log_K_ME_gross = "machinery growth"
)
plain_eq <- function(x) {
  v <- sub("\\.d$", "", x)
  paste0(ifelse(is.na(plain_var[v]), v, plain_var[v]))
}
plain_term <- function(x) {
  v <- sub("\\.(dl|l)[0-9]+$", "", x)
  lag <- sub(".*\\.dl", "", x)
  base <- ifelse(is.na(plain_var[v]), v, plain_var[v])
  ifelse(grepl("\\.dl", x), paste0("change in ", base, ", lag ", lag), base)
}
md_row <- function(...) paste0("| ", paste(c(...), collapse = " | "), " |")
rer_val <- function(check) {
  v <- rer_audit$value[rer_audit$check == check]
  if (!length(v)) NA_real_ else as.numeric(v[1])
}
pr <- function(s, col) promoted[[col]][promoted$sample == s][1]

# ---------------------------------------------------------------------------
# Narrative quantities.
# ---------------------------------------------------------------------------
prom_beta <- beta |> filter(model_id %in% promoted$model_id)
lr <- function(s, term) {
  v <- prom_beta$long_run_relation_coefficient[
    prom_beta$sample == s & grepl(paste0("^", term), prom_beta$term)]
  if (!length(v)) NA_real_ else v[1]
}
prom_alpha <- alpha |> filter(model_id %in% promoted$model_id)
al <- function(s, eq, col = "alpha") {
  v <- prom_alpha[[col]][prom_alpha$sample == s &
                           grepl(paste0("^", eq), prom_alpha$equation)]
  if (!length(v)) NA_real_ else v[1]
}
prom_gamma <- gamma |> filter(model_id %in% promoted$model_id)
gm <- function(s, term, col = "estimate") {
  v <- prom_gamma[[col]][prom_gamma$sample == s &
                           grepl("^log_imports", prom_gamma$equation) &
                           prom_gamma$term == term]
  if (!length(v)) NA_real_ else v[1]
}
cls_n <- function(s, cl) {
  v <- class_counts$years[class_counts$sample == s &
                            class_counts$classification == cl]
  if (!length(v)) 0L else sum(v)
}
bench_row <- function(s, col) benchmark[[col]][benchmark$sample == s][1]

mis_full <- misalignment |> filter(sample == "full_1920_2024")
mis_1961 <- episode_panel$import_misalignment[
  episode_panel$sample == "full_1920_2024" & episode_panel$year == 1961][1]

# Machinery battery evidence for the layered explanation of I(2).
bat_k <- battery |> filter(variable == "log_K_ME_gross",
                           sample == "full_1920_2024", deterministic == "drift")
bk <- function(d, col) {
  v <- bat_k[[col]][bat_k$difference_order == d]
  if (!length(v)) NA_real_ else v[1]
}
gk_pre <- mean(diff(panel$log_K_ME_gross[panel$year <= 1973]), na.rm = TRUE)
gk_post <- mean(diff(panel$log_K_ME_gross[panel$year >= 1974]), na.rm = TRUE)

# ---------------------------------------------------------------------------
# Table builders.
# ---------------------------------------------------------------------------
verdict_tbl <- verdict |>
  filter(variable %in% c("log_imports", "log_K_ME_gross", "log_RER",
                         "log_non_reinvested_surplus", "wage_share")) |>
  arrange(match(sample, samples), variable) |>
  mutate(plain = plain_var[variable])

battery_main <- battery |>
  filter(variable %in% c("log_imports", "log_K_ME_gross", "log_RER",
                         "log_non_reinvested_surplus", "wage_share"),
         deterministic == "drift") |>
  arrange(match(sample, samples), variable, difference_order)

rank_prom <- diagnostics |>
  filter(specification == "M3_plus_rer", status == "estimated") |>
  arrange(match(sample, samples), deterministic, lag_order)

ladder_ranks <- diagnostics |>
  filter(status == "estimated", deterministic == "const", lag_order == 2) |>
  arrange(match(sample, samples), specification)

rowbuild <- function(df, f, sep = "\n") paste(
  vapply(seq_len(nrow(df)), function(i) f(df[i, ]), character(1)),
  collapse = sep)

# Integration verdict. "classification" carries raw stage labels (eg.
# unresolved_by_d3) that are not meant as reader-facing prose, so they get the
# same underscore-to-space cleanup as disposition.
verdict_md <- rowbuild(verdict_tbl, function(z) md_row(
  ps_md(z$sample), z$plain, paste0("`", z$variable, "`"),
  gsub("_", " ", z$classification), gsub("_", " ", z$disposition)))
verdict_tex <- rowbuild(verdict_tbl, function(z) paste0(
  ps_tex(z$sample), " & ", tex_escape(z$plain), " & ",
  tex_escape(gsub("_", " ", z$classification)), " & ",
  tex_escape(gsub("_", " ", z$disposition)), " \\\\"))

# Battery (drift, main text)
battery_md <- rowbuild(battery_main, function(z) md_row(
  ps_md(z$sample), plain_var[z$variable], z$difference_order,
  fmt(z$adf_statistic, 2), fmt(z$adf_critical_5, 2),
  fmt(z$pp_statistic, 2), fmt(z$kpss_statistic, 3), fmt(z$kpss_critical_5, 3),
  ifelse(z$path_pass, "stationary", "not stationary")))
battery_tex <- rowbuild(battery_main, function(z) paste0(
  ps_tex(z$sample), " & ", tex_escape(plain_var[z$variable]), " & ",
  z$difference_order, " & ", fmt(z$adf_statistic, 2), " & ",
  fmt(z$adf_critical_5, 2), " & ", fmt(z$pp_statistic, 2), " & ",
  fmt(z$kpss_statistic, 3), " & ", fmt(z$kpss_critical_5, 3), " & ",
  ifelse(z$path_pass, "stationary", "not stationary"), " \\\\"))

# Ladder
ladder_md <- rowbuild(ladder, function(z) md_row(
  z$specification, paste(plain_var[strsplit(z$state_variables, ";")[[1]]],
                         collapse = ", "), z$role))
ladder_tex <- rowbuild(ladder, function(z) paste0(
  tex_escape(sub("_.*", "", z$specification)), " & ",
  tex_escape(paste(plain_var[strsplit(z$state_variables, ";")[[1]]],
                   collapse = ", ")), " & ", tex_escape(z$role), " \\\\"))

# Rank across ladder rungs
ladder_rank_md <- rowbuild(ladder_ranks, function(z) md_row(
  ps_md(z$sample), sub("_.*", "", z$specification), z$selected_rank_5,
  ifelse(is.na(z$serial_portmanteau_p), "n/a", fmt(z$serial_portmanteau_p, 3)),
  ifelse(z$balanced_order, "yes", "no")))
ladder_rank_tex <- rowbuild(ladder_ranks, function(z) paste0(
  ps_tex(z$sample), " & ", tex_escape(sub("_.*", "", z$specification)), " & ",
  z$selected_rank_5, " & ",
  ifelse(is.na(z$serial_portmanteau_p), "n/a", fmt(z$serial_portmanteau_p, 3)),
  " & ", ifelse(z$balanced_order, "yes", "no"), " \\\\"))

# Rank for the headline specification across deterministic and lag
rank_prom_md <- rowbuild(rank_prom, function(z) md_row(
  ps_md(z$sample), z$deterministic, z$lag_order, z$selected_rank_5,
  ifelse(is.na(z$serial_portmanteau_p), "n/a", fmt(z$serial_portmanteau_p, 3)),
  ifelse(is.na(z$max_modulus_beyond_unit_roots), "n/a",
         fmt(z$max_modulus_beyond_unit_roots, 3))))
rank_prom_tex <- rowbuild(rank_prom, function(z) paste0(
  ps_tex(z$sample), " & ", z$deterministic, " & ", z$lag_order, " & ",
  z$selected_rank_5, " & ",
  ifelse(is.na(z$serial_portmanteau_p), "n/a", fmt(z$serial_portmanteau_p, 3)),
  " & ", ifelse(is.na(z$max_modulus_beyond_unit_roots), "n/a",
                fmt(z$max_modulus_beyond_unit_roots, 3)), " \\\\"))

# Cointegrating vectors, promoted models
beta_state <- prom_beta |>
  filter(!grepl("constant|trend", term)) |>
  mutate(v = sub("\\.l1$", "", term)) |>
  arrange(match(sample, samples))
beta_md <- rowbuild(beta_state, function(z) md_row(
  ps_md(z$sample), plain_var[z$v], fmt(z$long_run_relation_coefficient, 3),
  fmt(z$import_normalization_share, 3),
  ifelse(z$normalization_reliable, "yes", "no")))
beta_tex <- rowbuild(beta_state, function(z) paste0(
  ps_tex(z$sample), " & ", tex_escape(plain_var[z$v]), " & ",
  fmt(z$long_run_relation_coefficient, 3), " & ",
  fmt(z$import_normalization_share, 3), " & ",
  ifelse(z$normalization_reliable, "yes", "no"), " \\\\"))

# Adjustment speeds
alpha_tbl <- prom_alpha |> arrange(match(sample, samples), equation)
alpha_md <- rowbuild(alpha_tbl, function(z) md_row(
  ps_md(z$sample), plain_eq(z$equation), fmt(z$alpha, 3),
  fmt(z$t_statistic, 2), fmt(z$p_value, 3),
  ifelse(z$adjusts_to_disequilibrium_5, "adjusts", "does not adjust")))
alpha_tex <- rowbuild(alpha_tbl, function(z) paste0(
  ps_tex(z$sample), " & ", tex_escape(plain_eq(z$equation)), " & ",
  fmt(z$alpha, 3), " & ", fmt(z$t_statistic, 2), " & ", fmt(z$p_value, 3),
  " & ", ifelse(z$adjusts_to_disequilibrium_5, "adjusts", "does not adjust"),
  " \\\\"))

# Short-run structure, import equation
gamma_imp <- prom_gamma |>
  filter(grepl("^log_imports", equation)) |>
  arrange(match(sample, samples), term)
gamma_md <- rowbuild(gamma_imp, function(z) md_row(
  ps_md(z$sample), plain_term(z$term), fmt(z$estimate, 3),
  fmt(z$t_statistic, 2), fmt(z$p_value, 3),
  ifelse(z$significant_5, "yes", "no")))
gamma_tex <- rowbuild(gamma_imp, function(z) paste0(
  ps_tex(z$sample), " & ", tex_escape(plain_term(z$term)), " & ",
  fmt(z$estimate, 3), " & ", fmt(z$t_statistic, 2), " & ",
  fmt(z$p_value, 3), " & ", ifelse(z$significant_5, "yes", "no"), " \\\\"))

# Class counts
cls_tbl <- bind_rows(lapply(samples, function(s) tibble(
  sample = s,
  binding = cls_n(s, "binding_confirmed"),
  short_only = cls_n(s, "imports_short_only"),
  stress_only = cls_n(s, "external_stress_only") +
    cls_n(s, "external_stress_no_usable_model_signal"),
  neither = cls_n(s, "not_binding") +
    cls_n(s, "no_stress_no_usable_model_signal"),
  total = year_accounting$years_in_sample[year_accounting$sample == s])))
cls_md <- rowbuild(cls_tbl, function(z) md_row(
  ps_md(z$sample), z$binding, z$short_only, z$stress_only, z$neither, z$total))
cls_tex <- rowbuild(cls_tbl, function(z) paste0(
  ps_tex(z$sample), " & ", z$binding, " & ", z$short_only, " & ",
  z$stress_only, " & ", z$neither, " & ", z$total, " \\\\"))

# Episodes
ep_md <- rowbuild(episode_summary, function(z) md_row(
  ps_md(z$sample),
  ifelse(z$start_year == z$end_year, z$start_year,
         paste0(z$start_year, "–", z$end_year)),
  z$duration_years, z$peak_year, fmt(z$peak_pressure_index, 3)))
ep_tex <- rowbuild(episode_summary, function(z) paste0(
  ps_tex(z$sample), " & ",
  ifelse(z$start_year == z$end_year, z$start_year,
         paste0(z$start_year, "--", z$end_year)), " & ",
  z$duration_years, " & ", z$peak_year, " & ",
  fmt(z$peak_pressure_index, 3), " \\\\"))

# Trend comparison
tc_md <- rowbuild(trend_comparison, function(z) md_row(
  ps_md(z$sample), fmt(z$vecm_long_run_machinery_coefficient, 3),
  fmt(z$ols_level_slope, 3), fmt(z$growth_ratio, 3)))
tc_tex <- rowbuild(trend_comparison, function(z) paste0(
  ps_tex(z$sample), " & ", fmt(z$vecm_long_run_machinery_coefficient, 3),
  " & ", fmt(z$ols_level_slope, 3), " & ", fmt(z$growth_ratio, 3), " \\\\"))

# Plain-language rules
rules_md <- rowbuild(class_rules, function(z) md_row(
  gsub("_", " ", z$classification), z$plain_language_meaning))
rules_tex <- rowbuild(class_rules, function(z) paste0(
  tex_escape(gsub("_", " ", z$classification)), " & ",
  tex_escape(z$plain_language_meaning), " \\\\ \\addlinespace"))

# Appendix: full battery
battery_app <- battery |> arrange(match(sample, samples), variable,
                                  difference_order, deterministic)
battery_app_tex <- rowbuild(battery_app, function(z) paste0(
  ps_tex(z$sample), " & ",
  tex_escape(ifelse(is.na(plain_var[z$variable]), z$variable,
                    plain_var[z$variable])), " & ",
  z$difference_order, " & ", z$deterministic, " & ", z$n, " & ",
  fmt(z$adf_statistic, 2), " & ", fmt(z$adf_critical_5, 2), " & ",
  fmt(z$pp_statistic, 2), " & ", fmt(z$kpss_statistic, 3), " & ",
  fmt(z$kpss_critical_5, 3), " \\\\"))
rank_app_tex <- rowbuild(
  diagnostics |> filter(status == "estimated") |>
    arrange(match(sample, samples), specification, deterministic, lag_order),
  function(z) paste0(
    ps_tex(z$sample), " & ", tex_escape(sub("_.*", "", z$specification)),
    " & ", z$deterministic, " & ", z$lag_order, " & ", z$selected_rank_5,
    " & ", ifelse(is.na(z$serial_portmanteau_p), "n/a",
                  fmt(z$serial_portmanteau_p, 3)), " \\\\"))

source_note <- paste0(
  "Every number is copied from a completed stage ledger; the builder performs ",
  "no estimation.")

# ---------------------------------------------------------------------------
# Markdown.
# ---------------------------------------------------------------------------
md <- c(
"# When Did Chile's Balance-of-Payments Constraint Bind?",
"",
"## An import-requirement account of machinery accumulation and external adjustment, 1920–2024",
"",
"### Abstract",
"",
paste0("Chile's imports are observed. The level of imports the country's ",
"productive structure required is not: it has to be estimated. This report ",
"estimates that requirement as a long-run relation between real imports, the ",
"gross machinery stock, non-reinvested surplus and the real exchange rate, and ",
"asks whether the gap between actual and required imports dates the years when ",
"the balance-of-payments constraint bound. A single long-run relation is found ",
"in all three samples. It is usable in two of them. Over 1920–2024 imports ",
"close ", fmt(abs(al("full_1920_2024", "log_imports")) * 100, 0),
"% of the gap each year and after 1974 they close ",
fmt(abs(al("post_1974_2024", "log_imports")) * 100, 0),
"%, so the gap measures something imports respond to. Before 1973 they do not ",
"respond at all, and the relation carries no import requirement in that ",
"period. Where the measure works it dates ", cls_n("full_1920_2024",
"binding_confirmed"), " binding years over the century, concentrated in the ",
"1930s, the 1950s, and the two post-reform adjustments of 1975–77 and 1983–86. ",
"It does not date 1961, the one crisis independently documented, because in ",
"1961 imports stood above their required level rather than below it. The ",
"measure identifies the compression that follows an external crisis, not the ",
"over-absorption that precedes one."),
"",
"**Keywords:** Chile; balance of payments; imports; machinery accumulation; real exchange rate; cointegration; error correction; Kaldor; Thirlwall",
"",
"### Resumen",
"",
paste0("Las importaciones chilenas se observan; el nivel de importaciones que la ",
"estructura productiva requería, no. Este informe estima ese requerimiento como ",
"una relación de largo plazo entre importaciones reales, stock bruto de ",
"maquinaria, excedente no reinvertido y tipo de cambio real, y pregunta si la ",
"brecha entre importaciones efectivas y requeridas fecha los años en que la ",
"restricción externa fue vinculante. Se encuentra una relación de largo plazo ",
"en las tres muestras, utilizable en dos. Antes de 1973 las importaciones no ",
"responden a la relación y la brecha no mide un requerimiento. Donde el ",
"indicador funciona, fecha ", cls_n("full_1920_2024", "binding_confirmed"),
" años vinculantes, concentrados en los años treinta, los cincuenta y los dos ",
"ajustes posreforma de 1975–77 y 1983–86. No fecha 1961: ese año las ",
"importaciones estuvieron por encima de su nivel requerido, no por debajo. El ",
"indicador identifica la compresión que sigue a una crisis externa, no el ",
"exceso de absorción que la precede."),
"",
"## 1. The question, and what has to be estimated to answer it",
"",
paste0("Chile's industrialization ran on imported machinery. Building productive ",
"capacity meant buying capital goods abroad, and paying for them depended on ",
"export earnings and on access to external finance. When those ran short, the ",
"imports that carried the accumulation had to be cut. The question is when that ",
"happened."),
"",
paste0("Answering it requires distinguishing two things that are easy to ",
"conflate. Actual imports are recorded in the national accounts every year. The ",
"level of imports the productive structure *required* is not recorded anywhere; ",
"it is a relation that has to be estimated. Only once that required level exists ",
"can a shortfall be defined, and only a shortfall can indicate that the external ",
"constraint was doing the cutting."),
"",
paste0("The required level is estimated as a long-run relation among four ",
"variables, all in logs. Real imports and the gross machinery stock carry ",
"Kaldor's mechanism: expanding the productive apparatus draws in capital goods. ",
"Non-reinvested surplus stands for the surplus not internally recapitalized, ",
"which has to be financed or spent abroad. The real exchange rate enters as the ",
"relative price at which foreign goods are bought. Writing imports as `m`, the ",
"machinery stock as `k`, non-reinvested surplus as `s` and the real exchange ",
"rate as `r`, the relation estimated is"),
"",
"    m = β₁ k + β₂ s + β₃ r + constant",
"",
paste0("and the gap between actual and required imports in a given year is ",
"`m − (β₁k + β₂s + β₃r + constant)`. A negative gap means imports sat below the ",
"level the relation implies. In the surplus approach β₁ is the foreign-exchange ",
"cost of the intensive margin of accumulation: how much import capacity a ",
"larger machinery stock commits the economy to, conditional on distribution and ",
"the relative price of foreign goods."),
"",
paste0("Throughout, a rise in the real exchange rate means real depreciation. ",
"The convention is confirmed in the data: the largest annual increases fall in ",
"1932, 1956–57, 1974–75 and 1983–85, each a documented Chilean devaluation."),
"",
"## 2. Data",
"",
paste0("Every estimate uses the frozen release `chile_bop_binding_v1_1`: 105 ",
"annual observations, 1920 to 2024, with 54 years before 1974 and 51 after. No ",
"stage re-queries a source or rebuilds a variable. Real series are in 2003 ",
"Chilean pesos, matching the GDP source so no rebasing is applied. The real ",
"exchange rate splices a ClioLab index through 2010 to the Banco Central series ",
"from 2011, rebased to the 2003 scale. Over the 1986–2010 overlap the two ",
"correlate at ", fmt(rer_val("overlap_level_correlation"), 3), " in levels and ",
fmt(rer_val("overlap_growth_correlation"), 3), " in growth rates, with a ",
"median absolute level gap of ", fmt(rer_val("median_absolute_level_gap"), 2),
"% and a 2011 boundary change of ", fmt(rer_val("splice_boundary_growth"), 3),
" log points. The splice passes its declared audit and is not seamless; the ",
"measured gap is a limitation, not a rounding detail."),
"",
"![The two real exchange-rate sources over their overlap](figures/rer_overlap.pdf)",
"",
paste0("The figure shows the two sources moving together over 1986–2010 while ",
"differing in level, which is why the splice is audited rather than assumed."),
"",
"![The four series with local trend lines](figures/raw_system.pdf)",
"",
paste0("The figure shows all four series before any model is imposed: imports ",
"and the machinery stock rising together across the century, with the two ",
"post-1974 accelerations visible without estimation."),
"",
"## 3. How persistent is each series?",
"",
paste0("A long-run relation between levels only makes sense if the levels ",
"themselves wander in a particular way. A series is called integrated of order ",
"one, written I(1), when its level wanders without returning to any fixed value ",
"but its year-to-year change does settle down. Cointegration analysis is built ",
"for exactly that case. So each variable is tested before any system is ",
"estimated, and the tests are run on the level, then on the change, then on the ",
"change in the change, stopping at the first order where the series settles."),
"",
paste0("Three tests are used because they ask the question from opposite ",
"directions. The augmented Dickey–Fuller and Phillips–Perron tests start from ",
"the assumption that the series wanders and look for evidence against it, so a ",
"statistic more negative than the critical value is evidence of stationarity. ",
"The KPSS test starts from the opposite assumption, that the series is stable, ",
"so a statistic *above* its critical value is evidence of wandering. Agreement ",
"across all three is what makes a verdict safe; disagreement is reported as ",
"disagreement."),
"",
"**Table 1 — Test statistics against 5% critical values (drift specification)**",
"",
md_row("Sample", "Variable", "Differences taken", "ADF", "ADF 5%", "PP",
       "KPSS", "KPSS 5%", "Verdict"),
md_row("---", "---", "---", "---", "---", "---", "---", "---", "---"),
battery_md,
"",
paste0("**Table 2 — Order of integration and what follows for each variable**"),
"",
md_row("Sample", "Variable", "Series", "Order", "Disposition"),
md_row("---", "---", "---", "---", "---"),
verdict_md,
"",
paste0("Read variable by variable. **Real imports** settle after one difference ",
"in every sample: the level wanders, the growth rate does not. That is the ",
"textbook I(1) case and imports enter the long-run relation without ",
"qualification. **The real exchange rate** behaves the same way in all three ",
"samples. **Non-reinvested surplus** is I(1) over the century and after 1974, ",
"but before 1973 it is already stationary in levels, which means that in the ",
"pre-1973 sample it contributes no long-run wandering for the others to be tied ",
"to. **The wage share** is stationary before 1974 and after 1974 and ",
"unresolved over the full span, so it never enters as a long-run variable and ",
"appears only in a robustness specification. **The machinery stock** is the ",
"problem, and it needs its own section."),
"",
paste0("One cell is genuinely inconclusive and is not smoothed over. For the ",
"change in the machinery stock over the full sample under a trend ",
"specification, KPSS returns ",
fmt(battery$kpss_statistic[battery$variable == "log_K_ME_gross" &
  battery$sample == "full_1920_2024" & battery$difference_order == 1 &
  battery$deterministic == "trend"][1], 3), " against a 5% value of ",
fmt(battery$kpss_critical_5[battery$variable == "log_K_ME_gross" &
  battery$sample == "full_1920_2024" & battery$difference_order == 1 &
  battery$deterministic == "trend"][1], 3),
", which does not reject stability, while ADF returns ",
fmt(battery$adf_statistic[battery$variable == "log_K_ME_gross" &
  battery$sample == "full_1920_2024" & battery$difference_order == 1 &
  battery$deterministic == "trend"][1], 2), " against ",
fmt(battery$adf_critical_5[battery$variable == "log_K_ME_gross" &
  battery$sample == "full_1920_2024" & battery$difference_order == 1 &
  battery$deterministic == "trend"][1], 2),
", which does not reject wandering. The two tests point opposite ways once a ",
"trend is allowed. The verdict rests on the drift specification, where all ",
"three tests agree, and the disagreement is recorded rather than resolved by ",
"preference."),
"",
"## 4. Why a machinery stock can need two differences",
"",
paste0("The machinery stock needs two differences before it settles, in every ",
"sample. That is unusual enough to explain from the ground up, because it is the ",
"single biggest constraint on everything that follows."),
"",
"### Start with what a capital stock is",
"",
paste0("A capital stock is a running total. This year's machinery is last year's ",
"machinery, minus what wore out, plus what was newly installed:"),
"",
"    K(t) = (1 − z)·K(t−1) + I(t)",
"",
paste0("where `I(t)` is investment in machinery during the year and `z` is the ",
"fraction of the existing stock retired. Nothing here is a modelling choice; it ",
"is how the stock is built from investment flows."),
"",
paste0("Now ask what happens if investment itself has no level it returns to. ",
"Suppose investment drifts upward for a couple of decades, then settles at a ",
"higher pace, then drifts again — never reverting to a long-run average. Adding ",
"up a series that wanders gives a total that wanders more. And because `z` is ",
"small for machinery, very little of the past is discarded each year, so almost ",
"the whole history stays in the total. The running total inherits the wandering ",
"of the flow and adds its own on top."),
"",
"### What the two differences mean",
"",
paste0("Saying the machinery stock is I(2) says exactly this: not only does the ",
"*level* of the stock fail to return to any fixed value, its *growth rate* ",
"fails to as well. The rate of machinery accumulation itself moves to a new ",
"level and stays there. Only the change in the growth rate settles down."),
"",
"### What the tests show",
"",
paste0("The battery in Table 1 shows the pattern directly for the full sample. ",
"In levels, ADF returns ", fmt(bk(0, "adf_statistic"), 2), " against a 5% value ",
"of ", fmt(bk(0, "adf_critical_5"), 2), " and KPSS returns ",
fmt(bk(0, "kpss_statistic"), 3), " against ", fmt(bk(0, "kpss_critical_5"), 3),
": the level wanders, and both tests agree. After one difference — that is, ",
"looking at the growth rate of the stock rather than its level — ADF still ",
"returns only ", fmt(bk(1, "adf_statistic"), 2), " against ",
fmt(bk(1, "adf_critical_5"), 2), " and KPSS still returns ",
fmt(bk(1, "kpss_statistic"), 3), " against ", fmt(bk(1, "kpss_critical_5"), 3),
". The growth rate is no more settled than the level was. Only after a second ",
"difference does the picture change decisively: ADF ", fmt(bk(2, "adf_statistic"), 2),
", Phillips–Perron ", fmt(bk(2, "pp_statistic"), 2), ", KPSS ",
fmt(bk(2, "kpss_statistic"), 3), " — all three tests agree on stationarity."),
"",
"### What it costs",
"",
paste0("Standard cointegration analysis assumes every variable in the long-run ",
"relation needs the same single difference to settle. Putting an I(2) variable ",
"alongside I(1) variables makes the relation *unbalanced*: the two sides wander ",
"at different orders, and a coefficient estimated on them is not a long-run ",
"elasticity in the usual sense. The honest options are to use machinery growth ",
"instead of the stock, to move to methods built for I(2) systems, or to keep the ",
"levels specification and report the limitation. This report keeps the levels ",
"specification, because the machinery stock is the variable the mechanism is ",
"about, and it carries the limitation forward explicitly. A differenced-machinery ",
"specification is estimated alongside it as a check."),
"",
"### What it means about Chile",
"",
paste0("The statistic is describing something concrete. Chile's machinery stock ",
"did not merely grow across the century — the pace at which it grew shifted and ",
"stayed shifted, averaging ", fmt(gk_pre * 100, 1), "% a year before 1973 and ",
fmt(gk_post * 100, 1), "% after. A series whose growth rate steps up to a new ",
"level and remains there is precisely what a second unit root describes. The ",
"awkward statistical property and the post-reform transformation of Chilean ",
"accumulation are the same fact, seen from two directions."),
"",
"## 5. How many long-run relations are there?",
"",
paste0("With the variables classified, the next question is how many independent ",
"long-run relations tie them together. The answer is the *rank*: zero means no ",
"relation and the variables drift apart permanently; one means a single relation ",
"holds them together; more than one means several do. Rank is estimated with the ",
"Johansen trace test, which asks in sequence whether the number of relations is ",
"zero, then at most one, and so on, stopping at the first hypothesis it cannot ",
"reject."),
"",
paste0("Rather than test one preferred model, the relation is built up one ",
"variable at a time, so the evidence can be read as a sequence."),
"",
"**Table 3 — The specifications, from the mechanism core outward**",
"",
md_row("Rung", "Variables", "What it adds"),
md_row("---", "---", "---"),
ladder_md,
"",
"**Table 4 — Number of long-run relations found at each rung (constant, two lags)**",
"",
md_row("Sample", "Rung", "Relations found", "Residual-correlation p",
       "All variables same order?"),
md_row("---", "---", "---", "---", "---"),
ladder_rank_md,
"",
paste0("The sequence tells a clear story. Over the full century and after 1974, ",
"a single relation appears as soon as imports and machinery are put together, ",
"and it survives every addition. Before 1973 the two-variable and ",
"three-variable systems find nothing: no relation ties imports to machinery, or ",
"to machinery and surplus, in the pre-reform period. A relation appears only ",
"once the real exchange rate is added. That is the first sign that the ",
"pre-1973 system behaves differently, and Section 7 shows why it matters."),
"",
"**Table 5 — The four-variable relation across deterministic terms and lags**",
"",
md_row("Sample", "Deterministic", "Lags", "Relations found",
       "Residual-correlation p", "Largest non-unit root"),
md_row("---", "---", "---", "---", "---", "---"),
rank_prom_md,
"",
paste0("The specification carried forward in each sample is the one that finds ",
"exactly one relation, leaves no residual correlation at 5%, and has stable ",
"dynamics. Requiring exactly one matters: when the test finds two, the single ",
"relation extracted from a two-dimensional space is one arbitrary combination ",
"of the two and cannot be read as *the* import requirement. The last column is ",
"the stability check. A system tied together by one relation among four ",
"variables must carry three permanent trends, so three roots sit on the unit ",
"circle by construction; the question is whether the remaining roots lie inside ",
"it. They do, between 0.68 and 0.84, so the dynamics are stable."),
"",
"![Trace statistics across every rung and sample](figures/rank_grid.pdf)",
"",
paste0("The figure shows each trace sequence against its 5% critical value: ",
"where the solid line starts above the dashed one and then crosses below, that ",
"crossing point is the number of relations."),
"",
paste0("The promoted specification is the four-variable relation in all three ",
"samples, with a constant, at three lags over the full century and two lags in ",
"each subsample."),
"",
"## 6. What the long-run relation says",
"",
"**Table 6 — The estimated import requirement**",
"",
md_row("Sample", "Variable", "Coefficient", "Import share of the relation",
       "Readable as an elasticity?"),
md_row("---", "---", "---", "---", "---"),
beta_md,
"",
paste0("Over the full century the required import level rises by ",
fmt(lr("full_1920_2024", "log_K_ME_gross"), 2),
"% for every 1% increase in the machinery stock, and after 1974 by ",
fmt(lr("post_1974_2024", "log_K_ME_gross"), 2),
"%. Read through the surplus approach, this is the foreign-exchange commitment ",
"attached to the intensive margin of accumulation: enlarging the machinery ",
"stock obliges the economy to sustain a proportionally higher level of imports, ",
"and the coefficient measures how much."),
"",
paste0("The pre-1973 column cannot be read this way, and the fourth column of ",
"Table 6 says why. Normalizing the relation on imports means dividing every ",
"coefficient by the weight imports carry in it. Before 1973 imports carry only ",
fmt(pr("pre_1920_1973", "import_normalization_share"), 3),
" of that weight, so the division is by something close to zero and the ",
"resulting numbers — a machinery coefficient above eleven, a real-exchange-rate ",
"coefficient near twenty — are an artifact of the arithmetic, not elasticities. ",
"The relation found in the pre-1973 sample is not an import relation. Section 7 ",
"confirms this from an entirely separate direction."),
"",
paste0("The real exchange rate enters the long-run relation with a **positive** ",
"sign: ", fmt(lr("full_1920_2024", "log_RER"), 2), " over the century and ",
fmt(lr("post_1974_2024", "log_RER"), 2), " after 1974. Since a rise means ",
"depreciation, this says a more depreciated currency goes with *higher* required ",
"imports, which is the opposite of a relative-price brake. The pattern is in the ",
"raw data, not an artifact of the system: over 1920–2024 the correlation between ",
"the log real exchange rate and the goods-import share of GDP is ",
fmt(cor(panel$log_RER, panel$goods_imports_gdp, use = "complete.obs"), 2),
". The reading that fits Chilean structure is that capital and intermediate ",
"imports are hard to substitute domestically, so depreciation raises their peso ",
"cost without displacing them, while depreciation episodes coincide with the ",
"external pressure that accompanies accumulation drives. Section 8 shows the ",
"real exchange rate doing something quite different within the year."),
"",
"**Table 7 — The machinery coefficient beside two simpler comparisons**",
"",
md_row("Sample", "Long-run coefficient", "Level regression slope",
       "Ratio of average growth rates"),
md_row("---", "---", "---", "---"),
tc_md,
"",
paste0("The comparison matters because two series that both trend upward will ",
"appear related whether or not anything ties them together. If the estimated ",
"coefficient simply reproduced the ratio of average growth rates, it would be ",
"measuring shared drift. It does not: over the full century the long-run ",
"coefficient is ", fmt(lr("full_1920_2024", "log_K_ME_gross"), 2),
" while the growth ratio is ",
fmt(trend_comparison$growth_ratio[trend_comparison$sample == "full_1920_2024"], 2),
" and the level slope is ",
fmt(trend_comparison$ols_level_slope[trend_comparison$sample == "full_1920_2024"], 2),
". The system estimate is well below both, which is what conditioning on ",
"surplus and the real exchange rate does: part of what a bare comparison ",
"attributes to machinery belongs to the other two."),
"",
"## 7. Which variable does the adjusting, and which does not",
"",
paste0("A long-run relation on its own says nothing about who moves when the ",
"relation is violated. That is the adjustment coefficient: for each variable, ",
"the fraction of last year's gap closed this year. A coefficient ",
"indistinguishable from zero says that variable ignores the gap entirely, which ",
"in this literature is called weak exogeneity. For the question at hand this is ",
"the decisive test, because a gap only measures an import requirement if ",
"imports are what responds to it."),
"",
"**Table 8 — Adjustment to the long-run gap, by equation**",
"",
md_row("Sample", "Equation for", "Coefficient", "t", "p", "Responds to the gap?"),
md_row("---", "---", "---", "---", "---", "---"),
alpha_md,
"",
paste0("Over the full century imports carry the adjustment, closing ",
fmt(abs(al("full_1920_2024", "log_imports")) * 100, 0),
"% of the gap each year with a t ratio of ",
fmt(al("full_1920_2024", "log_imports", "t_statistic"), 2),
". After 1974 the response is far faster, ",
fmt(abs(al("post_1974_2024", "log_imports")) * 100, 0),
"% within the year, and imports are the only variable that responds ",
"significantly: the machinery stock, surplus and the real exchange rate all ",
"ignore the gap. That is the configuration the question needs. Imports absorb ",
"the disequilibrium and the other three are free to push it around, so the gap ",
"is a genuine import requirement and the speed at which imports close it ",
"measures how hard the requirement bites."),
"",
paste0("Before 1973 the picture inverts. Imports respond by ",
fmt(al("pre_1920_1973", "log_imports"), 3), " with a t ratio of ",
fmt(al("pre_1920_1973", "log_imports", "t_statistic"), 2), " and a p value of ",
fmt(al("pre_1920_1973", "log_imports", "p_value"), 3),
" — indistinguishable from no response at all. The machinery stock is what ",
"adjusts, at a t ratio of ",
fmt(al("pre_1920_1973", "log_K_ME_gross", "t_statistic"), 2),
". So the relation that exists in the pre-1973 sample is one that machinery ",
"closes, not one that imports close. This is the same conclusion the ",
"normalization diagnostic reached in Section 6, arrived at independently: ",
"before 1973 there is no import requirement for imports to fall short of. Under ",
"import-substituting industrialization, imports of capital goods were ",
"administratively allocated through licensing and multiple exchange rates rather ",
"than adjusted to a price-and-quantity equilibrium, and a relation imports do ",
"not error-correct is what that institutional arrangement looks like in the ",
"time series."),
"",
"![The gap series, with the pre-1973 sample marked unusable](figures/misalignment_usability.pdf)",
"",
paste0("The figure shows the gap for each sample, greyed where imports do not ",
"respond to it: the pre-1973 line is drawn but carries no requirement reading."),
"",
"## 8. What moves imports within the year",
"",
"**Table 9 — Short-run structure of the import equation**",
"",
md_row("Sample", "Term", "Coefficient", "t", "p", "Significant at 5%?"),
md_row("---", "---", "---", "---", "---", "---"),
gamma_md,
"",
paste0("Over the full century imports have their own momentum: last year's ",
"import growth carries ", fmt(gm("full_1920_2024", "log_imports.dl1"), 2),
" into this year's, the most significant short-run term in the equation. After ",
"1974 that momentum disappears — the own-lag coefficient falls to ",
fmt(gm("post_1974_2024", "log_imports.dl1"), 3),
" and is indistinguishable from zero — and machinery growth takes over, at ",
fmt(gm("post_1974_2024", "log_K_ME_gross.dl1"), 2), " with a t ratio of ",
fmt(gm("post_1974_2024", "log_K_ME_gross.dl1", "t_statistic"), 2),
", alongside non-reinvested surplus at ",
fmt(gm("post_1974_2024", "log_non_reinvested_surplus.dl1"), 2),
". Post-reform import growth is driven by what is being installed and what ",
"surplus is available to finance it, not by its own past."),
"",
paste0("The real exchange rate is where short and long run part company. In the ",
"long-run relation its coefficient is positive. Within the year it enters ",
"negatively in every sample — ", fmt(gm("full_1920_2024", "log_RER.dl1"), 3),
" over the century, with a p value of ",
fmt(gm("full_1920_2024", "log_RER.dl1", "p_value"), 3), ", and ",
fmt(gm("post_1974_2024", "log_RER.dl1"), 3),
" after 1974 — so a depreciation does compress imports in the short term, ",
"though only marginally significantly. The relative price works as a brake on ",
"impact and as a co-mover over the long haul. Reporting only one of the two ",
"would misdescribe what the exchange rate does in this system."),
"",
paste0("Before 1973 nothing but the own lag matters: machinery growth, surplus ",
"and the real exchange rate are all insignificant in the import equation. The ",
"disconnection found in Section 7 shows up here too — pre-1973 imports move ",
"largely on their own history."),
"",
"## 9. The gap beside the external accounts",
"",
paste0("The gap is a model quantity, so on its own it cannot establish that ",
"the external constraint was binding: a shortfall relative to an estimated ",
"requirement could reflect a mis-specified requirement. Independent evidence ",
"is needed, and it comes from the external accounts, which are observed rather ",
"than estimated: the current-account balance, the goods balance, the change in ",
"manufactured imports, and a financing-compression indicator."),
"",
paste0("A year is counted as binding only when two independent things agree — ",
"imports below the requirement the relation implies, *and* at least one ",
"external-account indicator showing stress, meaning a current-account or goods ",
"deficit of 3% of GDP or more, a fall in manufactured imports of at least 3 ",
"percentage points of GDP, or the financing indicator triggering. Years that ",
"satisfy only one of the two are recorded as satisfying only one. Nothing is ",
"ever counted as binding on the strength of the model alone."),
"",
"**Table 10 — What each category means**",
"",
md_row("Category", "Meaning"),
md_row("---", "---"),
rules_md,
"",
"![The gap beside each external-account indicator](figures/shortfall_vs_accounts.pdf)",
"",
paste0("The figure puts the import shortfall and the three account-based ",
"pressure measures on one standardized scale: they rise together in the 1930s, ",
"the mid-1950s, and the mid-1970s and mid-1980s, and diverge in the early 1960s."),
"",
"**Table 11 — Years by category**",
"",
md_row("Sample", "Binding", "Import shortfall only", "External stress only",
       "Neither", "Total"),
md_row("---", "---", "---", "---", "---", "---"),
cls_md,
"",
paste0("Every year of the release is accounted for in each sample: ",
paste(year_accounting$years_in_sample[match(samples, year_accounting$sample)],
      collapse = ", "), " years respectively. The pre-1973 row is not a finding ",
"about Chile. It records that in that sample the model supplies no usable import ",
"signal, so the confirmation rule — which requires both kinds of evidence — can ",
"never be met. Thirty of those years show external stress in the accounts; what ",
"is missing is a requirement measure to pair it with, and the report does not ",
"convert that absence into a claim that the constraint never bound before 1973."),
"",
"**Table 12 — Binding episodes**",
"",
md_row("Sample", "Years", "Length", "Peak year", "Peak pressure"),
md_row("---", "---", "---", "---", "---"),
ep_md,
"",
"![The external pressure index, with binding years shaded](figures/pressure_index.pdf)",
"",
paste0("The figure shows the combined pressure index by sample, with binding ",
"years shaded: the tallest sustained blocks are the 1950s and the two ",
"post-reform adjustments."),
"",
paste0("The dated episodes line up with Chilean external history. 1933 sits in ",
"the Depression collapse of export earnings. The 1950–51, 1953–54 and 1957–59 ",
"runs fall inside the import-substituting decades, when capital-goods imports ",
"expanded against stagnant export receipts. 1975–77 follows the post-coup ",
"opening and the first oil shock, and 1983–86 is the debt crisis. Both ",
"post-reform episodes appear in the full-century and post-1974 datings alike, ",
"which is the strongest internal agreement in the report."),
"",
"## 10. Does the gap identify when the constraint bound?",
"",
paste0("Partly, and the qualification is specific enough to be useful. The gap ",
"identifies binding years where imports demonstrably respond to it, which means ",
"the full century and the post-1974 sample and not the decades before 1973. ",
"Where it works it is corroborated: ", cls_n("full_1920_2024",
"binding_confirmed"), " of the ",
year_accounting$years_in_sample[year_accounting$sample == "full_1920_2024"],
" years in the full sample show a shortfall and independent external stress ",
"together, and the episodes fall where Chilean external history puts them."),
"",
paste0("The decisive test is the one independent date available. The Banco ",
"Central's centennial history records the 1961 balance-of-payments crisis and ",
"the abandonment of the fixed exchange rate. The chronology does not identify ",
"it. In 1961 the gap is ", fmt(mis_1961, 3),
" — imports stood *above* their required level, the largest positive gap in the ",
"surrounding decade — while the external accounts did show stress. The year is ",
"therefore recorded as external stress without an import shortfall."),
"",
paste0("That is a coherent economic reading rather than a failure to explain. ",
"The sequence around it is 1958 and 1959 below the requirement and confirmed ",
"binding, 1960 through 1962 above it with stress continuing, then 1963 below ",
"again. What 1961 looks like in this measure is an economy sustaining imports ",
"above what its productive structure and export earnings supported, financed by ",
"reserves and external credit until they ran out. The crisis was the exhaustion ",
"of that financing; the compression came afterwards. An import-shortfall measure ",
"registers the adjustment, not the over-absorption that made adjustment ",
"necessary."),
"",
paste0("So the measure dates *external adjustment episodes* rather than crisis ",
"onsets, and that is what it should be used for. A chronology of when imports ",
"were compressed against a machinery-implied requirement is a different object ",
"from a chronology of when reserves ran out, and 1961 is where the two come ",
"apart most visibly."),
"",
"## 11. Limitations",
"",
paste0("**The machinery stock is I(2).** The promoted specification puts an ",
"I(2) variable in a levels relation with I(1) variables, so it is unbalanced and ",
"the machinery coefficient is not a long-run elasticity in the strict sense. ",
"A differenced-machinery specification is estimated as a check and finds a ",
"relation in every sample, but the levels version is what the report interprets. ",
"Resolving this properly means either a net-stock or investment-flow formulation ",
"or a method built for I(2) systems."),
"",
paste0("**Before 1973 the method does not apply.** Imports do not respond to ",
"the estimated relation and the relation does not normalize on imports. Both ",
"diagnostics point the same way, and the consequence is that the report has ",
"nothing to say about the timing of binding episodes in the import-substituting ",
"decades. That is the period the 1961 benchmark falls in."),
"",
paste0("**One external benchmark is a thin test.** The verified evidence base ",
"supplies exactly one precisely dated crisis, and no additional marker was ",
"invented to pad the comparison. The interpretation offered for the 1961 ",
"disagreement is plausible and is not established by a single case."),
"",
paste0("**The real exchange rate's long-run sign is unresolved.** A positive ",
"long-run coefficient on a depreciation measure cannot be read as a price ",
"elasticity. The short-run coefficient has the expected negative sign, which is ",
"reassuring but does not explain the long-run pattern."),
"",
paste0("**The splice is measurable.** The real exchange rate joins two sources ",
"with a median level gap of ", fmt(rer_val("median_absolute_level_gap"), 2),
"%, which enters every specification that uses it."),
"",
"## Data availability and reproducibility",
"",
paste0("The frozen release is `data/releases/chile_bop_binding_v1_1/`. ", source_note,
" The SHA-256 hash of every consumed input is recorded in ",
"`output/CL/BOP_BINDING_V7/S99_REPORT_ASSEMBLY/`, and the staged ledgers sit in ",
"`data/` beside this file. Stage integrity ledgers for the estimation and dating ",
"stages both report every check passing, and the builder refuses to assemble if ",
"either fails. Each gap value was verified to reproduce the long-run relation ",
"for its own year, to a maximum absolute deviation of ",
formatC(max(dating_audit$max_abs_deviation, na.rm = TRUE), format = "e",
        digits = 1), "."),
"",
paste0("The threshold model reported in the previous version is absent here. ",
"Its regime effect was not statistically supported, and the estimation stage ",
"refuses to run if any threshold ledger is among its inputs."),
"",
paste0("**AI-use disclosure.** Claude Code assisted with reproducible code, ",
"diagnostics, evidence organization and report assembly under human direction. ",
"All claims are auditable against the frozen release and the staged ledgers."),
""
)
md_file <- file.path(report_dir, "chile_bop_binding_report_v7.md")
writeLines(md, md_file, useBytes = TRUE)

# ---------------------------------------------------------------------------
# LaTeX.
# ---------------------------------------------------------------------------
tex <- paste0(
"\\documentclass[11pt]{article}
\\usepackage[utf8]{inputenc}
\\usepackage[T1]{fontenc}
\\usepackage{lmodern}
\\usepackage[margin=1in]{geometry}
\\usepackage{microtype}
\\usepackage{graphicx}
\\usepackage{booktabs}
\\usepackage{array}
\\usepackage{tabularx}
\\usepackage{longtable}
\\usepackage{float}
\\usepackage{placeins}
\\usepackage{xcolor}
\\usepackage{caption}
\\usepackage{natbib}
\\usepackage[hidelinks]{hyperref}
\\usepackage{fancyhdr}
\\setlength{\\parindent}{0pt}
\\setlength{\\parskip}{0.65em}
\\setlength{\\headheight}{14.5pt}
\\renewcommand{\\arraystretch}{1.15}
\\definecolor{ink}{HTML}{19324A}
\\definecolor{accent}{HTML}{A64B2A}
\\hypersetup{colorlinks=true,linkcolor=ink,citecolor=accent,urlcolor=accent}
\\pagestyle{fancy}
\\fancyhf{}
\\lhead{Chile: when did the external constraint bind?}
\\rhead{v7}
\\cfoot{\\thepage}
\\title{\\textbf{When Did Chile's Balance-of-Payments Constraint Bind?}\\\\
\\large An import-requirement account of machinery accumulation and external adjustment, 1920--2024}
\\author{Chapter 2 research pipeline}
\\date{29 July 2026}
\\begin{document}
\\maketitle

\\begin{abstract}
Chile's imports are observed. The level of imports the country's productive structure required is not: it has to be estimated. This report estimates that requirement as a long-run relation between real imports, the gross machinery stock, non-reinvested surplus and the real exchange rate, and asks whether the gap between actual and required imports dates the years when the balance-of-payments constraint bound. A single long-run relation is found in all three samples. It is usable in two of them. Over 1920--2024 imports close ",
fmt(abs(al("full_1920_2024", "log_imports")) * 100, 0),
"\\% of the gap each year and after 1974 they close ",
fmt(abs(al("post_1974_2024", "log_imports")) * 100, 0),
"\\%, so the gap measures something imports respond to. Before 1973 they do not respond at all, and the relation carries no import requirement in that period. Where the measure works it dates ",
cls_n("full_1920_2024", "binding_confirmed"),
" binding years over the century, concentrated in the 1930s, the 1950s, and the two post-reform adjustments of 1975--77 and 1983--86. It does not date 1961, the one crisis independently documented \\citep{bcch2025}, because in 1961 imports stood above their required level rather than below it. The measure identifies the compression that follows an external crisis, not the over-absorption that precedes one.

\\vspace{0.5em}\\noindent\\textbf{Keywords:} Chile; balance of payments; imports; machinery accumulation; real exchange rate; cointegration; error correction; Kaldor; Thirlwall
\\end{abstract}

\\FloatBarrier
\\section{The question, and what has to be estimated to answer it}

Chile's industrialization ran on imported machinery. Building productive capacity meant buying capital goods abroad, and paying for them depended on export earnings and on access to external finance \\citep{bcch2025,alvarez2003}. When those ran short, the imports that carried the accumulation had to be cut. The question is when that happened.

Answering it requires distinguishing two things that are easy to conflate. Actual imports are recorded in the national accounts every year. The level of imports the productive structure \\emph{required} is not recorded anywhere; it is a relation that has to be estimated. Only once that required level exists can a shortfall be defined, and only a shortfall can indicate that the external constraint was doing the cutting.

Kaldor's mechanism supplies the reason machinery belongs at the centre of that relation: manufacturing expansion raises productivity and draws in the capital goods that carry it \\citep{kaldor1967,kaldor1970}. Thirlwall's closure supplies the constraint: sustained growth is limited by export earnings and the import intensity of output, with external finance able to postpone but not remove the limit \\citep{thirlwall1979,thirlwall1982,morenobrid2003}.

The required level is estimated as a long-run relation among four variables, all in logs. Writing imports as $m$, the machinery stock as $k$, non-reinvested surplus as $s$ and the real exchange rate as $r$:
\\begin{equation}
m = \\beta_1 k + \\beta_2 s + \\beta_3 r + c
\\end{equation}
and the gap in a given year is $m - (\\beta_1 k + \\beta_2 s + \\beta_3 r + c)$. A negative gap means imports sat below the level the relation implies. In the surplus approach $\\beta_1$ is the foreign-exchange cost of the intensive margin of accumulation: how much import capacity a larger machinery stock commits the economy to, conditional on distribution and the relative price of foreign goods.

Throughout, a rise in the real exchange rate means real depreciation. The convention is confirmed in the data: the largest annual increases fall in 1932, 1956--57, 1974--75 and 1983--85, each a documented Chilean devaluation \\citep{ffd1983a,ffd2002}.

\\FloatBarrier
\\section{Data}

Every estimate uses the frozen release \\texttt{chile\\_bop\\_binding\\_v1\\_1}: 105 annual observations, 1920 to 2024, with 54 years before 1974 and 51 after. No stage re-queries a source or rebuilds a variable. Real series are in 2003 Chilean pesos, matching the GDP source so no rebasing is applied. The real exchange rate splices a ClioLab index through 2010 to the Banco Central series from 2011, rebased to the 2003 scale.

\\begin{table}[h!]
\\centering
\\caption{Provenance and the real-exchange-rate splice audit}
\\begin{tabular}{p{6.0cm}p{2.4cm}p{5.6cm}}
\\toprule
\\textbf{Audit object} & \\textbf{Result} & \\textbf{Reading} \\\\
\\midrule
Price base, all real series & 2003 CLP & Matches the GDP source; no rebasing applied. \\\\
Level correlation over 1986--2010 & ",
fmt(rer_val("overlap_level_correlation"), 3),
" & The two sources move together. \\\\
Growth correlation over 1987--2010 & ",
fmt(rer_val("overlap_growth_correlation"), 3),
" & Year-to-year movement is shared. \\\\
Median absolute level gap & ",
fmt(rer_val("median_absolute_level_gap"), 2),
"\\% & They differ in level; this is a limitation. \\\\
2011 boundary change & ",
fmt(rer_val("splice_boundary_growth"), 3),
" log points & Within four overlap-growth standard deviations. \\\\
Annual coverage & ", rer_val("spliced_coverage_1920_2024"),
" years & One observation per year, 1920--2024. \\\\
\\bottomrule
\\end{tabular}
\\end{table}

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.90\\textwidth]{figures/rer_overlap.pdf}
\\caption{The two real-exchange-rate sources over their overlap. They move together over 1986--2010 while differing in level, which is why the splice is audited rather than assumed.}
\\end{figure}

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.94\\textwidth]{figures/raw_system.pdf}
\\caption{The four series with local trend lines, before any model is imposed. Imports and the machinery stock rise together across the century, with the two post-1974 accelerations visible without estimation.}
\\end{figure}

\\FloatBarrier
\\section{How persistent is each series?}

A long-run relation between levels only makes sense if the levels themselves wander in a particular way. A series is integrated of order one, written I(1), when its level wanders without returning to any fixed value but its year-to-year change does settle down. Cointegration analysis is built for that case. Each variable is therefore tested before any system is estimated, on the level, then the change, then the change in the change, stopping at the first order where the series settles.

Three tests are used because they ask the question from opposite directions. Augmented Dickey--Fuller and Phillips--Perron start from the assumption that the series wanders and look for evidence against it, so a statistic more negative than the critical value is evidence of stationarity. KPSS starts from the opposite assumption, so a statistic \\emph{above} its critical value is evidence of wandering. Agreement across all three makes a verdict safe; disagreement is reported as disagreement.

\\begin{table}[h!]
\\centering
\\caption{Test statistics against 5\\% critical values, drift specification}
\\footnotesize
\\begin{tabular}{p{1.9cm}p{2.6cm}p{1.1cm}rrrrrp{2.0cm}}
\\toprule
\\textbf{Sample} & \\textbf{Variable} & \\textbf{Diffs} & \\textbf{ADF} & \\textbf{5\\%} & \\textbf{PP} & \\textbf{KPSS} & \\textbf{5\\%} & \\textbf{Verdict} \\\\
\\midrule
",
battery_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

\\begin{table}[h!]
\\centering
\\caption{Order of integration and what follows for each variable}
\\begin{tabular}{p{2.1cm}p{3.4cm}p{2.2cm}p{6.0cm}}
\\toprule
\\textbf{Sample} & \\textbf{Series} & \\textbf{Order} & \\textbf{Disposition} \\\\
\\midrule
",
verdict_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

Read variable by variable. \\textbf{Real imports} settle after one difference in every sample: the level wanders, the growth rate does not. Imports enter the long-run relation without qualification. \\textbf{The real exchange rate} behaves the same way in all three samples. \\textbf{Non-reinvested surplus} is I(1) over the century and after 1974, but before 1973 it is already stationary in levels, so in that sample it contributes no long-run wandering for the others to be tied to. \\textbf{The wage share} $\\omega_t$ is stationary before and after 1974 and unresolved over the full span, so it never enters as a long-run variable and appears only in a robustness specification. \\textbf{The machinery stock} $K^{ME}$ is the problem, and it needs its own section.

One cell is genuinely inconclusive and is not smoothed over. For the change in the machinery stock over the full sample under a trend specification, KPSS returns ",
fmt(battery$kpss_statistic[battery$variable == "log_K_ME_gross" &
  battery$sample == "full_1920_2024" & battery$difference_order == 1 &
  battery$deterministic == "trend"][1], 3), " against a 5\\% value of ",
fmt(battery$kpss_critical_5[battery$variable == "log_K_ME_gross" &
  battery$sample == "full_1920_2024" & battery$difference_order == 1 &
  battery$deterministic == "trend"][1], 3),
", which does not reject stability, while ADF returns ",
fmt(battery$adf_statistic[battery$variable == "log_K_ME_gross" &
  battery$sample == "full_1920_2024" & battery$difference_order == 1 &
  battery$deterministic == "trend"][1], 2), " against ",
fmt(battery$adf_critical_5[battery$variable == "log_K_ME_gross" &
  battery$sample == "full_1920_2024" & battery$difference_order == 1 &
  battery$deterministic == "trend"][1], 2),
", which does not reject wandering. The two point opposite ways once a trend is allowed. The verdict rests on the drift specification, where all three tests agree, and the disagreement is recorded rather than resolved by preference.

\\FloatBarrier
\\section{Why a machinery stock can need two differences}

The machinery stock needs two differences before it settles, in every sample. That is unusual enough to explain from the ground up, because it is the single biggest constraint on everything that follows.

\\subsection*{Start with what a capital stock is}

A capital stock is a running total. This year's machinery is last year's machinery, minus what wore out, plus what was newly installed:
\\begin{equation}
K_t = (1 - z) K_{t-1} + I_t
\\end{equation}
where $I_t$ is machinery investment during the year and $z$ is the fraction of the existing stock retired. Nothing here is a modelling choice; it is how the stock is built from investment flows.

Now ask what happens if investment itself has no level it returns to. Suppose investment drifts upward for two decades, settles at a higher pace, then drifts again, never reverting to a long-run average. Adding up a series that wanders gives a total that wanders more. And because $z$ is small for machinery, very little of the past is discarded each year, so almost the whole history stays in the total. The running total inherits the wandering of the flow and adds its own on top.

\\subsection*{What the two differences mean}

Saying the machinery stock is I(2) says exactly this: not only does the \\emph{level} of the stock fail to return to any fixed value, its \\emph{growth rate} fails to as well. The rate of machinery accumulation itself moves to a new level and stays there. Only the change in the growth rate settles down.

\\subsection*{What the tests show}

In levels, ADF returns ", fmt(bk(0, "adf_statistic"), 2),
" against a 5\\% value of ", fmt(bk(0, "adf_critical_5"), 2),
" and KPSS returns ", fmt(bk(0, "kpss_statistic"), 3), " against ",
fmt(bk(0, "kpss_critical_5"), 3),
": the level wanders and both tests agree. After one difference---looking at the growth rate of the stock rather than its level---ADF still returns only ",
fmt(bk(1, "adf_statistic"), 2), " against ", fmt(bk(1, "adf_critical_5"), 2),
" and KPSS still returns ", fmt(bk(1, "kpss_statistic"), 3), " against ",
fmt(bk(1, "kpss_critical_5"), 3),
". The growth rate is no more settled than the level was. Only after a second difference does the picture change decisively: ADF ",
fmt(bk(2, "adf_statistic"), 2), ", Phillips--Perron ",
fmt(bk(2, "pp_statistic"), 2), ", KPSS ", fmt(bk(2, "kpss_statistic"), 3),
"---all three agree on stationarity.

\\subsection*{What it costs}

Standard cointegration analysis assumes every variable in the long-run relation needs the same single difference to settle. Putting an I(2) variable alongside I(1) variables makes the relation \\emph{unbalanced}: the two sides wander at different orders, and a coefficient estimated on them is not a long-run elasticity in the usual sense. The honest options are machinery growth in place of the stock, methods built for I(2) systems, or keeping the levels specification and reporting the limitation. This report keeps the levels specification, because the machinery stock is the variable the mechanism is about, and carries the limitation forward explicitly. A differenced-machinery specification is estimated alongside it as a check.

\\subsection*{What it means about Chile}

The statistic describes something concrete. Chile's machinery stock did not merely grow across the century---the pace at which it grew shifted and stayed shifted, averaging ",
fmt(gk_pre * 100, 1), "\\% a year before 1973 and ", fmt(gk_post * 100, 1),
"\\% after. A series whose growth rate steps up to a new level and remains there is precisely what a second unit root describes. The awkward statistical property and the post-reform transformation of Chilean accumulation are the same fact seen from two directions \\citep{ffd2002,solimano2024}.

\\FloatBarrier
\\section{How many long-run relations are there?}

With the variables classified, the next question is how many independent long-run relations tie them together. The answer is the \\emph{rank}: zero means no relation and the variables drift apart permanently; one means a single relation holds them together; more than one means several do. Rank is estimated with the Johansen trace test, which asks in sequence whether the number of relations is zero, then at most one, and so on, stopping at the first hypothesis it cannot reject.

Rather than test one preferred model, the relation is built up one variable at a time, so the evidence reads as a sequence.

\\begin{table}[h!]
\\centering
\\caption{The specifications, from the mechanism core outward}
\\footnotesize
\\begin{tabular}{p{1.4cm}p{6.2cm}p{6.4cm}}
\\toprule
\\textbf{Rung} & \\textbf{Variables} & \\textbf{What it adds} \\\\
\\midrule
",
ladder_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

\\begin{table}[h!]
\\centering
\\caption{Number of long-run relations at each rung, constant and two lags}
\\begin{tabular}{p{2.2cm}p{1.6cm}p{2.4cm}p{3.4cm}p{3.4cm}}
\\toprule
\\textbf{Sample} & \\textbf{Rung} & \\textbf{Relations} & \\textbf{Residual-correlation} $p$ & \\textbf{Same order throughout?} \\\\
\\midrule
",
ladder_rank_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

The sequence tells a clear story. Over the full century and after 1974, a single relation appears as soon as imports and machinery are put together, and it survives every addition. Before 1973 the two- and three-variable systems find nothing: no relation ties imports to machinery, or to machinery and surplus, in the pre-reform period. A relation appears only once the real exchange rate is added. That is the first sign the pre-1973 system behaves differently, and Section~\\ref{sec:alpha} shows why it matters.

\\begin{table}[h!]
\\centering
\\caption{The four-variable relation across deterministic terms and lags}
\\begin{tabular}{p{2.2cm}p{1.9cm}p{1.1cm}p{1.9cm}p{2.6cm}p{2.6cm}}
\\toprule
\\textbf{Sample} & \\textbf{Determ.} & \\textbf{Lags} & \\textbf{Relations} & \\textbf{Resid.\\ corr.\\ } $p$ & \\textbf{Largest non-unit root} \\\\
\\midrule
",
rank_prom_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

The specification carried forward in each sample finds exactly one relation, leaves no residual correlation at 5\\%, and has stable dynamics. Requiring exactly one matters: when the test finds two, the single relation extracted from a two-dimensional space is one arbitrary combination of the two and cannot be read as \\emph{the} import requirement. The last column is the stability check. A system tied together by one relation among four variables must carry three permanent trends, so three roots sit on the unit circle by construction; the question is whether the remaining roots lie inside it. They do, between 0.68 and 0.84.

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.97\\textwidth]{figures/rank_grid.pdf}
\\caption{Trace statistics across every rung and sample against the 5\\% critical value (dashed). Where the solid line starts above the dashed one and then crosses below, that crossing is the number of relations.}
\\end{figure}

\\FloatBarrier
\\section{What the long-run relation says}

\\begin{table}[h!]
\\centering
\\caption{The estimated import requirement}
\\begin{tabular}{p{2.2cm}p{3.6cm}p{2.4cm}p{3.0cm}p{2.6cm}}
\\toprule
\\textbf{Sample} & \\textbf{Variable} & \\textbf{Coefficient} & \\textbf{Import share} & \\textbf{Elasticity?} \\\\
\\midrule
",
beta_tex,
"
\\bottomrule
\\multicolumn{5}{p{15.5cm}}{\\footnotesize The import share is the weight imports carry in the estimated relation. Normalizing on imports divides through by it, so a small share makes the reported coefficients arithmetic artifacts rather than elasticities.} \\\\
\\end{tabular}
\\end{table}

Over the full century the required import level rises by ",
fmt(lr("full_1920_2024", "log_K_ME_gross"), 2),
"\\% for every 1\\% increase in the machinery stock, and after 1974 by ",
fmt(lr("post_1974_2024", "log_K_ME_gross"), 2),
"\\%. Read through the surplus approach this is the foreign-exchange commitment attached to the intensive margin of accumulation: enlarging the machinery stock obliges the economy to sustain a proportionally higher level of imports.

The pre-1973 column cannot be read this way. Before 1973 imports carry only ",
fmt(pr("pre_1920_1973", "import_normalization_share"), 3),
" of the weight in the relation, so normalizing on imports divides by something close to zero, and the resulting numbers---a machinery coefficient above eleven, a real-exchange-rate coefficient near twenty---are an artifact of the arithmetic. The relation found before 1973 is not an import relation. Section~\\ref{sec:alpha} confirms this from an entirely separate direction.

The real exchange rate enters the long-run relation with a \\textbf{positive} sign: ",
fmt(lr("full_1920_2024", "log_RER"), 2), " over the century and ",
fmt(lr("post_1974_2024", "log_RER"), 2),
" after 1974. Since a rise means depreciation, a more depreciated currency goes with \\emph{higher} required imports, the opposite of a relative-price brake. The pattern is in the raw data, not an artifact of the system: over 1920--2024 the correlation between the log real exchange rate and the goods-import share of GDP is ",
fmt(cor(panel$log_RER, panel$goods_imports_gdp, use = "complete.obs"), 2),
". The reading that fits Chilean structure is that capital and intermediate imports are hard to substitute domestically, so depreciation raises their peso cost without displacing them, while depreciation episodes coincide with the external pressure that accompanies accumulation drives \\citep{albala2006,palma2019}. Section~\\ref{sec:gamma} shows the real exchange rate doing something quite different within the year.

\\begin{table}[h!]
\\centering
\\caption{The machinery coefficient beside two simpler comparisons}
\\begin{tabular}{p{2.6cm}p{3.4cm}p{3.4cm}p{4.0cm}}
\\toprule
\\textbf{Sample} & \\textbf{Long-run coefficient} & \\textbf{Level slope} & \\textbf{Growth-rate ratio} \\\\
\\midrule
",
tc_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

Two series that both trend upward will appear related whether or not anything ties them together, so the comparison matters. If the estimated coefficient simply reproduced the ratio of average growth rates it would be measuring shared drift. It does not: over the full century the long-run coefficient is ",
fmt(lr("full_1920_2024", "log_K_ME_gross"), 2), " while the growth ratio is ",
fmt(trend_comparison$growth_ratio[trend_comparison$sample == "full_1920_2024"], 2),
" and the level slope is ",
fmt(trend_comparison$ols_level_slope[trend_comparison$sample == "full_1920_2024"], 2),
". The system estimate sits well below both, which is what conditioning on surplus and the real exchange rate does.

\\FloatBarrier
\\section{Which variable does the adjusting, and which does not}
\\label{sec:alpha}

A long-run relation says nothing on its own about who moves when it is violated. That is the adjustment coefficient: for each variable, the fraction of last year's gap closed this year. A coefficient indistinguishable from zero says that variable ignores the gap, which is weak exogeneity. For the question at hand this is the decisive test, because a gap only measures an import requirement if imports are what responds to it.

\\begin{table}[h!]
\\centering
\\caption{Adjustment to the long-run gap, by equation}
\\begin{tabular}{p{2.2cm}p{3.6cm}p{2.2cm}rrp{3.0cm}}
\\toprule
\\textbf{Sample} & \\textbf{Equation for} & \\textbf{Coefficient} & \\textbf{t} & \\textbf{p} & \\textbf{Responds?} \\\\
\\midrule
",
alpha_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

Over the full century imports carry the adjustment, closing ",
fmt(abs(al("full_1920_2024", "log_imports")) * 100, 0),
"\\% of the gap each year with a t ratio of ",
fmt(al("full_1920_2024", "log_imports", "t_statistic"), 2),
". After 1974 the response is far faster, ",
fmt(abs(al("post_1974_2024", "log_imports")) * 100, 0),
"\\% within the year, and imports are the only variable responding significantly: the machinery stock, surplus and the real exchange rate all ignore the gap. That is the configuration the question needs. Imports absorb the disequilibrium and the other three push it around, so the gap is a genuine import requirement and the speed at which imports close it measures how hard the requirement bites.

Before 1973 the picture inverts. Imports respond by ",
fmt(al("pre_1920_1973", "log_imports"), 3), " with a t ratio of ",
fmt(al("pre_1920_1973", "log_imports", "t_statistic"), 2), " and $p = ",
fmt(al("pre_1920_1973", "log_imports", "p_value"), 3),
"$---indistinguishable from no response. The machinery stock is what adjusts, at a t ratio of ",
fmt(al("pre_1920_1973", "log_K_ME_gross", "t_statistic"), 2),
". The relation that exists before 1973 is one machinery closes, not one imports close. This is the same conclusion the normalization diagnostic reached in the previous section, arrived at independently: before 1973 there is no import requirement for imports to fall short of. Under import-substituting industrialization capital-goods imports were administratively allocated through licensing and multiple exchange rates rather than adjusted to a price-and-quantity equilibrium, and a relation imports do not error-correct is what that arrangement looks like in the time series \\citep{ffd2002,albala2006}.

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.92\\textwidth]{figures/misalignment_usability.pdf}
\\caption{The gap for each sample, greyed where imports do not respond to it. The pre-1973 line is drawn but carries no requirement reading.}
\\end{figure}

\\FloatBarrier
\\section{What moves imports within the year}
\\label{sec:gamma}

\\begin{table}[h!]
\\centering
\\caption{Short-run structure of the import equation}
\\begin{tabular}{p{2.2cm}p{4.6cm}p{2.2cm}rrp{1.8cm}}
\\toprule
\\textbf{Sample} & \\textbf{Term} & \\textbf{Coefficient} & \\textbf{t} & \\textbf{p} & \\textbf{Sig.\\ 5\\%} \\\\
\\midrule
",
gamma_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

Over the full century imports have their own momentum: last year's import growth carries ",
fmt(gm("full_1920_2024", "log_imports.dl1"), 2),
" into this year's, the most significant short-run term in the equation. After 1974 that momentum disappears---the own-lag coefficient falls to ",
fmt(gm("post_1974_2024", "log_imports.dl1"), 3),
" and is indistinguishable from zero---and machinery growth takes over at ",
fmt(gm("post_1974_2024", "log_K_ME_gross.dl1"), 2), " with a t ratio of ",
fmt(gm("post_1974_2024", "log_K_ME_gross.dl1", "t_statistic"), 2),
", alongside non-reinvested surplus at ",
fmt(gm("post_1974_2024", "log_non_reinvested_surplus.dl1"), 2),
". Post-reform import growth is driven by what is being installed and what surplus is available to finance it, not by its own past.

The real exchange rate is where short and long run part company. In the long-run relation its coefficient is positive. Within the year it enters negatively in every sample---",
fmt(gm("full_1920_2024", "log_RER.dl1"), 3), " over the century, $p = ",
fmt(gm("full_1920_2024", "log_RER.dl1", "p_value"), 3), "$, and ",
fmt(gm("post_1974_2024", "log_RER.dl1"), 3),
" after 1974---so a depreciation does compress imports in the short term, though only marginally significantly. The relative price works as a brake on impact and as a co-mover over the long haul. Reporting only one of the two would misdescribe what the exchange rate does in this system.

Before 1973 nothing but the own lag matters: machinery growth, surplus and the real exchange rate are all insignificant in the import equation. The disconnection found in the previous section shows up here too.

\\FloatBarrier
\\section{The gap beside the external accounts}

The gap is a model quantity, so on its own it cannot establish that the external constraint was binding: a shortfall relative to an estimated requirement could reflect a mis-specified requirement. Independent evidence is needed, and it comes from the external accounts, which are observed rather than estimated.

A year is counted as binding only when two independent things agree---imports below the requirement the relation implies, \\emph{and} at least one external-account indicator showing stress, meaning a current-account or goods deficit of 3\\% of GDP or more, a fall in manufactured imports of at least 3 percentage points of GDP, or the financing indicator triggering. Years satisfying only one are recorded as satisfying only one. Nothing is counted as binding on the model alone.

\\begin{table}[h!]
\\centering
\\caption{What each category means}
\\footnotesize
\\begin{tabular}{p{4.4cm}p{10.4cm}}
\\toprule
\\textbf{Category} & \\textbf{Meaning} \\\\
\\midrule
",
rules_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.92\\textwidth]{figures/shortfall_vs_accounts.pdf}
\\caption{The import shortfall and the three account-based pressure measures on one standardized scale. They rise together in the 1930s, the mid-1950s, and the mid-1970s and mid-1980s, and diverge in the early 1960s.}
\\end{figure}

\\begin{table}[h!]
\\centering
\\caption{Years by category}
\\begin{tabular}{p{2.6cm}p{1.8cm}p{3.0cm}p{2.8cm}p{1.8cm}p{1.4cm}}
\\toprule
\\textbf{Sample} & \\textbf{Binding} & \\textbf{Shortfall only} & \\textbf{Stress only} & \\textbf{Neither} & \\textbf{Total} \\\\
\\midrule
",
cls_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

Every year of the release is accounted for in each sample. The pre-1973 row is not a finding about Chile: it records that in that sample the model supplies no usable import signal, so the confirmation rule can never be met. Thirty of those years show external stress in the accounts; what is missing is a requirement measure to pair it with, and the report does not convert that absence into a claim that the constraint never bound before 1973.

\\begin{table}[h!]
\\centering
\\caption{Binding episodes}
\\begin{tabular}{p{2.8cm}p{2.4cm}p{2.0cm}p{2.2cm}p{2.6cm}}
\\toprule
\\textbf{Sample} & \\textbf{Years} & \\textbf{Length} & \\textbf{Peak year} & \\textbf{Peak pressure} \\\\
\\midrule
",
ep_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.92\\textwidth]{figures/pressure_index.pdf}
\\caption{The combined pressure index by sample, with binding years shaded. The tallest sustained blocks are the 1950s and the two post-reform adjustments.}
\\end{figure}

The dated episodes line up with Chilean external history. 1933 sits in the Depression collapse of export earnings. The 1950--51, 1953--54 and 1957--59 runs fall inside the import-substituting decades, when capital-goods imports expanded against stagnant export receipts \\citep{bcch2025}. 1975--77 follows the post-coup opening and the first oil shock, and 1983--86 is the debt crisis \\citep{ffd1983a,ffd1983b}. Both post-reform episodes appear in the full-century and post-1974 datings alike, which is the strongest internal agreement in the report.

\\FloatBarrier
\\section{Does the gap identify when the constraint bound?}

Partly, and the qualification is specific enough to be useful. The gap identifies binding years where imports demonstrably respond to it, which means the full century and the post-1974 sample and not the decades before 1973. Where it works it is corroborated: ",
cls_n("full_1920_2024", "binding_confirmed"), " of the ",
year_accounting$years_in_sample[year_accounting$sample == "full_1920_2024"],
" years in the full sample show a shortfall and independent external stress together, and the episodes fall where Chilean external history puts them.

The decisive test is the one independent date available. The Banco Central's centennial history records the 1961 balance-of-payments crisis and the abandonment of the fixed exchange rate \\citep{bcch2025}. The chronology does not identify it. In 1961 the gap is ",
fmt(mis_1961, 3),
"---imports stood \\emph{above} their required level, the largest positive gap in the surrounding decade---while the external accounts did show stress. The year is recorded as external stress without an import shortfall.

That is a coherent economic reading rather than a failure to explain. The sequence around it is 1958 and 1959 below the requirement and confirmed binding, 1960 through 1962 above it with stress continuing, then 1963 below again. What 1961 looks like in this measure is an economy sustaining imports above what its productive structure and export earnings supported, financed by reserves and external credit until they ran out. The crisis was the exhaustion of that financing; the compression came afterwards. An import-shortfall measure registers the adjustment, not the over-absorption that made adjustment necessary \\citep{thirlwall1982,morenobrid2003}.

So the measure dates \\emph{external adjustment episodes} rather than crisis onsets, and that is what it should be used for. A chronology of when imports were compressed against a machinery-implied requirement is a different object from a chronology of when reserves ran out, and 1961 is where the two come apart most visibly.

\\FloatBarrier
\\section{Limitations}

\\textbf{The machinery stock is I(2).} The promoted specification puts an I(2) variable in a levels relation with I(1) variables, so it is unbalanced and the machinery coefficient is not a long-run elasticity in the strict sense. A differenced-machinery specification is estimated as a check and finds a relation in every sample, but the levels version is what the report interprets. Resolving this properly means either a net-stock or investment-flow formulation or a method built for I(2) systems.

\\textbf{Before 1973 the method does not apply.} Imports do not respond to the estimated relation and the relation does not normalize on imports. Both diagnostics point the same way, and the consequence is that the report has nothing to say about the timing of binding episodes in the import-substituting decades---the period the 1961 benchmark falls in.

\\textbf{One external benchmark is a thin test.} The verified evidence base supplies exactly one precisely dated crisis, and no additional marker was invented to pad the comparison. The interpretation offered for the 1961 disagreement is plausible and is not established by a single case.

\\textbf{The real exchange rate's long-run sign is unresolved.} A positive long-run coefficient on a depreciation measure cannot be read as a price elasticity. The short-run coefficient has the expected negative sign, which is reassuring but does not explain the long-run pattern.

\\textbf{The splice is measurable.} The real exchange rate joins two sources with a median level gap of ",
fmt(rer_val("median_absolute_level_gap"), 2),
"\\%, which enters every specification that uses it.

\\FloatBarrier
\\section*{Data availability and reproducibility}

The frozen release is \\texttt{data/releases/chile\\_bop\\_binding\\_v1\\_1/}. Every number is copied from a completed stage ledger; the builder performs no estimation. The SHA-256 hash of every consumed input is recorded in \\texttt{output/CL/BOP\\_BINDING\\_V7/S99\\_REPORT\\_ASSEMBLY/}, and the staged ledgers sit in \\texttt{data/} beside this file. Stage integrity ledgers for the estimation and dating stages both report every check passing, and the builder refuses to assemble if either fails. Each gap value was verified to reproduce the long-run relation for its own year, to a maximum absolute deviation of ",
formatC(max(dating_audit$max_abs_deviation, na.rm = TRUE), format = "e",
        digits = 1),
".

The threshold model reported in the previous version is absent here. Its regime effect was not statistically supported, and the estimation stage refuses to run if any threshold ledger is among its inputs.

\\textbf{Ethics.} The study uses historical aggregate data and involves no human subjects.

\\textbf{AI-use disclosure.} Claude Code assisted with reproducible code, diagnostics, evidence organization and report assembly under human direction. All claims are auditable against the frozen release and the staged ledgers.

\\FloatBarrier
\\appendix
\\section{Full integration-order battery}

\\footnotesize
\\begin{longtable}{p{1.6cm}p{3.4cm}p{0.6cm}p{1.1cm}p{0.6cm}rrrrr}
\\toprule
\\textbf{Sample} & \\textbf{Variable} & \\textbf{Diffs} & \\textbf{Determ.} & \\textbf{n} & \\textbf{ADF} & \\textbf{5\\%} & \\textbf{PP} & \\textbf{KPSS} & \\textbf{5\\%} \\\\
\\midrule
\\endhead
",
battery_app_tex,
"
\\bottomrule
\\end{longtable}
\\normalsize

\\section{Full rank grid}

\\footnotesize
\\begin{longtable}{p{2.6cm}p{1.6cm}p{1.8cm}p{1.2cm}p{2.2cm}p{3.0cm}}
\\toprule
\\textbf{Sample} & \\textbf{Rung} & \\textbf{Determ.} & \\textbf{Lags} & \\textbf{Relations} & \\textbf{Resid.\\ corr.\\ } $p$ \\\\
\\midrule
\\endhead
",
rank_app_tex,
"
\\bottomrule
\\end{longtable}
\\normalsize

\\FloatBarrier
\\begin{thebibliography}{99}
\\raggedright

\\bibitem[Albala-Bertrand(2006)]{albala2006}
Albala-Bertrand, J. M. (2006). Changes in Chile's production structure, 1986--1996: Output and industrial interdependence. \\textit{CEPAL Review, 88}, 159--172.

\\bibitem[Álvarez and Fuentes(2003)]{alvarez2003}
Álvarez, R., \\& Fuentes, J. R. (2003). \\textit{Trade reforms and manufacturing industry in Chile} (Working Paper No. 210). Banco Central de Chile.

\\bibitem[Banco Central de Chile(2025)]{bcch2025}
Banco Central de Chile. (2025). \\textit{100 años de política económica y comercio exterior de Chile}.

\\bibitem[Ffrench-Davis(1983a)]{ffd1983a}
Ffrench-Davis, R. (1983a). El experimento monetarista en Chile: Una síntesis crítica. \\textit{Desarrollo Económico, 23}(90), 163--196. \\url{https://doi.org/10.2307/3466468}

\\bibitem[Ffrench-Davis(1983b)]{ffd1983b}
Ffrench-Davis, R. (1983b). Deuda externa y balanza de pagos de América Latina. \\textit{Estudios Internacionales, 16}(62), 281--304. \\url{https://doi.org/10.5354/0719-3769.1983.16673}

\\bibitem[Ffrench-Davis(2002)]{ffd2002}
Ffrench-Davis, R. (2002). \\textit{Economic reforms in Chile: From dictatorship to democracy}. University of Michigan Press. \\url{https://doi.org/10.3998/mpub.17208}

\\bibitem[Kaldor(1967)]{kaldor1967}
Kaldor, N. (1967). \\textit{Strategic factors in economic development}. Cornell University.

\\bibitem[Kaldor(1970)]{kaldor1970}
Kaldor, N. (1970). The case for regional policies. \\textit{Scottish Journal of Political Economy, 17}(3), 337--348. \\url{https://doi.org/10.1111/j.1467-9485.1970.tb00712.x}

\\bibitem[Moreno-Brid(2003)]{morenobrid2003}
Moreno-Brid, J. C. (2003). Capital flows, interest payments and the balance-of-payments constrained growth model. \\textit{Metroeconomica, 54}(2--3), 346--365. \\url{https://doi.org/10.1111/1467-999X.00170}

\\bibitem[Palma(2019)]{palma2019}
Palma, J. G. (2019). Desindustrialización, desindustrialización ``prematura'' y ``síndrome holandés''. \\textit{El Trimestre Económico, 86}(344), 901--966. \\url{https://doi.org/10.20430/ete.v86i344.970}

\\bibitem[Solimano and Zapata-Román(2024)]{solimano2024}
Solimano, A., \\& Zapata-Román, G. (2024). \\textit{Chilean economic development under neoliberalism}. Cambridge University Press. \\url{https://doi.org/10.1017/9781009477352}

\\bibitem[Thirlwall(1979)]{thirlwall1979}
Thirlwall, A. P. (1979). The balance of payments constraint as an explanation of international growth rate differences. \\textit{PSL Quarterly Review, 32}(128), 45--53. \\url{https://doi.org/10.13133/2037-3643/12804}

\\bibitem[Thirlwall and Hussain(1982)]{thirlwall1982}
Thirlwall, A. P., \\& Hussain, M. N. (1982). The balance of payments constraint, capital flows and growth rate differences between developing countries. \\textit{Oxford Economic Papers, 34}(3), 498--510. \\url{https://doi.org/10.1093/oxfordjournals.oep.a041565}

\\end{thebibliography}
\\end{document}
")
tex <- gsub("\\begin{table}[h!]", "\\begin{table}[H]", tex, fixed = TRUE)
tex <- gsub("\\begin{figure}[h!]", "\\begin{figure}[H]", tex, fixed = TRUE)
tex_file <- file.path(report_dir, "chile_bop_binding_report_v7.tex")
writeLines(tex, tex_file, useBytes = TRUE)

# ---------------------------------------------------------------------------
# Assembly summary and manifest.
# ---------------------------------------------------------------------------
assembly <- tibble(
  object = c("release coverage", "samples", "promoted specification",
             "relations found (full/pre/post)",
             "long-run machinery coefficient (full/post)",
             "import adjustment speed (full/pre/post)",
             "misalignment usable (full/pre/post)",
             "binding years (full/post)",
             "1961 benchmark, full sample", "1961 gap, full sample",
             "threshold model consumed", "report estimates models"),
  value = c(
    "1920-2024 (N=105)", "full, 1920-1973, 1974-2024",
    paste(unique(promoted$specification), collapse = "; "),
    paste(promoted$selected_rank_5[match(samples, promoted$sample)],
          collapse = " / "),
    paste(fmt(lr("full_1920_2024", "log_K_ME_gross"), 3),
          fmt(lr("post_1974_2024", "log_K_ME_gross"), 3), sep = " / "),
    paste(fmt(al("full_1920_2024", "log_imports"), 3),
          fmt(al("pre_1920_1973", "log_imports"), 3),
          fmt(al("post_1974_2024", "log_imports"), 3), sep = " / "),
    paste(promoted$misalignment_interpretable[match(samples, promoted$sample)],
          collapse = " / "),
    paste(cls_n("full_1920_2024", "binding_confirmed"),
          cls_n("post_1974_2024", "binding_confirmed"), sep = " / "),
    bench_row("full_1920_2024", "benchmark_agreement"), fmt(mis_1961, 3),
    "no", "no")
)
write.csv(assembly, file.path(assembly_dir, "report_result_summary_v7.csv"),
          row.names = FALSE)

manifest <- data.frame(
  role = c(rep("consumed_input", length(inputs)),
           rep("approved_figure", length(figure_sources)),
           "report_markdown", "report_latex"),
  file = normalizePath(c(unname(inputs), unname(figure_sources), md_file,
                         tex_file), winslash = "/", mustWork = TRUE),
  stringsAsFactors = FALSE
)
manifest$sha256 <- vapply(manifest$file, digest, character(1),
                          algo = "sha256", file = TRUE)
write.csv(manifest,
          file.path(assembly_dir, "report_assembly_sha256_manifest_v7.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# Compile.
# ---------------------------------------------------------------------------
pdflatex <- Sys.which("pdflatex")
status <- "pdflatex_not_found"
if (nzchar(pdflatex)) {
  old <- getwd(); on.exit(setwd(old), add = TRUE)
  setwd(report_dir)
  args <- c("-interaction=nonstopmode", "-halt-on-error",
            basename(tex_file))
  a <- system2(pdflatex, args, stdout = TRUE, stderr = TRUE)
  sa <- attr(a, "status"); if (is.null(sa)) sa <- 0L
  if (sa == 0L) {
    b <- system2(pdflatex, args, stdout = TRUE, stderr = TRUE)
    sb <- attr(b, "status"); if (is.null(sb)) sb <- 0L
    status <- if (sb == 0L) "compiled" else "second_pass_failed"
    if (sb != 0L) writeLines(tail(b, 40))
  } else {
    status <- "first_pass_failed"; writeLines(tail(a, 40))
  }
  setwd(old)
}
message("S99 v7 report assembly complete: ", report_dir)
message("pdflatex status: ", status)
