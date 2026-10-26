#!/usr/bin/env Rscript

# CL_S60_generate_chile_master_figures.R
# ---------------------------------------------------------------------------
# Chilean Peripheral Extension Master Visualization & Figure Engine (Section 3.3 / 4.4)
#
# Admissible Chilean Models:
#   - M3.2a: Continuous Mediated ToT Export Purchasing Power (M^{cap,ToT}_t)
#   - M3.3a: T-CMPR Prebischian Purchasing Power of Exports (M^{cap,ToT}_t, \hat{\gamma} = 16.28)
#   - M3.3b: T-CMPR Level Machinery Import Imbalance (Imbalance_{level,t}, \hat{\gamma} = -1.64) [PREFERRED PRIMARY]
#   - M3.3e: T-CMPR WBOP Foreign Income Outflow Drain (D1c_t, \hat{\gamma} = 0.09) [PREFERRED FINANCIAL]
#
# Figure Protocol Rules:
#   - No titles/subtitles inside ggplot2 canvases (rendered in LaTeX .tex captions)
#   - Dual export to high-resolution PNG (300 dpi) and vectorized PDF (.pdf)
#   - Legend positioned at bottom with clean labels
#   - Year X-axis rotated 45 degrees with 5-year tick marks (seq(1940, 2010, 5))
#   - Strict notation: \kappa_t = k^{ME}_t - k^{NRC}_t for capital composition / mechanization gap
#   - Level Anchoring at 1980 Pinch Year (\mu_{CL, 1980} = 100%) [Ffrench-Davis peak pre-1982 crisis]
#   - NO DATA CLIPPING: Use coord_cartesian(ylim=...) or full empirical bounds so geom_line() draws 100% continuous unbroken series.
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(readr)
  library(gridExtra)
  library(grid)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

# Load Chile staged panel data
panel_path <- file.path(repo_root, "data", "staged", "ch2_panel_chile_with_prices.csv")
if (!file.exists(panel_path)) stop("Missing staged panel data at: ", panel_path)
df_raw <- read_csv(panel_path, show_col_types = FALSE)

# Clean and transform
df <- df_raw %>%
  mutate(
    y_t                  = log(GDP_real),
    k_NR                 = log(K_NR),
    k_ME                 = log(K_ME),
    kappa_t              = k_ME - k_NR,
    omega_lag            = lag(omega),
    p_kappa              = ifelse(is.na(p_kappa_ipmusa), p_kappa_rer, p_kappa_ipmusa),
    thresh_tot_mcap      = ln_M_cap_tot,
    thresh_imb_level     = imbalance_level,
    thresh_imb_growth    = imbalance_growth,
    thresh_wbop_m_manuf  = wbop_m_manuf,
    thresh_wbop_inc_out  = wbop_inc_outflow,
    thresh_wbop_ca       = wbop_ca
  ) %>%
  filter(year >= 1940 & year <= 2010, 
         !is.na(y_t), !is.na(k_NR), !is.na(kappa_t), !is.na(omega_lag), !is.na(p_kappa)) %>%
  arrange(year)

cat(sprintf("Estimation Sample Window: %d - %d (N = %d observations)\n", 
            min(df$year), max(df$year), nrow(df)))

# Load estimated parameters
results_csv <- file.path(repo_root, "output", "chile_imols_peripheral_results.csv")
if (!file.exists(results_csv)) stop("Missing Chilean results CSV at: ", results_csv)
res_df <- read_csv(results_csv, show_col_types = FALSE)

# Output Directories
out_fig_dir   <- file.path(repo_root, "output", "CL", "figures")
csv_out_dir   <- file.path(out_fig_dir, "csv")
vault_fig_dir <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "drafts", "ch2_sec4_4_peripheral_extension_Chile")

