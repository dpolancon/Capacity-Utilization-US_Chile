library(readr)
library(readxl)
library(dplyr)
library(tidyr)
library(janitor)

# Paths
path_k <- "C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/Chile/harmonized_series_2003CLP_1900_2024.csv"
path_d <- "C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/Chile/distr_19202024.xlsx"
path_pe <- "C:/ReposGitHub/Capacity-Utilization-US_Chile/data/raw/Chile/PerezEyzaguirre_DemandaAgregada.xlsx"

# Load
kraw <- read_csv(path_k, show_col_types = FALSE) %>% clean_names()
draw <- read_excel(path_d) %>% clean_names()
pe <- read_excel(path_pe) %>% clean_names()

# Gross capital stocks by asset
k_wide <- kraw %>%
  select(year, asset, kg) %>%
  pivot_wider(names_from = asset, values_from = kg, names_prefix = "kg_")


pe_fixed <- pe %>%
  transmute(
    year = x1,
    y_real = pib_real_milllones_de_pesos_de_2003,
    i_me = fbkf_en_maquinaria,
    i_cons = fbkf_en_construccion,
    i_total = inversion_interna_bruta,
    m_cif = importaciones_cif_millones_de_pesos_de_2003
  )

panel_audit <- k_wide %>%
  transmute(
    year = year,
    K_ME_gross    = kg_ME,
    K_NRC_gross   = kg_NRC,
    K_NR_gross    = kg_NR,
    K_Total_gross = kg_Total,
    
    K_prod_sum_ME_NRC = K_ME_gross + K_NRC_gross,
    s_ME_in_prod  = K_ME_gross / K_prod_sum_ME_NRC,
    s_ME_in_NR    = K_ME_gross / K_NR_gross,
    s_ME_in_total = K_ME_gross / K_Total_gross,
    
    log_K_ME       = log(K_ME_gross),
    log_K_NRC      = log(K_NRC_gross),
    log_K_NR       = log(K_NR_gross),
    log_K_Total    = log(K_Total_gross),
    log_K_prod_sum = log(K_prod_sum_ME_NRC)
  ) %>%
  left_join(
    draw %>%
      transmute(
        year = periodo,
        wsh = wage_share,
        psh = profit_share,
        e   = exploitation_rate
      ),
    by = "year"
  ) %>%
  left_join(
    pe_fixed,
    by = "year"
  ) %>%
  mutate(
    log_y = log(y_real),
    omega_sME_prod = wsh * s_ME_in_prod,
    omega_sME_NR   = wsh * s_ME_in_NR
  )



# working sample builder
build_stage2_baseline_data <- function(panel_audit) {
  panel_audit %>%
    transmute(
      year = year,
      y = log_y,
      k_nr = log_K_NR,
      k_me = log_K_ME,
      s_me = s_ME_in_NR,
      wsh = wsh
    ) %>%
    mutate(
      s_me_c = s_me - mean(s_me, na.rm = TRUE),
      wsh_c  = wsh - mean(wsh, na.rm = TRUE),
      k_nr_sme = k_nr * s_me,
      k_nr_wsme = k_nr * wsh * s_me,
      k_nr_sme_c = k_nr * s_me_c,
      k_nr_wsme_c = k_nr * wsh_c * s_me_c,
      wsh_kme = wsh * k_me
    )
}

split_sample <- function(df, sample = c("full", "pre1974", "post1974")) {
  sample <- match.arg(sample)
  if (sample == "full") return(df)
  if (sample == "pre1974") return(filter(df, year <= 1973))
  if (sample == "post1974") return(filter(df, year >= 1974))
}


fit_baselines <- function(df) {
  list(
    A_main = lm(y ~ k_nr + k_nr_sme + k_nr_wsme, data = df),
    A_centered = lm(y ~ k_nr + k_nr_sme_c + k_nr_wsme_c, data = df),
    B_additive = lm(y ~ k_nr + s_me + I(wsh * s_me), data = df),
    C_legacy = lm(y ~ k_nr + k_me + wsh_kme, data = df)
  )
}



