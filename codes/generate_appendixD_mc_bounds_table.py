#!/usr/bin/env python3
"""
generate_appendixD_mc_bounds_table.py

Generates a single standalone, publication-grade LaTeX table containing the
custom specification-dependent Monte Carlo simulated critical bounds (N=100,000)
for Specification A (Aggregate Capital Model), adhering strictly to repo lock rules.
"""

import os
import pandas as pd

repo_root = "C:/ReposGitHub/Capacity-Utilization-US_Chile"
csv_t94 = os.path.join(repo_root, "output", "US", "S50_SECTION31_IMOLS", "csv", "section31_cmpr_custom_critical_values_T94_N100000.csv")
csv_t77 = os.path.join(repo_root, "output", "US", "S50_SECTION31_IMOLS", "csv", "section31_cmpr_custom_critical_values_T77_N100000.csv")

out_dir_reports = os.path.join(repo_root, "reports", "US_Section31_IMOLS_Results")
out_dir_paper   = os.path.join(repo_root, "chapter2_paper", "paper_tex_tables")

os.makedirs(out_dir_reports, exist_ok=True)
os.makedirs(out_dir_paper, exist_ok=True)

out_tex_path_reports = os.path.join(out_dir_reports, "table_appendixD_specA_mc_bounds.tex")
out_tex_path_paper   = os.path.join(out_dir_paper, "table_appendixD_specA_mc_bounds.tex")

df_t94 = pd.read_csv(csv_t94)
df_t77 = pd.read_csv(csv_t77)

def get_row_dict(df, variant_name):
    sub = df[df['Variant'] == variant_name]
    if len(sub) == 0:
        raise ValueError(f"Variant {variant_name} not found!")
    return sub.iloc[0].to_dict()

r94_nb = get_row_dict(df_t94, 'spec1')
r94_br = get_row_dict(df_t94, 'spec1_break')

r77_nb = get_row_dict(df_t77, 'spec1')
r77_br = get_row_dict(df_t77, 'spec1_break')

def f3(val):
    return f"{float(val):.3f}"

def f4(val):
    return f"{float(val):.4f}"

