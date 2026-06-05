library(readr); library(dplyr)
panel <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/stage_a/Chile/csv/stage2_panel_with_mu_v2.csv", show_col_types=FALSE)

panel %>% filter(year >= 1940, year <= 1978) %>%
  summarise(
    n          = n(),
    mu_ok      = sum(!is.na(mu_CL)),
    omega_ok   = sum(!is.na(omega)),
    y_ok       = sum(!is.na(y)),
    k_ok       = sum(!is.na(k_CL))
  ) %>% print()
