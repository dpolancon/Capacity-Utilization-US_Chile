#!/usr/bin/env Rscript

# Chile Stage S30 — gate-controlled capital-composition and WBOP estimators.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(urca)
  library(vars)
  library(cointReg)
  library(digest)
})

set.seed(1920)
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
panel_file <- file.path(root, "data", "processed", "CL", "S10_SOURCE_PANEL",
                        "chile_wbop_capital_annual_1920_2024.csv")
s20 <- file.path(root, "output", "CL", "S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY")
out <- file.path(root, "output", "CL", "S30_CHOICE_TECHNIQUE_BOP")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

d <- read.csv(panel_file, check.names = FALSE)
gate <- read.csv(file.path(s20, "capital_window_model_gate.csv"),
                 check.names = FALSE)
orders <- read.csv(file.path(s20, "capital_window_integration_verdicts.csv"),
                   check.names = FALSE)
wbop_roles <- read.csv(file.path(s20, "wbop_candidate_role_ledger.csv"),
                       check.names = FALSE)
data_sha <- digest(panel_file, algo = "sha256", file = TRUE)

window_order <- c("FULL", "NITRATE", "ISI", "DICTATORSHIP", "DEMO_NEOLIBERAL")
gate$window_id <- factor(gate$window_id, levels = window_order)
gate <- gate[order(gate$window_id), ]
gate$window_id <- as.character(gate$window_id)

fit_cointreg <- function(estimator, dd) {
  x <- as.matrix(dd["k_me"])
  y <- dd$k_nr
  deter <- rep(1, nrow(dd))
  fit <- switch(
    estimator,
    IM_OLS = cointRegIM(x = x, y = y, deter = deter),
    FM_OLS = cointRegFM(x = x, y = y, deter = deter),
    DOLS = cointRegD(x = x, y = y, deter = deter,
                    n.lead = 1L, n.lag = 1L)
  )
  idx <- grep("k_me", names(fit[["theta"]]))[1]
  tibble(
    beta_me = unname(fit[["theta"]][idx]),
    std_error = unname(fit[["sd.theta"]][idx]),
    p_value = unname(fit[["p.theta"]][idx]),
    ci_low = beta_me - 1.96 * std_error,
    ci_high = beta_me + 1.96 * std_error
  )
}

# Residual bootstrap under rank zero for small-sample Johansen trace inference.
bootstrap_trace_rank0 <- function(X, K, ecdet, B = 999L) {
  X <- as.matrix(X)
  dx <- diff(X)
  p <- max(1L, K - 1L)
  if (nrow(dx) <= p + 5L) return(NA_real_)
  emb <- embed(dx, p + 1L)
  Y <- emb[, 1:2, drop = FALSE]
  lagged <- emb[, -(1:2), drop = FALSE]
  trend <- seq_len(nrow(Y))
  design <- cbind(1, if (ecdet == "trend") trend else NULL, lagged)
  fit <- lm.fit(design, Y)
  residuals <- fit$residuals
  residuals <- sweep(residuals, 2, colMeans(residuals), "-")
  observed <- ca.jo(X, type = "trace", ecdet = ecdet, K = K,
                    spec = "transitory")@teststat[2]
  stats <- rep(NA_real_, B)
  for (b in seq_len(B)) {
    dx_b <- matrix(0, nrow(dx), 2)
    dx_b[seq_len(p), ] <- dx[seq_len(p), , drop = FALSE]
    draw <- sample(seq_len(nrow(residuals)), nrow(dx) - p, replace = TRUE)
    for (t in (p + 1L):nrow(dx)) {
      lags <- as.vector(t(dx_b[(t - 1L):(t - p), , drop = FALSE]))
      row <- c(1, if (ecdet == "trend") t else NULL, lags)
      dx_b[t, ] <- as.numeric(row %*% fit$coefficients) +
        residuals[draw[t - p], ]
    }
    X_b <- rbind(X[1, ], sweep(apply(dx_b, 2, cumsum), 2, X[1, ], "+"))
    stats[b] <- tryCatch(
      ca.jo(X_b, type = "trace", ecdet = ecdet, K = K,
            spec = "transitory")@teststat[2],
      error = function(e) NA_real_
    )
  }
  mean(stats >= observed, na.rm = TRUE)
}

