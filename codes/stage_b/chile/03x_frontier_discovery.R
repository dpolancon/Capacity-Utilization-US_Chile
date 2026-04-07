# 03x_frontier_discovery.R
# Stage 2 — Self-discovery: finding the right identification for the frontier
#
# The problem: (y, k_NR, k_ME, omega_kME) failed because k_NR and k_ME are
# ~99% correlated in logs. We need a reparametrization that separates the
# LEVEL of capital from the COMPOSITION.
#
# Key insight: phi = K_ME/K_NR captures composition. In logs:
#   lphi = k_ME - k_NR = log(K_ME/K_NR)
#
# If k_NR and k_ME share a common I(2) trend, then lphi = k_ME - k_NR
# may be I(1) or I(0) — solving both the collinearity AND the near-I(2) problem.
#
# Mu is NOT the ECT. It requires post-estimation computation:
#   theta(omega, phi) = f(estimated CV parameters)
#   g(Y*) = theta * g(K)
#   mu accumulated from pin year

library(urca)
library(vars)
library(readr)
library(dplyr)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)

df <- read_csv("data/final/chile_tvecm_panel.csv", show_col_types = FALSE) %>%
  filter(complete.cases(y, k_NR, k_ME, omega_kME)) %>%
  arrange(year)

# Construct lphi = k_ME - k_NR = log(K_ME/K_NR)
df$lphi <- df$k_ME - df$k_NR

df_pre  <- df %>% filter(year < 1973)
df_post <- df %>% filter(year >= 1973)

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  DISCOVERY 1: WHY (k_NR, k_ME) FAILS — COLLINEARITY\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("Pre-1973 correlations in logs:\n")
cat(sprintf("  cor(k_NR, k_ME) = %.4f   ← near-perfect; system can't separate them\n",
    cor(df_pre$k_NR, df_pre$k_ME)))
cat(sprintf("  cor(k_NR, lphi) = %.4f   ← orthogonalized; level vs composition\n",
    cor(df_pre$k_NR, df_pre$lphi)))
cat(sprintf("  cor(y, k_NR)    = %.4f\n", cor(df_pre$y, df_pre$k_NR)))
cat(sprintf("  cor(y, lphi)    = %.4f\n", cor(df_pre$y, df_pre$lphi)))


