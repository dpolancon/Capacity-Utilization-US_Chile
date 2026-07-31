#!/usr/bin/env Rscript

# S20: complete urca battery and two mechanically separate break methods.
# LOESS fitted values are never submitted to unit-root tests. The smoother is
# used only to compute second-derivative zero-crossings that date candidate
# changes in the tendency of observed kappa.
# Parametric dates use only Bai-Perron, Zivot-Andrews, Gregory-Hansen,
# and cajolst evidence. The two routes are never pooled for selection.

source("C:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_SBVECM_common.R")
suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
})

set.seed(sbvecm_seed)
B_break <- as.integer(Sys.getenv("CL_SBVECM_LOESS_BOOT_B", "999"))
if (!is.finite(B_break) || B_break < 499L) {
  stop("CL_SBVECM_LOESS_BOOT_B must be at least 499 for LOESS crossing stability.")
}

panel_file <- sbvecm_dir("data", "processed", "CL", "SBVECM",
                        "cl_capital_1920_2024.csv")
panel <- read.csv(panel_file, stringsAsFactors = FALSE)
out_dir <- sbvecm_dir("output", "CL", "SBVECM", "S20_DUAL_ROUTE_BREAK_AUDIT")
fig_dir <- file.path(out_dir, "figures")
sbvecm_ensure_dir(out_dir)
sbvecm_ensure_dir(fig_dir)

series <- list(k_ME = panel$k_ME, k_NR = panel$k_NR, kappa = panel$kappa)

