############################################################
# US_S15B_demand_control_variance_decomposition.R
#
# Quick diagnostic: how much of the variation in log NFC output
# is explained by the non-accumulation demand share (ad_t)?
#
# Tests:
#   1. Simple OLS: log(Y_NFC) ~ ad_t
#   2. ANOVA decomposition of variance explained
#   3. Rolling R² across Fordist / Post-Fordist windows
#   4. Correlation with capital accumulation variables (collinearity check)
############################################################

rm(list = ls())
options(stringsAsFactors = FALSE, scipen = 999)

library(httr)
library(dplyr)

root <- normalizePath(".", winslash = "/", mustWork = TRUE)
out_dir <- file.path(root, "output", "US", "S15B_DEMAND_CONTROL_VARIANCE_DECOMPOSITION")
csv_dir <- file.path(out_dir, "csv")
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

BEA_KEY <- Sys.getenv("BEA_API_KEY")
if (!nzchar(BEA_KEY)) stop("BEA_API_KEY is not set.")

## ==========================================================
## STEP 1: Read D10 wide panel and extract log(Y_NFC_real)
## ==========================================================

d10_candidates <- c(
  file.path(root, "output", "US",
    "D10_CLEAN_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET",
    "csv", "D10_clean_us_source_of_truth_panel_wide.csv"),
  file.path(root, "output", "US",
    "D10_US_ECONOMETRIC_AND_ACCOUNTING_SOURCE_OF_TRUTH_DATASET",
    "csv", "D10_us_source_of_truth_panel_wide.csv")
)

d10_path <- NULL
for (p in d10_candidates) {
  if (file.exists(p)) { d10_path <- p; break }
}
if (is.null(d10_path)) stop("D10 wide panel not found.")

d10 <- read.csv(d10_path, check.names = FALSE, stringsAsFactors = FALSE)

## Extract Y_REAL_NFC_GVA_BASELINE
y_nfc <- d10 |>
  select(year, Y_REAL_NFC_GVA_BASELINE) |>
  filter(!is.na(Y_REAL_NFC_GVA_BASELINE) & Y_REAL_NFC_GVA_BASELINE > 0) |>
  mutate(log_y_nfc = log(Y_REAL_NFC_GVA_BASELINE))

message(sprintf("Y_NFC real: %d obs, %d-%d",
                nrow(y_nfc), min(y_nfc$year), max(y_nfc$year)))

## ==========================================================
## STEP 2: Fetch T10110 and construct ad_t
## ==========================================================

resp <- GET(
  "https://apps.bea.gov/api/data",
  query = list(
    UserID = BEA_KEY, method = "GetData", datasetname = "NIPA",
    TableName = "T10110", Frequency = "A", Year = "ALL", ResultFormat = "JSON"
  ),
  timeout(120)
)
stop_for_status(resp)
payload <- content(resp, as = "parsed", simplifyVector = FALSE)
records <- payload$BEAAPI$Results$Data

years_raw <- vapply(records, function(x) x$TimePeriod, character(1))
years_num <- suppressWarnings(as.integer(years_raw))
descs <- vapply(records, function(x) x$LineDescription, character(1))
vals <- suppressWarnings(as.numeric(vapply(records, function(x) x$DataValue, character(1))))

df <- data.frame(
  year = years_num,
  line_description = descs,
  value = vals,
  stringsAsFactors = FALSE
)
df <- df[!is.na(df$year) & !is.na(df$value), ]

inv_share <- df |>
  filter(grepl("Gross private domestic investment", line_description, ignore.case = TRUE)) |>
  select(year, inv_share_pct = value)

ad_t <- inv_share |>
  mutate(ad_t = 1 - (inv_share_pct / 100)) |>
  select(year, ad_t)

yr_min <- min(ad_t$year, na.rm = TRUE)
yr_max <- max(ad_t$year, na.rm = TRUE)
message(sprintf("ad_t: %d obs, %d-%d", nrow(ad_t), yr_min, yr_max))

