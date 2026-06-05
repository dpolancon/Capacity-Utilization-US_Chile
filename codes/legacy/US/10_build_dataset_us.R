# 10_build_dataset_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Stage B/C dataset assembly — US NF corporate sector, 1929-2024
#
# Assembles all variables for profitability analysis and investment function
# estimation. Merges capacity utilization from Stage A.
#
# Sources:
#   - US_corporate_NF_kstock_distribution.csv (NF corporate income + capital)
#   - income_accounts_NF.csv (GDP deflator Py)
#   - theta_omega_tibble_us.csv (mu pinned + mu_ect from Stage A)
# ═══════════════════════════════════════════════════════════════════════════════

library(readr)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

out_dir <- file.path(REPO, "data/processed")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ── Load sources ─────────────────────────────────────────────────────────────
nf  <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
mu  <- read_csv(file.path(REPO, "output/stage_a/us/csv/theta_omega_tibble_us.csv"),
                show_col_types = FALSE)

nf  <- nf[order(nf$year), ]
inc <- inc[order(inc$year), ]

cat(sprintf("NF data: %d-%d (%d obs)\n", min(nf$year), max(nf$year), nrow(nf)))
cat(sprintf("Income:  %d-%d (%d obs)\n", min(inc$year), max(inc$year), nrow(inc)))
cat(sprintf("Mu tbl:  %d-%d (%d obs)\n", min(mu$year), max(mu$year), nrow(mu)))


# ── GDP deflator (Py) ────────────────────────────────────────────────────────
nf <- merge(nf, inc[, c("year", "Py_fred")], by = "year")

# Rebase Py to 2024 = 100
Py_2024 <- nf$Py_fred[nf$year == 2024]
nf$Py_index <- (nf$Py_fred / Py_2024) * 100

# ── Capital price deflator pK rebased to 2024 = 100 ─────────────────────────
pK_2024 <- nf$pK_NF[nf$year == 2024]
nf$pK_index <- (nf$pK_NF / pK_2024) * 100

# ── Real values in 2024 constant prices ──────────────────────────────────────
nf$GVA_real <- nf$GVA_NF / (nf$Py_fred / Py_2024)
nf$EC_real  <- nf$EC_NF  / (nf$Py_fred / Py_2024)
nf$GOS_real <- nf$GOS_NF / (nf$Py_fred / Py_2024)

# ── Merge capacity utilization from Stage A ──────────────────────────────────
mu_merge <- data.frame(
  year   = mu$year,
  theta  = mu$theta,
  mu     = mu$mu,
  mu_ect = mu$mu_ect
)
nf <- merge(nf, mu_merge, by = "year")


# ═══════════════════════════════════════════════════════════════════════════════
# ASSEMBLE DATASET
# ═══════════════════════════════════════════════════════════════════════════════

ds <- data.frame(
  year     = nf$year,

  # ── Income accounts (nominal, millions $) ──────────────────────────────────
  GVA      = nf$GVA_NF,         # Gross Value Added
  EC       = nf$EC_NF,          # Total Employment Compensation
  GOS      = nf$GOS_NF,         # Gross Operating Surplus

  # ── Distribution shares ────────────────────────────────────────────────────
  omega    = nf$Wsh_NF,         # Wage share = EC / GVA
  pi       = nf$Psh_NF,         # Profit share = GOS / GVA
  e        = nf$e_NF,           # Rate of exploitation = GOS / EC

  # ── Capital stocks ─────────────────────────────────────────────────────────
  KNC      = nf$KNC_NF,         # Net capital stock, current prices (millions $)
  KNR      = nf$KNR_NF,         # Net capital stock, 2024 prices (millions $)
  KGC      = nf$KGC_NF,         # Gross capital stock, current prices (millions $)
  KGR      = nf$KGR_NF,         # Gross capital stock, 2024 prices (millions $)

  # ── Investment ─────────────────────────────────────────────────────────────
  IGC      = nf$IGC_NF,         # Gross investment, current prices (millions $)

  # ── Price deflators (index, 2024 = 100) ────────────────────────────────────
  Py       = nf$Py_index,       # GDP deflator index (2024 = 100)
  pK       = nf$pK_index,       # Capital price deflator (2024 = 100)

  # ── Real values (2024 constant prices, millions $) ─────────────────────────
  GVA_real = nf$GVA_real,
  EC_real  = nf$EC_real,
  GOS_real = nf$GOS_real,

  # ── Structural objects from Stage A ────────────────────────────────────────
  theta    = nf$theta,          # theta(omega) = 8.924 - 12.851*omega
  mu       = nf$mu,             # Capacity utilization (pinned mu(1948) = 0.80)
  mu_ect   = nf$mu_ect          # Capacity utilization (ECT-based, centered on 1)
)

