from __future__ import annotations

import math

import numpy as np
import pandas as pd
from statsmodels.tsa.stattools import adfuller, kpss

from s34r_common import CSV_DIR, classify_i_order, decision_file, ensure_dirs, longest_block, read_csv, write_csv


ensure_dirs()
panel = read_csv(CSV_DIR / "S34R_repaired_candidate_panel.csv")
registry = read_csv(CSV_DIR / "S34R_repaired_variable_registry.csv")

try:
    from arch.unitroot import PhillipsPerron
    ARCH_AVAILABLE = True
except Exception:
    ARCH_AVAILABLE = False


def safe_adf(values: np.ndarray) -> float:
    try:
        return float(adfuller(values, autolag="AIC")[1])
    except Exception:
        return math.nan


def safe_kpss(values: np.ndarray) -> float:
    try:
        return float(kpss(values, regression="c", nlags="auto")[1])
    except Exception:
        return math.nan


def safe_pp(values: np.ndarray) -> float:
    if not ARCH_AVAILABLE:
        return math.nan
    try:
        return float(PhillipsPerron(values).pvalue)
    except Exception:
        return math.nan


rows = []
for _, meta in registry.iterrows():
    name = meta["variable_name"]
    if name not in panel.columns:
        tests = {
            "n_obs": 0, "sample_start": "", "sample_end": "",
            "adf_level_p": math.nan, "adf_diff_p": math.nan,
            "kpss_level_p": math.nan, "kpss_diff_p": math.nan,
            "pp_level_p_if_available": math.nan, "pp_diff_p_if_available": math.nan,
            "adf_second_diff_p": math.nan, "kpss_second_diff_p": math.nan,
        }
        classification = "STALE_BLOCKED" if "Q_q" in name else "DIAGNOSTIC_ONLY"
    else:
        block = longest_block(panel, [name])
        values = block[name].to_numpy(dtype=float) if not block.empty else np.array([])
        d1 = np.diff(values)
        d2 = np.diff(values, n=2)
        tests = {
            "n_obs": len(values),
            "sample_start": int(block["year"].min()) if len(values) else "",
            "sample_end": int(block["year"].max()) if len(values) else "",
            "adf_level_p": safe_adf(values) if len(values) >= 12 and np.nanstd(values) > 0 else math.nan,
            "adf_diff_p": safe_adf(d1) if len(d1) >= 12 and np.nanstd(d1) > 0 else math.nan,
            "kpss_level_p": safe_kpss(values) if len(values) >= 12 and np.nanstd(values) > 0 else math.nan,
            "kpss_diff_p": safe_kpss(d1) if len(d1) >= 12 and np.nanstd(d1) > 0 else math.nan,
            "pp_level_p_if_available": safe_pp(values) if len(values) >= 12 and np.nanstd(values) > 0 else math.nan,
            "pp_diff_p_if_available": safe_pp(d1) if len(d1) >= 12 and np.nanstd(d1) > 0 else math.nan,
            "adf_second_diff_p": safe_adf(d2) if len(d2) >= 12 and np.nanstd(d2) > 0 else math.nan,
            "kpss_second_diff_p": safe_kpss(d2) if len(d2) >= 12 and np.nanstd(d2) > 0 else math.nan,
        }
        classification = classify_i_order(name, tests)
        if name == "Q_q_if_retained" and classification != "I1":
            classification = "STALE_BLOCKED"
    rows.append(
        {
            "variable_name": name,
            "source_file": meta["source_file"],
            "construction_rule": meta["construction_rule"],
            "theoretical_role": meta["theoretical_role"],
            **tests,
            "classification": classification,
        "notes": (
            "" if pd.isna(meta.get("notes", "")) else str(meta.get("notes", ""))
        ) + ("" if ARCH_AVAILABLE else " PP unavailable: Python arch package not installed."),
        }
    )

ledger = pd.DataFrame(rows)
write_csv(ledger, CSV_DIR / "S34R_repaired_integration_order_ledger.csv")
decision = "BLOCK_I2_RISK_REVIEW_REQUIRED" if (ledger["classification"] == "I2_RISK").any() else "PASS_REPAIRED_I_ORDER_LEDGER"
decision_file(decision, "S34R_gate3_integration_order_decision.txt")
print(decision)
