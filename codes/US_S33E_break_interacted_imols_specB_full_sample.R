#!/usr/bin/env Rscript

# US_S33E_break_interacted_imols_specB_full_sample.R
# ---------------------------------------------------------------------------
# Full-sample wage-mechanization break track for Specification B.
#
#     One window (1929-2024, T=94). One internal multiplicative slope shift, on the
#     wage-mechanization channel kappa_t . omega_{t-1} only. No standalone kappa level.
#
# WHY THIS TRACK EXISTS. US_S33D estimates Spec B on two historical sub-samples with
# three simultaneous slope shifts (delta_1 on the gap level, delta_2 on the wage
# interaction, delta_3 on the price interaction). On the Fordist window that design puts
# 10 slope parameters on T=43, leaving 33 residual degrees of freedom and a standardized
# condition number of 361.44. Its wage-squeeze estimate is theta_omega_kappa = 47.79 with
# a Fixed-b HAR t of 1.06 -- an implied standard error near 45. The point estimate is
# large BECAUSE it is imprecise, not despite it: stacking three kappa-derived
# cross-products on a 43-observation window inflates the variance of every one of them.
#
# This script trades the historical split for degrees of freedom, and trades three slope
# shifts for one. It does NOT replace US_S33D, which remains the split-sample track and
# is not modified.
#
# ---------------------------------------------------------------------------
# WHY THE FULL SAMPLE IS ADMISSIBLE HERE (and this is the load-bearing point).
#
# US_S33B already ran Lee-Strazicich on Full_Sample_1929_2024. For Spec B's three gated
# base variables the verdict is:
#
#     k_NRC    I1_with_break   PASS
#     kappa    I1_with_break   PASS
#     p_kappa  I1_with_break   PASS
#
# All three clear the Step 2 gate on the full sample. This differs from the Post-Fordist
# sub-sample, where kappa returns persistent_I2_risk and forces every estimate onto the
# exploratory route. So the full-sample track is FORMALLY GATED where half of the
# split-sample track is not -- the longer window is better identified, not worse.
# No new Lee-Strazicich work is required; the existing verdict file is read as the gate.
#
# ---------------------------------------------------------------------------
# WHY NO LEE-STRAZICICH ON THE INTERACTION PRODUCT. Do not add one.
#
# Under E10V (chapter2_vault/03_econometrics/E10V_IMOLS_CPR_Active_Estimator_Lock.md
# line 37) the cross-product kappa_t . omega_{t-1} is classified as an O_p(T) degree-2
# polynomial CPR regressor, NOT as a classical I(2) series. Its admissibility is
# INHERITED from the individual I(1)-with-break status of its constituent series; it is
# not established by testing the product itself. s33_interaction_gate_ledger() gate item
# 2 codifies exactly this. Running a unit root test on the product would contradict the
# CPR treatment the estimator lock already fixes, and would invite reading a rejection as
# though it said something about admissibility. The Bai-Perron search in US_S33A Sec.6.5
# runs on Delta(kappa . omega) to locate a BREAK DATE, which is a different question from
# integration order and is not gated by the same rule.
#
# ---------------------------------------------------------------------------
# T_B* PROVENANCE. Read from US_S33A's ledger, never hardcoded.
#
# US_S33A Sec.6.5 runs Bai-Perron (univariate mean-shift route) on the first difference
# of the wage-mechanization product over the full sample. Where several breaks clear the
# UDmax-first rule, this script takes the one nearest 1974 and records the distance. The
# search was not restricted to a band around the theoretical date: a break far from 1974
# is evidence about when the decoupling actually bit, and constraining the window would
# make the exercise incapable of falsifying the periodization it examines.
#
# WHY ONLY THE WAGE CHANNEL BREAKS. ch2_sec2_theoretical_foundations_prelatex.md Sec.2.6
# predicts regime change in the wage-mechanization nexus specifically -- the Fordist
# "Distributive-Mechanization Nexus" giving way to "Post-Fordist Institutional
# Decoupling". It makes no comparable prediction for the price-conditioning channel. So
# kappa . p^kappa enters additively with no internal break. That asymmetry is a
# theoretical commitment, not a convenience, and it is what buys back the conditioning.
#
# NO STANDALONE KAPPA. Follows the B4 finding already in the codebase (US_S33D Sec.2 and
# chapter2_vault/03_econometrics/standalone_kappa_exclusion_assessment.md): the gap level
# is redundant against its own cross-products, near-perfectly so in some windows.
#
# Governance: artifacts land under
# output/US/BREAK_AWARE_IMOLS/S33E_IMOLS_SPEC_B_FULL_SAMPLE/.
#
# Usage:
#   Rscript codes/US_S33E_break_interacted_imols_specB_full_sample.R
#   (run codes/US_S33A_bai_perron_split_sample_prescan.R first: it supplies T_B*)
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

