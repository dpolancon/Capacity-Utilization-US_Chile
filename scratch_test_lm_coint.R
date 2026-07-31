# scratch_test_lm_coint.R
library(sandwich)
library(lmtest)

df <- read.csv("data/processed/cl_s40/chile_peripheral_staged_panel.csv")

fit_ols <- lm(k_NR ~ k_ME + omega + phi, data = df)
cat("=== OLS Cointegrating Regression ===\n")
print(summary(fit_ols))

cat("\n=== Newey-West HAR Standard Errors ===\n")
nw_se <- coeftest(fit_ols, vcov. = vcovNW(fit_ols))
print(nw_se)
