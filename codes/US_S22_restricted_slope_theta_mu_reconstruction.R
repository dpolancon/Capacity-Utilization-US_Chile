# US_S22_restricted_slope_theta_mu_reconstruction.R
# ─────────────────────────────────────────────────────────────────────────────
# Diagnostic: impose a common slope in the wage-share dimension at the 1973
# pinch point while letting the intercept (elasticity level) jump across the
# structural break.
#
# Specification:
#   y_t = alpha + beta_k^F * k_t^c
#             + beta_k^P * (k_t^c * Post_t)      # Post-Fordist intercept shift
#             + phi * omega_t^c
#             + theta_1 * (k_t^c * omega_t^c)    # common slope
#             + gamma * Post_t
#             + sum_j delta_j D_jt
#             + psi * tau_t^c + u_t
#
# Centering is on the pinch year 1973 for both regimes, so the two theta(omega)
# functions share the same slope theta_1 at omega_1973 but have different
# intercepts theta_0^F and theta_0^P at that point.
#
# Output:
#   - output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/csv/s22_restricted_slope_theta_mu_reconstruction.csv
#   - output/US/S19_FINAL_DEMAND_CONTROLS_SPECA/figs/S22_*.{png,pdf}
# ─────────────────────────────────────────────────────────────────────────────

library(dplyr)
library(ggplot2)
library(readr)
library(cointReg)

# Paths
repo_root   <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_root    <- file.path(repo_root, "output/US/S19_FINAL_DEMAND_CONTROLS_SPECA")
fig_dir     <- file.path(out_root, "figs")
csv_dir     <- file.path(out_root, "csv")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(csv_dir, showWarnings = FALSE, recursive = TRUE)

# ── helpers ─────────────────────────────────────────────────────────────────
safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  val[1]
}

cv_adf <- function(m) {
  tab <- list(
    `2` = c(p01 = -3.90, p05 = -3.34, p10 = -3.04),
    `3` = c(p01 = -4.29, p05 = -3.74, p10 = -3.45),
    `4` = c(p01 = -4.64, p05 = -4.10, p10 = -3.81),
    `5` = c(p01 = -4.96, p05 = -4.42, p10 = -4.13),
    `6` = c(p01 = -5.25, p05 = -4.72, p10 = -4.43)
  )
  tab[[as.character(min(max(m, 2), 6))]]
}

run_imols <- function(x, y, deter) {
  fit <- cointReg::cointRegIM(x = x, y = y, deter = deter,
                              selector = c(1, 2), t.test = TRUE,
                              kernel = "ba", bandwidth = "nw")
  u <- fit$residuals
  u <- u[!is.na(u)]
  T_obs <- length(u)
  m_i1 <- 1 + ncol(x)

  t_adf <- NA; adf_verdict <- ""
  try({
    eg_lm <- stats::lm(diff(u) ~ u[-T_obs] - 1)
    t_adf <- summary(eg_lm)$coefficients[1, 3]
    cv <- cv_adf(m_i1)
    adf_verdict <- if (t_adf <= cv["p01"]) "coint_1pct" else
                   if (t_adf <= cv["p05"]) "coint_5pct" else
                   if (t_adf <= cv["p10"]) "coint_10pct" else "no_coint"
  }, silent = TRUE)

  C_shin <- NA
  try({
    S_t <- cumsum(u)
    omega2 <- fit$omega.u.v
    if (is.null(omega2) || is.na(omega2) || omega2 <= 0) {
      omega2 <- cointReg::getLongRunVar(u, kernel = "ba", bandwidth = "nw")$long.run
    }
    C_shin <- sum(S_t^2) / (T_obs^2 * omega2)
  }, silent = TRUE)

  Xfull <- if (is.null(deter)) as.matrix(x) else {
    det_cn <- deter[, apply(as.matrix(deter), 2, var, na.rm = TRUE) > 1e-12, drop = FALSE]
    as.matrix(cbind(det_cn, x))
  }
  cn <- tryCatch(kappa(cor(Xfull), exact = TRUE), error = function(e) NA)

  list(fit = fit, t_adf = safe_scalar(t_adf), adf_verdict = adf_verdict,
       C_shin = safe_scalar(C_shin), cond_number = safe_scalar(cn),
       T_obs = T_obs)
}

# ── load data ───────────────────────────────────────────────────────────────
df <- readr::read_csv(file.path(repo_root, "output/gpim_baseline_components_long.csv"),
                      show_col_types = FALSE) |>
  filter(country == "US") |>
  arrange(year)

