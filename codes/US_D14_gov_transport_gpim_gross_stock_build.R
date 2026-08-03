#!/usr/bin/env Rscript

# US_D14_gov_transport_gpim_gross_stock_build.R
#
# Builds the government-transportation GPIM gross capital stock for the S41
# diagnostic branch, and assembles the extended estimation panel.
#
# Pipeline:
#   1. Gate on D13 readiness checks (all PASS required).
#   2. Implicit deflator per BEA line: p_GT = FAAt701 current-cost net stock
#      / FAAt702-rebased real net stock (2017=100). Backcast 1901-1924 by
#      log-linear backward extrapolation of the 1925-1950 mean log growth
#      (sensitivity: flat hold at the 1925 price).
#   3. Real gross investment I_real = I_current / (p_GT/100).
#   4. GPIM cohort convolution (kernel copied from D06 lines 212-273):
#      untruncated Weibull survival, L=60, alpha=1.3, ages 0:200.
#   5. Initialization (V02_GPIM_Constitution.md Sec. 12; warm-up HIGH at 1929
#      per D13; cold start is not authorized as the preferred baseline):
#      PRIMARY = benchmark-seeded: a flat pre-1901 real investment flow
#      (1841-1900) solved in closed form per line so that the 1929
#      current-cost gross stock equals BEA FAAt701 net x the late-sample
#      (1995-2024) stabilized gross/net ratio, where cold-start bias is
#      negligible (aggregate cold-vs-synthetic divergence < 1% from 1942).
#      SENSITIVITIES = (a) cold start at 1901; (b) synthetic pre-1901
#      history backcast at the 1901-1911 mean real-investment log growth.
#      Divergence paths and the < 1% convergence year are disclosed.
#   6. Current-cost valuation per line: K_current = K_real * p_GT/100, summed
#      across lines (mirrors D06's k_current step) so the stock adds to the
#      current-cost K_ME + K_NRC of the estimation panel on a like basis.
#   7. Extended panel: k_cap_GT = log(K_cap + K_GT_current) and the BEA-net
#      robustness variant k_cap_GTnet = log(K_cap + GOV_TRANS_stock).
#
# Governance: DIAGNOSTIC branch only. Does not modify D06/D07/D10 frozen
# outputs, the D06 exclusion ledger, or output/gpim_baseline_components_long.csv.
# Per the exclusion ledger, government transportation remains excluded from
# baseline K_capacity.

options(stringsAsFactors = FALSE, scipen = 999)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
menu_csv  <- file.path(repo_root, "data", "external", "us_bea_provider",
                       "us_bea_variable_menu_long.csv")
audit_dir <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "audit")
data_dir  <- file.path(repo_root, "output", "US", "S41_KGT_INCLUSION", "data")
dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

panel_csv <- file.path(repo_root, "output", "gpim_baseline_components_long.csv")

diagnostic_stamp <- "DIAGNOSTIC_ONLY;NOT_D06_BASELINE;S41_BRANCH"

## Locked survival parameters (promoted by D13 from D01 metadata row)
L_gov      <- 60
alpha_gov  <- 1.3
lambda_gov <- L_gov / gamma(1 + 1 / alpha_gov)
# D06 uses ages 0:200 for L=14/30; the L=60, alpha=1.3 Weibull has a fatter
# tail (S(200) ~ 0.013), so the tail-tolerance convention requires a longer
# support. Ages 0:500 satisfies S(max) < 1e-6; no observed or synthetic
# vintage exceeds age ~184, so no truncation binds in practice.
survival_max_age <- 500L
tail_tolerance <- 1e-6

survival_weibull <- function(age, alpha, lambda) {
  exp(-((age / lambda) ^ alpha))
}

cat("========================================================================\n")
cat("D14: Government transportation GPIM gross stock build (S41 branch)\n")
cat("========================================================================\n")

## ==========================================================
## STEP 0: Gate on D13
## ==========================================================

d13_checks_csv <- file.path(audit_dir, "D13_gov_transport_gpim_readiness_checks.csv")
if (!file.exists(d13_checks_csv)) stop("D13 checks not found; run D13 first.")
d13_checks <- read.csv(d13_checks_csv, stringsAsFactors = FALSE)
if (any(d13_checks$status != "PASS")) {
  stop("D13 gate not clean: ", sum(d13_checks$status != "PASS"), " FAIL rows.")
}
cat(sprintf("D13 gate: %d/%d checks PASS — authorized.\n",
            nrow(d13_checks), nrow(d13_checks)))

