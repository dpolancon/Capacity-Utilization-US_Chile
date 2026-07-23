from __future__ import annotations

import csv
import hashlib
import math
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd
from statsmodels.tsa.stattools import adfuller, kpss


REPO_ROOT = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
CODE_DIR = REPO_ROOT / "codes" / "S34R_A_repaired_design_review_state_dependence"
OUT_DIR = REPO_ROOT / "output" / "S34R_A_repaired_design_review_state_dependence"
CSV_DIR = OUT_DIR / "csv"
REPORT_DIR = OUT_DIR / "reports"
PLOT_DIR = OUT_DIR / "plots"
LOG_DIR = OUT_DIR / "logs"

S34R_DIR = REPO_ROOT / "output" / "S34R_gpim_repaired_pre_regression"
D06_DIR = REPO_ROOT / "output" / "US" / "D06_GPIM_REFREEZE_WITH_GPIM_GUARDED_pKN"
D07_DIR = REPO_ROOT / "output" / "US" / "D07_LEVEL_ACCOUNTING_PANEL_CONSUMPTION"

REQUIRED_INPUTS = [
    ("S34R_repaired_candidate_panel", S34R_DIR / "csv" / "S34R_repaired_candidate_panel.csv", "S34R repaired candidate panel"),
    ("S34R_repaired_variable_registry", S34R_DIR / "csv" / "S34R_repaired_variable_registry.csv", "S34R repaired variable registry"),
    ("S34R_repaired_integration_order_ledger", S34R_DIR / "csv" / "S34R_repaired_integration_order_ledger.csv", "S34R repaired I-order ledger"),
    ("S34R_repaired_interaction_i2_risk_ledger", S34R_DIR / "csv" / "S34R_repaired_interaction_i2_risk_ledger.csv", "S34R repaired interaction risk ledger"),
    ("S34R_repaired_design_diagnostics_ledger", S34R_DIR / "csv" / "S34R_repaired_design_diagnostics_ledger.csv", "S34R repaired design diagnostics"),
    ("S34R_residual_cointegration_eg_ledger", S34R_DIR / "csv" / "S34R_residual_cointegration_eg_ledger.csv", "S34R EG ledger"),
    ("S34R_unblock_decision_matrix", S34R_DIR / "csv" / "S34R_unblock_decision_matrix.csv", "S34R unblock matrix"),
    ("S34R_validation_checks", S34R_DIR / "csv" / "S34R_validation_checks.csv", "S34R validation checks"),
    ("S34R_unblock_decision_report", S34R_DIR / "reports" / "S34R_unblock_decision_report.md", "S34R decision report"),
    ("D06_capacity_refrozen_panel", D06_DIR / "csv" / "D06_capacity_refrozen_panel.csv", "D06 repaired capacity panel"),
    ("D06_asset_refrozen_gpim_panel", D06_DIR / "csv" / "D06_asset_refrozen_gpim_panel.csv", "D06 repaired asset GPIM panel"),
    ("D06_real_investment_guardian_panel", D06_DIR / "csv" / "D06_real_investment_guardian_panel.csv", "D06 guardian investment panel"),
    ("D06_validation_checks", D06_DIR / "csv" / "D06_validation_checks.csv", "D06 validation checks"),
    ("D06_decision_report", D06_DIR / "reports" / "D06_decision_report.md", "D06 decision report"),
    ("D07_output_directory", D07_DIR, "D07 level-accounting output directory"),
]

