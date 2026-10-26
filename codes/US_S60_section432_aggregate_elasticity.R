#!/usr/bin/env Rscript

# US_S60_section432_aggregate_elasticity.R
# ---------------------------------------------------------------------------
# Section 4.3.2 Aggregate Transformation Elasticity Engine & Figure Protocol
#
# Model: 
#   - Primary: M2.44b (Clean Corporate Tier 1 NVA, Set 2, Yes Break)
#
# Output Figures:
#   - fig_specB_candidate1_aggregate_elasticity (.png & .pdf)
#   - fig_specB_candidate2_aggregate_elasticity (.png & .pdf)
#   - fig_specB_dkappa_dknrc_slope (.png & .pdf)
#
# Visual Protocol: Adheres strictly to US_S60_section4313_omega_iota_plot.R
#   - Structural Regime Background Shading (5 historical eras)
#   - Period Banners & Vertical Boundary Lines
#   - Zero Titles/Subtitles in ggplot2 (all handled in LaTeX)
#   - Dual Vector PDF + High-DPI PNG Outputs
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(cointReg)
  library(grid)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
rds_path_specB  <- file.path(repo_root, "output", "US", "S61_SECTION32_IMOLS", "rds", "s61_fitted_models.rds")
f_in            <- file.path(repo_root, "output", "gpim_specB_components_long.csv")

out_dir   <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY")
csv_dir   <- file.path(out_dir, "csv")
fig_dir   <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
fig_vault <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "figures")
paper_dir <- file.path(repo_root, "chapter2_paper", "paper_tex_tables")

for (d in c(csv_dir, fig_dir, fig_vault, paper_dir, file.path(out_dir, "fig"))) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
}

cat("========================================================================\n")
cat("S60: Section 4.3.2 Aggregate Transformation Elasticity Suite\n")
cat("========================================================================\n")

if (!file.exists(rds_path_specB)) stop("Fitted models RDS not found at: ", rds_path_specB)
fs_specB <- readRDS(rds_path_specB)

compute_centered_derivative <- function(x, t) {
  n <- length(x)
  d <- rep(NA, n)
  d[1] <- (x[2] - x[1]) / (t[2] - t[1])
  for(i in 2:(n-1)) d[i] <- (x[i+1] - x[i-1]) / (t[i+1] - t[i-1])
  d[n] <- (x[n] - x[n-1]) / (t[n] - t[n-1])
  return(d)
}

# ==============================================================================
# ESTIMATION & ELASTICITY RECOVERY
# ==============================================================================
m <- fs_specB[["M2.44b"]]
df <- read.csv(f_in)

df_clean <- df[df$year %in% m$years, ]
df_clean <- df_clean[order(df_clean$year), ]

val_ME_real  <- df_clean$K_ME
val_NRC_real <- df_clean$K_NRC
df_clean$s_ME_real  <- val_ME_real / (val_ME_real + val_NRC_real)
df_clean$s_NRC_real <- val_NRC_real / (val_ME_real + val_NRC_real)

w_var <- if (grepl("Tier 1", m$Wage_Label)) "omega_ST_Tier1_NVA_lag1" else "omega_ST_Tier2_NVA_lag1"
w <- df_clean[[w_var]]

df_clean$iota_t <- df_clean$IPP_share_capital_plus_IPP
df_clean$iota_lag1 <- dplyr::lag(df_clean$iota_t, 1L)
df_clean$iota_lag1[1] <- df_clean$iota_t[1]

iota <- df_clean$iota_lag1
C_idx <- w * (1 - iota) # AT VALUE

kn <- df_clean$k_NRC - df_clean$k_NRC[1]
kp <- (df_clean$k_ME - df_clean$k_NRC) - (df_clean$k_ME[1] - df_clean$k_NRC[1])
pk <- df_clean$p_rel - df_clean$p_rel[1]

C_idx_c <- C_idx - C_idx[1]
inter_raw_1 <- kp * C_idx_c
inter_raw_2 <- kp * pk

deter_f <- m$deter
aux_df <- as.data.frame(cbind(k_NRC = kn, kappa = kp, deter_f))

fit_aux_w <- lm(inter_raw_1 ~ . - 1, data = aux_df)
fit_aux_p <- lm(inter_raw_2 ~ . - 1, data = aux_df)

a_w_NRC <- coef(fit_aux_w)["k_NRC"]
a_w_kp  <- coef(fit_aux_w)["kappa"]
a_p_NRC <- coef(fit_aux_p)["k_NRC"]
a_p_kp  <- coef(fit_aux_p)["kappa"]

theta <- m$fit$theta
d_k <- ncol(m$deter)

