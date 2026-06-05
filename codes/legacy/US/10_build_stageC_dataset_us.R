# 10_build_stageC_dataset_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Stage C dataset assembly — US NF corporate sector, 1929-2024
#
# Merges:
#   - Stage B table B1 (r, mu, B, B_real, PyPK, pi + contributions)
#   - Stage A/B base dataset (GVA, GOS, EC, capital stocks, deflators, theta)
#   - BEA income accounts (corporate tax, retained earnings, dividends, CCA)
#
# Computes:
#   - chi (recapitalization rate = IGC / GOS)
#   - g_K (capital accumulation rate = d ln KGR)
#   - g_Y (output growth = d ln GVA_real)
#   - g_Yp (potential output growth = theta * g_K)
#   - r_net (net profit rate = NOS / KNC)
#   - tax_rate (corporate tax rate = CorpTax / PBT)
#   - retention_rate (Retained / PAT)
#   - dividend_payout (Dividends / PAT)
#   - cash_flow_ratio (GOS - CorpTax) / KNC
#   - net_interest_share (NetInt / GOS)
#   - cca_rate (CCA / KGC — depreciation rate)
# ═══════════════════════════════════════════════════════════════════════════════

library(readr)
library(dplyr)
library(tibble)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

out_dir <- file.path(REPO, "data/processed")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)


# ── Load sources ─────────────────────────────────────────────────────────────

# Stage B table B1 (levels + contributions, 1940-2024)
b1 <- read_csv(file.path(REPO, "output/stage_b/US/csv",
               "stageB_US_table_B1_annual_contributions_v2.csv"),
               show_col_types = FALSE)

# Base dataset (full 1929-2024)
base <- read_csv(file.path(REPO, "data/processed/us_nf_corporate_stageBC.csv"),
                 show_col_types = FALSE)

# BEA income accounts (for tax, retained, dividends, CCA, NOS, net interest)
inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
inc <- inc[order(inc$year), ]

cat(sprintf("B1:   %d-%d (%d obs)\n", min(b1$year), max(b1$year), nrow(b1)))
cat(sprintf("Base: %d-%d (%d obs)\n", min(base$year), max(base$year), nrow(base)))
cat(sprintf("Inc:  %d-%d (%d obs)\n", min(inc$year), max(inc$year), nrow(inc)))


# ── Merge ────────────────────────────────────────────────────────────────────

# Start from base (1929-2024), merge B1 (1940-2024), merge inc
ds <- base

# B1 additions: r, B, B_real, PyPK already derived; merge contributions
b1_add <- b1 %>%
  select(year, r, B, B_real, PyPK,
         dlnr, phi_mu, phi_PyPK, phi_Br, phi_pi,
         regime, tendency_label)
ds <- merge(ds, b1_add, by = "year", all.x = TRUE)

# Income accounts additions
inc_add <- inc[, c("year", "CCA_NF", "NVA_NF", "NOS_NF", "TPI_NF",
                   "NetInt_NF", "Profits_IVA_CC_NF", "CorpTax_NF",
                   "PBT_NF", "PAT_NF", "Dividends_NF", "Retained_NF",
                   "Retained_IVA_CC_NF")]
ds <- merge(ds, inc_add, by = "year", all.x = TRUE)
ds <- ds[order(ds$year), ]


# ═══════════════════════════════════════════════════════════════════════════════
# COMPUTE DERIVED VARIABLES
# ═══════════════════════════════════════════════════════════════════════════════

N <- nrow(ds)

ds$chi         <- ds$IGC / ds$GOS                    # recapitalization rate
ds$r_net       <- ds$NOS_NF / ds$KNC                 # net profit rate
ds$tax_rate    <- ds$CorpTax_NF / ds$PBT_NF          # effective corporate tax rate
ds$ret_rate    <- ds$Retained_NF / ds$PAT_NF         # retention rate
ds$div_payout  <- ds$Dividends_NF / ds$PAT_NF        # dividend payout ratio
ds$cash_flow   <- (ds$GOS - ds$CorpTax_NF) / ds$KNC  # after-tax cash flow / capital
ds$int_share   <- ds$NetInt_NF / ds$GOS              # net interest share of GOS
ds$cca_rate    <- ds$CCA_NF / ds$KGC                 # depreciation rate (CCA/gross K)