## ==========================================================
## STEP 3: Merge and restrict to common years
## ==========================================================

panel <- y_nfc |>
  inner_join(ad_t, by = "year") |>
  mutate(log_ad_t = log(ad_t)) |>
  arrange(year)

message(sprintf("Merged panel: %d obs, %d-%d", nrow(panel), min(panel$year), max(panel$year)))

## ==========================================================
## STEP 4: Simple OLS — log(Y_NFC) ~ ad_t vs log(ad_t)
## ==========================================================

fit_level <- lm(log_y_nfc ~ ad_t, data = panel)
fit_log   <- lm(log_y_nfc ~ log_ad_t, data = panel)
fit_null  <- lm(log_y_nfc ~ 1, data = panel)

s_level <- summary(fit_level)
s_log   <- summary(fit_log)

message("\n=== OLS: log(Y_NFC) ~ ad_t (level share) ===")
message(sprintf("  R² = %.4f  Adj R² = %.4f  F = %.2f  p = %.2e",
                s_level$r.squared, s_level$adj.r.squared,
                s_level$fstatistic[1],
                pf(s_level$fstatistic[1], s_level$fstatistic[2], s_level$fstatistic[3], lower.tail = FALSE)))
message(sprintf("  ad_t: %.4f (t = %.2f, p = %.4f)",
                coef(s_level)["ad_t", "Estimate"],
                coef(s_level)["ad_t", "t value"],
                coef(s_level)["ad_t", "Pr(>|t|)"]))

message("\n=== OLS: log(Y_NFC) ~ log(ad_t) ===")
message(sprintf("  R² = %.4f  Adj R² = %.4f  F = %.2f  p = %.2e",
                s_log$r.squared, s_log$adj.r.squared,
                s_log$fstatistic[1],
                pf(s_log$fstatistic[1], s_log$fstatistic[2], s_log$fstatistic[3], lower.tail = FALSE)))
message(sprintf("  log_ad_t: %.4f (t = %.2f, p = %.4f)",
                coef(s_log)["log_ad_t", "Estimate"],
                coef(s_log)["log_ad_t", "t value"],
                coef(s_log)["log_ad_t", "Pr(>|t|)"]))

## AIC comparison
message(sprintf("\n  AIC (level): %.2f  |  AIC (log): %.2f", AIC(fit_level), AIC(fit_log)))

## ==========================================================
## STEP 5: ANOVA decomposition (log form preferred)
## ==========================================================

anova_level <- anova(fit_null, fit_level)
anova_log   <- anova(fit_null, fit_log)

message("\n=== ANOVA: Null vs log(ad_t) model ===")
message(sprintf("  SSR(log_ad_t) = %.4f (%.1f%% of total SS)",
                anova_log[2, "Sum Sq"],
                100 * anova_log[2, "Sum Sq"] / sum((panel$log_y_nfc - mean(panel$log_y_nfc))^2)))
message(sprintf("  F = %.2f, p = %.2e", anova_log[2, "F"], anova_log[2, "Pr(>F)"]))

## ==========================================================
## STEP 6: Sub-sample windows
## ==========================================================

windows <- list(
  list(name = "Full_Sample", start = min(panel$year), end = max(panel$year)),
  list(name = "Fordist_1929_1973", start = 1929, end = 1973),
  list(name = "PostFordist_1974_2024", start = 1974, end = 2024),
  list(name = "PreWar_1929_1946", start = 1929, end = 1946),
  list(name = "GoldenAge_1947_1973", start = 1947, end = 1973),
  list(name = "Neoliberal_1974_2008", start = 1974, end = 2008),
  list(name = "PostGFC_2009_2024", start = 2009, end = 2024)
)

