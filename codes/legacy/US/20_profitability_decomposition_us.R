# 20_profitability_decomposition_us.R
# ═══════════════════════════════════════════════════════════════════════════════
# Stage B: Weisskopf Profitability Decomposition — US NF Corporate Sector
#
# Exact decomposition: r = mu * B * pi
#   r  = GOS / KNC          (nominal profit rate)
#   B  = r / (mu * pi)      (capital productivity at normal capacity, from identity)
#   pi = GOS / GVA           (profit share)
#   mu = capacity utilization (pinned, from Stage A)
#
# Log-difference: d(ln r) = phi_mu + phi_B + phi_pi
# ═══════════════════════════════════════════════════════════════════════════════

library(tidyverse)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

fig_dir <- file.path(REPO, "output/stage_b/US/figs")
csv_dir <- file.path(REPO, "output/stage_b/US/csv")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

dual_save <- function(plot, name, w = 10, h = 6, dpi = 300) {
  ggsave(file.path(fig_dir, paste0(name, ".png")),
         plot = plot, width = w, height = h, dpi = dpi)
  ggsave(file.path(fig_dir, paste0(name, ".pdf")),
         plot = plot, width = w, height = h, device = cairo_pdf)
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}


# ═══════════════════════════════════════════════════════════════════════════════
# 0. LOAD DATA
# ═══════════════════════════════════════════════════════════════════════════════

raw <- read_csv(file.path(REPO, "data/processed/us_nf_corporate_stageBC.csv"),
                show_col_types = FALSE)


# ═══════════════════════════════════════════════════════════════════════════════
# 1. CONSTRUCT LEVELS (1940-2024)
# ═══════════════════════════════════════════════════════════════════════════════

df <- raw %>%
  filter(year >= 1940) %>%
  arrange(year) %>%
  mutate(
    r  = GOS / KNC,
    B  = r / (mu * pi),
    r_check = mu * B * pi,
    regime = case_when(
      year <= 1944 ~ "Pre-Fordist",
      year <= 1973 ~ "Fordist",
      TRUE         ~ "Post-Fordist"
    )
  )

# ── Identity check ──────────────────────────────────────────────────────────
id_err <- max(abs(df$r - df$r_check))
cat(sprintf("Weisskopf identity check: max|r - mu*B*pi| = %.2e  %s\n",
    id_err, ifelse(id_err < 1e-10, "PASS", "FAIL")))
stopifnot(id_err < 1e-10)


# ═══════════════════════════════════════════════════════════════════════════════
# 2. ANNUAL LOG-DIFFERENCE CONTRIBUTIONS
# ═══════════════════════════════════════════════════════════════════════════════

df <- df %>%
  mutate(
    dlnr   = c(NA, diff(log(r))),
    phi_mu = c(NA, diff(log(mu))),
    phi_B  = c(NA, diff(log(B))),
    phi_pi = c(NA, diff(log(pi))),
    resid_check = dlnr - (phi_mu + phi_B + phi_pi)
  )

add_err <- max(abs(df$resid_check), na.rm = TRUE)
cat(sprintf("Additivity check: max|dlnr - sum(phi)| = %.2e  %s\n",
    add_err, ifelse(add_err < 1e-10, "PASS", "FAIL")))
stopifnot(add_err < 1e-10)


# ═══════════════════════════════════════════════════════════════════════════════
# 3. STAGNATION TENDENCY CLASSIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

df <- df %>%
  mutate(
    tendency_label = case_when(
      is.na(phi_mu) ~ NA_character_,
      phi_mu < 0 & phi_pi < 0 & phi_B < 0 ~ "reinforcing_crisis",
      phi_mu < 0 & phi_pi < 0 & phi_B > 0 ~ "tech_offset_crisis",
      phi_mu < 0 & phi_pi > 0              ~ "demand_drag",
      phi_mu > 0 & phi_pi < 0              ~ "profit_squeeze",
      phi_mu > 0 & phi_pi > 0 & phi_B < 0  ~ "tech_drag",
      phi_mu > 0 & phi_pi > 0 & phi_B > 0  ~ "broad_expansion",
      TRUE                                  ~ "mixed"
    )
  )

cat("\nTendency counts (1941-2024):\n")
df %>%
  filter(!is.na(tendency_label)) %>%
  count(tendency_label) %>%
  arrange(desc(n)) %>%
  print()


