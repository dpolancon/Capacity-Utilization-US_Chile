#!/usr/bin/env Rscript

# US_S33D_break_interacted_imols_specB.R
# ---------------------------------------------------------------------------
# Step 3 of the binding S0* sequence, Specification B (disaggregated capital):
#
#     Break-interacted IM-OLS estimation over the nested B1 -> B2 -> B3 taxonomy,
#     with the three within-sample multiplicative slope shifts of S02 Sec.3,
#     gated on the US_S33B integration-order verdict.
#
# Authority:
#   S02 Sec.1 -- nested taxonomy. kappa_t = k_t^ME - k_t^NRC is the mechanization gap;
#       k_t^NRC is extensive plant scale; p_t^kappa = ln P^ME - ln P^NRC.
#       B1 (uninteracted baseline):
#           y = alpha + theta_NRC k^NRC + theta_kappa kappa + beta_pkappa p^kappa
#               + beta_omega omega_{t-1} + gamma' D + u
#       B2 (distribution interacted):  B1 + theta_omega_kappa (kappa . omega_{t-1})
#       B3 (canonical fully interacted): B2 + theta_kappa_pkappa (kappa . p^kappa)
#   S02 Sec.3 -- within-sample multiplicative slope interaction, THREE delta terms:
#       B3 + delta_1 [kappa . D_t(T_B*)]
#          + delta_2 [(kappa . omega_{t-1}) . D_t(T_B*)]
#          + delta_3 [(kappa . p^kappa) . D_t(T_B*)]
#       Marginal product of the gap:
#           MP_kappa = theta_kappa + theta_omega_kappa omega + theta_kappa_pkappa p^kappa
#                        for t <  T_B*
#           MP_kappa = (theta_kappa+delta_1) + (theta_omega_kappa+delta_2) omega
#                        + (theta_kappa_pkappa+delta_3) p^kappa   for t >= T_B*
#   S02 Sec.4 -- comparison anchors: Shin LM falls from 0.261 to 0.042 and sigma_u from
#       0.200 to 0.112 once step/slope controls enter.
#   S02 Sec.5 -- the four-column "Table 3.2" reporting matrix this script emits.
#   S02 Sec.6 -- interactions built for T_1947 (Fordism) and T_2008 (Post-Fordism).
#   E10V -- IM-OLS/CPR is the estimator; DOLS is a diagnostic comparator; FWL
#       orthogonalization of interaction terms is FORBIDDEN.
#
# ---------------------------------------------------------------------------
# RESOLVED GAP IN S02. Sec.3 defines delta_3 on (kappa . p^kappa) . D_t, but the Sec.5
# "Table 3.2" template carries no delta_3 row -- it stops at delta_2. Dropping the term
# to match the template would silently discard a parameter the protocol defines, so this
# script estimates delta_3 and ADDS a "Price Interaction Shift (delta_3)" row to the
# emitted matrix. The addition is recorded in the table's provenance column rather than
# made silently.
#
# ---------------------------------------------------------------------------
# BREAK-DATE ARCHITECTURE -- identical to US_S33C and settled with the author on
# 2026-07-30. Split samples are historical and fixed (Fordism to 1973, Post-Fordism from
# 1974). T_B* = 1947 / 2008 carries the multiplicative slope shift per S02 Sec.6.
# Bai-Perron dates enter as ADDITIVE controls only: D_1933 plus a 1942-1945 war block in
# Fordism; D_1981 and D_2000 in Post-Fordism. US_S33A's Spec B prescan lands at 1943-1945
# in Fordism and 1980/1990/1998 in Post-Fordism, which is what those controls absorb.
#
# ROUTE LABELLING -- as in US_S33C and codes/CL_S32_break_aware_machinery_v6.R:
# estimation always runs, and a window whose base variables do not all clear the Step 2
# gate is labelled estimated_as_exploratory_with_limitation on every coefficient row.
# This matters here: US_S33B returns persistent_I2_risk for kappa_t in the Post-Fordist
# window, so that whole era is an exploratory route and must be reported as one.
#
# CENTERING -- Regime A main, Regime B primary robustness (E10V). AGENTS.md directs
# logging the condition number and defaulting to Regime B rather than blocking; the
# reported regime is chosen by the standardized condition number, as in US_S33C.
#
# Governance: artifacts land under output/US/BREAK_AWARE_IMOLS/S33D_IMOLS_SPEC_B/.
#
# Usage:
#   Rscript codes/US_S33D_break_interacted_imols_specB.R
# ---------------------------------------------------------------------------

source(file.path(Sys.getenv("CH2_REPO_ROOT", "C:/ReposGitHub/Capacity-Utilization-US_Chile"),
                 "codes", "US_S33_break_aware_common.R"))

STAGE   <- "S33D_IMOLS_SPEC_B"
OUT_DIR <- s33_dir(STAGE)
CSV_DIR <- file.path(OUT_DIR, "csv")
LOG_DIR <- file.path(OUT_DIR, "logs")
s33_ensure_dir(CSV_DIR); s33_ensure_dir(LOG_DIR)

LOG_PATH <- file.path(LOG_DIR, "S33D_execution_log.txt")
log_msg <- function(...) {
  line <- paste0("[", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "] ", paste0(..., collapse = ""))
  cat(line, "\n", sep = "")
  cat(line, "\n", sep = "", file = LOG_PATH, append = TRUE)
}
cat("", file = LOG_PATH)

# ---------------------------------------------------------------------------
# 1. Step 2 gate
# ---------------------------------------------------------------------------

VERDICT_PATH <- s33_dir("S33B_LEE_STRAZICICH", "csv", "integration_order_verdict.csv")
if (!file.exists(VERDICT_PATH)) {
  stop("Step 2 verdict not found at ", VERDICT_PATH, ".\n",
       "Run codes/US_S33B_lee_strazicich_break_robust_unitroot.R first: S02 Stage 2B gates ",
       "Stage 3 on the Lee-Strazicich integration-order result.")
}
verdicts <- utils::read.csv(VERDICT_PATH, stringsAsFactors = FALSE)
log_msg("Step 2 gate read from ", VERDICT_PATH, " (", nrow(verdicts), " rows)")

BASE_VARS <- c("k_NRC", "kappa", "p_kappa")

gate_for <- function(window_key) {
  v <- verdicts[verdicts$spec == "Spec_B" & verdicts$window == window_key &
                  verdicts$variable %in% BASE_VARS, , drop = FALSE]
  ok <- setNames(rep(FALSE, length(BASE_VARS)), BASE_VARS)
  for (b in BASE_VARS) {
    r <- v[v$variable == b, , drop = FALSE]
    ok[b] <- nrow(r) == 1L && r$integration_verdict == "I1_with_break"
  }
  list(all_pass = all(ok), per_var = ok,
       verdict_string = paste(sprintf("%s=%s", v$variable, v$integration_verdict),
                              collapse = "; "),
       failing = paste(names(ok)[!ok], collapse = ", "))
}

# ---------------------------------------------------------------------------
# 2. Window architecture (mirrors US_S33C)
# ---------------------------------------------------------------------------