## Tail convention sanity
stopifnot(survival_weibull(survival_max_age, alpha_gov, lambda_gov) < tail_tolerance)
stopifnot(survival_weibull(L_gov + 1L, alpha_gov, lambda_gov) > 0)

## ==========================================================
## STEP 1: Load BEA series
## ==========================================================

menu <- read.csv(menu_csv, stringsAsFactors = FALSE)
gt_lines <- c("HIGHWAYS_STREETS", "TRANSPORTATION_STRUCTURES")

get_series <- function(line, type_suffix) {
  vid <- paste0("GOV_TRANS__", line, "__", type_suffix)
  sub <- menu[menu$variable_id == vid, c("year", "value")]
  sub <- sub[order(sub$year), ]
  names(sub)[2] <- "value"
  sub
}

validation <- list()
add_check <- function(check_id, passed, detail) {
  validation[[length(validation) + 1]] <<- data.frame(
    check_id = check_id, status = ifelse(passed, "PASS", "FAIL"),
    detail = detail, stamp = diagnostic_stamp)
}

## ==========================================================
## STEP 2-3: Implicit deflator and real investment, per line
## ==========================================================

deflator_rows <- list()
invest_rows <- list()

for (line in gt_lines) {
  inv <- get_series(line, "gross_investment_current_cost")   # 1901-2024
  ns  <- get_series(line, "net_stock_current_cost")          # 1925-2024
  qi  <- get_series(line, "net_stock_quantity_index")        # 1925-2024

  common <- merge(ns, qi, by = "year", suffixes = c("_ns", "_qi"))
  ns2017 <- common$value_ns[common$year == 2017]
  qi2017 <- common$value_qi[common$year == 2017]
  common$ns_real_2017 <- common$value_qi / qi2017 * ns2017
  common$p_gt <- common$value_ns / common$ns_real_2017 * 100

  add_check(paste0("P_GT_2017_EQUALS_100__", line),
            abs(common$p_gt[common$year == 2017] - 100) < 1e-8,
            sprintf("p_GT(2017) = %.10f", common$p_gt[common$year == 2017]))
  add_check(paste0("P_GT_POSITIVE__", line), all(common$p_gt > 0),
            sprintf("min p_GT = %.4f", min(common$p_gt)))

  ## Backcast 1901-1924: log-linear backward extrapolation
  early <- common[common$year >= 1925 & common$year <= 1950, ]
  mean_lg <- mean(diff(log(early$p_gt)))
  back_years <- seq(min(inv$year), 1924)
  p_back <- common$p_gt[common$year == 1925] *
    exp(mean_lg * (back_years - 1925))          # negative exponent backward
  p_back_flat <- rep(common$p_gt[common$year == 1925], length(back_years))

  defl <- rbind(
    data.frame(year = back_years, p_gt = p_back, p_gt_flat_sens = p_back_flat,
               source = "backcast_log_linear_1925_1950_mean_growth"),
    data.frame(year = common$year, p_gt = common$p_gt,
               p_gt_flat_sens = common$p_gt,
               source = "implicit_FAAt701_over_FAAt702")
  )
  defl$line <- line
  deflator_rows[[line]] <- defl

  im <- merge(inv, defl[, c("year", "p_gt", "p_gt_flat_sens")], by = "year")
  im$I_real <- im$value / (im$p_gt / 100)
  im$I_real_flat_sens <- im$value / (im$p_gt_flat_sens / 100)
  im$line <- line
  names(im)[names(im) == "value"] <- "I_current"
  invest_rows[[line]] <- im

  add_check(paste0("I_REAL_FINITE_POSITIVE__", line),
            all(is.finite(im$I_real) & im$I_real >= 0),
            sprintf("%d investment years %d-%d", nrow(im),
                    min(im$year), max(im$year)))
}

deflator_panel <- do.call(rbind, deflator_rows)
invest_panel <- do.call(rbind, invest_rows)
rownames(deflator_panel) <- rownames(invest_panel) <- NULL

## ==========================================================
## STEP 4-5: GPIM cohort convolution + initialization sensitivity
## ==========================================================

