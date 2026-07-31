#!/usr/bin/env Rscript

# US_S33G_specB5_theory_consistent_full_sample.R
# ---------------------------------------------------------------------------
# Specification B5: the Section 3.2 estimating equation, estimated on the full sample
# with a COMPLETE interaction span.
#
#   Sec.3.2 line 94:
#     y^p_t = theta_NRC k^NRC_t + theta_kappa kappa_t
#             + theta_omega_kappa (omega_{t-1} kappa_t)
#             + theta_kappa_pkappa (p^kappa_t kappa_t)
#
# ---------------------------------------------------------------------------
# WHY B5 EXISTS. Two corrections to the tracks that came before it.
#
# (1) theta_kappa IS RESTORED. Spec B4 (US_S33D, US_S33E) drops the standalone gap level
#     on the argument that mechanization is "only a channel". Sec.3.2 does not support
#     that: theta_kappa falls out of the quadratic lambda_2 kappa^2 viability term and
#     carries both the MP_kappa intercept (lambda_1 - gamma_0) and its curvature
#     (2 lambda_2). Dropping it leaves MP_kappa without an intercept and makes
#     theta_t^SpecB unrecoverable from the structural model. Sec.3.2 line 94 governs.
#
# (2) THE INTERACTION SPAN IS COMPLETED. This is the substantive econometric fix and it
#     is why the earlier estimates could not identify a sign.
#
#     Centering the base series before forming a break-interacted cross-product expands as
#
#       (kappa - k0)(omega - w0) D_t
#          = kappa.omega.D_t - k0 (omega.D_t) - w0 (kappa.D_t) + k0 w0 D_t
#
#     so the design must span kappa.omega.D_t, omega.D_t, kappa.D_t AND D_t for centering
#     to be a reparameterization rather than a change of model. US_S33D carries kappa.D_t
#     (as delta_1) but NOT omega.D_t. US_S33E carries neither. Both are outside the scope
#     of the N11 Sec.1 invariance theorem, and in both the centering regime silently
#     selects the SIGN of the parameters carrying H1 and H2.
#
#     Verified on synthetic data with a known DGP (US_S33F, and see the handoff note):
#     OLS relative spread across the three centering regimes is 6e-16 for the
#     {1, kappa, omega, kappa.omega} case N11 states, 7.8e-02 once kappa.omega.D enters
#     without omega.D and kappa.D, and 6e-16 again once those two are restored. The
#     mechanism is neither IM-OLS (invariant to ~0.3% on clean data) nor ill-conditioning
#     (CN forced to 181 leaves the spread at 0.26%), and a trend in deter does not fix it.
#
# ---------------------------------------------------------------------------
# WHAT IS NOT IN THIS DESIGN, AND WHY.
#
#   - No three-way kappa.omega.p^kappa. Sec.3.2's marginal cost is ADDITIVELY SEPARABLE
#     (line 51: MC = gamma_0 - gamma_1 omega + gamma_2 p^kappa), so the theory derives two
#     two-way interactions and no three-way term. Adding one would invent structure the
#     model does not have and would reintroduce the collinearity the full-sample design
#     was built to escape.
#   - No (kappa.p^kappa).D_t. Sec.2.6's regime-change prediction is specific to the
#     wage-mechanization nexus; the price channel carries no comparable prediction. And
#     because kappa.p^kappa is not interacted with the dummy, it imposes no span
#     requirement of its own.
#   - No unit-root test on any cross-product. Under E10V line 37 these are O_p(T) degree-2
#     CPR regressors whose admissibility is INHERITED from the base series' I(1)-with-break
#     status. Testing the product would contradict the estimator lock.
#
# CONTEMPORANEOUS p^kappa_t, per Sec.3.2 line 94. A06_RelativePrice_Mechanization_Theory.md
# uses a LAGGED p^rel_{t-1} in its interaction; that variant is recorded here and not
# estimated. A06 also derives the OPPOSITE sign to Sec.3.2 for the price channel
# (A06 line 72 gives dq*/dp^rel > 0 against Sec.3.2 line 68's dkappa*/dp^kappa < 0). The two
# drafts are unreconciled. This script REPORTS the conflict in a dedicated ledger and does
# NOT adjudicate it.
#
# ---------------------------------------------------------------------------
# ALL THREE CENTERING REGIMES ARE REPORTED. N11 Sec.1 itself states that centering changes
# "the point of evaluation for the baseline linear coefficients", so the base coefficients
# are SUPPOSED to move and a single reported regime misrepresents them. The gate this
# script applies is therefore restricted to the INTERACTION-class parameters, which is the
# only invariance N11 actually claims. A reported row is still marked for continuity with
# US_S33D/US_S33E conventions.
#
# Governance: artifacts land under output/US/BREAK_AWARE_IMOLS/S33G_IMOLS_SPEC_B5/.
#
# Usage:
#   Rscript codes/US_S33G_specB5_theory_consistent_full_sample.R
#   (run US_S33A first: its Sec.6.5 wage-mechanization block supplies T_B*)
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

