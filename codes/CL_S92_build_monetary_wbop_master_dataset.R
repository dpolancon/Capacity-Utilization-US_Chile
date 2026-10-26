# codes/CL_S92_build_monetary_wbop_master_dataset.R
# Purpose: Build a unified, comprehensive Source-of-Truth master dataset for Chile (1860-2024 / 1920-2024)
# combining ClioLab Central Bank monetary/solvency series and WBOP structural balance-of-payments series.

library(dplyr, warn.conflicts = FALSE)
library(readr)
library(readxl)
library(tidyr)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(repo_root)

cat("1. Loading Central Bank / ClioLab monetary series...\n")

# A) Load Staged Panel Ratios (from Capacity-Utilization pipeline)
panel_path <- "data/staged/ch2_panel_chile_with_prices.csv"
if (file.exists(panel_path)) {
  df_panel <- read_csv(panel_path, show_col_types = FALSE) %>%
    select(year, any_of(c("SolvR_M0", "SolvR_M1", "SolvR_M2", "LevR_M0", "LevR_M1", "LevR_M2")))
} else {
  df_panel <- data.frame(year = 1860:2024)
}

# B) Load Raw Monetary Components from ClioLab
clio_w04_path <- "data/raw/Chile/cliolab/W04_Precios.xlsx"
clio_w05_path <- "data/raw/Chile/cliolab/W05_Comercio.xlsx"
clio_w06_path <- "data/raw/Chile/cliolab/W06_Monetaria.xlsx"

df_e <- read_excel(clio_w04_path, sheet = "4.2.1", skip = 10) %>% 
  select(year = Code, e_t = TCNUSD) %>% 
  filter(!is.na(year))

df_ir <- read_excel(clio_w05_path, sheet = "5.3 Reservas Internacionales", skip = 10) %>% 
  select(year = Code, IR_usd = RIS) %>% 
  filter(!is.na(year))

df_m0 <- read_excel(clio_w06_path, sheet = "6.1.3", skip = 13) %>% 
  select(year = Code, M0_clp = EMN_A) %>% 
  filter(!is.na(year))

df_m12 <- read_excel(clio_w06_path, sheet = "6.1.2", skip = 10) %>% 
  select(year = Code, M1_clp = M1S1NOM_A, M2_clp = M2S1NOM_A) %>% 
  filter(!is.na(year))

df_money_raw <- df_e %>%
  full_join(df_ir, by = "year") %>%
  full_join(df_m0, by = "year") %>%
  full_join(df_m12, by = "year") %>%
  mutate(
    Reserves_clp = e_t * IR_usd,
    # Recompute Solvency & Leverage if not in panel
    calc_SolvR_M0 = Reserves_clp / M0_clp,
    calc_SolvR_M1 = Reserves_clp / M1_clp,
    calc_SolvR_M2 = Reserves_clp / M2_clp,
    calc_LevR_M0 = M0_clp / Reserves_clp,
    calc_LevR_M1 = M1_clp / Reserves_clp,
    calc_LevR_M2 = M2_clp / Reserves_clp
  )

df_money <- full_join(df_money_raw, df_panel, by = "year") %>%
  mutate(
    SolvR_M0 = coalesce(SolvR_M0, calc_SolvR_M0),
    SolvR_M1 = coalesce(SolvR_M1, calc_SolvR_M1),
    SolvR_M2 = coalesce(SolvR_M2, calc_SolvR_M2),
    LevR_M0 = coalesce(LevR_M0, calc_LevR_M0),
    LevR_M1 = coalesce(LevR_M1, calc_LevR_M1),
    LevR_M2 = coalesce(LevR_M2, calc_LevR_M2)
  ) %>%
  select(year, e_t, IR_usd, M0_clp, M1_clp, M2_clp, Reserves_clp,
         SolvR_M0, SolvR_M1, SolvR_M2, LevR_M0, LevR_M1, LevR_M2)

cat("2. Loading WBOP Balance-of-Payments series...\n")

wbop_path <- "data/raw/Chile/WBOP/NievasPiketty2025WBOPFinalSeries.xlsx"

get_wbop_series <- function(sheet_name, col_label) {
  d <- read_excel(wbop_path, sheet = sheet_name, skip = 2)
  cl_col <- which(colnames(d) == "CL")
  if (length(cl_col) == 0) {
    cl_col <- grep("^CL$", colnames(d), ignore.case = TRUE)
  }
  df_res <- data.frame(
    year = as.numeric(d[[1]]),
    val = as.numeric(d[[cl_col[1]]])
  )
  colnames(df_res)[2] <- col_label
  df_res <- df_res %>% filter(!is.na(year))
  return(df_res)
}

