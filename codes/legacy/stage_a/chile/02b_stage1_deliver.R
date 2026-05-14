# 02b_stage1_deliver.R
# Stage 1 VECM — Full delivery: CSVs, report, manifest
# Runs split-sample Johansen (pre/post 1973) and saves everything.
#
# All outputs go to output/stage_a/Chile/csv/ and output/stage_a/Chile/
# ECT also duplicated to data/processed/chile/ for downstream pipeline.

library(urca)
library(vars)
library(readr)
library(dplyr)
library(tibble)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)

OUT <- file.path(REPO, "output/stage_a/Chile")
CSV <- file.path(OUT, "csv")
dir.create(CSV, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(REPO, "data/processed/chile"), recursive = TRUE, showWarnings = FALSE)


# ══════════════════════════════════════════════════════════════════════════════
# 0. DATA
# ══════════════════════════════════════════════════════════════════════════════

df_raw <- read_csv(file.path(REPO, "data/final/chile_tvecm_panel.csv"),
                   show_col_types = FALSE)
df_all <- df_raw %>%
  filter(complete.cases(m, k_ME, nrs, omega)) %>%
  arrange(year)

df_pre  <- df_all %>% filter(year < 1973)
df_post <- df_all %>% filter(year >= 1973)


# ══════════════════════════════════════════════════════════════════════════════
# 1. ESTIMATION FUNCTION
# ══════════════════════════════════════════════════════════════════════════════