# Growth rates (log-differences)
ds$g_K   <- c(NA, diff(log(ds$KGR)))                 # real gross capital accumulation
ds$g_Kn  <- c(NA, diff(log(ds$KNR)))                 # real net capital accumulation
ds$g_Y   <- c(NA, diff(log(ds$GVA_real)))            # real output growth
ds$g_Yp  <- ds$theta * ds$g_K                        # potential output growth (closure)

# For r where B1 didn't cover (1929-1939), compute directly
ds$r[is.na(ds$r)]         <- ds$GOS[is.na(ds$r)] / ds$KNC[is.na(ds$r)]
ds$B[is.na(ds$B)]         <- ds$r[is.na(ds$B)] / (ds$mu[is.na(ds$B)] * ds$pi[is.na(ds$B)])
ds$PyPK[is.na(ds$PyPK)]   <- ds$Py[is.na(ds$PyPK)] / ds$pK[is.na(ds$PyPK)]
ds$B_real[is.na(ds$B_real)] <- ds$B[is.na(ds$B_real)] * (ds$pK[is.na(ds$B_real)] / ds$Py[is.na(ds$B_real)])
ds$regime[is.na(ds$regime)] <- "Pre-Fordist"


# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n=== VALIDATION ===\n")

# Identity: r = mu * B * pi (where all three exist)
idx <- !is.na(ds$r) & !is.na(ds$B) & !is.na(ds$mu)
id_err <- max(abs(ds$r[idx] - ds$mu[idx] * ds$B[idx] * ds$pi[idx]))
cat(sprintf("r = mu*B*pi:   max err = %.2e  %s\n", id_err, ifelse(id_err < 1e-10, "PASS", "CHECK")))

# chi > 0 throughout
cat(sprintf("chi > 0:       %s (min = %.4f)\n",
    ifelse(all(ds$chi > 0, na.rm=TRUE), "PASS", "CHECK"), min(ds$chi, na.rm=TRUE)))

# g_Yp = theta * g_K
idx2 <- !is.na(ds$g_Yp) & !is.na(ds$g_K)
gp_err <- max(abs(ds$g_Yp[idx2] - ds$theta[idx2] * ds$g_K[idx2]))
cat(sprintf("g_Yp = theta*g_K: max err = %.2e  %s\n", gp_err, ifelse(gp_err < 1e-10, "PASS", "CHECK")))

# NA count
na_total <- sum(is.na(ds[ds$year >= 1940, c("r","mu","B","B_real","pi","chi",
                                              "g_K","g_Y","theta","r_net")]))
cat(sprintf("NAs in 1940-2024 core vars: %d\n", na_total))


# ═══════════════════════════════════════════════════════════════════════════════
# REPORT
# ═══════════════════════════════════════════════════════════════════════════════

cat(sprintf("\n=== DATASET: %d vars x %d obs (%d-%d) ===\n",
    ncol(ds), nrow(ds), min(ds$year), max(ds$year)))

core_vars <- c("year","r","r_net","mu","B","B_real","PyPK","pi","omega","theta",
               "chi","g_K","g_Kn","g_Y","g_Yp",
               "tax_rate","ret_rate","div_payout","cash_flow","int_share","cca_rate",
               "GVA","GOS","EC","KNC","KNR","KGC","KGR","IGC","Py","pK",
               "GVA_real","EC_real","GOS_real",
               "dlnr","phi_mu","phi_PyPK","phi_Br","phi_pi",
               "regime","tendency_label")

cat(sprintf("\n%-14s %12s %12s %12s\n", "Variable", "Min", "Max", "Mean"))
cat(strrep("-", 54), "\n")
for (v in core_vars) {
  if (v %in% names(ds)) {
    x <- ds[[v]]
    if (is.numeric(x)) {
      cat(sprintf("%-14s %12.4f %12.4f %12.4f\n", v,
          min(x, na.rm=TRUE), max(x, na.rm=TRUE), mean(x, na.rm=TRUE)))
    }
  }
}


# ═══════════════════════════════════════════════════════════════════════════════
# SAVE
# ═══════════════════════════════════════════════════════════════════════════════

