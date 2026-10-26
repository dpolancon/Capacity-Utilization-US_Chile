#!/usr/bin/env Rscript

# CL_S60_capacity_utilization_plots.R
# Generates the publication-ready visualization suite for Chile Capacity Utilization:
#   Figure 1: Dual-axis plot of Capacity Utilization (mu_t, LHS, Black) vs Transformation Elasticity (theta_t^Agg, RHS, Red)
#   Figure 1B: Standalone plot of Transformation Elasticity (theta_t^Agg, Single Axis, Uncompressed)
#   Figure 2: Dual-axis plot of Composite Threshold (Z_t, LHS, Black) vs Gross Wage Share (omega_t-1^gross, RHS, Dark Green Dashed)
#   Figure 3: Components of Z_t (Solvency Ratio S_tilde Purple Twodash, Import Imbalance M_tilde Red Dotted & Thick 1.3, and Composite Z_t Black Solid 1.3)
#
# Formatting Rules:
#   - No graph titles or subtitles.
#   - Periodization text size: 4.0 bold.italic.
#   - Background shading: Binding (Z_t <= 0.425) in Light Gray, Slack unshaded (white).
#   - LHS Y-Axis ticks, labels, and titles: Black.
#   - RHS Y-Axis ticks, labels, and titles: Red (Fig 1), Dark Green (Fig 2).
#   - Strip out background fill legends (guides(fill = "none")).
#   - Line legends stay at bottom.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(repo_root)

csv_path <- file.path(repo_root, "output/chile_capacity_utilization_series.csv")
if (!file.exists(csv_path)) {
  stop("Capacity utilization series CSV not found at: ", csv_path)
}

df <- read_csv(csv_path, show_col_types = FALSE)
opt_gamma <- 0.425

out_dir <- file.path(repo_root, "output")
dir.create(out_dir, showWarnings = FALSE)

cat("========================================================================\n")
cat("CL_S60 Plots: Generating Chile Visualizations (Including Standalone Theta)\n")
cat("========================================================================\n")

# 1. Define Institutional Breakpoints and Annotations (Ahumada 2019 / Ffrench-Davis)
inst_breaks <- data.frame(
  year = c(1947, 1964, 1970, 1973, 1975, 1982, 1990, 1998),
  label = c("Classical ISI", "Frei Reforms", "UP", "Coup", "Shock Therapy", "Debt Crisis", "Democracy", "Asian Crisis"),
  y_pos_factor = c(0.96, 0.88, 0.96, 0.80, 0.88, 0.96, 0.88, 0.80)
)

# 2. Build Continuous Rectangles for Econometric Regime Shading
# Inverted: Binding is Light Gray, Slack is White (unshaded)
df <- df %>% arrange(year)
runs <- rle(df$D_gamma)
end_indices <- cumsum(runs$lengths)
start_indices <- c(1, head(end_indices, -1) + 1)

shading_df <- data.frame(
  xmin = df$year[start_indices] - 0.5,
  xmax = df$year[end_indices] + 0.5,
  D_gamma = runs$values,
  regime = ifelse(runs$values == 1, "Binding", "Slack")
)

col_binding_bg <- "#D9D9D9" # Light gray
col_slack_bg   <- "#FFFFFF" # White / unshaded

# Base theme generator
theme_paper_custom <- function(rhs_color = "firebrick3") {
  theme_minimal(base_size = 11) +
    theme(
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray88", linewidth = 0.4),
      legend.position = "bottom",
      legend.title = element_text(face = "bold", size = 10.5),
      legend.text = element_text(size = 10),
      
      axis.line = element_line(color = "black", linewidth = 0.6),
      axis.line.y.right = element_line(color = rhs_color, linewidth = 0.6),
      
      # Axis Styling: LHS Black, RHS Custom (Red or Dark Green)
      axis.title.x = element_text(face = "bold", color = "black", margin = margin(t = 8), size = 11),
      axis.text.x  = element_text(color = "black", size = 10),
      axis.ticks.x = element_line(color = "black"),
      
      axis.title.y.left = element_text(face = "bold", color = "black", margin = margin(r = 8), size = 11),
      axis.text.y.left  = element_text(color = "black", size = 10),
      axis.ticks.y.left = element_line(color = "black"),
      
      axis.title.y.right = element_text(face = "bold", color = rhs_color, margin = margin(l = 8), size = 11),
      axis.text.y.right  = element_text(color = rhs_color, size = 10, face = "bold"),
      axis.ticks.y.right = element_line(color = rhs_color)
    )
}

# Directories for multi-layer exports
fig_dir   <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
fig_vault <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "figures")
out_dir   <- file.path(repo_root, "output")

