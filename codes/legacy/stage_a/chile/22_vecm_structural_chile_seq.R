# 22_vecm_structural_chile_seq.R
# Sequential recursive CVAR identification — Chile (7-variable system)
# CV1 (Two-Type MPF) → CV2 (Phillips) → CV3 (Import) → CV4 (Goods Market)
#
# Authority: data/interim/structural_identification/chile_structural_identification.md
# Interactive protocol: stops after each stage, awaits instruction before proceeding.

library(urca)
library(vars)
library(readr)
library(dplyr)
library(tibble)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

# ══════════════════════════════════════════════════════════════════════════════
# 0. LOAD DATA + CONSTRUCT STATE VECTOR
# ══════════════════════════════════════════════════════════════════════════════
panel <- read_csv(file.path(REPO, "output/panel/chile_panel_extended.csv"),
                  show_col_types = FALSE)

# Construct NRS: non-reinvested surplus = Pi_nom - I_nom
# Pi_nom = pi * Y_nom (profit share × nominal GDP)
panel <- panel %>%
  mutate(
    Pi_nom = pi * Y_nom,
    NRS    = Pi_nom - I_nom
  )

# Filter to complete state vector observations
panel_est <- panel %>%
  filter(!is.na(Y_real) & !is.na(Kg_ME) & !is.na(Kg_NRC) &
         !is.na(pi) & !is.na(M_real) & !is.na(NRS) & NRS > 0) %>%
  arrange(year)

cat(sprintf("Raw panel: %d-%d (%d rows)\n",
    min(panel$year), max(panel$year), nrow(panel)))
cat(sprintf("Estimation sample: %d-%d (%d obs)\n",
    min(panel_est$year), max(panel_est$year), nrow(panel_est)))

# Present-period normalization
T_last <- max(panel_est$year)
Y_last    <- panel_est$Y_real[panel_est$year == T_last]
Kg_NR_last <- (panel_est$Kg_ME[panel_est$year == T_last] +
               panel_est$Kg_NRC[panel_est$year == T_last])
Kg_ME_last <- panel_est$Kg_ME[panel_est$year == T_last]

panel_est <- panel_est %>%
  mutate(
    Kg_NR  = Kg_ME + Kg_NRC,                          # total non-residential gross
    y_t    = log(Y_real / Y_last),                     # present-period normalized
    k_NR_t = log(Kg_NR / Kg_NR_last),                 # present-period normalized
    k_ME_t = log(Kg_ME / Kg_ME_last),                 # present-period normalized
    pi_t   = pi,                                       # ratio, scale-invariant
    pi_kME_t = pi_t * k_ME_t,                         # distribution-machinery interaction
    m_t    = M_real / Y_real,                          # import propensity ratio
    nrs_t  = log(NRS)                                  # log non-reinvested surplus
  )

# State vector matrix
X <- as.matrix(panel_est[, c("y_t", "k_NR_t", "k_ME_t", "pi_t",
                              "pi_kME_t", "m_t", "nrs_t")])
colnames(X) <- c("y", "k_NR", "k_ME", "pi", "pi_kME", "m", "nrs")
N <- nrow(X)

