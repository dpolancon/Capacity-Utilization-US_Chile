# Claude Code Prompt 06: Reparameterized Frontier Estimation
## State vector (y, k_CL, k_ME, omega_kME) — FOC-consistent decomposition
## Central test: Is B > 0? (Kaldor hypothesis directly testable)

---

## THEORETICAL MOTIVATION

The original state vector (y, k_NR, k_ME, omega_kME) produced
cor(k_NR, k_ME) = 0.99 in the ISI window — the Johansen cannot
separate theta_0 from psi, yielding psi = -0.176 (wrong sign,
violates the FOC requirement psi^ME > 0).

The fix: reparameterize using total capital k_CL and machinery k_ME.

From the FOC in §3.5.2, the productive frontier is:

  y^p = psi^NR * k^CL + (psi^ME - psi^NR) * k^ME + theta_2 * (omega * k^ME)

So the CV1 maps to:
  A = psi^NR          (total capital elasticity, > 0)
  B = psi^ME - psi^NR (machinery premium over infrastructure, > 0, Kaldor)
  C = theta_2 / 2     (distribution-composition interaction, < 0)

Post-estimation:
  theta_CL_t = A + (B + 2C * omega_t) * s_ME_t

where s_ME = K_ME / (K_NR + K_ME) in (0,1) as before.

Key advantages:
- cor(k_CL, k_ME) ≈ 0.85–0.90 (VIF drops from ~50 to ~5–10)
- k_ME is I(1) confirmed (avoids the I(2) problem from c_t = k_ME - k_NR)
- B directly tests the Kaldor hypothesis: B > 0 iff psi^ME > psi^NR
- A > 0 is required for infrastructure productivity (must verify)
- C < 0 is required for BoP distributional compression (already confirmed)

---

## REPO AND PATHS

REPO   <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
CSV_IN <- file.path(REPO, "output/stage_a/Chile/csv")
CSV_OUT<- file.path(REPO, "output/stage_a/Chile/csv")
PANEL  <- file.path(REPO, "data/final/chile_tvecm_panel.csv")
ECT_M  <- file.path(REPO, "data/processed/Chile/ECT_m_stage1.csv")

---

## STEP 0: SETUP AND DATA LOAD

```r
library(urca); library(vars); library(tidyverse); library(sandwich)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)

df <- read_csv("data/final/chile_tvecm_panel.csv") %>% arrange(year)

ect_s1 <- read_csv("data/processed/Chile/ECT_m_stage1.csv") %>%
  arrange(year) %>%
  mutate(ECT_m_lag1 = lag(ECT_m, 1))

df <- df %>%
  left_join(ect_s1 %>% select(year, ECT_m, ECT_m_lag1), by = "year") %>%
  mutate(
    k_CL     = log(exp(k_NR) + exp(k_ME)),   # total capital
    s_ME     = exp(k_ME) / (exp(k_NR) + exp(k_ME)),  # bounded share
    omega_kME = omega * k_ME                  # same interaction as before
  )

# Collinearity check — key diagnostic
cat(sprintf("cor(k_NR, k_ME)  = %.4f  [OLD — should be ~0.99]\n",
    cor(df$k_NR, df$k_ME, use="complete")))
cat(sprintf("cor(k_CL, k_ME)  = %.4f  [NEW — should be lower]\n",
    cor(df$k_CL, df$k_ME, use="complete")))
```

---

## STEP 1: ISI SUBSAMPLE JOHANSEN — NEW STATE VECTOR

