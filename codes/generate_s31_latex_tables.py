import pandas as pd
import numpy as np
import os

results_path = "C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S50_SECTION31_IMOLS/csv/s50_section31_results.csv"
cv_path_94 = "C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_T94_N100000.csv"
cv_path_77 = "C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_T77_N100000.csv"
out_dir = "C:/ReposGitHub/Capacity-Utilization-US_Chile/reports/US_Section31_IMOLS_Results"

os.makedirs(out_dir, exist_ok=True)

df = pd.read_csv(results_path)
cv_df_94 = pd.read_csv(cv_path_94)
cv_df_77 = pd.read_csv(cv_path_77)

cv_dict = {}
for idx, row in cv_df_94.iterrows():
    cv_dict[f"T94_{row['Variant']}"] = row.to_dict()
for idx, row in cv_df_77.iterrows():
    cv_dict[f"T77_{row['Variant']}"] = row.to_dict()


def fmt(val, decimals=2):
    if pd.isna(val) or val is None or str(val).strip() == "" or str(val).lower() == "nan":
        return "---"
    try:
        fval = float(val)
        if decimals == 2:
            return f"{fval:.2f}"
        elif decimals == 3:
            return f"{fval:.3f}"
        elif decimals == 4:
            return f"{fval:.4f}"
        return f"{fval:.2f}"
    except:
        return str(val)

def get_stars(t_val, variant_key, t_obs, param_type):
    key = f"T{t_obs}_{variant_key}"
    if key not in cv_dict:
        return ""
    cvs = cv_dict[key]
    
    if param_type == "k0":
        p90 = cvs["t_k0_p90"]
        p95 = cvs["t_k0_p95"]
        p99 = cvs["t_k0_p99"]
    elif param_type == "inter":
        p90 = cvs["t_inter_p90"]
        p95 = cvs["t_inter_p95"]
        p99 = cvs["t_inter_p99"]
    elif param_type == "ct_im":
        p90 = cvs["CT_IM_p90"]
        p95 = cvs["CT_IM_p95"]
        p99 = cvs["CT_IM_p99"]
    else:
        # Intercept fallback
        if t_val >= 2.576: return "$^{***}$"
        elif t_val >= 1.96: return "$^{**}$"
        elif t_val >= 1.645: return "$^{*}$"
        return ""
        
    if t_val >= p99: return "$^{***}$"
    elif t_val >= p95: return "$^{**}$"
    elif t_val >= p90: return "$^{*}$"
    return ""

