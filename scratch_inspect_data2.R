# scratch_inspect_data2.R
library(readxl)

repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"

check_excel <- function(fname) {
  path <- file.path(repo_root, "data", "raw", "Chile", fname)
  cat("\n=== Checking:", fname, "===\n")
  if (file.exists(path)) {
    sheets <- excel_sheets(path)
    cat("Sheets:", paste(sheets, collapse=", "), "\n")
    for (s in sheets[1:min(length(sheets), 3)]) {
      df <- read_excel(path, sheet = s, n_max = 5)
      cat("--- Sheet:", s, "---\n")
      print(colnames(df))
    }
  }
}

check_excel("distr_19202024.xlsx")
check_excel("PerezEyzaguirre_DemandaAgregada.xlsx")
check_excel("Astorga2023_SupM3.xlsx")
check_excel("CentralBank_RentsShares.xlsx")
check_excel("W04_Precios_ClioLabPUC.xlsx")
