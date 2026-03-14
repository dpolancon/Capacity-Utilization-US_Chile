############################################################
# 50_fetch_bea_corporate.R — Fetch BEA Corporate Fixed Assets
#                             + NIPA Corporate Output Tables
#                             + FRED GDP Deflator
#
# Downloads:
#   BEA FixedAssets: FAAt601-FAAt607 (Private FA by Legal Form)
#   BEA NIPA: T10114 (Table 1.14, Corporate GVA)
#             T70011 (Table 7.11, Interest Paid/Received)
#   FRED: A191RD3A086NBEA (GDP Implicit Price Deflator)
#
# Writes to:
#   data/interim/bea_parsed/corp_*.csv   (FixedAssets tables)
#   data/interim/bea_parsed/nipa_*.csv   (NIPA tables)
#   data/interim/gdp_components/gdp_deflator_fred.csv
#
# Requires: bea.R (or beaR), fredr, dplyr, readr
# Sources:  40_gdp_kstock_config.R, 99_utils.R, 97_kstock_helpers.R
############################################################

rm(list = ls())

library(dplyr)
library(readr)

source("codes/40_gdp_kstock_config.R")
source("codes/99_utils.R")
source("codes/97_kstock_helpers.R")

ensure_dirs(GDP_CONFIG)

## ----------------------------------------------------------
## Configuration
## ----------------------------------------------------------

force_refetch <- FALSE   # Set TRUE to re-download existing files

## BEA FixedAssets tables: Private FA by Legal Form (Section 6)
## These contain Corporate as a line item.
CORP_BEA_TABLES <- list(
  corp_net_cc    = "FAAt601",   # Table 6.1: Current-Cost Net Stock
  corp_net_chain = "FAAt602",   # Table 6.2: Chain-Type QI Net Stock
  corp_net_hist  = "FAAt603",   # Table 6.3: Historical-Cost Net Stock
  corp_dep_cc    = "FAAt604",   # Table 6.4: Current-Cost Depreciation
  corp_inv_cc    = "FAAt607"    # Table 6.7: Investment in Private FA
)

## BEA NIPA tables
NIPA_TABLES <- list(
  nipa_t1014 = "T10114",   # Table 1.14: Corporate GVA
  nipa_t7011 = "T70011"    # Table 7.11: Interest Paid/Received
)

## FRED series
FRED_DEFLATOR <- "A191RD3A086NBEA"  # GDP implicit price deflator (annual)


## ----------------------------------------------------------
## BEA API fetch (generalized for FixedAssets + NIPA)
## ----------------------------------------------------------

#' Fetch a BEA table via API (supports FixedAssets and NIPA datasets)
#'
#' @param table_name  BEA table name (e.g., "FAAt601" or "T10114")
#' @param api_key     BEA API key
#' @param dataset     BEA dataset name ("FixedAssets" or "NIPA")
#' @param year        Year parameter ("ALL" for FixedAssets, "X" for NIPA)
#' @return Data frame, or NULL on failure
fetch_bea_table <- function(table_name, api_key, dataset = "FixedAssets",
                             year = if (dataset == "NIPA") "X" else "ALL") {

  if (!requireNamespace("bea.R", quietly = TRUE)) {
    if (!requireNamespace("beaR", quietly = TRUE)) {
      stop("Neither bea.R nor beaR available. Install one with: ",
           "install.packages('bea.R')")
    }
  }

  message(sprintf("  Fetching %s from BEA API (dataset=%s)...", table_name, dataset))

  specs <- list(
    UserID      = api_key,
    Method      = "GetData",
    datasetname = dataset,
    TableName   = table_name,
    Frequency   = "A",
    Year        = year
  )

  tryCatch({
    if (requireNamespace("bea.R", quietly = TRUE)) {
      resp <- bea.R::beaGet(specs, asWide = FALSE)
    } else {
      resp <- beaR::beaGet(specs, asWide = FALSE)
    }

    if (is.null(resp) || nrow(resp) == 0) {
      message(sprintf("  Empty response for %s", table_name))
      return(NULL)
    }

    message(sprintf("  Got %d rows for %s", nrow(resp), table_name))
    resp

  }, error = function(e) {
    stop(sprintf("BEA API FAILED for %s (dataset=%s): %s",
                 table_name, dataset, e$message))
  })
}


## ----------------------------------------------------------
## FRED fetch (reuses pattern from 42_fetch_fred_gdp.R)
## ----------------------------------------------------------

