############################################################
# 99_utils.R — Shared utilities for Chapter 3 pipeline
############################################################

`%||%` <- function(x, y) if (is.null(x)) y else x

# ------------------------------------------------------------------
# Logging helpers
# ------------------------------------------------------------------
now_stamp <- function() format(Sys.time(), "%Y-%m-%d %H:%M:%S")

# ------------------------------------------------------------------
# Safe I/O helpers
# ------------------------------------------------------------------
safe_write_csv <- function(df, path) {
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  utils::write.csv(df, path, row.names = FALSE)
}

# ------------------------------------------------------------------
# Unified dummy builder — shock-type aware
# ------------------------------------------------------------------
make_dummies <- function(df, years, type = c("permanent", "transitory")) {
  type <- match.arg(type)
  for (yy in years) {
    df[[paste0("d", yy)]] <- if (type == "permanent") {
      as.integer(df$year >= yy)   # step dummy (permanent regime shift)
    } else {
      as.integer(df$year == yy)   # impulse dummy (transitory shock)
    }
  }
  df
}
