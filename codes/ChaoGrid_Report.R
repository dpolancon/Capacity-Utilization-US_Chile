# ============================================================
# ChaoGrid_Report_Q2_vSurfaceEverywhere.R
#
# Goal:
#   Build an UNRESTRICTED PIC surface over full (p,r) lattice via PIC_hat,
#   then overlay admissibility + runtime + comparability + final pick.
#
# Input:
#   output/ChaoGrid/csv/grid_pic_table_Q2_unrestricted.csv
#   output/ChaoGrid/csv/S4_final_recommendations_Q2.csv (optional)
#
# Output:
#   figs/: status + PIC_hat heatmaps (+ comparable versions)
#   html/: 3D PIC_hat surface + overlays (if plotly/htmlwidgets installed)
#   tex/ : PIC_surface_pack_Q2.csv (surface + overlays for LaTeX ingestion)
# ============================================================

suppressPackageStartupMessages({
  pkgs <- c("here","readr","dplyr","tidyr","ggplot2","tibble")
  invisible(lapply(pkgs, require, character.only = TRUE))
})

HAS_PLOTLY <- requireNamespace("plotly", quietly = TRUE)
HAS_HTML   <- requireNamespace("htmlwidgets", quietly = TRUE)

ROOT <- here::here("output/ChaoGrid")
DIRS_IN <- list(csv = file.path(ROOT, "csv"), meta = file.path(ROOT, "meta"))
DIRS_OUT <- list(
  figs = file.path(ROOT, "figs"),
  html = file.path(ROOT, "html"),
  tex  = file.path(ROOT, "tex"),
  logs = file.path(ROOT, "logs")
)
dir.create(DIRS_OUT$figs, recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS_OUT$html, recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS_OUT$tex,  recursive=TRUE, showWarnings=FALSE)
dir.create(DIRS_OUT$logs, recursive=TRUE, showWarnings=FALSE)

log_file <- file.path(DIRS_OUT$logs, "report_log_Q2_vSurfaceEverywhere.txt")
sink(log_file, split=TRUE)
on.exit(sink(), add=TRUE)

cat("=== Report start: Q2 vSurfaceEverywhere ===\n")
cat("ROOT:", ROOT, "\n\n")

# -------------------------
# Ingest (force types)
# -------------------------
pathU <- file.path(DIRS_IN$csv, "grid_pic_table_Q2_unrestricted.csv")
if (!file.exists(pathU)) stop("Missing: grid_pic_table_Q2_unrestricted.csv", call.=FALSE)

# Explicit col_types to avoid list-columns.
# If you add columns later, readr will default them reasonably.
gridU <- readr::read_csv(
  pathU,
  show_col_types = FALSE,
  col_types = cols(
    window = col_character(),
    ecdet  = col_character(),
    p      = col_integer(),
    r      = col_integer(),
    T      = col_integer(),
    m      = col_integer(),
    K      = col_integer(),
    gate_ok = col_logical(),
    runtime_ok = col_logical(),
    comparable_p = col_logical(),
    status = col_character(),
    PIC_obs = col_double(),
    BIC_obs = col_double(),
    .default = col_guess()
  )
)

pathF <- file.path(DIRS_IN$csv, "S4_final_recommendations_Q2.csv")
final <- if (file.exists(pathF)) {
  readr::read_csv(pathF, show_col_types = FALSE, col_types = cols(.default = col_guess()))
} else NULL

gridU <- gridU |>
  dplyr::mutate(
    window = as.character(window),
    ecdet  = as.character(ecdet),
    p = as.integer(p),
    r = as.integer(r),
    gate_ok = as.logical(gate_ok),
    runtime_ok = as.logical(runtime_ok),
    comparable_p = as.logical(comparable_p),
    status = as.character(status)
  )

cat("Rows gridU:", nrow(gridU), "\n")
cat("Final present:", !is.null(final), "\n\n")

# -------------------------
# Helpers
# -------------------------
build_full_grid <- function(d) {
  tidyr::expand_grid(
    p = sort(unique(d$p)),
    r = sort(unique(d$r))
  )
}

fit_predict_surface <- function(d_full, d_obs) {
  if (nrow(d_obs) == 0) return(rep(NA_real_, nrow(d_full)))
  
  if (nrow(d_obs) >= 12) {
    fit <- tryCatch(
      stats::loess(PIC_obs ~ p + r, data = d_obs,
                   span = 0.9, degree = 2,
                   control = stats::loess.control(surface="direct")),
      error = function(e) NULL
    )
    if (!is.null(fit)) {
      pred <- tryCatch(stats::predict(fit, newdata = d_full), error = function(e) rep(NA_real_, nrow(d_full)))
      if (any(is.finite(pred))) return(as.numeric(pred))
    }
  }
  
  if (nrow(d_obs) >= 6) {
    fit2 <- tryCatch(
      stats::lm(PIC_obs ~ p + r + I(p^2) + I(r^2) + I(p*r), data = d_obs),
      error = function(e) NULL
    )
    if (!is.null(fit2)) {
      pred <- tryCatch(stats::predict(fit2, newdata = d_full), error = function(e) rep(NA_real_, nrow(d_full)))
      if (any(is.finite(pred))) return(as.numeric(pred))
    }
  }
  
  rep(stats::median(d_obs$PIC_obs, na.rm=TRUE), nrow(d_full))
}

