#!/usr/bin/env Rscript

# CL_BOP_BINDING v6 / S99: progress-report assembly from the frozen release and
# the completed S30, S32, S40, and S50 ledgers. This script does not estimate,
# transform, or regenerate any upstream object. It stages ledgers and figures,
# records the SHA-256 hash of every consumed input, and writes the Markdown and
# LaTeX report sources.

suppressPackageStartupMessages({
  library(dplyr)
  library(digest)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release_dir <- file.path(root, "data", "releases", "chile_bop_binding_v1_1")
v6_root <- file.path(root, "output", "CL", "BOP_BINDING_V6")
v1_root <- file.path(root, "output", "CL", "BOP_BINDING")
report_dir <- file.path(root, "reports", "Chile_BOP_Binding_Import_ECT_Report",
                        "v6")
data_dir <- file.path(report_dir, "data")
figure_dir <- file.path(report_dir, "figures")
research_dir <- file.path(root, "reports", "Chile_BOP_Binding_Import_ECT_Report",
                          "research")
assembly_dir <- file.path(v6_root, "S99_REPORT_ASSEMBLY")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(assembly_dir, recursive = TRUE, showWarnings = FALSE)

release_file <- file.path(release_dir,
                          "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv")

# ---------------------------------------------------------------------------
# Consumed inputs. Every report number resolves to one of these files.
# ---------------------------------------------------------------------------
inputs <- c(
  release            = release_file,
  provenance         = file.path(release_dir,
                                 "CHILE_BOP_BINDING_PROVENANCE_LEDGER.csv"),
  release_sha        = file.path(release_dir,
                                 "CHILE_BOP_BINDING_SHA256_MANIFEST.csv"),
  rer_audit          = file.path(root, "data", "processed", "CL_BOP_BINDING",
                                 "S20_RER_SPLICE", "rer_splice_validation.csv"),
  integration        = file.path(v6_root, "S30_INTEGRATION_BREAKS",
                                 "sequential_integration_verdict.csv"),
  s30_integrity      = file.path(v6_root, "S30_INTEGRATION_BREAKS",
                                 "s30_sequential_stage_integrity.csv"),
  machinery_route    = file.path(v6_root, "S32_BREAK_AWARE_MACHINERY",
                                 "machinery_route_decision_ledger.csv"),
  zivot_andrews      = file.path(v6_root, "S32_BREAK_AWARE_MACHINERY",
                                 "zivot_andrews_break_ledger.csv"),
  s32_integrity      = file.path(v6_root, "S32_BREAK_AWARE_MACHINERY",
                                 "s32_break_route_integrity.csv"),
  tvecm_model        = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                 "endogenous_tvecm_model_ledger.csv"),
  tvecm_coef         = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                 "endogenous_tvecm_coefficients.csv"),
  tvecm_ect          = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                 "endogenous_tvecm_ect_regime_panel.csv"),
  hansen_seo         = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                 "hansen_seo_linear_threshold_test.csv"),
  seo_test           = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                 "seo_no_cointegration_threshold_test.csv"),
  three_regime       = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                 "three_regime_inaction_band_gate.csv"),
  s40_integrity      = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                 "s40_endogenous_tvecm_integrity.csv"),
  episode_panel      = file.path(v6_root, "S50_BINDING_STATE",
                                 "bop_binding_episode_panel.csv"),
  episode_summary    = file.path(v6_root, "S50_BINDING_STATE",
                                 "confirmed_binding_episode_summary.csv"),
  class_counts       = file.path(v6_root, "S50_BINDING_STATE",
                                 "binding_classification_counts.csv"),
  class_rules        = file.path(v6_root, "S50_BINDING_STATE",
                                 "binding_classification_rules.csv"),
  component_ledger   = file.path(v6_root, "S50_BINDING_STATE",
                                 "binding_index_component_ledger.csv"),
  historical_bench   = file.path(v6_root, "S50_BINDING_STATE",
                                 "historical_benchmark_ledger.csv"),
  ect_dating         = file.path(v6_root, "S50_BINDING_STATE",
                                 "ect_dating_audit.csv"),
  ect_dating_trials  = file.path(v6_root, "S50_BINDING_STATE",
                                 "ect_dating_offset_trials.csv"),
  year_accounting    = file.path(v6_root, "S50_BINDING_STATE",
                                 "s50_year_accounting.csv"),
  threshold_evidence = file.path(v6_root, "S50_BINDING_STATE",
                                 "threshold_evidence_status_ledger.csv"),
  s50_integrity      = file.path(v6_root, "S50_BINDING_STATE",
                                 "s50_binding_state_integrity.csv"),
  research_brief     = file.path(research_dir, "kaldor_chile_research_brief.md"),
  evidence_matrix    = file.path(research_dir, "kaldor_chile_evidence_matrix.md"),
  bibliography       = file.path(research_dir, "verified_bibliography_apa7.md")
)
missing <- inputs[!file.exists(inputs)]
if (length(missing)) {
  stop("missing report inputs:\n", paste(names(missing), missing,
                                         sep = ": ", collapse = "\n"))
}

rd <- function(nm) read.csv(inputs[[nm]], check.names = FALSE,
                            stringsAsFactors = FALSE)

panel <- rd("release")
rer_audit <- rd("rer_audit")
integration <- rd("integration")
machinery_route <- rd("machinery_route")
tvecm_model <- rd("tvecm_model")
tvecm_coef <- rd("tvecm_coef")
tvecm_ect <- rd("tvecm_ect")
hansen_seo <- rd("hansen_seo")
seo_test <- rd("seo_test")
three_regime <- rd("three_regime")
episode_panel <- rd("episode_panel")
episode_summary <- rd("episode_summary")
class_counts <- rd("class_counts")
historical_bench <- rd("historical_bench")
ect_dating <- rd("ect_dating")
year_accounting <- rd("year_accounting")
s30_integrity <- rd("s30_integrity")
s32_integrity <- rd("s32_integrity")
s40_integrity <- rd("s40_integrity")
s50_integrity <- rd("s50_integrity")

# ---------------------------------------------------------------------------
# Gates on the consumed evidence. The report refuses to assemble if any upstream
# stage is incomplete or if the negative threshold verdict has been overwritten.
# ---------------------------------------------------------------------------
samples <- c("full_1920_2024", "pre_1920_1973", "post_1974_2024")
stopifnot(
  identical(range(panel$year), c(1920L, 2024L)),
  sum(panel$year <= 1973) == 54L,
  sum(panel$year >= 1974) == 51L,
  all(rer_audit$passed),
  all(s30_integrity$passed), all(s32_integrity$passed),
  all(s40_integrity$passed), all(s50_integrity$passed),
  setequal(tvecm_model$sample, samples),
  setequal(hansen_seo$sample, samples),
  setequal(seo_test$sample, samples),
  setequal(unique(episode_panel$sample), samples),
  all(tvecm_model$status == "estimated"),
  all(tvecm_model$bootstrap_replications == 999L),
  all(year_accounting$all_years_accounted),
  # The v6 verdict: no sample rejects linear adjustment at the 5% level.
  all(hansen_seo$p_value >= 0.05),
  # The chronology must be dated by the year of each deviation, verified against
  # the frozen release rather than assumed from the upstream label.
  all(ect_dating$exact_match)
)

boot_n <- 999L
get_row <- function(df, s) df[df$sample == s, , drop = FALSE]
hs <- lapply(samples, function(s) get_row(hansen_seo, s))
names(hs) <- samples
sm <- lapply(samples, function(s) get_row(tvecm_model, s))
names(sm) <- samples
se <- lapply(samples, function(s) get_row(seo_test, s))
names(se) <- samples

# Monte Carlo standard error of a bootstrap p-value. The p-values are simulation
# output, so their sampling error belongs in the table beside them.
mc_se <- function(p, n = boot_n) sqrt(p * (1 - p) / n)
hansen_seo$p_mc_se <- mc_se(hansen_seo$p_value)

ect_coef <- function(s, eq, term) {
  v <- tvecm_coef$estimate[tvecm_coef$sample == s &
                             tvecm_coef$equation == eq &
                             tvecm_coef$term == term]
  if (!length(v)) NA_real_ else v[1]
}
adj <- lapply(samples, function(s) {
  list(low = ect_coef(s, "Equation log_imports", "ECT-"),
       high = ect_coef(s, "Equation log_imports", "ECT+"))
})
names(adj) <- samples

rer_val <- function(check) {
  v <- rer_audit$value[rer_audit$check == check]
  if (!length(v)) NA_real_ else as.numeric(v[1])
}

fmt <- function(x, digits = 3) formatC(as.numeric(x), digits = digits,
                                       format = "f")
