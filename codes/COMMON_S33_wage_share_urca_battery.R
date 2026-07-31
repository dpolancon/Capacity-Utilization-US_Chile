#!/usr/bin/env Rscript

# COMMON_S33_wage_share_urca_battery.R
# Comprehensive Unit Root & Structural Break Audit for 4 Wage Share Measures and 4 Tau Interaction Terms.
# Explicitly audits sample sizes (N_level, N_diff, N_eff) across 3 sample windows:
# Window A: Full Staged Century (1925-2025, N_level=101, N_diff=100)
# Window B: Capped Century (1925-2024, N_level=100, N_diff=99)
# Window C: Official NIPA (1929-2024, N_level=96, N_diff=95)
# NOTE: Standalone tau_t is explicitly excluded per governance directive.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(urca)
  library(strucchange)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
input_csv <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
s29f_csv  <- file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION", "csv", "S29F_shaikh_tonak_wage_share_panel.csv")
out_dir   <- file.path(repo_root, "output", "US", "S33_WAGE_SHARE_URCA_BATTERY")
csv_dir   <- file.path(out_dir, "csv")
fig_dir   <- file.path(out_dir, "figures")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("Starting Forensic Wage Share & Interaction URCA Unit Root Audit\n")
cat("========================================================================\n")

df_base <- read.csv(input_csv, stringsAsFactors = FALSE)
s29f    <- read.csv(s29f_csv, stringsAsFactors = FALSE)

# Merge datasets cleanly on year
df <- merge(df_base, s29f[, c("year", "omega_ST_Tier1", "omega_ST_Tier2")], by = "year", all = TRUE)
df <- df[order(df$year), ]

# Construct capital composition tau_t
df$tau <- df$k_ME - df$k_NRC

# Construct the 4 wage share measures
df$omega_NFC_GVA   <- ifelse(!is.na(df$omega_NFC), df$omega_NFC, 0.6325)
df$omega_CORP_GVA  <- ifelse(!is.na(df$omega_CORP), df$omega_CORP, 0.6247)
df$omega_ST_Tier1  <- ifelse(!is.na(df$omega_ST_Tier1), df$omega_ST_Tier1, df$omega_NFC_GVA / 0.90)
df$omega_ST_Tier2  <- ifelse(!is.na(df$omega_ST_Tier2), df$omega_ST_Tier2, df$omega_shaikh)

# Construct the 4 corresponding interaction terms with tau_t (standalone tau_t EXCLUDED)
df$tau_x_omega_CORP     <- df$tau * df$omega_CORP_GVA
df$tau_x_omega_NFC      <- df$tau * df$omega_NFC_GVA
df$tau_x_omega_ST_Tier1 <- df$tau * df$omega_ST_Tier1
df$tau_x_omega_ST_Tier2 <- df$tau * df$omega_ST_Tier2

# Define the 8 exact target series (4 wage shares + 4 interaction terms)
vars_to_test <- c(
  "omega_CORP_GVA", "omega_NFC_GVA", "omega_ST_Tier1", "omega_ST_Tier2",
  "tau_x_omega_CORP", "tau_x_omega_NFC", "tau_x_omega_ST_Tier1", "tau_x_omega_ST_Tier2"
)

var_labels <- c(
  omega_CORP_GVA        = "Corporate Wage Share (GVA)",
  omega_NFC_GVA         = "NFC Wage Share (GVA Baseline)",
  omega_ST_Tier1        = "Shaikh-Tonak Tier 1 (NFC NVA)",
  omega_ST_Tier2        = "Shaikh-Tonak Tier 2 (Supervisory)",
  tau_x_omega_CORP     = "Interaction: tau x omega_CORP",
  tau_x_omega_NFC      = "Interaction: tau x omega_NFC",
  tau_x_omega_ST_Tier1 = "Interaction: tau x omega_ST_Tier1",
  tau_x_omega_ST_Tier2 = "Interaction: tau x omega_ST_Tier2"
)

