# 27_vecm_split_wk_exog.R
# Split-sample VECM: w_t exogenous, (y, k, wk) endogenous
# w_t enters short-run via dumvar, NOT in cointegrating vector
# wk interaction: alpha row = 0, Gamma row/col = 0 (maintained)
# Split: 1929-1973 | 1974-2024

library(urca)
library(vars)
if (!requireNamespace("numDeriv", quietly = TRUE)) install.packages("numDeriv")

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

d <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
nf_inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
d <- merge(d, nf_inc[, c("year", "Py_fred")], by = "year")
d <- d[order(d$year), ]

# Real log levels — each series deflated by its OWN deflator
# Y: deflated by Py (GDP deflator)
# K: already real (deflated by pK in GPIM construction) → use KGR_NF
Py_2024 <- d$Py_fred[d$year == 2024]
d$Y_real <- d$GVA_NF / (d$Py_fred / Py_2024)   # real GVA in 2024 output prices
d$y_t    <- log(d$Y_real)
d$k_t    <- log(d$KGR_NF)                       # log real K (pK-deflated, own prices)
d$w_t    <- d$Wsh_NF
d$w_k_t  <- d$w_t * d$k_t

cat(sprintf("Full sample: %d-%d (%d obs)\n", min(d$year), max(d$year), nrow(d)))
cat("Endogenous: (y_t, k_t, w_k_t) | Exogenous: w_t via dumvar\n")
cat("y_t = log(GVA/Py) in 2024 output prices | k_t = log(KGR_NF) in pK capital prices\n")
cat("Dual deflators. Log real levels. No index normalization.\n")
cat("CV1: y = theta1*k + theta2*wk + c1 | theta(w) = theta1 + theta2*w\n\n")

