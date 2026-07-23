from __future__ import annotations

import pandas as pd

from s34r_common import CSV_DIR, build_repaired_panel, decision_file, ensure_dirs, load_json, write_csv


ensure_dirs()
paths = load_json()
panel = build_repaired_panel(paths)

keep = [
    "year", "y_t", "K_ME_repaired", "K_NRC_repaired", "K_cap_repaired",
    "k_ME", "k_NRC", "k_Kcap", "g_K_ME", "g_K_NRC", "g_Kcap",
    "ME_share", "NRC_share", "omega_NFC", "omega_CORP", "Q_omega",
    "Q_MEshare", "Q_q_if_retained", "q_proxy_if_retained",
]
panel = panel[keep]
write_csv(panel, CSV_DIR / "S34R_repaired_candidate_panel.csv")

registry_rows = [
    ("y_t", "D07:Y_REAL_NFC_GVA_BASELINE", "log real NFC GVA baseline", "effective_output_proxy", "REBUILT_FROM_D07"),
    ("K_ME_repaired", "D07:K_real_ME_refrozen", "repaired ME capacity stock", "capacity_capital_component", "REBUILT_FROM_D06_D07"),
    ("K_NRC_repaired", "D07:K_real_NRC_refrozen", "repaired NRC capacity stock", "capacity_capital_component", "REBUILT_FROM_D06_D07"),
    ("K_cap_repaired", "D07:K_real_capacity_refrozen", "ME + NRC repaired capacity stock", "capacity_capital_scale", "REBUILT_FROM_D06_D07"),
    ("k_ME", "S34R", "log K_ME_repaired", "log_capacity_component", "REBUILT_FROM_D06_D07"),
    ("k_NRC", "S34R", "log K_NRC_repaired", "log_capacity_component", "REBUILT_FROM_D06_D07"),
    ("k_Kcap", "S34R", "log K_cap_repaired", "log_capacity_capital", "REBUILT_FROM_D06_D07"),
    ("g_K_ME", "S34R", "annual first difference of k_ME", "capital_growth", "REBUILT_FROM_D06_D07"),
    ("g_K_NRC", "S34R", "annual first difference of k_NRC", "capital_growth", "REBUILT_FROM_D06_D07"),
    ("g_Kcap", "S34R", "annual first difference of k_Kcap", "capital_growth", "REBUILT_FROM_D06_D07"),
    ("ME_share", "S34R", "K_ME_repaired/(K_ME_repaired+K_NRC_repaired)", "bounded_composition_state", "REBUILT_FROM_D06_D07"),
    ("NRC_share", "S34R", "K_NRC_repaired/(K_ME_repaired+K_NRC_repaired)", "bounded_composition_state", "REBUILT_FROM_D06_D07"),
    ("omega_NFC", "D07:NFC_COMPENSATION_SHARE_GVA", "NFC wage share", "bounded_distribution_state", "REBUILT_FROM_D07"),
    ("omega_CORP", "D07:CORP_COMPENSATION_SHARE_GVA", "corporate wage share robustness", "bounded_distribution_state", "REBUILT_FROM_D07"),
    ("Q_omega", "S34R", "cumsum(lag(omega_NFC,1) * g_Kcap)", "distribution_weighted_accumulation_path", "REBUILT_FROM_D06_D07"),
    ("Q_MEshare", "S34R", "cumsum(lag(ME_share,1) * g_Kcap)", "composition_weighted_accumulation_path", "REBUILT_FROM_D06_D07"),
    ("q_proxy_if_retained", "S34R", "annual first difference of ME_share", "diagnostic_observed_q_proxy", "DIAGNOSTIC_ONLY"),
    ("Q_q_if_retained", "S34R", "cumsum(lag(q_proxy_if_retained,1) * g_Kcap)", "observed_q_weighted_path", "STALE_BLOCKED_UNLESS_REVIEWED"),
]
registry = pd.DataFrame(
    registry_rows,
    columns=["variable_name", "source_file", "construction_rule", "theoretical_role", "repair_status"],
)
registry["notes"] = registry["variable_name"].map(
    {
        "Q_q_if_retained": "Preserved for blocked diagnostic review only; not standard-grid authorized.",
        "omega_NFC": "Bounded-persistent OVB-control candidate, not direct theta recovery.",
        "Q_MEshare": "Mechanization-composition accumulated path; preferred theta-recovery candidate if design gates pass.",
        "Q_omega": "Reduced-form distribution-conditioned path; not direct mechanization composition.",
    }
).fillna("")
write_csv(registry, CSV_DIR / "S34R_repaired_variable_registry.csv")

required = ["year", "y_t", "k_Kcap", "g_Kcap", "ME_share", "omega_NFC", "Q_omega", "Q_MEshare"]
complete = all(col in panel.columns and panel[col].notna().sum() > 0 for col in required)
decision = "PASS_REPAIRED_PANEL_CREATED" if complete else "BLOCK_REPAIRED_PANEL_INCOMPLETE"
decision_file(decision, "S34R_gate2_repaired_panel_decision.txt")
print(decision)

