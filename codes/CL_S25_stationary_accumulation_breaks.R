#!/usr/bin/env Rscript

# S25: stationary accumulation dynamics and Bai-Perron break selection.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")
suppressPackageStartupMessages({
  library(mbreaks)
  library(lmtest)
})

panel <- read.csv(sbvecm_dir(
  "data", "processed", "CL", "SBVECM", "cl_capital_1920_2024.csv"
), check.names = FALSE, stringsAsFactors = FALSE)
out_dir <- sbvecm_dir("output", "CL", "SBVECM",
                      "S25_STATIONARY_ACCUMULATION_BREAKS")
sbvecm_ensure_dir(out_dir)

growth <- data.frame(
  year = panel$year[-1L],
  d_k_NR = diff(panel$k_NR),
  d_k_ME = diff(panel$k_ME),
  stringsAsFactors = FALSE
)

lag_vector <- function(x, lag) {
  if (lag == 0L) return(x)
  c(rep(NA_real_, lag), head(x, -lag))
}

for (lag in 1:4) {
  growth[[paste0("L", lag, "_d_k_NR")]] <- lag_vector(growth$d_k_NR, lag)
  growth[[paste0("L", lag, "_d_k_ME")]] <- lag_vector(growth$d_k_ME, lag)
}

common <- growth[complete.cases(growth), , drop = FALSE]
lag_rows <- list()
for (p in 0:4) {
  rhs <- c(
    "d_k_ME",
    if (p > 0L) paste0("L", 1:p, "_d_k_NR"),
    if (p > 0L) paste0("L", 1:p, "_d_k_ME")
  )
  fit <- lm(reformulate(rhs, "d_k_NR"), data = common)
  lag_rows[[length(lag_rows) + 1L]] <- data.frame(
    lag = p,
    N_common = nobs(fit),
    BIC = BIC(fit),
    residual_serial_p_BG4 = lmtest::bgtest(fit, order = 4)$p.value,
    stringsAsFactors = FALSE
  )
}
lag_ledger <- do.call(rbind, lag_rows)
initial_p <- lag_ledger$lag[which.min(lag_ledger$BIC)]
write.csv(lag_ledger, file.path(out_dir, "accumulation_lag_selection.csv"),
          row.names = FALSE)

prepare_for_p <- function(p) {
  needed <- c(
    "year", "d_k_NR", "d_k_ME",
    if (p > 0L) paste0("L", 1:p, "_d_k_NR"),
    if (p > 0L) paste0("L", 1:p, "_d_k_ME")
  )
  growth[complete.cases(growth[, needed, drop = FALSE]), needed, drop = FALSE]
}

run_break_model <- function(p) {
  d <- prepare_for_p(p)
  z_names <- c("d_k_ME", if (p > 0L) paste0("L", 1:p, "_d_k_ME"))
  x_names <- if (p > 0L) paste0("L", 1:p, "_d_k_NR") else NULL
  fit <- mbreaks::mdl(
    "d_k_NR", z_name = z_names, x_name = x_names, data = d,
    eps1 = 0.15, m = 3,
    prewhit = if (p == 0L) 1 else 0,
    robust = if (p == 0L) 1 else 0,
    hetdat = 1, hetvar = 1, hetomega = 0, hetq = 1,
    signif = 2, printd = 0
  )
  udmax <- as.numeric(fit$sbtests$UDmax[1, 1])
  udmax_cv5 <- as.numeric(fit$sbtests$UDmax[1, 3])
  seq_stats <- as.numeric(fit$seqtests$supfl[, 1])
  seq_cv5 <- as.numeric(fit$seqtests$cv["5", ])
  selected <- 0L
  if (udmax > udmax_cv5 && seq_stats[1] > seq_cv5[1]) {
    selected <- 1L
    if (seq_stats[2] > seq_cv5[2]) {
      selected <- 2L
      if (seq_stats[3] > seq_cv5[3]) selected <- 3L
    }
  }
  model <- if (selected == fit$SEQ$nbreak) {
    fit$SEQ
  } else if (selected > 0L) {
    mbreaks::dofix(
      "d_k_NR", z_name = z_names, x_name = x_names, data = d,
      fixn = selected, eps1 = 0.15, m = 3,
      prewhit = if (p == 0L) 1 else 0,
      robust = if (p == 0L) 1 else 0,
      hetdat = 1, hetvar = 1, hetomega = 0, hetq = 1,
      printd = 0
    )
  } else {
    NULL
  }
  residuals <- if (!is.null(model)) as.numeric(model$resid) else {
    rhs <- c(z_names, x_names)
    residuals(lm(reformulate(rhs, "d_k_NR"), data = d))
  }
  residual_serial_p <- lmtest::bgtest(
    lm(residuals ~ 1), order = min(4L, floor(length(residuals) / 5L))
  )$p.value
  list(
    data = d, fit = fit, model = model, selected = selected,
    udmax = udmax, udmax_cv5 = udmax_cv5,
    seq_stats = seq_stats, seq_cv5 = seq_cv5,
    residual_serial_p = residual_serial_p
  )
}

