#!/usr/bin/env Rscript

# US_S60_section4323_driving_forces_plot.R
# ---------------------------------------------------------------------------
# Section 4.3.2 Dual-Axis Plot Generation for Specification B Drivers
# Left Axis: Effective Distributive Pressure Index (C_index_t)
# Right Axis: Relative Asset Prices p_t^\kappa (ME / NRC, 1973 = 1.00)
#
# Model: M2.44b (Clean Corporate Tier 1 NVA, Set 2, Yes Break)
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(cointReg)
  library(grid)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
rds_path_specB <- file.path(repo_root, "output", "US", "S61_SECTION32_IMOLS", "rds", "s61_fitted_models.rds")
f_in           <- file.path(repo_root, "output", "gpim_specB_components_long.csv")

out_dir    <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY", "fig")
fig_dir    <- file.path(repo_root, "chapter2_paper", "paper_tex_tables")
brain_dir  <- "C:/Users/User/.gemini/antigravity/brain/b0cd553c-177b-4568-8922-6446219b2174"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Dual-Axis Driving Forces Plot Generation (Spec B)\n")
cat("========================================================================\n")

if (!file.exists(rds_path_specB)) stop("Fitted models RDS not found at: ", rds_path_specB)
fs_specB <- readRDS(rds_path_specB)
m <- fs_specB[["M2.44b"]]
df <- read.csv(f_in)

df_clean <- df[df$year %in% m$years, ]
df_clean <- df_clean[order(df_clean$year), ]

# Effective wage pressure
w_var <- if (grepl("Tier 1", m$Wage_Label)) "omega_ST_Tier1_NVA_lag1" else "omega_ST_Tier2_NVA_lag1"
w <- df_clean[[w_var]]

df_clean$iota_t <- df_clean$IPP_share_capital_plus_IPP
df_clean$iota_lag1 <- dplyr::lag(df_clean$iota_t, 1L)
df_clean$iota_lag1[1] <- df_clean$iota_t[1]

df_clean$C_idx <- w * (1 - df_clean$iota_lag1)
df_clean$Date <- as.Date(paste0(df_clean$year, "-01-01"))

# Relative price indexed to 1973 = 1.00 (100 at base year 1973)
p_raw <- df_clean$P_ME / df_clean$P_NRC
idx_1973 <- which(df_clean$year == 1973)
df_clean$p_rel_idx <- p_raw / p_raw[idx_1973]

# -----------------------------------------------------------------
# Dual-Axis Scaling & Transformations
# -----------------------------------------------------------------
min_L <- 0.45
max_L <- 0.90

min_R <- 0.30
max_R <- 1.50

scale_factor <- (max_L - min_L) / (max_R - min_R)
shift_factor <- min_L - scale_factor * min_R

df_clean$p_rel_scaled <- df_clean$p_rel_idx * scale_factor + shift_factor

# -----------------------------------------------------------------
# Regime Shading & Annotations Protocol (Harmonized Post-Fordism 1974-2009 & Monopoly Capital 2010-2024)
# -----------------------------------------------------------------
shade_df <- data.frame(
  xmin = as.Date(c("1939-01-01", "1947-01-01", "1968-01-01", "1974-01-01", "2010-01-01")),
  xmax = as.Date(c("1945-12-31", "1967-12-31", "1973-12-31", "2009-12-31", "2024-12-31")),
  fill_color = c("#CBD5E1", "#D1FAE5", "#FEE2E2", "#FEF3C7", "#E0E7FF"),
  alpha_val  = c(0.50, 0.55, 0.60, 0.50, 0.50)
)

anno_df <- data.frame(
  x = as.Date(c("1942-01-01", "1957-01-01", "1971-01-01", "1992-01-01", "2017-06-01")),
  y = rep(max_L - 0.015, 5),
  label = c(
    "War Mobilization\n(1939–1945)",
    "Atlantic Fordism\n(1947–1967)",
    "Profit Squeeze\n(1968–1973)",
    "Post-Fordism &\nFinancialization\n(1974–2009)",
    "Intellectual Monopoly\nCapital (2010–2024)"
  ),
  size = rep(3.8, 5)
)

