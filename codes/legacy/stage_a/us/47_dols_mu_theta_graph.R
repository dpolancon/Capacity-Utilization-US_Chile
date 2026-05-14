# mu_theta_preferred_window_plot_clean.R
# ==============================================================================
# Reconstruct and plot capacity utilization (mu_t) and transformation elasticity
# (theta_t) for the preferred U.S. window using the unbalanced-growth closure:
#
#   g_Y^p,t = theta_t * g_K,t
#
# where:
#   theta_t = beta1_hat + beta2_hat * omega_t
#   g_K,t   = diff(log(K_real_t))
#
# Pinch year is chosen from the maximum of annual FRED capacity utilization,
# but normalization imposes:
#
#   mu_pinch = 1
#
# so the pinch year is treated as full capacity utilization.
#
# Minimal outputs only:
#   1 CSV + 1 PDF + 1 PNG
# ==============================================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(grid)
})

# ------------------------------------------------------------------------------
# 0. Paths and fixed settings
# ------------------------------------------------------------------------------
REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
BEA  <- "C:/ReposGitHub/US-BEA-Income-FixedAssets-Dataset"
outdir <- file.path(REPO, "output/stage_a/us/cointreg_results")
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

DOLS_P <- 2L
CR_KERNEL <- "ba"
CR_BANDWIDTH <- 3L

preferred_window_label <- "Deep comparison"
preferred_spec_id      <- "S1"

# Plot mu as 100-index instead of ratio
PLOT_MU_AS_INDEX <- TRUE

# ------------------------------------------------------------------------------
# 1. Helper functions
# ------------------------------------------------------------------------------
compute_active_window <- function(df_full, p = DOLS_P) {
  n <- nrow(df_full)
  first_idx <- p + 2L
  last_idx  <- n - p
  
  if (first_idx >= last_idx) {
    stop("Active-window trimming leaves no usable observations.")
  }
  
  data.frame(
    regression_start_year = df_full$year[first_idx],
    regression_end_year   = df_full$year[last_idx],
    first_idx = first_idx,
    last_idx  = last_idx,
    N         = last_idx - first_idx + 1L
  )
}

save_pdf_safe <- function(plot_obj, filepath, width, height) {
  ok <- TRUE
  tryCatch(
    {
      ggsave(
        filename = filepath,
        plot = plot_obj,
        width = width,
        height = height,
        device = cairo_pdf
      )
    },
    error = function(e) {
      message("cairo_pdf failed; retrying with base pdf device.")
      ok <<- FALSE
    }
  )
  
  if (!ok) {
    ggsave(
      filename = filepath,
      plot = plot_obj,
      width = width,
      height = height,
      device = "pdf"
    )
  }
}

# ------------------------------------------------------------------------------
# 2. Load base data and construct real series
# ------------------------------------------------------------------------------
d_raw <- read.csv(file.path(REPO, "data/raw/us/US_corporate_NF_kstock_distribution.csv"))
nf_inc <- read.csv(file.path(BEA, "data/processed/income_accounts_NF.csv"))

d_raw <- merge(d_raw, nf_inc[, c("year", "Py_fred")], by = "year")
d_raw <- d_raw[order(d_raw$year), ]

Py_2024 <- d_raw$Py_fred[d_raw$year == 2024]
pK_2024 <- d_raw$pK_NF[d_raw$year == 2024]

if (length(Py_2024) != 1L || length(pK_2024) != 1L) {
  stop("Could not uniquely identify 2024 rebasing values for Py_fred and pK_NF.")
}

d_raw$Y_real  <- d_raw$GVA_NF / (d_raw$Py_fred / Py_2024)
d_raw$K_real  <- d_raw$KGC_NF / (d_raw$pK_NF / pK_2024)
d_raw$y_t     <- log(d_raw$Y_real)
d_raw$k_t     <- log(d_raw$K_real)
d_raw$omega_t <- d_raw$Wsh_NF

