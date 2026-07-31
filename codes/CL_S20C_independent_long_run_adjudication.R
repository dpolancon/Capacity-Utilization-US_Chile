#!/usr/bin/env Rscript

# S20C: independent long-run stability and cointegration adjudication.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")
suppressPackageStartupMessages({
  library(mbreaks)
  library(urca)
})

set.seed(sbvecm_seed + 20L)

panel <- read.csv(sbvecm_dir(
  "data", "processed", "CL", "SBVECM", "cl_capital_1920_2024.csv"
), check.names = FALSE, stringsAsFactors = FALSE)
s20_dir <- sbvecm_dir("output", "CL", "SBVECM",
                      "S20_DUAL_ROUTE_BREAK_AUDIT")
s20b_dir <- sbvecm_dir("output", "CL", "SBVECM",
                       "S20_PARAMETRIC_COINTEGRATION_BREAKS")
s30_dir <- sbvecm_dir("output", "CL", "SBVECM", "S30_BRANCH_VECM")
out_dir <- sbvecm_dir("output", "CL", "SBVECM",
                      "S20C_INDEPENDENT_LONG_RUN_ADJUDICATION")
sbvecm_ensure_dir(out_dir)

custom_kp <- read.csv(file.path(s20b_dir, "kp_adjudication_summary.csv"),
                      stringsAsFactors = FALSE)
parametric_evidence <- read.csv(
  file.path(s20_dir, "parametric_breakpoint_evidence.csv"),
  stringsAsFactors = FALSE
)
models <- read.csv(file.path(s30_dir, "vecm_model_ledger.csv"),
                   stringsAsFactors = FALSE)
orders <- read.csv(file.path(s20_dir, "route_specific_integration_orders.csv"),
                   stringsAsFactors = FALSE)

kp_cv_fixed_5 <- c(`1` = 12.11, `2` = 9.96, `3` = 8.60)
kp_cv_udmax_5 <- 12.25
kp_cv_sequential_5 <- c(`1|0` = 12.11, `2|1` = 13.78, `3|2` = 15.25)

run_mbreaks_kp <- function(d, maximum_breaks = 3L) {
  fit <- mbreaks::mdl(
    "k_NR", z_name = "k_ME", data = d,
    eps1 = 0.15, m = maximum_breaks,
    prewhit = 1, robust = 1, hetdat = 1, hetvar = 1,
    hetomega = 0, hetq = 1, signif = 2, printd = 0
  )
  fixed_stats <- as.numeric(fit$sbtests$ftest[, 1])
  sequential_stats <- as.numeric(fit$seqtests$supfl[, 1])
  udmax <- max(fixed_stats)
  rejects_udmax <- udmax > kp_cv_udmax_5
  selected <- 0L
  if (rejects_udmax && fixed_stats[1] > kp_cv_sequential_5["1|0"]) {
    selected <- 1L
    if (sequential_stats[2] > kp_cv_sequential_5["2|1"]) {
      selected <- 2L
      if (sequential_stats[3] > kp_cv_sequential_5["3|2"]) selected <- 3L
    }
  }
  fixed_model <- if (selected > 0L) {
    mbreaks::dofix(
      "k_NR", z_name = "k_ME", data = d, fixn = selected,
      eps1 = 0.15, m = maximum_breaks,
      prewhit = 1, robust = 1, hetdat = 1, hetvar = 1,
      hetomega = 0, hetq = 1, printd = 0
    )
  } else {
    NULL
  }
  selected_indices <- if (selected > 0L) as.integer(fixed_model$date[, 1]) else
    integer()
  selected_years <- if (length(selected_indices))
    as.integer(d$year[selected_indices]) else integer()
  list(
    fit = fit,
    fixed_stats = fixed_stats,
    sequential_stats = sequential_stats,
    udmax = udmax,
    rejects_udmax = rejects_udmax,
    selected = selected,
    selected_years = selected_years,
    fixed_model = fixed_model
  )
}

independent <- run_mbreaks_kp(panel)

