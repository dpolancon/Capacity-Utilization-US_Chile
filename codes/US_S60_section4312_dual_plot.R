#!/usr/bin/env Rscript

# US_S60_section4312_dual_plot.R
# Dual-axis capacity utilization and transformation elasticity plot
# specific to Section 4.3.1.2 based on Model M2.11b (Clean Corp Tier 1 NVA).

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(scales)
})

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
s50_dir   <- file.path(repo_root, "output", "US", "S50_SECTION31_IMOLS")
s41_csv   <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data", "s41_extended_capital_panel.csv")
s29f_csv  <- file.path(repo_root, "output", "US", "S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION", "csv", "S29F_shaikh_tonak_wage_share_panel.csv")
fred_csv  <- file.path(repo_root, "output", "US", "S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION", "csv", "fred_annual_ad_components_panel.csv")
out_dir   <- file.path(repo_root, "output", "US", "S60_CAPACITY_RECOVERY", "fig")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

cat("========================================================================\n")
cat("S60: Dual-Axis Plot Generation for Section 4.3.1.2\n")
cat("========================================================================\n")

# 1. Load fitted models
models_path <- file.path(s50_dir, "rds", "s50_fitted_models.rds")
fs <- readRDS(models_path)
m <- fs[["M2.11b"]] # Clean Corporate Tier 1 NVA (With break shifts)

# 2. Reconstruct design panel
df_cap <- read.csv(s41_csv, stringsAsFactors = FALSE)
df_st  <- read.csv(s29f_csv, stringsAsFactors = FALSE)
df_fred <- read.csv(fred_csv, stringsAsFactors = FALSE)

df <- df_cap[, c("year", "k_cap")]
df <- merge(df, df_st[, c("year", "omega_CORP_NVA_clean_Tier1")], by = "year", all.x = TRUE)
df <- merge(df, df_fred[, c("year", "GDP_real")], by = "year", all.x = TRUE)

df <- df[df$year >= 1929 & df$year <= 2024, ]
df <- df[order(df$year), ]

# Lags
df$omega_lag1 <- dplyr::lag(df$omega_CORP_NVA_clean_Tier1, 1L)
df$iota_t <- df_cap$IPP_share_capital_plus_IPP[match(df$year, df_cap$year)]
df$iota_lag1 <- dplyr::lag(df$iota_t, 1L)

req_cols <- c("year", "k_cap", "omega_lag1", "iota_lag1", "GDP_real")
df_clean <- df[complete.cases(df[, req_cols]), ]

# 3. Parameter extraction
coefs <- m$fit$theta
d_k <- ncol(m$deter)
b_idx <- d_k + 1 # k_cap
d_idx <- d_k + 2 # interaction

theta_0 <- coefs[b_idx]
theta_1 <- coefs[d_idx]

# 4. Math construction
# Per user request: DO NOT center C_index wrt 1929.
# theta_t = theta_0 + theta_1 * (omega_lag1 * (1 - iota_lag1))
df_clean$C_index <- df_clean$omega_lag1 * (1 - df_clean$iota_lag1)
df_clean$theta_t <- theta_0 + theta_1 * df_clean$C_index

y_agg <- log(df_clean$GDP_real)
k_t   <- df_clean$k_cap

idx_1973 <- which(df_clean$year == 1973)
if (length(idx_1973) == 0) stop("1973 pinch year not found!")

y_1973 <- y_agg[idx_1973]
k_1973 <- k_t[idx_1973]

# y_t^p = y_1973 + theta_t * (k_t - k_1973)
df_clean$y_p <- y_1973 + df_clean$theta_t * (k_t - k_1973)

# mu_t = exp(y_t - y_p_t) * 100
df_clean$mu_t <- exp(y_agg - df_clean$y_p) * 100

# 5. Dual-Axis Transformation
# Primary Y (mu_t): approx range 70 to 110 (or whatever min/max is)
# Secondary Y (theta_t): approx range 0.40 to 0.65
mu_min <- floor(min(df_clean$mu_t, na.rm = TRUE) / 5) * 5
mu_max <- ceiling(max(df_clean$mu_t, na.rm = TRUE) / 5) * 5
th_min <- min(df_clean$theta_t, na.rm = TRUE)
th_max <- max(df_clean$theta_t, na.rm = TRUE)

# Expand margins slightly for cleaner visual
mu_min <- min(75, mu_min)
mu_max <- max(105, mu_max)
# Let theta vary gracefully
th_margin <- (th_max - th_min) * 0.1
th_min <- th_min - th_margin
th_max <- th_max + th_margin

scale_factor <- (mu_max - mu_min) / (th_max - th_min)
shift_factor <- mu_min - scale_factor * th_min

# Transform secondary series to primary scale
df_clean$theta_scaled <- df_clean$theta_t * scale_factor + shift_factor

