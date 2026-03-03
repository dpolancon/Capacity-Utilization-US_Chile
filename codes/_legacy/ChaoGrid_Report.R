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
# =========================
# ChaoGrid_Report.R (definitive branch, vSurfaceEverywhere)
# Storytelling for joint (p,r) decision:
#   - Build an UNRESTRICTED PIC surface over the full (p,r) grid (even when runtime fails)
#   - Overlay: gate admissibility, runtime success/failure, comparable range, and final pick
#
# Inputs expected (from dual-output Engine):
#   - grid_pic_table_Q2_unrestricted.csv   (status, gate_ok, runtime_ok, comparable_p, PIC, BIC)
#   - S4_final_recommendations_Q2.csv
# Optional:
#   - grid_pic_table_Q2_restricted.csv
#   - S1_feasible_pmax_by_window_ecdet_Q2.csv
#   - meta/S1_COMMON_P_MAX_note.txt
#
# Outputs:
#   - figs/ : 2D PNG
#   - html/ : 3D plotly surface (PIC_hat) + overlays
#   - tex/  : compact CSV exports for LaTeX ingestion
#   - logs/ : report_log.txt
# =========================

suppressPackageStartupMessages({
  pkgs <- c("here","readr","dplyr","tidyr","ggplot2","tibble","stringr")
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
ROOT_IN  <- here::here("output/ChaoGrid")
DIRS_IN  <- list(csv = file.path(ROOT_IN, "csv"), meta = file.path(ROOT_IN, "meta"))
DIRS_OUT <- list(
  figs = file.path(ROOT_IN, "figs"),
  html = file.path(ROOT_IN, "html"),
  tex  = file.path(ROOT_IN, "tex"),
  logs = file.path(ROOT_IN, "logs")
)

dir.create(DIRS_OUT$figs, recursive = TRUE, showWarnings = FALSE)
dir.create(DIRS_OUT$html, recursive = TRUE, showWarnings = FALSE)
dir.create(DIRS_OUT$tex,  recursive = TRUE, showWarnings = FALSE)
dir.create(DIRS_OUT$logs, recursive = TRUE, showWarnings = FALSE)

report_log <- file.path(DIRS_OUT$logs, "report_log.txt")
sink(report_log, split = TRUE)
on.exit(sink(), add = TRUE)

cat("=== ChaoGrid_Report start (vSurfaceEverywhere) ===\n")
cat("IN :", ROOT_IN, "\n")
cat("OUT:", paste(unlist(DIRS_OUT), collapse = " | "), "\n\n")

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
  
add_missing_cols <- function(df, defaults) {
  for (nm in names(defaults)) if (!(nm %in% names(df))) df[[nm]] <- defaults[[nm]]
  df
}
read_if_exists <- function(path) if (file.exists(path)) readr::read_csv(path, show_col_types = FALSE) else NULL
safe_note <- function(path, fallback = NA_character_) {
  if (!file.exists(path)) return(fallback)
  paste(readLines(path, warn = FALSE), collapse = "\n")
}

stamp_common_pmax <- function(txt, w, ec) {
  if (is.na(txt) || !nzchar(txt)) return(paste0(w, " | ecdet=", ec))
  m <- stringr::str_match(txt, "COMMON_P_MAX\\s*=\\s*([0-9]+)")
  if (!is.na(m[,2])) return(paste0(w, " | ecdet=", ec, " | COMMON_P_MAX=", m[,2]))
  paste0(w, " | ecdet=", ec)
}

# Build a full p×r grid for a given window×ecdet from what exists in the file
build_full_grid <- function(d) {
  tibble::tibble(
    p = sort(unique(d$p)),
    r = sort(unique(d$r))
  ) |>
    tidyr::expand_grid(p = sort(unique(d$p)), r = sort(unique(d$r)))
}

# Fit PIC_hat(p,r) so a surface exists even where PIC_obs is missing
# Strategy:
#  - If >= 12 observed points: loess(PIC ~ p + r)
#  - Else if >= 6 points: quadratic lm
#  - Else: constant median
fit_predict_surface <- function(d_full, d_obs) {
  # d_full: full p×r grid with columns p,r
  # d_obs: observed subset with columns p,r,PIC_obs
  if (nrow(d_obs) >= 12) {
    # loess is happy enough here; use gentle smoothing
    fit <- tryCatch(
      stats::loess(PIC_obs ~ p + r, data = d_obs,
                   span = 0.9, degree = 2, family = "gaussian",
                   control = stats::loess.control(surface = "direct")),
      error = function(e) NULL
    )
    if (!is.null(fit)) {
      pred <- tryCatch(stats::predict(fit, newdata = d_full), error = function(e) rep(NA_real_, nrow(d_full)))
      if (any(is.finite(pred))) return(pred)
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
      if (any(is.finite(pred))) return(pred)
    }
  }
  
  # last resort: constant surface
  rep(stats::median(d_obs$PIC_obs, na.rm = TRUE), nrow(d_full))
}

# -------------------------
# Ingest
# -------------------------
need <- c("grid_pic_table_Q2_unrestricted.csv", "S4_final_recommendations_Q2.csv")
paths <- file.path(DIRS_IN$csv, need)
missing <- need[!file.exists(paths)]
if (length(missing) > 0) stop("Missing required CSVs: ", paste(missing, collapse=", "), call.=FALSE)

gridU <- readr::read_csv(file.path(DIRS_IN$csv, "grid_pic_table_Q2_unrestricted.csv"), show_col_types = FALSE)
final <- readr::read_csv(file.path(DIRS_IN$csv, "S4_final_recommendations_Q2.csv"), show_col_types = FALSE)

gridR <- read_if_exists(file.path(DIRS_IN$csv, "grid_pic_table_Q2_restricted.csv"))
feas  <- read_if_exists(file.path(DIRS_IN$csv, "S1_feasible_pmax_by_window_ecdet_Q2.csv"))
note_common <- safe_note(file.path(DIRS_IN$meta, "S1_COMMON_P_MAX_note.txt"), fallback = NA_character_)

cat("Rows: unrestricted=", nrow(gridU),
    " restricted=", if (is.null(gridR)) NA else nrow(gridR),
    " final=", nrow(final),
    " feas=", if (is.null(feas)) NA else nrow(feas), "\n\n")

stopifnot(all(c("window","ecdet","p","r") %in% names(gridU)))

gridU <- add_missing_cols(gridU, list(
  status = NA_character_,
  gate_ok = NA,
  runtime_ok = NA,
  comparable_p = NA,
  PIC = NA_real_,
  BIC = NA_real_
))

final <- add_missing_cols(final, list(
  winner_type = NA_character_,
  det_preference = NA_character_,
  det_improvement_rel = NA_real_,
  boundary_flag = NA,
  no_interior_within_epsilon = NA,
  tie_break_applied = NA_character_
))

# Standardize types a bit
gridU <- gridU |>
  dplyr::mutate(
    p = as.integer(p),
    r = as.integer(r),
    gate_ok = as.logical(gate_ok),
    runtime_ok = as.logical(runtime_ok),
    comparable_p = as.logical(comparable_p)
  )

# -------------------------
# Story table
# -------------------------
final_small <- final |>
  dplyr::select(dplyr::any_of(c(
    "window","ecdet","p","r","PIC","BIC",
    "winner_type","det_preference","det_improvement_rel",
    "boundary_flag","no_interior_within_epsilon","tie_break_applied"
  ))) |>
  dplyr::arrange(window, ecdet)

cat("Final picks:\n")
print(final_small)
cat("\n")

readr::write_csv(final_small, file.path(DIRS_OUT$tex, "final_picks_Q2_storytable.csv"))

# -------------------------
# Build per (window,ecdet) surfaces + exports
# -------------------------
surface_pack <- list()
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
for (i in seq_len(nrow(keys))) {
  w  <- keys$window[i]
  ec <- keys$ecdet[i]
  subtxt <- stamp_common_pmax(note_common, w, ec)
  
  d0 <- gridU |>
    dplyr::filter(window == w, ecdet == ec)
  
  # Full intended grid on the support present in the data (p,r combos)
  full_grid <- build_full_grid(d0)
  
  # Observed PIC points (runtime success)
  d_obs <- d0 |>
    dplyr::filter(status == "computed", is.finite(PIC)) |>
    dplyr::select(p, r, PIC_obs = PIC)
  
  # Predict a full-surface PIC_hat over all p×r
  if (nrow(d_obs) == 0) {
    # no observed points: surface is undefined, but keep a placeholder
    full_grid$PIC_hat <- NA_real_
  } else {
    full_grid$PIC_hat <- fit_predict_surface(full_grid, d_obs)
  }
  
  # Merge flags back for overlays (gate/runtime/comparable/status)
  overlay <- full_grid |>
    dplyr::left_join(
      d0 |> dplyr::select(p, r, status, gate_ok, runtime_ok, comparable_p, PIC_obs = PIC),
      by = c("p","r")
    ) |>
    dplyr::mutate(
      status = dplyr::coalesce(status, "missing"),
      gate_ok = dplyr::if_else(is.na(gate_ok), FALSE, gate_ok),
      runtime_ok = dplyr::if_else(is.na(runtime_ok), FALSE, runtime_ok),
      comparable_p = dplyr::if_else(is.na(comparable_p), FALSE, comparable_p),
      PIC_obs = ifelse(is.finite(PIC_obs), PIC_obs, NA_real_)
    )
  
  surface_pack[[length(surface_pack) + 1]] <- overlay |>
    dplyr::mutate(window = w, ecdet = ec, subtxt = subtxt)
}

SURF <- dplyr::bind_rows(surface_pack)

readr::write_csv(SURF, file.path(DIRS_OUT$tex, "PIC_surface_pack_Q2.csv"))

# -------------------------
# PANEL A: Admissibility map (status)
# -------------------------
plot_status <- function(d, w, ec, subtxt="") {
  dd <- d |> dplyr::filter(window==w, ecdet==ec)
  ggplot(dd, aes(x=p, y=r)) +
    geom_tile(aes(fill = status), alpha = 0.95) +
    labs(
      title = paste0("A. Status / admissibility | ", w, " | ecdet=", ec),
      subtitle = paste0("status from Engine (gate/runtime/computed). ", subtxt),
      x="p", y="r"
    )
}

for (w in WLIST) {
  for (ec in ECLIST) {
    g <- plot_status(SURF, w, ec)
    ggsave(file.path(DIRS_OUT$figs, paste0("A_STATUS_Q2_", w, "_", ec, ".png")),
           g, width=7, height=4.5, dpi=160)
for (w in unique(SURF$window)) {
  for (ec in unique(SURF$ecdet)) {
    subtxt <- unique(SURF$subtxt[SURF$window==w & SURF$ecdet==ec])[1]
    pA <- plot_status(SURF, w, ec, subtxt)
    ggsave(file.path(DIRS_OUT$figs, paste0("A_STATUS_Q2_", w, "_", ec, ".png")),
           pA, width=7, height=4.5, dpi=160)
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
# PANEL B: Unrestricted PIC surface heatmap (PIC_hat) + overlays
# -------------------------
plot_pic_hat_2d <- function(d, w, ec, subtxt="", final_df=NULL, label="") {
  dd <- d |> dplyr::filter(window==w, ecdet==ec)
  
  base <- ggplot(dd, aes(x=p, y=r)) +
    geom_tile(aes(fill = PIC_hat), alpha = 0.95, na.rm = TRUE) +
    # overlay runtime success points (observed PIC)
    geom_point(data = dd |> dplyr::filter(runtime_ok, is.finite(PIC_obs)),
               aes(x=p, y=r), inherit.aes = FALSE, size=2) +
    # overlay gate failures as X
    geom_point(data = dd |> dplyr::filter(!gate_ok),
               aes(x=p, y=r), inherit.aes = FALSE, shape=4, size=2) +
    labs(
      title = paste0("B. Unrestricted PIC surface (smoothed) | ", w, " | ecdet=", ec,
                     if (nzchar(label)) paste0(" | ", label) else ""),
      subtitle = paste0("Fill = PIC_hat everywhere; dots = runtime success (PIC observed); X = gate_fail. ", subtxt),
      x="p", y="r"
    )
  
  if (!is.null(final_df) && nrow(final_df)>0) {
    ff <- final_df |> dplyr::filter(window==w, ecdet==ec) |> dplyr::select(p,r) |> dplyr::distinct()
    if (nrow(ff)>0) base <- base + geom_point(data=ff, aes(x=p,y=r), inherit.aes=FALSE, size=3)
  }
  base
}

for (w in unique(SURF$window)) {
  for (ec in unique(SURF$ecdet)) {
    subtxt <- unique(SURF$subtxt[SURF$window==w & SURF$ecdet==ec])[1]
    pB <- plot_pic_hat_2d(SURF, w, ec, subtxt=subtxt, final_df=final, label="all p,r support")
    ggsave(file.path(DIRS_OUT$figs, paste0("B_PIC_HAT_Q2_", w, "_", ec, ".png")),
           pB, width=7, height=4.5, dpi=160)
    
    pC <- plot_pic_hat_2d(SURF |> dplyr::filter(comparable_p), w, ec, subtxt=subtxt, final_df=final, label="comparable p-range")
    ggsave(file.path(DIRS_OUT$figs, paste0("B_PIC_HAT_Q2_", w, "_", ec, "_comparable.png")),
           pC, width=7, height=4.5, dpi=160)
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
# PANEL C: Frontier on PIC_hat (best r per p) + show if gate_ok/runtime_ok
# -------------------------
frontier_hat <- function(d) {
  d |>
    dplyr::filter(is.finite(PIC_hat)) |>
    dplyr::group_by(p) |>
    dplyr::slice_min(order_by = PIC_hat, n=1, with_ties=FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(p, r_star = r, PIC_hat_star = PIC_hat, gate_ok, runtime_ok)
}

plot_frontier_hat <- function(d, w, ec, subtxt="", final_df=NULL, label="") {
  dd <- d |> dplyr::filter(window==w, ecdet==ec)
  fr <- frontier_hat(dd)
  
  if (nrow(fr) < 2) {
    return(ggplot() + labs(title=paste0("C. Frontier (PIC_hat) empty | ", w, " | ecdet=", ec)))
  }
  
  # annotate final if present
  ann <- NULL
  if (!is.null(final_df) && nrow(final_df)>0) {
    ann <- final_df |> dplyr::filter(window==w, ecdet==ec) |> dplyr::select(p, PIC=PIC) |> dplyr::distinct()
  }
  
  ggplot(fr, aes(x=p, y=PIC_hat_star)) +
    geom_line(aes(group=1)) +
    geom_point() +
    geom_text(aes(label=paste0("r*=", r_star,
                               ifelse(gate_ok,""," [gate_fail]"),
                               ifelse(runtime_ok,""," [noPIC]"))),
              vjust=-0.6, size=3) +
    labs(
      title = paste0("C. Joint frontier on PIC_hat | ", w, " | ecdet=", ec,
                     if (nzchar(label)) paste0(" | ", label) else ""),
      subtitle = paste0("Uses smoothed surface: each p chooses r minimizing PIC_hat. Tags show gate/runtime reality. ", subtxt),
      x="p", y="min_r PIC_hat(p,r)"
    ) +
    { if (!is.null(ann) && nrow(ann)>0) geom_point(data=ann, aes(x=p, y=PIC), inherit.aes=FALSE, size=3) else NULL }
}

for (w in unique(SURF$window)) {
  for (ec in unique(SURF$ecdet)) {
    subtxt <- unique(SURF$subtxt[SURF$window==w & SURF$ecdet==ec])[1]
    pC1 <- plot_frontier_hat(SURF, w, ec, subtxt=subtxt, final_df=final, label="all p,r support")
    ggsave(file.path(DIRS_OUT$figs, paste0("C_FRONTIER_HAT_Q2_", w, "_", ec, ".png")),
           pC1, width=7, height=4.5, dpi=160)
    
    pC2 <- plot_frontier_hat(SURF |> dplyr::filter(comparable_p), w, ec, subtxt=subtxt, final_df=final, label="comparable p-range")
    ggsave(file.path(DIRS_OUT$figs, paste0("C_FRONTIER_HAT_Q2_", w, "_", ec, "_comparable.png")),
           pC2, width=7, height=4.5, dpi=160)
  }
}

# -------------------------
# PANEL D: Epsilon band on PIC_hat (near-optimal region)
# -------------------------
EPS <- 2.0

plot_eps_hat <- function(d, w, ec, eps=EPS, subtxt="", final_df=NULL) {
  dd <- d |> dplyr::filter(window==w, ecdet==ec, is.finite(PIC_hat))
  if (nrow(dd)==0) return(ggplot() + labs(title=paste0("D. Epsilon band empty | ", w, " | ecdet=", ec)))
  
  m0 <- min(dd$PIC_hat, na.rm=TRUE)
  dd <- dd |> dplyr::mutate(near = (PIC_hat <= m0 + eps))
  
  g <- ggplot(dd, aes(x=p, y=r)) +
    geom_tile(aes(fill=near), alpha=0.95) +
    labs(
      title = paste0("D. Near-optimal region on PIC_hat (≤ min + ", eps, ") | ", w, " | ecdet=", ec),
      subtitle = paste0("Defined on smoothed surface; overlay reality using markers if you want. ", subtxt),
      x="p", y="r"
    )
  
  if (!is.null(final_df) && nrow(final_df)>0) {
    ff <- final_df |> dplyr::filter(window==w, ecdet==ec) |> dplyr::select(p,r) |> dplyr::distinct()
    if (nrow(ff)>0) g <- g + geom_point(data=ff, aes(x=p,y=r), inherit.aes=FALSE, size=3)
  }
  g
}

for (w in unique(SURF$window)) {
  for (ec in unique(SURF$ecdet)) {
    subtxt <- unique(SURF$subtxt[SURF$window==w & SURF$ecdet==ec])[1]
    pD <- plot_eps_hat(SURF, w, ec, eps=EPS, subtxt=subtxt, final_df=final)
    ggsave(file.path(DIRS_OUT$figs, paste0("D_EPSBAND_HAT_Q2_", w, "_", ec, ".png")),
           pD, width=7, height=4.5, dpi=160)
  }
}

# -------------------------
# PANEL E: 3D Surface of PIC_hat + overlays (runtime/gate/final)
# -------------------------
make_surface_matrix <- function(dd) {
  # dd has p,r,PIC_hat complete grid (ideally)
  m <- dd |>
    tidyr::pivot_wider(names_from = p, values_from = PIC_hat) |>
    dplyr::arrange(r)
  r_vals <- m$r
  z <- as.matrix(m[, setdiff(names(m), "r"), drop = FALSE])
  p_vals <- suppressWarnings(as.numeric(colnames(z)))
  list(p_vals=p_vals, r_vals=r_vals, z=z)
}

plot_pic_hat_3d <- function(d, w, ec, label="", final_df=NULL) {
  if (!HAS_PLOTLY || !HAS_HTML) return(NULL)
  
  dd <- d |> dplyr::filter(window==w, ecdet==ec)
  
  # Need a full grid with finite PIC_hat to make a surface
  ddS <- dd |> dplyr::filter(is.finite(PIC_hat))
  title_txt <- paste0("PIC_hat 3D | ", w, " | ecdet=", ec, if (nzchar(label)) paste0(" | ", label) else "")
  
  if (nrow(ddS) < 4) {
    # Explicit empty scatter3d so plotly shuts up
    return(
      plotly::plot_ly(type="scatter3d", mode="markers",
                      x=numeric(0), y=numeric(0), z=numeric(0)) |>
        plotly::layout(title = paste0(title_txt, " | no surface (insufficient data)"))
    )
  }
  
  mat <- make_surface_matrix(ddS)
  fig <- plotly::plot_ly(
    type = "surface",
    x = mat$p_vals, y = mat$r_vals, z = mat$z
  ) |>
    plotly::layout(
      title = title_txt,
      scene = list(
        xaxis = list(title="p"),
        yaxis = list(title="r"),
        zaxis = list(title="PIC_hat")
      )
    )
  
  # Overlay: observed PIC points (runtime success)
  obs <- dd |> dplyr::filter(runtime_ok, is.finite(PIC_obs)) |> dplyr::select(p,r,PIC_obs)
  if (nrow(obs) > 0) {
    fig <- fig |>
      plotly::add_markers(
        data = obs, x=~p, y=~r, z=~PIC_obs,
        type="scatter3d", mode="markers",
        marker = list(size=3),
        name="PIC observed (runtime_ok)"
      )
  }
  
  # Overlay: gate fails (put them on the surface height so you see where they land)
  gf <- dd |> dplyr::filter(!gate_ok, is.finite(PIC_hat)) |> dplyr::select(p,r,PIC_hat)
  if (nrow(gf) > 0) {
    fig <- fig |>
      plotly::add_markers(
        data = gf, x=~p, y=~r, z=~PIC_hat,
        type="scatter3d", mode="markers",
        marker = list(size=3, symbol="x"),
        name="gate_fail"
      )
  }
  
  # Overlay: final pick (if exists)
  if (!is.null(final_df) && nrow(final_df)>0) {
    ff <- final_df |> dplyr::filter(window==w, ecdet==ec) |> dplyr::select(p,r,PIC) |> dplyr::distinct()
    if (nrow(ff) > 0) {
      fig <- fig |>
        plotly::add_markers(
          data = ff, x=~p, y=~r, z=~PIC,
          type="scatter3d", mode="markers",
          marker = list(size=5),
          name="final pick"
        )
    }
  }
  
  fig
}

if (HAS_PLOTLY && HAS_HTML) {
  for (w in unique(SURF$window)) {
    for (ec in unique(SURF$ecdet)) {
      figU <- plot_pic_hat_3d(SURF, w, ec, label="all p,r support", final_df=final)
      htmlwidgets::saveWidget(
        figU,
        file = file.path(DIRS_OUT$html, paste0("E_PIC_HAT_3D_Q2_", w, "_", ec, ".html")),
        selfcontained = TRUE
      )
      
      figC <- plot_pic_hat_3d(SURF |> dplyr::filter(comparable_p), w, ec, label="comparable p-range", final_df=final)
      htmlwidgets::saveWidget(
        figC,
        file = file.path(DIRS_OUT$html, paste0("E_PIC_HAT_3D_Q2_", w, "_", ec, "_comparable.html")),
        selfcontained = TRUE
      )
    }
  }
} else {
  cat("NOTE: plotly/htmlwidgets not installed; skipping 3D outputs.\n")
}

cat("\n=== Report completed OK ===\n")
# -------------------------
# Compact exports for LaTeX ingestion
# -------------------------
frontier_tbl <- SURF |>
  dplyr::filter(is.finite(PIC_hat)) |>
  dplyr::group_by(window, ecdet, p) |>
  dplyr::slice_min(order_by = PIC_hat, n=1, with_ties=FALSE) |>
  dplyr::ungroup() |>
  dplyr::select(window, ecdet, p, r_star = r, PIC_hat_star = PIC_hat, gate_ok, runtime_ok, comparable_p)

readr::write_csv(frontier_tbl, file.path(DIRS_OUT$tex, "frontier_on_PIC_hat_Q2.csv"))

cat("\n=== ChaoGrid_Report completed (vSurfaceEverywhere) ===\n")
