#!/usr/bin/env Rscript

# US_S38_generate_us_only_figures.R
# Top-notch publication-grade ggplot2 figures for the US Capital Composition Report.
# Note: Graph titles and notes are handled strictly in LaTeX (\caption on top, Note on bottom).

suppressMessages(library(ggplot2))
suppressMessages(library(tidyr))
suppressMessages(library(dplyr))

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
us_file   <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
fig_dir   <- file.path(repo_root, "output", "figures")

if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

us <- read.csv(us_file)
nr_col <- if ("k_NRC" %in% colnames(us)) "k_NRC" else "k_NR"
us <- us[!is.na(us$k_ME) & !is.na(us[[nr_col]]), ]
us$k_NRC <- us[[nr_col]]
us$tau <- us$k_ME - us$k_NRC

# -----------------------------------------------------------------------------
# Figure 1: US Capital Components in Log-Levels (Granular 45° Year Ticks)
# -----------------------------------------------------------------------------
us_long <- us %>%
  select(year, k_ME, k_NRC) %>%
  pivot_longer(cols = c(k_ME, k_NRC), names_to = "Asset", values_to = "Log_Stock") %>%
  mutate(Asset_Label = ifelse(Asset == "k_ME", "k_ME (Machinery & Equipment)", "k_NRC (Nonresidential Structures)"))

# Dataframe for inflection labels positioned cleanly
inflect_labels_p1 <- data.frame(
  x = c(1933, 1968, 2008),
  y = rep(max(us_long$Log_Stock) * 0.96, 3),
  label = c("1933 Trough", "1968 Squeeze", "2008 GFC")
)

p1 <- ggplot() +
  geom_line(data = us_long, aes(x = year, y = Log_Stock, color = Asset_Label), linewidth = 1.3) +
  geom_vline(xintercept = c(1933, 1968, 2008), linetype = "dashed", color = "#4B5563", linewidth = 0.75) +
  geom_label(data = inflect_labels_p1, aes(x = x, y = y, label = label), 
             color = "#1F2937", fill = "#F3F4F6", linewidth = 0.3, size = 3.3, fontface = "bold", vjust = 0.5) +
  scale_color_manual(values = c("k_ME (Machinery & Equipment)" = "#1E3A8A", 
                                "k_NRC (Nonresidential Structures)" = "#DC2626")) +
  scale_x_continuous(breaks = seq(1925, 2021, by = 5), expand = c(0.01, 0.01)) +
  labs(x = "Year", 
       y = "Log Real Capital Stock",
       color = NULL) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    legend.text = element_text(size = 10, face = "bold"),
    axis.title = element_text(face = "bold", size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 9, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E5E7EB"),
    plot.margin = margin(t = 5, r = 10, b = 5, l = 5)
  )

png_fig1 <- file.path(fig_dir, "us_capital_levels_loess.png")
ggsave(png_fig1, p1, width = 9.5, height = 5.4, dpi = 300)
cat("Saved granular 45-deg ggplot Figure 1 to:", png_fig1, "\n")


# -----------------------------------------------------------------------------
# Figure 2: US Capital Composition tau_t Trajectory (Granular 45° Year Ticks)
# -----------------------------------------------------------------------------
us_rects <- data.frame(
  xmin = c(1925, 1933, 1968, 2008),
  xmax = c(1933, 1968, 2008, 2021),
  fill_color = c("#E0F2FE", "#DCFCE7", "#FEF3C7", "#FEE2E2")
)

# Inflection labels for Figure 2 positioned matching Figure 1
inflect_labels_p2 <- data.frame(
  x = c(1933, 1968, 2008),
  y = rep(max(us$tau) * 0.95, 3),
  label = c("1933 Trough", "1968 Squeeze", "2008 GFC")
)

p2 <- ggplot() +
  geom_rect(data = us_rects, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf), 
            fill = us_rects$fill_color, alpha = 0.45) +
  geom_point(data = us, aes(x = year, y = tau), color = "#1F2937", size = 1.5, alpha = 0.75) +
  geom_smooth(data = us, aes(x = year, y = tau), method = "loess", span = 0.3, color = "#6D28D9", linewidth = 1.3, se = FALSE) +
  geom_vline(xintercept = c(1933, 1968, 2008), linetype = "dashed", color = "#B91C1C", linewidth = 0.8) +
  geom_label(data = inflect_labels_p2, aes(x = x, y = y, label = label), 
             color = "#1F2937", fill = "#F3F4F6", linewidth = 0.3, size = 3.3, fontface = "bold", vjust = 0.5) +
  scale_x_continuous(breaks = seq(1925, 2021, by = 5), expand = c(0.01, 0.01)) +
  labs(x = "Year", 
       y = "tau_t = log(K_ME) - log(K_NRC)") +
  theme_minimal(base_size = 12) +
  theme(
    axis.title = element_text(face = "bold", size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 9, face = "bold"),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E5E7EB"),
    plot.margin = margin(t = 5, r = 10, b = 5, l = 5)
  )

png_fig2 <- file.path(fig_dir, "us_tau_regime_bands.png")
ggsave(png_fig2, p2, width = 9.5, height = 5.4, dpi = 300)
cat("Saved granular 45-deg ggplot Figure 2 with inflection labels to:", png_fig2, "\n")
