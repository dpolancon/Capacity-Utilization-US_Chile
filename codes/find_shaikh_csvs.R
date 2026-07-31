#!/usr/bin/env Rscript

root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/US/shaikh-data_v2.1.0"
csvs <- list.files(root, pattern = "\\.csv$", recursive = TRUE, full.names = TRUE)

cat("Found", length(csvs), "CSV files under shaikh-data_v2.1.0:\n")

for (c in csvs) {
  tryCatch({
    df <- read.csv(c, nrows = 5)
    cols <- colnames(df)
    matched <- grep("S512|S511|S504|V_star|supervis|ratio|share", cols, ignore.case = TRUE, value = TRUE)
    if (length(matched) > 0) {
      cat("\nFile:", relToRepo = gsub(".*Capacity-Utilization-US_Chile/", "", c), "\n")
      cat("  Matched Columns:", paste(matched, collapse = ", "), "\n")
    }
  }, error = function(e) {})
}
