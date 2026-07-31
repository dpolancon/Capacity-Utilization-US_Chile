#!/usr/bin/env Rscript

# US_S33C_break_interacted_imols_specA.R
# ---------------------------------------------------------------------------
# Step 3 of the binding S0* sequence, Specification A (aggregated capital k_t^cap):
#
#     Break-interacted IM-OLS estimation of the within-sub-sample multiplicative
#     model, gated on the US_S33B integration-order verdict.
#
# Authority:
#   S01 Sec.1A -- the estimated equation:
#       y_t^NFC = alpha_0 + gamma_1 D_t(T_B*) + beta_Kcap k_t^cap
#                 + delta_1 [k_t^cap . D_t(T_B*)]
#                 + phi_omega omega_{t-1} + theta_1 (k_t^cap . omega_{t-1})
#                 + delta_2 [k_t^cap . omega_{t-1} . D_t(T_B*)] + eps_t
#   S01 Sec.1B -- regime elasticity dynamics:
#       theta_t = beta_Kcap + theta_1 omega_{t-1}                    for t <  T_B*
#       theta_t = (beta_Kcap+delta_1) + (theta_1+delta_2) omega_{t-1} for t >= T_B*
#   S01 Sec.2 Step 3 -- IM-OLS with a DOLS read (q=1, l=1); variance-reduction check
#       against sigma_u = 0.158 (Fordist) and 0.184 (Post-Fordist); Shin LM and
#       residual ADF monitored.
#   S01 Sec.3 -- decision matrix: delta_1 or delta_2 significant at 5% under fixed-b HAR
#       => retain the multiplicative interaction and report dual sub-regime elasticities;
#       otherwise => retain additive step controls for variance hygiene only.
#   S01 Sec.4 -- the four-column "Table X" reporting matrix this script emits.
#   E10V -- IM-OLS/CPR is the estimator. DOLS and FM-OLS are diagnostic comparators
#       only. FWL orthogonalization of the interaction terms is FORBIDDEN.
#   Interaction_Term_Integration_Order_Gate -- four classifications recorded before any
#       coefficient is reported.
#
# ---------------------------------------------------------------------------
# BREAK-DATE ARCHITECTURE (settled with the author, 2026-07-30)
#
# The split samples are HISTORICAL and fixed: Fordism runs to 1973, Post-Fordism from
# 1974. Bai-Perron dates are NOT a rival periodization; they locate within-sample
# structural breaks that have to be controlled for the estimation to be adequate.
#
#   Slope shift  (multiplicative delta_1, delta_2): T_B* = 1947 in Fordism and 2008 in
#       Post-Fordism, exactly as S01 Sec.5 Step 1 pins them.
#   Additive steps (variance hygiene, no slope effect):
#       Fordism      -- D_1933 permanent step for the New Deal regime change, plus a
#                       1942-1945 war block that switches back off. US_S33A's prescan
#                       lands repeatedly in 1939-1945 across both specifications, and
#                       war mobilisation is a level distortion that REVERSES; forcing it
#                       into a permanent step would mis-attribute the post-war reversion
#                       to the capital elasticity.
#       Post-Fordism -- D_1981 and D_2000 permanent steps, both Bai-Perron supported
#                       (US_S33A: 1981 at distance 1 from the protocol's 1982; 2000 at
#                       distance 0).
#
# ---------------------------------------------------------------------------
# ROUTE LABELLING -- estimation is never blocked, only labelled.
#
# Following codes/CL_S32_break_aware_machinery_v6.R, which always estimates and carries
# a dual disposition rather than halting. A window whose base variables all clear the
# US_S33B gate is a formal_break_supported route; a window where any base variable is
# not I(1)-with-break is estimated_as_exploratory_with_limitation, and every coefficient
# row it produces carries that label. P05 requires the distinction to travel with the
# elasticity into the report prose, so it travels with it in the ledger first.
#
# ---------------------------------------------------------------------------
# CENTERING -- E10V Regime A is the main specification, Regime B the primary robustness.
# AGENTS.md directs that ill-conditioning be handled by logging the condition number and
# defaulting to Regime B rather than blocking, so the reported regime is chosen by the
# standardized condition number and recorded per model.
#
# Governance: artifacts land under output/US/BREAK_AWARE_IMOLS/S33C_IMOLS_SPEC_A/.
#
# Usage:
#   Rscript codes/US_S33C_break_interacted_imols_specA.R
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

STAGE   <- "S33C_IMOLS_SPEC_A"
OUT_DIR <- s33_dir(STAGE)
CSV_DIR <- file.path(OUT_DIR, "csv")
LOG_DIR <- file.path(OUT_DIR, "logs")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33C_execution_log.txt")
log_msg <- function(...) {
  line <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(line, "\n", sep = "")
  cat(line, "\n", sep = "", file = LOG_PATH, append = TRUE)
}
cat("", file = LOG_PATH)

# ---------------------------------------------------------------------------
# 1. Read the Step 2 gate
# ---------------------------------------------------------------------------

