library(httr)
library(dplyr)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)

## Check D10 for deflator/base year info
d10_path <- file.path(root, "output", "US",
  "D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET",
  "csv", "D10_clean_us_source_of_truth_panel_wide.csv")
d10 <- read.csv(d10_path, check.names = FALSE, stringsAsFactors = FALSE)

## Check what real output variables exist and their naming
real_cols <- grep("REAL|real|2017|chained|deflator", names(d10), value = TRUE, ignore.case = TRUE)
cat("Real/deflator columns in D10:\n")
print(real_cols)

## Check first few values of key real variables
if ("Y_REAL_NFC_GVA_BASELINE" %in% names(d10)) {
  cat("\nY_REAL_NFC_GVA_BASELINE first 5:\n")
  print(head(d10[, c("year", "Y_REAL_NFC_GVA_BASELINE")], 5))
}

## Check if there's a GDP deflator or price index
price_cols <- grep("deflator|price|P_", names(d10), value = TRUE, ignore.case = TRUE)
cat("\nPrice/deflator columns:\n")
print(price_cols)
