# 40_test_cv1_omega0_absolute_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Test beta restriction: omega = 0 in CV1
#
# Canonical model: r=3, alpha[omega_k,.]=0, Gamma[omega_k,.]=Gamma[.,omega_k]=0
# Beta restriction under test: CV1 has omega slot = 0 (MPF identification)
# CV2 and CV3 unrestricted.
#
# Method: concentrated profile likelihood (Johansen 1995, Ch. 7-8)
# with per-CV distinct restrictions.
#
# State vector: X = (y, k, omega, omega_k) — uncentered interaction omega*k
#
# CV1: beta1 = (free, free, 0, free, free) — 4 free after y-normalization = 3
# CV2: beta2 = (free, free, free, free, free) — 5 free after k-normalization = 4
# CV3: beta3 = (free, free, free, free, free) — 5 free after y-normalization = 4
# Total restricted free: 3 + 4 + 4 = 11
# Unrestricted: 3*(5-1) = 12 free (after 3 normalizations)
# df = 12 - 11 = 1
# ═══════════════════════════════════════════════════════════════════════════════

library(urca); library(tseries)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

csv_dir <- file.path(REPO, "output/stage_a/us/csv")

# ── Data ─────────────────────────────────────────────────────────────────────
nf  <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
nf  <- merge(nf, inc[, c("year","Py_fred")], by="year")
nf  <- nf[order(nf$year),]
P   <- nf$Py_fred[nf$year == 2024]
nf$y  <- log(nf$GVA_NF / (nf$Py_fred / P))
nf$k  <- log(nf$KGC_NF / (nf$Py_fred / P))
nf$w  <- nf$Wsh_NF
nf$wk <- nf$w * nf$k

X <- as.matrix(nf[, c("y","k","w","wk")])
cat(sprintf("omega range: [%.4f, %.4f], mean=%.4f\n",
    min(nf$w), max(nf$w), mean(nf$w)))
cat(sprintf("omega_k range: [%.4f, %.4f]\n", min(nf$wk), max(nf$wk)))
N <- nrow(X)
years <- nf$year

# ── Johansen + S-matrices ────────────────────────────────────────────────────
jo <- ca.jo(X, type="trace", ecdet="const", K=2, spec="longrun")
r  <- 3

Neff <- nrow(jo@Z0)
M00  <- crossprod(jo@Z0)/Neff; M11 <- crossprod(jo@Z1)/Neff
MKK  <- crossprod(jo@ZK)/Neff; M01 <- t(jo@Z0)%*%jo@Z1/Neff
M0K  <- t(jo@Z0)%*%jo@ZK/Neff; M1K <- t(jo@Z1)%*%jo@ZK/Neff
M11inv <- solve(M11)
S00 <- M00 - M01%*%M11inv%*%t(M01)
S0K <- M0K - M01%*%M11inv%*%M1K
SK0 <- t(S0K)
SKK <- MKK - t(M1K)%*%M11inv%*%M1K

conc_negloglik <- function(beta) {
  bSb <- t(beta) %*% SKK %*% beta
  d <- det(bSb)
  if (is.na(d) || d < 1e-20) return(1e12)
  Sigma <- S00 - S0K %*% beta %*% solve(bSb) %*% t(beta) %*% SK0
  ds <- det(Sigma)
  if (is.na(ds) || ds <= 0) return(1e12)
  (Neff/2) * log(ds)
}

logdet_unrestricted <- log(det(S00)) + sum(log(1 - jo@lambda[1:r]))

# ── Unrestricted beta from Johansen (for starting values) ────────────────────
V <- jo@V[, 1:r]
v1 <- V[,1]/V[1,1]  # norm y
v2 <- V[,2]/V[2,2]  # norm k
v3 <- V[,3]/V[1,3]  # norm y

cat(sprintf("Unrestricted CV1 (y-norm): k=%.4f omega=%.4f wk=%.4f const=%.4f\n",
    v1[2], v1[3], v1[4], v1[5]))


# ═══════════════════════════════════════════════════════════════════════════════
# RESTRICTED ESTIMATION: omega=0 in CV1
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("TEST: omega=0 in CV1 (MPF identification)\n")
cat(strrep("=", 60), "\n")

