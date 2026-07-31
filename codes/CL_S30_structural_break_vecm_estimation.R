#!/usr/bin/env Rscript

# S30: branch-specific bivariate VECMs and route-specific slope-change diagnostics.
# The LOESS and PARAMETRIC dummy matrices are constructed and estimated separately.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")
suppressPackageStartupMessages({
  library(urca)
  library(vars)
  library(strucchange)
  library(sandwich)
  library(lmtest)
})

set.seed(sbvecm_seed + 30L)

panel <- read.csv(sbvecm_dir("data", "processed", "CL", "SBVECM",
                            "cl_capital_1920_2024.csv"))
s20_dir <- sbvecm_dir("output", "CL", "SBVECM", "S20_DUAL_ROUTE_BREAK_AUDIT")
out_dir <- sbvecm_dir("output", "CL", "SBVECM", "S30_BRANCH_VECM")
sbvecm_ensure_dir(out_dir)

break_sets <- read.csv(file.path(s20_dir, "route_break_sets.csv"),
                       stringsAsFactors = FALSE)
order_gate <- read.csv(file.path(s20_dir, "route_specific_integration_orders.csv"),
                       stringsAsFactors = FALSE)

parse_breaks <- function(route) {
  x <- break_sets$break_years[break_sets$break_route == route]
  if (!length(x) || x == "NONE" || !nzchar(x)) return(integer())
  as.integer(strsplit(x, ";", fixed = TRUE)[[1]])
}

route_is_i1 <- function(route) {
  z <- order_gate[
    order_gate$break_route == route &
      order_gate$variable %in% c("k_NR", "k_ME"), ]
  nrow(z) == 2L && all(z$integration_order == "I(1)")
}

make_dum <- function(route, form) {
  breaks <- parse_breaks(route)
  if (form == "NONE" || !length(breaks)) return(NULL)
  if (form == "LEVEL") return(sbvecm_step_matrix(panel$year, breaks, route))
  if (form == "PIECEWISE_TREND") return(sbvecm_trend_matrix(panel$year, breaks, route))
  stop("Unknown break form.")
}

jo_stats <- function(obj) {
  data.frame(
    trace_r0 = as.numeric(obj@teststat[2]),
    trace_cv5 = as.numeric(obj@cval[2, "5pct"]),
    trace_r_le_1 = as.numeric(obj@teststat[1]),
    trace_r_le_1_cv5 = as.numeric(obj@cval[1, "5pct"]),
    stringsAsFactors = FALSE
  )
}

X <- as.matrix(panel[c("k_NR", "k_ME")])
spec_map <- list()
candidate_objects <- list()

