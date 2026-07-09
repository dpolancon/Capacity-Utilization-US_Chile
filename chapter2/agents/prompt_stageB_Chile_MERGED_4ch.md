# Stage B Chile — Merged Prompt (4-Channel, Final)
## Date: 2026-04-09
## Merges: prompt_stageB_Chile_FINAL.md + prompt_stageB_Chile_4ch_addendum.md
## Identity: r = mu * PyPK * B_real * pi (4-channel, mirrors US exactly)
## Mirrors: prompt_stageB_US_FINAL.md

---

## FIGURES LIST --- 10 standalone files, no panels in R

Every figure is a **single standalone file**. LaTeX handles all panel
assembly and layout. B1 layout is 2x3:

| | Col 1 | Col 2 | Col 3 |
|---|---|---|---|
| **Row 1** | B1a --- r | B1b --- mu | B1c --- B (nominal, reference) |
| **Row 2** | B1d --- pi | B1e --- Py/PK | B1f --- B_real |

Row 2 makes B = (Py/PK) x B_real visually decomposable.

| Content | Filename | LaTeX group |
|---|---|---|
| Profit rate r (indexed) | `fig_CL_B1a_r_levels` | B1 panel |
| Capacity utilization mu (indexed) | `fig_CL_B1b_mu_levels` | B1 panel |
| Nominal B (indexed, reference) | `fig_CL_B1c_B_levels` | B1 panel |
| Profit share pi (indexed) | `fig_CL_B1d_pi_levels` | B1 panel |
| Relative price Py/PK (indexed) | `fig_CL_B1e_PyPK_levels` | B1 panel |
| Real capital productivity B_real (indexed) | `fig_CL_B1f_Breal_levels` | B1 panel |
| Cumulative contributions | `fig_CL_B2a_cumulative` | standalone |
| Annual bar contributions | `fig_CL_B2b_annual_bars` | standalone |
| Swing composition | `fig_CL_B3_swing_composition` | standalone |
| Profit rate + turning points | `fig_CL_B4_profit_rate_turning_points` | standalone |

All to `output/stage_b/Chile/figs/`.

---

## SECTION 1 --- ANALYSIS WINDOW, DATA, AND 4-CHANNEL CONSTRUCTION

**Primary window: 1940--1978**, inclusive. N=39.

**Four-channel identity:** r = mu x (Py/PK) x B_real x pi (exact, no residual).

B (nominal capital productivity) is retained as a contextual level-panel
figure (B1c) but exits the decomposition.

### Step 0: Load and construct

```r
library(tidyverse); library(ggplot2); library(scales)
library(showtext); library(ggrepel)

font_add_google("Roboto Condensed", "roboto")
showtext_auto()

REPO    <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
CSV_IN  <- file.path(REPO, "output/stage_a/Chile/csv")
FIG_OUT <- file.path(REPO, "output/stage_b/Chile/figs")
CSV_OUT <- file.path(REPO, "output/stage_b/Chile/csv")
TAB_OUT <- file.path(REPO, "output/stage_b/Chile/tables")

dir.create(FIG_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(CSV_OUT, recursive = TRUE, showWarnings = FALSE)
dir.create(TAB_OUT, recursive = TRUE, showWarnings = FALSE)

# Load Stage A panel
panel <- read_csv(file.path(CSV_IN, "stage2_panel_with_mu_v2.csv"))
cat("Panel columns:\n"); cat(names(panel), sep = "\n")
cat(sprintf("\nPanel rows: %d\n", nrow(panel)))
```

### Step 0b: Column mapping and variable construction

Print columns and confirm mapping before proceeding:

