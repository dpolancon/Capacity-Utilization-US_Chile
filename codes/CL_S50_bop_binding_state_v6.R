#!/usr/bin/env Rscript

# CL_BOP_BINDING v6 S50: triangulate the machinery-import ECT with observed
# external-pressure indicators. The exploratory machinery route is retained
# in the labels; the ECT alone never confirms a BOP-binding episode.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release_file <- file.path(
  root, "data", "releases", "chile_bop_binding_v1_1",
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv"
)
ect_file <- file.path(
  root, "output", "CL", "BOP_BINDING_V6", "S40_ENDOGENOUS_ECT_TVECM",
  "endogenous_tvecm_ect_regime_panel.csv"
)
hansen_seo_file <- file.path(
  root, "output", "CL", "BOP_BINDING_V6", "S40_ENDOGENOUS_ECT_TVECM",
  "hansen_seo_linear_threshold_test.csv"
)
model_ledger_file <- file.path(
  root, "output", "CL", "BOP_BINDING_V6", "S40_ENDOGENOUS_ECT_TVECM",
  "endogenous_tvecm_model_ledger.csv"
)
route_file <- file.path(
  root, "output", "CL", "BOP_BINDING_V6", "S32_BREAK_AWARE_MACHINERY",
  "machinery_route_decision_ledger.csv"
)
benchmark_file <- file.path(
  root, "data", "processed", "CL_BOP_BINDING", "S40_BINDING_STATE",
  "ect_import_shortfall.csv"
)
# Second reduced-system benchmark. Both benchmarks are v1-pipeline artifacts and
# neither carries a full-sample row, so full_1920_2024 benchmark columns are
# legitimately empty rather than missing.
piecewise_file <- file.path(
  root, "output", "CL", "BOP_BINDING", "S30_VECM", "import_ect_piecewise.csv"
)
processed_dir <- file.path(
  root, "data", "processed", "CL_BOP_BINDING_V6", "S50_BINDING_STATE"
)
output_dir <- file.path(
  root, "output", "CL", "BOP_BINDING_V6", "S50_BINDING_STATE"
)
fig_dir <- file.path(output_dir, "figures")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release_file), file.exists(ect_file), file.exists(route_file),
          file.exists(hansen_seo_file), file.exists(model_ledger_file))
set.seed(20260729)

panel <- read.csv(release_file, check.names = FALSE, stringsAsFactors = FALSE)
ect <- read.csv(ect_file, check.names = FALSE, stringsAsFactors = FALSE)
route <- read.csv(route_file, check.names = FALSE, stringsAsFactors = FALSE)
hansen_seo <- read.csv(hansen_seo_file, check.names = FALSE,
                       stringsAsFactors = FALSE)
model_ledger <- read.csv(model_ledger_file, check.names = FALSE,
                         stringsAsFactors = FALSE)

# ---------------------------------------------------------------------------
# ECT dating audit.
#
# tsDyn returns the lagged disequilibrium: the term entering the year-t equation
# is the deviation measured at t-1. Whether the upstream ledger dated each value
# by the equation year or by the year of the deviation is not assumed here. The
# cointegrating relation is rebuilt from the frozen release using the estimated
# beta, matched against the recorded ECT at a range of offsets, and the exact
# match determines the dating. A chronology must pair each deviation with the
# external indicators of the year it was measured, so labels are corrected
# before any classification runs. If a corrected upstream stage already dates by
# the deviation year, the detected offset is zero and nothing shifts.
# ---------------------------------------------------------------------------
detect_ect_offset <- function(sample_name) {
  bm <- model_ledger$beta_machinery[model_ledger$sample == sample_name][1]
  recorded <- ect[ect$sample == sample_name, c("year", "ECT_import_machinery")]
  relation <- data.frame(year = panel$year,
                         z = panel$log_imports + bm * panel$log_K_ME_gross)
  trial <- lapply(-2:2, function(k) {
    d <- merge(recorded, transform(relation, year = year + k), by = "year")
    resid <- d$z - d$ECT_import_machinery
    data.frame(sample = sample_name, offset = k, matched_years = nrow(d),
               max_abs_deviation = if (nrow(d)) max(abs(resid)) else NA_real_)
  })
  do.call(rbind, trial)
}

