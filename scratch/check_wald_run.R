# scratch/check_wald_run.R
source("codes/US_S33_break_aware_common.R")
panel <- s33_load_spec_a()

WINDOWS <- list(
  Fordist_1929_1973 = list(
    key = "Fordist_1929_1973", label = "Fordist Era (1929-1973)",
    tb_star = 1947L, tb_source = "S01 Sec.5 Step 1 (T_1947 inside Fordism)",
    steps = list(
      list(name = "D_1933", type = "step", args = list(1933L),
           rationale = "New Deal regime change; permanent level shift"),
      list(name = "B_1942_1945", type = "block", args = list(1942L, 1945L),
           rationale = "WWII mobilisation; reverses on demobilisation")
    )),
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

std_condition <- function(X) {
  X <- as.matrix(X)
  s <- apply(X, 2, function(c) sqrt(sum(c^2)))
  s[s == 0 | !is.finite(s)] <- 1
  suppressWarnings(kappa(sweep(X, 2, s, "/"), exact = TRUE))
}

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

s33_joint_wald_robust <- function(fit, names_to_test) {
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
  vcov <- fit$varmat[idxs, idxs, drop = FALSE]
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

m <- fit_model_comb(WINDOWS$Fordist_1929_1973, "Regime_B_Initial_Centered", TRUE, TRUE, TRUE)
f <- m$fit
print(names(f$theta.all))
jw <- s33_joint_wald_robust(f, c("interaction", "inter_x_D"))
print(jw)
