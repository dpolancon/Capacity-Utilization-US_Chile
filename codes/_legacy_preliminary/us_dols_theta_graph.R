suppressPackageStartupMessages({
  library(cointReg)
  library(stats)
  library(ggplot2)
})
# ------------------------------------------------------------------------------
# 19. Paper-facing figure: theta_t and wage share over time for the preferred window
#     Main spec = S1 (intercept + uncentered)
#     Preferred estimated window in current grid = Deep comparison = 1940–1978
#     Plot/window tag uses year1_year2 form for plot purposes
# ------------------------------------------------------------------------------

preferred_window_label <- "Deep comparison"
preferred_spec_id      <- "S1"

# Pull coefficient row from the already estimated summary_df
pref_row <- subset(
  summary_df,
  sample_name == preferred_window_label & spec_id == preferred_spec_id
)

if (nrow(pref_row) != 1L) {
  stop("Could not uniquely identify preferred window/spec row in summary_df.")
}

# Recover the economic bounds from the window definition
pref_window_idx <- which(
  vapply(windows, function(w) w$label, character(1)) == preferred_window_label
)

if (length(pref_window_idx) != 1L) {
  stop("Preferred window label not found uniquely in windows list.")
}

pref_window <- windows[[pref_window_idx]]

# Plot/window tag in year1_year2 form
plot_window_tag <- sprintf("%d_%d", pref_window$start, pref_window$end)

# Rebuild the exact active window used in estimation
df_pref_full <- d_raw[d_raw$year >= pref_window$start & d_raw$year <= pref_window$end, ]
aw_pref <- compute_active_window(df_pref_full)
df_pref <- df_pref_full[aw_pref$first_idx:aw_pref$last_idx, ]

# Construct theta_t from the non-centered main specification
# theta_t = beta1_hat + beta2_hat * omega_t
df_pref$theta_t_hat <- pref_row$beta1_hat + pref_row$beta2_hat * df_pref$omega_t
df_pref$plot_window <- plot_window_tag

# Save the time-series data behind the figure
plot_data_fname <- sprintf(
  "us_theta_omega_path_spec-%s_window-%s_active-%d_%d_pkg-cointRegD_p-%d_kernel-%s_bw-%s.csv",
  preferred_spec_id,
  plot_window_tag,
  aw_pref$regression_start_year,
  aw_pref$regression_end_year,
  DOLS_P,
  CR_KERNEL,
  as.character(CR_BANDWIDTH)
)

write.csv(
  df_pref[, c("year", "omega_t", "theta_t_hat", "plot_window")],
  file.path(outdir, plot_data_fname),
  row.names = FALSE
)

# Regime shading
regime_bands <- data.frame(
  xmin  = c(1940, 1947, 1974),
  xmax  = c(1946, 1973, 1978),
  label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
  fill  = c("#F7F7F7", "#E5E5E5", "#D0D0D0"),
  stringsAsFactors = FALSE
)

# Keep only bands that overlap the preferred window
regime_bands <- regime_bands[
  regime_bands$xmax >= min(df_pref$year) & regime_bands$xmin <= max(df_pref$year),
]

# y-range for theta with tight padding
theta_min <- min(df_pref$theta_t_hat, na.rm = TRUE)
theta_max <- max(df_pref$theta_t_hat, na.rm = TRUE)
theta_rng <- theta_max - theta_min
pad <- max(theta_rng * 0.20, 0.0015)

y_lower <- theta_min - pad
y_upper <- theta_max + pad

# Rescale omega_t to theta-axis range for plotting
omega_min <- min(df_pref$omega_t, na.rm = TRUE)
omega_max <- max(df_pref$omega_t, na.rm = TRUE)
omega_rng <- omega_max - omega_min

if (omega_rng <= 0) {
  stop("omega_t has zero variation in preferred window; cannot construct overlay.")
}

