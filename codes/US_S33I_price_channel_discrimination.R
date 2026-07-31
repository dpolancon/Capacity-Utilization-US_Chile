#!/usr/bin/env Rscript

# US_S33I_price_channel_discrimination.R
# ---------------------------------------------------------------------------
# The nested ladder A06 Sec.2 calls for, run to supply EVIDENCE on the price-channel
# sign conflict between Sec.3.2 and A06. Full sample, complete interaction span.
#
# ---------------------------------------------------------------------------
# THE CONFLICT, STATED PRECISELY.
#
# ch2_sec3_2_heterogeneous_capital_prelatex.md line 51 specifies an ADDITIVELY SEPARABLE
# marginal viability cost
#
#     MC(omega_{t-1}, p^kappa_t) = gamma_0 - gamma_1 omega_{t-1} + gamma_2 p^kappa_t
#
# with gamma_2 > 0 (line 53). Line 88 defines theta_kappa_pkappa = -gamma_2, so Sec.3.2
# predicts theta_kappa_pkappa < 0, and line 68 gives d kappa*/d p^kappa = gamma_2/(2 lambda_2) < 0.
#
# A06_RelativePrice_Mechanization_Theory.md line 53 specifies a MULTIPLICATIVE cost
#
#     c(q; omega, p^rel) = a - q (1 - omega) e^{-p^rel}
#
# and line 72 reports d q*/d p^rel = -(1-omega) e^{-p^rel} / (2 lambda_2) > 0.
#
# TWO THINGS MUST BE SAID ABOUT THAT COMPARISON, AND THIS SCRIPT ONLY RECORDS THEM.
#
# (a) THE OBJECTS DIFFER. Sec.3.2's theta_kappa_pkappa is a coefficient in the CAPACITY
#     equation: it is how p^kappa shifts the marginal capacity payoff MP_kappa (line 86).
#     A06 line 72 is a comparative static on the OPTIMAL CHOICE q*. A06 never derives a
#     sign for its own estimating coefficient theta_{2,tau} in its Spec B3 (line 102);
#     the "A06 predicts positive" reading found in specB5_price_channel_sign_conflict.csv
#     is an inference across that gap, not a claim A06 makes.
#
# (b) A06 IS INTERNALLY INCONSISTENT AT THAT POINT. Line 72 states d q*/d p^rel > 0, but
#     line 74 glosses it as "cheapening of machinery ... accelerates mechanization
#     intensity", which is d q*/d p^rel < 0. The prose agrees with Sec.3.2; the formula
#     does not. Under A06's own algebra the formula follows from its setup, so the
#     discrepancy is in the model, not in the differentiation.
#
# This script does NOT adjudicate. It records both readings, estimates the ladder, and
# writes what the data can and cannot separate. The theoretical choice stays with the
# author. See A06_S32_PriceChannel_Reconciliation.md for the full write-up.
#
# ---------------------------------------------------------------------------
# THE LADDER (A06 Sec.2, mapped onto Sec.3.2's kappa notation).
#
#   A1  no price term        y = theta_NRC k^NRC + theta_kappa kappa + beta_omega omega
#                                + theta_omega_kappa (kappa . omega)
#   A2  additive price       A1 + beta_pkappa p^kappa_t
#   A3  fully interacted     A2 + theta_kappa_pkappa (kappa . p^kappa)
#
# A3 is estimated under TWO timings, which is the only place the two drafts differ
# operationally:
#   - contemporaneous: kappa . p^kappa_t     (Sec.3.2 line 94; this is Spec B5)
#   - lagged:          kappa . p^kappa_{t-1} (A06 line 102's theta_{2,tau} term)
# A06 keeps the ADDITIVE price contemporaneous even in its B3, so the additive term is
# p^kappa_t under both timings and only the interaction moves. A1 and A2 therefore carry
# no timing distinction and are estimated once.
#
# ---------------------------------------------------------------------------
# WHAT IS NOT HERE.
#   - No three-way kappa.omega.p^kappa. Sec.3.2's cost is additively separable and derives
#     no such term. A06's cross-partial (line 78) is non-zero, which is the sharpest formal
#     difference between the drafts, but it concerns the OPTIMAL GAP rather than the
#     capacity equation and so does not license the regressor. Logged in the verdict.
#   - No unit-root test on any cross-product. E10V line 37: degree-2 CPR regressors inherit
#     admissibility from the base series. Testing them would contradict the estimator lock.
#   - No (kappa.p^kappa).D_t. Sec.2.6's regime prediction is specific to the
#     wage-mechanization nexus; the price channel carries no comparable prediction.
#
# All three centering regimes are reported, per N11 Sec.1: only interaction-class
# parameters are claimed invariant, and only those are gated.
#
# Usage:
#   Rscript codes/US_S33I_price_channel_discrimination.R
#   (run US_S33A and US_S33B first)
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

