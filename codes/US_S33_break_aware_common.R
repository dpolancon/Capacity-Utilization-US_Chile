#!/usr/bin/env Rscript

# US_S33_break_aware_common.R
# ---------------------------------------------------------------------------
# Shared infrastructure for the binding S0* break-aware pre-testing sequence on
# the U.S. panel:
#
#     Step 1  Bai-Perron (1998, 2003) sequential break search   -> US_S33A_*.R
#     Step 2  Lee-Strazicich (2003) Minimum-LM unit root check  -> US_S33B_*.R
#     Step 3  Break-interacted IM-OLS / DOLS estimation         -> US_S33C_*.R (Spec A)
#                                                              -> US_S33D_*.R (Spec B)
#
# Authority (binding; read before editing anything in this file):
#   chapter2_vault/03_econometrics/S03_StructuralBreak_Protocol.md  (foundational)
#   chapter2_vault/03_econometrics/S01_StructuralBreak_Protocol.md  (Specification A)
#   chapter2_vault/03_econometrics/S02_StructuralBreak_Protocol.md  (Specification B)
#   chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
#   chapter2_vault/03_econometrics/Interaction_Term_Integration_Order_Gate.md
#   AGENTS.md  (notation lock, report-vs-output governance, WLM v4.0 voice)
#
# This file sets no policy of its own. Every constant below is a transcription
# from one of the protocol notes or from an existing frozen repo script, and the
# source is named in the adjacent comment. Do not add a constant here without a
# source line.
#
# Governance: all quantitative artifacts written by the US_S33* family land under
# output/US/BREAK_AWARE_IMOLS/. LaTeX table fragments land under reports/.
# ---------------------------------------------------------------------------

options(stringsAsFactors = FALSE, scipen = 999)

suppressPackageStartupMessages({
  library(strucchange)
  library(cointReg)
  library(sandwich)
})

# ---------------------------------------------------------------------------
# 0. Paths
# ---------------------------------------------------------------------------

S33_REPO_ROOT <- Sys.getenv("CH2_REPO_ROOT",
                            "C:/ReposGitHub/Capacity-Utilization-US_Chile")

S33_OUT_ROOT <- file.path(S33_REPO_ROOT, "output", "US", "BREAK_AWARE_IMOLS")

s33_dir <- function(...) file.path(S33_OUT_ROOT, ...)

s33_ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}

# Frozen panel inputs (identical files consumed by COMMON_S40_baseline_imols_cpr_estimation.R
# and COMMON_S40_specB_imols_estimation.R -- do not regenerate them here).
S33_PANEL_SPEC_A <- file.path(S33_REPO_ROOT, "output", "gpim_baseline_components_long.csv")
S33_PANEL_SPEC_B <- file.path(S33_REPO_ROOT, "output", "gpim_specB_components_long.csv")

# ---------------------------------------------------------------------------
# 1. Protocol constants (transcribed; each carries its source)
# ---------------------------------------------------------------------------

# S01 Sec.2 Step 1: "Fordist Window (1929-1973, T=43): Trimming parameter eps = 0.20."
#                   "Post-Fordist Window (1974-2024, T=51): Trimming parameter eps = 0.15."
# S02 Stage 2A adds the Full Sample (1929-2024, T=94). S02 does not name a full-sample
# trimming parameter; S03 Sec.2A gives the BP default ("a trimming parameter eps,
# typically 0.15"), which is what the full-sample row uses. Recorded explicitly so the
# choice is auditable rather than implicit.
S33_WINDOWS <- list(
  Full_Sample_1929_2024 = list(
    key        = "Full_Sample_1929_2024",
    label      = "Full Sample",
    range      = c(1929L, 2024L),
    epsilon    = 0.15,
    eps_source = "S03 Sec.2A default (S02 Stage 2A names no full-sample epsilon)",
    protocol_dates = c(1933L, 1947L, 1968L, 1982L, 2008L),
    dates_source   = "S02 Stage 2A: global break points at 1933, 1947, 1968, 1982, 2008"
  ),
  Fordist_1929_1973 = list(
    key        = "Fordist_1929_1973",
    label      = "Fordism",
    range      = c(1929L, 1973L),
    epsilon    = 0.20,
    eps_source = "S01 Sec.2 Step 1 (Fordist window)",
    protocol_dates = c(1933L, 1947L),
    dates_source   = "S01 Sec.2 Step 1: candidate slope breaks at 1933 and 1947; S02 Stage 2A agrees"
  ),
  Post_Fordist_1974_2024 = list(
    key        = "Post_Fordist_1974_2024",
    label      = "Post-Fordism",
    range      = c(1974L, 2024L),
    epsilon    = 0.15,
    eps_source = "S01 Sec.2 Step 1 (Post-Fordist window)",
    protocol_dates = c(1982L, 2000L, 2008L),
    dates_source   = "S01 Sec.2 Step 1: 1982, 2000, 2008 (S02 Stage 2A names 1982 and 2008 only)"
  )
)

# S01 Sec.5 Step 1 / S02 Sec.6 Step 1: the multiplicative interaction terms are built
# for T_1947 inside Fordism and T_2008 inside Post-Fordism.
S33_PRIMARY_TB <- c(Fordist_1929_1973 = 1947L, Post_Fordist_1974_2024 = 2008L)

# S01 Sec.2 Step 3 "Variance Reduction Check": progress-report baselines against which the
# break-interacted residual variance must be compared.
S33_SIGMA_U_BASELINE_SPEC_A <- c(Fordist_1929_1973 = 0.158, Post_Fordist_1974_2024 = 0.184)

# S02 Sec.4: Shin LM without step/slope controls (0.261) versus with controls (0.042);
# residual variance 0.200 -> 0.112. Used as the Spec B comparison anchors.
S33_SPEC_B_ANCHORS <- list(
  C_shin_uncontrolled = 0.261, C_shin_controlled = 0.042,
  sigma_u_uncontrolled = 0.200, sigma_u_controlled = 0.112
)

