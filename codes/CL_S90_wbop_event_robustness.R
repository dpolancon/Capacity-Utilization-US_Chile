#!/usr/bin/env Rscript

# Chile Stage S90 — event robustness, report-facing ledgers, and final map.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(patchwork)
})

set.seed(1920)
root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
processed_s20 <- file.path(root, "data", "processed", "CL",
                           "S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY")
s20 <- file.path(root, "output", "CL", "S20_EXTERNAL_CONSTRAINT_ADMISSIBILITY")
s30 <- file.path(root, "output", "CL", "S30_CHOICE_TECHNIQUE_BOP")
out <- file.path(root, "output", "CL", "S90_WBOP_EVENT_ROBUSTNESS")
dir.create(out, recursive = TRUE, showWarnings = FALSE)

d <- read.csv(file.path(processed_s20,
                         "chile_annual_capital_wbop_event_panel.csv"),
              check.names = FALSE)
events <- read.csv(file.path(s20,
                             "annual_wbop_financing_compression_events.csv"),
                   check.names = FALSE)
gate <- read.csv(file.path(s20, "capital_window_model_gate.csv"),
                 check.names = FALSE)
orders <- read.csv(file.path(s20,
                             "capital_window_integration_verdicts.csv"),
                   check.names = FALSE)
breaks <- read.csv(file.path(s20, "capital_window_break_ledger.csv"),
                   check.names = FALSE)
inflections <- read.csv(file.path(s20,
                                  "loess_second_derivative_inflections.csv"),
                        check.names = FALSE)
capital_models <- read.csv(file.path(s30, "capital_model_ledger.csv"),
                           check.names = FALSE)
wbop_models <- read.csv(file.path(s30, "wbop_model_role_ledger.csv"),
                        check.names = FALSE)

outcomes <- c("gdp_growth", "machinery_investment",
              "d_k_me", "d_k_nr", "d_kappa")
event_panel <- bind_rows(lapply(seq_len(nrow(events)), function(i) {
  e <- events$event_year[i]
  d |>
    filter(year >= e - 3L, year <= e + 3L) |>
    mutate(event_id = events$event_id[i], event_year = e,
           relative_year = year - e) |>
    select(event_id, event_year, relative_year, all_of(outcomes))
}))
event_long <- event_panel |>
  pivot_longer(all_of(outcomes), names_to = "outcome", values_to = "value")
event_summary <- event_long |>
  group_by(outcome, relative_year) |>
  summarise(mean = mean(value, na.rm = TRUE),
            median = median(value, na.rm = TRUE),
            sd = sd(value, na.rm = TRUE),
            n = sum(is.finite(value)), se = sd / sqrt(n),
            ci_low = mean - 1.96 * se,
            ci_high = mean + 1.96 * se, .groups = "drop")

episode_effect <- event_panel |>
  filter(relative_year %in% 0:3) |>
  group_by(event_id, event_year) |>
  summarise(
    post_mean_d_k_me = mean(d_k_me, na.rm = TRUE),
    post_mean_d_k_nr = mean(d_k_nr, na.rm = TRUE),
    machinery_minus_structures = mean(d_k_me - d_k_nr, na.rm = TRUE),
    post_mean_gdp_growth = mean(gdp_growth, na.rm = TRUE),
    .groups = "drop"
  )
boot_stat <- replicate(999, {
  ids <- sample(episode_effect$event_id, nrow(episode_effect), replace = TRUE)
  mean(episode_effect$machinery_minus_structures[
    match(ids, episode_effect$event_id)], na.rm = TRUE)
})
event_bootstrap <- tibble(
  statistic = "Post-event mean d_k_me minus d_k_nr",
  estimate = mean(episode_effect$machinery_minus_structures, na.rm = TRUE),
  replications = 999L,
  ci_low = unname(quantile(boot_stat, 0.025, na.rm = TRUE)),
  ci_high = unname(quantile(boot_stat, 0.975, na.rm = TRUE)),
  inference = ifelse(ci_low > 0 | ci_high < 0,
                     "interval_excludes_zero", "interval_includes_zero")
)

thresholds <- c(0.03, 0.04, 0.05, 0.06)
threshold_ledger <- bind_rows(lapply(thresholds, function(th) {
  years <- d$year[is.finite(d$d_external_financing_proxy_gdp) &
                    d$d_external_financing_proxy_gdp <= -th]
  tibble(threshold_pp = 100 * th, event_count = length(years),
         event_years = paste(years, collapse = ";"))
}))
loo <- bind_rows(lapply(seq_len(nrow(episode_effect)), function(i) {
  z <- episode_effect[-i, , drop = FALSE]
  tibble(
    excluded_event_year = episode_effect$event_year[i],
    remaining_events = nrow(z),
    mean_machinery_minus_structures =
      mean(z$machinery_minus_structures, na.rm = TRUE)
  )
}))

# Figure 6: external-pressure dating above; capital response below.
p_pressure <- ggplot(d, aes(year, 100 * d_external_financing_proxy_gdp)) +
  geom_hline(yintercept = -5, colour = "#cb181d", linewidth = 0.5) +
  geom_col(aes(fill = financing_compression_5pp == 1), width = 0.8) +
  scale_fill_manual(values = c(`FALSE` = "#6baed6", `TRUE` = "#cb181d"),
                    guide = "none") +
  labs(x = NULL, y = "Percentage points",
       title = "A. Annual WBOP financing compression",
       subtitle = "Change in -CA/GDP; red bars cross the five-point rule") +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank())

