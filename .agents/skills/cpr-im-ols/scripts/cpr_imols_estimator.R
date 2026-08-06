# -------------------------------------------------------------------------
# Reusable Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS
# Custom Implementation adapted for Vogelsang et al. (2024) Framework
# -------------------------------------------------------------------------

cointRegIM_CMPR <- function(x, y, deter, x_base, selector = c(1, 2), kernel = "ba", bandwidth = "nw") {
  y <- as.matrix(y)
  x <- as.matrix(x)
  x_base <- as.matrix(x_base)
  if (missing(deter) || is.null(deter)) deter <- matrix(nrow = nrow(x), ncol = 0)
  
  y.T <- nrow(y)
  x.k <- ncol(x)
  d.k <- ncol(deter)
  xb.k <- ncol(x_base)
  
  # Step 1: Compute Partial Sums
  Sy <- matrixStats::colCumsums(y)
  Sx <- matrixStats::colCumsums(x)
  Sd <- if (d.k == 0) deter else matrixStats::colCumsums(deter)
  
  X <- data.frame(Sd, Sx, x_base)
  Xmat <- as.matrix(X)
  
  # Step 2: Main IM-OLS Estimation (Type 1)
  if (1 %in% selector) {
    im.mod1 <- lm(Sy ~ . - 1, data = X)
    theta1 <- im.mod1$coeff
    theta <- theta1[1:(d.k + x.k)] 
    u1 <- im.mod1$resid
  } else { u1 <- NULL; theta <- NULL }
  
  # Step 3: Type 2 Estimation (Includes Reverse Cumulative Sums for CT_IM Test)
  if (2 %in% selector) {
    # FIX: Detrend x by deter AND Sd (piecewise linear trends) to remove drifts
    trend_mat_step3 <- if (d.k == 0) cbind(1, 1:y.T) else cbind(deter, Sd)
    x_det <- lm.fit(as.matrix(trend_mat_step3), as.matrix(x))$residuals
    Sx_det <- matrixStats::colCumsums(x_det)
    Sxrow <- nrow(Sx_det)
    InvBase <- Sx_det[Sxrow:1, , drop = FALSE]
    InvBaseCum <- matrixStats::colCumsums(InvBase)
    RevBase <- InvBaseCum[Sxrow:1, , drop = FALSE]
    Zreg <- matrixStats::colCumsums(RevBase)
    X2 <- data.frame(X, Zreg)
    im.mod2 <- lm(Sy ~ . - 1, data = X2)
    theta2 <- im.mod2$coeff
    u2 <- im.mod2$resid
    lambda2 <- theta2[(d.k + x.k + xb.k + 1):(d.k + 2*x.k + xb.k)]
  } else { u2 <- NULL; lambda2 <- NULL }
  
  # Step 4: Long-Run Variance (LRV) and HAC Correction
  S <- matrixStats::colCumsums(Xmat)
  DS <- rbind(S[y.T, ], t(S[y.T, ] - t(S[1:(y.T - 1), ])))
  Ha <- cointReg:::trySolve(t(Xmat) %*% Xmat)
  H <- Ha %*% t(DS)
  V <- H %*% t(H)
  
  X_lvl <- if (d.k == 0) as.matrix(x) else cbind(deter, x)
  fit_lvl <- lm.fit(X_lvl, as.numeric(y))
  u_hat <- fit_lvl$residuals
  dx_base <- rbind(rep(0, xb.k), apply(x_base, 2, diff))
  eta_t <- cbind(u_hat, dx_base)
  
  lrv_res <- cointReg::getLongRunVar(eta_t, kernel = kernel, bandwidth = bandwidth)
  omega2_eta <- lrv_res$Omega
  
  if (is.null(omega2_eta)) {
    omega.u.v <- NA
    sd.theta <- rep(NA, d.k + x.k)
  } else {
    Omega11 <- omega2_eta[1, 1]
    Omega22 <- omega2_eta[2:(xb.k+1), 2:(xb.k+1), drop = FALSE]
    Omega12 <- omega2_eta[1, 2:(xb.k+1), drop = FALSE]
    Omega21 <- omega2_eta[2:(xb.k+1), 1, drop = FALSE]
    
    O22inv <- cointReg:::trySolve(Omega22)
    omega.u.v <- if (is.null(O22inv)) as.numeric(Omega11) else as.numeric(Omega11 - Omega12 %*% O22inv %*% Omega21)
    
    sd.theta1 <- sqrt(omega.u.v * diag(V))
    sd.theta <- sd.theta1[1:(d.k + x.k)]
  }
  
  bw_val <- cointReg::getBandwidth(eta_t, kernel = "ba")
  return(list(
    theta = theta, sd.theta = sd.theta, u.plus = u1, u.plus2 = u2,
    residuals = fit_lvl$residuals, omega.u.v = omega.u.v, lambda2 = lambda2, bandwidth = list(number = bw_val)
  ))
}

