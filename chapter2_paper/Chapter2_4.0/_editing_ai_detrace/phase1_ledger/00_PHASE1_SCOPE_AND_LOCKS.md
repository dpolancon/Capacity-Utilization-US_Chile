# Phase 1 scope and locks

Date: 2026-09-29 (task-local date). Diagnostic pass only.

## Repository and initial Git observations

- Working directory: `C:\ReposGitHub\Capacity-Utilization-US_Chile\chapter2_paper\Chapter2_3.0`
- Repository root: `C:/ReposGitHub/Capacity-Utilization-US_Chile`
- Current branch: `main`
- The three requested read-only Git commands were run from Chapter2_3.0 immediately after reading the attached request. The working tree was already dirty. The status was persisted after source reconnaissance; no Git mutation occurred. Chapter2_3.0 was already represented by `?? ./`, so short status does not enumerate new diagnostics inside it.

```text
 M ../../.agents/skills/cpr-im-ols/SKILL.md
 m ../WP_Chapter2_1.0/.claudeprism/history.git
 m ../WP_Chapter2_1.0/.prism/build
 M ../WP_Chapter2_1.0/__pycache__/compile_chapter2.cpython-314.pyc
 M ../WP_Chapter2_1.0/appendixA.tex
 M ../WP_Chapter2_1.0/main.pdf
 M ../WP_Chapter2_1.0/main.tex
 M ../WP_Chapter2_1.0/references.bib
 M ../WP_Chapter2_1.0/section2.tex
 M ../WP_Chapter2_1.0/section3.tex
 M ../WP_Chapter2_1.0/section4.tex
 M ../WP_Chapter2_1.0/section6.tex
 M ../../chapter2_vault/.obsidian/app.json
 M ../../chapter2_vault/.obsidian/appearance.json
 M ../../chapter2_vault/03_econometrics/_03_Econometrics_MOC.md
 M ../../chapter2_vault/04_data_measurement/L06_US_Distributive_Variable_Profit_Share_Ledger.md
 M ../../chapter2_vault/05_codes_implementation/C05-FIGURE_PROTOCOL.md
 M ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_2_baseline_spec_US/ch2_sec4_2_1.md
 M ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_2_baseline_spec_US/ch2_sec4_2_2.md
 M ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_2_baseline_spec_US/ch2_sec4_2_3.md
 M ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/ch2_sec4_3_1.md
 M ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/ch2_sec4_3_2.md
 M ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/ch2_sec4_3_4.md
 D ../../chapter2_vault/08_audit_handoffs/regime_change_tests_proposal.md
 D ../../chapter2_vault/85_reports/R02_US_SpecificationB_IMOLS_Capital_Disaggregation_Report.md
 M ../../chapter2_vault/DEPENDENCY_MANIFEST.md
 M ../../chapter2_vault/NOTATION_SHEET.md
 M ../../chapter2_vault/_INDEX.md
 M ../../codes/CL_S40_price_proxy_integration.R
 M ../../codes/CL_S50_section33_imols_estimation.R
 M ../../codes/CL_S52_cmpr_montecarlo_critical_values.R
 M ../../codes/COMMON_S30_gpim_baseline_capital_intake.R
 M ../../codes/COMMON_S30_stage_specB_variables.R
 M ../../codes/US_S29F_shaikh_tonak_wage_share_construction.R
 M ../../codes/US_S50_section31_imols_estimation.R
 M ../../codes/US_S52_section31_cmpr_montecarlo_critical_values.R
 M ../../codes/US_S61_section32_imols_specB.R
 M ../../codes/US_S62_section32_imols_montecarlo.R
 M ../../codes/generate_s31_latex_tables.py
 M ../../data/staged/ch2_panel_chile_with_prices.csv
 M ../../output/Chile_S52_cmpr_critical_values_N1000.csv
 M ../../output/Chile_S52_cmpr_critical_values_N100000.csv
 M ../../output/US/S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION/csv/S29F_shaikh_tonak_wage_share_panel.csv
 M ../../output/US/S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION/md/S29F_SHAIKH_TONAK_WAGE_SHARE_CONSTRUCTION_SUMMARY.md
 M ../../output/US/S50_SECTION31_IMOLS/csv/s50_section31_results.csv
 M ../../output/US/S50_SECTION31_IMOLS/rds/s50_fitted_models.rds
 M ../../output/US/S60_CAPACITY_RECOVERY/csv/s60_section32_series.csv
 M ../../output/US/S61_SECTION32_IMOLS/csv/s61_section32_results.csv
 M ../../output/US/S61_SECTION32_IMOLS/rds/s61_fitted_models.rds
 M ../../output/chile_imols_peripheral_results.csv
 M ../../output/generate_latex_tables.py
 M ../../output/gpim_baseline_components_long.csv
 M ../../output/gpim_specB_components_long.csv
 D ../../reports/Chile_Capital_Composition_Integrated_Report/99_archive/chile_capital_composition_integrated_report.pdf
 D ../../reports/Chile_Capital_Composition_Integrated_Report/99_archive/chile_capital_composition_integrated_report.tex
 M ../../reports/Chile_Section33_Peripheral_IMOLS_Results/chile_section33_peripheral_results_new.pdf
 M ../../reports/Chile_Section33_Peripheral_IMOLS_Results/chile_section33_peripheral_results_new.tex
 M ../../reports/Chile_Section33_Peripheral_IMOLS_Results/table_chile_threshold_imols.tex
 D ../../reports/US_Integration_Order_Appendix/99_archive/us_integration_order_appendix.md
 D ../../reports/US_Integration_Order_Appendix/99_archive/us_integration_order_appendix.pdf
 D ../../reports/US_Integration_Order_Appendix/99_archive/us_integration_order_appendix.tex
 M ../../reports/US_Section31_IMOLS_Results/table_specA_set1_gva.tex
 M ../../reports/US_Section31_IMOLS_Results/table_specA_set1_nva.tex
 M ../../reports/US_Section31_IMOLS_Results/table_specA_set2_gva.tex
 M ../../reports/US_Section31_IMOLS_Results/table_specA_set2_nva.tex
 M ../../reports/US_Section31_IMOLS_Results/us_section31_imols_results.pdf
 M ../../reports/US_Section32_IMOLS_Results/table_specB_set1_gva.tex
 M ../../reports/US_Section32_IMOLS_Results/table_specB_set1_nva.tex
 M ../../reports/US_Section32_IMOLS_Results/table_specB_set2_gva.tex
 M ../../reports/US_Section32_IMOLS_Results/table_specB_set2_nva.tex
 M ../../reports/US_Section32_IMOLS_Results/us_section32_imols_results.pdf
 M ../../reports/US_Section32_IMOLS_Results/us_section32_imols_results.tex
?? ../../.env
?? ./
?? ../WP_Chapter2_1.0/descriptive_table_Kstock_US.tex
?? ../WP_Chapter2_1.0/figures_tables/
?? ../WP_Chapter2_1.0/references_long.tex
?? ../WP_Chapter2_1.0/section4_old.tex
?? ../WP_Chapter2_1.0/sync_figures_tables.py
?? ../WP_Chapter2_2.0/
?? ../paper_tex_3.0/
?? ../paper_tex_tables/
?? ../table_summary_stats.tex
?? ../../chapter2_vault/.obsidian/canvas.json
?? ../../chapter2_vault/02_analyitical_foundation/Future_Research_Corner_Solution_Kappa.md
?? ../../chapter2_vault/04_data_measurement/V02_Chile_KStock_DataProvenance_Management.md
?? ../../chapter2_vault/05_codes_implementation/C06-ARTIFACT_ROUTING_REGISTRY.md
?? ../../chapter2_vault/06_paper_facing/05_Chile_Peripheral_Econometric_Strategy.md
?? ../../chapter2_vault/06_paper_facing/06_Chile_Appendix_Full_Grid_Estimates.md
?? ../../chapter2_vault/06_paper_facing/Section4_Outline_ACTIVE.md
?? "../../chapter2_vault/06_paper_facing/drafts/Active Outline.md"
?? "../../chapter2_vault/06_paper_facing/drafts/Empirical Identification Strategy.md"
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/US_fig432_dual_theta_mu_specB.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/US_fig432_dual_theta_mu_specB.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig1_reconstructed_capacity_utilization.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig1_reconstructed_capacity_utilization.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig2_transformation_elasticity_aggregate_s31.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig2_transformation_elasticity_aggregate_s31.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig2_transformation_elasticity_heterogeneous_s32.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig2_transformation_elasticity_heterogeneous_s32.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig3_state_dependent_wage_pressure_stacked.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig3_state_dependent_wage_pressure_stacked.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig4_heterogeneous_mechanization_and_prices_stacked.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig4_heterogeneous_mechanization_and_prices_stacked.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_aggregate_elasticity_comparison.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_aggregate_elasticity_knife_edge.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_aggregate_elasticity_knife_edge.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_aggregate_elasticity_zoomed.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_aggregate_elasticity_zoomed.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_candidate1_aggregate_elasticity.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_candidate1_aggregate_elasticity.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_candidate2_aggregate_elasticity.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_candidate2_aggregate_elasticity.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_dkappa_dknrc_slope.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_dkappa_dknrc_slope.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_reconstructed_capacity_utilization.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_specB_reconstructed_capacity_utilization.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_us_specB_aggregate_elasticity.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_us_specB_aggregate_elasticity.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_us_specB_dkappa_slope.pdf
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_3_heterogeneous_capital_US/fig_us_specB_dkappa_slope.png
?? ../../chapter2_vault/06_paper_facing/drafts/ch2_sec4_4_peripheral_extension_Chile/
?? ../../chapter2_vault/06_paper_facing/drafts/historical_interpretation_material.md
?? ../../chapter2_vault/06_paper_facing/figures/
?? ../../chapter2_vault/06_paper_facing/results/R05_Chile_Preferable_Models_and_Aggregate_Elasticity_Audit.md
?? ../../chapter2_vault/06_paper_facing/results/deep_research_sec32_model_selection_and_elasticity.md
?? ../../chapter2_vault/08_audits_handoffs/2026-08-07_data_provenance_audit_report.md
?? ../../chapter2_vault/08_audits_handoffs/2026-08-09_chile_data_provenance_audit_report.md
?? ../../chapter2_vault/08_audits_handoffs/2026-08-11_cmpr_custom_cv_benchmarking_memo.md
?? ../../chapter2_vault/08_audits_handoffs/2026-08-11_data_provenance_Y_NFC_and_aggregate_output.md
?? ../../chapter2_vault/08_audits_handoffs/2026-08-11_figure_redesign_session_handoff.md
?? ../../chapter2_vault/08_audits_handoffs/2026-08-15_session_handoff_ch2_to_ch3_transmission.md
?? ../../chapter2_vault/08_audits_handoffs/Writting_Artifact.md
?? ../../chapter2_vault/08_audits_handoffs/chile_omega_net_robustness_specs_pendingtask_2026-08-17.md
?? ../../chapter2_vault/08_audits_handoffs/chile_section5_advisor_feedback_and_avenues.md
?? ../../chapter2_vault/08_audits_handoffs/chile_section5_stage3_review_report.md
?? ../../chapter2_vault/08_audits_handoffs/code_archeology.md
?? ../../chapter2_vault/08_audits_handoffs/figure_protocol_2026-08-17.md
?? ../../chapter2_vault/08_audits_handoffs/regime_change_tests_proposal.md
?? ../../chapter2_vault/70_papers/AhumadaFranco2025.pdf
?? ../../chapter2_vault/70_papers/FrensString2022.pdf
?? ../../chapter2_vault/70_papers/Gonzalez-Correa_Robles2022.pdf
?? ../../chapter2_vault/70_papers/LEY-7200_21-JUL-1942.pdf
?? ../../chapter2_vault/70_papers/LlanosReyes2011.pdf
?? "../../chapter2_vault/70_papers/Regime Change at the Border_ The 1942 Institutional Pivot That Stabilized Chile's Monetary System.pdf"
?? "../../chapter2_vault/85_reports/R02_RegimeChange_1942InstitutionalPivot_Monetary System.md"
?? ../../chapter2_vault/85_reports/R03_US_SpecificationB_IMOLS_Capital_Disaggregation_Report.md
?? ../../chapter2_vault/85_reports/R04_Chile_demoted_Report_BUTVALUABLE.md
?? ../../chapter2_vault/85_reports/R05_Chile_demoted_Report_BUTVALUABLE.md
?? ../../chapter2_vault/85_reports/Untitled.md
?? ../../codes/00_build_gdp_deflator_dataset.py
?? ../../codes/CL_S05_query_and_splice_bcch_gdp.py
?? ../../codes/CL_S06_query_and_splice_bcch_deflator.py
?? ../../codes/CL_S54_imols_backward_expanding_windows.R
?? ../../codes/CL_S60_capacity_utilization_plots.R
?? ../../codes/CL_S60_capacity_utilization_recovery.R
?? ../../codes/CL_S60_generate_chile_master_figures.R
?? ../../codes/CL_S60_generate_stylized_facts_figures.R
?? ../../codes/CL_S60_threshold_profile_lr.R
?? ../../codes/CL_S90_solv_lev_ratio_plots.R
?? ../../codes/CL_S91_wbop_structural_ratio_plots.R
?? ../../codes/CL_S92_build_monetary_wbop_master_dataset.R
?? ../../codes/COMMON_S00_artifact_routing_scan.py
?? ../../codes/S60_section5_comparative_mu.R
?? ../../codes/US_S60_generate_master_figures.R
?? ../../codes/US_S60_generate_stylized_facts_figures.R
?? ../../codes/US_S60_section4312_dual_plot.R
?? ../../codes/US_S60_section4313_omega_iota_plot.R
?? ../../codes/US_S60_section4323_driving_forces_plot.R
?? ../../codes/US_S60_section432_aggregate_elasticity.R
?? ../../codes/US_S60_section432_dual_plot_specB.R
?? ../../codes/export_specB_paper_tables.py
?? ../../codes/generate_appendixD_mc_bounds_table.py
?? ../../codes/generate_paper_specA_tables.py
?? ../../codes/scratch_test_theta.R
?? ../../data/interim/Chile/
?? ../../data/processed/Chile/chile_monetary_wbop_1920_2024.csv
?? ../../data/processed/Chile/chile_monetary_wbop_compilation_master.csv
?? ../../data/processed/gdp_deflator/
?? ../../data/raw/Chile/bis_dp_search_export_20260812-191754.csv
?? ../../data/raw/Chile/cliolab/
?? ../../output/CL/BOP_BINDING/CL_fig_profile_lr.pdf
?? ../../output/CL/BOP_BINDING/CL_fig_profile_lr.png
?? ../../output/CL/BOP_BINDING/fig_cl_results_threshold_profile_lr.pdf
?? ../../output/CL/BOP_BINDING/fig_cl_results_threshold_profile_lr.png
?? ../../output/CL/figures/cl_fig1_reconstructed_capacity_utilization.pdf
?? ../../output/CL/figures/cl_fig1_reconstructed_capacity_utilization.png
?? ../../output/CL/figures/cl_fig2_divisia_transformation_elasticity.pdf
?? ../../output/CL/figures/cl_fig2_divisia_transformation_elasticity.png
?? ../../output/CL/figures/cl_fig3_peripheral_realization_penalty_stacked.pdf
?? ../../output/CL/figures/cl_fig3_peripheral_realization_penalty_stacked.png
?? ../../output/CL/figures/cl_fig4_capital_composition_and_prices_stacked.pdf
?? ../../output/CL/figures/cl_fig4_capital_composition_and_prices_stacked.png
?? ../../output/CL/figures/cl_fig5_unconstrained_counterfactual_destruction_stacked.pdf
?? ../../output/CL/figures/cl_fig5_unconstrained_counterfactual_destruction_stacked.png
?? ../../output/CL/figures/csv/
?? ../../output/CL/figures/fig_cl_results_z_index_threshold.pdf
?? ../../output/CL/figures/fig_cl_results_z_index_threshold.png
?? ../../output/CL/figures/fig_cl_stylized_1_y_kcomponents.pdf
?? ../../output/CL/figures/fig_cl_stylized_1_y_kcomponents.png
?? ../../output/CL/figures/fig_cl_stylized_1a_y_kcap.pdf
?? ../../output/CL/figures/fig_cl_stylized_1a_y_kcap.png
?? ../../output/CL/figures/fig_cl_stylized_1b_yk_ratio.pdf
?? ../../output/CL/figures/fig_cl_stylized_1b_yk_ratio.png
?? ../../output/CL/figures/fig_cl_stylized_2_kappa_mechanization.pdf
?? ../../output/CL/figures/fig_cl_stylized_2_kappa_mechanization.png
?? ../../output/CL/figures/fig_cl_stylized_3_wage_share.pdf
?? ../../output/CL/figures/fig_cl_stylized_3_wage_share.png
?? ../../output/CL/figures/fig_cl_stylized_4_external_constraint.pdf
?? ../../output/CL/figures/fig_cl_stylized_4_external_constraint.png
?? ../../output/CL/figures/fig_cl_stylized_4a_external_constraint.pdf
?? ../../output/CL/figures/fig_cl_stylized_4a_external_constraint.png
?? ../../output/CL/figures/fig_cl_stylized_4b_external_constraint.pdf
?? ../../output/CL/figures/fig_cl_stylized_4b_external_constraint.png
?? ../../output/CL/figures/fig_cl_stylized_4c_external_constraint.pdf
?? ../../output/CL/figures/fig_cl_stylized_4c_external_constraint.png
?? ../../output/CL/figures/fig_cl_stylized_4d_external_constraint.pdf
?? ../../output/CL/figures/fig_cl_stylized_4d_external_constraint.png
?? ../../output/US/S50_SECTION31_IMOLS/csv/cmpr_s31_critical_values_T77_N100.csv
?? ../../output/US/S50_SECTION31_IMOLS/csv/cmpr_s31_critical_values_T94_N100.csv
?? ../../output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_T77_N100000.csv
?? ../../output/US/S50_SECTION31_IMOLS/csv/section31_cmpr_custom_critical_values_T94_N100000.csv
?? ../../output/US/S60_CAPACITY_RECOVERY/csv/s60_specB_aggregate_elasticity.csv
?? ../../output/US/S60_CAPACITY_RECOVERY/csv/us_mu_m244b.csv
?? ../../output/US/S60_CAPACITY_RECOVERY/fig/
?? ../../output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_T77_N100.csv
?? ../../output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_T77_N100000.csv
?? ../../output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_T94_N100.csv
?? ../../output/US/S62_SECTION32_MC/csv/cmpr_s32_critical_values_T94_N100000.csv
?? ../../output/US/figures/
?? ../../output/artifact_routing/
?? ../../output/chile_capacity_utilization_series.csv
?? ../../output/chile_champion_t_bounds.csv
?? ../../output/chile_expanded_grid_results.csv
?? ../../output/chile_fig1_mu_theta_dual_axis.pdf
?? ../../output/chile_fig1_mu_theta_dual_axis.png
?? ../../output/chile_fig1b_theta_standalone.pdf
?? ../../output/chile_fig1b_theta_standalone.png
?? ../../output/chile_fig2_Z_omega_drivers.pdf
?? ../../output/chile_fig2_Z_omega_drivers.png
?? ../../output/chile_fig3_Z_components.pdf
?? ../../output/chile_fig3_Z_components.png
?? ../../output/chile_imols_backward_trace_1973.csv
?? ../../output/chile_imols_peripheral_results_tiered.csv
?? ../../output/chile_imols_peripheral_table.tex
?? ../../output/chile_massive_grid_results.csv
?? ../../output/chile_massive_t_bounds.csv
?? ../../output/chile_parsimonious_theta.csv
?? ../../output/chile_preferred_theta_utilization.csv
?? ../../output/chile_profile_ssr_grid.csv
?? ../../output/data_provenance_audit_chile.csv
?? ../../output/fig_cl_results_dual_theta_mu.pdf
?? ../../output/fig_cl_results_dual_theta_mu.png
?? ../../output/fig_cl_results_theta_standalone.pdf
?? ../../output/fig_cl_results_theta_standalone.png
?? ../../output/fig_cl_results_z_components.pdf
?? ../../output/fig_cl_results_z_components.png
?? ../../output/fig_cl_results_z_omega_drivers.pdf
?? ../../output/fig_cl_results_z_omega_drivers.png
?? ../../output/gdp_deflator/
?? ../../output/omega_table_models.rds
?? ../../reports/CHILE_solv_lev_ratio_plots/
?? ../../reports/CL_import_capacity/
?? ../../reports/Chile_Capital_Composition_Integrated_Report/chile_capital_composition_integrated_report.pdf
?? ../../reports/Chile_Capital_Composition_Integrated_Report/chile_capital_composition_integrated_report.tex
?? ../../reports/Chile_Section33_Peripheral_IMOLS_Results/Chile_Section33_Peripheral_Figures_Political_Economy_Interpretation.md
?? ../../reports/Chile_Section33_Peripheral_IMOLS_Results/Set_1_Tier0_Physical_Core.md
?? ../../reports/Chile_Section33_Peripheral_IMOLS_Results/Set_2_Tier1_Standalone_Prices.md
?? ../../reports/Chile_Section33_Peripheral_IMOLS_Results/Set_3_Tier2_Interacted_Prices.md
?? ../../reports/Chile_Section33_Peripheral_IMOLS_Results/Set_4_Tier3_Deflated_Prices.md
?? ../../reports/Chile_Section33_Peripheral_IMOLS_Results/table_chile_appendix_sensitivity.tex
?? ../../reports/US_Integration_Order_Appendix/us_integration_order_appendix.md
?? ../../reports/US_Integration_Order_Appendix/us_integration_order_appendix.pdf
?? ../../reports/US_Integration_Order_Appendix/us_integration_order_appendix.tex
?? ../../reports/US_Section31_IMOLS_Results/table_appendixD_specA_mc_bounds.tex
?? ../../reports/US_Section32_IMOLS_Results/table_cmpr_s32_critical_values.tex
?? ../../reports/US_Section3_Figures_Political_Economy_Interpretation.md
?? ../../reports/chile_peripheral_econometric_strategy.tex
?? ../../reports/chile_specB_exploitation_variants_table.tex
?? ../../reports/chile_specB_full_distributive_tables.tex
?? ../../reports/chile_specB_omega_variants_table.tex
?? ../../reports/gdp_deflator_data_guideline.md
?? ../../reports/table_chile_distributive_comparison_main.tex
?? ../../reports/table_chile_parsimonious_champion.tex
?? ../../scratch/audit_chile_wage_share.R
?? ../../scratch/audit_nonredundant_perms.R
?? ../../scratch/audit_omega_theta.R
?? ../../scratch/audit_sudden_stops_mcap.R
?? ../../scratch/audit_transcript_8ba.R
?? ../../scratch/audit_us_wage_shares.R
?? ../../scratch/audit_wage_share.R
?? ../../scratch/check_12_permutations.R
?? ../../scratch/check_chile_cols.R
?? ../../scratch/check_coverage.R
?? ../../scratch/check_distr_raw.R
?? ../../scratch/check_distr_sheets.R
?? ../../scratch/check_perez_bcch_d.R
?? ../../scratch/check_us_kappa.R
?? ../../scratch/check_us_omega_permutations.R
?? ../../scratch/check_yk_ranges.R
?? ../../scratch/inspect_yk_log_diff.R
?? ../../scratch/plot_ratio.R
?? ../../scratch/print_us_kappa_all.R
?? ../../scratch/temp_run.R
?? ../../scratch/temp_run_main.R
?? ../../scratch/temp_run_parsimonious.R
?? ../../scratch/test_corrected_chile_omega_net.R
?? ../../scratch/test_fig4a_4b_permutations.R
?? ../../scratch/test_sudden_stop_thresholds.R
```

