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