```r
df_isi <- df %>% filter(year >= 1940, year <= 1972)

Y_isi <- df_isi %>%
  select(y, k_CL, k_ME, omega_kME) %>%
  as.matrix()
rownames(Y_isi) <- df_isi$year

cat(sprintf("ISI subsample: N=%d (1940–1972)\n", nrow(Y_isi)))
cat(sprintf("cor(k_CL, k_ME) in ISI: %.4f\n",
    cor(df_isi$k_CL, df_isi$k_ME)))

# Lag selection
var_sel_isi <- VARselect(Y_isi, lag.max=3, type="const")
print(var_sel_isi$selection)
K_isi  <- max(2, as.integer(var_sel_isi$selection["SC(n)"]))
cat(sprintf("VAR lag (SC): %d\n", K_isi))

# Johansen rank test
jo_isi <- ca.jo(Y_isi, type="trace", ecdet="const",
                K=K_isi, spec="transitory")

cat("\n=== ISI Johansen Trace Test (y, k_CL, k_ME, omega_kME) ===\n")
summary(jo_isi)

# Force r=1
vecm_isi <- cajorls(jo_isi, r=1)
beta_isi  <- vecm_isi$beta

cat("\n=== CV1 Raw Coefficients (y-normalized) ===\n")
print(round(beta_isi, 6))

# Extract A, B, C
A_hat   <- -beta_isi["k_CL.l1",     1]
B_hat   <- -beta_isi["k_ME.l1",     1]
C_hat   <- -beta_isi["omega_kME.l1",1]
kappa_1 <- -beta_isi["constant",    1]

cat(sprintf("\n  A (k_CL):      %+.4f  [Expected > 0: psi^NR]\n", A_hat))
cat(sprintf("  B (k_ME):      %+.4f  [Expected > 0: psi^ME - psi^NR, Kaldor]\n", B_hat))
cat(sprintf("  C (omega_kME): %+.4f  [Expected < 0: distribution compresses machinery]\n", C_hat))

# Sign checks
if (A_hat > 0) cat("✓ A > 0: infrastructure productive\n") else warning("A <= 0: WRONG SIGN")
if (B_hat > 0) cat("✓ B > 0: Kaldor hypothesis CONFIRMED\n") else cat("⚠ B <= 0: Kaldor NOT confirmed\n")
if (C_hat < 0) cat("✓ C < 0: distribution compresses machinery channel\n") else warning("C >= 0: WRONG SIGN")

# Structural parameter recovery
theta_0_hat <- A_hat          # psi^NR
psi_hat     <- A_hat + B_hat  # psi^ME = A + B
theta_2_hat <- 2 * C_hat

cat(sprintf("\n--- Structural Parameters ---\n"))
cat(sprintf("  psi^NR  = A     = %.4f\n", theta_0_hat))
cat(sprintf("  psi^ME  = A + B = %.4f\n", psi_hat))
cat(sprintf("  theta_2 = 2C    = %.4f\n", theta_2_hat))
cat(sprintf("  Kaldor premium (psi^ME - psi^NR) = B = %.4f  [Must be > 0]\n", B_hat))
```

---

## STEP 2: ECT_THETA — FULL SAMPLE STATIONARITY TEST

```r
Y_full <- df %>%
  select(y, k_CL, k_ME, omega_kME) %>%
  as.matrix()
rownames(Y_full) <- df$year

ECT_theta <- as.numeric(
  Y_full %*% beta_isi[1:4, 1] + beta_isi["constant", 1]
)
ECT_theta_lag1 <- c(NA, head(ECT_theta, -1))

adf_ect <- ur.df(na.omit(ECT_theta), type="drift",
                 selectlags="BIC", lags=4)
cat(sprintf("\nADF on ECT_theta (full sample, new beta):\n"))
cat(sprintf("  tau = %.4f [5%% CV: %.4f] -> %s\n",
    adf_ect@teststat[1], adf_ect@cval[1,2],
    ifelse(adf_ect@teststat[1] < adf_ect@cval[1,2],
           "STATIONARY ✓", "NOT STATIONARY ⚠")))

cat(sprintf("ECT_theta mean: pre-1973=%.4f | post-1973=%.4f\n",
    mean(ECT_theta[df$year < 1973], na.rm=TRUE),
    mean(ECT_theta[df$year >= 1973], na.rm=TRUE)))
```

---

