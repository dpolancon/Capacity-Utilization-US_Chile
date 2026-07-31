# scratch_inspect_astorga_chile.R
library(readxl)
repo_root <- "C:/ReposGitHub/Capacity-Utilization-US_Chile"
path <- file.path(repo_root, "data", "raw", "Chile", "Astorga2023_SupM3.xlsx")
df <- read_excel(path, sheet = "Chile", skip = 2)
print(head(df, 15))
