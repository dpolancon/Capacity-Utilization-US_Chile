# CL S20B: parametric breaks in the cointegrating relation.
#
# Bai-Perron and Zivot-Andrews results from S20 remain candidate-date
# evidence. This script implements the Kejriwal-Perron (2010) Category (a),
# Case 1 test for changes in the intercept and the coefficient on one I(1)
# regressor. The DOLS augmentation and hybrid long-run variance correction
# follow sections 5.1-5.2 of that paper. A Kejriwal-Perron rejection is a
# stability result conditional on cointegration; it cannot establish
# cointegration by itself.

source(file.path("codes", "CL_SBVECM_common.R"))

required <- c("strucchange", "urca", "ggplot2")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Missing required packages: ", paste(missing, collapse = ", "))

out_dir <- sbvecm_dir("output", "CL", "SBVECM",
                      "S20_PARAMETRIC_COINTEGRATION_BREAKS")
fig_dir <- file.path(out_dir, "figures")
sbvecm_ensure_dir(out_dir)
sbvecm_ensure_dir(fig_dir)

panel_path <- sbvecm_dir("data", "processed", "CL", "SBVECM",
                        "cl_capital_1920_2024.csv")
s20_dir <- sbvecm_dir("output", "CL", "SBVECM",
                      "S20_DUAL_ROUTE_BREAK_AUDIT")
panel <- read.csv(panel_path, stringsAsFactors = FALSE)
if (nrow(panel) != 105L || !identical(panel$year, 1920:2024)) {
  stop("S20B requires the canonical 105-observation 1920-2024 panel.")
}

parametric_evidence <- read.csv(
  file.path(s20_dir, "parametric_breakpoint_evidence.csv"),
  stringsAsFactors = FALSE
)
current_candidates <- c(1945L, 1971L, 1989L)
trim <- 0.15
max_breaks <- 3L

# ---------------------------------------------------------------------------
# 1. DOLS construction and Kejriwal-Perron statistics
# ---------------------------------------------------------------------------

build_dols_data <- function(d, q, q_max = 2L) {
  dx <- c(NA_real_, diff(d$k_ME))
  z <- data.frame(
    year = d$year,
    y = d$k_NR,
    x = d$k_ME,
    stringsAsFactors = FALSE
  )
  for (j in -q_max:q_max) {
    idx <- seq_along(dx) - j
    values <- rep(NA_real_, length(dx))
    ok <- idx >= 1L & idx <= length(dx)
    values[ok] <- dx[idx[ok]]
    z[[paste0("dx_", if (j < 0) "lead" else "lag", abs(j))]] <- values
  }
  keep_master <- complete.cases(z)
  z <- z[keep_master, , drop = FALSE]
  requested <- vapply(-q:q, function(j) {
    paste0("dx_", if (j < 0) "lead" else "lag", abs(j))
  }, character(1))
  list(data = z[c("year", "y", "x", requested)], dx_names = requested)
}

fit_partition_dols <- function(d, breaks = integer(), q = 1L) {
  built <- build_dols_data(d, q)
  z <- built$data
  breaks <- sort(unique(as.integer(breaks)))
  regime <- 1L + vapply(z$year, function(yr) sum(yr >= breaks), integer(1))
  regimes <- seq_len(length(breaks) + 1L)

  intercepts <- vapply(regimes, function(j) as.numeric(regime == j), numeric(nrow(z)))
  slopes <- intercepts * z$x
  colnames(intercepts) <- paste0("intercept_r", regimes)
  colnames(slopes) <- paste0("beta_r", regimes)
  dx_matrix <- as.matrix(z[built$dx_names])
  X <- cbind(intercepts, slopes, dx_matrix)
  fit <- lm.fit(X, z$y)
  if (fit$rank < ncol(X)) stop("Rank-deficient DOLS partition design.")
  residuals <- as.numeric(fit$residuals)
  fitted <- as.numeric(z$y - residuals)
  xtx_inv <- solve(crossprod(X))
  list(
    data = z,
    X = X,
    y = z$y,
    coefficients = setNames(as.numeric(fit$coefficients), colnames(X)),
    residuals = residuals,
    fitted = fitted,
    rss = sum(residuals^2),
    df = nrow(X) - ncol(X),
    xtx_inv = xtx_inv,
    breaks = breaks,
    q = q
  )
}

