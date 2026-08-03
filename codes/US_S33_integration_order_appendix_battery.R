#!/usr/bin/env Rscript

# US_S33_integration_order_appendix_battery.R
# Comprehensive Unit Root & Andrews-Zivot Structural Break Audit for:
#   1. Baseline Series: CORP_IPP_INVESTMENT_SHARE (iota), Capital Composition (kappa), gross capital stocks (k_cap_NoGov, k_cap_Gov), and wage share interactions.
#   2. Induced-Demand Series: Log Real Consumption (c_t), Log Real Imports (m_t), Log Real GDP (y_t), C/Y, M/Y, (C-M)/Y, and log spread (cm_t).
# Aligned with UMass Amherst Applied Econometrics standards: visual-first, forensic, active voice.

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(urca)
  library(strucchange)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
wide_sot_csv <- file.path(repo_root, "data", "releases", "chapter2_us_source_of_truth_v1_1_candidate", "CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_WIDE.csv")
s29f_csv  <- file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION", "csv", "S29F_shaikh_tonak_wage_share_panel.csv")
us_staged_csv <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
ext_csv <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data", "s41_extended_capital_panel.csv")
cm_csv <- file.path(repo_root, "output", "US", "S42_CM_EXTENSION", "csv", "s42a_extended_cm_control_panel.csv")

out_dir   <- file.path(repo_root, "output", "US", "S33_INTEGRATION_ORDER_APPENDIX_BATTERY")
csv_dir   <- file.path(out_dir, "csv")
fig_dir   <- file.path(out_dir, "figures")

dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("Starting Forensic Comprehensive Integration Order Appendix Audit\n")
cat("========================================================================\n")

# Load datasets
df_wide <- read.csv(wide_sot_csv, stringsAsFactors = FALSE)
df_st <- read.csv(s29f_csv, stringsAsFactors = FALSE)
df_cond <- read.csv(us_staged_csv, stringsAsFactors = FALSE)
df_ext <- read.csv(ext_csv, stringsAsFactors = FALSE)
df_cm <- read.csv(cm_csv, stringsAsFactors = FALSE)

# Merge datasets cleanly on year
df <- merge(df_wide[, c("year", "CORP_IPP_INVESTMENT_SHARE", 
                        "CORP_COMPENSATION_SHARE_GVA", "CORP_COMPENSATION_SHARE_NVA",
                        "NFC_COMPENSATION_SHARE_GVA", "NFC_COMPENSATION_SHARE_NVA",
                        "y_real_nfc_gva_baseline")],
            df_st[, c("year", "omega_ST_Tier1", "omega_ST_Tier2", 
                      "omega_ST_Tier1_GVA_adj", "omega_ST_Tier2_GVA_adj")],
            by = "year", all = TRUE)

df <- merge(df, df_cond[, c("year", "k_ME", "k_NRC")], by = "year", all.x = TRUE)
df <- merge(df, df_ext[, c("year", "K_cap", "K_cap_GT")], by = "year", all.x = TRUE)
df <- merge(df, df_cm[, c("year", "C_real_nipa", "M_real_nipa", "c_share_nom", "m_share_nom", "net_c_share_nom")], by = "year", all.x = TRUE)

df <- df[order(df$year), ]
df <- df[!is.na(df$year), ]

# Construct capital composition ratio kappa (replacing legacy tau)
df$kappa <- df$k_ME - df$k_NRC

# Construct log-levels of gross capital stocks
df$k_cap_NoGov <- log(df$K_cap)
df$k_cap_Gov <- log(df$K_cap_GT)

# Construct induced demand variables
# Log-levels and log-spread use chained real-dollar series (NIPA T1.1.6)
df$c_t <- log(df$C_real_nipa)
df$m_t <- log(df$M_real_nipa)
df$y_t <- log(df$y_real_nfc_gva_baseline)
df$cm_t <- df$c_t - df$m_t

# Shares use nominal current-dollar series relative to total NIPA GDP (NIPA T1.1.5)
df$c_share <- df$c_share_nom
df$m_share <- df$m_share_nom
df$net_c_share <- df$net_c_share_nom