def generate_section31_panel_table(df_set, caption_text, label_text, out_tex_path, set_id):
    models = list(df_set['Model_ID'].unique())
    n_cols = len(models)
    
    with open(out_tex_path, "w", encoding="utf-8") as f:
        f.write("\\begin{table}[H]\n")
        f.write("\\centering\n")
        f.write("\\setlength{\\tabcolsep}{2.5pt}\n")
        f.write(f"\\caption{{{caption_text}}}\n")
        f.write(f"\\label{{{label_text}}}\n")
        f.write("\\scriptsize\n")
        
        col_spec = "p{3.8cm}" + "p{1.1cm}" * n_cols
        f.write(f"\\begin{{tabular}}{{{col_spec}}}\n")
        f.write("\\toprule\n")
        f.write(f"\\multicolumn{{{n_cols + 1}}}{{l}}{{\\textbf{{Dependent Variable: $y_t^{{\\text{{NFC}}}}$ (Log NFC Real NVA)}}}} \\\\\n")
        f.write("\\midrule\n")
        
        # Header row
        f.write("Model & " + " & ".join(models) + " \\\\\n")
        f.write("\\midrule\n")
        
        # Parameter helper
        def write_param_rows(label, est_col, sd_col, param_type):
            row_est = [label]
            row_sd  = [""]
            for m in models:
                sub = df_set[df_set['Model_ID'] == m]
                if len(sub) > 0 and not pd.isna(sub[est_col].values[0]):
                    est = float(sub[est_col].values[0])
                    sd  = float(sub[sd_col].values[0])
                    break_mode = sub['Break_Mode'].values[0]
                    
                    set_prefix = "spec1" if set_id == "Set_1" else "spec2"
                    v_key = set_prefix
                    if break_mode == "Yes":
                        v_key += "_break"
                    
                    t_obs = int(sub['T_obs'].values[0]) if 'T_obs' in sub else 94
                    t_val = abs(est / sd) if sd > 0 else 0
                    stars = get_stars(t_val, v_key, t_obs, param_type)
                    
                    row_est.append(f"{est:.2f}{stars}")
                    row_sd.append(f"({sd:.2f})")
                else:
                    row_est.append("---")
                    row_sd.append("")
            f.write(" & ".join(row_est) + " \\\\\n")
            if any(r != "" for r in row_sd[1:]):
                f.write(" & ".join(row_sd) + " \\\\\n")

        # 1. Intercept
        write_param_rows("$\\hat{\\alpha}$ (Intercept)", "alpha", "alpha_sd", "intercept")
        
        # 2. Capital Elasticity
        write_param_rows("$\\hat{\\beta}$ (Private Core $k_{\\text{cap}}$)", "theta_0", "theta_0_sd", "k0")
        
        # 3. Interaction Elasticity
        write_param_rows("$\\hat{\\theta}_1$ (FWL Interaction)", "theta_1", "theta_1_sd", "inter")
        
        # 4. Step Shifts
        row_step = ["Step Shifts ($D_{T_b}^{\\text{step}}$)"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            row_step.append(sub['Break_Mode'].values[0] if len(sub) > 0 else "No")
        f.write(" & ".join(row_step) + " \\\\\n")
        
        f.write("\\midrule\n")
        f.write("\\multicolumn{" + str(n_cols + 1) + "}{l}{\\textbf{Collinearity Diagnostics (VIF)}} \\\\\n")
        
        # VIF Rows
        def write_vif_row(label, vif_col):
            row_vif = [label]
            for m in models:
                sub = df_set[df_set['Model_ID'] == m]
                if len(sub) > 0 and not pd.isna(sub[vif_col].values[0]):
                    row_vif.append(fmt(sub[vif_col].values[0], 2))
                else:
                    row_vif.append("---")
            f.write(" & ".join(row_vif) + " \\\\\n")
            
        write_vif_row("VIF ($k_{\\text{cap}}$)", "VIF_k")
        write_vif_row("VIF (Interaction)", "VIF_inter")
        
        f.write("\\midrule\n")
        f.write("\\multicolumn{" + str(n_cols + 1) + "}{l}{\\textbf{Cointegration Test Triad}} \\\\\n")
        
        # ADF
        row_adf = ["Resid. ADF ($t_{\\text{ADF}}$) [$H_0$: No Coint.]"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            if len(sub) > 0:
                val = fmt(sub['EG_ADF_stat'].values[0], 2)
                stars = str(sub['EG_ADF_stars'].values[0]) if not pd.isna(sub['EG_ADF_stars'].values[0]) else ""
                row_adf.append(f"{val}{stars}")
            else: row_adf.append("---")
        f.write(" & ".join(row_adf) + " \\\\\n")
        
        # Shin LM
        row_shin = ["Shin LM ($C_{\\text{Shin}}$) [$H_0$: Coint.]"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            if len(sub) > 0:
                val = float(sub['Shin_stat'].values[0])
                break_mode = sub['Break_Mode'].values[0]
                
                set_prefix = "spec1" if set_id == "Set_1" else "spec2"
                v_key = set_prefix
                if break_mode == "Yes":
                    v_key += "_break"
                
                t_obs = int(sub['T_obs'].values[0]) if 'T_obs' in sub else 94
                stars = get_stars(val, v_key, t_obs, "ct_im")
                row_shin.append(f"{val:.2f}{stars}")
            else: row_shin.append("---")
        f.write(" & ".join(row_shin) + " \\\\\n")

        # VW Type 2
        row_vw = ["VW Type 2 ($CT_{\\text{IM}}$) [$H_0$: No Coint.]"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            if len(sub) > 0:
                val = fmt(sub['VW_stat'].values[0], 2)
                
                break_mode = sub['Break_Mode'].values[0]
                set_prefix = "spec1" if set_id == "Set_1" else "spec2"
                v_key = set_prefix
                if break_mode == "Yes": v_key += "_break"
                t_obs = int(sub['T_obs'].values[0]) if 'T_obs' in sub else 94
                
                stars = get_stars(float(sub['VW_stat'].values[0]), v_key, t_obs, "ct_im") if not pd.isna(sub['VW_stat'].values[0]) else ""
                row_vw.append(f"{val}{stars}")
            else: row_vw.append("---")
        f.write(" & ".join(row_vw) + " \\\\\n")

        f.write("\\midrule\n")
        
        # Bandwidth b
        row_b = ["Bandwidth Ratio ($b$)"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            row_b.append(fmt(sub['B_Hat'].values[0], 4) if len(sub) > 0 else "---")
        f.write(" & ".join(row_b) + " \\\\\n")
        
        # Sample T
        row_t = ["Sample Size ($T$)"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            row_t.append(str(int(sub['T_obs'].values[0])) if len(sub) > 0 else "---")
        f.write(" & ".join(row_t) + " \\\\\n")
        
        f.write("\\bottomrule\n")
        f.write("\\multicolumn{" + str(n_cols + 1) + "}{p{14.5cm}}{\\footnotesize Note: Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS (Vogelsang et al. 2024) over 1929--2024 ($T=94$). Standard errors in parentheses. Significance: $^* p < 0.10, ^{**} p < 0.05, ^{***} p < 0.01$. Stars for coefficient rows (capital elasticity and interaction) and the Residual VW Type 2 test are derived from a 100,000-pass custom Monte Carlo simulation suite mapping the exact DGP variant. All interaction terms are FWL-orthogonalized against base capital regressors and step dummies.}\n")
        f.write("\\end{tabular}\n")
        f.write("\\end{table}\n")

# Generate 4 panel tables
# Set 1 GVA (M1.1a - M1.4b)
df_s1_gva = df[(df['Spec_Set'] == 'Set_1') & (df['Wage_Label'].str.contains('GVA'))]
generate_section31_panel_table(df_s1_gva, "Specification Set 1: Standard Wage Interaction (GVA Basis)", "tab:specA_set1_gva", os.path.join(out_dir, "table_specA_set1_gva.tex"), "Set_1")

# Set 1 NVA (M1.5a - M1.8b)
df_s1_nva = df[(df['Spec_Set'] == 'Set_1') & (df['Wage_Label'].str.contains('NVA'))]
generate_section31_panel_table(df_s1_nva, "Specification Set 1: Standard Wage Interaction (NVA Basis)", "tab:specA_set1_nva", os.path.join(out_dir, "table_specA_set1_nva.tex"), "Set_1")

# Set 2 GVA (M2.1a - M2.4b)
df_s2_gva = df[(df['Spec_Set'] == 'Set_2') & (df['Wage_Label'].str.contains('GVA'))]
generate_section31_panel_table(df_s2_gva, "Specification Set 2: Effective Wage Interaction (GVA Basis)", "tab:specA_set2_gva", os.path.join(out_dir, "table_specA_set2_gva.tex"), "Set_2")

# Set 2 NVA (M2.5a - M2.8b)
df_s2_nva = df[(df['Spec_Set'] == 'Set_2') & (df['Wage_Label'].str.contains('NVA'))]
generate_section31_panel_table(df_s2_nva, "Specification Set 2: Effective Wage Interaction (NVA Basis)", "tab:specA_set2_nva", os.path.join(out_dir, "table_specA_set2_nva.tex"), "Set_2")

print("Generated Section 3.1 panel tables cleanly: table_specA_set1_gva.tex, table_specA_set1_nva.tex, table_specA_set2_gva.tex, table_specA_set2_nva.tex.")