surface_matrix <- function(dd) {
  m <- dd |>
    tidyr::pivot_wider(names_from = p, values_from = PIC_hat) |>
    dplyr::arrange(r)
  
  r_vals <- m$r
  z <- as.matrix(m[, setdiff(names(m), "r"), drop=FALSE])
  p_vals <- suppressWarnings(as.numeric(colnames(z)))
  list(p_vals=p_vals, r_vals=r_vals, z=z)
}

# -------------------------
# Build SURF pack: PIC_hat everywhere + overlays
# -------------------------
keys <- gridU |>
  dplyr::distinct(window, ecdet) |>
  dplyr::arrange(window, ecdet)

surface_pack <- vector("list", nrow(keys))

for (i in seq_len(nrow(keys))) {
  w  <- as.character(keys$window[i])
  ec <- as.character(keys$ecdet[i])
  
  d0 <- gridU |> dplyr::filter(window == w, ecdet == ec)
  
  full_grid <- build_full_grid(d0)
  
  d_obs <- d0 |>
    dplyr::filter(is.finite(PIC_obs)) |>
    dplyr::select(p, r, PIC_obs)
  
  full_grid$PIC_hat <- fit_predict_surface(full_grid, d_obs)
  
  overlay <- full_grid |>
    dplyr::left_join(
      d0 |> dplyr::select(p,r,status,gate_ok,runtime_ok,comparable_p,PIC_obs,BIC_obs),
      by=c("p","r")
    ) |>
    dplyr::mutate(
      status       = dplyr::coalesce(status, "missing"),
      gate_ok      = dplyr::coalesce(gate_ok, FALSE),
      runtime_ok   = dplyr::coalesce(runtime_ok, FALSE),
      comparable_p = dplyr::coalesce(comparable_p, FALSE),
      window = w,
      ecdet  = ec
    )
  
  surface_pack[[i]] <- overlay
}

SURF <- dplyr::bind_rows(surface_pack) |>
  dplyr::mutate(
    window = as.character(window),
    ecdet  = as.character(ecdet)
  )

readr::write_csv(SURF, file.path(DIRS_OUT$tex, "PIC_surface_pack_Q2.csv"))
cat("Wrote:", file.path(DIRS_OUT$tex, "PIC_surface_pack_Q2.csv"), "\n\n")

WLIST <- sort(unique(SURF$window))
ECLIST <- sort(unique(SURF$ecdet))

# -------------------------
# PANEL A: status / admissibility tiles
# -------------------------
plot_status <- function(d, w, ec) {
  dd <- d |> dplyr::filter(window == w, ecdet == ec)
  ggplot(dd, aes(x=p, y=r)) +
    geom_tile(aes(fill=status), alpha=0.95) +
    labs(
      title = paste0("A. Status lattice | ", w, " | ecdet=", ec),
      subtitle = "computed has PIC_obs; runtime_fail has no likelihood; gate_fail violates feasibility rule",
      x="p", y="r"
    )
}

for (w in WLIST) {
  for (ec in ECLIST) {
    g <- plot_status(SURF, w, ec)
    ggsave(file.path(DIRS_OUT$figs, paste0("A_STATUS_Q2_", w, "_", ec, ".png")),
           g, width=7, height=4.5, dpi=160)
  }
}

# -------------------------
# PANEL B: PIC_hat heatmap + overlays
# -------------------------
plot_pic_hat <- function(d, w, ec, only_comparable=FALSE) {
  dd <- d |> dplyr::filter(window == w, ecdet == ec)
  if (only_comparable) dd <- dd |> dplyr::filter(comparable_p)
  
  g <- ggplot(dd, aes(x=p, y=r)) +
    geom_tile(aes(fill=PIC_hat), alpha=0.95) +
    geom_point(data = dd |> dplyr::filter(runtime_ok, is.finite(PIC_obs)),
               aes(x=p, y=r), inherit.aes=FALSE, size=2) +
    geom_point(data = dd |> dplyr::filter(!gate_ok),
               aes(x=p, y=r), inherit.aes=FALSE, shape=4, size=2) +
    labs(
      title = paste0("B. PIC_hat surface (full lattice) | ", w, " | ecdet=", ec,
                     if (only_comparable) " | comparable_p only" else ""),
      subtitle = "Fill = PIC_hat everywhere; dots = computed PIC_obs; X = gate_fail",
      x="p", y="r"
    )
  
  if (!is.null(final) && all(c("window","ecdet","p","r") %in% names(final))) {
    ff <- final |> dplyr::filter(window == w, ecdet == ec) |> dplyr::select(p,r) |> dplyr::distinct()
    if (nrow(ff)>0) g <- g + geom_point(data=ff, aes(x=p,y=r), inherit.aes=FALSE, size=3)
  }
  
  g
}

