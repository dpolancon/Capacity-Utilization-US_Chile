# ============================================================
# 20_shaikh_ardl_replication.R  (PATCH CONSOLIDATE v2)
#
# Study A — Shaikh faithful ARDL replication + CASE TOGGLE (1–5)
#
# LOCKED OBJECTIVE (Study A):
#   - Fix lag structure at (p,q) = (2,4)
#   - Run ALL 5 PSS/ARDL “cases” (1..5) for the SAME (2,4) spec
#   - Admissibility gate for inclusion in the main comparison figure:
#         PASS bounds F-test (cointegration gate)
#   - t-bounds test:
#         reported for all cases BUT “robustness star” only applies when
#         t-bounds is admissible (cases 1,3,5 per your lockdown)
#   - Figure: Shaikh u vs replication u for all F-admissible cases
#            with legend stars for t-bounds robustness (1/5/10%).
#   - Tables (CSV + optional LaTeX feed):
#        (i) Case contest table (ALL cases, levels not deltas):
#            F and t bounds stats/pvals + stars, theta + stars, alpha (UECM)
#        (ii) Coefficient summary table for ALL cases (LR multipliers + scaled LR dummies)
#
# Uses:
#   - CONFIG from codes/10_config.R
#   - utilities from codes/99_utils.R (safe_write_csv, now_stamp, %||%, add_stars if present)
#
# Outputs (under Exercise_a_ARDL_faithful):
#   - csv/SHAIKH_ARDL_case_contest_shaikh_window.csv
#   - csv/SHAIKH_ARDL_coef_table_shaikh_window.csv
#   - csv/SHAIKH_ARDL_u_cases_shaikh_window.csv
#   - figs/FIG_S1_ARDL_u_compare_cases_Fpass_shaikh_window.png
#   - logs/SHAIKH_ARDL_replication_log_shaikh_window.txt
#   - Manifest/RUN_MANIFEST_stage4.md (append)
# ============================================================

rm(list = ls())

suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(stringr)
  library(ARDL)
  library(ggplot2)
})

# ------------------------------------------------------------
# Load CONFIG + UTILS (repo-native)
# ------------------------------------------------------------
source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))

stopifnot(exists("CONFIG"))
stopifnot(is.list(CONFIG))

# ------------------------------------------------------------
# LOCKED TOGGLES (Study A)
# ------------------------------------------------------------
WINDOW_TAG <- "shaikh_window"
ORDER      <- c(2, 4)     # (p,q) locked
CASES      <- 1:5         # PSS cases 1..5
EXACT_TEST <- FALSE       # FALSE = asymptotic; TRUE = in-sample (exact=TRUE)

# Admissibility for t-bounds robustness labeling (your lockdown)
T_BOUNDS_ADMISSIBLE_CASES <- c(1, 3, 5)

# F-gate alpha (used only for flagging; p-values still reported)
F_GATE_ALPHA <- 0.10

# Step dummies (kept as in your current script)
DUMMY_YEARS <- c(1956L, 1974L, 1980L)

# ------------------------------------------------------------
# Helpers (local)
# ------------------------------------------------------------
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

# stars helper: prefer your utils add_stars(); fallback local
stars_from_p <- function(p) {
  if (!is.finite(p)) return("")
  if (p <= 0.01) return("***")
  if (p <= 0.05) return("**")
  if (p <= 0.10) return("*")
  ""
}

# LR multipliers + scaled LR dummy multipliers (since dummies enter outside LR relation but have LR multipliers)
get_lr_table_with_scaled_dummies <- function(fit_ardl, lnY_name = "lnY", dummy_names = character()) {
  lr_mult <- ARDL::multipliers(fit_ardl, type = "lr")
  
  coefs <- coef(fit_ardl)
  # denominator: 1 - sum phi_i on lagged dependent variable
  den <- 1 - sum(coefs[grep(paste0("^L\\(", lnY_name, ","), names(coefs))])
  
  dummy_table <- NULL
  if (length(dummy_names)) {
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
  }
  
  lr_full_table <- if (!is.null(dummy_table)) rbind(lr_mult, dummy_table) else lr_mult
  list(lr_full_table = lr_full_table, den = den)
}

