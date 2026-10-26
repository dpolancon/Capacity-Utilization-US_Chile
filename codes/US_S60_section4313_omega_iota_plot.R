#!/usr/bin/env Rscript

# US_S60_section4313_omega_iota_plot.R
# Generates the triplet plot of Wage Share, IPP Share, and Effective Wage Pressure
# specific to Section 4.3.1.3 based on Model M2.11b components.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(scales)
  library(grid)
  library(dplyr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
s41_csv   <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data", "s41_extended_capital_panel.csv")
s29f_csv  <- file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION", "csv", "S29F_shaikh_tonak_wage_share_panel.csv")
out_dir   <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY", "fig")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Triplet Plot (Omega, Iota, Effective) Generation for Section 4.3.1.3\n")
cat("========================================================================\n")

# ==============================================================================
# DATA PREPARATION & RECONSTRUCTION (US nonfinancial corporate 1929-2024)
# ==============================================================================
df_cap <- read.csv(s41_csv, stringsAsFactors = FALSE)
df_st  <- read.csv(s29f_csv, stringsAsFactors = FALSE)

df <- df_cap[, c("year", "k_cap")]
df <- merge(df, df_st[, c("year", "omega_CORP_NVA_clean_Tier1")], by = "year", all.x = TRUE)

df <- df[df$year >= 1929 & df$year <= 2024, ]
df <- df[order(df$year), ]

# Lags used in regression
df$wage_share_nva <- dplyr::lag(df$omega_CORP_NVA_clean_Tier1, 1L)
df$iota_t <- df_cap$IPP_share_capital_plus_IPP[match(df$year, df_cap$year)]
df$iota_share <- dplyr::lag(df$iota_t, 1L)

req_cols <- c("year", "wage_share_nva", "iota_share")
df_plot <- df[complete.cases(df[, req_cols]), ]

df_plot$effective_wage_pressure <- df_plot$wage_share_nva * (1 - df_plot$iota_share)

# Palette Definitions (Publication Standard)
color_omega     <- "#C0392B" # Crimson Red (Wage Share, dashed)
color_effective <- "#1A2530" # Dark Slate (Effective Wage Pressure, solid)
color_iota      <- "#E67E22" # Ochre Amber (IPP Share, dotdash)

# Scaling logic
# Left axis (omega and effective): 0.50 to 0.90
# Right axis (iota): 0.00 to 0.25
shift_factor <- 0.50
scale_factor <- 0.40 / 0.25

df_plot$iota_scaled <- df_plot$iota_share * scale_factor + shift_factor

## Shading & Annotations Data (Harmonized Post-Fordism 1974-2009 & Monopoly Capital 2010-2024)
shade_df <- data.frame(
  xmin = c(1939, 1947, 1968, 1974, 2010),
  xmax = c(1945, 1967, 1973, 2009, 2024),
  fill_color = c("#CBD5E1", "#D1FAE5", "#FEE2E2", "#FEF3C7", "#E0E7FF"),
  alpha_val = c(0.50, 0.55, 0.60, 0.50, 0.50)
)

anno_df <- data.frame(
  x = c(1942.0, 1957.0, 1970.5, 1991.5, 2017.0),
  y = rep(0.88, 5),
  label = c(
    "War Mobilization\n(1939–1945)",
    "Atlantic Fordism\n(1947–1967)",
    "Profit Squeeze\n(1968–1973)",
    "Post-Fordism &\nFinancialization\n(1974–2009)",
    "Intellectual Monopoly\nCapital (2010–2024)"
  ),
  size = rep(3.8, 5)
)

# Custom Theme
theme_triplet_axis <- function() {
  theme_classic(base_size = 11) %+replace%
    theme(
      legend.position = "bottom",
      legend.background = element_rect(fill = "transparent", color = NA),
      legend.key.width = unit(1.8, "line"),
      legend.text = element_text(size = 10),
      axis.title.y.left = element_text(face = "bold", margin = margin(r = 10)),
      axis.title.y.right = element_text(color = color_iota, face = "bold", margin = margin(l = 10), angle = 90),
      axis.title.x = element_text(face = "bold", margin = margin(t = 8)),
      
      axis.line.x = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.line.y.left = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.line.y.right = element_line(linewidth = 0.6, color = color_iota),
      
      axis.ticks.x = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.ticks.y.left = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.ticks.y.right = element_line(linewidth = 0.6, color = color_iota),
      
      axis.text.x = element_text(color = "black"),
      axis.text.y.left = element_text(color = "black"),
      axis.text.y.right = element_text(color = color_iota, face = "bold"),
      
      plot.margin = margin(t = 10, r = 15, b = 10, l = 10)
    )
}

