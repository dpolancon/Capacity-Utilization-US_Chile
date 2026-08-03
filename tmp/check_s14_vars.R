p <- read.csv("output/US/S14_CH2_SOURCE_OF_TRUTH_CONSOLIDATION/csv/S14_ch2_source_of_truth_panel_long.csv", check.names=FALSE)
print(unique(p$variable_id))
print(table(p$variable_id))
