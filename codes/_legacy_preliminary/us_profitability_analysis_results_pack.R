###############################################################################
# US — Profitability results pack
# Reads analytical_bundle_us.rds and exports tables / figures / results_pkg_us
###############################################################################

# ── 0. Packages ──────────────────────────────────────────────────────────────
pkgs <- c("dplyr", "readr", "tibble", "ggplot2", "tidyr", "knitr")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}
invisible(lapply(pkgs, library, character.only = TRUE))

# ── 1. Paths ─────────────────────────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_root <- file.path(proj_root, "output", "profitability_us")
fig_dir  <- file.path(out_root, "figs")
csv_dir  <- file.path(out_root, "csv")
tex_dir  <- file.path(out_root, "tex")
rds_dir  <- file.path(out_root, "rds")

dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(tex_dir, recursive = TRUE, showWarnings = FALSE)

# ── 2. Load analytical core ──────────────────────────────────────────────────
bundle <- readRDS(file.path(rds_dir, "analytical_bundle_us.rds"))

d <- bundle$d
tp_all_final <- bundle$tp_all_final
tp_env_final <- bundle$tp_env_final
swing_tbl_paper <- bundle$swing_tbl_paper
swing_tbl_decomp <- bundle$swing_tbl_decomp
swing_tbl_full <- bundle$swing_tbl_full
year_tbl_recap <- bundle$year_tbl_recap
swing_tbl_recap <- bundle$swing_tbl_recap
swing_tbl_recap_full <- bundle$swing_tbl_recap_full
swing_tbl_compact <- bundle$swing_tbl_compact
accounting_wedge_summary <- bundle$accounting_wedge_summary
year_tbl_dys <- bundle$year_tbl_dys
year_tbl_compact <- bundle$year_tbl_compact
tpw_all_final <- bundle$tpw_all_final
tpw_env_final <- bundle$tpw_env_final
swing_tbl_class <- bundle$swing_tbl_class
swing_tbl_class_compact <- bundle$swing_tbl_class_compact
overlap_tbl <- bundle$overlap_tbl

# ── 2.b. Rebuild HP-trend wage-share object needed for fig03 ────────────────
if (!"ln_omega_hp_trend" %in% names(d)) {
  if (!requireNamespace("mFilter", quietly = TRUE)) {
    install.packages("mFilter", repos = "https://cloud.r-project.org")
  }
  library(mFilter)
  
  hp_omega <- mFilter::hpfilter(
    log(d$omega_t),
    freq = 6.25,
    type = "lambda"
  )
  
  d <- d |>
    dplyr::mutate(
      ln_omega_hp_trend = hp_omega$trend,
      omega_hp_trend = exp(ln_omega_hp_trend)
    )
}

# ── 3. Helpers ───────────────────────────────────────────────────────────────
save_plot_dual <- function(plot_obj, filename_stub, fig_dir,
                           width = 8, height = 4.5, dpi = 320) {
  ggsave(
    filename = file.path(fig_dir, paste0(filename_stub, ".png")),
    plot = plot_obj,
    width = width,
    height = height,
    dpi = dpi
  )
  ggsave(
    filename = file.path(fig_dir, paste0(filename_stub, ".pdf")),
    plot = plot_obj,
    width = width,
    height = height,
    device = "pdf"
  )
}

save_table_dual <- function(df, filename_stub, csv_dir, tex_dir,
                            digits = NULL, longtable = FALSE) {
  out_df <- df
  if (!is.null(digits)) {
    num_cols <- vapply(out_df, is.numeric, logical(1))
    out_df[num_cols] <- lapply(out_df[num_cols], round, digits = digits)
  }
  
  readr::write_csv(out_df, file.path(csv_dir, paste0(filename_stub, ".csv")))
  
  tex_str <- knitr::kable(
    out_df,
    format = "latex",
    booktabs = TRUE,
    longtable = longtable,
    linesep = "",
    escape = FALSE,
    na = ""
  )
  writeLines(tex_str, file.path(tex_dir, paste0(filename_stub, ".tex")))
}

zscore <- function(x) {
  (x - mean(x, na.rm = TRUE)) / stats::sd(x, na.rm = TRUE)
}

theme_results_min <- function() {
  theme_minimal(base_size = 11) +
    theme(
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      axis.title.x = element_blank(),
      legend.title = element_blank(),
      legend.position = "bottom",
      legend.key = element_blank()
    )
}