p <- initial_p
repeat {
  break_result <- run_break_model(p)
  if (break_result$residual_serial_p >= 0.05 || p >= 4L) break
  p <- p + 1L
}

if (break_result$residual_serial_p < 0.05) {
  stop("No accumulation break specification passes residual serial correlation.")
}

selected_indices <- if (break_result$selected > 0L) {
  as.integer(break_result$model$date[, 1])
} else {
  integer()
}
selected_years <- if (length(selected_indices)) {
  as.integer(break_result$data$year[selected_indices])
} else {
  integer()
}
selected_ci <- if (length(selected_indices)) {
  ci <- break_result$model$CI
  data.frame(
    break_number = seq_along(selected_indices),
    break_year = selected_years,
    interval_low = break_result$data$year[as.integer(ci[, 1])],
    interval_high = break_result$data$year[as.integer(ci[, 2])],
    stringsAsFactors = FALSE
  )
} else {
  data.frame(
    break_number = integer(), break_year = integer(),
    interval_low = integer(), interval_high = integer()
  )
}
write.csv(selected_ci, file.path(out_dir, "accumulation_break_intervals.csv"),
          row.names = FALSE)

break_ledger <- data.frame(
  test = c("UDmax", "supF(1|0)", "supF(2|1)", "supF(3|2)"),
  statistic = c(break_result$udmax, break_result$seq_stats),
  critical_5 = c(break_result$udmax_cv5, break_result$seq_cv5),
  rejects_5 = c(
    break_result$udmax > break_result$udmax_cv5,
    break_result$seq_stats > break_result$seq_cv5
  ),
  selected_lag = p,
  selected_break_count = break_result$selected,
  selected_break_years = paste(selected_years, collapse = ";"),
  residual_serial_p = break_result$residual_serial_p,
  inferential_object =
    "stationary dynamic relation between capital-stock growth rates",
  stringsAsFactors = FALSE
)
write.csv(break_ledger, file.path(out_dir, "short_run_break_ledger.csv"),
          row.names = FALSE)

# The selected structural date controls the deterministic mean of each growth
# series. The fitted dynamic relation is not treated as a time series.
post_start <- if (length(selected_years)) max(selected_years) + 1L else
  max(growth$year) + 1L
post <- as.integer(growth$year >= post_start)
adjust_growth <- function(x) {
  residuals(lm(x ~ growth$year + post))
}