# 6. Plot Theme
theme_dual_axis <- function() {
  theme_classic(base_size = 13) %+replace%
    theme(
      panel.background = element_blank(),
      plot.background  = element_blank(),
      
      axis.line.x       = element_line(color = "black", linewidth = 1.0),
      axis.line.y.left  = element_line(color = "#1A2530", linewidth = 1.0),
      axis.line.y.right = element_line(color = "#C0392B", linewidth = 1.0),
      
      axis.ticks.x      = element_line(linewidth = 1.0),
      axis.ticks.y.left = element_line(color = "#1A2530", linewidth = 1.0),
      axis.ticks.y.right= element_line(color = "#C0392B", linewidth = 1.0),
      axis.ticks.length = unit(0.24, "cm"),
      
      axis.text.x       = element_text(color = "black"),
      axis.text.y.left  = element_text(color = "#1A2530", face = "bold"),
      axis.text.y.right = element_text(color = "#C0392B", face = "bold"),
      
      axis.title.x       = element_text(margin = margin(t = 10), color = "black"),
      axis.title.y.left  = element_text(color = "#1A2530", face = "bold", margin = margin(r = 10)),
      axis.title.y.right = element_text(color = "#C0392B", face = "bold", angle = 90, margin = margin(l = 10)),
      
      legend.position   = "bottom",
      legend.direction  = "horizontal",
      legend.title      = element_blank(),
      legend.background = element_blank(),
      legend.key        = element_blank(),
      legend.key.width  = unit(1.2, "cm")
    )
}

# Date formatting for ggplot (Year as Date)
df_clean$Date <- as.Date(paste0(df_clean$year, "-01-01"))

# Shading Data (Harmonized Post-Fordism 1974-2009 & Monopoly Capital 2010-2024)
shade_df <- data.frame(
  xmin = as.Date(c("1939-01-01", "1947-01-01", "1968-01-01", "1974-01-01", "2010-01-01")),
  xmax = as.Date(c("1945-12-31", "1967-12-31", "1973-12-31", "2009-12-31", "2024-12-31")),
  fill_color = c("#CBD5E1", "#D1FAE5", "#FEE2E2", "#FEF3C7", "#E0E7FF"),
  alpha_val = c(0.50, 0.55, 0.60, 0.50, 0.50)
)

anno_df <- data.frame(
  x = as.Date(c("1942-01-01", "1957-01-01", "1971-01-01", "1992-01-01", "2017-06-01")),
  y = rep(mu_max - 2, 5),
  label = c(
    "War Mobilization\n(1939–1945)",
    "Atlantic Fordism\n(1947–1967)",
    "Profit Squeeze\n(1968–1973)",
    "Post-Fordism &\nFinancialization\n(1974–2009)",
    "Intellectual Monopoly\nCapital (2010–2024)"
  ),
  size = rep(3.8, 5)
)

p <- ggplot(df_clean, aes(x = Date)) +
  # Background Shading
  geom_rect(data = shade_df, inherit.aes = FALSE,
            aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill_color, alpha = alpha_val)) +
  scale_fill_identity() +
  scale_alpha_identity() +
  
  # Vertical boundary lines
  geom_vline(xintercept = as.Date(c("1947-01-01", "1968-01-01", "1974-01-01", "2010-01-01")), color = "gray50", linetype = "dotted", linewidth = 0.5) +

  # Top-anchored regime label banners (Enlarged size = 3.8 bold)
  geom_text(data = anno_df, aes(x = x, y = y, label = label, size = size), inherit.aes = FALSE, 
            vjust = 1, lineheight = 0.9, color = "black", fontface = "bold") +
  scale_size_identity() +
  # Reference line for 1973 pinch year
  geom_hline(yintercept = 100, linetype = "dashed", color = "gray40", linewidth = 0.6) +
  # Primary Series: Capacity Utilization (Left)
  geom_line(aes(y = mu_t, color = "Implicit Capacity Utilization"), linewidth = 1.1) +
  # Secondary Series: Theta (Right)
  geom_line(aes(y = theta_scaled, color = "Transformation Elasticity"), linewidth = 1.1, linetype = "dashed") +
  # Colors
  scale_color_manual(values = c(
    "Implicit Capacity Utilization" = "#1A2530",
    "Transformation Elasticity" = "#C0392B"
  )) +
  # Dual Y-Axis
  scale_y_continuous(
    name = expression(paste("Implicit Capacity Utilization ", mu[t], " (%)")),
    limits = c(mu_min, mu_max),
    sec.axis = sec_axis(
      transform = ~ (. - shift_factor) / scale_factor,
      name = expression(paste("Transformation Elasticity ", theta[t]))
    )
  ) +
  scale_x_date(
    date_breaks = "10 years",
    date_labels = "%Y",
    expand = c(0.01, 0)
  ) +
  labs(x = "Year") +
  theme_dual_axis()

# 7. Output files across directories
fig_dir   <- file.path(repo_root, "chapter2_paper", "Chapter2_3.0", "figures")
fig_vault <- file.path(repo_root, "chapter2_vault", "06_paper_facing", "figures")

for (d in c(out_dir, fig_dir, fig_vault)) {
  dir.create(d, recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path(d, "fig_us_specA_dual_theta_mu.pdf"), plot = p, width = 9.5, height = 5.2, device = cairo_pdf)
  ggsave(file.path(d, "fig_us_specA_dual_theta_mu.png"), plot = p, width = 9.5, height = 5.2, dpi = 300, type = "cairo")
}

cat(sprintf("Harmonized Spec A dual plot saved to: %s as fig_us_specA_dual_theta_mu.pdf\n", fig_dir))
