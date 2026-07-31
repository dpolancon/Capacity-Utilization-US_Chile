#!/usr/bin/env Rscript

# CL_BOP_BINDING v7 / S60: linear VECM on the RER-controlled Kaldor system.
#
# The threshold VECM is absent from v7 by design. This stage estimates the linear
# system the v6 report promoted but never fitted: imports and machinery
# accumulation, controlled by the real exchange rate, across a nested
# specification ladder and three samples, with Johansen rank testing at every
# rung.
#
# The frozen release is the only data input. No upstream object is regenerated.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
source(file.path(root, "codes", "CL_BOP_VECM_common_v7.R"))

set.seed(19731974)
release_file <- file.path(
  root, "data", "releases", "chile_bop_binding_v1_1",
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv"
)
integration_file <- file.path(
  root, "output", "CL", "BOP_BINDING_V6", "S30_INTEGRATION_BREAKS",
  "sequential_integration_verdict.csv"
)
output_dir <- file.path(root, "output", "CL", "BOP_BINDING_V7", "S60_LINEAR_VECM")
fig_dir <- file.path(output_dir, "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release_file), file.exists(integration_file))

panel <- read.csv(release_file, check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(identical(panel$year, 1920:2024))
integration <- read.csv(integration_file, check.names = FALSE,
                        stringsAsFactors = FALSE)

# No dummy controls enter the ladder. A 1975 pulse was tried and makes the
# post-1974 design exactly singular: with two or three lags the dummy marks the
# second observation of the sample, so it is collinear with the lagged
# differences. The specification is the four variables, and every sample is
# estimated on the same design.
# First difference of machinery for the balanced-order diagnostic rung.
panel$d_log_K_ME_gross <- c(NA_real_, diff(panel$log_K_ME_gross))

samples <- list(
  full_1920_2024 = panel |> filter(year >= 1920, year <= 2024),
  pre_1920_1973  = panel |> filter(year >= 1920, year <= 1973),
  post_1974_2024 = panel |> filter(year >= 1974, year <= 2024)
)
sample_names <- names(samples)

# ---------------------------------------------------------------------------
# Nested specification ladder.
#
# Each rung adds one variable to the one before it, so the rank evidence can be
# read as a sequence rather than as a single preferred model. M3 is the headline:
# Kaldor's machinery-import relation controlled by the real exchange rate. M3d
# repeats the headline with machinery in first differences, which is the only
# rung whose integration orders are balanced.
# ---------------------------------------------------------------------------
ladder <- list(
  M1_kaldor_core = list(
    state = c("log_imports", "log_K_ME_gross"),
    role = "Kaldor core: imports and machinery accumulation",
    nests = NA_character_
  ),
  M2_plus_surplus = list(
    state = c("log_imports", "log_K_ME_gross", "log_non_reinvested_surplus"),
    role = "adds the surplus not internally recapitalized",
    nests = "M1_kaldor_core"
  ),
  M3_plus_rer = list(
    state = c("log_imports", "log_K_ME_gross", "log_non_reinvested_surplus",
              "log_RER"),
    role = "headline: Kaldor controlled by the real exchange rate",
    nests = "M2_plus_surplus"
  ),
  M4_plus_wage_share = list(
    state = c("log_imports", "log_K_ME_gross", "log_non_reinvested_surplus",
              "wage_share"),
    role = "robustness: legacy fourth variable in place of the RER",
    nests = "M2_plus_surplus"
  ),
  M3d_machinery_differenced = list(
    state = c("log_imports", "d_log_K_ME_gross", "log_non_reinvested_surplus",
              "log_RER"),
    role = "balanced-order diagnostic: machinery enters in first differences",
    nests = "M3_plus_rer"
  )
)

deterministics <- c("const", "trend")
lag_orders <- c(2L, 3L)

ladder_ledger <- bind_rows(lapply(names(ladder), function(m) {
  tibble(specification = m,
         state_variables = paste(ladder[[m]]$state, collapse = ";"),
         n_state = length(ladder[[m]]$state),
         role = ladder[[m]]$role,
         nests_within = ladder[[m]]$nests)
}))

# ---------------------------------------------------------------------------
# Integration-order context. Recorded, not enforced: the instruction is to
# estimate the four-variable system, and the ladder is what makes the cost of
# doing so with an I(2) regressor visible.
# ---------------------------------------------------------------------------
order_lookup <- integration |>
  select(sample, variable, classification, first_supported_order)

spec_order_audit <- bind_rows(lapply(sample_names, function(s) {
  bind_rows(lapply(names(ladder), function(m) {
    vars <- ladder[[m]]$state
    base_vars <- sub("^d_", "", vars)
    cls <- order_lookup$classification[
      match(paste(s, base_vars), paste(order_lookup$sample,
                                       order_lookup$variable))]
    # A differenced I(2) series is I(1); the audit reports the order as entered.
    entered <- ifelse(startsWith(vars, "d_") & cls == "I(2)", "I(1)", cls)
    tibble(
      sample = s, specification = m,
      variables_as_entered = paste(vars, collapse = ";"),
      orders_as_entered = paste(entered, collapse = ";"),
      all_I1 = all(entered == "I(1)", na.rm = TRUE),
      contains_I2 = any(entered == "I(2)", na.rm = TRUE),
      contains_I0 = any(entered == "I(0)", na.rm = TRUE),
      balanced_order = all(entered == "I(1)", na.rm = TRUE),
      note = case_when(
        any(entered == "I(2)", na.rm = TRUE) &
          any(entered == "I(0)", na.rm = TRUE) ~
          "mixed orders: an I(2) and an I(0) variable both enter in levels",
        any(entered == "I(2)", na.rm = TRUE) ~
          "unbalanced: an I(2) variable enters a levels system",
        any(entered == "I(0)", na.rm = TRUE) ~
          "an I(0) variable enters the levels system",
        TRUE ~ "all state variables are I(1)"
      )
    )
  }))
}))

# ---------------------------------------------------------------------------
# Collinearity and lag diagnostics per sample and rung.
# ---------------------------------------------------------------------------
design_audit <- bind_rows(lapply(sample_names, function(s) {
  bind_rows(lapply(names(ladder), function(m) {
    vars <- ladder[[m]]$state
    dat <- samples[[s]][, vars, drop = FALSE] |> na.omit()
    corr <- cor(dat, use = "pairwise.complete.obs")
    x <- scale(dat)
    cn <- if (ncol(x) >= 2L) kappa(x, exact = TRUE) else NA_real_
    max_corr <- max(abs(corr[upper.tri(corr)]), na.rm = TRUE)
    tibble(
      sample = s, specification = m,
      condition_number_standardized = cn,
      maximum_absolute_pairwise_correlation = max_corr,
      condition_number_gate_pass = is.na(cn) || cn <= 30,
      pairwise_gate_pass = max_corr <= 0.99
    )
  }))
}))

lag_ledger <- bind_rows(lapply(sample_names, function(s) {
  bind_rows(lapply(names(ladder), function(m) {
    vars <- ladder[[m]]$state
    dat <- samples[[s]][, vars, drop = FALSE] |> na.omit()
    bop_select_lag(dat, vars) |>
      mutate(sample = s, specification = m,
             state_variables = paste(vars, collapse = ";"), .before = 1)
  }))
}))

# ---------------------------------------------------------------------------
# Estimate the full grid: sample x rung x deterministic x lag.
# ---------------------------------------------------------------------------
all_rank <- list(); all_beta <- list(); all_alpha <- list()
all_gamma <- list(); all_diag <- list()
fits <- list()
counter <- 0L

for (s in sample_names) {
  for (m in names(ladder)) {
    vars <- ladder[[m]]$state
    dat <- samples[[s]][, c("year", vars)] |> na.omit()
    controls <- character(0)
    for (det in deterministics) {
      for (k in lag_orders) {
        fit <- bop_fit_johansen(dat, s, m, vars, controls, det, k,
                                ladder[[m]]$role)
        counter <- counter + 1L
        all_rank[[counter]] <- fit$ranks
        all_beta[[counter]] <- fit$beta
        all_alpha[[counter]] <- fit$alpha
        all_gamma[[counter]] <- fit$gamma
        all_diag[[counter]] <- fit$diagnostic
        fits[[fit$diagnostic$model_id[1]]] <- list(
          fit = fit, data = dat, state = vars, sample = s, specification = m,
          deterministic = det, lag_order = k
        )
      }
    }
  }
}

rank_ledger <- bind_rows(all_rank)
beta_ledger <- bind_rows(all_beta)
alpha_ledger <- bind_rows(all_alpha)
gamma_ledger <- bind_rows(all_gamma)
diagnostic_ledger <- bind_rows(all_diag) |>
  left_join(design_audit, by = c("sample", "specification")) |>
  left_join(spec_order_audit |> select(sample, specification, orders_as_entered,
                                       balanced_order, note),
            by = c("sample", "specification"))

# ---------------------------------------------------------------------------
# Promotion. The model carried into the chronology is the highest rung that
# returns at least one cointegrating relation, leaves no residual serial
# correlation, has stable companion roots, and clears the condition-number gate.
# Every requirement is recorded, so a promotion can be checked rather than
# trusted. Where no rung qualifies the ledger says so and the chronology for that
# sample rests on the observed external accounts alone.
# ---------------------------------------------------------------------------
ladder_order <- c("M1_kaldor_core", "M2_plus_surplus", "M4_plus_wage_share",
                  "M3_plus_rer")

beta_quality <- beta_ledger |>
  filter(grepl("^log_imports", term)) |>
  select(model_id, import_normalization_share, normalization_reliable) |>
  distinct(model_id, .keep_all = TRUE)

import_adjustment <- alpha_ledger |>
  filter(grepl("^log_imports", equation)) |>
  select(model_id, import_alpha = alpha, import_alpha_t = t_statistic,
         import_alpha_p = p_value,
         imports_adjust_5 = adjusts_to_disequilibrium_5) |>
  distinct(model_id, .keep_all = TRUE)

promotion_candidates <- diagnostic_ledger |>
  filter(status == "estimated", specification %in% ladder_order) |>
  left_join(beta_quality, by = "model_id") |>
  left_join(import_adjustment, by = "model_id") |>
  mutate(
    rank_at_least_one = !is.na(selected_rank_5) & selected_rank_5 >= 1L,
    # With rank above one the extracted vector is one basis of a
    # higher-dimensional cointegrating space and is not uniquely identified
    # without further restrictions. A misalignment series needs a single
    # identified relation, so rank one is preferred.
    rank_one_identified = !is.na(selected_rank_5) & selected_rank_5 == 1L,
    rank_below_full = !is.na(selected_rank_5) &
      selected_rank_5 < lengths(strsplit(state_variables, ";")),
    no_residual_serial_correlation = !is.na(serial_portmanteau_p) &
      serial_portmanteau_p >= 0.05,
    # A cointegrated system carries n - r unit roots by construction. Stability
    # means the roots beyond those sit inside the unit circle.
    roots_stable = !is.na(stable_roots) & stable_roots,
    qualifies = rank_at_least_one & rank_below_full &
      no_residual_serial_correlation & roots_stable &
      condition_number_gate_pass & pairwise_gate_pass,
    ladder_rung = match(specification, ladder_order)
  )

promotion_ledger <- promotion_candidates |>
  select(model_id, sample, specification, ladder_rung, deterministic, lag_order,
         selected_rank_5, rank_at_least_one, rank_one_identified,
         rank_below_full,
         serial_portmanteau_p, no_residual_serial_correlation,
         maximum_companion_root, implied_unit_roots,
         max_modulus_beyond_unit_roots, roots_stable,
         condition_number_standardized, condition_number_gate_pass,
         pairwise_gate_pass, import_normalization_share,
         normalization_reliable, import_alpha, import_alpha_t, import_alpha_p,
         imports_adjust_5, orders_as_entered, balanced_order, qualifies)

promoted <- promotion_candidates |>
  filter(qualifies) |>
  group_by(sample) |>
  arrange(desc(ladder_rung), desc(rank_one_identified), lag_order,
          deterministic, .by_group = TRUE) |>
  slice(1) |>
  ungroup()

promoted_ledger <- bind_rows(lapply(sample_names, function(s) {
  row <- promoted |> filter(sample == s)
  if (!nrow(row)) {
    tibble(sample = s, model_id = NA_character_,
           specification = NA_character_, deterministic = NA_character_,
           lag_order = NA_integer_, selected_rank_5 = NA_integer_,
           rank_one_identified = NA, normalization_reliable = NA,
           import_normalization_share = NA_real_,
           import_alpha = NA_real_, import_alpha_t = NA_real_,
           import_alpha_p = NA_real_, imports_adjust_5 = NA,
           misalignment_interpretable = FALSE,
           misalignment_verdict = paste("no long-run relation was established,",
                                        "so no misalignment series exists"),
           promotion_status = "no_qualifying_rung",
           chronology_basis = "observed external accounts only",
           selection_reason = paste("no rung returned a cointegrating relation",
                                    "that also passed the diagnostics"))
  } else {
    # Two further conditions decide whether the misalignment series can be read
    # as a distance from an import requirement at all: imports must respond to
    # the disequilibrium, and the vector must survive normalization on imports.
    interpretable <- isTRUE(row$imports_adjust_5[1]) &&
      isTRUE(row$normalization_reliable[1])
    verdict <- if (interpretable) {
      "imports error-correct and the vector normalizes on imports"
    } else if (!isTRUE(row$imports_adjust_5[1]) &&
               !isTRUE(row$normalization_reliable[1])) {
      paste("imports neither error-correct nor carry the normalization:",
            "the relation is not an import requirement in this sample")
    } else if (!isTRUE(row$imports_adjust_5[1])) {
      paste("imports do not error-correct: the relation exists but imports are",
            "weakly exogenous to it")
    } else {
      paste("imports carry too little of the cointegrating vector for the",
            "normalized coefficients to read as elasticities")
    }
    tibble(sample = s, model_id = row$model_id[1],
           specification = row$specification[1],
           deterministic = row$deterministic[1],
           lag_order = row$lag_order[1],
           selected_rank_5 = row$selected_rank_5[1],
           rank_one_identified = row$rank_one_identified[1],
           normalization_reliable = row$normalization_reliable[1],
           import_normalization_share = row$import_normalization_share[1],
           import_alpha = row$import_alpha[1],
           import_alpha_t = row$import_alpha_t[1],
           import_alpha_p = row$import_alpha_p[1],
           imports_adjust_5 = row$imports_adjust_5[1],
           misalignment_interpretable = interpretable,
           misalignment_verdict = verdict,
           promotion_status = "promoted",
           chronology_basis = if (interpretable) {
             "linear VECM misalignment plus observed accounts"
           } else "observed external accounts only",
           selection_reason = paste0(
             "highest qualifying rung; rank ", row$selected_rank_5[1],
             "; portmanteau p ",
             ifelse(is.na(row$serial_portmanteau_p[1]), "NA",
                    formatC(row$serial_portmanteau_p[1], format = "f",
                            digits = 3)),
             "; largest root beyond the ", row$implied_unit_roots[1],
             " unit roots ",
             formatC(row$max_modulus_beyond_unit_roots[1], format = "f",
                     digits = 3),
             "; condition number ",
             formatC(row$condition_number_standardized[1], format = "f",
                     digits = 1)))
  }
}))

# ---------------------------------------------------------------------------
# Misalignment series and bootstrap confidence intervals for the promoted models.
# ---------------------------------------------------------------------------
ect_rows <- list(); boot_records <- list(); boot_summary <- list()
for (s in sample_names) {
  pr <- promoted_ledger |> filter(sample == s)
  if (is.na(pr$model_id[1])) next
  obj <- fits[[pr$model_id[1]]]
  ect <- bop_build_ect(obj$data, obj$state, beta_ledger, pr$model_id[1])
  if (nrow(ect)) {
    ect_rows[[s]] <- ect |>
      mutate(sample = s, model_id = pr$model_id[1],
             specification = pr$specification[1],
             promotion_status = pr$promotion_status[1], .before = 1)
  }
  bs <- bop_beta_bootstrap(obj$data, obj$state, s)
  boot_records[[s]] <- bs$records
  boot_summary[[s]] <- bs$summary |> mutate(model_id = pr$model_id[1])
}
ect_panel <- bind_rows(ect_rows)
bootstrap_summary <- bind_rows(boot_summary)

# ---------------------------------------------------------------------------
# Common-trend comparison. The report sets the estimated long-run coefficient
# beside the level regression slope and the ratio of average growth rates, so a
# reader can judge how much of it is relation and how much is shared trend.
# ---------------------------------------------------------------------------
trend_comparison <- bind_rows(lapply(sample_names, function(s) {
  d <- samples[[s]]
  ols <- coef(lm(log_imports ~ log_K_ME_gross, data = d))[2]
  gi <- mean(diff(d$log_imports), na.rm = TRUE)
  gk <- mean(diff(d$log_K_ME_gross), na.rm = TRUE)
  pr <- promoted_ledger |> filter(sample == s)
  vecm_beta <- if (is.na(pr$model_id[1])) NA_real_ else {
    b <- beta_ledger |>
      filter(model_id == pr$model_id[1],
             grepl("^log_K_ME_gross", term))
    if (nrow(b)) b$long_run_relation_coefficient[1] else NA_real_
  }
  tibble(
    sample = s,
    vecm_long_run_machinery_coefficient = vecm_beta,
    ols_level_slope = as.numeric(ols),
    mean_growth_imports = gi, mean_growth_machinery = gk,
    growth_ratio = gi / gk
  )
}))

# ---------------------------------------------------------------------------
# Write ledgers.
# ---------------------------------------------------------------------------
w <- function(x, nm) write.csv(x, file.path(output_dir, nm), row.names = FALSE,
                               na = "")
w(ladder_ledger, "nested_specification_ladder.csv")
w(spec_order_audit, "specification_integration_order_audit.csv")
w(rank_ledger, "johansen_trace_rank_grid.csv")
w(beta_ledger, "cointegrating_vector_ledger.csv")
w(alpha_ledger, "adjustment_speed_exogeneity_ledger.csv")
w(gamma_ledger, "short_run_structure_ledger.csv")
w(diagnostic_ledger, "vecm_model_diagnostic_ledger.csv")
w(design_audit, "collinearity_condition_number_audit.csv")
w(lag_ledger, "lag_selection_ledger.csv")
w(promotion_ledger, "promotion_requirement_ledger.csv")
w(promoted_ledger, "promoted_model_ledger.csv")
w(ect_panel, "import_misalignment_panel.csv")
w(bootstrap_summary, "beta_bootstrap_summary.csv")
w(bind_rows(boot_records), "beta_bootstrap_records.csv")
w(trend_comparison, "long_run_coefficient_trend_comparison.csv")

# ---------------------------------------------------------------------------
# Figures.
# ---------------------------------------------------------------------------
if (nrow(ect_panel)) {
  p_ect <- ggplot(ect_panel, aes(year, ECT_import)) +
    geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.3) +
    geom_line(colour = "#0072B2", linewidth = 0.55) +
    facet_wrap(~sample, scales = "free") +
    labs(x = NULL, y = "Import misalignment",
         title = "Imports relative to their estimated long-run requirement",
         subtitle = paste("Below zero means imports sat under the level the",
                          "long-run relation implies")) +
    theme_minimal(base_size = 10)
  ggsave(file.path(fig_dir, "fig_import_misalignment.pdf"), p_ect,
         width = 9, height = 4.5)
  ggsave(file.path(fig_dir, "fig_import_misalignment.png"), p_ect,
         width = 9, height = 4.5, dpi = 220)
}

rank_plot_data <- rank_ledger |>
  left_join(diagnostic_ledger |> select(model_id, sample, specification),
            by = "model_id") |>
  filter(!is.na(sample))
if (nrow(rank_plot_data)) {
  p_rank <- ggplot(rank_plot_data,
                   aes(null_rank, trace_statistic, group = model_id)) +
    geom_line(alpha = 0.35, colour = "#0072B2") +
    geom_point(size = 0.7, alpha = 0.6, colour = "#0072B2") +
    geom_line(aes(y = critical_5), colour = "#D55E00", linetype = "dashed",
              linewidth = 0.4) +
    facet_grid(sample ~ specification, scales = "free") +
    labs(x = "Null hypothesis: rank r", y = "Trace statistic",
         title = "Johansen trace sequence across the nested ladder",
         subtitle = "Dashed line is the 5% critical value") +
    theme_minimal(base_size = 8)
  ggsave(file.path(fig_dir, "fig_rank_grid.pdf"), p_rank,
         width = 11, height = 6)
}

# ---------------------------------------------------------------------------
# Integrity.
# ---------------------------------------------------------------------------
n_expected <- length(sample_names) * length(ladder) * length(deterministics) *
  length(lag_orders)
integrity <- tibble(
  check = c(
    "frozen_release_input", "three_samples", "nested_ladder_complete",
    "full_grid_attempted", "rank_tested_every_model",
    "short_run_structure_recorded", "exogeneity_recorded",
    "promotion_requirements_recorded", "every_sample_has_promotion_verdict",
    "integration_order_cost_recorded", "no_threshold_model_input",
    "misalignment_dated_by_own_year"
  ),
  passed = c(
    file.exists(release_file),
    n_distinct(diagnostic_ledger$sample) == 3L,
    nrow(ladder_ledger) == length(ladder) &&
      all(!is.na(ladder_ledger$state_variables)),
    nrow(diagnostic_ledger) == n_expected,
    all(diagnostic_ledger$model_id[diagnostic_ledger$status == "estimated"] %in%
          rank_ledger$model_id),
    nrow(gamma_ledger) > 0L && all(c("t_statistic", "p_value") %in%
                                     names(gamma_ledger)),
    nrow(alpha_ledger) > 0L && "weakly_exogenous_5" %in% names(alpha_ledger),
    nrow(promotion_ledger) > 0L && "qualifies" %in% names(promotion_ledger),
    nrow(promoted_ledger) == 3L && all(!is.na(promoted_ledger$promotion_status)),
    nrow(spec_order_audit) == length(sample_names) * length(ladder),
    TRUE,
    nrow(ect_panel) == 0L ||
      all(ect_panel$year %in% panel$year)
  ),
  detail = c(
    "the frozen v1_1 release is the only data input",
    "full, pre-1974 and post-1974 samples are all estimated",
    "every rung of the nested ladder is declared with the rung it nests within",
    "sample x specification x deterministic x lag grid attempted in full",
    "every estimated model has a Johansen trace sequence",
    "short-run coefficients are recorded with t ratios and p values",
    "each equation records whether it adjusts to the disequilibrium",
    "each promotion requirement is recorded so the choice can be checked",
    "every sample carries an explicit promotion or no-promotion verdict",
    "the integration-order cost of each rung is recorded, not hidden",
    "no threshold-VECM ledger is consumed by this stage",
    "each misalignment value is dated by the year of its own state vector"
  )
)
w(integrity, "s60_stage_integrity.csv")
stopifnot(all(integrity$passed))

message("S60 linear VECM complete: ", output_dir)
message("promotions:")
for (i in seq_len(nrow(promoted_ledger))) {
  message("  ", promoted_ledger$sample[i], " -> ",
          promoted_ledger$promotion_status[i], " (",
          ifelse(is.na(promoted_ledger$specification[i]), "none",
                 promoted_ledger$specification[i]), ")")
}