STAGE   <- "S33I_PRICE_CHANNEL_DISCRIMINATION"
OUT_DIR <- s33_dir(STAGE)
CSV_DIR <- file.path(OUT_DIR, "csv")
LOG_DIR <- file.path(OUT_DIR, "logs")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33I_execution_log.txt")
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
TB_STAR   <- as.integer(wm$break_year[which.min(abs(wm$break_year - THEORY_DATE))])
TB_SOURCE <- paste0("US_S33A Sec.6.5 Bai-Perron univariate_mean on d_kappa_omega, ",
                    WINDOW_KEY, "; selected nearest ", THEORY_DATE, " = ", TB_STAR)
log_msg("T_B* = ", TB_STAR)

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
# Lag the price on the FULL panel before windowing so the window start is not sacrificed.
panel <- panel[order(panel$year), ]
panel$p_kappa_lag1 <- c(NA_real_, utils::head(panel$p_kappa, -1L))
log_msg("Spec B panel: ", nrow(panel), " rows, ", min(panel$year), "-", max(panel$year))

# The ladder. `price_mode` selects which price columns enter.
#   none        -> A1
#   additive    -> A2
#   interacted  -> A3 (with `price_timing` choosing the interaction's timing)
RUNGS <- list(
  A1 = list(rung = "A1", label = "no price term",              price_mode = "none",
            timings = "not_applicable"),
  A2 = list(rung = "A2", label = "additive price control",     price_mode = "additive",
            timings = "not_applicable"),
  A3 = list(rung = "A3", label = "fully interacted price",     price_mode = "interacted",
            timings = c("contemporaneous_sec32", "lagged_a06"))
)

fit_model <- function(price_mode, price_timing, interacted, regime) {
  win <- S33_WINDOWS[[WINDOW_KEY]]
  d <- s33_window(panel, win)
  need <- c("y", "k_NRC", "kappa", "p_kappa", "omega_lag1")
  if (identical(price_timing, "lagged_a06")) need <- c(need, "p_kappa_lag1")
  d <- d[stats::complete.cases(d[, need]), , drop = FALSE]
  yr <- d$year; y <- d$y

  kn <- s33_center(d$k_NRC, regime)
  kp <- s33_center(d$kappa, regime)
  pk <- s33_center(d$p_kappa, regime)
  w  <- s33_center(d$omega_lag1, regime)

  X <- cbind(k_NRC = kn, kappa = kp, omega = w)
  base_cols <- c("k_NRC", "kappa", "omega")
  X <- cbind(X, kappa_x_omega = kp * w)
  inter_cols <- "kappa_x_omega"
  price_cols <- character(0)

  if (price_mode %in% c("additive", "interacted")) {
    # A06 keeps the ADDITIVE price contemporaneous under both timings.
    X <- cbind(X, p_kappa = pk)
    base_cols <- c(base_cols, "p_kappa")
    price_cols <- c(price_cols, "p_kappa")
  }
  if (price_mode == "interacted") {
    pk_int <- if (identical(price_timing, "lagged_a06")) {
      s33_center(d$p_kappa_lag1, regime)
    } else pk
    X <- cbind(X, kappa_x_pkappa = kp * pk_int)
    inter_cols <- c(inter_cols, "kappa_x_pkappa")
    price_cols <- c(price_cols, "kappa_x_pkappa")
  }

  stepm <- build_steps(yr)
  if (!is.null(stepm)) X <- cbind(X, stepm)

  if (interacted) {
    D <- s33_step(yr, TB_STAR)
    if (stats::sd(D) == 0) return(NULL)
    # COMPLETE SPAN: kappa_omega_x_D requires kappa_x_D and omega_x_D alongside D_TB.
    X <- cbind(X, D_TB = D,
               kappa_x_D = kp * D,
               omega_x_D = w * D,
               kappa_omega_x_D = kp * w * D)
    inter_cols <- c(inter_cols, "kappa_x_D", "omega_x_D", "kappa_omega_x_D")
  }

  s33_assert_no_fwl(X, inter_cols, base_cols)
  if (interacted) {
    s33_assert_complete_span(X, products = list(c("kappa", "omega")))
  }

  deter <- matrix(1, nrow = length(y), ncol = 1)
  fit <- tryCatch(s33_imols(X, y, deter = deter), error = function(e) e)
  if (inherits(fit, "error")) return(list(error = conditionMessage(fit)))

  wald <- if (length(price_cols)) {
    tryCatch(s33_joint_wald(fit, price_cols), error = function(e) list(F_stat = NA_real_, p_val = NA_real_))
  } else list(F_stat = NA_real_, p_val = NA_real_)

  list(fit = fit, X = X, y = y, year = yr, T_obs = length(y),
       n_design_cols = ncol(X), residual_df = length(y) - ncol(X) - 1L,
       price_cols = price_cols, wald = wald,
       cond = std_condition(cbind(1, X)), error = NA_character_)
}

