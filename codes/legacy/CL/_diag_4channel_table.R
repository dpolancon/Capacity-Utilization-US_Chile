library(readr); library(dplyr)

df_b <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/stage_b/Chile/csv/stageB_CL_panel_1940_1978.csv",
                 show_col_types = FALSE)

# 4-channel decomposition:
#   r = mu * B_real * p_rel * pi
# where B_real = Y^p / K_real (real capital productivity, no price effect)
#       p_rel  = P_Y / P_K   (relative output-to-capital price)
#
# In logs: ln(r) = ln(mu) + ln(B_real) + ln(p_rel) + ln(pi)
#
# Reconstruct B_real and p_rel from the panel

df_b <- df_b %>%
  mutate(
    y_p_log  = y - log(mu_CL),
    B_real   = exp(y_p_log - k_CL),          # Y^p / K_real (both 2003 CLP)
    ln_B_real = log(B_real),
    ln_p_rel  = log(p_rel),
    ln_mu     = log(mu_CL),
    ln_pi     = log(pi_t),
    ln_r      = log(r_t)
  )

# Verify: ln(r) = ln(mu) + ln(B_real) + ln(p_rel) + ln(pi)
check <- max(abs(df_b$ln_r - (df_b$ln_mu + df_b$ln_B_real + df_b$ln_p_rel + df_b$ln_pi)), na.rm = TRUE)
cat(sprintf("4-channel identity check (max |residual|): %.2e\n\n", check))

subperiods <- list(
  "Pre-ISI/WWII  (1940-1945)" = c(1940, 1945),
  "Early ISI     (1946-1953)" = c(1946, 1953),
  "Mid ISI       (1954-1961)" = c(1954, 1961),
  "Late ISI      (1962-1972)" = c(1962, 1972),
  "Crisis        (1973-1978)" = c(1973, 1978)
)

sp_names <- names(subperiods)

# ── Period-to-period changes (log of period means) ──
cat("=== 4-Channel Sub-Period Decomposition ===\n")
cat("r = mu * B_real * p_rel * pi\n")
cat("d(ln r) = d(ln mu) + d(ln B_real) + d(ln p_rel) + d(ln pi)\n\n")

cat(sprintf("%-25s %7s %8s %9s %8s %8s %7s\n",
    "Transition", "d_ln_r", "d_ln_mu", "d_ln_Brl", "d_ln_p", "d_ln_pi", "check"))
cat(strrep("-", 80), "\n")

results <- list()
for (i in 1:length(sp_names)) {
  yr <- subperiods[[sp_names[i]]]
  idx <- df_b$year >= yr[1] & df_b$year <= yr[2]

  if (i == 1) {
    cat(sprintf("%-25s %7s  mu=%.3f  B_rl=%.3f  p=%.3f  pi=%.3f  r=%.4f\n",
        sp_names[i], "[base]",
        mean(df_b$mu_CL[idx]), mean(df_b$B_real[idx]),
        mean(df_b$p_rel[idx]), mean(df_b$pi_t[idx]),
        mean(df_b$r_t[idx])))
  } else {
    yr_prev <- subperiods[[sp_names[i-1]]]
    idx_prev <- df_b$year >= yr_prev[1] & df_b$year <= yr_prev[2]

    d_ln_r     <- log(mean(df_b$r_t[idx]))     - log(mean(df_b$r_t[idx_prev]))
    d_ln_mu    <- log(mean(df_b$mu_CL[idx]))   - log(mean(df_b$mu_CL[idx_prev]))
    d_ln_Breal <- log(mean(df_b$B_real[idx]))  - log(mean(df_b$B_real[idx_prev]))
    d_ln_prel  <- log(mean(df_b$p_rel[idx]))   - log(mean(df_b$p_rel[idx_prev]))
    d_ln_pi    <- log(mean(df_b$pi_t[idx]))    - log(mean(df_b$pi_t[idx_prev]))
    chk        <- d_ln_mu + d_ln_Breal + d_ln_prel + d_ln_pi

    cat(sprintf("-> %-22s %+7.3f %+8.3f %+9.3f %+8.3f %+8.3f %+7.3f\n",
        sp_names[i], d_ln_r, d_ln_mu, d_ln_Breal, d_ln_prel, d_ln_pi, chk))

    results[[i]] <- list(d_ln_r=d_ln_r, d_ln_mu=d_ln_mu, d_ln_Breal=d_ln_Breal,
                         d_ln_prel=d_ln_prel, d_ln_pi=d_ln_pi)
  }
}

