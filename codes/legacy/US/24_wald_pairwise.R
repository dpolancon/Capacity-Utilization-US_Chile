library(readr); library(dplyr); library(ARDL)
REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
ds <- read_csv(file.path(REPO, "data/processed/us_nf_corporate_stageC.csv"), show_col_types=FALSE)

run_pw <- function(ds, dv, s0, s1, lab) {
  cat(sprintf("\n%s\n%s (%s, %d-%d)\n%s\n", strrep("=",60), lab, dv, s0, s1, strrep("=",60)))
  df <- ds[ds$year >= (s0-3) & ds$year <= s1, ]
  df <- df[order(df$year), ]
  f <- as.formula(paste(dv, "~ mu + B_real + PyPK + pi"))
  dft <- ts(df[, c("year", dv, "mu","B_real","PyPK","pi")], start=min(df$year), frequency=1)
  a <- auto_ardl(f, data=dft, max_order=2, selection="AIC")
  b <- a$best_model
  cat(sprintf("ARDL(%s) N=%d\n", paste(a$best_order, collapse=","), nobs(b)))
  lr <- multipliers(b)
  cat("\nLR multipliers:\n")
  for(i in 1:nrow(lr)) cat(sprintf("  %-10s %+.4f (p=%.4f)\n", lr$Term[i], lr$Estimate[i], lr[["Pr(>|t|)"]][i]))
  an <- names(coef(b))
  gn <- function(p) grep(p, an, value=TRUE)
  mu_n <- gn("^mu$|^L[(]mu")
  br_n <- gn("^B_real$|^L[(]B_real")
  pp_n <- gn("^PyPK$|^L[(]PyPK")
  pi_n <- gn("^pi$|^L[(]pi")
  wt <- function(na, nb, la, lb) {
    R <- rep(0, length(coef(b))); names(R) <- an
    for(nm in na) R[nm] <- R[nm]+1; for(nm in nb) R[nm] <- R[nm]-1
    d <- sum(R*coef(b)); se <- as.numeric(sqrt(t(R) %*% vcov(b) %*% R))
    tt <- d/se; pp <- 2*pt(-abs(tt), df=nobs(b)-length(coef(b)))
    cat(sprintf("  H0: b_%s = b_%s | diff=%+.4f t=%.3f p=%.4f %s\n",
        la, lb, d, tt, pp, ifelse(pp<0.05,"REJECT",ifelse(pp<0.10,"MARGINAL","FAIL"))))
  }
  cat("\n--- Pairwise Wald Tests (LR multipliers) ---\n")
  wt(mu_n, pp_n, "mu","PyPK")
  wt(mu_n, br_n, "mu","B_real")
  wt(mu_n, pi_n, "mu","pi")
  wt(pp_n, br_n, "PyPK","B_real")
  wt(pp_n, pi_n, "PyPK","pi")
  wt(br_n, pi_n, "B_real","pi")
  cat("\n--- Composite ---\n")
  R <- rep(0, length(coef(b))); names(R) <- an
  for(nm in mu_n) R[nm]<-R[nm]+1; for(nm in br_n) R[nm]<-R[nm]-1; for(nm in pp_n) R[nm]<-R[nm]-1
  d <- sum(R*coef(b)); se <- as.numeric(sqrt(t(R) %*% vcov(b) %*% R))
  tt <- d/se; pp <- 2*pt(-abs(tt), df=nobs(b)-length(coef(b)))
  cat(sprintf("  H0: b_mu = b_PyPK+b_Br | diff=%+.4f t=%.3f p=%.4f %s\n",
      d, tt, pp, ifelse(pp<0.05,"REJECT","FAIL")))
}
run_pw(ds, "g_K", 1947, 1974, "GROSS K")
run_pw(ds, "g_Kn", 1947, 1974, "NET K")