dir.create(out_fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(csv_out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(vault_fig_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Chilean Peripheral Master Figure Redesign Engine (Figures 1 - 5)\n")
cat("========================================================================\n")

# Non-parametric LOESS fit along historical path
fit_loess <- loess(k_ME ~ k_NR, data = df, span = 0.35)
df$k_ME_loess <- predict(fit_loess)

d_kME  <- c(df$k_ME_loess[2] - df$k_ME_loess[1], diff(df$k_ME_loess))
d_kNR  <- c(df$k_NR[2] - df$k_NR[1], diff(df$k_NR))
df$dkappa_dkNR <- (d_kME / d_kNR) - 1

df$s_ME_real  <- df$K_ME / (df$K_ME + df$K_NR)
df$s_NRC_real <- df$K_NR / (df$K_ME + df$K_NR)

# Pinch Year Index at 1980 (\mu_{CL, 1980} = 100%)
idx_1980 <- which(df$year == 1980)
if (length(idx_1980) == 0) stop("Pinch year 1980 not found in estimation sample!")

calc_chile_reconstruction <- function(mod_id) {
  sub_m <- res_df %>% filter(Model_ID == mod_id)
  
  coefs <- sub_m$Estimate
  gamma_val  <- sub_m$Gamma_Val[1]
  thresh_var <- sub_m$Thresh_Var[1]
  
  if (mod_id == "M3.1a") {
    theta_NR <- coefs[2]; theta_kp <- coefs[3]; theta_ok <- coefs[4]; theta_pk <- coefs[5]
    delta_kp <- 0; delta_ok <- 0; theta_ok_Mcap <- 0
  } else if (mod_id == "M3.2a") {
    theta_NR <- coefs[2]; theta_kp <- coefs[3]; theta_ok <- coefs[4]
    theta_ok_Mcap <- coefs[5]; theta_pk <- coefs[6]
    delta_kp <- 0; delta_ok <- 0
  } else {
    theta_NR <- coefs[2]; theta_kp <- coefs[3]; delta_kp <- coefs[4]
    theta_ok <- coefs[5]; delta_ok <- coefs[6]; theta_pk <- coefs[7]
    theta_ok_Mcap <- 0
  }
  
  D_ext <- if (!is.na(gamma_val) && thresh_var %in% colnames(df)) {
    ifelse(df[[thresh_var]] <= gamma_val, 1, 0)
  } else {
    rep(0, nrow(df))
  }
  
  if (mod_id == "M3.2a") {
    mp_kappa <- theta_kp + theta_ok * df$omega_lag + theta_ok_Mcap * (df$omega_lag * df$thresh_tot_mcap) + theta_pk * df$p_kappa
    mp_kappa_unconstrained <- mp_kappa
  } else {
    mp_kappa <- theta_kp + theta_ok * df$omega_lag + theta_pk * df$p_kappa + delta_kp * D_ext + delta_ok * (df$omega_lag * D_ext)
    mp_kappa_unconstrained <- theta_kp + theta_ok * df$omega_lag + theta_pk * df$p_kappa
  }
  
  theta_divisia <- (theta_NR + mp_kappa * df$dkappa_dkNR) / (1 + df$s_ME_real * df$dkappa_dkNR)
  theta_unconstrained <- (theta_NR + mp_kappa_unconstrained * df$dkappa_dkNR) / (1 + df$s_ME_real * df$dkappa_dkNR)
  
  y_1980  <- df$y_t[idx_1980]
  kn_1980 <- df$k_NR[idx_1980]
  kp_1980 <- df$kappa_t[idx_1980]
  pk_1980 <- df$p_kappa[idx_1980]
  ok_1980 <- (df$omega_lag * df$kappa_t)[idx_1980]
  
  if (mod_id == "M3.1a") {
    y_p <- y_1980 + theta_NR * (df$k_NR - kn_1980) + theta_kp * (df$kappa_t - kp_1980) + 
           theta_ok * (df$omega_lag * df$kappa_t - ok_1980) + theta_pk * (df$p_kappa - pk_1980)
    y_p_unconstrained <- y_p
  } else if (mod_id == "M3.2a") {
    ok_mcap_1980 <- (df$omega_lag * df$kappa_t * df$thresh_tot_mcap)[idx_1980]
    y_p <- y_1980 + theta_NR * (df$k_NR - kn_1980) + theta_kp * (df$kappa_t - kp_1980) + 
           theta_ok * (df$omega_lag * df$kappa_t - ok_1980) + 
           theta_ok_Mcap * (df$omega_lag * df$kappa_t * df$thresh_tot_mcap - ok_mcap_1980) + 
           theta_pk * (df$p_kappa - pk_1980)
    y_p_unconstrained <- y_p
  } else {
    kp_D_1980 <- (df$kappa_t * D_ext)[idx_1980]
    ok_D_1980 <- (df$omega_lag * df$kappa_t * D_ext)[idx_1980]
    y_p <- y_1980 + theta_NR * (df$k_NR - kn_1980) + theta_kp * (df$kappa_t - kp_1980) + 
           theta_ok * (df$omega_lag * df$kappa_t - ok_1980) + 
           delta_kp * (df$kappa_t * D_ext - kp_D_1980) + 
           delta_ok * (df$omega_lag * df$kappa_t * D_ext - ok_D_1980) + 
           theta_pk * (df$p_kappa - pk_1980)
    
    y_p_unconstrained <- y_1980 + theta_NR * (df$k_NR - kn_1980) + theta_kp * (df$kappa_t - kp_1980) + 
                         theta_ok * (df$omega_lag * df$kappa_t - ok_1980) + 
                         theta_pk * (df$p_kappa - pk_1980)
  }
  
  mu_t <- exp(df$y_t - y_p)
  mu_unconstrained <- exp(df$y_t - y_p_unconstrained)
  
  data.frame(
    year = df$year,
    y_obs = df$y_t,
    y_p = y_p,
    y_p_unconstrained = y_p_unconstrained,
    mu_t = mu_t,
    mu_unconstrained = mu_unconstrained,
    theta_t = theta_divisia,
    theta_unconstrained = theta_unconstrained,
    D_ext = D_ext,
    model_id = mod_id
  )
}

res_m31a <- calc_chile_reconstruction("M3.1a")
res_m32a <- calc_chile_reconstruction("M3.2a")
res_m33a <- calc_chile_reconstruction("M3.3a")
res_m33b <- calc_chile_reconstruction("M3.3b")
res_m33e <- calc_chile_reconstruction("M3.3e")

# Merge into master Chilean series dataframe
df_master <- df[, c("year", "y_t", "k_NR", "k_ME", "kappa_t", "p_kappa", "omega_lag", "thresh_tot_mcap", "thresh_imb_level", "thresh_wbop_inc_out")]

df_master <- df_master %>%
  left_join(res_m31a[, c("year", "mu_t", "theta_t")], by = "year") %>%
  rename(mu_m31a = mu_t, theta_m31a = theta_t) %>%
  left_join(res_m32a[, c("year", "mu_t", "theta_t")], by = "year") %>%
  rename(mu_m32a = mu_t, theta_m32a = theta_t) %>%
  left_join(res_m33a[, c("year", "mu_t", "theta_t", "D_ext")], by = "year") %>%
  rename(mu_m33a = mu_t, theta_m33a = theta_t, D_ext_m33a = D_ext) %>%
  left_join(res_m33b[, c("year", "mu_t", "theta_t", "D_ext", "theta_unconstrained", "mu_unconstrained")], by = "year") %>%
  rename(mu_m33b = mu_t, theta_m33b = theta_t, D_ext_m33b = D_ext, theta_unconstrained_m33b = theta_unconstrained, mu_unconstrained_m33b = mu_unconstrained) %>%
  left_join(res_m33e[, c("year", "mu_t", "theta_t", "D_ext")], by = "year") %>%
  rename(mu_m33e = mu_t, theta_m33e = theta_t, D_ext_m33e = D_ext)

write.csv(df_master, file.path(csv_out_dir, "cl_master_figure_series.csv"), row.names = FALSE)
cat("Chilean master series saved to:", file.path(csv_out_dir, "cl_master_figure_series.csv"), "\n")

apply_chile_theme <- function() {
  theme_minimal(base_size = 11) +
    theme(
      legend.position = "bottom",
      legend.title = element_blank(),
      legend.text = element_text(size = 9.5),
      axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1, color = "#222222", size = 9),
      axis.text.y = element_text(color = "#222222", size = 9),
      axis.title.x = element_text(margin = margin(t = 8), face = "bold", size = 10),
      axis.title.y = element_text(margin = margin(r = 8), face = "bold", size = 10),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "#E5E5E5", linewidth = 0.4),
      plot.margin = margin(t = 10, r = 15, b = 10, l = 15)
    )
}

save_dual_figure <- function(plot_obj, filename_base, width = 9, height = 5.2) {
  png_path1 <- file.path(out_fig_dir, paste0(filename_base, ".png"))
  pdf_path1 <- file.path(out_fig_dir, paste0(filename_base, ".pdf"))
  png_path2 <- file.path(vault_fig_dir, paste0(filename_base, ".png"))
  pdf_path2 <- file.path(vault_fig_dir, paste0(filename_base, ".pdf"))
  
  ggsave(png_path1, plot_obj, width = width, height = height, dpi = 300)
  ggsave(pdf_path1, plot_obj, width = width, height = height)
  ggsave(png_path2, plot_obj, width = width, height = height, dpi = 300)
  ggsave(pdf_path2, plot_obj, width = width, height = height)
  
  cat(sprintf("Exported Dual Chile Figure [%s] (.png & .pdf)\n", filename_base))
}

# ---------------------------------------------------------------------------
# FIGURE 1: Reconstructed Capacity Utilization for Chile (\mu_{CL, t})
# ---------------------------------------------------------------------------
p_fig1 <- ggplot(df_master, aes(x = year)) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "#8B0000", linewidth = 0.8) +
  geom_vline(xintercept = 1980, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  geom_line(aes(y = mu_m33b * 100, color = "Preferred Primary Demand (M3.3b Level Imbalance)"), linewidth = 1.1) +
  geom_line(aes(y = mu_m32a * 100, color = "Preferred Primary Continuous (M3.2a ToT Capacity)"), linewidth = 1.0, linetype = "dashed") +
  geom_line(aes(y = mu_m33e * 100, color = "Preferred Financial (M3.3e Income Outflow Drain)"), linewidth = 0.9, linetype = "longdash") +
  annotate("text", x = 1981, y = 125, label = "1980 Pinch Anchor (mu = 100%)", 
           color = "#006400", size = 3.3, hjust = 0, fontface = "bold") +
  scale_x_continuous(breaks = seq(1940, 2010, 5), limits = c(1940, 2010)) +
  scale_y_continuous(breaks = seq(40, 140, 20)) +
  coord_cartesian(ylim = c(40, 135)) +
  scale_color_manual(values = c(
    "Preferred Primary Demand (M3.3b Level Imbalance)" = "#1B365D",
    "Preferred Primary Continuous (M3.2a ToT Capacity)" = "#008080",
    "Preferred Financial (M3.3e Income Outflow Drain)" = "#7570B3"
  )) +
  labs(
    x = "Year",
    y = "Capacity Utilization (mu_CL,t, %)"
  ) +
  apply_chile_theme() +
  guides(color = guide_legend(nrow = 2, byrow = TRUE))

save_dual_figure(p_fig1, "cl_fig1_reconstructed_capacity_utilization")

# ---------------------------------------------------------------------------
# FIGURE 2: Divisia Aggregate Transformation Elasticity (\theta_t^{Peripheral})
# ---------------------------------------------------------------------------
p_fig2 <- ggplot(df_master, aes(x = year)) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "#8B0000", linewidth = 0.9) +
  geom_line(aes(y = theta_m33b, color = "Preferred Primary Demand (M3.3b Level Imbalance)"), linewidth = 1.1) +
  geom_line(aes(y = theta_m32a, color = "Preferred Primary Continuous (M3.2a ToT Capacity)"), linewidth = 1.0, linetype = "dashed") +
  geom_line(aes(y = theta_m33e, color = "Preferred Financial (M3.3e Income Outflow Drain)"), linewidth = 0.9, linetype = "longdash") +
  geom_vline(xintercept = 1980, linetype = "dotted", color = "#006400", linewidth = 0.7) +
  annotate("text", x = 1942, y = 1.04, label = "Overaccumulation Threshold (theta = 1.00)", 
           color = "#8B0000", fontface = "bold", size = 3.2, hjust = 0) +
  scale_x_continuous(breaks = seq(1940, 2010, 5), limits = c(1940, 2010)) +
  scale_y_continuous(breaks = seq(0.20, 1.40, 0.20)) +
  coord_cartesian(ylim = c(0.20, 1.40)) +
  scale_color_manual(values = c(
    "Preferred Primary Demand (M3.3b Level Imbalance)" = "#1B365D",
    "Preferred Primary Continuous (M3.2a ToT Capacity)" = "#008080",
    "Preferred Financial (M3.3e Income Outflow Drain)" = "#7570B3"
  )) +
  labs(
    x = "Year",
    y = "Transformation Elasticity (theta_t^Peripheral)"
  ) +
  apply_chile_theme() +
  guides(color = guide_legend(nrow = 2, byrow = TRUE))

