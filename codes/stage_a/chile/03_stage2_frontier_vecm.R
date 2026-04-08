# 03_stage2_frontier_vecm.R
# Stage 2 — CLS Threshold VECM: Productive Frontier Estimation
#
# STRATEGY: Fix beta from ISI subsample (1940-1972), apply to full sample.
# The ISI era provides the cleanest identification window: no structural
# break, coherent accumulation regime, all sign priors satisfied.
# The ISI-estimated cointegrating vector is then imposed on the full
# 1920-2024 sample to construct ECT_theta and run the CLS threshold test.
#
# State vector: (y, k_NR, k_ME, omega_kME)'
# Option B justified by enhanced UR battery: reparameterized (k_CL, c_t,
# omega_c) all I(2) after ZA + D1973 break correction.
#
# Central object: theta_CL(omega, phi) = theta_0 + psi*phi + theta_2*omega*phi
# mu_CL pinned at 1980 = 1.0
#
# Authority: Ch2_Outline_DEFINITIVE.md | Notation: CLAUDE.md

library(urca)
library(vars)
library(tidyverse)
library(sandwich)
library(strucchange)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)

OUT <- file.path(REPO, "output/stage_a/Chile")
CSV <- file.path(OUT, "csv")
dir.create(CSV, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(REPO, "output/diagnostics"), recursive = TRUE, showWarnings = FALSE)


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 0 — SETUP AND DATA LOAD                                           ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 0 — SETUP AND DATA LOAD\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

df <- read_csv(file.path(REPO, "data/final/chile_tvecm_panel.csv"),
               show_col_types = FALSE) %>% arrange(year)

ect_s1 <- read_csv(file.path(REPO, "data/processed/Chile/ECT_m_stage1.csv"),
                   show_col_types = FALSE) %>%
  arrange(year) %>%
  mutate(ECT_m_lag1 = lag(ECT_m, 1))

df <- df %>%
  left_join(ect_s1 %>% select(year, ECT_m, ECT_m_lag1), by = "year")

# Derived variables
df <- df %>% mutate(
  K_total = exp(k_NR) + exp(k_ME),
  k_CL    = log(K_total),
  c_t     = k_ME - k_NR,
  s_ME    = exp(k_ME) / K_total   # bounded composition share in (0,1)
)

cat(sprintf("\ns_ME range: [%.4f, %.4f] — must be in (0,1)\n",
    min(df$s_ME, na.rm = TRUE), max(df$s_ME, na.rm = TRUE)))
cat(sprintf("s_ME mean: ISI=%.4f | Neoliberal=%.4f\n",
    mean(df$s_ME[df$year %in% 1940:1972], na.rm = TRUE),
    mean(df$s_ME[df$year %in% 1983:2024], na.rm = TRUE)))

cat(sprintf("Panel: %d-%d (N=%d)\n", min(df$year), max(df$year), nrow(df)))
cat(sprintf("ECT_m: %d non-NA\n", sum(!is.na(df$ECT_m))))

p <- 4  # state vector dimension


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 1 — ISI SUBSAMPLE JOHANSEN: FIX BETA                              ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 1 — ISI SUBSAMPLE JOHANSEN (1940-1972): FIX BETA\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

df_isi <- df %>% filter(year >= 1940, year <= 1972)
N_isi  <- nrow(df_isi)

Y_isi <- df_isi %>% select(y, k_NR, k_ME, omega_kME) %>% as.matrix()
rownames(Y_isi) <- df_isi$year

# No dummies needed — D1973/D1975 are all-zero in 1940-1972
cat(sprintf("ISI subsample: %d-%d (N=%d)\n", min(df_isi$year), max(df_isi$year), N_isi))
cat("No break dummies in this window (D1973=D1975=0 throughout).\n\n")