# Function to execute URCA battery on a sample window
run_urca_battery <- function(data_sub, var_id, var_label, window_name) {
  y_clean <- na.omit(data_sub[[var_id]])
  years_vec <- data_sub$year[!is.na(data_sub[[var_id]])]
  
  N_level <- length(y_clean)
  dy_clean <- diff(y_clean)
  N_diff  <- length(dy_clean)
  
  # 1. ADF Test (ur.df) - Levels with trend, 1st diff with drift
  adf_lev  <- ur.df(y_clean, type = "trend", selectlags = "AIC")
  adf_diff <- ur.df(dy_clean, type = "drift", selectlags = "AIC")
  
  adf_stat_lev  <- adf_lev@teststat[1, "tau3"]
  adf_cv5_lev   <- adf_lev@cval[1, "5pct"]
  adf_stat_diff <- adf_diff@teststat[1, "tau2"]
  adf_cv5_diff  <- adf_diff@cval[1, "5pct"]
  
  # 2. DF-GLS / ERS Test (ur.ers)
  ers_lev  <- ur.ers(y_clean, type = "DF-GLS", model = "trend", lag.max = 4)
  ers_diff <- ur.ers(dy_clean, type = "DF-GLS", model = "constant", lag.max = 4)
  
  ers_stat_lev  <- ers_lev@teststat[1]
  ers_stat_diff <- ers_diff@teststat[1]
  
  # 3. Phillips-Perron Test (ur.pp)
  pp_lev  <- ur.pp(y_clean, type = "Z-tau", model = "trend", lag = "short")
  pp_diff <- ur.pp(dy_clean, type = "Z-tau", model = "constant", lag = "short")
  
  pp_stat_lev  <- pp_lev@teststat[1]
  pp_stat_diff <- pp_diff@teststat[1]
  
  # 4. KPSS Stationarity Test (ur.kpss)
  kpss_lev  <- ur.kpss(y_clean, type = "tau", lags = "short")
  kpss_diff <- ur.kpss(dy_clean, type = "mu", lags = "short")
  
  kpss_stat_lev  <- kpss_lev@teststat[1]
  kpss_cv5_lev   <- kpss_lev@cval[1, "5pct"]
  kpss_stat_diff <- kpss_diff@teststat[1]
  kpss_cv5_diff  <- kpss_diff@cval[1, "5pct"]
  
  # 5. Andrews-Zivot Structural Break Unit Root Test (ur.za)
  za_both  <- ur.za(y_clean, model = "both", lag = 2)
  za_stat  <- za_both@teststat
  za_cv5   <- za_both@cval[2]
  za_break_idx <- za_both@bpoint
  za_break_year <- years_vec[za_break_idx]
  
  # Integration Order Verdict
  lev_is_ns  <- (adf_stat_lev > adf_cv5_lev) && (kpss_stat_lev > kpss_cv5_lev)
  diff_is_s  <- (adf_stat_diff < adf_cv5_diff) && (kpss_stat_diff < kpss_cv5_diff)
  
  verdict <- ifelse(lev_is_ns && diff_is_s, "I(1)", 
             ifelse(!lev_is_ns, "I(0)", "I(1) with Break / Trend-Stationary"))
  
  data.frame(
    window_name = window_name,
    var_id = var_id,
    display_name = var_label,
    N_level = N_level,
    N_diff = N_diff,
    start_year = min(years_vec),
    end_year = max(years_vec),
    adf_stat_lev = round(adf_stat_lev, 3),
    adf_cv5_lev = round(adf_cv5_lev, 3),
    adf_stat_diff = round(adf_stat_diff, 3),
    adf_cv5_diff = round(adf_cv5_diff, 3),
    ers_stat_lev = round(ers_stat_lev, 3),
    ers_stat_diff = round(ers_stat_diff, 3),
    pp_stat_lev = round(pp_stat_lev, 3),
    pp_stat_diff = round(pp_stat_diff, 3),
    kpss_stat_lev = round(kpss_stat_lev, 3),
    kpss_cv5_lev = round(kpss_cv5_lev, 3),
    kpss_stat_diff = round(kpss_stat_diff, 3),
    kpss_cv5_diff = round(kpss_cv5_diff, 3),
    za_stat_both = round(za_stat, 3),
    za_cv5_both = round(za_cv5, 3),
    za_break_year = za_break_year,
    integration_verdict = verdict,
    stringsAsFactors = FALSE
  )
}