tex_escape <- function(x) {
  x <- gsub("\\\\", "\\\\textbackslash{}", as.character(x))
  x <- gsub("([#$%&_{}])", "\\\\\\1", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x
}
pretty_sample <- function(s) {
  c(full_1920_2024 = "1920--2024", pre_1920_1973 = "1920--1973",
    post_1974_2024 = "1974--2024")[s]
}
pretty_sample_md <- function(s) {
  c(full_1920_2024 = "1920–2024", pre_1920_1973 = "1920–1973",
    post_1974_2024 = "1974–2024")[s]
}

# ---------------------------------------------------------------------------
# Stage ledgers and figures into the report directory.
# ---------------------------------------------------------------------------
staged <- setdiff(names(inputs), c("release", "research_brief",
                                   "evidence_matrix", "bibliography"))
for (nm in staged) {
  file.copy(inputs[[nm]], file.path(data_dir, basename(inputs[[nm]])),
            overwrite = TRUE)
}

figure_sources <- c(
  rer_overlap = file.path(v1_root, "S20_RER_SPLICE", "fig_rer_overlap.pdf"),
  raw_system = file.path(v1_root, "S30_VECM",
                         "fig_raw_import_system_loess.pdf"),
  endogenous_ect_regimes = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                     "figures", "endogenous_ect_regimes.pdf"),
  endogenous_tvecm_bootstrap = file.path(v6_root, "S40_ENDOGENOUS_ECT_TVECM",
                                         "figures",
                                         "endogenous_tvecm_bootstrap.pdf"),
  binding_index = file.path(v6_root, "S50_BINDING_STATE", "figures",
                            "fig_bop_binding_index_machinery.pdf"),
  machinery_ect_chronology = file.path(v6_root, "S50_BINDING_STATE", "figures",
                                       "fig_machinery_import_ect_chronology.pdf")
)
stopifnot(all(file.exists(figure_sources)))
for (nm in names(figure_sources)) {
  file.copy(figure_sources[[nm]], file.path(figure_dir, paste0(nm, ".pdf")),
            overwrite = TRUE)
}

# ---------------------------------------------------------------------------
# Report-facing derived tables. These reshape staged ledgers for presentation;
# they add the Monte Carlo standard error and no other new quantity.
# ---------------------------------------------------------------------------
threshold_table <- tvecm_model |>
  select(sample, beta_machinery, threshold_ect, n_regime_low, n_regime_high) |>
  left_join(hansen_seo |> select(sample, hansen_seo_statistic = statistic,
                                 hansen_seo_p = p_value,
                                 hansen_seo_p_mc_se = p_mc_se),
            by = "sample") |>
  left_join(seo_test |> select(sample, seo_statistic = statistic,
                               seo_p = p_value), by = "sample") |>
  mutate(
    machinery_elasticity = -beta_machinery,
    adjustment_below_threshold = vapply(sample, function(s) adj[[s]]$low,
                                        numeric(1)),
    adjustment_above_threshold = vapply(sample, function(s) adj[[s]]$high,
                                        numeric(1)),
    linearity_verdict = ifelse(
      hansen_seo_p < 0.05, "rejects linearity at 5%",
      ifelse(hansen_seo_p < 0.10, "marginal at 10%, not at 5%",
             "does not reject linearity")
    )
  ) |>
  arrange(match(sample, samples))
write.csv(threshold_table,
          file.path(data_dir, "report_threshold_summary.csv"),
          row.names = FALSE, na = "")

class_wide <- class_counts |>
  group_by(sample, classification) |>
  summarise(years = sum(years), .groups = "drop") |>
  tidyr::pivot_wider(names_from = classification, values_from = years,
                     values_fill = 0L) |>
  arrange(match(sample, samples))
write.csv(class_wide,
          file.path(data_dir, "report_classification_counts_wide.csv"),
          row.names = FALSE)

# The classification table reads named columns, so a renamed upstream class would
# silently print as zero. Fail instead.
expected_classes <- c("confirmed_binding", "ECT_only_pressure",
                      "observed_BOP_only_pressure", "non_binding_adjustment",
                      "ect_unavailable")
unknown_classes <- setdiff(unique(class_counts$classification),
                           expected_classes)
if (length(unknown_classes)) {
  stop("unrecognised S50 classification(s): ",
       paste(unknown_classes, collapse = ", "),
       " — update the report classification table before assembling")
}

# ---------------------------------------------------------------------------
# Table row builders.
# ---------------------------------------------------------------------------
integration_report <- integration |>
  filter(variable %in% c("log_imports", "log_K_ME_gross", "log_RER",
                         "log_non_reinvested_surplus", "wage_share")) |>
  arrange(match(sample, samples), variable)

integration_rows_tex <- paste(
  vapply(seq_len(nrow(integration_report)), function(i) {
    z <- integration_report[i, ]
    paste0(pretty_sample(z$sample), " & \\texttt{", tex_escape(z$variable),
           "} & ", tex_escape(gsub("_", " ", z$classification)), " & ",
           tex_escape(gsub("_", " ", z$disposition)), " \\\\")
  }, character(1)),
  collapse = "\n"
)

threshold_rows_tex <- paste(
  vapply(samples, function(s) {
    z <- threshold_table[threshold_table$sample == s, ]
    paste0(pretty_sample(s), " & ", fmt(z$machinery_elasticity, 3), " & ",
           fmt(z$threshold_ect, 3), " & ", z$n_regime_low, " / ",
           z$n_regime_high, " & ", fmt(z$adjustment_below_threshold, 3), " & ",
           fmt(z$adjustment_above_threshold, 3), " \\\\")
  }, character(1)),
  collapse = "\n"
)

test_rows_tex <- paste(
  vapply(samples, function(s) {
    z <- threshold_table[threshold_table$sample == s, ]
    paste0(pretty_sample(s), " & ", fmt(z$hansen_seo_statistic, 3), " & ",
           fmt(z$hansen_seo_p, 4), " & ", fmt(z$hansen_seo_p_mc_se, 4), " & ",
           fmt(z$seo_statistic, 3), " & ", fmt(z$seo_p, 3), " & ",
           tex_escape(z$linearity_verdict), " \\\\")
  }, character(1)),
  collapse = "\n"
)

route_rows_tex <- paste(
  vapply(samples, function(s) {
    z <- machinery_route[machinery_route$sample == s, ]
    paste0(pretty_sample(s), " & ", tex_escape(z$standard_gate_status), " & ",
           z$selected_break_year, " & ",
           tex_escape(gsub("_", " ", z$selected_model)), " & ",
           tex_escape(gsub("_", " ", z$break_route_status)), " \\\\")
  }, character(1)),
  collapse = "\n"
)

class_rows_tex <- paste(
  vapply(samples, function(s) {
    z <- class_wide[class_wide$sample == s, ]
    g <- function(col) if (col %in% names(z)) as.integer(z[[col]]) else 0L
    paste0(pretty_sample(s), " & ", g("confirmed_binding"), " & ",
           g("ECT_only_pressure"), " & ", g("observed_BOP_only_pressure"), " & ",
           g("non_binding_adjustment"), " & ", g("ect_unavailable"),
           " & ", sum(vapply(names(z)[-1], function(cc) g(cc), integer(1))),
           " \\\\")
  }, character(1)),
  collapse = "\n"
)

episode_rows_tex <- paste(
  vapply(seq_len(nrow(episode_summary)), function(i) {
    z <- episode_summary[i, ]
    span <- if (z$start_year == z$end_year) as.character(z$start_year) else
      paste0(z$start_year, "--", z$end_year)
    paste0(pretty_sample(z$sample), " & ", span, " & ", z$duration_years,
           " & ", z$peak_year, " & ", fmt(z$peak_binding_index, 3), " \\\\")
  }, character(1)),
  collapse = "\n"
)

bench_rows_tex <- paste(
  vapply(seq_len(nrow(historical_bench)), function(i) {
    z <- historical_bench[i, ]
    paste0(z$year, " & ", pretty_sample(z$sample), " & ",
           tex_escape(gsub("_", " ", z$model_classification)), " & ",
           fmt(z$bop_binding_index, 3), " & ",
           tex_escape(gsub("_", " ", z$benchmark_agreement)), " \\\\")
  }, character(1)),
  collapse = "\n"
)

md_row <- function(...) paste0("| ", paste(c(...), collapse = " | "), " |")

