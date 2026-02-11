# Diagnostics – Visuals only #

#### 0) Packages (viz + data wrangling only)  ####
pkgs <- c(
  "here","readxl","dplyr","tidyr","ggplot2","zoo",
  "patchwork","stats","knitr","KableExtra",
  "urca","vars","tseries","lmtest","sandwich","strucchange"
)
invisible(lapply(pkgs, require, character.only = TRUE))

#### 1) Preamble: paths, helpers, data  ####
source(paste0(here("codes"), "/0_functions.R"))  # uses your helpers: ensure_dirs, set_seed_deterministic, save_*()
data_path   <- here("data/processed/ddbb_cu_US_kgr.xlsx")
output_path <- here("output")

set_seed_deterministic()  # deterministic plots
ensure_dirs(file.path(output_path))

ddbb_us <- readxl::read_excel(data_path, sheet = "us_data")

#### 2) Build variables (exact scope you requested) ####
df <- ddbb_us |>
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
  "e_logk","d_e_logk", "e2_logk", "d_e2_logk")   # optionally add "yk_input" if you want visuals for the provided ratio too

#### 3) robust helpers (filter finite, align t/x, safely skip empties) ####
make_ts_df <- function(x, nm, tvec) {
  if (is.null(x)) return(NULL)
  idx <- which(is.finite(x) & is.finite(tvec))
  if (length(idx) == 0) return(NULL)
  data.frame(t = tvec[idx], val = as.numeric(x[idx]), var = nm)
}

# --- Candidate systems (levels) ---
# A) baseline sanity check
vars_A <- c("log_y","log_k")

# B) theory-consistent capacity manifold
vars_B <- c("log_y","log_k","e_logk","e2_logk")  # start with e_logk only if you want minimal

# Build matrix helper (drops all rows with any NA/Inf)
build_X <- function(df, vars, tvar="year") {
  tmp <- df |>
    dplyr::select(dplyr::all_of(c(tvar, vars))) |>
    dplyr::filter(dplyr::if_all(dplyr::all_of(vars), is.finite)) |>
    tidyr::drop_na()
  years <- tmp[[tvar]]
  X <- as.matrix(tmp[, vars])
  rownames(X) <- as.character(years)
  list(X=X, years=years)
}

XA <- build_X(df, vars_A)
XB <- build_X(df, vars_B)

# VAR lag selection guidance (levels VAR order p)
vars::VARselect(XA$X, lag.max=6, type="const")
vars::VARselect(XB$X, lag.max=6, type="const")



# Johansen rank tests
jo_A_p2 <- urca::ca.jo(XA$X, type="trace", ecdet="const", K=2, spec="transitory")
summary(jo_A_p2)

jo_B_p2 <- urca::ca.jo(XB$X, type="trace", ecdet="const", K=2, spec="transitory")
summary(jo_B_p2)


#Grid rank for rank stability  
fit_grid <- function(X, p_set=2:4, ecdet_set=c("const","trend"), type="trace") {
  out <- list()
  for (p in p_set) {
    for (ed in ecdet_set) {
      key <- paste0("p",p,"_",ed)
      out[[key]] <- urca::ca.jo(X, type=type, ecdet=ed, K=p, spec="transitory")
    }
  }
  out
}

grid_A <- fit_grid(XA$X)
grid_B <- fit_grid(XB$X)

# Print summaries compactly
for(nm in names(grid_B)) {
  cat("\n---", nm, "---\n")
  print(summary(grid_B[[nm]]))
}



##################################################


# Define windows
df_early <- df |> dplyr::filter(year >= 1925, year <= 1973)
df_late  <- df |> dplyr::filter(year >= 1974, year <= 2023)

# Build X matrices (theory-consistent system)
XB_early <- build_X(df_early, vars_B)
XB_late  <- build_X(df_late,  vars_B)

#Sample Sizes Check
nrow(XB_early$X)
nrow(XB_late$X)

#Johansen 
jo_early <- urca::ca.jo(
  XB_early$X,
  type = "trace",
  ecdet = "const",
  K = 2,
  spec = "transitory"
)

jo_late <- urca::ca.jo(
  XB_late$X,
  type = "trace",
  ecdet = "const",
  K = 2,
  spec = "transitory"
)

summary(jo_early)
summary(jo_late)


# --- Inputs assumed already in your workspace:
# jo_late  : ca.jo object for 1974–2023 with ecdet="const", K=2, spec="transitory"
# XB_late$X: the levels matrix used to estimate jo_late (rows = years, cols = vars_B)
# vars_B   : c("log_y","log_k","e_logk","e2_logk")

r_late <- 2  # from your rank test

# Extract a basis for the cointegration space
beta_hat <- urca::cajorls(jo_late, r = r_late)$beta  # m x r
beta_hat





