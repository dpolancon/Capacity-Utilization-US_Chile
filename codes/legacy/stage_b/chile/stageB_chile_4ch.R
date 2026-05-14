## ==========================================================================
## Chile Stage B — 4-Channel Profitability Analysis
## Source: agents/prompt_stageB_Chile_MERGED_4ch.md
## Identity: r = mu * (Py/PK) * B_real * pi
## Window: 1940–1978 (N=39)
## ==========================================================================

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(scales)
  library(forcats)
  library(purrr)
  library(ggrepel)
})

# Try showtext; fall back gracefully
has_showtext <- requireNamespace("showtext", quietly = TRUE)
if (has_showtext) {
  library(showtext)
  tryCatch({
    font_add_google("Roboto Condensed", "roboto")
    showtext_auto()
    base_family <- "roboto"
  }, error = function(e) {
    base_family <<- ""
    message("showtext font failed, using default font")
  })
} else {
  base_family <- ""
}

## ---- Paths ----
REPO    <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
FIG_OUT <- file.path(REPO, "output/stage_b/Chile/figs")
CSV_OUT <- file.path(REPO, "output/stage_b/Chile/csv")
TAB_OUT <- file.path(REPO, "output/stage_b/Chile/tables")

dir.create(FIG_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(CSV_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(TAB_OUT, recursive = TRUE, showWarnings = FALSE)

## ---- Step 0: Load existing 3-channel Stage B panel ----
## This panel was produced by the 3-channel run (prompt_07) and already
## contains: r_t, mu_CL, B_t, pi_t, p_Y, P_K, p_rel, ln_r, ln_mu, ln_pi,
## ECT_m, theta_CL, omega, y_p_log, k_CL, etc.
panel <- read_csv(file.path(CSV_OUT, "stageB_CL_panel_1940_1978.csv"),
                  show_col_types = FALSE)
cat("Panel columns:\n")
cat(names(panel), sep = "\n")
cat(sprintf("\nPanel rows: %d\n", nrow(panel)))
cat(sprintf("Year range: %d – %d\n", min(panel$year), max(panel$year)))

## ---- Step 0b: Column check ----
needed <- c("year","mu_CL","B_t","pi_t","p_rel","omega","r_t",
            "ln_r","ln_mu","ln_pi","ECT_m")
missing <- setdiff(needed, names(panel))
if (length(missing) > 0) {
  stop("Missing columns: ", paste(missing, collapse = ", "))
}
cat("All required columns present.\n")

cat(sprintf("mu_CL range: [%.4f, %.4f]\n",
    min(panel$mu_CL, na.rm=TRUE), max(panel$mu_CL, na.rm=TRUE)))
cat(sprintf("p_rel range: [%.4f, %.4f]\n",
    min(panel$p_rel, na.rm=TRUE), max(panel$p_rel, na.rm=TRUE)))
cat(sprintf("B_t   range: [%.4f, %.4f]\n",
    min(panel$B_t, na.rm=TRUE), max(panel$B_t, na.rm=TRUE)))
cat(sprintf("r_t   range: [%.4f, %.4f]\n",
    min(panel$r_t, na.rm=TRUE), max(panel$r_t, na.rm=TRUE)))

## ---- Step 1: Construct 4-channel variables ----
df_chile <- panel |>
  arrange(year) |>
  mutate(
    r      = r_t,
    mu     = mu_CL,
    pi     = pi_t,
    B      = B_t,
    PyPK   = p_rel,
    B_real = B / PyPK,

    dlnr     = c(NA, diff(ln_r)),
    phi_mu   = c(NA, diff(log(mu))),
    phi_PyPK = c(NA, diff(log(PyPK))),
    phi_Br   = c(NA, diff(log(B_real))),
    phi_pi   = c(NA, diff(log(pi))),

    regime = case_when(
      year <= 1945 ~ "Pre-ISI/WWII",
      year <= 1953 ~ "Early ISI",
      year <= 1961 ~ "Mid ISI",
      year <= 1972 ~ "Late ISI",
      TRUE         ~ "Crisis"
    ),
    regime = factor(regime, levels = c(
      "Pre-ISI/WWII", "Early ISI", "Mid ISI", "Late ISI", "Crisis"))
  )

df_plot <- df_chile  # Already filtered to 1940-1978 from source
cat(sprintf("\nStage B panel: N=%d (1940–1978)\n", nrow(df_plot)))
cat(sprintf("B_real range: [%.4f, %.4f]\n",
    min(df_plot$B_real, na.rm=TRUE), max(df_plot$B_real, na.rm=TRUE)))

## ---- Step 2: Identity checks ----
check_additive <- max(abs(
  df_plot$phi_mu + df_plot$phi_PyPK + df_plot$phi_Br + df_plot$phi_pi
  - df_plot$dlnr), na.rm = TRUE)
cat(sprintf("\nAdditive identity check: %.2e\n", check_additive))
stopifnot(check_additive < 1e-10)

check_B_decomp <- max(abs(df_plot$B - df_plot$PyPK * df_plot$B_real),
                      na.rm = TRUE)
cat(sprintf("B = PyPK * B_real check: %.2e\n", check_B_decomp))
stopifnot(check_B_decomp < 1e-6)

check_levels <- max(abs(
  df_plot$r - df_plot$mu * df_plot$PyPK * df_plot$B_real * df_plot$pi),
  na.rm = TRUE)
cat(sprintf("r = mu*PyPK*Br*pi check: %.2e\n", check_levels))
stopifnot(check_levels < 1e-6)

cat("All identity checks passed.\n")

## ---- Step 3: Theme and colors ----
theme_stageB_CL <- theme_minimal(base_family = base_family, base_size = 13) +
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
theme_set(theme_stageB_CL)

ch_colors_CL <- c(
  "mu (demand)"          = "#0072B2",
  "Py/PK (rel. price)"   = "#CC79A7",
  "B_real (technology)"   = "#009E73",
  "pi (distribution)"     = "#D55E00"
)

regime_colors_CL <- c(
  "Pre-ISI/WWII" = "#999999",
  "Early ISI"    = "#56B4E9",
  "Mid ISI"      = "#0072B2",
  "Late ISI"     = "#009E73",
  "Crisis"       = "#D95F02"
)

isi_bands <- tibble(
  xmin  = c(1940, 1946, 1954, 1962, 1973),
  xmax  = c(1945, 1953, 1961, 1972, 1978),
  fill  = c("#F5F5F5", "#EBF5FB", "#E8F8F5", "#FEF9E7", "#FDEDEC"),
  label = c("Pre-ISI\n/WWII", "Early\nISI", "Mid\nISI",
            "Late\nISI", "Crisis")
)

## ---- Step 4: BoP constraint band ----
lambda_hat <- -0.1394

bop_layer <- NULL
if ("ECT_m" %in% names(df_plot) && sum(!is.na(df_plot$ECT_m)) > 0) {
  df_bop <- df_plot |>
    select(year, ECT_m) |>
    filter(!is.na(ECT_m)) |>
    mutate(
      constrained = ECT_m > lambda_hat,
      episode_id  = cumsum(c(TRUE, diff(constrained) != 0))
    ) |>
    filter(constrained) |>
    group_by(episode_id) |>
    summarise(xmin = min(year) - 0.5, xmax = max(year) + 0.5,
              .groups = "drop")

  if (nrow(df_bop) > 0) {
    bop_layer <- geom_rect(
      data = df_bop,
      aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
      fill = "#E74C3C", alpha = 0.18,
      inherit.aes = FALSE, show.legend = FALSE
    )
    cat(sprintf("BoP constrained episodes: %d\n", nrow(df_bop)))
    print(df_bop)
  } else {
    cat("No BoP constrained episodes found.\n")
  }
} else {
  cat("ECT_m not available; skipping BoP band.\n")
}

## ---- Step 5: save_fig helper ----
save_fig <- function(fig, name, w = 12, h = 6) {
  ggsave(file.path(FIG_OUT, paste0(name, ".pdf")), fig,
         width = w, height = h, device = cairo_pdf)
  ggsave(file.path(FIG_OUT, paste0(name, ".png")), fig,
         width = w, height = h, dpi = 300)
  cat(sprintf("Saved: %s (.pdf + .png)\n", name))
}

W <- 12; H <- 6

## ---- Step 6: Index for B1 panels ----
df_B1 <- df_plot |>
  mutate(across(c(r, mu, B, pi, PyPK, B_real),
    ~ . / .[year == 1940] * 100, .names = "{.col}_idx"))

## ---- Step 7: make_B1 template function ----
make_B1 <- function(df, var_idx, ylab = "Index (1940 = 100)") {
  p <- ggplot(df, aes(x = year, y = .data[[var_idx]])) +
    geom_rect(data = isi_bands,
      aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
      alpha = 0.40, inherit.aes = FALSE, show.legend = FALSE) +
    scale_fill_identity()

  if (!is.null(bop_layer)) p <- p + bop_layer

  p <- p +
    geom_vline(xintercept = 1970, linetype = "dotted",
               color = "#BBBBBB", linewidth = 0.25) +
    geom_vline(xintercept = 1973, linetype = "dotted",
               color = "#BBBBBB", linewidth = 0.25) +
    annotate("text", x = 1971.5, y = Inf, label = "UP",
             vjust = 1.8, hjust = 0.5, size = 2.4,
             color = "#888888", fontface = "italic") +
    geom_line(color = "#CCCCCC", linewidth = 0.5) +
    geom_line(aes(color = regime, group = regime), linewidth = 1.0) +
    scale_color_manual(values = regime_colors_CL) +
    geom_hline(yintercept = 100, linetype = "dashed",
               color = "#AAAAAA", linewidth = 0.4) +
    annotate("text",
      x = c(1942.5, 1949.5, 1957.5, 1967, 1975.5), y = Inf,
      label = c("Pre-ISI\n/WWII", "Early\nISI", "Mid\nISI",
                "Late\nISI", "Crisis"),
      vjust = 1.4, hjust = 0.5, size = 2.8,
      color = "#555555", fontface = "italic") +
    geom_text_repel(
      data = df |> group_by(regime) |> slice_max(year, n = 1),
      aes(label = regime, color = regime),
      direction = "y", hjust = 0, nudge_x = 0.4,
      size = 3.2, segment.size = 0.3, show.legend = FALSE) +
    scale_x_continuous(breaks = 1940:1978, minor_breaks = NULL,
                       labels = 1940:1978) +
    labs(y = ylab) +
    theme(legend.position = "none")

  return(p)
}

## ---- Step 8: Generate B1 panels ----
cat("\n--- Generating B1 panels ---\n")
fig_CL_B1a <- make_B1(df_B1, "r_idx")
fig_CL_B1b <- make_B1(df_B1, "mu_idx")
fig_CL_B1c <- make_B1(df_B1, "B_idx")
fig_CL_B1d <- make_B1(df_B1, "pi_idx")
fig_CL_B1e <- make_B1(df_B1, "PyPK_idx")
fig_CL_B1f <- make_B1(df_B1, "B_real_idx")

save_fig(fig_CL_B1a, "fig_CL_B1a_r_levels",     w = W, h = H)
save_fig(fig_CL_B1b, "fig_CL_B1b_mu_levels",     w = W, h = H)
save_fig(fig_CL_B1c, "fig_CL_B1c_B_levels",      w = W, h = H)
save_fig(fig_CL_B1d, "fig_CL_B1d_pi_levels",     w = W, h = H)
save_fig(fig_CL_B1e, "fig_CL_B1e_PyPK_levels",   w = W, h = H)
save_fig(fig_CL_B1f, "fig_CL_B1f_Breal_levels",  w = W, h = H)

## ---- Step 9: B2a — Cumulative contributions ----
cat("\n--- Generating B2a cumulative ---\n")
df_cum <- df_plot |>
  arrange(year) |>
  mutate(
    cum_mu   = cumsum(replace_na(phi_mu,   0)),
    cum_PyPK = cumsum(replace_na(phi_PyPK, 0)),
    cum_Br   = cumsum(replace_na(phi_Br,   0)),
    cum_pi   = cumsum(replace_na(phi_pi,   0)),
    cum_r    = cumsum(replace_na(dlnr,     0))
  )

df_cum_long_CL <- df_cum |>
  pivot_longer(cols = c(cum_mu, cum_PyPK, cum_Br, cum_pi),
               names_to = "channel", values_to = "value") |>
  mutate(channel = recode(channel,
    "cum_mu"   = "mu (demand)",
    "cum_PyPK" = "Py/PK (rel. price)",
    "cum_Br"   = "B_real (technology)",
    "cum_pi"   = "pi (distribution)"))

fig_CL_B2a <- ggplot(df_cum_long_CL,
                      aes(x = year, fill = channel, group = channel)) +
  geom_ribbon(aes(ymin = pmin(value, 0), ymax = pmax(value, 0)),
              alpha = 0.72, position = "identity") +
  geom_hline(yintercept = 0, color = "#333333", linewidth = 0.6) +
  geom_line(data = df_cum, aes(x = year, y = cum_r),
            color = "black", linewidth = 1.0, inherit.aes = FALSE) +
  scale_fill_manual(values = ch_colors_CL) +
  scale_x_continuous(breaks = 1940:1978, labels = 1940:1978) +
  labs(y = "Cumulative delta-ln r") +
  annotate("rect", xmin = 1969, xmax = 1974,
           ymin = -Inf, ymax = Inf, fill = "#FFF3E0", alpha = 0.5) +
  annotate("text", x = 1971.5, y = Inf,
           label = "Distributional\noverdetermination",
           vjust = 1.4, size = 2.8, color = "#D95F02", fontface = "italic") +
  geom_text_repel(
    data = df_cum_long_CL |> group_by(channel) |> slice_max(year, n = 1),
    aes(x = year, y = value, label = channel, color = channel),
    direction = "y", hjust = 0, nudge_x = 0.4,
    size = 3.2, segment.size = 0.3, show.legend = FALSE,
    inherit.aes = FALSE) +
  scale_color_manual(values = ch_colors_CL) +
  theme(legend.position = "none")

save_fig(fig_CL_B2a, "fig_CL_B2a_cumulative", w = W, h = H)

## ---- Step 10: B2b — Annual bars ----
cat("\n--- Generating B2b annual bars ---\n")
df_annual_CL <- df_plot |> filter(!is.na(dlnr))

df_annual_long_CL <- df_annual_CL |>
  pivot_longer(cols = c(phi_mu, phi_PyPK, phi_Br, phi_pi),
               names_to = "channel", values_to = "value") |>
  mutate(channel = recode(channel,
    "phi_mu"   = "mu (demand)",
    "phi_PyPK" = "Py/PK (rel. price)",
    "phi_Br"   = "B_real (technology)",
    "phi_pi"   = "pi (distribution)"))

fig_CL_B2b <- ggplot(df_annual_long_CL,
                      aes(x = year, y = value, fill = channel)) +
  geom_col(position = "stack", width = 0.75,
           color = "white", linewidth = 0.1) +
  geom_point(data = df_annual_CL, aes(x = year, y = dlnr),
             shape = 21, fill = "white", color = "#333333",
             size = 1.6, inherit.aes = FALSE) +
  geom_hline(yintercept = 0, color = "#333333", linewidth = 0.5) +
  scale_fill_manual(values = ch_colors_CL) +
  scale_x_continuous(breaks = 1940:1978, labels = 1940:1978) +
  labs(y = "delta-ln r (annual)") +
  theme(legend.position  = c(0.85, 0.88),
        legend.background = element_rect(fill = "white", color = NA),
        legend.key.size   = unit(0.4, "cm"))

save_fig(fig_CL_B2b, "fig_CL_B2b_annual_bars", w = W, h = H)

## ---- Step 11: Swing decomposition ----
cat("\n--- Computing swing decomposition ---\n")
swings <- list(
  list(label = "1940-1946", start = 1940, end = 1946),
  list(label = "1946-1947", start = 1946, end = 1947),
  list(label = "1947-1953", start = 1947, end = 1953),
  list(label = "1953-1961", start = 1953, end = 1961),
  list(label = "1961-1969", start = 1961, end = 1969),
  list(label = "1969-1972", start = 1969, end = 1972),
  list(label = "1972-1974", start = 1972, end = 1974),
  list(label = "1974-1975", start = 1974, end = 1975),
  list(label = "1975-1978", start = 1975, end = 1978)
)

df_swings_CL <- map_dfr(swings, function(sw) {
  s_idx <- which(df_plot$year == sw$start)
  e_idx <- which(df_plot$year == sw$end)
  if (length(s_idx) == 0 || length(e_idx) == 0) return(NULL)

  delta_lnr  <- log(df_plot$r[e_idx])     - log(df_plot$r[s_idx])
  delta_mu   <- log(df_plot$mu[e_idx])    - log(df_plot$mu[s_idx])
  delta_PyPK <- log(df_plot$PyPK[e_idx])  - log(df_plot$PyPK[s_idx])
  delta_Br   <- log(df_plot$B_real[e_idx])- log(df_plot$B_real[s_idx])
  delta_pi   <- log(df_plot$pi[e_idx])    - log(df_plot$pi[s_idx])

  tibble(
    swing     = sw$label,
    type      = ifelse(delta_lnr > 0, "Expansion", "Contraction"),
    delta_lnr = delta_lnr,
    s_mu      = delta_mu   / delta_lnr,
    s_PyPK    = delta_PyPK / delta_lnr,
    s_Br      = delta_Br   / delta_lnr,
    s_pi      = delta_pi   / delta_lnr,
    check_sum = delta_mu/delta_lnr + delta_PyPK/delta_lnr +
                delta_Br/delta_lnr + delta_pi/delta_lnr
  )
})

# Identity check
stopifnot(all(abs(df_swings_CL$check_sum - 1) < 1e-10))
cat("Swing shares sum-to-unity check: PASSED\n")

# Dominant channel
df_swings_CL <- df_swings_CL |>
  rowwise() |>
  mutate(dominant = {
    shares <- c(mu = abs(s_mu), PyPK = abs(s_PyPK),
                Br = abs(s_Br), pi = abs(s_pi))
    names(which.max(shares))
  }) |>
  ungroup()

cat("\n=== Swing-Level 4-Channel Decomposition ===\n")
print(df_swings_CL, n = 20)

write_csv(df_swings_CL,
          file.path(CSV_OUT, "stageB_CL_swing_decomposition_4ch.csv"))

## ---- Step 12: B3 — Swing composition figure ----
cat("\n--- Generating B3 swing composition ---\n")
df_swings_long_CL <- df_swings_CL |>
  select(swing, type, delta_lnr, s_mu, s_PyPK, s_Br, s_pi) |>
  pivot_longer(cols = c(s_mu, s_PyPK, s_Br, s_pi),
               names_to = "channel", values_to = "share") |>
  mutate(
    channel = recode(channel,
      "s_mu"   = "mu (demand)",
      "s_PyPK" = "Py/PK (rel. price)",
      "s_Br"   = "B_real (technology)",
      "s_pi"   = "pi (distribution)"),
    channel = factor(channel, levels = names(ch_colors_CL))
  )

fig_CL_B3 <- ggplot(df_swings_long_CL,
                     aes(x = share, y = fct_rev(swing), fill = channel)) +
  geom_col(position = "stack", alpha = 0.85) +
  geom_vline(xintercept = 0, linetype = "dotted", color = "grey40") +
  geom_vline(xintercept = 1.0, linetype = "dashed",
             color = "#CCCCCC", linewidth = 0.4) +
  scale_fill_manual(values = ch_colors_CL) +
  scale_x_continuous(
    labels = scales::percent_format(accuracy = 1),
    breaks = c(-0.25, 0, 0.25, 0.5, 0.75, 1, 1.25),
    expand = expansion(add = c(0.08, 0.35))
  ) +
  geom_text(
    data = df_swings_CL,
    aes(x = 1.0, y = fct_rev(swing),
        label = sprintf("dlnr=%+.3f", delta_lnr)),
    hjust = -0.1, size = 3, inherit.aes = FALSE) +
  labs(x = "Share of total swing (%)", y = NULL, fill = NULL) +
  theme(
    plot.margin = margin(5, 90, 5, 140, unit = "pt"),
    legend.position = c(0.85, 0.15),
    legend.background = element_rect(fill = "white", color = NA),
    legend.key.size = unit(0.4, "cm"))

save_fig(fig_CL_B3, "fig_CL_B3_swing_composition", w = W, h = H)

## ---- Step 13: B4 — Profit rate with turning points ----
cat("\n--- Generating B4 profit rate with turning points ---\n")

# Classify turning points as peaks/troughs based on actual data
tp_years <- c(1946, 1947, 1953, 1961, 1969, 1972, 1974, 1975, 1978)
df_turning_CL <- df_plot |> filter(year %in% tp_years)

# Classify based on whether r increases or decreases after the point
classify_tp <- function(yr) {
  idx <- which(df_plot$year == yr)
  if (idx == 1) return("peak")
  if (idx == nrow(df_plot)) {
    # last point: compare to previous
    return(ifelse(df_plot$r[idx] > df_plot$r[idx-1], "peak", "trough"))
  }
  r_before <- df_plot$r[idx - 1]
  r_after  <- df_plot$r[idx + 1]
  r_now    <- df_plot$r[idx]
  if (r_now >= r_before && r_now >= r_after) return("peak")
  if (r_now <= r_before && r_now <= r_after) return("trough")
  # Swing-based: if next swing is contraction, this is a peak
  sw_idx <- which(sapply(swings, function(s) s$start) == yr)
  if (length(sw_idx) > 0) {
    sw <- swings[[sw_idx]]
    e <- which(df_plot$year == sw$end)
    return(ifelse(df_plot$r[e] < df_plot$r[idx], "peak", "trough"))
  }
  return("peak")
}

df_turning_CL <- df_turning_CL |>
  mutate(tp_type = sapply(year, classify_tp))

df_peaks_CL   <- df_turning_CL |> filter(tp_type == "peak")
df_troughs_CL <- df_turning_CL |> filter(tp_type == "trough")

cat(sprintf("Peaks: %s\n", paste(df_peaks_CL$year, collapse = ", ")))
cat(sprintf("Troughs: %s\n", paste(df_troughs_CL$year, collapse = ", ")))

# Determine y-axis range
r_range <- range(df_plot$r, na.rm = TRUE)
cat(sprintf("Profit rate range: [%.4f, %.4f]\n", r_range[1], r_range[2]))
ylim_B4 <- c(floor(r_range[1] * 100) / 100 - 0.005,
             ceiling(r_range[2] * 100) / 100 + 0.005)

fig_CL_B4 <- ggplot(df_plot, aes(x = year, y = r)) +
  geom_rect(data = isi_bands,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
    alpha = 0.40, inherit.aes = FALSE, show.legend = FALSE) +
  scale_fill_identity()

if (!is.null(bop_layer)) fig_CL_B4 <- fig_CL_B4 + bop_layer

fig_CL_B4 <- fig_CL_B4 +
  geom_vline(xintercept = 1970, linetype = "dotted",
             color = "#BBBBBB", linewidth = 0.25) +
  geom_vline(xintercept = 1973, linetype = "dotted",
             color = "#BBBBBB", linewidth = 0.25) +
  annotate("text", x = 1971.5, y = Inf, label = "UP",
           vjust = 1.8, hjust = 0.5, size = 2.4,
           color = "#888888", fontface = "italic") +
  geom_line(color = "#CCCCCC", linewidth = 0.6) +
  geom_line(aes(color = regime, group = regime), linewidth = 1.1) +
  scale_color_manual(values = regime_colors_CL) +
  geom_point(data = df_peaks_CL,
             aes(x = year, y = r),
             shape = 24, fill = "#D55E00", color = "#D55E00", size = 3,
             inherit.aes = FALSE) +
  geom_point(data = df_troughs_CL,
             aes(x = year, y = r),
             shape = 25, fill = "#0072B2", color = "#0072B2", size = 3,
             inherit.aes = FALSE) +
  geom_label_repel(data = df_turning_CL,
    aes(x = year, y = r, label = year),
    label.size = 0, fill = "white",
    size = 3, min.segment.length = 0, box.padding = 0.3,
    inherit.aes = FALSE) +
  annotate("text",
    x = c(1942.5, 1949.5, 1957.5, 1967, 1975.5), y = Inf,
    label = c("Pre-ISI\n/WWII", "Early\nISI", "Mid\nISI",
              "Late\nISI", "Crisis"),
    vjust = 1.4, hjust = 0.5, size = 2.8,
    color = "#555555", fontface = "italic") +
  coord_cartesian(ylim = ylim_B4) +
  scale_x_continuous(breaks = 1940:1978, labels = 1940:1978) +
  labs(y = expression(r[t] == Pi[t] / K[t])) +
  geom_text_repel(
    data = df_plot |> group_by(regime) |> slice_max(year, n = 1),
    aes(label = regime, color = regime),
    direction = "y", hjust = 0, nudge_x = 0.4,
    size = 3.2, segment.size = 0.3, show.legend = FALSE) +
  theme(legend.position = "none")

save_fig(fig_CL_B4, "fig_CL_B4_profit_rate_turning_points", w = W, h = H)

## ---- Step 14: Sub-period averages ----
cat("\n--- Computing sub-period averages ---\n")
subperiods <- list(
  "Pre-ISI/WWII" = c(1940, 1945),
  "Early ISI"    = c(1946, 1953),
  "Mid ISI"      = c(1954, 1961),
  "Late ISI"     = c(1962, 1972),
  "Crisis"       = c(1973, 1978)
)

tab_subperiod <- map_dfr(names(subperiods), function(nm) {
  yr  <- subperiods[[nm]]
  idx <- df_plot$year >= yr[1] & df_plot$year <= yr[2]
  tibble(
    period    = nm,
    years     = sprintf("%d--%d", yr[1], yr[2]),
    n         = sum(idx),
    r_mean    = mean(df_plot$r[idx],      na.rm = TRUE),
    mu_mean   = mean(df_plot$mu[idx],     na.rm = TRUE),
    PyPK_mean = mean(df_plot$PyPK[idx],   na.rm = TRUE),
    Br_mean   = mean(df_plot$B_real[idx], na.rm = TRUE),
    pi_mean   = mean(df_plot$pi[idx],     na.rm = TRUE)
  )
})

cat("\n=== Sub-Period Averages (4-Channel) ===\n")
print(tab_subperiod)
write_csv(tab_subperiod,
          file.path(CSV_OUT, "stageB_CL_subperiod_averages_4ch.csv"))

## ---- Step 15: Write LaTeX Table B4 ----
cat("\n--- Writing Table B4 ---\n")

tab_B4_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\small",
  "\\caption{Weisskopf components: sub-period means, Chile, 1940--1978.}",
  "\\label{tab:B4_subperiod_CL}",
  "\\begin{threeparttable}",
  "\\begin{tabular}{llrrrrr}",
  "\\toprule",
  "Period & Years & $\\bar{r}$ & $\\bar{\\mu}$ & $\\overline{Py/PK}$ & $\\bar{B}_{r}$ & $\\bar{\\pi}$ \\\\",
  "\\midrule"
)

for (i in seq_len(nrow(tab_subperiod))) {
  row <- tab_subperiod[i, ]
  line <- sprintf("%s & %s & %.3f & %.3f & %.3f & %.3f & %.3f \\\\",
                  row$period, row$years, row$r_mean, row$mu_mean,
                  row$PyPK_mean, row$Br_mean, row$pi_mean)
  tab_B4_lines <- c(tab_B4_lines, line)
  if (i == 1 || i == 4) tab_B4_lines <- c(tab_B4_lines, "\\midrule")
}

tab_B4_lines <- c(tab_B4_lines,
  "\\bottomrule",
  "\\end{tabular}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:}",
  "  Period arithmetic means of level variables.",
  "  $r = \\Pi/K$ (nominal profit rate);",
  "  $\\hat{\\mu}$ from Stage~A MPF (capacity utilization);",
  "  $Py/PK$ = GDP deflator / capital price deflator;",
  "  $B_{r} = Y^{p}_{r}/K$ (real capital productivity at normal capacity);",
  "  $\\pi = \\Pi/Y$ (profit share).",
  "  Exact identity in levels: $r \\equiv \\hat{\\mu} \\cdot (Py/PK) \\cdot B_{r} \\cdot \\pi$.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab_B4_lines, file.path(TAB_OUT, "tab_B4_subperiod_CL.tex"))
cat("Table B4 saved.\n")

## ---- Step 16: Write LaTeX Table B5 ----
cat("\n--- Writing Table B5 ---\n")

fmt_share <- function(s, is_negative_offset = FALSE) {
  if (is_negative_offset) {
    sprintf("\\textit{%.3f}$^{\\dagger}$", s)
  } else if (abs(s) > 1.0) {
    sprintf("%.3f$^{*}$", s)
  } else {
    sprintf("%.3f", s)
  }
}

fmt_dominant <- function(dom, s_pi_val = 0) {
  dom_map <- c(mu = "$\\mu$", PyPK = "$Py/PK$", Br = "$B_{r}$", pi = "$\\pi$")
  d <- dom_map[dom]
  if (dom == "pi" && abs(s_pi_val) > 1.0) d <- paste0(d, "$^{*}$")
  return(d)
}

tab_B5_lines <- c(
  "\\begin{table}[htbp]",
  "\\centering",
  "\\small",
  "\\caption{Four-channel decomposition of profit-rate swings, Chile, 1940--1978.}",
  "\\label{tab:B5_peaktotrough_CL}",
  "\\begin{threeparttable}",
  "\\adjustbox{max width=\\textwidth}{",
  "\\begin{tabular}{llrrrrrrrl}",
  "\\toprule",
  "Period & Type & $\\Delta\\ln r$ & $s_{\\mu}$ & $s_{Py/PK}$ & $s_{B_{r}}$ & $s_{\\pi}$ & $\\Sigma$ & Dominant \\\\",
  "\\midrule"
)

prev_type <- ""
for (i in seq_len(nrow(df_swings_CL))) {
  row <- df_swings_CL[i, ]
  # Addlinespace between type changes
  if (prev_type != "" && row$type != prev_type) {
    tab_B5_lines <- c(tab_B5_lines, "\\addlinespace[3pt]")
  }
  prev_type <- row$type

  # Offsetting = negative share (channel moves against swing direction)
  # s_j > 0 means channel contributes to the swing; s_j < 0 means it offsets
  off_mu   <- row$s_mu   < 0
  off_PyPK <- row$s_PyPK < 0
  off_Br   <- row$s_Br   < 0
  off_pi   <- row$s_pi   < 0

  line <- sprintf("%s & %s & %+.3f & %s & %s & %s & %s & %.3f & %s \\\\",
    row$swing,
    row$type,
    row$delta_lnr,
    fmt_share(row$s_mu,   off_mu),
    fmt_share(row$s_PyPK, off_PyPK),
    fmt_share(row$s_Br,   off_Br),
    fmt_share(row$s_pi,   off_pi),
    row$s_mu + row$s_PyPK + row$s_Br + row$s_pi,
    fmt_dominant(row$dominant, row$s_pi)
  )
  tab_B5_lines <- c(tab_B5_lines, line)
}

tab_B5_lines <- c(tab_B5_lines,
  "\\bottomrule",
  "\\end{tabular}}",
  "\\begin{tablenotes}",
  "\\small",
  "\\item \\textit{Notes:}",
  "  $s_{j} = \\varphi^{j}/\\Delta\\ln r$ (share of total compounded log-change);",
  "  $s_{\\mu} + s_{Py/PK} + s_{B_{r}} + s_{\\pi} = 1$ (exact).",
  "  $\\varphi^{\\mu} = \\Delta\\ln\\hat{\\mu}$,",
  "  $\\varphi^{Py/PK} = \\Delta\\ln(Py/PK)$,",
  "  $\\varphi^{B_{r}} = \\Delta\\ln B_{r}$,",
  "  $\\varphi^{\\pi} = \\Delta\\ln\\pi$.",
  "\\item[$\\dagger$] Offsetting channel: contribution moves against the swing direction ($s_{j} < 0$).",
  "\\item[$*$] Share exceeds unity: channel more than accounts for total swing;",
  "  remaining channels are jointly offsetting.",
  "\\end{tablenotes}",
  "\\end{threeparttable}",
  "\\end{table}"
)

writeLines(tab_B5_lines, file.path(TAB_OUT, "tab_B5_peaktotrough_CL.tex"))
cat("Table B5 saved.\n")

## ---- Step 17: Save full Stage B 4-channel panel ----
cat("\n--- Saving Stage B panel ---\n")
export_cols <- c("year", "r", "mu", "B", "PyPK", "B_real", "pi", "dlnr",
                 "phi_mu", "phi_PyPK", "phi_Br", "phi_pi",
                 "regime", "ECT_m", "theta_CL", "omega")
export_cols <- intersect(export_cols, names(df_plot))
df_export <- df_plot |> select(all_of(export_cols))

write_csv(df_export, file.path(CSV_OUT, "stageB_CL_panel_1940_1978_4ch.csv"))
cat("Stage B 4-channel panel saved.\n")

## ---- Step 18: Final report ----
cat("\n================================================================\n")
cat("  CHILE STAGE B — 4-CHANNEL PROFITABILITY ANALYSIS CROSSWALK\n")
cat("================================================================\n")
cat(sprintf("Window:      1940–1978 (N=%d)\n", nrow(df_plot)))
cat(sprintf("Identity:    r = mu * PyPK * B_real * pi\n"))
cat(sprintf("  Additive:  max|residual| = %.2e\n", check_additive))
cat(sprintf("  B decomp:  max|residual| = %.2e\n", check_B_decomp))
cat(sprintf("  Levels:    max|residual| = %.2e\n", check_levels))
cat("\nSub-period means:\n")
print(tab_subperiod |> select(period, r_mean, mu_mean, PyPK_mean, Br_mean, pi_mean))
cat("\nSwing dominant channels:\n")
print(df_swings_CL |> select(swing, type, delta_lnr, dominant))
cat("\nOutputs:\n")
for (f in c(
  "csv/stageB_CL_panel_1940_1978_4ch.csv",
  "csv/stageB_CL_subperiod_averages_4ch.csv",
  "csv/stageB_CL_swing_decomposition_4ch.csv",
  "figs/fig_CL_B1a_r_levels.pdf", "figs/fig_CL_B1b_mu_levels.pdf",
  "figs/fig_CL_B1c_B_levels.pdf", "figs/fig_CL_B1d_pi_levels.pdf",
  "figs/fig_CL_B1e_PyPK_levels.pdf", "figs/fig_CL_B1f_Breal_levels.pdf",
  "figs/fig_CL_B2a_cumulative.pdf", "figs/fig_CL_B2b_annual_bars.pdf",
  "figs/fig_CL_B3_swing_composition.pdf",
  "figs/fig_CL_B4_profit_rate_turning_points.pdf",
  "tables/tab_B4_subperiod_CL.tex",
  "tables/tab_B5_peaktotrough_CL.tex")) {
  exists <- file.exists(file.path(REPO, "output/stage_b/Chile", f))
  cat(sprintf("  [%s] %s\n", ifelse(exists, "OK", "!!"), f))
}
cat("================================================================\n")