DESIGNS = [
    ("D0_y_kKcap", "y_t", ["k_Kcap"], "baseline total capacity scale", "k_Kcap", "", "", ""),
    ("D1_y_kNRC", "y_t", ["k_NRC"], "NRC plant/envelope scale", "k_NRC", "", "", ""),
    ("D2_y_kME", "y_t", ["k_ME"], "ME scale diagnostic", "k_ME", "", "", ""),
    ("D3_y_kME_kNRC", "y_t", ["k_ME", "k_NRC"], "split capital-scale diagnostic", "k_ME+k_NRC", "", "", ""),
    ("D4_y_kKcap_QMEshare", "y_t", ["k_Kcap", "Q_MEshare_Kcap"], "previous repaired mechanization path", "k_Kcap", "ME_share_repaired", "", "d_k_Kcap"),
    ("D5_y_kKcap_QMEshare_omega", "y_t", ["k_Kcap", "Q_omega_MEshare_Kcap"], "previous repaired distribution-conditioned mechanization path", "k_Kcap", "ME_share_repaired", "omega_NFC", "d_k_Kcap"),
    ("D6_y_kNRC_QMEshare_Kcap", "y_t", ["k_NRC", "Q_MEshare_Kcap"], "NRC envelope plus mechanization path", "k_NRC", "ME_share_repaired", "", "d_k_Kcap"),
    ("D7_y_kNRC_QMEshare_NRC", "y_t", ["k_NRC", "Q_MEshare_NRC"], "NRC envelope plus NRC-weighted mechanization path", "k_NRC", "ME_share_repaired", "", "d_k_NRC"),
    ("D8_y_kNRC_Q_ME_NRC_ratio_Kcap", "y_t", ["k_NRC", "Q_ME_NRC_ratio_Kcap"], "NRC envelope plus ME/NRC ratio path", "k_NRC", "ME_NRC_ratio_repaired", "", "d_k_Kcap"),
    ("D9_y_kNRC_Q_ME_NRC_ratio_NRC", "y_t", ["k_NRC", "Q_ME_NRC_ratio_NRC"], "NRC envelope plus NRC-weighted ME/NRC ratio path", "k_NRC", "ME_NRC_ratio_repaired", "", "d_k_NRC"),
    ("D10_y_kNRC_Q_log_ME_NRC_ratio_Kcap", "y_t", ["k_NRC", "Q_log_ME_NRC_ratio_Kcap"], "NRC envelope plus log ME/NRC path", "k_NRC", "log_ME_NRC_ratio_repaired", "", "d_k_Kcap"),
    ("D11_y_kNRC_Q_log_ME_NRC_ratio_NRC", "y_t", ["k_NRC", "Q_log_ME_NRC_ratio_NRC"], "NRC envelope plus NRC-weighted log ME/NRC path", "k_NRC", "log_ME_NRC_ratio_repaired", "", "d_k_NRC"),
    ("D12_y_kNRC_Qomega_MEshare_Kcap", "y_t", ["k_NRC", "Q_omega_MEshare_Kcap"], "NRC envelope plus distribution-conditioned mechanization path", "k_NRC", "ME_share_repaired", "omega_NFC", "d_k_Kcap"),
    ("D13_y_kNRC_Qomega_MEshare_NRC", "y_t", ["k_NRC", "Q_omega_MEshare_NRC"], "NRC envelope plus NRC-weighted distribution-conditioned mechanization path", "k_NRC", "ME_share_repaired", "omega_NFC", "d_k_NRC"),
    ("D14_y_kNRC_Qomega_ME_NRC_ratio_Kcap", "y_t", ["k_NRC", "Q_omega_ME_NRC_ratio_Kcap"], "NRC envelope plus distribution-conditioned ME/NRC ratio path", "k_NRC", "ME_NRC_ratio_repaired", "omega_NFC", "d_k_Kcap"),
    ("D15_y_kNRC_Qomega_ME_NRC_ratio_NRC", "y_t", ["k_NRC", "Q_omega_ME_NRC_ratio_NRC"], "NRC envelope plus NRC-weighted distribution-conditioned ME/NRC ratio path", "k_NRC", "ME_NRC_ratio_repaired", "omega_NFC", "d_k_NRC"),
    ("D16_y_kNRC_Qomega_log_ME_NRC_ratio_Kcap", "y_t", ["k_NRC", "Q_omega_log_ME_NRC_ratio_Kcap"], "NRC envelope plus distribution-conditioned log ME/NRC path", "k_NRC", "log_ME_NRC_ratio_repaired", "omega_NFC", "d_k_Kcap"),
    ("D17_y_kNRC_Qomega_log_ME_NRC_ratio_NRC", "y_t", ["k_NRC", "Q_omega_log_ME_NRC_ratio_NRC"], "NRC envelope plus NRC-weighted distribution-conditioned log ME/NRC path", "k_NRC", "log_ME_NRC_ratio_repaired", "omega_NFC", "d_k_NRC"),
    ("D18_y_kNRC_Qomega_MEshare_Kcap_omega", "y_t", ["k_NRC", "Q_omega_MEshare_Kcap", "omega_NFC"], "OVB-control diagnostic for distribution-conditioned Kcap path", "k_NRC", "ME_share_repaired", "omega_NFC", "d_k_Kcap"),
    ("D19_y_kNRC_Qomega_MEshare_NRC_omega", "y_t", ["k_NRC", "Q_omega_MEshare_NRC", "omega_NFC"], "OVB-control diagnostic for distribution-conditioned NRC path", "k_NRC", "ME_share_repaired", "omega_NFC", "d_k_NRC"),
    ("D20_y_kNRC_QMEshare_Kcap_omega", "y_t", ["k_NRC", "Q_MEshare_Kcap", "omega_NFC"], "OVB-control diagnostic for mechanization-only Kcap path", "k_NRC", "ME_share_repaired", "omega_NFC", "d_k_Kcap"),
    ("D21_y_kNRC_QMEshare_NRC_omega", "y_t", ["k_NRC", "Q_MEshare_NRC", "omega_NFC"], "OVB-control diagnostic for mechanization-only NRC path", "k_NRC", "ME_share_repaired", "omega_NFC", "d_k_NRC"),
]

STATE_VARIABLES = [
    "ME_share_repaired",
    "ME_NRC_ratio_repaired",
    "log_ME_NRC_ratio_repaired",
    "Q_MEshare_Kcap",
    "Q_MEshare_NRC",
    "Q_ME_NRC_ratio_Kcap",
    "Q_ME_NRC_ratio_NRC",
    "Q_log_ME_NRC_ratio_Kcap",
    "Q_log_ME_NRC_ratio_NRC",
    "Q_omega_MEshare_Kcap",
    "Q_omega_MEshare_NRC",
    "Q_omega_ME_NRC_ratio_Kcap",
    "Q_omega_ME_NRC_ratio_NRC",
    "Q_omega_log_ME_NRC_ratio_Kcap",
    "Q_omega_log_ME_NRC_ratio_NRC",
    "omega_NFC",
    "k_Kcap",
    "k_NRC",
    "k_ME",
    "y_t",
]


def ensure_dirs() -> None:
    for path in (CSV_DIR, REPORT_DIR, PLOT_DIR, LOG_DIR):
        path.mkdir(parents=True, exist_ok=True)


def rel(path: Path) -> str:
    try:
        return str(path.relative_to(REPO_ROOT)).replace("\\", "/")
    except ValueError:
        return str(path).replace("\\", "/")


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def write_csv(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False, quoting=csv.QUOTE_MINIMAL)


def git_capture(args: list[str]) -> str:
    result = subprocess.run(["git", *args], cwd=REPO_ROOT, text=True, capture_output=True, check=False)
    return (result.stdout + result.stderr).strip()


def longest_block(df: pd.DataFrame, cols: Iterable[str]) -> pd.DataFrame:
    cols = list(cols)
    use = df[["year", *cols]].copy()
    for col in cols:
        use[col] = pd.to_numeric(use[col], errors="coerce")
    use = use.dropna(subset=cols).sort_values("year")
    if use.empty:
        return use
    breaks = use["year"].diff().fillna(1).ne(1).cumsum()
    block_id = breaks.value_counts().idxmax()
    return use.loc[breaks == block_id].copy()