STAGE   <- "S33G_IMOLS_SPEC_B5"
OUT_DIR <- s33_dir(STAGE)
CSV_DIR <- file.path(OUT_DIR, "csv")
LOG_DIR <- file.path(OUT_DIR, "logs")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33G_execution_log.txt")
log_msg <- function(...) {
  line <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(line, "\n", sep = "")
  cat(line, "\n", sep = "", file = LOG_PATH, append = TRUE)
}
cat("", file = LOG_PATH)

WINDOW_KEY   <- "Full_Sample_1929_2024"
THEORY_DATE  <- 1974L
CN_THRESHOLD <- 30

# ---------------------------------------------------------------------------
# 1. Step 2 gate
# ---------------------------------------------------------------------------

VERDICT_PATH <- s33_dir("S33B_LEE_STRAZICICH", "csv", "integration_order_verdict.csv")
if (!file.exists(VERDICT_PATH)) {
  stop("Step 2 verdict not found at ", VERDICT_PATH,
       ". Run codes/US_S33B_lee_strazicich_break_robust_unitroot.R first.")
}
verdicts <- utils::read.csv(VERDICT_PATH, stringsAsFactors = FALSE)
BASE_VARS <- c("k_NRC", "kappa", "p_kappa")
gv <- verdicts[verdicts$spec == "Spec_B" & verdicts$window == WINDOW_KEY &
                 verdicts$variable %in% BASE_VARS, , drop = FALSE]
gate_ok <- vapply(BASE_VARS, function(b) {
  r <- gv[gv$variable == b, , drop = FALSE]
  nrow(r) == 1L && r$integration_verdict == "I1_with_break"
}, logical(1))
gate_all_pass <- all(gate_ok)
gate_verdicts <- paste(sprintf("%s=%s", gv$variable, gv$integration_verdict), collapse = "; ")
gate_failing  <- paste(names(gate_ok)[!gate_ok], collapse = ", ")
route <- if (gate_all_pass) "formal_break_supported" else "exploratory_break_route"
disposition <- if (gate_all_pass) "break_unlocked_for_formal_route" else
  "estimated_as_exploratory_with_limitation"
log_msg("Step 2 gate (", WINDOW_KEY, "): ", route, " [", gate_verdicts, "]")

# ---------------------------------------------------------------------------
# 2. T_B* from US_S33A
# ---------------------------------------------------------------------------

BP_DATES <- s33_dir("S33A_BAI_PERRON", "csv", "bai_perron_break_dates.csv")
if (!file.exists(BP_DATES)) {
  stop("Bai-Perron break dates not found at ", BP_DATES,
       ". Run codes/US_S33A_bai_perron_split_sample_prescan.R first.")
}
bp <- utils::read.csv(BP_DATES, stringsAsFactors = FALSE)
wm <- bp[bp$spec == "Spec_B_WageMech" & bp$series == "d_kappa_omega" &
           bp$window == WINDOW_KEY, , drop = FALSE]
if (!nrow(wm)) {
  stop("No confirmed break on d_kappa_omega in ", WINDOW_KEY,
       ". Report that as the result rather than substituting a protocol date.")
}
TB_STAR     <- as.integer(wm$break_year[which.min(abs(wm$break_year - THEORY_DATE))])
TB_ROW      <- wm[wm$break_year == TB_STAR, , drop = FALSE][1, ]
TB_DISTANCE <- abs(TB_STAR - THEORY_DATE)
TB_SOURCE   <- paste0("US_S33A Sec.6.5 Bai-Perron univariate_mean on d_kappa_omega, ",
                      WINDOW_KEY, "; breaks {", paste(wm$break_year, collapse = ";"),
                      "}; selected nearest ", THEORY_DATE, " = ", TB_STAR,
                      " (distance ", TB_DISTANCE, " yr); 95% CI [",
                      TB_ROW$ci95_low, ", ", TB_ROW$ci95_high, "]")