## Source of truth and reconnaissance

`main.tex` is the active root, supported by its input chain and main.log. Active main-text prose is split across section1.tex–section6.tex; the abstract is in main.tex. references.bib is the active bibliography, confirmed by main.blg. Six appendix files and six table files are input by the root or Section 4. The exact dependency closure is in source_dependency_graph.md. Figures are read-only dependencies named by includegraphics. main.pdf and Chapter2_V3.0.pdf are byte-identical 103-page PDFs. PDF pages 44 and 78 were rendered and visually inspected only for context: displayed mathematics remains within its prose unit and the Conclusion opening is present. This is not a PDF-wide layout audit.

The existing compile_chapter2.py is a Markdown-to-LaTeX generator that would overwrite active sources; it was inspected but never run. Its upstream drafts are not substituted for active LaTeX. section4_old.tex, references_long.tex, and 99_archive are outside the active source chain. Existing directories include 99_archive, figures, tables, .prism, .claudeprism, .venv, and __pycache__; no existing equivalent Phase 1 directory was found. Repository audit/style locations identified include chapter2_vault/08_audits_handoffs and chapter2_vault/07_WrittingSkills_and_Rules. No prior artifacts were overwritten.

## Scope and counting convention

Abstract; Sections 1–2; Section 3 prose around formal material; Sections 4.1–4.6; Discussion; Conclusion. Source numbering is generated by section/subsection/subsubsection commands, consistent with main.toc, not inferred from stale cross-references inside prose.