# ---------------------------------------------------------------------------
# 4. Estimate the ladder
# ---------------------------------------------------------------------------

COEF_MAP <- c(theta_NRC = "k_NRC", theta_kappa = "kappa", beta_omega = "omega",
              beta_pkappa = "p_kappa",
              theta_omega_kappa = "kappa_x_omega",
              theta_kappa_pkappa = "kappa_x_pkappa",
              gamma_1 = "D_TB",
              theta_kappa_brk = "kappa_x_D",
              beta_omega_brk = "omega_x_D",
              theta_omega_kappa_brk = "kappa_omega_x_D")

PARAM_CLASS <- c(theta_NRC = "interaction", theta_kappa = "base", beta_omega = "base",
                 beta_pkappa = "base",
                 theta_omega_kappa = "interaction",
                 theta_kappa_pkappa = "interaction",
                 gamma_1 = "base", theta_kappa_brk = "base", beta_omega_brk = "base",
                 theta_omega_kappa_brk = "interaction")

coef_rows <- list(); model_rows <- list()

for (rk in names(RUNGS)) {
  spec <- RUNGS[[rk]]
  for (timing in spec$timings) {
    for (interacted in c(FALSE, TRUE)) {
      conds <- list(); fits <- list()
      for (rg in S33_CENTERING_REGIMES) {
        m <- fit_model(spec$price_mode, timing, interacted, rg)
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
      log_msg(rk, "/", timing, "/int=", if (interacted) "Yes" else "No", ": ", centering_note)

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
            spec = "Spec_B_PriceLadder", rung = spec$rung, rung_label = spec$label,
            price_timing = timing, window = WINDOW_KEY,
            internal_slope_interaction = if (interacted) "Yes" else "No",
            tb_star = TB_STAR, centering_regime = rg,
            is_reported_regime = identical(rg, reported),
            centering_note = centering_note,
            parameter = nm, parameter_class = unname(PARAM_CLASS[[nm]]),
            design_column = col,
            estimate = est, fixed_b_har_t = tst, stars = s33_stars(tst),
            significant_5pct = if (is.na(tst)) NA else abs(tst) >= 1.96,
            sigma_u = dg$sigma_u, C_shin = dg$C_shin, C_shin_stars = dg$shin_stars,
            residual_adf = dg$t_adf, residual_adf_stars = dg$adf_stars,
            r2_level = dg$r2_level, r2_sum = dg$r2_sum,
            T_obs = m$T_obs, k_reg = dg$k_reg,
            n_design_cols = m$n_design_cols, residual_df = m$residual_df,
            std_condition_number = m$cond,
            estimator = "IM-OLS (cointReg::cointRegIM), E10V active lock",
            break_route_status = route, disposition = disposition,
            stringsAsFactors = FALSE)
        }

        m2 <- m
        model_rows[[length(model_rows) + 1L]] <- data.frame(
          spec = "Spec_B_PriceLadder", rung = spec$rung, rung_label = spec$label,
          price_timing = timing, window = WINDOW_KEY,
          internal_slope_interaction = if (interacted) "Yes" else "No",
          centering_regime = rg, is_reported_regime = identical(rg, reported),
          T_obs = m2$T_obs, n_design_cols = m2$n_design_cols,
          residual_df = m2$residual_df, std_condition_number = m2$cond,
          sigma_u = dg$sigma_u, C_shin = dg$C_shin, C_shin_stars = dg$shin_stars,
          residual_adf = dg$t_adf, residual_adf_stars = dg$adf_stars,
          r2_level = dg$r2_level,
          price_terms_tested = if (length(m2$price_cols))
            paste(m2$price_cols, collapse = "+") else NA_character_,
          joint_wald_F = m2$wald$F_stat, joint_wald_p = m2$wald$p_val,
          joint_wald_sig_5pct = if (is.na(m2$wald$p_val)) NA else m2$wald$p_val < 0.05,
          stringsAsFactors = FALSE)
      }
    }
  }
}