# ═══════════════════════════════════════════════════════════════════════════════
# 4. PEAK-TO-TROUGH IDENTIFICATION (1945-1978)
# ═══════════════════════════════════════════════════════════════════════════════

fordist_window <- df %>% filter(year >= 1945, year <= 1978)

# Local extrema with 3-year neighborhood
find_extrema <- function(x, years, min_swing = 0.05) {
  n <- length(x)
  peaks <- troughs <- integer(0)

  for (i in 3:(n - 2)) {
    # Local max: higher than 2 neighbors on each side
    if (x[i] > x[i-1] & x[i] > x[i+1] &
        x[i] >= x[i-2] & x[i] >= x[i+2]) {
      peaks <- c(peaks, i)
    }
    # Local min
    if (x[i] < x[i-1] & x[i] < x[i+1] &
        x[i] <= x[i-2] & x[i] <= x[i+2]) {
      troughs <- c(troughs, i)
    }
  }

  # Check endpoints
  if (x[1] > x[2] & x[1] > x[3]) peaks <- c(1, peaks)
  if (x[1] < x[2] & x[1] < x[3]) troughs <- c(1, troughs)
  if (x[n] > x[n-1] & x[n] > x[n-2]) peaks <- c(peaks, n)
  if (x[n] < x[n-1] & x[n] < x[n-2]) troughs <- c(troughs, n)

  # Merge all turning points and sort
  tp <- tibble(
    idx  = c(peaks, troughs),
    type = c(rep("peak", length(peaks)), rep("trough", length(troughs)))
  ) %>% arrange(idx)

  # Alternate: ensure peak-trough-peak-... sequence
  if (nrow(tp) > 1) {
    keep <- rep(TRUE, nrow(tp))
    for (i in 2:nrow(tp)) {
      if (tp$type[i] == tp$type[i-1]) {
        # Keep the more extreme one
        if (tp$type[i] == "peak") {
          if (x[tp$idx[i]] > x[tp$idx[i-1]]) keep[i-1] <- FALSE else keep[i] <- FALSE
        } else {
          if (x[tp$idx[i]] < x[tp$idx[i-1]]) keep[i-1] <- FALSE else keep[i] <- FALSE
        }
      }
    }
    tp <- tp[keep, ]
  }

  # Filter by minimum swing magnitude
  if (nrow(tp) > 1) {
    keep <- rep(TRUE, nrow(tp))
    for (i in 2:nrow(tp)) {
      swing <- abs(log(x[tp$idx[i]]) - log(x[tp$idx[i-1]]))
      if (swing < min_swing) keep[i] <- FALSE
    }
    tp <- tp[keep, ]
  }

  tp$year <- years[tp$idx]
  tp$value <- x[tp$idx]
  tp
}

tp <- find_extrema(fordist_window$r, fordist_window$year, min_swing = 0.05)

cat("\n=== TURNING POINTS (profit rate, 1945-1978) ===\n")
cat(sprintf("%-6s %-8s %10s\n", "Year", "Type", "r"))
cat(strrep("-", 28), "\n")
for (i in 1:nrow(tp)) {
  cat(sprintf("%-6d %-8s %10.4f\n", tp$year[i], tp$type[i], tp$value[i]))
}


# ═══════════════════════════════════════════════════════════════════════════════
# 5. COMPOUNDED PEAK-TO-TROUGH CONTRIBUTIONS
# ═══════════════════════════════════════════════════════════════════════════════

swings <- tibble()
if (nrow(tp) > 1) {
  for (i in 1:(nrow(tp) - 1)) {
    t0 <- tp$year[i]; t1 <- tp$year[i + 1]
    window <- df %>% filter(year > t0, year <= t1)

    sum_mu <- sum(window$phi_mu)
    sum_B  <- sum(window$phi_B)
    sum_pi <- sum(window$phi_pi)
    delta  <- sum_mu + sum_B + sum_pi

    swing_type <- ifelse(delta > 0, "expansion", "contraction")

    s_mu <- sum_mu / delta
    s_B  <- sum_B / delta
    s_pi <- sum_pi / delta

    # Direction: drag if sign matches delta, offset if opposite
    dir_mu <- ifelse(sign(sum_mu) == sign(delta), "drag", "offset")
    dir_B  <- ifelse(sign(sum_B) == sign(delta), "drag", "offset")
    dir_pi <- ifelse(sign(sum_pi) == sign(delta), "drag", "offset")
    # For contractions: "drag" means contributing to decline
    # For expansions: "drag" means contributing to rise

    # Basu cell
    basu <- case_when(
      sum_mu < 0 & sum_pi < 0 ~ "reinforcing_squeeze",
      sum_mu < 0 & sum_pi > 0 ~ "demand_drag",
      sum_mu > 0 & sum_pi < 0 ~ "profit_squeeze",
      sum_mu > 0 & sum_pi > 0 ~ "broad_expansion",
      TRUE ~ "mixed"
    )

    swings <- bind_rows(swings, tibble(
      swing_id = i, t0 = t0, t1 = t1,
      type = swing_type, delta_lnr = delta,
      sum_phi_mu = sum_mu, sum_phi_B = sum_B, sum_phi_pi = sum_pi,
      s_mu = s_mu, s_B = s_B, s_pi = s_pi,
      dir_mu = dir_mu, dir_B = dir_B, dir_pi = dir_pi,
      basu_cell = basu
    ))
  }
}

