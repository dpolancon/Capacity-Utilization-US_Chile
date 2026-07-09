# Stage B Chile Figures — Master Prompt (Final)
## Date: 2026-04-08
## Mirrors: prompt_stageB_US_FINAL.md
## Key differences from US: 3-channel (no PyPK), ISI regime bands,
##   9 swings (not 7), base year 1940 (not 1947), Chilean data sources

---

## FIGURES LIST — 8 standalone files, no panels in R

Every figure is a **single standalone file**. LaTeX handles all panel
assembly and layout.

| Content | Filename | LaTeX group |
|---|---|---|
| Profit rate r (levels, indexed) | `fig_CL_B1a_r_levels` | B1 panel |
| Capacity utilization μ (levels, indexed) | `fig_CL_B1b_mu_levels` | B1 panel |
| Capital productivity B (levels, indexed) | `fig_CL_B1c_B_levels` | B1 panel |
| Profit share π (levels, indexed) | `fig_CL_B1d_pi_levels` | B1 panel |
| Cumulative contributions | `fig_CL_B2a_cumulative` | standalone |
| Annual bar contributions | `fig_CL_B2b_annual_bars` | standalone |
| Swing composition | `fig_CL_B3_swing_composition` | standalone |
| Profit rate + turning points | `fig_CL_B4_profit_rate_turning_points` | standalone |

All to `outputs/stage_b/Chile/figures/`.
No θ/μ bridge. No PyPK figure — the three-channel decomposition does not
separate the relative price component.

---

## SECTION 1 — ANALYSIS WINDOW AND DATA

**Primary window: 1940–1978**, inclusive. N=39.

```r
df_plot <- df_chile |> filter(year >= 1940, year <= 1978)
```

**Three-channel identity:** r = μ × B × π (exact, no residual).
Channels: phi_mu, phi_B, phi_pi. No phi_PyPK column.

**Variable names — confirm before running:**

| Object | Expected column name |
|---|---|
| Profit rate | `r` |
| Capacity utilization | `mu` |
| Capital productivity (nominal) | `B` |
| Profit share | `pi` |
| Annual log-change in r | `dlnr` |
| μ channel contribution | `phi_mu` |
| B channel contribution | `phi_B` |
| π channel contribution | `phi_pi` |
| ISI regime label | `regime` |

Print `names(df_chile)` and `head(df_chile)` before any figure code.
If column names differ, substitute throughout.

**Cumulative figure (B2a):**

```r
df_cum <- df_chile |>
  filter(year >= 1940, year <= 1978) |>
  arrange(year) |>
  mutate(
    cum_mu  = cumsum(replace_na(phi_mu, 0)),
    cum_B   = cumsum(replace_na(phi_B,  0)),
    cum_pi  = cumsum(replace_na(phi_pi, 0)),
    cum_r   = cumsum(replace_na(dlnr,   0))
  )
```

**Index base year: 1940** (not 1947 as in the US). First observation
in the data is 1940; index at 1940 = 100.

```r
df_B1 <- df_plot |>
  mutate(across(c(r, mu, B, pi),
    ~ . / .[year == 1940] * 100, .names = "{.col}_idx"))
```

---

## SECTION 2 — AXIS VISUALIZATION (MANDATORY, NON-NEGOTIABLE)

Identical requirements to the US prompt. All enforced without exception.

### 2.1 X-axis: annual labels, every year, 90° rotation

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

### 2.2 Y-axis: labeled, no suppression

```r
# Indexed level panels:
labs(y = "Index (1940 = 100)")

# Cumulative (B2a):
labs(y = "Cumulative Δln r")

# Annual bars (B2b):
labs(y = "Δln r (annual)")

# Swing composition (B3):
labs(x = "Share of total swing (%)", y = NULL)
scale_x_continuous(labels = scales::percent_format(accuracy = 1),
                   breaks = c(0, 0.25, 0.5, 0.75, 1))

# Profit rate (B4):
labs(y = expression(r[t] == Pi[t] / K[t]))
```

`axis.text.y` at `size = 10`. Do not suppress y-axis ticks.

### 2.3 Axis lines: restore

```r
theme(
  axis.line         = element_line(color = "#AAAAAA", linewidth = 0.4),
  axis.ticks        = element_line(color = "#AAAAAA", linewidth = 0.3),
  axis.ticks.length = unit(0.15, "cm")
)
```

