############################################################
# 51_build_corp_output.R — Build Corporate Output Series
#
# Constructs GVAcorp, VAcorp, NOScorp, ECcorp, DEPCcorp
# from NIPA Table 1.14 and Table 7.11.
#
# Applies Shaikh's imputed interest adjustment:
#   CorpImpIntAdj = -BankMonIntPaid - CorpNFNetImpIntPaid
#   GVAcorp = GVAcorpnipa + CorpImpIntAdj
#
# Reads: data/interim/bea_parsed/nipa_t1014.csv
#        data/interim/bea_parsed/nipa_t7011.csv
# Writes: data/processed/corp_output_series.csv
#
# Sources: 40_gdp_kstock_config.R, 99_utils.R
############################################################

rm(list = ls())

library(dplyr)
library(readr)

source("codes/40_gdp_kstock_config.R")
source("codes/99_utils.R")

## ----------------------------------------------------------
## Load NIPA tables
## ----------------------------------------------------------

load_nipa <- function(label) {
  path <- file.path(GDP_CONFIG$INTERIM_BEA_PARSED, sprintf("%s.csv", label))
  if (!file.exists(path)) {
    stop("NIPA table not found: ", path,
         "\nRun 50_fetch_bea_corporate.R first.")
  }
  readr::read_csv(path, show_col_types = FALSE)
}

t1014 <- load_nipa("nipa_t1014")
t7011 <- load_nipa("nipa_t7011")

message(sprintf("Loaded NIPA T1.14: %d rows, years %d-%d",
                nrow(t1014), min(t1014$year), max(t1014$year)))
message(sprintf("Loaded NIPA T7.11: %d rows, years %d-%d",
                nrow(t7011), min(t7011$year), max(t7011$year)))

## ----------------------------------------------------------
## Extract line helper
## ----------------------------------------------------------

extract_line <- function(tbl, line, col_name) {
  tbl |>
    filter(line_number == line) |>
    select(year, !!col_name := value) |>
    arrange(year)
}

## ----------------------------------------------------------
## Extract from NIPA Table 1.14 (Corporate GVA)
## ----------------------------------------------------------

message("\n--- Extracting NIPA T1.14 series ---")

## Print all line labels for verification
unique_lines_1014 <- t1014 |>
  distinct(line_number, line_desc) |>
  arrange(line_number)
cat("  T1.14 line labels:\n")
for (i in seq_len(nrow(unique_lines_1014))) {
  cat(sprintf("    Line %2d: %s\n",
              unique_lines_1014$line_number[i],
              unique_lines_1014$line_desc[i]))
}

GVAcorpnipa <- extract_line(t1014, 1, "GVAcorpnipa")
DEPCcorp    <- extract_line(t1014, 2, "DEPCcorp")
VAcorpnipa  <- extract_line(t1014, 3, "VAcorpnipa")
ECcorp      <- extract_line(t1014, 4, "ECcorp")
Tcorp       <- extract_line(t1014, 7, "Tcorp")
NOScorpnipa <- extract_line(t1014, 8, "NOScorpnipa")
Pcorpnipa   <- extract_line(t1014, 11, "Pcorpnipa")

## ----------------------------------------------------------
## Extract from NIPA Table 7.11 (Interest)
## ----------------------------------------------------------

message("\n--- Extracting NIPA T7.11 series ---")

unique_lines_7011 <- t7011 |>
  distinct(line_number, line_desc) |>
  arrange(line_number)
cat("  T7.11 line labels (first 20):\n")
for (i in seq_len(min(20, nrow(unique_lines_7011)))) {
  cat(sprintf("    Line %2d: %s\n",
              unique_lines_7011$line_number[i],
              unique_lines_7011$line_desc[i]))
}

## Line 4: Monetary interest paid by financial corporate business
## (BankMonIntPaid in Shaikh's notation)
BankMonIntPaid <- extract_line(t7011, 4, "BankMonIntPaid")

## Lines 74 and 53: Nonfinancial corporate imputed interest
## Line 53: Imputed interest received by nonfinancial corporate
## Line 74: Imputed interest paid by nonfinancial corporate
## CorpNFNetImpIntPaid = Line 74 - Line 53
line74 <- extract_line(t7011, 74, "imp_int_paid_nf")
line53 <- extract_line(t7011, 53, "imp_int_recv_nf")

