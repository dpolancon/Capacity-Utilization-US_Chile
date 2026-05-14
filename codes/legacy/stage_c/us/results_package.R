###############################################################################
# US — Consolidated Results Package (1940–1978)
# Blocks I–IV: Profitability · Dysfunctionality · Hypothesis · Local Projections
###############################################################################

# ── 0. Working paths & packages ─────────────────────────────────────────────
proj_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
data_dir  <- file.path(proj_root, "data/processed/US")
out_dir   <- file.path(proj_root, "output/results_package_us")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
fig_dir   <- file.path(out_dir, "figures")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
tab_dir   <- file.path(out_dir, "tables")
dir.create(tab_dir, recursive = TRUE, showWarnings = FALSE)

pkgs <- c("dplyr", "tidyr", "readr", "zoo", "lmtest", "sandwich", "strucchange", "ggplot2")
for (p in pkgs) if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
lapply(pkgs, library, character.only = TRUE)

# ─────────────────────────────────────────────────────────────────────────────
# 1. DATA FOUNDATION
# ─────────────────────────────────────────────────────────────────────────────

# --- 1a. Load μ/θ path package (master provenance) ---------------------------
mu_theta_file <- list.files(
  data_dir, pattern = "us_mu_theta_path_spec.*\\.csv$", full.names = TRUE
)
d_mt <- read_csv(mu_theta_file, show_col_types = FALSE)

# Keep only the lean analysis layer
d_mt <- d_mt |>
  select(year, omega_t, theta_t_hat, gK, gYp, Y_real, Yp_hat, mu_t) |>
  filter(year >= 1939, year <= 1978) |>
  arrange(year)

cat("μ/θ package loaded:", nrow(d_mt), "rows,", ncol(d_mt), "cols\n")

# --- 1b. Load stageBC (capital-stock, price-deflator, investment only) -------
d_bc <- read_csv(file.path(data_dir, "us_nf_corporate_stageBC.csv"),
                 show_col_types = FALSE)

d_bc <- d_bc |>
  select(year, KGR, KNR, KGC, KNC, pY = Py, pK, IGC) |>
  filter(year >= 1939, year <= 1978) |>
  arrange(year)

cat("stageBC loaded:", nrow(d_bc), "rows,", ncol(d_bc), "cols\n")

# --- 1c. Merge ---------------------------------------------------------------
d <- d_mt |> full_join(d_bc, by = "year") |> arrange(year)

# Verify no NAs introduced by merge on key vars
stopifnot(all(!is.na(d$mu_t)))
stopifnot(all(!is.na(d$KGR)))

cat("Merged panel:", nrow(d), "years (", min(d$year+1), "–", max(d$year), ")\n")

# ─────────────────────────────────────────────────────────────────────────────
# 2. CORE PROFITABILITY OBJECT
#    r_t = (1 - ω_t) · μ_t · p_t · B_t^{n,G} · ν_t
#    p_t       = pY_t / pK_t
#    B_t^{n,G} = Yp_hat_t / KGC_t          (gross physical productive capacity)
#    ν_t       = KGC_t / KNC_t             (gross-to-net wedge)
# ─────────────────────────────────────────────────────────────────────────────

d <- d |>
  mutate(
    # relative price
    p_t       = pY / pK,
    # gross physical productive capacity
    B_nG_t    = Yp_hat / KGC,
    # gross-to-net wedge
    nu_t      = KGC / KNC,
    # profit rate (level)
    r_t       = (1 - omega_t) * mu_t * p_t * B_nG_t * nu_t,
    # log profit rate
    ln_r_t    = log(r_t),
    # log components for decomposition
    ln_dist_t = log(1 - omega_t),
    ln_mu_t   = log(mu_t),
    ln_p_t    = log(p_t),
    ln_B_nG_t = log(B_nG_t),
    ln_nu_t   = log(nu_t),
    # growth rate of real output (income growth)
    gY_t      = c(NA, diff(log(Y_real)))
  )

