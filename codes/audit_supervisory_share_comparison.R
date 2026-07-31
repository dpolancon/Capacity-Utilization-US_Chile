#!/usr/bin/env Rscript

# audit_supervisory_share_comparison.R
# Compares the historical Shaikh-Tonak RMWND supervisory share (1 - S512) 
# against the NFC supervisory compensation proxy.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
f_s512 <- file.path(repo_root, "data", "raw", "US", "shaikh-data_v2.1.0", "rmwnd", "csv", "S512.csv")

if (file.exists(f_s512)) {
  s512 <- read.csv(f_s512)
  s512$phi_rmwnd <- 1 - s512$S512.COMBINED
  
  cat("========================================================================================\n")
  cat("HISTORICAL SUPERVISORY WAGE BILL SHARE (1 - V*/W) FROM SHAIKH-TONAK RMWND DATASET\n")
  cat("========================================================================================\n")
  
  # Print key decadal benchmark years
  years_check <- c(1948, 1960, 1970, 1980, 1990, 2000, 2010, 2020, 2024)
  bench <- s512[s512$year %in% years_check, c("year", "S512.COMBINED", "phi_rmwnd")]
  colnames(bench) <- c("Year", "Productive_Wage_Share_(V*/W)", "Supervisory_Share_(1_-_V*/W)")
  print(bench, row.names = FALSE)
  
  cat("========================================================================================\n")
}