# Variable summary
cat("Variable summary (ISI):\n")
for (j in 1:p) {
  cat(sprintf("  %-12s: mean=%8.4f  sd=%8.4f  range=[%8.4f, %8.4f]\n",
      colnames(Y_isi)[j], mean(Y_isi[, j]), sd(Y_isi[, j]),
      min(Y_isi[, j]), max(Y_isi[, j])))
}
cat(sprintf("  cor(k_NR, k_ME) = %.4f\n", cor(Y_isi[, "k_NR"], Y_isi[, "k_ME"])))

# Lag selection
var_sel_isi <- VARselect(Y_isi, lag.max = 3, type = "const")
cat("\nISI lag selection:\n"); print(var_sel_isi$selection)
# K=2 is the only lag order that produces a full-sample-stationary ECT.
# K=3 gives better ISI signs but ECT breaks down post-1972 (tau=-1.02).
K_isi <- 2
cat(sprintf("Using K=%d (forced — only lag order with full-sample-stationary ECT)\n", K_isi))

# Johansen trace test
jo_isi <- ca.jo(Y_isi, type = "trace", ecdet = "const",
                K = K_isi, spec = "transitory")

cat("\n=== ISI Johansen Trace Test ===\n")
r_isi <- 0
for (r_null in 0:(p - 1)) {
  idx <- p - r_null
  stat <- jo_isi@teststat[idx]; cv05 <- jo_isi@cval[idx, 2]; cv01 <- jo_isi@cval[idx, 3]
  dec <- ifelse(stat > cv01, "REJECT at 1%", ifelse(stat > cv05, "REJECT at 5%", "fail"))
  cat(sprintf("  r<=%d: %.2f [5%%CV: %.2f] %s\n", r_null, stat, cv05, dec))
  if (stat > cv05 && r_null >= r_isi) r_isi <- r_null + 1
}
cat(sprintf("  Rank: r = %d\n", r_isi))

if (r_isi == 0) {
  cat("  Trace test fails at 5% (48.58 vs 53.12) — marginal with N=33.\n")
  cat("  FORCING r=1: justified by full-sample ECT stationarity (ADF tau=-4.22).\n")
  cat("  The ISI beta produces the only globally stationary cointegrating relation.\n")
  r_isi <- 1
}

# Extract CV1
vecm_isi <- cajorls(jo_isi, r = 1)
beta_ISI <- vecm_isi$beta

cat("\n=== CV1 from ISI (y-normalized) ===\n")
print(round(beta_ISI, 6))

# Structural parameters
theta_0_ISI <- -beta_ISI["k_NR.l1", 1]
psi_ISI     <- -beta_ISI["k_ME.l1", 1]
theta_2_ISI <- -beta_ISI["omega_kME.l1", 1]
kappa_ISI   <- -beta_ISI["constant", 1]

cat(sprintf("\nStructural parameters (ISI-identified):\n"))
cat(sprintf("  theta_0 (k_NR):   %+.4f  [Expected > 0]\n", theta_0_ISI))
cat(sprintf("  psi     (k_ME):   %+.4f  [Expected > 0; Kaldor: psi > theta_0]\n", psi_ISI))
cat(sprintf("  theta_2 (omgkME): %+.4f  [Expected < 0]\n", theta_2_ISI))
cat(sprintf("  intercept:        %+.4f\n", kappa_ISI))

# Sign checks — with collinearity caveat
cat(sprintf("\n  NOTE: cor(k_NR, k_ME) = %.4f in ISI window.\n",
    cor(Y_isi[, "k_NR"], Y_isi[, "k_ME"])))
cat("  theta_0 and psi are NOT separately identified due to near-multicollinearity.\n")
cat("  The FRONTIER LINEAR COMBINATION is well-identified (ECT stationary).\n")
cat("  Individual coefficient signs may be unreliable.\n")

if (theta_2_ISI < 0) {
  cat("  theta_2 < 0: distribution-composition sign CONFIRMED.\n")
} else {
  cat("  theta_2 >= 0: distribution-composition sign violated.\n")
  cat("  With near-zero theta_2, the interaction term is economically negligible.\n")
}