# Accounting guardrail: ln r should equal sum of components (up to floating-pt)
d <- d |>
  mutate(
    ln_r_check = ln_dist_t + ln_mu_t + ln_p_t + ln_B_nG_t + ln_nu_t,
    decomp_tol = abs(ln_r_t - ln_r_check)
  )
max_tol <- max(d$decomp_tol, na.rm = TRUE)
cat("Accounting guardrail — max decomposition tolerance:", max_tol, "\n")
if (max_tol > 1e-10) stop("Accounting identity violated beyond tolerance.")

# ─────────────────────────────────────────────────────────────────────────────
# 4. BLOCK I — PROFITABILITY ANALYSIS
# ─────────────────────────────────────────────────────────────────────────────

# --- 4.1 Profit-swing chronology (peak-to-trough via turnpoints) -------------
identify_swings <- function(x, years, min_duration = 2) {
  # Returns a data.frame of swings: start, end, duration, amplitude, pace
  # Uses a minimum-duration filter to avoid micro-chatter
  n <- length(x)
  # simple local-extremum detector (strict)
  peaks <- which(c(FALSE, x[2:(n-1)] > x[1:(n-2)] & x[2:(n-1)] > x[3:n], FALSE))
  troughs <- which(c(FALSE, x[2:(n-1)] < x[1:(n-2)] & x[2:(n-1)] < x[3:n], FALSE))

  # merge and sort into turning-point sequence, then filter by min duration
  tp <- sort(unique(c(peaks, troughs)))
  if (length(tp) < 2) return(data.frame())

  # enforce minimum spacing between turning points
  tp_filtered <- tp[1]
  for (k in 2:length(tp)) {
    if (tp[k] - tp_filtered[length(tp_filtered)] >= min_duration) {
      tp_filtered <- c(tp_filtered, tp[k])
    }
  }
  tp <- tp_filtered
  if (length(tp) < 2) return(data.frame())

  swings <- data.frame(
    idx       = seq_along(tp[-length(tp)]),
    start_idx = tp[-length(tp)],
    end_idx   = tp[-1],
    stringsAsFactors = FALSE
  )
  swings$start_year <- years[swings$start_idx]
  swings$end_year   <- years[swings$end_idx]
  swings$duration   <- swings$end_year - swings$start_year
  swings$amplitude  <- x[swings$end_idx] - x[swings$start_idx]
  swings$pace       <- swings$amplitude / swings$duration
  swings$direction  <- ifelse(swings$amplitude > 0, "expansion", "contraction")
  swings
}

profit_swings <- identify_swings(d$r_t, d$year)
cat("\n=== PROFIT-SWING CHRONOLOGY ===\n")
print(profit_swings)
write_csv(profit_swings, file.path(tab_dir, "profit_swings.csv"))

# --- 4.2 Profitability decomposition by swing --------------------------------
decompose_swings <- function(swings, d) {
  comp_names <- c("ln_dist_t", "ln_mu_t", "ln_p_t", "ln_B_nG_t", "ln_nu_t")
  comp_labels <- c("distribution", "utilization", "rel_prices",
                   "gross_phys_capacity", "gross_net_wedge")
  out <- data.frame()
  for (i in seq_len(nrow(swings))) {
    s <- swings[i, ]
    row_i <- data.frame(
      swing      = s$idx,
      start_year = s$start_year,
      end_year   = s$end_year,
      direction  = s$direction,
      amplitude  = log(d$r_t[d$year == s$end_year]) -
                   log(d$r_t[d$year == s$start_year]),
      duration   = s$duration,
      pace       = (log(d$r_t[d$year == s$end_year]) -
                    log(d$r_t[d$year == s$start_year])) / s$duration,
      stringsAsFactors = FALSE
    )
    for (j in seq_along(comp_names)) {
      v <- comp_names[j]
      row_i[[comp_labels[j]]] <-
        d[[v]][d$year == s$end_year] - d[[v]][d$year == s$start_year]
    }
    out <- rbind(out, row_i)
  }
  out
}

