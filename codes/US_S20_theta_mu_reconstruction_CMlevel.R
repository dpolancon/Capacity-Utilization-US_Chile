#!/usr/bin/env Rscript

# US_S20_theta_mu_reconstruction_CMlevel.R
#
# Plots:
#   1. theta_t = theta0 + theta1 * omega_NFC_GVA  over time,
#      using split-sample CMlevel coefficients from S19:
#        Fordism (1929-1973):  theta0 = 0.557, theta1 = -4.553
#        Post-Fordism (1974-2024): theta0 = 7.348, theta1 = 143.296
#
#   2. Capacity utilization mu_t = Y_t / Y^p_t reconstructed from
#        g_Y^p_t = theta_t * g_K_t,
#        pin year 1973: mu_1973 = 1  => Y^p_1973 = Y_1973,
#        backward uses Fordism theta, forward uses Post-Fordism theta.
#
# Y is aggregate real GDP from FRED (GDPCA / GDP_real in S15C2 panel),
# K is aggregate capital stock K_cap from gpim_baseline_components_long.csv.
# omega is the NFC GVA wage share used in the CMlevel IM-OLS regression.
#
# Exports dual-format PNG and PDF to:
#   output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/

library(ggplot2)
library(dplyr)
library(readr)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(repo_root, "output", "US",
                        "S19_FINAL_DEMAND_CONTROLS_SPECA", "figs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ── CMlevel split-sample coefficients (from S19 results) ────────────────────────
coef_F <- list(theta0 = 0.5570985, theta1 = -4.552577)     # Fordism 1929-1973
coef_P <- list(theta0 = 7.3476891, theta1 = 143.295866)      # Post-Fordism 1974-2024
pin_year <- 1973
mu_pin   <- 1.0

# ── Load data ─────────────────────────────────────────────────────────────────
df <- read.csv(file.path(repo_root, "output", "gpim_baseline_components_long.csv"),
               stringsAsFactors = FALSE)
df <- df[df$country == "US", c("year", "K_cap", "omega_NFC_GVA")]
df <- df[!is.na(df$K_cap) & !is.na(df$omega_NFC_GVA), ]

# Aggregate real GDP from S15C2 FRED panel
gdp <- read.csv(file.path(repo_root, "output", "US",
                           "S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION",
                           "csv", "fred_annual_ad_components_panel.csv"),
                stringsAsFactors = FALSE)[, c("year", "GDP_real")]

df <- merge(df, gdp, by = "year", all.x = TRUE)
df <- df[!is.na(df$GDP_real), ]
df <- df[order(df$year), ]

# ── Build theta_t piecewise ───────────────────────────────────────────────────
df <- df %>%
  mutate(
    regime = ifelse(year <= pin_year, "F", "P"),
    theta  = ifelse(regime == "F",
                    coef_F$theta0 + coef_F$theta1 * omega_NFC_GVA,
                    coef_P$theta0 + coef_P$theta1 * omega_NFC_GVA)
  )

# ── Reconstruct potential output and utilization ────────────────────────────
N       <- nrow(df)
k_log   <- log(df$K_cap)
dk      <- c(NA, diff(k_log))
Y       <- df$GDP_real
i_pin   <- which(df$year == pin_year)

y_p_log <- numeric(N)
y_p_log[i_pin] <- log(Y[i_pin] / mu_pin)

# Forward from 1973 using Post-Fordism theta
for (t in (i_pin + 1):N) {
  y_p_log[t] <- y_p_log[t - 1] + df$theta[t] * dk[t]
}

# Backward from 1973 using Fordism theta
for (t in (i_pin - 1):1) {
  y_p_log[t] <- y_p_log[t + 1] - df$theta[t + 1] * dk[t + 1]
}

df$Y_p  <- exp(y_p_log)
df$mu   <- Y / df$Y_p

# ── Theme utility ─────────────────────────────────────────────────────────────
dual_save <- function(plot, name, w = 10, h = 6, dpi = 300) {
  png_path <- file.path(out_dir, paste0(name, ".png"))
  pdf_path <- file.path(out_dir, paste0(name, ".pdf"))
  ggsave(png_path, plot = plot, width = w, height = h, dpi = dpi)
  tryCatch(
    ggsave(pdf_path, plot = plot, width = w, height = h, device = cairo_pdf),
    error = function(e) ggsave(pdf_path, plot = plot, width = w, height = h, device = pdf)
  )
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}

theme_pub <- theme_minimal(base_size = 12) +
  theme(
    panel.grid.minor  = element_blank(),
    panel.grid.major  = element_line(color = "grey93", linewidth = 0.4),
    legend.position   = "bottom",
    plot.caption      = element_text(size = 7, color = "grey50"),
    axis.title        = element_text(size = 11),
    plot.margin       = margin(10, 15, 10, 10)
  )

# ── Plot 1: theta_t path over time ────────────────────────────────────────────
# Drop the first observation because dk is NA (not used, but avoids confusion)
regime_labs <- c(F = "Fordism (1929-1973)", P = "Post-Fordism (1974-2024)")

caption_theta <- paste0(
  "theta_t = theta0 + theta1*omega_t  |  ",
  "Fordism theta0=0.557, theta1=-4.553  |  ",
  "Post-Fordism theta0=7.348, theta1=143.296  |  ",
  "Source: S19 CMlevel IM-OLS specification with (c-m) control"
)

p_theta <- ggplot(df, aes(x = year, y = theta, color = regime)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.6, alpha = 0.7) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "firebrick", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey70", linewidth = 0.3) +
  geom_vline(xintercept = pin_year, linetype = "dotted", color = "grey50") +
  scale_color_manual(values = c(F = "steelblue", P = "darkorange"),
                     labels = regime_labs) +
  labs(
    x = NULL,
    y = expression(theta[t] == theta[0] + theta[1] * omega[t]),
    color = NULL,
    caption = caption_theta
  ) +
  theme_pub

dual_save(p_theta, "S20_theta_path_CMlevel", w = 11, h = 6)

# ── Plot 2: capacity utilization mu_t ─────────────────────────────────────────
caption_mu <- paste0(
  "Capacity utilization: mu_t = Y_t / Y^p_t  |  ",
  "pin: mu_{1973}=1  |  g(Y^p_t) = theta_t * g(K_t)  |  ",
  "Y = GDPCA (real GDP), K = aggregate capital stock K_cap"
)

p_mu <- ggplot(df, aes(x = year, y = mu, color = regime)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.6, alpha = 0.7) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = pin_year, linetype = "dotted", color = "grey50") +
  scale_color_manual(values = c(F = "steelblue", P = "darkorange"),
                     labels = regime_labs) +
  labs(
    x = NULL,
    y = expression(mu[t] == Y[t] / Y[t]^{p}),
    color = NULL,
    caption = caption_mu
  ) +
  theme_pub