STAGE   <- "S33E_IMOLS_SPEC_B_FULL_SAMPLE"
OUT_DIR <- s33_dir(STAGE)
CSV_DIR <- file.path(OUT_DIR, "csv")
LOG_DIR <- file.path(OUT_DIR, "logs")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33E_execution_log.txt")
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
# 1. Step 2 gate (existing full-sample Lee-Strazicich verdicts)
# ---------------------------------------------------------------------------

VERDICT_PATH <- s33_dir("S33B_LEE_STRAZICICH", "csv", "integration_order_verdict.csv")
if (!file.exists(VERDICT_PATH)) {
  stop("Step 2 verdict not found at ", VERDICT_PATH, ".\n",
       "Run codes/US_S33B_lee_strazicich_break_robust_unitroot.R first.")
}
verdicts <- utils::read.csv(VERDICT_PATH, stringsAsFactors = FALSE)

BASE_VARS <- c("k_NRC", "kappa", "p_kappa")

gv <- verdicts[verdicts$spec == "Spec_B" & verdicts$window == WINDOW_KEY &
                 verdicts$variable %in% BASE_VARS, , drop = FALSE]
gate_ok <- setNames(rep(FALSE, length(BASE_VARS)), BASE_VARS)
for (b in BASE_VARS) {
  r <- gv[gv$variable == b, , drop = FALSE]
  gate_ok[b] <- nrow(r) == 1L && r$integration_verdict == "I1_with_break"
}
gate_all_pass  <- all(gate_ok)
gate_verdicts  <- paste(sprintf("%s=%s", gv$variable, gv$integration_verdict), collapse = "; ")
gate_failing   <- paste(names(gate_ok)[!gate_ok], collapse = ", ")
route <- if (gate_all_pass) "formal_break_supported" else "exploratory_break_route"
disposition <- if (gate_all_pass) "break_unlocked_for_formal_route" else
  "estimated_as_exploratory_with_limitation"
log_msg("Step 2 gate (", WINDOW_KEY, "): ", route, " [", gate_verdicts, "]")

# ---------------------------------------------------------------------------
# 2. T_B* from US_S33A -- read, never hardcoded
# ---------------------------------------------------------------------------

BP_DATES <- s33_dir("S33A_BAI_PERRON", "csv", "bai_perron_break_dates.csv")
if (!file.exists(BP_DATES)) {
  stop("Bai-Perron break dates not found at ", BP_DATES, ".\n",
       "Run codes/US_S33A_bai_perron_split_sample_prescan.R first: its Sec.6.5 ",
       "wage-mechanization block supplies T_B* for this stage.")
}
bp <- utils::read.csv(BP_DATES, stringsAsFactors = FALSE)
wm <- bp[bp$spec == "Spec_B_WageMech" & bp$series == "d_kappa_omega" &
           bp$window == WINDOW_KEY, , drop = FALSE]
if (!nrow(wm)) {
  stop("No confirmed break on d_kappa_omega in ", WINDOW_KEY, ".\n",
       "US_S33A found no break clearing the UDmax-first rule on the wage-mechanization ",
       "channel, so there is no internal slope shift for this stage to estimate. ",
       "That is a substantive result, not a failure: report it rather than ",
       "substituting a protocol date.")
}
TB_STAR      <- as.integer(wm$break_year[which.min(abs(wm$break_year - THEORY_DATE))])
TB_ROW       <- wm[wm$break_year == TB_STAR, , drop = FALSE][1, ]
TB_DISTANCE  <- abs(TB_STAR - THEORY_DATE)
TB_ALL       <- paste(wm$break_year, collapse = ";")
TB_SOURCE    <- paste0("US_S33A Sec.6.5 Bai-Perron univariate_mean on d_kappa_omega, ",
                       WINDOW_KEY, "; breaks {", TB_ALL, "}; selected nearest ",
                       THEORY_DATE, " = ", TB_STAR, " (distance ", TB_DISTANCE, " yr); ",
                       "95% CI [", TB_ROW$ci95_low, ", ", TB_ROW$ci95_high, "]")