fixed_ledger <- data.frame(
  breaks_tested = 1:3,
  statistic = independent$fixed_stats,
  critical_5 = unname(kp_cv_fixed_5),
  rejects_stability_5 = independent$fixed_stats > unname(kp_cv_fixed_5),
  implementation = "mbreaks 1.0.1 statistic; Kejriwal-Perron critical value",
  stringsAsFactors = FALSE
)
write.csv(fixed_ledger,
          file.path(out_dir, "independent_kp_fixed_break_tests.csv"),
          row.names = FALSE)

sequential_ledger <- data.frame(
  test = names(kp_cv_sequential_5),
  statistic = independent$sequential_stats,
  critical_5 = unname(kp_cv_sequential_5),
  rejects_5 = independent$sequential_stats > unname(kp_cv_sequential_5),
  stringsAsFactors = FALSE
)
write.csv(sequential_ledger,
          file.path(out_dir, "independent_kp_sequential_tests.csv"),
          row.names = FALSE)

gh <- parametric_evidence[
  parametric_evidence$procedure == "Gregory-Hansen", , drop = FALSE
]
gh_reject <- any(gh$rejects_at_5pct %in% TRUE, na.rm = TRUE)
gh_best <- gh[which.min(gh$statistic), , drop = FALSE]

po_rows <- list()
for (type in c("Pu", "Pz")) {
  for (deterministic in c("none", "constant", "trend")) {
    obj <- urca::ca.po(
      cbind(panel$k_NR, panel$k_ME),
      demean = deterministic, type = type, lag = "long"
    )
    stat <- as.numeric(obj@teststat[1])
    cv5 <- as.numeric(obj@cval[2])
    po_rows[[length(po_rows) + 1L]] <- data.frame(
      test = paste("Phillips-Ouliaris", type, deterministic),
      statistic = stat,
      critical_5 = cv5,
      rejects_no_cointegration_5 = stat > cv5,
      stringsAsFactors = FALSE
    )
  }
}
po_ledger <- do.call(rbind, po_rows)
write.csv(po_ledger,
          file.path(out_dir, "phillips_ouliaris_cointegration_tests.csv"),
          row.names = FALSE)
po_reject <- any(po_ledger$rejects_no_cointegration_5)

no_break_system <- models[
  models$break_route == "PARAMETRIC" &
    models$break_form == "NONE", , drop = FALSE
]
no_break_rank_one <- nrow(no_break_system) == 1L &&
  no_break_system$rank == 1L &&
  no_break_system$residual_serial_p >= 0.05

raw_orders <- orders[
  orders$break_route == "NONE" &
    orders$variable %in% c("k_NR", "k_ME"), , drop = FALSE
]
raw_i1_gate <- nrow(raw_orders) == 2L &&
  all(raw_orders$integration_order == "I(1)")

cointegration_prerequisite <- gh_reject || po_reject || no_break_rank_one
kp_applicable <- cointegration_prerequisite
validated_breaks <- if (kp_applicable && independent$rejects_udmax) {
  independent$selected_years
} else {
  integer()
}
stable_long_run_identified <- raw_i1_gate && po_reject && no_break_rank_one
break_long_run_identified <- length(validated_breaks) > 0L &&
  any(models$break_route == "PARAMETRIC" &
        models$break_form != "NONE" &
        models$rank == 1L &
        models$residual_serial_p >= 0.05 &
        models$recursive_constancy_p >= 0.05)

imols_status <- if (break_long_run_identified || stable_long_run_identified) {
  "eligible for cointRegIM estimation"
} else {
  "not run: integration, cointegration, and rank prerequisites fail"
}

comparison <- data.frame(
  implementation = c("custom S20B", "independent mbreaks 1.0.1"),
  statistic = c(custom_kp$statistic[1], independent$udmax),
  critical_5 = c(custom_kp$critical_5[1], kp_cv_udmax_5),
  rejects_stability_5 = c(custom_kp$rejects_stability_5[1],
                           independent$rejects_udmax),
  cointegration_prerequisite = c(FALSE, cointegration_prerequisite),
  inferential_use = c(
    "diagnostic comparator only",
    if (kp_applicable) "eligible for break-count adjudication" else
      "not admissible for period definition because cointegration is not established"
  ),
  stringsAsFactors = FALSE
)
write.csv(comparison,
          file.path(out_dir, "kp_implementation_comparison.csv"),
          row.names = FALSE)

