###############################################################################
# US — Advanced Regression Analysis (1940–1978)
# Block V: ARDL (AIC/BIC) + Bounds Test · VECM (rank selection) · DOLS
#
# Strategy: run in isolated stages to avoid package conflicts (MASS vs dplyr)
###############################################################################

# ── 0. Working paths ────────────────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
data_dir  <- file.path(proj_root, "data/processed/US")
out_dir   <- file.path(proj_root, "output/results_package_us")
tab_dir   <- file.path(out_dir, "tables")

# ============================================================================
# STAGE 1: Build the analysis dataset (base R only — no package conflicts)
# ============================================================================

mu_theta_file <- list.files(
  data_dir, pattern = "us_mu_theta_path_spec.*\\.csv$", full.names = TRUE
)
mt <- read.csv(mu_theta_file)
bc <- read.csv(file.path(data_dir, "us_nf_corporate_stageBC.csv"))

# Merge on year, restrict 1940–1978
mt <- mt[mt$year >= 1940 & mt$year <= 1978, ]
bc <- bc[bc$year >= 1940 & bc$year <= 1978, ]
d <- merge(mt, bc[, c("year", "KGR", "KNR", "KGC", "KNC", "Py", "pK", "IGC")],
           by = "year", all = TRUE)
d <- d[order(d$year), ]

# Construct variables
d$p_t       <- d$Py / d$pK
d$B_nG_t    <- d$Yp_hat / d$KGC
d$nu_t      <- d$KGC / d$KNC
d$r_t       <- (1 - d$omega_t) * d$mu_t * d$p_t * d$B_nG_t * d$nu_t
d$ln_r_t    <- log(d$r_t)
d$GD_t      <- 1 - d$mu_t
d$SO_t      <- d$mu_t * (1 - d$omega_t)
d$ND_t      <- d$GD_t - d$SO_t
d$RR_t      <- ifelse(d$SO_t > 0, d$ND_t / d$SO_t, NA)
d$gY_t      <- c(NA, diff(log(d$Y_real)))

# Time-series sample: drop first NA row
d_ts <- d[!is.na(d$gY_t), ]
n_obs <- nrow(d_ts)

cat("Time-series sample:", n_obs, "observations (",
    min(d_ts$year), "–", max(d_ts$year), ")\n")

# Check for any remaining NAs
for (v in c("gY_t", "ln_r_t", "RR_t", "GD_t")) {
  cat(sprintf("  %s: %d NAs\n", v, sum(is.na(d_ts[[v]]))))
}

# Save clean dataset for subsequent stages
saveRDS(d_ts, file = file.path(out_dir, "d_ts_regression.rds"))

cat("\n=== STAGE 1 COMPLETE: Data prepared ===\n")
