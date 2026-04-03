import pandas as pd
import numpy as np
from pathlib import Path

REPO    = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
IN_FILE = REPO / "data/raw/chile/ch2_raw_panel_chile.csv"
OUT_FILE = REPO / "data/processed/chile/ch2_panel_chile.csv"
OUT_FILE.parent.mkdir(parents=True, exist_ok=True)

df = pd.read_csv(IN_FILE)
print(f"Loaded: {df['year'].min()}-{df['year'].max()}, {len(df)} rows")

# Log transforms
df["y"]    = np.log(df["GDP_real"])
df["k_NR"] = np.log(df["K_NR"])
df["k_ME"] = np.log(df["K_ME"])
df["K_total"] = df["K_NR"] + df["K_ME"]
df["k"]    = np.log(df["K_total"])

# Level variables
df["s_ME"]      = df["K_ME"] / df["K_total"]
df["phi_ME"]    = df["K_ME"] / df["K_NR"]
df["log_phi_ME"] = np.log(df["phi_ME"])

# Interaction term: pi * k_ME (core VECM regressor)
df["pi_kME"] = df["pi"] * df["k_ME"]
df["pi_kNR"] = df["pi"] * df["k_NR"]

# Select columns
cols = ["year","y","k","k_NR","k_ME","pi","s_ME","phi_ME","log_phi_ME",
        "pi_kME","pi_kNR","K_NR","K_ME","K_total","GDP_real",
        "omega","exploitation_rate","FBKF_ME","FBKF_NR","M_CIF","I_total"]
cols = [c for c in cols if c in df.columns]
df_out = df[cols].copy()

# Report coverage for Fordist window
df_fordist = df_out[(df_out["year"] >= 1945) & (df_out["year"] <= 1978)]
print(f"Fordist window (1945-1978): {len(df_fordist)} rows")
print(f"Missing in Fordist window:\n{df_fordist[['y','k_NR','k_ME','pi']].isnull().sum()}")

df_out.to_csv(OUT_FILE, index=False)
print(f"\nSaved: {OUT_FILE}")
print("Next: Rscript codes/stage_a/chile/20_integration_tests.R")
