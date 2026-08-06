# Wrapper script to run critical value simulations at three levels sequentially
source("codes/US_S52_section31_cmpr_bootstrap_critical_values.R")

cat("========================================================================\n")
cat("LAUNCHING OVERNIGHT BOOTSTRAP SIMULATION SUITE\n")
cat("========================================================================\n")

# Run 5k
cat("\n--- PHASE 1: Running 5,000 Simulations ---\n")
run_cmpr_simulation_suite(N_sim = 5000, T_obs = 94, out_csv = "output/US/S50_SECTION31_IMOLS/csv/cmpr_custom_critical_values_N5000.csv")

# Run 10k
cat("\n--- PHASE 2: Running 10,000 Simulations ---\n")
run_cmpr_simulation_suite(N_sim = 10000, T_obs = 94, out_csv = "output/US/S50_SECTION31_IMOLS/csv/cmpr_custom_critical_values_N10000.csv")

# Run 100k
cat("\n--- PHASE 3: Running 100,000 Simulations ---\n")
run_cmpr_simulation_suite(N_sim = 100000, T_obs = 94, out_csv = "output/US/S50_SECTION31_IMOLS/csv/cmpr_custom_critical_values_N100000.csv")

cat("\n========================================================================\n")
cat("ALL SIMULATION RUNS COMPLETED SUCCESSFULLY!\n")
cat("========================================================================\n")