extract_lr_row <- function(lr_full, term) {
  if (is.null(lr_full) || !("Term" %in% names(lr_full))) return(list(est = NA_real_, p = NA_real_))
  rr <- lr_full[lr_full$Term == term, , drop = FALSE]
  if (nrow(rr) == 0) return(list(est = NA_real_, p = NA_real_))
  p_col <- intersect(c("Pr(>|t|)", "Pr...t..", "p.value", "p_value"), names(rr))[1]
  list(
    est = suppressWarnings(as.numeric(rr$Estimate[1])),
    p = if (!is.na(p_col)) suppressWarnings(as.numeric(rr[[p_col]][1])) else NA_real_
  )
}

# Extract alpha (speed) from UECM coefficient on L(lnY,1)
extract_alpha_from_uecm <- function(fit_ardl, lnY_name = "lnY") {
  uecm_model <- ARDL::uecm(fit_ardl)
  uecm_coef <- tryCatch(summary(uecm_model)$coefficients, error = function(e) NULL)
  if (is.null(uecm_coef)) return(NA_real_)
  rr <- grep(paste0("^L\\(", lnY_name, ", 1\\)$"), rownames(uecm_coef), value = TRUE)
  if (length(rr) == 1) return(as.numeric(uecm_coef[rr, "Estimate"]))
  NA_real_
}

# Build u and lnY^p from LR object:
# lnY^p = a + theta lnK + sum_j lr_dummy_j * d_j
compute_u_from_lr <- function(df, lnY_name, lnK_name, lr_full, dummy_names) {
  a_lr <- lr_full$Estimate[lr_full$Term == "(Intercept)"]
  theta_lr <- lr_full$Estimate[lr_full$Term == lnK_name]
  
  dummy_coef <- if (length(dummy_names)) lr_full$Estimate[match(dummy_names, lr_full$Term)] else numeric(0)
  dummy_effect <- if (length(dummy_names)) rowSums(df[dummy_names] * dummy_coef) else 0
  
  lnY  <- df[[lnY_name]]
  lnK  <- df[[lnK_name]]
  lnYp <- a_lr + theta_lr * lnK + dummy_effect
  u    <- exp(lnY - lnYp)
  
  list(u = u, lnYp = lnYp, intercept = a_lr, theta = theta_lr)
}

# ------------------------------------------------------------
# 0) Load dataset (CONFIG) + build deflator base 2011 only
# ------------------------------------------------------------
df_raw <- readxl::read_excel(here::here(CONFIG$data_shaikh), sheet = CONFIG$data_shaikh_sheet)
stopifnot(all(c(CONFIG$year_col, CONFIG$y_nom, CONFIG$k_nom, CONFIG$p_index) %in% names(df_raw)))

# ledger for p rebase (fail fast)
p_ledger <- df_raw |>
  transmute(
    year  = as.integer(.data[[CONFIG$year_col]]),
    p_raw = as.numeric(.data[[CONFIG$p_index]])
  ) |>
  filter(is.finite(year), is.finite(p_raw), p_raw > 0) |>
  arrange(year)

stopifnot(any(p_ledger$year == 2011L))

p_ledger <- p_ledger |>
  mutate(p2011 = rebase_to_year_to_100(p_raw, year, 2011L, strict = TRUE)) |>
  select(year, p2011)

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

stopifnot(all(is.finite(df0$p2011)))

# ------------------------------------------------------------
# 1) Window lock
# ------------------------------------------------------------
w <- CONFIG$WINDOWS_LOCKED[[WINDOW_TAG]]
stopifnot(!is.null(w), length(w) == 2)

WINDOW_START <- as.integer(w[1])
WINDOW_END   <- as.integer(w[2])

df0 <- df0 |>
  filter(year >= w[1], year <= w[2]) |>
  arrange(year)

