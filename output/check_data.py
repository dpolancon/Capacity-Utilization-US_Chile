import pandas as pd
import numpy as np

df = pd.read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/gpim_specB_components_long.csv")
req_cols = ["y_t", "k_NRC", "k_GOV_TRANS", "tau_real", "p_rel"]
df = df.dropna(subset=req_cols)
df = df[(df['year'] >= 1929) & (df['year'] <= 2024)]

print("Rows:", len(df))
if len(df) > 0:
    print("k_NRC vs k_GT corr:", np.corrcoef(df['k_NRC'], df['k_GOV_TRANS'])[0,1])
    print("Variance k_NRC:", df['k_NRC'].var())
    print("Variance k_GT:", df['k_GOV_TRANS'].var())