# ==============================================================================
# GGPLOT2 CONSTRAINED SPECIFICATION (ZERO HEADERS/FOOTERS)
# ==============================================================================
p_fig4313 <- ggplot(df_plot, aes(x = year)) +
  # 1. Structural Regime Background Shading
  geom_rect(data = shade_df, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill_color, alpha = alpha_val)) +
  scale_fill_identity() +
  scale_alpha_identity() +
  
  # Vertical boundary lines
  geom_vline(xintercept = c(1947, 1968, 1974, 2010), color = "gray50", linetype = "dotted", linewidth = 0.5) +

  # Top-anchored regime label banners (Enlarged size = 3.8 bold)
  geom_text(data = anno_df, aes(x = x, y = y, label = label, size = size), inherit.aes = FALSE, 
            vjust = 1, lineheight = 0.9, color = "black", fontface = "bold") +
  scale_size_identity() +

  # 3. Three Time-Series Trajectories
  geom_line(aes(y = wage_share_nva, color = "Wage Share"), 
            linewidth = 1.1, linetype = "dashed") +
  geom_line(aes(y = effective_wage_pressure, color = "Effective Wage Pressure"), 
            linewidth = 1.1, linetype = "solid") +
  geom_line(aes(y = iota_scaled, color = "IPP Capital Share"), 
            linewidth = 1.1, linetype = "dotdash") +

  # 4. Scale and Axis Definitions
  scale_y_continuous(
    name = expression(paste("Wage Share & Effective Pressure (Left Axis)")),
    limits = c(0.50, 0.90),
    breaks = seq(0.50, 0.90, by = 0.10),
    labels = scales::percent_format(accuracy = 1),
    sec.axis = sec_axis(
      transform = ~ (. - shift_factor) / scale_factor,
      name = expression(paste("IPP Capital Share ", iota[t-1], " (Right Axis)")),
      breaks = seq(0.0, 0.25, by = 0.05),
      labels = scales::percent_format(accuracy = 1)
    )
  ) +
  scale_x_continuous(
    name = "Year",
    breaks = seq(1930, 2020, by = 10),
    expand = c(0.01, 0.01)
  ) +

  # 5. Manual Color & Line Mapping
  scale_color_manual(
    name = NULL,
    values = c(
      "Wage Share" = color_omega,
      "Effective Wage Pressure" = color_effective,
      "IPP Capital Share" = color_iota
    ),
    breaks = c(
      "Wage Share",
      "IPP Capital Share",
      "Effective Wage Pressure"
    ),
    labels = c(
      expression(paste("Wage Share (", omega[t-1], ")")),
      expression(paste("IPP Capital Share (", iota[t-1], ") [Right Axis]")),
      expression(paste("Effective Wage Pressure (", omega[t-1], "(1 - ", iota[t-1], "))"))
    )
  ) +

  # 6. Minimalist LaTeX-Harmonized Theme
  theme_triplet_axis()

# ==============================================================================
# DUAL EXPORT PIPELINE (PDF FOR LATEX / PNG FOR WEB PREVIEW)
# ==============================================================================
fig_dir   <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
fig_vault <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "figures")

for (d in c(out_dir, fig_dir, fig_vault)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path(d, "fig_us_specA_subregimes_omega_iota.pdf"), plot = p_fig4313, width = 9.5, height = 5.2, device = cairo_pdf)
  ggsave(file.path(d, "fig_us_specA_subregimes_omega_iota.png"), plot = p_fig4313, width = 9.5, height = 5.2, dpi = 300, type = "cairo")
}

cat(sprintf("Harmonized Spec A subregimes plot saved to: %s as fig_us_specA_subregimes_omega_iota.pdf\n", fig_dir))