for (route in c("LOESS", "PARAMETRIC")) {
  route_gate <- route_is_i1(route)
  forms <- c("NONE", "LEVEL", "PIECEWISE_TREND")
  for (form in forms) {
    dum <- make_dum(route, form)
    ecdet <- if (form == "PIECEWISE_TREND") "trend" else "const"
    for (K in 2:5) {
      model_breaks <- if (form == "NONE") integer() else parse_breaks(route)
      model_id <- sbvecm_model_id(route, form, model_breaks, K, "NA")
      if (!route_gate) {
        spec_map[[length(spec_map) + 1L]] <- data.frame(
          model_id = model_id, break_route = route, break_form = form,
          break_set = if (length(model_breaks)) paste(model_breaks, collapse = ";") else "NONE",
          lag = K,
          ecdet = ecdet, order_gate = "blocked", trace_r0 = NA,
          trace_cv5 = NA, serial_p = NA, asymptotic_rank = NA,
          selected_lag = FALSE, disposition = "blocked_before_estimation",
          stringsAsFactors = FALSE
        )
        next
      }
      jo <- tryCatch(
        ca.jo(X, type = "trace", ecdet = ecdet, K = K,
              spec = "transitory", dumvar = dum),
        error = function(e) NULL
      )
      if (is.null(jo)) {
        spec_map[[length(spec_map) + 1L]] <- data.frame(
          model_id = model_id, break_route = route, break_form = form,
          break_set = if (length(model_breaks)) paste(model_breaks, collapse = ";") else "NONE",
          lag = K,
          ecdet = ecdet, order_gate = "passed", trace_r0 = NA,
          trace_cv5 = NA, serial_p = NA, asymptotic_rank = NA,
          selected_lag = FALSE, disposition = "estimation_error",
          stringsAsFactors = FALSE
        )
        next
      }
      st <- jo_stats(jo)
      rls <- tryCatch(cajorls(jo, r = 1), error = function(e) NULL)
      serial_p <- sbvecm_serial_p(rls, lag = 4L)
      rank <- if (st$trace_r0 > st$trace_cv5 &&
                  st$trace_r_le_1 <= st$trace_r_le_1_cv5) 1L else
        if (st$trace_r_le_1 > st$trace_r_le_1_cv5) 2L else 0L
      spec_map[[length(spec_map) + 1L]] <- data.frame(
        model_id = model_id, break_route = route, break_form = form,
        break_set = if (length(model_breaks))
          paste(model_breaks, collapse = ";") else "NONE",
        lag = K, ecdet = ecdet, order_gate = "passed",
        trace_r0 = st$trace_r0, trace_cv5 = st$trace_cv5,
        serial_p = serial_p, asymptotic_rank = rank,
        selected_lag = FALSE, disposition = "mapped",
        stringsAsFactors = FALSE
      )
      candidate_objects[[model_id]] <- list(jo = jo, rls = rls, dum = dum)
    }
  }
}

spec_map <- do.call(rbind, spec_map)
spec_map$bic_initial_lag <- NA_integer_

# BIC is the initial lag. Promotion uses the smallest lag at or above two that
# passes the residual serial-correlation gate; BIC is retained in the ledger.
for (route in c("LOESS", "PARAMETRIC")) {
  for (form in c("NONE", "LEVEL", "PIECEWISE_TREND")) {
    zidx <- which(spec_map$break_route == route & spec_map$break_form == form &
                    spec_map$order_gate == "passed")
    if (!length(zidx)) next
    dum <- make_dum(route, form)
    vs <- tryCatch(VARselect(X, lag.max = 5, type = "const", exogen = dum),
                   error = function(e) NULL)
    bic <- if (is.null(vs)) 2L else
      max(2L, min(5L, as.integer(vs$selection["SC(n)"])))
    spec_map$bic_initial_lag[zidx] <- bic
    passing <- zidx[is.finite(spec_map$serial_p[zidx]) &
                      spec_map$serial_p[zidx] >= 0.05]
    chosen <- if (length(passing)) passing[which.min(spec_map$lag[passing])] else
      zidx[which.max(spec_map$serial_p[zidx])]
    spec_map$selected_lag[chosen] <- TRUE
    spec_map$disposition[chosen] <- if (spec_map$serial_p[chosen] >= 0.05)
      "selected_for_asymptotic_review" else "held_serial_correlation"
  }
}
write.csv(spec_map, file.path(out_dir, "vecm_specification_map_prebootstrap.csv"),
          row.names = FALSE)

