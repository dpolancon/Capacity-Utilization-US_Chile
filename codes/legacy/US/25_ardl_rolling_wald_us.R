# 25_ardl_rolling_wald_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Stage C: Rolling Window Wald Test Robustness
# H0: beta_mu = beta_PyPK + beta_Br (Okishio restriction)
# 4-channel ARDL, Case 3 only, max_order=2, AIC selection
# ═══════════════════════════════════════════════════════════════════════════════

library(readr)
library(dplyr)
library(tibble)
library(ARDL)
library(ggplot2)
library(showtext)

font_add_google("Roboto Condensed", "roboto")
showtext_auto()

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
csv_dir <- file.path(REPO, "output/stage_c/US/csv")
fig_dir <- file.path(REPO, "output/stage_c/US/figs")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)

save_fig <- function(plot, name, w = 10, h = 5, dpi = 150) {
  ggsave(file.path(fig_dir, paste0(name, ".png")), plot = plot, width = w, height = h, dpi = dpi)
  ggsave(file.path(fig_dir, paste0(name, ".pdf")), plot = plot, width = w, height = h, device = cairo_pdf)
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}

ds <- read_csv(file.path(REPO, "data/processed/us_nf_corporate_stageC.csv"),
               show_col_types = FALSE)


# ═══════════════════════════════════════════════════════════════════════════════
# WORKHORSE: estimate one window, return results row
# ═══════════════════════════════════════════════════════════════════════════════

estimate_window <- function(ds, s, e_yr) {
  tryCatch({
    buf <- 3
    df <- ds %>% filter(year >= (s - buf), year <= e_yr) %>% arrange(year)
    df_ts <- ts(df[, c("year","g_K","mu","B_real","PyPK","pi")],
                start = min(df$year), frequency = 1)

    auto <- auto_ardl(g_K ~ mu + B_real + PyPK + pi,
                      data = df_ts, max_order = 2, selection = "AIC")
    best <- auto$best_model
    n_eff <- nobs(best)

    # Bounds tests Case 3
    bf <- tryCatch(bounds_f_test(best, case = 3),
                   error = function(e) list(statistic = NA, p.value = NA))
    bt <- tryCatch(bounds_t_test(best, case = 3),
                   error = function(e) list(statistic = NA, p.value = NA))

    # Long-run multipliers
    lr <- multipliers(best)
    lr_mu   <- lr$Estimate[lr$Term == "mu"]
    lr_mu_p <- lr[["Pr(>|t|)"]][lr$Term == "mu"]
    lr_pp   <- lr$Estimate[lr$Term == "PyPK"]
    lr_pp_p <- lr[["Pr(>|t|)"]][lr$Term == "PyPK"]
    lr_br   <- lr$Estimate[lr$Term == "B_real"]
    lr_br_p <- lr[["Pr(>|t|)"]][lr$Term == "B_real"]
    lr_pi   <- lr$Estimate[lr$Term == "pi"]
    lr_pi_p <- lr[["Pr(>|t|)"]][lr$Term == "pi"]

    # ECM
    ecm <- recm(best, case = 3)
    ecm_cf <- summary(ecm)$coefficients
    ect_row <- which(rownames(ecm_cf) == "ect")
    ect_val <- ecm_cf[ect_row, "Estimate"]

    # Wald test: beta_mu = beta_PyPK + beta_Br
    an <- names(coef(best))
    mu_n <- grep("^mu$|^L[(]mu", an, value = TRUE)
    br_n <- grep("^B_real$|^L[(]B_real", an, value = TRUE)
    pp_n <- grep("^PyPK$|^L[(]PyPK", an, value = TRUE)

    R <- rep(0, length(coef(best))); names(R) <- an
    for (nm in mu_n) R[nm] <- R[nm] + 1
    for (nm in br_n) R[nm] <- R[nm] - 1
    for (nm in pp_n) R[nm] <- R[nm] - 1

    d <- sum(R * coef(best))
    se <- as.numeric(sqrt(t(R) %*% vcov(best) %*% R))
    wt <- d / se
    wp <- 2 * pt(-abs(wt), df = n_eff - length(coef(best)))

    tibble(
      window_start = s, window_end = e_yr, n_eff = n_eff,
      ardl_order = paste(auto$best_order, collapse = ","),
      aic = AIC(best),
      bounds_F_case3 = bf$statistic, bounds_F_p = bf$p.value,
      bounds_t_case3 = bt$statistic, bounds_t_p = bt$p.value,
      ECT = ect_val,
      LR_mu = lr_mu, LR_mu_p = lr_mu_p,
      LR_PyPK = lr_pp, LR_PyPK_p = lr_pp_p,
      LR_Br = lr_br, LR_Br_p = lr_br_p,
      LR_pi = lr_pi, LR_pi_p = lr_pi_p,
      wald_diff = d, wald_se = se, wald_t = wt, wald_p = wp,
      wald_decision = ifelse(wp < 0.05, "Reject", "Fail to reject")
    )
  }, error = function(e) {
    tibble(
      window_start = s, window_end = e_yr, n_eff = NA_integer_,
      ardl_order = NA_character_, aic = NA_real_,
      bounds_F_case3 = NA, bounds_F_p = NA,
      bounds_t_case3 = NA, bounds_t_p = NA,
      ECT = NA,
      LR_mu = NA, LR_mu_p = NA,
      LR_PyPK = NA, LR_PyPK_p = NA,
      LR_Br = NA, LR_Br_p = NA,
      LR_pi = NA, LR_pi_p = NA,
      wald_diff = NA, wald_se = NA, wald_t = NA, wald_p = NA,
      wald_decision = "ERROR"
    )
  })
}


