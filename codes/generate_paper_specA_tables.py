import pandas as pd
import numpy as np
import os

results_path = "C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S50_SECTION31_IMOLS/csv/s50_section31_results.csv"
cv_path_94 = "C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_T94_N100000.csv"
cv_path_77 = "C:/ReposGitHub/Capacity-Utilization-US_Chile/output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_T77_N100000.csv"
out_dir = "C:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_paper/paper_tex_tables"

os.makedirs(out_dir, exist_ok=True)

df = pd.read_csv(results_path)
cv_df_94 = pd.read_csv(cv_path_94)
cv_df_77 = pd.read_csv(cv_path_77)

cv_dict = {}
for idx, row in cv_df_94.iterrows():
    cv_dict[f"T94_{row['Variant']}"] = row.to_dict()
for idx, row in cv_df_77.iterrows():
    cv_dict[f"T77_{row['Variant']}"] = row.to_dict()

# Fixed-b Wald critical values for k=2 stochastic regressors (Vogelsang & Wagner 2014 Table 5)
b_grid = np.array([0.02, 0.04, 0.06, 0.08, 0.10, 0.12, 0.14, 0.16, 0.18, 0.20,
                   0.22, 0.24, 0.26, 0.28, 0.30, 0.32, 0.34, 0.36, 0.38, 0.40,
                   0.42, 0.44, 0.46, 0.48, 0.50, 0.52, 0.54, 0.56, 0.58, 0.60,
                   0.62, 0.64, 0.66, 0.68, 0.70, 0.72, 0.74, 0.76, 0.78, 0.80,
                   0.82, 0.84, 0.86, 0.88, 0.90, 0.92, 0.94, 0.96, 0.98, 1.00])

vw_wald_k2_p90 = np.array([5.34, 6.90, 9.05, 11.76, 15.07, 18.79, 22.83, 26.80, 30.68, 34.24,
                           37.50, 40.20, 42.72, 45.31, 47.58, 50.24, 52.63, 55.19, 57.74, 60.17,
                           62.81, 65.22, 67.78, 70.24, 72.80, 75.15, 77.66, 80.16, 82.68, 84.80,
                           86.90, 89.08, 91.45, 93.49, 95.74, 97.82, 100.06, 102.47, 104.64, 106.82,
                           108.65, 110.76, 113.08, 114.91, 117.17, 119.26, 121.08, 123.32, 125.50, 127.47])

def get_vw_wald_stars(vw_stat, b_hat):
    if pd.isna(vw_stat) or pd.isna(b_hat): return ""
    b_clamped = min(max(b_hat, 0.02), 1.00)
    p90 = np.interp(b_clamped, b_grid, vw_wald_k2_p90)
    # H0 is Cointegration; rejection (rejection of cointegration) occurs if stat >= p90
    if vw_stat >= p90:
        return "$^{***}$"
    return ""

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
    elif param_type == "shin":
        # Shin LM test H0: cointegration. Small stat = fail to reject H0 (cointegrated).
        p90 = cvs["CT_IM_p90"]
        p95 = cvs["CT_IM_p95"]
        p99 = cvs["CT_IM_p99"]
        if t_val >= p99: return "$^{***}$"
        elif t_val >= p95: return "$^{**}$"
        elif t_val >= p90: return "$^{*}$"
        return ""
    else:
        if t_val >= 2.576: return "$^{***}$"
        elif t_val >= 1.96: return "$^{**}$"
        elif t_val >= 1.645: return "$^{*}$"
        return ""
        
    if t_val >= p99: return "$^{***}$"
    elif t_val >= p95: return "$^{**}$"
    elif t_val >= p90: return "$^{*}$"
    return ""