theta_NRC_hat <- theta[d_k + 1]
theta_kp_hat  <- theta[d_k + 2]
theta_iw_hat  <- theta[d_k + 3]
theta_ip_hat  <- theta[d_k + 4]

theta_NRC_str <- theta_NRC_hat - theta_iw_hat * a_w_NRC - theta_ip_hat * a_p_NRC
theta_kp_str  <- theta_kp_hat  - theta_iw_hat * a_w_kp  - theta_ip_hat * a_p_kp

mp_kappa_str <- theta_kp_str + theta_iw_hat * C_idx_c + theta_ip_hat * pk

# Candidate 1: Asset-Weighted Structural Yield
theta_Cand1 <- theta_NRC_str + df_clean$s_ME_real * mp_kappa_str

# Candidate 2: Growth-Weighted Chain Rule
fit_ME  <- loess(k_ME ~ year, data = df_clean, span = 0.35, control = loess.control(surface = "direct"))
fit_NRC <- loess(k_NRC ~ year, data = df_clean, span = 0.35, control = loess.control(surface = "direct"))
fit_cap <- loess(log(K_ME + K_NRC) ~ year, data = df_clean, span = 0.35, control = loess.control(surface = "direct"))

dk_ME_dt  <- compute_centered_derivative(predict(fit_ME), df_clean$year)
dk_NRC_dt <- compute_centered_derivative(predict(fit_NRC), df_clean$year)
dk_cap_dt <- compute_centered_derivative(predict(fit_cap), df_clean$year)

dy_dt <- theta_NRC_str * dk_NRC_dt + mp_kappa_str * (dk_ME_dt - dk_NRC_dt)
theta_Cand2 <- dy_dt / dk_cap_dt

# Path Slopes (Figure 2)
dk_ME_dk_NRC  <- dk_ME_dt / dk_NRC_dt
dkappa_dk_NRC <- dk_ME_dk_NRC - 1

# Spec A Baseline Path
theta_SpecA_path <- 0.58 - 0.30 * C_idx

combined_df <- data.frame(
  year = df_clean$year,
  s_ME_real = df_clean$s_ME_real,
  C_idx = C_idx,
  mp_kappa_str = mp_kappa_str,
  theta_Cand1 = theta_Cand1,
  theta_Cand2 = theta_Cand2,
  dk_ME_dk_NRC = dk_ME_dk_NRC,
  dkappa_dk_NRC = dkappa_dk_NRC,
  theta_SpecA_path = theta_SpecA_path,
  theta_SpecA_baseline = 0.58
)

csv_path <- file.path(csv_dir, "s60_specB_aggregate_elasticity.csv")
write.csv(combined_df, csv_path, row.names = FALSE)
cat("Saved dataset to:", csv_path, "\n")

# ==============================================================================
# FIGURE PROTOCOL & REGIME SHADING DATA (Harmonized Post-Fordism 1974-2009 & Monopoly Capital 2010-2024)
# ==============================================================================
shade_df <- data.frame(
  xmin = c(1939, 1947, 1968, 1974, 2010),
  xmax = c(1945, 1967, 1973, 2009, 2024),
  fill_color = c("#CBD5E1", "#D1FAE5", "#FEE2E2", "#FEF3C7", "#E0E7FF"),
  alpha_val = c(0.50, 0.55, 0.60, 0.50, 0.50)
)

anno_df <- data.frame(
  x = c(1942.0, 1957.0, 1970.5, 1991.5, 2017.0),
  y = rep(1.42, 5),
  label = c(
    "War Mobilization\n(1939–1945)",
    "Atlantic Fordism\n(1947–1967)",
    "Profit Squeeze\n(1968–1973)",
    "Post-Fordism &\nFinancialization\n(1974–2009)",
    "Intellectual Monopoly\nCapital (2010–2024)"
  ),
  size = rep(3.8, 5)
)

theme_protocol <- function() {
  theme_classic(base_size = 11) %+replace%
    theme(
      legend.position = "bottom",
      legend.background = element_rect(fill = "transparent", color = NA),
      legend.key.width = unit(1.8, "line"),
      legend.text = element_text(size = 9.5),
      axis.title.y = element_text(face = "bold", margin = margin(r = 10), angle = 90),
      axis.title.x = element_text(face = "bold", margin = margin(t = 8)),
      axis.line.x = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.line.y = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.ticks = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.text = element_text(color = "black"),
      plot.margin = margin(t = 10, r = 15, b = 10, l = 10)
    )
}

