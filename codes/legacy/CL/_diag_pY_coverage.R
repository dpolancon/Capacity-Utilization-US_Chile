library(readr)
df <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/data/final/chile_tvecm_panel.csv", show_col_types=FALSE)
cat(sprintf("p_Y: %d non-NA out of %d\n", sum(!is.na(df$p_Y)), nrow(df)))
cat(sprintf("p_Y available from: %d\n", min(df$year[!is.na(df$p_Y)])))
cat(sprintf("p_Y range: [%.4f, %.4f]\n", min(df$p_Y, na.rm=TRUE), max(df$p_Y, na.rm=TRUE)))
# Show first non-NA years
pY_avail <- df[!is.na(df$p_Y), c("year","p_Y")]
cat("\nFirst 5 p_Y values:\n")
print(head(pY_avail, 5))
cat("\nLast 5 p_Y values:\n")
print(tail(pY_avail, 5))