267 prose units include 26 substantive list items. Each blank-line-delimited prose paragraph, run-in-heading body, or substantive list item is one unit. A displayed equation does not by itself split a paragraph: adjoining prose separated only by the display remains one unit. Genuine blank-line-separated equation introductions/continuations have their own IDs. Paragraph headings are not counted as prose. Formal statement prose is inventoried conservatively, with the formal claim protected; local explanatory grammar flags never authorize changing a proposition. Attached footnotes remain with their host paragraph and are not separately counted.

IDs reset by the deepest numbered section/subsection/subsubsection. Bare section-level prose retains its own counter when child sections begin. Source file, inclusive approximate line span, and the first 12 whitespace-separated opening source tokens identify each unit. LaTeX symbols/citations may remain in fingerprints to improve source search. For prose units shorter than eight tokens, the complete opening is used and listed in coverage_validation.json. IDs are fixed to this snapshot; future edits should match ID + fingerprint + source, not renumber the entire ledger.

Exclusions: title/author disclosures, keywords/JEL, contents, headings, references, appendix prose, standalone equations, equation content within prose units, all tables, notes, figures, captions and bibliography entries. Captions were screened: none contains unusually substantial argumentative prose requiring a separate row. Appendix files were inspected only for dependency closure, not classified or evaluated.

