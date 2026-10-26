#!/usr/bin/env Rscript

# CL_S60_generate_stylized_facts_figures.R
# ---------------------------------------------------------------------------
# Chilean Stylized Facts & Results Visualization Engine (Section 4.1.8 & 4.4)
#
# Revisions applied:
#   - Stylized Facts: Partitioned external constraint into 4 standalone single plots (4a, 4b, 4c, 4d) for LaTeX minipage paneling:
#       * 4a: Central Bank Solvency Ratio (SolvR_M0)
#       * 4b: Log Terms of Trade (log TERMINT_rebased)
#       * 4c: Log Real Exports (log X_FOB)
#       * 4d: Log Real Machinery Investment (log I_ME_perez)
#   - Results Section: Generates fig_cl_results_z_index_threshold (Option B) plotting Composite Z_t = 0.2 M_tilde + 0.8 S_tilde with threshold gamma_hat = 0.425 and binding regime background shading.
#   - All math symbols stripped from Y-axis labels and legend text.
#   - Axis and legend font color strictly set to black (#000000).
#   - LOESS trend curves dashed for clean visual contrast.
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(gridExtra)
  library(grid)
  library(readr)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

# Input Data Path
panel_path <- file.path(repo_root, "data", "staged", "ch2_panel_chile_with_prices.csv")
if (!file.exists(panel_path)) stop("Missing Chilean staged panel data at: ", panel_path)

df_raw <- read_csv(panel_path, show_col_types = FALSE)

df <- df_raw %>%
  mutate(
    y_t                  = log(GDP_real),
    k_NR                 = log(K_NR),
    k_ME                 = log(K_ME),
    kappa_t              = k_ME - k_NR,
    omega_lag            = lag(omega_gross),
    p_kappa              = ifelse(is.na(p_kappa_ipmusa), p_kappa_rer, p_kappa_ipmusa),
    tot_log              = log(TERMINT_rebased),
    x_fob_log            = log(X_FOB),
    i_me_log             = log(I_ME_perez),
    m_cap_tot_log        = log(TERMINT_rebased * X_FOB),
    imbalance_lvl        = i_me_log - m_cap_tot_log
  ) %>%
  filter(year >= 1940 & year <= 2010, 
         !is.na(y_t), !is.na(k_NR), !is.na(kappa_t), !is.na(SolvR_M0)) %>%
  arrange(year)

# Total capital stock log proxy
df$k_tot <- log(df$K_ME + df$K_NR)

# Standardized components for Z_t
df$S_tilde <- scale(df$SolvR_M0)[, 1]
df$M_tilde <- scale(df$imbalance_lvl)[, 1]
df$Z_t     <- 0.2 * df$M_tilde + 0.8 * df$S_tilde
opt_gamma  <- 0.425

# Shading dataframe for Z_t <= 0.425
df$D_gamma <- ifelse(df$Z_t <= opt_gamma, 1, 0)
df$regime_change <- c(0, diff(df$D_gamma))

# Create contiguous regime blocks for background shading
r_starts <- which(df$regime_change == 1 | (df$D_gamma == 1 & row_number(df) == 1))
r_ends   <- which(df$regime_change == -1 | (df$D_gamma == 1 & row_number(df) == nrow(df)))

shading_blocks <- data.frame()
if (length(r_starts) > 0 && length(r_ends) > 0) {
  if (r_ends[1] < r_starts[1]) r_starts <- c(1, r_starts)
  if (length(r_starts) > length(r_ends)) r_ends <- c(r_ends, nrow(df))
  shading_blocks <- data.frame(
    xmin = df$year[r_starts],
    xmax = df$year[r_ends]
  )
}

# Output Directories
paper_fig_dir <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
paper_tab_dir <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "tables")
paper_fig_old <- file.path(repo_root, "chapter2_paper", "paper_tex_3.0", "figures")
paper_tab_old <- file.path(repo_root, "chapter2_paper", "paper_tex_3.0", "tables")
archive_fig_dir <- file.path(repo_root, "output", "CL", "figures")
archive_csv_dir <- file.path(repo_root, "output", "CL", "figures", "csv")