# Kernel copied from US_D06_gpim_refreeze_with_guarded_pkn.R:242-252
# (cohort convolution over vintages with untruncated Weibull survival).
gpim_stock <- function(years, i_real) {
  ord <- order(years)
  years <- years[ord]; i_real <- i_real[ord]
  sapply(years, function(cy) {
    ages <- cy - years
    keep <- ages >= 0 & ages <= survival_max_age
    sum(i_real[keep] * survival_weibull(ages[keep], alpha_gov, lambda_gov))
  })
}

calibration_year <- 1929L
ratio_window <- 1995:2024
pre_years <- seq(1901L - L_gov, 1900L)   # 1841-1900 flat benchmark flow

stock_rows <- list()
seed_rows <- list()
for (line in gt_lines) {
  im <- invest_panel[invest_panel$line == line, ]
  im <- im[order(im$year), ]
  ns <- get_series(line, "net_stock_current_cost")

  ## Sensitivity (a): cold start at first observed investment year (1901)
  k_cold <- gpim_stock(im$year, im$I_real)

  ## Sensitivity (b): synthetic pre-1901 history, 60 years backcast at the
  ## 1901-1911 mean real-investment log growth.
  g_early <- mean(diff(log(im$I_real[im$year <= 1911])))
  syn_inv <- im$I_real[1] * exp(g_early * (pre_years - min(im$year)))
  k_syn_full <- gpim_stock(c(pre_years, im$year), c(syn_inv, im$I_real))
  k_syn <- k_syn_full[match(im$year, c(pre_years, im$year))]

  ## PRIMARY: benchmark-seeded. Late-sample stabilized gross/net ratio
  ## (cold-start bias negligible there) anchors the 1929 target; the flat
  ## pre-1901 flow solves it in closed form (stock is linear in the flow).
  cold_current <- k_cold * im$p_gt / 100
  ns_late <- ns$value[match(ratio_window, ns$year)]
  cur_late <- cold_current[match(ratio_window, im$year)]
  R_line <- mean(cur_late / ns_late)

  i_cal <- match(calibration_year, im$year)
  target_real_1929 <- (ns$value[ns$year == calibration_year] /
                         (im$p_gt[i_cal] / 100)) * R_line
  ages_at_cal <- calibration_year - pre_years
  W_cal <- sum(survival_weibull(ages_at_cal, alpha_gov, lambda_gov))
  I0 <- max(0, (target_real_1929 - k_cold[i_cal]) / W_cal)

  seed_contrib <- sapply(im$year, function(cy) {
    ages <- cy - pre_years
    keep <- ages <= survival_max_age
    I0 * sum(survival_weibull(ages[keep], alpha_gov, lambda_gov))
  })
  k_bench <- k_cold + seed_contrib

  seed_rows[[line]] <- data.frame(
    line = line, calibration_year = calibration_year,
    gross_net_ratio_late_sample = R_line,
    target_real_at_calibration = target_real_1929,
    cold_real_at_calibration = k_cold[i_cal],
    flat_pre1901_real_flow_I0 = I0,
    calibration_residual = k_bench[i_cal] - target_real_1929,
    stamp = diagnostic_stamp
  )

  stock_rows[[line]] <- data.frame(
    year = im$year, line = line,
    I_current = im$I_current, p_gt = im$p_gt, I_real = im$I_real,
    K_real_bench = k_bench, K_real_cold = k_cold, K_real_synthetic = k_syn
  )
}
stock_panel <- do.call(rbind, stock_rows)
seed_ledger <- do.call(rbind, seed_rows)
rownames(stock_panel) <- rownames(seed_ledger) <- NULL

add_check("BENCHMARK_CALIBRATION_EXACT",
          all(abs(seed_ledger$calibration_residual) < 1e-6 *
                seed_ledger$target_real_at_calibration),
          sprintf("residuals: %s",
                  paste(signif(seed_ledger$calibration_residual, 3),
                        collapse = "; ")))
add_check("BENCHMARK_SEED_FLOW_POSITIVE",
          all(seed_ledger$flat_pre1901_real_flow_I0 > 0),
          sprintf("I0: %s",
                  paste(signif(seed_ledger$flat_pre1901_real_flow_I0, 4),
                        collapse = "; ")))