p_event <- event_summary |>
  filter(outcome %in% c("d_k_me", "d_k_nr")) |>
  mutate(outcome = recode(outcome,
                          d_k_me = "Machinery and equipment",
                          d_k_nr = "Nonresidential structures")) |>
  ggplot(aes(relative_year, mean, colour = outcome)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey40") +
  geom_hline(yintercept = 0, colour = "grey75") +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high, fill = outcome),
              alpha = 0.12, colour = NA) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.7) +
  scale_colour_manual(values = c("Machinery and equipment" = "#08306b",
                                 "Nonresidential structures" = "#cb181d")) +
  scale_fill_manual(values = c("Machinery and equipment" = "#08306b",
                               "Nonresidential structures" = "#cb181d")) +
  scale_x_continuous(breaks = -3:3) +
  labs(x = "Years from financing-compression event",
       y = "Mean log-stock change", colour = NULL, fill = NULL,
       title = "B. Capital accumulation around independently dated events",
       subtitle = "Four-event mean with 95% normal bands") +
  theme_minimal(base_size = 9) +
  theme(legend.position = "top", panel.grid.minor = element_blank())

p_combined <- p_pressure / p_event + plot_layout(heights = c(0.8, 1.2))
ggsave(file.path(out, "fig_cl_wbop_event_capital_response.png"), p_combined,
       width = 7.4, height = 6.1, dpi = 240)

# Three central report-facing tables.
integration_table <- gate |>
  transmute(
    window_id, window, years = paste0(start_year, "--", end_year),
    n = end_year - start_year + 1L,
    k_me_order = integration_order_k_me,
    k_nr_order = integration_order_k_nr,
    capital_model = ifelse(standard_cointegration_eligible,
                           "Eligible", "Blocked"),
    reason
  )

model_table <- gate |>
  transmute(
    window_id, window, years = paste0(start_year, "--", end_year),
    n = end_year - start_year + 1L,
    im_ols = ifelse(standard_cointegration_eligible,
                    "See coefficient ledger", "Blocked"),
    fm_ols = ifelse(standard_cointegration_eligible,
                    "See coefficient ledger", "Blocked"),
    dols = ifelse(standard_cointegration_eligible,
                  "See coefficient ledger", "Blocked"),
    johansen = ifelse(standard_cointegration_eligible,
                      "See rank ledger", "Blocked"),
    promoted_beta_me = NA_real_,
    unit_vector_restriction = "Not tested: capital gate failed"
  )

full_break <- breaks |>
  filter(window_id == "FULL", variable == "k_nr_on_k_me")
break_wbop_table <- tibble(
  evidence = c("Bai-Perron capital relation",
               "LOESS second-derivative inflections",
               "WBOP five-point financing compression"),
  dates = c(full_break$bai_perron_break_years,
            paste(inflections$inflection_year, collapse = ";"),
            paste(events$event_year, collapse = ";")),
  empirical_role = c(
    "Endogenous parameter-instability dates",
    "Diagnostic changes in composition curvature",
    "Outcome-independent annual external-pressure events"
  ),
  disposition = c(
    "Break evidence; no automatic step controls",
    "Periodization diagnostic only",
    "Impulse/event evidence; never a permanent regime"
  )
)

short_sample_bootstrap <- gate |>
  mutate(n = end_year - start_year + 1L) |>
  filter(n <= 30L) |>
  transmute(
    window_id, window, n, required_replications = 999L,
    model_eligible = standard_cointegration_eligible,
    bootstrap_status = ifelse(
      model_eligible,
      "Required and executed in S30",
      "Not applicable: integration gate blocked estimation"
    )
  )

specification_map <- bind_rows(
  capital_models |>
    transmute(specification_id, family = "capital_composition",
              window_id, candidate = "none", estimator, role,
              disposition, reason, data_sha256),
  wbop_models |>
    transmute(specification_id, family = "wbop_extension",
              window_id, candidate, estimator = intended_role,
              role = intended_role, disposition, reason, data_sha256)
)

write.csv(event_panel, file.path(out, "event_window_episode_panel.csv"),
          row.names = FALSE, na = "")
write.csv(event_summary, file.path(out, "event_window_summary.csv"),
          row.names = FALSE, na = "")
write.csv(episode_effect, file.path(out, "episode_post_event_effects.csv"),
          row.names = FALSE, na = "")
write.csv(event_bootstrap, file.path(out, "event_sample_bootstrap_999.csv"),
          row.names = FALSE, na = "")
write.csv(threshold_ledger, file.path(out, "event_threshold_sensitivity.csv"),
          row.names = FALSE, na = "")
write.csv(loo, file.path(out, "leave_one_event_out.csv"),
          row.names = FALSE, na = "")
write.csv(integration_table, file.path(out, "table1_integration_gate.csv"),
          row.names = FALSE, na = "")
write.csv(model_table, file.path(out, "table2_model_results_disposition.csv"),
          row.names = FALSE, na = "")
write.csv(break_wbop_table, file.path(out, "table3_break_wbop_audit.csv"),
          row.names = FALSE, na = "")
write.csv(short_sample_bootstrap,
          file.path(out, "short_sample_bootstrap_requirement_ledger.csv"),
          row.names = FALSE, na = "")
write.csv(specification_map,
          file.path(out, "complete_specification_space_map.csv"),
          row.names = FALSE, na = "")

message("CL S90 complete: report-facing tables, event robustness, and final map written.")