# ------------------------------------------------------------
# 2) Output dirs + log sink (CONFIG)
# ------------------------------------------------------------
EXERCISE_DIR <- here::here(CONFIG$OUT_CR$exercise_a %||% "output/CriticalReplication/Exercise_a_ARDL_faithful")
CSV_DIR <- file.path(EXERCISE_DIR, "csv")
LOG_DIR <- file.path(EXERCISE_DIR, "logs")
FIG_DIR <- file.path(EXERCISE_DIR, "figs")
MAN_DIR <- here::here(CONFIG$OUT_CR$manifest %||% "output/CriticalReplication/Manifest")

dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(LOG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(MAN_DIR, recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(LOG_DIR, paste0("SHAIKH_ARDL_replication_log_", WINDOW_TAG, ".txt"))
sink(log_path, split = TRUE)
on.exit(try(sink(), silent = TRUE), add = TRUE)

cat("=== Shaikh ARDL replication — CASE TOGGLE (Study A) ===\n")
cat("Timestamp: ", now_stamp(), "\n", sep = "")
cat("Window:    ", WINDOW_TAG, " (", min(df0$year), "-", max(df0$year), ")\n", sep = "")
cat("Order:     (p,q) = (", paste(ORDER, collapse = ","), ")\n", sep = "")
cat("Cases:     ", paste(CASES, collapse = ","), "\n", sep = "")
cat("Bounds:    exact=", EXACT_TEST, " (FALSE=asymptotic; TRUE=in-sample)\n\n", sep = "")

# ------------------------------------------------------------
# 3) Dummies + build real logs (base 2011 only)
# ------------------------------------------------------------
df0 <- make_step_dummies(df0, DUMMY_YEARS)
dummy_names <- paste0("d", DUMMY_YEARS)

df <- df0 |>
  mutate(
    p = p2011,
    p_scale = p / 100,
    Y_real  = Y_nom / p_scale,
    K_real  = K_nom / p_scale,
    lnY     = log(Y_real),
    lnK     = log(K_real)
  )

# ------------------------------------------------------------
# 4) Run one CASE (bounded tests + LR + u)
# ------------------------------------------------------------
run_one_case <- function(df, case_id, order, dummy_names, exact_test) {
  df_ts <- ts(df |> select(all_of(c("lnY", "lnK", dummy_names))),
              start = min(df$year), frequency = 1)
  
  # ARDL formula: lnY ~ lnK | dummies
  fml <- as.formula(paste0("lnY ~ lnK | ", paste(dummy_names, collapse = " + ")))
  fit <- ARDL::ardl(formula = fml, data = df_ts, order = order)
  
  # bounds tests (F always; t returned but robustness-star only for cases 1,3,5)
  bt_f <- ARDL::bounds_f_test(fit, case = case_id, alpha = 0.05, pvalue = TRUE, exact = exact_test)
  bt_t <- ARDL::bounds_t_test(fit, case = case_id, alpha = 0.05, pvalue = TRUE, exact = exact_test)
  
  bF <- extract_bt(bt_f)
  bT <- extract_bt(bt_t)
  
  # LR multipliers + LR dummy scaling
  lr_pack <- get_lr_table_with_scaled_dummies(fit, lnY_name = "lnY", dummy_names = dummy_names)
  lr_full <- lr_pack$lr_full_table
  
  theta <- extract_lr_row(lr_full, "lnK")
  intercept <- extract_lr_row(lr_full, "(Intercept)")
  alpha_hat <- extract_alpha_from_uecm(fit, lnY_name = "lnY")
  
  # series
  series <- compute_u_from_lr(df, "lnY", "lnK", lr_full, dummy_names)
  
  list(
    case_id = case_id,
    fml     = fml,
    fit     = fit,
    bt_f    = bF,
    bt_t    = bT,
    lr_full = lr_full,
    theta   = theta,
    intercept = intercept,
    alpha_hat = alpha_hat,
    u = series$u,
    lnYp = series$lnYp
  )
}

# ------------------------------------------------------------
# 5) Execute all cases
# ------------------------------------------------------------
results <- lapply(CASES, function(cc) {
  cat("------------------------------------------------------------\n")
  cat("CASE ", cc, " | order=", paste(ORDER, collapse=","), " | exact=", EXACT_TEST, "\n", sep="")
  out <- run_one_case(df, case_id = cc, order = ORDER, dummy_names = dummy_names, exact_test = EXACT_TEST)
  cat("Formula: ", deparse(out$fml), "\n", sep="")
  print(summary(out$fit))
  cat("\nBounds F:\n"); print(ARDL::bounds_f_test(out$fit, case = cc, alpha = 0.05, pvalue = TRUE, exact = EXACT_TEST))
  cat("\nBounds t:\n"); print(ARDL::bounds_t_test(out$fit, case = cc, alpha = 0.05, pvalue = TRUE, exact = EXACT_TEST))
  cat("\nTheta (LR lnK): ", signif(out$theta$est, 6), " | p=", signif(out$theta$p, 6), "\n", sep="")
  cat("Alpha (UECM L(lnY,1)): ", signif(out$alpha_hat, 6), "\n", sep="")
  out
})

# ------------------------------------------------------------
# 6) Build contest table (LEVELS, not deltas) — ALL cases
# ------------------------------------------------------------
contest <- tibble(
  window_tag = WINDOW_TAG,
  order_p = ORDER[1],
  order_q = ORDER[2],
  exact_test = EXACT_TEST,
  case_id = sapply(results, `[[`, "case_id"),
  
  boundsF_stat = sapply(results, function(x) x$bt_f$stat),
  boundsF_p    = sapply(results, function(x) x$bt_f$pval),
  
  boundsT_stat = sapply(results, function(x) x$bt_t$stat),
  boundsT_p    = sapply(results, function(x) x$bt_t$pval),
  
  theta_hat    = sapply(results, function(x) x$theta$est),
  theta_p      = sapply(results, function(x) x$theta$p),
  
  alpha_hat    = sapply(results, function(x) x$alpha_hat),
  
  # Admissibility / robustness flags
  F_pass = (boundsF_p <= F_GATE_ALPHA),
  t_admissible = case_id %in% T_BOUNDS_ADMISSIBLE_CASES,
  t_pass_10 = if_else(t_admissible, boundsT_p <= 0.10, NA),
  t_pass_05 = if_else(t_admissible, boundsT_p <= 0.05, NA),
  t_pass_01 = if_else(t_admissible, boundsT_p <= 0.01, NA)
) |>
  mutate(
    boundsF_stars = map_chr(boundsF_p, stars_from_p),
    boundsT_stars = if_else(t_admissible, map_chr(boundsT_p, stars_from_p), ""),
    theta_stars   = map_chr(theta_p, stars_from_p),
    
    # Legend robustness stars: only meaningful if F_pass AND t_admissible
    robust_star = case_when(
      F_pass & t_admissible & boundsT_p <= 0.01 ~ "***",
      F_pass & t_admissible & boundsT_p <= 0.05 ~ "**",
      F_pass & t_admissible & boundsT_p <= 0.10 ~ "*",
      TRUE ~ ""
    )
  )

contest_path <- file.path(CSV_DIR, paste0("SHAIKH_ARDL_case_contest_", WINDOW_TAG, ".csv"))
safe_write_csv(contest, contest_path)
cat("\nWrote contest CSV:\n  ", contest_path, "\n", sep="")

# ------------------------------------------------------------
# 7) Coefficient table (LR multipliers table per case)
# ------------------------------------------------------------
coef_tbl <- purrr::map_dfr(results, function(x) {
  lr <- x$lr_full
  lr |>
    mutate(
      case_id = x$case_id,
      order_p = ORDER[1],
      order_q = ORDER[2],
      exact_test = EXACT_TEST,
      window_tag = WINDOW_TAG
    ) |>
    select(window_tag, case_id, order_p, order_q, exact_test, everything())
})

coef_path <- file.path(CSV_DIR, paste0("SHAIKH_ARDL_coef_table_", WINDOW_TAG, ".csv"))
safe_write_csv(coef_tbl, coef_path)
cat("Wrote coef CSV:\n  ", coef_path, "\n", sep="")

# ------------------------------------------------------------
# 8) Build u-series wide CSV: Shaikh + u_caseX (ALL cases)
# ------------------------------------------------------------
u_cases <- tibble(year = df$year, u_shaikh = df$u_shaikh)
for (x in results) {
  u_cases[[paste0("u_case", x$case_id)]] <- x$u
}
u_cases_path <- file.path(CSV_DIR, paste0("SHAIKH_ARDL_u_cases_", WINDOW_TAG, ".csv"))
safe_write_csv(u_cases, u_cases_path)
cat("Wrote u-cases CSV:\n  ", u_cases_path, "\n", sep="")

# ------------------------------------------------------------
# 9) Main comparison figure:
#     Shaikh u + ALL cases that pass F gate
#     Legend includes robustness stars (from t-bounds) only for cases 1/3/5
# ------------------------------------------------------------
plot_long <- u_cases |>
  pivot_longer(-c(year, u_shaikh), names_to = "series", values_to = "u") |>
  mutate(
    case_id = as.integer(str_extract(series, "\\d+"))
  ) |>
  left_join(contest |> select(case_id, F_pass, t_admissible, robust_star), by = "case_id") |>
  filter(F_pass) |>
  mutate(
    label = case_when(
      is.na(case_id) ~ series,
      t_admissible ~ paste0("Case ", case_id, " (F-pass, t-robust ", robust_star, ")"),
      TRUE ~ paste0("Case ", case_id, " (F-pass, t n/a)")
    )
  )

shaikh_df <- tibble(year = df$year, u = df$u_shaikh, label = "Shaikh (2016)")

plot_df <- bind_rows(
  shaikh_df,
  plot_long |> select(year, u, label)
) |>
  filter(is.finite(u))

p <- ggplot(plot_df, aes(x = year, y = u, color = label, linetype = label)) +
  geom_line(linewidth = 0.9, na.rm = TRUE) +
  geom_hline(yintercept = 1, alpha = 0.35) +
  geom_vline(xintercept = DUMMY_YEARS, linetype = "dashed", alpha = 0.45) +
  theme_minimal(base_size = 12) +
  theme(
    legend.title = element_blank(),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1)
  ) +
  labs(
    x = "Year",
    y = "Capacity Utilization (u)",
    title = paste0(
      "Shaikh replication | ARDL(", ORDER[1], ",", ORDER[2], ") | F-pass cases only | base p(2011)=100"
    ),
    subtitle = "Legend robustness stars apply only when t-bounds is admissible (cases 1,3,5) and F-pass"
  )

fig_path <- file.path(FIG_DIR, paste0("FIG_S1_ARDL_u_compare_cases_Fpass_", WINDOW_TAG, ".png"))
ggsave(fig_path, p, width = 11, height = 6.6, dpi = 300)
cat("Saved figure:\n  ", fig_path, "\n", sep="")

# ------------------------------------------------------------
# 10) Manifest append
# ------------------------------------------------------------
manifest_path <- file.path(MAN_DIR, "RUN_MANIFEST_stage4.md")
cat(
  paste0(
    "# Run Manifest (Stage 4)\n",
    "- stage: Study A (ARDL faithful + cases)\n",
    "- window_tag: ", WINDOW_TAG, "\n",
    "- window_start: ", WINDOW_START, "\n",
    "- window_end: ", WINDOW_END, "\n",
    "- script: codes/20_shaikh_ardl_replication.R\n",
    "- order_pq: (", paste(ORDER, collapse=","), ")\n",
    "- cases: ", paste(CASES, collapse=","), "\n",
    "- exact_test: ", EXACT_TEST, "\n",
    "- outputs:\n",
    "  - ", contest_path, "\n",
    "  - ", coef_path, "\n",
    "  - ", u_cases_path, "\n",
    "  - ", fig_path, "\n",
    "  - ", log_path, "\n",
    "- Timestamp: ", Sys.time(), "\n\n"
  ),
  file = manifest_path,
  append = TRUE
)

cat("\nAppended manifest:\n  ", manifest_path, "\n", sep = "")
cat("\nDONE.\n")