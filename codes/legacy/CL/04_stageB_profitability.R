# 04_stageB_profitability.R
# Chile Stage B — Weisskopf Profitability Decomposition
# r_t = mu_CL_t * B_t * pi_t
# Window: 1940–1978 (N=39)
# Authority: Ch2_Outline_DEFINITIVE.md | Notation: CLAUDE.md

library(tidyverse)
library(scales)

REPO    <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
setwd(REPO)
CSV_IN  <- file.path(REPO, "output/stage_a/Chile/csv")
CSV_OUT <- file.path(REPO, "output/stage_b/Chile/csv")
FIG_OUT <- file.path(REPO, "output/stage_b/Chile/figs")
dir.create(CSV_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(FIG_OUT, recursive = TRUE, showWarnings = FALSE)


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 0 — LOAD AND CONSTRUCT STAGE B VARIABLES                          ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 0 — LOAD AND CONSTRUCT STAGE B VARIABLES\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

panel <- read_csv(file.path(CSV_IN, "stage2_panel_with_mu_v2.csv"),
                  show_col_types = FALSE)

# Merge P_Y from the TVECM panel (GDP deflator, 2003=100)
tvecm <- read_csv(file.path(REPO, "data/final/chile_tvecm_panel.csv"),
                  show_col_types = FALSE) %>%
  select(year, p_Y)

# Merge P_K from K-Stock-Harmonization (capital goods deflator, 2003=100)
pk <- read_csv("C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_pk_2003base_1940_2024.csv",
               show_col_types = FALSE) %>%
  select(year, P_K = Pk_2003base)

panel <- panel %>%
  left_join(tvecm, by = "year") %>%
  left_join(pk,    by = "year") %>%
  mutate(
    p_rel = p_Y / P_K   # relative price of output to capital (P_Y / P_K)
  )

cat(sprintf("P_Y available: %d obs | P_K available: %d obs\n",
    sum(!is.na(panel$p_Y)), sum(!is.na(panel$P_K))))

cat("Panel columns:\n")
cat(names(panel), sep = ", ")
cat("\n\n")

# ── Construct Stage B variables ──────────────────────────────────────────
# Profit rate on current-cost capital:
#   r = Profits / K_cc = (Y * pi) / (K_real * P_K / P_Y)
#     = mu * (Y^p / K_real) * (P_Y / P_K) * pi
#     = mu * B_real * p_rel * pi
#
# We define B_t = B_real * p_rel = Y^p / K_cc
# where K_cc = K_real * (P_K / P_Y) is capital in output-price units.
# In logs: ln_B = (y - ln_mu) - k_CL + ln(P_Y/P_K) = y_p_log - k_CL + ln(p_rel)
#
# This is the Weisskopf (1979) specification: the profit rate is on
# capital valued at current cost, with the relative price p = P_Y/P_K
# capturing the terms-of-trade between output and capital goods.

df_b <- panel %>%
  arrange(year) %>%
  mutate(
    pi_t     = 1 - omega,
    y_p_log  = y - log(mu_CL),
    ln_p_rel = log(p_rel),
    ln_B     = y_p_log - k_CL + ln_p_rel,  # B = Y^p * p_rel / K_real
    B_t      = exp(ln_B),
    r_t      = mu_CL * B_t * pi_t,
    ln_r     = log(r_t),
    ln_mu    = log(mu_CL),
    ln_pi    = log(pi_t)
  ) %>%
  filter(year >= 1940, year <= 1978)

cat(sprintf("Stage B panel: N=%d (1940–1978)\n", nrow(df_b)))
cat(sprintf("p_rel range: [%.4f, %.4f]  (P_Y/P_K, 1.0 = equal price growth)\n",
    min(df_b$p_rel), max(df_b$p_rel)))
cat(sprintf("r_t:   mean=%.4f, range=[%.4f, %.4f]\n",
    mean(df_b$r_t), min(df_b$r_t), max(df_b$r_t)))
cat(sprintf("mu_CL: mean=%.4f, range=[%.4f, %.4f]\n",
    mean(df_b$mu_CL), min(df_b$mu_CL), max(df_b$mu_CL)))
cat(sprintf("B_t:   mean=%.4f, range=[%.4f, %.4f]\n",
    mean(df_b$B_t), min(df_b$B_t), max(df_b$B_t)))
cat(sprintf("pi_t:  mean=%.4f, range=[%.4f, %.4f]\n",
    mean(df_b$pi_t), min(df_b$pi_t), max(df_b$pi_t)))

cat(sprintf("\nIdentity check (max deviation): %.8f\n",
    max(abs(df_b$r_t - df_b$mu_CL * df_b$B_t * df_b$pi_t))))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 1 — PRINT r_t SERIES AND IDENTIFY TURNING POINTS                  ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 1 — PROFIT RATE SERIES (PAUSE FOR REVIEW)\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

cat("Profit rate series 1940–1978:\n")
df_b %>%
  select(year, r_t, mu_CL, B_t, pi_t) %>%
  mutate(across(where(is.numeric), ~ round(., 4))) %>%
  print(n = 39)

# Growth rates for turning point identification
df_b <- df_b %>%
  mutate(
    g_r  = c(NA, diff(ln_r)),
    g_mu = c(NA, diff(ln_mu)),
    g_B  = c(NA, diff(ln_B)),
    g_pi = c(NA, diff(ln_pi))
  )

df_b <- df_b %>%
  mutate(decomp_check = g_mu + g_B + g_pi - g_r)
cat(sprintf("\nLog decomposition check (max |residual|): %.8f\n",
    max(abs(df_b$decomp_check), na.rm = TRUE)))

cat("\nGrowth rate decomposition 1940–1978:\n")
df_b %>%
  select(year, g_r, g_mu, g_B, g_pi) %>%
  mutate(across(where(is.numeric), ~ round(., 4))) %>%
  print(n = 39)

# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 2 — SUB-PERIOD AVERAGES TABLE                                     ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 2 — SUB-PERIOD AVERAGES\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

subperiods <- list(
  "WWII          (1940-1945)" = c(1940, 1945),
  "Cold War ISI  (1946-1953)" = c(1946, 1953),
  "Mid ISI       (1954-1961)" = c(1954, 1961),
  "Late ISI      (1962-1972)" = c(1962, 1972),
  "Crash         (1973-1975)" = c(1973, 1975),
  "Auth Restor   (1976-1978)" = c(1976, 1978)
)

tab_subperiod <- purrr::map_dfr(names(subperiods), function(nm) {
  yr  <- subperiods[[nm]]
  idx <- df_b$year >= yr[1] & df_b$year <= yr[2]
  tibble(
    period  = nm,
    n       = sum(idx),
    r_mean  = mean(df_b$r_t[idx],   na.rm = TRUE),
    mu_mean = mean(df_b$mu_CL[idx], na.rm = TRUE),
    B_mean  = mean(df_b$B_t[idx],   na.rm = TRUE),
    pi_mean = mean(df_b$pi_t[idx],  na.rm = TRUE)
  )
})

cat("=== Sub-Period Averages: Chile Profitability 1940–1978 ===\n")
print(tab_subperiod)
write_csv(tab_subperiod, file.path(CSV_OUT, "stageB_CL_subperiod_averages.csv"))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 3 — SWING-LEVEL DECOMPOSITION (CONFIRMED TURNING POINTS)          ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 3 — SWING-LEVEL DECOMPOSITION\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

swings <- list(
  list(label = "1940-1946 (expansion)",          start = 1940, end = 1946),
  list(label = "1946-1947 (sharp contraction)",   start = 1946, end = 1947),
  list(label = "1947-1953 (expansion)",           start = 1947, end = 1953),
  list(label = "1953-1961 (secular decline)",     start = 1953, end = 1961),
  list(label = "1961-1969 (recovery)",            start = 1961, end = 1969),
  list(label = "1969-1972 (Allende squeeze)",     start = 1969, end = 1972),
  list(label = "1972-1974 (coup reversal)",       start = 1972, end = 1974),
  list(label = "1974-1975 (shock therapy crash)", start = 1974, end = 1975),
  list(label = "1975-1978 (recovery)",            start = 1975, end = 1978)
)

tab_swings <- purrr::map_dfr(swings, function(sw) {
  s_idx <- which(df_b$year == sw$start)
  e_idx <- which(df_b$year == sw$end)
  if (length(s_idx) == 0 || length(e_idx) == 0) return(NULL)

  delta_ln_r  <- df_b$ln_r[e_idx]  - df_b$ln_r[s_idx]
  delta_ln_mu <- df_b$ln_mu[e_idx] - df_b$ln_mu[s_idx]
  delta_ln_B  <- df_b$ln_B[e_idx]  - df_b$ln_B[s_idx]
  delta_ln_pi <- df_b$ln_pi[e_idx] - df_b$ln_pi[s_idx]

  s_mu <- delta_ln_mu / delta_ln_r
  s_B  <- delta_ln_B  / delta_ln_r
  s_pi <- delta_ln_pi / delta_ln_r

  tibble(
    swing       = sw$label,
    type        = ifelse(delta_ln_r > 0, "expansion", "contraction"),
    delta_ln_r  = delta_ln_r,
    share_mu    = s_mu,
    share_B     = s_B,
    share_pi    = s_pi,
    check_sum   = s_mu + s_B + s_pi
  )
})

cat("=== Swing-Level Decomposition ===\n")
print(tab_swings)

# Dominant channel per swing
tab_swings <- tab_swings %>%
  rowwise() %>%
  mutate(
    dominant = case_when(
      abs(share_mu) == max(abs(share_mu), abs(share_B), abs(share_pi)) ~ "mu (demand)",
      abs(share_B)  == max(abs(share_mu), abs(share_B), abs(share_pi)) ~ "B (technology)",
      TRUE ~ "pi (distribution)"
    )
  ) %>%
  ungroup()

cat("\nDominant channel by swing:\n")
print(tab_swings %>% select(swing, type, delta_ln_r, dominant))

write_csv(tab_swings, file.path(CSV_OUT, "stageB_CL_swing_decomposition.csv"))


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 4 — FIGURES                                                       ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 4 — FIGURES\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

# --- Figure B1: Profit rate with turning points ---
tp_years <- c(1946, 1947, 1953, 1961, 1969, 1972, 1974, 1975)

fig_B1 <- ggplot(df_b, aes(x = year, y = r_t)) +
  geom_line(linewidth = 0.8, color = "#2171b5") +
  geom_point(size = 1.5, color = "#2171b5") +
  geom_vline(xintercept = tp_years,
             linetype = "dashed", color = "grey50", linewidth = 0.4) +
  annotate("rect", xmin = 1940, xmax = 1946, ymin = -Inf, ymax = Inf,
           fill = "#6baed6", alpha = 0.08) +
  annotate("rect", xmin = 1972, xmax = 1978, ymin = -Inf, ymax = Inf,
           fill = "#cb181d", alpha = 0.08) +
  scale_x_continuous(breaks = seq(1940, 1978, 5)) +
  labs(
    title    = "Profit Rate, Chile 1940\u20131978",
    subtitle = expression(r[t]^{CL}~"="~hat(mu)[t]^{CL}~"\u00b7"~hat(B)[t]^{CL}~"\u00b7"~pi[t]^{CL}),
    x = NULL, y = expression(r[t]^{CL})
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(FIG_OUT, "figB1_CL_profit_rate.pdf"), fig_B1,
       width = 8, height = 4, device = cairo_pdf)
ggsave(file.path(FIG_OUT, "figB1_CL_profit_rate.png"), fig_B1,
       width = 8, height = 4, dpi = 300)
cat("Figure B1 saved.\n")

# --- Figure B2: Offsetting trajectories (indexed 1947=100) ---
df_indexed <- df_b %>%
  filter(year >= 1940) %>%
  mutate(
    mu_idx = mu_CL / mu_CL[year == 1947] * 100,
    B_idx  = B_t   / B_t[year == 1947]   * 100,
    pi_idx = pi_t  / pi_t[year == 1947]  * 100
  )

fig_B2 <- ggplot(df_indexed, aes(x = year)) +
  geom_line(aes(y = mu_idx, color = "mu (demand)"),      linewidth = 0.8) +
  geom_line(aes(y = B_idx,  color = "B (technology)"),   linewidth = 0.8) +
  geom_line(aes(y = pi_idx, color = "pi (distribution)"), linewidth = 0.8,
            linetype = "dashed") +
  geom_hline(yintercept = 100, linetype = "dotted", color = "grey50") +
  scale_color_manual(values = c(
    "mu (demand)"       = "#2171b5",
    "B (technology)"    = "#cb181d",
    "pi (distribution)" = "#41ab5d"
  )) +
  scale_x_continuous(breaks = seq(1940, 1978, 5)) +
  labs(
    title    = "Profitability Channels, Chile 1940\u20131978 (indexed 1947=100)",
    subtitle = "Offsetting trajectories of the ISI compensation mechanism",
    x = NULL, y = "Index (1947=100)", color = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom")

ggsave(file.path(FIG_OUT, "figB2_CL_channels_indexed.pdf"), fig_B2,
       width = 8, height = 4, device = cairo_pdf)
ggsave(file.path(FIG_OUT, "figB2_CL_channels_indexed.png"), fig_B2,
       width = 8, height = 4, dpi = 300)
cat("Figure B2 saved.\n")

# --- Figure B3: Swing composition bar chart ---
tab_swings_long <- tab_swings %>%
  select(swing, type, delta_ln_r, share_mu, share_B, share_pi) %>%
  pivot_longer(cols = c(share_mu, share_B, share_pi),
               names_to = "channel", values_to = "share") %>%
  mutate(
    channel = recode(channel,
      "share_mu" = "mu (demand)",
      "share_B"  = "B (technology)",
      "share_pi" = "pi (distribution)"
    )
  )

fig_B3 <- ggplot(tab_swings_long,
                 aes(x = share * 100, y = fct_rev(swing), fill = channel)) +
  geom_col(position = "stack", alpha = 0.85) +
  geom_vline(xintercept = c(0, 100), linetype = "dotted", color = "grey40") +
  scale_fill_manual(values = c(
    "mu (demand)"       = "#2171b5",
    "B (technology)"    = "#cb181d",
    "pi (distribution)" = "#41ab5d"
  )) +
  scale_x_continuous(labels = function(x) paste0(x, "%")) +
  labs(
    title    = "Channel Composition of Profit-Rate Swings, Chile 1940\u20131978",
    subtitle = "Share of total log swing. Values sum to 100%.",
    x = "Share of total swing (%)", y = NULL, fill = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(),
        legend.position = "bottom")

ggsave(file.path(FIG_OUT, "figB3_CL_swing_composition.pdf"), fig_B3,
       width = 8, height = 5, device = cairo_pdf)
ggsave(file.path(FIG_OUT, "figB3_CL_swing_composition.png"), fig_B3,
       width = 8, height = 5, dpi = 300)
cat("Figure B3 saved.\n")


# ╔════════════════════════════════════════════════════════════════════════════╗
# ║  STEP 5 — SAVE PANEL AND FINAL REPORT                                   ║
# ╚════════════════════════════════════════════════════════════════════════════╝

cat("\n\n")
cat("══════════════════════════════════════════════════════════════════════════\n")
cat("  STEP 5 — SAVE AND REPORT\n")
cat("══════════════════════════════════════════════════════════════════════════\n\n")

write_csv(df_b, file.path(CSV_OUT, "stageB_CL_panel_1940_1978.csv"))
cat("Stage B panel saved.\n")

cat("\n================================================================\n")
cat("  CHILE STAGE B — PROFITABILITY ANALYSIS CROSSWALK\n")
cat("================================================================\n")
cat(sprintf("Window:      1940–1978 (N=%d)\n", nrow(df_b)))
cat(sprintf("Identity:    r = mu * B * pi (max deviation: %.2e)\n",
    max(abs(df_b$r_t - df_b$mu_CL * df_b$B_t * df_b$pi_t))))

cat("\n--- Sub-period profit rate means ---\n")
for (i in 1:nrow(tab_subperiod)) {
  cat(sprintf("  %-30s r=%.4f  mu=%.4f  B=%.4f  pi=%.4f\n",
      tab_subperiod$period[i], tab_subperiod$r_mean[i],
      tab_subperiod$mu_mean[i], tab_subperiod$B_mean[i],
      tab_subperiod$pi_mean[i]))
}

cat("\n--- Swing dominant channels ---\n")
for (i in 1:nrow(tab_swings)) {
  cat(sprintf("  %-40s %12s  dlnr=%+.3f  %s\n",
      tab_swings$swing[i], tab_swings$type[i],
      tab_swings$delta_ln_r[i], tab_swings$dominant[i]))
}

cat("\n--- Outputs ---\n")
for (f in c("stageB_CL_panel_1940_1978.csv",
            "stageB_CL_subperiod_averages.csv",
            "stageB_CL_swing_decomposition.csv",
            "figB1_CL_profit_rate.pdf",
            "figB1_CL_profit_rate.png",
            "figB2_CL_channels_indexed.pdf",
            "figB2_CL_channels_indexed.png",
            "figB3_CL_swing_composition.pdf",
            "figB3_CL_swing_composition.png")) {
  cat(sprintf("  %s\n", f))
}
cat("================================================================\n")