ds <- ds[order(ds$year), ]


# ═══════════════════════════════════════════════════════════════════════════════
# VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n=== VALIDATION ===\n")

# Shares sum to 1
share_err <- max(abs(ds$omega + ds$pi - 1))
cat(sprintf("omega + pi = 1 check: max error = %.2e  %s\n",
    share_err, ifelse(share_err < 1e-10, "PASS", "FAIL")))

# GVA = EC + GOS + TPI (taxes on production & imports)
# TPI is not in the dataset — the residual is the implicit TPI
tpi_implied <- ds$GVA - ds$EC - ds$GOS
cat(sprintf("GVA - EC - GOS = TPI (implicit): range [%.0f, %.0f]  %s\n",
    min(tpi_implied), max(tpi_implied),
    ifelse(all(tpi_implied >= 0), "PASS (all non-negative)", "CHECK")))

# pK consistency: KNC / KNR ~ pK_NF / pK_2024
pK_implied <- ds$KNC / ds$KNR
pK_ratio   <- nf$pK_NF / pK_2024
pK_err     <- max(abs(pK_implied - pK_ratio))
cat(sprintf("pK consistency check: max error = %.2e  %s\n",
    pK_err, ifelse(pK_err < 1e-6, "PASS", "CHECK")))

# No NAs
na_count <- sum(is.na(ds))
cat(sprintf("NA count: %d  %s\n", na_count,
    ifelse(na_count == 0, "PASS", "FAIL")))


# ═══════════════════════════════════════════════════════════════════════════════
# REPORT
# ═══════════════════════════════════════════════════════════════════════════════
cat(sprintf("\n=== DATASET: %d vars x %d obs (%d-%d) ===\n",
    ncol(ds), nrow(ds), min(ds$year), max(ds$year)))

cat(sprintf("\n%-10s %12s %12s %12s %12s\n", "Variable", "Min", "Max", "Mean", "SD"))
cat(strrep("-", 60), "\n")
for (v in names(ds)) {
  x <- ds[[v]]
  cat(sprintf("%-10s %12.2f %12.2f %12.2f %12.2f\n",
      v, min(x), max(x), mean(x), sd(x)))
}

# ── Save ─────────────────────────────────────────────────────────────────────
write_csv(ds, file.path(out_dir, "us_nf_corporate_stageBC.csv"))
cat(sprintf("\nSaved: %s/us_nf_corporate_stageBC.csv\n", out_dir))

# Variable definitions
cat("\n=== VARIABLE DEFINITIONS ===\n")
defs <- data.frame(
  variable = names(ds),
  description = c(
    "Year",
    "Gross Value Added, nominal (millions $)",
    "Total Employment Compensation, nominal (millions $)",
    "Gross Operating Surplus, nominal (millions $)",
    "Wage share = EC / GVA",
    "Profit share = GOS / GVA",
    "Rate of exploitation = GOS / EC",
    "Net capital stock, current prices (millions $)",
    "Net capital stock, 2024 constant prices (millions $)",
    "Gross capital stock, current prices (millions $)",
    "Gross capital stock, 2024 constant prices (millions $)",
    "Gross investment, current prices (millions $)",
    "GDP deflator index (2024 = 100)",
    "Capital price deflator index (2024 = 100)",
    "Gross Value Added, 2024 prices (millions $)",
    "Employment Compensation, 2024 prices (millions $)",
    "Gross Operating Surplus, 2024 prices (millions $)",
    "theta(omega) = 8.924 - 12.851*omega (transformation elasticity)",
    "Capacity utilization, pinned mu(1948) = 0.80, closure g(Y*) = theta*g(K)",
    "Capacity utilization, exp(ECT1 - mean(ECT1)), centered on 1"
  )
)
for (i in 1:nrow(defs)) {
  cat(sprintf("  %-10s  %s\n", defs$variable[i], defs$description[i]))
}

write_csv(defs, file.path(out_dir, "us_nf_corporate_stageBC_codebook.csv"))
cat(sprintf("\nSaved: %s/us_nf_corporate_stageBC_codebook.csv\n", out_dir))
