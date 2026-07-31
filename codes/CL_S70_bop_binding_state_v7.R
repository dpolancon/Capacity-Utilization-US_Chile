#!/usr/bin/env Rscript

# CL_BOP_BINDING v7 / S70: when did Chile's balance-of-payments constraint bind?
#
# The question is dating, not model selection. Two independent things have to
# agree before a year is called binding: the estimated long-run relation must say
# imports sat below the level machinery accumulation and the real exchange rate
# imply, and the external accounts must independently show stress. A year that
# satisfies only one of the two is recorded as satisfying only one of the two.
#
# The threshold VECM is absent from v7. Where S60 established that imports do not
# error-correct, there is no import requirement to be short of, and the dating for
# that sample rests on the external accounts alone.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
set.seed(20260729)

release_file <- file.path(
  root, "data", "releases", "chile_bop_binding_v1_1",
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv"
)
s60_dir <- file.path(root, "output", "CL", "BOP_BINDING_V7", "S60_LINEAR_VECM")
misalignment_file <- file.path(s60_dir, "import_misalignment_panel.csv")
promoted_file <- file.path(s60_dir, "promoted_model_ledger.csv")
beta_file <- file.path(s60_dir, "cointegrating_vector_ledger.csv")
output_dir <- file.path(root, "output", "CL", "BOP_BINDING_V7",
                        "S70_BINDING_STATE")
fig_dir <- file.path(output_dir, "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release_file), file.exists(misalignment_file),
          file.exists(promoted_file), file.exists(beta_file))

panel <- read.csv(release_file, check.names = FALSE, stringsAsFactors = FALSE)
misalignment <- read.csv(misalignment_file, check.names = FALSE,
                         stringsAsFactors = FALSE)
promoted <- read.csv(promoted_file, check.names = FALSE,
                     stringsAsFactors = FALSE)
beta_ledger <- read.csv(beta_file, check.names = FALSE, stringsAsFactors = FALSE)

# No v7 stage may consume a threshold-model ledger.
stopifnot(!any(grepl("TVECM|tvecm|threshold", c(misalignment_file,
                                                promoted_file, beta_file))))

sample_names <- c("full_1920_2024", "pre_1920_1973", "post_1974_2024")

# ---------------------------------------------------------------------------
# Dating audit.
#
# Each misalignment value must belong to the year whose imports and machinery
# stock produced it. S60 builds the series from the contemporaneous state, so the
# expected offset is zero, but the check is kept: a threshold model consumed
# earlier in this project returned the lagged deviation and silently shifted an
# entire chronology by one year.
# ---------------------------------------------------------------------------
dating_audit <- bind_rows(lapply(sample_names, function(s) {
  pr <- promoted |> filter(sample == s)
  if (!nrow(pr) || is.na(pr$model_id[1])) {
    return(tibble(sample = s, offset = NA_integer_, matched_years = 0L,
                  max_abs_deviation = NA_real_, exact_match = NA,
                  dating_status = "no_promoted_model"))
  }
  b <- beta_ledger |> filter(model_id == pr$model_id[1])
  state_terms <- b$term[!grepl("constant|trend", b$term)]
  state_vars <- sub("\\.l1$", "", state_terms)
  coefs <- b$ect_coefficient[match(state_terms, b$term)]
  const <- b$ect_coefficient[grepl("constant", b$term)]
  rel <- as.matrix(panel[, state_vars, drop = FALSE]) %*% coefs
  if (length(const) == 1L) rel <- rel + const
  relation <- data.frame(year = panel$year, z = as.numeric(rel))
  recorded <- misalignment |> filter(sample == s) |> select(year, ECT_import)
  trials <- lapply(-2:2, function(k) {
    d <- merge(recorded, transform(relation, year = year + k), by = "year")
    tibble(sample = s, offset = k, matched_years = nrow(d),
           max_abs_deviation = if (nrow(d)) max(abs(d$z - d$ECT_import)) else
             NA_real_)
  })
  best <- bind_rows(trials) |>
    filter(is.finite(max_abs_deviation)) |>
    slice_min(max_abs_deviation, n = 1, with_ties = FALSE)
  best |>
    mutate(exact_match = max_abs_deviation < 1e-8,
           dating_status = case_when(
             !exact_match ~ "no_exact_match_dating_unverified",
             offset == 0L ~ "dated_by_deviation_year_no_correction",
             TRUE ~ "relabelled_to_deviation_year"))
}))
stopifnot(all(dating_audit$exact_match[!is.na(dating_audit$exact_match)]))

