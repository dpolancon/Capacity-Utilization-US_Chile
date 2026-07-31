# scratch/view_post_fordist_specA_regimeB.R
dfA <- read.csv("output/US/BREAK_AWARE_IMOLS/combinatorics/specA_break_combinatorics_summary.csv")

cat("=== SPECIFICATION A POST-FORDISM REGIME B (INITIAL-STATE CENTERED) ===\n")
subA_PF <- dfA[!is.na(dfA$permutation_id) & dfA$centering_regime == "Regime_B_Initial_Centered" & 
               dfA$window == "Post_Fordist_1974_2024", ]

print(subA_PF[, c("permutation_id", "CN", "sigma_u", "C_shin", "cointegration_pass", 
                 "beta_Kcap_est", "beta_Kcap_t", "phi_omega_est", "phi_omega_t", 
                 "theta_1_est", "theta_1_t", "theta_K_brk_est", "theta_K_brk_t", "adjudication")])