# Shares closure check
if (nrow(swings) > 0) {
  share_err <- max(abs(swings$s_mu + swings$s_B + swings$s_pi - 1))
  cat(sprintf("\nShares closure: max|s_mu+s_B+s_pi-1| = %.2e  %s\n",
      share_err, ifelse(share_err < 1e-10, "PASS", "FAIL")))
}

cat("\n=== COMPOUNDED PEAK-TO-TROUGH DECOMPOSITION ===\n")
cat(sprintf("%-3s %5s %5s %-12s %+8s | %+7s %+7s %+7s | %6s %6s %6s | %s\n",
    "id", "t0", "t1", "type", "d_lnr",
    "mu", "B", "pi",
    "s_mu", "s_B", "s_pi", "basu"))
cat(strrep("-", 95), "\n")
for (i in 1:nrow(swings)) {
  s <- swings[i, ]
  cat(sprintf("%-3d %5d %5d %-12s %+8.4f | %+7.4f %+7.4f %+7.4f | %6.3f %6.3f %6.3f | %s\n",
      s$swing_id, s$t0, s$t1, s$type, s$delta_lnr,
      s$sum_phi_mu, s$sum_phi_B, s$sum_phi_pi,
      s$s_mu, s$s_B, s$s_pi, s$basu_cell))
}


# ═══════════════════════════════════════════════════════════════════════════════
# 6. SUB-PERIOD AVERAGES
# ═══════════════════════════════════════════════════════════════════════════════

subperiods <- tribble(
  ~period_label,         ~y0,  ~y1,
  "Pre-Fordist/WWII",   1940, 1944,
  "Early Fordist",       1945, 1966,
  "Late Fordist",        1967, 1973,
  "Post-Fordist onset",  1974, 1978,
  "Post-Fordist full",   1974, 2024
)

sub_avgs <- subperiods %>%
  rowwise() %>%
  mutate(
    data = list(df %>% filter(year >= y0, year <= y1))
  ) %>%
  mutate(
    years   = sprintf("%d-%d", y0, y1),
    n       = nrow(data),
    mean_r  = mean(data$r),
    mean_mu = mean(data$mu),
    mean_B  = mean(data$B),
    mean_pi = mean(data$pi),
    mean_theta = mean(data$theta)
  ) %>%
  select(-data, -y0, -y1) %>%
  ungroup()

cat("\n=== SUB-PERIOD AVERAGES ===\n")
print(sub_avgs)


# ═══════════════════════════════════════════════════════════════════════════════
# 7. SAVE TABLES
# ═══════════════════════════════════════════════════════════════════════════════

# Table B1 — Annual contributions (full 1940-2024)
tbl_b1 <- df %>%
  select(year, r, mu, B, pi, dlnr, phi_mu, phi_B, phi_pi, regime, tendency_label)
write_csv(tbl_b1, file.path(csv_dir, "stageB_US_table_B1_annual_contributions.csv"))

# Table B2 — Peak-to-trough decomposition
write_csv(swings, file.path(csv_dir, "stageB_US_table_B2_peaktotrough.csv"))

# Table B3 — Sub-period averages
write_csv(sub_avgs, file.path(csv_dir, "stageB_US_table_B3_subperiod_averages.csv"))

cat("\nTables saved.\n")


# ═══════════════════════════════════════════════════════════════════════════════
# 8. FIGURES
# ═══════════════════════════════════════════════════════════════════════════════