cat("\n══════════════════════════════════════════════════════════════════════════\n")
cat("  DISCOVERY 2: INTEGRATION ORDER OF lphi = k_ME - k_NR\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("If k_NR and k_ME share a common I(2) trend, their DIFFERENCE lphi\n")
cat("cancels the I(2) component and may be I(1) or even I(0).\n\n")

for (nm in c("Pre-1973", "Post-1973")) {
  d <- if (nm == "Pre-1973") df_pre else df_post
  cat(sprintf("--- %s (N=%d) ---\n", nm, nrow(d)))

  # ADF on lphi in levels
  adf_lev <- ur.df(d$lphi, type = "drift", lags = 1)
  cat(sprintf("  ADF(lphi, levels): tau = %.4f", adf_lev@teststat[1]))
  cat(sprintf("  [5%% CV = %.2f]\n", adf_lev@cval[1, 2]))

  # ADF on Delta(lphi)
  dlphi <- diff(d$lphi)
  adf_d1 <- ur.df(dlphi, type = "drift", lags = 1)
  cat(sprintf("  ADF(Δlphi):        tau = %.4f", adf_d1@teststat[1]))
  cat(sprintf("  [5%% CV = %.2f]\n", adf_d1@cval[1, 2]))

  # KPSS on lphi (H0: stationary)
  kpss_lev <- ur.kpss(d$lphi, type = "mu", lags = "short")
  cat(sprintf("  KPSS(lphi, mu):    stat = %.4f", kpss_lev@teststat))
  cat(sprintf("  [5%% CV = %.2f]", kpss_lev@cval[1, 2]))
  cat(ifelse(kpss_lev@teststat > kpss_lev@cval[1, 2],
             "  ⚠ reject stationarity\n", "  ✓ stationary\n"))

  # Compare with k_ME and k_NR individually
  adf_kNR <- ur.df(d$k_NR, type = "drift", lags = 1)
  adf_kME <- ur.df(d$k_ME, type = "drift", lags = 1)
  adf_dkNR <- ur.df(diff(d$k_NR), type = "drift", lags = 1)
  adf_dkME <- ur.df(diff(d$k_ME), type = "drift", lags = 1)
  cat(sprintf("  For reference: ADF(Δk_NR)=%.4f, ADF(Δk_ME)=%.4f [near-I(2) if > -2.9]\n",
      adf_dkNR@teststat[1], adf_dkME@teststat[1]))
  cat("\n")
}


cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  DISCOVERY 3: MINIMAL SYSTEM — (y, k_NR, lphi)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("Start with the simplest frontier: y = theta*k_NR + psi*lphi + const\n")
cat("If this cointegrates (r >= 1), we have a baseline frontier.\n\n")

for (nm in c("Pre-1973", "Post-1973")) {
  d <- if (nm == "Pre-1973") df_pre else df_post
  cat(sprintf("--- %s (N=%d) ---\n", nm, nrow(d)))

  Y3 <- as.matrix(d[, c("y", "k_NR", "lphi")])
  rownames(Y3) <- d$year

  vs3 <- VARselect(Y3, lag.max = 3, type = "const")
  K3 <- max(vs3$selection["SC(n)"], 2)
  cat(sprintf("  Lag K=%d (SC)\n", K3))

  jo3 <- ca.jo(Y3, type = "trace", ecdet = "const", K = K3, spec = "longrun")
  p3 <- ncol(Y3)
  r3 <- 0
  for (r_null in 0:(p3 - 1)) {
    idx <- p3 - r_null
    stat <- jo3@teststat[idx]; cv05 <- jo3@cval[idx, 2]
    dec <- ifelse(stat > cv05, "REJECT", "fail")
    if (stat > cv05 && r_null >= r3) r3 <- r_null + 1
    cat(sprintf("  r<=%d: trace=%.2f  5%%cv=%.2f  [%s]\n", r_null, stat, cv05, dec))
  }
  cat(sprintf("  → r = %d\n", r3))

  if (r3 >= 1) {
    vecm3 <- cajorls(jo3, r = 1)
    cat("  Beta (normalized on y):\n")
    print(round(vecm3$beta, 4))
    theta <- -vecm3$beta[2, 1]
    psi   <- -vecm3$beta[3, 1]
    cat(sprintf("  theta (k_NR)  = %+.4f  [expected > 0] %s\n",
        theta, ifelse(theta > 0, "✓", "⚠")))
    cat(sprintf("  psi   (lphi)  = %+.4f  [expected > 0: machinery premium] %s\n",
        psi, ifelse(psi > 0, "✓", "⚠")))

    alpha <- coef(vecm3$rlm)["ect1", ]
    cat(sprintf("  alpha_y = %+.4f  %s\n", alpha[1],
        ifelse(alpha[1] < 0, "✓ error-corrects", "⚠")))
  }
  cat("\n")
}


cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  DISCOVERY 4: ADD DISTRIBUTION — (y, k_NR, lphi, omega_kME)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("Now add the distribution-machinery interaction omega*k_ME.\n")
cat("Since k_ME = k_NR + lphi, omega_kME = omega*(k_NR + lphi).\n")
cat("The time variation in omega breaks any linear dependence.\n\n")

for (nm in c("Pre-1973", "Post-1973")) {
  d <- if (nm == "Pre-1973") df_pre else df_post
  cat(sprintf("--- %s (N=%d) ---\n", nm, nrow(d)))

  Y4 <- as.matrix(d[, c("y", "k_NR", "lphi", "omega_kME")])
  rownames(Y4) <- d$year

  # Check the conditioning number to diagnose collinearity
  sv <- svd(scale(Y4))$d
  cond_num <- max(sv) / min(sv)
  cat(sprintf("  Condition number: %.1f (was %.1f with k_ME instead of lphi)\n",
      cond_num, {
        Y_old <- as.matrix(d[, c("y", "k_NR", "k_ME", "omega_kME")])
        sv_old <- svd(scale(Y_old))$d
        max(sv_old) / min(sv_old)
      }))

  vs4 <- VARselect(Y4, lag.max = 3, type = "const")
  K4 <- max(vs4$selection["SC(n)"], 2)
  cat(sprintf("  Lag K=%d (SC)\n", K4))

  jo4 <- ca.jo(Y4, type = "trace", ecdet = "const", K = K4, spec = "longrun")
  p4 <- ncol(Y4)
  r4 <- 0
  for (r_null in 0:(p4 - 1)) {
    idx <- p4 - r_null
    stat <- jo4@teststat[idx]; cv05 <- jo4@cval[idx, 2]
    dec <- ifelse(stat > cv05, "REJECT", "fail")
    if (stat > cv05 && r_null >= r4) r4 <- r_null + 1
    cat(sprintf("  r<=%d: trace=%.2f  5%%cv=%.2f  [%s]\n", r_null, stat, cv05, dec))
  }
  cat(sprintf("  → r = %d\n", r4))

  if (r4 >= 1) {
    vecm4 <- cajorls(jo4, r = 1)
    cat("  Beta (normalized on y):\n")
    print(round(vecm4$beta, 4))
    theta  <- -vecm4$beta[2, 1]
    psi    <- -vecm4$beta[3, 1]
    theta2 <- -vecm4$beta[4, 1]
    kappa  <- -vecm4$beta[5, 1]
    cat(sprintf("  theta  (k_NR)      = %+.4f  [expected > 0] %s\n",
        theta, ifelse(theta > 0, "✓", "⚠")))
    cat(sprintf("  psi    (lphi)      = %+.4f  [expected > 0: machinery premium] %s\n",
        psi, ifelse(psi > 0, "✓", "⚠")))
    cat(sprintf("  theta_2 (omega_kME)= %+.4f  [expected < 0: wage compression] %s\n",
        theta2, ifelse(theta2 < 0, "✓", "⚠")))

    alpha <- coef(vecm4$rlm)["ect1", ]
    alpha_clean <- setNames(as.numeric(alpha), c("y", "k_NR", "lphi", "omega_kME"))
    cat(sprintf("  alpha_y = %+.4f  %s\n", alpha_clean["y"],
        ifelse(alpha_clean["y"] < 0, "✓ error-corrects", "⚠")))
    cat("  Full alpha:\n")
    print(round(alpha_clean, 4))

    # Diagnostics
    vv <- vec2var(jo4, r = 1)
    pt <- serial.test(vv, lags.pt = 10, type = "PT.adjusted")
    cat(sprintf("  Portmanteau p = %.4f %s\n", pt$serial$p.value,
        ifelse(pt$serial$p.value > 0.05, "✓", "⚠")))
  }
  cat("\n")
}


cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  DISCOVERY 5: US-STYLE — (y, k_NR, omega, omega*k_NR)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("The US used (y, k, omega, omega*k) with a single capital aggregate.\n")
cat("Try this with k = k_NR (total NR capital). phi enters post-estimation.\n\n")

for (nm in c("Pre-1973", "Post-1973")) {
  d <- if (nm == "Pre-1973") df_pre else df_post
  cat(sprintf("--- %s (N=%d) ---\n", nm, nrow(d)))

  # Construct omega*k_NR
  d$omega_kNR <- d$omega * d$k_NR

  Y5 <- as.matrix(d[, c("y", "k_NR", "omega", "omega_kNR")])
  rownames(Y5) <- d$year

  vs5 <- VARselect(Y5, lag.max = 3, type = "const")
  K5 <- max(vs5$selection["SC(n)"], 2)
  cat(sprintf("  Lag K=%d (SC)\n", K5))

  jo5 <- ca.jo(Y5, type = "trace", ecdet = "const", K = K5, spec = "longrun")
  p5 <- ncol(Y5)
  r5 <- 0
  for (r_null in 0:(p5 - 1)) {
    idx <- p5 - r_null
    stat <- jo5@teststat[idx]; cv05 <- jo5@cval[idx, 2]
    dec <- ifelse(stat > cv05, "REJECT", "fail")
    if (stat > cv05 && r_null >= r5) r5 <- r_null + 1
    cat(sprintf("  r<=%d: trace=%.2f  5%%cv=%.2f  [%s]\n", r_null, stat, cv05, dec))
  }
  cat(sprintf("  → r = %d\n", r5))

  if (r5 >= 1) {
    vecm5 <- cajorls(jo5, r = 1)
    cat("  Beta (normalized on y):\n")
    print(round(vecm5$beta, 4))
    th1 <- -vecm5$beta[2, 1]  # k_NR
    th_o <- -vecm5$beta[3, 1] # omega alone
    th2 <- -vecm5$beta[4, 1]  # omega*k_NR
    cat(sprintf("  theta_1 (k_NR)       = %+.4f\n", th1))
    cat(sprintf("  coeff on omega alone = %+.4f  [US restricts this to 0]\n", th_o))
    cat(sprintf("  theta_2 (omega*k_NR) = %+.4f\n", th2))
    cat(sprintf("  → theta(omega) = %.4f + %.4f*omega\n", th1, th2))

    # Evaluate at sample mean omega
    omega_bar <- mean(d$omega)
    cat(sprintf("  → theta(omega_bar=%.3f) = %.4f\n", omega_bar, th1 + th2 * omega_bar))

    alpha <- coef(vecm5$rlm)["ect1", ]
    cat(sprintf("  alpha_y = %+.4f  %s\n", alpha[1],
        ifelse(alpha[1] < 0, "✓ error-corrects", "⚠")))
  }
  cat("\n")
}


cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  DISCOVERY 6: HYBRID — (y, k_NR, lphi, omega)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("Combine capital level + composition + distribution.\n")
cat("omega is I(0) but can enter the CV as a level-shift term.\n\n")

for (nm in c("Pre-1973", "Post-1973")) {
  d <- if (nm == "Pre-1973") df_pre else df_post
  cat(sprintf("--- %s (N=%d) ---\n", nm, nrow(d)))

  Y6 <- as.matrix(d[, c("y", "k_NR", "lphi", "omega")])
  rownames(Y6) <- d$year

  vs6 <- VARselect(Y6, lag.max = 3, type = "const")
  K6 <- max(vs6$selection["SC(n)"], 2)
  cat(sprintf("  Lag K=%d (SC)\n", K6))

  jo6 <- ca.jo(Y6, type = "trace", ecdet = "const", K = K6, spec = "longrun")
  p6 <- ncol(Y6)
  r6 <- 0
  for (r_null in 0:(p6 - 1)) {
    idx <- p6 - r_null
    stat <- jo6@teststat[idx]; cv05 <- jo6@cval[idx, 2]
    dec <- ifelse(stat > cv05, "REJECT", "fail")
    if (stat > cv05 && r_null >= r6) r6 <- r_null + 1
    cat(sprintf("  r<=%d: trace=%.2f  5%%cv=%.2f  [%s]\n", r_null, stat, cv05, dec))
  }
  cat(sprintf("  → r = %d\n", r6))

  if (r6 >= 1) {
    vecm6 <- cajorls(jo6, r = 1)
    cat("  Beta (normalized on y):\n")
    print(round(vecm6$beta, 4))
    cat(sprintf("  theta (k_NR)  = %+.4f\n", -vecm6$beta[2, 1]))
    cat(sprintf("  psi   (lphi)  = %+.4f\n", -vecm6$beta[3, 1]))
    cat(sprintf("  gamma (omega) = %+.4f\n", -vecm6$beta[4, 1]))

    alpha <- coef(vecm6$rlm)["ect1", ]
    cat(sprintf("  alpha_y = %+.4f  %s\n", alpha[1],
        ifelse(alpha[1] < 0, "✓ error-corrects", "⚠")))
  }
  cat("\n")
}

cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  SUMMARY — WHICH SYSTEM IDENTIFIES?\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("Compare across specifications. Look for:\n")
cat("  1. r >= 1 (cointegration exists)\n")
cat("  2. Correct signs on structural parameters\n")
cat("  3. alpha_y < 0 (output error-corrects toward frontier)\n")
cat("  4. Reasonable theta values (0.5 to 3.0 range)\n")
cat("  5. Clean diagnostics\n")
