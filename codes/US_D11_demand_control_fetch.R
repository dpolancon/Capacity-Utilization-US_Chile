############################################################
# US_D11_demand_control_fetch.R
#
# Fetches NIPA Table 1.1.10 (Percentage Shares of GDP) via BEA API,
# constructs the aggregate non-accumulation demand regressor:
#
#   ad_t = 1 - (I_t / Y_t) = (C_t + G_t + NX_t) / Y_t
#
# and merges it into the D10 source-of-truth panel.
#
# Output:
#   output/US/D11_DEMAND_CONTROL/csv/demand_control_panel.csv
#   output/US/D11_DEMAND_CONTROL/csv/d10_merged_with_ad.csv
############################################################

rm(list = ls())

library(httr)
library(dplyr)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output", "US", "D11_DEMAND_CONTROL")
csv_dir <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

BEA_KEY <- Sys.getenv("BEA_API_KEY")
if (!nzchar(BEA_KEY)) stop("BEA_API_KEY is not set.")

## ==========================================================
## STEP 1: Fetch NIPA T10110 (Percentage Shares of GDP)
## ==========================================================

message("\n=== Fetching NIPA Table 1.1.10: Percentage Shares of GDP ===")

resp <- GET(
  "https://apps.bea.gov/api/data",
  query = list(
    UserID = BEA_KEY,
    method = "GetData",
    datasetname = "NIPA",
    TableName = "T10110",
    Frequency = "A",
    Year = "ALL",
    ResultFormat = "JSON"
  ),
  timeout(120)
)
stop_for_status(resp)
payload <- content(resp, as = "parsed", simplifyVector = FALSE)
records <- payload$BEAAPI$Results$Data
if (is.null(records) || length(records) == 0L) stop("No data returned for T10110.")

df <- do.call(rbind, lapply(records, function(x) {
  data.frame(
    year = as.integer(x$TimePeriod),
    line_number = as.integer(x$LineNumber),
    line_description = as.character(x$LineDescription),
    value = suppressWarnings(as.numeric(gsub(",", "", x$DataValue))),
    stringsAsFactors = FALSE
  )
}))

message(sprintf("  Fetched %d rows from T10110", nrow(df)))

## ==========================================================
## STEP 2: Extract investment share (I/Y) and construct ad_t
## ==========================================================

## T10110 line 5 is "Gross domestic investment" as % of GDP
## (verify from line_description)
inv_share <- df |>
  filter(grepl("Gross domestic investment", line_description, ignore.case = TRUE)) |>
  select(year, inv_share_pct = value)

if (nrow(inv_share) == 0) {
  message("  Investment share line not found by name; scanning all lines:")
  print(unique(df$line_description))
  stop("Could not identify gross domestic investment share in T10110.")
}

message(sprintf("  Investment share: %d obs, %d-%d",
                nrow(inv_share), min(inv_share$year), max(inv_share$year)))

## ad_t = 1 - I_t/Y_t (convert from percentage to fraction)
ad_panel <- inv_share |>
  mutate(
    ad_t = 1 - (inv_share_pct / 100),
    inv_share_fraction = inv_share_pct / 100
  ) |>
  select(year, inv_share_pct, inv_share_fraction, ad_t)

## ==========================================================
## STEP 3: Merge into D10 source-of-truth panel
## ==========================================================

message("\n=== Merging into D10 panel ===")

d10_candidates <- c(
  file.path(root, "output", "US",
    "D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET",
    "csv", "D10_us_source_of_truth_panel_wide.csv"),
  file.path(root, "output", "US",
    "D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET",
    "csv", "D10_clean_us_source_of_truth_panel_wide.csv"),
  file.path(root, "output", "US",
    "D10_R3_FINAL_RECONCILIATION_CLOSURE_AND_HANDOFF",
    "rerun_files", "all_csv", "D10_us_source_of_truth_panel_wide.csv")
)

d10_path <- NULL
for (p in d10_candidates) {
  if (file.exists(p)) { d10_path <- p; break }
}

if (is.null(d10_path)) {
  stop("D10 wide panel not found. Run US_D10_us_econometric_and_accounting_source_of_truth_dataset.R first.")
}

d10 <- read.csv(d10_path, check.names = FALSE, stringsAsFactors = FALSE)
message(sprintf("  D10 panel: %d rows, %d columns", nrow(d10), ncol(d10)))

merged <- d10 |>
  left_join(ad_panel, by = "year")

n_missing_ad <- sum(is.na(merged$ad_t))
if (n_missing_ad > 0) {
  message(sprintf("  WARNING: %d years missing ad_t (pre-1929 investment share not available)", n_missing_ad))
}

## ==========================================================
## STEP 4: Write outputs
## ==========================================================

write.csv(ad_panel, file.path(csv_dir, "demand_control_panel.csv"),
          row.names = FALSE, na = "")
write.csv(merged, file.path(csv_dir, "d10_merged_with_ad.csv"),
          row.names = FALSE, na = "")

message(sprintf("\n=== Written ==="))
message(sprintf("  demand_control_panel.csv: %d rows (years %d-%d)",
                nrow(ad_panel), min(ad_panel$year), max(ad_panel$year)))
message(sprintf("  d10_merged_with_ad.csv:   %d rows, %d columns",
                nrow(merged), ncol(merged)))

## ==========================================================
## Verification
## ==========================================================

message("\n=== Verification ===")
for (yr in c(1929, 1933, 1947, 1973, 2000, 2008, 2020, 2024)) {
  row <- ad_panel |> filter(year == yr)
  if (nrow(row) > 0) {
    message(sprintf("  %d: I/Y = %.1f%%, ad_t = %.3f",
                    yr, row$inv_share_pct, row$ad_t))
  }
}
