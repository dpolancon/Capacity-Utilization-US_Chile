# 02_stage1_vecm.R
# Stage 1 VECM — Chilean Import Propensity Cointegration System
# Split-sample estimation: Pre-1973 (ISI) and Post-1973 (neoliberal)
#
# Each sub-sample gets a full Johansen VECM:
#   Pre-1973:  Y = (m, k_ME, nrs, omega)',  1920–1972 (N=53)
#   Post-1973: Y = (m, k_ME, nrs, omega)',  1973–2024 (N=52), dumvar = D1975
#
# Deliverable: ECT_m saved to data/processed/chile/ECT_m_stage1.csv
#   with regime-specific cointegrating residuals.
#
# Authority: Ch2_Outline_DEFINITIVE.md | Notation: CLAUDE.md

library(urca)
library(vars)
library(readr)
library(dplyr)
library(tibble)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)

dir.create(file.path(REPO, "output/tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(REPO, "output/diagnostics"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(REPO, "data/processed/chile"), recursive = TRUE, showWarnings = FALSE)


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 0 — SETUP AND DATA LOAD                                        ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  SECTION 0 — SETUP AND DATA LOAD\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

df_raw <- read_csv(file.path(REPO, "data/final/chile_tvecm_panel.csv"),
                   show_col_types = FALSE)

df_all <- df_raw %>%
  filter(complete.cases(m, k_ME, nrs, omega)) %>%
  arrange(year)

cat(sprintf("Full panel: %d-%d (N=%d)\n", min(df_all$year), max(df_all$year), nrow(df_all)))

# Split at 1973
df_pre  <- df_all %>% filter(year < 1973)
df_post <- df_all %>% filter(year >= 1973)

cat(sprintf("Pre-1973  (ISI):        %d-%d (N=%d)\n", min(df_pre$year), max(df_pre$year), nrow(df_pre)))
cat(sprintf("Post-1973 (neoliberal): %d-%d (N=%d)\n", min(df_post$year), max(df_post$year), nrow(df_post)))


# ────────────────────────────────────────────────────────────────────────────
# Helper: run a full Johansen VECM on a sub-sample
# Returns a list with all estimation objects and extracted quantities
# ────────────────────────────────────────────────────────────────────────────
run_johansen <- function(df_sub, label, dumvar = NULL, lag_max = 3) {

  cat("\n\n")
  cat("╔══════════════════════════════════════════════════════════════════════╗\n")
  cat(sprintf("║  %s\n", label))
  cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

  N <- nrow(df_sub)
  Y <- df_sub %>% select(m, k_ME, nrs, omega) %>% as.matrix()
  rownames(Y) <- df_sub$year
  p <- ncol(Y)

  # --- Variable summary ---
  cat("Variable summary:\n")
  for (j in 1:p) {
    cat(sprintf("  %-8s: mean=%8.4f  sd=%8.4f  range=[%8.4f, %8.4f]\n",
        colnames(Y)[j], mean(Y[, j]), sd(Y[, j]), min(Y[, j]), max(Y[, j])))
  }

  # --- Lag selection ---
  cat("\n--- Lag Selection ---\n")
  vs <- VARselect(y = Y, lag.max = lag_max, type = "const", exogen = dumvar)
  cat("All criteria:\n")
  print(vs$selection)

  K_bic <- vs$selection["SC(n)"]
  K_use <- max(K_bic, 2)
  cat(sprintf("SC selects K=%d. Using K=%d. VECM lag L=%d.\n", K_bic, K_use, K_use - 1))

  # --- Johansen trace test ---
  cat("\n--- Johansen Trace Test ---\n")
  jo <- ca.jo(x = Y, type = "trace", ecdet = "const", K = K_use,
              spec = "longrun", dumvar = dumvar)

  r_hat <- 0
  cat(sprintf("  %-8s  %10s  %8s  %8s  %8s  %s\n",
      "H0: r<=", "Trace", "10% CV", "5% CV", "1% CV", "Decision"))
  cat("  ", strrep("-", 70), "\n")
  for (r_null in 0:(p - 1)) {
    idx  <- p - r_null
    stat <- jo@teststat[idx]
    cv10 <- jo@cval[idx, 1]; cv05 <- jo@cval[idx, 2]; cv01 <- jo@cval[idx, 3]
    decision <- ifelse(stat > cv05, "REJECT at 5%", "fail to reject")
    if (stat > cv01) decision <- "REJECT at 1%"
    cat(sprintf("  r <= %d    %10.2f  %8.2f  %8.2f  %8.2f  [%s]\n",
        r_null, stat, cv10, cv05, cv01, decision))
    if (stat > cv05 && r_null >= r_hat) r_hat <- r_null + 1
  }
  cat(sprintf("\n  Rank: r = %d\n", r_hat))

  # Max-eigenvalue for comparison
  jo_e <- ca.jo(x = Y, type = "eigen", ecdet = "const", K = K_use,
                spec = "longrun", dumvar = dumvar)
  r_eigen <- 0
  for (r_null in 0:(p - 1)) {
    idx <- p - r_null
    if (jo_e@teststat[idx] > jo_e@cval[idx, 2]) r_eigen <- r_null + 1
  }
  if (r_hat != r_eigen) {
    cat(sprintf("  ⚠ Max-eigen gives r=%d. Preferring trace.\n", r_eigen))
  }

  if (r_hat == 0) {
    cat("\n  ⚠ BLOCKER: r=0. No cointegration found.\n")
    return(list(r = 0, label = label, N = N, K = K_use, jo = jo, vs = vs))
  }

  # --- VECM estimation (r=1) ---
  cat("\n--- VECM Estimation (r=1) ---\n")
  vecm <- cajorls(jo, r = 1)
  beta <- vecm$beta
  cat("Beta (normalized on m):\n")
  print(round(beta, 6))

  alpha_raw <- coef(vecm$rlm)["ect1", ]
  alpha <- setNames(as.numeric(alpha_raw), c("m", "k_ME", "nrs", "omega"))
  cat("\nAlpha:\n")
  print(round(alpha, 6))

  # --- Sign check ---
  zeta_1 <- -beta[2, 1]  # k_ME
  zeta_2 <- -beta[3, 1]  # nrs
  zeta_3 <- -beta[4, 1]  # omega
  zeta_0 <- -beta[5, 1]  # const

  cat(sprintf("\nLong-run: m = %.4f + %.4f*k_ME + %.4f*nrs + %.4f*omega\n",
      zeta_0, zeta_1, zeta_2, zeta_3))

  if (zeta_1 > 0) {
    cat("  ✓ zeta_1 > 0 — Tavares channel confirmed.\n")
  } else {
    cat("  ⚠ zeta_1 < 0 — Tavares channel REVERSED.\n")
  }

  cat(sprintf("  alpha_m = %+.4f %s\n", alpha["m"],
      ifelse(alpha["m"] < 0, "✓ error-corrects", "⚠ NOT error-correcting")))

  # --- Weak exogeneity ---
  cat("\n--- Weak Exogeneity ---\n")
  we_results <- data.frame(variable = character(), LR = numeric(),
                           p = numeric(), decision = character(),
                           stringsAsFactors = FALSE)
  for (j in 1:p) {
    A_j <- matrix(0, nrow = p, ncol = p - 1)
    col_idx <- 1
    for (i in 1:p) { if (i != j) { A_j[i, col_idx] <- 1; col_idx <- col_idx + 1 } }
    tryCatch({
      we <- alrtest(jo, A = A_j, r = 1)
      lr <- we@teststat; pv <- we@pval[1]
      dec <- ifelse(pv > 0.05, "WE", "not WE")
      cat(sprintf("  %s: LR=%.3f, p=%.4f → %s\n", colnames(Y)[j], lr, pv, dec))
      we_results <- rbind(we_results, data.frame(variable = colnames(Y)[j],
                                                  LR = lr, p = pv, decision = dec,
                                                  stringsAsFactors = FALSE))
    }, error = function(e) {
      cat(sprintf("  %s: alrtest failed\n", colnames(Y)[j]))
    })
  }

  # --- Extract ECT ---
  Y_ext <- cbind(Y, constant = 1)
  ECT <- as.numeric(Y_ext %*% beta[, 1])

  cat(sprintf("\n--- ECT ---\n"))
  cat(sprintf("  mean=%.6f  sd=%.4f  range=[%.4f, %.4f]\n",
      mean(ECT), sd(ECT), min(ECT), max(ECT)))

  adf_ect <- ur.df(ECT, type = "drift", lags = 1)
  cat(sprintf("  ADF tau=%.4f\n", adf_ect@teststat[1]))

  # --- Diagnostics ---
  cat("\n--- Diagnostics ---\n")
  vecm_var <- vec2var(jo, r = 1)

  pt <- serial.test(vecm_var, lags.pt = 10, type = "PT.adjusted")
  cat(sprintf("  Portmanteau: chi2=%.2f, p=%.4f %s\n",
      pt$serial$statistic, pt$serial$p.value,
      ifelse(pt$serial$p.value > 0.05, "✓", "⚠")))

  arch_t <- arch.test(vecm_var, lags.multi = 5)
  cat(sprintf("  ARCH-LM:     chi2=%.2f, p=%.4f %s\n",
      arch_t$arch.mul$statistic, arch_t$arch.mul$p.value,
      ifelse(arch_t$arch.mul$p.value > 0.05, "✓", "⚠")))

  norm_t <- normality.test(vecm_var, multivariate.only = TRUE)
  cat(sprintf("  Jarque-Bera: chi2=%.2f, p=%.4f %s\n",
      norm_t$jb.mul$JB$statistic, norm_t$jb.mul$JB$p.value,
      ifelse(norm_t$jb.mul$JB$p.value > 0.05, "✓", "⚠")))

  # --- Short-run dynamics (m equation only) ---
  cat("\n--- Import equation (m.d) ---\n")
  print(summary(vecm$rlm)$"Response m.d")

  list(
    label = label, N = N, K = K_use, r = r_hat,
    jo = jo, vecm = vecm, beta = beta, alpha = alpha,
    zeta = c(zeta_0 = zeta_0, zeta_1 = zeta_1, zeta_2 = zeta_2, zeta_3 = zeta_3),
    ECT = ECT, years = df_sub$year,
    we = we_results, vs = vs,
    diag_pt = pt$serial$p.value,
    diag_arch = arch_t$arch.mul$p.value,
    diag_jb = norm_t$jb.mul$JB$p.value,
    adf_tau = adf_ect@teststat[1]
  )
}


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 1 — PRE-1973 (ISI ERA)                                         ║
# ╚════════════════════════════════════════════════════════════════════════════╝

res_pre <- run_johansen(df_pre, "PRE-1973 — ISI ERA (1920–1972)")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 2 — POST-1973 (NEOLIBERAL ERA)                                 ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# D1975 impulse dummy for post-1973 sample
D_post <- df_post %>% select(D1975) %>% as.matrix()

res_post <- run_johansen(df_post, "POST-1973 — NEOLIBERAL ERA (1973–2024)", dumvar = D_post)


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 3 — COMBINE ECT_m AND SAVE                                     ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  SECTION 3 — COMBINE ECT_m AND SAVE\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# Build combined ECT_m: regime-appropriate cointegrating residual
ect_df <- rbind(
  data.frame(year = res_pre$years,  ECT_m = res_pre$ECT,  regime = "pre_1973"),
  data.frame(year = res_post$years, ECT_m = res_post$ECT, regime = "post_1973")
) %>% arrange(year)

ect_path <- file.path(REPO, "data/processed/chile/ECT_m_stage1.csv")
write_csv(ect_df, ect_path)
cat(sprintf("ECT_m saved to: %s\n", ect_path))
cat(sprintf("Rows: %d | Years: %d–%d\n", nrow(ect_df), min(ect_df$year), max(ect_df$year)))

cat("\nPre-1973 ECT_m:\n")
cat(sprintf("  mean=%+.4f  sd=%.4f  range=[%.4f, %.4f]\n",
    mean(res_pre$ECT), sd(res_pre$ECT), min(res_pre$ECT), max(res_pre$ECT)))
cat("Post-1973 ECT_m:\n")
cat(sprintf("  mean=%+.4f  sd=%.4f  range=[%.4f, %.4f]\n",
    mean(res_post$ECT), sd(res_post$ECT), min(res_post$ECT), max(res_post$ECT)))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 4 — CROSSWALK SUMMARY                                          ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("================================================================\n")
cat("    STAGE 1 VECM — SPLIT-SAMPLE CROSSWALK\n")
cat("================================================================\n\n")

# Helper to format one regime's results for the crosswalk
format_regime <- function(res) {
  lines <- c(
    sprintf("### %s", res$label),
    sprintf("- Sample: N=%d | VAR lag K=%d | Rank r=%d", res$N, res$K, res$r),
    ""
  )
  if (res$r == 0) {
    lines <- c(lines, "**⚠ No cointegration found.**", "")
    return(lines)
  }
  z <- res$zeta
  a <- res$alpha
  lines <- c(lines,
    "#### Cointegrating Vector (normalized on m)",
    sprintf("$$m = %.4f + %.4f \\cdot k^{ME} + %.4f \\cdot nrs + %.4f \\cdot \\omega$$",
            z["zeta_0"], z["zeta_1"], z["zeta_2"], z["zeta_3"]),
    "",
    "| Coefficient | Value | Interpretation |",
    "|-------------|-------|----------------|",
    sprintf("| zeta_1 (k_ME) | %+.4f | %s |", z["zeta_1"],
            ifelse(z["zeta_1"] > 0, "Tavares ✓", "Tavares ⚠ reversed")),
    sprintf("| zeta_2 (nrs) | %+.4f | Kaldor/Palma-Marcel |", z["zeta_2"]),
    sprintf("| zeta_3 (omega) | %+.4f | Wage share |", z["zeta_3"]),
    sprintf("| zeta_0 (const) | %+.4f | |", z["zeta_0"]),
    "",
    "#### Loading Matrix",
    sprintf("| Variable | alpha | |"),
    "|----------|-------|---|",
    sprintf("| m | %+.4f | %s |", a["m"],
            ifelse(a["m"] < 0, "✓ error-corrects", "⚠")),
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
          res$we$variable[i], res$we$LR[i], res$we$p[i], res$we$decision[i]))
    }
    lines <- c(lines, "")
  }

  lines <- c(lines,
    "#### Diagnostics",
    sprintf("- Portmanteau: p=%.4f %s", res$diag_pt,
            ifelse(res$diag_pt > 0.05, "✓", "⚠")),
    sprintf("- ARCH-LM:     p=%.4f %s", res$diag_arch,
            ifelse(res$diag_arch > 0.05, "✓", "⚠")),
    sprintf("- Jarque-Bera: p=%.4f %s", res$diag_jb,
            ifelse(res$diag_jb > 0.05, "✓", "⚠")),
    sprintf("- ADF on ECT:  tau=%.4f", res$adf_tau),
    "",
    sprintf("#### ECT Summary"),
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
  "## Strategy",
  "Split-sample Johansen VECM at 1973. Each sub-sample gets independent",
  "rank determination, cointegrating vector, alpha loadings, and diagnostics.",
  "",
  "## State Vector",
  "Y = (m, k_ME, nrs, omega)' | ecdet='const' (Case 3)",
  "",
  format_regime(res_pre),
  "---",
  "",
  format_regime(res_post),
  "---",
  "",
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
  sprintf("## ECT_m: `data/processed/chile/ECT_m_stage1.csv`"),
  sprintf("- %d observations (%d–%d)", nrow(ect_df), min(ect_df$year), max(ect_df$year)),
  "- Column `regime` identifies which system generated each ECT value",
  "",
  "---",
  sprintf("*Generated: %s | Authority: Ch2_Outline_DEFINITIVE.md*", Sys.Date())
)

