---
type: paper_facing
status: results
country: CL
stage_scope: S04_Empirical_Handoff
last_updated: 2026-08-05
depends_on:
  - 06_paper_facing/drafts/ch2_sec4_4_peripheral_econometrics_prelatex.md
layer: results
scope: section 4.4
---

# R04: Peripheral Threshold IM-OLS Results (Chile)

This vault ledger stores the estimation results of the T-CMPR IM-OLS model detailed in Section 4.4. 
The structural threshold ($\hat{\gamma}$) was identified endogenously using the Profile LS algorithm over the WBOP Prebischian Capacity to Import ($C_t = X_t \cdot ToT_t$). 
The resulting state dummy $D^{ext}_t = \mathbb{I}(C_t \le \hat{\gamma})$ was mapped into a linear interactive IM-OLS framework with FWL orthogonalization.

## Data Lineage
- **Coefficients Output CSV**: [CL_T_CMPR_Coefficients.csv](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/CL_T_CMPR_Coefficients.csv)
- **Monte Carlo Fixed-$b$ Bounds CSV**: [CL_T_CMPR_FixedB_Critical_Values.csv](file:///C:/ReposGitHub/Capacity-Utilization-US_Chile/output/CL_T_CMPR_FixedB_Critical_Values.csv)

---

## 1. LaTeX Estimation Table (Ready for Paper Handoff)

The following table structure conforms strictly to the `AGENTS.md` floating and column-width constraints to ensure immediate integrability into the `.tex` manuscript.

```latex
\begin{table}[h!]
\centering
\caption{Threshold CMPR IM-OLS Estimates for Chile (Peripheral Extension)}
\label{tab:chile_threshold_imols}
\begin{tabular}{p{5cm} p{2cm} p{2cm} p{2cm} p{2cm}}
\hline\hline
\textbf{Parameter} & \textbf{Estimate} & \textbf{SE} & \textbf{Fixed-$b$ $t$-stat} & \textbf{Sig.} \\
\hline
\textbf{Base Linear Regime} & & & & \\
Plant Infrastructure ($k^{\text{NRC}}$) & 0.61 & 0.02 & 30.50 & *** \\
Mechanization Gap ($\kappa$) & 0.31 & 0.14 & 2.21 & * \\
\hline
\textbf{Regime A: Slack BoP ($D^{ext}_t = 0$)} & & & & \\
Wage-Induced Mechanization ($\omega \kappa$) & 4.85 & 1.85 & 2.62 & ** \\
\hline
\textbf{Regime B: Binding Trap ($D^{ext}_t = 1$)} & & & & \\
Penalty on Base Gap ($\kappa \cdot D^{ext}$) & -0.10 & 0.18 & -0.55 & \\
Realization Penalty ($\omega \kappa \cdot D^{ext}$) & -15.99 & 4.94 & -3.24 & *** \\
\hline\hline
\multicolumn{5}{p{13cm}}{\footnotesize \textbf{Notes:} Estimation via T-CMPR IM-OLS with FWL orthogonalization. The external constraint state dummy $D^{ext}_t$ is derived via Chen (2015) Profile LS grid search over the WBOP Capacity to Import ($C_t = X_t \cdot ToT_t$). Significance stars (* $p < 0.10$, ** $p < 0.05$, *** $p < 0.01$) are benchmarked against 100,000-pass Monte Carlo simulated critical bounds natively capturing endogenous threshold data-mining degrees of freedom.}
\end{tabular}
\end{table}
```

## 2. Empirical Verification of Theoretical Tendencies

### A. The Unconstrained Okishio Mechanism ($\beta_2 > 0$)
In Regime A, when the foreign exchange constraint is slack ($D^{ext}_t = 0$), the coefficient on the effective wage pressure interaction ($\omega_{t-1}\kappa_t$) is strictly positive and significant ($\hat{\beta}_2 = 4.85^{**}$). 
This confirms the classic distributive tendency: as wage shares rise relative to capacity limits, capitalists aggressively mechanize to restore profitability. 

### B. The Peripheral Realization Penalty ($\delta_2 < 0$)
In Regime B, when the capacity to import collapses ($D^{ext}_t = 1$), the peripheral realization penalty activates violently ($\hat{\delta}_2 = -15.99^{***}$). 
The net elasticity under the trap becomes:
$$ \hat{\beta}_2 + \hat{\delta}_2 = 4.85 - 15.99 = -11.14 $$
This empirical result perfectly validates the theoretical model defined in Section 3.3. Under extreme structural stress, the Okishio wage dividend entirely breaks down. Nominal wage increases are immediately drained through conspicuous consumption import channels, squeezing the true effective profit share $\pi_t^{eff}$ and blocking physical capital accumulation.

## 3. Methodological Compliance
- The `cpr-im-ols` simulation algorithm correctly replaced the Bai-Perron sequential algorithm with the Profile LS grid-search across $C_t$ thresholds to generate the custom fixed-$b$ bounds. 
- All results successfully bypass the Dutch Disease trap by enforcing $C_t$ strictly as the non-linear gating threshold, preventing variance inflation with $RER$.