log_msg("T_B* = ", TB_STAR, " (", TB_DISTANCE, " yr from theoretical ", THEORY_DATE,
        "), 95% CI [", TB_ROW$ci95_low, ", ", TB_ROW$ci95_high, "]")

# ---------------------------------------------------------------------------
# 3. Additive nuisance controls
# ---------------------------------------------------------------------------
# Variance hygiene spanning the full history, NOT regime identification -- the regime
# question is carried entirely by the single T_B* slope shift. Same dates US_S33D uses,
# now all inside one window.

STEPS <- list(
  list(name = "D_1933",      type = "step",  args = list(1933L),
       rationale = "New Deal regime change; permanent level shift"),
  list(name = "B_1942_1945", type = "block", args = list(1942L, 1945L),
       rationale = "WWII mobilisation; reverses on demobilisation"),
  list(name = "D_1981",      type = "step",  args = list(1981L),
       rationale = "Volcker disinflation; Bai-Perron supported"),
  list(name = "D_2000",      type = "step",  args = list(2000L),
       rationale = "Dot-Com crash; Bai-Perron supported")
)

build_steps <- function(year) {
  out <- NULL; nms <- character(0)
  for (s in STEPS) {
    v <- switch(s$type,
                step  = s33_step(year, s$args[[1]]),
                block = s33_block(year, s$args[[1]], s$args[[2]]),
                stop("unknown step type: ", s$type))
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

# ---------------------------------------------------------------------------
# 4. One model
# ---------------------------------------------------------------------------

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

  # No standalone kappa: the gap enters only through its two conditioning channels.
  X <- cbind(k_NRC = kn, p_kappa = pk, omega = w)
  base_cols <- c("k_NRC", "p_kappa", "omega")

  X <- cbind(X, kappa_x_omega = kp * w, kappa_x_pkappa = kp * pk)
  inter_cols <- c("kappa_x_omega", "kappa_x_pkappa")

  stepm <- build_steps(yr)
  if (!is.null(stepm)) X <- cbind(X, stepm)

  # SPAN CORRECTION (2026-07-31). The single internal slope shift is the triple product
  # (kappa . omega) . D, which requires kappa.D and omega.D in the design for centering to
  # remain a reparameterization. This script previously carried neither, which left
  # theta_kappa_pkappa spanning [-0.744, 2.083] across centering regimes -- the SIGN of
  # the price channel was set by the centering convention. The earlier comment reasoned
  # that kappa_x_D was unnecessary because B4 carries no standalone kappa LEVEL; that is
  # wrong. The constituent is required because kappa appears inside the product, not
  # because it appears as a main effect. See US_S33F.
  #
  # Still no kappa_pkappa_x_D: the theory predicts no regime change in the price channel,
  # so that product is not formed, and a product not formed imposes no span requirement.
  products <- list(c("kappa", "omega"))
  if (interacted) {
    D <- s33_step(yr, TB_STAR)
    if (stats::sd(D) == 0) return(NULL)
    brk <- s33_break_span(D, vars = list(kappa = kp, omega = w), products = products)
    X <- cbind(X, brk)
    inter_cols <- c(inter_cols, setdiff(colnames(brk), "D_TB"))
    s33_assert_complete_span(X, products = products)
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
# 5. Drive interaction x centering
# ---------------------------------------------------------------------------

COEF_MAP <- c(theta_NRC = "k_NRC", beta_pkappa = "p_kappa", beta_omega = "omega",
              theta_omega_kappa = "kappa_x_omega",
              theta_kappa_pkappa = "kappa_x_pkappa",
              gamma_1 = "D_TB",
              # constituents added by the span correction
              theta_kappa_brk = "kappa_x_D", beta_omega_brk = "omega_x_D",
              theta_omega_kappa_brk = "kappa_omega_x_D")

# N11 Sec.1 claims invariance for interaction-class parameters only.
PARAM_CLASS <- c(theta_NRC = "interaction", beta_pkappa = "base", beta_omega = "base",
                 theta_omega_kappa = "interaction",
                 theta_kappa_pkappa = "interaction",
                 gamma_1 = "base", theta_kappa_brk = "base", beta_omega_brk = "base",
                 theta_omega_kappa_brk = "interaction")

coef_rows <- list(); gate_rows <- list(); dols_rows <- list()
mp_rows <- list(); dec_rows <- list()

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
    "standardized CN: A=%s B=%s C=%s; threshold %d; reported regime %s",
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
        spec = "Spec_B_FullSample", taxonomy = "B4_wage_break",
        taxonomy_label = "Full-sample, no standalone kappa, wage-channel slope shift only",
        window = WINDOW_KEY, era_label = "Full Sample (1929-2024)",
        internal_slope_interaction = if (interacted) "Yes" else "No",
        tb_star = TB_STAR, tb_source = TB_SOURCE,
        tb_distance_from_theory = TB_DISTANCE, theory_date = THEORY_DATE,
        centering_regime = rg, is_reported_regime = identical(rg, reported),
        centering_note = centering_note,
        parameter = nm, design_column = col,
        estimate = est, fixed_b_har_t = tst, stars = s33_stars(tst),
        significant_5pct = if (is.na(tst)) NA else abs(tst) >= 1.96,
        implied_se = if (is.na(tst) || tst == 0) NA_real_ else abs(est) / abs(tst),
        sigma_u = dg$sigma_u,
        sigma_u_anchor_uncontrolled = S33_SPEC_B_ANCHORS$sigma_u_uncontrolled,
        sigma_u_anchor_controlled = S33_SPEC_B_ANCHORS$sigma_u_controlled,
        C_shin = dg$C_shin, C_shin_stars = dg$shin_stars,
        C_shin_anchor_uncontrolled = S33_SPEC_B_ANCHORS$C_shin_uncontrolled,
        C_shin_anchor_controlled = S33_SPEC_B_ANCHORS$C_shin_controlled,
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
            spec = "Spec_B_FullSample", window = WINDOW_KEY,
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

      # Marginal product of the gap. No standalone intercept term by construction.
      gvv <- function(p, col = "estimate") {
        r <- vapply(coef_rows, function(x)
          if (x$parameter == p && x$centering_regime == rg &&
              x$internal_slope_interaction == (if (interacted) "Yes" else "No"))
            x[[col]] else NA_real_, numeric(1))
        r <- r[!is.na(r)]; if (length(r)) r[1] else NA_real_
      }
      th_wk <- gvv("theta_omega_kappa"); th_pk <- gvv("theta_kappa_pkappa")
      d2 <- gvv("theta_omega_kappa_brk")
      z <- function(x) ifelse(is.na(x), 0, x)
      mp_rows[[length(mp_rows) + 1L]] <- data.frame(
        spec = "Spec_B_FullSample", window = WINDOW_KEY,
        internal_slope_interaction = if (interacted) "Yes" else "No",
        tb_star = TB_STAR, mp_has_intercept = FALSE,
        early_omega_slope = th_wk, early_pkappa_slope = th_pk,
        late_omega_slope = th_wk + z(d2),
        late_pkappa_slope = th_pk,
        theta_omega_kappa_brk = d2,
        theta_omega_kappa_brk_t = gvv("theta_omega_kappa_brk", "fixed_b_har_t"),
        formula = paste("MP_kappa = theta_omega_kappa*omega + theta_kappa_pkappa*p_kappa;",
                        "no standalone intercept (kappa level excluded);",
                        "wage slope shifts by theta_omega_kappa_brk after T_B*;",
                        "price slope held constant (no theoretical break prediction)"),
        break_route_status = route, disposition = disposition,
        stringsAsFactors = FALSE)
    }
  }

  iv <- setNames(gv$integration_verdict, gv$variable)
  iv <- ifelse(iv == "I1_with_break", "I(1)", iv)
  terms_used <- c("kappa x omega_lag1", "kappa x p_kappa",
                  if (interacted) "kappa x omega_lag1 x D_TB")
  gl <- s33_interaction_gate_ledger(
    spec = sprintf("Spec_B_FullSample / %s / interaction=%s", WINDOW_KEY,
                   if (interacted) "Yes" else "No"),
    base_vars = BASE_VARS,
    interaction_terms = terms_used,
    integration_verdicts = iv,
    centering_regimes = S33_CENTERING_REGIMES)
  gl$window <- WINDOW_KEY
  gl$internal_slope_interaction <- if (interacted) "Yes" else "No"
  gl$reported_centering_regime <- reported
  gl$break_route_status <- route
  gate_rows[[length(gate_rows) + 1L]] <- gl
}

