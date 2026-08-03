p <- read.csv("output/US/S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION/csv/S14_ch2_source_of_truth_panel_long.csv", check.names=FALSE)
y <- p[p$variable_id == "Y_REAL_NFC_GVA_BASELINE", c("variable_id", "year", "value")]
print(head(y, 5))
print(str(y))
print(class(y$year))
print(class(y$value))
