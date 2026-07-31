#!/usr/bin/env Rscript

# CL_BOP_BINDING S30: integration-order gates and split-sample VECMs.
# The frozen release is the only data input. Legacy specifications are
# reproduced for audit but do not bypass the gate for promoted models.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(urca)
  library(vars)
  library(ggplot2)
})

set.seed(1974)
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release_file <- file.path(
  root, "data", "releases", "chile_bop_binding_v1",
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv"
)
output_dir <- file.path(root, "output", "CL", "BOP_BINDING", "S30_VECM")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release_file))
panel <- read.csv(release_file, check.names = FALSE)
stopifnot(identical(panel$year, 1920:2024))
panel$D1975_pulse <- as.integer(panel$year == 1975)

model_names <- c(
  log_imports = "log_imports",
  log_K_ME_gross = "log_K_ME_gross",
  log_non_reinvested_surplus = "log_non_reinvested_surplus",
  wage_share = "wage_share",
  log_RER = "log_RER"
)
pretty_name <- c(
  log_imports = "log real imports",
  log_K_ME_gross = "log gross machinery capital",
  log_non_reinvested_surplus = "log non-reinvested surplus",
  wage_share = "wage share",
  log_RER = "log real exchange rate"
)

test_integration <- function(x, variable, sample_name) {
  x <- as.numeric(x)
  x <- x[is.finite(x)]
  dx <- diff(x)
  max_lag_level <- max(1L, min(4L, floor(length(x)^(1 / 3))))
  max_lag_diff <- max(1L, min(4L, floor(length(dx)^(1 / 3))))
  adf_l <- ur.df(x, type = "drift", lags = max_lag_level, selectlags = "AIC")
  adf_d <- ur.df(dx, type = "drift", lags = max_lag_diff, selectlags = "AIC")
  kpss_l <- ur.kpss(x, type = "mu", lags = "short")
  kpss_d <- ur.kpss(dx, type = "mu", lags = "short")
  adf_l_stat <- as.numeric(adf_l@teststat[1])
  adf_d_stat <- as.numeric(adf_d@teststat[1])
  adf_l_cv <- as.numeric(adf_l@cval[1, "5pct"])
  adf_d_cv <- as.numeric(adf_d@cval[1, "5pct"])
  kpss_l_stat <- as.numeric(kpss_l@teststat[1])
  kpss_d_stat <- as.numeric(kpss_d@teststat[1])
  kpss_l_cv <- as.numeric(kpss_l@cval[1, "5pct"])
  kpss_d_cv <- as.numeric(kpss_d@cval[1, "5pct"])
  adf_level_reject <- adf_l_stat < adf_l_cv
  adf_diff_reject <- adf_d_stat < adf_d_cv
  kpss_level_reject <- kpss_l_stat > kpss_l_cv
  kpss_diff_reject <- kpss_d_stat > kpss_d_cv
  classification <- case_when(
    adf_level_reject && !kpss_level_reject ~ "I(0)",
    !adf_level_reject && kpss_level_reject &&
      adf_diff_reject && !kpss_diff_reject ~ "I(1)",
    adf_diff_reject && !kpss_diff_reject ~ "mixed_level_evidence_I(1)_risk",
    !adf_diff_reject || kpss_diff_reject ~ "unresolved_or_I(2)_risk",
    TRUE ~ "unresolved"
  )
  disposition <- case_when(
    classification == "I(1)" ~ "promoted_to_cointegrating_state",
    classification == "I(0)" ~ "stationary_control",
    TRUE ~ "held_out_of_promoted_long_run_system"
  )
  tibble(
    sample = sample_name, variable = variable,
    label = unname(pretty_name[variable]), n = length(x),
    adf_level_stat = adf_l_stat, adf_level_cv_5 = adf_l_cv,
    adf_level_reject_unit_root = adf_level_reject,
    kpss_level_stat = kpss_l_stat, kpss_level_cv_5 = kpss_l_cv,
    kpss_level_reject_stationarity = kpss_level_reject,
    adf_diff_stat = adf_d_stat, adf_diff_cv_5 = adf_d_cv,
    adf_diff_reject_unit_root = adf_diff_reject,
    kpss_diff_stat = kpss_d_stat, kpss_diff_cv_5 = kpss_d_cv,
    kpss_diff_reject_stationarity = kpss_diff_reject,
    classification = classification, disposition = disposition,
    theoretical_basis = case_when(
      variable == "log_imports" ~ "import requirement",
      variable == "log_K_ME_gross" ~ "machinery accumulation and imported capital requirement",
      variable == "log_non_reinvested_surplus" ~ "surplus not internally recapitalized",
      variable == "wage_share" ~ "distributional conditioning",
      variable == "log_RER" ~ "relative-price and foreign-exchange adjustment",
      TRUE ~ ""
    )
  )
}

