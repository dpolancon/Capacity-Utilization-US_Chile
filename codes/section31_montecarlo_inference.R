# Wrapper script to run critical value simulations at 100k level
source("codes/US_S52_section31_cmpr_montecarlo_critical_values.R")

cat("========================================================================\n")
cat("LAUNCHING MONTE CARLO SIMULATION SUITE (N=100,000)\n")
cat("========================================================================\n")

run_cmpr_simulation_suite(N_sim = 100000, T_obs = 94, out_csv = "output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_N100000.csv")

cat("\n========================================================================\n")
cat("SIMULATION RUN COMPLETED SUCCESSFULLY!\n")
cat("========================================================================\n")
