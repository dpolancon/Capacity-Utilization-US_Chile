# ============================================================
# 20_shaikh_ardl_replication_WRAPPED.R  (PATCH CONSOLIDATE)
#
# Faithful Shaikh ARDL replication, consolidated:
#  - console results + full log capture (sink split=TRUE)
#  - CSV export of replication series
#  - key-stats CSV export (LaTeX feed)
#  - single plot comparing: Shaikh series + replication variants
#  - two alternative numeraires:
#       (A) p rebased so p(2011)=100
#       (B) p rebased so p(1947)=100
#
# Outputs (under Exercise_a_ARDL_faithful):
#  - csv/SHAIKH_ARDL_replication_series_shaikh_window.csv
#  - csv/SHAIKH_ARDL_replication_key_stats_shaikh_window.csv
#  - logs/SHAIKH_ARDL_replication_log_shaikh_window.txt
#  - figs/FIG_SHAIKH_ARDL_u_shaikh_window.png
#  - Manifest/RUN_MANIFEST_stage4.md (append)
# ============================================================

rm(list = ls())

suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(ARDL)
  library(ggplot2)
})

# --- load CONFIG + utils (repo-local) ---
source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))

RUN_ROOT <- Sys.getenv("STAGE4_RUN_ROOT", unset = "")

# -----------------------------
# Helpers (local)
# -----------------------------

make_step_dummies <- function(df, years) {
  for (yy in years) df[[paste0("d", yy)]] <- as.integer(df$year >= yy)
  df
}

rebase_to_year_to_100 <- function(p_vec, year_vec, base_year, strict = TRUE) {
  idx <- which(year_vec == base_year)
  if (length(idx) != 1) {
    msg <- paste0("Base year ", base_year, " not uniquely present in price index series.")
    if (strict) stop(msg) else {
      warning(msg, " Falling back to first observation in provided series.")
      idx <- 1
    }
  }
  p0 <- p_vec[idx]
  if (!is.finite(p0) || p0 <= 0) stop("Invalid base-year price index value.")
  100 * (p_vec / p0)
}

extract_bt <- function(bt_obj) {
  out <- list(stat = NA_real_, pval = NA_real_)
  if (is.list(bt_obj)) {
    if (!is.null(bt_obj$statistic)) out$stat <- suppressWarnings(as.numeric(bt_obj$statistic))
    if (!is.null(bt_obj$p.value))   out$pval <- suppressWarnings(as.numeric(bt_obj$p.value))
  }
  out
}

get_lr_table_with_scaled_dummies <- function(fit_ardl, dummy_names) {
  lr_mult <- ARDL::multipliers(fit_ardl, type = "lr")
  
  coefs <- coef(fit_ardl)
  den <- 1 - sum(coefs[grep("^L\\(lnY,", names(coefs))])
  
  dummy_lr <- coefs[dummy_names] / den
  
  vc <- vcov(fit_ardl)
  se_delta <- sqrt(diag(vc))[dummy_names]
  se_lr <- se_delta / abs(den)
  
  t_lr <- dummy_lr / se_lr
  p_lr <- 2 * pt(abs(t_lr), df = df.residual(fit_ardl), lower.tail = FALSE)
  
  dummy_table <- data.frame(
    Term         = dummy_names,
    Estimate     = as.numeric(dummy_lr),
    `Std. Error` = as.numeric(se_lr),
    `t value`    = as.numeric(t_lr),
    `Pr(>|t|)`   = as.numeric(p_lr),
    stringsAsFactors = FALSE
  )
  
  names(dummy_table) <- names(lr_mult)
  lr_full_table <- rbind(lr_mult, dummy_table)
  
  list(lr_full_table = lr_full_table, den = den)
}