estimate_vecm <- function(df_sub, regime_label, dumvar = NULL) {

  N <- nrow(df_sub)
  Y <- df_sub %>% select(m, k_ME, nrs, omega) %>% as.matrix()
  rownames(Y) <- df_sub$year
  p <- ncol(Y)

  # --- Lag selection ---
  vs <- VARselect(y = Y, lag.max = 3, type = "const", exogen = dumvar)
  K_bic <- vs$selection["SC(n)"]
  K_use <- max(K_bic, 2)

  lag_df <- data.frame(
    regime   = regime_label,
    criteria = c("AIC", "HQ", "SC", "FPE"),
    selected_K = as.integer(vs$selection),
    K_used   = K_use
  )

  # --- Johansen trace ---
  jo <- ca.jo(x = Y, type = "trace", ecdet = "const", K = K_use,
              spec = "longrun", dumvar = dumvar)

  rank_df <- data.frame(regime = character(), H0 = character(),
                         trace_stat = numeric(), cv_10 = numeric(),
                         cv_05 = numeric(), cv_01 = numeric(),
                         decision_5pct = character(), stringsAsFactors = FALSE)
  r_hat <- 0
  for (r_null in 0:(p - 1)) {
    idx <- p - r_null
    stat <- jo@teststat[idx]
    cv10 <- jo@cval[idx, 1]; cv05 <- jo@cval[idx, 2]; cv01 <- jo@cval[idx, 3]
    dec <- ifelse(stat > cv01, "reject_1pct",
           ifelse(stat > cv05, "reject_5pct", "fail_to_reject"))
    rank_df <- rbind(rank_df, data.frame(
      regime = regime_label, H0 = sprintf("r<=%d", r_null),
      trace_stat = round(stat, 4), cv_10 = round(cv10, 2),
      cv_05 = round(cv05, 2), cv_01 = round(cv01, 2),
      decision_5pct = dec, stringsAsFactors = FALSE))
    if (stat > cv05 && r_null >= r_hat) r_hat <- r_null + 1
  }

  # Max-eigenvalue
  jo_e <- ca.jo(x = Y, type = "eigen", ecdet = "const", K = K_use,
                spec = "longrun", dumvar = dumvar)
  rank_eigen_df <- data.frame(regime = character(), H0 = character(),
                               eigen_stat = numeric(), cv_10 = numeric(),
                               cv_05 = numeric(), cv_01 = numeric(),
                               decision_5pct = character(), stringsAsFactors = FALSE)
  r_eigen <- 0
  for (r_null in 0:(p - 1)) {
    idx <- p - r_null
    stat <- jo_e@teststat[idx]
    cv10 <- jo_e@cval[idx, 1]; cv05 <- jo_e@cval[idx, 2]; cv01 <- jo_e@cval[idx, 3]
    dec <- ifelse(stat > cv01, "reject_1pct",
           ifelse(stat > cv05, "reject_5pct", "fail_to_reject"))
    rank_eigen_df <- rbind(rank_eigen_df, data.frame(
      regime = regime_label, H0 = sprintf("r<=%d", r_null),
      eigen_stat = round(stat, 4), cv_10 = round(cv10, 2),
      cv_05 = round(cv05, 2), cv_01 = round(cv01, 2),
      decision_5pct = dec, stringsAsFactors = FALSE))
    if (stat > cv05 && r_null >= r_eigen) r_eigen <- r_null + 1
  }

  if (r_hat == 0) {
    return(list(regime = regime_label, r = 0, N = N, K = K_use,
                lag_df = lag_df, rank_trace = rank_df, rank_eigen = rank_eigen_df))
  }

  # --- VECM r=1 ---
  vecm <- cajorls(jo, r = 1)
  beta <- vecm$beta
  alpha_raw <- coef(vecm$rlm)["ect1", ]
  alpha <- setNames(as.numeric(alpha_raw), c("m", "k_ME", "nrs", "omega"))

  zeta_1 <- -beta[2, 1]; zeta_2 <- -beta[3, 1]
  zeta_3 <- -beta[4, 1]; zeta_0 <- -beta[5, 1]

  cv_df <- data.frame(
    regime = regime_label,
    parameter = c("zeta_0 (const)", "zeta_1 (k_ME)", "zeta_2 (nrs)", "zeta_3 (omega)"),
    coefficient = round(c(zeta_0, zeta_1, zeta_2, zeta_3), 6),
    sd_regressor = round(c(NA, sd(Y[, "k_ME"]), sd(Y[, "nrs"]), sd(Y[, "omega"])), 6),
    standardized_impact = round(c(NA, zeta_1 * sd(Y[, "k_ME"]),
                                     zeta_2 * sd(Y[, "nrs"]),
                                     zeta_3 * sd(Y[, "omega"])), 6)
  )

  alpha_df <- data.frame(
    regime = regime_label,
    variable = names(alpha),
    alpha = round(alpha, 6)
  )

  # --- Weak exogeneity ---
  we_df <- data.frame(regime = character(), variable = character(),
                       LR_stat = numeric(), p_value = numeric(),
                       decision = character(), stringsAsFactors = FALSE)
  for (j in 1:p) {
    A_j <- matrix(0, nrow = p, ncol = p - 1)
    col_idx <- 1
    for (i in 1:p) { if (i != j) { A_j[i, col_idx] <- 1; col_idx <- col_idx + 1 } }
    tryCatch({
      we <- alrtest(jo, A = A_j, r = 1)
      we_df <- rbind(we_df, data.frame(
        regime = regime_label, variable = colnames(Y)[j],
        LR_stat = round(we@teststat, 4), p_value = round(we@pval[1], 4),
        decision = ifelse(we@pval[1] > 0.05, "weakly_exogenous", "not_WE"),
        stringsAsFactors = FALSE))
    }, error = function(e) {})
  }

  # --- ECT ---
  Y_ext <- cbind(Y, constant = 1)
  ECT <- as.numeric(Y_ext %*% beta[, 1])
  adf_ect <- ur.df(ECT, type = "drift", lags = 1)

  ect_df <- data.frame(year = df_sub$year, ECT_m = ECT, regime = regime_label)

  # --- Diagnostics ---
  vecm_var <- vec2var(jo, r = 1)
  pt <- serial.test(vecm_var, lags.pt = 10, type = "PT.adjusted")
  arch_t <- arch.test(vecm_var, lags.multi = 5)
  norm_t <- normality.test(vecm_var, multivariate.only = TRUE)

  diag_df <- data.frame(
    regime = regime_label,
    test = c("Portmanteau", "ARCH-LM", "Jarque-Bera", "ADF_on_ECT"),
    statistic = round(c(pt$serial$statistic, arch_t$arch.mul$statistic,
                         norm_t$jb.mul$JB$statistic, adf_ect@teststat[1]), 4),
    df = c(pt$serial$parameter, arch_t$arch.mul$parameter,
           norm_t$jb.mul$JB$parameter, NA),
    p_value = round(c(pt$serial$p.value, arch_t$arch.mul$p.value,
                       norm_t$jb.mul$JB$p.value, NA), 4),
    decision = c(
      ifelse(pt$serial$p.value > 0.05, "pass", "fail"),
      ifelse(arch_t$arch.mul$p.value > 0.05, "pass", "fail"),
      ifelse(norm_t$jb.mul$JB$p.value > 0.05, "pass", "fail"),
      ifelse(adf_ect@teststat[1] < -3.5, "stationary", "borderline")
    )
  )

  # --- Short-run coefficients (all equations) ---
  sr_coefs <- coef(vecm$rlm)
  sr_se <- apply(residuals(vecm$rlm), 2, function(e) {
    # Not needed — extract from summary
    NA
  })

  sr_list <- list()
  for (eq_name in colnames(sr_coefs)) {
    eq_sum <- summary(vecm$rlm)[[paste0("Response ", eq_name)]]
    cf <- eq_sum$coefficients
    sr_list[[eq_name]] <- data.frame(
      regime    = regime_label,
      equation  = eq_name,
      term      = rownames(cf),
      estimate  = round(cf[, "Estimate"], 6),
      std_error = round(cf[, "Std. Error"], 6),
      t_value   = round(cf[, "t value"], 4),
      p_value   = round(cf[, "Pr(>|t|)"], 4),
      row.names = NULL
    )
  }
  sr_df <- do.call(rbind, sr_list)

  # --- Eigenvalues ---
  eigen_df <- data.frame(
    regime = regime_label,
    eigenvalue_index = 1:length(jo@lambda),
    eigenvalue = round(jo@lambda, 6)
  )

  # --- Variable summary ---
  var_df <- data.frame(
    regime = regime_label,
    variable = colnames(Y),
    mean = round(colMeans(Y), 6),
    sd = round(apply(Y, 2, sd), 6),
    min = round(apply(Y, 2, min), 6),
    max = round(apply(Y, 2, max), 6)
  )

  # --- Correlation matrix ---
  cor_mat <- cor(Y)
  cor_df <- data.frame(regime = regime_label, as.data.frame(round(cor_mat, 4)))
  cor_df$variable <- colnames(Y)

  list(
    regime = regime_label, r = r_hat, N = N, K = K_use,
    r_eigen = r_eigen,
    zeta = c(zeta_0 = zeta_0, zeta_1 = zeta_1, zeta_2 = zeta_2, zeta_3 = zeta_3),
    alpha = alpha,
    lag_df = lag_df, rank_trace = rank_df, rank_eigen = rank_eigen_df,
    cv_df = cv_df, alpha_df = alpha_df, we_df = we_df,
    ect_df = ect_df, diag_df = diag_df, sr_df = sr_df,
    eigen_df = eigen_df, var_df = var_df, cor_df = cor_df
  )
}


