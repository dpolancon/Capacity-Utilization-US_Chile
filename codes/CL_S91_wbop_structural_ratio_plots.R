# codes/CL_S91_wbop_structural_ratio_plots.R
# Purpose: Generate plots for structural trade, mechanization bottleneck, financial subordination,
# and external balance sheet leverage ratios for Chile (1920-2024) from WBOP database (Nievas & Piketty, 2025).

library(dplyr, warn.conflicts = FALSE)
library(readr)
library(readxl)
library(ggplot2)
library(tidyr)
library(scales)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(repo_root)

# 1. Setup Output Directory
out_dir <- "reports/CHILE_solv_lev_ratio_plots"
if (!dir.exists(out_dir)) {
  dir.create(out_dir, recursive = TRUE)
}

# Also ensure reports/CL_import_capacity has the updated plots
alt_out_dir <- "reports/CL_import_capacity"
if (!dir.exists(alt_out_dir)) {
  dir.create(alt_out_dir, recursive = TRUE)
}

# 2. Helper to load a sheet for Chile (CL)
wbop_path <- "data/raw/Chile/WBOP/NievasPiketty2025WBOPFinalSeries.xlsx"

get_wbop_series <- function(sheet_name, col_label) {
  d <- read_excel(wbop_path, sheet = sheet_name, skip = 2)
  # Row 3 had header, row 4 starts data, let's find 'CL' column
  cl_col <- which(colnames(d) == "CL")
  if (length(cl_col) == 0) {
    # Try case-insensitive grep
    cl_col <- grep("^CL$", colnames(d), ignore.case = TRUE)
  }
  
  if (length(cl_col) == 0) {
    stop(paste("Column CL not found in sheet", sheet_name))
  }
  
  df_res <- data.frame(
    year = as.numeric(d[[1]]),
    val = as.numeric(d[[cl_col[1]]])
  )
  colnames(df_res)[2] <- col_label
  df_res <- df_res %>% filter(!is.na(year))
  return(df_res)
}

# Load all relevant WBOP sheets
# A1: GDP
# B1a: Net goods trade (% GDP), B1b: Goods exports (% GDP), B1c: Goods imports (% GDP)
# B2a: Net primary trade (% GDP), B2b: Primary exports (% GDP), B2c: Primary imports (% GDP)
# B3a: Net manuf trade (% GDP), B3b: Manuf exports (% GDP), B3c: Manuf imports (% GDP)
# C1a: Net services trade (% GDP), C1b: Services exports (% GDP), C1c: Services imports (% GDP)
# C1d: Net goods+services (% GDP), C1e: Goods+services exports (% GDP), C1f: Goods+services imports (% GDP)
# D1a: Net income balance (% GDP), D1b: Foreign income inflows (% GDP), D1c: Foreign income outflows (% GDP)
# E1a: Net transfer balance (% GDP), E1b: Transfer inflows (% GDP), E1c: Transfer outflows (% GDP)
# F1: Net current account (% GDP)
# G1a: Net foreign wealth / NIIP (% GDP), G1b: Gross foreign assets (% GDP), G1c: Gross foreign liabilities (% GDP)

cat("Extracting WBOP series for Chile...\n")
sheets_to_extract <- list(
  c("A1", "gdp_usd"),
  c("B1a", "tb_goods_gdp"),
  c("B1b", "x_goods_gdp"),
  c("B1c", "m_goods_gdp"),
  c("B2a", "tb_prim_gdp"),
  c("B2b", "x_prim_gdp"),
  c("B2c", "m_prim_gdp"),
  c("B3a", "tb_manuf_gdp"),
  c("B3b", "x_manuf_gdp"),
  c("B3c", "m_manuf_gdp"),
  c("C1a", "tb_serv_gdp"),
  c("C1b", "x_serv_gdp"),
  c("C1c", "m_serv_gdp"),
  c("C1d", "tb_tot_gdp"),
  c("C1e", "x_tot_gdp"),
  c("C1f", "m_tot_gdp"),
  c("D1a", "net_inc_gdp"),
  c("D1b", "inc_inflow_gdp"),
  c("D1c", "inc_outflow_gdp"),
  c("F1", "ca_gdp"),
  c("G1a", "niip_gdp"),
  c("G1b", "nfa_assets_gdp"),
  c("G1c", "nfa_liab_gdp")
)

wbop_all <- data.frame(year = 1800:2025)

for (item in sheets_to_extract) {
  s_name <- item[1]
  c_name <- item[2]
  s_df <- get_wbop_series(s_name, c_name)
  wbop_all <- left_join(wbop_all, s_df, by = "year")
}