## Absolute substantive locks

No assessment or change to specifications, estimator choice, identification, integration orders, cointegration, breaks, thresholds, Monte Carlo inference, estimates, SEs, statistics, numerical values, equations, derivations, propositions, formal claims, figures/tables/data, stock construction, GPIM, historical or causal claims, theory, center–periphery architecture, choice of technique, theta/mu interpretation, Okishio/Vidal/Prebisch/Kaldor frameworks, citations, bibliography, or references. No fact-checking, external literature search, citation addition/removal/relocation, or new estimator/model/history recommendation. Existing author-written future-work proposals are preserved as existing content, not proposed by this diagnosis. A KEEP may retain issue codes when meaning-drift risk outweighs stylistic gain.

All later operations are proposals only. No replacement sentences or revised paragraphs are supplied. A compression recommendation must preserve the claim even when deleting its duplicated certification; it cannot weaken or strengthen uncertainty or causality. Citations remain locked in place. Historical violence, class agency, dead labor, and theoretical metaphors are not defects merely because they are forceful.

## Benchmarks and method

Primary: Section 6, especially its reports/produces opening and estimate → economic mechanism sequence. Secondary: Section 1 on observed output/unobserved capacity, the three conventional treatments, and the Chapter 1 bridge. Technical sections retain their technical register. No journal template, word limit, AI detector, provenance inference, or aesthetic score was used. Automated extraction and lexical counts support a contextual, paragraph-specific editorial reading; keyword matches did not assign statuses.