fetch_fred_deflator <- function(series_id, api_key, max_retries = 4L) {
  if (!requireNamespace("fredr", quietly = TRUE)) {
    stop("fredr package required. Install with: install.packages('fredr')")
  }
  fredr::fredr_set_key(api_key)

  wait_secs <- 2

  for (attempt in seq_len(max_retries)) {
    result <- tryCatch({
      message(sprintf("  Fetching FRED %s (attempt %d)...", series_id, attempt))

      obs <- fredr::fredr(
        series_id         = series_id,
        observation_start = as.Date("1925-01-01"),
        observation_end   = as.Date("2024-12-31"),
        frequency         = "a"
      )

      if (is.null(obs) || nrow(obs) == 0) {
        message(sprintf("  Empty response for %s", series_id))
        return(NULL)
      }

      obs |>
        dplyr::transmute(
          date      = .data$date,
          year      = as.integer(format(.data$date, "%Y")),
          value     = .data$value,
          series_id = series_id
        )

    }, error = function(e) {
      message(sprintf("  Error fetching %s: %s", series_id, e$message))
      NULL
    })

    if (!is.null(result)) return(result)

    if (attempt < max_retries) {
      message(sprintf("  Retrying in %d seconds...", wait_secs))
      Sys.sleep(wait_secs)
      wait_secs <- wait_secs * 2
    }
  }

  stop(sprintf("FRED FAILED: %s after %d attempts", series_id, max_retries))
}


## ----------------------------------------------------------
## Disambiguation guard
## ----------------------------------------------------------

#' Verify that a parsed BEA table contains "Corporate" lines
#'
#' @param parsed Long-format tibble with line_desc column
#' @param label  Table label for error messages
verify_corporate_lines <- function(parsed, label) {
  unique_lines <- parsed |>
    dplyr::distinct(line_number, line_desc) |>
    dplyr::arrange(line_number)

  cat(sprintf("\n  --- %s: First 10 line labels ---\n", label))
  head_lines <- head(unique_lines, 10)
  for (i in seq_len(nrow(head_lines))) {
    cat(sprintf("    Line %2d: %s\n",
                head_lines$line_number[i],
                head_lines$line_desc[i]))
  }

  has_corporate <- any(grepl("corporate", unique_lines$line_desc,
                              ignore.case = TRUE))

  if (!has_corporate) {
    stop(sprintf(
      "DISAMBIGUATION ERROR: Table %s does NOT contain 'Corporate' lines.\n",
      label,
      "This may be the wrong BEA table. Check TableName parameter.\n",
      "Expected: Private FA by Legal Form (Section 6).\n",
      "Got lines: %s",
      paste(head(unique_lines$line_desc, 5), collapse = "; ")
    ))
  }

  corp_line <- unique_lines |>
    dplyr::filter(grepl("corporate", line_desc, ignore.case = TRUE))
  cat(sprintf("  Corporate line(s) found: %s\n",
              paste(sprintf("Line %d: %s", corp_line$line_number,
                            corp_line$line_desc), collapse = "; ")))
}


## ----------------------------------------------------------
## Main: Fetch BEA FixedAssets (corporate by legal form)
## ----------------------------------------------------------

log_file <- file.path(GDP_CONFIG$INTERIM_LOGS, "fetch_bea_corporate_log.txt")
dir.create(dirname(log_file), showWarnings = FALSE, recursive = TRUE)
log_conn <- file(log_file, open = "wt")

cat(sprintf("BEA Corporate Fetch — %s\n", now_stamp()), file = log_conn)

results <- list()

for (tbl_label in names(CORP_BEA_TABLES)) {
  tbl_name <- CORP_BEA_TABLES[[tbl_label]]
  out_path <- file.path(GDP_CONFIG$INTERIM_BEA_PARSED,
                         sprintf("%s.csv", tbl_label))

  ## Skip if already exists and not forcing refetch
  if (!force_refetch && file.exists(out_path)) {
    message(sprintf("\n[%s] Skipping %s — already exists: %s",
                    now_stamp(), tbl_label, out_path))
    cat(sprintf("SKIP: %s (exists)\n", tbl_label), file = log_conn)
    results[[tbl_label]] <- readr::read_csv(out_path, show_col_types = FALSE)
    next
  }

  message(sprintf("\n[%s] Processing %s (%s)...", now_stamp(), tbl_label, tbl_name))

  ## Fetch from API
  raw_resp <- fetch_bea_table(tbl_name, GDP_CONFIG$BEA_API_KEY,
                               dataset = "FixedAssets")

  if (is.null(raw_resp)) {
    msg <- sprintf("FAILED: %s (%s) — no data", tbl_label, tbl_name)
    message(msg)
    cat(msg, "\n", file = log_conn)
    stop(msg)
  }

  ## Parse to long format
  parsed <- parse_bea_api_response(raw_resp)

  ## Disambiguation check: verify "Corporate" lines exist
  verify_corporate_lines(parsed, tbl_label)

  ## Add metadata
  parsed <- parsed |>
    mutate(table_label = tbl_label,
           table_name  = tbl_name,
           source      = "API")

  ## Write parsed CSV
  safe_write_csv(parsed, out_path)

  ## Log
  msg <- sprintf("OK: %s (%s) — %d rows, years %d-%d",
                 tbl_label, tbl_name, nrow(parsed),
                 min(parsed$year), max(parsed$year))
  message(msg)
  cat(msg, "\n", file = log_conn)

  log_data_quality(parsed, tbl_label)
  results[[tbl_label]] <- parsed
}