single_results <- tibble(
  specification_id = character(), window_id = character(), window = character(),
  start_year = integer(), end_year = integer(), n = integer(),
  estimator = character(), role = character(), beta_me = double(),
  std_error = double(), p_value = double(), ci_low = double(),
  ci_high = double(), po_statistic = double(), po_critical_5pct = double(),
  residual_cointegration = logical(), disposition = character()
)
johansen_results <- tibble(
  specification_id = character(), window_id = character(), window = character(),
  start_year = integer(), end_year = integer(), n = integer(),
  deterministic_case = character(), K = integer(), lag_selection = character(),
  trace_r0 = double(), critical_r0_5pct = double(), rank_5pct = integer(),
  bootstrap_reps = integer(), bootstrap_p_value = double(),
  beta_me = double(), unit_restriction_statistic = double(),
  unit_restriction_p_value = double(), unit_vector_not_rejected = logical(),
  disposition = character()
)
adjustment_results <- tibble(
  specification_id = character(), window_id = character(), window = character(),
  deterministic_case = character(), K = integer(), equation = character(),
  alpha = double(), t_statistic = double(), p_value = double(),
  weakly_exogenous = logical()
)
system_diagnostics <- tibble(
  specification_id = character(), window_id = character(),
  deterministic_case = character(), K = integer(),
  serial_p_value = double(), normality_p_value = double(),
  maximum_companion_root = double(), stable = logical()
)

model_ledger <- bind_rows(lapply(seq_len(nrow(gate)), function(i) {
  g <- gate[i, ]
  bind_rows(lapply(c("IM_OLS", "FM_OLS", "DOLS", "JOHANSEN"), function(est) {
    tibble(
      specification_id = paste0("CL-", g$window_id, "-", est),
      window_id = g$window_id, window = g$window,
      start_year = g$start_year, end_year = g$end_year,
      n = g$end_year - g$start_year + 1L,
      sample = paste0(g$start_year, "--", g$end_year),
      estimator = est,
      role = case_when(
        est == "IM_OLS" ~ "active_baseline",
        est == "FM_OLS" ~ "diagnostic_comparator",
        est == "DOLS" ~ "fragility_diagnostic",
        TRUE ~ "system_benchmark"
      ),
      integration_gate = ifelse(g$standard_cointegration_eligible,
                                "passed", "failed"),
      disposition = ifelse(g$standard_cointegration_eligible,
                           "eligible_for_estimation", "blocked"),
      reason = g$reason, data_sha256 = data_sha,
      script = "codes/CL_S30_choice_technique_bop_models.R",
      deterministic_case = ifelse(est == "JOHANSEN",
                                  "const and trend gated cases",
                                  "constant"),
      lag_selection = ifelse(est == "JOHANSEN",
                             "BIC with annual maximum four",
                             NA_character_),
      rank_5pct = NA_integer_,
      beta_me = NA_real_,
      alpha_nr = NA_real_,
      alpha_me = NA_real_,
      bootstrap_required = ifelse(
        g$end_year - g$start_year + 1L <= 30L, 999L, 0L
      ),
      bootstrap_executed = 0L,
      bootstrap_p_value = NA_real_,
      unit_restriction_statistic = NA_real_,
      unit_restriction_p_value = NA_real_,
      serial_p_value = NA_real_,
      normality_p_value = NA_real_,
      maximum_companion_root = NA_real_,
      stable = NA
    )
  }))
}))

