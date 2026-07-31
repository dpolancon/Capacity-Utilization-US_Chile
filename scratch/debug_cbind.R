# scratch/debug_cbind.R
source("codes/US_S33_break_aware_common.R")
panel <- s33_load_spec_a()
win_spec <- S33_WINDOWS$Fordist_1929_1973
regime <- "Regime_B_Initial_Centered"
win <- S33_WINDOWS[[win_spec$key]]
d <- s33_window(panel, win)
d <- d[stats::complete.cases(d[, c("y", "k_cap", "omega_lag1")]), , drop = FALSE]
yr <- d$year
y <- d$y

k <- s33_center(d$k_cap, regime)
w <- s33_center(d$omega_lag1, regime)
inter <- k * w

X <- cbind(k_cap = k, omega = w, interaction = inter)
D <- s33_step(yr, win_spec$tb_star)
cat("length(yr) =", length(yr), "\n")
cat("length(D) =", length(D), "\n")
cat("class(D) =", class(D), "\n")
cat("sd(D) =", sd(D), "\n")

X2 <- cbind(X, D_TB = D, inter_x_D = inter * D)
cat("ncol(X2) =", ncol(X2), "\n")
cat("colnames(X2) =", paste(colnames(X2), collapse = ", "), "\n")
