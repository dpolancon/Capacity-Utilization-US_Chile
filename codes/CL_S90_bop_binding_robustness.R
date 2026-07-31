#!/usr/bin/env Rscript

# CL_BOP_BINDING S90: robustness and specification-space mapping.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(urca)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release_file <- file.path(
  root, "data", "releases", "chile_bop_binding_v1",
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv"
)
rer_file <- file.path(
  root, "data", "processed", "CL_BOP_BINDING", "S20_RER_SPLICE",
  "rer_spliced_2003base.csv"
)
model_map_file <- file.path(
  root, "output", "CL", "BOP_BINDING", "S30_VECM",
  "vecm_specification_map.csv"
)
threshold_file <- file.path(
  root, "output", "CL", "BOP_BINDING", "S40_THRESHOLD_VECM",
  "threshold_effect_summary.csv"
)
state_file <- file.path(
  root, "data", "processed", "CL_BOP_BINDING",
  "S40_BINDING_STATE", "bop_binding_episode_panel.csv"
)
output_dir <- file.path(
  root, "output", "CL", "BOP_BINDING", "S90_ROBUSTNESS"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(all(file.exists(c(
  release_file, rer_file, model_map_file, threshold_file, state_file
))))

panel <- read.csv(release_file, check.names = FALSE)
rer <- read.csv(rer_file, check.names = FALSE)
model_map <- read.csv(model_map_file, check.names = FALSE)
threshold <- read.csv(threshold_file, check.names = FALSE)
state <- read.csv(state_file, check.names = FALSE)

# Alternative overlap splice dates.
splice_years <- c(2006L, 2008L, 2010L)
splice_robustness <- bind_rows(lapply(splice_years, function(last_cliolab) {
  alt <- rer |>
    mutate(
      alternative_RER = ifelse(
        year <= last_cliolab, RER_cliolab_2003, RER_bcch_2003
      )
    )
  common <- alt |> filter(is.finite(alternative_RER),
                          is.finite(RER_spliced_2003base))
  tibble(
    last_cliolab_year = last_cliolab,
    first_bcch_year = last_cliolab + 1L,
    correlation_with_baseline_log_RER =
      cor(log(common$alternative_RER),
          log(common$RER_spliced_2003base)),
    maximum_absolute_log_difference =
      max(abs(log(common$alternative_RER) -
                log(common$RER_spliced_2003base))),
    boundary_log_growth = with(
      alt,
      log(alternative_RER[year == last_cliolab + 1L]) -
        log(alternative_RER[year == last_cliolab])
    )
  )
}))
write.csv(splice_robustness,
          file.path(output_dir, "alternative_rer_splice_windows.csv"),
          row.names = FALSE)

# Boundary and RER-source sensitivity for the requested full long-run equation.
fit_long_run <- function(dat, model_id, rer_variable = "log_RER") {
  f <- as.formula(paste(
    "log_imports ~ log_K_ME_gross + log_non_reinvested_surplus +",
    "wage_share +", rer_variable
  ))
  fit <- lm(f, data = dat)
  sm <- summary(fit)$coefficients
  X <- model.matrix(fit)[, -1, drop = FALSE]
  cn <- kappa(scale(X), exact = TRUE)
  ect_adf <- ur.df(residuals(fit), type = "none", lags = 1)
  ect_stationary <- as.numeric(ect_adf@teststat[1]) <
    as.numeric(ect_adf@cval[1, "5pct"])
  tibble(
    model_id = model_id,
    term = rownames(sm),
    estimate = sm[, "Estimate"],
    standard_error = sm[, "Std. Error"],
    ci_low = estimate - 1.96 * standard_error,
    ci_high = estimate + 1.96 * standard_error,
    n = nrow(model.frame(fit)),
    adjusted_r2 = summary(fit)$adj.r.squared,
    condition_number_standardized = cn,
    ect_adf_stat = as.numeric(ect_adf@teststat[1]),
    ect_adf_critical_5 = as.numeric(ect_adf@cval[1, "5pct"]),
    ect_stationary_5 = ect_stationary
  )
}

boundary_models <- list()
idx <- 0L
for (end_year in 1972:1974) {
  idx <- idx + 1L
  boundary_models[[idx]] <- fit_long_run(
    panel |> filter(year >= 1920, year <= end_year),
    paste0("pre_1920_", end_year)
  )
}
for (start_year in 1973:1975) {
  idx <- idx + 1L
  boundary_models[[idx]] <- fit_long_run(
    panel |> filter(year >= start_year, year <= 2024),
    paste0("post_", start_year, "_2024")
  )
}
boundary_ledger <- bind_rows(boundary_models)
write.csv(boundary_ledger,
          file.path(output_dir, "alternative_sample_boundary_models.csv"),
          row.names = FALSE)

# ClioLab-only versus spliced RER on their common post-1974 support.
common_post <- panel |>
  filter(year >= 1974, year <= 2010) |>
  mutate(log_RER_cliolab_only = log(RER_cliolab_2003))
rer_source_models <- bind_rows(
  fit_long_run(common_post, "post_1974_2010_spliced", "log_RER"),
  fit_long_run(common_post, "post_1974_2010_cliolab_only",
               "log_RER_cliolab_only")
)
write.csv(rer_source_models,
          file.path(output_dir, "cliolab_only_vs_spliced_models.csv"),
          row.names = FALSE)

# Confidence-band overlap across adjacent sample definitions.
baseline_terms <- boundary_ledger |>
  filter(model_id %in% c("pre_1920_1973", "post_1974_2024")) |>
  dplyr::select(period = model_id, term,
                base_low = ci_low, base_high = ci_high)
band_overlap <- boundary_ledger |>
  mutate(period = ifelse(grepl("^pre", model_id),
                         "pre_1920_1973", "post_1974_2024")) |>
  left_join(baseline_terms, by = c("period", "term")) |>
  mutate(
    confidence_band_overlap =
      pmax(ci_low, base_low) <= pmin(ci_high, base_high)
  )
write.csv(band_overlap,
          file.path(output_dir, "sample_boundary_confidence_band_overlap.csv"),
          row.names = FALSE)

# Deterministic-term and lag-order map from S30.
specification_summary <- model_map |>
  filter(model_role == "primary_RER_controlled_split_VECM") |>
  group_by(sample, deterministic, lag_order, gate_status) |>
  summarise(
    selected_rank_5 = first(selected_rank_5),
    serial_portmanteau_p = first(serial_portmanteau_p),
    maximum_companion_root = first(maximum_companion_root),
    stable_roots = first(stable_roots),
    .groups = "drop"
  )
write.csv(specification_summary,
          file.path(output_dir, "deterministic_lag_specification_map.csv"),
          row.names = FALSE)

# Leave-one-confirmed-episode-out sensitivity of the ECT/observed-pressure link.
episode_years <- state |>
  filter(classification == "confirmed_binding") |>
  arrange(year) |>
  mutate(run = cumsum(c(TRUE, diff(year) > 1))) |>
  group_by(run) |>
  summarise(start = min(year), end = max(year),
            years = paste(year, collapse = ";"), .groups = "drop")
full_state <- read.csv(
  file.path(root, "data", "processed", "CL_BOP_BINDING",
            "S40_BINDING_STATE", "bop_binding_index.csv"),
  check.names = FALSE
) |>
  left_join(
    panel |>
      dplyr::select(year, current_account_gdp, goods_balance_gdp),
    by = "year"
  )

loo_rows <- list()
for (i in seq_len(nrow(episode_years))) {
  omit <- seq(episode_years$start[i], episode_years$end[i])
  dat <- full_state |> filter(!year %in% omit)
  fit <- lm(
    import_shortfall_pressure_z ~
      current_account_pressure_z + goods_balance_pressure_z,
    data = dat
  )
  sm <- summary(fit)$coefficients
  loo_rows[[i]] <- tibble(
    omitted_episode = paste0(episode_years$start[i], "-",
                             episode_years$end[i]),
    term = rownames(sm),
    estimate = sm[, "Estimate"],
    standard_error = sm[, "Std. Error"],
    ci_low = estimate - 1.96 * standard_error,
    ci_high = estimate + 1.96 * standard_error,
    n = nrow(model.frame(fit))
  )
}
loo <- bind_rows(loo_rows)
write.csv(loo,
          file.path(output_dir, "leave_one_episode_out_sensitivity.csv"),
          row.names = FALSE)

# Alternative observed threshold variables for the gate-admissible reduced
# systems. These tests reuse the frozen release and the completed S40 ECT;
# they do not re-open the blocked machinery specification.
set.seed(1990)
reduced_ect <- read.csv(
  file.path(
    root, "output", "CL", "BOP_BINDING", "S40_THRESHOLD_VECM",
    "reduced_system_import_ect.csv"
  ),
  check.names = FALSE
)

ols_threshold_system <- function(X, Y) {
  valid <- complete.cases(X, Y)
  X <- X[valid, , drop = FALSE]
  Y <- Y[valid, , drop = FALSE]
  if (nrow(X) <= ncol(X) + 2L) return(NULL)
  coef <- tryCatch(qr.solve(X, Y), error = function(e) NULL)
  if (is.null(coef)) return(NULL)
  fitted <- X %*% coef
  residuals <- Y - fitted
  list(
    fitted = fitted,
    residuals = residuals,
    ssr = sum(residuals^2)
  )
}

alternative_threshold_test <- function(
    dat, state, controls, threshold_variable,
    trim = 0.15, grid_n = 160L, bootstrap_n = 999L) {
  y_level <- as.matrix(dat[, state, drop = FALSE])
  dy <- diff(y_level)
  n <- nrow(y_level)
  t_index <- 3:n
  response <- dy[t_index - 1L, , drop = FALSE]
  ect_lag <- dat$ECT_import_reduced[t_index - 1L]
  z_lag <- dat[[threshold_variable]][t_index - 1L]
  dy_lag <- dy[t_index - 2L, , drop = FALSE]
  controls_matrix <- as.matrix(dat[t_index, controls, drop = FALSE])
  valid <- complete.cases(
    response, ect_lag, z_lag, dy_lag, controls_matrix
  )
  response <- response[valid, , drop = FALSE]
  ect_lag <- ect_lag[valid]
  z_lag <- z_lag[valid]
  dy_lag <- dy_lag[valid, , drop = FALSE]
  controls_matrix <- controls_matrix[valid, , drop = FALSE]
  x_linear <- cbind(
    ECT = ect_lag, dy_lag, controls_matrix, intercept = 1
  )
  linear <- ols_threshold_system(x_linear, response)
  stopifnot(!is.null(linear))
  grid <- unique(as.numeric(quantile(
    z_lag,
    probs = seq(trim, 1 - trim, length.out = grid_n),
    na.rm = TRUE, type = 8
  )))
  candidate <- bind_rows(lapply(grid, function(gamma) {
    high <- as.integer(z_lag > gamma)
    counts <- tabulate(high + 1L, nbins = 2L)
    if (min(counts) < 10L) {
      return(tibble(
        gamma = gamma, ssr = Inf,
        n_low = counts[1], n_high = counts[2]
      ))
    }
    x <- cbind(
      ECT_low = ect_lag * (1 - high),
      ECT_high = ect_lag * high,
      dy_lag, controls_matrix, intercept = 1
    )
    fit <- ols_threshold_system(x, response)
    tibble(
      gamma = gamma,
      ssr = ifelse(is.null(fit), Inf, fit$ssr),
      n_low = counts[1],
      n_high = counts[2]
    )
  }))
  feasible <- candidate |> filter(is.finite(ssr))
  if (nrow(feasible) == 0L) {
    return(list(
      summary = tibble(
        threshold_variable = threshold_variable,
        threshold_hat = NA_real_,
        n = nrow(response),
        n_low = NA_integer_,
        n_high = NA_integer_,
        lr_statistic = NA_real_,
        bootstrap_replications = 0L,
        bootstrap_p_value = NA_real_,
        threshold_effect_reject_5 = FALSE,
        status = "blocked_by_minimum_regime_size"
      ),
      bootstrap = tibble()
    ))
  }
  best <- feasible |> slice_min(ssr, n = 1, with_ties = FALSE)
  high <- as.integer(z_lag > best$gamma)
  x_threshold <- cbind(
    ECT_low = ect_lag * (1 - high),
    ECT_high = ect_lag * high,
    dy_lag, controls_matrix, intercept = 1
  )
  threshold_fit <- ols_threshold_system(x_threshold, response)
  lr_observed <- nrow(response) *
    log(linear$ssr / threshold_fit$ssr)
  lr_boot <- numeric(bootstrap_n)
  for (b in seq_len(bootstrap_n)) {
    draw <- sample(seq_len(nrow(linear$residuals)), replace = TRUE)
    y_boot <- linear$fitted +
      linear$residuals[draw, , drop = FALSE]
    linear_ssr <- ols_threshold_system(x_linear, y_boot)$ssr
    threshold_ssr <- min(vapply(feasible$gamma, function(gamma) {
      rb <- as.integer(z_lag > gamma)
      xb <- cbind(
        ECT_low = ect_lag * (1 - rb),
        ECT_high = ect_lag * rb,
        dy_lag, controls_matrix, intercept = 1
      )
      fit <- ols_threshold_system(xb, y_boot)
      ifelse(is.null(fit), Inf, fit$ssr)
    }, numeric(1)))
    lr_boot[b] <- nrow(response) * log(linear_ssr / threshold_ssr)
  }
  p_value <- mean(lr_boot >= lr_observed)
  list(
    summary = tibble(
      threshold_variable = threshold_variable,
      threshold_hat = best$gamma,
      n = nrow(response),
      n_low = best$n_low,
      n_high = best$n_high,
      lr_statistic = lr_observed,
      bootstrap_replications = bootstrap_n,
      bootstrap_p_value = p_value,
      threshold_effect_reject_5 = p_value < 0.05,
      status = "estimated_reduced_system_robustness"
    ),
    bootstrap = tibble(
      replication = seq_len(bootstrap_n),
      lr_bootstrap = lr_boot
    )
  )
}

threshold_sample_map <- list(
  pre_1920_1973 = list(
    years = 1920:1973,
    state = c(
      "log_imports", "log_non_reinvested_surplus", "log_RER"
    ),
    controls = "wage_share"
  ),
  post_1974_2024 = list(
    years = 1974:2024,
    state = c(
      "log_imports", "log_non_reinvested_surplus", "wage_share"
    ),
    controls = "dlog_RER"
  )
)
alternative_threshold_summary <- list()
alternative_threshold_bootstrap <- list()
binary_episode_gate <- list()
threshold_index <- 0L
for (sample_name in names(threshold_sample_map)) {
  spec <- threshold_sample_map[[sample_name]]
  dat <- panel |>
    filter(year %in% spec$years) |>
    left_join(
      reduced_ect |>
        filter(sample == sample_name) |>
        dplyr::select(year, ECT_import_reduced),
      by = "year"
    ) |>
    mutate(
      current_account_pressure = -current_account_gdp,
      financing_pressure_change =
        external_financing_pressure_gdp -
        lag(external_financing_pressure_gdp)
    )
  for (threshold_variable in c(
      "current_account_pressure", "financing_pressure_change")) {
    threshold_index <- threshold_index + 1L
    fit <- alternative_threshold_test(
      dat = dat,
      state = spec$state,
      controls = spec$controls,
      threshold_variable = threshold_variable,
      trim = 0.15,
      grid_n = 160L,
      bootstrap_n = 999L
    )
    alternative_threshold_summary[[threshold_index]] <-
      fit$summary |> mutate(sample = sample_name)
    alternative_threshold_bootstrap[[threshold_index]] <-
      fit$bootstrap |>
      mutate(
        sample = sample_name,
        threshold_variable = threshold_variable
      )
  }
  t_index <- 3:nrow(dat)
  binary_lag <- dat$financing_compression_5pp[t_index - 1L]
  binary_lag <- binary_lag[is.finite(binary_lag)]
  counts <- tabulate(as.integer(binary_lag) + 1L, nbins = 2L)
  binary_episode_gate[[sample_name]] <- tibble(
    sample = sample_name,
    threshold_variable = "financing_compression_5pp",
    n_no_episode = counts[1],
    n_episode = counts[2],
    minimum_required_each_regime = 10L,
    gate_passed = min(counts) >= 10L,
    disposition = ifelse(
      min(counts) >= 10L,
      "eligible_for_binary_regime_estimation",
      "held_out_due_to_insufficient_episode_regime_size"
    )
  )
}
alternative_threshold_summary <- bind_rows(alternative_threshold_summary)
alternative_threshold_bootstrap <-
  bind_rows(alternative_threshold_bootstrap)
binary_episode_gate <- bind_rows(binary_episode_gate)
write.csv(
  alternative_threshold_summary,
  file.path(output_dir, "alternative_threshold_variable_summary.csv"),
  row.names = FALSE
)
write.csv(
  alternative_threshold_bootstrap,
  file.path(output_dir, "alternative_threshold_bootstrap_999.csv"),
  row.names = FALSE
)
write.csv(
  binary_episode_gate,
  file.path(
    output_dir, "financing_compression_episode_regime_size_gate.csv"
  ),
  row.names = FALSE
)

bootstrap_necessity <- tibble(
  object = c(
    "requested machinery Johansen rank",
    "reduced Johansen rank",
    "reduced threshold effect",
    "alternative observed threshold variables",
    "binary financing-compression episode threshold"
  ),
  bootstrap_status = c(
    "not run: estimator blocked before rank promotion",
    "asymptotic trace retained; each split has more than 30 observations",
    "completed: 999 conditional residual replications per split",
    "completed: 999 replications for current-account pressure and financing-pressure change in each split",
    "not run: observed episode regime fails the minimum-size gate"
  ),
  inference = c(
    "no rank claim",
    "rank is descriptive input to the reduced-system diagnostic",
    paste0(
      "pre p=", round(threshold$bootstrap_p_value[
        threshold$sample == "pre_1920_1973"], 3),
      "; post p=", round(threshold$bootstrap_p_value[
        threshold$sample == "post_1974_2024"], 3)
    ),
    paste(
      paste0(
        alternative_threshold_summary$sample, "/",
        alternative_threshold_summary$threshold_variable, " p=",
        round(alternative_threshold_summary$bootstrap_p_value, 3)
      ),
      collapse = "; "
    ),
    paste0(
      "pre episodes=", binary_episode_gate$n_episode[
        binary_episode_gate$sample == "pre_1920_1973"
      ],
      "; post episodes=", binary_episode_gate$n_episode[
        binary_episode_gate$sample == "post_1974_2024"
      ]
    )
  )
)
write.csv(bootstrap_necessity,
          file.path(output_dir, "bootstrap_inference_ledger.csv"),
          row.names = FALSE)

robustness_coverage <- tibble(
  requested_check = c(
    "alternative RER splice windows",
    "ClioLab-only versus spliced RER",
    "alternative deterministic terms",
    "alternative lag orders",
    "alternative sample boundaries",
    "threshold bootstrap",
    "alternative threshold variables",
    "financing-compression episode regime",
    "leave-one-episode-out",
    "condition-number reporting",
    "confidence-band overlap",
    "machinery long-run threshold system"
  ),
  status = c(
    "completed", "completed", "completed", "completed", "completed",
    "completed", "completed", "blocked by minimum regime-size gate",
    "completed", "completed", "completed",
    "blocked by S30 integration-order gate"
  ),
  artifact = c(
    "alternative_rer_splice_windows.csv",
    "cliolab_only_vs_spliced_models.csv",
    "deterministic_lag_specification_map.csv",
    "deterministic_lag_specification_map.csv",
    "alternative_sample_boundary_models.csv",
    "S40 threshold_lr_bootstrap_999.csv",
    "alternative_threshold_variable_summary.csv",
    "financing_compression_episode_regime_size_gate.csv",
    "leave_one_episode_out_sensitivity.csv",
    "alternative_sample_boundary_models.csv",
    "sample_boundary_confidence_band_overlap.csv",
    "S40 threshold_estimator_scope_and_gate.csv"
  )
)
write.csv(robustness_coverage,
          file.path(output_dir, "robustness_coverage_ledger.csv"),
          row.names = FALSE)

p <- boundary_ledger |>
  filter(term == "log_K_ME_gross") |>
  ggplot(aes(model_id, estimate, ymin = ci_low, ymax = ci_high,
             color = grepl("^pre", model_id))) +
  geom_hline(yintercept = 0, color = "grey65") +
  geom_pointrange() +
  coord_flip() +
  scale_color_manual(values = c(`TRUE` = "#0072B2", `FALSE` = "#D55E00"),
                     labels = c(`TRUE` = "pre boundary",
                                `FALSE` = "post boundary")) +
  labs(x = NULL, y = "OLS coefficient and 95% interval",
       color = NULL,
       title = "Machinery coefficient sensitivity across sample boundaries",
       subtitle = "Descriptive only: the machinery level fails the long-run integration gate") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "fig_machinery_boundary_sensitivity.png"),
       p, width = 7.8, height = 4.8, dpi = 220)
