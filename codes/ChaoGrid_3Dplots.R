############################################################
## ChaoGrid_Plotly3D_GLOBAL_MARKERS.R
##
## For each window: dropdown modes = none / const / trend / GLOBAL
## Each mode shows:
##   - ΔPIC surface
##   - marker at BEST (p*, r*) for that mode
############################################################

suppressPackageStartupMessages({
  if (!requireNamespace("plotly", quietly = TRUE)) install.packages("plotly")
  if (!requireNamespace("htmlwidgets", quietly = TRUE)) install.packages("htmlwidgets")
  if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
  if (!requireNamespace("tidyr", quietly = TRUE)) install.packages("tidyr")
  if (!requireNamespace("here", quietly = TRUE)) install.packages("here")
  
  library(plotly)
  library(htmlwidgets)
  library(dplyr)
  library(tidyr)
  library(here)
})

# ---- paths ----
ROOT_OUT <- here::here("output/ChaoGrid")
DIRS <- list(
  csv   = file.path(ROOT_OUT, "csv"),
  html3d = file.path(ROOT_OUT, "html_3d")
)
dir.create(DIRS$html3d, recursive = TRUE, showWarnings = FALSE)

pic_path <- file.path(DIRS$csv, "grid_pic_table.csv")
stopifnot(file.exists(pic_path))

# ---- constants ----
WINDOW_ORDER <- c("full","ford","post")
ECDET_ORDER  <- c("none","const","trend")
ECDET_LABELS <- c(none = "No Constant", const = "Constant", trend = "Trend")

# ---- load ----
pt <- read.csv(pic_path, stringsAsFactors = FALSE) %>%
  mutate(
    window = as.character(window),
    ecdet  = as.character(ecdet),
    p      = as.integer(p),
    r      = as.integer(r),
    PIC    = as.numeric(PIC),
    logdet = if ("logdet" %in% names(.)) as.numeric(logdet) else NA_real_,
    k_par  = if ("k_par"  %in% names(.)) as.numeric(k_par)  else NA_real_
  ) %>%
  mutate(
    window = factor(window, levels = WINDOW_ORDER),
    ecdet  = factor(ecdet,  levels = ECDET_ORDER)
  ) %>%
  arrange(window, ecdet, p, r)

# ---- compute within-ecdet and global ΔPIC ----
pt <- pt %>%
  group_by(window, ecdet) %>%
  mutate(
    dPIC_within = PIC - min(PIC, na.rm = TRUE),
    is_best_within = (PIC == min(PIC, na.rm = TRUE))
  ) %>%
  ungroup() %>%
  group_by(window) %>%
  mutate(
    dPIC_global = PIC - min(PIC, na.rm = TRUE),
    is_best_global = (PIC == min(PIC, na.rm = TRUE))
  ) %>%
  ungroup()

# ---- helper: build full grid matrix ----
to_surface_mats <- function(df_sub, z_col) {
  stopifnot(z_col %in% names(df_sub))
  
  p_vals <- sort(unique(df_sub$p))
  r_vals <- sort(unique(df_sub$r))
  
  df_grid <- tidyr::expand_grid(p = p_vals, r = r_vals) %>%
    dplyr::left_join(df_sub, by = c("p","r"))
  
  z_mat <- matrix(df_grid[[z_col]],
                  nrow = length(r_vals),
                  ncol = length(p_vals),
                  byrow = TRUE)
  
  list(p_vals = p_vals, r_vals = r_vals, z_mat = z_mat, df_grid = df_grid)
}

# ---- helper: build hover matrix + z ----
make_surface_data <- function(df_sub, z_col, best_flag_col, mode_tag, zmax_cap = NULL) {
  mats <- to_surface_mats(df_sub, z_col = z_col)
  x <- mats$p_vals
  y <- mats$r_vals
  z <- mats$z_mat
  
  if (!is.null(zmax_cap)) z[z > zmax_cap] <- zmax_cap
  
  hover_df <- mats$df_grid %>%
    mutate(
      window_chr = as.character(window),
      ecdet_chr  = as.character(ecdet),
      ecdet_label = ifelse(is.na(ecdet_chr), "GLOBAL", ECDET_LABELS[ecdet_chr]),
      zval = .data[[z_col]],
      best_flag = .data[[best_flag_col]],
      hover = paste0(
        "window: ", window_chr,
        "<br>mode: ", mode_tag,
        "<br>ecdet: ", ecdet_label,
        "<br>p: ", p,
        "<br>r: ", r,
        "<br>PIC: ", ifelse(is.na(PIC), "NA", sprintf("%.4f", PIC)),
        "<br>ΔPIC: ", ifelse(is.na(zval), "NA", sprintf("%.4f", zval)),
        if (!all(is.na(logdet))) paste0("<br>logdet: ", ifelse(is.na(logdet), "NA", sprintf("%.4f", logdet))) else "",
        if (!all(is.na(k_par)))  paste0("<br>k_par: ",  ifelse(is.na(k_par),  "NA", sprintf("%.0f", k_par)))  else "",
        ifelse(isTRUE(best_flag), "<br><b>BEST</b>", "")
      )
    )
  
  text <- matrix(hover_df$hover, nrow = length(y), ncol = length(x), byrow = TRUE)
  
  list(x = x, y = y, z = z, text = text)
}