theme_pub <- theme_minimal(base_size = 10) +
  theme(
    panel.grid.minor   = element_blank(),
    panel.grid.major   = element_line(color = "grey93", linewidth = 0.3),
    strip.text         = element_text(size = 9, face = "bold"),
    legend.position    = "bottom",
    legend.key.size    = unit(0.35, "cm"),
    legend.text        = element_text(size = 8),
    plot.caption       = element_text(size = 6, color = "grey50"),
    axis.title         = element_text(size = 9),
    axis.text          = element_text(size = 8),
    plot.margin        = margin(8, 12, 8, 8)
  )

regime_colors <- c(
  "Pre-Fordist" = "grey55",
  "Fordist"     = "steelblue",
  "Post-Fordist" = "darkorange"
)

fordist_lines <- list(
  geom_vline(xintercept = 1945, linetype = "dashed", color = "grey60", linewidth = 0.3),
  geom_vline(xintercept = 1973, linetype = "dashed", color = "grey60", linewidth = 0.3)
)

# ── Filter for Fordist-focus figures (1940-1978) ────────────────────────────
df_focus <- df %>% filter(year >= 1940, year <= 1978)

# ── Figure B1: Four-panel levels ────────────────────────────────────────────
panel_data <- df_focus %>%
  select(year, r, mu, B, pi, regime) %>%
  pivot_longer(cols = c(r, mu, B, pi),
               names_to = "variable", values_to = "value") %>%
  mutate(
    variable = factor(variable,
      levels = c("r", "mu", "B", "pi"),
      labels = c("r (profit rate)", "mu (capacity utilization)",
                 "B (capital productivity)", "pi (profit share)"))
  )

fig_b1 <- ggplot(panel_data, aes(x = year, y = value)) +
  geom_line(aes(color = regime), linewidth = 0.6) +
  fordist_lines +
  facet_wrap(~ variable, scales = "free_y", ncol = 2) +
  scale_color_manual(values = regime_colors) +
  labs(x = NULL, y = NULL, color = NULL,
       caption = "US NF Corporate Sector, 1940-1978 | r = GOS/KNC | B = r/(mu*pi) | mu from Stage A (pinned)") +
  theme_pub

dual_save(fig_b1, "stageB_US_fig_B1_levels_panel", w = 10, h = 7)


# ── Figure B2: Annual stacked bar contributions ─────────────────────────────
bar_data <- df_focus %>%
  filter(!is.na(dlnr)) %>%
  select(year, phi_mu, phi_B, phi_pi, dlnr) %>%
  pivot_longer(cols = c(phi_mu, phi_B, phi_pi),
               names_to = "channel", values_to = "contribution") %>%
  mutate(
    channel = factor(channel,
      levels = c("phi_mu", "phi_B", "phi_pi"),
      labels = c("mu (demand)", "B (technology)", "pi (distribution)"))
  )

line_data <- df_focus %>% filter(!is.na(dlnr)) %>% select(year, dlnr)

channel_colors <- c(
  "mu (demand)"       = "steelblue",
  "B (technology)"    = "seagreen",
  "pi (distribution)" = "firebrick"
)

fig_b2 <- ggplot() +
  geom_col(data = bar_data,
           aes(x = year, y = contribution, fill = channel),
           width = 0.7, position = "stack") +
  geom_line(data = line_data,
            aes(x = year, y = dlnr),
            linewidth = 0.6, color = "black") +
  geom_point(data = line_data,
             aes(x = year, y = dlnr),
             size = 0.8, color = "black") +
  geom_hline(yintercept = 0, linewidth = 0.3) +
  fordist_lines +
  scale_fill_manual(values = channel_colors) +
  labs(x = NULL, y = expression(Delta * ln),
       fill = NULL,
       caption = "US NF Corporate 1941-1978 | Bars: phi_mu + phi_B + phi_pi = d(ln r) (black line)") +
  theme_pub

dual_save(fig_b2, "stageB_US_fig_B2_annual_contributions", w = 11, h = 5.5)