WINDOWS <- list(
  Fordist_1929_1973 = list(
    key = "Fordist_1929_1973", label = "Fordist Era (1929-1973)",
    tb_star = 1947L, tb_source = "S02 Sec.6 Step 1 (T_1947 inside Fordism)",
    steps = list(
      list(name = "D_1933", type = "step", args = list(1933L),
           rationale = "New Deal regime change; permanent level shift"),
      list(name = "B_1942_1945", type = "block", args = list(1942L, 1945L),
           rationale = "WWII mobilisation; reverses on demobilisation (S33A Spec B: 1943, 1945)")
    )),
  Post_Fordist_1974_2024 = list(
    key = "Post_Fordist_1974_2024", label = "Post-Fordist Era (1974-2024)",
    tb_star = 2008L, tb_source = "S02 Sec.6 Step 1 (T_2008 inside Post-Fordism)",
    steps = list(
      list(name = "D_1981", type = "step", args = list(1981L),
           rationale = "Volcker disinflation; Bai-Perron supported (S33A Spec B: 1980/1981)"),
      list(name = "D_2000", type = "step", args = list(2000L),
           rationale = "Dot-Com crash; Bai-Perron supported (S33A Spec B: 1998)")
    ))
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

# S02 Sec.1 nested taxonomy (B1 -> B2 -> B3). B3 is canonical and is what Table 3.2
# reports.
#
# B4 is NOT in S02. It is added under chapter2_vault/03_econometrics/
# standalone_kappa_exclusion_assessment.md, which argues that carrying the standalone
# log level of the mechanization gap alongside its own interaction terms induces
# structural collinearity: kappa_t and kappa_t * omega_{t-1} move together in level
# space, so the estimator has to untangle two near-parallel columns and inflates the
# standard errors of both. Dropping standalone kappa gives the pure
# distribution/price-conditioned model
#
#   y = alpha + theta_NRC k^NRC + beta_pkappa p^kappa + beta_omega omega_{t-1}
#       + theta_omega_kappa (kappa . omega_{t-1}) + theta_kappa_pkappa (kappa . p^kappa)
#       + gamma' D + u
#
# The theoretical warrant is Marxian choice-of-technique (Okishio 1961; Foley & Michl
# 1999; Shaikh 2016): capitalists do not raise the machinery-to-structures ratio out of
# a distribution-neutral propensity to mechanise. Technical choice is driven by
# distributional conflict and by relative asset prices, so kappa_t belongs in the
# capacity relation as a state-dependent CHANNEL, not as an autonomous physical level.
# Omitted-main-effect bias is the standard objection; it does not bite here because the
# main effect is not a behavioural primitive of the model being estimated.
#
# use_standalone_kappa is a flag rather than a separate code path so that the taxonomy
# loops, the gate ledger, and the integrity counts all scale on length(TAXONOMY).
TAXONOMY <- list(
  B1 = list(key = "B1", label = "Uninteracted Baseline",
            use_standalone_kappa = TRUE,
            use_omega_kappa = FALSE, use_kappa_pkappa = FALSE),
  B2 = list(key = "B2", label = "Distribution Interacted",
            use_standalone_kappa = TRUE,
            use_omega_kappa = TRUE,  use_kappa_pkappa = FALSE),
  B3 = list(key = "B3", label = "Canonical Fully Interacted",
            use_standalone_kappa = TRUE,
            use_omega_kappa = TRUE,  use_kappa_pkappa = TRUE),
  B4 = list(key = "B4", label = "Pure Distribution/Price-Conditioned (no standalone kappa)",
            use_standalone_kappa = FALSE,
            use_omega_kappa = TRUE,  use_kappa_pkappa = TRUE)
)

CN_THRESHOLD <- 30

std_condition <- function(X) {
  X <- as.matrix(X)
  s <- apply(X, 2, function(c) sqrt(sum(c^2)))
  s[s == 0 | !is.finite(s)] <- 1
  suppressWarnings(kappa(sweep(X, 2, s, "/"), exact = TRUE))
}

# ---------------------------------------------------------------------------
# 3. One model
# ---------------------------------------------------------------------------

fit_model <- function(win_spec, tax, interacted, regime) {
  win <- S33_WINDOWS[[win_spec$key]]
  d <- s33_window(panel, win)
  need <- c("y", "k_NRC", "kappa", "p_kappa", "omega_lag1")
  d <- d[stats::complete.cases(d[, need]), , drop = FALSE]
  yr <- d$year; y <- d$y

  kn <- s33_center(d$k_NRC, regime)
  kp <- s33_center(d$kappa, regime)
  pk <- s33_center(d$p_kappa, regime)
  w  <- s33_center(d$omega_lag1, regime)

  # kp stays available for the interaction products whether or not the standalone level
  # enters the design. Under B4 the level is dropped and base_cols shrinks with it, so
  # s33_assert_no_fwl() stops guarding against a column that is not there -- it already
  # intersects base_cols with colnames(X), so no change is needed in the helper.
  X <- cbind(k_NRC = kn, p_kappa = pk, omega = w)
  base_cols <- c("k_NRC", "p_kappa", "omega")
  if (isTRUE(tax$use_standalone_kappa)) {
    X <- cbind(X, kappa = kp)
    base_cols <- c(base_cols, "kappa")
  }
  inter_cols <- character(0)

  if (tax$use_omega_kappa) {
    X <- cbind(X, kappa_x_omega = kp * w)           # theta_omega_kappa
    inter_cols <- c(inter_cols, "kappa_x_omega")
  }
  if (tax$use_kappa_pkappa) {
    X <- cbind(X, kappa_x_pkappa = kp * pk)         # theta_kappa_pkappa
    inter_cols <- c(inter_cols, "kappa_x_pkappa")
  }

  stepm <- build_steps(yr, win_spec)
  if (!is.null(stepm)) X <- cbind(X, stepm)

  # SPAN CORRECTION (2026-07-31). Each break-interacted cross-product requires ALL its
  # lower-order constituents, or centering stops being a reparameterization and starts
  # selecting a different model. This script previously carried kappa_x_D but neither
  # omega_x_D nor pkappa_x_D, and dropped kappa_x_D entirely under B4 -- leaving the
  # Fordist interacted theta_omega_kappa spanning [-23.61, 47.79] across centering
  # regimes. s33_break_span() now emits the constituents automatically; note that
  # kappa_x_D is required whenever kappa appears inside a product, independently of
  # whether the standalone kappa LEVEL is in the design (B4 excludes the level but still
  # forms products in kappa). See US_S33F for the synthetic-data verification.
  products <- list()
  if (tax$use_omega_kappa)   products <- c(products, list(c("kappa", "omega")))
  if (tax$use_kappa_pkappa)  products <- c(products, list(c("kappa", "p_kappa")))

  if (interacted && length(products)) {
    D <- s33_step(yr, win_spec$tb_star)
    if (stats::sd(D) == 0) return(NULL)
    brk <- s33_break_span(D, vars = list(kappa = kp, omega = w, p_kappa = pk),
                          products = products)
    X <- cbind(X, brk)
    inter_cols <- c(inter_cols, setdiff(colnames(brk), "D_TB"))
    s33_assert_complete_span(X, products = products)
  } else if (interacted) {
    D <- s33_step(yr, win_spec$tb_star)
    if (stats::sd(D) == 0) return(NULL)
    X <- cbind(X, D_TB = D)                                     # B1: level shift only
  }

  if (length(inter_cols)) s33_assert_no_fwl(X, inter_cols, base_cols)

  deter <- matrix(1, nrow = length(y), ncol = 1)
  fit <- tryCatch(s33_imols(X, y, deter = deter), error = function(e) e)
  if (inherits(fit, "error")) return(list(error = conditionMessage(fit)))

  list(fit = fit, X = X, y = y, year = yr, T_obs = length(y),
       mean_omega = mean(w), mean_pkappa = mean(pk),
       cond = std_condition(cbind(1, X)), error = NA_character_)
}

# ---------------------------------------------------------------------------
# 4. Drive taxonomy x interaction x window x centering
# ---------------------------------------------------------------------------

panel <- s33_load_spec_b()
log_msg("Spec B panel: ", nrow(panel), " rows, ", min(panel$year), "-", max(panel$year))

COEF_MAP <- c(theta_NRC = "k_NRC", theta_kappa = "kappa",
              beta_pkappa = "p_kappa", beta_omega = "omega",
              theta_omega_kappa = "kappa_x_omega",
              theta_kappa_pkappa = "kappa_x_pkappa",
              gamma_1 = "D_TB", delta_1 = "kappa_x_D",
              # constituents added by the span correction
              beta_omega_brk = "omega_x_D", beta_pkappa_brk = "p_kappa_x_D",
              delta_2 = "kappa_omega_x_D", delta_3 = "kappa_p_kappa_x_D")

# N11 Sec.1 claims invariance for interaction-class parameters only; base-class ones shift
# with the point of evaluation by construction (Sec.1 point 2).
PARAM_CLASS <- c(theta_NRC = "interaction", theta_kappa = "base",
                 beta_pkappa = "base", beta_omega = "base",
                 theta_omega_kappa = "interaction",
                 theta_kappa_pkappa = "interaction",
                 gamma_1 = "base", delta_1 = "base",
                 beta_omega_brk = "base", beta_pkappa_brk = "base",
                 delta_2 = "interaction", delta_3 = "interaction")

coef_rows <- list(); gate_rows <- list(); dols_rows <- list(); mp_rows <- list()

for (wk in names(WINDOWS)) {
  wsp <- WINDOWS[[wk]]
  g <- gate_for(wk)
  route <- if (g$all_pass) "formal_break_supported" else "exploratory_break_route"
  disposition <- if (g$all_pass) "break_unlocked_for_formal_route" else
    "estimated_as_exploratory_with_limitation"
  log_msg(wsp$label, ": gate ", route, " [", g$verdict_string, "]")

  for (tk in names(TAXONOMY)) {
    tax <- TAXONOMY[[tk]]
    for (interacted in c(FALSE, TRUE)) {
      conds <- list(); fits <- list()
      for (rg in S33_CENTERING_REGIMES) {
        m <- fit_model(wsp, tax, interacted, rg)
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
      log_msg("  ", tk, " ", if (interacted) "with-interaction" else "no-interaction",
              ": ", centering_note)

      for (rg in S33_CENTERING_REGIMES) {
        m <- fits[[rg]]
        if (is.null(m) || !is.na(m$error)) {
          log_msg("    ", rg, " FAILED: ",
                  if (is.null(m)) "degenerate design" else m$error)
          next
        }
        f <- m$fit; dg <- f$diag

        for (nm in names(COEF_MAP)) {
          col <- COEF_MAP[[nm]]
          if (!(col %in% colnames(m$X))) next
          est <- s33_coef(f, col); tst <- s33_tstat(f, col)
          coef_rows[[length(coef_rows) + 1L]] <- data.frame(
            spec = "Spec_B", taxonomy = tk, taxonomy_label = tax$label,
            window = wk, era_label = wsp$label,
            internal_slope_interaction = if (interacted) "Yes" else "No",
            tb_star = wsp$tb_star, tb_source = wsp$tb_source,
            centering_regime = rg, is_reported_regime = identical(rg, reported),
            centering_note = centering_note,
            parameter = nm, design_column = col,
            estimate = est, fixed_b_har_t = tst, stars = s33_stars(tst),
            significant_5pct = if (is.na(tst)) NA else abs(tst) >= 1.96,
            sigma_u = dg$sigma_u,
            sigma_u_anchor_uncontrolled = S33_SPEC_B_ANCHORS$sigma_u_uncontrolled,
            sigma_u_anchor_controlled = S33_SPEC_B_ANCHORS$sigma_u_controlled,
            C_shin = dg$C_shin, C_shin_stars = dg$shin_stars,
            C_shin_anchor_uncontrolled = S33_SPEC_B_ANCHORS$C_shin_uncontrolled,
            C_shin_anchor_controlled = S33_SPEC_B_ANCHORS$C_shin_controlled,
            residual_adf = dg$t_adf, residual_adf_stars = dg$adf_stars,
            r2_level = dg$r2_level, r2_sum = dg$r2_sum,
            T_obs = m$T_obs, k_reg = dg$k_reg,
            std_condition_number = m$cond,
            step_controls = paste(vapply(wsp$steps, `[[`, character(1), "name"),
                                  collapse = "+"),
            estimator = "IM-OLS (cointReg::cointRegIM), E10V active lock",
            break_route_status = route, disposition = disposition,
            gate_verdicts = g$verdict_string,
            gate_failing_vars = if (nzchar(g$failing)) g$failing else NA_character_,
            stringsAsFactors = FALSE)
        }

        if (identical(rg, reported)) {
          dl <- tryCatch(s33_dols(m$X, m$y), error = function(e) NULL)
          if (!is.null(dl)) {
            for (nm in names(COEF_MAP)) {
              col <- COEF_MAP[[nm]]
              if (!(col %in% names(dl$estimate))) next
              dols_rows[[length(dols_rows) + 1L]] <- data.frame(
                spec = "Spec_B", taxonomy = tk, window = wk,
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

      iv <- setNames(
        verdicts$integration_verdict[verdicts$spec == "Spec_B" & verdicts$window == wk &
                                       verdicts$variable %in% BASE_VARS],
        verdicts$variable[verdicts$spec == "Spec_B" & verdicts$window == wk &
                            verdicts$variable %in% BASE_VARS])
      iv <- ifelse(iv == "I1_with_break", "I(1)", iv)
      terms_used <- c(
        if (tax$use_omega_kappa) "kappa x omega_lag1",
        if (tax$use_kappa_pkappa) "kappa x p_kappa",
        if (interacted) "kappa x D_TB",
        if (interacted && tax$use_omega_kappa) "kappa x omega_lag1 x D_TB",
        if (interacted && tax$use_kappa_pkappa) "kappa x p_kappa x D_TB")
      gl <- s33_interaction_gate_ledger(
        spec = sprintf("Spec_B / %s / %s / interaction=%s", tk, wk,
                       if (interacted) "Yes" else "No"),
        base_vars = BASE_VARS,
        interaction_terms = if (length(terms_used)) terms_used else "none (B1 uninteracted)",
        integration_verdicts = iv,
        centering_regimes = S33_CENTERING_REGIMES)
      gl$taxonomy <- tk; gl$window <- wk
      gl$reported_centering_regime <- reported
      gl$break_route_status <- route
      gate_rows[[length(gate_rows) + 1L]] <- gl
    }
  }
}

coef_ledger <- do.call(rbind, coef_rows)
gate_ledger <- do.call(rbind, gate_rows)
dols_ledger <- if (length(dols_rows)) do.call(rbind, dols_rows) else
  data.frame(spec = character(), taxonomy = character(), parameter = character())

s33_write_ledger(coef_ledger, CSV_DIR, "specB_break_interacted_imols_coefficients.csv")
s33_write_ledger(gate_ledger, CSV_DIR, "specB_interaction_gate_ledger.csv")
s33_write_ledger(dols_ledger, CSV_DIR, "specB_dols_comparator_ledger.csv")

# ---------------------------------------------------------------------------
# 5. S02 Sec.3 marginal product of the gap, by sub-regime
# ---------------------------------------------------------------------------

rep_coef <- coef_ledger[coef_ledger$is_reported_regime %in% TRUE, , drop = FALSE]

# Computed for B3 and B4. Under B4 there is no theta_kappa intercept term: the marginal
# product of the gap is purely state-dependent, MP_kappa = theta_omega_kappa * omega +
# theta_kappa_pkappa * p_kappa, which is the whole substantive point of the
# specification. The intercept columns are written as NA rather than 0 and
# mp_has_intercept records which regime the row is in, so a reader cannot mistake an
# absent parameter for one estimated at zero.
for (tk in c("B3", "B4")) {
for (wk in names(WINDOWS)) {
  sub <- rep_coef[rep_coef$window == wk & rep_coef$taxonomy == tk &
                    rep_coef$internal_slope_interaction == "Yes", , drop = FALSE]
  if (!nrow(sub)) next
  has_int <- isTRUE(TAXONOMY[[tk]]$use_standalone_kappa)
  gv <- function(p, col = "estimate") { r <- sub[sub$parameter == p, col]; if (length(r)) r[1] else NA_real_ }
  th_k <- if (has_int) gv("theta_kappa") else NA_real_
  th_wk <- gv("theta_omega_kappa"); th_pk <- gv("theta_kappa_pkappa")
  d1 <- gv("delta_1"); d2 <- gv("delta_2"); d3 <- gv("delta_3")
  z <- function(x) ifelse(is.na(x), 0, x)

  mp_rows[[length(mp_rows) + 1L]] <- data.frame(
    spec = "Spec_B", taxonomy = tk, window = wk, era_label = WINDOWS[[wk]]$label,
    tb_star = WINDOWS[[wk]]$tb_star,
    mp_has_intercept = has_int,
    early_intercept = th_k, early_omega_slope = th_wk, early_pkappa_slope = th_pk,
    late_intercept = if (has_int) th_k + z(d1) else NA_real_,
    late_omega_slope = th_wk + z(d2),
    late_pkappa_slope = th_pk + z(d3),
    delta_1 = d1, delta_1_t = gv("delta_1", "fixed_b_har_t"),
    delta_2 = d2, delta_2_t = gv("delta_2", "fixed_b_har_t"),
    delta_3 = d3, delta_3_t = gv("delta_3", "fixed_b_har_t"),
    formula = if (has_int)
      paste("MP_kappa = theta_kappa + theta_omega_kappa*omega +",
            "theta_kappa_pkappa*p_kappa (early);",
            "coefficients shifted by delta_1/delta_2/delta_3 (late)") else
      paste("MP_kappa = theta_omega_kappa*omega + theta_kappa_pkappa*p_kappa;",
            "no standalone intercept term (B4 excludes the kappa level);",
            "slopes shifted by delta_2/delta_3 (late)"),
    break_route_status = sub$break_route_status[1],
    disposition = sub$disposition[1],
    stringsAsFactors = FALSE)
}
}
mp_ledger <- do.call(rbind, mp_rows)
s33_write_ledger(mp_ledger, CSV_DIR, "specB_marginal_product_kappa_regimes.csv")

# ---------------------------------------------------------------------------
# 6. Slope-break decision ledger (S01 Sec.3 rule applied to S02's three deltas)
# ---------------------------------------------------------------------------

dec_rows <- list()
for (wk in names(WINDOWS)) {
  for (tk in names(TAXONOMY)) {
    sub <- rep_coef[rep_coef$window == wk & rep_coef$taxonomy == tk &
                      rep_coef$internal_slope_interaction == "Yes", , drop = FALSE]
    if (!nrow(sub)) next
    noint <- rep_coef[rep_coef$window == wk & rep_coef$taxonomy == tk &
                        rep_coef$internal_slope_interaction == "No", , drop = FALSE]
    gt <- function(p) { r <- sub[sub$parameter == p, "fixed_b_har_t"]; if (length(r)) r[1] else NA_real_ }
    ge <- function(p) { r <- sub[sub$parameter == p, "estimate"]; if (length(r)) r[1] else NA_real_ }
    ts <- c(delta_1 = gt("delta_1"), delta_2 = gt("delta_2"), delta_3 = gt("delta_3"))
    sig <- any(!is.na(ts) & abs(ts) >= 1.96)
    decision <- if (sig) "retain_multiplicative_interaction" else "retain_additive_step_control"

    dec_rows[[length(dec_rows) + 1L]] <- data.frame(
      spec = "Spec_B", taxonomy = tk, window = wk, era_label = WINDOWS[[wk]]$label,
      tb_star = WINDOWS[[wk]]$tb_star,
      delta_1 = ge("delta_1"), delta_1_t = ts[["delta_1"]],
      delta_2 = ge("delta_2"), delta_2_t = ts[["delta_2"]],
      delta_3 = ge("delta_3"), delta_3_t = ts[["delta_3"]],
      significant_deltas = paste(names(ts)[!is.na(ts) & abs(ts) >= 1.96], collapse = ";"),
      s02_decision = decision,
      s02_meaning = if (sig)
        "gap elasticity shifted internally; report dual sub-regime MP_kappa" else
        "gap elasticity structurally invariant; step dummies retained for variance hygiene",
      sigma_u_with_interaction = sub$sigma_u[1],
      sigma_u_without_interaction = if (nrow(noint)) noint$sigma_u[1] else NA_real_,
      C_shin_with_interaction = sub$C_shin[1],
      C_shin_without_interaction = if (nrow(noint)) noint$C_shin[1] else NA_real_,
      C_shin_anchor_uncontrolled = S33_SPEC_B_ANCHORS$C_shin_uncontrolled,
      C_shin_anchor_controlled = S33_SPEC_B_ANCHORS$C_shin_controlled,
      break_route_status = sub$break_route_status[1],
      disposition = sub$disposition[1],
      reported_centering_regime = sub$centering_regime[1],
      stringsAsFactors = FALSE)
  }
}
decision_ledger <- do.call(rbind, dec_rows)
s33_write_ledger(decision_ledger, CSV_DIR, "specB_slope_break_decision_ledger.csv")

# ---------------------------------------------------------------------------
# 7. Table 3.2 matrix (S02 Sec.5 layout, B3, plus the added delta_3 row)
# ---------------------------------------------------------------------------

fmt <- function(v, t) if (is.na(v)) "--" else sprintf("%.2f%s", v, s33_stars(t))
fmt_t <- function(t) if (is.na(t)) "" else sprintf("(%.2f)", t)

col_for <- function(wk, interacted, tk = "B3") {
  s <- rep_coef[rep_coef$window == wk & rep_coef$taxonomy == tk &
                  rep_coef$internal_slope_interaction == (if (interacted) "Yes" else "No"), ,
                drop = FALSE]
  if (!nrow(s)) return(NULL)
  gv <- function(p, col) { r <- s[s$parameter == p, col]; if (length(r)) r[1] else NA }
  pair <- function(p) if (!interacted) c("--", "") else
    c(fmt(gv(p, "estimate"), gv(p, "fixed_b_har_t")), fmt_t(gv(p, "fixed_b_har_t")))
  d1 <- pair("delta_1"); d2 <- pair("delta_2"); d3 <- pair("delta_3")
  c(theta_NRC = fmt(gv("theta_NRC", "estimate"), gv("theta_NRC", "fixed_b_har_t")),
    theta_NRC_t = fmt_t(gv("theta_NRC", "fixed_b_har_t")),
    theta_kappa = fmt(gv("theta_kappa", "estimate"), gv("theta_kappa", "fixed_b_har_t")),
    theta_kappa_t = fmt_t(gv("theta_kappa", "fixed_b_har_t")),
    delta_1 = d1[1], delta_1_t = d1[2],
    theta_omega_kappa = fmt(gv("theta_omega_kappa", "estimate"),
                            gv("theta_omega_kappa", "fixed_b_har_t")),
    theta_omega_kappa_t = fmt_t(gv("theta_omega_kappa", "fixed_b_har_t")),
    delta_2 = d2[1], delta_2_t = d2[2],
    theta_kappa_pkappa = fmt(gv("theta_kappa_pkappa", "estimate"),
                             gv("theta_kappa_pkappa", "fixed_b_har_t")),
    theta_kappa_pkappa_t = fmt_t(gv("theta_kappa_pkappa", "fixed_b_har_t")),
    delta_3 = d3[1], delta_3_t = d3[2],
    step_dummies = "Yes",
    sigma_u = sprintf("%.3f", s$sigma_u[1]),
    C_shin = sprintf("%.3f%s", s$C_shin[1], s$C_shin_stars[1]),
    residual_adf = sprintf("%.3f%s", s$residual_adf[1], s$residual_adf_stars[1]),
    T_obs = as.character(s$T_obs[1]),
    break_route = s$break_route_status[1],
    centering = s$centering_regime[1])
}

ROW_LABELS <- c(
  theta_NRC = "Structures Scale (theta_NRC)", theta_NRC_t = "",
  theta_kappa = "Mechanization Gap (theta_kappa)", theta_kappa_t = "",
  delta_1 = "Gap Slope Shift (delta_1)", delta_1_t = "",
  theta_omega_kappa = "Wage Squeeze (theta_omega_kappa)", theta_omega_kappa_t = "",
  delta_2 = "Wage Interaction Shift (delta_2)", delta_2_t = "",
  theta_kappa_pkappa = "Price Penalty (theta_kappa_pkappa)", theta_kappa_pkappa_t = "",
  delta_3 = "Price Interaction Shift (delta_3)", delta_3_t = "",
  step_dummies = "Step & Slope Dummies",
  sigma_u = "Residual Variance (sigma_u)",
  C_shin = "Shin LM Test (C_Shin)",
  residual_adf = "Residual ADF (ADF)",
  T_obs = "Sample Size (T)",
  break_route = "Break-Aware Gate Status",
  centering = "Reported Centering Regime")

# Provenance for the row S02 Sec.5 omits.
ROW_PROVENANCE <- setNames(rep("S02 Sec.5 Table 3.2 template", length(ROW_LABELS)),
                           names(ROW_LABELS))
ROW_PROVENANCE[c("delta_3", "delta_3_t")] <-
  "ADDED: delta_3 is defined in S02 Sec.3 but absent from the Sec.5 template"
ROW_PROVENANCE[c("break_route", "centering")] <-
  "ADDED: break-aware route status and centering regime (P05 honesty requirement)"

cols <- list(
  `(1)` = col_for("Fordist_1929_1973", FALSE),
  `(2)` = col_for("Fordist_1929_1973", TRUE),
  `(3)` = col_for("Post_Fordist_1974_2024", FALSE),
  `(4)` = col_for("Post_Fordist_1974_2024", TRUE))

table_32 <- data.frame(row = names(ROW_LABELS), label = unname(ROW_LABELS),
                       stringsAsFactors = FALSE)
for (cn in names(cols)) {
  table_32[[cn]] <- if (is.null(cols[[cn]])) NA_character_ else
    unname(cols[[cn]][names(ROW_LABELS)])
}
table_32$provenance <- unname(ROW_PROVENANCE[table_32$row])

header <- data.frame(
  row = c("era", "interaction", "tb_star"),
  label = c("Era", "Internal Slope Interaction", "Internal Break Date (T_B*)"),
  `(1)` = c("Fordist 1929-1973", "No", "1947"),
  `(2)` = c("Fordist 1929-1973", "Yes", "1947"),
  `(3)` = c("Post-Fordist 1974-2024", "No", "2008"),
  `(4)` = c("Post-Fordist 1974-2024", "Yes", "2008"),
  provenance = "S02 Sec.5 Table 3.2 template",
  check.names = FALSE, stringsAsFactors = FALSE)
table_32 <- rbind(header, table_32)

s33_write_ledger(table_32, CSV_DIR, "specB_table_3_2_matrix.csv")

# ---------------------------------------------------------------------------
# 7.2. Table 3.3 matrix -- same layout under Spec B4
# ---------------------------------------------------------------------------
# Identical row structure to Table 3.2 so the two read side by side. The gap-level rows
# come back "--" by construction, which is the specification being visible in the table
# rather than a missing estimate.

cols_b4 <- list(
  `(1)` = col_for("Fordist_1929_1973", FALSE, "B4"),
  `(2)` = col_for("Fordist_1929_1973", TRUE,  "B4"),
  `(3)` = col_for("Post_Fordist_1974_2024", FALSE, "B4"),
  `(4)` = col_for("Post_Fordist_1974_2024", TRUE,  "B4"))

table_33 <- data.frame(row = names(ROW_LABELS), label = unname(ROW_LABELS),
                       stringsAsFactors = FALSE)
for (cn in names(cols_b4)) {
  table_33[[cn]] <- if (is.null(cols_b4[[cn]])) NA_character_ else
    unname(cols_b4[[cn]][names(ROW_LABELS)])
}
b4_prov <- ROW_PROVENANCE
b4_prov[c("theta_kappa", "theta_kappa_t", "delta_1", "delta_1_t")] <-
  "EXCLUDED BY CONSTRUCTION: Spec B4 drops the standalone kappa level and its break"
table_33$provenance <- unname(b4_prov[table_33$row])

header_b4 <- header
header_b4$provenance <- "Spec B4 (standalone_kappa_exclusion_assessment.md), Table 3.2 layout"
table_33 <- rbind(header_b4, table_33)

s33_write_ledger(table_33, CSV_DIR, "specB_table_3_3_B4_matrix.csv")

# ---------------------------------------------------------------------------
# 7.3. B3 vs B4 collinearity comparison
# ---------------------------------------------------------------------------
# The diagnostic table the standalone-kappa assessment was reaching for, computed rather
# than asserted. Two things it carries that the assessment did not:
#
#   1. The pairwise correlation between the standalone kappa level and each of its own
#      interaction columns, per window and centering regime. The assessment claims this
#      exceeds 0.92; nothing in the pipeline had ever computed it.
#   2. Both the reported regime and every centering regime, so the conditioning claim
#      can be checked rather than taken on the reported row alone.

kappa_collinearity <- function(wk, regime) {
  win <- S33_WINDOWS[[wk]]
  d <- s33_window(panel, win)
  need <- c("y", "k_NRC", "kappa", "p_kappa", "omega_lag1")
  d <- d[stats::complete.cases(d[, need]), , drop = FALSE]
  kp <- s33_center(d$kappa, regime)
  pk <- s33_center(d$p_kappa, regime)
  w  <- s33_center(d$omega_lag1, regime)
  c(corr_kappa_vs_kappa_omega  = suppressWarnings(stats::cor(kp, kp * w)),
    corr_kappa_vs_kappa_pkappa = suppressWarnings(stats::cor(kp, kp * pk)))
}

cmp_rows <- list()
for (wk in names(WINDOWS)) {
  for (rg in S33_CENTERING_REGIMES) {
    cc <- kappa_collinearity(wk, rg)
    for (interacted in c(FALSE, TRUE)) {
      lab <- if (interacted) "Yes" else "No"
      get_one <- function(tk) {
        coef_ledger[coef_ledger$taxonomy == tk & coef_ledger$window == wk &
                      coef_ledger$centering_regime == rg &
                      coef_ledger$internal_slope_interaction == lab, , drop = FALSE]
      }
      b3 <- get_one("B3"); b4 <- get_one("B4")
      if (!nrow(b3) || !nrow(b4)) next
      pick <- function(df, p, col) {
        r <- df[df$parameter == p, col]; if (length(r)) r[1] else NA_real_
      }
      cmp_rows[[length(cmp_rows) + 1L]] <- data.frame(
        spec = "Spec_B", window = wk, era_label = WINDOWS[[wk]]$label,
        centering_regime = rg,
        is_reported_regime = b3$is_reported_regime[1],
        internal_slope_interaction = lab,
        T_obs = b3$T_obs[1],
        corr_kappa_vs_kappa_omega  = unname(cc[["corr_kappa_vs_kappa_omega"]]),
        corr_kappa_vs_kappa_pkappa = unname(cc[["corr_kappa_vs_kappa_pkappa"]]),
        B3_condition_number = b3$std_condition_number[1],
        B4_condition_number = b4$std_condition_number[1],
        condition_number_reduction = b3$std_condition_number[1] - b4$std_condition_number[1],
        B3_clears_cn_threshold = b3$std_condition_number[1] <= CN_THRESHOLD,
        B4_clears_cn_threshold = b4$std_condition_number[1] <= CN_THRESHOLD,
        cn_threshold = CN_THRESHOLD,
        B3_sigma_u = b3$sigma_u[1], B4_sigma_u = b4$sigma_u[1],
        B3_C_shin = b3$C_shin[1],   B4_C_shin = b4$C_shin[1],
        B3_residual_adf = b3$residual_adf[1], B4_residual_adf = b4$residual_adf[1],
        B3_theta_NRC = pick(b3, "theta_NRC", "estimate"),
        B3_theta_NRC_t = pick(b3, "theta_NRC", "fixed_b_har_t"),
        B4_theta_NRC = pick(b4, "theta_NRC", "estimate"),
        B4_theta_NRC_t = pick(b4, "theta_NRC", "fixed_b_har_t"),
        B3_theta_kappa = pick(b3, "theta_kappa", "estimate"),
        B3_theta_kappa_t = pick(b3, "theta_kappa", "fixed_b_har_t"),
        B4_theta_kappa = NA_real_, B4_theta_kappa_t = NA_real_,
        B3_theta_omega_kappa = pick(b3, "theta_omega_kappa", "estimate"),
        B3_theta_omega_kappa_t = pick(b3, "theta_omega_kappa", "fixed_b_har_t"),
        B4_theta_omega_kappa = pick(b4, "theta_omega_kappa", "estimate"),
        B4_theta_omega_kappa_t = pick(b4, "theta_omega_kappa", "fixed_b_har_t"),
        B3_theta_kappa_pkappa = pick(b3, "theta_kappa_pkappa", "estimate"),
        B3_theta_kappa_pkappa_t = pick(b3, "theta_kappa_pkappa", "fixed_b_har_t"),
        B4_theta_kappa_pkappa = pick(b4, "theta_kappa_pkappa", "estimate"),
        B4_theta_kappa_pkappa_t = pick(b4, "theta_kappa_pkappa", "fixed_b_har_t"),
        break_route_status = b3$break_route_status[1],
        note = paste("B4 excludes the standalone kappa level; B4_theta_kappa is NA by",
                     "construction, not a failed estimate"),
        stringsAsFactors = FALSE)
    }
  }
}
comparison_ledger <- do.call(rbind, cmp_rows)
s33_write_ledger(comparison_ledger, CSV_DIR, "specB_B3_vs_B4_collinearity_comparison.csv")

rep_cmp <- comparison_ledger[comparison_ledger$is_reported_regime %in% TRUE, , drop = FALSE]
for (i in seq_len(nrow(rep_cmp))) {
  r <- rep_cmp[i, ]
  log_msg(sprintf("  B3->B4 %-23s int=%-3s CN %8.2f -> %8.2f (%s)  corr(kappa, kappa*omega)=%.4f",
                  r$window, r$internal_slope_interaction,
                  r$B3_condition_number, r$B4_condition_number,
                  if (r$B4_clears_cn_threshold) "clears CN<=30" else "still above CN=30",
                  r$corr_kappa_vs_kappa_omega))
}

# ---------------------------------------------------------------------------
# 7.5. Structural Break Shift Combinatorics Grid (Spec B)
# ---------------------------------------------------------------------------
log_msg("Starting Specification B Combinatorics Grid (16 models per window x 3 regimes)...")

fit_model_comb_specB <- function(win_spec, regime, has_kn_x_D, has_kappa_x_D, has_kappa_omega_x_D, has_kappa_pkappa_x_D) {
  win <- S33_WINDOWS[[win_spec$key]]
  d <- s33_window(panel, win)
  need <- c("y", "k_NRC", "kappa", "p_kappa", "omega_lag1")
  d <- d[stats::complete.cases(d[, need]), , drop = FALSE]
  yr <- d$year; y <- d$y

  kn <- s33_center(d$k_NRC, regime)
  kp <- s33_center(d$kappa, regime)
  pk <- s33_center(d$p_kappa, regime)
  w  <- s33_center(d$omega_lag1, regime)

  X <- cbind(k_NRC = kn, kappa = kp, p_kappa = pk, omega = w)
  base_cols <- c("k_NRC", "kappa", "p_kappa", "omega")
  inter_cols <- character(0)

  # Spec B3 is the canonical base fully interacted model:
  X <- cbind(X, kappa_x_omega = kp * w)
  inter_cols <- c(inter_cols, "kappa_x_omega")
  
  X <- cbind(X, kappa_x_pkappa = kp * pk)
  inter_cols <- c(inter_cols, "kappa_x_pkappa")

  stepm <- build_steps(yr, win_spec)
  if (!is.null(stepm)) X <- cbind(X, stepm)

  # Always include step dummy level control D_TB
  D <- s33_step(yr, win_spec$tb_star)
  if (stats::sd(D) == 0) return(NULL)
  X <- cbind(X, D_TB = D)

  if (has_kn_x_D) {
    X <- cbind(X, kn_x_D = kn * D)
    inter_cols <- c(inter_cols, "kn_x_D")
  }
  if (has_kappa_x_D) {
    X <- cbind(X, kappa_x_D = kp * D)
    inter_cols <- c(inter_cols, "kappa_x_D")
  }
  if (has_kappa_omega_x_D) {
    X <- cbind(X, kappa_omega_x_D = kp * w * D)
    inter_cols <- c(inter_cols, "kappa_omega_x_D")
  }
  if (has_kappa_pkappa_x_D) {
    X <- cbind(X, kappa_pkappa_x_D = kp * pk * D)
    inter_cols <- c(inter_cols, "kappa_pkappa_x_D")
  }

  if (length(inter_cols)) s33_assert_no_fwl(X, inter_cols, base_cols)

  deter <- matrix(1, nrow = length(y), ncol = 1)
  fit <- tryCatch(s33_imols(X, y, deter = deter), error = function(e) e)
  if (inherits(fit, "error")) return(list(error = conditionMessage(fit)))

  list(fit = fit, X = X, y = y, year = yr, T_obs = length(y),
       cond = std_condition(cbind(1, X)), error = NA_character_)
}

comb_grid_B <- expand.grid(
  has_kn_x_D = c(FALSE, TRUE),
  has_kappa_x_D = c(FALSE, TRUE),
  has_kappa_omega_x_D = c(FALSE, TRUE),
  has_kappa_pkappa_x_D = c(FALSE, TRUE)
)
# Sort to ensure Perm 0 is first, then ordered
comb_grid_B$perm_id <- paste0("SpecB-", 0:15)

comb_rows_B <- list()
for (wk in names(WINDOWS)) {
  wsp <- WINDOWS[[wk]]
  for (rg in S33_CENTERING_REGIMES) {
    # First fit Perm 0 to get baseline sigma_u for variance reduction calculation
    m0 <- fit_model_comb_specB(wsp, rg, FALSE, FALSE, FALSE, FALSE)
    sigma_u_0 <- if (!is.null(m0) && is.na(m0$error)) m0$fit$diag$sigma_u else NA_real_
    C_shin_0 <- if (!is.null(m0) && is.na(m0$error)) m0$fit$diag$C_shin else NA_real_
    
    for (i in 1:nrow(comb_grid_B)) {
      row <- comb_grid_B[i, ]
      m <- fit_model_comb_specB(wsp, rg, row$has_kn_x_D, row$has_kappa_x_D, row$has_kappa_omega_x_D, row$has_kappa_pkappa_x_D)
      if (is.null(m) || !is.na(m$error)) next
      
      f <- m$fit
      dg <- f$diag
      
      gv_est <- function(p) { r <- s33_coef(f, p); if (is.na(r)) NA_real_ else r }
      gv_t <- function(p) { r <- s33_tstat(f, p); if (is.na(r)) NA_real_ else r }
      
      # Joint Wald test for primary hypothesis: H0: theta_omega_kappa = 0 AND theta_omega_kappa_brk = 0
      # Which corresponds to kappa_x_omega and kappa_omega_x_D
      names_to_test <- c("kappa_x_omega")
      if (row$has_kappa_omega_x_D) names_to_test <- c("kappa_x_omega", "kappa_omega_x_D")
      jw <- s33_joint_wald(f, names_to_test)
      
      # Variance reduction relative to Perm 0
      var_red <- if (!is.na(sigma_u_0) && sigma_u_0 > 0) (sigma_u_0 - dg$sigma_u) / sigma_u_0 * 100 else 0
      
      # Adjudication
      coint_pass <- !is.na(dg$C_shin) && dg$C_shin < 0.095
      collin_pass <- !is.na(m$cond) && m$cond <= 100
      
      # Check significance of included break parameters
      break_sigs <- logical(0)
      if (row$has_kn_x_D) break_sigs <- c(break_sigs, abs(gv_t("kn_x_D")) >= 1.96)
      if (row$has_kappa_x_D) break_sigs <- c(break_sigs, abs(gv_t("kappa_x_D")) >= 1.96)
      if (row$has_kappa_omega_x_D) break_sigs <- c(break_sigs, abs(gv_t("kappa_omega_x_D")) >= 1.96)
      if (row$has_kappa_pkappa_x_D) break_sigs <- c(break_sigs, abs(gv_t("kappa_pkappa_x_D")) >= 1.96)
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
      
      comb_rows_B[[length(comb_rows_B) + 1L]] <- data.frame(
        permutation_id = row$perm_id,
        window = wk,
        centering_regime = rg,
        has_D_TB = TRUE,
        has_kn_x_D = row$has_kn_x_D,
        has_kappa_x_D = row$has_kappa_x_D,
        has_kappa_omega_x_D = row$has_kappa_omega_x_D,
        has_kappa_pkappa_x_D = row$has_kappa_pkappa_x_D,
        CN = m$cond,
        sigma_u = dg$sigma_u,
        r2_level = dg$r2_level,
        C_shin = dg$C_shin,
        C_shin_stars = dg$shin_stars,
        t_adf = dg$t_adf,
        adf_stars = dg$adf_stars,
        theta_NRC_est = gv_est("k_NRC"),
        theta_NRC_t = gv_t("k_NRC"),
        theta_NRC_brk_est = if (row$has_kn_x_D) gv_est("kn_x_D") else NA_real_,
        theta_NRC_brk_t = if (row$has_kn_x_D) gv_t("kn_x_D") else NA_real_,
        theta_kappa_est = gv_est("kappa"),
        theta_kappa_t = gv_t("kappa"),
        theta_kappa_brk_est = if (row$has_kappa_x_D) gv_est("kappa_x_D") else NA_real_,
        theta_kappa_brk_t = if (row$has_kappa_x_D) gv_t("kappa_x_D") else NA_real_,
        theta_omega_kappa_est = gv_est("kappa_x_omega"),
        theta_omega_kappa_t = gv_t("kappa_x_omega"),
        theta_omega_kappa_brk_est = if (row$has_kappa_omega_x_D) gv_est("kappa_omega_x_D") else NA_real_,
        theta_omega_kappa_brk_t = if (row$has_kappa_omega_x_D) gv_t("kappa_omega_x_D") else NA_real_,
        theta_kappa_pkappa_est = gv_est("kappa_x_pkappa"),
        theta_kappa_pkappa_t = gv_t("kappa_x_pkappa"),
        theta_kappa_pkappa_brk_est = if (row$has_kappa_pkappa_x_D) gv_est("kappa_pkappa_x_D") else NA_real_,
        theta_kappa_pkappa_brk_t = if (row$has_kappa_pkappa_x_D) gv_t("kappa_pkappa_x_D") else NA_real_,
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
comb_ledger_B <- do.call(rbind, comb_rows_B)
COMB_DIR <- file.path(S33_OUT_ROOT, "combinatorics")
s33_ensure_dir(COMB_DIR)
s33_write_ledger(comb_ledger_B, COMB_DIR, "specB_break_combinatorics_summary.csv")

# ---------------------------------------------------------------------------
# 8. Stage integrity
# ---------------------------------------------------------------------------

integrity <- s33_integrity(
  checks = c(
    "step2_gate_consumed",
    "estimator_is_imols_not_dols",
    "nested_taxonomy_B1_B2_B3_all_estimated",
    "interaction_span_complete",
    "b4_estimated_and_excludes_standalone_kappa",
    "b4_condition_number_recorded_against_b3",
    "delta_3_estimated_and_table_gap_resolved",
    "interaction_gate_recorded_for_every_model",
    "condition_number_logged_and_regime_chosen",
    "protocol_tb_star_used_for_slope_shift",
    "all_four_table_32_columns_populated",
    "break_route_status_travels_with_every_coefficient",
    "s02_decision_recorded_per_taxonomy",
    "spec_b_anchors_carried",
    "marginal_product_regimes_computed",
    "dols_marked_diagnostic_comparator_only",
    "outputs_confined_to_break_aware_tree"
  ),
  passed = c(
    file.exists(VERDICT_PATH) && nrow(verdicts) > 0,
    all(grepl("^IM-OLS", coef_ledger$estimator)),
    all(c("B1", "B2", "B3") %in% unique(coef_ledger$taxonomy)),
    # Span correction: every product column has its constituents. Checked structurally by
    # s33_assert_complete_span() before any fit, and re-asserted here on the ledger.
    {
      ic <- coef_ledger$design_column[coef_ledger$internal_slope_interaction == "Yes"]
      ok <- TRUE
      if ("kappa_omega_x_D" %in% ic) ok <- ok && all(c("kappa_x_D", "omega_x_D") %in% ic)
      if ("kappa_p_kappa_x_D" %in% ic) ok <- ok && all(c("kappa_x_D", "p_kappa_x_D") %in% ic)
      ok
    },
    # B4 excludes the standalone kappa LEVEL. It still carries kappa_x_D, which is a span
    # constituent required because kappa appears inside a product -- not a main effect.
    "B4" %in% unique(coef_ledger$taxonomy) &&
      !any(coef_ledger$taxonomy == "B4" & coef_ledger$design_column == "kappa"),
    nrow(comparison_ledger) > 0 &&
      all(is.finite(comparison_ledger$B3_condition_number)) &&
      all(is.finite(comparison_ledger$B4_condition_number)),
    any(coef_ledger$parameter == "delta_3") &&
      any(grepl("^ADDED", table_32$provenance)),
    nrow(gate_ledger) == 4L * length(TAXONOMY) * 2L * length(WINDOWS),
    all(is.finite(coef_ledger$std_condition_number)) &&
      all(nzchar(coef_ledger$centering_note)),
    all(coef_ledger$tb_star[coef_ledger$window == "Fordist_1929_1973"] == 1947L) &&
      all(coef_ledger$tb_star[coef_ledger$window == "Post_Fordist_1974_2024"] == 2008L),
    all(!vapply(cols, is.null, logical(1))),
    all(coef_ledger$break_route_status %in%
          c("formal_break_supported", "exploratory_break_route")),
    nrow(decision_ledger) == length(WINDOWS) * length(TAXONOMY),
    all(coef_ledger$C_shin_anchor_uncontrolled == S33_SPEC_B_ANCHORS$C_shin_uncontrolled),
    nrow(mp_ledger) == 2L * length(WINDOWS),
    nrow(dols_ledger) == 0L || all(dols_ledger$role == "diagnostic_comparator"),
    grepl("BREAK_AWARE_IMOLS", normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE),
          fixed = TRUE)
  ),
  detail = c(
    paste0("read ", VERDICT_PATH),
    "cointReg::cointRegIM via s33_imols(); E10V active estimator lock",
    paste("taxonomy estimated:", paste(sort(unique(coef_ledger$taxonomy)), collapse = ", ")),
    paste("span correction 2026-07-31: omega.D and p_kappa.D added, and kappa.D retained",
          "under B4; previously absent, which left the Fordist interacted",
          "theta_omega_kappa spanning [-23.61, 47.79] across centering regimes"),
    paste0("B4 rows: ", sum(coef_ledger$taxonomy == "B4"),
           "; standalone kappa level and its break absent from every B4 design"),
    {
      rc <- comparison_ledger[comparison_ledger$is_reported_regime %in% TRUE, , drop = FALSE]
      paste0("B3 vs B4 CN (reported regime): ",
             paste(sprintf("%s/int=%s %.1f->%.1f", rc$window,
                           rc$internal_slope_interaction,
                           rc$B3_condition_number, rc$B4_condition_number),
                   collapse = "; "))
    },
    "delta_3 estimated per S02 Sec.3 and added to the Sec.5 table with provenance recorded",
    paste0(nrow(gate_ledger), " gate rows (4 items x ", length(TAXONOMY),
           " taxonomy x 2 interaction x 2 windows)"),
    paste0("standardized CN threshold ", CN_THRESHOLD, "; reported regimes: ",
           paste(unique(rep_coef$centering_regime), collapse = ", ")),
    "Fordism T_B*=1947, Post-Fordism T_B*=2008 (S02 Sec.6 Step 1)",
    "Table 3.2 columns (1)-(4) all populated from the B3 canonical specification",
    paste0(sum(rep_coef$break_route_status == "formal_break_supported"), " formal, ",
           sum(rep_coef$break_route_status == "exploratory_break_route"),
           " exploratory coefficient rows"),
    paste(decision_ledger$window, decision_ledger$taxonomy,
          decision_ledger$s02_decision, collapse = "; "),
    sprintf("C_Shin anchors %.3f -> %.3f; sigma_u anchors %.3f -> %.3f",
            S33_SPEC_B_ANCHORS$C_shin_uncontrolled, S33_SPEC_B_ANCHORS$C_shin_controlled,
            S33_SPEC_B_ANCHORS$sigma_u_uncontrolled, S33_SPEC_B_ANCHORS$sigma_u_controlled),
    paste0(nrow(mp_ledger), " MP_kappa sub-regime rows (S02 Sec.3)"),
    paste0(nrow(dols_ledger), " DOLS comparator rows, none promoted"),
    normalizePath(CSV_DIR, winslash = "/", mustWork = FALSE)
  )
)

s33_write_ledger(integrity, CSV_DIR, "s33d_specB_integrity.csv")
s33_halt_on_integrity(integrity, "US_S33D")

log_msg("US_S33D complete. ", nrow(coef_ledger), " coefficient rows; B3 decisions: ",
        paste(decision_ledger$window[decision_ledger$taxonomy == "B3"],
              decision_ledger$s02_decision[decision_ledger$taxonomy == "B3"],
              collapse = "; "))
log_msg("All four S0* stages complete. Ledgers under ", s33_dir())