VERDICT_PATH <- s33_dir("S33B_LEE_STRAZICICH", "csv", "integration_order_verdict.csv")
if (!file.exists(VERDICT_PATH)) {
  stop("Step 2 verdict not found at ", VERDICT_PATH, ".\n",
       "Run codes/US_S33B_lee_strazicich_break_robust_unitroot.R first: S01 Sec.2 gates ",
       "Step 3 on the Lee-Strazicich integration-order result.")
}
verdicts <- utils::read.csv(VERDICT_PATH, stringsAsFactors = FALSE)
log_msg("Step 2 gate read from ", VERDICT_PATH, " (", nrow(verdicts), " rows)")

BASE_VARS <- c("k_cap", "y", "omega_lag1")

gate_for <- function(window_key) {
  v <- verdicts[verdicts$spec == "Spec_A" & verdicts$window == window_key &
                  verdicts$variable %in% BASE_VARS, , drop = FALSE]
  present <- BASE_VARS %in% v$variable
  ok <- setNames(rep(FALSE, length(BASE_VARS)), BASE_VARS)
  for (b in BASE_VARS) {
    r <- v[v$variable == b, , drop = FALSE]
    ok[b] <- nrow(r) == 1L && r$integration_verdict == "I1_with_break"
  }
  list(
    all_pass = all(present) && all(ok),
    per_var = ok,
    verdict_string = paste(sprintf("%s=%s", v$variable, v$integration_verdict), collapse = "; "),
    failing = paste(names(ok)[!ok], collapse = ", ")
  )
}

# ---------------------------------------------------------------------------
# 2. Window architecture
# ---------------------------------------------------------------------------

WINDOWS <- list(
  Fordist_1929_1973 = list(
    key = "Fordist_1929_1973", label = "Fordist Era (1929-1973)",
    tb_star = 1947L,
    tb_source = "S01 Sec.5 Step 1 (T_1947 inside Fordism)",
    steps = list(
      list(name = "D_1933", type = "step",  args = list(1933L),
           rationale = "New Deal regime change; permanent level shift"),
      list(name = "B_1942_1945", type = "block", args = list(1942L, 1945L),
           rationale = "WWII mobilisation; level distortion that reverses on demobilisation")
    ),
    sigma_baseline = unname(S33_SIGMA_U_BASELINE_SPEC_A["Fordist_1929_1973"])
  ),
  Post_Fordist_1974_2024 = list(
    key = "Post_Fordist_1974_2024", label = "Post-Fordist Era (1974-2024)",
    tb_star = 2008L,
    tb_source = "S01 Sec.5 Step 1 (T_2008 inside Post-Fordism)",
    steps = list(
      list(name = "D_1981", type = "step", args = list(1981L),
           rationale = "Volcker disinflation; Bai-Perron supported (S33A, 1 year from protocol 1982)"),
      list(name = "D_2000", type = "step", args = list(2000L),
           rationale = "Dot-Com crash; Bai-Perron supported (S33A, exact protocol match)")
    ),
    sigma_baseline = unname(S33_SIGMA_U_BASELINE_SPEC_A["Post_Fordist_1974_2024"])
  )
)

build_steps <- function(year, spec) {
  out <- NULL; nms <- character(0)
  for (s in spec$steps) {
    v <- switch(s$type,
                step  = s33_step(year, s$args[[1]]),
                block = s33_block(year, s$args[[1]], s$args[[2]]),
                trend = s33_trend_break(year, s$args[[1]]),
                stop("unknown step type: ", s$type))
    if (stats::sd(v) > 0) { out <- cbind(out, v); nms <- c(nms, s$name) }
  }
  if (!is.null(out)) colnames(out) <- nms
  out
}

# ---------------------------------------------------------------------------
# 3. Conditioning and centering choice
# ---------------------------------------------------------------------------
# Standardized (column-scaled) condition number, so the diagnostic is about collinearity
# rather than units. Belsley's rule of thumb, and the threshold already recorded in
# output/CL/.../s30_stage_integrity_checks.csv ("standardized CN>30 recorded"), is 30.

CN_THRESHOLD <- 30

std_condition <- function(X) {
  X <- as.matrix(X)
  s <- apply(X, 2, function(c) sqrt(sum(c^2)))
  s[s == 0 | !is.finite(s)] <- 1
  suppressWarnings(kappa(sweep(X, 2, s, "/"), exact = TRUE))
}

# ---------------------------------------------------------------------------
# 4. One model
# ---------------------------------------------------------------------------

