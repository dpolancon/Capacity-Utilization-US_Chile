# 42_rank1_check.R
# ═══════════════════════════════════════════════════════════════════════════════
# Johansen at r=1: what does the first eigenvector look like alone?
# Same state vector X = (y, k, omega, omega_k), K=2, ecdet="const"
# ═══════════════════════════════════════════════════════════════════════════════

library(urca); library(tseries)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"

nf  <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))
nf  <- merge(nf, inc[, c("year","Py_fred")], by="year")
nf  <- nf[order(nf$year),]
P   <- nf$Py_fred[nf$year == 2024]
nf$y  <- log(nf$GVA_NF / (nf$Py_fred / P))
nf$k  <- log(nf$KGC_NF / (nf$Py_fred / P))
nf$w  <- nf$Wsh_NF
nf$wk <- nf$w * nf$k

X <- as.matrix(nf[, c("y","k","w","wk")])
N <- nrow(X)

jo <- ca.jo(X, type="trace", ecdet="const", K=2, spec="longrun")

# ── First eigenvector ────────────────────────────────────────────────────────
beta1 <- jo@V[, 1]
names(beta1) <- c("y","k","omega","omega_k","const")

# y-normalized
b1_y <- beta1 / beta1[1]

cat("=== RANK 1: First eigenvector (y-normalized) ===\n\n")
cat(sprintf("%-10s %12s\n", "Variable", "Coefficient"))
cat(strrep("-", 24), "\n")
for (i in 1:5) cat(sprintf("%-10s %+12.4f\n", names(b1_y)[i], b1_y[i]))

alpha1 <- -b1_y["k"]
alpha2 <- -b1_y["omega_k"]
gamma_w <- -b1_y["omega"]
c1     <- -b1_y["const"]

cat(sprintf("\nStructural content:\n"))
cat(sprintf("  y = %.4f*k + %.4f*omega + %.4f*(omega*k) + %.4f\n",
    alpha1, gamma_w, alpha2, c1))
cat(sprintf("  theta(omega) = %.4f + %.4f*omega\n", alpha1, alpha2))

omega_H <- (1 - alpha1) / alpha2
omega_star <- -alpha1 / alpha2
omega_range <- range(nf$w)
theta_range <- alpha1 + alpha2 * rev(omega_range)

cat(sprintf("\n  alpha1 (base elasticity)     = %.4f\n", alpha1))
cat(sprintf("  alpha2 (distribution slope)  = %.4f\n", alpha2))
cat(sprintf("  gamma  (direct omega)        = %.4f\n", gamma_w))
cat(sprintf("  c1     (constant)            = %.4f\n", c1))
cat(sprintf("  theta range                  = [%.4f, %.4f]\n",
    min(theta_range), max(theta_range)))
cat(sprintf("  omega_H (theta=1)            = %.4f  %s sample\n",
    omega_H,
    ifelse(omega_H >= omega_range[1] & omega_H <= omega_range[2], "IN", "outside")))
cat(sprintf("  omega*  (theta=0)            = %.4f  %s sample\n",
    omega_star,
    ifelse(omega_star >= omega_range[1] & omega_star <= omega_range[2], "IN", "outside")))

# ── Alpha loading ────────────────────────────────────────────────────────────
cat("\n=== ALPHA LOADING (r=1) ===\n")

Neff <- nrow(jo@Z0)
M00  <- crossprod(jo@Z0)/Neff; M11 <- crossprod(jo@Z1)/Neff
MKK  <- crossprod(jo@ZK)/Neff; M01 <- t(jo@Z0)%*%jo@Z1/Neff
M0K  <- t(jo@Z0)%*%jo@ZK/Neff; M1K <- t(jo@Z1)%*%jo@ZK/Neff
M11inv <- solve(M11)
S00 <- M00 - M01%*%M11inv%*%t(M01)
S0K <- M0K - M01%*%M11inv%*%M1K
SKK <- MKK - t(M1K)%*%M11inv%*%M1K