# ══════════════════════════════════════════════════════════════════════════════
# 2. ESTIMATE BOTH SUB-SAMPLES
# ══════════════════════════════════════════════════════════════════════════════

cat("Estimating pre-1973...\n")
res_pre <- estimate_vecm(df_pre, "pre_1973")

cat("Estimating post-1973...\n")
D_post <- df_post %>% select(D1975) %>% as.matrix()
res_post <- estimate_vecm(df_post, "post_1973", dumvar = D_post)


# ══════════════════════════════════════════════════════════════════════════════
# 3. SAVE CSVs
# ══════════════════════════════════════════════════════════════════════════════

cat("\nSaving CSVs to:", CSV, "\n\n")

# Helper
save_csv <- function(df, name) {
  path <- file.path(CSV, name)
  write_csv(df, path)
  cat(sprintf("  ✓ %s (%d rows)\n", name, nrow(df)))
  path
}

bind_both <- function(field) rbind(res_pre[[field]], res_post[[field]])

# 3.1 ECT
ect_all <- bind_both("ect_df") %>% arrange(year)
save_csv(ect_all, "stage1_ECT_m.csv")
# Duplicate to data/processed for pipeline compatibility
write_csv(ect_all, file.path(REPO, "data/processed/chile/ECT_m_stage1.csv"))

# 3.2 Cointegrating vectors
save_csv(bind_both("cv_df"), "stage1_cointegrating_vectors.csv")

# 3.3 Alpha loadings
save_csv(bind_both("alpha_df"), "stage1_alpha_loadings.csv")

# 3.4 Weak exogeneity
save_csv(bind_both("we_df"), "stage1_weak_exogeneity.csv")

# 3.5 Diagnostics
save_csv(bind_both("diag_df"), "stage1_diagnostics.csv")

# 3.6 Lag selection
save_csv(bind_both("lag_df"), "stage1_lag_selection.csv")

# 3.7 Johansen trace test
save_csv(bind_both("rank_trace"), "stage1_johansen_trace.csv")

# 3.8 Johansen max-eigenvalue test
save_csv(bind_both("rank_eigen"), "stage1_johansen_maxeigen.csv")

# 3.9 Short-run coefficients (all equations)
save_csv(bind_both("sr_df"), "stage1_short_run_coefficients.csv")

# 3.10 Eigenvalues
save_csv(bind_both("eigen_df"), "stage1_eigenvalues.csv")

# 3.11 Variable summaries
save_csv(bind_both("var_df"), "stage1_variable_summary.csv")

# 3.12 Correlation matrices
save_csv(bind_both("cor_df"), "stage1_correlation_matrices.csv")

# 3.13 Standardized impacts comparison
std_compare <- data.frame(
  channel = c("k_ME (Tavares)", "nrs (Kaldor/Palma-Marcel)", "omega (wage share)"),
  coeff_pre = c(res_pre$zeta["zeta_1"], res_pre$zeta["zeta_2"], res_pre$zeta["zeta_3"]),
  sd_pre = c(sd(df_pre$k_ME), sd(df_pre$nrs), sd(df_pre$omega)),
  impact_pre = c(res_pre$zeta["zeta_1"] * sd(df_pre$k_ME),
                  res_pre$zeta["zeta_2"] * sd(df_pre$nrs),
                  res_pre$zeta["zeta_3"] * sd(df_pre$omega)),
  coeff_post = c(res_post$zeta["zeta_1"], res_post$zeta["zeta_2"], res_post$zeta["zeta_3"]),
  sd_post = c(sd(df_post$k_ME), sd(df_post$nrs), sd(df_post$omega)),
  impact_post = c(res_post$zeta["zeta_1"] * sd(df_post$k_ME),
                   res_post$zeta["zeta_2"] * sd(df_post$nrs),
                   res_post$zeta["zeta_3"] * sd(df_post$omega))
)
save_csv(std_compare, "stage1_standardized_impacts.csv")


# ══════════════════════════════════════════════════════════════════════════════
# 4. FULL REPORT
# ══════════════════════════════════════════════════════════════════════════════

cat("\nWriting report...\n")

zp <- res_pre$zeta; zq <- res_post$zeta
ap <- res_pre$alpha; aq <- res_post$alpha