integration_rows_md <- paste(
  vapply(seq_len(nrow(integration_report)), function(i) {
    z <- integration_report[i, ]
    md_row(pretty_sample_md(z$sample), paste0("`", z$variable, "`"),
           z$classification, gsub("_", " ", z$disposition))
  }, character(1)),
  collapse = "\n"
)
threshold_rows_md <- paste(
  vapply(samples, function(s) {
    z <- threshold_table[threshold_table$sample == s, ]
    md_row(pretty_sample_md(s), fmt(z$machinery_elasticity, 3),
           fmt(z$threshold_ect, 3),
           paste0(z$n_regime_low, " / ", z$n_regime_high),
           fmt(z$adjustment_below_threshold, 3),
           fmt(z$adjustment_above_threshold, 3))
  }, character(1)),
  collapse = "\n"
)
test_rows_md <- paste(
  vapply(samples, function(s) {
    z <- threshold_table[threshold_table$sample == s, ]
    md_row(pretty_sample_md(s), fmt(z$hansen_seo_statistic, 3),
           fmt(z$hansen_seo_p, 4), fmt(z$hansen_seo_p_mc_se, 4),
           fmt(z$seo_statistic, 3), fmt(z$seo_p, 3), z$linearity_verdict)
  }, character(1)),
  collapse = "\n"
)
route_rows_md <- paste(
  vapply(samples, function(s) {
    z <- machinery_route[machinery_route$sample == s, ]
    md_row(pretty_sample_md(s), z$standard_gate_status, z$selected_break_year,
           gsub("_", " ", z$selected_model),
           gsub("_", " ", z$break_route_status))
  }, character(1)),
  collapse = "\n"
)
class_rows_md <- paste(
  vapply(samples, function(s) {
    z <- class_wide[class_wide$sample == s, ]
    g <- function(col) if (col %in% names(z)) as.integer(z[[col]]) else 0L
    md_row(pretty_sample_md(s), g("confirmed_binding"), g("ECT_only_pressure"),
           g("observed_BOP_only_pressure"), g("non_binding_adjustment"),
           g("ect_unavailable"),
           sum(vapply(names(z)[-1], function(cc) g(cc), integer(1))))
  }, character(1)),
  collapse = "\n"
)
episode_rows_md <- paste(
  vapply(seq_len(nrow(episode_summary)), function(i) {
    z <- episode_summary[i, ]
    span <- if (z$start_year == z$end_year) as.character(z$start_year) else
      paste0(z$start_year, "–", z$end_year)
    md_row(pretty_sample_md(z$sample), span, z$duration_years, z$peak_year,
           fmt(z$peak_binding_index, 3))
  }, character(1)),
  collapse = "\n"
)
bench_rows_md <- paste(
  vapply(seq_len(nrow(historical_bench)), function(i) {
    z <- historical_bench[i, ]
    md_row(z$year, pretty_sample_md(z$sample),
           gsub("_", " ", z$model_classification),
           fmt(z$bop_binding_index, 3),
           gsub("_", " ", z$benchmark_agreement))
  }, character(1)),
  collapse = "\n"
)

# Narrative quantities, each resolved from a staged ledger.
elast_lo <- min(threshold_table$machinery_elasticity)
elast_hi <- max(threshold_table$machinery_elasticity)
full_conf <- sum(episode_panel$classification == "confirmed_binding" &
                   episode_panel$sample == "full_1920_2024")
bench_full <- historical_bench[historical_bench$sample == "full_1920_2024", ]
bench_pre <- historical_bench[historical_bench$sample == "pre_1920_1973", ]
post_low_n <- sm[["post_1974_2024"]]$n_regime_low
three_min <- three_regime$min_regime_n[
  three_regime$sample == "post_1974_2024"]
pre_p <- hs[["pre_1920_1973"]]$p_value
pre_p_se <- mc_se(pre_p)
pre_dist_05 <- (pre_p - 0.05) / pre_p_se
pre_dist_10 <- (0.10 - pre_p) / pre_p_se

