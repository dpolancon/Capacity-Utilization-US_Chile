# 20_profitability_decomposition_us_v2.R
# ═══════════════════════════════════════════════════════════════════════════════
# Stage B v2: Weisskopf Profitability Decomposition — US NF Corporate Sector
# 4-channel decomposition: mu, Py/PK, B_real, pi
#
# r = mu * B * pi   where   B = (Py/PK) * B_real
# d(ln r) = phi_mu + phi_PyPK + phi_Br + phi_pi  (exact)
# ═══════════════════════════════════════════════════════════════════════════════

library(tidyverse)
library(showtext)
library(ggrepel)

font_add_google("Roboto Condensed", "roboto")
showtext_auto()

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

fig_dir <- file.path(REPO, "output/stage_b/US/figs")
csv_dir <- file.path(REPO, "output/stage_b/US/csv")
dir.create(fig_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(csv_dir, recursive = TRUE, showWarnings = FALSE)

dual_save <- function(plot, name, w = 10, h = 6.5, dpi = 300) {
  ggsave(file.path(fig_dir, paste0(name, ".png")),
         plot = plot, width = w, height = h, dpi = dpi)
  ggsave(file.path(fig_dir, paste0(name, ".pdf")),
         plot = plot, width = w, height = h, device = cairo_pdf)
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}

# ── Color palettes — Okabe-Ito (colorblind accessible) ──────────────────────
ch_colors <- c(
  "\u03bc (demand)"          = "#0072B2",
  "Py/PK (rel. price)"      = "#CC79A7",
  "B_real (technology)"      = "#009E73",
  "\u03c0 (distribution)"   = "#D55E00"
)

regime_colors <- c(
  "Pre-Fordist"  = "#999999",
  "Fordist"      = "#0072B2",
  "Post-Fordist" = "#D55E00"
)

# ── Regime annotation bands (replaces geom_vline) ──────────────────────────
regime_bands <- tibble(
  xmin  = c(1940, 1947, 1974),
  xmax  = c(1946, 1973, 1978),
  label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
  fill  = c("#F5F5F5", "#EBF5FB", "#FEF9E7")
)



# ═══════════════════════════════════════════════════════════════════════════════
# 0. LOAD DATA
# ═══════════════════════════════════════════════════════════════════════════════

df_raw <- read_csv(file.path(REPO, "data/processed/us_nf_corporate_stageBC.csv"),
                   show_col_types = FALSE)

df <- df_raw %>%
  filter(year >= 1939) %>%
  arrange(year)

cat(sprintf("Loaded: %d obs (%d-%d)\n", nrow(df), min(df$year), max(df$year)))


# ═══════════════════════════════════════════════════════════════════════════════
# 1. CONSTRUCT LEVELS
# ═══════════════════════════════════════════════════════════════════════════════

df <- df %>%
  mutate(
    r      = GOS / KNC,
    B      = r / (mu * pi),
    PyPK   = Py / pK,
    # B_real derived from identity: B = (Py/pK) * B_real => B_real = B * (pK/Py)
    # This ensures exact closure regardless of the pi definition
    B_real = B * (pK / Py),
    regime = case_when(
      year <= 1944 ~ "Pre-Fordist",
      year <= 1973 ~ "Fordist",
      TRUE         ~ "Post-Fordist"
    )
  )

# Identity checks
id1 <- max(abs(df$mu * df$B * df$pi - df$r))
id2 <- max(abs(df$B - df$PyPK * df$B_real))
cat(sprintf("Identity 1 (r = mu*B*pi):       max err = %.2e  %s\n", id1, ifelse(id1 < 1e-10, "PASS", "FAIL")))
cat(sprintf("Identity 2 (B = PyPK*B_real):    max err = %.2e  %s\n", id2, ifelse(id2 < 1e-10, "PASS", "FAIL")))
stopifnot(id1 < 1e-10, id2 < 1e-10)


# ═══════════════════════════════════════════════════════════════════════════════
# 2. FOUR-CHANNEL LOG-DIFFERENCE DECOMPOSITION
# ═══════════════════════════════════════════════════════════════════════════════

df <- df %>%
  mutate(
    dlnr     = c(NA, diff(log(r))),
    phi_mu   = c(NA, diff(log(mu))),
    phi_PyPK = c(NA, diff(log(PyPK))),
    phi_Br   = c(NA, diff(log(B_real))),
    phi_pi   = c(NA, diff(log(pi))),
    resid_4ch = dlnr - (phi_mu + phi_PyPK + phi_Br + phi_pi)
  )

id3 <- max(abs(df$resid_4ch), na.rm = TRUE)
cat(sprintf("Identity 3 (4-ch additivity):   max err = %.2e  %s\n", id3, ifelse(id3 < 1e-10, "PASS", "FAIL")))
stopifnot(id3 < 1e-10)

# Sub-decomposition check: phi_PyPK + phi_Br = phi_B (original 3-channel)
phi_B_orig <- c(NA, diff(log(df$B)))
id4 <- max(abs(df$phi_PyPK + df$phi_Br - phi_B_orig), na.rm = TRUE)
cat(sprintf("Identity 4 (B sub-decomp):      max err = %.2e  %s\n", id4, ifelse(id4 < 1e-10, "PASS", "FAIL")))
stopifnot(id4 < 1e-10)

# Drop 1939 (used only for differencing)
df <- df %>% filter(year >= 1940)

# Positivity check
stopifnot(all(df$PyPK > 0), all(df$B_real > 0))
cat("Positivity check (PyPK, B_real > 0): PASS\n")


# ═══════════════════════════════════════════════════════════════════════════════
# 3. TENDENCY CLASSIFICATION
# ═══════════════════════════════════════════════════════════════════════════════

df <- df %>%
  mutate(
    tendency_label = case_when(
      is.na(phi_mu) ~ NA_character_,
      phi_mu < 0 & phi_pi < 0 ~ "reinforcing_crisis",
      phi_mu < 0 & phi_pi > 0 ~ "demand_drag",
      phi_mu > 0 & phi_pi < 0 ~ "profit_squeeze",
      phi_mu > 0 & phi_pi > 0 ~ "broad_expansion",
      TRUE ~ "mixed"
    )
  )


# ═══════════════════════════════════════════════════════════════════════════════
# 4. PEAK-TO-TROUGH IDENTIFICATION (1945-1978)
# ═══════════════════════════════════════════════════════════════════════════════

fw <- df %>% filter(year >= 1945, year <= 1978)

find_extrema <- function(x, years, min_swing = 0.05) {
  n <- length(x)
  peaks <- troughs <- integer(0)
  for (i in 3:(n - 2)) {
    if (x[i] > x[i-1] & x[i] > x[i+1] & x[i] >= x[i-2] & x[i] >= x[i+2])
      peaks <- c(peaks, i)
    if (x[i] < x[i-1] & x[i] < x[i+1] & x[i] <= x[i-2] & x[i] <= x[i+2])
      troughs <- c(troughs, i)
  }
  if (x[1] > x[2] & x[1] > x[3]) peaks <- c(1, peaks)
  if (x[1] < x[2] & x[1] < x[3]) troughs <- c(1, troughs)
  if (x[n] > x[n-1] & x[n] > x[n-2]) peaks <- c(peaks, n)
  if (x[n] < x[n-1] & x[n] < x[n-2]) troughs <- c(troughs, n)

  tp <- tibble(idx = c(peaks, troughs),
               type = c(rep("peak", length(peaks)), rep("trough", length(troughs)))) %>%
    arrange(idx)

  # Alternate peaks/troughs
  if (nrow(tp) > 1) {
    keep <- rep(TRUE, nrow(tp))
    for (i in 2:nrow(tp)) {
      if (tp$type[i] == tp$type[i-1]) {
        if (tp$type[i] == "peak") {
          if (x[tp$idx[i]] > x[tp$idx[i-1]]) keep[i-1] <- FALSE else keep[i] <- FALSE
        } else {
          if (x[tp$idx[i]] < x[tp$idx[i-1]]) keep[i-1] <- FALSE else keep[i] <- FALSE
        }
      }
    }
    tp <- tp[keep, ]
  }

  # Minimum swing filter
  if (nrow(tp) > 1) {
    keep <- rep(TRUE, nrow(tp))
    for (i in 2:nrow(tp)) {
      swing <- abs(log(x[tp$idx[i]]) - log(x[tp$idx[i-1]]))
      if (swing < min_swing) keep[i] <- FALSE
    }
    tp <- tp[keep, ]
  }

  tp$year <- years[tp$idx]; tp$value <- x[tp$idx]
  tp
}

tp <- find_extrema(fw$r, fw$year, min_swing = 0.05)

cat("\n=== TURNING POINTS ===\n")
cat(sprintf("%-6s %-8s %10s\n", "Year", "Type", "r"))
for (i in 1:nrow(tp)) cat(sprintf("%-6d %-8s %10.4f\n", tp$year[i], tp$type[i], tp$value[i]))


# ═══════════════════════════════════════════════════════════════════════════════
# 5. COMPOUNDED PEAK-TO-TROUGH (4 CHANNELS)
# ═══════════════════════════════════════════════════════════════════════════════

swings <- tibble()
if (nrow(tp) > 1) {
  for (i in 1:(nrow(tp) - 1)) {
    t0 <- tp$year[i]; t1 <- tp$year[i + 1]
    w <- df %>% filter(year > t0, year <= t1)
    sm <- sum(w$phi_mu); sp <- sum(w$phi_PyPK); sb <- sum(w$phi_Br); spi <- sum(w$phi_pi)
    delta <- sm + sp + sb + spi
    swing_type <- ifelse(delta > 0, "expansion", "contraction")
    swings <- bind_rows(swings, tibble(
      swing_id = i, t0 = t0, t1 = t1, type = swing_type, delta_lnr = delta,
      sum_phi_mu = sm, sum_phi_PyPK = sp, sum_phi_Br = sb, sum_phi_pi = spi,
      s_mu = sm/delta, s_PyPK = sp/delta, s_Br = sb/delta, s_pi = spi/delta,
      dir_mu = ifelse(sign(sm)==sign(delta),"drag","offset"),
      dir_PyPK = ifelse(sign(sp)==sign(delta),"drag","offset"),
      dir_Br = ifelse(sign(sb)==sign(delta),"drag","offset"),
      dir_pi = ifelse(sign(spi)==sign(delta),"drag","offset"),
      dominant_channel = c("mu","PyPK","B_real","pi")[which.max(abs(c(sm,sp,sb,spi)))]
    ))
  }
}

# Shares closure
sh_err <- max(abs(swings$s_mu + swings$s_PyPK + swings$s_Br + swings$s_pi - 1))
cat(sprintf("\nShares closure: %.2e  %s\n", sh_err, ifelse(sh_err < 1e-10, "PASS", "FAIL")))
stopifnot(sh_err < 1e-10)

cat("\n=== SWING DECOMPOSITION (4 channels) ===\n")
cat(sprintf("%-3s %5s %5s %-12s %+7s | %+7s %+7s %+7s %+7s | %s\n",
    "id","t0","t1","type","d_lnr","mu","PyPK","Br","pi","dominant"))
cat(strrep("-", 85), "\n")
for (i in 1:nrow(swings)) {
  s <- swings[i,]
  cat(sprintf("%-3d %5d %5d %-12s %+7.4f | %+7.4f %+7.4f %+7.4f %+7.4f | %s\n",
      s$swing_id, s$t0, s$t1, s$type, s$delta_lnr,
      s$sum_phi_mu, s$sum_phi_PyPK, s$sum_phi_Br, s$sum_phi_pi, s$dominant_channel))
}


# ═══════════════════════════════════════════════════════════════════════════════
# 6. SUB-PERIOD AVERAGES
# ═══════════════════════════════════════════════════════════════════════════════

subperiods <- tribble(
  ~period_label,        ~y0,  ~y1,
  "Pre-Fordist/WWII",  1940, 1944,
  "Early Fordist",      1945, 1966,
  "Late Fordist",       1967, 1973,
  "Post-Fordist onset", 1974, 1978,
  "Post-Fordist full",  1974, 2024
)

sub_avgs <- subperiods %>%
  rowwise() %>%
  mutate(data = list(df %>% filter(year >= y0, year <= y1))) %>%
  mutate(
    years = sprintf("%d-%d", y0, y1), n = nrow(data),
    mean_r = mean(data$r), mean_mu = mean(data$mu),
    mean_PyPK = mean(data$PyPK), mean_B_real = mean(data$B_real),
    mean_B = mean(data$B), mean_pi = mean(data$pi), mean_theta = mean(data$theta)
  ) %>% select(-data, -y0, -y1) %>% ungroup()

cat("\n=== SUB-PERIOD AVERAGES ===\n")
print(sub_avgs)


# ═══════════════════════════════════════════════════════════════════════════════
# 7. SAVE TABLES
# ═══════════════════════════════════════════════════════════════════════════════

tbl_b1 <- df %>%
  select(year, r, mu, PyPK, B_real, B, pi, dlnr, phi_mu, phi_PyPK, phi_Br, phi_pi,
         regime, tendency_label)
write_csv(tbl_b1, file.path(csv_dir, "stageB_US_table_B1_annual_contributions_v2.csv"))
write_csv(swings, file.path(csv_dir, "stageB_US_table_B2_peaktotrough_v2.csv"))
write_csv(sub_avgs, file.path(csv_dir, "stageB_US_table_B3_subperiod_averages_v2.csv"))
cat("\nTables saved.\n")


# ═══════════════════════════════════════════════════════════════════════════════
# 8. THEME AND FIGURE GLOBALS (Master Prompt Final)
# ═══════════════════════════════════════════════════════════════════════════════

theme_stageB <- theme_minimal(base_family = "roboto", base_size = 13) +
  theme(
    axis.text.x        = element_text(angle = 90, vjust = 0.5,
                                      hjust = 1, size = 8, color = "#333333"),
    axis.text.y        = element_text(size = 10),
    axis.title         = element_text(size = 11),
    axis.line          = element_line(color = "#AAAAAA", linewidth = 0.4),
    axis.ticks         = element_line(color = "#AAAAAA", linewidth = 0.3),
    axis.ticks.length  = unit(0.15, "cm"),
    panel.grid.major.y = element_line(color = "#EEEEEE", linewidth = 0.3),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.text        = element_text(size = 10),
    legend.title       = element_blank(),
    plot.caption       = element_text(size = 7, color = "#666666", hjust = 1),
    plot.margin        = margin(5, 90, 5, 5)
  )
theme_set(theme_stageB)

W <- 12; H <- 6

save_fig <- function(plot, name, w = W, h = H, dpi = 150) {
  ggsave(file.path(fig_dir, paste0(name, ".png")),
         plot = plot, width = w, height = h, dpi = dpi)
  ggsave(file.path(fig_dir, paste0(name, ".pdf")),
         plot = plot, width = w, height = h, device = cairo_pdf)
  cat(sprintf("Saved: %s.png / .pdf\n", name))
}

x_ann <- scale_x_continuous(breaks = 1940:1978, minor_breaks = NULL, labels = 1940:1978)

# Turning-point verticals — primary analytical (dashed, dark)
tp_vlines <- geom_vline(xintercept = tp$year, linetype = "dashed",
                         color = "#666666", linewidth = 0.4)

# Period window annotations — secondary contextual (dotted, light)
period_windows <- list(
  geom_vline(xintercept = 1944, linetype = "dotted", color = "#BBBBBB", linewidth = 0.25),
  geom_vline(xintercept = 1947, linetype = "dotted", color = "#BBBBBB", linewidth = 0.25),
  annotate("text", x = 1942, y = Inf, label = "WWII\nbuildup",
           vjust = 1.8, hjust = 0.5, size = 2.4, color = "#888888",
           fontface = "italic", family = "roboto"),
  annotate("text", x = 1945.5, y = Inf, label = "Interim",
           vjust = 1.8, hjust = 0.5, size = 2.4, color = "#888888",
           fontface = "italic", family = "roboto")
)

df_plot <- df %>% filter(year >= 1940, year <= 1978)

# Index to 1947 = 100
base47 <- df_plot %>% filter(year == 1947)
df_plot <- df_plot %>%
  mutate(
    r_idx      = r / base47$r * 100,
    mu_idx     = mu / base47$mu * 100,
    B_real_idx = B_real / base47$B_real * 100,
    PyPK_idx   = PyPK / base47$PyPK * 100,
    pi_idx     = pi / base47$pi * 100,
    B_idx      = B / base47$B * 100
  )


# ── Helper: B1 level panel ──────────────────────────────────────────────────
make_B1 <- function(df, yvar, caption_var, zoom = NULL) {
  df_labels <- df %>% group_by(regime) %>% slice_max(year, n = 1) %>%
    mutate(y = .data[[yvar]])

  p <- ggplot(df, aes(x = year, y = .data[[yvar]])) +
    # Layer A: regime bands
    geom_rect(data = regime_bands,
      aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
      alpha = 0.40, inherit.aes = FALSE, show.legend = FALSE) +
    scale_fill_identity() +
    # Layer B: period windows (secondary)
    period_windows +
    # Turning points (primary analytical)
    tp_vlines +
    # Regime text
    annotate("text", x = c(1943, 1960, 1976), y = Inf,
      label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
      vjust = 1.4, hjust = 0.5, size = 3, color = "#555555",
      fontface = "italic", family = "roboto") +
    # Data: gray underlay + regime overlay
    geom_line(color = "#CCCCCC", linewidth = 0.5) +
    geom_line(aes(color = regime, group = regime), linewidth = 1.0) +
    scale_color_manual(values = regime_colors) +
    # Reference
    geom_hline(yintercept = 100, linetype = "dashed", color = "#AAAAAA", linewidth = 0.4) +
    # End-of-line labels
    geom_text_repel(data = df_labels, aes(label = regime, color = regime, y = y),
      direction = "y", hjust = 0, nudge_x = 0.4, size = 3.2,
      segment.size = 0.3, show.legend = FALSE) +
    x_ann +
    labs(x = NULL, y = "Index (1947 = 100)",
         caption = sprintf("%s, US NF Corporate 1940-1978, indexed 1947=100.",
                           caption_var)) +
    theme(legend.position = "none")

  if (!is.null(zoom)) p <- p + coord_cartesian(ylim = zoom, clip = "off")
  else p <- p + coord_cartesian(clip = "off")
  p
}


# ═══════════════════════════════════════════════════════════════════════════════
# B1a–B1f — Level panels
# ═══════════════════════════════════════════════════════════════════════════════
save_fig(make_B1(df_plot, "r_idx",      "r = GOS/KNC"),                     "fig_B1a_r_levels")
save_fig(make_B1(df_plot, "mu_idx",     "mu from Stage A MPF (pinned)", zoom = c(75, 130)), "fig_B1b_mu_levels")
save_fig(make_B1(df_plot, "B_real_idx", "B_real = B*(pK/Py)"),              "fig_B1c_Breal_levels")
save_fig(make_B1(df_plot, "PyPK_idx",   "Py/PK = GDP deflator / K deflator"), "fig_B1d_PyPK_levels")
save_fig(make_B1(df_plot, "pi_idx",     "pi = GOS/GVA"),                    "fig_B1e_pi_levels")
save_fig(make_B1(df_plot, "B_idx",      "B = r/(mu*pi)"),                   "fig_B1f_B_levels")


# ═══════════════════════════════════════════════════════════════════════════════
# B2a — Cumulative contributions (ribbon, 1940-1978)
# No regime bands, no period windows per spec
# ═══════════════════════════════════════════════════════════════════════════════

df_cum <- df %>%
  filter(year >= 1940, year <= 1978) %>%
  arrange(year) %>%
  mutate(
    cum_mu   = cumsum(replace_na(phi_mu, 0)),
    cum_PyPK = cumsum(replace_na(phi_PyPK, 0)),
    cum_Br   = cumsum(replace_na(phi_Br, 0)),
    cum_pi   = cumsum(replace_na(phi_pi, 0)),
    cum_r    = cumsum(replace_na(dlnr, 0))
  )

df_cum_long <- df_cum %>%
  select(year, cum_mu, cum_PyPK, cum_Br, cum_pi) %>%
  pivot_longer(cols = starts_with("cum_"), names_to = "channel", values_to = "value") %>%
  mutate(channel = factor(channel,
    levels = c("cum_mu", "cum_PyPK", "cum_Br", "cum_pi"),
    labels = names(ch_colors)))

df_cum_last <- df_cum_long %>% group_by(channel) %>% slice_max(year, n = 1)

fig_B2a <- ggplot(df_cum_long, aes(x = year, fill = channel, group = channel)) +
  geom_ribbon(aes(ymin = pmin(value, 0), ymax = pmax(value, 0)),
              alpha = 0.72, position = "identity") +
  geom_hline(yintercept = 0, color = "#333333", linewidth = 0.6) +
  geom_line(data = df_cum, aes(x = year, y = cum_r),
            color = "black", linewidth = 1.0, inherit.aes = FALSE) +
  annotate("rect", xmin = 1966, xmax = 1970, ymin = -Inf, ymax = Inf,
           fill = "#FFF3E0", alpha = 0.5) +
  annotate("text", x = 1968, y = Inf, label = "Crisis\nonset",
           vjust = 1.4, size = 3, color = "#D95F02", fontface = "italic",
           family = "roboto") +
  geom_text_repel(data = df_cum_last,
    aes(x = year, y = value, label = channel, color = channel),
    direction = "y", hjust = 0, nudge_x = 0.4, size = 3.2,
    segment.size = 0.3, show.legend = FALSE, inherit.aes = FALSE) +
  scale_fill_manual(values = ch_colors) +
  scale_color_manual(values = ch_colors) +
  x_ann +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = expression(Cumulative ~ Delta * ln ~ r),
       caption = "Cumulative log-contributions 1940-1978 (4-channel, exact). Black line: cum. d(ln r).") +
  theme(legend.position = "none")

