# 10_data_prep_us.R (v2)
# Stage A.1 — US Center: Build estimation panel from BEA repo outputs
#
# DUAL CAPITAL ACCOUNTING (locked 2026-04-03):
#
#   FOR CAPACITY UTILIZATION (MPF):
#     k = log(NR_K_gross_real)  — real GROSS capital stock (GPIM deflated)
#     Y^p = theta * K_gross_real (physical productive capacity)
#     mu_t = Y / Y^p            (utilization = actual/physical capacity)
#
#   FOR PROFIT RATE (Weisskopf):
#     K_nc = NR_K_net_cc        — net current cost capital (value of capital advanced)
#     r = Pi / K_nc             (monetary profit rate)
#     b_nc = Y^p / K_nc         (output-capital ratio at current values)
#     Decomposition: r = pi * mu * b_nc
#
#   COMPOSITION RATIO:
#     comp = K_gross_real / K_net_cc  (physical-to-value ratio)
#     When high: older capital, more physical capacity per value unit
#     Encodes the over-accumulation tendency
#
# State vector for VECM: (y, k_gross, pi, pi_k_gross)
# Stage B Weisskopf: uses mu_hat (from VECM) + b_nc (from dual accounting)
# Stage C FM: chi = I_gross / Pi (recapitalization rate)

library(readr)
library(dplyr)

BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"
REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

cat("Loading BEA processed files...\n")

master  <- read_csv(file.path(BEA, "data/processed/master_dataset.csv"),
                    show_col_types=FALSE)
exploit <- read_csv(file.path(BEA, "data/processed/corp_exploitation_series.csv"),
                    show_col_types=FALSE)
output  <- read_csv(file.path(BEA, "data/processed/corp_output_series.csv"),
                    show_col_types=FALSE)

cat(sprintf("  master: %d rows (%g-%g)\n",
            nrow(master), min(master$year,na.rm=T), max(master$year,na.rm=T)))

# ── Select columns ─────────────────────────────────────────────────────────────
master_sel <- master %>% select(
  year,
  gdp_real_2017,
  # GROSS real (for MPF / capacity utilization)
  NR_K_gross_real,     # NRC + ME gross real (= ME_K_gross_real + NRC_K_gross_real)
  ME_K_gross_real,
  NRC_K_gross_real,
  # NET current cost (for profit rate)
  NR_K_net_cc,
  ME_K_net_cc,
  NRC_K_net_cc,
  # GROSS current cost (for investment flows)
  ME_IG_real,
  NRC_IG_real,
  # Price deflators
  ME_p_K,
  NRC_p_K,
  NR_p_K
)

exploit_sel <- exploit %>%
  select(year, profit_share, exploit_rate) %>%
  rename(pi=profit_share, e=exploit_rate)

output_sel <- output %>%
  select(year, VAcorpnipa, ECcorp, Pcorpnipa) %>%
  rename(VA=VAcorpnipa, EC=ECcorp, Pi=Pcorpnipa)

# ── Merge ──────────────────────────────────────────────────────────────────────
df <- master_sel %>%
  left_join(exploit_sel, by="year") %>%
  left_join(output_sel,  by="year") %>%
  arrange(year)

# ── State vector for VECM (uses GROSS real) ────────────────────────────────────
df$y        <- log(df$gdp_real_2017)
df$k        <- log(df$NR_K_gross_real)   # GROSS — for MPF
df$k_ME     <- log(df$ME_K_gross_real)
df$k_NR     <- log(df$NRC_K_gross_real)
df$pi_k     <- df$pi * df$k              # interaction for VECM CV1

# ── Profit rate accounting (uses NET CURRENT COST) ────────────────────────────
# Monetary profit rate: r = Pi / K_net_cc
df$r_nc     <- df$Pi / df$NR_K_net_cc

# Output-capital ratio at current values: b_nc = GDP_real / K_net_cc
# Note: this mixes real Y and nominal K — use Pi/K_net_cc for r instead
# For Weisskopf: b_nc = Y^p / K_net_cc where Y^p recovered from VECM
# Pre-VECM proxy: b_nc_raw = gdp_real / K_net_cc (to be replaced by Y_hat^p)
df$b_nc_raw <- df$gdp_real_2017 / df$NR_K_net_cc

# Vintage-composition ratio: physical-to-value
df$comp     <- df$NR_K_gross_real / df$NR_K_net_cc

# ── Stage C variables ──────────────────────────────────────────────────────────
df$I_total  <- df$ME_IG_real + df$NRC_IG_real  # gross investment real
df$chi      <- df$I_total / df$Pi              # recapitalization rate

# Log capital productivity (using gross real — consistent with MPF)
df$b        <- df$y - df$k

# ── Coverage check ─────────────────────────────────────────────────────────────
cat("\nCoverage check (key variables):\n")
check_vars <- c("y","k","pi","pi_k","r_nc","chi","comp")
df_check <- df %>%
  filter(year >= 1930, year <= 1985) %>%
  mutate(decade=floor(year/10)*10) %>%
  group_by(decade) %>%
  summarise(across(all_of(check_vars), ~sum(!is.na(.)), .names="n_{.col}"))
print(df_check)

# Fordist window
df_f <- df[df$year >= 1945 & df$year <= 1978, ]
cat(sprintf("\nFordist window: %d rows\n", nrow(df_f)))
cat("Missing — state vector:\n")
for(v in c("y","k","pi","pi_k")) cat(sprintf("  %-10s %d\n", v, sum(is.na(df_f[[v]]))))
cat("Missing — profit rate:\n")
for(v in c("r_nc","b_nc_raw","comp","chi")) cat(sprintf("  %-10s %d\n", v, sum(is.na(df_f[[v]]))))

cat(sprintf("\nGross/net composition ratio (Fordist mean): %.3f\n",
            mean(df_f$comp, na.rm=TRUE)))
cat("(High ratio = older capital vintage, more physical capacity per value unit)\n")

# ── Save ──────────────────────────────────────────────────────────────────────
out_dir <- file.path(REPO, "data/processed/us")
dir.create(out_dir, recursive=TRUE, showWarnings=FALSE)
out_file <- file.path(out_dir, "ch2_panel_us.csv")

out_cols <- c(
  "year",
  # VECM state vector
  "y","k","pi","pi_k","k_ME","k_NR",
  # Profit rate accounting
  "r_nc","b_nc_raw","comp","Pi",
  # Stage C
  "chi","I_total","b",
  # Raw series
  "gdp_real_2017",
  "NR_K_gross_real","ME_K_gross_real","NRC_K_gross_real",
  "NR_K_net_cc","ME_K_net_cc","NRC_K_net_cc",
  "ME_p_K","NRC_p_K","NR_p_K",
  "e"
)
out_cols <- out_cols[out_cols %in% names(df)]

write_csv(df[, out_cols], out_file)
cat(sprintf("\nSaved: %s\n", out_file))
cat("\nDual capital accounting locked:\n")
cat("  VECM / MPF:    k = log(NR_K_gross_real)\n")
cat("  Profit rate:   r = Pi / NR_K_net_cc\n")
cat("  Composition:   comp = NR_K_gross_real / NR_K_net_cc\n")
cat("  Recapitalization: chi = I_total / Pi\n")
cat("\nNext: Rscript codes/stage_a/us/20_integration_tests_us.R\n")
