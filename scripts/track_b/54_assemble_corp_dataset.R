############################################################
# 54_assemble_corp_dataset.R — Assemble Corporate Dataset
#
# Merges all corporate series + GDP deflator (Py) into a
# single self-contained CSV for the ARDL replication.
#
# Final deliverable:
#   data/processed/corporate_sector_dataset.csv
#
# This file must contain all series needed to run
# 20_S0_shaikh_faithful.R with:
#   CONFIG$y_nom = "GVAcorp"
#   CONFIG$k_nom = "KGCcorp"
#   CONFIG$p_index = "Py"
#
# Reads:
#   data/processed/corp_output_series.csv
#   data/processed/corp_kstock_series.csv
#   data/processed/corp_exploitation_series.csv
#   data/interim/gdp_components/gdp_deflator_fred.csv
#     OR data/processed/gdp_us_1925_2024.csv (fallback)
#
# Writes: data/processed/corporate_sector_dataset.csv
#
# Sources: 40_gdp_kstock_config.R, 99_utils.R
############################################################

rm(list = ls())

library(dplyr)
library(readr)

source("codes/40_gdp_kstock_config.R")
source("codes/99_utils.R")

## ----------------------------------------------------------
## Load component datasets
## ----------------------------------------------------------

load_processed <- function(filename, required = TRUE) {
  path <- file.path(GDP_CONFIG$PROCESSED, filename)
  if (!file.exists(path)) {
    ## Try interim path for GDP deflator
    path2 <- file.path(GDP_CONFIG$INTERIM_GDP, filename)
    if (file.exists(path2)) {
      return(readr::read_csv(path2, show_col_types = FALSE))
    }
    if (required) {
      stop("Required file not found: ", path)
    }
    return(NULL)
  }
  readr::read_csv(path, show_col_types = FALSE)
}

corp_out    <- load_processed("corp_output_series.csv")
corp_k      <- load_processed("corp_kstock_series.csv")
corp_exploit <- load_processed("corp_exploitation_series.csv")

message(sprintf("Corp output:       %d rows, years %d-%d",
                nrow(corp_out), min(corp_out$year), max(corp_out$year)))
message(sprintf("Corp K-stock:      %d rows, years %d-%d",
                nrow(corp_k), min(corp_k$year), max(corp_k$year)))
message(sprintf("Corp exploitation: %d rows, years %d-%d",
                nrow(corp_exploit), min(corp_exploit$year), max(corp_exploit$year)))


## ----------------------------------------------------------
## Load GDP deflator (Py)
## ----------------------------------------------------------

message("\n--- Loading GDP deflator (Py) ---")

## Primary: from script 50's FRED fetch
fred_defl_path <- file.path(GDP_CONFIG$INTERIM_GDP, "gdp_deflator_fred.csv")
## Fallback: from 40-series pipeline
gdp_path <- file.path(GDP_CONFIG$PROCESSED, "gdp_us_1925_2024.csv")

if (file.exists(fred_defl_path)) {
  py_df <- readr::read_csv(fred_defl_path, show_col_types = FALSE)
  message(sprintf("  Loaded FRED GDP deflator: %d rows", nrow(py_df)))
  if (!"Py" %in% names(py_df)) {
    ## Try common column names
    if ("gdp_deflator" %in% names(py_df)) {
      py_df <- py_df |> rename(Py = gdp_deflator)
    } else if ("value" %in% names(py_df)) {
      py_df <- py_df |> rename(Py = value)
    }
  }
} else if (file.exists(gdp_path)) {
  gdp_df <- readr::read_csv(gdp_path, show_col_types = FALSE)
  ## Extract Py (GDP deflator) column
  if ("gdp_deflator" %in% names(gdp_df)) {
    py_df <- gdp_df |> select(year, Py = gdp_deflator)
  } else if ("Py" %in% names(gdp_df)) {
    py_df <- gdp_df |> select(year, Py)
  } else {
    stop("Cannot find GDP deflator column in ", gdp_path)
  }
  message(sprintf("  Loaded GDP deflator from 40-series: %d rows", nrow(py_df)))
} else {
  stop("No GDP deflator source found.\n",
       "  Expected: ", fred_defl_path, "\n",
       "  Or: ", gdp_path, "\n",
       "  Run 50_fetch_bea_corporate.R first.")
}

py_df <- py_df |> select(year, Py) |> arrange(year)
message(sprintf("  Py(1947) = %.3f, Py(2017) = %.3f",
                py_df$Py[py_df$year == 1947],
                py_df$Py[py_df$year == 2017]))


## ----------------------------------------------------------
## Merge all components
## ----------------------------------------------------------

message("\n--- Assembling corporate sector dataset ---")

df <- corp_out |>
  select(year, GVAcorp, VAcorp, DEPCcorp, NOScorp, ECcorp, Pcorp,
         GVAcorpnipa, VAcorpnipa, NOScorpnipa, Pcorpnipa, Tcorp,
         CorpImpIntAdj) |>
  inner_join(
    corp_k |> select(year, KGCcorp, KNCcorp, KNCcorpbea, KNRcorpbea,
                     IGCcorpbea, DEPCcorpbea, dcorpstar, dcorp_WL, pKN),
    by = "year"
  ) |>
  left_join(
    corp_exploit |> select(year, exploit_rate, profit_share, rcorp, R_obs, R_net),
    by = "year"
  ) |>
  left_join(py_df, by = "year") |>
  arrange(year)

## Add uK placeholder (filled by ARDL run)
df <- df |> mutate(uK = NA_real_)

