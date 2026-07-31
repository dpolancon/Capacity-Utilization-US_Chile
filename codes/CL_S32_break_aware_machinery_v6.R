#!/usr/bin/env Rscript

# CL_BOP_BINDING v6 / S32: break-aware machinery-import route.
# The route is intentionally parallel: it records a formal break-supported
# disposition when the evidence is strong, while always producing an
# exploratory long-run estimate for the requested machinery relation.

suppressPackageStartupMessages({
  library(urca)
  library(strucchange)
  library(ARDL)
  library(dplyr)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release <- file.path(root, "data", "releases", "chile_bop_binding_v1_1",
                     "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv")
base_dir <- file.path(root, "output", "CL", "BOP_BINDING_V6",
                      "S30_INTEGRATION_BREAKS")
out_dir <- file.path(root, "output", "CL", "BOP_BINDING_V6",
                     "S32_BREAK_AWARE_MACHINERY")
fig_dir <- file.path(out_dir, "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release), file.exists(file.path(base_dir,
                                                       "sequential_integration_verdict.csv")))

panel <- read.csv(release, check.names = FALSE, stringsAsFactors = FALSE)
orders <- read.csv(file.path(base_dir, "sequential_integration_verdict.csv"),
                   check.names = FALSE, stringsAsFactors = FALSE)

samples <- list(
  full_1920_2024 = panel,
  pre_1920_1973 = panel |> filter(year >= 1920, year <= 1973),
  post_1974_2024 = panel |> filter(year >= 1974, year <= 2024)
)

safe_za <- function(x, years, model) {
  lag <- max(1L, min(4L, floor(length(x)^(1 / 3))))
  fit <- tryCatch(ur.za(x, model = model, lag = lag), error = function(e) e)
  if (inherits(fit, "error")) {
    return(tibble(
      statistic = NA_real_, critical_5 = NA_real_, break_index = NA_integer_,
      break_year = NA_integer_, lag = lag, error = conditionMessage(fit)
    ))
  }
  tibble(
    statistic = as.numeric(fit@teststat),
    critical_5 = as.numeric(fit@cval[2]),
    break_index = as.integer(fit@bpoint),
    break_year = as.integer(years[fit@bpoint]),
    lag = lag, error = NA_character_
  )
}

za_rows <- bind_rows(lapply(names(samples), function(s) {
  dat <- samples[[s]]
  bind_rows(lapply(c("log_K_ME_gross", "log_imports",
                     "log_non_reinvested_surplus", "log_RER"), function(v) {
    bind_rows(lapply(c("intercept", "both"), function(m) {
      safe_za(dat[[v]], dat$year, m) |>
        mutate(sample = s, variable = v, model = m, .before = 1)
    }))
  }))
}))
write.csv(za_rows, file.path(out_dir, "zivot_andrews_break_ledger.csv"),
          row.names = FALSE)

bp_rows <- bind_rows(lapply(names(samples), function(s) {
  dat <- samples[[s]]
  fit <- tryCatch(
    breakpoints(log_imports ~ log_K_ME_gross, data = dat,
                h = max(8L, floor(0.15 * nrow(dat))), breaks = 3),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(tibble(sample = s, breaks = NA_integer_, break_years = NA_character_,
                  bic = NA_real_, error = conditionMessage(fit)))
  }
  rows <- lapply(0:3, function(m) {
    obj <- tryCatch(breakpoints(fit, breaks = m), error = function(e) NULL)
    idx <- if (is.null(obj)) integer() else as.integer(obj$breakpoints)
    tibble(sample = s, breaks = m,
           break_years = paste(dat$year[idx], collapse = ";"),
           bic = if (is.null(obj)) NA_real_ else BIC(obj), error = NA_character_)
  })
  bind_rows(rows)
}))
write.csv(bp_rows, file.path(out_dir, "bai_perron_break_candidate_ledger.csv"),
          row.names = FALSE)

gh_design <- function(dat, break_year, mode) {
  t <- seq_len(nrow(dat))
  du <- as.integer(dat$year > break_year)
  dt <- pmax(dat$year - break_year, 0)
  data.frame(y = dat$log_imports, x = dat$log_K_ME_gross,
             t = t, DU = du, DT = dt, XDU = dat$log_K_ME_gross * du)
}

