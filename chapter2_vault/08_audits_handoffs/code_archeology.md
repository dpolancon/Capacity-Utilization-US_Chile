I will write a python script to audit the exact units of `G_TOT_GPIM_2017` and `LOG_G_TOT_GPIM_2017` across the dataset and BEA Fixed Assets source tables.

Created audit_capital_units.py

I will run the python audit script to verify the exact unit conversions for $K_t$.

Ran command: `python C:\Users\User\.gemini\antigravity\brain\b0cd553c-177b-4568-8922-6446219b2174\scratch\audit_capital_units.py`

I will update `generate_summary_table.py` to fix the capital stock unit definition to **Trillions of 2017 USD** ($K_t = 38.24$ Trillion USD average, $91.74$ Trillion USD max in 2024), update the table notes, and re-export the LaTeX file to `chapter2_paper/table_summary_stats.tex`.

Created generate_summary_table.py

I will run `generate_summary_table.py` to regenerate `table_summary_stats.tex`.

Ran command: `python C:\Users\User\.gemini\antigravity\brain\b0cd553c-177b-4568-8922-6446219b2174\scratch\generate_summary_table.py`

I will view `chapter2_paper/table_summary_stats.tex` to confirm the reconciled LaTeX output.

Viewed table_summary_stats.tex:1-26

### Unit Audit & Reconciliation Report

The audit confirms your macroeconomic assessment:

1. **Upstream Data Unit Verification**:
   * Raw BEA Fixed Assets level data in `G_TOT_GPIM_2017` is expressed in **Millions of 2017 USD**.
   * In 1931: `G_TOT_GPIM_2017` $= 19,322,142.64 \text{ Million USD} = \mathbf{19.32 \text{ Trillion USD}}$.
   * In 2024: `G_TOT_GPIM_2017` $= 91,738,095.97 \text{ Million USD} = \mathbf{91.74 \text{ Trillion USD}}$.
   * Sample Mean (1931–2024): $38,237,502.59 \text{ Million USD} = \mathbf{38.24 \text{ Trillion USD}}$.

2. **Reconciliation**:
   * When dividing by $1,000,000$, the level is converted into **Trillions of 2017 USD**, matching macroeconomic reality ($K_{2024} \approx \$91.74 \text{ Trillion}$).
   * The variable label in the table and the `tablenotes` have been updated to explicitly state **Trillions of 2017 USD**.

---

### Reconciled Python Generator Script

```python
import pandas as pd
import numpy as np
import os

repo_root = "C:/ReposGitHub/Capacity-Utilization-US_Chile"
wide_csv  = os.path.join(repo_root, "data/releases/chapter2_us_source_of_truth_v1_1_candidate/CH2_US_V1_1_CANDIDATE_SOURCE_OF_TRUTH_WIDE.csv")
specb_csv = os.path.join(repo_root, "output/gpim_specB_components_long.csv")

df_wide  = pd.read_csv(wide_csv)
df_specb = pd.read_csv(specb_csv)

# Merge wide source of truth with staged disaggregated stocks
df = pd.merge(df_wide, df_specb[['year', 'k_NRC', 'k_ME', 'tau_real']], on='year', how='left')

# Filter for common estimation window 1931-2024 (T=94)
df_sub = df[(df['year'] >= 1931) & (df['year'] <= 2024)].copy()

# Raw G_TOT_GPIM_2017 is in Millions of 2017 USD.
# Dividing by 1,000,000 converts Millions of 2017 USD into Trillions of 2017 USD.
df_sub['K_trillions'] = df_sub['G_TOT_GPIM_2017'] / 1000000.0

# Target variables mapping
var_specs = [
    ('y_real_nfc_gva_baseline', r'$\ln Y_t$', 'Log Real Output (NFC Real Net Value Added)', False),
    ('K_trillions', r'$K_t$', 'Gross Productive Capital (Trillions of 2017 USD)', True),
    ('LOG_G_TOT_GPIM_2017', r'$\ln K_t$', 'Log Aggregate Gross Capital', False),
    ('k_NRC', r'$k_t^{\text{NRC}}$', 'Log Nonresidential Structures Stock', False),
    ('k_ME', r'$k_t^{\text{ME}}$', 'Log Machinery \& Equipment Stock', False),
    ('tau_real', r'$\kappa_t$', r'Mechanization Gap ($k_t^{\text{ME}} - k_t^{\text{NRC}}$)', False),
    ('DLOG_G_TOT', r'$\Delta \ln K_t$', 'Capital Stock Growth Rate', False),
    ('NFC_COMPENSATION_SHARE_NVA', r'$\omega_t^{\text{NVA}}$', 'Baseline Nominal Wage Share (NVA)', False),
    ('NFC_COMPENSATION_SHARE_GVA', r'$\omega_t^{\text{GVA}}$', 'Robustness Nominal Wage Share (GVA)', False),
]

stats_rows = []
for var_id, symbol, label, is_level in var_specs:
    s = df_sub[var_id].dropna()
    n = len(s)
    mean_val = s.mean()
    std_val = s.std()
    min_val = s.min()
    max_val = s.max()
    
    if is_level:
        mean_str = f"{mean_val:,.2f}"
        std_str = f"{std_val:,.2f}"
        min_str = f"{min_val:,.2f}"
        max_str = f"{max_val:,.2f}"
    else:
        mean_str = f"{mean_val:.3f}"
        std_str = f"{std_val:.3f}"
        min_str = f"{min_val:.3f}"
        max_str = f"{max_val:.3f}"
        
    stats_rows.append({
        'symbol': symbol,
        'label': label,
        'n': n,
        'mean': mean_str,
        'std': std_str,
        'min': min_str,
        'max': max_str
    })

# Generate Publication-Ready LaTeX Code
latex_lines = []
latex_lines.append(r"\begin{table}[h!]")
latex_lines.append(r"\centering")
latex_lines.append(r"\begin{threeparttable}")
latex_lines.append(r"\caption{Summary Statistics: U.S. NFC Estimation Panel (1931--2024)}")
latex_lines.append(r"\label{tab:41:summary_stats}")
latex_lines.append(r"\begin{tabular}{l p{7.0cm} c c c c c}")
latex_lines.append(r"\toprule")
latex_lines.append(r"\textbf{Symbol} & \textbf{Variable Description} & \textbf{N} & \textbf{Mean} & \textbf{Std. Dev.} & \textbf{Min} & \textbf{Max} \\")
latex_lines.append(r"\midrule")

for r in stats_rows:
    latex_lines.append(f"{r['symbol']} & {r['label']} & {r['n']} & {r['mean']} & {r['std']} & {r['min']} & {r['max']} \\\\")

latex_lines.append(r"\bottomrule")
latex_lines.append(r"\end{tabular}")
latex_lines.append(r"\begin{tablenotes}")
latex_lines.append(r"\small")
latex_lines.append(r"\item \textit{Notes:} Sample restricted to years with full baseline window eligibility per the Support Window Ledger ($T=94$). Capital stock level $K_t$ is gross real GPIM stock expressed in trillions of 2017 USD (formatted to 2 decimal places). Log variables, growth rates, and dimensionless wage share ratios are formatted to 3 decimal places. Source: BEA NIPA and Fixed Assets Accounts, reconstructed via S12D-B GPIM engine.")
latex_lines.append(r"\end{tablenotes}")
latex_lines.append(r"\end{threeparttable}")
latex_lines.append(r"\end{table}")

latex_code = "\n".join(latex_lines)

out_tex = os.path.join(repo_root, "chapter2_paper", "table_summary_stats.tex")
os.makedirs(os.path.dirname(out_tex), exist_ok=True)
with open(out_tex, "w", encoding="utf-8") as f:
    f.write(latex_code)
```