```r
# ---- Column mapping (adapt if names differ) ----
# Expected in panel: year, mu_CL, B_t, pi_t, p_rel, omega, r_t,
#   ln_r, ln_mu, ln_pi, g_r, ECT_m, k_CL, y, y_p_log

cat(sprintf("mu_CL range: [%.4f, %.4f]\n", min(panel$mu_CL, na.rm=T), max(panel$mu_CL, na.rm=T)))
cat(sprintf("p_rel range: [%.4f, %.4f]\n", min(panel$p_rel, na.rm=T), max(panel$p_rel, na.rm=T)))
cat(sprintf("B_t   range: [%.4f, %.4f]\n", min(panel$B_t,   na.rm=T), max(panel$B_t,   na.rm=T)))

# ---- Construct 4-channel variables ----
df_chile <- panel |>
  arrange(year) |>
  mutate(
    # Rename for prompt consistency
    r      = r_t,
    mu     = mu_CL,
    pi     = pi_t,
    B      = B_t,
    PyPK   = p_rel,

    # Real capital productivity: B = PyPK * B_real => B_real = B / PyPK
    B_real = B / PyPK,

    # Log-change contributions (4-channel additive in logs)
    dlnr    = c(NA, diff(ln_r)),
    phi_mu  = c(NA, diff(log(mu))),
    phi_PyPK = c(NA, diff(log(PyPK))),
    phi_Br  = c(NA, diff(log(B_real))),
    phi_pi  = c(NA, diff(log(pi))),

    # ISI regime label
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

# ---- Filter to analysis window ----
df_plot <- df_chile |> filter(year >= 1940, year <= 1978)
cat(sprintf("\nStage B panel: N=%d (1940-1978)\n", nrow(df_plot)))

# ---- Sanity checks on B_real ----
cat(sprintf("B_real range: [%.4f, %.4f]\n",
    min(df_plot$B_real, na.rm=T), max(df_plot$B_real, na.rm=T)))
# Expected: approximately [0.10, 0.30]
```

---

## SECTION 2 --- IDENTITY CHECKS (run before any figure)

```r
# 1. Additive log-change identity (4 channels)
check_additive <- max(abs(
  df_plot$phi_mu + df_plot$phi_PyPK + df_plot$phi_Br + df_plot$phi_pi
  - df_plot$dlnr), na.rm = TRUE)
cat(sprintf("Additive identity check (max |residual|): %.2e\n", check_additive))
stopifnot(check_additive < 1e-10)

# 2. Levels identity: B = PyPK * B_real
check_B_decomp <- max(abs(df_plot$B - df_plot$PyPK * df_plot$B_real), na.rm = TRUE)
cat(sprintf("B = PyPK * B_real check (max |residual|): %.2e\n", check_B_decomp))
stopifnot(check_B_decomp < 1e-6)

# 3. Full levels identity: r = mu * PyPK * B_real * pi
check_levels <- max(abs(
  df_plot$r - df_plot$mu * df_plot$PyPK * df_plot$B_real * df_plot$pi),
  na.rm = TRUE)
cat(sprintf("r = mu*PyPK*Br*pi check (max |residual|): %.2e\n", check_levels))
stopifnot(check_levels < 1e-6)

cat("\nAll identity checks passed.\n")
```

---

## SECTION 3 --- AXIS VISUALIZATION (MANDATORY, NON-NEGOTIABLE)

### 3.1 X-axis: annual labels, every year, 90 degree rotation

```r
scale_x_continuous(
  breaks       = 1940:1978,
  minor_breaks = NULL,
  labels       = 1940:1978
) +
theme(axis.text.x = element_text(
  angle = 90, vjust = 0.5, hjust = 1, size = 8, color = "#333333"
))
```

### 3.2 Y-axis: labeled, no suppression

```r
# Indexed level panels:
labs(y = "Index (1940 = 100)")

# Cumulative (B2a):
labs(y = "Cumulative delta-ln r")

# Annual bars (B2b):
labs(y = "delta-ln r (annual)")

# Swing composition (B3):
labs(x = "Share of total swing (%)", y = NULL)
scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                   breaks = c(-0.25, 0, 0.25, 0.5, 0.75, 1, 1.25))

# Profit rate (B4):
labs(y = expression(r[t] == Pi[t] / K[t]))
```

`axis.text.y` at `size = 10`. Do not suppress y-axis ticks.

### 3.3 Axis lines: restore

```r
theme(
  axis.line         = element_line(color = "#AAAAAA", linewidth = 0.4),
  axis.ticks        = element_line(color = "#AAAAAA", linewidth = 0.3),
  axis.ticks.length = unit(0.15, "cm")
)
```

### 3.4 Zoom via coord_cartesian only

```r
# B4 --- Chilean r is lower and more volatile than US:
coord_cartesian(ylim = c(0.03, 0.12))
# Adjust after inspecting data range.

# B1a-B1f: auto-scale unless outlier years distort
```

### 3.5 Grid lines

```r
theme(
  panel.grid.major.y = element_line(color = "#EEEEEE", linewidth = 0.3),
  panel.grid.major.x = element_blank(),
  panel.grid.minor   = element_blank()
)
```

---

## SECTION 4 --- GLOBAL DESIGN RULES

### 4.1 Base theme (identical to US)

```r
theme_stageB_CL <- theme_minimal(base_family = "roboto", base_size = 13) +
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
```

### 4.2 Channel colors --- Okabe-Ito (4 channels, mirrors US)

