# =========================
# ChaoGrid_3Dplots.R (vNext)
# Q2-only surface plots aligned to new artifacts
# =========================

pkgs <- c("here","readr")
invisible(lapply(pkgs, require, character.only = TRUE))

source(here::here("codes","0_functions.R"))

ROOT_OUT <- here::here("output/ChaoGrid")
DIRS <- list(
  csv  = file.path(ROOT_OUT, "csv"),
  figs = file.path(ROOT_OUT, "figs")
)
ensure_dirs(DIRS$figs)

grid_path <- file.path(DIRS$csv, "grid_pic_table_Q2.csv")
stopifnot(file.exists(grid_path))
dfG <- readr::read_csv(grid_path, show_col_types = FALSE)

has_plotly <- requireNamespace("plotly", quietly = TRUE) && requireNamespace("htmlwidgets", quietly = TRUE)

make_surface_matrix <- function(df, value_col = "PIC") {
  ps <- sort(unique(df$p))
  rs <- sort(unique(df$r))
  Z  <- matrix(NA_real_, nrow = length(rs), ncol = length(ps),
               dimnames = list(r = rs, p = ps))
  for (i in seq_len(nrow(df))) {
    Z[as.character(df$r[i]), as.character(df$p[i])] <- df[[value_col]][i]
  }
  list(ps = ps, rs = rs, Z = Z)
}

for (w in unique(dfG$window)) {
  for (ec in ECDET_LOCKED) {
    sub <- dfG[dfG$grid == "comparable" & dfG$window == w & dfG$ecdet == ec, , drop = FALSE]
    if (nrow(sub) == 0) next
    
    sm <- make_surface_matrix(sub, "PIC")
    
    if (has_plotly) {
      p <- plotly::plot_ly(x = sm$ps, y = sm$rs, z = sm$Z, type = "surface") |>
        plotly::layout(
          title = paste0("PIC surface (Q2 comparable) — ", w, " / ecdet=", ec),
          scene = list(
            xaxis = list(title = "p"),
            yaxis = list(title = "r"),
            zaxis = list(title = "PIC")
          )
        )
      
      htmlwidgets::saveWidget(
        p,
        file = file.path(DIRS$figs, paste0("S5_surface_PIC_Q2_", w, "_", ec, ".html")),
        selfcontained = TRUE
      )
    } else {
      png(file.path(DIRS$figs, paste0("S5_surface_PIC_Q2_", w, "_", ec, ".png")),
          width = 1000, height = 700)
      try({
        persp(sm$ps, sm$rs, sm$Z,
              theta = 35, phi = 25,
              xlab = "p", ylab = "r", zlab = "PIC",
              main = paste0("PIC surface (Q2 comparable) — ", w, " / ecdet=", ec))
      }, silent = TRUE)
      dev.off()
    }
  }
}

message("ChaoGrid_3Dplots.R completed.")