sheets_to_extract <- list(
  c("A1", "wbop_gdp_usd_mer"),
  c("B1a", "wbop_tb_goods_gdp"),
  c("B1b", "wbop_x_goods_gdp"),
  c("B1c", "wbop_m_goods_gdp"),
  c("B2a", "wbop_tb_prim_gdp"),
  c("B2b", "wbop_x_prim_gdp"),
  c("B2c", "wbop_m_prim_gdp"),
  c("B3a", "wbop_tb_manuf_gdp"),
  c("B3b", "wbop_x_manuf_gdp"),
  c("B3c", "wbop_m_manuf_gdp"),
  c("C1a", "wbop_tb_serv_gdp"),
  c("C1b", "wbop_x_serv_gdp"),
  c("C1c", "wbop_m_serv_gdp"),
  c("C1d", "wbop_tb_tot_gdp"),
  c("C1e", "wbop_x_tot_gdp"),
  c("C1f", "wbop_m_tot_gdp"),
  c("D1a", "wbop_net_inc_gdp"),
  c("D1b", "wbop_inc_inflow_gdp"),
  c("D1c", "wbop_inc_outflow_gdp"),
  c("E1a", "wbop_net_transfer_gdp"),
  c("E1b", "wbop_transfer_inflow_gdp"),
  c("E1c", "wbop_transfer_outflow_gdp"),
  c("F1", "wbop_current_account_gdp"),
  c("G1a", "wbop_niip_gdp"),
  c("G1b", "wbop_nfa_assets_gdp"),
  c("G1c", "wbop_nfa_liab_gdp")
)

wbop_all <- data.frame(year = 1800:2025)
for (item in sheets_to_extract) {
  s_df <- get_wbop_series(item[1], item[2])
  wbop_all <- left_join(wbop_all, s_df, by = "year")
}

cat("3. Merging and constructing derived structural indicators...\n")

master_df <- full_join(df_money, wbop_all, by = "year") %>%
  filter(year >= 1860 & year <= 2024) %>%
  arrange(year) %>%
  mutate(
    # Effective Export capacity used
    x_total_used = ifelse(!is.na(wbop_x_tot_gdp), wbop_x_tot_gdp, wbop_x_goods_gdp),
    
    # Structural Ratios
    R_manuf_exp = wbop_m_manuf_gdp / x_total_used,
    R_prebisch_singer = wbop_m_manuf_gdp / wbop_x_prim_gdp,
    share_prim_exp_pct = (wbop_x_prim_gdp / wbop_x_goods_gdp) * 100,
    drainage_exp_pct = (wbop_inc_outflow_gdp / x_total_used) * 100,
    ext_leverage_ratio = wbop_nfa_liab_gdp / wbop_nfa_assets_gdp,
    liab_to_exp_ratio = wbop_nfa_liab_gdp / x_total_used
  )

# 4. Save Master CSV in multiple designated locations
dest_paths <- c(
  "data/processed/Chile/chile_monetary_wbop_compilation_master.csv",
  "reports/CHILE_solv_lev_ratio_plots/chile_monetary_wbop_compilation_master.csv",
  "C:/ReposGitHub/Chapter3_RPEUP/data/money_data_set/chile_monetary_wbop_compilation_master.csv"
)

for (p in dest_paths) {
  dir_p <- dirname(p)
  if (!dir.exists(dir_p)) dir.create(dir_p, recursive = TRUE)
  write_csv(master_df, p)
  cat(sprintf("Successfully written source-of-truth CSV: %s (Rows: %d, Cols: %d)\n", p, nrow(master_df), ncol(master_df)))
}

# Also output a 1920-2024 estimation-focused version
dest_paths_1920 <- c(
  "data/processed/Chile/chile_monetary_wbop_1920_2024.csv",
  "C:/ReposGitHub/Chapter3_RPEUP/data/money_data_set/chile_monetary_wbop_1920_2024.csv"
)

master_1920 <- master_df %>% filter(year >= 1920 & year <= 2024)
for (p in dest_paths_1920) {
  dir_p <- dirname(p)
  if (!dir.exists(dir_p)) dir.create(dir_p, recursive = TRUE)
  write_csv(master_1920, p)
  cat(sprintf("Successfully written 1920-2024 CSV: %s (Rows: %d, Cols: %d)\n", p, nrow(master_1920), ncol(master_1920)))
}

cat("Master dataset compilation complete.\n")