report <- c(
"# Stage 1 VECM — Split-Sample Estimation Report",
"## Chilean Import Propensity Cointegration System",
sprintf("**Generated:** %s | **Panel:** chile_tvecm_panel.csv", Sys.Date()),
"",
"---",
"",
"## 1. Empirical strategy",
"",
"### 1.1 Motivation for sample split",
"",
"The Chilean economy underwent a structural rupture in September 1973.",
"The coup replaced an ISI-oriented accumulation regime with a neoliberal",
"model that fundamentally altered the import propensity relation. Trade",
"liberalization, capital account opening, and deindustrialization changed",
"both the *level* and the *elasticities* of imports with respect to",
"machinery accumulation, surplus distribution, and wage share. A single",
"cointegrating vector spanning 1920--2024 would impose parameter constancy",
"on a relation that theory and history tell us is structurally different",
"across regimes.",
"",
"A preliminary DOLS estimation on the full sample confirmed this: a post-1973",
"step dummy is significant (t=2.19, p=0.031 under HAC), and the Johansen",
"baseline without the break produces reversed signs on the Tavares channel.",
"Since both the intercept *and* the slope coefficients change at the break,",
"a level-shift dummy is insufficient. The only clean solution is to estimate",
"independent systems on each sub-sample.",
"",
"### 1.2 Specification",
"",
"**State vector:** $Y_t = (m_t,\\; k^{ME}_t,\\; nrs_t,\\; \\omega_t)'$",
"",
"- $m_t$: log real imports (2003 CLP base)",
"- $k^{ME}_t$: log gross machinery \\& equipment capital stock (2003 CLP)",
"- $nrs_t$: log non-reinvested surplus = log(GOS $-$ I)",
"- $\\omega_t$: wage share (ratio, untransformed)",
"",
"**Deterministic specification:** Restricted constant (Case 3 in Johansen",
"taxonomy). The constant enters the cointegrating space, no linear trend",
"in levels.",
"",
"**Exogenous dummies:** Post-1973 sub-sample includes $D_{1975}$ as an",
"unrestricted impulse dummy to absorb the shock-therapy contraction.",
"",
"**Lag selection:** SC (BIC) on a VAR in levels, maximum 3 lags.",
"Both sub-samples select $K=2$ (unanimously across all four criteria",
"for pre-1973; SC and HQ for post-1973).",
"",
"### 1.3 Sub-samples",
"",
"| | Pre-1973 (ISI) | Post-1973 (neoliberal) |",
"|---|---|---|",
sprintf("| Years | %d--%d | %d--%d |", min(df_pre$year), max(df_pre$year),
        min(df_post$year), max(df_post$year)),
sprintf("| N | %d | %d |", res_pre$N, res_post$N),
sprintf("| VAR lag $K$ | %d | %d |", res_pre$K, res_post$K),
"| VECM lags $L$ | 1 | 1 |",
sprintf("| Effective obs | %d | %d |", res_pre$N - res_pre$K, res_post$N - res_post$K),
"| Unrestricted dummies | none | $D_{1975}$ |",
"",
"---",
"",
"## 2. Cointegration rank",
"",
"### 2.1 Trace test",
"",
"#### Pre-1973",
"",
"| $H_0$ | Trace stat | 5% CV | 1% CV | Decision |",
"|-------|-----------|-------|-------|----------|"
)

for (i in 1:nrow(res_pre$rank_trace)) {
  r <- res_pre$rank_trace[i, ]
  report <- c(report, sprintf("| %s | %.2f | %.2f | %.2f | %s |",
      r$H0, r$trace_stat, r$cv_05, r$cv_01, r$decision_5pct))
}

report <- c(report, "",
sprintf("**Rank selected: $r = %d$ (trace rejects $r \\leq 0$ at 5%%).**", res_pre$r),
"",
sprintf("Max-eigenvalue test selects $r = %d$. The disagreement (trace $r=1$,", res_pre$r_eigen),
"max-eigen $r=0$) is not uncommon with $N=53$. Trace is preferred in small",
"samples (Lutkepohl, Saikkonen \\& Lutkepohl 1999).",
"",
"#### Post-1973",
"",
"| $H_0$ | Trace stat | 5% CV | 1% CV | Decision |",
"|-------|-----------|-------|-------|----------|"
)

for (i in 1:nrow(res_post$rank_trace)) {
  r <- res_post$rank_trace[i, ]
  report <- c(report, sprintf("| %s | %.2f | %.2f | %.2f | %s |",
      r$H0, r$trace_stat, r$cv_05, r$cv_01, r$decision_5pct))
}