### 2.4 Zoom via coord_cartesian only

```r
# B4 — Chilean r is lower and more volatile than US:
coord_cartesian(ylim = c(0.03, 0.12))

# B1b (μ) — check for outlier years; use auto-scale first,
# then apply coord_cartesian if WWII or coup years distort:
# coord_cartesian(ylim = c(70, 130))   # adjust after inspection

# B1a, B1c, B1d: auto-scale
```

### 2.5 Grid lines

```r
theme(
  panel.grid.major.y = element_line(color = "#EEEEEE", linewidth = 0.3),
  panel.grid.major.x = element_blank(),
  panel.grid.minor   = element_blank()
)
```

---

## SECTION 3 — GLOBAL DESIGN RULES

### 3.1 Base theme (identical to US)

```r
library(showtext)
font_add_google("Roboto Condensed", "roboto")
showtext_auto()

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

### 3.2 Channel colors — Okabe-Ito (three channels only)

The US used four channels. Chile uses three. Drop the PyPK color.
Keep the same colors for shared channels so cross-country visual
comparison is immediate.

```r
ch_colors_CL <- c(
  "μ (demand)"       = "#0072B2",   # same blue as US
  "B (technology)"   = "#009E73",   # same teal as US B_real
  "π (distribution)" = "#D55E00"    # same vermillion as US
)

# ISI regime colors — distinct from US Fordist palette
regime_colors_CL <- c(
  "Pre-ISI/WWII"  = "#999999",   # gray
  "Early ISI"     = "#56B4E9",   # sky blue
  "Mid ISI"       = "#0072B2",   # blue
  "Late ISI"      = "#009E73",   # teal
  "Crisis"        = "#D95F02"    # orange
)
```

### 3.3 ISI regime bands and period window annotations

**Layer A — ISI regime bands** (primary, applied first, behind all data):

Five ISI accumulation regime bands for B1a–B1d and B4.

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

**Layer B — Period window annotations** (secondary, subordinate to
turning points):

The Allende period (1970–1973) and coup (1973) are analytically
important sub-windows within the Late ISI and Crisis bands. Mark with
dotted lines, not filled bands — they are sub-windows within an
existing band, not separate regime phases.

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

"UP" = Unidad Popular. Single label centered in the 1970–1973 window.
The 1973 dotted line coincides with the Crisis regime band start —
this is correct and intentional.

**Visual hierarchy:**
```
ISI regime bands (filled rectangles)          ← primary structure
Turning point verticals (dashed, labeled)     ← primary analytical
Period window boundaries (dotted, unlabeled)  ← secondary contextual
Period window text (small, italic, top)       ← secondary contextual
```

**Do NOT apply regime bands to B2a, B2b.**
**Do NOT apply period window annotations to B2a, B2b, B3.**

### 3.4 Export — session dual-save helper

```r
W <- 12; H <- 6

save_fig(fig_CL_B1a, "fig_CL_B1a_r_levels",                  w = W, h = H)
save_fig(fig_CL_B1b, "fig_CL_B1b_mu_levels",                 w = W, h = H)
save_fig(fig_CL_B1c, "fig_CL_B1c_B_levels",                  w = W, h = H)
save_fig(fig_CL_B1d, "fig_CL_B1d_pi_levels",                 w = W, h = H)
save_fig(fig_CL_B2a, "fig_CL_B2a_cumulative",                w = W, h = H)
save_fig(fig_CL_B2b, "fig_CL_B2b_annual_bars",               w = W, h = H)
save_fig(fig_CL_B3,  "fig_CL_B3_swing_composition",          w = W, h = H)
save_fig(fig_CL_B4,  "fig_CL_B4_profit_rate_turning_points", w = W, h = H)
```

---

## SECTION 4 — FIGURE-SPECIFIC SPECS

### B1a–B1d — Level panels (indexed 1940 = 100)

No LOESS. No titles. Layer order identical to US B1 spec:

```r
# 1. ISI regime bands + Allende window (Section 3.3)
# 2. Continuous gray underlay
geom_line(color = "#CCCCCC", linewidth = 0.5) +
# 3. Regime-colored overlay
geom_line(aes(color = regime, group = regime), linewidth = 1.0) +
scale_color_manual(values = regime_colors_CL) +
# 4. Reference line at 100
geom_hline(yintercept = 100, linetype = "dashed",
           color = "#AAAAAA", linewidth = 0.4)