CorpNFNetImpIntPaid <- line74 |>
  left_join(line53, by = "year") |>
  mutate(CorpNFNetImpIntPaid = imp_int_paid_nf - imp_int_recv_nf) |>
  select(year, CorpNFNetImpIntPaid)

## ----------------------------------------------------------
## Merge and compute adjustments
## ----------------------------------------------------------

message("\n--- Computing imputed interest adjustment ---")

df <- GVAcorpnipa |>
  left_join(DEPCcorp,    by = "year") |>
  left_join(VAcorpnipa,  by = "year") |>
  left_join(ECcorp,      by = "year") |>
  left_join(Tcorp,       by = "year") |>
  left_join(NOScorpnipa, by = "year") |>
  left_join(Pcorpnipa,   by = "year") |>
  left_join(BankMonIntPaid,       by = "year") |>
  left_join(CorpNFNetImpIntPaid,  by = "year") |>
  arrange(year)

## Imputed interest adjustment (Shaikh Appendix 6.8)
df <- df |>
  mutate(
    CorpImpIntAdj = -BankMonIntPaid - CorpNFNetImpIntPaid,
    GVAcorp  = GVAcorpnipa + CorpImpIntAdj,
    NOScorp  = NOScorpnipa + CorpImpIntAdj,
    VAcorp   = VAcorpnipa  + CorpImpIntAdj,
    Pcorp    = Pcorpnipa  # No adjustment to profits (adjustment is to NOS/GVA)
  )


## ----------------------------------------------------------
## Validation vs 1947 targets
## ----------------------------------------------------------

message("\n=== CORPORATE OUTPUT VALIDATION (1947) ===")

v <- df |> filter(year == 1947)

targets <- tibble::tribble(
  ~variable,      ~computed,          ~target,
  "GVAcorpnipa",  v$GVAcorpnipa,     126.0,
  "GVAcorp",      v$GVAcorp,         127.5,
  "DEPCcorp",     v$DEPCcorp,          8.9,
  "VAcorpnipa",   v$VAcorpnipa,      117.1,
  "VAcorp",       v$VAcorp,          118.6,
  "ECcorp",       v$ECcorp,           82.1,
  "NOScorpnipa",  v$NOScorpnipa,      23.4,
  "NOScorp",      v$NOScorp,          24.9,
  "Pcorpnipa",    v$Pcorpnipa,        22.5,
  "Tcorp",        v$Tcorp,            11.5,
  "CorpImpIntAdj",v$CorpImpIntAdj,     1.5
)

for (i in seq_len(nrow(targets))) {
  gap <- targets$computed[i] - targets$target[i]
  flag <- ifelse(abs(gap) > 2.0, " *** WARNING ***", "")
  cat(sprintf("  %-15s: %8.1f | Target: %8.1f | Gap: %+.1f%s\n",
              targets$variable[i], targets$computed[i],
              targets$target[i], gap, flag))
}

if (abs(v$GVAcorp - 127.5) > 2.0) {
  message("\n  WARNING: GVAcorp_1947 deviates from target by more than 2.0!")
  message("  This may indicate a BEA vintage difference or line number mismatch.")
}

## Identity check: GVAcorp = VAcorp + DEPCcorp
identity_gap <- v$GVAcorp - (v$VAcorp + v$DEPCcorp)
cat(sprintf("  Identity check: GVAcorp - (VAcorp + DEPCcorp) = %.2f\n",
            identity_gap))


## ----------------------------------------------------------
## Write output
## ----------------------------------------------------------

out_cols <- c("year", "GVAcorpnipa", "GVAcorp", "DEPCcorp",
              "VAcorpnipa", "VAcorp", "ECcorp", "Tcorp",
              "NOScorpnipa", "NOScorp", "Pcorpnipa", "Pcorp",
              "BankMonIntPaid", "CorpNFNetImpIntPaid", "CorpImpIntAdj")

out_df <- df |> select(all_of(out_cols))

out_path <- file.path(GDP_CONFIG$PROCESSED, "corp_output_series.csv")
safe_write_csv(out_df, out_path)

message(sprintf("\nWritten: %s (%d rows, years %d-%d)",
                out_path, nrow(out_df),
                min(out_df$year), max(out_df$year)))