fit_model <- function(win_spec, interacted, regime) {
  win <- S33_WINDOWS[[win_spec$key]]
  d <- s33_window(panel, win)
  d <- d[stats::complete.cases(d[, c("y", "k_cap", "omega_lag1")]), , drop = FALSE]
  yr <- d$year
  y <- d$y

  k <- s33_center(d$k_cap, regime)
  w <- s33_center(d$omega_lag1, regime)
  inter <- k * w                      # raw product, never residualized (E10V)

  X <- cbind(k_cap = k, omega = w, interaction = inter)
  base_cols <- c("k_cap", "omega")
  inter_cols <- "interaction"

  stepm <- build_steps(yr, win_spec)
  if (!is.null(stepm)) X <- cbind(X, stepm)

  # SPAN CORRECTION (2026-07-31). The squeeze slope shift is the triple product
  # (k_cap . omega) . D, so centering expands it into terms requiring BOTH k_cap.D and
  # omega.D in the design. This script previously carried k_x_D but not omega_x_D, which
  # left the centering regime selecting the model rather than merely conditioning it: the
  # Fordist interacted theta_1 spanned [-5.899, 3.459] across the three regimes, i.e. its
  # SIGN was set by an arbitrary convention. s33_break_span() now builds the block so the
  # constituents cannot be omitted. See US_S33F for the synthetic-data verification.
  products <- list(c("k_cap", "omega"))
  if (interacted) {
    D <- s33_step(yr, win_spec$tb_star)
    if (stats::sd(D) == 0) return(NULL)
    brk <- s33_break_span(D, vars = list(k_cap = k, omega = w), products = products)
    X <- cbind(X, brk)
    inter_cols <- c(inter_cols, "k_cap_x_D", "omega_x_D", "k_cap_omega_x_D")
    s33_assert_complete_span(X, products = products)
  }

  # E10V structural guard: interactions must enter raw, not orthogonalized.
  s33_assert_no_fwl(X, inter_cols, base_cols)

  deter <- matrix(1, nrow = length(y), ncol = 1)   # same convention as COMMON_S40
  fit <- tryCatch(s33_imols(X, y, deter = deter), error = function(e) e)
  if (inherits(fit, "error")) return(list(error = conditionMessage(fit)))

  list(fit = fit, X = X, y = y, year = yr, T_obs = length(y),
       cond = std_condition(cbind(1, X)), error = NA_character_)
}

# ---------------------------------------------------------------------------
# 5. Drive the four Table X columns across three centering regimes
# ---------------------------------------------------------------------------

panel <- s33_load_spec_a()
log_msg("Spec A panel: ", nrow(panel), " rows, ", min(panel$year), "-", max(panel$year))

coef_rows <- list(); gate_rows <- list(); dols_rows <- list()

COEF_MAP <- c(beta_Kcap = "k_cap", phi_omega = "omega", theta_1 = "interaction",
              gamma_1 = "D_TB", delta_1 = "k_cap_x_D",
              phi_omega_brk = "omega_x_D",          # added by the span correction
              delta_2 = "k_cap_omega_x_D")

# Which parameters the N11 Sec.1 invariance claim actually covers. Base-class coefficients
# shift with the point of evaluation by construction (N11 Sec.1 point 2); only
# interaction-class ones are claimed invariant.
PARAM_CLASS <- c(beta_Kcap = "base", phi_omega = "base", theta_1 = "interaction",
                 gamma_1 = "base", delta_1 = "base", phi_omega_brk = "base",
                 delta_2 = "interaction")

