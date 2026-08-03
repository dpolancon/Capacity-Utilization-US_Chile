#!/usr/bin/env Rscript

# US_S21_path_dependent_theta_mu_reconstruction.R
#
# Corrected reconstruction of theta_t and capacity utilization using the
# path-dependent intercept interpretation of the split-sample CMlevel
# IM-OLS coefficients.
#
# Key point: In Regime B initial-state centering, theta0 is the elasticity
# evaluated at the initial wage share of the sample. Therefore the
# time-varying elasticity must be computed using the _deviation_ of the wage
# share from that initial observation:
#
#   theta_t = theta0 + theta1 * (omega_t - omega_0^regime)
#
# Coefficients come from S19 CMlevel split-sample IM-OLS results.
#
# Pinch year: 1973 with mu_1973 = 1.
# Backward accumulation uses Fordism theta_t.
# Forward accumulation uses Post-Fordism theta_t.
#
# Exports PNG + PDF plots to
#   output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/

library(ggplot2)
library(dplyr)
library(readr)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir   <- file.path(repo_root, "output", "US",
                        "S19_FINAL_DEMAND_CONTROLS_SPECA", "figs")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ── CMlevel split-sample coefficients from S19 ──────────────────────────────────
coef_F <- list(theta0 = 0.5570985, theta1 = -4.552577)   # Fordism 1929-1973
coef_P <- list(theta0 = 7.3476891, theta1 = 143.295866)   # Post-Fordism 1974-2024
pin_year <- 1973
mu_pin   <- 1.0

# ── Load data ───────────────────────────────────────────────────────────────────
df <- read.csv(file.path(repo_root, "output", "gpim_baseline_components_long.csv"),
               stringsAsFactors = FALSE)
df <- df[df$country == "US", c("year", "K_cap", "omega_NFC_GVA")]
df <- df[!is.na(df$K_cap) & !is.na(df$omega_NFC_GVA), ]

gdp <- read.csv(file.path(repo_root, "output", "US",
                           "S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION",
                           "csv", "fred_annual_ad_components_panel.csv"),
                stringsAsFactors = FALSE)[, c("year", "GDP_real")]

df <- merge(df, gdp, by = "year", all.x = TRUE)
df <- df[!is.na(df$GDP_real), ]
df <- df[order(df$year), ]

# ── Path-dependent theta_t with per-sample initial anchors ────────────────────
#
# Fordism:    omega_0 = first observation of the Fordist window (1929).
# Post-Fordism: omega_0 = pinch year (1973), i.e. the first observation of the
#               regime as measured from the structural break.
#
# Intercepts are the elasticities evaluated at those initial observations.
# Pinch for utilization: mu_1973 = 1 in both directions.

i_1929 <- which(df$year == 1929)
i_1973 <- which(df$year == 1973)

omega0_Ford <- df$omega_NFC_GVA[i_1929]
omega0_Post <- df$omega_NFC_GVA[i_1973]

# Post-Fordism intercept must be relocated from its regression window-start
# (1974) to the 1973 anchor using the invariant theta(omega) relation.
coef_P$theta0 <- coef_P$theta0 + coef_P$theta1 * (omega0_Post - df$omega_NFC_GVA[df$year >= 1974 & df$year <= 2024][1])

df <- df %>%
  mutate(
    regime = case_when(
      year <= pin_year ~ "F",
      year >  pin_year ~ "P"
    ),
    omega_dev = case_when(
      regime == "F" ~ omega_NFC_GVA - omega0_Ford,
      regime == "P" ~ omega_NFC_GVA - omega0_Post
    ),
    theta = case_when(
      regime == "F" ~ coef_F$theta0 + coef_F$theta1 * omega_dev,
      regime == "P" ~ coef_P$theta0 + coef_P$theta1 * omega_dev
    )
  )

# ── Reconstruct potential output and utilization ───────────────────────────────
N     <- nrow(df)
Y     <- df$GDP_real
k_log <- log(df$K_cap)
dk    <- c(NA, diff(k_log))

i_pin <- which(df$year == pin_year)
y_p_log <- numeric(N)
y_p_log[i_pin] <- log(Y[i_pin] / mu_pin)

# Forward: use Post-Fordism theta
theta_vec <- df$theta
for (t in (i_pin + 1):N) {
  y_p_log[t] <- y_p_log[t - 1] + theta_vec[t] * dk[t]
}