cat(paste(crosswalk_lines, collapse = "\n"))
cat("\n")

crosswalk_path <- file.path(REPO, "output/diagnostics/stage1_vecm_crosswalk.md")
writeLines(crosswalk_lines, crosswalk_path)
cat(sprintf("\nCrosswalk saved to: %s\n", crosswalk_path))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  SECTION 5 — LATEX TABLE                                                ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  SECTION 5 — LATEX TABLE\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

tex_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\caption{Stage 1 Cointegrating Vector --- Import Propensity, Split-Sample}",
  "\\label{tab:stage1_cv1}",
  "\\begin{tabular}{lcc}",
  "\\toprule",
  "Parameter & Pre-1973 (ISI) & Post-1973 (Neoliberal) \\\\"
)

if (res_pre$r > 0 && res_post$r > 0) {
  zp <- res_pre$zeta; zq <- res_post$zeta
  ap <- res_pre$alpha; aq <- res_post$alpha
  tex_lines <- c(tex_lines,
    "\\midrule",
    sprintf("$\\zeta_0$ (constant) & $%.4f$ & $%.4f$ \\\\", zp["zeta_0"], zq["zeta_0"]),
    sprintf("$\\zeta_1$ ($k^{ME}_t$) & $%.4f$ & $%.4f$ \\\\", zp["zeta_1"], zq["zeta_1"]),
    sprintf("$\\zeta_2$ ($nrs_t$) & $%.4f$ & $%.4f$ \\\\", zp["zeta_2"], zq["zeta_2"]),
    sprintf("$\\zeta_3$ ($\\omega_t$) & $%.4f$ & $%.4f$ \\\\", zp["zeta_3"], zq["zeta_3"]),
    "\\midrule",
    sprintf("$\\alpha_m$ & $%.4f$ & $%.4f$ \\\\", ap["m"], aq["m"]),
    sprintf("Rank $r$ & %d & %d \\\\", res_pre$r, res_post$r),
    sprintf("$N$ & %d & %d \\\\", res_pre$N, res_post$N),
    sprintf("$K$ (VAR lag) & %d & %d \\\\", res_pre$K, res_post$K)
  )
} else {
  tex_lines <- c(tex_lines, "\\midrule",
    "\\multicolumn{3}{c}{\\textit{One or both sub-samples failed rank test.}} \\\\")
}

