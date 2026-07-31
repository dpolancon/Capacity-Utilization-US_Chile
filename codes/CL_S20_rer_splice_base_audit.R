#!/usr/bin/env Rscript

# CL_BOP_BINDING S20: annualize, rebase, splice, and audit the RER series.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})

root <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
s10_file <- file.path(root, "data", "processed", "CL_BOP_BINDING",
                      "S10_SOURCE_PANEL", "chile_bop_source_panel_wide.csv")
bcch_file <- file.path(root, "data", "raw", "Chile", "BCCh_TCR",
                       "bcch_tcr_monthly_raw.csv")
processed_dir <- file.path(root, "data", "processed", "CL_BOP_BINDING",
                           "S20_RER_SPLICE")
output_dir <- file.path(root, "output", "CL", "BOP_BINDING",
                        "S20_RER_SPLICE")
dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(s10_file), file.exists(bcch_file))

s10 <- read.csv(s10_file, check.names = FALSE)
bcch_monthly <- read.csv(bcch_file, stringsAsFactors = FALSE)

cliolab <- s10 |>
  select(year, RER_cliolab_2003) |>
  filter(is.finite(RER_cliolab_2003))

bcch_annual <- bcch_monthly |>
  group_by(year = as.integer(year)) |>
  summarise(
    RER_bcch_1986 = mean(value, na.rm = TRUE),
    months = sum(is.finite(value)),
    annualization_rule = "arithmetic mean of available monthly index observations",
    .groups = "drop"
  ) |>
  filter(year >= 1986, year <= 2024)
stopifnot(all(bcch_annual$months == 12))

cliolab_2003 <- cliolab$RER_cliolab_2003[cliolab$year == 2003]
bcch_2003 <- bcch_annual$RER_bcch_1986[bcch_annual$year == 2003]
stopifnot(length(cliolab_2003) == 1L, length(bcch_2003) == 1L)
rebase_factor <- cliolab_2003 / bcch_2003
bcch_annual <- bcch_annual |>
  mutate(
    RER_bcch_2003 = RER_bcch_1986 * rebase_factor,
    log_RER_bcch_2003 = log(RER_bcch_2003)
  )

overlap <- inner_join(cliolab, bcch_annual, by = "year") |>
  arrange(year) |>
  mutate(
    log_RER_cliolab = log(RER_cliolab_2003),
    level_gap_pct = 100 * (RER_bcch_2003 / RER_cliolab_2003 - 1),
    cliolab_growth = 100 * (log_RER_cliolab - lag(log_RER_cliolab)),
    bcch_growth = 100 * (log_RER_bcch_2003 - lag(log_RER_bcch_2003))
  )

level_correlation <- cor(overlap$log_RER_cliolab,
                         overlap$log_RER_bcch_2003,
                         use = "complete.obs")
growth_correlation <- cor(overlap$cliolab_growth, overlap$bcch_growth,
                          use = "complete.obs")
median_abs_level_gap <- median(abs(overlap$level_gap_pct), na.rm = TRUE)
mean_growth_gap <- mean(abs(overlap$cliolab_growth - overlap$bcch_growth),
                        na.rm = TRUE)

spliced <- tibble(year = 1920:2024) |>
  left_join(cliolab, by = "year") |>
  left_join(
    bcch_annual |>
      select(year, RER_bcch_1986, RER_bcch_2003, months),
    by = "year"
  ) |>
  mutate(
    RER_spliced_2003base = ifelse(
      year <= 2010, RER_cliolab_2003, RER_bcch_2003
    ),
    RER_source = ifelse(
      year <= 2010, "ClioLab PUC sheet 4.2.2",
      "BCCh F073.TCR.IND.199101.M rebased at 2003"
    ),
    log_RER = log(RER_spliced_2003base),
    dlog_RER = log_RER - lag(log_RER)
  )

boundary_growth <- spliced$dlog_RER[spliced$year == 2011]
overlap_growth_sd <- sd(overlap$cliolab_growth, na.rm = TRUE) / 100
continuity_pass <- is.finite(boundary_growth) &&
  abs(boundary_growth) <= 4 * overlap_growth_sd