save_fig(fig_B2a, "fig_B2a_cumulative")


# ═══════════════════════════════════════════════════════════════════════════════
# B2b — Annual bar contributions (1940-1978)
# No regime bands, no period windows per spec
# ═══════════════════════════════════════════════════════════════════════════════

df_annual <- df_plot %>% filter(!is.na(dlnr))

bar_long <- df_annual %>%
  select(year, phi_mu, phi_PyPK, phi_Br, phi_pi) %>%
  pivot_longer(cols = starts_with("phi_"), names_to = "channel", values_to = "value") %>%
  mutate(channel = factor(channel,
    levels = c("phi_mu", "phi_PyPK", "phi_Br", "phi_pi"),
    labels = names(ch_colors)))

fig_B2b <- ggplot(bar_long, aes(x = year, y = value, fill = channel)) +
  geom_col(position = "stack", width = 0.75, color = "white", linewidth = 0.1) +
  geom_point(data = df_annual, aes(x = year, y = dlnr),
             shape = 21, fill = "white", color = "#333333", size = 1.6,
             inherit.aes = FALSE) +
  geom_hline(yintercept = 0, color = "#333333", linewidth = 0.5) +
  scale_fill_manual(values = ch_colors) +
  x_ann +
  labs(x = NULL, y = expression(Delta * ln ~ r ~ "(annual)"),
       caption = "Annual log-contributions 1940-1978 (4-channel, exact). Dots = realized d(ln r).") +
  theme(legend.position  = c(0.85, 0.88),
        legend.background = element_rect(fill = "white", color = NA),
        legend.key.size   = unit(0.4, "cm"),
        plot.margin       = margin(5, 15, 5, 5))

