#!/usr/bin/env Rscript

# S60_section5_comparative_mu.R
# Plots implicit capacity utilization (\mu_t) for the U.S. and Chile in a single plot.

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(tidyr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(repo_root)

# Load data
us_path <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY", "csv", "us_mu_m244b.csv")
cl_path <- file.path(repo_root, "output", "chile_capacity_utilization_series.csv")

if (!file.exists(us_path)) stop("US series not found")
if (!file.exists(cl_path)) stop("Chile series not found")

us_df <- read_csv(us_path, show_col_types = FALSE) %>%
  select(year, mu_us = mu_t) %>%
  mutate(mu_us = mu_us / 100) # Convert from percentage to ratio to match Chile

cl_df <- read_csv(cl_path, show_col_types = FALSE) %>%
  select(year, mu_cl = mu_t)

# Merge
df <- full_join(us_df, cl_df, by = "year") %>%
  filter(year >= 1931, year <= 2024) %>%
  arrange(year)

# Theme
theme_paper_custom <- function() {
  theme_classic(base_size = 11) %+replace%
    theme(
      plot.title = element_blank(),
      plot.subtitle = element_blank(),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray90", linewidth = 0.4),
      legend.position = "bottom",
      legend.background = element_rect(fill = "transparent", color = NA),
      legend.key = element_rect(fill = "transparent", color = NA),
      legend.key.width = unit(1.8, "line"),
      legend.text = element_text(size = 9.5),
      axis.line.x = element_line(linewidth = 0.6, color = "black"),
      axis.line.y = element_line(linewidth = 0.6, color = "black"),
      axis.ticks = element_line(linewidth = 0.6, color = "black"),
      axis.title.x = element_text(face = "bold", color = "black", margin = margin(t = 8), size = 10.5),
      axis.text.x  = element_text(color = "black", size = 9.5),
      axis.title.y = element_text(face = "bold", color = "black", margin = margin(r = 8), size = 10.5, angle = 90),
      axis.text.y  = element_text(color = "black", size = 9.5),
      plot.margin  = margin(t = 10, r = 15, b = 10, l = 10)
    )
}

# Plot
p <- ggplot(df, aes(x = year)) +
  # Shaded band for 1979-1985 crisis
  annotate("rect", xmin = 1979, xmax = 1985, ymin = -Inf, ymax = Inf, fill = "gray80", alpha = 0.45) +
  # Reference line at 1.00
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "gray30", linewidth = 0.7) +
  
  # Series
  geom_line(aes(y = mu_us, color = "U.S. (Base 1973=1.0)", linetype = "U.S. (Base 1973=1.0)"), linewidth = 1.1) +
  geom_line(aes(y = mu_cl, color = "Chile (Base 1981=1.0)", linetype = "Chile (Base 1981=1.0)"), linewidth = 1.1) +
  
  scale_x_continuous(
    name = "Year",
    breaks = seq(1930, 2020, by = 10),
    limits = c(1930, 2025),
    expand = c(0.01, 0.01)
  ) +
  scale_y_continuous(
    name = expression(paste("Capacity Utilization (", mu[t], ")")),
    limits = c(0.50, 1.35),
    breaks = seq(0.50, 1.30, by = 0.10)
  ) +
  scale_color_manual(
    name = NULL,
    values = c(
      "U.S. (Base 1973=1.0)" = "#1B365D",
      "Chile (Base 1981=1.0)" = "firebrick3"
    )
  ) +
  scale_linetype_manual(
    name = NULL,
    values = c(
      "U.S. (Base 1973=1.0)" = "solid",
      "Chile (Base 1981=1.0)" = "dashed"
    )
  ) +
  theme_paper_custom()

# Export
fig_dir   <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
fig_vault <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "figures")

for (d in c(fig_dir, fig_vault)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path(d, "fig_sec5_combined_mu.pdf"), p, width = 9.5, height = 5.2, device = cairo_pdf)
  ggsave(file.path(d, "fig_sec5_combined_mu.png"), p, width = 9.5, height = 5.2, dpi = 300)
  write_csv(df, file.path(d, "fig_sec5_combined_mu_data.csv"))
}

cat("Successfully generated fig_sec5_combined_mu.pdf, .png, and .csv with standard 9.5x5.2 aspect ratio\n")