profit_decomp <- decompose_swings(profit_swings, d)
cat("\n=== PROFITABILITY DECOMPOSITION ===\n")
print(profit_decomp)
write_csv(profit_decomp, file.path(tab_dir, "profit_decomposition.csv"))

# --- 4.3 Additional descriptive rows: capitalization & accumulation ---------
d <- d |>
  mutate(
    # rate of capitalization: χ_t = I/Π = IGC / GOS_real (from stageBC if avail)
    # Since GOS_real is excluded, approximate via identity:
    #   χ_t ≈ gK_t / r_t  (recapitalization as capital-growth over profit rate)
    # For descriptive bridge use gK directly as capitalization pace
    chi_desc = gK,
    # rate of accumulation: gK (already in data)
    gK_acc   = gK
  )

profit_decomp <- profit_decomp |>
  mutate(
    capitalization = NA_real_,
    accumulation   = NA_real_
  )

for (i in seq_len(nrow(profit_decomp))) {
  s <- profit_decomp[i, ]
  yrs <- d$year >= s$start_year & d$year <= s$end_year
  profit_decomp$capitalization[i] <- mean(d$gK[yrs], na.rm = TRUE)
  profit_decomp$accumulation[i]   <- mean(d$gK[yrs], na.rm = TRUE)
}

write_csv(profit_decomp, file.path(tab_dir, "profit_decomposition.csv"))

# ─────────────────────────────────────────────────────────────────────────────
# 5. BLOCK I.b — INTERSECTING TEMPORALITIES OF CLASS STRUGGLE
# ─────────────────────────────────────────────────────────────────────────────

# --- 5.1 Filtered tendential wage-share path ---------------------------------
d <- d |>
  mutate(
    ln_omega_T = log(omega_t) - theta_t_hat * log(mu_t)
  )

# --- 5.2 Tendential wage-share swing chronology ------------------------------
wage_swings <- identify_swings(d$ln_omega_T, d$year, min_duration = 3)
cat("\n=== TENDENTIAL WAGE-SWING CHRONOLOGY ===\n")
print(wage_swings)
write_csv(wage_swings, file.path(tab_dir, "wage_swings.csv"))

# --- 5.3 Intersecting temporalities ------------------------------------------
intersect_swings <- function(profit_sw, wage_sw) {
  out <- data.frame()
  for (i in seq_len(nrow(profit_sw))) {
    for (j in seq_len(nrow(wage_sw))) {
      p_start <- profit_sw$start_year[i]
      p_end   <- profit_sw$end_year[i]
      w_start <- wage_sw$start_year[j]
      w_end   <- wage_sw$end_year[j]
      # overlap or border intersection
      overlaps <- (p_start <= w_end & p_end >= w_start)
      if (overlaps) {
        hinge_start <- max(p_start, w_start)
        hinge_end   <- min(p_end, w_end)
        out <- rbind(out, data.frame(
          profit_swing   = profit_sw$idx[i],
          profit_dir     = profit_sw$direction[i],
          wage_swing     = wage_sw$idx[j],
          hinge_start    = hinge_start,
          hinge_end      = hinge_end,
          hinge_duration = hinge_end - hinge_start,
          stringsAsFactors = FALSE
        ))
      }
    }
  }
  out
}

intersections <- intersect_swings(profit_swings, wage_swings)
cat("\n=== INTERSECTING TEMPORALITIES ===\n")
print(intersections)
write_csv(intersections, file.path(tab_dir, "intersecting_temporalities.csv"))

# ─────────────────────────────────────────────────────────────────────────────
# 6. BLOCK II — DYSFUNCTIONALITY INDICES
# ─────────────────────────────────────────────────────────────────────────────

