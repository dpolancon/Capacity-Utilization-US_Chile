############################################################
# US_S15_demand_control_registration.R
#
# Constructs real non-accumulation demand AD_t = C + G + NX
# from nominal NIPA T10105, deflates using GDP implicit price
# deflator (2017 base, matching D10 Y_REAL_NFC_GVA_BASELINE),
# and registers it into the S14 source-of-truth panel.
#
# Output:
#   output/US/S15_DEMAND_CONTROL_REGISTRATION/csv/S14_ch2_source_of_truth_panel_long.csv
#   output/US/S15_DEMAND_CONTROL_REGISTRATION/csv/S14_object_role_ledger.csv
#   output/US/S15_DEMAND_CONTROL_REGISTRATION/csv/demand_control_audit.csv
############################################################

rm(list = ls())
options(stringsAsFactors = FALSE, scipen = 999)

library(httr)
library(dplyr)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output", "US", "S15_DEMAND_CONTROL_REGISTRATION")
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
## STEP 1: Fetch nominal components from T10105
## ==========================================================

message("=== Fetching NIPA T10105: Nominal GDP components ===")
t10105 <- fetch_nipa("T10105")

extract_line <- function(ln, label) {
  row <- t10105 |> filter(line_description == label) |>
    select(year, value) |> rename(!!label := value)
  if (nrow(row) == 0) { message(sprintf("  NOT FOUND line %d: %s", ln, label)); return(NULL) }
  message(sprintf("  Line %d (%s): %d obs (%d-%d)",
                  ln, label, nrow(row), min(row$year), max(row$year)))
  row
}

gdp_nom <- extract_line(1, "Gross domestic product")
c_nom   <- extract_line(2, "Personal consumption expenditures")
g_nom   <- extract_line(22, "Government consumption expenditures and gross investment")
nx_nom  <- extract_line(15, "Net exports of goods and services")

if (any(sapply(list(gdp_nom, c_nom, g_nom, nx_nom), is.null))) stop("Missing nominal component.")

## ==========================================================
## STEP 2: Fetch real GDP from T10106 for deflator
## ==========================================================

message("\n=== Fetching T10106 for GDP deflator ===")
t10106 <- fetch_nipa("T10106")
gdp_real_bea <- t10106 |>
  filter(line_description == "Gross domestic product") |>
  select(year, Y_real_BEA = value)

## ==========================================================
## STEP 3: Construct AD_real_2017
## ==========================================================

ad_panel <- gdp_nom |>
  inner_join(c_nom, by = "year") |>
  inner_join(g_nom, by = "year") |>
  inner_join(nx_nom, by = "year") |>
  inner_join(gdp_real_bea, by = "year") |>
  rename(Y_nominal = `Gross domestic product`,
         C_nominal = `Personal consumption expenditures`,
         G_nominal = `Government consumption expenditures and gross investment`,
         NX_nominal = `Net exports of goods and services`) |>
  mutate(
    AD_nominal = C_nominal + G_nominal + NX_nominal,
    P_GDP = (Y_nominal / Y_real_BEA) * 100,
    P_2017 = P_GDP / P_GDP[year == 2017] * 100,
    AD_real_2017 = AD_nominal / (P_2017 / 100),
    log_AD_real = log(AD_real_2017)
  ) |>
  arrange(year)

message(sprintf("\n  AD_real_2017: %d obs, %d-%d",
                nrow(ad_panel), min(ad_panel$year), max(ad_panel$year)))

## ==========================================================
## STEP 4: Read S14 panel and append AD_real_2017
## ==========================================================

s14_dir <- file.path(root, "output", "US", "S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION")
s14_panel <- read.csv(file.path(s14_dir, "csv", "S14_ch2_source_of_truth_panel_long.csv"),
                       check.names = FALSE, stringsAsFactors = FALSE)
s14_ledger <- read.csv(file.path(s14_dir, "csv", "S14_object_role_ledger.csv"),
                        check.names = FALSE, stringsAsFactors = FALSE)

## Build long-format rows for AD_real_2017
ad_long <- ad_panel |>
  mutate(
    variable_id = "AD_REAL_NONACCUMULATION_2017",
    asset_block = "MACRO",
    value = AD_real_2017,
    unit = "millions_2017_dollars",
    object_role = "DEMAND_CONTROL_REGRESSOR",
    downstream_consumption_status = "BASELINE_CONSUMABLE",
    construction_stage = "NIPA_T10105_DEFLATED",
    source_table = "NIPA_T10105_T10106",
    notes = "Real non-accumulation demand: AD_t = C + G + NX, deflated by GDP implicit price deflator (2017=100). Matches D10 base year. Single regressor absorbs demand-side variation in observed output, preserving degrees of freedom for supply-side theta parameters.",
    chapter2_object_family = "demand_control",
    source_of_truth_role = "demand_control_regressor",
    source_of_truth_status = "REGISTERED_BASELINE",
    architecture_layer = "S15_DEMAND_CONTROL_REGISTRATION",
    registered_from_stage = "S15_DEMAND_CONTROL_REGISTRATION",
    downstream_stage_owner = "S20_MODEL_INPUT_LAYER",
    transformation_applied = "nominal_to_real_2017_base"
  ) |>
  select(names(s14_panel))