# ==============================================================================
# FIGURE 1A: CANDIDATE 1 (ASSET-WEIGHTED STRUCTURAL YIELD)
# ==============================================================================
p_cand1 <- ggplot(combined_df, aes(x = year)) +
  geom_rect(data = shade_df, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill_color, alpha = alpha_val)) +
  scale_fill_identity() +
  scale_alpha_identity() +
  geom_vline(xintercept = c(1947, 1968, 1974, 2010), color = "gray50", linetype = "dotted", linewidth = 0.5) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "#8B0000", linewidth = 0.8) +
  geom_hline(yintercept = 0.58, linetype = "dotted", color = "#D9534F", linewidth = 0.8) +
  geom_text(data = anno_df, aes(x = x, y = y, label = label, size = size), inherit.aes = FALSE, 
            vjust = 1, lineheight = 0.9, color = "black", fontface = "bold") +
  scale_size_identity() +
  geom_line(aes(y = theta_Cand1, color = "Candidate 1: Asset-Weighted Yield (Spec B)"), linewidth = 1.1, linetype = "solid") +
  geom_line(aes(y = theta_SpecA_path, color = "Spec A Dynamic Baseline"), linewidth = 1.1, linetype = "dashed") +
  scale_y_continuous(
    name = expression(paste("Aggregate Transformation Elasticity (", theta[t], ")")),
    limits = c(0.00, 1.50),
    breaks = seq(0.00, 1.50, by = 0.25)
  ) +
  scale_x_continuous(
    name = "Year",
    breaks = seq(1930, 2020, by = 10),
    expand = c(0.01, 0.01)
  ) +
  scale_color_manual(
    name = NULL,
    values = c(
      "Candidate 1: Asset-Weighted Yield (Spec B)" = "#1B365D",
      "Spec A Dynamic Baseline" = "#5C768D"
    ),
    labels = c(
      expression(paste("Candidate 1: Asset-Weighted Yield (", theta[NRC]^str + s[ME] %*% MP[kappa]^str, ")")),
      expression(paste("Spec A Baseline (", 0.58 - 0.30 %*% C[index], ")"))
    )
  ) +
  theme_protocol()

# Export Figure 1a (Harmonized name: fig_us_specB_aggregate_elasticity)
ggsave(file.path(fig_dir, "fig_us_specB_aggregate_elasticity.png"), p_cand1, width = 9.5, height = 5.2, dpi = 300)
ggsave(file.path(fig_dir, "fig_us_specB_aggregate_elasticity.pdf"), p_cand1, width = 9.5, height = 5.2, device = cairo_pdf)
ggsave(file.path(fig_vault, "fig_us_specB_aggregate_elasticity.png"), p_cand1, width = 9.5, height = 5.2, dpi = 300)
ggsave(file.path(fig_vault, "fig_us_specB_aggregate_elasticity.pdf"), p_cand1, width = 9.5, height = 5.2, device = cairo_pdf)
cat("Saved Figure 1a (Harmonized Spec B Aggregate Elasticity)\n")

# ==============================================================================
# FIGURE 1B: CANDIDATE 2 (GROWTH-WEIGHTED CHAIN RULE)
# ==============================================================================
p_cand2 <- ggplot(combined_df, aes(x = year)) +
  geom_rect(data = shade_df, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill_color, alpha = alpha_val)) +
  scale_fill_identity() +
  scale_alpha_identity() +
  geom_vline(xintercept = c(1947, 1968, 1974, 2008), color = "gray50", linetype = "dotted", linewidth = 0.5) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "#8B0000", linewidth = 0.9) +
  geom_hline(yintercept = 0.58, linetype = "dotted", color = "#D9534F", linewidth = 0.9) +
  geom_text(data = anno_df, aes(x = x, y = y, label = label, size = size), inherit.aes = FALSE, 
            vjust = 1, lineheight = 0.9, color = "black") +
  scale_size_identity() +
  geom_line(aes(y = theta_Cand2, color = "Candidate 2: Growth-Weighted Yield (Spec B)"), linewidth = 1.2, linetype = "solid") +
  geom_line(aes(y = theta_SpecA_path, color = "Spec A Dynamic Baseline"), linewidth = 1.0, linetype = "dashed") +
  scale_y_continuous(
    name = expression(paste("Aggregate Transformation Elasticity (", theta[t], ")")),
    limits = c(0.00, 1.80),
    breaks = seq(0.00, 1.75, by = 0.25)
  ) +
  scale_x_continuous(
    name = "Year",
    breaks = seq(1930, 2020, by = 10),
    expand = c(0.01, 0.01)
  ) +
  scale_color_manual(
    name = NULL,
    values = c(
      "Candidate 2: Growth-Weighted Yield (Spec B)" = "#1B365D",
      "Spec A Dynamic Baseline" = "#5C768D"
    ),
    labels = c(
      expression(paste("Candidate 2: Growth-Weighted Yield (", (dy^p/dt) / (dk[cap]/dt), ")")),
      expression(paste("Spec A Baseline (", 0.58 - 0.30 %*% C[index], ")"))
    )
  ) +
  theme_protocol()