# ══════════════════════════════════════════════════════════════════════════════
# ESTIMATION FUNCTION
# ══════════════════════════════════════════════════════════════════════════════
estimate_subsample <- function(df, label, K = 2) {

  X <- as.matrix(df[, c("y_t", "k_t", "w_k_t")])
  W <- as.matrix(df[, "w_t", drop = FALSE])  # exogenous
  n <- nrow(X)

  cat(sprintf("\n{'='*60}\n"))
  cat(sprintf("=== %s: %d-%d (%d obs) ===\n",
      label, min(df$year), max(df$year), n))
  cat(sprintf("{'='*60}\n\n"))

  # Lag selection (on endogenous only)
  sel <- VARselect(X, lag.max = 4, type = "const", exogen = W)
  cat("Lag selection: "); print(sel$selection)
  cat(sprintf("Using K=%d\n\n", K))

  # Johansen with w_t exogenous
  jo <- ca.jo(X, type = "trace", ecdet = "const", K = K,
              spec = "longrun", dumvar = W)

  # Rank test
  p <- ncol(X)  # = 3
  cat("Trace test:\n")
  for (r0 in 0:(p - 1)) {
    idx <- p - r0
    cat(sprintf("  r<=%d: trace=%.2f  5%%cv=%.2f  %s\n",
        r0, jo@teststat[idx], jo@cval[idx, 2],
        ifelse(jo@teststat[idx] > jo@cval[idx, 2], "REJECT", "fail")))
  }
  r_hat <- sum(jo@teststat[p:1] > jo@cval[p:1, 2])
  cat(sprintf("Supported rank: r=%d\n\n", r_hat))

  # Unrestricted first eigenvector
  b1 <- jo@V[, 1] / jo@V[1, 1]  # normalize on y
  vnames <- c("y_t", "k_t", "w_k_t", "const")
  cat("Unrestricted CV1 (y=1):\n")
  for (i in 1:4)
    cat(sprintf("  %-6s = %.4f\n", vnames[i], b1[i]))

  th1_unr <- -b1[2]
  th2_unr <- -b1[3]
  c1_unr  <- -b1[4]
  cat(sprintf("\nImplied: theta1=%.4f, theta2=%.4f, c1=%.4f\n",
      th1_unr, th2_unr, c1_unr))

  # blrtest: restrict nothing beyond normalization (saturated at r=1)
  # beta = (1, -theta1, -theta2, -c1) on (y, k, wk, const)
  # 4 slots, 3 free (theta1, theta2, c1) + 1 norm = 4 → no overID
  # So blrtest with H being identity minus normalization:
  H_cv1 <- matrix(c(
    1, 0, 0,
    0, 1, 0,
    0, 0, 1,
    0, 0, 0    # const: need 4th column for c1
  ), nrow = 4, ncol = 3, byrow = TRUE)

  # Actually: 4 slots (3 vars + const), we want all free → H = 4x3
  # But that's df=0. For the MPF there's no overidentifying restriction
  # in a 3-var system with 3 free params. Just use the unrestricted.

  # Concentrated likelihood for Hessian
  Neff <- nrow(jo@Z0)
  M00 <- crossprod(jo@Z0)/Neff; M11 <- crossprod(jo@Z1)/Neff
  MKK <- crossprod(jo@ZK)/Neff
  M01 <- t(jo@Z0)%*%jo@Z1/Neff; M0K <- t(jo@Z0)%*%jo@ZK/Neff
  M1K <- t(jo@Z1)%*%jo@ZK/Neff; M11inv <- solve(M11)
  S00 <- M00 - M01%*%M11inv%*%t(M01)
  S0K <- M0K - M01%*%M11inv%*%M1K
  SK0 <- t(S0K); SKK <- MKK - t(M1K)%*%M11inv%*%M1K

  nll <- function(phi) {
    beta <- matrix(c(1, -phi[1], -phi[2], -phi[3]), ncol = 1)
    bSb <- as.numeric(t(beta) %*% SKK %*% beta)
    if (bSb < 1e-20) return(1e12)
    Sigma <- S00 - S0K %*% beta %*% (1/bSb) %*% t(beta) %*% SK0
    d_val <- det(Sigma)
    if (is.na(d_val) || d_val <= 0) return(1e12)
    (Neff / 2) * log(d_val)
  }

  phi <- c(th1_unr, th2_unr, c1_unr)
  hess <- numDeriv::hessian(nll, phi)
  eig  <- eigen(hess, symmetric = TRUE)
  nn   <- sum(eig$values <= 0)
  if (nn > 0) {
    ef <- max(eig$values) * 1e-8
    eig$values[eig$values < ef] <- ef
    vc <- solve(eig$vectors %*% diag(eig$values) %*% t(eig$vectors))
  } else { vc <- solve(hess) }
  se <- sqrt(diag(vc)); tst <- phi / se

  cat(sprintf("\n%-8s %10s %8s %8s\n", "Param", "Est", "SE", "t"))
  cat(strrep("-", 38), "\n")
  cat(sprintf("%-8s %10.4f %8.4f %8.3f\n", "theta1", phi[1], se[1], tst[1]))
  cat(sprintf("%-8s %10.4f %8.4f %8.3f\n", "theta2", phi[2], se[2], tst[2]))
  cat(sprintf("%-8s %10.4f %8.4f %8.3f\n", "c1", phi[3], se[3], tst[3]))
  cat(sprintf("Hessian: %d neg, cond=%.2e\n", nn,
      max(abs(eig$values)) / min(abs(eig$values))))

  # Centered theta
  w_bar <- mean(df$w_t)
  th_bar <- phi[1] + phi[2] * w_bar
  se_bar <- sqrt(vc[1,1] + w_bar^2*vc[2,2] + 2*w_bar*vc[1,2])
  cat(sprintf("\ntheta_bar(w=%.4f) = %.4f (SE=%.4f, t=%.3f)\n",
      w_bar, th_bar, se_bar, th_bar / se_bar))

  # Knife edge
  if (phi[2] < 0) {
    w_H <- (phi[1] - 1) / abs(phi[2])
    cat(sprintf("Knife edge: w_H=%.4f %s [%.4f, %.4f]\n", w_H,
        ifelse(w_H >= min(df$w_t) & w_H <= max(df$w_t), "IN RANGE", "outside"),
        min(df$w_t), max(df$w_t)))
  } else {
    w_H <- NA
    cat(sprintf("Knife edge: N/A (theta2 > 0)\n"))
  }

  # ECT stationarity
  mu_hat <- df$y_t - phi[1] * df$k_t - phi[2] * df$w_k_t - phi[3]
  adf <- ur.df(mu_hat, type = "drift", lags = 2)
  cat(sprintf("ECT1: mean=%.4f, sd=%.4f | ADF=%.3f (5%%cv=%.2f) — %s\n",
      mean(mu_hat), sd(mu_hat), adf@teststat[1], adf@cval[1, 2],
      ifelse(adf@teststat[1] < adf@cval[1, 2], "I(0)", "WARNING")))

  # Alpha (unrestricted at r=1)
  if (r_hat >= 1) {
    vecm <- cajorls(jo, r = 1)
    alpha_raw <- vecm$rlm$coefficients[1, ]  # first row = ECT1 loadings
    cat(sprintf("\nAlpha (ECT1 loadings):\n"))
    eq_names <- c("dy", "dk", "dwk")
    for (i in 1:3)
      cat(sprintf("  alpha[%s] = %+.4f\n", eq_names[i], alpha_raw[i]))
    cat(sprintf("  wk row: %+.4f (%s)\n", alpha_raw[3],
        ifelse(abs(alpha_raw[3]) < 0.05, "near zero — good", "nonzero")))
  }

  # Theta profile
  cat(sprintf("\nTheta profile:\n"))
  w_pts <- c(min(df$w_t), w_bar, max(df$w_t))
  w_nms <- c("w_min", "w_bar", "w_max")
  for (i in 1:3) {
    th <- phi[1] + phi[2] * w_pts[i]
    cat(sprintf("  w=%.4f (%s): theta=%.4f %s\n", w_pts[i], w_nms[i], th,
        ifelse(abs(th-1) < 0.05, "<- knife edge", "")))
  }

  list(theta1 = phi[1], theta2 = phi[2], c1 = phi[3],
       se = se, vc = vc, th_bar = th_bar, se_bar = se_bar,
       w_H = w_H, w_bar = w_bar, n = n, r = r_hat,
       years = range(df$year), mu_hat = mu_hat)
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN BOTH SUB-SAMPLES
# ══════════════════════════════════════════════════════════════════════════════
d_pre  <- d[d$year <= 1973, ]
d_post <- d[d$year >= 1974, ]

res_pre  <- estimate_subsample(d_pre,  "PRE-1973 (Fordist)")
res_post <- estimate_subsample(d_post, "POST-1974 (Neoliberal)")

# Full sample for reference
res_full <- estimate_subsample(d, "FULL SAMPLE")

# ══════════════════════════════════════════════════════════════════════════════
# COMPARISON
# ══════════════════════════════════════════════════════════════════════════════
cat(sprintf("\n%s\n", strrep("=", 65)))
cat("SPLIT-SAMPLE COMPARISON\n")
cat(sprintf("%s\n\n", strrep("=", 65)))

cat(sprintf("%-20s %12s %12s %12s\n", "Parameter", "Pre-1973", "Post-1974", "Full"))
cat(strrep("-", 60), "\n")
cat(sprintf("%-20s %12d %12d %12d\n", "n obs",
    res_pre$n, res_post$n, res_full$n))
cat(sprintf("%-20s %12d %12d %12d\n", "rank",
    res_pre$r, res_post$r, res_full$r))
cat(sprintf("%-20s %12.4f %12.4f %12.4f\n", "theta1",
    res_pre$theta1, res_post$theta1, res_full$theta1))
cat(sprintf("%-20s %12.4f %12.4f %12.4f\n", "theta2",
    res_pre$theta2, res_post$theta2, res_full$theta2))
cat(sprintf("%-20s %12.4f %12.4f %12.4f\n", "c1",
    res_pre$c1, res_post$c1, res_full$c1))
cat(sprintf("%-20s %12.4f %12.4f %12.4f\n", "theta_bar",
    res_pre$th_bar, res_post$th_bar, res_full$th_bar))
cat(sprintf("%-20s %12.4f %12.4f %12.4f\n", "SE(theta_bar)",
    res_pre$se_bar, res_post$se_bar, res_full$se_bar))
cat(sprintf("%-20s %12.4f %12.4f %12.4f\n", "w_H (knife edge)",
    ifelse(is.na(res_pre$w_H), NA, res_pre$w_H),
    ifelse(is.na(res_post$w_H), NA, res_post$w_H),
    ifelse(is.na(res_full$w_H), NA, res_full$w_H)))

cat(sprintf("\n%-20s %12s %12s\n", "Shift", "Pre→Post", "Magnitude"))
cat(strrep("-", 45), "\n")
cat(sprintf("%-20s %+12.4f %12.4f\n", "Δtheta1",
    res_post$theta1 - res_pre$theta1, abs(res_post$theta1 - res_pre$theta1)))
cat(sprintf("%-20s %+12.4f %12.4f\n", "Δtheta2",
    res_post$theta2 - res_pre$theta2, abs(res_post$theta2 - res_pre$theta2)))
cat(sprintf("%-20s %+12.4f %12.4f\n", "Δtheta_bar",
    res_post$th_bar - res_pre$th_bar, abs(res_post$th_bar - res_pre$th_bar)))
cat(sprintf("%-20s %+12.4f %12.4f\n", "Δw_H",
    ifelse(is.na(res_pre$w_H) | is.na(res_post$w_H), NA,
           res_post$w_H - res_pre$w_H),
    ifelse(is.na(res_pre$w_H) | is.na(res_post$w_H), NA,
           abs(res_post$w_H - res_pre$w_H))))

# Sign checks
cat(sprintf("\nSign checks:\n"))
cat(sprintf("  Pre:  theta1 %s 0 (%s), theta2 %s 0 (%s)\n",
    ifelse(res_pre$theta1>0,">","<"), ifelse(res_pre$theta1>0,"OK","WRONG"),
    ifelse(res_pre$theta2<0,"<",">"), ifelse(res_pre$theta2<0,"OK","WRONG")))
cat(sprintf("  Post: theta1 %s 0 (%s), theta2 %s 0 (%s)\n",
    ifelse(res_post$theta1>0,">","<"), ifelse(res_post$theta1>0,"OK","WRONG"),
    ifelse(res_post$theta2<0,"<",">"), ifelse(res_post$theta2<0,"OK","WRONG")))

# ══════════════════════════════════════════════════════════════════════════════
# SAVE
# ══════════════════════════════════════════════════════════════════════════════
outdir <- file.path(REPO, "output/stage_a/us/vecm_results")

comparison <- data.frame(
  parameter = c("theta1", "theta2", "c1", "theta_bar", "SE_theta_bar",
                "w_H", "n", "rank"),
  pre_1973  = c(res_pre$theta1, res_pre$theta2, res_pre$c1, res_pre$th_bar,
                res_pre$se_bar, res_pre$w_H, res_pre$n, res_pre$r),
  post_1974 = c(res_post$theta1, res_post$theta2, res_post$c1, res_post$th_bar,
                res_post$se_bar, res_post$w_H, res_post$n, res_post$r),
  full      = c(res_full$theta1, res_full$theta2, res_full$c1, res_full$th_bar,
                res_full$se_bar, res_full$w_H, res_full$n, res_full$r)
)
write.csv(comparison, file.path(outdir, "split_sample_comparison.csv"), row.names = FALSE)

cat(sprintf("\nSaved: split_sample_comparison.csv\n"))
cat(sprintf("\n=== DONE ===\n"))