save_fig(fig_B2b, "fig_B2b_annual_bars")


# ═══════════════════════════════════════════════════════════════════════════════
# B3 — Swing composition (normalized 100% horizontal bars)
# ═══════════════════════════════════════════════════════════════════════════════

if (nrow(swings) > 0) {

  swing_shares <- swings %>%
    mutate(swing_label = sprintf("%d\u2013%d (%s)", t0, t1, type)) %>%
    select(swing_id, swing_label, type, delta_lnr, s_mu, s_PyPK, s_Br, s_pi) %>%
    pivot_longer(cols = starts_with("s_"), names_to = "channel", values_to = "share") %>%
    mutate(
      channel = factor(channel,
        levels = c("s_mu", "s_PyPK", "s_Br", "s_pi"),
        labels = names(ch_colors)),
      swing_label = fct_reorder(swing_label, swing_id)
    )

  swing_mag <- swings %>%
    mutate(swing_label = sprintf("%d\u2013%d (%s)", t0, t1, type)) %>%
    mutate(swing_label = fct_reorder(swing_label, swing_id))

  # Verify labels
  cat("\n=== B3 LABEL VERIFICATION ===\n")
  swing_mag %>%
    mutate(label = sprintf("\u0394lnr=%+.3f", delta_lnr)) %>%
    select(t0, t1, delta_lnr, label) %>%
    print()

  fig_B3 <- ggplot(swing_shares, aes(x = share, y = fct_rev(swing_label), fill = channel)) +
    geom_col(position = "fill", width = 0.65) +
    geom_vline(xintercept = c(0.25, 0.5, 0.75), color = "white",
               linetype = "dotted", linewidth = 0.5) +
    geom_segment(data = swing_mag,
      aes(x = 1.02, xend = 1.02 + abs(delta_lnr),
          y = fct_rev(swing_label), yend = fct_rev(swing_label),
          color = type),
      linewidth = 4, lineend = "round", inherit.aes = FALSE) +
    geom_text(data = swing_mag,
      aes(x = 1.02 + abs(delta_lnr) + 0.008,
          y = fct_rev(swing_label),
          label = sprintf("\u0394lnr=%+.3f", delta_lnr)),
      hjust = 0, size = 2.8, color = "#333333", family = "roboto",
      inherit.aes = FALSE) +
    scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                       breaks = c(0, 0.25, 0.5, 0.75, 1),
                       expand = expansion(add = c(0, 0.30))) +
    scale_fill_manual(values = ch_colors) +
    scale_color_manual(values = c("contraction" = "#D55E00", "expansion" = "#0072B2"),
                       guide = "none") +
    labs(x = "Share of total swing (%)", y = NULL, fill = NULL,
         caption = "Composition of profit-rate swings, US NF Corporate 1951-1974. Shares sum to 1 (4-channel).") +
    theme(legend.position  = c(0.75, 0.15),
          legend.background = element_rect(fill = "white", color = NA),
          legend.key.size   = unit(0.4, "cm"),
          plot.margin       = margin(5, 80, 5, 130))

  save_fig(fig_B3, "fig_B3_swing_composition",
           w = W, h = max(5, nrow(swings) * 0.9 + 2))
}


