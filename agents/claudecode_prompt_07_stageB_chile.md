# Claude Code Prompt 07: Chile Stage B — Profitability Analysis
## Weisskopf Decomposition using Stage A structurally-identified inputs
## Window: 1940–1978 (N=39) | Constraint: P_K deflator available from 1940

---

## CONTEXT

Stage B applies the Weisskopf (1979) decomposition to Chile using the
structurally-identified inputs from Stage A. The profit rate decomposes as:

  r_t = mu_CL_t · B_t · pi_t

where:
  mu_CL_t  = capacity utilization (from Stage A CLS-TVECM, validated 1920–1987)
  B_t      = capital productivity at normal capacity = Y^p_t / K_t
  pi_t     = profit share = 1 - omega_t

The contribution relative to Weisskopf (1979): mu_CL_t is structurally
identified from the productive frontier, NOT from an HP-filter or peak-output
method. This separates the demand channel from the technology channel in a
way the original paper could not.

Window: 1940–1978 (N=39, all observations complete, no NAs).
Deflator constraint: P_K available from 1940 — hard lower bound.
Upper bound: 1978 — pre-BCCh era, within validated identification window.

---

## REPO AND PATHS

```r
REPO    <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
CSV_IN  <- file.path(REPO, "output/stage_a/Chile/csv")
CSV_OUT <- file.path(REPO, "output/stage_b/Chile/csv")
FIG_OUT <- file.path(REPO, "output/stage_b/Chile/figs")

dir.create(CSV_OUT, recursive=TRUE, showWarnings=FALSE)
dir.create(FIG_OUT, recursive=TRUE, showWarnings=FALSE)
```

---

## STEP 0: LOAD STAGE A PANEL AND CONSTRUCT STAGE B VARIABLES

```r
library(tidyverse); library(ggplot2); library(scales)

# Load Stage A panel (all 105 years)
panel <- read_csv(file.path(CSV_IN, "stage2_panel_with_mu_v2.csv"))

# Load P_K (capital price deflator) — confirm column name
# Expected file: data/processed/Chile/chile_pk_deflator.csv
# or it may be in the main panel already — check first
cat("Panel columns:\n"); cat(names(panel), sep="\n")

# If P_K is in the panel, use directly.
# If not, load from the separate deflator file and merge.
# The deflator is needed for: K_net_cc = K_net_real * P_K / 100

# ── Construct Stage B variables ────────────────────────────────────────────
df_b <- panel %>%
  arrange(year) %>%
  mutate(
    # Profit share (distribution channel)
    pi_t    = 1 - omega,

    # Productive capacity in log: y^p = y - ln(mu_CL)
    y_p     = y + log(mu_CL),    # log(Y^p) = log(Y/mu) + log(mu) + log(mu)
    # Correct: y^p = y - g_mu accumulated... but since mu_CL = Y/Y^p:
    # Y^p = Y / mu_CL → log(Y^p) = y - log(mu_CL)
    y_p_log = y - log(mu_CL),

    # Capital productivity at normal capacity: B = Y^p / K
    # In log: ln(B) = y_p_log - k_CL
    ln_B    = y_p_log - k_CL,
    B_t     = exp(ln_B),

    # Profit rate: r = mu * B * pi
    # Computed from components (exact identity in levels)
    r_t     = mu_CL * B_t * pi_t,

    # Log profit rate and components for growth decomposition
    ln_r    = log(r_t),
    ln_mu   = log(mu_CL),
    ln_pi   = log(pi_t)
    # ln_B already computed above
  ) %>%
  filter(year >= 1940, year <= 1978)

cat(sprintf("\nStage B panel: N=%d (1940–1978)\n", nrow(df_b)))
cat(sprintf("r_t:   mean=%.4f, range=[%.4f, %.4f]\n",
    mean(df_b$r_t), min(df_b$r_t), max(df_b$r_t)))
cat(sprintf("mu_CL: mean=%.4f, range=[%.4f, %.4f]\n",
    mean(df_b$mu_CL), min(df_b$mu_CL), max(df_b$mu_CL)))
cat(sprintf("B_t:   mean=%.4f, range=[%.4f, %.4f]\n",
    mean(df_b$B_t), min(df_b$B_t), max(df_b$B_t)))
cat(sprintf("pi_t:  mean=%.4f, range=[%.4f, %.4f]\n",
    mean(df_b$pi_t), min(df_b$pi_t), max(df_b$pi_t)))

# Verify identity: r_t ≈ mu_CL * B_t * pi_t
cat(sprintf("\nIdentity check (max deviation): %.8f\n",
    max(abs(df_b$r_t - df_b$mu_CL * df_b$B_t * df_b$pi_t))))
```