# ── Figure B3: Compounded contributions by swing ────────────────────────────
if (nrow(swings) > 0) {
  swing_bar <- swings %>%
    mutate(label = sprintf("%d-%d (%s)", t0, t1, type)) %>%
    select(label, swing_id, delta_lnr, sum_phi_mu, sum_phi_B, sum_phi_pi) %>%
    pivot_longer(cols = c(sum_phi_mu, sum_phi_B, sum_phi_pi),
                 names_to = "channel", values_to = "contribution") %>%
    mutate(
      channel = factor(channel,
        levels = c("sum_phi_mu", "sum_phi_B", "sum_phi_pi"),
        labels = c("mu (demand)", "B (technology)", "pi (distribution)")),
      label = fct_reorder(label, swing_id)
    )

  fig_b3 <- ggplot(swing_bar, aes(x = contribution, y = label, fill = channel)) +
    geom_col(position = "dodge", width = 0.7) +
    geom_vline(xintercept = 0, linewidth = 0.3) +
    scale_fill_manual(values = channel_colors) +
    labs(x = expression(Sigma * phi), y = NULL, fill = NULL,
         caption = "US NF Corporate | Compounded log-contributions per swing") +
    theme_pub

  dual_save(fig_b3, "stageB_US_fig_B3_swing_decomposition", w = 10, h = max(4, nrow(swings) * 0.8 + 2))
}


# ── Figure B4: Profit rate with turning points ──────────────────────────────
tp_df <- tp %>% select(year, type, value)

fig_b4 <- ggplot(df_focus, aes(x = year, y = r)) +
  geom_line(aes(color = regime), linewidth = 0.6) +
  geom_point(data = tp_df %>% filter(type == "peak"),
             aes(x = year, y = value),
             shape = 24, size = 2.5, fill = "firebrick", color = "firebrick") +
  geom_point(data = tp_df %>% filter(type == "trough"),
             aes(x = year, y = value),
             shape = 25, size = 2.5, fill = "steelblue", color = "steelblue") +
  geom_text(data = tp_df,
            aes(x = year, y = value, label = year),
            size = 2.5, vjust = ifelse(tp_df$type == "peak", -1.2, 1.8),
            color = "grey30") +
  fordist_lines +
  geom_hline(yintercept = 0, linewidth = 0.2) +
  scale_color_manual(values = regime_colors) +
  labs(x = NULL, y = expression(r[t] == GOS[t] / KNC[t]),
       color = NULL,
       caption = "US NF Corporate 1940-1978 | Triangles: turning points on r") +
  theme_pub

dual_save(fig_b4, "stageB_US_fig_B4_profit_rate_turning_points", w = 10, h = 5.5)


# ═══════════════════════════════════════════════════════════════════════════════
# 9. ROBUSTNESS: mu_ect vs mu (1941-1978)
# ═══════════════════════════════════════════════════════════════════════════════

df_rob <- raw %>%
  filter(year >= 1940, year <= 1978) %>%
  arrange(year) %>%
  mutate(
    r      = GOS / KNC,
    B_pin  = r / (mu * pi),
    B_ect  = r / (mu_ect * pi),
    phi_mu_pinned = c(NA, diff(log(mu))),
    phi_mu_ect    = c(NA, diff(log(mu_ect))),
    phi_B_pinned  = c(NA, diff(log(B_pin))),
    phi_B_ect     = c(NA, diff(log(B_ect)))
  ) %>%
  filter(year >= 1941) %>%
  select(year, phi_mu_pinned, phi_mu_ect, phi_B_pinned, phi_B_ect)

write_csv(df_rob, file.path(csv_dir, "stageB_US_table_B_robustness_mu_comparison.csv"))
cat("Saved: robustness table\n")


# ═══════════════════════════════════════════════════════════════════════════════
# 10. FINAL CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n=== FINAL VALIDATION ===\n")

# No NAs in 1941-1978
fordist_check <- df %>% filter(year >= 1941, year <= 1978)
na_vars <- c("r","mu","B","pi","dlnr","phi_mu","phi_B","phi_pi")
na_count <- sum(is.na(fordist_check[, na_vars]))
cat(sprintf("NAs in 1941-1978 window: %d  %s\n", na_count,
    ifelse(na_count == 0, "PASS", "FAIL")))

# Spot-check 1966 and 1973
for (yr in c(1966, 1973)) {
  row <- df %>% filter(year == yr)
  bar_sum <- row$phi_mu + row$phi_B + row$phi_pi
  cat(sprintf("Spot-check %d: dlnr=%.6f  sum(phi)=%.6f  diff=%.2e  %s\n",
      yr, row$dlnr, bar_sum, abs(row$dlnr - bar_sum),
      ifelse(abs(row$dlnr - bar_sum) < 1e-10, "PASS", "FAIL")))
}

cat("\nStage B complete.\n")
