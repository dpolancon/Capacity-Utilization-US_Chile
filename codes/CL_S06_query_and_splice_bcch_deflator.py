import os
import sys
import pandas as pd
from dotenv import load_dotenv
import bcchapi

def main():
    load_dotenv(r"C:\ReposGitHub\Capacity-Utilization-US_Chile\.env")
    token = os.environ.get("BCCH_PASSWORD")
    siete = bcchapi.Siete(token=token)
    
    # 1. Fetch BCCh Deflator (2010-2025)
    print("Fetching BCCh Deflator (Annual)...")
    try:
        # F032.PIB.DEF.N.CLP.EP18.Z.Z.0.A is the Annual Deflator
        df_bcch = siete.cuadro(
            series=["F032.PIB.DEF.N.CLP.EP18.Z.Z.0.A"],
            desde="2010-01-01",
            hasta="2025-12-31"
        )
    except Exception as e:
        print(f"API Error: {e}")
        sys.exit(1)
        
    df_bcch = df_bcch.reset_index()
    df_bcch = df_bcch.rename(columns={df_bcch.columns[0]: 'date', 'F032.PIB.DEF.N.CLP.EP18.Z.Z.0.A': 'value'})
    df_bcch['date'] = pd.to_datetime(df_bcch['date'])
    df_bcch['year'] = df_bcch['date'].dt.year
    bcch_dict = dict(zip(df_bcch['year'], df_bcch['value']))
    
    # 2. Read ClioLab DEFPGB (1810-2010)
    clio_path = r"C:\ReposGitHub\Capacity-Utilization-US_Chile\data\raw\Chile\W04_Precios_ClioLabPUC.xlsx"
    df_clio = pd.read_excel(clio_path, sheet_name='4.1.3', skiprows=10)
    df_clio = df_clio[['Code', 'DEFPGB']].rename(columns={'Code': 'year'})
    df_clio = df_clio.dropna()
    
    # Splice
    spliced_def = []
    
    for year in range(1860, 2026):
        if year <= 2010:
            val = df_clio.loc[df_clio['year'] == year, 'DEFPGB'].values
            spliced_def.append({'year': year, 'P_Y_spliced': val[0] if len(val) > 0 else None})
        else:
            prev_year = spliced_def[-1]['P_Y_spliced']
            bcch_t = bcch_dict.get(year)
            bcch_t_1 = bcch_dict.get(year - 1)
            
            if bcch_t and bcch_t_1:
                growth_rate = bcch_t / bcch_t_1
                new_val = prev_year * growth_rate
                spliced_def.append({'year': year, 'P_Y_spliced': new_val})
            else:
                spliced_def.append({'year': year, 'P_Y_spliced': None})
                
    df_out = pd.DataFrame(spliced_def)
    out_dir = r"C:\ReposGitHub\Capacity-Utilization-US_Chile\data\interim\Chile"
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "gdp_deflator_spliced_1860_2025.csv")
    df_out.to_csv(out_path, index=False)
    
    print(f"Successfully spliced GDP Deflator and saved to {out_path}")
    print(df_out.tail(20))

if __name__ == "__main__":
    main()
