#!/usr/bin/env Rscript

# COMMON_S38_cointreg_strucchange_pipeline.R
# Single-equation super-consistent cointegration audit (cointReg: FM-OLS, DOLS, IM-OLS)
# and structural break testing (strucchange: Bai-Perron breakpoints, CUSUM, SupF/AveF/ExpF)

suppressMessages(library(cointReg))
suppressMessages(library(strucchange))
suppressMessages(library(ggplot2))
suppressMessages(library(gridExtra))
suppressMessages(library(dplyr))

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
cl_file   <- file.path(repo_root, "data", "processed", "cl_s20", "chile_orthogonalized_panel.csv")
us_file   <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
out_csv   <- file.path(repo_root, "output", "cointreg_strucchange_robustness_ledger.csv")
fig_dir   <- file.path(repo_root, "output", "figures")

if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

cat("=== Step 1: Loading Data ===\n")

cl_df <- read.csv(cl_file)
cl_df <- cl_df[!is.na(cl_df$k_ME) & !is.na(cl_df$k_NR), ]

us_df <- read.csv(us_file)
nr_col <- if ("k_NRC" %in% colnames(us_df)) "k_NRC" else "k_NR"
us_df <- us_df[!is.na(us_df$k_ME) & !is.na(us_df[[nr_col]]), ]
us_df$k_NR <- us_df[[nr_col]]

# Define windows list
windows_list <- list(
  # U.S. Windows
  list(country = "U.S.", label = "U.S. Full Century", start = 1925, end = 2021, df = us_df),
  list(country = "U.S.", label = "U.S. Interwar & WWII", start = 1925, end = 1946, df = us_df),
  list(country = "U.S.", label = "U.S. Fordist Golden Age", start = 1947, end = 1973, df = us_df),
  list(country = "U.S.", label = "U.S. Neoliberal Restructuring", start = 1974, end = 2008, df = us_df),
  list(country = "U.S.", label = "U.S. Post-GFC Stagnation", start = 2009, end = 2021, df = us_df),
  
  # Chile Windows
  list(country = "Chile", label = "Chile Full Century", start = 1920, end = 2024, df = cl_df),
  list(country = "Chile", label = "Chile Nitrate Crisis & Early State", start = 1920, end = 1938, df = cl_df),
  list(country = "Chile", label = "Chile Pre-1973 ISI Era", start = 1939, end = 1973, df = cl_df),
  list(country = "Chile", label = "Chile Dictatorship Shock", start = 1974, end = 1989, df = cl_df),
  list(country = "Chile", label = "Chile Democratic Neoliberal", start = 1990, end = 2024, df = cl_df)
)

cat("\n=== Step 2: Running cointReg Triad Estimation across Windows ===\n")

results <- list()

for (w in windows_list) {
  sub_df <- w$df[w$df$year >= w$start & w$df$year <= w$end, ]
  N <- nrow(sub_df)
  
  if (N < 8) next # skip tiny windows
  
  y <- sub_df$k_NR
  x <- sub_df$k_ME
  deter <- matrix(1, N, 1)
  
  # 1. FM-OLS
  fm <- tryCatch({
    cointRegFM(x = x, y = y, deter = deter)
  }, error = function(e) NULL)
  
  # 2. DOLS
  dols <- tryCatch({
    cointRegD(x = x, y = y, deter = deter, n.p = 1, n.n = 1)
  }, error = function(e) NULL)
  
  # 3. IM-OLS
  im <- tryCatch({
    cointRegIM(x = x, y = y, deter = deter)
  }, error = function(e) NULL)
  
  results[[length(results) + 1]] <- data.frame(
    Country = w$country,
    Window = w$label,
    Start_Year = w$start,
    End_Year = w$end,
    N = N,
    
    # FM-OLS
    Gamma_FM = if (!is.null(fm)) round(fm$theta[1], 4) else NA,
    SE_FM = if (!is.null(fm)) round(fm$sd.theta[1], 4) else NA,
    T_FM = if (!is.null(fm)) round(fm$t.theta[1], 2) else NA,
    P_FM = if (!is.null(fm)) round(fm$p.theta[1], 4) else NA,
    
    # DOLS
    Gamma_DOLS = if (!is.null(dols)) round(dols$theta[1], 4) else NA,
    SE_DOLS = if (!is.null(dols)) round(dols$sd.theta[1], 4) else NA,
    T_DOLS = if (!is.null(dols)) round(dols$t.theta[1], 2) else NA,
    P_DOLS = if (!is.null(dols)) round(dols$p.theta[1], 4) else NA,
    
    # IM-OLS
    Gamma_IM = if (!is.null(im)) round(im$theta[1], 4) else NA,
    SE_IM = if (!is.null(im)) round(im$sd.theta[1], 4) else NA,
    Stat_IM = if (!is.null(im)) round(im$t.theta[1], 2) else NA,
    P_IM = if (!is.null(im)) round(im$p.theta[1], 4) else NA,
    
    stringsAsFactors = FALSE
  )
}

ledger_df <- do.call(rbind, results)

cat("\n=== Step 3: Running strucchange Structural Break Tests ===\n")