# -----------------------------------------------------------------
# Plot Theme
# -----------------------------------------------------------------
theme_dual_axis <- function() {
  theme_classic(base_size = 11) %+replace%
    theme(
      panel.background = element_blank(),
      plot.background  = element_blank(),

      axis.line.x       = element_line(color = "#2C3E50", linewidth = 0.8),
      axis.line.y.left  = element_line(color = "#1A2530", linewidth = 0.8),
      axis.line.y.right = element_line(color = "#2980B9", linewidth = 0.8),

      axis.ticks.x      = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.ticks.y.left = element_line(color = "#1A2530", linewidth = 0.6),
      axis.ticks.y.right= element_line(color = "#2980B9", linewidth = 0.6),
      axis.ticks.length = unit(0.20, "cm"),

      axis.text.x       = element_text(color = "black"),
      axis.text.y.left  = element_text(color = "#1A2530", face = "bold"),
      axis.text.y.right = element_text(color = "#2980B9", face = "bold"),

      axis.title.x       = element_text(face = "bold", margin = margin(t = 8), color = "black"),
      axis.title.y.left  = element_text(color = "#1A2530", face = "bold", margin = margin(r = 8)),
      axis.title.y.right = element_text(color = "#2980B9", face = "bold", angle = 90, margin = margin(l = 8)),

      legend.position   = "bottom",
      legend.direction  = "horizontal",
      legend.title      = element_blank(),
      legend.background = element_blank(),
      legend.key        = element_blank(),
      legend.key.width  = unit(1.5, "cm"),
      plot.margin       = margin(t = 10, r = 15, b = 10, l = 10)
    )
}

# -----------------------------------------------------------------
# Construct Dual Plot Object
# -----------------------------------------------------------------
p_dual <- ggplot(df_clean, aes(x = Date)) +
  # Background Shading
  geom_rect(data = shade_df, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill_color, alpha = alpha_val)) +
  scale_fill_identity() +
  scale_alpha_identity() +

  # Boundary lines
  geom_vline(xintercept = as.Date(c("1947-01-01", "1968-01-01", "1974-01-01", "2010-01-01")),
             color = "gray50", linetype = "dotted", linewidth = 0.5) +

  # Annotations (Enlarged size = 3.8 bold)
  geom_text(data = anno_df, aes(x = x, y = y, label = label, size = size),
            inherit.aes = FALSE, vjust = 1, lineheight = 0.9, color = "black", fontface = "bold") +
  scale_size_identity() +

  # Time Series Lines
  geom_line(aes(y = C_idx, color = "Effective Distributive Pressure (C_idx)"), linewidth = 1.1, linetype = "solid") +
  geom_line(aes(y = p_rel_scaled, color = "Relative Asset Prices (p_rel)"), linewidth = 1.1, linetype = "dashed") +

  # Color Scale & Labels
  scale_color_manual(
    values = c(
      "Effective Distributive Pressure (C_idx)" = "#1A2530",
      "Relative Asset Prices (p_rel)" = "#2980B9"
    ),
    labels = c(
      expression(paste("Effective Distributive Pressure Index ", C[t])),
      expression(paste("Relative Asset Prices ", p[t]^kappa, " (ME / NRC) [1973 = 1.00]"))
    )
  ) +

  # Continuous Dual Axis Scaling
  scale_y_continuous(
    name = expression(paste("Effective Distributive Pressure ", C[t])),
    limits = c(min_L, max_L),
    breaks = seq(min_L, max_L, by = 0.05),
    labels = scales::percent_format(accuracy = 1),
    sec.axis = sec_axis(
      transform = ~ (. - shift_factor) / scale_factor,
      name = expression(paste("Relative Asset Prices ", p[t]^kappa, " (1973 = 1.00)")),
      breaks = seq(min_R, max_R, by = 0.20),
      labels = scales::number_format(accuracy = 0.01)
    )
  ) +
  scale_x_date(
    name = "Year",
    date_breaks = "10 years",
    date_labels = "%Y",
    expand = c(0.01, 0)
  ) +
  theme_dual_axis()

# -----------------------------------------------------------------
# Export Visual Artifacts
# -----------------------------------------------------------------
fig_dir   <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
fig_vault <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "figures")

for (d in c(out_dir, fig_dir, fig_vault)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path(d, "fig_us_specB_driving_forces.pdf"), plot = p_dual, width = 9.5, height = 5.2, device = cairo_pdf)
  ggsave(file.path(d, "fig_us_specB_driving_forces.png"), plot = p_dual, width = 9.5, height = 5.2, dpi = 300, type = "cairo")
}

cat("Updated dual-axis driving forces plot saved successfully as fig_us_specB_driving_forces.pdf!\n")
