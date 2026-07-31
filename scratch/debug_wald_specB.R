# scratch/debug_wald_specB.R
source("codes/US_S33_break_aware_common.R")
panel <- s33_load_spec_b()

WINDOWS <- list(
  Post_Fordist_1974_2024 = list(
    key = "Post_Fordist_1974_2024", label = "Post-Fordist Era (1974-2024)",
    tb_star = 2008L, tb_source = "S01 Sec.5 Step 1 (T_2008 inside Post-Fordism)",
    steps = list(
      list(name = "D_1981", type = "step", args = list(1981L),
           rationale = "Volcker disinflation; Bai-Perron supported"),
      list(name = "D_2000", type = "step", args = list(2000L),
           rationale = "Dot-Com crash; Bai-Perron supported")
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

  D <- s33_step(yr, win_spec$tb_star)
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

  list(fit = fit, X = X, y = y, year = yr, T_obs = length(y), error = NA_character_)
}

m <- fit_model_comb_specB(WINDOWS$Post_Fordist_1974_2024, "Regime_B_Initial_Centered", FALSE, TRUE, TRUE, FALSE)
f <- m$fit

cat("omega.u.v =", f$omega.u.v, "\n")
cat("T =", length(f$u.plus), "\n")
cat("ratio =", f$sd.theta[1]^2 / diag(f$varmat)[1], "\n")
cat("ratio * f$omega.u.v =", (f$sd.theta[1]^2 / diag(f$varmat)[1]) * f$omega.u.v, "\n")
cat("ratio * (T^2) =", (f$sd.theta[1]^2 / diag(f$varmat)[1]) * (length(f$u.plus)^2), "\n")
