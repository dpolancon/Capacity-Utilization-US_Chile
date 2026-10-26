import pandas as pd
import numpy as np

df = pd.read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S61_SECTION32_IMOLS/csv/s61_section32_results.csv")

try:
    cv_df_94 = pd.read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_T94_N100000.csv")
    cv_df_77 = pd.read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_T77_N100000.csv")
except FileNotFoundError:
    print("Warning: CV tables not found. Please ensure MC simulations have completed.")
    cv_df_94 = pd.DataFrame()
    cv_df_77 = pd.DataFrame()

# Convert cv_dfs to a dict for easy lookup
cv_dict = {}
if not cv_df_94.empty:
    for idx, row in cv_df_94.iterrows():
        cv_dict[(94, row['Variant'])] = row.to_dict()
if not cv_df_77.empty:
    for idx, row in cv_df_77.iterrows():
        cv_dict[(77, row['Variant'])] = row.to_dict()

def fmt(val, decimals=2, is_stat=False):
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

def get_stars(t_val, variant_key, param_type, t_obs):
    key = (t_obs, variant_key)
    if key not in cv_dict:
        return ""
    cvs = cv_dict[key]
    
    if param_type == "kappa":
        p90 = cvs["t_kappa_p90"]
        p95 = cvs["t_kappa_p95"]
        p99 = cvs["t_kappa_p99"]
    elif param_type == "ortho1":
        p90 = cvs["t_ortho1_p90"]
        p95 = cvs["t_ortho1_p95"]
        p99 = cvs["t_ortho1_p99"]
    elif param_type == "ortho2":
        p90 = cvs["t_ortho2_p90"]
        p95 = cvs["t_ortho2_p95"]
        p99 = cvs["t_ortho2_p99"]
    elif param_type == "ct_im":
        p90 = cvs["CT_IM_p90"]
        p95 = cvs["CT_IM_p95"]
        p99 = cvs["CT_IM_p99"]
    else:
        # Fallback to standard normal for intercept
        if t_val >= 2.576: return "$^{***}$"
        elif t_val >= 1.96: return "$^{**}$"
        elif t_val >= 1.645: return "$^{*}$"
        return ""
        
    if t_val >= p99: return "$^{***}$"
    elif t_val >= p95: return "$^{**}$"
    elif t_val >= p90: return "$^{*}$"
    return ""

