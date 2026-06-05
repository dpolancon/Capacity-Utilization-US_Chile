"""
00_deflator_splice_diagnostic.py
Diagnostic: compare ClioLab vs BCCh deflator growth rates in the
overlap window 1996-2010.  Outputs two CSVs; does NOT implement splice.
"""

import pathlib
import pandas as pd
import numpy as np
from scipy import stats

# ── paths ────────────────────────────────────────────────────────────
ROOT = pathlib.Path(__file__).resolve().parents[3]
CLIO_PATH = ROOT / "data/raw/Chile/W04_Precios_ClioLabPUC.xlsx"
BCCH_PATH = ROOT / "data/raw/Chile/ADnominal_deflators_19962025_BCCH.xlsx"
OUT_DIR = ROOT / "output/diagnostics"
OUT_DIR.mkdir(parents=True, exist_ok=True)

# ── deflator mapping ────────────────────────────────────────────────
DEFLATORS = ["P_Y", "P_C", "P_G", "P_K", "P_X", "P_M"]

# ClioLab: series IDs in row 2 of sheet 4.1.3
CLIO_ID_MAP = {
    4003: "P_Y",
    4004: "P_C",
    4005: "P_G",
    4006: "P_K",
    4007: "P_X",
    4008: "P_M",
}

# BCCh: partial-match strings in 'Descripción series' (sheet Canasta)
BCCH_MATCH = {
    "P_Y": "Deflactor del Producto Interno Bruto",
    "P_C": ("Consumo privado",),
    "P_G": ("Consumo gobierno",),
    "P_K": ("Formación bruta de capital fijo",),
    "P_X": ("Exportaciones",),
    "P_M": ("Importaciones",),
}

OVERLAP = range(1996, 2011)  # 1996-2010 inclusive


# ── loaders ──────────────────────────────────────────────────────────
def load_cliolab() -> pd.DataFrame:
    """Load ClioLab deflator index levels (2003=100)."""
    # Read raw — skip header rows 1-10 (0-indexed: skiprows=0..10),
    # row 2 has IDs, row 11 has codes, data from row 12.
    # Easier: read with header=None, parse manually.
    raw = pd.read_excel(CLIO_PATH, sheet_name="4.1.3", header=None)
    # Row 1 (0-indexed) has series IDs in columns 1-6
    id_row = raw.iloc[1, 1:7].astype(int).tolist()
    # Data starts at row 11 (0-indexed) — year in col 0, values in cols 1-6
    data = raw.iloc[11:, :7].copy()
    data.columns = ["year"] + [CLIO_ID_MAP[sid] for sid in id_row]
    data["year"] = data["year"].astype(int)
    data = data.set_index("year")
    data = data.apply(pd.to_numeric, errors="coerce")
    return data.loc[data.index >= 1940]


def load_bcch() -> pd.DataFrame:
    """Load BCCh deflators, rebase to 2003=100."""
    raw = pd.read_excel(BCCH_PATH, sheet_name="Canasta", header=None)
    # Row 0: headers — cols 2+ are datetime years
    year_cols = raw.iloc[0, 2:].tolist()
    years = [int(y.year) if hasattr(y, "year") else int(y) for y in year_cols]

    # Extract description column for matching
    descriptions = raw.iloc[1:, 0].astype(str).tolist()
    row_indices = list(range(1, len(descriptions) + 1))

    # Build dict: deflator_code -> series values
    result = {}

    for code, match in BCCH_MATCH.items():
        found = False
        for i, desc in zip(row_indices, descriptions):
            if code == "P_Y":
                # Exact match for GDP deflator
                if match in desc:
                    vals = pd.to_numeric(raw.iloc[i, 2:], errors="coerce").values
                    result[code] = vals
                    found = True
                    break
            else:
                # Must contain "Deflactor" AND the specific substring
                keywords = match
                if "Deflactor" in desc and all(k in desc for k in keywords):
                    vals = pd.to_numeric(raw.iloc[i, 2:], errors="coerce").values
                    result[code] = vals
                    found = True
                    break
        if not found:
            raise ValueError(f"BCCh: could not match deflator {code}")

    df = pd.DataFrame(result, index=years)
    df.index.name = "year"

    # Rebase to 2003=100
    base_2003 = df.loc[2003]
    df = df / base_2003 * 100

    return df


# ── main ─────────────────────────────────────────────────────────────
def main():
    cliolab = load_cliolab()
    bcch = load_bcch()

    print("ClioLab range:", cliolab.index.min(), "-", cliolab.index.max())
    print("BCCh range:   ", bcch.index.min(), "-", bcch.index.max())

    diagnostics = []
    summary = []

    for defl in DEFLATORS:
        # Growth rates in overlap window
        gr_cl = cliolab[defl].pct_change().loc[list(OVERLAP)]
        gr_bc = bcch[defl].pct_change().loc[list(OVERLAP)]

        # Year-by-year diagnostics
        for yr in OVERLAP:
            diagnostics.append(
                {
                    "deflator": defl,
                    "year": yr,
                    "gr_cliolab": gr_cl.loc[yr],
                    "gr_bcch": gr_bc.loc[yr],
                    "deviation": gr_cl.loc[yr] - gr_bc.loc[yr],
                }
            )

        # Summary statistics
        mean_cl, sd_cl = gr_cl.mean(), gr_cl.std()
        mean_bc, sd_bc = gr_bc.mean(), gr_bc.std()

        # Welch t-test
        t_stat, p_value = stats.ttest_ind(
            gr_cl.dropna(), gr_bc.dropna(), equal_var=False
        )
        significant = p_value < 0.05

        summary.append(
            {
                "deflator": defl,
                "mean_cliolab": mean_cl,
                "sd_cliolab": sd_cl,
                "mean_bcch": mean_bc,
                "sd_bcch": sd_bc,
                "t_stat": t_stat,
                "p_value": p_value,
                "significant": significant,
            }
        )

        flag = " ***" if significant else ""
        print(
            f"  {defl:4s}  ClioLab={mean_cl:+.4f}  BCCh={mean_bc:+.4f}  "
            f"t={t_stat:+.3f}  p={p_value:.4f}{flag}"
        )

    # ── write outputs ────────────────────────────────────────────────
    df_diag = pd.DataFrame(diagnostics)
    df_summ = pd.DataFrame(summary)

    df_diag.to_csv(OUT_DIR / "deflator_splice_diagnostics.csv", index=False)
    df_summ.to_csv(OUT_DIR / "deflator_splice_summary.csv", index=False)

    print(f"\nWrote: {OUT_DIR / 'deflator_splice_diagnostics.csv'}")
    print(f"Wrote: {OUT_DIR / 'deflator_splice_summary.csv'}")


if __name__ == "__main__":
    main()
