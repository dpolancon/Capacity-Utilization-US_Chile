# CL_S40_price_proxy_integration.R
# Integrates price proxies for Chile: US Wholesale Index (IPMUSA), Real Exchange Rate (TCREAL)
# and internal capital deflator (pK) to build relative price indexes.

library(readxl)
library(dplyr)
library(readr)
library(tidyr)

# Paths
clio_path <- "data/raw/Chile/W04_Precios_ClioLabPUC.xlsx"
pk_path <- "C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_pk_2003base_1940_2024.csv"
panel_path <- "data/raw/Chile/ch2_raw_panel_chile.csv"
output_path <- "data/staged/ch2_panel_chile_with_prices.csv"

# 1. Read ClioLab Price Data
# TCREAL (Real Exchange Rate) - Sheet 4.2.2
df_rer <- read_excel(clio_path, sheet = "4.2.2", skip = 10) %>%
  select(year = Code, TCREAL) %>%
  filter(!is.na(year))

# IPMUSA (US Wholesale Index) - Sheet 4.3.6
df_ipmusa <- read_excel(clio_path, sheet = "4.3.6", skip = 10) %>%
  select(year = Code, IPMUSA) %>%
  filter(!is.na(year))

# 2. Read Harmonized pK
df_pk <- read_csv(pk_path, show_col_types = FALSE) %>%
  select(year, Pk_2003base) %>%
  filter(!is.na(year))

# 3. Merge Price Data
df_prices <- df_rer %>%
  full_join(df_ipmusa, by = "year") %>%
  full_join(df_pk, by = "year") %>%
  filter(year >= 1900 & year <= 2024) %>%
  arrange(year)

# 4. Rebase and construct proxies (Base 2003 = 1)
val_ipmusa_2003 <- df_prices$IPMUSA[df_prices$year == 2003]
val_pk_2003 <- df_prices$Pk_2003base[df_prices$year == 2003]
val_rer_2003 <- df_prices$TCREAL[df_prices$year == 2003]

df_prices <- df_prices %>%
  mutate(
    IPMUSA_rebased = IPMUSA / val_ipmusa_2003,
    Pk_rebased = Pk_2003base / val_pk_2003,
    TCREAL_rebased = TCREAL / val_rer_2003
  ) %>%
  mutate(
    p_kappa_ipmusa = log(IPMUSA_rebased / Pk_rebased),
    p_kappa_rer = log(TCREAL_rebased)
  )

# 5. Read main panel and merge
df_panel <- read_csv(panel_path, show_col_types = FALSE)
df_panel_merged <- df_panel %>%
  left_join(df_prices %>% select(year, p_kappa_ipmusa, p_kappa_rer, IPMUSA_rebased, Pk_rebased, TCREAL_rebased), by = "year")

# Save staged panel
dir.create("data/staged", showWarnings = FALSE)
write_csv(df_panel_merged, output_path)

cat("Successfully integrated price proxies and saved to", output_path, "\n")