coef_ledger <- do.call(rbind, coef_rows)
gate_ledger <- do.call(rbind, gate_rows)
dols_ledger <- do.call(rbind, dols_rows)
mp_ledger   <- do.call(rbind, mp_rows)

s33_write_ledger(coef_ledger, CSV_DIR, "specB_full_sample_wage_break_coefficients.csv")
s33_write_ledger(gate_ledger, CSV_DIR, "specB_full_sample_interaction_gate_ledger.csv")
s33_write_ledger(dols_ledger, CSV_DIR, "specB_full_sample_dols_comparator_ledger.csv")
s33_write_ledger(mp_ledger,   CSV_DIR, "specB_full_sample_marginal_product_wage_channel.csv")

# ---------------------------------------------------------------------------
# 6. Slope-break decision
# ---------------------------------------------------------------------------

rep_coef <- coef_ledger[coef_ledger$is_reported_regime %in% TRUE &
                          coef_ledger$internal_slope_interaction == "Yes", , drop = FALSE]
brk <- rep_coef[rep_coef$parameter == "theta_omega_kappa_brk", , drop = FALSE]
brk_sig <- nrow(brk) == 1L && !is.na(brk$fixed_b_har_t) && abs(brk$fixed_b_har_t) >= 1.96
decision <- if (brk_sig) "retain_multiplicative_interaction" else
  "retain_additive_step_control"