rescale_omega_to_theta <- function(x) {
  y_lower + (x - omega_min) * (y_upper - y_lower) / omega_rng
}

rescale_theta_to_omega <- function(y) {
  omega_min + (y - y_lower) * omega_rng / (y_upper - y_lower)
}

df_pref$omega_scaled <- rescale_omega_to_theta(df_pref$omega_t)

# Regime label position
y_top <- y_upper - 0.02 * (y_upper - y_lower)

p_theta <- ggplot(df_pref, aes(x = year)) +
  geom_rect(
    data = regime_bands,
    aes(xmin = xmin, xmax = xmax, ymin = -Inf, ymax = Inf),
    inherit.aes = FALSE,
    fill = regime_bands$fill,
    alpha = 0.20
  ) +
  # theta series
  geom_line(
    aes(y = theta_t_hat, color = "theta", linetype = "theta"),
    linewidth = 1.0
  ) +
  # wage share series, scaled onto theta axis
  geom_line(
    aes(y = omega_scaled, color = "omega", linetype = "omega"),
    linewidth = 0.9
  ) +
  annotate(
    "text",
    x = c(1943, 1960, 1976),
    y = y_top,
    label = c("Pre-Fordist", "Fordist", "Post-Fordist\nonset"),
    vjust = 1,
    hjust = 0.5,
    size = 3.0,
    color = "black",
    fontface = "italic"
  ) +
  scale_color_manual(
    values = c("theta" = "black", "omega" = "#D55E00"),
    labels = c("theta" = expression(hat(theta)[t]), "omega" = expression(omega[t])),
    name = NULL
  ) +
  scale_linetype_manual(
    values = c("theta" = "solid", "omega" = "dashed"),
    labels = c("theta" = expression(hat(theta)[t]), "omega" = expression(omega[t])),
    name = NULL
  ) +
  scale_x_continuous(
    breaks = seq(min(df_pref$year), max(df_pref$year), by = 1),
    labels = seq(min(df_pref$year), max(df_pref$year), by = 1),
    expand = expansion(mult = c(0.01, 0.03))
  ) +
  scale_y_continuous(
    limits = c(y_lower, y_upper),
    expand = expansion(mult = c(0, 0)),
    name = expression(hat(theta)[t]),
    sec.axis = sec_axis(
      trans = ~ rescale_theta_to_omega(.),
      name = expression(omega[t])
    )
  ) +
  labs(
    x = NULL,
    y = expression(hat(theta)[t])
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = c(0.35, 0.97),
    legend.direction = "vertical",
    legend.justification = c(0, 1),
    legend.background = element_rect(
      fill = "white",
      color = "black",
      linewidth = 0.3
    ),
    legend.box.background = element_rect(
      fill = "white",
      color = "black",
      linewidth = 0.3
    ),
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

# Provenance-rich filenames
plot_stem <- sprintf(
  "us_theta_omega_path_spec-%s_window-%s_active-%d_%d_pkg-cointRegD_p-%d_kernel-%s_bw-%s",
  preferred_spec_id,
  plot_window_tag,
  aw_pref$regression_start_year,
  aw_pref$regression_end_year,
  DOLS_P,
  CR_KERNEL,
  as.character(CR_BANDWIDTH)
)

ggsave(
  filename = file.path(outdir, paste0(plot_stem, ".pdf")),
  plot = p_theta,
  width = 8.8,
  height = 5.2,
  device = cairo_pdf
)

ggsave(
  filename = file.path(outdir, paste0(plot_stem, ".png")),
  plot = p_theta,
  width = 8.8,
  height = 5.2,
  dpi = 320
)

cat("Saved preferred-window theta + omega figure:\n")
cat(sprintf("  - %s\n", file.path(outdir, plot_data_fname)))
cat(sprintf("  - %s\n", file.path(outdir, paste0(plot_stem, ".pdf"))))
cat(sprintf("  - %s\n", file.path(outdir, paste0(plot_stem, ".png"))))