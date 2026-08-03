############################################################
# US_S15B_demand_control_real_series.R
#
# Constructs real non-accumulation demand AD_t = C + G + NX
# in nominal dollars from NIPA T10105, then deflates using
# the GDP implicit price deflator (same 2017 base as D10
# Y_REAL_NFC_GVA_BASELINE).
#
# Output:
#   output/US/S15B_DEMAND_CONTROL_REAL/csv/nonacc_demand_real_panel.csv
############################################################

rm(list = ls())
options(stringsAsFactors = FALSE, scipen = 999)

library(httr)
library(dplyr)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output", "US", "S15B_DEMAND_CONTROL_REAL")
csv_dir <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

BEA_KEY <- Sys.getenv("BEA_API_KEY")
if (!nzchar(BEA_KEY)) stop("BEA_API_KEY is not set.")

fetch_nipa <- function(table) {
  resp <- GET("https://apps.bea.gov/api/data",
    query = list(UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
      TableName = table, Frequency = "A", Year = "ALL", ResultFormat = "JSON"),
    timeout(120))
  stop_for_status(resp)
  payload <- content(resp, as = "parsed", simplifyVector = FALSE)
  records <- payload$BEAAPI$Results$Data
  years_raw <- vapply(records, function(x) x$TimePeriod, character(1))
  years_num <- suppressWarnings(as.integer(years_raw))
  descs <- vapply(records, function(x) x$LineDescription, character(1))
  vals_raw <- vapply(records, function(x) x$DataValue, character(1))
  vals <- suppressWarnings(as.numeric(gsub(",", "", vals_raw, fixed = TRUE)))
  data.frame(year = years_num, line_description = descs, value = vals,
             stringsAsFactors = FALSE) |> filter(!is.na(year) & !is.na(value))
}

## ==========================================================
## STEP 1: Fetch T10105 (Nominal GDP and components)
## ==========================================================

message("=== Fetching NIPA T10105: Gross Domestic Product (Current Dollars) ===")
t10105 <- fetch_nipa("T10105")

## T10105 line numbers:
## Line 1:  Gross domestic product
## Line 2:  Personal consumption expenditures
## Line 22: Government consumption expenditures and gross investment
## Line 15: Net exports of goods and services

extract_line <- function(ln, label) {
  row <- t10105 |> filter(line_description == label) |>
    select(year, value) |>
    rename(!!label := value)
  if (nrow(row) == 0) { message(sprintf("  NOT FOUND line %d: %s", ln, label)); return(NULL) }
  message(sprintf("  Line %d (%s): %d obs (%d-%d), last = %.1f",
                  ln, label, nrow(row), min(row$year), max(row$year), tail(row[[1]], 1)))
  row
}

gdp_nom <- extract_line(1, "Gross domestic product")
c_nom   <- extract_line(2, "Personal consumption expenditures")
g_nom   <- extract_line(22, "Government consumption expenditures and gross investment")
nx_nom  <- extract_line(15, "Net exports of goods and services")

if (any(sapply(list(gdp_nom, c_nom, g_nom, nx_nom), is.null))) {
  message("\n  Available lines in T10105:")
  print(unique(t10105$line_description))
  stop("Missing required nominal GDP component.")
}

## ==========================================================
## STEP 2: Construct nominal AD_t = C + G + NX
## ==========================================================

ad_nominal <- gdp_nom |>
  inner_join(c_nom, by = "year") |>
  inner_join(g_nom, by = "year") |>
  inner_join(nx_nom, by = "year") |>
  rename(Y_nominal = `Gross domestic product`,
         C_nominal = `Personal consumption expenditures`,
         G_nominal = `Government consumption expenditures and gross investment`,
         NX_nominal = `Net exports of goods and services`) |>
  mutate(
    AD_nominal = C_nominal + G_nominal + NX_nominal,
    I_implied = Y_nominal - AD_nominal,
    I_share = I_implied / Y_nominal
  ) |>
  arrange(year)

message(sprintf("\n  AD_nominal: %d obs, %d-%d",
                nrow(ad_nominal), min(ad_nominal$year), max(ad_nominal$year)))