```r
ch_colors_CL <- c(
  "mu (demand)"          = "#0072B2",   # blue
  "Py/PK (rel. price)"   = "#CC79A7",   # pink
  "B_real (technology)"   = "#009E73",   # teal
  "pi (distribution)"     = "#D55E00"    # vermillion
)

# ISI regime colors --- distinct from US Fordist palette
regime_colors_CL <- c(
  "Pre-ISI/WWII"  = "#999999",   # gray
  "Early ISI"     = "#56B4E9",   # sky blue
  "Mid ISI"       = "#0072B2",   # blue
  "Late ISI"      = "#009E73",   # teal
  "Crisis"        = "#D95F02"    # orange
)
```

### 4.3 ISI regime bands and period window annotations

**Layer A --- ISI regime bands** (primary, applied first, behind all data):

Five ISI accumulation regime bands for B1a--B1f and B4.

```r
isi_bands <- tibble(
  xmin  = c(1940, 1946, 1954, 1962, 1973),
  xmax  = c(1945, 1953, 1961, 1972, 1978),
  fill  = c("#F5F5F5", "#EBF5FB", "#E8F8F5", "#FEF9E7", "#FDEDEC"),
  label = c("Pre-ISI\n/WWII", "Early\nISI", "Mid\nISI",
            "Late\nISI", "Crisis")
)

geom_rect(
  data = isi_bands,
  aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
  alpha = 0.40, inherit.aes = FALSE, show.legend = FALSE
) +
scale_fill_identity() +
annotate("text",
  x     = c(1942.5, 1949.5, 1957.5, 1967,  1975.5),
  y     = Inf,
  label = c("Pre-ISI\n/WWII", "Early\nISI", "Mid\nISI",
            "Late\nISI", "Crisis"),
  vjust = 1.4, hjust = 0.5, size = 2.8,
  color = "#555555", fontface = "italic"
)
```

**Layer B --- Period window annotations** (secondary):

The Allende period (1970--1973) and coup (1973).

```r
# Allende period boundary
geom_vline(xintercept = 1970, linetype = "dotted",
           color = "#BBBBBB", linewidth = 0.25) +
geom_vline(xintercept = 1973, linetype = "dotted",
           color = "#BBBBBB", linewidth = 0.25) +

annotate("text",
  x = 1971.5, y = Inf,
  label = "UP",
  vjust = 1.8, hjust = 0.5, size = 2.4,
  color = "#888888", fontface = "italic"
)
```

**Visual hierarchy:**
```
ISI regime bands (filled rectangles)          <- primary structure
Turning point verticals (dashed, labeled)     <- primary analytical
BoP constraint band (filled, alpha=0.18)      <- secondary structural
Period window boundaries (dotted, unlabeled)  <- tertiary contextual
Period window text (small, italic, top)       <- tertiary contextual
```

**Do NOT apply regime bands to B2a, B2b.**
**Do NOT apply period window annotations to B2a, B2b, B3.**

### 4.4 Export --- session dual-save helper

```r
save_fig <- function(fig, name, w = 12, h = 6) {
  ggsave(file.path(FIG_OUT, paste0(name, ".pdf")), fig,
         width = w, height = h, device = cairo_pdf)
  ggsave(file.path(FIG_OUT, paste0(name, ".png")), fig,
         width = w, height = h, dpi = 300)
  cat(sprintf("Saved: %s (.pdf + .png)\n", name))
}

W <- 12; H <- 6
```

---

## SECTION 5 --- BoP CONSTRAINT BAND: ECT_m OVERLAY

This section adds a time-varying shaded band to B1a--B1f and B4,
showing periods when the BoP constraint was binding according to
the Stage 1 TVECM threshold variable.

```r
# ECT_m is in the main panel as column ECT_m
# Threshold lambda from Stage A estimation
lambda_hat <- -0.1394

df_bop <- df_plot |>
  select(year, ECT_m) |>
  filter(!is.na(ECT_m)) |>
  mutate(
    constrained = ECT_m > lambda_hat,
    episode_id = cumsum(c(TRUE, diff(constrained) != 0))
  ) |>
  filter(constrained) |>
  group_by(episode_id) |>
  summarise(
    xmin = min(year) - 0.5,
    xmax = max(year) + 0.5,
    .groups = "drop"
  )

bop_layer <- geom_rect(
  data = df_bop,
  aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
  fill  = "#E74C3C",   # red --- BoP pressure
  alpha = 0.18,
  inherit.aes = FALSE,
  show.legend = FALSE
)

cat(sprintf("BoP constrained episodes: %d\n", nrow(df_bop)))
print(df_bop)
```

