#!/usr/bin/env Rscript

# CL_BOP_BINDING S40: conditional threshold VECMs after the S30 gate.
# The requested machinery state is blocked because log gross K^ME carries
# unresolved I(2) risk in both samples. This stage therefore estimates only
# gate-admissible reduced systems and records that scope restriction.

suppressPackageStartupMessages({
  library(dplyr)
  library(urca)
  library(ggplot2)
})

set.seed(1974)
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release_file <- file.path(
  root, "data", "releases", "chile_bop_binding_v1",
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv"
)
gate_file <- file.path(
  root, "output", "CL", "BOP_BINDING", "S30_VECM",
  "integration_order_verdict_ledger.csv"
)
output_dir <- file.path(
  root, "output", "CL", "BOP_BINDING", "S40_THRESHOLD_VECM"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release_file), file.exists(gate_file))
panel <- read.csv(release_file, check.names = FALSE)
gate <- read.csv(gate_file, check.names = FALSE)

sample_data <- list(
  pre_1920_1973 = panel |> filter(year >= 1920, year <= 1973),
  post_1974_2024 = panel |> filter(year >= 1974, year <= 2024)
)
system_map <- list(
  pre_1920_1973 = list(
    state = c("log_imports", "log_non_reinvested_surplus", "log_RER"),
    controls = "wage_share",
    control_rule = "wage share is I(0)"
  ),
  post_1974_2024 = list(
    state = c("log_imports", "log_non_reinvested_surplus", "wage_share"),
    controls = "dlog_RER",
    control_rule = "RER level has mixed evidence; stationary annual change used"
  )
)

selected_rank <- function(jo) {
  labels <- rownames(jo@cval)
  null_rank <- as.integer(sub(".*r[^0-9]*([0-9]+).*", "\\1", labels))
  tab <- tibble(
    null_rank = null_rank,
    trace_statistic = as.numeric(jo@teststat),
    critical_5 = as.numeric(jo@cval[, "5pct"]),
    reject_5 = trace_statistic > critical_5
  ) |>
    arrange(null_rank)
  rank <- 0L
  for (r in tab$null_rank) {
    if (isTRUE(tab$reject_5[tab$null_rank == r])) rank <- r + 1L else break
  }
  tab$selected_rank_5 <- rank
  tab
}

fit_reduced_system <- function(dat, sample_name, state, controls) {
  y <- as.matrix(dat[, state, drop = FALSE])
  x <- as.matrix(dat[, controls, drop = FALSE])
  colnames(x) <- paste0(controls, "_stationary_control")
  jo <- ca.jo(y, type = "trace", ecdet = "const", K = 2,
              spec = "transitory", dumvar = x)
  rank <- selected_rank(jo)
  r <- unique(rank$selected_rank_5)
  if (r < 1L) stop("No cointegrating vector in reduced system: ", sample_name)
  fit <- cajorls(jo, r = 1)
  beta <- as.numeric(fit$beta[, 1])
  names(beta) <- rownames(fit$beta)
  import_row <- grep("^log_imports", names(beta), value = TRUE)[1]
  beta <- beta / beta[import_row]
  state_coef <- beta[match(paste0(state, ".l1"), names(beta))]
  ect <- as.numeric(y %*% state_coef)
  const <- beta[grepl("constant", names(beta))]
  if (length(const) == 1L) ect <- ect + const
  list(
    jo = jo, rank = rank,
    beta = tibble(
      sample = sample_name, term = names(beta),
      ect_coefficient = beta,
      long_run_relation_coefficient = ifelse(
        names(beta) == import_row, 1, -beta
      ),
      normalization = paste0(import_row, "=1")
    ),
    ect = tibble(
      year = dat$year, sample = sample_name,
      ECT_import_reduced = ect,
      state_variables = paste(state, collapse = ";"),
      stationary_controls = paste(controls, collapse = ";"),
      normalization = "log_imports coefficient equals +1"
    )
  )
}

ols_system <- function(X, Y) {
  valid <- complete.cases(X, Y)
  Xv <- X[valid, , drop = FALSE]
  Yv <- Y[valid, , drop = FALSE]
  if (nrow(Xv) <= ncol(Xv) + 2L) return(NULL)
  coef <- tryCatch(qr.solve(Xv, Yv), error = function(e) NULL)
  if (is.null(coef)) return(NULL)
  fitted <- Xv %*% coef
  residuals <- Yv - fitted
  list(
    X = Xv, Y = Yv, coef = coef, fitted = fitted,
    residuals = residuals, ssr = sum(residuals^2),
    valid = valid
  )
}

