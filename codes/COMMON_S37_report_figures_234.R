#!/usr/bin/env Rscript

# COMMON_S37_report_figures_234.R
# Generate Figures 2, 3, and 4 for the S34 Comprehensive Econometric Report
# Figure 2: tau_t Path with Regime Bands (US & Chile)
# Figure 3: gamma_hat Coefficient Map Across Windows
# Figure 4: Speed-of-Adjustment Asymmetry (alpha_NRC vs alpha_ME)

suppressMessages(library(ggplot2))
suppressMessages(library(gridExtra))
suppressMessages(library(dplyr))

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
cl_file   <- file.path(repo_root, "data", "processed", "cl_s20", "chile_orthogonalized_panel.csv")
us_file   <- file.path(repo_root, "data", "processed", "us_s31j", "us_staged_pending_conditioners.csv")
ledger_file <- file.path(repo_root, "output", "break_informed_johansen_vecm_ledger.csv")
fig_dir   <- file.path(repo_root, "output", "figures")

if (!dir.exists(fig_dir)) dir.create(fig_dir, recursive = TRUE)

cat("=== Step 1: Generating Figure 2 (tau_t Path with Regime Bands) ===\n")

# Load US and Chile series
cl <- read.csv(cl_file)
cl <- cl[!is.na(cl$k_ME) & !is.na(cl$k_NR), ]
cl$tau <- cl$k_ME - cl$k_NR

us <- read.csv(us_file)
nr_col <- if ("k_NRC" %in% colnames(us)) "k_NRC" else "k_NR"
us <- us[!is.na(us$k_ME) & !is.na(us[[nr_col]]), ]
us$tau <- us$k_ME - us[[nr_col]]

# US Regime Bands
us_rects <- data.frame(
  xmin = c(1925, 1933, 1968, 2008),
  xmax = c(1933, 1968, 2008, 2021),
  Regime = factor(c("Pre-Depression", "Fordist Core (gamma=0.60)", "Neoliberal (r=0)", "Post-GFC (r=0)"),
                  levels = c("Pre-Depression", "Fordist Core (gamma=0.60)", "Neoliberal (r=0)", "Post-GFC (r=0)"))
)

p_us <- ggplot() +
  geom_rect(data = us_rects, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = Regime), alpha = 0.25) +
  geom_point(data = us, aes(x = year, y = tau), color = "gray30", size = 1.2, alpha = 0.7) +
  geom_smooth(data = us, aes(x = year, y = tau), method = "loess", span = 0.3, color = "purple", se = FALSE, size = 1.2) +
  geom_vline(xintercept = c(1933, 1968, 2008), linetype = "dashed", color = "firebrick", size = 0.8) +
  scale_fill_manual(values = c("lightblue", "lightgreen", "orange", "pink")) +
  labs(title = "U.S.: Capital Composition (tau_t = k_ME - k_NRC)",
       subtitle = "Inflections: 1933 (Depression), 1968 (Fordist Squeeze), 2008 (GFC)",
       x = "Year", y = "tau_t", fill = "Accumulation Regime") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))

# Chile Regime Bands
cl_rects <- data.frame(
  xmin = c(1920, 1936, 1971, 1982),
  xmax = c(1936, 1971, 1982, 2024),
  Regime = factor(c("Pre-ISI", "ISI Build-Up (r=0)", "Dictatorship (gamma=1.16)", "Neoliberal Export (gamma=0.69)"),
                  levels = c("Pre-ISI", "ISI Build-Up (r=0)", "Dictatorship (gamma=1.16)", "Neoliberal Export (gamma=0.69)"))
)

p_cl <- ggplot() +
  geom_rect(data = cl_rects, aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = Regime), alpha = 0.25) +
  geom_point(data = cl, aes(x = year, y = tau), color = "gray30", size = 1.2, alpha = 0.7) +
  geom_smooth(data = cl, aes(x = year, y = tau), method = "loess", span = 0.3, color = "purple", se = FALSE, size = 1.2) +
  geom_vline(xintercept = c(1936, 1971, 1982), linetype = "dashed", color = "firebrick", size = 0.8) +
  scale_fill_manual(values = c("lightblue", "lightgreen", "orange", "pink")) +
  labs(title = "Chile: Capital Composition (tau_t = k_ME - k_NR)",
       subtitle = "Inflections: 1936 (State ISI), 1971 (Allende FX Crisis), 1982 (Debt Crisis)",
       x = "Year", y = "tau_t", fill = "Accumulation Regime") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"))