If ECT_m is unavailable or the series does not cover 1940--1978:
skip this section entirely and set `bop_layer <- NULL`.

---

## SECTION 6 --- FIGURE-SPECIFIC SPECS

### Index base year: 1940

```r
df_B1 <- df_plot |>
  mutate(across(c(r, mu, B, pi, PyPK, B_real),
    ~ . / .[year == 1940] * 100, .names = "{.col}_idx"))
```

### B1a--B1f --- Level panels (indexed 1940 = 100)

No LOESS. No titles. Layer order:

```r
# Template for B1 panels. Substitute variable_idx for each panel.
make_B1 <- function(df, var_idx, ylab = "Index (1940 = 100)") {
  ggplot(df, aes(x = year, y = .data[[var_idx]])) +
    # Layer 1: ISI regime bands
    geom_rect(data = isi_bands,
      aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
      alpha = 0.40, inherit.aes = FALSE, show.legend = FALSE) +
    scale_fill_identity() +
    # Layer 2: BoP constraint band
    bop_layer +
    # Layer 3: UP period window
    geom_vline(xintercept = 1970, linetype = "dotted",
               color = "#BBBBBB", linewidth = 0.25) +
    geom_vline(xintercept = 1973, linetype = "dotted",
               color = "#BBBBBB", linewidth = 0.25) +
    annotate("text", x = 1971.5, y = Inf, label = "UP",
             vjust = 1.8, hjust = 0.5, size = 2.4,
             color = "#888888", fontface = "italic") +
    # Layer 4: Gray continuous underlay
    geom_line(color = "#CCCCCC", linewidth = 0.5) +
    # Layer 5: Regime-colored overlay
    geom_line(aes(color = regime, group = regime), linewidth = 1.0) +
    scale_color_manual(values = regime_colors_CL) +
    # Layer 6: Reference line at 100
    geom_hline(yintercept = 100, linetype = "dashed",
               color = "#AAAAAA", linewidth = 0.4) +
    # Layer 7: Regime band top labels
    annotate("text",
      x = c(1942.5, 1949.5, 1957.5, 1967, 1975.5), y = Inf,
      label = c("Pre-ISI\n/WWII", "Early\nISI", "Mid\nISI",
                "Late\nISI", "Crisis"),
      vjust = 1.4, hjust = 0.5, size = 2.8,
      color = "#555555", fontface = "italic") +
    # Layer 8: End-of-line labels
    geom_text_repel(
      data = df |> group_by(regime) |> slice_max(year, n = 1),
      aes(label = regime, color = regime),
      direction = "y", hjust = 0, nudge_x = 0.4,
      size = 3.2, segment.size = 0.3, show.legend = FALSE) +
    scale_x_continuous(breaks = 1940:1978, minor_breaks = NULL,
                       labels = 1940:1978) +
    labs(y = ylab) +
    theme(legend.position = "none")
}

fig_CL_B1a <- make_B1(df_B1, "r_idx")
fig_CL_B1b <- make_B1(df_B1, "mu_idx")
fig_CL_B1c <- make_B1(df_B1, "B_idx")       # nominal B, reference only
fig_CL_B1d <- make_B1(df_B1, "pi_idx")
fig_CL_B1e <- make_B1(df_B1, "PyPK_idx")
fig_CL_B1f <- make_B1(df_B1, "B_real_idx")
```

**B1c special note:** This is nominal capital productivity, NOT real.
The caption in LaTeX must state "nominal" explicitly.

---

### B2a --- Cumulative contributions (4 channels, ribbon)

```r
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
  # Distributional overdetermination annotation
  annotate("rect", xmin = 1969, xmax = 1974,
           ymin = -Inf, ymax = Inf, fill = "#FFF3E0", alpha = 0.5) +
  annotate("text", x = 1971.5, y = Inf,
           label = "Distributional\noverdetermination",
           vjust = 1.4, size = 2.8, color = "#D95F02", fontface = "italic") +
  # End-of-line labels
  geom_text_repel(
    data = df_cum_long_CL |> group_by(channel) |> slice_max(year, n = 1),
    aes(x = year, y = value, label = channel, color = channel),
    direction = "y", hjust = 0, nudge_x = 0.4,
    size = 3.2, segment.size = 0.3, show.legend = FALSE,
    inherit.aes = FALSE) +
  scale_color_manual(values = ch_colors_CL) +
  theme(legend.position = "none")
```

---

### B2b --- Annual bars (1940--1978, 4 channels)

```r
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
```

---

### B3 --- Swing composition (normalized 100% bars, 9 swings, 4 channels)

