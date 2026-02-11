############################################################
## UNIT ROOT TABLES — FULL VARIABLE SET (incl. cubic term)
## Full + Fordist + Post-Fordist
## Exports to UNIT_ROOT_TABLES_CORE/tex and /csv
############################################################

#### 0) Packages  ####
pkgs <- c(
  "here","readxl","dplyr","tidyr","ggplot2","zoo",
  "patchwork","stats","knitr","kableExtra",
  "urca","vars","tseries","lmtest","sandwich","strucchange"
)
invisible(lapply(pkgs, require, character.only = TRUE))

#### 1) Preamble: paths, helpers, data  ####
source(paste0(here::here("codes"), "/0_functions.R"))  # UnitRootTests + exporters + ensure_dirs

data_path   <- here::here("data/processed/ddbb_cu_US_kgr.xlsx")
output_path <- here::here("output")

set_seed_deterministic()
ensure_dirs(output_path)

ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

#### 2) Build base variables (levels + diffs) ####
df <- ddbb_us |>
  dplyr::transmute(
    year      = .data$year,
    K         = .data$KGCRcorp,
    Y         = .data$Yrgdp,
    e         = .data$e,                # exploitation = profits / wage bill
    yk_input  = .data$yk,
    yk_calc   = .data$Yrgdp / .data$KGCRcorp,
    log_y     = log(.data$Yrgdp),
    log_k     = log(.data$KGCRcorp),
    log_yk    = log(yk_calc),
    e2        = (.data$e)^2,
    # differences (base)
    d_log_y   = log_y - dplyr::lag(log_y),
    d_log_k   = log_k - dplyr::lag(log_k),
    d_e       = e     - dplyr::lag(e)
  ) |>
  dplyr::arrange(year)

#### 3) Window-specific demean + interactions (incl. cubic) + diffs ####
add_e_bar_and_interactions <- function(dfw) {
    mu_e <- mean(dfw$e, na.rm = TRUE)
    
    dfw |>
      dplyr::arrange(year) |>
      dplyr::mutate(
        # demeaned exploitation and powers
        e_bar   = e - mu_e,
        e_bar2  = e_bar^2,
        e_bar3  = e_bar^3,
        
        # raw powers (optional but useful if you want them tested too)
        e2      = e^2,
        e3      = e^3,
        
        # raw interactions required by strategy
        logK_e   = log_k * e,
        logK_e2  = log_k * e2,
        logK_e3  = log_k * e3,
        
        # demeaned interactions (multicollinearity-safe basis)
        logK_ebar  = log_k * e_bar,
        logK_ebar2 = log_k * e_bar2,
        logK_ebar3 = log_k * e_bar3,
        
        # differences of constructed terms
        d_e_bar       = e_bar       - dplyr::lag(e_bar),
        d_logK_e      = logK_e      - dplyr::lag(logK_e),
        d_logK_e2     = logK_e2     - dplyr::lag(logK_e2),
        d_logK_e3     = logK_e3     - dplyr::lag(logK_e3),
        d_logK_ebar   = logK_ebar   - dplyr::lag(logK_ebar),
        d_logK_ebar2  = logK_ebar2  - dplyr::lag(logK_ebar2),
        d_logK_ebar3  = logK_ebar3  - dplyr::lag(logK_ebar3)
      )
}

#### 4) Unit-root table machinery (visuals-informed deterministics) ####

# Variables (levels + differences) to include
vars_lvl <- c(
  "log_y","log_k",
  "e","e_bar",
  "logK_e","logK_e2","logK_e3",
  "logK_ebar","logK_ebar2","logK_ebar3"
)

vars_dif <- c(
  "d_log_y","d_log_k",
  "d_e","d_e_bar",
  "d_logK_e","d_logK_e2","d_logK_e3",
  "d_logK_ebar","d_logK_ebar2","d_logK_ebar3"
)

# Decide deterministic for a level series using a trend proxy
choose_model_type <- function(x, t, alpha = 0.10) {
  ok <- is.finite(x) & is.finite(t)
  x <- x[ok]; t <- t[ok]
  if (length(x) < 20) return("constant")
  p_trend <- tryCatch(summary(lm(x ~ t))$coefficients["t", "Pr(>|t|)"], error = function(e) NA_real_)
  if (is.finite(p_trend) && p_trend < alpha) "trend" else "constant"
}

# Run UnitRootTests for one series at a time (so model_type can differ by variable)
unitroot_onevar_table <- function(x, model_type,
                                  adf_lag_select = "BIC",
                                  ers_lag_max = 5,
                                  pp_lags = "long",
                                  digits = 2) {
  dat <- data.frame(series = as.numeric(x))
  res <- UnitRootTests(dat,
                       model_type = model_type,
                       adf_lag_select = adf_lag_select,
                       ers_lag_max = ers_lag_max,
                       pp_lags = pp_lags)
  processAndAddStars(res, tidy = FALSE, digits = digits)
}

