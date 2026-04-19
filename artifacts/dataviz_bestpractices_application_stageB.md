# Data Viz Best Practices — Applied to Stage B US Figures
## Date: 2026-04-06 | Source: data-viz-best-practices.md (Spanish)

All outputs in English.

---

## What applies directly — 5 actionable improvements

### 1. Color palette: switch to Okabe-Ito (accessibility)

The document is explicit: no red/green combinations; palettes must pass
colorblind accessibility checks. The current channel scheme has B_real (green)
and π (red) adjacent in every bar and stacked area — this fails deuteranopia.

Replace with Okabe-Ito, the document's recommended standard for categorical
scientific figures:

```r
ch_colors <- c(
  "μ (demand)"          = "#0072B2",  # blue       (replaces #2166AC)
  "Py/PK (rel. price)"  = "#CC79A7",  # pink       (replaces #762A83)
  "B_real (technology)" = "#009E73",  # green      (replaces #1B7837)
  "π (distribution)"    = "#D55E00"   # vermillion (replaces #B2182B)
)
```

Vermillion (#D55E00) and green (#009E73) are distinguishable under all
common colorblindness types. Apply to all figures without exception.

### 2. Direct line labels instead of legend boxes

The document is categorical: label at the end of lines, not in a detached
legend box. This reduces cognitive load and is a mark of top-journal figures.

Apply to: B1 level panels, B2a cumulative ribbons, θ/μ bridge.

```r
# Pattern for all multi-series line figures:
library(ggrepel)

df_last <- df_plot |> group_by(channel) |> slice_max(year, n = 1)

# Add to each figure:
geom_text_repel(
  data        = df_last,
  aes(label   = channel, color = channel),
  direction   = "y",
  hjust       = 0,
  nudge_x     = 0.5,
  size        = 3.5,
  segment.size= 0.3,
  show.legend = FALSE
) +
coord_cartesian(clip = "off") +        # allow labels outside plot area
theme(
  legend.position = "none",            # remove legend box entirely
  plot.margin = margin(5, 80, 5, 5)    # right margin for label overflow
)
```

For bar figures (B2b, B3) where end-of-line labeling does not apply,
keep the legend but position it **inside** the plot area at an empty corner,
not below the figure (below-figure legends force the eye to travel far).

### 3. Dual axis: justify or separate (θ/μ bridge)

The document flags dual Y axis as high risk — it "can induce co-movement
readings that are not identified." ggplot2 restricts secondary axes to
strict one-to-one linear transformations of the primary, which is satisfied
here (θ rescaled linearly to μ's range). The dual axis is therefore technically
admissible in ggplot2 terms.

However, the document's recommendation is clear: if the co-movement is the
argument, the dual axis is tempting but editorially suspect. Since the θ/μ
figure is a bridge (showing that Stage A's transformation elasticity generates
Stage B's utilization path), the more defensible design is **two stacked
panels sharing the x-axis**, saved as two separate files per the no-panel rule,
with a note in the LaTeX layout to place them adjacently.

If the dual axis is kept, add this disclaimer to the caption:
"Secondary axis is a linear rescaling of θ to the μ range: θ_scaled =
(θ − 0.5) × 0.5 + 0.55. No co-movement inference is implied by axis alignment."

### 4. Add LOESS smoother to level panels (B1a–B1f)

The document: "show raw data + smoother; justify both." Annual series are noisy.
A LOESS smoother with `span = 0.35` overlaid on the raw line immediately
reveals the underlying trend without hiding the annual volatility.

```r
# Add to each B1 level panel:
geom_smooth(
  method = "loess", span = 0.35, se = FALSE,
  color  = "black", linewidth = 0.7, linetype = "solid"
) +
# Raw line becomes thinner and semi-transparent:
geom_line(aes(color = regime), linewidth = 0.6, alpha = 0.55)
```

Caption addition: "Thin line: annual series; black line: LOESS smoother
(span = 0.35)."

Do NOT add the smoother to B2a (cumulative), B2b (annual bars), B3 (swing),
or B4 (profit rate with turning points) — those figures' analytical content
is in the annual variation itself.

### 5. Regime annotation with labeled rectangles (all figures)

The document recommends `geom_rect()` with low alpha to mark periods,
with text annotations rather than just vertical lines. Replace the current
`geom_vline()` boundaries with shaded bands:

```r
# Regime shading — add to all level panels and B4:
regime_bands <- tibble(
  xmin  = c(1940, 1947, 1974),
  xmax  = c(1946, 1973, 1978),
  label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
  fill  = c("#F5F5F5", "#EBF5FB", "#FEF9E7")
)

geom_rect(
  data = regime_bands,
  aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf, fill = fill),
  alpha = 0.35, inherit.aes = FALSE, show.legend = FALSE
) +
scale_fill_identity() +
annotate("text",
  x     = c(1943, 1960, 1976),
  y     = Inf,              # top of panel
  label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
  vjust = 1.5, hjust = 0.5,
  size  = 3, color = "#555555", fontface = "italic"
)
```

This replaces the two `geom_vline()` calls at 1947 and 1973 in every figure.

---

## What does NOT apply

- **Seasonality decomposition (STL):** Data are annual — no intra-year
  seasonality. Irrelevant.
- **Forecasting fan charts:** Stage B is descriptive decomposition, not
  forecasting.
- **ITS/DiD visual design:** The turning-point analysis is not a
  quasi-experimental design — it is a descriptive accounting decomposition.
  Annotate turning points as "identified turning points on r_t" not as
  "interventions."
- **renv/targets workflow:** Already managed by the session's existing
  pipeline. No change needed.

---

## What is already correct per the document

- PDF + PNG dual export ✓
- `cairo_pdf` for vector output ✓
- Annual x-axis breaks (full granularity) ✓
- `theme_minimal` base ✓
- No chart borders ✓
- Turning points annotated as descriptive markers, not causal claims ✓

---

## Summary of changes to pass to Claude Code

| Change | Figures affected | Priority |
|---|---|---|
| Switch to Okabe-Ito palette | All | High — accessibility |
| End-of-line labels, remove legend box | B1a–f, B2a, θ/μ | High — readability |
| LOESS smoother on raw line | B1a–f only | Medium — trend legibility |
| Regime shaded bands + text | All level panels, B4 | Medium — narrative |
| Dual axis caption disclaimer OR split θ/μ | θ/μ bridge | Low — editorial hygiene |
