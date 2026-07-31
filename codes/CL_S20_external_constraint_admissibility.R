#!/usr/bin/env Rscript

# Chile Stage S20 — canonical windowed capital integration, break, and WBOP gate.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(urca)
  library(strucchange)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
s10 <- file.path(root, "data", "processed", "CL", "S10_SOURCE_PANEL")
out <- file.path(root, "output", "CL", "S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY")
processed <- file.path(root, "data", "processed", "CL",
                       "S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
dir.create(processed, recursive = TRUE, showWarnings = FALSE)

annual <- read.csv(file.path(s10, "chile_wbop_capital_annual_1920_2024.csv"),
                   check.names = FALSE) |>
  arrange(year)
stopifnot(nrow(annual) == 105L,
          min(annual$year) == 1920L,
          max(annual$year) == 2024L,
          sum(is.finite(annual$k_me)) == 105L,
          sum(is.finite(annual$k_nr)) == 105L)

windows <- tibble::tribble(
  ~window_id, ~window, ~start_year, ~end_year,
  "FULL", "Full Chile Century", 1920L, 2024L,
  "NITRATE", "Nitrate Crisis and Early State", 1920L, 1938L,
  "ISI", "Classic ISI", 1939L, 1973L,
  "DICTATORSHIP", "Dictatorship Shock", 1974L, 1989L,
  "DEMO_NEOLIBERAL", "Democratic Neoliberal Export Model", 1990L, 2024L
)

stationary_vote <- function(null, reject) {
  ifelse(is.na(reject), NA,
         ifelse(null == "unit root", reject, !reject))
}

test_one <- function(x, test, deterministic, transformation) {
  x <- as.numeric(x[is.finite(x)])
  if (transformation == "first_difference") x <- diff(x)
  if (transformation == "second_difference") x <- diff(x, differences = 2)
  n <- length(x)
  if (n < 11L || sd(x) == 0) {
    return(tibble(n = n, lag = NA_integer_, statistic = NA_real_,
                  critical_5pct = NA_real_, reject_null = NA,
                  null = ifelse(test == "KPSS", "stationarity", "unit root")))
  }
  lag_max <- if (n <= 20) 1L else if (n <= 40) 2L else 4L
  tryCatch({
    if (test == "ADF") {
      type <- ifelse(deterministic == "trend", "trend", "drift")
      z <- ur.df(x, type = type, lags = lag_max, selectlags = "AIC")
      key <- ifelse(type == "trend", "tau3", "tau2")
      tibble(n = n, lag = z@lags, statistic = unname(z@teststat[1, key]),
             critical_5pct = unname(z@cval[key, "5pct"]),
             reject_null = statistic < critical_5pct, null = "unit root")
    } else if (test == "PP") {
      z <- ur.pp(x, type = "Z-tau",
                 model = ifelse(deterministic == "trend", "trend", "constant"),
                 lags = ifelse(n <= 30, "short", "long"))
      tibble(n = n, lag = z@lag, statistic = unname(z@teststat),
             critical_5pct = unname(z@cval[1, "5pct"]),
             reject_null = statistic < critical_5pct, null = "unit root")
    } else if (test == "KPSS") {
      z <- ur.kpss(x, type = ifelse(deterministic == "trend", "tau", "mu"),
                   lags = ifelse(n <= 30, "short", "long"))
      tibble(n = n, lag = z@lag, statistic = unname(z@teststat),
             critical_5pct = unname(z@cval[1, "5pct"]),
             reject_null = statistic > critical_5pct, null = "stationarity")
    } else if (test == "ERS-GLS") {
      z <- ur.ers(x, type = "DF-GLS",
                  model = ifelse(deterministic == "trend", "trend", "constant"),
                  lag.max = lag_max)
      tibble(n = n, lag = z@lag, statistic = unname(z@teststat),
             critical_5pct = unname(z@cval[1, "5pct"]),
             reject_null = statistic < critical_5pct, null = "unit root")
    } else {
      if (n < 20L) stop("ZA omitted below 20 observations")
      z <- ur.za(x, model = ifelse(deterministic == "trend", "both", "intercept"),
                 lag = min(2L, lag_max))
      tibble(n = n, lag = z@lag, statistic = unname(z@teststat),
             critical_5pct = unname(z@cval[2]),
             reject_null = statistic < critical_5pct, null = "unit root")
    }
  }, error = function(e) {
    tibble(n = n, lag = NA_integer_, statistic = NA_real_,
           critical_5pct = NA_real_, reject_null = NA,
           null = ifelse(test == "KPSS", "stationarity", "unit root"))
  })
}

grid <- expand.grid(
  window_id = windows$window_id,
  variable = c("k_me", "k_nr", "kappa"),
  transformation = c("level", "first_difference", "second_difference"),
  test = c("ADF", "PP", "KPSS", "ERS-GLS", "ZA-break"),
  deterministic = c("constant", "trend"),
  stringsAsFactors = FALSE
)

capital_test_ledger <- bind_rows(lapply(seq_len(nrow(grid)), function(i) {
  g <- grid[i, ]
  w <- windows[match(g$window_id, windows$window_id), ]
  x <- annual[[g$variable]][annual$year >= w$start_year &
                              annual$year <= w$end_year]
  ans <- test_one(x, g$test, g$deterministic, g$transformation)
  mutate(ans,
         window_id = g$window_id, window = w$window,
         start_year = w$start_year, end_year = w$end_year,
         variable = g$variable, transformation = g$transformation,
         test = g$test, deterministic = g$deterministic,
         stationary_vote = stationary_vote(null, reject_null),
         .before = 1)
}))

score <- capital_test_ledger |>
  group_by(window_id, window, start_year, end_year, variable, transformation) |>
  summarise(stationary_votes = sum(stationary_vote, na.rm = TRUE),
            valid_tests = sum(!is.na(stationary_vote)),
            stationary_share = stationary_votes / valid_tests,
            .groups = "drop") |>
  pivot_wider(names_from = transformation,
              values_from = c(stationary_votes, valid_tests, stationary_share))

capital_verdicts <- score |>
  mutate(
    integration_order = case_when(
      valid_tests_level >= 6 & stationary_share_level >= 0.60 ~ "I(0)",
      valid_tests_first_difference >= 6 &
        stationary_share_level < 0.60 &
        stationary_share_first_difference >= 0.60 ~ "I(1)",
      valid_tests_second_difference >= 6 &
        stationary_share_first_difference < 0.60 &
        stationary_share_second_difference >= 0.60 ~ "I(2)-risk",
      TRUE ~ "unresolved"
    ),
    gate_status = case_when(
      integration_order == "I(1)" ~ "promoted",
      integration_order == "I(0)" ~ "stationary_short_run",
      integration_order == "I(2)-risk" ~ "blocked_I2",
      TRUE ~ "held"
    ),
    decision_rule = paste(
      "At least six valid tests and 60% stationary support;",
      "I(1) requires nonstationary level and stationary first difference;",
      "I(2)-risk requires nonstationary first and stationary second difference."
    )
  )

# Make each test row self-contained: the test evidence and the window-level
# adjudication travel together in the authoritative integration ledger.
capital_test_ledger <- capital_test_ledger |>
  left_join(
    capital_verdicts |>
      select(window_id, variable, integration_order, gate_status) |>
      rename(window_order_verdict = integration_order,
             window_gate_verdict = gate_status),
    by = c("window_id", "variable")
  )

# Break audit for each capital series and the normalized relation.
break_rows <- list()
for (i in seq_len(nrow(windows))) {
  w <- windows[i, ]
  d <- annual |>
    filter(year >= w$start_year, year <= w$end_year) |>
    select(year, k_me, k_nr, kappa)
  h <- max(4L, floor(0.15 * nrow(d)))
  for (v in c("k_me", "k_nr", "kappa")) {
    bp <- tryCatch(breakpoints(reformulate("year", response = v),
                               data = d, h = h), error = function(e) NULL)
    years <- if (is.null(bp)) integer() else
      d$year[bp$breakpoints[is.finite(bp$breakpoints)]]
    fs <- tryCatch(sctest(Fstats(reformulate("year", response = v), data = d)),
                   error = function(e) NULL)
    cs <- tryCatch(sctest(efp(reformulate("year", response = v),
                              data = d, type = "Rec-CUSUM")),
                   error = function(e) NULL)
    break_rows[[length(break_rows) + 1L]] <- tibble(
      window_id = w$window_id, window = w$window, variable = v,
      n = nrow(d), bai_perron_break_years = paste(years, collapse = ";"),
      supF_statistic = ifelse(is.null(fs), NA, unname(fs$statistic)),
      supF_p_value = ifelse(is.null(fs), NA, fs$p.value),
      cusum_statistic = ifelse(is.null(cs), NA, unname(cs$statistic)),
      cusum_p_value = ifelse(is.null(cs), NA, cs$p.value)
    )
  }
  rel_bp <- tryCatch(breakpoints(k_nr ~ k_me, data = d, h = h),
                     error = function(e) NULL)
  rel_years <- if (is.null(rel_bp)) integer() else
    d$year[rel_bp$breakpoints[is.finite(rel_bp$breakpoints)]]
  rel_fs <- tryCatch(sctest(Fstats(k_nr ~ k_me, data = d)),
                     error = function(e) NULL)
  rel_cs <- tryCatch(sctest(efp(k_nr ~ k_me, data = d, type = "Rec-CUSUM")),
                     error = function(e) NULL)
  break_rows[[length(break_rows) + 1L]] <- tibble(
    window_id = w$window_id, window = w$window,
    variable = "k_nr_on_k_me", n = nrow(d),
    bai_perron_break_years = paste(rel_years, collapse = ";"),
    supF_statistic = ifelse(is.null(rel_fs), NA, unname(rel_fs$statistic)),
    supF_p_value = ifelse(is.null(rel_fs), NA, rel_fs$p.value),
    cusum_statistic = ifelse(is.null(rel_cs), NA, unname(rel_cs$statistic)),
    cusum_p_value = ifelse(is.null(rel_cs), NA, rel_cs$p.value)
  )
}
break_ledger <- bind_rows(break_rows)

# Break-dummy unit-root diagnostics. A single endogenous break is absorbed by
# a step and slope change; the residual receives an ADF test with no additional
# deterministic term. These diagnostics are reported but never override the
# raw battery without institutional concurrence.
break_dummy_rows <- list()
for (i in seq_len(nrow(windows))) {
  w <- windows[i, ]
  d0 <- annual |>
    filter(year >= w$start_year, year <= w$end_year) |>
    select(year, k_me, k_nr, kappa)
  for (v in c("k_me", "k_nr", "kappa")) {
    for (transformation in c("level", "first_difference")) {
      value <- d0[[v]]
      years <- d0$year
      if (transformation == "first_difference") {
        value <- diff(value)
        years <- years[-1]
      }
      dd <- tibble(year = years, value = value) |>
        filter(is.finite(value))
      h <- max(4L, floor(0.20 * nrow(dd)))
      bp1 <- tryCatch(
        breakpoints(value ~ year, data = dd, h = h, breaks = 1),
        error = function(e) NULL
      )
      bidx <- if (is.null(bp1)) NA_integer_ else
        bp1$breakpoints[which(is.finite(bp1$breakpoints))[1]]
      byear <- if (is.finite(bidx)) dd$year[bidx] else NA_integer_
      ans <- tryCatch({
        if (!is.finite(byear)) stop("No break")
        dd <- dd |>
          mutate(step = as.integer(year > byear),
                 slope_shift = pmax(year - byear, 0))
        resid <- residuals(lm(value ~ year + step + slope_shift, data = dd))
        lag_max <- if (length(resid) <= 20) 1L else
          if (length(resid) <= 40) 2L else 4L
        z <- ur.df(resid, type = "none", lags = lag_max, selectlags = "AIC")
        tibble(statistic = unname(z@teststat[1, "tau1"]),
               critical_5pct = unname(z@cval["tau1", "5pct"]),
               reject_unit_root = statistic < critical_5pct,
               lag = z@lags)
      }, error = function(e) {
        tibble(statistic = NA_real_, critical_5pct = NA_real_,
               reject_unit_root = NA, lag = NA_integer_)
      })
      break_dummy_rows[[length(break_dummy_rows) + 1L]] <- mutate(
        ans, window_id = w$window_id, window = w$window,
        variable = v, transformation = transformation,
        break_year = byear, n = nrow(dd), .before = 1
      )
    }
  }
}
break_dummy_ledger <- bind_rows(break_dummy_rows)

window_gate <- capital_verdicts |>
  filter(variable %in% c("k_me", "k_nr")) |>
  select(window_id, window, variable, integration_order, gate_status) |>
  pivot_wider(names_from = variable,
              values_from = c(integration_order, gate_status)) |>
  mutate(
    standard_cointegration_eligible =
      integration_order_k_me == "I(1)" & integration_order_k_nr == "I(1)",
    disposition = ifelse(standard_cointegration_eligible, "eligible",
                         "blocked"),
    reason = ifelse(
      standard_cointegration_eligible,
      "Both component log stocks pass as I(1) in this window",
      paste0("k_me=", integration_order_k_me,
             "; k_nr=", integration_order_k_nr)
    )
  ) |>
  left_join(select(windows, window_id, start_year, end_year), by = "window_id")

# Officially observed WBOP candidates, one at a time.
wbop_candidates <- tibble::tribble(
  ~candidate, ~label, ~intended_role,
  "manufactures_imports_gdp", "Manufactured imports / GDP",
  "Broad import-dependence conditioner; not machinery imports",
  "current_account_gdp", "Current account / GDP",
  "Net external-financing requirement",
  "net_foreign_income_gdp", "Net foreign income / GDP",
  "Foreign-income drainage",
  "gross_foreign_liabilities_gdp", "Gross foreign liabilities / GDP",
  "Short-run foreign-liability exposure"
)

wbop_test_grid <- expand.grid(
  candidate = wbop_candidates$candidate,
  transformation = c("level", "first_difference", "second_difference"),
  test = c("ADF", "PP", "KPSS", "ERS-GLS", "ZA-break"),
  deterministic = c("constant", "trend"),
  stringsAsFactors = FALSE
)
wbop_test_ledger <- bind_rows(lapply(seq_len(nrow(wbop_test_grid)), function(i) {
  g <- wbop_test_grid[i, ]
  ans <- test_one(annual[[g$candidate]], g$test, g$deterministic,
                  g$transformation)
  mutate(ans, candidate = g$candidate, transformation = g$transformation,
         test = g$test, deterministic = g$deterministic,
         stationary_vote = stationary_vote(null, reject_null), .before = 1)
}))
wbop_verdicts <- wbop_test_ledger |>
  group_by(candidate, transformation) |>
  summarise(stationary_votes = sum(stationary_vote, na.rm = TRUE),
            valid_tests = sum(!is.na(stationary_vote)),
            stationary_share = stationary_votes / valid_tests,
            .groups = "drop") |>
  pivot_wider(names_from = transformation,
              values_from = c(stationary_votes, valid_tests, stationary_share)) |>
  mutate(
    integration_order = case_when(
      stationary_share_level >= 0.60 ~ "I(0)",
      stationary_share_level < 0.60 &
        stationary_share_first_difference >= 0.60 ~ "I(1)",
      stationary_share_first_difference < 0.60 &
        stationary_share_second_difference >= 0.60 ~ "I(2)-risk",
      TRUE ~ "unresolved"
    ),
    permitted_role = case_when(
      integration_order == "I(1)" ~ "one_at_a_time_long_run_candidate",
      integration_order == "I(0)" ~ "short_run_exogenous_or_impulse",
      TRUE ~ "held"
    )
  ) |>
  left_join(wbop_candidates, by = "candidate")

# Annual WBOP financing-compression events. GDP and capital outcomes are excluded.
annual_events <- annual |>
  mutate(
    external_financing_proxy_gdp = -current_account_gdp,
    d_external_financing_proxy_gdp =
      external_financing_proxy_gdp - lag(external_financing_proxy_gdp),
    financing_compression_5pp =
      as.integer(d_external_financing_proxy_gdp <= -0.05),
    d_manufactures_imports_gdp =
      manufactures_imports_gdp - lag(manufactures_imports_gdp),
    d_net_foreign_income_gdp =
      net_foreign_income_gdp - lag(net_foreign_income_gdp)
  )
events <- annual_events |>
  filter(financing_compression_5pp == 1) |>
  transmute(
    event_id = row_number(), event_year = year,
    change_external_financing_gdp = d_external_financing_proxy_gdp,
    change_manufactures_imports_gdp = d_manufactures_imports_gdp,
    change_net_foreign_income_gdp = d_net_foreign_income_gdp,
    event_definition =
      "Annual WBOP financing compression of at least five GDP points; not a gross-flow sudden stop"
  )
stopifnot(identical(events$event_year, c(1937L, 1976L, 1999L, 2023L)))

# U.S.-style visual history with Chilean era shading.
era_rects <- windows |>
  filter(window_id != "FULL") |>
  mutate(
    xmin = start_year - 0.5, xmax = end_year + 0.5,
    fill = c("#dadaeb", "#c7e9c0", "#fee391", "#fdd0a2")
  )
capital_long <- annual |>
  select(year, k_me, k_nr) |>
  pivot_longer(-year, names_to = "series", values_to = "value")

smooth_kappa <- loess(kappa ~ year, data = annual, span = 0.30, degree = 2)
annual$kappa_loess <- predict(smooth_kappa, annual$year)
annual$kappa_d2 <- c(NA, diff(annual$kappa_loess, differences = 2), NA)
zc <- annual$year[
  c(FALSE, FALSE,
    sign(annual$kappa_d2[3:nrow(annual)]) !=
      sign(annual$kappa_d2[2:(nrow(annual) - 1)])
  ) & is.finite(annual$kappa_d2)
]
zc <- zc[zc >= 1923 & zc <= 2021]
if (length(zc) > 1) {
  keep <- c(TRUE, diff(zc) >= 5)
  zc <- zc[keep]
}
write.csv(tibble(inflection_year = zc),
          file.path(out, "loess_second_derivative_inflections.csv"),
          row.names = FALSE)

p_levels <- ggplot(capital_long, aes(year, value, colour = series)) +
  geom_line(linewidth = 0.85) +
  geom_vline(xintercept = zc, linetype = 2, colour = "#636363", linewidth = 0.35) +
  scale_colour_manual(values = c(k_me = "#08306b", k_nr = "#cb181d"),
                      labels = c(k_me = "Machinery and equipment",
                                 k_nr = "Nonresidential structures")) +
  labs(x = "Year", y = "Log capital stock", colour = NULL,
       title = "Chile: capital stock components in log levels",
       subtitle = "Dashed lines mark LOESS second-derivative inflections") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "top", panel.grid.minor = element_blank())
