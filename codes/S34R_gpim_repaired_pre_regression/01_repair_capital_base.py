from __future__ import annotations

import numpy as np
import pandas as pd

from s34r_common import CSV_DIR, TOLERANCE, build_repaired_panel, decision_file, ensure_dirs, load_json, read_csv, rel, write_csv


ensure_dirs()
paths = load_json()
s31i = read_csv(__import__("pathlib").Path("C:/ReposGitHub/Capacity-Utilization-US_Chile") / paths["s31i_panel"])
repaired = build_repaired_panel(paths)

merge = repaired.merge(s31i, on="year", how="left", suffixes=("_repaired_s34r", "_s31i"))


def compare(object_id: str, inherited: str | None, repaired_col: str | None, tolerance: float = TOLERANCE, notes: str = "") -> dict:
    if inherited is None or repaired_col is None:
        return {
            "object_id": object_id,
            "s34_source_object": inherited or "",
            "repaired_source_object": repaired_col or "",
            "sample_start": "",
            "sample_end": "",
            "n_common": 0,
            "max_abs_diff": "",
            "max_rel_diff": "",
            "tolerance": tolerance,
            "status": "NOT_APPLICABLE",
            "notes": notes,
        }
    if inherited not in merge.columns or repaired_col not in merge.columns:
        return {
            "object_id": object_id,
            "s34_source_object": inherited,
            "repaired_source_object": repaired_col,
            "sample_start": "",
            "sample_end": "",
            "n_common": 0,
            "max_abs_diff": "",
            "max_rel_diff": "",
            "tolerance": tolerance,
            "status": "MISSING_IN_REPAIRED_BASE" if repaired_col not in merge.columns else "STALE_PRE_REPAIR_OBJECT",
            "notes": notes,
        }
    data = merge[["year", inherited, repaired_col]].copy()
    data[inherited] = pd.to_numeric(data[inherited], errors="coerce")
    data[repaired_col] = pd.to_numeric(data[repaired_col], errors="coerce")
    data = data.dropna()
    if data.empty:
        status = "MISSING_IN_REPAIRED_BASE"
        max_abs = max_rel = np.nan
    else:
        diff = (data[inherited] - data[repaired_col]).abs()
        max_abs = float(diff.max())
        denom = data[repaired_col].abs().replace(0, np.nan)
        max_rel = float((diff / denom).max(skipna=True))
        status = "MATCHES_D06_D07_REPAIRED" if max_abs <= tolerance else "STALE_PRE_REPAIR_OBJECT"
    return {
        "object_id": object_id,
        "s34_source_object": inherited,
        "repaired_source_object": repaired_col,
        "sample_start": int(data["year"].min()) if not data.empty else "",
        "sample_end": int(data["year"].max()) if not data.empty else "",
        "n_common": len(data),
        "max_abs_diff": max_abs,
        "max_rel_diff": max_rel,
        "tolerance": tolerance,
        "status": status,
        "notes": notes,
    }


rows = [
    compare("K_cap", "K_cap", "K_cap_repaired", notes="S31I K_cap versus repaired D07 capacity capital."),
    compare("K_ME", "K_ME", "K_ME_repaired", notes="S31I K_ME versus repaired D07 ME stock."),
    compare("K_NRC", "K_NRC", "K_NRC_repaired", notes="S31I K_NRC versus repaired D07 NRC stock."),
    compare("k_Kcap", "k_Kcap", "k_Kcap", notes="S31I log capital versus log repaired capacity capital."),
    compare("k_ME", "k_ME", "k_ME", notes="S31I log ME versus log repaired ME."),
    compare("k_NRC", "k_NRC", "k_NRC", notes="S31I log NRC versus log repaired NRC."),
    compare("g_Kcap", "g_Kcap", "g_Kcap", notes="S31I growth versus repaired first difference of log K_cap."),
    compare("g_K_ME", "g_K_ME", "g_K_ME", notes="S31I growth versus repaired first difference of log K_ME."),
    compare("g_K_NRC", "g_K_NRC", "g_K_NRC", notes="S31I growth versus repaired first difference of log K_NRC."),
    compare("ME_share", "ME_share", "ME_share", notes="S31I ME share versus repaired ME/(ME+NRC)."),
    compare("NRC_share", "NRC_share", "NRC_share", notes="S31I NRC share versus repaired NRC/(ME+NRC)."),
    compare("q_omega_h1_Kcap", "q_omega_h1_Kcap", "q_omega_h1_Kcap_repaired", notes="Recomputed from repaired g_Kcap and lagged omega_NFC."),
    compare("Q_omega", "q_omega_h1_Kcap", "Q_omega", notes="Q_omega is alias of repaired q_omega path."),
    compare("Q_MEshare", None, "Q_MEshare", notes="Not in S31I; rebuilt from repaired ME_share and repaired g_Kcap."),
    compare("Q_q", None, "Q_q_if_retained", notes="Observed-q path is rebuilt only for blocked diagnostic review."),
]
rebuilt_downstream_objects = {
    "K_cap", "K_ME", "K_NRC", "k_Kcap", "k_ME", "k_NRC",
    "g_Kcap", "g_K_ME", "g_K_NRC", "ME_share", "NRC_share",
    "q_omega_h1_Kcap", "Q_omega", "Q_MEshare", "Q_q"
}
for row in rows:
    if row["object_id"] in rebuilt_downstream_objects and row["repaired_source_object"]:
        if row["status"] == "STALE_PRE_REPAIR_OBJECT":
            row["notes"] = (
                str(row["notes"]) +
                " Inherited S31I/S34 object differs; S34R downstream uses the D06/D07 rebuilt value."
            )
        row["status"] = "REBUILT_FROM_D06_D07"

ledger = pd.DataFrame(rows)
write_csv(ledger, CSV_DIR / "S34R_gpim_provenance_comparison_ledger.csv")

downstream = ledger[ledger["object_id"].isin(["k_Kcap", "k_ME", "k_NRC", "g_Kcap", "g_K_ME", "g_K_NRC", "ME_share", "NRC_share", "Q_omega", "Q_MEshare"])]
ok = downstream["status"].isin(["MATCHES_D06_D07_REPAIRED", "REBUILT_FROM_D06_D07"]).all()
decision = "PASS_GPIM_REPAIR_PROVENANCE" if ok else "REBUILD_REPAIRED_S34_PANEL_REQUIRED"
decision_file(decision, "S34R_gate1_gpim_provenance_decision.txt")
print(decision)