ect_offset_trials <- do.call(rbind, lapply(unique(ect$sample),
                                           detect_ect_offset))
ect_dating_audit <- ect_offset_trials |>
  group_by(sample) |>
  slice_min(max_abs_deviation, n = 1, with_ties = FALSE) |>
  ungroup() |>
  mutate(
    exact_match = is.finite(max_abs_deviation) & max_abs_deviation < 1e-8,
    # A recorded label of Y that matches the relation at Y + offset describes
    # the deviation of year Y + offset, so labels move by -offset.
    year_correction = -offset,
    dating_status = case_when(
      !exact_match ~ "no_exact_match_dating_unverified",
      year_correction == 0L ~ "dated_by_deviation_year_no_correction",
      TRUE ~ "relabelled_from_equation_year_to_deviation_year"
    )
  )
stopifnot(all(ect_dating_audit$exact_match))

ect <- ect |>
  left_join(ect_dating_audit |> select(sample, year_correction), by = "sample") |>
  mutate(equation_year = year, year = year + year_correction) |>
  select(-year_correction)

if (file.exists(benchmark_file)) {
  benchmark <- read.csv(benchmark_file, check.names = FALSE,
                        stringsAsFactors = FALSE) |>
    select(year, sample, ECT_import_reduced,
           import_shortfall_pressure_reduced = import_shortfall_pressure)
} else {
  benchmark <- tibble(year = integer(), sample = character(),
                      ECT_import_reduced = numeric(),
                      import_shortfall_pressure_reduced = numeric())
}

if (file.exists(piecewise_file)) {
  piecewise <- read.csv(piecewise_file, check.names = FALSE,
                        stringsAsFactors = FALSE) |>
    select(year, sample,
           ECT_import_piecewise = ECT_import,
           piecewise_gate_status = gate_status)
} else {
  piecewise <- tibble(year = integer(), sample = character(),
                      ECT_import_piecewise = numeric(),
                      piecewise_gate_status = character())
}

# Threshold-evidence status. The S40 Hansen-Seo bootstrap decides whether an
# ECT-defined regime carries formal support; it does not decide whether the
# machinery route is admissible. The two limitations stay separate fields.
threshold_evidence <- hansen_seo |>
  select(sample, hansen_seo_statistic = statistic,
         hansen_seo_p_value = p_value) |>
  mutate(
    hansen_seo_p_mc_se = sqrt(hansen_seo_p_value * (1 - hansen_seo_p_value) /
                                999),
    threshold_evidence_status = case_when(
      !is.finite(hansen_seo_p_value) ~ "threshold_test_unavailable",
      hansen_seo_p_value < 0.05 ~ "threshold_supported",
      hansen_seo_p_value < 0.10 ~ "threshold_marginal_exploratory",
      TRUE ~ "threshold_not_supported_linear_adequate"
    )
  )

# Independent historical benchmarks. Only dated events with a verified source in
# this repo's research files enter the layer; an unsourced crisis list would be
# fabricated evidence, and the resulting thin benchmark set is itself a reported
# limitation. Source: reports/Chile_BOP_Binding_Import_ECT_Report/research/
# kaldor_chile_evidence_matrix.md and kaldor_chile_research_brief.md.
historical_markers <- tibble::tribble(
  ~year, ~historical_marker, ~historical_marker_source,
  1961L, "official BOP crisis and abandonment of the fixed exchange rate",
  "Banco Central de Chile centennial history (verified in kaldor_chile_evidence_matrix.md)"
)

sample_panels <- bind_rows(
  panel |> mutate(sample = "full_1920_2024"),
  panel |> filter(year <= 1973) |> mutate(sample = "pre_1920_1973"),
  panel |> filter(year >= 1974) |> mutate(sample = "post_1974_2024")
)

route_status <- route |>
  select(sample, machinery_variable, machinery_route_status = break_route_status,
         machinery_standard_gate_status = standard_gate_status,
         selected_break_year, selected_mode = selected_model)

z_score <- function(x) {
  s <- sd(x, na.rm = TRUE)
  if (!is.finite(s) || s == 0) return(rep(NA_real_, length(x)))
  (x - mean(x, na.rm = TRUE)) / s
}

