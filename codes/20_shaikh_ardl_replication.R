# ============================================================
# 20_shaikh_ardl_replication_WRAPPED.R  (PATCH CONSOLIDATE)
#
# Wrap-up runner:
#  - console results + full log capture (sink split=TRUE)
#  - CSV export of replication series
#  - single minimal ggplot (with/without LR dummies + Shaikh series if present)
#
# Outputs:
#  - output/CU_estimates_compare/csv/SHAIKH_ARDL_replication_series_shaikh_window.csv
#  - output/CU_estimates_compare/logs/SHAIKH_ARDL_replication_log_shaikh_window.txt
#  - output/CU_estimates_compare/figs/FIG_SHAIKH_ARDL_u_shaikh_window.png
# ============================================================

rm(list = ls())

suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(ARDL)
  library(ggplot2)
})

# --- load CONFIG + utils (RENAMED) ---
source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))

# -----------------------------
# 0) Load Shaikh replication dataset
# -----------------------------
df_raw <- readxl::read_excel(here::here(CONFIG$data_shaikh), sheet = CONFIG$data_shaikh_sheet)

stopifnot(all(c(CONFIG$year_col, CONFIG$y_nom, CONFIG$k_nom, CONFIG$p_index) %in% names(df_raw)))

df <- df_raw |>
  transmute(
    year    = as.integer(.data[[CONFIG$year_col]]),
    Y_nom   = as.numeric(.data[[CONFIG$y_nom]]),
    K_nom   = as.numeric(.data[[CONFIG$k_nom]]),
    p       = as.numeric(.data[[CONFIG$p_index]]),
    u_shaikh = if ("u_shaikh" %in% names(df_raw)) as.numeric(.data[["u_shaikh"]]) else NA_real_
  ) |>
  filter(is.finite(year), is.finite(Y_nom), is.finite(K_nom), is.finite(p), p > 0) |>
  mutate(
    p_scale = p / 100,
    Y_real  = Y_nom / p_scale,
    K_real  = K_nom / p_scale,
    lnY     = log(Y_real),
    lnK     = log(K_real)
  ) |>
  arrange(year)

# -----------------------------
# 1) Window lock
# -----------------------------
WINDOW_TAG <- "shaikh_window"
w <- CONFIG$WINDOWS_LOCKED[[WINDOW_TAG]]
df <- df |>
  filter(year >= w[1], year <= w[2]) |>
  arrange(year)

# -----------------------------
# 1.5) Output dirs + log sink (console + file)
# -----------------------------
CSV_DIR <- here::here("output", "CU_estimates_compare", "csv")
LOG_DIR <- here::here("output", "CU_estimates_compare", "logs")
FIG_DIR <- here::here("output", "CU_estimates_compare", "figs")

dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(LOG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)

log_path <- file.path(LOG_DIR, paste0("SHAIKH_ARDL_replication_log_", WINDOW_TAG, ".txt"))
sink(log_path, split = TRUE)
on.exit(try(sink(), silent = TRUE), add = TRUE)

cat("=== Shaikh ARDL replication log ===\n")
cat("Timestamp: ", now_stamp(), "\n", sep = "")

# -----------------------------
# 2) Dummies (edit as needed)
# -----------------------------
DUMMY_YEARS <- c(1956L, 1974L, 1980L)
for (yy in DUMMY_YEARS) df[[paste0("d", yy)]] <- as.integer(df$year == yy)
dummy_names <- paste0("d", DUMMY_YEARS)
dummy_years <- DUMMY_YEARS

# -----------------------------
# 3) Fit ARDL (fixed order replication)
# -----------------------------
df_ts <- ts(df |> select(lnY, lnK, all_of(dummy_names)),
            start = min(df$year), frequency = 1)

ORDER <- c(2, 4)
fml <- as.formula(paste0("lnY ~ lnK | ", paste(dummy_names, collapse = " + ")))

fit_ardl <- ARDL::ardl(formula = fml, data = df_ts, order = ORDER)

# -----------------------------
# 4) Bounds tests (CASE aligned with deterministics)
# intercept, no trend -> "uc"
# -----------------------------
CASE <- "uc"

