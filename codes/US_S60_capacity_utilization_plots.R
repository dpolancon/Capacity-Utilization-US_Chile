#!/usr/bin/env Rscript

# US_S60_capacity_utilization_plots.R
# Generates figures for the recovered capacity utilization (mu_t) and transformation elasticity (theta_t)
# 1. Capacity Utilization (mu_t) for M2.10 (WD) with a reference line at mu = 1.00.
# 2. Transformation Elasticity (theta_t) plotted with its underlying endogenous variables
#    (Shaikh-Tonak Tier 2 Wage Share and Investment Intensity) on a dual-axis chart.

options(stringsAsFactors = FALSE, scipen = 999)

suppressMessages(library(ggplot2))
suppressMessages(library(dplyr))

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
csv_path  <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY", "csv", "s60_capacity_utilization_series.csv")
fig_dir   <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY", "figures")

dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

if (!file.exists(csv_path)) {
  stop("Recovered series CSV not found at: ", csv_path)
}

df <- read.csv(csv_path)

cat("========================================================================\n")
cat("S60 Plots: Generating Capacity Recovery Visualizations\n")
cat("========================================================================\n")

# Clean 1929 row (which has NAs due to lags) for plotting
df_plot <- df %>% filter(!is.na(theta_m2_10))

# ----------------------------------------------------------------------
# GRAPH 1: Capacity Utilization (mu_t) for M2.10 (WD)
# ----------------------------------------------------------------------
p_mu <- ggplot(df_plot, aes(x = year, y = mu_m2_10)) +
  geom_line(color = "firebrick3", linewidth = 1.2) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "black", linewidth = 0.8) +
  geom_vline(xintercept = 1973, color = "darkred", linetype = "solid", linewidth = 0.5) +
  annotate("text", x = 1973.5, y = 1.25, label = "1973 Pinch Year (mu = 1.0)", color = "darkred", size = 3.5, hjust = 0) +
  scale_x_continuous(limits = c(1929, 2024), breaks = seq(1930, 2020, 10)) +
  scale_y_continuous(limits = c(0.30, 1.50), breaks = seq(0.4, 1.4, 0.2)) +
  labs(
    title = "U.S. Aggregate Capacity Utilization (mu_t)",
    subtitle = "Primary Specification: Model M2.10 (WD) [1973 Anchored]",
    x = "Year", y = "Capacity Utilization (mu_t)"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(face = "italic", size = 10, color = "gray30"),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(fig_dir, "m2_10_capacity_utilization.png"), p_mu, width = 9, height = 5.5, dpi = 150)
cat("Saved: m2_10_capacity_utilization.png\n")


# ----------------------------------------------------------------------
# GRAPH 2: Transformation Elasticity & Endogenous Variables (Dual-Axis)
# ----------------------------------------------------------------------
# Left Axis limits (theta_t): c(0.20, 0.60)
# Right Axis limits (omega and iota): c(0.00, 0.60)
# Mapping: y_left = (2/3) * x_right + 0.20
# Inverse: x_right = 1.5 * (y_left - 0.20)
a <- 2/3
b <- 0.20

p_theta <- ggplot(df_plot, aes(x = year)) +
  # Theta_t on Left Axis (solid blue line)
  geom_line(aes(y = theta_m2_10, color = "Transformation Elasticity (theta_t)"), linewidth = 1.2) +
  
  # Wage Share on Right Axis (dashed red line)
  geom_line(aes(y = a * omega_ST_Tier2_lag1 + b, color = "Shaikh-Tonak Tier 2 Wage Share (omega_t-1)"), 
            linewidth = 1.0, linetype = "dashed") +
  
  # Investment Intensity on Right Axis (dotted green line)
  geom_line(aes(y = a * iota_lag1 + b, color = "IPP Investment Share (iota_t-1)"), 
            linewidth = 1.0, linetype = "dotted") +
  
  # Structural Breakpoints
  geom_vline(xintercept = c(1944, 1967, 1981, 1996, 2010), linetype = "dashed", color = "gray60", linewidth = 0.6) +
  
  scale_x_continuous(limits = c(1929, 2024), breaks = seq(1930, 2020, 10)) +
  scale_y_continuous(
    name = "Transformation Elasticity (theta_t)",
    limits = c(0.20, 0.60),
    breaks = seq(0.20, 0.60, 0.10),
    sec.axis = sec_axis(~ (. - b) / a, name = "Wage Share & Investment Share (omega_t-1, iota_t-1)")
  ) +
  scale_color_manual(
    values = c(
      "Transformation Elasticity (theta_t)" = "royalblue4",
      "Shaikh-Tonak Tier 2 Wage Share (omega_t-1)" = "firebrick",
      "IPP Investment Share (iota_t-1)" = "forestgreen"
    )
  ) +
  labs(
    title = "U.S. Transformation Elasticity & Endogenous Drivers (M2.10 WD)",
    subtitle = "Dual Axis: theta_t (Left) vs. Underlying Distribution & Investment Intensity (Right)",
    x = "Year",
    color = "Variable"
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(face = "italic", size = 10, color = "gray30"),
    axis.title.y.left = element_text(color = "royalblue4", face = "bold"),
    axis.title.y.right = element_text(color = "firebrick4", face = "bold"),
    legend.text = element_text(size = 9),
    panel.grid.minor = element_blank()
  ) +
  guides(color = guide_legend(nrow = 2, byrow = TRUE))

ggsave(file.path(fig_dir, "m2_10_elasticity_and_inputs_dual_axis.png"), p_theta, width = 10, height = 6.0, dpi = 150)
cat("Saved: m2_10_elasticity_and_inputs_dual_axis.png\n")

cat("S60 Plotting complete.\n")