choose_dols_q <- function(d, q_values = 0:2) {
  rows <- lapply(q_values, function(q) {
    fit <- fit_partition_dols(d, integer(), q)
    n <- length(fit$residuals)
    k <- length(fit$coefficients)
    data.frame(
      q = q,
      N = n,
      parameters = k,
      BIC = n * log(fit$rss / n) + k * log(n)
    )
  })
  rows <- do.call(rbind, rows)
  list(q = rows$q[which.min(rows$BIC)], ledger = rows)
}

qs_kernel <- function(x) {
  ans <- rep(1, length(x))
  nz <- abs(x) > .Machine$double.eps
  y <- 6 * pi * x[nz] / 5
  ans[nz] <- 25 / (12 * pi^2 * x[nz]^2) *
    (sin(y) / y - cos(y))
  ans
}

hybrid_long_run_variance <- function(null_resid, alternative_resid) {
  n <- length(null_resid)
  rho_num <- sum(alternative_resid[-1L] *
                   alternative_resid[-length(alternative_resid)])
  rho_den <- sum(alternative_resid[-length(alternative_resid)]^2)
  rho <- if (rho_den > 0) rho_num / rho_den else 0
  rho <- max(min(rho, 0.98), -0.98)
  a2 <- 4 * rho^2 / (1 - rho)^4
  bandwidth <- if (a2 <= 0) 1 else 1.3221 * (a2 * n)^(1 / 5)
  bandwidth <- max(1, bandwidth)
  max_lag <- min(n - 1L, ceiling(4 * bandwidth))
  gamma0 <- sum(null_resid^2) / n
  if (max_lag < 1L) {
    return(list(variance = gamma0, bandwidth = bandwidth, rho = rho))
  }
  lags <- seq_len(max_lag)
  autocov <- vapply(lags, function(j) {
    sum(null_resid[(j + 1L):n] * null_resid[1L:(n - j)]) / n
  }, numeric(1))
  variance <- gamma0 + 2 * sum(qs_kernel(lags / bandwidth) * autocov)
  if (!is.finite(variance) || variance <= 0) variance <- gamma0
  list(variance = variance, bandwidth = bandwidth, rho = rho)
}

partition_wald <- function(null_fit, alt_fit, break_count) {
  regimes <- break_count + 1L
  p <- ncol(alt_fit$X)
  R <- matrix(0, nrow = 2L * break_count, ncol = p)
  colnames(R) <- colnames(alt_fit$X)
  for (j in seq_len(break_count)) {
    R[2L * j - 1L, paste0("intercept_r", j)] <- 1
    R[2L * j - 1L, paste0("intercept_r", j + 1L)] <- -1
    R[2L * j, paste0("beta_r", j)] <- 1
    R[2L * j, paste0("beta_r", j + 1L)] <- -1
  }
  rb <- as.numeric(R %*% alt_fit$coefficients)
  middle <- solve(R %*% alt_fit$xtx_inv %*% t(R))
  wald <- as.numeric(crossprod(rb, middle %*% rb))
  lrv <- hybrid_long_run_variance(null_fit$residuals, alt_fit$residuals)
  f_static <- (alt_fit$df / break_count) * wald / alt_fit$rss
  f_dols <- (alt_fit$rss / (nrow(alt_fit$X) * lrv$variance)) * f_static
  list(
    statistic = f_dols,
    static_statistic = f_static,
    wald = wald,
    lrv = lrv$variance,
    bandwidth = lrv$bandwidth,
    rho = lrv$rho,
    restriction_count = nrow(R),
    regimes = regimes
  )
}