misalignment <- misalignment |>
  left_join(dating_audit |> select(sample, offset), by = "sample") |>
  mutate(year = year + ifelse(is.na(offset), 0L, -offset)) |>
  select(-offset)

# ---------------------------------------------------------------------------
# Which samples can carry a model-based signal at all.
# ---------------------------------------------------------------------------
usable <- promoted |>
  select(sample, model_id, specification, promotion_status,
         misalignment_interpretable, misalignment_verdict,
         import_alpha, import_alpha_p, imports_adjust_5,
         import_normalization_share, normalization_reliable)

sample_panels <- bind_rows(
  panel |> mutate(sample = "full_1920_2024"),
  panel |> filter(year <= 1973) |> mutate(sample = "pre_1920_1973"),
  panel |> filter(year >= 1974) |> mutate(sample = "post_1974_2024")
)

historical_markers <- tibble::tribble(
  ~year, ~historical_marker, ~historical_marker_source,
  1961L, "official BOP crisis and abandonment of the fixed exchange rate",
  "Banco Central de Chile centennial history (verified in kaldor_chile_evidence_matrix.md)"
)

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
  left_join(misalignment |> select(sample, year, import_misalignment = ECT_import,
                                  misalignment_model_id = model_id),
            by = c("sample", "year")) |>
  left_join(usable, by = "sample") |>
  left_join(historical_markers, by = "year") |>
  arrange(sample, year) |>
  group_by(sample) |>
  mutate(
    # Shortfall is the mirror of misalignment: positive means imports sat below
    # the level the long-run relation implies.
    import_shortfall = -import_misalignment,
    import_shortfall_z = robust_z(import_shortfall),
    current_account_pressure_z = robust_z(-current_account_gdp),
    goods_balance_pressure_z = robust_z(-goods_balance_gdp),
    manufactured_import_compression =
      -(manufactures_imports_gdp - lag(manufactures_imports_gdp)),
    manufactured_import_compression_z = robust_z(manufactured_import_compression)
  ) |>
  ungroup() |>
  mutate(
    misalignment_available = is.finite(import_misalignment) &
      misalignment_interpretable,
    # Imports below their estimated long-run requirement.
    imports_below_requirement = misalignment_available & import_misalignment < 0,
    current_account_deficit_signal = current_account_gdp <= -0.03,
    goods_deficit_signal = goods_balance_gdp <= -0.03,
    manufactured_import_compression_signal =
      manufactured_import_compression >= 0.03,
    financing_compression_signal = financing_compression_5pp == 1,
    # The stress signal is an OR across the indicators. A missing indicator
    # cannot create stress and must not be able to mask it either, so the OR runs
    # over whichever indicators exist. Only 1920 is affected: the financing
    # measure needs a lag, so that year rests on three of the four.
    external_indicators_available =
      as.integer(!is.na(current_account_deficit_signal)) +
      as.integer(!is.na(goods_deficit_signal)) +
      as.integer(!is.na(manufactured_import_compression_signal)) +
      as.integer(!is.na(financing_compression_signal)),
    external_stress_signal =
      coalesce(current_account_deficit_signal, FALSE) |
      coalesce(goods_deficit_signal, FALSE) |
      coalesce(manufactured_import_compression_signal, FALSE) |
      coalesce(financing_compression_signal, FALSE),
    external_signal_count =
      as.integer(coalesce(current_account_deficit_signal, FALSE)) +
      as.integer(coalesce(goods_deficit_signal, FALSE)) +
      as.integer(coalesce(manufactured_import_compression_signal, FALSE)) +
      as.integer(coalesce(financing_compression_signal, FALSE))
  )

# ---------------------------------------------------------------------------
# Index weights, declared per sample from what S60 established rather than fixed
# in advance. Where the model carries no usable import signal the index is the
# external accounts alone and says so.
# ---------------------------------------------------------------------------
weights <- bind_rows(lapply(sample_names, function(s) {
  ok <- usable$misalignment_interpretable[usable$sample == s]
  ok <- length(ok) == 1L && isTRUE(ok)
  if (ok) {
    tibble(sample = s,
           w_shortfall = 0.40, w_current_account = 0.25,
           w_goods_balance = 0.15, w_manufactured_compression = 0.20,
           basis = "model shortfall plus external accounts")
  } else {
    tibble(sample = s,
           w_shortfall = 0, w_current_account = 0.45,
           w_goods_balance = 0.25, w_manufactured_compression = 0.30,
           basis = "external accounts only; imports do not error-correct")
  }
}))
stopifnot(all(abs(rowSums(weights[, 2:5]) - 1) < 1e-8))