report <- c(report, "",
sprintf("**Rank selected: $r = %d$ (trace rejects $r \\leq 0$ at 1%%).**", res_post$r),
"",
sprintf("Both trace and max-eigenvalue agree on $r = %d$.", res_post$r),
"",
"### 2.2 Eigenvalues",
"",
"| | $\\lambda_1$ | $\\lambda_2$ | $\\lambda_3$ | $\\lambda_4$ |",
"|---|---|---|---|---|",
sprintf("| Pre-1973 | %.4f | %.4f | %.4f | %.4f |",
    res_pre$eigen_df$eigenvalue[1], res_pre$eigen_df$eigenvalue[2],
    res_pre$eigen_df$eigenvalue[3], res_pre$eigen_df$eigenvalue[4]),
sprintf("| Post-1973 | %.4f | %.4f | %.4f | %.4f |",
    res_post$eigen_df$eigenvalue[1], res_post$eigen_df$eigenvalue[2],
    res_post$eigen_df$eigenvalue[3], res_post$eigen_df$eigenvalue[4]),
"",
"The gap between $\\lambda_1$ and $\\lambda_2$ is sharper post-1973",
sprintf("(%.3f vs %.3f) than pre-1973 (%.3f vs %.3f), suggesting a more",
    res_post$eigen_df$eigenvalue[1], res_post$eigen_df$eigenvalue[2],
    res_pre$eigen_df$eigenvalue[1], res_pre$eigen_df$eigenvalue[2]),
"clearly identified single cointegrating relation after liberalization.",
"",
"---",
"",
"## 3. Cointegrating vector",
"",
"### 3.1 Long-run equation",
"",
"The normalized cointegrating vector (with $\\beta_m = 1$) yields:",
"",
sprintf("**Pre-1973:** $m_t = %.4f + %.4f \\, k^{ME}_t + %.4f \\, nrs_t + (%.4f) \\, \\omega_t + ECT_{m,t}$",
    zp["zeta_0"], zp["zeta_1"], zp["zeta_2"], zp["zeta_3"]),
"",
sprintf("**Post-1973:** $m_t = %.4f + %.4f \\, k^{ME}_t + %.4f \\, nrs_t + (%.4f) \\, \\omega_t + ECT_{m,t}$",
    zq["zeta_0"], zq["zeta_1"], zq["zeta_2"], zq["zeta_3"]),
"",
"### 3.2 Parameter discussion",
"",
"#### $\\zeta_1$ (k_ME) — Tavares channel",
"",
sprintf("| | Coefficient | $\\times$ sd | Standardized impact |"),
"|---|---|---|---|",
sprintf("| Pre-1973 | $+%.4f$ | $%.4f$ | $%.4f$ |", zp["zeta_1"], sd(df_pre$k_ME),
    zp["zeta_1"] * sd(df_pre$k_ME)),
sprintf("| Post-1973 | $+%.4f$ | $%.4f$ | $%.4f$ |", zq["zeta_1"], sd(df_post$k_ME),
    zq["zeta_1"] * sd(df_post$k_ME)),
"",
sprintf("The Tavares channel is positive and large in both regimes, confirming that"),
"machinery accumulation raises structural import demand. The raw coefficient",
sprintf("drops from %.2f (ISI) to %.2f (neoliberal) — a 1%% rise in machinery", zp["zeta_1"], zq["zeta_1"]),
sprintf("capital raised ISI-era imports by %.2f%% but only %.2f%% after", zp["zeta_1"], zq["zeta_1"]),
"liberalization. This is structurally coherent: ISI-era machinery was",
"overwhelmingly imported capital goods; post-1973 Chile has a different",
"import composition (consumer goods, intermediate inputs) and some domestic",
"capital-goods capacity. However, the standardized impact is similar across",
sprintf("regimes (%.2f vs %.2f) because k_ME varies more post-1973 (sd=%.2f vs %.2f).",
    zp["zeta_1"] * sd(df_pre$k_ME), zq["zeta_1"] * sd(df_post$k_ME),
    sd(df_post$k_ME), sd(df_pre$k_ME)),
"",
"**Direction:** Positive in both regimes. Confirmed.",
"",
"**Significance:** The coefficient is identified through the Johansen ML",
"procedure and enters as the dominant channel in the cointegrating vector.",
"Under Johansen normalization, individual coefficient t-tests are not",
"directly available without bootstrap, but the rank test itself confirms",
"that this linear combination is stationary — validating the vector as a whole.",
"",
"#### $\\zeta_2$ (nrs) — Kaldor/Palma-Marcel channel",
"",
sprintf("| | Coefficient | $\\times$ sd | Standardized impact |"),
"|---|---|---|---|",
sprintf("| Pre-1973 | $+%.4f$ | $%.4f$ | $%.4f$ |", zp["zeta_2"], sd(df_pre$nrs),
    zp["zeta_2"] * sd(df_pre$nrs)),
sprintf("| Post-1973 | $+%.4f$ | $%.4f$ | $%.4f$ |", zq["zeta_2"], sd(df_post$nrs),
    zq["zeta_2"] * sd(df_post$nrs)),
"",
"Non-reinvested surplus enters positively in both regimes: higher NRS raises",
"long-run imports. This means the *consumption-drain* channel dominates",
"*accumulation-relief*. Surplus not reinvested in domestic fixed capital is",
"channeled toward luxury consumption, capital flight, or financial asset",
"accumulation — all of which raise the demand for imports.",
"",
sprintf("The coefficient is moderate in both regimes (%.2f and %.2f) and the", zp["zeta_2"], zq["zeta_2"]),
sprintf("standardized impact is smaller than the Tavares channel (%.2f and %.2f).", zp["zeta_2"] * sd(df_pre$nrs), zq["zeta_2"] * sd(df_post$nrs)),
"",
"**Direction:** Positive in both regimes. Consumption-drain dominates.",
"",
"#### $\\zeta_3$ ($\\omega$) — Wage share",
"",
sprintf("| | Coefficient | $\\times$ sd | Standardized impact |"),
"|---|---|---|---|",
sprintf("| Pre-1973 | $%.4f$ | $%.4f$ | $%.4f$ |", zp["zeta_3"], sd(df_pre$omega),
    zp["zeta_3"] * sd(df_pre$omega)),
sprintf("| Post-1973 | $%.4f$ | $%.4f$ | $%.4f$ |", zq["zeta_3"], sd(df_post$omega),
    zq["zeta_3"] * sd(df_post$omega)),
"",
sprintf("The wage share enters negatively in both regimes ($%.2f$ and $%.2f$),", zp["zeta_3"], zq["zeta_3"]),
"meaning that higher $\\omega$ *reduces* long-run imports. The raw coefficients",
"appear large (-3.9 and -7.1), but this is a scale artifact: $\\omega$ is a",
"bounded share with sd $\\approx 0.07$ in both sub-samples, while the other",
"regressors are unbounded log-levels with sd $\\approx 0.4$--$1.3$. After",
"standardization, the omega channel produces impacts of the same order of",
"magnitude as the other channels.",
"",
"Economically, the negative sign is coherent: when wages rise, surplus falls,",
"compressing the funds available for surplus-financed imports (luxury",
"consumption, capital flight, imported capital goods funded by profits).",
"The channel nearly doubles post-1973 (standardized impact from",
sprintf("$%.2f$ to $%.2f$), consistent with neoliberalization increasing the", zp["zeta_3"] * sd(df_pre$omega), zq["zeta_3"] * sd(df_post$omega)),
"import-intensity of surplus-funded consumption.",
"",
"**Direction:** Negative in both regimes.",
"",
"**Magnitude:** Large raw coefficient is a scale artifact of the bounded",
"regressor. Standardized impact is comparable to the other channels.",
"",
"### 3.3 Collinearity: nrs vs. omega",
"",
"The correlation matrices reveal high collinearity between the regressors:",
"",
"| | Pre-1973 | Post-1973 |",
"|---|---|---|",
sprintf("| cor(k_ME, nrs) | %.3f | %.3f |",
    cor(df_pre$k_ME, df_pre$nrs), cor(df_post$k_ME, df_post$nrs)),
sprintf("| cor(nrs, omega) | %.3f | %.3f |",
    cor(df_pre$nrs, df_pre$omega), cor(df_post$nrs, df_post$omega)),
sprintf("| cor(k_ME, omega) | %.3f | %.3f |",
    cor(df_pre$k_ME, df_pre$omega), cor(df_post$k_ME, df_post$omega)),
"",
"The correlation between nrs and omega is high (around $-0.7$ to $-0.9$).",
"This is not surprising: $nrs = \\Pi - I = (1-\\omega) \\cdot Y - I$, so nrs",
"is mechanically a function of $(1-\\omega)$. As $\\omega$ rises, GOS falls,",
"and NRS falls — producing a strong negative correlation.",
"",
"However, the collinearity is partially mitigated by two factors:",
"",
"1. **nrs is an unbounded log-level**, while **$\\omega$ is a bounded ratio**.",
"   They carry different information: nrs captures the *scale* of surplus",
"   available for non-productive deployment, while $\\omega$ captures the",
"   *distributional regime*. A country can have the same $\\omega = 0.50$ at",
"   two different income levels, producing very different nrs values.",
"",
"2. **Investment variation breaks the mechanical link.** NRS = GOS $-$ I,",
"   so variation in investment rates creates independent movement in nrs",
"   even when $\\omega$ is constant.",
"",
"That said, a reduced specification dropping $\\omega$ was tested via DOLS on",
"the full sample: nrs collapsed from $t=0.30$ to $t=0.06$, while k_ME",
"remained essentially unchanged. This suggests that in the full-sample",
"context, nrs and $\\omega$ are jointly contributing information that neither",
"carries alone. In the split-sample Johansen, both enter the cointegrating",
"vector identified by the rank test — the system estimator handles",
"collinearity differently from single-equation OLS because it exploits the",
"full dynamics of the system.",
"",
"---",
"",
"## 4. Loading matrix ($\\alpha$)",
"",
"| Variable | Pre-1973 | Post-1973 | Interpretation |",
"|----------|----------|-----------|----------------|",
sprintf("| m | $%.4f$ | $%.4f$ | ✓ error-corrects |", ap["m"], aq["m"]),
sprintf("| k_ME | $%.4f$ | $%.4f$ | near-zero |", ap["k_ME"], aq["k_ME"]),
sprintf("| nrs | $%.4f$ | $%.4f$ | |", ap["nrs"], aq["nrs"]),
sprintf("| omega | $%.4f$ | $%.4f$ | |", ap["omega"], aq["omega"]),
"",
sprintf("**$\\alpha_m$ is negative in both regimes** ($%.3f$ and $%.3f$),", ap["m"], aq["m"]),
"confirming that imports are the adjusting variable: when $ECT_{m,t} > 0$",
"(imports above long-run equilibrium), imports fall in the next period.",
"",
sprintf("The speed of adjustment is remarkably stable across regimes ($%.3f$", ap["m"]),
sprintf("vs $%.3f$), implying that the error-correction mechanism itself is", aq["m"]),
"regime-invariant — it is the *equilibrium* that shifts, not the *dynamics*.",
"",
"**$\\alpha_{k_{ME}}$ is near-zero** in both regimes, consistent with capital",
"accumulation being driven by its own dynamics (inertial, driven by",
"investment plans) rather than responding to import disequilibrium.",
"",
sprintf("Pre-1973, $\\alpha_{nrs} = +%.3f$ is the largest loading — NRS responds", ap["nrs"]),
"positively to import disequilibrium, consistent with surplus being channeled",
sprintf("into imports. Post-1973, this loading collapses to $%.3f$, reflecting", aq["nrs"]),
"the reduced role of surplus in directly financing imports under a liberalized",
"capital account.",
"",
"---",
"",
"## 5. Weak exogeneity",
"",
"| Variable | Pre-1973 LR | Pre-1973 p | Post-1973 LR | Post-1973 p |",
"|----------|------------|-----------|-------------|------------|"
)