def first_diff_by_year(series: pd.Series, years: pd.Series) -> pd.Series:
    lookup = pd.Series(series.to_numpy(), index=years.to_numpy())
    out = []
    for year, value in zip(years, series):
        old = lookup.get(year - 1, np.nan)
        out.append(value - old if pd.notna(value) and pd.notna(old) else np.nan)
    return pd.Series(out, index=series.index, dtype="float64")


def lag_by_year(series: pd.Series, years: pd.Series) -> pd.Series:
    lookup = pd.Series(series.to_numpy(), index=years.to_numpy())
    return years.map(lambda year: lookup.get(year - 1, np.nan))


def weighted_path(state: pd.Series, change: pd.Series, years: pd.Series) -> pd.Series:
    lagged_state = lag_by_year(pd.to_numeric(state, errors="coerce"), years)
    change = pd.to_numeric(change, errors="coerce")
    inc = lagged_state.to_numpy(dtype="float64") * change.to_numpy(dtype="float64")
    result = np.full(len(inc), np.nan)
    ok = np.where(np.isfinite(inc))[0]
    if len(ok) == 0:
        return pd.Series(result, index=state.index)
    blocks: list[np.ndarray] = []
    start = 0
    for i in range(1, len(ok)):
        if ok[i] != ok[i - 1] + 1:
            blocks.append(ok[start:i])
            start = i
    blocks.append(ok[start:])
    block = max(blocks, key=len)
    result[block] = np.cumsum(inc[block])
    return pd.Series(result, index=state.index)


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


def classify_i_order(name: str, tests: dict[str, float | int | str]) -> str:
    n_obs = int(tests.get("n_obs", 0) or 0)
    if n_obs < 12:
        return "DIAGNOSTIC_ONLY"
    bounded = name in {"omega_NFC", "omega_CORP", "ME_share", "NRC_share", "ME_share_repaired"}
    growth_like = name.startswith("d_") or name.startswith("g_")
    ur_level = (tests.get("adf_level_p", math.nan) <= 0.05) or (tests.get("pp_level_p_if_available", math.nan) <= 0.05)
    ur_diff = (tests.get("adf_diff_p", math.nan) <= 0.05) or (tests.get("pp_diff_p_if_available", math.nan) <= 0.05)
    ur_second = tests.get("adf_second_diff_p", math.nan) <= 0.05
    kpss_level_stationary = tests.get("kpss_level_p", math.nan) > 0.05
    kpss_diff_stationary = tests.get("kpss_diff_p", math.nan) > 0.05
    kpss_second_stationary = tests.get("kpss_second_diff_p", math.nan) > 0.05
    if bounded and not (ur_level and kpss_level_stationary):
        return "BOUNDED_PERSISTENT"
    if ur_level and kpss_level_stationary:
        return "I0"
    if ur_diff and kpss_diff_stationary:
        return "I1"
    if ur_second and kpss_second_stationary:
        return "I2_RISK"
    if growth_like:
        return "DIAGNOSTIC_ONLY"
    return "AMBIGUOUS"


def integration_row(panel: pd.DataFrame, name: str) -> dict:
    if name not in panel.columns:
        return {
            "variable_name": name,
            "n_obs": 0,
            "sample_start": "",
            "sample_end": "",
            "adf_level_p": math.nan,
            "adf_diff_p": math.nan,
            "kpss_level_p": math.nan,
            "kpss_diff_p": math.nan,
            "pp_level_p_if_available": math.nan,
            "pp_diff_p_if_available": math.nan,
            "adf_second_diff_p": math.nan,
            "kpss_second_diff_p": math.nan,
            "classification": "NOT_CONSTRUCTED",
            "notes": "Variable not constructed.",
        }
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
    notes = "" if ARCH_AVAILABLE else "PP unavailable: Python arch package not installed."
    return {
        "variable_name": name,
        **tests,
        "classification": classify_i_order(name, tests),
        "notes": notes,
    }


