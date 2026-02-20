# ============================================================
# 10_config.R — ChaoGrid Confinement / Lattice config
# Repo: capacity_utilization/
# ============================================================

CONFIG <- list(
  
  # --- Data
  data_file  = "data/processed/ddbb_cu_US_kgr.xlsx",
  data_sheet = "us_data",
  
  # --- Variables (column names inside the sheet)
  year_col = "year",
  y_col    = "Yrgdp",
  k_col    = "KGCRcorp",
  e_col    = "e",
  
  # --- Windows (keep consistent with the chapter narrative)
  WINDOWS_LOCKED = list(
    full         = c(-Inf, Inf),
    fordism      = c(-Inf, 1973),
    post_fordism = c(1974,  Inf)
  ),
  
  # --- Johansen deterministics
  ECDET_LOCKED = c("none", "const"),
  
  # --- Lattice ranges
  P_MIN = 1L,
  P_MAX_EXPLORATORY = 7L,
  
  # --- Model specs
  # Interpretation used here:
  # Q2 = polynomial degree 2 block
  # Q3 = polynomial degree 3 block
  SPECS = list(
    Q2 = list(degree = 2L),
    Q3 = list(degree = 3L)
  ),
  
  # --- Toggle: orthogonalized polynomial basis vs raw standardized powers
  ORTHO_TOGGLE = c(FALSE, TRUE),
  
  # --- Outputs (under output/ChaoGrid/)
  OUT_ROOT = "output/ChaoGrid",
  
  # --- Engine behavior
  seed = 123456,
  johansen_spec = "transitory",
  
  DELTA_PIC_TOL = 2  # ejemplo: tolerancia ΔPIC para “ambiguity set”
)