Nine turning points: 1946, 1947, 1953, 1961, 1969, 1972, 1974, 1975, 1978.

```r
# ---- Step 1: Identify turning points and compute swings ----
turning_years <- c(1940, 1946, 1947, 1953, 1961, 1969, 1972, 1974, 1975, 1978)

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

df_swings_CL <- purrr::map_dfr(swings, function(sw) {
  s_idx <- which(df_plot$year == sw$start)
  e_idx <- which(df_plot$year == sw$end)
  if (length(s_idx) == 0 || length(e_idx) == 0) return(NULL)

  # Compounded log-change over the swing
  delta_lnr  <- log(df_plot$r[e_idx])  - log(df_plot$r[s_idx])
  delta_mu   <- log(df_plot$mu[e_idx]) - log(df_plot$mu[s_idx])
  delta_PyPK <- log(df_plot$PyPK[e_idx]) - log(df_plot$PyPK[s_idx])
  delta_Br   <- log(df_plot$B_real[e_idx]) - log(df_plot$B_real[s_idx])
  delta_pi   <- log(df_plot$pi[e_idx]) - log(df_plot$pi[s_idx])

  # Shares of total log-change
  s_mu   <- delta_mu   / delta_lnr
  s_PyPK <- delta_PyPK / delta_lnr
  s_Br   <- delta_Br   / delta_lnr
  s_pi   <- delta_pi   / delta_lnr

  tibble(
    swing      = sw$label,
    type       = ifelse(delta_lnr > 0, "Expansion", "Contraction"),
    delta_lnr  = delta_lnr,
    s_mu       = s_mu,
    s_PyPK     = s_PyPK,
    s_Br       = s_Br,
    s_pi       = s_pi,
    check_sum  = s_mu + s_PyPK + s_Br + s_pi
  )
})

# Identity check: swing shares sum to unity
stopifnot(all(abs(df_swings_CL$check_sum - 1) < 1e-10))

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
print(df_swings_CL)

write_csv(df_swings_CL, file.path(CSV_OUT, "stageB_CL_swing_decomposition_4ch.csv"))
```

```r
# ---- Step 2: Build B3 figure ----
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
    delta_r_label = sprintf("delta-lnr=%+.3f", delta_lnr)
  )

fig_CL_B3 <- ggplot(df_swings_long_CL,
                     aes(x = share, y = fct_rev(swing), fill = channel)) +
  geom_col(position = "stack", alpha = 0.85) +
  geom_vline(xintercept = c(0, 1), linetype = "dotted", color = "grey40") +
  # 100% reference line
  geom_vline(xintercept = 1.0, linetype = "dashed",
             color = "#CCCCCC", linewidth = 0.4) +
  scale_fill_manual(values = ch_colors_CL) +
  scale_x_continuous(
    labels = scales::percent_format(accuracy = 1),
    breaks = c(-0.25, 0, 0.25, 0.5, 0.75, 1, 1.25),
    expand = expansion(add = c(0.08, 0.35))
  ) +
  # Magnitude annotation at right edge
  geom_text(
    data = df_swings_CL,
    aes(x = 1.0, y = fct_rev(swing),
        label = sprintf("delta-lnr=%+.3f", delta_lnr)),
    hjust = -0.1, size = 3, inherit.aes = FALSE) +
  labs(
    x = "Share of total swing (%)", y = NULL, fill = NULL
  ) +
  theme(
    plot.margin = margin(5, 90, 5, 140, unit = "pt"),
    legend.position = c(0.85, 0.15),
    legend.background = element_rect(fill = "white", color = NA),
    legend.key.size = unit(0.4, "cm"))
```

---

### B4 --- Profit rate with turning points

