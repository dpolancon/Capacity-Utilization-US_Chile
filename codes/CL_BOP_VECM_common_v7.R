#!/usr/bin/env Rscript

# CL_BOP_BINDING v7: shared linear-VECM helpers.
#
# Adapted from codes/CL_S30_rer_controlled_vecm.R (v1 stage), which is left
# untouched. This file defines functions only and runs no estimation, so it can
# be sourced by the v7 estimation and chronology stages without side effects.
#
# extract_gamma() is new: the v1 stage recorded the error-correction row of each
# equation but never the short-run coefficients.

suppressPackageStartupMessages({
  library(dplyr)
})
# urca and vars are called through their namespaces rather than attached. vars
# attaches MASS, whose select() masks dplyr's, and a caller that already has
# dplyr attached cannot re-order it. Namespacing keeps the caller's search path
# untouched.
stopifnot(requireNamespace("urca", quietly = TRUE),
          requireNamespace("vars", quietly = TRUE))

# Johansen trace sequence with critical values and the sequentially selected
# rank. The selection walks up from r = 0 and stops at the first null it cannot
# reject, which is the standard reading of the trace sequence.
bop_rank_table <- function(jo, model_id) {
  stats <- as.numeric(jo@teststat)
  cv <- as.data.frame(jo@cval)
  labels <- rownames(jo@cval)
  null_rank <- as.integer(sub(".*r[^0-9]*([0-9]+).*", "\\1", labels))
  if (anyNA(null_rank)) null_rank <- rev(seq_along(stats) - 1L)
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

# Rank-one cointegrating vector, normalized so the import coefficient is +1.
# long_run_relation_coefficient is the coefficient as it reads in the solved
# long-run relation, so a positive value means imports rise with that variable.
bop_extract_beta <- function(jo, model_id, sample_name, specification,
                             deterministic, lag_order) {
  fit <- urca::cajorls(jo, r = 1)
  beta_raw <- as.numeric(fit$beta[, 1])
  names(beta_raw) <- rownames(fit$beta)
  import_row <- grep("^log_imports", names(beta_raw), value = TRUE)[1]
  if (is.na(import_row) || !is.finite(beta_raw[import_row]) ||
      abs(beta_raw[import_row]) < 1e-10) {
    return(tibble())
  }
  # Normalizing on imports divides the whole vector by the import loading. When
  # imports barely enter the estimated cointegrating space that loading is near
  # zero, and the normalized coefficients inflate into magnitudes that cannot be
  # read as elasticities. The import loading's share of the vector norm records
  # whether the normalization carries information or is an artifact of dividing
  # by a small number.
  state_loadings <- beta_raw[!grepl("constant|trend", names(beta_raw))]
  import_norm_share <- abs(beta_raw[import_row]) /
    sqrt(sum(state_loadings^2, na.rm = TRUE))
  beta <- beta_raw / beta_raw[import_row]
  tibble(
    model_id = model_id, sample = sample_name,
    specification = specification,
    deterministic = deterministic, lag_order = lag_order,
    term = names(beta), ect_coefficient = beta,
    long_run_relation_coefficient = ifelse(names(beta) == import_row, 1, -beta),
    loading_normalized_on_imports = beta,
    import_normalization_share = as.numeric(import_norm_share),
    normalization_reliable = as.numeric(import_norm_share) >= 0.10,
    normalization = paste0(import_row, "=1")
  )
}

# Speed of adjustment. One row per equation: the loading on the error-correction
# term, its standard error and t ratio. A coefficient indistinguishable from zero
# says that variable does not respond to the disequilibrium, which is the weak
# exogeneity reading.
bop_extract_alpha <- function(jo, model_id, sample_name, specification,
                              deterministic, lag_order) {
  fit <- urca::cajorls(jo, r = 1)
  sm <- summary(fit$rlm)
  eq_names <- colnames(jo@Z0)
  bind_rows(lapply(seq_along(sm), function(i) {
    cm <- sm[[i]]$coefficients
    ect_row <- grep("^ect", rownames(cm), value = TRUE)[1]
    if (is.na(ect_row)) return(tibble())
    tibble(
      model_id = model_id, sample = sample_name,
      specification = specification,
      deterministic = deterministic, lag_order = lag_order,
      equation = ifelse(length(eq_names) >= i, eq_names[i], paste0("eq", i)),
      alpha = cm[ect_row, "Estimate"],
      standard_error = cm[ect_row, "Std. Error"],
      t_statistic = cm[ect_row, "t value"],
      p_value = cm[ect_row, "Pr(>|t|)"],
      adjusts_to_disequilibrium_5 = p_value < 0.05,
      weakly_exogenous_5 = p_value >= 0.05
    )
  }))
}

# Short-run structure: every coefficient in each equation that is not the
# error-correction loading. These are the within-period dynamics, reported with
# significance so the report can say what moves imports inside the year.
bop_extract_gamma <- function(jo, model_id, sample_name, specification,
                              deterministic, lag_order) {
  fit <- urca::cajorls(jo, r = 1)
  sm <- summary(fit$rlm)
  eq_names <- colnames(jo@Z0)
  bind_rows(lapply(seq_along(sm), function(i) {
    cm <- sm[[i]]$coefficients
    keep <- !grepl("^ect", rownames(cm))
    if (!any(keep)) return(tibble())
    cm <- cm[keep, , drop = FALSE]
    tibble(
      model_id = model_id, sample = sample_name,
      specification = specification,
      deterministic = deterministic, lag_order = lag_order,
      equation = ifelse(length(eq_names) >= i, eq_names[i], paste0("eq", i)),
      term = rownames(cm),
      estimate = cm[, "Estimate"],
      standard_error = cm[, "Std. Error"],
      t_statistic = cm[, "t value"],
      p_value = cm[, "Pr(>|t|)"],
      significant_5 = p_value < 0.05
    )
  }))
}

# Companion-root diagnostic.
#
# A cointegrated system with n variables and rank r carries n - r unit roots by
# construction, so "largest modulus below one" is the wrong adequacy condition --
# it rejects every correctly specified VECM. The condition is that the roots
# beyond those n - r sit inside the unit circle. vars::roots() also requires a
# varest object and errors on the vec2var output, so the levels VAR is refitted
# here to obtain the companion eigenvalues.
bop_companion_roots <- function(y, lag_order, rank) {
  v <- tryCatch(vars::VAR(y, p = lag_order, type = "const"),
                error = function(e) NULL)
  if (is.null(v)) return(NULL)
  rts <- tryCatch(vars::roots(v), error = function(e) NULL)
  if (is.null(rts) || !length(rts)) return(NULL)
  mods <- sort(Mod(rts), decreasing = TRUE)
  n_unit <- max(0L, ncol(y) - rank)
  remaining <- if (length(mods) > n_unit) {
    mods[(n_unit + 1L):length(mods)]
  } else numeric(0)
  list(
    max_modulus = mods[1],
    implied_unit_roots = n_unit,
    max_modulus_beyond_unit_roots = if (length(remaining)) max(remaining) else
      NA_real_
  )
}

# Fit one Johansen system and return the rank sequence, the cointegrating vector,
# the adjustment speeds, the short-run structure, and model adequacy diagnostics.
bop_fit_johansen <- function(dat, sample_name, specification, state_vars,
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
  jo <- tryCatch(
    urca::ca.jo(y, type = "trace", ecdet = deterministic, K = lag_order,
          spec = "transitory", dumvar = controls),
    error = function(e) e
  )
  if (inherits(jo, "error")) {
    return(list(
      jo = NULL, ranks = tibble(), beta = tibble(), alpha = tibble(),
      gamma = tibble(),
      diagnostic = tibble(
        model_id = model_id, sample = sample_name,
        specification = specification, model_role = model_role,
        state_variables = paste(state_vars, collapse = ";"),
        stationary_controls = paste(control_vars, collapse = ";"),
        deterministic = deterministic, lag_order = lag_order,
        status = "failed", error = conditionMessage(jo),
        selected_rank_5 = NA_integer_, n = nrow(dat),
        serial_portmanteau_stat = NA_real_, serial_portmanteau_p = NA_real_,
        maximum_companion_root = NA_real_, implied_unit_roots = NA_integer_,
        max_modulus_beyond_unit_roots = NA_real_, stable_roots = NA
      )
    ))
  }
  ranks <- bop_rank_table(jo, model_id)
  selected_rank <- unique(ranks$selected_rank_5)
  beta <- bop_extract_beta(jo, model_id, sample_name, specification,
                           deterministic, lag_order)
  alpha <- bop_extract_alpha(jo, model_id, sample_name, specification,
                             deterministic, lag_order)
  gamma <- bop_extract_gamma(jo, model_id, sample_name, specification,
                             deterministic, lag_order)
  diagnostic <- tibble(
    model_id = model_id, sample = sample_name,
    specification = specification, model_role = model_role,
    state_variables = paste(state_vars, collapse = ";"),
    stationary_controls = paste(control_vars, collapse = ";"),
    deterministic = deterministic, lag_order = lag_order,
    status = "estimated", error = NA_character_,
    selected_rank_5 = selected_rank,
    n = nrow(dat), serial_portmanteau_stat = NA_real_,
    serial_portmanteau_p = NA_real_,
    maximum_companion_root = NA_real_, implied_unit_roots = NA_integer_,
    max_modulus_beyond_unit_roots = NA_real_, stable_roots = NA
  )
  if (selected_rank >= 1L && selected_rank < ncol(y)) {
    vec <- tryCatch(vars::vec2var(jo, r = selected_rank), error = function(e) NULL)
    if (!is.null(vec)) {
      serial <- tryCatch(
        vars::serial.test(vec, lags.pt = min(8L, floor(nrow(dat) / 4)),
                    type = "PT.asymptotic"),
        error = function(e) NULL
      )
      if (!is.null(serial)) {
        diagnostic$serial_portmanteau_stat <-
          as.numeric(serial$serial$statistic)
        diagnostic$serial_portmanteau_p <- as.numeric(serial$serial$p.value)
      }
    }
    rts <- bop_companion_roots(y, lag_order, selected_rank)
    if (!is.null(rts)) {
      diagnostic$maximum_companion_root <- rts$max_modulus
      diagnostic$implied_unit_roots <- rts$implied_unit_roots
      diagnostic$max_modulus_beyond_unit_roots <-
        rts$max_modulus_beyond_unit_roots
      diagnostic$stable_roots <- is.finite(rts$max_modulus_beyond_unit_roots) &&
        rts$max_modulus_beyond_unit_roots < 1
    }
  }
  list(jo = jo, ranks = ranks, beta = beta, alpha = alpha, gamma = gamma,
       diagnostic = diagnostic)
}

# What the information criteria want, recorded alongside whatever lag is imposed.
bop_select_lag <- function(dat, vars) {
  x <- as.matrix(dat[, vars, drop = FALSE])
  out <- vars::VARselect(x, lag.max = max(2L, min(4L, floor(nrow(x) / 8))),
                   type = "const")
  selected <- as.integer(out$selection[c("AIC(n)", "HQ(n)", "SC(n)", "FPE(n)")])
  tibble(
    criterion = names(out$selection)[seq_along(selected)],
    selected_lag = selected,
    chosen_lag = max(2L, min(4L, as.integer(stats::median(selected))))
  )
}

# The misalignment series: how far actual imports sit from the long-run
# requirement implied by the cointegrating vector. Built from the contemporaneous
# state, so each value is dated to the year it was measured. Positive means
# imports exceed the estimated requirement.
bop_build_ect <- function(dat, state_vars, beta_ledger, model_id) {
  beta <- beta_ledger |>
    filter(model_id == !!model_id) |>
    select(term, ect_coefficient)
  if (!nrow(beta)) return(tibble())
  beta_vec <- beta$ect_coefficient
  names(beta_vec) <- beta$term
  state <- as.matrix(dat[, state_vars, drop = FALSE])
  state_lag_names <- paste0(colnames(state), ".l1")
  coef_state <- beta_vec[match(state_lag_names, names(beta_vec))]
  if (anyNA(coef_state)) return(tibble())
  ect <- as.numeric(state %*% coef_state)
  const_term <- beta_vec[grepl("constant", names(beta_vec))]
  if (length(const_term) == 1L) ect <- ect + const_term
  trend_term <- beta_vec[grepl("trend", names(beta_vec))]
  if (length(trend_term) == 1L) ect <- ect + trend_term * seq_len(nrow(dat))
  tibble(
    year = dat$year, ECT_import = ect,
    ECT_normalization = "log_imports coefficient equals +1",
    ECT_interpretation =
      "positive means actual imports exceed the estimated long-run requirement"
  )
}

# Percentile confidence interval for the long-run coefficients by resampling
# rows. Reported because the split samples are short enough that asymptotic
# standard errors overstate precision.
bop_beta_bootstrap <- function(dat, state_vars, sample_name, replications = 499L) {
  y <- dat[[state_vars[1]]]
  x_vars <- setdiff(state_vars, state_vars[1])
  if (!length(x_vars)) return(list(records = tibble(), summary = tibble()))
  x <- dat[, x_vars, drop = FALSE]
  records <- bind_rows(lapply(seq_len(replications), function(i) {
    idx <- sample(seq_len(nrow(dat)), replace = TRUE)
    boot_dat <- data.frame(y = y[idx], x[idx, , drop = FALSE])
    cf <- tryCatch(coef(lm(y ~ ., data = boot_dat)),
                   error = function(e) rep(NA_real_, ncol(x) + 1L))
    tibble(sample = sample_name, replication = i,
           term = names(cf), coefficient = as.numeric(cf))
  }))
  summary_tbl <- records |>
    group_by(sample, term) |>
    summarise(
      estimate_median = median(coefficient, na.rm = TRUE),
      ci_low = quantile(coefficient, 0.025, na.rm = TRUE),
      ci_high = quantile(coefficient, 0.975, na.rm = TRUE),
      replications = sum(is.finite(coefficient)),
      .groups = "drop"
    )
  list(records = records, summary = summary_tbl)
}
