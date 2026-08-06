# ==============================================================================
# S53: Monte Carlo Tail Convergence Analysis & Visual Panel Generator
# ==============================================================================
# Audits the asymptotic tail convergence of CT_IM cointegration tests and 
# coefficient t-statistics as N_sim scales from 100 to 100,000 runs.
# Saves high-resolution PNG plots to chapter2_vault/06_paper_facing/results/figures/
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(gridExtra)
})

csv_dir <- "output/US/S50_SECTION31_IMOLS/csv"
fig_dir <- "chapter2_vault/06_paper_facing/results/figures"
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

# Load simulation results
f100   <- file.path(csv_dir, "cmpr_custom_critical_values_N100.csv")
f5k    <- file.path(csv_dir, "cmpr_custom_critical_values_N5000.csv")
f10k   <- file.path(csv_dir, "cmpr_custom_critical_values_N10000.csv")
f100k  <- file.path(csv_dir, "cmpr_custom_critical_values_N100000.csv")

d100  <- read.csv(f100)  %>% mutate(N_sim = 100)
d5k   <- read.csv(f5k)   %>% mutate(N_sim = 5000)
d10k  <- read.csv(f10k)  %>% mutate(N_sim = 10000)
d100k <- read.csv(f100k) %>% mutate(N_sim = 100000)

df_all <- bind_rows(d100, d5k, d10k, d100k)

# ------------------------------------------------------------------------------
# 1. CT_IM Cointegration Test Tail Convergence
# ------------------------------------------------------------------------------
df_ct <- df_all %>%
  select(Variant, N_sim, p90 = CT_IM_p90, p95 = CT_IM_p95, p99 = CT_IM_p99) %>%
  pivot_longer(cols = c(p90, p95, p99), names_to = "Quantile", values_to = "Value") %>%
  mutate(Quantile = factor(Quantile, levels = c("p90", "p95", "p99"), labels = c("90th Percentile", "95th Percentile", "99th Percentile")))

p_ct <- ggplot(df_ct, aes(x = N_sim, y = Value, color = Quantile, group = Quantile)) +
  geom_line(size = 1) +
  geom_point(size = 2.5) +
  scale_x_log10(breaks = c(100, 5000, 10000, 100000), labels = c("100", "5k", "10k", "100k")) +
  facet_wrap(~ Variant, ncol = 4, scales = "free_y") +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    strip.background = element_rect(fill = "#f0f0f0", color = NA),
    strip.text = element_text(face = "bold"),
    legend.position = "top",
    panel.border = element_rect(color = "#cccccc", fill = NA, size = 0.5)
  ) +
  labs(
    title = "CT_IM Cointegration Test Statistic Tail Convergence (N_sim = 100 to 100,000)",
    subtitle = "Demonstrates asymptotic stabilization of non-standard residual LM test quantiles",
    x = "Number of Monte Carlo Simulations (Log Scale)",
    y = "Critical Value Threshold",
    color = "Quantile"
  )

ggsave(file.path(fig_dir, "cmpr_tail_convergence_ct_im.png"), plot = p_ct, width = 12, height = 7, dpi = 300)

# ------------------------------------------------------------------------------
# 2. t_k0 (Capital Level Coefficient t-stat) Tail Convergence
# ------------------------------------------------------------------------------
df_tk0 <- df_all %>%
  select(Variant, N_sim, p90 = t_k0_p90, p95 = t_k0_p95, p99 = t_k0_p99) %>%
  pivot_longer(cols = c(p90, p95, p99), names_to = "Quantile", values_to = "Value") %>%
  mutate(Quantile = factor(Quantile, levels = c("p90", "p95", "p99"), labels = c("90th Percentile", "95th Percentile", "99th Percentile")))