# Backward: use Fordism theta
for (t in (i_pin - 1):1) {
  y_p_log[t] <- y_p_log[t + 1] - theta_vec[t + 1] * dk[t + 1]
}

df$Y_p  <- exp(y_p_log)
df$mu   <- Y / df$Y_p

cat(sprintf("Pin year: %d, mu_pin = %.2f, Y_1973 = %.0f\n", pin_year, mu_pin, Y[i_pin]))
cat(sprintf("Ford: omega0 = %.4f (1929), theta0 = %.4f\n", omega0_Ford, coef_F$theta0))
cat(sprintf("Post: omega0 = %.4f (1973), theta0 = %.4f\n", omega0_Post, coef_P$theta0))
cat(sprintf("Post initial deviation at 1974: %.4f\n", df$omega_NFC_GVA[df$year == 1974] - omega0_Post))
cat(sprintf("theta_t range: [%.4f, %.4f]\n", min(df$theta, na.rm = TRUE), max(df$theta, na.rm = TRUE)))
cat(sprintf("mu_t range: [%.6f, %.6f]\n", min(df$mu, na.rm = TRUE), max(df$mu, na.rm = TRUE)))

# ── Plot theme & export utility ───────────────────────────────────────────────
dual_save <- function(plot, name, w = 10, h = 6, dpi = 300) {
  ggsave(file.path(out_dir, paste0(name, ".png")),
         plot = plot, width = w, height = h, dpi = dpi)
  tryCatch(
    ggsave(file.path(out_dir, paste0(name, ".pdf")),
           plot = plot, width = w, height = h, device = cairo_pdf),
    error = function(e) {
      ggsave(file.path(out_dir, paste0(name, ".pdf")),
             plot = plot, width = w, height = h, device = pdf)
    }
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

regime_labs <- c(F = "Fordism (1929-1973)", P = "Post-Fordism (1974-2024)")

caption_theta <- paste0(
  "theta_t = theta_0^regime + theta_1 (omega_t - omega_0^regime)  |  ",
  "Ford: omega_0=", round(omega0_Ford, 3), " (1929), theta_0=", round(coef_F$theta0, 3), ", theta_1=-4.553  |  ",
  "Post: omega_0=", round(omega0_Post, 3), " (1973), theta_0=", round(coef_P$theta0, 3), ", theta_1=143.296"
)

p_theta <- ggplot(df, aes(x = year, y = theta, color = regime)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.6, alpha = 0.7) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "firebrick", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "solid", color = "grey70", linewidth = 0.3) +
  geom_vline(xintercept = pin_year, linetype = "dotted", color = "grey50") +
  scale_color_manual(values = c(F = "steelblue", P = "darkorange"), labels = regime_labs) +
  labs(
    x = NULL,
    y = expression(theta[t]),
    color = NULL,
    caption = caption_theta
  ) +
  theme_pub

dual_save(p_theta, "S21_theta_path_CMlevel_path_dependent", w = 11, h = 6)

caption_mu <- paste0(
  "Capacity utilization: mu_t = Y_t / Y^p_t  |  ",
  "pin: mu_{1973}=1  |  g(Y^p_t) = theta_t * g(K_t)  |  ",
  "Y = GDPCA, K = aggregate capital stock K_cap"
)

p_mu <- ggplot(df, aes(x = year, y = mu, color = regime)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.6, alpha = 0.7) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = pin_year, linetype = "dotted", color = "grey50") +
  scale_color_manual(values = c(F = "steelblue", P = "darkorange"), labels = regime_labs) +
  labs(
    x = NULL,
    y = expression(mu[t]),
    color = NULL,
    caption = caption_mu
  ) +
  theme_pub

dual_save(p_mu, "S21_mu_capacity_utilization_CMlevel_path_dependent", w = 11, h = 6)

# ── Save reconstruction table ───────────────────────────────────────────────────
csv_out <- file.path(repo_root, "output", "US",
                      "S19_FINAL_DEMAND_CONTROLS_SPECA", "csv",
                      "s21_path_dependent_theta_mu_reconstruction.csv")
dir.create(dirname(csv_out), recursive = TRUE, showWarnings = FALSE)
write.csv(df[, c("year", "GDP_real", "K_cap", "omega_NFC_GVA",
                  "omega_dev", "regime", "theta", "Y_p", "mu")],
          csv_out, row.names = FALSE)
cat("Saved reconstruction CSV:", csv_out, "\n")
cat("Plot directory:", out_dir, "\n")