# ═══════════════════════════════════════════════════════════════════════════════
# EXERCISE 1 — Extend backwards (start 1945:1948, end 1973)
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 60), "\n")
cat("EXERCISE 1: Backward extension (start 1945-1948, end 1973)\n")
cat(strrep("=", 60), "\n")

res_back <- bind_rows(lapply(1945:1948, function(s) {
  cat(sprintf("  %d-1973...", s))
  r <- estimate_window(ds, s, 1973)
  cat(sprintf(" ARDL(%s) N=%d Wald p=%.4f %s\n",
      r$ardl_order, r$n_eff, r$wald_p, r$wald_decision))
  r
}))

cat("\n=== EXERCISE 1 SUMMARY ===\n")
print(res_back)
cat("\nFlagged:\n")
flagged <- res_back %>% filter(n_eff < 20 | bounds_F_p > 0.10 | wald_decision == "ERROR")
if (nrow(flagged) > 0) print(flagged) else cat("  None\n")

write_csv(res_back, file.path(csv_dir, "stageC_US_rolling_wald_backward.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# EXERCISE 2 — Extend forwards (start 1948, end 1973:1978)
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 60), "\n")
cat("EXERCISE 2: Forward extension (start 1948, end 1973-1978)\n")
cat(strrep("=", 60), "\n")

res_fwd <- bind_rows(lapply(1973:1978, function(e_yr) {
  cat(sprintf("  1948-%d...", e_yr))
  r <- estimate_window(ds, 1948, e_yr)
  cat(sprintf(" ARDL(%s) N=%d Wald p=%.4f %s\n",
      r$ardl_order, r$n_eff, r$wald_p, r$wald_decision))
  r
}))

cat("\n=== EXERCISE 2 SUMMARY ===\n")
print(res_fwd)
cat("\nFlagged:\n")
flagged <- res_fwd %>% filter(n_eff < 20 | bounds_F_p > 0.10 | wald_decision == "ERROR")
if (nrow(flagged) > 0) print(flagged) else cat("  None\n")