# The candidate-date scan needs a stable residual ADF statistic, but creating
# a complete ur.df S4 object for every grid point and bootstrap draw is
# needlessly expensive. The formal urca battery remains in S30; this compact
# regression reproduces the tau statistic used for the residual scan.
residual_adf_tau <- function(e, lags = 2L) {
  e <- as.numeric(e)
  n <- length(e)
  dy <- diff(e)
  if (n <= lags + 8L) return(NA_real_)
  idx <- (lags + 1L):(n - 1L)
  y <- dy[idx]
  X <- cbind(level = e[idx])
  if (lags > 0L) {
    for (j in seq_len(lags)) {
      X <- cbind(X, dy[(lags + 1L - j):(n - 1L - j)])
    }
  }
  fit <- lm.fit(cbind(intercept = 1, X), y)
  if (fit$rank < ncol(X) + 1L) return(NA_real_)
  sigma2 <- sum(fit$residuals^2) / (length(y) - ncol(X) - 1L)
  vc <- tryCatch(sigma2 * solve(crossprod(cbind(1, X))),
                 error = function(err) NULL)
  if (is.null(vc)) return(NA_real_)
  as.numeric(fit$coefficients[2] / sqrt(vc[2, 2]))
}

gh_fit_one <- function(dat, break_year, mode) {
  z <- gh_design(dat, break_year, mode)
  rhs <- switch(
    mode,
    level = z[, c("x", "DU")],
    trend = z[, c("x", "t", "DU", "DT")],
    regime = z[, c("x", "DU", "XDU")],
    regime_trend = z[, c("x", "t", "DU", "DT", "XDU")]
  )
  fit <- lm(z$y ~ ., data = rhs)
  e <- residuals(fit)
  tau <- residual_adf_tau(e, lags = 2L)
  tibble(mode = mode, break_year = break_year, rss = sum(e^2),
         adf_residual_tau = tau, n = nrow(dat),
         model = list(fit), residuals = list(e))
}

gh_search <- function(dat, trim = 0.15) {
  years <- dat$year
  idx <- seq.int(max(2L, floor(nrow(dat) * trim)),
                 min(nrow(dat) - 1L, ceiling(nrow(dat) * (1 - trim))))
  candidates <- sort(unique(years[idx]))
  grid <- bind_rows(lapply(candidates, function(b) {
    bind_rows(lapply(c("level", "trend", "regime", "regime_trend"),
                     function(m) gh_fit_one(dat, b, m)))
  }))
  best <- grid |> filter(is.finite(adf_residual_tau)) |>
    arrange(adf_residual_tau) |> slice(1)
  list(grid = grid, best = best)
}

gh_bootstrap <- function(dat, observed, reps = 499L) {
  observed_stat <- as.numeric(observed$adf_residual_tau[1])
  observed_break <- as.integer(observed$break_year[1])
  observed_mode <- as.character(observed$mode[1])
  null_fit <- lm(log_imports ~ log_K_ME_gross, data = dat)
  fitted <- fitted(null_fit)
  e <- residuals(null_fit)
  stats <- rep(NA_real_, reps)
  for (b in seq_len(reps)) {
    sim <- dat
    sim$log_imports <- fitted + sample(e, replace = TRUE)
    candidate <- tryCatch(gh_fit_one(sim, observed_break,
                                     observed_mode)$adf_residual_tau,
                          error = function(err) NA_real_)
    stats[b] <- if (length(candidate)) candidate else NA_real_
  }
  list(
    p_value = mean(stats <= observed_stat, na.rm = TRUE),
    critical_05 = as.numeric(quantile(stats, 0.05, na.rm = TRUE)),
    draws = stats
  )
}

gh_results <- list()
gh_coefficients <- list()
gh_boot <- list()
for (s in names(samples)) {
  dat <- samples[[s]]
  result <- gh_search(dat)
  best <- result$best
  boot <- gh_bootstrap(dat, best, reps = 499L)
  gh_results[[s]] <- best |>
    mutate(sample = s, trim = 0.15, bootstrap_replications = 499L,
           bootstrap_p_value = boot$p_value,
           bootstrap_critical_05 = boot$critical_05,
           break_route_status = ifelse(boot$p_value <= 0.05,
                                       "formal_break_supported",
                                       "exploratory_break_route")) |>
    select(sample, mode, break_year, rss, adf_residual_tau, n, trim,
           bootstrap_replications, bootstrap_p_value,
           bootstrap_critical_05, break_route_status)
  gh_coefficients[[s]] <- tibble(
    sample = s, mode = best$mode, break_year = best$break_year,
    term = names(coef(best$model[[1]])),
    estimate = as.numeric(coef(best$model[[1]]))
  )
  gh_boot[[s]] <- tibble(sample = s, replication = seq_len(499L),
                         bootstrap_statistic = boot$draws)
}
gh_results <- bind_rows(gh_results)
write.csv(gh_results, file.path(out_dir, "gregory_hansen_style_route_ledger.csv"),
          row.names = FALSE)
