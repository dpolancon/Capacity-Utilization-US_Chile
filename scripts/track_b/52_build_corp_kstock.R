############################################################
# 52_build_corp_kstock.R — Build Corporate Capital Stock (GPIM)
#
# Implements Shaikh's Generalized Perpetual Inventory Method
# for corporate-sector capital stocks (K by legal form).
#
# Three independently toggle-able adjustments:
#   ADJ_1: BEA 1993 depletion rates (dcorpstar vs Whelan-Liu)
#   ADJ_2: BEA 1993 initial value scaling (IRS/BEA ratio)
#   ADJ_3: IRS Depression-era scrapping (needs external data)
#
# IMPORTANT — TABLE DISAMBIGUATION:
# data/interim/bea_parsed/ may contain govt_net_cc.csv (fetched
# by script 41 as government Table 6.1). This script uses
# corp_net_cc.csv (fetched by script 50 as PRIVATE fixed assets
# by legal form, which is a DIFFERENT BEA table despite similar
# numbering). At runtime, we verify that "Corporate" appears
# in the line labels. If the response looks like government
# data, the script stops with an error.
# Write to: data/interim/bea_parsed/corp_net_cc.csv (NOT govt_net_cc.csv).
#
# Reads: data/interim/bea_parsed/corp_*.csv
#        data/processed/corp_output_series.csv (for DEPCcorp cross-check)
# Writes: data/processed/corp_kstock_series.csv
#
# Sources: 40_gdp_kstock_config.R, 99_utils.R, 97_kstock_helpers.R
############################################################

rm(list = ls())

library(dplyr)
library(readr)

source("codes/40_gdp_kstock_config.R")
source("codes/99_utils.R")
source("codes/97_kstock_helpers.R")

ensure_dirs(GDP_CONFIG)

## ----------------------------------------------------------
## Toggle structure (Shaikh Appendix 6.8 adjustments)
## ----------------------------------------------------------

CORP_ADJ <- list(
  ADJ1_BEA1993_DEPLETION = TRUE,   # Use dcorpstar vs Whelan-Liu
  ADJ2_BEA1993_INITIAL   = TRUE,   # Scale 1925 initial value by IRS ratio
  ADJ3_IRS_SCRAPPING     = FALSE   # IRS book value correction (needs file)
)

cat("=== Corporate K-stock adjustments ===\n")
for (nm in names(CORP_ADJ)) {
  cat(sprintf("  %s: %s\n", nm, CORP_ADJ[[nm]]))
}

## Corporate retirement rate: 1/L_corp where L_corp ~ 35 years
## Per GPIM_Formalization_v3 §1: gross stocks use retirement rate
RET_CORP <- 1 / 35   # 0.02857

## IRS/BEA ratio for initial value scaling (Shaikh II.5 row 19)
IRS_BEA_RATIO_1947 <- 0.793


## ----------------------------------------------------------
## Load parsed BEA tables (corporate by legal form)
## ----------------------------------------------------------

load_parsed <- function(label) {
  path <- file.path(GDP_CONFIG$INTERIM_BEA_PARSED, sprintf("%s.csv", label))
  if (!file.exists(path)) {
    stop("Parsed BEA table not found: ", path,
         "\nRun 50_fetch_bea_corporate.R first.")
  }
  readr::read_csv(path, show_col_types = FALSE)
}

tbl_net_cc    <- load_parsed("corp_net_cc")      # FAAt601
tbl_net_chain <- load_parsed("corp_net_chain")    # FAAt602
tbl_net_hist  <- load_parsed("corp_net_hist")     # FAAt603
tbl_dep_cc    <- load_parsed("corp_dep_cc")       # FAAt604
tbl_inv_cc    <- load_parsed("corp_inv_cc")       # FAAt607

message(sprintf("Loaded 5 corporate BEA tables. Year range: %d-%d",
                min(tbl_net_cc$year), max(tbl_net_cc$year)))


