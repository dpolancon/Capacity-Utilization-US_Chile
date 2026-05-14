# 41_test_beta_restrictions_all_cvs.R
# ═══════════════════════════════════════════════════════════════════════════════
# Test parametric restrictions on each CV (y-normalized):
#
#   R1: beta_j[omega]   = 0
#   R2: beta_j[omega_k] = 1/2
#
# Then test the additional restriction:
#   R3: alpha1 = 1  (H0: theta at omega=0 equals 1)
#   Under R1+R2: alpha1 = -beta_j[k], so R3 imposes beta_j[k] = -1
#   Joint R1+R2+R3: beta_j = (1, -1, 0, 0.5, phi_const) — df = 3
#
# Iterated over j = 1, 2, 3. Each test restricts one CV while leaving
# the other two unrestricted. Alpha loadings reported for robustness.
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

# ── Unrestricted beta (y-normalized) ────────────────────────────────────────
V <- jo@V[, 1:r]
v <- list()
for (j in 1:3) v[[j]] <- V[, j] / V[1, j]

cat("Unrestricted beta (all y-normalized):\n")
cat(sprintf("%-8s %10s %10s %10s\n", "", "CV1", "CV2", "CV3"))
rnames <- c("y","k","omega","omega_k","const")
for (i in 1:5) {
  cat(sprintf("%-8s %10.4f %10.4f %10.4f\n",
      rnames[i], v[[1]][i], v[[2]][i], v[[3]][i]))
}


# ═══════════════════════════════════════════════════════════════════════════════
# OPTIMIZER
# ═══════════════════════════════════════════════════════════════════════════════
optimize_beta <- function(negll, phi0, n_par) {
  set.seed(42)
  best_val <- 1e12; best_par <- phi0
  for (ci in 1:4) {
    scale <- c(1, 1.05, 0.95, 1)[ci]
    shift <- c(0, 0.5, -0.5, 1)[ci]
    for (j in 1:80) {
      p0 <- if (j == 1) phi0 * scale + shift else
            phi0 + rnorm(n_par, sd = abs(phi0) * 0.05 + 0.5)
      opt <- tryCatch({
        o1 <- optim(p0, negll, method="Nelder-Mead",
                    control=list(maxit=100000, reltol=1e-14))
        optim(o1$par, negll, method="Nelder-Mead",
              control=list(maxit=100000, reltol=1e-14))
      }, error=function(e) list(par=p0, value=1e12))
      if (opt$value < best_val) { best_val <- opt$value; best_par <- opt$par }
    }
  }
  bfgs <- tryCatch({
    optim(best_par, negll, method="BFGS",
          control=list(maxit=10000, reltol=1e-16))
  }, error=function(e) list(par=best_par, value=best_val))
  if (bfgs$value <= best_val) bfgs$par else best_par
}


# ═══════════════════════════════════════════════════════════════════════════════
# ALPHA INFERENCE HELPER
# ═══════════════════════════════════════════════════════════════════════════════
compute_alpha <- function(beta_res) {
  # Restricted VECM: equations 1-3 (omega_k row = 0, Gamma col omega_k = 0)
  vn <- c("y","k","omega","omega_k")
  dX <- diff(X); idx <- 2:(N-1); neff <- length(idx)
  dY <- dX[idx,]; dL <- dX[idx-1, 1:3]
  ECT <- (cbind(X,1) %*% beta_res)[idx,]
  RHS <- cbind(1, ECT, dL)

  alpha_mat <- matrix(NA, 3, r)
  alpha_t   <- matrix(NA, 3, r)
  r2_vec    <- numeric(3)

  for (i in 1:3) {
    f <- lm(dY[,i] ~ RHS - 1)
    s <- summary(f)
    cf <- s$coefficients
    for (j in 1:r) {
      alpha_mat[i, j] <- cf[1+j, 1]
      alpha_t[i, j]   <- cf[1+j, 3]
    }
    r2_vec[i] <- s$r.squared
  }
  rownames(alpha_mat) <- rownames(alpha_t) <- vn[1:3]
  colnames(alpha_mat) <- colnames(alpha_t) <- paste0("ECT", 1:r)
  list(alpha = alpha_mat, t_stat = alpha_t, r2 = r2_vec)
}


# ═══════════════════════════════════════════════════════════════════════════════
# ITERATE: R1+R2 (omega=0, omega_k=1/2) on each CV
# ═══════════════════════════════════════════════════════════════════════════════
results <- list()