# 3. Filter to 1920-2024 and Compute Ratios
df_cl <- wbop_all %>%
  filter(year >= 1920 & year <= 2024) %>%
  mutate(
    # 1. Mechanization Import Burden: Manuf Imports / Total Exports
    # If x_tot_gdp is NA in some year, fallback to x_goods_gdp
    x_total_used = ifelse(!is.na(x_tot_gdp), x_tot_gdp, x_goods_gdp),
    R_manuf_exp = m_manuf_gdp / x_total_used,
    
    # 2. Prebisch-Singer Bottleneck: Manuf Imports / Primary Exports
    R_prebisch_singer = m_manuf_gdp / x_prim_gdp,
    
    # 3. Extractivist Specialization: Primary Exports / Total Goods Exports
    share_prim_exp = (x_prim_gdp / x_goods_gdp) * 100,
    
    # 4. Financial Drainage / Surplus Extraction: Income Outflows / Total Exports
    drainage_exp_ratio = (inc_outflow_gdp / x_total_used) * 100,
    
    # 5. External Gross Balance Sheet Leverage: Gross Liabilities / Gross Assets
    ext_leverage_ratio = nfa_liab_gdp / nfa_assets_gdp,
    
    # 6. External Liabilities to Exports: Gross Liabilities / Total Exports
    liab_to_exp_ratio = nfa_liab_gdp / x_total_used
  )

# 4. Plotting Setup
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
    plot.title = element_text(face = "bold", size = 13, margin = margin(b = 8)),
    plot.subtitle = element_text(size = 10, margin = margin(b = 12)),
    axis.title = element_text(face = "bold", size = 10),
    axis.text = element_text(color = "black", size = 9),
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_line(color = "gray90"),
    panel.grid.major.y = element_line(color = "gray80", linetype = "dotted"),
    legend.position = "bottom",
    legend.title = element_blank(),
    strip.text = element_text(face = "bold", size = 11)
  )

save_plot <- function(plot_obj, name_prefix, w = 10, h = 5.8) {
  # Save in reports/CHILE_solv_lev_ratio_plots
  ggsave(filename = file.path(out_dir, paste0(name_prefix, ".pdf")), plot = plot_obj, width = w, height = h, device = cairo_pdf)
  ggsave(filename = file.path(out_dir, paste0(name_prefix, ".png")), plot = plot_obj, width = w, height = h, dpi = 300)
}

cat("Generating figures...\n")

# --- Figure 1: Mechanization Import Burden (R_t Manuf / Exports) ---
# Also known as CL_Import_ratioWBOP
p_import_ratio <- ggplot(df_cl %>% filter(!is.na(R_manuf_exp)), aes(x = year, y = R_manuf_exp)) +
  geom_line(color = "#d62728", linewidth = 0.9) +
  geom_point(color = "#d62728", size = 1.5, alpha = 0.7) +
  scale_x_continuous(breaks = seq(1920, 2024, by = 10), expand = c(0.02, 0.02)) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Mechanization Import Capacity Ratio in Chile (1920-2024)",
    subtitle = "Ratio of Manufactured Imports to Total Export Earnings (R_t = M_manuf / X_total)",
    y = expression(paste("Import Capacity Ratio (", R[t], ")")),
    x = "Year"
  ) +
  umass_theme
p_import_ratio <- add_annotations(p_import_ratio)
save_plot(p_import_ratio, "fig_wbop_import_ratio")
# Dual export to reports/CL_import_capacity
ggsave(file.path(alt_out_dir, "CL_import_ratio_WBOP.pdf"), plot = p_import_ratio, width = 10, height = 5.8, device = cairo_pdf)
ggsave(file.path(alt_out_dir, "CL_import_ratio_WBOP.png"), plot = p_import_ratio, width = 10, height = 5.8, dpi = 300)

# --- Figure 2: Prebisch-Singer Structural Bottleneck ---
p_prebisch <- ggplot(df_cl %>% filter(!is.na(R_prebisch_singer)), aes(x = year, y = R_prebisch_singer)) +
  geom_line(color = "#8c564b", linewidth = 0.9) +
  geom_point(color = "#8c564b", size = 1.5, alpha = 0.7) +
  scale_x_continuous(breaks = seq(1920, 2024, by = 10), expand = c(0.02, 0.02)) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Prebisch-Singer Structural Bottleneck Ratio in Chile (1920-2024)",
    subtitle = "Manufactured Imports Relative to Primary Commodity Exports (M_manuf / X_prim)",
    y = "Manufactures / Primary Exports Ratio",
    x = "Year"
  ) +
  umass_theme
p_prebisch <- add_annotations(p_prebisch)
save_plot(p_prebisch, "fig_wbop_prebisch_singer")

