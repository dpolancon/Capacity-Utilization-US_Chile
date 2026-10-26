#!/usr/bin/env Rscript

# US_S60_generate_stylized_facts_figures.R
# ---------------------------------------------------------------------------
# US Stylized Facts Visualization & Data Table Engine (Section 4.1.8)
#
# Revisions applied:
#   - All math symbols stripped from Y-axis labels and legends for clean publication presentation
#   - Axis and legend font color strictly set to black (#000000)
#   - Full-sample net wage share uses omega_ST_Tier1_NVA_lag1 (1930-2025)
#   - LOESS trend curves dashed for clean visual contrast against solid data lines
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
f_in <- file.path(repo_root, "output", "gpim_specB_components_long.csv")
if (!file.exists(f_in)) stop("Missing US specB components CSV at: ", f_in)

df_all <- read.csv(f_in, stringsAsFactors = FALSE)
df <- df_all %>%
  filter(year >= 1931 & year <= 2024) %>%
  arrange(year)

# Ensure required variables exist
if (!"iota_t" %in% colnames(df)) {
  df$iota_t <- df$IPP_share_capital_plus_IPP
}
df$iota_lag1 <- dplyr::lag(df$iota_t, 1L)

# Use Tier 1 / NFC net wage share for full 1931-2024 continuity
w_var <- if ("omega_ST_Tier1_NVA_lag1" %in% colnames(df) && !all(is.na(df$omega_ST_Tier1_NVA_lag1[df$year < 1948]))) {
  "omega_ST_Tier1_NVA_lag1"
} else {
  "omega_NFC_NVA_lag1"
}
df$omega_lag <- df[[w_var]]
df$eff_wage_pressure <- df$omega_lag * (1 - df$iota_lag1)

# Growth rates
df$dy <- c(NA, diff(df$y_t))
df$dk <- c(NA, diff(df$k_cap))

# Output Directories
paper_fig_dir <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
paper_tab_dir <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "tables")
paper_fig_old <- file.path(repo_root, "chapter2_paper", "paper_tex_3.0", "figures")
paper_tab_old <- file.path(repo_root, "chapter2_paper", "paper_tex_3.0", "tables")
archive_fig_dir <- file.path(repo_root, "output", "US", "figures")
archive_csv_dir <- file.path(repo_root, "output", "US", "figures", "csv")

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
cat("Generating US Stylized Facts Figures without Math Symbols in Y-Axes (1931-2024)\n")
cat("========================================================================\n")

# Color Palette (Academic PE)
c_navy    <- "#1A365D"
c_crimson <- "#9B2C2C"
c_forest  <- "#22543D"
c_amber   <- "#B7791F"
c_slate   <- "#4A5568"

# NBER Recession Shading Data (1931-2024 approximation for background bands)
nber_recessions <- data.frame(
  xmin = c(1937, 1945, 1948.8, 1953.5, 1957.6, 1960.3, 1969.9, 1973.9, 1980.1, 1981.5, 1990.5, 2001.2, 2007.9, 2020.1),
  xmax = c(1938.4, 1945.8, 1949.8, 1954.4, 1958.3, 1961.1, 1970.9, 1975.2, 1980.6, 1982.9, 1991.2, 2001.8, 2009.5, 2020.3)
)
nber_recessions <- nber_recessions %>% filter(xmin >= 1931 & xmax <= 2024)