# phi = 11 free params:
# CV1 (y-norm): k, wk, const = 3 free (omega forced to 0)
# CV2 (k-norm): y, omega, wk, const = 4 free
# CV3 (y-norm): k, omega, wk, const = 4 free
make_beta_cv1r <- function(phi) {
  # CV1: (1, phi[1], 0, phi[2], phi[3])
  # CV2: (phi[4], 1, phi[5], phi[6], phi[7])
  # CV3: (1, phi[8], phi[9], phi[10], phi[11])
  matrix(c(
    1,       phi[1],  0,       phi[2],  phi[3],   # CV1 y-norm, omega=0
    phi[4],  1,       phi[5],  phi[6],  phi[7],   # CV2 k-norm
    1,       phi[8],  phi[9],  phi[10], phi[11]   # CV3 y-norm
  ), nrow=5, ncol=3, byrow=FALSE)
}

negll_cv1r <- function(phi) conc_negloglik(make_beta_cv1r(phi))

# Starting values from unrestricted eigenvectors
phi0 <- c(v1[2], v1[4], v1[5],      # CV1: k, wk, const (omega dropped)
          v2[1], v2[3], v2[4], v2[5], # CV2: y, omega, wk, const
          v3[2], v3[3], v3[4], v3[5]) # CV3: k, omega, wk, const

centers <- list(
  phi0,
  phi0 * c(1.05, 0.95, 1.02, 0.98, 1.1, 0.9, 1.0, 0.95, 1.05, 0.98, 1.02),
  phi0 * c(0.95, 1.05, 0.98, 1.02, 0.9, 1.1, 1.0, 1.05, 0.95, 1.02, 0.98),
  phi0 + c(0.5, -0.5, 1, -0.1, 2, 0.1, -1, 0.2, -5, 0.3, 3)
)

set.seed(42)
best_val <- 1e12; best_par <- phi0

cat("Multi-start: 4 centers x 60 perturbations...\n")
for (ci in seq_along(centers)) {
  ctr <- centers[[ci]]
  for (j in 1:60) {
    p0 <- if (j == 1) ctr else ctr + rnorm(11, sd = abs(ctr) * 0.05 + 0.5)
    opt <- tryCatch({
      o1 <- optim(p0, negll_cv1r, method="Nelder-Mead",
                  control=list(maxit=100000, reltol=1e-14))
      optim(o1$par, negll_cv1r, method="Nelder-Mead",
            control=list(maxit=100000, reltol=1e-14))
    }, error=function(e) list(par=p0, value=1e12))
    if (opt$value < best_val) { best_val <- opt$value; best_par <- opt$par }
  }
}

bfgs <- tryCatch({
  optim(best_par, negll_cv1r, method="BFGS",
        control=list(maxit=10000, reltol=1e-16))
}, error=function(e) list(par=best_par, value=best_val))

phi_hat <- if (bfgs$value <= best_val) bfgs$par else best_par

cat(sprintf("Converged. neg_loglik = %.6f\n", negll_cv1r(phi_hat)))

# ── Build restricted beta and compute LR ─────────────────────────────────────
beta_res <- make_beta_cv1r(phi_hat)
rownames(beta_res) <- c("y","k","omega","wk","const")
colnames(beta_res) <- c("CV1","CV2","CV3")

bSb_res    <- t(beta_res) %*% SKK %*% beta_res
Sigma_res  <- S00 - S0K %*% beta_res %*% solve(bSb_res) %*% t(beta_res) %*% SK0
logdet_res <- log(det(Sigma_res))

LR <- Neff * (logdet_res - logdet_unrestricted)
df_lr <- 1   # one restriction: omega=0 in CV1
p_lr  <- pchisq(max(LR, 0), df=df_lr, lower.tail=FALSE)

cat(sprintf("\n=== LR TEST: omega=0 in CV1 ===\n"))
cat(sprintf("log|Sigma| restricted:   %.6f\n", logdet_res))
cat(sprintf("log|Sigma| unrestricted: %.6f\n", logdet_unrestricted))
cat(sprintf("LR = %.4f  df = %d  p = %.4f\n", max(LR,0), df_lr, p_lr))
cat(sprintf("Decision: %s\n",
    ifelse(p_lr > 0.10, "ACCEPTED — omega=0 is free",
    ifelse(p_lr > 0.05, "MARGINAL",
                        "REJECTED — omega=0 costs likelihood"))))

