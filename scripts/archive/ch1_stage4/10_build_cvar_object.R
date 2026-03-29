# CONTRACT COMPLIANCE CHECK:
# Notebook: A2_CVAR_builder
# Upstream: CVAR_RRR_MASTER_CONTRACT_v1.md
# Spec: A2_A3_SPEC_CVAR_RankGeometry_v1.md

# =============================================================================
# 10_build_cvar_object.R
# -----------------------------------------------------------------------------
# Purpose:
#   Build an admissible CVAR / VECM representation object from transformed level
#   data, under the project contract and A2/A3 specification layer.
#
# Scope:
#   This file is an implementation skeleton. It defines the object grammar,
#   validation logic, deterministic handling, lag-block construction, common-
#   sample enforcement, and canonical-matrix exposure needed for downstream
#   rank-geometry analysis.
#
# Methodological note:
#   The script is designed so that every econometric object is declared before
#   it is estimated. The theoretical mechanism must already have been translated
#   into transformed variables prior to entering this layer.
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(rlang)
  library(tibble)
  library(tidyr)
})

# -----------------------------------------------------------------------------
# 0. Configuration helpers
# -----------------------------------------------------------------------------

new_cvar_spec <- function(
    spec_id,
    window_id,
    basis_id = c("raw", "orthogonal"),
    deterministic_id = c("none", "const_restricted", "const_unrestricted",
                         "trend_restricted", "trend_unrestricted"),
    p,
    q_profile = NULL,
    variables,
    variable_roles,
    transformation_map,
    sample_start,
    sample_end,
    metadata = list()) {

  basis_id <- match.arg(basis_id)
  deterministic_id <- match.arg(deterministic_id)

  stopifnot(length(variables) >= 2)
  stopifnot(length(variable_roles) == length(variables))
  stopifnot(is.numeric(p), length(p) == 1, p >= 1)

  list(
    spec_id = spec_id,
    window_id = window_id,
    basis_id = basis_id,
    deterministic_id = deterministic_id,
    p = as.integer(p),
    q_profile = q_profile,
    variables = variables,
    variable_roles = variable_roles,
    transformation_map = transformation_map,
    sample_start = sample_start,
    sample_end = sample_end,
    metadata = metadata
  )
}

# -----------------------------------------------------------------------------
# 1. Contract-facing validation layer
# -----------------------------------------------------------------------------

validate_sample_window <- function(data, year_col, sample_start, sample_end) {
  years <- data[[year_col]]
  ok <- all(years >= sample_start & years <= sample_end)

  list(
    check = "sample_window_validation",
    passed = ok,
    details = list(
      observed_min = min(years, na.rm = TRUE),
      observed_max = max(years, na.rm = TRUE),
      expected_min = sample_start,
      expected_max = sample_end
    )
  )
}

validate_missing_values <- function(data, variables) {
  missing_counts <- vapply(data[variables], function(x) sum(is.na(x)), numeric(1))
  ok <- all(missing_counts == 0)

  list(
    check = "missing_value_validation",
    passed = ok,
    details = as.list(missing_counts)
  )
}

validate_common_numeraire <- function(transformation_map) {
  # Skeleton rule:
  # Every modeled variable should declare whether it is already expressed in a
  # common numeraire / real-log space.
  flags <- vapply(transformation_map, function(x) isTRUE(x$common_numeraire), logical(1))
  ok <- all(flags)

  list(
    check = "common_numeraire_validation",
    passed = ok,
    details = transformation_map
  )
}

validate_level_difference_consistency <- function(data, variables) {
  # Skeleton placeholder.
  # In full implementation, this should verify that differencing is applied only
  # after level alignment and that level / difference objects refer to the same
  # trimmed support.
  ok <- all(vapply(data[variables], is.numeric, logical(1)))

  list(
    check = "difference_level_consistency_validation",
    passed = ok,
    details = list(message = "Numeric level variables available for lag/difference construction.")
  )
}

validate_effective_sample <- function(n_obs, p_max) {
  t_eff <- n_obs - p_max
  ok <- isTRUE(t_eff > 0)

  list(
    check = "effective_sample_validation",
    passed = ok,
    details = list(n_obs = n_obs, p_max = p_max, T_eff_common = t_eff)
  )
}

