# 35_theta_omega_plot_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# theta(omega) plane analysis — cost-minimizing elasticity at realized omega
#
# Specification: unrestricted Johansen beta (r=3) with short-run restrictions
# only:  alpha[omega_k,.]=0, Gamma[omega_k,.]=0, Gamma[.,omega_k]=0
#
# CV1 (y-normalized):
#   y = alpha1*k + gamma*omega + alpha2*(omega*k) + c1
#   theta(omega) = alpha1 + alpha2*omega  [cost-minimizing elasticity]
#
# Each year's realized omega_t is evaluated through the structural function
# to obtain its cost-minimizing theta(omega_t). The scatter in the
# (omega, theta) plane lies ON the function by construction.
#
# Capacity utilization in levels:
#   mu_t = Y_t / K_t^{theta(omega_t)}
# ═══════════════════════════════════════════════════════════════════════════════

library(tidyverse)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

fig_dir <- file.path(REPO, "output/stage_a/us/figs")
csv_dir <- file.path(REPO, "output/stage_a/us/csv")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

dual_save <- function(plot, name, w = 8, h = 5.5, dpi = 300) {
  ggsave(file.path(fig_dir, paste0(name, ".png")),
         plot = plot, width = w, height = h, dpi = dpi)
  ggsave(file.path(fig_dir, paste0(name, ".pdf")),
         plot = plot, width = w, height = h, device = cairo_pdf)
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}


# ── Parameters from unrestricted CV1 (y-normalized, script 37/39) ────────────
# CV1 beta: (y=1, k=-8.9238, omega=-222.1611, omega_k=12.8509, const=138.2544)
alpha1  <-   8.9238
alpha2  <- -12.8509
gamma_w <- 222.1611   # direct omega coefficient in CV1
c1      <- -138.2544  # constant in CV1

omega_H    <- (1 - alpha1) / alpha2    # knife-edge: theta = 1
omega_star <- -alpha1 / alpha2          # crisis boundary: theta = 0

cat(sprintf("alpha1     = %.4f\n", alpha1))
cat(sprintf("alpha2     = %.4f\n", alpha2))
cat(sprintf("gamma_w    = %.4f\n", gamma_w))
cat(sprintf("c1         = %.4f\n", c1))
cat(sprintf("omega_H    = %.4f  (theta=1)\n", omega_H))
cat(sprintf("omega*     = %.4f  (theta=0)\n", omega_star))


# ── Load data ────────────────────────────────────────────────────────────────
nf  <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
nf  <- merge(nf, inc[, c("year", "Py_fred")], by = "year")
nf  <- nf[order(nf$year), ]

P <- nf$Py_fred[nf$year == 2024]

# Real levels in 2024 prices
nf$Y_real <- nf$GVA_NF / (nf$Py_fred / P)
nf$K_real <- nf$KGC_NF / (nf$Py_fred / P)
nf$omega  <- nf$Wsh_NF

cat(sprintf("Sample: %d-%d (%d obs)\n", min(nf$year), max(nf$year), nrow(nf)))


# ═══════════════════════════════════════════════════════════════════════════════
# 1. BUILD TIBBLE
# ═══════════════════════════════════════════════════════════════════════════════

# ── Build frontier via growth-rate closure ────────────────────────────────────
# Pin: mu_1948 = 0.8 (Federal Reserve capacity utilization benchmark)
# => Y^p_1948 = Y_1948 / 0.8
# Then accumulate forward and backward: g_Y^p_t = theta_t * g_K_t

mu_pin   <- 0.8
year_pin <- 1948

N     <- nrow(nf)
Y     <- nf$Y_real
K     <- nf$K_real
omega <- nf$omega
theta <- alpha1 + alpha2 * omega

k     <- log(K)
dk    <- c(NA, diff(k))

# Pin index
i_pin <- which(nf$year == year_pin)
y_star    <- numeric(N)
y_star[i_pin] <- log(Y[i_pin] / mu_pin)

cat(sprintf("\nPin: mu(%d) = %.2f => Y^p_%d = %.0f  (Y_%d = %.0f)\n",
    year_pin, mu_pin, year_pin, exp(y_star[i_pin]), year_pin, Y[i_pin]))

# Forward from pin
for (t in (i_pin + 1):N) {
  y_star[t] <- y_star[t - 1] + theta[t] * dk[t]
}

# Backward from pin
for (t in (i_pin - 1):1) {
  # y_star[t] = y_star[t+1] - theta[t+1]*dk[t+1]
  y_star[t] <- y_star[t + 1] - theta[t + 1] * dk[t + 1]
}