```r
# Turning point classification
df_turning_CL <- df_plot |>
  filter(year %in% c(1946, 1947, 1953, 1961, 1969, 1972, 1974, 1975, 1978))

df_peaks_CL <- df_turning_CL |>
  filter(year %in% c(1946, 1953, 1969, 1974, 1978))

df_troughs_CL <- df_turning_CL |>
  filter(year %in% c(1947, 1961, 1972, 1975))
# Note: Adjust peak/trough classification after inspecting r_t series.
# The above is tentative based on Chilean macro history.

fig_CL_B4 <- ggplot(df_plot, aes(x = year, y = r)) +
  # Layer 1: ISI regime bands
  geom_rect(data = isi_bands,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
    alpha = 0.40, inherit.aes = FALSE, show.legend = FALSE) +
  scale_fill_identity() +
  # Layer 2: BoP constraint band
  bop_layer +
  # Layer 3: UP period window
  geom_vline(xintercept = 1970, linetype = "dotted",
             color = "#BBBBBB", linewidth = 0.25) +
  geom_vline(xintercept = 1973, linetype = "dotted",
             color = "#BBBBBB", linewidth = 0.25) +
  annotate("text", x = 1971.5, y = Inf, label = "UP",
           vjust = 1.8, hjust = 0.5, size = 2.4,
           color = "#888888", fontface = "italic") +
  # Layer 4: Gray continuous underlay
  geom_line(color = "#CCCCCC", linewidth = 0.6) +
  # Layer 5: Regime-colored overlay
  geom_line(aes(color = regime, group = regime), linewidth = 1.1) +
  scale_color_manual(values = regime_colors_CL) +
  # Layer 6: Turning points --- peaks (triangle up) and troughs (triangle down)
  geom_point(data = df_peaks_CL,
             shape = 24, fill = "#D55E00", color = "#D55E00", size = 3) +
  geom_point(data = df_troughs_CL,
             shape = 25, fill = "#0072B2", color = "#0072B2", size = 3) +
  ggrepel::geom_label_repel(data = df_turning_CL,
    aes(label = year), label.size = 0, fill = "white",
    size = 3, min.segment.length = 0, box.padding = 0.3) +
  # Layer 7: Regime band top labels
  annotate("text",
    x = c(1942.5, 1949.5, 1957.5, 1967, 1975.5), y = Inf,
    label = c("Pre-ISI\n/WWII", "Early\nISI", "Mid\nISI",
              "Late\nISI", "Crisis"),
    vjust = 1.4, hjust = 0.5, size = 2.8,
    color = "#555555", fontface = "italic") +
  coord_cartesian(ylim = c(0.03, 0.12)) +
  scale_x_continuous(breaks = 1940:1978, labels = 1940:1978) +
  labs(y = expression(r[t] == Pi[t] / K[t])) +
  # End-of-line labels
  geom_text_repel(
    data = df_plot |> group_by(regime) |> slice_max(year, n = 1),
    aes(label = regime, color = regime),
    direction = "y", hjust = 0, nudge_x = 0.4,
    size = 3.2, segment.size = 0.3, show.legend = FALSE) +
  theme(legend.position = "none")
```

---

## SECTION 7 --- SUB-PERIOD AVERAGES (Table B4 data)

```r
subperiods <- list(
  "Pre-ISI/WWII" = c(1940, 1945),
  "Early ISI"    = c(1946, 1953),
  "Mid ISI"      = c(1954, 1961),
  "Late ISI"     = c(1962, 1972),
  "Crisis"       = c(1973, 1978)
)

tab_subperiod <- purrr::map_dfr(names(subperiods), function(nm) {
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
write_csv(tab_subperiod, file.path(CSV_OUT, "stageB_CL_subperiod_averages_4ch.csv"))
```

---

## SECTION 8 --- EXPORT ALL FIGURES

```r
save_fig(fig_CL_B1a, "fig_CL_B1a_r_levels",                  w = W, h = H)
save_fig(fig_CL_B1b, "fig_CL_B1b_mu_levels",                 w = W, h = H)
save_fig(fig_CL_B1c, "fig_CL_B1c_B_levels",                  w = W, h = H)
save_fig(fig_CL_B1d, "fig_CL_B1d_pi_levels",                 w = W, h = H)
save_fig(fig_CL_B1e, "fig_CL_B1e_PyPK_levels",               w = W, h = H)
save_fig(fig_CL_B1f, "fig_CL_B1f_Breal_levels",              w = W, h = H)
save_fig(fig_CL_B2a, "fig_CL_B2a_cumulative",                w = W, h = H)
save_fig(fig_CL_B2b, "fig_CL_B2b_annual_bars",               w = W, h = H)
save_fig(fig_CL_B3,  "fig_CL_B3_swing_composition",          w = W, h = H)
save_fig(fig_CL_B4,  "fig_CL_B4_profit_rate_turning_points", w = W, h = H)
```

---

## SECTION 9 --- SAVE FULL STAGE B PANEL

```r
# Save updated panel with 4-channel columns
df_export <- df_plot |>
  select(year, r, mu, B, PyPK, B_real, pi, dlnr,
         phi_mu, phi_PyPK, phi_Br, phi_pi,
         regime, ECT_m, theta_CL, omega)

write_csv(df_export, file.path(CSV_OUT, "stageB_CL_panel_1940_1978_4ch.csv"))
cat("Stage B 4-channel panel saved.\n")
```

---

## SECTION 10 --- LaTeX TABLE SPECS

### Table B4 --- Sub-period arithmetic means of level components