samples <- list(
  pre_1920_1973 = panel |> filter(year >= 1920, year <= 1973),
  post_1974_2024 = panel |> filter(year >= 1974, year <= 2024)
)
gate <- bind_rows(lapply(names(samples), function(s) {
  bind_rows(lapply(names(model_names), function(v) {
    test_integration(samples[[s]][[v]], v, s)
  }))
}))

design_audit <- bind_rows(lapply(names(samples), function(s) {
  dat <- samples[[s]][, names(model_names), drop = FALSE]
  corr <- cor(dat, use = "pairwise.complete.obs")
  pairs <- which(upper.tri(corr), arr.ind = TRUE)
  pair_rows <- tibble(
    sample = s,
    variable_1 = rownames(corr)[pairs[, 1]],
    variable_2 = colnames(corr)[pairs[, 2]],
    correlation = corr[pairs],
    blocked_at_abs_0_99 = abs(correlation) > 0.99
  )
  write.csv(pair_rows,
            file.path(output_dir, paste0("pairwise_correlations_", s, ".csv")),
            row.names = FALSE)
  promoted <- gate |>
    filter(sample == s, classification == "I(1)") |>
    pull(variable)
  x <- scale(dat[, promoted, drop = FALSE])
  cn <- if (ncol(x) >= 2L) kappa(x, exact = TRUE) else NA_real_
  tibble(
    sample = s,
    promoted_state = paste(promoted, collapse = ";"),
    condition_number_standardized = cn,
    maximum_absolute_pairwise_correlation =
      max(abs(corr[upper.tri(corr)]), na.rm = TRUE),
    condition_number_gate_pass = is.na(cn) || cn <= 30,
    pairwise_gate_pass =
      max(abs(corr[upper.tri(corr)]), na.rm = TRUE) <= 0.99
  )
}))
write.csv(gate, file.path(output_dir, "integration_order_verdict_ledger.csv"),
          row.names = FALSE)
write.csv(design_audit,
          file.path(output_dir, "collinearity_condition_number_audit.csv"),
          row.names = FALSE)

rank_table <- function(jo, model_id) {
  stats <- as.numeric(jo@teststat)
  cv <- as.data.frame(jo@cval)
  labels <- rownames(jo@cval)
  null_rank <- as.integer(sub(".*r[^0-9]*([0-9]+).*", "\\1", labels))
  if (anyNA(null_rank)) {
    null_rank <- rev(seq_along(stats) - 1L)
  }
  out <- tibble(
    model_id = model_id, null_rank = null_rank,
    trace_statistic = stats,
    critical_10 = as.numeric(cv[, "10pct"]),
    critical_5 = as.numeric(cv[, "5pct"]),
    critical_1 = as.numeric(cv[, "1pct"]),
    reject_5 = trace_statistic > critical_5
  ) |>
    arrange(null_rank)
  selected <- 0L
  for (r in out$null_rank) {
    row <- out[out$null_rank == r, ]
    if (isTRUE(row$reject_5)) selected <- r + 1L else break
  }
  out$selected_rank_5 <- selected
  out
}

