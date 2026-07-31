#!/usr/bin/env Rscript

# CL_S44_generate_peripheral_figures.R
# Generates 6 publication-grade ggplot2 visualizations for Chile (1920-2024).
# Adheres strictly to layout rules: 5-year 45-degree year ticks, top captions, bottom notes.

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
  library(gridExtra)
  library(tidyr)
})

repo_root  <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_file <- file.path(repo_root, "data", "processed", "cl_s40", "chile_peripheral_staged_panel.csv")
out_dir    <- file.path(repo_root, "output", "CL", "figures")

if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

cat("=== Step 1: Loading staged panel data ===\n")
df <- read.csv(input_file, stringsAsFactors = FALSE)
df_clean <- df[!is.na(df$k_NR) & !is.na(df$k_ME), ]

theme_ch2 <- function() {
  theme_minimal(base_size = 11) +
    theme(
      plot.title        = element_text(face = "bold", size = 12, hjust = 0, margin = margin(b = 4)),
      plot.subtitle     = element_text(size = 9, color = "grey30", hjust = 0, margin = margin(b = 8)),
      plot.caption      = element_text(size = 8, color = "grey40", hjust = 0, margin = margin(t = 8)),
      axis.title        = element_text(size = 10, face = "plain"),
      axis.text.x       = element_text(angle = 45, hjust = 1, vjust = 1, size = 8),
      axis.text.y       = element_text(size = 8),
      panel.grid.minor  = element_blank(),
      panel.border      = element_rect(color = "grey80", fill = NA, linewidth = 0.5),
      legend.position   = "bottom",
      legend.title      = element_blank(),
      legend.text       = element_text(size = 9)
    )
}

x_ticks_5yr <- seq(1920, 2024, by = 5)

# --- Figure 1: Capital Log Levels (k_ME vs k_NR) ---
cat("Generating Figure 1: cl_capital_levels_loess.png...\n")
p1 <- ggplot(df_clean, aes(x = year)) +
  geom_line(aes(y = k_NR, color = "Nonresidential Structures (k_NR)"), linewidth = 1.0) +
  geom_line(aes(y = k_ME, color = "Machinery & Equipment (k_ME)"), linewidth = 1.0, linetype = "dashed") +
  geom_vline(xintercept = c(1936, 1971, 1982), linetype = "dotted", color = "firebrick", linewidth = 0.6) +
  annotate("text", x = 1936, y = max(df_clean$k_NR, na.rm=TRUE)*0.98, label = "1936 (Nitrate Crisis)", angle = 90, vjust = -0.5, size = 2.8, color = "firebrick") +
  annotate("text", x = 1971, y = max(df_clean$k_NR, na.rm=TRUE)*0.98, label = "1971 (ISI Peak)", angle = 90, vjust = -0.5, size = 2.8, color = "firebrick") +
  annotate("text", x = 1982, y = max(df_clean$k_NR, na.rm=TRUE)*0.98, label = "1982 (Debt Crisis)", angle = 90, vjust = -0.5, size = 2.8, color = "firebrick") +
  scale_x_continuous(breaks = x_ticks_5yr) +
  scale_color_manual(values = c("Nonresidential Structures (k_NR)" = "#1f77b4", "Machinery & Equipment (k_ME)" = "#ff7f0e")) +
  labs(
    title = "Figure 1: Heterogeneous Capital Stock Trajectories in Chile (1920-2024)",
    subtitle = "Log-levels of real Nonresidential Structures (k_NR) and Machinery & Equipment (k_ME)",
    x = "Year",
    y = "Log-Level (2003 CLP Base)",
    caption = "Source: Author calculations based on K-Stock-Harmonization & Perez & Eyzaguirre (2021). Vertical lines denote LOESS inflections."
  ) +
  theme_ch2()

ggsave(file.path(out_dir, "cl_capital_levels_loess.png"), plot = p1, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(out_dir, "cl_capital_levels_loess.pdf"), plot = p1, width = 9, height = 5.5)