coef_ledger  <- do.call(rbind, coef_rows)
model_ledger <- do.call(rbind, model_rows)
s33_write_ledger(coef_ledger, CSV_DIR, "specB_price_channel_discrimination.csv")
s33_write_ledger(model_ledger, CSV_DIR, "specB_price_channel_model_comparison.csv")

# ---------------------------------------------------------------------------
# 5. Centering stability, gated on interaction-class only (N11 Sec.1)
# ---------------------------------------------------------------------------

stab_rows <- list()
key_cols <- c("rung", "price_timing", "internal_slope_interaction")
keys <- unique(coef_ledger[, key_cols, drop = FALSE])
for (i in seq_len(nrow(keys))) {
  k <- keys[i, ]
  sub_i <- coef_ledger[coef_ledger$rung == k$rung &
                         coef_ledger$price_timing == k$price_timing &
                         coef_ledger$internal_slope_interaction ==
                           k$internal_slope_interaction, , drop = FALSE]
  for (nm in unique(sub_i$parameter)) {
    s <- sub_i[sub_i$parameter == nm, , drop = FALSE]
    est <- s$estimate[is.finite(s$estimate)]
    if (length(est) < 2L) next
    scale <- mean(abs(est))
    stab_rows[[length(stab_rows) + 1L]] <- data.frame(
      spec = "Spec_B_PriceLadder", rung = k$rung, price_timing = k$price_timing,
      internal_slope_interaction = k$internal_slope_interaction,
      parameter = nm, parameter_class = s$parameter_class[1],
      n_regimes = length(est), est_min = min(est), est_max = max(est),
      absolute_spread = max(est) - min(est),
      relative_spread = if (scale > 0) (max(est) - min(est)) / scale else NA_real_,
      sign_stable = length(unique(sign(est))) == 1L,
      all_significant_5pct = all(s$significant_5pct %in% TRUE),
      gated = s$parameter_class[1] == "interaction",
      stringsAsFactors = FALSE)
  }
}
stability <- do.call(rbind, stab_rows)
s33_write_ledger(stability, CSV_DIR, "specB_price_channel_centering_stability.csv")

gated <- stability[stability$gated %in% TRUE, , drop = FALSE]
GATE_PASS <- nrow(gated) > 0 && all(gated$sign_stable %in% TRUE)
log_msg("")
log_msg("CENTERING GATE (interaction-class): ",
        sum(gated$sign_stable %in% TRUE), "/", nrow(gated), " sign-stable -> ",
        if (GATE_PASS) "PASS" else "FAIL")

# ---------------------------------------------------------------------------
# 6. Verdict ledger -- evidence recorded, theory NOT adjudicated
# ---------------------------------------------------------------------------