decision_ledger <- data.frame(
  spec = "Spec_B_FullSample", window = WINDOW_KEY, tb_star = TB_STAR,
  tb_source = TB_SOURCE, tb_distance_from_theory = TB_DISTANCE,
  theta_omega_kappa_brk = if (nrow(brk)) brk$estimate else NA_real_,
  theta_omega_kappa_brk_t = if (nrow(brk)) brk$fixed_b_har_t else NA_real_,
  significant_5pct = brk_sig,
  s02_decision = decision,
  rule = paste("S01 Sec.3: a slope shift significant at 5% licenses the multiplicative",
               "branch; otherwise the additive step control suffices"),
  interpretation = if (brk_sig)
    paste("The wage-mechanization elasticity shifts at T_B*: the Fordist-to-Post-Fordist",
          "decoupling predicted by Sec.2.6 is present as an internal slope break.") else
    paste("No significant shift in the wage-mechanization elasticity at T_B*. On the full",
          "sample the channel is not detectably regime-dependent at this date; the",
          "step controls absorb the level movement."),
  break_route_status = route, disposition = disposition,
  stringsAsFactors = FALSE)
s33_write_ledger(decision_ledger, CSV_DIR, "specB_full_sample_slope_break_decision_ledger.csv")

# ---------------------------------------------------------------------------
# 7. Conditioning comparison against the split-sample worst cell
# ---------------------------------------------------------------------------
# Reads US_S33D's ledger READ-ONLY. Operationalises the motivation for this stage:
# whether trading the historical split for degrees of freedom, and three slope shifts
# for one, actually buys conditioning.

SPLIT_COEF <- s33_dir("S33D_IMOLS_SPEC_B", "csv",
                      "specB_break_interacted_imols_coefficients.csv")
cmp_rows <- list()
if (file.exists(SPLIT_COEF)) {
  sc <- utils::read.csv(SPLIT_COEF, stringsAsFactors = FALSE)
  sc <- sc[sc$is_reported_regime %in% c(TRUE, "TRUE") &
             sc$parameter == "theta_omega_kappa", , drop = FALSE]
  for (i in seq_len(nrow(sc))) {
    r <- sc[i, ]
    cmp_rows[[length(cmp_rows) + 1L]] <- data.frame(
      track = "split_sample (US_S33D)", taxonomy = r$taxonomy, window = r$window,
      internal_slope_interaction = r$internal_slope_interaction,
      T_obs = r$T_obs, k_reg = r$k_reg,
      std_condition_number = r$std_condition_number,
      theta_omega_kappa = r$estimate, fixed_b_har_t = r$fixed_b_har_t,
      implied_se = if (is.na(r$fixed_b_har_t) || r$fixed_b_har_t == 0) NA_real_ else
        abs(r$estimate) / abs(r$fixed_b_har_t),
      break_route_status = r$break_route_status,
      stringsAsFactors = FALSE)
  }
}
fs <- coef_ledger[coef_ledger$is_reported_regime %in% TRUE &
                    coef_ledger$parameter == "theta_omega_kappa", , drop = FALSE]
for (i in seq_len(nrow(fs))) {
  r <- fs[i, ]
  cmp_rows[[length(cmp_rows) + 1L]] <- data.frame(
    track = "full_sample (US_S33E)", taxonomy = r$taxonomy, window = r$window,
    internal_slope_interaction = r$internal_slope_interaction,
    T_obs = r$T_obs, k_reg = r$k_reg,
    std_condition_number = r$std_condition_number,
    theta_omega_kappa = r$estimate, fixed_b_har_t = r$fixed_b_har_t,
    implied_se = r$implied_se,
    break_route_status = r$break_route_status,
    stringsAsFactors = FALSE)
}
comparison_ledger <- do.call(rbind, cmp_rows)
s33_write_ledger(comparison_ledger, CSV_DIR,
                 "specB_full_sample_vs_split_sample_conditioning_comparison.csv")

