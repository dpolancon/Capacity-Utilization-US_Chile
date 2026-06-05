# 02_US_theta_results_md.R
# Loads US_theta_DOLS_results.rds and writes three .md files:
#   1. US_theta_DOLS_coefficient_table.md
#   2. US_theta_DOLS_summary_stats.md
#   3. US_theta_DOLS_diagnostic_notes.md

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
out_dir <- file.path(REPO, "AR_Corridor/02_country_tracks/united_states/results")
results_dir <- file.path(REPO, "AR_Corridor/04_estimation_outputs/stable_results")
diag_dir    <- file.path(REPO, "AR_Corridor/04_estimation_outputs/diagnostics")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# Load results
rds_path <- file.path(results_dir, "US_theta_DOLS_results.rds")
if (!file.exists(rds_path)) {
  stop(sprintf("[results] RDS not found: %s\n  Run 01_US_theta_DOLS.R first.", rds_path))
}

rd <- readRDS(rds_path)
results  <- rd$results
series   <- rd$series
audit    <- rd$audit
bm_year  <- rd$benchmark_year

cat(sprintf("[results] Loaded: %s\n", rds_path))
cat(sprintf("[results] Benchmark year: %d\n", bm_year))

# ============================================================
# FILE 1: Coefficient table
# ============================================================

coeff_lines <- c(
  "# US θ Identification — DOLS Coefficient Table",
  sprintf("**Estimator:** DOLS, p=2 leads/lags, Newey-West HAC standard errors  "),
  sprintf("**Specification:** y_t = c + β₁·k_t + β₂·(ω_t·k_t) + leads/lags + ε_t  "),
  sprintf("**θ̂_t = β̂₁ + β̂₂·ω_t**  "),
  ""
)

# Build markdown table rows
sample_names <- c("full", "pre1974", "post1973")
col_labels  <- c("Full sample", "Pre-1974 (≤1973)", "Post-1973 (≥1974)")

# Header row
header <- "| Parameter |"
sep    <- "|-----------|"
for (cl in col_labels) {
  header <- paste0(header, sprintf(" %s |", cl))
  sep    <- paste0(sep, "-----------|")
}
coeff_lines <- c(coeff_lines, header, sep)

# β₁ row
row_b1 <- "| β̂₁ (k_t) |"
for (nm in sample_names) {
  r <- results[[nm]]
  row_b1 <- paste0(row_b1, sprintf(" %.4f |", r$beta1))
}
coeff_lines <- c(coeff_lines, row_b1)

# β₁ SE row
row_se1 <- "| (HAC s.e.) |"
for (nm in sample_names) {
  r <- results[[nm]]
  row_se1 <- paste0(row_se1, sprintf(" (%.4f) |", r$beta1_se))
}
coeff_lines <- c(coeff_lines, row_se1)

# β₂ row
row_b2 <- "| β̂₂ (ω_t·k_t) |"
for (nm in sample_names) {
  r <- results[[nm]]
  row_b2 <- paste0(row_b2, sprintf(" %.4f |", r$beta2))
}
coeff_lines <- c(coeff_lines, row_b2)

# β₂ SE row
row_se2 <- "| (HAC s.e.) |"
for (nm in sample_names) {
  r <- results[[nm]]
  row_se2 <- paste0(row_se2, sprintf(" (%.4f) |", r$beta2_se))
}
coeff_lines <- c(coeff_lines, row_se2)

# θ̄ at ω̄ row
row_tb <- "| θ̂ at ω̄ |"
for (nm in sample_names) {
  r <- results[[nm]]
  row_tb <- paste0(row_tb, sprintf(" %.4f |", r$theta_bar))
}
coeff_lines <- c(coeff_lines, row_tb)

# ω̄ row
row_wb <- "| ω̄ (sample mean) |"
for (nm in sample_names) {
  r <- results[[nm]]
  row_wb <- paste0(row_wb, sprintf(" %.4f |", r$w_bar))
}
coeff_lines <- c(coeff_lines, row_wb)

# Harrodian threshold row
row_wH <- "| Harrodian threshold ω_H |"
for (nm in sample_names) {
  r <- results[[nm]]
  val <- ifelse(is.na(r$omega_H), "N/A", sprintf("%.4f", r$omega_H))
  row_wH <- paste0(row_wH, sprintf(" %s |", val))
}
coeff_lines <- c(coeff_lines, row_wH)