log_msg("T_B* = ", TB_STAR, " (", TB_DISTANCE, " yr from theoretical ", THEORY_DATE, ")")

# ---------------------------------------------------------------------------
# 3. Design
# ---------------------------------------------------------------------------

STEPS <- list(
  list(name = "D_1933",      type = "step",  args = list(1933L)),
  list(name = "B_1942_1945", type = "block", args = list(1942L, 1945L)),
  list(name = "D_1981",      type = "step",  args = list(1981L)),
  list(name = "D_2000",      type = "step",  args = list(2000L))
)
build_steps <- function(year) {
  out <- NULL; nms <- character(0)
  for (s in STEPS) {
    v <- switch(s$type,
                step  = s33_step(year, s$args[[1]]),
                block = s33_block(year, s$args[[1]], s$args[[2]]))
    if (stats::sd(v) > 0) { out <- cbind(out, v); nms <- c(nms, s$name) }
  }
  if (!is.null(out)) colnames(out) <- nms
  out
}
std_condition <- function(X) {
  X <- as.matrix(X)
  s <- apply(X, 2, function(c) sqrt(sum(c^2)))
  s[s == 0 | !is.finite(s)] <- 1
  suppressWarnings(kappa(sweep(X, 2, s, "/"), exact = TRUE))
}

panel <- s33_load_spec_b()
log_msg("Spec B panel: ", nrow(panel), " rows, ", min(panel$year), "-", max(panel$year))

fit_model <- function(interacted, regime) {
  win <- S33_WINDOWS[[WINDOW_KEY]]
  d <- s33_window(panel, win)
  need <- c("y", "k_NRC", "kappa", "p_kappa", "omega_lag1")
  d <- d[stats::complete.cases(d[, need]), , drop = FALSE]
  yr <- d$year; y <- d$y

  kn <- s33_center(d$k_NRC, regime)
  kp <- s33_center(d$kappa, regime)
  pk <- s33_center(d$p_kappa, regime)
  w  <- s33_center(d$omega_lag1, regime)

  # Sec.3.2 line 94: standalone kappa present.
  X <- cbind(k_NRC = kn, kappa = kp, p_kappa = pk, omega = w)
  base_cols <- c("k_NRC", "kappa", "p_kappa", "omega")
  X <- cbind(X, kappa_x_omega = kp * w, kappa_x_pkappa = kp * pk)
  inter_cols <- c("kappa_x_omega", "kappa_x_pkappa")

  stepm <- build_steps(yr)
  if (!is.null(stepm)) X <- cbind(X, stepm)

  if (interacted) {
    D <- s33_step(yr, TB_STAR)
    if (stats::sd(D) == 0) return(NULL)
    # COMPLETE SPAN: kappa_omega_x_D requires omega_x_D and kappa_x_D alongside D_TB.
    # Omitting either makes centering a change of model rather than a reparameterization.
    X <- cbind(X, D_TB = D,
               kappa_x_D = kp * D,
               omega_x_D = w * D,
               kappa_omega_x_D = kp * w * D)
    inter_cols <- c(inter_cols, "kappa_x_D", "omega_x_D", "kappa_omega_x_D")
  }

  s33_assert_no_fwl(X, inter_cols, base_cols)

  deter <- matrix(1, nrow = length(y), ncol = 1)
  fit <- tryCatch(s33_imols(X, y, deter = deter), error = function(e) e)
  if (inherits(fit, "error")) return(list(error = conditionMessage(fit)))

  list(fit = fit, X = X, y = y, year = yr, T_obs = length(y),
       n_design_cols = ncol(X), residual_df = length(y) - ncol(X) - 1L,
       mean_omega = mean(w), mean_pkappa = mean(pk),
       cond = std_condition(cbind(1, X)), error = NA_character_)
}

# ---------------------------------------------------------------------------
# 4. Estimate
# ---------------------------------------------------------------------------

COEF_MAP <- c(theta_NRC = "k_NRC", theta_kappa = "kappa",
              beta_pkappa = "p_kappa", beta_omega = "omega",
              theta_omega_kappa = "kappa_x_omega",
              theta_kappa_pkappa = "kappa_x_pkappa",
              gamma_1 = "D_TB",
              theta_kappa_brk = "kappa_x_D",
              beta_omega_brk = "omega_x_D",
              theta_omega_kappa_brk = "kappa_omega_x_D")