save_dual_figure(p_fig2, "cl_fig2_divisia_transformation_elasticity")

# ---------------------------------------------------------------------------
# FIGURE 3: Peripheral Realization Penalty & Threshold Bottleneck (Stacked 2-Panel)
# ---------------------------------------------------------------------------
p_fig3_top <- ggplot(df_master, aes(x = year)) +
  geom_line(aes(y = theta_m33b, color = "Divisia Transformation Elasticity (theta_t, M3.3b)"), linewidth = 1.1) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "#8B0000", linewidth = 0.8) +
  geom_vline(xintercept = 1980, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  scale_x_continuous(breaks = seq(1940, 2010, 5), limits = c(1940, 2010)) +
  scale_y_continuous(breaks = seq(0.40, 1.40, 0.20)) +
  coord_cartesian(ylim = c(0.40, 1.40)) +
  scale_color_manual(values = c("Divisia Transformation Elasticity (theta_t, M3.3b)" = "#1B365D")) +
  labs(
    x = NULL,
    y = "Transformation Elasticity (theta_t)"
  ) +
  apply_chile_theme() +
  theme(axis.text.x = element_blank(), axis.title.x = element_blank())

p_fig3_bottom <- ggplot(df_master, aes(x = year)) +
  geom_step(aes(y = D_ext_m33b, color = "External Balance Bottleneck Indicator (D_t^ext)"), linewidth = 1.0) +
  geom_vline(xintercept = 1980, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  scale_x_continuous(breaks = seq(1940, 2010, 5), limits = c(1940, 2010)) +
  scale_y_continuous(breaks = c(0, 1), labels = c("0 (Slack)", "1 (Crisis Trap)")) +
  coord_cartesian(ylim = c(-0.1, 1.1)) +
  scale_color_manual(values = c("External Balance Bottleneck Indicator (D_t^ext)" = "#D95F02")) +
  labs(
    x = "Year",
    y = "Threshold Regime (D_t^ext)"
  ) +
  apply_chile_theme()

p_fig3_stacked <- grid.arrange(p_fig3_top, p_fig3_bottom, ncol = 1, heights = c(1, 1))
save_dual_figure(p_fig3_stacked, "cl_fig3_peripheral_realization_penalty_stacked", width = 9, height = 7.5)

# ---------------------------------------------------------------------------
# FIGURE 4: Heterogeneous Capital Composition (\kappa_t) & Relative Prices (p_t^\kappa)
# ---------------------------------------------------------------------------
p_fig4_top <- ggplot(df_master, aes(x = year)) +
  geom_line(aes(y = kappa_t, color = "Capital Composition Ratio (kappa_t = k_ME - k_NRC)"), linewidth = 1.1) +
  geom_vline(xintercept = 1980, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  scale_x_continuous(breaks = seq(1940, 2010, 5), limits = c(1940, 2010)) +
  scale_y_continuous(breaks = seq(-1.5, -0.3, 0.2)) +
  coord_cartesian(ylim = c(-1.5, -0.3)) +
  scale_color_manual(values = c("Capital Composition Ratio (kappa_t = k_ME - k_NRC)" = "#1B365D")) +
  labs(
    x = NULL,
    y = "Capital Composition (kappa_t)"
  ) +
  apply_chile_theme() +
  theme(axis.text.x = element_blank(), axis.title.x = element_blank())

p_fig4_bottom <- ggplot(df_master, aes(x = year)) +
  geom_line(aes(y = p_kappa, color = "Relative Capital Asset Price (p_t^kappa = P_ME / P_NRC)"), linewidth = 1.1) +
  geom_vline(xintercept = 1980, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  scale_x_continuous(breaks = seq(1940, 2010, 5), limits = c(1940, 2010)) +
  scale_color_manual(values = c("Relative Capital Asset Price (p_t^kappa = P_ME / P_NRC)" = "#008080")) +
  labs(
    x = "Year",
    y = "Relative Price Ratio (p_t^kappa)"
  ) +
  apply_chile_theme()

p_fig4_stacked <- grid.arrange(p_fig4_top, p_fig4_bottom, ncol = 1, heights = c(1, 1))
save_dual_figure(p_fig4_stacked, "cl_fig4_capital_composition_and_prices_stacked", width = 9, height = 7.5)

# ---------------------------------------------------------------------------
# FIGURE 5: Unconstrained Counterfactual Path & Productive Capacity Destruction (Stacked 2-Panel)
# ---------------------------------------------------------------------------
p_fig5_top <- ggplot(df_master, aes(x = year)) +
  geom_line(aes(y = theta_unconstrained_m33b, color = "Unconstrained Elasticity Path (theta_t^Unconstrained)"), linewidth = 1.1, linetype = "dashed") +
  geom_line(aes(y = theta_m33b, color = "Actual Threshold Constrained Path (theta_t^Actual)"), linewidth = 1.1) +
  geom_hline(yintercept = 1.00, linetype = "dotted", color = "#8B0000", linewidth = 0.8) +
  geom_vline(xintercept = 1980, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  annotate("rect", xmin = 1971, xmax = 1973, ymin = -Inf, ymax = Inf, fill = "#8B0000", alpha = 0.08) +
  annotate("rect", xmin = 1982, xmax = 1985, ymin = -Inf, ymax = Inf, fill = "#8B0000", alpha = 0.08) +
  annotate("text", x = 1972, y = 1.35, label = "Allende UP BoP Bottleneck", color = "#8B0000", size = 2.8, fontface = "bold") +
  annotate("text", x = 1983.5, y = 1.35, label = "1982 Debt Crisis Trap", color = "#8B0000", size = 2.8, fontface = "bold") +
  scale_x_continuous(breaks = seq(1940, 2010, 5), limits = c(1940, 2010)) +
  scale_y_continuous(breaks = seq(0.60, 1.40, 0.20)) +
  coord_cartesian(ylim = c(0.60, 1.40)) +
  scale_color_manual(values = c(
    "Unconstrained Elasticity Path (theta_t^Unconstrained)" = "#008080",
    "Actual Threshold Constrained Path (theta_t^Actual)" = "#1B365D"
  )) +
  labs(
    x = NULL,
    y = "Transformation Elasticity (theta_t)"
  ) +
  apply_chile_theme() +
  theme(axis.text.x = element_blank(), axis.title.x = element_blank())

p_fig5_bottom <- ggplot(df_master, aes(x = year)) +
  geom_line(aes(y = mu_unconstrained_m33b * 100, color = "Unconstrained Capacity Utilization (mu_t^Unconstrained, %)"), linewidth = 1.1, linetype = "dashed") +
  geom_line(aes(y = mu_m33b * 100, color = "Actual Capacity Utilization (mu_t^Actual, %)"), linewidth = 1.1) +
  geom_hline(yintercept = 100, linetype = "dashed", color = "#8B0000", linewidth = 0.8) +
  geom_vline(xintercept = 1980, linetype = "dotted", color = "#006400", linewidth = 0.8) +
  annotate("rect", xmin = 1971, xmax = 1973, ymin = -Inf, ymax = Inf, fill = "#8B0000", alpha = 0.08) +
  annotate("rect", xmin = 1982, xmax = 1985, ymin = -Inf, ymax = Inf, fill = "#8B0000", alpha = 0.08) +
  annotate("text", x = 1974, y = 58, label = "-50.4% Capacity Loss", color = "#8B0000", size = 3.0, fontface = "bold") +
  annotate("text", x = 1986, y = 52, label = "-45.7% Capacity Loss", color = "#8B0000", size = 3.0, fontface = "bold") +
  scale_x_continuous(breaks = seq(1940, 2010, 5), limits = c(1940, 2010)) +
  scale_y_continuous(breaks = seq(40, 140, 20)) +
  coord_cartesian(ylim = c(40, 135)) +
  scale_color_manual(values = c(
    "Unconstrained Capacity Utilization (mu_t^Unconstrained, %)" = "#008080",
    "Actual Capacity Utilization (mu_t^Actual, %)" = "#1B365D"
  )) +
  labs(
    x = "Year",
    y = "Capacity Utilization (mu_CL,t, %)"
  ) +
  apply_chile_theme()

p_fig5_stacked <- grid.arrange(p_fig5_top, p_fig5_bottom, ncol = 1, heights = c(1, 1))
save_dual_figure(p_fig5_stacked, "cl_fig5_unconstrained_counterfactual_destruction_stacked", width = 9, height = 7.5)

cat("========================================================================\n")
cat("Chilean Peripheral Master Figure Generation Complete! All 5 figures generated.\n")
cat("========================================================================\n")