# Dysfunctionality system definitions:
# GD_t = 1 - μ_t                    (gross dysfunction — unused capacity)
# SO_t = mu_t * (1 - omega_t)       (support / offset — realized surplus share)
# ND_t = GD_t - SO_t                (net dysfunction — residual after offset)
# OD_t = SO_t / (1 - GD_t)          (offset dependence — offset relative to active capacity)
# RR_t = ND_t / SO_t                (reversal risk — residual fragility per unit offset)
# ST_t = GD_t * (1 - mu_t)          (stagnation transmission — burden × idle capacity)

d <- d |>
  mutate(
    GD_t = 1 - mu_t,
    SO_t = mu_t * (1 - omega_t),
    ND_t = GD_t - SO_t,
    OD_t = ifelse(SO_t > 0, SO_t / (1 - GD_t), NA),
    RR_t = ifelse(SO_t > 0, ND_t / SO_t, NA),
    ST_t = GD_t * (1 - mu_t)
  )

# --- 6.1 Minimalist figures --------------------------------------------------
plot_minimal <- function(x, y, ylab_short, fname) {
  p <- ggplot(data.frame(year = x, val = y), aes(year, val)) +
    geom_line(color = "black", linewidth = 0.6) +
    geom_point(color = "black", size = 0.8) +
    scale_x_continuous(breaks = seq(floor(min(x)), ceiling(max(x)), by = 2)) +
    labs(x = "", y = ylab_short) +
    theme_minimal(base_size = 11) +
    theme(
      panel.grid    = element_blank(),
      panel.border  = element_blank(),
      plot.title    = element_blank(),
      plot.subtitle = element_blank(),
      axis.text.x   = element_text(size = 7, angle = 45, hjust = 1),
      axis.text.y   = element_text(size = 8),
      axis.ticks    = element_line(color = "black", linewidth = 0.3),
      axis.line     = element_line(color = "black", linewidth = 0.3)
    )
  ggsave(file.path(fig_dir, fname), p, width = 6, height = 2.5, dpi = 300)
  p
}

dysf_indices <- c("GD_t", "SO_t", "ND_t", "OD_t", "RR_t", "ST_t")
dysf_labels  <- c("Gross dysfunction", "Support / offset", "Net dysfunction",
                   "Offset dependence", "Reversal risk", "Stagnation transmission")

for (k in seq_along(dysf_indices)) {
  idx  <- dysf_indices[k]
  lbl  <- dysf_labels[k]
  fname <- paste0("dysf_", tolower(sub("_t$", "", idx)), ".png")
  plot_minimal(d$year, d[[idx]], lbl, fname)
  cat("Figure saved:", fname, "\n")
}

# ─────────────────────────────────────────────────────────────────────────────
# 7. BLOCK III — HYPOTHESIS TESTING
#    gY_t ≈ α' + β₁ ln r_t + β₂ RR_t − β₃ GD_t + u_t
# ─────────────────────────────────────────────────────────────────────────────

d_reg <- d |>
  filter(!is.na(gY_t), !is.na(ln_r_t), !is.na(RR_t), !is.na(GD_t))

cat("\n=== BASELINE REDUCED-FORM REGRESSION ===\n")
cat("Sample:", nrow(d_reg), "observations\n")

fit_baseline <- lm(gY_t ~ ln_r_t + RR_t + GD_t, data = d_reg)
summary_fit <- summary(fit_baseline)
print(summary_fit)

# HAC-robust inference
vcov_hac <- NeweyWest(fit_baseline, lag = 2, prewhite = FALSE)
coeftest_baseline <- coeftest(fit_baseline, vcov = vcov_hac)
cat("\nHAC-robust coefficients:\n")
print(coeftest_baseline)

# Save regression outputs
capture.output(summary_fit,
               file = file.path(tab_dir, "regression_baseline.txt"))
capture.output(coeftest_baseline,
               file = file.path(tab_dir, "regression_baseline_hac.txt"),
               append = TRUE)