Y_star <- exp(y_star)
mu     <- Y / Y_star

# ── ECT1-based mu: exp(ECT1 - mean(ECT1)) ──────────────────────────────────
# ECT1 = y - alpha1*k - gamma_w*omega - alpha2*omega*k - c1
y   <- log(Y)
ect1 <- y - alpha1*k - gamma_w*omega - alpha2*omega*k - c1
mu_ect <- exp(ect1 - mean(ect1))

cat(sprintf("ECT1: mean=%.4f  sd=%.4f  range=[%.4f, %.4f]\n",
    mean(ect1), sd(ect1), min(ect1), max(ect1)))

theta_tbl <- tibble(
  year    = nf$year,
  Y       = Y,
  K       = K,
  omega   = omega,
  theta   = theta,
  g_K     = c(NA, diff(K) / K[-N]),
  g_Yp    = c(NA, theta[-1] * dk[-1]),
  Y_star  = Y_star,
  mu      = mu,
  mu_ect  = mu_ect,
  period  = case_when(
    year <= 1944 ~ "Pre-Fordist",
    year <= 1973 ~ "Fordist",
    TRUE         ~ "Post-Fordist"
  )
)

# ── Report ───────────────────────────────────────────────────────────────────
omega_range <- range(theta_tbl$omega)
cat(sprintf("\nDomain:  omega in [%.4f, %.4f]\n", omega_range[1], omega_range[2]))
cat(sprintf("Range:   theta in [%.4f, %.4f]\n", min(theta_tbl$theta), max(theta_tbl$theta)))
cat(sprintf("omega_H: %.4f  (theta=1) — %s sample\n",
    omega_H,
    ifelse(omega_H >= omega_range[1] & omega_H <= omega_range[2], "IN", "outside")))
cat(sprintf("omega*:  %.4f  (theta=0) — %s sample\n",
    omega_star,
    ifelse(omega_star >= omega_range[1] & omega_star <= omega_range[2], "IN", "outside")))

cat("\n=== THETA-OMEGA-MU TIBBLE — ALL YEARS ===\n")
cat(sprintf("%-5s %7s %8s %12s %12s %8s\n",
    "year", "omega", "theta", "Y", "Y_star", "mu"))
cat(strrep("-", 62), "\n")
for (i in 1:nrow(theta_tbl)) {
  r <- theta_tbl[i, ]
  cat(sprintf("%4d  %.4f  %7.4f  %10.0f  %10.0f  %7.4f\n",
      r$year, r$omega, r$theta, r$Y, r$Y_star, r$mu))
}

cat("\n--- Summary by period ---\n")
theta_tbl %>%
  group_by(period) %>%
  summarise(
    n          = n(),
    omega_mean = round(mean(omega), 4),
    theta_mean = round(mean(theta), 4),
    mu_mean    = round(mean(mu), 4),
    mu_sd      = round(sd(mu), 4),
    .groups = "drop"
  ) %>% print()

# Save CSV
write_csv(theta_tbl, file.path(csv_dir, "theta_omega_tibble_us.csv"))
cat("\nSaved: theta_omega_tibble_us.csv\n")


# ═══════════════════════════════════════════════════════════════════════════════
# 2. PLOT SETUP
# ═══════════════════════════════════════════════════════════════════════════════

omega_grid <- tibble(
  omega = seq(omega_range[1] - 0.02, omega_star + 0.02, length.out = 500),
  theta = alpha1 + alpha2 * omega
)

period_colors <- c(
  "Pre-Fordist"  = "grey55",
  "Fordist"      = "steelblue",
  "Post-Fordist" = "darkorange"
)

theme_theta <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor  = element_blank(),
    panel.grid.major  = element_line(color = "grey93", linewidth = 0.35),
    legend.position   = "bottom",
    legend.key.size   = unit(0.4, "cm"),
    plot.caption      = element_text(size = 6.5, color = "grey50"),
    axis.title        = element_text(size = 10),
    plot.margin       = margin(10, 20, 10, 10)
  )

caption_text <- paste0(
  "theta(omega) = ", round(alpha1, 3), " + (", round(alpha2, 3), ")*omega",
  "  |  omega_H = ", round(omega_H, 3),
  "  |  omega* = ", round(omega_star, 3),
  "  |  US NF corporate 1929-2024")


# ═══════════════════════════════════════════════════════════════════════════════
# Plot A — theta-omega plane: scatter on the function (every year)
# ═══════════════════════════════════════════════════════════════════════════════

