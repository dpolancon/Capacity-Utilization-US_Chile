# scratch/view_results.R
dfA <- read.csv("output/US/BREAK_AWARE_IMOLS/combinatorics/specA_break_combinatorics_summary.csv")
dfB <- read.csv("output/US/BREAK_AWARE_IMOLS/combinatorics/specB_break_combinatorics_summary.csv")

cat("=== SPECIFICATION A REGIME B RESULTS ===\n")
subA <- dfA[!is.na(dfA$permutation_id) & dfA$centering_regime == "Regime_B_Initial_Centered", 
            c("permutation_id", "window", "CN", "sigma_u", "wald_F", "wald_p", "adjudication")]
row.names(subA) <- NULL
print(subA)

cat("\n=== SPECIFICATION B REGIME B RESULTS ===\n")
subB <- dfB[!is.na(dfB$permutation_id) & dfB$centering_regime == "Regime_B_Initial_Centered", 
            c("permutation_id", "window", "CN", "sigma_u", "wald_F", "wald_p", "adjudication")]
row.names(subB) <- NULL
print(subB)