beta_mat <- matrix(beta1, ncol=1)
bSb <- t(beta_mat) %*% SKK %*% beta_mat
alpha_hat <- S0K %*% beta_mat %*% solve(bSb)
Sigma_hat <- S00 - S0K %*% beta_mat %*% solve(bSb) %*% t(beta_mat) %*% t(S0K)
bSb_inv <- solve(bSb)

vn <- c("y","k","omega","omega_k")
cat(sprintf("\n%-10s %10s %10s %10s\n", "Variable", "alpha", "SE", "t-stat"))
cat(strrep("-", 42), "\n")
for (i in 1:4) {
  se <- sqrt(Sigma_hat[i,i] * bSb_inv[1,1] / Neff)
  tt <- alpha_hat[i,1] / se
  cat(sprintf("%-10s %+10.4f %10.4f %10.2f\n", vn[i], alpha_hat[i,1], se, tt))
}

# ── ECT stationarity ────────────────────────────────────────────────────────
ect1 <- cbind(X, 1) %*% beta1
adf <- adf.test(ect1)
cat(sprintf("\nECT1 stationarity: ADF = %.3f  p = %.3f  %s\n",
    adf$statistic, adf$p.value,
    ifelse(adf$p.value < 0.05, "I(0)", "WARNING")))

# ── Eigenvalue ───────────────────────────────────────────────────────────────
cat(sprintf("\nlambda_1 = %.4f  (trace stat for r<=0: %.2f, 5%% cv: %.2f)\n",
    jo@lambda[1], jo@teststat[4], jo@cval[4,2]))

cat("\n=== COMPARISON: r=1 vs r=3 (unrestricted) ===\n")
cat(sprintf("%-20s %12s %12s\n", "", "r=1", "r=3"))
cat(strrep("-", 46), "\n")

V3 <- jo@V[, 1:3]
v3_y <- V3[,1] / V3[1,1]
cat(sprintf("%-20s %+12.4f %+12.4f\n", "k (alpha1)", b1_y[2], v3_y[2]))
cat(sprintf("%-20s %+12.4f %+12.4f\n", "omega (gamma)", b1_y[3], v3_y[3]))
cat(sprintf("%-20s %+12.4f %+12.4f\n", "omega_k (alpha2)", b1_y[4], v3_y[4]))
cat(sprintf("%-20s %+12.4f %+12.4f\n", "const (c1)", b1_y[5], v3_y[5]))
cat(sprintf("%-20s %12.4f %12.4f\n", "theta(omega_bar)",
    alpha1 + alpha2 * mean(nf$w),
    -v3_y[2] + (-v3_y[4]) * mean(nf$w)))


# ═══════════════════════════════════════════════════════════════════════════════
# CAPACITY UTILIZATION — pinned at mu(1948)=0.80, closure g_Y^p = theta*g_K
# ═══════════════════════════════════════════════════════════════════════════════
library(tidyverse)

fig_dir <- file.path(REPO, "output/stage_a/us/figs")
csv_dir <- file.path(REPO, "output/stage_a/us/csv")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

dual_save <- function(plot, name, w = 8, h = 5.5, dpi = 300) {
  ggsave(file.path(fig_dir, paste0(name, ".png")),
         plot = plot, width = w, height = h, dpi = dpi)
  ggsave(file.path(fig_dir, paste0(name, ".pdf")),
         plot = plot, width = w, height = h, device = cairo_pdf)
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}

cat("\n=== CAPACITY UTILIZATION (r=1) ===\n")

Y     <- nf$GVA_NF / (nf$Py_fred / P)
K     <- nf$KGC_NF / (nf$Py_fred / P)
omega <- nf$w
theta_t <- alpha1 + alpha2 * omega
k_log <- log(K)
dk    <- c(NA, diff(k_log))

