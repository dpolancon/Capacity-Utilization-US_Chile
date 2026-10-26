import os
import sys
import pandas as pd
from datetime import date
from dotenv import load_dotenv
import bcchapi

def main():
    # Load env
    load_dotenv(r"C:\ReposGitHub\Capacity-Utilization-US_Chile\.env")
    
    token = os.environ.get("BCCH_PASSWORD")
    
    if not token or token == "your_api_password":
        print("ERROR: Invalid or missing BCCh API token in .env (BCCH_PASSWORD)")
        sys.exit(1)
        
    siete = bcchapi.Siete(token=token)
    
    print("Querying BCCh API for F032.PIB.FLU.R.CLP.EP18.Z.Z.0.T (2010-2025)...")
    try:
        # We query the quarterly series because the annual series is not available in the API for real GDP
        df_bcch = siete.cuadro(
            series=["F032.PIB.FLU.R.CLP.EP18.Z.Z.0.T"],
            desde="2010-01-01",
            hasta="2025-12-31"
        )
    except Exception as e:
        print(f"API Error: {e}")
        sys.exit(1)
        
    if df_bcch.empty:
        print("ERROR: No data returned from BCCh API")
        sys.exit(1)
        
    df_bcch = df_bcch.reset_index()
    # rename index column to date
    df_bcch = df_bcch.rename(columns={df_bcch.columns[0]: 'date', 'F032.PIB.FLU.R.CLP.EP18.Z.Z.0.T': 'value'})
    
    df_bcch['date'] = pd.to_datetime(df_bcch['date'])
    df_bcch['year'] = df_bcch['date'].dt.year
    
    # Aggregate quarterly flow to annual by summing
    df_annual = df_bcch.groupby('year')['value'].sum().reset_index()
    bcch_dict = dict(zip(df_annual['year'], df_annual['value']))
    
    staged_path = r"C:\ReposGitHub\Capacity-Utilization-US_Chile\data\staged\ch2_panel_chile_with_prices.csv"
    df_staged = pd.read_csv(staged_path)
    
    # Splice
    spliced_gdp = []
    
    for year in range(1860, 2026):
        if year <= 2010:
            val = df_staged.loc[df_staged['year'] == year, 'GDP_real'].values
            spliced_gdp.append({'year': year, 'GDP_real_spliced': val[0] if len(val) > 0 else None})
        else:
            # chaining
            prev_year = spliced_gdp[-1]['GDP_real_spliced']
            bcch_t = bcch_dict.get(year)
            bcch_t_1 = bcch_dict.get(year - 1)
            
            if bcch_t and bcch_t_1:
                growth_rate = bcch_t / bcch_t_1
                new_val = prev_year * growth_rate
                spliced_gdp.append({'year': year, 'GDP_real_spliced': new_val})
            else:
                spliced_gdp.append({'year': year, 'GDP_real_spliced': None})
                
    df_out = pd.DataFrame(spliced_gdp)
    
    out_dir = r"C:\ReposGitHub\Capacity-Utilization-US_Chile\data\interim\Chile"
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, "gdp_spliced_1860_2025.csv")
    df_out.to_csv(out_path, index=False)
    
    print(f"Successfully spliced GDP and saved to {out_path}")
    print(df_out.tail(20))

if __name__ == "__main__":
    main()