for (w in WLIST) {
  for (ec in ECLIST) {
    g1 <- plot_pic_hat(SURF, w, ec, only_comparable=FALSE)
    ggsave(file.path(DIRS_OUT$figs, paste0("B_PICHAT_Q2_", w, "_", ec, ".png")),
           g1, width=7, height=4.5, dpi=160)
    
    g2 <- plot_pic_hat(SURF, w, ec, only_comparable=TRUE)
    ggsave(file.path(DIRS_OUT$figs, paste0("B_PICHAT_Q2_", w, "_", ec, "_comparable.png")),
           g2, width=7, height=4.5, dpi=160)
  }
}

# -------------------------
# PANEL E: 3D PIC_hat surface + overlays
# -------------------------
plot_pic_hat_3d <- function(d, w, ec, only_comparable=FALSE) {
  if (!HAS_PLOTLY || !HAS_HTML) return(NULL)
  
  dd <- d |> dplyr::filter(window == w, ecdet == ec)
  if (only_comparable) dd <- dd |> dplyr::filter(comparable_p)
  
  ddS <- dd |> dplyr::filter(is.finite(PIC_hat))
  if (nrow(ddS) < 4) {
    return(plotly::plot_ly(type="scatter3d", mode="markers",
                           x=numeric(0), y=numeric(0), z=numeric(0)) |>
             plotly::layout(title=paste0("PIC_hat 3D | ", w, " | ecdet=", ec, " | no surface")))
  }
  
  mat <- surface_matrix(ddS)
  
  fig <- plotly::plot_ly(type="surface", x=mat$p_vals, y=mat$r_vals, z=mat$z) |>
    plotly::layout(
      title = paste0("PIC_hat 3D | ", w, " | ecdet=", ec,
                     if (only_comparable) " | comparable_p" else ""),
      scene = list(
        xaxis = list(title="p"),
        yaxis = list(title="r"),
        zaxis = list(title="PIC_hat")
      )
    )
  
  obs <- dd |> dplyr::filter(runtime_ok, is.finite(PIC_obs)) |> dplyr::select(p,r,PIC_obs)
  if (nrow(obs) > 0) {
    fig <- fig |>
      plotly::add_markers(data=obs, x=~p, y=~r, z=~PIC_obs,
                          type="scatter3d", mode="markers",
                          marker=list(size=3), name="PIC_obs (runtime_ok)")
  }
  
  gf <- dd |> dplyr::filter(!gate_ok, is.finite(PIC_hat)) |> dplyr::select(p,r,PIC_hat)
  if (nrow(gf) > 0) {
    fig <- fig |>
      plotly::add_markers(data=gf, x=~p, y=~r, z=~PIC_hat,
                          type="scatter3d", mode="markers",
                          marker=list(size=3, symbol="x"), name="gate_fail")
  }
  
  if (!is.null(final) && all(c("window","ecdet","p","r","PIC") %in% names(final))) {
    ff <- final |> dplyr::filter(window==w, ecdet==ec) |> dplyr::select(p,r,PIC) |> dplyr::distinct()
    if (nrow(ff) > 0) {
      fig <- fig |>
        plotly::add_markers(data=ff, x=~p, y=~r, z=~PIC,
                            type="scatter3d", mode="markers",
                            marker=list(size=5), name="final pick")
    }
  }
  
  fig
}

if (HAS_PLOTLY && HAS_HTML) {
  for (w in WLIST) {
    for (ec in ECLIST) {
      fig1 <- plot_pic_hat_3d(SURF, w, ec, only_comparable=FALSE)
      htmlwidgets::saveWidget(fig1,
                              file = file.path(DIRS_OUT$html, paste0("E_PICHAT3D_Q2_", w, "_", ec, ".html")),
                              selfcontained = TRUE
      )
      
      fig2 <- plot_pic_hat_3d(SURF, w, ec, only_comparable=TRUE)
      htmlwidgets::saveWidget(fig2,
                              file = file.path(DIRS_OUT$html, paste0("E_PICHAT3D_Q2_", w, "_", ec, "_comparable.html")),
                              selfcontained = TRUE
      )
    }
  }
} else {
  cat("NOTE: plotly/htmlwidgets not installed; skipping 3D outputs.\n")
}

cat("\n=== Report completed OK ===\n")
