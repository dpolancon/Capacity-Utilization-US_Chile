#!/usr/bin/env Rscript

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
us_file <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
us <- read.csv(us_file)
nr_col <- if ("k_NRC" %in% colnames(us)) "k_NRC" else "k_NR"
us <- us[!is.na(us$k_ME) & !is.na(us[[nr_col]]), ]
us$tau <- us$k_ME - us[[nr_col]]

# 1. Raw Data 2nd Difference
d1_raw <- c(NA, diff(us$tau))
d2_raw <- c(NA, diff(d1_raw))

raw_crossings <- c()
for (i in 3:(nrow(us) - 1)) {
  if (!is.na(d2_raw[i]) && !is.na(d2_raw[i+1])) {
    if ((d2_raw[i] > 0 && d2_raw[i+1] < 0) || (d2_raw[i] < 0 && d2_raw[i+1] > 0)) {
      raw_crossings <- c(raw_crossings, us$year[i])
    }
  }
}

# 2. LOESS Curve (span = 0.30) 2nd Difference
l_fit <- loess(tau ~ year, data = us, span = 0.3)
pred_tau <- predict(l_fit)
d1_loess <- c(NA, diff(pred_tau))
d2_loess <- c(NA, diff(d1_loess))

loess_crossings <- c()
for (i in 3:(nrow(us) - 1)) {
  if (!is.na(d2_loess[i]) && !is.na(d2_loess[i+1])) {
    if ((d2_loess[i] > 0 && d2_loess[i+1] < 0) || (d2_loess[i] < 0 && d2_loess[i+1] > 0)) {
      loess_crossings <- c(loess_crossings, us$year[i])
    }
  }
}

cat("=== COMPARISON OF SECOND DERIVATIVE ZERO-CROSSINGS ===\n\n")
cat("1. RAW DATA SECOND DIFFERENCE (d^2 tau_t / dt^2):\n")
cat("   Total Zero-Crossings Count:", length(raw_crossings), "\n")
cat("   Crossing Years:\n   ", paste(raw_crossings, collapse=", "), "\n\n")

cat("2. LOESS SMOOTHED CURVE (span = 0.30) SECOND DERIVATIVE:\n")
cat("   Total Zero-Crossings Count:", length(loess_crossings), "\n")
cat("   Crossing Years:\n   ", paste(loess_crossings, collapse=", "), "\n")