# ── 4. Canonical results package object ──────────────────────────────────────
results_pkg_us <- swing_tbl_recap_full |>
  dplyr::filter(!(duration_years < 3 & abs(amplitude_pct_diag) < 5)) |>
  dplyr::select(
    swing_id,
    start_year,
    end_year,
    direction,
    duration_years,
    amplitude_pct_diag,
    pace_pct_diag_per_year,
    amplitude_log_struct,
    dist_share_pct,
    util_share_pct,
    price_share_pct,
    capacity_share_pct,
    wedge_share_pct,
    share_sum_pct,
    gross_reinforcing_pct,
    gross_offsetting_pct,
    net_imbalance_idx,
    compensation_intensity,
    reinforcing_concentration,
    reversal_risk_raw,
    momentum_contradiction,
    avg_r_diag,
    avg_g_K,
    avg_gross_recap_ratio,
    delta_gross_recap_ratio,
    avg_net_recap_ratio,
    delta_net_recap_ratio,
    reinforcing_main_component,
    offsetting_main_component
  )

saveRDS(results_pkg_us, file.path(rds_dir, "results_pkg_us.rds"))

# ── 5. Tables ────────────────────────────────────────────────────────────────
save_table_dual(swing_tbl_paper,      "tbl01_profit_swings",              csv_dir, tex_dir, digits = 3)
save_table_dual(swing_tbl_decomp,     "tbl02_profit_decomposition",       csv_dir, tex_dir, digits = 3)
save_table_dual(swing_tbl_full,       "tbl03_profit_dysfunction",         csv_dir, tex_dir, digits = 3)
save_table_dual(swing_tbl_class,      "tbl04_class_swings",               csv_dir, tex_dir, digits = 3)
save_table_dual(overlap_tbl,          "tbl05_overlap_windows",            csv_dir, tex_dir, digits = 0)
save_table_dual(year_tbl_dys,         "tbl06_year_dysfunction_full",      csv_dir, tex_dir, digits = 3, longtable = TRUE)
save_table_dual(year_tbl_compact,     "tbl07_year_dysfunction_compact",   csv_dir, tex_dir, digits = 3, longtable = TRUE)
save_table_dual(year_tbl_recap,       "tbl08_year_recapitalization",      csv_dir, tex_dir, digits = 3, longtable = TRUE)
save_table_dual(swing_tbl_recap,      "tbl09_swing_recapitalization",     csv_dir, tex_dir, digits = 3)
save_table_dual(results_pkg_us,       "tbl10_results_pkg_us",             csv_dir, tex_dir, digits = 3)
save_table_dual(accounting_wedge_summary, "tbl11_accounting_wedge_summary", csv_dir, tex_dir, digits = 3)

# ── 6. Figures ───────────────────────────────────────────────────────────────
tp_all_plot <- tp_all_final |> dplyr::filter(type %in% c("peak", "trough"))
tp_env_plot <- tp_env_final |> dplyr::filter(type %in% c("peak", "trough"))

rng_r <- range(d$r_diag_t, na.rm = TRUE)
rng_d <- range(d$dln_r_diag_ma3, na.rm = TRUE)
a <- diff(rng_r) / diff(rng_d)
b <- rng_r[1] - a * rng_d[1]

p_fig01 <- ggplot() +
  geom_line(data = d, aes(x = year, y = r_diag_t), linewidth = 0.9) +
  geom_line(data = d, aes(x = year, y = a * dln_r_diag_ma3 + b), linetype = "dashed", linewidth = 0.7) +
  geom_hline(yintercept = b, linetype = "dotted", linewidth = 0.3) +
  geom_point(data = tp_all_plot, aes(x = year, y = exp(value), shape = type), size = 2.0, alpha = 0.7) +
  geom_point(data = tp_env_plot, aes(x = year, y = exp(value)), shape = 21, size = 3.5, stroke = 1.0, fill = NA) +
  scale_shape_manual(values = c(peak = 24, trough = 25)) +
  scale_y_continuous(
    name = "profit rate: GOS / KNC",
    sec.axis = sec_axis(trans = ~ (. - b) / a, name = "smoothed Δ log profit")
  ) +
  scale_x_continuous(breaks = seq(1940, 1978, by = 4)) +
  theme_results_min()

save_plot_dual(p_fig01, "fig01_profit_turning_points", fig_dir, width = 8.8, height = 4.8)

