#!/usr/bin/env Rscript

# audit_supervisory_provenance.R
# Audit of supervisory compensation data provenance across BEA, BLS, and Shaikh-Tonak RMWND datasets.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
rmwnd_dir <- file.path(repo_root, "data", "raw", "US", "shaikh-data_v2.1.0", "rmwnd")
dict_f <- file.path(rmwnd_dir, "data_dictionary.csv")

cat("========================================================================================\n")
cat("DATA PROVENANCE AUDIT: SUPERVISORY & PRODUCTIVE LABOR COMPENSATION\n")
cat("========================================================================================\n")

if (file.exists(dict_f)) {
  dict <- read.csv(dict_f, stringsAsFactors = FALSE)
  cat("RMWND Data Dictionary Loaded: Total Rows =", nrow(dict), "\n\n")
  
  target_ids <- c("S504", "S511", "S512")
  matching_rows <- dict[dict$series_id %in% target_ids, ]
  
  for (i in 1:nrow(matching_rows)) {
    r <- matching_rows[i, ]
    cat(sprintf("Series: %-8s | Subseries: %-15s | Name: %-35s | Start: %d | End: %d\n",
                r$series_id, r$subseries_id, r$display_name, r$period_start, r$period_end))
    cat(sprintf("  -> Source: %s\n", r$source))
    cat(sprintf("  -> Construction: %s\n\n", r$construction_type))
  }
} else {
  cat("RMWND data dictionary not found at:", dict_f, "\n")
}

# Check if RMWND time-series data file exists
data_f <- file.path(rmwnd_dir, "rmwnd_annual.csv")
if (!file.exists(data_f)) {
  # Look for CSV files in rmwnd_dir
  csvs <- list.files(rmwnd_dir, pattern = "\\.csv$", full.names = TRUE)
  cat("CSV files in rmwnd directory:\n")
  print(basename(csvs))
  
  # Try to read the main dataset file if available
  data_f <- csvs[grep("annual|data|series|rmwnd", basename(csvs), ignore.case = TRUE)][1]
}

if (!is.na(data_f) && file.exists(data_f)) {
  cat("\nInspecting RMWND dataset file:", basename(data_f), "\n")
  df <- read.csv(data_f, stringsAsFactors = FALSE)
  cat("Dataset dimensions:", nrow(df), "rows x", ncol(df), "cols\n")
  cols_interest <- grep("S504|S511|S512|year", colnames(df), value = TRUE, ignore.case = TRUE)
  cat("Matching columns:\n")
  print(cols_interest)
  
  if (length(cols_interest) > 0) {
    head_df <- head(df[, cols_interest], 10)
    print(head_df)
  }
}

cat("========================================================================================\n")
