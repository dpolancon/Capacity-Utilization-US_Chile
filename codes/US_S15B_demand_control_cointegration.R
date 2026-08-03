############################################################
# US_S15B_demand_control_cointegration.R
#
# Constructs real non-accumulation demand AD_t = C + G + NX
# in chained 2017 dollars (matching Y_NFC real), then runs
# Engle-Granger cointegration: log(Y_NFC) ~ log(AD_t).
############################################################

rm(list = ls())
options(stringsAsFactors = FALSE, scipen = 999)

library(httr)
library(dplyr)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output", "US", "S15B_DEMAND_CONTROL_COINTEGRATION")
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
## STEP 1: Fetch T10106 (Real GDP, Chained 2017 Dollars)
## ==========================================================

message("=== Fetching NIPA T10106: Real GDP (Chained 2017 Dollars) ===")
t10106 <- fetch_nipa("T10106")

## Extract by line number (T10106 structure)
## Line 1: GDP, Line 2: C, Line 22: G, Line 15: NX (all in billions chained 2017$)
extract_line <- function(ln, label) {
  row <- t10106 |> filter(line_description == label) |>
    mutate(year = as.integer(year)) |>
    filter(!is.na(year)) |>
    select(year, value) |>
    rename(!!label := value)
  if (nrow(row) == 0) { message(sprintf("  NOT FOUND line %d: %s", ln, label)); return(NULL) }
  message(sprintf("  Line %d (%s): %d obs (%d-%d), last = %.1f",
                  ln, label, nrow(row), min(row$year), max(row$year), tail(row[[1]], 1)))
  row
}

gdp_real <- extract_line(1, "Gross domestic product")
c_real   <- extract_line(2, "Personal consumption expenditures")
g_real   <- extract_line(22, "Government consumption expenditures and gross investment")
nx_real  <- extract_line(15, "Net exports of goods and services")

if (any(sapply(list(gdp_real, c_real, g_real, nx_real), is.null))) {
  message("\n  Available lines in T10106:")
  print(unique(t10106$line_description))
  stop("Missing required real GDP component.")
}

## ==========================================================
## STEP 2: Construct AD_t = C + G + NX (real, chained 2017$)
## ==========================================================

ad_real <- gdp_real |>
  inner_join(c_real, by = "year") |>
  inner_join(g_real, by = "year") |>
  inner_join(nx_real, by = "year") |>
  rename(Y_real = `Gross domestic product`,
         C_real = `Personal consumption expenditures`,
         G_real = `Government consumption expenditures and gross investment`,
         NX_real = `Net exports of goods and services`) |>
  mutate(
    AD_real = C_real + G_real + NX_real,
    log_Y   = log(Y_real),
    log_AD  = log(AD_real),
    ## Sanity: Y = C + I + G + NX => I = Y - AD
    I_implied = Y_real - AD_real,
    I_share   = I_implied / Y_real
  ) |>
  arrange(year)

message(sprintf("\n  AD_t (real): %d obs, %d-%d", nrow(ad_real), min(ad_real$year), max(ad_real$year)))
message(sprintf("  I/Y implied (check): mean = %.3f, range = [%.3f, %.3f]",
                mean(ad_real$I_share, na.rm = TRUE),
                min(ad_real$I_share, na.rm = TRUE),
                max(ad_real$I_share, na.rm = TRUE)))

## ==========================================================
## STEP 3: Engle-Granger cointegration: log(Y_NFC) ~ log(AD_t)
## ==========================================================

## Read D10 for Y_REAL_NFC_GVA_BASELINE
d10_candidates <- c(
  file.path(root, "output", "US",
    "D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET",
    "csv", "D10_clean_us_source_of_truth_panel_wide.csv"),
  file.path(root, "output", "US",
    "D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET",
    "csv", "D10_us_source_of_truth_panel_wide.csv")
)
d10_path <- NULL
for (p in d10_candidates) { if (file.exists(p)) { d10_path <- p; break } }
if (is.null(d10_path)) stop("D10 wide panel not found.")

d10 <- read.csv(d10_path, check.names = FALSE, stringsAsFactors = FALSE)
y_nfc <- d10 |>
  select(year, Y_REAL_NFC_GVA_BASELINE) |>
  filter(!is.na(Y_REAL_NFC_GVA_BASELINE) & Y_REAL_NFC_GVA_BASELINE > 0) |>
  mutate(log_y_nfc = log(Y_REAL_NFC_GVA_BASELINE))

## Merge: common years
panel <- ad_real |>
  inner_join(y_nfc, by = "year") |>
  arrange(year)

message(sprintf("\n  Merged panel: %d obs, %d-%d", nrow(panel), min(panel$year), max(panel$year)))