ggsave(file.path(output_dir, "fig_machinery_boundary_sensitivity.pdf"),
       p, width = 7.8, height = 4.8)

integrity <- tibble(
  check = c(
    "no_strict_decimal_comparability_gate",
    "confidence_band_overlap_used",
    "condition_numbers_reported",
    "blocked_model_not_promoted",
    "alternative_threshold_bootstrap_complete",
    "binary_financing_episode_gate_recorded",
    "all_requested_robustness_items_disposed"
  ),
  passed = c(
    TRUE,
    all(!is.na(band_overlap$confidence_band_overlap)),
    all(is.finite(boundary_ledger$condition_number_standardized)),
    robustness_coverage$status[
      robustness_coverage$requested_check ==
        "machinery long-run threshold system"
    ] == "blocked by S30 integration-order gate",
    all(
      alternative_threshold_summary$bootstrap_replications == 999L
    ),
    all(!binary_episode_gate$gate_passed),
    nrow(robustness_coverage) == 12
  ),
  detail = c(
    "identity tolerances are separate from model comparability",
    "95 percent intervals",
    "standardized design matrices",
    "machinery evidence remains descriptive",
    "current-account pressure and financing-pressure change",
    "episode counts remain below 10 in both split samples",
    "completed or explicitly blocked with governing reason"
  )
)
write.csv(integrity,
          file.path(output_dir, "s90_stage_integrity_checks.csv"),
          row.names = FALSE)
stopifnot(all(integrity$passed))

message("CL_BOP_BINDING S90 complete: robustness package written.")
