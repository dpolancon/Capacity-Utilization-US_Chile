# scratch_test_cointreg.R
library(cointReg)
df <- read.csv("data/processed/cl_s40/chile_peripheral_staged_panel.csv")
y <- df$k_NR
x <- cbind(k_ME = df$k_ME, omega = df$omega, phi = df$phi)

cat("--- FM-OLS ---\n")
fit_fm <- cointRegFM(y = y, x = x)
print(fit_fm$theta)
print(fit_fm$sd.theta)
print(fit_fm$p.theta)

cat("\n--- DOLS ---\n")
fit_dols <- cointRegD(y = y, x = x)
print(fit_dols$theta)
print(fit_dols$sd.theta)
print(fit_dols$p.theta)

cat("\n--- IM-OLS ---\n")
fit_im <- cointRegIM(y = y, x = x)
print(fit_im$theta)
print(fit_im$sd.theta)
print(fit_im$p.theta)