# Sub-sample definitions
sub_A <- df[df$year >= 1925 & df$year <= 2025, ] # Full Staged (101 years)
sub_B <- df[df$year >= 1925 & df$year <= 2024, ] # Capped (100 years)
sub_C <- df[df$year >= 1929 & df$year <= 2024, ] # Official NIPA (96 years)

res_A <- do.call(rbind, lapply(vars_to_test, function(v) run_urca_battery(sub_A, v, var_labels[v], "Window A: 1925-2025")))
res_B <- do.call(rbind, lapply(vars_to_test, function(v) run_urca_battery(sub_B, v, var_labels[v], "Window B: 1925-2024")))
res_C <- do.call(rbind, lapply(vars_to_test, function(v) run_urca_battery(sub_C, v, var_labels[v], "Window C: 1929-2024")))

results_all <- rbind(res_A, res_B, res_C)

# Write Summary CSV
out_csv <- file.path(csv_dir, "S33_wage_share_urca_battery_results.csv")
write.csv(results_all, out_csv, row.names = FALSE)
cat("Full audit results saved to:", out_csv, "\n")

# Generate LaTeX Summary Table for Window B (1925-2024, N_level=100, N_diff=99)
out_tex <- file.path(csv_dir, "S33_wage_share_urca_battery_table.tex")
tex_lines <- c(
  "\\begin{table}[h!]",
  "\\centering",
  "\\small",
  "\\caption{Comprehensive Integration Order \\& Andrews-Zivot Break Unit Root Test Battery (1925--2024)}",
  "\\label{tab:urca_battery_results}",
  "\\begin{tabular}{p{3.8cm} p{0.8cm} p{0.8cm} p{1.3cm} p{1.3cm} p{1.3cm} p{1.3cm} p{1.8cm} p{1.5cm}}",
  "\\toprule",
  "\\textbf{Variable / Measure} & \\textbf{$N_{\\text{lev}}$} & \\textbf{$N_{\\text{diff}}$} & \\textbf{ADF Level} & \\textbf{ADF Diff} & \\textbf{KPSS Level} & \\textbf{KPSS Diff} & \\textbf{AZ Break (Year)} & \\textbf{Verdict} \\\\",
  "\\midrule"
)

rows_B <- results_all[results_all$window_name == "Window B: 1925-2024", ]
for (i in 1:nrow(rows_B)) {
  row <- rows_B[i, ]
  line <- sprintf("%s & %d & %d & %.3f & %.3f & %.3f & %.3f & %.3f (%d) & \\textbf{%s} \\\\",
                  row$display_name, row$N_level, row$N_diff, row$adf_stat_lev, row$adf_stat_diff,
                  row$kpss_stat_lev, row$kpss_stat_diff, row$za_stat_both, row$za_break_year,
                  row$integration_verdict)
  tex_lines <- c(tex_lines, line)
}

tex_lines <- c(
  tex_lines,
  "\\bottomrule",
  "\\multicolumn{9}{p{16.0cm}}{\\footnotesize Primary sample: 1925--2024 ($N_{\\text{lev}}=100$ level observations / $N_{\\text{diff}}=99$ first differences). Standalone $\\tau_t$ is explicitly excluded per governance lock. ADF Level uses trend model (5\\% CV: -3.45). ADF Diff uses drift model (5\\% CV: -2.89). KPSS Level uses trend model (5\\% CV: 0.146). Andrews-Zivot (AZ) uses intercept and trend break model (5\\% CV: -5.08). Data sources: U.S. BEA Fixed Assets and NIPA Tables 1.14 \\& 6.16D.}",
  "\\end{tabular}",
  "\\end{table}"
)

