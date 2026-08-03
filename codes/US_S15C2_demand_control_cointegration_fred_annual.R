############################################################
# US_S15C2_demand_control_cointegration_fred_annual.R
#
# Builds real non-accumulation demand AD_t = C + G + NX from
# *annual* FRED real series (chained 2017 $).  NX is computed
# as the expenditure residual: NX = GDP - C - I - G.  This is
# equivalent to AD_t = GDP - I (non-accumulation demand), but
# keeps the component interpretation explicit.
#
# Series IDs (real, annual, chained 2017 $):
#   GDPA     Real Gross Domestic Product
#   PCECCA   Real Personal Consumption Expenditures
#   GPDICA   Real Gross Private Domestic Investment
#   GCECA    Real Government Consumption Expenditures & Gross Investment
#
# Why annual: FRED's annual aggregations of the quarterly SAAR
# series are identical to the published annual levels and avoid
# the mechanical averaging step.  They also avoid the 1970 net
# exports truncation issue in BEA NIPA T10106.
#
# Source identification note (per Qwen research):
#   FRED mirrors BEA NIPA; the Q07053USQ027NNBR vintage is not
#   needed because the GDP expenditure identity is used instead.
############################################################

rm(list = ls())
options(stringsAsFactors = FALSE, scipen = 999)

library(httr)
library(dplyr)
library(jsonlite)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output", "US", "S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION")
csv_dir <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

FRED_KEY <- Sys.getenv("FRED_API_KEY")
if (!nzchar(FRED_KEY)) stop("FRED_API_KEY is not set.")

`%||%` <- function(x, y) { if (is.null(x) || length(x) == 0L) y else x }

## ==========================================================
## STEP 1: Fetch annual real series from FRED
## ==========================================================

fetch_fred_annual <- function(series_id) {
  resp <- GET(
    "https://api.stlouisfed.org/fred/series/observations",
    query = list(
      api_key = FRED_KEY,
      file_type = "json",
      series_id = series_id,
      frequency = "a",
      aggregation_method = "avg",
      units = "lin"
    ),
    timeout(120)
  )
  stop_for_status(resp)
  payload <- content(resp, as = "parsed", simplifyVector = FALSE)
  obs <- payload$observations
  if (is.null(obs) || length(obs) == 0L) {
    stop("No observations returned for FRED series ", series_id)
  }
  df <- data.frame(
    date = sapply(obs, function(x) as.character(x$date)),
    value = suppressWarnings(as.numeric(sapply(obs, function(x) as.character(x$value)))),
    stringsAsFactors = FALSE
  )
  df$year <- suppressWarnings(as.integer(substr(df$date, 1, 4)))
  df <- df |> filter(!is.na(year) & !is.na(value)) |> arrange(year)
  message(sprintf("  %s: %d obs (%d-%d), last = %.3f",
                  series_id, nrow(df), min(df$year), max(df$year),
                  tail(df$value, 1)))
  df |> select(year, value)
}

fetch_fred_meta <- function(series_id) {
  resp <- GET(
    "https://api.stlouisfed.org/fred/series",
    query = list(api_key = FRED_KEY, file_type = "json", series_id = series_id),
    timeout(60)
  )
  stop_for_status(resp)
  s <- content(resp, as = "parsed", simplifyVector = FALSE)$seriess[[1]]
  data.frame(
    series_id = series_id,
    title = as.character(s$title %||% NA),
    freq = as.character(s$frequency %||% NA),
    units = as.character(s$units %||% NA),
    units_short = as.character(s$units_short %||% NA),
    seasonal = as.character(s$seasonal_adjustment %||% NA),
    start = as.character(s$observation_start %||% NA),
    end = as.character(s$observation_end %||% NA),
    stringsAsFactors = FALSE
  )
}

message("=== Fetching FRED annual real GDP and demand components ===")
series_ids <- c("GDPCA", "PCECCA", "GPDICA", "GCECA")
meta <- do.call(rbind, lapply(series_ids, fetch_fred_meta))
print(meta)

components <- lapply(setNames(series_ids, series_ids), fetch_fred_annual)

## ==========================================================
## STEP 2: Build annual AD_t = C + G + NX using GDP identity
## ==========================================================

fred_panel <- components$GDPCA |>
  rename(GDP_real = value) |>
  inner_join(components$PCECCA |> rename(C_real = value), by = "year") |>
  inner_join(components$GPDICA |> rename(I_real = value), by = "year") |>
  inner_join(components$GCECA |> rename(G_real = value), by = "year") |>
  mutate(
    NX_real = GDP_real - C_real - I_real - G_real,
    AD_real_fred = C_real + G_real + NX_real,   # = GDP_real - I_real
    log_AD_fred = log(AD_real_fred),
    C_share = C_real / GDP_real,
    I_share = I_real / GDP_real,
    G_share = G_real / GDP_real,
    NX_share = NX_real / GDP_real,
    AD_share = AD_real_fred / GDP_real
  ) |>
  arrange(year)

message(sprintf("\n  AD_t (FRED annual, real): %d obs, %d-%d",
                nrow(fred_panel), min(fred_panel$year), max(fred_panel$year)))
