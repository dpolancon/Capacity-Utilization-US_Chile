d10 <- read.csv("output/US/D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET/csv/D10_clean_us_source_of_truth_panel_wide.csv", check.names=FALSE)
print(names(d10))
print(head(d10[, c("year", "Y_REAL_NFC_GVA_BASELINE", "Y_NOMINAL_NFC_GVA_BASELINE")], 5))