# Merge the FRED C/M panel used by S19 to build the (c - m) control
cm_csv <- file.path(repo_root, "output/US/S15C_FRED_DEMAND_CONTROL_COINTEGRATION/csv/fred_ad_components_panel.csv")
cm_panel <- readr::read_csv(cm_csv, show_col_types = FALSE) |>
  mutate(c_t = log(C_real), m_t = log(M_real), cm_t = c_t - m_t) |>
  arrange(year) |>
  mutate(cm_lag1 = dplyr::lag(cm_t, 1L))

df <- df |>
  left_join(cm_panel |> select(year, cm_lag1), by = "year")

# Merge real output level used for utilisation reconstruction
gdp <- readr::read_csv(
  file.path(repo_root, "output/US/S15C2_FRED_ANNUAL_DEMAND_CONTROL_COINTEGRATION/csv/fred_annual_ad_components_panel.csv"),
  show_col_types = FALSE)[, c("year", "GDP_real")]
df <- df |>
  left_join(gdp, by = "year")

pin_year <- 1973
i_pin <- which(df$year == pin_year)

# Full window used in the unrestricted CMlevel diagnostics
df <- df |>
  filter(year >= 1929, year <= 2024) |>
  mutate(
    D1933 = ifelse(year >= 1933, 1, 0),
    D1947 = ifelse(year >= 1947, 1, 0),
    D2008 = ifelse(year >= 2008, 1, 0),
    Post   = ifelse(year >= 1974, 1, 0)
  )

# Center all relevant variables on 1973
anchor_var <- function(z) z - z[df$year == pin_year]

df <- df |>
  mutate(
    k_c    = anchor_var(k_cap),
    w_c    = anchor_var(omega_NFC_GVA_lag1),
    kw_c   = k_c * w_c,
    cm_c   = anchor_var(cm_lag1),
    kpost  = k_c * Post
  )

valid <- complete.cases(df$y_t, df$k_c, df$w_c, df$kw_c, df$kpost, df$cm_lag1)
df <- df[valid, ]

y   <- df$y_t
x   <- as.matrix(cbind(k_c = df$k_c, kpost = df$kpost,
                       omega = df$w_c, k_x_omega = df$kw_c))
deter <- as.matrix(cbind(Intercept = 1,
                         D1933 = df$D1933,
                         D1947 = df$D1947,
                         D2008 = df$D2008,
                         Post  = df$Post,
                         cm_lag1 = df$cm_c))
# keep only non-constant deterministic columns
keep <- apply(deter, 2, function(z) length(unique(z)) > 1)
deter <- deter[, keep, drop = FALSE]

# re-establish pinch row index on the filtered data frame
i_pin <- which(df$year == pin_year)

# ── estimate restricted-slope model ─────────────────────────────────────────
res <- run_imols(x, y, deter)
fit <- res$fit

extract <- function(nm) {
  idx <- match(nm, names(fit$theta))
  if (!is.finite(idx)) return(c(coef = NA_real_, t = NA_real_, se = NA_real_))
  c(coef = as.numeric(fit$theta[idx]),
    t    = as.numeric(fit$t.theta[idx]),
    se   = as.numeric(fit$sd.theta[idx]))
}

c_kf  <- extract("S.k_c")       # common Ford intercept at 1973
c_kp  <- extract("S.kpost")     # Post intercept shift at 1973
c_phi <- extract("S.omega")
c_kw  <- extract("S.k_x_omega") # common slope theta_1
c_cm  <- extract("S.cm_lag1")

theta0_Ford <- c_kf["coef"]
theta0_Post <- c_kf["coef"] + c_kp["coef"]
theta1      <- c_kw["coef"]

omega1973 <- df$omega_NFC_GVA_lag1[df$year == pin_year]

# ── reconstruct theta_t and mu_t ────────────────────────────────────────────
df <- df |>
  mutate(
    omega_dev = omega_NFC_GVA_lag1 - omega1973,
    theta = case_when(
      year <= pin_year ~ theta0_Ford + theta1 * omega_dev,
      year >  pin_year ~ theta0_Post + theta1 * omega_dev
    )
  )

Y <- df$GDP_real
K <- df$K_cap
g_K <- df$g_Kcap

Yp <- rep(NA_real_, nrow(df))
Yp[i_pin] <- Y[i_pin]

# Backward accumulation
for (i in (i_pin - 1):1) {
  if (!is.na(df$theta[i])) {
    Yp[i] <- Yp[i + 1] / (1 + df$theta[i] * g_K[i + 1])
  }
}
# Forward accumulation
for (i in (i_pin + 1):length(Yp)) {
  if (!is.na(df$theta[i])) {
    Yp[i] <- Yp[i - 1] * (1 + df$theta[i] * g_K[i])
  }
}

df$mu <- Y / Yp
df$Yp <- Yp

# ── extract unrestricted comparison (CMlevel, split-sample) ───────────────
unres <- readr::read_csv(file.path(csv_dir, "s19_final_demand_controls_specA_results.csv"),
                         show_col_types = FALSE)
