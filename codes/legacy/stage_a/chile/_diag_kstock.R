library(readr)
library(dplyr)
df <- read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/data/final/chile_tvecm_panel.csv",
               show_col_types = FALSE) %>% arrange(year)

df <- df %>%
  mutate(
    k_NRC     = log(exp(k_NR) - exp(k_ME)),
    phi_check = exp(k_ME) / exp(k_NR)
  )

cat(sprintf("phi vs phi_check max diff: %.8f\n",
    max(abs(df$phi - df$phi_check), na.rm = TRUE)))

cat(sprintf("cor(k_NRC, k_ME) = %.4f  [should be << 0.99]\n",
    cor(df$k_NRC, df$k_ME, use = "complete")))

cat(sprintf("k_NRC range: [%.4f, %.4f]\n",
    min(df$k_NRC, na.rm = TRUE), max(df$k_NRC, na.rm = TRUE)))

cat(sprintf("\nphi range: [%.4f, %.4f]\n", min(df$phi, na.rm = TRUE), max(df$phi, na.rm = TRUE)))
cat(sprintf("phi_check range: [%.4f, %.4f]\n", min(df$phi_check, na.rm = TRUE), max(df$phi_check, na.rm = TRUE)))

cat(sprintf("\nphi_check by period:\n"))
cat(sprintf("  ISI (1940-72):    %.4f\n", mean(df$phi_check[df$year %in% 1940:1972], na.rm = TRUE)))
cat(sprintf("  Neo (1983-2024):  %.4f\n", mean(df$phi_check[df$year %in% 1983:2024], na.rm = TRUE)))

# Check if any years have K_ME > K_NR (would make k_NRC = log(negative))
cat(sprintf("\nYears where K_ME > K_NR (phi > 1): %d\n",
    sum(df$phi_check > 1, na.rm = TRUE)))
cat(sprintf("Any NaN in k_NRC: %s\n", any(is.nan(df$k_NRC))))

# If k_NRC has NaN, show which years
if (any(is.nan(df$k_NRC))) {
  cat(sprintf("NaN years: %s\n", paste(df$year[is.nan(df$k_NRC)], collapse = ", ")))
}

cat(sprintf("\ncor(k_NR, k_ME) = %.4f  [original — high collinearity]\n",
    cor(df$k_NR, df$k_ME, use = "complete")))