dual_save(p_mu, "S20_mu_capacity_utilization_CMlevel", w = 11, h = 6)

# ── Save reconstruction table for inspection ──────────────────────────────────
csv_out <- file.path(repo_root, "output", "US",
                      "S19_FINAL_DEMAND_CONTROLS_SPECA", "csv",
                      "s20_theta_mu_reconstruction_CMlevel.csv")
dir.create(dirname(csv_out), recursive = TRUE, showWarnings = FALSE)
write.csv(df[, c("year", "GDP_real", "K_cap", "omega_NFC_GVA",
                  "regime", "theta", "Y_p", "mu")], csv_out, row.names = FALSE)
cat("Saved reconstruction CSV:", csv_out, "\n")

omega_pin <- df$omega_NFC_GVA[i_pin]
theta_1973_F <- coef_F$theta0 + coef_F$theta1 * omega_pin
theta_1973_P <- coef_P$theta0 + coef_P$theta1 * omega_pin
cat(sprintf("\nPin year: %d  mu_pin=%.2f  Y_1973=%.0f\n",
            pin_year, mu_pin, Y[i_pin]))
cat(sprintf("theta_1973 (Fordism coeff) = %.2f\n", theta_1973_F))
cat(sprintf("theta_1973 (Post-Fordism coeff) = %.2f\n", theta_1973_P))
cat(sprintf("mu range: [%.4f, %.4f]\n", min(df$mu, na.rm = TRUE), max(df$mu, na.rm = TRUE)))
cat("Plot directory:", out_dir, "\n")