md <- c(
"# Chile's Balance-of-Payments Constraint and Machinery Accumulation",
"",
"## Progress report v6: endogenous import-ECT threshold VECM, 1920–2024",
"",
"### Abstract",
"",
paste0("Machinery accumulation and imports share a long-run relation in Chile ",
"that is remarkably stable across the country's central political-economic ",
"break: the machinery elasticity of imports runs from ", fmt(elast_lo, 2),
" to ", fmt(elast_hi, 2), " across 1920–2024, 1920–1973, and 1974–2024. The ",
"adjustment to that relation is not. This report fits an endogenous ",
"error-correction threshold VECM in which the import ECT selects its own ",
"regime boundary, and finds no statistically significant asymmetry. The ",
"Hansen–Seo bootstrap does not reject linear adjustment in any sample ",
"(p = ", fmt(hs[["full_1920_2024"]]$p_value, 3), ", ",
fmt(pre_p, 4), ", and ", fmt(hs[["post_1974_2024"]]$p_value, 3),
"), and the Seo no-cointegration test rejects nothing. The linear VECM is ",
"therefore the specification for inference, and the estimated ECT regimes are ",
"exploratory screening devices. A dating audit of the error-correction path ",
"establishes a second negative result: with each deviation dated to the year ",
"it was measured, the triangulated chronology does not identify the officially ",
"documented 1961 balance-of-payments crisis as a confirmed binding episode in ",
"either sample. The false negative that disqualified the previous screen ",
"survives."),
"",
"**Keywords:** Chile; balance of payments; imports; machinery accumulation; threshold VECM; error correction; Kaldor; Thirlwall",
"",
"### Resumen",
"",
paste0("La acumulación de maquinaria y las importaciones comparten una ",
"relación de largo plazo notablemente estable en Chile: la elasticidad ",
"maquinaria–importaciones va de ", fmt(elast_lo, 2), " a ", fmt(elast_hi, 2),
" en las tres muestras. El ajuste a esa relación no lo es. El modelo TVECM ",
"con umbral endógeno sobre el ECT no encuentra asimetría estadísticamente ",
"significativa: el bootstrap de Hansen–Seo no rechaza linealidad en ninguna ",
"muestra. El VECM lineal es la especificación válida para inferencia y los ",
"regímenes del ECT son instrumentos exploratorios de tamizaje. Una auditoría ",
"de fechamiento del ECT aporta un segundo resultado negativo: al fechar cada ",
"desviación en el año en que se midió, la cronología triangulada no identifica ",
"la crisis de balanza de pagos de 1961 como episodio confirmado en ninguna ",
"muestra. El falso negativo del tamizaje anterior persiste."),
"",
"## 1. Introduction",
"",
paste0("Chile's industrialization made foreign exchange a condition of ",
"productive transformation. Machinery and intermediate imports built the ",
"productive apparatus; weak export earnings periodically withdrew the means ",
"to pay for them. This report examines whether the adjustment of imports to ",
"their machinery-implied long-run requirement switches between a binding and ",
"a slack regime, and whether that switch dates the periods when the external ",
"constraint actually bound."),
"",
paste0("The long-run relation survives every test put to it. The machinery ",
"elasticity of imports is ", fmt(elast_lo, 2), "–", fmt(elast_hi, 2),
" and barely moves across the 1973/74 break, which is a strong result for a ",
"peripheral economy whose trade regime, exchange-rate rule, and industrial ",
"policy were all rebuilt in between. The threshold does not survive. With the ",
"regime boundary estimated jointly with the cointegrating vector rather than ",
"imposed, the Hansen–Seo bootstrap fails to reject linear adjustment in all ",
"three samples, and the Seo no-cointegration test rejects nothing anywhere. ",
"The asymmetry that motivated the specification is not in the data at ",
"conventional significance."),
"",
paste0("That verdict sets the evidential status of everything downstream. The ",
"linear VECM carries inference. The ECT regimes remain useful as a screening ",
"layer for organizing evidence, and they are reported as such — never as ",
"estimated policy states."),
"",
paste0("The chronology built on those regimes fails its external test. The ",
"1961 balance-of-payments crisis recorded in the Banco Central's centennial ",
"history registers as observed external pressure without the machinery-ECT ",
"signal, in the full sample and in the pre-1974 sample alike. That is the same ",
"false negative that disqualified the previous reduced-system screen, and it ",
"is worth being precise about how it was found: an intermediate version of ",
"this chronology did appear to capture 1961, and the appearance was an ",
"artifact of dating each error-correction value by the year of the equation it ",
"entered rather than the year of the deviation it measured. Section 3.4 ",
"reports the audit that caught the one-year displacement."),
"",
"## 2. Methodology",
"",
"### 2.1 Data and provenance",
"",
paste0("Every estimate consumes the frozen release `chile_bop_binding_v1_1`, ",
"1920–2024, 105 annual observations, with 54 years before 1974 and 51 after. ",
"No stage in this report re-queries a source, re-splices a series, or ",
"reconstructs a variable. GDP, imports, investment, non-reinvested surplus, ",
"and gross machinery capital are in 2003 CLP. The Banco Central RER is an ",
"arithmetic annual mean of monthly observations, rebased from its 1986 ",
"reference to the ClioLab 2003 scale; the overlap gives a level correlation ",
"of ", fmt(rer_val("overlap_level_correlation"), 3), ", a growth correlation ",
"of ", fmt(rer_val("overlap_growth_correlation"), 3), ", a median absolute ",
"level gap of ", fmt(rer_val("median_absolute_level_gap"), 2),
"%, and a 2011 boundary change of ",
fmt(rer_val("splice_boundary_growth"), 3), " log points. The splice passes ",
"every declared audit and is not seamless; the measured source gap stays in ",
"the sensitivity analysis rather than being described away."),
"",
"![ClioLab and BCCh RER overlap](figures/rer_overlap.pdf)",
"",
"![Raw import system with LOESS trends](figures/raw_system.pdf)",
"",
"### 2.2 Integration-order gate",
"",
paste0("A sequential ADF, Phillips–Perron, and KPSS battery classifies each ",
"candidate on levels and successive differences before any long-run system is ",
"fitted. Table 1 records the verdict. Imports and the real exchange rate are ",
"I(1) in every sample, which admits them. Gross machinery capital is I(2) in ",
"every sample, which does not. The wage share is stationary before 1974 and ",
"after 1974 and unresolved over the full span, so it enters as a control and ",
"never as a cointegrating state."),
"",
"**Table 1 — Sequential integration-order verdict**",
"",
md_row("Sample", "Variable", "Classification", "Disposition"),
md_row("---", "---", "---", "---"),
integration_rows_md,
"",
paste0("The machinery result is the binding constraint on the whole exercise. ",
"A gross capital stock is an accumulated path of investment flows, so it ",
"inherits an extra unit root when those flows are themselves persistent. The ",
"theory says machinery accumulation drives the import requirement; the ",
"stochastic evidence says this particular observable proxy is not admissible ",
"in a standard long-run regression. Theory motivates a regressor; it does not ",
"license one."),
"",
"### 2.3 Break-aware machinery route",
"",
paste0("Rather than abandon the machinery channel or smuggle it past the gate, ",
"the pipeline routes it through a Zivot–Andrews and Gregory–Hansen break-aware ",
"stage and labels the result exploratory. Table 2 records the selected breaks: ",
"1936 before 1974 and 1991 in the full and post-1974 samples. This route is ",
"reported, not promoted. Nothing in Section 3 acquires formal status from it."),
"",
"**Table 2 — Break-aware machinery route**",
"",
md_row("Sample", "Standard gate", "Selected break", "Model", "Route status"),
md_row("---", "---", "---", "---", "---"),
route_rows_md,
"",
"### 2.4 Endogenous ECT-threshold VECM",
"",
paste0("The threshold model is a bivariate TVECM in log imports and log gross ",
"machinery capital, estimated with `tsDyn` over a joint grid in the ",
"cointegrating vector and the threshold, one lag, 15% trimming, and ",
boot_n, " bootstrap replications. The threshold variable is the error-",
"correction term itself, so the regime boundary is estimated rather than read ",
"off an observed indicator such as the real exchange rate. Two tests follow: ",
"the Hansen–Seo bootstrap of linear against threshold cointegration, and the ",
"Seo test of no cointegration against threshold cointegration."),
"",
"## 3. Empirical results",
"",
"### 3.1 The long-run relation is stable; the regime split is not",
"",
paste0("Table 3 reports the joint estimates. The machinery elasticity of ",
"imports sits at ", fmt(elast_lo, 3), "–", fmt(elast_hi, 3),
" across all three samples. A relation this stable across the 1973/74 break ",
"says the import requirement attached to machinery accumulation is a ",
"structural feature of Chilean accumulation rather than an artifact of one ",
"trade regime. Read through the surplus approach, the coefficient is the ",
"long-run foreign-exchange cost of the intensive margin of accumulation: ",
"expanding the machinery stock draws imports in near-proportion, whichever ",
"institutional settlement is in place."),
"",
"**Table 3 — Endogenous ECT threshold and regime-specific adjustment**",
"",
md_row("Sample", "Machinery elasticity", "Threshold τ̂", "Regime n (below / above)",
       "Adjustment below τ̂", "Adjustment above τ̂"),
md_row("---", "---", "---", "---", "---", "---"),
threshold_rows_md,
"",
paste0("Two features of this table must not be over-read. First, the ",
"full-sample threshold is **positive** at ",
fmt(sm[["full_1920_2024"]]$threshold_ect, 3),
". The regime labelled *below τ̂* is therefore not the negative-ECT regime: it ",
"pools genuinely negative ECT years with mildly positive ones. The chronology ",
"in Section 3.3 keeps the two definitions apart, intersecting a negative ECT ",
"with the estimated lower regime rather than conflating them. Second, the ",
"post-1974 lower regime holds ", post_low_n, " of 49 observations. Its ",
"adjustment coefficient is not identified with any useful precision, and the ",
"sign contrast against the upper regime in that sample carries no ",
"interpretation."),
"",
"### 3.2 The threshold effect is not statistically supported",
"",
paste0("Table 4 is the result that governs the report. The Hansen–Seo bootstrap ",
"fails to reject linear adjustment in every sample. The full sample returns ",
"p = ", fmt(hs[["full_1920_2024"]]$p_value, 3), " and the post-1974 sample ",
"p = ", fmt(hs[["post_1974_2024"]]$p_value, 3),
", neither remotely close to conventional significance. The pre-1974 sample ",
"comes nearest at p = ", fmt(pre_p, 4), ", which is marginal at 10% and not ",
"significant at 5%."),
"",
"**Table 4 — Threshold tests with bootstrap Monte Carlo error**",
"",
md_row("Sample", "Hansen–Seo LR", "Bootstrap p", "MC s.e.(p)", "Seo LR",
       "Seo p", "Verdict"),
md_row("---", "---", "---", "---", "---", "---", "---"),
test_rows_md,
"",
paste0("Because these p-values are simulation output, the table reports their ",
"Monte Carlo standard error. With ", boot_n, " replications the standard ",
"error at the pre-1974 estimate is ", fmt(pre_p_se, 4), ", which places ",
"p = ", fmt(pre_p, 4), " about ", fmt(pre_dist_05, 1),
" standard errors above 0.05 and ", fmt(pre_dist_10, 1),
" below 0.10. The marginal reading is not an artifact of simulation noise: ",
"more replications would sharpen the estimate without moving it across ",
"either conventional boundary."),
"",
paste0("The Seo no-cointegration test reinforces the verdict from the other ",
"direction. It fails to reject its null in every sample, at p = ",
fmt(se[["full_1920_2024"]]$p_value, 3), ", ", fmt(se[["pre_1920_1973"]]$p_value, 3),
", and ", fmt(se[["post_1974_2024"]]$p_value, 3),
". The threshold specification therefore adds nothing that linear adjustment ",
"does not already deliver, and the estimated thresholds are profile minima ",
"rather than evidence of distinct adjustment regimes."),
"",
"![Endogenous import-ECT regimes](figures/endogenous_ect_regimes.pdf)",
"",
"![Bootstrap distributions of the threshold statistics](figures/endogenous_tvecm_bootstrap.pdf)",
"",
"### 3.3 Triangulated balance-of-payments chronology",
"",
paste0("The chronology treats the ECT regime as one of two independent ",
"requirements. A year is a confirmed binding episode only when a negative ",
"machinery-import ECT inside the estimated lower regime coincides with at ",
"least one observed external signal: a current-account or goods deficit of at ",
"least 3% of GDP, a fall in manufactured imports of at least 3 percentage ",
"points of GDP, or the financing-compression indicator. ECT-only and ",
"observed-only years stay in separate categories, so no episode is ever ",
"confirmed by the model against itself."),
"",
"**Table 5 — Year classification by sample**",
"",
md_row("Sample", "Confirmed binding", "ECT-only pressure", "Observed-BOP only",
       "Non-binding", "No ECT estimate", "Total"),
md_row("---", "---", "---", "---", "---", "---", "---"),
class_rows_md,
"",
paste0("The final column matters for honesty about coverage. The lag and first ",
"difference cost each sample two observations, and after the dating correction ",
"those fall at the first and last year of the sample, which therefore carry no ",
"error-correction estimate. Those years are labelled rather than silently ",
"recorded as non-binding. Every release year in every sample lands in exactly ",
"one class."),
"",
"**Table 6 — Confirmed binding episode runs**",
"",
md_row("Sample", "Years", "Duration", "Peak year", "Peak index"),
md_row("---", "---", "---", "---", "---"),
episode_rows_md,
"",
"![Triangulated BOP-binding index](figures/binding_index.pdf)",
"",
"![Machinery-import ECT chronology](figures/machinery_ect_chronology.pdf)",
"",
"### 3.4 Dating audit and the 1961 benchmark",
"",
paste0("A threshold VECM switches regime on the lagged error-correction term: ",
"the deviation entering the year-t equation is the one measured at t−1. That ",
"is correct for the estimator and treacherous for a chronology, because a ",
"panel that labels each deviation with the equation year attributes every ",
"disequilibrium to the year after it occurred. Triangulating such a panel ",
"against contemporaneous external indicators pairs each year's observed ",
"pressure with the previous year's model signal."),
"",
paste0("The chronology therefore does not trust the upstream year labels. It ",
"rebuilds the cointegrating relation from the frozen release using the ",
"estimated elasticity, matches it against the recorded error-correction path ",
"across a range of leads and lags, and adopts the offset that reproduces the ",
"path exactly. The audit returns a one-year displacement in all three samples, ",
"matching to a maximum absolute deviation of ",
formatC(max(ect_dating$max_abs_deviation), format = "e", digits = 1),
" — machine precision, not an approximate fit. Labels are shifted back one ",
"year before any year is classified, so each deviation is dated to the year it ",
"was measured. The audit is self-checking rather than a fixed correction: if ",
"the upstream stage is re-run with corrected dating, the detected offset is ",
"zero and nothing shifts."),
"",
paste0("The consequence is the second negative result of this report. The ",
"Banco Central's centennial history records that CORFO-led industrialization ",
"raised capital- and intermediate-goods imports from the late 1940s, that ",
"export stagnation left insufficient foreign exchange, and that the sequence ",
"culminated in the 1961 balance-of-payments crisis and the abandonment of the ",
"fixed exchange rate. The previous reduced-system screen missed that year, and ",
"the miss was decisive against it."),
"",
"**Table 7 — Independent historical benchmark**",
"",
md_row("Year", "Sample", "Model classification", "Binding index", "Agreement"),
md_row("---", "---", "---", "---", "---"),
bench_rows_md,
"",
paste0("Correctly dated, the machinery-ECT chronology misses 1961 too. In both ",
"samples the year registers as observed external pressure without the ",
"machinery-ECT signal: the external evidence is present, the model signal is ",
"not. Before the dating audit the full sample appeared to capture 1961 as a ",
"confirmed binding year, and that reading was an artifact of the one-year ",
"displacement — the signal it credited to 1961 belonged to 1960. Replacing ",
"the machinery route for the reduced-system route does not repair the false ",
"negative; it relocates it."),
"",
paste0("The negative result is informative about the screen rather than about ",
"Chile. A single-equation disequilibrium measure built on machinery ",
"accumulation identifies episodes in which imports fell below their ",
"machinery-implied requirement. It is not built to identify a reserve crisis ",
"resolved by devaluation, which is what 1961 was, and which registers in the ",
"observed external accounts precisely where the chronology puts it. The screen ",
"organizes evidence; it does not date crises."),
"",
paste0("One benchmark is also a thin test. The verified evidence base for this ",
"pipeline supplies exactly one precisely dated official crisis, and no ",
"additional marker was invented to pad the comparison. A chronology that fails ",
"its only external test has not been rescued by the size of the test set."),
"",
"## 4. What remains unresolved",
"",
paste0("**Machinery's integration order.** Gross machinery capital is I(2) ",
"under the standard gate in all three samples. The break-aware route is ",
"exploratory, and it stays exploratory: no result in this report acquires ",
"formal status from it. Until the stock's stochastic properties are resolved ",
"— by a net-stock or investment-flow formulation, or by an explicitly ",
"I(2)-admissible estimator — the machinery channel cannot carry paper-facing ",
"inference."),
"",
paste0("**The threshold effect.** Not statistically supported. The Hansen–Seo ",
"bootstrap fails to reject linearity in every sample and the Seo test rejects ",
"nothing. The pre-1974 marginal result at p = ", fmt(pre_p, 4),
" is worth revisiting on a longer or higher-frequency sample; it is not worth ",
"reporting as a regime finding now."),
"",
paste0("**Three-regime inaction band.** The three-regime model was fitted and ",
"gated for feasibility, but its thresholds and coefficients were never ",
"written out, so this report records feasibility rather than a completed ",
"robustness check. The gate itself is fragile: the recorded minimum outer-",
"regime size for the post-1974 sample is ", fmt(three_min, 2),
", which rounds to the eight observations the gate requires and sits exactly ",
"on its boundary. The recorded figure also scales regime shares by the ",
"pre-lag row count rather than the effective estimation sample, which is why ",
"it is not an integer. A three-regime inaction band is not evidence in this ",
"report."),
"",
paste0("**The chronology's external validity.** The screen fails its only dated ",
"external benchmark. Until it identifies 1961 — or until an argument is made ",
"for why a machinery-import disequilibrium measure should not be expected to ",
"identify a reserve crisis resolved by devaluation — the episode panel is a ",
"device for organizing evidence and nothing more. The benchmark set also needs ",
"to grow before failure or success on it means much."),
"",
paste0("**RER-only external threshold.** Planned as a comparison and not yet ",
"fitted. The previous pipeline found no RER-threshold effect in reduced ",
"systems, so the comparison is expected to be negative; it has not been run ",
"on the machinery system and is not claimed either way."),
"",
paste0("**Bootstrap reproducibility.** The S40 ledgers consumed here were ",
"produced before the estimation script set a random seed. The reported ",
"bootstrap p-values are therefore not exactly reproducible, which is why ",
"their Monte Carlo standard errors appear in Table 4. The script now seeds ",
"the bootstrap, so subsequent runs are reproducible and will differ from ",
"these figures within simulation error."),
"",
"## 5. Next empirical decision",
"",
paste0("The decision rule set before estimation was explicit: proceed to ",
"threshold-aware analysis if the Hansen–Seo bootstrap rejected linearity at ",
"5%, and treat the linear VECM as adequate otherwise. No sample rejects. The ",
"linear VECM is the specification for inference, and the threshold branch ",
"closes."),
"",
paste0("Three steps follow. Resolve machinery's integration order, since that ",
"blocks the long-run system regardless of what the adjustment dynamics turn ",
"out to be. Report the linear machinery relation alongside the ARDL fallback, ",
"with the I(2) limitation stated rather than managed. Keep the ECT chronology ",
"as a screening layer for organizing historical evidence, and extend the ",
"external benchmark set beyond 1961 so that the screen faces a real test ",
"rather than a single date."),
"",
"## Data availability and reproducibility",
"",
paste0("The frozen release is `data/releases/chile_bop_binding_v1_1/`. Every ",
"table and figure in this report is copied from a completed stage ledger; the ",
"report builder performs no estimation and records the SHA-256 hash of each ",
"consumed input in `output/CL/BOP_BINDING_V6/S99_REPORT_ASSEMBLY/`. Staged ",
"ledgers are in `data/` beside this file. Stage integrity ledgers for S30, ",
"S32, S40, and S50 all report passing checks, and the builder refuses to ",
"assemble if any of them fails."),
"",
paste0("**AI-use disclosure.** Claude Code assisted with reproducible code, ",
"diagnostics, evidence organization, and report assembly under human ",
"direction. All claims are auditable against the frozen release and the ",
"staged stage ledgers."),
""
)