ggsave(file.path(out, "fig_cl_capital_levels_loess.png"), p_levels,
       width = 7.4, height = 4.1, dpi = 240)

p_kappa <- ggplot(annual, aes(year, kappa)) +
  geom_rect(data = era_rects,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
            inherit.aes = FALSE, alpha = 0.20) +
  scale_fill_identity() +
  geom_line(colour = "#54278f", linewidth = 0.55) +
  geom_line(aes(y = kappa_loess), colour = "#238b45", linewidth = 1.0) +
  geom_vline(xintercept = zc, linetype = 2, colour = "#cb181d", linewidth = 0.35) +
  labs(x = "Year", y = expression(kappa[t]),
       title = "Chile: capital composition and historical accumulation windows",
       subtitle = expression(kappa[t] == k[t]^ME - k[t]^NR)) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())
ggsave(file.path(out, "fig_cl_kappa_regime_bands.png"), p_kappa,
       width = 7.4, height = 4.25, dpi = 240)

full_break <- break_ledger |>
  filter(window_id == "FULL", variable == "k_nr_on_k_me")
bp_years <- suppressWarnings(as.integer(strsplit(
  full_break$bai_perron_break_years, ";", fixed = TRUE)[[1]]))
bp_years <- bp_years[is.finite(bp_years)]
rel_model <- lm(k_nr ~ k_me, data = annual)
cus <- efp(k_nr ~ k_me, data = annual, type = "Rec-CUSUM")
cus_df <- tibble(index = seq_along(cus$process),
                 year = annual$year[(nrow(annual) - length(cus$process) + 1):nrow(annual)],
                 process = as.numeric(cus$process))