## ----------------------------------------------------------
## Main: Fetch NIPA tables (corporate output + interest)
## ----------------------------------------------------------

message(sprintf("\n[%s] === Fetching NIPA tables ===", now_stamp()))

for (tbl_label in names(NIPA_TABLES)) {
  tbl_name <- NIPA_TABLES[[tbl_label]]
  out_path <- file.path(GDP_CONFIG$INTERIM_BEA_PARSED,
                         sprintf("%s.csv", tbl_label))

  ## Skip if already exists
  if (!force_refetch && file.exists(out_path)) {
    message(sprintf("\n[%s] Skipping %s — already exists", now_stamp(), tbl_label))
    cat(sprintf("SKIP: %s (exists)\n", tbl_label), file = log_conn)
    results[[tbl_label]] <- readr::read_csv(out_path, show_col_types = FALSE)
    next
  }

  message(sprintf("\n[%s] Processing %s (%s)...", now_stamp(), tbl_label, tbl_name))

  raw_resp <- fetch_bea_table(tbl_name, GDP_CONFIG$BEA_API_KEY,
                               dataset = "NIPA", year = "X")

  if (is.null(raw_resp)) {
    msg <- sprintf("FAILED: %s (%s)", tbl_label, tbl_name)
    message(msg)
    cat(msg, "\n", file = log_conn)
    stop(msg)
  }

  parsed <- parse_bea_api_response(raw_resp)

  ## Print first 10 line labels for NIPA tables
  unique_lines <- parsed |>
    dplyr::distinct(line_number, line_desc) |>
    dplyr::arrange(line_number)
  cat(sprintf("\n  --- %s: First 10 line labels ---\n", tbl_label))
  for (i in seq_len(min(10, nrow(unique_lines)))) {
    cat(sprintf("    Line %2d: %s\n",
                unique_lines$line_number[i],
                unique_lines$line_desc[i]))
  }

  parsed <- parsed |>
    mutate(table_label = tbl_label,
           table_name  = tbl_name,
           source      = "API")

  safe_write_csv(parsed, out_path)

  msg <- sprintf("OK: %s (%s) — %d rows, years %d-%d",
                 tbl_label, tbl_name, nrow(parsed),
                 min(parsed$year), max(parsed$year))
  message(msg)
  cat(msg, "\n", file = log_conn)

  log_data_quality(parsed, tbl_label)
  results[[tbl_label]] <- parsed
}


## ----------------------------------------------------------
## Main: Fetch FRED GDP deflator (Py)
## ----------------------------------------------------------

message(sprintf("\n[%s] === Fetching FRED GDP deflator ===", now_stamp()))

fred_out_dir <- GDP_CONFIG$INTERIM_GDP
dir.create(fred_out_dir, showWarnings = FALSE, recursive = TRUE)
fred_out_path <- file.path(fred_out_dir, "gdp_deflator_fred.csv")

if (!force_refetch && file.exists(fred_out_path)) {
  message(sprintf("Skipping FRED deflator — already exists: %s", fred_out_path))
  cat("SKIP: FRED GDP deflator (exists)\n", file = log_conn)
} else {
  fred_df <- fetch_fred_deflator(FRED_DEFLATOR, GDP_CONFIG$FRED_API_KEY)

  if (!is.null(fred_df) && nrow(fred_df) > 0) {
    ## Rename value to Py for clarity
    fred_df <- fred_df |>
      dplyr::rename(Py = value) |>
      dplyr::select(year, Py)

    safe_write_csv(fred_df, fred_out_path)

    msg <- sprintf("OK: FRED GDP deflator — %d obs, years %d-%d, Py_1947=%.3f",
                   nrow(fred_df), min(fred_df$year), max(fred_df$year),
                   fred_df$Py[fred_df$year == 1947])
    message(msg)
    cat(msg, "\n", file = log_conn)
  } else {
    stop("FRED GDP deflator fetch FAILED")
  }
}


## ----------------------------------------------------------
## Summary
## ----------------------------------------------------------

cat(sprintf("\nFetch complete: %d tables + FRED deflator — %s\n",
            length(results), now_stamp()),
    file = log_conn)
close(log_conn)

message(sprintf("\n=== Corporate sector fetch complete ==="))
message(sprintf("  BEA FixedAssets: %d tables", length(CORP_BEA_TABLES)))
message(sprintf("  NIPA tables: %d tables", length(NIPA_TABLES)))
message(sprintf("  FRED deflator: %s", FRED_DEFLATOR))
message(sprintf("  Parsed data: %s", GDP_CONFIG$INTERIM_BEA_PARSED))
message(sprintf("  Log: %s", log_file))