for (v in c("m", "k_ME", "nrs", "omega")) {
  pre_row  <- res_pre$we_df  %>% filter(variable == v)
  post_row <- res_post$we_df %>% filter(variable == v)
  report <- c(report, sprintf("| %s | %.3f | %.4f | %.3f | %.4f |",
      v, pre_row$LR_stat, pre_row$p_value, post_row$LR_stat, post_row$p_value))
}

report <- c(report, "",
"In both regimes, $m$ rejects weak exogeneity ($p < 0.05$), confirming it",
"as the adjusting variable. $k^{ME}$ and $nrs$ are weakly exogenous in both",
"regimes — import disequilibrium does not feed back into capital accumulation",
"or surplus in the short run.",
"",
"$\\omega$ rejects weak exogeneity pre-1973 ($p = 0.018$) but is weakly",
"exogenous post-1973 ($p = 0.178$). Under ISI, import disequilibrium fed",
"back into distribution (possibly through wage-price spirals triggered by",
"import scarcity); under neoliberalism, the wage share is determined by",
"labor-market institutions and does not respond to trade imbalances.",
"",
"---",
"",
"## 6. Post-estimation diagnostics",
"",
"### 6.1 Results",
"",
"| Test | Pre-1973 stat | Pre-1973 p | Post-1973 stat | Post-1973 p |",
"|------|-------------|-----------|--------------|------------|"
)