## ----------------------------------------------------------
## Extract corporate line from each table
## ----------------------------------------------------------

#' Find and extract the "Corporate" line from a BEA table
#'
#' @param tbl  Long-format BEA table
#' @param col_name Name for the extracted value column
#' @return tibble(year, col_name)
extract_corporate_line <- function(tbl, col_name) {
  ## Identify corporate line
  unique_lines <- tbl |>
    distinct(line_number, line_desc) |>
    arrange(line_number)

  corp_lines <- unique_lines |>
    filter(grepl("^\\s*Corporate\\b", line_desc, ignore.case = TRUE))

  if (nrow(corp_lines) == 0) {
    ## Try broader match
    corp_lines <- unique_lines |>
      filter(grepl("corporate", line_desc, ignore.case = TRUE))
  }

  if (nrow(corp_lines) == 0) {
    stop("No 'Corporate' line found in table for ", col_name,
         "\nAvailable lines:\n",
         paste(sprintf("  %d: %s", unique_lines$line_number,
                       unique_lines$line_desc), collapse = "\n"))
  }

  ## Use the first match (most specific corporate line)
  corp_line_num <- corp_lines$line_number[1]
  message(sprintf("  %s: using line %d = '%s'",
                  col_name, corp_line_num, corp_lines$line_desc[1]))

  tbl |>
    filter(line_number == corp_line_num) |>
    select(year, !!col_name := value) |>
    arrange(year)
}

message("\n--- Extracting corporate lines ---")

KNCcorpbea_df     <- extract_corporate_line(tbl_net_cc,    "KNCcorpbea")
KNRIndxcorpbea_df <- extract_corporate_line(tbl_net_chain, "KNRIndxcorpbea")
KNHcorpbea_df     <- extract_corporate_line(tbl_net_hist,  "KNHcorpbea")
DEPCcorpbea_df    <- extract_corporate_line(tbl_dep_cc,    "DEPCcorpbea")
IGCcorpbea_df     <- extract_corporate_line(tbl_inv_cc,    "IGCcorpbea")


## ----------------------------------------------------------
## Merge into single data frame
## ----------------------------------------------------------

df <- KNCcorpbea_df |>
  left_join(KNRIndxcorpbea_df, by = "year") |>
  left_join(KNHcorpbea_df,     by = "year") |>
  left_join(DEPCcorpbea_df,    by = "year") |>
  left_join(IGCcorpbea_df,     by = "year") |>
  arrange(year)

message(sprintf("Merged corporate data: %d rows, years %d-%d",
                nrow(df), min(df$year), max(df$year)))


## ----------------------------------------------------------
## Cross-check DEPCcorp with script 51 output
## ----------------------------------------------------------

corp_output_path <- file.path(GDP_CONFIG$PROCESSED, "corp_output_series.csv")
if (file.exists(corp_output_path)) {
  corp_out <- readr::read_csv(corp_output_path, show_col_types = FALSE)
  if ("DEPCcorp" %in% names(corp_out)) {
    check_df <- df |>
      inner_join(corp_out |> select(year, DEPCcorp_nipa = DEPCcorp), by = "year")
    max_gap <- max(abs(check_df$DEPCcorpbea - check_df$DEPCcorp_nipa), na.rm = TRUE)
    message(sprintf("  DEPCcorp cross-check (BEA FA vs NIPA): max gap = %.2f", max_gap))
    if (max_gap > 1.0) {
      message("  NOTE: DEPCcorp gap > 1.0 — may reflect BEA FA vs NIPA accounting differences")
    }
  }
}


## ----------------------------------------------------------
## §A. Deflator construction (Shaikh II.1)
## ----------------------------------------------------------

message("\n--- Computing deflators ---")