cat(sprintf("\nState vector: %d variables × %d observations\n", ncol(X), N))
cat(sprintf("Variables: %s\n", paste(colnames(X), collapse = ", ")))
cat(sprintf("\nVariable summary:\n"))
for (j in 1:ncol(X)) {
  cat(sprintf("  %-8s: mean=%8.4f  sd=%8.4f  range=[%8.4f, %8.4f]\n",
      colnames(X)[j], mean(X[, j]), sd(X[, j]), min(X[, j]), max(X[, j])))
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STAGE 0 — REGULARIZATION AND RANK DETERMINATION                        ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STAGE 0 — REGULARIZATION AND RANK DETERMINATION\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# --- Step 0.1: BIC lag selection ---
cat("--- Step 0.1: Lag Selection ---\n")
lag_sel <- VARselect(X, lag.max = 3, type = "const")
cat("\nLag selection (all criteria):\n")
print(lag_sel$selection)

K_BIC <- lag_sel$selection["SC(n)"]   # BIC = SC in VARselect
K_use <- max(K_BIC, 2)                # minimum K=2 (L=1 first-difference lag)
cat(sprintf("\nBIC selects K=%d. Using K=%d (minimum K=2 enforced).\n", K_BIC, K_use))
cat(sprintf("L=%d first-difference lag(s) in VECM.\n", K_use - 1))

# --- Step 0.2: Johansen rank test (full 7-variable system) ---
cat("\n--- Step 0.2: Johansen Rank Test ---\n")

jo_full <- ca.jo(X, type = "trace", ecdet = "const", K = K_use, spec = "longrun")

p_var <- ncol(X)
cat("\necdet='const' (Case 3), trace test:\n")
for (r_null in 0:(p_var - 1)) {
  idx <- p_var - r_null
  stat <- jo_full@teststat[idx]
  cv10 <- jo_full@cval[idx, 1]
  cv05 <- jo_full@cval[idx, 2]
  cv01 <- jo_full@cval[idx, 3]
  decision <- ifelse(stat > cv05, "REJECT", "fail to reject")
  cat(sprintf("  r<=%d: trace=%8.2f  10%%cv=%6.2f  5%%cv=%6.2f  1%%cv=%6.2f  [%s]\n",
      r_null, stat, cv10, cv05, cv01, decision))
}

# Also run with Bartlett small-sample correction if available
cat(sprintf("\n  Note: %d obs, %d vars, K=%d. Small-sample correction recommended.\n",
    N, p_var, K_use))

# Eigenvalues
cat("\nEigenvalues:\n")
print(round(jo_full@lambda, 6))

# --- Step 0.3: Unrestricted alpha and weak exogeneity ---
cat("\n--- Step 0.3: Unrestricted VECM and Weak Exogeneity Tests ---\n")

r_stage0 <- 4  # rank prior; update if trace test suggests otherwise
vecm_unres <- cajorls(jo_full, r = r_stage0)

# Extract alpha matrix (loading coefficients)
# cajorls returns rlm: multivariate lm object
# Rows of coefficient matrix: ect1..ect_r, then lagged diffs, then const
alpha_hat <- coef(vecm_unres$rlm)[1:r_stage0, ]
cat("\nUnrestricted alpha matrix (r=4, transposed: rows=ECTs, cols=variables):\n")
print(round(alpha_hat, 4))

# Alpha in conventional form: rows=variables, cols=ECTs
alpha_conv <- t(alpha_hat)
cat("\nAlpha (rows=variables, cols=ECTs):\n")
rownames(alpha_conv) <- colnames(X)
colnames(alpha_conv) <- paste0("ECT", 1:r_stage0)
print(round(alpha_conv, 4))

# --- Weak exogeneity LR tests ---
# Full unrestricted log-likelihood from the Johansen procedure
# Test via alrtest() if available, or manually via restricted cajorls

cat("\n--- Weak exogeneity assessment (inspect alpha magnitudes) ---\n")
cat("k_NR row (expected: only ECT4 significant):\n")
cat(sprintf("  ECT1=%.4f  ECT2=%.4f  ECT3=%.4f  ECT4=%.4f\n",
    alpha_conv["k_NR", 1], alpha_conv["k_NR", 2],
    alpha_conv["k_NR", 3], alpha_conv["k_NR", 4]))

cat("nrs row (expected: only ECT2 and ECT4 significant):\n")
cat(sprintf("  ECT1=%.4f  ECT2=%.4f  ECT3=%.4f  ECT4=%.4f\n",
    alpha_conv["nrs", 1], alpha_conv["nrs", 2],
    alpha_conv["nrs", 3], alpha_conv["nrs", 4]))

# Formal weak exogeneity test for k_NR: alpha[k_NR, .] = (0, 0, 0, free)
# Use alrtest: tests H0: alpha = A*psi (A is n x s restriction matrix)
# A_kNR restricts k_NR row to load only on ECT4
A_kNR <- matrix(0, nrow = p_var, ncol = r_stage0)
A_kNR[2, 4] <- 1  # k_NR (row 2) loads only on ECT4
# But alrtest takes different form — test row-by-row restrictions
# Use the manual approach: compare restricted vs unrestricted likelihood

cat("\n--- Formal WE tests require restricted estimation (deferred to post-rank) ---\n")
cat("Visual inspection of alpha magnitudes above guides rank decision.\n")

# --- Step 0.4: Report ---
cat("\n")
cat("=== STAGE 0 COMPLETE ===\n")
cat(sprintf("Sample: %d-%d (%d obs)\n",
    min(panel_est$year), max(panel_est$year), N))
cat(sprintf("K (BIC): %d | L=%d first-difference lags\n", K_use, K_use - 1))
cat(sprintf("Rank prior: r=4. Inspect trace test above for empirical rank.\n"))
cat("Weak exogeneity: inspect alpha magnitudes above.\n")
cat("If k_NR and nrs are weakly exogenous: condition on them (5-variable system).\n")
cat("\nAwaiting instruction before proceeding to Stage 1.\n")
cat("Instruction needed: confirm rank r and whether to condition on k_NR / nrs.\n")

# ══════════════════════════════════════════════════════════════════════════════
# STOP HERE — Do not proceed without explicit instruction.
# ══════════════════════════════════════════════════════════════════════════════
# stop("STAGE 0 COMPLETE — awaiting instruction.")
# INSTRUCTION: r=4 confirmed, no conditioning, proceed with full 7-var system.


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STAGE 1 — CV1 ALONE: TWO-TYPE MPF                                      ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STAGE 1 — CV1 ALONE: TWO-TYPE MPF\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# beta_1 = (1, -theta0, -(theta1-theta0), 0, -theta2, 0, 0, -c1)
# Free params: theta0, delta (= theta1-theta0), theta2, c1 [4 free]
# c1 column block-diagonal — orthogonal to structural columns

# --- Model A: CV1 with restricted constant (c1 free) ---
cat("=== MODEL A: CV1 WITH c1 FREE (ecdet='const', Case 3) ===\n")

# H_CV1_A: spans the subspace consistent with CV1 restrictions.
# blrtest convention: beta = H * phi, then normalizes beta[1]=1.
# Free slots: y, k_NR, k_ME, pi_kME, const (5 free).
# Restricted to 0: pi, m, nrs (3 restrictions).
# df = r*(n_eff - ncol(H)) = 1*(8 - 5) = 3 overidentifying restrictions.
H_CV1_A <- matrix(c(
  # col1  col2  col3  col4  col5
    1,    0,    0,    0,    0,   # y:      free
    0,    1,    0,    0,    0,   # k_NR:   free
    0,    0,    1,    0,    0,   # k_ME:   free
    0,    0,    0,    0,    0,   # pi:     restricted = 0
    0,    0,    0,    1,    0,   # pi_kME: free
    0,    0,    0,    0,    0,   # m:      restricted = 0
    0,    0,    0,    0,    0,   # nrs:    restricted = 0
    0,    0,    0,    0,    1    # const:  free (c1)
), nrow = 8, ncol = 5, byrow = TRUE)

cv1_A <- blrtest(jo_full, H = H_CV1_A, r = 1)

beta1_A    <- cv1_A@V[, 1]
theta0_A   <- -beta1_A[2]
delta_A    <- -beta1_A[3]           # = theta1 - theta0
theta2_A   <- -beta1_A[5]
c1_A       <- -beta1_A[8]

cat(sprintf("  beta_1 = (%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)\n",
    beta1_A[1], beta1_A[2], beta1_A[3], beta1_A[4],
    beta1_A[5], beta1_A[6], beta1_A[7], beta1_A[8]))
cat(sprintf("  theta0_hat   = %.4f  (infrastructure elasticity)\n", theta0_A))
cat(sprintf("  delta_hat    = %.4f  (machinery premium = theta1 - theta0)\n", delta_A))
cat(sprintf("  theta1_hat   = %.4f  (machinery elasticity = theta0 + delta)\n",
    theta0_A + delta_A))
cat(sprintf("  theta2_hat   = %.4f  (distribution-mechanization slope)\n", theta2_A))
cat(sprintf("  c1_hat       = %.4f  (technology level nuisance)\n", c1_A))
cat(sprintf("  blrtest LR (vs unrestricted r=1): %.4f, p=%.4f\n",
    cv1_A@teststat, cv1_A@pval[1]))

# --- Model B: CV1 with c1 = 0 (ecdet="none", Case 1) ---
cat("\n=== MODEL B: CV1 WITH c1 = 0 (ecdet='none', Case 1) ===\n")

jo_none <- ca.jo(X, type = "trace", ecdet = "none", K = K_use, spec = "longrun")

# H_CV1_B: 7 rows (no const) × 4 cols (y, k_NR, k_ME, pi_kME free)
H_CV1_B <- matrix(c(
    1,  0,  0,  0,    # y
    0,  1,  0,  0,    # k_NR
    0,  0,  1,  0,    # k_ME
    0,  0,  0,  0,    # pi:     0
    0,  0,  0,  1,    # pi_kME
    0,  0,  0,  0,    # m:      0
    0,  0,  0,  0     # nrs:    0
), nrow = 7, ncol = 4, byrow = TRUE)

cv1_B <- blrtest(jo_none, H = H_CV1_B, r = 1)

beta1_B  <- cv1_B@V[, 1]
theta0_B <- -beta1_B[2]
delta_B  <- -beta1_B[3]
theta2_B <- -beta1_B[5]

cat(sprintf("  beta_1 = (%.4f, %.4f, %.4f, %.4f, %.4f, %.4f, %.4f)\n",
    beta1_B[1], beta1_B[2], beta1_B[3], beta1_B[4],
    beta1_B[5], beta1_B[6], beta1_B[7]))
cat(sprintf("  theta0_hat   = %.4f\n", theta0_B))
cat(sprintf("  delta_hat    = %.4f\n", delta_B))
cat(sprintf("  theta1_hat   = %.4f\n", theta0_B + delta_B))
cat(sprintf("  theta2_hat   = %.4f\n", theta2_B))
cat(sprintf("  blrtest LR: %.4f, p=%.4f\n",
    cv1_B@teststat, cv1_B@pval[1]))

# --- LR test: c1 = 0 ---
# Model B (c1=0) is nested within Model A (c1 free) — 1 additional restriction
# But they use different Johansen objects (ecdet="none" vs "const"),
# so direct LR comparison via blrtest stats is not valid.
# Instead: test c1=0 within the ecdet="const" framework by restricting const row
cat("\n--- LR test c1=0 (within ecdet='const' framework) ---\n")

H_CV1_A0 <- matrix(c(
    1,  0,  0,    # y
    0,  1,  0,    # k_NR
    0,  0,  1,    # k_ME
    0,  0,  0,    # pi:     0
    0,  0,  0,    # pi_kME: free
    0,  0,  0,    # m:      0
    0,  0,  0,    # nrs:    0
    0,  0,  0     # const:  restricted = 0
), nrow = 8, ncol = 3, byrow = TRUE)
# Fix: pi_kME must be free
H_CV1_A0[5, 3] <- 1  # pi_kME loads on third free param
# Now: 8 × 3, but we have 4 free slots (y, k_NR, k_ME, pi_kME) with const=0
H_CV1_A0 <- matrix(c(
    1,  0,  0,  0,    # y
    0,  1,  0,  0,    # k_NR
    0,  0,  1,  0,    # k_ME
    0,  0,  0,  0,    # pi:     0
    0,  0,  0,  1,    # pi_kME
    0,  0,  0,  0,    # m:      0
    0,  0,  0,  0,    # nrs:    0
    0,  0,  0,  0     # const:  0
), nrow = 8, ncol = 4, byrow = TRUE)

cv1_A0 <- blrtest(jo_full, H = H_CV1_A0, r = 1)

LR_c1 <- cv1_A0@teststat - cv1_A@teststat
p_c1  <- 1 - pchisq(LR_c1, df = 1)
cat(sprintf("  H0: c1=0 within ecdet='const':\n"))
cat(sprintf("  LR(c1=0 vs c1 free) = %.4f - %.4f = %.4f, df=1, p=%.4f\n",
    cv1_A0@teststat, cv1_A@teststat, LR_c1, p_c1))
cat(sprintf("  Decision at 5%%: %s\n",
    ifelse(p_c1 < 0.05, "REJECT — c1 significant, keep Model A",
                        "FAIL TO REJECT — c1 not significant, Model B admissible")))

# --- Diagnostics for both models ---
cat("\n--- Diagnostics ---\n")

# theta(pi) at key distributional anchors
pi_fordist  <- mean(panel_est$pi_t[panel_est$year >= 1940 & panel_est$year <= 1978],
                    na.rm = TRUE)
pi_pinochet <- mean(panel_est$pi_t[panel_est$year >= 1974 & panel_est$year <= 1989],
                    na.rm = TRUE)
pi_recent   <- panel_est$pi_t[panel_est$year == max(panel_est$year)]

for (label in c("A", "B")) {
  th0 <- get(paste0("theta0_", label))
  del <- get(paste0("delta_", label))
  th2 <- get(paste0("theta2_", label))

  cat(sprintf("\nModel %s — theta(pi) at key distributional anchors:\n", label))
  cat(sprintf("  Fordist mean  (pi=%.3f):  theta = %.4f\n",
      pi_fordist,  th0 + del + th2 * pi_fordist))
  cat(sprintf("  Pinochet mean (pi=%.3f):  theta = %.4f\n",
      pi_pinochet, th0 + del + th2 * pi_pinochet))
  cat(sprintf("  Recent        (pi=%.3f):  theta = %.4f\n",
      pi_recent,   th0 + del + th2 * pi_recent))

  # Threshold where theta = 1
  pi_H <- (1 - th0 - del) / th2
  cat(sprintf("  pi_H (theta=1 threshold): pi = %.4f\n", pi_H))
}

# ECT1 stationarity check
mu0_hat_A <- X[, 1] - theta0_A * X[, 2] - delta_A * X[, 3] - theta2_A * X[, 5]
mu_hat_A  <- mu0_hat_A - c1_A
mu_hat_B  <- X[, 1] - theta0_B * X[, 2] - delta_B * X[, 3] - theta2_B * X[, 5]

for (label in c("A", "B")) {
  mu <- get(paste0("mu_hat_", label))
  adf <- ur.df(mu, type = "none", selectlags = "BIC")
  cat(sprintf("\nModel %s ECT1 — ADF: stat=%.4f (need < -1.95 for I(0) at 5%%)\n",
      label, adf@teststat[1]))
  cat(sprintf("  Mean=%.4f, SD=%.4f, Range=[%.4f, %.4f]\n",
      mean(mu, na.rm = TRUE), sd(mu, na.rm = TRUE),
      min(mu, na.rm = TRUE), max(mu, na.rm = TRUE)))
}

# theta(pi) sensitivity grid
cat("\nSensitivity grid — theta(pi):\n")
cat(sprintf("%-8s  %-10s  %-10s\n", "pi", "Model A", "Model B"))
for (pi_val in seq(0.05, 0.45, by = 0.05)) {
  theta_A <- theta0_A + delta_A + theta2_A * pi_val
  theta_B <- theta0_B + delta_B + theta2_B * pi_val
  cat(sprintf("%-8.2f  %-10.4f  %-10.4f\n", pi_val, theta_A, theta_B))
}

# Save CV1 comparison
write_csv(
  tibble(year     = panel_est$year,
         mu_hat_A  = as.numeric(mu_hat_A),
         mu0_hat_A = as.numeric(mu0_hat_A),
         theta_A   = theta0_A + delta_A + theta2_A * panel_est$pi_t,
         mu_hat_B  = as.numeric(mu_hat_B),
         theta_B   = theta0_B + delta_B + theta2_B * panel_est$pi_t),
  file.path(REPO, "output/stage_a/chile/csv/chile_cv1_comparison.csv")
)

cat("\n=== STAGE 1 COMPLETE ===\n")
cat(sprintf("Model A: theta0=%.4f, delta=%.4f, theta2=%.4f, c1=%.4f\n",
    theta0_A, delta_A, theta2_A, c1_A))
cat(sprintf("Model B: theta0=%.4f, delta=%.4f, theta2=%.4f (c1=0)\n",
    theta0_B, delta_B, theta2_B))
cat(sprintf("LR test c1=0: chi2=%.4f, p=%.4f\n", LR_c1, p_c1))
cat("\nAwaiting instruction before proceeding to Stage 2.\n")
cat("Instruction needed: confirm Model A or B; confirm theta values for cross-eq use.\n")

stop("STAGE 1 COMPLETE — awaiting instruction.")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STAGE 2 — ADD CV2: NEO-GOODWIN PHILLIPS CURVE                          ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STAGE 2 — ADD CV2: NEO-GOODWIN PHILLIPS CURVE\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# INSTRUCTION: Set these from Stage 1 chosen model before running Stage 2
# theta0_hat <- theta0_A   # or theta0_B
# delta_hat  <- delta_A    # or delta_B
# theta2_hat <- theta2_A   # or theta2_B

# beta_2 = (rho2, -rho2*theta0, -rho2*delta, 1, 0, 0, 0, -rho1)
# Cross-eq: same theta0, delta from CV1
# Free CV2: rho1, rho2 [2 free]
# pi normalized to 1 (slot 4). Zero on pi_kME, m, nrs.

# H_CV2: 8 rows × 2 cols (rho2, rho1)
# beta_2 = H_CV2 * (rho2, rho1)' with pi slot normalized to 1
# Row 1 (y):      rho2 * 1        → H[1,] = (1, 0)
# Row 2 (k_NR):   -rho2 * theta0  → H[2,] = (-theta0_hat, 0)
# Row 3 (k_ME):   -rho2 * delta   → H[3,] = (-delta_hat, 0)
# Row 4 (pi):     1 (normalized)  → must be in column span but normalized by blrtest
# Row 5 (pi_kME): 0
# Row 6 (m):      0
# Row 7 (nrs):    0
# Row 8 (const):  -rho1           → H[8,] = (0, -1)

# For blrtest: pi slot needs a free direction for normalization
# Actually blrtest normalizes the first variable. Since we want pi=1 normalization
# for CV2, we can't use blrtest's default normalization (which normalizes slot 1 = y).
# Instead: include pi as a free direction — blrtest spans the subspace, then
# the coefficient vector is normalized post-estimation.

# Safer approach: H spans the subspace, blrtest estimates phi, then beta = H*phi.
# After normalization by beta[4] (pi slot), we recover rho1, rho2.

H_CV2 <- matrix(c(
  # col1            col2
    1,               0,     # y:      loads rho2
   -theta0_hat,      0,     # k_NR:   -rho2*theta0 (cross-eq)
   -delta_hat,       0,     # k_ME:   -rho2*delta (cross-eq)
    0,               0,     # pi:     normalized (outside H — handled by blrtest)
    0,               0,     # pi_kME: 0
    0,               0,     # m:      0
    0,               0,     # nrs:    0
    0,              -1      # const:  -rho1
), nrow = 8, ncol = 2, byrow = TRUE)

# Problem: pi slot is all zeros in H — beta[4] cannot be nonzero.
# We need pi in the column span. Fix: add a direction for pi.
H_CV2 <- matrix(c(
  # col1            col2    col3
    1,               0,      0,     # y:      rho2
   -theta0_hat,      0,      0,     # k_NR:   -rho2*theta0
   -delta_hat,       0,      0,     # k_ME:   -rho2*delta
    0,               0,      1,     # pi:     free (normalized to 1)
    0,               0,      0,     # pi_kME: 0
    0,               0,      0,     # m:      0
    0,               0,      0,     # nrs:    0
    0,              -1,      0      # const:  -rho1
), nrow = 8, ncol = 3, byrow = TRUE)
# Now H is 8×3: spans the 3D subspace consistent with CV2 restrictions.
# blrtest estimates phi = (rho2, rho1, pi_scale)' and normalizes.
# After normalization: beta[4] = pi_scale → rho2 = beta[1]/beta[4], etc.
# But this loses the cross-equation structure — phi[3] should be exactly 1.

# The cleanest approach for blrtest with cross-equation restrictions and
# non-standard normalization: include all non-zero slots as free directions
# and let blrtest normalize. The cross-equation content is in the H structure.

# Joint estimation: CV1 + CV2
cat("Joint estimation: CV1 + CV2 (r=2)\n")
cv12_test <- blrtest(jo_full, H = list(H_CV1_A, H_CV2), r = 2)

cat(sprintf("\nblrtest LR (CV1+CV2 vs unrestricted r=2): %.4f, p=%.4f\n",
    cv12_test@teststat, cv12_test@pval[1]))
print(summary(cv12_test))

beta12 <- cv12_test@V
cat("\nEstimated beta (CV1 | CV2):\n")
colnames(beta12) <- c("CV1", "CV2")
rownames(beta12) <- c("y", "k_NR", "k_ME", "pi", "pi_kME", "m", "nrs", "const")
print(round(beta12, 4))

# Extract CV2 parameters (normalize by pi slot if needed)
beta2 <- beta12[, 2]
if (abs(beta2[4]) > 1e-10) {
  beta2 <- beta2 / beta2[4]  # normalize pi = 1
}
rho2_hat <- beta2[1]
rho1_hat <- -beta2[8]

cat(sprintf("\nCV2 (normalized pi=1):\n"))
cat(sprintf("  rho2_hat = %.4f  (Goodwin slope)\n", rho2_hat))
cat(sprintf("  rho1_hat = %.4f  (structural profit share attractor)\n", rho1_hat))
cat(sprintf("  Implied long-run wage share (1-rho1): %.4f\n", 1 - rho1_hat))

# Verify cross-equation structure
cat(sprintf("\n  Cross-eq check (CV2 k_NR / CV2 y = -theta0?):\n"))
cat(sprintf("    beta2[k_NR]/beta2[y] = %.4f  (should be %.4f = -theta0)\n",
    beta2[2] / beta2[1], -theta0_hat))
cat(sprintf("    beta2[k_ME]/beta2[y] = %.4f  (should be %.4f = -delta)\n",
    beta2[3] / beta2[1], -delta_hat))

# Update CV1 parameters from joint estimation
beta1_joint <- beta12[, 1]
theta0_joint <- -beta1_joint[2] / beta1_joint[1]
delta_joint  <- -beta1_joint[3] / beta1_joint[1]
theta2_joint <- -beta1_joint[5] / beta1_joint[1]
c1_joint     <- -beta1_joint[8] / beta1_joint[1]
cat(sprintf("\n  CV1 (joint): theta0=%.4f, delta=%.4f, theta2=%.4f, c1=%.4f\n",
    theta0_joint, delta_joint, theta2_joint, c1_joint))

cat("\n=== STAGE 2 COMPLETE ===\n")
cat(sprintf("rho1=%.4f, rho2=%.4f | wage share=%.4f\n",
    rho1_hat, rho2_hat, 1 - rho1_hat))
cat("\nAwaiting instruction before proceeding to Stage 3.\n")
cat("Instruction needed: confirm CV2 parameters; proceed to CV3?\n")

stop("STAGE 2 COMPLETE — awaiting instruction.")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STAGE 3 — ADD CV3: IMPORT PROPENSITY ATTRACTOR                         ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STAGE 3 — ADD CV3: IMPORT PROPENSITY ATTRACTOR\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# beta_3 = (0, 0, zeta1, 0, 0, -1, zeta2, -zeta0)
# Free CV3: zeta0, zeta1, zeta2 [3 free]
# Zeros on y, k_NR, pi, pi_kME. m normalized to -1.

# H_CV3: 8 rows × 3+1 cols
# Need m slot free (normalized to -1 post-estimation)
# zeta1 on k_ME, zeta2 on nrs, zeta0 on const
H_CV3 <- matrix(c(
  # col1  col2  col3  col4
    0,    0,    0,    0,    # y:      0
    0,    0,    0,    0,    # k_NR:   0
    1,    0,    0,    0,    # k_ME:   zeta1 (free)
    0,    0,    0,    0,    # pi:     0
    0,    0,    0,    0,    # pi_kME: 0
    0,    0,    0,    1,    # m:      free (normalized to -1)
    0,    1,    0,    0,    # nrs:    zeta2 (free)
    0,    0,   -1,    0     # const:  -zeta0 (free)
), nrow = 8, ncol = 4, byrow = TRUE)

# Joint estimation: CV1 + CV2 + CV3
cat("Joint estimation: CV1 + CV2 + CV3 (r=3)\n")
cv123_test <- blrtest(jo_full, H = list(H_CV1_A, H_CV2, H_CV3), r = 3)

cat(sprintf("\nblrtest LR (CV1+CV2+CV3 vs unrestricted r=3): %.4f, p=%.4f\n",
    cv123_test@teststat, cv123_test@pval[1]))
print(summary(cv123_test))

beta123 <- cv123_test@V
cat("\nEstimated beta (CV1 | CV2 | CV3):\n")
colnames(beta123) <- c("CV1", "CV2", "CV3")
rownames(beta123) <- c("y", "k_NR", "k_ME", "pi", "pi_kME", "m", "nrs", "const")
print(round(beta123, 4))

# Extract CV3 parameters (normalize by m slot: m = -1)
beta3 <- beta123[, 3]
if (abs(beta3[6]) > 1e-10) {
  beta3 <- beta3 / (-beta3[6])  # normalize m = -1
}
zeta1_hat <- beta3[3]
zeta2_hat <- beta3[7]
zeta0_hat <- -beta3[8]

cat(sprintf("\nCV3 (normalized m=-1):\n"))
cat(sprintf("  zeta0_hat = %.4f\n", zeta0_hat))
cat(sprintf("  zeta1_hat = %.4f  (Tavares channel — prior: ~0.92-0.94)\n", zeta1_hat))
cat(sprintf("  zeta2_hat = %.4f  (Palma-Marcel consumption drain)\n", zeta2_hat))

# Kaldor-ECLA fault line
k_ME_bar <- mean(X[, "k_ME"])
nrs_bar  <- mean(X[, "nrs"])
if (zeta1_hat * k_ME_bar + zeta2_hat * nrs_bar != 0) {
  tavares_share <- (zeta1_hat * k_ME_bar) /
                   (zeta1_hat * k_ME_bar + zeta2_hat * nrs_bar)
  cat(sprintf("\n  Kaldor-ECLA Tavares share: %.4f\n", tavares_share))
  cat(sprintf("    (Tavares vs Palma-Marcel in long-run forex allocation)\n"))
}

# ECT3 time series
ECT3 <- X[, "m"] - zeta0_hat - zeta1_hat * X[, "k_ME"] - zeta2_hat * X[, "nrs"]
cat(sprintf("\n  ECT3 summary: mean=%.4f, sd=%.4f\n",
    mean(ECT3, na.rm = TRUE), sd(ECT3, na.rm = TRUE)))
cat(sprintf("  ECT3 > 0 (forex overdrawn): %d obs\n", sum(ECT3 > 0)))
cat(sprintf("  ECT3 < 0 (import compression): %d obs\n", sum(ECT3 < 0)))

cat("\n=== STAGE 3 COMPLETE ===\n")
cat(sprintf("zeta1=%.4f (Tavares), zeta2=%.4f (Palma-Marcel)\n",
    zeta1_hat, zeta2_hat))
cat("\nAwaiting instruction before proceeding to Stage 4.\n")
cat("Instruction needed: confirm CV3; proceed to CV4?\n")

stop("STAGE 3 COMPLETE — awaiting instruction.")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STAGE 4 — ADD CV4: MPF-CONSISTENT GOODS MARKET CONDITION               ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STAGE 4 — ADD CV4: MPF-CONSISTENT GOODS MARKET CONDITION\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# beta_4 = (1, -psi*theta0-lambda, -psi*delta, gamma2, -psi*theta2, -gamma3, 0, -gamma0)
# Cross-eq: same theta0, delta, theta2 from CV1
# Free CV4: psi, lambda, gamma2, gamma3, gamma0 [5 free]
# nrs slot restricted to 0.

# H_CV4: 8 rows × 6 cols (y free + psi, lambda, gamma2, gamma3, gamma0)
# y normalized to 1. Slot structure via H*phi:
# Row 1 (y):      1 → free direction
# Row 2 (k_NR):   -psi*theta0_hat - lambda → H[2,] = (-theta0_hat, -1, 0, 0, 0, 0)
# Row 3 (k_ME):   -psi*delta_hat → H[3,] = (-delta_hat, 0, 0, 0, 0, 0)
# Row 4 (pi):     gamma2 → H[4,] = (0, 0, 1, 0, 0, 0)
# Row 5 (pi_kME): -psi*theta2_hat → H[5,] = (-theta2_hat, 0, 0, 0, 0, 0)
# Row 6 (m):      -gamma3 → H[6,] = (0, 0, 0, -1, 0, 0)
# Row 7 (nrs):    0
# Row 8 (const):  -gamma0 → H[8,] = (0, 0, 0, 0, -1, 0)
# Plus y direction: col 6 covers y slot

H_CV4 <- matrix(c(
  # psi              lambda  gamma2  gamma3  gamma0  y_dir
    0,               0,      0,      0,      0,      1,     # y: free (normalized)
   -theta0_hat,     -1,      0,      0,      0,      0,     # k_NR
   -delta_hat,       0,      0,      0,      0,      0,     # k_ME
    0,               0,      1,      0,      0,      0,     # pi
   -theta2_hat,      0,      0,      0,      0,      0,     # pi_kME
    0,               0,      0,     -1,      0,      0,     # m
    0,               0,      0,      0,      0,      0,     # nrs: 0
    0,               0,      0,      0,     -1,      0      # const
), nrow = 8, ncol = 6, byrow = TRUE)

# Joint estimation: full system CV1 + CV2 + CV3 + CV4
cat("Joint estimation: CV1 + CV2 + CV3 + CV4 (r=4)\n")
cv1234_test <- blrtest(jo_full,
  H = list(H_CV1_A, H_CV2, H_CV3, H_CV4), r = 4)

cat(sprintf("\n=== FULL SYSTEM vs UNRESTRICTED JOHANSEN ===\n"))
cat(sprintf("blrtest LR: %.4f, df=%d, p=%.4f\n",
    cv1234_test@teststat,
    ncol(cv1234_test@V) * nrow(cv1234_test@V) -
      sum(sapply(list(H_CV1_A, H_CV2, H_CV3, H_CV4), ncol)),
    cv1234_test@pval[1]))
print(summary(cv1234_test))

beta_full <- cv1234_test@V
cat("\nEstimated beta (CV1 | CV2 | CV3 | CV4):\n")
colnames(beta_full) <- c("CV1", "CV2", "CV3", "CV4")
rownames(beta_full) <- c("y", "k_NR", "k_ME", "pi", "pi_kME", "m", "nrs", "const")
print(round(beta_full, 4))

# --- Extract all parameters ---
# CV1
b1 <- beta_full[, 1]
if (abs(b1[1]) > 1e-10) b1 <- b1 / b1[1]  # normalize y=1
theta0_hat  <- -b1[2]
delta_hat   <- -b1[3]
theta2_hat  <- -b1[5]
c1_hat      <- -b1[8]

# CV2
b2 <- beta_full[, 2]
if (abs(b2[4]) > 1e-10) b2 <- b2 / b2[4]  # normalize pi=1
rho2_hat <- b2[1]
rho1_hat <- -b2[8]

# CV3
b3 <- beta_full[, 3]
if (abs(b3[6]) > 1e-10) b3 <- b3 / (-b3[6])  # normalize m=-1
zeta1_hat <- b3[3]
zeta2_hat <- b3[7]
zeta0_hat <- -b3[8]

# CV4
b4 <- beta_full[, 4]
if (abs(b4[1]) > 1e-10) b4 <- b4 / b4[1]  # normalize y=1
psi_hat    <- -b4[3] / delta_hat              # from k_ME slot
lambda_hat <- -(b4[2] + psi_hat * theta0_hat) # from k_NR slot
gamma2_hat <-  b4[4]
gamma3_hat <- -b4[6]
gamma0_hat <- -b4[8]

cat(sprintf("\n--- Full System Parameter Extraction ---\n"))
cat(sprintf("\nCV1 (Two-Type MPF):\n"))
cat(sprintf("  theta0   = %.4f  (infrastructure elasticity)\n", theta0_hat))
cat(sprintf("  delta    = %.4f  (machinery premium)\n", delta_hat))
cat(sprintf("  theta1   = %.4f  (machinery elasticity)\n", theta0_hat + delta_hat))
cat(sprintf("  theta2   = %.4f  (distribution-mechanization slope)\n", theta2_hat))
cat(sprintf("  c1       = %.4f  (nuisance)\n", c1_hat))

cat(sprintf("\nCV2 (Neo-Goodwin Phillips):\n"))
cat(sprintf("  rho1     = %.4f  (structural profit share attractor)\n", rho1_hat))
cat(sprintf("  rho2     = %.4f  (Goodwin slope)\n", rho2_hat))
cat(sprintf("  wage share = %.4f\n", 1 - rho1_hat))

cat(sprintf("\nCV3 (Import Propensity):\n"))
cat(sprintf("  zeta1    = %.4f  (Tavares)\n", zeta1_hat))
cat(sprintf("  zeta2    = %.4f  (Palma-Marcel)\n", zeta2_hat))
cat(sprintf("  zeta0    = %.4f\n", zeta0_hat))

cat(sprintf("\nCV4 (Goods Market):\n"))
cat(sprintf("  psi      = %.4f  (net capacity manifold scale = gamma1-lambda)\n", psi_hat))
cat(sprintf("  lambda   = %.4f  (capital productivity sensitivity)\n", lambda_hat))
cat(sprintf("  gamma2   = %.4f  (Cambridge-Kaldor saving)\n", gamma2_hat))
cat(sprintf("  gamma3   = %.4f  (import leakage multiplier)\n", gamma3_hat))
cat(sprintf("  gamma0   = %.4f\n", gamma0_hat))

# --- Post-estimation diagnostics ---
cat(sprintf("\n--- Diagnostics ---\n"))

# lambda/theta2 implied b_bar
if (abs(theta2_hat) > 1e-10) {
  b_bar_implied <- lambda_hat / theta2_hat
  cat(sprintf("  Implied b_bar = lambda/theta2 = %.4f", b_bar_implied))
  cat(sprintf("  (under theta<1: should be negative)\n"))
}

# Construct mu_hat (c1-purged for cross-equation use)
mu0_hat <- X[, 1] - theta0_hat * X[, 2] - delta_hat * X[, 3] -
           theta2_hat * X[, 5]
mu_hat  <- mu0_hat - c1_hat

# theta(pi) path
theta_path <- theta0_hat + delta_hat + theta2_hat * panel_est$pi_t

# Save outputs
write_csv(
  tibble(year     = panel_est$year,
         mu_hat   = as.numeric(mu_hat),
         mu0_hat  = as.numeric(mu0_hat),
         theta_pi = theta_path),
  file.path(REPO, "output/stage_a/chile/csv/chile_mu_hat.csv")
)

write_csv(
  tibble(parameter = c("theta0", "delta", "theta1", "theta2", "c1",
                        "rho1", "rho2",
                        "zeta0", "zeta1", "zeta2",
                        "psi", "lambda", "gamma2", "gamma3", "gamma0"),
         value     = c(theta0_hat, delta_hat, theta0_hat + delta_hat,
                        theta2_hat, c1_hat,
                        rho1_hat, rho2_hat,
                        zeta0_hat, zeta1_hat, zeta2_hat,
                        psi_hat, lambda_hat, gamma2_hat, gamma3_hat, gamma0_hat)),
  file.path(REPO, "output/stage_a/chile/csv/chile_theta_hat.csv")
)

beta_out <- as_tibble(beta_full, .name_repair = ~c("CV1", "CV2", "CV3", "CV4")) %>%
  mutate(variable = c("y", "k_NR", "k_ME", "pi", "pi_kME", "m", "nrs", "const"),
         .before = 1)
write_csv(beta_out,
  file.path(REPO, "output/stage_a/chile/csv/chile_beta_restricted.csv"))

cat("\n=== STAGE 4 COMPLETE ===\n")
cat("Full structural identification complete. Beta saved.\n")
cat("\nAwaiting instruction before proceeding to Stage 5 (alpha restrictions).\n")

stop("STAGE 4 COMPLETE — awaiting instruction.")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STAGE 5 — ALPHA REFINEMENT + TESTABLE RESTRICTION                      ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STAGE 5 — ALPHA REFINEMENT + TESTABLE RESTRICTION\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Maintained zeros indicator (7 vars × 4 ECTs):
# 1=free, 0=maintained zero, NA=testable
alpha_indicator <- matrix(c(
# ECT1  ECT2  ECT3  ECT4
    1,    1,    1,    1,   # y
    0,    0,    0,    1,   # k_NR     (only ECT4 free)
    1,    1,    1,    1,   # k_ME
    1,    1,    0,    1,   # pi       (ECT3=0)
    0,    0,    0,    0,   # pi_kME   (full row zero)
    1,    0,    1,    1,   # m        (ECT2=0)
    NA,   1,    0,    1    # nrs      (ECT1=testable, ECT3=0)
), nrow = 7, ncol = 4, byrow = TRUE)
rownames(alpha_indicator) <- c("y", "k_NR", "k_ME", "pi", "pi_kME", "m", "nrs")
colnames(alpha_indicator) <- c("ECT1", "ECT2", "ECT3", "ECT4")

cat("Maintained alpha restriction indicator:\n")
cat("(1=free, 0=maintained zero, NA=testable)\n")
print(alpha_indicator)

cat(sprintf("\nMaintained zeros: %d\n", sum(alpha_indicator == 0, na.rm = TRUE)))
cat(sprintf("Free elements: %d\n", sum(alpha_indicator == 1, na.rm = TRUE)))
cat(sprintf("Testable: %d (alpha[nrs, ECT1])\n", sum(is.na(alpha_indicator))))

# Get unrestricted alpha from Stage 4 VECM
vecm_s4 <- cajorls(jo_full, r = 4)
alpha_unres <- t(coef(vecm_s4$rlm)[1:4, ])
rownames(alpha_unres) <- colnames(X)
colnames(alpha_unres) <- paste0("ECT", 1:4)

cat("\nUnrestricted alpha (from cajorls at r=4):\n")
print(round(alpha_unres, 4))

# Check which maintained zeros are already near zero
cat("\nMaintained zeros — magnitude check:\n")
for (i in 1:7) {
  for (j in 1:4) {
    if (!is.na(alpha_indicator[i, j]) && alpha_indicator[i, j] == 0) {
      cat(sprintf("  alpha[%s, ECT%d] = %.4f  [maintained zero]\n",
          rownames(alpha_indicator)[i], j, alpha_unres[i, j]))
    }
  }
}

# Testable restriction: alpha[nrs, ECT1]
cat(sprintf("\nTestable: alpha[nrs, ECT1] = %.4f\n", alpha_unres["nrs", "ECT1"]))
cat("H0: NRS does not respond to utilization gap\n")
cat("H1: Ruling class accelerates luxury consumption during booms\n")
cat("    → amplifies BoP constraint procyclically\n")

# Implement alpha restrictions via alrtest()
# alrtest tests H0: alpha = A*psi where A is the n×s restriction matrix
# For maintained zeros: A selects the free alpha elements

# Build A matrix for maintained zeros (with nrs ECT1 = 0, i.e. maintained)
# A is n×s where s = number of free alpha elements per ECT column
# Actually alrtest works differently: it tests restrictions on alpha for a SINGLE
# cointegrating vector. For joint alpha restrictions across all ECTs, we need
# a different approach (manual restricted estimation).

# Approach: use the alrtest one ECT at a time to assess individual loadings
# For the testable restriction:
# Test alpha[nrs, ECT1] via alrtest on first cointegrating vector
# A_nrs_test: column span of alpha[.,1] excluding nrs row
A_ECT1_restricted <- matrix(0, nrow = p_var, ncol = p_var - 1)
# Free rows for ECT1: y (1), k_ME (3), pi (4), m (6) — 4 free
# Restricted: k_NR (2), pi_kME (5), nrs (7) — 3 maintained zeros
free_ect1 <- c(1, 3, 4, 6)  # rows with alpha free for ECT1
for (idx in seq_along(free_ect1)) {
  A_ECT1_restricted[free_ect1[idx], idx] <- 1
}

# nrs also free under H1 (testable):
A_ECT1_free <- A_ECT1_restricted
A_ECT1_free <- cbind(A_ECT1_free[, 1:length(free_ect1)], 0)
A_ECT1_free[7, length(free_ect1) + 1] <- 1  # add nrs free

cat("\nNote: Full alpha restriction testing requires restricted VECM estimation.\n")
cat("The alrtest() function tests one alpha column at a time.\n")
cat("Joint alpha restriction LR test deferred to manual implementation.\n")

cat("\n=== STAGE 5 COMPLETE ===\n")
cat("Awaiting instruction before proceeding to Stage 6 (1974 Phillips break).\n")

stop("STAGE 5 COMPLETE — awaiting instruction.")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STAGE 6 — PHILLIPS CURVE REGIME CHANGE, 1974                           ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STAGE 6 — PHILLIPS CURVE REGIME CHANGE, 1974\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Augment state vector with D74 dummy interactions
# D74 = 1[t >= 1974]
panel_est <- panel_est %>%
  mutate(
    D74     = as.numeric(year >= 1974),
    D74_y   = D74 * y_t,
    D74_kNR = D74 * k_NR_t,
    D74_kME = D74 * k_ME_t,
    D74_pik = D74 * pi_kME_t
  )

X_aug <- as.matrix(panel_est[, c("y_t", "k_NR_t", "k_ME_t", "pi_t",
                                   "pi_kME_t", "m_t", "nrs_t",
                                   "D74", "D74_y", "D74_kNR",
                                   "D74_kME", "D74_pik")])
colnames(X_aug) <- c("y", "k_NR", "k_ME", "pi", "pi_kME", "m", "nrs",
                      "D74", "D74_y", "D74_kNR", "D74_kME", "D74_pik")

cat(sprintf("Augmented state vector: %d variables × %d obs\n",
    ncol(X_aug), nrow(X_aug)))

# Johansen on augmented system
jo_aug <- ca.jo(X_aug, type = "trace", ecdet = "const", K = K_use, spec = "longrun")

cat("\nRank test (augmented system):\n")
p_aug <- ncol(X_aug)
for (r_null in 0:min(6, p_aug - 1)) {
  idx <- p_aug - r_null
  if (idx >= 1 && idx <= length(jo_aug@teststat)) {
    stat <- jo_aug@teststat[idx]
    cv05 <- jo_aug@cval[idx, 2]
    decision <- ifelse(stat > cv05, "REJECT", "fail")
    cat(sprintf("  r<=%d: trace=%8.2f  5%%cv=%6.2f  [%s]\n",
        r_null, stat, cv05, decision))
  }
}

# Expand H matrices from 8 rows to 13 rows (12 vars + const)
n_aug <- 13  # 12 variables + restricted constant
expand_H <- function(H_orig, n_new = n_aug) {
  H_exp <- matrix(0, nrow = n_new, ncol = ncol(H_orig))
  # Copy original rows 1:7 (variables) to rows 1:7
  H_exp[1:7, ] <- H_orig[1:7, ]
  # Copy const row (row 8 of original) to last row (n_new)
  H_exp[n_new, ] <- H_orig[8, ]
  return(H_exp)
}

H_CV1_aug <- expand_H(H_CV1_A)
H_CV3_aug <- expand_H(H_CV3)
H_CV4_aug <- expand_H(H_CV4)

# Modified CV2_aug: pre-1974 Phillips + post-1974 level AND slope shift
# Pre-1974: pi = rho1 - rho2 * mu
# Post-1974: pi = (rho1+rho1*) - (rho2+rho2*) * mu
# Additional free params: rho1_star (level), rho2_star (slope)
#
# CV2_aug beta vector (13 slots):
# y:        rho2
# k_NR:     -rho2*theta0
# k_ME:     -rho2*delta
# pi:       1 (normalized)
# pi_kME:   0
# m:        0
# nrs:      0
# D74:      -rho1_star (level shift)
# D74_y:    rho2_star (slope shift on y)
# D74_kNR:  -rho2_star*theta0 (cross-eq)
# D74_kME:  -rho2_star*delta (cross-eq)
# D74_pik:  0
# const:    -rho1

H_CV2_aug <- matrix(0, nrow = n_aug, ncol = 4)
colnames(H_CV2_aug) <- c("rho2", "rho1", "rho2s", "rho1s")

# Pre-1974 structure (same as base CV2, in augmented form)
H_CV2_aug[1, 1]  <-  1              # y: rho2
H_CV2_aug[2, 1]  <- -theta0_hat     # k_NR: -rho2*theta0
H_CV2_aug[3, 1]  <- -delta_hat      # k_ME: -rho2*delta
# pi (row 4): needs free direction for normalization — add separate column
# Actually pi=1 is normalization, handled by blrtest after estimation
# For now: pi must be in column span
H_CV2_aug[4, ]   <- c(0, 0, 0, 0)  # pi: will need extra column

# Post-1974 regime shift
H_CV2_aug[8, 4]  <- -1              # D74: -rho1_star (level shift)
H_CV2_aug[9, 3]  <-  1              # D74_y: rho2_star (slope)
H_CV2_aug[10, 3] <- -theta0_hat     # D74_kNR: -rho2_star*theta0
H_CV2_aug[11, 3] <- -delta_hat      # D74_kME: -rho2_star*delta
# D74_pik (row 12): 0

# Constants
H_CV2_aug[n_aug, 2] <- -1           # const: -rho1

# Add pi direction (column 5) for normalization
H_CV2_aug <- cbind(H_CV2_aug, 0)
H_CV2_aug[4, 5] <- 1                # pi: free direction
colnames(H_CV2_aug) <- c("rho2", "rho1", "rho2s", "rho1s", "pi_dir")

cat("\nH_CV2_aug structure (13 × 5):\n")
print(H_CV2_aug)

# Joint estimation: augmented system
cat("\nJoint estimation: augmented CV1 + CV2_aug + CV3 + CV4 (r=4)\n")

tryCatch({
  aug_test <- blrtest(jo_aug,
    H = list(H_CV1_aug, H_CV2_aug, H_CV3_aug, H_CV4_aug), r = 4)

  cat(sprintf("\nblrtest LR: %.4f, p=%.4f\n",
      aug_test@teststat, aug_test@pval[1]))
  print(summary(aug_test))

  beta_aug <- aug_test@V
  cat("\nEstimated beta (augmented):\n")
  print(round(beta_aug, 4))

  # Extract CV2 augmented parameters
  b2_aug <- beta_aug[, 2]
  if (abs(b2_aug[4]) > 1e-10) b2_aug <- b2_aug / b2_aug[4]  # normalize pi=1

  rho2_hat_pre  <- b2_aug[1]
  rho1_hat_pre  <- -b2_aug[n_aug]
  rho1_star     <- -b2_aug[8]
  rho2_star     <-  b2_aug[9]

  cat(sprintf("\nPre-1974 Phillips curve:\n"))
  cat(sprintf("  rho1     = %.4f | rho2     = %.4f\n", rho1_hat_pre, rho2_hat_pre))
  cat(sprintf("  Implied wage share: %.4f\n", 1 - rho1_hat_pre))

  cat(sprintf("\nPost-1974 Phillips curve:\n"))
  cat(sprintf("  rho1+rho1* = %.4f (shift: %+.4f)\n",
      rho1_hat_pre + rho1_star, rho1_star))
  cat(sprintf("  rho2+rho2* = %.4f (shift: %+.4f)\n",
      rho2_hat_pre + rho2_star, rho2_star))
  cat(sprintf("  Implied wage share: %.4f\n",
      1 - (rho1_hat_pre + rho1_star)))

  cat(sprintf("\nInterpretation:\n"))
  cat(sprintf("  rho1_star %s 0: %s\n",
      ifelse(rho1_star > 0, ">", "<"),
      ifelse(rho1_star > 0,
             "Pinochet raises structural profit floor (prior met)",
             "Capital flight compresses profits despite repression")))
  cat(sprintf("  rho2_star %s 0: %s\n",
      ifelse(rho2_star < 0, "<", ">"),
      ifelse(rho2_star < 0,
             "Goodwin mechanism institutionally severed by repression",
             "Goodwin strengthens under repression")))

  # Save regime summary
  write_csv(
    tibble(
      parameter = c("rho1_pre", "rho2_pre", "wage_share_pre",
                     "rho1_post", "rho2_post", "wage_share_post",
                     "rho1_star", "rho2_star"),
      value = c(rho1_hat_pre, rho2_hat_pre, 1 - rho1_hat_pre,
                rho1_hat_pre + rho1_star,
                rho2_hat_pre + rho2_star,
                1 - (rho1_hat_pre + rho1_star),
                rho1_star, rho2_star)
    ),
    file.path(REPO, "output/stage_a/chile/csv/chile_phillips_regime_1974.csv")
  )
}, error = function(e) {
  cat(sprintf("\nERROR in augmented estimation: %s\n", e$message))
  cat("The augmented system (12 variables) may exceed blrtest capacity.\n")
  cat("Consider: (1) Hansen-Johansen recursive test, or\n")
  cat("          (2) Johansen-Mosconi-Nielsen level shift test,\n")
  cat("          (3) split-sample estimation.\n")
})

cat("\n=== STAGE 6 COMPLETE ===\n")
cat("All stages complete. Awaiting instruction for any further refinement.\n")

stop("STAGE 6 COMPLETE — all stages done.")
