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
