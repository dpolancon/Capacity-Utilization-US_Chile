# 26_ardl_rolling_wald_netK_exact.R
# ═══════════════════════════════════════════════════════════════════════════════
# Rolling Window Wald + Exact-Sample Bounds Tests
# Both g_K (gross) and g_Kn (net) capital accumulation
# 4-channel ARDL, Case 3, max_order=2, AIC
# Exact bootstrap: R=20000 (stable to 3 decimal places)
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

BOOT_R <- 20000

save_fig <- function(plot, name, w = 10, h = 5, dpi = 150) {
  ggsave(file.path(fig_dir, paste0(name, ".png")), plot = plot, width = w, height = h, dpi = dpi)
  ggsave(file.path(fig_dir, paste0(name, ".pdf")), plot = plot, width = w, height = h, device = cairo_pdf)
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}

ds <- read_csv(file.path(REPO, "data/processed/us_nf_corporate_stageC.csv"),
               show_col_types = FALSE)

set.seed(2024)


# ═══════════════════════════════════════════════════════════════════════════════
# WORKHORSE
# ═══════════════════════════════════════════════════════════════════════════════

estimate_window <- function(ds, dv, s, e_yr, boot_R) {
  tryCatch({
    buf <- 3
    df <- ds %>% filter(year >= (s - buf), year <= e_yr) %>% arrange(year)
    f <- as.formula(paste(dv, "~ mu + B_real + PyPK + pi"))
    df_ts <- ts(df[, c("year", dv, "mu","B_real","PyPK","pi")],
                start = min(df$year), frequency = 1)

    auto <- auto_ardl(f, data = df_ts, max_order = 2, selection = "AIC")
    best <- auto$best_model
    n_eff <- nobs(best)

    # Asymptotic bounds (Case 3)
    bf_asy <- tryCatch(bounds_f_test(best, case = 3, exact = FALSE),
                       error = function(e) list(statistic = NA, p.value = NA))
    bt_asy <- tryCatch(bounds_t_test(best, case = 3, exact = FALSE),
                       error = function(e) list(statistic = NA, p.value = NA))

    # Exact-sample bounds (Case 3, bootstrap)
    bf_ex <- tryCatch(bounds_f_test(best, case = 3, exact = TRUE, R = boot_R),
                      error = function(e) list(statistic = NA, p.value = NA))
    bt_ex <- tryCatch(bounds_t_test(best, case = 3, exact = TRUE, R = boot_R),
                      error = function(e) list(statistic = NA, p.value = NA))

    # Long-run multipliers
    lr <- multipliers(best)
    get_lr <- function(term) {
      row <- which(lr$Term == term)
      if (length(row) == 0) return(c(NA, NA))
      c(lr$Estimate[row], lr[["Pr(>|t|)"]][row])
    }
    lm <- get_lr("mu"); lp <- get_lr("PyPK"); lb <- get_lr("B_real"); lpi <- get_lr("pi")

    # ECM
    ecm <- recm(best, case = 3)
    ecm_cf <- summary(ecm)$coefficients
    ect_row <- which(rownames(ecm_cf) == "ect")
    ect_val <- ecm_cf[ect_row, "Estimate"]

    # Wald test
    an <- names(coef(best))
    mu_n <- grep("^mu$|^L[(]mu", an, value = TRUE)
    br_n <- grep("^B_real$|^L[(]B_real", an, value = TRUE)
    pp_n <- grep("^PyPK$|^L[(]PyPK", an, value = TRUE)

    R_vec <- rep(0, length(coef(best))); names(R_vec) <- an
    for (nm in mu_n) R_vec[nm] <- R_vec[nm] + 1
    for (nm in br_n) R_vec[nm] <- R_vec[nm] - 1
    for (nm in pp_n) R_vec[nm] <- R_vec[nm] - 1

    d <- sum(R_vec * coef(best))
    se <- as.numeric(sqrt(t(R_vec) %*% vcov(best) %*% R_vec))
    wt <- d / se
    wp <- 2 * pt(-abs(wt), df = n_eff - length(coef(best)))

    tibble(
      dep_var = dv, window_start = s, window_end = e_yr, n_eff = n_eff,
      ardl_order = paste(auto$best_order, collapse = ","),
      aic = AIC(best),
      # Asymptotic
      F_asy = bf_asy$statistic, F_asy_p = bf_asy$p.value,
      t_asy = bt_asy$statistic, t_asy_p = bt_asy$p.value,
      # Exact (bootstrap)
      F_exact = bf_ex$statistic, F_exact_p = bf_ex$p.value,
      t_exact = bt_ex$statistic, t_exact_p = bt_ex$p.value,
      # ECT and LR
      ECT = ect_val,
      LR_mu = lm[1], LR_mu_p = lm[2],
      LR_PyPK = lp[1], LR_PyPK_p = lp[2],
      LR_Br = lb[1], LR_Br_p = lb[2],
      LR_pi = lpi[1], LR_pi_p = lpi[2],
      # Wald
      wald_diff = d, wald_se = se, wald_t = wt, wald_p = wp,
      wald_decision = ifelse(wp < 0.05, "Reject", "Fail to reject")
    )
  }, error = function(e) {
    tibble(
      dep_var = dv, window_start = s, window_end = e_yr, n_eff = NA_integer_,
      ardl_order = NA_character_, aic = NA,
      F_asy = NA, F_asy_p = NA, t_asy = NA, t_asy_p = NA,
      F_exact = NA, F_exact_p = NA, t_exact = NA, t_exact_p = NA,
      ECT = NA,
      LR_mu = NA, LR_mu_p = NA, LR_PyPK = NA, LR_PyPK_p = NA,
      LR_Br = NA, LR_Br_p = NA, LR_pi = NA, LR_pi_p = NA,
      wald_diff = NA, wald_se = NA, wald_t = NA, wald_p = NA,
      wald_decision = "ERROR"
    )
  })
}


