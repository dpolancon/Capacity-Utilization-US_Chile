# .Rprofile — Capacity-Utilization-US_Chile
# Suppress all interactive prompts during scripted runs

options(
  repos                     = c(CRAN = "https://cloud.r-project.org"),
  install.packages.check.source = "no",
  ask                       = FALSE,
  pkgType                   = "binary",
  Ncpus                     = 2
)

if (!interactive()) {
  options(warn = -1, keep.source = FALSE)
}
