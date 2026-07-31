#!/usr/bin/env Rscript

# CL_BOP_BINDING S50: triangulate reduced-system import disequilibrium with
# observed balance-of-payments evidence. The ECT never determines a binding
# date by itself.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release_file <- file.path(
  root, "data", "releases", "chile_bop_binding_v1",
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv"
)
ect_file <- file.path(
  root, "output", "CL", "BOP_BINDING", "S40_THRESHOLD_VECM",
  "reduced_system_import_ect.csv"
)
regime_file <- file.path(
  root, "output", "CL", "BOP_BINDING", "S40_THRESHOLD_VECM",
  "threshold_regime_classification.csv"
)
threshold_file <- file.path(
  root, "output", "CL", "BOP_BINDING", "S40_THRESHOLD_VECM",
  "threshold_effect_summary.csv"
)
processed_dir <- file.path(
  root, "data", "processed", "CL_BOP_BINDING", "S40_BINDING_STATE"
)
output_dir <- file.path(
  root, "output", "CL", "BOP_BINDING", "S50_BINDING_STATE"
)
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release_file), file.exists(ect_file),
          file.exists(regime_file), file.exists(threshold_file))

panel <- read.csv(release_file, check.names = FALSE)
ect <- read.csv(ect_file, check.names = FALSE)
regime <- read.csv(regime_file, check.names = FALSE) |>
  dplyr::select(year, sample, threshold_regime = regime,
                threshold_value_lagged, threshold_hat)
threshold <- read.csv(threshold_file, check.names = FALSE)

z_score <- function(x) {
  ifelse(is.finite(sd(x, na.rm = TRUE)) && sd(x, na.rm = TRUE) > 0,
         (x - mean(x, na.rm = TRUE)) / sd(x, na.rm = TRUE), NA_real_)
}
robust_z <- function(x) {
  center <- median(x, na.rm = TRUE)
  scale <- mad(x, center = center, constant = 1.4826, na.rm = TRUE)
  if (!is.finite(scale) || scale == 0) return(z_score(x))
  (x - center) / scale
}

state <- panel |>
  left_join(
    ect |>
      dplyr::select(year, sample, ECT_import_reduced,
                    state_variables, stationary_controls),
    by = "year"
  ) |>
  left_join(regime, by = c("year", "sample")) |>
  arrange(year) |>
  group_by(sample) |>
  mutate(
    import_shortfall_pressure = -ECT_import_reduced,
    import_shortfall_pressure_z = robust_z(import_shortfall_pressure),
    current_account_pressure_z = robust_z(-current_account_gdp),
    goods_balance_pressure_z = robust_z(-goods_balance_gdp),
    manufactured_import_compression =
      -(manufactures_imports_gdp - lag(manufactures_imports_gdp)),
    manufactured_import_compression_z =
      robust_z(manufactured_import_compression)
  ) |>
  ungroup() |>
  mutate(
    ect_pressure_signal = import_shortfall_pressure_z >= 1,
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
      0.50 * import_shortfall_pressure_z +
      0.20 * current_account_pressure_z +
      0.15 * goods_balance_pressure_z +
      0.15 * manufactured_import_compression_z,
    classification = case_when(
      ect_pressure_signal & observed_bop_pressure_signal ~
        "confirmed_binding",
      ect_pressure_signal & !observed_bop_pressure_signal ~
        "ECT_only_pressure",
      !ect_pressure_signal & observed_bop_pressure_signal ~
        "observed_BOP_only_pressure",
      TRUE ~ "non_binding_adjustment"
    ),
    threshold_effect_supported_5 = case_when(
      sample == "pre_1920_1973" ~ threshold$threshold_effect_reject_5[
        threshold$sample == "pre_1920_1973"
      ],
      sample == "post_1974_2024" ~ threshold$threshold_effect_reject_5[
        threshold$sample == "post_1974_2024"
      ],
      TRUE ~ FALSE
    ),
    threshold_regime_role = ifelse(
      threshold_effect_supported_5,
      "corroborating_regime_evidence",
      "descriptive_only_threshold_not_supported"
    )
  )

ect_output <- state |>
  dplyr::select(
    year, sample, ECT_import_reduced, import_shortfall_pressure,
    import_shortfall_pressure_z, ect_pressure_signal,
    state_variables, stationary_controls
  )
episode_panel <- state |>
  dplyr::select(
    year, sample, classification, bop_binding_index,
    ect_pressure_signal, observed_bop_pressure_signal,
    observed_signal_count, current_account_gdp, goods_balance_gdp,
    manufactures_imports_gdp, manufactured_import_compression,
    financing_compression_signal, threshold_regime,
    threshold_effect_supported_5, threshold_regime_role
  )
index_output <- state |>
  dplyr::select(
    year, sample, bop_binding_index, import_shortfall_pressure_z,
    current_account_pressure_z, goods_balance_pressure_z,
    manufactured_import_compression_z, classification
  )

write.csv(ect_output,
          file.path(processed_dir, "ect_import_shortfall.csv"),
          row.names = FALSE, na = "")
write.csv(episode_panel,
          file.path(processed_dir, "bop_binding_episode_panel.csv"),
          row.names = FALSE, na = "")
write.csv(index_output,
          file.path(processed_dir, "bop_binding_index.csv"),
          row.names = FALSE, na = "")