# Export Figure 1b
ggsave(file.path(fig_dir, "fig_specB_candidate2_aggregate_elasticity.png"), p_cand2, width = 9.5, height = 5.2, dpi = 300)
ggsave(file.path(fig_dir, "fig_specB_candidate2_aggregate_elasticity.pdf"), p_cand2, width = 9.5, height = 5.2, device = cairo_pdf)
ggsave(file.path(fig_vault, "fig_specB_candidate2_aggregate_elasticity.png"), p_cand2, width = 9.5, height = 5.2, dpi = 300)
ggsave(file.path(fig_vault, "fig_specB_candidate2_aggregate_elasticity.pdf"), p_cand2, width = 9.5, height = 5.2, device = cairo_pdf)
cat("Saved Figure 1b (Candidate 2)\n")

# ==============================================================================
# FIGURE 2: EMPIRICAL ACCUMULATION PATH DERIVATIVES (dk_ME / dk_NRC & dkappa / dk_NRC)
# ==============================================================================
anno_df_fig2 <- data.frame(
  x = c(1942.0, 1957.0, 1970.5, 1991.5, 2017.0),
  y = rep(2.35, 5),
  label = c(
    "War Mobilization\n(1939–1945)",
    "Atlantic Fordism\n(1947–1967)",
    "Profit Squeeze\n(1968–1973)",
    "Post-Fordism &\nFinancialization\n(1974–2009)",
    "Intellectual Monopoly\nCapital (2010–2024)"
  ),
  size = rep(3.8, 5)
)

p_slope <- ggplot(combined_df, aes(x = year)) +
  geom_rect(data = shade_df, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill_color, alpha = alpha_val)) +
  scale_fill_identity() +
  scale_alpha_identity() +
  geom_vline(xintercept = c(1947, 1968, 1974, 2010), color = "gray50", linetype = "dotted", linewidth = 0.5) +
  geom_hline(yintercept = 1.00, linetype = "dashed", color = "gray30", linewidth = 0.8) +
  geom_hline(yintercept = 0.00, linetype = "solid", color = "gray60", linewidth = 0.5) +
  geom_text(data = anno_df_fig2, aes(x = x, y = y, label = label, size = size), inherit.aes = FALSE, 
            vjust = 1, lineheight = 0.9, color = "black", fontface = "bold") +
  scale_size_identity() +
  geom_line(aes(y = dk_ME_dk_NRC, color = "Relative Accumulation Slope (dk^ME / dk^NRC)"), linewidth = 1.1, linetype = "solid") +
  geom_line(aes(y = dkappa_dk_NRC, color = "Mechanization Gap Derivative (dkappa / dk^NRC)"), linewidth = 1.1, linetype = "dotdash") +
  scale_y_continuous(
    name = expression(paste("Accumulation Path Slope")),
    limits = c(-1.20, 2.50),
    breaks = seq(-1.00, 2.50, by = 0.50)
  ) +
  scale_x_continuous(
    name = "Year",
    breaks = seq(1930, 2020, by = 10),
    expand = c(0.01, 0.01)
  ) +
  scale_color_manual(
    name = NULL,
    values = c(
      "Relative Accumulation Slope (dk^ME / dk^NRC)" = "#10B981",
      "Mechanization Gap Derivative (dkappa / dk^NRC)" = "#DC2626"
    ),
    labels = c(
      expression(paste("Relative Accumulation Slope (", dk^ME / dk^NRC, ")")),
      expression(paste("Mechanization Gap Derivative (", dkappa / dk^NRC, " = ", dk^ME / dk^NRC - 1, ")"))
    )
  ) +
  theme_protocol()

# Export Figure 2 (Harmonized name: fig_us_specB_dkappa_slope)
ggsave(file.path(fig_dir, "fig_us_specB_dkappa_slope.png"), p_slope, width = 9.5, height = 5.2, dpi = 300)
ggsave(file.path(fig_dir, "fig_us_specB_dkappa_slope.pdf"), p_slope, width = 9.5, height = 5.2, device = cairo_pdf)
ggsave(file.path(fig_vault, "fig_us_specB_dkappa_slope.png"), p_slope, width = 9.5, height = 5.2, dpi = 300)
ggsave(file.path(fig_vault, "fig_us_specB_dkappa_slope.pdf"), p_slope, width = 9.5, height = 5.2, device = cairo_pdf)
cat("Saved Figure 2 (Harmonized Path Slopes: PNG & PDF)\n")

cat("S60 Aggregate Elasticity Suite Execution Complete!\n")
