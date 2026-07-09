# Stage B Chile — 4-Channel Addendum
## Date: 2026-04-08
## Supersedes: all 3-channel specifications in prompt_stageB_Chile_FINAL.md
## Apply on top of FINAL prompt. Where this addendum conflicts, this wins.

---

## CHANGE 1 — IDENTITY AND VARIABLE NAMES

Replace the three-channel identity throughout with the four-channel:

```
OLD: r = mu * B * pi       (3-channel)
NEW: r = mu * PyPK * B_r * pi  (4-channel)
```

Column names in the Chilean data — confirm before running:

| Object | Expected column |
|---|---|
| Real capital productivity | `B_real` or `B_r` |
| Relative price (output/capital) | `PyPK` |
| μ channel contribution | `phi_mu` |
| PyPK channel contribution | `phi_PyPK` |
| B_real channel contribution | `phi_Br` |
| π channel contribution | `phi_pi` |

`B` (nominal capital productivity) is retained as a contextual
level-panel figure (B1 Row 1, Col 3) but exits the decomposition.

---

## CHANGE 2 — FIGURES LIST (updated)

10 standalone files, mirroring the US exactly:

| Content | Filename | LaTeX group |
|---|---|---|
| Profit rate r (indexed) | `fig_CL_B1a_r_levels` | B1 panel |
| Capacity utilization μ (indexed) | `fig_CL_B1b_mu_levels` | B1 panel |
| Nominal B (indexed, reference) | `fig_CL_B1c_B_levels` | B1 panel |
| Profit share π (indexed) | `fig_CL_B1d_pi_levels` | B1 panel |
| Relative price Py/PK (indexed) | `fig_CL_B1e_PyPK_levels` | B1 panel |
| Real capital productivity B_real (indexed) | `fig_CL_B1f_Breal_levels` | B1 panel |
| Cumulative contributions | `fig_CL_B2a_cumulative` | standalone |
| Annual bar contributions | `fig_CL_B2b_annual_bars` | standalone |
| Swing composition | `fig_CL_B3_swing_composition` | standalone |
| Profit rate + turning points | `fig_CL_B4_profit_rate_turning_points` | standalone |

---

## CHANGE 3 — B1 PANEL LAYOUT (2×3, mirrors US exactly)

| | Col 1 | Col 2 | Col 3 |
|---|---|---|---|
| **Row 1** | B1a — r | B1b — μ | B1c — B (nominal) |
| **Row 2** | B1d — π | B1e — Py/PK | B1f — B_real |

Row 2 makes $B = (Py/PK) \times B_r$ visually decomposable —
real component and price component sit side by side, nominal B
directly above as their product. Identical logic to the US layout.

---

## CHANGE 4 — CHANNEL COLORS (four channels, Okabe-Ito)

```r
ch_colors_CL <- c(
  "μ (demand)"          = "#0072B2",   # blue     — same as US
  "Py/PK (rel. price)"  = "#CC79A7",   # pink     — same as US
  "B_real (technology)" = "#009E73",   # teal     — same as US
  "π (distribution)"    = "#D55E00"    # vermillion — same as US
)
```

Colors are identical to the US palette — critical for cross-country
visual comparison at the B3 swing composition figure level.

---

## CHANGE 5 — CUMULATIVE FIGURE (B2a)

```r
df_cum <- df_chile |>
  filter(year >= 1940, year <= 1978) |>
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
    "cum_mu"   = "μ (demand)",
    "cum_PyPK" = "Py/PK (rel. price)",
    "cum_Br"   = "B_real (technology)",
    "cum_pi"   = "π (distribution)"))
```

---

## CHANGE 6 — B3 SWING COMPOSITION (4 channels, 9 swings)

The Chilean π share of 115% in 1972–74 still applies.
Now with four channels, the PyPK channel may also produce
negative shares in some swings (offsetting). Treat exactly
as the US: italics + dagger for negative shares.

```r
# Left-side expansion for negative bars (PyPK or B_real may offset)
scale_x_continuous(
  labels = scales::percent_format(accuracy = 1),
  breaks = c(-0.25, 0, 0.25, 0.5, 0.75, 1, 1.25),
  expand = expansion(add = c(0.08, 0.35))
) +
# 100% reference line
geom_vline(xintercept = 1.0, linetype = "dashed",
           color = "#CCCCCC", linewidth = 0.4)
```

Magnitude annotation: `sprintf("Δlnr=%+.3f", delta_lnr)`
Verify all 9 labels visible. 1947–1953 (+0.732) is the longest.

---

## CHANGE 7 — IDENTITY CHECKS (4-channel)