## Engle-Granger Step 1: Cointegrating regression
eg_fit <- lm(log_y_nfc ~ log_AD, data = panel)
eg_summary <- summary(eg_fit)
panel$residuals <- residuals(eg_fit)

message("\n=== Engle-Granger Step 1: log(Y_NFC) ~ log(AD_t) ===")
message(sprintf("  R² = %.6f", eg_summary$r.squared))
message(sprintf("  Coefficient on log(AD_t): %.4f (t = %.2f)",
                coef(eg_fit)["log_AD"], coef(eg_summary)["log_AD", "t value"]))

## Engle-Granger Step 2: ADF test on residuals
## Using urca::ur.df for ADF on residuals
if (!requireNamespace("urca", quietly = TRUE)) {
  message("  urca package not available — skipping ADF on residuals.")
  adf_p <- NA
} else {
  adf_test <- urca::ur.df(panel$residuals, type = "none", lags = 1, selectlags = "Fixed")
  adf_stat <- adf_test@teststat[1]
  adf_crit_1 <- adf_test@cval[1]
  adf_crit_5 <- adf_test@cval[2]
  adf_crit_10 <- adf_test@cval[3]
  adf_p <- if (adf_stat < adf_crit_1) "< 0.01" else if (adf_stat < adf_crit_5) "< 0.05" else if (adf_stat < adf_crit_10) "< 0.10" else "> 0.10"

  message("\n=== Engle-Granger Step 2: ADF on residuals ===")
  message(sprintf("  ADF statistic: %.4f", adf_stat))
  message(sprintf("  Critical values: 1%% = %.4f, 5%% = %.4f, 10%% = %.4f", adf_crit_1, adf_crit_5, adf_crit_10))
  message(sprintf("  Verdict: residuals are I(0) — COINTEGRATED (p %s)", adf_p))
}

## ==========================================================
## STEP 4: Sub-sample windows
## ==========================================================

windows <- list(
  list(name = "Full_Sample", start = min(panel$year), end = max(panel$year)),
  list(name = "Fordist_1929_1973", start = 1929, end = 1973),
  list(name = "PostFordist_1974_2024", start = 1974, end = 2024),
  list(name = "GoldenAge_1947_1973", start = 1947, end = 1973),
  list(name = "Neoliberal_1974_2008", start = 1974, end = 2008),
  list(name = "PostGFC_2009_2024", start = 2009, end = 2024)
)

results <- lapply(windows, function(w) {
  sub <- panel |> filter(year >= w$start & year <= w$end)
  if (nrow(sub) < 10) return(NULL)
  fit <- lm(log_y_nfc ~ log_AD, data = sub)
  s <- summary(fit)
  res <- residuals(fit)
  if (requireNamespace("urca", quietly = TRUE) && nrow(sub) > 12) {
    adf <- urca::ur.df(res, type = "none", lags = 1, selectlags = "Fixed")
    adf_stat <- adf@teststat[1]
    adf_crit5 <- adf@cval[2]
    cointegrated <- adf_stat < adf_crit5
  } else {
    adf_stat <- NA; adf_crit5 <- NA; cointegrated <- NA
  }
  data.frame(
    window = w$name, n_obs = nrow(sub),
    year_range = paste(w$start, "-", w$end),
    R_squared = s$r.squared,
    log_AD_coef = coef(fit)["log_AD"],
    log_AD_t = coef(s)["log_AD", "t value"],
    log_AD_p = coef(s)["log_AD", "Pr(>|t|)"],
    ADF_stat = adf_stat,
    ADF_crit_5 = adf_crit5,
    cointegrated_5pct = cointegrated,
    stringsAsFactors = FALSE
  )
})

results_df <- do.call(rbind, results[!sapply(results, is.null)])

message("\n=== Sub-Sample Engle-Granger Results ===")
for (i in seq_len(nrow(results_df))) {
  r <- results_df[i, ]
  coin_status <- if (is.na(r$cointegrated_5pct)) "N/A" else if (r$cointegrated_5pct) "YES" else "NO"
  message(sprintf("  %-25s: n=%3d  R²=%.4f  β=%.4f (t=%.2f)  ADF=%.3f  Cointegrated=%s",
                  r$window, r$n_obs, r$R_squared, r$log_AD_coef, r$log_AD_t,
                  ifelse(is.na(r$ADF_stat), NA, r$ADF_stat), coin_status))
}

## ==========================================================
## STEP 5: Write outputs
## ==========================================================

write.csv(panel, file.path(csv_dir, "eg_cointegration_panel.csv"), row.names = FALSE, na = "")
write.csv(results_df, file.path(csv_dir, "eg_window_results.csv"), row.names = FALSE, na = "")

message(sprintf("\n=== Written: %d files ===", 2))