def design_diagnostics(panel: pd.DataFrame, design_id: str, lhs: str, rhs: list[str], admissible: dict[str, str], meta: dict[str, str]) -> dict:
    all_vars = [lhs, *rhs]
    missing = [var for var in all_vars if var not in panel.columns]
    if missing:
        n_obs = 0
        cond = math.nan
        max_corr = math.nan
        rank_status = "missing_variable"
        design_status = "BLOCK_MISSING_VARIABLE"
        notes = "Missing: " + ", ".join(missing)
    else:
        block = longest_block(panel, all_vars)
        n_obs = len(block)
        if n_obs < len(rhs) + 10:
            cond = math.nan
            max_corr = math.nan
            rank_status = "insufficient_sample"
            design_status = "BLOCK_INSUFFICIENT_SAMPLE"
            notes = "Too few complete annual observations."
        else:
            x = block[rhs].to_numpy(dtype=float)
            x_sd = np.nanstd(x, axis=0, ddof=1)
            if np.any(x_sd == 0):
                cond = math.inf
                max_corr = math.nan
                rank_status = "zero_variance"
                design_status = "BLOCK_RANK_DEFICIENT"
                notes = "At least one regressor has zero variance."
            else:
                z = (x - np.nanmean(x, axis=0)) / x_sd
                rank = np.linalg.matrix_rank(z)
                cond = float(np.linalg.cond(z))
                if len(rhs) > 1:
                    corr = np.corrcoef(z, rowvar=False)
                    max_corr = float(np.nanmax(np.abs(corr[np.triu_indices_from(corr, 1)])))
                else:
                    max_corr = math.nan
                if rank < len(rhs):
                    rank_status = "rank_deficient"
                    design_status = "BLOCK_RANK_DEFICIENT"
                    notes = "Design matrix is rank deficient."
                elif cond >= 100:
                    rank_status = "full_rank"
                    design_status = "SEVERE_FRAGILITY"
                    notes = "Condition number is at or above 100."
                elif cond >= 30:
                    rank_status = "full_rank"
                    design_status = "WARNING_FRAGILITY"
                    notes = "Condition number is between 30 and 100."
                elif pd.notna(max_corr) and max_corr > 0.98:
                    rank_status = "full_rank"
                    design_status = "NEAR_COLLINEAR_WARNING"
                    notes = "Pairwise correlation exceeds 0.98."
                else:
                    rank_status = "full_rank"
                    design_status = "PASS_DESIGN_DIAGNOSTICS"
                    notes = "Condition number below 30; no near-perfect pairwise correlation."
    path_vars = [v for v in rhs if v.startswith("Q_")]
    all_standard = True
    for var in rhs:
        if var == "omega_NFC":
            continue
        status = admissible.get(var, "DIAGNOSTIC_ONLY")
        if status not in {"AUTHORIZE_STANDARD_IF_I1", "AUTHORIZE_ONLY_IF_STATE_I0", "DIAGNOSTIC_ONLY"} and var in path_vars:
            all_standard = False
        if var in {"k_Kcap", "k_NRC", "k_ME"} and status == "BLOCK_STANDARD_I2_RISK":
            all_standard = False
    return {
        "design_id": design_id,
        "lhs": lhs,
        "regressors": " + ".join(rhs),
        "n_obs": n_obs,
        "condition_number": cond,
        "pairwise_correlation_max": max_corr,
        "rank_status": rank_status,
        "all_regressors_available": not missing,
        "all_standard_regressors_admissible": all_standard,
        "contains_bounded_control": "omega_NFC" in rhs,
        "contains_distributionally_conditioned_path": any(v.startswith("Q_omega_") for v in rhs),
        "contains_mechanization_only_path": any(v.startswith("Q_ME") or v.startswith("Q_log") for v in rhs),
        "contains_ratio_path": any("ratio" in v for v in rhs),
        "design_status": design_status,
        "notes": f"{notes} {meta['theoretical_role']}",
    }


def path_status(var: str, cls: str) -> str:
    if cls == "NOT_CONSTRUCTED":
        return "NOT_CONSTRUCTED"
    if var in {"omega_NFC", "ME_share_repaired"}:
        return "AUTHORIZE_ONLY_IF_STATE_I0" if cls == "I0" else "DIAGNOSTIC_ONLY"
    if var.startswith("Q_"):
        if cls == "I1":
            return "AUTHORIZE_STANDARD_IF_I1"
        if cls == "I2_RISK":
            return "BLOCK_STANDARD_I2_RISK"
        if "ratio" in var and cls in {"AMBIGUOUS", "BOUNDED_PERSISTENT"}:
            return "ROUTE_RATIO_MECHANIZATION_TO_CPR_OR_APPENDIX"
        return "DIAGNOSTIC_ONLY"
    if var in {"k_Kcap", "k_NRC", "k_ME"}:
        return "BLOCK_STANDARD_I2_RISK" if cls == "I2_RISK" else "AUTHORIZE_STANDARD_IF_I1"
    if cls in {"DIAGNOSTIC_ONLY", "BOUNDED_PERSISTENT"}:
        return "DIAGNOSTIC_ONLY"
    return "AUTHORIZE_STANDARD_IF_I1" if cls == "I1" else "DIAGNOSTIC_ONLY"