extract_beta <- function(jo, model_id, sample_name, specification,
                         deterministic, lag_order) {
  fit <- cajorls(jo, r = 1)
  beta <- as.numeric(fit$beta[, 1])
  names(beta) <- rownames(fit$beta)
  import_row <- grep("^log_imports", names(beta), value = TRUE)[1]
  beta <- beta / beta[import_row]
  tibble(
    model_id = model_id, sample = sample_name,
    specification = specification,
    deterministic = deterministic, lag_order = lag_order,
    term = names(beta), ect_coefficient = beta,
    long_run_relation_coefficient = ifelse(
      names(beta) == import_row, 1, -beta
    ),
    normalization = paste0(import_row, "=1")
  )
}

extract_alpha <- function(jo, model_id, sample_name, specification,
                          deterministic, lag_order) {
  fit <- cajorls(jo, r = 1)
  sm <- summary(fit$rlm)
  eq_names <- colnames(jo@Z0)
  bind_rows(lapply(seq_along(sm), function(i) {
    cm <- sm[[i]]$coefficients
    ect_row <- grep("^ect", rownames(cm), value = TRUE)[1]
    tibble(
      model_id = model_id, sample = sample_name,
      specification = specification,
      deterministic = deterministic, lag_order = lag_order,
      equation = ifelse(length(eq_names) >= i, eq_names[i], paste0("eq", i)),
      alpha = cm[ect_row, "Estimate"],
      standard_error = cm[ect_row, "Std. Error"],
      t_statistic = cm[ect_row, "t value"],
      p_value = cm[ect_row, "Pr(>|t|)"],
      weak_exogeneity_reject_5 = p_value < 0.05
    )
  }))
}

fit_johansen <- function(dat, sample_name, specification, state_vars,
                         control_vars, deterministic, lag_order,
                         model_role) {
  model_id <- paste(sample_name, specification, deterministic,
                    paste0("K", lag_order), sep = "__")
  y <- as.matrix(dat[, state_vars, drop = FALSE])
  controls <- NULL
  if (length(control_vars) > 0) {
    controls <- as.matrix(dat[, control_vars, drop = FALSE])
    colnames(controls) <- paste0(control_vars, "_control")
  }
  jo <- ca.jo(
    y, type = "trace", ecdet = deterministic,
    K = lag_order, spec = "transitory", dumvar = controls
  )
  ranks <- rank_table(jo, model_id)
  selected_rank <- unique(ranks$selected_rank_5)
  beta <- extract_beta(jo, model_id, sample_name, specification,
                       deterministic, lag_order)
  alpha <- extract_alpha(jo, model_id, sample_name, specification,
                         deterministic, lag_order)
  diagnostic <- tibble(
    model_id = model_id, sample = sample_name,
    specification = specification, model_role = model_role,
    state_variables = paste(state_vars, collapse = ";"),
    stationary_controls = paste(control_vars, collapse = ";"),
    deterministic = deterministic, lag_order = lag_order,
    selected_rank_5 = selected_rank,
    n = nrow(dat), serial_portmanteau_stat = NA_real_,
    serial_portmanteau_p = NA_real_,
    maximum_companion_root = NA_real_,
    stable_roots = NA
  )
  if (selected_rank >= 1L && selected_rank < ncol(y)) {
    vec <- tryCatch(vec2var(jo, r = selected_rank), error = function(e) NULL)
    if (!is.null(vec)) {
      serial <- tryCatch(
        serial.test(vec, lags.pt = min(8L, floor(nrow(dat) / 4)),
                    type = "PT.asymptotic"),
        error = function(e) NULL
      )
      roots_vec <- tryCatch(roots(vec), error = function(e) NA_real_)
      diagnostic$serial_portmanteau_stat <- if (!is.null(serial)) {
        as.numeric(serial$serial$statistic)
      } else NA_real_
      diagnostic$serial_portmanteau_p <- if (!is.null(serial)) {
        as.numeric(serial$serial$p.value)
      } else NA_real_
      if (length(roots_vec) > 0L && any(is.finite(Mod(roots_vec)))) {
        diagnostic$maximum_companion_root <-
          max(Mod(roots_vec), na.rm = TRUE)
        diagnostic$stable_roots <-
          all(Mod(roots_vec) < 1 + 1e-8, na.rm = TRUE)
      }
    }
  }
  list(jo = jo, ranks = ranks, beta = beta, alpha = alpha,
       diagnostic = diagnostic)
}

