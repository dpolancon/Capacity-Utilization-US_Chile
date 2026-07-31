# scratch/view_fordist_specB_details.R
dfB <- read.csv("output/US/BREAK_AWARE_IMOLS/combinatorics/specB_break_combinatorics_summary.csv")

cat("=== SPECIFICATION B FORDIST ERA (1929-1973) REGIME B ESTIMATES ===\n")
subB_Ford <- dfB[!is.na(dfB$permutation_id) & dfB$centering_regime == "Regime_B_Initial_Centered" & 
                 dfB$window == "Fordist_1929_1973", ]

print(subB_Ford[, c("permutation_id", "CN", "sigma_u", "C_shin", 
                   "theta_NRC_est", "theta_NRC_t", 
                   "theta_kappa_est", "theta_kappa_t", 
                   "theta_omega_kappa_est", "theta_omega_kappa_t", 
                   "theta_kappa_pkappa_est", "theta_kappa_pkappa_t")])