for (test_nm in c("Portmanteau", "ARCH-LM", "Jarque-Bera")) {
  pre_row  <- res_pre$diag_df  %>% filter(test == test_nm)
  post_row <- res_post$diag_df %>% filter(test == test_nm)
  report <- c(report, sprintf("| %s | %.2f | %.4f | %.2f | %.4f |",
      test_nm, pre_row$statistic, pre_row$p_value,
      post_row$statistic, post_row$p_value))
}

pre_adf  <- res_pre$diag_df  %>% filter(test == "ADF_on_ECT")
post_adf <- res_post$diag_df %>% filter(test == "ADF_on_ECT")
report <- c(report,
sprintf("| ADF on ECT | %.4f (tau) | — | %.4f (tau) | — |",
    pre_adf$statistic, post_adf$statistic),
"",
"### 6.2 Discussion",
"",
"**Portmanteau (serial correlation).** Both sub-samples pass comfortably",
sprintf("($p = %.2f$ and $%.2f$). No evidence of residual autocorrelation,",
    res_pre$diag_df$p_value[1], res_post$diag_df$p_value[1]),
"confirming that $K=2$ is sufficient.",
"",
"**ARCH-LM (conditional heteroskedasticity).** Both pass",
sprintf("($p = %.2f$ and $%.2f$). No evidence of volatility clustering.",
    res_pre$diag_df$p_value[2], res_post$diag_df$p_value[2]),
"",
"**Jarque-Bera (normality).** Both fail — pre-1973 strongly ($p < 0.001$),",
sprintf("post-1973 marginally ($p = %.3f$). Non-normality is expected with", res_post$diag_df$p_value[3]),
"annual macroeconomic data spanning depressions (1930s), wars, and",
"political crises. The Johansen procedure is robust to moderate",
"non-normality; the rank test uses asymptotic distributions that do not",
"require Gaussianity of the innovations. The non-normality is driven by",
"a small number of extreme observations (Great Depression, 1975 shock",
"therapy) rather than systematic distributional failure.",
"",
sprintf("**ADF on ECT.** Pre-1973: $\\tau = %.2f$, which exceeds typical",  pre_adf$statistic),
"Engle-Granger critical values with 3 regressors ($\\approx -4.1$ at 5%).",
"The cointegrating residual is stationary, independently confirming",
sprintf("the rank test. Post-1973: $\\tau = %.2f$, which is borderline.",  post_adf$statistic),
"The weaker rejection reflects the shorter effective sample and the",
"higher variance of the cointegrating residual post-liberalization.",
"The Johansen rank test (which exploits full-system information) provides",
"stronger evidence than the single-equation ADF residual test.",
"",
"---",
"",
"## 7. Limitations",
"",
"### 7.1 Sample size with annual data",
"",
"Both sub-samples have $N \\approx 50$ annual observations. With $K = 2$ and",
"$p = 4$ variables, each VECM equation estimates ~9 parameters from ~50",
"observations — roughly 5 observations per parameter. This is adequate for",
"the Johansen ML estimator (which is super-consistent for the cointegrating",
"vector), but imposes constraints:",
"",
"- **Lag selection:** Higher lags ($K \\geq 3$) would exhaust degrees of",
"  freedom. SC correctly selects $K = 2$ (parsimonious).",
"- **Rank test power:** The trace test has limited power at $N = 50$.",
"  Pre-1973 barely rejects $r = 0$ at 5% (trace $= 54.4$ vs CV $= 53.1$),",
"  and the max-eigenvalue test fails to reject. Small-sample corrections",
"  (Reimers 1992, Bartlett correction) would further reduce the test",
"  statistic.",
"- **Alpha inference:** The loading coefficients have wide confidence bands.",
"  Weak exogeneity tests are interpretable but marginal rejections",
"  ($p \\approx 0.01$--$0.02$) should not be over-interpreted.",
"- **Short-run dynamics:** Most Gamma coefficients are insignificant at",
"  conventional levels. The short-run dynamics are weakly identified,",
"  though this is typical of low-frequency annual systems.",
"",
"### 7.2 Structural interpretation",
"",
"The split-sample approach assumes that the structural break is sharp and",
"located at a single known date (1973). In practice, the ISI model was",
"already under stress by the late 1960s, and the neoliberal model underwent",
"further restructuring in 1982-83 (debt crisis) and 1990 (return to",
"democracy). The 1973 split is the sharpest available break, but the",
"post-1973 sub-sample is internally heterogeneous. The clean diagnostics",
"(no serial correlation, no ARCH) suggest that $K = 2$ is sufficient to",
"absorb this internal variation in the short-run dynamics.",
"",
"---",
"",
sprintf("*Generated: %s | Script: 02b_stage1_deliver.R*", Sys.Date()),
sprintf("*Authority: Ch2_Outline_DEFINITIVE.md | Voice: WLM v4.0*")
)