decomp_long <- swing_tbl_recap_full |>
  dplyr::transmute(
    swing = paste0(start_year, "-", end_year),
    distribution = dist_share_pct,
    utilization = util_share_pct,
    price = price_share_pct,
    capacity = capacity_share_pct,
    wedge = wedge_share_pct
  ) |>
  tidyr::pivot_longer(-swing, names_to = "component", values_to = "share_pct") |>
  dplyr::mutate(
    component = factor(component, levels = c("distribution", "utilization", "price", "capacity", "wedge")),
    swing = factor(swing, levels = paste0(swing_tbl_recap_full$start_year, "-", swing_tbl_recap_full$end_year))
  )

p_fig02 <- ggplot(decomp_long, aes(x = swing, y = share_pct, fill = component)) +
  geom_col(position = "stack", width = 0.72) +
  geom_hline(yintercept = 0, linetype = "dashed", linewidth = 0.3) +
  labs(y = "share of structural swing (%)") +
  theme_results_min() +
  theme(legend.position = "bottom")

save_plot_dual(p_fig02, "fig02_profit_swing_decomposition", fig_dir, width = 8.6, height = 4.8)

d_plot <- d |>
  dplyr::transmute(
    year,
    z_profit = zscore(ln_r_diag_t),
    z_class_filtered = zscore(ln_omega_T_t),
    z_wage_raw = zscore(log(omega_t)),
    z_wage_hp = zscore(ln_omega_hp_trend)
  )

tp_profit_plot <- tp_env_final |>
  dplyr::filter(type %in% c("peak", "trough")) |>
  dplyr::transmute(year, value = zscore(d$ln_r_diag_t)[idx], type)

tp_class_plot <- tpw_env_final |>
  dplyr::filter(type %in% c("peak", "trough")) |>
  dplyr::transmute(year, value = zscore(d$ln_omega_T_t)[idx])

p_fig03 <- ggplot(d_plot, aes(x = year)) +
  geom_line(aes(y = z_profit, color = "profit"), linewidth = 0.95) +
  geom_line(aes(y = z_class_filtered, color = "filtered wage share"), linewidth = 0.9, linetype = "dashed") +
  geom_line(aes(y = z_wage_raw, color = "raw wage share"), linewidth = 0.65, linetype = "dotted", alpha = 0.7) +
  geom_line(aes(y = z_wage_hp, color = "HP trend"), linewidth = 0.7, linetype = "dotdash", alpha = 0.7) +
  geom_point(data = tp_profit_plot, aes(x = year, y = value, shape = type), inherit.aes = FALSE, size = 2.2, color = "black") +
  geom_point(data = tp_class_plot, aes(x = year, y = value), inherit.aes = FALSE, shape = 21, size = 2.5, stroke = 0.9, fill = NA, color = "black") +
  scale_shape_manual(values = c(peak = 24, trough = 25)) +
  scale_color_manual(values = c("profit" = "black", "filtered wage share" = "#D55E00", "raw wage share" = "black", "HP trend" = "#7A7A7A")) +
  scale_x_continuous(breaks = seq(1940, 1978, by = 4)) +
  labs(y = "standardized log series") +
  theme_results_min()

save_plot_dual(p_fig03, "fig03_profit_filtered_raw_hp", fig_dir, width = 9.2, height = 4.8)

overlap_windows <- overlap_tbl |>
  dplyr::distinct(overlap_start, overlap_end) |>
  dplyr::arrange(overlap_start, overlap_end) |>
  dplyr::mutate(xmin = overlap_start - 0.5, xmax = overlap_end + 0.5)

p_fig04 <- ggplot() +
  geom_rect(data = overlap_windows, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf), inherit.aes = FALSE, fill = "grey70", alpha = 0.18) +
  geom_line(data = d_plot, aes(x = year, y = z_profit, color = "profit"), linewidth = 0.95) +
  geom_line(data = d_plot, aes(x = year, y = z_class_filtered, color = "filtered wage share"), linewidth = 0.9, linetype = "dashed") +
  geom_point(data = tp_profit_plot, aes(x = year, y = value, shape = type), inherit.aes = FALSE, size = 2.2, color = "black") +
  geom_point(data = tp_class_plot, aes(x = year, y = value), inherit.aes = FALSE, shape = 21, size = 2.5, stroke = 0.9, fill = NA, color = "black") +
  scale_shape_manual(values = c(peak = 24, trough = 25)) +
  scale_color_manual(values = c("profit" = "black", "filtered wage share" = "#D55E00")) +
  scale_x_continuous(breaks = seq(1940, 1978, by = 4)) +
  labs(y = "standardized log series") +
  theme_results_min()