for (j_test in 1:3) {
  cat(sprintf("\n%s\n", strrep("=", 70)))
  cat(sprintf("TEST: CV%d — R1: omega=0, R2: omega_k=1/2  (df=2)\n", j_test))
  cat(sprintf("%s\n", strrep("=", 70)))

  j_free <- setdiff(1:3, j_test)

  # R1+R2: beta_j = (1, phi_k, 0, 0.5, phi_const) — 2 free
  make_beta_r12 <- function(phi) {
    beta <- matrix(NA, 5, 3)
    beta[, 1] <- c(1, phi[1], 0, 0.5, phi[2])
    beta[, 2] <- c(1, phi[3], phi[4], phi[5], phi[6])
    beta[, 3] <- c(1, phi[7], phi[8], phi[9], phi[10])
    beta
  }
  negll_r12 <- function(phi) conc_negloglik(make_beta_r12(phi))

  v_test <- v[[j_test]]; v_f1 <- v[[j_free[1]]]; v_f2 <- v[[j_free[2]]]
  phi0_r12 <- c(v_test[2], v_test[5],
                v_f1[2], v_f1[3], v_f1[4], v_f1[5],
                v_f2[2], v_f2[3], v_f2[4], v_f2[5])

  cat("Optimizing R1+R2...\n")
  phi_hat_r12 <- optimize_beta(negll_r12, phi0_r12, 10)
  beta_r12 <- make_beta_r12(phi_hat_r12)
  rownames(beta_r12) <- rnames
  colnames(beta_r12) <- paste0("CV", c(j_test, j_free))

  bSb   <- t(beta_r12) %*% SKK %*% beta_r12
  Sig   <- S00 - S0K %*% beta_r12 %*% solve(bSb) %*% t(beta_r12) %*% SK0
  ld_r12 <- log(det(Sig))
  LR_r12 <- Neff * (ld_r12 - logdet_unrestricted)
  p_r12  <- pchisq(max(LR_r12, 0), df=2, lower.tail=FALSE)

  alpha1_j <- -beta_r12[2, 1]

  cat(sprintf("\n--- R1+R2 result ---\n"))
  cat(sprintf("LR = %.4f  df = 2  p = %.4f  %s\n",
      max(LR_r12,0), p_r12,
      ifelse(p_r12 > 0.05, "ACCEPTED", "REJECTED")))
  cat(sprintf("alpha1 = %.4f  (alpha1 > 1: %s)\n",
      alpha1_j, ifelse(alpha1_j > 1, "YES", "NO")))
  print(round(beta_r12, 4))

  # ── R1+R2+R3: additionally impose alpha1=1, i.e. k=-1 ─────────────────────
  # beta_j = (1, -1, 0, 0.5, phi_const) — 1 free
  cat(sprintf("\n--- R1+R2+R3: additionally impose alpha1=1 (k=-1)  (df=3) ---\n"))

  make_beta_r123 <- function(phi) {
    beta <- matrix(NA, 5, 3)
    beta[, 1] <- c(1, -1, 0, 0.5, phi[1])
    beta[, 2] <- c(1, phi[2], phi[3], phi[4], phi[5])
    beta[, 3] <- c(1, phi[6], phi[7], phi[8], phi[9])
    beta
  }
  negll_r123 <- function(phi) conc_negloglik(make_beta_r123(phi))

  phi0_r123 <- c(phi_hat_r12[2],
                 phi_hat_r12[3:6],
                 phi_hat_r12[7:10])

  cat("Optimizing R1+R2+R3...\n")
  phi_hat_r123 <- optimize_beta(negll_r123, phi0_r123, 9)
  beta_r123 <- make_beta_r123(phi_hat_r123)
  rownames(beta_r123) <- rnames
  colnames(beta_r123) <- paste0("CV", c(j_test, j_free))

  bSb3   <- t(beta_r123) %*% SKK %*% beta_r123
  Sig3   <- S00 - S0K %*% beta_r123 %*% solve(bSb3) %*% t(beta_r123) %*% SK0
  ld_r123 <- log(det(Sig3))
  LR_r123 <- Neff * (ld_r123 - logdet_unrestricted)
  p_r123  <- pchisq(max(LR_r123, 0), df=3, lower.tail=FALSE)

  # Incremental test: R3 given R1+R2
  LR_incr <- max(LR_r123, 0) - max(LR_r12, 0)
  p_incr  <- pchisq(max(LR_incr, 0), df=1, lower.tail=FALSE)

  cat(sprintf("Joint LR (R1+R2+R3 vs unrestricted) = %.4f  df=3  p=%.4f  %s\n",
      max(LR_r123,0), p_r123,
      ifelse(p_r123 > 0.05, "ACCEPTED", "REJECTED")))

  # One-sided test: H0: alpha1 <= 1 vs H1: alpha1 > 1
  # Under H0 (alpha1=1), incremental LR ~ chi2(1). For one-sided:
  # z = sign(alpha1-1) * sqrt(LR_incr), p_one = pnorm(-z)
  z_one <- sign(alpha1_j - 1) * sqrt(max(LR_incr, 0))
  p_one <- pnorm(-z_one)
  cat(sprintf("One-sided test H0: alpha1<=1 vs H1: alpha1>1:\n"))
  cat(sprintf("  alpha1_hat = %.4f  z = %.4f  p(one-sided) = %.6f  %s\n",
      alpha1_j, z_one, p_one,
      ifelse(p_one < 0.01, "REJECTED at 1% => alpha1 > 1",
      ifelse(p_one < 0.05, "REJECTED at 5% => alpha1 > 1",
                            "NOT REJECTED"))))

  # ── Alpha under R1+R2 restricted beta ──────────────────────────────────────
  cat(sprintf("\n--- Alpha loadings under R1+R2 (CV%d restricted) ---\n", j_test))
  alpha_info <- compute_alpha(beta_r12)

  cat(sprintf("%-7s", ""))
  for (jj in 1:r) cat(sprintf(" %15s", paste0("ECT", jj)))
  cat(sprintf("  %6s\n", "R2"))
  cat(strrep("-", 58), "\n")
  for (i in 1:3) {
    cat(sprintf("d(%-4s)", c("y","k","w")[i]))
    for (jj in 1:r) {
      cat(sprintf(" %+7.4f(%5.2f)", alpha_info$alpha[i,jj], alpha_info$t_stat[i,jj]))
    }
    cat(sprintf("  %.3f\n", alpha_info$r2[i]))
  }
  cat(sprintf("d(wk)      [0]            [0]            [0]\n"))

  results[[j_test]] <- list(
    cv = j_test,
    LR_r12 = max(LR_r12,0), p_r12 = p_r12,
    LR_r123 = max(LR_r123,0), p_r123 = p_r123,
    LR_incr = max(LR_incr,0), p_incr = p_incr,
    z_one = z_one, p_one = p_one,
    alpha1 = alpha1_j,
    beta_r12 = beta_r12,
    alpha = alpha_info
  )
}


# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY TABLE
# ═══════════════════════════════════════════════════════════════════════════════
cat(sprintf("\n%s\n", strrep("=", 80)))
cat("SUMMARY: Restriction tests by CV (all y-normalized)\n")
cat(sprintf("%s\n", strrep("=", 80)))
cat(sprintf("%-4s | %7s %5s | %7s %5s | %7s %7s %8s | %7s\n",
    "CV",
    "LR_R12", "p",
    "LR_R123", "p",
    "z_one", "p_one", "H1:a1>1",
    "alpha1"))
cat(strrep("-", 75), "\n")
for (j in 1:3) {
  r <- results[[j]]
  dec <- ifelse(r$p_one < 0.01, "***",
         ifelse(r$p_one < 0.05, "**",
         ifelse(r$p_one < 0.10, "*", "")))
  cat(sprintf("CV%d  | %7.4f %5.4f | %7.4f %5.4f | %+7.4f %7.6f %8s | %7.4f\n",
      j,
      r$LR_r12, r$p_r12,
      r$LR_r123, r$p_r123,
      r$z_one, r$p_one, dec,
      r$alpha1))
}
cat(strrep("=", 75), "\n")
cat("\nR1+R2: omega=0, omega_k=1/2 (df=2)\n")
cat("R1+R2+R3: omega=0, omega_k=1/2, alpha1=1 (df=3)\n")
cat("z_one / p_one: one-sided test H0: alpha1<=1 vs H1: alpha1>1\n")

# Save
saveRDS(results, file.path(csv_dir, "test_beta_restrictions_all_cvs.rds"))
cat("\nSaved: test_beta_restrictions_all_cvs.rds\n")
