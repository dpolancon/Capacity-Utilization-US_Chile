############################################################

# 20_CR_ARDL_grid.R

#

# Stage 4 – Critical Replication

# ARDL Auto-Grid + Geometry + Frontiers

#

# Window: shaikh_window (LOCKED)

# Output root: output/CriticalReplication/

############################################################

rm(list = ls())

suppressPackageStartupMessages({
  library(here)
  library(readxl)
  library(dplyr)
  library(ARDL)
  library(ggplot2)
})

# ----------------------------------------------------------

# Load config + utils

# ----------------------------------------------------------

source(here::here("codes", "10_config.R"))
source(here::here("codes", "99_utils.R"))
source(here::here("codes", "25_envelope_tools.R"))
source(here::here("codes", "24_complexity_penalties.R"))

set.seed(CONFIG$seed)

# ----------------------------------------------------------

# Output root (Stage 4 contract)

# ----------------------------------------------------------

OUT_ROOT <- here::here(CONFIG$OUT_CR_ROOT %||% "output/CriticalReplication")
EXERCISE_DIR <- here::here(CONFIG$OUT_CR$exercise_b %||% "output/CriticalReplication/Exercise_b_ARDL_grid")
CSV_DIR  <- file.path(EXERCISE_DIR, "csv")
FIG_DIR  <- file.path(EXERCISE_DIR, "figs")
LOG_DIR  <- file.path(EXERCISE_DIR, "logs")
MAN_DIR  <- here::here(CONFIG$OUT_CR$manifest %||% "output/CriticalReplication/Manifest")