Blocks A–D were read and classified sequentially. After each block the CSV/Markdown ledger was saved, unique IDs validated, and hashes checked. progress.jsonl records 95, 169, 248, and 267 completed units. baseline.json snapshots 155 pre-existing chapter files outside environment/build internals, including all active sources, bibliography, tables, figures, PDFs, and build-context files. No original file in that snapshot changed.

## Skills and precedence

The prose-register-critic skill supplied a narrow scaffolding/register lens; econ-write supplied mechanics only; the repository political-economy/UMass guidance supplied the framing constraint. The PDF skill was used only for two context pages. The user request overrides skill instructions to purge prose, impose neutral vocabulary, produce referee perspectives/scores, audit economics, add literature, or write outside this diagnostic directory. No such wider workflow was run and no agents were spawned. The latest explicit artifact location overrides the general reports-directory convention. Vault notes and maps were untouched.

## Issue codes

- **SCF**: generic academic scaffolding / metadiscourse.
- **CERT**: repeated certification or evidentiary self-congratulation.
- **CONTR**: unnecessary binary contrast.
- **INT**: adjectival or adverbial intensification.
- **ABSN**: abstract-noun stacking.
- **RHYTH**: overly regular sentence/paragraph cadence.
- **TMPL**: templated empirical paragraph architecture.
- **REP**: redundant nearby restatement.
- **FIG**: generic figure/table narration.
- **VOICE**: abrupt authorial-register discontinuity.
- **META**: unnecessary reader instruction.
- **QUAL**: excessive defensive qualification.
- **MET**: metaphor density / rhetorical overheating.
- **TERM**: conceptual terminology overloaded into one sentence.
- **SYN**: syntax/grammar obstructing reading.
- **TYPO**: obvious typographic/mechanical defect.

SYN/TYPO are copyediting observations, not stylistic AI-trace findings. No new codes were added.

## Status, risk and priority

KEEP protects working prose or consequential wording; LIGHT permits local repair; COMPRESS targets duplicate or non-substantive framing; REWRITE is sparse and preserves the full claim set; DELETE-SCAFFOLD is confined to a content-free sentence. HIGH risk protects estimates, causal interpretation, formal mappings, and attribution. MEDIUM concerns substantive navigation or removable implementation vocabulary. LOW is limited to simple navigation/scaffold. P0 = no edit/benchmark; P1 = highest-value architectural/compression intervention; P2 = useful local intervention; P3 = optional cleanup. Actual row values govern.

## Deviations and limits

No substantive or Git deviation. Supporting scripts, inventories, hashes, decisions, validation files, and two PDF context images are additional diagnostic artifacts inside the authorized folder. Very short list/continuation units cannot supply eight words; their full openings are preserved. The inventory is based on LaTeX source paragraph boundaries, not PDF block detection. The source snapshot is the coverage denominator. The one high-risk ambiguous passage (CH2-S04.05.02-P006) remains KEEP with an explicit author-dependent hold; this does not block completion of Phase 1. No Phase 2 work was begun.