message(sprintf("  I/Y implied: mean = %.3f, range = [%.3f, %.3f]",
                mean(ad_nominal$I_share, na.rm = TRUE),
                min(ad_nominal$I_share, na.rm = TRUE),
                max(ad_nominal$I_share, na.rm = TRUE)))

## ==========================================================
## STEP 3: Deflate using GDP implicit price deflator
##
## D10 uses 2017 as base year. We construct the GDP deflator
## as: P_GDP = Y_nominal / Y_real (from T10105 line 1 and
## T10106 line 1), then re-base to 2017 = 100.
## ==========================================================

message("\n=== Fetching T10106 for GDP deflator construction ===")
t10106 <- fetch_nipa("T10106")

gdp_real_bea <- t10106 |>
  filter(line_description == "Gross domestic product") |>
  select(year, Y_real_BEA = value)

if (nrow(gdp_real_bea) == 0) stop("T10106 GDP real not found.")

message(sprintf("  T10106 GDP real: %d obs (%d-%d)",
                nrow(gdp_real_bea), min(gdp_real_bea$year), max(gdp_real_bea$year)))

## Construct GDP deflator: P = Y_nom / Y_real * 100 (BEA convention)
deflator <- ad_nominal |>
  inner_join(gdp_real_bea, by = "year") |>
  mutate(
    P_GDP = (Y_nominal / Y_real_BEA) * 100,
    ## Re-base to 2017 = 100
    P_2017 = P_GDP / P_GDP[year == 2017] * 100
  )

message(sprintf("  GDP deflator (2017=100): range [%.1f, %.1f]",
                min(deflator$P_2017, na.rm = TRUE),
                max(deflator$P_2017, na.rm = TRUE)))

## Deflate AD_t to 2017 dollars
## AD_real_2017 = AD_nominal / (P_2017 / 100)
ad_real <- deflator |>
  mutate(
    AD_real_2017 = AD_nominal / (P_2017 / 100),
    log_AD_real = log(AD_real_2017),
    log_Y_NFC_proxy = log(Y_real_BEA)  ## proxy for Y_NFC real
  ) |>
  select(year, Y_nominal, C_nominal, G_nominal, NX_nominal, AD_nominal,
         I_implied, I_share, P_GDP, P_2017, AD_real_2017, log_AD_real,
         Y_real_BEA, log_Y_NFC_proxy)

message(sprintf("\n  AD_real_2017: %d obs, %d-%d",
                nrow(ad_real), min(ad_real$year), max(ad_real$year)))
message(sprintf("  AD_real_2017 last value: %.1f (billions 2017$)", tail(ad_real$AD_real_2017, 1)))

## ==========================================================
## STEP 4: Quick EG check against BEA real GDP
## ==========================================================

eg_fit <- lm(log_Y_NFC_proxy ~ log_AD_real, data = ad_real)
eg_s <- summary(eg_fit)
resid <- residuals(eg_fit)

message("\n=== Quick EG: log(Y_real_BEA) ~ log(AD_real_2017) ===")
message(sprintf("  R² = %.6f, β = %.4f (t = %.2f)",
                eg_s$r.squared, coef(eg_fit)["log_AD_real"],
                coef(eg_s)["log_AD_real", "t value"]))

if (requireNamespace("urca", quietly = TRUE)) {
  adf <- urca::ur.df(resid, type = "none", lags = 1, selectlags = "Fixed")
  message(sprintf("  ADF on residuals: %.3f (5%% crit = %.3f) → %s",
                  adf@teststat[1], adf@cval[2],
                  if (adf@teststat[1] < adf@cval[2]) "COINTEGRATED" else "NOT cointegrated"))
}

## ==========================================================
## STEP 5: Write output
## ==========================================================

write.csv(ad_real, file.path(csv_dir, "nonacc_demand_real_panel.csv"),
          row.names = FALSE, na = "")

message(sprintf("\n=== Written: nonacc_demand_real_panel.csv (%d rows) ===", nrow(ad_real)))
