# 01_US_theta_DOLS.R
# DOLS estimation of θ for the United States with pre-flight variable audit guardrail
# Samples: full, pre-1974 (≤1973), post-1973 (≥1974)
# Distributional variable: ω_t = wage share (EC_NF / GVA_NF)
# NOTATION LOCKS: omega_t, k_t, y_t, ok_t, theta_t, mu_hat

# ============================================================
# BLOCK 0: Setup — packages, paths, install if needed
# ============================================================

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

pkgs <- c("dplyr", "dynlm", "sandwich", "lmtest", "ggplot2")
missing_pkgs <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  cat(sprintf("[setup] Installing missing packages: %s\n", paste(missing_pkgs, collapse = ", ")))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}

suppressPackageStartupMessages({
  library(dplyr)
  library(dynlm)
  library(sandwich)
  library(lmtest)
  library(ggplot2)
})

out_dir <- file.path(REPO, "AR_Corridor/04_estimation_outputs/stable_results")
diag_dir <- file.path(REPO, "AR_Corridor/04_estimation_outputs/diagnostics")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(diag_dir, recursive = TRUE, showWarnings = FALSE)

benchmark_year   <- 1966
benchmark_year_2 <- 1948
caput_pin_note   <- "1966 = peak Fordist utilization; 1948 = post-WWII recovery baseline"

cat(sprintf("[setup] Benchmark year: %d (primary), %d (secondary)\n", benchmark_year, benchmark_year_2))
cat(sprintf("[setup] CAPUT note: %s\n", caput_pin_note))
cat(sprintf("[setup] Output directory: %s\n", out_dir))

# ============================================================
# BLOCK 1: load_panel() — with variable audit (adapted from amendment)
# Resolves column aliases, derives omega_t, detects pi_t spec,
# rebuilds stale ok_t, returns data + audit log.
# ============================================================

