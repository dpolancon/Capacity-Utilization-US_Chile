import pandas as pd
import numpy as np
from pathlib import Path

REPO   = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
KSTOCK = Path("C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1/harmonized_series_2003CLP_1900_2024.csv")
DISTR  = REPO / "data/raw/Chile/distr_19202024.xlsx"
GDP    = REPO / "data/raw/Chile/PerezEyzaguirre_DemandaAgregada.xlsx"
OUT    = REPO / "data/raw/chile/ch2_raw_panel_chile.csv"
OUT.parent.mkdir(parents=True, exist_ok=True)

print("Loading K-Stock...")
df_k = pd.read_csv(KSTOCK)
df_k = df_k[df_k["asset"].isin(["ME","NR"])][["year","asset","Kn"]].copy()
df_k = df_k.pivot(index="year", columns="asset", values="Kn").reset_index()
df_k.columns.name = None
df_k = df_k.rename(columns={"NR":"K_NR","ME":"K_ME"})
print(f"  K-Stock: {df_k['year'].min()}-{df_k['year'].max()}, {len(df_k)} rows")

print("Loading distribution...")
df_d = pd.read_excel(DISTR, sheet_name="values")
df_d = df_d[["periodo","psh","wsh","e"]].rename(columns={"periodo":"year","psh":"pi","wsh":"omega","e":"exploitation_rate"})
print(f"  Distribution: {df_d['year'].min()}-{df_d['year'].max()}, {len(df_d)} rows")

print("Loading GDP...")
df_g = pd.read_excel(GDP, header=0)
df_g.columns = ["year","GDP_real","X_FOB","M_CIF","X_net","FBKF_ME","FBKF_NR","inv_change","I_total","G","C_priv"]
df_g = df_g.dropna(subset=["year"])
df_g["year"] = df_g["year"].astype(int)
print(f"  GDP: {df_g['year'].min()}-{df_g['year'].max()}, {len(df_g)} rows")

print("Merging...")
df = df_k.merge(df_d, on="year", how="outer")
df = df.merge(df_g, on="year", how="outer")
df = df.sort_values("year").reset_index(drop=True)
print(f"  Panel: {df['year'].min()}-{df['year'].max()}, {len(df)} rows")
print(f"  Missing:\n{df[['year','K_NR','K_ME','pi','GDP_real']].isnull().sum()}")

df.to_csv(OUT, index=False)
print(f"\nSaved: {OUT}")
print("Next: python codes/stage_a/chile/11_construct_panel.py")
