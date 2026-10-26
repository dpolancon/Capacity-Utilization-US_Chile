import pandas as pd
import os

# Configuration
results_path = 'output/US/S61_SECTION32_IMOLS/csv/s61_section32_results.csv'
out_dir = 'chapter2_paper/paper_tex_tables'

os.makedirs(out_dir, exist_ok=True)

df = pd.read_csv(results_path)

# Ensure numeric types where appropriate
cols_to_numeric = ['Alpha_Est', 'Alpha_SD', 'Theta_kn_Est', 'Theta_kn_SD', 
                   'Theta_kp_Est', 'Theta_kp_SD', 'Theta_iw_Est', 'Theta_iw_SD',
                   'Theta_ip_Est', 'Theta_ip_SD', 't_ADF', 'Shin_LM', 'VW_Type2', 'Bandwidth_b', 'Sample_T']
for c in cols_to_numeric:
    if c in df.columns:
        df[c] = pd.to_numeric(df[c], errors='coerce')

# Map Stars
def get_stars(val):
    if pd.isna(val):
        return ""
    return str(val).strip()

df['ADF_Stars'] = df['ADF_Stars'].apply(get_stars)
df['Shin_Stars'] = df['Shin_Stars'].apply(get_stars)
df['VW_Stars'] = df['VW_Stars'].apply(get_stars)

# Define wage mapping for column logic
wage_labels_ordered = [
    "NFC Baseline",
    "Corporate Baseline",
    "Shaikh-Tonak Tier 1",
    "Shaikh-Tonak Tier 2",
    "Clean Corporate Tier 1",
    "Clean Corporate Tier 2"
]

def map_wage_label_to_base(lbl):
    if "NFC" in lbl: return "NFC Baseline"
    if "Corporate GVA" in lbl or "Corporate NVA" in lbl: return "Corporate Baseline"
    if "Clean Corporate Tier 1" in lbl: return "Clean Corporate Tier 1"
    if "Clean Corporate Tier 2" in lbl: return "Clean Corporate Tier 2"
    if "Shaikh-Tonak Tier 1" in lbl: return "Shaikh-Tonak Tier 1"
    if "Shaikh-Tonak Tier 2" in lbl: return "Shaikh-Tonak Tier 2"
    return lbl

df['Wage_Base'] = df['Wage_Label'].apply(map_wage_label_to_base)
df['Basis'] = df['Wage_Label'].apply(lambda x: 'NVA' if 'NVA' in x else 'GVA')

def get_coef_stars(est, sd):
    if pd.isna(est) or pd.isna(sd) or sd == 0:
        return ""
    t = abs(est / sd)
    if t >= 3.50:
        return "^{***}"
    elif t >= 2.40:
        return "^{**}"
    elif t >= 1.75:
        return "^{*}"
    return ""

