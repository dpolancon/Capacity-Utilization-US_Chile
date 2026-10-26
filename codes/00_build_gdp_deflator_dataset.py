#!/usr/bin/env python3
"""
00_build_gdp_deflator_dataset.py
---------------------------------
Constructs standardized Real GDP, Nominal GDP, and GDP Deflator datasets
for Chile (1860-2025) and the United States (1929-2025).

Outputs:
  - data/processed/gdp_deflator/chile_gdp_deflator_annual_1860_2025.csv
  - data/processed/gdp_deflator/us_gdp_deflator_annual_1929_2025.csv
  - data/processed/gdp_deflator/us_chile_gdp_deflator_panel_annual.csv
  - output/gdp_deflator/csv/chile_gdp_deflator_annual_1860_2025.csv
  - output/gdp_deflator/csv/us_gdp_deflator_annual_1929_2025.csv
  - output/gdp_deflator/csv/us_chile_gdp_deflator_panel_annual.csv
"""

import os
import pandas as pd
import numpy as np

def main():
    repo_root = r"C:\ReposGitHub\Capacity-Utilization-US_Chile"
    
    # ---------------------------------------------------------
    # 1. Process Chile Data (1860 - 2025)
    # ---------------------------------------------------------
    cl_gdp_path = os.path.join(repo_root, "data", "interim", "Chile", "gdp_spliced_1860_2025.csv")
    cl_def_path = os.path.join(repo_root, "data", "interim", "Chile", "gdp_deflator_spliced_1860_2025.csv")
    
    df_cl_gdp = pd.read_csv(cl_gdp_path)
    df_cl_def = pd.read_csv(cl_def_path)
    
    df_cl = pd.merge(df_cl_gdp, df_cl_def, on="year", how="inner")
    
    # Ensure sorted by year
    df_cl = df_cl.sort_values("year").reset_index(drop=True)
    
    # Format columns for Chile
    df_cl["country"] = "Chile"
    df_cl["iso3"] = "CHL"
    df_cl["local_currency"] = "CLP"
    df_cl["sector_boundary"] = "Total Economy (Aggregate GDP)"
    df_cl["gdp_real_mil"] = df_cl["GDP_real_spliced"]
    df_cl["gdp_deflator_index"] = df_cl["P_Y_spliced"]
    df_cl["base_year"] = 2003
    
    # Nominal GDP = Real GDP * (Deflator / 100)
    df_cl["gdp_nominal_mil"] = df_cl["gdp_real_mil"] * (df_cl["gdp_deflator_index"] / 100.0)
    
    df_cl["source_provenance"] = (
        "PerezEyzaguirre (1860-2010) spliced with BCCh API Siete (2010-2025) for Real GDP; "
        "ClioLab DEFPGB (1860-2010) spliced with BCCh API deflator (2010-2025) for GDP Deflator"
    )
    
    cl_cols = [
        "country", "iso3", "year", "sector_boundary", "local_currency",
        "gdp_nominal_mil", "gdp_real_mil", "gdp_deflator_index", "base_year",
        "source_provenance"
    ]
    df_cl_clean = df_cl[cl_cols].copy()
    
    # ---------------------------------------------------------
    # 2. Process US Data (1929 - 2025)
    # ---------------------------------------------------------
    us_gdpa_path = os.path.join(repo_root, "data", "raw", "US", "fred", "GDPA.csv")
    us_def_path = os.path.join(repo_root, "data", "raw", "US", "fred", "A191RD3A086NBEA.csv")
    
    df_us_gdpa = pd.read_csv(us_gdpa_path)
    df_us_def = pd.read_csv(us_def_path)
    
    # Select year and value
    df_us_gdpa = df_us_gdpa[["year", "value"]].rename(columns={"value": "GDPA_nominal_billions"})
    df_us_def = df_us_def[["year", "value"]].rename(columns={"value": "A191RD3A_deflator_2017"})
    
    df_us_macro = pd.merge(df_us_gdpa, df_us_def, on="year", how="inner").sort_values("year").reset_index(drop=True)
    
    df_us_macro["country"] = "United States"
    df_us_macro["iso3"] = "USA"
    df_us_macro["local_currency"] = "USD"
    df_us_macro["sector_boundary"] = "Total Economy (Aggregate GDP)"
    df_us_macro["gdp_nominal_mil"] = df_us_macro["GDPA_nominal_billions"] * 1000.0
    df_us_macro["gdp_deflator_index"] = df_us_macro["A191RD3A_deflator_2017"]
    df_us_macro["gdp_real_mil"] = df_us_macro["gdp_nominal_mil"] / (df_us_macro["gdp_deflator_index"] / 100.0)
    df_us_macro["base_year"] = 2017
    df_us_macro["source_provenance"] = "BEA NIPA Table 1.1.5 (GDPA) & NIPA Table 1.1.9 (A191RD3A086NBEA) via FRED API"
    
    df_us_macro_clean = df_us_macro[cl_cols].copy()
    
    # ---------------------------------------------------------
    # 3. Add US Non-Financial Corporate GVA Layer (1929 - 2024)
    # ---------------------------------------------------------
    us_nfc_real_path = os.path.join(
        repo_root, "output", "US", "S12B_OUTPUT_PRICE_REAL_OUTPUT", "csv", "S12B_real_output_objects_long.csv"
    )
    df_us_nfc_raw = pd.read_csv(us_nfc_real_path)
    
    # Filter for baseline NFC object
    df_us_nfc_base = df_us_nfc_raw[df_us_nfc_raw["variable_name"] == "Y_REAL_NFC_GVA_BASELINE"].copy()
    
    df_us_nfc = pd.DataFrame({
        "country": "United States",
        "iso3": "USA",
        "year": df_us_nfc_base["year"],
        "sector_boundary": "Non-Financial Corporate (NFC GVA)",
        "local_currency": "USD",
        "gdp_nominal_mil": df_us_nfc_base["nominal_gva_value"],
        "gdp_real_mil": df_us_nfc_base["real_output_value"],
        "gdp_deflator_index": df_us_nfc_base["price_index_value"],
        "base_year": 2017,
        "source_provenance": "BEA NIPA Table 1.14 (T11400 lines 17 and 41) via S12B output layer protocol"
    }).sort_values("year").reset_index(drop=True)
    
    # Combine US aggregate and US NFC into a single US dataset
    df_us_clean = pd.concat([df_us_macro_clean, df_us_nfc], ignore_index=True)
    
    # Combine all into long panel
    df_panel = pd.concat([df_cl_clean, df_us_macro_clean], ignore_index=True)
    
    # ---------------------------------------------------------
    # 4. Save CSV Artifacts
    # ---------------------------------------------------------
    proc_dir = os.path.join(repo_root, "data", "processed", "gdp_deflator")
    out_dir = os.path.join(repo_root, "output", "gdp_deflator", "csv")
    
    os.makedirs(proc_dir, exist_ok=True)
    os.makedirs(out_dir, exist_ok=True)
    
    targets = [
        ("chile_gdp_deflator_annual_1860_2025.csv", df_cl_clean),
        ("us_gdp_deflator_annual_1929_2025.csv", df_us_clean),
        ("us_chile_gdp_deflator_panel_annual.csv", df_panel)
    ]
    
    for filename, df in targets:
        p_path = os.path.join(proc_dir, filename)
        o_path = os.path.join(out_dir, filename)
        df.to_csv(p_path, index=False)
        df.to_csv(o_path, index=False)
        print(f"[OK] Saved {filename} ({len(df)} rows) to processed and output directories.")

    # ---------------------------------------------------------
    # 5. Verification Checks
    # ---------------------------------------------------------
    print("\n--- RUNNING VALIDATION CHECKS ---")
    
    # Check nulls
    for filename, df in targets:
        null_count = df[["gdp_nominal_mil", "gdp_real_mil", "gdp_deflator_index"]].isnull().sum().sum()
        assert null_count == 0, f"Error: Null values detected in {filename}"
        
        # Check identity: Real * Deflator / 100 == Nominal within 0.1% tolerance (due to index rounding)
        calc_nom = df["gdp_real_mil"] * (df["gdp_deflator_index"] / 100.0)
        rel_diff = np.abs(calc_nom - df["gdp_nominal_mil"]) / df["gdp_nominal_mil"]
        max_diff = rel_diff.max()
        print(f"{filename}: Max relative discrepancy between Real*Deflator/100 and Nominal = {max_diff:.6f}")
        assert max_diff < 0.01, f"Error: Identity check failed for {filename}"

    print("[SUCCESS] All dataset build and validation checks passed clean!")

if __name__ == "__main__":
    main()