results <- lapply(windows, function(w) {
  sub <- panel |> filter(year >= w$start & year <= w$end)
  if (nrow(sub) < 10) return(NULL)
  fit_l <- lm(log_y_nfc ~ ad_t, data = sub)
  fit_ll <- lm(log_y_nfc ~ log_ad_t, data = sub)
  s_l  <- summary(fit_l)
  s_ll <- summary(fit_ll)
  data.frame(
    window = w$name,
    n_obs = nrow(sub),
    year_range = paste(w$start, "-", w$end),
    R2_level = s_l$r.squared,
    R2_log = s_ll$r.squared,
    AIC_level = AIC(fit_l),
    AIC_log = AIC(fit_ll),
    ad_t_coef = coef(fit_l)["ad_t"],
    ad_t_t = coef(s_l)["ad_t", "t value"],
    ad_t_p = coef(s_l)["ad_t", "Pr(>|t|)"],
    log_ad_t_coef = coef(fit_ll)["log_ad_t"],
    log_ad_t_t = coef(s_ll)["log_ad_t", "t value"],
    log_ad_t_p = coef(s_ll)["log_ad_t", "Pr(>|t|)"],
    stringsAsFactors = FALSE
  )
})

results_df <- do.call(rbind, results[!sapply(results, is.null)])

message("\n=== Sub-Sample R² Decomposition ===")
for (i in seq_len(nrow(results_df))) {
  r <- results_df[i, ]
  message(sprintf("  %-25s: n=%3d  R²=%.4f  ad_t=%.3f (t=%.2f, p=%.4f)  F=%.2f (p=%.4f)",
                  r$window, r$n_obs, r$R_squared, r$ad_t_coef, r$ad_t_t, r$ad_t_p,
                  r$F_stat, r$F_p))
}

## ==========================================================
## STEP 7: Correlation with capital variables (collinearity check)
## ==========================================================

## Extract k_NRC and kappa from D10
k_nrc <- d10 |>
  select(year, K_NRC) |>
  filter(!is.na(K_NRC) & K_NRC > 0) |>
  mutate(k_NRC = log(K_NRC))

k_me <- d10 |>
  select(year, K_ME) |>
  filter(!is.na(K_ME) & K_ME > 0) |>
  mutate(k_ME = log(K_ME))

cap_panel <- panel |>
  left_join(k_nrc, by = "year") |>
  left_join(k_me, by = "year") |>
  mutate(kappa = k_ME - k_NRC) |>
  filter(!is.na(kappa))

if (nrow(cap_panel) > 10) {
  cor_ad_kNRC <- cor(cap_panel$ad_t, cap_panel$k_NRC, use = "complete.obs")
  cor_ad_kappa <- cor(cap_panel$ad_t, cap_panel$kappa, use = "complete.obs")
  cor_ad_logy <- cor(cap_panel$ad_t, cap_panel$log_y_nfc, use = "complete.obs")

  message("\n=== Correlation: ad_t vs capital variables ===")
  message(sprintf("  corr(ad_t, k_NRC)   = %.4f", cor_ad_kNRC))
  message(sprintf("  corr(ad_t, kappa)   = %.4f", cor_ad_kappa))
  message(sprintf("  corr(ad_t, log_y)   = %.4f", cor_ad_logy))

  ## VIF check: does ad_t add collinearity to the capacity regression?
  cap_clean <- cap_panel |> filter(!is.na(k_NRC) & !is.na(kappa) & !is.na(ad_t))
  if (nrow(cap_clean) > 10) {
    fit_vif <- lm(log_y_nfc ~ k_NRC + kappa + ad_t, data = cap_clean)
    vif_vals <- car::vif(fit_vif)
    message(sprintf("\n  VIF (log_y ~ k_NRC + kappa + ad_t):"))
    for (nm in names(vif_vals)) {
      message(sprintf("    %-10s: %.2f", nm, vif_vals[nm]))
    }
  }
}

## ==========================================================
## STEP 8: Write outputs
## ==========================================================

write.csv(results_df, file.path(csv_dir, "demand_control_window_r2.csv"),
          row.names = FALSE, na = "")
write.csv(panel, file.path(csv_dir, "demand_control_merged_panel.csv"),
          row.names = FALSE, na = "")

message(sprintf("\n=== Written: %d files to %s ===",
                2, csv_dir))