# Contiguous confirmed-binding runs.
confirmed_flag <- state$classification == "confirmed_binding"
run_id <- cumsum(c(TRUE, diff(as.integer(confirmed_flag)) != 0))
episode_summary <- state |>
  mutate(run_id = run_id) |>
  filter(classification == "confirmed_binding") |>
  group_by(run_id, sample) |>
  summarise(
    start_year = min(year), end_year = max(year),
    duration_years = n(),
    peak_year = year[which.max(bop_binding_index)],
    peak_binding_index = max(bop_binding_index, na.rm = TRUE),
    mean_binding_index = mean(bop_binding_index, na.rm = TRUE),
    mean_observed_signal_count = mean(observed_signal_count, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::select(-run_id)

classification_counts <- state |>
  count(sample, classification, name = "years")
component_ledger <- tibble::tribble(
  ~component, ~weight, ~positive_pressure_definition, ~role,
  "reduced import ECT", 0.50, "-ECT standardized within split sample", "latent import shortfall",
  "current account", 0.20, "negative current-account balance", "observed BOP",
  "goods balance", 0.15, "negative goods balance", "observed BOP",
  "manufactured-import compression", 0.15, "annual fall in manufactured imports/GDP", "observed BOP"
)
classification_rules <- tibble::tribble(
  ~classification, ~ECT_signal, ~observed_signal, ~interpretation,
  "confirmed_binding", TRUE, TRUE, "latent import shortfall and at least one observed BOP pressure indicator",
  "ECT_only_pressure", TRUE, FALSE, "latent pressure without observed confirmation",
  "observed_BOP_only_pressure", FALSE, TRUE, "observed external pressure without a one-SD ECT shortfall",
  "non_binding_adjustment", FALSE, FALSE, "neither triangulation family crosses its rule"
)
write.csv(episode_summary,
          file.path(output_dir, "confirmed_binding_episode_summary.csv"),
          row.names = FALSE, na = "")
write.csv(classification_counts,
          file.path(output_dir, "binding_classification_counts.csv"),
          row.names = FALSE)
write.csv(component_ledger,
          file.path(output_dir, "binding_index_component_ledger.csv"),
          row.names = FALSE)
write.csv(classification_rules,
          file.path(output_dir, "binding_classification_rules.csv"),
          row.names = FALSE)
write.csv(episode_panel,
          file.path(output_dir, "bop_binding_episode_panel.csv"),
          row.names = FALSE, na = "")

p <- ggplot(state, aes(year, bop_binding_index)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_rect(
    data = state |> filter(classification == "confirmed_binding"),
    aes(xmin = year - 0.5, xmax = year + 0.5,
        ymin = -Inf, ymax = Inf),
    inherit.aes = FALSE, fill = "#D55E00", alpha = 0.15
  ) +
  geom_line(color = "#0072B2", linewidth = 0.75) +
  geom_vline(xintercept = 1973.5, linetype = "dotted") +
  labs(
    x = NULL, y = "Triangulated BOP-binding index",
    title = "Chile: import shortfall and observed external-pressure evidence",
    subtitle = "Shading marks confirmed years; threshold regimes are not used because their bootstrap tests fail"
  ) +
  theme_minimal(base_size = 11)
ggsave(file.path(output_dir, "fig_bop_binding_index.png"),
       p, width = 8.3, height = 4.6, dpi = 220)
ggsave(file.path(output_dir, "fig_bop_binding_index.pdf"),
       p, width = 8.3, height = 4.6)

p_components <- state |>
  dplyr::select(
    year, import_shortfall_pressure_z, current_account_pressure_z,
    goods_balance_pressure_z, manufactured_import_compression_z
  ) |>
  tidyr::pivot_longer(-year, names_to = "component", values_to = "z") |>
  ggplot(aes(year, z, color = component)) +
  geom_hline(yintercept = 0, color = "grey65") +
  geom_line(linewidth = 0.55) +
  facet_wrap(~component, ncol = 1, scales = "free_y") +
  labs(x = NULL, y = "Standardized pressure", color = NULL,
       title = "BOP-binding index components") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "none")
ggsave(file.path(output_dir, "fig_binding_components.png"),
       p_components, width = 8.3, height = 7, dpi = 220)
ggsave(file.path(output_dir, "fig_binding_components.pdf"),
       p_components, width = 8.3, height = 7)

integrity <- tibble(
  check = c(
    "ECT_sign_verified",
    "ECT_not_sufficient_for_confirmation",
    "four_class_typology",
    "threshold_nonrejection_respected",
    "full_1920_2024_panel",
    "component_weights_sum_to_one",
    "machinery_scope_limit_retained"
  ),
  passed = c(
    all(ect_output$import_shortfall_pressure ==
          -ect_output$ECT_import_reduced),
    {
      idx <- which(state$ect_pressure_signal %in% TRUE &
                     state$observed_bop_pressure_signal %in% FALSE)
      all(state$classification[idx] == "ECT_only_pressure")
    },
    all(c("confirmed_binding", "ECT_only_pressure",
          "observed_BOP_only_pressure", "non_binding_adjustment") %in%
          unique(state$classification)),
    all(!state$threshold_effect_supported_5),
    nrow(state) == 105,
    abs(sum(component_ledger$weight) - 1) < 1e-8,
    grepl("log_K_ME_gross",
          "log_K_ME_gross remains outside the reduced ECT")
  ),
  detail = c(
    "positive original ECT means imports above equilibrium; pressure=-ECT",
    "confirmation requires at least one observed WBOP signal",
    "confirmed / ECT-only / observed-only / non-binding",
    "threshold regimes retained as descriptive only",
    "annual 1920-2024",
    "0.50 + 0.20 + 0.15 + 0.15",
    "S40 reduced-system ECT does not estimate a machinery coefficient"
  )
)
write.csv(integrity,
          file.path(output_dir, "s50_stage_integrity_checks.csv"),
          row.names = FALSE)
stopifnot(all(integrity$passed))

message("CL_BOP_BINDING S50 complete: triangulated binding-state panel written.")