# Define wage share measures to interact
wage_vars <- c(
  "CORP_COMPENSATION_SHARE_GVA", "CORP_COMPENSATION_SHARE_NVA",
  "NFC_COMPENSATION_SHARE_GVA", "NFC_COMPENSATION_SHARE_NVA",
  "omega_ST_Tier1", "omega_ST_Tier2",
  "omega_ST_Tier1_GVA_adj", "omega_ST_Tier2_GVA_adj"
)

# Apply dynamic padding/backcasting to 1925-1928 based on 1929 values for wage shares
for (var in wage_vars) {
  val_row <- df$year == 1929 & !is.na(df$year)
  if (any(val_row)) {
    val <- df[val_row, var][1]
    idx <- df$year < 1929 & !is.na(df$year)
    df[idx, var] <- val
  }
}

# Construct double and triple interaction terms for baseline
for (var in wage_vars) {
  df[[paste0("inter_ipp_", var)]] <- df$CORP_IPP_INVESTMENT_SHARE * df[[var]]
  df[[paste0("inter_kappa_ipp_", var)]] <- df$kappa * df$CORP_IPP_INVESTMENT_SHARE * df[[var]]
  df[[paste0("inter_nogov_", var)]] <- df$k_cap_NoGov * df[[var]]
  df[[paste0("inter_nogov_ipp_", var)]] <- df$k_cap_NoGov * df[[var]] * df$CORP_IPP_INVESTMENT_SHARE
  df[[paste0("inter_gov_", var)]] <- df$k_cap_Gov * df[[var]]
  df[[paste0("inter_gov_ipp_", var)]] <- df$k_cap_Gov * df[[var]] * df$CORP_IPP_INVESTMENT_SHARE
}

# Define the target series list to test
vars_to_test <- c(
  "CORP_IPP_INVESTMENT_SHARE",
  "kappa",
  "k_cap_NoGov",
  "k_cap_Gov",
  "c_t",
  "m_t",
  "y_t",
  "c_share",
  "m_share",
  "net_c_share",
  "cm_t",
  paste0("inter_ipp_", wage_vars),
  paste0("inter_kappa_ipp_", wage_vars),
  paste0("inter_nogov_", wage_vars),
  paste0("inter_gov_", wage_vars),
  paste0("inter_nogov_ipp_", wage_vars),
  paste0("inter_gov_ipp_", wage_vars)
)

var_labels <- c(
  CORP_IPP_INVESTMENT_SHARE = "Corp IPP Share ($\\iota_t$)",
  kappa = "Capital Composition ($\\kappa_t$)",
  k_cap_NoGov = "Private Capital ($k^{\\text{cap}}_{\\text{NoGov}}$)",
  k_cap_Gov = "Infrastructure-Augmented Capital ($k^{\\text{cap}}_{\\text{Gov}}$)",
  c_t = "Log Real Consumption ($c_t$)",
  m_t = "Log Real Imports ($m_t$)",
  y_t = "Log Real GDP ($y_t$)",
  c_share = "Consumption Share ($C_t/Y_t$)",
  m_share = "Import Share ($M_t/Y_t$)",
  net_c_share = "Net Consumption Share ($(C_t - M_t)/Y_t$)",
  cm_t = "Log Consumption-Import Spread ($cm_t$)"
)

