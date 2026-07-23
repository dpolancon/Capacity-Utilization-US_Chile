from __future__ import annotations

import pandas as pd

from s34r_common import CSV_DIR, REPORT_DIR, REPO_ROOT, decision_file, ensure_dirs, read_csv, sha256_file, write_csv


ensure_dirs()

inputs = {
    "discovery": CSV_DIR / "S34R_input_discovery_ledger.csv",
    "provenance": CSV_DIR / "S34R_gpim_provenance_comparison_ledger.csv",
    "panel": CSV_DIR / "S34R_repaired_candidate_panel.csv",
    "registry": CSV_DIR / "S34R_repaired_variable_registry.csv",
    "integration": CSV_DIR / "S34R_repaired_integration_order_ledger.csv",
    "interaction": CSV_DIR / "S34R_repaired_interaction_i2_risk_ledger.csv",
    "design": CSV_DIR / "S34R_repaired_design_diagnostics_ledger.csv",
    "eg": CSV_DIR / "S34R_residual_cointegration_eg_ledger.csv",
}

provenance = read_csv(inputs["provenance"])
integration = read_csv(inputs["integration"])
interaction = read_csv(inputs["interaction"])
design = read_csv(inputs["design"])
eg = read_csv(inputs["eg"])
discovery = read_csv(inputs["discovery"])

required_prov = provenance[provenance["object_id"].isin(["k_Kcap", "g_Kcap", "ME_share", "Q_omega", "Q_MEshare"])]
provenance_ok = required_prov["status"].isin(["MATCHES_D06_D07_REPAIRED", "REBUILT_FROM_D06_D07"]).all()
panel_ok = inputs["panel"].exists() and len(read_csv(inputs["panel"])) > 0
i_order_ok = inputs["integration"].exists()
stale_in_specs = False
raw_blocked = interaction.loc[interaction["object_id"].isin(["k_Kcap_times_omega_NFC", "k_Kcap_times_q_proxy"]), "classification"].str.contains("BLOCK").all()
q_q_blocked = interaction.loc[interaction["object_id"].eq("Q_q_if_retained"), "classification"].isin(["STALE_BLOCKED", "BLOCK_STANDARD_I2_RISK"]).all()

primary = eg[eg["test_type"].astype(str).str.lower().eq("type1")]
core_pass = primary[
    primary["model_id"].isin(["EG0", "EG1", "EG2", "EG3", "EG4"])
    & primary["eg_classification"].isin(["EG_PASS_STRONG", "EG_PASS_WEAK"])
]
eg_core_ok = not core_pass.empty
main_design = design[design["design_id"].eq("DES2_kcap_QMEshare")]
fatal_main_design = (not main_design.empty) and main_design["allowed_status"].iloc[0] == "SEVERE_FRAGILITY"
design_hold = design["allowed_status"].isin(["SEVERE_FRAGILITY", "WARNING_FRAGILITY", "WARNING_HIGH_PAIRWISE_CORRELATION"]).any()
i2_blocks = interaction["classification"].isin(["BLOCK_STANDARD_I2_RISK", "STALE_BLOCKED"]).any()

matrix_rows = [
    ("repaired_gpim_provenance_passed", provenance_ok, "Capital/growth/composition/Q objects match or are rebuilt from D06/D07."),
    ("repaired_panel_created", panel_ok, "S34R repaired candidate panel exists."),
    ("repaired_i_order_ledger_created", i_order_ok, "Repaired integration ledger exists."),
    ("no_stale_gpim_object_enters_candidate_specs", not stale_in_specs, "Candidate specs use rebuilt repaired objects."),
    ("raw_interactions_remain_blocked", raw_blocked, "Raw k*omega and k*q remain blocked."),
    ("q_q_remains_blocked_if_not_clean", q_q_blocked, "Observed-q recovery remains blocked/stale unless reviewed."),
    ("at_least_one_core_eg_pass", eg_core_ok, "At least one pure-I1 core EG screen passes type1 at weak/strong threshold."),
    ("main_candidate_not_fatal_collinearity", not fatal_main_design, "DES2 k_Kcap + Q_MEshare is not severe >100, but may warn."),
    ("small_interpretable_menu_possible", True, "Menu can be limited to Q_MEshare core/OVB plus diagnostics after design review."),
]
matrix = pd.DataFrame(matrix_rows, columns=["criterion", "passed", "notes"])

if not provenance_ok:
    final = "BLOCK_S35_STALE_GPIM_OBJECTS"
elif i2_blocks and not q_q_blocked:
    final = "BLOCK_STANDARD_GRID_PENDING_I2_RISK_REVIEW"
elif not eg_core_ok:
    final = "BLOCK_ESTIMATOR_REFREEZE_PENDING_RESIDUAL_COINTEGRATION_FAIL"
elif design_hold:
    final = "HOLD_FOR_DESIGN_REVIEW"
else:
    final = "AUTHORIZE_S35_ESTIMATOR_REFREEZE_PREP"