latex_lines = [
    r"\FloatBarrier",
    r"\begin{table}[h!]",
    r"\centering",
    r"\caption{Custom Monte Carlo Simulated Critical Bounds for CMPR IM-OLS Inference (Specification A)}",
    r"\label{tab:appendixD_specA_mc_bounds}",
    r"\begin{tabular}{p{4.2cm} p{2.6cm} p{2.2cm} p{2.2cm} p{2.2cm}}",
    r"\toprule",
    r"\textbf{Statistic / Parameter} & \textbf{Asymptotic 95\%} & \textbf{Sim 90\%} & \textbf{Sim 95\%} & \textbf{Sim 99\%} \\",
    r"\midrule",
    r"\multicolumn{5}{l}{\textbf{Panel A: Baseline Sample ($T=94$, 1931--2024) --- No Structural Breaks ($m=0$)}} \\",
    r"\midrule",
    rf"$t_{{\text{{level}}}}$ ($k_t^{{\text{{cap}}}}$) & 1.960 & {f3(r94_nb['t_k0_p90'])} & {f3(r94_nb['t_k0_p95'])} & {f3(r94_nb['t_k0_p99'])} \\",
    rf"$t_{{\text{{inter}}}}$ ($k_t^{{\text{{cap}}}} \cdot C_t$) & N/A & {f3(r94_nb['t_inter_p90'])} & {f3(r94_nb['t_inter_p95'])} & {f3(r94_nb['t_inter_p99'])} \\",
    rf"$CT_{{\text{{IM}}}}$ (Type 2 Cointegration) & 0.070 & {f4(r94_nb['CT_IM_p90'])} & {f4(r94_nb['CT_IM_p95'])} & {f4(r94_nb['CT_IM_p99'])} \\",
    r"\midrule",
    r"\multicolumn{5}{l}{\textbf{Panel B: Baseline Sample ($T=94$, 1931--2024) --- Bai-Perron Level-Shift Breaks ($m \ge 1$)}} \\",
    r"\midrule",
    rf"$t_{{\text{{level}}}}$ ($k_t^{{\text{{cap}}}}$) & 1.960 & {f3(r94_br['t_k0_p90'])} & {f3(r94_br['t_k0_p95'])} & {f3(r94_br['t_k0_p99'])} \\",
    rf"$t_{{\text{{inter}}}}$ ($k_t^{{\text{{cap}}}} \cdot C_t$) & N/A & {f3(r94_br['t_inter_p90'])} & {f3(r94_br['t_inter_p95'])} & {f3(r94_br['t_inter_p99'])} \\",
    rf"$CT_{{\text{{IM}}}}$ (Type 2 Cointegration) & 0.070 & {f4(r94_br['CT_IM_p90'])} & {f4(r94_br['CT_IM_p95'])} & {f4(r94_br['CT_IM_p99'])} \\",
    r"\midrule",
    r"\multicolumn{5}{l}{\textbf{Panel C: Supervisory Sample ($T=76$, 1948--2024) --- No Structural Breaks ($m=0$)}} \\",
    r"\midrule",
    rf"$t_{{\text{{level}}}}$ ($k_t^{{\text{{cap}}}}$) & 1.960 & {f3(r77_nb['t_k0_p90'])} & {f3(r77_nb['t_k0_p95'])} & {f3(r77_nb['t_k0_p99'])} \\",
    rf"$t_{{\text{{inter}}}}$ ($k_t^{{\text{{cap}}}} \cdot C_t$) & N/A & {f3(r77_nb['t_inter_p90'])} & {f3(r77_nb['t_inter_p95'])} & {f3(r77_nb['t_inter_p99'])} \\",
    rf"$CT_{{\text{{IM}}}}$ (Type 2 Cointegration) & 0.070 & {f4(r77_nb['CT_IM_p90'])} & {f4(r77_nb['CT_IM_p95'])} & {f4(r77_nb['CT_IM_p99'])} \\",
    r"\midrule",
    r"\multicolumn{5}{l}{\textbf{Panel D: Supervisory Sample ($T=76$, 1948--2024) --- Bai-Perron Level-Shift Breaks ($m \ge 1$)}} \\",
    r"\midrule",
    rf"$t_{{\text{{level}}}}$ ($k_t^{{\text{{cap}}}}$) & 1.960 & {f3(r77_br['t_k0_p90'])} & {f3(r77_br['t_k0_p95'])} & {f3(r77_br['t_k0_p99'])} \\",
    rf"$t_{{\text{{inter}}}}$ ($k_t^{{\text{{cap}}}} \cdot C_t$) & N/A & {f3(r77_br['t_inter_p90'])} & {f3(r77_br['t_inter_p95'])} & {f3(r77_br['t_inter_p99'])} \\",
    rf"$CT_{{\text{{IM}}}}$ (Type 2 Cointegration) & 0.070 & {f4(r77_br['CT_IM_p90'])} & {f4(r77_br['CT_IM_p95'])} & {f4(r77_br['CT_IM_p99'])} \\",
    r"\bottomrule",
    r"\multicolumn{5}{p{14.2cm}}{\footnotesize \textbf{Notes:} Critical bounds derived from a custom $N=100,000$ iteration Monte Carlo simulation suite calibrated specifically to the $I(1) \times I(1)$ product integration geometry of the regressors and dynamic Bai-Perron break degrees of freedom. Panels A and B reflect the baseline 1931--2024 sample length ($T=94$), while Panels C and D reflect the supervisory-adjusted Tier 2 wage share sample ($T=76$). Bandwidth $b = M/T$ is fixed per Vogelsang \& Wagner (2014) IM-OLS specification. Data Generating Process ($H_0$) constructs independent zero-drift random walks for base level variables ($k_t^{\text{cap}}, \omega_t$), with interaction product processes algebraically assembled prior to estimation. Parameter $t$-statistics are centered around their true theoretical values ($t^* = |(\hat{\beta}^* - \beta_{\text{true}})/SE|$) to ensure pure size calibration rather than power distortion.} \\",
    r"\end{tabular}",
    r"\end{table}"
]

latex_content = "\n".join(latex_lines) + "\n"

with open(out_tex_path_reports, "w", encoding="utf-8") as f:
    f.write(latex_content)

with open(out_tex_path_paper, "w", encoding="utf-8") as f:
    f.write(latex_content)

print(f"Successfully generated Appendix D Monte Carlo bounds LaTeX table:")
print(f"  - {out_tex_path_reports}")
print(f"  - {out_tex_path_paper}")