# Theme with STRICT BLACK TEXT for all axis elements and legends
theme_pe <- function() {
  theme_minimal(base_size = 11) +
    theme(
      axis.title = element_text(face = "bold", size = 10, color = "#000000"),
      axis.title.y.right = element_text(face = "bold", size = 10, color = "#000000", angle = 90, vjust = 1),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, size = 9, color = "#000000"),
      axis.text.y = element_text(size = 9, color = "#000000"),
      axis.text.y.right = element_text(size = 9, color = "#000000"),
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
# US Figure 1: Log Real Output vs Log Core Capital Stock (Single Top Panel Only)
# ---------------------------------------------------------------------------
fig1 <- ggplot(df, aes(x = year)) +
  geom_rect(data = nber_recessions, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            fill = "#EDF2F7", alpha = 0.7) +
  geom_line(aes(y = y_t, color = "Log Real NFC Output"), linewidth = 1.0) +
  geom_line(aes(y = k_cap, color = "Log Core Capital Stock"), linewidth = 1.0, linetype = "dashed") +
  scale_color_manual(values = c("Log Real NFC Output" = c_navy, "Log Core Capital Stock" = c_crimson)) +
  scale_x_continuous(breaks = seq(1930, 2025, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(11, 17, by = 1)) +
  labs(x = "Year", y = "Log Level") +
  theme_pe()

save_plot_all("fig_us_stylized_1_y_kcap", fig1, width = 8, height = 4.8)

# ---------------------------------------------------------------------------
# US Figure 2: Log Output-Capital Ratio (Log Difference with LOESS & Mean Line)
# ---------------------------------------------------------------------------
df$yk_log <- df$y_t - df$k_cap
mean_yk <- mean(df$yk_log, na.rm = TRUE)

fig2 <- ggplot(df, aes(x = year, y = yk_log)) +
  geom_rect(data = nber_recessions, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            fill = "#EDF2F7", alpha = 0.7) +
  geom_hline(yintercept = mean_yk, linetype = "dotted", color = c_slate, linewidth = 0.7) +
  geom_line(aes(color = "Observed Log Output-Capital Ratio"), linewidth = 0.95) +
  geom_smooth(aes(color = "LOESS Secular Trend"), method = "loess", span = 0.35, linetype = "dashed", se = FALSE, linewidth = 1.1) +
  scale_color_manual(values = c("Observed Log Output-Capital Ratio" = c_navy, "LOESS Secular Trend" = c_crimson)) +
  scale_x_continuous(breaks = seq(1930, 2025, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(-0.6, 2.0, by = 0.4), limits = c(-0.65, 2.05)) +
  labs(x = "Year", y = "Log Output-Capital Ratio") +
  theme_pe()

save_plot_all("fig_us_stylized_2_yk_ratio", fig2, width = 8, height = 4.8)

# ---------------------------------------------------------------------------
# US Figure 2b: Capital Composition & Mechanization Gap (k_ME - k_NRC)
# ---------------------------------------------------------------------------
df$kappa_t <- df$k_ME - df$k_NRC
mean_kappa_us <- mean(df$kappa_t, na.rm = TRUE)

fig2b <- ggplot(df, aes(x = year, y = kappa_t)) +
  geom_rect(data = nber_recessions, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            fill = "#EDF2F7", alpha = 0.7) +
  geom_hline(yintercept = mean_kappa_us, linetype = "dotted", color = c_slate, linewidth = 0.7) +
  geom_line(aes(color = "Observed Mechanization Gap"), linewidth = 0.95) +
  geom_smooth(aes(color = "LOESS Secular Trend"), method = "loess", span = 0.35, linetype = "dashed", se = FALSE, linewidth = 1.1) +
  scale_color_manual(values = c("Observed Mechanization Gap" = c_navy, "LOESS Secular Trend" = c_crimson)) +
  scale_x_continuous(breaks = seq(1930, 2025, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(-1.4, -0.2, by = 0.2), limits = c(-1.35, -0.20)) +
  labs(x = "Year", y = "Capital Composition Gap") +
  theme_pe()

save_plot_all("fig_us_stylized_2b_kappa", fig2b, width = 8, height = 4.8)
save_plot_all("us_stylized_2b_kappa", fig2b, width = 8, height = 4.8)

# ---------------------------------------------------------------------------
# US Figure 3: Annual Growth Rates — Output vs Capital
# ---------------------------------------------------------------------------
df_growth <- df %>% filter(!is.na(dy) & !is.na(dk))

fig3 <- ggplot(df_growth, aes(x = year)) +
  geom_rect(data = nber_recessions, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            fill = "#EDF2F7", alpha = 0.7) +
  geom_hline(yintercept = 0, color = "#000000", linetype = "solid", linewidth = 0.4) +
  geom_line(aes(y = dy, color = "Output Growth"), linewidth = 0.85) +
  geom_line(aes(y = dk, color = "Capital Growth"), linewidth = 1.1, linetype = "dashed") +
  scale_color_manual(values = c("Output Growth" = c_navy, "Capital Growth" = c_forest)) +
  scale_x_continuous(breaks = seq(1930, 2025, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(-0.20, 0.20, by = 0.05)) +
  labs(x = "Year", y = "Annual Log Growth Rate") +
  theme_pe()

save_plot_all("fig_us_stylized_3_growth_rates", fig3, width = 8, height = 4.8)

# ---------------------------------------------------------------------------
# US Figure 4a: Distributive State — Non-Redundant Wage Share Permutations
# ---------------------------------------------------------------------------
# Key non-redundant permutations across Value-Added bases (NVA vs GVA) and supervisory adjustments (Tier 1 vs Tier 2)
perms <- list(
  list(var = "omega_CORP_NVA_clean_Tier1_lag1", label = "Clean Corporate Tier 1 (NVA, Preferred)", col = "#1A365D", lty = "solid", lwd = 1.15),
  list(var = "omega_CORP_GVA_clean_Tier1_lag1", label = "Clean Corporate Tier 1 (GVA)",           col = "#3182CE", lty = "solid", lwd = 0.85),
  list(var = "omega_CORP_NVA_clean_Tier2_lag1", label = "Clean Corporate Tier 2 (NVA Super)",     col = "#9B2C2C", lty = "dashed", lwd = 0.95),
  list(var = "omega_ST_Tier1_NVA_lag1",         label = "Shaikh-Tonak Tier 1 (NVA)",             col = "#22543D", lty = "solid", lwd = 0.85),
  list(var = "omega_ST_Tier1_GVA_lag1",         label = "Shaikh-Tonak Tier 1 (GVA)",             col = "#38A169", lty = "solid", lwd = 0.85),
  list(var = "omega_ST_Tier2_NVA_lag1",         label = "Shaikh-Tonak Tier 2 (NVA Super)",       col = "#D69E2E", lty = "dashed", lwd = 0.85)
)

df$omega_net_lag   <- if ("omega_ST_Tier1_NVA_lag1" %in% colnames(df)) df$omega_ST_Tier1_NVA_lag1 else df$omega_NFC_NVA_lag1
df$omega_gross_lag <- if ("omega_ST_Tier1_GVA_lag1" %in% colnames(df)) df$omega_ST_Tier1_GVA_lag1 else df$omega_NFC_GVA_lag1

df_4a_list <- list()
df_4b_list <- list()

for (p in perms) {
  if (p$var %in% colnames(df)) {
    val_4a <- df[[p$var]]
    val_4b <- val_4a * (1 - df$iota_lag1)
    
    df_4a_list[[p$label]] <- data.frame(
      year = df$year,
      value = val_4a,
      label = p$label,
      stringsAsFactors = FALSE
    )
    
    df_4b_list[[p$label]] <- data.frame(
      year = df$year,
      value = val_4b,
      label = p$label,
      stringsAsFactors = FALSE
    )
  }
}

df_4a_long <- bind_rows(df_4a_list)
df_4b_long <- bind_rows(df_4b_list)

lbl_order  <- sapply(perms, function(x) x$label)
color_vals <- setNames(sapply(perms, function(x) x$col), lbl_order)
lty_vals   <- setNames(sapply(perms, function(x) x$lty), lbl_order)
lwd_vals   <- setNames(sapply(perms, function(x) x$lwd), lbl_order)

df_4a_long$label <- factor(df_4a_long$label, levels = lbl_order)
df_4b_long$label <- factor(df_4b_long$label, levels = lbl_order)

fig4a <- ggplot(df_4a_long, aes(x = year, y = value, color = label, linetype = label, linewidth = label)) +
  geom_rect(data = nber_recessions, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            fill = "#EDF2F7", alpha = 0.7) +
  geom_line() +
  scale_color_manual(values = color_vals) +
  scale_linetype_manual(values = lty_vals) +
  scale_discrete_manual("linewidth", values = lwd_vals) +
  scale_x_continuous(breaks = seq(1930, 2025, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(0.35, 0.90, by = 0.10), limits = c(0.34, 0.92)) +
  labs(x = "Year", y = "Wage Share") +
  guides(color = guide_legend(ncol = 2, byrow = TRUE)) +
  theme_pe() +
  theme(legend.text = element_text(size = 9.0, color = "#000000"))

save_plot_all("fig_us_stylized_4a_distributive_state", fig4a, width = 8.5, height = 5.2)

# ---------------------------------------------------------------------------
# US Figure 4b: Effective Wage Pressure Permutations Scaled by (1 - iota), No LOESS
# ---------------------------------------------------------------------------
fig4b <- ggplot(df_4b_long, aes(x = year, y = value, color = label, linetype = label, linewidth = label)) +
  geom_rect(data = nber_recessions, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
            fill = "#EDF2F7", alpha = 0.7) +
  geom_line() +
  scale_color_manual(values = color_vals) +
  scale_linetype_manual(values = lty_vals) +
  scale_discrete_manual("linewidth", values = lwd_vals) +
  scale_x_continuous(breaks = seq(1930, 2025, by = 5), expand = expansion(mult = c(0.01, 0.01))) +
  scale_y_continuous(breaks = seq(0.30, 0.85, by = 0.10), limits = c(0.28, 0.88)) +
  labs(x = "Year", y = "Effective Wage Pressure") +
  guides(color = guide_legend(ncol = 2, byrow = TRUE)) +
  theme_pe() +
  theme(legend.text = element_text(size = 9.0, color = "#000000"))

save_plot_all("fig_us_stylized_4b_distributive_state", fig4b, width = 8.5, height = 5.2)

# Backward-compatible stacked Figure 4 export
fig4_stacked <- grid.arrange(fig4a, fig4b, ncol = 1)
save_plot_all("fig_us_stylized_4_distributive_state", fig4_stacked, width = 8.5, height = 9.5)

# ---------------------------------------------------------------------------
# US Table 1: Summary Statistics of US Stylized Facts (1931-2024)
# ---------------------------------------------------------------------------
summary_us <- df %>%
  summarize(
    Mean_y = mean(y_t, na.rm=T), SD_y = sd(y_t, na.rm=T),
    Mean_k = mean(k_cap, na.rm=T), SD_k = sd(k_cap, na.rm=T),
    Mean_yk_log = mean(yk_log, na.rm=T), SD_yk_log = sd(yk_log, na.rm=T),
    Mean_kappa = mean(kappa_t, na.rm=T), SD_kappa = sd(kappa_t, na.rm=T),
    Mean_dy = mean(dy, na.rm=T), SD_dy = sd(dy, na.rm=T),
    Mean_dk = mean(dk, na.rm=T), SD_dk = sd(dk, na.rm=T),
    Mean_w_net = mean(omega_net_lag, na.rm=T), SD_w_net = sd(omega_net_lag, na.rm=T),
    Mean_w_gross = mean(omega_gross_lag, na.rm=T), SD_w_gross = sd(omega_gross_lag, na.rm=T),
    Mean_iota = mean(iota_lag1, na.rm=T), SD_iota = sd(iota_lag1, na.rm=T),
    Mean_C = mean(eff_wage_pressure, na.rm=T), SD_C = sd(eff_wage_pressure, na.rm=T)
  )

tab_us_csv <- data.frame(
  Variable = c("Log Real NFC Output", "Log Core Capital Stock", "Log Output-Capital Ratio", 
               "Mechanization Gap", "Output Growth", "Capital Growth", "Net Wage Share", "Gross Wage Share", 
               "IPP Capital Share", "Effective Wage Pressure"),
  Mean = c(summary_us$Mean_y, summary_us$Mean_k, summary_us$Mean_yk_log, summary_us$Mean_kappa, summary_us$Mean_dy, summary_us$Mean_dk, summary_us$Mean_w_net, summary_us$Mean_w_gross, summary_us$Mean_iota, summary_us$Mean_C),
  Std_Dev = c(summary_us$SD_y, summary_us$SD_k, summary_us$SD_yk_log, summary_us$SD_kappa, summary_us$SD_dy, summary_us$SD_dk, summary_us$SD_w_net, summary_us$SD_w_gross, summary_us$SD_iota, summary_us$SD_C)
)

tab_us_tex <- paste0(
"\\begin{table}[H]\n",
"\\centering\n",
"\\caption{United States Macroeconomic and Distributive Summary Statistics (1931--2024)}\n",
"\\label{tab:us_stylized_facts_summary}\n",
"\\begin{tabular}{p{7.5cm} p{2.5cm} p{2.5cm}}\n",
"\\hline\\hline\n",
"\\textbf{Variable} & \\textbf{Mean} & \\textbf{Std. Dev.} \\\\\n",
"\\hline\n",
sprintf("Log Real Output ($y_t$) & %.3f & %.3f \\\\\n", summary_us$Mean_y, summary_us$SD_y),
sprintf("Log Core Capital Stock ($k_t^{cap}$) & %.3f & %.3f \\\\\n", summary_us$Mean_k, summary_us$SD_k),
sprintf("Log Output--Capital Ratio ($y_t - k_t^{cap}$) & %.3f & %.3f \\\\\n", summary_us$Mean_yk_log, summary_us$SD_yk_log),
sprintf("Mechanization Gap ($\\kappa_t = k_t^{\\text{ME}} - k_t^{\\text{NRC}}$) & %.3f & %.3f \\\\\n", summary_us$Mean_kappa, summary_us$SD_kappa),
sprintf("Annual Output Growth ($\\Delta y_t$) & %.3f & %.3f \\\\\n", summary_us$Mean_dy, summary_us$SD_dy),
sprintf("Annual Capital Growth ($\\Delta k_t^{cap}$) & %.3f & %.3f \\\\\n", summary_us$Mean_dk, summary_us$SD_dk),
sprintf("Net Wage Share ($\\omega_{t-1}^{\\text{net}}$) & %.3f & %.3f \\\\\n", summary_us$Mean_w_net, summary_us$SD_w_net),
sprintf("Gross Wage Share ($\\omega_{t-1}^{\\text{gross}}$) & %.3f & %.3f \\\\\n", summary_us$Mean_w_gross, summary_us$SD_w_gross),
sprintf("IPP Capital Share ($\\iota_{t-1}$) & %.3f & %.3f \\\\\n", summary_us$Mean_iota, summary_us$SD_iota),
sprintf("Effective Wage Pressure ($C_t$) & %.3f & %.3f \\\\\n", summary_us$Mean_C, summary_us$SD_C),
"\\hline\\hline\n",
"\\multicolumn{3}{p{13.0cm}}{\\footnotesize \\textbf{Note:} Sample window spans 1931--2024 ($N = 94$). Output $y_t$ is non-financial corporate real gross value added. Core capital $k_t^{cap}$ comprises machinery, equipment, and non-residential structures ($K_{\\text{ME}} + K_{\\text{NRC}}$). Mechanization gap $\\kappa_t = k_t^{\\text{ME}} - k_t^{\\text{NRC}}$ measures the capital composition ratio. Net wage share ($\\omega^{\\text{net}} = \\text{Compensation} / \\text{NVA}$) and Gross wage share ($\\omega^{\\text{gross}} = \\text{Compensation} / \\text{GVA}$) are both evaluated in nominal terms. IPP capital share $\\iota_{t-1} = K_{\\text{IPP}} / (K_{\\text{cap}} + K_{\\text{IPP}})$. Effective wage pressure $C_t = \\omega_{t-1}(1 - \\iota_{t-1})$. Data sources: BEA NIPA Tables and Fixed Assets Accounts.} \\\\\n",
"\\end{tabular}\n",
"\\end{table}\n"
)

for (d in c(paper_tab_dir, paper_tab_old, archive_csv_dir)) {
  write.csv(tab_us_csv, file.path(d, "tab_us_stylized_facts_summary.csv"), row.names = FALSE)
}

for (d in c(paper_tab_dir, paper_tab_old)) {
  writeLines(tab_us_tex, file.path(d, "tab_us_stylized_facts_summary.tex"))
}

cat("US Stylized Facts figures and summary table successfully generated!\n")