# Main Table: Spec B, Set 2, NVA
def generate_main_table():
    subset = df[(df['Spec_Set'] == 'Set_2') & (df['Basis'] == 'NVA')].copy()
    
    if subset.empty: return
    
    # Keep only these 4 for main table
    cols_order = ["NFC Baseline", "Clean Corporate Tier 1", "Clean Corporate Tier 2", "Shaikh-Tonak Tier 2"]
    subset = subset[subset['Wage_Base'].isin(cols_order)]
    
    # Sort
    subset['Wage_Order'] = subset['Wage_Base'].apply(lambda x: cols_order.index(x) if x in cols_order else 99)
    subset['Break_Order'] = subset['Break_Mode'].apply(lambda x: 0 if x == 'No' else 1)
    subset = subset.sort_values(['Wage_Order', 'Break_Order'])
    
    tex = []
    tex.append("\\begin{table}[h!]")
    tex.append("\\centering")
    tex.append("\\caption{Specification B, Set 2: Effective Wage Interaction (NVA Basis)}")
    tex.append("\\label{tab:specB_set2_nva_main}")
    tex.append("\\small")
    tex.append("\\begin{tabular}{p{3.0cm}p{1.25cm}p{1.25cm}p{1.25cm}p{1.25cm}p{1.5cm}p{1.5cm}p{1.5cm}p{1.5cm}}")
    tex.append("\\toprule")
    
    tex.append(" & \\multicolumn{2}{c}{NFC NVA Baseline} & \\multicolumn{2}{c}{Clean Corp Tier 1} & \\multicolumn{2}{c}{Clean Corp Tier 2} & \\multicolumn{2}{c}{ST Tier 2 NVA} \\\\")
    tex.append("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}")
    tex.append(" & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\\\")
    tex.append("\\midrule")
    
    def row_fmt(title, est_col, sd_col=None, star_col=None, is_coef=False):
        vals = []
        for _, r in subset.iterrows():
            est = f"{r[est_col]:.2f}" if pd.notna(r[est_col]) else ""
            if is_coef and sd_col and pd.notna(r[est_col]) and pd.notna(r[sd_col]):
                stars = get_coef_stars(r[est_col], r[sd_col])
                if stars:
                    est += f"${stars}$"
            elif star_col and pd.notna(r[star_col]):
                est += r[star_col]
            vals.append(est)
        return title + " & " + " & ".join(vals) + " \\\\"
        
    def sd_fmt(sd_col):
        vals = []
        for _, r in subset.iterrows():
            sd = f"({r[sd_col]:.2f})" if pd.notna(r[sd_col]) else ""
            vals.append(sd)
        return " & " + " & ".join(vals) + " \\\\"
    
    # Parameters
    # 1. kn
    tex.append(row_fmt("$\\hat{\\theta}_{\\text{NRC}}$ (Structures $k^{\\text{NRC}}$)", 'Theta_kn_Est', sd_col='Theta_kn_SD', is_coef=True))
    tex.append(sd_fmt('Theta_kn_SD'))
    # 2. kp
    tex.append(row_fmt("$\\hat{\\theta}_{\\kappa}$ (Mechanization Gap $\\kappa$)", 'Theta_kp_Est', sd_col='Theta_kp_SD', is_coef=True))
    tex.append(sd_fmt('Theta_kp_SD'))
    # 3. iw
    tex.append(row_fmt("$\\hat{\\theta}_{\\omega\\kappa}$ (Wage Interaction)", 'Theta_iw_Est', sd_col='Theta_iw_SD', is_coef=True))
    tex.append(sd_fmt('Theta_iw_SD'))
    # 4. ip
    tex.append(row_fmt("$\\hat{\\theta}_{\\kappa p}$ (Price Interaction)", 'Theta_ip_Est', sd_col='Theta_ip_SD', is_coef=True))
    tex.append(sd_fmt('Theta_ip_SD'))
    
    tex.append("\\midrule")
    
    # Diagnostics
    tex.append("Step Shifts ($D_{T_b}^{\\text{step}}$) & " + " & ".join(subset['Break_Mode'].tolist()) + " \\\\")
    tex.append(row_fmt("$C_{\\text{Shin}}$ [$H_0$: coint.]", 'Shin_LM', star_col='Shin_Stars'))
    tex.append(row_fmt("$S_{\\text{Type 2}}$ [$H_0$: coint.]", 'VW_Type2', star_col='VW_Stars'))
    tex.append(row_fmt("$t_{\\text{ADF}}$ [$H_0$: no coint.]", 't_ADF', star_col='ADF_Stars'))
    
    b_vals = []
    for _, r in subset.iterrows():
        b_vals.append(f"{r['Bandwidth_b']:.3f}" if pd.notna(r['Bandwidth_b']) else "")
    tex.append("Bandwidth ratio $b$ & " + " & ".join(b_vals) + " \\\\")
    
    t_vals = [str(int(x)) if pd.notna(x) else "" for x in subset['Sample_T']]
    tex.append("Sample Size $T$ & " + " & ".join(t_vals) + " \\\\")
    
    tex.append("\\bottomrule")
    tex.append("\\end{tabular}")
    tex.append("\\begin{minipage}{\\textwidth}")
    tex.append("\\scriptsize")
    tex.append("\\textit{Notes:} Dependent variable: $y_t^{\\text{NFC}}$ (log real capacity). Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS \\citep{VogelsangWagner2024}. Step Shifts \"No\": no structural break dummies; \"Yes\": Bai-Perron step dummies included. All interaction terms are FWL-orthogonalized against base capital regressors and step dummies. Significance: $^*p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. Stars for coefficient rows and cointegration tests are derived from a 100,000-pass Monte Carlo simulation suite mapping the exact DGP variant and fixed-$b$ Wald tables. Standard errors in parentheses.")
    tex.append("\\end{minipage}")
    tex.append("\\end{table}")
    
    with open(os.path.join(out_dir, "tab_specB_set2_nva_main.tex"), "w") as f:
        f.write("\n".join(tex) + "\n")

# Appendix Tables
def generate_appendix_table(set_name, basis_name):
    subset = df[(df['Spec_Set'] == set_name) & (df['Basis'] == basis_name)].copy()
    
    if subset.empty: return
    
    # All 6 wage permutations
    subset['Wage_Order'] = subset['Wage_Base'].apply(lambda x: wage_labels_ordered.index(x) if x in wage_labels_ordered else 99)
    subset['Break_Order'] = subset['Break_Mode'].apply(lambda x: 0 if x == 'No' else 1)
    subset = subset.sort_values(['Wage_Order', 'Break_Order'])
    
    tex = []
    tex.append("\\FloatBarrier")
    tex.append("\\begin{table}[h!]")
    tex.append("\\centering")
    
    set_num = "1" if set_name == "Set_1" else "2"
    interaction_type = "Standard Wage Interaction" if set_num == "1" else "Effective Wage Interaction"
    tex.append(f"\\caption{{\\textbf{{Specification B, Set {set_num}: {interaction_type} ({basis_name} Basis)}}}}")
    tex.append(f"\\label{{tab:specB_set{set_num}_{basis_name.lower()}_app}}")
    tex.append("\\tiny")
    tex.append("\\setlength{\\tabcolsep}{1.5pt}")
    tex.append("\\begin{tabular}{p{3.2cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}p{1.0cm}}")
    tex.append("\\toprule")
    
    models = subset['Model_ID'].tolist()
    tex.append("Model & " + " & ".join(models) + " \\\\")
    tex.append("\\midrule")
    
    def row_fmt(title, est_col, sd_col=None, star_col=None, is_coef=False):
        vals = []
        for _, r in subset.iterrows():
            est = f"{r[est_col]:.2f}" if pd.notna(r[est_col]) else ""
            if is_coef and sd_col and pd.notna(r[est_col]) and pd.notna(r[sd_col]):
                stars = get_coef_stars(r[est_col], r[sd_col])
                if stars:
                    est += f"${stars}$"
            elif star_col and pd.notna(r[star_col]):
                est += r[star_col]
            vals.append(est)
        return title + " & " + " & ".join(vals) + " \\\\"
        
    def sd_fmt(sd_col):
        vals = []
        for _, r in subset.iterrows():
            sd = f"({r[sd_col]:.2f})" if pd.notna(r[sd_col]) else ""
            vals.append(sd)
        return " & " + " & ".join(vals) + " \\\\"
    
    # Parameters
    tex.append(row_fmt("$\\hat{\\alpha}$ (Intercept)", 'Alpha_Est', sd_col='Alpha_SD', is_coef=True))
    tex.append(sd_fmt('Alpha_SD'))
    tex.append(row_fmt("$\\hat{\\theta}_{\\text{NRC}}$", 'Theta_kn_Est', sd_col='Theta_kn_SD', is_coef=True))
    tex.append(sd_fmt('Theta_kn_SD'))
    tex.append(row_fmt("$\\hat{\\theta}_{\\kappa}$", 'Theta_kp_Est', sd_col='Theta_kp_SD', is_coef=True))
    tex.append(sd_fmt('Theta_kp_SD'))
    tex.append(row_fmt("$\\hat{\\theta}_{\\omega\\kappa}$", 'Theta_iw_Est', sd_col='Theta_iw_SD', is_coef=True))
    tex.append(sd_fmt('Theta_iw_SD'))
    tex.append(row_fmt("$\\hat{\\theta}_{\\kappa p}$", 'Theta_ip_Est', sd_col='Theta_ip_SD', is_coef=True))
    tex.append(sd_fmt('Theta_ip_SD'))
    
    tex.append("\\midrule")
    
    tex.append("Step shifts & " + " & ".join(subset['Break_Mode'].tolist()) + " \\\\")
    tex.append(row_fmt("$C_{\\text{Shin}}$ [$H_0$: coint.]", 'Shin_LM', star_col='Shin_Stars'))
    tex.append(row_fmt("$S_{\\text{Type 2}}$ [$H_0$: coint.]", 'VW_Type2', star_col='VW_Stars'))
    tex.append(row_fmt("$t_{\\text{ADF}}$ [$H_0$: no coint.]", 't_ADF', star_col='ADF_Stars'))
    
    b_vals = []
    for _, r in subset.iterrows():
        b_vals.append(f"{r['Bandwidth_b']:.3f}" if pd.notna(r['Bandwidth_b']) else "")
    tex.append("Bandwidth ratio $b$ & " + " & ".join(b_vals) + " \\\\")
    
    t_vals = [str(int(x)) if pd.notna(x) else "" for x in subset['Sample_T']]
    tex.append("Sample Size $T$ & " + " & ".join(t_vals) + " \\\\")
    
    tex.append("\\bottomrule")
    tex.append("\\end{tabular}")
    tex.append("\\begin{minipage}{\\textwidth}")
    tex.append("\\scriptsize")
    tex.append("\\textit{Notes:} Dependent variable: $y_t^{\\text{NFC}}$ (log real capacity). Estimated via CMPR IM-OLS \\citep{VogelsangWagner2024}. All interaction terms are FWL-orthogonalized against base capital regressors and step dummies. Significance: $^*p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. Stars for coefficient rows and cointegration tests are derived from a 100,000-pass Monte Carlo simulation suite mapping the exact DGP variant and fixed-$b$ Wald tables. Standard errors in parentheses.")
    tex.append("\\end{minipage}")
    tex.append("\\end{table}")
    
    out_file = f"tab_specB_set{set_num}_{basis_name.lower()}_app.tex"
    with open(os.path.join(out_dir, out_file), "w") as f:
        f.write("\n".join(tex) + "\n")

if __name__ == "__main__":
    generate_main_table()
    for s in ["Set_1", "Set_2"]:
        for b in ["GVA", "NVA"]:
            generate_appendix_table(s, b)
    print("Exported Spec B tables successfully!")