```

End-of-line labels, no legend box:

```r
library(ggrepel)
df_labels_CL <- df_plot |> group_by(regime) |> slice_max(year, n = 1)

geom_text_repel(
  data = df_labels_CL, aes(label = regime, color = regime),
  direction = "y", hjust = 0, nudge_x = 0.4,
  size = 3.2, segment.size = 0.3, show.legend = FALSE
) +
theme(legend.position = "none")
```

**B1c special note (B nominal):** The Chilean B is nominal capital
productivity — not deflated as in the US B_real. The caption must
state "nominal" explicitly. Do not label this panel "B_real."

---

### B2a — Cumulative contributions (3 channels, ribbon)

```r
df_cum_long_CL <- df_cum |>
  pivot_longer(cols = c(cum_mu, cum_B, cum_pi),
               names_to = "channel", values_to = "value") |>
  mutate(channel = recode(channel,
    "cum_mu"  = "μ (demand)",
    "cum_B"   = "B (technology)",
    "cum_pi"  = "π (distribution)"))

ggplot(df_cum_long_CL, aes(x = year, fill = channel, group = channel)) +
  geom_ribbon(aes(ymin = pmin(value, 0), ymax = pmax(value, 0)),
              alpha = 0.72, position = "identity") +
  geom_hline(yintercept = 0, color = "#333333", linewidth = 0.6) +
  geom_line(data = df_cum, aes(x = year, y = cum_r),
            color = "black", linewidth = 1.0, inherit.aes = FALSE) +
  scale_fill_manual(values = ch_colors_CL) +
  scale_x_continuous(breaks = 1940:1978, labels = 1940:1978) +
  labs(y = "Cumulative Δln r") +
  # Allende period annotation — NOT a crisis onset box,
  # but a distributional overdetermination marker
  annotate("rect", xmin = 1969, xmax = 1974,
           ymin = -Inf, ymax = Inf, fill = "#FFF3E0", alpha = 0.5) +
  annotate("text", x = 1971.5, y = Inf,
           label = "Distributional\noverdetermination",
           vjust = 1.4, size = 2.8, color = "#D95F02", fontface = "italic")
```

End-of-line labels at right edge (same spec as US B2a).

---

### B2b — Annual bars (1940–1978, 3 channels)

```r
ggplot(df_annual_long_CL, aes(x = year, y = value, fill = channel)) +
  geom_col(position = "stack", width = 0.75,
           color = "white", linewidth = 0.1) +
  geom_point(data = df_annual_CL, aes(x = year, y = dlnr),
             shape = 21, fill = "white", color = "#333333",
             size = 1.6, inherit.aes = FALSE) +
  geom_hline(yintercept = 0, color = "#333333", linewidth = 0.5) +
  scale_fill_manual(values = ch_colors_CL) +
  scale_x_continuous(breaks = 1940:1978, labels = 1940:1978) +
  labs(y = "Δln r (annual)") +
  theme(legend.position  = c(0.85, 0.88),
        legend.background = element_rect(fill = "white", color = NA),
        legend.key.size   = unit(0.4, "cm"))
```

---

### B3 — Swing composition (normalized 100% bars, 9 swings)

Nine swings rather than seven. The bar with π > 100% (1972–74,
π = 115%) must be handled: use the actual share value — do not cap
at 100% or clip. The offsetting channels (μ and B negative in that
swing) will appear as negative bars to the left of zero.

```r
theme(plot.margin = margin(5, 90, 5, 140, unit = "pt"))
# Left margin wider than US (140 vs 130) — "1972-1974" label is longer

scale_x_continuous(
  labels = scales::percent_format(accuracy = 1),
  breaks = c(-0.25, 0, 0.25, 0.5, 0.75, 1, 1.25),
  expand = expansion(add = c(0.05, 0.35))
  # Left expansion for negative bars (1972-74 offsetting channels)
  # Right expansion for magnitude annotation labels
) +
labs(x = "Share of total swing (%)", y = NULL)
```

**Critical — the 1972–74 row:** π = 115% extends beyond the 100% mark.
Include a vertical reference line at x = 1.0 (dashed, light gray) to
mark the 100% boundary, so the reader can immediately see which swing
has an overcompensating dominant channel.

```r
geom_vline(xintercept = 1.0, linetype = "dashed",
           color = "#CCCCCC", linewidth = 0.4)
