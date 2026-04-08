# _diag_enhanced_ur.R — Enhanced unit root battery for Stage 2
# Addresses PIM smoothing artifact: standard ADF on d(x) misclassifies
# persistent capital stock series when structural breaks are present.

library(urca)
library(readr)
library(dplyr)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
df <- read_csv(file.path(REPO, "data/final/chile_tvecm_panel.csv"),
               show_col_types = FALSE) %>% arrange(year)
df <- df %>% mutate(
  k_CL    = log(exp(k_NR) + exp(k_ME)),
  c_t     = k_ME - k_NR,
  omega_c = omega * c_t
)

D1973_diff <- df$D1973[-1]

cat("================================================================\n")
cat("  ENHANCED UNIT ROOT BATTERY — PIM BREAK CORRECTION\n")
cat("================================================================\n\n")

vars_list <- list(
  list("k_CL",    df$k_CL),
  list("c_t",     df$c_t),
  list("omega_c", df$omega_c),
  list("y",       df$y),
  list("omega",   df$omega),
  list("phi",     df$phi)
)

results_all <- list()

for (v in vars_list) {
  nm <- v[[1]]; x <- na.omit(v[[2]])
  dx <- diff(x)
  cat(sprintf("\n--- %s ---\n", nm))

  # 1. Standard ADF on d(x) — baseline
  adf_std <- ur.df(dx, type = "drift", selectlags = "BIC", lags = 4)
  std_tau <- adf_std@teststat[1]
  std_rej <- std_tau < adf_std@cval[1, 2]
  cat(sprintf("  ADF(d%s):           tau=%.4f [5%%CV: %.4f] %s\n",
      nm, std_tau, adf_std@cval[1, 2],
      ifelse(std_rej, "REJECT -> I(1)", "fail -> I(2)?")))

  # 2. ADF on d(x) WITH D1973 exogenous (manual regression)
  ddx <- diff(dx)
  T_dd <- length(ddx)
  adf_df <- data.frame(
    ddx     = ddx,
    dx_lag1 = dx[1:T_dd],
    D1973   = D1973_diff[2:(T_dd + 1)]
  )
  for (j in 1:4) {
    adf_df[[paste0("L", j)]] <- c(rep(NA, j), head(ddx, -j))
  }
  adf_df <- na.omit(adf_df)

  best_bic <- Inf; best_p <- 0
  for (pp in 0:4) {
    fml <- "ddx ~ dx_lag1 + D1973"
    if (pp > 0) fml <- paste0(fml, " + ", paste0("L", 1:pp, collapse = " + "))
    fit <- lm(as.formula(fml), data = adf_df)
    bc <- BIC(fit)
    if (bc < best_bic) { best_bic <- bc; best_p <- pp }
  }
  fml <- "ddx ~ dx_lag1 + D1973"
  if (best_p > 0) fml <- paste0(fml, " + ", paste0("L", 1:best_p, collapse = " + "))
  fit_best <- lm(as.formula(fml), data = adf_df)
  tau_d73 <- coef(summary(fit_best))["dx_lag1", "t value"]
  d73_rej <- tau_d73 < -2.88
  cat(sprintf("  ADF(d%s|D1973):     tau=%.4f [5%%CV: ~-2.88] %s  (BIC lags=%d)\n",
      nm, tau_d73, ifelse(d73_rej, "REJECT -> I(1)", "fail -> I(2)?"), best_p))

  # 3. ZA on levels
  za_lev <- ur.za(x, model = "both", lag = 4)
  cat(sprintf("  ZA(levels):         tau=%.4f [5%%CV: -5.08] break=t%d %s\n",
      za_lev@teststat, za_lev@bpoint,
      ifelse(za_lev@teststat < -5.08, "REJECT -> I(0)+break", "fail -> unit root")))

  # 4. ZA on first differences
  za_diff_rej <- FALSE
  tryCatch({
    za_diff <- ur.za(dx, model = "both", lag = 4)
    za_diff_rej <- za_diff@teststat < -5.08
    cat(sprintf("  ZA(d%s):           tau=%.4f [5%%CV: -5.08] break=t%d %s\n",
        nm, za_diff@teststat, za_diff@bpoint,
        ifelse(za_diff_rej, "REJECT -> d(x) stationary -> I(1)", "fail")))
  }, error = function(e) cat(sprintf("  ZA(d%s): error\n", nm)))

  # Verdict
  i1_evidence <- sum(c(std_rej, d73_rej, za_diff_rej))
  if (i1_evidence >= 2) {
    verdict <- "I(1) — confirmed (break-corrected)"
  } else if (i1_evidence == 1) {
    verdict <- "I(1) — marginal (one test rejects)"
  } else {
    verdict <- "I(2) — persists after break correction"
  }
  cat(sprintf("  >>> ENHANCED VERDICT: %s  (%d/3 tests reject d(x) unit root)\n",
      verdict, i1_evidence))

  results_all[[nm]] <- list(
    std_rej = std_rej, d73_rej = d73_rej, za_diff_rej = za_diff_rej,
    i1_evidence = i1_evidence, verdict = verdict
  )
}

# Decision gate
cat("\n================================================================\n")
cat("  DECISION GATE\n")
cat("================================================================\n\n")

cat(sprintf("%-12s  %-6s  %-10s  %-10s  %s\n",
    "Variable", "d-ADF", "d-ADF|D73", "ZA(d(x))", "Verdict"))
cat(strrep("-", 70), "\n")
for (nm in names(results_all)) {
  r <- results_all[[nm]]
  cat(sprintf("%-12s  %-6s  %-10s  %-10s  %s\n",
      nm,
      ifelse(r$std_rej, "rej", "FAIL"),
      ifelse(r$d73_rej, "rej", "FAIL"),
      ifelse(r$za_diff_rej, "rej", "FAIL"),
      r$verdict))
}

ct_ok     <- results_all[["c_t"]]$i1_evidence >= 1
kCL_ok    <- results_all[["k_CL"]]$i1_evidence >= 1
omegac_ok <- results_all[["omega_c"]]$i1_evidence >= 1

cat(sprintf("\nk_CL I(1): %s | c_t I(1): %s | omega_c I(1): %s\n",
    ifelse(kCL_ok, "YES", "NO"), ifelse(ct_ok, "YES", "NO"),
    ifelse(omegac_ok, "YES", "NO")))

if (ct_ok && kCL_ok && omegac_ok) {
  cat("\n>>> OPTION A: Reparameterized vector (y, k_CL, c_t, omega_c) is valid.\n")
  cat("    Proceed with 4-variable Johansen as specified.\n")
} else if (!ct_ok) {
  cat("\n>>> OPTION B: c_t persists as I(2). Switch to original state vector.\n")
  cat("    Use (y, k_NR, k_ME, omega_kME). theta_0/psi not separately identified.\n")
  cat("    Recover theta^CL post-estimation using phi_t and Kaldor prior.\n")
} else {
  cat("\n>>> OPTION A with caveats: c_t passes but other variables borderline.\n")
}
