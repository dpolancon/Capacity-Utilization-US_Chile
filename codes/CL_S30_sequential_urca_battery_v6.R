#!/usr/bin/env Rscript

# CL_BOP_BINDING v6 / S30: sequential integration-order battery.
# This script is deliberately independent of the legacy S30 estimator. It
# consumes only the versioned v1.1 release and records every test attempt.

suppressPackageStartupMessages({
  library(urca)
  library(dplyr)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release <- file.path(
  root, "data", "releases", "chile_bop_binding_v1_1",
  "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv"
)
out_dir <- file.path(root, "output", "CL", "BOP_BINDING_V6",
                     "S30_INTEGRATION_BREAKS")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release))

panel <- read.csv(release, check.names = FALSE, stringsAsFactors = FALSE)
stopifnot(identical(as.integer(panel$year), 1920:2024))

targets <- tibble::tribble(
  ~variable, ~label, ~theoretical_basis, ~log_applied, ~model_role,
  "log_imports", "Log real imports", "import requirement", TRUE, "cointegrating candidate",
  "log_K_ME_gross", "Log gross machinery capital", "machinery accumulation and imported capital requirement", TRUE, "cointegrating candidate",
  "log_non_reinvested_surplus", "Log non-reinvested surplus", "surplus not internally recapitalized", TRUE, "cointegrating candidate",
  "log_RER", "Log real exchange rate", "relative-price and foreign-exchange adjustment", TRUE, "state or stationary control after gate",
  "wage_share", "Wage share", "distributional conditioning", FALSE, "stationary control after gate",
  "log_K_NR_gross", "Log gross non-residential capital", "contextual capital-stock comparison", TRUE, "context only; excluded from final VECM"
)

safe_numeric <- function(x) as.numeric(x[is.finite(x)])

extract_urca <- function(obj, statistic_name = NA_character_) {
  if (is.null(obj)) {
    return(list(statistic = NA_real_, critical_5 = NA_real_, error = "null_object"))
  }
  stat <- tryCatch(as.numeric(obj@teststat[1]), error = function(e) NA_real_)
  cv <- tryCatch(as.numeric(obj@cval[1, "5pct"]), error = function(e) NA_real_)
  list(statistic = stat, critical_5 = cv, error = NA_character_)
}

run_one <- function(z, order, sample_name, variable, years, det) {
  z <- safe_numeric(z)
  if (length(z) < 20L || sd(z) == 0) {
    return(tibble(
      sample = sample_name, variable = variable, difference_order = order,
      deterministic = det, n = length(z),
      adf_statistic = NA_real_, adf_critical_5 = NA_real_,
      pp_statistic = NA_real_, pp_critical_5 = NA_real_,
      kpss_statistic = NA_real_, kpss_critical_5 = NA_real_,
      adf_reject_unit_root = NA, pp_reject_unit_root = NA,
      kpss_reject_stationarity = NA, path_pass = FALSE,
      error = "insufficient_or_constant_series"
    ))
  }
  lag_max <- max(1L, min(8L, floor(length(z)^(1 / 3))))
  adf <- tryCatch(
    ur.df(z, type = det, lags = lag_max, selectlags = "AIC"),
    error = function(e) e
  )
  pp <- tryCatch(
    ur.pp(z, type = "Z-tau", model = ifelse(det == "trend", "trend", "constant"),
          lags = "short"),
    error = function(e) e
  )
  kpss <- tryCatch(
    ur.kpss(z, type = ifelse(det == "trend", "tau", "mu"), lags = "short"),
    error = function(e) e
  )
  adf_v <- if (inherits(adf, "error")) list(statistic = NA_real_, critical_5 = NA_real_,
                                             error = conditionMessage(adf)) else extract_urca(adf)
  pp_v <- if (inherits(pp, "error")) list(statistic = NA_real_, critical_5 = NA_real_,
                                           error = conditionMessage(pp)) else extract_urca(pp)
  kpss_v <- if (inherits(kpss, "error")) list(statistic = NA_real_, critical_5 = NA_real_,
                                               error = conditionMessage(kpss)) else extract_urca(kpss)
  adf_reject <- is.finite(adf_v[["statistic"]]) &&
    adf_v[["statistic"]] < adf_v[["critical_5"]]
  pp_reject <- is.finite(pp_v[["statistic"]]) &&
    pp_v[["statistic"]] < pp_v[["critical_5"]]
  kpss_reject <- is.finite(kpss_v[["statistic"]]) &&
    kpss_v[["statistic"]] > kpss_v[["critical_5"]]
  tibble(
    sample = sample_name, variable = variable, difference_order = order,
    deterministic = det, n = length(z),
    adf_statistic = as.numeric(adf_v[["statistic"]]),
    adf_critical_5 = as.numeric(adf_v[["critical_5"]]),
    pp_statistic = as.numeric(pp_v[["statistic"]]),
    pp_critical_5 = as.numeric(pp_v[["critical_5"]]),
    kpss_statistic = as.numeric(kpss_v[["statistic"]]),
    kpss_critical_5 = as.numeric(kpss_v[["critical_5"]]),
    adf_reject_unit_root = adf_reject,
    pp_reject_unit_root = pp_reject,
    kpss_reject_stationarity = kpss_reject,
    path_pass = adf_reject && pp_reject && !kpss_reject,
    error = paste(na.omit(c(adf_v[["error"]], pp_v[["error"]],
                            kpss_v[["error"]])), collapse = ";")
  )
}