p_break <- ggplot(cus_df, aes(year, process)) +
  geom_hline(yintercept = 0, colour = "grey70") +
  geom_line(colour = "black", linewidth = 0.7) +
  geom_vline(xintercept = bp_years, linetype = 2, colour = "#cb181d") +
  labs(x = "Year", y = "Recursive CUSUM process",
       title = "Chile: capital-composition stability and Bai-Perron dates",
       subtitle = "Red dashed lines are endogenous breaks in k_NR on k_ME") +
  theme_minimal(base_size = 10)
ggsave(file.path(out, "fig_cl_cusum_breaks.png"), p_break,
       width = 7.4, height = 3.8, dpi = 240)

p_wbop <- ggplot(annual_events, aes(year, 100 * d_external_financing_proxy_gdp)) +
  geom_hline(yintercept = -5, colour = "#cb181d", linewidth = 0.55) +
  geom_col(fill = ifelse(annual_events$financing_compression_5pp == 1,
                         "#cb181d", "#6baed6"), width = 0.8) +
  labs(x = "Year", y = "Percentage-point change",
       title = "Chile: annual WBOP external-financing compression",
       subtitle = "Change in -CA/GDP; red bars cross the five-point event rule") +
  theme_minimal(base_size = 10)
ggsave(file.path(out, "fig_cl_wbop_financing_compression.png"), p_wbop,
       width = 7.4, height = 3.7, dpi = 240)

write.csv(capital_test_ledger,
          file.path(out, "capital_window_integration_test_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(capital_verdicts,
          file.path(out, "capital_window_integration_verdicts.csv"),
          row.names = FALSE, na = "")
write.csv(window_gate, file.path(out, "capital_window_model_gate.csv"),
          row.names = FALSE, na = "")
write.csv(break_ledger, file.path(out, "capital_window_break_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(break_dummy_ledger,
          file.path(out, "capital_break_dummy_unit_root_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(wbop_test_ledger, file.path(out, "wbop_integration_test_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(wbop_verdicts, file.path(out, "wbop_candidate_role_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(events, file.path(out, "annual_wbop_financing_compression_events.csv"),
          row.names = FALSE, na = "")
write.csv(annual_events,
          file.path(processed, "chile_annual_capital_wbop_event_panel.csv"),
          row.names = FALSE, na = "")

message("CL S20 complete: windowed I(0)/I(1)/I(2)-risk, break, and WBOP gates written.")