def generate_main_specA_set2_nva_table(df_all, out_path):
    target_models = ["M2.7a", "M2.7b", "M2.11a", "M2.11b", "M2.12a", "M2.12b", "M2.10a", "M2.10b"]
    sub_df = df_all[df_all['Model_ID'].isin(target_models)].copy()
    sub_df['sort_key'] = sub_df['Model_ID'].map(lambda x: target_models.index(x))
    sub_df = sub_df.sort_values('sort_key')
    
    n_cols = len(target_models)
    
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\\begin{table}[h!]\n")
        f.write("\\centering\n")
        f.write("\\caption{\\textbf{Specification A, Set 2: Effective Wage Interaction (NVA Basis)}}\n")
        f.write("\\label{tab:specA_set2_nva_main}\n")
        f.write("\\small\n")
        col_spec = "p{4.2cm}" + "p{1.2cm}" * n_cols
        f.write(f"\\begin{{tabular}}{{{col_spec}}}\n")
        f.write("\\toprule\n")
        f.write(" & \\multicolumn{2}{c}{NFC NVA Baseline} & \\multicolumn{2}{c}{Clean Corp Tier 1} & \\multicolumn{2}{c}{Clean Corp Tier 2} & \\multicolumn{2}{c}{ST Tier 2 NVA} \\\\\n")
        f.write("\\cmidrule(lr){2-3} \\cmidrule(lr){4-5} \\cmidrule(lr){6-7} \\cmidrule(lr){8-9}\n")
        f.write(" & (1) & (2) & (3) & (4) & (5) & (6) & (7) & (8) \\\\\n")
        f.write("\\midrule\n")
        
        # Intercept theta_0
        row_t0 = ["$\\hat{\\theta}_0$ (Capital Elasticity)"]
        row_t0_sd = [""]
        for m in target_models:
            row = sub_df[sub_df['Model_ID'] == m].iloc[0]
            est = float(row['theta_0'])
            sd = float(row['theta_0_sd'])
            t_obs = int(row['T_obs'])
            break_mode = row['Break_Mode']
            v_key = "spec2_break" if break_mode == "Yes" else "spec2"
            t_val = abs(est / sd) if sd > 0 else 0
            stars = get_stars(t_val, v_key, t_obs, "k0")
            row_t0.append(f"{est:.2f}{stars}")
            row_t0_sd.append(f"({sd:.2f})")
        f.write(" & ".join(row_t0) + " \\\\\n")
        f.write(" & ".join(row_t0_sd) + " \\\\\n")
        
        # Interaction theta_1
        row_t1 = ["$\\hat{\\theta}_1$ (Effective Wage Pressure)"]
        row_t1_sd = [""]
        for m in target_models:
            row = sub_df[sub_df['Model_ID'] == m].iloc[0]
            est = float(row['theta_1'])
            sd = float(row['theta_1_sd'])
            t_obs = int(row['T_obs'])
            break_mode = row['Break_Mode']
            v_key = "spec2_break" if break_mode == "Yes" else "spec2"
            t_val = abs(est / sd) if sd > 0 else 0
            stars = get_stars(t_val, v_key, t_obs, "inter")
            row_t1.append(f"{est:.2f}{stars}")
            row_t1_sd.append(f"({sd:.2f})")
        f.write(" & ".join(row_t1) + " \\\\\n")
        f.write(" & ".join(row_t1_sd) + " \\\\\n")
        
        f.write("\\midrule\n")
        
        # Step shifts
        row_step = ["Step Shifts ($D_{T_b}^{\\text{step}}$)"]
        for m in target_models:
            row = sub_df[sub_df['Model_ID'] == m].iloc[0]
            row_step.append(row['Break_Mode'])
        f.write(" & ".join(row_step) + " \\\\\n")
        
        # Shin LM
        row_shin = ["$C_{\\text{Shin}}$ [$H_0$: coint.]"]
        for m in target_models:
            row = sub_df[sub_df['Model_ID'] == m].iloc[0]
            val = float(row['Shin_stat'])
            t_obs = int(row['T_obs'])
            break_mode = row['Break_Mode']
            v_key = "spec2_break" if break_mode == "Yes" else "spec2"
            stars = get_stars(val, v_key, t_obs, "shin")
            row_shin.append(f"{val:.2f}{stars}")
        f.write(" & ".join(row_shin) + " \\\\\n")
        
        # VW Type 2 Wald
        row_vw = ["$S_{\\text{Type 2}}$ [$H_0$: coint.]"]
        for m in target_models:
            row = sub_df[sub_df['Model_ID'] == m].iloc[0]
            val = float(row['VW_stat'])
            b_hat = float(row['B_Hat'])
            stars = get_vw_wald_stars(val, b_hat)
            row_vw.append(f"{val:.2f}{stars}")
        f.write(" & ".join(row_vw) + " \\\\\n")
        
        # EG-ADF
        row_adf = ["$t_{\\text{ADF}}$ [$H_0$: no coint.]"]
        for m in target_models:
            row = sub_df[sub_df['Model_ID'] == m].iloc[0]
            val = float(row['EG_ADF_stat'])
            stars = str(row['EG_ADF_stars']) if not pd.isna(row['EG_ADF_stars']) else ""
            row_adf.append(f"{val:.2f}{stars}")
        f.write(" & ".join(row_adf) + " \\\\\n")
        
        # Bandwidth b
        row_b = ["Bandwidth ratio $b$"]
        for m in target_models:
            row = sub_df[sub_df['Model_ID'] == m].iloc[0]
            row_b.append(f"{float(row['B_Hat']):.3f}")
        f.write(" & ".join(row_b) + " \\\\\n")
        
        # Sample T
        row_t = ["Sample Size $T$"]
        for m in target_models:
            row = sub_df[sub_df['Model_ID'] == m].iloc[0]
            row_t.append(str(int(row['T_obs'])))
        f.write(" & ".join(row_t) + " \\\\\n")
        
        f.write("\\bottomrule\n")
        f.write("\\end{tabular}\n")
        f.write("\\begin{minipage}{\\textwidth}\n")
        f.write("\\scriptsize\n")
        f.write("\\textit{Notes:} Dependent variable: $y_t^{\\text{NFC}}$ (log NFC real GVA). Estimated via Cointegrating Multivariate Polynomial Regression (CMPR) IM-OLS \\citep{VogelsangWagner2014}. Step Shifts \"No\": no structural break dummies; \"Yes\": Bai-Perron step dummies included. All interaction terms are FWL-orthogonalized against base capital regressors and step dummies. The effective wage interaction is $\\omega_{t-1}(1-\\iota_{t-1}) \\times k_{\\text{cap},t}$, where $\\iota_{t-1}$ is the lagged IPP share of capital. Significance: $^*p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. Stars for coefficient rows and cointegration tests are derived from a 100,000-pass Monte Carlo simulation suite mapping the exact DGP variant and fixed-$b$ Wald tables. Standard errors in parentheses.\n")
        f.write("\\end{minipage}\n")
        f.write("\\end{table}\n")