# -------------------------------------------------------------------------
# Test Statistic Generator for VW Type 2 (CT_IM) Test
# -------------------------------------------------------------------------

calc_vw_type2_stat <- function(x, y, deter, fit, x_base) {
  tryCatch({
    y.T <- nrow(x); x.k <- ncol(x)
    d.k <- if (is.null(deter)) 0 else ncol(deter)
    
    Sy <- cumsum(y)
    Sx <- matrixStats::colCumsums(x)
    Sd <- if (d.k == 0) matrix(nrow = y.T, ncol = 0) else matrixStats::colCumsums(deter)
    
    # FIX: Detrend x by deter AND Sd to remove deterministic drifts before cumsum
    trend_mat_vw <- if (d.k == 0) cbind(1, 1:y.T) else cbind(deter, Sd)
    x_det <- lm.fit(as.matrix(trend_mat_vw), as.matrix(x))$residuals
    Sx_det <- matrixStats::colCumsums(x_det)
    
    InvBase <- Sx_det[y.T:1, , drop = FALSE]
    InvBaseCum <- matrixStats::colCumsums(InvBase)
    RevBase <- InvBaseCum[y.T:1, , drop = FALSE]
    Zreg <- matrixStats::colCumsums(RevBase)
    
    X2mat <- if (d.k == 0) as.matrix(cbind(Sx, x_base, Zreg)) else as.matrix(cbind(Sd, Sx, x_base, Zreg))
    
    S <- matrixStats::colCumsums(X2mat)
    DS <- rbind(S[y.T, ], t(S[y.T, ] - t(S[1:(y.T - 1), ])))
    Ha <- cointReg:::trySolve(t(X2mat) %*% X2mat)
    H <- Ha %*% t(DS)
    V2 <- H %*% t(H)
    
    xb.k <- ncol(x_base)
    lambda2 <- fit$lambda2
    if (is.null(lambda2) || length(lambda2) == 0) return(list(stat = NA, b_hat = NA, k_reg = x.k))

    idx <- (d.k + x.k + xb.k + 1):(d.k + 2 * x.k + xb.k)
    V2_lambda <- V2[idx, idx, drop = FALSE]
    w2 <- fit$omega.u.v
    if (is.null(w2) || is.na(w2) || w2 <= 0) return(list(stat = NA, b_hat = NA, k_reg = x.k))
    
    V2_inv <- cointReg:::trySolve(V2_lambda)
    S_type2 <- as.numeric(t(lambda2) %*% V2_inv %*% lambda2 / w2)
    b_hat <- fit$bandwidth$number / y.T
    
    stars <- if (exists("fixedb_stars")) {
      fixedb_stars(S_type2, stat = "wald", k = x.k, b = b_hat, direction = "ge")
    } else ""
    
    return(list(stat = S_type2, stars = stars, b_hat = b_hat, k_reg = x.k))
  }, error = function(e) { return(list(stat = NA, stars = "", b_hat = NA, k_reg = NA)) })
}

# -------------------------------------------------------------------------
# Test Statistic Generator for Shin (1994) LM Test (H0: Cointegration)
# -------------------------------------------------------------------------
calc_shin_lm_stat <- function(fit, T_obs) {
  tryCatch({
    # The crucial fix: NO double accumulation. fit$u.plus are ALREADY partial sums (S_t)
    S_t <- fit$u.plus
    omega2 <- fit$omega.u.v
    
    if (is.null(omega2) || is.na(omega2) || omega2 <= 0) {
      omega2 <- tryCatch(cointReg::getLongRunVar(fit$residuals, kernel = "ba", bandwidth = "nw")$long.run, error = function(e) NA)
    }
    
    if (is.na(omega2)) return(list(stat = NA, stars = ""))
    
    C_shin <- sum(S_t^2) / (T_obs^2 * omega2)
    stars <- if (C_shin >= 0.184) "$^{***}$" else if (C_shin >= 0.121) "$^{**}$" else if (C_shin >= 0.095) "$^{*}$" else ""
    
    return(list(stat = C_shin, stars = stars))
  }, error = function(e) { return(list(stat = NA, stars = "")) })
}
