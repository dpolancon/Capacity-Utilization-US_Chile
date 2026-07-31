#!/usr/bin/env Rscript

# COMMON_S36_kcap_loess_inflections.R
# Computes LOESS second derivative zero-crossings specifically for log K_cap scale

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_csv <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[is.finite(df$k_cap), ]
df <- df[order(df$year), ]

fit <- loess(k_cap ~ year, data = df, span = 0.30)
pred <- predict(fit)

d1 <- diff(pred) / diff(df$year)
d2 <- diff(d1) / diff(df$year[-1])

idx <- which(diff(sign(d2)) != 0)
inflection_years <- df$year[idx + 1]

cat("LOESS 2nd Derivative Inflection Years for k_cap (span = 0.30):\n")
print(inflection_years)
