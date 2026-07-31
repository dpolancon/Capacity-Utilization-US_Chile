#!/usr/bin/env Rscript

# audit_sample_sizes.R
# Forensic audit of sample sizes, non-missing observations, and year spans across repo datasets.

files <- c(
  "data/processed/us_s31j/us_staged_pending_conditioners.csv",
  "output/US/D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_clean_us_source_of_truth_panel_wide.csv",
  "output/US/S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION/csv/S29F_shaikh_tonak_wage_share_panel.csv",
  "data/raw/US/US_corporate_NF_kstock_distribution.csv"
)

cat("========================================================================================\n")
cat("FORENSIC SAMPLE SIZE & YEAR SPAN AUDIT ACROSS REPOSITORY DATASETS\n")
cat("========================================================================================\n")

for (f in files) {
  full_p <- file.path("C:/ReposGitHub/Capacity-Utilization-US_Chile", f)
  if (file.exists(full_p)) {
    df <- read.csv(full_p, stringsAsFactors = FALSE)
    if ("year" %in% colnames(df)) {
      yr <- as.numeric(df$year)
      yr_clean <- yr[!is.na(yr)]
      cat(sprintf("File: %-75s\n  -> Total Rows: %3d | Years: %d to %d (Span = %d years)\n", 
                  f, nrow(df), min(yr_clean), max(yr_clean), max(yr_clean) - min(yr_clean) + 1))
    }
  } else {
    cat(sprintf("File: %-75s | MISSING\n", f))
  }
}

cat("========================================================================================\n")
