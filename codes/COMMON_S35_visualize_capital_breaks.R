#!/usr/bin/env Rscript

# COMMON_S35_visualize_capital_breaks.R
# Data-first non-parametric LOESS visualization of capital stocks (US 1925-2021 & Chile 1920-2024)
# with 2nd derivative zero-crossing inflection overlays.

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
cl_file   <- file.path(repo_root, "data", "processed", "cl_s20", "chile_orthogonalized_panel.csv")
us_file   <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
fig_dir   <- file.path(repo_root, "output", "figures")

if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

png_file <- file.path(fig_dir, "chile_us_capital_breaks_loess.png")

png(png_file, width = 1100, height = 750, res = 120)
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1), family = "sans")

# 1. Chile Capital Levels LOESS (1920-2024)
if (file.exists(cl_file)) {
  cl <- read.csv(cl_file)
  cl <- cl[!is.na(cl$k_ME) & !is.na(cl$k_NR), ]
  plot(cl$year, cl$k_ME, type = "l", col = "blue", lwd = 2, ylim = range(c(cl$k_ME, cl$k_NR)),
       main = "Chile: Capital Stock Components (1920-2024)", xlab = "Year", ylab = "Log Capital Stock")
  lines(cl$year, cl$k_NR, col = "red", lwd = 2)
  abline(v = 1936, col = "darkblue", lty = 3, lwd = 1.5)
  abline(v = 1971, col = "darkgreen", lty = 2, lwd = 2)
  abline(v = 1982, col = "orange", lty = 2, lwd = 2)
  legend("bottomright", legend = c("k_ME (Machinery)", "k_NR (Structures)", "LOESS Inflect 1936", "LOESS Inflect 1971", "LOESS Inflect 1982"),
         col = c("blue", "red", "darkblue", "darkgreen", "orange"), lty = c(1, 1, 3, 2, 2), lwd = 1.5, cex = 0.75)
  
  ratio_cl <- cl$k_ME - cl$k_NR
  l_fit <- loess(ratio_cl ~ year, data = cl, span = 0.3)
  plot(cl$year, ratio_cl, type = "p", pch = 16, col = "gray40", cex = 0.6,
       main = "Chile: Capital Composition (tau_t) & LOESS 2nd Deriv Zero-Crossings", xlab = "Year", ylab = "k_ME - k_NR")
  lines(cl$year, predict(l_fit), col = "purple", lwd = 2.5)
  abline(v = c(1936, 1971, 1982), col = c("darkblue", "darkgreen", "orange"), lty = c(3, 2, 2), lwd = 1.5)
}

# 2. US Capital Levels LOESS Extended (1925-2021)
if (file.exists(us_file)) {
  us <- read.csv(us_file)
  nr_col <- if ("k_NRC" %in% colnames(us)) "k_NRC" else "k_NR"
  us <- us[!is.na(us$k_ME) & !is.na(us[[nr_col]]), ]
  plot(us$year, us$k_ME, type = "l", col = "blue", lwd = 2, ylim = range(c(us$k_ME, us[[nr_col]])),
       main = "US: Capital Stock Components Extended (1925-2021)", xlab = "Year", ylab = "Log Capital Stock")
  lines(us$year, us[[nr_col]], col = "red", lwd = 2)
  abline(v = 1933, col = "darkblue", lty = 3, lwd = 1.5) # Great Depression Trough
  abline(v = 1968, col = "darkgreen", lty = 2, lwd = 2) # Late-60s Fordist Profit Squeeze Inflection
  abline(v = 2008, col = "darkred", lty = 2, lwd = 2)   # GFC
  legend("bottomright", legend = c("k_ME (Machinery)", "k_NRC (Structures)", "LOESS Inflect 1933", "LOESS Inflect 1968", "LOESS Inflect 2008"),
         col = c("blue", "red", "darkblue", "darkgreen", "darkred"), lty = c(1, 1, 3, 2, 2), lwd = 1.5, cex = 0.75)

  ratio_us <- us$k_ME - us[[nr_col]]
  l_fit_us <- loess(ratio_us ~ year, data = us, span = 0.3)
  plot(us$year, ratio_us, type = "p", pch = 16, col = "gray40", cex = 0.6,
       main = "US: Capital Composition (tau_t) & LOESS 2nd Deriv Zero-Crossings", xlab = "Year", ylab = "k_ME - k_NRC")
  lines(us$year, predict(l_fit_us), col = "purple", lwd = 2.5)
  abline(v = c(1933, 1968, 2008), col = c("darkblue", "darkgreen", "darkred"), lty = c(3, 2, 2), lwd = 1.5)
}

dev.off()
cat("Data-first non-parametric capital break plot (US 1925-2021) saved to:", png_file, "\n")