---

### Reconciled LaTeX Output File (`chapter2_paper/table_summary_stats.tex`)

```latex
\begin{table}[h!]
\centering
\begin{threeparttable}
\caption{Summary Statistics: U.S. NFC Estimation Panel (1931--2024)}
\label{tab:41:summary_stats}
\begin{tabular}{l p{7.0cm} c c c c c}
\toprule
\textbf{Symbol} & \textbf{Variable Description} & \textbf{N} & \textbf{Mean} & \textbf{Std. Dev.} & \textbf{Min} & \textbf{Max} \\
\midrule
$\ln Y_t$ & Log Real Output (NFC Real Net Value Added) & 94 & 14.734 & 1.107 & 12.485 & 16.289 \\
$K_t$ & Gross Productive Capital (Trillions of 2017 USD) & 94 & 38.24 & 17.58 & 19.32 & 91.74 \\
$\ln K_t$ & Log Aggregate Gross Capital & 94 & 17.375 & 0.395 & 16.777 & 18.334 \\
$k_t^{\text{NRC}}$ & Log Nonresidential Structures Stock & 94 & 13.725 & 1.753 & 11.012 & 16.423 \\
$k_t^{\text{ME}}$ & Log Machinery \& Equipment Stock & 94 & 13.087 & 1.942 & 9.845 & 15.728 \\
$\kappa_t$ & Mechanization Gap ($k_t^{\text{ME}} - k_t^{\text{NRC}}$) & 94 & -0.637 & 0.278 & -1.210 & -0.313 \\
$\Delta \ln K_t$ & Capital Stock Growth Rate & 94 & -0.017 & 0.015 & -0.055 & 0.009 \\
$\omega_t^{\text{NVA}}$ & Baseline Nominal Wage Share (NVA) & 94 & 0.706 & 0.029 & 0.647 & 0.805 \\
$\omega_t^{\text{GVA}}$ & Robustness Nominal Wage Share (GVA) & 94 & 0.623 & 0.026 & 0.565 & 0.678 \\
\bottomrule
\end{tabular}
\begin{tablenotes}
\small
\item \textit{Notes:} Sample restricted to years with full baseline window eligibility per the Support Window Ledger ($T=94$). Capital stock level $K_t$ is gross real GPIM stock expressed in trillions of 2017 USD (formatted to 2 decimal places). Log variables, growth rates, and dimensionless wage share ratios are formatted to 3 decimal places. Source: BEA NIPA and Fixed Assets Accounts, reconstructed via S12D-B GPIM engine.
\end{tablenotes}
\end{threeparttable}
\end{table}
```