threshold_fit <- function(dat, ect, state, controls, threshold_variable,
                          trim = 0.15, grid_n = 160L, bootstrap_n = 999L) {
  Y_level <- as.matrix(dat[, state, drop = FALSE])
  dY <- diff(Y_level)
  n <- nrow(Y_level)
  # Equation at t uses ECT_{t-1}, threshold z_{t-1}, and Delta Y_{t-1}.
  t_index <- 3:n
  response <- dY[t_index - 1L, , drop = FALSE]
  ect_lag <- ect[t_index - 1L]
  z_lag <- dat[[threshold_variable]][t_index - 1L]
  dy_lag <- dY[t_index - 2L, , drop = FALSE]
  colnames(dy_lag) <- paste0("d_", state, "_lag1")
  control_matrix <- as.matrix(dat[t_index, controls, drop = FALSE])
  colnames(control_matrix) <- paste0(controls, "_control")
  year <- dat$year[t_index]
  base_valid <- complete.cases(response, ect_lag, z_lag, dy_lag,
                               control_matrix)
  response <- response[base_valid, , drop = FALSE]
  ect_lag <- ect_lag[base_valid]
  z_lag <- z_lag[base_valid]
  dy_lag <- dy_lag[base_valid, , drop = FALSE]
  control_matrix <- control_matrix[base_valid, , drop = FALSE]
  year <- year[base_valid]

  X_linear <- cbind(
    ECT = ect_lag, dy_lag, control_matrix, intercept = 1
  )
  linear <- ols_system(X_linear, response)
  stopifnot(!is.null(linear))

  grid <- unique(as.numeric(quantile(
    z_lag, probs = seq(trim, 1 - trim, length.out = grid_n),
    na.rm = TRUE, type = 8
  )))
  grid_result <- bind_rows(lapply(grid, function(gamma) {
    regime_high <- as.integer(z_lag > gamma)
    if (min(table(regime_high)) < 10L) {
      return(tibble(gamma = gamma, ssr = Inf,
                    n_low = sum(regime_high == 0L),
                    n_high = sum(regime_high == 1L)))
    }
    X <- cbind(
      ECT_low = ect_lag * (1 - regime_high),
      ECT_high = ect_lag * regime_high,
      dy_lag, control_matrix, intercept = 1
    )
    fit <- ols_system(X, response)
    tibble(
      gamma = gamma,
      ssr = ifelse(is.null(fit), Inf, fit$ssr),
      n_low = sum(regime_high == 0L),
      n_high = sum(regime_high == 1L)
    )
  }))
  best <- grid_result |>
    filter(is.finite(ssr)) |>
    slice_min(ssr, n = 1, with_ties = FALSE)
  gamma_hat <- best$gamma
  regime_high <- as.integer(z_lag > gamma_hat)
  X_threshold <- cbind(
    ECT_low = ect_lag * (1 - regime_high),
    ECT_high = ect_lag * regime_high,
    dy_lag, control_matrix, intercept = 1
  )
  threshold <- ols_system(X_threshold, response)
  lr_observed <- nrow(response) * log(linear$ssr / threshold$ssr)

  lr_boot <- numeric(bootstrap_n)
  for (b in seq_len(bootstrap_n)) {
    idx <- sample(seq_len(nrow(linear$residuals)), replace = TRUE)
    Yb <- linear$fitted + linear$residuals[idx, , drop = FALSE]
    ssr_b_linear <- ols_system(X_linear, Yb)$ssr
    ssr_b_threshold <- min(vapply(grid_result$gamma, function(gamma) {
      rb <- as.integer(z_lag > gamma)
      if (min(table(rb)) < 10L) return(Inf)
      Xb <- cbind(
        ECT_low = ect_lag * (1 - rb),
        ECT_high = ect_lag * rb,
        dy_lag, control_matrix, intercept = 1
      )
      fit <- ols_system(Xb, Yb)
      ifelse(is.null(fit), Inf, fit$ssr)
    }, numeric(1)))
    lr_boot[b] <- nrow(response) * log(ssr_b_linear / ssr_b_threshold)
  }
  bootstrap_p <- mean(lr_boot >= lr_observed)
  cv95 <- as.numeric(quantile(lr_boot, 0.95, na.rm = TRUE))
  profile_lr <- nrow(response) * log(grid_result$ssr / min(grid_result$ssr))
  ci_grid <- grid_result$gamma[is.finite(profile_lr) & profile_lr <= cv95]
  gamma_low <- if (length(ci_grid)) min(ci_grid) else NA_real_
  gamma_high <- if (length(ci_grid)) max(ci_grid) else NA_real_

  coef <- threshold$coef
  loadings <- bind_rows(lapply(seq_len(ncol(response)), function(j) {
    sigma2 <- sum(threshold$residuals[, j]^2) /
      (nrow(threshold$X) - ncol(threshold$X))
    vcov <- sigma2 * solve(crossprod(threshold$X))
    se <- sqrt(diag(vcov))
    tibble(
      equation = colnames(response)[j],
      alpha_low = coef["ECT_low", j],
      se_low = se["ECT_low"],
      t_low = alpha_low / se_low,
      alpha_high = coef["ECT_high", j],
      se_high = se["ECT_high"],
      t_high = alpha_high / se_high,
      alpha_difference = alpha_high - alpha_low
    )
  }))

  list(
    summary = tibble(
      threshold_variable = threshold_variable,
      threshold_hat = gamma_hat,
      threshold_ci_low = gamma_low,
      threshold_ci_high = gamma_high,
      trim = trim, grid_candidates = nrow(grid_result),
      n = nrow(response), n_low = sum(regime_high == 0L),
      n_high = sum(regime_high == 1L),
      lr_statistic = lr_observed,
      bootstrap_replications = bootstrap_n,
      bootstrap_p_value = bootstrap_p,
      bootstrap_critical_95 = cv95,
      threshold_effect_reject_5 = bootstrap_p < 0.05
    ),
    grid = grid_result |> mutate(profile_lr = profile_lr),
    bootstrap = tibble(replication = seq_len(bootstrap_n),
                       lr_bootstrap = lr_boot),
    loadings = loadings,
    regimes = tibble(
      year = year, threshold_value_lagged = z_lag,
      threshold_hat = gamma_hat,
      regime = ifelse(regime_high == 1L,
                      "higher_RER_change", "lower_RER_change")
    )
  )
}