diag_one <- function(fit, name, sample_name) {
  res <- resid(fit)
  adf_res <- tryCatch(
    urca::ur.df(res, type = "drift", lags = 1, selectlags = "Fixed"),
    error = function(e) NULL
  )
  
  tibble(
    sample = sample_name,
    model = name,
    n = nobs(fit),
    r2 = summary(fit)$r.squared,
    adj_r2 = summary(fit)$adj.r.squared,
    aic = AIC(fit),
    bic = BIC(fit),
    max_vif = tryCatch(max(car::vif(fit)), error = function(e) NA_real_),
    adf_tau = if (!is.null(adf_res)) unname(adf_res@teststat[1]) else NA_real_
  )
}

coef_table <- function(fit, name, sample_name) {
  broom::tidy(fit) %>%
    mutate(sample = sample_name, model = name, .before = 1)
}





df0 <- build_stage2_baseline_data(panel_audit)
df0 <- df0 %>%
  filter(!is.na(y), !is.na(k_nr), !is.na(s_me), !is.na(wsh))

sample_names <- c("full", "pre1974", "post1974")

all_diags <- list()
all_coefs <- list()

for (s in sample_names) {
  dfs <- split_sample(df0, s)
  fits <- fit_baselines(dfs)
  
  for (nm in names(fits)) {
    all_diags[[paste(s, nm, sep = "__")]] <- diag_one(fits[[nm]], nm, s)
    all_coefs[[paste(s, nm, sep = "__")]] <- coef_table(fits[[nm]], nm, s)
  }
}

diag_tbl <- bind_rows(all_diags)
coef_tbl <- bind_rows(all_coefs)



theta_from_A <- function(df, fit) {
  b <- coef(fit)
  df %>%
    mutate(
      theta_hat = b["k_nr"] +
        b["k_nr_sme"] * s_me +
        b["k_nr_wsme"] * (wsh * s_me)
    ) %>%
    select(year, theta_hat)
}


theta_full <- theta_from_A(split_sample(df0, "full"), fit_baselines(split_sample(df0, "full"))$A_main)
theta_pre  <- theta_from_A(split_sample(df0, "pre1974"), fit_baselines(split_sample(df0, "pre1974"))$A_main)
theta_post <- theta_from_A(split_sample(df0, "post1974"), fit_baselines(split_sample(df0, "post1974"))$A_main)


coef(fit_baselines(split_sample(df0, "full"))$A_main)
coef(fit_baselines(split_sample(df0, "pre1974"))$A_main)
coef(fit_baselines(split_sample(df0, "post1974"))$A_main)

summary(fit_baselines(split_sample(df0, "full"))$A_main)
summary(fit_baselines(split_sample(df0, "pre1974"))$A_main)
summary(fit_baselines(split_sample(df0, "post1974"))$A_main)

##############################


library(cointReg)
library(dplyr)
library(broom)

# -------------------------
# Common-support sample
# -------------------------

df0_cs <- df0 %>%
  filter(
    is.finite(y),
    is.finite(k_nr),
    is.finite(k_me),
    is.finite(s_me),
    is.finite(wsh)
  ) %>%
  mutate(
    # preferred mechanization-grounded regressors
    k_nr_sme  = k_nr * s_me,
    k_nr_wsme = k_nr * wsh * s_me,
    
    # additive comparator
    wsme = wsh * s_me,
    
    # legacy comparator
    wsh_kme = wsh * k_me
  )

split_sample <- function(df, sample = c("full", "pre1974", "post1974")) {
  sample <- match.arg(sample)
  if (sample == "full") return(df)
  if (sample == "pre1974") return(filter(df, year <= 1973))
  if (sample == "post1974") return(filter(df, year >= 1974))
}


library(cointReg)

run_dols <- function(df, xvars) {
  cointRegD(
    y = df$y,
    x = as.data.frame(df[, xvars]),
    deter = matrix(1, nrow = nrow(df), ncol = 1),  # intercept
    kmax = "k4",
    info.crit = "BIC"
  )
}



samples <- c("full", "pre1974", "post1974")

results <- list()

for (s in samples) {
  dfs <- split_sample(df0_cs, s)
  
  results[[paste0(s, "_A")]] <- run_dols(dfs, c("k_nr", "k_nr_sme", "k_nr_wsme"))
  results[[paste0(s, "_B")]] <- run_dols(dfs, c("k_nr", "s_me", "wsme"))
  results[[paste0(s, "_C")]] <- run_dols(dfs, c("k_nr", "k_me", "wsh_kme"))
}

print(results)