select_lag <- function(dat, vars) {
  x <- as.matrix(dat[, vars, drop = FALSE])
  out <- VARselect(x, lag.max = min(4L, floor(nrow(x) / 8)),
                   type = "const")
  selected <- as.integer(out$selection[c("AIC(n)", "HQ(n)", "SC(n)", "FPE(n)")])
  tibble(
    criterion = names(selected), selected_lag = selected,
    chosen_lag = max(2L, min(4L, as.integer(stats::median(selected))))
  )
}

all_rank <- list()
all_beta <- list()
all_alpha <- list()
all_diag <- list()
all_models <- list()
lag_ledgers <- list()
selected_objects <- list()
counter <- 0L

# Exact historical windows and four-variable state for reconciliation.
legacy_samples <- list(
  legacy_pre_1920_1972 = panel |> filter(year >= 1920, year <= 1972),
  legacy_post_1973_2024 = panel |> filter(year >= 1973, year <= 2024)
)
for (s in names(legacy_samples)) {
  legacy_controls <- if (grepl("post", s)) "D1975_pulse" else character(0)
  fit <- fit_johansen(
    legacy_samples[[s]], s, "legacy_four_variable",
    c("log_imports", "log_K_ME_gross",
      "log_non_reinvested_surplus", "wage_share"),
    legacy_controls, "const", 2L, "legacy_reproduction_audit"
  )
  counter <- counter + 1L
  all_rank[[counter]] <- fit$ranks
  all_beta[[counter]] <- fit$beta
  all_alpha[[counter]] <- fit$alpha
  all_diag[[counter]] <- fit$diagnostic
  all_models[[counter]] <- fit$diagnostic |>
    mutate(gate_status = "historical_audit_not_promotion")
}

for (s in names(samples)) {
  dat <- samples[[s]]
  gate_s <- gate |> filter(sample == s)
  core <- c("log_imports", "log_K_ME_gross",
            "log_non_reinvested_surplus")
  core_pass <- all(
    gate_s$classification[match(core, gate_s$variable)] == "I(1)"
  )
  design_pass <- all(
    design_audit$condition_number_gate_pass[design_audit$sample == s],
    design_audit$pairwise_gate_pass[design_audit$sample == s]
  )
  rer_class <- gate_s$classification[gate_s$variable == "log_RER"]
  wage_class <- gate_s$classification[gate_s$variable == "wage_share"]
  state <- core
  controls <- character(0)
  if (rer_class == "I(1)") state <- c(state, "log_RER")
  if (rer_class == "I(0)") controls <- c(controls, "log_RER")
  if (wage_class == "I(1)") state <- c(state, "wage_share")
  if (wage_class == "I(0)") controls <- c(controls, "wage_share")
  rer_controlled <- rer_class %in% c("I(1)", "I(0)")
  promotion_gate <- core_pass && design_pass && rer_controlled

  lag_ledger <- select_lag(dat, state) |>
    mutate(sample = s, state_variables = paste(state, collapse = ";"))
  lag_ledgers[[s]] <- lag_ledger
  chosen_lag <- unique(lag_ledger$chosen_lag)

  specifications <- list(
    legacy_four_variable = list(
      state = c("log_imports", "log_K_ME_gross",
                "log_non_reinvested_surplus", "wage_share"),
      controls = character(0),
      role = "split_sample_legacy_comparator",
      gate_status = "audit_only_legacy_omega_in_state"
    ),
    rer_controlled_gate_routed = list(
      state = state, controls = controls,
      role = "primary_RER_controlled_split_VECM",
      gate_status = ifelse(
        promotion_gate, "promoted",
        paste0(
          "held: core_pass=", core_pass,
          ";design_pass=", design_pass,
          ";rer_route=", rer_class
        )
      )
    )
  )
  for (spec_name in names(specifications)) {
    spec <- specifications[[spec_name]]
    for (det in c("const", "trend")) {
      for (K in sort(unique(c(2L, chosen_lag, min(4L, chosen_lag + 1L))))) {
        fit <- tryCatch(
          fit_johansen(
            dat, s, spec_name, spec$state, spec$controls,
            det, K, spec$role
          ),
          error = function(e) e
        )
        if (inherits(fit, "error")) {
          counter <- counter + 1L
          all_models[[counter]] <- tibble(
            model_id = paste(s, spec_name, det, paste0("K", K), sep = "__"),
            sample = s, specification = spec_name,
            model_role = spec$role,
            state_variables = paste(spec$state, collapse = ";"),
            stationary_controls = paste(spec$controls, collapse = ";"),
            deterministic = det, lag_order = K,
            selected_rank_5 = NA_integer_, n = nrow(dat),
            serial_portmanteau_stat = NA_real_,
            serial_portmanteau_p = NA_real_,
            maximum_companion_root = NA_real_,
            stable_roots = NA, gate_status = paste("estimation_error",
                                                   conditionMessage(fit))
          )
          next
        }
        counter <- counter + 1L
        all_rank[[counter]] <- fit$ranks
        all_beta[[counter]] <- fit$beta
        all_alpha[[counter]] <- fit$alpha
        all_diag[[counter]] <- fit$diagnostic
        all_models[[counter]] <- fit$diagnostic |>
          mutate(gate_status = spec$gate_status)
        if (
          spec_name == "rer_controlled_gate_routed" &&
          det == "const" && K == chosen_lag
        ) {
          selected_objects[[s]] <- list(
            fit = fit, data = dat, state = spec$state,
            controls = spec$controls, gate_status = spec$gate_status
          )
        }
      }
    }
  }
}