## Also add log version
ad_log_long <- ad_panel |>
  mutate(
    variable_id = "LOG_AD_REAL_NONACCUMULATION",
    asset_block = "MACRO",
    value = log_AD_real,
    unit = "log_millions_2017_dollars",
    object_role = "DEMAND_CONTROL_REGRESSOR_LOG",
    downstream_consumption_status = "BASELINE_CONSUMABLE",
    construction_stage = "NIPA_T10105_DEFLATED_LOG",
    source_table = "NIPA_T10105_T10106",
    notes = "Log of real non-accumulation demand. For cointegrating regression with log(Y_NFC).",
    chapter2_object_family = "demand_control",
    source_of_truth_role = "demand_control_regressor_log",
    source_of_truth_status = "REGISTERED_BASELINE",
    architecture_layer = "S15_DEMAND_CONTROL_REGISTRATION",
    registered_from_stage = "S15_DEMAND_CONTROL_REGISTRATION",
    downstream_stage_owner = "S20_MODEL_INPUT_LAYER",
    transformation_applied = "log_of_real_2017_base"
  ) |>
  select(names(s14_panel))

updated_panel <- bind_rows(s14_panel, ad_long, ad_log_long)
updated_panel <- updated_panel |> arrange(variable_id, asset_block, year)

## Update ledger
new_ledger_rows <- data.frame(
  variable_id = c("AD_REAL_NONACCUMULATION_2017", "LOG_AD_REAL_NONACCUMULATION"),
  asset_block = c("MACRO", "MACRO"),
  object_role = c("DEMAND_CONTROL_REGRESSOR", "DEMAND_CONTROL_REGRESSOR_LOG"),
  source_of_truth_role = c("demand_control_regressor", "demand_control_regressor_log"),
  unit = c("millions_2017_dollars", "log_millions_2017_dollars"),
  coverage_start = min(ad_panel$year),
  coverage_end = max(ad_panel$year),
  observation_count = nrow(ad_panel),
  registration_status = "REGISTERED_BASELINE",
  stringsAsFactors = FALSE
)

updated_ledger <- bind_rows(s14_ledger, new_ledger_rows)

## ==========================================================
## STEP 5: Write outputs
## ==========================================================

write.csv(updated_panel, file.path(csv_dir, "S14_ch2_source_of_truth_panel_long.csv"),
          row.names = FALSE, na = "")
write.csv(updated_ledger, file.path(csv_dir, "S14_object_role_ledger.csv"),
          row.names = FALSE, na = "")

## Audit
audit <- data.frame(
  check = c("S14_rows_before", "S14_rows_after", "AD_real_obs", "AD_real_year_range",
            "AD_real_mean_2017", "AD_real_last", "I_share_mean", "I_share_min", "I_share_max",
            "deflator_2017_value", "ledger_rows_before", "ledger_rows_after"),
  value = c(nrow(s14_panel), nrow(updated_panel), nrow(ad_panel),
            paste(min(ad_panel$year), "-", max(ad_panel$year)),
            round(mean(ad_panel$AD_real_2017, na.rm = TRUE), 1),
            round(tail(ad_panel$AD_real_2017, 1), 1),
            round(mean(ad_panel$AD_nominal / (ad_panel$P_2017/100) / ad_panel$Y_real_BEA, na.rm = TRUE), 4),
            round(min(ad_panel$AD_nominal / (ad_panel$P_2017/100) / ad_panel$Y_real_BEA, na.rm = TRUE), 4),
            round(max(ad_panel$AD_nominal / (ad_panel$P_2017/100) / ad_panel$Y_real_BEA, na.rm = TRUE), 4),
            round(ad_panel$P_2017[ad_panel$year == 2017], 1),
            nrow(s14_ledger), nrow(updated_ledger)),
  stringsAsFactors = FALSE
)
write.csv(audit, file.path(csv_dir, "demand_control_audit.csv"), row.names = FALSE, na = "")

message(sprintf("\n=== Written ==="))
message(sprintf("  S14 panel: %d -> %d rows (+%d AD_real + %d log_AD)",
                nrow(s14_panel), nrow(updated_panel), nrow(ad_long), nrow(ad_log_long)))
message(sprintf("  S14 ledger: %d -> %d rows (+2 variables)",
                nrow(s14_ledger), nrow(updated_ledger)))