# S01 Sec.2 Step 3: "DOLS ... with leads and lags (q = 1, l = 1)".
S33_DOLS_LEADS <- 1L
S33_DOLS_LAGS  <- 1L

# ---------------------------------------------------------------------------
# 2. Panel loaders
# ---------------------------------------------------------------------------

# Specification A regressand / regressors, per the v5 report Sec.2 equation:
#   y_t^NFC = alpha + beta_Kcap k_t^cap + phi_omega omega_{t-1}
#             + theta_1 (k_t^cap . omega_{t-1}) + Lambda D_t' + u_t
s33_load_spec_a <- function(wage_measure = "omega_NFC_GVA") {
  stopifnot(file.exists(S33_PANEL_SPEC_A))
  df <- read.csv(S33_PANEL_SPEC_A, stringsAsFactors = FALSE)
  lag_col <- paste0(wage_measure, "_lag1")
  need <- c("year", "y_t", "k_cap", wage_measure, lag_col)
  missing <- setdiff(need, names(df))
  if (length(missing)) stop("Spec A panel is missing columns: ", paste(missing, collapse = ", "))
  df <- df[stats::complete.cases(df[, need]), need]
  names(df) <- c("year", "y", "k_cap", "omega", "omega_lag1")
  df[order(df$year), ]
}

# Specification B regressand / regressors, per S02 Sec.1B:
#   y_t^NFC = alpha + theta_NRC k_t^NRC + theta_kappa kappa_t + beta_pkappa p_t^kappa
#             + beta_omega omega_{t-1} + theta_omega_kappa (kappa_t . omega_{t-1})
#             + theta_kappa_pkappa (kappa_t . p_t^kappa) + gamma' D_t + u_t
# Notation lock (AGENTS.md): kappa_t = k_t^ME - k_t^NRC. In the frozen panel this column
# is stored as `tau_real`; it is renamed to `kappa` on load so no downstream script
# reproduces the retired tau_t notation.
s33_load_spec_b <- function(wage_measure = "omega_NFC_GVA") {
  stopifnot(file.exists(S33_PANEL_SPEC_B))
  df <- read.csv(S33_PANEL_SPEC_B, stringsAsFactors = FALSE)
  lag_col <- paste0(wage_measure, "_lag1")
  need <- c("year", "y_t", "k_NRC", "tau_real", "p_rel", wage_measure, lag_col)
  missing <- setdiff(need, names(df))
  if (length(missing)) stop("Spec B panel is missing columns: ", paste(missing, collapse = ", "))
  df <- df[stats::complete.cases(df[, need]), need]
  names(df) <- c("year", "y", "k_NRC", "kappa", "p_kappa", "omega", "omega_lag1")
  df[order(df$year), ]
}

s33_window <- function(df, win) {
  df[df$year >= win$range[1] & df$year <= win$range[2], , drop = FALSE]
}

# ---------------------------------------------------------------------------
# 3. Break-term constructors (S03 Sec.1A / Sec.3)
# ---------------------------------------------------------------------------

# D_t(T_B) = I(t >= T_B): step / level dummy.
s33_step <- function(year, tb) as.numeric(year >= tb)

# DT_t(T_B) = (t - T_B + 1) . I(t >= T_B): trend-break (deterministic slope shift) dummy.
s33_trend_break <- function(year, tb) ifelse(year >= tb, year - tb + 1, 0)

# P_t(T_B) = I(t == T_B): single-period pulse. S03 Sec.3 requires this inside the
# lead/lag polynomial so the differenced pulse at T_B does not contaminate the
# long-run elasticity estimates.
s33_pulse <- function(year, tb) as.numeric(year == tb)

# B_t(a, b) = I(a <= t <= b): finite block dummy that switches back off.
#
# Not in S01-S03, which only define permanent steps D_t and trend breaks DT_t. It is
# added because US_S33A's Bai-Perron prescan lands repeatedly in 1939-1945 across both
# specifications (Spec A: 1939 and 1942; Spec B: 1943 and 1945), and war mobilisation is
# a level distortion that REVERSES after demobilisation rather than a permanent regime
# shift. Forcing it into a permanent step would mis-attribute the post-war reversion to
# the capital elasticity. Used for the 1942-1945 war block inside the Fordist window;
# the 1933 New Deal regime change stays a permanent step.
s33_block <- function(year, from, to) as.numeric(year >= from & year <= to)

# ---------------------------------------------------------------------------
# 4. Ledger writers
# ---------------------------------------------------------------------------

s33_write_ledger <- function(x, dir, filename) {
  s33_ensure_dir(dir)
  path <- file.path(dir, filename)
  utils::write.csv(x, path, row.names = FALSE)
  message("  wrote ", path)
  invisible(path)
}

# Integrity ledgers pattern-match output/CL/BOP_BINDING_V6/*/s3*_*integrity*.csv:
# a three-column check / passed / detail frame.
s33_integrity <- function(checks, passed, detail) {
  stopifnot(length(checks) == length(passed), length(checks) == length(detail))
  data.frame(check = checks, passed = passed, detail = detail, stringsAsFactors = FALSE)
}

s33_halt_on_integrity <- function(integrity, stage) {
  if (!all(integrity$passed %in% TRUE)) {
    failed <- paste(integrity$check[!(integrity$passed %in% TRUE)], collapse = "; ")
    stop(stage, " integrity checks failed: ", failed)
  }
  message(stage, " integrity checks passed (", nrow(integrity), " checks).")
  invisible(TRUE)
}

s33_pending <- function(what) paste0("[PENDING: LOCAL EXECUTION] ", what)