# Run Bai-Perron breakpoints and Fstats on Full Century models
# 1. US Full Century
us_full <- us_df[us_df$year >= 1925 & us_df$year <= 2021, ]
bp_us <- breakpoints(k_NR ~ k_ME, data = us_full, h = 0.15, breaks = 3)
fs_us <- Fstats(k_NR ~ k_ME, data = us_full, from = 0.15, to = 0.85)
supF_us <- sctest(fs_us, type = "supF")
aveF_us <- sctest(fs_us, type = "aveF")
expF_us <- sctest(fs_us, type = "expF")

us_break_years <- if (!is.na(bp_us$breakpoints[1])) paste(us_full$year[bp_us$breakpoints], collapse = ", ") else "None"

# 2. Chile Full Century
cl_full <- cl_df[cl_df$year >= 1920 & cl_df$year <= 2024, ]
bp_cl <- breakpoints(k_NR ~ k_ME, data = cl_full, h = 0.15, breaks = 3)
fs_cl <- Fstats(k_NR ~ k_ME, data = cl_full, from = 0.15, to = 0.85)
supF_cl <- sctest(fs_cl, type = "supF")
aveF_cl <- sctest(fs_cl, type = "aveF")
expF_cl <- sctest(fs_cl, type = "expF")

cl_break_years <- if (!is.na(bp_cl$breakpoints[1])) paste(cl_full$year[bp_cl$breakpoints], collapse = ", ") else "None"

# Attach break testing results to ledger_df
ledger_df$BP_Break_Years <- NA
ledger_df$SupF_Stat <- NA
ledger_df$SupF_PVal <- NA

ledger_df$BP_Break_Years[ledger_df$Window == "U.S. Full Century"] <- us_break_years
ledger_df$SupF_Stat[ledger_df$Window == "U.S. Full Century"] <- round(supF_us$statistic, 2)
ledger_df$SupF_PVal[ledger_df$Window == "U.S. Full Century"] <- round(supF_us$p.value, 4)

ledger_df$BP_Break_Years[ledger_df$Window == "Chile Full Century"] <- cl_break_years
ledger_df$SupF_Stat[ledger_df$Window == "Chile Full Century"] <- round(supF_cl$statistic, 2)
ledger_df$SupF_PVal[ledger_df$Window == "Chile Full Century"] <- round(supF_cl$p.value, 4)

write.csv(ledger_df, out_csv, row.names = FALSE)
cat("Saved Ledger: ", out_csv, "\n")

cat("\n=== Step 4: Generating Figures ===\n")

# Figure 3A: cointReg Estimator Triad Comparison
long_triad <- ledger_df %>%
  select(Country, Window, Start_Year, Gamma_FM, Gamma_DOLS, Gamma_IM) %>%
  tidyr::pivot_longer(cols = c("Gamma_FM", "Gamma_DOLS", "Gamma_IM"), names_to = "Estimator", values_to = "Gamma_Hat")

long_triad$Estimator <- factor(long_triad$Estimator,
                               levels = c("Gamma_FM", "Gamma_DOLS", "Gamma_IM"),
                               labels = c("FM-OLS (Phillips-Hansen)", "DOLS (Stock-Watson)", "IM-OLS (Vogelsang-Wagner)"))

long_triad$Window_Short <- gsub("Chile |U.S. ", "", long_triad$Window)

p_triad <- ggplot(long_triad, aes(x = Gamma_Hat, y = reorder(Window_Short, Start_Year), color = Estimator, shape = Estimator)) +
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "gray40", size = 0.8) +
  geom_point(size = 3.2, position = position_dodge(width = 0.5)) +
  facet_wrap(~Country, scales = "free_y") +
  scale_color_manual(values = c("navy", "firebrick", "forestgreen")) +
  labs(title = "Single-Equation Super-Consistent Cointegrating Elasticities (gamma_hat)",
       subtitle = "Comparative Triad: FM-OLS vs DOLS vs IM-OLS | Dashed Line = 1.0 (Fordist Proportionality)",
       x = "gamma_hat Coefficient", y = "Historical Window",
       color = "Estimator Method", shape = "Estimator Method") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))

ggsave(file.path(fig_dir, "cointreg_estimator_triad_comparison.png"), p_triad, width = 12, height = 6, dpi = 150)
cat("Saved Figure: cointreg_estimator_triad_comparison.png\n")

# Figure 3B: strucchange OLS-CUSUM Fluctuation Plots
efp_us <- efp(k_NR ~ k_ME, data = us_full, type = "OLS-CUSUM")
efp_cl <- efp(k_NR ~ k_ME, data = cl_full, type = "OLS-CUSUM")

png(file.path(fig_dir, "strucchange_cusum_breakpoints.png"), width = 1200, height = 600, res = 130)
par(mfrow = c(1, 2), mar = c(4, 4, 3, 1))

plot(efp_us, main = "U.S. OLS-CUSUM Empirical Fluctuation (1925-2021)", xlab = "Time Index", ylab = "Empirical Fluctuation")
abline(v = us_full$year[bp_us$breakpoints], col = "red", lty = 2, lwd = 1.5)

plot(efp_cl, main = "Chile OLS-CUSUM Empirical Fluctuation (1920-2024)", xlab = "Time Index", ylab = "Empirical Fluctuation")
abline(v = cl_full$year[bp_cl$breakpoints], col = "red", lty = 2, lwd = 1.5)

dev.off()
cat("Saved Figure: strucchange_cusum_breakpoints.png\n")

cat("\n=== cointReg + strucchange Pipeline Complete! ===\n")