load_panel <- function(panel_path) {

  if (!file.exists(panel_path)) {
    stop(sprintf("[load_panel] Panel file not found: %s", panel_path))
  }

  df   <- read.csv(panel_path, stringsAsFactors = FALSE)
  cols <- names(df)

  audit <- list(
    file       = panel_path,
    all_cols   = paste(cols, collapse = ", "),
    year_col   = NA, y_col = NA, k_col = NA, omega_col = NA,
    omega_derived_from = NA,
    ok_rebuilt = FALSE,
    warnings   = character()
  )

  resolve <- function(aliases, df_cols) {
    m <- df_cols[tolower(df_cols) %in% tolower(aliases)]
    if (length(m) == 0) return(NA_character_)
    m[1]
  }

  # --- Year ---
  year_col <- resolve(c("year", "yr", "YEAR"), cols)
  if (is.na(year_col)) stop("[load_panel] year column not found.")
  audit$year_col <- year_col

  # --- y_t (log output) ---
  y_aliases <- c("y_t", "log_y", "log_Y", "lnY", "ln_y", "y_log")
  y_col <- resolve(y_aliases, cols)
  if (is.na(y_col)) stop(sprintf(
    "[load_panel] y_t not found. Tried: %s\nAvailable: %s",
    paste(y_aliases, collapse = ", "), paste(cols, collapse = ", ")))
  audit$y_col <- y_col

  # --- k_t (log capital stock) ---
  k_aliases <- c("k_t", "log_k", "log_K", "lnK", "ln_k", "k_log")
  k_col <- resolve(k_aliases, cols)
  if (is.na(k_col)) stop(sprintf(
    "[load_panel] k_t not found. Tried: %s\nAvailable: %s",
    paste(k_aliases, collapse = ", "), paste(cols, collapse = ", ")))
  audit$k_col <- k_col
  if (grepl("net|KNC|k_net|knet", k_col, ignore.case = TRUE)) {
    audit$warnings <- c(audit$warnings,
      sprintf("WARNING: k_col='%s' looks like a NET stock. Gross required for theta.", k_col))
  }

  # --- omega_t (wage share) — primary resolution ---
  omega_aliases <- c("omega_t", "wage_share", "omega", "w_share", "EC_NF_share",
                     "wage_share_NF", "wshare")
  omega_col <- resolve(omega_aliases, cols)

  if (!is.na(omega_col)) {
    # Sanity check: omega should be in (0,1)
    vals <- suppressWarnings(as.numeric(df[[omega_col]]))
    vals <- vals[!is.na(vals)]
    if (length(vals) > 0 && (min(vals) < 0 || max(vals) > 1)) {
      audit$warnings <- c(audit$warnings,
        sprintf("WARNING: '%s' has values outside (0,1): [%.3f, %.3f]. Not a share?",
                omega_col, min(vals), max(vals)))
    }
    audit$omega_col <- omega_col
    audit$omega_derived_from <- "direct"

  } else {
    # omega not found directly — try derivation cascade

    # Case 1: pi_t (profit share) present → omega = 1 - pi_t
    # This catches panels built under the old pi_t specification
    pi_aliases <- c("pi_t", "pi", "profit_share", "profsh", "Profshcorp",
                    "Profshcorpt", "profit_share_corp", "profsh_corp",
                    "profit_share_nfc", "profsh_nfc", "pishare")
    pi_col <- resolve(pi_aliases, cols)

    if (!is.na(pi_col)) {
      df$omega_t <- 1 - suppressWarnings(as.numeric(df[[pi_col]]))
      omega_col  <- "omega_t"
      audit$omega_col <- omega_col
      audit$omega_derived_from <- paste0("1 - ", pi_col, "  [OLD pi_t SPEC DETECTED]")
      audit$warnings <- c(audit$warnings,
        sprintf("DERIVATION: omega_t = 1 - %s. Panel was built under pi_t spec.", pi_col))

    # Case 2: compensation and GVA columns present → omega = EC / GVA
    } else {
      ec_aliases <- c("EC_NF", "EC_nfc", "compensation", "EC", "wages",
                      "employee_compensation", "EC_NF_raw")
      gva_aliases <- c("GVA_NF", "GVA_nfc", "GVA", "value_added", "gross_value_added")
      ec_col  <- resolve(ec_aliases, cols)
      gva_col <- resolve(gva_aliases, cols)

      if (!is.na(ec_col) && !is.na(gva_col)) {
        ec_vals  <- suppressWarnings(as.numeric(df[[ec_col]]))
        gva_vals <- suppressWarnings(as.numeric(df[[gva_col]]))
        df$omega_t <- ec_vals / gva_vals
        omega_col  <- "omega_t"
        audit$omega_col <- omega_col
        audit$omega_derived_from <- paste0(ec_col, " / ", gva_col)
        audit$warnings <- c(audit$warnings,
          sprintf("DERIVATION: omega_t = %s / %s.", ec_col, gva_col))

      } else {
        stop(sprintf(
          "[load_panel] Cannot resolve omega_t. Tried direct aliases, 1-pi_t, and EC/GVA ratio.\nAvailable columns: %s",
          paste(cols, collapse = ", ")))
      }
    }
  }

  # --- Check for stale ok_t ---
  if ("ok_t" %in% cols) {
    stored_ok   <- suppressWarnings(as.numeric(df[["ok_t"]]))
    computed_ok <- suppressWarnings(as.numeric(df[[omega_col]])) *
                   suppressWarnings(as.numeric(df[[k_col]]))
    ok_diff <- mean(abs(stored_ok - computed_ok), na.rm = TRUE)
    if (ok_diff > 1e-6) {
      audit$warnings <- c(audit$warnings,
        sprintf("WARNING: stored ok_t differs from omega_t*k_t by mean %.6f. Rebuilding ok_t.", ok_diff))
      df$ok_t       <- computed_ok
      audit$ok_rebuilt <- TRUE
    }
  }

  # --- Standardise column names to canonical ---
  out <- data.frame(
    year    = as.integer(df[[year_col]]),
    y_t     = as.numeric(df[[y_col]]),
    k_t     = as.numeric(df[[k_col]]),
    omega_t = as.numeric(df[[omega_col]])
  )
  out <- out[complete.cases(out), ]
  out <- out[order(out$year), ]
  out$ok_t <- out$omega_t * out$k_t   # always recompute from canonical omega

  audit$n_obs     <- nrow(out)
  audit$year_min  <- min(out$year)
  audit$year_max  <- max(out$year)
  audit$omega_min <- round(min(out$omega_t), 4)
  audit$omega_max <- round(max(out$omega_t), 4)

  list(data = out, audit = audit)
}

# ============================================================
# BLOCK 2: Resolve panel file path
# ============================================================

candidate_paths <- c(
  file.path(REPO, "data/processed/US/us_nfc_panel.csv"),
  file.path(REPO, "data/processed/us_nfc_panel.csv"),
  file.path(REPO, "data/processed/US/US_corporate_NF_kstock_distribution.csv"),
  file.path(REPO, "data/processed/us_nf_corporate_stageBC.csv"),
  file.path(REPO, "data/processed/us_nf_corporate_stageC.csv")
)