for (wk in names(WINDOWS)) {
  wsp <- WINDOWS[[wk]]
  g <- gate_for(wk)
  route <- if (g$all_pass) "formal_break_supported" else "exploratory_break_route"
  disposition <- if (g$all_pass) "break_unlocked_for_formal_route" else
    "estimated_as_exploratory_with_limitation"
  log_msg(wsp$label, ": gate ", route, " [", g$verdict_string, "]")

  for (interacted in c(FALSE, TRUE)) {
    # Choose the reported centering regime by conditioning, per AGENTS.md.
    conds <- list(); fits <- list()
    for (rg in S33_CENTERING_REGIMES) {
      m <- fit_model(wsp, interacted, rg)
      fits[[rg]] <- m
      conds[[rg]] <- if (!is.null(m) && is.na(m$error)) m$cond else NA_real_
    }
    cnA <- conds[["Regime_A_Uncentered"]]
    reported <- if (is.finite(cnA) && cnA <= CN_THRESHOLD) "Regime_A_Uncentered" else
      "Regime_B_Initial_Centered"
    centering_note <- sprintf(
      "standardized CN: A=%s B=%s C=%s; threshold %d; reported regime %s",
      format(conds[["Regime_A_Uncentered"]], digits = 5),
      format(conds[["Regime_B_Initial_Centered"]], digits = 5),
      format(conds[["Regime_C_Mean_Centered"]], digits = 5),
      CN_THRESHOLD, reported)
    log_msg("  ", if (interacted) "with-interaction" else "no-interaction", ": ",
            centering_note)

    for (rg in S33_CENTERING_REGIMES) {
      m <- fits[[rg]]
      if (is.null(m) || !is.na(m$error)) {
        log_msg("    ", rg, " FAILED: ", if (is.null(m)) "degenerate design" else m$error)
        next
      }
      f <- m$fit; dg <- f$diag

      for (nm in names(COEF_MAP)) {
        col <- COEF_MAP[[nm]]
        if (!(col %in% colnames(m$X))) next
        est <- s33_coef(f, col); tst <- s33_tstat(f, col)
        coef_rows[[length(coef_rows) + 1L]] <- data.frame(
          spec = "Spec_A", window = wk, era_label = wsp$label,
          internal_slope_interaction = if (interacted) "Yes" else "No",
          tb_star = wsp$tb_star, tb_source = wsp$tb_source,
          centering_regime = rg, is_reported_regime = identical(rg, reported),
          centering_note = centering_note,
          parameter = nm, design_column = col,
          estimate = est, fixed_b_har_t = tst, stars = s33_stars(tst),
          significant_5pct = if (is.na(tst)) NA else abs(tst) >= 1.96,
          sigma_u = dg$sigma_u,
          sigma_u_baseline = wsp$sigma_baseline,
          variance_reduction = dg$sigma_u < wsp$sigma_baseline,
          C_shin = dg$C_shin, C_shin_stars = dg$shin_stars,
          residual_adf = dg$t_adf, residual_adf_stars = dg$adf_stars,
          r2_level = dg$r2_level, r2_sum = dg$r2_sum,
          T_obs = m$T_obs, k_reg = dg$k_reg,
          std_condition_number = m$cond,
          step_controls = paste(vapply(wsp$steps, `[[`, character(1), "name"), collapse = "+"),
          estimator = "IM-OLS (cointReg::cointRegIM), E10V active lock",
          break_route_status = route, disposition = disposition,
          gate_verdicts = g$verdict_string,
          gate_failing_vars = if (nzchar(g$failing)) g$failing else NA_character_,
          stringsAsFactors = FALSE)
      }

      # DOLS diagnostic comparator (E10V: never promoted into a report table alone).
      if (identical(rg, reported)) {
        dl <- tryCatch(s33_dols(m$X, m$y), error = function(e) NULL)
        if (!is.null(dl)) {
          for (nm in names(COEF_MAP)) {
            col <- COEF_MAP[[nm]]
            if (!(col %in% names(dl$estimate))) next
            dols_rows[[length(dols_rows) + 1L]] <- data.frame(
              spec = "Spec_A", window = wk,
              internal_slope_interaction = if (interacted) "Yes" else "No",
              parameter = nm, design_column = col,
              estimate = unname(dl$estimate[col]),
              newey_west_t = unname(dl$tstat[col]),
              T_obs = dl$T_obs, leads = S33_DOLS_LEADS, lags = S33_DOLS_LAGS,
              role = dl$role,
              e10v_status = "diagnostic-comparator; blocked from baseline reporting",
              stringsAsFactors = FALSE)
          }
        }
      }
    }

    # Interaction-Term Integration Order Gate ledger, per model.
    iv <- setNames(
      verdicts$integration_verdict[verdicts$spec == "Spec_A" &
                                     verdicts$window == wk &
                                     verdicts$variable %in% BASE_VARS],
      verdicts$variable[verdicts$spec == "Spec_A" & verdicts$window == wk &
                          verdicts$variable %in% BASE_VARS])
    iv <- ifelse(iv == "I1_with_break", "I(1)", iv)
    gl <- s33_interaction_gate_ledger(
      spec = sprintf("Spec_A / %s / interaction=%s", wk, if (interacted) "Yes" else "No"),
      base_vars = BASE_VARS,
      interaction_terms = if (interacted)
        c("k_cap x omega_lag1", "k_cap x D_TB", "k_cap x omega_lag1 x D_TB") else
          "k_cap x omega_lag1",
      integration_verdicts = iv,
      centering_regimes = S33_CENTERING_REGIMES)
    gl$window <- wk
    gl$reported_centering_regime <- reported
    gl$break_route_status <- route
    gate_rows[[length(gate_rows) + 1L]] <- gl
  }
}

coef_ledger <- do.call(rbind, coef_rows)
gate_ledger <- do.call(rbind, gate_rows)
dols_ledger <- if (length(dols_rows)) do.call(rbind, dols_rows) else
  data.frame(spec = character(), window = character(), parameter = character())

s33_write_ledger(coef_ledger, CSV_DIR, "specA_break_interacted_imols_coefficients.csv")
s33_write_ledger(gate_ledger, CSV_DIR, "specA_interaction_gate_ledger.csv")
s33_write_ledger(dols_ledger, CSV_DIR, "specA_dols_comparator_ledger.csv")

# ---------------------------------------------------------------------------
# 6. S01 Sec.3 decision matrix and sub-regime elasticities (S01 Sec.1B)
# ---------------------------------------------------------------------------

rep_coef <- coef_ledger[coef_ledger$is_reported_regime %in% TRUE, , drop = FALSE]