def generate_set_table(df_set, caption_text, label_text, out_tex_path, set_id):
    models = list(df_set['Model_ID'].unique())
    n_cols = len(models)
    
    with open(out_tex_path, "w", encoding="utf-8") as f:
        f.write("\\begin{table}[H]\n")
        f.write("\\centering\n")
        f.write("\\setlength{\\tabcolsep}{1.5pt}\n")
        f.write(f"\\caption{{{caption_text}}}\n")
        f.write(f"\\label{{{label_text}}}\n")
        f.write("\\tiny\n")
        
        col_spec = "p{3.5cm}" + "p{1.0cm}" * n_cols
        f.write(f"\\begin{{tabular}}{{{col_spec}}}\n")
        f.write("\\toprule\n")
        f.write(f"\\multicolumn{{{n_cols + 1}}}{{l}}{{\\textbf{{Dependent Variable: $y_t^{{\\text{{NFC}}}}$ (Log NFC Real GVA)}}}} \\\\\n")
        f.write("\\midrule\n")
        
        # Header row
        f.write("Model & " + " & ".join(models) + " \\\\\n")
        f.write("\\midrule\n")
        
        # Helper for param row (Estimate, SE, Stars)
        def write_param_rows(label, est_col, sd_col, param_type):
            row_est = [label]
            row_sd  = [""]
            for m in models:
                sub = df_set[df_set['Model_ID'] == m]
                if len(sub) > 0 and not pd.isna(sub[est_col].values[0]):
                    est = float(sub[est_col].values[0])
                    sd  = float(sub[sd_col].values[0])
                    break_mode = sub['Break_Mode'].values[0]
                    
                    # Determine variant key
                    set_suffix = "1" if set_id == "Set_1" else "2"
                    v_key = f"set{set_suffix}"
                    if break_mode == "Yes":
                        v_key += "_break"
                    
                    # Calculate t-stat
                    t_val = abs(est / sd) if sd > 0 else 0
                    t_obs = int(sub['Sample_T'].values[0]) if 'Sample_T' in sub.columns else 94
                    stars = get_stars(t_val, v_key, param_type, t_obs)
                    
                    row_est.append(f"{est:.2f}{stars}")
                    row_sd.append(f"({sd:.2f})")
                else:
                    row_est.append("---")
                    row_sd.append("")
            f.write(" & ".join(row_est) + " \\\\\n")
            if any(r != "" for r in row_sd[1:]):
                f.write(" & ".join(row_sd) + " \\\\\n")

        # 1. Intercept
        write_param_rows("$\\hat{\\alpha}$ (Intercept)", "Alpha_Est", "Alpha_SD", "intercept")
        
        # 2. Theta_kn (Non-Residential Structures)
        write_param_rows("$\\hat{\\theta}_{NRC}$ (Structures $k^{\\text{NRC}}$)", "Theta_kn_Est", "Theta_kn_SD", "kappa")
        
        # 3. Theta_kp (Mechanization Gap)
        write_param_rows("$\\hat{\\theta}_{\\kappa}$ (Mech. Gap $\\kappa$)", "Theta_kp_Est", "Theta_kp_SD", "kappa")
        
        # 4. Wage Interaction
        write_param_rows("$\\hat{\\theta}_{\\omega\\kappa}$ (FWL Wage Interact)", "Theta_iw_Est", "Theta_iw_SD", "ortho1")
        
        # 5. Price Interaction
        write_param_rows("$\\hat{\\theta}_{\\kappa p}$ (FWL Price Interact)", "Theta_ip_Est", "Theta_ip_SD", "ortho2")
        
        # 6. Step Shifts
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
            
        write_vif_row("VIF ($k^{\\text{NRC}}$)", "VIF_kn")
        write_vif_row("VIF ($\\kappa$)", "VIF_kp")
        write_vif_row("VIF (Wage Interaction)", "VIF_iw")
        write_vif_row("VIF (Price Interaction)", "VIF_ip")
        
        f.write("\\midrule\n")
        f.write("\\multicolumn{" + str(n_cols + 1) + "}{l}{\\textbf{Cointegration Test Triad}} \\\\\n")
        
        # ADF
        row_adf = ["Resid. ADF ($t_{\\text{ADF}}$) [$H_0$: No Coint.]"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            if len(sub) > 0:
                val = fmt(sub['t_ADF'].values[0], 2)
                stars = str(sub['ADF_Stars'].values[0]) if not pd.isna(sub['ADF_Stars'].values[0]) else ""
                row_adf.append(f"{val}{stars}")
            else: row_adf.append("---")
        f.write(" & ".join(row_adf) + " \\\\\n")
        
        # Shin LM
        row_shin = ["Shin LM ($C_{\\text{Shin}}$) [$H_0$: Coint.]"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            if len(sub) > 0:
                val = float(sub['Shin_LM'].values[0])
                break_mode = sub['Break_Mode'].values[0]
                
                # Determine variant key
                set_suffix = "1" if set_id == "Set_1" else "2"
                v_key = f"set{set_suffix}"
                if break_mode == "Yes":
                    v_key += "_break"
                
                t_obs = int(sub['Sample_T'].values[0]) if 'Sample_T' in sub.columns else 94
                stars = get_stars(val, v_key, "ct_im", t_obs)
                row_shin.append(f"{val:.2f}{stars}")
            else: row_shin.append("---")
        f.write(" & ".join(row_shin) + " \\\\\n")

        # VW Type 2
        row_vw = ["VW Type 2 ($S_{\\text{Type 2}}$) [$H_0$: Coint.]"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            if len(sub) > 0:
                val = fmt(sub['VW_Type2'].values[0], 2)
                stars = str(sub['VW_Stars'].values[0]) if not pd.isna(sub['VW_Stars'].values[0]) else ""
                row_vw.append(f"{val}{stars}")
            else: row_vw.append("---")
        f.write(" & ".join(row_vw) + " \\\\\n")

        f.write("\\midrule\n")
        
        # Bandwidth b
        row_b = ["Bandwidth Ratio ($b$)"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            row_b.append(fmt(sub['Bandwidth_b'].values[0], 4) if len(sub) > 0 else "---")
        f.write(" & ".join(row_b) + " \\\\\n")
        
        # Sample T
        row_t = ["Sample Size ($T$)"]
        for m in models:
            sub = df_set[df_set['Model_ID'] == m]
            row_t.append(str(int(sub['Sample_T'].values[0])) if len(sub) > 0 else "---")
        f.write(" & ".join(row_t) + " \\\\\n")
        
        f.write("\\bottomrule\n")
        f.write("\\multicolumn{" + str(n_cols + 1) + "}{p{15cm}}{\\footnotesize Note: Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS (Vogelsang et al. 2024) over 1929--2024. Standard errors in parentheses. Significance: $^* p < 0.10, ^{**} p < 0.05, ^{***} p < 0.01$. Stars for coefficient rows (structures, mechanization gap, and interactions) and the Residual VW Type 2 cointegration test are derived from a 100,000-pass custom Monte Carlo simulation suite mapping the exact DGP variant (with/without step level-shifts). All interaction terms are FWL-orthogonalized against base capital regressors and step dummies.}\n")
        f.write("\\end{tabular}\n")
        f.write("\\end{table}\n")

# Generate 4 separate tables splitting Set 1 and Set 2 into GVA and NVA basis

# Set 1 GVA
df_set1_gva = df[(df['Spec_Set'] == 'Set_1') & (df['Wage_Label'].str.contains('GVA'))]
generate_set_table(df_set1_gva, "Specification Set 1: Standard Wage Interaction (GVA Basis)", "tab:specB_set1_gva", "C:/ReposGitHub/Capacity-Utilization-US_Chile/reports/US_Section32_IMOLS_Results/table_specB_set1_gva.tex", "Set_1")

# Set 1 NVA
df_set1_nva = df[(df['Spec_Set'] == 'Set_1') & (df['Wage_Label'].str.contains('NVA'))]
generate_set_table(df_set1_nva, "Specification Set 1: Standard Wage Interaction (NVA Basis)", "tab:specB_set1_nva", "C:/ReposGitHub/Capacity-Utilization-US_Chile/reports/US_Section32_IMOLS_Results/table_specB_set1_nva.tex", "Set_1")

# Set 2 GVA
df_set2_gva = df[(df['Spec_Set'] == 'Set_2') & (df['Wage_Label'].str.contains('GVA'))]
generate_set_table(df_set2_gva, "Specification Set 2: Effective Wage Interaction (GVA Basis)", "tab:specB_set2_gva", "C:/ReposGitHub/Capacity-Utilization-US_Chile/reports/US_Section32_IMOLS_Results/table_specB_set2_gva.tex", "Set_2")

# Set 2 NVA
df_set2_nva = df[(df['Spec_Set'] == 'Set_2') & (df['Wage_Label'].str.contains('NVA'))]
generate_set_table(df_set2_nva, "Specification Set 2: Effective Wage Interaction (NVA Basis)", "tab:specB_set2_nva", "C:/ReposGitHub/Capacity-Utilization-US_Chile/reports/US_Section32_IMOLS_Results/table_specB_set2_nva.tex", "Set_2")

print("Generated table_specB_set1_gva.tex, table_specB_set1_nva.tex, table_specB_set2_gva.tex, and table_specB_set2_nva.tex cleanly.")


def generate_cv_appendix_table():
    out_tex = "C:/ReposGitHub/Capacity-Utilization-US_Chile/reports/US_Section32_IMOLS_Results/table_cmpr_s32_critical_values.tex"
    
    try:
        cv_94 = pd.read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_T94_N100000.csv")
        cv_77 = pd.read_csv("C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_T77_N100000.csv")
    except:
        return
        
    with open(out_tex, "w", encoding="utf-8") as f:
        f.write("\\begin{table}[H]\n")
        f.write("\\centering\n")
        f.write("\\begin{threeparttable}\n")
        f.write("\\caption{Non-Standard CMPR IM-OLS Critical Values (100,000 Replications)}\n")
        f.write("\\label{tab:s32_cvs}\n")
        f.write("\\scriptsize\n")
        f.write("\\begin{tabular}{l | ccc | ccc}\n")
        f.write("\\toprule\n")
        f.write(" & \\multicolumn{3}{c|}{$\\boldsymbol{T=94}$ \\textbf{(1931--2024)}} & \\multicolumn{3}{c}{$\\boldsymbol{T=77}$ \\textbf{(1948--2024)}} \\\\\n")
        f.write("\\cmidrule(lr){2-4} \\cmidrule(lr){5-7}\n")
        f.write("\\textbf{Parameter/Test} & 90\\% & 95\\% & 99\\% & 90\\% & 95\\% & 99\\% \\\\\n")
        f.write("\\midrule\n")
        
        # Helper to format row
        def w_row(label, col90, col95, col99, variant_idx=0):
            r94 = cv_94.iloc[variant_idx]
            r77 = cv_77.iloc[variant_idx]
            v94_90, v94_95, v94_99 = r94[col90], r94[col95], r94[col99]
            v77_90, v77_95, v77_99 = r77[col90], r77[col95], r77[col99]
            f.write(f"{label} & {v94_90:.3f} & {v94_95:.3f} & {v94_99:.3f} & {v77_90:.3f} & {v77_95:.3f} & {v77_99:.3f} \\\\\n")
        
        f.write("\\multicolumn{7}{l}{\\textbf{Panel A: Standard Wage Proxy Models (Set 1, No Break)}} \\\\\n")
        w_row("$CT_{\\text{IM}}$ (Global Coint. Test)", "CT_IM_p90", "CT_IM_p95", "CT_IM_p99", 0)
        w_row("$t_{\\kappa}$ (Composition)", "t_kappa_p90", "t_kappa_p95", "t_kappa_p99", 0)
        w_row("$t_{\\theta_{\\omega\\kappa}}$ (Wage Interaction)", "t_ortho1_p90", "t_ortho1_p95", "t_ortho1_p99", 0)
        w_row("$t_{\\theta_{\\kappa p}}$ (Price Interaction)", "t_ortho2_p90", "t_ortho2_p95", "t_ortho2_p99", 0)
        
        f.write("\\midrule\n")
        f.write("\\multicolumn{7}{l}{\\textbf{Panel B: Effective Wage Proxy Models (Set 2, No Break)}} \\\\\n")
        w_row("$CT_{\\text{IM}}$ (Global Coint. Test)", "CT_IM_p90", "CT_IM_p95", "CT_IM_p99", 2)
        w_row("$t_{\\kappa}$ (Composition)", "t_kappa_p90", "t_kappa_p95", "t_kappa_p99", 2)
        w_row("$t_{\\theta_{\\omega\\kappa}}$ (Effective Wage Int.)", "t_ortho1_p90", "t_ortho1_p95", "t_ortho1_p99", 2)
        w_row("$t_{\\theta_{\\kappa p}}$ (Price Interaction)", "t_ortho2_p90", "t_ortho2_p95", "t_ortho2_p99", 2)
        
        f.write("\\midrule\n")
        f.write("\\multicolumn{7}{l}{\\textbf{Panel C: Asymptotic Normal Benchmarks}} \\\\\n")
        f.write("Standard Normal $Z$ & 1.645 & 1.960 & 2.576 & 1.645 & 1.960 & 2.576 \\\\\n")
        f.write("\\bottomrule\n")
        f.write("\\end{tabular}\n")
        f.write("\\begin{tablenotes}\n")
        f.write("\\item \\textit{Note:} Critical values derived via custom $N=100,000$ pass Monte Carlo simulation matched exactly to the integration geometry of the regressors ($H_0$: $y^*_t \\sim I(0)$). Fixed-$b$ inference utilizes Andrews automatic bandwidth selection ($b = M/T$) and the Bartlett kernel. Random number generator uses Mersenne Twister with \\texttt{set.seed(1929)}.\n")
        f.write("\\end{tablenotes}\n")
        f.write("\\end{threeparttable}\n")
        f.write("\\end{table}\n")

generate_cv_appendix_table()