panel_path <- NULL
for (f in candidate_paths) {
  if (file.exists(f)) { panel_path <- f; break }
}

# Fallback: scan data/processed/US/ for most recent .csv
if (is.null(panel_path)) {
  us_data_dir <- file.path(REPO, "data/processed/US")
  if (dir.exists(us_data_dir)) {
    csv_files <- list.files(us_data_dir, pattern = "\\.csv$", full.names = TRUE)
    if (length(csv_files) > 0) {
      mt <- file.info(csv_files)$mtime
      panel_path <- csv_files[which.max(mt)]
      cat(sprintf("[data] Using most recent CSV in data/processed/US/: %s\n", panel_path))
    }
  }
}

if (is.null(panel_path)) {
  stop("[data] No panel file found. Tried:\n  "
       %>% paste(paste(candidate_paths, collapse = "\n  "), ., sep = "\n"))
}

cat(sprintf("[data] Panel loaded: %s\n", panel_path))

# ============================================================
# BLOCK PREFLIGHT: Variable audit — run before any estimation
# Loads the panel, runs audit, writes pre-flight report.
# Halts if any critical issue cannot be resolved automatically.
# ============================================================

result <- tryCatch(
  load_panel(panel_path),
  error = function(e) {
    list(data = NULL, audit = list(
      file = panel_path,
      all_cols = "—", year_col = NA, y_col = NA, k_col = NA,
      omega_col = NA, omega_derived_from = NA, ok_rebuilt = FALSE,
      warnings = paste("LOAD ERROR:", e$message),
      n_obs = 0, year_min = NA, year_max = NA,
      omega_min = NA, omega_max = NA))
  }
)

panel_data <- result$data
audit      <- result$audit

pf_lines <- c(
  "## Pre-flight variable audit",
  sprintf("Generated: %s", Sys.time()),
  sprintf("benchmark_year (primary): %d", benchmark_year),
  sprintf("benchmark_year (secondary): %d", benchmark_year_2),
  sprintf("CAPUT note: %s", caput_pin_note),
  ""
)

pf_lines <- c(pf_lines,
  "### US Panel",
  "",
  sprintf("| Field | Value |"),
  sprintf("|-------|-------|"),
  sprintf("| File  | %s |", audit$file),
  sprintf("| year  | %s |", audit$year_col),
  sprintf("| y_t   | %s |", audit$y_col),
  sprintf("| k_t   | %s |", audit$k_col),
  sprintf("| omega_t | %s |", audit$omega_col),
  sprintf("| omega derived from | %s |", audit$omega_derived_from),
  sprintf("| ok_t rebuilt? | %s |", audit$ok_rebuilt),
  sprintf("| N obs | %s |", audit$n_obs),
  sprintf("| Year range | %s - %s |", audit$year_min, audit$year_max),
  sprintf("| omega range | [%s, %s] |", audit$omega_min, audit$omega_max),
  ""
)

if (length(audit$warnings) > 0) {
  pf_lines <- c(pf_lines, "**Warnings:**", "")
  for (w in audit$warnings) pf_lines <- c(pf_lines, sprintf("- %s", w))
  pf_lines <- c(pf_lines, "")
}

# Flag critical failures
if (is.null(panel_data)) {
  pf_lines <- c(pf_lines, "**CRITICAL: US panel failed to load.**", "")
  stop(sprintf("[preflight] US panel failed to load.\n  Error: %s\n  See audit report for details.",
               paste(audit$warnings, collapse = "; ")))
}

# Flag if omega derivation used old pi_t spec
if (!is.na(audit$omega_derived_from) &&
    grepl("pi_t SPEC", audit$omega_derived_from, ignore.case = TRUE)) {
  pf_lines <- c(pf_lines,
    "**FLAG: Panel was built under pi_t spec. omega_t auto-derived as 1-pi_t.**",
    "Verify this is the correct transformation before trusting estimation results.", "")
}

# Sample coverage check: warn if Fordist window 1945-1978 is not fully covered
fordist_yrs     <- 1945:1978
missing_fordist <- fordist_yrs[!fordist_yrs %in% panel_data$year]
if (length(missing_fordist) > 0) {
  msg <- sprintf("[preflight] Fordist window gap: missing years %s",
                 paste(range(missing_fordist), collapse = "-"))
  pf_lines <- c(pf_lines, paste("**WARNING:**", msg), "")
  cat(sprintf("%s\n", msg))
}

# Write pre-flight report
pf_file <- file.path(diag_dir, "US_preflight_audit_130426.md")
writeLines(pf_lines, pf_file)
cat(sprintf("[preflight] Report written: %s\n", pf_file))
for (w in audit$warnings) cat(sprintf("  [!] %s\n", w))