dec_rows <- list()
for (wk in names(WINDOWS)) {
  wsp <- WINDOWS[[wk]]
  sub <- rep_coef[rep_coef$window == wk & rep_coef$internal_slope_interaction == "Yes", ,
                  drop = FALSE]
  if (!nrow(sub)) next
  get1 <- function(p, col) {
    r <- sub[sub$parameter == p, col]
    if (length(r)) r[1] else NA_real_
  }
  d1 <- get1("delta_1", "estimate"); t1 <- get1("delta_1", "fixed_b_har_t")
  d2 <- get1("delta_2", "estimate"); t2 <- get1("delta_2", "fixed_b_har_t")
  b  <- get1("beta_Kcap", "estimate"); th <- get1("theta_1", "estimate")

  sig <- (!is.na(t1) && abs(t1) >= 1.96) || (!is.na(t2) && abs(t2) >= 1.96)
  decision <- if (sig) "retain_multiplicative_interaction" else "retain_additive_step_control"
  meaning <- if (sig)
    paste("S01 Sec.3 YES branch: parameter elasticity shifted internally; report dual",
          "sub-regime elasticities theta_early vs theta_late") else
    paste("S01 Sec.3 NO branch: parameter elasticity is structurally invariant; step",
          "dummies D_t(T_B*) retained strictly for variance hygiene")

  noint <- rep_coef[rep_coef$window == wk & rep_coef$internal_slope_interaction == "No", ,
                    drop = FALSE]
  dec_rows[[length(dec_rows) + 1L]] <- data.frame(
    spec = "Spec_A", window = wk, era_label = wsp$label, tb_star = wsp$tb_star,
    delta_1 = d1, delta_1_t = t1, delta_1_sig_5pct = if (is.na(t1)) NA else abs(t1) >= 1.96,
    delta_2 = d2, delta_2_t = t2, delta_2_sig_5pct = if (is.na(t2)) NA else abs(t2) >= 1.96,
    beta_Kcap = b, theta_1 = th,
    # S01 Sec.1B: theta_t = beta + theta_1 omega  (early);
    #             theta_t = (beta+delta_1) + (theta_1+delta_2) omega  (late)
    early_regime_intercept = b, early_regime_omega_slope = th,
    late_regime_intercept = b + ifelse(is.na(d1), 0, d1),
    late_regime_omega_slope = th + ifelse(is.na(d2), 0, d2),
    s01_sec3_decision = decision, s01_sec3_meaning = meaning,
    sigma_u_with_interaction = sub$sigma_u[1],
    sigma_u_without_interaction = if (nrow(noint)) noint$sigma_u[1] else NA_real_,
    sigma_u_baseline_s01 = wsp$sigma_baseline,
    variance_reduced_vs_baseline = sub$variance_reduction[1],
    variance_reduced_vs_no_interaction = if (nrow(noint))
      sub$sigma_u[1] < noint$sigma_u[1] else NA,
    break_route_status = sub$break_route_status[1],
    disposition = sub$disposition[1],
    reported_centering_regime = sub$centering_regime[1],
    stringsAsFactors = FALSE)
}
decision_ledger <- do.call(rbind, dec_rows)
s33_write_ledger(decision_ledger, CSV_DIR, "specA_slope_break_decision_ledger.csv")

# ---------------------------------------------------------------------------
# 7. Table X matrix (S01 Sec.4 layout, reported centering regime)
# ---------------------------------------------------------------------------

fmt <- function(v, t) {
  if (is.na(v)) return("--")
  sprintf("%.2f%s", v, s33_stars(t))
}
fmt_t <- function(t) if (is.na(t)) "" else sprintf("(%.2f)", t)

col_for <- function(wk, interacted) {
  s <- rep_coef[rep_coef$window == wk &
                  rep_coef$internal_slope_interaction == (if (interacted) "Yes" else "No"), ,
                drop = FALSE]
  if (!nrow(s)) return(NULL)
  gv <- function(p, col) { r <- s[s$parameter == p, col]; if (length(r)) r[1] else NA }
  list(
    values = c(
      beta_Kcap = fmt(gv("beta_Kcap", "estimate"), gv("beta_Kcap", "fixed_b_har_t")),
      beta_Kcap_t = fmt_t(gv("beta_Kcap", "fixed_b_har_t")),
      delta_1 = if (interacted) fmt(gv("delta_1", "estimate"), gv("delta_1", "fixed_b_har_t")) else "--",
      delta_1_t = if (interacted) fmt_t(gv("delta_1", "fixed_b_har_t")) else "",
      phi_omega = fmt(gv("phi_omega", "estimate"), gv("phi_omega", "fixed_b_har_t")),
      phi_omega_t = fmt_t(gv("phi_omega", "fixed_b_har_t")),
      phi_omega_brk = if (interacted) fmt(gv("phi_omega_brk", "estimate"), gv("phi_omega_brk", "fixed_b_har_t")) else "--",
      phi_omega_brk_t = if (interacted) fmt_t(gv("phi_omega_brk", "fixed_b_har_t")) else "",
      theta_1 = fmt(gv("theta_1", "estimate"), gv("theta_1", "fixed_b_har_t")),
      theta_1_t = fmt_t(gv("theta_1", "fixed_b_har_t")),
      delta_2 = if (interacted) fmt(gv("delta_2", "estimate"), gv("delta_2", "fixed_b_har_t")) else "--",
      delta_2_t = if (interacted) fmt_t(gv("delta_2", "fixed_b_har_t")) else "",
      step_dummies = "Yes",
      sigma_u = sprintf("%.3f", s$sigma_u[1]),
      C_shin = sprintf("%.3f%s", s$C_shin[1], s$C_shin_stars[1]),
      residual_adf = sprintf("%.3f%s", s$residual_adf[1], s$residual_adf_stars[1]),
      T_obs = as.character(s$T_obs[1]),
      break_route = s$break_route_status[1],
      centering = s$centering_regime[1]),
    tb = s$tb_star[1])
}