def generate_appendix_specA_tables(df_all, out_path):
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\\FloatBarrier\n")
        f.write("\\section{Appendix D: Specification A --- Full Estimation Results}\n")
        f.write("\\label{app:specA_full_results}\n\n")
        f.write("This appendix reports the full empirical estimation matrix across all 48 specifications of the aggregate capital model (Specification A). ")
        f.write("The specifications span two interaction sets (Set 1: standard wage interaction; Set 2: effective wage interaction scaled by $(1-\\iota_{t-1})$), ")
        f.write("two value-added bases (Gross Value Added [GVA] and Net Value Added [NVA]), six wage share measures per basis ")
        f.write("(NFC Baseline, Corporate, Shaikh-Tonak Tier 1, Shaikh-Tonak Tier 2, Clean Corporate Tier 1, and Clean Corporate Tier 2), ")
        f.write("and two structural break modes (without step dummies; with Bai-Perron step shifts).\n\n")
        
        configs = [
            ("Set_1", "GVA", "Specification A, Set 1: Standard Wage Interaction (GVA Basis)", "tab:specA_set1_gva_app"),
            ("Set_1", "NVA", "Specification A, Set 1: Standard Wage Interaction (NVA Basis)", "tab:specA_set1_nva_app"),
            ("Set_2", "GVA", "Specification A, Set 2: Effective Wage Interaction (GVA Basis)", "tab:specA_set2_gva_app"),
            ("Set_2", "NVA", "Specification A, Set 2: Effective Wage Interaction (NVA Basis)", "tab:specA_set2_nva_app"),
        ]
        
        for set_id, basis, caption_text, label_text in configs:
            sub = df_all[(df_all['Spec_Set'] == set_id) & (df_all['Wage_Label'].str.contains(basis))].copy()
            models = list(sub['Model_ID'].unique())
            n_cols = len(models)
            
            f.write("\\FloatBarrier\n")
            f.write("\\begin{table}[h!]\n")
            f.write("\\centering\n")
            f.write(f"\\caption{{\\textbf{{{caption_text}}}}}\n")
            f.write(f"\\label{{{label_text}}}\n")
            f.write("\\tiny\n")
            f.write("\\setlength{\\tabcolsep}{1.5pt}\n")
            
            col_spec = "p{3.2cm}" + "p{1.0cm}" * n_cols
            f.write(f"\\begin{{tabular}}{{{col_spec}}}\n")
            f.write("\\toprule\n")
            f.write("Model & " + " & ".join(models) + " \\\\\n")
            f.write("\\midrule\n")
            
            # Param rows
            # 1. theta_0
            row_t0 = ["$\\hat{\\theta}_0$ (Capital)"]
            row_t0_sd = [""]
            for m in models:
                r = sub[sub['Model_ID'] == m].iloc[0]
                est = float(r['theta_0'])
                sd = float(r['theta_0_sd'])
                t_obs = int(r['T_obs'])
                break_mode = r['Break_Mode']
                v_key = ("spec1" if set_id=="Set_1" else "spec2") + ("_break" if break_mode=="Yes" else "")
                t_val = abs(est/sd) if sd > 0 else 0
                stars = get_stars(t_val, v_key, t_obs, "k0")
                row_t0.append(f"{est:.2f}{stars}")
                row_t0_sd.append(f"({sd:.2f})")
            f.write(" & ".join(row_t0) + " \\\\\n")
            f.write(" & ".join(row_t0_sd) + " \\\\\n")
            
            # 2. theta_1
            row_t1 = ["$\\hat{\\theta}_1$ (Interaction)"]
            row_t1_sd = [""]
            for m in models:
                r = sub[sub['Model_ID'] == m].iloc[0]
                est = float(r['theta_1'])
                sd = float(r['theta_1_sd'])
                t_obs = int(r['T_obs'])
                break_mode = r['Break_Mode']
                v_key = ("spec1" if set_id=="Set_1" else "spec2") + ("_break" if break_mode=="Yes" else "")
                t_val = abs(est/sd) if sd > 0 else 0
                stars = get_stars(t_val, v_key, t_obs, "inter")
                row_t1.append(f"{est:.2f}{stars}")
                row_t1_sd.append(f"({sd:.2f})")
            f.write(" & ".join(row_t1) + " \\\\\n")
            f.write(" & ".join(row_t1_sd) + " \\\\\n")
            
            f.write("\\midrule\n")
            
            # Step shifts
            row_step = ["Step shifts"]
            for m in models:
                r = sub[sub['Model_ID'] == m].iloc[0]
                row_step.append(r['Break_Mode'])
            f.write(" & ".join(row_step) + " \\\\\n")
            
            # Shin LM
            row_shin = ["$C_{\\text{Shin}}$ [$H_0$: coint.]"]
            for m in models:
                r = sub[sub['Model_ID'] == m].iloc[0]
                val = float(r['Shin_stat'])
                t_obs = int(r['T_obs'])
                break_mode = r['Break_Mode']
                v_key = ("spec1" if set_id=="Set_1" else "spec2") + ("_break" if break_mode=="Yes" else "")
                stars = get_stars(val, v_key, t_obs, "shin")
                row_shin.append(f"{val:.2f}{stars}")
            f.write(" & ".join(row_shin) + " \\\\\n")
            
            # VW Type 2
            row_vw = ["$S_{\\text{Type 2}}$ [$H_0$: coint.]"]
            for m in models:
                r = sub[sub['Model_ID'] == m].iloc[0]
                val = float(r['VW_stat'])
                b_hat = float(r['B_Hat'])
                stars = get_vw_wald_stars(val, b_hat)
                row_vw.append(f"{val:.2f}{stars}")
            f.write(" & ".join(row_vw) + " \\\\\n")
            
            # ADF
            row_adf = ["$t_{\\text{ADF}}$ [$H_0$: no coint.]"]
            for m in models:
                r = sub[sub['Model_ID'] == m].iloc[0]
                val = float(r['EG_ADF_stat'])
                stars = str(r['EG_ADF_stars']) if not pd.isna(r['EG_ADF_stars']) else ""
                row_adf.append(f"{val:.2f}{stars}")
            f.write(" & ".join(row_adf) + " \\\\\n")
            
            # Bandwidth b
            row_b = ["Bandwidth ratio $b$"]
            for m in models:
                r = sub[sub['Model_ID'] == m].iloc[0]
                row_b.append(f"{float(r['B_Hat']):.3f}")
            f.write(" & ".join(row_b) + " \\\\\n")
            
            # Sample T
            row_t = ["Sample Size $T$"]
            for m in models:
                r = sub[sub['Model_ID'] == m].iloc[0]
                row_t.append(str(int(r['T_obs'])))
            f.write(" & ".join(row_t) + " \\\\\n")
            
            f.write("\\bottomrule\n")
            f.write("\\end{tabular}\n")
            f.write("\\begin{minipage}{\\textwidth}\n")
            f.write("\\scriptsize\n")
            f.write("\\textit{Notes:} Dependent variable: $y_t^{\\text{NFC}}$ (log NFC real GVA/NVA). Estimated via CMPR IM-OLS \\citep{VogelsangWagner2014}. ")
            f.write("All interaction terms are FWL-orthogonalized against base capital regressors and step dummies. Significance: $^*p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$. Stars for coefficient rows and cointegration tests are derived from a 100,000-pass Monte Carlo simulation suite mapping the exact DGP variant and fixed-$b$ Wald tables. Standard errors in parentheses.\n")
            f.write("\\end{minipage}\n")
            f.write("\\end{table}\n\n")

# Run generation
generate_main_specA_set2_nva_table(df, os.path.join(out_dir, "table_specA_set2_nva_main.tex"))
generate_appendix_specA_tables(df, os.path.join(out_dir, "appendix_specA_tables.tex"))

print("Generated Specification A tables successfully with fixed Vogelsang-Wagner Wald star mapping!")