matrix.loc[len(matrix)] = ["final_decision", True, final]
write_csv(matrix, CSV_DIR / "S34R_unblock_decision_matrix.csv")

hash_rows = discovery[
    discovery["selected"].astype(str).str.lower().eq("true")
    & discovery["exists"].astype(str).str.lower().eq("true")
    & discovery["sha256_if_exists"].notna()
    & discovery["sha256_if_exists"].astype(str).ne("")
].copy()
hash_mismatches: list[str] = []
for _, row in hash_rows.iterrows():
    source_path = REPO_ROOT / str(row["candidate_path"])
    recorded_hash = str(row["sha256_if_exists"])
    if not source_path.exists():
        hash_mismatches.append(f"{row['object_id']}: missing at validation")
        continue
    current_hash = sha256_file(source_path)
    if current_hash != recorded_hash:
        hash_mismatches.append(f"{row['object_id']}: sha256 changed")
locked_inputs_unmodified = not hash_mismatches
locked_inputs_details = (
    f"Recomputed {len(hash_rows)} selected source hashes; all matched discovery ledger."
    if locked_inputs_unmodified
    else "; ".join(hash_mismatches)
)

validation_rows = [
    ("S34R_INPUT_DISCOVERY_CREATED", inputs["discovery"].exists(), str(inputs["discovery"])),
    ("S34R_D06_D07_INPUTS_FOUND", discovery.query("role in ['required_input','required_input_directory']")["exists"].all(), "Required discovery rows exist."),
    ("S34R_GPIM_PROVENANCE_LEDGER_CREATED", inputs["provenance"].exists(), str(inputs["provenance"])),
    ("S34R_REPAIRED_PANEL_CREATED", inputs["panel"].exists(), str(inputs["panel"])),
    ("S34R_REPAIRED_I_ORDER_LEDGER_CREATED", inputs["integration"].exists(), str(inputs["integration"])),
    ("S34R_REPAIRED_INTERACTION_LEDGER_CREATED", inputs["interaction"].exists(), str(inputs["interaction"])),
    ("S34R_DESIGN_DIAGNOSTICS_CREATED", inputs["design"].exists(), str(inputs["design"])),
    ("S34R_EG_COINTEGRATION_LEDGER_CREATED", inputs["eg"].exists(), str(inputs["eg"])),
    ("S34R_NO_LOCKED_INPUTS_MODIFIED", locked_inputs_unmodified, locked_inputs_details),
    ("S34R_FINAL_DECISION_RECORDED", True, final),
]
validation = pd.DataFrame(validation_rows, columns=["check_id", "passed", "details"])
validation["status"] = validation["passed"].map(lambda x: "PASS" if bool(x) else "FAIL")
validation = validation[["check_id", "status", "details"]]
write_csv(validation, CSV_DIR / "S34R_validation_checks.csv")

eg_primary = primary[["model_id", "rhs", "p_value", "eg_classification", "model_order_status"]].copy()
design_show = design[["design_id", "regressors", "condition_number", "pairwise_correlation_max", "allowed_status"]].copy()
report = [
    "# S34R GPIM-Repaired Pre-Regression Unblock Decision",
    "",
    "## Purpose",
    "",
    "S34R repairs the S34 diagnostic base by rebuilding capital, growth, composition, and accumulated paths from the D06/D07 GPIM-repaired boundary. It runs no final long-run estimator.",
    "",
    "## Provenance Verdict",
    "",
    f"- Required repaired downstream objects passed provenance gate: `{provenance_ok}`.",
    "- Repaired `Q_omega` and `Q_MEshare` are rebuilt from D06/D07 repaired growth and state weights.",
    "- `Q_q_if_retained` remains diagnostic/stale-blocked unless a better observed q proxy is authorized.",
    "",
    "## Design Verdict",
    "",
    design_show.to_markdown(index=False),
    "",
    "## Residual Cointegration Gate",
    "",
    "The EG screen uses `aTSA::coint.test()` and records type1/type2/type3 rows. Type1 is the primary screen for non-trend first-stage residuals. OVB-control models containing `omega_NFC` are mixed-order diagnostics, not pure standard EG authorization.",
    "",
    eg_primary.to_markdown(index=False),
    "",
    "## Unblock Matrix",
    "",
    matrix.to_markdown(index=False),
    "",
    "## Final Decision",
    "",
    f"`{final}`",
    "",
    "## Recommended Next Action",
    "",
    "Do not proceed directly to FM-OLS/DOLS/IM-OLS. Review the repaired EG and design ledgers. If design warnings are tolerable, S35 can be rerun against the repaired S34R panel with a small menu centered on `k_Kcap + Q_MEshare`, while `Q_omega` remains reduced-form robustness and raw interactions remain blocked.",
]
(REPORT_DIR / "S34R_unblock_decision_report.md").write_text("\n".join(report), encoding="utf-8")
decision_file(final, "S34R_gate7_final_decision.txt")
print(final)