cat("[preflight] Panel loaded and audited. Proceeding to estimation.\n\n")

# ============================================================
# BLOCK 3: Sample definitions and DOLS specification
# ============================================================

FULL   <- function(df) df
SAMPLE_A <- function(df) filter(df, year <= 1973)
SAMPLE_B <- function(df) filter(df, year >= 1974)

samples <- list(
  full     = list(label = "Full sample",          data_fn = FULL),
  pre1974  = list(label = "Pre-1974 (≤1973)",    data_fn = SAMPLE_A),
  post1973 = list(label = "Post-1973 (≥1974)",   data_fn = SAMPLE_B)
)

# --- DOLS fitting function ---
dols_fit <- function(df, p = 2) {
  # Construct interaction and differenced terms
  df <- df %>%
    mutate(
      ok_t = omega_t * k_t,
      dk   = c(NA, diff(k_t)),
      dok  = c(NA, diff(ok_t))
    )

  n <- nrow(df)

  # Build lead/lag columns for Δk and Δ(ω·k)
  for (j in seq(-p, p)) {
    suffix <- if (j < 0) paste0("lead", abs(j)) else if (j == 0) "lag0" else paste0("lag", j)
    # Negative j = leads (future values shifted back)
    df[[paste0("dk_l", suffix)]]  <- dplyr::lag(df$dk,  -j)
    df[[paste0("dok_l", suffix)]] <- dplyr::lag(df$dok, -j)
  }

  # Drop rows with any NA (leads/lags trim the ends)
  df_clean <- na.omit(df)

  # Build dynamic regressor names
  ll_vars <- c(
    paste0("dk_l",  c(paste0("lead", p:1), "lag0", paste0("lag", 1:p))),
    paste0("dok_l", c(paste0("lead", p:1), "lag0", paste0("lag", 1:p)))
  )
  fml <- as.formula(paste("y_t ~ k_t + ok_t +", paste(ll_vars, collapse = " + ")))

  fit <- lm(fml, data = df_clean)
  list(fit = fit, df_clean = df_clean, formula = fml)
}

# --- Post-estimation recovery ---
recover_objects <- function(dols_result, benchmark_year) {
  fit      <- dols_result$fit
  df_used  <- dols_result$df_clean
  beta1    <- coef(fit)["k_t"]
  beta2    <- coef(fit)["ok_t"]

  # omega_vec from cleaned data
  omega_vec <- df_used$omega_t
  years_used <- df_used$year

  # Time-varying θ̂_t
  theta_t <- beta1 + beta2 * omega_vec

  # DOLS residual
  eps_hat <- residuals(fit)

  # Benchmark normalization
  bm_idx <- which.min(abs(years_used - benchmark_year))
  if (length(bm_idx) == 0 || bm_idx > length(eps_hat)) {
    bm_idx <- 1  # fallback
  }
  eps_tilde <- eps_hat - eps_hat[bm_idx]

  # Capacity utilization index
  mu_hat <- exp(eps_tilde)

  # Log productive capacity
  yp_hat <- df_used$y_t - eps_tilde

  data.frame(
    year      = years_used,
    theta_t   = theta_t,
    eps_hat   = eps_hat,
    eps_tilde = eps_tilde,
    mu_hat    = mu_hat,
    yp_hat    = yp_hat,
    omega_t   = omega_vec
  )
}

# ============================================================
# BLOCK 4: Main estimation loop
# ============================================================

results_list <- list()
series_list  <- list()
p_baseline   <- 2

cat("=", rep("=", 64), "\n")
cat("DOLS ESTIMATION — US θ identification\n")
cat(rep("=", 65), "\n\n")

