# Diagnostics – Visuals only #

#### 0) Packages (viz + data wrangling only)  ####
pkgs <- c(
  "here","readxl","dplyr","tidyr","ggplot2","zoo",
  "patchwork","stats","knitr"
)
invisible(lapply(pkgs, require, character.only = TRUE))

#### 1) Preamble: paths, helpers, data  ####
source(paste0(here("codes"), "/0_functions.R"))  # uses your helpers: ensure_dirs, set_seed_deterministic, save_*()
data_path   <- here("data/processed/ddbb_cu_US_kgr.xlsx")
output_path <- here("output")

set_seed_deterministic()  # deterministic plots
ensure_dirs(file.path(output_path, "diagnostics", "visuals"))

ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

#### 2) Build variables (exact scope you requested) ####
dfv <- ddbb_us |>
  dplyr::transmute(
    year      = .data$year,
    K         = .data$KGCRcorp,
    Y         = .data$Yrgdp,
    e         = .data$e,
    yk_input  = .data$yk,              # provided ratio (for cross-check)
    yk_calc   = .data$Yrgdp / .data$KGCRcorp,
    log_y     = log(.data$Yrgdp),
    log_k     = log(.data$KGCRcorp),
    log_yk    = log(yk_calc),
    e2        = (.data$e)^2,
    e_logk     = log_k*e,
    e2_logk     = log_k*e2,
    d_yk      = yk_calc - dplyr::lag(yk_calc),
    d_log_y   = log_y - dplyr::lag(log_y),
    d_log_k   = log_k - dplyr::lag(log_k),
    d_log_yk  = log_yk - dplyr::lag(log_yk),
    d_e       = e - dplyr::lag(e),
    d_e2      = e2 - dplyr::lag(e2),
    d_e_logk  = e_logk - dplyr::lag(e_logk),
    d_e2_logk = e2_logk - dplyr::lag(e2_logk)
  )

# --- fixed series_order: use yk_calc, not yk ---
series_order <- c(
  "yk_calc","log_yk","d_yk","d_log_yk",
  "e","d_e","e2","d_e2",
  "log_y","d_log_y","log_k","d_log_k",
  "e_logk","d_e_logk", "e2_logk", "d_e2_logk"
  # optionally add "yk_input" if you want visuals for the provided ratio too
)

#### 3) robust helpers (filter finite, align t/x, safely skip empties) ####
make_ts_df <- function(x, nm, tvec) {
  if (is.null(x)) return(NULL)
  idx <- which(is.finite(x) & is.finite(tvec))
  if (length(idx) == 0) return(NULL)
  data.frame(t = tvec[idx], val = as.numeric(x[idx]), var = nm)
}

plot_ts <- function(df, title) {
  ggplot2::ggplot(df, ggplot2::aes(t, val)) +
    ggplot2::geom_line() +
    ggplot2::labs(x = NULL, y = NULL, title = title) +
    ggplot2::theme_minimal(base_size = 11)
}

plot_hist <- function(df, title) {
  ggplot2::ggplot(df, ggplot2::aes(val)) +
    ggplot2::geom_histogram(bins = 30) +
    ggplot2::labs(x = NULL, y = NULL, title = title) +
    ggplot2::theme_minimal(base_size = 11)
}

plot_qq <- function(x, title) {
  x <- x[is.finite(x)]
  if (!length(x)) return(NULL)
  df <- data.frame(sample = sort(as.numeric(x)))
  ggplot2::ggplot(df, ggplot2::aes(sample = sample)) +
    ggplot2::stat_qq() + ggplot2::stat_qq_line() +
    ggplot2::labs(title = title) +
    ggplot2::theme_minimal(base_size = 11)
}

save_acf_pacf <- function(x, stem) {
  x <- x[is.finite(x)]
  if (!length(x)) return(invisible(NULL))
  save_baseplot_dual({ stats::acf(x,  lag.max = 36, main = "ACF") },
                     file.path(output_path,"diagnostics","visuals", paste0(stem, "_acf")))
  save_baseplot_dual({ stats::pacf(x, lag.max = 36, main = "PACF") },
                     file.path(output_path,"diagnostics","visuals", paste0(stem, "_pacf")))
}

####  4) plotting loop (time axis = year; skip empties) ####
for (nm in series_order) {
  x  <- dfv[[nm]]
  tt <- dfv$year
  ts_df <- make_ts_df(x, nm, tt)
  if (is.null(ts_df)) {
    message("Skipping '", nm, "' (empty or non-finite).")
    next
  }
  
  p_ts  <- plot_ts(ts_df, paste0(nm, " — time series"))
  save_plot_dual(p_ts, file.path(output_path,"diagnostics","visuals", paste0(nm, "_ts")))
  
  p_h   <- plot_hist(ts_df, paste0(nm, " — histogram"))
  save_plot_dual(p_h,  file.path(output_path,"diagnostics","visuals", paste0(nm, "_hist")))
  
  p_qq  <- plot_qq(x, paste0(nm, " — QQ plot"))
  if (!is.null(p_qq)) {
    save_plot_dual(p_qq, file.path(output_path,"diagnostics","visuals", paste0(nm, "_qq")))
  } else {
    message("Skipping QQ for '", nm, "' (empty after filtering).")
  }
  
  save_acf_pacf(x, nm)
}

#### 5) Minimal manifest #####
write_session_info(file.path(output_path,"diagnostics","visuals","session_info.txt"))
cat("Visual diagnostics completed. Files in: ", file.path(output_path,"diagnostics","visuals"), "\n")
