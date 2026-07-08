from __future__ import annotations

import subprocess

import pandas as pd

from s34r_common import CODE_DIR, CSV_DIR, REPO_ROOT, decision_file, ensure_dirs, read_csv


ensure_dirs()
helper = CODE_DIR / "run_atsa_coint_test.R"
try:
    subprocess.run(["Rscript", str(helper), str(REPO_ROOT)], cwd=REPO_ROOT, check=True)
except subprocess.CalledProcessError as exc:
    raise SystemExit(f"aTSA residual cointegration gate failed: {exc}")

ledger = read_csv(CSV_DIR / "S34R_residual_cointegration_eg_ledger.csv")
design = read_csv(CSV_DIR / "S34R_repaired_design_diagnostics_ledger.csv")
primary = ledger[ledger["test_type"].astype(str).str.lower().eq("type1")].copy()
core_pass = primary[
    primary["model_id"].isin(["EG0", "EG1", "EG2", "EG3", "EG4"])
    & primary["eg_classification"].isin(["EG_PASS_STRONG", "EG_PASS_WEAK"])
]
severe_designs = set(design.loc[design["allowed_status"].eq("SEVERE_FRAGILITY"), "design_id"])
model_design = {
    "EG0": "DES0_kcap",
    "EG1": "DES5_kME_kNRC",
    "EG2": "DES2_kcap_QMEshare",
    "EG3": "DES1_kcap_Qomega",
    "EG4": "DES6_kcap_Qomega_QMEshare",
}
non_severe_core_pass = [
    row for _, row in core_pass.iterrows()
    if model_design.get(row["model_id"], "") not in severe_designs
]
if non_severe_core_pass:
    decision = "PASS_RESIDUAL_COINTEGRATION_GATE"
elif core_pass.empty:
    decision = "BLOCK_ESTIMATOR_REFREEZE_PENDING_RESIDUAL_COINTEGRATION_FAIL"
else:
    decision = "HOLD_FOR_SPECIFICATION_REVIEW"
decision_file(decision, "S34R_gate6_residual_cointegration_decision.txt")
print(decision)