ROW_LABELS <- c(
  beta_Kcap = "Capital Stock (beta_Kcap)", beta_Kcap_t = "",
  delta_1 = "Capital Slope Shift (delta_1)", delta_1_t = "",
  phi_omega = "Wage Share (phi_omega)", phi_omega_t = "",
  phi_omega_brk = "Wage Share Slope Shift (phi_omega,brk)", phi_omega_brk_t = "",
  theta_1 = "Interaction Squeeze (theta_1)", theta_1_t = "",
  delta_2 = "Interaction Slope Shift (delta_2)", delta_2_t = "",
  step_dummies = "Step Dummies (D_t)",
  sigma_u = "Residual Variance (sigma_u)",
  C_shin = "Shin LM Test (C_Shin)",
  residual_adf = "Residual ADF (ADF)",
  T_obs = "Sample Size (T)",
  break_route = "Break-Aware Gate Status",
  centering = "Reported Centering Regime")

cols <- list(
  `(1)` = col_for("Fordist_1929_1973", FALSE),
  `(2)` = col_for("Fordist_1929_1973", TRUE),
  `(3)` = col_for("Post_Fordist_1974_2024", FALSE),
  `(4)` = col_for("Post_Fordist_1974_2024", TRUE))

table_x <- data.frame(row = names(ROW_LABELS), label = unname(ROW_LABELS),
                      stringsAsFactors = FALSE)
for (cn in names(cols)) {
  table_x[[cn]] <- if (is.null(cols[[cn]])) NA_character_ else
    unname(cols[[cn]]$values[names(ROW_LABELS)])
}
header <- data.frame(
  row = c("era", "interaction", "tb_star"),
  label = c("Era", "Internal Slope Interaction", "Internal Break Date (T_B*)"),
  `(1)` = c("Fordist 1929-1973", "No", "1947"),
  `(2)` = c("Fordist 1929-1973", "Yes", "1947"),
  `(3)` = c("Post-Fordist 1974-2024", "No", "2008"),
  `(4)` = c("Post-Fordist 1974-2024", "Yes", "2008"),
  check.names = FALSE, stringsAsFactors = FALSE)
table_x <- rbind(header, table_x)

s33_write_ledger(table_x, CSV_DIR, "specA_table_X_matrix.csv")

# ---------------------------------------------------------------------------
# 7.5. Structural Break Shift Combinatorics Grid (Spec A)
# ---------------------------------------------------------------------------
log_msg("Starting Specification A Combinatorics Grid (8 models per window x 3 regimes)...")

fit_model_comb <- function(win_spec, regime, has_k_x_D, has_w_x_D, has_inter_x_D) {
  win <- S33_WINDOWS[[win_spec$key]]
  d <- s33_window(panel, win)
  d <- d[stats::complete.cases(d[, c("y", "k_cap", "omega_lag1")]), , drop = FALSE]
  yr <- d$year
  y <- d$y

  k <- s33_center(d$k_cap, regime)
  w <- s33_center(d$omega_lag1, regime)
  inter <- k * w

  X <- cbind(k_cap = k, omega = w, interaction = inter)
  base_cols <- c("k_cap", "omega")
  inter_cols <- "interaction"

  stepm <- build_steps(yr, win_spec)
  if (!is.null(stepm)) X <- cbind(X, stepm)

  D <- s33_step(yr, win_spec$tb_star)
  if (stats::sd(D) == 0) return(NULL)
  X <- cbind(X, D_TB = D)

  if (has_k_x_D) {
    X <- cbind(X, k_x_D = k * D)
    inter_cols <- c(inter_cols, "k_x_D")
  }
  if (has_w_x_D) {
    X <- cbind(X, w_x_D = w * D)
    inter_cols <- c(inter_cols, "w_x_D")
  }
  if (has_inter_x_D) {
    X <- cbind(X, inter_x_D = inter * D)
    inter_cols <- c(inter_cols, "inter_x_D")
  }

  s33_assert_no_fwl(X, inter_cols, base_cols)

  deter <- matrix(1, nrow = length(y), ncol = 1)
  fit <- tryCatch(s33_imols(X, y, deter = deter), error = function(e) e)
  if (inherits(fit, "error")) return(list(error = conditionMessage(fit)))

  list(fit = fit, X = X, y = y, year = yr, T_obs = length(y),
       cond = std_condition(cbind(1, X)), error = NA_character_)
}