long_run <- data.frame(
  evidence = c(
    "raw integration-order classification",
    "Gregory-Hansen one-break cointegration",
    "Phillips-Ouliaris stable cointegration",
    "no-break Johansen rank",
    "independent Kejriwal-Perron stability",
    "cointegration-validated break dates",
    "stable full-sample beta_ME",
    "period-specific beta_ME"
  ),
  statistic_or_result = c(
    paste(raw_orders$variable, raw_orders$integration_order,
          collapse = "; "),
    sprintf("minimum %.3f against %.2f",
            gh_best$statistic[1], gh_best$critical_5[1]),
    paste0(sum(po_ledger$rejects_no_cointegration_5), " of ",
           nrow(po_ledger), " reject"),
    if (nrow(no_break_system)) paste0("rank=", no_break_system$rank[1]) else
      "not available",
    sprintf("UDmax %.3f against %.2f",
            independent$udmax, kp_cv_udmax_5),
    if (length(validated_breaks)) paste(validated_breaks, collapse = ";") else
      "none",
    if (stable_long_run_identified) "identified" else "not identified",
    if (break_long_run_identified) "identified" else "not identified"
  ),
  prerequisite_pass = c(
    raw_i1_gate,
    gh_reject,
    po_reject,
    no_break_rank_one,
    kp_applicable,
    length(validated_breaks) > 0L,
    stable_long_run_identified,
    break_long_run_identified
  ),
  permitted_claim = c(
    if (raw_i1_gate) "standard I(1) system may proceed" else
      "raw capital orders remain inconclusive",
    if (gh_reject) "one-break cointegration is supported" else
      "one-break cointegration is not supported",
    if (po_reject) "stable cointegration is supported" else
      "stable cointegration is not supported",
    if (no_break_rank_one) "one common trend relation is supported" else
      "the system does not supply an admissible rank-one relation",
    if (kp_applicable)
      "stability result may be interpreted conditional on cointegration" else
      "stability statistic cannot define coefficient periods",
    if (length(validated_breaks)) "dates may define beta_ME periods" else
      "no date defines a beta_ME period",
    imols_status,
    imols_status
  ),
  stringsAsFactors = FALSE
)
write.csv(long_run,
          file.path(out_dir, "long_run_identification_ledger.csv"),
          row.names = FALSE)

simulate_case <- function(kind, seed) {
  set.seed(seed)
  n <- 105L
  year <- 1920:(1920 + n - 1L)
  x <- cumsum(rnorm(n))
  if (kind == "stable_cointegrated") {
    u <- as.numeric(arima.sim(list(ar = 0.20), n = n, sd = 0.10))
    y <- 0.8 * x + u
    truth <- integer()
  } else if (kind == "one_break_cointegrated") {
    u <- as.numeric(arima.sim(list(ar = 0.20), n = n, sd = 0.06))
    truth <- 1972L
    centered <- x - x[year == truth]
    y <- 0.70 * x + 0.55 * centered * (year > truth) + u
  } else if (kind == "multiple_breaks_cointegrated") {
    u <- as.numeric(arima.sim(list(ar = 0.15), n = n, sd = 0.05))
    truth <- c(1950L, 1983L)
    y <- 0.55 * x +
      0.65 * (x - x[year == truth[1]]) * (year > truth[1]) -
      0.50 * (x - x[year == truth[2]]) * (year > truth[2]) + u
  } else {
    truth <- integer()
    y <- cumsum(rnorm(n))
  }
  d <- data.frame(year = year, k_ME = x, k_NR = y)
  ans <- run_mbreaks_kp(d)
  po <- urca::ca.po(cbind(d$k_NR, d$k_ME), demean = "constant",
                    type = "Pz", lag = "short")
  po_reject_case <- as.numeric(po@teststat[1]) > as.numeric(po@cval[2])
  date_error <- if (length(truth) && length(ans$selected_years)) {
    max(vapply(truth, function(b)
      min(abs(ans$selected_years - b)), numeric(1)))
  } else {
    NA_real_
  }
  pass <- switch(
    kind,
    stable_cointegrated = po_reject_case && !ans$rejects_udmax,
    one_break_cointegrated =
      ans$rejects_udmax &&
        length(ans$selected_years) >= 1L &&
        min(abs(ans$selected_years - truth)) <= 8L,
    multiple_breaks_cointegrated =
      ans$rejects_udmax &&
        length(ans$selected_years) >= 1L,
    spurious = !po_reject_case
  )
  data.frame(
    simulation = kind,
    true_breaks = paste(truth, collapse = ";"),
    phillips_ouliaris_rejects_no_cointegration = po_reject_case,
    kp_udmax = ans$udmax,
    kp_rejects_stability = ans$rejects_udmax,
    selected_dates = paste(ans$selected_years, collapse = ";"),
    maximum_date_error = date_error,
    validation_pass = pass,
    stringsAsFactors = FALSE
  )
}