md_file <- file.path(report_dir, "chile_bop_binding_report_v6.md")
writeLines(md, md_file, useBytes = TRUE)

# ---------------------------------------------------------------------------
# LaTeX source.
# ---------------------------------------------------------------------------
report_tex <- paste0(
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
\\lhead{Chile BOP-Binding Progress Report v6}
\\rhead{Endogenous ECT-TVECM}
\\cfoot{\\thepage}
\\title{\\textbf{Chile's Balance-of-Payments Constraint and Machinery Accumulation}\\\\
\\large Progress report v6: endogenous import-ECT threshold VECM, 1920--2024}
\\author{Chapter 2 research pipeline}
\\date{29 July 2026}
\\begin{document}
\\maketitle

\\begin{abstract}
Machinery accumulation and imports share a long-run relation in Chile that is remarkably stable across the country's central political-economic break: the machinery elasticity of imports runs from ",
fmt(elast_lo, 2), " to ", fmt(elast_hi, 2),
" across 1920--2024, 1920--1973, and 1974--2024. The adjustment to that relation is not. This report fits an endogenous error-correction threshold VECM in which the import ECT selects its own regime boundary, and finds no statistically significant asymmetry. The Hansen--Seo bootstrap does not reject linear adjustment in any sample ($p=",
fmt(hs[["full_1920_2024"]]$p_value, 3), "$, $", fmt(pre_p, 4), "$, and $",
fmt(hs[["post_1974_2024"]]$p_value, 3),
"$), and the Seo no-cointegration test rejects nothing. The linear VECM is therefore the specification for inference, and the estimated ECT regimes are exploratory screening devices. A dating audit of the error-correction path establishes a second negative result: with each deviation dated to the year it was measured, the triangulated chronology does not identify the officially documented 1961 balance-of-payments crisis as a confirmed binding episode in either sample \\citep{bcch2025}. The false negative that disqualified the previous screen survives.

\\vspace{0.5em}\\noindent\\textbf{Keywords:} Chile; balance of payments; imports; machinery accumulation; threshold VECM; error correction; Kaldor; Thirlwall
\\end{abstract}

\\FloatBarrier
\\section*{Resumen}
La acumulación de maquinaria y las importaciones comparten una relación de largo plazo notablemente estable en Chile: la elasticidad maquinaria--importaciones va de ",
fmt(elast_lo, 2), " a ", fmt(elast_hi, 2),
" en las tres muestras. El ajuste a esa relación no lo es. El modelo TVECM con umbral endógeno sobre el ECT no encuentra asimetría estadísticamente significativa: el bootstrap de Hansen--Seo no rechaza linealidad en ninguna muestra. El VECM lineal es la especificación válida para inferencia y los regímenes del ECT son instrumentos exploratorios de tamizaje. Una auditoría de fechamiento del ECT aporta un segundo resultado negativo: al fechar cada desviación en el año en que se midió, la cronología triangulada no identifica la crisis de balanza de pagos de 1961 como episodio confirmado en ninguna muestra. El falso negativo del tamizaje anterior persiste.

\\FloatBarrier
\\section{Introduction}

Chile's industrialization made foreign exchange a condition of productive transformation. Machinery and intermediate imports built the productive apparatus; weak export earnings periodically withdrew the means to pay for them \\citep{bcch2025,alvarez2003}. This report examines whether the adjustment of imports to their machinery-implied long-run requirement switches between a binding and a slack regime, and whether that switch dates the periods when the external constraint actually bound.

The long-run relation survives every test put to it. The machinery elasticity of imports is ",
fmt(elast_lo, 2), "--", fmt(elast_hi, 2),
" and barely moves across the 1973/74 break, which is a strong result for a peripheral economy whose trade regime, exchange-rate rule, and industrial policy were all rebuilt in between. The threshold does not survive. With the regime boundary estimated jointly with the cointegrating vector rather than imposed, the Hansen--Seo bootstrap fails to reject linear adjustment in all three samples, and the Seo no-cointegration test rejects nothing anywhere. The asymmetry that motivated the specification is not in the data at conventional significance.

That verdict sets the evidential status of everything downstream. The linear VECM carries inference. The ECT regimes remain useful as a screening layer for organizing evidence, and they are reported as such---never as estimated policy states.

The chronology built on those regimes fails its external test. The 1961 balance-of-payments crisis recorded in the Banco Central's centennial history registers as observed external pressure without the machinery-ECT signal, in the full sample and in the pre-1974 sample alike \\citep{bcch2025}. That is the same false negative that disqualified the previous reduced-system screen, and it is worth being precise about how it was found: an intermediate version of this chronology did appear to capture 1961, and the appearance was an artifact of dating each error-correction value by the year of the equation it entered rather than the year of the deviation it measured. Section~\\ref{sec:dating} reports the audit that caught the one-year displacement.

\\FloatBarrier
\\section{Mechanism and identification}

Kaldor's mechanism runs from manufacturing expansion to increasing returns and productivity growth, and cumulative causation then makes productive structure path dependent \\citep{kaldor1967,kaldor1970}. Cross-country evidence supports the general manufacturing-growth mechanism without identifying a Chilean coefficient \\citep{marconi2016}. Thirlwall's closure makes sustained growth conditional on export earnings and the income elasticity of imports, and later extensions admit capital flows and debt service \\citep{thirlwall1979,thirlwall1982,morenobrid2003}. The theory predicts a foreign-exchange constraint on transformation. It does not predict a particular integration order, cointegrating rank, or crisis classifier, and this report does not let it substitute for one.

For Chile the connecting mechanism is imported productive inputs. Official history records that CORFO-led industrialization raised capital- and intermediate-goods imports from the late 1940s while export stagnation left insufficient foreign exchange, producing the 1961 balance-of-payments crisis \\citep{bcch2025}. Plant-level analysis emphasizes technology embodied in imported capital and intermediate goods and their limited domestic substitutability \\citep{alvarez2003}. The post-1974 split is equally substantive: trade reform changed manufacturing composition and productivity, import penetration weakened domestic interindustry linkages, and development remained tied to copper and externally exposed structural change \\citep{ffd1983a,ffd1983b,ffd2002,albala2006,palma2019,solimano2024}. A direct Chilean application of balance-of-payments-constrained growth covers 1980--2019 and cannot adjudicate the earlier system or the 1961 benchmark \\citep{yunga2022}.

\\FloatBarrier
\\section{Methodology}

\\subsection{Data and provenance}

Every estimate consumes the frozen release \\texttt{chile\\_bop\\_binding\\_v1\\_1}, 1920--2024, 105 annual observations, with 54 years before 1974 and 51 after. No stage in this report re-queries a source, re-splices a series, or reconstructs a variable. GDP, imports, investment, non-reinvested surplus, and gross machinery capital are in 2003 CLP. The Banco Central RER is an arithmetic annual mean of monthly observations, rebased from its 1986 reference to the ClioLab 2003 scale.

\\begin{table}[h!]
\\centering
\\caption{Provenance, units, and the RER splice audit}
\\label{tab:provenance}
\\begin{tabular}{p{6.0cm}p{2.4cm}p{5.6cm}}
\\toprule
\\textbf{Audit object} & \\textbf{Result} & \\textbf{Verdict} \\\\
\\midrule
Price base, all real series & 2003 CLP & Matches the GDP source exactly; no rebasing applied. \\\\
Overlap level correlation, 1986--2010 & ",
fmt(rer_val("overlap_level_correlation"), 3),
" & Clears the declared 0.80 floor; the definitions are related, not identical. \\\\
Overlap growth correlation, 1987--2010 & ",
fmt(rer_val("overlap_growth_correlation"), 3),
" & Common annual movement supports a documented splice. \\\\
Median absolute level gap & ",
fmt(rer_val("median_absolute_level_gap"), 2),
"\\% & Material, and retained in the sensitivity analysis. \\\\
2011 boundary log growth & ",
fmt(rer_val("splice_boundary_growth"), 3),
" & Within four overlap-growth standard deviations. \\\\
Spliced annual coverage & ",
rer_val("spliced_coverage_1920_2024"),
" years & One row per year, 1920--2024. \\\\
\\bottomrule
\\end{tabular}
\\end{table}

The splice passes every declared audit and is not seamless. The measured source gap stays in the sensitivity analysis rather than being described away.

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.92\\textwidth]{figures/rer_overlap.pdf}
\\caption{ClioLab and Banco Central RER over the 1986--2010 overlap.}
\\end{figure}

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.96\\textwidth]{figures/raw_system.pdf}
\\caption{Raw import system with LOESS trends, before any parametric restriction.}
\\end{figure}

