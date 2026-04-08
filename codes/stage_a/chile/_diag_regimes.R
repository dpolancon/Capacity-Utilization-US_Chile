library(readr)
regime_df <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/stage_a/Chile/csv/stage2_regime_classification.csv",
                      show_col_types = FALSE)

cat("Regime 2 (binding) years:\n")
print(sort(regime_df$year[regime_df$R_t == 1]))

cat("\nRegime 1 (slack) years:\n")
print(sort(regime_df$year[regime_df$R_t == 0]))

cat(sprintf("\nRegime 2: %d obs | Regime 1: %d obs\n",
    sum(regime_df$R_t == 1), sum(regime_df$R_t == 0)))