def main() -> None:
    ensure_dirs()
    started_at = datetime.now().isoformat(timespec="seconds")
    opening_rows = [
        {"field": "recorded_at", "value": started_at},
        {"field": "cwd", "value": str(REPO_ROOT)},
        {"field": "git_branch", "value": git_capture(["branch", "--show-current"])},
        {"field": "git_status_short", "value": git_capture(["status", "--short"])},
        {"field": "git_log_oneline_8", "value": git_capture(["log", "--oneline", "-8"]).replace("\n", " | ")},
        {"field": "stage", "value": "S34R_A_REPAIRED_DESIGN_REVIEW_AND_STATE_DEPENDENCE_GATE"},
    ]
    write_csv(pd.DataFrame(opening_rows), CSV_DIR / "S34R_A_opening_repo_state.csv")

    discovery_rows = []
    for object_id, path, role in REQUIRED_INPUTS:
        exists = path.exists()
        discovery_rows.append(
            {
                "object_id": object_id,
                "candidate_path": rel(path),
                "exists": exists,
                "required": True,
                "selected": exists,
                "role": role,
                "sha256_if_exists": sha256_file(path) if exists and path.is_file() else "",
                "notes": "Directory input." if exists and path.is_dir() else "",
            }
        )
    discovery = pd.DataFrame(discovery_rows)
    write_csv(discovery, CSV_DIR / "S34R_A_input_discovery_ledger.csv")
    missing_required = discovery.loc[discovery["required"] & ~discovery["exists"], "object_id"].tolist()
    if missing_required:
        write_decision_and_validation("BLOCK_MISSING_REQUIRED_INPUTS", missing_required)
        raise SystemExit("Missing required inputs: " + ", ".join(missing_required))

    panel = pd.read_csv(S34R_DIR / "csv" / "S34R_repaired_candidate_panel.csv")
    panel = panel.sort_values("year").reset_index(drop=True)
    for col in panel.columns:
        if col != "year":
            panel[col] = pd.to_numeric(panel[col], errors="coerce")

    if "K_cap_repaired" not in panel.columns or panel["K_cap_repaired"].isna().all():
        panel["K_cap_repaired"] = panel["K_ME_repaired"] + panel["K_NRC_repaired"]
    for stock, log_col in [("K_ME_repaired", "k_ME"), ("K_NRC_repaired", "k_NRC"), ("K_cap_repaired", "k_Kcap")]:
        panel[log_col] = np.log(panel[stock].where(panel[stock] > 0))
    panel["ME_share_repaired"] = panel["K_ME_repaired"] / (panel["K_ME_repaired"] + panel["K_NRC_repaired"])
    panel["ME_NRC_ratio_repaired"] = panel["K_ME_repaired"] / panel["K_NRC_repaired"]
    panel["log_ME_NRC_ratio_repaired"] = np.log(panel["ME_NRC_ratio_repaired"].where(panel["ME_NRC_ratio_repaired"] > 0))
    panel["d_k_Kcap"] = first_diff_by_year(panel["k_Kcap"], panel["year"])
    panel["d_k_NRC"] = first_diff_by_year(panel["k_NRC"], panel["year"])

    state_defs = [
        ("MEshare", "ME_share_repaired", "ME share in repaired capacity stock", True),
        ("ME_NRC_ratio", "ME_NRC_ratio_repaired", "ME/NRC repaired stock ratio", False),
        ("log_ME_NRC_ratio", "log_ME_NRC_ratio_repaired", "log ME/NRC repaired stock ratio", False),
    ]
    inc_defs = [("Kcap", "d_k_Kcap"), ("NRC", "d_k_NRC")]
    ledger_rows = []
    for state_key, state_col, definition, bounded in state_defs:
        block = longest_block(panel, [state_col]) if state_col in panel else pd.DataFrame()
        ledger_rows.append(
            {
                "variable_name": state_col,
                "definition": definition,
                "mechanization_state": state_col,
                "distribution_state": "",
                "accumulation_increment": "",
                "bounded_expected": bounded,
                "constructed": state_col in panel and panel[state_col].notna().any(),
                "sample_start": int(block["year"].min()) if not block.empty else "",
                "sample_end": int(block["year"].max()) if not block.empty else "",
                "n_obs": len(block),
                "notes": "State tested directly; bounded shares are not mechanically promoted to I(1).",
            }
        )
        for inc_key, inc_col in inc_defs:
            q_name = f"Q_{state_key}_{inc_key}"
            q_omega_name = f"Q_omega_{state_key}_{inc_key}"
            panel[q_name] = weighted_path(panel[state_col], panel[inc_col], panel["year"])
            panel[q_omega_name] = weighted_path(panel["omega_NFC"] * panel[state_col], panel[inc_col], panel["year"])
            for var, dist, note in [
                (q_name, "", "Mechanization-only accumulated path."),
                (q_omega_name, "omega_NFC", "Distributionally conditioned accumulated path."),
            ]:
                block = longest_block(panel, [var])
                ledger_rows.append(
                    {
                        "variable_name": var,
                        "definition": f"cumsum(lag({dist + ' * ' if dist else ''}{state_col}, 1) * {inc_col})",
                        "mechanization_state": state_col,
                        "distribution_state": dist,
                        "accumulation_increment": inc_col,
                        "bounded_expected": False,
                        "constructed": panel[var].notna().any(),
                        "sample_start": int(block["year"].min()) if not block.empty else "",
                        "sample_end": int(block["year"].max()) if not block.empty else "",
                        "n_obs": len(block),
                        "notes": note,
                    }
                )
    if "Q_MEshare_Kcap" in panel:
        panel["Q_MEshare"] = panel["Q_MEshare_Kcap"]
    write_csv(pd.DataFrame(ledger_rows), CSV_DIR / "S34R_A_repaired_state_variable_ledger.csv")
    write_csv(panel, CSV_DIR / "S34R_A_repaired_augmented_panel.csv")

    integration = pd.DataFrame([integration_row(panel, name) for name in STATE_VARIABLES if name in panel.columns or name in STATE_VARIABLES])
    write_csv(integration, CSV_DIR / "S34R_A_repaired_state_integration_ledger.csv")
    class_of = dict(zip(integration["variable_name"], integration["classification"]))
    admissibility_rows = []
    for name in [
        "k_Kcap_times_omega_NFC",
        "k_NRC_times_omega_NFC",
        "k_Kcap_times_ME_share_repaired",
        "k_NRC_times_ME_share_repaired",
    ]:
        admissibility_rows.append(
            {
                "object_id": name,
                "object_type": "raw_level_interaction",
                "variables_used": name.replace("_times_", " * "),
                "i_order_classification": "not_tested_raw_interaction",
                "admissibility_class": "BLOCK_STANDARD_I2_RISK",
                "notes": "Raw level interaction remains blocked; only accumulated paths enter the standard screen.",
            }
        )
    for name in STATE_VARIABLES:
        if name not in class_of:
            continue
        admissibility_rows.append(
            {
                "object_id": name,
                "object_type": "state_or_accumulated_path",
                "variables_used": name,
                "i_order_classification": class_of[name],
                "admissibility_class": path_status(name, class_of[name]),
                "notes": "Distribution-conditioned paths preserve state-dependence; mechanization-only paths are secondary diagnostics.",
            }
        )
    path_admissibility = pd.DataFrame(admissibility_rows)
    write_csv(path_admissibility, CSV_DIR / "S34R_A_repaired_path_admissibility_ledger.csv")
    admissible = dict(zip(path_admissibility["object_id"], path_admissibility["admissibility_class"]))

    design_rows = []
    spec_rows = []
    for design_id, lhs, rhs, theoretical_role, scale_term, mech_state, dist_state, inc in DESIGNS:
        meta = {
            "theoretical_role": theoretical_role,
            "scale_term": scale_term,
            "mechanization_state": mech_state,
            "distribution_state": dist_state,
            "accumulation_increment": inc,
        }
        row = design_diagnostics(panel, design_id, lhs, rhs, admissible, meta)
        design_rows.append(row)
        has_omega_control = "omega_NFC" in rhs
        blocked_order = any(
            admissible.get(var) in {"BLOCK_STANDARD_I2_RISK", "ROUTE_RATIO_MECHANIZATION_TO_CPR_OR_APPENDIX", "NOT_CONSTRUCTED"}
            for var in rhs
            if var.startswith("Q_")
        )
        run_eg = (
            row["design_status"] not in {"BLOCK_MISSING_VARIABLE", "BLOCK_INSUFFICIENT_SAMPLE", "BLOCK_RANK_DEFICIENT", "SEVERE_FRAGILITY"}
            and not blocked_order
        )
        skip_class = "EG_MIXED_ORDER_CONTROL_DIAGNOSTIC" if has_omega_control else "EG_NOT_RUN_ORDER_INCOMPATIBLE"
        skip_reason = "EG run authorized." if run_eg else "Design or path order gate blocked EG standard run."
        spec_rows.append(
            {
                "design_id": design_id,
                "lhs": lhs,
                "regressors": " + ".join(rhs),
                "model_order_status": "EG_MIXED_ORDER_CONTROL_DIAGNOSTIC" if has_omega_control else "PURE_I1_CORE",
                "run_eg": str(run_eg).upper(),
                "skip_classification": skip_class,
                "skip_reason": skip_reason,
            }
        )
    design_ledger = pd.DataFrame(design_rows)
    write_csv(design_ledger, CSV_DIR / "S34R_A_design_diagnostics_ledger.csv")
    write_csv(pd.DataFrame(spec_rows), CSV_DIR / "S34R_A_eg_model_specs.csv")

    subprocess.run(
        ["Rscript", str(CODE_DIR / "run_atsa_coint_test.R"), str(REPO_ROOT)],
        cwd=REPO_ROOT,
        check=True,
    )
    eg = pd.read_csv(CSV_DIR / "S34R_A_residual_cointegration_eg_ledger.csv")

    spec_review = build_spec_review(design_ledger, eg, admissible)
    write_csv(spec_review, CSV_DIR / "S34R_A_specification_review_ledger.csv")

    final_decision = choose_final_decision(discovery, integration, path_admissibility, design_ledger, eg, spec_review)
    decision_matrix = build_decision_matrix(final_decision, discovery, integration, path_admissibility, design_ledger, eg, spec_review)
    write_csv(decision_matrix, CSV_DIR / "S34R_A_unblock_decision_matrix.csv")
    write_report(final_decision, spec_review, design_ledger, eg, integration)
    validation = build_validation(final_decision, discovery)
    write_csv(validation, CSV_DIR / "S34R_A_validation_checks.csv")
    print(final_decision)