# ---------------------------------------------------------------------------
# 1. Complete raw urca battery
# ---------------------------------------------------------------------------
raw_battery <- do.call(rbind, lapply(names(series), function(v) {
  sbvecm_run_urca_battery(series[[v]], panel$year, v, "NONE", "raw")
}))
raw_battery <- sbvecm_mark_primary(raw_battery)
raw_battery$tested_object <- "observed_capital_series"
write.csv(raw_battery, file.path(out_dir, "urca_complete_battery_raw.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# 2. LOESS route: cross-validated span and moving-block bootstrap
# ---------------------------------------------------------------------------
span_grid <- seq(0.15, 0.75, by = 0.01)
span_cv <- sbvecm_loess_cv_span(panel$year, panel$kappa, span_grid)
min_row <- which.min(span_cv$loocv_mse)
one_se_threshold <- span_cv$loocv_mse[min_row] + span_cv$loocv_se[min_row]
# The one-standard-error LOOCV choice avoids treating high-frequency curvature
# as a structural break while remaining a leave-one-out criterion.
chosen_span <- max(span_cv$span[span_cv$loocv_mse <= one_se_threshold])
span_cv$selected_one_se <- span_cv$span == chosen_span
write.csv(span_cv, file.path(out_dir, "loess_span_loocv.csv"), row.names = FALSE)

loess_fit <- sbvecm_loess_fit(panel$year, panel$kappa, chosen_span)
loess_candidates <- sbvecm_loess_crossings(panel$year, loess_fit$d2)

growth <- cbind(d_k_NR = diff(panel$k_NR), d_k_ME = diff(panel$k_ME))
block_length <- max(4L, as.integer(round(length(panel$year)^(1 / 3))))
loess_boot_dates <- vector("list", B_break)
for (b in seq_len(B_break)) {
  idx <- sbvecm_block_indices(nrow(growth), block_length)
  gb <- growth[idx, , drop = FALSE]
  k_nr_b <- c(panel$k_NR[1], panel$k_NR[1] + cumsum(gb[, "d_k_NR"]))
  k_me_b <- c(panel$k_ME[1], panel$k_ME[1] + cumsum(gb[, "d_k_ME"]))
  fit_b <- tryCatch(
    sbvecm_loess_fit(panel$year, k_me_b - k_nr_b, chosen_span),
    error = function(e) NULL
  )
  loess_boot_dates[[b]] <- if (is.null(fit_b)) integer() else
    sbvecm_loess_crossings(panel$year, fit_b$d2)
}

match_radius <- 6L
loess_selection <- lapply(loess_candidates, function(candidate) {
  matched <- vapply(loess_boot_dates, function(x) {
    if (!length(x)) return(NA_integer_)
    nearest <- x[which.min(abs(x - candidate))]
    if (abs(nearest - candidate) <= match_radius) nearest else NA_integer_
  }, integer(1))
  selected <- matched[is.finite(matched)]
  data.frame(
    break_route = "LOESS",
    candidate_year = candidate,
    selection_frequency = length(selected) / B_break,
    band80_low = if (length(selected)) unname(quantile(selected, 0.10, type = 1)) else NA,
    band80_high = if (length(selected)) unname(quantile(selected, 0.90, type = 1)) else NA,
    band80_width = if (length(selected)) diff(unname(quantile(selected, c(0.10, 0.90),
                                                                type = 1))) else NA,
    bootstrap_replications = B_break,
    block_length = block_length,
    stringsAsFactors = FALSE
  )
})
loess_selection <- do.call(rbind, loess_selection)
loess_selection$bounded_band <- with(
  loess_selection, is.finite(band80_width) & band80_width <= 12
)
loess_selection$distinct_band <- TRUE
if (nrow(loess_selection) > 1L) {
  for (i in seq_len(nrow(loess_selection) - 1L)) {
    if (loess_selection$band80_high[i] >= loess_selection$band80_low[i + 1L]) {
      loess_selection$distinct_band[c(i, i + 1L)] <- FALSE
    }
  }
}
loess_selection$retained <- with(
  loess_selection,
  selection_frequency >= 0.75 & bounded_band & distinct_band
)
loess_breaks <- as.integer(loess_selection$candidate_year[loess_selection$retained])
write.csv(loess_selection, file.path(out_dir, "loess_breakpoint_selection.csv"),
          row.names = FALSE)

loess_path <- data.frame(
  year = panel$year,
  kappa = panel$kappa,
  loess = loess_fit$fitted,
  first_derivative = loess_fit$d1,
  second_derivative = loess_fit$d2,
  span = chosen_span,
  empirical_role = "curvature_date_identification_only"
)
write.csv(loess_path, file.path(out_dir, "loess_kappa_derivatives.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# 3. Parametric route, without consulting LOESS objects
# ---------------------------------------------------------------------------
bp_rows <- list()
bp_plot_rows <- list()
bp_plot_breaks <- list()
bp_specs <- list(
  k_ME = k_ME ~ year,
  k_NR = k_NR ~ year,
  kappa = kappa ~ year,
  capital_relation = k_NR ~ k_ME
)
bp_data <- panel[c("year", "k_ME", "k_NR", "kappa")]
for (nm in names(bp_specs)) {
  bp_full <- breakpoints(bp_specs[[nm]], data = bp_data, h = 0.15, breaks = 5)
  bp_bic <- breakpoints(bp_full)
  idx <- bp_bic$breakpoints
  idx <- idx[is.finite(idx)]
  segment <- if (length(idx)) {
    breakfactor(bp_bic)
  } else {
    factor(rep("segment1", nrow(bp_data)))
  }
  plot_data <- transform(bp_data, segment = segment)
  segmented_fit <- switch(
    nm,
    k_ME = lm(k_ME ~ year * segment, data = plot_data),
    k_NR = lm(k_NR ~ year * segment, data = plot_data),
    kappa = lm(kappa ~ year * segment, data = plot_data),
    capital_relation = lm(k_NR ~ k_ME * segment, data = plot_data)
  )
  observed_response <- switch(
    nm,
    k_ME = panel$k_ME,
    k_NR = panel$k_NR,
    kappa = panel$kappa,
    capital_relation = panel$k_NR
  )
  panel_label <- switch(
    nm,
    k_ME = "Machinery log stock",
    k_NR = "Structures log stock",
    kappa = "Capital composition",
    capital_relation = "Normalized capital relation"
  )
  bp_plot_rows[[length(bp_plot_rows) + 1L]] <- data.frame(
    year = panel$year,
    specification = nm,
    panel_label = panel_label,
    observed = observed_response,
    fitted = as.numeric(fitted(segmented_fit)),
    stringsAsFactors = FALSE
  )
  if (length(idx)) {
    bp_plot_breaks[[length(bp_plot_breaks) + 1L]] <- data.frame(
      specification = nm,
      panel_label = panel_label,
      break_year = panel$year[idx],
      stringsAsFactors = FALSE
    )
  }
  if (!length(idx)) next
  ci <- tryCatch(confint(bp_bic), error = function(e) NULL)
  for (j in seq_along(idx)) {
    lo <- hi <- idx[j]
    if (!is.null(ci) && !is.null(ci$confint) && nrow(ci$confint) >= j) {
      lo <- ci$confint[j, 1]
      hi <- ci$confint[j, 3]
    }
    bp_rows[[length(bp_rows) + 1L]] <- data.frame(
      break_route = "PARAMETRIC",
      procedure = "Bai-Perron",
      specification = nm,
      candidate_year = panel$year[idx[j]],
      interval_low = panel$year[max(1L, as.integer(lo))],
      interval_high = panel$year[min(nrow(panel), as.integer(hi))],
      statistic = NA_real_,
      critical_5 = NA_real_,
      rejects_at_5pct = NA,
      stringsAsFactors = FALSE
    )
  }
}

za_rows <- list()
for (v in names(series)) {
  for (model in c("intercept", "trend", "both")) {
    za_stats <- lapply(0:4, function(lag) {
      o <- ur.za(series[[v]], model = model, lag = lag)
      za_k <- length(coef(o@testreg))
      za_n <- length(residuals(o@testreg))
      za_rss <- sum(residuals(o@testreg)^2)
      data.frame(
        lag = lag,
        statistic = as.numeric(o@teststat),
        critical_5 = as.numeric(o@cval[2]),
        bpoint = as.integer(o@bpoint),
        bic = za_n * log(za_rss / za_n) + za_k * log(za_n)
      )
    })
    za_stats <- do.call(rbind, za_stats)
    z <- za_stats[which.min(za_stats$bic), ]
    za_rows[[length(za_rows) + 1L]] <- data.frame(
      break_route = "PARAMETRIC",
      procedure = "Zivot-Andrews",
      specification = paste(v, model, sep = ":"),
      candidate_year = panel$year[z$bpoint],
      interval_low = panel$year[z$bpoint] - 2L,
      interval_high = panel$year[z$bpoint] + 2L,
      statistic = z$statistic,
      critical_5 = z$critical_5,
      rejects_at_5pct = z$statistic < z$critical_5,
      stringsAsFactors = FALSE
    )
  }
}

gh_design <- function(y, x, year, break_year, model) {
  D <- as.integer(year >= break_year)
  DT <- pmax(0, year - break_year)
  if (model == "level") return(lm(y ~ x + D))
  if (model == "trend") return(lm(y ~ x + D + year + DT))
  if (model == "regime") return(lm(y ~ x + D + I(D * x)))
  stop("Unknown Gregory-Hansen model.")
}

gh_rows <- list()
trim_idx <- seq(floor(0.15 * nrow(panel)), ceiling(0.85 * nrow(panel)))
for (model in c("level", "trend", "regime")) {
  scan <- lapply(trim_idx, function(i) {
    fit <- gh_design(panel$k_NR, panel$k_ME, panel$year, panel$year[i], model)
    adf <- sbvecm_adf_stat(residuals(fit), deterministic = "none", max_lag = 4L)
    data.frame(index = i, year = panel$year[i], statistic = adf["statistic"],
               lag = adf["lag"])
  })
  scan <- do.call(rbind, scan)
  best <- scan[which.min(scan$statistic), ]
  near <- scan$year[scan$statistic <= best$statistic + 0.15]
  gh_cv <- switch(model, level = -4.61, trend = -4.99, regime = -4.95)
  gh_rows[[length(gh_rows) + 1L]] <- data.frame(
    break_route = "PARAMETRIC",
    procedure = "Gregory-Hansen",
    specification = model,
    candidate_year = best$year,
    interval_low = min(near),
    interval_high = max(near),
    statistic = best$statistic,
    critical_5 = gh_cv,
    rejects_at_5pct = best$statistic < gh_cv,
    stringsAsFactors = FALSE
  )
}

cajolst_rows <- list()
X <- as.matrix(panel[c("k_NR", "k_ME")])
for (lag in 2:5) {
  for (trend in c(FALSE, TRUE)) {
    obj <- tryCatch(urca::cajolst(X, trend = trend, K = lag), error = function(e) NULL)
    if (is.null(obj)) next
    bp <- as.integer(obj@bp)
    cajolst_rows[[length(cajolst_rows) + 1L]] <- data.frame(
      break_route = "PARAMETRIC",
      procedure = "cajolst",
      specification = paste0("K", lag, ":", if (trend) "trend" else "no_trend"),
      candidate_year = panel$year[bp],
      interval_low = panel$year[bp] - 2L,
      interval_high = panel$year[bp] + 2L,
      statistic = as.numeric(obj@teststat[2]),
      critical_5 = as.numeric(obj@cval[2, "5pct"]),
      rejects_at_5pct = as.numeric(obj@teststat[2]) > as.numeric(obj@cval[2, "5pct"]),
      stringsAsFactors = FALSE
    )
  }
}

param_evidence <- do.call(rbind, c(bp_rows, za_rows, gh_rows, cajolst_rows))
param_evidence$interval_low <- pmax(param_evidence$interval_low, min(panel$year))
param_evidence$interval_high <- pmin(param_evidence$interval_high, max(panel$year))
write.csv(param_evidence, file.path(out_dir, "parametric_breakpoint_evidence.csv"),
          row.names = FALSE)
bp_plot_data <- do.call(rbind, bp_plot_rows)
bp_plot_dates <- if (length(bp_plot_breaks)) {
  do.call(rbind, bp_plot_breaks)
} else {
  data.frame(specification = character(), panel_label = character(),
             break_year = integer())
}
write.csv(bp_plot_data, file.path(out_dir, "bai_perron_segmented_fits.csv"),
          row.names = FALSE)
write.csv(bp_plot_dates, file.path(out_dir, "bai_perron_break_dates.csv"),
          row.names = FALSE)

# Cluster only parametric intervals. A procedure can contribute at most one
# support vote to a cluster, preventing its configuration count from dominating.
candidate_years <- sort(unique(param_evidence$candidate_year))
clusters <- lapply(candidate_years, function(y) {
  z <- param_evidence[
    param_evidence$interval_low <= y & param_evidence$interval_high >= y, ]
  data.frame(
    candidate_year = y,
    procedure_support = length(unique(z$procedure)),
    procedures = paste(sort(unique(z$procedure)), collapse = ";"),
    interval_low = if (nrow(z)) max(z$interval_low) else y,
    interval_high = if (nrow(z)) min(z$interval_high) else y,
    rejection_support = sum(z$rejects_at_5pct %in% TRUE, na.rm = TRUE),
    stringsAsFactors = FALSE
  )
})
param_clusters <- do.call(rbind, clusters)
param_clusters <- param_clusters[param_clusters$procedure_support >= 2L, ]
param_clusters <- param_clusters[
  order(-param_clusters$procedure_support, -param_clusters$rejection_support,
        param_clusters$candidate_year), ]

min_seg <- ceiling(0.15 * nrow(panel))
selected_param <- integer()
if (nrow(param_clusters)) {
  for (y in param_clusters$candidate_year) {
    trial <- sort(c(selected_param, y))
    segment_lengths <- diff(c(min(panel$year) - 1L, trial, max(panel$year)))
    if (all(segment_lengths >= min_seg)) selected_param <- trial
    if (length(selected_param) == 3L) break
  }
}
param_breaks <- as.integer(selected_param)
param_clusters$retained <- param_clusters$candidate_year %in% param_breaks
param_clusters$minimum_segment_years <- min_seg
write.csv(param_clusters, file.path(out_dir, "parametric_breakpoint_selection.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# 4. Unit-root batteries for observed capital series under alternative
# deterministic controls. No LOESS fitted value or derivative enters a test.
# ---------------------------------------------------------------------------
route_breaks <- list(LOESS = loess_breaks, PARAMETRIC = param_breaks)
adjusted_batteries <- list()
for (route in names(route_breaks)) {
  breaks <- route_breaks[[route]]
  for (v in names(series)) {
    adjusted <- sbvecm_adjust_for_steps(series[[v]], panel$year, breaks)
    tested <- sbvecm_run_urca_battery(
        adjusted, panel$year, v, route,
        if (length(breaks)) "route_step_and_linear_trend_residual" else "no_retained_break"
      )
    tested$tested_object <-
      "observed_capital_series_after_step_and_linear_trend_controls"
    adjusted_batteries[[length(adjusted_batteries) + 1L]] <- tested
  }
}
adjusted_battery <- sbvecm_mark_primary(do.call(rbind, adjusted_batteries))
all_battery <- rbind(raw_battery, adjusted_battery)
write.csv(adjusted_battery,
          file.path(out_dir, "urca_complete_battery_route_adjusted.csv"),
          row.names = FALSE)
write.csv(all_battery, file.path(out_dir, "urca_complete_battery_all.csv"),
          row.names = FALSE)

family_verdicts <- sbvecm_family_verdicts(all_battery)
order_ledger <- sbvecm_order_adjudication(family_verdicts)
write.csv(family_verdicts, file.path(out_dir, "urca_family_primary_verdicts.csv"),
          row.names = FALSE)
write.csv(order_ledger, file.path(out_dir, "route_specific_integration_orders.csv"),
          row.names = FALSE)

break_sets <- data.frame(
  break_route = c("LOESS", "PARAMETRIC"),
  break_years = c(
    if (length(loess_breaks)) paste(loess_breaks, collapse = ";") else "NONE",
    if (length(param_breaks)) paste(param_breaks, collapse = ";") else "NONE"
  ),
  n_breaks = c(length(loess_breaks), length(param_breaks)),
  selection_basis = c(
    "LOESS(kappa) second-derivative zero-crossings only",
    "Bai-Perron, Zivot-Andrews, Gregory-Hansen, cajolst only"
  ),
  stringsAsFactors = FALSE
)
write.csv(break_sets, file.path(out_dir, "route_break_sets.csv"), row.names = FALSE)

comparison <- merge(
  data.frame(loess_year = loess_candidates),
  data.frame(parametric_year = sort(unique(param_evidence$candidate_year))),
  by = NULL
)
comparison$distance_years <- abs(comparison$loess_year - comparison$parametric_year)
comparison <- comparison[order(comparison$loess_year, comparison$distance_years), ]
comparison$nearest_parametric_for_loess <- ave(
  comparison$distance_years, comparison$loess_year,
  FUN = function(x) x == min(x)
)
comparison$used_for_selection <- FALSE
write.csv(comparison, file.path(out_dir, "break_route_comparison_only.csv"),
          row.names = FALSE)

# ---------------------------------------------------------------------------
# 5. Visual-first figures
# ---------------------------------------------------------------------------
long_cap <- panel |>
  select(year, k_ME, k_NR) |>
  pivot_longer(-year, names_to = "series", values_to = "value")

p1 <- ggplot(long_cap, aes(year, value, colour = series)) +
  geom_line(linewidth = 0.7) +
  scale_colour_manual(values = c(k_ME = "#163A5F", k_NR = "#A33A3A"),
                      labels = c(k_ME = expression(k[t]^ME),
                                 k_NR = expression(k[t]^NR))) +
  labs(x = NULL, y = "Log capital stock", colour = NULL) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "top", panel.grid.minor = element_blank())
ggsave(file.path(fig_dir, "fig1_capital_log_stocks.png"), p1,
       width = 7.2, height = 3.3, dpi = 320)
ggsave(file.path(fig_dir, "fig1_capital_log_stocks.pdf"), p1,
       width = 7.2, height = 3.3, device = cairo_pdf)

p2 <- ggplot(loess_path, aes(year)) +
  geom_point(aes(y = kappa), colour = "#5C3A8E", size = 1.25, alpha = 0.72) +
  geom_line(aes(y = loess), colour = "#177245", linewidth = 0.9) +
  geom_vline(data = loess_selection[loess_selection$retained, ],
             aes(xintercept = candidate_year), colour = "#B22222",
             linetype = "dashed", linewidth = 0.45) +
  labs(x = NULL, y = expression(kappa[t]),
       subtitle = paste0("LOOCV one-SE span = ", sprintf("%.2f", chosen_span))) +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank())
ggsave(file.path(fig_dir, "fig2_kappa_loess_route.png"), p2,
       width = 7.2, height = 3.2, dpi = 320)
ggsave(file.path(fig_dir, "fig2_kappa_loess_route.pdf"), p2,
       width = 7.2, height = 3.2, device = cairo_pdf)

p_bp <- ggplot(bp_plot_data, aes(year)) +
  geom_point(aes(y = observed), colour = "#4D4D4D", size = 0.65, alpha = 0.65) +
  geom_line(aes(y = fitted), colour = "#B22222", linewidth = 0.75) +
  geom_vline(data = bp_plot_dates, aes(xintercept = break_year),
             colour = "#163A5F", linetype = "dashed", linewidth = 0.35) +
  facet_wrap(~ panel_label, scales = "free_y", ncol = 2) +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 9.5) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold"))
ggsave(file.path(fig_dir, "fig3_bai_perron_segmented_fits.png"), p_bp,
       width = 7.2, height = 4.3, dpi = 320)
ggsave(file.path(fig_dir, "fig3_bai_perron_segmented_fits.pdf"), p_bp,
       width = 7.2, height = 4.3, device = cairo_pdf)

timeline <- rbind(
  data.frame(route = "LOESS retained",
             year = loess_breaks),
  data.frame(route = "Parametric retained",
             year = param_breaks)
)
if (!nrow(timeline)) {
  timeline <- data.frame(route = c("LOESS retained", "Parametric retained"),
                         year = c(NA, NA))
}
p3 <- ggplot(timeline, aes(year, route, colour = route)) +
  geom_point(size = 3, na.rm = TRUE) +
  geom_vline(data = timeline, aes(xintercept = year, colour = route),
             linewidth = 0.35, alpha = 0.65, na.rm = TRUE) +
  scale_colour_manual(values = c("LOESS retained" = "#5C3A8E",
                                 "Parametric retained" = "#B22222")) +
  scale_x_continuous(limits = c(1920, 2024), breaks = seq(1920, 2020, 20)) +
  labs(x = NULL, y = NULL, colour = NULL) +
  theme_minimal(base_size = 10) +
  theme(legend.position = "none", panel.grid.minor = element_blank())
ggsave(file.path(fig_dir, "fig3_break_route_comparison.png"), p3,
       width = 7.2, height = 2.25, dpi = 320)
ggsave(file.path(fig_dir, "fig3_break_route_comparison.pdf"), p3,
       width = 7.2, height = 2.25, device = cairo_pdf)

heat <- order_ledger |>
  filter(break_route %in% c("LOESS", "PARAMETRIC")) |>
  mutate(label = integration_order,
         score = case_when(
           integration_order == "I(1)" ~ 2,
           integration_order == "I(0)" ~ 1,
           integration_order == "I(2)-risk" ~ -1,
           TRUE ~ 0
         ))
p4 <- ggplot(heat, aes(variable, break_route, fill = score)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = label), size = 3.4) +
  scale_fill_gradient2(low = "#B22222", mid = "#E8E8E8", high = "#177245",
                       midpoint = 0, guide = "none") +
  labs(x = NULL, y = NULL) +
  theme_minimal(base_size = 10) +
  theme(panel.grid = element_blank())
ggsave(file.path(fig_dir, "fig4_route_order_gate.png"), p4,
       width = 7.2, height = 2.4, dpi = 320)
ggsave(file.path(fig_dir, "fig4_route_order_gate.pdf"), p4,
       width = 7.2, height = 2.4, device = cairo_pdf)

route_contamination_checks <- data.frame(
  check = c(
    "LOESS evidence contains only LOESS route",
    "parametric evidence contains only PARAMETRIC route",
    "comparison table never used for selection",
    "route labels are locked",
    "no shared dummy matrix constructed",
    "LOESS fitted path is excluded from unit-root testing"
  ),
  pass = c(
    all(loess_selection$break_route == "LOESS"),
    all(param_evidence$break_route == "PARAMETRIC"),
    !any(comparison$used_for_selection),
    setequal(names(route_breaks), c("LOESS", "PARAMETRIC")),
    TRUE,
    all(!grepl("loess_fit|loess_path|derivative", all_battery$tested_object,
               ignore.case = TRUE)) &&
      all(loess_path$empirical_role == "curvature_date_identification_only")
  ),
  stringsAsFactors = FALSE
)
write.csv(route_contamination_checks,
          file.path(out_dir, "route_contamination_checks.csv"), row.names = FALSE)
if (!all(route_contamination_checks$pass)) stop("Break-route contamination detected.")

message("S20 complete. LOESS retained: ",
        if (length(loess_breaks)) paste(loess_breaks, collapse = ", ") else "none",
        ". Parametric retained: ",
        if (length(param_breaks)) paste(param_breaks, collapse = ", ") else "none",
        ".")
