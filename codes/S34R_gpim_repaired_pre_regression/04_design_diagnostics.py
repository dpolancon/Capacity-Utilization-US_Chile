from __future__ import annotations

import pandas as pd

from s34r_common import CSV_DIR, decision_file, design_diagnostics, ensure_dirs, read_csv, write_csv


ensure_dirs()
panel = read_csv(CSV_DIR / "S34R_repaired_candidate_panel.csv")
integration = read_csv(CSV_DIR / "S34R_repaired_integration_order_ledger.csv")

class_of = dict(zip(integration["variable_name"], integration["classification"]))

rows = []
def add_interaction(object_id, object_type, variables, classification, notes):
    rows.append({
        "object_id": object_id,
        "object_type": object_type,
        "variables_used": " + ".join(variables),
        "classification": classification,
        "notes": notes,
    })

add_interaction("k_Kcap_times_omega_NFC", "raw_level_interaction", ["k_Kcap", "omega_NFC"], "BLOCK_STANDARD_I2_RISK", "Raw level interaction involving I(1) capital and bounded-persistent state remains blocked.")
add_interaction("k_Kcap_times_q_proxy", "raw_level_interaction", ["k_Kcap", "q_proxy_if_retained"], "BLOCK_STANDARD_I2_RISK", "Raw k*q proxy interaction remains outside standard grid.")
add_interaction("q_proxy_squared", "power", ["q_proxy_if_retained"], "CPR_EXPERIMENT_ONLY", "Polynomial mechanization proxy routes to CPR/polynomial layer.")
add_interaction("omega_NFC_squared", "power", ["omega_NFC"], "CPR_EXPERIMENT_ONLY", "Bounded persistent wage-share polynomial is not standard grid.")
add_interaction("q_proxy_times_omega_NFC", "raw_level_interaction", ["q_proxy_if_retained", "omega_NFC"], "CPR_EXPERIMENT_ONLY", "Raw q*omega is overloaded and not theta recovery.")
for obj in ["Q_omega", "Q_MEshare", "Q_q_if_retained"]:
    cls = class_of.get(obj, "NOT_CONSTRUCTED")
    if obj == "Q_q_if_retained":
        status = "STALE_BLOCKED" if cls != "I1" else "AUTHORIZE_STANDARD_IF_I1"
    elif cls == "I1":
        status = "AUTHORIZE_STANDARD_IF_I1"
    elif cls == "I2_RISK":
        status = "BLOCK_STANDARD_I2_RISK"
    elif cls == "DIAGNOSTIC_ONLY":
        status = "DIAGNOSTIC_ONLY"
    else:
        status = "NOT_CONSTRUCTED"
    add_interaction(obj, "accumulated_weighted_path", [obj], status, f"Repaired integration classification: {cls}.")
interaction_ledger = pd.DataFrame(rows)
write_csv(interaction_ledger, CSV_DIR / "S34R_repaired_interaction_i2_risk_ledger.csv")

design_specs = {
    "DES0_kcap": ["k_Kcap"],
    "DES1_kcap_Qomega": ["k_Kcap", "Q_omega"],
    "DES2_kcap_QMEshare": ["k_Kcap", "Q_MEshare"],
    "DES3_kcap_QMEshare_omega": ["k_Kcap", "Q_MEshare", "omega_NFC"],
    "DES4_kcap_Qomega_omega": ["k_Kcap", "Q_omega", "omega_NFC"],
    "DES5_kME_kNRC": ["k_ME", "k_NRC"],
    "DES6_kcap_Qomega_QMEshare": ["k_Kcap", "Q_omega", "Q_MEshare"],
}
design_ledger = pd.DataFrame([
    design_diagnostics(panel, design_id, vars_) for design_id, vars_ in design_specs.items()
])
write_csv(design_ledger, CSV_DIR / "S34R_repaired_design_diagnostics_ledger.csv")

interaction_decision = "BLOCK_STANDARD_GRID_PENDING_I2_RISK_REVIEW" if interaction_ledger["classification"].isin(["BLOCK_STANDARD_I2_RISK", "STALE_BLOCKED"]).any() else "PASS_REPAIRED_INTERACTION_RISK_GATE"
design_decision = "HOLD_FOR_DESIGN_REVIEW" if design_ledger["allowed_status"].isin(["SEVERE_FRAGILITY", "WARNING_FRAGILITY", "WARNING_HIGH_PAIRWISE_CORRELATION"]).any() else "PASS_DESIGN_DIAGNOSTICS"
decision_file(interaction_decision, "S34R_gate4_interaction_risk_decision.txt")
decision_file(design_decision, "S34R_gate5_design_diagnostics_decision.txt")
print(interaction_decision)
print(design_decision)