pA <- ggplot() +

  annotate("rect", xmin = -Inf, xmax = omega_H,
           ymin = -Inf, ymax = Inf, fill = "steelblue", alpha = 0.04) +
  annotate("rect", xmin = omega_H, xmax = Inf,
           ymin = -Inf, ymax = Inf, fill = "firebrick", alpha = 0.04) +

  # Structural function
  geom_line(data = omega_grid, aes(x = omega, y = theta),
            color = "grey30", linewidth = 0.7) +

  geom_hline(yintercept = 1, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "solid",
             color = "grey70", linewidth = 0.3) +
  geom_vline(xintercept = omega_H, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = omega_star, linetype = "dotted",
             color = "darkred", linewidth = 0.4) +

  # Scatter: realized omega on the cost-minimizing function
  geom_point(data = theta_tbl,
    aes(x = omega, y = theta, color = period),
    size = 1.8, alpha = 0.85) +

  geom_text(data = theta_tbl,
    aes(x = omega, y = theta, label = year),
    size = 1.9, hjust = -0.12, vjust = 0.3,
    family = "sans", color = "grey25") +

  annotate("text", x = omega_H - 0.003, y = max(omega_grid$theta) * 0.92,
           label = sprintf("omega_H = %.3f", omega_H),
           size = 2.7, color = "firebrick", hjust = 1) +
  annotate("text", x = omega_star + 0.003, y = 0.3,
           label = sprintf("omega* = %.3f", omega_star),
           size = 2.5, color = "darkred", hjust = 0) +

  scale_color_manual(values = period_colors) +
  labs(x = expression(omega[t]),
       y = expression(theta(omega[t])),
       color = NULL, caption = caption_text) +
  theme_theta

dual_save(pA, "theta_omega_scatter_full", w = 12, h = 8)


# ═══════════════════════════════════════════════════════════════════════════════
# Plot B — Publication: selected labels, broad scope
# ═══════════════════════════════════════════════════════════════════════════════

label_years <- c(seq(1930, 2020, by = 10), 1929, 1932, 1941, 1944, 1945,
                 1965, 1973, 1979, 2006, 2009, 2020, 2024) %>%
  unique() %>% sort()
theta_pub <- theta_tbl %>% filter(year %in% label_years)

pB <- ggplot() +

  annotate("rect", xmin = -Inf, xmax = omega_H,
           ymin = -Inf, ymax = Inf, fill = "steelblue", alpha = 0.04) +
  annotate("rect", xmin = omega_H, xmax = Inf,
           ymin = -Inf, ymax = Inf, fill = "firebrick", alpha = 0.04) +

  geom_line(data = omega_grid, aes(x = omega, y = theta),
            color = "grey30", linewidth = 0.7) +

  geom_hline(yintercept = 1, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "solid",
             color = "grey70", linewidth = 0.3) +
  geom_vline(xintercept = omega_H, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = omega_star, linetype = "dotted",
             color = "darkred", linewidth = 0.4) +

  annotate("rect", xmin = omega_range[1], xmax = omega_range[2],
           ymin = -Inf, ymax = Inf, fill = "gold", alpha = 0.08) +

  geom_point(data = theta_tbl,
    aes(x = omega, y = theta, color = period),
    size = 1.8, alpha = 0.85) +

  geom_text(data = theta_pub,
    aes(x = omega, y = theta, label = year),
    size = 2.5, hjust = -0.12, vjust = 0.3,
    family = "sans", color = "grey25") +

  annotate("text", x = omega_H + 0.005, y = max(omega_grid$theta) * 0.85,
           label = sprintf("omega_H = %.3f\n(knife-edge)", omega_H),
           size = 2.7, color = "firebrick", hjust = 0) +
  annotate("text", x = omega_star + 0.005, y = 0.3,
           label = sprintf("omega* = %.3f\n(crisis boundary)", omega_star),
           size = 2.5, color = "darkred", hjust = 0) +

  scale_color_manual(values = period_colors) +
  scale_x_continuous(breaks = seq(0.55, 0.75, by = 0.025)) +
  labs(x = expression(omega[t]),
       y = expression(theta(omega[t])),
       color = NULL, caption = caption_text) +
  theme_theta

dual_save(pB, "theta_omega_plane_us", w = 11, h = 7)


# ═══════════════════════════════════════════════════════════════════════════════
# Plot C — theta(omega_t) over time
# ═══════════════════════════════════════════════════════════════════════════════