\\FloatBarrier
\\subsection{Integration-order gate}

A sequential ADF, Phillips--Perron, and KPSS battery classifies each candidate on levels and successive differences before any long-run system is fitted. Imports and the real exchange rate are I(1) in every sample, which admits them. Gross machinery capital is I(2) in every sample, which does not. The wage share $\\omega_t$ is stationary before 1974 and after 1974 and unresolved over the full span, so it enters as a control and never as a cointegrating state.

\\begin{table}[h!]
\\centering
\\caption{Sequential integration-order verdict}
\\label{tab:integration}
\\begin{tabular}{p{2.0cm}p{5.7cm}p{2.4cm}p{4.0cm}}
\\toprule
\\textbf{Sample} & \\textbf{Variable} & \\textbf{Classification} & \\textbf{Disposition} \\\\
\\midrule
",
integration_rows_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

The machinery result is the binding constraint on the whole exercise. A gross capital stock is an accumulated path of investment flows, so it inherits an extra unit root when those flows are themselves persistent. The theory says machinery accumulation drives the import requirement; the stochastic evidence says this particular observable proxy is not admissible in a standard long-run regression. Theory motivates a regressor; it does not license one.

\\FloatBarrier
\\subsection{Break-aware machinery route}

Rather than abandon the machinery channel or smuggle it past the gate, the pipeline routes it through a Zivot--Andrews and Gregory--Hansen break-aware stage and labels the result exploratory. This route is reported, not promoted. No result in Section~\\ref{sec:results} acquires formal status from it.

\\begin{table}[h!]
\\centering
\\caption{Break-aware machinery route}
\\label{tab:route}
\\begin{tabular}{p{2.3cm}p{2.2cm}p{2.2cm}p{2.8cm}p{4.2cm}}
\\toprule
\\textbf{Sample} & \\textbf{Standard gate} & \\textbf{Break} & \\textbf{Model} & \\textbf{Route status} \\\\
\\midrule
",
route_rows_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

\\FloatBarrier
\\subsection{Endogenous ECT-threshold VECM}

The threshold model is a bivariate TVECM in log imports and log gross machinery capital, estimated with \\texttt{tsDyn} over a joint grid in the cointegrating vector and the threshold, one lag, 15\\% trimming, and ",
boot_n,
" bootstrap replications. The threshold variable is the error-correction term itself, so the regime boundary is estimated rather than read off an observed indicator such as the real exchange rate. Two tests follow: the Hansen--Seo bootstrap of linear against threshold cointegration, and the Seo test of no cointegration against threshold cointegration.

\\FloatBarrier
\\section{Empirical results}
\\label{sec:results}

\\subsection{The long-run relation is stable; the regime split is not}

The machinery elasticity of imports sits at ",
fmt(elast_lo, 3), "--", fmt(elast_hi, 3),
" across all three samples. A relation this stable across the 1973/74 break says the import requirement attached to machinery accumulation is a structural feature of Chilean accumulation rather than an artifact of one trade regime. Read through the surplus approach, the coefficient is the long-run foreign-exchange cost of the intensive margin of accumulation: expanding the machinery stock draws imports in near-proportion, whichever institutional settlement is in place.

\\begin{table}[h!]
\\centering
\\caption{Endogenous ECT threshold and regime-specific adjustment}
\\label{tab:threshold}
\\begin{tabular}{p{2.3cm}p{2.4cm}p{2.0cm}p{2.4cm}p{2.4cm}p{2.4cm}}
\\toprule
\\textbf{Sample} & \\textbf{Machinery elasticity} & \\textbf{Threshold} $\\hat{\\tau}$ & \\textbf{Regime} $n$ & \\textbf{Adj. below} $\\hat{\\tau}$ & \\textbf{Adj. above} $\\hat{\\tau}$ \\\\
\\midrule
",
threshold_rows_tex,
"
\\bottomrule
\\multicolumn{6}{p{15.5cm}}{\\footnotesize Regime $n$ reports observations below and above $\\hat{\\tau}$. Adjustment coefficients are the import-equation error-correction terms in each regime.} \\\\
\\end{tabular}
\\end{table}

