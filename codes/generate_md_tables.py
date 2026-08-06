import pandas as pd
import os

csv_path = "output/US/S50_SECTION31_IMOLS/csv/s50_section31_results.csv"
md_dir = "reports/US_Section31_IMOLS_Results"
os.makedirs(md_dir, exist_ok=True)

df = pd.read_csv(csv_path)

def format_cell(coef, se):
    if pd.isna(coef):
        return ""
    coef_str = f"{coef:.3f}"
    se_str = f"({se:.3f})"
    return f"{coef_str}<br>{se_str}"

for spec_set in df['Spec_Set'].unique():
    subset = df[df['Spec_Set'] == spec_set].copy()
    
    md_lines = []
    md_lines.append(f"# {spec_set} Results\n")
    md_lines.append("| Wage Base | Capital Base | Break Mode | Break Year | Bandwidth $b$ | ADF | Shin LM | VW Type 2 | $\\theta_K$ | $\\phi_\\omega$ | $\\gamma_{x_3}$ | Interaction |")
    md_lines.append("|---|---|---|---|---|---|---|---|---|---|---|---|")
    
    for _, row in subset.iterrows():
        wage = str(row['Wage_Label'])
        cap = str(row['Capital_Label'])
        b_mode = str(row['Break_Mode'])
        b_year = str(row['Break_Years']) if pd.notna(row['Break_Years']) else "None"
        b_hat = f"{row['B_Hat']:.4f}" if pd.notna(row['B_Hat']) else ""
        
        adf_sig = str(row['EG_ADF_stars']) if pd.notna(row['EG_ADF_stars']) else ""
        adf = f"{row['EG_ADF_stat']:.2f}{adf_sig}" if pd.notna(row['EG_ADF_stat']) else ""
        
        shin_sig = str(row['Shin_stars']) if pd.notna(row['Shin_stars']) else ""
        shin = f"{row['Shin_stat']:.2f}{shin_sig}" if pd.notna(row['Shin_stat']) else ""
        
        vw_sig = str(row['VW_stars']) if pd.notna(row['VW_stars']) else ""
        vw = f"{row['VW_stat']:.2f}{vw_sig}" if pd.notna(row['VW_stat']) else ""
        
        theta_k = format_cell(row['theta_0'], row['theta_0_sd'])
        phi_w = format_cell(row['phi_w'], row['phi_w_sd'])
        gam_c = format_cell(row['gam_c'], row['gam_c_sd'])
        inter = format_cell(row['theta_1'], row['theta_1_sd'])
            
        md_lines.append(f"| {wage} | {cap} | {b_mode} | {b_year} | {b_hat} | {adf} | {shin} | {vw} | {theta_k} | {phi_w} | {gam_c} | {inter} |")
        
    md_path = os.path.join(md_dir, f"{spec_set.replace(' ', '_').replace('(', '').replace(')', '')}.md")
    with open(md_path, 'w') as f:
        f.write("\n".join(md_lines))
    print(f"Generated {md_path}")

print("Markdown artifacts created.")