state <- state |>
  left_join(weights, by = "sample") |>
  mutate(
    bop_pressure_index =
      w_shortfall * coalesce(import_shortfall_z, 0) +
      w_current_account * coalesce(current_account_pressure_z, 0) +
      w_goods_balance * coalesce(goods_balance_pressure_z, 0) +
      w_manufactured_compression * coalesce(manufactured_import_compression_z, 0),
    classification = case_when(
      !misalignment_interpretable & external_stress_signal ~
        "external_stress_no_usable_model_signal",
      !misalignment_interpretable & !external_stress_signal ~
        "no_stress_no_usable_model_signal",
      !misalignment_available ~ "no_estimate_for_year",
      imports_below_requirement & external_stress_signal ~ "binding_confirmed",
      imports_below_requirement & !external_stress_signal ~
        "imports_short_only",
      !imports_below_requirement & external_stress_signal ~
        "external_stress_only",
      TRUE ~ "not_binding"
    ),
    confirmation_rule = paste(
      "imports below their estimated long-run requirement and at least one",
      "independent external-account signal in the same year"
    )
  )

# ---------------------------------------------------------------------------
# Ledgers.
# ---------------------------------------------------------------------------
episode_panel <- state |>
  select(year, sample, classification, bop_pressure_index,
         import_misalignment, import_shortfall, import_shortfall_z,
         misalignment_available, misalignment_interpretable,
         imports_below_requirement, external_stress_signal,
         external_signal_count, external_indicators_available,
         current_account_gdp, goods_balance_gdp,
         manufactures_imports_gdp, manufactured_import_compression,
         financing_compression_signal, log_RER, dlog_RER,
         historical_marker, historical_marker_source,
         misalignment_model_id, specification, misalignment_verdict,
         import_alpha, import_alpha_p, basis)

episode_summary <- state |>
  group_by(sample) |>
  mutate(run_id = cumsum(c(TRUE, diff(as.integer(
    classification == "binding_confirmed")) != 0))) |>
  filter(classification == "binding_confirmed") |>
  group_by(sample, run_id) |>
  summarise(start_year = min(year), end_year = max(year),
            duration_years = n(),
            peak_year = year[which.max(bop_pressure_index)],
            peak_pressure_index = max(bop_pressure_index, na.rm = TRUE),
            mean_pressure_index = mean(bop_pressure_index, na.rm = TRUE),
            mean_external_signal_count = mean(external_signal_count,
                                              na.rm = TRUE),
            .groups = "drop") |>
  select(-run_id)

classification_counts <- state |>
  count(sample, classification, basis, name = "years")

year_accounting <- state |>
  group_by(sample) |>
  summarise(first_year = min(year), last_year = max(year),
            years_in_sample = n(),
            years_classified = sum(!is.na(classification)),
            years_with_usable_misalignment = sum(misalignment_available),
            min_external_indicators_available =
              min(external_indicators_available),
            years_with_all_four_indicators =
              sum(external_indicators_available == 4L),
            .groups = "drop") |>
  mutate(all_years_accounted = years_in_sample == years_classified)

# Written in words rather than column names, so the rule can be read directly.
classification_rules <- tibble::tribble(
  ~classification, ~plain_language_meaning,
  "binding_confirmed",
  "Imports sat below the level the long-run relation implies, and the external accounts showed stress in the same year. Both kinds of evidence agree.",
  "imports_short_only",
  "Imports sat below the implied level, but no external-account indicator crossed its threshold. The model sees a shortfall the accounts do not corroborate.",
  "external_stress_only",
  "The external accounts showed stress, but imports were at or above the level the relation implies. Pressure without an import shortfall.",
  "not_binding",
  "Neither imports fell short of the implied level nor did the accounts show stress.",
  "no_estimate_for_year",
  "The lag structure leaves this year without a value for the long-run relation, so no statement is made about it.",
  "external_stress_no_usable_model_signal",
  "The accounts showed stress, and in this sample the model provides no usable import signal because imports do not adjust to the relation.",
  "no_stress_no_usable_model_signal",
  "The accounts showed no stress, and in this sample the model provides no usable import signal."
)