pk <- stability[stability$parameter == "theta_kappa_pkappa", , drop = FALSE]
v_rows <- list()
add_v <- function(question, evidence, favours, note) {
  v_rows[[length(v_rows) + 1L]] <<- data.frame(
    question = question, evidence = evidence, favours = favours, note = note,
    adjudicated = FALSE, stringsAsFactors = FALSE)
}

for (i in seq_len(nrow(pk))) {
  r <- pk[i, ]
  fav <- if (!r$sign_stable) "indeterminate (sign not stable across centering)" else
    if (r$est_max < 0) "Sec.3.2 (theta_kappa_pkappa < 0)" else
      "A06 line 72 as literally written (theta_kappa_pkappa > 0)"
  add_v(
    sprintf("Sign of theta_kappa_pkappa, timing=%s, break-interaction=%s",
            r$price_timing, r$internal_slope_interaction),
    sprintf("centering range [%.4f, %.4f]; sign_stable=%s; all sig at 5%%=%s",
            r$est_min, r$est_max, r$sign_stable, r$all_significant_5pct),
    fav,
    "Sec.3.2 line 88 predicts negative. A06 makes no direct prediction for this coefficient.")
}

rep_m <- model_ledger[model_ledger$is_reported_regime %in% TRUE, , drop = FALSE]
a3 <- rep_m[rep_m$rung == "A3", , drop = FALSE]
for (int in unique(a3$internal_slope_interaction)) {
  s <- a3[a3$internal_slope_interaction == int, , drop = FALSE]
  con <- s[s$price_timing == "contemporaneous_sec32", , drop = FALSE]
  lag <- s[s$price_timing == "lagged_a06", , drop = FALSE]
  if (nrow(con) && nrow(lag)) {
    fav <- if (con$sigma_u[1] < lag$sigma_u[1]) "Sec.3.2 timing (contemporaneous)" else
      if (lag$sigma_u[1] < con$sigma_u[1]) "A06 timing (lagged)" else "tie"
    add_v(
      sprintf("Which price timing fits better (break-interaction=%s)", int),
      sprintf("sigma_u contemporaneous=%.5f vs lagged=%.5f; C_shin %.5f vs %.5f; residual ADF %.3f vs %.3f",
              con$sigma_u[1], lag$sigma_u[1], con$C_shin[1], lag$C_shin[1],
              con$residual_adf[1], lag$residual_adf[1]),
      fav,
      "Fit differences this small do not by themselves settle a timing convention.")
  }
}

for (int in unique(rep_m$internal_slope_interaction)) {
  s <- rep_m[rep_m$internal_slope_interaction == int, , drop = FALSE]
  a1 <- s[s$rung == "A1", , drop = FALSE]
  a2 <- s[s$rung == "A2", , drop = FALSE]
  if (nrow(a1) && nrow(a2)) {
    add_v(
      sprintf("Marginal contribution of the ADDITIVE price control A1->A2 (break-interaction=%s)", int),
      sprintf("sigma_u %.5f -> %.5f; CN %.1f -> %.1f; joint Wald on price terms F=%.3f p=%.4f",
              a1$sigma_u[1], a2$sigma_u[1], a1$std_condition_number[1],
              a2$std_condition_number[1], a2$joint_wald_F[1], a2$joint_wald_p[1]),
      "neither (rung test, not a sign test)",
      "A06 Sec.2 poses B2 as a standalone option; this separates it from the interacted rung.")
  }
  a3c <- s[s$rung == "A3" & s$price_timing == "contemporaneous_sec32", , drop = FALSE]
  if (nrow(a2) && nrow(a3c)) {
    add_v(
      sprintf("Marginal contribution of the INTERACTION A2->A3 contemporaneous (break-interaction=%s)", int),
      sprintf("sigma_u %.5f -> %.5f; CN %.1f -> %.1f; joint Wald on price terms F=%.3f p=%.4f",
              a2$sigma_u[1], a3c$sigma_u[1], a2$std_condition_number[1],
              a3c$std_condition_number[1], a3c$joint_wald_F[1], a3c$joint_wald_p[1]),
      "neither (rung test, not a sign test)",
      "Whether the price channel needs to be state-dependent at all.")
  }
}