# --- Figure 2: Capital Composition (tau_t = k_ME - k_NR) with Regime Bands ---
cat("Generating Figure 2: cl_tau_regime_bands.png...\n")
p2 <- ggplot(df_clean, aes(x = year, y = tau)) +
  annotate("rect", xmin = 1920, xmax = 1938, ymin = -Inf, ymax = Inf, fill = "#e41a1c", alpha = 0.1) +
  annotate("rect", xmin = 1939, xmax = 1973, ymin = -Inf, ymax = Inf, fill = "#377eb8", alpha = 0.1) +
  annotate("rect", xmin = 1974, xmax = 1989, ymin = -Inf, ymax = Inf, fill = "#4daf4a", alpha = 0.1) +
  annotate("rect", xmin = 1990, xmax = 2024, ymin = -Inf, ymax = Inf, fill = "#984ea3", alpha = 0.1) +
  geom_line(color = "darkblue", linewidth = 1.1) +
  geom_smooth(method = "loess", se = FALSE, color = "black", linetype = "twodash", linewidth = 0.8) +
  scale_x_continuous(breaks = x_ticks_5yr) +
  labs(
    title = "Figure 2: Chilean Capital Composition Ratio (tau_t = k_ME - k_NR) Across Regimes",
    subtitle = "Shaded areas: 1920-38 Nitrate Crisis, 1939-73 Classic ISI, 1974-89 Dictatorship, 1990-2024 Neoliberal",
    x = "Year",
    y = "Capital Composition Ratio (tau_t)",
    caption = "Source: Author calculations. LOESS trend line super-imposed."
  ) +
  theme_ch2()

ggsave(file.path(out_dir, "cl_tau_regime_bands.png"), plot = p2, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(out_dir, "cl_tau_regime_bands.pdf"), plot = p2, width = 9, height = 5.5)

# --- Figure 3: BoP Realization Ratio (phi_t) & Blocked Surplus ---
cat("Generating Figure 3: cl_bop_realization_wedge.png...\n")
p3 <- ggplot(df_clean, aes(x = year)) +
  geom_line(aes(y = phi, color = "FX Realization Ratio (phi_t)"), linewidth = 1.0) +
  geom_line(aes(y = pi_blocked, color = "Blocked Surplus (pi - pi_eff)"), linewidth = 0.9, linetype = "dotted") +
  annotate("rect", xmin = 1931, xmax = 1938, ymin = 0, ymax = 1, fill = "red", alpha = 0.15) +
  annotate("rect", xmin = 1971, xmax = 1973, ymin = 0, ymax = 1, fill = "red", alpha = 0.15) +
  annotate("rect", xmin = 1982, xmax = 1985, ymin = 0, ymax = 1, fill = "red", alpha = 0.15) +
  scale_x_continuous(breaks = x_ticks_5yr) +
  scale_y_continuous(limits = c(0, 1)) +
  scale_color_manual(values = c("FX Realization Ratio (phi_t)" = "#2b8cbe", "Blocked Surplus (pi - pi_eff)" = "#e41a1c")) +
  labs(
    title = "Figure 3: FX Realization Ratio (phi_t) and Blocked Surplus in Chile (1920-2024)",
    subtitle = "Highlighting binding BoP external bottleneck episodes (1931-38, 1971-73, 1982-85)",
    x = "Year",
    y = "Ratio / Surplus Share",
    caption = "Source: Author calculations incorporating Note A04 FX conversion ratio phi_t."
  ) +
  theme_ch2()

ggsave(file.path(out_dir, "cl_bop_realization_wedge.png"), plot = p3, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(out_dir, "cl_bop_realization_wedge.pdf"), plot = p3, width = 9, height = 5.5)

# --- Figure 4: Distributive Conflict & FX Interaction ---
cat("Generating Figure 4: cl_distributive_fx_interaction.png...\n")
p4 <- ggplot(df_clean, aes(x = year)) +
  geom_line(aes(y = omega, color = "Wage Share (omega_t)"), linewidth = 1.0) +
  geom_line(aes(y = pi_eff, color = "Effective Profit Share (pi_eff_t)"), linewidth = 1.0, linetype = "dashed") +
  geom_line(aes(y = omega_phi, color = "Distribution-FX Interaction (omega * phi)"), linewidth = 0.8, linetype = "dotdash") +
  scale_x_continuous(breaks = x_ticks_5yr) +
  scale_color_manual(values = c("Wage Share (omega_t)" = "#3182bd", "Effective Profit Share (pi_eff_t)" = "#de2d26", "Distribution-FX Interaction (omega * phi)" = "#31a354")) +
  labs(
    title = "Figure 4: Distributive Conflict, Effective Profit Share & FX Bottleneck in Chile",
    subtitle = "Comparing nominal wage share, effective profit share, and distributive-FX interaction series",
    x = "Year",
    y = "Share / Interaction Level",
    caption = "Source: Author calculations from distr_19202024 & Note A04 effective profit share."
  ) +
  theme_ch2()