unres_ford <- unres |> filter(spec == "CMlevel", window_id == "Long_Fordist_Era_1929_1973")
unres_post <- unres |> filter(spec == "CMlevel", window_id == "Long_Post_Fordist_Era_1974_2024")

theta1_ford <- unres_ford$theta1_kw[1]
theta1_post <- unres_post$theta1_kw[1]
se_ford     <- abs(unres_ford$theta1_kw[1] / unres_ford$t_theta1_kw[1])
se_post     <- abs(unres_post$theta1_kw[1] / unres_post$t_theta1_kw[1])
slope_diff  <- theta1_post - theta1_ford
se_diff     <- sqrt(se_ford^2 + se_post^2)
t_diff      <- slope_diff / se_diff

# ── console summary ─────────────────────────────────────────────────────────
cat(sprintf("Restricted-slope CMlevel model (common theta_1 at 1973)\n"))
cat(sprintf("Common theta_1 = %.4f (t = %.3f)\n", c_kw["coef"], c_kw["t"]))
cat(sprintf("theta_0^Ford at 1973 = %.4f (t = %.3f)\n", theta0_Ford, c_kf["t"]))
cat(sprintf("theta_0^Post at 1973 = %.4f (delta t = %.3f)\n", theta0_Post, c_kp["t"]))
cat(sprintf("Unrestricted theta_1: Ford %.4f (se %.4f), Post %.4f (se %.4f)\n",
            theta1_ford, se_ford, theta1_post, se_post))
cat(sprintf("Slope equality test: diff %.4f, t = %.3f\n", slope_diff, t_diff))
cat(sprintf("Diagnostics: T=%d, ADF=%.3f (%s), C_Shin=%.4f, cond=%.1f\n",
            res$T_obs, res$t_adf, res$adf_verdict, res$C_shin, res$cond_number))
cat(sprintf("Theta_t range: [%.4f, %.4f]\n", min(df$theta, na.rm = TRUE), max(df$theta, na.rm = TRUE)))
cat(sprintf("Mu_t range: [%.6f, %.6f]\n", min(df$mu, na.rm = TRUE), max(df$mu, na.rm = TRUE)))

# ── save CSV ────────────────────────────────────────────────────────────────
out_df <- df |>
  select(year, GDP_real, K_cap, omega_NFC_GVA_lag1, omega_dev, theta, Yp, mu) |>
  mutate(model = "restricted_slope_cmlevel", .before = 1)
readr::write_csv(out_df, file.path(csv_dir, "s22_restricted_slope_theta_mu_reconstruction.csv"))

# ── plots ───────────────────────────────────────────────────────────────────
theme_set <- function() {
  theme_bw(base_size = 12) +
    theme(panel.grid = element_blank(),
          plot.caption = element_text(size = 9, hjust = 0))
}

caption_theta <- paste0(
  "Restricted common slope at 1973: theta_1 = ", round(theta1, 3),
  ", theta_0^Ford(1973) = ", round(theta0_Ford, 3),
  ", theta_0^Post(1973) = ", round(theta0_Post, 3)
)

p_theta <- ggplot(df, aes(x = year, y = theta)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "firebrick") +
  geom_line(color = "steelblue", linewidth = 1) +
  labs(x = "Year", y = expression(theta[t]),
       title = expression(paste(theta[t], " path under common-slope restriction")),
       caption = caption_theta) +
  theme_set()

caption_mu <- sprintf("Pinch: mu_1973 = 1 | restricted theta_t range [%.3f, %.3f] | mu_t range [%.5f, %.3f]",
                      min(df$theta, na.rm = TRUE), max(df$theta, na.rm = TRUE),
                      min(df$mu, na.rm = TRUE), max(df$mu, na.rm = TRUE))

p_mu <- ggplot(df, aes(x = year, y = mu)) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "firebrick") +
  geom_line(color = "darkgreen", linewidth = 1) +
  labs(x = "Year", y = expression(mu[t]),
       title = expression(paste("Reconstructed capacity utilization under common-slope restriction")),
       caption = caption_mu) +
  theme_set()

ggsave(file.path(fig_dir, "S22_theta_path_CMlevel_restricted_slope.png"), p_theta, width = 11, height = 6, dpi = 150)
ggsave(file.path(fig_dir, "S22_theta_path_CMlevel_restricted_slope.pdf"), p_theta, width = 11, height = 6)
ggsave(file.path(fig_dir, "S22_mu_capacity_utilization_CMlevel_restricted_slope.png"), p_mu, width = 11, height = 6, dpi = 150)
ggsave(file.path(fig_dir, "S22_mu_capacity_utilization_CMlevel_restricted_slope.pdf"), p_mu, width = 11, height = 6)

cat(sprintf("\nSaved: %s\n", fig_dir))
