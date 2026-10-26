#!/usr/bin/env Rscript

# US_S60_section432_dual_plot_specB.R
# ---------------------------------------------------------------------------
# Section 4.3.2 Dual-Axis Plot Generation for Specification B
# Capacity Utilization (μ_t) and Asset-Weighted Transformation Elasticity (θ_t)
#
# Model: M2.44b (Clean Corporate Tier 1 NVA, Set 2, Yes Break)
# Pinch Year: 1973 (μ_1973 = 100%)
# Transformation Elasticity: Locked Asset-Weighted Structural Yield
#   theta_t = theta_NRC_str + s_ME_real * MP_kappa_str
#
# Protocol & Aesthetics:
#   - Dual Y-Axis: Left = Capacity Utilization μ_t (%), Right = Transformation Elasticity θ_t
#   - 90-Degree Rotated Right Axis Label for θ_t
#   - 5 Structural Regime Shading Eras & Top Banner Annotations
#   - Reference Lines: μ = 100% (dashed), θ = 1.00 (Harrodian knife-edge), θ = 0.58 (Spec A base)
#   - Full Sample Range [1931-2024] Unclipped Limits: μ ∈ [50, 130], θ ∈ [0.20, 1.40]
#   - Outputs: Vector PDF (cairo_pdf) + High-DPI PNG
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(scales)
  library(cointReg)
  library(grid)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
rds_path_specB <- file.path(repo_root, "output", "US", "S61_SECTION32_IMOLS", "rds", "s61_fitted_models.rds")
f_in           <- file.path(repo_root, "output", "gpim_specB_components_long.csv")