# ═══════════════════════════════════════════════════════════════════════════════
# B4 — Profit rate with turning points
# ═══════════════════════════════════════════════════════════════════════════════

df_peaks   <- tp %>% filter(type == "peak")
df_troughs <- tp %>% filter(type == "trough")
df_b4_labels <- df_plot %>% group_by(regime) %>% slice_max(year, n = 1)

fig_B4 <- ggplot(df_plot, aes(x = year, y = r)) +
  # Layer A: regime bands
  geom_rect(data = regime_bands,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
    alpha = 0.40, inherit.aes = FALSE, show.legend = FALSE) +
  scale_fill_identity() +
  # Layer B: period windows
  period_windows +
  # Turning points (primary)
  tp_vlines +
  # Regime text
  annotate("text", x = c(1943, 1960, 1976), y = Inf,
    label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
    vjust = 1.4, hjust = 0.5, size = 3, color = "#555555",
    fontface = "italic", family = "roboto") +
  # Data
  geom_line(color = "#CCCCCC", linewidth = 0.6) +
  geom_line(aes(color = regime, group = regime), linewidth = 1.1) +
  scale_color_manual(values = regime_colors) +
  # Turning point markers
  geom_point(data = df_peaks, aes(x = year, y = value),
             shape = 24, fill = "#D55E00", color = "#D55E00", size = 3,
             inherit.aes = FALSE) +
  geom_point(data = df_troughs, aes(x = year, y = value),
             shape = 25, fill = "#0072B2", color = "#0072B2", size = 3,
             inherit.aes = FALSE) +
  geom_label_repel(data = tp, aes(x = year, y = value, label = year),
    label.size = 0, fill = "white", size = 3, family = "roboto",
    min.segment.length = 0, box.padding = 0.3, inherit.aes = FALSE) +
  # End-of-line regime labels
  geom_text_repel(data = df_b4_labels, aes(label = regime, color = regime),
    direction = "y", hjust = 0, nudge_x = 0.4, size = 3.2,
    segment.size = 0.3, show.legend = FALSE) +
  coord_cartesian(ylim = c(0.13, 0.28), clip = "off") +
  x_ann +
  labs(x = NULL, y = expression(r[t] == GOS[t] / KNC[t]),
       caption = "US NF Corporate 1940-1978. Turning points: local-extrema, min |d(ln r)| >= 0.05, +/- 3yr.") +
  theme(legend.position = "none")

save_fig(fig_B4, "fig_B4_profit_rate_turning_points")


# ═══════════════════════════════════════════════════════════════════════════════
# FINAL CHECKS
# ═══════════════════════════════════════════════════════════════════════════════

cat("\n=== FINAL VALIDATION ===\n")
fc <- df %>% filter(year >= 1940, year <= 1978)
na_count <- sum(is.na(fc %>% select(phi_mu, phi_PyPK, phi_Br, phi_pi, dlnr)))
cat(sprintf("NAs in 1940-1978 phi variables: %d  %s\n", na_count, ifelse(na_count == 0, "PASS", "FAIL")))
stopifnot(na_count == 0)

for (yr in c(1966, 1973)) {
  row <- df %>% filter(year == yr)
  s <- row$phi_mu + row$phi_PyPK + row$phi_Br + row$phi_pi
  cat(sprintf("Spot %d: dlnr=%.6f  sum=%.6f  err=%.2e  %s\n",
      yr, row$dlnr, s, abs(row$dlnr - s), ifelse(abs(row$dlnr - s) < 1e-10, "PASS", "FAIL")))
}

cat(sprintf("\nFigures saved: %s\n", fig_dir))
cat("Stage B v2 complete.\n")