bt_f_asympt <- ARDL::bounds_f_test(fit_ardl, case = CASE, alpha = 0.05, pvalue = TRUE, exact = FALSE)
bt_f_exact  <- ARDL::bounds_f_test(fit_ardl, case = CASE, alpha = 0.05, pvalue = TRUE, exact = TRUE)

bt_t_asympt <- ARDL::bounds_t_test(fit_ardl, case = CASE, alpha = 0.05, pvalue = TRUE, exact = FALSE)
bt_t_exact  <- ARDL::bounds_t_test(fit_ardl, case = CASE, alpha = 0.05, pvalue = TRUE, exact = TRUE)

# -----------------------------
# 5) Long-run multipliers (package) + dummy LR multipliers (scaled)
# -----------------------------
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
  `Pr(>|t|)`   = as.numeric(p_lr)
)

names(dummy_table) <- names(lr_mult)
lr_full_table <- rbind(lr_mult, dummy_table)

# -----------------------------
# 6) Build lnY^p and utilization series
#    (A) With LR dummies (Shaikh-style)
#    (B) Without LR dummies
# -----------------------------
a_lr <- lr_full_table$Estimate[lr_full_table$Term == "(Intercept)"]
b_lr <- lr_full_table$Estimate[lr_full_table$Term == "lnK"]

dummy_coef   <- lr_full_table$Estimate[match(dummy_names, lr_full_table$Term)]
dummy_effect <- rowSums(df[dummy_names] * dummy_coef)

lnYp_hat_with_dummies <- a_lr + b_lr * df$lnK + dummy_effect
lnYp_hat_no_dummies   <- a_lr + b_lr * df$lnK

u_hat_with_dummies <- exp(df$lnY - lnYp_hat_with_dummies)
u_hat_no_dummies   <- exp(df$lnY - lnYp_hat_no_dummies)

# -----------------------------
# 7) Console wrap-up (captured to log too)
# -----------------------------
cat("\n=== Shaikh ARDL replication (fixed order) ===\n")
cat("Window: ", WINDOW_TAG, " (", min(df$year), "-", max(df$year), ")\n", sep = "")
cat("Formula: ", deparse(fml), "\n", sep = "")
cat("Order (p,q): ", paste(ORDER, collapse = ","), "\n", sep = "")
cat("CASE: ", CASE, "\n", sep = "")

cat("\n--- ARDL summary ---\n")
print(summary(fit_ardl))

cat("\n--- Bounds F test ---\n")
print(bt_f_asympt)
print(bt_f_exact)

cat("\n--- Bounds t test ---\n")
print(bt_t_asympt)
print(bt_t_exact)

cat("\n--- Long-run multipliers (including scaled dummies) ---\n")
print(lr_full_table)

cat("\n--- Utilization diagnostics ---\n")
cat("mean(u_with_dummies) = ", round(mean(u_hat_with_dummies, na.rm = TRUE), 4), "\n", sep = "")
cat("sd(u_with_dummies)   = ", round(sd(u_hat_with_dummies,   na.rm = TRUE), 4), "\n", sep = "")
cat("mean(u_no_dummies)   = ", round(mean(u_hat_no_dummies,   na.rm = TRUE), 4), "\n", sep = "")
cat("sd(u_no_dummies)     = ", round(sd(u_hat_no_dummies,     na.rm = TRUE), 4), "\n", sep = "")

if ("u_shaikh" %in% names(df)) {
  cat("\n--- Correlation with Shaikh series ---\n")
  cat("cor(u_with_dummies, u_shaikh) = ", round(cor(u_hat_with_dummies, df$u_shaikh, use = "complete.obs"), 4), "\n", sep = "")
  cat("cor(u_no_dummies,   u_shaikh) = ", round(cor(u_hat_no_dummies,   df$u_shaikh, use = "complete.obs"), 4), "\n", sep = "")
} else {
  cat("\nNOTE: df$u_shaikh not found, skipping Shaikh comparison.\n")
}

# -----------------------------
# RECM / UECM extraction (speed of adjustment λ)
# -----------------------------
uecm_model <- ARDL::uecm(fit_ardl)

cat("\n--- UECM summary ---\n")
print(summary(uecm_model))