message(sprintf("  Assembled: %d rows, %d columns, years %d-%d",
                nrow(df), ncol(df), min(df$year), max(df$year)))


## ----------------------------------------------------------
## Identity checks
## ----------------------------------------------------------

message("\n--- Identity checks ---")

## GVAcorp = VAcorp + DEPCcorp
df <- df |>
  mutate(gva_gap = GVAcorp - (VAcorp + DEPCcorp))

gva_violations <- df |> filter(abs(gva_gap) >= 0.5)
if (nrow(gva_violations) > 0) {
  cat("  WARNING: GVAcorp != VAcorp + DEPCcorp in these years:\n")
  for (i in seq_len(nrow(gva_violations))) {
    cat(sprintf("    %d: gap = %.2f\n",
                gva_violations$year[i], gva_violations$gva_gap[i]))
  }
} else {
  message("  GVAcorp = VAcorp + DEPCcorp: PASS (all gaps < 0.5)")
}

## Remove temp column
df <- df |> select(-gva_gap)


## ----------------------------------------------------------
## Required columns check
## ----------------------------------------------------------

REQUIRED_COLS <- c(
  "year", "GVAcorp", "VAcorp", "DEPCcorp", "NOScorp", "ECcorp",
  "Pcorp", "KGCcorp", "KNCcorp", "Py", "pKN",
  "exploit_rate", "profit_share", "rcorp", "uK"
)

missing_cols <- setdiff(REQUIRED_COLS, names(df))
if (length(missing_cols) > 0) {
  stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
}
message(sprintf("  All %d required columns present", length(REQUIRED_COLS)))


## ----------------------------------------------------------
## Final verification block
## ----------------------------------------------------------

cat("\n=== CORPORATE SECTOR VERIFICATION ===\n")

if (1947 %in% df$year) {
  v <- df |> filter(year == 1947)
  cat(sprintf("GVAcorp_1947:  %8.1f | Target: 127.5\n", v$GVAcorp))
  cat(sprintf("VAcorp_1947:   %8.1f | Target: 118.6\n", v$VAcorp))
  cat(sprintf("DEPCcorp_1947: %8.1f | Target: 8.9\n", v$DEPCcorp))
  cat(sprintf("NOScorp_1947:  %8.1f | Target: 24.9\n", v$NOScorp))
  cat(sprintf("ECcorp_1947:   %8.1f | Target: 82.1\n", v$ECcorp))
  cat(sprintf("Pcorp_1947:    %8.1f | Target: 22.5\n", v$Pcorp))
  cat(sprintf("KGCcorp_1947:  %8.1f | Shaikh II.5: 141.9 | Canonical: ~170.6\n", v$KGCcorp))
  cat(sprintf("KNCcorp_1947:  %8.1f | Shaikh II.5: 77.77 | BEA 2011: 190.1\n", v$KNCcorp))
  cat(sprintf("Py_1947:       %8.3f | Should be ~11.43 (2017=100 base)\n", v$Py))
  cat(sprintf("pKN_1947:      %8.2f | Canonical: 11.69\n", v$pKN))
  cat(sprintf("exploit_1947:  %8.4f | Target: ~0.303\n", v$exploit_rate))
  cat(sprintf("profit_sh_1947:%8.4f | Target: ~0.210\n", v$profit_share))
}

cat(sprintf("Year range:    %d-%d\n", min(df$year), max(df$year)))
cat(sprintf("Columns:       %d\n", ncol(df)))
cat(sprintf("Rows:          %d\n", nrow(df)))


## ----------------------------------------------------------
## Smoke test: OLS theta pre-screen
## ----------------------------------------------------------

message("\n=== OLS THETA PRE-SCREEN ===")

df_w <- df |>
  filter(year >= 1947, year <= 2011, !is.na(Py), Py > 0) |>
  mutate(
    lnY = log(GVAcorp / (Py / 100)),
    lnK = log(KGCcorp / (Py / 100))
  ) |>
  filter(is.finite(lnY), is.finite(lnK))

if (nrow(df_w) > 10) {
  theta_ols <- cov(df_w$lnY, df_w$lnK) / var(df_w$lnK)
  cat(sprintf("OLS theta (pre-screen): %.4f\n", theta_ols))
  cat("Target: ~0.75 (current BEA vintage) or 0.661 (Shaikh 2016 vintage)\n")
  cat(sprintf("lnY_1947: %.4f | Shaikh target: ~6.54\n",
              df_w$lnY[df_w$year == 1947]))
  cat(sprintf("lnK_1947: %.4f | Shaikh target: ~6.60\n",
              df_w$lnK[df_w$year == 1947]))

  ## Structural break check
  cat("\n--- Structural break years ---\n")
  break_years <- c(1955, 1956, 1957, 1973, 1974, 1975, 1979, 1980, 1981)
  break_df <- df_w |>
    filter(year %in% break_years) |>
    mutate(dlnY = lnY - dplyr::lag(lnY)) |>
    select(year, lnY, lnK, dlnY)
  print(break_df)
} else {
  message("  Insufficient data for OLS theta (need 1947-2011 with valid Py)")
}


## ----------------------------------------------------------
## Write final dataset
## ----------------------------------------------------------

out_path <- file.path(GDP_CONFIG$PROCESSED, "corporate_sector_dataset.csv")
safe_write_csv(df, out_path)

cat(sprintf("\n=== Written: %s ===\n", out_path))
cat(sprintf("  %d rows, %d columns\n", nrow(df), ncol(df)))
cat(sprintf("  Year range: %d-%d\n", min(df$year), max(df$year)))
cat("  Ready for 20_S0_shaikh_faithful.R\n")