for (var in wage_vars) {
  omega_label <- gsub("CORP_COMPENSATION_SHARE_GVA", "CORP,GVA", var)
  omega_label <- gsub("CORP_COMPENSATION_SHARE_NVA", "CORP,NVA", omega_label)
  omega_label <- gsub("NFC_COMPENSATION_SHARE_GVA", "NFC,GVA", omega_label)
  omega_label <- gsub("NFC_COMPENSATION_SHARE_NVA", "NFC,NVA", omega_label)
  omega_label <- gsub("omega_ST_Tier1_GVA_adj", "ST,Tier1,GVA", omega_label)
  omega_label <- gsub("omega_ST_Tier2_GVA_adj", "ST,Tier2,GVA", omega_label)
  omega_label <- gsub("omega_ST_Tier1", "ST,Tier1", omega_label)
  omega_label <- gsub("omega_ST_Tier2", "ST,Tier2", omega_label)
  
  var_labels[paste0("inter_ipp_", var)] <- paste0("$\\iota_t \\times \\omega_{\\text{", omega_label, "}}$")
  var_labels[paste0("inter_kappa_ipp_", var)] <- paste0("$\\kappa_t \\times \\iota_t \\times \\omega_{\\text{", omega_label, "}}$")
  var_labels[paste0("inter_nogov_", var)] <- paste0("$k^{\\text{cap}}_{\\text{NoGov}} \\times \\omega_{\\text{", omega_label, "}}$")
  var_labels[paste0("inter_gov_", var)] <- paste0("$k^{\\text{cap}}_{\\text{Gov}} \\times \\omega_{\\text{", omega_label, "}}$")
  var_labels[paste0("inter_nogov_ipp_", var)] <- paste0("$k^{\\text{cap}}_{\\text{NoGov}} \\times \\omega_{\\text{", omega_label, "}} \\times \\iota_t$")
  var_labels[paste0("inter_gov_ipp_", var)] <- paste0("$k^{\\text{cap}}_{\\text{Gov}} \\times \\omega_{\\text{", omega_label, "}} \\times \\iota_t$")
}