# ------------------------------------------------------------------------------
# 3. Window definitions
# ------------------------------------------------------------------------------
windows <- list(
  list(label = "Full sample",     start = 1929, end = 2024),
  list(label = "Pre-1974",        start = 1929, end = 1973),
  list(label = "Post-1973",       start = 1974, end = 2024),
  list(label = "Fordist core",    start = 1945, end = 1973),
  list(label = "Deep comparison", start = 1940, end = 1978)
)

# ------------------------------------------------------------------------------
# 4. Load preferred coefficients from summary output
# ------------------------------------------------------------------------------
summary_path <- file.path(outdir, "dols_spec_grid_cointReg_summary_us.csv")
if (!file.exists(summary_path)) {
  stop("Could not find dols_spec_grid_cointReg_summary_us.csv in output folder.")
}

summary_df <- read.csv(summary_path, stringsAsFactors = FALSE)

pref_row <- subset(
  summary_df,
  sample_name == preferred_window_label & spec_id == preferred_spec_id
)

if (nrow(pref_row) != 1L) {
  stop("Could not uniquely identify preferred window/spec row in summary_df.")
}

# ------------------------------------------------------------------------------
# 5. Recover preferred economic and active windows
# ------------------------------------------------------------------------------
pref_window_idx <- which(
  vapply(windows, function(w) w$label, character(1)) == preferred_window_label
)

if (length(pref_window_idx) != 1L) {
  stop("Preferred window label not found uniquely in windows list.")
}

pref_window <- windows[[pref_window_idx]]
plot_window_tag <- sprintf("%d_%d", pref_window$start, pref_window$end)

df_pref_full <- d_raw[d_raw$year >= pref_window$start & d_raw$year <= pref_window$end, ]
aw_pref <- compute_active_window(df_pref_full)
df_pref <- df_pref_full   # full economic window for plotting

# ------------------------------------------------------------------------------
# 6. Construct theta_t
# ------------------------------------------------------------------------------
df_pref$theta_t_hat <- pref_row$beta1_hat + pref_row$beta2_hat * df_pref$omega_t
df_pref$plot_window <- plot_window_tag

# ------------------------------------------------------------------------------
# 7. Find pinch year from FRED CAPUT max
# ------------------------------------------------------------------------------
fred_caput_path <- file.path(REPO, "data/raw/US/fred/CAPUT_1967_2025_FRED.csv")
caput_raw <- read.csv(fred_caput_path, stringsAsFactors = FALSE)

date_col  <- names(caput_raw)[grepl("date", names(caput_raw), ignore.case = TRUE)][1]
value_col <- setdiff(names(caput_raw), date_col)[1]

caput_raw[[date_col]]  <- as.Date(caput_raw[[date_col]])
caput_raw[[value_col]] <- suppressWarnings(as.numeric(caput_raw[[value_col]]))

caput <- caput_raw[!is.na(caput_raw[[date_col]]) & !is.na(caput_raw[[value_col]]), ]
caput$year <- as.integer(format(caput[[date_col]], "%Y"))

caput_ann <- aggregate(
  caput[[value_col]],
  by = list(year = caput$year),
  FUN = mean,
  na.rm = TRUE
)
names(caput_ann)[2] <- "caput"

pinch_row <- caput_ann[which.max(caput_ann$caput), ]
pinch_year  <- pinch_row$year
pinch_value <- pinch_row$caput

if (!(pinch_year %in% df_pref$year)) {
  stop("Pinch year is not inside the preferred economic window.")
}

# IMPORTANT FIX:
# Normalize pinch year to full capacity
mu_pinch <- 1

cat(sprintf("Pinch year from FRED max: %d\n", pinch_year))
cat(sprintf("Observed FRED max annual CAPUT: %.4f\n", pinch_value))
cat(sprintf("Imposed normalization: mu_pinch = %.1f\n", mu_pinch))
cat(sprintf("Economic plotting window: %d-%d\n", min(df_pref$year), max(df_pref$year)))
cat(sprintf("Active estimation window: %d-%d\n", aw_pref$regression_start_year, aw_pref$regression_end_year))

# ------------------------------------------------------------------------------
# 8. Unbalanced-growth closure
# ------------------------------------------------------------------------------
df_pref$logY <- log(df_pref$Y_real)
df_pref$logK <- log(df_pref$K_real)