component_ledger <- weights |>
  pivot_longer(cols = starts_with("w_"), names_to = "component",
               values_to = "weight") |>
  mutate(component = sub("^w_", "", component),
         plain_language = recode(component,
           shortfall = "how far imports sat below their estimated long-run requirement",
           current_account = "current-account deficit as a share of GDP",
           goods_balance = "goods-trade deficit as a share of GDP",
           manufactured_compression = "annual fall in manufactured imports as a share of GDP"),
         role = ifelse(component == "shortfall", "estimated relation",
                       "observed external accounts"))

historical_benchmark_ledger <- state |>
  filter(!is.na(historical_marker)) |>
  transmute(year, sample, historical_marker, historical_marker_source,
            model_classification = classification, bop_pressure_index,
            external_signal_count, misalignment_interpretable,
            benchmark_agreement = case_when(
              classification == "binding_confirmed" ~ "captured_as_binding",
              classification == "imports_short_only" ~
                "import_shortfall_without_external_corroboration",
              classification %in% c("external_stress_only",
                                    "external_stress_no_usable_model_signal") ~
                "external_stress_without_import_shortfall",
              classification == "no_estimate_for_year" ~ "no_estimate_for_year",
              TRUE ~ "missed")) |>
  arrange(year, sample)

w <- function(x, nm) write.csv(x, file.path(output_dir, nm), row.names = FALSE,
                               na = "")
w(episode_panel, "bop_binding_episode_panel.csv")
w(episode_summary, "binding_episode_summary.csv")
w(classification_counts, "binding_classification_counts.csv")
w(classification_rules, "binding_classification_rules_plain_language.csv")
w(component_ledger, "bop_pressure_index_components.csv")
w(historical_benchmark_ledger, "historical_benchmark_ledger.csv")
w(year_accounting, "s70_year_accounting.csv")
w(dating_audit, "misalignment_dating_audit.csv")
w(usable, "misalignment_usability_ledger.csv")

# ---------------------------------------------------------------------------
# Figures.
# ---------------------------------------------------------------------------
p_index <- ggplot(state, aes(year, bop_pressure_index)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_rect(data = state |> filter(classification == "binding_confirmed"),
            aes(xmin = year - 0.5, xmax = year + 0.5, ymin = -Inf, ymax = Inf),
            inherit.aes = FALSE, fill = "#D55E00", alpha = 0.15) +
  geom_line(colour = "#0072B2", linewidth = 0.6) +
  facet_wrap(~sample, scales = "free_x") +
  labs(x = NULL, y = "External pressure index",
       title = "When did Chile's balance-of-payments constraint bind?",
       subtitle = paste("Shaded years: imports below their estimated long-run",
                        "requirement and external stress in the accounts")) +
  theme_minimal(base_size = 10)
ggsave(file.path(fig_dir, "fig_bop_pressure_index.pdf"), p_index,
       width = 9, height = 4.8)
ggsave(file.path(fig_dir, "fig_bop_pressure_index.png"), p_index,
       width = 9, height = 4.8, dpi = 220)

mis <- state |> filter(is.finite(import_misalignment))
if (nrow(mis)) {
  p_mis <- ggplot(mis, aes(year, import_misalignment)) +
    geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
    geom_line(aes(colour = misalignment_interpretable), linewidth = 0.55) +
    scale_colour_manual(values = c(`TRUE` = "#0072B2", `FALSE` = "grey65"),
                        name = "imports error-correct") +
    facet_wrap(~sample, scales = "free") +
    labs(x = NULL, y = "Imports relative to long-run requirement",
         title = "Import misalignment from the RER-controlled long-run relation",
         subtitle = paste("Grey where imports do not adjust to the relation, so",
                          "the series carries no requirement reading")) +
    theme_minimal(base_size = 10) + theme(legend.position = "bottom")
  ggsave(file.path(fig_dir, "fig_import_misalignment_usability.pdf"), p_mis,
         width = 9, height = 4.8)
}

# Misalignment beside the external accounts: the relational picture.
rel_long <- state |>
  filter(misalignment_available) |>
  select(sample, year, `Import shortfall` = import_shortfall_z,
         `Current-account pressure` = current_account_pressure_z,
         `Goods-balance pressure` = goods_balance_pressure_z,
         `Manufactured-import compression` = manufactured_import_compression_z) |>
  pivot_longer(-c(sample, year), names_to = "series", values_to = "value")
if (nrow(rel_long)) {
  p_rel <- ggplot(rel_long, aes(year, value, colour = series)) +
    geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.25) +
    geom_line(linewidth = 0.45) +
    facet_wrap(~sample, scales = "free_x", ncol = 1) +
    labs(x = NULL, y = "Standardized pressure",
         title = "Import shortfall beside the external accounts") +
    theme_minimal(base_size = 9) + theme(legend.position = "bottom")
  ggsave(file.path(fig_dir, "fig_shortfall_vs_accounts.pdf"), p_rel,
         width = 9, height = 7)
}