# ---------------------------------------------------------------------------
# 5. IM-OLS engine (E10V active estimator lock)
# ---------------------------------------------------------------------------
# The wrapper below is the COMMON_S40_baseline_imols_cpr_estimation.R triad, lifted so
# the break-aware family produces diagnostics on exactly the same scale as the v5 / v6
# reports. Critical values are the ones already frozen in that script; nothing new is
# introduced here.
#
# E10V hard constraints enforced downstream:
#   - IM-OLS (cointReg::cointRegIM) is the estimator. DOLS and FM-OLS are comparators only.
#   - FWL orthogonalization / auxiliary residualization of the interaction terms is
#     FORBIDDEN. Interactions enter raw into the full design (see s33_assert_no_fwl).
#   - Regime A (uncentered, QR-factorised) is the main specification; Regime B
#     (initial-state centering) is the primary robustness; Regime C (sample-mean) secondary.

s33_safe_scalar <- function(val, default = NA) {
  if (is.null(val) || length(val) == 0 || is.na(val[1])) return(default)
  val[1]
}

s33_stars <- function(t_val) {
  if (is.null(t_val) || length(t_val) == 0 || is.na(t_val)) return("")
  a <- abs(t_val)
  if (a >= 2.58) return("***")
  if (a >= 1.96) return("**")
  if (a >= 1.645) return("*")
  ""
}

# MacKinnon (2010) residual-ADF critical values, transcribed from
# COMMON_S40_specB_imols_estimation.R (k_reg switch) so the two families agree.
s33_adf_crit <- function(k_reg) {
  c(
    crit_1  = if (k_reg <= 1) -3.96 else if (k_reg <= 3) -4.48 else -4.98,
    crit_5  = if (k_reg <= 1) -3.41 else if (k_reg <= 3) -3.90 else -4.43
  )
}

# Shin (1994) LM critical values, transcribed from COMMON_S40_baseline_imols_cpr_estimation.R.
S33_SHIN_CRIT <- c(crit_10 = 0.095, crit_5 = 0.121, crit_1 = 0.184)

s33_imols <- function(x, y, deter = NULL, kernel = "ba", bandwidth = "nw") {
  x <- as.matrix(x)
  if (is.null(deter)) deter <- matrix(1, nrow = length(y), ncol = 1)

  fit <- cointReg::cointRegIM(x = x, y = y, deter = deter,
                              selector = c(1, 2), t.test = TRUE,
                              kernel = kernel, bandwidth = bandwidth)

  u <- fit$u.plus
  T_obs <- length(u)
  k_reg <- ncol(x)

  # 1. Engle-Granger residual ADF (H0: no cointegration)
  t_adf <- NA_real_; adf_stars <- ""
  try({
    eg <- stats::lm(diff(u) ~ u[-T_obs] - 1)
    t_adf <- summary(eg)$coefficients[1, 3]
    cv <- s33_adf_crit(k_reg)
    adf_stars <- if (t_adf < cv[["crit_1"]]) "***" else
      if (t_adf < cv[["crit_5"]]) "**" else
        if (t_adf < (cv[["crit_5"]] + 0.3)) "*" else ""
  }, silent = TRUE)

  # 2. Shin (1994) LM stationarity test (H0: cointegration)
  C_shin <- NA_real_; shin_stars <- ""
  try({
    S_t <- cumsum(u)
    omega2 <- fit$omega.u.v
    if (is.null(omega2) || is.na(omega2) || omega2 <= 0) {
      omega2 <- cointReg::getLongRunVar(u, kernel = kernel, bandwidth = bandwidth)$long.run
    }
    C_shin <- sum(S_t^2) / (T_obs^2 * omega2)
    shin_stars <- if (C_shin >= S33_SHIN_CRIT[["crit_1"]]) "***" else
      if (C_shin >= S33_SHIN_CRIT[["crit_5"]]) "**" else
        if (C_shin >= S33_SHIN_CRIT[["crit_10"]]) "*" else ""
  }, silent = TRUE)

  # 3. Fit / variance
  ss_tot <- sum((y - mean(y))^2)
  ss_res <- sum(u^2)
  r2_level <- max(0, 1 - ss_res / ss_tot)
  sigma_u <- sqrt(ss_res / max(1, T_obs - k_reg))

  Sy <- cumsum(y)
  res_sum <- fit$u.plus2
  if (is.null(res_sum)) res_sum <- fit$residuals
  r2_sum <- if (!is.null(res_sum)) max(0, 1 - sum(res_sum^2) / sum((Sy - mean(Sy))^2)) else NA_real_

  lambda2 <- fit$lambda2
  lambda2_norm <- if (!is.null(lambda2) && length(lambda2) > 0) sqrt(sum(lambda2^2, na.rm = TRUE)) else NA_real_

  fit$diag <- list(
    t_adf = s33_safe_scalar(t_adf), adf_stars = adf_stars,
    C_shin = s33_safe_scalar(C_shin), shin_stars = shin_stars,
    lambda2_norm = s33_safe_scalar(lambda2_norm),
    r2_level = r2_level, r2_sum = r2_sum, sigma_u = sigma_u,
    T_obs = T_obs, k_reg = k_reg
  )
  fit
}

# Extract a named IM-OLS coefficient. cointReg prefixes partial-sum regressors with "S.".
s33_coef <- function(fit, name) {
  th <- fit$theta
  key <- paste0("S.", name)
  if (key %in% names(th)) return(unname(th[key]))
  if (name %in% names(th)) return(unname(th[name]))
  NA_real_
}

s33_tstat <- function(fit, name) {
  tt <- fit$t.theta
  if (is.null(tt)) return(NA_real_)
  if (is.null(names(tt)) && length(tt) == length(fit$theta)) names(tt) <- names(fit$theta)
  key <- paste0("S.", name)
  if (key %in% names(tt)) return(unname(tt[key]))
  if (name %in% names(tt)) return(unname(tt[name]))
  NA_real_
}

# ---------------------------------------------------------------------------
# 6. DOLS comparator (E10V: dols_status = diagnostic-comparator)
# ---------------------------------------------------------------------------
# S01 Sec.2 Step 3 asks for a DOLS read alongside IM-OLS with q = 1 lead and l = 1 lag.
# E10V blocks DOLS from any baseline role, so every DOLS row this family writes carries
# role = "diagnostic_comparator" and is never promoted into a report table on its own.

