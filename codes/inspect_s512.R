#!/usr/bin/env Rscript

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
f_s512 <- file.path(repo_root, "data", "raw", "US", "shaikh-data_v2.1.0", "rmwnd", "csv", "S512.csv")
f_s511 <- file.path(repo_root, "data", "raw", "US", "shaikh-data_v2.1.0", "rmwnd", "csv", "S511.csv")

cat("========================================================================================\n")
cat("INSPECTING SHAIKH-TONAK RMWND S512 (V*/W) & S511 (Lp/L)\n")
cat("========================================================================================\n")

if (file.exists(f_s512)) {
  s512 <- read.csv(f_s512)
  cat("S512 (Productive Wage Share V*/W) - Head & Tail:\n")
  print(head(s512, 10))
  print(tail(s512, 10))
}

if (file.exists(f_s511)) {
  s511 <- read.csv(f_s511)
  cat("\nS511 (Productive Labor Share Lp/L) - Head & Tail:\n")
  print(head(s511, 10))
  print(tail(s511, 10))
}

cat("========================================================================================\n")