Two features of this table must not be over-read. First, the full-sample threshold is positive at $",
fmt(sm[["full_1920_2024"]]$threshold_ect, 3),
"$. The regime labelled below $\\hat{\\tau}$ is therefore not the negative-ECT regime: it pools genuinely negative ECT years with mildly positive ones. The chronology in Section~\\ref{sec:chronology} keeps the two definitions apart, intersecting a negative ECT with the estimated lower regime rather than conflating them. Second, the post-1974 lower regime holds ",
post_low_n,
" of 49 observations. Its adjustment coefficient is not identified with any useful precision, and the sign contrast against the upper regime in that sample carries no interpretation.

\\FloatBarrier
\\subsection{The threshold effect is not statistically supported}

Table~\\ref{tab:tests} is the result that governs the report. The Hansen--Seo bootstrap fails to reject linear adjustment in every sample. The full sample returns $p=",
fmt(hs[["full_1920_2024"]]$p_value, 3), "$ and the post-1974 sample $p=",
fmt(hs[["post_1974_2024"]]$p_value, 3),
"$, neither remotely close to conventional significance. The pre-1974 sample comes nearest at $p=",
fmt(pre_p, 4), "$, which is marginal at 10\\% and not significant at 5\\%.

\\begin{table}[h!]
\\centering
\\caption{Threshold tests with bootstrap Monte Carlo error}
\\label{tab:tests}
\\begin{tabular}{p{2.1cm}p{1.9cm}p{1.9cm}p{1.9cm}p{1.5cm}p{1.3cm}p{3.0cm}}
\\toprule
\\textbf{Sample} & \\textbf{H--S LR} & \\textbf{Boot.} $p$ & \\textbf{MC s.e.} & \\textbf{Seo LR} & \\textbf{Seo} $p$ & \\textbf{Verdict} \\\\
\\midrule
",
test_rows_tex,
"
\\bottomrule
\\multicolumn{7}{p{15.5cm}}{\\footnotesize Hansen--Seo tests linear against threshold cointegration; Seo tests no cointegration against threshold cointegration. Monte Carlo standard error is $\\sqrt{\\hat{p}(1-\\hat{p})/",
boot_n, "}$.} \\\\
\\end{tabular}
\\end{table}

Because these $p$-values are simulation output, the table reports their Monte Carlo standard error. With ",
boot_n, " replications the standard error at the pre-1974 estimate is $",
fmt(pre_p_se, 4), "$, which places $p=", fmt(pre_p, 4), "$ about ",
fmt(pre_dist_05, 1), " standard errors above 0.05 and ", fmt(pre_dist_10, 1),
" below 0.10. The marginal reading is not an artifact of simulation noise: more replications would sharpen the estimate without moving it across either conventional boundary.

The Seo no-cointegration test reinforces the verdict from the other direction. It fails to reject its null in every sample, at $p=",
fmt(se[["full_1920_2024"]]$p_value, 3), "$, $",
fmt(se[["pre_1920_1973"]]$p_value, 3), "$, and $",
fmt(se[["post_1974_2024"]]$p_value, 3),
"$. The threshold specification therefore adds nothing that linear adjustment does not already deliver, and the estimated thresholds are profile minima rather than evidence of distinct adjustment regimes.

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.92\\textwidth]{figures/endogenous_ect_regimes.pdf}
\\caption{Endogenous import-ECT regimes. Regime boundaries are exploratory: the Hansen--Seo bootstrap does not reject linear adjustment.}
\\end{figure}

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.92\\textwidth]{figures/endogenous_tvecm_bootstrap.pdf}
\\caption{Bootstrap distributions of the Hansen--Seo and Seo statistics.}
\\end{figure}

\\FloatBarrier
\\subsection{Triangulated balance-of-payments chronology}
\\label{sec:chronology}

The chronology treats the ECT regime as one of two independent requirements. A year is a confirmed binding episode only when a negative machinery-import ECT inside the estimated lower regime coincides with at least one observed external signal: a current-account or goods deficit of at least 3\\% of GDP, a fall in manufactured imports of at least 3 percentage points of GDP, or the financing-compression indicator. ECT-only and observed-only years stay in separate categories, so no episode is ever confirmed by the model against itself.

\\begin{table}[h!]
\\centering
\\caption{Year classification by sample}
\\label{tab:classes}
\\begin{tabular}{p{2.2cm}p{2.0cm}p{1.9cm}p{2.1cm}p{1.9cm}p{1.9cm}p{1.2cm}}
\\toprule
\\textbf{Sample} & \\textbf{Confirmed} & \\textbf{ECT only} & \\textbf{Observed only} & \\textbf{Non-binding} & \\textbf{No ECT} & \\textbf{Total} \\\\
\\midrule
",
class_rows_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

The final column matters for honesty about coverage. The lag and first difference cost each sample two observations, and after the dating correction those fall at the first and last year of the sample, which therefore carry no error-correction estimate. Those years are labelled rather than silently recorded as non-binding. Every release year in every sample lands in exactly one class.

\\begin{table}[h!]
\\centering
\\caption{Confirmed binding episode runs}
\\label{tab:episodes}
\\begin{tabular}{p{2.6cm}p{2.4cm}p{2.2cm}p{2.2cm}p{2.6cm}}
\\toprule
\\textbf{Sample} & \\textbf{Years} & \\textbf{Duration} & \\textbf{Peak year} & \\textbf{Peak index} \\\\
\\midrule
",
episode_rows_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.92\\textwidth]{figures/binding_index.pdf}
\\caption{Triangulated BOP-binding index. Shading marks years satisfying both the ECT-regime and external-evidence rules.}
\\end{figure}

\\begin{figure}[h!]
\\centering
\\includegraphics[width=0.92\\textwidth]{figures/machinery_ect_chronology.pdf}
\\caption{Machinery-import ECT chronology and candidate binding regimes.}
\\end{figure}

\\FloatBarrier
\\subsection{Dating audit and the 1961 benchmark}
\\label{sec:dating}

A threshold VECM switches regime on the lagged error-correction term: the deviation entering the year-$t$ equation is the one measured at $t-1$. That is correct for the estimator and treacherous for a chronology, because a panel that labels each deviation with the equation year attributes every disequilibrium to the year after it occurred. Triangulating such a panel against contemporaneous external indicators pairs each year's observed pressure with the previous year's model signal.

The chronology therefore does not trust the upstream year labels. It rebuilds the cointegrating relation from the frozen release using the estimated elasticity, matches it against the recorded error-correction path across a range of leads and lags, and adopts the offset that reproduces the path exactly. The audit returns a one-year displacement in all three samples, matching to a maximum absolute deviation of $",
formatC(max(ect_dating$max_abs_deviation), format = "e", digits = 1),
"$---machine precision, not an approximate fit. Labels are shifted back one year before any year is classified, so each deviation is dated to the year it was measured. The audit is self-checking rather than a fixed correction: if the upstream stage is re-run with corrected dating, the detected offset is zero and nothing shifts.

The consequence is the second negative result of this report. The Banco Central's centennial history records that CORFO-led industrialization raised capital- and intermediate-goods imports from the late 1940s, that export stagnation left insufficient foreign exchange, and that the sequence culminated in the 1961 balance-of-payments crisis and the abandonment of the fixed exchange rate \\citep{bcch2025}. The previous reduced-system screen missed that year, and the miss was decisive against it.

\\begin{table}[h!]
\\centering
\\caption{Independent historical benchmark}
\\label{tab:benchmark}
\\begin{tabular}{p{1.4cm}p{2.4cm}p{4.4cm}p{2.4cm}p{4.0cm}}
\\toprule
\\textbf{Year} & \\textbf{Sample} & \\textbf{Model classification} & \\textbf{Binding index} & \\textbf{Agreement} \\\\
\\midrule
",
bench_rows_tex,
"
\\bottomrule
\\end{tabular}
\\end{table}

Correctly dated, the machinery-ECT chronology misses 1961 too. In both samples the year registers as observed external pressure without the machinery-ECT signal: the external evidence is present, the model signal is not. Before the dating audit the full sample appeared to capture 1961 as a confirmed binding year, and that reading was an artifact of the one-year displacement---the signal it credited to 1961 belonged to 1960. Replacing the machinery route for the reduced-system route does not repair the false negative; it relocates it.

The negative result is informative about the screen rather than about Chile. A single-equation disequilibrium measure built on machinery accumulation identifies episodes in which imports fell below their machinery-implied requirement. It is not built to identify a reserve crisis resolved by devaluation, which is what 1961 was, and which registers in the observed external accounts precisely where the chronology puts it. The screen organizes evidence; it does not date crises.

One benchmark is also a thin test. The verified evidence base for this pipeline supplies exactly one precisely dated official crisis, and no additional marker was invented to pad the comparison. A chronology that fails its only external test has not been rescued by the size of the test set.

\\FloatBarrier
\\section{What remains unresolved}