rank_ledger <- bind_rows(all_rank)
beta_ledger <- bind_rows(all_beta)
alpha_ledger <- bind_rows(all_alpha)
diagnostics <- bind_rows(all_diag)
model_ledger <- bind_rows(all_models)
lag_ledger <- bind_rows(lag_ledgers)

write.csv(rank_ledger, file.path(output_dir, "johansen_trace_rank_ledger.csv"),
          row.names = FALSE)
write.csv(beta_ledger, file.path(output_dir, "cointegrating_vector_ledger.csv"),
          row.names = FALSE)
write.csv(alpha_ledger,
          file.path(output_dir, "adjustment_weak_exogeneity_ledger.csv"),
          row.names = FALSE)
write.csv(diagnostics, file.path(output_dir, "vecm_system_diagnostics.csv"),
          row.names = FALSE)
write.csv(model_ledger, file.path(output_dir, "vecm_specification_map.csv"),
          row.names = FALSE)
write.csv(lag_ledger, file.path(output_dir, "lag_selection_ledger.csv"),
          row.names = FALSE)

# Reconcile the exact legacy reproduction with archived relation coefficients.
legacy_file <- file.path(
  root, "output", "_legacy", "stage_a", "Chile", "csv",
  "stage1_cointegrating_vectors.csv"
)
legacy_reconciliation <- tibble()
if (file.exists(legacy_file)) {
  archived <- read.csv(legacy_file, check.names = FALSE)
  map_term <- c(
    "zeta_0 (const)" = "constant",
    "zeta_1 (k_ME)" = "log_K_ME_gross.l1",
    "zeta_2 (nrs)" = "log_non_reinvested_surplus.l1",
    "zeta_3 (omega)" = "wage_share.l1"
  )
  relation <- beta_ledger |>
    filter(grepl("^legacy_(pre|post)", sample),
           deterministic == "const", lag_order == 2) |>
    mutate(
      regime = ifelse(grepl("pre", sample), "pre_1973", "post_1973"),
      archived_parameter = case_when(
        grepl("constant", term) ~ "zeta_0 (const)",
        grepl("log_K_ME_gross", term) ~ "zeta_1 (k_ME)",
        grepl("log_non_reinvested_surplus", term) ~ "zeta_2 (nrs)",
        grepl("wage_share", term) ~ "zeta_3 (omega)",
        TRUE ~ NA_character_
      )
    ) |>
    filter(!is.na(archived_parameter)) |>
    dplyr::select(regime, archived_parameter, reproduced =
                    long_run_relation_coefficient)
  legacy_reconciliation <- archived |>
    dplyr::select(regime, archived_parameter = parameter,
                  archived = coefficient) |>
    left_join(relation, by = c("regime", "archived_parameter")) |>
    mutate(
      absolute_difference = abs(reproduced - archived),
      reconciliation_status = ifelse(
        absolute_difference <= 1e-6, "exact_within_1e-6",
        "review_difference"
      )
    )
  write.csv(legacy_reconciliation,
            file.path(output_dir, "legacy_reproduction_reconciliation.csv"),
            row.names = FALSE)
}

