# CL_S40_price_proxy_integration.R
# Integrates price proxies, Terms of Trade, machinery import demand imbalance,
# and Nievas & Piketty (2025) WBOP balance of payments threshold variables for Chile.

library(readxl)
library(dplyr)
library(readr)
library(tidyr)

# Paths
clio_path  <- "data/raw/Chile/W04_Precios_ClioLabPUC.xlsx"
clio_w04_path <- "data/raw/Chile/cliolab/W04_Precios.xlsx"
clio_w05_path <- "data/raw/Chile/cliolab/W05_Comercio.xlsx"
clio_w06_path <- "data/raw/Chile/cliolab/W06_Monetaria.xlsx"
wbop_path  <- "data/raw/Chile/WBOP/NievasPiketty2025WBOPFinalSeries.xlsx"
perez_path <- "data/raw/Chile/PerezEyzaguirre_DemandaAgregada.xlsx"
pk_path    <- "C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_pk_2003base_1940_2024.csv"
k_perez_path <- "C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_PEREZ_2003CLP_v1/harmonized_series_2003CLP_1900_1994.csv"
k_bcch_path  <- "C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_series_2003CLP_1900_2024.csv"
panel_path <- "data/raw/Chile/ch2_raw_panel_chile.csv"
gdp_path   <- "data/interim/Chile/gdp_spliced_1860_2025.csv"
def_path   <- "data/interim/Chile/gdp_deflator_spliced_1860_2025.csv"
output_path <- "data/staged/ch2_panel_chile_with_prices.csv"

# 1. Read ClioLab Price & ToT Data
df_rer <- read_excel(clio_path, sheet = "4.2.2", skip = 10) %>% select(year = Code, TCREAL) %>% filter(!is.na(year))
df_ipmusa <- read_excel(clio_path, sheet = "4.3.6", skip = 10) %>% select(year = Code, IPMUSA) %>% filter(!is.na(year))
df_tot <- read_excel(clio_path, sheet = "4.3.2", skip = 10) %>% select(year = Code, TERMINT) %>% filter(!is.na(year))

# 1.5 Read ClioLab Leverage Ratio Ingredients
# TCNUSD: Exchange rate
df_e <- read_excel(clio_w04_path, sheet = "4.2.1", skip = 10) %>% select(year = Code, e_t = TCNUSD) %>% filter(!is.na(year))
# RIS: Gross Reserves
df_ir <- read_excel(clio_w05_path, sheet = "5.3 Reservas Internacionales", skip = 10) %>% select(year = Code, IR_t = RIS) %>% filter(!is.na(year))
# M0: Base Money (Emisión)
df_m0 <- read_excel(clio_w06_path, sheet = "6.1.3", skip = 13) %>% select(year = Code, M0_t = EMN_A) %>% filter(!is.na(year))
# M1, M2: Money Supply
df_m12 <- read_excel(clio_w06_path, sheet = "6.1.2", skip = 10) %>% select(year = Code, M1_t = M1S1NOM_A, M2_t = M2S1NOM_A) %>% filter(!is.na(year))

# Combine Leverage Ingredients
df_lev <- df_e %>%
  full_join(df_ir, by = "year") %>%
  full_join(df_m0, by = "year") %>%
  full_join(df_m12, by = "year") %>%
  mutate(
    F_t = e_t * IR_t,
    LevR_M0 = M0_t / F_t,
    LevR_M1 = M1_t / F_t,
    LevR_M2 = M2_t / F_t,
    SolvR_M0 = F_t / M0_t,
    SolvR_M1 = F_t / M1_t,
    SolvR_M2 = F_t / M2_t
  ) %>%
  select(year, LevR_M0, LevR_M1, LevR_M2, SolvR_M0, SolvR_M1, SolvR_M2)

# 2. Read Harmonized pK
df_pk <- read_csv(pk_path, show_col_types = FALSE) %>% select(year, Pk_2003base) %>% filter(!is.na(year))