**File:** `output/stage_b/Chile/tables/tab_B4_subperiod_CL.tex`

7 columns, `\small`, no `\adjustbox`.

Column header:
```latex
Period & Years & $\bar{r}$ & $\bar{\mu}$ & $\overline{Py/PK}$ & $\bar{B}_{r}$ & $\bar{\pi}$
```

`\midrule` after row 1 and after row 4. No dagger rows.

**Caption:**
```latex
\caption{Weisskopf components: sub-period means, Chile, 1940--1978.}
\label{tab:B4_subperiod_CL}
```

**Notes:**
```latex
\item \textit{Notes:}
  Period arithmetic means of level variables.
  $r = \Pi/K$ (nominal profit rate);
  $\hat{\mu}$ from Stage~A MPF (capacity utilization);
  $Py/PK$ = GDP deflator / capital price deflator (relative output-to-capital price);
  $B_{r} = Y^{p}_{r}/K$ (real capital productivity at normal capacity);
  $\pi = \Pi/Y$ (profit share).
  Exact identity in levels: $r \equiv \hat{\mu} \cdot (Py/PK) \cdot B_{r} \cdot \pi$.
```

### Table B5 --- Shares of compounded log-change per swing

**File:** `output/stage_b/Chile/tables/tab_B5_peaktotrough_CL.tex`

9 columns. `\adjustbox{max width=\textwidth}` + `\small`.

Column header:
```latex
Period & Type & $\Delta\ln r$ & $s_{\mu}$ & $s_{Py/PK}$ & $s_{B_{r}}$ & $s_{\pi}$ & $\Sigma$ & Dominant
```

Negative shares: italics + dagger (same as US).
pi > 1.0 in 1972--74: dominant cell reads `$\pi^{*}$` with note.
`\addlinespace[3pt]` between every type change.

**Caption:**
```latex
\caption{Four-channel decomposition of profit-rate swings,
  Chile, 1940--1978.}
\label{tab:B5_peaktotrough_CL}
```

**Notes:**
```latex
\item \textit{Notes:}
  $s_{j} = \varphi^{j}/\Delta\ln r$ (share of total compounded log-change);
  $s_{\mu} + s_{Py/PK} + s_{B_{r}} + s_{\pi} = 1$ (exact).
  $\varphi^{j} = \sum_{t \in \text{swing}} \Delta\ln x_{j,t}$:
  $\varphi^{\mu} = \Delta\ln\hat{\mu}$,
  $\varphi^{Py/PK} = \Delta\ln(Py/PK)$,
  $\varphi^{B_{r}} = \Delta\ln B_{r}$,
  $\varphi^{\pi} = \Delta\ln\pi$.
\item[$\dagger$] Offsetting channel: contribution moves against the
  swing direction ($s_{j} < 0$).
\item[$*$] Share exceeds unity: channel more than accounts for total swing;
  remaining channels are jointly offsetting.
```

---

## SECTION 11 --- SHARED SOURCE NOTE (for LaTeX body)

Place once in the chapter before the first figure reference:

```latex
\textit{Note on figures:} All figures cover Chile, 1940--1978.
$r_{t} = \Pi_{t}/K_{t}$; $\hat{\mu}_{t}$ from Stage~A MPF;
$B_{r,t} = \text{GVA}_{r,t}/(\text{KNR}_{t}\cdot\hat{\mu}_{t})$
(real capital productivity);
$Py/PK_{t}$ = GDP deflator / capital price deflator;
$\pi_{t} = \Pi_{t}/Y_{t}$.
Four-channel identity: $r = \mu \cdot (Py/PK) \cdot B_{r} \cdot \pi$ (exact).
Regime shading: Pre-ISI/WWII (1940--1945), Early ISI (1946--1953),
Mid ISI (1954--1961), Late ISI (1962--1972), Crisis (1973--1978).
Red shading: BoP-constrained periods ($\widehat{ECT}_{m,t-1} > \hat{\lambda}$).
Period window: Unidad Popular (1970--1973).
```

**Parsimonious figure captions:**