# ═══════════════════════════════════════════════════════════════════════════════
# FULL GRID: 4 start x 6 end x 2 dep vars = 48 windows
# ═══════════════════════════════════════════════════════════════════════════════

grid <- expand.grid(s = 1945:1948, e = 1973:1978, dv = c("g_K", "g_Kn"),
                    stringsAsFactors = FALSE)

cat(sprintf("Running %d windows with R=%d bootstrap replications each...\n",
    nrow(grid), BOOT_R))
cat("This will take several minutes.\n\n")

results <- bind_rows(lapply(1:nrow(grid), function(i) {
  s <- grid$s[i]; e_yr <- grid$e[i]; dv <- grid$dv[i]
  cat(sprintf("[%2d/%d] %s %d-%d ...", i, nrow(grid), dv, s, e_yr))
  r <- estimate_window(ds, dv, s, e_yr, BOOT_R)
  cat(sprintf(" N=%d F_asy=%.3f F_ex=%.3f t_asy=%.3f t_ex=%.3f Wald=%.4f\n",
      r$n_eff,
      ifelse(is.na(r$F_asy), NA, r$F_asy),
      ifelse(is.na(r$F_exact), NA, r$F_exact),
      ifelse(is.na(r$t_asy), NA, r$t_asy),
      ifelse(is.na(r$t_exact), NA, r$t_exact),
      r$wald_p))
  r
}))


# ═══════════════════════════════════════════════════════════════════════════════
# SAVE CSVs
# ═══════════════════════════════════════════════════════════════════════════════

# Split by dep var
res_gK  <- results %>% filter(dep_var == "g_K")
res_gKn <- results %>% filter(dep_var == "g_Kn")

write_csv(res_gK,  file.path(csv_dir, "stageC_US_rolling_wald_grid_grossK_exact.csv"))
write_csv(res_gKn, file.path(csv_dir, "stageC_US_rolling_wald_grid_netK_exact.csv"))
write_csv(results, file.path(csv_dir, "stageC_US_rolling_wald_grid_both_exact.csv"))


# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY TABLES
# ═══════════════════════════════════════════════════════════════════════════════

for (dv_label in c("g_K", "g_Kn")) {
  d <- results %>% filter(dep_var == dv_label)
  cat(sprintf("\n%s\n=== %s: Asymptotic vs Exact-Sample Bounds (Case 3) ===\n%s\n",
      strrep("=", 70), dv_label, strrep("=", 70)))
  cat(sprintf("%-5s %-5s %3s | %7s %7s %7s %7s | %7s %7s %7s %7s\n",
      "Start","End","N", "F_asy","F_asy_p","t_asy","t_asy_p",
      "F_ex","F_ex_p","t_ex","t_ex_p"))
  cat(strrep("-", 85), "\n")
  for (i in 1:nrow(d)) {
    cat(sprintf("%-5d %-5d %3d | %7.3f %7.4f %7.3f %7.4f | %7.3f %7.4f %7.3f %7.4f\n",
        d$window_start[i], d$window_end[i], d$n_eff[i],
        d$F_asy[i], d$F_asy_p[i], d$t_asy[i], d$t_asy_p[i],
        d$F_exact[i], d$F_exact_p[i], d$t_exact[i], d$t_exact_p[i]))
  }

  cat(sprintf("\nRejection counts (asymptotic):\n"))
  cat(sprintf("  F at 5%%: %d/%d | t at 5%%: %d/%d\n",
      sum(d$F_asy_p < 0.05, na.rm=TRUE), nrow(d),
      sum(d$t_asy_p < 0.05, na.rm=TRUE), nrow(d)))
  cat(sprintf("Rejection counts (exact, R=%d):\n", BOOT_R))
  cat(sprintf("  F at 5%%: %d/%d | t at 5%%: %d/%d\n",
      sum(d$F_exact_p < 0.05, na.rm=TRUE), nrow(d),
      sum(d$t_exact_p < 0.05, na.rm=TRUE), nrow(d)))
}