add_v("Are the two drafts comparing the same object?",
      "Sec.3.2 line 88 defines theta_kappa_pkappa inside the CAPACITY equation; A06 line 72 is a comparative static on the OPTIMAL GAP q*. A06 derives no sign for its own theta_{2,tau} (line 102).",
      "neither -- the objects differ",
      "The 'A06 predicts positive' reading is an inference across that gap, not a claim A06 makes.")

add_v("Is A06 internally consistent at the price channel?",
      "A06 line 72 states d q*/d p^rel > 0; A06 line 74 glosses it as cheapening machinery accelerating mechanization, i.e. d q*/d p^rel < 0. The prose agrees with Sec.3.2 line 68; the formula does not.",
      "unresolved within A06 itself",
      "Recorded for the author. This script does not choose between A06's formula and its prose.")

add_v("Open route not taken here",
      "A06 line 78 gives a non-zero cross-partial d2 q*/(d omega d p^rel) < 0, whereas Sec.3.2's additively separable cost implies zero. That is the sharpest formal difference between the drafts.",
      "neither (not estimated)",
      "It concerns the optimal gap rather than the capacity equation, so it does not license a three-way kappa.omega.p^kappa regressor here.")

verdict <- do.call(rbind, v_rows)
s33_write_ledger(verdict, CSV_DIR, "specB_price_channel_verdict.csv")

log_msg("")
log_msg("VERDICT LEDGER")
for (i in seq_len(nrow(verdict))) {
  log_msg("  ", verdict$question[i])
  log_msg("      favours: ", verdict$favours[i])
}

# ---------------------------------------------------------------------------
# 7. Integrity
# ---------------------------------------------------------------------------

design_cols <- unique(coef_ledger$design_column)
int_cols <- coef_ledger$design_column[coef_ledger$internal_slope_interaction == "Yes"]

integrity <- s33_integrity(
  checks = c("step2_gate_consumed",
             "all_three_rungs_estimated",
             "both_price_timings_estimated_at_A3",
             "interaction_span_complete_when_break_interacted",
             "no_three_way_interaction",
             "no_price_break_interaction",
             "all_three_centering_regimes_reported",
             "joint_wald_computed_for_price_rungs",
             "verdict_records_without_adjudicating",
             "outputs_confined_to_break_aware_tree"),
  passed = c(
    nrow(gv) == length(BASE_VARS),
    identical(sort(unique(coef_ledger$rung)), c("A1", "A2", "A3")),
    all(c("contemporaneous_sec32", "lagged_a06") %in%
          coef_ledger$price_timing[coef_ledger$rung == "A3"]),
    all(c("kappa_x_D", "omega_x_D", "kappa_omega_x_D") %in% int_cols),
    !any(grepl("kappa.*omega.*pkappa|three_way", design_cols)),
    !any(grepl("pkappa_x_D|p_kappa_x_D", design_cols)),
    identical(sort(unique(coef_ledger$centering_regime)), sort(S33_CENTERING_REGIMES)),
    any(is.finite(model_ledger$joint_wald_F[model_ledger$rung != "A1"])),
    nrow(verdict) > 0 && all(verdict$adjudicated == FALSE),
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
          fixed = TRUE)
  ),
  detail = c(
    paste0("read ", VERDICT_PATH, "; ", gate_verdicts, "; route ", route),
    "A06 Sec.2 ladder: A1 no price, A2 additive, A3 fully interacted",
    "A3 estimated under Sec.3.2 contemporaneous and A06 lagged interaction timing",
    "kappa_omega_x_D accompanied by kappa_x_D and omega_x_D",
    "Sec.3.2 cost is additively separable; A06 cross-partial logged as an open route",
    "Sec.2.6's regime prediction is specific to the wage-mechanization nexus",
    "base coefficients move by design (N11 Sec.1 point 2); no single regime is the model",
    "joint Wald on the price block at A2 and A3",
    paste0(nrow(verdict), " verdict rows; adjudicated=FALSE throughout"),
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE)
  )
)
s33_write_ledger(integrity, CSV_DIR, "s33i_price_channel_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33I")

log_msg("US_S33I complete. ", nrow(coef_ledger), " coefficient rows, ",
        nrow(model_ledger), " model rows, ", nrow(verdict), " verdict rows.")