# ---- helper: find best point for a mode ----
best_point <- function(df_sub, best_flag_col, z_col) {
  stopifnot(best_flag_col %in% names(df_sub), z_col %in% names(df_sub))
  
  bp <- df_sub %>%
    dplyr::filter(.data[[best_flag_col]] == TRUE) %>%
    dplyr::arrange(PIC, p, r) %>%   # deterministic tie-breaker
    dplyr::slice(1)
  
  list(
    p = as.numeric(bp$p),
    r = as.numeric(bp$r),
    z = as.numeric(bp[[z_col]]),
    hover = paste0(
      "<b>BEST</b>",
      "<br>p: ", bp$p,
      "<br>r: ", bp$r,
      "<br>PIC: ", sprintf("%.4f", bp$PIC),
      "<br>ΔPIC: ", sprintf("%.4f", bp[[z_col]])
    )
  )
}

# ---- per window: build dropdown with 4 modes, each = 2 traces (surface+marker) ----
plot_window_dropdown_global_markers <- function(pt, window_name,
                                                contours = c(0.5, 1, 2),
                                                zmax_cap = NULL) {
  
  dfw <- pt %>% dplyr::filter(as.character(window) == window_name)
  stopifnot(nrow(dfw) > 0)
  
  # axis maxima from the window grid
  max_p <- max(dfw$p, na.rm = TRUE)
  max_r <- max(dfw$r, na.rm = TRUE)
  
  modes <- c(ECDET_ORDER, "GLOBAL")
  
  fig <- plotly::plot_ly()
  mode_titles <- character(length(modes))
  
  # We'll track a safe z max for axis range (post-cap)
  z_max_seen <- 0
  
  for (i in seq_along(modes)) {
    mode <- modes[i]
    
    if (mode == "GLOBAL") {
      sub <- dfw
      z_col <- "dPIC_global"
      best_col <- "is_best_global"
      mode_tag <- "GLOBAL (across ecdet)"
      mode_titles[i] <- "GLOBAL"
    } else {
      sub <- dfw %>% dplyr::filter(as.character(ecdet) == mode)
      z_col <- "dPIC_within"
      best_col <- "is_best_within"
      mode_tag <- paste0(ECDET_LABELS[[mode]], " (within ecdet)")
      mode_titles[i] <- ECDET_LABELS[[mode]]
    }
    
    # surface
    surf <- make_surface_data(sub, z_col = z_col, best_flag_col = best_col,
                              mode_tag = mode_tag, zmax_cap = zmax_cap)
    
    # update z max tracker
    z_max_seen <- max(z_max_seen, max(surf$z, na.rm = TRUE))
    
    fig <- fig %>% plotly::add_surface(
      x = surf$x, y = surf$y, z = surf$z,
      text = surf$text, hoverinfo = "text",
      contours = list(
        z = list(
          show = TRUE,
          usecolormap = TRUE,
          project = list(z = TRUE),
          start = min(contours),
          end   = max(contours),
          size  = if (length(contours) > 1) min(diff(sort(contours))) else 0.5
        )
      ),
      visible = (i == 1)
    )
    
    # marker for BEST
    bp <- best_point(sub, best_flag_col = best_col, z_col = z_col)
    
    fig <- fig %>% plotly::add_markers(
      x = bp$p, y = bp$r, z = bp$z,
      text = bp$hover, hoverinfo = "text",
      marker = list(size = 6, symbol = "circle"),
      visible = (i == 1)
    )
  }
  
  # Dropdown visibility: 2 traces per mode (surface + marker)
  n_modes <- length(modes)
  n_traces <- 2 * n_modes
  
  buttons <- lapply(seq_along(modes), function(i) {
    vis <- rep(FALSE, n_traces)
    vis[(2*i - 1):(2*i)] <- TRUE
    
    list(
      method = "update",
      args = list(
        list(visible = vis),
        list(title = paste0("S5.4 3D ΔPIC surface (window: ", window_name, "; mode: ", mode_titles[i], ")"))
      ),
      label = mode_titles[i]
    )
  })
  
  # Force axes to start at 0 and include 0 ticks
  fig %>%
    plotly::layout(
      title = list(text = paste0("S5.4 3D ΔPIC surface (window: ", window_name, "; mode: ", mode_titles[1], ")")),
      scene = list(
        xaxis = list(
          title = "p (VAR lag length)",
          range = c(0,max_p),
          tickmode = "array",
          tickvals = 0:max_p
        ),
        yaxis = list(
          title = "r (cointegration rank)",
          range = c(0, max_r),
          tickmode = "array",
          tickvals = 0:max_r
        ),
        zaxis = list(
          title = "ΔPIC",
          range = c(0, z_max_seen)
        ),
        camera = list(eye = list(x = 1.35, y = 1.35, z = 0.85))
      ),
      updatemenus = list(list(
        type = "dropdown",
        direction = "down",
        x = 0.02, y = 0.98,
        showactive = TRUE,
        buttons = buttons
      )),
      margin = list(l = 0, r = 0, b = 0, t = 55)
    )
}

# ---- run & save ----
contours <- c(0.5, 1, 2)

for (w in WINDOW_ORDER) {
  zcap <- if (w == "ford") 4 else NULL
  
  fig <- plot_window_dropdown_global_markers(pt, w, contours = contours, zmax_cap = zcap)
  
  out <- file.path(DIRS$html3d, paste0("S5_4_plotly_surface_dPIC_", w, ".html"))
  htmlwidgets::saveWidget(fig, out, selfcontained = TRUE)
  message("Saved HTML: ", out)
}

message("Done. HTML 3D diagnostics in: ", DIRS$html3d)
