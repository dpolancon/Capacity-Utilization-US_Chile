# scratch_inspect_data.R
library(readxl)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

cat("=== ch2_raw_panel_chile.csv ===\n")
raw_panel <- read.csv(file.path(repo_root, "data", "raw", "Chile", "ch2_raw_panel_chile.csv"))
print(colnames(raw_panel))
cat("Year range:", range(raw_panel$year), "\n")

cat("\n=== Astorga2023_SupM2.xlsx ===\n")
m2_path <- file.path(repo_root, "data", "raw", "Chile", "Astorga2023_SupM2.xlsx")
if (file.exists(m2_path)) {
  sheets <- excel_sheets(m2_path)
  cat("Sheets:", paste(sheets, collapse=", "), "\n")
  df_m2 <- read_excel(m2_path, sheet = 1)
  cat("Sheet 1 head:\n")
  print(head(df_m2, 5))
} else {
  cat("File not found:", m2_path, "\n")
}

cat("\n=== K-Stock-Harmonization raw files ===\n")
k_dir <- "C:/ReposGitHub/K-Stock-Harmonization/data/raw"
if (dir.exists(k_dir)) {
  print(list.files(k_dir))
} else {
  cat("K-Stock-Harmonization dir not found\n")
}