pC <- ggplot(theta_tbl, aes(x = year, y = theta)) +
  geom_line(linewidth = 0.7, color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_hline(yintercept = 0, linetype = "solid",
             color = "grey70", linewidth = 0.3) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "grey50") +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = 1, ymax = Inf,
           fill = "steelblue", alpha = 0.04) +
  annotate("rect", xmin = -Inf, xmax = Inf, ymin = -Inf, ymax = 1,
           fill = "firebrick", alpha = 0.04) +
  labs(x = NULL, y = expression(theta(omega[t])),
       caption = caption_text) +
  theme_theta

dual_save(pC, "theta_timeseries", w = 10, h = 5.5)


# ═══════════════════════════════════════════════════════════════════════════════
# Plot D — omega over time
# ═══════════════════════════════════════════════════════════════════════════════

pD <- ggplot(theta_tbl, aes(x = year, y = omega)) +
  geom_line(linewidth = 0.7, color = "steelblue") +
  geom_hline(yintercept = omega_H, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "grey50") +
  annotate("text", x = 2000, y = omega_H + 0.003,
           label = sprintf("omega_H = %.3f (theta = 1)", omega_H),
           size = 2.7, color = "firebrick", hjust = 0.5) +
  labs(x = NULL, y = expression(omega[t]),
       caption = caption_text) +
  theme_theta

dual_save(pD, "omega_timeseries", w = 10, h = 5.5)


# ═══════════════════════════════════════════════════════════════════════════════
# Plot E — Capacity utilization: mu = Y / K^{theta(omega)}
# ═══════════════════════════════════════════════════════════════════════════════

pE <- ggplot(theta_tbl, aes(x = year, y = mu)) +
  geom_line(linewidth = 0.7, color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "grey50") +
  labs(x = NULL, y = expression(mu[t]),
       caption = sprintf("mu(1948) = 0.80 pinned | g(Y*) = theta*g(K) | %s", caption_text)) +
  theme_theta

dual_save(pE, "mu_capacity_utilization", w = 10, h = 5.5)


# ═══════════════════════════════════════════════════════════════════════════════
# Plot F — theta and omega jointly over time (dual axis)
# ═══════════════════════════════════════════════════════════════════════════════

# Rescale omega to theta's range for dual-axis overlay
theta_range <- range(theta_tbl$theta)
omega_rng   <- range(theta_tbl$omega)
rescale_omega <- function(w) {
  theta_range[1] + (w - omega_rng[1]) / diff(omega_rng) * diff(theta_range)
}
inv_rescale <- function(th) {
  omega_rng[1] + (th - theta_range[1]) / diff(theta_range) * diff(omega_rng)
}

pF <- ggplot(theta_tbl, aes(x = year)) +
  geom_line(aes(y = theta), linewidth = 0.7, color = "steelblue") +
  geom_line(aes(y = rescale_omega(omega)), linewidth = 0.7, color = "darkorange") +
  geom_hline(yintercept = 1, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "grey50") +
  scale_y_continuous(
    name = expression(theta(omega[t])),
    sec.axis = sec_axis(~ inv_rescale(.),
                        name = expression(omega[t]))
  ) +
  annotate("text", x = 1935, y = max(theta_tbl$theta) * 0.95,
           label = expression(theta(omega[t])),
           size = 3, color = "steelblue", hjust = 0) +
  annotate("text", x = 1935, y = min(theta_tbl$theta) * 1.2,
           label = expression(omega[t]),
           size = 3, color = "darkorange", hjust = 0) +
  labs(x = NULL, caption = caption_text) +
  theme_theta +
  theme(
    axis.title.y.left  = element_text(color = "steelblue"),
    axis.text.y.left   = element_text(color = "steelblue"),
    axis.title.y.right = element_text(color = "darkorange"),
    axis.text.y.right  = element_text(color = "darkorange")
  )

dual_save(pF, "theta_omega_joint_timeseries", w = 10, h = 5.5)


# ═══════════════════════════════════════════════════════════════════════════════
# Plot G — mu_ect = exp(ECT1 - mean(ECT1))
# ═══════════════════════════════════════════════════════════════════════════════

pG <- ggplot(theta_tbl, aes(x = year, y = mu_ect)) +
  geom_line(linewidth = 0.7, color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed",
             color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "grey50") +
  labs(x = NULL, y = expression(mu[ECT]),
       caption = sprintf("mu_ect = exp(ECT1 - mean(ECT1)) | mean(ECT1) = %.3f | %s",
                         mean(ect1), caption_text)) +
  theme_theta

dual_save(pG, "mu_ect_capacity_utilization", w = 10, h = 5.5)


cat("\nAll plots saved to:", fig_dir, "\n")