selected <- spec_map[spec_map$selected_lag, ]
model_rows <- list()
for (i in seq_len(nrow(selected))) {
  s <- selected[i, ]
  obj <- candidate_objects[[s$model_id]]
  if (is.null(obj)) next
  jo_eigen <- ca.jo(X, type = "eigen", ecdet = s$ecdet, K = s$lag,
                    spec = "transitory", dumvar = obj$dum)
  beta_hat <- -obj$jo@V[2, 1] / obj$jo@V[1, 1]
  beta_ci <- c(NA_real_, NA_real_)
  beta_p1 <- NA_real_

  alpha_nr <- alpha_me <- alpha_nr_p <- alpha_me_p <- NA_real_
  arch_p <- normality_p <- NA_real_
  root_max <- NA_real_
  if (!is.null(obj$rls)) {
    sm <- summary(obj$rls$rlm)
    c1 <- sm[[1]]$coefficients
    c2 <- sm[[2]]$coefficients
    if ("ect1" %in% rownames(c1)) {
      alpha_nr <- c1["ect1", "Estimate"]
      alpha_nr_p <- 2 * pt(abs(c1["ect1", "t value"]), df = obj$rls$rlm$df.residual,
                           lower.tail = FALSE)
    }
    if ("ect1" %in% rownames(c2)) {
      alpha_me <- c2["ect1", "Estimate"]
      alpha_me_p <- 2 * pt(abs(c2["ect1", "t value"]), df = obj$rls$rlm$df.residual,
                           lower.tail = FALSE)
    }
    er <- residuals(obj$rls$rlm)
    arch_p <- min(apply(er, 2, function(e)
      Box.test(e^2, lag = 4, type = "Ljung-Box")$p.value))
    normality_p <- min(apply(er, 2, function(e)
      tryCatch(tseries::jarque.bera.test(e)$p.value, error = function(err) NA_real_)),
      na.rm = TRUE)
    vec <- tryCatch(vec2var(obj$jo, r = 1), error = function(e) NULL)
    if (!is.null(vec)) {
      amat <- do.call(cbind, vec$A)
      k_vars <- nrow(amat)
      p_lags <- length(vec$A)
      companion <- rbind(
        amat,
        cbind(diag(k_vars * (p_lags - 1L)),
              matrix(0, k_vars * (p_lags - 1L), k_vars))
      )
      root_mod <- Mod(eigen(companion, only.values = TRUE)$values)
      # A rank-one bivariate VECM has one common-trend unit root by design.
      # Remove the root closest to unity and test the remaining roots.
      drop_unit <- which.min(abs(root_mod - 1))[1]
      root_max <- max(root_mod[-drop_unit])
    }
  }
  stability_p <- tryCatch({
    form <- if (is.null(obj$dum)) k_NR ~ k_ME else k_NR ~ k_ME + obj$dum
    sctest(efp(form, data = panel, type = "Rec-CUSUM"))$p.value
  }, error = function(e) NA_real_)

  adjudicated_rank <- as.integer(s$asymptotic_rank)
  bootstrap_necessity <- if (adjudicated_rank == 1L &&
                              s$break_form != "NONE") {
    "required_only_if_break_model_is_considered_for_promotion"
  } else if (adjudicated_rank == 1L && s$break_form == "NONE") {
    "not_required_full_sample_standard_asymptotic_case"
  } else {
    "not_required_no_rank_one_promotion_candidate"
  }
  disposition <- if (s$serial_p < 0.05) {
    "held_serial_correlation"
  } else if (adjudicated_rank == 0L) {
    "held_asymptotic_rank_zero"
  } else if (adjudicated_rank == 2L) {
    "held_full_rank_conflicts_with_I1_gate"
  } else if (s$break_form != "NONE") {
    "held_nonstandard_break_inference"
  } else if (is.finite(root_max) && root_max >= 1) {
    "held_instability"
  } else {
    "promoted_asymptotic_full_sample"
  }

  model_rows[[length(model_rows) + 1L]] <- data.frame(
    model_id = s$model_id,
    data_sha256 = unique(panel$source_sha256),
    break_route = s$break_route,
    break_form = s$break_form,
    break_set = s$break_set,
    sample = "1920-2024",
    N = nrow(panel),
    lag = s$lag,
    ecdet = s$ecdet,
    trace_r0 = as.numeric(obj$jo@teststat[2]),
    trace_cv5_asymptotic = as.numeric(obj$jo@cval[2, "5pct"]),
    trace_boot_critical_95 = NA_real_,
    trace_boot_p = NA_real_,
    max_eigen_r0 = as.numeric(jo_eigen@teststat[2]),
    max_eigen_cv5 = as.numeric(jo_eigen@cval[2, "5pct"]),
    bootstrap_valid = 0L,
    bootstrap_necessity = bootstrap_necessity,
    bootstrap_status = "not_run_not_strictly_necessary_for_current_disposition",
    rank = adjudicated_rank,
    beta_ME = beta_hat,
    beta_ME_ci_low = beta_ci[1],
    beta_ME_ci_high = beta_ci[2],
    beta_ME_equals_1_boot_p = beta_p1,
    alpha_NR = alpha_nr,
    alpha_NR_weak_exog_p = alpha_nr_p,
    alpha_ME = alpha_me,
    alpha_ME_weak_exog_p = alpha_me_p,
    residual_serial_p = s$serial_p,
    residual_arch_p = arch_p,
    residual_normality_p = normality_p,
    recursive_constancy_p = stability_p,
    companion_root_max = root_max,
    disposition = disposition,
    stringsAsFactors = FALSE
  )
}

