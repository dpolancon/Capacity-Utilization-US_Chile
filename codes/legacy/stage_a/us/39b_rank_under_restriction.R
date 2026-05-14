# 39b_rank_under_restriction.R — does the system still need r=3 under restrictions?
library(urca); library(tseries)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"
nf <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
nf <- merge(nf, inc[, c("year","Py_fred")], by="year")
nf <- nf[order(nf$year),]
P <- nf$Py_fred[nf$year == 2024]
nf$y  <- log(nf$GVA_NF / (nf$Py_fred / P))
nf$k  <- log(nf$KGC_NF / (nf$Py_fred / P))
nf$w  <- nf$Wsh_NF
nf$wk <- nf$w * nf$k
X <- as.matrix(nf[, c("y","k","w","wk")])
N <- nrow(X)

jo <- ca.jo(X, type="trace", ecdet="const", K=2, spec="longrun")
vn <- c("y","k","omega","omega_k")

dX <- diff(X)
idx <- 2:(N-1)
neff <- length(idx)
dY <- dX[idx, ]
dL <- dX[idx - 1, 1:3]  # lagged diffs, col 4 excluded

# ── Compare r=2 vs r=3 under the restriction ────────────────────────────────
cat("=== RESTRICTED ESTIMATION: r=2 vs r=3 ===\n\n")

for (rr in 2:3) {
  beta <- jo@V[, 1:rr]
  ECT  <- cbind(X, 1) %*% beta
  E    <- ECT[idx, , drop = FALSE]
  RHS  <- cbind(1, E, dL)

  cat(sprintf("--- r = %d ---\n", rr))
  resids <- matrix(NA, neff, 4)
  for (i in 1:3) {
    f <- lm(dY[, i] ~ RHS - 1)
    s <- summary(f)
    cf <- s$coefficients
    cat(sprintf("  d(%s): ", vn[i]))
    for (j in 1:rr) {
      cat(sprintf("ECT%d=%+.4f(t=%5.2f) ", j, cf[1+j, 1], cf[1+j, 3]))
    }
    cat(sprintf(" R2=%.4f adj=%.4f\n", s$r.squared, s$adj.r.squared))
    resids[, i] <- residuals(f)
  }
  resids[, 4] <- dY[, 4]
  Sig <- crossprod(resids) / neff
  cat(sprintf("  log|Sigma| = %.6f\n\n", log(det(Sig))))
}

# ── F-test: does ECT3 add explanatory power? ────────────────────────────────
cat("=== F-TEST: ECT3 contribution (r=3 vs r=2) ===\n")

b3 <- jo@V[, 1:3]
b2 <- jo@V[, 1:2]
E3 <- cbind(X, 1) %*% b3
E2 <- cbind(X, 1) %*% b2
R3 <- cbind(1, E3[idx, ], dL)
R2 <- cbind(1, E2[idx, ], dL)

for (i in 1:3) {
  f3 <- lm(dY[, i] ~ R3 - 1)
  f2 <- lm(dY[, i] ~ R2 - 1)
  af <- anova(f2, f3)
  cat(sprintf("  d(%s): F = %.3f  p = %.4f  %s\n",
    vn[i], af$F[2], af$`Pr(>F)`[2],
    ifelse(af$`Pr(>F)`[2] < 0.05, "ECT3 SIGNIFICANT",
    ifelse(af$`Pr(>F)`[2] < 0.10, "ECT3 marginal", "ECT3 n.s."))))
}

# ── LR: r=2 restricted vs r=3 restricted ────────────────────────────────────
cat("\n=== LR TEST: r=2 restricted vs r=3 restricted ===\n")
# Compute Sigma for both
resid2 <- resid3 <- matrix(NA, neff, 4)
for (i in 1:3) {
  resid2[, i] <- residuals(lm(dY[, i] ~ R2 - 1))
  resid3[, i] <- residuals(lm(dY[, i] ~ R3 - 1))
}
resid2[, 4] <- resid3[, 4] <- dY[, 4]

Sig2 <- crossprod(resid2) / neff
Sig3 <- crossprod(resid3) / neff

LR_23 <- neff * (log(det(Sig2)) - log(det(Sig3)))
# df: r=3 has 3 extra ECT regressors across 3 equations = 3 extra params
df_23 <- 3
p_23 <- pchisq(LR_23, df = df_23, lower.tail = FALSE)

cat(sprintf("  log|Sigma_r2| = %.6f\n", log(det(Sig2))))
cat(sprintf("  log|Sigma_r3| = %.6f\n", log(det(Sig3))))
cat(sprintf("  LR = %.4f  df = %d  p = %.4f  %s\n",
    LR_23, df_23, p_23,
    ifelse(p_23 < 0.05, "r=3 adds significant information", "r=2 sufficient")))