# --- Figure 3: Primary Commodity Export Specialization ---
p_extractivism <- ggplot(df_cl %>% filter(!is.na(share_prim_exp)), aes(x = year, y = share_prim_exp)) +
  geom_line(color = "#1f77b4", linewidth = 0.9) +
  geom_point(color = "#1f77b4", size = 1.5, alpha = 0.7) +
  geom_hline(yintercept = 80, linetype = "dotted", color = "gray40") +
  scale_x_continuous(breaks = seq(1920, 2024, by = 10), expand = c(0.02, 0.02)) +
  scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(50, 100)) +
  labs(
    title = "Primary Export Specialization / Extractivism in Chile (1920-2024)",
    subtitle = "Primary Commodity Exports as Percentage of Total Goods Exports (X_prim / X_goods)",
    y = "Primary Export Share (%)",
    x = "Year"
  ) +
  umass_theme
p_extractivism <- add_annotations(p_extractivism)
save_plot(p_extractivism, "fig_wbop_extractivism")

# --- Figure 4: Structural Trade Balance Decomposition (% GDP) ---
df_trade_long <- df_cl %>%
  select(year, tb_goods_gdp, tb_manuf_gdp, tb_prim_gdp, tb_serv_gdp) %>%
  pivot_longer(cols = -year, names_to = "component", values_to = "pct_gdp") %>%
  mutate(
    pct_gdp = pct_gdp * 100,
    component = factor(component, 
                       levels = c("tb_goods_gdp", "tb_prim_gdp", "tb_manuf_gdp", "tb_serv_gdp"),
                       labels = c("Total Goods Balance", "Primary Goods (Surplus)", "Manufactured Goods (Deficit)", "Services Balance"))
  ) %>%
  filter(!is.na(pct_gdp))

p_trade_decomp <- ggplot(df_trade_long, aes(x = year, y = pct_gdp, color = component, linetype = component)) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = c("Total Goods Balance" = "#333333", 
                                "Primary Goods (Surplus)" = "#2ca02c", 
                                "Manufactured Goods (Deficit)" = "#d62728", 
                                "Services Balance" = "#9467bd")) +
  scale_linetype_manual(values = c("Total Goods Balance" = "solid", 
                                  "Primary Goods (Surplus)" = "solid", 
                                  "Manufactured Goods (Deficit)" = "solid", 
                                  "Services Balance" = "dashed")) +
  scale_x_continuous(breaks = seq(1920, 2024, by = 10), expand = c(0.02, 0.02)) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "Sectoral Trade Balance Decomposition in Chile (1920-2024)",
    subtitle = "Trade Balances by Commodity Group as Percentage of GDP (% GDP)",
    y = "Balance (% GDP)",
    x = "Year"
  ) +
  umass_theme
p_trade_decomp <- add_annotations(p_trade_decomp)
save_plot(p_trade_decomp, "fig_wbop_trade_balances")

# --- Figure 5: Financial Subordination & Surplus Drainage ---
df_drainage <- df_cl %>%
  mutate(
    outflow_pct_gdp = inc_outflow_gdp * 100,
    net_inc_pct_gdp = net_inc_gdp * 100
  )

p_drainage <- ggplot(df_drainage, aes(x = year)) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
  geom_line(aes(y = outflow_pct_gdp, color = "Gross Income Outflow (% GDP)"), linewidth = 0.85) +
  geom_line(aes(y = net_inc_pct_gdp, color = "Net Income Balance (% GDP)"), linewidth = 0.85, linetype = "dashed") +
  geom_line(aes(y = drainage_exp_ratio / 2, color = "Drainage / Exports (% RHS)"), linewidth = 0.85, linetype = "dotdash") +
  scale_color_manual(values = c(
    "Gross Income Outflow (% GDP)" = "#e377c2",
    "Net Income Balance (% GDP)" = "#8c564b",
    "Drainage / Exports (% RHS)" = "#d62728"
  )) +
  scale_x_continuous(breaks = seq(1920, 2024, by = 10), expand = c(0.02, 0.02)) +
  scale_y_continuous(
    name = "Income Balance & Outflows (% GDP)",
    labels = function(x) paste0(x, "%"),
    sec.axis = sec_axis(~ . * 2, name = "Drainage as % of Exports (RHS)", labels = function(x) paste0(x, "%"))
  ) +
  labs(
    title = "Financial Subordination and External Surplus Drainage in Chile (1920-2024)",
    subtitle = "Foreign Profit Repatriation and External Debt Service (% GDP and % Exports)",
    x = "Year"
  ) +
  umass_theme +
  theme(
    axis.title.y.right = element_text(color = "#d62728"),
    axis.text.y.right = element_text(color = "#d62728")
  )
p_drainage <- add_annotations(p_drainage)
save_plot(p_drainage, "fig_wbop_income_drainage")