## Aggregate across lines; current-cost valuation per line then sum
for (v in c("bench", "cold", "synthetic")) {
  stock_panel[[paste0("K_current_", v)]] <-
    stock_panel[[paste0("K_real_", v)]] * stock_panel$p_gt / 100
}
agg <- aggregate(cbind(K_real_bench, K_real_cold, K_real_synthetic,
                       K_current_bench, K_current_cold, K_current_synthetic)
                 ~ year, data = stock_panel, FUN = sum)
gt_stock <- agg
names(gt_stock)[names(gt_stock) == "K_real_bench"] <- "K_GT_real"
names(gt_stock)[names(gt_stock) == "K_current_bench"] <- "K_GT_current"
gt_stock$div_cold_pct <-
  (gt_stock$K_current_cold - gt_stock$K_GT_current) / gt_stock$K_GT_current * 100
gt_stock$div_syn_pct <-
  (gt_stock$K_current_synthetic - gt_stock$K_GT_current) / gt_stock$K_GT_current * 100

conv_years <- gt_stock$year[abs(gt_stock$div_cold_pct) < 1]
convergence_year <- if (length(conv_years) > 0) min(conv_years) else NA_integer_

add_check("INIT_SENSITIVITY_CONVERGENCE_FOUND", !is.na(convergence_year),
          sprintf("cold-vs-benchmark |divergence| < 1%% from %s (1929: %.2f%%; 1947: %.2f%%; 1973: %.2f%%)",
                  convergence_year,
                  gt_stock$div_cold_pct[gt_stock$year == 1929],
                  gt_stock$div_cold_pct[gt_stock$year == 1947],
                  gt_stock$div_cold_pct[gt_stock$year == 1973]))
# A benchmarked real gross stock can genuinely decline when retirements of
# seeded vintages exceed new investment (observed 1902-1913 and the WWII
# collapse 1943-1945, max -0.86%/yr). Assert positivity and no implausibly
# sharp drop; declining years are disclosed.
ann_growth <- diff(gt_stock$K_GT_real) / head(gt_stock$K_GT_real, -1)
add_check("K_GT_REAL_POSITIVE_NO_SHARP_DROP",
          all(gt_stock$K_GT_real > 0) && all(ann_growth > -0.03),
          sprintf("min = %.0f; %d declining years; max annual decline %.2f%%",
                  min(gt_stock$K_GT_real), sum(ann_growth < 0),
                  min(ann_growth) * 100))

## Context ledger: model gross (current, benchmark) vs BEA net stock ratio.
## Gross should exceed net once initialization is benchmarked; disclosed as
## a path, asserted only as positivity + finiteness (methodological
## differences — Weibull retirement vs BEA depreciation — preclude a strict
## year-by-year bound).
ns_total <- Reduce(function(a, b) merge(a, b, by = "year"),
  lapply(gt_lines, function(l) {
    s <- get_series(l, "net_stock_current_cost"); names(s)[2] <- l; s }))
ns_total$NS_BEA_net <- rowSums(ns_total[, gt_lines])
gross_net <- merge(gt_stock[, c("year", "K_GT_current")],
                   ns_total[, c("year", "NS_BEA_net")], by = "year")
gross_net$gross_to_net_ratio <- gross_net$K_GT_current / gross_net$NS_BEA_net

add_check("GROSS_NET_RATIO_FINITE_POSITIVE",
          all(is.finite(gross_net$gross_to_net_ratio) &
                gross_net$gross_to_net_ratio > 0),
          sprintf("ratio range %.3f-%.3f (1929+: min %.3f)",
                  min(gross_net$gross_to_net_ratio),
                  max(gross_net$gross_to_net_ratio),
                  min(gross_net$gross_to_net_ratio[gross_net$year >= 1929])))

## ==========================================================
## STEP 6-7: Extended estimation panel
## ==========================================================

panel <- read.csv(panel_csv, stringsAsFactors = FALSE)
ext <- merge(panel, gt_stock[, c("year", "K_GT_real", "K_GT_current",
                                 "div_cold_pct", "div_syn_pct")],
             by = "year", all.x = TRUE)
ext$K_cap_GT <- ext$K_cap + ext$K_GT_current
ext$k_cap_GT <- log(ext$K_cap_GT)
ext$K_cap_GTnet <- ext$K_cap + ext$GOV_TRANS_stock
ext$k_cap_GTnet <- log(ext$K_cap_GTnet)
ext$GT_share <- ext$K_GT_current / ext$K_cap_GT
ext$stamp <- diagnostic_stamp