s33_dols <- function(X, y, leads = S33_DOLS_LEADS, lags = S33_DOLS_LAGS) {
  X <- as.matrix(X)
  n <- nrow(X)
  dX <- rbind(rep(NA_real_, ncol(X)), diff(X))
  aug <- NULL
  aug_names <- character(0)
  for (j in seq_len(ncol(X))) {
    for (h in seq_len(lags)) {
      aug <- cbind(aug, c(rep(NA_real_, h), dX[seq_len(n - h), j]))
      aug_names <- c(aug_names, sprintf("dlag%d_%s", h, colnames(X)[j]))
    }
    for (h in seq_len(leads)) {
      aug <- cbind(aug, c(dX[(h + 1):n, j], rep(NA_real_, h)))
      aug_names <- c(aug_names, sprintf("dlead%d_%s", h, colnames(X)[j]))
    }
  }
  colnames(aug) <- aug_names
  design <- cbind(X, aug)
  keep <- stats::complete.cases(design) & !is.na(y)
  design <- design[keep, , drop = FALSE]
  yk <- y[keep]
  fit <- stats::lm(yk ~ design)
  vc <- sandwich::NeweyWest(fit, prewhite = FALSE, adjust = TRUE)
  est <- stats::coef(fit)
  se <- sqrt(diag(vc))
  nm <- gsub("^design", "", names(est))
  list(estimate = stats::setNames(est, nm),
       se = stats::setNames(se, nm),
       tstat = stats::setNames(est / se, nm),
       T_obs = sum(keep),
       role = "diagnostic_comparator")
}

# ---------------------------------------------------------------------------
# 7. Interaction-Term Integration Order Gate
# ---------------------------------------------------------------------------
# Interaction_Term_Integration_Order_Gate.md blocks estimator selection until four
# classifications are recorded. The break-interacted terms introduced by S01 Sec.1A and
# S02 Sec.3 are generated regressors and therefore fall squarely inside the gate.
# Every US_S33C/D run writes this ledger and halts if any row is not PASS.

s33_interaction_gate_ledger <- function(spec, base_vars, interaction_terms,
                                        integration_verdicts, centering_regimes) {
  rows <- list()
  rows[[1]] <- data.frame(
    gate_item = "1. Base variable integration order",
    requirement = "Base variables verified I(1) under unit-root tests allowing structural breaks",
    evidence = paste(sprintf("%s=%s", names(integration_verdicts), integration_verdicts), collapse = "; "),
    status = if (all(integration_verdicts == "I(1)")) "PASS" else "BLOCK",
    stringsAsFactors = FALSE
  )
  rows[[2]] <- data.frame(
    gate_item = "2. Interaction term classification",
    requirement = "Cross-products classified as O_p(T) degree-2 polynomial CPR regressors, not classical I(2)",
    evidence = paste(interaction_terms, collapse = "; "),
    status = if (length(interaction_terms) > 0) "PASS" else "BLOCK",
    stringsAsFactors = FALSE
  )
  rows[[3]] <- data.frame(
    gate_item = "3. FWL pre-filtering prohibition",
    requirement = "No auxiliary OLS orthogonalization or residualization of any interaction term",
    evidence = "Interactions constructed raw and passed directly into the IM-OLS design matrix; see s33_assert_no_fwl()",
    status = "PASS",
    stringsAsFactors = FALSE
  )
  rows[[4]] <- data.frame(
    gate_item = "4. Centering protocol verification",
    requirement = "Regime A (uncentered, QR/SVD) main + Regime B (initial-state) primary robustness",
    evidence = paste(centering_regimes, collapse = "; "),
    status = if (all(c("Regime_A_Uncentered", "Regime_B_Initial_Centered") %in% centering_regimes)) "PASS" else "BLOCK",
    stringsAsFactors = FALSE
  )
  out <- do.call(rbind, rows)
  out$specification <- spec
  out$base_variables <- paste(base_vars, collapse = "; ")
  out[, c("specification", "gate_item", "requirement", "evidence", "status", "base_variables")]
}

# Structural guard: the design matrix handed to IM-OLS must contain the raw interaction
# columns, i.e. the interaction column must NOT be orthogonal-by-construction to its own
# constituent levels (which is exactly the signature of an FWL pre-filtered regressor).
# ---------------------------------------------------------------------------
# Break-interaction span
# ---------------------------------------------------------------------------
# A break-interacted cross-product only behaves as a reparameterization under centering
# if the design also spans every LOWER-ORDER constituent of that product. Centering the
# base series expands
#
#   (a - a0)(b - b0) D_t = ab.D_t - a0 (b.D_t) - b0 (a.D_t) + a0 b0 D_t
#
# so a design carrying ab.D_t must also carry a.D_t, b.D_t and D_t. Omit either
# first-order term and the centering regime stops being a numerical convention and starts
# selecting a different model -- which is what US_S33F found had happened across
# US_S33C, US_S33D and US_S33E, in some cells flipping the SIGN of the parameter carrying
# the hypothesis.
#
# Verified on synthetic data with a known DGP (US_S33F): OLS relative spread across the
# three centering regimes is 6e-16 for {1, a, b, ab}, 7.8e-02 once ab.D enters without
# a.D and b.D, and 6e-16 again once those are restored. Neither IM-OLS itself (0.3% on
# clean data) nor ill-conditioning (0.26% at CN 181) accounts for it.
#
# s33_break_span() builds the block so a caller cannot forget a constituent, and
# s33_assert_complete_span() fails loudly if one is missing anyway -- the same posture as
# s33_assert_no_fwl() takes toward FWL pre-filtering.

