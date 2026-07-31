# scratch/test_pure_interaction_specB.R
source("codes/US_S33_break_aware_common.R")

std_condition <- function(X) {
  X <- as.matrix(X)
  s <- apply(X, 2, function(c) sqrt(sum(c^2)))
  s[s == 0 | !is.finite(s)] <- 1
  suppressWarnings(kappa(sweep(X, 2, s, "/"), exact = TRUE))
}

panel <- s33_load_spec_b()

run_pure_spec <- function(win_key, step_years, block_args = NULL, drop_standalone_kappa = TRUE) {
  win <- if(grepl("Fordist", win_key)) list(key = "Fordist_1929_1973", range = c(1929, 1973)) else list(key = "PostFordist_1974_2024", range = c(1974, 2024))
  d <- s33_window(panel, win)
  yr <- as.numeric(d$year)
  y <- as.numeric(d$y)

  # Regime B Initial-State Centering
  kn <- s33_center(d$k_NRC, "Regime_B_Initial_Centered")
  kp <- s33_center(d$kappa, "Regime_B_Initial_Centered")
  pk <- s33_center(d$p_kappa, "Regime_B_Initial_Centered")
  w  <- s33_center(d$omega_lag1, "Regime_B_Initial_Centered")

  if (drop_standalone_kappa) {
    # Drop standalone kappa! Keep k_NRC, p_kappa, omega, and interaction kappa * omega
    X <- cbind(k_NRC = kn, p_kappa = pk, omega = w, kappa_x_omega = kp * w, kappa_x_pkappa = kp * pk)
  } else {
    # Standard Spec B3 with standalone kappa
    X <- cbind(k_NRC = kn, kappa = kp, p_kappa = pk, omega = w, kappa_x_omega = kp * w, kappa_x_pkappa = kp * pk)
  }

  for (sy in step_years) {
    st <- as.numeric(yr >= sy)
    if (sd(st) > 0) {
      X <- cbind(X, st)
      colnames(X)[ncol(X)] <- paste0("D_", sy)
    }
  }
  if (!is.null(block_args)) {
    bl <- as.numeric(yr >= block_args[1] & yr <= block_args[2])
    if (sd(bl) > 0) {
      X <- cbind(X, bl)
      colnames(X)[ncol(X)] <- paste0("B_", block_args[1], "_", block_args[2])
    }
  }

  deter <- matrix(1, nrow = length(y), ncol = 1)
  fit_imols <- cointReg::cointRegIM(x = as.matrix(X), y = as.vector(y), deter = deter, selector = c(1, 2), t.test = TRUE)
  cond_num <- std_condition(cbind(1, X))
  
  nms <- c("Intercept", colnames(X))
  res_df <- data.frame(
    term     = nms[1:length(fit_imols$theta)],
    estimate = round(as.vector(fit_imols$theta), 4),
    std_err  = round(as.vector(fit_imols$sd.theta), 4),
    t_stat   = round(as.vector(fit_imols$t.theta), 2)
  )

  return(list(res_table = res_df, cond = cond_num, c_shin = fit_imols$c.shin))
}

cat("===================================================================\n")
cat("EVALUATING STANDALONE KAPPA EXCLUSION IN SPECIFICATION B (REGIME B)\n")
cat("===================================================================\n\n")

cat("--- 1. FORDIST ERA (1929-1973) ---\n")
r_ford_std <- run_pure_spec("Fordist_1929_1973", c(1933, 1947), c(1942, 1945), drop_standalone_kappa = FALSE)
r_ford_excl <- run_pure_spec("Fordist_1929_1973", c(1933, 1947), c(1942, 1945), drop_standalone_kappa = TRUE)

cat("\nA. STANDARD MODEL (Includes Standalone Kappa):\n")
cat("Condition Number:", r_ford_std$cond, "\n")
cat("Shin LM (C_shin):", r_ford_std$c_shin, "\n")
print(r_ford_std$res_table)

cat("\nB. EXCLUDED STANDALONE KAPPA MODEL (Pure Wage Interaction Only):\n")
cat("Condition Number:", r_ford_excl$cond, "\n")
cat("Shin LM (C_shin):", r_ford_excl$c_shin, "\n")
print(r_ford_excl$res_table)

cat("\n===================================================================\n")
cat("--- 2. POST-FORDIST ERA (1974-2024) ---\n")
r_post_std <- run_pure_spec("PostFordist_1974_2024", c(1981, 2000, 2008), NULL, drop_standalone_kappa = FALSE)
r_post_excl <- run_pure_spec("PostFordist_1974_2024", c(1981, 2000, 2008), NULL, drop_standalone_kappa = TRUE)

cat("\nA. STANDARD MODEL (Includes Standalone Kappa):\n")
cat("Condition Number:", r_post_std$cond, "\n")
cat("Shin LM (C_shin):", r_post_std$c_shin, "\n")
print(r_post_std$res_table)

cat("\nB. EXCLUDED STANDALONE KAPPA MODEL (Pure Wage Interaction Only):\n")
cat("Condition Number:", r_post_excl$cond, "\n")
cat("Shin LM (C_shin):", r_post_excl$c_shin, "\n")
print(r_post_excl$res_table)
