library(readr)
library(dplyr)

# Note: panel is in stage_b, not stage_a
panel <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/stage_a/Chile/csv/stage2_panel_with_mu_v2.csv",
                  show_col_types = FALSE)

cat("Columns:", paste(names(panel), collapse = ", "), "\n\n")

panel %>%
  filter(year %in% 1940:1972) %>%
  select(year, g_Y, g_Yp, g_mu, mu_CL, theta_CL) %>%
  print(n = 33)