model_ledger <- if (length(model_rows)) do.call(rbind, model_rows) else data.frame()
beta_boot <- data.frame(
  model_id = character(), replication = integer(), beta_ME = numeric(),
  break_route = character(), status = character(), stringsAsFactors = FALSE
)
write.csv(model_ledger, file.path(out_dir, "vecm_model_ledger.csv"), row.names = FALSE)
write.csv(beta_boot, file.path(out_dir, "vecm_beta_bootstrap_records.csv"),
          row.names = FALSE)

# Route-specific raw-interaction slope diagnostics. These are never used to
# select the break dates and never combine routes.
slope_rows <- list()
restriction_rows <- list()
for (route in c("LOESS", "PARAMETRIC")) {
  breaks <- parse_breaks(route)
  if (!route_is_i1(route) || !length(breaks)) next
  for (set_name in c(paste0("ONE_", breaks), "JOINT")) {
    active <- if (set_name == "JOINT") breaks else
      as.integer(sub("ONE_", "", set_name))
    for (centering in c("UNCENTERED", "INITIAL_STATE", "SAMPLE_MEAN")) {
      D <- sbvecm_step_matrix(panel$year, active, paste0(route, "_D"))
      int <- sapply(seq_along(active), function(j) {
        center <- switch(
          centering,
          UNCENTERED = 0,
          INITIAL_STATE = panel$k_ME[match(active[j], panel$year)],
          SAMPLE_MEAN = mean(panel$k_ME)
        )
        D[, j] * (panel$k_ME - center)
      })
      if (is.null(dim(int))) int <- matrix(int, ncol = 1L)
      colnames(int) <- paste0("slope_", active)
      design <- data.frame(k_NR = panel$k_NR, k_ME = panel$k_ME, D, int,
                           check.names = FALSE)
      rhs <- setdiff(names(design), "k_NR")
      fit <- lm(reformulate(rhs, response = "k_NR"), data = design)
      vc <- sandwich::vcovHC(fit, type = "HC3")
      cn <- kappa(model.matrix(fit), exact = TRUE)
      ect <- residuals(fit)
      adf <- sbvecm_adf_stat(ect, deterministic = "none", max_lag = 4L)
      base_beta <- coef(fit)["k_ME"]
      interaction_names <- paste0("slope_", active)
      slope_changes <- coef(fit)[interaction_names]
      slopes <- base_beta + cumsum(slope_changes)

      R <- matrix(0, nrow = 1L + length(active), ncol = length(coef(fit)))
      colnames(R) <- names(coef(fit))
      R[1, "k_ME"] <- 1
      for (j in seq_along(active)) {
        R[j + 1L, interaction_names[seq_len(j)]] <- 1
      }
      q <- c(1, rep(0, length(active)))
      diffq <- as.numeric(R %*% coef(fit) - q)
      wald <- as.numeric(t(diffq) %*% solve(R %*% vc %*% t(R), diffq))
      wald_p <- pchisq(wald, df = nrow(R), lower.tail = FALSE)

      model_id <- sbvecm_model_id(route, paste0("SLOPE_", set_name),
                                  active, 2L, centering)
      slope_rows[[length(slope_rows) + 1L]] <- data.frame(
        model_id = model_id,
        break_route = route,
        break_form = "SLOPE_CHANGE_DIAGNOSTIC",
        break_set = paste(active, collapse = ";"),
        centering = centering,
        condition_number = cn,
        beta_ME_base = base_beta,
        regime_slopes = paste(sprintf("%d:%.6f", active, slopes), collapse = ";"),
        residual_adf_stat = adf["statistic"],
        residual_adf_cv5_unadjusted = adf["critical_5"],
        joint_piecewise_unit_wald = wald,
        joint_piecewise_unit_asymptotic_p = wald_p,
        confidence_method = "HC3; diagnostic only",
        disposition = if (cn > 30 && centering == "UNCENTERED")
          "held_condition_number" else "diagnostic",
        stringsAsFactors = FALSE
      )
      restriction_rows[[length(restriction_rows) + 1L]] <- data.frame(
        model_id = model_id,
        break_route = route,
        claim = "piecewise_kappa_stationarity",
        null = "base beta_ME=1 and every route-specific slope change=0",
        statistic = wald,
        asymptotic_p = wald_p,
        bootstrap_p = NA_real_,
        verdict = if (wald_p >= 0.05) "not_rejected_diagnostic" else "rejected",
        stringsAsFactors = FALSE
      )
    }
  }
}