tex_lines <- c(tex_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\vspace{0.5em}",
  "\\begin{minipage}{0.85\\textwidth}",
  "\\footnotesize",
  "\\textit{Notes:} Independent Johansen VECM (Case~3, restricted constant)",
  "estimated on each sub-sample. Sample split at 1973 (Chilean coup).",
  sprintf("Pre-1973: %d--%d. Post-1973: %d--%d.",
          min(df_pre$year), max(df_pre$year), min(df_post$year), max(df_post$year)),
  "Post-1973 includes $D_{1975}$ as unrestricted impulse dummy.",
  "\\end{minipage}",
  "\\end{table}"
)

tex_path <- file.path(REPO, "output/tables/stage1_cointegrating_vector.tex")
writeLines(tex_lines, tex_path)
cat(sprintf("LaTeX table saved to: %s\n", tex_path))


# ══════════════════════════════════════════════════════════════════════════════
cat("\n\n")
cat("================================================================\n")
cat("    STAGE 1 VECM — COMPLETE (SPLIT-SAMPLE)\n")
cat("================================================================\n")
cat(sprintf("  Pre-1973:  r=%d, N=%d, K=%d\n", res_pre$r, res_pre$N, res_pre$K))
cat(sprintf("  Post-1973: r=%d, N=%d, K=%d\n", res_post$r, res_post$N, res_post$K))
cat(sprintf("  ECT_m:     %s\n", ect_path))
cat(sprintf("  Crosswalk: %s\n", crosswalk_path))
cat(sprintf("  LaTeX:     %s\n", tex_path))
cat("================================================================\n")
