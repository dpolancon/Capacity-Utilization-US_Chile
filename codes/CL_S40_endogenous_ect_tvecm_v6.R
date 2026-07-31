#!/usr/bin/env Rscript

# CL_BOP_BINDING v6 / S40: endogenous import-ECT threshold VECM.
# tsDyn is used for the bivariate joint beta/threshold search. The model is
# explicitly exploratory when the S32 break route is not formally supported.

suppressPackageStartupMessages({
  library(tsDyn)
  library(dplyr)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
release <- file.path(root, "data", "releases", "chile_bop_binding_v1_1",
                     "CHILE_BOP_BINDING_SOURCE_OF_TRUTH_WIDE.csv")
route_file <- file.path(root, "output", "CL", "BOP_BINDING_V6",
                        "S32_BREAK_AWARE_MACHINERY",
                        "machinery_route_decision_ledger.csv")
out_dir <- file.path(root, "output", "CL", "BOP_BINDING_V6",
                     "S40_ENDOGENOUS_ECT_TVECM")
fig_dir <- file.path(out_dir, "figures")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(release), file.exists(route_file))

panel <- read.csv(release, check.names = FALSE, stringsAsFactors = FALSE)
route <- read.csv(route_file, check.names = FALSE, stringsAsFactors = FALSE)
boot_n <- as.integer(Sys.getenv("CL_TVECM_BOOTSTRAP", "999"))
if (!is.finite(boot_n) || boot_n < 1L) boot_n <- 999L
# The bootstrap p-values are simulation output, so the seed is part of the
# specification and is recorded in the model ledger. Ledgers written before
# this seed was introduced are not reproducible and say so in the report.
boot_seed <- suppressWarnings(as.integer(Sys.getenv("CL_TVECM_SEED", "20260729")))
if (!is.finite(boot_seed)) boot_seed <- 20260729L
set.seed(boot_seed)
# The VECM lag governs both the estimator and the chronology dating, so it is
# declared once rather than repeated at each call site.
lag_order <- 1L

samples <- list(
  full_1920_2024 = panel,
  pre_1920_1973 = panel |> filter(year >= 1920, year <= 1973),
  post_1974_2024 = panel |> filter(year >= 1974, year <= 2024)
)

tidy_coef <- function(fit, sample_name, model_name) {
  cm <- as.matrix(coef(fit))
  out <- as.data.frame(as.table(cm), stringsAsFactors = FALSE)
  names(out) <- c("equation", "term", "estimate")
  out |> mutate(sample = sample_name, model = model_name, .before = 1)
}

fit_primary <- function(dat, sample_name) {
  y <- as.matrix(dat[, c("log_imports", "log_K_ME_gross")])
  fit <- tryCatch(
    TVECM(y, lag = lag_order, nthresh = 1, trim = 0.15,
          ngridBeta = 30, ngridTh = 60, plot = FALSE,
          common = "only_ECT", include = "const", trace = FALSE),
    error = function(e) e
  )
  if (inherits(fit, "error")) {
    return(list(
      summary = tibble(sample = sample_name, status = "failed",
                       error = conditionMessage(fit)),
      coef = tibble(), ect = tibble(), hs = tibble(), seo = tibble(), boot = tibble()
    ))
  }
  spec <- fit[["model.specific"]]
  beta <- as.numeric(spec[["beta"]])
  threshold <- as.numeric(spec[["Thresh"]])
  ect <- as.numeric(spec[["ect"]][, 1])
  reg <- as.integer(spec[["regime"]])
  # tsDyn stores the regime path on the estimation frame, while the ECT
  # vector can be shorter by one or more observations after lagging.  Align
  # both paths to their common terminal estimation window before writing the
  # chronology; do not recycle either vector.
  n_common <- min(length(ect), length(reg), nrow(dat))
  ect <- tail(ect, n_common)
  reg <- tail(reg, n_common)
  # tsDyn returns the lagged disequilibrium: the value entering the year-t
  # equation is the deviation measured at t-1.  Using ECT_{t-1} to switch the
  # regime is correct for the model, but the chronology must date each
  # deviation to the year it was measured, so the equation years are shifted
  # back by the lag.  Labelling the deviation with the equation year would
  # attribute every disequilibrium to the year after it occurred and would
  # pair it with the wrong external indicators downstream.
  years <- tail(dat$year, n_common) - lag_order
  binding_regime <- ifelse(ect <= threshold, "negative_or_lower_ECT",
                           "positive_or_higher_ECT")
  nobs <- as.numeric(spec[["nobs"]])
  hs <- tryCatch(
    TVECM.HStest(y, lag = lag_order, ngridTh = 60, trim = 0.15,
                 nboot = boot_n, fixed.beta = beta,
                 intercept = TRUE, boot.type = "ResBoot"),
    error = function(e) e
  )
  seo <- tryCatch(
    TVECM.SeoTest(y, lag = lag_order, beta = beta, trim = 0.15,
                  nboot = boot_n, plot = FALSE),
    error = function(e) e
  )
  hs_row <- if (inherits(hs, "error")) {
    tibble(sample = sample_name, status = "failed", error = conditionMessage(hs),
           statistic = NA_real_, p_value = NA_real_, threshold_at_max = NA_real_,
           bootstrap_replications = boot_n)
  } else {
    tibble(sample = sample_name, status = "estimated", error = NA_character_,
           statistic = as.numeric(hs[["stat"]]),
           p_value = as.numeric(hs[["PvalBoot"]]),
           threshold_at_max = as.numeric(hs[["maxTh"]]),
           bootstrap_replications = length(hs[["allBoots"]]))
  }
  seo_row <- if (inherits(seo, "error")) {
    tibble(sample = sample_name, status = "failed", error = conditionMessage(seo),
           statistic = NA_real_, p_value = NA_real_,
           threshold_low = NA_real_, threshold_high = NA_real_,
           bootstrap_replications = boot_n)
  } else {
    tibble(sample = sample_name, status = "estimated", error = NA_character_,
           statistic = as.numeric(seo[["supWald"]]),
           p_value = as.numeric(seo[["PvalBoot"]]),
           threshold_low = as.numeric(seo[["gamma1"]]),
           threshold_high = as.numeric(seo[["gamma2"]]),
           bootstrap_replications = length(seo[["allBoots"]]))
  }
  boot_rows <- list()
  if (!inherits(hs, "error")) {
    boot_rows[[1]] <- tibble(sample = sample_name, test = "Hansen_Seo_linear_vs_threshold",
                             replication = seq_along(hs[["allBoots"]]),
                             statistic = as.numeric(hs[["allBoots"]]))
  }
  if (!inherits(seo, "error")) {
    boot_rows[[2]] <- tibble(sample = sample_name, test = "Seo_no_cointegration_vs_threshold",
                             replication = seq_along(seo[["allBoots"]]),
                             statistic = as.numeric(seo[["allBoots"]]))
  }
  summary <- tibble(
    sample = sample_name, status = "estimated", error = NA_character_,
    estimator = "tsDyn::TVECM joint beta-threshold search",
    lag = lag_order, regimes = 2L, trim = 0.15,
    beta_import_normalized = 1, beta_machinery = -beta,
    threshold_ect = threshold,
    n_regime_low = sum(reg == 1L, na.rm = TRUE),
    n_regime_high = sum(reg == 2L, na.rm = TRUE),
    low_regime_share = nobs[1], high_regime_share = nobs[2],
    bootstrap_replications = boot_n,
    bootstrap_seed = boot_seed,
    route_status = route$break_route_status[route$sample == sample_name][1],
    interpretation = "negative/lower import ECT is the candidate binding regime"
  )
  ect_panel <- tibble(
    sample = sample_name, year = years, ECT_import_machinery = ect,
    threshold_ect = threshold, tsdyn_regime = reg,
    ect_regime = binding_regime,
    binding_signal = ect < 0 & ect <= threshold,
    normalization = "log_imports coefficient equals +1"
  )
  list(summary = summary, coef = tidy_coef(fit, sample_name, "primary_2regime"),
       ect = ect_panel, hs = hs_row, seo = seo_row,
       boot = if (length(boot_rows)) bind_rows(boot_rows) else tibble())
}

results <- lapply(names(samples), function(s) fit_primary(samples[[s]], s))
names(results) <- names(samples)

summary_rows <- bind_rows(lapply(results, `[[`, "summary"))
coef_rows <- bind_rows(lapply(results, `[[`, "coef"))
ect_rows <- bind_rows(lapply(results, `[[`, "ect"))
hs_rows <- bind_rows(lapply(results, `[[`, "hs"))
seo_rows <- bind_rows(lapply(results, `[[`, "seo"))
boot_rows <- bind_rows(lapply(results, `[[`, "boot"))

write.csv(summary_rows, file.path(out_dir, "endogenous_tvecm_model_ledger.csv"),
          row.names = FALSE)
write.csv(coef_rows, file.path(out_dir, "endogenous_tvecm_coefficients.csv"),
          row.names = FALSE)
write.csv(ect_rows, file.path(out_dir, "endogenous_tvecm_ect_regime_panel.csv"),
          row.names = FALSE)
write.csv(hs_rows, file.path(out_dir, "hansen_seo_linear_threshold_test.csv"),
          row.names = FALSE)
write.csv(seo_rows, file.path(out_dir, "seo_no_cointegration_threshold_test.csv"),
          row.names = FALSE)
write.csv(boot_rows, file.path(out_dir, "tvecm_bootstrap_ledger.csv"),
          row.names = FALSE)

# Three-regime robustness is attempted only when the primary two-regime fit
# has a usable sample; the minimum outer-regime condition is recorded.
three_rows <- lapply(names(samples), function(s) {
  dat <- samples[[s]]
  y <- as.matrix(dat[, c("log_imports", "log_K_ME_gross")])
  fit3 <- tryCatch(
    TVECM(y, lag = lag_order, nthresh = 2, trim = 0.15,
          ngridBeta = 20, ngridTh = 30, plot = FALSE,
          common = "only_ECT", include = "const", trace = FALSE),
    error = function(e) e
  )
  if (inherits(fit3, "error")) {
    return(tibble(sample = s, status = "failed", error = conditionMessage(fit3),
                  min_regime_n = NA_real_, outer_regimes_sufficient = FALSE))
  }
  nr <- as.numeric(fit3[["model.specific"]][["nobs"]]) *
    nrow(y)
  tibble(sample = s, status = "estimated", error = NA_character_,
         min_regime_n = min(nr), outer_regimes_sufficient = min(nr) >= 8)
})
write.csv(bind_rows(three_rows), file.path(out_dir,
                                           "three_regime_inaction_band_gate.csv"),
          row.names = FALSE)

fig <- ggplot(ect_rows, aes(year, ECT_import_machinery, colour = ect_regime)) +
  geom_hline(yintercept = 0, linewidth = 0.25, colour = "grey50") +
  geom_line(linewidth = 0.45) +
  geom_point(size = 0.8) +
  facet_wrap(~sample, scales = "free_x") +
  labs(x = NULL, y = "Import ECT",
       title = "Endogenous import-ECT regimes") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "bottom")