---

## STEP 1: IDENTIFY TURNING POINTS ON r_t

Turning points identified on the profit rate series — not on output or
employment. A profit rate contraction can begin while output is still
expanding (the structural condition of capital over-accumulation).

```r
# Print r_t series for visual inspection of turning points
cat("\nProfit rate series 1940–1978:\n")
df_b %>% select(year, r_t, mu_CL, B_t, pi_t) %>% print(n=39)

# Sub-period classification (to be refined after visual inspection)
# Tentative turning points based on Chilean macro history:
# 1940–1945: Pre-ISI consolidation / WWII
# 1946–1955: Early ISI expansion
# 1956–1961: Stabilization / external constraint
# 1962–1971: Late ISI / Frei-Allende
# 1972–1978: Crisis onset / coup / shock therapy

# Compute growth rates of each component
df_b <- df_b %>%
  mutate(
    g_r  = c(NA, diff(ln_r)),
    g_mu = c(NA, diff(ln_mu)),
    g_B  = c(NA, diff(ln_B)),
    g_pi = c(NA, diff(ln_pi))
  )

# Verify additive decomposition (exact in logs)
df_b <- df_b %>%
  mutate(decomp_check = g_mu + g_B + g_pi - g_r)
cat(sprintf("Log decomposition check (max |residual|): %.8f\n",
    max(abs(df_b$decomp_check), na.rm=TRUE)))
```

---

## STEP 2: SUB-PERIOD AVERAGES TABLE

```r
# Define sub-periods for Chilean ISI arc
# Adjust boundaries after Step 1 visual inspection if needed
subperiods <- list(
  "Pre-ISI/WWII  (1940-1945)" = c(1940, 1945),
  "Early ISI     (1946-1955)" = c(1946, 1955),
  "Stabilization (1956-1961)" = c(1956, 1961),
  "Late ISI      (1962-1971)" = c(1962, 1971),
  "Crisis onset  (1972-1978)" = c(1972, 1978)
)

tab_subperiod <- purrr::map_dfr(names(subperiods), function(nm) {
  yr  <- subperiods[[nm]]
  idx <- df_b$year >= yr[1] & df_b$year <= yr[2]
  tibble(
    period  = nm,
    n       = sum(idx),
    r_mean  = mean(df_b$r_t[idx],  na.rm=TRUE),
    mu_mean = mean(df_b$mu_CL[idx],na.rm=TRUE),
    B_mean  = mean(df_b$B_t[idx],  na.rm=TRUE),
    pi_mean = mean(df_b$pi_t[idx], na.rm=TRUE)
  )
})

cat("\n=== Sub-Period Averages: Chile Profitability 1940–1978 ===\n")
print(tab_subperiod)
write_csv(tab_subperiod, file.path(CSV_OUT, "stageB_CL_subperiod_averages.csv"))
```

---

## STEP 3: SWING-LEVEL DECOMPOSITION (PEAK-TO-TROUGH)

```r
# After identifying turning points in Step 1, define swings here.
# Tentative swing structure (revise after Step 1 inspection):
swings <- list(
  list(label="1940-1945 (expansion)", start=1940, end=1945),
  list(label="1945-1950 (contraction)", start=1945, end=1950),
  list(label="1950-1955 (expansion)", start=1950, end=1955),
  list(label="1955-1961 (contraction)", start=1955, end=1961),
  list(label="1961-1966 (expansion)", start=1961, end=1966),
  list(label="1966-1972 (contraction)", start=1966, end=1972),
  list(label="1972-1975 (crisis)", start=1972, end=1975),
  list(label="1975-1978 (partial recovery)", start=1975, end=1978)
)

tab_swings <- purrr::map_dfr(swings, function(sw) {
  s_idx <- which(df_b$year == sw$start)
  e_idx <- which(df_b$year == sw$end)
  if (length(s_idx)==0 || length(e_idx)==0) return(NULL)

  delta_ln_r  <- df_b$ln_r[e_idx]  - df_b$ln_r[s_idx]
  delta_ln_mu <- df_b$ln_mu[e_idx] - df_b$ln_mu[s_idx]
  delta_ln_B  <- df_b$ln_B[e_idx]  - df_b$ln_B[s_idx]
  delta_ln_pi <- df_b$ln_pi[e_idx] - df_b$ln_pi[s_idx]

  # Share of total swing
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

cat("\n=== Swing-Level Decomposition ===\n")
print(tab_swings)
write_csv(tab_swings, file.path(CSV_OUT, "stageB_CL_swing_decomposition.csv"))

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
```

