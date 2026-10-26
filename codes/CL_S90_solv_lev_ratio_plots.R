# codes/CL_S90_solv_lev_ratio_plots.R
# Purpose: Generate plots for Solvency and Leverage ratios of Chile (1926-2010),
# as well as raw monetary aggregates, reserves, and nominal exchange rate.

library(dplyr, warn.conflicts = FALSE)
library(readr)
library(readxl)
library(ggplot2)
library(tidyr)
library(gridExtra)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(repo_root)

# 1. Setup Output Directory
out_dir <- "reports/CHILE_solv_lev_ratio_plots"
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

# 2. Load Data

# A) Load Staged Panel for Ratios
panel_path <- "data/staged/ch2_panel_chile_with_prices.csv"
df <- read_csv(panel_path, show_col_types = FALSE)

df_sub <- df %>%
  select(year, SolvR_M0, SolvR_M1, SolvR_M2, LevR_M0, LevR_M1, LevR_M2) %>%
  filter(year >= 1926 & year <= 2010)

df_long_solv <- df_sub %>%
  select(year, starts_with("SolvR")) %>%
  pivot_longer(cols = starts_with("SolvR"), names_to = "measure", values_to = "value") %>%
  mutate(measure = factor(measure, levels = c("SolvR_M0", "SolvR_M1", "SolvR_M2"), 
                          labels = c("M0", "M1", "M2"))) %>%
  filter(!is.na(value))

df_long_lev <- df_sub %>%
  select(year, starts_with("LevR")) %>%
  pivot_longer(cols = starts_with("LevR"), names_to = "measure", values_to = "value") %>%
  mutate(measure = factor(measure, levels = c("LevR_M0", "LevR_M1", "LevR_M2"), 
                          labels = c("M0", "M1", "M2"))) %>%
  filter(!is.na(value))

# B) Load Raw Components from ClioLab
clio_w04_path <- "data/raw/Chile/cliolab/W04_Precios.xlsx"
clio_w05_path <- "data/raw/Chile/cliolab/W05_Comercio.xlsx"
clio_w06_path <- "data/raw/Chile/cliolab/W06_Monetaria.xlsx"

df_e <- read_excel(clio_w04_path, sheet = "4.2.1", skip = 10) %>% select(year = Code, e_t = TCNUSD) %>% filter(!is.na(year))
df_ir <- read_excel(clio_w05_path, sheet = "5.3 Reservas Internacionales", skip = 10) %>% select(year = Code, IR_t = RIS) %>% filter(!is.na(year))
df_m0 <- read_excel(clio_w06_path, sheet = "6.1.3", skip = 13) %>% select(year = Code, M0_t = EMN_A) %>% filter(!is.na(year))
df_m12 <- read_excel(clio_w06_path, sheet = "6.1.2", skip = 10) %>% select(year = Code, M1_t = M1S1NOM_A, M2_t = M2S1NOM_A) %>% filter(!is.na(year))

df_raw <- df_e %>%
  full_join(df_ir, by = "year") %>%
  full_join(df_m0, by = "year") %>%
  full_join(df_m12, by = "year") %>%
  mutate(F_t = e_t * IR_t) %>%
  filter(year >= 1926 & year <= 2010)

df_long_money <- df_raw %>%
  select(year, M0_t, M1_t, M2_t) %>%
  pivot_longer(cols = -year, names_to = "measure", values_to = "value") %>%
  mutate(measure = factor(measure, levels = c("M0_t", "M1_t", "M2_t"), 
                          labels = c("M0", "M1", "M2"))) %>%
  filter(!is.na(value))


# 3. Plotting Setup

events <- data.frame(
  year = c(1931, 1942, 1973, 1989),
  label = c("1931:\nSuspension of\nConvertibility", 
            "1942:\nInstitutional\nPivot", 
            "1973:\nMilitary\nCoup", 
            "1989:\nCentral Bank\nAutonomy")
)

add_annotations <- function(p) {
  p + 
    geom_vline(data = events, aes(xintercept = year), linetype = "dashed", color = "gray50", linewidth = 0.6) +
    geom_text(data = events, aes(x = year, y = Inf, label = label), 
              vjust = 1.1, hjust = -0.05, size = 2.5, color = "gray30", inherit.aes = FALSE)
}

umass_theme <- theme_minimal() +
  theme(
    text = element_text(family = "sans", color = "black"),
    plot.title = element_text(face = "bold", size = 14, margin = margin(b = 10)),
    plot.subtitle = element_text(size = 11, margin = margin(b = 15)),
    axis.title = element_text(face = "bold"),
    axis.text = element_text(color = "black"),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "gray90"),
    panel.grid.major.y = element_line(color = "gray80", linetype = "dotted"),
    legend.position = "bottom",
    legend.title = element_blank(),
    strip.text = element_text(face = "bold", size = 12)
  )

# --- 4. Plotting Original Ratios ---

p_solv_combined <- ggplot(df_long_solv, aes(x = year, y = value, color = measure, linetype = measure)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("M0" = "#1f77b4", "M1" = "#d62728", "M2" = "#2ca02c")) +
  scale_x_continuous(breaks = seq(1925, 2010, by = 5), expand = c(0.02, 0.02)) +
  labs(title = "Solvency Ratios in Chile (1926-2010)",
       subtitle = "Ratio of International Reserves to Monetary Aggregates",
       y = "Solvency Ratio",
       x = "Year") +
  umass_theme
p_solv_combined <- add_annotations(p_solv_combined)