fig2 <- grid.arrange(p_us, p_cl, ncol = 2)
ggsave(file.path(fig_dir, "tau_path_regime_bands.png"), fig2, width = 13, height = 5.5, dpi = 150)
cat("Saved Figure 2: tau_path_regime_bands.png\n")


cat("\n=== Step 2: Generating Figure 3 (gamma_hat Coefficient Map) ===\n")

ledger <- read.csv(ledger_file)
# Filter un-augmented models
ledger_unaug <- ledger[ledger$Dummy_Type == "None", ]

# Shorten window names for visual clarity
ledger_unaug$Window_Short <- gsub("Chile |US ", "", ledger_unaug$Window)
ledger_unaug$Is_Cointegrated <- grepl("r = 1", ledger_unaug$Decision)

p_fig3 <- ggplot(ledger_unaug, aes(x = Gamma_Hat, y = reorder(Window_Short, Start_Year), color = EC_Control, shape = Is_Cointegrated)) +
  geom_vline(xintercept = 1.0, linetype = "dashed", color = "gray40", size = 0.8) +
  geom_point(size = 3.5, stroke = 1.2) +
  facet_wrap(~Country, scales = "free_y") +
  scale_color_manual(values = c("const" = "navy", "trend" = "firebrick"),
                     labels = c("const" = "Drift (ecdet=const)", "trend" = "Trend (ecdet=trend)")) +
  scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 1),
                     labels = c(`TRUE` = "Cointegrated (r=1)", `FALSE` = "No Cointegration (r=0)")) +
  labs(title = "Cointegrating Coefficient gamma_hat Across Windows & EC Controls",
       subtitle = "LHS Normalization: k_NRC = alpha + gamma * k_ME | Dashed Line = 1.0 (Fordist Proportionality)",
       x = "gamma_hat Coefficient", y = "Historical Window",
       color = "EC Control", shape = "Rank Verdict") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank())

ggsave(file.path(fig_dir, "gamma_hat_coefficient_map.png"), p_fig3, width = 11, height = 6, dpi = 150)
cat("Saved Figure 3: gamma_hat_coefficient_map.png\n")


cat("\n=== Step 3: Generating Figure 4 (Speed-of-Adjustment Asymmetry) ===\n")

# Filter cointegrated models with valid alpha loadings
ledger_coint <- ledger[grepl("r = 1", ledger$Decision) & !is.na(ledger$Alpha_NR), ]
ledger_coint$Window_Label <- paste0(ledger_coint$Country, ": ", gsub("Chile |US ", "", ledger_coint$Window), " (", ledger_coint$EC_Control, ")")

# Reshape for dumbbell plot
alpha_df <- data.frame(
  Window = rep(ledger_coint$Window_Label, 2),
  Country = rep(ledger_coint$Country, 2),
  Asset = c(rep("alpha_NRC (Structures)", nrow(ledger_coint)), rep("alpha_ME (Machinery)", nrow(ledger_coint))),
  Alpha = c(ledger_coint$Alpha_NR, ledger_coint$Alpha_ME),
  T_Stat = c(ledger_coint$T_Alpha_NR, ledger_coint$T_Alpha_ME)
)
alpha_df$Signif <- abs(alpha_df$T_Stat) >= 1.96

p_fig4 <- ggplot(alpha_df, aes(x = Alpha, y = Window, color = Asset)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray40", size = 0.8) +
  geom_line(aes(group = Window), color = "gray60", size = 0.8) +
  geom_point(aes(size = abs(T_Stat), shape = Signif), stroke = 1.1) +
  scale_color_manual(values = c("alpha_NRC (Structures)" = "navy", "alpha_ME (Machinery)" = "firebrick")) +
  scale_shape_manual(values = c(`TRUE` = 16, `FALSE` = 1),
                     labels = c(`TRUE` = "Significant (|t| >= 1.96)", `FALSE` = "Weak Exogeneity (|t| < 1.96)")) +
  scale_size_continuous(range = c(2.5, 5.5), name = "|t-statistic|") +
  labs(title = "VECM Speed-of-Adjustment Loading Coefficients (alpha_NRC vs alpha_ME)",
       subtitle = "Negative Alpha = Error Correcting | Marker Size = |t|-stat | Hollow = Weakly Exogenous",
       x = "Speed-of-Adjustment Loading (alpha)", y = "Cointegrated Window",
       color = "Capital Asset", shape = "Significance") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"),
        panel.grid.minor = element_blank())

ggsave(file.path(fig_dir, "alpha_speed_of_adjustment.png"), p_fig4, width = 11, height = 5.5, dpi = 150)
cat("Saved Figure 4: alpha_speed_of_adjustment.png\n")

cat("\n=== All 3 Figures Generated Successfully! ===\n")