# Pin
mu_pin <- 0.8; year_pin <- 1948
i_pin  <- which(nf$year == year_pin)
y_star <- numeric(N)
y_star[i_pin] <- log(Y[i_pin] / mu_pin)

for (t in (i_pin + 1):N) y_star[t] <- y_star[t-1] + theta_t[t] * dk[t]
for (t in (i_pin - 1):1)  y_star[t] <- y_star[t+1] - theta_t[t+1] * dk[t+1]

Y_star <- exp(y_star)
mu_t   <- Y / Y_star

# ECT-based mu
y_log <- log(Y)
ect1_vec <- y_log - alpha1*k_log - gamma_w*omega - alpha2*omega*k_log - c1
mu_ect <- exp(ect1_vec - mean(ect1_vec))

# Tibble
r1_tbl <- tibble(
  year    = nf$year,
  omega   = omega,
  theta   = theta_t,
  Y       = Y,
  K       = K,
  Y_star  = Y_star,
  mu      = mu_t,
  mu_ect  = mu_ect,
  period  = case_when(
    year <= 1944 ~ "Pre-Fordist",
    year <= 1973 ~ "Fordist",
    TRUE         ~ "Post-Fordist"
  )
)

cat(sprintf("%-5s %7s %8s %10s %10s %7s %7s\n",
    "year", "omega", "theta", "Y", "Y_star", "mu", "mu_ect"))
cat(strrep("-", 62), "\n")
for (i in 1:nrow(r1_tbl)) {
  r <- r1_tbl[i, ]
  cat(sprintf("%4d  %.4f  %7.4f  %8.0f  %8.0f  %.4f  %.4f\n",
      r$year, r$omega, r$theta, r$Y, r$Y_star, r$mu, r$mu_ect))
}

cat("\n--- Summary by period ---\n")
r1_tbl %>%
  group_by(period) %>%
  summarise(
    n = n(),
    theta_mean = round(mean(theta), 4),
    mu_mean    = round(mean(mu), 4),
    mu_ect_mn  = round(mean(mu_ect), 4),
    .groups = "drop"
  ) %>% print()

write_csv(r1_tbl, file.path(csv_dir, "rank1_theta_mu_us.csv"))
cat("\nSaved: rank1_theta_mu_us.csv\n")

# ── Plots ────────────────────────────────────────────────────────────────────
theme_r1 <- theme_minimal(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "grey93", linewidth = 0.35),
    legend.position  = "bottom",
    plot.caption     = element_text(size = 6.5, color = "grey50"),
    plot.margin      = margin(10, 20, 10, 10)
  )

cap <- "r=1 | theta(omega) = 8.924 - 12.851*omega | mu(1948)=0.80 pinned"

# mu (structural closure)
p1 <- ggplot(r1_tbl, aes(x = year, y = mu)) +
  geom_line(linewidth = 0.7, color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "grey50") +
  labs(x = NULL, y = expression(mu[t]), caption = cap) +
  theme_r1
dual_save(p1, "r1_mu_capacity_utilization", w = 10, h = 5.5)

# mu_ect
p2 <- ggplot(r1_tbl, aes(x = year, y = mu_ect)) +
  geom_line(linewidth = 0.7, color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "grey50") +
  labs(x = NULL, y = expression(mu[ECT]), caption = "r=1 | exp(ECT1 - mean(ECT1))") +
  theme_r1
dual_save(p2, "r1_mu_ect", w = 10, h = 5.5)

# theta over time
p3 <- ggplot(r1_tbl, aes(x = year, y = theta)) +
  geom_line(linewidth = 0.7, color = "steelblue") +
  geom_hline(yintercept = 1, linetype = "dashed", color = "firebrick", linewidth = 0.4) +
  geom_vline(xintercept = 1973, linetype = "dotted", color = "grey50") +
  labs(x = NULL, y = expression(theta(omega[t])), caption = cap) +
  theme_r1
dual_save(p3, "r1_theta_timeseries", w = 10, h = 5.5)

cat("\nAll r=1 plots saved.\n")