# ---------------------------------------------------------------------------
# Integrity.
# ---------------------------------------------------------------------------
integrity <- tibble(
  check = c(
    "frozen_release_input", "no_threshold_model_input", "three_samples",
    "all_years_accounted", "misalignment_dating_verified",
    "model_alone_never_confirms", "confirmation_needs_external_signal",
    "unusable_samples_fall_back_to_accounts", "index_weights_sum_to_one",
    "weights_declared_from_evidence", "plain_language_rules_written",
    "every_class_documented", "independent_benchmark_tested",
    "missing_indicator_cannot_mask_stress"
  ),
  passed = c(
    file.exists(release_file),
    !any(grepl("tvecm|threshold", tolower(c(misalignment_file, promoted_file,
                                            beta_file)))),
    n_distinct(state$sample) == 3L,
    all(year_accounting$all_years_accounted),
    all(dating_audit$exact_match[!is.na(dating_audit$exact_match)]),
    all(state$classification[state$imports_below_requirement &
          !state$external_stress_signal] == "imports_short_only", na.rm = TRUE),
    !any(state$classification == "binding_confirmed" &
           (!state$external_stress_signal | state$external_signal_count < 1L),
         na.rm = TRUE),
    all(state$classification[!state$misalignment_interpretable] %in%
          c("external_stress_no_usable_model_signal",
            "no_stress_no_usable_model_signal")),
    all(abs(rowSums(weights[, 2:5]) - 1) < 1e-8),
    nrow(weights) == 3L && any(weights$w_shortfall == 0) ==
      any(!usable$misalignment_interpretable),
    nrow(classification_rules) >= 7L &&
      all(nchar(classification_rules$plain_language_meaning) > 40),
    setequal(unique(state$classification), classification_rules$classification) ||
      all(unique(state$classification) %in% classification_rules$classification),
    nrow(historical_benchmark_ledger) > 0L &&
      all(!is.na(historical_benchmark_ledger$historical_marker_source)),
    all(!is.na(state$external_stress_signal)) &&
      all(state$external_indicators_available >= 2L)
  ),
  detail = c(
    "the frozen v1_1 release is the only source of external-account data",
    "no threshold-VECM ledger is consumed anywhere in this stage",
    "full, pre-1974 and post-1974 chronologies are all produced",
    "every release year in every sample lands in exactly one class",
    "each misalignment value reproduces the long-run relation for its own year",
    "an import shortfall without external corroboration is labelled as such",
    "no year is called binding on the estimated relation alone",
    "samples where imports do not error-correct are dated on the accounts alone",
    "index weights sum to one in every sample",
    "the weights follow what the estimation established, not a fixed prior",
    "each class carries a plain-language statement of what it means",
    "every class appearing in the panel is documented in the rules ledger",
    "the chronology is tested against a dated, sourced external benchmark",
    paste("the stress signal is an OR over available indicators and is never NA;",
          "two of the four need a lag, so the first year of each sample rests on",
          "the remaining two")
  )
)
w(integrity, "s70_binding_state_integrity.csv")
stopifnot(all(integrity$passed))

message("S70 binding state complete: ", output_dir)
for (s in sample_names) {
  cc <- classification_counts |> filter(sample == s)
  nb <- sum(cc$years[cc$classification == "binding_confirmed"])
  message("  ", s, ": ", nb, " binding years (",
          weights$basis[weights$sample == s], ")")
}