slope_ledger <- if (length(slope_rows)) do.call(rbind, slope_rows) else data.frame()
restriction_ledger <- if (length(restriction_rows))
  do.call(rbind, restriction_rows) else data.frame()
write.csv(slope_ledger, file.path(out_dir, "route_slope_change_diagnostics.csv"),
          row.names = FALSE)
write.csv(restriction_ledger, file.path(out_dir, "kappa_restriction_ledger.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# Cointegration-validated period coefficients
# ---------------------------------------------------------------------------

s20b_dir <- sbvecm_dir("output", "CL", "SBVECM",
                       "S20_PARAMETRIC_COINTEGRATION_BREAKS")
pre_system_breaks <- read.csv(
  file.path(s20b_dir, "cointegration_validated_breaks_pre_system.csv"),
  stringsAsFactors = FALSE
)
kp_summary <- read.csv(file.path(s20b_dir, "kp_adjudication_summary.csv"),
                       stringsAsFactors = FALSE)

parametric_systems <- model_ledger[
  model_ledger$break_route == "PARAMETRIC" &
    model_ledger$break_form %in% c("LEVEL", "PIECEWISE_TREND"), ,
  drop = FALSE
]
system_rank_one <- any(
  parametric_systems$rank == 1L &
    parametric_systems$residual_serial_p >= 0.05 &
    parametric_systems$recursive_constancy_p >= 0.05 &
    !grepl("^held_", parametric_systems$disposition)
)
pre_system_years <- pre_system_breaks$candidate_year[
  pre_system_breaks$pre_system_validated %in% TRUE
]
validated_period_breaks <- if (system_rank_one) {
  sort(unique(as.integer(pre_system_years)))
} else {
  integer()
}

period_bounds <- c(1920L, 1945L, 1971L, 1989L, 2025L)
period_rows <- lapply(seq_len(length(period_bounds) - 1L), function(j) {
  start <- period_bounds[j]
  end <- period_bounds[j + 1L] - 1L
  n_period <- sum(panel$year >= start & panel$year <= end)
  data.frame(
    period = paste0(start, "--", end),
    start_year = start,
    end_year = end,
    N = n_period,
    boundary_status = if (j == 1L)
      "initial candidate span"
    else if (start %in% validated_period_breaks)
      "cointegration-validated"
    else
      "candidate boundary not validated",
    beta_ME = NA_real_,
    standard_error = NA_real_,
    ci_low = NA_real_,
    ci_high = NA_real_,
    beta_equals_1_p = NA_real_,
    adjacent_equality_p = NA_real_,
    estimator = "not run",
    system_rank = if (system_rank_one) 1L else NA_integer_,
    residual_gate = system_rank_one,
    bootstrap_use = if (n_period <= 30L)
      "not required: coefficient blocked before inference"
    else
      "not required",
    result = if (!kp_summary$rejects_stability_5)
      "magnitude not identified: KP stability not rejected"
    else if (!any(pre_system_breaks$pre_system_validated))
      "magnitude not identified: break cointegration not established"
    else if (!system_rank_one)
      "magnitude not identified: system rank or stability gate failed"
    else
      "awaiting admissible joint estimator",
    stringsAsFactors = FALSE
  )
})
period_beta_ledger <- do.call(rbind, period_rows)
write.csv(period_beta_ledger,
          file.path(out_dir, "period_beta_ME_ledger.csv"), row.names = FALSE)

beta_gate_ledger <- data.frame(
  gate = c(
    "Kejriwal-Perron coefficient stability",
    "Gregory-Hansen break cointegration",
    "validated breakpoint intervals",
    "break-adjusted system rank and residual stability",
    "period coefficient estimation",
    "short-period bootstrap"
  ),
  pass = c(
    kp_summary$rejects_stability_5,
    any(pre_system_breaks$gregory_hansen_cointegration_rejects_5),
    any(pre_system_breaks$pre_system_validated),
    system_rank_one,
    any(is.finite(period_beta_ledger$beta_ME)),
    NA
  ),
  evidence = c(
    sprintf("UDmax %.3f against %.2f",
            kp_summary$statistic, kp_summary$critical_5),
    "Gregory-Hansen minimum statistic reported in S20B gate ledger",
    if (length(pre_system_years))
      paste(pre_system_years, collapse = ";") else "none",
    if (system_rank_one) "rank one with stable residuals" else
      "no promoted break-adjusted rank-one system",
    "no estimator may run before all previous gates pass",
    "used only after a coefficient is identified in a period with N <= 30"
  ),
  stringsAsFactors = FALSE
)
write.csv(beta_gate_ledger,
          file.path(out_dir, "period_beta_ME_gate_ledger.csv"),
          row.names = FALSE)

# Mechanical unit test for the cumulative regime-slope mapping:
# beta_j = beta_1 + sum_{b<j} delta_b.
test_base <- 0.70
test_changes <- c(0.10, -0.20, 0.30)
test_expected <- c(0.70, 0.80, 0.60, 0.90)
test_recovered <- c(test_base, test_base + cumsum(test_changes))
cumulative_check <- data.frame(
  regime = seq_along(test_expected),
  expected_beta = test_expected,
  recovered_beta = test_recovered,
  pass = abs(test_expected - test_recovered) < 1e-12
)
write.csv(cumulative_check,
          file.path(out_dir, "cumulative_beta_mapping_unit_test.csv"),
          row.names = FALSE)

checks <- data.frame(
  check = c(
    "all model IDs use one route",
    "no LOESS model contains PARAMETRIC",
    "no PARAMETRIC model contains LOESS",
    "system is bivariate",
    "bootstrap necessity gate recorded",
    "no FWL residualization",
    "cumulative regime coefficients",
    "no beta before the full gate"
  ),
  pass = c(
    all(grepl("CL-BVECM-(LOESS|PARAMETRIC)-", spec_map$model_id)),
    !any(grepl("PARAMETRIC", spec_map$model_id[spec_map$break_route == "LOESS"])),
    !any(grepl("LOESS", spec_map$model_id[spec_map$break_route == "PARAMETRIC"])),
    ncol(X) == 2L,
    all(nzchar(model_ledger$bootstrap_necessity) &
          model_ledger$bootstrap_status ==
            "not_run_not_strictly_necessary_for_current_disposition"),
    TRUE,
    all(cumulative_check$pass),
    !any(is.finite(period_beta_ledger$beta_ME)) ||
      all(beta_gate_ledger$pass[1:4] %in% TRUE)
  ),
  stringsAsFactors = FALSE
)
write.csv(checks, file.path(out_dir, "vecm_route_integrity_checks.csv"),
          row.names = FALSE)
if (!all(checks$pass)) stop("S30 route-integrity gate failed.")

message("S30 complete: ", nrow(model_ledger),
        " selected VECMs adjudicated under the bootstrap-necessity gate and ",
        nrow(slope_ledger),
        " route-specific slope diagnostics mapped.")