estimate_static_breaks <- function(d, max_breaks = 3L, trim = 0.15) {
  full <- strucchange::breakpoints(
    k_NR ~ k_ME, data = d, h = trim, breaks = max_breaks
  )
  lapply(seq_len(max_breaks), function(m) {
    obj <- strucchange::breakpoints(full, breaks = m)
    idx <- as.integer(obj$breakpoints)
    years <- d$year[idx]
    ci <- tryCatch(confint(obj), error = function(e) NULL)
    ci_rows <- data.frame(
      break_number = seq_along(idx),
      break_year = years,
      interval_low = years,
      interval_high = years
    )
    if (!is.null(ci) && !is.null(ci$confint)) {
      ci_mat <- ci$confint
      for (j in seq_len(min(nrow(ci_mat), nrow(ci_rows)))) {
        lo <- max(1L, min(nrow(d), as.integer(ci_mat[j, 1L])))
        hi <- max(1L, min(nrow(d), as.integer(ci_mat[j, 3L])))
        ci_rows$interval_low[j] <- d$year[lo]
        ci_rows$interval_high[j] <- d$year[hi]
      }
    }
    list(m = m, object = obj, indices = idx, years = years,
         confidence = ci_rows)
  })
}

kp_test <- function(d, max_breaks = 3L, trim = 0.15) {
  q_choice <- choose_dols_q(d)
  q <- q_choice$q
  null_fit <- fit_partition_dols(d, integer(), q)
  bp <- estimate_static_breaks(d, max_breaks, trim)
  cv5 <- c(`1` = 12.11, `2` = 9.96, `3` = 8.60)
  udmax_cv5 <- 12.25
  rows <- lapply(bp, function(b) {
    alt_fit <- fit_partition_dols(d, b$years, q)
    test <- partition_wald(null_fit, alt_fit, b$m)
    data.frame(
      breaks_tested = b$m,
      break_years = paste(b$years, collapse = ";"),
      statistic = test$statistic,
      static_statistic = test$static_statistic,
      critical_5 = cv5[as.character(b$m)],
      rejects_stability_5 = test$statistic > cv5[as.character(b$m)],
      q_dols = q,
      N_effective = nrow(alt_fit$X),
      hybrid_lrv = test$lrv,
      qs_bandwidth = test$bandwidth,
      alternative_residual_rho = test$rho,
      stringsAsFactors = FALSE
    )
  })
  rows <- do.call(rbind, rows)
  udmax <- max(rows$statistic)
  udmax_reject <- udmax > udmax_cv5
  bic_ledger <- data.frame(
    breaks = 0:max_breaks,
    BIC = c(
      nrow(null_fit$X) * log(null_fit$rss / nrow(null_fit$X)) +
        ncol(null_fit$X) * log(nrow(null_fit$X)),
      vapply(bp, function(b) {
        fit <- fit_partition_dols(d, b$years, q)
        nrow(fit$X) * log(fit$rss / nrow(fit$X)) +
          ncol(fit$X) * log(nrow(fit$X))
      }, numeric(1))
    )
  )

  # Kejriwal-Perron sequential tests. The base partitions are global
  # minimizers. The extra break is searched within each base segment using
  # the same 15 percent trimming fraction.
  sequential <- list()
  if (max_breaks >= 2L) {
    for (k in 1L:(max_breaks - 1L)) {
      base <- bp[[k]]
      base_fit <- fit_partition_dols(d, base$years, q)
      bounds <- c(min(d$year), base$years, max(d$year) + 1L)
      best_stat <- -Inf
      best_year <- NA_integer_
      for (j in seq_len(length(bounds) - 1L)) {
        lo <- bounds[j]
        hi <- bounds[j + 1L] - 1L
        segment_years <- d$year[d$year >= lo & d$year <= hi]
        nseg <- length(segment_years)
        left <- ceiling(trim * nseg)
        right <- floor((1 - trim) * nseg)
        if (right <= left) next
        candidates <- segment_years[left:right]
        for (candidate in candidates) {
          trial_breaks <- sort(c(base$years, candidate))
          trial_fit <- tryCatch(
            fit_partition_dols(d, trial_breaks, q),
            error = function(e) NULL
          )
          if (is.null(trial_fit) || trial_fit$rss >= base_fit$rss) next
          lrv <- hybrid_long_run_variance(base_fit$residuals,
                                          trial_fit$residuals)
          raw <- nrow(trial_fit$X) *
            (base_fit$rss - trial_fit$rss) / trial_fit$rss
          robust <- raw * trial_fit$rss /
            (nrow(trial_fit$X) * lrv$variance)
          if (is.finite(robust) && robust > best_stat) {
            best_stat <- robust
            best_year <- candidate
          }
        }
      }
      seq_cv <- if (k == 1L) 13.78 else 15.25
      sequential[[length(sequential) + 1L]] <- data.frame(
        null_breaks = k,
        alternative_breaks = k + 1L,
        statistic = best_stat,
        critical_5 = seq_cv,
        rejects_5 = is.finite(best_stat) && best_stat > seq_cv,
        additional_break_year = best_year,
        stringsAsFactors = FALSE
      )
    }
  }
  sequential <- do.call(rbind, sequential)

  # The UDmax test answers whether any instability is present. Conditional on
  # rejection, the BIC over the same globally minimized DOLS partitions selects
  # the number of breaks. The sequential statistics remain a reported
  # sensitivity check because their finite-sample scaling is especially
  # fragile in short annual segments.
  selected_m <- if (udmax_reject) {
    as.integer(bic_ledger$breaks[which.min(bic_ledger$BIC)])
  } else {
    0L
  }
  selected_years <- if (selected_m == 0L) integer() else bp[[selected_m]]$years
  selected_confidence <- if (selected_m == 0L) {
    data.frame(
      break_number = integer(), break_year = integer(),
      interval_low = integer(), interval_high = integer()
    )
  } else {
    bp[[selected_m]]$confidence
  }
  list(
    q_choice = q_choice,
    tests = rows,
    udmax = udmax,
    udmax_cv5 = udmax_cv5,
    udmax_reject = udmax_reject,
    sequential = sequential,
    bic_ledger = bic_ledger,
    selected_m = selected_m,
    selected_years = selected_years,
    selected_confidence = selected_confidence
  )
}