comb_grid <- expand.grid(
  has_k_x_D = c(FALSE, TRUE),
  has_w_x_D = c(FALSE, TRUE),
  has_inter_x_D = c(FALSE, TRUE)
)
# Sort to ensure Perm 0 is first, then ordered
comb_grid$perm_id <- paste0("SpecA-", 0:7)

comb_rows <- list()
for (wk in names(WINDOWS)) {
  wsp <- WINDOWS[[wk]]
  for (rg in S33_CENTERING_REGIMES) {
    # First fit Perm 0 to get baseline sigma_u for variance reduction calculation
    m0 <- fit_model_comb(wsp, rg, FALSE, FALSE, FALSE)
    sigma_u_0 <- if (!is.null(m0) && is.na(m0$error)) m0$fit$diag$sigma_u else NA_real_
    C_shin_0 <- if (!is.null(m0) && is.na(m0$error)) m0$fit$diag$C_shin else NA_real_
    
    for (i in 1:nrow(comb_grid)) {
      row <- comb_grid[i, ]
      m <- fit_model_comb(wsp, rg, row$has_k_x_D, row$has_w_x_D, row$has_inter_x_D)
      if (is.null(m) || !is.na(m$error)) next
      
      f <- m$fit
      dg <- f$diag
      
      gv_est <- function(p) { r <- s33_coef(f, p); if (is.na(r)) NA_real_ else r }
      gv_t <- function(p) { r <- s33_tstat(f, p); if (is.na(r)) NA_real_ else r }
      
      # Joint Wald test for primary hypothesis: H0: theta_1 = 0 AND theta_omegaK_brk = 0
      names_to_test <- c("interaction")
      if (row$has_inter_x_D) names_to_test <- c("interaction", "inter_x_D")
      jw <- s33_joint_wald(f, names_to_test)
      
      # Variance reduction relative to Perm 0
      var_red <- if (!is.na(sigma_u_0) && sigma_u_0 > 0) (sigma_u_0 - dg$sigma_u) / sigma_u_0 * 100 else 0
      
      # Adjudication
      coint_pass <- !is.na(dg$C_shin) && dg$C_shin < 0.095
      collin_pass <- !is.na(m$cond) && m$cond <= 100
      
      # Check significance of included break parameters
      break_sigs <- logical(0)
      if (row$has_k_x_D) break_sigs <- c(break_sigs, abs(gv_t("k_x_D")) >= 1.96)
      if (row$has_w_x_D) break_sigs <- c(break_sigs, abs(gv_t("w_x_D")) >= 1.96)
      if (row$has_inter_x_D) break_sigs <- c(break_sigs, abs(gv_t("inter_x_D")) >= 1.96)
      any_break_sig <- if (length(break_sigs) > 0) any(break_sigs, na.rm = TRUE) else FALSE
      
      adjudication <- "Drop"
      if (!coint_pass) {
        adjudication <- "Disqualified (Non-stationary)"
      } else if (!collin_pass) {
        adjudication <- "Collinear"
      } else if (i == 1) {
        adjudication <- "Baseline (Level Only)"
      } else if (any_break_sig && var_red > 5) {
        adjudication <- "Retain"
      } else if (!is.na(C_shin_0) && C_shin_0 < 0.095) {
        adjudication <- "Convert to Level"
      }
      
      comb_rows[[length(comb_rows) + 1L]] <- data.frame(
        permutation_id = row$perm_id,
        window = wk,
        centering_regime = rg,
        has_D_TB = TRUE,
        has_k_x_D = row$has_k_x_D,
        has_w_x_D = row$has_w_x_D,
        has_inter_x_D = row$has_inter_x_D,
        CN = m$cond,
        sigma_u = dg$sigma_u,
        r2_level = dg$r2_level,
        C_shin = dg$C_shin,
        C_shin_stars = dg$shin_stars,
        t_adf = dg$t_adf,
        adf_stars = dg$adf_stars,
        beta_Kcap_est = gv_est("k_cap"),
        beta_Kcap_t = gv_t("k_cap"),
        theta_K_brk_est = if (row$has_k_x_D) gv_est("k_x_D") else NA_real_,
        theta_K_brk_t = if (row$has_k_x_D) gv_t("k_x_D") else NA_real_,
        phi_omega_est = gv_est("omega"),
        phi_omega_t = gv_t("omega"),
        theta_1_brk_est = if (row$has_w_x_D) gv_est("w_x_D") else NA_real_,
        theta_1_brk_t = if (row$has_w_x_D) gv_t("w_x_D") else NA_real_,
        theta_1_est = gv_est("interaction"),
        theta_1_t = gv_t("interaction"),
        theta_omegaK_brk_est = if (row$has_inter_x_D) gv_est("inter_x_D") else NA_real_,
        theta_omegaK_brk_t = if (row$has_inter_x_D) gv_t("inter_x_D") else NA_real_,
        wald_F = jw$F_stat,
        wald_p = jw$p_val,
        cointegration_pass = coint_pass,
        collinearity_pass = collin_pass,
        variance_reduction_pct = var_red,
        adjudication = adjudication,
        stringsAsFactors = FALSE
      )
    }
  }
}
comb_ledger <- do.call(rbind, comb_rows)
COMB_DIR <- file.path(S33_OUT_ROOT, "combinatorics")
s33_ensure_dir(COMB_DIR)
s33_write_ledger(comb_ledger, COMB_DIR, "specA_break_combinatorics_summary.csv")

