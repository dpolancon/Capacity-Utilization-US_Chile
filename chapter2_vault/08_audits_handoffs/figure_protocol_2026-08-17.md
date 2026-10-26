# Walkthrough: Figure Naming Protocol, Periodization & Visual Harmonization Suite

We have standardized the naming architecture, updated historical periodization regimes, harmonized graphical aesthetics, and synchronized the LaTeX manuscript layer across all 11 core econometric figures for the United States and Chile, including the dedicated Chilean Profile Likelihood Ratio sequence.

---

## 1. Summary of Standardized Naming Protocol

All figure visual artifacts now follow the standardized convention:
$$\mathbf{fig\_\{country\}\_\{specification/stage\}\_\{semantic\_concept\}\.pdf}$$

All internal in-graph titles and subtitles have been removed (`plot.title = element_blank()`), delegating captioning and note provenance strictly to LaTeX (`\caption{...}` and `\textbf{Note:}`).

### Standardized Figure Mapping:

| # | Previous Name | Standardized Filename | Country | LaTeX Caption Concept | Generator Script |
|---|---|---|---|---|---|
| 1 | `US_fig4312_dual_theta_mu_enhanced` | `fig_us_specA_dual_theta_mu.pdf` | US | Spec A: $\mu_t$ vs. $\theta_t$ Dual Axis | [`codes/US_S60_section4312_dual_plot.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_S60_section4312_dual_plot.R) |
| 2 | `US_fig4313_dual_axis_subregimes` | `fig_us_specA_subregimes_omega_iota.pdf` | US | Spec A: Sub-Regimes & Distributive State ($\omega_{t-1}, \iota_{t-1}$) | [`codes/US_S60_section4313_omega_iota_plot.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_S60_section4313_omega_iota_plot.R) |
| 3 | `fig_specB_candidate1_aggregate_elasticity` | `fig_us_specB_aggregate_elasticity.pdf` | US | Spec B: Baseline Aggregate Elasticity ($\theta_t^{\text{SpecB}}$) | [`codes/US_S60_section432_aggregate_elasticity.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_S60_section432_aggregate_elasticity.R) |
| 4 | `fig_specB_dkappa_dknrc_slope` | `fig_us_specB_dkappa_slope.pdf` | US | Spec B: Mechanization Expansion Path Derivative ($d\kappa/dk^{\text{NRC}}$) | [`codes/US_S60_section432_aggregate_elasticity.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_S60_section432_aggregate_elasticity.R) |
| 5 | `US_fig432_dual_theta_mu_specB` | `fig_us_specB_dual_theta_mu.pdf` | US | Spec B (Preferred M2.44b): Dual $\mu_t$ vs. $\theta_t^{\text{SpecB}}$ | [`codes/US_S60_section432_dual_plot_specB.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_S60_section432_dual_plot_specB.R) |
| 6 | `US_fig4323_dual_axis_driving_forces` | `fig_us_specB_driving_forces.pdf` | US | Spec B: Driving Forces of Overaccumulation ($\kappa_t, C_t, p_t^{\kappa}$) | [`codes/US_S60_section4323_driving_forces_plot.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/US_S60_section4323_driving_forces_plot.R) |
| 7 | `CL_fig_profile_lr` | `fig_cl_results_threshold_profile_lr.pdf` | Chile | Profile Likelihood Ratio Sequence for External Constraint ($LR_1(\gamma)$) | [`codes/CL_S60_threshold_profile_lr.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_S60_threshold_profile_lr.R) |
| 8 | `chile_fig2_Z_omega_drivers` | `fig_cl_results_z_omega_drivers.pdf` | Chile | Composite BoP Index ($Z_t$) vs. Gross Wage Share ($\omega_{t-1}^{\text{gross}}$) | [`codes/CL_S60_capacity_utilization_plots.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_S60_capacity_utilization_plots.R) |
| 9 | `chile_fig1_mu_theta_dual_axis` | `fig_cl_results_dual_theta_mu.pdf` | Chile | Capacity Utilization ($\mu_t$) vs. Transformation Elasticity ($\theta_t^{\text{Agg}}$) | [`codes/CL_S60_capacity_utilization_plots.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_S60_capacity_utilization_plots.R) |
| 10 | `chile_fig1b_theta_standalone` | `fig_cl_results_theta_standalone.pdf` | Chile | Standalone Peripheral Transformation Elasticity ($\theta_t^{\text{Agg}}$) | [`codes/CL_S60_capacity_utilization_plots.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_S60_capacity_utilization_plots.R) |
| 11 | `chile_fig3_Z_components` | `fig_cl_results_z_components.pdf` | Chile | External Constraint Constituent Series ($S_t, M_t, Z_t$) | [`codes/CL_S60_capacity_utilization_plots.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_S60_capacity_utilization_plots.R) |

---

## 2. Key Code & Styling Upgrades

### U.S. Figure Suite:
1. **Periodization Dates**: Synchronized to `Post-Fordism & Financialization (1974–2009)` and `Intellectual Monopoly Capital (2010–2024)`.
2. **Font Typography**: Enlarged regime annotation text banners to `size = 3.8` bold (`fontface = "bold"`).
3. **Linewidths**: Standardized to `linewidth = 1.1` across all time-series curves.

### Chile Figure Suite & Profile LR Audit:
1. **Hansen Profile LR Sequence (`fig_cl_results_threshold_profile_lr.pdf` / `CL_fig_profile_lr.pdf`)**:
   - Built dedicated pipeline in [`codes/CL_S60_threshold_profile_lr.R`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/codes/CL_S60_threshold_profile_lr.R).
   - Estimated for the preferred **Gross Wage Share ($\omega^{\text{gross}}$)** model (Column 2 of Table 3).
   - X-axis labeled `"Threshold"`; Y-axis labeled `"Profile Likelihood Ratio LR1(gamma)"`.
   - Clear horizontal dashed red line for 95% critical boundary ($c(0.05) = 7.35$) with 95% confidence interval shaded in slate gray ($[0.383, 0.521]$ covering the benchmark threshold $0.425$).
   - Profile minimum and threshold annotated clearly.
   - Exported as both `fig_cl_results_threshold_profile_lr.pdf` and `CL_fig_profile_lr.pdf` across all figure directories.
2. **External Constraint vs. Wage Share Drivers (`fig_cl_results_z_omega_drivers.pdf`)**:
   - Color-coded dual axes: LHS Y-axis in Black ($Z_t$), RHS Y-axis in Dark Green (`#2E7D32` for $\omega_{t-1}^{\text{gross}}$).
   - Enlarged font sizes for y-axis titles, numbers, and bottom legend.
3. **Capacity Utilization, Standalone Theta, and Components**:
   - Periodization labels enlarged to `size = 4.2` bold.italic.
   - Linewidths harmonized to `1.1`.

---

## 3. LaTeX Manuscript Integration & Verification

1. **Section 4 & Section 5 Updates**:
   - All `\includegraphics` commands in [`chapter2_paper/Chapter2_3.0/section4.tex`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_paper/Chapter2_3.0/section4.tex) and [`chapter2_paper/Chapter2_3.0/section5.tex`](file:///c:/ReposGitHub/Capacity-Utilization-US_Chile/chapter2_paper/Chapter2_3.0/section5.tex) updated to the standardized filenames.
   - Footnote on Figure 6 / `fig_cl_results_threshold_profile_lr` updated to explicitly note that the LR profile corresponds to the **preferred gross wage share model ($\omega^{\text{gross}}$)**.
   - All `\label{...}` and `\ref{...}` cross-references aligned to the new naming standard.
2. **Compilation**:
   - Clean compilation: `main.pdf` generated successfully (94 pages, 0 errors, 0 broken cross-references).