# ω_H in sample range? row
row_inr <- "| ω_H in sample range? |"
for (nm in sample_names) {
  r <- results[[nm]]
  if (is.na(r$omega_H)) {
    in_range <- "N/A"
  } else {
    in_range <- ifelse(r$omega_H >= r$omega_min && r$omega_H <= r$omega_max, "YES", "NO")
  }
  row_inr <- paste0(row_inr, sprintf(" %s |", in_range))
}
coeff_lines <- c(coeff_lines, row_inr)

# N row
row_n <- "| N (after trimming) |"
for (nm in sample_names) {
  r <- results[[nm]]
  row_n <- paste0(row_n, sprintf(" %d |", r$nobs))
}
coeff_lines <- c(coeff_lines, row_n)

# R² row
row_r2 <- "| R² |"
for (nm in sample_names) {
  r <- results[[nm]]
  row_r2 <- paste0(row_r2, sprintf(" %.4f |", r$r2))
}
coeff_lines <- c(coeff_lines, row_r2)

# Footer notes
coeff_lines <- c(coeff_lines,
  "",
  "**Note:** Harrodian threshold ω_H = (1 − β̂₁) / (−β̂₂) is the wage share at which θ̂ = 1.  ",
  "If ω_H lies inside the sample range [ω_min, ω_max], the crisis-trigger interpretation is confirmed.  ",
  "Standard errors corrected for heteroskedasticity and autocorrelation (Newey-West, automatic bandwidth)."
)

writeLines(coeff_lines, file.path(out_dir, "US_theta_DOLS_coefficient_table.md"))
cat("[results] Written: US_theta_DOLS_coefficient_table.md\n")

# ============================================================
# FILE 2: Summary statistics
# ============================================================

stats_lines <- c(
  "# US θ and μ — Recovered Series Summary Statistics",
  sprintf("**Benchmark normalization:** μ̂_t normalized to 1.000 at benchmark year %d  ", bm_year),
  "θ̂_t < 1 = over-accumulation regime (productive capacities built slower than capital accumulates).  ",
  "θ̂_t > 1 = sub-Harrodian regime.  ",
  ""
)

for (nm in sample_names) {
  r <- results[[nm]]
  s <- series[[nm]]

  stats_lines <- c(stats_lines,
    sprintf("## %s", r$label),
    ""
  )

  # θ̂_t stats
  th_mean <- mean(s$theta_t, na.rm = TRUE)
  th_sd   <- sd(s$theta_t, na.rm = TRUE)
  th_min  <- min(s$theta_t, na.rm = TRUE)
  th_max  <- max(s$theta_t, na.rm = TRUE)
  th_yr_min <- s$year[which.min(s$theta_t)]
  th_yr_max <- s$year[which.max(s$theta_t)]

  # μ̂_t stats
  mu_mean <- mean(s$mu_hat, na.rm = TRUE)
  mu_sd   <- sd(s$mu_hat, na.rm = TRUE)
  mu_min  <- min(s$mu_hat, na.rm = TRUE)
  mu_max  <- max(s$mu_hat, na.rm = TRUE)
  mu_yr_min <- s$year[which.min(s$mu_hat)]
  mu_yr_max <- s$year[which.max(s$mu_hat)]

  stats_lines <- c(stats_lines,
    "| Statistic | θ̂_t | μ̂_t |",
    "|-----------|------|------|",
    sprintf("| Mean      | %.4f | %.4f |", th_mean, mu_mean),
    sprintf("| Std dev   | %.4f | %.4f |", th_sd, mu_sd),
    sprintf("| Min       | %.4f | %.4f |", th_min, mu_min),
    sprintf("| Max       | %.4f | %.4f |", th_max, mu_max),
    sprintf("| Year of min | %d | %d |", th_yr_min, mu_yr_min),
    sprintf("| Year of max | %d | %d |", th_yr_max, mu_yr_max),
    "", ""
  )
}

writeLines(stats_lines, file.path(out_dir, "US_theta_DOLS_summary_stats.md"))
cat("[results] Written: US_theta_DOLS_summary_stats.md\n")

# ============================================================
# FILE 3: Diagnostic notes
# ============================================================