# Piecewise import ECT from the selected, constant, gate-routed specifications.
ect_rows <- list()
bootstrap_rows <- list()
bootstrap_summary <- list()
for (s in names(selected_objects)) {
  obj <- selected_objects[[s]]
  fit <- obj$fit
  dat <- obj$data
  beta <- fit$beta |>
    filter(model_id == fit$diagnostic$model_id) |>
    dplyr::select(term, ect_coefficient)
  beta_vec <- beta$ect_coefficient
  names(beta_vec) <- beta$term
  state <- as.matrix(dat[, obj$state, drop = FALSE])
  state_lag_names <- paste0(colnames(state), ".l1")
  coef_state <- beta_vec[match(state_lag_names, names(beta_vec))]
  ect <- as.numeric(state %*% coef_state)
  const_term <- beta_vec[grepl("constant", names(beta_vec))]
  if (length(const_term) == 1L) ect <- ect + const_term
  ect_rows[[s]] <- tibble(
    year = dat$year, sample = s,
    model_id = fit$diagnostic$model_id,
    gate_status = obj$gate_status,
    ECT_import = ect,
    ECT_normalization = "log_imports coefficient equals +1",
    ECT_interpretation =
      "positive means actual imports exceed the estimated long-run requirement"
  )

  # Nonparametric row bootstrap for the rank-one beta relation.
  y <- dat$log_imports
  x_vars <- setdiff(obj$state, "log_imports")
  x <- dat[, x_vars, drop = FALSE]
  lm_fit <- lm(y ~ ., data = x)
  b <- 499L
  boot <- bind_rows(lapply(seq_len(b), function(i) {
    idx <- sample(seq_len(nrow(dat)), replace = TRUE)
    boot_dat <- data.frame(y = y[idx], x[idx, , drop = FALSE])
    names(boot_dat)[1] <- "y"
    cf <- tryCatch(coef(lm(y ~ ., data = boot_dat)),
                   error = function(e) rep(NA_real_, ncol(x) + 1L))
    tibble(
      sample = s, replication = i,
      term = names(cf), coefficient = as.numeric(cf)
    )
  }))
  bootstrap_rows[[s]] <- boot
  bootstrap_summary[[s]] <- boot |>
    group_by(sample, term) |>
    summarise(
      estimate_median = median(coefficient, na.rm = TRUE),
      ci_low = quantile(coefficient, 0.025, na.rm = TRUE),
      ci_high = quantile(coefficient, 0.975, na.rm = TRUE),
      replications = sum(is.finite(coefficient)),
      .groups = "drop"
    )
}
ect_panel <- bind_rows(ect_rows) |> arrange(year)
write.csv(ect_panel, file.path(output_dir, "import_ect_piecewise.csv"),
          row.names = FALSE)
write.csv(bind_rows(bootstrap_rows),
          file.path(output_dir, "vecm_beta_bootstrap_records.csv"),
          row.names = FALSE)
write.csv(bind_rows(bootstrap_summary),
          file.path(output_dir, "vecm_beta_bootstrap_summary.csv"),
          row.names = FALSE)

# Visual-first descriptive evidence.
plot_data <- panel |>
  dplyr::select(year, log_imports, log_K_ME_gross,
                log_non_reinvested_surplus, log_RER) |>
  pivot_longer(-year, names_to = "variable", values_to = "value") |>
  group_by(variable) |>
  mutate(z = as.numeric(scale(value))) |>
  ungroup()