run_one_variant <- function(df, lnY_col, lnK_col, dummy_names,
                            order = c(2,4), case = "uc") {
  
  df_ts <- ts(df |> select(all_of(c(lnY_col, lnK_col, dummy_names))),
              start = min(df$year), frequency = 1)
  
  fml <- as.formula(paste0(lnY_col, " ~ ", lnK_col, " | ", paste(dummy_names, collapse = " + ")))
  fit_ardl <- ARDL::ardl(formula = fml, data = df_ts, order = order)
  
  # Bounds tests
  bt_f_asympt <- ARDL::bounds_f_test(fit_ardl, case = case, alpha = 0.05, pvalue = TRUE, exact = FALSE)
  bt_f_exact  <- ARDL::bounds_f_test(fit_ardl, case = case, alpha = 0.05, pvalue = TRUE, exact = TRUE)
  bt_t_asympt <- ARDL::bounds_t_test(fit_ardl, case = case, alpha = 0.05, pvalue = TRUE, exact = FALSE)
  bt_t_exact  <- ARDL::bounds_t_test(fit_ardl, case = case, alpha = 0.05, pvalue = TRUE, exact = TRUE)
  
  # LR multipliers incl scaled dummy LR
  lr_pack <- get_lr_table_with_scaled_dummies(fit_ardl, dummy_names)
  lr_full <- lr_pack$lr_full_table
  
  a_lr <- lr_full$Estimate[lr_full$Term == "(Intercept)"]
  b_lr <- lr_full$Estimate[lr_full$Term == lnK_col]
  
  dummy_coef   <- lr_full$Estimate[match(dummy_names, lr_full$Term)]
  dummy_effect <- rowSums(df[dummy_names] * dummy_coef)
  
  lnY <- df[[lnY_col]]
  lnK <- df[[lnK_col]]
  
  lnYp_with <- a_lr + b_lr * lnK + dummy_effect
  lnYp_no   <- a_lr + b_lr * lnK
  
  u_with <- exp(lnY - lnYp_with)
  u_no   <- exp(lnY - lnYp_no)
  
  # λ from UECM
  uecm_model <- ARDL::uecm(fit_ardl)
  uecm_coef <- tryCatch(summary(uecm_model)$coefficients, error = function(e) NULL)
  lambda_hat <- NA_real_
  if (!is.null(uecm_coef)) {
    rr <- grep("^L\\(lnY, 1\\)$", rownames(uecm_coef), value = TRUE)
    if (length(rr) == 1) lambda_hat <- as.numeric(uecm_coef[rr, "Estimate"])
  }
  
  list(
    fml = fml,
    fit = fit_ardl,
    bt  = list(f_asympt = bt_f_asympt, f_exact = bt_f_exact,
               t_asympt = bt_t_asympt, t_exact = bt_t_exact),
    lr_full = lr_full,
    lambda_hat = lambda_hat,
    series = list(u_with = u_with, u_no = u_no, lnYp_with = lnYp_with, lnYp_no = lnYp_no)
  )
}

# -----------------------------
# 0) Load Shaikh replication dataset (CONFIG)
# -----------------------------
df_raw <- readxl::read_excel(here::here(CONFIG$data_shaikh), sheet = CONFIG$data_shaikh_sheet)

stopifnot(all(c(CONFIG$year_col, CONFIG$y_nom, CONFIG$k_nom, CONFIG$p_index) %in% names(df_raw)))

# keep a "full series ledger" for p rebase
p_ledger <- df_raw |>
  transmute(
    year  = as.integer(.data[[CONFIG$year_col]]),
    p_raw = as.numeric(.data[[CONFIG$p_index]])
  ) |>
  filter(is.finite(year), is.finite(p_raw), p_raw > 0) |>
  arrange(year)

# fail fast (don’t let the pipeline invent base years)
stopifnot(any(p_ledger$year == 2011L))
stopifnot(any(p_ledger$year == 1947L))

p_ledger <- p_ledger |>
  mutate(
    p2011 = rebase_to_year_to_100(p_raw, year, 2011L, strict = TRUE),
    p1947 = rebase_to_year_to_100(p_raw, year, 1947L, strict = TRUE)
  ) |>
  select(year, p2011, p1947)

df0 <- df_raw |>
  transmute(
    year  = as.integer(.data[[CONFIG$year_col]]),
    Y_nom = as.numeric(.data[[CONFIG$y_nom]]),
    K_nom = as.numeric(.data[[CONFIG$k_nom]]),
    u_shaikh = {
      if (!is.null(CONFIG$u_shaikh) && CONFIG$u_shaikh %in% names(df_raw)) {
        as.numeric(.data[[CONFIG$u_shaikh]])
      } else if ("u_shaikh" %in% names(df_raw)) {
        as.numeric(.data[["u_shaikh"]])
      } else {
        NA_real_
      }
    }
  ) |>
  filter(is.finite(year), is.finite(Y_nom), is.finite(K_nom)) |>
  arrange(year) |>
  left_join(p_ledger, by = "year")

stopifnot(all(is.finite(df0$p2011)), all(is.finite(df0$p1947)))

# -----------------------------
# 1) Window lock (CONFIG)
# -----------------------------
WINDOW_TAG <- "shaikh_window"
w <- CONFIG$WINDOWS_LOCKED[[WINDOW_TAG]]
WINDOW_START <- as.integer(w[1])
WINDOW_END   <- as.integer(w[2])