# ── Display restricted beta ──────────────────────────────────────────────────
cat("\n=== RESTRICTED BETA (omega=0 in CV1) ===\n")
cat("CV1 norm y | CV2 norm k | CV3 norm y\n\n")
print(round(beta_res, 4))

# With uncentered interaction: wk = omega*k
# CV1: y = alpha1*k + alpha2*omega*k + c1
#      y = [alpha1 + alpha2*omega] * k + c1
#      theta(omega) = alpha1 + alpha2*omega
alpha1_hat <- -beta_res[2,1]
alpha2_hat <- -beta_res[4,1]
c1_hat     <- -beta_res[5,1]
omega_bar  <- mean(nf$w)
theta_at_bar <- alpha1_hat + alpha2_hat * omega_bar
omega_H <- (1 - alpha1_hat) / alpha2_hat

cat(sprintf("\nCV1: y = %.4f*k + %.4f*omega*k + %.4f\n",
    alpha1_hat, alpha2_hat, c1_hat))
cat(sprintf("     theta(omega) = %.4f + %.4f*omega\n",
    alpha1_hat, alpha2_hat))
cat(sprintf("     alpha1 = %.4f  [base elasticity]\n", alpha1_hat))
cat(sprintf("     alpha2 = %.4f  [distribution sensitivity]\n", alpha2_hat))
cat(sprintf("     theta at mean omega (%.4f) = %.4f\n", omega_bar, theta_at_bar))
cat(sprintf("     omega_H (knife-edge) = %.4f  [in sample: %s]\n",
    omega_H, ifelse(omega_H >= min(nf$w) & omega_H <= max(nf$w), "YES", "NO")))

# ── Alpha under restricted beta (equations 1-3 only, Gamma col 4 excluded) ──
cat("\n=== ALPHA UNDER RESTRICTED BETA ===\n")
vn <- c("y","k","omega","wk")
dX <- diff(X); idx <- 2:(N-1); neff <- length(idx)
dY <- dX[idx,]; dL <- dX[idx-1, 1:3]
ECT_res <- (cbind(X,1) %*% beta_res)[idx,]
RHS <- cbind(1, ECT_res, dL)

for (i in 1:3) {
  f <- lm(dY[,i] ~ RHS - 1)
  s <- summary(f)
  cf <- s$coefficients
  cat(sprintf("  d(%s): ", vn[i]))
  for (j in 1:3) cat(sprintf("ECT%d=%+.4f(t=%5.2f) ", j, cf[1+j,1], cf[1+j,3]))
  cat(sprintf(" R2=%.4f\n", s$r.squared))
}

# ── ECT stationarity ────────────────────────────────────────────────────────
cat("\n=== ECT STATIONARITY (restricted beta) ===\n")
ECT_full <- cbind(X,1) %*% beta_res
for (j in 1:3) {
  a <- adf.test(ECT_full[,j])
  cat(sprintf("ECT%d: ADF=%.3f  p=%.3f  %s\n", j, a$statistic, a$p.value,
      ifelse(a$p.value < 0.05, "I(0)", "WARNING")))
}

# ── Save ─────────────────────────────────────────────────────────────────────
saveRDS(list(
  beta_res = beta_res, phi = phi_hat,
  LR = max(LR,0), df = df_lr, p = p_lr,
  logdet_res = logdet_res, logdet_unr = logdet_unrestricted
), file.path(csv_dir, "test_cv1_omega0_objects.rds"))

cat("\nSaved: test_cv1_omega0_objects.rds\n")

cat("\n", strrep("=", 60), "\n")
cat("SUMMARY\n")
cat(strrep("=", 60), "\n")
cat(sprintf("Interaction: wk = omega*k  [uncentered]\n"))
cat(sprintf("Restriction: omega=0 in CV1 (MPF)\n"))
cat(sprintf("LR = %.4f  df=%d  p=%.4f  -> %s\n",
    max(LR,0), df_lr, p_lr,
    ifelse(p_lr > 0.05, "ACCEPTED", "REJECTED")))
cat(sprintf("CV1: theta(omega) = %.4f + %.4f*omega\n",
    alpha1_hat, alpha2_hat))
cat(sprintf("     theta at mean omega (%.4f) = %.4f\n", omega_bar, theta_at_bar))
cat(sprintf("     omega_H = %.4f\n", omega_H))
cat(strrep("=", 60), "\n")
