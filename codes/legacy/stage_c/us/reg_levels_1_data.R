###############################################################################
# STAGE 1: Data preparation — log Y (level), r (level), RR, GD
# ============================================================================
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
data_dir  <- file.path(proj_root, "data/processed/US")
out_dir   <- file.path(proj_root, "output/results_package_us")

mt_file <- list.files(data_dir, pattern = "us_mu_theta_path_spec.*\\.csv$",
                      full.names = TRUE)
mt <- read.csv(mt_file)
bc <- read.csv(file.path(data_dir, "us_nf_corporate_stageBC.csv"))

mt <- mt[mt$year >= 1940 & mt$year <= 1978, ]
bc <- bc[bc$year >= 1940 & bc$year <= 1978, ]
d <- merge(mt, bc[, c("year", "KGR", "KNR", "KGC", "KNC", "Py", "pK", "IGC")],
           by = "year", all = TRUE)
d <- d[order(d$year), ]

# Construct variables
d$p_t    <- d$Py / d$pK
d$B_nG_t <- d$Yp_hat / d$KGC
d$nu_t   <- d$KGC / d$KNC
d$r_t    <- (1 - d$omega_t) * d$mu_t * d$p_t * d$B_nG_t * d$nu_t
d$log_Y  <- log(d$Y_real)
d$GD_t   <- 1 - d$mu_t
d$SO_t   <- d$mu_t * (1 - d$omega_t)
d$ND_t   <- d$GD_t - d$SO_t
d$RR_t   <- ifelse(d$SO_t > 0, d$ND_t / d$SO_t, NA)

# Full sample for levels analysis
d_ts <- d[!is.na(d$r_t) & !is.na(d$RR_t) & !is.na(d$GD_t) & !is.na(d$log_Y), ]
d_ts <- d_ts[order(d_ts$year), ]
n_obs <- nrow(d_ts)

cat("Time-series sample:", n_obs, "observations (",
    min(d_ts$year), "–", max(d_ts$year), ")\n")
for (v in c("log_Y", "r_t", "RR_t", "GD_t")) {
  rng <- range(d_ts[[v]], na.rm = TRUE)
  cat(sprintf("  %s: %d NAs, range [%.4f, %.4f]\n", v,
              sum(is.na(d_ts[[v]])), rng[1], rng[2]))
}

saveRDS(d_ts, file = file.path(out_dir, "d_ts_levels.rds"))
cat("\n=== STAGE 1 COMPLETE ===\n")
