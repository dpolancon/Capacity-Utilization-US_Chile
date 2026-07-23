from __future__ import annotations

from pathlib import Path

import pandas as pd

from s34r_common import CSV_DIR, DISCOVERY_JSON, REPO_ROOT, decision_file, ensure_dirs, rel, save_json, sha256_file, write_csv


def first_existing(candidates: list[str]) -> str | None:
    for item in candidates:
        if (REPO_ROOT / item).exists():
            return item
    return None


ensure_dirs()

required = {
    "s34_integration": "output/S34_pre_regression/us_s34_variable_menu_integration_ledger.csv",
    "s34_interaction": "output/S34_pre_regression/us_s34_interaction_i2_risk_ledger.csv",
    "s34_relation": "output/S34_pre_regression/us_s34_candidate_level_relation_ledger.csv",
    "s34_design": "output/S34_pre_regression/us_s34_collinearity_design_ledger.csv",
    "s34_memo": "output/S34_pre_regression/us_s34_pre_regression_admissibility_memo.md",
    "s31i_panel": "data/processed/us_s31i/us_s31i_candidate_audit_panel.csv",
    "d06_capacity": "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_capacity_refrozen_panel.csv",
    "d06_asset": "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_asset_refrozen_gpim_panel.csv",
    "d06_investment": "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_real_investment_guardian_panel.csv",
    "d06_checks": "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/csv/D06_validation_checks.csv",
    "d06_report": "output/US/D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN/reports/D06_decision_report.md",
    "d07_wide": "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv/D07_level_accounting_panel_wide.csv",
    "d07_long": "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv/D07_level_accounting_panel_long.csv",
    "d07_dictionary": "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv/D07_variable_dictionary.csv",
    "d07_checks": "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv/D07_validation_checks.csv",
    "d07_report": "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/reports/D07_decision_report.md",
}

optional = {
    "s35_review": "output/S35_specification_review/us_s35_specification_review_ledger.csv",
    "s35_design": "output/S35_specification_review/us_s35_design_diagnostics_ledger.csv",
}

rows = []
selected_paths = {}
for object_id, candidate in {**required, **optional}.items():
    path = REPO_ROOT / candidate
    exists = path.exists()
    selected = exists and object_id in required
    selected_paths[object_id] = candidate if exists else ""
    rows.append(
        {
            "object_id": object_id,
            "candidate_path": candidate,
            "exists": exists,
            "role": "required_input" if object_id in required else "optional_context",
            "selected": selected,
            "reason": "required by S34R gate" if object_id in required else "optional S35 context",
            "sha256_if_exists": sha256_file(path) if exists and path.is_file() else "",
            "notes": "",
        }
    )

d07_dir = REPO_ROOT / "output/US/D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION/csv"
rows.append(
    {
        "object_id": "d07_csv_directory",
        "candidate_path": rel(d07_dir),
        "exists": d07_dir.exists(),
        "role": "required_input_directory",
        "selected": d07_dir.exists(),
        "reason": "D07 consumption directory required by S34R",
        "sha256_if_exists": "",
        "notes": f"{len(list(d07_dir.glob('*.csv'))) if d07_dir.exists() else 0} csv files",
    }
)

if (REPO_ROOT / required["d07_wide"]).exists():
    d07 = pd.read_csv(REPO_ROOT / required["d07_wide"], nrows=1)
    for object_id, col in {
        "real_output_y_source": "Y_REAL_NFC_GVA_BASELINE",
        "omega_NFC_source": "NFC_COMPENSATION_SHARE_GVA",
        "omega_CORP_source": "CORP_COMPENSATION_SHARE_GVA",
    }.items():
        rows.append(
            {
                "object_id": object_id,
                "candidate_path": required["d07_wide"],
                "exists": col in d07.columns,
                "role": "repaired_candidate_panel_source",
                "selected": col in d07.columns,
                "reason": f"D07 column `{col}` is the repaired source object.",
                "sha256_if_exists": sha256_file(REPO_ROOT / required["d07_wide"]),
                "notes": col,
            }
        )

ledger = pd.DataFrame(rows)
write_csv(ledger, CSV_DIR / "S34R_input_discovery_ledger.csv")
save_json(selected_paths, DISCOVERY_JSON)

required_ok = ledger.loc[ledger["role"].isin(["required_input", "required_input_directory"]), "exists"].all()
source_ok = ledger.loc[ledger["object_id"].isin(["real_output_y_source", "omega_NFC_source"]), "exists"].all()
decision = "PASS_INPUT_DISCOVERY" if required_ok and source_ok else "BLOCK_MISSING_REQUIRED_INPUTS"
decision_file(decision, "S34R_gate0_input_discovery_decision.txt")
print(decision)