p_tk0 <- ggplot(df_tk0, aes(x = N_sim, y = Value, color = Quantile, group = Quantile)) +
  geom_line(size = 1) +
  geom_point(size = 2.5) +
  scale_x_log10(breaks = c(100, 5000, 10000, 100000), labels = c("100", "5k", "10k", "100k")) +
  facet_wrap(~ Variant, ncol = 4, scales = "free_y") +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    strip.background = element_rect(fill = "#f0f0f0", color = NA),
    strip.text = element_text(face = "bold"),
    legend.position = "top",
    panel.border = element_rect(color = "#cccccc", fill = NA, size = 0.5)
  ) +
  labs(
    title = "Capital Level Coefficient t-Statistic Tail Convergence (t_k0)",
    subtitle = "Fixed-b asymptotic critical values for primary capital elasticity parameter theta_0",
    x = "Number of Monte Carlo Simulations (Log Scale)",
    y = "t-Statistic Threshold",
    color = "Quantile"
  )

ggsave(file.path(fig_dir, "cmpr_tail_convergence_t_k0.png"), plot = p_tk0, width = 12, height = 7, dpi = 300)

# ------------------------------------------------------------------------------
# 3. t_inter (Interaction Coefficient t-stat) Tail Convergence
# ------------------------------------------------------------------------------
df_tinter <- df_all %>%
  select(Variant, N_sim, p90 = t_inter_p90, p95 = t_inter_p95, p99 = t_inter_p99) %>%
  pivot_longer(cols = c(p90, p95, p99), names_to = "Quantile", values_to = "Value") %>%
  mutate(Quantile = factor(Quantile, levels = c("p90", "p95", "p99"), labels = c("90th Percentile", "95th Percentile", "99th Percentile")))

p_tinter <- ggplot(df_tinter, aes(x = N_sim, y = Value, color = Quantile, group = Quantile)) +
  geom_line(size = 1) +
  geom_point(size = 2.5) +
  scale_x_log10(breaks = c(100, 5000, 10000, 100000), labels = c("100", "5k", "10k", "100k")) +
  facet_wrap(~ Variant, ncol = 4, scales = "free_y") +
  theme_minimal(base_size = 11) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    strip.background = element_rect(fill = "#f0f0f0", color = NA),
    strip.text = element_text(face = "bold"),
    legend.position = "top",
    panel.border = element_rect(color = "#cccccc", fill = NA, size = 0.5)
  ) +
  labs(
    title = "Interaction Coefficient t-Statistic Tail Convergence (t_inter)",
    subtitle = "Asymptotic critical values for double (I(1)xI(1)) and triple (I(1)xI(1)xI(1)) interaction terms",
    x = "Number of Monte Carlo Simulations (Log Scale)",
    y = "t-Statistic Threshold",
    color = "Quantile"
  )

ggsave(file.path(fig_dir, "cmpr_tail_convergence_t_inter.png"), plot = p_tinter, width = 12, height = 7, dpi = 300)

# ------------------------------------------------------------------------------
# 4. Break vs No-Break Quantile Inflation Impact Panel (N = 100k)
# ------------------------------------------------------------------------------
df_100k_comp <- d100k %>%
  mutate(
    Interaction_Type = if_else(grepl("spec1", Variant), "Double (Spec 1)", "Triple (Spec 2)"),
    Has_Break = if_else(grepl("_break", Variant), "With Step Breaks", "No Breaks"),
    Has_I0 = if_else(grepl("_i0", Variant), "With I(0) Control", "No I(0) Control")
  )

p_break_impact <- ggplot(df_100k_comp, aes(x = Variant, y = t_inter_p95, fill = Has_Break)) +
  geom_bar(stat = "identity", width = 0.6) +
  scale_fill_manual(values = c("No Breaks" = "#2b5c8f", "With Step Breaks" = "#d95f02")) +
  facet_wrap(~ Interaction_Type, scales = "free_x") +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = "top",
    strip.background = element_rect(fill = "#f0f0f0", color = NA),
    strip.text = element_text(face = "bold")
  ) +
  labs(
    title = "Impact of Endogenous Structural Breaks on 95% Interaction Critical Values (N = 100k)",
    subtitle = "Compares baseline vs Bai-Perron step dummy augmented DGPs for Double and Triple interactions",
    x = "DGP Specification Variant",
    y = "95% Critical Value (t_inter)",
    fill = "Structural Break Regime"
  )

ggsave(file.path(fig_dir, "cmpr_tail_convergence_break_impact.png"), plot = p_break_impact, width = 10, height = 6, dpi = 300)

cat("Successfully generated 4 high-resolution tail convergence figures in:", fig_dir, "\n")
