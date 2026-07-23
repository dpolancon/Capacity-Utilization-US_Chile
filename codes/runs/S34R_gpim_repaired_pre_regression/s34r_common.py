from __future__ import annotations

import csv
import hashlib
import json
import math
import subprocess
from pathlib import Path
from typing import Iterable

import numpy as np
import pandas as pd


REPO_ROOT = Path("C:/ReposGitHub/Capacity-Utilization-US_Chile")
CODE_DIR = REPO_ROOT / "codes" / "S34R_gpim_repaired_pre_regression"
OUT_DIR = REPO_ROOT / "output" / "S34R_gpim_repaired_pre_regression"
CSV_DIR = OUT_DIR / "csv"
REPORT_DIR = OUT_DIR / "reports"
PLOT_DIR = OUT_DIR / "plots"
DISCOVERY_JSON = CSV_DIR / "S34R_discovery_paths.json"
TOLERANCE = 1e-8


def ensure_dirs() -> None:
    for path in (CSV_DIR, REPORT_DIR, PLOT_DIR):
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


def read_csv(path: Path) -> pd.DataFrame:
    return pd.read_csv(path)


def write_csv(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False, quoting=csv.QUOTE_MINIMAL)


def save_json(data: dict, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, sort_keys=True), encoding="utf-8")


def load_json(path: Path = DISCOVERY_JSON) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def bool_status(condition: bool) -> str:
    return "PASS" if condition else "FAIL"


def decision_file(decision: str, name: str) -> None:
    (REPORT_DIR / name).write_text(decision + "\n", encoding="utf-8")


def longest_block(df: pd.DataFrame, cols: Iterable[str]) -> pd.DataFrame:
    cols = list(cols)
    use = df[["year", *cols]].copy()
    for col in cols:
        use[col] = pd.to_numeric(use[col], errors="coerce")
    use = use.dropna(subset=cols)
    if use.empty:
        return use
    use = use.sort_values("year").reset_index(drop=True)
    breaks = use["year"].diff().fillna(1).ne(1).cumsum()
    sizes = breaks.value_counts()
    block_id = sizes.idxmax()
    return use.loc[breaks == block_id].copy()


def lag_by_year(series: pd.Series, years: pd.Series, lag: int = 1) -> pd.Series:
    mapper = pd.Series(series.to_numpy(), index=years.to_numpy())
    return years.map(lambda y: mapper.get(y - lag, np.nan))


def first_diff_by_year(series: pd.Series, years: pd.Series) -> pd.Series:
    out = pd.Series(np.nan, index=series.index, dtype="float64")
    prev = pd.Series(series.to_numpy(), index=years.to_numpy())
    for idx, year in years.items():
        val = series.loc[idx]
        old = prev.get(year - 1, np.nan)
        if pd.notna(val) and pd.notna(old):
            out.loc[idx] = val - old
    return out


def weighted_path(state: pd.Series, change: pd.Series, years: pd.Series) -> pd.Series:
    lagged = lag_by_year(pd.to_numeric(state, errors="coerce"), years, 1)
    inc = lagged.to_numpy(dtype="float64") * pd.to_numeric(change, errors="coerce").to_numpy(dtype="float64")
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


def build_repaired_panel(paths: dict | None = None) -> pd.DataFrame:
    if paths is None:
        paths = load_json()
    d07 = read_csv(REPO_ROOT / paths["d07_wide"])
    s31i = read_csv(REPO_ROOT / paths["s31i_panel"])
    panel = pd.DataFrame({"year": sorted(set(d07["year"]).union(set(s31i["year"])))})
    d07_idx = d07.set_index("year")
    s31i_idx = s31i.set_index("year")

    def from_d07(col: str) -> pd.Series:
        return panel["year"].map(d07_idx[col]) if col in d07_idx.columns else pd.Series(np.nan, index=panel.index)

    def from_s31i(col: str) -> pd.Series:
        return panel["year"].map(s31i_idx[col]) if col in s31i_idx.columns else pd.Series(np.nan, index=panel.index)

    panel["y_t"] = np.log(pd.to_numeric(from_d07("Y_REAL_NFC_GVA_BASELINE"), errors="coerce"))
    panel["K_ME_repaired"] = pd.to_numeric(from_d07("K_real_ME_refrozen"), errors="coerce")
    panel["K_NRC_repaired"] = pd.to_numeric(from_d07("K_real_NRC_refrozen"), errors="coerce")
    panel["K_cap_repaired"] = pd.to_numeric(from_d07("K_real_capacity_refrozen"), errors="coerce")
    missing_cap = panel["K_cap_repaired"].isna()
    panel.loc[missing_cap, "K_cap_repaired"] = (
        panel.loc[missing_cap, "K_ME_repaired"] + panel.loc[missing_cap, "K_NRC_repaired"]
    )
    panel["k_ME"] = np.log(panel["K_ME_repaired"])
    panel["k_NRC"] = np.log(panel["K_NRC_repaired"])
    panel["k_Kcap"] = np.log(panel["K_cap_repaired"])
    panel["g_K_ME"] = first_diff_by_year(panel["k_ME"], panel["year"])
    panel["g_K_NRC"] = first_diff_by_year(panel["k_NRC"], panel["year"])
    panel["g_Kcap"] = first_diff_by_year(panel["k_Kcap"], panel["year"])
    denom = panel["K_ME_repaired"] + panel["K_NRC_repaired"]
    panel["ME_share"] = panel["K_ME_repaired"] / denom
    panel["NRC_share"] = panel["K_NRC_repaired"] / denom
    panel["omega_NFC"] = pd.to_numeric(from_d07("NFC_COMPENSATION_SHARE_GVA"), errors="coerce")
    panel["omega_CORP"] = pd.to_numeric(from_d07("CORP_COMPENSATION_SHARE_GVA"), errors="coerce")
    for col in ["NFC_NET_OPERATING_SURPLUS_SHARE_GVA", "CORP_NET_OPERATING_SURPLUS_SHARE_GVA"]:
        if col in d07_idx.columns:
            panel[col] = pd.to_numeric(from_d07(col), errors="coerce")
    panel["Q_omega"] = weighted_path(panel["omega_NFC"], panel["g_Kcap"], panel["year"])
    panel["Q_MEshare"] = weighted_path(panel["ME_share"], panel["g_Kcap"], panel["year"])
    panel["q_proxy_if_retained"] = first_diff_by_year(panel["ME_share"], panel["year"])
    panel["Q_q_if_retained"] = weighted_path(panel["q_proxy_if_retained"], panel["g_Kcap"], panel["year"])
    panel["q_omega_h1_Kcap_repaired"] = panel["Q_omega"]
    return panel