# --- Figure 6: Current Account Balance & Drivers (% GDP) ---
df_ca_long <- df_cl %>%
  select(year, ca_gdp, tb_tot_gdp, net_inc_gdp) %>%
  pivot_longer(cols = -year, names_to = "component", values_to = "pct_gdp") %>%
  mutate(
    pct_gdp = pct_gdp * 100,
    component = factor(component,
                       levels = c("ca_gdp", "tb_tot_gdp", "net_inc_gdp"),
                       labels = c("Current Account (% GDP)", "Trade Balance Goods+Serv (% GDP)", "Net Primary Income (% GDP)"))
  ) %>%
  filter(!is.na(pct_gdp))

p_ca <- ggplot(df_ca_long, aes(x = year, y = pct_gdp, color = component, linetype = component)) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
  geom_line(linewidth = 0.85) +
  scale_color_manual(values = c(
    "Current Account (% GDP)" = "#1f77b4",
    "Trade Balance Goods+Serv (% GDP)" = "#2ca02c",
    "Net Primary Income (% GDP)" = "#d62728"
  )) +
  scale_linetype_manual(values = c(
    "Current Account (% GDP)" = "solid",
    "Trade Balance Goods+Serv (% GDP)" = "dashed",
    "Net Primary Income (% GDP)" = "dotdash"
  )) +
  scale_x_continuous(breaks = seq(1920, 2024, by = 10), expand = c(0.02, 0.02)) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "Current Account Balance and Structural Components in Chile (1920-2024)",
    subtitle = "Current Account Decomposition: Trade Balance vs. Primary Income Drainage (% GDP)",
    y = "Balance (% GDP)",
    x = "Year"
  ) +
  umass_theme
p_ca <- add_annotations(p_ca)
save_plot(p_ca, "fig_wbop_current_account")

# --- Figure 7: Gross External Leverage (Foreign Liabilities / Foreign Assets) ---
p_ext_lev <- ggplot(df_cl %>% filter(!is.na(ext_leverage_ratio)), aes(x = year, y = ext_leverage_ratio)) +
  geom_hline(yintercept = 1.0, linetype = "dotted", color = "gray40") +
  geom_line(color = "#e6550d", linewidth = 0.9) +
  geom_point(color = "#e6550d", size = 1.5, alpha = 0.7) +
  scale_x_continuous(breaks = seq(1920, 2024, by = 10), expand = c(0.02, 0.02)) +
  scale_y_continuous(labels = comma) +
  labs(
    title = "Gross External Balance Sheet Leverage in Chile (1920-2024)",
    subtitle = "Ratio of Gross Foreign Liabilities to Gross Foreign Assets (L_ext = Liabilities / Assets)",
    y = "Gross External Leverage Ratio",
    x = "Year"
  ) +
  umass_theme
p_ext_lev <- add_annotations(p_ext_lev)
save_plot(p_ext_lev, "fig_wbop_external_leverage")

# --- Figure 8: Net International Investment Position (NIIP % GDP) ---
df_nfa_long <- df_cl %>%
  select(year, niip_gdp, nfa_assets_gdp, nfa_liab_gdp) %>%
  pivot_longer(cols = -year, names_to = "component", values_to = "pct_gdp") %>%
  mutate(
    pct_gdp = pct_gdp * 100,
    component = factor(component,
                       levels = c("niip_gdp", "nfa_assets_gdp", "nfa_liab_gdp"),
                       labels = c("Net Foreign Wealth / NIIP", "Gross Foreign Assets", "Gross Foreign Liabilities"))
  ) %>%
  filter(!is.na(pct_gdp))

p_niip <- ggplot(df_nfa_long, aes(x = year, y = pct_gdp, color = component, linetype = component)) +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.5) +
  geom_line(linewidth = 0.85) +
  scale_color_manual(values = c(
    "Net Foreign Wealth / NIIP" = "#3182bd",
    "Gross Foreign Assets" = "#31a354",
    "Gross Foreign Liabilities" = "#de2d26"
  )) +
  scale_linetype_manual(values = c(
    "Net Foreign Wealth / NIIP" = "solid",
    "Gross Foreign Assets" = "dashed",
    "Gross Foreign Liabilities" = "dotdash"
  )) +
  scale_x_continuous(breaks = seq(1920, 2024, by = 10), expand = c(0.02, 0.02)) +
  scale_y_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title = "Net International Investment Position (NIIP) and Gross Positions (1920-2024)",
    subtitle = "Foreign Assets, Foreign Liabilities, and Net Wealth as Percentage of GDP (% GDP)",
    y = "Position (% GDP)",
    x = "Year"
  ) +
  umass_theme
p_niip <- add_annotations(p_niip)
save_plot(p_niip, "fig_wbop_niip")

cat("Successfully generated and saved all WBOP structural ratio plots.\n")