## Real net stock from chain QI (rebased to constant 2005 dollars)
## KNRcorpbea = KNRIndxcorpbea * KNCcorpbea[2005] / 100
base_2005_val <- df$KNCcorpbea[df$year == 2005]
if (length(base_2005_val) == 0 || is.na(base_2005_val)) {
  stop("No KNCcorpbea value for 2005 — needed for chain QI conversion")
}
message(sprintf("  KNCcorpbea(2005) = %.1f (base for chain QI conversion)", base_2005_val))

df <- df |>
  mutate(
    ## Convert chain QI index to real dollar levels
    KNRcorpbea = KNRIndxcorpbea * base_2005_val / 100,

    ## Implicit price deflator for net corporate K stock
    ## pKN = (KNCcorpbea / KNRcorpbea) * 100
    pKN = (KNCcorpbea / KNRcorpbea) * 100
  )

message(sprintf("  pKN range: %.2f to %.2f (100 = 2005 prices)",
                min(df$pKN, na.rm = TRUE), max(df$pKN, na.rm = TRUE)))
message(sprintf("  pKN(1947) = %.2f", df$pKN[df$year == 1947]))


## ----------------------------------------------------------
## §B. Depreciation rate construction
## ----------------------------------------------------------

message("\n--- Computing depreciation rates ---")

df <- df |>
  mutate(
    KNRcorpbea_lag = dplyr::lag(KNRcorpbea),
    KNCcorpbea_lag = dplyr::lag(KNCcorpbea)
  )

if (CORP_ADJ$ADJ1_BEA1993_DEPLETION) {
  message("  ADJ_1 ON: Using theoretically correct depreciation rate (dcorpstar)")
  ## Theoretically correct rate (eq. 6):
  ## dcorpstar(t) = DEPCcorp(t) / (pKN(t)/100 * KNRcorpbea(t-1))
  df <- df |>
    mutate(
      dcorpstar = gpim_depreciation_rate(DEPCcorpbea, pKN / 100, KNRcorpbea_lag),
      dcorp_WL  = gpim_whelan_liu_rate(DEPCcorpbea, KNCcorpbea_lag)
    )
  dep_rate_col <- "dcorpstar"
} else {
  message("  ADJ_1 OFF: Using Whelan-Liu approximation")
  df <- df |>
    mutate(
      dcorpstar = gpim_depreciation_rate(DEPCcorpbea, pKN / 100, KNRcorpbea_lag),
      dcorp_WL  = gpim_whelan_liu_rate(DEPCcorpbea, KNCcorpbea_lag)
    )
  dep_rate_col <- "dcorp_WL"
}

## Report depreciation rate summary
dep_rates <- df |> filter(!is.na(dcorpstar), year >= 1930)
message(sprintf("  dcorpstar mean (1930+): %.4f", mean(dep_rates$dcorpstar, na.rm = TRUE)))
message(sprintf("  dcorp_WL  mean (1930+): %.4f", mean(dep_rates$dcorp_WL, na.rm = TRUE)))


## ----------------------------------------------------------
## §C. Net stock accumulation (GPIM eq. 5)
## ----------------------------------------------------------

message("\n--- Building GPIM net stock ---")

## Get the active depreciation rate vector
dep_rate_vec <- df[[dep_rate_col]]

## Handle NAs in early periods (first observation has no lag)
first_valid <- min(which(!is.na(dep_rate_vec)))
if (first_valid > 1) {
  ## Fill initial NAs with mean of available rates
  dep_rate_vec[1:(first_valid - 1)] <- mean(dep_rate_vec, na.rm = TRUE)
}

## Initial value for net stock
if (CORP_ADJ$ADJ2_BEA1993_INITIAL) {
  message("  ADJ_2 ON: Scaling initial value by IRS/BEA ratio = ", IRS_BEA_RATIO_1947)
  K_net_R_0 <- df$KNRcorpbea[1] * IRS_BEA_RATIO_1947
} else {
  message("  ADJ_2 OFF: Using BEA initial value directly")
  K_net_R_0 <- df$KNRcorpbea[1]
}
message(sprintf("  Initial KNR (real, year %d): %.2f (BEA: %.2f)",
                df$year[1], K_net_R_0, df$KNRcorpbea[1]))

