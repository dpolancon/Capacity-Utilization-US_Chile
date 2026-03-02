# /patch_consolidate
rm(list=ls())
# ============================================================
# 51_shaikh_auto_ardl.R
# self-discovery of reduced rank geometry (ARDL IC-space)
# Output:
#   - output/ARDL_IC_space/<WINDOW_TAG>/ic_space_table.csv
#   - output/ARDL_IC_space/<WINDOW_TAG>/*.png  (IC maps + PCA/MDS)
# ============================================================

suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(ARDL)
  library(purrr)
  library(readr)
  library(tidyr)
  library(ggrepel)
})

# --- load CONFIG + utils ---
source(here::here("codes", "10_config_tsdyn.R"))
source(here::here("codes", "99_tsdyn_utils.R"))

# -----------------------------
# 0) Load Shaikh replication dataset
# -----------------------------
df_raw <- readxl::read_excel(here::here(CONFIG$data_shaikh),
                             sheet = CONFIG$data_shaikh_sheet)

stopifnot(all(c(CONFIG$year_col, CONFIG$y_nom, CONFIG$k_nom, CONFIG$p_index) %in% names(df_raw)))

df <- df_raw |>
  transmute(
    year  = as.integer(.data[[CONFIG$year_col]]),
    Y_nom = as.numeric(.data[[CONFIG$y_nom]]),
    K_nom = as.numeric(.data[[CONFIG$k_nom]]),
    p     = as.numeric(.data[[CONFIG$p_index]])
  ) |>
  filter(is.finite(year), is.finite(Y_nom), is.finite(K_nom), is.finite(p), p > 0) |>
  mutate(
    p_scale = p / 100,
    Y_real  = Y_nom / p_scale,
    K_real  = K_nom / p_scale,
    lnY     = log(Y_real),
    lnK     = log(K_real)
  ) |>
  arrange(year)

# -----------------------------
# 1) Window lock
# -----------------------------
WINDOW_TAG <- "shaikh_window"
w <- CONFIG$WINDOWS_LOCKED[[WINDOW_TAG]]
stopifnot(length(w) == 2)

df <- df |>
  filter(year >= w[1], year <= w[2]) |>
  arrange(year)

# -----------------------------
# 2) Time series dataset
# -----------------------------
if (!exists("dummy_names")) dummy_names <- character(0)
dummy_names <- intersect(dummy_names, names(df))

df_ts <- ts(
  df |> dplyr::select(lnY, lnK, dplyr::all_of(dummy_names)),
  start = min(df$year),
  frequency = 1
)

# -----------------------------
# 3) Discovery: IC space via auto_ardl grid search
# -----------------------------
MAX_P <- 5
MAX_Q <- 5
max_order_vec <- c(MAX_P, MAX_Q)

ic_set <- c("AIC", "BIC")

# Custom IC functions (passed by name; ARDL stores score column as function name)
HQ_fun <- function(m) {
  ll <- as.numeric(stats::logLik(m))
  k  <- attr(stats::logLik(m), "df")
  Tt <- stats::nobs(m)
  -2 * ll + 2 * k * log(log(Tt))
}

AICc_fun <- function(m) {
  ll <- as.numeric(stats::logLik(m))
  k  <- attr(stats::logLik(m), "df")
  Tt <- stats::nobs(m)
  aic <- -2 * ll + 2 * k
  aic + (2 * k * (k + 1)) / max(1, (Tt - k - 1))
}

ic_surfaces <- list()

for (ic in ic_set) {
  ic_surfaces[[ic]] <- ARDL::auto_ardl(
    lnY ~ lnK,
    data      = df_ts,
    max_order = max_order_vec,
    selection = ic,
    grid      = TRUE
  )
}

ic_surfaces[["HQ"]] <- ARDL::auto_ardl(
  lnY ~ lnK,
  data      = df_ts,
  max_order = max_order_vec,
  selection = "HQ_fun",
  grid      = TRUE
)

ic_surfaces[["AICc"]] <- ARDL::auto_ardl(
  lnY ~ lnK,
  data      = df_ts,
  max_order = max_order_vec,
  selection = "AICc_fun",
  grid      = TRUE
)

# -----------------------------
# 4) Extract IC tables into a single ic_df
# -----------------------------
extract_orders_table <- function(obj) {
  cand_names <- c("all_orders", "orders", "grid_orders", "top_orders")
  nm <- cand_names[cand_names %in% names(obj)][1]
  if (is.na(nm)) stop("Can't find candidate order table in auto_ardl object. Run str(obj).")
  obj[[nm]]
}