write_csv(res_fwd, file.path(csv_dir, "stageC_US_rolling_wald_forward.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# EXERCISE 3 — Full grid (4 x 6 = 24 windows)
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n", strrep("=", 60), "\n")
cat("EXERCISE 3: Full grid (start 1945-1948 x end 1973-1978)\n")
cat(strrep("=", 60), "\n")

grid <- expand.grid(s = 1945:1948, e = 1973:1978)
res_grid <- bind_rows(lapply(1:nrow(grid), function(i) {
  s <- grid$s[i]; e_yr <- grid$e[i]
  cat(sprintf("  %d-%d...", s, e_yr))
  r <- estimate_window(ds, s, e_yr)
  cat(sprintf(" N=%d Wald p=%.4f %s\n", r$n_eff, r$wald_p, r$wald_decision))
  r
}))

cat("\n=== EXERCISE 3 SUMMARY ===\n")
print(res_grid)
cat("\nFlagged:\n")
flagged <- res_grid %>% filter(n_eff < 20 | bounds_F_p > 0.10 | wald_decision == "ERROR")
if (nrow(flagged) > 0) print(flagged) else cat("  None\n")

write_csv(res_grid, file.path(csv_dir, "stageC_US_rolling_wald_grid.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# FIGURES
# ═══════════════════════════════════════════════════════════════════════════════

theme_rc <- theme_minimal(base_family = "roboto", base_size = 11) +
  theme(
    axis.line = element_line(color = "#AAAAAA", linewidth = 0.4),
    axis.ticks = element_line(color = "#AAAAAA", linewidth = 0.3),
    panel.grid.major.y = element_line(color = "#EEEEEE", linewidth = 0.3),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.caption = element_text(size = 7, color = "#666666"),
    plot.margin = margin(5, 15, 5, 5)
  )

ref_lines <- list(
  geom_hline(yintercept = 0.05, linetype = "dashed", color = "#B2182B", linewidth = 0.5),
  geom_hline(yintercept = 0.10, linetype = "dotted", color = "#D55E00", linewidth = 0.4)
)

# ── RC1a: backward ─────────────────────────────────────────────────────────
fig_rc1a <- ggplot(res_back, aes(x = window_start, y = wald_p)) +
  ref_lines +
  geom_vline(xintercept = 1948, linetype = "dashed", color = "#666666", linewidth = 0.4) +
  geom_point(aes(color = wald_decision), size = 3) +
  geom_line(linewidth = 0.5, color = "#333333") +
  scale_color_manual(values = c("Reject" = "#B2182B", "Fail to reject" = "#2166AC",
                                "ERROR" = "grey50")) +
  scale_x_reverse(breaks = 1945:1948) +
  annotate("text", x = 1948, y = max(res_back$wald_p, na.rm=TRUE) * 0.9,
           label = "primary", size = 3, color = "#666666", hjust = 1.2, family = "roboto") +
  labs(x = "Start year", y = "Wald p-value", color = NULL,
       caption = "H0: beta_mu = beta_PyPK + beta_Br | End fixed at 1973 | Case 3") +
  theme_rc + theme(legend.position = c(0.8, 0.8))

save_fig(fig_rc1a, "fig_RC1a_wald_backward")

# ── RC1b: forward ──────────────────────────────────────────────────────────
fig_rc1b <- ggplot(res_fwd, aes(x = window_end, y = wald_p)) +
  ref_lines +
  geom_vline(xintercept = 1973, linetype = "dashed", color = "#666666", linewidth = 0.4) +
  geom_point(aes(color = wald_decision), size = 3) +
  geom_line(linewidth = 0.5, color = "#333333") +
  scale_color_manual(values = c("Reject" = "#B2182B", "Fail to reject" = "#2166AC",
                                "ERROR" = "grey50")) +
  scale_x_continuous(breaks = 1973:1978) +
  annotate("text", x = 1973, y = max(res_fwd$wald_p, na.rm=TRUE) * 0.9,
           label = "primary", size = 3, color = "#666666", hjust = -0.2, family = "roboto") +
  labs(x = "End year", y = "Wald p-value", color = NULL,
       caption = "H0: beta_mu = beta_PyPK + beta_Br | Start fixed at 1948 | Case 3") +
  theme_rc + theme(legend.position = c(0.8, 0.8))

save_fig(fig_rc1b, "fig_RC1b_wald_forward")

# ── RC2: heatmap ───────────────────────────────────────────────────────────
fig_rc2 <- ggplot(res_grid, aes(x = factor(window_end), y = factor(window_start))) +
  geom_tile(aes(fill = wald_p), color = "white", linewidth = 0.8) +
  geom_text(aes(label = sprintf("%.3f", wald_p)), size = 3.5, family = "roboto") +
  # Highlight primary window
  geom_tile(data = res_grid %>% filter(window_start == 1948, window_end == 1973),
            fill = NA, color = "black", linewidth = 1.2) +
  scale_fill_gradient2(low = "#B2182B", mid = "#FFFFFF", high = "#2166AC",
                       midpoint = 0.05, name = "Wald p") +
  scale_y_discrete(limits = rev(as.character(1945:1948))) +
  labs(x = "End year", y = "Start year",
       caption = "H0: beta_mu = beta_PyPK + beta_Br | 4ch ARDL, Case 3, max_order=2 | Black border: primary window") +
  theme_rc +
  theme(panel.grid = element_blank(),
        axis.text = element_text(size = 10))

save_fig(fig_rc2, "fig_RC2_wald_grid_heatmap")


cat("\n", strrep("=", 60), "\n")
cat("Rolling window Wald test robustness complete.\n")
cat(strrep("=", 60), "\n")