```

Magnitude annotation format: `sprintf("Δlnr=%+.3f", delta_lnr)`.
Right-expand to 0.35 — the label for 1947–1953 (+0.732, the largest
swing) is the longest and must be fully visible.

Legend inside plot at bottom-right. No end-of-line labels.

---

### B4 — Profit rate with turning points

Nine turning points: 1946, 1947, 1953, 1961, 1969, 1972, 1974,
1975, 1978.

```r
ggplot(df_plot, aes(x = year, y = r)) +
  # 1. ISI regime bands + Allende window (Section 3.3)
  # 2. Gray continuous underlay
  geom_line(color = "#CCCCCC", linewidth = 0.6) +
  # 3. Regime-colored overlay
  geom_line(aes(color = regime, group = regime), linewidth = 1.1) +
  scale_color_manual(values = regime_colors_CL) +
  # 4. Turning points — peaks (▲) and troughs (▽)
  geom_point(data = df_peaks_CL,
             shape = 24, fill = "#D55E00", color = "#D55E00", size = 3) +
  geom_point(data = df_troughs_CL,
             shape = 25, fill = "#0072B2", color = "#0072B2", size = 3) +
  ggrepel::geom_label_repel(data = df_turning_CL,
    aes(label = year), label.size = 0, fill = "white",
    size = 3, min.segment.length = 0, box.padding = 0.3) +
  coord_cartesian(ylim = c(0.03, 0.12)) +
  scale_x_continuous(breaks = 1940:1978, labels = 1940:1978) +
  labs(y = expression(r[t] == Pi[t] / K[t])) +
  geom_text_repel(data = df_labels_CL,
    aes(label = regime, color = regime),
    direction = "y", hjust = 0, nudge_x = 0.4,
    size = 3.2, segment.size = 0.3, show.legend = FALSE) +
  theme(legend.position = "none")
```

**Note on ylim:** Chilean profit rates are much lower than US
(0.05–0.09 vs 0.13–0.28). Adjust `coord_cartesian(ylim)` after
inspecting the data range — the range above is indicative.

---

## SECTION 5 — PARSIMONY RULES (identical to US)

**Rule 1 — Caption = what + when + where. One sentence.**
**Rule 2 — Notes = two items maximum per table.**
**Rule 3 — No repetition across caption and notes.**
**Rule 4 — Shared source note for figures.**

Place once in §2.6.3 before the first figure reference:

```latex
\textit{Note on figures:} All figures cover Chile, 1940--1978.
$r_{t} = \Pi_{t}/K_{t}$ (aggregate profit rate);
$\hat{\mu}_{t}$ from Stage~A MPF;
$B_{t} = Y_{t}^{p}/K_{t}$ (nominal capital productivity);
$\pi_{t} = \Pi_{t}/Y_{t}$ (profit share).
Three-channel identity: $r = \mu \cdot B \cdot \pi$ (exact).
Regime shading: Pre-ISI/WWII (1940--1945), Early ISI (1946--1953),
Mid ISI (1954--1961), Late ISI (1962--1972), Crisis (1973--1978).
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

% B2a:
\caption{Cumulative three-channel contributions to profit-rate growth,
  Chile, 1940--1978.}
\label{fig:CL_B2a}