for (nm in names(samples)) {
  cat(sprintf("\n--- %s ---\n", samples[[nm]]$label))

  df_s   <- samples[[nm]]$data_fn(panel_data)
  dols_r <- dols_fit(df_s, p = p_baseline)
  fit_s  <- dols_r$fit
  hac_s  <- coeftest(fit_s, vcov = NeweyWest(fit_s))
  objs_s <- recover_objects(dols_r, benchmark_year = benchmark_year)

  w_bar  <- mean(df_s$omega_t, na.rm = TRUE)
  beta1  <- coef(fit_s)["k_t"]
  beta2  <- coef(fit_s)["ok_t"]

  theta_bar <- beta1 + beta2 * w_bar
  # Delta method SE for theta_bar
  vc_12 <- vcov(fit_s)[c("k_t", "ok_t"), c("k_t", "ok_t")]
  se_bar <- sqrt(vc_12[1,1] + w_bar^2 * vc_12[2,2] + 2 * w_bar * vc_12[1,2])

  # Harrodian threshold: ω_H where θ = 1 → β₁ + β₂·ω_H = 1
  omega_H <- if (abs(beta2) > 1e-10) (1 - beta1) / (-beta2) else NA

  cat(sprintf("  β₁ (k_t)  = %.4f  (HAC SE = %.4f, t = %.3f)\n",
              beta1, hac_s["k_t", "Std. Error"], hac_s["k_t", "t value"]))
  cat(sprintf("  β₂ (ok_t) = %.4f  (HAC SE = %.4f, t = %.3f)\n",
              beta2, hac_s["ok_t", "Std. Error"], hac_s["ok_t", "t value"]))
  cat(sprintf("  θ̄(ω̄=%.4f) = %.4f  (SE = %.4f)\n", w_bar, theta_bar, se_bar))
  cat(sprintf("  ω_H (Harrodian) = %s\n", ifelse(is.na(omega_H), "N/A", sprintf("%.4f", omega_H))))
  if (!is.na(omega_H)) {
    w_min <- min(df_s$omega_t, na.rm = TRUE)
    w_max <- max(df_s$omega_t, na.rm = TRUE)
    in_range <- omega_H >= w_min && omega_H <= w_max
    cat(sprintf("  ω_H in sample range [%.4f, %.4f]? %s\n", w_min, w_max, ifelse(in_range, "YES", "NO")))
  }
  cat(sprintf("  N = %d  R² = %.4f\n", nobs(fit_s), summary(fit_s)$r.squared))

  results_list[[nm]] <- list(
    label    = samples[[nm]]$label,
    fit      = fit_s,
    hac      = hac_s,
    beta1    = beta1,
    beta2    = beta2,
    beta1_se = hac_s["k_t", "Std. Error"],
    beta2_se = hac_s["ok_t", "Std. Error"],
    beta1_t  = hac_s["k_t", "t value"],
    beta2_t  = hac_s["ok_t", "t value"],
    beta1_p  = hac_s["k_t", "Pr(>|t|)"],
    beta2_p  = hac_s["ok_t", "Pr(>|t|)"],
    nobs     = nobs(fit_s),
    r2       = summary(fit_s)$r.squared,
    w_bar    = w_bar,
    theta_bar= theta_bar,
    se_bar   = se_bar,
    omega_H  = omega_H,
    omega_min= min(df_s$omega_t, na.rm = TRUE),
    omega_max= max(df_s$omega_t, na.rm = TRUE),
    n_raw    = nrow(df_s),
    n_clean  = nrow(dols_r$df_clean),
    year_min = min(dols_r$df_clean$year),
    year_max = max(dols_r$df_clean$year)
  )
  series_list[[nm]] <- objs_s
}

# ============================================================
# BLOCK 5: Save outputs
# ============================================================

# CSV: time series of θ̂_t and μ̂_t per sample
for (nm in names(series_list)) {
  write.csv(
    series_list[[nm]],
    file = file.path(out_dir, sprintf("US_theta_mu_series_%s.csv", nm)),
    row.names = FALSE
  )
}

# RDS: full results object (for downstream Stage B)
saveRDS(list(results = results_list, series = series_list, audit = audit,
             benchmark_year = benchmark_year, benchmark_year_2 = benchmark_year_2,
             caput_pin_note = caput_pin_note),
        file = file.path(out_dir, "US_theta_DOLS_results.rds"))

cat(sprintf("\n[saved] Series CSVs written to: %s\n", out_dir))
cat(sprintf("[saved] RDS results pack: US_theta_DOLS_results.rds\n"))

# ============================================================
# BLOCK 6: Sign checks and final verdict
# ============================================================

cat("\n", rep("=", 65), "\n")
cat("SIGN CHECK SUMMARY\n")
cat(rep("=", 65), "\n\n")

for (nm in names(results_list)) {
  r <- results_list[[nm]]
  beta2_ok <- r$beta2 < 0
  cat(sprintf("  %-25s β₂ = %+8.4f  sign %s 0 — %s\n",
              r$label, r$beta2,
              ifelse(beta2_ok, "<", ">"),
              ifelse(beta2_ok, "CORRECT", "PROBLEM — inconsistent with theoretical prior")))
}

cat("\n=== DOLS estimation complete ===\n")
cat("Run 02_US_theta_results_md.R next to generate .md result tables.\n")