dir.create(CSV_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(FIG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(LOG_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(MAN_DIR, recursive = TRUE, showWarnings = FALSE)

WINDOW_TAG <- "shaikh_window"
w <- CONFIG$WINDOWS_LOCKED[[WINDOW_TAG]]
WINDOW_START <- as.integer(w[1])
WINDOW_END <- as.integer(w[2])

# ----------------------------------------------------------

# Load Shaikh dataset

# ----------------------------------------------------------

df_raw <- read_excel(here::here(CONFIG$data_shaikh),
                     sheet = CONFIG$data_shaikh_sheet)

df <- df_raw |>
  transmute(
    year  = as.integer(.data[[CONFIG$year_col]]),
    Y_nom = as.numeric(.data[[CONFIG$y_nom]]),
    K_nom = as.numeric(.data[[CONFIG$k_nom]]),
    p     = as.numeric(.data[[CONFIG$p_index]])
  ) |>
  filter(is.finite(year), is.finite(Y_nom),
         is.finite(K_nom), is.finite(p), p > 0) |>
  mutate(
    p_scale = p / 100,
    Y_real  = Y_nom / p_scale,
    K_real  = K_nom / p_scale,
    lnY     = log(Y_real),
    lnK     = log(K_real)
  ) |>
  filter(year >= w[1], year <= w[2]) |>
  arrange(year)

T_obs <- nrow(df)

# ----------------------------------------------------------

# Auto-ARDL grid

# ----------------------------------------------------------

P_MAX <- 4
Q_MAX <- 4

grid_results <- list()

for (p in 1:P_MAX) {
  for (q in 1:Q_MAX) {
    
    fml <- as.formula("lnY ~ lnK")

    fit_try <- try(
      ARDL::ardl(
        formula = fml,
        data    = ts(df[, c("lnY", "lnK")],
                     start = min(df$year), frequency = 1),
        order   = c(p, q)
      ),
      silent = TRUE
    )
    
    if (inherits(fit_try, "try-error")) next
    
    fit <- fit_try
    
    ll  <- as.numeric(logLik(fit))
    k   <- length(coef(fit))
    
    AIC_val  <- AIC(fit)
    BIC_val  <- BIC(fit)
    HQ_val   <- AIC_val + 2 * log(log(T_obs))
    AICc_val <- AIC_val + (2*k*(k+1))/(T_obs - k - 1)
    
    Sigma_hat <- vcov(fit)
    icomp_pen  <- log(det(Sigma_hat))
    ricomp_pen <- log(sum(diag(Sigma_hat)^2))
    
    comp_row <- compute_complexity_record(
      exercise = "ARDL",
      model_class = "ARDL",
      window = WINDOW_TAG,
      window_tag = WINDOW_TAG,
      window_start = WINDOW_START,
      window_end = WINDOW_END,
      p = p,
      r = NA,
      logLik = ll,
      k = k,
      ICOMP_pen = icomp_pen,
      RICOMP_pen = ricomp_pen,
      AIC = AIC_val,
      BIC = BIC_val,
      HQ = HQ_val,
      AICc = AICc_val,
      SI_Y = NA,
      s_K = q / (p + q),
      notes = "",
      extra = list()
    )
    comp_row <- compute_complexity_record(
      model_class = "ARDL",
      logLik = ll,
      k_total = k,
      vcov_mat = Sigma_hat,
      T_eff = T_obs,
      extra = list(
        exercise = "ARDL",
        window = WINDOW_TAG,
        window_tag = WINDOW_TAG,
        window_start = WINDOW_START,
        window_end = WINDOW_END,
        p = p,
        q = q,
        r = NA,
        logLik = ll,
        k_total = k,
        ICOMP_pen = icomp_pen,
        RICOMP_pen = ricomp_pen,
        k = k,
        AIC = AIC_val,
        BIC = BIC_val,
        HQ = HQ_val,
        AICc = AICc_val,
        SI_Y = NA,
        s_K = q / (p + q),
        notes = "",
        fit_term_source = "ARDL::logLik_gaussian_OLS",
        covariance_source = "vcov(ARDL_fit)_OLS"
      )
    
    )

    grid_results[[length(grid_results) + 1]] <- comp_row

  }
}

geom_df <- bind_rows(grid_results)

# ----------------------------------------------------------

# Geometry cards export

# ----------------------------------------------------------

geom_path <- file.path(CSV_DIR, "GEOMETRY_CARDS_ARDL.csv")
write.csv(geom_df, geom_path, row.names = FALSE)

# ----------------------------------------------------------

# Mandatory frontier planes

# ----------------------------------------------------------

write_envelope_plane(
  geom_df,
  x_col = "k_total",
  y_col = "logLik",
  csv_path = file.path(CSV_DIR, "ENVELOPE_ARDL_logLik_vs_k_total.csv"),
  fig_path = file.path(FIG_DIR, "FIG_Frontier_ARDL_logLik_vs_k_total.png"),
  title = "ARDL frontier: logLik vs k_total"
)

write_envelope_plane(
  geom_df,
  x_col = "ICOMP_pen",
  y_col = "logLik",
  csv_path = file.path(CSV_DIR, "ENVELOPE_ARDL_logLik_vs_ICOMP_pen.csv"),
  fig_path = file.path(FIG_DIR, "FIG_Frontier_ARDL_logLik_vs_ICOMP_pen.png"),
  title = "ARDL frontier: logLik vs ICOMP_pen"
)

write_envelope_plane(
  geom_df,
  x_col = "RICOMP_pen",
  y_col = "logLik",
  csv_path = file.path(CSV_DIR, "ENVELOPE_ARDL_logLik_vs_RICOMP_pen.csv"),
  fig_path = file.path(FIG_DIR, "FIG_Frontier_ARDL_logLik_vs_RICOMP_pen.png"),
  title = "ARDL frontier: logLik vs RICOMP_pen"
)

# ----------------------------------------------------------

# Manifest append

# ----------------------------------------------------------

manifest_path <- file.path(MAN_DIR, "RUN_MANIFEST_stage4.md")

cat(
  paste0(
    "# Run Manifest (Stage 4)\n",
    "- window_tag: ", WINDOW_TAG, "\n",
    "- window_start: ", WINDOW_START, "\n",
    "- window_end: ", WINDOW_END, "\n\n",
    "## Script: codes/21_CR_ARDL_grid.R\n",
    "- exercise_output: output/CriticalReplication/Exercise_b_ARDL_grid/\n",
    "- window_tag: ", WINDOW_TAG, "\n",
    "- window_start: ", WINDOW_START, "\n",
    "- window_end: ", WINDOW_END, "\n",
    "- Observations: ", T_obs, "\n",
    "- Grid: p,q ≤ ", P_MAX, "\n",
    "- Timestamp: ", Sys.time(), "\n\n"
  ),
  file = manifest_path,
  append = TRUE
)

cat("\nStage 4 ARDL grid complete.\n")
############################################################