run_variable <- function(dat, sample_name, target) {
  x <- dat[[target$variable]]
  if (!target$log_applied && target$variable == "wage_share") {
    return(bind_rows(
      run_one(x, 0L, sample_name, target$variable, dat$year, "drift"),
      run_one(x, 0L, sample_name, target$variable, dat$year, "trend")
    ))
  }
  rows <- list()
  for (d in 0:3) {
    z <- if (d == 0) x else diff(x, differences = d)
    row_years <- dat$year[seq.int(d + 1L, nrow(dat))]
    rows[[length(rows) + 1L]] <- run_one(
      z, d, sample_name, target$variable, row_years, "drift"
    )
    rows[[length(rows) + 1L]] <- run_one(
      z, d, sample_name, target$variable, row_years, "trend"
    )
    latest <- tail(rows, 2)
    if (any(vapply(latest, function(x) isTRUE(x$path_pass), logical(1)))) break
  }
  bind_rows(rows)
}

samples <- list(
  full_1920_2024 = panel,
  pre_1920_1973 = panel |> filter(year >= 1920, year <= 1973),
  post_1974_2024 = panel |> filter(year >= 1974, year <= 2024)
)

long <- bind_rows(lapply(names(samples), function(s) {
  dat <- samples[[s]]
  bind_rows(lapply(seq_len(nrow(targets)), function(i) {
    target <- targets[i, ]
    if (!target$variable %in% names(dat)) stop("Missing target: ", target$variable)
    run_variable(dat, s, target)
  }))
}))

verdict <- long |>
  group_by(sample, variable) |>
  summarise(
    first_supported_order = if (any(path_pass, na.rm = TRUE))
      min(difference_order[path_pass], na.rm = TRUE) else NA_integer_,
    supporting_paths = paste(unique(deterministic[path_pass]), collapse = ";"),
    max_order_tested = max(difference_order, na.rm = TRUE),
    tests_complete = all(is.na(error) | error == ""),
    .groups = "drop"
  ) |>
  left_join(targets, by = "variable") |>
  mutate(
    classification = case_when(
      variable == "wage_share" & first_supported_order == 0L ~ "I(0)",
      is.na(first_supported_order) ~ "unresolved_by_d3",
      first_supported_order == 0L ~ "I(0)",
      first_supported_order == 1L ~ "I(1)",
      first_supported_order == 2L ~ "I(2)",
      TRUE ~ paste0("I(", first_supported_order, ")")
    ),
    disposition = case_when(
      variable == "log_K_NR_gross" ~ "context_only_excluded_from_final_vecm",
      classification == "I(0)" ~ "stationary_control_candidate",
      classification == "I(1)" ~ "cointegrating_state_candidate",
      TRUE ~ "break_aware_or_exploratory_route_required"
    )
  )

write.csv(long, file.path(out_dir, "sequential_urca_long_ledger.csv"),
          row.names = FALSE)
write.csv(verdict, file.path(out_dir, "sequential_integration_verdict.csv"),
          row.names = FALSE)

integrity <- tibble(
  check = c("full_sample", "pre_sample", "post_sample", "wage_share_not_logged",
            "nonresidential_context_only"),
  passed = c(
    nrow(samples$full_1920_2024) == 105L,
    nrow(samples$pre_1920_1973) == 54L,
    nrow(samples$post_1974_2024) == 51L,
    targets$log_applied[targets$variable == "wage_share"] == FALSE,
    targets$model_role[targets$variable == "log_K_NR_gross"] ==
      "context only; excluded from final VECM"
  ),
  detail = c(
    "1920-2024", "1920-1973", "1974-2024",
    "wage share is tested in original level form",
    "log_K_NR_gross is never promoted into the VECM"
  )
)
write.csv(integrity, file.path(out_dir, "s30_sequential_stage_integrity.csv"),
          row.names = FALSE)
stopifnot(all(integrity$passed))
message("S30 sequential urca battery complete: ", out_dir)