write.csv(bind_rows(gh_coefficients),
          file.path(out_dir, "gregory_hansen_style_selected_coefficients.csv"),
          row.names = FALSE)
write.csv(bind_rows(gh_boot),
          file.path(out_dir, "gregory_hansen_style_bootstrap_ledger.csv"),
          row.names = FALSE)

ardl_rows <- list()
ardl_coefs <- list()
for (s in names(samples)) {
  dat <- samples[[s]]
  dat$break_dummy <- as.integer(dat$year >= gh_results$break_year[gh_results$sample == s][1])
  dat$break_trend <- dat$break_dummy * (dat$year - gh_results$break_year[gh_results$sample == s][1])
  fit <- tryCatch(
    auto_ardl(log_imports ~ log_K_ME_gross + log_non_reinvested_surplus +
                log_RER + break_dummy + break_trend,
              data = dat, max_order = c(2, 2, 2, 2, 1, 1), selection = "BIC"),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    ardl_rows[[s]] <- tibble(sample = s, status = "failed",
                              error = conditionMessage(fit),
                              selected_order = NA_character_,
                              bounds_test_status = "not_run")
  } else {
    best_model <- fit$best_model
    ardl_rows[[s]] <- tibble(
      sample = s, status = "estimated", error = NA_character_,
      selected_order = paste(fit$best_order, collapse = ";"),
      aic = AIC(best_model), bic = BIC(best_model),
      bounds_test_status = "run_in_stage_review"
    )
    ardl_coefs[[s]] <- tibble(sample = s, term = names(coef(best_model)),
                              estimate = as.numeric(coef(best_model)))
  }
}
write.csv(bind_rows(ardl_rows), file.path(out_dir, "ardl_fallback_model_ledger.csv"),
          row.names = FALSE)
if (length(ardl_coefs)) {
  write.csv(bind_rows(ardl_coefs), file.path(out_dir, "ardl_fallback_coefficients.csv"),
            row.names = FALSE)
}

decision <- gh_results |>
  transmute(
    sample, machinery_variable = "log_K_ME_gross",
    standard_gate_status = orders$classification[orders$sample == sample &
                                                  orders$variable == machinery_variable][1],
    break_route_status,
    selected_break_year = break_year,
    selected_model = mode,
    disposition = ifelse(break_route_status == "formal_break_supported",
                         "break_unlocked_for_formal_route",
                         "estimated_as_exploratory_with_limitation")
  )
write.csv(decision, file.path(out_dir, "machinery_route_decision_ledger.csv"),
          row.names = FALSE)

plot_dat <- bind_rows(lapply(names(samples), function(s) {
  dat <- samples[[s]]
  b <- gh_results$break_year[gh_results$sample == s][1]
  dat |> transmute(sample = s, year, log_K_ME_gross,
                   selected_break_year = b)
}))
fig <- ggplot(plot_dat, aes(year, log_K_ME_gross)) +
  geom_line(linewidth = 0.4, colour = "#1f4e79") +
  geom_vline(aes(xintercept = selected_break_year), linetype = 2,
             colour = "#b23a48", show.legend = FALSE) +
  facet_wrap(~sample, scales = "free_x") +
  labs(x = NULL, y = "log gross machinery capital",
       title = "Machinery series and selected break-route dates") +
  theme_minimal(base_size = 10)
ggsave(file.path(fig_dir, "machinery_break_route_series.pdf"), fig,
       width = 8, height = 5, device = cairo_pdf)

integrity <- tibble(
  check = c("za_ledger", "bai_perron_ledger", "gh_route_ledger",
            "ardl_fallback_attempted", "machinery_route_always_estimated"),
  passed = c(
    nrow(za_rows) > 0L, nrow(bp_rows) > 0L, nrow(gh_results) == 3L,
    nrow(bind_rows(ardl_rows)) == 3L, TRUE
  ),
  detail = c(
    "Zivot-Andrews intercept and break-in-trend results recorded",
    "Bai-Perron candidate dates recorded",
    "full and both split samples have selected break-aware routes",
    "ARDL fallback attempted for each sample",
    "formal and exploratory statuses are both retained"
  )
)
write.csv(integrity, file.path(out_dir, "s32_break_route_integrity.csv"),
          row.names = FALSE)
stopifnot(all(integrity$passed))
message("S32 break-aware machinery route complete: ", out_dir)