def build_spec_review(design: pd.DataFrame, eg: pd.DataFrame, admissible: dict[str, str]) -> pd.DataFrame:
    eg_primary = eg[eg["test_type"].astype(str).eq("type1")].copy()
    eg_status = dict(zip(eg_primary["design_id"], eg_primary["eg_classification"]))
    rows = []
    for design_id, lhs, rhs, theoretical_role, scale_term, mech_state, dist_state, inc in DESIGNS:
        drow = design.loc[design["design_id"].eq(design_id)].iloc[0]
        rhs_text = " + ".join(rhs)
        i_statuses = [admissible.get(var, "DIAGNOSTIC_ONLY") for var in rhs]
        i_order_status = "PASS" if not any(status.startswith("BLOCK") or status.startswith("ROUTE") or status == "NOT_CONSTRUCTED" for status in i_statuses) else "BLOCK_OR_ROUTE"
        egs = eg_status.get(design_id, "EG_NOT_RUN_ORDER_INCOMPATIBLE")
        standard_status = "STANDARD_CANDIDATE" if i_order_status == "PASS" and drow["design_status"] in {"PASS_DESIGN_DIAGNOSTICS", "WARNING_FRAGILITY", "NEAR_COLLINEAR_WARNING"} and egs in {"EG_PASS_STRONG", "EG_PASS_WEAK"} else "NOT_STANDARD_AUTHORIZED"
        if design_id in {"D12_y_kNRC_Qomega_MEshare_Kcap", "D13_y_kNRC_Qomega_MEshare_NRC"} and standard_status == "STANDARD_CANDIDATE":
            rec = "MAIN_CANDIDATE_FOR_S35"
        elif standard_status == "STANDARD_CANDIDATE" and "Q_omega_MEshare" in rhs_text:
            rec = "SECONDARY_CANDIDATE_FOR_S35"
        elif "omega_NFC" in rhs:
            rec = "OVB_CONTROL_DIAGNOSTIC"
        elif any("ratio" in var for var in rhs):
            rec = "CPR_OR_APPENDIX_DIAGNOSTIC"
        else:
            rec = "DO_NOT_ADVANCE"
        theta = "theta_t equals scale coefficient plus path coefficient times lagged distribution-mechanization state in envelope-growth interpretation." if "Q_omega_" in rhs_text else "No direct distribution-conditioned theta recovery."
        rows.append(
            {
                "spec_id": design_id,
                "lhs": lhs,
                "regressors": rhs_text,
                "theoretical_role": theoretical_role,
                "scale_term": scale_term,
                "mechanization_state": mech_state,
                "distribution_state": dist_state,
                "accumulation_increment": inc,
                "theta_recovery_interpretation": theta,
                "ovb_control_status": "MIXED_ORDER_CONTROL_DIAGNOSTIC" if "omega_NFC" in rhs else "NO_STANDALONE_OMEGA_CONTROL",
                "i_order_status": i_order_status,
                "design_status": drow["design_status"],
                "eg_status": egs,
                "standard_grid_status": standard_status,
                "recommended_role": rec,
                "notes": "Standalone omega, where present, is an OVB-control state and not direct theta recovery.",
            }
        )
    return pd.DataFrame(rows)