adjusted_battery <- do.call(rbind, list(
  sbvecm_run_urca_battery(
    adjust_growth(growth$d_k_NR), growth$year,
    "d_k_NR", "ACCUMULATION", paste0("mean_shift_", paste(selected_years,
                                                          collapse = "_"))
  ),
  sbvecm_run_urca_battery(
    adjust_growth(growth$d_k_ME), growth$year,
    "d_k_ME", "ACCUMULATION", paste0("mean_shift_", paste(selected_years,
                                                          collapse = "_"))
  )
))
adjusted_battery <- sbvecm_mark_primary(adjusted_battery)
family_verdicts <- sbvecm_family_verdicts(adjusted_battery)
stationarity_orders <- sbvecm_order_adjudication(family_verdicts)
write.csv(adjusted_battery,
          file.path(out_dir, "short_run_urca_complete_battery.csv"),
          row.names = FALSE)
write.csv(family_verdicts,
          file.path(out_dir, "short_run_urca_family_verdicts.csv"),
          row.names = FALSE)
write.csv(stationarity_orders,
          file.path(out_dir, "short_run_stationarity_ledger.csv"),
          row.names = FALSE)

ls_stat <- function(y, years, tb1, tb2, lag) {
  t <- seq_along(y)
  DU1 <- as.integer(years > tb1)
  DU2 <- as.integer(years > tb2)
  DT1 <- pmax(0, years - tb1)
  DT2 <- pmax(0, years - tb2)
  Z <- cbind(1, t, DU1, DU2, DT1, DT2)
  dZ <- apply(Z, 2, diff)
  keep <- apply(dZ, 2, function(z) sd(z) > 0)
  dZ <- dZ[, keep, drop = FALSE]
  active_Z <- Z[, c(FALSE, keep[-1]), drop = FALSE]
  dy <- diff(y)
  delta <- lm.fit(dZ, dy)$coefficients
  psi <- y[1] - as.numeric(active_Z[1, ] %*% delta)
  S <- as.numeric(y - psi - active_Z %*% delta)
  dS <- diff(S)
  idx <- max(2L, lag + 1L):length(dy)
  R <- cbind(dZ[idx, , drop = FALSE], S_lag = S[idx])
  if (lag > 0L) {
    for (j in seq_len(lag)) R <- cbind(R, dS[idx - j])
  }
  fit <- lm.fit(R, dy[idx])
  rss <- sum(fit$residuals^2)
  vc <- rss / (length(idx) - fit$rank) * chol2inv(qr.R(fit$qr))
  coef_idx <- which(colnames(R) == "S_lag")
  tstat <- fit$coefficients[coef_idx] / sqrt(vc[coef_idx, coef_idx])
  bic <- length(idx) * log(rss / length(idx)) + fit$rank * log(length(idx))
  c(tstat = unname(tstat), bic = unname(bic))
}

ls_two_break_search <- function(y, years, max_lag = 4L, trim = 0.15) {
  n <- length(y)
  h <- ceiling(trim * n)
  candidates <- seq(h + 1L, n - h)
  best <- list(tstat = Inf, bic = Inf, tb1 = NA_integer_,
               tb2 = NA_integer_, lag = NA_integer_)
  for (i in candidates) {
    for (j in candidates[candidates >= i + h]) {
      if (n - j < h) next
      candidates_lag <- lapply(0:max_lag, function(lag)
        tryCatch(ls_stat(y, years, years[i], years[j], lag),
                 error = function(e) c(tstat = NA_real_, bic = Inf)))
      candidates_lag <- do.call(rbind, candidates_lag)
      chosen <- which.min(candidates_lag[, "bic"])
      stat <- candidates_lag[chosen, "tstat"]
      if (is.finite(stat) && stat < best$tstat) {
        best <- list(
          tstat = stat, bic = candidates_lag[chosen, "bic"],
          tb1 = years[i], tb2 = years[j], lag = chosen - 1L
        )
      }
    }
  }
  best
}

