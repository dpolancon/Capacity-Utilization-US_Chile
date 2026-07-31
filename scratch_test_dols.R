# scratch_test_dols.R
library(sandwich)
library(lmtest)

df <- read.csv("data/processed/cl_s40/chile_peripheral_staged_panel.csv")
df_sub <- df[!is.na(df$k_NR) & !is.na(df$k_ME) & !is.na(df$omega) & !is.na(df$phi), ]

# Compute leads and lags of diff(k_ME)
df_sub$dk_ME <- c(NA, diff(df_sub$k_ME))
df_sub$dk_ME_lead1 <- c(df_sub$dk_ME[-1], NA)
df_sub$dk_ME_lag1  <- c(NA, df_sub$dk_ME[-length(df_sub$dk_ME)])

df_clean <- df_sub[complete.cases(df_sub[, c("k_NR", "k_ME", "omega", "phi", "dk_ME", "dk_ME_lead1", "dk_ME_lag1")]), ]

cat("=== DOLS Estimation (Stock & Watson 1993) ===\n")
fit_dols <- lm(k_NR ~ k_ME + omega + phi + dk_ME + dk_ME_lead1 + dk_ME_lag1, data = df_clean)
print(coeftest(fit_dols, vcov. = NeweyWest(fit_dols, prewhite = FALSE)))

cat("\n=== IM-OLS Estimation (Vogelsang & Wagner 2014) ===\n")
df_clean$S_k_ME <- cumsum(df_clean$k_ME)
fit_imols <- lm(k_NR ~ k_ME + omega + phi + S_k_ME, data = df_clean)
print(coeftest(fit_imols, vcov. = NeweyWest(fit_imols, prewhite = FALSE)))