## STEP 3: THETA_CL AND MU_CL — CORRECTED POST-ESTIMATION

```r
# Post-estimation formula (FOC-consistent):
# theta_CL_t = A + (B + 2C * omega_t) * s_ME_t
#            = psi^NR + (psi^ME - psi^NR + theta_2 * omega_t) * s_ME_t

theta_CL_t <- A_hat + (B_hat + 2 * C_hat * df$omega) * df$s_ME

cat(sprintf("\ntheta^CL = %.4f + (%.4f + 2*(%.4f)*omega) * s_ME\n",
    A_hat, B_hat, C_hat))
cat(sprintf("theta^CL: mean=%.4f, range=[%.4f, %.4f]\n",
    mean(theta_CL_t, na.rm=T),
    min(theta_CL_t, na.rm=T),
    max(theta_CL_t, na.rm=T)))

periods <- list(
  "Pre-ISI (1920-1939)" = c(1920,1939),
  "ISI     (1940-1972)" = c(1940,1972),
  "Crisis  (1973-1982)" = c(1973,1982),
  "Neolib  (1983-2024)" = c(1983,2024)
)
cat("\ntheta^CL period means:\n")
for (nm in names(periods)) {
  yr  <- periods[[nm]]
  idx <- df$year >= yr[1] & df$year <= yr[2]
  cat(sprintf("  %-25s: %.4f\n", nm, mean(theta_CL_t[idx], na.rm=T)))
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
  ic <- which(df$year==yr); ip <- which(df$year==yr-1)
  if (length(ic)==1 && length(ip)==1 && !is.na(df$g_mu[ic]))
    df$mu_CL[ic] <- df$mu_CL[ip] * exp(df$g_mu[ic])
}
for (yr in 1979:min(df$year)) {
  ic <- which(df$year==yr); in_ <- which(df$year==yr+1)
  if (length(ic)==1 && length(in_)==1 && !is.na(df$g_mu[in_]))
    df$mu_CL[ic] <- df$mu_CL[in_] / exp(df$g_mu[in_])
}

cat(sprintf("\nmu_CL(1980) = %.6f [target: 1.000000]\n",
    df$mu_CL[df$year==1980]))

cat("\nmu_CL period means:\n")
for (nm in names(periods)) {
  yr  <- periods[[nm]]
  idx <- df$year >= yr[1] & df$year <= yr[2]
  cat(sprintf("  %-25s: %.4f\n", nm, mean(df$mu_CL[idx], na.rm=T)))
}

# Sanity check: is ISI g_mu cyclical (alternating signs)?
cat("\nISI g_mu sample (should alternate sign):\n")
df %>% filter(year %in% 1940:1955) %>%
  select(year, g_Y, g_Yp, g_mu, mu_CL, theta_CL) %>%
  print(n=16)
```

---

## STEP 4: CLS GRID SEARCH — UNCHANGED

Run the CLS threshold estimation exactly as in
codes/stage_a/chile/03_stage2_frontier_vecm.R
Steps 4–8, but replacing:
- ECT_theta and ECT_theta_lag1 with the new values from Step 2
- theta_CL_t with the new values from Step 3
- Y_levels with the new (y, k_CL, k_ME, omega_kME) matrix

Everything else (grid search, bootstrap, shadow price test) is unchanged.

---

## STEP 5: SAVE AND REPORT