# vars: named list of centered base vectors, e.g. list(kappa = kp, omega = w)
# products: list of character vectors naming the factors of each wanted cross-product,
#           e.g. list(c("kappa","omega")) for kappa.omega.D
# Returns the design block including D itself and every first-order var.D term implied.
s33_break_span <- function(D, vars, products, prefix_D = "D_TB") {
  stopifnot(is.numeric(D), length(vars) > 0)
  needed <- unique(unlist(products))
  missing_vars <- setdiff(needed, names(vars))
  if (length(missing_vars)) {
    stop("s33_break_span: products reference vars not supplied: ",
         paste(missing_vars, collapse = ", "))
  }
  out <- matrix(D, ncol = 1L); nms <- prefix_D

  # First-order constituents: every variable appearing in any product.
  for (v in needed) {
    out <- cbind(out, vars[[v]] * D)
    nms <- c(nms, paste0(v, "_x_D"))
  }
  # The products themselves.
  for (p in products) {
    col <- D
    for (v in p) col <- col * vars[[v]]
    out <- cbind(out, col)
    nms <- c(nms, paste0(paste(p, collapse = "_"), "_x_D"))
  }
  colnames(out) <- nms
  out
}

# Guard. `products` is the same list passed to s33_break_span(), so the check is explicit
# rather than parsed back out of column names -- variable names here contain underscores
# ("k_NRC", "p_kappa") and any name-splitting heuristic would mis-decompose them.
s33_assert_complete_span <- function(X, products, vars_present = NULL, prefix_D = "D_TB") {
  cn <- colnames(X)
  if (is.null(cn)) stop("s33_assert_complete_span: X has no column names")
  if (!length(products)) return(invisible(TRUE))
  if (!(prefix_D %in% cn)) {
    stop("Incomplete break span: break interactions are specified but the level dummy '",
         prefix_D, "' is absent from the design.")
  }
  for (p in products) {
    prod_col <- paste0(paste(p, collapse = "_"), "_x_D")
    if (!(prod_col %in% cn)) next          # product not in this design; nothing to check
    for (v in p) {
      want <- paste0(v, "_x_D")
      if (!(want %in% cn)) {
        stop("Incomplete break span: '", prod_col, "' is in the design but its ",
             "constituent '", want, "' is not. Centering is then a change of model ",
             "rather than a reparameterization (see US_S33F). Build the block with ",
             "s33_break_span().")
      }
    }
  }
  invisible(TRUE)
}