extract_ic_table2 <- function(obj, ic_tag) {
  tab <- extract_orders_table(obj)
  stopifnot(all(c("lnY", "lnK") %in% names(tab)))
  
  score_candidates <- setdiff(names(tab), c("lnY", "lnK"))
  if (length(score_candidates) != 1) {
    stop("Can't uniquely detect score column. Found: ",
         paste(score_candidates, collapse = ", "),
         ". Inspect names(tab).")
  }
  score_col <- score_candidates[1]
  
  tab |>
    dplyr::rename(p = lnY, q = lnK) |>
    dplyr::transmute(
      p = as.integer(p),
      q = as.integer(q),
      !!ic_tag := as.numeric(.data[[score_col]])
    )
}

ic_AIC  <- extract_ic_table2(ic_surfaces[["AIC"]],  "AIC")
ic_BIC  <- extract_ic_table2(ic_surfaces[["BIC"]],  "BIC")
ic_HQ   <- extract_ic_table2(ic_surfaces[["HQ"]],   "HQ")
ic_AICc <- extract_ic_table2(ic_surfaces[["AICc"]], "AICc")

ic_df <- ic_AIC |>
  dplyr::left_join(ic_BIC,  by = c("p", "q")) |>
  dplyr::left_join(ic_HQ,   by = c("p", "q")) |>
  dplyr::left_join(ic_AICc, by = c("p", "q"))

# -----------------------------
# 5) Add logLik, k, T_eff by refitting each (p,q)
# -----------------------------
fit_one <- function(p, q, data_ts) {
  m <- ARDL::ardl(lnY ~ lnK, data = data_ts, order = c(p, q))
  ll <- as.numeric(stats::logLik(m))
  k  <- attr(stats::logLik(m), "df")      # complexity = df used by likelihood
  Te <- stats::nobs(m)
  dplyr::tibble(logLik = ll, k = k, T_eff = Te)
}

meta_df <- purrr::pmap_dfr(list(ic_df$p, ic_df$q), fit_one, data_ts = df_ts)
ic_df <- dplyr::bind_cols(ic_df, meta_df)
ic_df$.pq <- paste0("(", ic_df$p, ",", ic_df$q, ")")


# ------------------------------------------------------------
# 6) IC Space Plotter (ggplot2)
# ------------------------------------------------------------

# /patches_consolidate
# ============================================================
# 51_shaikh_auto_ardl.R  (PLOTTING SECTION ONLY)
# Consolidated ggplot2 plotting with robust PNG saving (no blank files)
# Drop-in replacement for your current plotting section:
#   - replaces plot_ic_space(), plot_ic_space_pca(), plot_ic_space_mds()
#   - replaces ggsave() with explicit png()+print()+dev.off()
# Dependencies: ggplot2, dplyr, tidyr, purrr (already), optional ggrepel
# ============================================================

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(purrr)
})

# ------------------------------------------------------------
# Robust plot saver: avoids blank PNGs by forcing rendering
# ------------------------------------------------------------
save_gg <- function(p, filename, width = 10, height = 7, dpi = 200) {
  grDevices::png(filename, width = width, height = height, units = "in", res = dpi)
  on.exit({ if (grDevices::dev.cur() != 1) grDevices::dev.off() }, add = TRUE)
  print(p)
}

# ------------------------------------------------------------
# Label layer (ggrepel if available, else geom_text fallback)
# ------------------------------------------------------------
label_layer <- function(mapping, size = 3) {
  if (requireNamespace("ggrepel", quietly = TRUE)) {
    ggrepel::geom_text_repel(mapping = mapping, size = size, max.overlaps = Inf)
  } else {
    ggplot2::geom_text(mapping = mapping, size = size, vjust = -0.6)
  }
}