\\textbf{Machinery's integration order.} Gross machinery capital is I(2) under the standard gate in all three samples. The break-aware route is exploratory, and it stays exploratory: no result in this report acquires formal status from it. Until the stock's stochastic properties are resolved---by a net-stock or investment-flow formulation, or by an explicitly I(2)-admissible estimator---the machinery channel cannot carry paper-facing inference.

\\textbf{The threshold effect.} Not statistically supported. The Hansen--Seo bootstrap fails to reject linearity in every sample and the Seo test rejects nothing. The pre-1974 marginal result at $p=",
fmt(pre_p, 4),
"$ is worth revisiting on a longer or higher-frequency sample; it is not worth reporting as a regime finding now.

\\textbf{Three-regime inaction band.} The three-regime model was fitted and gated for feasibility, but its thresholds and coefficients were never written out, so this report records feasibility rather than a completed robustness check. The gate itself is fragile: the recorded minimum outer-regime size for the post-1974 sample is ",
fmt(three_min, 2),
", which rounds to the eight observations the gate requires and sits exactly on its boundary. The recorded figure also scales regime shares by the pre-lag row count rather than the effective estimation sample, which is why it is not an integer. A three-regime inaction band is not evidence in this report.

\\textbf{The chronology's external validity.} The screen fails its only dated external benchmark. Until it identifies 1961---or until an argument is made for why a machinery-import disequilibrium measure should not be expected to identify a reserve crisis resolved by devaluation---the episode panel is a device for organizing evidence and nothing more. The benchmark set also needs to grow before failure or success on it means much.

\\textbf{RER-only external threshold.} Planned as a comparison and not yet fitted. The previous pipeline found no RER-threshold effect in reduced systems, so the comparison is expected to be negative; it has not been run on the machinery system and is not claimed either way.

\\textbf{Bootstrap reproducibility.} The S40 ledgers consumed here were produced before the estimation script set a random seed. The reported bootstrap $p$-values are therefore not exactly reproducible, which is why their Monte Carlo standard errors appear in Table~\\ref{tab:tests}. The script now seeds the bootstrap, so subsequent runs are reproducible and will differ from these figures within simulation error.

\\FloatBarrier
\\section{Next empirical decision}

The decision rule set before estimation was explicit: proceed to threshold-aware analysis if the Hansen--Seo bootstrap rejected linearity at 5\\%, and treat the linear VECM as adequate otherwise. No sample rejects. The linear VECM is the specification for inference, and the threshold branch closes.

Three steps follow. Resolve machinery's integration order, since that blocks the long-run system regardless of what the adjustment dynamics turn out to be. Report the linear machinery relation alongside the ARDL fallback, with the I(2) limitation stated rather than managed. Keep the ECT chronology as a screening layer for organizing historical evidence, and extend the external benchmark set beyond 1961 so that the screen faces a real test rather than a single date.

\\FloatBarrier
\\section*{Data availability and reproducibility}

The frozen release is \\texttt{data/releases/chile\\_bop\\_binding\\_v1\\_1/}. Every table and figure in this report is copied from a completed stage ledger; the report builder performs no estimation and records the SHA-256 hash of each consumed input in \\texttt{output/CL/BOP\\_BINDING\\_V6/S99\\_REPORT\\_ASSEMBLY/}. Staged ledgers accompany the report in \\texttt{data/}. Stage integrity ledgers for S30, S32, S40, and S50 all report passing checks, and the builder refuses to assemble if any of them fails.

\\textbf{Ethics.} The study uses historical aggregate data and involves no human subjects.

\\textbf{AI-use disclosure.} Claude Code assisted with reproducible code, diagnostics, evidence organization, and report assembly under human direction. All claims are auditable against the frozen release and the staged stage ledgers.

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
Ffrench-Davis, R. (1983b). Deuda externa y balanza de pagos de América Latina: Tendencias recientes y perspectivas. \\textit{Estudios Internacionales, 16}(62), 281--304. \\url{https://doi.org/10.5354/0719-3769.1983.16673}

\\bibitem[Ffrench-Davis(2002)]{ffd2002}
Ffrench-Davis, R. (2002). \\textit{Economic reforms in Chile: From dictatorship to democracy}. University of Michigan Press. \\url{https://doi.org/10.3998/mpub.17208}

\\bibitem[Kaldor(1967)]{kaldor1967}
Kaldor, N. (1967). \\textit{Strategic factors in economic development}. Cornell University.

\\bibitem[Kaldor(1970)]{kaldor1970}
Kaldor, N. (1970). The case for regional policies. \\textit{Scottish Journal of Political Economy, 17}(3), 337--348. \\url{https://doi.org/10.1111/j.1467-9485.1970.tb00712.x}

\\bibitem[Marconi et al.(2016)]{marconi2016}
Marconi, N., Reis, C. F. de B., \\& Araújo, E. C. de. (2016). Manufacturing and economic development: The actuality of Kaldor's first and second laws. \\textit{Structural Change and Economic Dynamics, 37}, 75--89. \\url{https://doi.org/10.1016/j.strueco.2015.12.002}

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

\\bibitem[Yunga Medina et al.(2022)]{yunga2022}
Yunga Medina, F., Tapia Morquecho, C., Camacho Manzanillas, S., \\& Cueva Jiménez, A. (2022). Does the balance of payments constrain economic growth? New evidence for Chile 1980--2019. \\textit{Boletín de Coyuntura, 35}, 25--35. \\url{https://doi.org/10.31243/bcoyu.35.2022.1851}

\\end{thebibliography}
\\end{document}
")
report_tex <- gsub("\\begin{table}[h!]", "\\begin{table}[H]", report_tex,
                   fixed = TRUE)
report_tex <- gsub("\\begin{figure}[h!]", "\\begin{figure}[H]", report_tex,
                   fixed = TRUE)

tex_file <- file.path(report_dir, "chile_bop_binding_report_v6.tex")
writeLines(report_tex, tex_file, useBytes = TRUE)

# ---------------------------------------------------------------------------
# Assembly summary and SHA-256 manifest.
# ---------------------------------------------------------------------------
assembly_summary <- data.frame(
  object = c(
    "frozen release coverage", "pre sample", "post sample",
    "machinery elasticity range",
    "Hansen-Seo bootstrap p, full", "Hansen-Seo bootstrap p, pre-1974",
    "Hansen-Seo bootstrap p, post-1974",
    "threshold effect significant at 5 percent",
    "inference specification",
    "confirmed binding years, full sample",
    "ECT dating offset detected", "ECT dating match precision",
    "1961 benchmark, full sample", "1961 benchmark, pre-1974 sample",
    "bootstrap seed present in consumed ledgers",
    "report estimates models"
  ),
  value = c(
    "1920-2024 (N=105)", "1920-1973 (N=54)", "1974-2024 (N=51)",
    paste0(fmt(elast_lo, 3), " to ", fmt(elast_hi, 3)),
    fmt(hs[["full_1920_2024"]]$p_value, 6), fmt(pre_p, 6),
    fmt(hs[["post_1974_2024"]]$p_value, 6),
    "no", "linear VECM", as.character(full_conf),
    paste(unique(ect_dating$year_correction), "year(s)"),
    formatC(max(ect_dating$max_abs_deviation), format = "e", digits = 2),
    bench_full$benchmark_agreement[1], bench_pre$benchmark_agreement[1],
    if ("bootstrap_seed" %in% names(tvecm_model)) "yes" else "no",
    "no"
  ),
  stringsAsFactors = FALSE
)
write.csv(assembly_summary,
          file.path(assembly_dir, "report_result_summary_v6.csv"),
          row.names = FALSE)

manifest <- data.frame(
  role = c(rep("consumed_input", length(inputs)),
           rep("approved_figure", length(figure_sources)),
           "report_markdown", "report_latex"),
  file = normalizePath(c(unname(inputs), unname(figure_sources), md_file,
                         tex_file),
                       winslash = "/", mustWork = TRUE),
  stringsAsFactors = FALSE
)
manifest$sha256 <- vapply(manifest$file, digest, character(1),
                          algo = "sha256", file = TRUE)
write.csv(manifest,
          file.path(assembly_dir, "report_assembly_sha256_manifest_v6.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# Compile.
# ---------------------------------------------------------------------------
pdflatex <- Sys.which("pdflatex")
compile_status <- "pdflatex_not_found"
if (nzchar(pdflatex)) {
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(report_dir)
  compile_args <- c("-interaction=nonstopmode", "-halt-on-error",
                    basename(tex_file))
  first <- system2(pdflatex, compile_args, stdout = TRUE, stderr = TRUE)
  first_status <- attr(first, "status")
  if (is.null(first_status)) first_status <- 0L
  if (first_status == 0L) {
    second <- system2(pdflatex, compile_args, stdout = TRUE, stderr = TRUE)
    second_status <- attr(second, "status")
    if (is.null(second_status)) second_status <- 0L
    compile_status <- if (second_status == 0L) "compiled" else "second_pass_failed"
    if (second_status != 0L) writeLines(tail(second, 40))
  } else {
    compile_status <- "first_pass_failed"
    writeLines(tail(first, 40))
  }
  setwd(old_wd)
}
message("S99 v6 report assembly complete: ", report_dir)
message("pdflatex status: ", compile_status)
if (!identical(compile_status, "compiled")) {
  message("PDF not produced; Markdown and LaTeX sources are written.")
}