for (i in seq_len(nrow(comparison_ledger))) {
  r <- comparison_ledger[i, ]
  log_msg(sprintf("  %-24s %-22s int=%-3s T=%-3s CN=%9.2f  theta=%8.2f (t=%6.2f, SE=%7.2f)",
                  r$track, r$window, r$internal_slope_interaction, r$T_obs,
                  r$std_condition_number, r$theta_omega_kappa, r$fixed_b_har_t,
                  r$implied_se))
}

# ---------------------------------------------------------------------------
# 8. Stage integrity
# ---------------------------------------------------------------------------

design_cols_all <- unique(coef_ledger$design_column)

integrity <- s33_integrity(
  checks = c(
    "step2_gate_consumed",
    "estimator_is_imols_not_dols",
    "single_window_only",
    "interaction_span_complete",
    "tb_star_sourced_from_s33a_search_not_hardcoded",
    "no_standalone_kappa_in_design",
    "no_kappa_pkappa_internal_break_column",
    "no_ls_run_on_interaction_product",
    "wage_channel_break_is_only_slope_shift",
    "conditioning_comparison_written",
    "outputs_confined_to_break_aware_tree"
  ),
  passed = c(
    nrow(gv) == length(BASE_VARS),
    all(grepl("IM-OLS", coef_ledger$estimator, fixed = TRUE)),
    identical(unique(coef_ledger$window), WINDOW_KEY),
    {
      ic <- coef_ledger$design_column[coef_ledger$internal_slope_interaction == "Yes"]
      !("kappa_omega_x_D" %in% ic) || all(c("kappa_x_D", "omega_x_D") %in% ic)
    },
    nrow(wm) > 0 && TB_STAR %in% wm$break_year,
    !any(design_cols_all == "kappa"),
    !any(design_cols_all == "kappa_pkappa_x_D"),
    !file.exists(s33_dir(STAGE, "csv", "lee_strazicich_interaction_product.csv")),
    # The theoretical commitment is that only the WAGE channel carries a slope shift.
    # After the 2026-07-31 span correction that is expressed as: the wage product
    # kappa_omega_x_D is present and the price product is not. kappa_x_D and omega_x_D are
    # span constituents required by the wage product, not additional theoretical shifts,
    # so their presence does not violate the commitment -- the earlier form of this check
    # conflated the two and would now reject a correctly specified design.
    ("kappa_omega_x_D" %in% design_cols_all) &&
      !any(c("kappa_pkappa_x_D", "kappa_p_kappa_x_D") %in% design_cols_all),
    nrow(comparison_ledger) > 0,
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
          fixed = TRUE)
  ),
  detail = c(
    paste0("read ", VERDICT_PATH, "; ", gate_verdicts, "; route ", route),
    "cointReg::cointRegIM via s33_imols; DOLS written only as diagnostic comparator",
    paste0("single window ", WINDOW_KEY, ", T=", unique(coef_ledger$T_obs)[1]),
    paste("span correction 2026-07-31: kappa.D and omega.D added alongside",
          "(kappa.omega).D; both were previously absent, which left theta_kappa_pkappa",
          "spanning [-0.744, 2.083] across centering regimes"),
    TB_SOURCE,
    "standalone kappa level excluded (B4 pattern); gap enters only via interactions",
    paste("price channel carries no internal break: Sec.2.6 predicts regime change in",
          "the wage-mechanization nexus only"),
    paste("kappa*omega is an O_p(T) degree-2 CPR regressor under E10V line 37;",
          "admissibility inherited from base series, never independently unit-root tested"),
    paste0("slope-shift columns present: ",
           paste(intersect(design_cols_all,
                           c("kappa_x_D", "kappa_omega_x_D", "kappa_pkappa_x_D")),
                 collapse = ", ")),
    paste0(nrow(comparison_ledger), " rows comparing full-sample against split-sample ",
           "theta_omega_kappa conditioning"),
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE)
  )
)

s33_write_ledger(integrity, CSV_DIR, "s33e_specB_full_sample_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33E")

log_msg("US_S33E complete. ", nrow(coef_ledger), " coefficient rows; T_B* = ", TB_STAR,
        "; decision: ", decision)
