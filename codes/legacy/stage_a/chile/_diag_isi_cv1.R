library(urca); library(readr); library(dplyr)
df <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/data/final/chile_tvecm_panel.csv",
               show_col_types = FALSE) %>% arrange(year)

# 1. ISI K=3 (N=33, rejects at 1%)
cat("=== ISI 1940-1972, K=3 ===\n")
df1 <- df %>% filter(year >= 1940, year <= 1972)
Y1 <- df1 %>% select(y, k_NR, k_ME, omega_kME) %>% as.matrix()
jo1 <- ca.jo(Y1, type = "trace", ecdet = "const", K = 3, spec = "transitory")
v1 <- cajorls(jo1, r = 1)
cat("CV1:\n"); print(round(v1$beta, 4))
cat(sprintf("theta_0=%+.4f  psi=%+.4f  theta_2=%+.4f\n",
    -v1$beta[2,1], -v1$beta[3,1], -v1$beta[4,1]))
a1 <- coef(v1$rlm)["ect1", ]
cat("Alpha: "); print(round(a1, 4))
ect1 <- as.numeric(cbind(Y1, 1) %*% v1$beta[, 1])
adf1 <- ur.df(ect1, type = "drift", lags = 2)
cat(sprintf("ADF(ECT): tau=%.4f\n\n", adf1@teststat[1]))

# 2. Extended 1935-1978, K=2
cat("=== Extended 1935-1978, K=2 ===\n")
df2 <- df %>% filter(year >= 1935, year <= 1978)
Y2 <- df2 %>% select(y, k_NR, k_ME, omega_kME) %>% as.matrix()
D2 <- df2 %>% select(D1973, D1975) %>% as.matrix()
jo2 <- ca.jo(Y2, type = "trace", ecdet = "const", K = 2, spec = "transitory", dumvar = D2)
v2 <- cajorls(jo2, r = 1)
cat("CV1:\n"); print(round(v2$beta, 4))
cat(sprintf("theta_0=%+.4f  psi=%+.4f  theta_2=%+.4f\n",
    -v2$beta[2,1], -v2$beta[3,1], -v2$beta[4,1]))
a2 <- coef(v2$rlm)["ect1", ]
cat("Alpha: "); print(round(a2, 4))
ect2 <- as.numeric(cbind(Y2, 1) %*% v2$beta[, 1])
adf2 <- ur.df(ect2, type = "drift", lags = 2)
cat(sprintf("ADF(ECT): tau=%.4f\n\n", adf2@teststat[1]))

# 3. ISI K=2 forced r=1 (below 5% but close — 48.58 vs 53.12)
cat("=== ISI 1940-1972, K=2 (forced r=1) ===\n")
jo3 <- ca.jo(Y1, type = "trace", ecdet = "const", K = 2, spec = "transitory")
v3 <- cajorls(jo3, r = 1)
cat("CV1:\n"); print(round(v3$beta, 4))
cat(sprintf("theta_0=%+.4f  psi=%+.4f  theta_2=%+.4f\n",
    -v3$beta[2,1], -v3$beta[3,1], -v3$beta[4,1]))
ect3 <- as.numeric(cbind(Y1, 1) %*% v3$beta[, 1])
adf3 <- ur.df(ect3, type = "drift", lags = 2)
cat(sprintf("ADF(ECT): tau=%.4f\n\n", adf3@teststat[1]))

# Full-sample stationarity check for each beta
cat("=== Full-sample ECT stationarity (1920-2024) ===\n")
Y_full <- df %>% select(y, k_NR, k_ME, omega_kME) %>% as.matrix()
for (label in c("ISI_K3", "Ext_K2", "ISI_K2")) {
  beta <- switch(label, ISI_K3 = v1$beta, Ext_K2 = v2$beta, ISI_K2 = v3$beta)
  ect_full <- as.numeric(cbind(Y_full, 1) %*% beta[, 1])
  adf_f <- ur.df(ect_full, type = "drift", selectlags = "BIC", lags = 4)
  cat(sprintf("  %s: ADF tau=%.4f [5%%CV: %.4f] %s\n", label,
      adf_f@teststat[1], adf_f@cval[1,2],
      ifelse(adf_f@teststat[1] < adf_f@cval[1,2], "STATIONARY", "NOT stationary")))
}