run_a2_validations <- function(data, year_col, spec) {
  checks <- list(
    validate_sample_window(data, year_col, spec$sample_start, spec$sample_end),
    validate_missing_values(data, spec$variables),
    validate_common_numeraire(spec$transformation_map),
    validate_level_difference_consistency(data, spec$variables),
    validate_effective_sample(n_obs = nrow(data), p_max = spec$p)
  )

  passed <- all(vapply(checks, `[[`, logical(1), "passed"))

  list(
    passed = passed,
    checks = checks,
    computed_status = if (passed) "admissible" else "gate_fail"
  )
}

# -----------------------------------------------------------------------------
# 2. Deterministic components
# -----------------------------------------------------------------------------

build_deterministics <- function(n, deterministic_id) {
  t_seq <- seq_len(n)

  out <- switch(
    deterministic_id,
    none = tibble(),
    const_restricted = tibble(const_restricted = 1),
    const_unrestricted = tibble(const_unrestricted = 1),
    trend_restricted = tibble(trend_restricted = t_seq),
    trend_unrestricted = tibble(const_unrestricted = 1, trend_unrestricted = t_seq)
  )

  as_tibble(out)
}

# -----------------------------------------------------------------------------
# 3. Basis handling
# -----------------------------------------------------------------------------

build_level_matrix <- function(data, variables) {
  X <- as.matrix(data[, variables, drop = FALSE])
  storage.mode(X) <- "double"
  X
}

build_basis <- function(X, basis_id) {
  if (basis_id == "raw") {
    return(list(X_basis = X, basis_map = diag(ncol(X)), basis_label = "raw"))
  }

  qr_x <- qr(scale(X, center = TRUE, scale = FALSE))
  Q <- qr.Q(qr_x)
  R <- qr.R(qr_x)

  list(
    X_basis = Q,
    basis_map = R,
    basis_label = "orthogonal"
  )
}

# -----------------------------------------------------------------------------
# 4. Lag and difference block construction
# -----------------------------------------------------------------------------

lag_matrix <- function(X, k = 1L) {
  stopifnot(k >= 0)
  if (k == 0) return(X)
  rbind(matrix(NA_real_, nrow = k, ncol = ncol(X)), X[seq_len(nrow(X) - k), , drop = FALSE])
}

build_var_blocks <- function(X, p) {
  dX <- diff(X)
  X_lag1 <- lag_matrix(X, 1L)[-1, , drop = FALSE]

  dX_lags <- vector("list", max(p - 1L, 0L))
  if (p > 1L) {
    for (i in seq_len(p - 1L)) {
      dX_lags[[i]] <- lag_matrix(dX, i)[-(seq_len(i)), , drop = FALSE]
    }
  }

  list(
    dX = dX,
    X_lag1 = X_lag1,
    dX_lags = dX_lags
  )
}

trim_to_common_sample <- function(blocks, D = NULL, p) {
  # Common support after differencing and lagging.
  start_row <- p

  dX <- blocks$dX[start_row:nrow(blocks$dX), , drop = FALSE]
  X_lag1 <- blocks$X_lag1[start_row:nrow(blocks$X_lag1), , drop = FALSE]

  dX_lags <- purrr::map(blocks$dX_lags, ~ .x[start_row:nrow(.x), , drop = FALSE])

  D_trim <- NULL
  if (!is.null(D) && ncol(D) > 0) {
    D_trim <- as.matrix(D[(start_row + 1):nrow(D), , drop = FALSE])
  }

  list(
    dX = dX,
    X_lag1 = X_lag1,
    dX_lags = dX_lags,
    D = D_trim,
    T_eff_common = nrow(dX)
  )
}

# -----------------------------------------------------------------------------
# 5. Residual-maker and canonical blocks for Johansen-style estimation
# -----------------------------------------------------------------------------

residualize_on_Z <- function(Y, Z) {
  if (is.null(Z) || ncol(Z) == 0) return(Y)
  Mz <- diag(nrow(Z)) - Z %*% solve(crossprod(Z)) %*% t(Z)
  Mz %*% Y
}

bind_short_run_regressors <- function(dX_lags, D) {
  Z_parts <- c(dX_lags, list(D))
  Z_parts <- Z_parts[!vapply(Z_parts, is.null, logical(1))]
  Z_parts <- Z_parts[vapply(Z_parts, function(x) ncol(as.matrix(x)) > 0, logical(1))]

  if (length(Z_parts) == 0) return(NULL)
  do.call(cbind, Z_parts)
}