# ------------------------------------------------------------
# Main IC-space plotter (ALL plots in ggplot2)
# Outputs:
#   *_pairs.png
#   *_ic_vs_logLik.png
#   *_frontier.png
# ------------------------------------------------------------
plot_ic_space <- function(ic_df,
                          out_dir = "output/ARDL_IC_space",
                          prefix  = "icspace",
                          winners = TRUE,
                          label_points = TRUE) {
  
  stopifnot(is.data.frame(ic_df))
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  
  base_req <- c("p","q","k","T_eff","logLik")
  stopifnot(all(base_req %in% names(ic_df)))
  
  ic_cols <- intersect(c("AIC","BIC","HQ","AICc"), names(ic_df))
  if (length(ic_cols) == 0) stop("ic_df must contain at least one of: AIC, BIC, HQ, AICc")
  
  ic_df <- ic_df |>
    dplyr::mutate(.pq = paste0("(", p, ",", q, ")"))
  
  if (winners) {
    for (ic in ic_cols) {
      ic_df[[paste0("WIN_", ic)]] <- ic_df[[ic]] == min(ic_df[[ic]], na.rm = TRUE)
    }
  }
  
  # -------------------------
  # (1) Pairwise IC scatter grid (FIXED)
  # -------------------------
  pairs_list <- list(
    c("AIC","BIC"),
    c("AIC","HQ"),
    c("AIC","AICc"),
    c("BIC","HQ"),
    c("BIC","AICc"),
    c("HQ","AICc")
  )
  pairs_list <- Filter(function(xy) all(xy %in% ic_cols), pairs_list)
  
  if (length(pairs_list) > 0) {
    pair_long <- purrr::map_dfr(pairs_list, function(xy) {
      xname <- xy[1]; yname <- xy[2]
      out <- ic_df |>
        dplyr::transmute(
          pair = paste0(yname, " vs ", xname),
          x = .data[[xname]],
          y = .data[[yname]],
          .pq = .pq
        )
      if (winners) {
        out$win_x <- ic_df[[paste0("WIN_", xname)]]
        out$win_y <- ic_df[[paste0("WIN_", yname)]]
      }
      out
    })
    
    g_pairs <- ggplot2::ggplot(pair_long, ggplot2::aes(x = x, y = y)) +
      ggplot2::geom_point(size = 2) +
      ggplot2::facet_wrap(~pair, scales = "free") +
      ggplot2::labs(x = "IC(x)", y = "IC(y)", title = "Pairwise IC space") +
      ggplot2::theme_minimal(base_size = 14)
    
    if (winners) {
      g_pairs <- g_pairs +
        ggplot2::geom_point(data = pair_long[pair_long$win_x, ],
                            ggplot2::aes(x = x, y = y),
                            shape = 21, size = 4, stroke = 1.2) +
        ggplot2::geom_point(data = pair_long[pair_long$win_y, ],
                            ggplot2::aes(x = x, y = y),
                            shape = 1, size = 4, stroke = 1.2)
    }
    
    save_gg(g_pairs,
            file.path(out_dir, paste0(prefix, "_pairs.png")),
            width = 12, height = 8, dpi = 200)
  }
  
  # -------------------------
  # (2) IC vs logLik (faceted)  [FIXED: winner flags without dynamic column lookup]
  # -------------------------
  ic_long <- ic_df |>
    tidyr::pivot_longer(cols = dplyr::all_of(ic_cols),
                        names_to = "IC",
                        values_to = "IC_value") |>
    dplyr::filter(is.finite(IC_value), is.finite(logLik))  # drop NAs early
  
  # attach "is winner" flag by computing min within each IC
  ic_long <- ic_long |>
    dplyr::group_by(IC) |>
    dplyr::mutate(is_winner = IC_value == min(IC_value, na.rm = TRUE)) |>
    dplyr::ungroup()
  
  g_ic_ll <- ggplot2::ggplot(ic_long, ggplot2::aes(x = logLik, y = IC_value)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::facet_wrap(~IC, scales = "free_y") +
    ggplot2::labs(title = "IC vs logLik (penalty geometry)",
                  x = "logLik", y = "IC value") +
    ggplot2::theme_minimal(base_size = 14)
  
  if (winners) {
    g_ic_ll <- g_ic_ll +
      ggplot2::geom_point(data = ic_long[ic_long$is_winner, ],
                          ggplot2::aes(x = logLik, y = IC_value),
                          shape = 21, size = 4, stroke = 1.2)
  }
  
  save_gg(g_ic_ll,
          file.path(out_dir, paste0(prefix, "_ic_vs_logLik.png")),
          width = 12, height = 8, dpi = 200)
  
  # -------------------------
  # (3) Frontier: logLik vs k (with envelope + labels)
  # -------------------------
  front <- ic_df |>
    dplyr::group_by(k) |>
    dplyr::summarise(logLik = max(logLik), .groups = "drop") |>
    dplyr::arrange(k)
  
  g_front <- ggplot2::ggplot(ic_df, ggplot2::aes(x = k, y = logLik)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_line(data = front, ggplot2::aes(x = k, y = logLik), linewidth = 1) +
    ggplot2::labs(title = "Fit–Complexity Plane (logLik vs k)",
                  x = "k (df from logLik)",
                  y = "logLik") +
    ggplot2::theme_minimal(base_size = 14)
  
  if (label_points) {
    g_front <- g_front + label_layer(ggplot2::aes(label = .pq), size = 3)
  }
  
  if (winners) {
    for (ic in ic_cols) {
      wcol <- paste0("WIN_", ic)
      g_front <- g_front +
        ggplot2::geom_point(data = ic_df[ic_df[[wcol]], ],
                            ggplot2::aes(x = k, y = logLik),
                            shape = 21, size = 4, stroke = 1.2) +
        ggplot2::geom_text(data = ic_df[ic_df[[wcol]], ],
                           ggplot2::aes(label = ic),
                           hjust = -0.1, vjust = 0.4, size = 4)
    }
  }
  
  save_gg(g_front,
          file.path(out_dir, paste0(prefix, "_frontier.png")),
          width = 10, height = 7, dpi = 200)
  
  invisible(list(out_dir = out_dir, plotted_criteria = ic_cols))
}

# ------------------------------------------------------------
# PCA plots (ggplot2)
# Outputs:
#   *_PCA_scree.png
#   *_PCA_scores.png
#   *_PCA_loadings.png
# ------------------------------------------------------------
plot_ic_space_pca <- function(ic_df, out_dir, prefix = "icspace", label_points = TRUE) {
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  
  req <- c("p","q","AIC","BIC","HQ","AICc","logLik","k","T_eff")
  stopifnot(all(req %in% names(ic_df)))
  
  ic_df <- ic_df |>
    dplyr::mutate(.pq = paste0("(", p, ",", q, ")"))
  
  X <- ic_df[, c("AIC","BIC","HQ","AICc","logLik","k")]
  X <- stats::na.omit(X)
  row_idx <- as.integer(rownames(X))
  
  pca <- stats::prcomp(X, scale. = TRUE)
  
  var_exp <- (pca$sdev^2) / sum(pca$sdev^2)
  scree_df <- dplyr::tibble(PC = seq_along(var_exp), var_exp = var_exp)
  
  g_scree <- ggplot2::ggplot(scree_df, ggplot2::aes(x = PC, y = var_exp)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::labs(title = "PCA scree", x = "PC", y = "Variance explained") +
    ggplot2::theme_minimal(base_size = 14)
  
  save_gg(g_scree,
          file.path(out_dir, paste0(prefix, "_PCA_scree.png")),
          width = 8, height = 5, dpi = 200)
  
  scores <- as.data.frame(pca$x[, 1:2, drop = FALSE])
  scores$.pq <- ic_df$.pq[row_idx]
  
  g_scores <- ggplot2::ggplot(scores, ggplot2::aes(x = PC1, y = PC2)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::labs(title = "PCA scores (models in IC space)", x = "PC1", y = "PC2") +
    ggplot2::theme_minimal(base_size = 14)
  
  if (label_points) {
    g_scores <- g_scores + label_layer(ggplot2::aes(label = .pq), size = 3)
  }
  
  save_gg(g_scores,
          file.path(out_dir, paste0(prefix, "_PCA_scores.png")),
          width = 10, height = 7, dpi = 200)
  
  load <- as.data.frame(pca$rotation[, 1:2, drop = FALSE])
  load$var <- rownames(load)
  
  g_load <- ggplot2::ggplot(load, ggplot2::aes(x = PC1, y = PC2)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::geom_text(ggplot2::aes(label = var), vjust = -0.6, size = 4) +
    ggplot2::labs(title = "PCA loadings (axis meaning)", x = "Loading PC1", y = "Loading PC2") +
    ggplot2::theme_minimal(base_size = 14)
  
  save_gg(g_load,
          file.path(out_dir, paste0(prefix, "_PCA_loadings.png")),
          width = 9, height = 6, dpi = 200)
  
  invisible(list(pca = pca))
}

# ------------------------------------------------------------
# MDS plot (ggplot2)
# Output:
#   *_MDS.png
# ------------------------------------------------------------
plot_ic_space_mds <- function(ic_df, out_dir, prefix = "icspace", label_points = TRUE) {
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  
  req <- c("p","q","AIC","BIC","HQ","AICc")
  stopifnot(all(req %in% names(ic_df)))
  
  ic_df <- ic_df |>
    dplyr::mutate(.pq = paste0("(", p, ",", q, ")"))
  
  X <- scale(ic_df[, c("AIC","BIC","HQ","AICc")])
  D <- dist(X)
  m <- cmdscale(D, k = 2)
  mds <- dplyr::tibble(MDS1 = m[, 1], MDS2 = m[, 2], .pq = ic_df$.pq)
  
  g_mds <- ggplot2::ggplot(mds, ggplot2::aes(x = MDS1, y = MDS2)) +
    ggplot2::geom_point(size = 2) +
    ggplot2::labs(title = "MDS map of IC space", x = "MDS1", y = "MDS2") +
    ggplot2::theme_minimal(base_size = 14)
  
  if (label_points) {
    g_mds <- g_mds + label_layer(ggplot2::aes(label = .pq), size = 3)
  }
  
  save_gg(g_mds,
          file.path(out_dir, paste0(prefix, "_MDS.png")),
          width = 10, height = 7, dpi = 200)
  
  invisible(mds)
}


# ------------------------------------------------------------
# 8) Run: plot + export
# ------------------------------------------------------------
out_dir <- here::here("output", "ARDL_IC_space", WINDOW_TAG)
if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)


#nforce complete cases for the criteria you actually want:
ic_df_plot <- ic_df |> dplyr::filter(is.finite(AIC), is.finite(BIC), is.finite(HQ), is.finite(AICc),
                                     is.finite(logLik), is.finite(k))

# Set of IC space plots 
plot_ic_space(ic_df_plot, out_dir = out_dir, prefix = "shaikh_ardl_icspace",
              winners = TRUE, label_points = TRUE)

readr::write_csv(ic_df_plot, file.path(out_dir, "ic_space_table.csv"))

#Plot PCA and MDS analysis 
plot_ic_space_pca(ic_df_plot, out_dir, prefix = "shaikh_ardl", label_points = TRUE)
plot_ic_space_mds(ic_df_plot, out_dir, prefix = "shaikh_ardl", label_points = TRUE)


# ------------------------------------------------------------
# MDS + correlation diagnostics (saved to disk)
# ------------------------------------------------------------

# 1) MDS computation
mds <- plot_ic_space_mds(ic_df_plot, out_dir, prefix = "shaikh_ardl", label_points = TRUE)

cor_mat  <- cor(
  cbind(MDS1 = mds$MDS1, MDS2 = mds$MDS2),
  ic_df_plot[, c("logLik","k","AIC","BIC","HQ","AICc")],
  use = "complete.obs"
)

cor_tidy <- as.data.frame(as.table(cor_mat))
names(cor_tidy) <- c("MDS_axis","metric","corr")

cor_tidy <- cor_tidy |>
  dplyr::arrange(MDS_axis, dplyr::desc(abs(corr))) |>
  dplyr::group_by(MDS_axis) |>
  dplyr::mutate(metric = factor(metric,
                                levels = metric[order(abs(corr), decreasing = TRUE)])) |>
  dplyr::ungroup()

# ------------------------------------------------------------
# 2) Heatmap: MDS axis meaning
# ------------------------------------------------------------

g_heat <- ggplot(cor_tidy, aes(x = metric, y = MDS_axis, fill = corr)) +
  geom_tile() +
  geom_text(aes(label = sprintf("%.2f", corr)), size = 4) +
  scale_fill_viridis_c(option = "C", limits = c(-1,1)) +
  theme_minimal(base_size = 14) +
  labs(title = "What MDS axes represent (correlations)",
       x = NULL, y = NULL)

save_gg(
  g_heat,
  file.path(out_dir, "shaikh_ardl_MDS_correlation_heatmap.png"),
  width = 9, height = 5
)

# ------------------------------------------------------------
# 3) MDS gradient plots
# ------------------------------------------------------------

mds_df <- dplyr::bind_cols(ic_df_plot, mds)

# MDS colored by logLik
g_logLik <- ggplot(mds_df, aes(MDS1, MDS2)) +
  geom_point(aes(color = logLik), size = 3) +
  scale_color_viridis_c(option = "C") +
  theme_minimal(base_size = 14) +
  labs(title = "MDS space colored by logLik")

save_gg(
  g_logLik,
  file.path(out_dir, "shaikh_ardl_MDS_logLik.png"),
  width = 8, height = 6
)

# MDS colored by complexity k
g_k <- ggplot(mds_df, aes(MDS1, MDS2)) +
  geom_point(aes(color = k), size = 3) +
  scale_color_viridis_c(option = "C") +
  theme_minimal(base_size = 14) +
  labs(title = "MDS space colored by complexity (k)")

save_gg(
  g_k,
  file.path(out_dir, "shaikh_ardl_MDS_complexity.png"),
  width = 8, height = 6
)