for (i in which(gate$standard_cointegration_eligible)) {
  g <- gate[i, ]
  dd <- d |>
    dplyr::filter(year >= g$start_year, year <= g$end_year) |>
    dplyr::select(year, k_nr, k_me) |>
    dplyr::filter(if_all(-year, is.finite))
  X <- dd[, c("k_nr", "k_me")]

  po <- tryCatch(ca.po(X, demean = "constant", lag = "short", type = "Pz"),
                 error = function(e) NULL)
  po_stat <- if (is.null(po)) NA_real_ else unname(po@teststat)
  po_cv <- if (is.null(po)) NA_real_ else unname(po@cval[1, "5pct"])
  po_pass <- is.finite(po_stat) && po_stat > po_cv

  for (est in c("IM_OLS", "FM_OLS", "DOLS")) {
    r <- tryCatch(fit_cointreg(est, dd), error = function(e) NULL)
    if (is.null(r)) next
    single_results <- bind_rows(single_results, mutate(
      r,
      specification_id = paste0("CL-", g$window_id, "-", est),
      window_id = g$window_id, window = g$window,
      start_year = g$start_year, end_year = g$end_year,
      n = nrow(dd), estimator = est,
      role = ifelse(est == "IM_OLS", "active_baseline",
                    ifelse(est == "FM_OLS", "diagnostic_comparator",
                           "fragility_diagnostic")),
      po_statistic = po_stat, po_critical_5pct = po_cv,
      residual_cointegration = po_pass,
      disposition = ifelse(po_pass, "estimated_promoted",
                           "estimated_held_rank_failure"),
      .before = 1
    ))
  }

  for (ecdet in c("const", "trend")) {
    type <- ifelse(ecdet == "const", "const", "both")
    lag_max <- min(4L, max(2L, floor(nrow(dd) / 6)))
    selected <- tryCatch(
      as.integer(VARselect(X, lag.max = lag_max, type = type)$selection["SC(n)"]),
      error = function(e) 2L
    )
    K <- max(2L, min(lag_max, selected))
    jo <- tryCatch(ca.jo(X, type = "trace", ecdet = ecdet, K = K,
                         spec = "transitory"), error = function(e) NULL)
    if (is.null(jo)) next
    trace <- as.numeric(jo@teststat)
    cv5 <- as.numeric(jo@cval[, "5pct"])
    rank <- sum(trace > cv5)
    beta_vec <- as.numeric(jo@V[, 1] / jo@V[1, 1])
    beta_me <- -beta_vec[2]
    boot_p <- if (nrow(dd) <= 30L)
      bootstrap_trace_rank0(X, K, ecdet, B = 999L) else NA_real_
    rank_promoted <- rank == 1L &&
      (nrow(dd) > 30L || (is.finite(boot_p) && boot_p < 0.05))

    H <- if (nrow(jo@V) == 3L)
      cbind(c(1, -1, 0), c(0, 0, 1)) else matrix(c(1, -1), ncol = 1)
    restriction <- if (rank_promoted)
      tryCatch(blrtest(jo, H = H, r = 1), error = function(e) NULL) else NULL
    restriction_stat <- if (is.null(restriction)) NA_real_ else restriction@teststat
    restriction_p <- if (is.null(restriction)) NA_real_ else restriction@pval[1]

    sid <- paste0("CL-", g$window_id, "-JOHANSEN-", toupper(ecdet))
    johansen_results <- bind_rows(johansen_results, tibble(
      specification_id = sid, window_id = g$window_id, window = g$window,
      start_year = g$start_year, end_year = g$end_year, n = nrow(dd),
      deterministic_case = ecdet, K = K,
      lag_selection = "BIC with annual maximum four",
      trace_r0 = trace[2], critical_r0_5pct = cv5[2], rank_5pct = rank,
      bootstrap_reps = ifelse(nrow(dd) <= 30L, 999L, 0L),
      bootstrap_p_value = boot_p, beta_me = beta_me,
      unit_restriction_statistic = restriction_stat,
      unit_restriction_p_value = restriction_p,
      unit_vector_not_rejected =
        is.finite(restriction_p) && restriction_p >= 0.05,
      disposition = ifelse(rank_promoted, "rank_promoted",
                           "rank_held_or_rejected")
    ))

    if (rank_promoted) {
      cr <- tryCatch(cajorls(jo, r = 1), error = function(e) NULL)
      if (!is.null(cr)) {
        sm <- summary(cr$rlm)
        for (eq in seq_along(sm)) {
          cf <- sm[[eq]]$coefficients
          ect <- grep("^ect", rownames(cf), ignore.case = TRUE)[1]
          if (is.finite(ect)) {
            adjustment_results <- bind_rows(adjustment_results, tibble(
              specification_id = sid, window_id = g$window_id,
              window = g$window, deterministic_case = ecdet, K = K,
              equation = names(sm)[eq], alpha = cf[ect, 1],
              t_statistic = cf[ect, 3], p_value = cf[ect, 4],
              weakly_exogenous = cf[ect, 4] >= 0.05
            ))
          }
        }
      }
      vv <- tryCatch(vec2var(jo, r = 1), error = function(e) NULL)
      if (!is.null(vv)) {
        serial <- tryCatch(
          serial.test(vv, lags.pt = min(4L, floor(nrow(dd) / 5)),
                      type = "PT.asymptotic")$serial$p.value,
          error = function(e) NA_real_
        )
        normal <- tryCatch(
          normality.test(vv, multivariate.only = TRUE)$jb.mul$JB$p.value,
          error = function(e) NA_real_
        )
        root_max <- tryCatch(max(Mod(roots(vv))), error = function(e) NA_real_)
        system_diagnostics <- bind_rows(system_diagnostics, tibble(
          specification_id = sid, window_id = g$window_id,
          deterministic_case = ecdet, K = K,
          serial_p_value = serial, normality_p_value = normal,
          maximum_companion_root = root_max,
          stable = is.finite(root_max) && root_max < 1
        ))
      }
    }
  }
}