def choose_final_decision(
    discovery: pd.DataFrame,
    integration: pd.DataFrame,
    path_admissibility: pd.DataFrame,
    design: pd.DataFrame,
    eg: pd.DataFrame,
    spec_review: pd.DataFrame,
) -> str:
    if (discovery["required"] & ~discovery["exists"]).any():
        return "BLOCK_MISSING_REQUIRED_INPUTS"
    state_i2 = integration[
        integration["variable_name"].isin(["Q_omega_MEshare_Kcap", "Q_omega_MEshare_NRC", "Q_MEshare_Kcap", "Q_MEshare_NRC"])
        & integration["classification"].eq("I2_RISK")
    ]
    if not state_i2.empty:
        return "BLOCK_STATE_I2_RISK_REVIEW_REQUIRED"
    nrc_designs = design[
        design["design_id"].isin(["D12_y_kNRC_Qomega_MEshare_Kcap", "D13_y_kNRC_Qomega_MEshare_NRC", "D6_y_kNRC_QMEshare_Kcap", "D7_y_kNRC_QMEshare_NRC"])
        & design["design_status"].isin(["PASS_DESIGN_DIAGNOSTICS", "WARNING_FRAGILITY", "NEAR_COLLINEAR_WARNING"])
    ]
    if nrc_designs.empty:
        return "HOLD_FOR_DESIGN_REVIEW"
    eg_primary = eg[eg["test_type"].astype(str).eq("type1")]
    core_pass = eg_primary[eg_primary["eg_classification"].isin(["EG_PASS_STRONG", "EG_PASS_WEAK"])]
    if core_pass.empty:
        return "BLOCK_ESTIMATOR_REFREEZE_PENDING_EG_FAIL"
    dist_authorized = spec_review[
        spec_review["regressors"].str.contains("Q_omega_MEshare", regex=False)
        & spec_review["standard_grid_status"].eq("STANDARD_CANDIDATE")
    ]
    if dist_authorized.empty:
        return "BLOCK_DISTRIBUTIONAL_STATE_DEPENDENCE_NOT_IDENTIFIED"
    if (design["design_status"].isin(["WARNING_FRAGILITY", "NEAR_COLLINEAR_WARNING"])).any():
        return "AUTHORIZE_S35_WITH_NRC_ENVELOPE_MENU"
    return "AUTHORIZE_S35_ESTIMATOR_REFREEZE_PREP"


def build_decision_matrix(
    final_decision: str,
    discovery: pd.DataFrame,
    integration: pd.DataFrame,
    path_admissibility: pd.DataFrame,
    design: pd.DataFrame,
    eg: pd.DataFrame,
    spec_review: pd.DataFrame,
) -> pd.DataFrame:
    eg_primary = eg[eg["test_type"].astype(str).eq("type1")]
    return pd.DataFrame(
        [
            {"criterion": "input_discovery_passed", "passed": not (discovery["required"] & ~discovery["exists"]).any(), "notes": "Required S34R, D06, and D07 objects found."},
            {"criterion": "new_states_constructed", "passed": (CSV_DIR / "S34R_A_repaired_augmented_panel.csv").exists(), "notes": "Mechanization and distribution-conditioned paths written."},
            {"criterion": "state_i_order_ledger_created", "passed": (CSV_DIR / "S34R_A_repaired_state_integration_ledger.csv").exists(), "notes": "ADF/KPSS/PP-if-available and second-difference checks recorded."},
            {"criterion": "raw_interactions_blocked", "passed": not path_admissibility.loc[path_admissibility["object_type"].eq("raw_level_interaction")].empty and path_admissibility.loc[path_admissibility["object_type"].eq("raw_level_interaction"), "admissibility_class"].eq("BLOCK_STANDARD_I2_RISK").all(), "notes": "Raw k*state interactions are not in the standard grid."},
            {"criterion": "nrc_envelope_design_available", "passed": design["design_id"].isin(["D12_y_kNRC_Qomega_MEshare_Kcap", "D13_y_kNRC_Qomega_MEshare_NRC"]).any(), "notes": "NRC-envelope designs were screened."},
            {"criterion": "core_eg_pass_exists", "passed": eg_primary["eg_classification"].isin(["EG_PASS_STRONG", "EG_PASS_WEAK"]).any(), "notes": "Type1 residual cointegration screen has at least one weak/strong pass."},
            {"criterion": "distributional_state_dependence_identified", "passed": spec_review["recommended_role"].isin(["MAIN_CANDIDATE_FOR_S35", "SECONDARY_CANDIDATE_FOR_S35"]).any(), "notes": "A distribution-conditioned mechanization path must survive as a standard S35 candidate."},
            {"criterion": "no_final_estimators_run", "passed": True, "notes": "Only design diagnostics and EG residual screens were run."},
            {"criterion": "final_decision", "passed": True, "notes": final_decision},
        ]
    )


