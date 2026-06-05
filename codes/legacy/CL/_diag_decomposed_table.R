library(readr); library(dplyr)

df_b <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/stage_b/Chile/csv/stageB_CL_panel_1940_1978.csv",
                 show_col_types = FALSE)

subperiods <- list(
  "Pre-ISI/WWII  (1940-1945)" = c(1940, 1945),
  "Early ISI     (1946-1953)" = c(1946, 1953),
  "Mid ISI       (1954-1961)" = c(1954, 1961),
  "Late ISI      (1962-1972)" = c(1962, 1972),
  "Crisis        (1973-1978)" = c(1973, 1978)
)

# Decompose sub-period changes in ln(r) between adjacent periods
cat("=== Sub-Period Decomposition of Profit Rate Changes ===\n\n")
cat(sprintf("%-30s %7s %7s %7s %7s %7s\n",
    "Transition", "d_ln_r", "d_ln_mu", "d_ln_B", "d_ln_pi", "check"))
cat(strrep("-", 72), "\n")

sp_names <- names(subperiods)
for (i in 1:length(sp_names)) {
  yr <- subperiods[[sp_names[i]]]
  idx <- df_b$year >= yr[1] & df_b$year <= yr[2]

  if (i == 1) {
    # First row: show levels only
    cat(sprintf("%-30s %7s  mu=%.3f  B=%.3f  pi=%.3f  r=%.4f\n",
        sp_names[i], "[base]",
        mean(df_b$mu_CL[idx]), mean(df_b$B_t[idx]),
        mean(df_b$pi_t[idx]), mean(df_b$r_t[idx])))
  } else {
    yr_prev <- subperiods[[sp_names[i-1]]]
    idx_prev <- df_b$year >= yr_prev[1] & df_b$year <= yr_prev[2]

    d_ln_r  <- log(mean(df_b$r_t[idx]))   - log(mean(df_b$r_t[idx_prev]))
    d_ln_mu <- log(mean(df_b$mu_CL[idx])) - log(mean(df_b$mu_CL[idx_prev]))
    d_ln_B  <- log(mean(df_b$B_t[idx]))   - log(mean(df_b$B_t[idx_prev]))
    d_ln_pi <- log(mean(df_b$pi_t[idx]))  - log(mean(df_b$pi_t[idx_prev]))
    check   <- d_ln_mu + d_ln_B + d_ln_pi

    cat(sprintf("%-30s %+7.3f %+7.3f %+7.3f %+7.3f %+7.3f\n",
        paste0("-> ", sp_names[i]),
        d_ln_r, d_ln_mu, d_ln_B, d_ln_pi, check))
  }
}

# Full arc: Pre-ISI to Crisis
cat(strrep("-", 72), "\n")
idx_first <- df_b$year >= 1940 & df_b$year <= 1945
idx_last  <- df_b$year >= 1973 & df_b$year <= 1978
d_ln_r  <- log(mean(df_b$r_t[idx_last]))   - log(mean(df_b$r_t[idx_first]))
d_ln_mu <- log(mean(df_b$mu_CL[idx_last])) - log(mean(df_b$mu_CL[idx_first]))
d_ln_B  <- log(mean(df_b$B_t[idx_last]))   - log(mean(df_b$B_t[idx_first]))
d_ln_pi <- log(mean(df_b$pi_t[idx_last]))  - log(mean(df_b$pi_t[idx_first]))

cat(sprintf("%-30s %+7.3f %+7.3f %+7.3f %+7.3f %+7.3f\n",
    "FULL ARC (1940-45 -> 1973-78)",
    d_ln_r, d_ln_mu, d_ln_B, d_ln_pi, d_ln_mu + d_ln_B + d_ln_pi))

cat(sprintf("\nShares of full arc:\n"))
cat(sprintf("  mu (demand):       %+.1f%%\n", 100 * d_ln_mu / d_ln_r))
cat(sprintf("  B  (tech+price):   %+.1f%%\n", 100 * d_ln_B  / d_ln_r))
cat(sprintf("  pi (distribution): %+.1f%%\n", 100 * d_ln_pi / d_ln_r))

# Also show period-to-period shares
cat("\n\n=== Period-to-Period Shares (%) ===\n\n")
cat(sprintf("%-30s %8s %8s %8s\n", "Transition", "mu%", "B%", "pi%"))
cat(strrep("-", 60), "\n")

for (i in 2:length(sp_names)) {
  yr <- subperiods[[sp_names[i]]]
  yr_prev <- subperiods[[sp_names[i-1]]]
  idx <- df_b$year >= yr[1] & df_b$year <= yr[2]
  idx_prev <- df_b$year >= yr_prev[1] & df_b$year <= yr_prev[2]

  d_ln_r  <- log(mean(df_b$r_t[idx]))   - log(mean(df_b$r_t[idx_prev]))
  d_ln_mu <- log(mean(df_b$mu_CL[idx])) - log(mean(df_b$mu_CL[idx_prev]))
  d_ln_B  <- log(mean(df_b$B_t[idx]))   - log(mean(df_b$B_t[idx_prev]))
  d_ln_pi <- log(mean(df_b$pi_t[idx]))  - log(mean(df_b$pi_t[idx_prev]))

  cat(sprintf("%-30s %+8.1f %+8.1f %+8.1f\n",
      paste0(sp_names[i-1], " ->"),
      100 * d_ln_mu / d_ln_r,
      100 * d_ln_B  / d_ln_r,
      100 * d_ln_pi / d_ln_r))
}