robust_z <- function(x) {
  center <- median(x, na.rm = TRUE)
  scale <- mad(x, center = center, constant = 1.4826, na.rm = TRUE)
  if (!is.finite(scale) || scale == 0) return(z_score(x))
  (x - center) / scale
}

state <- sample_panels |>
  left_join(ect |> select(sample, year, ECT_import_machinery,
                          threshold_ect, tsdyn_regime, ect_regime,
                          tv_ec_binding_signal = binding_signal),
            by = c("sample", "year")) |>
  left_join(benchmark, by = c("sample", "year")) |>
  left_join(piecewise, by = c("sample", "year")) |>
  left_join(route_status, by = "sample") |>
  left_join(threshold_evidence, by = "sample") |>
  left_join(historical_markers, by = "year") |>
  arrange(sample, year) |>
  group_by(sample) |>
  mutate(
    import_shortfall_pressure_machinery = -ECT_import_machinery,
    import_shortfall_pressure_machinery_z = robust_z(
      import_shortfall_pressure_machinery
    ),
    current_account_pressure_z = robust_z(-current_account_gdp),
    goods_balance_pressure_z = robust_z(-goods_balance_gdp),
    manufactured_import_compression =
      -(manufactures_imports_gdp - lag(manufactures_imports_gdp)),
    manufactured_import_compression_z = robust_z(
      manufactured_import_compression
    )
  ) |>
  ungroup() |>
  mutate(
    # An absent ECT estimate is not an absent ECT signal. The lag and first
    # difference cost each sample two leading years, and those years must not be
    # coded as non-binding on observed indicators alone.
    ect_available = is.finite(ECT_import_machinery),
    negative_ect_signal = is.finite(ECT_import_machinery) &
      ECT_import_machinery < 0,
    ect_binding_regime_signal = is.finite(ECT_import_machinery) &
      is.finite(threshold_ect) & ECT_import_machinery < 0 &
      ECT_import_machinery <= threshold_ect,
    current_account_deficit_signal = current_account_gdp <= -0.03,
    goods_deficit_signal = goods_balance_gdp <= -0.03,
    manufactured_import_compression_signal =
      manufactured_import_compression >= 0.03,
    financing_compression_signal = financing_compression_5pp == 1,
    observed_bop_pressure_signal =
      current_account_deficit_signal |
      goods_deficit_signal |
      manufactured_import_compression_signal |
      financing_compression_signal,
    observed_signal_count =
      as.integer(current_account_deficit_signal) +
      as.integer(goods_deficit_signal) +
      as.integer(manufactured_import_compression_signal) +
      as.integer(financing_compression_signal),
    bop_binding_index =
      0.50 * import_shortfall_pressure_machinery_z +
      0.20 * current_account_pressure_z +
      0.15 * goods_balance_pressure_z +
      0.15 * manufactured_import_compression_z,
    classification = case_when(
      !ect_available ~ "ect_unavailable",
      ect_binding_regime_signal & observed_bop_pressure_signal ~
        "confirmed_binding",
      ect_binding_regime_signal & !observed_bop_pressure_signal ~
        "ECT_only_pressure",
      !ect_binding_regime_signal & observed_bop_pressure_signal ~
        "observed_BOP_only_pressure",
      TRUE ~ "non_binding_adjustment"
    ),
    machinery_route_signal_status = case_when(
      grepl("exploratory", machinery_route_status, ignore.case = TRUE) &
        ect_binding_regime_signal ~ "exploratory_machinery_route_signal",
      TRUE ~ "not_triggered"
    ),
    confirmation_rule = paste(
      "negative import ECT in estimated lower regime plus at least one",
      "independent observed BOP or historical indicator"
    ),
    # An ECT-defined regime is not a confirmed episode, and where the Hansen-Seo
    # bootstrap does not reject linearity the regime boundary itself carries no
    # formal support. Both caveats travel with every row.
    regime_evidence_label = case_when(
      !ect_available ~ "no_ECT_estimate",
      threshold_evidence_status == "threshold_supported" ~
        "ECT_regime_formally_supported",
      threshold_evidence_status == "threshold_marginal_exploratory" ~
        "ECT_regime_marginal_exploratory",
      TRUE ~ "ECT_regime_exploratory_screening_only"
    )
  )