# 3. Read Perez & Eyzaguirre Machinery Investment (FBKF en maquinaria)
df_perez <- read_excel(perez_path, sheet = "Demanda Agregada")
colnames(df_perez)[1] <- "year"
colnames(df_perez)[which(grepl("maquinaria", colnames(df_perez), ignore.case = TRUE))] <- "I_ME_perez"
df_perez_me <- df_perez %>% select(year, I_ME_perez) %>% filter(!is.na(year))

# 4. Read Nievas & Piketty (2025) WBOP Variables (Column CL)
read_wbop_col <- function(sheet_name, var_name) {
  df <- read_excel(wbop_path, sheet = sheet_name, skip = 2)
  year <- as.numeric(df[[1]])
  val  <- as.numeric(df[["CL"]])
  res  <- data.frame(year = year, val = val)
  colnames(res)[2] <- var_name
  res %>% filter(!is.na(year))
}
df_wbop_b3c <- read_wbop_col("B3c", "wbop_m_manuf")      
df_wbop_b3a <- read_wbop_col("B3a", "wbop_net_manuf")    
df_wbop_d1c <- read_wbop_col("D1c", "wbop_inc_outflow")  
df_wbop_f1  <- read_wbop_col("F1",  "wbop_ca")           
df_wbop_b1b <- read_wbop_col("B1b", "wbop_x_tot")        

df_wbop_all <- df_wbop_b3c %>%
  full_join(df_wbop_b3a, by = "year") %>%
  full_join(df_wbop_d1c, by = "year") %>%
  full_join(df_wbop_f1,  by = "year") %>%
  full_join(df_wbop_b1b, by = "year") %>%
  mutate(
    wbop_tau = wbop_m_manuf / wbop_x_tot,
    wbop_inc_outflow_x = wbop_inc_outflow / wbop_x_tot
  )

# 5. Read New GDP & Deflator Spliced Series
df_gdp_spliced <- read_csv(gdp_path, show_col_types = FALSE)
df_def_spliced <- read_csv(def_path, show_col_types = FALSE)

# 6. Read Main Panel
df_panel <- read_csv(panel_path, show_col_types = FALSE)
# Drop old GDP_real since we have the spliced one
if("GDP_real" %in% names(df_panel)) {
  df_panel <- df_panel %>% select(-GDP_real)
}

# 7. Merge Everything
df_merged <- data.frame(year = 1860:2025) %>%
  left_join(df_panel, by = "year") %>%
  left_join(df_gdp_spliced, by = "year") %>%
  rename(GDP_real = GDP_real_spliced) %>%
  left_join(df_def_spliced, by = "year") %>%
  left_join(df_rer, by = "year") %>%
  left_join(df_ipmusa, by = "year") %>%
  left_join(df_tot, by = "year") %>%
  left_join(df_pk, by = "year") %>%
  left_join(df_perez_me, by = "year") %>%
  left_join(df_wbop_all, by = "year") %>%
  left_join(df_lev, by = "year")

# 8. Rebase and Construct Multi-Proxy Relative Capital Prices
# Base 2003 = 1
val_ipmusa_2003  <- df_merged$IPMUSA[df_merged$year == 2003]
val_pk_2003      <- df_merged$Pk_2003base[df_merged$year == 2003]
val_rer_2003     <- df_merged$TCREAL[df_merged$year == 2003]
val_tot_2003     <- df_merged$TERMINT[df_merged$year == 2003]
val_py_2003      <- df_merged$P_Y_spliced[df_merged$year == 2003]

