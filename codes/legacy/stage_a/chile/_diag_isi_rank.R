library(urca); library(readr); library(dplyr)
df <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/data/final/chile_tvecm_panel.csv", show_col_types=FALSE) %>% arrange(year)
df_isi <- df %>% filter(year>=1940, year<=1972)
Y <- df_isi %>% select(y,k_NR,k_ME,omega_kME) %>% as.matrix()
cat("ISI subsample 1940-1972 (N=33)\n\n")
for (K in 2:3) {
  jo <- ca.jo(Y, type="trace", ecdet="const", K=K, spec="transitory")
  cat(sprintf("K=%d:\n", K))
  for (r_null in 0:3) {
    idx <- 4-r_null
    cat(sprintf("  r<=%d: stat=%.2f  10%%CV=%.2f  5%%CV=%.2f  1%%CV=%.2f\n",
        r_null, jo@teststat[idx], jo@cval[idx,1], jo@cval[idx,2], jo@cval[idx,3]))
  }
}

# Also try extended ISI window: 1935-1978 (pre-crisis + early post)
cat("\n\nExtended window 1935-1978 (N=44):\n")
df_ext <- df %>% filter(year>=1935, year<=1978)
Y2 <- df_ext %>% select(y,k_NR,k_ME,omega_kME) %>% as.matrix()
D2 <- df_ext %>% select(D1973,D1975) %>% as.matrix()
for (K in 2:3) {
  jo <- ca.jo(Y2, type="trace", ecdet="const", K=K, spec="transitory", dumvar=D2)
  cat(sprintf("K=%d:\n", K))
  for (r_null in 0:3) {
    idx <- 4-r_null
    cat(sprintf("  r<=%d: stat=%.2f  10%%CV=%.2f  5%%CV=%.2f\n",
        r_null, jo@teststat[idx], jo@cval[idx,1], jo@cval[idx,2]))
  }
}

# In-sample window 1940-1978 (N=39)
cat("\n\nIn-sample 1940-1978 (N=39):\n")
df39 <- df %>% filter(year>=1940, year<=1978)
Y3 <- df39 %>% select(y,k_NR,k_ME,omega_kME) %>% as.matrix()
D3 <- df39 %>% select(D1973,D1975) %>% as.matrix()
for (K in 2:3) {
  jo <- ca.jo(Y3, type="trace", ecdet="const", K=K, spec="transitory", dumvar=D3)
  cat(sprintf("K=%d:\n", K))
  for (r_null in 0:3) {
    idx <- 4-r_null
    cat(sprintf("  r<=%d: stat=%.2f  5%%CV=%.2f  %s\n",
        r_null, jo@teststat[idx], jo@cval[idx,2],
        ifelse(jo@teststat[idx]>jo@cval[idx,2],"REJECT","fail")))
  }
  if (jo@teststat[4] > jo@cval[4,2]) {
    vecm <- cajorls(jo, r=1)
    cat("  CV1: "); print(round(vecm$beta,4))
    cat(sprintf("  theta_0=%+.4f psi=%+.4f theta_2=%+.4f\n",
        -vecm$beta[2,1], -vecm$beta[3,1], -vecm$beta[4,1]))
  }
}