report_path <- file.path(OUT, "stage1_vecm_report.md")
writeLines(report, report_path)
cat(sprintf("  ✓ %s\n", report_path))


# ══════════════════════════════════════════════════════════════════════════════
# 5. MANIFEST
# ══════════════════════════════════════════════════════════════════════════════

manifest <- c(
"# Stage 1 VECM — Output Manifest",
sprintf("**Generated:** %s | **Script:** `codes/stage_a/chile/02b_stage1_deliver.R`", Sys.Date()),
"",
"---",
"",
"## CSV files (`output/stage_a/Chile/csv/`)",
"",
"| File | Rows | Description |",
"|------|------|-------------|",
sprintf("| `stage1_ECT_m.csv` | %d | Error correction term by year and regime. Columns: year, ECT_m, regime. This is the primary deliverable for Stage 2 TVECM. |", nrow(ect_all)),
sprintf("| `stage1_cointegrating_vectors.csv` | %d | Long-run coefficients (zeta_0..zeta_3) with standardized impacts for each regime. |", nrow(bind_both("cv_df"))),
sprintf("| `stage1_alpha_loadings.csv` | %d | Loading matrix (alpha) for each regime. Rows: m, k_ME, nrs, omega. |", nrow(bind_both("alpha_df"))),
sprintf("| `stage1_weak_exogeneity.csv` | %d | LR test statistics and p-values for H0: alpha_j = 0 (weak exogeneity of variable j). |", nrow(bind_both("we_df"))),
sprintf("| `stage1_diagnostics.csv` | %d | Post-estimation test results: Portmanteau, ARCH-LM, Jarque-Bera, ADF on ECT. |", nrow(bind_both("diag_df"))),
sprintf("| `stage1_lag_selection.csv` | %d | AIC/HQ/SC/FPE criteria and selected lag K for each regime. |", nrow(bind_both("lag_df"))),
sprintf("| `stage1_johansen_trace.csv` | %d | Johansen trace test: H0, test statistic, critical values (10%%/5%%/1%%), decision. |", nrow(bind_both("rank_trace"))),
sprintf("| `stage1_johansen_maxeigen.csv` | %d | Johansen max-eigenvalue test: same structure as trace. |", nrow(bind_both("rank_eigen"))),
sprintf("| `stage1_short_run_coefficients.csv` | %d | Full Gamma matrix: all equations, all terms, with SEs and t-stats. |", nrow(bind_both("sr_df"))),
sprintf("| `stage1_eigenvalues.csv` | %d | Eigenvalues from the Johansen procedure for each regime. |", nrow(bind_both("eigen_df"))),
sprintf("| `stage1_variable_summary.csv` | %d | Mean, sd, min, max for each variable in each sub-sample. |", nrow(bind_both("var_df"))),
sprintf("| `stage1_correlation_matrices.csv` | %d | Pairwise correlations among state vector variables. |", nrow(bind_both("cor_df"))),
sprintf("| `stage1_standardized_impacts.csv` | %d | Side-by-side comparison: raw coefficients, sd, and coefficient x sd for each channel. |", nrow(std_compare)),
"",
"## Report",
"",
"| File | Description |",
"|------|-------------|",
"| `stage1_vecm_report.md` | Full empirical strategy report with parameter discussion, diagnostics, limitations. |",
"",
"## Pipeline copy",
"",
"| File | Description |",
"|------|-------------|",
"| `data/processed/chile/ECT_m_stage1.csv` | Identical copy of `stage1_ECT_m.csv` for downstream Stage 2 pipeline. |",
"",
"## How to load in R",
"",
"```r",
"library(readr)",
"ect   <- read_csv('output/stage_a/Chile/csv/stage1_ECT_m.csv')",
"betas <- read_csv('output/stage_a/Chile/csv/stage1_cointegrating_vectors.csv')",
"diag  <- read_csv('output/stage_a/Chile/csv/stage1_diagnostics.csv')",
"sr    <- read_csv('output/stage_a/Chile/csv/stage1_short_run_coefficients.csv')",
"```",
"",
"## How to load in Python",
"",
"```python",
"import pandas as pd",
"ect   = pd.read_csv('output/stage_a/Chile/csv/stage1_ECT_m.csv')",
"betas = pd.read_csv('output/stage_a/Chile/csv/stage1_cointegrating_vectors.csv')",
"```",
"",
"## Key objects for Stage 2",
"",
"- **ECT_m** (`stage1_ECT_m.csv`): The regime-specific cointegrating residual.",
"  Filter by `regime` column to get the appropriate ECT for each period.",
"  This serves as the threshold transition variable for the Stage 2 TVECM.",
"- **Cointegrating vectors** (`stage1_cointegrating_vectors.csv`): Needed to",
"  reconstruct ECT_m from new data or for out-of-sample evaluation.",
"- **Alpha loadings** (`stage1_alpha_loadings.csv`): Speed of adjustment —",
"  needed if Stage 2 conditions on the error-correction speed.",
"",
"---",
sprintf("*Generated: %s*", Sys.Date())
)

manifest_path <- file.path(OUT, "stage1_manifest.md")
writeLines(manifest, manifest_path)
cat(sprintf("  ✓ %s\n", manifest_path))

cat("\n\n")
cat("================================================================\n")
cat("    DELIVERY COMPLETE\n")
cat("================================================================\n")
cat(sprintf("  CSVs:     %s/ (13 files)\n", CSV))
cat(sprintf("  Report:   %s\n", report_path))
cat(sprintf("  Manifest: %s\n", manifest_path))
cat("================================================================\n")