s33_assert_no_fwl <- function(X, interaction_cols, base_cols, tol = 1e-8) {
  X <- as.matrix(X)
  for (ic in interaction_cols) {
    if (!(ic %in% colnames(X))) next
    for (bc in intersect(base_cols, colnames(X))) {
      cp <- abs(sum(X[, ic] * X[, bc]))
      if (cp < tol) {
        stop("FWL pre-filtering detected: interaction column '", ic,
             "' is numerically orthogonal to base column '", bc,
             "'. E10V forbids auxiliary residualization of interaction terms.")
      }
    }
  }
  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# 8. Centering regimes (E10V / N11 three-regime protocol)
# ---------------------------------------------------------------------------

s33_center <- function(v, regime) {
  switch(regime,
         Regime_A_Uncentered       = v,
         Regime_B_Initial_Centered = v - v[1],
         Regime_C_Mean_Centered    = v - mean(v, na.rm = TRUE),
         stop("unknown centering regime: ", regime))
}

S33_CENTERING_REGIMES <- c("Regime_A_Uncentered",
                           "Regime_B_Initial_Centered",
                           "Regime_C_Mean_Centered")

S33_CENTERING_CODE <- c(Regime_A_Uncentered = "Uncentered",
                        Regime_B_Initial_Centered = "Initial-St",
                        Regime_C_Mean_Centered = "Sample-Mean")

# ---------------------------------------------------------------------------
# 9. Lee-Strazicich engine adapter (external dependency)
# ---------------------------------------------------------------------------
# S01/S02/S03 all declare  external_dependency: "C:/ReposGitHub/LeeStrazicichUnitRoot".
# The Minimum-LM test MUST come from that repo -- a hand-rolled substitute is
# explicitly forbidden by the acceptance criteria of P05.
#
# That repo is now present and its surface is known, so this adapter is pinned to it
# rather than auto-discovering an entry point. The repo is NOT an R package: it is a
# flat set of loose scripts that must be sourced. It exposes exactly two callables:
#
#   ur.ls(y, model = c("crash","break"), breaks = 1, lags = NULL,
#         method = c("GTOS","Fixed"), pn = 0.1, print.results = c("print","silent"))
#   ur.ls.bootstrap(...)   # same, plus critval = c("bootstrap","theoretical")
#
# Four properties of ur.ls() drive the design below and are easy to get wrong:
#
#   (a) model is match.arg(c("crash","break")). "crash" = Model A (intercept break);
#       "break" = Model C (intercept AND trend break). S01 Sec.2 Step 2 requires Z_t to
#       carry both D_t and DT_t, so Model C is the protocol-relevant run and Model A is
#       the reported robustness companion.
#   (b) method and print.results are compared with `==` BEFORE (or without) match.arg.
#       Passing the length-2 defaults raises "invalid length" under R >= 4.3. Both MUST
#       be supplied as single strings on every call.
#   (c) The trimming argument is named `pn`, not `trim`/`eps`. Under method = "GTOS" the
#       `lags` argument is the general-to-specific MAXIMUM, so it must be supplied even
#       though its default is NULL.
#   (d) The return value is list(results.return, break.reg) -- the OUTER list is unnamed.
#       results.return is named c("t-stat","First break","Second break","Runtime") for
#       breaks = 2 and c("t-stat","First break","Runtime") for breaks = 1. Break entries
#       are POSITIONS in y, not years. No critical values are returned at all.
#
# Because of (d) the critical values are transcribed below from the engine's own source.
# Transcribing published constants is not a reimplementation of the test: the LM
# statistic, the break search, and the lag selection all still come from ur.ls().
#
# On the first local run, execute
#
#     Rscript codes/US_S33B_lee_strazicich_break_robust_unitroot.R --probe
#
# to print every callable the repo exposes together with its formal arguments.

S33_LS_REPO <- Sys.getenv("LS_REPO", "C:/ReposGitHub/LeeStrazicichUnitRoot")

# Pinned entry point. Overridable only if the upstream repo renames it.
S33_LS_FUN <- Sys.getenv("LS_FUN", "ur.ls")

# ur.ls() takes no fixed-break-date argument and its internal LM regression helper
# (myLSfunc) is defined inside the function body, so it cannot be called at pinned
# dates. S01 Sec.2 Step 2 / S02 Stage 2B ask for the LM test "at the candidate break
# dates from Bai-Perron"; that is not executable with the mandated engine. US_S33B
# therefore runs the endogenous minimum-LM search as designed and reports a
# LS-vs-Bai-Perron date concordance ledger. Recorded here so the deviation is auditable
# rather than buried in the calling script.
S33_LS_DATE_MODE <- "endogenous_search_with_bp_concordance"

# ur.ls() supports one or two breaks only. Post-Fordism carries three protocol
# candidates (1982/2000/2008), so both breaks = 1 and breaks = 2 are run and the
# ledger records which protocol dates each endogenous solution recovers.
S33_LS_MAX_BREAKS <- 2L

# Critical values transcribed verbatim from LeeStrazicichUnitRootTest.R lines 47-100.
# ALL derived at T = 100. The Fordist (T ~ 45) and Post-Fordist (T ~ 51) windows are
# roughly half that, so these are approximations in the sub-samples. Every ledger row
# written by US_S33B carries this caveat in an explicit column, and both report drafts
# state it in prose.
S33_LS_CVAL_SAMPLE_SIZE <- 100L

S33_LS_CVAL <- list(
  # Model A, one break: invariant to break location.
  crash_1 = c(crit_1 = -4.239, crit_5 = -3.566, crit_10 = -3.211),

  # Model C, one break: depends on lambda = T_B / T, symmetric about lambda and 1-lambda.
  # Grid rows are lambda = 0.1 ... 0.5; the engine's own comment states intermediate
  # locations "can be interpolated", which is what s33_ls_cval() does.
  break_1 = data.frame(
    lambda  = c(0.1,   0.2,   0.3,   0.4,   0.5),
    crit_1  = c(-5.11, -5.07, -5.15, -5.05, -5.11),
    crit_5  = c(-4.50, -4.47, -4.45, -4.50, -4.51),
    crit_10 = c(-4.21, -4.20, -4.18, -4.18, -4.17)
  ),

  # Model A, two breaks: invariant to break location (LM_tau row).
  crash_2 = c(crit_1 = -4.545, crit_5 = -3.842, crit_10 = -3.504),

  # Model C, two breaks, breaks entering the DGP: invariant to break location (LM_tau).
  break_2_dgp = c(crit_1 = -5.823, crit_5 = -5.286, crit_10 = -4.989),

  # Model C, two breaks, breaks NOT in the DGP: depends on (lambda_1, lambda_2).
  # Rows are lambda_1 in {0.2, 0.4, 0.6}; columns are lambda_2 in {0.4, 0.6, 0.8}.
  # NA where lambda_1 >= lambda_2. This is the table ur.ls() itself prints for breaks = 2.
  break_2_tau = list(
    lambda_1 = c(0.2, 0.4, 0.6),
    lambda_2 = c(0.4, 0.6, 0.8),
    crit_1  = matrix(c(-6.16, -6.41, -6.33,
                       NA,    -6.45, -6.42,
                       NA,    NA,    -6.32), nrow = 3, byrow = TRUE),
    crit_5  = matrix(c(-5.59, -5.74, -5.71,
                       NA,    -5.67, -5.65,
                       NA,    NA,    -5.73), nrow = 3, byrow = TRUE),
    crit_10 = matrix(c(-5.27, -5.32, -5.33,
                       NA,    -5.31, -5.32,
                       NA,    NA,    -5.32), nrow = 3, byrow = TRUE)
  )
)

s33_ls_load <- function(repo = S33_LS_REPO) {
  if (!dir.exists(repo)) {
    stop("Lee-Strazicich engine not found at '", repo, "'. ",
         "S01/S02/S03 declare this repo as a binding external dependency. ",
         "Clone it or set LS_REPO. A local reimplementation is not an acceptable substitute.")
  }
  env <- new.env(parent = globalenv())

  # Route 1: the dependency is an R package.
  if (file.exists(file.path(repo, "DESCRIPTION"))) {
    loaded <- FALSE
    if (requireNamespace("pkgload", quietly = TRUE)) {
      loaded <- tryCatch({ pkgload::load_all(repo, quiet = TRUE); TRUE },
                         error = function(e) FALSE)
    }
    if (!loaded && requireNamespace("devtools", quietly = TRUE)) {
      loaded <- tryCatch({ devtools::load_all(repo, quiet = TRUE); TRUE },
                         error = function(e) FALSE)
    }
    if (loaded) {
      pkg <- tryCatch(read.dcf(file.path(repo, "DESCRIPTION"), "Package")[1, 1],
                      error = function(e) NA_character_)
      if (!is.na(pkg)) {
        ns <- asNamespace(pkg)
        for (nm in ls(ns, all.names = FALSE)) assign(nm, get(nm, envir = ns), envir = env)
        attr(env, "route") <- paste0("package::", pkg)
        return(env)
      }
    }
  }

  # Route 2: loose scripts. Source R/ first, then top-level .R files.
  files <- c(list.files(file.path(repo, "R"), pattern = "\\.[Rr]$", full.names = TRUE),
             list.files(repo, pattern = "\\.[Rr]$", full.names = TRUE))
  files <- unique(files)

  # Two files in the upstream repo are DRIVERS, not definitions: sourcing them executes
  # a worked example (LeeStrazicichApplication.R) and a 1000-replication bootstrap
  # (BootstrapImplementation.R, which also hard-requires doSNOW). Neither defines a
  # callable this family needs, and BootstrapImplementation.R would silently burn a very
  # long run on the example series if doSNOW were ever installed. Skip both by name.
  drivers <- c("LeeStrazicichApplication.R", "BootstrapImplementation.R")
  files <- files[!(basename(files) %in% drivers)]
  if (!length(files)) {
    stop("No .R sources found under '", repo, "'. Cannot bind the Lee-Strazicich engine.")
  }
  for (f in files) {
    tryCatch(sys.source(f, envir = env, keep.source = FALSE),
             error = function(e) message("  [ls_load] skipped ", basename(f), ": ", conditionMessage(e)))
  }
  attr(env, "route") <- paste0("sourced ", length(files), " file(s)")
  env
}

s33_ls_catalogue <- function(env) {
  nms <- ls(env, all.names = FALSE)
  fns <- nms[vapply(nms, function(n) is.function(get(n, envir = env)), logical(1))]
  data.frame(
    fun_name = fns,
    formals = vapply(fns, function(n) paste(names(formals(get(n, envir = env))), collapse = ", "),
                     character(1)),
    stringsAsFactors = FALSE
  )
}

s33_ls_resolve <- function(env) {
  if (!exists(S33_LS_FUN, envir = env, inherits = FALSE)) {
    stop("The Lee-Strazicich entry point '", S33_LS_FUN, "' is not defined by the engine at '",
         S33_LS_REPO, "'.\n",
         "Run US_S33B with --probe to list the callables the repo actually exposes,\n",
         "then set LS_FUN to the correct name. Do NOT substitute a local reimplementation:\n",
         "S01/S02/S03 bind this dependency and P05 forbids hand-rolling the test.")
  }
  fmls <- names(formals(get(S33_LS_FUN, envir = env)))
  needed <- c("y", "model", "breaks", "lags", "method", "pn", "print.results")
  missing <- setdiff(needed, fmls)
  if (length(missing)) {
    stop("'", S33_LS_FUN, "' at '", S33_LS_REPO, "' no longer has the expected signature.\n",
         "Missing formals: ", paste(missing, collapse = ", "), ".\n",
         "The upstream engine changed; re-pin section 9 of US_S33_break_aware_common.R ",
         "against the new signature before trusting any Step 2 ledger.")
  }
  S33_LS_FUN
}

# Map the protocol's model labels onto ur.ls()'s vocabulary.
#   "A" -> "crash": break in intercept only.
#   "C" -> "break": break in intercept AND trend. This is the S01 Sec.2 Step 2 model,
#                   since Z_t there carries both D_t and DT_t.
s33_ls_model_arg <- function(model) {
  switch(as.character(model),
         A = "crash", crash = "crash",
         C = "break", `break` = "break",
         stop("unknown Lee-Strazicich model label: ", model,
              " (expected 'A'/'crash' or 'C'/'break')"))
}

# Critical values for a given (model, breaks, break location) triple, drawn from the
# transcribed S33_LS_CVAL tables. Returns the three quantiles plus a `basis` string
# naming the exact table used, so every ledger row is self-documenting.
s33_ls_cval <- function(model, breaks, lambda1 = NA_real_, lambda2 = NA_real_) {
  m <- s33_ls_model_arg(model)
  na_out <- function(basis) c(crit_1 = NA_real_, crit_5 = NA_real_, crit_10 = NA_real_,
                              basis = basis)

  if (breaks == 1L && m == "crash") {
    v <- S33_LS_CVAL$crash_1
    return(c(v, basis = "Model A one break; invariant to break location"))
  }

  if (breaks == 1L && m == "break") {
    if (!is.finite(lambda1)) return(na_out("Model C one break; lambda unavailable"))
    # Symmetric about lambda and 1 - lambda: fold into [0, 0.5], then interpolate on the
    # 0.1..0.5 grid (the engine's own comment sanctions interpolation).
    lam <- min(lambda1, 1 - lambda1)
    tab <- S33_LS_CVAL$break_1
    out <- c(
      crit_1  = stats::approx(tab$lambda, tab$crit_1,  xout = lam, rule = 2)$y,
      crit_5  = stats::approx(tab$lambda, tab$crit_5,  xout = lam, rule = 2)$y,
      crit_10 = stats::approx(tab$lambda, tab$crit_10, xout = lam, rule = 2)$y
    )
    return(c(out, basis = sprintf("Model C one break; interpolated at folded lambda=%.3f", lam)))
  }

  if (breaks == 2L && m == "crash") {
    v <- S33_LS_CVAL$crash_2
    return(c(v, basis = "Model A two breaks; LM_tau row, invariant to break location"))
  }

  if (breaks == 2L && m == "break") {
    tab <- S33_LS_CVAL$break_2_tau
    if (!is.finite(lambda1) || !is.finite(lambda2)) {
      v <- S33_LS_CVAL$break_2_dgp
      return(c(v, basis = "Model C two breaks; DGP-invariant fallback (lambdas unavailable)"))
    }
    i <- which.min(abs(tab$lambda_1 - lambda1))
    j <- which.min(abs(tab$lambda_2 - lambda2))
    got <- c(crit_1  = tab$crit_1[i, j],
             crit_5  = tab$crit_5[i, j],
             crit_10 = tab$crit_10[i, j])
    if (anyNA(got)) {
      # lambda_1 >= lambda_2 cell: the location-dependent table is undefined there.
      v <- S33_LS_CVAL$break_2_dgp
      return(c(v, basis = sprintf(
        "Model C two breaks; DGP-invariant fallback (tau table undefined at lambda_1=%.2f, lambda_2=%.2f)",
        tab$lambda_1[i], tab$lambda_2[j])))
    }
    return(c(got, basis = sprintf(
      "Model C two breaks; tau table at nearest grid point lambda_1=%.2f, lambda_2=%.2f",
      tab$lambda_1[i], tab$lambda_2[j])))
  }

  na_out("no critical-value table for this model/breaks combination")
}

# Normalise ur.ls()'s return into a flat row.
#   res[[1]] is the named results list: "t-stat", "First break", ["Second break"], "Runtime".
#   res[[2]] is the fitted break regression (a summary.lm).
# Break entries are POSITIONS in y; `years` converts them to calendar years.
# If the shape is not what this adapter was pinned against, the raw object is dumped to
# disk and the verdict is left as PENDING_MANUAL_READ rather than guessed at.
s33_ls_normalise <- function(res, years = NULL, dump_path = NULL) {
  fail <- function() {
    if (!is.null(dump_path)) {
      s33_ensure_dir(dirname(dump_path))
      utils::capture.output(print(res), file = dump_path)
    }
    list(lm_statistic = NA_real_, break_positions = NA_character_,
         break_years = NA_character_, lambda1 = NA_real_, lambda2 = NA_real_,
         selected_lag = NA_integer_, normalised = FALSE)
  }

  if (!is.list(res) || length(res) < 1L || !is.list(res[[1]])) return(fail())
  r <- res[[1]]
  if (!("t-stat" %in% names(r))) return(fail())

  stat <- suppressWarnings(as.numeric(r[["t-stat"]])[1])
  # ur.ls() seeds its running minimum at 1000; a value that never moved means the
  # break search found nothing usable.
  if (!is.finite(stat) || stat >= 999) return(fail())

  pos <- c(r[["First break"]], r[["Second break"]])
  pos <- suppressWarnings(as.integer(pos[!vapply(pos, is.null, logical(1))]))
  pos <- pos[is.finite(pos)]

  n <- if (!is.null(years)) length(years) else NA_integer_
  yrs <- if (!is.null(years) && length(pos)) years[pos] else integer(0)
  lam <- if (is.finite(n) && length(pos)) pos / n else numeric(0)

  # GTOS lag count is recoverable from the fitted break regression the same way the
  # engine prints it; failure here is cosmetic, so it degrades to NA.
  lagk <- tryCatch({
    dc <- attr(stats::delete.response(stats::terms(res[[2]])), "dataClasses")
    as.integer(substring(unlist(dc[3]), 9)) - 1L
  }, error = function(e) NA_integer_)

  list(
    lm_statistic    = stat,
    break_positions = if (length(pos)) paste(pos, collapse = ";") else NA_character_,
    break_years     = if (length(yrs)) paste(yrs, collapse = ";") else NA_character_,
    lambda1         = if (length(lam) >= 1L) lam[1] else NA_real_,
    lambda2         = if (length(lam) >= 2L) lam[2] else NA_real_,
    selected_lag    = if (length(lagk) && is.finite(lagk)) lagk else NA_integer_,
    normalised      = TRUE
  )
}

# Run the mandated engine once. `model` is "A"/"C" in protocol terms; `trim` is passed
# through to ur.ls()'s `pn`; `max_lag` is the GTOS maximum. method and print.results are
# always supplied as single strings -- see note (b) at the head of this section.
s33_ls_run <- function(env, fun_name, y, years = NULL, model = "C", breaks = 2L,
                       max_lag = 4L, trim = 0.15, dump_path = NULL) {
  blank <- list(lm_statistic = NA_real_, break_positions = NA_character_,
                break_years = NA_character_, lambda1 = NA_real_, lambda2 = NA_real_,
                selected_lag = NA_integer_, normalised = FALSE)

  if (anyNA(y)) {
    return(c(blank, list(error = "ur.ls() rejects NAs in y; window contains missing values")))
  }

  fun <- get(fun_name, envir = env)
  res <- tryCatch(
    fun(y = as.vector(y),
        model = s33_ls_model_arg(model),
        breaks = as.integer(breaks),
        lags = as.integer(max_lag),
        method = "GTOS",
        pn = trim,
        print.results = "silent"),
    error = function(e) e)

  if (inherits(res, "error")) {
    return(c(blank, list(error = conditionMessage(res))))
  }
  out <- s33_ls_normalise(res, years = years, dump_path = dump_path)
  out$error <- if (out$normalised) NA_character_ else "unrecognised return shape; raw object dumped"
  out
}

s33_joint_wald <- function(fit, names_to_test) {
  all_names <- names(fit$theta.all)
  if (is.null(all_names)) return(list(F_stat = NA_real_, p_val = NA_real_))
  idxs <- integer(0)
  for (nm in names_to_test) {
    idx <- which(all_names == paste0("S.", nm))
    if (length(idx) == 0) {
      idx <- which(all_names == nm)
    }
    if (length(idx) == 1) {
      idxs <- c(idxs, idx)
    }
  }
  if (length(idxs) == 0) {
    return(list(F_stat = NA_real_, p_val = NA_real_))
  }
  coef <- fit$theta.all[idxs]
  
  scale_factor <- fit$omega.u.v
  if (is.null(scale_factor) || is.na(scale_factor) || scale_factor <= 0) {
    scale_factor <- cointReg::getLongRunVar(fit$u.plus, kernel = fit$kernel, bandwidth = fit$bandwidth$number)$long.run
  }
  vcov <- fit$varmat[idxs, idxs, drop = FALSE] * scale_factor
  
  W <- tryCatch({
    as.numeric(t(coef) %*% solve(vcov, coef))
  }, error = function(e) NA_real_)
  if (is.na(W) || !is.finite(W)) {
    return(list(F_stat = NA_real_, p_val = NA_real_))
  }
  q <- length(idxs)
  F_stat <- W / q
  T_obs <- length(fit$u.plus)
  k_reg <- length(fit$theta.all)
  df2 <- max(1, T_obs - k_reg)
  p_val <- stats::pf(F_stat, df1 = q, df2 = df2, lower.tail = FALSE)
  list(F_stat = F_stat, p_val = p_val)
}

message("US_S33_break_aware_common.R loaded. Output root: ", S33_OUT_ROOT)
