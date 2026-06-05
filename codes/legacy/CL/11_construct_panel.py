"""
11_construct_panel.py
=====================
Build master Chilean panel from four primary sources:
  1. PerezEyzaguirre — real quantities (2003 CLP, 1860-2010)
  2. ClioLab 4.1.3   — deflators base (2003=100, 1940-2010)
  3. BCCh Canasta     — deflators extension (rebase 2003=100, 1996-2025)
  4. K-Stock-Harmonization — P_K + net capital stocks (2003=100, 1940-2024)

Deflator splice rule (locked):
  ClioLab through 2010, BCCh from 2011 onward.
  Confirmed by Welch t-test: p >> 0.05 for all 6 pairs.
  See output/diagnostics/deflator_splice_summary.csv.
"""

import pandas as pd
import numpy as np
from pathlib import Path

# ── paths ────────────────────────────────────────────────────────────
REPO = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
KSTOCK_REPO = Path("C:/ReposGitHub/K-Stock-Harmonization/outputs/HARMONIZED_BCCH_2003CLP_v1")

PE_FILE   = REPO / "data/raw/Chile/PerezEyzaguirre_DemandaAgregada.xlsx"
CLIO_FILE = REPO / "data/raw/Chile/W04_Precios_ClioLabPUC.xlsx"
BCCH_FILE = REPO / "data/raw/Chile/ADnominal_deflators_19962025_BCCH.xlsx"
PK_FILE   = KSTOCK_REPO / "harmonized_pk_2003base_1940_2024.csv"
KS_FILE   = KSTOCK_REPO / "harmonized_series_2003CLP_1900_2024.csv"

OUT_DIR  = REPO / "output/panel"
OUT_FILE = OUT_DIR / "chile_panel.csv"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SPLICE_YEAR = 2010

# ── Source 1: PerezEyzaguirre real quantities ────────────────────────
def load_perez_eyzaguirre():
    """Real demand-side aggregates, 2003 CLP, 1860-2010."""
    df = pd.read_excel(PE_FILE, sheet_name="Demanda Agregada")
    rename = {
        df.columns[0]:  "year",
        df.columns[1]:  "Y_real",
        df.columns[2]:  "X_real",
        df.columns[3]:  "M_real",
        df.columns[4]:  "NX_real",
        df.columns[5]:  "I_ME_real",
        df.columns[6]:  "I_NRC_real",
        df.columns[7]:  "INV_real",
        df.columns[8]:  "I_real",
        df.columns[9]:  "G_real",
        df.columns[10]: "C_real",
    }
    df = df.rename(columns=rename)
    df["year"] = df["year"].astype(int)
    df = df.set_index("year").apply(pd.to_numeric, errors="coerce")
    return df


# ── Source 2: ClioLab deflators (base) ───────────────────────────────
CLIO_ID_MAP = {
    4003: "P_Y_cl",
    4004: "P_C_cl",
    4005: "P_G_cl",
    4006: "P_K_fbkf_cl",
    4007: "P_X_cl",
    4008: "P_M_cl",
}

def load_cliolab():
    """ClioLab deflator index levels, 2003=100, 1940-2010."""
    raw = pd.read_excel(CLIO_FILE, sheet_name="4.1.3", header=None)
    id_row = raw.iloc[1, 1:7].astype(int).tolist()
    data = raw.iloc[11:, :7].copy()
    data.columns = ["year"] + [CLIO_ID_MAP[sid] for sid in id_row]
    data["year"] = data["year"].astype(int)
    data = data.set_index("year").apply(pd.to_numeric, errors="coerce")
    return data.loc[data.index >= 1940]


# ── Source 3: BCCh deflators (forward extension) ────────────────────
BCCH_MATCH = {
    "P_Y_bc":      ("Deflactor del Producto Interno Bruto",),
    "P_C_bc":      ("Deflactor", "Consumo privado"),
    "P_G_bc":      ("Deflactor", "Consumo gobierno"),
    "P_K_fbkf_bc": ("Deflactor", "Formación bruta de capital fijo"),
    "P_X_bc":      ("Deflactor", "Exportaciones"),
    "P_M_bc":      ("Deflactor", "Importaciones"),
}

def load_bcch():
    """BCCh deflators rebased to 2003=100, 1996-2025."""
    raw = pd.read_excel(BCCH_FILE, sheet_name="Canasta", header=None)
    year_cols = raw.iloc[0, 2:].tolist()
    years = [int(y.year) if hasattr(y, "year") else int(y) for y in year_cols]

    descriptions = raw.iloc[1:, 0].astype(str).tolist()
    row_indices = list(range(1, len(descriptions) + 1))

    result = {}
    for var_name, keywords in BCCH_MATCH.items():
        found = False
        for i, desc in zip(row_indices, descriptions):
            if all(k in desc for k in keywords):
                vals = pd.to_numeric(raw.iloc[i, 2:], errors="coerce").values
                result[var_name] = vals
                found = True
                break
        if not found:
            raise ValueError(f"BCCh: could not match {var_name} with {keywords}")

    df = pd.DataFrame(result, index=years)
    df.index.name = "year"

    # Rebase to 2003=100
    base = df.loc[2003]
    df = df / base * 100
    return df