# Full arc
cat(strrep("-", 80), "\n")
idx_first <- df_b$year >= 1940 & df_b$year <= 1945
idx_last  <- df_b$year >= 1973 & df_b$year <= 1978
d_ln_r     <- log(mean(df_b$r_t[idx_last]))     - log(mean(df_b$r_t[idx_first]))
d_ln_mu    <- log(mean(df_b$mu_CL[idx_last]))   - log(mean(df_b$mu_CL[idx_first]))
d_ln_Breal <- log(mean(df_b$B_real[idx_last]))  - log(mean(df_b$B_real[idx_first]))
d_ln_prel  <- log(mean(df_b$p_rel[idx_last]))   - log(mean(df_b$p_rel[idx_first]))
d_ln_pi    <- log(mean(df_b$pi_t[idx_last]))    - log(mean(df_b$pi_t[idx_first]))

cat(sprintf("FULL ARC (Pre-ISI->Crisis) %+7.3f %+8.3f %+9.3f %+8.3f %+8.3f %+7.3f\n",
    d_ln_r, d_ln_mu, d_ln_Breal, d_ln_prel, d_ln_pi,
    d_ln_mu + d_ln_Breal + d_ln_prel + d_ln_pi))

# ── Period-to-period shares ──
cat("\n\n=== Period-to-Period Shares (%) ===\n\n")
cat(sprintf("%-25s %8s %9s %8s %8s\n", "Transition", "mu%", "B_real%", "p_rel%", "pi%"))
cat(strrep("-", 65), "\n")

for (i in 2:length(sp_names)) {
  yr <- subperiods[[sp_names[i]]]
  yr_prev <- subperiods[[sp_names[i-1]]]
  idx <- df_b$year >= yr[1] & df_b$year <= yr[2]
  idx_prev <- df_b$year >= yr_prev[1] & df_b$year <= yr_prev[2]

  d_ln_r     <- log(mean(df_b$r_t[idx]))     - log(mean(df_b$r_t[idx_prev]))
  d_ln_mu    <- log(mean(df_b$mu_CL[idx]))   - log(mean(df_b$mu_CL[idx_prev]))
  d_ln_Breal <- log(mean(df_b$B_real[idx]))  - log(mean(df_b$B_real[idx_prev]))
  d_ln_prel  <- log(mean(df_b$p_rel[idx]))   - log(mean(df_b$p_rel[idx_prev]))
  d_ln_pi    <- log(mean(df_b$pi_t[idx]))    - log(mean(df_b$pi_t[idx_prev]))

  cat(sprintf("%-25s %+8.1f %+9.1f %+8.1f %+8.1f\n",
      paste0(sp_names[i-1], " ->"),
      100 * d_ln_mu / d_ln_r,
      100 * d_ln_Breal / d_ln_r,
      100 * d_ln_prel / d_ln_r,
      100 * d_ln_pi / d_ln_r))
}

cat(strrep("-", 65), "\n")
cat(sprintf("%-25s %+8.1f %+9.1f %+8.1f %+8.1f\n",
    "FULL ARC",
    100 * d_ln_mu / d_ln_r,
    100 * d_ln_Breal / d_ln_r,
    100 * d_ln_prel / d_ln_r,
    100 * d_ln_pi / d_ln_r))

# ── Also show p_rel by period ──
cat("\n\n=== Relative Price p = P_Y/P_K by Period ===\n\n")
for (nm in sp_names) {
  yr <- subperiods[[nm]]
  idx <- df_b$year >= yr[1] & df_b$year <= yr[2]
  cat(sprintf("  %-30s p_rel=%.4f  P_Y=%.6f  P_K=%.6f\n",
      nm, mean(df_b$p_rel[idx]),
      mean(df_b$p_Y[idx]), mean(df_b$P_K[idx])))
}