---

## STEP 4: FIGURES

### Figure B1: Profit rate with turning points
```r
fig_B1 <- ggplot(df_b, aes(x=year, y=r_t)) +
  geom_line(linewidth=0.8, color="#2171b5") +
  geom_point(size=1.5, color="#2171b5") +
  # Turning point markers — adjust years after Step 1 inspection
  geom_vline(xintercept=c(1945, 1950, 1955, 1961, 1966, 1972, 1975),
             linetype="dashed", color="grey50", linewidth=0.4) +
  # Regime shading
  annotate("rect", xmin=1940, xmax=1946, ymin=-Inf, ymax=Inf,
           fill="#6baed6", alpha=0.08) +
  annotate("rect", xmin=1972, xmax=1978, ymin=-Inf, ymax=Inf,
           fill="#cb181d", alpha=0.08) +
  scale_x_continuous(breaks=seq(1940,1978,5)) +
  labs(
    title    = "Profit Rate, Chile 1940–1978",
    subtitle = expression(r[t]^{CL}~"="~hat(mu)[t]^{CL}~"·"~hat(B)[t]^{CL}~"·"~pi[t]^{CL}),
    x=NULL, y=expression(r[t]^{CL})
  ) +
  theme_minimal(base_size=11) +
  theme(panel.grid.minor=element_blank())

ggsave(file.path(FIG_OUT, "figB1_CL_profit_rate.pdf"), fig_B1,
       width=8, height=4, device=cairo_pdf)
ggsave(file.path(FIG_OUT, "figB1_CL_profit_rate.png"), fig_B1,
       width=8, height=4, dpi=300)
cat("Figure B1 saved.\n")
```

### Figure B2: Offsetting trajectories (mu and B indexed)
```r
df_indexed <- df_b %>%
  filter(year >= 1940) %>%
  mutate(
    mu_idx = mu_CL / mu_CL[year==1947] * 100,
    B_idx  = B_t   / B_t[year==1947]   * 100,
    pi_idx = pi_t  / pi_t[year==1947]  * 100
  )

fig_B2 <- ggplot(df_indexed, aes(x=year)) +
  geom_line(aes(y=mu_idx, color="mu (demand)"),     linewidth=0.8) +
  geom_line(aes(y=B_idx,  color="B (technology)"),  linewidth=0.8) +
  geom_line(aes(y=pi_idx, color="pi (distribution)"),linewidth=0.8, linetype="dashed") +
  geom_hline(yintercept=100, linetype="dotted", color="grey50") +
  scale_color_manual(values=c(
    "mu (demand)"       = "#2171b5",
    "B (technology)"    = "#cb181d",
    "pi (distribution)" = "#41ab5d"
  )) +
  scale_x_continuous(breaks=seq(1940,1978,5)) +
  labs(
    title    = "Profitability Channels, Chile 1940–1978 (indexed 1947=100)",
    subtitle = "Offsetting trajectories of the ISI compensation mechanism",
    x=NULL, y="Index (1947=100)", color=NULL
  ) +
  theme_minimal(base_size=11) +
  theme(panel.grid.minor=element_blank(),
        legend.position="bottom")

ggsave(file.path(FIG_OUT, "figB2_CL_channels_indexed.pdf"), fig_B2,
       width=8, height=4, device=cairo_pdf)
ggsave(file.path(FIG_OUT, "figB2_CL_channels_indexed.png"), fig_B2,
       width=8, height=4, dpi=300)
cat("Figure B2 saved.\n")
```

