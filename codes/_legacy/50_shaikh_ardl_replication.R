# ============================================================
# 50_shaikh_ardl_replication.R — ARDL-package-only replication
#
# Key Shaikh alignment:
#   - fixed (unlagged) dummies using "|" in ardl() formula
#   - trend included as trend(lnY)
#   - fixed ARDL order (replication object, not auto selection)
#   - coint_eq() treated as cointegrating equation vector (not fitted lnY^p)
#
# Output: output/CU_estimates_compare/{csv,figs,logs,tex}
# ============================================================

suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(readr)
  library(ARDL)
  library(lmtest) # for bgtest(), bptest(), and resettest()
  library(tseries) # for jarque.bera.test()
  library(strucchange) # for efp(), and sctest()
  library(ggplot2)
})

`%||%` <- function(a, b) if (is.null(a)) b else a

# -----------------------------
# 0) CONFIG-driven data load (Shaikh replication dataset)
# -----------------------------
CONFIG_PATH <- here::here("codes", "10_config_tsdyn.R")
stopifnot(file.exists(CONFIG_PATH))
source(CONFIG_PATH)
stopifnot(exists("CONFIG"))

DATA_XLSX <- here::here(CONFIG$data_shaikh)
SHEET     <- CONFIG$data_shaikh_sheet %||% "long"
stopifnot(file.exists(DATA_XLSX))

df_raw <- readxl::read_excel(DATA_XLSX, sheet = SHEET)

# Validate required columns exist
stopifnot(all(c(CONFIG$year_col, CONFIG$y_nom, CONFIG$k_nom, CONFIG$p_index) %in% names(df_raw)))

df <- df_raw %>%
  transmute(
    year  = as.integer(.data[[CONFIG$year_col]]),
    Y_nom = as.numeric(.data[[CONFIG$y_nom]]),
    K_nom = as.numeric(.data[[CONFIG$k_nom]]),
    p     = as.numeric(.data[[CONFIG$p_index]]),   # base 2011 = 100
    u_shaikh = as.numeric(.data[[CONFIG$u_shaikh]])
  ) %>%
  filter(is.finite(year), is.finite(Y_nom), is.finite(K_nom), is.finite(p),is.finite(u_shaikh)) %>%
  filter(p > 0) %>%
  mutate(
    p_scale = p / 100,            # convert to 2011=1
    Y_real  = Y_nom / p_scale,    # common-deflator real series
    K_real  = K_nom / p_scale
  ) %>%
  filter(Y_real > 0, K_real > 0) %>%
  mutate(
    lnY = log(Y_real),
    lnK = log(K_real)
  ) %>%
  arrange(year)

# -----------------------------
# Window toggle (replication lock)
# -----------------------------
WINDOW_TAG <- "shaikh_window"  # options: names(CONFIG$WINDOWS_LOCKED)

stopifnot("WINDOWS_LOCKED" %in% names(CONFIG))
stopifnot(WINDOW_TAG %in% names(CONFIG$WINDOWS_LOCKED))

w <- CONFIG$WINDOWS_LOCKED[[WINDOW_TAG]]
stopifnot(length(w) == 2)

start_w <- w[[1]]
end_w   <- w[[2]]

# Treat -Inf/Inf as open bounds
df <- df %>%
  filter(
    (is.infinite(start_w) | year >= start_w),
    (is.infinite(end_w)   | year <= end_w)
  ) %>%
  arrange(year)


# -----------------------------
# 1) Output dirs
# -----------------------------
ROOT_OUT <- here::here("output", "CU_estimates_compare")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  figs = file.path(ROOT_OUT, "figs"),
  logs = file.path(ROOT_OUT, "logs"),
  tex  = file.path(ROOT_OUT, "tex")
)
invisible(lapply(DIRS, dir.create, recursive = TRUE, showWarnings = FALSE))

# Add WINDOW_TAG suffix to outputs
series_path <- file.path(DIRS$csv,  paste0("SHAIKH_ARDL_u_series_", WINDOW_TAG, ".csv"))
log_path    <- file.path(DIRS$logs, paste0("SHAIKH_ARDL_replication_log_", WINDOW_TAG, ".txt"))

# -----------------------------
# 2) Shaikh-style knobs (here)
# -----------------------------
INCLUDE_TREND <- FALSE

# Fix the ARDL order explicitly: ARDL(p,q) with one regressor lnK
# Example: p=2 (lags of lnY), q=4 (lags of lnK including 0..4) as in your screenshot structure.

# One-year pulse dummies (unlagged). Edit here.
DUMMY_YEARS <- c(1956L, 1974L, 1980L)
for (yy in DUMMY_YEARS) {
  nm <- paste0("d", yy)
  df[[nm]] <- as.integer(df$year == yy)
}
DUMMY_VARS <- paste0("d", DUMMY_YEARS)


# One-year pulse dummies (unlagged). Edit here.
DUMMY_YEARS_FULL_Sample <- c(1956L, 1974L, 1980L,2009L,2020L)
for (yy in DUMMY_YEARS_FULL_Sample) {
  nm <- paste0("d", yy)
  df[[nm]] <- as.integer(df$year == yy)
}
DUMMY_YEARS_FULL_Sample <- paste0("d", DUMMY_YEARS_FULL_Sample)