dir.create(paper_fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(paper_tab_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(paper_fig_old, recursive = TRUE, showWarnings = FALSE)
dir.create(paper_tab_old, recursive = TRUE, showWarnings = FALSE)
dir.create(archive_fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(archive_csv_dir, recursive = TRUE, showWarnings = FALSE)

save_plot_all <- function(fname_base, p, width = 8, height = 4.8) {
  for (d in c(paper_fig_dir, paper_fig_old, archive_fig_dir)) {
    ggsave(file.path(d, paste0(fname_base, ".pdf")), p, width = width, height = height, device = cairo_pdf)
    ggsave(file.path(d, paste0(fname_base, ".png")), p, width = width, height = height, dpi = 300)
  }
}

cat("========================================================================\n")
cat("Generating Chilean Stylized Facts (1a, 1b, 2, 3, 4a-4d) & Results Figures (1940-2010)\n")
cat("========================================================================\n")

# Color Palette (Academic PE)
c_navy    <- "#1A365D"
c_crimson <- "#9B2C2C"
c_forest  <- "#22543D"
c_amber   <- "#B7791F"
c_purple  <- "#6B46C1"
c_slate   <- "#4A5568"

# Theme with STRICT BLACK TEXT for all axis elements and legends
theme_pe <- function() {
  theme_minimal(base_size = 11) +
    theme(
      axis.title = element_text(face = "bold", size = 10, color = "#000000"),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 9, color = "#000000"),
      axis.text.y = element_text(size = 9, color = "#000000"),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#E2E8F0", linewidth = 0.4),
      legend.position = "bottom",
      legend.title = element_blank(),
      legend.text = element_text(size = 9.5, color = "#000000"),
      panel.border = element_rect(color = "#CBD5E0", fill = NA, linewidth = 0.6),
      plot.margin = margin(8, 12, 8, 8)
    )
}

# ---------------------------------------------------------------------------
# Chile Figure 1a: Log Real GDP vs Log Core Capital Stock (K_cap = K_ME + K_NRC)
# ---------------------------------------------------------------------------
df$k_cap <- log(df$K_ME + df$K_NR)

fig1a <- ggplot(df, aes(x = year)) +
  geom_vline(xintercept = c(1973, 1990), linetype = "dotted", color = c_slate, linewidth = 0.5) +
  geom_line(aes(y = y_t, color = "Log Real GDP"), linewidth = 1.0) +
  geom_line(aes(y = k_cap, color = "Log Core Capital Stock"), linewidth = 1.0, linetype = "dashed") +
  scale_color_manual(values = c(
    "Log Real GDP" = c_navy, 
    "Log Core Capital Stock" = c_crimson
  )) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(12, 22, by = 2)) +
  labs(x = "Year", y = "Log Level") +
  theme_pe()

save_plot_all("fig_cl_stylized_1a_y_kcap", fig1a, width = 8, height = 4.8)
save_plot_all("fig_cl_stylized_1_y_kcomponents", fig1a, width = 8, height = 4.8)

# ---------------------------------------------------------------------------
# Chile Figure 1b: Log Output-Capital Ratio (Log Difference with LOESS & Mean Line)
# ---------------------------------------------------------------------------
df$yk_log <- df$y_t - df$k_cap
mean_yk_cl <- mean(df$yk_log, na.rm = TRUE)

fig1b <- ggplot(df, aes(x = year, y = yk_log)) +
  geom_vline(xintercept = c(1973, 1990), linetype = "dotted", color = c_slate, linewidth = 0.5) +
  geom_hline(yintercept = mean_yk_cl, linetype = "dotted", color = c_slate, linewidth = 0.7) +
  geom_line(aes(color = "Observed Log Output-Capital Ratio"), linewidth = 0.95) +
  geom_smooth(aes(color = "LOESS Secular Trend"), method = "loess", span = 0.35, linetype = "dashed", se = FALSE, linewidth = 1.1) +
  scale_color_manual(values = c("Observed Log Output-Capital Ratio" = c_navy, "LOESS Secular Trend" = c_crimson)) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(-2.6, -1.4, by = 0.2), limits = c(-2.65, -1.35)) +
  labs(x = "Year", y = "Log Output-Capital Ratio") +
  theme_pe()

save_plot_all("fig_cl_stylized_1b_yk_ratio", fig1b, width = 8, height = 4.8)