p_lev_combined <- ggplot(df_long_lev, aes(x = year, y = value, color = measure, linetype = measure)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("M0" = "#1f77b4", "M1" = "#d62728", "M2" = "#2ca02c")) +
  scale_x_continuous(breaks = seq(1925, 2010, by = 5), expand = c(0.02, 0.02)) +
  labs(title = "Leverage Ratios in Chile (1926-2010)",
       subtitle = "Inverse of Solvency Ratio (Monetary Aggregate / International Reserves)",
       y = "Leverage Ratio",
       x = "Year") +
  umass_theme
p_lev_combined <- add_annotations(p_lev_combined)

# --- 5. Plotting New Components ---

ihs_trans <- scales::trans_new(
  name = "ihs",
  transform = function(x) asinh(x),
  inverse = function(x) sinh(x)
)

# A) Monetary Aggregates (IHS scale)
p_money <- ggplot(df_long_money, aes(x = year, y = value, color = measure, linetype = measure)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("M0" = "#1f77b4", "M1" = "#d62728", "M2" = "#2ca02c")) +
  scale_x_continuous(breaks = seq(1925, 2010, by = 5), expand = c(0.02, 0.02)) +
  scale_y_continuous(trans = ihs_trans, labels = scales::comma) +
  labs(title = "Monetary Aggregates in Chile (1926-2010)",
       subtitle = "M0, M1, and M2 (Nominal CLP)",
       y = "Nominal Value",
       x = "Year") +
  umass_theme
p_money <- add_annotations(p_money)

# B) International Reserves (USD) - IHS scale
df_ir_clean <- df_raw %>% filter(!is.na(IR_t))
p_reserves <- ggplot(df_ir_clean, aes(x = year, y = IR_t)) +
  geom_line(linewidth = 0.8, color = "#ff7f0e") +
  scale_x_continuous(breaks = seq(1925, 2010, by = 5), expand = c(0.02, 0.02)) +
  scale_y_continuous(trans = ihs_trans, labels = scales::comma) +
  labs(title = "International Reserves (1926-2010)",
       subtitle = "Gross International Reserves (Nominal USD)",
       y = "Reserves in USD",
       x = "Year") +
  umass_theme
p_reserves <- add_annotations(p_reserves)

# C) Nominal Exchange Rate - IHS scale
df_e_clean <- df_raw %>% filter(!is.na(e_t))
p_exchange <- ggplot(df_e_clean, aes(x = year, y = e_t)) +
  geom_line(linewidth = 0.8, color = "#9467bd") +
  scale_x_continuous(breaks = seq(1925, 2010, by = 5), expand = c(0.02, 0.02)) +
  scale_y_continuous(trans = ihs_trans, labels = scales::comma) +
  labs(title = "Nominal Exchange Rate (1926-2010)",
       subtitle = "CLP per USD",
       y = "Exchange Rate",
       x = "Year") +
  umass_theme
p_exchange <- add_annotations(p_exchange)

# D) Dual Plot: Money vs Reserves in CLP (IHS scale, LHS/RHS axes)
# To create a dual axis with independent scales that visually aligns the series despite massive hyperinflation scale differences,
# we compute a scaling coefficient based on the maximums of the series.
max_money <- max(df_raw$M2_t, df_raw$M1_t, df_raw$M0_t, na.rm = TRUE)
max_reserves <- max(df_raw$F_t, na.rm = TRUE)
coeff <- max_money / max_reserves

p_dual <- ggplot(df_raw, aes(x = year)) +
  # Money aggregates on LHS
  geom_line(aes(y = M0_t, color = "M0"), linewidth = 0.8, linetype = "solid") +
  geom_line(aes(y = M1_t, color = "M1"), linewidth = 0.8, linetype = "solid") +
  geom_line(aes(y = M2_t, color = "M2"), linewidth = 0.8, linetype = "solid") +
  # Reserves scaled to match LHS range visually
  geom_line(aes(y = F_t * coeff, color = "Reserves (CLP)"), linewidth = 0.8, linetype = "dashed") +
  
  scale_color_manual(values = c("M0" = "#1f77b4", "M1" = "#d62728", "M2" = "#2ca02c", "Reserves (CLP)" = "#ff7f0e")) +
  scale_x_continuous(breaks = seq(1925, 2010, by = 5), expand = c(0.02, 0.02)) +
  
  # LHS/RHS dual axes
  scale_y_continuous(
    trans = ihs_trans,
    name = "Monetary Aggregates (LHS, Nominal CLP)",
    labels = scales::comma,
    sec.axis = sec_axis(~ . / coeff, name = "International Reserves (RHS, Nominal CLP)", labels = scales::comma)
  ) +
  labs(title = "Monetary Aggregates vs. International Reserves (1926-2010)",
       subtitle = "Reserves converted to Nominal CLP via Exchange Rate. Dual Y-Axes.",
       x = "Year") +
  umass_theme +
  theme(
    axis.title.y.left = element_text(color = "black"),
    axis.title.y.right = element_text(color = "#ff7f0e"),
    axis.text.y.right = element_text(color = "#ff7f0e")
  )
p_dual <- add_annotations(p_dual)

# --- 6. Save Plots ---

save_plot <- function(plot_obj, name_prefix, w = 10, h = 6) {
  ggsave(filename = file.path(out_dir, paste0(name_prefix, ".pdf")), plot = plot_obj, width = w, height = h, device = cairo_pdf)
  ggsave(filename = file.path(out_dir, paste0(name_prefix, ".png")), plot = plot_obj, width = w, height = h, dpi = 300)
}

save_plot(p_solv_combined, "fig_solv_combined")
save_plot(p_lev_combined, "fig_lev_combined")
save_plot(p_money, "fig_money_aggregates")
save_plot(p_reserves, "fig_reserves_usd")
save_plot(p_exchange, "fig_exchange_rate")
save_plot(p_dual, "fig_dual_money_reserves")

cat("Successfully generated and saved all plots.\n")
