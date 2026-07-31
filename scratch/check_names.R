# scratch/check_names.R
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
X <- cbind(X, D_TB = D, inter_x_D = inter * D)

print(colnames(X))
deter <- matrix(1, nrow = length(y), ncol = 1)
fit <- cointReg::cointRegIM(x = X, y = y, deter = deter, selector = c(1, 2), t.test = TRUE)
print(names(fit$theta.all))
print(fit$theta.all)