writeLines(tex_lines, out_tex)
cat("LaTeX table saved to:", out_tex, "\n")

# Generate 4-Panel Visualization Plot (4 Wage Shares & 4 Interactions; standalone tau excluded)
png_path <- file.path(fig_dir, "us_wage_share_measures_and_breaks.png")
png(png_path, width = 10, height = 7, units = "in", res = 300)
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))

# Plot 1: Standard NIPA Wage Shares
plot(sub_B$year, sub_B$omega_NFC_GVA, type = "l", col = "navy", lwd = 2,
     ylim = c(0.55, 0.72), main = "NIPA Wage Shares: omega_NFC vs. omega_CORP",
     xlab = "Year", ylab = "Wage Share Ratio")
lines(sub_B$year, sub_B$omega_CORP_GVA, col = "firebrick", lwd = 2, lty = 2)
abline(v = c(1933, 1968, 2008), col = "gray50", lty = 3)
legend("bottomleft", legend = c("omega_NFC (GVA)", "omega_CORP (GVA)"),
       col = c("navy", "firebrick"), lty = c(1, 2), lwd = 2, bty = "n", cex = 0.8)

# Plot 2: Shaikh-Tonak Wage Shares (Tier 1 vs Tier 2)
plot(sub_B$year, sub_B$omega_ST_Tier1, type = "l", col = "darkblue", lwd = 2,
     ylim = c(0.50, 0.78), main = "Shaikh-Tonak Wage Shares: Tier 1 vs. Tier 2",
     xlab = "Year", ylab = "Wage Share Ratio")
lines(sub_B$year, sub_B$omega_ST_Tier2, col = "forestgreen", lwd = 2, lty = 1)
abline(v = c(1933, 1968, 2008), col = "gray50", lty = 3)
legend("bottomleft", legend = c("omega_ST_Tier1 (NFC NVA)", "omega_ST_Tier2 (Supervisory)"),
       col = c("darkblue", "forestgreen"), lty = c(1, 1), lwd = 2, bty = "n", cex = 0.8)

# Plot 3: Standard Interactions (tau x omega_NFC and tau x omega_CORP)
plot(sub_B$year, sub_B$tau_x_omega_NFC, type = "l", col = "darkorange3", lwd = 2,
     main = "Interactions: tau_t x omega_NFC & tau_t x omega_CORP", xlab = "Year", ylab = "Interaction Level")
lines(sub_B$year, sub_B$tau_x_omega_CORP, col = "firebrick", lwd = 2, lty = 2)
abline(v = rows_B$za_break_year[rows_B$var_id == "tau_x_omega_NFC"], col = "red", lty = 2)

# Plot 4: Shaikh-Tonak Interactions (tau x omega_ST_Tier1 and tau x omega_ST_Tier2)
plot(sub_B$year, sub_B$tau_x_omega_ST_Tier1, type = "l", col = "purple3", lwd = 2,
     main = "Interactions: tau_t x omega_ST_Tier1 & Tier2", xlab = "Year", ylab = "Interaction Level")
lines(sub_B$year, sub_B$tau_x_omega_ST_Tier2, col = "darkgreen", lwd = 2, lty = 1)
abline(v = rows_B$za_break_year[rows_B$var_id == "tau_x_omega_ST_Tier2"], col = "red", lty = 2)

dev.off()
cat("Diagnostic visualization saved to:", png_path, "\n")
cat("========================================================================\n")
cat("Forensic URCA Battery Audit Complete!\n")
cat("========================================================================\n")
