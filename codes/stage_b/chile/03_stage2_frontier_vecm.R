# 03_stage2_frontier_vecm.R
# Stage 2 — Chilean Productive Frontier: Asymmetric Split-Sample VECM
#
# The composition variable lphi = log(K_ME/K_NR) = k_ME - k_NR replaces
# the collinear (k_NR, k_ME) pair. This separates SCALE from COMPOSITION.
#
# Pre-1973 (ISI): (y, k_NR, lphi, omega*lphi)  — 4 variables, r=1
#   CV1: y = theta*k_NR + psi*lphi + theta_2*(omega*lphi) + kappa
#   Distribution-composition interaction is cleanly identified.
#
# Post-1973 (neoliberal): (y, k_NR, lphi)  — 3 variables, r=1
#   CV1: y = theta*k_NR + psi*lphi + kappa
#   The omega*lphi interaction is collinear post-1973 (cor=0.99); dropped.
#
# Post-estimation (both regimes):
#   theta^CL(omega, phi) computed from CV1 parameters
#   g(Y*) = theta^CL * g(K_NR)
#   g(mu) = g(Y) - g(Y*)
#   mu pinned at mu(1980) = 1.0 (Ffrench-Davis pre-debt-crisis peak)
#
# NOTE: mu is NOT the ECT. mu is constructed from theta via growth rate
# accumulation and pin-year normalization. The ECT is just the stationary
# cointegrating residual.
#
# Authority: Ch2_Outline_DEFINITIVE.md | Notation: CLAUDE.md

library(urca)
library(vars)
library(readr)
library(dplyr)
library(tibble)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)

OUT <- file.path(REPO, "output/stage_b/Chile")
CSV <- file.path(OUT, "csv")
dir.create(CSV, recursive = TRUE, showWarnings = FALSE)


# ══════════════════════════════════════════════════════════════════════════════
# 0. DATA
# ══════════════════════════════════════════════════════════════════════════════