ok <- !is.na(ext$K_cap_GT)
add_check("K_CAP_GT_EXCEEDS_K_CAP_ALL_YEARS",
          all(ext$K_cap_GT[ok] > ext$K_cap[ok]),
          sprintf("%d panel years with K_GT_current", sum(ok)))

# Peak timing is an empirical outcome, not a validity invariant (the BEA-net
# GOV_TRANS/K_cap ratio in the baseline panel peaks in 1943 and rises again
# post-2010). Assert bounds only; the path is disclosed in the panel.
peak_year <- ext$year[which.max(ext$GT_share)]
add_check("GT_SHARE_WITHIN_PLAUSIBLE_BOUNDS",
          all(ext$GT_share[ok] > 0.02 & ext$GT_share[ok] < 0.50),
          sprintf("range %.3f-%.3f; peak %.3f in %d",
                  min(ext$GT_share, na.rm = TRUE),
                  max(ext$GT_share, na.rm = TRUE),
                  max(ext$GT_share, na.rm = TRUE), peak_year))

## ==========================================================
## STEP 8: Write outputs
## ==========================================================

validation_df <- do.call(rbind, validation)

write.csv(deflator_panel,
  file.path(data_dir, "D14_gov_transport_implicit_deflator_panel.csv"),
  row.names = FALSE)
write.csv(stock_panel,
  file.path(data_dir, "D14_gov_transport_gpim_line_stock_panel.csv"),
  row.names = FALSE)
write.csv(gt_stock,
  file.path(data_dir, "D14_gov_transport_gpim_aggregate_stock.csv"),
  row.names = FALSE)
write.csv(gross_net,
  file.path(data_dir, "D14_gross_vs_bea_net_context_ledger.csv"),
  row.names = FALSE)
write.csv(ext,
  file.path(data_dir, "s41_extended_capital_panel.csv"),
  row.names = FALSE)
write.csv(validation_df,
  file.path(data_dir, "D14_validation_checks.csv"),
  row.names = FALSE)

init_disclosure <- data.frame(
  primary_initialization = "benchmark_seeded_flat_pre1901_flow_calibrated_1929_BEA_net_x_late_sample_gross_net_ratio",
  sensitivity_a = "cold_start_1901_observed_history_only",
  sensitivity_b = "synthetic_pre_1901_history_60y_backcast_mean_growth_1901_1911",
  cold_convergence_year_1pct = convergence_year,
  cold_divergence_1929_pct = round(gt_stock$div_cold_pct[gt_stock$year == 1929], 3),
  cold_divergence_1947_pct = round(gt_stock$div_cold_pct[gt_stock$year == 1947], 3),
  cold_divergence_1973_pct = round(gt_stock$div_cold_pct[gt_stock$year == 1973], 3),
  warmup_risk_1929 = "HIGH (0.47) per D13 ledger",
  constitution_ref = "V02_GPIM_Constitution.md Sec. 12 (cold start not preferred baseline)",
  stamp = diagnostic_stamp
)
write.csv(init_disclosure,
  file.path(data_dir, "D14_initialization_sensitivity_disclosure.csv"),
  row.names = FALSE)
write.csv(seed_ledger,
  file.path(data_dir, "D14_benchmark_seed_calibration_ledger.csv"),
  row.names = FALSE)

n_fail <- sum(validation_df$status == "FAIL")
cat(sprintf("\nValidation: %d checks, %d FAIL\n", nrow(validation_df), n_fail))
print(validation_df[, c("check_id", "status", "detail")], row.names = FALSE)
cat(sprintf("\nGT_share path: 1929=%.3f | peak %.3f (%d) | 2024=%.3f\n",
            ext$GT_share[ext$year == 1929],
            max(ext$GT_share, na.rm = TRUE), peak_year,
            ext$GT_share[ext$year == 2024]))

if (n_fail == 0) {
  cat("\nGATE: AUTHORIZE_S41_KGT_INCLUSION_IMOLS_ESTIMATION\n")
} else {
  cat("\nGATE: BLOCKED — validation failures; S41 must not run.\n")
  quit(status = 1)
}