# Build the Table-5 style panel for a given window
make_unitroot_panel <- function(df_window, window_tag,
                                trend_alpha = 0.10,
                                adf_lag_select = "BIC",
                                ers_lag_max = 5,
                                pp_lags = "long",
                                digits = 2) {
  
  need <- c("year", vars_lvl, vars_dif)
  stopifnot(all(need %in% names(df_window)))
  
  tvec <- df_window$year
  
  # levels: visuals-informed except demeaned objects forced constant
  demeaned_const <- c("e_bar","logK_ebar","logK_ebar2","logK_ebar3")
  model_map <- setNames(
    vapply(vars_lvl, function(v) {
      if (v %in% demeaned_const) "constant"
      else choose_model_type(df_window[[v]], tvec, alpha = trend_alpha)
    }, character(1)),
    vars_lvl
  )
  
  panels <- list()
  
  # Levels
  for (v in vars_lvl) {
    tab <- unitroot_onevar_table(df_window[[v]], model_type = model_map[[v]],
                                 adf_lag_select = adf_lag_select,
                                 ers_lag_max = ers_lag_max,
                                 pp_lags = pp_lags,
                                 digits = digits)
    rownames(tab) <- v
    panels[[v]] <- tab
  }
  
  # Differences (constant by default)
  for (v in vars_dif) {
    tab <- unitroot_onevar_table(df_window[[v]], model_type = "constant",
                                 adf_lag_select = adf_lag_select,
                                 ers_lag_max = ers_lag_max,
                                 pp_lags = pp_lags,
                                 digits = digits)
    rownames(tab) <- v
    panels[[v]] <- tab
  }
  
  panel <- do.call(rbind, panels)
  
  # Pretty labels (LaTeX-friendly) with safe fallback
  pretty <- c(
    log_y         = "logY",
    log_k         = "logK",
    e             = "e",
    e_bar         = "\\bar{e}",
    
    logK_e        = "logK \\cdot e",
    logK_e2       = "logK \\cdot e^{2}",
    logK_e3       = "logK \\cdot e^{3}",
    
    logK_ebar     = "logK \\cdot \\bar{e}",
    logK_ebar2    = "logK \\cdot \\bar{e}^{2}",
    logK_ebar3    = "logK \\cdot \\bar{e}^{3}",
    
    d_log_y       = "\\Delta logY",
    d_log_k       = "\\Delta logK",
    d_e           = "\\Delta e",
    d_e_bar       = "\\Delta \\bar{e}",
    
    d_logK_e      = "\\Delta (logK \\cdot e)",
    d_logK_e2     = "\\Delta (logK \\cdot e^{2})",
    d_logK_e3     = "\\Delta (logK \\cdot e^{3})",
    
    d_logK_ebar   = "\\Delta (logK \\cdot \\bar{e})",
    d_logK_ebar2  = "\\Delta (logK \\cdot \\bar{e}^{2})",
    d_logK_ebar3  = "\\Delta (logK \\cdot \\bar{e}^{3})"
  )
  rn <- rownames(panel)
  rownames(panel) <- ifelse(!is.na(pretty[rn]), pretty[rn], rn)
  
  det_note <- paste0(
    "Window: ", window_tag, ". ",
    "Deterministics (levels): ",
    paste(sprintf("%s=%s", names(model_map), model_map), collapse = ", "),
    ". Differences use constant."
  )
  
  list(panel = panel, det_note = det_note)
}

#### 5) Output folders (locked structure) ####
UNITROOT_DIR <- file.path(output_path, "UNIT_ROOT_TABLES_CORE")
UNITROOT_TEX <- file.path(UNITROOT_DIR, "tex")
UNITROOT_CSV <- file.path(UNITROOT_DIR, "csv")
ensure_dirs(c(UNITROOT_DIR, UNITROOT_TEX, UNITROOT_CSV))

# Export wrapper (writes into /tex and /csv forks)
export_panel <- function(P, file_stub, caption) {
  save_table_tex_csv(
    P$panel,
    tex_path = file.path(UNITROOT_TEX, paste0(file_stub, ".tex")),
    csv_path = file.path(UNITROOT_CSV, paste0(file_stub, ".csv")),
    caption  = caption,
    footnote = paste(
      "ADF/PP/DF-GLS/ERS reject unit root for sufficiently negative statistics;",
      "KPSS rejects stationarity for large statistics (stars reversed).",
      P$det_note
    ),
    escape = FALSE,
    overwrite = TRUE
  )
}

#### 6) Windows + run + export ####

# Full + regime windows with window-specific e_bar and interactions
df_full <- df |> dplyr::filter(year >= 1925, year <= 2023) |> add_e_bar_and_interactions()
df_ford <- df |> dplyr::filter(year >= 1925, year <= 1973) |> add_e_bar_and_interactions()
df_post <- df |> dplyr::filter(year >= 1974, year <= 2023) |> add_e_bar_and_interactions()

# Panels
P_full <- make_unitroot_panel(df_full, "1925_2023")
P_ford <- make_unitroot_panel(df_ford, "1925_1973")
P_post <- make_unitroot_panel(df_post, "1974_2023")

# Export (LaTeX + CSV)
export_panel(P_full, "unitroot_allvars_full_1925_2023",
             "Unit root tests for full variable set (Full sample: 1925--2023).")

export_panel(P_ford, "unitroot_allvars_fordist_1925_1973",
             "Unit root tests for full variable set (Fordist: 1925--1973).")

export_panel(P_post, "unitroot_allvars_postfordist_1974_2023",
             "Unit root tests for full variable set (Post-Fordist: 1974--2023).")

# Print deterministic notes for audit
cat(P_full$det_note, "\n")
cat(P_ford$det_note, "\n")
cat(P_post$det_note, "\n")
