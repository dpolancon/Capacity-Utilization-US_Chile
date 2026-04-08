# 02_stage1_vecm.R
# Stage 1 VECM — Chilean Import Propensity Cointegration System
# Split-sample estimation: Pre-1973 (ISI) and Post-1973 (neoliberal)
#
# Each sub-sample gets a full Johansen VECM:
#   Pre-1973:  Y = (m, k_ME, nrs, omega)', 1920–1972 (N=53)
#   Post-1973: Y = (m, k_ME, nrs, omega)', 1973–2024 (N=52), dumvar = D1975
#
# State vector: Y = (m, k_ME, nrs, omega)'
# Deterministic: restricted constant (Case 3, ecdet="const")
# Parameterization: spec="transitory"
# VAR lag: K=2, VECM lag L=1
#
# Deliverable: ECT_m saved to data/processed/Chile/ECT_m_stage1.csv
#   with regime-specific cointegrating residuals (1920–2024, N=105).
#
# Authority: Ch2_Outline_DEFINITIVE.md | Notation: CLAUDE.md

library(urca)
library(vars)
library(readr)
library(dplyr)
library(tibble)
library(knitr)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)

OUT  <- file.path(REPO, "output/stage_b/Chile")
CSV  <- file.path(OUT, "csv")
dir.create(CSV, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(REPO, "output/tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(REPO, "output/diagnostics"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(REPO, "data/processed/Chile"), recursive = TRUE, showWarnings = FALSE)

K_use  <- 2     # VAR lag in levels (all criteria selected K=2)
L_vecm <- 1     # VECM lag = K - 1
p      <- 4     # dimension of state vector


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 0 — SETUP AND DATA LOAD                                           ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 0 — SETUP AND DATA LOAD\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

df_raw <- read_csv(file.path(REPO, "data/final/chile_tvecm_panel.csv"),
                   show_col_types = FALSE)

# Full sample — filter only for complete state vector, NO in_sample filter
df_all <- df_raw %>%
  filter(complete.cases(m, k_ME, nrs, omega)) %>%
  arrange(year)

cat(sprintf("Full panel: %d–%d (N=%d)\n", min(df_all$year), max(df_all$year), nrow(df_all)))

# Split at 1973
df_pre  <- df_all %>% filter(year < 1973)
df_post <- df_all %>% filter(year >= 1973)

cat(sprintf("Pre-1973  (ISI):        %d–%d (N=%d)\n",
    min(df_pre$year), max(df_pre$year), nrow(df_pre)))
cat(sprintf("Post-1973 (neoliberal): %d–%d (N=%d)\n",
    min(df_post$year), max(df_post$year), nrow(df_post)))

stopifnot(nrow(df_all) == nrow(df_pre) + nrow(df_post))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  ESTIMATION ENGINE — run_johansen()                                      ║
# ╚════════════════════════════════════════════════════════════════════════════╝

run_johansen <- function(df_sub, label, dumvar = NULL) {

  cat("\n\n")
  cat("╔══════════════════════════════════════════════════════════════════════╗\n")
  cat(sprintf("║  %s\n", label))
  cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

  N <- nrow(df_sub)
  Y <- df_sub %>% select(m, k_ME, nrs, omega) %>% as.matrix()
  rownames(Y) <- df_sub$year

  # --- STEP 0b: Variable summary ---
  cat("Variable summary:\n")
  for (j in 1:p) {
    cat(sprintf("  %-8s: mean=%8.4f  sd=%8.4f  range=[%8.4f, %8.4f]\n",
        colnames(Y)[j], mean(Y[, j]), sd(Y[, j]), min(Y[, j]), max(Y[, j])))
  }

  # --- STEP 1: Lag selection ---
  cat("\n--- Step 1: Lag Selection ---\n")
  vs <- VARselect(y = Y, lag.max = 3, type = "const", exogen = dumvar)
  cat("All criteria:\n")
  print(vs$selection)
  cat("\nFull criteria table:\n")
  print(round(vs$criteria, 3))

  cat(sprintf("Using K=%d (fixed). VECM lag L=%d.\n", K_use, L_vecm))

  # Store lag selection
  lag_df <- data.frame(
    criteria   = names(vs$selection),
    selected_K = as.integer(vs$selection),
    K_used     = K_use,
    stringsAsFactors = FALSE
  )

  # --- STEP 2: Johansen trace test ---
  cat("\n--- Step 2: Johansen Trace Test ---\n")
  jo <- ca.jo(x = Y, type = "trace", ecdet = "const", K = K_use,
              spec = "transitory", dumvar = dumvar)

  r_hat <- 0
  cat(sprintf("  %-8s  %10s  %8s  %8s  %8s  %s\n",
      "H0: r<=", "Trace", "10% CV", "5% CV", "1% CV", "Decision"))
  cat("  ", strrep("-", 70), "\n")

  trace_rows <- list()
  for (r_null in 0:(p - 1)) {
    idx  <- p - r_null
    stat <- jo@teststat[idx]
    cv10 <- jo@cval[idx, 1]; cv05 <- jo@cval[idx, 2]; cv01 <- jo@cval[idx, 3]
    decision <- ifelse(stat > cv05, "REJECT at 5%", "fail to reject")
    if (stat > cv01) decision <- "REJECT at 1%"
    cat(sprintf("  r <= %d    %10.2f  %8.2f  %8.2f  %8.2f  [%s]\n",
        r_null, stat, cv10, cv05, cv01, decision))
    if (stat > cv05 && r_null >= r_hat) r_hat <- r_null + 1
    trace_rows[[r_null + 1]] <- data.frame(
      H0 = sprintf("r <= %d", r_null), trace_stat = stat,
      cv_10 = cv10, cv_05 = cv05, cv_01 = cv01, decision_5pct = decision,
      stringsAsFactors = FALSE)
  }
  trace_df <- do.call(rbind, trace_rows)
  cat(sprintf("\n  Rank: r = %d\n", r_hat))

  # Max-eigenvalue for comparison
  jo_e <- ca.jo(x = Y, type = "eigen", ecdet = "const", K = K_use,
                spec = "transitory", dumvar = dumvar)
  r_eigen <- 0
  eigen_rows <- list()
  for (r_null in 0:(p - 1)) {
    idx <- p - r_null
    stat <- jo_e@teststat[idx]
    cv10 <- jo_e@cval[idx, 1]; cv05 <- jo_e@cval[idx, 2]; cv01 <- jo_e@cval[idx, 3]
    decision <- ifelse(stat > cv05, "REJECT at 5%", "fail to reject")
    if (stat > cv01) decision <- "REJECT at 1%"
    if (stat > cv05 && r_null >= r_eigen) r_eigen <- r_null + 1
    eigen_rows[[r_null + 1]] <- data.frame(
      H0 = sprintf("r <= %d", r_null), eigen_stat = stat,
      cv_10 = cv10, cv_05 = cv05, cv_01 = cv01, decision_5pct = decision,
      stringsAsFactors = FALSE)
  }
  eigen_df <- do.call(rbind, eigen_rows)

  if (r_hat != r_eigen) {
    cat(sprintf("  NOTE: Max-eigen gives r=%d. Preferring trace.\n", r_eigen))
  }

  if (r_hat == 0) {
    cat("\n  *** BLOCKER: r=0. No cointegration found. ***\n")
    return(list(r = 0, label = label, N = N, jo = jo, vs = vs,
                lag_df = lag_df, trace_df = trace_df, eigen_df = eigen_df))
  }

  # --- STEP 3: VECM estimation (r=1) ---
  cat("\n--- Step 3: VECM Estimation (r=1) ---\n")
  vecm <- cajorls(jo, r = 1)
  beta <- vecm$beta
  cat("Beta (normalized on m):\n")
  print(round(beta, 6))

  alpha_raw <- coef(vecm$rlm)["ect1", ]
  alpha <- setNames(as.numeric(alpha_raw), c("m", "k_ME", "nrs", "omega"))
  cat("\nAlpha:\n")
  print(round(alpha, 6))

  # --- STEP 4: Sign check ---
  zeta_1 <- -beta[2, 1]   # k_ME
  zeta_2 <- -beta[3, 1]   # nrs
  zeta_3 <- -beta[4, 1]   # omega
  zeta_0 <- -beta[5, 1]   # constant

  cat(sprintf("\nLong-run: m = %.4f + %.4f*k_ME + %.4f*nrs + %.4f*omega\n",
      zeta_0, zeta_1, zeta_2, zeta_3))

  if (zeta_1 > 0) {
    cat("  zeta_1 > 0 — Tavares channel confirmed.\n")
  } else {
    cat("  WARNING: zeta_1 < 0 — Tavares channel REVERSED.\n")
  }

  cat(sprintf("  alpha_m = %+.4f %s\n", alpha["m"],
      ifelse(alpha["m"] < 0, "— error-corrects", "— NOT error-correcting")))

  # Standardized impacts
  sd_vars <- apply(Y, 2, sd)
  std_impact <- abs(c(zeta_1, zeta_2, zeta_3)) * sd_vars[c("k_ME", "nrs", "omega")]

  # --- STEP 5: Weak exogeneity ---
  cat("\n--- Step 5: Weak Exogeneity ---\n")
  we_results <- data.frame(variable = character(), LR_stat = numeric(),
                           p_value = numeric(), decision = character(),
                           stringsAsFactors = FALSE)
  for (j in 1:p) {
    A_j <- matrix(0, nrow = p, ncol = p - 1)
    col_idx <- 1
    for (i in 1:p) { if (i != j) { A_j[i, col_idx] <- 1; col_idx <- col_idx + 1 } }
    tryCatch({
      we <- alrtest(jo, A = A_j, r = 1)
      lr <- we@teststat; pv <- we@pval[1]
      dec <- ifelse(pv > 0.05, "weakly exogenous", "NOT weakly exogenous")
      cat(sprintf("  %s: LR=%.3f, p=%.4f  [%s]\n", colnames(Y)[j], lr, pv, dec))
      we_results <- rbind(we_results, data.frame(
        variable = colnames(Y)[j], LR_stat = lr, p_value = pv, decision = dec,
        stringsAsFactors = FALSE))
    }, error = function(e) {
      cat(sprintf("  %s: alrtest failed — %s\n", colnames(Y)[j], e$message))
      we_results <<- rbind(we_results, data.frame(
        variable = colnames(Y)[j], LR_stat = NA, p_value = NA, decision = "test failed",
        stringsAsFactors = FALSE))
    })
  }

  # --- STEP 6: Extract ECT ---
  Y_ext <- cbind(Y, constant = 1)
  ECT <- as.numeric(Y_ext %*% beta[, 1])

  cat(sprintf("\n--- Step 6: ECT ---\n"))
  cat(sprintf("  mean=%+.6f  sd=%.4f  range=[%.4f, %.4f]\n",
      mean(ECT), sd(ECT), min(ECT), max(ECT)))

  adf_ect <- ur.df(ECT, type = "drift", lags = 1)
  cat(sprintf("  ADF tau=%.4f %s\n", adf_ect@teststat[1],
      ifelse(adf_ect@teststat[1] < -2.89, "— stationary", "— WARNING: non-stationary")))

  # --- STEP 7: Diagnostics ---
  cat("\n--- Step 7: Diagnostics ---\n")
  vecm_var <- vec2var(jo, r = 1)

  pt <- serial.test(vecm_var, lags.pt = 10, type = "PT.adjusted")
  cat(sprintf("  Portmanteau: chi2=%.2f, p=%.4f %s\n",
      pt$serial$statistic, pt$serial$p.value,
      ifelse(pt$serial$p.value > 0.05, "OK", "FAIL")))

  arch_t <- arch.test(vecm_var, lags.multi = 5)
  arch_pval <- as.numeric(arch_t$arch.mul$p.value)
  cat(sprintf("  ARCH-LM:     chi2=%.2f, p=%.4f %s\n",
      as.numeric(arch_t$arch.mul$statistic), arch_pval,
      ifelse(arch_pval > 0.05, "OK", "FAIL")))

  norm_t <- normality.test(vecm_var, multivariate.only = TRUE)
  cat(sprintf("  Jarque-Bera: chi2=%.2f, p=%.4f %s\n",
      norm_t$jb.mul$JB$statistic, norm_t$jb.mul$JB$p.value,
      ifelse(norm_t$jb.mul$JB$p.value > 0.05, "OK", "FAIL")))

  # CUSUM on m-equation
  cusum_stat <- NA; cusum_pval <- NA
  tryCatch({
    library(strucchange)
    m_resid <- residuals(vecm$rlm)[, "m.d"]
    cusum <- efp(m_resid ~ 1, type = "OLS-CUSUM")
    sc_test <- sctest(cusum)
    cusum_stat <- sc_test$statistic; cusum_pval <- sc_test$p.value
    cat(sprintf("  CUSUM (m):   stat=%.4f, p=%.4f %s\n",
        cusum_stat, cusum_pval,
        ifelse(cusum_pval > 0.05, "OK — stable", "FAIL — instability")))
  }, error = function(e) {
    cat(sprintf("  CUSUM: skipped — %s\n", e$message))
  })

  # Diagnostics df
  diag_df <- data.frame(
    test = c("Portmanteau", "ARCH-LM", "Jarque-Bera"),
    statistic = c(as.numeric(pt$serial$statistic),
                  as.numeric(arch_t$arch.mul$statistic),
                  as.numeric(norm_t$jb.mul$JB$statistic)),
    df = c(as.numeric(pt$serial$parameter[1]),
           as.numeric(arch_t$arch.mul$parameter[1]),
           as.numeric(norm_t$jb.mul$JB$parameter[1])),
    p_value = c(as.numeric(pt$serial$p.value), arch_pval,
                as.numeric(norm_t$jb.mul$JB$p.value)),
    decision = c(
      ifelse(pt$serial$p.value > 0.05, "OK", "FAIL"),
      ifelse(arch_pval > 0.05, "OK", "FAIL"),
      ifelse(norm_t$jb.mul$JB$p.value > 0.05, "OK", "FAIL")
    ),
    stringsAsFactors = FALSE
  )
  if (!is.na(cusum_pval)) {
    diag_df <- rbind(diag_df, data.frame(
      test = "CUSUM (m eq.)", statistic = as.numeric(cusum_stat),
      df = NA, p_value = as.numeric(cusum_pval),
      decision = ifelse(cusum_pval > 0.05, "OK", "FAIL"),
      stringsAsFactors = FALSE))
  }

  # Short-run coefficients
  sr_list <- list()
  for (eq_name in colnames(residuals(vecm$rlm))) {
    sm <- summary(vecm$rlm)[[paste0("Response ", eq_name)]]
    cf <- as.data.frame(sm$coefficients)
    cf$equation <- eq_name
    cf$term <- rownames(cf)
    sr_list[[eq_name]] <- cf
  }
  sr_df <- do.call(rbind, sr_list)
  rownames(sr_df) <- NULL
  names(sr_df) <- c("estimate", "std_error", "t_value", "p_value", "equation", "term")
  sr_df <- sr_df[, c("equation", "term", "estimate", "std_error", "t_value", "p_value")]

  # Print import equation
  cat("\n--- Import equation (m.d) ---\n")
  print(summary(vecm$rlm)$"Response m.d")

  # Return all objects
  list(
    label = label, N = N, r = r_hat,
    jo = jo, jo_e = jo_e, vecm = vecm, vecm_var = vecm_var,
    beta = beta, alpha = alpha,
    zeta = c(zeta_0 = zeta_0, zeta_1 = zeta_1, zeta_2 = zeta_2, zeta_3 = zeta_3),
    sd_vars = sd_vars, std_impact = std_impact,
    ECT = ECT, years = df_sub$year,
    we = we_results, lag_df = lag_df,
    trace_df = trace_df, eigen_df = eigen_df,
    diag_df = diag_df, sr_df = sr_df,
    diag_pt = as.numeric(pt$serial$p.value),
    diag_arch = arch_pval,
    diag_jb = as.numeric(norm_t$jb.mul$JB$p.value),
    adf_tau = adf_ect@teststat[1]
  )
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 1–7: PRE-1973 (ISI ERA)                                           ║
# ╚════════════════════════════════════════════════════════════════════════════╝

res_pre <- run_johansen(df_pre, "PRE-1973 — ISI ERA (1920–1972)")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 1–7: POST-1973 (NEOLIBERAL ERA)                                   ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# D1975 impulse dummy for post-1973 sample
D_post <- df_post %>% select(D1975) %>% as.matrix()

res_post <- run_johansen(df_post, "POST-1973 — NEOLIBERAL ERA (1973–2024)", dumvar = D_post)


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 8 — COMBINE ECT_m AND CROSSWALK                                   ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 8 — COMBINE ECT_m AND CROSSWALK\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Build combined ECT_m: regime-appropriate cointegrating residual
ect_df <- rbind(
  data.frame(year = res_pre$years,  ECT_m = res_pre$ECT,  regime = "pre_1973"),
  data.frame(year = res_post$years, ECT_m = res_post$ECT, regime = "post_1973")
) %>% arrange(year)

ect_path <- file.path(REPO, "data/processed/Chile/ECT_m_stage1.csv")
write_csv(ect_df, ect_path)
cat(sprintf("ECT_m saved to: %s\n", ect_path))
cat(sprintf("Rows: %d | Years: %d–%d\n", nrow(ect_df), min(ect_df$year), max(ect_df$year)))

cat("\nPre-1973 ECT_m:\n")
cat(sprintf("  mean=%+.4f  sd=%.4f  range=[%.4f, %.4f]\n",
    mean(res_pre$ECT), sd(res_pre$ECT), min(res_pre$ECT), max(res_pre$ECT)))
cat("Post-1973 ECT_m:\n")
cat(sprintf("  mean=%+.4f  sd=%.4f  range=[%.4f, %.4f]\n",
    mean(res_post$ECT), sd(res_post$ECT), min(res_post$ECT), max(res_post$ECT)))


# ══════════════════════════════════════════════════════════════════════════════
# CROSSWALK SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

cat("\n\n")
cat("================================================================\n")
cat("    STAGE 1 VECM — SPLIT-SAMPLE CROSSWALK\n")
cat("================================================================\n\n")

format_regime <- function(res) {
  lines <- c(
    sprintf("### %s", res$label),
    sprintf("- Sample: N=%d | VAR lag K=%d | Rank r=%d", res$N, K_use, res$r),
    ""
  )
  if (res$r == 0) {
    lines <- c(lines, "**BLOCKER: No cointegration found.**", "")
    return(lines)
  }
  z <- res$zeta; a <- res$alpha
  lines <- c(lines,
    "#### Cointegrating Vector (normalized on m)",
    sprintf("$$m = %.4f + %.4f \\cdot k^{ME} + %.4f \\cdot nrs + %.4f \\cdot \\omega$$",
            z["zeta_0"], z["zeta_1"], z["zeta_2"], z["zeta_3"]),
    "",
    "| Coefficient | Value | Interpretation |",
    "|-------------|-------|----------------|",
    sprintf("| zeta_1 (k_ME) | %+.4f | %s |", z["zeta_1"],
            ifelse(z["zeta_1"] > 0, "Tavares confirmed", "Tavares REVERSED")),
    sprintf("| zeta_2 (nrs) | %+.4f | Kaldor/Palma-Marcel |", z["zeta_2"]),
    sprintf("| zeta_3 (omega) | %+.4f | Wage share |", z["zeta_3"]),
    sprintf("| zeta_0 (const) | %+.4f | |", z["zeta_0"]),
    "",
    "#### Loading Matrix",
    "| Variable | alpha | |",
    "|----------|-------|---|",
    sprintf("| m | %+.4f | %s |", a["m"],
            ifelse(a["m"] < 0, "error-corrects", "NOT error-correcting")),
    sprintf("| k_ME | %+.4f | |", a["k_ME"]),
    sprintf("| nrs | %+.4f | |", a["nrs"]),
    sprintf("| omega | %+.4f | |", a["omega"]),
    ""
  )
  if (nrow(res$we) > 0) {
    lines <- c(lines,
      "#### Weak Exogeneity",
      "| Variable | LR | p | Decision |",
      "|----------|-----|---|----------|")
    for (i in 1:nrow(res$we)) {
      lines <- c(lines, sprintf("| %s | %.3f | %.4f | %s |",
          res$we$variable[i], res$we$LR_stat[i], res$we$p_value[i], res$we$decision[i]))
    }
    lines <- c(lines, "")
  }
  lines <- c(lines,
    "#### Diagnostics",
    sprintf("- Portmanteau: p=%.4f %s", res$diag_pt,
            ifelse(res$diag_pt > 0.05, "OK", "FAIL")),
    sprintf("- ARCH-LM:     p=%.4f %s", res$diag_arch,
            ifelse(res$diag_arch > 0.05, "OK", "FAIL")),
    sprintf("- Jarque-Bera: p=%.4f %s", res$diag_jb,
            ifelse(res$diag_jb > 0.05, "OK", "FAIL")),
    sprintf("- ADF on ECT:  tau=%.4f %s", res$adf_tau,
            ifelse(res$adf_tau < -2.89, "stationary", "WARNING")),
    "",
    "#### ECT Summary",
    sprintf("- mean=%+.4f  sd=%.4f  range=[%.4f, %.4f]",
            mean(res$ECT), sd(res$ECT), min(res$ECT), max(res$ECT)),
    ""
  )
  lines
}

crosswalk_lines <- c(
  "# Stage 1 VECM — Split-Sample Estimation Crosswalk",
  sprintf("**Date:** %s | **Country:** Chile", Sys.Date()),
  "",
  "## Specification",
  "- State vector: Y = (m, k_ME, nrs, omega)'",
  "- Deterministic: restricted constant (Case 3, ecdet='const')",
  "- Parameterization: spec='transitory'",
  sprintf("- VAR lag K=%d (fixed) | VECM lag L=%d", K_use, L_vecm),
  "- Split at 1973. Post-1973 includes D1975 as unrestricted impulse dummy.",
  "",
  format_regime(res_pre),
  "---", "",
  format_regime(res_post),
  "---", "",
  "## Structural Comparison",
  "| Parameter | Pre-1973 (ISI) | Post-1973 (neoliberal) |",
  "|-----------|---------------|----------------------|"
)

if (res_pre$r > 0 && res_post$r > 0) {
  zp <- res_pre$zeta; zq <- res_post$zeta
  ap <- res_pre$alpha; aq <- res_post$alpha
  crosswalk_lines <- c(crosswalk_lines,
    sprintf("| zeta_1 (k_ME) | %+.4f | %+.4f |", zp["zeta_1"], zq["zeta_1"]),
    sprintf("| zeta_2 (nrs) | %+.4f | %+.4f |", zp["zeta_2"], zq["zeta_2"]),
    sprintf("| zeta_3 (omega) | %+.4f | %+.4f |", zp["zeta_3"], zq["zeta_3"]),
    sprintf("| zeta_0 (const) | %+.4f | %+.4f |", zp["zeta_0"], zq["zeta_0"]),
    sprintf("| alpha_m | %+.4f | %+.4f |", ap["m"], aq["m"]),
    sprintf("| Portmanteau p | %.4f | %.4f |", res_pre$diag_pt, res_post$diag_pt),
    sprintf("| ARCH p | %.4f | %.4f |", res_pre$diag_arch, res_post$diag_arch),
    sprintf("| JB p | %.4f | %.4f |", res_pre$diag_jb, res_post$diag_jb)
  )
}

crosswalk_lines <- c(crosswalk_lines, "",
  sprintf("## ECT_m: `data/processed/Chile/ECT_m_stage1.csv`"),
  sprintf("- %d observations (%d–%d)", nrow(ect_df), min(ect_df$year), max(ect_df$year)),
  "- Column `regime` identifies which system generated each ECT value",
  "",
  "---",
  sprintf("*Generated: %s | Authority: Ch2_Outline_DEFINITIVE.md*", Sys.Date())
)

# Print to console
cat(paste(crosswalk_lines, collapse = "\n"))
cat("\n")

crosswalk_path <- file.path(REPO, "output/diagnostics/stage1_vecm_crosswalk.md")
writeLines(crosswalk_lines, crosswalk_path)
cat(sprintf("\nCrosswalk saved to: %s\n", crosswalk_path))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 9 — BOOTSTRAP CONFIDENCE INTERVALS (n_boot=999)                   ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 9 — BOOTSTRAP CONFIDENCE INTERVALS (n_boot=999)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

n_boot <- 999
set.seed(42)

boot_regime <- function(res, label, dumvar_full = NULL) {

  cat(sprintf("Bootstrap %s ...\n", label))

  jo  <- res$jo
  vec <- res$vecm
  var_rep <- res$vecm_var

  resid_mat <- residuals(vec$rlm)
  T_eff <- nrow(resid_mat)

  A_mats  <- var_rep$A
  det_coef <- var_rep$deterministic

  N_full <- res$N
  Y_orig <- cbind(res$jo@x)  # original Y used by ca.jo

  # Effective dummies (rows K_use+1 : N)
  if (!is.null(dumvar_full)) {
    dum_eff <- dumvar_full[(K_use + 1):N_full, , drop = FALSE]
  } else {
    dum_eff <- NULL
  }

  boot_betas  <- matrix(NA_real_, nrow = n_boot, ncol = 5)
  colnames(boot_betas) <- c("m", "k_ME", "nrs", "omega", "const")
  boot_alphas <- matrix(NA_real_, nrow = n_boot, ncol = p)
  colnames(boot_alphas) <- c("m", "k_ME", "nrs", "omega")
  n_fail <- 0

  for (b in 1:n_boot) {
    tryCatch({
      idx <- sample(1:T_eff, T_eff, replace = TRUE)
      resid_star <- resid_mat[idx, ]

      Y_star <- matrix(NA_real_, nrow = N_full, ncol = p)
      colnames(Y_star) <- colnames(Y_orig)
      Y_star[1:K_use, ] <- Y_orig[1:K_use, ]

      for (t_idx in 1:T_eff) {
        t_abs <- K_use + t_idx
        y_hat <- rep(0, p)
        for (lag in 1:K_use) {
          y_hat <- y_hat + as.numeric(A_mats[[lag]] %*% Y_star[t_abs - lag, ])
        }
        det_vec <- 1  # constant
        if (!is.null(dum_eff) && t_idx <= nrow(dum_eff)) {
          det_vec <- c(det_vec, dum_eff[t_idx, ])
        }
        y_hat <- y_hat + as.numeric(det_coef %*% det_vec)
        Y_star[t_abs, ] <- y_hat + resid_star[t_idx, ]
      }

      jo_b <- ca.jo(x = Y_star, type = "trace", ecdet = "const",
                    K = K_use, spec = "transitory", dumvar = dumvar_full)
      vecm_b <- cajorls(jo_b, r = 1)
      boot_betas[b, ]  <- vecm_b$beta[, 1]
      boot_alphas[b, ] <- as.numeric(coef(vecm_b$rlm)["ect1", ])

    }, error = function(e) {
      n_fail <<- n_fail + 1
    })

    if (b %% 200 == 0) cat(sprintf("  %d/%d (failures: %d)\n", b, n_boot, n_fail))
  }

  n_success <- sum(!is.na(boot_betas[, 1]))
  cat(sprintf("  Done: %d successes, %d failures (%.1f%%)\n",
      n_success, n_fail, 100 * n_fail / n_boot))

  # Normalize and compute zeta
  boot_norm <- boot_betas[!is.na(boot_betas[, 1]), , drop = FALSE]
  for (i in 1:nrow(boot_norm)) {
    boot_norm[i, ] <- boot_norm[i, ] / boot_norm[i, 1]
  }
  boot_zeta <- cbind(
    zeta_1 = -boot_norm[, 2], zeta_2 = -boot_norm[, 3],
    zeta_3 = -boot_norm[, 4], zeta_0 = -boot_norm[, 5]
  )

  ci_90 <- apply(boot_zeta, 2, quantile, probs = c(0.05, 0.95), na.rm = TRUE)
  ci_95 <- apply(boot_zeta, 2, quantile, probs = c(0.025, 0.975), na.rm = TRUE)

  # Alpha CIs
  boot_alpha_clean <- boot_alphas[!is.na(boot_alphas[, 1]), , drop = FALSE]
  alpha_ci_90 <- apply(boot_alpha_clean, 2, quantile, probs = c(0.05, 0.95), na.rm = TRUE)
  alpha_ci_95 <- apply(boot_alpha_clean, 2, quantile, probs = c(0.025, 0.975), na.rm = TRUE)

  list(ci_90 = ci_90, ci_95 = ci_95,
       alpha_ci_90 = alpha_ci_90, alpha_ci_95 = alpha_ci_95,
       n_success = n_success, n_fail = n_fail)
}

# Pre-1973 bootstrap (no dummies)
boot_pre <- boot_regime(res_pre, "Pre-1973", dumvar_full = NULL)

# Post-1973 bootstrap (D1975 dummy)
boot_post <- boot_regime(res_post, "Post-1973", dumvar_full = D_post)

# Report
param_names <- c("zeta_1 (k_ME)", "zeta_2 (nrs)", "zeta_3 (omega)", "zeta_0 (const)")
zeta_cols   <- c("zeta_1", "zeta_2", "zeta_3", "zeta_0")

for (regime_label in c("Pre-1973", "Post-1973")) {
  bt <- if (regime_label == "Pre-1973") boot_pre else boot_post
  zz <- if (regime_label == "Pre-1973") res_pre$zeta else res_post$zeta
  point_vals <- c(zz["zeta_1"], zz["zeta_2"], zz["zeta_3"], zz["zeta_0"])

  cat(sprintf("\n%s bootstrap CIs (%d successes):\n", regime_label, bt$n_success))
  cat(sprintf("  %-20s  %10s  %18s  %18s\n", "Parameter", "Estimate", "90% CI", "95% CI"))
  cat("  ", strrep("-", 72), "\n")
  for (j in 1:4) {
    cat(sprintf("  %-20s  %+10.4f  [%+7.4f, %+7.4f]  [%+7.4f, %+7.4f]\n",
        param_names[j], point_vals[j],
        bt$ci_90[1, zeta_cols[j]], bt$ci_90[2, zeta_cols[j]],
        bt$ci_95[1, zeta_cols[j]], bt$ci_95[2, zeta_cols[j]]))
  }
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 10 — FINAL DELIVERY                                               ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 10 — FINAL DELIVERY\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

save_csv <- function(df_out, name) {
  path <- file.path(CSV, name)
  write_csv(df_out, path)
  cat(sprintf("  saved %s (%d rows)\n", name, nrow(df_out)))
}

# --- Combine regime results into CSVs ---

# ECT
save_csv(ect_df, "stage1_ECT_m.csv")

# Cointegrating vectors
cv_df <- rbind(
  data.frame(regime = "pre_1973",
    parameter  = c("zeta_0 (const)", "zeta_1 (k_ME)", "zeta_2 (nrs)", "zeta_3 (omega)"),
    coefficient = c(res_pre$zeta["zeta_0"], res_pre$zeta["zeta_1"],
                    res_pre$zeta["zeta_2"], res_pre$zeta["zeta_3"]),
    sd_regressor = c(NA, res_pre$sd_vars["k_ME"], res_pre$sd_vars["nrs"], res_pre$sd_vars["omega"]),
    standardized_impact = c(NA, res_pre$std_impact[1], res_pre$std_impact[2], res_pre$std_impact[3]),
    stringsAsFactors = FALSE),
  data.frame(regime = "post_1973",
    parameter  = c("zeta_0 (const)", "zeta_1 (k_ME)", "zeta_2 (nrs)", "zeta_3 (omega)"),
    coefficient = c(res_post$zeta["zeta_0"], res_post$zeta["zeta_1"],
                    res_post$zeta["zeta_2"], res_post$zeta["zeta_3"]),
    sd_regressor = c(NA, res_post$sd_vars["k_ME"], res_post$sd_vars["nrs"], res_post$sd_vars["omega"]),
    standardized_impact = c(NA, res_post$std_impact[1], res_post$std_impact[2], res_post$std_impact[3]),
    stringsAsFactors = FALSE)
)
rownames(cv_df) <- NULL
save_csv(cv_df, "stage1_cointegrating_vectors.csv")

# Alpha loadings
alpha_df <- rbind(
  data.frame(regime = "pre_1973",  variable = names(res_pre$alpha),  alpha = as.numeric(res_pre$alpha),  stringsAsFactors = FALSE),
  data.frame(regime = "post_1973", variable = names(res_post$alpha), alpha = as.numeric(res_post$alpha), stringsAsFactors = FALSE)
)
save_csv(alpha_df, "stage1_alpha_loadings.csv")

# Weak exogeneity
we_df <- rbind(
  cbind(regime = "pre_1973", res_pre$we),
  cbind(regime = "post_1973", res_post$we)
)
save_csv(we_df, "stage1_weak_exogeneity.csv")

# Diagnostics
diag_all <- rbind(
  cbind(regime = "pre_1973", res_pre$diag_df),
  cbind(regime = "post_1973", res_post$diag_df)
)
save_csv(diag_all, "stage1_diagnostics.csv")

# Lag selection
lag_all <- rbind(
  cbind(regime = "pre_1973", res_pre$lag_df),
  cbind(regime = "post_1973", res_post$lag_df)
)
save_csv(lag_all, "stage1_lag_selection.csv")

# Johansen trace
trace_all <- rbind(
  cbind(regime = "pre_1973", res_pre$trace_df),
  cbind(regime = "post_1973", res_post$trace_df)
)
save_csv(trace_all, "stage1_johansen_trace.csv")

# Johansen max-eigenvalue
eigen_all <- rbind(
  cbind(regime = "pre_1973", res_pre$eigen_df),
  cbind(regime = "post_1973", res_post$eigen_df)
)
save_csv(eigen_all, "stage1_johansen_maxeigen.csv")

# Short-run coefficients
sr_all <- rbind(
  cbind(regime = "pre_1973", res_pre$sr_df),
  cbind(regime = "post_1973", res_post$sr_df)
)
save_csv(sr_all, "stage1_short_run_coefficients.csv")

# Eigenvalues
eig_all <- rbind(
  data.frame(regime = "pre_1973",  eigenvalue_index = 1:length(res_pre$jo@lambda),
             eigenvalue = res_pre$jo@lambda, stringsAsFactors = FALSE),
  data.frame(regime = "post_1973", eigenvalue_index = 1:length(res_post$jo@lambda),
             eigenvalue = res_post$jo@lambda, stringsAsFactors = FALSE)
)
save_csv(eig_all, "stage1_eigenvalues.csv")

# Variable summary
Y_pre  <- df_pre  %>% select(m, k_ME, nrs, omega) %>% as.matrix()
Y_post <- df_post %>% select(m, k_ME, nrs, omega) %>% as.matrix()
var_sum <- rbind(
  data.frame(regime = "pre_1973", variable = colnames(Y_pre),
    mean = colMeans(Y_pre), sd = apply(Y_pre, 2, sd),
    min = apply(Y_pre, 2, min), max = apply(Y_pre, 2, max),
    stringsAsFactors = FALSE),
  data.frame(regime = "post_1973", variable = colnames(Y_post),
    mean = colMeans(Y_post), sd = apply(Y_post, 2, sd),
    min = apply(Y_post, 2, min), max = apply(Y_post, 2, max),
    stringsAsFactors = FALSE)
)
rownames(var_sum) <- NULL
save_csv(var_sum, "stage1_variable_summary.csv")

# Correlation matrices
cor_pre  <- as.data.frame(cor(Y_pre));  cor_pre$variable  <- rownames(cor_pre);  cor_pre$regime  <- "pre_1973"
cor_post <- as.data.frame(cor(Y_post)); cor_post$variable <- rownames(cor_post); cor_post$regime <- "post_1973"
cor_all <- rbind(cor_pre, cor_post)[, c("regime", "variable", "m", "k_ME", "nrs", "omega")]
rownames(cor_all) <- NULL
save_csv(cor_all, "stage1_correlation_matrices.csv")

# Standardized impacts
impact_df <- data.frame(
  channel = c("k_ME (Tavares)", "nrs (Kaldor/Palma-Marcel)", "omega (wage share)"),
  coeff_pre = c(res_pre$zeta["zeta_1"], res_pre$zeta["zeta_2"], res_pre$zeta["zeta_3"]),
  sd_pre = res_pre$sd_vars[c("k_ME", "nrs", "omega")],
  impact_pre = res_pre$std_impact,
  coeff_post = c(res_post$zeta["zeta_1"], res_post$zeta["zeta_2"], res_post$zeta["zeta_3"]),
  sd_post = res_post$sd_vars[c("k_ME", "nrs", "omega")],
  impact_post = res_post$std_impact,
  stringsAsFactors = FALSE
)
rownames(impact_df) <- NULL
save_csv(impact_df, "stage1_standardized_impacts.csv")

# Bootstrap CIs
make_boot_ci_df <- function(bt, zz, regime_label) {
  point_vals <- c(zz["zeta_1"], zz["zeta_2"], zz["zeta_3"], zz["zeta_0"])
  data.frame(
    regime = regime_label,
    parameter = param_names,
    estimate = as.numeric(point_vals),
    ci_90_lo = as.numeric(bt$ci_90[1, zeta_cols]),
    ci_90_hi = as.numeric(bt$ci_90[2, zeta_cols]),
    ci_95_lo = as.numeric(bt$ci_95[1, zeta_cols]),
    ci_95_hi = as.numeric(bt$ci_95[2, zeta_cols]),
    n_boot = bt$n_success,
    stringsAsFactors = FALSE
  )
}
boot_ci_df <- rbind(
  make_boot_ci_df(boot_pre,  res_pre$zeta,  "pre_1973"),
  make_boot_ci_df(boot_post, res_post$zeta, "post_1973")
)
rownames(boot_ci_df) <- NULL
save_csv(boot_ci_df, "stage1_bootstrap_ci.csv")

# Alpha bootstrap CIs
make_alpha_ci_df <- function(bt, alpha_vec, regime_label) {
  data.frame(
    regime = regime_label,
    variable = names(alpha_vec),
    alpha = as.numeric(alpha_vec),
    ci_90_lo = as.numeric(bt$alpha_ci_90[1, ]),
    ci_90_hi = as.numeric(bt$alpha_ci_90[2, ]),
    ci_95_lo = as.numeric(bt$alpha_ci_95[1, ]),
    ci_95_hi = as.numeric(bt$alpha_ci_95[2, ]),
    stringsAsFactors = FALSE
  )
}
alpha_ci_df <- rbind(
  make_alpha_ci_df(boot_pre,  res_pre$alpha,  "pre_1973"),
  make_alpha_ci_df(boot_post, res_post$alpha, "post_1973")
)
rownames(alpha_ci_df) <- NULL
save_csv(alpha_ci_df, "stage1_alpha_bootstrap_ci.csv")


# --- LaTeX table ---
cat("\nGenerating LaTeX table...\n")

tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Stage~1 Cointegrating Vector --- Import Propensity, Split-Sample}",
  "\\label{tab:stage1_cv1}",
  "\\begin{tabular}{lcccc}",
  "\\toprule",
  " & \\multicolumn{2}{c}{Pre-1973 (ISI)} & \\multicolumn{2}{c}{Post-1973 (Neoliberal)} \\\\",
  "\\cmidrule(lr){2-3} \\cmidrule(lr){4-5}",
  "Parameter & Estimate & 95\\% CI & Estimate & 95\\% CI \\\\",
  "\\midrule"
)

param_tex <- c("\\zeta_0", "\\zeta_1\\;(k^{ME})", "\\zeta_2\\;(nrs)", "\\zeta_3\\;(\\omega)")
zp <- res_pre$zeta; zq <- res_post$zeta
for (j in 1:4) {
  zeta_name <- c("zeta_0", "zeta_1", "zeta_2", "zeta_3")[j]
  pv_pre  <- c(zp["zeta_0"], zp["zeta_1"], zp["zeta_2"], zp["zeta_3"])[j]
  pv_post <- c(zq["zeta_0"], zq["zeta_1"], zq["zeta_2"], zq["zeta_3"])[j]
  tex_lines <- c(tex_lines, sprintf(
    "$%s$ & $%.4f$ & $[%.3f,\\; %.3f]$ & $%.4f$ & $[%.3f,\\; %.3f]$ \\\\",
    param_tex[j],
    pv_pre, boot_pre$ci_95[1, zeta_name], boot_pre$ci_95[2, zeta_name],
    pv_post, boot_post$ci_95[1, zeta_name], boot_post$ci_95[2, zeta_name]
  ))
}

ap <- res_pre$alpha; aq <- res_post$alpha
tex_lines <- c(tex_lines,
  "\\midrule",
  sprintf("$\\alpha_m$ & $%.4f$ & $[%.3f,\\; %.3f]$ & $%.4f$ & $[%.3f,\\; %.3f]$ \\\\",
    ap["m"], boot_pre$alpha_ci_95[1, "m"], boot_pre$alpha_ci_95[2, "m"],
    aq["m"], boot_post$alpha_ci_95[1, "m"], boot_post$alpha_ci_95[2, "m"]),
  sprintf("Rank $r$ & %d & & %d & \\\\", res_pre$r, res_post$r),
  sprintf("$N$ & %d & & %d & \\\\", res_pre$N, res_post$N),
  sprintf("$K$ (VAR lag) & %d & & %d & \\\\", K_use, K_use),
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.5em}",
  "\\begin{minipage}{0.95\\textwidth}",
  "\\footnotesize",
  sprintf("\\textit{Notes:} Independent Johansen VECM (Case~3, restricted constant, \\texttt{spec=transitory}) on $Y_t = (m_t, k_t^{ME}, nrs_t, \\omega_t)'$. Sample split at 1973 (Chilean coup). Pre-1973: %d--%d (N=%d). Post-1973: %d--%d (N=%d), with $D_{1975}$ as unrestricted impulse dummy. 95\\%% CIs from %d recursive-bootstrap replications.",
    min(df_pre$year), max(df_pre$year), nrow(df_pre),
    min(df_post$year), max(df_post$year), nrow(df_post),
    min(boot_pre$n_success, boot_post$n_success)),
  "\\end{minipage}",
  "\\end{table}"
)

tex_path <- file.path(REPO, "output/tables/stage1_cointegrating_vector.tex")
writeLines(tex_lines, tex_path)
cat(sprintf("LaTeX table saved to: %s\n", tex_path))


# ══════════════════════════════════════════════════════════════════════════════
# FINAL CROSSWALK PRINTOUT
# ══════════════════════════════════════════════════════════════════════════════

cat("\n\n")
cat("================================================================\n")
cat("    STAGE 1 VECM — FINAL CROSSWALK (SPLIT-SAMPLE)\n")
cat("================================================================\n\n")

cat(sprintf("Pre-1973:  %d–%d (N=%d) | r=%d\n", min(df_pre$year), max(df_pre$year), nrow(df_pre), res_pre$r))
cat(sprintf("Post-1973: %d–%d (N=%d) | r=%d | D1975 unrestricted\n",
    min(df_post$year), max(df_post$year), nrow(df_post), res_post$r))
cat(sprintf("VAR lag K=%d | VECM lag L=%d | spec=transitory | Case 3\n\n", K_use, L_vecm))

for (regime_label in c("Pre-1973", "Post-1973")) {
  res <- if (regime_label == "Pre-1973") res_pre else res_post
  bt  <- if (regime_label == "Pre-1973") boot_pre else boot_post
  z <- res$zeta; a <- res$alpha

  cat(sprintf("--- %s ---\n", regime_label))
  cat(sprintf("  m = %.4f + %.4f*k_ME + %.4f*nrs + %.4f*omega\n",
      z["zeta_0"], z["zeta_1"], z["zeta_2"], z["zeta_3"]))

  point_vals <- c(z["zeta_1"], z["zeta_2"], z["zeta_3"], z["zeta_0"])
  cat(sprintf("  %-20s  %10s  %18s\n", "Parameter", "Estimate", "95% CI"))
  for (j in 1:4) {
    cat(sprintf("  %-20s  %+10.4f  [%+7.4f, %+7.4f]\n",
        param_names[j], point_vals[j],
        bt$ci_95[1, zeta_cols[j]], bt$ci_95[2, zeta_cols[j]]))
  }

  cat(sprintf("  alpha_m = %+.4f  [95%%: %+.4f, %+.4f] — %s\n",
      a["m"], bt$alpha_ci_95[1, "m"], bt$alpha_ci_95[2, "m"],
      ifelse(a["m"] < 0, "error-corrects", "NOT error-correcting")))

  cat("  Diagnostics:")
  for (i in 1:nrow(res$diag_df)) {
    cat(sprintf(" %s p=%.3f[%s]", res$diag_df$test[i], res$diag_df$p_value[i], res$diag_df$decision[i]))
  }
  cat(sprintf("\n  ADF(ECT) tau=%.4f\n\n", res$adf_tau))
}

cat(sprintf("ECT_m: %d obs (%d–%d) → data/processed/Chile/ECT_m_stage1.csv\n",
    nrow(ect_df), min(ect_df$year), max(ect_df$year)))
cat(sprintf("CSVs: output/stage_b/Chile/csv/ (15 files)\n"))
cat(sprintf("Bootstrap: Pre=%d/%d, Post=%d/%d successful\n",
    boot_pre$n_success, n_boot, boot_post$n_success, n_boot))
cat("================================================================\n")