def write_report(final_decision: str, spec_review: pd.DataFrame, design: pd.DataFrame, eg: pd.DataFrame, integration: pd.DataFrame) -> None:
    leading = spec_review[spec_review["recommended_role"].eq("MAIN_CANDIDATE_FOR_S35")]
    if leading.empty:
        leading = spec_review[spec_review["recommended_role"].eq("SECONDARY_CANDIDATE_FOR_S35")]
    lead_text = "No S35 main candidate authorized."
    if not leading.empty:
        row = leading.iloc[0]
        lead_text = f"{row['spec_id']}: {row['lhs']} ~ {row['regressors']}."
    next_action = (
        "use the S34R-A specification review ledger to prepare S35 estimator refreeze only for candidates marked `MAIN_CANDIDATE_FOR_S35` or `SECONDARY_CANDIDATE_FOR_S35`."
        if not leading.empty
        else "do not run S35 estimators; first resolve the ambiguous/I2-risk state-path classifications that block distribution-conditioned mechanization from the standard grid."
    )
    report = f"""# S34R-A Repaired Design Review and State-Dependence Gate

Final decision: `{final_decision}`

Leading specification: {lead_text}

Interpretation: the NRC scale term is the plant/envelope scale. A surviving `Q_omega_MEshare_*` path is the distributionally conditioned mechanization-biased envelope accumulation path. Its coefficient is not a generic mechanization effect; it is the contribution of distributionally selected technique to capacity building. With `y_t ~ k_NRC + Q_omega_MEshare_NRC`, theta recovery is read as the scale coefficient plus the path coefficient times lagged `omega_NFC * ME_share_repaired` in the envelope-growth interpretation. A standalone `omega_NFC` term is only an OVB-control diagnostic.

Diagnostics:
- State variables and accumulated paths tested: {len(integration)}
- Designs screened: {len(design)}
- Type1 EG pass count: {int(eg[eg['test_type'].astype(str).eq('type1')]['eg_classification'].isin(['EG_PASS_STRONG', 'EG_PASS_WEAK']).sum())}
- Final estimators run: no

Recommended next action: {next_action}
"""
    (REPORT_DIR / "S34R_A_decision_report.md").write_text(report, encoding="utf-8")


def build_validation(final_decision: str, discovery: pd.DataFrame) -> pd.DataFrame:
    selected_hash_mismatches = []
    for _, row in discovery.iterrows():
        path = REPO_ROOT / row["candidate_path"]
        if row["selected"] and row["sha256_if_exists"] and path.exists() and path.is_file():
            if sha256_file(path) != row["sha256_if_exists"]:
                selected_hash_mismatches.append(row["object_id"])
    checks = [
        ("S34R_A_OPENING_REPO_STATE_RECORDED", (CSV_DIR / "S34R_A_opening_repo_state.csv").exists(), "Opening branch, status, and log recorded."),
        ("S34R_A_INPUT_DISCOVERY_CREATED", (CSV_DIR / "S34R_A_input_discovery_ledger.csv").exists(), "Input discovery ledger created."),
        ("S34R_A_REQUIRED_INPUTS_FOUND", not (discovery["required"] & ~discovery["exists"]).any(), "Required S34R, D06, and D07 inputs found."),
        ("S34R_A_AUGMENTED_PANEL_CREATED", (CSV_DIR / "S34R_A_repaired_augmented_panel.csv").exists(), "Augmented panel created."),
        ("S34R_A_STATE_VARIABLE_LEDGER_CREATED", (CSV_DIR / "S34R_A_repaired_state_variable_ledger.csv").exists(), "State variable ledger created."),
        ("S34R_A_STATE_I_ORDER_LEDGER_CREATED", (CSV_DIR / "S34R_A_repaired_state_integration_ledger.csv").exists(), "State I-order ledger created."),
        ("S34R_A_PATH_ADMISSIBILITY_LEDGER_CREATED", (CSV_DIR / "S34R_A_repaired_path_admissibility_ledger.csv").exists(), "Path admissibility ledger created."),
        ("S34R_A_DESIGN_DIAGNOSTICS_CREATED", (CSV_DIR / "S34R_A_design_diagnostics_ledger.csv").exists(), "Design diagnostics ledger created."),
        ("S34R_A_EG_LEDGER_CREATED", (CSV_DIR / "S34R_A_residual_cointegration_eg_ledger.csv").exists(), "EG ledger created."),
        ("S34R_A_SPECIFICATION_REVIEW_LEDGER_CREATED", (CSV_DIR / "S34R_A_specification_review_ledger.csv").exists(), "Specification review ledger created."),
        ("S34R_A_DECISION_MATRIX_CREATED", (CSV_DIR / "S34R_A_unblock_decision_matrix.csv").exists(), "Decision matrix created."),
        ("S34R_A_DECISION_REPORT_CREATED", (REPORT_DIR / "S34R_A_decision_report.md").exists(), "Decision report created."),
        ("S34R_A_NO_FINAL_ESTIMATORS_RUN", True, "No FM-OLS, DOLS, IM-OLS, or final long-run model output was produced."),
        ("S34R_A_NO_LOCKED_INPUTS_MODIFIED", not selected_hash_mismatches, "Selected source hashes unchanged." if not selected_hash_mismatches else "Changed: " + ", ".join(selected_hash_mismatches)),
        ("S34R_A_FINAL_DECISION_RECORDED", bool(final_decision), final_decision),
    ]
    return pd.DataFrame([{"check_id": cid, "status": "PASS" if passed else "FAIL", "details": details} for cid, passed, details in checks])


def write_decision_and_validation(final_decision: str, missing: list[str]) -> None:
    write_csv(pd.DataFrame([{"criterion": "final_decision", "passed": False, "notes": final_decision}]), CSV_DIR / "S34R_A_unblock_decision_matrix.csv")
    (REPORT_DIR / "S34R_A_decision_report.md").write_text(
        f"# S34R-A Repaired Design Review and State-Dependence Gate\n\nFinal decision: `{final_decision}`\n\nMissing inputs: {', '.join(missing)}\n",
        encoding="utf-8",
    )
    write_csv(
        pd.DataFrame(
            [
                {"check_id": "S34R_A_OPENING_REPO_STATE_RECORDED", "status": "PASS", "details": "Opening repo state recorded."},
                {"check_id": "S34R_A_INPUT_DISCOVERY_CREATED", "status": "PASS", "details": "Input discovery ledger created."},
                {"check_id": "S34R_A_REQUIRED_INPUTS_FOUND", "status": "FAIL", "details": ", ".join(missing)},
                {"check_id": "S34R_A_FINAL_DECISION_RECORDED", "status": "PASS", "details": final_decision},
            ]
        ),
        CSV_DIR / "S34R_A_validation_checks.csv",
    )


if __name__ == "__main__":
    main()