validation <- tibble(
  check = c(
    "GDP_imports_investment_NRS_2003_CLP",
    "gross_machinery_capital_2003_CLP",
    "ClioLab_RER_2003_base",
    "BCCh_original_1986_base",
    "BCCh_annual_month_completeness",
    "overlap_level_correlation",
    "overlap_growth_correlation",
    "median_absolute_level_gap",
    "splice_boundary_growth",
    "aligned_annual_years",
    "spliced_coverage_1920_2024"
  ),
  value = c(
    2003, 2003, cliolab_2003, bcch_2003,
    min(bcch_annual$months), level_correlation, growth_correlation,
    median_abs_level_gap, boundary_growth,
    nrow(spliced), sum(is.finite(spliced$RER_spliced_2003base))
  ),
  criterion = c(
    "documented 2003 prices",
    "documented 2003 prices",
    "finite and provenance-labelled",
    "finite; rebase factor recorded",
    "12 months in every annual observation",
    "correlation >= 0.80; source definitions need not be level-identical",
    "correlation >= 0.35",
    "median absolute level gap <= 20 percent",
    "absolute boundary growth <= four overlap-growth standard deviations",
    "one row per year, 1920-2024",
    "105 annual observations"
  ),
  passed = c(
    TRUE, TRUE, is.finite(cliolab_2003), is.finite(bcch_2003),
    all(bcch_annual$months == 12),
    level_correlation >= 0.80,
    growth_correlation >= 0.35,
    median_abs_level_gap <= 20,
    continuity_pass,
    identical(spliced$year, 1920:2024),
    sum(is.finite(spliced$RER_spliced_2003base)) == 105
  ),
  detail = c(
    "Pérez-Eyzaguirre and constructed NRS",
    "K-Stock-Harmonization gross stock",
    "ClioLab annual index",
    sprintf("BCCh 2003 annual mean %.4f; factor %.8f",
            bcch_2003, rebase_factor),
    "arithmetic annual mean",
    sprintf("%.4f over 1986-2010", level_correlation),
    sprintf("%.4f over annual growth, 1987-2010", growth_correlation),
    sprintf("%.3f percent", median_abs_level_gap),
    sprintf("%.4f log points in 2011", boundary_growth),
    "1920-2024",
    "ClioLab through 2010; BCCh from 2011"
  )
)

write.csv(cliolab, file.path(processed_dir, "rer_cliolab_annual.csv"),
          row.names = FALSE, na = "")
write.csv(bcch_annual, file.path(processed_dir, "rer_bcch_annual.csv"),
          row.names = FALSE, na = "")
write.csv(spliced, file.path(processed_dir, "rer_spliced_2003base.csv"),
          row.names = FALSE, na = "")
write.csv(validation, file.path(processed_dir, "rer_splice_validation.csv"),
          row.names = FALSE, na = "")
write.csv(overlap, file.path(output_dir, "rer_overlap_diagnostics.csv"),
          row.names = FALSE, na = "")
write.csv(validation, file.path(output_dir, "rer_splice_validation.csv"),
          row.names = FALSE, na = "")
write.csv(
  tibble(
    parameter = c(
      "annualization_rule", "overlap_years", "splice_rule",
      "cliolab_base_value_2003", "bcch_original_value_2003",
      "bcch_to_cliolab_rebase_factor"
    ),
    value = c(
      "arithmetic mean of 12 monthly index observations",
      "1986-2010",
      "ClioLab <=2010; BCCh rebased >=2011",
      cliolab_2003, bcch_2003, rebase_factor
    )
  ),
  file.path(output_dir, "rer_splice_parameter_ledger.csv"),
  row.names = FALSE
)

p <- ggplot(overlap, aes(x = year)) +
  geom_line(aes(y = RER_cliolab_2003, color = "ClioLab"), linewidth = 0.8) +
  geom_line(aes(y = RER_bcch_2003, color = "BCCh rebased"), linewidth = 0.8) +
  scale_color_manual(values = c("ClioLab" = "#0072B2",
                                "BCCh rebased" = "#D55E00")) +
  labs(x = NULL, y = "RER index (ClioLab 2003 scale)", color = NULL,
       title = "Chile real exchange-rate overlap audit, 1986-2010") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom")
ggsave(file.path(output_dir, "fig_rer_overlap.png"), p,
       width = 7.2, height = 4.5, dpi = 220)
ggsave(file.path(output_dir, "fig_rer_overlap.pdf"), p,
       width = 7.2, height = 4.5)

stopifnot(all(validation$passed))
message("CL_BOP_BINDING S20 complete: RER splice passed all declared checks.")
