# 03b_reparam_frontier_steps0to3.R
# Reparameterized frontier: (y, k_CL, k_ME, omega_kME)
# Steps 0–3 only. Decision gate at end.
# Prompt 06 | FOC-consistent: A=psi^NR, B=psi^ME-psi^NR, C=theta_2/2

library(urca)
library(vars)
library(tidyverse)
library(sandwich)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)

# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 0 — SETUP AND DATA LOAD                                           ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 0 — SETUP AND DATA LOAD\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

df <- read_csv("data/final/chile_tvecm_panel.csv", show_col_types = FALSE) %>%
  arrange(year)

ect_s1 <- read_csv("data/processed/Chile/ECT_m_stage1.csv",
                   show_col_types = FALSE) %>%
  arrange(year) %>%
  mutate(ECT_m_lag1 = lag(ECT_m, 1))

df <- df %>%
  left_join(ect_s1 %>% select(year, ECT_m, ECT_m_lag1), by = "year") %>%
  mutate(
    k_CL      = log(exp(k_NR) + exp(k_ME)),
    s_ME      = exp(k_ME) / (exp(k_NR) + exp(k_ME)),
    omega_kME = omega * k_ME
  )

cat(sprintf("Panel: %d–%d (N=%d)\n", min(df$year), max(df$year), nrow(df)))

# Collinearity check
cat(sprintf("\nCollinearity diagnostic:\n"))
cat(sprintf("  cor(k_NR, k_ME)  = %.4f  [OLD — collinear]\n",
    cor(df$k_NR, df$k_ME, use = "complete")))
cat(sprintf("  cor(k_CL, k_ME)  = %.4f  [NEW — should be lower]\n",
    cor(df$k_CL, df$k_ME, use = "complete")))

cat(sprintf("\ns_ME range: [%.4f, %.4f]\n",
    min(df$s_ME, na.rm = TRUE), max(df$s_ME, na.rm = TRUE)))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 1 — ISI SUBSAMPLE JOHANSEN: NEW STATE VECTOR                      ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 1 — ISI JOHANSEN: (y, k_CL, k_ME, omega_kME)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

df_isi <- df %>% filter(year >= 1940, year <= 1972)

Y_isi <- df_isi %>%
  select(y, k_CL, k_ME, omega_kME) %>%
  as.matrix()
rownames(Y_isi) <- df_isi$year

cat(sprintf("ISI subsample: N=%d (1940–1972)\n", nrow(Y_isi)))
cat(sprintf("cor(k_CL, k_ME) in ISI: %.4f\n", cor(df_isi$k_CL, df_isi$k_ME)))

# Lag selection
var_sel_isi <- VARselect(Y_isi, lag.max = 3, type = "const")
cat("\nLag selection:\n")
print(var_sel_isi$selection)
K_isi <- max(2, as.integer(var_sel_isi$selection["SC(n)"]))
cat(sprintf("VAR lag (SC): %d\n", K_isi))

# Johansen rank test
jo_isi <- ca.jo(Y_isi, type = "trace", ecdet = "const",
                K = K_isi, spec = "transitory")

cat("\n=== ISI Johansen Trace Test (y, k_CL, k_ME, omega_kME) ===\n")
p <- 4
r_hat <- 0
for (r_null in 0:(p - 1)) {
  idx <- p - r_null
  stat <- jo_isi@teststat[idx]
  cv05 <- jo_isi@cval[idx, 2]; cv01 <- jo_isi@cval[idx, 3]
  dec <- ifelse(stat > cv01, "REJECT at 1%",
         ifelse(stat > cv05, "REJECT at 5%", "fail"))
  cat(sprintf("  r<=%d: %.2f [5%%CV: %.2f, 1%%CV: %.2f] %s\n",
      r_null, stat, cv05, cv01, dec))
  if (stat > cv05 && r_null >= r_hat) r_hat <- r_null + 1
}
cat(sprintf("  Rank: r = %d\n", r_hat))

if (r_hat == 0) {
  cat("  Trace test fails — forcing r=1 (justified if ECT stationary on full sample)\n")
  r_hat <- 1
}

# VECM r=1
vecm_isi <- cajorls(jo_isi, r = 1)
beta_isi <- vecm_isi$beta

cat("\n=== CV1 Raw Coefficients (y-normalized) ===\n")
print(round(beta_isi, 6))

# Extract A, B, C
A_hat   <- -beta_isi["k_CL.l1",      1]
B_hat   <- -beta_isi["k_ME.l1",      1]
C_hat   <- -beta_isi["omega_kME.l1", 1]
kappa_1 <- -beta_isi["constant",     1]

