#!/usr/bin/env Rscript

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_csv <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")

df <- read.csv(input_csv, stringsAsFactors = FALSE)
df <- df[is.finite(df$k_cap), ]
df <- df[order(df$year), ]

# Fit LOESS on log K_cap with span 0.35
l_fit <- loess(k_cap ~ year, data = df, span = 0.35)
pred  <- predict(l_fit)

d1 <- c(NA, diff(pred))
d2 <- c(NA, diff(d1))

inflections <- c()
for (i in 3:(nrow(df) - 1)) {
  if (!is.na(d2[i]) && !is.na(d2[i+1])) {
    if ((d2[i] > 0 && d2[i+1] < 0) || (d2[i] < 0 && d2[i+1] > 0)) {
      inflections <- c(inflections, df$year[i])
    }
  }
}

cat("LOESS 2nd Derivative Zero-Crossings for k_cap (span = 0.35):\n")
print(inflections)