save_plot_dual(p_fig04, "fig04_intersecting_temporalities_overlap", fig_dir, width = 9.2, height = 4.8)

dys_long <- swing_tbl_recap_full |>
  dplyr::transmute(
    swing = factor(paste0(start_year, "-", end_year), levels = paste0(start_year, "-", end_year)),
    `gross offsetting (%)` = gross_offsetting_pct,
    `net imbalance` = net_imbalance_idx,
    `compensation intensity` = compensation_intensity,
    `reversal risk` = reversal_risk_raw
  ) |>
  tidyr::pivot_longer(-swing, names_to = "metric", values_to = "value")

p_fig05 <- ggplot(dys_long, aes(x = swing, y = value, group = metric)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2.0) +
  facet_wrap(~ metric, scales = "free_y", ncol = 1) +
  labs(y = NULL) +
  theme_results_min() +
  theme(legend.position = "none", strip.background = element_blank())

save_plot_dual(p_fig05, "fig05_dysfunctionality_swings", fig_dir, width = 8.2, height = 8.6)

p_fig06 <- ggplot(year_tbl_recap, aes(x = year)) +
  geom_line(aes(y = zscore(r_diag_t), color = "accounting profit rate"), linewidth = 0.9) +
  geom_line(aes(y = zscore(gross_recap_ratio_t), color = "gross recap ratio"), linewidth = 0.8, linetype = "dashed") +
  geom_line(aes(y = zscore(net_recap_ratio_t), color = "net recap ratio"), linewidth = 0.8, linetype = "dotdash") +
  scale_color_manual(values = c("accounting profit rate" = "black", "gross recap ratio" = "#4D4D4D", "net recap ratio" = "#D55E00")) +
  scale_x_continuous(breaks = seq(1940, 1978, by = 4)) +
  labs(y = "standardized series") +
  theme_results_min()

save_plot_dual(p_fig06, "fig06_profit_recapitalization", fig_dir, width = 9.0, height = 4.8)

recap_long <- swing_tbl_recap_full |>
  dplyr::filter(!(duration_years < 3 & abs(amplitude_pct_diag) < 5)) |>
  dplyr::mutate(swing = factor(paste0(start_year, "-", end_year), levels = paste0(start_year, "-", end_year))) |>
  dplyr::transmute(
    swing,
    `avg accounting profit` = avg_r_diag,
    `avg capital growth` = avg_g_K,
    `avg gross recap ratio` = avg_gross_recap_ratio,
    `avg net recap ratio` = avg_net_recap_ratio
  ) |>
  tidyr::pivot_longer(-swing, names_to = "metric", values_to = "value")

p_fig07 <- ggplot(recap_long, aes(x = swing, y = value, group = metric)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 2.0) +
  facet_wrap(~ metric, scales = "free_y", ncol = 1) +
  labs(y = NULL) +
  theme_results_min() +
  theme(legend.position = "none", strip.background = element_blank())

save_plot_dual(p_fig07, "fig07_swing_recapitalization_profile", fig_dir, width = 8.2, height = 8.4)

p_fig08 <- ggplot(
  swing_tbl_recap_full |> dplyr::filter(!(duration_years < 3 & abs(amplitude_pct_diag) < 5)),
  aes(x = reversal_risk_raw, y = avg_gross_recap_ratio)
) +
  geom_point(size = 3) +
  geom_text(aes(label = paste0(start_year, "-", end_year)), nudge_y = 0.01, size = 3) +
  labs(x = "reversal risk", y = "average gross recap ratio") +
  theme_results_min()

save_plot_dual(p_fig08, "fig08_grossrecap_vs_reversalrisk", fig_dir, width = 8.0, height = 4.8)

wedge_plot_tbl <- d |>
  dplyr::transmute(year, accounting_wedge_t)

p_fig09 <- ggplot(wedge_plot_tbl, aes(x = year, y = accounting_wedge_t)) +
  geom_line(linewidth = 0.8) +
  scale_x_continuous(breaks = seq(1940, 1978, by = 4)) +
  labs(y = "accounting wedge") +
  theme_results_min()

save_plot_dual(p_fig09, "fig09_accounting_wedge_timeseries", fig_dir, width = 8.4, height = 4.2)

cat("\nResults package saved to:\n")
cat("  figs: ", fig_dir, "\n", sep = "")
cat("  csv : ", csv_dir, "\n", sep = "")
cat("  tex : ", tex_dir, "\n", sep = "")
cat("  rds : ", rds_dir, "\n", sep = "")