message(sprintf("  Implied component shares (latest): C=%.3f  I=%.3f  G=%.3f  NX=%.3f  AD/GDP=%.3f",
                tail(fred_panel$C_share, 1), tail(fred_panel$I_share, 1),
                tail(fred_panel$G_share, 1), tail(fred_panel$NX_share, 1),
                tail(fred_panel$AD_share, 1)))

## ==========================================================
## STEP 3: Merge with Y_NFC
## ==========================================================

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

panel <- fred_panel |>
  inner_join(y_nfc, by = "year") |>
  filter(!is.na(log_y_nfc) & !is.na(log_AD_fred) & AD_real_fred > 0 & Y_REAL_NFC_GVA_BASELINE > 0) |>
  arrange(year)

message(sprintf("  Merged Y_NFC + AD_t panel: %d obs, %d-%d",
                nrow(panel), min(panel$year), max(panel$year)))

## ==========================================================
## STEP 4: Engle-Granger cointegration
## ==========================================================

eg_fit <- lm(log_y_nfc ~ log_AD_fred, data = panel)
eg_summary <- summary(eg_fit)
panel$residuals <- residuals(eg_fit)

message("\n=== Engle-Granger Step 1: log(Y_NFC) ~ log(AD_t[FRED annual]) ===")
message(sprintf("  R² = %.6f", eg_summary$r.squared))
message(sprintf("  Coefficient on log(AD_t): %.4f (t = %.2f)",
                coef(eg_fit)["log_AD_fred"],
                coef(eg_summary)["log_AD_fred", "t value"]))

if (!requireNamespace("urca", quietly = TRUE)) {
  message("  urca not installed — skipping ADF.")
  adf_p <- NA
} else {
  adf_test <- urca::ur.df(panel$residuals, type = "none", lags = 1, selectlags = "Fixed")
  adf_stat <- adf_test@teststat[1]
  adf_crit_1 <- adf_test@cval[1]
  adf_crit_5 <- adf_test@cval[2]
  adf_crit_10 <- adf_test@cval[3]
  adf_p <- if (adf_stat < adf_crit_1) "< 0.01" else if (adf_stat < adf_crit_5) "< 0.05" else
            if (adf_stat < adf_crit_10) "< 0.10" else "> 0.10"

  message("\n=== Engle-Granger Step 2: ADF on residuals ===")
  message(sprintf("  ADF statistic: %.4f", adf_stat))
  message(sprintf("  Critical values: 1%% = %.4f, 5%% = %.4f, 10%% = %.4f",
                  adf_crit_1, adf_crit_5, adf_crit_10))
  message(sprintf("  Verdict: residuals are I(0) — COINTEGRATED (p %s)", adf_p))
}

## ==========================================================
## STEP 5: Sub-sample windows
## ==========================================================

windows <- list(
  list(name = "Full_Sample", start = min(panel$year), end = max(panel$year)),
  list(name = "Prewar_1929_1941", start = 1929, end = 1941),
  list(name = "WarAndReconversion_1942_1953", start = 1942, end = 1953),
  list(name = "GoldenAge_1947_1973", start = 1947, end = 1973),
  list(name = "Fordist_1929_1973", start = 1929, end = 1973),
  list(name = "PostFordist_1974_2024", start = 1974, end = 2024),
  list(name = "Neoliberal_1974_2008", start = 1974, end = 2008),
  list(name = "PostGFC_2009_2024", start = 2009, end = 2024)
)

results <- lapply(windows, function(w) {
  sub <- panel |> filter(year >= w$start & year <= w$end)
  if (nrow(sub) < 10) return(NULL)
  fit <- lm(log_y_nfc ~ log_AD_fred, data = sub)
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
    log_AD_coef = coef(fit)["log_AD_fred"],
    log_AD_t = coef(s)["log_AD_fred", "t value"],
    log_AD_p = coef(s)["log_AD_fred", "Pr(>|t|)"],
    ADF_stat = adf_stat,
    ADF_crit_5 = adf_crit5,
    cointegrated_5pct = cointegrated,
    stringsAsFactors = FALSE
  )
})

results_df <- do.call(rbind, results[!sapply(results, is.null)])

message("\n=== Sub-Sample Engle-Granger Results (FRED annual AD_t) ===")
for (i in seq_len(nrow(results_df))) {
  r <- results_df[i, ]
  coin_status <- if (is.na(r$cointegrated_5pct)) "N/A" else if (r$cointegrated_5pct) "YES" else "NO"
  message(sprintf("  %-32s: n=%3d  R²=%.4f  β=%.4f (t=%.2f)  ADF=%.3f  Cointegrated=%s",
                  r$window, r$n_obs, r$R_squared, r$log_AD_coef, r$log_AD_t,
                  ifelse(is.na(r$ADF_stat), NA, r$ADF_stat), coin_status))
}

## ==========================================================
## STEP 6: Write outputs
## ==========================================================

write.csv(meta, file.path(csv_dir, "fred_annual_series_metadata.csv"), row.names = FALSE, na = "")
write.csv(fred_panel, file.path(csv_dir, "fred_annual_ad_components_panel.csv"), row.names = FALSE, na = "")
write.csv(panel, file.path(csv_dir, "eg_fred_annual_cointegration_panel.csv"), row.names = FALSE, na = "")
write.csv(results_df, file.path(csv_dir, "eg_fred_annual_window_results.csv"), row.names = FALSE, na = "")

message(sprintf("\n=== Written: %d files ===", 4))
