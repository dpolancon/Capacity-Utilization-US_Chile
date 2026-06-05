library(urca)
df <- read.csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/data/final/chile_tvecm_panel.csv")
for (v in c("y","k_NR","k_ME","omega_kME")) {
  x <- na.omit(df[[v]]); dx <- diff(x)
  adf_l <- ur.df(x, type="drift", selectlags="BIC", lags=4)
  adf_d <- ur.df(dx, type="drift", selectlags="BIC", lags=4)
  kp <- ur.kpss(x, type="mu", lags="short")
  cat(sprintf("%-12s ADF(lev)=%.3f[%s] ADF(diff)=%.3f[%s] KPSS=%.3f[%s]\n",
    v, adf_l@teststat[1], ifelse(adf_l@teststat[1]<adf_l@cval[1,2],"rej","fail"),
    adf_d@teststat[1], ifelse(adf_d@teststat[1]<adf_d@cval[1,2],"rej","fail"),
    kp@teststat, ifelse(kp@teststat>0.463,"rej","fail")))
}