df_pref$gK  <- c(NA_real_, diff(df_pref$logK))
df_pref$gYp <- df_pref$theta_t_hat * df_pref$gK

df_pref$logYp <- NA_real_

pinch_idx <- which(df_pref$year == pinch_year)
df_pref$logYp[pinch_idx] <- df_pref$logY[pinch_idx] - log(mu_pinch)

if (pinch_idx < nrow(df_pref)) {
  for (i in (pinch_idx + 1):nrow(df_pref)) {
    df_pref$logYp[i] <- df_pref$logYp[i - 1] + df_pref$gYp[i]
  }
}

if (pinch_idx > 1) {
  for (i in seq(from = pinch_idx - 1, to = 1, by = -1)) {
    df_pref$logYp[i] <- df_pref$logYp[i + 1] - df_pref$gYp[i + 1]
  }
}

df_pref$Yp_hat <- exp(df_pref$logYp)
df_pref$mu_t   <- exp(df_pref$logY - df_pref$logYp)

if (PLOT_MU_AS_INDEX) {
  df_pref$mu_plot <- 100 * df_pref$mu_t
  mu_axis_label <- expression(mu[t]~"(1973= 100)")
} else {
  df_pref$mu_plot <- df_pref$mu_t
  mu_axis_label <- expression(mu[t])
}

# ------------------------------------------------------------------------------
# 9. Minimal export set: one CSV only
# ------------------------------------------------------------------------------
export_stem <- sprintf(
  "us_mu_theta_path_spec-%s_window-%s_estActive-%d_%d_anchorYear-%d_norm-fullcap_pkg-cointRegD_p-%d_kernel-%s_bw-%s",
  preferred_spec_id,
  plot_window_tag,
  aw_pref$regression_start_year,
  aw_pref$regression_end_year,
  pinch_year,
  DOLS_P,
  CR_KERNEL,
  as.character(CR_BANDWIDTH)
)

export_df <- df_pref[, c(
  "year", "plot_window", "omega_t", "theta_t_hat",
  "gK", "gYp", "Y_real", "Yp_hat", "mu_t", "mu_plot"
)]

write.csv(
  export_df,
  file.path(outdir, paste0(export_stem, ".csv")),
  row.names = FALSE
)

# ------------------------------------------------------------------------------
# 10. Regime shading
# ------------------------------------------------------------------------------
regime_bands <- data.frame(
  xmin  = c(1940, 1947, 1974),
  xmax  = c(1946, 1973, 1978),
  label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
  fill  = c("#F7F7F7", "#E5E5E5", "#D0D0D0"),
  stringsAsFactors = FALSE
)

regime_bands <- regime_bands[
  regime_bands$xmax >= min(df_pref$year) & regime_bands$xmin <= max(df_pref$year),
]

# ------------------------------------------------------------------------------
# 11. Build dual-axis plot
# ------------------------------------------------------------------------------
mu_min <- min(df_pref$mu_plot, na.rm = TRUE)
mu_max <- max(df_pref$mu_plot, na.rm = TRUE)
mu_rng <- mu_max - mu_min
mu_pad <- max(mu_rng * 0.20, if (PLOT_MU_AS_INDEX) 2 else 0.005)

mu_lower <- mu_min - mu_pad
mu_upper <- mu_max + mu_pad

theta_min <- min(df_pref$theta_t_hat, na.rm = TRUE)
theta_max <- max(df_pref$theta_t_hat, na.rm = TRUE)
theta_rng <- theta_max - theta_min

rescale_theta_to_mu <- function(x) {
  mu_lower + (x - theta_min) * (mu_upper - mu_lower) / theta_rng
}

rescale_mu_to_theta <- function(y) {
  theta_min + (y - mu_lower) * theta_rng / (mu_upper - mu_lower)
}

df_pref$theta_scaled <- rescale_theta_to_mu(df_pref$theta_t_hat)
y_top <- mu_upper - 0.02 * (mu_upper - mu_lower)