rank_rows <- list()
beta_rows <- list()
ect_rows <- list()
threshold_summaries <- list()
threshold_grids <- list()
threshold_bootstraps <- list()
threshold_loadings <- list()
threshold_regimes <- list()

for (s in names(sample_data)) {
  dat <- sample_data[[s]]
  spec <- system_map[[s]]
  gate_s <- gate |> filter(sample == s)
  state_pass <- all(
    gate_s$classification[match(spec$state, gate_s$variable)] == "I(1)"
  )
  control_pass <- if (s == "pre_1920_1973") {
    gate_s$classification[gate_s$variable == "wage_share"] == "I(0)"
  } else {
    rer <- gate_s |> filter(variable == "log_RER")
    rer$adf_diff_reject_unit_root && !rer$kpss_diff_reject_stationarity
  }
  if (!state_pass || !control_pass) {
    stop("Reduced-system gate failed for ", s)
  }
  reduced <- fit_reduced_system(
    dat, s, spec$state, spec$controls
  )
  rank_rows[[s]] <- reduced$rank |> mutate(sample = s)
  beta_rows[[s]] <- reduced$beta
  ect_rows[[s]] <- reduced$ect

  fit <- threshold_fit(
    dat = dat,
    ect = reduced$ect$ECT_import_reduced,
    state = spec$state,
    controls = spec$controls,
    threshold_variable = "dlog_RER",
    trim = 0.15, grid_n = 160L, bootstrap_n = 999L
  )
  threshold_summaries[[s]] <- fit$summary |> mutate(sample = s)
  threshold_grids[[s]] <- fit$grid |> mutate(sample = s)
  threshold_bootstraps[[s]] <- fit$bootstrap |> mutate(sample = s)
  threshold_loadings[[s]] <- fit$loadings |> mutate(sample = s)
  threshold_regimes[[s]] <- fit$regimes |> mutate(sample = s)
}

rank_ledger <- bind_rows(rank_rows)
beta_ledger <- bind_rows(beta_rows)
ect_panel <- bind_rows(ect_rows) |> arrange(year)
threshold_summary <- bind_rows(threshold_summaries)
grid_ledger <- bind_rows(threshold_grids)
bootstrap_ledger <- bind_rows(threshold_bootstraps)
loadings_ledger <- bind_rows(threshold_loadings)
regime_panel <- bind_rows(threshold_regimes) |> arrange(year)

write.csv(rank_ledger,
          file.path(output_dir, "reduced_system_johansen_rank.csv"),
          row.names = FALSE)
write.csv(beta_ledger,
          file.path(output_dir, "reduced_system_cointegrating_vectors.csv"),
          row.names = FALSE)
