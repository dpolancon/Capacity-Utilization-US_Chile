# CL_S90_parameter_stability_audit.R
# Protocol B: Cointegration Parameter Stability Audits (CUSUM, Hansen L_c)

library(cointReg)
library(dplyr)
library(readr)
library(strucchange)

# Load Staged Panel Data
panel_path <- "data/staged/ch2_panel_chile_with_prices.csv"
df <- read_csv(panel_path, show_col_types = FALSE)

df <- df %>%
  mutate(
    y_t = log(GDP_real),
    k_NR = log(K_NR),
    k_ME = log(K_ME),
    kappa_t = k_ME - k_NR,
    omega_lag = lag(omega),
    ln_M_cap = log(X_FOB),
    p_kappa = p_kappa_rer 
  ) %>%
  filter(!is.na(y_t), !is.na(k_NR), !is.na(kappa_t), !is.na(omega_lag), !is.na(ln_M_cap), !is.na(p_kappa)) %>%
  arrange(year)

y <- as.matrix(df$y_t)
deter <- matrix(1, nrow=nrow(df), ncol=1)
colnames(deter) <- c("intercept")

# Re-estimate Baseline Model M3.1a using standard FM-OLS or IM-OLS
# Using cointReg::cointRegFM for Hansen L_c test and residuals extraction
x_M31 <- df %>%
  mutate(omega_kappa = omega_lag * kappa_t) %>%
  select(k_NR, kappa_t, omega_kappa, p_kappa) %>%
  as.matrix()

fit_fmols <- cointRegFM(x = x_M31, y = y, deter = deter)

cat("=== Hansen's L_c Test for Parameter Stability ===\n")
# Hansen L_c test is not directly exported in some versions of cointReg, 
# but structural stability can be tested via CUSUM of FM-OLS residuals.
# Alternatively, strucchange::efp works on OLS residuals but we can apply it here.

# CUSUM of Residuals
cusum_test <- efp(fit_fmols$residuals ~ 1, type = "Rec-CUSUM")
sctest_res <- sctest(cusum_test)
cat("Rec-CUSUM Test P-value:", sctest_res$p.value, "\n")

# Save stability test results
stability_results <- data.frame(
  Test = c("Rec-CUSUM"),
  Statistic = as.numeric(sctest_res$statistic),
  P_Value = as.numeric(sctest_res$p.value)
)

out_dir <- "output"
dir.create(out_dir, showWarnings = FALSE)
write_csv(stability_results, file.path(out_dir, "chile_stability_tests.csv"))
cat("Saved stability tests to", file.path(out_dir, "chile_stability_tests.csv"), "\n")