```r
# Additive identity — 4 channels
stopifnot(max(abs(
  df_chile$phi_mu + df_chile$phi_PyPK +
  df_chile$phi_Br + df_chile$phi_pi - df_chile$dlnr),
  na.rm = TRUE) < 1e-10)

# Levels identity: B = PyPK * B_real (price × real decomposition)
stopifnot(max(abs(
  df_chile$B - df_chile$PyPK * df_chile$B_real),
  na.rm = TRUE) < 1e-6)

# Swing shares sum to unity
stopifnot(all(abs(
  df_swings_CL$s_mu + df_swings_CL$s_PyPK +
  df_swings_CL$s_Br + df_swings_CL$s_pi - 1) < 1e-10))

# Full levels identity
stopifnot(max(abs(
  df_chile$r - df_chile$mu * df_chile$PyPK *
               df_chile$B_real * df_chile$pi),
  na.rm = TRUE) < 1e-6)
```

---

## CHANGE 8 — TABLE B4 (sub-period averages, 4-channel)

**File:** `outputs/stage_b/Chile/tables/tab_B4_subperiod_CL.tex`

7 columns, `\small`, no `\adjustbox` — identical structure to US tab_B3.

Columns: Period | Years | r̄ | μ̄ | Py/PK̄ | B̄_real | π̄

Drop `mean_B` (nominal B, redundant once decomposed).

Data: read from `output/stage_b/Chile/csv/` — confirm column names.
Sub-period means from the crosswalk (r, mu, pi confirmed):
```
Pre-ISI/WWII | 1940-1945 | 0.052 | 0.763 | [from CSV] | [from CSV] | 0.396
Early ISI    | 1946-1953 | 0.063 | 0.857 | [from CSV] | [from CSV] | 0.425
Mid ISI      | 1954-1961 | 0.069 | 0.870 | [from CSV] | [from CSV] | 0.477
Late ISI     | 1962-1972 | 0.060 | 0.927 | [from CSV] | [from CSV] | 0.418
Crisis       | 1973-1978 | 0.066 | 0.850 | [from CSV] | [from CSV] | 0.522
```

`\midrule` after row 1 and after row 4. No dagger rows — all five
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
  $B_{r} = \text{GVA}_{r}/(\text{KNR}\cdot\hat{\mu})$;
  $Py/PK$ = GDP deflator / capital price deflator;
  $\pi = \Pi/Y$.
  Four-channel identity: $r = \mu \cdot (Py/PK) \cdot B_{r} \cdot \pi$ (exact).
```

---

## CHANGE 9 — TABLE B5 (swing decomposition, 4-channel)

**File:** `outputs/stage_b/Chile/tables/tab_B5_peaktotrough_CL.tex`

9 columns — identical structure to US tab_B2.
`\adjustbox{max width=\textwidth}` + `\small`.

Columns: Period | Type | Δln r | s_μ | s_PyPK | s_Br | s_π | Σ | Dominant

Negative shares: italics + dagger (same as US).
π > 1.0 in 1972–74: dominant cell reads `$\pi^{*}$` with note.
`\addlinespace[3pt]` between every type change.

Read full swing data from CSV before writing. Dominant channel
logic from the crosswalk (dominant percentages confirmed):
- 1940–46: μ (71%)
- 1946–47: π (66%)
- 1947–53: π (80%)
- 1953–61: π (86%)
- 1961–69: π (96%)
- 1969–72: π (100%)
- 1972–74: π (115%) → `$\pi^{*}$`
- 1974–75: π (54%), μ secondary
- 1975–78: μ (68%)

**Note on PyPK in Chile:** The Chilean Py/PK channel may show
different patterns from the US — particularly around the 1973–74
copper price shock and import liberalization. Do not assume the
same sign structure as the US. Read from the data.

**Caption:**
```latex
\caption{Four-channel decomposition of profit-rate swings,
  Chile, 1940--1978.}
\label{tab:B5_peaktotrough_CL}
```

**Notes:**
```latex
\item \textit{Notes:}
  $\Delta\ln r = \phi^{\mu} + \phi^{Py/PK} + \phi^{B_{r}} + \phi^{\pi}$
  (exact); $s_j$ sum to unity.
  $r = \Pi/K$; $B_{r} = \text{GVA}_{r}/(\text{KNR}\cdot\hat{\mu})$;
  $Py/PK$ = GDP deflator / capital price deflator;
  $\hat{\mu}$ from Stage~A MPF.
\item[$\dagger$] Offsetting channel: contribution moves against the
  swing direction.
\item[$*$] Distribution share exceeds unity: the profit share recovery
  more than reverses the combined drag from the other three channels.
```

---

## CHANGE 10 — UPDATED SHARED SOURCE NOTE

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

---

## EXPORT CALL (updated — 10 figures)

```r
W <- 12; H <- 6

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