# ═══════════════════════════════════════════════════════════════════════════════
# FIGURES — Heatmaps: Asymptotic vs Exact, Gross vs Net
# ═══════════════════════════════════════════════════════════════════════════════

theme_rc <- theme_minimal(base_family = "roboto", base_size = 11) +
  theme(
    axis.line = element_line(color = "#AAAAAA", linewidth = 0.4),
    axis.ticks = element_line(color = "#AAAAAA", linewidth = 0.3),
    panel.grid = element_blank(),
    plot.caption = element_text(size = 6.5, color = "#666666"),
    plot.margin = margin(5, 15, 5, 5),
    axis.text = element_text(size = 10)
  )

make_heatmap <- function(df, fill_var, fill_label, caption_text) {
  ggplot(df, aes(x = factor(window_end), y = factor(window_start))) +
    geom_tile(aes(fill = .data[[fill_var]]), color = "white", linewidth = 0.8) +
    geom_text(aes(label = sprintf("%.3f", .data[[fill_var]])),
              size = 3.5, family = "roboto") +
    geom_tile(data = df %>% filter(window_start == 1948, window_end == 1973),
              fill = NA, color = "black", linewidth = 1.2) +
    scale_fill_gradient2(low = "#B2182B", mid = "#FFFFFF", high = "#2166AC",
                         midpoint = 0.05, name = fill_label) +
    scale_y_discrete(limits = rev(as.character(1945:1948))) +
    labs(x = "End year", y = "Start year", caption = caption_text) +
    theme_rc
}

# Gross K — F asymptotic vs exact
save_fig(
  make_heatmap(res_gK, "F_asy_p", "p (asy)",
    "Bounds F p-value (asymptotic) | g_K | Case 3 | 4ch ARDL"),
  "fig_RC_grossK_F_asy_heatmap")

save_fig(
  make_heatmap(res_gK, "F_exact_p", "p (exact)",
    sprintf("Bounds F p-value (exact, R=%d) | g_K | Case 3 | 4ch ARDL", BOOT_R)),
  "fig_RC_grossK_F_exact_heatmap")

# Gross K — t asymptotic vs exact
save_fig(
  make_heatmap(res_gK, "t_asy_p", "p (asy)",
    "Bounds t p-value (asymptotic) | g_K | Case 3"),
  "fig_RC_grossK_t_asy_heatmap")

save_fig(
  make_heatmap(res_gK, "t_exact_p", "p (exact)",
    sprintf("Bounds t p-value (exact, R=%d) | g_K | Case 3", BOOT_R)),
  "fig_RC_grossK_t_exact_heatmap")

# Net K — same 4 heatmaps
save_fig(
  make_heatmap(res_gKn, "F_asy_p", "p (asy)",
    "Bounds F p-value (asymptotic) | g_Kn | Case 3 | 4ch ARDL"),
  "fig_RC_netK_F_asy_heatmap")

save_fig(
  make_heatmap(res_gKn, "F_exact_p", "p (exact)",
    sprintf("Bounds F p-value (exact, R=%d) | g_Kn | Case 3 | 4ch ARDL", BOOT_R)),
  "fig_RC_netK_F_exact_heatmap")

save_fig(
  make_heatmap(res_gKn, "t_asy_p", "p (asy)",
    "Bounds t p-value (asymptotic) | g_Kn | Case 3"),
  "fig_RC_netK_t_asy_heatmap")

save_fig(
  make_heatmap(res_gKn, "t_exact_p", "p (exact)",
    sprintf("Bounds t p-value (exact, R=%d) | g_Kn | Case 3", BOOT_R)),
  "fig_RC_netK_t_exact_heatmap")

# Wald heatmaps (both capital measures)
save_fig(
  make_heatmap(res_gK, "wald_p", "Wald p",
    "Wald H0: beta_mu=beta_PyPK+beta_Br | g_K | Case 3"),
  "fig_RC_grossK_wald_heatmap")

save_fig(
  make_heatmap(res_gKn, "wald_p", "Wald p",
    "Wald H0: beta_mu=beta_PyPK+beta_Br | g_Kn | Case 3"),
  "fig_RC_netK_wald_heatmap")


cat(sprintf("\n%s\nRolling window analysis complete (R=%d).\n", strrep("=", 60), BOOT_R))
cat(sprintf("CSVs: %s\n", csv_dir))
cat(sprintf("Figs: %s\n", fig_dir))
cat(strrep("=", 60), "\n")