diag_lines <- c(
  "# US DOLS — Diagnostic Notes",
  sprintf("**Date generated:** %s  ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "**Script:** 01_US_theta_DOLS.R  ",
  "**p (leads/lags):** 2  ",
  ""
)

# Section 1: Data loaded
diag_lines <- c(diag_lines,
  "## 1. Data loaded",
  sprintf("- Source path: %s", audit$file),
  sprintf("- Years in panel: %s – %s", audit$year_min, audit$year_max),
  sprintf("- N total rows: %s", audit$n_obs),
  ""
)

# Section 2: Sample trimming
diag_lines <- c(diag_lines,
  "## 2. Sample trimming (leads/lags)",
  "| Sample | Raw N | After trimming | Years |",
  "|--------|-------|----------------|-------|"
)
for (nm in sample_names) {
  r <- results[[nm]]
  diag_lines <- c(diag_lines,
    sprintf("| %s | %d | %d | %d–%d |",
            r$label, r$n_raw, r$nobs, r$year_min, r$year_max))
}
diag_lines <- c(diag_lines, "")

# Section 3: Sign checks
diag_lines <- c(diag_lines,
  "## 3. Sign checks",
  "| Sample | β̂₂ < 0? | Interpretation |",
  "|--------|----------|----------------|"
)
for (nm in sample_names) {
  r <- results[[nm]]
  sign_ok <- r$beta2 < 0
  interp  <- ifelse(sign_ok, "Consistent with theoretical prior", "INCONSISTENT — theoretical prior requires β̂₂ < 0")
  diag_lines <- c(diag_lines,
    sprintf("| %s | %s | %s |", r$label, ifelse(sign_ok, "YES", "NO"), interp))
}
diag_lines <- c(diag_lines, "", "Theoretical prior: β̂₂ < 0 required (higher wage share reduces transformation elasticity slope).", "")

# Section 4: Harrodian threshold
diag_lines <- c(diag_lines,
  "## 4. Harrodian threshold",
  "| Sample | ω_H | ω̄ | ω_min | ω_max | ω_H in range? |",
  "|--------|-----|-----|-------|-------|---------------|"
)
for (nm in sample_names) {
  r <- results[[nm]]
  wH_str <- ifelse(is.na(r$omega_H), "N/A", sprintf("%.4f", r$omega_H))
  in_range <- ifelse(!is.na(r$omega_H) && r$omega_H >= r$omega_min && r$omega_H <= r$omega_max, "YES", "NO")
  diag_lines <- c(diag_lines,
    sprintf("| %s | %s | %.4f | %.4f | %.4f | %s |",
            r$label, wH_str, r$w_bar, r$omega_min, r$omega_max, in_range))
}
diag_lines <- c(diag_lines, "")

# Section 5: Benchmark normalization
# Recover eps_hat at benchmark year from the series
bm_eps <- NA
if (!is.null(series$full)) {
  bm_idx <- which.min(abs(series$full$year - bm_year))
  if (length(bm_idx) > 0) bm_eps <- series$full$eps_hat[bm_idx]
}

diag_lines <- c(diag_lines,
  "## 5. Benchmark normalization",
  sprintf("- Primary benchmark year: %d", bm_year),
  sprintf("- ε̂_{%d} (full sample): %s", bm_year, ifelse(is.na(bm_eps), "N/A", sprintf("%.6f", bm_eps))),
  "- μ̂_{benchmark} = 1.000 (by construction)",
  ""
)

# Section 6: Open flags
diag_lines <- c(diag_lines,
  "## 6. Open flags"
)
if (length(audit$warnings) > 0) {
  for (w in audit$warnings) {
    diag_lines <- c(diag_lines, sprintf("- %s", w))
  }
} else {
  diag_lines <- c(diag_lines, "- None.")
}
diag_lines <- c(diag_lines,
  "",
  sprintf("- Column resolution: omega_t derived from: %s", audit$omega_derived_from),
  sprintf("- ok_t rebuilt: %s", audit$ok_rebuilt)
)

writeLines(diag_lines, file.path(out_dir, "US_theta_DOLS_diagnostic_notes.md"))
cat("[results] Written: US_theta_DOLS_diagnostic_notes.md\n")

cat("\n=== Results .md files generated ===\n")
cat(sprintf("Output directory: %s\n", out_dir))