write_csv(ds, file.path(out_dir, "us_nf_corporate_stageC.csv"))
cat(sprintf("\nSaved: %s/us_nf_corporate_stageC.csv\n", out_dir))

# Codebook
defs <- tribble(
  ~variable, ~description,
  "year",         "Year",
  "r",            "Nominal profit rate = GOS / KNC",
  "r_net",        "Net profit rate = NOS / KNC",
  "mu",           "Capacity utilization (pinned mu(1948)=0.80, g(Y*)=theta*g(K))",
  "mu_ect",       "Capacity utilization (ECT-based, centered on 1)",
  "B",            "Nominal capital productivity at normal capacity = r/(mu*pi)",
  "B_real",       "Real capital productivity = B*(pK/Py)",
  "PyPK",         "Relative output-to-capital price = Py/pK",
  "pi",           "Profit share = GOS/GVA (includes TPI in denominator)",
  "omega",        "Wage share = EC/GVA",
  "e",            "Rate of exploitation = GOS/EC",
  "theta",        "Transformation elasticity theta(omega) = 8.924 - 12.851*omega",
  "chi",          "Recapitalization rate = IGC/GOS",
  "g_K",          "Real gross capital accumulation rate = d(ln KGR)",
  "g_Kn",         "Real net capital accumulation rate = d(ln KNR)",
  "g_Y",          "Real output growth rate = d(ln GVA_real)",
  "g_Yp",         "Potential output growth = theta * g_K",
  "tax_rate",     "Effective corporate tax rate = CorpTax/PBT",
  "ret_rate",     "Retention rate = Retained/PAT",
  "div_payout",   "Dividend payout ratio = Dividends/PAT",
  "cash_flow",    "After-tax cash flow rate = (GOS-CorpTax)/KNC",
  "int_share",    "Net interest share of GOS = NetInt/GOS",
  "cca_rate",     "Depreciation rate = CCA/KGC",
  "GVA",          "Gross Value Added, nominal (millions $)",
  "GOS",          "Gross Operating Surplus, nominal (millions $)",
  "EC",           "Employment Compensation, nominal (millions $)",
  "KNC",          "Net capital stock, current prices (millions $)",
  "KNR",          "Net capital stock, 2024 prices (millions $)",
  "KGC",          "Gross capital stock, current prices (millions $)",
  "KGR",          "Gross capital stock, 2024 prices (millions $)",
  "IGC",          "Gross investment, current prices (millions $)",
  "Py",           "GDP deflator index (2024=100)",
  "pK",           "Capital price deflator index (2024=100)",
  "GVA_real",     "GVA in 2024 constant prices (millions $)",
  "EC_real",      "EC in 2024 constant prices (millions $)",
  "GOS_real",     "GOS in 2024 constant prices (millions $)",
  "CCA_NF",       "Consumption of fixed capital, nominal (millions $)",
  "NVA_NF",       "Net Value Added, nominal (millions $)",
  "NOS_NF",       "Net Operating Surplus, nominal (millions $)",
  "TPI_NF",       "Taxes on production and imports (millions $)",
  "NetInt_NF",    "Net interest paid, nominal (millions $)",
  "CorpTax_NF",   "Corporate income tax, nominal (millions $)",
  "PBT_NF",       "Profit before tax, nominal (millions $)",
  "PAT_NF",       "Profit after tax, nominal (millions $)",
  "Dividends_NF", "Dividends paid, nominal (millions $)",
  "Retained_NF",  "Retained earnings, nominal (millions $)",
  "dlnr",         "d(ln r) — annual log-change in profit rate",
  "phi_mu",       "mu contribution to d(ln r)",
  "phi_PyPK",     "Py/PK contribution to d(ln r)",
  "phi_Br",       "B_real contribution to d(ln r)",
  "phi_pi",       "pi contribution to d(ln r)",
  "regime",       "Accumulation regime (Pre-Fordist / Fordist / Post-Fordist)",
  "tendency_label","Stagnation tendency classification"
)

write_csv(defs, file.path(out_dir, "us_nf_corporate_stageC_codebook.csv"))
cat(sprintf("Saved: %s/us_nf_corporate_stageC_codebook.csv\n", out_dir))