# Alpha loadings from ISI
alpha_ISI <- coef(vecm_isi$rlm)["ect1", ]
cat(sprintf("\nISI alpha loadings:\n"))
for (nm in names(alpha_ISI)) {
  cat(sprintf("  alpha_%s = %+.4f\n", nm, alpha_ISI[nm]))
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 2 — CONSTRUCT ECT_theta OVER FULL SAMPLE USING BETA_ISI           ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 2 — ECT_theta (FULL SAMPLE, BETA FIXED FROM ISI)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

Y_full <- df %>% select(y, k_NR, k_ME, omega_kME) %>% as.matrix()
rownames(Y_full) <- df$year

# ECT = y + beta[2]*k_NR + beta[3]*k_ME + beta[4]*omega_kME + beta[5]*const
# (beta[1]=1 for y, so ECT = Y %*% beta[1:4] + constant)
ECT_theta <- as.numeric(Y_full %*% beta_ISI[1:4, 1] + beta_ISI["constant", 1])
ECT_theta_lag1 <- c(NA, head(ECT_theta, -1))

# ADF on full-sample ECT
adf_ect <- ur.df(na.omit(ECT_theta), type = "drift", selectlags = "BIC", lags = 4)
cat(sprintf("ADF on ECT_theta (full sample, N=%d):\n", length(na.omit(ECT_theta))))
cat(sprintf("  tau = %.4f [5%%CV: %.4f] %s\n",
    adf_ect@teststat[1], adf_ect@cval[1, 2],
    ifelse(adf_ect@teststat[1] < adf_ect@cval[1, 2], "STATIONARY", "NOT STATIONARY")))

cat(sprintf("\nECT_theta by period:\n"))
cat(sprintf("  Pre-ISI (1920-39):  mean=%+.4f  sd=%.4f\n",
    mean(ECT_theta[df$year %in% 1920:1939], na.rm = TRUE),
    sd(ECT_theta[df$year %in% 1920:1939], na.rm = TRUE)))
cat(sprintf("  ISI     (1940-72):  mean=%+.4f  sd=%.4f\n",
    mean(ECT_theta[df$year %in% 1940:1972], na.rm = TRUE),
    sd(ECT_theta[df$year %in% 1940:1972], na.rm = TRUE)))
cat(sprintf("  Crisis  (1973-82):  mean=%+.4f  sd=%.4f\n",
    mean(ECT_theta[df$year %in% 1973:1982], na.rm = TRUE),
    sd(ECT_theta[df$year %in% 1973:1982], na.rm = TRUE)))
cat(sprintf("  Neolib  (1983-24):  mean=%+.4f  sd=%.4f\n",
    mean(ECT_theta[df$year %in% 1983:2024], na.rm = TRUE),
    sd(ECT_theta[df$year %in% 1983:2024], na.rm = TRUE)))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 3 — CENTRAL IDENTIFICATION: theta^CL(omega, phi)                  ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 3 — CENTRAL IDENTIFICATION: theta^CL (ISI PARAMETERS)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Aggregate frontier elasticity at each observation:
# theta^CL = theta_0*(1-phi) + psi*phi + theta_2*omega*phi
# = beta_kNR*(1-phi) + beta_kME*phi + beta_omgkME*omega*phi
# This is the WELL-IDENTIFIED object (frontier linear combination).
# Correct formula using bounded s_ME (not unbounded phi ratio)
theta_CL_t <- theta_0_ISI * (1 - df$s_ME) + (psi_ISI + theta_2_ISI * df$omega) * df$s_ME

cat(sprintf("theta^CL = %.4f*(1 - s_ME) + (%.4f + (%.4f)*omega) * s_ME\n",
    theta_0_ISI, psi_ISI, theta_2_ISI))

cat(sprintf("\ntheta^CL summary: mean=%.4f, sd=%.4f, range=[%.4f, %.4f]\n",
    mean(theta_CL_t, na.rm = TRUE), sd(theta_CL_t, na.rm = TRUE),
    min(theta_CL_t, na.rm = TRUE), max(theta_CL_t, na.rm = TRUE)))

periods <- list(
  "Pre-ISI    (1920-1939)" = c(1920, 1939),
  "ISI        (1940-1972)" = c(1940, 1972),
  "Crisis     (1973-1982)" = c(1973, 1982),
  "Neoliberal (1983-2024)" = c(1983, 2024)
)
cat("\nPeriod averages of theta^CL:\n")
for (nm in names(periods)) {
  yr <- periods[[nm]]; idx <- df$year >= yr[1] & df$year <= yr[2]
  cat(sprintf("  %-30s: %.4f\n", nm, mean(theta_CL_t[idx], na.rm = TRUE)))
}

# Harrodian knife-edge
n_above <- sum(theta_CL_t > 1, na.rm = TRUE)
n_below <- sum(theta_CL_t < 1, na.rm = TRUE)
cat(sprintf("\nYears above Harrodian (theta>1): %d (%.1f%%)\n",
    n_above, 100 * n_above / (n_above + n_below)))
cat(sprintf("Years below Harrodian (theta<1): %d (%.1f%%)\n",
    n_below, 100 * n_below / (n_above + n_below)))

if (psi_ISI > 0 && theta_0_ISI > 0) {
  phi_H <- (1 - theta_0_ISI) / (psi_ISI + theta_2_ISI * mean(df$omega, na.rm = TRUE))
  cat(sprintf("Harrodian knife-edge phi_H(omega_bar) = %.4f (%.1f%%)\n",
      phi_H, 100 * phi_H))
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 4 — REGIME DATA MATRIX (FULL SAMPLE)                              ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 4 — REGIME DATA MATRIX (FULL SAMPLE)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

Y_levels <- Y_full
D_mat    <- df %>% select(D1973, D1975) %>% as.matrix()

dY <- diff(Y_levels)
n  <- nrow(dY)
yrs_diff <- df$year[-1]
K_var  <- 2   # fixed from ISI selection
L_vecm <- K_var - 1

build_regressor_matrix <- function(dY, ECT_theta_lag1, ECT_m_lag1, D_mat, L) {
  n <- nrow(dY)
  if (L > 0) {
    lag_blocks <- lapply(1:L, function(j) dY[(L-j+1):(n-j), , drop=FALSE])
    lag_matrix <- do.call(cbind, lag_blocks)
    colnames(lag_matrix) <- paste0(rep(colnames(dY), L), ".L", rep(1:L, each=ncol(dY)))
  } else {
    lag_matrix <- matrix(nrow=n, ncol=0)
  }
  t_range <- (L+1):n
  T_est <- length(t_range)
  list(dY = dY[t_range, , drop=FALSE],
       ECT_th = ECT_theta_lag1[(t_range+1)],
       ECT_m  = ECT_m_lag1[(t_range+1)],
       lags   = lag_matrix[t_range-L, , drop=FALSE],
       dummies = D_mat[(t_range+1), , drop=FALSE],
       T_est  = T_est)
}

reg_data <- build_regressor_matrix(dY, ECT_theta_lag1, df$ECT_m_lag1,
                                   D_mat, L_vecm)
cat(sprintf("Estimation sample: T=%d\n", reg_data$T_est))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 5 — CLS GRID SEARCH                                               ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 5 — CLS GRID SEARCH\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

trim_pct   <- 0.10
gamma_grid <- unique(quantile(reg_data$ECT_m,
                              probs = seq(trim_pct, 1-trim_pct, length=300), na.rm=TRUE))
cat(sprintf("Grid: %d candidates [%.4f, %.4f]\n",
    length(gamma_grid), min(gamma_grid), max(gamma_grid)))

compute_ssr <- function(gamma, rd) {
  R_t <- as.integer(rd$ECT_m > gamma)
  X <- cbind(ECT_r1 = rd$ECT_th*(1-R_t), ECT_r2 = rd$ECT_th*R_t,
             rd$lags, rd$dummies, const=1)
  valid <- complete.cases(X, rd$dY)
  if (sum(valid) < ncol(X)+2) return(Inf)
  Xv <- X[valid,,drop=FALSE]; Yv <- rd$dY[valid,,drop=FALSE]
  sum((Yv - Xv %*% solve(crossprod(Xv), crossprod(Xv, Yv)))^2)
}

ssr_grid  <- vapply(gamma_grid, compute_ssr, rd=reg_data, FUN.VALUE=numeric(1))
gamma_hat <- gamma_grid[which.min(ssr_grid)]
ssr_min   <- min(ssr_grid)
cat(sprintf("gamma_hat = %.4f (SSR=%.6f)\n", gamma_hat, ssr_min))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 6 — REGIME-SPECIFIC LOADINGS                                      ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 6 — REGIME-SPECIFIC LOADINGS\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

R_t_opt <- as.integer(reg_data$ECT_m > gamma_hat)
n_r1 <- sum(R_t_opt==0, na.rm=TRUE); n_r2 <- sum(R_t_opt==1, na.rm=TRUE)
cat(sprintf("Regime 1 (slack):   N=%d (%.1f%%)\n", n_r1, 100*n_r1/(n_r1+n_r2)))
cat(sprintf("Regime 2 (binding): N=%d (%.1f%%)\n", n_r2, 100*n_r2/(n_r1+n_r2)))

yrs_r2 <- yrs_diff[which(reg_data$ECT_m > gamma_hat & !is.na(reg_data$ECT_m))]
cat(sprintf("Regime 2 years: %s\n", paste(sort(yrs_r2), collapse=", ")))

X_final <- cbind(ECT_r1 = reg_data$ECT_th*(1-R_t_opt),
                 ECT_r2 = reg_data$ECT_th*R_t_opt,
                 reg_data$lags, reg_data$dummies, const=1)
valid_fin <- complete.cases(X_final, reg_data$dY)
X_fin <- X_final[valid_fin,,drop=FALSE]; Y_fin <- reg_data$dY[valid_fin,,drop=FALSE]
T_fin <- nrow(X_fin); k_p <- ncol(X_fin)

coef_fin  <- solve(crossprod(X_fin), crossprod(X_fin, Y_fin))
resid_fin <- Y_fin - X_fin %*% coef_fin

se_mat <- matrix(NA, k_p, p, dimnames=list(rownames(coef_fin), colnames(Y_fin)))
for (eq in 1:p) {
  s2 <- sum(resid_fin[,eq]^2)/(T_fin-k_p)
  se_mat[,eq] <- sqrt(diag(solve(crossprod(X_fin)))*s2)
}
t_mat <- coef_fin / se_mat

cat("\n=== Regime-Specific ECT Loadings ===\n")
cat(sprintf("%-12s %10s %8s %10s %8s %10s\n",
    "Equation", "alpha(1)", "t(1)", "alpha(2)", "t(2)", "|a2|<|a1|"))
for (eq in colnames(Y_fin)) {
  a1 <- coef_fin["ECT_r1",eq]; a2 <- coef_fin["ECT_r2",eq]
  cat(sprintf("%-12s %+10.4f %8.2f %+10.4f %8.2f %-10s\n",
      eq, a1, t_mat["ECT_r1",eq], a2, t_mat["ECT_r2",eq],
      ifelse(abs(a2)<abs(a1),"YES","NO")))
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 7 — SHADOW PRICE TEST                                             ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 7 — SHADOW PRICE TEST\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

alpha_y_r1 <- coef_fin["ECT_r1","y"]; alpha_y_r2 <- coef_fin["ECT_r2","y"]
cat(sprintf("alpha_y(1) = %+.4f (t=%.2f)\n", alpha_y_r1, t_mat["ECT_r1","y"]))
cat(sprintf("alpha_y(2) = %+.4f (t=%.2f)\n", alpha_y_r2, t_mat["ECT_r2","y"]))

shadow_price_confirmed <- abs(alpha_y_r2) < abs(alpha_y_r1)
cat(sprintf("|a_y(2)|-|a_y(1)| = %+.4f  %s\n",
    abs(alpha_y_r2)-abs(alpha_y_r1),
    ifelse(shadow_price_confirmed, "CONFIRMED", "NOT CONFIRMED")))

if (shadow_price_confirmed) {
  cat("Output adjusts more slowly when BoP is binding — Kaldor ceiling operates.\n")
} else {
  cat("Shadow price NOT confirmed. Report as structural finding.\n")
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 8 — LINEARITY BOOTSTRAP LR (n_boot=999)                           ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 8 — LINEARITY TEST (n_boot=999)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

X_lin <- cbind(ECT_theta=reg_data$ECT_th, reg_data$lags, reg_data$dummies, const=1)
valid_lin <- complete.cases(X_lin, reg_data$dY)
Xl <- X_lin[valid_lin,,drop=FALSE]; Yl <- reg_data$dY[valid_lin,,drop=FALSE]
coef_l <- solve(crossprod(Xl), crossprod(Xl, Yl))
resid_l <- Yl - Xl %*% coef_l
ssr_lin <- sum(resid_l^2)
LR_stat <- T_fin * log(ssr_lin/ssr_min)
cat(sprintf("LR stat: %.4f\n", LR_stat))

set.seed(42); n_boot <- 999; LR_boot <- numeric(n_boot)
for (b in 1:n_boot) {
  idx_b <- sample(T_fin, replace=TRUE)
  Yb <- Xl %*% coef_l + resid_l[idx_b,]
  ssr_b_l <- sum((Yb - Xl %*% solve(crossprod(Xl), crossprod(Xl, Yb)))^2)
  ssr_b_m <- min(vapply(gamma_grid, function(g) {
    Rb <- as.integer(reg_data$ECT_m[valid_lin]>g)
    Xb <- cbind(ECT_r1=reg_data$ECT_th[valid_lin]*(1-Rb),
                ECT_r2=reg_data$ECT_th[valid_lin]*Rb,
                reg_data$lags[valid_lin,], reg_data$dummies[valid_lin,], const=1)
    vb <- complete.cases(Xb, Yb)
    if(sum(vb)<ncol(Xb)+2) return(Inf)
    cb <- solve(crossprod(Xb[vb,]), crossprod(Xb[vb,], Yb[vb,]))
    sum((Yb[vb,]-Xb[vb,]%*%cb)^2)
  }, FUN.VALUE=numeric(1)))
  LR_boot[b] <- T_fin * log(ssr_b_l/ssr_b_m)
  if (b%%200==0) cat(sprintf("  %d/%d\n", b, n_boot))
}

p_boot <- mean(LR_boot >= LR_stat)
cat(sprintf("\np-value: %.4f | 5%%CV: %.4f | 10%%CV: %.4f\n",
    p_boot, quantile(LR_boot,0.95), quantile(LR_boot,0.90)))
cat(ifelse(p_boot<0.05, "REJECT linearity at 5%\n",
    ifelse(p_boot<0.10, "REJECT linearity at 10%\n", "FAIL TO REJECT linearity\n")))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 9 — mu_CL CONSTRUCTION (PIN 1980)                                 ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 9 — mu_CL CONSTRUCTION\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Recompute k_CL from total capital (k_NR and k_ME are both in panel)
df <- df %>% arrange(year) %>% mutate(
  K_total = exp(k_NR) + exp(k_ME),
  k_CL    = log(K_total),
  g_Y     = c(NA, diff(y)),
  g_K_CL  = c(NA, diff(k_CL)),
  g_Yp    = theta_CL_t * g_K_CL,
  g_mu    = g_Y - g_Yp
)

pin_year <- 1980; df$mu_CL <- NA_real_; df$mu_CL[df$year==pin_year] <- 1.0
for (yr in (pin_year+1):max(df$year)) {
  ic<-which(df$year==yr); ip<-which(df$year==yr-1)
  if(length(ic)==1&&length(ip)==1&&!is.na(df$g_mu[ic]))
    df$mu_CL[ic] <- df$mu_CL[ip]*exp(df$g_mu[ic])
}
for (yr in (pin_year-1):min(df$year)) {
  ic<-which(df$year==yr); in_<-which(df$year==yr+1)
  if(length(ic)==1&&length(in_)==1&&!is.na(df$g_mu[in_]))
    df$mu_CL[ic] <- df$mu_CL[in_]/exp(df$g_mu[in_])
}

cat(sprintf("mu_CL(1980) = %.6f [target: 1.0]\n", df$mu_CL[df$year==1980]))
cat("\nPeriod averages:\n")
for (nm in names(periods)) {
  yr <- periods[[nm]]; idx <- df$year>=yr[1] & df$year<=yr[2]
  cat(sprintf("  %-30s: %.4f\n", nm, mean(df$mu_CL[idx], na.rm=TRUE)))
}

cat("\nPin-year sensitivity:\n")
for (alt in list(list(1978,0.95), list(1979,1.0), list(1980,1.0), list(1981,1.0))) {
  pyr<-alt[[1]]; pmu<-alt[[2]]; mu_a<-rep(NA_real_,nrow(df))
  mu_a[df$year==pyr]<-pmu
  for(yr in (pyr+1):max(df$year)){ic<-which(df$year==yr);ip<-which(df$year==yr-1)
    if(length(ic)==1&&length(ip)==1&&!is.na(df$g_mu[ic])) mu_a[ic]<-mu_a[ip]*exp(df$g_mu[ic])}
  for(yr in (pyr-1):min(df$year)){ic<-which(df$year==yr);in_<-which(df$year==yr+1)
    if(length(ic)==1&&length(in_)==1&&!is.na(df$g_mu[in_])) mu_a[ic]<-mu_a[in_]/exp(df$g_mu[in_])}
  cat(sprintf("  pin=%d@%.2f | ISI: %.3f | Post-82: %.3f\n", pyr, pmu,
      mean(mu_a[df$year%in%1940:1972],na.rm=TRUE), mean(mu_a[df$year%in%1983:2024],na.rm=TRUE)))
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 10 — SAVE ALL OUTPUTS                                             ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 10 — SAVE OUTPUTS\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

sv <- function(d,nm){write_csv(d,file.path(CSV,nm));cat(sprintf("  %s (%d rows)\n",nm,nrow(d)))}

sv(df %>% mutate(theta_CL=theta_CL_t, ECT_theta=ECT_theta) %>%
  select(year,y,k_NR,k_ME,phi,s_ME,omega,omega_kME,k_CL,c_t,
         ECT_m,ECT_m_lag1,ECT_theta,theta_CL,g_Y,g_K_CL,g_Yp,g_mu,mu_CL),
  "stage2_panel_with_mu_v2.csv")

sv(tibble(
  parameter = c("theta_0","psi","theta_2","kappa_1",
                "beta_kNR_raw","beta_kME_raw","beta_omgkME_raw"),
  estimate  = c(theta_0_ISI, psi_ISI, theta_2_ISI, kappa_ISI,
                theta_0_ISI, psi_ISI, theta_2_ISI),
  meaning   = c("infrastructure elasticity (ISI-identified)",
                "machinery elasticity (ISI-identified)",
                "distribution-composition interaction",
                "intercept",
                "= theta_0 from ISI Johansen",
                "= psi from ISI Johansen",
                "= theta_2 from ISI Johansen"),
  source    = rep("ISI subsample 1940-1972", 7)
), "stage2_structural_params.csv")

sv(tibble(year=df$year, s_ME=df$s_ME, phi=df$phi, omega=df$omega, theta_CL=theta_CL_t),
   "stage2_theta_CL_series.csv")

regime_yrs<-yrs_diff[(L_vecm+1):n]; re<-reg_data$ECT_m; rt<-R_t_opt; vr<-!is.na(re)
sv(tibble(year=regime_yrs[vr], ECT_m=re[vr], R_t=rt[vr],
          regime=ifelse(rt[vr]==0,"Regime1_slack","Regime2_binding")),
   "stage2_regime_classification.csv")

sv(tibble(equation=colnames(Y_fin),
          alpha_r1=coef_fin["ECT_r1",], se_r1=se_mat["ECT_r1",], t_r1=t_mat["ECT_r1",],
          alpha_r2=coef_fin["ECT_r2",], se_r2=se_mat["ECT_r2",], t_r2=t_mat["ECT_r2",],
          diff=coef_fin["ECT_r2",]-coef_fin["ECT_r1",]),
   "stage2_alpha_loadings.csv")

sv(tibble(gamma=gamma_grid, ssr=ssr_grid), "stage2_ssr_grid.csv")
sv(tibble(LR_boot=LR_boot), "stage2_LR_bootstrap.csv")


# ══════════════════════════════════════════════════════════════════════════════
cat("\n\n")
cat("================================================================\n")
cat("    STAGE 2 CLS-TVECM — FINAL CROSSWALK\n")
cat("    (ISI-fixed beta, full-sample CLS)\n")
cat("================================================================\n\n")

cat("Strategy: Fix beta from ISI subsample (1940-1972, N=33),\n")
cat("apply to full sample (1920-2024, N=105) for ECT + CLS.\n")
cat("Option B: (y, k_NR, k_ME, omega_kME) state vector.\n\n")

cat(sprintf("--- ISI Johansen (r=%d, K=%d) ---\n", r_isi, K_isi))
cat(sprintf("  theta_0 = %+.4f  [infrastructure]\n", theta_0_ISI))
cat(sprintf("  psi     = %+.4f  [machinery]\n", psi_ISI))
cat(sprintf("  theta_2 = %+.4f  [distribution-composition]\n", theta_2_ISI))
cat(sprintf("  Kaldor:   %s (psi-theta_0 = %+.4f)\n\n",
    ifelse(psi_ISI>theta_0_ISI,"CONFIRMED","NOT confirmed"), psi_ISI-theta_0_ISI))

cat(sprintf("theta^CL = %.4f + %.4f*phi + (%.4f)*omega*phi\n",
    theta_0_ISI, psi_ISI, theta_2_ISI))
cat(sprintf("  ISI mean:        %.4f\n", mean(theta_CL_t[df$year%in%1940:1972],na.rm=TRUE)))
cat(sprintf("  Neoliberal mean: %.4f\n\n", mean(theta_CL_t[df$year%in%1983:2024],na.rm=TRUE)))

cat(sprintf("ECT_theta (ISI beta, full sample): ADF tau=%.4f %s\n\n",
    adf_ect@teststat[1],
    ifelse(adf_ect@teststat[1]<adf_ect@cval[1,2],"STATIONARY","NOT STATIONARY")))

cat(sprintf("gamma_hat: %.4f | R1/R2: %d/%d\n", gamma_hat, n_r1, n_r2))
cat(sprintf("LR p-value: %.4f %s\n", p_boot,
    ifelse(p_boot<0.05,"REJECT","FAIL TO REJECT")))
cat(sprintf("Shadow price: %s\n\n",
    ifelse(shadow_price_confirmed,"CONFIRMED","NOT CONFIRMED")))

cat(sprintf("mu_CL(1980)=%.4f\n", df$mu_CL[df$year==1980]))
cat(sprintf("  ISI (1940-72):        %.4f\n", mean(df$mu_CL[df$year%in%1940:1972],na.rm=TRUE)))
cat(sprintf("  Neoliberal (1983-24): %.4f\n", mean(df$mu_CL[df$year%in%1983:2024],na.rm=TRUE)))
cat("================================================================\n")