print_lambda <- function(model_obj,
                         ect_pattern = "^L\\(lnY, 1\\)$",
                         model_label = "UECM") {
  
  coefs <- summary(model_obj)$coefficients
  ect_row <- grep(ect_pattern, rownames(coefs), value = TRUE)
  
  if (length(ect_row) == 1) {
    
    lambda_hat <- coefs[ect_row, "Estimate"]
    lambda_se  <- coefs[ect_row, "Std. Error"]
    lambda_t   <- coefs[ect_row, "t value"]
    lambda_p   <- coefs[ect_row, "Pr(>|t|)"]
    
    cat("\n--- Error-Correction Term (λ) [", model_label, "] ---\n", sep = "")
    cat("λ (ECT coefficient) = ", round(lambda_hat, 6), "\n", sep = "")
    cat("Std. Error          = ", round(lambda_se, 6), "\n", sep = "")
    cat("t-value             = ", round(lambda_t, 4), "\n", sep = "")
    cat("p-value             = ", round(lambda_p, 6), "\n", sep = "")
    
    if (is.finite(lambda_hat) && lambda_hat < 0) {
      half_life <- log(0.5) / log(1 + lambda_hat)
      cat("Implied half-life (years) ≈ ", round(half_life, 2), "\n", sep = "")
    }
    
  } else {
    cat("\nECT term not uniquely identified in ", model_label,
        ". Check rownames(summary(model_obj)$coefficients).\n", sep = "")
  }
}

cat("\n--- RECM (candidate A): intercept unrestricted (short-run) ---\n")
recm_A <- ARDL::recm(fit_ardl, case = 3)
print(summary(recm_A))

cat("\n--- RECM (candidate B): intercept in long-run (inside ECT) ---\n")
recm_B <- ARDL::recm(fit_ardl, case = 2)
print(summary(recm_B))

print_lambda(uecm_model, ect_pattern = "^L\\(lnY, 1\\)$", model_label = "UECM")
print_lambda(recm_A,     ect_pattern = "^ect$",          model_label = "RECM Case 3")
print_lambda(recm_B,     ect_pattern = "^ect$",          model_label = "RECM Case 2")

# -----------------------------
# 8) Export series to CSV
# -----------------------------
out_path <- file.path(CSV_DIR, paste0("SHAIKH_ARDL_replication_series_", WINDOW_TAG, ".csv"))

out_df <- data.frame(
  year         = df$year,
  u_with_dummy = u_hat_with_dummies,
  u_no_dummy   = u_hat_no_dummies
)
if ("u_shaikh" %in% names(df)) out_df$u_shaikh <- df$u_shaikh

safe_write_csv(out_df, out_path)
cat("\nWrote CSV:\n  ", out_path, "\n", sep = "")

# -----------------------------
# 9) Single minimalistic plot + save PNG
# -----------------------------
df_plot <- data.frame(
  year         = df$year,
  u_with_dummy = u_hat_with_dummies,
  u_no_dummy   = u_hat_no_dummies,
  u_shaikh     = if ("u_shaikh" %in% names(df)) df$u_shaikh else NA_real_
)

plot_u <- ggplot(df_plot, aes(x = year)) +
  geom_line(aes(y = u_shaikh, color = "Shaikh (2016)"), size = 0.9, na.rm = TRUE) +
  geom_line(aes(y = u_with_dummy, color = "Replication (LR dummies in Y^p)"),
            linetype = "dashed", size = 0.8, na.rm = TRUE) +
  geom_line(aes(y = u_no_dummy, color = "Replication (no LR dummies in Y^p)"),
            size = 0.8, na.rm = TRUE) +
  geom_hline(yintercept = 1, linetype = "solid", alpha = 0.4) +
  geom_vline(xintercept = dummy_years, linetype = "dashed", alpha = 0.6) +
  theme_minimal(base_size = 12) +
  theme(
    legend.title = element_blank(),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid = element_blank()
  ) +
  labs(x = "Year", y = "Capacity Utilization (u)")

print(plot_u)

fig_path <- file.path(FIG_DIR, paste0("FIG_SHAIKH_ARDL_u_", WINDOW_TAG, ".png"))
ggsave(fig_path, plot_u, width = 10, height = 4.5, dpi = 300)

cat("\nSaved figure:\n  ", fig_path, "\n", sep = "")
cat("Saved log:\n  ", log_path, "\n", sep = "")