cat(sprintf("\n  A (k_CL):      %+.4f  [Expected > 0: psi^NR]\n", A_hat))
cat(sprintf("  B (k_ME):      %+.4f  [Expected > 0: psi^ME - psi^NR, Kaldor]\n", B_hat))
cat(sprintf("  C (omega_kME): %+.4f  [Expected < 0: distribution compresses machinery]\n", C_hat))

# Sign checks
if (A_hat > 0) cat("  A > 0: infrastructure productive\n") else cat("  WARNING: A <= 0\n")
if (B_hat > 0) cat("  B > 0: Kaldor hypothesis CONFIRMED\n") else cat("  B <= 0: Kaldor NOT confirmed\n")
if (C_hat < 0) cat("  C < 0: distribution compresses machinery channel\n") else cat("  WARNING: C >= 0\n")

# Structural parameter recovery
theta_0_hat <- A_hat
psi_hat     <- A_hat + B_hat
theta_2_hat <- 2 * C_hat

cat(sprintf("\n--- Structural Parameters ---\n"))
cat(sprintf("  psi^NR  = A     = %.4f\n", theta_0_hat))
cat(sprintf("  psi^ME  = A + B = %.4f\n", psi_hat))
cat(sprintf("  theta_2 = 2C    = %.4f\n", theta_2_hat))
cat(sprintf("  Kaldor premium (psi^ME - psi^NR) = B = %.4f\n", B_hat))

# Alpha loadings
alpha_isi <- coef(vecm_isi$rlm)["ect1", ]
cat("\nAlpha loadings (ISI):\n")
print(round(alpha_isi, 4))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 2 — ECT_THETA: FULL SAMPLE STATIONARITY                           ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 2 — ECT_THETA FULL SAMPLE STATIONARITY\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

Y_full <- df %>%
  select(y, k_CL, k_ME, omega_kME) %>%
  as.matrix()
rownames(Y_full) <- df$year

ECT_theta <- as.numeric(
  Y_full %*% beta_isi[1:4, 1] + beta_isi["constant", 1]
)
ECT_theta_lag1 <- c(NA, head(ECT_theta, -1))

adf_ect <- ur.df(na.omit(ECT_theta), type = "drift",
                 selectlags = "BIC", lags = 4)
cat(sprintf("ADF on ECT_theta (full sample):\n"))
cat(sprintf("  tau = %.4f [5%% CV: %.4f] -> %s\n",
    adf_ect@teststat[1], adf_ect@cval[1, 2],
    ifelse(adf_ect@teststat[1] < adf_ect@cval[1, 2],
           "STATIONARY", "NOT STATIONARY")))

cat(sprintf("\nECT_theta by period:\n"))
cat(sprintf("  Pre-ISI (1920-39): %+.4f\n", mean(ECT_theta[df$year %in% 1920:1939], na.rm = TRUE)))
cat(sprintf("  ISI     (1940-72): %+.4f\n", mean(ECT_theta[df$year %in% 1940:1972], na.rm = TRUE)))
cat(sprintf("  Crisis  (1973-82): %+.4f\n", mean(ECT_theta[df$year %in% 1973:1982], na.rm = TRUE)))
cat(sprintf("  Neolib  (1983-24): %+.4f\n", mean(ECT_theta[df$year %in% 1983:2024], na.rm = TRUE)))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 3 — THETA_CL AND MU_CL                                            ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 3 — THETA_CL AND MU_CL\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# FOC-consistent formula:
# theta_CL_t = A + (B + 2C * omega_t) * s_ME_t
theta_CL_t <- A_hat + (B_hat + 2 * C_hat * df$omega) * df$s_ME

cat(sprintf("theta^CL = %.4f + (%.4f + 2*(%.4f)*omega) * s_ME\n",
    A_hat, B_hat, C_hat))
cat(sprintf("theta^CL: mean=%.4f, range=[%.4f, %.4f]\n",
    mean(theta_CL_t, na.rm = TRUE),
    min(theta_CL_t, na.rm = TRUE),
    max(theta_CL_t, na.rm = TRUE)))

periods <- list(
  "Pre-ISI (1920-1939)" = c(1920, 1939),
  "ISI     (1940-1972)" = c(1940, 1972),
  "Crisis  (1973-1982)" = c(1973, 1982),
  "Neolib  (1983-2024)" = c(1983, 2024)
)
cat("\ntheta^CL period means:\n")
for (nm in names(periods)) {
  yr <- periods[[nm]]
  idx <- df$year >= yr[1] & df$year <= yr[2]
  cat(sprintf("  %-25s: %.4f\n", nm, mean(theta_CL_t[idx], na.rm = TRUE)))
}