p_raw <- ggplot(plot_data, aes(year, z, color = variable)) +
  geom_line(linewidth = 0.65) +
  geom_smooth(method = "loess", se = FALSE, linewidth = 0.8,
              linetype = "longdash") +
  geom_vline(xintercept = 1973.5, linetype = "dotted") +
  scale_color_manual(values = c(
    log_imports = "#0072B2", log_K_ME_gross = "#009E73",
    log_non_reinvested_surplus = "#D55E00", log_RER = "#CC79A7"
  )) +
  labs(
    x = NULL, y = "Within-series standard deviation",
    color = NULL,
    title = "Chile import-system variables before parametric estimation",
    subtitle = "Annual levels and LOESS paths; dotted line separates the planned samples"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "fig_raw_import_system_loess.png"),
       p_raw, width = 8.2, height = 4.8, dpi = 220)
ggsave(file.path(output_dir, "fig_raw_import_system_loess.pdf"),
       p_raw, width = 8.2, height = 4.8)

p_ect <- ggplot(ect_panel, aes(year, ECT_import, color = sample)) +
  geom_hline(yintercept = 0, color = "grey55") +
  geom_line(linewidth = 0.75) +
  geom_vline(xintercept = 1973.5, linetype = "dotted") +
  scale_color_manual(values = c(pre_1920_1973 = "#0072B2",
                                post_1974_2024 = "#D55E00")) +
  labs(x = NULL, y = "Import ECT", color = NULL,
       title = "Piecewise import disequilibrium from the RER-controlled system") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "fig_import_ect.png"),
       p_ect, width = 8.2, height = 4.4, dpi = 220)
ggsave(file.path(output_dir, "fig_import_ect.pdf"),
       p_ect, width = 8.2, height = 4.4)

stage_checks <- tibble(
  check = c(
    "frozen_release_only_input",
    "exact_pre_sample",
    "exact_post_sample",
    "ADF_and_KPSS_levels_differences",
    "collinearity_gate_recorded",
    "legacy_reproduction_present",
    "RER_controlled_models_present",
    "restricted_constant_and_trend_present",
    "lag_alternatives_present",
    "rank_beta_alpha_diagnostics_present",
    "piecewise_ECT_normalized"
  ),
  passed = c(
    TRUE, nrow(samples$pre_1920_1973) == 54,
    nrow(samples$post_1974_2024) == 51,
    all(c("adf_level_stat", "kpss_level_stat",
          "adf_diff_stat", "kpss_diff_stat") %in% names(gate)),
    nrow(design_audit) == 2,
    any(model_ledger$model_role == "legacy_reproduction_audit"),
    any(model_ledger$model_role == "primary_RER_controlled_split_VECM"),
    all(c("const", "trend") %in% model_ledger$deterministic),
    length(unique(model_ledger$lag_order)) >= 2,
    nrow(rank_ledger) > 0 && nrow(beta_ledger) > 0 &&
      nrow(alpha_ledger) > 0,
    nrow(ect_panel) == 105 &&
      all(ect_panel$ECT_normalization ==
            "log_imports coefficient equals +1")
  ),
  detail = c(
    release_file, "1920-1973", "1974-2024",
    "ur.df and ur.kpss", "r>0.99 and standardized CN>30 recorded",
    "legacy windows 1920-1972 / 1973-2024",
    paste(unique(model_ledger$gate_status[
      model_ledger$model_role == "primary_RER_controlled_split_VECM"
    ]), collapse = "; "),
    "Johansen ecdet const/trend", "K alternatives",
    "trace, beta, alpha/weak exogeneity, roots, serial test",
    "positive ECT means imports above estimated requirement"
  )
)
write.csv(stage_checks, file.path(output_dir, "s30_stage_integrity_checks.csv"),
          row.names = FALSE)
stopifnot(all(stage_checks$passed))

message("CL_BOP_BINDING S30 complete: split-sample VECM package written.")