for (d in c(fig_dir, fig_vault, out_dir)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

# ==============================================================================
# FIGURE 1: Dual-Axis mu_t (LHS, Black) vs theta_t^Agg (RHS, Red)
# ==============================================================================
a_fig1 <- (1.45 - 0.50) / 1.20
b_fig1 <- 0.50

p1 <- ggplot(df) +
  # Background Shading: Binding is Light Gray, Slack is White
  geom_rect(data = shading_df, aes(xmin = xmin, xmax = xmax, ymin = 0.50, ymax = 1.45, fill = regime),
            alpha = 0.5, inherit.aes = FALSE) +
  scale_fill_manual(values = c("Binding" = col_binding_bg, "Slack" = col_slack_bg)) +
  guides(fill = "none") +
  
  # Institutional Breakpoint Lines
  geom_vline(data = inst_breaks, aes(xintercept = year), linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_text(data = inst_breaks, aes(x = year, y = b_fig1 + a_fig1 * 1.20 * y_pos_factor, label = label),
            angle = 90, vjust = -0.35, hjust = 1, size = 4.2, fontface = "bold.italic", color = "gray15") +
  
  # Reference Lines
  geom_hline(yintercept = 1.00, linetype = "solid", color = "black", linewidth = 0.7) +
  geom_vline(xintercept = 1981, linetype = "dotdash", color = "black", linewidth = 0.8) +
  annotate("text", x = 1981.5, y = 1.03, label = "1981 Pinch Year (mu = 1.0)", color = "black", size = 3.6, hjust = 0, fontface = "bold") +
  
  # Primary Series: Capacity Utilization (mu_t, LHS - Black)
  geom_line(aes(x = year, y = mu_t, color = "Capacity Utilization (mu_t)"), linewidth = 1.1) +
  
  # Secondary Series: Transformation Elasticity (theta_t^Agg, RHS - Red)
  geom_line(aes(x = year, y = b_fig1 + a_fig1 * theta_t_agg, color = "Transformation Elasticity (theta_t^Agg)"), linewidth = 1.1) +
  
  scale_x_continuous(breaks = seq(1945, 2010, by = 5), limits = c(1941.5, 2010.5)) +
  scale_y_continuous(
    name = "Capacity Utilization (mu_t)",
    limits = c(0.50, 1.45),
    breaks = seq(0.50, 1.40, by = 0.10),
    sec.axis = sec_axis(~ (. - b_fig1) / a_fig1, name = "Transformation Elasticity (theta_t^Agg)", breaks = seq(0.00, 1.20, by = 0.20))
  ) +
  scale_color_manual(
    name = NULL,
    values = c(
      "Capacity Utilization (mu_t)" = "black",
      "Transformation Elasticity (theta_t^Agg)" = "firebrick3"
    )
  ) +
  theme_paper_custom(rhs_color = "firebrick3")

for (d in c(fig_dir, fig_vault, out_dir)) {
  ggsave(file.path(d, "fig_cl_results_dual_theta_mu.pdf"), p1, width = 11, height = 6.5, device = cairo_pdf)
  ggsave(file.path(d, "fig_cl_results_dual_theta_mu.png"), p1, width = 11, height = 6.5, dpi = 300)
}
cat("Saved Figure 1 as fig_cl_results_dual_theta_mu.pdf\n")


# ==============================================================================
# FIGURE 1B: Standalone Transformation Elasticity (theta_t^Agg, Uncompressed)
# ==============================================================================
p1b <- ggplot(df) +
  # Background Shading: Binding is Light Gray, Slack is White
  geom_rect(data = shading_df, aes(xmin = xmin, xmax = xmax, ymin = 0.68, ymax = 0.95, fill = regime),
            alpha = 0.5, inherit.aes = FALSE) +
  scale_fill_manual(values = c("Binding" = col_binding_bg, "Slack" = col_slack_bg)) +
  guides(fill = "none") +
  
  # Institutional Breakpoint Lines
  geom_vline(data = inst_breaks, aes(xintercept = year), linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_text(data = inst_breaks, aes(x = year, y = 0.68 + 0.27 * y_pos_factor, label = label),
            angle = 90, vjust = -0.35, hjust = 1, size = 4.2, fontface = "bold.italic", color = "gray15") +
  
  # Reference Lines
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "gray30", linewidth = 0.7) +
  annotate("text", x = 1943, y = 0.94, label = "Harrodian Benchmark (theta = 1.0)", color = "gray25", size = 3.5, fontface = "bold.italic", hjust = 0) +
  
  # Standalone Series: Transformation Elasticity (theta_t^Agg, Black Solid 1.1)
  geom_line(aes(x = year, y = theta_t_agg, color = "Transformation Elasticity (theta_t^Agg)"), linewidth = 1.1) +
  
  scale_x_continuous(breaks = seq(1945, 2010, by = 5), limits = c(1941.5, 2010.5)) +
  scale_y_continuous(
    name = "Transformation Elasticity (theta_t^Agg)",
    limits = c(0.68, 0.95),
    breaks = seq(0.70, 0.95, by = 0.05)
  ) +
  scale_color_manual(
    name = NULL,
    values = c("Transformation Elasticity (theta_t^Agg)" = "black")
  ) +
  theme_paper_custom(rhs_color = "black") +
  theme(
    axis.title.y.right = element_blank(),
    axis.text.y.right  = element_blank(),
    axis.ticks.y.right = element_blank()
  )

for (d in c(fig_dir, fig_vault, out_dir)) {
  ggsave(file.path(d, "fig_cl_results_theta_standalone.pdf"), p1b, width = 11, height = 6.5, device = cairo_pdf)
  ggsave(file.path(d, "fig_cl_results_theta_standalone.png"), p1b, width = 11, height = 6.5, dpi = 300)
}
cat("Saved Figure 1B as fig_cl_results_theta_standalone.pdf\n")


# ==============================================================================
# FIGURE 2: Dual-Axis Z_t (LHS, Black) vs omega_t-1^gross (RHS, Dark Green Dashed)
# ==============================================================================
a_fig2 <- 12.5
b_fig2 <- -2.50
col_dark_green <- "#2E7D32" # Vivid dark green for RHS axis and series

p2 <- ggplot(df) +
  # Background Shading: Binding is Light Gray, Slack is White
  geom_rect(data = shading_df, aes(xmin = xmin, xmax = xmax, ymin = -2.50, ymax = 2.50, fill = regime),
            alpha = 0.5, inherit.aes = FALSE) +
  scale_fill_manual(values = c("Binding" = col_binding_bg, "Slack" = col_slack_bg)) +
  guides(fill = "none") +
  
  # Institutional Breakpoint Lines
  geom_vline(data = inst_breaks, aes(xintercept = year), linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_text(data = inst_breaks, aes(x = year, y = -2.50 + 5.0 * y_pos_factor, label = label),
            angle = 90, vjust = -0.35, hjust = 1, size = 4.2, fontface = "bold.italic", color = "gray15") +
  
  # Threshold Reference Line
  geom_hline(yintercept = opt_gamma, linetype = "dashed", color = "black", linewidth = 0.8) +
  annotate("text", x = 1943, y = opt_gamma + 0.18, label = sprintf("Threshold gamma = %.3f", opt_gamma), color = "black", size = 3.8, fontface = "bold", hjust = 0) +
  
  # Primary Series: Composite Threshold Z_t (LHS - Black Solid)
  geom_line(aes(x = year, y = Z_t, color = "Composite Threshold (Z_t)", linetype = "Composite Threshold (Z_t)"), linewidth = 1.1) +
  
  # Secondary Series: Lagged Gross Wage Share (omega_t-1^gross, RHS - Dark Green Dashed)
  geom_line(aes(x = year, y = b_fig2 + a_fig2 * (omega_gross_lag - 0.30), color = "Gross Wage Share (omega_t-1^gross)", linetype = "Gross Wage Share (omega_t-1^gross)"), linewidth = 1.1) +
  
  scale_x_continuous(breaks = seq(1945, 2010, by = 5), limits = c(1941.5, 2010.5)) +
  scale_y_continuous(
    name = "Composite Solvency & BoP Index (Z_t)",
    limits = c(-2.50, 2.50),
    breaks = seq(-2.50, 2.50, by = 0.50),
    sec.axis = sec_axis(~ 0.30 + (. - b_fig2) / a_fig2, name = "Gross Wage Share (omega_t-1^gross)", breaks = seq(0.30, 0.70, by = 0.05))
  ) +
  scale_color_manual(
    name = NULL,
    values = c(
      "Composite Threshold (Z_t)" = "black",
      "Gross Wage Share (omega_t-1^gross)" = col_dark_green
    )
  ) +
  scale_linetype_manual(
    name = NULL,
    values = c(
      "Composite Threshold (Z_t)" = "solid",
      "Gross Wage Share (omega_t-1^gross)" = "dashed"
    )
  ) +
  theme_paper_custom(rhs_color = col_dark_green)

for (d in c(fig_dir, fig_vault, out_dir)) {
  ggsave(file.path(d, "fig_cl_results_z_omega_drivers.pdf"), p2, width = 11, height = 6.5, device = cairo_pdf)
  ggsave(file.path(d, "fig_cl_results_z_omega_drivers.png"), p2, width = 11, height = 6.5, dpi = 300)
}
cat("Saved Figure 2 as fig_cl_results_z_omega_drivers.pdf\n")


# ==============================================================================
# FIGURE 3: Components of Z_t (S_tilde, M_tilde Red Dotted, Z_t Black Solid)
# ==============================================================================
p3 <- ggplot(df) +
  # Background Shading: Binding is Light Gray, Slack is White
  geom_rect(data = shading_df, aes(xmin = xmin, xmax = xmax, ymin = -3.0, ymax = 3.0, fill = regime),
            alpha = 0.5, inherit.aes = FALSE) +
  scale_fill_manual(values = c("Binding" = col_binding_bg, "Slack" = col_slack_bg)) +
  guides(fill = "none") +
  
  # Institutional Breakpoint Lines
  geom_vline(data = inst_breaks, aes(xintercept = year), linetype = "dashed", color = "gray40", linewidth = 0.5) +
  geom_text(data = inst_breaks, aes(x = year, y = -3.0 + 6.0 * y_pos_factor, label = label),
            angle = 90, vjust = -0.35, hjust = 1, size = 4.2, fontface = "bold.italic", color = "gray15") +
  
  # Threshold Reference Line
  geom_hline(yintercept = opt_gamma, linetype = "dashed", color = "black", linewidth = 0.8) +
  annotate("text", x = 1943, y = opt_gamma + 0.18, label = sprintf("Threshold gamma = %.3f", opt_gamma), color = "black", size = 3.8, fontface = "bold", hjust = 0) +
  
  # Three Line Components (Linewidth = 1.1)
  # Solvency Ratio: Purple3, twodash, 1.1
  geom_line(aes(x = year, y = S_tilde, color = "Solvency Ratio (S_tilde: Reserves / M0)", linetype = "Solvency Ratio (S_tilde: Reserves / M0)"), linewidth = 1.1) +
  # Import Imbalance: Firebrick3 (Red), dotted, 1.1
  geom_line(aes(x = year, y = M_tilde, color = "Import Demand Imbalance (M_tilde: WBOP)", linetype = "Import Demand Imbalance (M_tilde: WBOP)"), linewidth = 1.1) +
  # Composite Index: Black, solid, 1.1
  geom_line(aes(x = year, y = Z_t, color = "Composite Index (Z_t = 0.2 M_tilde + 0.8 S_tilde)", linetype = "Composite Index (Z_t = 0.2 M_tilde + 0.8 S_tilde)"), linewidth = 1.1) +
  
  scale_x_continuous(breaks = seq(1945, 2010, by = 5), limits = c(1941.5, 2010.5)) +
  scale_y_continuous(
    name = "Standardized Index Level (Zero Mean, Unit Variance)",
    limits = c(-3.0, 3.0),
    breaks = seq(-3.0, 3.0, by = 0.50)
  ) +
  scale_color_manual(
    name = NULL,
    values = c(
      "Solvency Ratio (S_tilde: Reserves / M0)" = "purple3",
      "Import Demand Imbalance (M_tilde: WBOP)" = "firebrick3",
      "Composite Index (Z_t = 0.2 M_tilde + 0.8 S_tilde)" = "black"
    )
  ) +
  scale_linetype_manual(
    name = NULL,
    values = c(
      "Solvency Ratio (S_tilde: Reserves / M0)" = "twodash",
      "Import Demand Imbalance (M_tilde: WBOP)" = "dotted",
      "Composite Index (Z_t = 0.2 M_tilde + 0.8 S_tilde)" = "solid"
    )
  ) +
  theme_paper_custom(rhs_color = "black") +
  theme(
    axis.title.y.right = element_blank(),
    axis.text.y.right  = element_blank(),
    axis.ticks.y.right = element_blank(),
    legend.key.width   = unit(1.5, "cm")
  )

for (d in c(fig_dir, fig_vault, out_dir)) {
  ggsave(file.path(d, "fig_cl_results_z_components.pdf"), p3, width = 11, height = 6.5, device = cairo_pdf)
  ggsave(file.path(d, "fig_cl_results_z_components.png"), p3, width = 11, height = 6.5, dpi = 300)
}
cat("Saved Figure 3 as fig_cl_results_z_components.pdf\n")

cat("\n========================================================================\n")
cat("CL_S60 Plots Complete: All 4 figures generated successfully.\n")
cat("========================================================================\n")