out_dir    <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY", "fig")
fig_dir    <- file.path(repo_root, "chapter2_paper", "paper_tex_tables")
fig_vault  <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "drafts", "ch2_sec4_3_heterogeneous_capital_US")
brain_dir  <- "C:/Users/User/.gemini/antigravity/brain/b0cd553c-177b-4568-8922-6446219b2174"

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(fig_vault, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Dual-Axis μ_t & θ_t Plot Generation (Specification B - M2.44b)\n")
cat("========================================================================\n")

if (!file.exists(rds_path_specB)) stop("Fitted models RDS not found at: ", rds_path_specB)
fs_specB <- readRDS(rds_path_specB)

# -----------------------------------------------------------------
# 1. Load fitted model (M2.44b - Clean Corp Tier 1 NVA, Set 2, Breaks)
# -----------------------------------------------------------------
m <- fs_specB[["M2.44b"]]
df <- read.csv(f_in)

df_clean <- df[df$year %in% m$years, ]
df_clean <- df_clean[order(df_clean$year), ]

# Physical capital asset shares
val_ME_real  <- df_clean$K_ME
val_NRC_real <- df_clean$K_NRC
df_clean$s_ME_real  <- val_ME_real / (val_ME_real + val_NRC_real)
df_clean$s_NRC_real <- val_NRC_real / (val_ME_real + val_NRC_real)

# Effective wage pressure
w_var <- if (grepl("Tier 1", m$Wage_Label)) "omega_ST_Tier1_NVA_lag1" else "omega_ST_Tier2_NVA_lag1"
w <- df_clean[[w_var]]

df_clean$iota_t <- df_clean$IPP_share_capital_plus_IPP
df_clean$iota_lag1 <- dplyr::lag(df_clean$iota_t, 1L)
df_clean$iota_lag1[1] <- df_clean$iota_t[1]

iota <- df_clean$iota_lag1
C_idx <- w * (1 - iota)

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

# -----------------------------------------------------------------
# 2. Compute Locked Structural Asset-Weighted Elasticity (theta_t)
# -----------------------------------------------------------------
df_clean$theta_t <- theta_NRC_str + df_clean$s_ME_real * mp_kappa_str

# -----------------------------------------------------------------
# 3. Compute Productive Capacity y_p and Capacity Utilization mu_t (Pinch 1973)
# -----------------------------------------------------------------
o1 <- m$X_mat[, "inter_w"]
o2 <- m$X_mat[, "inter_p"]

idx_1973 <- which(df_clean$year == 1973)
if (length(idx_1973) == 0) stop("1973 pinch year not found!")

y_1973 <- df_clean$y_t[idx_1973]

y_p <- y_1973 + 
       theta_NRC_hat * (kn - kn[idx_1973]) + 
       theta_kp_hat  * (kp - kp[idx_1973]) + 
       theta_iw_hat  * (o1 - o1[idx_1973]) + 
       theta_ip_hat  * (o2 - o2[idx_1973])

if (d_k > 1) {
  gamma_coefs <- theta[2:d_k]
  D_mat <- deter_f[, 2:d_k, drop = FALSE]
  D_diff <- sweep(D_mat, 2, D_mat[idx_1973, ], "-")
  y_p <- y_p + as.vector(D_diff %*% gamma_coefs)
}

df_clean$y_p <- y_p
df_clean$mu_t <- exp(df_clean$y_t - y_p) * 100

# Date mapping for plotting
df_clean$Date <- as.Date(paste0(df_clean$year, "-01-01"))

# Export series to CSV for cross-script consumption
csv_out_dir <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY", "csv")
dir.create(csv_out_dir, recursive = TRUE, showWarnings = FALSE)
write.csv(df_clean[, c("year", "mu_t")], file.path(csv_out_dir, "us_mu_m244b.csv"), row.names = FALSE)

# -----------------------------------------------------------------
# 4. Dual-Axis Scaling & Transformations (Unclipped Full Range)
# -----------------------------------------------------------------
mu_min <- 50
mu_max <- 130

th_min <- 0.20
th_max <- 1.40

scale_factor <- (mu_max - mu_min) / (th_max - th_min)
shift_factor <- mu_min - scale_factor * th_min

df_clean$theta_scaled <- df_clean$theta_t * scale_factor + shift_factor

# -----------------------------------------------------------------
# 5. Regime Shading & Annotations Protocol (Harmonized Post-Fordism 1974-2009 & Monopoly Capital 2010-2024)
# -----------------------------------------------------------------
shade_df <- data.frame(
  xmin = as.Date(c("1939-01-01", "1947-01-01", "1968-01-01", "1974-01-01", "2010-01-01")),
  xmax = as.Date(c("1945-12-31", "1967-12-31", "1973-12-31", "2009-12-31", "2024-12-31")),
  fill_color = c("#CBD5E1", "#D1FAE5", "#FEE2E2", "#FEF3C7", "#E0E7FF"),
  alpha_val  = c(0.50, 0.55, 0.60, 0.50, 0.50)
)

anno_df <- data.frame(
  x = as.Date(c("1942-01-01", "1957-01-01", "1971-01-01", "1992-01-01", "2017-06-01")),
  y = rep(mu_max - 2.0, 5),
  label = c(
    "War Mobilization\n(1939–1945)",
    "Atlantic Fordism\n(1947–1967)",
    "Profit Squeeze\n(1968–1973)",
    "Post-Fordism &\nFinancialization\n(1974–2009)",
    "Intellectual Monopoly\nCapital (2010–2024)"
  ),
  size = rep(3.8, 5)
)

# Reference lines scaled
th_100_scaled <- 1.00 * scale_factor + shift_factor
th_058_scaled <- 0.58 * scale_factor + shift_factor

# -----------------------------------------------------------------
# 6. Plot Theme (Protocol Compliant)
# -----------------------------------------------------------------
theme_dual_axis <- function() {
  theme_classic(base_size = 11) %+replace%
    theme(
      panel.background = element_blank(),
      plot.background  = element_blank(),

      axis.line.x       = element_line(color = "#2C3E50", linewidth = 0.8),
      axis.line.y.left  = element_line(color = "#1A2530", linewidth = 0.8),
      axis.line.y.right = element_line(color = "#C0392B", linewidth = 0.8),

      axis.ticks.x      = element_line(linewidth = 0.6, color = "#2C3E50"),
      axis.ticks.y.left = element_line(color = "#1A2530", linewidth = 0.6),
      axis.ticks.y.right= element_line(color = "#C0392B", linewidth = 0.6),
      axis.ticks.length = unit(0.20, "cm"),

      axis.text.x       = element_text(color = "black"),
      axis.text.y.left  = element_text(color = "#1A2530", face = "bold"),
      axis.text.y.right = element_text(color = "#C0392B", face = "bold"),

      axis.title.x       = element_text(face = "bold", margin = margin(t = 8), color = "black"),
      axis.title.y.left  = element_text(color = "#1A2530", face = "bold", margin = margin(r = 8)),
      axis.title.y.right = element_text(color = "#C0392B", face = "bold", angle = 90, margin = margin(l = 8)),

      legend.position   = "bottom",
      legend.direction  = "horizontal",
      legend.title      = element_blank(),
      legend.background = element_blank(),
      legend.key        = element_blank(),
      legend.key.width  = unit(1.5, "cm"),
      plot.margin       = margin(t = 10, r = 15, b = 10, l = 10)
    )
}

# -----------------------------------------------------------------
# 7. Construct Dual Plot Object
# -----------------------------------------------------------------
p_dual <- ggplot(df_clean, aes(x = Date)) +
  # Background Shading
  geom_rect(data = shade_df, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill_color, alpha = alpha_val)) +
  scale_fill_identity() +
  scale_alpha_identity() +

  # Boundary lines
  geom_vline(xintercept = as.Date(c("1947-01-01", "1968-01-01", "1974-01-01", "2010-01-01")),
             color = "gray50", linetype = "dotted", linewidth = 0.5) +

  # Annotations (Enlarged size = 3.8 bold)
  geom_text(data = anno_df, aes(x = x, y = y, label = label, size = size),
            inherit.aes = FALSE, vjust = 1, lineheight = 0.9, color = "black", fontface = "bold") +
  scale_size_identity() +

  # Reference Lines
  geom_hline(yintercept = 100, linetype = "dashed", color = "#1A2530", linewidth = 0.7) +
  geom_hline(yintercept = th_100_scaled, linetype = "dashed", color = "#8B0000", linewidth = 0.7) +
  geom_hline(yintercept = th_058_scaled, linetype = "dotted", color = "#D9534F", linewidth = 0.7) +

  # Time Series Lines
  geom_line(aes(y = mu_t, color = "Implicit Capacity Utilization (mu_t)"), linewidth = 1.1, linetype = "solid") +
  geom_line(aes(y = theta_scaled, color = "Transformation Elasticity (theta_t)"), linewidth = 1.1, linetype = "dashed") +

  # Color Scale & Labels
  scale_color_manual(
    values = c(
      "Implicit Capacity Utilization (mu_t)" = "#1A2530",
      "Transformation Elasticity (theta_t)" = "#C0392B"
    ),
    labels = c(
      expression(paste("Implicit Capacity Utilization ", mu[t], " (%) [Pinch 1973]")),
      expression(paste("Structural Transformation Elasticity ", theta[t], " (Asset-Weighted)"))
    )
  ) +

  # Continuous Dual Axis Scaling
  scale_y_continuous(
    name = expression(paste("Implicit Capacity Utilization ", mu[t], " (%)")),
    limits = c(mu_min, mu_max),
    breaks = seq(mu_min, mu_max, by = 10),
    sec.axis = sec_axis(
      transform = ~ (. - shift_factor) / scale_factor,
      name = expression(paste("Transformation Elasticity ", theta[t])),
      breaks = seq(0.20, 1.40, by = 0.20),
      labels = scales::number_format(accuracy = 0.01)
    )
  ) +
  scale_x_date(
    name = "Year",
    date_breaks = "10 years",
    date_labels = "%Y",
    expand = c(0.01, 0)
  ) +
  theme_dual_axis()

# -----------------------------------------------------------------
# 8. Export Visual Artifacts (PNG & Cairo PDF)
# -----------------------------------------------------------------
fig_dir   <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
fig_vault <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "figures")

for (d in c(out_dir, fig_dir, fig_vault)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path(d, "fig_us_specB_dual_theta_mu.pdf"), plot = p_dual, width = 9.5, height = 5.2, device = cairo_pdf)
  ggsave(file.path(d, "fig_us_specB_dual_theta_mu.png"), plot = p_dual, width = 9.5, height = 5.2, dpi = 300, type = "cairo")
}

cat("Dual-axis plot saved successfully across output, paper_tex_tables, vault, and artifacts as fig_us_specB_dual_theta_mu.pdf!\n")