% B2b (appendix):
\caption{Annual three-channel contributions to profit-rate growth,
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

## SECTION 6 — TABLE SPECS

### Table B4 — Sub-period averages, Chile

**File:** `outputs/stage_b/Chile/tables/tab_B4_subperiod_CL.tex`

6 columns (no PyPK column). `\small`, no `\adjustbox` needed.

Columns: Period | Years | r̄ | μ̄ | B̄ | π̄

Data (pre-rounded to 3 decimal places):
```
Pre-ISI/WWII | 1940--1945 | 0.052 | 0.763 | 0.174 | 0.396
Early ISI    | 1946--1953 | 0.063 | 0.857 | 0.172 | 0.425
Mid ISI      | 1954--1961 | 0.069 | 0.870 | 0.166 | 0.477
Late ISI     | 1962--1972 | 0.060 | 0.927 | 0.155 | 0.418
Crisis       | 1973--1978 | 0.066 | 0.850 | 0.149 | 0.522
```

`\midrule` after row 1 (Pre-ISI / Early ISI boundary) and after row 4
(Late ISI / Crisis boundary). No `\addlinespace` rows — all five
periods are primary analytical periods.

**Caption:**
```latex
\caption{Weisskopf components: sub-period means, Chile, 1940--1978.}
\label{tab:B4_subperiod_CL}
```

**Notes:**
```latex
\item \textit{Notes:}
  $r = \Pi/K$ (nominal); $\hat{\mu}$ from Stage~A MPF;
  $B = Y^{p}/K$ (nominal capital productivity);
  $\pi = \Pi/Y$.
  Three-channel identity: $r = \mu \cdot B \cdot \pi$ (exact).
\item Three-channel decomposition; relative price channel
  ($Py/PK$) not separately identified for Chile over this window.
```

### Table B5 — Swing decomposition, Chile

**File:** `outputs/stage_b/Chile/tables/tab_B5_peaktotrough_CL.tex`

7 columns (not 9 — no PyPK or Σ columns needed since 3 channels
always sum to 1.000 exactly and none have negative shares except
1972–74). Wrap in `\adjustbox{max width=\textwidth}` and `\small`.

Columns: Period | Type | Δln r | s_μ | s_B | s_π | Dominant

Data (pre-rounded to 3 decimal places):

```
1940--1946 | Expansion   | +0.300 | 0.710 |  ?   | 0.290 | μ
1946--1947 | Contraction | -0.450 | ?     |  ?   | 0.660 | π
1947--1953 | Expansion   | +0.730 | ?     |  ?   | 0.800 | π
1953--1961 | Contraction | -0.590 | ?     |  ?   | 0.860 | π
1961--1969 | Recovery    | +0.400 | ?     |  ?   | 0.960 | π
1969--1972 | Contraction | -0.480 | ?     |  ?   | 1.000 | π
1972--1974 | Expansion   | +0.580 | ?     |  ?   | 1.150 | π
1974--1975 | Contraction | -0.330 | ?     | ?    | 0.540 | π
1975--1978 | Recovery    | +0.250 | 0.680 |  ?   | 0.320 | μ
```

The `?` entries must be filled from the actual CSV data in
`output/stage_b/Chile/csv/`. Read the CSV first:

```r
df_swings_CL <- read_csv(
  "output/stage_b/Chile/csv/stageB_Chile_table_B2_peaktotrough.csv"
)
print(df_swings_CL)
```

The dominant channel column:
- When π > 1.0 (1972–74): dominant cell reads `$\pi^{*}$` with a
  dagger footnote: "Channel share exceeds unity; offsetting channels
  drag against the swing direction."
- All other rows: `$\pi$` or `$\mu$` as appropriate.

`\addlinespace[3pt]` between every type change (expansion →
contraction → expansion etc.).

**Caption:**
```latex
\caption{Three-channel decomposition of profit-rate swings,
  Chile, 1940--1978.}
\label{tab:B5_peaktotrough_CL}
```

**Notes:**
```latex
\item \textit{Notes:}
  $\Delta\ln r = \phi^{\mu} + \phi^{B} + \phi^{\pi}$ (exact);
  $s_j$ sum to unity.
  $r = \Pi/K$; $B = Y^{p}/K$; $\pi = \Pi/Y$;
  $\hat{\mu}$ from Stage~A MPF.
\item[$*$] Share exceeds unity: the distribution channel more than
  reverses the combined drag from demand and technology channels.
```

---

## SECTION 7 — BEST PRACTICES: KEEP VS DROP

### KEPT (from US spec)

| Practice | Applied to |
|---|---|
| Okabe-Ito palette (3 channels) | All |
| End-of-line labels, no legend box | B1a–d, B2a, B4 |
| Legend inside plot | B2b, B3 |
| ISI regime shaded bands | B1a–d, B4 |
| UP period window annotation | B1a–d, B4 |
| `geom_ribbon(pmin/pmax)` | B2a |
| Gray underlay + regime overlay | B1a–d, B4 |
| `coord_cartesian()` for zoom | B1b if needed, B4 |
| Visible axis lines and ticks | All |
| Parsimony in captions/notes | All |

### DROPPED or ADAPTED

| US practice | Chile adaptation |
|---|---|
| 4-channel palette (with PyPK pink) | 3-channel only — drop PyPK |
| Base year 1947 = 100 | Base year 1940 = 100 |
| 7 swings in B3 | 9 swings in B3 |
| x-axis expand = 0.30 (B3) | x-axis expand = 0.35 (B3 — wider labels) |
| WWII / Interim period windows | UP period window (1970–73) |
| No negative x-axis on B3 | Negative x-axis needed (1972–74 offsetting) |
| US ylim on B4: c(0.13, 0.28) | Chile ylim: c(0.03, 0.12) approx |

---

## SECTION 8 — IDENTITY CHECKS

Run before any save call. Three-channel identity only.

```r
# Additive identity
stopifnot(max(abs(df_chile$phi_mu + df_chile$phi_B + df_chile$phi_pi
                  - df_chile$dlnr), na.rm = TRUE) < 1e-10)

# Swing shares sum to unity
stopifnot(all(abs(df_swings_CL$s_mu + df_swings_CL$s_B +
                  df_swings_CL$s_pi - 1) < 1e-10))

# Levels identity: r = mu * B * pi
stopifnot(max(abs(df_chile$r - df_chile$mu * df_chile$B * df_chile$pi),
              na.rm = TRUE) < 1e-6)
```

---

## SECTION 9 — POST-SAVE VERIFICATION

1. **B3 negative bars (1972–74):** The π bar extends past 100%.
   The 100% reference line (dashed gray) is visible. The μ and B bars
   extend to the left of zero for that row.

2. **B3 magnitude labels:** All 9 swing labels visible.
   Largest swing (1947–53, +0.732) label does not truncate.

3. **B4 turning points:** All 9 turning points labeled (1946, 1947,
   1953, 1961, 1969, 1972, 1974, 1975, 1978). No label overlaps
   the UP period window annotation.

4. **Axis labels:** All 39 year labels (1940–1978) visible and
   non-overlapping. No year skipped.

5. **ISI regime bands:** Five distinct fills visible. UP dotted
   boundaries (1970, 1973) lighter than turning-point dashed verticals.

6. **Channel color consistency with US:** μ blue (#0072B2),
   B teal (#009E73), π vermillion (#D55E00) — same as US counterparts.
   A reader comparing the two B3 figures should immediately recognize
   the channel colors without reading the legend.

---

## SECTION 10 — BoP CONSTRAINT BAND: ECT_m OVERLAY

This section adds a time-varying shaded band to B1a–B1d and B4,
showing periods when the BoP constraint was binding according to
the Stage 1 TVECM threshold variable.

### What ECT_m represents

$\widehat{ECT}_{m,t}$ is the cointegrating residual from the Stage 1
import system — the VECM on $(m_t, k_t^{ME}, nrs_t, \omega_t)$.
It measures the deviation of import demand from its long-run
equilibrium. When $\widehat{ECT}_{m,t-1} > \hat{\lambda}$, imports
are above their structural long-run level relative to the capital
accumulation regime — the economy is in the BoP-constrained regime
$R_t = 1$. When $\widehat{ECT}_{m,t-1} \leq \hat{\lambda}$, the
constraint is slack, $R_t = 0$.

This band is the empirical trace of the modulator that governs
regime switching in the Stage 2 TVECM. Overlaying it on the Stage B
profitability figures connects the descriptive decomposition to the
structural identification — the reader can see when the BoP constraint
was binding relative to the profitability swings.

### Data requirement

Before running: confirm that the ECT_m series is available as a
column in the Chile data or as a separate CSV. Expected file:

```r
# Option A — column in the main Chile panel
df_ect <- df_chile |> select(year, ect_m)

# Option B — separate CSV from Stage 1 estimation
df_ect <- read_csv(
  "output/stage_a/Chile/csv/stageA_Chile_ECTm_series.csv"
) |> select(year, ect_m)
```

Print `summary(df_ect$ect_m)` and confirm the series covers 1940–1978.
If ECT_m is not yet estimated (Stage A Chile pending), use a placeholder
series and mark figures as DRAFT.

**If ECT_m is not available:** skip this section entirely and add a
`% TODO: add ECT_m band after Stage A Chile estimation` comment in
the figure code. Do not fabricate or approximate the series.

### Visual specification

The BoP constraint band is a **tertiary layer** — subordinate to both
the ISI regime bands and the turning-point verticals.

**Visual hierarchy (updated):**
```
ISI regime bands (filled, α=0.40)          ← primary structure
Turning point verticals (dashed, labeled)   ← primary analytical
BoP constraint band (filled, α=0.18)        ← secondary structural
UP period window (dotted, unlabeled)        ← tertiary contextual
BoP constraint text (small, italic, top)    ← tertiary contextual
```

The BoP band uses a lighter alpha (0.18 vs 0.40 for regime bands)
and a distinct color to avoid visual confusion with the ISI regime
fills.

```r
# Step 1: identify constrained periods (R_t = 1)
# Threshold lambda: use the estimated lambda from Stage 1 TVECM.
# If not yet estimated, use lambda = 0 (deviation above long-run mean).

lambda_hat <- 0   # PLACEHOLDER — replace with estimated threshold

df_bop <- df_ect |>
  filter(year >= 1940, year <= 1978) |>
  mutate(
    constrained = ect_m > lambda_hat,
    # Identify contiguous constrained episodes
    episode_id = cumsum(c(TRUE, diff(constrained) != 0))
  ) |>
  filter(constrained) |>
  group_by(episode_id) |>
  summarise(
    xmin = min(year) - 0.5,
    xmax = max(year) + 0.5,
    .groups = "drop"
  )

# Step 2: add to figures as geom_rect AFTER regime bands, BEFORE data lines
bop_layer <- geom_rect(
  data = df_bop,
  aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
  fill  = "#E74C3C",   # red — BoP pressure
  alpha = 0.18,
  inherit.aes = FALSE,
  show.legend = FALSE
)

# Step 3: add label for the first constrained episode (or the longest)
# Use annotate() — not a fixed position, locate after inspecting the data
# Example:
# annotate("text", x = [midpoint of first episode], y = Inf,
#          label = "BoP\nconstrained", vjust = 1.8, hjust = 0.5,
#          size = 2.2, color = "#C0392B", fontface = "italic")
```

### Layer order in B1a–B1d and B4 (revised)

```r
ggplot(df_plot, aes(x = year, y = [variable])) +
  # Layer 1: ISI regime bands (primary)
  geom_rect(data = isi_bands, ..., alpha = 0.40) +
  # Layer 2: BoP constraint band (secondary)
  bop_layer +
  # Layer 3: UP period window (tertiary — dotted lines)
  geom_vline(xintercept = 1970, ...) +
  geom_vline(xintercept = 1973, ...) +
  # Layer 4: Gray continuous underlay (data)
  geom_line(color = "#CCCCCC", linewidth = 0.5) +
  # Layer 5: Regime-colored overlay (data)
  geom_line(aes(color = regime, group = regime), linewidth = 1.0) +
  # Layer 6: Reference line (if applicable)
  geom_hline(yintercept = 100, ...) +
  # Layer 7: Turning point verticals (analytical)
  geom_vline(data = df_turning_CL, aes(xintercept = year),
             linetype = "dashed", color = "#AAAAAA", linewidth = 0.3) +
  # Layer 8: End-of-line labels
  geom_text_repel(...)
```

**Do NOT apply the BoP band to B2a, B2b, B3.** Same rule as regime
bands — the decomposition figures carry their own periodization.

### Updated shared source note

Replace the source note from Section 5 with this expanded version:

```latex
\textit{Note on figures:} All figures cover Chile, 1940--1978.
$r_{t} = \Pi_{t}/K_{t}$; $\hat{\mu}_{t}$ from Stage~A MPF;
$B_{t} = Y^{p}_{t}/K_{t}$ (nominal capital productivity);
$\pi_{t} = \Pi_{t}/Y_{t}$.
Three-channel identity: $r = \mu \cdot B \cdot \pi$ (exact).
Regime shading: Pre-ISI/WWII (1940--1945), Early ISI (1946--1953),
Mid ISI (1954--1961), Late ISI (1962--1972), Crisis (1973--1978).
Red shading: periods when the balance-of-payments constraint was
binding ($\widehat{ECT}_{m,t-1} > \hat{\lambda}$), where
$\widehat{ECT}_{m,t}$ is the cointegrating residual from the
Stage~A import system. Period window: Unidad Popular (1970--1973).
```

### Post-save verification addition

Add to Section 9:

6. **BoP band:** Red shading visible in constrained episodes. Alpha
   (0.18) clearly lighter than ISI regime fills (0.40). No BoP band
   bleeds into unconstrained years. If ECT_m was a placeholder (λ=0),
   figures carry "DRAFT" annotation — confirm before final export.
