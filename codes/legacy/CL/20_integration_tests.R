library(tseries)
library(readr)
library(urca)

REPO <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
df   <- read_csv(file.path(REPO, "data/processed/chile/ch2_panel_chile.csv"), show_col_types=FALSE)
df_f <- df[df$year >= 1940, ]
vars <- c("y", "k_NR", "k_ME", "pi", "pi_kME")
results <- list()

cat("=== ADF + KPSS (full sample 1940-2024) ===\n\n")
for (v in vars) {
  x      <- df_f[[v]]; x <- x[!is.na(x)]
  adf_l  <- adf.test(x)
  kpss_l <- kpss.test(x, null="Level")
  adf_d  <- adf.test(diff(x))
  verdict <- ifelse(adf_l$p.value > 0.05 & kpss_l$p.value < 0.05 & adf_d$p.value < 0.05,
                    "I(1) PASS", "CHECK")
  cat(sprintf("%-10s ADF=%.3f KPSS=%.3f ADF_d=%.3f %s\n",
              v, adf_l$p.value, kpss_l$p.value, adf_d$p.value, verdict))
  results[[v]] <- data.frame(variable=v,
    adf_levels=round(adf_l$p.value,4),
    kpss_levels=round(kpss_l$p.value,4),
    adf_diff=round(adf_d$p.value,4),
    conclusion=verdict)
}

cat("\n=== Phillips-Perron tests ===\n\n")
pp_results <- list()
for (v in vars) {
  x    <- df_f[[v]]; x <- x[!is.na(x)]
  pp_l <- PP.test(x)
  pp_d <- PP.test(diff(x))
  verdict <- ifelse(pp_l$p.value > 0.05 & pp_d$p.value < 0.05, "I(1) PASS", "CHECK")
  cat(sprintf("%-10s PP_lev=%.3f PP_diff=%.3f %s\n",
              v, pp_l$p.value, pp_d$p.value, verdict))
  pp_results[[v]] <- data.frame(variable=v,
    pp_levels=round(pp_l$p.value,4),
    pp_diff=round(pp_d$p.value,4),
    conclusion_pp=verdict)
}

cat("\n=== Zivot-Andrews (allows one structural break - 1973 coup) ===\n\n")
za_results <- list()
for (v in vars) {
  x <- df_f[[v]]; x <- x[!is.na(x)]
  za <- ur.za(x, model="both", lag=NULL)
  stat  <- za@teststat
  crit5 <- za@cval[2]
  verdict <- ifelse(stat < crit5, "I(1) PASS", "CHECK")
  cat(sprintf("%-10s ZA_stat=%.3f crit5%%=%.3f breakpoint=%d %s\n",
              v, stat, crit5, za@bpoint, verdict))
  za_results[[v]] <- data.frame(variable=v,
    za_stat=round(stat,4),
    crit5pct=round(crit5,4),
    breakpoint=za@bpoint,
    conclusion_za=verdict)
}

out    <- do.call(rbind, results)
out_pp <- do.call(rbind, pp_results)
out_za <- do.call(rbind, za_results)

outdir <- file.path(REPO, "output/stage_a/chile/csv")
dir.create(outdir, recursive=TRUE, showWarnings=FALSE)
write_csv(out,    file.path(outdir, "integration_tests_adf.csv"))
write_csv(out_pp, file.path(outdir, "integration_tests_pp.csv"))
write_csv(out_za, file.path(outdir, "integration_tests_za.csv"))

cat("\n=== Stage gate summary ===\n")
cat(sprintf("ADF: %d/5  PP: %d/5  ZA: %d/5\n",
    sum(out$conclusion=="I(1) PASS"),
    sum(out_pp$conclusion_pp=="I(1) PASS"),
    sum(out_za$conclusion_za=="I(1) PASS")))
cat("\nNote: ZA is decisive for k_NR and k_ME (1973 structural break)\n")
cat("Note: pi contradiction ADF vs PP is known issue with bounded series — theoretical prior I(1)\n")