# Function to execute URCA battery on a sample window
run_urca_battery <- function(data_sub, var_id, var_label, window_name) {
  y_clean <- na.omit(data_sub[[var_id]])
  years_vec <- data_sub$year[!is.na(data_sub[[var_id]])]
  
  N_level <- length(y_clean)
  dy_clean <- diff(y_clean)
  N_diff  <- length(dy_clean)
  
  if (N_level < 10) {
    return(NULL)
  }
  
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
  ers_cv5_lev   <- ers_lev@cval[1]
  ers_stat_diff <- ers_diff@teststat[1]
  ers_cv5_diff  <- ers_diff@cval[1]
  
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
  
  if (lev_is_ns) {
    if (diff_is_s) {
      if (za_stat < za_cv5) {
        verdict <- "I(1) with Break"
      } else {
        verdict <- "I(1)"
      }
    } else {
      verdict <- "I(2) / Non-Stationary"
    }
  } else {
    verdict <- "I(0)"
  }
  
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
    ers_cv5_lev = round(ers_cv5_lev, 3),
    ers_stat_diff = round(ers_stat_diff, 3),
    ers_cv5_diff = round(ers_cv5_diff, 3),
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

# Subset windows
sub_A <- df[df$year >= 1925 & df$year <= 2024, ] # Window A: Capped Century
sub_B <- df[df$year >= 1929 & df$year <= 2024, ] # Window B: Official NIPA

cat("Auditing Window A: 1925-2024...\n")
res_A <- do.call(rbind, lapply(vars_to_test, function(v) run_urca_battery(sub_A, v, var_labels[v], "Window A: 1925-2024")))
cat("Auditing Window B: 1929-2024...\n")
res_B <- do.call(rbind, lapply(vars_to_test, function(v) run_urca_battery(sub_B, v, var_labels[v], "Window B: 1929-2024")))

results_all <- rbind(res_A, res_B)

# Save full results to CSV
out_csv <- file.path(csv_dir, "US_integration_order_appendix_results.csv")
write.csv(results_all, out_csv, row.names = FALSE)
cat("Full audit results saved to:", out_csv, "\n")

# Generate LaTeX Table lines for Window B (Official NIPA 1929-2024)
out_tex_lines <- file.path(csv_dir, "US_integration_order_appendix_table_lines.tex")
rows_B <- results_all[results_all$window_name == "Window B: 1929-2024", ]

format_latex_row <- function(row) {
  verdict_str <- sprintf("\\textbf{%s}", row$integration_verdict)
  sprintf("%s & %d & %d & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f & %.3f (%d) & %s \\\\",
          row$display_name, row$N_level, row$N_diff, row$adf_stat_lev, row$adf_stat_diff,
          row$ers_stat_lev, row$ers_stat_diff, row$kpss_stat_lev, row$kpss_stat_diff,
          row$za_stat_both, row$za_break_year, verdict_str)
}

# Panel A: Level Series and Composition Baseline
panel_a_vars <- c("CORP_IPP_INVESTMENT_SHARE", "kappa", "k_cap_NoGov", "k_cap_Gov")
panel_a_lines <- c("\\midrule", "\\multicolumn{11}{l}{\\textbf{Panel A: Level Series and Composition Baseline}} \\\\", "\\midrule")
for (v in panel_a_vars) {
  row <- rows_B[rows_B$var_id == v, ]
  if (nrow(row) > 0) panel_a_lines <- c(panel_a_lines, format_latex_row(row))
}

# Panel B: IPP and Capital Composition Interactions
panel_b_vars <- c(paste0("inter_ipp_", wage_vars), paste0("inter_kappa_ipp_", wage_vars))
panel_b_lines <- c("\\midrule", "\\multicolumn{11}{l}{\\textbf{Panel B: IPP and Capital Composition Interactions}} \\\\", "\\midrule")
for (v in panel_b_vars) {
  row <- rows_B[rows_B$var_id == v, ]
  if (nrow(row) > 0) panel_b_lines <- c(panel_b_lines, format_latex_row(row))
}

# Panel C: Private Capital Interactions
panel_c_vars <- c(paste0("inter_nogov_", wage_vars), paste0("inter_nogov_ipp_", wage_vars))
panel_c_lines <- c("\\midrule", "\\multicolumn{11}{l}{\\textbf{Panel C: Private Capital Interactions ($K^{\\text{cap}}_{\\text{NoGov}}$)}} \\\\", "\\midrule")
for (v in panel_c_vars) {
  row <- rows_B[rows_B$var_id == v, ]
  if (nrow(row) > 0) panel_c_lines <- c(panel_c_lines, format_latex_row(row))
}

# Panel D: Infrastructure-Augmented Capital Interactions
panel_d_vars <- c(paste0("inter_gov_", wage_vars), paste0("inter_gov_ipp_", wage_vars))
panel_d_lines <- c("\\midrule", "\\multicolumn{11}{l}{\\textbf{Panel D: Infrastructure-Augmented Capital Interactions ($K^{\\text{cap}}_{\\text{Gov}}$)}} \\\\", "\\midrule")
for (v in panel_d_vars) {
  row <- rows_B[rows_B$var_id == v, ]
  if (nrow(row) > 0) panel_d_lines <- c(panel_d_lines, format_latex_row(row))
}

# Panel E: Induced-Demand Control Variables
panel_e_vars <- c("c_t", "m_t", "y_t", "c_share", "m_share", "net_c_share", "cm_t")
panel_e_lines <- c("\\midrule", "\\multicolumn{11}{l}{\\textbf{Panel E: Induced-Demand Control Variables}} \\\\", "\\midrule")
for (v in panel_e_vars) {
  row <- rows_B[rows_B$var_id == v, ]
  if (nrow(row) > 0) panel_e_lines <- c(panel_e_lines, format_latex_row(row))
}

tex_lines <- c(panel_a_lines, panel_b_lines, panel_c_lines, panel_d_lines, panel_e_lines)
cat(paste(tex_lines, collapse = "\n"), file = out_tex_lines)
cat("LaTeX table lines saved to:", out_tex_lines, "\n")

# Plotting Function 1: Original baseline diagnostic plot
generate_plots_baseline <- function() {
  par(mfrow = c(2, 2), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
  
  # Plot 1: CORP_IPP_INVESTMENT_SHARE and ZA breakpoint
  za_row <- rows_B[rows_B$var_id == "CORP_IPP_INVESTMENT_SHARE", ]
  plot(sub_A$year, sub_A$CORP_IPP_INVESTMENT_SHARE, type = "l", col = "navy", lwd = 2.5,
       main = "Corp IPP Share of Gross Investment (iota)", xlab = "Year", ylab = "Share Ratio")
  abline(v = za_row$za_break_year, col = "red", lty = 2, lwd = 1.5)
  text(za_row$za_break_year + 2, max(sub_A$CORP_IPP_INVESTMENT_SHARE, na.rm=TRUE) * 0.9, 
       paste("Break:", za_row$za_break_year), col = "red", adj = 0, cex = 0.8)
  
  # Plot 2: Capital Stocks and ZA breakpoints
  za_row_nogov <- rows_B[rows_B$var_id == "k_cap_NoGov", ]
  za_row_gov <- rows_B[rows_B$var_id == "k_cap_Gov", ]
  plot(sub_A$year, sub_A$k_cap_NoGov, type = "l", col = "darkgreen", lwd = 2.5,
       ylim = c(min(sub_A$k_cap_NoGov, na.rm=TRUE), max(sub_A$k_cap_Gov, na.rm=TRUE)),
       main = "Private vs. Infrastructure-Augmented Capital", xlab = "Year", ylab = "log-level")
  lines(sub_A$year, sub_A$k_cap_Gov, col = "purple", lwd = 2.5)
  abline(v = za_row_nogov$za_break_year, col = "darkgreen", lty = 2, lwd = 1.5)
  abline(v = za_row_gov$za_break_year, col = "purple", lty = 2, lwd = 1.5)
  legend("bottomright", legend = c("k_cap_NoGov", "k_cap_Gov"),
         col = c("darkgreen", "purple"), lty = 1, lwd = 2.5, bty = "n", cex = 0.8)
  
  # Plot 3: Double Interactions (k_cap_NoGov x Wage Share)
  plot(sub_A$year, sub_A$inter_nogov_NFC_COMPENSATION_SHARE_GVA, type = "l", col = "orange3", lwd = 2,
       ylim = c(0, max(sub_A$inter_nogov_omega_ST_Tier2, na.rm=TRUE) * 1.1),
       main = "Private Capital Double Interactions (k_NoGov x omega_i)", xlab = "Year", ylab = "Level")
  lines(sub_A$year, sub_A$inter_nogov_omega_ST_Tier1, col = "blue3", lwd = 1.5)
  lines(sub_A$year, sub_A$inter_nogov_omega_ST_Tier2, col = "purple3", lwd = 1.5)
  legend("topleft", legend = c("k_NoGov x NFC GVA", "k_NoGov x ST Tier 1", "k_NoGov x ST Tier 2"),
         col = c("orange3", "blue3", "purple3"), lty = 1, lwd = 1.5, bty = "n", cex = 0.7)
  
  # Plot 4: Triple Interactions (k_cap_NoGov x Wage Share x iota)
  plot(sub_A$year, sub_A$inter_nogov_ipp_NFC_COMPENSATION_SHARE_GVA, type = "l", col = "orange3", lwd = 2,
       ylim = c(0, max(sub_A$inter_nogov_ipp_omega_ST_Tier2, na.rm=TRUE) * 1.1),
       main = "Private Capital Triple Interactions (k_NoGov x omega_i x iota)", xlab = "Year", ylab = "Level")
  lines(sub_A$year, sub_A$inter_nogov_ipp_omega_ST_Tier1, col = "blue3", lwd = 1.5)
  lines(sub_A$year, sub_A$inter_nogov_ipp_omega_ST_Tier2, col = "purple3", lwd = 1.5)
  legend("topleft", legend = c("k_NoGov x NFC GVA x iota", "k_NoGov x ST Tier 1 x iota", "k_NoGov x ST Tier 2 x iota"),
         col = c("orange3", "blue3", "purple3"), lty = 1, lwd = 1.5, bty = "n", cex = 0.7)
  
  mtext("U.S. IPP Share & Capital Stock Cointegration Interactions (1925-2024)", outer = TRUE, cex = 1.2, font = 2)
}

# Plotting Function 2: New induced-demand diagnostic plot
generate_plots_demand <- function() {
  par(mfrow = c(2, 2), mar = c(4, 4, 3, 1), oma = c(0, 0, 2, 0))
  
  # Plot 1: Log Levels of Consumption, Imports and GDP
  plot(sub_B$year, sub_B$c_t, type = "l", col = "blue3", lwd = 2,
       ylim = c(min(sub_B$m_t, na.rm=TRUE), max(sub_B$y_t, na.rm=TRUE)),
       main = "Log Real C, M and Y", xlab = "Year", ylab = "log-level")
  lines(sub_B$year, sub_B$m_t, col = "red3", lwd = 2)
  lines(sub_B$year, sub_B$y_t, col = "black", lwd = 1.5, lty = 2)
  legend("bottomright", legend = c("log C (c_t)", "log M (m_t)", "log Y (y_t)"),
         col = c("blue3", "red3", "black"), lty = c(1, 1, 2), lwd = 2, bty = "n", cex = 0.8)
  
  # Plot 2: Consumption and Import Shares (levels)
  plot(sub_B$year, sub_B$c_share, type = "l", col = "blue3", lwd = 2,
       ylim = c(0, max(sub_B$c_share, na.rm=TRUE) * 1.1),
       main = "Consumption & Import Shares of GDP", xlab = "Year", ylab = "Share of GDP")
  lines(sub_B$year, sub_B$m_share, col = "red3", lwd = 2)
  legend("left", legend = c("C / Y", "M / Y"),
         col = c("blue3", "red3"), lty = 1, lwd = 2, bty = "n", cex = 0.8)
  
  # Plot 3: Net Demand Composition Share and ZA breakpoint
  za_row_net <- rows_B[rows_B$var_id == "net_c_share", ]
  plot(sub_B$year, sub_B$net_c_share, type = "l", col = "purple3", lwd = 2,
       main = "Net Demand Composition (C - M) / Y", xlab = "Year", ylab = "Share Ratio")
  abline(v = za_row_net$za_break_year, col = "darkred", lty = 2, lwd = 1.5)
  text(za_row_net$za_break_year + 2, min(sub_B$net_c_share, na.rm=TRUE) * 1.05, 
       paste("Break:", za_row_net$za_break_year), col = "darkred", adj = 0, cex = 0.8)
  
  # Plot 4: Log Consumption-Import Ratio and ZA breakpoint
  za_row_cm <- rows_B[rows_B$var_id == "cm_t", ]
  plot(sub_B$year, sub_B$cm_t, type = "l", col = "orange3", lwd = 2,
       main = "Log Consumption-Import Spread (c_t - m_t)", xlab = "Year", ylab = "Spread")
  abline(v = za_row_cm$za_break_year, col = "darkred", lty = 2, lwd = 1.5)
  text(za_row_cm$za_break_year + 2, min(sub_B$cm_t, na.rm=TRUE) * 1.05, 
       paste("Break:", za_row_cm$za_break_year), col = "darkred", adj = 0, cex = 0.8)
  
  mtext("U.S. Induced Demand & Trade Cointegration Controls (1929-2024)", outer = TRUE, cex = 1.2, font = 2)
}

# Export dual-registry formats for baseline
png_path1 <- file.path(fig_dir, "us_ipp_share_dynamics_and_breaks.png")
png(png_path1, width = 10, height = 7, units = "in", res = 300)
generate_plots_baseline()
dev.off()

pdf_path1 <- file.path(fig_dir, "us_ipp_share_dynamics_and_breaks.pdf")
pdf(pdf_path1, width = 10, height = 7)
generate_plots_baseline()
dev.off()

# Export dual-registry formats for demand
png_path2 <- file.path(fig_dir, "us_demand_dynamics_and_breaks.png")
png(png_path2, width = 10, height = 7, units = "in", res = 300)
generate_plots_demand()
dev.off()
cat("Diagnostic demand PNG saved to:", png_path2, "\n")

pdf_path2 <- file.path(fig_dir, "us_demand_dynamics_and_breaks.pdf")
pdf(pdf_path2, width = 10, height = 7)
generate_plots_demand()
dev.off()
cat("Diagnostic demand PDF saved to:", pdf_path2, "\n")

cat("========================================================================\n")
cat("Forensic Appendix URCA Battery Audit Complete!\n")
cat("========================================================================\n")