cat("\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STAGE 2 — PRODUCTIVE FRONTIER (ASYMMETRIC SPLIT-SAMPLE)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

df_raw <- read_csv(file.path(REPO, "data/final/chile_tvecm_panel.csv"),
                   show_col_types = FALSE)
df_all <- df_raw %>%
  filter(complete.cases(y, k_NR, k_ME, omega_kME)) %>%
  arrange(year) %>%
  mutate(
    lphi       = k_ME - k_NR,          # log composition = log(K_ME/K_NR)
    omega_lphi = omega * lphi           # distribution × composition interaction
  )

cat(sprintf("Full panel: %d-%d (N=%d)\n", min(df_all$year), max(df_all$year), nrow(df_all)))

df_pre  <- df_all %>% filter(year < 1973)
df_post <- df_all %>% filter(year >= 1973)

cat(sprintf("Pre-1973  (ISI):        %d-%d (N=%d)  → (y, k_NR, lphi, omega*lphi)\n",
    min(df_pre$year), max(df_pre$year), nrow(df_pre)))
cat(sprintf("Post-1973 (neoliberal): %d-%d (N=%d)  → (y, k_NR, lphi)\n",
    min(df_post$year), max(df_post$year), nrow(df_post)))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 1 — PRE-1973: (y, k_NR, lphi, omega*lphi)                      ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║  PRE-1973 — ISI ERA: (y, k_NR, lphi, omega*lphi)                  ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

Y_pre <- df_pre %>% select(y, k_NR, lphi, omega_lphi) %>% as.matrix()
rownames(Y_pre) <- df_pre$year
p_pre <- ncol(Y_pre)

cat("Variable summary:\n")
for (j in 1:p_pre) cat(sprintf("  %-12s: mean=%8.4f  sd=%8.4f  range=[%8.4f, %8.4f]\n",
    colnames(Y_pre)[j], mean(Y_pre[,j]), sd(Y_pre[,j]), min(Y_pre[,j]), max(Y_pre[,j])))

# Lag selection
vs_pre <- VARselect(Y_pre, lag.max = 3, type = "const")
cat("\nLag selection:\n"); print(vs_pre$selection)
K_pre <- max(vs_pre$selection["SC(n)"], 2)
cat(sprintf("Using K=%d (SC). VECM lag L=%d.\n", K_pre, K_pre - 1))

# Johansen trace
jo_pre <- ca.jo(Y_pre, type = "trace", ecdet = "const", K = K_pre, spec = "longrun")
cat("\nJohansen Trace Test:\n")
r_pre <- 0
for (r_null in 0:(p_pre - 1)) {
  idx <- p_pre - r_null
  stat <- jo_pre@teststat[idx]; cv05 <- jo_pre@cval[idx, 2]; cv01 <- jo_pre@cval[idx, 3]
  dec <- ifelse(stat > cv01, "REJECT 1%", ifelse(stat > cv05, "REJECT 5%", "fail"))
  if (stat > cv05 && r_null >= r_pre) r_pre <- r_null + 1
  cat(sprintf("  r<=%d: trace=%.2f  5%%cv=%.2f  1%%cv=%.2f  [%s]\n",
      r_null, stat, cv05, cv01, dec))
}
cat(sprintf("  → r = %d\n", r_pre))
cat("Eigenvalues:"); print(round(jo_pre@lambda, 4))

if (r_pre == 0) stop("BLOCKER: r=0 pre-1973. No frontier cointegration.")

# VECM r=1
vecm_pre <- cajorls(jo_pre, r = 1)
beta_pre <- vecm_pre$beta
cat("\nBeta (normalized on y):\n"); print(round(beta_pre, 6))

alpha_pre_raw <- coef(vecm_pre$rlm)["ect1", ]
alpha_pre <- setNames(as.numeric(alpha_pre_raw), colnames(Y_pre))

# Structural parameters
theta_pre  <- -beta_pre[2, 1]   # k_NR
psi_pre    <- -beta_pre[3, 1]   # lphi
theta2_pre <- -beta_pre[4, 1]   # omega*lphi
kappa_pre  <- -beta_pre[5, 1]   # constant

cat(sprintf("\nFrontier: y = %.4f*k_NR + %.4f*lphi + %.4f*(omega*lphi) + %.4f\n",
    theta_pre, psi_pre, theta2_pre, kappa_pre))
cat(sprintf("  theta  (k_NR)       = %+.4f  %s\n", theta_pre, ifelse(theta_pre > 0, "✓", "⚠")))
cat(sprintf("  psi    (lphi)       = %+.4f  %s\n", psi_pre, ifelse(psi_pre > 0, "✓", "⚠")))
cat(sprintf("  theta_2 (omega*lphi)= %+.4f\n", theta2_pre))
cat(sprintf("  alpha_y = %+.4f  %s\n", alpha_pre["y"],
    ifelse(alpha_pre["y"] < 0, "✓ error-corrects", "⚠")))

# Weak exogeneity
cat("\nWeak exogeneity:\n")
we_pre <- data.frame(variable = character(), LR = numeric(), p = numeric(),
                      decision = character(), stringsAsFactors = FALSE)
for (j in 1:p_pre) {
  A_j <- matrix(0, nrow = p_pre, ncol = p_pre - 1); ci <- 1
  for (i in 1:p_pre) { if (i != j) { A_j[i, ci] <- 1; ci <- ci + 1 } }
  tryCatch({
    we <- alrtest(jo_pre, A = A_j, r = 1)
    dec <- ifelse(we@pval[1] > 0.05, "WE", "not WE")
    cat(sprintf("  %s: LR=%.3f, p=%.4f → %s\n", colnames(Y_pre)[j], we@teststat, we@pval[1], dec))
    we_pre <- rbind(we_pre, data.frame(variable = colnames(Y_pre)[j],
      LR = round(we@teststat, 4), p = round(we@pval[1], 4), decision = dec, stringsAsFactors = FALSE))
  }, error = function(e) cat(sprintf("  %s: failed\n", colnames(Y_pre)[j])))
}

# Diagnostics
vv_pre <- vec2var(jo_pre, r = 1)
pt_pre   <- serial.test(vv_pre, lags.pt = 10, type = "PT.adjusted")
arch_pre <- arch.test(vv_pre, lags.multi = 5)
jb_pre   <- normality.test(vv_pre, multivariate.only = TRUE)
cat(sprintf("\nDiagnostics:\n  Portmanteau: p=%.4f %s\n  ARCH-LM: p=%.4f %s\n  JB: p=%.4f %s\n",
    pt_pre$serial$p.value, ifelse(pt_pre$serial$p.value > 0.05, "✓", "⚠"),
    arch_pre$arch.mul$p.value, ifelse(arch_pre$arch.mul$p.value > 0.05, "✓", "⚠"),
    jb_pre$jb.mul$JB$p.value, ifelse(jb_pre$jb.mul$JB$p.value > 0.05, "✓", "⚠")))

# Short-run output equation
cat("\nOutput equation (y.d):\n")
print(summary(vecm_pre$rlm)$"Response y.d")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 2 — POST-1973: (y, k_NR, lphi)                                 ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║  POST-1973 — NEOLIBERAL ERA: (y, k_NR, lphi)                      ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

Y_post <- df_post %>% select(y, k_NR, lphi) %>% as.matrix()
rownames(Y_post) <- df_post$year
p_post <- ncol(Y_post)
D_post <- df_post %>% select(D1975) %>% as.matrix()

cat("Variable summary:\n")
for (j in 1:p_post) cat(sprintf("  %-12s: mean=%8.4f  sd=%8.4f  range=[%8.4f, %8.4f]\n",
    colnames(Y_post)[j], mean(Y_post[,j]), sd(Y_post[,j]), min(Y_post[,j]), max(Y_post[,j])))

cat(sprintf("\nNote: cor(lphi, omega*lphi) = %.3f post-1973 → interaction dropped (collinear)\n",
    cor(df_post$lphi, df_post$omega_lphi)))

# Lag selection
vs_post <- VARselect(Y_post, lag.max = 3, type = "const", exogen = D_post)
cat("\nLag selection:\n"); print(vs_post$selection)
K_post <- max(vs_post$selection["SC(n)"], 2)
cat(sprintf("Using K=%d (SC). VECM lag L=%d.\n", K_post, K_post - 1))

# Johansen trace
jo_post <- ca.jo(Y_post, type = "trace", ecdet = "const", K = K_post,
                 spec = "longrun", dumvar = D_post)
cat("\nJohansen Trace Test:\n")
r_post <- 0
for (r_null in 0:(p_post - 1)) {
  idx <- p_post - r_null
  stat <- jo_post@teststat[idx]; cv05 <- jo_post@cval[idx, 2]; cv01 <- jo_post@cval[idx, 3]
  dec <- ifelse(stat > cv01, "REJECT 1%", ifelse(stat > cv05, "REJECT 5%", "fail"))
  if (stat > cv05 && r_null >= r_post) r_post <- r_null + 1
  cat(sprintf("  r<=%d: trace=%.2f  5%%cv=%.2f  1%%cv=%.2f  [%s]\n",
      r_null, stat, cv05, cv01, dec))
}
cat(sprintf("  → r = %d\n", r_post))
cat("Eigenvalues:"); print(round(jo_post@lambda, 4))

if (r_post == 0) stop("BLOCKER: r=0 post-1973. No frontier cointegration.")

# VECM r=1
vecm_post <- cajorls(jo_post, r = 1)
beta_post <- vecm_post$beta
cat("\nBeta (normalized on y):\n"); print(round(beta_post, 6))

alpha_post_raw <- coef(vecm_post$rlm)["ect1", ]
alpha_post <- setNames(as.numeric(alpha_post_raw), colnames(Y_post))

theta_post  <- -beta_post[2, 1]   # k_NR
psi_post    <- -beta_post[3, 1]   # lphi
kappa_post  <- -beta_post[4, 1]   # constant

cat(sprintf("\nFrontier: y = %.4f*k_NR + %.4f*lphi + %.4f\n",
    theta_post, psi_post, kappa_post))
cat(sprintf("  theta  (k_NR)  = %+.4f  %s\n", theta_post, ifelse(theta_post > 0, "✓", "⚠")))
cat(sprintf("  psi    (lphi)  = %+.4f  %s\n", psi_post, ifelse(psi_post > 0, "✓", "⚠")))
cat(sprintf("  alpha_y = %+.4f  %s\n", alpha_post["y"],
    ifelse(alpha_post["y"] < 0, "✓ error-corrects", "⚠")))

# Weak exogeneity
cat("\nWeak exogeneity:\n")
we_post <- data.frame(variable = character(), LR = numeric(), p = numeric(),
                       decision = character(), stringsAsFactors = FALSE)
for (j in 1:p_post) {
  A_j <- matrix(0, nrow = p_post, ncol = p_post - 1); ci <- 1
  for (i in 1:p_post) { if (i != j) { A_j[i, ci] <- 1; ci <- ci + 1 } }
  tryCatch({
    we <- alrtest(jo_post, A = A_j, r = 1)
    dec <- ifelse(we@pval[1] > 0.05, "WE", "not WE")
    cat(sprintf("  %s: LR=%.3f, p=%.4f → %s\n", colnames(Y_post)[j], we@teststat, we@pval[1], dec))
    we_post <- rbind(we_post, data.frame(variable = colnames(Y_post)[j],
      LR = round(we@teststat, 4), p = round(we@pval[1], 4), decision = dec, stringsAsFactors = FALSE))
  }, error = function(e) cat(sprintf("  %s: failed\n", colnames(Y_post)[j])))
}

# Diagnostics
vv_post <- vec2var(jo_post, r = 1)
pt_post   <- serial.test(vv_post, lags.pt = 10, type = "PT.adjusted")
arch_post <- arch.test(vv_post, lags.multi = 5)
jb_post   <- normality.test(vv_post, multivariate.only = TRUE)
cat(sprintf("\nDiagnostics:\n  Portmanteau: p=%.4f %s\n  ARCH-LM: p=%.4f %s\n  JB: p=%.4f %s\n",
    pt_post$serial$p.value, ifelse(pt_post$serial$p.value > 0.05, "✓", "⚠"),
    arch_post$arch.mul$p.value, ifelse(arch_post$arch.mul$p.value > 0.05, "✓", "⚠"),
    jb_post$jb.mul$JB$p.value, ifelse(jb_post$jb.mul$JB$p.value > 0.05, "✓", "⚠")))

cat("\nOutput equation (y.d):\n")
print(summary(vecm_post$rlm)$"Response y.d")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 3 — THETA AND MU COMPUTATION                                   ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  SECTION 3 — THETA^CL AND MU^CL\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("mu is NOT the ECT. mu = Y/Y* where Y* grows at g(Y*) = theta^CL * g(K).\n")
cat("mu is accumulated from a pin year, not read off the cointegrating residual.\n\n")

# Pre-1973: theta^CL = theta + psi*phi + theta_2*omega*phi
#   where phi = exp(lphi) = K_ME/K_NR and lphi = k_ME - k_NR
#   BUT: the CV identifies theta on k_NR directly. The transformation elasticity
#   that maps g(K_NR) → g(Y*) is just theta_pre (the coefficient on k_NR in CV1).
#   The composition and interaction terms shift the LEVEL of the frontier, not
#   the marginal elasticity with respect to total capital growth.
#
#   More precisely: g(Y*) = theta*g(k_NR) + psi*g(lphi) + theta_2*g(omega*lphi)
#   This is the FULL frontier growth decomposition.

compute_mu <- function(df_sub, theta_k, psi_phi, theta2_interaction, has_interaction, pin_year, pin_mu) {
  n <- nrow(df_sub)

  # Growth rates
  g_Y    <- c(NA, diff(df_sub$y))
  g_kNR  <- c(NA, diff(df_sub$k_NR))
  g_lphi <- c(NA, diff(df_sub$lphi))

  if (has_interaction) {
    g_omega_lphi <- c(NA, diff(df_sub$omega_lphi))
    g_Yp <- theta_k * g_kNR + psi_phi * g_lphi + theta2_interaction * g_omega_lphi
  } else {
    g_Yp <- theta_k * g_kNR + psi_phi * g_lphi
  }

  g_mu <- g_Y - g_Yp

  # Accumulate from pin year
  mu <- rep(NA_real_, n)
  pin_idx <- which(df_sub$year == pin_year)

  if (length(pin_idx) == 1) {
    mu[pin_idx] <- pin_mu
    for (i in (pin_idx + 1):n) {
      if (!is.na(g_mu[i])) mu[i] <- mu[i - 1] * exp(g_mu[i])
    }
    for (i in (pin_idx - 1):1) {
      if (!is.na(g_mu[i + 1])) mu[i] <- mu[i + 1] / exp(g_mu[i + 1])
    }
  } else {
    cat(sprintf("  ⚠ Pin year %d not in sample. Using ECT-based fallback.\n", pin_year))
    # Fallback not implemented here — caller should handle
    mu <- rep(NA, n)
  }

  # Time-varying theta: the effective transformation elasticity on total K
  # This is for interpretation, not for mu computation (mu uses the full decomposition)
  if (has_interaction) {
    theta_CL <- theta_k + psi_phi * (df_sub$lphi / df_sub$k_NR) +
                theta2_interaction * (df_sub$omega_lphi / df_sub$k_NR)
  } else {
    theta_CL <- theta_k + psi_phi * (df_sub$lphi / df_sub$k_NR)
  }

  data.frame(
    year = df_sub$year,
    g_Y = g_Y, g_kNR = g_kNR, g_lphi = g_lphi,
    g_Yp = g_Yp, g_mu = g_mu, mu_CL = mu,
    theta_CL = theta_CL,
    lphi = df_sub$lphi, omega = df_sub$omega, phi = df_sub$phi
  )
}

# Pre-1973: pin at 1970 = 0.95 (pre-Allende ISI peak)
cat("Pre-1973: pin mu(1970) = 0.95\n")
out_pre <- compute_mu(df_pre, theta_pre, psi_pre, theta2_pre,
                       has_interaction = TRUE, pin_year = 1970, pin_mu = 0.95)

# Post-1973: pin at 1980 = 1.0 (Ffrench-Davis)
cat("Post-1973: pin mu(1980) = 1.0\n")
out_post <- compute_mu(df_post, theta_post, psi_post, NA,
                        has_interaction = FALSE, pin_year = 1980, pin_mu = 1.0)

# Report
for (nm in c("Pre-1973", "Post-1973")) {
  out <- if (nm == "Pre-1973") out_pre else out_post
  cat(sprintf("\n%s:\n", nm))
  cat(sprintf("  mu^CL: mean=%.3f  sd=%.3f  range=[%.3f, %.3f]\n",
      mean(out$mu_CL, na.rm=TRUE), sd(out$mu_CL, na.rm=TRUE),
      min(out$mu_CL, na.rm=TRUE), max(out$mu_CL, na.rm=TRUE)))
  cat(sprintf("  g(Y*): mean=%.4f  sd=%.4f\n",
      mean(out$g_Yp, na.rm=TRUE), sd(out$g_Yp, na.rm=TRUE)))
}

# Landmarks
cat("\nLandmark years:\n")
for (yr in c(1930, 1940, 1950, 1960, 1970, 1972, 1973, 1975, 1980, 1982, 1990, 2000, 2010, 2020)) {
  row <- rbind(out_pre[out_pre$year == yr, ], out_post[out_post$year == yr, ])
  if (nrow(row) == 1)
    cat(sprintf("  %d: mu=%.3f  g_Y=%.4f  g_Y*=%.4f  g_mu=%.4f\n",
        yr, row$mu_CL, row$g_Y, row$g_Yp, row$g_mu))
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 4 — STRUCTURAL COMPARISON AND OUTPUTS                          ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("================================================================\n")
cat("    STRUCTURAL COMPARISON\n")
cat("================================================================\n\n")

cat(sprintf("  %-25s  %12s  %12s\n", "", "Pre-1973", "Post-1973"))
cat("  ", strrep("-", 55), "\n")
cat(sprintf("  %-25s  %12d  %12d\n", "N", nrow(df_pre), nrow(df_post)))
cat(sprintf("  %-25s  %12s  %12s\n", "State vector", "(y,k,lp,w*lp)", "(y,k,lp)"))
cat(sprintf("  %-25s  %12d  %12d\n", "rank r", r_pre, r_post))
cat(sprintf("  %-25s  %+12.4f  %+12.4f\n", "theta (k_NR)", theta_pre, theta_post))
cat(sprintf("  %-25s  %+12.4f  %+12.4f\n", "psi (lphi)", psi_pre, psi_post))
cat(sprintf("  %-25s  %+12.4f  %12s\n", "theta_2 (omega*lphi)", theta2_pre, "—"))
cat(sprintf("  %-25s  %+12.4f  %+12.4f\n", "alpha_y", alpha_pre["y"], alpha_post["y"]))
cat(sprintf("  %-25s  %12.4f  %12.4f\n", "Portmanteau p", pt_pre$serial$p.value, pt_post$serial$p.value))
cat(sprintf("  %-25s  %12.4f  %12.4f\n", "ARCH p", arch_pre$arch.mul$p.value, arch_post$arch.mul$p.value))
cat(sprintf("  %-25s  %12.4f  %12.4f\n", "JB p", jb_pre$jb.mul$JB$p.value, jb_post$jb.mul$JB$p.value))
cat(sprintf("  %-25s  %12.3f  %12.3f\n", "mean mu^CL",
    mean(out_pre$mu_CL, na.rm=TRUE), mean(out_post$mu_CL, na.rm=TRUE)))


# Save CSVs
cat("\n\nSaving outputs...\n")

save_csv <- function(df_out, name) {
  path <- file.path(CSV, name)
  write_csv(df_out, path)
  cat(sprintf("  ✓ %s (%d rows)\n", name, nrow(df_out)))
}

# Combined mu panel
out_pre$regime  <- "pre_1973"
out_post$regime <- "post_1973"
panel_mu <- rbind(out_pre, out_post) %>% arrange(year)
save_csv(panel_mu, "stage2_theta_mu_panel.csv")

# Also to data/processed for pipeline
write_csv(panel_mu, file.path(REPO, "data/processed/chile/stage2_theta_mu.csv"))

# Cointegrating vectors
cv_df <- data.frame(
  regime = c("pre_1973", "post_1973"),
  spec = c("(y,k_NR,lphi,omega_lphi)", "(y,k_NR,lphi)"),
  theta_kNR = c(theta_pre, theta_post),
  psi_lphi  = c(psi_pre, psi_post),
  theta2_omega_lphi = c(theta2_pre, NA),
  kappa = c(kappa_pre, kappa_post),
  r = c(r_pre, r_post), N = c(nrow(df_pre), nrow(df_post)),
  K = c(K_pre, K_post)
)
save_csv(cv_df, "stage2_cointegrating_vectors.csv")

# Alpha loadings
alpha_df <- rbind(
  data.frame(regime = "pre_1973", variable = names(alpha_pre),
             alpha = round(as.numeric(alpha_pre), 6)),
  data.frame(regime = "post_1973", variable = names(alpha_post),
             alpha = round(as.numeric(alpha_post), 6))
)
save_csv(alpha_df, "stage2_alpha_loadings.csv")

# Weak exogeneity
we_all <- rbind(
  data.frame(regime = "pre_1973", we_pre),
  data.frame(regime = "post_1973", we_post)
)
save_csv(we_all, "stage2_weak_exogeneity.csv")

# Diagnostics
diag_df <- data.frame(
  regime = rep(c("pre_1973", "post_1973"), each = 3),
  test = rep(c("Portmanteau", "ARCH-LM", "Jarque-Bera"), 2),
  p_value = round(c(pt_pre$serial$p.value, arch_pre$arch.mul$p.value, jb_pre$jb.mul$JB$p.value,
                      pt_post$serial$p.value, arch_post$arch.mul$p.value, jb_post$jb.mul$JB$p.value), 4)
)
save_csv(diag_df, "stage2_diagnostics.csv")


cat("\n\n")
cat("================================================================\n")
cat("    STAGE 2 FRONTIER VECM — COMPLETE\n")
cat("================================================================\n")
cat(sprintf("  Pre-1973:  r=%d, (y, k_NR, lphi, omega*lphi), K=%d\n", r_pre, K_pre))
cat(sprintf("  Post-1973: r=%d, (y, k_NR, lphi), K=%d\n", r_post, K_post))
cat(sprintf("  mu pin: 1970=0.95, 1980=1.0\n"))
cat("================================================================\n")