# ─────────────────────────────────────────────────────────────────────────────
# 8. BLOCK IV — DYNAMIC COMPLEMENT (LOCAL PROJECTIONS)
#    Trace impulse responses of Δln Y to shocks in profitability & dysfunction
# ─────────────────────────────────────────────────────────────────────────────

# Shocks: innovations in ln_r_t, GD_t, RR_t
# Horizon: 0–3 years
max_h <- 3

shock_vars <- c("ln_r_t", "GD_t", "RR_t")
resp_var   <- "gY_t"

# Prepare first-differenced response
d_lp <- d |>
  mutate(dy = c(NA, diff(log(Y_real)))) |>
  filter(!is.na(dy))

# LP coefficients storage
lp_results <- list()

for (h in 0:max_h) {
  # forward outcome at horizon h
  d_lp[[paste0("y_h", h)]] <- c(d_lp$dy[(h + 1):nrow(d_lp)],
                                 rep(NA, h))
}

lp_coefs <- data.frame()

for (sv in shock_vars) {
  for (h in 0:max_h) {
    df_h <- d_lp |> filter(!is.na(.data[[paste0("y_h", h)]]), !is.na(.data[[sv]]))
    if (nrow(df_h) < 10) next
    fit_h <- lm(as.formula(paste0("y_h", h, " ~ ", sv)), data = df_h)
    b <- coef(fit_h)[2]
    se <- summary(fit_h)$coefficients[2, 2]
    lp_coefs <- rbind(lp_coefs, data.frame(
      shock_var = sv,
      horizon   = h,
      beta      = b,
      se        = se,
      stringsAsFactors = FALSE
    ))
  }
}

cat("\n=== LOCAL PROJECTIONS (first differences) ===\n")
print(lp_coefs)
write_csv(lp_coefs, file.path(tab_dir, "local_projections.csv"))

# ── LP impulse-response style plots (one per shock) ──────────────────────────
plot_lp <- function(df, shock_name) {
  sub <- df |> filter(shock_var == shock_name)
  p <- ggplot(sub, aes(horizon, beta)) +
    geom_line(color = "black", linewidth = 0.6) +
    geom_point(color = "black", size = 1.5) +
    geom_errorbar(aes(ymin = beta - 1.96 * se, ymax = beta + 1.96 * se),
                  width = 0.15, color = "grey50", linewidth = 0.5) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "grey40",
               linewidth = 0.4) +
    scale_x_continuous(breaks = 0:max_h) +
    labs(x = "Horizon (years)", y = "Response of Δln Y") +
    theme_minimal(base_size = 11) +
    theme(
      panel.grid    = element_blank(),
      panel.border  = element_blank(),
      plot.title    = element_blank(),
      axis.text     = element_text(size = 9),
      axis.line     = element_line(color = "black", linewidth = 0.3)
    )
  fname <- paste0("lp_", tolower(sub("_t$", "", shock_name)), ".png")
  ggsave(file.path(fig_dir, fname), p, width = 5, height = 3, dpi = 300)
  p
}

for (sv in shock_vars) {
  plot_lp(lp_coefs, sv)
  cat("LP figure saved:", sv, "\n")
}

# ─────────────────────────────────────────────────────────────────────────────
# 9. FINAL ASSEMBLY — SUMMARY OUTPUT
# ─────────────────────────────────────────────────────────────────────────────

cat("\n")
cat("=============================================================\n")
cat("  RESULTS PACKAGE ASSEMBLY COMPLETE\n")
cat("=============================================================\n")
cat("Tables saved to :", tab_dir, "\n")
cat("Figures saved to :", fig_dir, "\n")
cat("\nContents:\n")
cat("  Block I   — Profitability swings & decomposition\n")
cat("  Block I.b — Intersecting wage-share temporalities\n")
cat("  Block II  — Dysfunctionality indices (6 figures)\n")
cat("  Block III — Baseline reduced-form regression (OLS + HAC)\n")
cat("  Block IV  — Local projections (3 shock × 4 horizons)\n")
cat("=============================================================\n")
