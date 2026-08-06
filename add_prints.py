import re

with open('codes/US_S50_section31_imols_estimation.R', 'r', encoding='utf-8') as f:
    code = f.read()

# Add detailed prints in cointRegIM_CMPR
prints_cmpr = """
  print("Entering cointRegIM_CMPR")
  print(paste("dim y:", paste(dim(as.matrix(y)), collapse="x")))
  print(paste("dim x:", paste(dim(as.matrix(x)), collapse="x")))
  print(paste("dim x_base:", paste(dim(as.matrix(x_base)), collapse="x")))
"""
code = code.replace("cointRegIM_CMPR <- function(x, y, deter, x_base, selector = c(1, 2), kernel = \"ba\", bandwidth = \"nw\") {",
"cointRegIM_CMPR <- function(x, y, deter, x_base, selector = c(1, 2), kernel = \"ba\", bandwidth = \"nw\") {\n" + prints_cmpr)

code = code.replace("X_lvl <- if (d.k == 0) as.matrix(x) else cbind(deter, x)",
"print(\"Constructing X_lvl\")\n  X_lvl <- if (d.k == 0) as.matrix(x) else cbind(deter, x)")

code = code.replace("lrv_res <- cointReg::getLongRunVar(eta_t, kernel = kernel, bandwidth = bandwidth)",
"print(\"Running getLongRunVar\")\n  lrv_res <- cointReg::getLongRunVar(eta_t, kernel = kernel, bandwidth = bandwidth)")

code = code.replace("O22inv <- cointReg:::trySolve(Omega22)",
"print(\"Trying trySolve on Omega22\")\n  print(dim(Omega22))\n  O22inv <- cointReg:::trySolve(Omega22)")

code = code.replace("omega.u.v <- as.numeric(Omega11)", "print(\"omega.u.v (null case)\"); omega.u.v <- as.numeric(Omega11)")
code = code.replace("omega.u.v <- as.numeric(Omega11 - Omega12 %*% O22inv %*% Omega21)", "print(\"omega.u.v (matrix case)\"); omega.u.v <- as.numeric(Omega11 - Omega12 %*% O22inv %*% Omega21)")

code = code.replace("sd.theta1 <- sqrt(omega.u.v * diag(V))", "print(\"Calculating sd.theta1\"); sd.theta1 <- sqrt(omega.u.v * diag(V))")

# Also calc_vw_type2_stat
code = code.replace("calc_vw_type2_stat <- function(x, y, deter, fit, x_base) {",
"calc_vw_type2_stat <- function(x, y, deter, fit, x_base) {\n  print(\"Entering calc_vw_type2_stat\")\n  print(paste(\"dim x_base:\", paste(dim(as.matrix(x_base)), collapse=\"x\")))")

with open('codes/US_S50_section31_imols_estimation.R', 'w', encoding='utf-8') as f:
    f.write(code)