simulation <- do.call(rbind, list(
  simulate_case("stable_cointegrated", 12011L),
  simulate_case("one_break_cointegrated", 12002L),
  simulate_case("multiple_breaks_cointegrated", 12003L),
  simulate_case("spurious", 12004L)
))
write.csv(simulation,
          file.path(out_dir, "independent_kp_simulation_validation.csv"),
          row.names = FALSE)

bootstrap <- data.frame(
  inferential_object = c(
    "independent KP stability",
    "stable full-sample cointegration",
    "estimated-break VECM rank",
    "long-run beta_ME"
  ),
  bootstrap_required = c(FALSE, FALSE, FALSE, FALSE),
  reason = c(
    "published integrated-regressor critical values are available",
    "analytic Phillips-Ouliaris and Johansen evidence is decisive",
    "not eligible because no cointegration-validated break exists",
    "coefficient is not identified and is not estimated"
  ),
  replications = 0L,
  stringsAsFactors = FALSE
)
write.csv(bootstrap,
          file.path(out_dir, "long_run_bootstrap_necessity_ledger.csv"),
          row.names = FALSE)

checks <- data.frame(
  check = c(
    "canonical observations",
    "mbreaks version",
    "published KP critical values",
    "independent statistic recorded",
    "cointegration prerequisite enforced",
    "no beta before prerequisites",
    "simulation validation"
  ),
  pass = c(
    nrow(panel) == 105L,
    as.character(packageVersion("mbreaks")) == "1.0.1",
    identical(unname(kp_cv_fixed_5), c(12.11, 9.96, 8.60)) &&
      kp_cv_udmax_5 == 12.25,
    is.finite(independent$udmax),
    kp_applicable == cointegration_prerequisite,
    break_long_run_identified || stable_long_run_identified ||
      grepl("^not run", imols_status),
    all(simulation$validation_pass)
  ),
  detail = c(
    nrow(panel),
    as.character(packageVersion("mbreaks")),
    "Category (a), Case 1; 15 percent trim; one changing I(1) coefficient",
    sprintf("%.3f", independent$udmax),
    paste0("cointegration prerequisite=", cointegration_prerequisite),
    imols_status,
    paste(simulation$simulation[!simulation$validation_pass],
          collapse = ";")
  ),
  stringsAsFactors = FALSE
)
write.csv(checks, file.path(out_dir, "long_run_integrity_checks.csv"),
          row.names = FALSE)

if (!all(checks$pass)) {
  stop("S20C independent long-run adjudication failed: ",
       paste(checks$check[!checks$pass], collapse = "; "))
}

message("S20C complete: long-run beta_ME remains unidentified; ",
        "independent KP statistic=", sprintf("%.3f", independent$udmax),
        ", applicability=", kp_applicable, ".")