def classify_i_order(name: str, tests: dict) -> str:
    n_obs = tests.get("n_obs", 0) or 0
    if n_obs < 12:
        return "DIAGNOSTIC_ONLY"
    bounded = (
        name in {"omega_NFC", "omega_CORP", "ME_share", "NRC_share"}
        or "share" in name.lower()
        or "_to_" in name.lower()
        or "ratio" in name.lower()
    )
    ur_level = (tests.get("adf_level_p", math.nan) <= 0.05) or (
        tests.get("pp_level_p_if_available", math.nan) <= 0.05
    )
    ur_diff = (tests.get("adf_diff_p", math.nan) <= 0.05) or (
        tests.get("pp_diff_p_if_available", math.nan) <= 0.05
    )
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
    if "q_proxy" in name or "growth" in name or name.startswith("g_"):
        return "DIAGNOSTIC_ONLY"
    return "AMBIGUOUS"


def design_diagnostics(panel: pd.DataFrame, design_id: str, vars_: list[str]) -> dict:
    if not all(v in panel.columns for v in vars_):
        return {
            "design_id": design_id,
            "regressors": " + ".join(vars_),
            "n_obs": 0,
            "condition_number": np.nan,
            "pairwise_correlation_max": np.nan,
            "rank_status": "missing_variable",
            "allowed_status": "BLOCK_MISSING_VARIABLE",
            "notes": "Missing: " + ", ".join([v for v in vars_ if v not in panel.columns]),
        }
    block = longest_block(panel, vars_)
    if len(block) < len(vars_) + 5:
        return {
            "design_id": design_id,
            "regressors": " + ".join(vars_),
            "n_obs": len(block),
            "condition_number": np.nan,
            "pairwise_correlation_max": np.nan,
            "rank_status": "insufficient_sample",
            "allowed_status": "BLOCK_INSUFFICIENT_SAMPLE",
            "notes": "Too few complete annual observations.",
        }
    x = block[vars_].to_numpy(dtype=float)
    x = (x - np.nanmean(x, axis=0)) / np.nanstd(x, axis=0, ddof=1)
    rank = np.linalg.matrix_rank(x)
    cond = float(np.linalg.cond(x))
    corr = np.corrcoef(x, rowvar=False)
    max_corr = float(np.nanmax(np.abs(corr[np.triu_indices_from(corr, 1)]))) if len(vars_) > 1 else np.nan
    if rank < len(vars_):
        status = "BLOCK_RANK_DEFICIENT"
        notes = "Design matrix is rank deficient."
    elif cond > 100:
        status = "SEVERE_FRAGILITY"
        notes = "Condition number exceeds 100; blocks main-menu authorization."
    elif cond >= 30:
        status = "WARNING_FRAGILITY"
        notes = "Condition number between 30 and 100; hold for design review."
    elif max_corr >= 0.95:
        status = "WARNING_HIGH_PAIRWISE_CORRELATION"
        notes = "Pairwise correlation exceeds 0.95; hold for design review if main candidate."
    else:
        status = "PASS_DESIGN_DIAGNOSTICS"
        notes = "Condition number below 30 and no near-perfect pairwise correlation."
    return {
        "design_id": design_id,
        "regressors": " + ".join(vars_),
        "n_obs": len(block),
        "condition_number": cond,
        "pairwise_correlation_max": max_corr,
        "rank_status": "full_rank" if rank == len(vars_) else "rank_deficient",
        "allowed_status": status,
        "notes": notes,
    }


def run_py(script: str) -> None:
    subprocess.run(["python", str(CODE_DIR / script)], cwd=REPO_ROOT, check=True)