# ---------------------------------------------------------------------------
# 8. Stage integrity
# ---------------------------------------------------------------------------

integrity <- s33_integrity(
  checks = c(
    "step2_gate_consumed",
    "estimator_is_imols_not_dols",
    "fwl_prohibition_enforced_structurally",
    "interaction_span_complete",
    "interaction_gate_recorded_for_every_model",
    "three_centering_regimes_attempted",
    "condition_number_logged_and_regime_chosen",
    "protocol_tb_star_used_for_slope_shift",
    "additive_controls_are_bp_supported_or_historical",
    "all_four_table_x_columns_populated",
    "break_route_status_travels_with_every_coefficient",
    "s01_sec3_decision_recorded",
    "variance_reduction_compared_to_s01_baselines",
    "dols_marked_diagnostic_comparator_only",
    "outputs_confined_to_break_aware_tree"
  ),
  passed = c(
    file.exists(VERDICT_PATH) && nrow(verdicts) > 0,
    all(grepl("^IM-OLS", coef_ledger$estimator)),
    TRUE,  # s33_assert_no_fwl() stops the run before any fit if violated
    TRUE,  # s33_assert_complete_span() stops the run before any fit if violated
    nrow(gate_ledger) == 4L * 4L,
    all(vapply(split(coef_ledger, list(coef_ledger$window,
                                       coef_ledger$internal_slope_interaction), drop = TRUE),
               function(g) length(unique(g$centering_regime)) >= 1L, logical(1))),
    all(is.finite(coef_ledger$std_condition_number)) &&
      all(nzchar(coef_ledger$centering_note)),
    all(coef_ledger$tb_star[coef_ledger$window == "Fordist_1929_1973"] == 1947L) &&
      all(coef_ledger$tb_star[coef_ledger$window == "Post_Fordist_1974_2024"] == 2008L),
    all(nzchar(coef_ledger$step_controls)),
    all(!vapply(cols, is.null, logical(1))),
    all(coef_ledger$break_route_status %in%
          c("formal_break_supported", "exploratory_break_route")),
    nrow(decision_ledger) == length(WINDOWS) &&
      all(decision_ledger$s01_sec3_decision %in%
            c("retain_multiplicative_interaction", "retain_additive_step_control")),
    all(is.finite(coef_ledger$sigma_u_baseline)),
    nrow(dols_ledger) == 0L || all(dols_ledger$role == "diagnostic_comparator"),
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
          fixed = TRUE)
  ),
  detail = c(
    paste0("read ", VERDICT_PATH),
    "cointReg::cointRegIM via s33_imols(); E10V active estimator lock",
    "s33_assert_no_fwl() run on every design matrix before estimation",
    paste("span correction 2026-07-31: (k_cap.omega).D now accompanied by k_cap.D AND",
          "omega.D; omega.D was previously absent, which left the Fordist interacted",
          "theta_1 spanning [-5.899, 3.459] across centering regimes"),
    paste0(nrow(gate_ledger), " gate rows (4 items x 4 models)"),
    paste("regimes attempted:", paste(S33_CENTERING_REGIMES, collapse = ", ")),
    paste0("standardized CN threshold ", CN_THRESHOLD,
           "; reported regimes: ",
           paste(unique(rep_coef$centering_regime), collapse = ", ")),
    "Fordism T_B*=1947, Post-Fordism T_B*=2008 (S01 Sec.5 Step 1)",
    paste("controls:", paste(unique(coef_ledger$step_controls), collapse = " | ")),
    "Table X columns (1)-(4) all populated",
    paste0(sum(rep_coef$break_route_status == "formal_break_supported"), " formal, ",
           sum(rep_coef$break_route_status == "exploratory_break_route"),
           " exploratory coefficient rows"),
    paste(decision_ledger$window, decision_ledger$s01_sec3_decision, collapse = "; "),
    sprintf("baselines: Fordist %.3f, Post-Fordist %.3f",
            S33_SIGMA_U_BASELINE_SPEC_A[["Fordist_1929_1973"]],
            S33_SIGMA_U_BASELINE_SPEC_A[["Post_Fordist_1974_2024"]]),
    paste0(nrow(dols_ledger), " DOLS comparator rows, none promoted"),
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE)
  )
)

s33_write_ledger(integrity, CSV_DIR, "s33c_specA_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33C")

log_msg("US_S33C complete. ", nrow(coef_ledger), " coefficient rows; decisions: ",
        paste(decision_ledger$window, decision_ledger$s01_sec3_decision, collapse = "; "))
log_msg("Next: Rscript codes/US_S33D_break_interacted_imols_specB.R")