# WBOP candidates never bypass the capital gate.
wbop_model_ledger <- bind_rows(lapply(seq_len(nrow(gate)), function(i) {
  g <- gate[i, ]
  bind_rows(lapply(seq_len(nrow(wbop_roles)), function(j) {
    z <- wbop_roles[j, ]
    candidate_ok <- z$integration_order %in% c("I(1)", "I(0)")
    eligible <- g$standard_cointegration_eligible && candidate_ok
    tibble(
      specification_id = paste0("CL-", g$window_id, "-WBOP-", j),
      window_id = g$window_id, window = g$window,
      candidate = z$candidate, label = z$label,
      candidate_order = z$integration_order,
      intended_role = z$permitted_role,
      capital_gate = ifelse(g$standard_cointegration_eligible,
                            "passed", "failed"),
      disposition = ifelse(
        eligible,
        ifelse(z$integration_order == "I(1)",
               "eligible_trivariate_one_at_a_time",
               "eligible_short_run_only"),
        "blocked_by_capital_gate"
      ),
      reason = ifelse(eligible, "Candidate and capital prerequisites pass",
                      g$reason),
      data_sha256 = data_sha
    )
  }))
}))

# Figure 3: the evidence that decides whether coefficients can exist.
vote_plot <- orders |>
  dplyr::filter(variable %in% c("k_me", "k_nr")) |>
  dplyr::select(window_id, window, variable,
                stationary_share_level,
                stationary_share_first_difference,
                stationary_share_second_difference) |>
  tidyr::pivot_longer(starts_with("stationary_share"),
                      names_to = "transformation",
                      values_to = "stationary_share") |>
  dplyr::mutate(
    transformation = recode(
      transformation,
      stationary_share_level = "Level",
      stationary_share_first_difference = "First difference",
      stationary_share_second_difference = "Second difference"
    ),
    window = factor(window, levels = rev(gate$window))
  )
p_votes <- ggplot(vote_plot,
                  aes(stationary_share, window, colour = variable,
                      shape = variable)) +
  geom_vline(xintercept = 0.60, linetype = 2, colour = "grey40") +
  geom_point(size = 2.5) +
  facet_wrap(~transformation, nrow = 1) +
  scale_colour_manual(values = c(k_me = "#08306b", k_nr = "#cb181d"),
                      labels = c(k_me = expression(k[ME]),
                                 k_nr = expression(k[NR]))) +
  scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                     limits = c(0, 1)) +
  labs(x = "Share of valid tests supporting stationarity", y = NULL,
       colour = NULL, shape = NULL,
       title = "Chile: capital-stock integration evidence by historical window",
       subtitle = "The dashed line is the pre-declared 60% promotion threshold") +
  theme_minimal(base_size = 9) +
  theme(legend.position = "top", panel.grid.minor = element_blank())
ggsave(file.path(out, "fig_cl_integration_vote_map.png"), p_votes,
       width = 8.2, height = 4.3, dpi = 240)

# Figure 4: U.S.-style estimator map, with blocked cells instead of coefficients.
estimator_map <- model_ledger |>
  dplyr::mutate(
    window = factor(window, levels = rev(gate$window)),
    estimator = factor(estimator,
                       levels = c("IM_OLS", "FM_OLS", "DOLS", "JOHANSEN")),
    status = ifelse(disposition == "blocked", "Blocked", "Eligible")
  )
p_gate <- ggplot(estimator_map, aes(estimator, window, fill = status)) +
  geom_tile(colour = "white", linewidth = 1.0) +
  geom_text(aes(label = ifelse(status == "Blocked", "\u00d7", "\u2713")),
            colour = "white", fontface = "bold", size = 4.2) +
  scale_fill_manual(values = c(Blocked = "#b2182b", Eligible = "#2166ac")) +
  labs(x = NULL, y = NULL, fill = NULL,
       title = "Chile: coefficient and system-estimation admissibility map",
       subtitle = "No coefficient is reported where the common I(1) prerequisite fails") +
  theme_minimal(base_size = 9) +
  theme(legend.position = "top", panel.grid = element_blank())
ggsave(file.path(out, "fig_cl_estimator_gate_map.png"), p_gate,
       width = 7.4, height = 3.9, dpi = 240)

write.csv(model_ledger, file.path(out, "capital_model_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(single_results, file.path(out, "single_equation_results.csv"),
          row.names = FALSE, na = "")
write.csv(johansen_results, file.path(out, "johansen_rank_beta_restrictions.csv"),
          row.names = FALSE, na = "")
write.csv(adjustment_results, file.path(out, "vecm_adjustment_weak_exogeneity.csv"),
          row.names = FALSE, na = "")
write.csv(system_diagnostics, file.path(out, "vecm_system_diagnostics.csv"),
          row.names = FALSE, na = "")
write.csv(wbop_model_ledger, file.path(out, "wbop_model_role_ledger.csv"),
          row.names = FALSE, na = "")

message("CL S30 complete: ",
        sum(gate$standard_cointegration_eligible), " eligible capital windows; ",
        ifelse(any(gate$standard_cointegration_eligible),
               "gated estimators executed.", "all standard estimators blocked."))