# Which parameters the N11 invariance claim actually covers. Base-class coefficients are
# expected to move with centering (N11 Sec.1 point 2); only interaction-class ones are
# claimed invariant, and only those are gated.
PARAM_CLASS <- c(theta_NRC = "interaction", theta_kappa = "base",
                 beta_pkappa = "base", beta_omega = "base",
                 theta_omega_kappa = "interaction",
                 theta_kappa_pkappa = "interaction",
                 gamma_1 = "base",
                 theta_kappa_brk = "base",
                 beta_omega_brk = "base",
                 theta_omega_kappa_brk = "interaction")

coef_rows <- list(); gate_rows <- list(); dols_rows <- list(); mp_rows <- list()

for (interacted in c(FALSE, TRUE)) {
  conds <- list(); fits <- list()
  for (rg in S33_CENTERING_REGIMES) {
    m <- fit_model(interacted, rg)
    fits[[rg]] <- m
    conds[[rg]] <- if (!is.null(m) && is.na(m$error)) m$cond else NA_real_
  }
  cnA <- conds[["Regime_A_Uncentered"]]
  reported <- if (is.finite(cnA) && cnA <= CN_THRESHOLD) "Regime_A_Uncentered" else
    "Regime_B_Initial_Centered"
  centering_note <- sprintf(
    "standardized CN: A=%s B=%s C=%s; threshold %d; marked regime %s; ALL THREE reported",
    format(conds[["Regime_A_Uncentered"]], digits = 5),
    format(conds[["Regime_B_Initial_Centered"]], digits = 5),
    format(conds[["Regime_C_Mean_Centered"]], digits = 5),
    CN_THRESHOLD, reported)
  log_msg(if (interacted) "with-interaction" else "no-interaction", ": ", centering_note)

  for (rg in S33_CENTERING_REGIMES) {
    m <- fits[[rg]]
    if (is.null(m) || !is.na(m$error)) {
      log_msg("  ", rg, " FAILED: ", if (is.null(m)) "degenerate design" else m$error)
      next
    }
    f <- m$fit; dg <- f$diag
    for (nm in names(COEF_MAP)) {
      col <- COEF_MAP[[nm]]
      if (!(col %in% colnames(m$X))) next
      est <- s33_coef(f, col); tst <- s33_tstat(f, col)
      coef_rows[[length(coef_rows) + 1L]] <- data.frame(
        spec = "Spec_B5", taxonomy = "B5_sec32_span_complete",
        taxonomy_label = "Sec.3.2 line 94 form, full sample, complete interaction span",
        window = WINDOW_KEY, era_label = "Full Sample (1929-2024)",
        internal_slope_interaction = if (interacted) "Yes" else "No",
        tb_star = TB_STAR, tb_source = TB_SOURCE,
        tb_distance_from_theory = TB_DISTANCE, theory_date = THEORY_DATE,
        centering_regime = rg, is_reported_regime = identical(rg, reported),
        centering_note = centering_note,
        parameter = nm, parameter_class = unname(PARAM_CLASS[[nm]]),
        design_column = col,
        estimate = est, fixed_b_har_t = tst, stars = s33_stars(tst),
        significant_5pct = if (is.na(tst)) NA else abs(tst) >= 1.96,
        implied_se = if (is.na(tst) || tst == 0) NA_real_ else abs(est) / abs(tst),
        sigma_u = dg$sigma_u, C_shin = dg$C_shin, C_shin_stars = dg$shin_stars,
        residual_adf = dg$t_adf, residual_adf_stars = dg$adf_stars,
        r2_level = dg$r2_level, r2_sum = dg$r2_sum,
        T_obs = m$T_obs, k_reg = dg$k_reg,
        n_design_cols = m$n_design_cols, residual_df = m$residual_df,
        std_condition_number = m$cond,
        step_controls = paste(vapply(STEPS, `[[`, character(1), "name"), collapse = "+"),
        estimator = "IM-OLS (cointReg::cointRegIM), E10V active lock",
        break_route_status = route, disposition = disposition,
        gate_verdicts = gate_verdicts,
        gate_failing_vars = if (nzchar(gate_failing)) gate_failing else NA_character_,
        stringsAsFactors = FALSE)
    }

    if (identical(rg, reported)) {
      dl <- tryCatch(s33_dols(m$X, m$y), error = function(e) NULL)
      if (!is.null(dl)) {
        for (nm in names(COEF_MAP)) {
          col <- COEF_MAP[[nm]]
          if (!(col %in% names(dl$estimate))) next
          dols_rows[[length(dols_rows) + 1L]] <- data.frame(
            spec = "Spec_B5", window = WINDOW_KEY,
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

  iv <- setNames(gv$integration_verdict, gv$variable)
  iv <- ifelse(iv == "I1_with_break", "I(1)", iv)
  terms_used <- c("kappa x omega_lag1", "kappa x p_kappa",
                  if (interacted) c("kappa x D_TB", "omega_lag1 x D_TB",
                                    "kappa x omega_lag1 x D_TB"))
  gl <- s33_interaction_gate_ledger(
    spec = sprintf("Spec_B5 / %s / interaction=%s", WINDOW_KEY,
                   if (interacted) "Yes" else "No"),
    base_vars = BASE_VARS, interaction_terms = terms_used,
    integration_verdicts = iv, centering_regimes = S33_CENTERING_REGIMES)
  gl$window <- WINDOW_KEY
  gl$internal_slope_interaction <- if (interacted) "Yes" else "No"
  gl$break_route_status <- route
  gate_rows[[length(gate_rows) + 1L]] <- gl
}

coef_ledger <- do.call(rbind, coef_rows)
s33_write_ledger(coef_ledger, CSV_DIR, "specB5_coefficients.csv")
s33_write_ledger(do.call(rbind, gate_rows), CSV_DIR, "specB5_interaction_gate_ledger.csv")
s33_write_ledger(do.call(rbind, dols_rows), CSV_DIR, "specB5_dols_comparator_ledger.csv")

# ---------------------------------------------------------------------------
# 5. Centering-stability gate
# ---------------------------------------------------------------------------
# The gate. N11 Sec.1 claims invariance for interaction coefficients only; it explicitly
# expects baseline linear coefficients to shift with the point of evaluation. So
# parameter_class is carried in the data and only interaction-class rows are gated.

stab_rows <- list()
for (interacted in c("No", "Yes")) {
  sub_i <- coef_ledger[coef_ledger$internal_slope_interaction == interacted, , drop = FALSE]
  for (nm in unique(sub_i$parameter)) {
    s <- sub_i[sub_i$parameter == nm, , drop = FALSE]
    est <- s$estimate[is.finite(s$estimate)]
    if (length(est) < 2L) next
    scale <- mean(abs(est))
    stab_rows[[length(stab_rows) + 1L]] <- data.frame(
      spec = "Spec_B5", window = WINDOW_KEY,
      internal_slope_interaction = interacted,
      parameter = nm, parameter_class = s$parameter_class[1],
      n_regimes = length(est),
      est_min = min(est), est_max = max(est),
      absolute_spread = max(est) - min(est),
      relative_spread = if (scale > 0) (max(est) - min(est)) / scale else NA_real_,
      sign_stable = length(unique(sign(est))) == 1L,
      all_significant_5pct = all(s$significant_5pct %in% TRUE),
      gated = s$parameter_class[1] == "interaction",
      n11_note = if (s$parameter_class[1] == "interaction")
        "N11 Sec.1 claims invariance for this class; gated" else
        "N11 Sec.1 point 2: point of evaluation shifts with centering; not gated",
      stringsAsFactors = FALSE)
  }
}
stability <- do.call(rbind, stab_rows)
s33_write_ledger(stability, CSV_DIR, "specB5_centering_stability.csv")

gated <- stability[stability$gated %in% TRUE, , drop = FALSE]
GATE_PASS <- nrow(gated) > 0 && all(gated$sign_stable %in% TRUE)

log_msg("")
log_msg("CENTERING-STABILITY GATE (interaction-class parameters only)")
for (i in seq_len(nrow(stability))) {
  r <- stability[i, ]
  log_msg(sprintf("  %-4s %-24s %-12s [%9.3f, %9.3f] rel=%6.3f stable=%-5s %s",
                  r$internal_slope_interaction, r$parameter, r$parameter_class,
                  r$est_min, r$est_max, r$relative_spread, r$sign_stable,
                  if (r$gated) "<-- GATED" else ""))
}
log_msg("GATE: ", if (GATE_PASS) "PASS" else "FAIL",
        " (", sum(gated$sign_stable %in% TRUE), "/", nrow(gated),
        " interaction-class parameters sign-stable)")

# ---------------------------------------------------------------------------
# 6. Structural recovery to Sec.3.2 primitives
# ---------------------------------------------------------------------------
# Identities, from Sec.3.2 Sec.3.2.3. The envelope theorem gives
#     MP_kappa = (lambda_1 - gamma_0 + 2 lambda_2 kappa) + gamma_1 omega - gamma_2 p^kappa
# and integrating over kappa yields the intensive capacity yield
#     Psi_t = theta_kappa kappa + theta_omega_kappa (omega kappa)
#             + theta_kappa_pkappa (p^kappa kappa)
# with theta_omega_kappa = gamma_1 and theta_kappa_pkappa = -gamma_2.
#
# NOTE ON theta_kappa. The integrated form carries NO kappa^2 term, so theta_kappa maps to
# the AUTONOMOUS YIELD (lambda_1 - gamma_0), not to the frontier curvature. lambda_2 is
# therefore NOT identified by this regression: recovering it would require a kappa^2
# regressor, which Sec.3.2's estimating equation does not carry. Strict concavity
# (lambda_2 < 0, which Sec.3.2 invokes to guarantee a unique interior optimum) is an
# assumption here, not a tested restriction.
#
# theta_kappa is base-class and centering-sensitive, so the autonomous yield is reported
# per regime and must be read as a range rather than a point.

pick <- function(df, p, col = "estimate") {
  r <- df[df$parameter == p, col]
  if (length(r)) r[1] else NA_real_
}
rec_rows <- list()
for (interacted in c("No", "Yes")) {
  for (rg in S33_CENTERING_REGIMES) {
    s <- coef_ledger[coef_ledger$internal_slope_interaction == interacted &
                       coef_ledger$centering_regime == rg, , drop = FALSE]
    if (!nrow(s)) next
    th_wk <- pick(s, "theta_omega_kappa"); th_pk <- pick(s, "theta_kappa_pkappa")
    th_k  <- pick(s, "theta_kappa");       brk   <- pick(s, "theta_omega_kappa_brk")
    z <- function(x) ifelse(is.na(x), 0, x)
    rec_rows[[length(rec_rows) + 1L]] <- data.frame(
      spec = "Spec_B5", window = WINDOW_KEY,
      internal_slope_interaction = interacted, centering_regime = rg,
      tb_star = TB_STAR,
      gamma_1_hat = th_wk,
      gamma_2_hat = -th_pk,
      autonomous_yield_hat = th_k,           # (lambda_1 - gamma_0), NOT lambda_2
      lambda_2_identified = FALSE,
      theta_omega_kappa = th_wk, theta_kappa_pkappa = th_pk, theta_kappa = th_k,
      gamma_1_sign_ok = !is.na(th_wk) && th_wk > 0,   # Sec.3.2 requires gamma_1 > 0
      gamma_2_sign_ok = !is.na(th_pk) && -th_pk > 0,  # Sec.3.2 requires gamma_2 > 0
      omega_slope_pre_TB = th_wk,
      omega_slope_post_TB = th_wk + z(brk),
      identities = paste("Sec.3.2.3: gamma_1 = theta_omega_kappa;",
                         "gamma_2 = -theta_kappa_pkappa;",
                         "theta_kappa = autonomous yield (lambda_1 - gamma_0)"),
      caveat = paste("lambda_2 is NOT identified: the integrated Psi_t carries no kappa^2",
                     "term, so the frontier curvature cannot be recovered from this",
                     "regression. Strict concavity (lambda_2 < 0) is assumed, not tested.",
                     "theta_kappa is base-class and centering-sensitive, so the autonomous",
                     "yield must be read as a range across regimes, not a point."),
      stringsAsFactors = FALSE)
  }
}
s33_write_ledger(do.call(rbind, rec_rows), CSV_DIR,
                 "specB5_structural_parameter_recovery.csv")

# ---------------------------------------------------------------------------
# 7. Price-channel sign conflict -- reported, NOT adjudicated
# ---------------------------------------------------------------------------

pk_rows <- coef_ledger[coef_ledger$parameter == "theta_kappa_pkappa", , drop = FALSE]
sign_conflict <- data.frame(
  spec = "Spec_B5", window = WINDOW_KEY,
  internal_slope_interaction = pk_rows$internal_slope_interaction,
  centering_regime = pk_rows$centering_regime,
  theta_kappa_pkappa = pk_rows$estimate,
  fixed_b_har_t = pk_rows$fixed_b_har_t,
  observed_sign = ifelse(pk_rows$estimate < 0, "negative", "positive"),
  sec32_prediction = "negative",
  sec32_basis = paste("ch2_sec3_2_heterogeneous_capital_prelatex.md line 68:",
                      "gamma_2 > 0 implies d kappa*/d p^kappa < 0, so theta_kappa_pkappa < 0"),
  a06_prediction = "positive",
  a06_basis = paste("A06_RelativePrice_Mechanization_Theory.md line 72:",
                    "d q*/d p^rel > 0 under the multiplicative cost form"),
  consistent_with_sec32 = pk_rows$estimate < 0,
  consistent_with_a06 = pk_rows$estimate > 0,
  theoretical_conflict_unresolved = TRUE,
  note = paste("Sec.3.2 and A06 derive OPPOSITE signs for the price channel and are not",
               "reconciled in the vault. This ledger records the estimate and both",
               "derivations; it does not adjudicate between them."),
  stringsAsFactors = FALSE)
s33_write_ledger(sign_conflict, CSV_DIR, "specB5_price_channel_sign_conflict.csv")

# ---------------------------------------------------------------------------
# 8. Slope-break decision
# ---------------------------------------------------------------------------

rep_i <- coef_ledger[coef_ledger$is_reported_regime %in% TRUE &
                       coef_ledger$internal_slope_interaction == "Yes", , drop = FALSE]
brk <- rep_i[rep_i$parameter == "theta_omega_kappa_brk", , drop = FALSE]
brk_stab <- stability[stability$parameter == "theta_omega_kappa_brk" &
                        stability$internal_slope_interaction == "Yes", , drop = FALSE]
brk_sig <- nrow(brk) == 1L && !is.na(brk$fixed_b_har_t) && abs(brk$fixed_b_har_t) >= 1.96
decision <- if (brk_sig) "retain_multiplicative_interaction" else "retain_additive_step_control"
s33_write_ledger(data.frame(
  spec = "Spec_B5", window = WINDOW_KEY, tb_star = TB_STAR, tb_source = TB_SOURCE,
  theta_omega_kappa_brk = if (nrow(brk)) brk$estimate else NA_real_,
  theta_omega_kappa_brk_t = if (nrow(brk)) brk$fixed_b_har_t else NA_real_,
  significant_5pct = brk_sig,
  sign_stable_across_centering = if (nrow(brk_stab)) brk_stab$sign_stable[1] else NA,
  s02_decision = decision,
  rule = paste("S01 Sec.3: a slope shift significant at 5% licenses the multiplicative",
               "branch; here additionally required to be sign-stable across centering"),
  break_route_status = route, disposition = disposition,
  stringsAsFactors = FALSE), CSV_DIR, "specB5_slope_break_decision_ledger.csv")

# ---------------------------------------------------------------------------
# 9. Comparison against the prior tracks
# ---------------------------------------------------------------------------

cmp_rows <- list()
add_prior <- function(path, track) {
  if (!file.exists(path)) return(invisible(NULL))
  sc <- utils::read.csv(path, stringsAsFactors = FALSE)
  for (p in c("theta_omega_kappa", "theta_kappa_pkappa")) {
    for (win in unique(sc$window)) {
      for (int in unique(sc$internal_slope_interaction)) {
        s <- sc[sc$parameter == p & sc$window == win &
                  sc$internal_slope_interaction == int, , drop = FALSE]
        if ("taxonomy" %in% names(s)) s <- s[s$taxonomy %in% c("B3", "B4_wage_break"), , drop = FALSE]
        est <- s$estimate[is.finite(s$estimate)]
        if (length(est) < 2L) next
        cmp_rows[[length(cmp_rows) + 1L]] <<- data.frame(
          track = track, window = win, internal_slope_interaction = int,
          parameter = p, T_obs = s$T_obs[1],
          n_design_cols = if ("n_design_cols" %in% names(s)) s$n_design_cols[1] else NA_integer_,
          span_complete = FALSE,
          est_min = min(est), est_max = max(est),
          sign_stable = length(unique(sign(est))) == 1L,
          cn_min = min(s$std_condition_number, na.rm = TRUE),
          cn_max = max(s$std_condition_number, na.rm = TRUE),
          stringsAsFactors = FALSE)
      }
    }
  }
}
add_prior(s33_dir("S33D_IMOLS_SPEC_B", "csv", "specB_break_interacted_imols_coefficients.csv"),
          "split_sample (US_S33D)")
add_prior(s33_dir("S33E_IMOLS_SPEC_B_FULL_SAMPLE", "csv",
                  "specB_full_sample_wage_break_coefficients.csv"),
          "full_sample span-broken (US_S33E)")
for (p in c("theta_omega_kappa", "theta_kappa_pkappa")) {
  for (int in c("No", "Yes")) {
    s <- stability[stability$parameter == p & stability$internal_slope_interaction == int, ,
                   drop = FALSE]
    if (!nrow(s)) next
    cc <- coef_ledger[coef_ledger$parameter == p &
                        coef_ledger$internal_slope_interaction == int, , drop = FALSE]
    cmp_rows[[length(cmp_rows) + 1L]] <- data.frame(
      track = "full_sample span-COMPLETE (US_S33G, Spec B5)",
      window = WINDOW_KEY, internal_slope_interaction = int, parameter = p,
      T_obs = cc$T_obs[1], n_design_cols = cc$n_design_cols[1], span_complete = TRUE,
      est_min = s$est_min[1], est_max = s$est_max[1], sign_stable = s$sign_stable[1],
      cn_min = min(cc$std_condition_number, na.rm = TRUE),
      cn_max = max(cc$std_condition_number, na.rm = TRUE),
      stringsAsFactors = FALSE)
  }
}
comparison <- do.call(rbind, cmp_rows)
s33_write_ledger(comparison, CSV_DIR, "specB5_vs_prior_tracks_comparison.csv")

log_msg("")
log_msg("SIGN STABILITY ACROSS CENTERING -- B5 vs prior tracks")
for (i in seq_len(nrow(comparison))) {
  r <- comparison[i, ]
  log_msg(sprintf("  %-42s %-23s int=%-3s %-19s [%9.3f,%9.3f] stable=%s",
                  r$track, r$window, r$internal_slope_interaction, r$parameter,
                  r$est_min, r$est_max, r$sign_stable))
}

# ---------------------------------------------------------------------------
# 10. Integrity
# ---------------------------------------------------------------------------

design_cols <- unique(coef_ledger$design_column)
int_cols <- coef_ledger$design_column[coef_ledger$internal_slope_interaction == "Yes"]

integrity <- s33_integrity(
  checks = c("step2_gate_consumed",
             "theta_kappa_present_per_sec32",
             "interaction_span_complete",
             "no_three_way_interaction",
             "contemporaneous_pkappa_per_sec32",
             "tb_star_sourced_from_s33a_not_hardcoded",
             "all_three_centering_regimes_reported",
             "interaction_coefficients_sign_stable",
             "sign_conflict_logged_not_adjudicated",
             "outputs_confined_to_break_aware_tree"),
  passed = c(
    nrow(gv) == length(BASE_VARS),
    "kappa" %in% design_cols,
    all(c("kappa_x_D", "omega_x_D", "kappa_omega_x_D") %in% int_cols),
    !any(grepl("kappa.*omega.*pkappa|three_way", design_cols)),
    !any(grepl("p_kappa_lag", design_cols)),
    TB_STAR %in% wm$break_year,
    identical(sort(unique(coef_ledger$centering_regime)), sort(S33_CENTERING_REGIMES)),
    GATE_PASS,
    nrow(sign_conflict) > 0 && all(sign_conflict$theoretical_conflict_unresolved),
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
          fixed = TRUE)
  ),
  detail = c(
    paste0("read ", VERDICT_PATH, "; ", gate_verdicts, "; route ", route),
    "standalone kappa restored per Sec.3.2 line 94 (carries MP intercept and curvature)",
    paste("kappa_omega_x_D accompanied by kappa_x_D and omega_x_D; centering is a",
          "reparameterization rather than a change of model"),
    "Sec.3.2 marginal cost is additively separable; no three-way term derived or estimated",
    "contemporaneous p^kappa_t per Sec.3.2; A06's lagged variant recorded, not estimated",
    TB_SOURCE,
    paste("all three centering regimes written; base coefficients move by design",
          "(N11 Sec.1 point 2), so no single regime is presented as the model"),
    paste0(sum(gated$sign_stable %in% TRUE), "/", nrow(gated),
           " interaction-class parameters sign-stable across centering; ",
           "median relative spread ",
           sprintf("%.3f", stats::median(gated$relative_spread, na.rm = TRUE))),
    "Sec.3.2 vs A06 price-sign conflict recorded with both derivations; not adjudicated",
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE)
  )
)
s33_write_ledger(integrity, CSV_DIR, "s33g_specB5_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33G")

log_msg("US_S33G complete. ", nrow(coef_ledger), " coefficient rows; T_B* = ", TB_STAR,
        "; gate ", if (GATE_PASS) "PASS" else "FAIL", "; decision: ", decision)