### Figure B3: Swing composition bar chart
```r
tab_swings_long <- tab_swings %>%
  select(swing, type, delta_ln_r, share_mu, share_B, share_pi) %>%
  pivot_longer(cols=c(share_mu, share_B, share_pi),
               names_to="channel", values_to="share") %>%
  mutate(
    channel = recode(channel,
      "share_mu" = "mu (demand)",
      "share_B"  = "B (technology)",
      "share_pi" = "pi (distribution)"
    ),
    delta_r_label = sprintf("Δlnr=%+.3f", delta_ln_r)
  )

fig_B3 <- ggplot(tab_swings_long,
                 aes(x=share*100, y=fct_rev(swing), fill=channel)) +
  geom_col(position="stack", alpha=0.85) +
  geom_vline(xintercept=c(0,100), linetype="dotted", color="grey40") +
  scale_fill_manual(values=c(
    "mu (demand)"       = "#2171b5",
    "B (technology)"    = "#cb181d",
    "pi (distribution)" = "#41ab5d"
  )) +
  scale_x_continuous(labels=function(x) paste0(x,"%")) +
  labs(
    title    = "Channel Composition of Profit-Rate Swings, Chile 1940–1978",
    subtitle = "Share of total log swing. Values sum to 100%.",
    x="Share of total swing (%)", y=NULL, fill=NULL
  ) +
  theme_minimal(base_size=11) +
  theme(panel.grid.minor=element_blank(),
        legend.position="bottom")

ggsave(file.path(FIG_OUT, "figB3_CL_swing_composition.pdf"), fig_B3,
       width=8, height=5, device=cairo_pdf)
ggsave(file.path(FIG_OUT, "figB3_CL_swing_composition.png"), fig_B3,
       width=8, height=5, dpi=300)
cat("Figure B3 saved.\n")
```

---

## STEP 5: SAVE FULL STAGE B PANEL AND REPORT

```r
# Save full stage B panel
write_csv(df_b, file.path(CSV_OUT, "stageB_CL_panel_1940_1978.csv"))
cat("Stage B panel saved.\n")

# Final report
cat("\n================================================================\n")
cat("  CHILE STAGE B — PROFITABILITY ANALYSIS CROSSWALK\n")
cat("================================================================\n")
cat(sprintf("Window:      1940–1978 (N=%d)\n", nrow(df_b)))
cat(sprintf("Identity:    r = mu · B · pi (max deviation: %.2e)\n",
    max(abs(df_b$r_t - df_b$mu_CL * df_b$B_t * df_b$pi_t))))
cat("\nSub-period profit rate means:\n")
print(tab_subperiod %>% select(period, r_mean, mu_mean, B_mean, pi_mean))
cat("\nSwing dominant channels:\n")
print(tab_swings %>% select(swing, type, dominant))
cat("\nOutputs:\n")
for (f in c("stageB_CL_panel_1940_1978.csv",
            "stageB_CL_subperiod_averages.csv",
            "stageB_CL_swing_decomposition.csv",
            "figB1_CL_profit_rate.pdf",
            "figB2_CL_channels_indexed.pdf",
            "figB3_CL_swing_composition.pdf")) {
  cat(sprintf("  %s\n", f))
}
cat("================================================================\n")
```

---

## CRITICAL NOTES FOR CLAUDE CODE

1. **B_t construction:** Verify the formula y_p_log = y - log(mu_CL) by
   checking that exp(y_p_log - k_CL) produces economically plausible
   capital productivity values (should be in the range [0.3, 1.0]).

2. **Turning points:** The tentative swing boundaries in Step 3 are based
   on Chilean macro history. After printing the profit rate series in Step 1,
   revise the swing list if the actual turning points differ. The turning
   points should be identified on r_t, not on output.

3. **P_K deflator:** If the current panel does not include net current-cost
   capital, compute the real profit rate using gross real capital (k_CL)
   as the denominator. Note this in the crosswalk output. The distinction
   between gross and net capital for the denominator should match the
   choice made for the US Stage B.

4. **1973–1975:** The coup and shock therapy produce extreme values. Report
   them but do not exclude — the crisis expression is part of the story.

5. **Output paths:**
   CSVs → output/stage_b/Chile/csv/
   Figs → output/stage_b/Chile/figs/

---

*Prompt 07 | 2026-04-08 | Chile Stage B Profitability Analysis*
*Window: 1940–1978 | Inputs: Stage A mu_CL, B_t from y_p_log, pi = 1-omega*