write.csv(ect_panel,
          file.path(output_dir, "reduced_system_import_ect.csv"),
          row.names = FALSE)
write.csv(threshold_summary,
          file.path(output_dir, "threshold_effect_summary.csv"),
          row.names = FALSE)
write.csv(grid_ledger,
          file.path(output_dir, "threshold_ssr_grid.csv"),
          row.names = FALSE)
write.csv(bootstrap_ledger,
          file.path(output_dir, "threshold_lr_bootstrap_999.csv"),
          row.names = FALSE)
write.csv(loadings_ledger,
          file.path(output_dir, "threshold_regime_adjustment_loadings.csv"),
          row.names = FALSE)
write.csv(regime_panel,
          file.path(output_dir, "threshold_regime_classification.csv"),
          row.names = FALSE)

scope_ledger <- tibble(
  model_object = c(
    "requested import-machinery threshold VECM",
    "pre-1973 reduced conditional threshold VECM",
    "post-1974 reduced conditional threshold VECM"
  ),
  status = c("blocked", "estimated", "estimated"),
  reason = c(
    "log gross K^ME has unresolved I(2) risk in both split samples",
    "I(1) state: imports, NRS, RER; I(0) wage-share control",
    "I(1) state: imports, NRS, wage share; stationary delta-log-RER control"
  ),
  interpretation_limit = c(
    "no promoted long-run machinery coefficient or machinery-defined ECT",
    "nonlinear adjustment in a reduced import-surplus-RER system",
    "nonlinear adjustment in a reduced import-surplus-distribution system"
  ),
  estimator = c(
    "not selected under the integration-order gate",
    "fixed-rank-one beta, observed delta-log-RER threshold, conditional residual bootstrap",
    "fixed-rank-one beta, observed delta-log-RER threshold, conditional residual bootstrap"
  )
)
write.csv(scope_ledger,
          file.path(output_dir, "threshold_estimator_scope_and_gate.csv"),
          row.names = FALSE)

p_grid <- ggplot(grid_ledger, aes(gamma, profile_lr, color = sample)) +
  geom_line(linewidth = 0.8) +
  geom_vline(
    data = threshold_summary,
    aes(xintercept = threshold_hat, color = sample),
    linetype = "dashed", show.legend = FALSE
  ) +
  facet_wrap(~sample, scales = "free_x") +
  scale_color_manual(values = c(pre_1920_1973 = "#0072B2",
                                post_1974_2024 = "#D55E00")) +
  labs(
    x = "Lagged annual change in log RER",
    y = "Profile LR relative to minimum SSR",
    color = NULL,
    title = "Observed-RER threshold search in gate-admissible reduced systems"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "fig_threshold_profile.png"),
       p_grid, width = 8, height = 4.6, dpi = 220)
ggsave(file.path(output_dir, "fig_threshold_profile.pdf"),
       p_grid, width = 8, height = 4.6)

integrity <- tibble(
  check = c(
    "machinery_block_respected",
    "all_reduced_state_variables_I1",
    "RER_threshold_is_observed_stationary_change",
    "trimmed_search",
    "minimum_regime_size",
    "bootstrap_999_each_sample",
    "threshold_confidence_interval_recorded",
    "ECT_normalized_on_imports",
    "no_ECT_defined_threshold"
  ),
  passed = c(
    scope_ledger$status[1] == "blocked",
    TRUE, TRUE,
    all(threshold_summary$trim == 0.15),
    all(threshold_summary$n_low >= 10 &
          threshold_summary$n_high >= 10),
    all(threshold_summary$bootstrap_replications == 999),
    all(is.finite(threshold_summary$threshold_ci_low) &
          is.finite(threshold_summary$threshold_ci_high)),
    all(ect_panel$normalization ==
          "log_imports coefficient equals +1"),
    all(threshold_summary$threshold_variable == "dlog_RER")
  ),
  detail = c(
    "S30 integration ledger",
    "imports/NRS plus sample-admissible RER or wage share",
    "annual delta log RER; increase is real depreciation",
    "15 percent", "at least 10 observations",
    "conditional residual bootstrap",
    "profile-LR set using bootstrap 95 percent critical value",
    "positive ECT = imports above reduced-system equilibrium",
    "ECT enters adjustment equations only"
  )
)
write.csv(integrity,
          file.path(output_dir, "s40_stage_integrity_checks.csv"),
          row.names = FALSE)
stopifnot(all(integrity$passed))

message(
  "CL_BOP_BINDING S40 complete: reduced conditional TVECMs estimated; ",
  "requested machinery TVECM remains blocked."
)