compute_johansen_blocks <- function(trimmed) {
  Z <- bind_short_run_regressors(trimmed$dX_lags, trimmed$D)

  R0 <- residualize_on_Z(trimmed$dX, Z)
  R1 <- residualize_on_Z(trimmed$X_lag1, Z)

  S00 <- crossprod(R0) / nrow(R0)
  S11 <- crossprod(R1) / nrow(R1)
  S01 <- crossprod(R0, R1) / nrow(R0)
  S10 <- t(S01)

  list(
    Z = Z,
    R0 = R0,
    R1 = R1,
    S00 = S00,
    S11 = S11,
    S01 = S01,
    S10 = S10
  )
}

# -----------------------------------------------------------------------------
# 6. Main builder
# -----------------------------------------------------------------------------

build_cvar_object <- function(data, year_col = "year", spec) {
  validation <- run_a2_validations(data = data, year_col = year_col, spec = spec)

  if (!validation$passed) {
    return(list(
      spec_id = spec$spec_id,
      window_id = spec$window_id,
      basis_id = spec$basis_id,
      deterministic_id = spec$deterministic_id,
      p = spec$p,
      q_profile = spec$q_profile,
      m = length(spec$variables),
      T_raw = nrow(data),
      T_eff_common = NA_integer_,
      computed_status = "gate_fail",
      validation = validation,
      message = "A2 validation failed. Specification is not admissible."
    ))
  }

  X_levels <- build_level_matrix(data, spec$variables)
  basis_obj <- build_basis(X_levels, spec$basis_id)
  D_full <- build_deterministics(n = nrow(X_levels), deterministic_id = spec$deterministic_id)

  blocks <- build_var_blocks(X = basis_obj$X_basis, p = spec$p)
  trimmed <- trim_to_common_sample(blocks = blocks, D = D_full, p = spec$p)
  johansen <- compute_johansen_blocks(trimmed)

  list(
    spec_id = spec$spec_id,
    window_id = spec$window_id,
    basis_id = spec$basis_id,
    deterministic_id = spec$deterministic_id,
    p = spec$p,
    q_profile = spec$q_profile,
    m = ncol(X_levels),
    T_raw = nrow(X_levels),
    T_eff_common = trimmed$T_eff_common,
    computed_status = "computed",
    variables = spec$variables,
    variable_roles = spec$variable_roles,
    transformation_map = spec$transformation_map,
    sample_range = c(spec$sample_start, spec$sample_end),
    basis_map = basis_obj$basis_map,
    validation = validation,
    unrestricted_covariance_blocks = johansen[c("S00", "S11", "S01", "S10")],
    reduced_rank_ready = johansen,
    conceptual_admissibility_notes = list(
      rank_interpretation = "confinement_dimension",
      cointegration_interpretation = "long_run_transformation_structure",
      comparability_rule = "common_effective_sample_enforced"
    )
  )
}

# -----------------------------------------------------------------------------
# 7. Minimal pilot specification constructor
# -----------------------------------------------------------------------------

make_minimal_yk_spec <- function(sample_start = 1900, sample_end = 1994, p = 1L,
                                 basis_id = "raw", deterministic_id = "const_restricted") {
  new_cvar_spec(
    spec_id = paste0("minimal_yk_p", p, "_", basis_id, "_", deterministic_id),
    window_id = "full_1900_1994",
    basis_id = basis_id,
    deterministic_id = deterministic_id,
    p = p,
    q_profile = NULL,
    variables = c("y", "k"),
    variable_roles = c("output_real_log", "capital_real_log"),
    transformation_map = list(
      y = list(source = "ln(Y/p)", common_numeraire = TRUE, level = "real_log"),
      k = list(source = "ln(K/p)", common_numeraire = TRUE, level = "real_log")
    ),
    sample_start = sample_start,
    sample_end = sample_end,
    metadata = list(theoretical_relation = "y - theta*k = ln(u)")
  )
}

# -----------------------------------------------------------------------------
# 8. Example execution block (commented)
# -----------------------------------------------------------------------------

# data_in <- readr::read_csv("data/transformed_levels.csv")
# spec <- make_minimal_yk_spec(p = 2, basis_id = "raw", deterministic_id = "const_restricted")
# cvar_obj <- build_cvar_object(data = data_in, year_col = "year", spec = spec)
# str(cvar_obj, max.level = 2)