## Real investment: IG_R = IGCcorpbea / (pKN/100)
df <- df |>
  mutate(IG_R_net = IGCcorpbea / (pKN / 100))

## GPIM accumulation: K_net_R[t] = IG_R[t] + (1 - z[t]) * K_net_R[t-1]
KNR_gpim <- gpim_accumulate_real(df$IG_R_net, dep_rate_vec, K_net_R_0)

df <- df |>
  mutate(
    KNRcorp = KNR_gpim,
    ## Back to current cost: KNCcorp = KNRcorp * (pKN/100)
    KNCcorp = KNRcorp * (pKN / 100)
  )


## ----------------------------------------------------------
## §D. ADJ_3: IRS Depression-era scrapping
## ----------------------------------------------------------

if (CORP_ADJ$ADJ3_IRS_SCRAPPING) {
  irs_path <- here::here("data/raw/irs_book_value.csv")
  if (file.exists(irs_path)) {
    message("\n  ADJ_3 ON: Applying IRS scrapping correction")
    irs <- readr::read_csv(irs_path, show_col_types = FALSE)
    ## Apply IRS/BEA ratio for 1925-1947
    ## Then resume GPIM from adjusted 1947 value
    ## TODO: Implement when IRS data becomes available
    message("  ADJ_3: IRS file found but correction not yet implemented")
  } else {
    message("\n  ADJ_3 skipped: IRS book value file not available")
    message(sprintf("  Expected: %s", irs_path))
  }
} else {
  message("\n  ADJ_3 OFF: IRS scrapping correction disabled")
}


## ----------------------------------------------------------
## §E. Gross stock accumulation (GPIM with retirement rate)
## ----------------------------------------------------------

message("\n--- Building GPIM gross stock ---")
message(sprintf("  Retirement rate: %.4f (1/L_corp, L_corp = 35 yr)", RET_CORP))

## For gross stock, use the investment goods deflator (pIGcorpbea)
## to convert investment to real terms.
## However, we don't have pIGcorpbea from the BEA FA tables —
## it comes from the Shaikh canonical CSV or needs separate computation.
##
## Approach: use pKN as the deflator for gross stock construction too
## (common deflator for the corporate sector).
## This is consistent with GPIM single-deflation.

## Real investment for gross stock: same as for net stock
IG_R_gross <- df$IG_R_net

## Average depreciation rate for initial condition
avg_dep <- mean(dep_rate_vec, na.rm = TRUE)

## Build gross real stock
gross_result <- gpim_build_gross_real(
  IG_R       = IG_R_gross,
  ret        = RET_CORP,
  K_net_R_0  = K_net_R_0,   # adjusted initial net stock
  dep_rate   = avg_dep
)

df <- df |>
  mutate(
    KGRcorp = gross_result$K_gross_R,
    ## Back to current cost: KGCcorp = KGRcorp * (pKN/100)
    KGCcorp = KGRcorp * (pKN / 100)
  )


## ----------------------------------------------------------
## §F. SFC validation
## ----------------------------------------------------------

message("\n--- SFC validation ---")

n <- nrow(df)

## Net stock SFC (GPIM real): K_t = K_{t-1} + IG_t - D_t
sfc_net <- validate_sfc_identity(
  K     = df$KNRcorp[-1],
  K_lag = df$KNRcorp[-n],
  I     = df$IG_R_net[-1],
  D     = (dep_rate_vec * c(K_net_R_0, df$KNRcorp[-n]))[-1],
  label = "corp_net_gpim_real"
)
max_r_net <- max(abs(sfc_net$pct_residual), na.rm = TRUE)
message(sprintf("  NET GPIM SFC: max |resid| = %.6f %s",
                max_r_net,
                ifelse(max_r_net < 0.001, "[PASS]", "[WARN]")))