# mu_CL: pin 1980 = 1.0
df <- df %>%
  arrange(year) %>%
  mutate(
    g_Y    = c(NA, diff(y)),
    g_K_CL = c(NA, diff(k_CL)),
    g_Yp   = theta_CL_t * g_K_CL,
    g_mu   = g_Y - g_Yp,
    mu_CL  = NA_real_
  )
df$mu_CL[df$year == 1980] <- 1.0

for (yr in 1981:max(df$year)) {
  ic <- which(df$year == yr); ip <- which(df$year == yr - 1)
  if (length(ic) == 1 && length(ip) == 1 && !is.na(df$g_mu[ic]))
    df$mu_CL[ic] <- df$mu_CL[ip] * exp(df$g_mu[ic])
}
for (yr in 1979:min(df$year)) {
  ic <- which(df$year == yr); in_ <- which(df$year == yr + 1)
  if (length(ic) == 1 && length(in_) == 1 && !is.na(df$g_mu[in_]))
    df$mu_CL[ic] <- df$mu_CL[in_] / exp(df$g_mu[in_])
}

cat(sprintf("\nmu_CL(1980) = %.6f [target: 1.000000]\n", df$mu_CL[df$year == 1980]))

cat("\nmu_CL period means:\n")
for (nm in names(periods)) {
  yr <- periods[[nm]]
  idx <- df$year >= yr[1] & df$year <= yr[2]
  cat(sprintf("  %-25s: %.4f\n", nm, mean(df$mu_CL[idx], na.rm = TRUE)))
}

# ISI g_mu sanity check
cat("\nISI g_mu sample (should alternate sign):\n")
df %>% filter(year %in% 1940:1955) %>%
  mutate(theta_CL = theta_CL_t[year %in% 1940:1955]) %>%
  select(year, g_Y, g_Yp, g_mu, mu_CL, theta_CL) %>%
  print(n = 16)


# ══════════════════════════════════════════════════════════════════════════════
# FINAL CROSSWALK (Steps 0–3)
# ══════════════════════════════════════════════════════════════════════════════

cat("\n\n")
cat("================================================================\n")
cat("  REPARAMETERIZED FRONTIER — FINAL CROSSWALK\n")
cat("================================================================\n")
cat(sprintf("State vector:       (y, k_CL, k_ME, omega_kME)\n"))
cat(sprintf("Beta from:          ISI subsample (1940-1972, K=%d, r=1)\n", K_isi))
cat(sprintf("cor(k_CL, k_ME):    %.4f  [was %.4f with k_NR/k_ME]\n",
    cor(df_isi$k_CL, df_isi$k_ME),
    cor(df_isi$k_NR, df_isi$k_ME)))
cat(sprintf("\nA (psi^NR):         %+.4f  %s\n", A_hat,
    ifelse(A_hat > 0, "OK", "WRONG SIGN")))
cat(sprintf("B (Kaldor premium): %+.4f  %s\n", B_hat,
    ifelse(B_hat > 0, "Kaldor CONFIRMED", "Kaldor NOT confirmed")))
cat(sprintf("C (theta_2/2):      %+.4f  %s\n", C_hat,
    ifelse(C_hat < 0, "OK", "WRONG SIGN")))
cat(sprintf("\nECT_theta ADF:      tau=%.4f  %s\n",
    adf_ect@teststat[1],
    ifelse(adf_ect@teststat[1] < adf_ect@cval[1, 2],
           "STATIONARY", "NOT STATIONARY")))
cat(sprintf("\ntheta^CL ISI mean:  %.4f\n",
    mean(theta_CL_t[df$year %in% 1940:1972], na.rm = TRUE)))
cat(sprintf("theta^CL Neo mean:  %.4f\n",
    mean(theta_CL_t[df$year %in% 1983:2024], na.rm = TRUE)))
cat(sprintf("mu^CL ISI mean:     %.4f\n",
    mean(df$mu_CL[df$year %in% 1940:1972], na.rm = TRUE)))
cat(sprintf("mu^CL Neo mean:     %.4f\n",
    mean(df$mu_CL[df$year %in% 1983:2024], na.rm = TRUE)))
cat(sprintf("mu^CL(1980):        %.6f\n", df$mu_CL[df$year == 1980]))
cat("================================================================\n")

# Decision gate
cat("\n--- DECISION GATE ---\n")
if (B_hat > 0 && adf_ect@teststat[1] < adf_ect@cval[1, 2]) {
  cat("B > 0 AND ECT stationary: PROCEED to CLS (Step 4).\n")
} else if (B_hat <= 0) {
  cat("B <= 0: Kaldor NOT confirmed. Fall back to Proposal B.\n")
} else {
  cat("ECT NOT stationary: Investigate lag order.\n")
}