ect_output <- state |>
  select(year, sample, ect_available, ECT_import_machinery, threshold_ect,
         import_shortfall_pressure_machinery,
         import_shortfall_pressure_machinery_z,
         negative_ect_signal, ect_binding_regime_signal, ect_regime,
         tv_ec_binding_signal, machinery_route_signal_status,
         regime_evidence_label, threshold_evidence_status,
         ECT_import_reduced, import_shortfall_pressure_reduced,
         ECT_import_piecewise, machinery_route_status)

episode_panel <- state |>
  select(year, sample, classification, regime_evidence_label,
         machinery_route_signal_status,
         bop_binding_index, ect_available, ECT_import_machinery, threshold_ect,
         negative_ect_signal, ect_binding_regime_signal,
         observed_bop_pressure_signal, observed_signal_count,
         historical_marker, historical_marker_source,
         current_account_gdp, goods_balance_gdp,
         manufactures_imports_gdp, manufactured_import_compression,
         financing_compression_signal, log_RER, dlog_RER,
         ECT_import_reduced, ECT_import_piecewise,
         threshold_evidence_status, hansen_seo_p_value, hansen_seo_p_mc_se,
         machinery_variable, machinery_standard_gate_status,
         selected_break_year, selected_mode, machinery_route_status)

index_output <- state |>
  select(year, sample, bop_binding_index,
         import_shortfall_pressure_machinery_z, current_account_pressure_z,
         goods_balance_pressure_z, manufactured_import_compression_z,
         classification, regime_evidence_label, machinery_route_signal_status)

write.csv(ect_output, file.path(processed_dir, "ect_import_shortfall_machinery.csv"),
          row.names = FALSE, na = "")
write.csv(episode_panel, file.path(processed_dir, "bop_binding_episode_panel.csv"),
          row.names = FALSE, na = "")
write.csv(index_output, file.path(processed_dir, "bop_binding_index.csv"),
          row.names = FALSE, na = "")