## Gross stock SFC (GPIM real)
sfc_gross <- validate_gross_sfc(
  K_gross     = df$KGRcorp[-1],
  K_gross_lag = df$KGRcorp[-n],
  I           = IG_R_gross[-1],
  Ret         = gross_result$ret_R[-1],
  label       = "corp_gross_gpim_real"
)
max_r_gross <- max(abs(sfc_gross$pct_residual), na.rm = TRUE)
message(sprintf("  GROSS GPIM SFC: max |resid| = %.6f %s",
                max_r_gross,
                ifelse(max_r_gross < 0.001, "[PASS]", "[WARN]")))


## ----------------------------------------------------------
## §G. Verification table
## ----------------------------------------------------------

message("\n=== CORPORATE K-STOCK VERIFICATION TABLE ===")

verify_years <- c(1947, 1960, 1980, 2000, 2011)
verify_years <- verify_years[verify_years %in% df$year]

verify_df <- df |>
  filter(year %in% verify_years) |>
  select(year, KNCcorpbea, KNCcorp, KGCcorp, dcorpstar, dcorp_WL, pKN)

cat(sprintf("%-6s %10s %10s %10s %8s %8s %8s\n",
            "Year", "KNCcorpbea", "KNCcorp", "KGCcorp",
            "dcorp*", "dcorp_WL", "pKN"))
cat(paste(rep("-", 60), collapse = ""), "\n")

for (i in seq_len(nrow(verify_df))) {
  r <- verify_df[i, ]
  cat(sprintf("%-6d %10.1f %10.1f %10.1f %8.4f %8.4f %8.2f\n",
              r$year, r$KNCcorpbea, r$KNCcorp, r$KGCcorp,
              r$dcorpstar, r$dcorp_WL, r$pKN))
}

## Compare vs Shaikh targets
if (1947 %in% df$year) {
  v47 <- df |> filter(year == 1947)
  cat("\n--- 1947 Shaikh comparison ---\n")
  cat(sprintf("  KNCcorp:    %.1f | Shaikh II.5 target: ~77.77\n", v47$KNCcorp))
  cat(sprintf("  KGCcorp:    %.1f | Shaikh II.5 target: ~141.9\n", v47$KGCcorp))
  cat(sprintf("  KNCcorpbea: %.1f | BEA 2011: 190.1\n", v47$KNCcorpbea))
  cat(sprintf("  pKN:        %.2f | Canonical CSV: 11.69\n", v47$pKN))

  cat("\n  NOTE: Gaps from Shaikh's II.5 targets reflect BEA vintage differences.\n")
  cat("  The current-vintage BEA data uses geometric depreciation (post-1997),\n")
  cat("  while Shaikh's 2011 vintage used finite service lives (BEA 1993 methodology).\n")
  cat("  This is a KNOWN finding of the critical replication — not a bug.\n")
}


## ----------------------------------------------------------
## §H. Write output
## ----------------------------------------------------------

out_cols <- c("year", "KNCcorpbea", "KNRcorpbea", "KNCcorp", "KNRcorp",
              "KGCcorp", "KGRcorp", "IGCcorpbea", "IG_R_net",
              "DEPCcorpbea", "dcorpstar", "dcorp_WL", "pKN",
              "KNHcorpbea", "KNRIndxcorpbea")

out_df <- df |> select(all_of(intersect(out_cols, names(df))))

out_path <- file.path(GDP_CONFIG$PROCESSED, "corp_kstock_series.csv")
safe_write_csv(out_df, out_path)

message(sprintf("\nWritten: %s (%d rows, years %d-%d)",
                out_path, nrow(out_df),
                min(out_df$year), max(out_df$year)))

## Report adjustment toggle state
cat("\n=== Adjustment toggles used ===\n")
for (nm in names(CORP_ADJ)) {
  cat(sprintf("  %s: %s\n", nm, CORP_ADJ[[nm]]))
}