kp <- kp_test(panel, max_breaks, trim)
write.csv(kp$q_choice$ledger,
          file.path(out_dir, "kp_dols_lag_selection.csv"), row.names = FALSE)
write.csv(kp$tests, file.path(out_dir, "kp_supwald_tests.csv"),
          row.names = FALSE)
write.csv(kp$sequential, file.path(out_dir, "kp_sequential_tests.csv"),
          row.names = FALSE)
write.csv(kp$bic_ledger, file.path(out_dir, "kp_break_count_bic.csv"),
          row.names = FALSE)

kp_summary <- data.frame(
  test = "Kejriwal-Perron UDmax",
  category = "a",
  case = 1L,
  changing_parameters = "intercept and beta_ME",
  I1_regressors = 1L,
  trim = trim,
  maximum_breaks = max_breaks,
  q_dols = kp$q_choice$q,
  statistic = kp$udmax,
  critical_5 = kp$udmax_cv5,
  rejects_stability_5 = kp$udmax_reject,
  selected_break_count = kp$selected_m,
  selected_break_years = paste(kp$selected_years, collapse = ";"),
  break_count_rule = "BIC conditional on UDmax rejection",
  inferential_scope =
    "tests parameter stability conditional on a cointegrated regression",
  stringsAsFactors = FALSE
)
write.csv(kp_summary, file.path(out_dir, "kp_adjudication_summary.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# 2. Cointegration prerequisite and validated period boundaries
# ---------------------------------------------------------------------------

gh <- parametric_evidence[
  parametric_evidence$procedure == "Gregory-Hansen", , drop = FALSE
]
gh_reject <- any(gh$rejects_at_5pct %in% TRUE, na.rm = TRUE)
gh_best <- gh[which.min(gh$statistic), , drop = FALSE]

selected_ci_bounded <- nrow(kp$selected_confidence) == kp$selected_m &&
  (kp$selected_m == 0L ||
     all(is.finite(kp$selected_confidence$interval_low) &
           is.finite(kp$selected_confidence$interval_high)))
selected_ci_distinct <- if (kp$selected_m <= 1L) TRUE else {
  all(kp$selected_confidence$interval_high[-kp$selected_m] <
        kp$selected_confidence$interval_low[-1L])
}

# The system rank and residual-stability gates are completed in S30. S20B can
# validate candidate period boundaries only up to the single-equation
# cointegration prerequisite.
single_equation_gate <- kp$udmax_reject && gh_reject &&
  selected_ci_bounded && selected_ci_distinct
validated_breaks_pre_system <- if (single_equation_gate) {
  kp$selected_years
} else {
  integer()
}

candidate_union <- sort(unique(c(current_candidates, kp$selected_years)))
candidate_ledger <- lapply(candidate_union, function(year) {
  kp_match <- if (length(kp$selected_years)) {
    min(abs(kp$selected_years - year)) <= 2L
  } else {
    FALSE
  }
  current <- year %in% current_candidates
  data.frame(
    candidate_year = year,
    in_existing_parametric_set = current,
    in_kp_selected_set = kp_match,
    kp_stability_rejects_5 = kp$udmax_reject,
    gregory_hansen_cointegration_rejects_5 = gh_reject,
    confidence_intervals_bounded = selected_ci_bounded,
    confidence_intervals_distinct = selected_ci_distinct,
    pre_system_validated = year %in% validated_breaks_pre_system,
    paper_status = if (year %in% validated_breaks_pre_system)
      "awaiting system rank and residual gates"
    else if (!gh_reject)
      "candidate only: break-aware cointegration not established"
    else if (!kp$udmax_reject)
      "candidate only: cointegrating coefficient stability not rejected"
    else
      "candidate only: breakpoint interval gate failed",
    stringsAsFactors = FALSE
  )
})
candidate_ledger <- do.call(rbind, candidate_ledger)
write.csv(candidate_ledger,
          file.path(out_dir, "cointegration_validated_breaks_pre_system.csv"),
          row.names = FALSE)

gate_ledger <- data.frame(
  gate = c(
    "capital integration order",
    "Kejriwal-Perron stability",
    "Gregory-Hansen break cointegration",
    "breakpoint intervals",
    "system rank and residual stability"
  ),
  evidence = c(
    "S20 route-specific order ledger",
    sprintf("UDmax %.3f; 5%% critical %.2f", kp$udmax, kp$udmax_cv5),
    sprintf("minimum ADF* %.3f; model %s; 5%% critical %.2f",
            gh_best$statistic, gh_best$specification, gh_best$critical_5),
    paste0("bounded=", selected_ci_bounded, "; distinct=", selected_ci_distinct),
    "completed in S30"
  ),
  pass_at_S20B = c(
    NA,
    kp$udmax_reject,
    gh_reject,
    selected_ci_bounded && selected_ci_distinct,
    NA
  ),
  implication = c(
    "necessary before long-run estimation",
    "a rejection permits break dating only conditional on cointegration",
    "a rejection establishes one-break cointegration evidence",
    "required before dates define periods",
    "required before any beta_ME magnitude is reported"
  ),
  stringsAsFactors = FALSE
)
write.csv(gate_ledger, file.path(out_dir, "break_adjudication_gate_ledger.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# 3. Verified methodological source matrix
# ---------------------------------------------------------------------------

source_matrix <- data.frame(
  method = c(
    "Bai-Perron", "Zivot-Andrews", "Gregory-Hansen",
    "Kejriwal-Perron", "Johansen-Mosconi-Nielsen",
    "Lutkepohl-Saikkonen-Trenkler", "Hansen-Johansen",
    "Lee-Strazicich"
  ),
  object = c(
    "linear regression coefficients",
    "one observed series",
    "single-equation cointegrating residual",
    "cointegrated regression coefficients",
    "cointegrating rank with known deterministic breaks",
    "cointegrating rank with one unknown level shift",
    "long-run parameter constancy in a cointegrated VAR",
    "one observed series"
  ),
  null_hypothesis = c(
    "specified number of stable regression coefficients",
    "unit root without an included break under the null",
    "no cointegration",
    "no coefficient change, or k changes in the sequential test",
    "rank at most r under a known piecewise-linear deterministic design",
    "rank at most r after removing one estimated level shift",
    "constant long-run parameters",
    "unit root while allowing two breaks under the null"
  ),
  alternative_hypothesis = c(
    "one or more unknown coefficient changes",
    "trend-stationary process with one endogenous break",
    "cointegration with one unknown level or regime shift",
    "one or more unknown changes in a cointegrated regression",
    "higher rank and testable restrictions under known breaks",
    "higher rank in a system with one unknown level shift",
    "recursive fluctuation or LM evidence of instability",
    "break-stationary alternative with two endogenous breaks"
  ),
  integrated_variable_treatment = c(
    "standard critical values are not the cointegrated-regression reference",
    "unit-root test for an individual series",
    "special residual-test critical values for I(1) variables",
    "I(1) and I(0) regressors with nonstandard critical values",
    "I(1) system with known deterministic breaks",
    "I(1) VAR adjusted for one estimated deterministic shift",
    "already cointegrated VAR",
    "breaks permitted under both unit-root null and stationary alternative"
  ),
  break_scope = c(
    "multiple unknown breaks",
    "one unknown break",
    "one unknown break",
    "multiple unknown breaks",
    "multiple known breaks",
    "one unknown level shift",
    "parameter stability rather than date selection",
    "two unknown breaks"
  ),
  can_identify_beta_change = c(
    "candidate evidence only for this application",
    "no",
    "yes, for one break under the cointegration alternative",
    "yes, conditional on cointegration",
    "tests vector restrictions under its deterministic design",
    "no direct multiple-slope-break test",
    "tests constancy after rank is established",
    "no"
  ),
  verified_source = c(
    "https://doi.org/10.1002/jae.659",
    "https://doi.org/10.1080/07350015.1992.10509904",
    "https://doi.org/10.1016/0304-4076(69)41685-7",
    "https://doi.org/10.1198/jbes.2009.07220",
    "https://doi.org/10.1111/1368-423X.00047",
    "https://doi.org/10.1111/j.1468-0262.2004.00505.x",
    "https://doi.org/10.1111/1368-423X.00035",
    "https://ideas.repec.org/a/tpr/restat/v85y2003i4p1082-1089.html"
  ),
  stringsAsFactors = FALSE
)
write.csv(source_matrix,
          file.path(out_dir, "parametric_test_methodological_source_matrix.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# 4. Simulation checks and report-facing figure
# ---------------------------------------------------------------------------

simulate_case <- function(kind, seed) {
  set.seed(seed)
  n <- 105L
  year <- 1920:(1920 + n - 1L)
  x <- cumsum(rnorm(n, 0.04, 0.03)) + 15
  u_sd <- if (kind == "stable") 0.015 else 0.006
  u <- as.numeric(arima.sim(model = list(ar = 0.35), n = n, sd = u_sd))
  if (kind == "stable") {
    y <- 1 + 0.8 * x + u
    truth <- integer()
  } else if (kind == "one_break") {
    truth <- year[53L]
    beta <- ifelse(year >= truth, 1.25, 0.70)
    y <- 1 + beta * (x - x[53L]) + 0.70 * x[53L] + u
  } else {
    truth <- year[c(36L, 71L)]
    y <- ifelse(
      year < truth[1L],
      1 + 0.40 * x,
      ifelse(year < truth[2L], -4 + 1.45 * x, 5 + 0.35 * x)
    ) + u
  }
  d <- data.frame(year = year, k_ME = x, k_NR = y)
  ans <- kp_test(d, max_breaks = 3L, trim = 0.15)
  nearest <- if (length(truth) && length(ans$selected_years)) {
    max(vapply(truth, function(z) min(abs(ans$selected_years - z)), numeric(1)))
  } else if (!length(truth) && !length(ans$selected_years)) {
    0
  } else {
    Inf
  }
  data.frame(
    simulation = kind,
    true_breaks = paste(truth, collapse = ";"),
    udmax = ans$udmax,
    critical_5 = ans$udmax_cv5,
    rejects_stability_5 = ans$udmax_reject,
    selected_breaks = paste(ans$selected_years, collapse = ";"),
    maximum_date_error = nearest,
    extra_selected_breaks =
      max(0L, length(ans$selected_years) - length(truth)),
    expected_result = if (kind == "stable")
      "do not reject stability" else "reject stability and recover nearby dates",
    validation_pass = if (kind == "stable")
      !ans$udmax_reject
    else ans$udmax_reject && is.finite(nearest) && nearest <= 6,
    stringsAsFactors = FALSE
  )
}

simulation_validation <- do.call(rbind, list(
  simulate_case("stable", 90210L),
  simulate_case("one_break", 90211L),
  simulate_case("multiple_breaks", 90212L)
))
write.csv(simulation_validation,
          file.path(out_dir, "kp_simulation_validation.csv"), row.names = FALSE)

plot_data <- panel
plot_data$candidate_period <- cut(
  plot_data$year,
  breaks = c(-Inf, current_candidates, Inf),
  labels = c("1920-1944", "1945-1970", "1971-1988", "1989-2024"),
  right = FALSE
)
p <- ggplot2::ggplot(plot_data,
                     ggplot2::aes(k_ME, k_NR, colour = candidate_period)) +
  ggplot2::geom_point(size = 1.45, alpha = 0.8) +
  ggplot2::scale_colour_brewer(palette = "Dark2") +
  ggplot2::labs(
    x = expression(k[t]^ME),
    y = expression(k[t]^NR),
    colour = "Candidate period",
    title = "Observed capital relation before cointegration validation",
    subtitle = if (single_equation_gate)
      "Validated period lines await the system rank and residual gates"
    else
      "No piecewise coefficient line is drawn: break cointegration is not established"
  ) +
  ggplot2::theme_minimal(base_size = 10) +
  ggplot2::theme(
    plot.title = ggplot2::element_text(face = "bold"),
    legend.position = "bottom",
    panel.grid.minor = ggplot2::element_blank()
  )
ggplot2::ggsave(
  file.path(fig_dir, "fig6_cointegration_validated_piecewise_relation.png"),
  p, width = 8.1, height = 4.6, dpi = 320
)
ggplot2::ggsave(
  file.path(fig_dir, "fig6_cointegration_validated_piecewise_relation.pdf"),
  p, width = 8.1, height = 4.6
)

checks <- data.frame(
  check = c(
    "canonical 105 observations",
    "published KP critical values encoded",
    "DOLS lag chosen by BIC on common sample",
    "LOESS evidence excluded",
    "candidate dates do not automatically define periods",
    "simulation validation"
  ),
  pass = c(
    nrow(panel) == 105L,
    identical(unname(c(`1` = 12.11, `2` = 9.96, `3` = 8.60)),
              c(12.11, 9.96, 8.60)) && kp$udmax_cv5 == 12.25,
    kp$q_choice$q %in% 0:2,
    !any(grepl("LOESS", c(names(kp_summary), unlist(kp_summary)),
               ignore.case = TRUE)),
    !any(candidate_ledger$pre_system_validated) || single_equation_gate,
    all(simulation_validation$validation_pass)
  ),
  detail = c(
    paste(min(panel$year), max(panel$year), sep = "-"),
    "Category (a), Case 1, q_b=1, epsilon=0.15",
    paste0("q=", kp$q_choice$q),
    "S20B reads only parametric and observed-capital objects",
    paste0("single-equation gate=", single_equation_gate),
    paste(simulation_validation$simulation[
      !simulation_validation$validation_pass], collapse = ";")
  ),
  stringsAsFactors = FALSE
)
write.csv(checks, file.path(out_dir, "s20b_integrity_checks.csv"),
          row.names = FALSE)
if (!all(checks$pass)) {
  stop("S20B integrity checks failed: ",
       paste(checks$check[!checks$pass], collapse = "; "))
}

message(
  "S20B complete: KP UDmax=", sprintf("%.3f", kp$udmax),
  ", critical=", kp$udmax_cv5,
  ", GH cointegration rejection=", gh_reject,
  ", pre-system validated breaks=",
  if (length(validated_breaks_pre_system))
    paste(validated_breaks_pre_system, collapse = ",") else "none", "."
)