# ── Source 4: K-Stock-Harmonization ──────────────────────────────────
def load_kstock():
    """P_K (2003=100) + net capital stocks by asset, 1940-2024."""
    # Investment deflator
    pk = pd.read_csv(PK_FILE)
    pk = pk.rename(columns={"Pk_2003base": "P_K"})
    pk = pk[["year", "P_K"]].set_index("year")

    # Net capital stocks
    ks = pd.read_csv(KS_FILE)
    frames = {}
    for asset in ["ME", "NRC"]:
        sub = ks[ks["asset"] == asset][["year", "Kn"]].copy()
        sub = sub.rename(columns={"Kn": f"Kn_{asset}"})
        sub = sub.set_index("year")
        frames[asset] = sub

    kn = frames["ME"].join(frames["NRC"], how="outer")
    return pk.join(kn, how="outer")


# ── Splice deflators ────────────────────────────────────────────────
DEFLATOR_PAIRS = {
    "P_Y":      ("P_Y_cl",      "P_Y_bc"),
    "P_C":      ("P_C_cl",      "P_C_bc"),
    "P_G":      ("P_G_cl",      "P_G_bc"),
    "P_K_fbkf": ("P_K_fbkf_cl", "P_K_fbkf_bc"),
    "P_X":      ("P_X_cl",      "P_X_bc"),
    "P_M":      ("P_M_cl",      "P_M_bc"),
}

def splice_deflators(cliolab, bcch):
    """ClioLab through SPLICE_YEAR, BCCh from SPLICE_YEAR+1 onward."""
    spliced = {}
    for var, (cl_col, bc_col) in DEFLATOR_PAIRS.items():
        spliced[var] = pd.concat([
            cliolab[cl_col].loc[:SPLICE_YEAR],
            bcch[bc_col].loc[SPLICE_YEAR + 1:],
        ])
    return pd.DataFrame(spliced)


# ── Main ─────────────────────────────────────────────────────────────
def main():
    print("=" * 60)
    print("11_construct_panel.py — Chilean master panel")
    print("=" * 60)

    # Load sources
    pe = load_perez_eyzaguirre()
    print(f"PerezEyzaguirre: {pe.index.min()}-{pe.index.max()}, {len(pe)} rows")

    cliolab = load_cliolab()
    print(f"ClioLab:         {cliolab.index.min()}-{cliolab.index.max()}, {len(cliolab)} rows")

    bcch = load_bcch()
    print(f"BCCh:            {bcch.index.min()}-{bcch.index.max()}, {len(bcch)} rows")

    kstock = load_kstock()
    print(f"K-Stock:         {kstock.index.min()}-{kstock.index.max()}, {len(kstock)} rows")

    # Splice deflators
    deflators = splice_deflators(cliolab, bcch)
    print(f"\nSpliced deflators: {deflators.index.min()}-{deflators.index.max()}")
    print(f"  Splice year: {SPLICE_YEAR} (ClioLab ≤{SPLICE_YEAR}, BCCh ≥{SPLICE_YEAR+1})")

    # Assemble panel
    panel = pe.join(deflators, how="outer").join(kstock, how="outer")
    panel.index.name = "year"

    # ── Current-cost net capital stocks ──────────────────────────────
    panel["Kn_cc_ME"]  = panel["Kn_ME"]  * panel["P_K"] / 100
    panel["Kn_cc_NRC"] = panel["Kn_NRC"] * panel["P_K"] / 100
    panel["Kn_cc"]     = panel["Kn_cc_ME"] + panel["Kn_cc_NRC"]

    # ── Derived variables ────────────────────────────────────────────
    panel["P_K_rel"] = panel["P_K"] / panel["P_Y"]
    panel["Y_nom"]   = panel["Y_real"] * panel["P_Y"] / 100

    # ── Period classification ────────────────────────────────────────
    conditions = [
        panel.index < 1940,
        (panel.index >= 1940) & (panel.index <= 1978),
        (panel.index >= 1979) & (panel.index <= 1984),
        panel.index >= 1985,
    ]
    choices = ["pre_fordist", "fordist", "transition", "neoliberal"]
    panel["period"] = np.select(conditions, choices, default="unknown")

    panel["in_investment_window"] = (panel.index >= 1940) & (panel.index <= 1978)

    # ── Fordist window assertion ─────────────────────────────────────
    FORDIST = slice(1945, 1978)
    key_vars = [
        "Y_real", "I_ME_real", "I_NRC_real", "P_Y", "P_K",
        "Kn_cc_ME", "Kn_cc_NRC", "P_K_rel",
    ]
    missing = panel.loc[FORDIST, key_vars].isnull().sum()
    fordist_ok = missing.sum() == 0

    print(f"\n{'='*60}")
    print(f"Panel shape: {panel.shape[0]} rows × {panel.shape[1]} cols")
    print(f"Year range:  {panel.index.min()}-{panel.index.max()}")
    print(f"Fordist window (1945-1978): {'PASSED' if fordist_ok else 'FAILED'}")

    if not fordist_ok:
        print(f"\n*** MISSING VALUES IN FORDIST WINDOW ***")
        for v in missing[missing > 0].index:
            yrs = panel.loc[FORDIST, v]
            miss_yrs = yrs[yrs.isnull()].index.tolist()
            print(f"  {v}: {missing[v]} missing — years {miss_yrs}")
        raise AssertionError("Missing values in Fordist window — cannot proceed.")

    # Missing values summary (post-1940)
    post1940 = panel.loc[1940:]
    miss_post = post1940.isnull().sum()
    miss_post = miss_post[miss_post > 0].sort_values(ascending=False)
    if len(miss_post) > 0:
        print(f"\nMissing values by variable (post-1940):")
        for v, n in miss_post.items():
            print(f"  {v:20s}: {n}")
    else:
        print(f"\nNo missing values post-1940.")

    # ── Save ─────────────────────────────────────────────────────────
    panel.to_csv(OUT_FILE)
    print(f"\nSaved: {OUT_FILE}")


if __name__ == "__main__":
    main()