# ---------------------------------------------------------------------------
# Chile Figure 2: Capital Composition & Mechanization Gap
# ---------------------------------------------------------------------------
fig2 <- ggplot(df, aes(x = year, y = kappa_t)) +
  geom_vline(xintercept = c(1973, 1990), linetype = "dotted", color = c_slate, linewidth = 0.6) +
  geom_line(aes(color = "Observed Mechanization Gap"), linewidth = 0.95) +
  geom_smooth(aes(color = "LOESS Secular Trend"), method = "loess", span = 0.35, se = FALSE, linewidth = 1.1, linetype = "dashed") +
  scale_color_manual(values = c("Observed Mechanization Gap" = c_navy, "LOESS Secular Trend" = c_crimson)) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(-2.5, 0.5, by = 0.5)) +
  labs(x = "Year", y = "Capital Composition Gap") +
  theme_pe()

save_plot_all("fig_cl_stylized_2_kappa_mechanization", fig2, width = 8, height = 4.5)

# ---------------------------------------------------------------------------
# Chile Figure 3: Peripheral Distributive Trajectory (Gross vs Net Wage Share)
# ---------------------------------------------------------------------------
fig3 <- ggplot(df, aes(x = year)) +
  geom_vline(xintercept = c(1973, 1990), linetype = "dotted", color = c_slate, linewidth = 0.6) +
  geom_line(aes(y = omega_gross, color = "Gross Wage Share"), linewidth = 1.0) +
  geom_line(aes(y = omega_net, color = "Net Wage Share"), linewidth = 1.0, linetype = "dashed") +
  scale_color_manual(values = c("Gross Wage Share" = c_navy, "Net Wage Share" = c_crimson)) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(0.30, 1.00, by = 0.10), limits = c(0.30, 1.02)) +
  labs(x = "Year", y = "Wage Share") +
  theme_pe()

save_plot_all("fig_cl_stylized_3_wage_share", fig3, width = 8, height = 4.8)

# ---------------------------------------------------------------------------
# STYLIZED FACTS: 4 STANDALONE RAW SERIES FIGURES (4a, 4b, 4c, 4d)
# ---------------------------------------------------------------------------

# Fig 4a: Central Bank Solvency Ratio (SolvR_M0)
fig4a <- ggplot(df, aes(x = year, y = SolvR_M0)) +
  geom_vline(xintercept = c(1973, 1990), linetype = "dotted", color = c_slate, linewidth = 0.6) +
  geom_line(color = c_purple, linewidth = 1.0) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(-0.5, 7.0, by = 1.0)) +
  labs(x = "Year", y = "Central Bank Solvency Ratio") +
  theme_pe()

save_plot_all("fig_cl_stylized_4a_external_constraint", fig4a, width = 8, height = 4.5)

# Fig 4b: Log Terms of Trade
fig4b <- ggplot(df, aes(x = year, y = tot_log)) +
  geom_vline(xintercept = c(1973, 1990), linetype = "dotted", color = c_slate, linewidth = 0.6) +
  geom_line(color = c_amber, linewidth = 1.0) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(-0.5, 1.0, by = 0.25)) +
  labs(x = "Year", y = "Log Terms of Trade") +
  theme_pe()

save_plot_all("fig_cl_stylized_4b_external_constraint", fig4b, width = 8, height = 4.5)

# Fig 4c: Log Real Exports
fig4c <- ggplot(df, aes(x = year, y = x_fob_log)) +
  geom_vline(xintercept = c(1973, 1990), linetype = "dotted", color = c_slate, linewidth = 0.6) +
  geom_line(color = c_forest, linewidth = 1.0) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(11.0, 17.0, by = 1.0)) +
  labs(x = "Year", y = "Log Real Exports") +
  theme_pe()

save_plot_all("fig_cl_stylized_4c_external_constraint", fig4c, width = 8, height = 4.5)

# Fig 4d: Log Machinery Investment
fig4d <- ggplot(df, aes(x = year, y = i_me_log)) +
  geom_vline(xintercept = c(1973, 1990), linetype = "dotted", color = c_slate, linewidth = 0.6) +
  geom_line(color = c_navy, linewidth = 1.0) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(8.0, 17.0, by = 1.5)) +
  labs(x = "Year", y = "Log Machinery Investment") +
  theme_pe()