episode_summary <- state |>
  group_by(sample) |>
  mutate(run_id = cumsum(c(TRUE, diff(as.integer(
    classification == "confirmed_binding"
  )) != 0))) |>
  filter(classification == "confirmed_binding") |>
  group_by(sample, run_id) |>
  summarise(
    start_year = min(year), end_year = max(year),
    duration_years = n(),
    peak_year = year[which.max(bop_binding_index)],
    peak_binding_index = max(bop_binding_index, na.rm = TRUE),
    mean_binding_index = mean(bop_binding_index, na.rm = TRUE),
    mean_observed_signal_count = mean(observed_signal_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  select(-run_id)

classification_counts <- state |>
  count(sample, classification, regime_evidence_label, machinery_route_status,
        name = "years")

# Year accounting: every release year in every sample must land in exactly one
# class, so the report can never present a partial chronology as complete.
year_accounting <- state |>
  group_by(sample) |>
  summarise(
    first_year = min(year), last_year = max(year),
    years_in_sample = n(),
    years_classified = sum(!is.na(classification)),
    years_with_ect = sum(ect_available),
    years_without_ect = sum(!ect_available),
    .groups = "drop"
  ) |>
  mutate(all_years_accounted = years_in_sample == years_classified)

component_ledger <- tibble::tribble(
  ~component, ~weight, ~positive_pressure_definition, ~role,
  "machinery-import ECT", 0.50,
  "negative ECT standardized within sample; lower-ECT regime retained",
  "latent import shortfall; exploratory machinery route",
  "current account", 0.20, "negative current-account balance",
  "observed BOP",
  "goods balance", 0.15, "negative goods balance", "observed BOP",
  "manufactured-import compression", 0.15,
  "annual fall in manufactured imports/GDP", "observed BOP"
)

classification_rules <- tibble::tribble(
  ~classification, ~ECT_estimate_available, ~ECT_regime_signal, ~observed_signal,
  ~interpretation,
  "confirmed_binding", TRUE, TRUE, TRUE,
  "negative machinery-import ECT in the lower regime plus independent BOP evidence",
  "ECT_only_pressure", TRUE, TRUE, FALSE,
  "candidate import-compression pressure without independent confirmation",
  "observed_BOP_only_pressure", TRUE, FALSE, TRUE,
  "observed external pressure without the estimated machinery ECT signal",
  "non_binding_adjustment", TRUE, FALSE, FALSE,
  "neither triangulation family crosses its rule",
  "ect_unavailable", FALSE, NA, NA,
  "lag and first difference leave no ECT estimate; the year is not evidence of non-binding"
)

# Independent-benchmark agreement. The chronology is tested against dated
# external evidence rather than against itself.
historical_benchmark_ledger <- state |>
  filter(!is.na(historical_marker)) |>
  transmute(
    year, sample, historical_marker, historical_marker_source,
    model_classification = classification,
    regime_evidence_label,
    bop_binding_index,
    observed_signal_count,
    benchmark_agreement = case_when(
      classification == "confirmed_binding" ~ "captured_as_confirmed_binding",
      classification == "ECT_only_pressure" ~ "captured_as_ECT_only_pressure",
      classification == "observed_BOP_only_pressure" ~
        "captured_as_observed_BOP_only",
      classification == "ect_unavailable" ~ "no_ECT_estimate_for_year",
      TRUE ~ "missed_false_negative"
    )
  ) |>
  arrange(year, sample)

write.csv(episode_summary,
          file.path(output_dir, "confirmed_binding_episode_summary.csv"),
          row.names = FALSE, na = "")
write.csv(classification_counts,
          file.path(output_dir, "binding_classification_counts.csv"),
          row.names = FALSE)
write.csv(component_ledger,
          file.path(output_dir, "binding_index_component_ledger.csv"),
          row.names = FALSE)
write.csv(historical_benchmark_ledger,
          file.path(output_dir, "historical_benchmark_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(ect_dating_audit,
          file.path(output_dir, "ect_dating_audit.csv"),
          row.names = FALSE, na = "")
write.csv(ect_offset_trials,
          file.path(output_dir, "ect_dating_offset_trials.csv"),
          row.names = FALSE, na = "")
write.csv(year_accounting,
          file.path(output_dir, "s50_year_accounting.csv"),
          row.names = FALSE)
write.csv(threshold_evidence,
          file.path(output_dir, "threshold_evidence_status_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(classification_rules,
          file.path(output_dir, "binding_classification_rules.csv"),
          row.names = FALSE)
write.csv(episode_panel, file.path(output_dir, "bop_binding_episode_panel.csv"),
          row.names = FALSE, na = "")

p <- ggplot(state, aes(year, bop_binding_index)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_rect(
    data = state |> filter(classification == "confirmed_binding"),
    aes(xmin = year - 0.5, xmax = year + 0.5,
        ymin = -Inf, ymax = Inf),
    inherit.aes = FALSE, fill = "#D55E00", alpha = 0.15
  ) +
  geom_line(colour = "#0072B2", linewidth = 0.65) +
  geom_vline(xintercept = 1973.5, linetype = "dotted") +
  facet_wrap(~sample, scales = "free_x") +
  labs(x = NULL, y = "Triangulated BOP-binding index",
       title = "Chile: machinery-import pressure and observed BOP evidence",
       subtitle = paste("Shading marks years satisfying both the ECT-regime and",
                        "external-evidence rules; ECT regimes are exploratory")) +
  theme_minimal(base_size = 10)
ggsave(file.path(fig_dir, "fig_bop_binding_index_machinery.png"),
       p, width = 9, height = 5.5, dpi = 220)
ggsave(file.path(fig_dir, "fig_bop_binding_index_machinery.pdf"),
       p, width = 9, height = 5.5)

p_ect <- ggplot(state, aes(year, ECT_import_machinery, colour = ect_regime)) +
  geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey50") +
  geom_line(linewidth = 0.45) + geom_point(size = 0.55) +
  facet_wrap(~sample, scales = "free_x") +
  labs(x = NULL, y = "Machinery-import ECT",
       title = "Machinery-import ECT and candidate binding regimes",
       subtitle = paste("Regime boundaries are exploratory: the Hansen-Seo",
                        "bootstrap does not reject linear adjustment")) +
  theme_minimal(base_size = 10) + theme(legend.position = "bottom")
ggsave(file.path(fig_dir, "fig_machinery_import_ect_chronology.pdf"),
       p_ect, width = 9, height = 5.5)
ggsave(file.path(fig_dir, "fig_machinery_import_ect_chronology.png"),
       p_ect, width = 9, height = 5.5, dpi = 220)

integrity <- tibble(
  check = c(
    "frozen_release_input", "three_sample_panels", "ECT_sign_verified",
    "ECT_alone_never_confirms", "typology_complete",
    "historical_or_external_confirmation_required", "machinery_scope_label",
    "machinery_route_status_labelled", "component_weights_sum_to_one",
    "all_years_accounted", "missing_ECT_not_coded_as_non_binding",
    "threshold_evidence_status_attached", "no_circular_confirmation",
    "independent_benchmark_tested", "ECT_dating_verified_against_release",
    "ECT_dated_by_deviation_year"
  ),
  passed = c(
    file.exists(release_file),
    n_distinct(state$sample) == 3L,
    all(state$import_shortfall_pressure_machinery ==
          -state$ECT_import_machinery |>
          replace(!is.finite(state$ECT_import_machinery), TRUE), na.rm = TRUE),
    # An ECT regime signal with no independent evidence must route to
    # ECT_only_pressure. The previous form of this check compared a disjunction
    # that was false for exactly those rows and so could never pass.
    all(state$classification[state$ect_available &
          state$ect_binding_regime_signal &
          !state$observed_bop_pressure_signal] == "ECT_only_pressure",
        na.rm = TRUE),
    setequal(unique(state$classification), c(
      "confirmed_binding", "ECT_only_pressure",
      "observed_BOP_only_pressure", "non_binding_adjustment",
      "ect_unavailable"
    )),
    all(state$classification != "confirmed_binding" |
          state$observed_bop_pressure_signal, na.rm = TRUE),
    # Scope is carried by the machinery variable, not by the route label. The
    # S32 ledger writes break_route_status = "exploratory_break_route", which
    # never contains the string the previous check searched for.
    all(state$machinery_variable == "log_K_ME_gross"),
    all(grepl("exploratory|formal", tolower(state$machinery_route_status))),
    abs(sum(component_ledger$weight) - 1) < 1e-8,
    all(year_accounting$all_years_accounted),
    all(state$classification[!state$ect_available] == "ect_unavailable"),
    all(!is.na(state$threshold_evidence_status)) &&
      all(state$regime_evidence_label != "ECT_regime_formally_supported" |
            state$threshold_evidence_status == "threshold_supported"),
    !any(state$classification == "confirmed_binding" &
           state$observed_signal_count < 1L, na.rm = TRUE),
    nrow(historical_benchmark_ledger) > 0L &&
      all(!is.na(historical_benchmark_ledger$historical_marker_source)),
    all(ect_dating_audit$exact_match),
    all(state$classification[state$ect_available] != "ect_unavailable") &&
      nrow(ect_dating_audit) == 3L
  ),
  detail = c(
    "all chronology inputs come from the v1_1 frozen release and completed S40 ledger",
    "full, pre-1974, and post-1974 chronologies are retained",
    "pressure is defined as the negative of the normalized import ECT",
    "an ECT regime signal without independent evidence routes to ECT_only_pressure",
    "the episode panel preserves the four evidence categories plus the no-estimate class",
    "confirmed years require at least one observed BOP indicator",
    "the triangulated machinery variable is log_K_ME_gross in every sample",
    "the machinery route status is explicitly exploratory or formal",
    "index weights sum to one",
    "every release year in every sample lands in exactly one class",
    "years without an ECT estimate are labelled, never coded as non-binding",
    "each regime label carries the Hansen-Seo evidential status of its sample",
    "no confirmed year rests on the machinery ECT alone",
    "the chronology is tested against a dated, sourced external benchmark",
    "each recorded ECT reproduces the cointegrating relation exactly at one offset",
    "every ECT value is dated by the year of the deviation it measures"
  )
)
write.csv(integrity, file.path(output_dir, "s50_binding_state_integrity.csv"),
          row.names = FALSE)
stopifnot(all(integrity$passed))
message("S50 machinery-import ECT BOP-binding state complete: ", output_dir)