df_prices <- df_merged %>%
  mutate(
    IPMUSA_rebased  = IPMUSA / val_ipmusa_2003,
    Pk_rebased      = Pk_2003base / val_pk_2003,
    TCREAL_rebased  = TCREAL / val_rer_2003,
    TERMINT_rebased = TERMINT / val_tot_2003,
    P_Y_rebased     = P_Y_spliced / val_py_2003
  ) %>%
  mutate(
    # Category B: Native 1920-2024 Proxies (Do not use Pk)
    p_kappa_rer       = log(TCREAL_rebased),
    p_kappa_ipmusa    = log(IPMUSA_rebased),
    p_kappa_composite = log(IPMUSA_rebased * TCREAL_rebased),
    
    # Category C: Pk-Deflated 1940-2024 Proxies (Uses Pk)
    # 5. P_Y / P_K
    p_kappa_py_pk     = log(P_Y_rebased / Pk_rebased),
    
    # Optional version ToT adjusted as requested
    p_kappa_py_tot_pk = log((P_Y_rebased / TERMINT_rebased) / Pk_rebased),
    
    # Terms of Trade Capacity to Import
    M_cap_tot = TERMINT_rebased * X_FOB,
    ln_M_cap_tot = log(M_cap_tot),
    
    # Machinery Demand vs Import Capacity Imbalance Terms
    imbalance_level = log(I_ME_perez) - log(M_cap_tot),
    imbalance_growth = c(NA, diff(log(I_ME_perez))) - c(NA, diff(log(M_cap_tot)))
  )

# 9. Compute Stock-Flow Consistent Net Wage Share & Distributive Conflict Variants
df_k_perez <- read_csv(k_perez_path, show_col_types = FALSE)
df_k_bcch  <- read_csv(k_bcch_path, show_col_types = FALSE)

d_me_perez  <- df_k_perez %>% filter(asset == "ME") %>% select(year, D_ME = D)
d_nrc_perez <- df_k_perez %>% filter(asset == "NRC") %>% select(year, D_NRC = D)

# Harmonized BCCh extension (already on 2003 CLP basis matching Perez)
d_me_bcch  <- df_k_bcch %>% filter(asset == "ME") %>% select(year, D_ME = D)
d_nrc_bcch <- df_k_bcch %>% filter(asset == "NRC") %>% select(year, D_NRC = D)

df_cfc <- data.frame(year = 1900:2024) %>%
  left_join(d_me_perez, by = "year") %>%
  left_join(d_me_bcch, by = "year", suffix = c("_perez", "_bcch")) %>%
  mutate(D_ME = ifelse(!is.na(D_ME_perez), D_ME_perez, D_ME_bcch)) %>%
  left_join(d_nrc_perez, by = "year") %>%
  left_join(d_nrc_bcch, by = "year", suffix = c("_perez", "_bcch")) %>%
  mutate(D_NRC = ifelse(!is.na(D_NRC_perez), D_NRC_perez, D_NRC_bcch)) %>%
  mutate(CFC_real = D_ME + D_NRC) %>%
  select(year, CFC_real)

df_prices <- df_prices %>%
  left_join(df_cfc, by = "year") %>%
  mutate(
    # Nominal CFC Share of GVA: (P_K / P_Y) * (CFC_real / GDP_real)
    CFC_ratio_nom = (Pk_rebased / P_Y_rebased) * (CFC_real / GDP_real),
    
    # Gross Distributive Variables (Astorga-BCCh baseline)
    omega_gross = omega,
    pi_gross    = 1 - omega_gross,
    e_gross     = pi_gross / omega_gross,
    
    # Net Distributive Variables (Depreciation & Relative Capital Price Adjusted)
    omega_net = ifelse(!is.na(CFC_ratio_nom) & CFC_ratio_nom < 0.95, omega_gross / (1 - CFC_ratio_nom), NA),
    pi_net    = 1 - omega_net,
    e_net     = pi_net / omega_net,
    
    # Log Transformations
    ln_omega_gross = log(omega_gross),
    ln_omega_net   = log(omega_net),
    ln_e_gross     = log(e_gross),
    ln_e_net       = log(e_net)
  )

# Save Staged Panel
dir.create("data/staged", showWarnings = FALSE)
write_csv(df_prices, output_path)

cat("Successfully integrated multi-proxy prices, ToT capacity, machinery demand imbalances, and WBOP series into", output_path, "\n")