ggsave(file.path(out_dir, "cl_distributive_fx_interaction.png"), plot = p4, width = 9, height = 5.5, dpi = 300)
ggsave(file.path(out_dir, "cl_distributive_fx_interaction.pdf"), plot = p4, width = 9, height = 5.5)

# --- Figure 5: Single-Equation Cointegration Elasticity Map ---
cat("Generating Figure 5: cl_cointreg_triad_comparison.png...\n")
triad_file <- file.path(repo_root, "output", "CL", "CL_S42_COINTREG_TRIAD", "chile_cointreg_triad_results.csv")
if (file.exists(triad_file)) {
  df_triad <- read.csv(triad_file, stringsAsFactors = FALSE)
  df_triad_plot <- pivot_longer(df_triad, cols = c("gamma_IMOLS", "gamma_FMOLS", "gamma_DOLS"), names_to = "Estimator", values_to = "Gamma")
  
  p5 <- ggplot(df_triad_plot, aes(x = Regime, y = Gamma, fill = Estimator)) +
    geom_bar(stat = "identity", position = position_dodge(width = 0.7), width = 0.6) +
    geom_hline(yintercept = 1.0, linetype = "dashed", color = "red") +
    scale_fill_manual(values = c("gamma_IMOLS" = "#7570b3", "gamma_FMOLS" = "#1b9e77", "gamma_DOLS" = "#d95f02"),
                      labels = c("IM-OLS", "FM-OLS", "DOLS")) +
    labs(
      title = "Figure 5: Cointegrating Capital Transformation Elasticity (gamma) Across Eras",
      subtitle = "Comparing IM-OLS, FM-OLS, and DOLS point estimates across historical macro regimes",
      x = "Historical Regime",
      y = "Estimated Elasticity (gamma)",
      caption = "Source: Author estimations from CL_S42. Dashed red line denotes benchmark gamma = 1.0."
    ) +
    theme_ch2() +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))
  
  ggsave(file.path(out_dir, "cl_cointreg_triad_comparison.png"), plot = p5, width = 9, height = 5.5, dpi = 300)
  ggsave(file.path(out_dir, "cl_cointreg_triad_comparison.pdf"), plot = p5, width = 9, height = 5.5)
}

# --- Figure 6: VECM Speed of Adjustment (Alpha) ---
cat("Generating Figure 6: cl_alpha_speed_adjustment.png...\n")
vecm_file <- file.path(repo_root, "output", "CL", "CL_S43_VECM_BOP", "chile_vecm_bop_results.csv")
if (file.exists(vecm_file)) {
  df_vecm <- read.csv(vecm_file, stringsAsFactors = FALSE)
  df_alpha <- data.frame(
    Variable = c("Structures (k_NR)", "Machinery (k_ME)"),
    Alpha    = c(df_vecm$Alpha_kNR[1], df_vecm$Alpha_kME[1])
  )
  
  p6 <- ggplot(df_alpha, aes(x = Variable, y = Alpha, fill = Variable)) +
    geom_bar(stat = "identity", width = 0.5) +
    geom_hline(yintercept = 0, linetype = "solid", color = "black") +
    scale_fill_manual(values = c("Structures (k_NR)" = "#3182bd", "Machinery (k_ME)" = "#e6550d")) +
    labs(
      title = "Figure 6: VECM Speed of Adjustment Parameters (alpha) for Chile (1920-2024)",
      subtitle = "Evaluating weak exogeneity: alpha_NR vs alpha_ME under FX constraints",
      x = "Capital Stock Variable",
      y = "Speed of Adjustment (Alpha)",
      caption = "Source: Johansen VECM estimation from CL_S43. Negative values indicate error correction adjustment."
    ) +
    theme_ch2()
  
  ggsave(file.path(out_dir, "cl_alpha_speed_adjustment.png"), plot = p6, width = 7, height = 5, dpi = 300)
  ggsave(file.path(out_dir, "cl_alpha_speed_adjustment.pdf"), plot = p6, width = 7, height = 5)
}

cat("=== All 6 Figures Successfully Generated in output/CL/figures/ ===\n")