# -----------------------------
# 3) Estimate ARDL with fixed (unlagged) dummies
#    Use "|" so dummies are NOT lagged by the ARDL constructor.
# -----------------------------
start_year <- min(df$year, na.rm = TRUE)
df_ts <- ts(df %>% select(lnY, lnK, all_of(DUMMY_VARS)), start = start_year, frequency = 1)


ORDER <- c(2, 4)
fml <- as.formula(lnY ~ lnK | d1956  + d1974  + d1980)
fit_ardl <- ARDL::ardl(formula = fml, data = df_ts, order = ORDER)
summary(fit_ardl)

# -----------------------------
# 4) Bounds test (case depends on deterministics)
# -----------------------------
CASE <- "uc"
bt_f_asympt <- bounds_f_test(fit_ardl, case = CASE, alpha = 0.05, pvalue = TRUE, exact = FALSE)
print(bt_f_asympt)
bt_f_exact  <- bounds_f_test(fit_ardl, case = CASE, alpha = 0.05, pvalue = TRUE, exact = TRUE)
print(bt_f_exact)


bt_f_asympt <- bounds_t_test(fit_ardl, case = CASE, alpha = 0.05, pvalue = TRUE, exact = FALSE)
print(bt_f_asympt)
bt_f_exact  <- bounds_t_test(fit_ardl, case = CASE, alpha = 0.05, pvalue = TRUE, exact = TRUE)
print(bt_f_exact)


# ------------------------------------------------------------
# PATCH A — Correct u_t construction + long-run multiplier
# Place AFTER you fit fit_ardl and define CASE
# ------------------------------------------------------------


#Full table inference of Long-Run multipliers 
lr_mult <- multipliers(fit_ardl, type = "lr")

#Extracting coeficients from ADL 
coefs <- coef(fit_ardl)

# denominator = 1 - sum of lnY lag coefficients
den <- 1 - sum(coefs[grep("^L\\(lnY,", names(coefs))])

# extract dummy level coefficients (e.g. d1956, d1974, d1980)
dummy_names <- grep("^d[0-9]{4}$", names(coefs), value = TRUE)

#Long run dummy 
dummy_lr <- coefs[dummy_names] / den


vc <- vcov(fit_ardl)

# extract standard errors for dummies
se_delta <- sqrt(diag(vc))[dummy_names]

# approximate scaled standard errors
se_lr <- se_delta / abs(den)

# t-values and p-values
t_lr <- dummy_lr / se_lr
p_lr <- 2 * pt(abs(t_lr), df = df.residual(fit_ardl), lower.tail = FALSE)

dummy_table <- data.frame(
  Term      = dummy_names,
  Estimate  = dummy_lr,
  'Std. Error' = se_lr,
  't value'   = t_lr,
  'Pr(>|t|)'  = p_lr
)
colnames(dummy_table) <- c("Term", "Estimate", "Std. Error", "t value", "Pr(>|t|)")

#Full table for inference of long run multipliers  
lr_full_table <- rbind(
  lr_mult,         # from multipliers()
  dummy_table
)

rownames(lr_full_table)[1:2] <- c("(Intercept)","lnK")
a_lr <- lr_full_table$Estimate[lr_full_table$Term == "(Intercept)"]
b_lr <- lr_full_table$Estimate[lr_full_table$Term == "lnK"]
dummy_coef <- lr_full_table$Estimate[match(dummy_names, lr_full_table$Term)]


dummy_effect <- exp(rowSums(df[dummy_names] * dummy_coef))-1

# CU estimate 
lnYp_hat <- a_lr + b_lr * df$lnK + dummy_effect
lnu_hat <- df$lnY - lnYp_hat
u_hat_shaikh_ardl_rep_dummy   <- exp(lnu_hat) + (exp(rowSums(df[dummy_names] * dummy_coef))-1)
u_hat_shaikh_ardl_rep_nodummy   <- exp(lnu_hat) 

#DF_plot
df_plot <- data.frame(
  year     = df$year,
  u_dummy  = u_hat_shaikh_ardl_rep_dummy,
  u_nodummy = u_hat_shaikh_ardl_rep_nodummy,
  u_shaikh = df$u_shaikh
)

#Aux Dummy Years
dummy_years <- as.numeric(gsub("d", "", dummy_names))


#Plot
plot_u_hat_shaikh_ardl_rep <- ggplot(df_plot, aes(x = year)) +
  geom_line(aes(y = u_dummy,   color = "With LR dummies"), size = 0.8) +
  geom_line(aes(y = u_nodummy, color = "Without LR dummies"), size = 0.8) +
  geom_line(aes(y = u_shaikh,  color = "Shaikh (2016)"), size = 0.9) +
  geom_hline(yintercept = 1, linetype = "solid", alpha = 0.4) +
  geom_vline(xintercept = dummy_years, linetype = "dashed", alpha = 0.6) +
  scale_color_manual(
    values = c(
      "With LR dummies"    = "steelblue",
      "Without LR dummies" = "black",
      "Shaikh (2016)"      = "red"
    )
  ) +
  scale_x_continuous(
    breaks = seq(min(df_plot$year), max(df_plot$year), by = 1)
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.title = element_blank(),
    legend.position = "bottom",
    axis.text.x = element_text(angle = 45, hjust = 1),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  labs(
    x = "Year",
    y = "Capacity Utilization (u)"
  )

print(plot_u_hat_shaikh_ardl_rep)