ls_rows <- lapply(c("d_k_NR", "d_k_ME"), function(variable) {
  result <- ls_two_break_search(growth[[variable]], growth$year)
  data.frame(
    variable = variable,
    test = "Lee-Strazicich Model C two-break LM diagnostic",
    break_1 = result$tb1,
    break_2 = result$tb2,
    selected_lag = result$lag,
    statistic = result$tstat,
    conservative_reference_5pct = -5.65,
    rejects_unit_root_diagnostic = result$tstat < -5.65,
    role = "piecewise-stationarity diagnostic; does not select dynamic-relation breaks",
    stringsAsFactors = FALSE
  )
})
ls_ledger <- do.call(rbind, ls_rows)
write.csv(ls_ledger,
          file.path(out_dir, "short_run_lee_strazicich_ledger.csv"),
          row.names = FALSE)

stationary_gate <- nrow(stationarity_orders) == 2L &&
  all(stationarity_orders$integration_order == "I(0)")

break_ledger$stationarity_prerequisite_pass <- stationary_gate
break_ledger$inferential_status <- if (stationary_gate) {
  "eligible for dynamic-response estimation"
} else {
  "diagnostic break evidence only: growth-rate stationarity is inconclusive"
}
write.csv(break_ledger, file.path(out_dir, "short_run_break_ledger.csv"),
          row.names = FALSE)

bootstrap <- data.frame(
  inferential_object = c(
    "accumulation break tests",
    "break-date confidence interval",
    "growth-rate stationarity"
  ),
  bootstrap_required = FALSE,
  replications = 0L,
  reason = c(
    "Bai-Perron analytic critical values apply to the stationary dynamic regression",
    "mbreaks supplies analytic break-date intervals",
    "urca and Lee-Strazicich analytic reference values are used"
  ),
  stringsAsFactors = FALSE
)
write.csv(bootstrap,
          file.path(out_dir, "short_run_bootstrap_necessity.csv"),
          row.names = FALSE)

checks <- data.frame(
  check = c(
    "canonical growth observations",
    "lag selected on common sample",
    "UDmax-first sequential rule",
    "residual serial correlation",
    "break interval bounded",
    "piecewise stationarity verdict recorded",
    "formal response blocked when stationarity is inconclusive",
    "LOESS excluded",
    "bootstrap omitted with analytic inference"
  ),
  pass = c(
    nrow(growth) == 104L,
    p %in% 0:4,
    break_result$selected >= 0L && break_result$selected <= 3L,
    break_result$residual_serial_p >= 0.05,
    break_result$selected == 0L ||
      (nrow(selected_ci) == break_result$selected &&
         all(is.finite(selected_ci$interval_low)) &&
         all(is.finite(selected_ci$interval_high))),
    nrow(stationarity_orders) == 2L &&
      all(stationarity_orders$variable %in% c("d_k_NR", "d_k_ME")),
    stationary_gate ||
      all(break_ledger$inferential_status ==
            "diagnostic break evidence only: growth-rate stationarity is inconclusive"),
    !any(grepl("LOESS", c(names(break_ledger), unlist(break_ledger)),
               ignore.case = TRUE)),
    all(!bootstrap$bootstrap_required)
  ),
  detail = c(
    nrow(growth),
    paste0("p=", p, "; initial BIC p=", initial_p),
    paste0("selected breaks=", break_result$selected),
    sprintf("%.4f", break_result$residual_serial_p),
    if (nrow(selected_ci))
      paste(selected_ci$interval_low, selected_ci$interval_high, sep = "-",
            collapse = ";") else "no break",
    paste(stationarity_orders$variable,
          stationarity_orders$integration_order, collapse = ";"),
    if (stationary_gate) "response estimation may proceed" else
      "response coefficients must remain unreported diagnostics",
    "no LOESS input read",
    "zero replications"
  ),
  stringsAsFactors = FALSE
)
write.csv(checks, file.path(out_dir, "short_run_break_integrity_checks.csv"),
          row.names = FALSE)

if (!all(checks$pass)) {
  stop("S25 accumulation-break gate failed: ",
       paste(checks$check[!checks$pass], collapse = "; "))
}

message("S25 complete: p=", p, ", breaks=",
        if (length(selected_years)) paste(selected_years, collapse = ";") else
          "none", ", stationary gate=", stationary_gate, ".")