```r
out_dir <- "output/stage_a/Chile/csv"

# Save updated panel
df_out <- df %>%
  mutate(theta_CL = theta_CL_t) %>%
  select(year, y, k_CL, k_ME, s_ME, omega, omega_kME,
         k_NR, ECT_m, ECT_m_lag1,
         theta_CL, g_Y, g_K_CL, g_Yp, g_mu, mu_CL)
write_csv(df_out, file.path(out_dir, "stage2_panel_reparam_v3.csv"))

# Save structural parameters
params_v3 <- tibble(
  parameter  = c("A", "B", "C", "psi_NR", "psi_ME", "theta_2",
                 "kappa_1", "kaldor_premium"),
  estimate   = c(A_hat, B_hat, C_hat, theta_0_hat, psi_hat,
                 theta_2_hat, kappa_1, B_hat),
  sign_prior = c(">0", ">0", "<0", ">0", ">0", "<0", "any", ">0"),
  satisfied  = c(A_hat>0, B_hat>0, C_hat<0, theta_0_hat>0,
                 psi_hat>0, theta_2_hat<0, TRUE, B_hat>0)
)
write_csv(params_v3, file.path(out_dir, "stage2_structural_params_v3.csv"))

# Final crosswalk
cat("\n================================================================\n")
cat("  REPARAMETERIZED FRONTIER — FINAL CROSSWALK\n")
cat("================================================================\n")
cat(sprintf("State vector:       (y, k_CL, k_ME, omega_kME)\n"))
cat(sprintf("Beta from:          ISI subsample (1940–1972, K=%d, r=1)\n", K_isi))
cat(sprintf("cor(k_CL, k_ME):    %.4f  [was %.4f with k_NR/k_ME]\n",
    cor(df_isi$k_CL, df_isi$k_ME),
    cor(df_isi$k_NR, df_isi$k_ME)))
cat(sprintf("\nA (psi^NR):         %+.4f  %s\n", A_hat,
    ifelse(A_hat>0,"✓",  "⚠ WRONG SIGN")))
cat(sprintf("B (Kaldor premium): %+.4f  %s\n", B_hat,
    ifelse(B_hat>0,"✓ Kaldor CONFIRMED", "⚠ Kaldor NOT confirmed")))
cat(sprintf("C (theta_2/2):      %+.4f  %s\n", C_hat,
    ifelse(C_hat<0,"✓", "⚠ WRONG SIGN")))
cat(sprintf("\nECT_theta ADF:      tau=%.4f  %s\n",
    adf_ect@teststat[1],
    ifelse(adf_ect@teststat[1] < adf_ect@cval[1,2],
           "STATIONARY ✓", "NOT STATIONARY ⚠")))
cat(sprintf("\ntheta^CL ISI mean:  %.4f\n",
    mean(theta_CL_t[df$year %in% 1940:1972], na.rm=T)))
cat(sprintf("mu^CL ISI mean:     %.4f\n",
    mean(df$mu_CL[df$year %in% 1940:1972], na.rm=T)))
cat(sprintf("mu^CL(1980):        %.6f\n",
    df$mu_CL[df$year==1980]))
cat("================================================================\n")
```

---

## DECISION GATE

After Step 3, check the crosswalk summary:

IF B > 0 AND ECT_theta stationary:
  → Proceed to CLS in Step 4. Report CONFIRMED Kaldor.
  → This is the primary specification for §2.8.2.

IF B <= 0:
  → Do NOT proceed to CLS with this specification.
  → Report: "Kaldor hypothesis not confirmed in reparameterized system."
  → Fall back to Proposal B: impose homogeneous capital restriction
    (theta_0 = psi) via blrtest() on the original ISI Johansen object.
  → Report that result as the primary specification instead.

IF ECT_theta NOT stationary:
  → Investigate lag order K_isi. Try K=3.
  → If still not stationary after lag adjustment, report as a
    cointegration failure and revert to the original ISI beta
    (stage2_structural_params.csv) with the acknowledged limitation.

---

## OUTPUT FILES

output/stage_a/Chile/csv/stage2_panel_reparam_v3.csv
output/stage_a/Chile/csv/stage2_structural_params_v3.csv
(CLS outputs from Step 4 overwrite existing stage2_* files)

---

*Prompt 06 | 2026-04-08 | FOC-consistent reparameterization*
*State vector: (y, k_CL, k_ME, omega_kME)*
*Theoretical basis: §3.5.2, psi^NR = A, psi^ME = A+B, theta_2 = 2C*