p_mu_theta <- ggplot(df_pref, aes(x = year)) +
  geom_rect(
    data = regime_bands,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
    inherit.aes = FALSE,
    fill = regime_bands$fill,
    alpha = 0.20
  ) +
  geom_vline(
    xintercept = pinch_year,
    linetype = "dotted",
    linewidth = 0.6,
    color = "black"
  ) +
  geom_line(
    aes(y = mu_plot, color = "mu", linetype = "mu"),
    linewidth = 1.0
  ) +
  geom_line(
    aes(y = theta_scaled, color = "theta", linetype = "theta"),
    linewidth = 0.9
  ) +
  annotate(
    "text",
    x = pinch_year + 0.3,
    y = y_top,
    label = paste0("pinch year: ", pinch_year),
    hjust = 0,
    vjust = 1,
    size = 3.0,
    color = "black"
  ) +
  annotate(
    "text",
    x = c(1943, 1960, 1976),
    y = y_top,
    label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
    vjust = 2.4,
    hjust = 0.5,
    size = 3.0,
    color = "black",
    fontface = "italic"
  ) +
  scale_color_manual(
    values = c("mu" = "black", "theta" = "#D55E00"),
    labels = c("mu" = expression(mu[t]), "theta" = expression(hat(theta)[t])),
    name = NULL
  ) +
  scale_linetype_manual(
    values = c("mu" = "solid", "theta" = "dashed"),
    labels = c("mu" = expression(mu[t]), "theta" = expression(hat(theta)[t])),
    name = NULL
  ) +
  scale_x_continuous(
    breaks = seq(min(df_pref$year), max(df_pref$year), by = 1),
    labels = seq(min(df_pref$year), max(df_pref$year), by = 1),
    expand = expansion(mult = c(0.01, 0.03))
  ) +
  scale_y_continuous(
    limits = c(mu_lower, mu_upper),
    expand = expansion(mult = c(0, 0)),
    name = mu_axis_label,
    sec.axis = sec_axis(
      transform = ~ rescale_mu_to_theta(.),
      name = expression(hat(theta)[t])
    )
  ) +
  labs(x = NULL, y = mu_axis_label) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = c(0.25, 0.94),
    legend.direction = "vertical",
    legend.justification = c(0, 1),
    legend.background = element_rect(fill = "white", color = "black", linewidth = 0.3),
    legend.box.background = element_rect(fill = "white", color = "black", linewidth = 0.3),
    legend.key = element_blank(),
    legend.key.width = unit(1.2, "cm"),
    legend.key.height = unit(0.6, "cm"),
    legend.text = element_text(size = 12, color = "black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    axis.line = element_blank(),
    axis.ticks = element_blank(),
    axis.text.x = element_text(size = 10, angle = 90, vjust = 0.5, hjust = 1, color = "black"),
    axis.text.y.left = element_text(size = 11, color = "black"),
    axis.text.y.right = element_text(size = 11, color = "black"),
    axis.title.y.left = element_text(size = 11, color = "black"),
    axis.title.y.right = element_text(size = 11, color = "black"),
    plot.title = element_blank(),
    plot.subtitle = element_blank(),
    panel.border = element_blank(),
    plot.background = element_blank(),
    panel.background = element_blank(),
    plot.margin = margin(5.5, 8, 20, 5.5)
  ) +
  guides(
    color = guide_legend(override.aes = list(linewidth = c(1.0, 0.9))),
    linetype = "none"
  ) +
  coord_cartesian(clip = "off")

# ------------------------------------------------------------------------------
# 12. Save only PDF + PNG
# ------------------------------------------------------------------------------
save_pdf_safe(
  plot_obj = p_mu_theta,
  filepath = file.path(outdir, paste0(export_stem, ".pdf")),
  width = 8.8,
  height = 5.2
)

ggsave(
  filename = file.path(outdir, paste0(export_stem, ".png")),
  plot = p_mu_theta,
  width = 8.8,
  height = 5.2,
  dpi = 320
)

cat("Saved minimal output set:\n")
cat(sprintf("  - %s\n", file.path(outdir, paste0(export_stem, ".csv"))))
cat(sprintf("  - %s\n", file.path(outdir, paste0(export_stem, ".pdf"))))
cat(sprintf("  - %s\n", file.path(outdir, paste0(export_stem, ".png"))))