df0 <- df0 |>
  filter(year >= w[1], year <= w[2]) |>
  arrange(year)

# -----------------------------
# 1.5) Output dirs + log sink (CONFIG)
# -----------------------------
EXERCISE_DIR <- if (nzchar(RUN_ROOT)) file.path(RUN_ROOT, "Exercise_a_ARDL_faithful") else here::here(CONFIG$OUT_CR$exercise_a %||% "output/CriticalReplication/Exercise_a_ARDL_faithful")
CSV_DIR <- file.path(EXERCISE_DIR, "csv")
LOG_DIR <- file.path(EXERCISE_DIR, "logs")
FIG_DIR <- file.path(EXERCISE_DIR, "figs")
MAN_DIR <- if (nzchar(RUN_ROOT)) file.path(RUN_ROOT, "Manifest") else here::here(CONFIG$OUT_CR$manifest %||% "output/CriticalReplication/Manifest")

dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(LOG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(MAN_DIR, recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(LOG_DIR, paste0("SHAIKH_ARDL_replication_log_", WINDOW_TAG, ".txt"))
sink(log_path, split = TRUE)
on.exit(try(sink(), silent = TRUE), add = TRUE)

cat("=== Shaikh ARDL faithful replication log ===\n")
cat("Timestamp: ", now_stamp(), "\n", sep = "")
cat("Window: ", WINDOW_TAG, " (", min(df0$year), "-", max(df0$year), ")\n\n", sep = "")

# -----------------------------
# 2) Dummies (step / level-shift dummies)
# -----------------------------
DUMMY_YEARS <- c(1956L, 1974L, 1980L)
df0 <- make_step_dummies(df0, DUMMY_YEARS)
dummy_names <- paste0("d", DUMMY_YEARS)
dummy_years <- DUMMY_YEARS

# -----------------------------
# 3) Build two numeraire variants (2011=100 vs 1947=100)
# -----------------------------
build_real_logs <- function(df, p_col) {
  df |>
    mutate(
      p = .data[[p_col]],
      p_scale = p / 100,
      Y_real  = Y_nom / p_scale,
      K_real  = K_nom / p_scale,
      lnY     = log(Y_real),
      lnK     = log(K_real)
    )
}

df_2011 <- build_real_logs(df0, "p2011")
df_1947 <- build_real_logs(df0, "p1947")

# -----------------------------
# 4) Fit ARDL (fixed order replication)
# -----------------------------
ORDER <- c(2, 4)
CASE  <- "uc"  # intercept, no trend

res2011 <- run_one_variant(df_2011, "lnY", "lnK", dummy_names, order = ORDER, case = CASE)
res1947 <- run_one_variant(df_1947, "lnY", "lnK", dummy_names, order = ORDER, case = CASE)

cat("=== Variant A: deflator rebased p(2011)=100 ===\n")
cat("Formula: ", deparse(res2011$fml), "\n", sep = "")
cat("Order (p,q): ", paste(ORDER, collapse = ","), " | CASE=", CASE, "\n\n", sep = "")
print(summary(res2011$fit))
cat("\nBounds F (asympt/exact):\n"); print(res2011$bt$f_asympt); print(res2011$bt$f_exact)
cat("\nBounds t (asympt/exact):\n"); print(res2011$bt$t_asympt); print(res2011$bt$t_exact)

cat("\n=== Variant B: deflator rebased p(1947)=100 ===\n")
cat("Formula: ", deparse(res1947$fml), "\n", sep = "")
cat("Order (p,q): ", paste(ORDER, collapse = ","), " | CASE=", CASE, "\n\n", sep = "")
print(summary(res1947$fit))
cat("\nBounds F (asympt/exact):\n"); print(res1947$bt$f_asympt); print(res1947$bt$f_exact)
cat("\nBounds t (asympt/exact):\n"); print(res1947$bt$t_asympt); print(res1947$bt$t_exact)

# sanity: base-year choice should not change utilization shape if everything cancels correctly
diff_max <- max(abs(res2011$series$u_with - res1947$series$u_with), na.rm = TRUE)
cat("\nSANITY CHECK: max|u_with(2011base)-u_with(1947base)| = ", signif(diff_max, 6), "\n", sep = "")

# -----------------------------
# 5) Export series to CSV
# -----------------------------
out_series <- data.frame(
  year = df0$year,
  u_shaikh = df0$u_shaikh,
  
  u_2011_with_dummy = res2011$series$u_with,
  u_2011_no_dummy   = res2011$series$u_no,
  
  u_1947_with_dummy = res1947$series$u_with,
  u_1947_no_dummy   = res1947$series$u_no
)

out_path <- file.path(CSV_DIR, paste0("SHAIKH_ARDL_replication_series_", WINDOW_TAG, ".csv"))
safe_write_csv(out_series, out_path)
cat("\nWrote series CSV:\n  ", out_path, "\n", sep = "")

# -----------------------------
# 6) Key stats export (LaTeX feed table)
# -----------------------------
Teff <- function(fit) {
  tryCatch(length(residuals(fit)), error = function(e) NA_integer_)
}

bF_2011 <- extract_bt(res2011$bt$f_asympt)
bT_2011 <- extract_bt(res2011$bt$t_asympt)
bF_1947 <- extract_bt(res1947$bt$f_asympt)
bT_1947 <- extract_bt(res1947$bt$t_asympt)

key_stats <- tibble::tibble(
  run_id = paste0("stage4_", format(Sys.time(), "%Y%m%d_%H%M%S")),
  stage_tag = "S1_ARDL_faithful",
  window_tag = WINDOW_TAG,
  
  model = "Shaikh baseline",
  system = "ARDL",
  det_terms = "none",
  lag_structure = "(p=2,q=4)",
  cap_memory = 4 / ((2 - 1) + 4),
  
  N = nrow(df0),
  T_eff_2011 = Teff(res2011$fit),
  T_eff_1947 = Teff(res1947$fit),
  
  logLik_2011 = tryCatch(as.numeric(logLik(res2011$fit)), error = function(e) NA_real_),
  logLik_1947 = tryCatch(as.numeric(logLik(res1947$fit)), error = function(e) NA_real_),
  
  k_total_2011 = tryCatch(attr(logLik(res2011$fit), "df"), error = function(e) NA_real_),
  k_total_1947 = tryCatch(attr(logLik(res1947$fit), "df"), error = function(e) NA_real_),
  
  boundsF_stat_2011 = bF_2011$stat,
  boundsF_p_2011    = bF_2011$pval,
  boundsT_stat_2011 = bT_2011$stat,
  boundsT_p_2011    = bT_2011$pval,
  
  boundsF_stat_1947 = bF_1947$stat,
  boundsF_p_1947    = bF_1947$pval,
  boundsT_stat_1947 = bT_1947$stat,
  boundsT_p_1947    = bT_1947$pval,
  
  lambda_hat_2011 = res2011$lambda_hat,
  lambda_hat_1947 = res1947$lambda_hat,
  
  max_abs_u_with_diff = diff_max
)

key_path <- file.path(CSV_DIR, paste0("SHAIKH_ARDL_replication_key_stats_", WINDOW_TAG, ".csv"))
safe_write_csv(key_stats, key_path)
cat("\nWrote key-stats CSV:\n  ", key_path, "\n", sep = "")

# -----------------------------
# 7) Plot (comparison across rebases + Shaikh series)
# -----------------------------
df_plot <- out_series |>
  pivot_longer(
    cols = c(df0$u_shaikh, u_2011_with_dummy, u_2011_no_dummy, u_1947_with_dummy, u_1947_no_dummy),
    names_to = "series",
    values_to = "u"
  ) |>
  mutate(
    group = case_when(
      series == "u_shaikh" ~ "Shaikh (2016)",
      grepl("^u_2011_", series) ~ "Replication: p(2011)=100",
      grepl("^u_1947_", series) ~ "Replication: p(1947)=100",
      TRUE ~ "other"
    ),
    label = case_when(
      series == "u_shaikh" ~ "Shaikh (2016)",
      grepl("_with_dummy$", series) ~ "Replication (LR step dummies in Y^p)",
      grepl("_no_dummy$", series) ~ "Replication (no LR dummies in Y^p)",
      TRUE ~ series
    ),
    lty = case_when(
      label == "Replication (LR step dummies in Y^p)" ~ "dashed",
      TRUE ~ "solid"
    )
  )

plot_u <- ggplot(df_plot, aes(x = year, y = u, color = label, linetype = lty)) +
  geom_line(size = 0.9, na.rm = TRUE) +
  geom_hline(yintercept = 1, alpha = 0.35) +
  geom_vline(xintercept = dummy_years, linetype = "dashed", alpha = 0.5) +
  facet_wrap(~ group, ncol = 1) +
  theme_minimal(base_size = 12) +
  theme(
    legend.title = element_blank(),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  ) +
  labs(x = "Year", y = "Capacity Utilization (u)", linetype = NULL)

print(plot_u)

fig_path <- file.path(FIG_DIR, paste0("FIG_SHAIKH_ARDL_u_", WINDOW_TAG, ".png"))
ggsave(fig_path, plot_u, width = 10, height = 6.2, dpi = 300)

cat("\nSaved figure:\n  ", fig_path, "\n", sep = "")
cat("Saved log:\n  ", log_path, "\n", sep = "")



# -----------------------------
# 7.5) Correlation diagnostics vs Shaikh (levels + first differences)
# -----------------------------
if (!all(is.na(df_plot$u_shaikh))) {
  
  # levels
  ok_lvl <- is.finite(df_plot$u_shaikh) & is.finite(df_plot$u_with_dummy) & is.finite(df_plot$u_no_dummy)
  
  cor_lvl_with <- cor(df_plot$u_with_dummy[ok_lvl], df_plot$u_shaikh[ok_lvl])
  cor_lvl_no   <- cor(df_plot$u_no_dummy[ok_lvl],   df_plot$u_shaikh[ok_lvl])
  
  # first differences (Δu)
  du_shaikh <- c(NA_real_, diff(df_plot$u_shaikh))
  du_with   <- c(NA_real_, diff(df_plot$u_with_dummy))
  du_no     <- c(NA_real_, diff(df_plot$u_no_dummy))
  
  ok_d <- is.finite(du_shaikh) & is.finite(du_with) & is.finite(du_no)
  
  cor_du_with <- cor(du_with[ok_d], du_shaikh[ok_d])
  cor_du_no   <- cor(du_no[ok_d],   du_shaikh[ok_d])
  
  cat("\n--- Correlation vs Shaikh (2016) ---\n")
  cat("N (levels)  = ", sum(ok_lvl), "\n", sep = "")
  cat("N (diffs)   = ", sum(ok_d),   "\n", sep = "")
  cat("cor(u_with_dummy, u_shaikh) = ", round(cor_lvl_with, 4), "\n", sep = "")
  cat("cor(u_no_dummy,   u_shaikh) = ", round(cor_lvl_no,   4), "\n", sep = "")
  cat("cor(Δu_with_dummy, Δu_shaikh) = ", round(cor_du_with, 4), "\n", sep = "")
  cat("cor(Δu_no_dummy,   Δu_shaikh) = ", round(cor_du_no,   4), "\n", sep = "")
  
} else {
  cat("\nNOTE: u_shaikh missing/NA; skipping correlation diagnostics.\n")
}

corr_out <- data.frame(
  window_tag = WINDOW_TAG,
  N_levels = if (exists("ok_lvl")) sum(ok_lvl) else NA_integer_,
  N_diffs  = if (exists("ok_d"))   sum(ok_d)   else NA_integer_,
  cor_lvl_with = if (exists("cor_lvl_with")) cor_lvl_with else NA_real_,
  cor_lvl_no   = if (exists("cor_lvl_no"))   cor_lvl_no   else NA_real_,
  cor_du_with  = if (exists("cor_du_with"))  cor_du_with  else NA_real_,
  cor_du_no    = if (exists("cor_du_no"))    cor_du_no    else NA_real_
)

safe_write_csv(corr_out, file.path(CSV_DIR, paste0("DIAG_corr_vs_shaikh_", WINDOW_TAG, ".csv")))
cat("Wrote CSV:\n  ", file.path(CSV_DIR, paste0("DIAG_corr_vs_shaikh_", WINDOW_TAG, ".csv")), "\n", sep = "")

# -----------------------------
# 8) Manifest append
# -----------------------------
manifest_path <- file.path(MAN_DIR, "RUN_MANIFEST_stage4.md")
cat(
  paste0(
    "# Run Manifest (Stage 4)\n",
    "- window_tag: ", WINDOW_TAG, "\n",
    "- window_start: ", WINDOW_START, "\n",
    "- window_end: ", WINDOW_END, "\n",
    "- script: codes/20_shaikh_ardl_replication_WRAPPED.R\n",
    "- outputs:\n",
    "  - ", out_path, "\n",
    "  - ", key_path, "\n",
    "  - ", fig_path, "\n",
    "  - ", log_path, "\n",
    "- Timestamp: ", Sys.time(), "\n\n"
  ),
  file = manifest_path,
  append = TRUE
)

cat("\nAppended manifest:\n  ", manifest_path, "\n", sep = "")