save_plot_all("fig_cl_stylized_4d_external_constraint", fig4d, width = 8, height = 4.5)

# Backward-compatible 4-panel composite figure
fig4_composite <- grid.arrange(fig4a, fig4b, fig4c, fig4d, ncol = 2)
save_plot_all("fig_cl_stylized_4_external_constraint", fig4_composite, width = 10, height = 7.5)

# ---------------------------------------------------------------------------
# RESULTS SECTION: COMPOSITE Z_t INDEX & THRESHOLD CLASSIFICATION (Option B)
# ---------------------------------------------------------------------------
fig_results_z <- ggplot(df, aes(x = year)) +
  { if (nrow(shading_blocks) > 0) geom_rect(data = shading_blocks, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -3.0, ymax = 3.0),
            fill = "#EDF2F7", alpha = 0.7) } +
  geom_hline(yintercept = opt_gamma, linetype = "dashed", color = c_crimson, linewidth = 0.8) +
  geom_line(aes(y = S_tilde, color = "Solvency Ratio (S_tilde)"), linewidth = 0.9, linetype = "twodash") +
  geom_line(aes(y = M_tilde, color = "Import Imbalance (M_tilde)"), linewidth = 0.9, linetype = "dotted") +
  geom_line(aes(y = Z_t, color = "Composite Index (Z_t)"), linewidth = 1.2, linetype = "solid") +
  scale_color_manual(values = c(
    "Solvency Ratio (S_tilde)" = c_purple,
    "Import Imbalance (M_tilde)" = c_crimson,
    "Composite Index (Z_t)" = "#000000"
  )) +
  scale_x_continuous(breaks = seq(1940, 2010, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(-3.0, 3.0, by = 0.5), limits = c(-3.0, 3.0)) +
  annotate("text", x = 1943, y = opt_gamma + 0.20, label = sprintf("Threshold gamma_hat = %.3f", opt_gamma), color = c_crimson, fontface = "bold", size = 3.3, hjust = 0) +
  labs(x = "Year", y = "Standardized Index Level") +
  theme_pe()

save_plot_all("fig_cl_results_z_index_threshold", fig_results_z, width = 8.5, height = 5.2)

# ---------------------------------------------------------------------------
# Chile Table 2: Summary Statistics of Chilean Stylized Facts (1940-2010)
# ---------------------------------------------------------------------------
summary_cl <- df %>%
  summarize(
    Mean_y = mean(y_t, na.rm=T), SD_y = sd(y_t, na.rm=T),
    Mean_k = mean(k_cap, na.rm=T), SD_k = sd(k_cap, na.rm=T),
    Mean_yk_log = mean(yk_log, na.rm=T), SD_yk_log = sd(yk_log, na.rm=T),
    Mean_kappa = mean(kappa_t, na.rm=T), SD_kappa = sd(kappa_t, na.rm=T),
    Mean_w_gross = mean(omega_gross, na.rm=T), SD_w_gross = sd(omega_gross, na.rm=T),
    Mean_w_net = mean(omega_net, na.rm=T), SD_w_net = sd(omega_net, na.rm=T),
    Mean_solv = mean(SolvR_M0, na.rm=T), SD_solv = sd(SolvR_M0, na.rm=T),
    Mean_tot = mean(tot_log, na.rm=T), SD_tot = sd(tot_log, na.rm=T),
    Mean_x = mean(x_fob_log, na.rm=T), SD_x = sd(x_fob_log, na.rm=T),
    Mean_ime = mean(i_me_log, na.rm=T), SD_ime = sd(i_me_log, na.rm=T)
  )

tab_cl_csv <- data.frame(
  Variable = c("Log Real GDP", "Log Core Capital Stock", "Log Output-Capital Ratio", "Capital Composition Gap", 
               "Gross Wage Share", "Net Wage Share", 
               "Central Bank Solvency Ratio", "Log Terms of Trade", "Log Real Exports", "Log Machinery Investment"),
  Mean = c(summary_cl$Mean_y, summary_cl$Mean_k, summary_cl$Mean_yk_log, summary_cl$Mean_kappa, summary_cl$Mean_w_gross, summary_cl$Mean_w_net, summary_cl$Mean_solv, summary_cl$Mean_tot, summary_cl$Mean_x, summary_cl$Mean_ime),
  Std_Dev = c(summary_cl$SD_y, summary_cl$SD_k, summary_cl$SD_yk_log, summary_cl$SD_kappa, summary_cl$SD_w_gross, summary_cl$SD_w_net, summary_cl$SD_solv, summary_cl$SD_tot, summary_cl$SD_x, summary_cl$SD_ime)
)

tab_cl_tex <- paste0(
"\\begin{table}[H]\n",
"\\centering\n",
"\\footnotesize\n",
"\\caption{Chile Descriptive Statistics (1940--2010)}\n",
"\\label{tab:cl_stylized_facts_summary}\n",
"\\begin{tabular}{p{7.5cm} p{2.5cm} p{2.5cm}}\n",
"\\hline\\hline\n",
"\\textbf{Variable} & \\textbf{Mean} & \\textbf{Std. Dev.} \\\\\n",
"\\hline\n",
sprintf("Log Real GDP ($y_t$) & %.3f & %.3f \\\\\n", summary_cl$Mean_y, summary_cl$SD_y),
sprintf("Log Core Capital Stock ($k_t^{cap}$) & %.3f & %.3f \\\\\n", summary_cl$Mean_k, summary_cl$SD_k),
sprintf("Log Output--Capital Ratio ($y_t - k_t^{cap}$) & %.3f & %.3f \\\\\n", summary_cl$Mean_yk_log, summary_cl$SD_yk_log),
sprintf("Capital Composition Gap ($\\kappa_t$) & %.3f & %.3f \\\\\n", summary_cl$Mean_kappa, summary_cl$SD_kappa),
sprintf("Gross Wage Share ($\\omega_t^{gross}$) & %.3f & %.3f \\\\\n", summary_cl$Mean_w_gross, summary_cl$SD_w_gross),
sprintf("Net Wage Share ($\\omega_t^{net}$) & %.3f & %.3f \\\\\n", summary_cl$Mean_w_net, summary_cl$SD_w_net),
sprintf("Central Bank Solvency Ratio ($S_t$) & %.3f & %.3f \\\\\n", summary_cl$Mean_solv, summary_cl$SD_solv),
sprintf("Log Terms of Trade ($\\ln \\text{ToT}_t$) & %.3f & %.3f \\\\\n", summary_cl$Mean_tot, summary_cl$SD_tot),
sprintf("Log Real Exports ($\\ln X_{\\text{FOB},t}$) & %.3f & %.3f \\\\\n", summary_cl$Mean_x, summary_cl$SD_x),
sprintf("Log Machinery Investment ($\\ln I_t^{\\text{ME}}$) & %.3f & %.3f \\\\\n", summary_cl$Mean_ime, summary_cl$SD_ime),
"\\hline\\hline\n",
"\\multicolumn{3}{p{12.5cm}}{\\scriptsize \\textbf{Note:} Sample window spans 1940--2010 ($N = 71$). Real GDP and capital stock components sourced from Díaz, Lüders and Wagner (2016) and Pérez and Eyzaguirre (2021). Core capital stock is $K_t^{cap} = K_t^{\\text{ME}} + K_t^{\\text{NRC}}$. Capital composition gap $\\kappa_t = k_t^{\\text{ME}} - k_t^{\\text{NRC}}$. Both Gross wage share (nominal compensation / nominal GDP) and Net wage share (nominal compensation / nominal NVA) are evaluated in nominal terms. Structural threshold $\\hat{\\gamma} = 0.425$ separates binding foreign exchange bottleneck regimes.} \\\\\n",
"\\end{tabular}\n",
"\\end{table}\n"
)

for (d in c(paper_tab_dir, paper_tab_old, archive_csv_dir)) {
  write.csv(tab_cl_csv, file.path(d, "tab_cl_stylized_facts_summary.csv"), row.names = FALSE)
}

for (d in c(paper_tab_dir, paper_tab_old)) {
  writeLines(tab_cl_tex, file.path(d, "tab_cl_stylized_facts_summary.tex"))
}

cat("Updated Chilean Stylized Facts (1a, 1b, 2, 3, 4a-4d) & Results Z-Index figures successfully generated!\n")