```latex
% B1a:
\caption{Profit rate $r_{t}$, indexed 1940\,=\,100, Chile, 1940--1978.}
\label{fig:CL_B1a}

% B1b:
\caption{Capacity utilization $\hat{\mu}_{t}$, indexed 1940\,=\,100,
  Chile, 1940--1978.}
\label{fig:CL_B1b}

% B1c:
\caption{Nominal capital productivity $B_{t}$, indexed 1940\,=\,100,
  Chile, 1940--1978.}
\label{fig:CL_B1c}

% B1d:
\caption{Profit share $\pi_{t}$, indexed 1940\,=\,100,
  Chile, 1940--1978.}
\label{fig:CL_B1d}

% B1e:
\caption{Relative price $Py/PK_{t}$, indexed 1940\,=\,100,
  Chile, 1940--1978.}
\label{fig:CL_B1e}

% B1f:
\caption{Real capital productivity $B_{r,t}$, indexed 1940\,=\,100,
  Chile, 1940--1978.}
\label{fig:CL_B1f}

% B2a:
\caption{Cumulative four-channel contributions to profit-rate growth,
  Chile, 1940--1978.}
\label{fig:CL_B2a}

% B2b (appendix):
\caption{Annual four-channel contributions to profit-rate growth,
  Chile, 1940--1978.}
\label{fig:CL_B2b}

% B3:
\caption{Channel composition of profit-rate swings, Chile, 1940--1978.}
\label{fig:CL_B3}

% B4:
\caption{Profit rate with identified turning points, Chile, 1940--1978.}
\label{fig:CL_B4}
```

---

## SECTION 12 --- POST-SAVE VERIFICATION

1. **B3 negative bars (1972--74):** The pi bar extends past 100%.
   The 100% reference line (dashed gray) is visible. Offsetting channels
   extend to the left of zero for that row.

2. **B3 magnitude labels:** All 9 swing labels visible.
   Largest swing (1947--53, +0.732) label does not truncate.

3. **B4 turning points:** All 9 turning points labeled (1946, 1947,
   1953, 1961, 1969, 1972, 1974, 1975, 1978). No label overlaps
   the UP period window annotation.

4. **Axis labels:** All 39 year labels (1940--1978) visible and
   non-overlapping. No year skipped.

5. **ISI regime bands:** Five distinct fills visible. UP dotted
   boundaries (1970, 1973) lighter than turning-point dashed verticals.

6. **Channel color consistency with US:** mu blue (#0072B2),
   PyPK pink (#CC79A7), B_real teal (#009E73), pi vermillion (#D55E00).
   A reader comparing the two B3 figures should immediately recognize
   the channel colors without reading the legend.

7. **B_real plausibility:** Values in approximately [0.10, 0.30].
   If outside this range, check p_rel and B_t construction.

8. **Identity residuals:** All three identity checks below 1e-6.

---

## SECTION 13 --- FINAL REPORT

```r
cat("\n================================================================\n")
cat("  CHILE STAGE B --- 4-CHANNEL PROFITABILITY ANALYSIS CROSSWALK\n")
cat("================================================================\n")
cat(sprintf("Window:      1940-1978 (N=%d)\n", nrow(df_plot)))
cat(sprintf("Identity:    r = mu * PyPK * B_real * pi\n"))
cat(sprintf("  Additive:  max|residual| = %.2e\n", check_additive))
cat(sprintf("  B decomp:  max|residual| = %.2e\n", check_B_decomp))
cat(sprintf("  Levels:    max|residual| = %.2e\n", check_levels))
cat("\nSub-period profit rate means:\n")
print(tab_subperiod |> select(period, r_mean, mu_mean, PyPK_mean, Br_mean, pi_mean))
cat("\nSwing dominant channels:\n")
print(df_swings_CL |> select(swing, type, delta_lnr, dominant))
cat("\nOutputs:\n")
for (f in c(
  "stageB_CL_panel_1940_1978_4ch.csv",
  "stageB_CL_subperiod_averages_4ch.csv",
  "stageB_CL_swing_decomposition_4ch.csv",
  "fig_CL_B1a_r_levels.pdf", "fig_CL_B1b_mu_levels.pdf",
  "fig_CL_B1c_B_levels.pdf", "fig_CL_B1d_pi_levels.pdf",
  "fig_CL_B1e_PyPK_levels.pdf", "fig_CL_B1f_Breal_levels.pdf",
  "fig_CL_B2a_cumulative.pdf", "fig_CL_B2b_annual_bars.pdf",
  "fig_CL_B3_swing_composition.pdf",
  "fig_CL_B4_profit_rate_turning_points.pdf")) {
  cat(sprintf("  %s\n", f))
}
cat("================================================================\n")
```

---

*Merged prompt | 2026-04-09 | Chile Stage B 4-Channel Profitability Analysis*
*Sources: prompt_stageB_Chile_FINAL.md + prompt_stageB_Chile_4ch_addendum.md*
*Window: 1940--1978 | Identity: r = mu * (Py/PK) * B_real * pi*
*Output: output/stage_b/Chile/{csv,figs,tables}/*