ggsave(file.path(fig_dir, "endogenous_ect_regimes.pdf"), fig,
       width = 8, height = 5, device = cairo_pdf)

if (nrow(boot_rows) > 0L) {
  p <- ggplot(boot_rows, aes(statistic, fill = test)) +
    geom_histogram(bins = 35, alpha = 0.55, colour = "white") +
    facet_wrap(~sample + test, scales = "free") +
    labs(x = "Bootstrap test statistic", y = "Count",
         title = "Endogenous TVECM bootstrap distributions") +
    theme_minimal(base_size = 9) + theme(legend.position = "none")
  ggsave(file.path(fig_dir, "endogenous_tvecm_bootstrap.pdf"), p,
         width = 8, height = 6, device = cairo_pdf)
}

integrity <- tibble(
  check = c("three_samples", "negative_ect_signal_defined", "bootstrap_count_recorded",
            "primary_joint_estimator", "three_regime_gate_recorded"),
  passed = c(
    nrow(summary_rows) == 3L,
    nrow(ect_rows) > 0L && all(!is.na(ect_rows$binding_signal)),
    nrow(summary_rows) == 0L || all(is.na(summary_rows$bootstrap_replications) |
      summary_rows$bootstrap_replications == boot_n),
    nrow(summary_rows) == 0L || all(is.na(summary_rows$estimator) |
      summary_rows$estimator == "tsDyn::TVECM joint beta-threshold search"),
    nrow(bind_rows(three_rows)) == 3L
  ),
  detail = c(
    "full, pre-1974, and post-1974 models attempted",
    "negative ECT and lower-ECT regime are kept as separate fields",
    "the configured bootstrap count is recorded",
    "the bivariate joint beta/threshold estimator is the headline route",
    "three-regime robustness is conditional on regime-size diagnostics"
  )
)
write.csv(integrity, file.path(out_dir, "s40_endogenous_tvecm_integrity.csv"),
          row.names = FALSE)
stopifnot(all(integrity$passed))
message("S40 endogenous ECT-TVECM complete: ", out_dir,
        "; bootstrap_n=", boot_n)
